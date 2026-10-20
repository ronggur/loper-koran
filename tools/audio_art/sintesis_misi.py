#!/usr/bin/env python3
"""Sintesis bunyi placeholder misi kucing run 4B: petunjuk, kucing terlihat, misi selesai, dan misi gagal (SOUND_DESIGN 3.1, 4; AC-15 run
fase4b-misi-kucing, usulan). Hanya pustaka standar.

Menulis 4 WAV mono 16-bit 22050 Hz (laju sama dengan bunyi sepeda, lempar, dan rute), dibuat sendiri dari rumus (tanpa rekaman, tanpa unduhan):
  mission/sfx_mis_meong_01.wav     "meong" petunjuk dari pelanggan: nada naik lalu turun dengan getar dan forman suara "e-o", 0,55 detik.
  mission/sfx_mis_terlihat_01.wav  kucing mulai terlihat: "mrik" kecil nada naik cepat, 0,28 detik (pasangan visual: kilau di atas kepala).
  mission/sfx_mis_selesai_01.wav   misi selesai: tiga nada naik (do mi sol) lalu satu nada panjang hangat, 0,70 detik (pasangan visual: banner "Kucing ketemu!").
  mission/sfx_mis_gagal_01.wav     misi gagal: dua nada turun lembut, 0,50 detik, sekitar 3 dB lebih pelan (pasangan visual: banner "Kucingnya lolos hari ini";
                                   SOUND_DESIGN 2: gagal berbunyi lembut, tidak menghakimi).

Keluaran deterministik: acak hanya dari `random.Random(BENIH)` dengan benih tetap dan hanya `random()`, jadi dua kali jalan menghasilkan byte yang
sama (diperiksa `tools/tests_cek/uji_sintesis_misi.py`). Semua bunyi sekali putar: sampel pertama dan terakhir tepat nol (tanpa klik). Puncak
dinormalkan ke `PUNCAK` (gagal ke `PUNCAK_LEMBUT`); keras-pelan saat main diatur di Godot lewat `Config.AUDIO_*_VOLUME_DB`, bukan di sini.

Cara pakai (dari root repo):
    python3 tools/audio_art/sintesis_misi.py                 # tulis ke assets/audio/sfx/mission/
    python3 tools/audio_art/sintesis_misi.py --out build/x   # tulis ke folder lain (subfolder mission), untuk uji
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
PUNCAK_LEMBUT = 0.63
BENIH = 20261018
FOLDER = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(FOLDER, '..', '..'))
KELUARAN_BAWAAN = os.path.join(ROOT, 'assets', 'audio', 'sfx')
SERANG_DETIK = 0.006
LEPAS_DETIK = 0.05

# Meong: (detik, nada awal Hz, nada puncak Hz, nada akhir Hz, getar Hz, dalam getar).
MEONG = (0.55, 520.0, 780.0, 480.0, 6.0, 0.02)
# Forman "e" lalu "o" (Hz) dan lebar pita.
MEONG_FORMAN = ((2300.0, 1000.0), (900.0, 500.0))
MEONG_FORMAN_KUAT = 1.2
# Terlihat: (detik, nada awal Hz, nada akhir Hz).
TERLIHAT = (0.28, 700.0, 1150.0)
# Selesai: tiga nada naik (Hz) tiap `SELESAI_LANGKAH_DETIK`, lalu nada panjang; total detik.
SELESAI_DETIK = 0.70
SELESAI_NADA = (523.25, 659.25, 783.99, 1046.5)
SELESAI_LANGKAH_DETIK = 0.14
SELESAI_LURUH_DETIK = 0.22
# Gagal: dua nada turun lembut.
GAGAL_DETIK = 0.50
GAGAL_NADA = (493.88, 392.0)
GAGAL_LANGKAH_DETIK = 0.20
GAGAL_LURUH_DETIK = 0.16

NAMA = ['mission/sfx_mis_meong_01.wav', 'mission/sfx_mis_terlihat_01.wav', 'mission/sfx_mis_selesai_01.wav', 'mission/sfx_mis_gagal_01.wav']


def semua_nama():
    """Ke-4 nama (subfolder/nama), urut tulis."""
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


def _normalkan(sampel, puncak_sasaran):
    puncak = max(abs(s) for s in sampel)
    skala = puncak_sasaran / puncak if puncak > 0.0 else 0.0
    return [s * skala for s in sampel]


def _ke_int16(sampel):
    batas = 32767
    return [max(-batas, min(batas, int(round(s * batas)))) for s in sampel]


def _selesai(sampel, amplop, puncak_sasaran):
    return _ke_int16(_normalkan([s * a for s, a in zip(sampel, amplop)], puncak_sasaran))


def meong(acak):
    detik, awal, puncak, akhir, getar, dalam = MEONG
    n = _jumlah(detik)
    # Sumber: gelombang gergaji bernada meluncur (naik ke puncak di sepertiga pertama, lalu turun), disaring dua forman bergantian "e" -> "o".
    sumber = []
    fase = 0.0
    fase_getar = acak.random() * 2.0 * math.pi
    for i in range(n):
        t = i / n
        if t < 0.35:
            f = awal + (puncak - awal) * (t / 0.35)
        else:
            f = puncak + (akhir - puncak) * ((t - 0.35) / 0.65)
        f *= 1.0 + dalam * math.sin(2.0 * math.pi * getar * (i / LAJU_SAMPEL) + fase_getar)
        fase += 2.0 * math.pi * f / LAJU_SAMPEL
        sumber.append(sum(math.sin(h * fase) / h for h in range(1, 9)))
    e = _pita(sumber, MEONG_FORMAN[0][0], MEONG_FORMAN[0][1])
    o = _pita(sumber, MEONG_FORMAN[1][0], MEONG_FORMAN[1][1])
    pe = max(abs(v) for v in e) or 1.0
    po = max(abs(v) for v in o) or 1.0
    hasil = []
    for i in range(n):
        t = i / n
        campur = min(1.0, max(0.0, (t - 0.25) / 0.5))
        hasil.append(MEONG_FORMAN_KUAT * ((1.0 - campur) * e[i] / pe + campur * o[i] / po) + 0.25 * sumber[i] / 3.0)
    return _selesai(hasil, _amplop(n, 0.04, 0.12), PUNCAK)


def terlihat(acak):
    detik, awal, akhir = TERLIHAT
    n = _jumlah(detik)
    hasil = []
    fase = 0.0
    for i in range(n):
        t = i / n
        f = awal + (akhir - awal) * t * t
        fase += 2.0 * math.pi * f / LAJU_SAMPEL
        hasil.append(math.sin(fase) + 0.35 * math.sin(2.0 * fase))
    acak.random()
    return _selesai(hasil, _amplop(n, 0.01, 0.1), PUNCAK)


def selesai(acak):
    n = _jumlah(SELESAI_DETIK)
    hasil = [0.0] * n
    langkah = _jumlah(SELESAI_LANGKAH_DETIK)
    for k, nada in enumerate(SELESAI_NADA):
        mulai = k * langkah
        panjang = n - mulai
        luruh = SELESAI_LURUH_DETIK * (2.2 if k == len(SELESAI_NADA) - 1 else 1.0)
        for i in range(max(panjang, 0)):
            t = i / LAJU_SAMPEL
            naik = min(1.0, t / 0.003)
            nilai = math.sin(2.0 * math.pi * nada * t) + 0.3 * math.sin(2.0 * math.pi * nada * 2.0 * t)
            hasil[mulai + i] += nilai * math.exp(-t / luruh) * naik
    acak.random()
    return _selesai(hasil, _amplop(n, 0.002, 0.08), PUNCAK)


def gagal(acak):
    n = _jumlah(GAGAL_DETIK)
    hasil = [0.0] * n
    langkah = _jumlah(GAGAL_LANGKAH_DETIK)
    for k, nada in enumerate(GAGAL_NADA):
        mulai = k * langkah
        for i in range(max(n - mulai, 0)):
            t = i / LAJU_SAMPEL
            naik = min(1.0, t / 0.01)
            hasil[mulai + i] += math.sin(2.0 * math.pi * nada * t) * math.exp(-t / GAGAL_LURUH_DETIK) * naik
    acak.random()
    return _selesai(hasil, _amplop(n, 0.004, 0.1), PUNCAK_LEMBUT)


def tulis_wav(jalur, sampel):
    with wave.open(jalur, 'wb') as berkas:
        berkas.setnchannels(1)
        berkas.setsampwidth(LEBAR_SAMPEL)
        berkas.setframerate(LAJU_SAMPEL)
        berkas.writeframes(struct.pack('<%dh' % len(sampel), *sampel))


def bangun(folder):
    """Membuat ke-4 WAV ke subfolder `mission` di `folder`. Mengembalikan daftar (subfolder/nama, jumlah sampel)."""
    acak = random.Random(BENIH)
    pembuat = [
        ('mission/sfx_mis_meong_01.wav', meong),
        ('mission/sfx_mis_terlihat_01.wav', terlihat),
        ('mission/sfx_mis_selesai_01.wav', selesai),
        ('mission/sfx_mis_gagal_01.wav', gagal),
    ]
    hasil = []
    for nama, fungsi in pembuat:
        jalur = os.path.join(folder, nama)
        os.makedirs(os.path.dirname(jalur), exist_ok=True)
        sampel = fungsi(acak)
        tulis_wav(jalur, sampel)
        hasil.append((nama, len(sampel)))
    return hasil


def main():
    pengurai = argparse.ArgumentParser(description='Sintesis bunyi placeholder misi kucing run 4B (petunjuk, terlihat, selesai, gagal).')
    pengurai.add_argument('--out', default=KELUARAN_BAWAAN, help='folder induk keluaran (bawaan: assets/audio/sfx)')
    argumen = pengurai.parse_args()
    for nama, jumlah in bangun(argumen.out):
        print('%s: %d sampel, %.3f detik' % (os.path.join(argumen.out, nama), jumlah, jumlah / LAJU_SAMPEL))
    return 0


if __name__ == '__main__':
    sys.exit(main())
