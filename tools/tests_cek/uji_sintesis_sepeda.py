#!/usr/bin/env python3
"""Uji `tools/audio_art/sintesis_sepeda.py` (bunyi placeholder sepeda, D-4 run fase1b-umpan-balik). Hanya pustaka standar.

Membuktikan: (1) tiga WAV di `assets/audio/sfx/bike/` sama persis dengan keluaran skrip (tidak diedit tangan, tidak diganti
rekaman), (2) skrip deterministik (dua kali jalan = byte sama), (3) format WAV mono 16-bit 22050 Hz dengan durasi sesuai
(loop 1,0 detik, rem 0,3-0,6 detik), (4) kedua loop tanpa klik di sambungan (sampel awal dan akhir dekat nol, lompatan di
sambungan kecil) dan bunyi rem mulai dan berakhir di nol, (5) skrip hanya mengimpor pustaka standar, (6) total di bawah
500 KB, nama berkas sesuai SOUND_DESIGN 6, `.import` loop benar, dan `assets/audio/LICENSES.md` mencatat ketiganya,
(7) pemeriksaan menolak contoh buruk (berkas diubah satu byte, loop berklik).

Cara pakai (dari root repo):
    python3 tools/tests_cek/uji_sintesis_sepeda.py

Exit code: 0 bila semua pemeriksaan lolos, 1 bila ada yang gagal.
"""
import ast
import os
import struct
import subprocess
import sys
import tempfile
import wave

FOLDER = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(FOLDER, '..', '..'))
SKRIP = os.path.join(ROOT, 'tools', 'audio_art', 'sintesis_sepeda.py')
HASIL_REPO = os.path.join(ROOT, 'assets', 'audio', 'sfx', 'bike')
LISENSI = os.path.join(ROOT, 'assets', 'audio', 'LICENSES.md')
LAJU_SAMPEL = 22050
# nama: (loop, durasi minimum detik, durasi maksimum detik, edit/loop_mode di .import)
BERKAS = {
    'sfx_bike_pedal_loop.wav': (True, 1.0, 1.0, 2),
    'sfx_bike_freewheel_loop.wav': (True, 1.0, 1.0, 2),
    'sfx_bike_brake_01.wav': (False, 0.3, 0.6, 1),
}
BATAS_TOTAL_BYTE = 500 * 1024
# Sampel "dekat nol" di ujung: 1% skala penuh.
BATAS_UJUNG = 328

gagal = 0
lolos = 0


def periksa(kondisi, label):
    global gagal, lolos
    if kondisi:
        lolos += 1
    else:
        gagal += 1
        print('GAGAL:', label)


def jalankan(*argumen):
    hasil = subprocess.run([sys.executable, '-I', SKRIP, *argumen], capture_output=True, text=True)
    return hasil.returncode, hasil.stdout + hasil.stderr


def baca(jalur):
    with open(jalur, 'rb') as f:
        return f.read()


def sampel_wav(jalur):
    """(kanal, lebar sampel, laju, daftar sampel int16)."""
    with wave.open(jalur, 'rb') as w:
        kanal, lebar, laju, jumlah = w.getnchannels(), w.getsampwidth(), w.getframerate(), w.getnframes()
        data = w.readframes(jumlah)
    if lebar != 2:
        return kanal, lebar, laju, []
    return kanal, lebar, laju, list(struct.unpack('<%dh' % (len(data) // 2), data))


def masalah_loop(sampel):
    """Daftar masalah sambungan loop: ujung tidak dekat nol, atau lompatan di sambungan jauh di atas lompatan biasa."""
    masalah = []
    if not sampel:
        return ['tanpa sampel']
    if abs(sampel[0]) > BATAS_UJUNG or abs(sampel[-1]) > BATAS_UJUNG:
        masalah.append('ujung tidak dekat nol (%d, %d)' % (sampel[0], sampel[-1]))
    lompat = abs(sampel[0] - sampel[-1])
    if lompat > 2 * BATAS_UJUNG:
        masalah.append('lompatan di sambungan %d' % lompat)
    return masalah


def impor_stdlib(jalur):
    """Modul yang diimpor skrip dan bukan pustaka standar."""
    with open(jalur, encoding='utf-8') as f:
        pohon = ast.parse(f.read())
    nama = set()
    for simpul in ast.walk(pohon):
        if isinstance(simpul, ast.Import):
            nama.update(a.name.split('.')[0] for a in simpul.names)
        elif isinstance(simpul, ast.ImportFrom) and simpul.module:
            nama.add(simpul.module.split('.')[0])
    return sorted(n for n in nama if n not in sys.stdlib_module_names), sorted(nama)


def main():
    # (5) Hanya pustaka standar.
    bukan_stdlib, semua = impor_stdlib(SKRIP)
    periksa(not bukan_stdlib and semua, f'sintesis_sepeda.py hanya mengimpor pustaka standar ({", ".join(semua)}); bukan stdlib: {bukan_stdlib}')

    with tempfile.TemporaryDirectory() as sementara:
        # (2) Deterministik.
        a, b = os.path.join(sementara, 'a'), os.path.join(sementara, 'b')
        kode_a, keluaran_a = jalankan('--out', a)
        kode_b, _ = jalankan('--out', b)
        periksa(kode_a == 0 and kode_b == 0, f'skrip berhasil ditulis dua kali ke folder berbeda ({keluaran_a.strip()[:200]})')
        daftar = sorted(os.listdir(a)) if os.path.isdir(a) else []
        periksa(daftar == sorted(BERKAS) and daftar == sorted(os.listdir(b)), f'skrip menulis tepat tiga berkas bernama sesuai SOUND_DESIGN 6, dapat {daftar}')
        periksa(all(baca(os.path.join(a, n)) == baca(os.path.join(b, n)) for n in daftar), 'dua kali jalan menghasilkan byte yang sama')

        # (1) Berkas di repo = keluaran skrip.
        total = 0
        for nama in sorted(BERKAS):
            jalur_repo = os.path.join(HASIL_REPO, nama)
            ada = os.path.isfile(jalur_repo)
            periksa(ada, f'{nama} ada di assets/audio/sfx/bike/')
            if not ada or nama not in daftar:
                continue
            total += os.path.getsize(jalur_repo)
            periksa(baca(jalur_repo) == baca(os.path.join(a, nama)), f'{nama}: berkas di repo byte-identik dengan keluaran skrip')

            # (3) Format dan durasi.
            loop, durasi_min, durasi_maks, mode_impor = BERKAS[nama]
            kanal, lebar, laju, sampel = sampel_wav(jalur_repo)
            periksa(kanal == 1 and lebar == 2 and laju == LAJU_SAMPEL, f'{nama}: mono 16-bit {LAJU_SAMPEL} Hz (dapat {kanal} kanal, {lebar * 8} bit, {laju} Hz)')
            durasi = len(sampel) / LAJU_SAMPEL
            periksa(durasi_min - 1e-9 <= durasi <= durasi_maks + 1e-9, f'{nama}: durasi {durasi:.3f} detik ({durasi_min}..{durasi_maks})')
            periksa(max((abs(s) for s in sampel), default=0) > 16384, f'{nama}: tidak senyap (puncak di atas setengah skala)')

            # (4) Tanpa klik.
            if loop:
                periksa(not masalah_loop(sampel), f'{nama}: sambungan loop tanpa klik: {masalah_loop(sampel)}')
            else:
                periksa(sampel and sampel[0] == 0 and sampel[-1] == 0, f'{nama}: mulai dan berakhir tepat di nol (tanpa klik)')

            # (6) Setelan impor.
            jalur_impor = jalur_repo + '.import'
            impor = open(jalur_impor, encoding='utf-8').read() if os.path.isfile(jalur_impor) else ''
            periksa(f'edit/loop_mode={mode_impor}\n' in impor and 'compress/mode=0\n' in impor and 'importer="wav"' in impor,
                    f'{nama}.import: edit/loop_mode={mode_impor} ({"Forward" if loop else "Disabled"}), compress/mode=0 (PCM)')
        periksa(0 < total < BATAS_TOTAL_BYTE, f'total ketiga WAV {total} byte, di bawah 500 KB')

        lisensi = open(LISENSI, encoding='utf-8').read() if os.path.isfile(LISENSI) else ''
        periksa(all(n in lisensi for n in BERKAS) and 'sintesis_sepeda.py' in lisensi, 'assets/audio/LICENSES.md mencatat ketiga WAV dan skrip pembuatnya')

        # (7) Contoh buruk ditolak.
        jalur_ubah = os.path.join(sementara, 'ubah.wav')
        data = bytearray(baca(os.path.join(a, 'sfx_bike_pedal_loop.wav')))
        data[-2] ^= 0x01
        with open(jalur_ubah, 'wb') as f:
            f.write(data)
        periksa(baca(jalur_ubah) != baca(os.path.join(HASIL_REPO, 'sfx_bike_pedal_loop.wav')), 'kontrol: berkas yang diubah satu byte terdeteksi berbeda')
        periksa(masalah_loop([0, 100, -200, 9000]) != [], 'kontrol: loop yang berakhir jauh dari nol ditolak (klik)')
        periksa(masalah_loop([5000, 100, -200, 0]) != [], 'kontrol: loop yang mulai jauh dari nol ditolak (klik)')
        periksa(masalah_loop([0, 3000, -3000, 0]) == [], 'kontrol: loop yang mulai dan berakhir di nol diterima')
        jalur_skrip_buruk = os.path.join(sementara, 'buruk.py')
        with open(jalur_skrip_buruk, 'w', encoding='utf-8') as f:
            f.write('import wave\nimport numpy as np\nfrom PIL import Image\n')
        periksa(impor_stdlib(jalur_skrip_buruk)[0] == ['PIL', 'numpy'], 'kontrol: skrip yang mengimpor numpy dan PIL ditolak')

    print(f'{lolos} lolos, {gagal} gagal')
    return 1 if gagal else 0


if __name__ == '__main__':
    sys.exit(main())
