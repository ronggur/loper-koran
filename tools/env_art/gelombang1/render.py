"""Aset gelombang 1 Fase 5 (usulan): bangun semua sprite 1x + JSON per sprite + manifest, papan pratinjau, dan komposisi.

Dari root repo (butuh numpy dan pillow, seperti tools/env_art):
    python3 tools/env_art/gelombang1/render.py            # ke build/env_art/gelombang1/{sprites,board}/
    python3 tools/env_art/gelombang1/render.py --mock     # juga salin mock terpilih ke docs/design/environment/gelombang1/
    python3 tools/env_art/gelombang1/render.py --salin    # juga salin HANYA sprite yang dipasang (PASANG) ke assets/sprites/{props,vfx,houses/perumahan}/
Keluaran bisa dipindah dengan ENV_ART_OUT (folder induk, sama dengan renderer env_art lain). Hasil deterministik.
`--salin` (run fase5a-pasang-aset-gelombang1, D-1): 13 sprite (PNG + JSON) dipasang di rute: koran ke props/, VFX sepeda, bintang, koin,
dan kilau misi ke vfx/. Run fase5b-tembok-dekor (D-1): ditambah lima tembok sisi dekat (`house_tembok_{polos,bata,besi,pot,tiang}`) ke
houses/perumahan/ dan `prop_tong_sampah_logam` ke props/ (tong biru TIDAK, K-2). Aset lain (jejak, mangkuk, portal, pos, percikan, ubin)
TIDAK disalin; ubin jalan disalin `tools/env_art/ubin_perumahan.py --salin`. `ENV_ART_MOCK_KE` mengganti folder mock `--mock`. `ENV_ART_SALIN_KE` mengganti folder induk tujuan (default assets/sprites; dipakai
tools/tests_cek/uji_aset_pasang_gelombang1.py). Tiga penyesuaian K-1 (2026-10-21): kilau dua warna, tong sampah logam dan biru
(hijau dibuang), polisi tidur kuning-hitam lama dibuang dari ubin_perumahan.py.
"""
import json
import os
import shutil
import sys
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np
from PIL import Image

from pxcore import *
import koran as K_
import vfx as V
import properti as PR
import tembok_ubin as T
import komposisi as scene
import sumber

OUTDIR = Path(os.environ.get('ENV_ART_OUT', sumber.ROOT / 'build' / 'env_art')) / 'gelombang1'
SPR = str(OUTDIR / 'sprites')
BRD = str(OUTDIR / 'board')
MOCK = Path(os.environ.get('ENV_ART_MOCK_KE', sumber.ROOT / 'docs' / 'design' / 'environment' / 'gelombang1'))
os.makedirs(SPR, exist_ok=True)
os.makedirs(BRD, exist_ok=True)

SALIN_KE = Path(os.environ.get('ENV_ART_SALIN_KE', sumber.ROOT / 'assets' / 'sprites'))
# Hanya yang dipasang di rute (D-1): folder tujuan -> nama sprite (tanpa ekstensi).
PASANG = {
    'props': ['prop_koran_putar', 'prop_koran_bayangan', 'prop_koran_teras', 'prop_koran_rumput', 'prop_koran_kotak_surat',
              'prop_koran_terlipat'],
    'vfx': ['vfx_debu_roda', 'vfx_garis_kecepatan_a', 'vfx_garis_kecepatan_b', 'vfx_garis_kecepatan_c', 'vfx_bintang_kena',
            'vfx_koin_tip', 'mission_kilau'],
}
# Tambahan run fase5b-tembok-dekor (D-1): isi pasangan 5A di atas tidak berubah.
PASANG_5B = {
    'houses/perumahan': ['house_tembok_polos', 'house_tembok_bata', 'house_tembok_besi', 'house_tembok_pot', 'house_tembok_tiang'],
    'props': ['prop_tong_sampah_logam'],
}

PANEL = (0x34, 0x27, 0x1F, 255)
CELL_LINE = (0x5A, 0x46, 0x3A, 255)
ANCHOR = (0xFF, 0x4F, 0xD8, 255)    # penanda presentasi saja, bukan palet game

# ----------------------------------------------------------- daftar sprite
# (papan, nama_file, frames, fps, pijak, catatan)
S = []
def add(board, name, frames, fps, anchor, note, test=True):
    S.append(dict(board=board, name=name, frames=frames, fps=fps, anchor=anchor, note=note, test=test))

add('koran', 'prop_koran_putar', K_.koran_spin(), 12, (5, 5),
    'Berputar maju: mendatar, serong naik, tegak, serong turun. Pijak = pusat putar; tinggi diatur kode, bayangan terpisah.')
add('koran', 'prop_koran_bayangan', K_.koran_bayangan(), 0, (6, 3),
    'Pilih frame dari tinggi koran: 10 px (rendah), 8 px, 6 px (tinggi). Warna penanda.')
add('koran', 'prop_koran_teras', [K_.koran_teras()], 0, (6, 6),
    'Gulungan tergeletak di lantai keras, sejajar jalan.')
add('koran', 'prop_koran_rumput', [K_.koran_rumput()], 0, (6, 6),
    'Gulungan sama, kakinya tertutup dua jumput rumput.')
add('koran', 'prop_koran_kotak_surat', [K_.koran_kotak_surat()], 0, (-3, 19),
    'Tumpangan di atas kotak surat yang ada: pijak kotak surat = piksel (-3, 19) sel ini, jadi ujung gulungan keluar dari celah sisi kanan.')
add('koran', 'prop_koran_terlipat', [K_.koran_terlipat()], 0, (7, 5),
    'Pose "terantar": koran terlipat rata di teras, kepala berita dongker.')

add('vfx', 'vfx_debu_roda', V.debu_roda(), 12, (14, 7),
    'Loop. Pijak = titik roda belakang di tanah. Kotak 2x2 lalu 1x1 mundur 2 px kiri, 1 px turun per frame.')
gk = V.garis_kecepatan()
for k, g in zip('abc', gk):
    add('vfx', f'vfx_garis_kecepatan_{k}', [g], 0, (27, 7),
        'Putih alfa 70 persen, anak tangga 2x1. Tanpa garis luar. Diacak tiap 2-3 frame saat ngebut.')
add('vfx', 'vfx_bintang_kena', V.bintang_kena(), 15, (7, 7),
    'Sekali main. Bintang 4 sudut + 4 sinar pendek berputar 90 derajat lalu pecah jadi serpih.')
add('vfx', 'vfx_koin_tip', V.koin_tip(), 10, (8, 24),
    'Sekali main. Koin naik 16 px sambil berputar (lebar 6/4/2), lalu "+5" tinggal sendiri.')
add('vfx', 'vfx_percikan_genangan', V.percikan(), 12, (12, 12),
    'M3. Sekali main. Mahkota air, tetes jatuh, cincin melebar lalu putus-putus.')

add('properti', 'prop_tong_sampah_logam', [PR.tong_sampah('logam')], 0, (10, 25),
    'Tong bulat bertutup abu-abu logam (K-1: hijau dibuang), tapak r 7 unit.')
add('properti', 'prop_tong_sampah_biru', [PR.tong_sampah('biru')], 0, (10, 25),
    'Palette swap dari versi logam. Biru tidak bentrok token semantik DESIGN_SPEC 1.1.')
add('properti', 'mission_jejak_kucing_1', [PR.jejak_kucing(1)], 0, (2, 18),
    'Lurus sepanjang jalan, naik ke kanan atas. Decal tanah tanpa garis luar.')
add('properti', 'mission_jejak_kucing_2', [PR.jejak_kucing(2)], 0, (2, 18),
    'Berbelok masuk ke halaman.')
add('properti', 'mission_mangkuk_kucing', [PR.mangkuk_kucing()], 0, (7, 8),
    'Mangkuk pink berisi pelet.')
add('properti', 'mission_kilau', PR.kilau_misi(), 4, (4, 4),
    'Loop 2 frame. Pijak = pusat; dipasang 12-16 px di atas benda petunjuk.')
add('properti', 'prop_portal_satpam', [PR.portal_satpam(False), PR.portal_satpam(True)], 0, (14, 48),
    'M3. Frame 0 tertutup, frame 1 terbuka. Pijak = kaki tiang. Palang 52 unit melintang jalan.')
add('properti', 'prop_pos_satpam', [PR.pos_satpam()], 0, (32, 50),
    'M3. Pos 20x24 unit, jendela menghadap jalan samping, pintu di sisi kiri bawah.')

for v in ('polos', 'bata', 'besi', 'pot'):
    add('dekat', f'house_tembok_{v}', [T.tembok(v)], 0, T.WALL_ANCHOR,
        'Modul 1 ubin, tinggi 14. Sambung: modul berikut digeser (-32, +16) px.')
add('dekat', 'house_tembok_tiang', [T.tembok_tiang_ujung()], 0, T.WALL_ANCHOR,
    'Tiang penutup di ujung kiri bawah rantai modul.')

add('ubin', 'tile_perumahan_polisi_tidur', [T.ubin_polisi_tidur()], 0, (32, 16),
    'Satu ubin per lajur aspal (dipakai di kedua lajur).', test=False)
add('ubin', 'tile_perumahan_zebra', [T.ubin_zebra()], 0, (32, 16),
    'Persimpangan: zebra cross di kedua lajur aspal, jalan samping memakai aspal polos.', test=False)
add('ubin', 'tile_perumahan_genangan', [T.ubin_genangan()], 0, (32, 16),
    'Genangan di aspal; percikan dipicu saat sepeda lewat.', test=False)


# ----------------------------------------------------------- latar uji
def _tiled(tile, w, h):
    out = np.zeros((h, w, 4), np.uint8)
    for j in range(-2, h // 16 + 3):
        for i in range(-2, w // 64 + 3):
            x = i * 64 + (32 if j % 2 else 0)
            paste(out, tile, x - 32, j * 16 - 16)
    return out


def bg_patch(kind, w, h):
    if kind == 'aspal':
        return _tiled(sumber.ubin('aspal_polos'), w, h)
    if kind == 'rumput':
        return _tiled(sumber.ubin('rumput_polos'), w, h)
    rng = np.random.default_rng(7)
    out = np.zeros((h, w, 4), np.uint8); out[:] = TROTOAR[0]
    out[rng.random((h, w)) < 0.18] = TROTOAR[1]
    return out


def up(a, k):
    return np.kron(a, np.ones((k, k, 1), np.uint8))


def x5_sheet(frames, anchor, k=5, pad=3):
    cw = max(f.shape[1] for f in frames); ch = max(f.shape[0] for f in frames)
    W = len(frames) * (cw * k + pad * 2) + (len(frames) - 1) * 8
    Hh = ch * k + pad * 2
    out = np.zeros((Hh, W, 4), np.uint8)
    x = 0
    for f in frames:
        box = np.zeros((ch * k + pad * 2, cw * k + pad * 2, 4), np.uint8); box[:] = PANEL
        box[pad - 1, :] = CELL_LINE; box[-pad, :] = CELL_LINE
        box[:, pad - 1] = CELL_LINE; box[:, -pad] = CELL_LINE
        paste(box, up(f, k), pad, pad)
        ax, ay = anchor
        if 0 <= ax < cw and 0 <= ay < ch:
            x0, y0 = pad + ax * k, pad + ay * k
            box[y0:y0 + k, x0] = ANCHOR; box[y0:y0 + k, x0 + k - 1] = ANCHOR
            box[y0, x0:x0 + k] = ANCHOR; box[y0 + k - 1, x0:x0 + k] = ANCHOR
            cx, cy = x0 + k // 2, y0 + k // 2
            box[cy, max(0, x0 - 4):x0] = ANCHOR; box[cy, x0 + k:x0 + k + 4] = ANCHOR
            box[max(0, y0 - 4):y0, cx] = ANCHOR; box[y0 + k:y0 + k + 4, cx] = ANCHOR
        out[:, x:x + box.shape[1]] = box
        x += box.shape[1] + 8
    return out


def x3_test(frames, k=3, margin=6):
    cw = max(f.shape[1] for f in frames); ch = max(f.shape[0] for f in frames)
    rows = []
    for kind in ('aspal', 'trotoar', 'rumput'):
        w = len(frames) * (cw + margin) + margin
        h = ch + 2 * margin
        bg = bg_patch(kind, w, h)
        for i, f in enumerate(frames):
            paste(bg, f, margin + i * (cw + margin), margin)
        rows.append(up(bg, k))
    gap = np.zeros((6, rows[0].shape[1], 4), np.uint8)
    return np.concatenate([rows[0], gap, rows[1], gap, rows[2]], 0)


manifest = []
for s in S:
    fr = s['frames']
    cw = max(f.shape[1] for f in fr); ch = max(f.shape[0] for f in fr)
    fr = [pad_to(f, cw, ch, 0, 0) for f in fr]
    Image.fromarray(hstack(fr), 'RGBA').save(os.path.join(SPR, s['name'] + '.png'))
    Image.fromarray(x5_sheet(fr, s['anchor']), 'RGBA').save(os.path.join(BRD, 'x5_' + s['name'] + '.png'))
    if s['test']:
        Image.fromarray(x3_test(fr), 'RGBA').save(os.path.join(BRD, 'x3_' + s['name'] + '.png'))
    meta = {'sprite': s['name'] + '.png', 'cell': [cw, ch], 'frames': len(fr), 'fps': s['fps'],
            'ground_anchor': [int(v) for v in s['anchor']], 'board': s['board'],
            'note': 'Usulan, tools/env_art/gelombang1 (Fase 5 gelombang 1). Frame berjajar kiri ke kanan. ' + s['note']}
    with open(os.path.join(SPR, s['name'] + '.json'), 'w') as f:
        json.dump(meta, f, indent=1, ensure_ascii=False)
        f.write('\n')
    manifest.append(meta)
with open(os.path.join(SPR, 'manifest.json'), 'w') as f:
    json.dump(manifest, f, indent=1, ensure_ascii=False)
    f.write('\n')

# ----------------------------------------------------------- komposisi
a = scene.build(False); b = scene.build(True)
Image.fromarray(up(a, 3)).save(os.path.join(BRD, 'komposisi_siang_x3.png'))
Image.fromarray(up(b, 3)).save(os.path.join(BRD, 'komposisi_sore_x3.png'))
Image.fromarray(a).save(os.path.join(SPR, 'komposisi_siang_1x.png'))
Image.fromarray(b).save(os.path.join(SPR, 'komposisi_sore_1x.png'))
c = scene.build(False, minimal=True)
Image.fromarray(up(c, 3)).save(os.path.join(BRD, 'sisi_dekat_siang_x3.png'))

# rantai tembok di atas rumput (x3) untuk melihat sambungan
chain = np.zeros((176, 330, 4), np.uint8); chain[:] = P['rumput'][1]
seq = ['polos', 'bata', 'besi', 'pot', 'polos', 'pot', 'bata', 'besi']
wim = {v: T.tembok(v) for v in set(seq)}
bx, by = 300, 4
ax_, ay_ = T.WALL_ANCHOR
for i, v in enumerate(seq):
    paste(chain, wim[v], bx - 32 * i - ax_ + 3, by + 16 * i - ay_ + 20)
paste(chain, T.tembok_tiang_ujung(), bx - 32 * len(seq) - ax_ + 3, by + 16 * len(seq) - ay_ + 20)
Image.fromarray(up(chain, 3)).save(os.path.join(BRD, 'tembok_rantai_x3.png'))

# potongan jalan dengan ubin baru (x3)
patch = scene.potongan_ubin()
Image.fromarray(up(patch, 3)).save(os.path.join(BRD, 'ubin_potongan_x3.png'))

MOCK_PILIH = ['komposisi_siang_x3.png', 'komposisi_sore_x3.png', 'sisi_dekat_siang_x3.png', 'tembok_rantai_x3.png',
              'ubin_potongan_x3.png']
if '--mock' in sys.argv:
    MOCK.mkdir(parents=True, exist_ok=True)
    for nm in MOCK_PILIH:
        shutil.copyfile(os.path.join(BRD, nm), MOCK / nm)
    # lembar kontak semua sprite x5, satu per papan
    for papan in ('koran', 'vfx', 'properti', 'dekat', 'ubin'):
        isi = [np.array(Image.open(os.path.join(BRD, 'x5_' + e['name'] + '.png'))) for e in S if e['board'] == papan]
        lebar = max(a.shape[1] for a in isi)
        tinggi = sum(a.shape[0] for a in isi) + 12 * (len(isi) - 1)
        kanvas = np.zeros((tinggi + 24, lebar + 24, 4), np.uint8)
        kanvas[:] = (0x1C, 0x13, 0x0F, 255)
        y = 12
        for a in isi:
            paste(kanvas, a, 12, y)
            y += a.shape[0] + 12
        Image.fromarray(kanvas, 'RGBA').save(MOCK / ('lembar_%s_x5.png' % papan))
if '--salin' in sys.argv:
    ada = {e['name'] for e in S}
    pasang = {folder: list(nama) for folder, nama in PASANG.items()}
    for folder, nama in PASANG_5B.items():
        pasang.setdefault(folder, []).extend(nama)
    for folder, nama in pasang.items():
        tujuan = SALIN_KE / folder
        tujuan.mkdir(parents=True, exist_ok=True)
        for n in nama:
            assert n in ada, n
            for ekstensi in ('.png', '.json'):
                shutil.copyfile(os.path.join(SPR, n + ekstensi), tujuan / (n + ekstensi))
    print('disalin ke', SALIN_KE, '(hanya', sum(len(v) for v in pasang.values()), 'sprite)')
print(len(S), 'sprite ->', OUTDIR)
