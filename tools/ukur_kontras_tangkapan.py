#!/usr/bin/env python3
"""Ukur kontras dari tangkapan layar nyata probe bengkel (run ui1-komponen-bengkel bagian B, AC-9), probe layar hasil (run ui2-semua-layar bagian A, AC-7, `--jenis hasil`), dan probe halaman koran
(run ui2-semua-layar bagian B, AC-7, `--jenis koran`).

Membaca pasangan `<awalan>_<jenis>_<keadaan>.png` dan `.json` (ditulis `tests/probe_bengkel_jendela.gd`, `tests/probe_hasil_jendela.gd`, atau `tests/probe_halaman_koran_jendela.gd`; jenis bawaan `bengkel`):
- TEKS: tiap persegi teks; latar = warna terbanyak di persegi, teks = piksel persentil 98 terjauh dari latar (piksel solid, bukan tepi lunak).
  Kontras WCAG antara keduanya; batas >= 7:1.
- GARIS KOMPONEN: tiap tombol dan kartu; garis = piksel terang di pita 2 px game paling luar (tepi atas dan bawah) melawan piksel 2 px game di luar tepi; batas >= 3:1.
  Hanya dilaporkan (garis bingkai bergantung pada desain 9-slice); nonaktif sengaja redup.
  `--jenis koran`: tombol (Berangkat, tinta penuh) dan pilih (Ambil/Lewati, tipis atau terpilih) adalah kontrol aktif dan WAJIB >= 3:1 (exit 1 bila kurang); `kotak_misi` adalah wadah non-kontrol (garis ganda `KORAN_GARIS`
  di atas kertas, dilaporkan saja seperti kartu bengkel dan struk hasil). Teks di atas kertas terang (tinta di krem) ikut diukur >= 7:1.
Pakai: python3 tools/ukur_kontras_tangkapan.py <folder tangkapan> [--awalan 1920x1080] [--jenis bengkel|hasil|koran] (butuh numpy, pillow). Exit 1 bila ada teks < 7:1 (atau kontrol koran aktif < 3:1).
"""
import json
import sys
from collections import Counter
from pathlib import Path

import numpy as np
from PIL import Image


def lum(rgb):
    c = np.asarray(rgb, dtype=float) / 255.0
    c = np.where(c <= 0.03928, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    return 0.2126 * c[..., 0] + 0.7152 * c[..., 1] + 0.0722 * c[..., 2]


def kontras(a, b):
    la, lb = float(lum(a)), float(lum(b))
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)


def ukur_teks(img, skala, item):
    x, y, w, h = [v * skala for v in item["rect"]]
    x0, y0, x1, y1 = int(round(x)), int(round(y)), int(round(x + w)), int(round(y + h))
    area = img[y0:y1, x0:x1, :3].reshape(-1, 3)
    if len(area) == 0:
        return None
    latar = Counter(map(tuple, area)).most_common(1)[0][0]
    jarak = np.abs(area.astype(int) - np.array(latar)).sum(axis=1)
    ambang = np.percentile(jarak, 98)
    fg = area[jarak >= ambang].mean(axis=0)
    return kontras(fg, latar), latar, tuple(int(v) for v in fg)


def ukur_garis(img, skala, item):
    x, y, w, h = [v * skala for v in item["rect"]]
    s = int(skala)
    xs = slice(int(x + w * 0.25), int(x + w * 0.75))
    terbaik = 0.0
    for sisi_y, luar_y in ((int(y), int(y) - 2 * s), (int(y + h) - 1, int(y + h) + 2 * s - 1)):
        luar = img[luar_y:luar_y + 1, xs, :3].reshape(-1, 3).mean(axis=0)
        for dy in range(0, 2 * s):
            yy = sisi_y + dy if sisi_y == int(y) else sisi_y - dy
            baris = img[yy:yy + 1, xs, :3].reshape(-1, 3).mean(axis=0)
            terbaik = max(terbaik, kontras(baris, luar))
    return terbaik


def main():
    folder = Path(sys.argv[1])
    awalan = sys.argv[sys.argv.index("--awalan") + 1] if "--awalan" in sys.argv else ""
    jenis = sys.argv[sys.argv.index("--jenis") + 1] if "--jenis" in sys.argv else "bengkel"
    gagal = 0
    for js in sorted(folder.glob(f"{awalan}*_{jenis}_*.json")):
        png = js.with_suffix(".png")
        if not png.exists():
            continue
        data = json.loads(js.read_text())
        img = np.array(Image.open(png).convert("RGB"))
        skala = img.shape[1] / data["viewport"][0]
        teks = [(ukur_teks(img, skala, t), t["teks"]) for t in data["teks"]]
        teks = [(r, n) for r, n in teks if r is not None]
        terburuk = min(teks, key=lambda p: p[0][0])
        gagal_berkas = [(r, n) for r, n in teks if r[0] < 7.0]
        gagal += len(gagal_berkas)
        garis = {"tombol": [], "tombol_nonaktif": [], "kartu": [], "struk": [], "pilih": [], "kotak_misi": []}
        for k in data["komponen"]:
            garis.setdefault(k["jenis"], []).append(ukur_garis(img, skala, k))
        ringkas = {j: (round(min(v), 2) if v else None) for j, v in garis.items() if jenis == "koran" or j not in ("pilih", "kotak_misi")}
        if jenis == "koran":
            lemah = [(j, round(min(garis[j]), 2)) for j in ("tombol", "pilih") if garis[j] and min(garis[j]) < 3.0]
            gagal += len(lemah)
            for j, nilai in lemah:
                print(f"   KONTROL AKTIF < 3:1 '{j}' {nilai}")
        print(f"{js.stem}: {len(teks)} teks, terburuk {terburuk[0][0]:.2f}:1 '{terburuk[1]}', < 7: {len(gagal_berkas)}; garis min {ringkas}")
        for r, n in gagal_berkas:
            print(f"   TEKS < 7:1 '{n}' {r[0]:.2f} latar {r[1]} teks {r[2]}")
    sys.exit(1 if gagal else 0)


if __name__ == "__main__":
    main()
