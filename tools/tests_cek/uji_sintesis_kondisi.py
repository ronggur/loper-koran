#!/usr/bin/env python3
"""Uji `tools/audio_art/sintesis_kondisi.py` (bunyi placeholder kondisi sepeda run 6A1 bagian B: rantai berisik, rem berdecit, ban mendesis, servis, upgrade; AC-27 run
fase6a1-bengkel-kondisi). Hanya pustaka standar.

Membuktikan: (1) 5 WAV di `assets/audio/sfx/condition/` sama persis dengan keluaran skrip (tidak diedit tangan, tidak diganti rekaman atau unduhan), (2) skrip deterministik (dua
kali jalan = byte sama), (3) format WAV mono 16-bit 22050 Hz dan durasi tiap berkas di rentangnya, (4) tanpa klik: sampel pertama dan terakhir tepat nol dan sampel tepi dekat nol,
(5) sifat tiap bunyi: rem berdecit lebih tinggi nadanya dari rantai berisik (lintas nol), rantai berisik berupa lima ketukan terpisah, ban mendesis berupa derau yang meredup,
servis dan upgrade naik nadanya, (6) kelima bunyi berbeda nyata (byte dan panjang), (7) skrip hanya mengimpor pustaka standar, (8) `.import` sekali putar dan PCM,
`assets/audio/LICENSES.md` mencatat kelima berkas, total jauh di bawah anggaran, (9) pemeriksaan menolak contoh buruk.

Cara pakai (dari root repo):
    python3 tools/tests_cek/uji_sintesis_kondisi.py

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
SKRIP = os.path.join(ROOT, 'tools', 'audio_art', 'sintesis_kondisi.py')
HASIL_REPO = os.path.join(ROOT, 'assets', 'audio', 'sfx')
LISENSI = os.path.join(ROOT, 'assets', 'audio', 'LICENSES.md')
LAJU_SAMPEL = 22050
# Kelima nama ditulis eksplisit (SOUND_DESIGN 6), bukan dibaca dari skrip, dengan rentang durasi (detik, inklusif).
RENTANG = {
    'condition/sfx_cond_rantai_berisik_01.wav': (0.4, 0.8),
    'condition/sfx_cond_rem_berdecit_01.wav': (0.3, 0.7),
    'condition/sfx_cond_ban_mendesis_01.wav': (0.4, 0.9),
    'condition/sfx_cond_servis_01.wav': (0.4, 0.9),
    'condition/sfx_cond_upgrade_01.wav': (0.5, 1.1),
}
NAMA = sorted(RENTANG)
RANTAI, REM, BAN, SERVIS, UPGRADE = ('condition/sfx_cond_rantai_berisik_01.wav', 'condition/sfx_cond_rem_berdecit_01.wav', 'condition/sfx_cond_ban_mendesis_01.wav',
                                     'condition/sfx_cond_servis_01.wav', 'condition/sfx_cond_upgrade_01.wav')
BATAS_TOTAL_BYTE = 250 * 1024
BATAS_TEPI = 655
TEPI_SAMPEL = 3

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


def jendela(sampel, awal_detik, akhir_detik):
    return sampel[int(awal_detik * LAJU_SAMPEL):int(akhir_detik * LAJU_SAMPEL)]


def jumlah_semburan(sampel, ambang=2000, jeda_min=500):
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


def energi(sampel):
    return float(sum(s * s for s in sampel))


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
    jalur = os.path.join(folder, 'condition')
    if os.path.isdir(jalur):
        hasil.extend('condition/%s' % n for n in os.listdir(jalur) if n.endswith('.wav'))
    return sorted(hasil)


def main():
    bukan_stdlib, semua = impor_stdlib(SKRIP)
    periksa(not bukan_stdlib and semua, f'sintesis_kondisi.py hanya mengimpor pustaka standar ({", ".join(semua)}); bukan stdlib: {bukan_stdlib}')

    with tempfile.TemporaryDirectory() as sementara:
        a, b = os.path.join(sementara, 'a'), os.path.join(sementara, 'b')
        kode_a, keluaran_a = jalankan('--out', a)
        kode_b, _ = jalankan('--out', b)
        periksa(kode_a == 0 and kode_b == 0, f'skrip berhasil ditulis dua kali ke folder berbeda ({keluaran_a.strip()[:200]})')
        daftar = daftar_wav(a)
        periksa(daftar == NAMA and daftar == daftar_wav(b), f'skrip menulis tepat 5 berkas bernama sesuai rencana, dapat {daftar}')
        periksa(daftar and all(baca(os.path.join(a, n)) == baca(os.path.join(b, n)) for n in daftar), 'dua kali jalan menghasilkan byte yang sama (deterministik)')
        periksa(daftar_wav(HASIL_REPO) == NAMA, f'assets/audio/sfx/condition/ berisi tepat 5 WAV itu, dapat {daftar_wav(HASIL_REPO)}')

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
        periksa(0 < total < BATAS_TOTAL_BYTE, f'total 5 WAV {total} byte, di bawah {BATAS_TOTAL_BYTE // 1024} KB (anggaran audio M3 10 MB)')

        rantai = sampel_per.get(RANTAI, [])
        rem = sampel_per.get(REM, [])
        ban = sampel_per.get(BAN, [])
        servis = sampel_per.get(SERVIS, [])
        upgrade = sampel_per.get(UPGRADE, [])
        periksa(bool(rantai) and bool(rem) and lintas_nol_per_detik(rem) > 1.3 * lintas_nol_per_detik(rantai),
                f'rem berdecit lebih tinggi dari rantai berisik (lintas nol {lintas_nol_per_detik(rem):.0f} lawan {lintas_nol_per_detik(rantai):.0f} per detik)')
        periksa(bool(rantai) and jumlah_semburan(rantai) == 5, f'rantai berisik: lima ketukan terpisah, dapat {jumlah_semburan(rantai)}')
        n = len(ban)
        periksa(bool(ban) and energi(ban[n // 8:n // 2]) > 2.0 * energi(ban[n // 2:7 * n // 8]), 'ban mendesis: meredup (energi separuh awal > 2x separuh akhir)')
        periksa(bool(ban) and lintas_nol_per_detik(ban) > 2.0 * lintas_nol_per_detik(rem), 'ban mendesis: derau bernada tinggi (lintas nol > 2x rem berdecit)')
        periksa(bool(servis) and lintas_nol_per_detik(jendela(servis, 0.42, 0.52)) > 1.1 * lintas_nol_per_detik(jendela(servis, 0.28, 0.36)), 'servis: dua dentingan naik (dentingan kedua lebih tinggi)')
        periksa(bool(upgrade) and lintas_nol_per_detik(jendela(upgrade, 0.62, 0.78)) > 1.3 * lintas_nol_per_detik(jendela(upgrade, 0.0, 0.12)), 'upgrade: nada akhir lebih tinggi dari nada awal (naik)')

        semua_bunyi = [(byte_per.get(n_, b''), sampel_per.get(n_, [])) for n_ in NAMA]
        periksa(all(s for _, s in semua_bunyi) and len({b_ for b_, _ in semua_bunyi}) == 5 and len({len(s) for _, s in semua_bunyi}) == 5, 'kelima bunyi berbeda nyata (byte dan panjang berbeda semua)')

        lisensi = open(LISENSI, encoding='utf-8').read() if os.path.isfile(LISENSI) else ''
        periksa(all(n_.split('/')[1] in lisensi for n_ in NAMA) and 'sintesis_kondisi.py' in lisensi, 'assets/audio/LICENSES.md mencatat kelima WAV dan skrip pembuatnya')

        contoh = os.path.join(a, UPGRADE)
        data = bytearray(baca(contoh))
        data[-40] ^= 0x01
        periksa(bytes(data) != baca(os.path.join(HASIL_REPO, UPGRADE)), 'kontrol: berkas yang diubah satu byte terdeteksi berbeda')
        periksa(masalah_tepi([0, 100, -200, 3000, 50, 9000]) != [], 'kontrol: bunyi yang berakhir jauh dari nol ditolak (klik)')
        periksa(masalah_tepi([0, 40, -90, 3000, -2000, 50, 30, 0]) == [], 'kontrol: bunyi yang mulai dan berakhir di nol dengan tepi landai diterima')
        periksa(jumlah_semburan([0, 5000, 0, 0, 0, 5000, 0], 2000, 2) == 2 and jumlah_semburan([0, 5000, 0, 5000, 0], 2000, 2) == 1, 'kontrol: penghitung semburan memisahkan ketukan menurut senyap')
        periksa(lintas_nol_per_detik([0, 1, -1, 1, -1, 1, -1, 1, -1, 1]) > 0.0, 'kontrol: penghitung lintas nol bekerja')
        jalur_skrip_buruk = os.path.join(sementara, 'buruk.py')
        with open(jalur_skrip_buruk, 'w', encoding='utf-8') as f:
            f.write('import wave\nimport numpy as np\n')
        periksa(impor_stdlib(jalur_skrip_buruk)[0] == ['numpy'], 'kontrol: skrip yang mengimpor numpy ditolak')

    print(f"{lolos} lolos, {gagal} gagal")
    return 1 if gagal else 0


if __name__ == '__main__':
    sys.exit(main())
