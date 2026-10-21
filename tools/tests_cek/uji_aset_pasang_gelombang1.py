#!/usr/bin/env python3
"""Uji pemasangan aset gelombang 1 Fase 5 (run fase5a-pasang-aset-gelombang1, AC-2 dan AC-3; pola `uji_aset_kucing.py`):

1. `tools/env_art/gelombang1/render.py --salin` dan `tools/env_art/ubin_perumahan.py --salin` deterministik: dua kali jalan = piksel RGBA sama
   dan JSON byte-identik (tujuan dialihkan ke folder sementara lewat ENV_ART_SALIN_KE; folder repo tidak disentuh).
2. Isi `assets/sprites/props/`, `vfx/`, `tiles/perumahan/` piksel-identik (PNG) dan byte-identik (JSON) dengan keluaran skrip, dan berkas aset
   di folder itu HANYA daftar D-1 (13 sprite gelombang 1 + 7 ubin + JSON ubin terpangkas, ditambah kotak surat lama). Tidak ada aset
   gelombang 1 yang belum dipasang (tong sampah, jejak, mangkuk, portal, pos, tembok, percikan, polisi tidur, zebra, genangan, `*_masuk`,
   `*_simbol`, `aspal_N`, `rumput_2/3`) di assets/.
3. JSON konsisten: sel x jumlah frame = ukuran PNG, titik pijak di dalam sel (kecuali tumpangan kotak surat), ubin 64x32 pijak (32, 16),
   `tile_perumahan.json` hanya memuat ubin yang dipasang dan `tiles` = berkas PNG di folder.
4. Impor (AC-3): tiap PNG baru punya `.png.import` dengan `compress/mode=0` (Lossless) dan `mipmaps/generate=false`, ukuran < 2048, `.uid`
   ada, dan `project.godot` menggambar tekstur Nearest (`default_texture_filter=0`) dengan `snap_2d_transforms_to_pixel`.
5. Kontrol: satu byte yang diubah terdeteksi.

Butuh numpy dan pillow (seperti `tools/env_art`); bila tidak ada, uji berhenti dengan exit code 2 (CI memasangnya).

Cara pakai (dari root repo):
    python3 tools/tests_cek/uji_aset_pasang_gelombang1.py

Exit code: 0 lolos semua, 1 ada yang gagal, 2 numpy/pillow tidak terpasang.
"""
import json
import os
import re
import subprocess
import sys
import tempfile

FOLDER = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(FOLDER, '..', '..'))
SKRIP_SPRITE = os.path.join(ROOT, 'tools', 'env_art', 'gelombang1', 'render.py')
SKRIP_UBIN = os.path.join(ROOT, 'tools', 'env_art', 'ubin_perumahan.py')
SPRITES = os.path.join(ROOT, 'assets', 'sprites')

# Daftar D-1 (SPEC): satu-satunya aset gelombang 1 yang boleh ada di assets/.
PASANG_SPRITE = {
    'props': ['prop_koran_putar', 'prop_koran_bayangan', 'prop_koran_teras', 'prop_koran_rumput', 'prop_koran_kotak_surat',
              'prop_koran_terlipat'],
    'vfx': ['vfx_debu_roda', 'vfx_garis_kecepatan_a', 'vfx_garis_kecepatan_b', 'vfx_garis_kecepatan_c', 'vfx_bintang_kena',
            'vfx_koin_tip', 'mission_kilau'],
}
LAMA_PROPS = ['prop_kotak_surat', 'prop_kotak_surat_bukan']     # sudah ada sebelum run 5A (run 3A)
PASANG_UBIN = ['rumput_seberang', 'trotoar_seberang', 'aspal_seberang', 'aspal_dekat', 'trotoar_dekat', 'rumput_dekat']
UBIN_TAMBAHAN = ['rumput_1']        # pengecualian D-2 (satu ubin rumput polos)
TIDAK_DIPASANG = ('house_tembok_', 'prop_tong_sampah', 'mission_jejak', 'mission_mangkuk', 'prop_portal', 'prop_pos', 'vfx_percikan',
                  'tile_perumahan_polisi_tidur', 'tile_perumahan_zebra', 'tile_perumahan_genangan', 'prop_polisi_tidur')

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
    # Bandingkan piksel RGBA, bukan byte berkas: pengodean zlib PNG berbeda antar platform dan versi pillow padahal gambarnya sama.
    from PIL import Image
    with Image.open(jalur) as gambar:
        gambar = gambar.convert('RGBA')
        return gambar.size, gambar.tobytes()


def ukuran(jalur):
    from PIL import Image
    with Image.open(jalur) as gambar:
        return gambar.size


def jalankan(skrip, keluaran, salin_ke):
    env = dict(os.environ, ENV_ART_OUT=keluaran, ENV_ART_SALIN_KE=salin_ke)
    h = subprocess.run([sys.executable, skrip, '--salin'], capture_output=True, text=True, env=env, cwd=ROOT)
    return h.returncode, h.stdout + h.stderr


def berkas_aset(folder):
    """Berkas aset di folder, tanpa .import dan .uid (hasil Godot)."""
    return sorted(n for n in os.listdir(folder) if not n.endswith(('.import', '.uid'))) if os.path.isdir(folder) else []


def ekspektasi_repo():
    """{folder relatif: [nama berkas aset]} yang harus ada di assets/sprites sesuai D-1 (ditulis eksplisit, bukan dari skrip)."""
    props = sorted(n + e for n in PASANG_SPRITE['props'] + LAMA_PROPS for e in ('.png', '.json'))
    vfx = sorted(n + e for n in PASANG_SPRITE['vfx'] for e in ('.png', '.json'))
    ubin = sorted(['tile_perumahan_%s.png' % n for n in PASANG_UBIN + UBIN_TAMBAHAN] + ['tile_perumahan.json'])
    return {'props': props, 'vfx': vfx, os.path.join('tiles', 'perumahan'): ubin}


def main():
    try:
        import numpy  # noqa: F401
        import PIL  # noqa: F401
    except ImportError as galat:
        print('numpy dan pillow dibutuhkan untuk uji ini:', galat)
        return 2

    ekspektasi = ekspektasi_repo()
    with tempfile.TemporaryDirectory() as sementara:
        hasil_salin = {}
        for kunci in ('a', 'b'):
            out = os.path.join(sementara, 'out_' + kunci)
            tujuan = os.path.join(sementara, 'salin_' + kunci)
            os.makedirs(tujuan)
            # sprite ke <tujuan>/{props,vfx}; ubin ke <tujuan>/tiles/perumahan
            ks, os_ = jalankan(SKRIP_SPRITE, out, tujuan)
            ku, ou = jalankan(SKRIP_UBIN, out, os.path.join(tujuan, 'tiles', 'perumahan'))
            periksa(ks == 0, 'render.py --salin berhasil (%s): %s' % (kunci, os_.strip()[-200:]))
            periksa(ku == 0, 'ubin_perumahan.py --salin berhasil (%s): %s' % (kunci, ou.strip()[-200:]))
            periksa('beda sambungan: 0' in ou, 'ubin_perumahan.py: ubin menyambung, beda sambungan = 0 (%s)' % ou.strip().splitlines()[:1])
            hasil_salin[kunci] = tujuan

        a, b = hasil_salin['a'], hasil_salin['b']
        for folder, nama in ekspektasi.items():
            baru_nama = sorted(n for n in nama if n not in [x + e for x in LAMA_PROPS for e in ('.png', '.json')])
            # folder keluaran skrip hanya berisi yang dipasang oleh skrip (kotak surat lama bukan keluaran skrip)
            isi_a = berkas_aset(os.path.join(a, folder))
            isi_b = berkas_aset(os.path.join(b, folder))
            periksa(isi_a == baru_nama, '--salin menghasilkan tepat daftar D-1 di %s: %s' % (folder, isi_a))
            periksa(isi_a == isi_b, 'daftar --salin sama antar dua jalan di %s' % folder)
            for n in baru_nama:
                pa, pb = os.path.join(a, folder, n), os.path.join(b, folder, n)
                if not (os.path.isfile(pa) and os.path.isfile(pb)):
                    periksa(False, 'berkas hasil --salin ada: %s/%s' % (folder, n))
                    continue
                if n.endswith('.png'):
                    periksa(piksel(pa) == piksel(pb), 'deterministik (piksel sama dua kali jalan): %s/%s' % (folder, n))
                else:
                    periksa(baca(pa) == baca(pb), 'deterministik (JSON byte sama dua kali jalan): %s/%s' % (folder, n))
                repo = os.path.join(SPRITES, folder, n)
                if not os.path.isfile(repo):
                    periksa(False, 'berkas ada di assets/sprites/%s: %s' % (folder, n))
                    continue
                if n.endswith('.png'):
                    periksa(piksel(repo) == piksel(pa), 'assets/sprites/%s/%s piksel-identik dengan keluaran skrip (bukan salinan tangan)' % (folder, n))
                else:
                    periksa(baca(repo) == baca(pa), 'assets/sprites/%s/%s byte-identik dengan keluaran skrip' % (folder, n))

    # ---- isi folder repo persis daftar D-1
    for folder, nama in ekspektasi.items():
        isi = berkas_aset(os.path.join(SPRITES, folder))
        periksa(isi == nama, 'assets/sprites/%s hanya berisi daftar D-1 (+ kotak surat lama): %s' % (folder, isi))

    # ---- tidak ada aset yang tidak dipasang di assets/
    semua = []
    for dirpath, _, files in os.walk(os.path.join(ROOT, 'assets')):
        semua += [n for n in files if not n.endswith(('.import', '.uid'))]
    asing = [n for n in semua if n.startswith(TIDAK_DIPASANG)]
    periksa(asing == [], 'aset gelombang 1 yang belum dipasang tidak ada di assets/: %s' % asing)
    asing = [n for n in semua if re.match(r'tile_perumahan_.*(_masuk|_simbol)\.png$', n) or re.match(r'tile_perumahan_(aspal|rumput)_[2-9]\.png$', n)
             or n in ('tile_perumahan_aspal_1.png',)]
    periksa(asing == [], 'ubin varian, masuk, simbol tidak ada di assets/: %s' % asing)

    # ---- JSON konsisten dengan PNG
    for folder in ('props', 'vfx'):
        for n in PASANG_SPRITE[folder]:
            png = os.path.join(SPRITES, folder, n + '.png')
            js = os.path.join(SPRITES, folder, n + '.json')
            if not (os.path.isfile(png) and os.path.isfile(js)):
                periksa(False, 'PNG dan JSON ada: %s/%s' % (folder, n))
                continue
            m = json.loads(baca(js))
            lebar, tinggi = ukuran(png)
            cw, ch = m['cell']
            periksa(m['sprite'] == n + '.png', 'JSON %s menunjuk PNG sendiri' % n)
            periksa((lebar, tinggi) == (cw * m['frames'], ch), 'JSON %s: sel x frame = ukuran PNG (%s x %d vs %s)' % (n, m['cell'], m['frames'], (lebar, tinggi)))
            ax, ay = m['ground_anchor']
            if n != 'prop_koran_kotak_surat':
                periksa(0 <= ax < cw and 0 <= ay < ch, 'JSON %s: titik pijak di dalam sel' % n)
            periksa(lebar < 2048 and tinggi < 2048, 'ukuran < 2048: %s' % n)
    meta = json.loads(baca(os.path.join(SPRITES, 'tiles', 'perumahan', 'tile_perumahan.json')))
    periksa(meta['tile'] == [64, 32] and meta['ground_anchor'] == [32, 16], 'JSON ubin: 64x32, titik pijak (32, 16)')
    periksa(meta['tiles'] == sorted('tile_perumahan_%s.png' % n for n in PASANG_UBIN + UBIN_TAMBAHAN), 'JSON ubin hanya memuat ubin yang dipasang: %s' % meta['tiles'])
    periksa(sorted(meta['kolom_x_ubin']) == sorted(PASANG_UBIN), 'JSON ubin: kolom_x_ubin = enam kolom')
    periksa(meta['kolom_x_ubin'] == {'rumput_seberang': -2.5, 'trotoar_seberang': -1.5, 'aspal_seberang': -0.5, 'aspal_dekat': 0.5,
                                      'trotoar_dekat': 1.5, 'rumput_dekat': 2.5}, 'JSON ubin: pusat kolom -2,5 .. 2,5 ubin')
    for n in PASANG_UBIN + UBIN_TAMBAHAN:
        jalur = os.path.join(SPRITES, 'tiles', 'perumahan', 'tile_perumahan_%s.png' % n)
        periksa(os.path.isfile(jalur) and ukuran(jalur) == (64, 32), 'ubin %s ukuran 64x32' % n)

    # ---- impor Godot (AC-3)
    png_baru = []
    for folder in ('props', 'vfx'):
        png_baru += [os.path.join(SPRITES, folder, n + '.png') for n in PASANG_SPRITE[folder]]
    png_baru += [os.path.join(SPRITES, 'tiles', 'perumahan', 'tile_perumahan_%s.png' % n) for n in PASANG_UBIN + UBIN_TAMBAHAN]
    for jalur in png_baru:
        nama = os.path.relpath(jalur, SPRITES)
        imp = jalur + '.import'
        if not os.path.isfile(imp):
            periksa(False, '.png.import ada: %s (jalankan godot --headless --import)' % nama)
            continue
        teks = open(imp, encoding='utf-8').read()
        periksa('compress/mode=0\n' in teks, '%s: impor Lossless (compress/mode=0)' % nama)
        periksa('mipmaps/generate=false\n' in teks, '%s: tanpa mipmap' % nama)
        periksa('"vram_texture": false' in teks, '%s: bukan tekstur VRAM terkompresi' % nama)
        periksa(re.search(r'^uid="uid://[a-z0-9]+"$', teks, re.M) is not None, '%s: uid tekstur ada' % nama)
    project = open(os.path.join(ROOT, 'project.godot'), encoding='utf-8').read()
    periksa('textures/canvas_textures/default_texture_filter=0' in project, 'project.godot: filter tekstur bawaan Nearest')
    periksa('2d/snap/snap_2d_transforms_to_pixel=true' in project, 'project.godot: snap_2d_transforms_to_pixel aktif')

    # ---- kontrol: satu piksel dan satu byte JSON yang diubah terdeteksi oleh pembanding yang sama
    from PIL import Image
    sumber_png = os.path.join(SPRITES, 'props', 'prop_koran_putar.png')
    with tempfile.TemporaryDirectory() as sementara:
        rusak = os.path.join(sementara, 'rusak.png')
        with Image.open(sumber_png) as g:
            g = g.convert('RGBA')
            px = g.load()
            r, gg, bb, al = px[5, 5]
            px[5, 5] = ((r + 1) % 256, gg, bb, al)
            g.save(rusak)
        periksa(piksel(rusak) != piksel(sumber_png), 'kontrol: pembanding piksel mendeteksi satu piksel berbeda')
        js = bytearray(baca(os.path.join(SPRITES, 'props', 'prop_koran_putar.json')))
        js[10] ^= 0x01
        periksa(bytes(js) != baca(os.path.join(SPRITES, 'props', 'prop_koran_putar.json')), 'kontrol: pembanding byte mendeteksi satu byte JSON berbeda')

    print('uji_aset_pasang_gelombang1: %d lolos, %d gagal' % (lolos, gagal))
    return 1 if gagal else 0


if __name__ == '__main__':
    sys.exit(main())
