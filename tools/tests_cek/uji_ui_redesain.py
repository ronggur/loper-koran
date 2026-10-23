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


def render(out):
    subprocess.run([sys.executable, SKRIP, '--out', out], check=True, stdout=subprocess.DEVNULL)
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
    docs = sorted(n for n in os.listdir(DOCS_ASET) if n.endswith(('.png', '.json')))
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
    cek(uk('sepeda_samping') == (124, 72), 'sepeda tampak samping 124x72')

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

print()
print('LOLOS' if not gagal else f'GAGAL: {gagal}')
sys.exit(1 if gagal else 0)
