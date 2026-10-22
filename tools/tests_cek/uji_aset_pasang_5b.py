#!/usr/bin/env python3
"""Uji pemasangan aset run fase5b-tembok-dekor (AC-1 dan AC-3; pola `uji_aset_pasang_gelombang1.py`):

1. `tools/env_art/gelombang1/render.py --salin`, `tools/env_art/lampu_pohon.py --salin`, dan `tools/env_art/ubin_perumahan.py --salin` deterministik:
   dua kali jalan = piksel RGBA sama dan JSON byte-identik (tujuan dialihkan lewat ENV_ART_SALIN_KE; folder repo tidak disentuh).
2. Isi `assets/sprites/{houses/perumahan,props,tiles/perumahan}/` piksel-identik (PNG) dan byte-identik (JSON) dengan keluaran skrip untuk semua aset
   baru D-1 (lima tembok, tong sampah logam, tiga pohon, dua lampu mati, enam ubin: `trotoar_seberang_masuk`, `rumput_seberang_masuk`,
   `trotoar_seberang_simbol`, `trotoar_dekat_simbol`, `rumput_2`, `rumput_3`), dan isi folder itu persis daftar D-1 ditambah isi 5A dan berkas lama
   (daftar ditulis eksplisit di sini). Tidak ada aset yang tidak dipasang (tong biru, pohon dan lampu jenis lain, bingkai nyala, `aspal_N`,
   `*_dekat_masuk`, polisi tidur, zebra, genangan, jejak, mangkuk, portal, pos, percikan).
3. Isi pasangan 5A, kotak surat lama, dan rumah perumahan lama BYTE-identik dengan golden (`golden_aset_5b.json`, sha256 dihitung dari berkas
   sebelum run, commit d102d61): 61 berkas.
4. JSON: tembok sel 46x46 pijak (41, 25), tong sampah 20x30 pijak (10, 25), pohon dan lampu `cell` = ukuran PNG, ubin 64x32 pijak (32, 16);
   `tile_perumahan.json` hanya memuat ubin yang dipasang, `tiles` = berkas PNG di folder, `ubin_khusus` dan `ubin_polos_luar` benar.
5. Impor (AC-3): tiap PNG baru punya `.png.import` dengan `compress/mode=0` (Lossless), `mipmaps/generate=false`, bukan tekstur VRAM, uid ada,
   ukuran < 2048, dan `project.godot` menggambar tekstur Nearest.
6. Kontrol: satu piksel, satu byte JSON, dan satu byte golden yang diubah terdeteksi.
7. Ubin khusus (bagian C, AC-16, sisi Python): susunan dari berkas assets/ untuk potongan 8 ubin maju x 8 kolom yang memuat jalan masuk garasi (baris 4), simbol sepeda (baris 6), dan
   `rumput_2`/`rumput_3` di kolom luar (pilihan ditulis ulang di sini lewat `struct` dan FNV-1a, oracle terpisah dari `UbinKhusus`) disamakan dengan adegan renderer: simbol sepeda
   = adegan (0 piksel beda); jalan masuk = adegan di sisi seberang, 0 piksel beda (run fase5c: ubin ujung kerb `*_masuk_ujung` di baris maju + 1 menutup C-F1; kontrol:
   tanpa ubin ujung tepat 22 piksel beda di baris itu, angka lama run 5B);
   `rumput_2`/`rumput_3` diulang = adegan rumput polos dan tepi cincinnya hanya memuat warna rumput. `tests/data/ubin_potongan_5b.png` = susunan itu dari assets/ (dibandingkan
   scene Godot oleh `tests/tes_ubin_5b.gd`; `--perbarui-referensi` menulis ulang berkas dari assets/, bukan diedit tangan).

Butuh numpy dan pillow (seperti `tools/env_art`); bila tidak ada, uji berhenti dengan exit code 2 (CI memasangnya).

Cara pakai (dari root repo):
    python3 tools/tests_cek/uji_aset_pasang_5b.py

Exit code: 0 lolos semua, 1 ada yang gagal, 2 numpy/pillow tidak terpasang.
"""
import hashlib
import json
import os
import re
import struct
import subprocess
import sys
import tempfile

FOLDER = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(FOLDER, '..', '..'))
SKRIP_SPRITE = os.path.join(ROOT, 'tools', 'env_art', 'gelombang1', 'render.py')
SKRIP_LAMPU_POHON = os.path.join(ROOT, 'tools', 'env_art', 'lampu_pohon.py')
SKRIP_UBIN = os.path.join(ROOT, 'tools', 'env_art', 'ubin_perumahan.py')
SPRITES = os.path.join(ROOT, 'assets', 'sprites')
GOLDEN = os.path.join(FOLDER, 'golden_aset_5b.json')

# Daftar D-1 run 5B (ditulis eksplisit, bukan dari skrip). Nilai: (sel lebar, sel tinggi, pijak x, pijak y, jumlah frame).
TEMBOK = {'house_tembok_polos': (46, 46, 41, 25, 1), 'house_tembok_bata': (46, 46, 41, 25, 1), 'house_tembok_besi': (46, 46, 41, 25, 1),
          'house_tembok_pot': (46, 46, 41, 25, 1), 'house_tembok_tiang': (46, 46, 41, 25, 1)}
TONG = {'prop_tong_sampah_logam': (20, 30, 10, 25, 1)}
POHON = ['prop_pohon_rindang', 'prop_pohon_glodokan', 'prop_pohon_ketapang']
LAMPU = ['prop_lampu_lengan_seberang', 'prop_lampu_lengan_dekat']
UBIN_BARU = ['trotoar_seberang_masuk', 'rumput_seberang_masuk', 'trotoar_seberang_simbol', 'trotoar_dekat_simbol', 'rumput_2', 'rumput_3']
UBIN_5A = ['rumput_seberang', 'trotoar_seberang', 'aspal_seberang', 'aspal_dekat', 'trotoar_dekat', 'rumput_dekat', 'rumput_1']
PROPS_5A = ['prop_koran_putar', 'prop_koran_bayangan', 'prop_koran_teras', 'prop_koran_rumput', 'prop_koran_kotak_surat', 'prop_koran_terlipat']
PROPS_LAMA = ['prop_kotak_surat', 'prop_kotak_surat_bukan']
VFX_5A = ['vfx_debu_roda', 'vfx_garis_kecepatan_a', 'vfx_garis_kecepatan_b', 'vfx_garis_kecepatan_c', 'vfx_bintang_kena', 'vfx_koin_tip', 'mission_kilau']
RUMAH_LAMA = ['house_perumahan_%s' % n for n in (
    'dekat_limasan_bukan', 'dekat_limasan_pelanggan', 'dekat_pelana_lintang_bukan', 'dekat_pelana_lintang_pelanggan',
    'dekat_pelana_sejajar_bukan', 'dekat_pelana_sejajar_pelanggan', 'limasan_bukan', 'limasan_pelanggan', 'pelana_bukan', 'pelana_pelanggan',
    'sayap_bukan', 'sayap_pelanggan')]
# Nama (awalan) yang TIDAK boleh ada di assets/ (tidak dipasang, D-1 dan D-4).
TIDAK_DIPASANG_REGEX = [
    r'^prop_tong_sampah_biru', r'^prop_pohon_(?!rindang\.|glodokan\.|ketapang\.)', r'^prop_lampu_(?!lengan_seberang\.|lengan_dekat\.)', r'nyala',
    r'^tile_perumahan_aspal_[0-9]\.', r'^tile_perumahan_.*_dekat_masuk\.', r'^tile_perumahan_rumput_([04-9])\.', r'polisi', r'zebra', r'genangan',
    r'^mission_jejak', r'^mission_mangkuk', r'^prop_portal', r'^prop_pos', r'^vfx_percikan',
]

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


def sha(b):
    return hashlib.sha256(b).hexdigest()


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


def pasang(nama):
    return [n + e for n in nama for e in ('.png', '.json')]


def ekspektasi_repo():
    """{folder relatif: [berkas aset]} persis isi assets/sprites untuk tiga folder run 5B (ditulis eksplisit)."""
    return {
        'houses/perumahan': sorted(pasang(RUMAH_LAMA) + pasang(TEMBOK)),
        'props': sorted(pasang(PROPS_5A + PROPS_LAMA + list(TONG) + POHON + LAMPU)),
        'tiles/perumahan': sorted(['tile_perumahan_%s.png' % n for n in UBIN_5A + UBIN_BARU + UBIN_5C] + ['tile_perumahan.json']),
    }


# ---------------------------------------------------------------- ubin khusus (bagian C, AC-16) ----
REFERENSI_5B = os.path.join(ROOT, 'tests', 'data', 'ubin_potongan_5b.png')
BARIS_5B = range(0, 8)          # 8 ubin maju (pusat y = -maju); lebih banyak keluar dari adegan renderer (768 x 448)
KOLOM_5B = range(-4, 4)         # indeks kolom ic: pusat x = ic + 0,5 ubin (-3,5 .. +3,5)
MASUK_5B = {4}                  # baris jalan masuk garasi di potongan
SIMBOL_5B = {6}                 # baris simbol sepeda di potongan (baris mutlak 6 + 12 k)
UJUNG_KERB_MASUK = 22           # kontrol: piksel beda di baris tetangga (maju + 1) di tepi jalan masuk TANPA ubin ujung kerb (C-F1 run 5B)
# Run fase5c-animasi-simpang (C-F1, simpang T sisi dekat; D-2): ubin baru yang dipasang, ditulis eksplisit.
UBIN_UJUNG = ['trotoar_seberang_masuk_ujung', 'rumput_seberang_masuk_ujung']
UBIN_SIMPANG_DEKAT = ['simpang_dekat_%s' % n for n in (
    'trotoar_dekat_depan_2', 'rumput_dekat_depan_2', 'lengan_depan_2', 'aspal_dekat_depan_1', 'trotoar_dekat_depan_1', 'rumput_dekat_depan_1', 'lengan_depan_1',
    'aspal_dekat_mulut_1', 'trotoar_dekat_mulut_1', 'rumput_dekat_mulut_1', 'lengan_mulut_1', 'aspal_dekat_mulut_2', 'trotoar_dekat_mulut_2', 'rumput_dekat_mulut_2',
    'lengan_mulut_2', 'trotoar_dekat_belakang_1', 'rumput_dekat_belakang_1', 'lengan_belakang_1')]
UBIN_5C = UBIN_UJUNG + UBIN_SIMPANG_DEKAT


def fnv_dua_int(a, b):
    """FNV-1a 32 bit atas dua bilangan bulat 32 bit little-endian (oracle terpisah dari UbinKhusus: struct, bukan geser bit)."""
    h = 0x811C9DC5
    for byte in struct.pack('<ii', a, b):
        h = ((h ^ byte) * 0x01000193) & 0xFFFFFFFF
    return h


def nama_ubin_khusus(ic, m, masuk, simbol, varian=True, ujung=True):
    """Ubin di kolom ic (pusat x = ic + 0,5) baris mutlak m: ditulis eksplisit per kolom (oracle D-7; ujung kerb run 5C di baris m bila m - 1 jalan masuk)."""
    uj = ujung and (m - 1) in masuk and m not in masuk
    if abs(ic + 0.5) >= 3:
        if not varian:
            return 'rumput_1'
        v = fnv_dua_int(ic, m) % 100
        return 'rumput_2' if v < 12 else ('rumput_3' if v < 20 else 'rumput_1')
    if ic == -3:
        if uj:
            return 'rumput_seberang_masuk_ujung'
        return 'rumput_seberang_masuk' if m in masuk else 'rumput_seberang'
    if ic == -2:
        if uj:
            return 'trotoar_seberang_masuk_ujung'
        return 'trotoar_seberang_masuk' if m in masuk else ('trotoar_seberang_simbol' if m in simbol else 'trotoar_seberang')
    if ic == -1:
        return 'aspal_seberang'
    if ic == 0:
        return 'aspal_dekat'
    if ic == 1:
        return 'trotoar_dekat_simbol' if (m in simbol and m not in masuk) else 'trotoar_dekat'
    return 'rumput_dekat'


def susun_nama(fn_nama):
    """Susun ubin dari assets/ menurut fn_nama(ic, m) untuk baris BARIS_5B dan kolom KOLOM_5B. Kembali (rgba, (kiri, atas))."""
    import numpy as np
    from PIL import Image
    letak = []
    for m in BARIS_5B:
        for ic in KOLOM_5B:
            sx = int((ic + 0.5 + m) * 32)
            sy = int((ic + 0.5 - m) * 16)
            jalur = os.path.join(SPRITES, 'tiles', 'perumahan', 'tile_perumahan_%s.png' % fn_nama(ic, m))
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


def uji_ubin_khusus():
    import numpy as np
    from PIL import Image
    sys.path.insert(0, os.path.join(ROOT, 'tools', 'env_art'))
    os.environ.setdefault('ENV_ART_OUT', tempfile.mkdtemp())
    import ubin_perumahan as UP
    ox, oy = UP.OX, UP.OY
    U = UP.U

    # (a) oracle pemilihan: jumlah dan jenis varian di potongan (kolom luar -4 dan 3), tanpa kolom rumput pertama diganti
    varian = [(ic, m, nama_ubin_khusus(ic, m, set(), set())) for ic in (-4, 3) for m in BARIS_5B]
    periksa(any(v[2] == 'rumput_2' for v in varian) and any(v[2] == 'rumput_3' for v in varian), 'potongan 8 ubin memuat rumput_2 dan rumput_3 (%s)' % [v for v in varian if v[2] != 'rumput_1'])
    periksa(all(nama_ubin_khusus(ic, m, set(), set()) == n for ic, n in ((-3, 'rumput_seberang'), (2, 'rumput_dekat')) for m in range(-60, 60)), 'kolom rumput pertama tidak pernah diganti variasi')

    # (b) simbol sepeda: susunan = adegan (tanpa celah dan tanpa tepi)
    adegan_s, _ = UP.render_adegan(lambda s: UP.build_jalan(s, simbol=-6 * U))
    kanvas_s, (kiri, atas) = susun_nama(lambda ic, m: nama_ubin_khusus(ic, m, set(), SIMBOL_5B, varian=False))
    tinggi, lebar = kanvas_s.shape[:2]
    potong_s = adegan_s[atas + oy:atas + oy + tinggi, kiri + ox:kiri + ox + lebar]
    tertutup = kanvas_s[..., 3] == 255
    beda_s = int((potong_s[..., :3][tertutup].astype(int) != kanvas_s[..., :3][tertutup].astype(int)).any(axis=1).sum())
    periksa(beda_s == 0, 'ubin simbol sepeda menyambung: susunan = adegan renderer, %d piksel beda dari %d' % (beda_s, int(tertutup.sum())))

    # (c) jalan masuk garasi: sisi seberang = adegan (run 5C: ubin ujung kerb); kontrol tanpa ubin ujung = 22 piksel ujung kerb di baris tetangga (maju + 1)
    adegan_m, _ = UP.render_adegan(lambda s: UP.build_jalan(s, masuk=(-4 * U - 16.0, -4 * U + 16.0)))
    kanvas_u, _ = susun_nama(lambda ic, m: nama_ubin_khusus(ic, m, MASUK_5B, set(), varian=False))
    kanvas_m, (kiri, atas) = susun_nama(lambda ic, m: nama_ubin_khusus(ic, m, MASUK_5B, set(), varian=False, ujung=False))
    tinggi, lebar = kanvas_m.shape[:2]
    potong_m = adegan_m[atas + oy:atas + oy + tinggi, kiri + ox:kiri + ox + lebar]
    tertutup = kanvas_m[..., 3] == 255
    py, px = np.mgrid[0:tinggi, 0:lebar]
    sx, sy = px + 0.5 + kiri, py + 0.5 + atas
    gx = (sy / 16.0 + sx / 32.0) / 2.0          # x dunia, ubin
    gy = (sy / 16.0 - sx / 32.0) / 2.0          # y dunia = -maju
    beda_px = (potong_m[..., :3].astype(int) != kanvas_m[..., :3].astype(int)).any(axis=2) & tertutup
    seberang = beda_px & (gx < 0)
    periksa(int(seberang.sum()) == UJUNG_KERB_MASUK, 'kontrol tanpa ubin ujung: jalan masuk seberang tepat %d piksel beda dari adegan (ujung kerb C-F1), dapat %d' % (UJUNG_KERB_MASUK, int(seberang.sum())))
    maju_beda = sorted({int(round(-gy[y, x])) for y, x in zip(*np.nonzero(seberang))})
    periksa(maju_beda == [5], 'kontrol: piksel beda hanya di baris tetangga maju 5 (di depan jalan masuk di baris 4): %s' % maju_beda)
    periksa(bool(((gx[seberang] > -2.1) & (gx[seberang] < -1.0)).all()), 'kontrol: piksel beda hanya di sekitar kedua kerb (x antara -2,1 dan -1,0): ujung kerb dalam dan luar')
    beda_u = (potong_m[..., :3].astype(int) != kanvas_u[..., :3].astype(int)).any(axis=2) & (kanvas_u[..., 3] == 255)
    periksa(int((beda_u & (gx < 0)).sum()) == 0, 'jalan masuk seberang dengan ubin ujung kerb (run 5C) = adegan renderer: %d piksel beda (C-F1 = 0)' % int((beda_u & (gx < 0)).sum()))
    periksa(int((kanvas_u[..., 3] == 255).sum()) == int(tertutup.sum()), 'susunan dengan ujung kerb menutup piksel yang sama (tanpa celah)')
    # sisi dekat berbeda karena adegan menggambar jalan masuk di kedua sisi (ubin *_dekat_masuk tidak dipasang, D-1): kontrol bahwa pembanding mendeteksi perbedaan
    periksa(int((beda_px & (gx > 0)).sum()) > 0, 'kontrol: pembanding mendeteksi beda di sisi dekat (jalan masuk dekat tidak dipasang)')

    # (d) rumput_2 dan rumput_3 diulang = adegan rumput polos (tanpa pita tepi) dan tepi hanya berwarna rumput
    rumput1 = np.array(Image.open(os.path.join(SPRITES, 'tiles', 'perumahan', 'tile_perumahan_rumput_1.png')).convert('RGBA'))
    for v, nama in ((1, 'rumput_2'), (2, 'rumput_3')):
        adegan_v, _ = UP.render_adegan(lambda s, v=v: s.add(UP.ground_prim(lambda x, y, v=v: UP._polos(x, y, v), UP.MATS)))
        tile = np.array(Image.open(os.path.join(SPRITES, 'tiles', 'perumahan', 'tile_perumahan_%s.png' % nama)).convert('RGBA'))
        kanvas = np.zeros((UP.H_ADEGAN, UP.W_ADEGAN, 4), np.uint8)
        for m in range(0, 4):
            for ic in range(4, 8):
                X = int((ic + 0.5 + m) * 32) - 32 + ox
                Y = int((ic + 0.5 - m) * 16) - 16 + oy
                t = tile[..., 3] == 255
                ruang = kanvas[Y:Y + 32, X:X + 64]
                ruang[t] = tile[t]
        tertutup_v = kanvas[..., 3] == 255
        beda_v = int((adegan_v[..., :3][tertutup_v].astype(int) != kanvas[..., :3][tertutup_v].astype(int)).any(axis=1).sum())
        periksa(int(tertutup_v.sum()) > 10000 and beda_v == 0, '%s diulang = adegan rumput polos: %d piksel beda dari %d (pita atau tepi)' % (nama, beda_v, int(tertutup_v.sum())))
        # cincin tepi belah ketupat (piksel opak yang punya tetangga 4 arah transparan) hanya berwarna rumput: himpunan warna sudah ada di rumput_1 atau di dalam ubin itu
        opak = tile[..., 3] == 255
        dalam = opak.copy()
        dalam[1:, :] &= opak[:-1, :]; dalam[:-1, :] &= opak[1:, :]; dalam[:, 1:] &= opak[:, :-1]; dalam[:, :-1] &= opak[:, 1:]
        cincin = opak & ~dalam
        warna = lambda a, mask: {tuple(c) for c in a[..., :3][mask]}
        periksa(int(cincin.sum()) > 100 and warna(tile, cincin) <= warna(rumput1, rumput1[..., 3] == 255) | warna(tile, dalam),
                '%s: warna cincin tepi hanya warna rumput (tanpa garis tepi kerb), %d piksel cincin' % (nama, int(cincin.sum())))

    # (e) referensi tests/data = susunan dari assets/ untuk potongan campuran (masuk, simbol, rumput_2 dan _3); dibandingkan scene Godot di tests/tes_ubin_5b.gd
    kanvas_r, _ = susun_nama(lambda ic, m: nama_ubin_khusus(ic, m, MASUK_5B, SIMBOL_5B))
    if '--perbarui-referensi' in sys.argv:
        os.makedirs(os.path.dirname(REFERENSI_5B), exist_ok=True)
        Image.fromarray(kanvas_r, 'RGBA').save(REFERENSI_5B)
    if os.path.isfile(REFERENSI_5B):
        with Image.open(REFERENSI_5B) as g:
            ref = np.array(g.convert('RGBA'))
        periksa(ref.shape == kanvas_r.shape and bool((ref == kanvas_r).all()), 'tests/data/ubin_potongan_5b.png = susunan dari assets/ (jalankan --perbarui-referensi)')
    else:
        periksa(False, 'berkas referensi tidak ada: tests/data/ubin_potongan_5b.png (jalankan dengan --perbarui-referensi)')
    rusak = kanvas_r.copy()
    y, x = np.argwhere(kanvas_r[..., 3] == 255)[len(np.argwhere(kanvas_r[..., 3] == 255)) // 2]
    rusak[y, x, 0] ^= 1
    periksa(not (rusak == kanvas_r).all(), 'kontrol: pembanding susunan ubin khusus mendeteksi satu piksel berbeda')


def main():
    try:
        import numpy  # noqa: F401
        import PIL  # noqa: F401
    except ImportError as galat:
        print('numpy dan pillow dibutuhkan untuk uji ini:', galat)
        return 2

    golden = json.load(open(GOLDEN, encoding='utf-8'))['pasangan_5a']
    ekspektasi = ekspektasi_repo()
    baru = {  # keluaran skrip untuk aset baru: folder -> nama (tanpa ekstensi)
        'houses/perumahan': list(TEMBOK),
        'props': list(TONG) + POHON + LAMPU,
    }

    with tempfile.TemporaryDirectory() as sementara:
        hasil = {}
        for kunci in ('a', 'b'):
            out = os.path.join(sementara, 'out_' + kunci)
            tujuan = os.path.join(sementara, 'salin_' + kunci)
            os.makedirs(os.path.join(tujuan, 'tiles', 'perumahan'))
            ks, os_ = jalankan(SKRIP_SPRITE, out, tujuan)
            ku, ou = jalankan(SKRIP_UBIN, out, os.path.join(tujuan, 'tiles', 'perumahan'))
            kl, ol = jalankan(SKRIP_LAMPU_POHON, out, os.path.join(tujuan, 'props'))
            periksa(ks == 0, 'render.py --salin berhasil (%s): %s' % (kunci, os_.strip()[-200:]))
            periksa(ku == 0, 'ubin_perumahan.py --salin berhasil (%s): %s' % (kunci, ou.strip()[-200:]))
            periksa(kl == 0, 'lampu_pohon.py --salin berhasil (%s): %s' % (kunci, ol.strip()[-200:]))
            periksa('beda sambungan: 0' in ou, 'ubin_perumahan.py: ubin menyambung, beda sambungan = 0')
            periksa('beda sambungan masuk seberang: 0' in ou, 'ubin_perumahan.py: jalan masuk seberang dengan ujung kerb menyambung, beda = 0 (C-F1)')
            hasil[kunci] = tujuan

        a, b = hasil['a'], hasil['b']
        # isi keluaran skrip: persis aset baru + isi 5A (tanpa kotak surat dan rumah lama, bukan keluaran skrip)
        harap_keluaran = {
            'houses/perumahan': sorted(pasang(TEMBOK)),
            'props': sorted(pasang(PROPS_5A + list(TONG) + POHON + LAMPU)),
            'vfx': sorted(pasang(VFX_5A)),
            'tiles/perumahan': ekspektasi['tiles/perumahan'],
        }
        for folder, nama in harap_keluaran.items():
            isi_a, isi_b = berkas_aset(os.path.join(a, folder)), berkas_aset(os.path.join(b, folder))
            periksa(isi_a == nama, '--salin menghasilkan tepat daftar D-1 di %s: %s' % (folder, isi_a))
            periksa(isi_a == isi_b, 'daftar --salin sama antar dua jalan di %s' % folder)
            for n in nama:
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

    # ---- isi folder repo persis daftar D-1 + 5A + lama
    for folder, nama in ekspektasi.items():
        isi = berkas_aset(os.path.join(SPRITES, folder))
        periksa(isi == nama, 'assets/sprites/%s hanya berisi daftar D-1, isi 5A, dan berkas lama: %s' % (folder, sorted(set(isi) ^ set(nama))))
    isi_vfx = berkas_aset(os.path.join(SPRITES, 'vfx'))
    periksa(isi_vfx == sorted(pasang(VFX_5A)), 'assets/sprites/vfx tidak berubah (isi 5A saja): %s' % isi_vfx)

    # ---- tidak ada aset yang tidak dipasang di assets/
    semua = []
    for dirpath, _, files in os.walk(os.path.join(ROOT, 'assets')):
        semua += [n for n in files if not n.endswith(('.import', '.uid'))]
    periksa(len(semua) > 100, 'pemindai assets/ membaca banyak berkas (%d)' % len(semua))
    for pola in TIDAK_DIPASANG_REGEX:
        asing = [n for n in semua if re.search(pola, n)]
        periksa(asing == [], 'aset yang tidak dipasang tidak ada di assets/ (%s): %s' % (pola, asing))

    # ---- golden 5A: byte-identik
    for jalur, harapan in golden.items():
        repo = os.path.join(SPRITES, jalur)
        periksa(os.path.isfile(repo) and sha(baca(repo)) == harapan, 'isi 5A/lama byte-identik dengan golden: %s' % jalur)
    periksa(len(golden) == 61, 'golden memuat 61 berkas (dapat %d)' % len(golden))

    # ---- JSON konsisten
    spesifik = dict(TEMBOK)
    spesifik.update(TONG)
    for nama, (cw, ch, ax, ay, frames) in spesifik.items():
        folder = 'houses/perumahan' if nama.startswith('house_') else 'props'
        png, js = os.path.join(SPRITES, folder, nama + '.png'), os.path.join(SPRITES, folder, nama + '.json')
        if not (os.path.isfile(png) and os.path.isfile(js)):
            periksa(False, 'PNG dan JSON ada: %s' % nama)
            continue
        m = json.loads(baca(js))
        periksa(m['sprite'] == nama + '.png' and m['cell'] == [cw, ch] and m['ground_anchor'] == [ax, ay] and m['frames'] == frames,
                '%s: JSON sel %sx%s pijak (%s, %s) %d frame (dapat %s %s %s)' % (nama, cw, ch, ax, ay, frames, m['cell'], m['ground_anchor'], m['frames']))
        periksa(ukuran(png) == (cw * frames, ch), '%s: ukuran PNG = sel x frame' % nama)
    for nama in POHON + LAMPU:
        png, js = os.path.join(SPRITES, 'props', nama + '.png'), os.path.join(SPRITES, 'props', nama + '.json')
        if not (os.path.isfile(png) and os.path.isfile(js)):
            periksa(False, 'PNG dan JSON ada: %s' % nama)
            continue
        m = json.loads(baca(js))
        lebar, tinggi = ukuran(png)
        periksa(m['sprite'] == nama + '.png' and m['cell'] == [lebar, tinggi] and m['frames'] == 1, '%s: JSON sel = ukuran PNG, satu frame' % nama)
        ax, ay = m['ground_anchor']
        periksa(0 <= ax < lebar and 0 <= ay < tinggi and lebar < 2048 and tinggi < 2048, '%s: pijak di dalam gambar, ukuran < 2048' % nama)
    meta = json.loads(baca(os.path.join(SPRITES, 'tiles', 'perumahan', 'tile_perumahan.json')))
    periksa(meta['tile'] == [64, 32] and meta['ground_anchor'] == [32, 16], 'JSON ubin: 64x32, titik pijak (32, 16)')
    periksa(meta['tiles'] == sorted('tile_perumahan_%s.png' % n for n in UBIN_5A + UBIN_BARU + UBIN_5C), 'JSON ubin hanya memuat ubin yang dipasang: %s' % meta['tiles'])
    periksa(meta['ubin_ujung_kerb'] == UBIN_UJUNG and meta['ujung_kerb_baris_relatif'] == 1, 'JSON ubin: ujung kerb = %s baris relatif %s' % (meta['ubin_ujung_kerb'], meta['ujung_kerb_baris_relatif']))
    periksa(meta['ubin_khusus'] == UBIN_BARU[:4], 'JSON ubin: ubin_khusus = %s' % meta['ubin_khusus'])
    periksa(meta['ubin_polos_luar'] == ['rumput_1', 'rumput_2', 'rumput_3'], 'JSON ubin: ubin_polos_luar = %s' % meta['ubin_polos_luar'])
    periksa(meta['kolom_x_ubin'] == {'rumput_seberang': -2.5, 'trotoar_seberang': -1.5, 'aspal_seberang': -0.5, 'aspal_dekat': 0.5,
                                      'trotoar_dekat': 1.5, 'rumput_dekat': 2.5}, 'JSON ubin: pusat kolom -2,5 .. 2,5 ubin')
    for n in UBIN_5A + UBIN_BARU + UBIN_5C:
        jalur = os.path.join(SPRITES, 'tiles', 'perumahan', 'tile_perumahan_%s.png' % n)
        periksa(os.path.isfile(jalur) and ukuran(jalur) == (64, 32), 'ubin %s ukuran 64x32' % n)

    # ---- impor Godot (AC-3)
    png_baru = [os.path.join(SPRITES, 'houses', 'perumahan', n + '.png') for n in TEMBOK]
    png_baru += [os.path.join(SPRITES, 'props', n + '.png') for n in list(TONG) + POHON + LAMPU]
    png_baru += [os.path.join(SPRITES, 'tiles', 'perumahan', 'tile_perumahan_%s.png' % n) for n in UBIN_BARU + UBIN_5C]
    periksa(len(png_baru) == 37, '37 PNG baru (17 run 5B + 20 run 5C; dapat %d)' % len(png_baru))
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
        lebar, tinggi = ukuran(jalur)
        periksa(lebar < 2048 and tinggi < 2048, '%s: ukuran < 2048' % nama)
    project = open(os.path.join(ROOT, 'project.godot'), encoding='utf-8').read()
    periksa('textures/canvas_textures/default_texture_filter=0' in project, 'project.godot: filter tekstur bawaan Nearest')
    periksa('2d/snap/snap_2d_transforms_to_pixel=true' in project, 'project.godot: snap_2d_transforms_to_pixel aktif')

    # ---- kontrol: satu piksel, satu byte JSON, satu byte golden yang diubah terdeteksi
    from PIL import Image
    sumber_png = os.path.join(SPRITES, 'houses', 'perumahan', 'house_tembok_bata.png')
    with tempfile.TemporaryDirectory() as sementara:
        rusak = os.path.join(sementara, 'rusak.png')
        with Image.open(sumber_png) as g:
            g = g.convert('RGBA')
            px = g.load()
            titik = next((x, y) for y in range(g.height) for x in range(g.width) if px[x, y][3] == 255)
            r, gg, bb, al = px[titik]
            px[titik] = ((r + 1) % 256, gg, bb, al)
            g.save(rusak)
        periksa(piksel(rusak) != piksel(sumber_png), 'kontrol: pembanding piksel mendeteksi satu piksel berbeda')
        js = bytearray(baca(os.path.join(SPRITES, 'props', 'prop_tong_sampah_logam.json')))
        js[10] ^= 0x01
        periksa(bytes(js) != baca(os.path.join(SPRITES, 'props', 'prop_tong_sampah_logam.json')), 'kontrol: pembanding byte mendeteksi satu byte JSON berbeda')
        isi = bytearray(baca(os.path.join(SPRITES, 'props', 'prop_koran_putar.png')))
        isi[len(isi) // 2] ^= 0x01
        periksa(sha(bytes(isi)) != golden['props/prop_koran_putar.png'], 'kontrol: golden mendeteksi satu byte PNG 5A berbeda')
    periksa(any(re.search(r'^prop_pohon_(?!rindang\.|glodokan\.|ketapang\.)', n) for n in ['prop_pohon_beringin.png']), 'kontrol: pohon jenis lain terdeteksi')
    periksa(any(re.search(r'nyala', n) for n in ['prop_lampu_lengan_seberang_nyala.png']), 'kontrol: bingkai nyala terdeteksi')

    uji_ubin_khusus()

    print('uji_aset_pasang_5b: %d lolos, %d gagal' % (lolos, gagal))
    return 1 if gagal else 0


if __name__ == '__main__':
    sys.exit(main())
