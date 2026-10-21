#!/usr/bin/env python3
"""Uji aset gelombang 1 Fase 5 (usulan, `tools/env_art/gelombang1/`):

1. Renderer deterministik: dua kali jalan = piksel RGBA dan JSON sama untuk semua sprite dan papan.
2. Manifest: 29 sprite dengan nama berawalan kategori (prop_, vfx_, mission_, house_, tile_), sel dan jumlah frame sesuai lebar PNG,
   titik pijak di dalam sel (kecuali tumpangan `prop_koran_kotak_surat` yang pijaknya = pijak kotak surat), ubin 64x32 pijak (32, 16).
3. Palet: setiap warna opak sprite ada di palet induk (`pxcore.P` + aspal, marka, trotoar, kerb, garis luar) atau di ubin alas dari
   `tools/env_art/ubin_perumahan.py`; semi-transparan hanya penanda bayangan #000000 alpha 71 atau putih alpha 179 (garis kecepatan).
4. Mock di `docs/design/environment/gelombang1/` (papan, komposisi, dan lembar kontak) sama dengan hasil `render.py --mock` (tidak diedit tangan).
5. Tiga penyesuaian K-1 (run fase5a-pasang-aset-gelombang1, AC-1): (a) `mission_kilau` dua warna, tiap frame krem terang dominan (>= 60% piksel
   non-garis-luar) dan kuning aksen <= 5 piksel (titik tengah); (b) tidak ada tong sampah hijau (nama maupun warna dasar), warna dasar bukan
   `#969AA0` (= RADAR_BUKAN), dan versi biru tidak sama atau dekat dengan token semantik di `scripts/ui/palette.gd` (OK, FAIL, WARN, ACCENT,
   RADAR_*); (c) `ubin_perumahan.py` tidak lagi menghasilkan `prop_polisi_tidur` dan tidak ada sprite polisi tidur kuning-hitam di mana pun
   kecuali `tile_perumahan_polisi_tidur` gelombang 1 (assets/ dan docs/design/environment/).

Butuh numpy dan pillow; bila tidak ada, uji berhenti dengan exit code 2.

Cara pakai (dari root repo):
    python3 tools/tests_cek/uji_aset_gelombang1.py

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
SKRIP = os.path.join(ROOT, 'tools', 'env_art', 'gelombang1', 'render.py')
SKRIP_UBIN = os.path.join(ROOT, 'tools', 'env_art', 'ubin_perumahan.py')
PALETTE = os.path.join(ROOT, 'scripts', 'ui', 'palette.gd')
TOKEN_SEMANTIK = ('ACCENT', 'OK', 'FAIL', 'WARN', 'RADAR_PELANGGAN', 'RADAR_TIP', 'RADAR_MISI', 'RADAR_BUKAN')
JARAK_TOKEN_MIN = 40.0      # jarak RGB minimum warna dasar tong biru dari tiap token semantik
MOCK = os.path.join(ROOT, 'docs', 'design', 'environment', 'gelombang1')
AWALAN = ('prop_', 'vfx_', 'mission_', 'house_', 'tile_')

gagal = 0
lolos = 0


def periksa(kondisi, label):
    global gagal, lolos
    if kondisi:
        lolos += 1
    else:
        gagal += 1
        print('GAGAL:', label)


def piksel(jalur):
    from PIL import Image
    with Image.open(jalur) as g:
        g = g.convert('RGBA')
        return g.size, g.tobytes()


def jalankan(keluaran, skrip=None, argumen=(), **tambahan):
    env = dict(os.environ, ENV_ART_OUT=keluaran, **tambahan)
    h = subprocess.run([sys.executable, skrip or SKRIP, *argumen], capture_output=True, text=True, env=env, cwd=ROOT)
    return h.returncode, h.stdout + h.stderr


def token_palette():
    """{nama: (r, g, b)} dari `const NAMA: Color = Color("#rrggbb"...)` di scripts/ui/palette.gd."""
    hasil = {}
    for baris in open(PALETTE, encoding='utf-8'):
        m = re.match(r'const (\w+): Color = Color\("#([0-9A-Fa-f]{6})"', baris)
        if m:
            h = m.group(2)
            hasil[m.group(1)] = (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))
    return hasil


def hijau_dominan(c):
    r, g, b = c
    return g > r + 10 and g > b + 10


def main():
    try:
        import numpy as np
        from PIL import Image
    except ImportError:
        print('numpy dan pillow dibutuhkan: python3 -m pip install numpy pillow')
        return 2

    with tempfile.TemporaryDirectory() as t1, tempfile.TemporaryDirectory() as t2, tempfile.TemporaryDirectory() as tmock:
        k1, o1 = jalankan(t1, argumen=('--mock',), ENV_ART_MOCK_KE=tmock)
        k2, o2 = jalankan(t2)
        periksa(k1 == 0 and k2 == 0, 'render.py gagal:\n' + o1 + o2)
        if k1 or k2:
            return 1
        g1, g2 = os.path.join(t1, 'gelombang1'), os.path.join(t2, 'gelombang1')
        for sub in ('sprites', 'board'):
            a = sorted(os.listdir(os.path.join(g1, sub)))
            b = sorted(os.listdir(os.path.join(g2, sub)))
            periksa(a == b, 'daftar berkas %s beda antar jalan' % sub)
            for nm in a:
                p1, p2 = os.path.join(g1, sub, nm), os.path.join(g2, sub, nm)
                if nm.endswith('.png'):
                    periksa(piksel(p1) == piksel(p2), 'tidak deterministik: %s/%s' % (sub, nm))
                else:
                    periksa(open(p1).read() == open(p2).read(), 'tidak deterministik: %s/%s' % (sub, nm))

        spr = os.path.join(g1, 'sprites')
        manifest = json.load(open(os.path.join(spr, 'manifest.json')))
        periksa(len(manifest) == 29, 'manifest harus 29 sprite, ada %d' % len(manifest))

        sys.path.insert(0, os.path.dirname(SKRIP))
        import pxcore
        import sumber
        boleh = set()
        for nada in pxcore.P.values():
            boleh.update(tuple(c[:3]) for c in nada)
        for c in pxcore.ASPAL + pxcore.TROTOAR + [pxcore.MARKA, pxcore.KERB, pxcore.OUT, pxcore.PUTIH]:
            boleh.add(tuple(c[:3]))
        alas = sumber.ubin('aspal_polos')
        boleh.update(map(tuple, alas[alas[..., 3] == 255][:, :3].tolist()))

        for m in manifest:
            nama = m['sprite']
            periksa(nama.startswith(AWALAN), 'awalan kategori: %s' % nama)
            with Image.open(os.path.join(spr, nama)) as g:
                a = np.array(g.convert('RGBA'))
            cw, ch = m['cell']
            periksa(a.shape[0] == ch and a.shape[1] == cw * m['frames'], 'ukuran sheet %s vs sel x frame' % nama)
            ax, ay = m['ground_anchor']
            if nama != 'prop_koran_kotak_surat.png':
                periksa(0 <= ax < cw and 0 <= ay < ch, 'pijak di luar sel: %s' % nama)
            if nama.startswith('tile_'):
                periksa([cw, ch] == [64, 32] and [ax, ay] == [32, 16], 'ubin 64x32 pijak (32,16): %s' % nama)
            js = json.load(open(os.path.join(spr, nama[:-4] + '.json')))
            periksa(js == m, 'JSON sprite = entri manifest: %s' % nama)
            opak = a[a[..., 3] == 255][:, :3]
            asing = {tuple(c) for c in opak.tolist()} - boleh
            periksa(not asing, 'warna di luar palet induk di %s: %s' % (nama, sorted(asing)[:4]))
            semi = a[(a[..., 3] > 0) & (a[..., 3] < 255)]
            semi_ok = {(0, 0, 0, 71), (255, 255, 255, 179)}
            asing_semi = {tuple(c) for c in semi.tolist()} - semi_ok
            periksa(not asing_semi, 'semi-transparan selain penanda bayangan / garis kecepatan di %s: %s' % (nama, sorted(asing_semi)[:4]))

        # Mock docs (papan, komposisi, dan lembar kontak) = hasil `render.py --mock` (dirender ke folder sementara, dibandingkan piksel)
        if os.path.isdir(MOCK):
            hasil_mock = sorted(n for n in os.listdir(tmock) if n.endswith('.png'))
            ada_mock = sorted(n for n in os.listdir(MOCK) if n.endswith('.png'))
            periksa(hasil_mock == ada_mock, 'daftar mock docs beda dengan hasil --mock: %s vs %s' % (ada_mock, hasil_mock))
            for nm in ada_mock:
                periksa(os.path.exists(os.path.join(tmock, nm)) and piksel(os.path.join(MOCK, nm)) == piksel(os.path.join(tmock, nm)),
                        'mock docs beda dengan render: %s (jalankan render.py --mock)' % nm)
        else:
            periksa(False, 'folder mock tidak ada: %s' % MOCK)

        # ---- K-1 (1): mission_kilau dua warna
        def muat(nama):
            with Image.open(os.path.join(spr, nama + '.png')) as g:
                return np.array(g.convert('RGBA'))
        meta_kilau = next(m for m in manifest if m['sprite'] == 'mission_kilau.png')
        kilau = muat('mission_kilau')
        cw_k = meta_kilau['cell'][0]
        krem_terang = tuple(pxcore.P['kertas'][0][:3])
        kuning = {tuple(c[:3]) for c in pxcore.P['aksen']}
        garis_luar = tuple(pxcore.OUT[:3])
        periksa(meta_kilau['frames'] == 2, 'mission_kilau tetap 2 frame')
        for f in range(meta_kilau['frames']):
            fr = kilau[:, f * cw_k:(f + 1) * cw_k]
            opak = fr[fr[..., 3] == 255][:, :3]
            bukan_garis = [tuple(c) for c in opak.tolist() if tuple(c) != garis_luar]
            n_krem = sum(1 for c in bukan_garis if c == krem_terang)
            n_kuning = sum(1 for c in bukan_garis if c in kuning)
            periksa(bool(bukan_garis) and n_krem / len(bukan_garis) >= 0.60,
                    'kilau frame %d: krem terang harus >= 60%% piksel non-garis-luar (dapat %d dari %d)' % (f, n_krem, len(bukan_garis)))
            periksa(1 <= n_kuning <= 5, 'kilau frame %d: kuning aksen hanya di titik tengah, 1..5 piksel (dapat %d)' % (f, n_kuning))
            titik = [(x, y) for y in range(fr.shape[0]) for x in range(fr.shape[1])
                     if fr[y, x, 3] == 255 and tuple(fr[y, x, :3]) in kuning]
            periksa(all(abs(x - 4) <= 1 and abs(y - 4) <= 1 for x, y in titik), 'kilau frame %d: piksel kuning di titik tengah sel 9x9 %s' % (f, titik))
            sisa = {c for c in bukan_garis} - {krem_terang} - kuning
            periksa(not sisa, 'kilau frame %d: hanya dua warna (krem terang, kuning) + garis luar, ada lagi: %s' % (f, sorted(sisa)[:3]))

        # ---- K-1 (2): tong sampah tidak hijau; biru tidak bentrok token semantik
        tong = [m for m in manifest if m['sprite'].startswith('prop_tong_sampah')]
        periksa(len(tong) == 2, 'dua varian tong sampah (logam dan biru), dapat %s' % [m['sprite'] for m in tong])
        periksa(not any('hijau' in m['sprite'] for m in manifest), 'tidak ada sprite bernama hijau di manifest')
        token = token_palette()
        periksa(all(k in token for k in TOKEN_SEMANTIK), 'token semantik terbaca dari palette.gd')
        for m in tong:
            a = muat(m['sprite'][:-4])
            opak = [tuple(c) for c in a[a[..., 3] == 255][:, :3].tolist() if tuple(c) != garis_luar]
            hitung = {}
            for c in opak:
                hitung[c] = hitung.get(c, 0) + 1
            dasar = max(hitung, key=hitung.get)
            periksa(not hijau_dominan(dasar), 'tong %s: warna dasar %s tidak hijau' % (m['sprite'], dasar))
            periksa(not any(hijau_dominan(c) and n / len(opak) >= 0.05 for c, n in hitung.items()),
                    'tong %s: tidak ada warna hijau berarti (>= 5%% piksel)' % m['sprite'])
            periksa(dasar != token['RADAR_BUKAN'], 'tong %s: warna dasar %s bukan RADAR_BUKAN #969AA0' % (m['sprite'], dasar))
            for nm in TOKEN_SEMANTIK:
                t = token[nm]
                jarak = sum((u - v) ** 2 for u, v in zip(dasar, t)) ** 0.5
                periksa(jarak >= JARAK_TOKEN_MIN, 'tong %s: warna dasar %s terlalu dekat token %s %s (jarak %.0f)' % (m['sprite'], dasar, nm, t, jarak))
            print('  tong %s: warna dasar %s' % (m['sprite'], dasar))

        # ---- K-1 (3): hanya SATU polisi tidur (gelombang 1)
        with tempfile.TemporaryDirectory() as tub:
            ku, ou = jalankan(tub, skrip=SKRIP_UBIN)
            periksa(ku == 0, 'ubin_perumahan.py gagal:\n' + ou)
            hasil_ubin = os.listdir(os.path.join(tub, 'ubin')) if ku == 0 else []
            periksa(not any('polisi' in n for n in hasil_ubin), 'ubin_perumahan.py tidak lagi menghasilkan polisi tidur, dapat %s' % [n for n in hasil_ubin if 'polisi' in n])
            periksa(len(hasil_ubin) > 10, 'ubin_perumahan.py masih menghasilkan ubin (%d berkas)' % len(hasil_ubin))
        ada_polisi = []
        for akar in (os.path.join(ROOT, 'assets'), os.path.join(ROOT, 'docs', 'design', 'environment')):
            for dirpath, _, files in os.walk(akar):
                ada_polisi += [os.path.join(dirpath, n) for n in files if 'polisi' in n.lower() and not n.endswith(('.import', '.uid'))]
        periksa(ada_polisi == [], 'tidak ada berkas polisi tidur di assets/ atau docs/design/environment/: %s' % ada_polisi)
        polisi_g1 = [m['sprite'] for m in manifest if 'polisi' in m['sprite']]
        periksa(polisi_g1 == ['tile_perumahan_polisi_tidur.png'], 'satu-satunya polisi tidur = gelombang 1, dapat %s' % polisi_g1)
        sisa_kode = [n for n in ('KUNING', 'HITAM_PT', 'ekspor_polisi_tidur', 'def polisi_tidur') if n in open(SKRIP_UBIN, encoding='utf-8').read()]
        periksa(not sisa_kode, 'kode mati polisi tidur lama sudah dibuang dari ubin_perumahan.py: %s' % sisa_kode)

    print('uji_aset_gelombang1: %d lolos, %d gagal' % (lolos, gagal))
    return 1 if gagal else 0


if __name__ == '__main__':
    sys.exit(main())
