#!/usr/bin/env python3
"""Sintesis bunyi placeholder kondisi sepeda run 6A1 bagian B: tiga tanda peringatan (rantai berisik, rem berdecit, ban mendesis) dan dua bunyi transaksi bengkel (servis, upgrade)
(SOUND_DESIGN 3.1, 4; AC-27 run fase6a1-bengkel-kondisi, usulan). Hanya pustaka standar.

Menulis 5 WAV mono 16-bit 22050 Hz (laju sama dengan bunyi sepeda, lempar, rute, dan misi), dibuat sendiri dari rumus (tanpa rekaman, tanpa unduhan):
  condition/sfx_cond_rantai_berisik_01.wav  rantai berisik: lima ketukan logam pendek tak beraturan ("tik-tik-tik") dari derau yang disaring pita 1,3 kHz, 0,55 detik
                                            (pasangan visual: ikon rantai bergetar dan kotak berwarna WARN di HUD).
  condition/sfx_cond_rem_berdecit_01.wav    rem berdecit: nada tinggi meluncur turun 2,6 kHz ke 2,0 kHz dengan getar dan sedikit derau, 0,45 detik (ikon rem bergetar).
  condition/sfx_cond_ban_mendesis_01.wav    ban mendesis: desis derau lolos-atas bernada tinggi yang meredup, 0,65 detik (ikon ban bergetar).
  condition/sfx_cond_servis_01.wav          servis di bengkel: tiga ketukan ratchet lalu dua dentingan naik (660 Hz lalu 880 Hz), 0,60 detik.
  condition/sfx_cond_upgrade_01.wav         upgrade di bengkel: empat nada naik (arpeggio do mi sol do tinggi) bertimbre cerah dengan kilau, 0,80 detik.

Keluaran deterministik: acak hanya dari `random.Random(BENIH)` dengan benih tetap dan hanya `random()`, jadi dua kali jalan menghasilkan byte yang sama (diperiksa
`tools/tests_cek/uji_sintesis_kondisi.py`). Semua bunyi sekali putar: sampel pertama dan terakhir tepat nol (tanpa klik). Puncak dinormalkan ke `PUNCAK`; keras-pelan saat main
diatur di Godot lewat `Config.AUDIO_KONDISI_*_VOLUME_DB`, bukan di sini.

Cara pakai (dari root repo):
    python3 tools/audio_art/sintesis_kondisi.py                 # tulis ke assets/audio/sfx/condition/
    python3 tools/audio_art/sintesis_kondisi.py --out build/x   # tulis ke folder lain (subfolder condition), untuk uji
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
PUNCAK = 0.85
BENIH = 20261020
FOLDER = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(FOLDER, '..', '..'))
KELUARAN_BAWAAN = os.path.join(ROOT, 'assets', 'audio', 'sfx')

# Rantai berisik: (detik total, waktu mulai tiap ketukan dalam detik, pusat pita Hz, lebar pita Hz, peluruhan detik per ketukan).
RANTAI = (0.55, (0.02, 0.11, 0.19, 0.31, 0.40), 1300.0, 900.0, 0.022)
# Rem berdecit: (detik, nada awal Hz, nada akhir Hz, getar Hz, dalam getar, bagian derau).
REM = (0.45, 2600.0, 2000.0, 38.0, 0.015, 0.12)
# Ban mendesis: (detik, frekuensi potong lolos-atas Hz, peluruhan detik).
BAN = (0.65, 3200.0, 0.30)
# Servis: tiga ketukan ratchet lalu dua dentingan naik.
SERVIS_DETIK = 0.60
SERVIS_KETUK = (0.02, 0.09, 0.16)
SERVIS_DENTING = ((0.26, 660.0), (0.38, 880.0))
SERVIS_LURUH_DETIK = 0.11
# Upgrade: empat nada naik (Hz) tiap `UPGRADE_LANGKAH_DETIK`.
UPGRADE_DETIK = 0.80
UPGRADE_NADA = (523.25, 659.25, 783.99, 1046.5)
UPGRADE_LANGKAH_DETIK = 0.12
UPGRADE_LURUH_DETIK = 0.20

NAMA = [
    'condition/sfx_cond_rantai_berisik_01.wav',
    'condition/sfx_cond_rem_berdecit_01.wav',
    'condition/sfx_cond_ban_mendesis_01.wav',
    'condition/sfx_cond_servis_01.wav',
    'condition/sfx_cond_upgrade_01.wav',
]


def semua_nama():
    """Ke-5 nama (subfolder/nama), urut tulis."""
    return list(NAMA)


def _jumlah(detik):
    return int(round(detik * LAJU_SAMPEL))


def _amplop(n, serang_detik, lepas_detik):
    """Amplop sekali putar: naik setengah kosinus dari nol, rata, turun sampai tepat nol di akhir."""
    serang = max(1, int(serang_detik * LAJU_SAMPEL))
    lepas = max(2, int(lepas_detik * LAJU_SAMPEL))
    hasil = []
    for i in range(n):
        if i < serang:
            a = 0.5 * (1.0 - math.cos(math.pi * i / serang))
        elif i >= n - lepas:
            a = 0.5 * (1.0 + math.cos(math.pi * (i - (n - lepas)) / (lepas - 1)))
        else:
            a = 1.0
        hasil.append(a)
    return hasil


def _pita(masukan, pusat_hz, lebar_pita_hz):
    """Lolos-pita dua kutub dengan pusat `pusat_hz` dan lebar pita `lebar_pita_hz`."""
    r = math.exp(-math.pi * lebar_pita_hz / LAJU_SAMPEL)
    theta = 2.0 * math.pi * pusat_hz / LAJU_SAMPEL
    y1 = 0.0
    y2 = 0.0
    keluaran = []
    for x in masukan:
        y = (1.0 - r) * x + 2.0 * r * math.cos(theta) * y1 - r * r * y2
        keluaran.append(y)
        y2 = y1
        y1 = y
    return keluaran


def _lolos_atas(masukan, potong_hz):
    """Lolos-atas satu kutub dengan frekuensi potong `potong_hz`."""
    a = math.exp(-2.0 * math.pi * potong_hz / LAJU_SAMPEL)
    keluaran = []
    x_sebelum = 0.0
    y_sebelum = 0.0
    for x in masukan:
        y = a * (y_sebelum + x - x_sebelum)
        keluaran.append(y)
        x_sebelum = x
        y_sebelum = y
    return keluaran


def _normalkan(sampel, puncak_sasaran):
    puncak = max(abs(s) for s in sampel)
    skala = puncak_sasaran / puncak if puncak > 0.0 else 0.0
    return [s * skala for s in sampel]


def _ke_int16(sampel):
    batas = 32767
    return [max(-batas, min(batas, int(round(s * batas)))) for s in sampel]


def _selesai(sampel, amplop, puncak_sasaran):
    return _ke_int16(_normalkan([s * a for s, a in zip(sampel, amplop)], puncak_sasaran))


def rantai_berisik(acak):
    detik, mulai, pusat, lebar, luruh = RANTAI
    n = _jumlah(detik)
    derau = [acak.random() * 2.0 - 1.0 for _ in range(n)]
    pita = _pita(derau, pusat, lebar)
    hasil = [0.0] * n
    for k, t0 in enumerate(mulai):
        awal = _jumlah(t0)
        kuat = 0.7 + 0.3 * acak.random()
        for i in range(awal, min(n, awal + _jumlah(luruh * 7.0))):
            t = (i - awal) / LAJU_SAMPEL
            naik = min(1.0, t / 0.0015)
            hasil[i] += pita[i] * math.exp(-t / luruh) * naik * kuat
    return _selesai(hasil, _amplop(n, 0.002, 0.06), PUNCAK)


def rem_berdecit(acak):
    detik, awal, akhir, getar, dalam, bagian_derau = REM
    n = _jumlah(detik)
    hasil = []
    fase = 0.0
    fase_getar = acak.random() * 2.0 * math.pi
    for i in range(n):
        t = i / n
        f = awal + (akhir - awal) * t
        f *= 1.0 + dalam * math.sin(2.0 * math.pi * getar * (i / LAJU_SAMPEL) + fase_getar)
        fase += 2.0 * math.pi * f / LAJU_SAMPEL
        nilai = math.sin(fase) + 0.4 * math.sin(2.0 * fase) + bagian_derau * (acak.random() * 2.0 - 1.0)
        hasil.append(nilai)
    return _selesai(hasil, _amplop(n, 0.02, 0.12), PUNCAK)


def ban_mendesis(acak):
    detik, potong, luruh = BAN
    n = _jumlah(detik)
    derau = [acak.random() * 2.0 - 1.0 for _ in range(n)]
    tinggi = _lolos_atas(derau, potong)
    hasil = []
    for i in range(n):
        t = i / LAJU_SAMPEL
        hasil.append(tinggi[i] * math.exp(-t / luruh))
    return _selesai(hasil, _amplop(n, 0.03, 0.2), PUNCAK)


def servis(acak):
    n = _jumlah(SERVIS_DETIK)
    hasil = [0.0] * n
    derau = [acak.random() * 2.0 - 1.0 for _ in range(n)]
    pita = _pita(derau, 1800.0, 1200.0)
    for t0 in SERVIS_KETUK:
        awal = _jumlah(t0)
        for i in range(awal, min(n, awal + _jumlah(0.05))):
            t = (i - awal) / LAJU_SAMPEL
            hasil[i] += pita[i] * math.exp(-t / 0.012) * min(1.0, t / 0.001) * 0.9
    for t0, nada in SERVIS_DENTING:
        awal = _jumlah(t0)
        for i in range(awal, n):
            t = (i - awal) / LAJU_SAMPEL
            naik = min(1.0, t / 0.003)
            hasil[i] += (math.sin(2.0 * math.pi * nada * t) + 0.3 * math.sin(2.0 * math.pi * nada * 2.0 * t)) * math.exp(-t / SERVIS_LURUH_DETIK) * naik
    return _selesai(hasil, _amplop(n, 0.002, 0.08), PUNCAK)


def upgrade(acak):
    n = _jumlah(UPGRADE_DETIK)
    hasil = [0.0] * n
    langkah = _jumlah(UPGRADE_LANGKAH_DETIK)
    for k, nada in enumerate(UPGRADE_NADA):
        mulai = k * langkah
        luruh = UPGRADE_LURUH_DETIK * (2.0 if k == len(UPGRADE_NADA) - 1 else 1.0)
        for i in range(max(n - mulai, 0)):
            t = i / LAJU_SAMPEL
            naik = min(1.0, t / 0.002)
            segitiga = (2.0 / math.pi) * math.asin(math.sin(2.0 * math.pi * nada * t))
            kilau = math.sin(2.0 * math.pi * nada * 3.0 * t)
            hasil[mulai + i] += (segitiga + 0.25 * kilau) * math.exp(-t / luruh) * naik
    acak.random()
    return _selesai(hasil, _amplop(n, 0.002, 0.1), PUNCAK)


def tulis_wav(jalur, sampel):
    with wave.open(jalur, 'wb') as berkas:
        berkas.setnchannels(1)
        berkas.setsampwidth(LEBAR_SAMPEL)
        berkas.setframerate(LAJU_SAMPEL)
        berkas.writeframes(struct.pack('<%dh' % len(sampel), *sampel))


def bangun(folder):
    """Membuat ke-5 WAV ke subfolder `condition` di `folder`. Mengembalikan daftar (subfolder/nama, jumlah sampel)."""
    acak = random.Random(BENIH)
    pembuat = list(zip(NAMA, [rantai_berisik, rem_berdecit, ban_mendesis, servis, upgrade]))
    hasil = []
    for nama, fungsi in pembuat:
        jalur = os.path.join(folder, nama)
        os.makedirs(os.path.dirname(jalur), exist_ok=True)
        sampel = fungsi(acak)
        tulis_wav(jalur, sampel)
        hasil.append((nama, len(sampel)))
    return hasil


def main():
    pengurai = argparse.ArgumentParser(description='Sintesis bunyi placeholder kondisi sepeda run 6A1 (rantai berisik, rem berdecit, ban mendesis, servis, upgrade).')
    pengurai.add_argument('--out', default=KELUARAN_BAWAAN, help='folder induk keluaran (bawaan: assets/audio/sfx)')
    argumen = pengurai.parse_args()
    for nama, jumlah in bangun(argumen.out):
        print('%s: %d sampel, %.3f detik' % (os.path.join(argumen.out, nama), jumlah, jumlah / LAJU_SAMPEL))
    return 0


if __name__ == '__main__':
    sys.exit(main())
