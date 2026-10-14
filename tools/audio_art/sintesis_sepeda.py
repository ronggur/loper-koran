#!/usr/bin/env python3
"""Sintesis bunyi placeholder sepeda (SOUND_DESIGN 3.2, D-4 run fase1b-umpan-balik). Hanya pustaka standar.

Menulis tiga WAV mono 16-bit 22050 Hz, dibuat sendiri dari rumus (tanpa rekaman, tanpa unduhan):
  sfx_bike_pedal_loop.wav      ketukan rantai + hentakan pedal, 1,0 detik, loop. 8 ketukan per detik = kayuh santai
                               8 fps (ART_DIRECTION 3.2); hentakan tiap 0,25 detik (dua injakan per putaran 4 frame).
  sfx_bike_freewheel_loop.wav  "tik-tik-tik" freewheel pelan, 1,0 detik, loop, 10 tik per detik.
  sfx_bike_brake_01.wav        decit rem pendek 0,45 detik, sekali putar.

Keluaran deterministik: acak hanya dari `random.Random(BENIH)` dengan benih tetap dan hanya `random()`, jadi dua kali
jalan menghasilkan byte yang sama (diperiksa `tools/tests_cek/uji_sintesis_sepeda.py`). Loop dibangun sebagai satu siklus
utuh: ekor bunyi yang melewati ujung dibungkus ke awal, dan tiap ketukan meluruh jauh sebelum ujung, jadi sampel awal dan
akhir dekat nol dan sambungan loop tanpa klik. Puncak dinormalkan ke `PUNCAK`; keras-pelan relatif diatur di Godot lewat
`Config.AUDIO_*_VOLUME_DB`, bukan di sini.

Cara pakai (dari root repo):
    python3 tools/audio_art/sintesis_sepeda.py                 # tulis ke assets/audio/sfx/bike/
    python3 tools/audio_art/sintesis_sepeda.py --out build/x   # tulis ke folder lain (untuk uji)
"""
import argparse
import math
import os
import random
import struct
import sys
import wave

LAJU_SAMPEL = 22050
LEBAR_SAMPEL = 2
PUNCAK = 0.89
BENIH = 20261014
FOLDER = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(FOLDER, '..', '..'))
KELUARAN_BAWAAN = os.path.join(ROOT, 'assets', 'audio', 'sfx', 'bike')

NAMA_KAYUH = 'sfx_bike_pedal_loop.wav'
NAMA_FREEWHEEL = 'sfx_bike_freewheel_loop.wav'
NAMA_REM = 'sfx_bike_brake_01.wav'

# Kayuhan: 8 ketukan rantai per detik (kayuh santai 8 fps), hentakan pedal tiap ketukan kedua.
KAYUH_DETIK = 1.0
KAYUH_KETUKAN_PER_DETIK = 8
KAYUH_KLIK_HZ = 3200.0
KAYUH_KLIK_LURUH_DETIK = 0.004
KAYUH_HENTAK_HZ = 170.0
KAYUH_HENTAK_LURUH_DETIK = 0.011
KAYUH_HENTAK_KUAT = 0.9
KAYUH_KLIK_KUAT = 0.55

# Freewheel: tik pendek dan tinggi, 10 per detik.
FREEWHEEL_DETIK = 1.0
FREEWHEEL_TIK_PER_DETIK = 10
FREEWHEEL_TIK_HZ = 4600.0
FREEWHEEL_TIK_LURUH_DETIK = 0.0016

# Rem: decit 2400 Hz dengan getar 7 Hz, naik sedikit, gesekan di awal.
REM_DETIK = 0.45
REM_NADA_HZ = 2400.0
REM_NADA_NAIK = 0.04
REM_GETAR_HZ = 7.0
REM_GETAR_DALAM = 0.015
REM_SERANG_DETIK = 0.02
REM_LEPAS_DETIK = 0.12
REM_GESEK_DETIK = 0.06
REM_GESEK_KUAT = 0.35
REM_HARMONIK = ((1.0, 1.0), (2.0, 0.3), (3.0, 0.1))


def _resonator(masukan, frekuensi_hz, luruh_detik):
    """Filter dua kutub (resonator) atas `masukan`; dering meluruh dengan konstanta waktu `luruh_detik`."""
    r = math.exp(-1.0 / (luruh_detik * LAJU_SAMPEL))
    theta = 2.0 * math.pi * frekuensi_hz / LAJU_SAMPEL
    a1 = 2.0 * r * math.cos(theta)
    a2 = -r * r
    y1 = 0.0
    y2 = 0.0
    keluaran = []
    for x in masukan:
        y = x + a1 * y1 + a2 * y2
        keluaran.append(y)
        y2 = y1
        y1 = y
    return keluaran


def _derau(acak, jumlah, luruh_detik):
    """Semburan derau putih yang meluruh eksponensial, `jumlah` sampel."""
    return [(acak.random() * 2.0 - 1.0) * math.exp(-i / (luruh_detik * LAJU_SAMPEL)) for i in range(jumlah)]


def _tambah_melingkar(buffer, mulai, potongan):
    """Menambahkan `potongan` ke `buffer` mulai indeks `mulai`; yang melewati ujung dibungkus ke awal (loop utuh)."""
    n = len(buffer)
    for i, nilai in enumerate(potongan):
        buffer[(mulai + i) % n] += nilai


def _normalkan(sampel):
    puncak = max(abs(s) for s in sampel)
    skala = PUNCAK / puncak if puncak > 0.0 else 0.0
    return [s * skala for s in sampel]


def _ke_int16(sampel):
    batas = 32767
    return [max(-batas, min(batas, int(round(s * batas)))) for s in sampel]


def kayuh(acak):
    n = int(round(KAYUH_DETIK * LAJU_SAMPEL))
    buffer = [0.0] * n
    jarak = n // KAYUH_KETUKAN_PER_DETIK
    panjang_klik = int(LAJU_SAMPEL * KAYUH_KLIK_LURUH_DETIK * 12)
    panjang_hentak = int(LAJU_SAMPEL * KAYUH_HENTAK_LURUH_DETIK * 8)
    for k in range(KAYUH_KETUKAN_PER_DETIK):
        mulai = k * jarak + jarak // 2
        kuat = KAYUH_KLIK_KUAT * (0.9 + 0.2 * acak.random())
        klik = _resonator(_derau(acak, panjang_klik, KAYUH_KLIK_LURUH_DETIK * 0.5), KAYUH_KLIK_HZ, KAYUH_KLIK_LURUH_DETIK)
        puncak_klik = max(abs(v) for v in klik)
        _tambah_melingkar(buffer, mulai, [v / puncak_klik * kuat for v in klik])
        if k % 2 == 0:
            # Hentakan pedal: kaki kanan dan kiri bergantian sedikit beda kuat.
            kuat_hentak = KAYUH_HENTAK_KUAT * (1.0 if k % 4 == 0 else 0.8)
            hentak = [math.sin(2.0 * math.pi * KAYUH_HENTAK_HZ * i / LAJU_SAMPEL) * math.exp(-i / (KAYUH_HENTAK_LURUH_DETIK * LAJU_SAMPEL)) * kuat_hentak
                      for i in range(panjang_hentak)]
            _tambah_melingkar(buffer, mulai, hentak)
    return _ke_int16(_normalkan(buffer))


def freewheel(acak):
    n = int(round(FREEWHEEL_DETIK * LAJU_SAMPEL))
    buffer = [0.0] * n
    jarak = n // FREEWHEEL_TIK_PER_DETIK
    panjang = int(LAJU_SAMPEL * FREEWHEEL_TIK_LURUH_DETIK * 14)
    for k in range(FREEWHEEL_TIK_PER_DETIK):
        mulai = k * jarak + jarak // 2
        kuat = 0.85 + 0.3 * acak.random()
        tik = _resonator(_derau(acak, panjang, FREEWHEEL_TIK_LURUH_DETIK * 0.4), FREEWHEEL_TIK_HZ, FREEWHEEL_TIK_LURUH_DETIK)
        puncak_tik = max(abs(v) for v in tik)
        _tambah_melingkar(buffer, mulai, [v / puncak_tik * kuat for v in tik])
    return _ke_int16(_normalkan(buffer))


def rem(acak):
    n = int(round(REM_DETIK * LAJU_SAMPEL))
    serang = int(REM_SERANG_DETIK * LAJU_SAMPEL)
    lepas = int(REM_LEPAS_DETIK * LAJU_SAMPEL)
    gesek = int(REM_GESEK_DETIK * LAJU_SAMPEL)
    fase = 0.0
    hasil = []
    derau_lalu = 0.0
    for i in range(n):
        t = i / LAJU_SAMPEL
        frekuensi = REM_NADA_HZ * (1.0 + REM_NADA_NAIK * t / REM_DETIK) * (1.0 + REM_GETAR_DALAM * math.sin(2.0 * math.pi * REM_GETAR_HZ * t))
        fase += 2.0 * math.pi * frekuensi / LAJU_SAMPEL
        nada = sum(kuat * math.sin(kelipatan * fase) for kelipatan, kuat in REM_HARMONIK)
        if i < serang:
            amplop = i / serang
        elif i >= n - lepas:
            # Lepas setengah kosinus sampai tepat nol di sampel terakhir.
            amplop = 0.5 * (1.0 + math.cos(math.pi * (i - (n - lepas)) / (lepas - 1)))
        else:
            amplop = 1.0
        nilai = nada * amplop
        if i < gesek:
            # Gesekan kampas: derau ditapis lolos-bawah satu kutub, meluruh sampai nol di akhir potongan.
            derau_lalu = 0.7 * derau_lalu + 0.3 * (acak.random() * 2.0 - 1.0)
            nilai += derau_lalu * REM_GESEK_KUAT * (1.0 - i / gesek) * (i / serang if i < serang else 1.0)
        hasil.append(nilai)
    return _ke_int16(_normalkan(hasil))


def tulis_wav(jalur, sampel):
    with wave.open(jalur, 'wb') as berkas:
        berkas.setnchannels(1)
        berkas.setsampwidth(LEBAR_SAMPEL)
        berkas.setframerate(LAJU_SAMPEL)
        berkas.writeframes(struct.pack('<%dh' % len(sampel), *sampel))


def bangun(folder):
    """Membuat ketiga WAV ke `folder`. Mengembalikan daftar (nama, jumlah sampel)."""
    os.makedirs(folder, exist_ok=True)
    acak = random.Random(BENIH)
    hasil = []
    for nama, fungsi in ((NAMA_KAYUH, kayuh), (NAMA_FREEWHEEL, freewheel), (NAMA_REM, rem)):
        sampel = fungsi(acak)
        tulis_wav(os.path.join(folder, nama), sampel)
        hasil.append((nama, len(sampel)))
    return hasil


def main():
    pengurai = argparse.ArgumentParser(description='Sintesis bunyi placeholder sepeda (kayuh, freewheel, rem).')
    pengurai.add_argument('--out', default=KELUARAN_BAWAAN, help='folder keluaran (bawaan: assets/audio/sfx/bike)')
    argumen = pengurai.parse_args()
    for nama, jumlah in bangun(argumen.out):
        print('%s: %d sampel, %.3f detik' % (os.path.join(argumen.out, nama), jumlah, jumlah / LAJU_SAMPEL))
    return 0


if __name__ == '__main__':
    sys.exit(main())
