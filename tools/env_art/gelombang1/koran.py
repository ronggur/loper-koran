"""Butir 1 — KORAN (M2): gulung berputar, mendarat, terlipat, bayangan."""
import numpy as np
from pxcore import *

K = P['kertas']
BATA = P['bata']


def roll_screen(angle_deg, length=2.6, r=2.0, cell=(10, 10), cxy=None):
    """Koran gulung di ruang layar: kapsul dengan karet bata di tengah.
    Sisi menghadap kiri atas = terang, tengah = dasar, kanan bawah = gelap."""
    w, h = cell
    cx, cy = cxy if cxy else (w / 2, h / 2)
    a = np.radians(angle_deg)
    ux, uy = np.cos(a), -np.sin(a)            # sumbu gulungan
    vx, vy = -uy, ux                          # tegak lurus
    if vx * -1 + vy * -1 < 0:                 # v menunjuk ke kiri atas
        vx, vy = -vx, -vy
    py, px = np.mgrid[0:h, 0:w]
    dx = px + 0.5 - cx; dy = py + 0.5 - cy
    t = dx * ux + dy * uy
    s = dx * vx + dy * vy
    tc = np.clip(t, -length / 2, length / 2)
    dist = np.sqrt((t - tc)**2 + s**2)
    inside = dist <= r
    img = np.zeros((h, w, 4), np.uint8)
    img[inside] = K[1]
    img[inside & (s > 0.7)] = K[0]
    img[inside & (s < -0.7)] = K[2]
    band = inside & (np.abs(t) < 0.75)
    img[band] = BATA[1]
    img[band & (s > 0.7)] = BATA[0]
    img[band & (s < -0.7)] = BATA[2]
    return add_outline(img)


def koran_spin():
    # 4 frame: mendatar, serong naik, tegak, serong turun (berputar maju)
    angs = [0, 45, 90, 135]
    return [roll_screen(a) for a in angs]


SLOPE = 26.565  # sudut garis 2:1 di layar

def koran_teras():
    """Tergeletak di lantai keras, sejajar jalan (garis 2:1)."""
    img = roll_screen(SLOPE, length=3.4, r=2.0, cell=(12, 10), cxy=(6, 5))
    return with_shadow(img, 6, 6.5, 10, 4)


def koran_rumput():
    """Sama, tapi terbenam: dua jumput rumput menutup kaki gulungan."""
    img = koran_teras()
    R = P['rumput']
    tufts = grid([
        '............',
        '............',
        '............',
        '............',
        '............',
        '.....o......',
        '..o.oao.....',
        '.oaooao.o...',
        '.oao.o.oao..',
        '..o.....o...',
    ], {'o': OUT, 'a': R[0]})
    m = tufts[..., 3] > 0
    img[m] = tufts[m]
    return img


def koran_kotak_surat():
    """Ujung gulungan mencuat dari celah kotak surat ke arah kanan bawah (+x).
    Sprite tumpangan 8x7: dipasang di atas kotak surat yang sudah ada."""
    return roll_screen(-SLOPE, length=1.6, r=1.6, cell=(8, 7), cxy=(4, 3.5))


def koran_terlipat():
    """Koran terlipat rata di teras (pose 'terantar'): lembar 8x12 unit setebal
    1 unit. Kepala berita dongker, kolom berita garis krem gelap, lipatan."""
    w, h, ax, ay = 14, 10, 7, 5
    def sdf(x, y, z):
        return sd_box((0, 0, 0.5), (3, 4.5, 0.5))(x, y, z)
    def shade(x, y, z, nx, ny, nz):
        f = face_of(nx, ny, nz)
        c = np.zeros(x.shape + (4,), np.uint8)
        c[:] = K[1]
        c[f == 1] = K[2]
        c[f == 2] = K[2]
        top = f == 0
        c[top & (x < -1.6)] = K[0]
        c[top & (np.abs(y) < 0.5)] = K[2]                       # lipatan
        head = top & (x > -1.8) & (x < 0.2) & (y < -1.0) & (y > -3.8)
        c[head] = P['dongker'][1]
        col = top & (x > 0.9) & (x < 2.6) & (np.abs(y) > 1.0) & (np.abs(y) < 3.8)
        c[col] = K[2]
        return c
    img = render(w, h, ax, ay, [Solid(sdf, shade)], zmin=-0.5, zmax=3, step=0.05, inner=0)
    return with_shadow(img, ax, ay + 1, 12, 5)


def koran_bayangan():
    """3 ukuran bayangan sesuai tinggi koran: 10, 8, 6 px (rendah -> tinggi)."""
    out = []
    for wdt in (10, 8, 6):
        img = np.zeros((6, 12, 4), np.uint8)
        m = ellipse_mask(12, 6, 6, 3, wdt / 2, wdt / 4 + 0.3)
        img[m] = SHADOW
        out.append(img)
    return out
