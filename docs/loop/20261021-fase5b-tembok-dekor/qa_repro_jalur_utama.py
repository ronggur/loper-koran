#!/usr/bin/env python3
"""QA iterasi 1 (run 5B), bukti QA-001: piksel OPAK pohon/lampu sisi dekat menimpa piksel pemain di lajur sepeda (|lateral| <= 1,0),
padahal kotak penutup (PenutupPemain, tinggi 1,25 / 1,0 ubin) bilang "tidak menutupi" sehingga alfa tetap 1,0.
Bukan bagian CI. Jalankan dari root repo: python3 docs/loop/20261021-fase5b-tembok-dekor/qa_repro_jalur_utama.py (butuh numpy, pillow).
Model: proyeksi iso 2:1 (x layar = (lateral - y) * 32, y layar = (lateral + y) * 16, y dunia = -maju), sel sprite pemain 46x58 pijak (23, 46)
baris 0 kolom 0 sheet (frame lurus), sprite dekor di tengah tapaknya (lateral per jenis dari config.gd), dekor digambar SESUDAH pemain (Y-sort) bila pijaknya lebih rendah di layar."""
import json, numpy as np
from PIL import Image

def scr(x, y): return ((x - y) * 32, (x + y) * 16)
PL = np.array(Image.open('assets/sprites/loper/loper_agen.png').convert('RGBA'))[0:58, 0:46, 3] >= 250
PA = (23, 46)

def tumpang(nama, lateral_dekor, lateral_pemain):
    m = np.array(Image.open(f'assets/sprites/props/{nama}.png').convert('RGBA'))[:, :, 3] >= 250
    a = json.load(open(f'assets/sprites/props/{nama}.json'))['ground_anchor']
    fx, fy = scr(lateral_dekor, 0)
    terbaik = (0, None)
    for k in range(-200, 200):
        dm = k * 0.025                      # maju pemain relatif ke maju dekor
        px, py = scr(lateral_pemain, -dm)
        if fy <= py: continue               # dekor digambar sebelum pemain
        ox = int(round(px - PA[0] - (fx - a[0]))); oy = int(round(py - PA[1] - (fy - a[1])))
        H, W = m.shape; h, w = PL.shape
        y0, y1 = max(0, oy), min(H, oy + h); x0, x1 = max(0, ox), min(W, ox + w)
        if y0 >= y1 or x0 >= x1: continue
        n = int((m[y0:y1, x0:x1] & PL[y0 - oy:y1 - oy, x0 - ox:x1 - ox]).sum())
        if n > terbaik[0]: terbaik = (n, round(dm, 3))
    return terbaik

kasus = [('prop_pohon_glodokan', 2.5, 1.0), ('prop_pohon_ketapang', 2.5, 1.0), ('prop_pohon_rindang', 2.5, 1.0),
         ('prop_lampu_lengan_dekat', 2.25, 0.5), ('prop_lampu_lengan_dekat', 2.25, 1.0)]
gagal = 0
for nama, ld, lp in kasus:
    n, dm = tumpang(nama, ld, lp)
    print(f'{nama} lateral dekor {ld}, pemain {lp}: piksel opak bertumpuk maks {n} (pemain {dm} ubin di depan dekor)')
    gagal += n > 0
print('GAGAL: dekor menimpa pemain di lajur sepeda tanpa alfa' if gagal else 'OK')
raise SystemExit(1 if gagal else 0)
