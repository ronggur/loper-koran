#!/usr/bin/env python3
"""QA independen: ukur kontras teks dari piksel tangkapan (bukan warna deklarasi JSON)."""
import sys, json, glob, os
from collections import Counter
import numpy as np
from PIL import Image


def lin(c):
    c = c / 255.0
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def lum(rgb):
    l = lin(np.asarray(rgb, dtype=float))
    return 0.2126 * l[..., 0] + 0.7152 * l[..., 1] + 0.0722 * l[..., 2]


def ratio(a, b):
    la, lb = lum(a), lum(b)
    hi, lo = np.maximum(la, lb), np.minimum(la, lb)
    return (hi + 0.05) / (lo + 0.05)


def ukur(png, kecil_saja=False):
    js = png[:-4] + '.json'
    if not os.path.exists(js):
        return []
    d = json.load(open(js))
    img = np.array(Image.open(png).convert('RGB')).astype(int)
    skala = img.shape[0] // 360
    latar_p = png[:-4] + '_latar.png'
    latar = np.array(Image.open(latar_p).convert('RGB')).astype(int) if os.path.exists(latar_p) else None
    hasil = []
    for t in d.get('teks', []):
        x, y, w, h = [int(round(v * skala)) for v in t['rect']]
        if w <= 0 or h <= 0:
            continue
        crop = img[max(y, 0):y + h, max(x, 0):x + w]
        if crop.size == 0:
            continue
        if latar is not None:
            lc = latar[max(y, 0):y + h, max(x, 0):x + w]
            masked = (np.abs(crop - lc).sum(axis=2) > 0)
            if masked.sum() < 4:
                continue
            piksel = crop[masked]
            # warna teks = warna modal piksel yang beda (inti huruf)
            cnt = Counter(map(tuple, piksel))
            fg = np.array(cnt.most_common(1)[0][0])
            # latar di bawah huruf: setiap piksel latar pada rect diperluas 2 px
            ys, xs = np.nonzero(masked)
            bgpix = lc[masked]
            r = ratio(np.broadcast_to(fg, bgpix.shape), bgpix)
            hasil.append((float(r.min()), float(np.percentile(r, 1)), t['teks'][:40], '#%02x%02x%02x' % tuple(fg), t.get('warna')))
        else:
            flat = crop.reshape(-1, 3)
            cnt = Counter(map(tuple, flat))
            bg = np.array(cnt.most_common(1)[0][0])
            kontras = ratio(flat, np.broadcast_to(bg, flat.shape))
            i = int(np.argmax(kontras))
            fg = flat[i]
            # warna fg inti: modal di antara piksel dengan kontras >= 0.9*maks
            kuat = flat[kontras >= 0.9 * kontras.max()]
            fg = np.array(Counter(map(tuple, kuat)).most_common(1)[0][0])
            hasil.append((float(ratio(fg, bg)), float(ratio(fg, bg)), t['teks'][:40], '#%02x%02x%02x' % tuple(fg), t.get('warna')))
    return hasil


if __name__ == '__main__':
    pola = sys.argv[1]
    ambang = float(sys.argv[2]) if len(sys.argv) > 2 else 7.0
    semua = []
    for png in sorted(glob.glob(pola)):
        if png.endswith('_latar.png'):
            continue
        for r in ukur(png):
            semua.append((r[0], r[1], os.path.basename(png), r[2], r[3], r[4]))
    semua.sort()
    print(len(semua), 'teks diukur')
    for r in semua[:int(sys.argv[3]) if len(sys.argv) > 3 else 25]:
        print('%.2f p1=%.2f %s | %s | fg=%s deklarasi=%s' % r)
    print('di bawah', ambang, ':', sum(1 for r in semua if r[0] < ambang))
