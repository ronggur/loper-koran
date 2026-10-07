"""Penyesuaian hasil konversi gambar AI loper ke brief (ART_DIRECTION 3.1).

Menjalankan konversi.py lalu:
1. celana diwarnai ulang ke dongker (ramp yang sama dengan jogger di gambar full body resmi),
2. mata menatap ke depan (iris di tengah mata, putih tipis di kedua sisi),
3. kepala (bagian yang melayang) diturunkan supaya jaraknya ke kerah lebih kecil.

    python3 tools/loper_art/fullbody/konversi_loper.py docs/design/character/loper_agen/konversi/sumber_ai.jpg --out build/loper_art/konversi
"""
import argparse
import os
import sys
import numpy as np
from PIL import Image
from scipy import ndimage
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from konversi import convert  # noqa: E402

# 1. celana: biru muda dari gambar AI -> dongker, urut dari terang ke gelap
PANTS = {
    '#99b8db': '#7282ab', '#8aaad2': '#57658e', '#7b99c3': '#4e5b84', '#6a88b4': '#46527a',
    '#5c78a2': '#3f4a72', '#476088': '#343d62', '#2a3e60': '#2a3154', '#1d283c': '#1f2440',
}
PANTS_TOP = 139                      # baris pertama di bawah ujung kemeja
PANTS_X = (85, 180)

# 2. mata: (x, y) -> warna. Iris di tengah mata dengan putih tipis di kedua sisi: menatap ke depan, tidak melirik
LID, PUPIL, SPARK, WHITE = '#0b0806', '#0b0806', '#e2d1be', '#f5e6d7'
IRIS, IRIS_LO, SKIN = '#482013', '#61301f', '#e29e69'
EYES = {}


def _row(y, x0, cols):
    for i, c in enumerate(cols):
        EYES[(x0 + i, y)] = c


# mata dekat (kiri layar), x 124-130: iris di tengah, putih tipis di kedua sisi
_row(31, 124, [LID] * 7)
_row(32, 124, [LID, WHITE, PUPIL, SPARK, PUPIL, WHITE, LID])
_row(33, 124, [LID, WHITE, PUPIL, PUPIL, PUPIL, WHITE, LID])
_row(34, 124, [SKIN, WHITE, IRIS, PUPIL, IRIS, WHITE, LID])
_row(35, 124, [SKIN, WHITE, IRIS, IRIS, IRIS, WHITE, IRIS_LO])
_row(36, 124, [SKIN, SKIN, WHITE, IRIS_LO, IRIS_LO, IRIS_LO, IRIS_LO])
# mata jauh (kanan layar), x 140-145
_row(31, 140, [LID] * 6)
_row(32, 140, [WHITE, PUPIL, SPARK, PUPIL, WHITE, '#321307'])
_row(33, 140, [WHITE, PUPIL, PUPIL, PUPIL, WHITE, SKIN])
_row(34, 140, [WHITE, IRIS, PUPIL, IRIS, WHITE, SKIN])
_row(35, 140, [SKIN, WHITE, IRIS, IRIS, '#321307', SKIN])

HEAD_DROP = 3                        # px; dagu sedikit menumpuk kerah (diminta 2026-10-07)


def hexrgb(h):
    h = h.lstrip('#')
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], np.uint8)


def adjust(img, head_drop=HEAD_DROP):
    a = np.array(img)
    H, W = a.shape[:2]
    yy, xx = np.mgrid[0:H, 0:W]
    # 1. pants
    region = (yy >= PANTS_TOP) & (xx >= PANTS_X[0]) & (xx < PANTS_X[1]) & (a[..., 3] == 255)
    for src, dst in PANTS.items():
        m = region & np.all(a[..., :3] == hexrgb(src), -1)
        a[m, :3] = hexrgb(dst)
    # 3. the floating head is the second largest solid part (the largest is body + bike)
    solid = a[..., 3] == 255
    lab, n = ndimage.label(solid)
    sizes = ndimage.sum(solid, lab, range(1, n + 1))
    body_k, head_k = np.argsort(-sizes)[:2] + 1
    head = lab == head_k
    assert np.where(head)[0].max() < np.where(lab == body_k)[0].max(), 'bagian kedua terbesar bukan kepala'
    if head_drop:
        hp = a.copy()
        a[head] = 0
        moved = np.zeros_like(head)
        moved[head_drop:] = head[:-head_drop]
        src = np.zeros_like(a)
        src[head_drop:] = hp[:-head_drop]
        a[moved] = src[moved]
    # 2. eyes (coordinates are before the head moves)
    for (x, y), c in EYES.items():
        a[y + head_drop, x, :3] = hexrgb(c)
        a[y + head_drop, x, 3] = 255
    return Image.fromarray(a, 'RGBA')


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument('src')
    ap.add_argument('--out', default='build/loper_art/konversi')
    ap.add_argument('--name', default='loper_agen_konversi')
    ap.add_argument('--head-drop', type=int, default=HEAD_DROP)
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)
    img, pal, box, f = convert(args.src, 278, 40)
    img.save(f'{args.out}/{args.name}_asli.png')
    out = adjust(img, args.head_drop)
    out.save(f'{args.out}/{args.name}.png')
    out.resize((out.width * 3, out.height * 3), Image.NEAREST).save(f'{args.out}/{args.name}_x3.png')
    cols = sorted({tuple(c) for c in np.array(out)[np.array(out)[..., 3] == 255][:, :3]},
                  key=lambda c: 0.3 * c[0] + 0.59 * c[1] + 0.11 * c[2])
    sw = Image.new('RGB', (len(cols) * 12, 12))
    for i, c in enumerate(cols):
        sw.paste(tuple(int(x) for x in c), (i * 12, 0, i * 12 + 12, 12))
    sw.save(f'{args.out}/{args.name}_palet.png')
    print(f'{args.name}: {out.width}x{out.height} px, {len(cols)} warna, kepala turun {args.head_drop} px')


if __name__ == '__main__':
    main()
