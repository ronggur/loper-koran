#!/usr/bin/env python3
"""Uji `tools/loper_art/bangun_frames.py` (pembangun SpriteFrames gabungan). Hanya pustaka standar.

Membuktikan: (1) `loper_agen_frames.tres` dan salinan aset di repo sama persis dengan hasil skrip dari tiga JSON sumber
(tidak ada yang diedit dengan tangan), (2) skrip deterministik (dua kali jalan = byte sama), (3) hasilnya 38 animasi dengan
loop dan fps yang benar, (4) skrip menolak sumber yang rusak (nama ganda, region di luar PNG, PNG hilang, ukuran sheet
tidak cocok dengan JSON) dan `--cek` menolak berkas hasil yang diubah.

Cara pakai (dari root repo):
    python3 tools/tests_cek/uji_bangun_frames.py

Exit code: 0 bila semua pemeriksaan lolos, 1 bila ada yang gagal.
"""
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

FOLDER = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(FOLDER, '..', '..'))
SKRIP = os.path.join(ROOT, 'tools', 'loper_art', 'bangun_frames.py')
SUMBER = os.path.join(ROOT, 'docs', 'design', 'character', 'loper_agen')
HASIL_REPO = os.path.join(ROOT, 'assets', 'sprites', 'loper')
BERKAS_SUMBER = ['loper_agen.json', 'loper_agen.png', 'melambat/loper_agen_melambat.json', 'melambat/loper_agen_melambat.png',
                 'lempar/loper_agen_lempar.json', 'lempar/loper_agen_lempar.png']

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


def salin_sumber(tujuan):
    for rel in BERKAS_SUMBER:
        jalur = os.path.join(tujuan, rel)
        os.makedirs(os.path.dirname(jalur), exist_ok=True)
        shutil.copyfile(os.path.join(SUMBER, rel), jalur)


def main():
    # (1) Berkas di repo = hasil skrip.
    kode, keluaran = jalankan('--cek')
    periksa(kode == 0, f'--cek terhadap assets/sprites/loper: berkas di repo sama dengan hasil skrip ({keluaran.strip()})')
    for rel in BERKAS_SUMBER:
        periksa(baca(os.path.join(SUMBER, rel)) == baca(os.path.join(HASIL_REPO, os.path.basename(rel))),
                f'{os.path.basename(rel)}: salinan di assets byte-identik dengan sumber')

    with tempfile.TemporaryDirectory() as sementara:
        # (2) Deterministik: dua kali jalan, semua berkas sama.
        a, b = os.path.join(sementara, 'a'), os.path.join(sementara, 'b')
        kode_a, _ = jalankan('--out', a)
        kode_b, _ = jalankan('--out', b)
        periksa(kode_a == 0 and kode_b == 0, 'skrip berhasil ditulis dua kali ke folder berbeda')
        daftar = sorted(os.listdir(a))
        periksa(daftar == sorted(os.listdir(b)) and len(daftar) == 7, f'dua kali jalan menghasilkan 7 berkas yang sama, dapat {daftar}')
        periksa(all(baca(os.path.join(a, n)) == baca(os.path.join(b, n)) for n in daftar), 'dua kali jalan menghasilkan byte yang sama')
        periksa(baca(os.path.join(a, 'loper_agen_frames.tres')) == baca(os.path.join(HASIL_REPO, 'loper_agen_frames.tres')),
                '.tres hasil = .tres di repo')

        # (3) Isi .tres: 38 animasi, loop dan fps menurut JSON.
        tres = baca(os.path.join(a, 'loper_agen_frames.tres')).decode('utf-8')
        periksa(tres.count('"name": &"') == 38, '.tres memuat 38 animasi')
        periksa(tres.count('"loop": false') == 18 and tres.count('"loop": true') == 20, 'loop false untuk 18 lempar saja, true untuk 15 kayuh + 5 melambat')
        periksa(tres.count('"speed": 4.0') == 5 and tres.count('"speed": 12.0') == 18 + 5 and tres.count('"speed": 8.0') == 5 and tres.count('"speed": 10.0') == 5,
                'fps: 4 untuk 5 melambat, 8 dan 10 untuk 5 kayuh masing-masing, 12 untuk 5 kayuh ngebut + 18 lempar')
        periksa(tres.count('[sub_resource') == 152 and tres.count('[ext_resource') == 3 and 'load_steps=156' in tres, '152 AtlasTexture, 3 sheet, load_steps 156')
        periksa(re.search(r'"name": &"lempar_[a-z_]+",\n"speed": 12.0', tres) is not None, 'animasi lempar ditulis dengan nama lempar_... dan speed 12.0')
        meta = json.loads(baca(os.path.join(SUMBER, 'lempar', 'loper_agen_lempar.json')))
        urut = [m for m in re.findall(r'"name": &"([^"]+)"', tres)]
        periksa(urut[20:] == [x['name'] for x in meta['animations']], 'urutan 18 animasi lempar di .tres = urutan JSON')

        # (4) Sumber rusak ditolak (exit 2), --cek menolak hasil yang diubah (exit 1).
        def sumber_rusak(ubah, label, harapan=2):
            folder = tempfile.mkdtemp(dir=sementara)
            salin_sumber(folder)
            ubah(folder)
            kode_rusak, keluaran_rusak = jalankan('--src', folder, '--out', os.path.join(folder, 'hasil'))
            periksa(kode_rusak == harapan, f'sumber rusak ditolak: {label} (exit {kode_rusak}, harapan {harapan}): {keluaran_rusak.strip()[:90]}')

        def ubah_json(rel, fungsi):
            def terapkan(folder):
                jalur = os.path.join(folder, rel)
                data = json.loads(baca(jalur))
                fungsi(data)
                with open(jalur, 'w', encoding='utf-8') as f:
                    json.dump(data, f)
            return terapkan

        lempar = 'lempar/loper_agen_lempar.json'
        sumber_rusak(ubah_json(lempar, lambda d: d['animations'][1].update(name=d['animations'][0]['name'])), 'nama animasi ganda')
        sumber_rusak(ubah_json(lempar, lambda d: d['animations'][0]['regions'][3].__setitem__(0, 9999)), 'region di luar PNG')
        sumber_rusak(ubah_json(lempar, lambda d: d.update(rows=17)), 'jumlah baris JSON tidak cocok dengan tinggi PNG')
        sumber_rusak(ubah_json(lempar, lambda d: d['animations'][0].update(regions=[])), 'animasi tanpa frame')
        sumber_rusak(lambda folder: os.remove(os.path.join(folder, 'melambat', 'loper_agen_melambat.png')), 'PNG melambat hilang')
        sumber_rusak(lambda folder: os.remove(os.path.join(folder, 'lempar', 'loper_agen_lempar.json')), 'JSON lempar hilang')
        sumber_rusak(lambda folder: open(os.path.join(folder, 'loper_agen.png'), 'wb').write(b'bukan png'), 'berkas PNG rusak')

        # --cek menolak berkas hasil yang diubah, dihapus, atau hilang foldernya.
        tres_ubah = os.path.join(a, 'loper_agen_frames.tres')
        asli = baca(tres_ubah)
        with open(tres_ubah, 'wb') as f:
            f.write(asli.replace(b'"loop": false', b'"loop": true', 1))
        kode_cek, _ = jalankan('--cek', '--out', a)
        periksa(kode_cek == 1, '--cek menolak .tres yang satu animasi lemparnya diubah jadi loop')
        with open(tres_ubah, 'wb') as f:
            f.write(asli)
        png_ubah = os.path.join(a, 'loper_agen_lempar.png')
        png_asli = baca(png_ubah)
        with open(png_ubah, 'wb') as f:
            f.write(png_asli[:-1] + bytes([png_asli[-1] ^ 1]))
        kode_cek, _ = jalankan('--cek', '--out', a)
        periksa(kode_cek == 1, '--cek menolak PNG salinan yang satu byte-nya berbeda dari sumber')
        with open(png_ubah, 'wb') as f:
            f.write(png_asli)
        kode_cek, _ = jalankan('--cek', '--out', a)
        periksa(kode_cek == 0, '--cek menerima kembali hasil yang dipulihkan (kontrol positif)')
        kode_cek, _ = jalankan('--cek', '--out', os.path.join(sementara, 'tidak_ada'))
        periksa(kode_cek == 1, '--cek menolak folder hasil yang tidak ada')

    print(f'uji_bangun_frames: {lolos} lolos, {gagal} gagal')
    return 1 if gagal else 0


if __name__ == '__main__':
    sys.exit(main())
