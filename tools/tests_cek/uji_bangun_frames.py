#!/usr/bin/env python3
"""Uji `tools/loper_art/bangun_frames.py` (pembangun SpriteFrames gabungan). Hanya pustaka standar.

Membuktikan: (1) `loper_agen_frames.tres` dan salinan aset di repo sama persis dengan hasil skrip dari delapan JSON sumber
(tidak ada yang diedit dengan tangan), (2) skrip deterministik (dua kali jalan = byte sama), (3) hasilnya 68 animasi
(15 kayuh + 5 melambat + 18 lempar + 5 meluncur + 5 rem + 10 jatuh/terjerembab + 5 bangkit + 5 berhenti; Fase 5C) dengan urutan,
loop, dan fps yang benar, (4) skrip menolak sumber yang rusak (nama ganda, region di luar PNG, PNG hilang, ukuran sheet tidak
cocok dengan JSON, juga untuk sheet meluncur, rem, jatuh, bangkit, dan berhenti) dan `--cek` menolak berkas hasil yang diubah.

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
                 'lempar/loper_agen_lempar.json', 'lempar/loper_agen_lempar.png',
                 'rem_meluncur/loper_agen_meluncur.json', 'rem_meluncur/loper_agen_meluncur.png',
                 'rem_meluncur/loper_agen_rem.json', 'rem_meluncur/loper_agen_rem.png',
                 'jatuh/loper_agen_jatuh.json', 'jatuh/loper_agen_jatuh.png',
                 'bangkit/loper_agen_bangkit.json', 'bangkit/loper_agen_bangkit.png',
                 'berhenti/loper_agen_berhenti.json', 'berhenti/loper_agen_berhenti.png']
ARAH = ['normal', 'serong_kanan', 'kanan', 'serong_kiri', 'kiri']

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
        periksa(daftar == sorted(os.listdir(b)) and len(daftar) == 17, f'dua kali jalan menghasilkan 17 berkas yang sama, dapat {daftar}')
        periksa(all(baca(os.path.join(a, n)) == baca(os.path.join(b, n)) for n in daftar), 'dua kali jalan menghasilkan byte yang sama')
        periksa(baca(os.path.join(a, 'loper_agen_frames.tres')) == baca(os.path.join(HASIL_REPO, 'loper_agen_frames.tres')),
                '.tres hasil = .tres di repo')

        # (3) Isi .tres: 68 animasi, loop dan fps menurut JSON.
        tres = baca(os.path.join(a, 'loper_agen_frames.tres')).decode('utf-8')
        periksa(tres.count('"name": &"') == 68, '.tres memuat 68 animasi')
        periksa(tres.count('"loop": false') == 18 + 5 + 5 and tres.count('"loop": true') == 30 + 5 + 5,
                'loop false untuk 18 lempar + 5 jatuh + 5 bangkit, true untuk 15 kayuh + 5 melambat + 5 meluncur + 5 rem + 5 terjerembab + 5 berhenti')
        periksa(tres.count('"speed": 4.0') == 5 + 5 and tres.count('"speed": 12.0') == 18 + 5 and tres.count('"speed": 8.0') == 5 + 5
                and tres.count('"speed": 10.0') == 5 + 5 + 5 and tres.count('"speed": 3.0') == 5 + 5,
                'fps: 4 untuk 5 melambat + 5 meluncur, 8 untuk 5 santai + 5 rem, 10 untuk 5 cepat + 5 jatuh + 5 bangkit, 12 untuk 5 ngebut + 18 lempar, 3 untuk 5 terjerembab + 5 berhenti')
        periksa(tres.count('[sub_resource') == 262 and tres.count('[ext_resource') == 8 and 'load_steps=271' in tres,
                '262 AtlasTexture (192 + 20 jatuh + 10 terjerembab + 30 bangkit + 10 berhenti), 8 sheet, load_steps 271')
        periksa(re.search(r'"name": &"jatuh_normal",\n"speed": 10.0', tres) is not None and re.search(r'"loop": true,\n"name": &"terjerembab_normal",\n"speed": 3.0', tres) is not None,
                'jatuh_normal 10 fps dan terjerembab_normal 3 fps berulang')
        periksa('[ext_resource type="Texture2D" path="res://assets/sprites/loper/loper_agen_jatuh.png" id="6_jatuh"]' in tres, 'sheet jatuh dirujuk dari assets/sprites/loper')
        # Region jatuh dan terjerembab = sel 140x88 dari JSON (frame 3 dipakai keduanya), baris = arah.
        periksa(tres.count('atlas = ExtResource("6_jatuh")') == 30 and 'region = Rect2(420, 0, 140, 88)' in tres and 'region = Rect2(560, 352, 140, 88)' in tres,
                '30 AtlasTexture memakai sheet jatuh, termasuk frame 3 normal (420, 0) dan frame 4 kiri (560, 352) bersel 140x88')
        periksa(tres.count('atlas = ExtResource("7_bangkit")') == 30 and 'region = Rect2(700, 352, 140, 88)' in tres
                and tres.count('atlas = ExtResource("8_berhenti")') == 10 and 'region = Rect2(46, 232, 46, 58)' in tres,
                '30 AtlasTexture bangkit (frame 5 kiri di 700, 352) dan 10 berhenti (frame 1 kiri di 46, 232)')
        periksa(re.search(r'"loop": false,\n"name": &"bangkit_kiri",\n"speed": 10.0', tres) is not None
                and re.search(r'"loop": true,\n"name": &"berhenti_normal",\n"speed": 3.0', tres) is not None,
                'bangkit_kiri 10 fps sekali, berhenti_normal 3 fps berulang')
        periksa(re.search(r'"name": &"meluncur_normal",\n"speed": 4.0', tres) is not None and re.search(r'"name": &"rem_normal",\n"speed": 8.0', tres) is not None,
                'meluncur_normal 4 fps dan rem_normal 8 fps')
        periksa(re.search(r'"name": &"lempar_[a-z_]+",\n"speed": 12.0', tres) is not None, 'animasi lempar ditulis dengan nama lempar_... dan speed 12.0')
        meta = json.loads(baca(os.path.join(SUMBER, 'lempar', 'loper_agen_lempar.json')))
        urut = [m for m in re.findall(r'"name": &"([^"]+)"', tres)]
        periksa(urut[20:38] == [x['name'] for x in meta['animations']], 'urutan 18 animasi lempar di .tres = urutan JSON')
        for i, rel in ((38, 'rem_meluncur/loper_agen_meluncur.json'), (43, 'rem_meluncur/loper_agen_rem.json')):
            meta_baru = json.loads(baca(os.path.join(SUMBER, rel)))
            periksa(urut[i:i + 5] == [x['name'] for x in meta_baru['animations']], f'urutan 5 animasi {os.path.basename(rel)} di .tres = urutan JSON, sesudah lempar')
        periksa(urut[48:58] == [f'{j}_{h}' for h in ARAH for j in ('jatuh', 'terjerembab')], f'sepuluh animasi jatuh sesudah rem, dapat {urut[48:58]}')
        periksa(urut[58:63] == [f'bangkit_{h}' for h in ARAH] and urut[63:68] == [f'berhenti_{h}' for h in ARAH],
                f'bangkit lalu berhenti paling belakang, dapat {urut[58:]}')
        periksa(len(urut) == len(set(urut)) == 68, '68 nama animasi berbeda semua')

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
        rem = 'rem_meluncur/loper_agen_rem.json'
        meluncur = 'rem_meluncur/loper_agen_meluncur.json'
        sumber_rusak(ubah_json(rem, lambda d: d['animations'][0].update(name='meluncur_normal')), 'nama rem sama dengan nama meluncur (ganda lintas sheet)')
        sumber_rusak(ubah_json(meluncur, lambda d: d['animations'][4]['regions'][0].__setitem__(1, 300)), 'region meluncur di luar PNG')
        sumber_rusak(ubah_json(rem, lambda d: d.update(rows=6)), 'jumlah baris JSON rem tidak cocok dengan tinggi PNG')
        sumber_rusak(lambda folder: os.remove(os.path.join(folder, 'rem_meluncur', 'loper_agen_rem.png')), 'PNG rem hilang')
        sumber_rusak(lambda folder: os.remove(os.path.join(folder, 'rem_meluncur', 'loper_agen_meluncur.json')), 'JSON meluncur hilang')
        jatuh = 'jatuh/loper_agen_jatuh.json'
        sumber_rusak(ubah_json(jatuh, lambda d: d['animations'][1].update(name='rem_normal')), 'nama terjerembab sama dengan nama rem (ganda lintas sheet)')
        sumber_rusak(ubah_json(jatuh, lambda d: d['animations'][1]['regions'][1].__setitem__(0, 600)), 'region terjerembab di luar PNG jatuh (600 + 140 > 700)')
        sumber_rusak(ubah_json(jatuh, lambda d: d.update(columns=4)), 'jumlah kolom JSON jatuh tidak cocok dengan lebar PNG')
        sumber_rusak(lambda folder: os.remove(os.path.join(folder, 'jatuh', 'loper_agen_jatuh.png')), 'PNG jatuh hilang')
        bangkit = 'bangkit/loper_agen_bangkit.json'
        berhenti = 'berhenti/loper_agen_berhenti.json'
        sumber_rusak(ubah_json(bangkit, lambda d: d['animations'][0].update(name='jatuh_normal')), 'nama bangkit sama dengan nama jatuh (ganda lintas sheet)')
        sumber_rusak(ubah_json(bangkit, lambda d: d.update(columns=5)), 'jumlah kolom JSON bangkit tidak cocok dengan lebar PNG')
        sumber_rusak(ubah_json(berhenti, lambda d: d['animations'][4]['regions'][1].__setitem__(1, 260)), 'region berhenti di luar PNG (260 + 58 > 290)')
        sumber_rusak(lambda folder: os.remove(os.path.join(folder, 'berhenti', 'loper_agen_berhenti.png')), 'PNG berhenti hilang')

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
