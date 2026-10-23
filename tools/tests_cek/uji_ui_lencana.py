#!/usr/bin/env python3
"""Uji `tools/ui_art/lencana.py` (lencana milestone 14x14, run 6A2 bagian C, AC-15). Butuh pillow.

Membuktikan: (1) skrip deterministik (dua kali jalan = byte sama), (2) tiga PNG di `assets/sprites/ui/` byte-identik dengan keluaran skrip (tidak diedit tangan),
(3) ukuran 14x14 RGBA, (4) hanya warna palet induk (`assets/palette/loper_master.gpl`) dan garis luar OUTLINE, (5) tingkat terbaca TANPA warna: jumlah garis hitungan
di tengah medali 1, 2, 3 dan bentuk (mask alfa) pita + cakram sama, (6) tiga lencana berbeda nyata, (7) `.png.import` Lossless tanpa mipmap bukan VRAM, (8) pemeriksaan
menolak contoh buruk.

Cara pakai (dari root repo):
    python3 tools/tests_cek/uji_ui_lencana.py
Exit code: 0 bila semua lolos, 1 bila ada yang gagal.
"""
import os
import re
import subprocess
import sys
import tempfile

from PIL import Image

FOLDER = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(FOLDER, '..', '..'))
SKRIP = os.path.join(ROOT, 'tools', 'ui_art', 'lencana.py')
ASET = os.path.join(ROOT, 'assets', 'sprites', 'ui')
PALET = os.path.join(ROOT, 'assets', 'palette', 'loper_master.gpl')
TINGKAT = ['perunggu', 'perak', 'emas']
OUTLINE = (14, 10, 28, 255)

gagal = 0
lolos = 0


def periksa(kondisi, label):
    global gagal, lolos
    if kondisi:
        lolos += 1
    else:
        gagal += 1
        print('GAGAL:', label)


def baca(jalur):
    with open(jalur, 'rb') as f:
        return f.read()


def warna_palet():
    hasil = set()
    with open(PALET, encoding='utf-8') as f:
        for baris in f:
            m = re.match(r'\s*(\d+)\s+(\d+)\s+(\d+)\s', baris)
            if m:
                hasil.add((int(m.group(1)), int(m.group(2)), int(m.group(3)), 255))
    return hasil


def warna_di_luar_palet(im, palet):
    luar = set()
    for y in range(im.height):
        for x in range(im.width):
            p = im.getpixel((x, y))
            if p[3] == 0:
                continue
            if p != OUTLINE and p not in palet:
                luar.add(p)
    return sorted(luar)


def jumlah_garis(im):
    """Jumlah garis hitungan: baris di mana 6 piksel tengah (x 4..9) semuanya OUTLINE, dipisah baris bukan-garis."""
    garis = 0
    sebelumnya = False
    for y in range(5, 13):
        penuh = all(im.getpixel((x, y)) == OUTLINE for x in range(4, 10))
        if penuh and not sebelumnya:
            garis += 1
        sebelumnya = penuh
    return garis


def mask_alfa(im):
    return [[im.getpixel((x, y))[3] > 0 for x in range(im.width)] for y in range(im.height)]


def main():
    palet = warna_palet()
    periksa(len(palet) > 30, 'palet induk terbaca')
    with tempfile.TemporaryDirectory() as sementara:
        a, b = os.path.join(sementara, 'a'), os.path.join(sementara, 'b')
        for folder in (a, b):
            hasil = subprocess.run([sys.executable, SKRIP, '--out', folder], capture_output=True, text=True)
            periksa(hasil.returncode == 0, 'skrip berhasil: %s' % (hasil.stdout + hasil.stderr)[:200])
        ims = {}
        for t in TINGKAT:
            nama = 'ui_lencana_%s.png' % t
            ja, jb, jr = os.path.join(a, nama), os.path.join(b, nama), os.path.join(ASET, nama)
            periksa(os.path.isfile(ja) and os.path.isfile(jb) and baca(ja) == baca(jb), '%s: dua kali jalan byte sama (deterministik)' % nama)
            periksa(os.path.isfile(jr) and baca(jr) == baca(ja), '%s: berkas di assets/ byte-identik dengan keluaran skrip (tidak diedit tangan)' % nama)
            if not os.path.isfile(jr):
                continue
            im = Image.open(jr).convert('RGBA')
            ims[t] = im
            periksa(im.size == (14, 14), '%s: 14x14 (dapat %s)' % (nama, im.size))
            luar = warna_di_luar_palet(im, palet)
            periksa(not luar, '%s: hanya warna palet induk dan OUTLINE (di luar: %s)' % (nama, luar))
            berkas_impor = jr + '.import'
            teks = open(berkas_impor, encoding='utf-8').read() if os.path.isfile(berkas_impor) else ''
            periksa('compress/mode=0\n' in teks and 'mipmaps/generate=false\n' in teks and '"vram_texture": false' in teks and 'uid="uid://' in teks,
                    '%s.import: Lossless, tanpa mipmap, bukan VRAM, uid ada' % nama)
        if len(ims) == 3:
            garis = [jumlah_garis(ims[t]) for t in TINGKAT]
            periksa(garis == [1, 2, 3], 'jumlah garis hitungan 1/2/3 (tingkat terbaca tanpa warna): %s' % garis)
            periksa(mask_alfa(ims['perunggu']) == mask_alfa(ims['perak']) == mask_alfa(ims['emas']), 'bentuk (mask alfa) tiga lencana sama; perbedaan hanya warna dan garis')
            periksa(len({baca(os.path.join(ASET, 'ui_lencana_%s.png' % t)) for t in TINGKAT}) == 3, 'tiga lencana berbeda byte')
            warna_tengah = [ims[t].getpixel((6, 6)) for t in TINGKAT]
            periksa(len(set(warna_tengah)) == 3, 'warna cakram tiga tingkat berbeda: %s' % warna_tengah)
        # Kontrol: pemeriksa menolak contoh buruk.
        buruk = Image.new('RGBA', (14, 14), (0, 0, 0, 0))
        buruk.putpixel((3, 3), (1, 2, 3, 255))
        periksa(warna_di_luar_palet(buruk, palet) == [(1, 2, 3, 255)], 'kontrol: warna di luar palet terdeteksi')
        kosong = Image.new('RGBA', (14, 14), (0, 0, 0, 0))
        periksa(jumlah_garis(kosong) == 0, 'kontrol: gambar kosong tanpa garis hitungan')
        tiga = Image.new('RGBA', (14, 14), (0, 0, 0, 0))
        for y in (7, 9, 11):
            for x in range(4, 10):
                tiga.putpixel((x, y), OUTLINE)
        periksa(jumlah_garis(tiga) == 3, 'kontrol: tiga garis terhitung tiga')
    print('%d lolos, %d gagal' % (lolos, gagal))
    return 1 if gagal else 0


if __name__ == '__main__':
    sys.exit(main())
