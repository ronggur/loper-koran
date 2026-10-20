#!/usr/bin/env python3
"""Uji aset gelombang 1 Fase 5 (usulan, `tools/env_art/gelombang1/`):

1. Renderer deterministik: dua kali jalan = piksel RGBA dan JSON sama untuk semua sprite dan papan.
2. Manifest: 29 sprite dengan nama berawalan kategori (prop_, vfx_, mission_, house_, tile_), sel dan jumlah frame sesuai lebar PNG,
   titik pijak di dalam sel (kecuali tumpangan `prop_koran_kotak_surat` yang pijaknya = pijak kotak surat), ubin 64x32 pijak (32, 16).
3. Palet: setiap warna opak sprite ada di palet induk (`pxcore.P` + aspal, marka, trotoar, kerb, garis luar) atau di ubin alas dari
   `tools/env_art/ubin_perumahan.py`; semi-transparan hanya penanda bayangan #000000 alpha 71 atau putih alpha 179 (garis kecepatan).
4. Mock di `docs/design/environment/gelombang1/` sama dengan hasil `render.py --mock` (tidak diedit tangan).

Butuh numpy dan pillow; bila tidak ada, uji berhenti dengan exit code 2.

Cara pakai (dari root repo):
    python3 tools/tests_cek/uji_aset_gelombang1.py

Exit code: 0 lolos semua, 1 ada yang gagal, 2 numpy/pillow tidak terpasang.
"""
import json
import os
import subprocess
import sys
import tempfile

FOLDER = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(FOLDER, '..', '..'))
SKRIP = os.path.join(ROOT, 'tools', 'env_art', 'gelombang1', 'render.py')
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


def jalankan(keluaran):
    env = dict(os.environ, ENV_ART_OUT=keluaran)
    h = subprocess.run([sys.executable, SKRIP], capture_output=True, text=True, env=env, cwd=ROOT)
    return h.returncode, h.stdout + h.stderr


def main():
    try:
        import numpy as np
        from PIL import Image
    except ImportError:
        print('numpy dan pillow dibutuhkan: python3 -m pip install numpy pillow')
        return 2

    with tempfile.TemporaryDirectory() as t1, tempfile.TemporaryDirectory() as t2:
        k1, o1 = jalankan(t1)
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

        brd = os.path.join(g1, 'board')
        if os.path.isdir(MOCK):
            for nm in sorted(os.listdir(MOCK)):
                if not nm.endswith('.png') or nm.startswith('lembar_'):
                    continue
                periksa(os.path.exists(os.path.join(brd, nm)) and piksel(os.path.join(MOCK, nm)) == piksel(os.path.join(brd, nm)),
                        'mock docs beda dengan render: %s (jalankan render.py --mock)' % nm)
        else:
            periksa(False, 'folder mock tidak ada: %s' % MOCK)

    print('uji_aset_gelombang1: %d lolos, %d gagal' % (lolos, gagal))
    return 1 if gagal else 0


if __name__ == '__main__':
    sys.exit(main())
