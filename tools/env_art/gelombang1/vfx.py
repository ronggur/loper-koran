"""Butir 2 — VFX DASAR (M2/M3). Semi-transparan = tanpa garis luar."""
import numpy as np
from pxcore import *

K = P['kertas']
A = P['aksen']
WHITE70 = (255, 255, 255, 179)


def debu_roda(frames=6, cell=(18, 10), anchor=(14, 7)):
    """Kotak debu 2x2 lalu 1x1, krem #F2E7C9, mundur di sepanjang jalan
    (2 px kiri, 1 px turun per frame) dari titik roda belakang."""
    w, h = cell; ax, ay = anchor
    parts = [(0, 0), (2, -1), (4, 1)]          # (frame lahir, geser tegak)
    out = []
    for f in range(frames):
        img = np.zeros((h, w, 4), np.uint8)
        for born, dy in parts:
            a = (f - born) % frames
            x = ax - 1 - 2 * a
            y = ay + a // 1 * 1 // 1 - (1 if a in (1, 2) else 0) + dy
            y = ay + (a + 1) // 2 + dy - (1 if a in (1, 2) else 0)
            size = 2 if a < 3 else (1 if a < 5 else 0)
            if size == 0:
                continue
            c = K[1] if a < 4 else K[2]
            img[max(0, y):y + size, max(0, x):x + size] = c
        out.append(img)
    return out


def _stair(img, x, y, steps, color):
    """garis bertangga 2:1: anak tangga 2x1 px, turun ke kiri"""
    for i in range(steps):
        xx = x - 2 * i; yy = y + i
        if 0 <= yy < img.shape[0]:
            img[yy, max(0, xx - 1):max(0, xx + 1)] = color


def garis_kecepatan(cell=(28, 14)):
    w, h = cell
    v = []
    a = np.zeros((h, w, 4), np.uint8); _stair(a, 27, 3, 10, WHITE70); v.append(a)
    b = np.zeros((h, w, 4), np.uint8); _stair(b, 27, 2, 7, WHITE70); _stair(b, 21, 7, 6, WHITE70); v.append(b)
    c = np.zeros((h, w, 4), np.uint8)
    _stair(c, 27, 1, 4, WHITE70); _stair(c, 17, 6, 4, WHITE70); _stair(c, 25, 9, 3, WHITE70)
    v.append(c)
    return v


def _star(R, theta, cell=15, inner=0.32):
    c = cell / 2
    py, px = np.mgrid[0:cell, 0:cell]
    dx = px + 0.5 - c; dy = py + 0.5 - c
    r = np.sqrt(dx**2 + dy**2)
    phi = np.arctan2(dy, dx) - np.radians(theta)
    lim = R * (inner + (1 - inner) * np.maximum(np.abs(np.cos(2 * phi))**6,
                                              0.42 * np.abs(np.sin(2 * phi))**6))
    m = r <= np.maximum(lim, 1.0)
    img = np.zeros((cell, cell, 4), np.uint8)
    img[m] = A[2]
    img[m & (r < R * 0.62)] = A[1]
    img[m & (r < R * 0.3 + 0.8)] = A[0]
    return add_outline(img)


def bintang_kena():
    """Bintang 4 sudut, 6 frame, berputar 90 derajat sekali lalu pecah."""
    spec = [(1.6, 0), (4.2, 0), (6.0, 22.5), (6.2, 45), (4.6, 67.5), (2.6, 90)]
    frames = [_star(R, t) for R, t in spec]
    # dua frame terakhir: serpih kecil terlempar ke luar
    for f, dist in ((4, 5), (5, 6)):
        img = frames[f]
        for ddx, ddy in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
            x = 7 + ddx * dist - (1 if ddx < 0 else 0); y = 7 + ddy * dist - (1 if ddy < 0 else 0)
            if 0 <= x < 14 and 0 <= y < 14:
                img[y:y + 1, x:x + 1] = A[0]
        frames[f] = add_outline(np.where((img == OUT).all(-1)[..., None], 0, img).astype(np.uint8))
    return frames


DIG = {
    '+': ['...', '.#.', '###', '.#.', '...'],
    '5': ['###', '#..', '##.', '..#', '##.'],
}


def text_px(s):
    rows = [''.join(DIG[ch][r] + '.' for ch in s)[:-1] for r in range(5)]
    img = grid(rows, {'#': K[0]})
    big = np.zeros((7, img.shape[1] + 2, 4), np.uint8)
    big[1:6, 1:-1] = img
    return add_outline(big)


def _coin(wd):
    """koin dilihat dari depan, lebar 6/4/2 px untuk efek berputar"""
    h = 6
    rows = {
        6: ['.####.', '#aabb#', '#abbc#', '#abbc#', '#bbcc#', '.####.'],
        4: ['.##.', '#ab#', '#bc#', '#bc#', '#bc#', '.##.'],
        2: ['##', 'ab', 'bc', 'bc', 'bc', '##'],
    }[wd]
    img = grid(rows, {'#': OUT, 'a': A[0], 'b': A[1], 'c': A[2]})
    return img


def koin_tip(cell=(16, 26), anchor=(8, 24)):
    """Koin naik dan berputar, '+5' muncul di atasnya. 6 frame."""
    w, h = cell; ax, ay = anchor
    rise = [2, 6, 10, 13, 15, 16]
    widths = [6, 4, 2, 4, 6, 6]
    txt = text_px('+5')
    out = []
    for f in range(6):
        img = np.zeros((h, w, 4), np.uint8)
        cimg = _coin(widths[f])
        cx = ax - cimg.shape[1] // 2; cy = ay - rise[f] - cimg.shape[0]
        if f < 5:
            paste(img, cimg, cx, cy)
        if f >= 2:
            ty = cy - txt.shape[0] - 2
            if f == 5:
                ty = ay - rise[f] - 6 - txt.shape[0] - 1
            paste(img, txt, ax - txt.shape[1] // 2, max(0, ty))
        out.append(img)
    return out


def percikan(cell=(24, 16), anchor=(12, 12)):
    """Percikan genangan 5 frame: mahkota air naik, tetes jatuh, cincin melebar.
    Biru muda tanpa garis luar (dianggap semi-transparan di atas genangan)."""
    w, h = cell; ax, ay = anchor
    BM = P['bmuda']; HI = K[0]
    out = []
    drops = [(-4, -1), (-2, -2), (2, -2), (4, -1)]  # arah
    for f in range(5):
        img = np.zeros((h, w, 4), np.uint8)
        # cincin
        rw = [3, 5, 7, 9, 10][f]
        if f >= 1:
            py, px = np.mgrid[0:h, 0:w]
            e = ((px + 0.5 - ax) / rw)**2 + ((py + 0.5 - ay) / (rw / 2))**2
            ring = (e <= 1.0) & (e > 0.55)
            if f == 4:
                ring &= ((px + py) % 2 == 0)
            img[ring] = BM[1] if f < 3 else BM[2]
        # tetes
        t = [1, 2, 3, 4, 5][f]
        for dx, dy in drops:
            x = ax + dx * t // 2
            y = ay + dy * t + (t * t) // 3 - 1
            if f <= 3 and 0 <= y < h - 1 and 0 <= x < w - 1:
                s = 2 if f < 2 else 1
                img[y:y + s, x:x + s] = HI if f < 2 else BM[0]
        if f == 0:
            img[ay - 3:ay, ax - 1:ax + 1] = HI
            img[ay - 1:ay + 1, ax - 3:ax + 3] = BM[0]
        out.append(img)
    return out
