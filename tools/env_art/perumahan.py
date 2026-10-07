import math, sys
import numpy as np
from PIL import Image
from engine import *
from lib import *

import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(os.environ.get('ENV_ART_OUT', ROOT / 'build' / 'env_art'))
OUT.mkdir(parents=True, exist_ok=True)
SPR = Image.open(ROOT / 'docs/design/character/loper_agen/loper_agen.png').convert('RGBA')


def loper_frame(row=0, col=0):
    a = np.array(SPR)
    return a[row * 58:(row + 1) * 58, col * 46:(col + 1) * 46]


# ---- penampang jalan perumahan (usulan): aspal 3 ubin, pemisah, lajur sepeda 3/4 ubin tiap sisi ----
RD = 48            # setengah lebar aspal (2 lajur mobil @ 48)
SEP = (48, 52)     # kerb pemisah
BIKE = (52, 76)    # lajur sepeda (bekas trotoar), ditinggikan 2
EDGE = (76, 78)    # kerb luar
FX1, FX0 = -104, -198      # rumah sisi seberang: muka, belakang (halaman depan 26)
NX0, NX1 = 120, 206        # rumah sisi dekat (mundur 42 supaya atap tidak menutupi lajur)
BIKE_C = (BIKE[0] + BIKE[1]) / 2
PLAYER = (-BIKE_C, 150, 0)  # loper di lajur sepeda kiri (lalu lintas lajur kiri)

FAR_YC = [-448, -320, -192, -64, 64, 192, 320, 448]
NEAR_YC = [-400, -272, -144, -16, 112, 240, 368]
WALLS = ['pink', 'cream', 'mint', 'sky', 'cream', 'pink', 'sky', 'mint']
ROOFS = ['roof_red', 'roof_dk', 'roof_red', 'roof_gr', 'roof_dk', 'roof_red', 'roof_red', 'roof_dk']

BIKE_MAT = Mat('#7CC09A', '#4F9A74', '#356C52')


def far_drive(yc):
    return (yc - 40, yc - 18)


def near_drive(yc):
    return (yc - 38, yc - 16)


def region(x, y):
    n = len(x)
    mi = np.zeros(n, int)   # 0 grass
    sh = np.ones(n, int) + grass_tufts(x, y)
    ax = np.abs(x)
    road = ax < RD
    mi = np.where(road, 1, mi)
    sh = np.where(road, 1 + speckle(x, y, 5, 0.03, 0.05, 1), sh)
    dash = road & (ax < 1.6) & ((np.mod(y, 32)) < 16)
    edge = road & (ax > RD - 4) & (ax < RD - 2.6)
    mi = np.where(dash | edge, 2, mi); sh = np.where(dash | edge, 1, sh)
    # driveways + paths
    for yc in FAR_YC:
        a, b = far_drive(yc)
        dv = (x < -RD) & (x > FX1 - 2) & (y > a) & (y < b)
        mi = np.where(dv, 3, mi)
        sh = np.where(dv, 1 + np.where((np.mod(y - yc, 11) < 1) | (np.mod(x, 11) < 1), 1, 0), sh)
        pth = (x < -EDGE[1]) & (x > FX1 + 14) & (y > yc + 2) & (y < yc + 16)
        tile = (np.mod(x, 6) < 1) | (np.mod(y - yc - 2, 7) < 1)
        mi = np.where(pth, 3, mi); sh = np.where(pth, np.where(tile, 2, 1), sh)
    for yc in NEAR_YC:
        a, b = near_drive(yc)
        dv = (x > RD) & (x < NX0 + 2) & (y > a) & (y < b)
        mi = np.where(dv, 3, mi)
        sh = np.where(dv, 1 + np.where((np.mod(y - yc, 11) < 1) | (np.mod(x, 11) < 1), 1, 0), sh)
    return mi, sh


def _seg_dist(u, v, a, b):
    ax_, ay_ = a; bx_, by_ = b
    dx, dy = bx_ - ax_, by_ - ay_
    t = np.clip(((u - ax_) * dx + (v - ay_) * dy) / (dx * dx + dy * dy), 0, 1)
    return np.hypot(u - ax_ - t * dx, v - ay_ - t * dy)


BIKE_SYMBOL_Y = [-306, -178, -50, 30, 158, 286]


def bike_stencil(u, v):
    """Side-view bicycle painted on the lane. u = forward along the lane, v = lateral."""
    m = np.zeros(len(u), bool)
    for cu in (-4.6, 4.6):
        m |= np.abs(np.hypot(u - cu, v) - 3.0) < 0.75
    pts = {'r': (-4.6, 0), 'c': (0, 0), 's': (-1.6, -4.2), 'h': (3.2, -4.6), 'f': (4.6, 0)}
    for a, b in (('r', 's'), ('s', 'c'), ('r', 'c'), ('s', 'h'), ('h', 'f'), ('c', 'h')):
        m |= _seg_dist(u, v, pts[a], pts[b]) < 0.6
    m |= _seg_dist(u, v, (-2.8, -4.6), (-0.6, -4.6)) < 0.6     # sadel
    m |= _seg_dist(u, v, (3.2, -4.6), (4.6, -5.6)) < 0.6       # setang
    # panah arah di depan simbol
    m |= _seg_dist(u, v, (10, -3.2), (13, 0)) < 0.65
    m |= _seg_dist(u, v, (10, 3.2), (13, 0)) < 0.65
    return m


def bike_tex(Pw, Nw):
    x, y = Pw[:, 0], Pw[:, 1]
    top = Nw[:, 2] > 0.5
    ax = np.abs(x)
    mi = np.zeros(len(x), int)
    sh = np.where(top, 1, 0)
    sh = np.where(top & (hash2(np.floor(x), np.floor(y), 11) > 0.93), 2, sh)
    # garis tepi putih di sisi luar lajur
    line = top & (ax > BIKE[1] - 2.2) & (ax < BIKE[1] - 1.0)
    mi = np.where(line, 1, mi)
    # simbol sepeda + panah (lajur kiri ke -y, lajur kanan ke +y)
    for yc in BIKE_SYMBOL_Y:
        far = x < 0
        u = np.where(far, -(y - yc), (y - yc))
        v = np.where(far, -(x + BIKE_C), (x - BIKE_C))
        near = np.abs(y - yc) < 16
        st = top & near & bike_stencil(u, v)
        mi = np.where(st, 1, mi)
    # penyeberangan jalan masuk garasi: tepi putus-putus
    cross = np.zeros(len(x), bool)
    for yc in FAR_YC:
        a, b = far_drive(yc)
        cross |= (x < 0) & (y > a) & (y < b)
    for yc in NEAR_YC:
        a, b = near_drive(yc)
        cross |= (x > 0) & (y > a) & (y < b)
    dsh = top & cross & ((np.abs(ax - BIKE[0] - 1.2) < 0.7) | (np.abs(ax - BIKE[1] + 1.6) < 0.7)) & (np.mod(y, 4) < 2)
    mi = np.where(dsh, 1, mi)
    mi = np.where(top & cross & ~dsh & (np.abs(ax - BIKE[1] + 1.6) < 0.7), 0, mi)
    return mi, sh


def kerb_with_gaps(s, a, b, z1, mat, gaps):
    segs, ys = [], -900
    for g0, g1 in sorted(gaps):
        segs.append((ys, g0)); ys = g1
    segs.append((ys, 900))
    for y0, y1 in segs:
        if y1 > y0:
            s.add(box(a, b, y0, y1, 0, z1, mat, outline=False, cast=False))


def _teras(s, x1, ya, yb, R, seed, kind='shed', h=27):
    """Teras di depan pintu: lantai keramik, keset, dua tiang, atap kecil, lampu."""
    s.add(box(x1, x1 + 15, ya, yb, 0, 2.5, P['paper'],
              lambda Pw, Nw: (0, np.where((np.mod(Pw[:, 0], 5) < 0.8) | (np.mod(Pw[:, 1], 5) < 0.8), 1, 0)),
              outline=True, cast=False))
    yc = (ya + yb) / 2
    s.add(box(x1 + 3, x1 + 9, yc - 3, yc + 5, 2.5, 3.2, P['red'], outline=False, cast=False))  # keset
    for py in (ya + 1, yb - 3):
        s.add(box(x1 + 12, x1 + 14, py, py + 2, 2.5, h, P['white']))
    if kind == 'shed':
        s.add(shed(x1 - 2, x1 + 17, ya - 2, yb + 2, h + 3, h - 1, '+x', 2, mats=R, tex=roof_tex('flat')))
    else:   # dak beton datar dengan lis
        s.add(box(x1 - 1, x1 + 17, ya - 2, yb + 2, h, h + 3, P['white']))
    s.add(box(x1 + 0.5, x1 + 2.5, yc - 1, yc + 1, h - 5, h - 3, P['lamp']))
    s.lights.append(Light((x1 + 6, yc, 16), 46, '#FFC870', 0.85, flat=0.5))


HOUSE_TYPES = ('limasan', 'pelana', 'sayap')


def house_far(s, yc, wall, roof, seed=0, carport_car=False, kind='limasan'):
    """Rumah sisi seberang (fasad terlihat). Tiga bentuk:
    limasan: badan lebar, atap limas, teras di tengah.
    pelana: atap pelana dengan segitiga menghadap jalan, teras samping beratap dak.
    sayap: badan utama mundur, satu ruang depan menonjol beratap pelana kecil, teras di ceruk."""
    W, R = P[wall], P[roof]
    x0, x1 = FX0, FX1
    y0, y1 = yc - 44, yc + 44
    mats = [W, P['wood'], P['white'], P['glass'], P['metal_dk'], P['conc']]
    rt = roof_tex('genteng', seed, wall=True)
    if kind == 'limasan':
        feats = [
            dict(face='+x', u=(yc + 2, yc + 14), v=(2, 25), mat=1, frame=2, kind='door', handle=4),
            dict(face='+x', u=(yc - 32, yc - 16), v=(12, 25), mat=3, frame=2),
            dict(face='+x', u=(yc + 22, yc + 36), v=(12, 25), mat=3, frame=2),
            dict(face='+y', u=(x0 + 18, x0 + 34), v=(12, 25), mat=3, frame=2),
            dict(face='+y', u=(x0 + 54, x0 + 70), v=(12, 25), mat=3, frame=2)]
        s.add(box(x0, x1, y0, y1, 0, 34, mats, wall_tex(feats, plinth=(3.5, 5))))
        s.add(hip(x0 - 5, x1 + 5, y0 - 5, y1 + 5, 33, 58, mats=[R, W], tex=rt))
        _teras(s, x1, yc - 6, yc + 20, R, seed)
        bush_ys = (yc + 24, yc + 31, yc + 38)
        ant = (x0 + 34, yc + 14 - (seed % 2) * 20, 34, 72)
    elif kind == 'pelana':
        y0, y1 = yc - 36, yc + 36
        feats = [
            dict(face='+x', u=(yc + 10, yc + 22), v=(2, 25), mat=1, frame=2, kind='door', handle=4),
            dict(face='+x', u=(yc - 26, yc - 4), v=(12, 25), mat=3, frame=2),
            dict(face='+x', u=(yc - 4, yc + 4), v=(42, 48), mat=4, frame=2, kind='nako'),   # lubang angin di segitiga
            dict(face='+y', u=(x0 + 18, x0 + 34), v=(12, 25), mat=3, frame=2),
            dict(face='+y', u=(x0 + 54, x0 + 70), v=(12, 25), mat=3, frame=2)]
        tex = wall_tex(feats, plinth=(3.5, 5))
        s.add(box(x0, x1, y0, y1, 0, 34, mats, tex))
        # atap pelana, bubungan tegak lurus jalan; dinding segitiga ikut warna dinding
        s.add(gable(x0 - 4, x1 + 4, y0 - 5, y1 + 5, 34, 62, 'x', mats=[R, W], tex=rt))
        s.add(gable(x0, x1, y0, y1, 34, 59, 'x', mats=mats, tex=tex, part=s.prims[-1].part))
        _teras(s, x1, yc + 4, yc + 30, R, seed, kind='dak', h=26)
        bush_ys = (yc - 30, yc - 22)
        ant = (x0 + 30, yc - 12, 50, 80)
    else:  # sayap
        xb = x1 - 16                       # badan utama mundur
        feats = [
            dict(face='+x', u=(yc + 6, yc + 18), v=(2, 25), mat=1, frame=2, kind='door', handle=4),
            dict(face='+x', u=(yc + 24, yc + 38), v=(12, 25), mat=3, frame=2),
            dict(face='+y', u=(x0 + 18, x0 + 34), v=(12, 25), mat=3, frame=2),
            dict(face='+y', u=(x0 + 54, x0 + 70), v=(12, 25), mat=3, frame=2)]
        s.add(box(x0, xb, y0, y1, 0, 34, mats, wall_tex(feats, plinth=(3.5, 5))))
        s.add(hip(x0 - 5, xb + 5, y0 - 5, y1 + 5, 33, 56, mats=[R, W], tex=rt))
        # ruang depan menonjol di sisi kiri, segitiga atap menghadap jalan
        wy0, wy1 = y0, yc - 2
        wf = [dict(face='+x', u=(wy0 + 8, wy1 - 8), v=(10, 25), mat=3, frame=2, kind='window'),
              dict(face='+y', u=(xb + 2, x1 - 3), v=(12, 24), mat=3, frame=2)]
        wt = wall_tex(wf, plinth=(3.5, 5))
        s.add(box(xb - 2, x1, wy0, wy1, 0, 33, mats, wt))
        s.add(gable(xb - 6, x1 + 4, wy0 - 3, wy1 + 3, 33, 52, 'x', mats=[R, W], tex=rt))
        s.add(gable(xb - 2, x1, wy0, wy1, 33, 50, 'x', mats=mats, tex=wt, part=s.prims[-1].part))
        _teras(s, xb, yc + 2, yc + 26, R, seed, h=26)
        bush_ys = (yc + 30, yc + 37)
        ant = (x0 + 30, yc + 20, 34, 70)
    for i, py in enumerate(bush_ys):
        bush(s, x1 + 4, py, 4.2, seed=seed * 7 + i)
    pot_plant(s, x1 + 3, yc - 3 if kind != 'pelana' else yc + 1, 2.6, seed=seed)
    kotak_surat(s, -EDGE[1] - 5, yc + 24)
    if carport_car:
        car(s, x1 + 26, yc - 29, body=Mat('#9CC4E4', '#6C9CC8', '#46688E'), length=50, width=22)
    if seed % 3 != 1:
        antena(s, *ant, seed=seed)


def house_near(s, yc, wall, roof, seed=0):
    W, R = P[wall], P[roof]
    x0, x1 = NX0, NX1
    y0, y1 = yc - 40, yc + 40
    feats = [
        dict(face='+x', u=(yc - 6, yc + 4), v=(2, 22), mat=1, frame=2, kind='door', handle=4),
        dict(face='+x', u=(yc + 14, yc + 26), v=(13, 22), mat=3, frame=2, kind='nako'),
        dict(face='+x', u=(yc - 30, yc - 20), v=(15, 22), mat=3, frame=2, kind='nako'),
        dict(face='+y', u=(x0 + 22, x0 + 36), v=(12, 24), mat=3, frame=2),
        dict(face='+y', u=(x0 + 52, x0 + 66), v=(12, 24), mat=3, frame=2),
    ]
    mats = [W, P['wood'], P['white'], P['glass'], P['metal_dk'], P['conc']]
    s.add(box(x0, x1, y0, y1, 0, 32, mats, wall_tex(feats, plinth=(3.5, 5))))
    rt = roof_tex('genteng', seed + 9, wall=True)
    k = seed % 3
    if k == 0:
        s.add(hip(x0 - 5, x1 + 5, y0 - 5, y1 + 5, 31, 54, mats=[R, W], tex=rt))
    elif k == 1:
        s.add(gable(x0 - 4, x1 + 4, y0 - 5, y1 + 5, 32, 56, 'x', mats=[R, W], tex=rt))
        s.add(gable(x0, x1, y0, y1, 32, 53, 'x', mats=W, part=s.prims[-1].part))
    else:
        s.add(gable(x0 - 5, x1 + 5, y0 - 4, y1 + 4, 32, 52, 'y', mats=[R, W], tex=rt))
        s.add(gable(x0, x1, y0, y1, 32, 50, 'y', mats=W, part=s.prims[-1].part))
    s.add(shed(x1, x1 + 12, yc - 12, yc + 10, 25, 22, '+x', 1.5, mats=P['metal'], tex=roof_tex('seng')))
    if seed % 2 == 0:
        antena(s, x0 + 50, yc - 8, 32, 68, seed=seed + 20)
    for py in (yc - 11, yc + 8):
        s.add(box(x1 + 10, x1 + 11.5, py, py + 1.5, 0, 22, P['metal_dk']))


def build(s, car_on=True):
    mats = [P['grass'], P['asph'], P['mark'], P['conc']]
    s.add(ground_prim(region, mats))
    far_gaps = [far_drive(yc) for yc in FAR_YC]
    near_gaps = [near_drive(yc) for yc in NEAR_YC]
    for sg, gaps in ((-1, far_gaps), (1, near_gaps)):
        a, b = (SEP if sg > 0 else (-SEP[1], -SEP[0]))
        kerb_with_gaps(s, a, b, 3, P['kerb'], gaps)
        a, b = (BIKE if sg > 0 else (-BIKE[1], -BIKE[0]))
        s.add(box(a, b, -900, 900, 0, 2, [BIKE_MAT, P['mark']], bike_tex, outline=False, cast=False))
        a, b = (EDGE if sg > 0 else (-EDGE[1], -EDGE[0]))
        kerb_with_gaps(s, a, b, 2.6, P['kerb'], gaps)
    for i, yc in enumerate(FAR_YC):
        house_far(s, yc, WALLS[i], ROOFS[i], seed=i, carport_car=(i == 3), kind=HOUSE_TYPES[i % 3])
        # pohon di halaman samping, bergantian tiga jenis; sesekali cuma semak
        if i % 4 != 3:
            tree_perumahan(s, FX1 - 26, yc + 64, TREE_KINDS[i % 3], seed=i)
        else:
            bush(s, FX1 - 10, yc + 62, 6, seed=i)
            bush(s, FX1 - 22, yc + 70, 5, seed=i + 3)
    for i, yc in enumerate(NEAR_YC):
        house_near(s, yc, WALLS[(i + 3) % 8], ROOFS[(i + 2) % 8], seed=i)
        bush(s, NX0 - 10, yc + 10, 5, seed=20 + i)
        if i % 2 == 1:
            tree_perumahan(s, NX1 + 30, yc + 54, TREE_KINDS[(i + 1) % 3], seed=30 + i)
    # deret rumah di belakang sisi seberang
    for i, yc in enumerate([-420, -300, -180, -60, 60, 180]):
        s.add(box(FX0 - 146, FX0 - 64, yc - 40, yc + 40, 0, 32, P[WALLS[(i + 5) % 8]]))
        s.add(hip(FX0 - 151, FX0 - 59, yc - 45, yc + 45, 31, 54, mats=[P[ROOFS[(i + 1) % 8]], P['cream']],
                  tex=roof_tex('genteng', 40 + i, wall=True)))
        if i % 2 == 1:
            antena(s, FX0 - 100, yc + 10, 32, 68, seed=40 + i)
    for i, yc in enumerate([-370, -250, -130, -10, 110]):
        tree_perumahan(s, FX0 - 34, yc, TREE_KINDS[(i + 2) % 3], seed=50 + i)
    s.add(box(NX1 + 50, NX1 + 54, -900, 900, 0, 14, P['conc']))
    # lampu jalan di tepi luar lajur sepeda sisi seberang, menerangi lajur
    for ly in (-256, 0, 256):
        lamp_post(s, -EDGE[1] - 3, ly, h=58, arm=15, toward=+1, light_r=100)
    tong_sampah(s, EDGE[1] + 5, -40)
    tong_sampah(s, EDGE[1] + 5, 210, Mat('#F0A24E', '#D97D2E', '#9A5420'))
    if car_on:
        car(s, RD - 15, -120, body=Mat('#F2F2F4', '#CFD2DA', '#8E94A2'))


def render_time(tname, scale=1, out=None, crop=None, W=640, H=360, ox=427, oy=172):
    s = Scene(W, H, ox, oy)
    build(s)
    tc = TIMES[tname]
    px, py, _ = PLAYER
    spr = loper_frame(0, 0)
    if tc.lights_on:
        s.lights.append(Light((px + 4, py - 33, 1), 34, '#FFE6A8', 1.0, flat=0.5))
    s.render(tc)
    img = finish_with_sprites(s, [(spr, (23, 46), PLAYER)])
    if tc.lights_on:
        sx, sy = s.proj((px + 1, py - 14, 13))
        X, Y = int(sx[0]), int(sy[0])
        img[Y, X:X + 2] = (255, 236, 170)
    s.img = img
    im = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), 'RGB')
    if crop:
        im = im.crop(crop)
    if scale != 1:
        im = im.resize((im.width * scale, im.height * scale), Image.NEAREST)
    if out:
        im.save(out)
    return im, s


if __name__ == '__main__':
    import time
    for tn in sys.argv[1:] or ['siang']:
        t = time.time()
        render_time(tn, 2, OUT / f'perumahan_{tn}.png')
        print(tn, round(time.time() - t, 1))
