"""Ubin jalan perumahan (usulan): aspal, lajur sepeda di atas trotoar, kerb, rumput, jalan masuk garasi.

Mengikuti tata letak game (scripts/config.gd): aspal JALAN_LEBAR_UBIN = 2 (x -1..1 ubin), trotoar
JALAN_TROTOAR_UBIN = 1 per sisi, rumput di luarnya; 1 ubin = 32 unit dunia = belah ketupat 64x32 px.

Cara kerja: penampang jalan (dengan kerb dan lajur sepeda yang ditinggikan) dirender sekali sebagai adegan
yang berulang tiap 32 unit sepanjang jalan, lalu dipotong per belah ketupat. Belah ketupat layar membagi
bidang tanpa celah dan tumpang tindih, jadi menyusun ubin kembali menghasilkan gambar yang sama persis,
termasuk kerb yang tingginya melewati batas ubin. Tekstur memakai koordinat modulo 32, jadi ubin polos bisa
diulang ke segala arah.

    python3 tools/env_art/ubin_perumahan.py              # ke build/env_art/ubin/ (semua ubin, termasuk yang belum dipasang)
    python3 tools/env_art/ubin_perumahan.py --salin      # juga salin HANYA ubin yang dipasang ke assets/sprites/tiles/perumahan/

`--salin` (run fase5a-pasang-aset-gelombang1, D-1 dan D-2): enam ubin kolom jalan (`PASANG`) ditambah satu ubin rumput polos
(`PASANG_TAMBAHAN`: `rumput_1`, untuk kolom rumput di luar kolom pertama; ubin `rumput_seberang` membawa tepi kerb luar sehingga
mengulangnya membuat pita tepi di tiap ubin), masing-masing PNG, ditambah `tile_perumahan.json` yang HANYA memuat ubin yang dipasang
(dibuat skrip, bukan salinan JSON penuh di build/). Ubin lain (simbol, masuk garasi, aspal_N, rumput_2 dan 3) tetap hanya di build/.
`ENV_ART_SALIN_KE` mengganti folder tujuan (dipakai tools/tests_cek/uji_aset_pasang_gelombang1.py). Polisi tidur kuning-hitam lama
sudah dibuang dari ekspor (K-1 run 5A): satu-satunya polisi tidur adalah `tile_perumahan_polisi_tidur` di tools/env_art/gelombang1/.
"""
import json
import math
import os
import sys
from pathlib import Path

import numpy as np
from PIL import Image

from engine import *          # noqa: F401,F403
from lib import *             # noqa: F401,F403
import perumahan as PR

OUT_DIR = PR.OUT / 'ubin'
OUT_DIR.mkdir(parents=True, exist_ok=True)

U = 32.0                    # 1 ubin, unit dunia
A = 32.0                    # setengah lebar aspal (1 ubin)
KERB_D = (32.0, 35.0)       # kerb dalam (tepi aspal), tinggi 3
LAJUR = (35.0, 62.0)        # lajur sepeda hijau di atas trotoar, tinggi 2
KERB_L = (62.0, 64.0)       # kerb luar, tinggi 2,6
LAJUR_C = (LAJUR[0] + LAJUR[1]) / 2

MATS = [P['grass'], P['asph'], P['mark'], P['conc'], Mat('#5E5A66', '#54505C', '#48444F'), Mat('#9CB86A', '#7FA650', '#5E8A3C')]


def _w(v):
    return np.mod(v, U)


def region_fn(varian=0, marka=True, masuk=None):
    """varian: 0 biasa, 1 tambalan, 2 retak (hanya ubin aspal polos di kolom luar). masuk: (y0, y1) jalan masuk garasi."""
    def region(x, y):
        n = len(x)
        xw, yw = _w(x), _w(y)
        ax = np.abs(x)
        mi = np.zeros(n, int)
        sh = np.ones(n, int) + grass_tufts(xw, yw, 3 + varian)
        # bunga rumput kecil di varian 2
        if varian == 2:
            h = hash2(np.floor(xw / 4), np.floor(yw / 4), 77)
            fl = (h > 0.93) & (np.mod(xw, 4) < 1) & (np.mod(yw, 4) < 1)
            mi = np.where(fl & (ax > KERB_L[1]), 2, mi)
            sh = np.where(fl & (ax > KERB_L[1]), 0, sh)
        road = ax < A
        mi = np.where(road, 1, mi)
        sh = np.where(road, 1 + speckle(xw, yw, 5 + varian, 0.03, 0.05, 1), sh)
        if marka:
            dash = road & (ax < 1.6) & (yw < 16)
            edge = road & (ax > A - 4) & (ax < A - 2.6)
            mi = np.where(dash | edge, 2, mi); sh = np.where(dash | edge, 1, sh)
        if varian == 1:      # tambalan aspal lebih gelap, bentuk kotak tidak rata
            tb = road & (np.abs(xw - 14) + 0.3 * np.abs(yw - 17) < 7) & (np.abs(yw - 17) < 9)
            mi = np.where(tb, 4, mi); sh = np.where(tb, 1 + speckle(xw, yw, 9, 0.02, 0.1, 1), sh)
        if varian == 2:      # retak rambut
            c1 = road & (np.abs((yw - 6) - 0.55 * (xw - 6)) < 0.5) & (xw > 6) & (xw < 22)
            c2 = road & (np.abs((yw - 14) + 0.8 * (xw - 16)) < 0.5) & (xw > 14) & (xw < 21)
            mi = np.where(c1 | c2, 4, mi); sh = np.where(c1 | c2, 2, sh)
        if masuk is not None:
            m0, m1 = masuk
            dv = (ax >= A) & (ax < KERB_L[1] + U) & (y > m0) & (y < m1)
            mi = np.where(dv, 3, mi)
            sh = np.where(dv, 1 + np.where((np.mod(y - m0, 11) < 1) | (np.mod(x, 11) < 1), 1, 0), sh)
        return mi, sh
    return region


def lajur_tex(simbol=None, masuk=None):
    """Permukaan lajur sepeda: hijau, garis tepi luar putih, simbol sepeda + panah opsional (yc), tepi putus di depan
    jalan masuk. Lajur kiri (x < 0) panah ke -y, lajur kanan ke +y (lajur kiri, lalu lintas Indonesia)."""
    def tex(Pw, Nw):
        x, y = Pw[:, 0], Pw[:, 1]
        yw = _w(y)
        top = Nw[:, 2] > 0.5
        ax = np.abs(x)
        mi = np.zeros(len(x), int)
        sh = np.where(top, 1, 0)
        sh = np.where(top & (hash2(np.floor(_w(x)), np.floor(yw), 11) > 0.93), 2, sh)
        line = top & (ax > LAJUR[1] - 2.2) & (ax < LAJUR[1] - 1.0)
        mi = np.where(line, 1, mi)
        if simbol is not None:
            far = x < 0
            u = np.where(far, -(y - simbol), (y - simbol))
            v = np.where(far, -(x + LAJUR_C), (x - LAJUR_C))
            st = top & (np.abs(y - simbol) < 16) & PR.bike_stencil(u, v * 1.0)
            mi = np.where(st, 1, mi)
        if masuk is not None:
            m0, m1 = masuk
            cross = (y > m0) & (y < m1)
            dsh = top & cross & ((np.abs(ax - LAJUR[0] - 1.2) < 0.7) | (np.abs(ax - LAJUR[1] + 1.6) < 0.7)) & (np.mod(y, 4) < 2)
            mi = np.where(dsh, 1, mi)
            mi = np.where(top & cross & ~dsh & (np.abs(ax - LAJUR[1] + 1.6) < 0.7), 0, mi)
        return mi, sh
    return tex


def build_jalan(s, varian=0, marka=True, simbol=None, masuk=None, y_range=(-400, 400)):
    s.add(ground_prim(region_fn(varian, marka, masuk), MATS))
    gaps = [masuk] if masuk else []
    for sg in (-1, 1):
        a, b = (KERB_D if sg > 0 else (-KERB_D[1], -KERB_D[0]))
        PR.kerb_with_gaps(s, a, b, 3, P['kerb'], gaps)
        a, b = (LAJUR if sg > 0 else (-LAJUR[1], -LAJUR[0]))
        if masuk:
            # lajur tetap menerus, beton jalan masuk di bawahnya dari region; lajur dibuat lebih rendah di sini
            s.add(box(a, b, y_range[0], y_range[1], 0, 2, [PR.BIKE_MAT, P['mark']], lajur_tex(simbol, masuk),
                      outline=False, cast=False))
        else:
            s.add(box(a, b, y_range[0], y_range[1], 0, 2, [PR.BIKE_MAT, P['mark']], lajur_tex(simbol),
                      outline=False, cast=False))
        a, b = (KERB_L if sg > 0 else (-KERB_L[1], -KERB_L[0]))
        PR.kerb_with_gaps(s, a, b, 2.6, P['kerb'], gaps)


# ------------------------------------------------------------ potong ubin ----
W_ADEGAN, H_ADEGAN = 768, 448
OX, OY = W_ADEGAN // 2, H_ADEGAN // 2


def render_adegan(build, tname='siang'):
    s = Scene(W_ADEGAN, H_ADEGAN, OX, OY)
    build(s)
    s.render(TIMES[tname])
    s.compose()
    return np.clip(s.img, 0, 255).astype(np.uint8), s


def masker_ubin(cx, cy):
    """Piksel layar (adegan) yang pusatnya jatuh di bujur sangkar dunia [cx-16,cx+16]x[cy-16,cy+16] pada z=0."""
    py, px = np.mgrid[0:H_ADEGAN, 0:W_ADEGAN]
    sx, sy = px + 0.5 - OX, py + 0.5 - OY
    gx, gy = sy + sx / 2, sy - sx / 2
    return (np.abs(gx - cx) < U / 2) & (np.abs(gy - cy) < U / 2)


def potong(img, cx, cy):
    """Ubin 64x32: jendela tetap di sekitar pusat ubin (pusat = piksel (32, 16)), hanya piksel milik ubin ini yang
    opak. Ubin tetangga di posisi bulat (+-32, +-16) menutup sisanya tanpa celah dan tanpa tumpang tindih."""
    m = masker_ubin(cx, cy)
    X, Y = int(round(cx - cy + OX)), int(round((cx + cy) / 2 + OY))
    win = (slice(Y - 16, Y + 16), slice(X - 32, X + 32))
    mw = m[win]
    assert m.sum() == mw.sum() == 1024
    out = np.zeros((32, 64, 4), np.uint8)
    out[..., :3] = img[win]
    out[..., 3] = np.where(mw, 255, 0)
    out[~mw, :3] = 0
    return out


# kolom: nama -> pusat x (ubin dari garis tengah)
KOLOM = {'rumput_seberang': -2.5, 'trotoar_seberang': -1.5, 'aspal_seberang': -0.5,
         'aspal_dekat': 0.5, 'trotoar_dekat': 1.5, 'rumput_dekat': 2.5}


def ekspor_ubin():
    ubin = {}
    img, _ = render_adegan(lambda s: build_jalan(s))
    for nm, cxu in KOLOM.items():
        ubin[nm] = potong(img, cxu * U, 0.0)
    img_simbol, _ = render_adegan(lambda s: build_jalan(s, simbol=0.0))
    ubin['trotoar_seberang_simbol'] = potong(img_simbol, -1.5 * U, 0.0)
    ubin['trotoar_dekat_simbol'] = potong(img_simbol, 1.5 * U, 0.0)
    img_masuk, _ = render_adegan(lambda s: build_jalan(s, masuk=(-16.0, 16.0)))
    ubin['trotoar_seberang_masuk'] = potong(img_masuk, -1.5 * U, 0.0)
    ubin['trotoar_dekat_masuk'] = potong(img_masuk, 1.5 * U, 0.0)
    ubin['rumput_seberang_masuk'] = potong(img_masuk, -2.5 * U, 0.0)
    ubin['rumput_dekat_masuk'] = potong(img_masuk, 2.5 * U, 0.0)
    # ubin polos (diulang ke segala arah): kolom jauh dari kerb, tanpa marka
    for v in range(3):
        im, _ = render_adegan(lambda s, v=v: s.add(ground_prim(lambda x, y, v=v: _polos(x, y, v), MATS)))
        ubin['aspal_%d' % (v + 1)] = potong(im, 0.5 * U, 0.0)
        ubin['rumput_%d' % (v + 1)] = potong(im, 6.5 * U, 0.0)
    for nm, a in ubin.items():
        Image.fromarray(a, 'RGBA').save(OUT_DIR / ('tile_perumahan_%s.png' % nm))
    meta = {'tile': [64, 32], 'ground_anchor': [32, 16], 'unit_dunia_per_ubin': 32,
            'note': 'Usulan, tools/env_art/ubin_perumahan.py. Kolom mengikuti scripts/config.gd: aspal x -1..1 ubin '
                    '(seberang, dekat), trotoar 1 ubin per sisi (kerb dalam, lajur sepeda, kerb luar), rumput di luar. '
                    'Ubin sepanjang jalan berulang tiap 1 ubin. *_simbol: simbol sepeda dan panah; *_masuk: jalan masuk '
                    'garasi beton (kerb putus, lajur tetap menerus dengan tepi putus-putus; rumput_*_masuk menyambung ke halaman). aspal_N dan rumput_N: polos, bisa diulang ke segala arah (N=2 tambalan, '
                    'N=3 retak untuk aspal; N=3 bunga kecil untuk rumput).',
            'kolom_x_ubin': KOLOM, 'tiles': sorted('tile_perumahan_%s.png' % n for n in ubin)}
    with open(OUT_DIR / 'tile_perumahan.json', 'w') as f:
        json.dump(meta, f, indent=1, ensure_ascii=False); f.write('\n')
    return ubin


ROOT = Path(__file__).resolve().parents[2]
SALIN_KE = Path(os.environ.get('ENV_ART_SALIN_KE', ROOT / 'assets' / 'sprites' / 'tiles' / 'perumahan'))
PASANG = list(KOLOM)               # enam kolom jalan, urut dari sisi seberang ke sisi dekat (D-1)
PASANG_TAMBAHAN = ['rumput_1']     # ubin polos untuk kolom rumput di luar kolom pertama (D-2, satu-satunya pengecualian)


def meta_terpasang():
    """Isi `tile_perumahan.json` di assets/: hanya ubin yang dipasang. Titik pijak (32, 16), kolom x dalam ubin dari garis tengah."""
    return {'tile': [64, 32], 'ground_anchor': [32, 16], 'unit_dunia_per_ubin': 32,
            'note': 'Usulan, tools/env_art/ubin_perumahan.py --salin (run fase5a-pasang-aset-gelombang1). Hanya ubin yang dipasang. '
                    'Kolom mengikuti scripts/config.gd: aspal x -1..1 ubin (seberang, dekat), trotoar 1 ubin per sisi (kerb dalam, '
                    'lajur sepeda, kerb luar), rumput di luar. Ubin sepanjang jalan berulang tiap 1 ubin. rumput_1: rumput polos '
                    'untuk kolom rumput di luar kolom pertama (rumput_seberang membawa tepi kerb luar yang tidak boleh berulang).',
            'kolom_x_ubin': {nm: KOLOM[nm] for nm in PASANG},
            'ubin_polos_luar': list(PASANG_TAMBAHAN),
            'tiles': sorted('tile_perumahan_%s.png' % nm for nm in PASANG + PASANG_TAMBAHAN)}


def salin(ubin):
    """Salin HANYA ubin yang dipasang (PNG) dan JSON terpangkas ke SALIN_KE."""
    SALIN_KE.mkdir(parents=True, exist_ok=True)
    for nm in PASANG + PASANG_TAMBAHAN:
        Image.fromarray(ubin[nm], 'RGBA').save(SALIN_KE / ('tile_perumahan_%s.png' % nm))
    with open(SALIN_KE / 'tile_perumahan.json', 'w') as f:
        json.dump(meta_terpasang(), f, indent=1, ensure_ascii=False); f.write('\n')


def _polos(x, y, v):
    """Aspal polos di x < 4 ubin, rumput polos di luarnya (tanpa marka, kerb, lajur)."""
    road = np.abs(x) < 4 * U
    xw, yw = _w(x), _w(y)
    mi2 = np.where(road, 1, 0)
    sh2 = np.where(road, 1 + speckle(xw, yw, 5 + v, 0.03, 0.05, 1), 1 + grass_tufts(xw, yw, 3 + v))
    if v == 1:
        tb = road & (np.abs(xw - 14) + 0.3 * np.abs(yw - 17) < 7) & (np.abs(yw - 17) < 9)
        mi2 = np.where(tb, 4, mi2); sh2 = np.where(tb, 1 + speckle(xw, yw, 9, 0.02, 0.1, 1), sh2)
    if v == 2:
        c1 = road & (np.abs((yw - 6) - 0.55 * (xw - 6)) < 0.5) & (xw > 6) & (xw < 22)
        c2 = road & (np.abs((yw - 14) + 0.8 * (xw - 16)) < 0.5) & (xw > 14) & (xw < 21)
        mi2 = np.where(c1 | c2, 4, mi2); sh2 = np.where(c1 | c2, 2, sh2)
        h = hash2(np.floor(xw / 4), np.floor(yw / 4), 77)
        fl = (~road) & (h > 0.9) & (np.mod(xw, 4) < 1) & (np.mod(yw, 4) < 1)
        mi2 = np.where(fl, 2, mi2); sh2 = np.where(fl, 0, sh2)
    return mi2, sh2


# ------------------------------------------------------------ uji ulang susun ----
def susun(ubin_kolom, n_maju=6):
    """Susun ubin per kolom menjadi potongan jalan (untuk mengecek sambungan)."""
    W, H = 64 * 8, 32 * 9
    out = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ox, oy = W // 2 - 60, H // 2 + 40
    for m in range(-n_maju, n_maju + 1):
        for nm, cxu in KOLOM.items():
            t = ubin_kolom(nm, m)
            if t is None:
                continue
            cx, cy = cxu * U, -m * U
            sx, sy = cx - cy + ox, (cx + cy) / 2 + oy
            out.alpha_composite(Image.fromarray(t, 'RGBA'), (int(sx - 32), int(sy - 16)))
    return out


def cek_sambungan(ubin):
    """Bandingkan ubin yang disusun ulang dengan adegan aslinya: harus identik."""
    img, _ = render_adegan(lambda s: build_jalan(s))
    beda = 0
    for nm, cxu in KOLOM.items():
        for m in (-1, 0, 1):
            a = potong(img, cxu * U, m * U)
            beda += int(np.abs(a.astype(int) - ubin[nm].astype(int)).sum())
    return beda


if __name__ == '__main__':
    u = ekspor_ubin()
    print('beda sambungan:', cek_sambungan(u))
    print('selesai ->', OUT_DIR)
    if '--salin' in sys.argv[1:]:
        salin(u)
        print('disalin ke', SALIN_KE, '(hanya', len(PASANG) + len(PASANG_TAMBAHAN), 'ubin dan JSON terpangkas)')
