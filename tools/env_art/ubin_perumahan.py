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
(dibuat skrip, bukan salinan JSON penuh di build/). Ubin lain (aspal_N, *_dekat_masuk; run 5B memasang simbol, masuk seberang, rumput_2 dan 3) tetap hanya di build/.
`ENV_ART_SALIN_KE` mengganti folder tujuan (dipakai tools/tests_cek/uji_aset_pasang_gelombang1.py). Polisi tidur kuning-hitam lama
sudah dibuang dari ekspor (K-1 run 5A): satu-satunya polisi tidur adalah `tile_perumahan_polisi_tidur` di tools/env_art/gelombang1/.

Run fase5b-tembok-dekor (D-1 dan D-4) menambah ke `--salin`: `rumput_2` dan `rumput_3` (variasi rumput polos, `PASANG_TAMBAHAN`) dan empat ubin
khusus (`PASANG_KHUSUS`): `trotoar_seberang_masuk` dan `rumput_seberang_masuk` (jalan masuk garasi, hanya sisi seberang), `trotoar_seberang_simbol`
dan `trotoar_dekat_simbol` (simbol sepeda). `aspal_1..3` (polos tanpa garis tepi kerb, memutus garis) dan `*_dekat_masuk` TIDAK disalin.

Run fase5c-animasi-simpang (C-F1 run 5B, D-2 dan D-3 run 5C) menambah ke `--salin`: dua ubin ujung kerb jalan masuk sisi seberang (`PASANG_UJUNG`:
`trotoar_seberang_masuk_ujung`, `rumput_seberang_masuk_ujung`, baris maju + 1 dari baris jalan masuk; hanya sel yang pada adegan jalan masuk berbeda dari ubin
lurus, dihitung, bukan didaftar tangan) dan ubin simpang T hiasan untuk sisi yang dipakai data segmen (`SIMPANG_SISI_DIPASANG`; hanya ubin yang berbeda dari jalan lurus,
pola `ekspor_simpang`). JSON terpangkas membawa `ubin_ujung_kerb`, `ujung_kerb_baris_relatif`, dan `simpang` (y mulut renderer, lebar mulut, pita baris, sel per sisi
dengan baris relatif maju) yang dijaga sama dengan konstanta `scripts/config.gd` oleh tes. `*_dekat_masuk`, `aspal_N`, dan ubin simpang sisi yang tidak dipakai TIDAK disalin.
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



# ------------------------------------------------------------ simpang T (Fase 5C, usulan) ----
# Jalan samping (aspal 2 ubin, tanpa marka) keluar tegak lurus dari jalan utama ke satu sisi, di antara dua baris ubin
# (y -48..16, baris berpusat y = -32 dan 0). Trotoar jalan utama (kerb dalam, lajur sepeda, kerb luar) membelok siku
# ke jalan samping, jadi tiap mulut simpang punya sudut luar (di tepi aspal) dan sudut dalam (di sisi rumput).
SIMPANG_Y = (-48.0, 16.0)


def _d_trotoar(x, y, sg):
    """Jarak ke tepi aspal terdekat (jalan utama atau jalan samping) untuk titik di sisi simpang."""
    ya, yb = SIMPANG_Y
    dm = sg * x - A
    ds = np.where(y < ya, ya - y, np.where(y > yb, y - yb, 0.0))
    return np.where(sg * x >= A, np.minimum(dm, ds), dm)


def region_simpang(sg):
    base = region_fn()
    ya, yb = SIMPANG_Y

    def region(x, y):
        mi, sh = base(x, y)
        xw, yw = _w(x), _w(y)
        mulut = (sg * x >= A - 4) & (y > ya) & (y < yb)          # mulut simpang + garis tepi yang terputus
        mi = np.where(mulut, 1, mi)
        sh = np.where(mulut, 1 + speckle(xw, yw, 5, 0.03, 0.05, 1), sh)
        return mi, sh
    return region


def lajur_tex_simpang(sg):
    """Seperti lajur_tex(), tetapi garis tepi luar mengikuti belokan siku ke jalan samping."""
    def tex(Pw, Nw):
        x, y = Pw[:, 0], Pw[:, 1]
        top = Nw[:, 2] > 0.5
        d = _d_trotoar(x, y, sg)
        mi = np.zeros(len(x), int)
        sh = np.where(top, 1, 0)
        sh = np.where(top & (hash2(np.floor(_w(x)), np.floor(_w(y)), 11) > 0.93), 2, sh)
        line = top & (d > LAJUR[1] - 2.2 - A) & (d < LAJUR[1] - 1.0 - A)
        mi = np.where(line, 1, mi)
        return mi, sh
    return tex


def _xs(sg, a, b):
    """Rentang x [a, b] (jarak dari garis tengah) di sisi sg, terurut."""
    return (a, b) if sg > 0 else (-b, -a)


def build_simpang(s, sg):
    """sg = +1: simpang ke sisi dekat, -1: ke sisi seberang. Sisi lain jalan utama tetap lurus."""
    s.add(ground_prim(region_simpang(sg), MATS))
    ya, yb = SIMPANG_Y
    # sisi tanpa simpang: sama dengan build_jalan
    o = -sg
    PR.kerb_with_gaps(s, *_xs(o, *KERB_D), 3, P['kerb'], [])
    s.add(box(*_xs(o, *LAJUR), -900, 900, 0, 2, [PR.BIKE_MAT, P['mark']], lajur_tex(), outline=False, cast=False))
    PR.kerb_with_gaps(s, *_xs(o, *KERB_L), 2.6, P['kerb'], [])
    # sisi simpang: dua blok (depan y < ya, belakang y > yb), trotoar membelok siku ke jalan samping
    lt = lajur_tex_simpang(sg)
    for blk in (-1, 1):
        def yr(off_main):
            """rentang y lengan jalan utama yang berhenti `off_main` unit sebelum tepi jalan samping."""
            return (-900, ya - off_main) if blk < 0 else (yb + off_main, 900)

        def ys(d0, d1):
            """rentang y lengan jalan samping, d0..d1 unit dari tepi aspalnya."""
            return (ya - d1, ya - d0) if blk < 0 else (yb + d0, yb + d1)
        k0 = KERB_D[0] - A; k1 = KERB_D[1] - A; l1 = LAJUR[1] - A; e1 = KERB_L[1] - A
        # jalan utama
        s.add(box(*_xs(sg, *KERB_D), *yr(0), 0, 3, P['kerb'], outline=False, cast=False))
        s.add(box(*_xs(sg, *LAJUR), *yr(k1), 0, 2, [PR.BIKE_MAT, P['mark']], lt, outline=False, cast=False))
        s.add(box(*_xs(sg, *KERB_L), *yr(l1), 0, 2.6, P['kerb'], outline=False, cast=False))
        # jalan samping
        s.add(box(*_xs(sg, KERB_D[0], 900), *ys(k0, k1), 0, 3, P['kerb'], outline=False, cast=False))
        s.add(box(*_xs(sg, LAJUR[0], 900), *ys(k1, l1), 0, 2, [PR.BIKE_MAT, P['mark']], lt, outline=False, cast=False))
        s.add(box(*_xs(sg, KERB_L[0], 900), *ys(l1, e1), 0, 2.6, P['kerb'], outline=False, cast=False))

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
    # ujung kerb (C-F1, run 5C): sel tetangga jalan masuk sisi seberang yang pada adegan jalan masuk berbeda dari ubin lurus (kerb yang putus di baris
    # jalan masuk tidak lagi menjorok ke sel tetangga). Dihitung, lalu dicocokkan dengan UJUNG_SEL supaya perubahan adegan tidak lolos diam-diam.
    beda_ujung = []
    for cy in (-1, 1):
        for nm in ('rumput_seberang', 'trotoar_seberang', 'aspal_seberang'):
            t = potong(img_masuk, KOLOM[nm] * U, cy * U)
            if not (t == potong(img, KOLOM[nm] * U, cy * U)).all():
                beda_ujung.append((nm, -cy))
                ubin[nm + '_masuk_ujung'] = t
    assert sorted(beda_ujung) == sorted(UJUNG_SEL), 'sel ujung kerb berubah: %s' % beda_ujung
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
                    'N=3 retak untuk aspal; N=3 bunga kecil untuk rumput). *_masuk_ujung: ujung kerb di baris maju + 1 dari jalan masuk sisi seberang.',
            'kolom_x_ubin': KOLOM, 'tiles': sorted('tile_perumahan_%s.png' % n for n in ubin)}
    with open(OUT_DIR / 'tile_perumahan.json', 'w') as f:
        json.dump(meta, f, indent=1, ensure_ascii=False); f.write('\n')
    return ubin


ROOT = Path(__file__).resolve().parents[2]
SALIN_KE = Path(os.environ.get('ENV_ART_SALIN_KE', ROOT / 'assets' / 'sprites' / 'tiles' / 'perumahan'))
PASANG = list(KOLOM)               # enam kolom jalan, urut dari sisi seberang ke sisi dekat (D-1)
PASANG_TAMBAHAN = ['rumput_1', 'rumput_2', 'rumput_3']   # ubin polos untuk kolom rumput di luar kolom pertama (D-2 run 5A; rumput_2 dan 3: D-1 run 5B)
PASANG_KHUSUS = ['trotoar_seberang_masuk', 'rumput_seberang_masuk', 'trotoar_seberang_simbol', 'trotoar_dekat_simbol']   # D-1 dan D-7 run 5B
# Ujung kerb jalan masuk sisi seberang (C-F1, run 5C): (kolom, baris maju relatif ke baris jalan masuk). Sel ini satu-satunya yang berbeda dari ubin lurus di baris
# tetangga sisi seberang (diperiksa `ekspor_ubin`): kerb dalam dan luar yang berhenti di tepi jalan masuk.
UJUNG_SEL = [('trotoar_seberang', 1), ('rumput_seberang', 1)]
PASANG_UJUNG = [nm + '_masuk_ujung' for nm, _ in UJUNG_SEL]
# Sisi simpang T yang dipasang (D-2 run 5C: hanya ubin yang dipakai data segmen). Sisi seberang belum dipakai data (lihat LOG run 5C, D-4), jadi ubinnya hanya di build/.
SIMPANG_SISI_DIPASANG = ['dekat']


def meta_terpasang(meta_simpang):
    """Isi `tile_perumahan.json` di assets/: hanya ubin yang dipasang. Titik pijak (32, 16), kolom x dalam ubin dari garis tengah."""
    return {'tile': [64, 32], 'ground_anchor': [32, 16], 'unit_dunia_per_ubin': 32,
            'note': 'Usulan, tools/env_art/ubin_perumahan.py --salin (run fase5a-pasang-aset-gelombang1 dan fase5b-tembok-dekor). Hanya ubin yang dipasang. '
                    'Kolom mengikuti scripts/config.gd: aspal x -1..1 ubin (seberang, dekat), trotoar 1 ubin per sisi (kerb dalam, '
                    'lajur sepeda, kerb luar), rumput di luar. Ubin sepanjang jalan berulang tiap 1 ubin. rumput_1, rumput_2, rumput_3: rumput polos '
                    'untuk kolom rumput di luar kolom pertama (rumput_seberang membawa tepi kerb luar yang tidak boleh berulang; 2 dan 3 variasi, 3 '
                    'dengan bunga kecil). ubin_khusus: pengganti satu sel kolomnya (*_masuk: jalan masuk garasi beton di bawah mobil parkir, hanya '
                    'sisi seberang; *_simbol: simbol sepeda dan panah di lajur sepeda trotoar). ubin_ujung_kerb (run fase5c): ujung kerb di baris '
                    'maju + ujung_kerb_baris_relatif dari jalan masuk sisi seberang. simpang (run fase5c, usulan, hiasan): ubin simpang T per sisi terpasang; baris_relatif = '
                    'maju dari baris mulut_2 (pos data segmen), kolom lengan berulang ke luar sejauh kolom yang tampil.',
            'kolom_x_ubin': {nm: KOLOM[nm] for nm in PASANG},
            'ubin_polos_luar': list(PASANG_TAMBAHAN),
            'ubin_khusus': list(PASANG_KHUSUS),
            'ubin_ujung_kerb': list(PASANG_UJUNG),
            'ujung_kerb_baris_relatif': UJUNG_SEL[0][1],
            'simpang': meta_simpang_terpasang(meta_simpang),
            'tiles': sorted('tile_perumahan_%s.png' % nm for nm in PASANG + PASANG_TAMBAHAN + PASANG_KHUSUS + PASANG_UJUNG + nama_simpang_terpasang(meta_simpang))}


def nama_simpang_terpasang(meta_simpang):
    """Nama ubin simpang (tanpa awalan dan .png) untuk sisi di SIMPANG_SISI_DIPASANG, urut seperti ekspor."""
    return [d['file'][len('tile_perumahan_'):-len('.png')] for sisi in SIMPANG_SISI_DIPASANG for d in meta_simpang['sisi'][sisi]]


def meta_simpang_terpasang(meta_simpang):
    """Bagian `simpang` JSON terpangkas (D-3 run 5C): y mulut renderer (unit dunia), lebar mulut (ubin), pita baris relatif maju (semua baris yang ubinnya diganti di
    kolom trotoar, rumput, atau lengan, kedua sisi yang dirender), dan sel per sisi terpasang dengan baris relatif maju (= -baris_y_ubin renderer; baris 0 = `mulut_2`)."""
    baris = sorted({-d['baris_y_ubin'] for l in meta_simpang['sisi'].values() for d in l if abs(d['kolom_x_ubin']) >= 1.5})
    kolom = {0.5: 'aspal', 1.5: 'trotoar', 2.5: 'rumput', 3.5: 'lengan'}
    return {'y_mulut_unit': list(SIMPANG_Y), 'lebar_mulut_ubin': (SIMPANG_Y[1] - SIMPANG_Y[0]) / U,
            'pita_baris_relatif': [baris[0], baris[-1]],
            'sisi': {sisi: [{'nama': d['file'][len('tile_perumahan_'):-len('.png')], 'kolom': kolom[abs(d['kolom_x_ubin'])],
                             'kolom_x_ubin': d['kolom_x_ubin'], 'baris_relatif': -d['baris_y_ubin'], 'berulang_ke_luar': d['berulang_ke_luar']}
                            for d in meta_simpang['sisi'][sisi]] for sisi in SIMPANG_SISI_DIPASANG}}


def salin(ubin, hasil_simpang, meta_simpang):
    """Salin HANYA ubin yang dipasang (PNG) dan JSON terpangkas ke SALIN_KE."""
    SALIN_KE.mkdir(parents=True, exist_ok=True)
    for nm in PASANG + PASANG_TAMBAHAN + PASANG_KHUSUS + PASANG_UJUNG:
        Image.fromarray(ubin[nm], 'RGBA').save(SALIN_KE / ('tile_perumahan_%s.png' % nm))
    for nm in nama_simpang_terpasang(meta_simpang):
        Image.fromarray(hasil_simpang[nm], 'RGBA').save(SALIN_KE / ('tile_perumahan_%s.png' % nm))
    with open(SALIN_KE / 'tile_perumahan.json', 'w') as f:
        json.dump(meta_terpasang(meta_simpang), f, indent=1, ensure_ascii=False); f.write('\n')


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


def cek_masuk(ubin):
    """Susun ulang jalan masuk sisi seberang dari ubin terpasang (baris jalan masuk: *_masuk, baris maju + 1: *_masuk_ujung, lain: lurus, kolom luar rumput_1)
    dan bandingkan dengan adegan jalan masuk: harus identik (C-F1 run 5C; sebelumnya 22 piksel ujung kerb)."""
    img, _ = render_adegan(lambda s: build_jalan(s, masuk=(-16.0, 16.0)))
    ujung = {nm: r for nm, r in UJUNG_SEL}
    beda = 0
    for cy in range(-3, 4):
        for nm, cxu in list(KOLOM.items())[:3] + [('rumput_1', -3.5), ('rumput_1', -4.5)]:
            if cy == 0 and nm in ('trotoar_seberang', 'rumput_seberang'):
                t = ubin[nm + '_masuk']
            elif nm in ujung and -cy == ujung[nm]:
                t = ubin[nm + '_masuk_ujung']
            else:
                t = ubin[nm]
            beda += int(np.abs(t.astype(int) - potong(img, cxu * U, cy * U).astype(int)).sum())
    return beda


# ------------------------------------------------------------ ekspor simpang T ----
SIMPANG_BARIS = {-3: 'depan_2', -2: 'depan_1', -1: 'mulut_1', 0: 'mulut_2', 1: 'belakang_1', 2: 'belakang_2'}


def ekspor_simpang():
    """Ubin simpang T ke sisi dekat dan sisi seberang: hanya ubin yang berbeda dari ubin jalan lurus.
    Kolom di luar rumput (|x| >= 3,5 ubin) adalah lengan jalan samping yang berulang tiap 1 ubin ke luar."""
    out_dir = OUT_DIR / 'simpang'
    out_dir.mkdir(parents=True, exist_ok=True)
    lurus, _ = render_adegan(lambda s: build_jalan(s))
    meta = {'tile': [64, 32], 'ground_anchor': [32, 16], 'status': 'usulan Fase 5C',
            'note': 'Simpang T: jalan samping aspal 2 ubin di antara baris y = -1 (mulut_1) dan y = 0 (mulut_2) ubin. '
                    'Pasang ubin ini di posisi (kolom_x_ubin, baris_y_ubin) relatif ke ubin jalan lurus baris 0; '
                    'kolom lengan berulang ke luar tiap 1 ubin. Sel lain tetap ubin jalan lurus.',
            'sisi': {}}
    hasil = {}
    for sg, sisi in ((1, 'dekat'), (-1, 'seberang')):
        img, _ = render_adegan(lambda s, sg=sg: build_simpang(s, sg))
        nama_kolom = {0.5 * sg: 'aspal_' + sisi, 1.5 * sg: 'trotoar_' + sisi, 2.5 * sg: 'rumput_' + sisi}
        daftar = []
        for cy in sorted(SIMPANG_BARIS):
            lengan = [potong(img, cx * U, cy * U) for cx in (3.5 * sg, 4.5 * sg, 5.5 * sg)]
            assert all((t == lengan[0]).all() for t in lengan), 'lengan simpang tidak berulang'
            for cxu in (0.5 * sg, 1.5 * sg, 2.5 * sg, 3.5 * sg):
                a = potong(img, cxu * U, cy * U)
                if (a == potong(lurus, cxu * U, cy * U)).all():
                    continue
                kol = nama_kolom.get(cxu, 'lengan')
                nm = 'simpang_%s_%s_%s' % (sisi, kol, SIMPANG_BARIS[cy])
                Image.fromarray(a, 'RGBA').save(out_dir / ('tile_perumahan_%s.png' % nm))
                hasil[nm] = a
                daftar.append({'file': 'tile_perumahan_%s.png' % nm, 'kolom_x_ubin': cxu, 'baris_y_ubin': cy,
                               'berulang_ke_luar': kol == 'lengan'})
        meta['sisi'][sisi] = daftar
    with open(out_dir / 'tile_perumahan_simpang.json', 'w') as f:
        json.dump(meta, f, indent=1, ensure_ascii=False); f.write('\n')
    return hasil, meta


def cek_simpang(meta):
    """Susun ulang potongan simpang dari ubin (baru + lurus) dan bandingkan dengan adegannya: harus identik."""
    lurus, _ = render_adegan(lambda s: build_jalan(s))
    beda = 0
    for sg, sisi in ((1, 'dekat'), (-1, 'seberang')):
        img, _ = render_adegan(lambda s, sg=sg: build_simpang(s, sg))
        pos = {(d['kolom_x_ubin'], d['baris_y_ubin']): d for d in meta['sisi'][sisi]}
        for cy in range(-4, 4):
            for k in range(-6, 6):          # kedua sisi jalan, sampai 3 ubin lengan ke luar
                cxu = sg * (k + 0.5)
                key = (cxu, cy)
                if key in pos:
                    t = np.array(Image.open(OUT_DIR / 'simpang' / pos[key]['file']))
                elif sg * cxu >= 3.5 and (sg * 3.5, cy) in pos:
                    t = np.array(Image.open(OUT_DIR / 'simpang' / pos[(sg * 3.5, cy)]['file']))
                else:
                    t = potong(lurus, cxu * U, cy * U)
                beda += int(np.abs(t.astype(int) - potong(img, cxu * U, cy * U).astype(int)).sum())
    return beda


if __name__ == '__main__':
    u = ekspor_ubin()
    print('beda sambungan:', cek_sambungan(u))
    print('beda sambungan masuk seberang:', cek_masuk(u))
    hasil_simpang, meta_simpang = ekspor_simpang()
    print('beda sambungan simpang:', cek_simpang(meta_simpang))
    print('selesai ->', OUT_DIR)
    if '--salin' in sys.argv[1:]:
        salin(u, hasil_simpang, meta_simpang)
        n = len(PASANG) + len(PASANG_TAMBAHAN) + len(PASANG_KHUSUS) + len(PASANG_UJUNG) + len(nama_simpang_terpasang(meta_simpang))
        print('disalin ke', SALIN_KE, '(hanya', n, 'ubin dan JSON terpangkas)')
