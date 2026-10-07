"""Konversi ilustrasi (misalnya hasil generator gambar) jadi pixel art sungguhan.

Langkah: buang latar polos, pisahkan bayangan tanah, kuantisasi warna ke palet terbatas (k-means di ruang Lab),
perkecil per blok dengan warna terbanyak (bukan rata-rata, supaya tidak kabur), rapikan piksel lepas,
lalu tambahkan garis luar 1 px dan bayangan tanah dongker transparan seperti gaya skala besar (ART_DIRECTION 3.5).

    python3 tools/loper_art/fullbody/konversi.py SUMBER.jpg --out build/loper_art/konversi --height 278 --colors 40
"""
import argparse
import os
import numpy as np
from PIL import Image
from scipy import ndimage
from skimage.color import rgb2lab
from sklearn.cluster import KMeans

OUT = np.array([0x1B, 0x12, 0x26])
SHADOW = (0x2E, 0x35, 0x50, 96)


def background_mask(a, tol=26.0):
    """Latar = warna polos sudut gambar yang tersambung ke tepi."""
    corners = np.concatenate([a[:16, :16], a[:16, -16:], a[-16:, :16], a[-16:, -16:]]).reshape(-1, 3)
    bg = np.median(corners, 0)
    near = np.sqrt(((a - bg) ** 2).sum(2)) < tol
    lab, _ = ndimage.label(near)
    edge = np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))
    return np.isin(lab, edge[edge > 0]), bg


def shadow_mask(a, fg, bottom_frac=0.12):
    """Bayangan tanah: piksel gelap kebiruan di pita bawah subjek."""
    ys = np.where(fg.any(1))[0]
    y1 = ys.max()
    y0 = int(y1 - (y1 - ys.min()) * bottom_frac)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    lum = 0.3 * r + 0.59 * g + 0.11 * b
    dark_blue = (lum < 70) & (b >= r - 4)
    band = np.zeros_like(fg)
    band[y0:y1 + 1] = True
    return fg & band & dark_blue


def convert(src, height=278, colors=40, seed=3):
    im = Image.open(src).convert('RGB')
    a = np.asarray(im).astype(float)
    bgm, bg = background_mask(a)
    fg = ~bgm
    fg = ndimage.binary_opening(fg, iterations=1)
    sh = shadow_mask(a, fg)
    body = fg & ~sh
    # keep only the big connected pieces (drop JPEG specks)
    lab, n = ndimage.label(body)
    sizes = ndimage.sum(body, lab, range(1, n + 1))
    body = np.isin(lab, 1 + np.where(sizes > 400)[0])
    ys, xs = np.where(body | sh)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    by0 = np.where(body.any(1))[0]
    subj_h = by0.max() + 1 - by0.min()
    f = subj_h / height                                     # source pixels per target pixel
    W, H = int(np.ceil((x1 - x0) / f)), int(np.ceil((y1 - y0) / f))

    # palette from the subject in Lab space
    pix = a[body]
    rng = np.random.RandomState(seed)
    samp = pix[rng.choice(len(pix), min(60000, len(pix)), replace=False)]
    km = KMeans(n_clusters=colors, n_init=4, random_state=seed).fit(rgb2lab(samp[None] / 255.0)[0])
    labs = km.cluster_centers_
    # palette colour = median RGB of its members (keeps real colours, not Lab averages)
    lab_s = rgb2lab(samp[None] / 255.0)[0]
    lbl_s = km.predict(lab_s)
    pal = np.array([np.median(samp[lbl_s == k], 0) if (lbl_s == k).any() else [0, 0, 0] for k in range(colors)])

    # assign every source pixel of the crop
    crop = a[y0:y1, x0:x1]
    cl = km.predict(rgb2lab(crop / 255.0).reshape(-1, 3)).reshape(crop.shape[:2])
    cb = body[y0:y1, x0:x1]
    cs = sh[y0:y1, x0:x1]
    idx = np.full((H, W), -1, int)          # -1 empty, -2 shadow, k palette
    lum = pal @ np.array([0.3, 0.59, 0.11])
    pal_lab = rgb2lab(pal[None] / 255.0)[0]
    for ty in range(H):
        sy0, sy1 = int(round(ty * f)), int(round((ty + 1) * f))
        for tx in range(W):
            sx0, sx1 = int(round(tx * f)), int(round((tx + 1) * f))
            m = cb[sy0:sy1, sx0:sx1]
            tot = m.size
            if tot == 0:
                continue
            if m.sum() >= 0.45 * tot:
                c = cl[sy0:sy1, sx0:sx1][m]
                cnt = np.bincount(c, minlength=colors).astype(float)
                # thin dark lines survive: give dark colours a bonus
                cnt *= 1.0 + 0.6 * (lum < 55)
                idx[ty, tx] = int(cnt.argmax())
            elif cs[sy0:sy1, sx0:sx1].sum() >= 0.45 * tot:
                idx[ty, tx] = -2
    # flatten JPEG speckle: a pixel takes the 3x3 majority colour when at least 6 of 9 agree
    for _ in range(2):
        p = np.pad(idx, 1, constant_values=-9)
        win = np.stack([p[dy:dy + H, dx:dx + W] for dy in range(3) for dx in range(3)])
        best = np.full((H, W), -9)
        bestc = np.zeros((H, W), int)
        for k in np.unique(idx[idx >= 0]):
            cnt = (win == k).sum(0)
            m = cnt > bestc
            best[m], bestc[m] = k, cnt[m]
        near = np.linalg.norm(pal_lab[np.maximum(idx, 0)] - pal_lab[np.maximum(best, 0)], axis=-1) < 14
        flip = (idx >= 0) & (best >= 0) & (bestc >= 6) & (best != idx) & near     # only near-identical shades
        idx[flip] = best[flip]
    # clean lone pixels: a pixel whose 4 neighbours agree on another colour takes that colour
    for _ in range(2):
        p = np.pad(idx, 1, constant_values=-1)
        nb = np.stack([p[:-2, 1:-1], p[2:, 1:-1], p[1:-1, :-2], p[1:-1, 2:]])
        same = (nb == nb[0]).all(0) & (nb[0] != idx) & (idx >= 0) & (nb[0] >= 0)
        idx[same] = nb[0][same]
    # outline: silhouette edge pixels become the outline colour (sel-out on the light side)
    solid = idx >= 0
    p = np.pad(solid, 1)
    edge = solid & ~(p[:-2, 1:-1] & p[2:, 1:-1] & p[1:-1, :-2] & p[1:-1, 2:])
    rgb = np.zeros((H, W, 4), np.uint8)
    used = np.unique(idx[solid])
    rgb[solid, :3] = pal[idx[solid]].astype(np.uint8)
    rgb[solid, 3] = 255
    # silhouette pixels that are not already dark become the outline colour (no new blended colours)
    light_edge = edge & (lum[np.maximum(idx, 0)] >= 60)
    rgb[light_edge, :3] = OUT
    shm = idx == -2
    rgb[shm] = SHADOW
    final_pal = sorted({tuple(c) for c in rgb[solid, :3].reshape(-1, 3)}, key=lambda c: 0.3 * c[0] + 0.59 * c[1] + 0.11 * c[2])
    return Image.fromarray(rgb, 'RGBA'), final_pal, (x0, y0, x1, y1), f


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument('src')
    ap.add_argument('--out', default='build/loper_art/konversi')
    ap.add_argument('--height', type=int, default=278, help='tinggi subjek tanpa bayangan, px')
    ap.add_argument('--colors', type=int, default=40)
    ap.add_argument('--name', default='loper_agen_konversi')
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)
    img, pal, box, f = convert(args.src, args.height, args.colors)
    img.save(f'{args.out}/{args.name}.png')
    img.resize((img.width * 3, img.height * 3), Image.NEAREST).save(f'{args.out}/{args.name}_x3.png')
    sw = Image.new('RGB', (len(pal) * 12, 12))
    for i, c in enumerate(pal):
        sw.paste(tuple(int(x) for x in c), (i * 12, 0, i * 12 + 12, 12))
    sw.save(f'{args.out}/{args.name}_palet.png')
    print(f'{args.name}: {img.width}x{img.height} px, {len(pal)} warna, 1 px = {f:.2f} px sumber')


if __name__ == '__main__':
    main()
