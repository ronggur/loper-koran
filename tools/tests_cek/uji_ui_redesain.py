#!/usr/bin/env python3
"""Uji aset redesain UI (usulan 2026-10-23, `tools/ui_art/redesain/`, docs/design/redesain/README.md):

1. `komponen.py` deterministik: dua kali jalan = berkas PNG dan meta.json byte-identik.
2. Isi `docs/design/redesain/aset/` sama dengan keluaran `komponen.py --mock` (tidak diedit tangan).
3. Palet: setiap warna opak di aset komponen ada di palet induk (`assets/palette/loper_master.gpl`) atau token
   `scripts/ui/palette.gd`; satu-satunya warna semi-transparan adalah isi panel HUD (#0E0A1C alpha 214).
4. Bentuk: bingkai 9-slice tombol 12x16, panel/kartu 12x12, chip 8x8; sheet glif 12 per sel, ikon 24 per sel, lencana 32 per sel.
5. Latar bengkel (`latar_bengkel.py`, langkah numerik bisa berbeda antar-mesin, jadi yang diuji sifatnya):
   640x360 dan 800x360 opak, bagian tengah versi 800 = versi 640, pratinjau x3 = versi 800 diperbesar tanpa penghalusan,
   paling banyak 40 warna, dan tidak ada piksel hijau daun di tiga kotak tanaman yang dihapus.
6. Sepeda dari gambar full body (`sepeda_fullbody.py`): deterministik, docs = keluaran skrip, semua warna dari palet
   gambar full body, tidak ada warna kulit/kemeja/celana di bekas tempat tokoh, versi kecil = setengah ukuran versi besar,
   dan titik penanda kondisi jatuh di piksel sepeda yang opak.
7. Pemasangan ke `assets/sprites/ui/` (run ui1-komponen-bengkel, `pasang.py`): set berkas redesain TEPAT sama dengan daftar yang dipakai
   (tidak ada aset redesain lain), isi = keluaran `--salin` (komponen: piksel sama dengan keluaran `komponen.py`; sepeda dan latar: sama
   dengan berkas resmi di docs/), ikon 24 dan glif 12 = sel sheet, impor Lossless/tanpa mipmap/bukan VRAM, ukuran dan slice = `meta.json`
   (dan `Config.UI_*` = slice meta.json), warna dari palet induk atau token UI, tidak ada aset docs yang tidak dipasang ikut tersalin.

Butuh pillow dan numpy; bila tidak ada, uji berhenti dengan exit code 2.

Cara pakai (dari root repo):
    python3 tools/tests_cek/uji_ui_redesain.py

Exit code: 0 lolos semua, 1 ada yang gagal, 2 pillow/numpy tidak terpasang.
"""
import json
import os
import re
import subprocess
import sys
import tempfile

try:
    import numpy as np
    from PIL import Image
except ImportError:
    print('LEWAT: butuh numpy dan pillow (pip install numpy pillow)')
    sys.exit(2)

FOLDER = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(FOLDER, '..', '..'))
SKRIP = os.path.join(ROOT, 'tools', 'ui_art', 'redesain', 'komponen.py')
SKRIP_SEPEDA = os.path.join(ROOT, 'tools', 'ui_art', 'redesain', 'sepeda_fullbody.py')
FULLBODY = os.path.join(ROOT, 'docs', 'design', 'character', 'loper_agen', 'loper_agen_fullbody.png')
BERKAS_SEPEDA = ['sepeda.json', 'sepeda_besar.png', 'sepeda_besar_x3.png', 'sepeda_kecil.png']
# warna tokoh di gambar full body (kulit, kemeja, celana) yang tidak boleh tersisa di bekas tempat tokoh
WARNA_TOKOH = [(239, 164, 98), (220, 118, 69), (199, 103, 61), (240, 165, 99), (132, 166, 186), (110, 138, 170),
               (101, 121, 158), (127, 158, 182), (44, 48, 79), (58, 66, 94), (84, 96, 142), (36, 34, 61)]
sys.path.insert(0, os.path.join(ROOT, 'tools', 'ui_art', 'redesain'))
import pasang  # noqa: E402  (data murni: daftar aset yang dipasang)

SKRIP_LATAR = os.path.join(ROOT, 'tools', 'ui_art', 'redesain', 'latar_bengkel.py')
ASET_UI = os.path.join(ROOT, 'assets', 'sprites', 'ui')
CONFIG_GD = os.path.join(ROOT, 'scripts', 'config.gd')
DOCS_ASET = os.path.join(ROOT, 'docs', 'design', 'redesain', 'aset')
DOCS_LATAR = os.path.join(ROOT, 'docs', 'design', 'redesain', 'latar_bengkel')
GPL = os.path.join(ROOT, 'assets', 'palette', 'loper_master.gpl')
PALETTE_GD = os.path.join(ROOT, 'scripts', 'ui', 'palette.gd')
# kotak tanaman yang dihapus; kaca jendela (x 503-539, y 158-186) dikecualikan karena memang menampilkan pohon di luar
TANAMAN = {'kiri': (0, 144, 37, 211), 'kusen': (492, 158, 503, 198), 'ambang': (503, 186, 539, 198), 'kanan': (598, 165, 640, 225)}
PANEL_HUD_ISI = (14, 10, 28, 214)

gagal = 0


def cek(syarat, pesan):
    global gagal
    if syarat:
        print('  ok   ', pesan)
    else:
        gagal += 1
        print('  GAGAL', pesan)


def render(out, skrip=SKRIP):
    subprocess.run([sys.executable, skrip, '--out', out], check=True, stdout=subprocess.DEVNULL)
    return {n: open(os.path.join(out, n), 'rb').read() for n in sorted(os.listdir(out))}


def palet_boleh():
    warna = set()
    for baris in open(GPL, encoding='utf-8'):
        m = re.match(r'\s*(\d+)\s+(\d+)\s+(\d+)\s', baris)
        if m:
            warna.add(tuple(int(v) for v in m.groups()))
    for h in re.findall(r'Color\("#([0-9A-Fa-f]{6})"', open(PALETTE_GD, encoding='utf-8').read()):
        warna.add(tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)))
    return warna


print('1. komponen.py deterministik')
with tempfile.TemporaryDirectory() as a, tempfile.TemporaryDirectory() as b:
    ra, rb = render(a), render(b)
    cek(ra.keys() == rb.keys() and all(ra[n] == rb[n] for n in ra), f'{len(ra)} berkas identik di dua kali jalan')

    print('2. docs/design/redesain/aset = keluaran skrip')
    docs = sorted(n for n in os.listdir(DOCS_ASET) if n.endswith(('.png', '.json')) and n not in BERKAS_SEPEDA)
    cek(docs == sorted(ra.keys()), f'daftar berkas sama ({len(docs)})')
    beda = []
    for n in docs:
        if n not in ra:
            continue
        if n.endswith('.json'):
            if json.load(open(os.path.join(DOCS_ASET, n))) != json.loads(ra[n]):
                beda.append(n)
        else:
            x = Image.open(os.path.join(DOCS_ASET, n)).convert('RGBA')
            y = Image.open(os.path.join(a, n)).convert('RGBA')
            if x.size != y.size or x.tobytes() != y.tobytes():
                beda.append(n)
    cek(not beda, 'isi sama piksel per piksel' + (f' (beda: {beda})' if beda else ''))

    print('3. palet aset komponen')
    boleh = palet_boleh()
    asing = {}
    semi = set()
    for n in ra:
        if not n.endswith('.png') or n.startswith('lembar_'):
            continue
        arr = np.asarray(Image.open(os.path.join(a, n)).convert('RGBA'))
        for px in {tuple(int(v) for v in p) for p in arr.reshape(-1, 4)}:
            if px[3] == 0:
                continue
            if px[3] < 255:
                semi.add((n, px))
            elif px[:3] not in boleh:
                asing.setdefault(n, set()).add(px[:3])
    cek(not asing, 'semua warna opak dari palet induk atau token UI' + (f' (asing: {asing})' if asing else ''))
    cek(all(n == 'panel_hud.png' and px == PANEL_HUD_ISI for n, px in semi), 'semi-transparan hanya isi panel HUD')

    print('4. ukuran bingkai dan sheet')
    meta = json.loads(ra['meta.json'])
    uk = lambda n: Image.open(os.path.join(a, n + '.png')).size
    tombol = [n for n in meta if n.startswith(('btn_', 'koran_btn_'))]
    cek(tombol and all(uk(n) == (12, 16) for n in tombol), f'{len(tombol)} bingkai tombol 12x16')
    panel = ['panel_layar', 'panel_hud', 'kartu_biasa', 'kartu_menonjol', 'kartu_redup', 'koran_kotak', 'struk']
    cek(all(uk(n) == (12, 12) for n in panel), 'panel, kartu, kotak koran, struk 12x12')
    chip = [n for n in meta if n.startswith('chip_')]
    cek(chip and all(uk(n) == (8, 8) for n in chip), f'{len(chip)} chip 8x8')
    g = meta['glif12']
    cek(uk('glif12') == (12 * len(g['kolom']), 12 * len(g['baris'])), 'glif12 = 12 px per kolom dan per warna')
    cek(uk('ikon24') == (24 * len(meta['ikon24']['urutan']), 24), 'ikon24 = 24 px per ikon')
    cek(uk('lencana32') == (32 * len(meta['lencana32']['urutan']), 32), 'lencana32 = 32 px per lencana')
    cek(uk('papan_alat')[1] == 104, 'papan alat setinggi 104')

print('5. latar bengkel')
l640 = np.asarray(Image.open(os.path.join(DOCS_LATAR, 'bengkel_latar_640.png')).convert('RGBA'))
l800 = np.asarray(Image.open(os.path.join(DOCS_LATAR, 'bengkel_latar_800.png')).convert('RGBA'))
x3 = Image.open(os.path.join(DOCS_LATAR, 'bengkel_latar_800_x3.png')).convert('RGBA')
cek(l640.shape[:2] == (360, 640) and l800.shape[:2] == (360, 800), 'ukuran 640x360 dan 800x360')
cek(bool((l640[..., 3] == 255).all() and (l800[..., 3] == 255).all()), 'opak')
cek(bool((l800[:, 80:720] == l640).all()), 'tengah versi 800 = versi 640')
besar = Image.fromarray(l800).resize((2400, 1080), Image.NEAREST)
cek(x3.size == (2400, 1080) and x3.tobytes() == besar.tobytes(), 'pratinjau x3 = versi 800 diperbesar bulat')
jumlah = len({tuple(p) for p in l640[..., :3].reshape(-1, 3)})
cek(jumlah <= 40, f'{jumlah} warna (<= 40)')
rgb = l640[..., :3].astype(int)
hijau = (rgb[..., 1] >= rgb[..., 0] + 5) & (rgb[..., 1] >= rgb[..., 2] + 12) & (rgb[..., 1] < 80)   # daun redup; abu kehijauan ambang (G 91) tidak terhitung
sisa = {k: int(hijau[y0:y1, x0:x1].sum()) for k, (x0, y0, x1, y1) in TANAMAN.items()}
cek(all(v == 0 for v in sisa.values()), f'tanpa hijau daun di kotak tanaman {sisa}')

print('6. sepeda dari gambar full body')
with tempfile.TemporaryDirectory() as a, tempfile.TemporaryDirectory() as b:
    ra, rb = render(a, SKRIP_SEPEDA), render(b, SKRIP_SEPEDA)
    cek(ra.keys() == rb.keys() and all(ra[n] == rb[n] for n in ra), f'{len(ra)} berkas identik di dua kali jalan')
    cek(sorted(ra.keys()) == BERKAS_SEPEDA, 'berkas keluaran: ' + ', '.join(sorted(ra.keys())))
    beda = []
    for n in BERKAS_SEPEDA:
        if n.endswith('.json'):
            if json.load(open(os.path.join(DOCS_ASET, n))) != json.loads(ra[n]):
                beda.append(n)
        elif Image.open(os.path.join(DOCS_ASET, n)).convert('RGBA').tobytes() != Image.open(os.path.join(a, n)).convert('RGBA').tobytes():
            beda.append(n)
    cek(not beda, 'docs/design/redesain/aset = keluaran skrip' + (f' (beda: {beda})' if beda else ''))
besar = np.asarray(Image.open(os.path.join(DOCS_ASET, 'sepeda_besar.png')).convert('RGBA'))
kecil = np.asarray(Image.open(os.path.join(DOCS_ASET, 'sepeda_kecil.png')).convert('RGBA'))
meta = json.load(open(os.path.join(DOCS_ASET, 'sepeda.json')))
fb = np.asarray(Image.open(FULLBODY).convert('RGBA'))
palet_fb = {tuple(int(v) for v in p) for p in fb.reshape(-1, 4) if p[3] > 0}
warna = {tuple(int(v) for v in p) for p in besar.reshape(-1, 4) if p[3] > 0}
cek(warna <= palet_fb, f'{len(warna)} warna, semua dari palet gambar full body')
x0, y0 = meta['potong_dari']
bekas = besar[max(0, 108 - y0):250 - y0, 60 - x0:170 - x0]
sisa = [c for c in WARNA_TOKOH if ((bekas[..., :3] == c).all(-1) & (bekas[..., 3] == 255)).any()]
cek(not sisa, 'tanpa warna kulit/kemeja/celana di bekas tempat tokoh' + (f' (sisa: {sisa})' if sisa else ''))
cek(kecil.shape[1] == (besar.shape[1] + 1) // 2 and kecil.shape[0] == (besar.shape[0] + 1) // 2, f'kecil {kecil.shape[1]}x{kecil.shape[0]} = setengah besar')
titik_ok = all(kecil[y, x, 3] == 255 for x, y in meta['titik_kecil'].values())
cek(titik_ok, 'titik penanda ban/rem/rantai di piksel sepeda opak')

print('7. pemasangan ke assets/sprites/ui/')


def piksel(jalur):
    im = Image.open(jalur).convert('RGBA')
    return im.size, im.tobytes()


def konstanta_config(nama):
    m = re.search(r'^const ' + nama + r'\b[^=]*=\s*(-?\d+)\s*$', open(CONFIG_GD, encoding='utf-8').read(), re.M)
    return int(m.group(1)) if m else None


ada = sorted(n for n in os.listdir(ASET_UI) if n.startswith(pasang.AWALAN) and not n.endswith('.import'))
cek(ada == pasang.nama_semua(), f'set berkas redesain di assets/sprites/ui tepat {len(pasang.nama_semua())} (hanya yang dipakai)'
    + ('' if ada == pasang.nama_semua() else f' (lebih: {sorted(set(ada) - set(pasang.nama_semua()))}, kurang: {sorted(set(pasang.nama_semua()) - set(ada))})'))
with tempfile.TemporaryDirectory() as keluar, tempfile.TemporaryDirectory() as tujuan:
    env = dict(os.environ, UI_ART_SALIN_KE=tujuan)
    for skrip, args in ((SKRIP, ['--out', keluar]), (SKRIP_SEPEDA, []), (SKRIP_LATAR, [])):
        r = subprocess.run([sys.executable, skrip, '--salin'] + args, env=env, capture_output=True, text=True)
        cek(r.returncode == 0, f'{os.path.basename(skrip)} --salin berhasil' + ('' if r.returncode == 0 else f': {r.stderr[-200:]}'))
    hasil = sorted(os.listdir(tujuan))
    cek(hasil == pasang.nama_semua(), '--salin menulis tepat daftar yang dipasang')
    beda = [n for n in pasang.nama_komponen() if n in hasil and os.path.isfile(os.path.join(ASET_UI, n)) and piksel(os.path.join(ASET_UI, n)) != piksel(os.path.join(tujuan, n))]
    cek(not beda, 'komponen di assets/ piksel-identik dengan keluaran --salin (tidak diedit tangan)' + (f' (beda: {beda})' if beda else ''))
    beda = []
    for berkas, folder in ((pasang.SEPEDA, pasang.FOLDER_SEPEDA), (pasang.LATAR, pasang.FOLDER_LATAR)):
        for sumber, dst in berkas.items():
            resmi = os.path.join(ROOT, folder, sumber)
            if dst.endswith('.json'):
                ok = json.load(open(os.path.join(ASET_UI, dst))) == json.load(open(resmi)) == json.load(open(os.path.join(tujuan, dst)))
            else:
                ok = piksel(os.path.join(ASET_UI, dst)) == piksel(resmi) == piksel(os.path.join(tujuan, dst))
            if not ok:
                beda.append(dst)
    cek(not beda, 'sepeda dan latar di assets/ = berkas resmi di docs/' + (f' (beda: {beda})' if beda else ''))

meta = json.load(open(os.path.join(DOCS_ASET, 'meta.json')))
ikon_sheet = Image.open(os.path.join(DOCS_ASET, 'ikon24.png')).convert('RGBA')
salah = []
for nama, dst in pasang.IKON24.items():
    i = meta['ikon24']['urutan'].index(nama)
    if piksel(os.path.join(ASET_UI, dst + '.png')) != ((24, 24), ikon_sheet.crop((i * 24, 0, i * 24 + 24, 24)).tobytes()):
        salah.append(dst)
glif_sheet = Image.open(os.path.join(DOCS_ASET, 'glif12.png')).convert('RGBA')
for (nama, warna), dst in pasang.GLIF12.items():
    c, r = meta['glif12']['kolom'].index(nama), meta['glif12']['baris'].index(warna)
    if piksel(os.path.join(ASET_UI, dst + '.png')) != ((12, 12), glif_sheet.crop((c * 12, r * 12, c * 12 + 12, r * 12 + 12)).tobytes()):
        salah.append(dst)
cek(not salah, f'{len(pasang.IKON24)} ikon 24 dan {len(pasang.GLIF12)} glif 12 = sel sheet di docs' + (f' (salah: {salah})' if salah else ''))

salah = []
for sumber, dst in {**pasang.TOMBOL, **pasang.PANEL, **pasang.PAPAN}.items():
    if Image.open(os.path.join(ASET_UI, dst + '.png')).size != tuple(meta[sumber]['size']):
        salah.append(dst)
cek(not salah, 'ukuran bingkai/papan di assets/ = meta.json' + (f' (salah: {salah})' if salah else ''))
cek(Image.open(os.path.join(ASET_UI, 'ui_arsir_nonaktif.png')).size == (4, 4), 'arsir nonaktif 4x4 = tengah bingkai tombol (lebar 12 - 2x4, tinggi 16 - 2x6)')

# slice (atas, kanan, bawah, kiri; urutan CSS) di meta.json = konstanta Config yang dipakai GayaHud
slice_tombol = {tuple(meta[n]['slice']) for n in pasang.TOMBOL if 'slice' in meta[n]}
slice_panel = {tuple(meta[n]['slice']) for n in pasang.PANEL if n.startswith(('panel_', 'kartu_'))}
slice_chip = {tuple(meta[n]['slice']) for n in pasang.PANEL if n.startswith('chip_')}
cek(len(slice_tombol) == 1 and len(slice_panel) == 1 and len(slice_chip) == 1, 'slice seragam per jenis (tombol, panel/kartu, chip) di meta.json')
if len(slice_tombol) == 1 and len(slice_panel) == 1 and len(slice_chip) == 1:
    t, r, b, k = next(iter(slice_tombol))
    p_ = next(iter(slice_panel))
    c_ = next(iter(slice_chip))
    cfg = {n: konstanta_config(n) for n in ('UI_TOMBOL_SLICE_ATAS_PX', 'UI_TOMBOL_SLICE_BAWAH_PX', 'UI_TOMBOL_SLICE_SAMPING_PX', 'UI_PANEL_SLICE_PX', 'UI_CHIP_SLICE_PX')}
    cek(cfg == {'UI_TOMBOL_SLICE_ATAS_PX': t, 'UI_TOMBOL_SLICE_BAWAH_PX': b, 'UI_TOMBOL_SLICE_SAMPING_PX': r,
                'UI_PANEL_SLICE_PX': p_[0], 'UI_CHIP_SLICE_PX': c_[0]} and r == k and p_ == (p_[0],) * 4 and c_ == (c_[0],) * 4,
        f'slice meta.json (tombol {t}/{r}/{b}/{k}, panel {p_[0]}, chip {c_[0]}) = Config.UI_*_SLICE_PX ({cfg})')

salah = []
for n in pasang.nama_semua():
    if not n.endswith('.png'):
        continue
    teks = open(os.path.join(ASET_UI, n + '.import'), encoding='utf-8').read() if os.path.isfile(os.path.join(ASET_UI, n + '.import')) else ''
    if not ('compress/mode=0\n' in teks and 'mipmaps/generate=false\n' in teks and '"vram_texture": false' in teks and 'uid="uid://' in teks):
        salah.append(n)
cek(not salah, 'setiap PNG punya .import Lossless, tanpa mipmap, bukan VRAM, uid ada' + (f' (salah: {salah})' if salah else ''))

boleh = palet_boleh()
asing = {}
for n in pasang.nama_komponen():
    arr = np.asarray(Image.open(os.path.join(ASET_UI, n)).convert('RGBA'))
    for px in {tuple(int(v) for v in p) for p in arr.reshape(-1, 4)}:
        if px[3] == 255 and px[:3] not in boleh:
            asing.setdefault(n, set()).add(px[:3])
cek(not asing, 'warna opak komponen terpasang dari palet induk atau token UI' + (f' (asing: {asing})' if asing else ''))

# tidak ada aset docs yang tidak dipasang ikut tersalin (bandingkan piksel dengan setiap PNG baru di assets/)
dipasang_sumber = set(pasang.TOMBOL) | set(pasang.PANEL) | set(pasang.PAPAN) | {'ikon24', 'glif12'} | {os.path.splitext(n)[0] for n in pasang.SEPEDA}
tak_dipasang = [n for n in sorted(os.listdir(DOCS_ASET)) if n.endswith('.png') and not n.startswith('lembar_') and os.path.splitext(n)[0] not in dipasang_sumber and not n.endswith('_x3.png')]
sidik = {piksel(os.path.join(ASET_UI, n)) for n in ada if n.endswith('.png')}
bocor = [n for n in tak_dipasang if piksel(os.path.join(DOCS_ASET, n)) in sidik]
cek(not bocor, f'{len(tak_dipasang)} aset docs yang belum dipasang tidak ada di assets/' + (f' (bocor: {bocor})' if bocor else ''))

print()
print('LOLOS' if not gagal else f'GAGAL: {gagal}')
sys.exit(1 if gagal else 0)
