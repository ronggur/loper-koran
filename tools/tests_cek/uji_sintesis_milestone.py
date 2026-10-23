#!/usr/bin/env python3
"""Uji `tools/audio_art/sintesis_milestone.py` (bunyi placeholder milestone tercapai run 6A2 bagian C, AC-15). Hanya pustaka standar.

Membuktikan: (1) WAV di `assets/audio/sfx/milestone/` sama persis dengan keluaran skrip (tidak diedit tangan, bukan rekaman atau unduhan), (2) skrip deterministik (dua kali
jalan = byte sama), (3) mono 16-bit 22050 Hz dan durasi 0,5..0,8 detik, (4) tanpa klik: sampel pertama dan terakhir tepat nol dan tepi dekat nol, (5) lembut: puncak paling
sedikit 3 dB di bawah bunyi misi selesai (tidak mengganggu, tidak menghukum), tetapi tidak senyap, (6) arah nada naik (laju lintas nol akhir > awal), (7) skrip hanya mengimpor
pustaka standar, (8) `.import` sekali putar dan PCM, `assets/audio/LICENSES.md` mencatat berkas dan skrip, (9) pemeriksaan menolak contoh buruk.

Cara pakai (dari root repo):
    python3 tools/tests_cek/uji_sintesis_milestone.py
Exit code: 0 bila semua lolos, 1 bila ada yang gagal.
"""
import ast
import math
import os
import struct
import subprocess
import sys
import tempfile
import wave

FOLDER = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(FOLDER, '..', '..'))
SKRIP = os.path.join(ROOT, 'tools', 'audio_art', 'sintesis_milestone.py')
SFX = os.path.join(ROOT, 'assets', 'audio', 'sfx')
LISENSI = os.path.join(ROOT, 'assets', 'audio', 'LICENSES.md')
NAMA = 'milestone/sfx_milestone_tercapai_01.wav'
PEMBANDING = 'mission/sfx_mis_selesai_01.wav'
LAJU = 22050
BATAS_TEPI = 655

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


def sampel_wav(jalur):
    with wave.open(jalur, 'rb') as w:
        kanal, lebar, laju, n = w.getnchannels(), w.getsampwidth(), w.getframerate(), w.getnframes()
        data = w.readframes(n)
    return kanal, lebar, laju, list(struct.unpack('<%dh' % n, data)) if lebar == 2 else []


def masalah_tepi(sampel):
    if len(sampel) < 6:
        return ['terlalu pendek']
    masalah = []
    if sampel[0] != 0 or sampel[-1] != 0:
        masalah.append('ujung tidak tepat nol (%d, %d)' % (sampel[0], sampel[-1]))
    if max(abs(s) for s in sampel[:3] + sampel[-3:]) > BATAS_TEPI:
        masalah.append('sampel tepi jauh dari nol')
    return masalah


def lintas_nol(sampel):
    if len(sampel) < 2:
        return 0.0
    n = sum(1 for i in range(1, len(sampel)) if (sampel[i - 1] < 0) != (sampel[i] < 0))
    return n / (len(sampel) / LAJU)


def impor_stdlib(jalur):
    with open(jalur, encoding='utf-8') as f:
        pohon = ast.parse(f.read())
    nama = set()
    for s in ast.walk(pohon):
        if isinstance(s, ast.Import):
            nama.update(a.name.split('.')[0] for a in s.names)
        elif isinstance(s, ast.ImportFrom) and s.module:
            nama.add(s.module.split('.')[0])
    return sorted(n for n in nama if n not in sys.stdlib_module_names)


def main():
    periksa(not impor_stdlib(SKRIP), 'sintesis_milestone.py hanya mengimpor pustaka standar: %s' % impor_stdlib(SKRIP))
    with tempfile.TemporaryDirectory() as sementara:
        a, b = os.path.join(sementara, 'a'), os.path.join(sementara, 'b')
        kode = [subprocess.run([sys.executable, '-I', SKRIP, '--out', d], capture_output=True, text=True).returncode for d in (a, b)]
        periksa(kode == [0, 0], 'skrip berhasil ditulis dua kali')
        ja, jb, jr = os.path.join(a, NAMA), os.path.join(b, NAMA), os.path.join(SFX, NAMA)
        periksa(os.path.isfile(ja) and baca(ja) == baca(jb), 'dua kali jalan menghasilkan byte yang sama (deterministik)')
        periksa(os.path.isfile(jr) and baca(jr) == baca(ja), 'berkas di repo byte-identik dengan keluaran skrip (tidak diedit tangan)')
        daftar = sorted(os.listdir(os.path.join(SFX, 'milestone')))
        periksa([n for n in daftar if n.endswith('.wav')] == [os.path.basename(NAMA)], 'assets/audio/sfx/milestone/ berisi tepat 1 WAV: %s' % daftar)
        if os.path.isfile(jr):
            kanal, lebar, laju, s = sampel_wav(jr)
            periksa(kanal == 1 and lebar == 2 and laju == LAJU, 'mono 16-bit 22050 Hz')
            durasi = len(s) / LAJU
            periksa(0.5 <= durasi <= 0.8, 'durasi %.3f detik (0,5..0,8)' % durasi)
            puncak = max(abs(x) for x in s)
            periksa(puncak > 8192, 'tidak senyap (puncak %d)' % puncak)
            periksa(not masalah_tepi(s), 'tanpa klik di awal dan akhir: %s' % masalah_tepi(s))
            pembanding = sampel_wav(os.path.join(SFX, PEMBANDING))[3]
            rasio_db = 20 * math.log10(puncak / max(abs(x) for x in pembanding))
            periksa(rasio_db <= -3.0, 'lebih lembut dari bunyi misi selesai (%.1f dB, harus <= -3)' % rasio_db)
            periksa(lintas_nol(s[int(len(s) * 0.5):int(len(s) * 0.8)]) > lintas_nol(s[:int(len(s) * 0.2)]) * 1.2, 'nada naik: laju lintas nol bagian akhir > awal')
            impor = open(jr + '.import', encoding='utf-8').read() if os.path.isfile(jr + '.import') else ''
            periksa('edit/loop_mode=1\n' in impor and 'compress/mode=0\n' in impor and 'importer="wav"' in impor and 'uid="uid://' in impor, '.import: hasil Godot (uid), edit/loop_mode=1 (sekali putar), compress/mode=0 (PCM)')
            periksa(os.path.getsize(jr) < 100 * 1024, 'ukuran di bawah 100 KB')
        lisensi = open(LISENSI, encoding='utf-8').read() if os.path.isfile(LISENSI) else ''
        periksa('sfx_milestone_tercapai_01.wav' in lisensi and 'sintesis_milestone.py' in lisensi, 'assets/audio/LICENSES.md mencatat WAV dan skrip pembuatnya')
        data = bytearray(baca(ja))
        data[-40] ^= 0x01
        periksa(bytes(data) != baca(jr), 'kontrol: berkas yang diubah satu byte terdeteksi berbeda')
        periksa(masalah_tepi([0, 100, -200, 3000, 50, 9000]) != [], 'kontrol: bunyi yang berakhir jauh dari nol ditolak (klik)')
        periksa(masalah_tepi([0, 40, -90, 3000, -2000, 50, 30, 0]) == [], 'kontrol: bunyi landai di kedua ujung diterima')
        buruk = os.path.join(sementara, 'buruk.py')
        with open(buruk, 'w', encoding='utf-8') as f:
            f.write('import wave\nimport numpy as np\n')
        periksa(impor_stdlib(buruk) == ['numpy'], 'kontrol: skrip yang mengimpor numpy ditolak')
    print('%d lolos, %d gagal' % (lolos, gagal))
    return 1 if gagal else 0


if __name__ == '__main__':
    sys.exit(main())
