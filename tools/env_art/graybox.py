#!/usr/bin/env python3
"""Pembuat ubin dan kotak graybox (placeholder) untuk Godot. Hanya pustaka standar Python 3.

Menulis PNG 1x (RGBA, latar transparan) ke `assets/sprites/_placeholder/` (ubah dengan --out):

    tile_graybox_aspal.png        belah ketupat 64x32, aspal
    tile_graybox_trotoar.png      belah ketupat 64x32, trotoar
    tile_graybox_rumput.png       belah ketupat 64x32, rumput
    house_graybox_kotak.png       161x129, kotak rumah 3 ubin (sepanjang jalan) x 2 ubin (dalam), tinggi 48 px
    prop_graybox_kotak_surat.png  17x23, kotak kecil 0,25 x 0,25 ubin, tinggi 14 px

Aset ini sementara untuk menilai skala terhadap sprite pemain (TECH_PLAN Fase 0). Ukuran ubin
64x32 masih usulan (ART_DIRECTION 11). Warna diambil dari palet induk (ART_DIRECTION 2.4, usulan).

Geometri isometrik 2:1, jalan naik ke kanan atas (ART_DIRECTION 2.2): satu ubin sepanjang jalan
= (+32, -16) px layar, satu ubin menuju sisi `dekat` = (+32, +16) px, menuju sisi `seberang` = (-32, -16).

Titik pijak (pivot) di dalam PNG, dalam piksel dari pojok kiri atas gambar:
    ubin    : (32, 16), pusat belah ketupat
    rumah   : (64, 128), pojok bawah kotak (pertemuan sisi samping dan fasad) di tanah
    kotak surat : (8, 22), pojok bawah kotak di tanah
Fasad kotak rumah menghadap sisi `dekat` (kanan bawah layar), sisi samping menghadap kiri bawah.
Cahaya dari kiri atas: atas terang, sisi samping nada dasar, fasad nada gelap.

Cara pakai (dari root repo):
    python3 tools/env_art/graybox.py
Hasilnya deterministik (tanpa cap waktu), jadi menjalankan ulang tidak mengubah byte file.
Jangan edit PNG hasilnya dengan tangan: ubah skrip ini lalu jalankan ulang (rule `art-assets`).
"""
import argparse
import os
import struct
import zlib

UBIN_LEBAR = 64
UBIN_TINGGI = 32
SETENGAH_LEBAR = UBIN_LEBAR // 2
SETENGAH_TINGGI = UBIN_TINGGI // 2

# Warna dari palet induk (ART_DIRECTION 2.4).
ASPAL = ("#6C6872", "#5F5B66")  # isi, tepi (aspal, logam gelap)
TROTOAR = ("#DCCBA6", "#A9A2AE")  # isi, tepi (trotoar, kerb)
RUMPUT = ("#7DBB5A", "#6FAE4F")  # isi, tepi (rumput)
KOTAK_RUMAH = ("#C4C0C8", "#969AA0", "#67636D")  # atas, samping, fasad (logam)
KOTAK_SURAT = ("#FFE08A", "#FFC94A", "#E98E3F")  # atas, samping, fasad (aksen hangat)
GARIS_LUAR = "#0E0A1C"

TRANSPARAN = (0, 0, 0, 0)


def warna(hex_rgb):
    """'#RRGGBB' -> (r, g, b, 255)."""
    h = hex_rgb.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


def kanvas(lebar, tinggi):
    return [[TRANSPARAN] * lebar for _ in range(tinggi)]


def tulis_png(path, piksel):
    """Menulis PNG RGBA 8-bit tanpa pustaka luar. `piksel` = daftar baris berisi tuple (r, g, b, a)."""
    tinggi = len(piksel)
    lebar = len(piksel[0])
    mentah = bytearray()
    for baris in piksel:
        mentah.append(0)  # filter None
        for r, g, b, a in baris:
            mentah.extend((r, g, b, a))

    def potongan(jenis, data):
        isi = jenis + data
        return struct.pack(">I", len(data)) + isi + struct.pack(">I", zlib.crc32(isi) & 0xFFFFFFFF)

    ihdr = struct.pack(">IIBBBBB", lebar, tinggi, 8, 6, 0, 0, 0)
    data = (
        b"\x89PNG\r\n\x1a\n"
        + potongan(b"IHDR", ihdr)
        + potongan(b"IDAT", zlib.compress(bytes(mentah), 9))
        + potongan(b"IEND", b"")
    )
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(data)


def tambah_garis_tepi(piksel, topeng, warna_tepi):
    """Mewarnai piksel topeng yang bertetangga (4 arah) dengan luar topeng atau tepi gambar."""
    tinggi = len(topeng)
    lebar = len(topeng[0])
    for y in range(tinggi):
        for x in range(lebar):
            if not topeng[y][x]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if nx < 0 or ny < 0 or nx >= lebar or ny >= tinggi or not topeng[ny][nx]:
                    piksel[y][x] = warna_tepi
                    break


def ubin(isi_hex, tepi_hex):
    """Belah ketupat 64x32: baris y selebar 4*(y+1) piksel di separuh atas, lalu menyempit simetris."""
    piksel = kanvas(UBIN_LEBAR, UBIN_TINGGI)
    topeng = [[False] * UBIN_LEBAR for _ in range(UBIN_TINGGI)]
    for y in range(UBIN_TINGGI):
        setengah = (y + 1) * 2 if y < SETENGAH_TINGGI else (UBIN_TINGGI - y) * 2
        for x in range(SETENGAH_LEBAR - setengah, SETENGAH_LEBAR + setengah):
            topeng[y][x] = True
            piksel[y][x] = warna(isi_hex)
    tambah_garis_tepi(piksel, topeng, warna(tepi_hex))
    return piksel


def di_dalam(poligon, px, py):
    """True bila titik (px, py) ada di dalam poligon cembung (urutan titik bebas arah)."""
    tanda = 0
    n = len(poligon)
    for i in range(n):
        x1, y1 = poligon[i]
        x2, y2 = poligon[(i + 1) % n]
        silang = (x2 - x1) * (py - y1) - (y2 - y1) * (px - x1)
        if silang == 0:
            continue
        arah = 1 if silang > 0 else -1
        if tanda == 0:
            tanda = arah
        elif arah != tanda:
            return False
    return True


def kotak_iso(sepanjang_jalan, ke_dalam, tinggi, nada):
    """Kotak isometrik 2:1. Mengembalikan (piksel, titik_pijak).

    `sepanjang_jalan` dan `ke_dalam` dalam ubin (boleh pecahan), `tinggi` dalam piksel,
    `nada` = (atas, samping, fasad) dalam hex. Titik pijak = pojok bawah kotak di tanah.
    """
    w = sepanjang_jalan
    d = ke_dalam
    # Koordinat relatif terhadap pojok bawah B = (0, 0); y layar ke bawah.
    kanan = (SETENGAH_LEBAR * w, -SETENGAH_TINGGI * w)  # B + sepanjang jalan
    kiri = (-SETENGAH_LEBAR * d, -SETENGAH_TINGGI * d)  # B + menuju sisi seberang
    puncak = (kanan[0] + kiri[0], kanan[1] + kiri[1])

    def naik(p):
        return (p[0], p[1] - tinggi)

    b = (0.0, 0.0)
    fasad = [b, kanan, naik(kanan), naik(b)]
    samping = [b, kiri, naik(kiri), naik(b)]
    atas = [naik(b), naik(kanan), naik(puncak), naik(kiri)]

    min_x = min(p[0] for p in fasad + samping + atas)
    max_x = max(p[0] for p in fasad + samping + atas)
    min_y = min(p[1] for p in fasad + samping + atas)
    max_y = 0.0
    ox = int(round(-min_x))
    oy = int(round(-min_y))
    lebar = int(round(max_x - min_x)) + 1
    tinggi_gambar = int(round(max_y - min_y)) + 1

    # Nomor sisi: 0 kosong, 1 atas, 2 samping, 3 fasad (urutan tindih tidak penting: sisi tidak tumpang tindih).
    peta = [[0] * lebar for _ in range(tinggi_gambar)]
    for y in range(tinggi_gambar):
        for x in range(lebar):
            px = x - ox + 0.5
            py = y - oy + 0.5
            if di_dalam(atas, px, py):
                peta[y][x] = 1
            elif di_dalam(samping, px, py):
                peta[y][x] = 2
            elif di_dalam(fasad, px, py):
                peta[y][x] = 3

    piksel = kanvas(lebar, tinggi_gambar)
    for y in range(tinggi_gambar):
        for x in range(lebar):
            if peta[y][x]:
                piksel[y][x] = warna(nada[peta[y][x] - 1])

    # Garis luar 1 px: batas luar, dan batas antar sisi (digambar di sisi bernomor lebih besar).
    garis = warna(GARIS_LUAR)
    for y in range(tinggi_gambar):
        for x in range(lebar):
            nomor = peta[y][x]
            if not nomor:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                tetangga = 0
                if 0 <= nx < lebar and 0 <= ny < tinggi_gambar:
                    tetangga = peta[ny][nx]
                if tetangga == 0 or tetangga < nomor:
                    piksel[y][x] = garis
                    break
    return piksel, (ox, oy)


def main():
    akar_repo = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
    parser = argparse.ArgumentParser(description="Membuat ubin dan kotak graybox untuk Godot.")
    parser.add_argument(
        "--out",
        default=os.path.join(akar_repo, "assets", "sprites", "_placeholder"),
        help="folder keluaran (bawaan: assets/sprites/_placeholder)",
    )
    args = parser.parse_args()

    berkas = {
        "tile_graybox_aspal.png": ubin(*ASPAL),
        "tile_graybox_trotoar.png": ubin(*TROTOAR),
        "tile_graybox_rumput.png": ubin(*RUMPUT),
    }
    rumah, pijak_rumah = kotak_iso(3, 2, 48, KOTAK_RUMAH)
    berkas["house_graybox_kotak.png"] = rumah
    kotak_surat, pijak_kotak = kotak_iso(0.25, 0.25, 14, KOTAK_SURAT)
    berkas["prop_graybox_kotak_surat.png"] = kotak_surat

    for nama, piksel in berkas.items():
        tujuan = os.path.join(args.out, nama)
        tulis_png(tujuan, piksel)
        print("%s  %dx%d" % (tujuan, len(piksel[0]), len(piksel)))
    print("titik pijak rumah: %s, kotak surat: %s" % (pijak_rumah, pijak_kotak))


if __name__ == "__main__":
    main()
