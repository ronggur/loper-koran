"""Butir 3 — PROPERTI & MISI."""
import numpy as np
from pxcore import *

K = P['kertas']


# Palet tong sampah (terang, dasar, gelap). K-1 (2026-10-21): hijau dibuang (bentrok OK/tip di HUD dan lajur hijau);
# 'logam' = abu-abu logam dengan DASAR logamg (bukan #969AA0 = RADAR_BUKAN); 'biru' dipertahankan karena tidak ada
# token semantik DESIGN_SPEC 1.1 yang biru (diuji tools/tests_cek/uji_aset_gelombang1.py).
PAL_TONG = {
    'logam': [P['logam'][0], P['logamg'][0], P['logamg'][1]],
    'biru': P['biru'],
}


def tong_sampah(pal_name='logam'):
    """Tong sampah bulat bertutup, tapak r=7 unit (~1/4 ubin).
    Palette swap: 'logam' (abu-abu logam) dan 'biru'. Sel 20x30, pijak (10,25)."""
    pal = PAL_TONG[pal_name]
    lg = P['logamg']
    body = sd_cyl(0, 0, 0, 15, 6.5)
    rim = sd_cyl(0, 0, 9.5, 11, 7.0)          # cincin pegangan di tengah badan
    lid = sd_cyl(0, 0, 15, 17.5, 7.2)
    knob = sd_box((0, 0, 18.5), (1.6, 3.0, 1.0))
    def sh(pl, hi=0.5, lo=-0.25):
        tones = np.array(pl, np.uint8)
        def f(x, y, z, nx, ny, nz):
            return tones[tone_from_normal(nx, ny, nz, hi, lo)]
        return f
    lidpal = [pal[1], pal[2], lg[0]]
    solids = [Solid(knob, sh([lg[0], lg[1], lg[2]])), Solid(lid, sh(lidpal)),
              Solid(rim, sh([pal[1], pal[2], lg[1]])), Solid(body, sh(pal))]
    img = render(20, 30, 10, 25, solids, zmin=-1, zmax=24, step=0.1, inner=3.0)
    return with_shadow(img, 10, 25, 18, 8)


PAW = ['.#.#.', '#.#.#', '.###.', '.###.']   # 1 jejak: 3 jari + telapak


def jejak_kucing(variant=1):
    """Jejak kaki kucing berlumpur (kayu gelap) di bidang tanah.
    v1 = lurus sepanjang jalan (naik ke kanan atas), v2 = berbelok ke rumah (kiri atas)."""
    w, h = 40, 20
    img = np.zeros((h, w, 4), np.uint8)
    paw = grid(['.#.#.', '#####', '.###.', '.###.'], {'#': P['kayu'][2]})
    # versi 2 px aman: jari digabung jadi baris 5 px agar tidak ada detail 1 px lepas
    paw = grid(['##.##', '#####', '.###.'], {'#': P['kayu'][2]})
    if variant == 1:
        pts = [(2, 15), (9, 13), (14, 9), (21, 7), (26, 3), (33, 1)]
        pts = [(x, y + (2 if i % 2 else 0)) for i, (x, y) in enumerate(pts)]
    else:
        pts = [(2, 15), (9, 14), (13, 10), (17, 9), (17, 5), (22, 3), (24, 0)]
        pts = [(2, 16), (9, 14), (13, 10), (19, 10), (21, 6), (27, 5), (29, 1)]
    for x, y in pts:
        paste(img, paw, x, y)
    return img


def mangkuk_kucing():
    """Mangkuk plastik pink berisi pelet makanan kucing. Sel 14x12, pijak (7,8)."""
    pk = P['pink']
    bowl = sd_sub(sd_cyl(0, 0, 0, 3.0, 4.5), sd_cyl(0, 0, 1.6, 4.0, 3.3))
    food = sd_cyl(0, 0, 0, 2.4, 3.4)
    def bsh(x, y, z, nx, ny, nz):
        t = tone_from_normal(nx, ny, nz, 0.5, -0.2)
        return np.array([pk[0], pk[0], pk[2]], np.uint8)[t]
    def fsh(x, y, z, nx, ny, nz):
        kk = P['kayu']
        pat = ((np.floor(x * 1.0) + np.floor(y * 1.0)) % 2 == 0)
        c = np.where(pat[:, None], np.array(kk[0], np.uint8), np.array(kk[1], np.uint8))
        return c
    img = render(14, 12, 7, 8, [Solid(food, fsh), Solid(bowl, bsh)], zmin=-1, zmax=8, step=0.1, inner=2.0)
    return with_shadow(img, 7, 8, 11, 5)


def kilau_misi():
    """Kilau petunjuk misi 9x9, 2 frame, dua warna + garis luar (K-1, 2026-10-21): krem terang (`kertas` terang) dominan,
    kuning aksen HANYA satu piksel di titik tengah. Garis luar yang membuatnya terbaca di atas trotoar krem; kuning tidak
    menjadi isi utama supaya tidak tertukar dengan penanda sasaran kuning (ART_DIRECTION 11a)."""
    key = {'o': OUT, 'a': P['kertas'][0], 'c': P['aksen'][1]}
    f1 = grid([
        '.........',
        '....o....',
        '...oao...',
        '..oaaao..',
        '.oaacaao.',
        '..oaaao..',
        '...oao...',
        '....o....',
        '.........'], key)
    f2 = grid([
        '....o....',
        '...oao...',
        '.o.oao.o.',
        'oaooaooao',
        '.ooacaoo.',
        'oaooaooao',
        '.o.oao.o.',
        '...oao...',
        '....o....'], key)
    return [f1, f2]


def _box_solid(c, half, pal, faces=None, pattern=None):
    f = sd_box(c, half)
    def sh(x, y, z, nx, ny, nz):
        fc = face_of(nx, ny, nz)
        col = np.zeros(x.shape + (4,), np.uint8)
        col[:] = pal[1]
        col[fc == 0] = pal[0]
        col[fc == 2] = pal[2]
        if pattern is not None:
            pattern(col, x, y, z, fc)
        return col
    return Solid(f, sh)


def portal_satpam(terbuka=False):
    """Portal palang: tiang + pemberat di sisi seberang, palang belang
    bata/krem melintang jalan (sepanjang x, 52 unit). Sel 80x56, pijak (14,40)."""
    lg = P['logamg']; br = P['bata']
    solids = []
    solids.append(_box_solid((0, 0, 9), (2, 2, 9), [lg[0], lg[1], lg[2]]))       # tiang
    solids.append(_box_solid((-4, 0, 16), (3, 2.5, 2.5), P['logam']))            # pemberat
    def stripes(col, x, y, z, fc, along):
        k = (np.floor(along / 6) % 2 == 0)
        col[k & (fc == 0)] = br[0]; col[k & (fc == 1)] = br[1]; col[k & (fc == 2)] = br[2]
        col[~k & (fc == 0)] = K[0]; col[~k & (fc == 1)] = K[1]; col[~k & (fc == 2)] = K[2]
    if not terbuka:
        solids.append(_box_solid((28, 0, 16), (26, 1.2, 1.2), K,
                                 pattern=lambda c, x, y, z, fc: stripes(c, x, y, z, fc, x)))
        solids.append(_box_solid((52, 0, 6), (1, 1, 6), P['logam']))             # penyangga ujung
    else:
        # palang terangkat: diputar ke atas sekitar 75 derajat -> hampir tegak
        def sdf_up(x, y, z):
            ang = np.radians(75)
            u = (x - 2) * np.cos(ang) + (z - 16) * np.sin(ang)
            v = -(x - 2) * np.sin(ang) + (z - 16) * np.cos(ang)
            q = np.maximum(np.maximum(np.abs(u - 24) - 24, np.abs(y) - 1.2), np.abs(v) - 1.2)
            return q
        def shu(x, y, z, nx, ny, nz):
            ang = np.radians(75)
            u = (x - 2) * np.cos(ang) + (z - 16) * np.sin(ang)
            fc = face_of(nx, ny, nz)
            col = np.zeros(x.shape + (4,), np.uint8); col[:] = K[1]
            stripes(col, x, y, z, np.where(fc == 0, 1, fc), u)
            return col
        solids.append(Solid(sdf_up, shu))
    img = render(80, 64, 14, 48, solids, zmin=-1, zmax=70, step=0.15, inner=4.0)
    return with_shadow(img, 14, 48, 10, 5)


def pos_satpam():
    """Pos satpam kecil 20x24 unit, dinding krem pastel, jendela kaca biru muda,
    atap dongker menjorok, plat atap tipis. Sel 64x64, pijak (32,48)."""
    kr = P['krem']; dk = P['dongker']; bm = P['bmuda']
    def wall_pat(col, x, y, z, fc):
        # jendela lebar di sisi +x (menghadap kamera kanan bawah) dan pintu di sisi +y
        win = (fc == 2) & (z > 9) & (z < 17) & (np.abs(y) < 8)
        col[win] = bm[2]
        col[win & (z > 15)] = OUT
        col[(fc == 2) & (z > 9) & (z < 17) & (np.abs(np.abs(y) - 8) < 0.6)] = OUT
        door = (fc == 1) & (z < 18) & (x > -2) & (x < 6)
        col[door] = P['kayu'][1]
        col[door & (x > 4.5)] = P['kayu'][2]
        col[(fc == 2) & (z < 2)] = P['logam'][2]   # plint
        col[(fc == 1) & (z < 2) & ~door] = P['logam'][1]
    walls = _box_solid((0, 0, 11), (10, 12, 11), [kr[0], kr[0], kr[2]], pattern=wall_pat)
    roof = _box_solid((1, 1, 23.5), (13, 15, 1.5), [dk[0], dk[1], dk[2]])
    sign = _box_solid((11, 0, 19.5), (0.6, 7, 2.2), [K[0], K[0], K[1]],
                      pattern=lambda c, x, y, z, fc: c.__setitem__((fc == 2) & (np.abs(z - 19.5) < 0.6) & (np.abs(y) < 5), P['dongker'][1]))
    img = render(64, 64, 32, 50, [sign, roof, walls], zmin=-1, zmax=30, step=0.1, inner=4.0)
    return with_shadow(img, 34, 52, 52, 22)
