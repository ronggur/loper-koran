#!/usr/bin/env python3
"""Sintesis bunyi placeholder milestone tercapai run 6A2 bagian C (SOUND_DESIGN 3.1, 4; AC-15 run fase6a2-reputasi-pelanggan, usulan). Hanya pustaka standar.

Menulis 1 WAV mono 16-bit 22050 Hz (laju sama dengan bunyi lain), dibuat sendiri dari rumus (tanpa rekaman, tanpa unduhan):
  milestone/sfx_milestone_tercapai_01.wav   denting lembut dua nada naik (mi lalu si, selang kelima) dengan parsial lonceng, 0,65 detik, sekitar 4 dB lebih pelan dari bunyi misi
                                            selesai (pasangan visual: lencana dan baris "Baru" di layar hasil; tidak pernah satu-satunya pembawa informasi).

Keluaran deterministik (tanpa acak). Sekali putar: sampel pertama dan terakhir tepat nol (tanpa klik). Keras-pelan saat main diatur di Godot lewat `Config.AUDIO_MILESTONE_VOLUME_DB`.

Cara pakai (dari root repo):
    python3 tools/audio_art/sintesis_milestone.py                 # tulis ke assets/audio/sfx/milestone/
    python3 tools/audio_art/sintesis_milestone.py --out build/x   # tulis ke folder lain (subfolder milestone), untuk uji
"""
import argparse
import math
import os
import struct
import sys
import wave

LAJU_SAMPEL = 22050
LEBAR_SAMPEL = 2
PUNCAK = 0.56
FOLDER = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(FOLDER, '..', '..'))
KELUARAN_BAWAAN = os.path.join(ROOT, 'assets', 'audio', 'sfx')
DETIK = 0.65
NADA = (659.25, 987.77)
LANGKAH_DETIK = 0.17
LURUH_DETIK = (0.16, 0.28)
NAMA = ['milestone/sfx_milestone_tercapai_01.wav']


def semua_nama():
    """Nama (subfolder/nama) yang ditulis."""
    return list(NAMA)


def _jumlah(detik):
    return int(round(detik * LAJU_SAMPEL))


def _amplop(n, serang_detik, lepas_detik):
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


def tercapai():
    n = _jumlah(DETIK)
    hasil = [0.0] * n
    langkah = _jumlah(LANGKAH_DETIK)
    for k, nada in enumerate(NADA):
        mulai = k * langkah
        for i in range(max(n - mulai, 0)):
            t = i / LAJU_SAMPEL
            naik = min(1.0, t / 0.004)
            # Parsial lonceng sedikit tak harmonis (2,0 dan 2,76) meluruh lebih cepat dari dasar.
            nilai = (math.sin(2.0 * math.pi * nada * t)
                     + 0.35 * math.sin(2.0 * math.pi * nada * 2.0 * t) * math.exp(-t / 0.08)
                     + 0.18 * math.sin(2.0 * math.pi * nada * 2.76 * t) * math.exp(-t / 0.05))
            hasil[mulai + i] += nilai * math.exp(-t / LURUH_DETIK[k]) * naik
    amplop = _amplop(n, 0.002, 0.1)
    sampel = [s * a for s, a in zip(hasil, amplop)]
    puncak = max(abs(s) for s in sampel)
    skala = PUNCAK / puncak if puncak > 0.0 else 0.0
    batas = 32767
    return [max(-batas, min(batas, int(round(s * skala * batas)))) for s in sampel]


def tulis_wav(jalur, sampel):
    with wave.open(jalur, 'wb') as berkas:
        berkas.setnchannels(1)
        berkas.setsampwidth(LEBAR_SAMPEL)
        berkas.setframerate(LAJU_SAMPEL)
        berkas.writeframes(struct.pack('<%dh' % len(sampel), *sampel))


def bangun(folder):
    """Membuat WAV ke subfolder `milestone` di `folder`. Mengembalikan daftar (subfolder/nama, jumlah sampel)."""
    hasil = []
    for nama, fungsi in (('milestone/sfx_milestone_tercapai_01.wav', tercapai),):
        jalur = os.path.join(folder, nama)
        os.makedirs(os.path.dirname(jalur), exist_ok=True)
        sampel = fungsi()
        tulis_wav(jalur, sampel)
        hasil.append((nama, len(sampel)))
    return hasil


def main():
    pengurai = argparse.ArgumentParser(description='Sintesis bunyi placeholder milestone tercapai run 6A2.')
    pengurai.add_argument('--out', default=KELUARAN_BAWAAN, help='folder induk keluaran (bawaan: assets/audio/sfx)')
    argumen = pengurai.parse_args()
    for nama, jumlah in bangun(argumen.out):
        print('%s: %d sampel, %.3f detik' % (os.path.join(argumen.out, nama), jumlah, jumlah / LAJU_SAMPEL))
    return 0


if __name__ == '__main__':
    sys.exit(main())
