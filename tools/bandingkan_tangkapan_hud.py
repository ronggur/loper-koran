#!/usr/bin/env python3
"""Bandingkan tangkapan HUD rute sebelum dan sesudah tata ulang V-9 (run ui2-semua-layar bagian C2, AC-6): semua yang TIDAK boleh berubah harus piksel-identik.

Membaca pasangan tangkapan `<awalan>_<jenis>_<keadaan>.png` dari folder baseline (sebelum run) dan folder iterasi (sesudah), dari probe lama `tests/probe_hud_rute_jendela.gd` (`hud_*`),
`tests/probe_misi_jendela.gd` (`misi_*`), dan `tests/probe_reputasi_jendela.gd` (`reputasi_hud_*`). Probe berjalan dengan langkah tetap, jadi jalan, rumah, radar, panel progres dan tenggat,
kartu misi, banner, penanda kucing, umpan melayang, dan tombol bel harus sama persis. Kelompok perubahan yang DISENGAJA dikecualikan (persegi dalam piksel game, dikali skala tangkapan):
- panel bawah (kecepatan, stamina, koran): pita bawah x 90..540 dari tepi sisi stick (dicerminkan saat kidal), 80 dari bawah (panel lama mulai y 293, baru y 313; dengan inset lebih tinggi);
- kolom kanan atas (koin, skor, kondisi, reputasi): x lebar-225 sampai lebar-20, y 0..130 (baris 3 reputasi lama dengan inset) (radar kanan di x lebar-16 tidak ikut dikecualikan);
- derau animasi di sekitar pemain (debu roda, bingkai kayuh; dua jalan probe yang sama berbeda 36 sampai 45 piksel di sini): x 150..270, y 230..345;
- tombol jeda HUD berbentuk tombol biasa (V-9 H-3): x 14..80, y 2..72 (termasuk geseran inset);
- keadaan yang mengubah isinya sendiri (AC-5): tutorial (tombol Lewati dan panel petunjuk) di semua tangkapan `misi_*`, gelembung petunjuk (label "PELANGGAN:") di `misi_petunjuk`.
Keluaran per berkas: jumlah piksel berbeda di luar pengecualian dan kotak pembatasnya. Exit 1 bila ada piksel berbeda.

Pakai: python3 tools/bandingkan_tangkapan_hud.py <folder baseline> <folder iterasi> [--awalan 1920x1080] (butuh numpy, pillow).
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

JENIS = ('hud', 'misi', 'reputasi_hud')
# Tangkapan yang bukan HUD rute (layar hasil, jeda) atau yang berubah karena bagian lain dari run ini.
LEWATI = ('hasil', 'jeda_sakelar')


def kotak_dikecualikan(nama, lebar, tinggi, skala):
    """Persegi (x0, y0, x1, y1) dalam piksel tangkapan yang dikecualikan untuk tangkapan `nama` (viewport lebar x tinggi game)."""
    kotak = []
    kidal = 'kidal' in nama
    x0, x1 = (lebar - 540, lebar - 90) if kidal else (90, 540)
    kotak.append((x0, tinggi - 80, x1, tinggi))
    kotak.append((lebar - 225, 0, lebar - 20, 130))
    kotak.append((150, 230, 270, 345))
    kotak.append((14, 2, 80, 72))
    if nama.startswith('misi_'):
        kotak.append((60, 0, 140, 50))
        kotak.append((20, 84, 210, 150))
    if nama == 'misi_petunjuk':
        kotak.append((lebar // 2 - 125, 46, lebar // 2 + 125, 100))
    return [(int(a * skala), int(b * skala), int(c * skala), int(d * skala)) for a, b, c, d in kotak]


def main():
    baseline = Path(sys.argv[1])
    iterasi = Path(sys.argv[2])
    awalan = sys.argv[sys.argv.index('--awalan') + 1] if '--awalan' in sys.argv else ''
    beda_total = 0
    dibandingkan = 0
    for png in sorted(baseline.glob(f'{awalan}*.png')):
        bagian = png.stem.split('_', 1)
        if len(bagian) != 2 or not any(bagian[1].startswith(j + '_') for j in JENIS) or any(k in bagian[1] for k in LEWATI):
            continue
        pasangan = iterasi / png.name
        if not pasangan.exists():
            print(f'{png.name}: tidak ada di {iterasi}')
            beda_total += 1
            continue
        a = np.array(Image.open(png).convert('RGB')).astype(int)
        b = np.array(Image.open(pasangan).convert('RGB')).astype(int)
        if a.shape != b.shape:
            print(f'{png.name}: ukuran berbeda {a.shape} vs {b.shape}')
            beda_total += 1
            continue
        tinggi_px, lebar_px = a.shape[0], a.shape[1]
        skala = tinggi_px // 360
        lebar_game, tinggi_game = lebar_px // skala, tinggi_px // skala
        beda = np.abs(a - b).sum(axis=2) > 0
        for x0, y0, x1, y1 in kotak_dikecualikan(bagian[1], lebar_game, tinggi_game, skala):
            beda[y0:y1, x0:x1] = False
        jumlah = int(beda.sum())
        dibandingkan += 1
        if jumlah:
            ys, xs = np.nonzero(beda)
            print(f'{png.name}: {jumlah} piksel berbeda, kotak game x {xs.min() // skala}..{xs.max() // skala}, y {ys.min() // skala}..{ys.max() // skala}')
            beda_total += 1
        else:
            print(f'{png.name}: identik di luar pengecualian')
    print(f'{dibandingkan} tangkapan dibandingkan, {beda_total} berbeda')
    sys.exit(1 if beda_total else 0)


if __name__ == '__main__':
    main()
