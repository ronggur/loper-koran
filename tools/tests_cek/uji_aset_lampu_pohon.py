#!/usr/bin/env python3
"""Uji renderer pohon dan lampu `tools/env_art/lampu_pohon.py` (run fase5b-tembok-dekor, AC-2; pola `uji_aset_gelombang1.py`):

1. Deterministik: dua kali jalan `--salin` (dan tanpa argumen) = piksel RGBA sama untuk semua PNG dan byte sama untuk semua JSON.
2. Jalan tanpa argumen tetap menghasilkan keluaran lama: 38 berkas di `lampu_pohon/` sama dengan golden (`golden_aset_5b.json`, dihitung dari skrip
   sebelum run 5B), tanpa berkas baru.
3. `--salin` hanya menyalin yang dipasang (D-1, D-5): tiga pohon (rindang, glodokan, ketapang) dan dua lampu `lengan` (seberang, dekat), PNG + JSON,
   tidak ada bingkai nyala (sprite lampu satu bingkai, piksel = bingkai MATI di sheet, beda dari bingkai nyala), tidak ada jenis lain.
4. JSON: `cell` = ukuran PNG (satu bingkai), `ground_anchor` di dalam gambar, ukuran < 2048, `sprite` menunjuk PNG sendiri; titik pijak lampu
   = kaki tiang (tiang berdiri di atas pijak: kolom pijak opak tepat di atasnya dan tidak ada piksel tiang di bawah), pohon = pangkal batang.
5. Warna: setiap warna opak ada di palet induk (ART_DIRECTION 2.4; `tools/env_art/gelombang1/pxcore.py`) atau di katalog warna renderer pohon
   dan lampu (`KATALOG_RENDERER`, ditulis eksplisit dari keluaran renderer; palet pohon dan lampu MELEBIHI 2.4, dicatat di LOG run 5B, palet
   induk tidak dikunci). Semi-transparan hanya bayangan #000000 alfa 71.
6. Kontrol: satu piksel dan satu byte JSON yang diubah terdeteksi; warna di luar katalog terdeteksi.

Butuh numpy dan pillow (seperti `tools/env_art`); bila tidak ada, uji berhenti dengan exit code 2 (CI memasangnya).

Cara pakai (dari root repo):
    python3 tools/tests_cek/uji_aset_lampu_pohon.py

Exit code: 0 lolos semua, 1 ada yang gagal, 2 numpy/pillow tidak terpasang.
"""
import hashlib
import json
import os
import subprocess
import sys
import tempfile

FOLDER = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(FOLDER, '..', '..'))
SKRIP = os.path.join(ROOT, 'tools', 'env_art', 'lampu_pohon.py')
PXCORE = os.path.join(ROOT, 'tools', 'env_art', 'gelombang1')
GOLDEN = os.path.join(FOLDER, 'golden_aset_5b.json')

POHON = ['prop_pohon_rindang', 'prop_pohon_glodokan', 'prop_pohon_ketapang']
LAMPU = ['prop_lampu_lengan_seberang', 'prop_lampu_lengan_dekat']
DIPASANG = POHON + LAMPU
# Warna opak di luar palet induk yang dipakai renderer pohon dan lampu (23 warna; ramp bahan daun, batang, dan tiang di lib.py/lampu_pohon.py).
KATALOG_RENDERER = {
    '#14121F', '#152C24', '#1B322C', '#242B3B', '#24482C', '#25442F', '#254B37', '#2C1A1A', '#2E5236', '#2F553C', '#393853', '#3F6E3A',
    '#3F7A44', '#41292A', '#42496D', '#426B40', '#4B7349', '#4F8A4A', '#6C8856', '#6D4334', '#8CC860', '#9AA2B0', '#B4DC6A',
}
BAYANGAN = (0, 0, 0, 71)

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


def sidik_piksel(jalur):
    from PIL import Image
    with Image.open(jalur) as g:
        g = g.convert('RGBA')
        return '%dx%d:%s' % (g.size[0], g.size[1], hashlib.sha256(g.tobytes()).hexdigest())


def piksel(jalur):
    from PIL import Image
    with Image.open(jalur) as g:
        g = g.convert('RGBA')
        return g.size, g.tobytes()


def jalankan(keluaran, salin_ke=None):
    env = dict(os.environ, ENV_ART_OUT=keluaran)
    argumen = []
    if salin_ke is not None:
        env['ENV_ART_SALIN_KE'] = salin_ke
        argumen = ['--salin']
    h = subprocess.run([sys.executable, SKRIP, *argumen], capture_output=True, text=True, env=env, cwd=ROOT)
    return h.returncode, h.stdout + h.stderr


def hex_warna(c):
    return '#%02X%02X%02X' % tuple(c[:3])


def palet_induk():
    sys.path.insert(0, PXCORE)
    import pxcore
    boleh = set()
    for nada in pxcore.P.values():
        boleh.update(hex_warna(c) for c in nada)
    for c in pxcore.ASPAL + pxcore.TROTOAR + [pxcore.MARKA, pxcore.KERB, pxcore.OUT, pxcore.PUTIH]:
        boleh.add(hex_warna(c))
    return boleh


def warna_di_luar(a, induk, katalog):
    """Daftar warna opak `a` (RGBA numpy) yang tidak ada di induk atau katalog, ditambah semi-transparan selain bayangan."""
    opak = a[a[..., 3] == 255][:, :3]
    asing = sorted({hex_warna(c) for c in opak.tolist()} - induk - katalog)
    semi = a[(a[..., 3] > 0) & (a[..., 3] < 255)]
    asing += ['semi%s' % (tuple(c),) for c in sorted({tuple(c) for c in semi.tolist()} - {BAYANGAN})]
    return asing


def bbox_alfa(a):
    import numpy as np
    ys, xs = np.nonzero(a[..., 3])
    return int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1


def main():
    try:
        import numpy as np
        from PIL import Image
    except ImportError as galat:
        print('numpy dan pillow dibutuhkan untuk uji ini:', galat)
        return 2

    golden = json.load(open(GOLDEN, encoding='utf-8'))['lampu_pohon_lama']
    induk = palet_induk()

    with tempfile.TemporaryDirectory() as sementara:
        hasil = {}
        for kunci in ('a', 'b'):
            out = os.path.join(sementara, 'out_' + kunci)
            salin = os.path.join(sementara, 'salin_' + kunci)
            k, o = jalankan(out, salin)
            periksa(k == 0, 'lampu_pohon.py --salin berhasil (%s): %s' % (kunci, o.strip()[-200:]))
            hasil[kunci] = (out, salin)
        k, o = jalankan(os.path.join(sementara, 'out_polos'))
        periksa(k == 0, 'lampu_pohon.py tanpa argumen berhasil: %s' % o.strip()[-200:])
        folder_polos = os.path.join(sementara, 'out_polos', 'lampu_pohon')
        (out_a, salin_a), (out_b, salin_b) = hasil['a'], hasil['b']

        # ---- 1. deterministik (keluaran build/ dan hasil salin)
        for sub_a, sub_b, label in ((os.path.join(out_a, 'lampu_pohon'), os.path.join(out_b, 'lampu_pohon'), 'lampu_pohon/'), (salin_a, salin_b, 'salin')):
            na, nb = sorted(os.listdir(sub_a)), sorted(os.listdir(sub_b))
            periksa(na == nb and len(na) > 0, 'daftar berkas %s sama antar dua jalan' % label)
            for nm in na:
                pa, pb = os.path.join(sub_a, nm), os.path.join(sub_b, nm)
                if nm.endswith('.png'):
                    periksa(os.path.isfile(pb) and piksel(pa) == piksel(pb), 'deterministik (piksel): %s/%s' % (label, nm))
                else:
                    periksa(os.path.isfile(pb) and baca(pa) == baca(pb), 'deterministik (JSON byte): %s/%s' % (label, nm))

        # ---- 2. tanpa argumen = keluaran lama
        ada = sorted(os.listdir(folder_polos)) if os.path.isdir(folder_polos) else []
        periksa(ada == sorted(golden), 'tanpa argumen: daftar berkas = keluaran lama (%d berkas, dapat %d)' % (len(golden), len(ada)))
        # --salin tidak boleh mengubah keluaran build/ juga
        ada_salin_mode = sorted(os.listdir(os.path.join(out_a, 'lampu_pohon')))
        periksa(ada_salin_mode == sorted(golden), '--salin: keluaran build/ tetap daftar lama')
        for nm, harapan in golden.items():
            for label, folder in (('tanpa argumen', folder_polos), ('--salin', os.path.join(out_a, 'lampu_pohon'))):
                jalur = os.path.join(folder, nm)
                if not os.path.isfile(jalur):
                    periksa(False, '%s: berkas lama ada: %s' % (label, nm))
                    continue
                dapat = sidik_piksel(jalur) if nm.endswith('.png') else hashlib.sha256(baca(jalur)).hexdigest()
                periksa(dapat == harapan, '%s: keluaran lama tidak berubah: %s' % (label, nm))

        # ---- 3. --salin hanya yang dipasang
        harap_berkas = sorted(n + e for n in DIPASANG for e in ('.png', '.json'))
        periksa(sorted(os.listdir(salin_a)) == harap_berkas, '--salin: tepat 5 sprite (PNG + JSON): %s' % sorted(os.listdir(salin_a)))
        periksa(not any('nyala' in n for n in os.listdir(salin_a)), '--salin: tidak ada berkas nyala')
        sheet = os.path.join(folder_polos, 'prop_lampu_lengan_sheet.png')
        meta_sheet = json.loads(baca(os.path.join(folder_polos, 'prop_lampu_lengan_sheet.json')))
        periksa(meta_sheet['frames'] == ['seberang_mati', 'seberang_nyala', 'dekat_mati', 'dekat_nyala'], 'urutan bingkai sheet lampu lengan: %s' % meta_sheet['frames'])
        with Image.open(sheet) as g:
            sh = np.array(g.convert('RGBA'))
        cw, ch = meta_sheet['cell']
        ax_sh, ay_sh = meta_sheet['ground_anchor']
        for nama, indeks_mati, indeks_nyala in (('prop_lampu_lengan_seberang', 0, 1), ('prop_lampu_lengan_dekat', 2, 3)):
            with Image.open(os.path.join(salin_a, nama + '.png')) as g:
                tunggal = np.array(g.convert('RGBA'))
            meta = json.loads(baca(os.path.join(salin_a, nama + '.json')))

            def potongan(i):
                """Isi bingkai i di sheet: kotak alfa-opak, dan geseran kotak itu terhadap titik pijak sheet."""
                bf = sh[:, i * cw:(i + 1) * cw]
                x0, y0, x1, y1 = bbox_alfa(bf)
                return bf[y0:y1, x0:x1], (x0 - ax_sh, y0 - ay_sh)
            isi_tunggal = tunggal[bbox_alfa(tunggal)[1]:bbox_alfa(tunggal)[3], bbox_alfa(tunggal)[0]:bbox_alfa(tunggal)[2]]
            geser_tunggal = (bbox_alfa(tunggal)[0] - meta['ground_anchor'][0], bbox_alfa(tunggal)[1] - meta['ground_anchor'][1])
            isi_mati, geser_mati = potongan(indeks_mati)
            isi_nyala, geser_nyala = potongan(indeks_nyala)
            periksa(isi_tunggal.shape == isi_mati.shape and bool((isi_tunggal == isi_mati).all()) and geser_tunggal == geser_mati,
                    '%s: piksel dan letak terhadap pijak = bingkai MATI di sheet' % nama)
            periksa(not (isi_tunggal.shape == isi_nyala.shape and bool((isi_tunggal == isi_nyala).all())), '%s: bukan bingkai nyala' % nama)
            periksa(meta['frames'] == 1 and meta['fps'] == 0, '%s: satu bingkai' % nama)

        # ---- 4. JSON dan warna dari hasil salin
        for nama in DIPASANG:
            png = os.path.join(salin_a, nama + '.png')
            m = json.loads(baca(os.path.join(salin_a, nama + '.json')))
            with Image.open(png) as g:
                a = np.array(g.convert('RGBA'))
            h, w = a.shape[:2]
            periksa(m['sprite'] == nama + '.png', '%s: JSON menunjuk PNG sendiri' % nama)
            periksa(m['cell'] == [w, h] and m['frames'] == 1, '%s: sel = ukuran PNG (satu bingkai): %s vs %s' % (nama, m['cell'], [w, h]))
            ax, ay = m['ground_anchor']
            periksa(0 <= ax < w and 0 <= ay < h, '%s: titik pijak di dalam gambar: %s' % (nama, m['ground_anchor']))
            periksa(w < 2048 and h < 2048, '%s: ukuran < 2048' % nama)
            asing = warna_di_luar(a, induk, KATALOG_RENDERER)
            periksa(asing == [], '%s: warna hanya palet induk atau katalog renderer: %s' % (nama, asing[:5]))
            opak = a[..., 3] == 255
            periksa(int(opak.sum()) > 100, '%s: sprite tidak kosong' % nama)
            if nama.startswith('prop_lampu_'):
                # kaki tiang di pijak: piksel pijak ada isinya dan tiang menjulang ke atas, tidak ada tiang di bawah pijak
                kolom = opak[:ay + 1, ax]
                periksa(bool(kolom[ay - 2:ay + 1].any()), '%s: ada piksel opak di kaki tiang (pijak %s)' % (nama, m['ground_anchor']))
                tinggi = int(np.nonzero(opak[:, ax])[0].min()) if opak[:, ax].any() else 0
                periksa(ay - tinggi >= 40, '%s: tiang menjulang >= 40 px di atas pijak (%d)' % (nama, ay - tinggi))
            else:
                periksa(bool(opak[ay - 6:ay + 1, ax - 3:ax + 4].any()), '%s: batang di pangkal (pijak %s)' % (nama, m['ground_anchor']))

        # ---- 6. kontrol
        a0 = np.zeros((4, 4, 4), np.uint8)
        a0[1, 1] = (0x8C, 0xC8, 0x60, 255)
        periksa(warna_di_luar(a0, induk, KATALOG_RENDERER) == [], 'kontrol: warna katalog diterima')
        a0[2, 2] = (1, 2, 3, 255)
        periksa(warna_di_luar(a0, induk, KATALOG_RENDERER) == ['#010203'], 'kontrol: warna di luar katalog terdeteksi')
        a0[3, 3] = (0, 0, 0, 100)
        periksa(len(warna_di_luar(a0, induk, KATALOG_RENDERER)) == 2, 'kontrol: semi-transparan selain bayangan terdeteksi')
        sumber_png = os.path.join(salin_a, 'prop_pohon_rindang.png')
        rusak = os.path.join(sementara, 'rusak.png')
        with Image.open(sumber_png) as g:
            g = g.convert('RGBA')
            px = g.load()
            ys, xs = np.nonzero(np.array(g)[..., 3] == 255)
            r, gg, bb, al = px[int(xs[len(xs) // 2]), int(ys[len(ys) // 2])]
            px[int(xs[len(xs) // 2]), int(ys[len(ys) // 2])] = ((r + 1) % 256, gg, bb, al)
            g.save(rusak)
        periksa(piksel(rusak) != piksel(sumber_png), 'kontrol: pembanding piksel mendeteksi satu piksel berbeda')
        js = bytearray(baca(os.path.join(salin_a, 'prop_pohon_rindang.json')))
        js[10] ^= 0x01
        periksa(bytes(js) != baca(os.path.join(salin_a, 'prop_pohon_rindang.json')), 'kontrol: pembanding byte mendeteksi satu byte JSON berbeda')
        periksa(sidik_piksel(rusak) != sidik_piksel(sumber_png), 'kontrol: sidik golden mendeteksi satu piksel berbeda')

    print('uji_aset_lampu_pohon: %d lolos, %d gagal' % (lolos, gagal))
    return 1 if gagal else 0


if __name__ == '__main__':
    sys.exit(main())
