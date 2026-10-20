"""pxcore — inti renderer pixel art isometrik 2:1 untuk Loper Koran (usulan, gelombang 1).

Semua sprite digambar dengan kode: SDF (kotak, silinder, kapsul) yang di-raycast
per piksel, decal di bidang tanah, atau grid piksel eksplisit. Tanpa anti-aliasing.

Proyeksi (unit dunia = 1 px):
  sumbu x -> layar (+1, +0.5)   (melintang jalan, + ke sisi dekat / kanan bawah)
  sumbu y -> layar (-1, +0.5)   (sepanjang jalan, - ke kanan atas)
  sumbu z -> layar ( 0, -1)     (tinggi)
  1 ubin = 32 unit = belah ketupat 64x32 px.
Cahaya dari kiri atas layar: sisi atas = terang, sisi +y = dasar, sisi +x = gelap.
"""
import numpy as np
from PIL import Image


def H(s, a=255):
    s = s.lstrip('#')
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), a)


OUT = H('#0E0A1C')
SHADOW = (0, 0, 0, 71)          # warna PENANDA bayangan, diganti saat render
CLEAR = (0, 0, 0, 0)

# Palet induk (terang, dasar, gelap)
P = {
    'kertas':  [H('#FBF6E8'), H('#F2E7C9'), H('#C2AF86')],
    'kulit':   [H('#F2B98C'), H('#E8A07A'), H('#B47C5F')],
    'biru':    [H('#9BC4D8'), H('#5F96C8'), H('#466E8C')],
    'dongker': [H('#7480A3'), H('#5C6A8C'), H('#404A62')],
    'hijau':   [H('#6FAE4F'), H('#466E50'), H('#314D38')],
    'rumput':  [H('#7DBB5A'), H('#6FAE4F'), H('#62A046')],
    'bata':    [H('#B5523B'), H('#994532'), H('#673F31')],
    'kayu':    [H('#B47C5F'), H('#96643C'), H('#553428')],
    'logam':   [H('#C4C0C8'), H('#969AA0'), H('#67636D')],
    'logamg':  [H('#5F5B66'), H('#3D4649'), H('#221E26')],
    'aksen':   [H('#FFE08A'), H('#FFC94A'), H('#E98E3F')],
    'pink':    [H('#F0C8CD'), H('#F0C8CD'), H('#BB9C9F')],
    'hmuda':   [H('#C9E0A5'), H('#C9E0A5'), H('#9CAE80')],
    'bmuda':   [H('#AADCF0'), H('#AADCF0'), H('#90BBCC')],
    'krem':    [H('#F6D6A0'), H('#F6D6A0'), H('#C2AF86')],
}
ASPAL = [H('#6C6872'), H('#67636D')]
MARKA = H('#F2E7C9')
TROTOAR = [H('#DCCBA6'), H('#D5C4A1')]
KERB = H('#A9A2AE')
PUTIH = H('#FFFFFF')

LIGHT = np.array([-1.0, 0.55, 1.3])
LIGHT = LIGHT / np.linalg.norm(LIGHT)


# ---------------------------------------------------------------- SDF
def sd_box(c, half):
    c = np.array(c, float); half = np.array(half, float)
    def f(x, y, z):
        qx = np.abs(x - c[0]) - half[0]
        qy = np.abs(y - c[1]) - half[1]
        qz = np.abs(z - c[2]) - half[2]
        out = np.sqrt(np.maximum(qx, 0)**2 + np.maximum(qy, 0)**2 + np.maximum(qz, 0)**2)
        ins = np.minimum(np.maximum(qx, np.maximum(qy, qz)), 0)
        return out + ins
    return f


def sd_cyl(cx, cy, z0, z1, r):
    """silinder tegak"""
    def f(x, y, z):
        d = np.sqrt((x - cx)**2 + (y - cy)**2) - r
        h = np.abs(z - (z0 + z1) / 2) - (z1 - z0) / 2
        return np.minimum(np.maximum(d, h), 0) + np.sqrt(np.maximum(d, 0)**2 + np.maximum(h, 0)**2)
    return f


def sd_cyl_x(cy, cz, x0, x1, r):
    """silinder rebah sepanjang sumbu x"""
    def f(x, y, z):
        d = np.sqrt((y - cy)**2 + (z - cz)**2) - r
        h = np.abs(x - (x0 + x1) / 2) - (x1 - x0) / 2
        return np.minimum(np.maximum(d, h), 0) + np.sqrt(np.maximum(d, 0)**2 + np.maximum(h, 0)**2)
    return f


def sd_union(*fs):
    def f(x, y, z):
        r = fs[0](x, y, z)
        for g in fs[1:]:
            r = np.minimum(r, g(x, y, z))
        return r
    return f


def sd_sub(a, b):
    def f(x, y, z):
        return np.maximum(a(x, y, z), -b(x, y, z))
    return f


def tone_from_normal(nx, ny, nz, hi=0.55, lo=-0.05):
    d = nx * LIGHT[0] + ny * LIGHT[1] + nz * LIGHT[2]
    t = np.where(d > hi, 0, np.where(d > lo, 1, 2))
    return t


class Solid:
    def __init__(self, sdf, shade, name=''):
        self.sdf, self.shade, self.name = sdf, shade, name


def mat(pal, hi=0.55, lo=-0.05):
    """shader sederhana: 3 nada dari normal"""
    tones = np.array([pal[0], pal[1], pal[2]], np.uint8)
    def s(x, y, z, nx, ny, nz):
        return tones[tone_from_normal(nx, ny, nz, hi, lo)]
    return s


def face_of(nx, ny, nz):
    """0=atas, 1=sisi +y (kiri bawah), 2=sisi +x (kanan bawah), 3=lain"""
    ax = np.abs(nx); ay = np.abs(ny); az = np.abs(nz)
    return np.where((az >= ax) & (az >= ay) & (nz > 0), 0,
           np.where((ay >= ax) & (ny > 0), 1,
           np.where(nx > 0, 2, 3)))


def render(w, h, ax, ay, solids, zmin=-2, zmax=80, step=0.125, outline=True,
           inner=6.0, eps=0.3):
    """Raycast satu sprite. (ax, ay) = titik pijak dunia (0,0,0) di sel."""
    py, px = np.mgrid[0:h, 0:w]
    sx = px + 0.5 - ax
    sy = py + 0.5 - ay
    zs = np.arange(zmax, zmin, -step)
    best_t = np.full((h, w), -1, int)
    best_s = np.full((h, w), -1, int)
    for zi, z in enumerate(zs):
        x = (sx + 2 * (sy + z)) / 2
        y = (2 * (sy + z) - sx) / 2
        open_ = best_t < 0
        if not open_.any():
            break
        for si, so in enumerate(solids):
            ins = (so.sdf(x, y, np.full_like(x, z)) <= 0) & open_ & (best_t < 0)
            best_t[ins] = zi
            best_s[ins] = si
    img = np.zeros((h, w, 4), np.uint8)
    depth = np.full((h, w), -1e9)
    hit = best_t >= 0
    for si, so in enumerate(solids):
        m = hit & (best_s == si)
        if not m.any():
            continue
        z = zs[best_t[m]]
        x = (sx[m] + 2 * (sy[m] + z)) / 2
        y = (2 * (sy[m] + z) - sx[m]) / 2
        f = so.sdf
        nx = f(x + eps, y, z) - f(x - eps, y, z)
        ny = f(x, y + eps, z) - f(x, y - eps, z)
        nz = f(x, y, z + eps) - f(x, y, z - eps)
        n = np.sqrt(nx**2 + ny**2 + nz**2) + 1e-9
        img[m] = so.shade(x, y, z, nx / n, ny / n, nz / n)
        depth[m] = x + y + z
    if inner:
        # garis dalam di patahan kedalaman besar (tepi tutup, pinggiran)
        out = img.copy()
        for dy, dx in ((0, 1), (1, 0), (0, -1), (-1, 0)):
            nd = np.roll(np.roll(depth, dy, 0), dx, 1)
            nh = np.roll(np.roll(hit, dy, 0), dx, 1)
            m = hit & nh & (nd - depth > inner)
            out[m] = OUT
        img = out
    if outline:
        img = add_outline(img)
    return img


def add_outline(img, color=OUT):
    a = img[..., 3] == 255
    ring = np.zeros_like(a)
    ring[1:, :] |= a[:-1, :]
    ring[:-1, :] |= a[1:, :]
    ring[:, 1:] |= a[:, :-1]
    ring[:, :-1] |= a[:, 1:]
    ring &= ~a
    out = img.copy()
    out[ring] = color
    return out


def ellipse_mask(w, h, cx, cy, rw, rh):
    py, px = np.mgrid[0:h, 0:w]
    return ((px + 0.5 - cx) / rw)**2 + ((py + 0.5 - cy) / rh)**2 <= 1.0


def with_shadow(img, cx, cy, sw, sh=None):
    """Bayangan elips penanda di bawah sprite, digeser 1 px kanan bawah."""
    h, w = img.shape[:2]
    sh = sh if sh is not None else sw / 2
    m = ellipse_mask(w, h, cx + 1, cy + 1, sw / 2, sh / 2)
    base = np.zeros_like(img)
    base[m] = SHADOW
    opaque = img[..., 3] > 0
    base[opaque] = img[opaque]
    return base


def grid(rows, key):
    """Grid piksel eksplisit: tiap karakter -> warna lewat key ('.' = kosong)."""
    h = len(rows); w = max(len(r) for r in rows)
    img = np.zeros((h, w, 4), np.uint8)
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch != '.' and ch != ' ':
                img[y, x] = key[ch]
    return img


def ground_xy(w, h, ax, ay):
    """koordinat dunia (x, y) di bidang z=0 untuk tiap piksel"""
    py, px = np.mgrid[0:h, 0:w]
    sx = px + 0.5 - ax
    sy = py + 0.5 - ay
    return (sx + 2 * sy) / 2, (2 * sy - sx) / 2


def paste(dst, src, x, y):
    """tempel RGBA (numpy) ke dst (numpy) di (x,y) kiri atas, alpha-over"""
    h, w = src.shape[:2]
    H_, W_ = dst.shape[:2]
    x0, y0 = max(0, x), max(0, y)
    x1, y1 = min(W_, x + w), min(H_, y + h)
    if x0 >= x1 or y0 >= y1:
        return
    s = src[y0 - y:y1 - y, x0 - x:x1 - x].astype(float)
    d = dst[y0:y1, x0:x1].astype(float)
    a = s[..., 3:4] / 255
    da = d[..., 3:4] / 255
    oa = a + da * (1 - a)
    rgb = (s[..., :3] * a + d[..., :3] * da * (1 - a)) / np.maximum(oa, 1e-6)
    d[..., :3] = rgb
    d[..., 3:4] = oa * 255
    dst[y0:y1, x0:x1] = np.round(d).astype(np.uint8)


def to_img(a):
    return Image.fromarray(a, 'RGBA')


def from_img(im):
    return np.array(im.convert('RGBA'))


def hstack(frames, gap=0):
    h = max(f.shape[0] for f in frames)
    w = sum(f.shape[1] for f in frames) + gap * (len(frames) - 1)
    out = np.zeros((h, w, 4), np.uint8)
    x = 0
    for f in frames:
        out[:f.shape[0], x:x + f.shape[1]] = f
        x += f.shape[1] + gap
    return out


def pad_to(img, w, h, x, y):
    out = np.zeros((h, w, 4), np.uint8)
    paste(out, img, x, y)
    return out
