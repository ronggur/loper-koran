#!/usr/bin/env python3
"""Uji aset fase 3 perumahan `tools/env_art/fase3.py` (run fase5d-sisi-dekat, AC-2; pola `uji_aset_kucing.py` dan `uji_aset_lampu_pohon.py`):

1. Deterministik: dua kali jalan (folder build berbeda) = piksel RGBA sama untuk semua PNG dan byte sama untuk semua JSON.
2. Isi `assets/sprites/{houses/perumahan,obstacles,props}` yang berasal dari fase3 = keluaran skrip: PNG piksel-identik (bukan byte: pengodean
   zlib beda antar mesin), JSON byte-identik. Daftar sprite fase3 ditulis di sini (`DIPASANG`), bukan dibaca dari skrip.
3. `--salin` (ke folder sementara lewat `ENV_ART_SALIN_KE`) hanya menyalin daftar itu (PNG + JSON) dan tujuh mock dokumen; `assets/sprites/houses/perumahan/`
   tidak memuat `house_perumahan_*` lain dan `obstacles/` hanya berisi anjing dan mobil.
4. Mock dokumen `docs/design/environment/fase3_*.png` = keluaran skrip diperbesar x2 (tetangga terdekat), termasuk lembar banding rumah dekat dan
   layar contoh run 5D; JSON rumah dekat run 5D memuat geometri teras dan kotak penutup (literal) dan catatan tanpa kotak surat terpanggang.
5. Impor: tiap PNG fase3 di `assets/` punya `.png.import` Lossless, tanpa mipmap, bukan tekstur VRAM.
6. Kontrol: satu byte PNG dan satu piksel yang diubah terdeteksi.

Butuh numpy dan pillow (seperti `tools/env_art`); bila tidak ada, uji berhenti dengan exit code 2 (CI memasangnya).

Cara pakai (dari root repo):
    python3 tools/tests_cek/uji_aset_fase3.py

Exit code: 0 lolos semua, 1 ada yang gagal, 2 numpy/pillow tidak terpasang.
"""
import os
import subprocess
import sys
import tempfile

FOLDER = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(FOLDER, '..', '..'))
SKRIP = os.path.join(ROOT, 'tools', 'env_art', 'fase3.py')
SPRITES = os.path.join(ROOT, 'assets', 'sprites')
MOCK = os.path.join(ROOT, 'docs', 'design', 'environment')

RUMAH_SEBERANG = ['house_perumahan_%s_%s' % (j, p) for j in ('limasan', 'pelana', 'sayap') for p in ('pelanggan', 'bukan')]
RUMAH_DEKAT = ['house_perumahan_dekat_%s_%s' % (j, p) for j in ('limasan', 'pelana_lintang', 'pelana_sejajar') for p in ('pelanggan', 'bukan')]
DIPASANG = {
    'houses/perumahan': RUMAH_SEBERANG + RUMAH_DEKAT,
    'obstacles': ['obs_anjing_sheet', 'obs_mobil_garasi_sheet'],
    'props': ['prop_kotak_surat', 'prop_kotak_surat_bukan'],
}
MOCK_DOK = {'layar_fase3.png': 'fase3_perumahan.png', 'layar_dua_sisi.png': 'fase3_dua_sisi.png', 'antena_tv_contoh.png': 'fase3_antena_tv.png',
            'obs_anjing_sheet.png': 'fase3_anjing.png', 'obs_mobil_garasi_sheet.png': 'fase3_mobil_garasi.png',
            # run fase5d (AC-3): lembar banding rumah dekat lama/baru dan layar contoh tata letak game
            'banding_rumah_dekat.png': 'fase3_rumah_dekat_banding.png', 'layar_dekat_5d.png': 'fase3_layar_dekat_5d.png'}
# Geometri rumah dekat run 5D di JSON (ubin relatif titik pijak gambar; dihitung tangan dari konstanta DEKAT_* fase3.py: unit / 32):
# teras x -58..-30, y 14..44 -> [-1.8125, -1.375, 0.875, 0.9375]; penutup = badan + cucuran (x -35..45, y -45..45) dan belakang (toren/jemuran) tanpa
# teras dan antena; tinggi = puncak atap / 32.
GEOMETRI_DEKAT = {
    'limasan': {'teras_ubin': [-1.8125, -1.375, 0.875, 0.9375], 'penutup_ubin': [-1.09375, -1.40625, 3.06875, 2.8125], 'penutup_tinggi_ubin': 1.625},
    'pelana_lintang': {'teras_ubin': [-1.8125, -1.375, 0.875, 0.9375], 'penutup_ubin': [-1.09375, -1.40625, 3.1125, 2.8125], 'penutup_tinggi_ubin': 1.6875},
    'pelana_sejajar': {'teras_ubin': [-1.8125, -1.375, 0.875, 0.9375], 'penutup_ubin': [-1.09375, -1.375, 3.1125, 2.75], 'penutup_tinggi_ubin': 1.5625},
}

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


def piksel(jalur, kali=1):
    from PIL import Image
    with Image.open(jalur) as gambar:
        gambar = gambar.convert('RGBA')
        if kali != 1:
            gambar = gambar.resize((gambar.width * kali, gambar.height * kali), Image.NEAREST)
        return gambar.size, gambar.tobytes()


def jalankan(keluaran, salin_ke=None):
    lingkungan = dict(os.environ, ENV_ART_OUT=keluaran)
    argumen = [sys.executable, SKRIP]
    if salin_ke is not None:
        lingkungan['ENV_ART_SALIN_KE'] = salin_ke
        argumen.append('--salin')
    hasil = subprocess.run(argumen, capture_output=True, text=True, env=lingkungan, cwd=ROOT)
    return hasil.returncode, hasil.stdout + hasil.stderr


def berkas_aset(folder):
    if not os.path.isdir(folder):
        return []
    return sorted(n for n in os.listdir(folder) if not n.endswith('.import') and not n.endswith('.uid'))


def main():
    try:
        import numpy  # noqa: F401
        import PIL  # noqa: F401
    except ImportError as galat:
        print('numpy dan pillow dibutuhkan untuk uji ini:', galat)
        return 2
    with tempfile.TemporaryDirectory() as sementara:
        a, b, tujuan = (os.path.join(sementara, n) for n in ('a', 'b', 'salin'))
        kode_a, keluaran_a = jalankan(a)
        kode_b, keluaran_b = jalankan(b, tujuan)
        periksa(kode_a == 0 and kode_b == 0, 'fase3.py berhasil dua kali (%s | %s)' % (keluaran_a.strip()[-200:], keluaran_b.strip()[-200:]))
        hasil_a, hasil_b = os.path.join(a, 'fase3'), os.path.join(b, 'fase3')
        # 1. deterministik
        semua = sorted(os.listdir(hasil_a)) if os.path.isdir(hasil_a) else []
        periksa(semua == (sorted(os.listdir(hasil_b)) if os.path.isdir(hasil_b) else None), 'dua kali jalan menghasilkan daftar berkas yang sama')
        for nama in semua:
            ja, jb = os.path.join(hasil_a, nama), os.path.join(hasil_b, nama)
            if not os.path.isfile(jb):
                continue
            if nama.endswith('.png'):
                periksa(piksel(ja) == piksel(jb), '%s: dua kali jalan = piksel sama (deterministik)' % nama)
            else:
                periksa(baca(ja) == baca(jb), '%s: dua kali jalan = byte sama (deterministik)' % nama)
        # 2. isi assets/ = keluaran skrip
        for folder, nama_nama in DIPASANG.items():
            for nama in nama_nama:
                for ekstensi in ('.png', '.json'):
                    keluar = os.path.join(hasil_a, nama + ekstensi)
                    repo = os.path.join(SPRITES, folder, nama + ekstensi)
                    ada = os.path.isfile(keluar) and os.path.isfile(repo)
                    periksa(ada, '%s%s ada di keluaran skrip dan di assets/sprites/%s' % (nama, ekstensi, folder))
                    if not ada:
                        continue
                    if ekstensi == '.png':
                        periksa(piksel(keluar) == piksel(repo), 'assets/sprites/%s/%s.png piksel-identik dengan keluaran fase3.py' % (folder, nama))
                    else:
                        periksa(baca(keluar) == baca(repo), 'assets/sprites/%s/%s.json byte-identik dengan keluaran fase3.py' % (folder, nama))
        # 3. --salin hanya yang dipasang
        for folder, nama_nama in DIPASANG.items():
            diharapkan = sorted(n + e for n in nama_nama for e in ('.png', '.json'))
            periksa(berkas_aset(os.path.join(tujuan, 'assets', 'sprites', folder)) == diharapkan,
                    '--salin ke assets/sprites/%s hanya daftar fase3 (dapat %s)' % (folder, berkas_aset(os.path.join(tujuan, 'assets', 'sprites', folder))))
        periksa(sorted(os.listdir(os.path.join(tujuan, 'assets', 'sprites'))) == sorted(f.split('/')[0] for f in DIPASANG),
                '--salin tidak membuat folder sprite lain')
        periksa(berkas_aset(os.path.join(tujuan, 'docs', 'design', 'environment')) == sorted(MOCK_DOK.values()), '--salin menyalin tepat tujuh mock dokumen')
        rumah_repo = [n for n in berkas_aset(os.path.join(SPRITES, 'houses', 'perumahan')) if n.startswith('house_perumahan_')]
        periksa(rumah_repo == sorted(n + e for n in DIPASANG['houses/perumahan'] for e in ('.png', '.json')),
                'assets/sprites/houses/perumahan tidak memuat house_perumahan_* di luar daftar fase3 (dapat %s)' % rumah_repo)
        periksa(berkas_aset(os.path.join(SPRITES, 'obstacles')) == sorted(n + e for n in DIPASANG['obstacles'] for e in ('.png', '.json')),
                'assets/sprites/obstacles hanya anjing dan mobil garasi')
        # 4. mock dokumen = keluaran x2
        for sumber, tujuan_mock in MOCK_DOK.items():
            keluar = os.path.join(hasil_a, sumber)
            dok = os.path.join(MOCK, tujuan_mock)
            periksa(os.path.isfile(keluar) and os.path.isfile(dok) and piksel(keluar, 2) == piksel(dok, 1),
                    'docs/design/environment/%s = keluaran %s diperbesar x2' % (tujuan_mock, sumber))
    # 4b. geometri rumah dekat di JSON (literal) dan catatan tanpa kotak surat terpanggang
    import json
    for jenis, harap in GEOMETRI_DEKAT.items():
        for p in ('pelanggan', 'bukan'):
            jalur = os.path.join(SPRITES, 'houses', 'perumahan', 'house_perumahan_dekat_%s_%s.json' % (jenis, p))
            data = json.loads(baca(jalur)) if os.path.isfile(jalur) else {}
            periksa(all(data.get(k) == v for k, v in harap.items()), 'JSON rumah dekat %s_%s: teras, penutup, tinggi = literal (dapat %s)' % (
                jenis, p, {k: data.get(k) for k in harap}))
            periksa('TANPA kotak surat' in data.get('note', ''), 'JSON rumah dekat %s_%s: catatan tanpa kotak surat terpanggang' % (jenis, p))
    # 5. impor Lossless
    for folder, nama_nama in DIPASANG.items():
        for nama in nama_nama:
            jalur = os.path.join(SPRITES, folder, nama + '.png.import')
            teks = baca(jalur).decode('utf-8') if os.path.isfile(jalur) else ''
            periksa('compress/mode=0\n' in teks and 'mipmaps/generate=false\n' in teks and '"vram_texture": false' in teks and 'uid="uid://' in teks,
                    '%s.png.import: Lossless, tanpa mipmap, bukan VRAM, uid ada' % nama)
    # 6. kontrol
    contoh = os.path.join(SPRITES, 'obstacles', 'obs_mobil_garasi_sheet.png')
    asli = baca(contoh)
    ubah = bytearray(asli)
    ubah[-20] ^= 0x01
    periksa(bytes(ubah) != asli, 'kontrol: perbandingan byte mendeteksi satu byte berbeda')
    ukuran, isi = piksel(contoh)
    isi2 = bytearray(isi)
    isi2[0] ^= 0x01
    periksa((ukuran, bytes(isi2)) != (ukuran, isi), 'kontrol: perbandingan piksel mendeteksi satu piksel berbeda')
    print(f'{lolos} lolos, {gagal} gagal')
    return 1 if gagal else 0


if __name__ == '__main__':
    sys.exit(main())
