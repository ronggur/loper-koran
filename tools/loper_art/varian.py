"""Pratinjau semua varian baju pemain (a-h): 5 arah santai dan animasi kayuh arah normal.

Varian a-g disimpan untuk item atau kosmetik nanti (ART_DIRECTION 3) dan belum diaudit frame per frame.
Varian h (Kemeja Agen) adalah base model produksi; sheet lengkapnya dibuat oleh produce.py.

    python3 tools/loper_art/varian.py --out build/loper_art/varian
"""
import argparse
import os
import numpy as np
from PIL import Image
import iso
from iso import render
from base import HEADINGS, ground
from loper import build, ALL
from produce import PHI, SLUG

BIG, CX, CY = 150, 75, 108
BG = (0x6c, 0x68, 0x72, 255)


def frame(variant, yaw, lean, steer, phi):
    iso.POSE['yaw'], iso.POSE['lean'] = yaw, lean
    M, sh = build(dict(variant, steer=steer), phi)
    c = iso.L2W(np.array([8.5, 0.0, 0.0]))
    img = render(M, BIG, BIG, CX - (c[0] - c[1]), CY - (c[0] + c[1]) / 2, shadow_pts=sh)
    iso.POSE['yaw'] = iso.POSE['lean'] = 0
    return img


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument('--out', default='build/loper_art/varian')
    args = ap.parse_args()
    out = args.out
    os.makedirs(f'{out}/preview', exist_ok=True)

    dirs, cyc = {}, {}
    for v in ALL:
        for key, yaw, lean, steer in HEADINGS:
            dirs[(v['id'], key)] = frame(v, yaw, lean, steer, PHI[0])
        for f, phi in enumerate(PHI):
            cyc[(v['id'], f)] = frame(v, 0, 0, 0, phi)

    alpha = np.zeros((BIG, BIG), bool)
    for a in list(dirs.values()) + list(cyc.values()):
        alpha |= a[..., 3] > 0
    ys, xs = np.where(alpha)
    x0, y0 = xs.min() - 1, ys.min() - 1
    CW, CH = int(xs.max() + 2 - x0), int(ys.max() + 2 - y0)
    AX, AY = CX - x0, CY - y0

    def cell(a):
        return Image.fromarray(a[y0:y0 + CH, x0:x0 + CW], 'RGBA')

    names = [h[0] for h in HEADINGS]
    board = Image.new('RGBA', (CW * len(names), CH * len(ALL)), (0, 0, 0, 0))
    for r, v in enumerate(ALL):
        name = f"{v['id']}_{SLUG[v['id']]}"
        strip = Image.new('RGBA', (CW * len(names), CH), (0, 0, 0, 0))
        for i, key in enumerate(names):
            strip.alpha_composite(cell(dirs[(v['id'], key)]), (i * CW, 0))
        strip.save(f'{out}/{name}_5arah.png')
        board.alpha_composite(strip, (0, r * CH))
        # pedal cycle on a road tile, x4
        gif = []
        for f in range(len(PHI)):
            g = Image.fromarray(ground(CW + 20, CH + 10, 10 + AX + 0.5, 5 + AY), 'RGBA')
            g.alpha_composite(cell(cyc[(v['id'], f)]), (10, 5))
            gif.append(g.convert('RGB').resize(((CW + 20) * 4, (CH + 10) * 4), Image.NEAREST))
        gif[0].save(f'{out}/preview/{name}_kayuh.gif', save_all=True, append_images=gif[1:], duration=125, loop=0)
    board.save(f'{out}/varian_5arah.png')
    bg = Image.new('RGBA', board.size, BG)
    bg.alpha_composite(board)
    bg.resize((board.width * 4, board.height * 4), Image.NEAREST).save(f'{out}/preview/varian_5arah_x4.png')
    print(f'{len(ALL)} varian, sel {CW}x{CH}, titik pijak ({AX}, {AY}) -> {out}')


if __name__ == '__main__':
    main()
