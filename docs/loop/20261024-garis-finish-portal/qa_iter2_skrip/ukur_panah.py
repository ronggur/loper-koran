"""QA iterasi 2: jarak tinta teks (kiri) dan panah (kanan) ke tepi tombol dari tangkapan nyata probe.
python3 ukur_panah.py <folder induk probe> -> menulis jarak untuk Berangkat, Hari berikutnya, Lanjut di 4 ukuran."""
import json, sys
import numpy as np
from PIL import Image
def ink(png, rect, scale):
    A = np.asarray(Image.open(png).convert('RGB'), float)
    x, y, w, h = [int(round(v * scale)) for v in rect]
    ins = int(5 * scale)
    sub = A[y + ins:y + h - ins, x + ins:x + w - ins]
    L = sub @ np.array([.2126, .7152, .0722]); bg = np.median(L); m = np.abs(L - bg) > 70
    cols = np.where(m.any(axis=0))[0]
    return round((cols.min() + ins) / scale, 2), round((w - (cols.max() + 1 + ins)) / scale, 2)
base = sys.argv[1]
for sz, sc in [('2340x1080', 3), ('1920x1080', 3), ('2400x1080', 3), ('1600x720', 2)]:
    for pref, nm in [('halaman_koran/%s_koran_hari1', 'Berangkat'), ('bengkel/%s_bengkel_a_baru', 'Hari berikutnya'), ('jeda_hud/%s_jeda_mati', 'Lanjut')]:
        p = base + '/' + pref % sz
        d = json.load(open(p + '.json'))
        r = [c['rect'] for c in d['komponen'] if c['jenis'] in ('tombol', 'tombol_utama') and c['rect'][2] >= 130][0]
        print(sz, nm, r, ink(p + '.png', r, sc))
