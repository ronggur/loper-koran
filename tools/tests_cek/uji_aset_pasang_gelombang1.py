#!/usr/bin/env python3
"""Uji pemasangan aset gelombang 1 Fase 5 (run fase5a-pasang-aset-gelombang1, AC-2 dan AC-3; pola `uji_aset_kucing.py`):

1. `tools/env_art/gelombang1/render.py --salin` dan `tools/env_art/ubin_perumahan.py --salin` deterministik: dua kali jalan = piksel RGBA sama
   dan JSON byte-identik (tujuan dialihkan ke folder sementara lewat ENV_ART_SALIN_KE; folder repo tidak disentuh).
2. Isi `assets/sprites/props/`, `vfx/`, `houses/perumahan/`, `tiles/perumahan/` piksel-identik (PNG) dan byte-identik (JSON) dengan keluaran skrip,
   dan berkas aset di folder itu HANYA daftar D-1 (run 5A: 13 sprite gelombang 1 + 7 ubin + JSON ubin terpangkas; run 5B: lima tembok, tong sampah logam,
   tiga pohon, dua lampu, `rumput_2/3`, empat ubin khusus), ditambah berkas lama (kotak surat, rumah perumahan). Tidak ada aset gelombang 1 yang belum
   dipasang (tong sampah biru, jejak, mangkuk, portal, pos, percikan, polisi tidur, zebra, genangan, `aspal_N`, `*_dekat_masuk`) di assets/.
   Catatan run 5B: pohon dan lampu dikeluarkan `tools/env_art/lampu_pohon.py --salin` (diuji `uji_aset_lampu_pohon.py` dan `uji_aset_pasang_5b.py`),
   jadi hanya dicek ada di repo di sini, bukan dibangkitkan ulang.
3. JSON konsisten: sel x jumlah frame = ukuran PNG, titik pijak di dalam sel (kecuali tumpangan kotak surat), ubin 64x32 pijak (32, 16),
   `tile_perumahan.json` hanya memuat ubin yang dipasang dan `tiles` = berkas PNG di folder.
4. Impor (AC-3): tiap PNG baru punya `.png.import` dengan `compress/mode=0` (Lossless) dan `mipmaps/generate=false`, ukuran < 2048, `.uid`
   ada, dan `project.godot` menggambar tekstur Nearest (`default_texture_filter=0`) dengan `snap_2d_transforms_to_pixel`.
5. Susunan ubin (AC-6, sisi Python): potongan 8 ubin maju x 8 kolom (-3,5 .. +3,5 ubin, memuat kedua kolom rumput luar `rumput_1`) yang disusun
   dari berkas PNG di assets/ piksel-identik dengan adegan renderer pada piksel yang dicakup ubin (tanpa celah dan tanpa pita tepi), dan sama
   dengan referensi `tests/data/ubin_potongan_8_maju.png` yang dibandingkan susunan scene Godot oleh `tests/tes_ubin.gd`. `--perbarui-referensi`
   menulis ulang berkas referensi itu dari assets/ (hasil skrip, tidak diedit tangan).
6. Kontrol: satu piksel dan satu byte JSON yang diubah terdeteksi.

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
UBIN_TAMBAHAN = ['rumput_1', 'rumput_2', 'rumput_3']    # D-2 run 5A (rumput_1) dan D-1 run 5B (rumput_2, rumput_3): rumput polos kolom luar
UBIN_KHUSUS = ['trotoar_seberang_masuk', 'rumput_seberang_masuk', 'trotoar_seberang_simbol', 'trotoar_dekat_simbol']   # D-1 run 5B
# Run fase5c-animasi-simpang (D-2): dua ujung kerb jalan masuk seberang dan 18 ubin simpang sisi dekat, ditulis eksplisit.
UBIN_5C = ['trotoar_seberang_masuk_ujung', 'rumput_seberang_masuk_ujung'] + ['simpang_dekat_%s' % n for n in (
    'trotoar_dekat_depan_2', 'rumput_dekat_depan_2', 'lengan_depan_2', 'aspal_dekat_depan_1', 'trotoar_dekat_depan_1', 'rumput_dekat_depan_1', 'lengan_depan_1',
    'aspal_dekat_mulut_1', 'trotoar_dekat_mulut_1', 'rumput_dekat_mulut_1', 'lengan_mulut_1', 'aspal_dekat_mulut_2', 'trotoar_dekat_mulut_2', 'rumput_dekat_mulut_2',
    'lengan_mulut_2', 'trotoar_dekat_belakang_1', 'rumput_dekat_belakang_1', 'lengan_belakang_1')]
UBIN_5C += ['simpang_seberang_%s' % n for n in (
    'rumput_seberang_depan_2', 'lengan_depan_2', 'trotoar_seberang_depan_1', 'rumput_seberang_depan_1', 'lengan_depan_1', 'aspal_seberang_mulut_1', 'trotoar_seberang_mulut_1', 'rumput_seberang_mulut_1',
    'lengan_mulut_1', 'aspal_seberang_mulut_2', 'trotoar_seberang_mulut_2', 'rumput_seberang_mulut_2', 'lengan_mulut_2', 'trotoar_seberang_belakang_1', 'rumput_seberang_belakang_1', 'lengan_belakang_1')]   # putusan P-6 run 5C
# Run 5B (D-1): keluaran tambahan render.py --salin (isi pasangan 5A di atas tidak berubah) dan keluaran lampu_pohon.py --salin.
PASANG_SPRITE_5B = {
    'houses/perumahan': ['house_tembok_polos', 'house_tembok_bata', 'house_tembok_besi', 'house_tembok_pot', 'house_tembok_tiang'],
    'props': ['prop_tong_sampah_logam'],
}
PASANG_LAMPU_POHON = ['prop_pohon_rindang', 'prop_pohon_glodokan', 'prop_pohon_ketapang', 'prop_lampu_lengan_seberang', 'prop_lampu_lengan_dekat']
TIDAK_DIPASANG = ('prop_tong_sampah_biru', 'mission_jejak', 'mission_mangkuk', 'prop_portal', 'prop_pos', 'vfx_percikan',
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


REFERENSI = os.path.join(ROOT, 'tests', 'data', 'ubin_potongan_8_maju.png')
KOLOM_REFERENSI = range(-4, 4)      # indeks kolom ic: pusat x = ic + 0,5 ubin (-3,5 .. +3,5)
BARIS_REFERENSI = range(0, 8)       # 8 ubin maju: pusat y = -maju


def nama_ubin_kolom(ic):
    """Ubin yang dipasang di kolom ic (pusat x = ic + 0,5 ubin), ditulis eksplisit: enam kolom + rumput polos di luar kolom rumput pertama."""
    x = ic + 0.5
    if abs(x) >= 3:
        return 'rumput_1'
    return {-3: 'rumput_seberang', -2: 'trotoar_seberang', -1: 'aspal_seberang', 0: 'aspal_dekat', 1: 'trotoar_dekat', 2: 'rumput_dekat'}[ic]


def susun_referensi():
    """Susun ubin dari assets/ ke satu gambar RGBA: tiap ubin 64x32 di pusat layar ((x - y) * 32, (x + y) * 16), y = -maju. Kembali (rgba, (kiri, atas))."""
    import numpy as np
    from PIL import Image
    letak = []
    for m in BARIS_REFERENSI:
        for ic in KOLOM_REFERENSI:
            sx = int((ic + 0.5 + m) * 32)
            sy = int((ic + 0.5 - m) * 16)
            jalur = os.path.join(SPRITES, 'tiles', 'perumahan', 'tile_perumahan_%s.png' % nama_ubin_kolom(ic))
            with Image.open(jalur) as g:
                letak.append((sx - 32, sy - 16, np.array(g.convert('RGBA'))))
    kiri = min(l[0] for l in letak)
    atas = min(l[1] for l in letak)
    lebar = max(l[0] for l in letak) + 64 - kiri
    tinggi = max(l[1] for l in letak) + 32 - atas
    kanvas = np.zeros((tinggi, lebar, 4), np.uint8)
    for x, y, a in letak:
        tembus = a[..., 3] == 255
        ruang = kanvas[y - atas:y - atas + 32, x - kiri:x - kiri + 64]
        ruang[tembus] = a[tembus]
    return kanvas, (kiri, atas)


def uji_susunan(periksa):
    import numpy as np
    from PIL import Image
    kanvas, (kiri, atas) = susun_referensi()
    # (a) susunan dari berkas = adegan renderer pada piksel yang dicakup ubin (translasi tiap 1 ubin dan rumput_1 menyambung)
    sys.path.insert(0, os.path.join(ROOT, 'tools', 'env_art'))
    os.environ.setdefault('ENV_ART_OUT', tempfile.mkdtemp())
    import ubin_perumahan as UP
    adegan, _ = UP.render_adegan(lambda s: UP.build_jalan(s))
    ox, oy = UP.OX, UP.OY
    tinggi, lebar = kanvas.shape[:2]
    potong = adegan[atas + oy:atas + oy + tinggi, kiri + ox:kiri + ox + lebar]
    periksa(potong.shape[:2] == kanvas.shape[:2], 'potongan adegan seukuran susunan (%s vs %s)' % (potong.shape, kanvas.shape))
    tertutup = kanvas[..., 3] == 255
    beda = int((potong[..., :3][tertutup].astype(int) != kanvas[..., :3][tertutup].astype(int)).any(axis=1).sum())
    periksa(beda == 0, 'susunan ubin dari assets/ = adegan renderer: %d piksel beda dari %d (celah atau pita tepi)' % (beda, int(tertutup.sum())))
    # (b) tanpa celah: setiap piksel yang titik tanahnya jatuh di dalam persegi dunia yang dicakup (x -4..4, y -7,5..0,5 ubin) tertutup ubin
    py, px = np.mgrid[0:tinggi, 0:lebar]
    sx, sy = px + 0.5 + kiri, py + 0.5 + atas
    gx = (sy / 16 + sx / 32) / 2
    gy = (sy / 16 - sx / 32) / 2
    dalam = (gx > -4 + 0.01) & (gx < 4 - 0.01) & (gy > -7.5 + 0.01) & (gy < 0.5 - 0.01)
    celah = int((dalam & ~tertutup).sum())
    periksa(int(dalam.sum()) > 10000 and celah == 0, 'tanpa celah transparan di dalam persegi yang dicakup ubin (%d piksel dicek, %d celah)' % (int(dalam.sum()), celah))
    # (c) referensi tests/data = susunan dari assets/ (dibandingkan scene Godot di tests/tes_ubin.gd)
    if '--perbarui-referensi' in sys.argv:
        os.makedirs(os.path.dirname(REFERENSI), exist_ok=True)
        Image.fromarray(kanvas, 'RGBA').save(REFERENSI)
    if os.path.isfile(REFERENSI):
        with Image.open(REFERENSI) as g:
            ref = np.array(g.convert('RGBA'))
        periksa(ref.shape == kanvas.shape and bool((ref == kanvas).all()), 'tests/data/ubin_potongan_8_maju.png = susunan dari assets/ (jalankan --perbarui-referensi)')
    else:
        periksa(False, 'berkas referensi tidak ada: tests/data/ubin_potongan_8_maju.png (jalankan dengan --perbarui-referensi)')
    # (d) kontrol: satu piksel referensi yang diubah terdeteksi
    rusak = kanvas.copy()
    y, x = np.argwhere(tertutup)[len(np.argwhere(tertutup)) // 2]
    rusak[y, x, 0] ^= 1
    periksa(not (rusak == kanvas).all(), 'kontrol: pembanding susunan mendeteksi satu piksel berbeda')


def ekspektasi_skrip():
    """{folder relatif: [nama berkas]} keluaran render.py --salin dan ubin_perumahan.py --salin (ditulis eksplisit, bukan dari skrip)."""
    props = sorted(n + e for n in PASANG_SPRITE['props'] + PASANG_SPRITE_5B['props'] for e in ('.png', '.json'))
    vfx = sorted(n + e for n in PASANG_SPRITE['vfx'] for e in ('.png', '.json'))
    rumah = sorted(n + e for n in PASANG_SPRITE_5B['houses/perumahan'] for e in ('.png', '.json'))
    ubin = sorted(['tile_perumahan_%s.png' % n for n in PASANG_UBIN + UBIN_TAMBAHAN + UBIN_KHUSUS + UBIN_5C] + ['tile_perumahan.json'])
    return {'props': props, 'vfx': vfx, os.path.join('houses', 'perumahan'): rumah, os.path.join('tiles', 'perumahan'): ubin}


def ekspektasi_repo():
    """{folder relatif: [nama berkas aset]} yang harus ada di assets/sprites sesuai D-1 (ditulis eksplisit, bukan dari skrip)."""
    hasil = ekspektasi_skrip()
    hasil['props'] = sorted(hasil['props'] + [n + e for n in LAMA_PROPS + PASANG_LAMPU_POHON for e in ('.png', '.json')])
    rumah_lama = sorted(n for n in berkas_aset(os.path.join(SPRITES, 'houses', 'perumahan')) if n.startswith('house_perumahan_'))
    hasil[os.path.join('houses', 'perumahan')] = sorted(hasil[os.path.join('houses', 'perumahan')] + rumah_lama)
    return hasil


def main():
    try:
        import numpy  # noqa: F401
        import PIL  # noqa: F401
    except ImportError as galat:
        print('numpy dan pillow dibutuhkan untuk uji ini:', galat)
        return 2

    ekspektasi = ekspektasi_skrip()
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
            baru_nama = sorted(nama)
            # folder keluaran skrip hanya berisi yang dipasang oleh skrip (kotak surat dan rumah lama bukan keluaran skrip)
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
    for folder, nama in ekspektasi_repo().items():
        isi = berkas_aset(os.path.join(SPRITES, folder))
        periksa(isi == nama, 'assets/sprites/%s hanya berisi daftar D-1 (+ kotak surat lama): %s' % (folder, isi))

    # ---- tidak ada aset yang tidak dipasang di assets/
    semua = []
    for dirpath, _, files in os.walk(os.path.join(ROOT, 'assets')):
        semua += [n for n in files if not n.endswith(('.import', '.uid'))]
    asing = [n for n in semua if n.startswith(TIDAK_DIPASANG)]
    periksa(asing == [], 'aset gelombang 1 yang belum dipasang tidak ada di assets/: %s' % asing)
    asing = [n for n in semua if re.match(r'tile_perumahan_.*_dekat_masuk\.png$', n) or re.match(r'tile_perumahan_aspal_[0-9]\.png$', n)
             or re.match(r'tile_perumahan_rumput_([04-9])\.png$', n)]
    periksa(asing == [], 'ubin yang belum dipasang (aspal_N, *_dekat_masuk, rumput_4+) tidak ada di assets/: %s' % asing)

    # ---- JSON konsisten dengan PNG
    daftar_json = [(f, n) for f in ('props', 'vfx') for n in PASANG_SPRITE[f]] + [(f, n) for f, ns in PASANG_SPRITE_5B.items() for n in ns]
    for folder, n in daftar_json:
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
    periksa(meta['tiles'] == sorted('tile_perumahan_%s.png' % n for n in PASANG_UBIN + UBIN_TAMBAHAN + UBIN_KHUSUS + UBIN_5C), 'JSON ubin hanya memuat ubin yang dipasang: %s' % meta['tiles'])
    periksa(sorted(meta['kolom_x_ubin']) == sorted(PASANG_UBIN), 'JSON ubin: kolom_x_ubin = enam kolom')
    periksa(meta['kolom_x_ubin'] == {'rumput_seberang': -2.5, 'trotoar_seberang': -1.5, 'aspal_seberang': -0.5, 'aspal_dekat': 0.5,
                                      'trotoar_dekat': 1.5, 'rumput_dekat': 2.5}, 'JSON ubin: pusat kolom -2,5 .. 2,5 ubin')
    for n in PASANG_UBIN + UBIN_TAMBAHAN + UBIN_KHUSUS + UBIN_5C:
        jalur = os.path.join(SPRITES, 'tiles', 'perumahan', 'tile_perumahan_%s.png' % n)
        periksa(os.path.isfile(jalur) and ukuran(jalur) == (64, 32), 'ubin %s ukuran 64x32' % n)

    # ---- impor Godot (AC-3)
    png_baru = [os.path.join(SPRITES, f, n + '.png') for f, n in daftar_json]
    png_baru += [os.path.join(SPRITES, 'props', n + '.png') for n in PASANG_LAMPU_POHON]
    png_baru += [os.path.join(SPRITES, 'tiles', 'perumahan', 'tile_perumahan_%s.png' % n) for n in PASANG_UBIN + UBIN_TAMBAHAN + UBIN_KHUSUS + UBIN_5C]
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

    # ---- susunan ubin (AC-6)
    uji_susunan(periksa)

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
