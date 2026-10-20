#!/usr/bin/env python3
"""Uji aset kucing misi run 4B (M-10, AC-22 run fase4b-misi-kucing): `assets/sprites/npc/mission_kucing_sheet.{png,json}` sama persis dengan hasil
`tools/env_art/kendaraan.py` (tidak disalin atau diedit tangan), skrip deterministik (dua kali jalan = byte sama), hanya sheet kucing misi yang disalin
`--salin` (folder npc berisi tepat satu PNG dan satu JSON), JSON memuat sel 46x38, titik pijak (18, 21), 7 pose x 4 arah, dan pose `duduk` kolom 0 baris `masuk`.
Butuh numpy dan pillow (seperti `tools/env_art`); bila tidak ada, uji berhenti dengan exit code 2 dan pesan jelas (CI memasangnya).

Cara pakai (dari root repo):
    python3 tools/tests_cek/uji_aset_kucing.py

Exit code: 0 bila semua pemeriksaan lolos, 1 bila ada yang gagal, 2 bila numpy atau pillow tidak terpasang.
"""
import json
import os
import subprocess
import sys
import tempfile

FOLDER = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(FOLDER, '..', '..'))
SKRIP = os.path.join(ROOT, 'tools', 'env_art', 'kendaraan.py')
HASIL_REPO = os.path.join(ROOT, 'assets', 'sprites', 'npc')
NAMA = 'mission_kucing_sheet'

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


def piksel(jalur):
    # Bandingkan piksel RGBA, bukan byte berkas: pengodean zlib di PNG berbeda antar platform dan versi pillow (macOS vs runner CI)
    # padahal gambarnya sama.
    from PIL import Image
    with Image.open(jalur) as gambar:
        gambar = gambar.convert('RGBA')
        return gambar.size, gambar.tobytes()


def jalankan(keluaran):
    lingkungan = dict(os.environ, ENV_ART_OUT=keluaran)
    hasil = subprocess.run([sys.executable, SKRIP], capture_output=True, text=True, env=lingkungan, cwd=ROOT)
    return hasil.returncode, hasil.stdout + hasil.stderr


def main():
    try:
        import numpy  # noqa: F401
        import PIL  # noqa: F401
    except ImportError as galat:
        print('numpy dan pillow dibutuhkan untuk uji ini:', galat)
        return 2
    with tempfile.TemporaryDirectory() as sementara:
        a, b = os.path.join(sementara, 'a'), os.path.join(sementara, 'b')
        kode_a, keluaran_a = jalankan(a)
        kode_b, _ = jalankan(b)
        periksa(kode_a == 0 and kode_b == 0, f'kendaraan.py berhasil dua kali ({keluaran_a.strip()[-200:]})')
        for ekstensi in ('.png', '.json'):
            hasil_a = os.path.join(a, 'kendaraan', NAMA + ekstensi)
            hasil_b = os.path.join(b, 'kendaraan', NAMA + ekstensi)
            ada = os.path.isfile(hasil_a) and os.path.isfile(hasil_b)
            periksa(ada, f'{NAMA}{ekstensi} dihasilkan skrip')
            if not ada:
                continue
            periksa(baca(hasil_a) == baca(hasil_b), f'{NAMA}{ekstensi}: dua kali jalan menghasilkan byte yang sama (deterministik)')
            repo = os.path.join(HASIL_REPO, NAMA + ekstensi)
            if ekstensi == '.png':
                periksa(os.path.isfile(repo) and piksel(repo) == piksel(hasil_a), f'{NAMA}{ekstensi} di assets/sprites/npc/ piksel-identik dengan keluaran skrip (bukan salinan tangan)')
            else:
                periksa(os.path.isfile(repo) and baca(repo) == baca(hasil_a), f'{NAMA}{ekstensi} di assets/sprites/npc/ byte-identik dengan keluaran skrip (bukan salinan tangan)')
    isi = sorted(os.listdir(HASIL_REPO)) if os.path.isdir(HASIL_REPO) else []
    berkas_aset = [n for n in isi if not n.endswith('.import') and not n.endswith('.uid')]
    periksa(berkas_aset == [NAMA + '.json', NAMA + '.png'], f'assets/sprites/npc hanya berisi sheet kucing misi (png + json), dapat {berkas_aset}')
    periksa(os.path.isfile(os.path.join(HASIL_REPO, NAMA + '.png.import')), 'sheet kucing punya .import hasil Godot')
    data = json.loads(baca(os.path.join(HASIL_REPO, NAMA + '.json')))
    periksa(data['cell'] == [46, 38] and data['ground_anchor'] == [18, 21] and data['columns'] == 7 and data['rows'] == 4, 'JSON: sel 46x38, titik pijak (18, 21), 7 kolom, 4 baris')
    periksa(data['frames'][0] == 'duduk' and data['row_names'][1] == 'masuk', 'JSON: kolom 0 = duduk, baris 1 = masuk (menghadap rumah seberang)')
    # Kontrol: berkas yang diubah satu byte terdeteksi berbeda dari hasil skrip.
    asli = bytearray(baca(os.path.join(HASIL_REPO, NAMA + '.png')))
    asli[-20] ^= 0x01
    periksa(bytes(asli) != baca(os.path.join(HASIL_REPO, NAMA + '.png')), 'kontrol: perbandingan byte mendeteksi satu byte berbeda')
    print(f'{lolos} lolos, {gagal} gagal')
    return 1 if gagal else 0


if __name__ == '__main__':
    sys.exit(main())
