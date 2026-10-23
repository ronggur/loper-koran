"""Lencana milestone 14x14 (perunggu, perak, emas) untuk layar hasil (run 6A2 bagian C, AC-15, usulan).

Medali bulat bergantung pita biru. Tingkat dibedakan oleh WARNA dan BENTUK: garis di tengah medali berjumlah 1 (perunggu), 2 (perak), 3 (emas), jadi tingkat tetap terbaca
tanpa warna (rule ui-scenes). Warna hanya dari palet induk (ART_DIRECTION 2.4); pola ditulis sebagai teks seperti `hud_ikon.py`: '.' kosong, 'o' garis luar OUTLINE,
huruf lain = nada. Deterministik: tanpa acak.

Menjalankan (dari root repo):
    python3 tools/ui_art/lencana.py                       # tulis ke build/ui_art/lencana/
    python3 tools/ui_art/lencana.py --out jalur           # tulis ke folder lain
    python3 tools/ui_art/lencana.py --salin               # lalu salin ke assets/sprites/ui/ (ui_lencana_<tingkat>.png)
Butuh pillow. Diperiksa tools/tests_cek/uji_ui_lencana.py.
"""
import argparse
import shutil
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT_BAWAAN = ROOT / 'build' / 'ui_art' / 'lencana'
SALIN_KE = ROOT / 'assets' / 'sprites' / 'ui'
UKURAN = 14
TINGKAT = ['perunggu', 'perak', 'emas']


def hexc(h, a=255):
    h = h.lstrip('#')
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


O = hexc('#0E0A1C')
# Nada medali (terang, dasar, gelap) dari palet induk: sawo/kayu (perunggu), logam (perak), aksen hangat (emas).
MEDALI = {
    'perunggu': {'L': hexc('#D89A6C'), 'm': hexc('#B47C5F'), 'd': hexc('#8A5A40')},
    'perak': {'L': hexc('#C4C0C8'), 'm': hexc('#969AA0'), 'd': hexc('#67636D')},
    'emas': {'L': hexc('#FFE08A'), 'm': hexc('#FFC94A'), 'd': hexc('#E98E3F')},
}
PITA = {'p': hexc('#5F96C8'), 'q': hexc('#466E8C')}
# Garis hitungan di tengah medali: y tiap garis per tingkat (1, 2, 3 garis), lebar `GARIS_X`; 'o' garis luar.
GARIS_Y = {'perunggu': [9], 'perak': [8, 10], 'emas': [7, 9, 11]}
GARIS_X = range(4, 10)


def pola(tingkat):
    """Pola 14x14 sebuah lencana sebagai daftar baris teks."""
    g = [['.'] * UKURAN for _ in range(UKURAN)]
    # Pita: dua ekor di atas medali.
    for y in range(0, 5):
        g[y][4 + (1 if y > 2 else 0)] = 'o'
        g[y][5 + (1 if y > 2 else 0)] = 'p' if y else 'o'
        g[y][8 - (1 if y > 2 else 0)] = 'o'
        g[y][7 - (1 if y > 2 else 0)] = 'q' if y else 'o'
    # Cakram: lingkaran pusat (6,5; 8,5), jari-jari 5,2; garis luar satu piksel.
    pusat_x, pusat_y, r = 6.5, 8.5, 5.0
    ins = set()
    for y in range(UKURAN):
        for x in range(UKURAN):
            if (x - pusat_x) ** 2 + (y - pusat_y) ** 2 <= r * r + 0.5:
                ins.add((x, y))
    for (x, y) in ins:
        g[y][x] = 'm'
    for (x, y) in ins:
        dx, dy = x - pusat_x, y - pusat_y
        tepi = any((x + ex, y + ey) not in ins for ex, ey in ((1, 0), (-1, 0), (0, 1), (0, -1)))
        if tepi:
            g[y][x] = 'o'
        elif dx + dy < -2.2:
            g[y][x] = 'L'
        elif dx + dy > 2.2:
            g[y][x] = 'd'
    for y in GARIS_Y[tingkat]:
        for x in GARIS_X:
            g[y][x] = 'o'
    return [''.join(r_) for r_ in g]


def render(tingkat):
    pal = dict(MEDALI[tingkat])
    pal.update(PITA)
    p = pola(tingkat)
    im = Image.new('RGBA', (UKURAN, UKURAN), (0, 0, 0, 0))
    for y, baris in enumerate(p):
        for x, c in enumerate(baris):
            if c == '.':
                continue
            im.putpixel((x, y), O if c == 'o' else pal[c])
    return im


def nama_berkas(tingkat):
    return 'ui_lencana_%s.png' % tingkat


def bangun(folder):
    """Menulis tiga PNG ke `folder`; mengembalikan daftar nama berkas."""
    folder = Path(folder)
    folder.mkdir(parents=True, exist_ok=True)
    hasil = []
    for t in TINGKAT:
        render(t).save(folder / nama_berkas(t), optimize=False)
        hasil.append(nama_berkas(t))
    return hasil


def main():
    pengurai = argparse.ArgumentParser(description='Lencana milestone 14x14 (perunggu, perak, emas).')
    pengurai.add_argument('--out', default=str(OUT_BAWAAN), help='folder keluaran (bawaan: build/ui_art/lencana)')
    pengurai.add_argument('--salin', action='store_true', help='salin juga ke assets/sprites/ui/')
    argumen = pengurai.parse_args()
    for n in bangun(argumen.out):
        print('%s/%s' % (argumen.out, n))
    if argumen.salin:
        tujuan = Path(__import__('os').environ.get('UI_ART_SALIN_KE', SALIN_KE))
        tujuan.mkdir(parents=True, exist_ok=True)
        for t in TINGKAT:
            shutil.copyfile(Path(argumen.out) / nama_berkas(t), tujuan / nama_berkas(t))
        print('disalin ke', tujuan)
    return 0


if __name__ == '__main__':
    sys.exit(main())
