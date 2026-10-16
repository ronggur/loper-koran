#!/usr/bin/env python3
"""Sintesis bunyi placeholder rute run 3B: rintangan, tabrakan, bel, tip, dan tepat (SOUND_DESIGN 3.1, 3.3, 4.1-4.3; AC-19 run
fase3b-rintangan-skor). Hanya pustaka standar.

Menulis 10 WAV mono 16-bit 22050 Hz (laju sama dengan bunyi sepeda dan lempar), dibuat sendiri dari rumus (tanpa rekaman, tanpa unduhan):
  obstacle/sfx_obs_dog_growl.wav  geraman anjing waspada: dengung rendah bergetar + desis, 0,80 detik.
  obstacle/sfx_obs_dog_bark_01.wav gonggongan anjing mulai mengejar: dua "guk" pendek bernada turun, 0,42 detik.
  obstacle/sfx_obs_car_beep.wav   bip lampu mundur: tiga bip 1100 Hz (0,25 detik bunyi, 0,25 senyap) selama tanda 1,5 detik.
  obstacle/sfx_obs_car_engine.wav mesin mobil mundur: gemuruh rendah dengan denyut silinder, 1,00 detik.
  obstacle/sfx_obs_crash_01.wav   tabrakan lembut: "bruk" rendah + kerincing logam kecil, 0,45 detik (SOUND_DESIGN 2: gagal berbunyi lembut).
  bell/sfx_bike_bell_0{1,2,3}.wav "kring" bel sepeda: parsial logam tak harmonis dengan getar pemukul, 0,40 / 0,36 / 0,44 detik, tiga
                                  variasi (nada dasar berbeda). "Kring kring!" = variasi berikutnya diputar sedikit lebih tinggi
                                  (`Config.AUDIO_BEL_KEDUA_SEMITON`), bukan berkas lain.
  ui/sfx_ui_tip_01.wav            denting koin tip, 0,35 detik, diawali 0,12 detik senyap supaya terdengar SESUDAH bunyi mendarat.
  ui/sfx_ui_tepat_01.wav          kilau "tepat": dua nada naik cepat, 0,30 detik, diawali 0,05 detik senyap (di atas bunyi kotak surat).

Keluaran deterministik: acak hanya dari `random.Random(BENIH)` dengan benih tetap dan hanya `random()`, jadi dua kali jalan menghasilkan
byte yang sama (diperiksa `tools/tests_cek/uji_sintesis_rute.py`). Semua bunyi sekali putar: sampel pertama dan terakhir tepat nol (tanpa
klik); bunyi berawalan senyap mulai dari nol. Puncak dinormalkan ke `PUNCAK` (tabrakan ke `PUNCAK_LEMBUT`, lebih pelan); keras-pelan saat
main diatur di Godot lewat `Config.AUDIO_*_VOLUME_DB`, bukan di sini.

Cara pakai (dari root repo):
    python3 tools/audio_art/sintesis_rute.py                 # tulis ke assets/audio/sfx/{obstacle,bell,ui}/
    python3 tools/audio_art/sintesis_rute.py --out build/x   # tulis ke folder lain (subfolder sama), untuk uji
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
# Tabrakan "lembut" (SOUND_DESIGN 2 butir 2): sekitar 3 dB di bawah bunyi lain.
PUNCAK_LEMBUT = 0.63
BENIH = 20261017
FOLDER = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(FOLDER, '..', '..'))
KELUARAN_BAWAAN = os.path.join(ROOT, 'assets', 'audio', 'sfx')

SERANG_DETIK = 0.004
LEPAS_DETIK = 0.03

# Geraman: (detik, nada dasar Hz, getar Hz).
GERAM = (0.80, 95.0, 23.0)
GERAM_DESIS_KUAT = 0.25
# Gonggongan: dua "guk" (mulai detik, panjang detik, nada awal Hz, nada akhir Hz) di dalam berkas 0,42 detik.
GONGGONG_DETIK = 0.42
GONGGONG_GUK = ((0.0, 0.16, 520.0, 300.0), (0.22, 0.18, 480.0, 260.0))
GONGGONG_FORMAN_HZ = 1300.0
# Bip lampu mundur: tiga bip.
BIP_DETIK = 1.5
BIP_HZ = 1100.0
BIP_NYALA_DETIK = 0.25
BIP_PERIODE_DETIK = 0.5
# Mesin: (detik, nada dasar Hz, denyut Hz).
MESIN = (1.0, 55.0, 12.0)
# Tabrakan: dentum rendah + kerincing.
TABRAK_DETIK = 0.45
TABRAK_DENTUM_HZ = 70.0
TABRAK_DENTUM_LURUH_DETIK = 0.07
TABRAK_KERINCING = ((0.03, 2900.0), (0.09, 3700.0), (0.16, 3300.0))
TABRAK_KERINCING_LURUH_DETIK = 0.05
TABRAK_KERINCING_KUAT = 0.35
# Bel: (detik, nada dasar Hz). Parsial bel tak harmonis (kelipatan, kuat, pengali luruh) dan getar pemukul.
BEL_VARIASI = ((0.40, 2100.0), (0.36, 2350.0), (0.44, 1900.0))
BEL_PARSIAL = ((1.0, 1.0, 1.0), (1.52, 0.55, 0.8), (2.33, 0.35, 0.55), (3.17, 0.2, 0.4))
BEL_LURUH_DETIK = 0.16
BEL_GETAR_HZ = 32.0
BEL_GETAR_DALAM = 0.45
# Tip: (senyap awal, panjang denting, nada Hz).
TIP = (0.12, 0.23, 1568.0)
TIP_LURUH_DETIK = 0.06
# Tepat: (senyap awal, panjang, nada pertama Hz, nada kedua Hz).
TEPAT = (0.05, 0.25, 1319.0, 1976.0)
TEPAT_LURUH_DETIK = 0.05

NAMA = {
    'obstacle': ['sfx_obs_dog_growl.wav', 'sfx_obs_dog_bark_01.wav', 'sfx_obs_car_beep.wav', 'sfx_obs_car_engine.wav', 'sfx_obs_crash_01.wav'],
    'bell': ['sfx_bike_bell_01.wav', 'sfx_bike_bell_02.wav', 'sfx_bike_bell_03.wav'],
    'ui': ['sfx_ui_tip_01.wav', 'sfx_ui_tepat_01.wav'],
}


def semua_nama():
    """Ke-10 nama (subfolder/nama), urut tulis."""
    return ['%s/%s' % (k, n) for k in ('obstacle', 'bell', 'ui') for n in NAMA[k]]


def _jumlah(detik):
    return int(round(detik * LAJU_SAMPEL))


def _amplop(n, serang_detik, lepas_detik, mulai=0):
    """Amplop sekali putar mulai sampel `mulai` (sebelumnya nol): naik setengah kosinus dari nol, rata, turun sampai tepat nol di akhir."""
    serang = max(1, int(serang_detik * LAJU_SAMPEL))
    lepas = max(2, int(lepas_detik * LAJU_SAMPEL))
    hasil = []
    for i in range(n):
        j = i - mulai
        if j < 0:
            a = 0.0
        elif j < serang:
            a = 0.5 * (1.0 - math.cos(math.pi * j / serang))
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


def geram(acak):
    detik, dasar, getar = GERAM
    n = _jumlah(detik)
    desis = _pita(_derau(acak, n), 400.0, 300.0)
    puncak_desis = max(abs(v) for v in desis) or 1.0
    hasil = []
    fase = 0.0
    for i in range(n):
        t = i / LAJU_SAMPEL
        frekuensi = dasar * (1.0 + 0.06 * math.sin(2.0 * math.pi * 3.0 * t))
        fase += 2.0 * math.pi * frekuensi / LAJU_SAMPEL
        # Gelombang kaya harmonik (jumlah tiga harmonik) dengan getar amplitudo cepat: "grrr".
        nada = math.sin(fase) + 0.6 * math.sin(2.0 * fase) + 0.4 * math.sin(3.0 * fase)
        am = 0.55 + 0.45 * math.sin(2.0 * math.pi * getar * t)
        hasil.append(nada * am + GERAM_DESIS_KUAT * desis[i] / puncak_desis)
    return _selesai(hasil, _amplop(n, 0.06, 0.12), PUNCAK)


def gonggong(acak):
    n = _jumlah(GONGGONG_DETIK)
    hasil = [0.0] * n
    for mulai, panjang, awal_hz, akhir_hz in GONGGONG_GUK:
        m = _jumlah(mulai)
        k = _jumlah(panjang)
        fase = 0.0
        derau = _pita(_derau(acak, k), GONGGONG_FORMAN_HZ, 700.0)
        puncak_derau = max(abs(v) for v in derau) or 1.0
        amplop = _amplop(k, 0.008, 0.06)
        for i in range(k):
            if m + i >= n:
                break
            t = i / k
            frekuensi = awal_hz + (akhir_hz - awal_hz) * t
            fase += 2.0 * math.pi * frekuensi / LAJU_SAMPEL
            # Gelombang gergaji lembut (lima harmonik) + semburan derau di forman: "guk".
            gergaji = sum(math.sin(h * fase) / h for h in range(1, 6))
            hasil[m + i] += (gergaji + 0.5 * derau[i] / puncak_derau) * amplop[i]
    return _selesai(hasil, _amplop(n, SERANG_DETIK, LEPAS_DETIK), PUNCAK)


def bip(acak):
    n = _jumlah(BIP_DETIK)
    hasil = [0.0] * n
    nyala = _jumlah(BIP_NYALA_DETIK)
    periode = _jumlah(BIP_PERIODE_DETIK)
    amplop = _amplop(nyala, 0.006, 0.02)
    for awal in range(0, n, periode):
        for i in range(nyala):
            if awal + i < n:
                t = (awal + i) / LAJU_SAMPEL
                hasil[awal + i] = (math.sin(2.0 * math.pi * BIP_HZ * t) + 0.25 * math.sin(2.0 * math.pi * BIP_HZ * 3.0 * t)) * amplop[i]
    acak.random()
    return _selesai(hasil, _amplop(n, SERANG_DETIK, LEPAS_DETIK), PUNCAK)


def mesin(acak):
    detik, dasar, denyut = MESIN
    n = _jumlah(detik)
    gemuruh = _pita(_derau(acak, n), 180.0, 160.0)
    puncak_gemuruh = max(abs(v) for v in gemuruh) or 1.0
    hasil = []
    fase = 0.0
    for i in range(n):
        t = i / LAJU_SAMPEL
        fase += 2.0 * math.pi * dasar / LAJU_SAMPEL
        nada = math.sin(fase) + 0.5 * math.sin(2.0 * fase) + 0.3 * math.sin(4.0 * fase)
        am = 0.6 + 0.4 * (0.5 + 0.5 * math.sin(2.0 * math.pi * denyut * t))
        hasil.append(nada * am + 0.6 * gemuruh[i] / puncak_gemuruh)
    return _selesai(hasil, _amplop(n, 0.08, 0.15), PUNCAK)


def tabrak(acak):
    n = _jumlah(TABRAK_DETIK)
    hasil = []
    derau = _pita(_derau(acak, n), 220.0, 260.0)
    puncak_derau = max(abs(v) for v in derau) or 1.0
    for i in range(n):
        t = i / LAJU_SAMPEL
        dentum = math.sin(2.0 * math.pi * TABRAK_DENTUM_HZ * t * (1.0 - 0.3 * t)) * math.exp(-t / TABRAK_DENTUM_LURUH_DETIK)
        hasil.append(dentum + 0.5 * derau[i] / puncak_derau * math.exp(-t / (TABRAK_DENTUM_LURUH_DETIK * 0.7)))
    for mulai, nada in TABRAK_KERINCING:
        m = _jumlah(mulai)
        for i in range(n - m):
            t = i / LAJU_SAMPEL
            hasil[m + i] += TABRAK_KERINCING_KUAT * (math.sin(2.0 * math.pi * nada * t) + 0.5 * math.sin(2.0 * math.pi * nada * 1.41 * t)) * math.exp(-t / TABRAK_KERINCING_LURUH_DETIK)
    return _selesai(hasil, _amplop(n, SERANG_DETIK, 0.08), PUNCAK_LEMBUT)


def bel(acak, variasi):
    detik, dasar = BEL_VARIASI[variasi]
    n = _jumlah(detik)
    fase_getar = acak.random() * 2.0 * math.pi
    hasil = []
    for i in range(n):
        t = i / LAJU_SAMPEL
        nilai = 0.0
        for kelipatan, kuat, pengali_luruh in BEL_PARSIAL:
            nilai += kuat * math.sin(2.0 * math.pi * dasar * kelipatan * t) * math.exp(-t / (BEL_LURUH_DETIK * pengali_luruh))
        # Pemukul bel bergetar cepat: "rrring".
        getar = 1.0 - BEL_GETAR_DALAM * (0.5 + 0.5 * math.sin(2.0 * math.pi * BEL_GETAR_HZ * t + fase_getar))
        hasil.append(nilai * getar)
    return _selesai(hasil, _amplop(n, 0.002, 0.05), PUNCAK)


def tip(acak):
    senyap, panjang, nada = TIP
    mulai = _jumlah(senyap)
    n = mulai + _jumlah(panjang)
    hasil = [0.0] * n
    for i in range(n - mulai):
        t = i / LAJU_SAMPEL
        hasil[mulai + i] = (math.sin(2.0 * math.pi * nada * t) + 0.4 * math.sin(2.0 * math.pi * nada * 2.76 * t)) * math.exp(-t / TIP_LURUH_DETIK)
    acak.random()
    return _selesai(hasil, _amplop(n, 0.002, LEPAS_DETIK, mulai), PUNCAK)


def tepat(acak):
    senyap, panjang, nada_1, nada_2 = TEPAT
    mulai = _jumlah(senyap)
    n = mulai + _jumlah(panjang)
    hasil = [0.0] * n
    kedua = _jumlah(panjang * 0.4)
    for i in range(n - mulai):
        t = i / LAJU_SAMPEL
        nilai = math.sin(2.0 * math.pi * nada_1 * t) * math.exp(-t / TEPAT_LURUH_DETIK)
        if i >= kedua:
            t2 = (i - kedua) / LAJU_SAMPEL
            nilai += math.sin(2.0 * math.pi * nada_2 * t2) * math.exp(-t2 / TEPAT_LURUH_DETIK) * min(1.0, t2 / 0.002)
        hasil[mulai + i] = nilai
    acak.random()
    return _selesai(hasil, _amplop(n, 0.002, LEPAS_DETIK, mulai), PUNCAK)


def tulis_wav(jalur, sampel):
    with wave.open(jalur, 'wb') as berkas:
        berkas.setnchannels(1)
        berkas.setsampwidth(LEBAR_SAMPEL)
        berkas.setframerate(LAJU_SAMPEL)
        berkas.writeframes(struct.pack('<%dh' % len(sampel), *sampel))


def bangun(folder):
    """Membuat ke-10 WAV ke subfolder `obstacle`, `bell`, `ui` di `folder`. Mengembalikan daftar (subfolder/nama, jumlah sampel)."""
    acak = random.Random(BENIH)
    pembuat = [
        ('obstacle/sfx_obs_dog_growl.wav', geram),
        ('obstacle/sfx_obs_dog_bark_01.wav', gonggong),
        ('obstacle/sfx_obs_car_beep.wav', bip),
        ('obstacle/sfx_obs_car_engine.wav', mesin),
        ('obstacle/sfx_obs_crash_01.wav', tabrak),
        ('bell/sfx_bike_bell_01.wav', lambda a: bel(a, 0)),
        ('bell/sfx_bike_bell_02.wav', lambda a: bel(a, 1)),
        ('bell/sfx_bike_bell_03.wav', lambda a: bel(a, 2)),
        ('ui/sfx_ui_tip_01.wav', tip),
        ('ui/sfx_ui_tepat_01.wav', tepat),
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
    pengurai = argparse.ArgumentParser(description='Sintesis bunyi placeholder rute run 3B (rintangan, tabrakan, bel, tip, tepat).')
    pengurai.add_argument('--out', default=KELUARAN_BAWAAN, help='folder induk keluaran (bawaan: assets/audio/sfx)')
    argumen = pengurai.parse_args()
    for nama, jumlah in bangun(argumen.out):
        print('%s: %d sampel, %.3f detik' % (os.path.join(argumen.out, nama), jumlah, jumlah / LAJU_SAMPEL))
    return 0


if __name__ == '__main__':
    sys.exit(main())
