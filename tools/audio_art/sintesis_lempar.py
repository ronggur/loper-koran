#!/usr/bin/env python3
"""Sintesis bunyi placeholder lempar dan mendarat (SOUND_DESIGN 3.1 dan 4.2, D-9 run fase2b-bantu-audio). Hanya pustaka standar.

Menulis 13 WAV mono 16-bit 22050 Hz (laju sama dengan bunyi sepeda), dibuat sendiri dari rumus (tanpa rekaman, tanpa unduhan):
  sfx_throw_whoosh_01.wav       "wus": desis derau pita sempit yang pusatnya naik lalu turun, 0,20 detik.
  sfx_land_mailbox_0{1,2,3}.wav "tunk" logam pendek bernada naik: parsial tak harmonis + ketukan, 0,17 / 0,20 / 0,23 detik.
  sfx_land_porch_0{1,2,3}.wav   "plak" kertas renyah di lantai: tamparan derau tinggi + gemeresik + dentum badan, 0,16 / 0,19 / 0,22 detik.
  sfx_land_grass_0{1,2,3}.wav   "puk" lembut redup: derau lolos-bawah + dentum rendah dengan serangan lunak, 0,15 / 0,17 / 0,19 detik.
  sfx_land_miss_0{1,2,3}.wav    "plek" datar: derau pita tengah pendek, 0,14 / 0,15 / 0,16 detik, puncak lebih rendah (`PUNCAK_MELESET`).

Tiga variasi tiap permukaan berbeda nada, warna, dan panjang (bukan salinan). Keluaran deterministik: acak hanya dari
`random.Random(BENIH)` dengan benih tetap dan hanya `random()`, jadi dua kali jalan menghasilkan byte yang sama (diperiksa
`tools/tests_cek/uji_sintesis_lempar.py`). Semua bunyi sekali putar: serangan dan lepas setengah kosinus sampai tepat nol,
jadi sampel pertama dan terakhir tepat nol (tanpa klik). Puncak dinormalkan ke `PUNCAK` (meleset ke `PUNCAK_MELESET`, sekitar 5 dB
lebih pelan, SOUND_DESIGN 3.1); keras-pelan saat main diatur di Godot lewat `Config.AUDIO_WUS_VOLUME_DB` dan
`Config.AUDIO_MENDARAT_VOLUME_DB`, bukan di sini.

Cara pakai (dari root repo):
    python3 tools/audio_art/sintesis_lempar.py                 # tulis ke assets/audio/sfx/throw/
    python3 tools/audio_art/sintesis_lempar.py --out build/x   # tulis ke folder lain (untuk uji)
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
# Meleset "lebih pelan" (SOUND_DESIGN 3.1): sekitar -6 dBFS, 5 dB di bawah permukaan lain.
PUNCAK_MELESET = 0.5
BENIH = 20261015
FOLDER = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(FOLDER, '..', '..'))
KELUARAN_BAWAAN = os.path.join(ROOT, 'assets', 'audio', 'sfx', 'throw')

NAMA_WUS = 'sfx_throw_whoosh_01.wav'

# "Wus": derau putih lewat resonator yang pusatnya bergeser naik lalu turun (sinus setengah putaran).
WUS_DETIK = 0.20
WUS_PUSAT_AWAL_HZ = 700.0
WUS_PUSAT_NAIK_HZ = 1500.0
WUS_LEBAR_PITA_HZ = 650.0

# Kotak surat: (detik, nada dasar Hz, luruh nada dasar detik). Parsial tak harmonis (kelipatan, kuat, pengali luruh).
KOTAK_VARIASI = ((0.17, 520.0, 0.050), (0.20, 600.0, 0.060), (0.23, 690.0, 0.072))
KOTAK_PARSIAL = ((1.0, 1.0, 1.0), (2.41, 0.55, 0.6), (3.93, 0.32, 0.4), (5.62, 0.16, 0.28))
KOTAK_NAIK = 0.12
KOTAK_NAIK_DETIK = 0.03
KOTAK_KETUK_HZ = 3100.0
KOTAK_KETUK_LURUH_DETIK = 0.0025
KOTAK_KETUK_KUAT = 0.45

# Teras: (detik, pusat tamparan Hz, jumlah gemeresik, nada badan Hz).
TERAS_VARIASI = ((0.16, 2600.0, 2, 170.0), (0.19, 3000.0, 3, 150.0), (0.22, 3500.0, 4, 190.0))
TERAS_TAMPAR_LURUH_DETIK = 0.010
TERAS_GEMERESIK_LURUH_DETIK = 0.004
TERAS_GEMERESIK_KUAT = 0.5
TERAS_BADAN_LURUH_DETIK = 0.018
TERAS_BADAN_KUAT = 0.55

# Rumput: (detik, nada dentum Hz, koefisien lolos-bawah derau 0..1; makin kecil makin redup).
RUMPUT_VARIASI = ((0.15, 105.0, 0.06), (0.17, 122.0, 0.09), (0.19, 140.0, 0.045))
RUMPUT_DENTUM_LURUH_DETIK = 0.035
RUMPUT_DERAU_LURUH_DETIK = 0.03
RUMPUT_DERAU_KUAT = 0.9

# Meleset: (detik, pusat derau Hz, nada datar Hz).
MELESET_VARIASI = ((0.14, 950.0, 260.0), (0.15, 1150.0, 300.0), (0.16, 1350.0, 340.0))
MELESET_LEBAR_PITA_HZ = 900.0
MELESET_LURUH_DETIK = 0.016
MELESET_NADA_KUAT = 0.35

SERANG_KERAS_DETIK = 0.003
SERANG_LUNAK_DETIK = 0.008
LEPAS_DETIK = 0.03

PERMUKAAN = ('mailbox', 'porch', 'grass', 'miss')


def nama_mendarat(permukaan, variasi):
    """Nama berkas bunyi mendarat (SOUND_DESIGN 6), `variasi` mulai 1."""
    return 'sfx_land_%s_%02d.wav' % (permukaan, variasi)


def semua_nama():
    """Ke-13 nama berkas, urut tulis."""
    return [NAMA_WUS] + [nama_mendarat(p, v) for p in PERMUKAAN for v in (1, 2, 3)]


def _jumlah(detik):
    return int(round(detik * LAJU_SAMPEL))


def _amplop(n, serang_detik, lepas_detik):
    """Amplop sekali putar: naik setengah kosinus dari tepat nol, rata, lalu turun setengah kosinus sampai tepat nol di sampel terakhir."""
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


def _pita(masukan, pusat_hz, lebar_pita_hz):
    """Lolos-pita dua kutub dengan pusat `pusat_hz` (angka tetap atau daftar per sampel) dan lebar pita `lebar_pita_hz`."""
    r = math.exp(-math.pi * lebar_pita_hz / LAJU_SAMPEL)
    y1 = 0.0
    y2 = 0.0
    keluaran = []
    for i, x in enumerate(masukan):
        pusat = pusat_hz[i] if isinstance(pusat_hz, list) else pusat_hz
        theta = 2.0 * math.pi * pusat / LAJU_SAMPEL
        y = (1.0 - r) * x + 2.0 * r * math.cos(theta) * y1 - r * r * y2
        keluaran.append(y)
        y2 = y1
        y1 = y
    return keluaran


def _derau(acak, n):
    return [acak.random() * 2.0 - 1.0 for _ in range(n)]


def _normalkan(sampel, puncak_sasaran):
    puncak = max(abs(s) for s in sampel)
    skala = puncak_sasaran / puncak if puncak > 0.0 else 0.0
    return [s * skala for s in sampel]


def _ke_int16(sampel):
    batas = 32767
    return [max(-batas, min(batas, int(round(s * batas)))) for s in sampel]


def _selesai(sampel, amplop, puncak_sasaran):
    return _ke_int16(_normalkan([s * a for s, a in zip(sampel, amplop)], puncak_sasaran))


def wus(acak):
    n = _jumlah(WUS_DETIK)
    pusat = [WUS_PUSAT_AWAL_HZ + WUS_PUSAT_NAIK_HZ * math.sin(math.pi * i / (n - 1)) for i in range(n)]
    desis = _pita(_derau(acak, n), pusat, WUS_LEBAR_PITA_HZ)
    # Keras-pelan mengikuti sin^2: mulai dan berakhir di nol, terkeras di tengah ayunan.
    amplop = [math.sin(math.pi * i / (n - 1)) ** 2 for i in range(n)]
    amplop[-1] = 0.0
    return _selesai(desis, amplop, PUNCAK)


def kotak_surat(acak, variasi):
    detik, dasar_hz, luruh = KOTAK_VARIASI[variasi]
    n = _jumlah(detik)
    fase = [0.0] * len(KOTAK_PARSIAL)
    hasil = []
    for i in range(n):
        t = i / LAJU_SAMPEL
        # Nada naik cepat lalu bertahan ("tunk" bernada naik, SOUND_DESIGN 3.1).
        frekuensi = dasar_hz * (1.0 + KOTAK_NAIK * (1.0 - math.exp(-t / KOTAK_NAIK_DETIK)))
        nilai = 0.0
        for k, (kelipatan, kuat, pengali_luruh) in enumerate(KOTAK_PARSIAL):
            fase[k] += 2.0 * math.pi * frekuensi * kelipatan / LAJU_SAMPEL
            nilai += kuat * math.sin(fase[k]) * math.exp(-t / (luruh * pengali_luruh))
        hasil.append(nilai)
    ketuk = _resonator(_derau(acak, n), KOTAK_KETUK_HZ, KOTAK_KETUK_LURUH_DETIK)
    puncak_ketuk = max(abs(v) for v in ketuk) or 1.0
    for i in range(n):
        hasil[i] += ketuk[i] / puncak_ketuk * KOTAK_KETUK_KUAT * math.exp(-i / (KOTAK_KETUK_LURUH_DETIK * 2.0 * LAJU_SAMPEL))
    return _selesai(hasil, _amplop(n, SERANG_KERAS_DETIK, LEPAS_DETIK), PUNCAK)


def teras(acak, variasi):
    detik, tampar_hz, gemeresik, badan_hz = TERAS_VARIASI[variasi]
    n = _jumlah(detik)
    # Tamparan: derau lolos-tinggi (selisih sampel) lewat pita tinggi, meluruh cepat.
    mentah = _derau(acak, n)
    tinggi = [mentah[0]] + [mentah[i] - mentah[i - 1] for i in range(1, n)]
    tampar = _pita(tinggi, tampar_hz, tampar_hz * 0.6)
    hasil = [tampar[i] * math.exp(-i / (TERAS_TAMPAR_LURUH_DETIK * LAJU_SAMPEL)) for i in range(n)]
    puncak = max(abs(v) for v in hasil) or 1.0
    hasil = [v / puncak for v in hasil]
    # Gemeresik kertas: beberapa semburan kecil sesudah tamparan.
    for k in range(gemeresik):
        mulai = int((0.012 + 0.011 * k + 0.004 * acak.random()) * LAJU_SAMPEL)
        kuat = TERAS_GEMERESIK_KUAT * (1.0 - 0.18 * k)
        for i in range(int(TERAS_GEMERESIK_LURUH_DETIK * 6 * LAJU_SAMPEL)):
            if mulai + i < n:
                hasil[mulai + i] += (acak.random() * 2.0 - 1.0) * kuat * math.exp(-i / (TERAS_GEMERESIK_LURUH_DETIK * LAJU_SAMPEL))
    # Dentum badan koran di lantai.
    for i in range(n):
        hasil[i] += TERAS_BADAN_KUAT * math.sin(2.0 * math.pi * badan_hz * i / LAJU_SAMPEL) * math.exp(-i / (TERAS_BADAN_LURUH_DETIK * LAJU_SAMPEL))
    return _selesai(hasil, _amplop(n, SERANG_KERAS_DETIK, LEPAS_DETIK), PUNCAK)


def rumput(acak, variasi):
    detik, dentum_hz, lolos_bawah = RUMPUT_VARIASI[variasi]
    n = _jumlah(detik)
    hasil = []
    lalu = 0.0
    for i in range(n):
        t = i / LAJU_SAMPEL
        lalu += lolos_bawah * ((acak.random() * 2.0 - 1.0) - lalu)
        derau = lalu * RUMPUT_DERAU_KUAT * math.exp(-t / RUMPUT_DERAU_LURUH_DETIK) / max(lolos_bawah, 1e-9) ** 0.5
        dentum = math.sin(2.0 * math.pi * dentum_hz * t) * math.exp(-t / RUMPUT_DENTUM_LURUH_DETIK)
        hasil.append(derau + dentum)
    return _selesai(hasil, _amplop(n, SERANG_LUNAK_DETIK, LEPAS_DETIK), PUNCAK)


def meleset(acak, variasi):
    detik, pusat_hz, nada_hz = MELESET_VARIASI[variasi]
    n = _jumlah(detik)
    derau = _pita(_derau(acak, n), pusat_hz, MELESET_LEBAR_PITA_HZ)
    puncak = max(abs(v) for v in derau) or 1.0
    hasil = []
    for i in range(n):
        t = i / LAJU_SAMPEL
        luruh = math.exp(-t / MELESET_LURUH_DETIK)
        hasil.append((derau[i] / puncak + MELESET_NADA_KUAT * math.sin(2.0 * math.pi * nada_hz * t)) * luruh)
    return _selesai(hasil, _amplop(n, SERANG_KERAS_DETIK, LEPAS_DETIK), PUNCAK_MELESET)


def tulis_wav(jalur, sampel):
    with wave.open(jalur, 'wb') as berkas:
        berkas.setnchannels(1)
        berkas.setsampwidth(LEBAR_SAMPEL)
        berkas.setframerate(LAJU_SAMPEL)
        berkas.writeframes(struct.pack('<%dh' % len(sampel), *sampel))


def bangun(folder):
    """Membuat ke-13 WAV ke `folder`. Mengembalikan daftar (nama, jumlah sampel)."""
    os.makedirs(folder, exist_ok=True)
    acak = random.Random(BENIH)
    pembuat = {'mailbox': kotak_surat, 'porch': teras, 'grass': rumput, 'miss': meleset}
    hasil = []
    sampel = wus(acak)
    tulis_wav(os.path.join(folder, NAMA_WUS), sampel)
    hasil.append((NAMA_WUS, len(sampel)))
    for permukaan in PERMUKAAN:
        for variasi in range(3):
            nama = nama_mendarat(permukaan, variasi + 1)
            sampel = pembuat[permukaan](acak, variasi)
            tulis_wav(os.path.join(folder, nama), sampel)
            hasil.append((nama, len(sampel)))
    return hasil


def main():
    pengurai = argparse.ArgumentParser(description='Sintesis bunyi placeholder lempar ("wus") dan mendarat (empat permukaan x 3 variasi).')
    pengurai.add_argument('--out', default=KELUARAN_BAWAAN, help='folder keluaran (bawaan: assets/audio/sfx/throw)')
    argumen = pengurai.parse_args()
    for nama, jumlah in bangun(argumen.out):
        print('%s: %d sampel, %.3f detik' % (os.path.join(argumen.out, nama), jumlah, jumlah / LAJU_SAMPEL))
    return 0


if __name__ == '__main__':
    sys.exit(main())
