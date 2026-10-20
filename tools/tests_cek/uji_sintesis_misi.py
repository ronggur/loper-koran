#!/usr/bin/env python3
"""Uji `tools/audio_art/sintesis_misi.py` (bunyi placeholder misi kucing run 4B: petunjuk/meong, kucing terlihat, misi selesai, misi gagal; AC-15
run fase4b-misi-kucing). Hanya pustaka standar.

Membuktikan: (1) 4 WAV di `assets/audio/sfx/mission/` sama persis dengan keluaran skrip (tidak diedit tangan, tidak diganti rekaman atau unduhan),
(2) skrip deterministik (dua kali jalan = byte sama), (3) format WAV mono 16-bit 22050 Hz dan durasi tiap berkas di rentangnya, (4) bunyi gagal
lebih pelan dari bunyi lain (SOUND_DESIGN 2: gagal berbunyi lembut), (5) tanpa klik: sampel pertama dan terakhir tepat nol dan sampel tepi dekat
nol, (6) arah nada: terlihat dan selesai naik, gagal turun, meong naik lalu turun, (7) keempat bunyi berbeda nyata (byte dan panjang),
(8) skrip hanya mengimpor pustaka standar, (9) `.import` sekali putar dan PCM, `assets/audio/LICENSES.md` mencatat keempat berkas, total jauh di
bawah anggaran, (10) pemeriksaan menolak contoh buruk.

Cara pakai (dari root repo):
    python3 tools/tests_cek/uji_sintesis_misi.py

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
SKRIP = os.path.join(ROOT, 'tools', 'audio_art', 'sintesis_misi.py')
HASIL_REPO = os.path.join(ROOT, 'assets', 'audio', 'sfx')
LISENSI = os.path.join(ROOT, 'assets', 'audio', 'LICENSES.md')
LAJU_SAMPEL = 22050
# Ke-4 nama ditulis eksplisit (SOUND_DESIGN 6), bukan dibaca dari skrip, dengan rentang durasi (detik, inklusif).
RENTANG = {
    'mission/sfx_mis_meong_01.wav': (0.4, 0.7),
    'mission/sfx_mis_terlihat_01.wav': (0.2, 0.4),
    'mission/sfx_mis_selesai_01.wav': (0.5, 0.9),
    'mission/sfx_mis_gagal_01.wav': (0.3, 0.7),
}
NAMA = sorted(RENTANG)
BATAS_TOTAL_BYTE = 200 * 1024
BATAS_TEPI = 655
TEPI_SAMPEL = 3
BEDA_LINTAS_NOL = 0.05

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
    with wave.open(jalur, 'rb') as w:
        kanal, lebar, laju, jumlah = w.getnchannels(), w.getsampwidth(), w.getframerate(), w.getnframes()
        data = w.readframes(jumlah)
    if lebar != 2:
        return kanal, lebar, laju, []
    return kanal, lebar, laju, list(struct.unpack('<%dh' % (len(data) // 2), data))


def masalah_tepi(sampel):
    if len(sampel) < 2 * TEPI_SAMPEL:
        return ['terlalu pendek']
    masalah = []
    if sampel[0] != 0 or sampel[-1] != 0:
        masalah.append('ujung tidak tepat nol (%d, %d)' % (sampel[0], sampel[-1]))
    tepi = sampel[:TEPI_SAMPEL] + sampel[-TEPI_SAMPEL:]
    if max(abs(s) for s in tepi) > BATAS_TEPI:
        masalah.append('sampel tepi jauh dari nol %s' % tepi)
    return masalah


def lintas_nol_per_detik(sampel):
    if len(sampel) < 2:
        return 0.0
    jumlah = sum(1 for i in range(1, len(sampel)) if (sampel[i - 1] < 0) != (sampel[i] < 0))
    return jumlah / (len(sampel) / LAJU_SAMPEL)


def masalah_variasi(tiga):
    masalah = []
    for i in range(len(tiga)):
        for j in range(i + 1, len(tiga)):
            (bi, si), (bj, sj) = tiga[i], tiga[j]
            if bi == bj:
                masalah.append('%d=%d byte sama' % (i + 1, j + 1))
                continue
            if len(si) == len(sj):
                masalah.append('%d,%d panjang sama' % (i + 1, j + 1))
            zi, zj = lintas_nol_per_detik(si), lintas_nol_per_detik(sj)
            if abs(zi - zj) < BEDA_LINTAS_NOL * max(zi, zj, 1.0):
                masalah.append('%d,%d lintas nol mirip (%.0f, %.0f)' % (i + 1, j + 1, zi, zj))
    return masalah


def senyap_awal_detik(sampel):
    """Lama senyap (sampel tepat nol) di awal, detik."""
    i = 0
    while i < len(sampel) and sampel[i] == 0:
        i += 1
    return i / LAJU_SAMPEL


def jumlah_semburan(sampel, ambang=2000, jeda_min=1000):
    """Jumlah semburan bunyi (bagian di atas ambang) yang dipisah senyap paling sedikit `jeda_min` sampel."""
    semburan = 0
    sunyi = jeda_min
    for s in sampel:
        if abs(s) > ambang:
            if sunyi >= jeda_min:
                semburan += 1
            sunyi = 0
        else:
            sunyi += 1
    return semburan


def impor_stdlib(jalur):
    with open(jalur, encoding='utf-8') as f:
        pohon = ast.parse(f.read())
    nama = set()
    for simpul in ast.walk(pohon):
        if isinstance(simpul, ast.Import):
            nama.update(a.name.split('.')[0] for a in simpul.names)
        elif isinstance(simpul, ast.ImportFrom) and simpul.module:
            nama.add(simpul.module.split('.')[0])
    return sorted(n for n in nama if n not in sys.stdlib_module_names), sorted(nama)


def daftar_wav(folder):
    hasil = []
    for sub in ('mission',):
        jalur = os.path.join(folder, sub)
        if os.path.isdir(jalur):
            hasil.extend('%s/%s' % (sub, n) for n in os.listdir(jalur) if n.endswith('.wav'))
    return sorted(hasil)


def paruh_lintas_nol(sampel, awal, akhir):
    """Laju lintas nol (per detik) pada bagian `awal`..`akhir` (pecahan 0..1) dari sampel."""
    n = len(sampel)
    bagian = sampel[int(n * awal):int(n * akhir)]
    return lintas_nol_per_detik(bagian)


def main():
    bukan_stdlib, semua = impor_stdlib(SKRIP)
    periksa(not bukan_stdlib and semua, f'sintesis_misi.py hanya mengimpor pustaka standar ({", ".join(semua)}); bukan stdlib: {bukan_stdlib}')

    with tempfile.TemporaryDirectory() as sementara:
        a, b = os.path.join(sementara, 'a'), os.path.join(sementara, 'b')
        kode_a, keluaran_a = jalankan('--out', a)
        kode_b, _ = jalankan('--out', b)
        periksa(kode_a == 0 and kode_b == 0, f'skrip berhasil ditulis dua kali ke folder berbeda ({keluaran_a.strip()[:200]})')
        daftar = daftar_wav(a)
        periksa(daftar == NAMA and daftar == daftar_wav(b), f'skrip menulis tepat 4 berkas bernama sesuai rencana, dapat {daftar}')
        periksa(daftar and all(baca(os.path.join(a, n)) == baca(os.path.join(b, n)) for n in daftar), 'dua kali jalan menghasilkan byte yang sama (deterministik)')
        periksa(daftar_wav(HASIL_REPO) == NAMA, f'assets/audio/sfx/mission/ berisi tepat 4 WAV itu, dapat {daftar_wav(HASIL_REPO)}')

        total = 0
        sampel_per = {}
        byte_per = {}
        for nama in NAMA:
            jalur_repo = os.path.join(HASIL_REPO, nama)
            ada = os.path.isfile(jalur_repo)
            periksa(ada, f'{nama} ada di assets/audio/sfx/')
            if not ada or nama not in daftar:
                continue
            total += os.path.getsize(jalur_repo)
            byte_per[nama] = baca(jalur_repo)
            periksa(byte_per[nama] == baca(os.path.join(a, nama)), f'{nama}: berkas di repo byte-identik dengan keluaran skrip (tidak diedit tangan)')
            kanal, lebar, laju, sampel = sampel_wav(jalur_repo)
            sampel_per[nama] = sampel
            periksa(kanal == 1 and lebar == 2 and laju == LAJU_SAMPEL, f'{nama}: mono 16-bit {LAJU_SAMPEL} Hz')
            durasi = len(sampel) / LAJU_SAMPEL
            durasi_min, durasi_maks = RENTANG[nama]
            periksa(durasi_min - 1e-9 <= durasi <= durasi_maks + 1e-9, f'{nama}: durasi {durasi:.3f} detik ({durasi_min}..{durasi_maks})')
            periksa(max((abs(s) for s in sampel), default=0) > 8192, f'{nama}: tidak senyap (puncak di atas seperempat skala)')
            periksa(not masalah_tepi(sampel), f'{nama}: tanpa klik di awal dan akhir: {masalah_tepi(sampel)}')
            jalur_impor = jalur_repo + '.import'
            impor = open(jalur_impor, encoding='utf-8').read() if os.path.isfile(jalur_impor) else ''
            periksa('edit/loop_mode=1\n' in impor and 'compress/mode=0\n' in impor and 'importer="wav"' in impor and 'uid="uid://' in impor,
                    f'{nama}.import: hasil Godot (uid), edit/loop_mode=1 (sekali putar), compress/mode=0 (PCM)')
        periksa(0 < total < BATAS_TOTAL_BYTE, f'total 4 WAV {total} byte, di bawah {BATAS_TOTAL_BYTE // 1024} KB (anggaran audio M3 10 MB)')

        def puncak(nama):
            return max((abs(s) for s in sampel_per.get(nama, [])), default=0)
        puncak_gagal = puncak('mission/sfx_mis_gagal_01.wav')
        puncak_lain = min(puncak(n) for n in NAMA if n != 'mission/sfx_mis_gagal_01.wav')
        periksa(0 < puncak_gagal < puncak_lain, f'bunyi gagal lebih pelan ({puncak_gagal}) dari bunyi lain terpelan ({puncak_lain}), SOUND_DESIGN 2 (gagal berbunyi lembut)')

        terlihat = sampel_per.get('mission/sfx_mis_terlihat_01.wav', [])
        selesai = sampel_per.get('mission/sfx_mis_selesai_01.wav', [])
        gagal_s = sampel_per.get('mission/sfx_mis_gagal_01.wav', [])
        meong = sampel_per.get('mission/sfx_mis_meong_01.wav', [])
        periksa(bool(terlihat) and paruh_lintas_nol(terlihat, 0.6, 0.9) > paruh_lintas_nol(terlihat, 0.05, 0.35) * 1.2, 'terlihat: nada naik (laju lintas nol akhir > awal)')
        periksa(bool(selesai) and paruh_lintas_nol(selesai, 0.7, 0.95) > paruh_lintas_nol(selesai, 0.0, 0.15) * 1.3, 'selesai: nada akhir lebih tinggi dari nada awal (naik)')
        periksa(bool(gagal_s) and paruh_lintas_nol(gagal_s, 0.7, 0.95) < paruh_lintas_nol(gagal_s, 0.0, 0.3) * 0.9, 'gagal: nada akhir lebih rendah dari nada awal (turun)')
        periksa(bool(meong) and paruh_lintas_nol(meong, 0.25, 0.4) > paruh_lintas_nol(meong, 0.0, 0.1) * 0.8, 'meong: nada tidak turun di sepertiga awal (naik menuju puncak)')

        semua_bunyi = [(byte_per.get(n, b''), sampel_per.get(n, [])) for n in NAMA]
        periksa(all(s for _, s in semua_bunyi) and len({b for b, _ in semua_bunyi}) == 4 and len({len(s) for _, s in semua_bunyi}) == 4, 'keempat bunyi berbeda nyata (byte dan panjang berbeda semua)')

        lisensi = open(LISENSI, encoding='utf-8').read() if os.path.isfile(LISENSI) else ''
        periksa(all(n.split('/')[1] in lisensi for n in NAMA) and 'sintesis_misi.py' in lisensi, 'assets/audio/LICENSES.md mencatat keempat WAV dan skrip pembuatnya')

        contoh = os.path.join(a, 'mission/sfx_mis_selesai_01.wav')
        data = bytearray(baca(contoh))
        data[-40] ^= 0x01
        periksa(bytes(data) != baca(os.path.join(HASIL_REPO, 'mission/sfx_mis_selesai_01.wav')), 'kontrol: berkas yang diubah satu byte terdeteksi berbeda')
        periksa(masalah_tepi([0, 100, -200, 3000, 50, 9000]) != [], 'kontrol: bunyi yang berakhir jauh dari nol ditolak (klik)')
        periksa(masalah_tepi([0, 40, -90, 3000, -2000, 50, 30, 0]) == [], 'kontrol: bunyi yang mulai dan berakhir di nol dengan tepi landai diterima')
        kembar = [(b'x', [0, 5, -5, 0]), (b'x', [0, 5, -5, 0]), (b'y', [0, 5, -5, 5, -5, 0])]
        periksa(masalah_variasi(kembar) != [], 'kontrol: dua bunyi kembar ditolak')
        periksa(paruh_lintas_nol([0, 1, -1, 1, -1, 1, -1, 1, -1, 1], 0.0, 0.5) > 0.0, 'kontrol: penghitung lintas nol bekerja')
        jalur_skrip_buruk = os.path.join(sementara, 'buruk.py')
        with open(jalur_skrip_buruk, 'w', encoding='utf-8') as f:
            f.write('import wave\nimport numpy as np\n')
        periksa(impor_stdlib(jalur_skrip_buruk)[0] == ['numpy'], 'kontrol: skrip yang mengimpor numpy ditolak')

    print(f"{lolos} lolos, {gagal} gagal")
    return 1 if gagal else 0


if __name__ == '__main__':
    sys.exit(main())
