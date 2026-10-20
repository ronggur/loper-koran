"""Komposisi jalan perumahan 640x360 (1x) dengan semua aset gelombang 1 (usulan).

Koordinat dunia mengikuti game (`scripts/config.gd`): x = melintang (0 = garis tengah, + ke sisi dekat), y = sepanjang
jalan (- ke kanan atas), 1 ubin = 32 unit. Aspal x -32..32, trotoar sampai +-64, rumput di luarnya.
- Rumah seberang: pusat tapak x = -137 (halaman depan 26 unit dari kerb luar, `perumahan.py`), kotak surat di x = -69,
  y = pusat + 24 (`fase3.house_far_v`). Pelanggan memakai `prop_kotak_surat` (oranye), bukan pelanggan `prop_kotak_surat_bukan`.
- Sisi dekat (keputusan 2026-10-17, spike run 3C): tembok belakang rendah berpusat di x = 100 (`TEMBOK_X_UBIN` 3,125 di
  `scripts/dev/spike_sisi_dekat.gd`), rumah dekat (varian `bukan`, tanpa kotak surat) mundur 1,25 ubin = 40 unit dari tapak biasa.

`build(sore)`: siang = bayangan penanda apa adanya; sore = penanda diganti #5A2E3A lalu grading hangat satu layar (usulan kasar,
belum memakai shader game). `build(minimal=True)`: hanya aset lama + tembok baru (papan sisi dekat).
"""
import numpy as np

from pxcore import *
import sumber
import koran as K_
import vfx as V
import properti as PR
import tembok_ubin as T

W, H_ = 640, 360
OX, OY = 320, 180            # layar untuk titik dunia (0, 0)

KOLOM = ['rumput_seberang', 'trotoar_seberang', 'aspal_seberang', 'aspal_dekat', 'trotoar_dekat', 'rumput_dekat']
J_ZEBRA, J_POLISI, J_GENANG = -7, -3, 1      # baris ubin (y // 32) untuk ubin baru

RUMAH_SEBERANG_X = -137
KOTAK_SEBERANG_X = -69
TEMBOK_X = 100
RUMAH_DEKAT_X = 171 + 40
SORE_BAYANGAN = (0x5A, 0x2E, 0x3A, 120)


def scr(x, y, z=0):
    return OX + x - y, OY + (x + y) / 2 - z


def _ubin_di(ic, j, minimal, baru):
    """ic = indeks kolom dari garis tengah (-3..2 = KOLOM), j = baris."""
    t = sumber.ubin(KOLOM[ic + 3]) if -3 <= ic <= 2 else sumber.ubin('rumput_polos')
    if minimal:
        return t
    if j == J_ZEBRA:
        if ic in (-1, 0):
            t = baru['zebra']
        elif ic >= 1:
            t = sumber.ubin('aspal_polos')        # simpang T ke sisi dekat
    if j == J_POLISI and ic in (-1, 0):
        t = baru['polisi']
    if j == J_GENANG and ic == 0:
        t = baru['genang']
    return t


def build(sore=False, minimal=False):
    img = np.zeros((H_, W, 4), np.uint8)
    img[:] = P['rumput'][1]
    baru = {'zebra': T.ubin_zebra(), 'polisi': T.ubin_polisi_tidur(), 'genang': T.ubin_genangan()}
    for j in range(-14, 14):
        for ic in range(-11, 13):
            cx, cy = scr(ic * 32 + 16, j * 32 + 16)
            paste(img, _ubin_di(ic, j, minimal, baru), int(cx) - 32, int(cy) - 16)

    objs = []   # (lapisan, kedalaman, sprite, x_kiri, y_atas); lapisan 0 = decal tanah, 1 = benda Y-sort, 3 = efek di atas

    def put(spr, wx, wy, ax, ay, wz=0, depth=None, layer=1):
        sx, sy = scr(wx, wy, wz)
        objs.append((layer, depth if depth is not None else wx + wy, spr, int(round(sx)) - ax, int(round(sy)) - ay))

    # ---- sisi seberang: (rumah, y kotak surat, pelanggan)
    seberang = [('limasan_bukan', -175, False), ('pelana_pelanggan', -45, True), ('limasan_pelanggan', 120, True)]
    kotak = {}
    for nama, ymb, pel in seberang:
        a, o = sumber.rumah(nama)
        put(a, RUMAH_SEBERANG_X, ymb - 24, *o)
        ka, ko = sumber.kotak_surat(pel)
        put(ka, KOTAK_SEBERANG_X, ymb, *ko)
        kotak[nama] = (KOTAK_SEBERANG_X, ymb)

    # ---- sisi dekat: rumah dilihat dari belakang, mundur 1,25 ubin, tembok rendah di kaki kavling
    for nama, yc in (('dekat_limasan_bukan', -94), ('dekat_pelana_lintang_bukan', 56)):
        a, o = sumber.rumah(nama)
        put(a, RUMAH_DEKAT_X, yc, *o)
    urutan = ['polos', 'bata', 'besi', 'pot', 'bata', 'polos', 'besi', 'pot', 'polos']
    modul = {v: T.tembok(v) for v in set(urutan)}
    y0 = -120
    for k, v in enumerate(urutan):
        put(modul[v], TEMBOK_X, y0 + k * 32, *T.WALL_ANCHOR, depth=TEMBOK_X + y0 + k * 32 + 16)
    yk = y0 + len(urutan) * 32
    put(T.tembok_tiang_ujung(), TEMBOK_X, yk, *T.WALL_ANCHOR, depth=TEMBOK_X + yk)

    # ---- pemain di lajur sepeda seberang
    PX, PY = -50, 66
    put(sumber.pemain_frame(0, 0), PX, PY, 23, 46)
    psx, psy = scr(PX, PY)
    if not minimal:
        objs.append((3, 0, V.debu_roda()[2], int(psx) - 22, int(psy) - 4))
        gk = V.garis_kecepatan()
        objs.append((3, 0, gk[0], int(psx) - 40, int(psy) - 30))
        objs.append((3, 0, gk[1], int(psx) - 46, int(psy) - 14))

        # koran terbang ke sisi seberang + bayangannya di tanah
        fx, fy, fz = -66, 20, 22
        put(K_.koran_bayangan()[1], fx, fy, 6, 3, layer=0)
        put(K_.koran_spin()[1], fx, fy, 5, 5, wz=fz, layer=3)

        # koran masuk kotak surat + bintang kena (pelana pelanggan); tumpangan dipasang di pijak kotak surat
        sx, sy = scr(*kotak['pelana_pelanggan'])
        objs.append((3, 0, K_.koran_kotak_surat(), int(sx) + 3, int(sy) - 19))
        objs.append((3, 0, V.bintang_kena()[2], int(sx) - 2, int(sy) - 30))

        # koran terlipat dan gulungan di teras + koin tip (limasan pelanggan)
        sx, sy = scr(*kotak['limasan_pelanggan'])
        objs.append((3, 0, K_.koran_terlipat(), int(sx) - 30, int(sy) - 22))
        objs.append((3, 0, V.koin_tip()[3], int(sx) + 2, int(sy) - 52))
        objs.append((3, 0, K_.koran_teras(), int(sx) - 44, int(sy) - 10))

        # koran meleset di rumput rumah bukan pelanggan
        put(K_.koran_rumput(), -84, -128, 6, 6)

        # tong sampah di rumput sisi dekat, depan tembok
        put(PR.tong_sampah('hijau'), 80, -150, 10, 25)
        put(PR.tong_sampah('biru'), 80, -136, 10, 25)

        # misi kucing: jejak di trotoar dekat menuju mangkuk + kilau
        put(PR.jejak_kucing(2), 44, 112, 2, 18, layer=0)
        put(PR.mangkuk_kucing(), 80, 82, 7, 8)
        put(PR.kilau_misi()[1], 80, 82, 4, 4, wz=16, layer=3)

        # percikan di ubin genangan
        put(V.percikan()[2], 16, 48, 12, 12, layer=3)

        # gerbang: portal terbuka di halaman seberang, pos satpam di sisi dekat sesudah tembok
        put(PR.portal_satpam(terbuka=True), -100, 206, 14, 48)
        put(PR.pos_satpam(), 118, 210, 32, 50)

    urut = ([o for o in objs if o[0] == 0] + sorted([o for o in objs if o[0] == 1], key=lambda o: o[1])
            + [o for o in objs if o[0] == 3])
    for _, _, spr, x, y in urut:
        s = spr
        if sore:
            s = s.copy()
            m = (s[..., 0] == 0) & (s[..., 1] == 0) & (s[..., 2] == 0) & (s[..., 3] == 71)
            s[m] = SORE_BAYANGAN
        paste(img, s, x, y)
    if sore:
        f = img[..., :3].astype(float) * np.array([1.0, 0.86, 0.74]) + np.array([18, 4, 0])
        img[..., :3] = np.clip(f, 0, 255).astype(np.uint8)
    return img


def potongan_ubin(w=320, h=200):
    """Potongan jalan 1x dari ubin lama + ubin baru: zebra simpang, polisi tidur, genangan."""
    img = np.zeros((h, w, 4), np.uint8)
    img[:] = P['rumput'][1]
    baru = {'zebra': T.ubin_zebra(), 'polisi': T.ubin_polisi_tidur(), 'genang': T.ubin_genangan()}
    ox, oy = 112 + 96, 50 + 48
    for j in range(-8, 9):
        for ic in range(-7, 8):
            t = sumber.ubin(KOLOM[ic + 3]) if -3 <= ic <= 2 else sumber.ubin('rumput_polos')
            if j == -3:
                if ic in (-1, 0):
                    t = baru['zebra']
                elif ic >= 1:
                    t = sumber.ubin('aspal_polos')
            if j == 0 and ic in (-1, 0):
                t = baru['polisi']
            if j == 2 and ic == 0:
                t = baru['genang']
            x, y = ic * 32 + 16, j * 32 + 16
            paste(img, t, ox + x - y - 32, oy + (x + y) // 2 - 16)
    return img
