"""Butir 4 — tembok belakang rendah sisi dekat, dan butir 5 — ubin tambahan."""
import numpy as np
from PIL import Image
from pxcore import *
import sumber

K = P['kertas']
WALL_CELL = (46, 46)
WALL_ANCHOR = (41, 25)   # titik dunia (0,0,0) = garis tengah tembok di awal modul
MODUL = 32               # panjang modul sepanjang sumbu y (1 ubin)


def sd_sphere(c, r):
    def f(x, y, z):
        return np.sqrt((x - c[0])**2 + (y - c[1])**2 + (z - c[2])**2) - r
    return f


def _wall_shader(face_pal, top_pal, pattern=None, plint=True):
    def sh(x, y, z, nx, ny, nz):
        fc = face_of(nx, ny, nz)
        col = np.zeros(x.shape + (4,), np.uint8)
        col[:] = face_pal[1]               # sisi +x (menghadap kamera): dasar
        col[fc == 0] = top_pal[0]          # atas: terang
        col[fc == 1] = top_pal[0]          # ujung +y: terang (tepi kena cahaya)
        if plint:
            col[(fc == 2) & (z < 2)] = face_pal[2]
        if pattern is not None:
            pattern(col, x, y, z, fc)
        return col
    return sh


def _pillar(top=17):
    pl = K
    s = Solid(sd_union(sd_box((0, 2, top / 2 - 1), (3, 2, top / 2 - 1)),
                       sd_box((0, 2, top - 0.75), (3.5, 2.5, 0.75))),
              _wall_shader([pl[0], pl[1], pl[2]], pl))
    return s


def _body(face_pal, top_pal, pattern=None, h=14, x_half=2.0, plint=True):
    body = sd_box((0, MODUL / 2 + 2, h / 2 - 0.5), (x_half, MODUL / 2 - 2, h / 2 - 0.5))
    cap = sd_box((0, MODUL / 2 + 2, h - 0.5), (x_half + 0.5, MODUL / 2 - 2, 0.5))
    return [Solid(cap, _wall_shader(top_pal, top_pal, None, plint=False)),
            Solid(body, _wall_shader(face_pal, top_pal, pattern, plint))]


def tembok(var):
    """var: polos | bata | besi | pot"""
    solids = [_pillar()]
    if var == 'polos':
        solids += _body(K, K)
    elif var == 'bata':
        br = P['bata']
        def bricks(col, x, y, z, fc):
            m = (fc == 2) & (z >= 2) & (z < 13)
            row = np.floor((z - 2) / 3)
            mortar = ((z - 2) % 3 < 1) | (((y + 3 * (row % 2)) % 6) < 1)
            col[m] = br[1]
            col[m & mortar] = br[2]
            col[(fc == 2) & (z < 2)] = br[2]
        solids += _body([br[0], br[1], br[2]], K, bricks)
    elif var == 'besi':
        lg = P['logamg']
        solids += _body(K, K, h=5)
        rail = sd_box((0, MODUL / 2 + 2, 13.5), (0.6, MODUL / 2 - 2, 0.6))
        bars = []
        for i in range(7):
            yy = 6 + i * 4
            bars.append(sd_box((0, yy, 9.5), (0.5, 0.5, 4.5)))
        iron = Solid(sd_union(rail, *bars), _wall_shader([lg[0], lg[1], lg[2]], [lg[0], lg[1], lg[2]], plint=False))
        solids.insert(1, iron)
    elif var == 'pot':
        hm = P['hmuda']; br = P['bata']; hj = P['hijau']
        pots = []
        for yy in (12, 26):
            bush = sd_union(sd_sphere((0, yy, 19.5), 3.0), sd_sphere((0.5, yy - 2, 18.5), 2.2),
                            sd_sphere((-0.5, yy + 2, 18.8), 2.2), sd_sphere((0, yy, 21.5), 2.0))
            pots.append(Solid(bush, mat([P['rumput'][0], hj[1], hj[2]], 0.45, -0.1)))
            pots.append(Solid(sd_cyl(0, yy, 14, 18, 2.4), mat([br[0], br[1], br[2]], 0.5, -0.2)))
        solids = pots + solids + _body([hm[0], hm[1], hm[2]], K)
    img = render(*WALL_CELL, *WALL_ANCHOR, solids, zmin=-1, zmax=26, step=0.1, inner=5.0)
    return img


def tembok_tiang_ujung():
    """tiang penutup untuk ujung rantai modul"""
    return render(*WALL_CELL, *WALL_ANCHOR, [_pillar()], zmin=-1, zmax=20, step=0.1, inner=5.0)


# ------------------------------------------------------------------ ubin
TW, TH = 64, 32


def _tile_base(name='aspal_polos'):
    return sumber.ubin(name)


def _diamond():
    py, px = np.mgrid[0:TH, 0:TW]
    return np.abs(px + 0.5 - 32) / 32 + np.abs(py + 0.5 - 16) / 16 <= 1.0


def ubin_polisi_tidur():
    """Polisi tidur melintang lajur: pita 7 unit, belang krem/logam gelap tiap 5 unit.
    Tepi +y (kiri bawah) lebih gelap memberi kesan tinggi tanpa keluar dari 64x32."""
    t = _tile_base()
    x, y = ground_xy(TW, TH, 32, 16)
    d = _diamond()
    band = d & (np.abs(y) <= 4.0)
    stripe = (np.floor((x + 16) / 4) % 2 == 0)
    lg = P['logamg']
    t[band & stripe] = MARKA
    t[band & ~stripe] = lg[1]
    edge = band & (y > 2.4)
    t[edge & stripe] = K[2]
    t[edge & ~stripe] = lg[2]
    lip = d & (y > 4.0) & (y <= 5.2)
    t[lip] = lg[2]
    hi = band & (y < -3.0)
    t[hi & stripe] = K[0]
    t[hi & ~stripe] = lg[0]
    return t


def ubin_zebra():
    """Persimpangan: zebra cross melintang jalan, garis sejajar jalan
    (sumbu y) lebar 4 unit, celah 4 unit. Dipakai di dua lajur aspal."""
    t = _tile_base()
    x, y = ground_xy(TW, TH, 32, 16)
    d = _diamond()
    stripe = d & (((x + 16) % 8) >= 2) & (((x + 16) % 8) < 6) & (np.abs(y) <= 11)
    t[stripe] = MARKA
    return t


def ubin_genangan():
    """Genangan air di aspal: tepi bergelombang, pantulan langit biru muda,
    bibir gelap di sisi kanan bawah."""
    t = _tile_base()
    x, y = ground_xy(TW, TH, 32, 16)
    th = np.arctan2(y, x)
    rr = np.sqrt((x / 11)**2 + (y / 13)**2) * (1 + 0.12 * np.sin(3 * th + 0.7) + 0.06 * np.sin(5 * th))
    pud = rr <= 1.0
    bm = P['bmuda']; bi = P['biru']
    t[pud] = bm[2]
    t[pud & (rr > 0.82) & ((x + y) > 0)] = bi[2]           # bibir gelap kanan bawah
    refl = pud & (np.abs(x - y * 0.5 + 2) < 2.2) & (rr < 0.8)
    t[refl] = bm[0]
    spark = pud & (np.abs(x + 4) < 1.1) & (np.abs(y + 5) < 1.1)
    t[spark] = K[0]
    return t
