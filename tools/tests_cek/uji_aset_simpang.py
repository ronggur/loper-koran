#!/usr/bin/env python3
"""Uji ubin simpang T hiasan dan ujung kerb run fase5c-animasi-simpang (AC-12, AC-14, AC-18, AC-19; D-2, D-3):

1. `tools/env_art/ubin_perumahan.py --salin` deterministik untuk ubin simpang dan ujung kerb: dua kali jalan = piksel RGBA sama, JSON byte sama
   (tujuan dialihkan lewat ENV_ART_SALIN_KE dan ENV_ART_OUT; folder repo tidak disentuh), dan isi `assets/sprites/tiles/perumahan/` = keluaran itu.
2. Hanya ubin yang dipakai yang dipasang (D-2): 18 ubin simpang sisi `dekat` (daftar ditulis eksplisit di sini), tidak ada ubin simpang sisi `seberang`
   (data segmen belum memakainya), tidak ada `aspal_N` atau `*_dekat_masuk`.
3. Konstanta `scripts/config.gd` (dibaca dari baris literal, bukan lewat Godot) = JSON renderer: lebar mulut, tepi mulut, pita baris, tabel sel kedua sisi
   (`RUTE_SIMPANG_SEL_SEBERANG` dibandingkan JSON lengkap di build), baris ujung kerb. Tabel sel juga = tabel literal di sini.
4. Susunan (AC-19, oracle terpisah dari kode game): ubin dari assets/ (sisi dekat) dan dari build/ (sisi seberang, tidak dipasang) disusun dengan pemilihan
   yang ditulis ulang di sini (pita, kolom, lengan berulang ke luar sampai kolom terjauh) = adegan renderer `build_simpang` piksel-identik pada 12 kolom
   x 9 baris (mulut, sudut, dan lengan tiga kolom ke luar); tanpa celah transparan. Kontrol: lengan berhenti satu kolom terlalu awal, ubin simpang di baris
   salah, dan sisi salah terdeteksi.
5. Referensi `tests/data/ubin_potongan_simpang.png` = susunan potongan rute dengan simpang dekat di baris 3 dan variasi rumput (FNV-1a, `struct`) dari assets/;
   dibandingkan scene Godot oleh `tests/tes_simpang.gd`. `--perbarui-referensi` menulis ulang berkas dari assets/ (bukan diedit tangan).
6. Impor: tiap PNG baru `.png.import` Lossless, tanpa mipmap, bukan tekstur VRAM, uid ada.

Butuh numpy dan pillow; bila tidak ada, exit code 2. Exit code: 0 lolos, 1 ada yang gagal.

    python3 tools/tests_cek/uji_aset_simpang.py [--perbarui-referensi]
"""
import json
import os
import re
import struct
import subprocess
import sys
import tempfile

FOLDER = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(FOLDER, '..', '..'))
SKRIP_UBIN = os.path.join(ROOT, 'tools', 'env_art', 'ubin_perumahan.py')
UBIN = os.path.join(ROOT, 'assets', 'sprites', 'tiles', 'perumahan')
CONFIG = os.path.join(ROOT, 'scripts', 'config.gd')
REFERENSI = os.path.join(ROOT, 'tests', 'data', 'ubin_potongan_simpang.png')

# Tabel sel literal (baris relatif maju dari `pos`, kolom: 0 aspal, 1 trotoar, 2 rumput pertama, 3 lengan), urut ekspor renderer.
SEL_DEKAT = [(3, 1), (3, 2), (3, 3), (2, 0), (2, 1), (2, 2), (2, 3), (1, 0), (1, 1), (1, 2), (1, 3), (0, 0), (0, 1), (0, 2), (0, 3), (-1, 1), (-1, 2), (-1, 3)]
SEL_SEBERANG = [(3, 2), (3, 3), (2, 1), (2, 2), (2, 3), (1, 0), (1, 1), (1, 2), (1, 3), (0, 0), (0, 1), (0, 2), (0, 3), (-1, 1), (-1, 2), (-1, 3)]
NAMA_BARIS = {3: 'depan_2', 2: 'depan_1', 1: 'mulut_1', 0: 'mulut_2', -1: 'belakang_1'}
NAMA_KOLOM = {0: 'aspal_%s', 1: 'trotoar_%s', 2: 'rumput_%s', 3: 'lengan'}
PITA = (-1, 3)


def nama_sel(sisi, rel, kol):
    k = NAMA_KOLOM[kol] % sisi if kol < 3 else 'lengan'
    return 'simpang_%s_%s_%s' % (sisi, k, NAMA_BARIS[rel])


UBIN_SIMPANG_DEKAT = [nama_sel('dekat', r, k) for r, k in SEL_DEKAT]
UBIN_UJUNG = ['trotoar_seberang_masuk_ujung', 'rumput_seberang_masuk_ujung']

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


def rgba(jalur):
    import numpy as np
    from PIL import Image
    with Image.open(jalur) as g:
        return np.array(g.convert('RGBA'))


def config_literal(nama):
    """Nilai konstanta `nama` dari baris literal config.gd (satu baris, rule balancing)."""
    for baris in open(CONFIG, encoding='utf-8'):
        m = re.match(r'^const %s: [^=]+= (.+)$' % nama, baris.strip())
        if m:
            return json.loads(m.group(1))
    raise KeyError(nama)


def pasangan(datar):
    return [(datar[i], datar[i + 1]) for i in range(0, len(datar), 2)]


def fnv_dua_int(a, b):
    h = 0x811C9DC5
    for byte in struct.pack('<ii', a, b):
        h = ((h ^ byte) * 0x01000193) & 0xFFFFFFFF
    return h


def nama_lurus(ic, m, varian):
    """Ubin jalan lurus di kolom ic (pusat x = ic + 0,5) baris m (tanpa jalan masuk). `varian` = potongan rute: variasi rumput luar dan simbol sepeda
    (kedua trotoar, baris 6 + 12 k), seperti `UbinKhusus` run 5B, ditulis ulang di sini."""
    if varian and ic in (-2, 1) and (m - 6) % 12 == 0:
        return 'trotoar_seberang_simbol' if ic == -2 else 'trotoar_dekat_simbol'
    if abs(ic + 0.5) >= 3:
        if not varian:
            return 'rumput_1'
        v = fnv_dua_int(ic, m) % 100
        return 'rumput_2' if v < 12 else ('rumput_3' if v < 20 else 'rumput_1')
    return {-3: 'rumput_seberang', -2: 'trotoar_seberang', -1: 'aspal_seberang', 0: 'aspal_dekat', 1: 'trotoar_dekat', 2: 'rumput_dekat'}[ic]


def nama_sel_rute(ic, m, simpang, varian=True, lengan_sampai=None, geser_baris=0):
    """Oracle pemilihan: simpang = {baris pos: sisi}. Ubin simpang di baris pos-1..pos+3, hanya sisi simpang, kolom dari ic; lengan untuk semua |x| >= 3
    (atau sampai `lengan_sampai` kolom, kontrol); sel yang tidak ada di tabel = jalan lurus."""
    for pos, sisi in simpang.items():
        rel = m - pos + geser_baris
        if PITA[0] <= rel <= PITA[1] and (ic >= 0) == (sisi == 'dekat'):
            jauh = ic if ic >= 0 else -ic - 1      # 0 aspal, 1 trotoar, 2 rumput pertama, >= 3 lengan
            kol = min(jauh, 3)
            if kol == 3 and lengan_sampai is not None and jauh > lengan_sampai:
                break
            tabel = SEL_DEKAT if sisi == 'dekat' else SEL_SEBERANG
            if (rel, kol) in tabel:
                return nama_sel(sisi, rel, kol)
    return nama_lurus(ic, m, varian)


def susun(fn_nama, baris, kolom, folder_ubin):
    """Susun ubin per (ic, m) menjadi satu gambar: pusat layar ((ic + 0,5 + m) * 32, (ic + 0,5 - m) * 16). Kembali (rgba, (kiri, atas))."""
    import numpy as np
    letak = []
    for m in baris:
        for ic in kolom:
            nm = fn_nama(ic, m)
            jalur = os.path.join(folder_ubin(nm), 'tile_perumahan_%s.png' % nm)
            letak.append((int((ic + 0.5 + m) * 32) - 32, int((ic + 0.5 - m) * 16) - 16, rgba(jalur)))
    kiri = min(l[0] for l in letak)
    atas = min(l[1] for l in letak)
    kanvas = np.zeros((max(l[1] for l in letak) + 32 - atas, max(l[0] for l in letak) + 64 - kiri, 4), np.uint8)
    for x, y, a in letak:
        t = a[..., 3] == 255
        kanvas[y - atas:y - atas + 32, x - kiri:x - kiri + 64][t] = a[t]
    return kanvas, (kiri, atas)


def jalankan(keluaran, salin_ke):
    env = dict(os.environ, ENV_ART_OUT=keluaran, ENV_ART_SALIN_KE=salin_ke)
    h = subprocess.run([sys.executable, SKRIP_UBIN, '--salin'], capture_output=True, text=True, env=env, cwd=ROOT)
    return h.returncode, h.stdout + h.stderr


def main():
    try:
        import numpy as np
        from PIL import Image
    except ImportError as galat:
        print('numpy dan pillow dibutuhkan untuk uji ini:', galat)
        return 2

    sementara = tempfile.mkdtemp()
    hasil = {}
    for kunci in ('a', 'b'):
        out, tujuan = os.path.join(sementara, 'out_' + kunci), os.path.join(sementara, 'salin_' + kunci)
        kode, teks = jalankan(out, tujuan)
        periksa(kode == 0, 'ubin_perumahan.py --salin berhasil (%s): %s' % (kunci, teks.strip()[-200:]))
        periksa('beda sambungan simpang: 0' in teks and 'beda sambungan masuk seberang: 0' in teks, 'renderer: cek_simpang = 0 dan jalan masuk dengan ujung kerb = 0 (%s)' % kunci)
        hasil[kunci] = (out, tujuan)
    (out_a, sal_a), (out_b, sal_b) = hasil['a'], hasil['b']
    os.environ['ENV_ART_OUT'] = out_a
    sys.path.insert(0, os.path.join(ROOT, 'tools', 'env_art'))
    import ubin_perumahan as UP

    # ---- 1-2. deterministik, isi assets/ = keluaran, hanya yang dipakai
    baru = UBIN_SIMPANG_DEKAT + UBIN_UJUNG
    for nm in baru:
        f = 'tile_perumahan_%s.png' % nm
        pa, pb, repo = os.path.join(sal_a, f), os.path.join(sal_b, f), os.path.join(UBIN, f)
        if not (os.path.isfile(pa) and os.path.isfile(pb) and os.path.isfile(repo)):
            periksa(False, 'berkas ada di keluaran dan assets/: %s' % f)
            continue
        periksa((rgba(pa) == rgba(pb)).all(), 'deterministik (piksel sama dua kali jalan): %s' % f)
        periksa((rgba(repo) == rgba(pa)).all(), 'assets/ piksel-identik dengan keluaran skrip: %s' % f)
        periksa(rgba(repo).shape == (32, 64, 4) and int((rgba(repo)[..., 3] == 255).sum()) == 1024, '%s: 64x32, belah ketupat 1.024 piksel opak' % f)
    periksa(baca(os.path.join(sal_a, 'tile_perumahan.json')) == baca(os.path.join(sal_b, 'tile_perumahan.json')) == baca(os.path.join(UBIN, 'tile_perumahan.json')),
            'tile_perumahan.json byte-identik: dua kali jalan dan assets/')
    isi = sorted(n for n in os.listdir(UBIN) if n.startswith('tile_perumahan_simpang_') and n.endswith('.png'))
    periksa(isi == sorted('tile_perumahan_%s.png' % n for n in UBIN_SIMPANG_DEKAT), 'assets/ hanya memuat 18 ubin simpang dekat (D-2): %s' % sorted(set(isi) ^ {'tile_perumahan_%s.png' % n for n in UBIN_SIMPANG_DEKAT}))
    periksa(not any('simpang_seberang' in n for n in os.listdir(UBIN)), 'tidak ada ubin simpang seberang di assets/ (belum dipakai data)')
    periksa(not any(re.search(r'^tile_perumahan_(aspal_[0-9]|.*_dekat_masuk)', n) for n in os.listdir(UBIN)), 'tidak ada aspal_N atau *_dekat_masuk di assets/')
    lengkap = json.loads(baca(os.path.join(out_a, 'ubin', 'simpang', 'tile_perumahan_simpang.json')))
    nama_build = {d['file'][len('tile_perumahan_'):-4] for l in lengkap['sisi'].values() for d in l}
    periksa(len(nama_build) == 34 and set(UBIN_SIMPANG_DEKAT) < nama_build, 'renderer mengekspor 34 ubin simpang (18 dekat + 16 seberang), hanya yang dekat disalin')

    # ---- 3. config = JSON renderer = tabel literal
    meta = json.loads(baca(os.path.join(UBIN, 'tile_perumahan.json')))
    sp = meta['simpang']
    periksa(sp['y_mulut_unit'] == [-48.0, 16.0] and list(UP.SIMPANG_Y) == [-48.0, 16.0], 'JSON: y mulut renderer -48 .. 16 unit')
    periksa(config_literal('RUTE_SIMPANG_LEBAR_MULUT_UBIN') == sp['lebar_mulut_ubin'] == 2.0, 'RUTE_SIMPANG_LEBAR_MULUT_UBIN = JSON lebar_mulut_ubin = 2,0')
    periksa(config_literal('RUTE_SIMPANG_MULUT_AWAL_UBIN') == -sp['y_mulut_unit'][1] / 32.0 == -0.5, 'RUTE_SIMPANG_MULUT_AWAL_UBIN = -y_mulut[1] / 32 = -0,5')
    periksa(config_literal('RUTE_SIMPANG_PITA_BARIS') == sp['pita_baris_relatif'] == list(PITA), 'RUTE_SIMPANG_PITA_BARIS = JSON pita = [-1, 3]')
    periksa(config_literal('RUTE_SETENGAH_BARIS_UBIN') == 0.5, 'RUTE_SETENGAH_BARIS_UBIN = 0,5 (setengah ubin 32 unit)')
    periksa(config_literal('RUTE_UJUNG_KERB_BARIS_RELATIF') == meta['ujung_kerb_baris_relatif'] == 1, 'RUTE_UJUNG_KERB_BARIS_RELATIF = JSON = 1')
    kol = {'aspal': 0, 'trotoar': 1, 'rumput': 2, 'lengan': 3}
    dari_json = [(d['baris_relatif'], kol[d['kolom']]) for d in sp['sisi']['dekat']]
    periksa(pasangan(config_literal('RUTE_SIMPANG_SEL_DEKAT')) == dari_json == SEL_DEKAT, 'RUTE_SIMPANG_SEL_DEKAT = JSON terpasang = tabel literal')
    periksa([d['nama'] for d in sp['sisi']['dekat']] == UBIN_SIMPANG_DEKAT, 'urutan nama ubin simpang dekat di JSON = urutan tabel sel')
    kol_x = {0.5: 0, 1.5: 1, 2.5: 2, 3.5: 3}
    seb_build = [(-d['baris_y_ubin'], kol_x[abs(d['kolom_x_ubin'])]) for d in lengkap['sisi']['seberang']]
    periksa(pasangan(config_literal('RUTE_SIMPANG_SEL_SEBERANG')) == seb_build == SEL_SEBERANG, 'RUTE_SIMPANG_SEL_SEBERANG = JSON renderer lengkap (build) = tabel literal')
    pita_build = sorted({-d['baris_y_ubin'] for l in lengkap['sisi'].values() for d in l if abs(d['kolom_x_ubin']) >= 1.5})
    periksa([pita_build[0], pita_build[-1]] == list(PITA), 'pita = baris pertama dan terakhir yang diganti di kolom trotoar, rumput, lengan (kedua sisi): %s' % pita_build)

    # ---- 4. susunan = adegan renderer (varian mati), kedua sisi
    def folder_ubin(nm):
        return UBIN if os.path.isfile(os.path.join(UBIN, 'tile_perumahan_%s.png' % nm)) else os.path.join(out_a, 'ubin', 'simpang')
    baris_uji, kolom_uji = range(-4, 5), range(-6, 6)
    for sg, sisi in ((1, 'dekat'), (-1, 'seberang')):
        adegan, _ = UP.render_adegan(lambda s, sg=sg: UP.build_simpang(s, sg))
        kanvas, (kiri, atas) = susun(lambda ic, m: nama_sel_rute(ic, m, {0: sisi}, varian=False), baris_uji, kolom_uji, folder_ubin)
        t, l = kanvas.shape[:2]
        potong = adegan[atas + UP.OY:atas + UP.OY + t, kiri + UP.OX:kiri + UP.OX + l]
        tertutup = kanvas[..., 3] == 255
        beda = int(((potong[..., :3].astype(int) != kanvas[..., :3].astype(int)).any(axis=2) & tertutup).sum())
        periksa(int(tertutup.sum()) > 50000 and beda == 0, 'simpang %s: susunan 12 kolom x 9 baris = adegan renderer, %d piksel beda dari %d' % (sisi, beda, int(tertutup.sum())))
        # tanpa celah di dalam persegi dunia yang dicakup (x -6..6, y -4,5..4,5 ubin)
        py, px = np.mgrid[0:t, 0:l]
        sx, sy = px + 0.5 + kiri, py + 0.5 + atas
        gx, gy = (sy / 16.0 + sx / 32.0) / 2.0, (sy / 16.0 - sx / 32.0) / 2.0
        dalam = (gx > -5.95) & (gx < 5.95) & (gy > -4.45) & (gy < 4.45)
        periksa(int((dalam & ~tertutup).sum()) == 0, 'simpang %s: tanpa celah transparan (%d piksel dicek)' % (sisi, int(dalam.sum())))
        # kontrol: lengan berhenti satu kolom terlalu awal, simpang di baris salah, sisi salah
        for label, fn in (('lengan berhenti di kolom ke-4', lambda ic, m: nama_sel_rute(ic, m, {0: sisi}, False, lengan_sampai=4)),
                          ('simpang bergeser satu baris', lambda ic, m: nama_sel_rute(ic, m, {0: sisi}, False, geser_baris=1)),
                          ('simpang di sisi lain', lambda ic, m: nama_sel_rute(ic, m, {0: 'seberang' if sisi == 'dekat' else 'dekat'}, False))):
            k2, _ = susun(fn, baris_uji, kolom_uji, folder_ubin)
            beda2 = int(((potong[..., :3].astype(int) != k2[..., :3].astype(int)).any(axis=2) & (k2[..., 3] == 255)).sum())
            periksa(beda2 > 0, 'kontrol simpang %s: %s terdeteksi (%d piksel beda)' % (sisi, label, beda2))

    # ---- 5. referensi potongan rute (simpang dekat di baris 3, variasi rumput)
    kanvas_r, _ = susun(lambda ic, m: nama_sel_rute(ic, m, {3: 'dekat'}), range(0, 9), range(-5, 6), lambda nm: UBIN)
    if '--perbarui-referensi' in sys.argv:
        os.makedirs(os.path.dirname(REFERENSI), exist_ok=True)
        Image.fromarray(kanvas_r, 'RGBA').save(REFERENSI)
    if os.path.isfile(REFERENSI):
        ref = rgba(REFERENSI)
        periksa(ref.shape == kanvas_r.shape and bool((ref == kanvas_r).all()), 'tests/data/ubin_potongan_simpang.png = susunan dari assets/ (jalankan --perbarui-referensi)')
    else:
        periksa(False, 'berkas referensi tidak ada: tests/data/ubin_potongan_simpang.png (jalankan --perbarui-referensi)')
    jumlah_simpang = sum(1 for m in range(0, 9) for ic in range(-5, 6) if nama_sel_rute(ic, m, {3: 'dekat'}).startswith('simpang_'))
    periksa(jumlah_simpang == 18 + 5 * 2, 'potongan referensi memuat 28 ubin simpang (18 sel tabel + lengan berulang di kolom 4 dan 5 untuk 5 baris), dapat %d' % jumlah_simpang)
    rusak = kanvas_r.copy()
    rusak[rusak.shape[0] // 2, rusak.shape[1] // 2, 0] ^= 1
    periksa(not (rusak == kanvas_r).all(), 'kontrol: pembanding referensi mendeteksi satu piksel berbeda')

    # ---- 6. impor
    for nm in baru:
        imp = os.path.join(UBIN, 'tile_perumahan_%s.png.import' % nm)
        if not os.path.isfile(imp):
            periksa(False, '.png.import ada: %s (jalankan godot --headless --import)' % nm)
            continue
        teks = open(imp, encoding='utf-8').read()
        periksa('compress/mode=0\n' in teks and 'mipmaps/generate=false\n' in teks and '"vram_texture": false' in teks, '%s: impor Lossless, tanpa mipmap, bukan VRAM' % nm)
        periksa(re.search(r'^uid="uid://[a-z0-9]+"$', teks, re.M) is not None, '%s: uid ada' % nm)

    print('uji_aset_simpang: %d lolos, %d gagal' % (lolos, gagal))
    return 1 if gagal else 0


if __name__ == '__main__':
    sys.exit(main())
