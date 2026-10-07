"""Pose yang dikunci untuk produksi (2026-10-07): base model Kemeja Agen, 5 arah, 3 kecepatan.

Diimpor oleh produce.py. Dijalankan langsung, file ini merender papan pratinjau statis
(5 arah santai + 3 pose kecepatan) seperti di kanvas "Karakter Loper Koran".

    python3 tools/loper_art/base.py --out build/loper_art/base
"""
import argparse
import math
import os
import numpy as np
from PIL import Image
import iso
from iso import render, hexc
from loper import build, ALL

BASE = [v for v in ALL if v['id'] == 'h'][0]


def lean_pose(hip, deg, torso=10.1, neck=(2.4, 5.4)):
    """Pinggul di `hip`, badan condong `deg` derajat dari tegak, leher (maju, naik)."""
    t = math.radians(deg)
    sh = (hip[0] + torso * math.sin(t), 0, hip[2] + torso * math.cos(t))
    return dict(hip=hip, shoulder=sh, head=(sh[0] + neck[0], 0, sh[2] + neck[1]), arm_ik=True)


# Tiga tingkat kecepatan (ART_DIRECTION 3.2). ngebut = berdiri dari sadel.
SPEED = {
    'santai': {},
    'cepat': lean_pose((3.6, 0, 18.3), 50, neck=(2.8, 5.0)),
    'ngebut': lean_pose((5.8, 0, 21.6), 55, neck=(2.6, 4.6)),
}
SPEED_LEAN = {'santai': 0, 'cepat': 0, 'ngebut': -3}
# Lima arah: nama, yaw (derajat, + = kanan pelempar), condong badan, belok setang.
HEADINGS = [
    ('normal', 0, 0, 0),
    ('serong_kanan', 45, 4, 8),
    ('kanan', 90, 6, 12),
    ('serong_kiri', -45, -4, -8),
    ('kiri', -90, -6, -12),
]
BIG, CX, CY = 140, 70, 100

GRASS = [hexc('#6fae4f'), hexc('#62a046')]
ROAD = [hexc('#6c6872'), hexc('#67636d')]
WALK = [hexc('#dccba6'), hexc('#d5c4a1')]
DASH = hexc('#f2e7c9'); CURB = hexc('#a9a2ae')


def ground(W, H, ox, oy, road_half=34, walk=12):
    """Potongan jalan isometrik (aspal, kerb, trotoar, rumput) untuk latar pratinjau."""
    py, px = np.mgrid[0:H, 0:W]
    sx = px + 0.5 - ox; sy = py + 0.5 - oy
    x = sy + sx / 2; y = sy - sx / 2
    chk = (np.floor(x / 32).astype(int) + np.floor(y / 32).astype(int)) % 2
    img = np.zeros((H, W, 3), np.uint8); ax = np.abs(x)
    for k in (0, 1):
        img[(ax < road_half) & (chk == k)] = ROAD[k]
        img[(ax >= road_half + walk) & (chk == k)] = GRASS[k]
        img[(ax >= road_half) & (ax < road_half + walk) & (chk == k)] = WALK[k]
    img[(ax >= road_half) & (ax < road_half + 1.2)] = CURB
    img[(ax < 1.0) & ((np.floor(y / 12).astype(int) % 2) == 0)] = DASH
    out = np.full((H, W, 4), 255, np.uint8); out[..., :3] = img
    return out


def draw(yaw, lean, steer, extra, variant=None):
    iso.POSE['yaw'], iso.POSE['lean'] = yaw, lean
    M, sh = build(dict(variant or BASE, steer=steer, **extra), -40)
    c = iso.L2W(np.array([8.5, 0.0, 0.0]))
    img = render(M, BIG, BIG, CX - (c[0] - c[1]), CY - (c[0] + c[1]) / 2, shadow_pts=sh)
    iso.POSE['yaw'] = iso.POSE['lean'] = 0
    return img


def boards(out):
    os.makedirs(out, exist_ok=True)
    big = {}
    for key, yaw, lean, steer in HEADINGS:
        big['arah_' + key] = draw(yaw, lean, steer, {})
    for k, extra in SPEED.items():
        big['pose_' + k] = draw(0, SPEED_LEAN[k], 0, extra)
        big['pose_' + k + '_samping'] = draw(45, SPEED_LEAN[k], 0, extra)

    alpha = np.zeros((BIG, BIG), bool)
    for a in big.values():
        alpha |= a[..., 3] > 0
    ys, xs = np.where(alpha)
    x0, x1, y0, y1 = xs.min() - 1, xs.max() + 2, ys.min() - 1, ys.max() + 2
    CW, CH = int(x1 - x0), int(y1 - y0)
    cells = {k: Image.fromarray(v[y0:y1, x0:x1], 'RGBA') for k, v in big.items()}

    arah = Image.new('RGBA', (CW * 5, CH), (0, 0, 0, 0))
    for i, (key, *_r) in enumerate(HEADINGS):
        arah.alpha_composite(cells['arah_' + key], (i * CW, 0))
    pose = Image.new('RGBA', (CW * 3, CH * 2), (0, 0, 0, 0))
    for i, k in enumerate(SPEED):
        pose.alpha_composite(cells['pose_' + k], (i * CW, 0))
        pose.alpha_composite(cells['pose_' + k + '_samping'], (i * CW, CH))

    def onbg(im, z):
        bg = Image.new('RGBA', im.size, (0x6c, 0x68, 0x72, 255)); bg.alpha_composite(im)
        return bg.resize((im.width * z, im.height * z), Image.NEAREST)

    arah.save(f'{out}/agen_5arah_1x.png')
    onbg(arah, 6).save(f'{out}/agen_5arah_x6.png')
    pose.save(f'{out}/agen_kecepatan_1x.png')
    onbg(pose, 6).save(f'{out}/agen_kecepatan_x6.png')
    print('papan pratinjau ditulis ke', out)


if __name__ == '__main__':
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument('--out', default='build/loper_art/base')
    boards(ap.parse_args().out)
