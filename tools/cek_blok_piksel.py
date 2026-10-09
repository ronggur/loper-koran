#!/usr/bin/env python3
"""Memeriksa tangkapan layar game: apakah tiap piksel game menjadi blok SKALA x SKALA piksel yang seragam?

Hanya pustaka standar Python 3 (membaca PNG 8-bit RGB/RGBA tanpa interlace). Dipakai sebagai bukti
verifikasi layar (AC-13, run 0A): dengan stretch `canvas_items` + skala bulat + filter Nearest + posisi
sprite bilangan bulat, hasilnya harus berupa blok yang seragam. Blur, skala pecahan, atau sprite di
posisi setengah piksel membuat sebagian blok tidak seragam.

Cara pakai:
    python3 tools/cek_blok_piksel.py <skala> <png> [<png> ...]
    python3 tools/cek_blok_piksel.py 3 docs/loop/20261009-fase0a-fondasi/shots/iter1/jendela_2340x1080.png

Tangkapan layar dibuat oleh `tests/probe_layar_jendela.gd`. Exit code 0 bila semua blok seragam, 1 bila ada
yang tidak, 2 bila berkas tidak bisa dibaca.
"""
import struct
import sys
import zlib


def baca_png(jalur):
    """Mengembalikan (lebar, tinggi, byte_per_piksel, daftar_baris_bytes)."""
    with open(jalur, "rb") as f:
        data = f.read()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("bukan PNG")
    pos = 8
    idat = b""
    lebar = tinggi = tipe = kedalaman = interlace = 0
    while pos < len(data):
        panjang = struct.unpack(">I", data[pos : pos + 4])[0]
        jenis = data[pos + 4 : pos + 8]
        isi = data[pos + 8 : pos + 8 + panjang]
        pos += 12 + panjang
        if jenis == b"IHDR":
            lebar, tinggi, kedalaman, tipe, _, _, interlace = struct.unpack(">IIBBBBB", isi)
        elif jenis == b"IDAT":
            idat += isi
    if kedalaman != 8 or interlace != 0 or tipe not in (2, 6):
        raise ValueError("hanya PNG 8-bit RGB/RGBA tanpa interlace (kedalaman %d, tipe %d)" % (kedalaman, tipe))
    bpp = 3 if tipe == 2 else 4
    mentah = zlib.decompress(idat)
    langkah = lebar * bpp
    baris = []
    sebelumnya = bytearray(langkah)
    p = 0
    for _ in range(tinggi):
        filter_baris = mentah[p]
        saat_ini = bytearray(mentah[p + 1 : p + 1 + langkah])
        p += 1 + langkah
        for i in range(langkah):
            a = saat_ini[i - bpp] if i >= bpp else 0
            b = sebelumnya[i]
            c = sebelumnya[i - bpp] if i >= bpp else 0
            if filter_baris == 1:
                saat_ini[i] = (saat_ini[i] + a) & 255
            elif filter_baris == 2:
                saat_ini[i] = (saat_ini[i] + b) & 255
            elif filter_baris == 3:
                saat_ini[i] = (saat_ini[i] + ((a + b) >> 1)) & 255
            elif filter_baris == 4:
                pa, pb, pc = abs(b - c), abs(a - c), abs(a + b - 2 * c)
                prediksi = a if pa <= pb and pa <= pc else (b if pb <= pc else c)
                saat_ini[i] = (saat_ini[i] + prediksi) & 255
        baris.append(bytes(saat_ini))
        sebelumnya = saat_ini
    return lebar, tinggi, bpp, baris


def periksa(jalur, skala):
    lebar, tinggi, bpp, baris = baca_png(jalur)
    total = 0
    tidak_seragam = 0
    for by in range(0, tinggi - tinggi % skala, skala):
        for bx in range(0, lebar - lebar % skala, skala):
            acuan = baris[by][bx * bpp : (bx + 1) * bpp]
            seragam = True
            for dy in range(skala):
                for dx in range(skala):
                    if baris[by + dy][(bx + dx) * bpp : (bx + dx + 1) * bpp] != acuan:
                        seragam = False
                        break
                if not seragam:
                    break
            total += 1
            tidak_seragam += 0 if seragam else 1
    sisa = (lebar % skala, tinggi % skala)
    print("%s: %dx%d, skala %d, %d blok, %d tidak seragam, sisa tepi %s" % (jalur, lebar, tinggi, skala, total, tidak_seragam, sisa))
    return tidak_seragam == 0 and sisa == (0, 0)


def main():
    if len(sys.argv) < 3 or not sys.argv[1].isdigit() or int(sys.argv[1]) < 1:
        print("pemakaian: cek_blok_piksel.py <skala> <png> [<png> ...]", file=sys.stderr)
        return 2
    skala = int(sys.argv[1])
    semua_baik = True
    for jalur in sys.argv[2:]:
        try:
            semua_baik = periksa(jalur, skala) and semua_baik
        except (OSError, ValueError) as galat:
            print("tidak bisa membaca %s: %s" % (jalur, galat), file=sys.stderr)
            return 2
    return 0 if semua_baik else 1


if __name__ == "__main__":
    sys.exit(main())
