"""Six district vignettes (usulan): same pixel style, own palette + light colour grading."""
import math, sys, json
import numpy as np
from PIL import Image
from engine import *
from lib import *
import perumahan as PR
import kampung as KP
from kampung import K, text_mask

OUTD = str(PR.OUT) + '/'
VW, VH = 400, 250


def grade_cfg(sun, shade=None, name='siang'):
    b = TIMES['siang']
    sun = np.array(sun, np.float32)
    shade = b.shade * sun if shade is None else np.array(shade, np.float32)
    return TimeCfg(name, 50, sun, shade)


def save(img, name, scale=2):
    im = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), 'RGB')
    im.resize((im.width * scale, im.height * scale), Image.NEAREST).save(OUTD + name)
    return im


# ------------------------------------------------------------------ ruko
RK = dict(
    beton=Mat('#D2D0CC', '#BDBAB5', '#97948F'),
    beton2=Mat('#C8C2B6', '#B2AB9E', '#8C8578'),
    roll=Mat('#B8BCC4', '#9CA0AA', '#70747E'),
    dalam=Mat('#4A4048', '#3A3038', '#262028'),
    s_red=Mat('#F06A4E', '#D94F3D', '#8E2E25'), s_yel=Mat('#FFE08A', '#FFC94A', '#C98E2A'),
    s_blu=Mat('#7FB2E0', '#3F7FC4', '#2A5688'), s_grn=Mat('#8FD49A', '#4FA466', '#2F7046'),
    angkot=Mat('#B6E4F2', '#7CC6E2', '#4A8EAE'),
    trotoar=Mat('#D8CFC2', '#C8BDAE', '#A69A8A'),
)


RR = 48   # setengah lebar aspal ruko: 2 lajur @ 48 (sebelumnya 40)


def ruko_region(x, y):
    n = len(x)
    mi = np.zeros(n, int)
    sh = 1 + speckle(x, y, 5, 0.03, 0.05, 1)
    lane = (np.abs(x) < 1.2) & (np.mod(y, 28) < 14)                        # garis tengah putus-putus
    edge = np.abs(np.abs(x) - (RR - 3)) < 0.6
    mi = np.where(lane | edge, 1, mi)
    side = np.abs(x) >= RR
    mi = np.where(side, 2, mi)
    sh = np.where(side, 1 + np.where((np.mod(y, 12) < 0.9) | (np.mod(x, 12) < 0.9), 1, 0), sh)
    return mi, sh


SIGNS = [('TOKO', 's_red'), ('BAKSO', 's_yel'), ('FOTO', 's_blu'), ('JAHIT', 's_grn'), ('SERVIS', 's_red'),
         ('EMAS', 's_yel'), ('TOKO', 's_blu')]


def ruko_unit(s, y0, y1, open_=True, sign=('TOKO', 's_red'), seed=0, h=64):
    x1, x0 = -56, -136
    yc = (y0 + y1) / 2
    feats = [dict(face='+x', u=(y0 + 4, y1 - 4), v=(0, 24), mat=(2 if open_ else 1), kind=None if open_ else 'roll'),
             dict(face='+x', u=(y0 + 6, yc - 2), v=(38, 52), mat=3, frame=4),
             dict(face='+x', u=(yc + 2, y1 - 6), v=(38, 52), mat=3, frame=4),
             dict(face='+y', u=(x0 + 14, x0 + 30), v=(38, 52), mat=3, frame=4)]

    def goods(Pw, Nw, u, v, code, mi, sh):
        ins = (mi == 2) & (code == 1)
        shelf = ins & (np.mod(v, 7) < 1)
        item = ins & ~shelf & (np.mod(v, 7) > 2.5) & (v < 21) & (hash2(np.floor(u / 1.6), np.floor(v / 7), seed) > 0.3)
        col = 5 + (hash2(np.floor(u / 1.6), np.floor(v / 7), seed + 2) * 4).astype(int)
        mi = np.where(shelf, 4, mi)
        mi = np.where(item, col, mi)
        return mi, sh
    mats = [RK['beton'], RK['roll'], RK['dalam'], P['glass'], P['white'], RK['s_red'], RK['s_yel'], RK['s_blu'], RK['s_grn']]
    s.add(box(x0, x1, y0, y1, 0, h, mats, wall_tex(feats, plinth=None, extra=goods)))
    # floor slab / canopy between floors
    s.add(box(x1, x1 + 8, y0, y1, 28, 30, RK['beton2']))
    # parapet
    s.add(box(x0, x1 + 1, y0, y1, h, h + 5, RK['beton2'],
              lambda Pw, Nw: (0, np.where((Nw[:, 2] > 0.5) & ((np.mod(Pw[:, 0], 10) < 0.8) | (np.mod(Pw[:, 1], 10) < 0.8)), 1, 0))))
    if seed % 3 != 2:
        antena(s, x0 + 56, y0 + 14, h, h + 26, seed=seed + 70)
    if seed % 2 == 0:
        s.add(cyl((x0 + 30, y0 + 22), 6, h + 5, h + 17, mats=[K['toren_o'], K['toren_b']][seed % 4 // 2]))
    else:
        s.add(box(x0 + 20, x0 + 34, y0 + 10, y0 + 30, h + 5, h + 12, P['white']))
    # sign board on the canopy edge
    txt, sm = sign
    s.add(box(x1 + 6, x1 + 8, y0 + 3, y1 - 3, 30, 37, [RK[sm], P['white']],
              lambda Pw, Nw, t=txt, a=y1 - 3: (np.where(text_mask(t, -Pw[:, 1], Pw[:, 2], -a + 3, 35.5) & (Nw[:, 0] > 0.5), 1, 0), 0)))
    # AC unit on the upper side
    if seed % 2:
        s.add(box(x1, x1 + 3, y0 + 8, y0 + 16, 54, 60, P['white']))


def build_ruko(s):
    s.add(ground_prim(ruko_region, [P['asph'], P['mark'], RK['trotoar']]))
    for sg in (-1, 1):
        a, b = (RR, RR + 2) if sg > 0 else (-RR - 2, -RR)
        s.add(box(a, b, -900, 900, 0, 3, P['kerb'], outline=False, cast=False))
        a, b = (RR + 2, RR + 16) if sg > 0 else (-RR - 16, -RR - 2)
        s.add(box(a, b, -900, 900, 0, 2.5, RK['trotoar'],
                  lambda Pw, Nw: (0, np.where(Nw[:, 2] > 0.5, 1 + ((np.mod(Pw[:, 1], 12) < 0.9) | (np.mod(Pw[:, 0], 12) < 0.9)), 0)),
                  outline=False, cast=False))
    i0 = len(s.prims)
    ys = np.arange(-300, 260, 44)
    for i, y0 in enumerate(ys):
        ruko_unit(s, y0, y0 + 44, open_=(i % 3 != 1), sign=SIGNS[i % len(SIGNS)], seed=i)
    shift_prims(s.prims[i0:], -(RR - 40))
    i0 = len(s.prims)
    # near side: halte, kios kecil, pohon peneduh, parkiran
    s.add(box(44, 58, 10, 54, 0, 2, RK['trotoar'], outline=False, cast=False))
    for (a, b) in ((54, 12), (54, 50)):
        s.add(box(a, a + 1.5, b, b + 1.5, 0, 26, P['metal_dk']))
    s.add(shed(42, 60, 8, 56, 28, 25, '-x', 1.2, mats=RK['s_blu']))
    bench(s, 50, 54, 18, 46, h=8, mat=P['metal'])
    for i, y0 in enumerate((-220, -120, 90, 180)):
        c = [RK['s_yel'], RK['s_grn'], RK['s_red'], RK['s_blu']][i]
        s.add(box(72, 96, y0, y0 + 30, 0, 22, [c, RK['dalam'], P['white']],
                  wall_tex([dict(face='+y', u=(76, 92), v=(8, 18), mat=1, frame=2)])))
        s.add(shed(70, 98, y0 - 2, y0 + 32, 25, 30, '+x', 1.2, mats=[K['seng'], K['seng'], K['karat']], tex=roof_tex('seng', 9 + i, rust=0.2)))
    for ty in (-170, -60, 140, 240):
        tree_round(s, 66, ty, r=12, h=24, seed=int(ty) & 255)
    shift_prims(s.prims[i0:], RR - 40)
    for i, my in enumerate(np.arange(-150, 150, 22)):
        motor(s, -(RR + 8) if i % 2 else RR + 8, my, body=[P['red'], P['blue'], P['metal_dk'], RK['s_yel']][i % 4])
    # angkot di lajur dekat
    angkot(s, 30, -40, body=RK['angkot'], front=1)
    bus_kecil(s, -26, 70, front=-1)
    # gerobak kaki lima di trotoar seberang
    gx0 = -RR - 14
    s.add(box(gx0, gx0 + 10, 70, 90, 6, 18, [P['white'], RK['s_red']], wall_tex([dict(face='+x', u=(70, 90), v=(14, 16), mat=1)])))
    s.add(box(gx0, gx0 + 10, 70, 90, 18, 26, P['glass_off']))
    s.add(cyl((80, 5), 5, gx0 - 1, gx0 + 11, axis=0, mats=P['metal_dk']))
    s.add(cyl((gx0 + 5, 80), 0.8, 26, 40, mats=P['metal_dk']))
    s.add(ellip((gx0 + 5, 80, 40), (12, 12, 4), RK['s_blu'], zmin=40))
    lamp_post(s, -RR - 8, -110, h=60, arm=14, toward=+1)


# ------------------------------------------------------------------ pasar
PS = dict(
    lantai=Mat('#8E8A8E', '#77727A', '#5A5660'),
    genangan=Mat('#A9C4D2', '#7E9AAE', '#56708A'),
    meja=Mat('#C99A6A', '#A87A4A', '#76532E'),
    tp_b=Mat('#6FAEE8', '#3E86CF', '#2A5E96'),
    tp_o=Mat('#FFB061', '#EE8A32', '#AD5C1C'),
    tp_g=Mat('#8FD49A', '#4FA466', '#2F7046'),
    tomat=Mat('#FF7A5E', '#E2533B', '#9C2E22'),
    sayur=Mat('#A6E07A', '#6FBF4A', '#3E8A2E'),
    jeruk=Mat('#FFC46A', '#F29A2E', '#B4661A'),
    ikan=Mat('#DDE6EE', '#B2C2D2', '#7C8FA2'),
    keranjang=Mat('#E2C48A', '#C9A464', '#8E7040'),
    kerat=Mat('#7FB2E0', '#3F7FC4', '#2A5688'),
)


def pasar_region(x, y):
    n = len(x)
    mi = np.zeros(n, int)
    wet = vnoise(x, y, 14, 21) > 0.68
    mi = np.where(wet, 1, mi)
    sh = 1 + speckle(x, y, 3, 0.05, 0.08, 1)
    sh = np.where(wet, np.where(hash2(np.floor(x / 3), np.floor(y / 2), 2) > 0.88, 0, 1), sh)
    tile = (np.mod(x, 16) < 0.8) | (np.mod(y, 16) < 0.8)
    sh = np.where(tile & ~wet, 2, sh)
    return mi, sh


def lapak(s, x0, x1, y0, y1, goods, tarp, seed=0, roof_down='+x', tall=True):
    s.add(box(x0, x1, y0, y1, 9, 11, PS['meja']))
    for (a, b) in ((x0, y0), (x1 - 1.2, y0), (x0, y1 - 1.2), (x1 - 1.2, y1 - 1.2)):
        s.add(box(a, a + 1.2, b, b + 1.2, 0, 9, PS['meja']))
    rng = np.random.default_rng(seed)
    gx = np.arange(x0 + 3, x1 - 2, 5)
    gy = np.arange(y0 + 3, y1 - 2, 5)
    for i, a in enumerate(gx):
        for j, b in enumerate(gy):
            g = goods[(i + j) % len(goods)]
            r = 2.2 + rng.random() * 0.6
            s.add(ellip((a, b, 11), (r, r, r * 0.8), PS[g], zmin=11))
    if tall:
        for (a, b) in ((x0 - 1, y0 - 1), (x1, y0 - 1), (x0 - 1, y1), (x1, y1)):
            s.add(cyl((a, b), 0.7, 0, 30, mats=K['batang']))

        def stripes(Pw, Nw, t=tarp):
            return (np.mod(Pw[:, 1] + Pw[:, 0] * 0, 10) < 5).astype(int) * (len(t) > 1), 0
        s.add(shed(x0 - 4, x1 + 4, y0 - 4, y1 + 4, 32, 26, roof_down, 0.8, mats=[PS[t] for t in tarp], tex=stripes))


def build_pasar(s):
    s.add(ground_prim(pasar_region, [PS['lantai'], PS['genangan']]))
    PD = 16   # lorong dilebarkan 2 x 16: 88 -> 120
    i0 = len(s.prims)
    # far side los (permanent stalls) with seng roof
    for i, y0 in enumerate(np.arange(-300, 300, 46)):
        lapak(s, -70, -44, y0 + 4, y0 + 40, [['tomat', 'sayur'], ['jeruk'], ['ikan'], ['sayur', 'jeruk'], ['tomat']][i % 5],
              [('tp_b', 'tp_o'), ('tp_b',), ('tp_o',), ('tp_g', 'tp_b')][i % 4], seed=i)
        s.add(box(-150, -84, y0, y0 + 44, 0, 34, [K['putih'], RK['roll'], RK['dalam']],
                  wall_tex([dict(face='+x', u=(y0 + 6, y0 + 38), v=(0, 24), mat=2 if i % 2 else 1, kind=None if i % 2 else 'roll')])))
        s.add(shed(-154, -80, y0 - 1, y0 + 45, 46, 34, '+x', 1.5, mats=[K['seng'], K['seng'], K['karat']],
                   tex=roof_tex('seng', 120 + i, rust=0.25)))
    shift_prims(s.prims[i0:], -PD)
    i0 = len(s.prims)
    # near side stalls: low tables + umbrellas
    for i, y0 in enumerate(np.arange(-280, 300, 52)):
        lapak(s, 44, 66, y0, y0 + 30, [['jeruk', 'tomat'], ['sayur'], ['ikan', 'sayur']][i % 3], [('tp_o',)], seed=40 + i,
              tall=False)
        s.add(cyl((55, y0 + 15), 0.7, 11, 34, mats=P['metal_dk']))
        s.add(ellip((55, y0 + 15, 34), (16, 16, 5), [PS['tp_b'], PS['tp_o'], PS['tp_g']][i % 3], zmin=34))
    shift_prims(s.prims[i0:], PD)
    # baskets + crates in the lane
    for (bx, by) in ((-50, -40), (-46, 60), (46, 10), (-52, 150), (50, -150)):
        s.add(cyl((bx, by), 4.5, 0, 7, mats=PS['keranjang'],
                  tex=lambda Pw, Nw: (0, np.where(np.mod(Pw[:, 2] + np.arctan2(Pw[:, 1] - 0, Pw[:, 0]) * 3, 2.5) < 1, 1, 0))))
    for (bx, by) in ((-54, 10), (52, 100), (-52, -150)):
        s.add(box(bx - 5, bx + 5, by - 7, by + 7, 0, 8, PS['kerat'],
                  lambda Pw, Nw: (0, np.where((np.mod(Pw[:, 2], 4) < 1) & (np.abs(Nw[:, 2]) < 0.5), 1, 0))))
    # becak parked
    s.add(box(14, 32, -100, -84, 6, 18, P['red']))
    s.add(shed(13, 33, -102, -88, 30, 26, '-y', 1, mats=P['blue']))
    for wy in (-100, -84):
        s.add(cyl((wy, 6), 6, 12, 13, axis=0, mats=P['metal_dk']))
    s.add(cyl((-110, 6), 6, 22, 23, axis=0, mats=P['metal_dk']))


# ------------------------------------------------------------------ desa
DS = dict(
    tanah=Mat('#D2A874', '#B88A56', '#8A643C'),
    sawah=Mat('#B6E06A', '#8CC84A', '#5E9A34'),
    air=Mat('#B8E2EC', '#86C2D4', '#5A97AC'),
    pematang=Mat('#B89A6A', '#9A7E52', '#6E5838'),
    kayu=Mat('#C99A6A', '#A87A4A', '#6E4A2A'),
    atap=Mat('#9A7A5E', '#7A5C44', '#523C2C'),
    kelapa=Mat('#B4DC6A', '#7DB446', '#46782E'),
    batang=Mat('#B4987A', '#94785A', '#665038'),
    gabah=Mat('#F6DC8A', '#E6C062', '#B8923A'),
    terpal=Mat('#7FB2E0', '#3F7FC4', '#2A5688'),
)


DD = 10   # jalan desa dilebarkan 2 x 10: 44 -> 64


def desa_region(x, y):
    n = len(x)
    ax = np.abs(x)
    mi = np.full(n, 1)                 # sawah
    sh = np.ones(n, int)
    rows = np.mod(x + y * 0.0, 4) < 1.2
    young = hash2(np.floor(x / 40), np.floor(y / 48), 5) > 0.55
    sh = np.where(rows, 2, 1)
    mi = np.where(young & ~rows, 2, mi)  # flooded young field shows water between rows
    sh = np.where(young & ~rows, np.where(hash2(np.floor(x / 3), np.floor(y / 2), 3) > 0.9, 0, 1), sh)
    road = ax < 22 + DD
    track = road & (np.abs(ax - 13) < 3)
    mi = np.where(road, 0, mi)
    sh = np.where(road, np.where(track, 2, 1) + speckle(x, y, 4, 0.05, 0.06, 2) * (~track), sh)
    shoulder = (ax >= 22 + DD) & (ax < 30 + DD)
    mi = np.where(shoulder, 3, mi)
    sh = np.where(shoulder, 1 + grass_tufts(x, y, 9), sh)
    parit = (x >= 30 + DD) & (x < 38 + DD)
    mi = np.where(parit, 2, mi)
    sh = np.where(parit, 1, sh)
    return mi, sh


def coconut(s, x, y, h=56, lean=(0.18, 0.05), seed=0, fronds=8):
    """Pohon kelapa: batang melengkung bercincin, pelepah melengkung turun dengan anak daun berbentuk V."""
    rng = np.random.default_rng(seed)
    pid = None
    # batang: tumpukan silinder pendek mengikuti lengkung, makin ke atas makin ramping
    n = int(h // 3.5)
    for i in range(n):
        t0, t1 = i / n, (i + 1) / n
        cx = x + lean[0] * h * t0 ** 1.6
        cy = y + lean[1] * h * t0 ** 1.6
        r = 2.3 - 0.8 * t0
        s.add(cyl((cx, cy), r, h * t0, h * t1 + 0.4, mats=DS['batang'],
                  tex=lambda Pw, Nw, z0=h * t0: (0, np.where(Pw[:, 2] - z0 < 0.9, 1, 0)), part=pid))
        pid = s.prims[-1].part
    top = np.array([x + lean[0] * h, y + lean[1] * h, h])
    up = np.array([0, 0, 1.0])
    mat = DS['kelapa']
    crown = None
    for i in range(fronds):
        yaw = 2 * math.pi * i / fronds + rng.random() * 0.35
        hd = np.array([math.cos(yaw), math.sin(yaw), 0.0])
        side = np.array([-hd[1], hd[0], 0.0])
        L = 28 + rng.random() * 6
        rise = 0.32 + rng.random() * 0.12 if i % 2 else 0.18 + rng.random() * 0.1
        drop = 0.8 + rng.random() * 0.25
        segs = 6
        pts = []
        for k in range(segs + 1):
            t = k / segs
            pts.append(top + hd * L * t + up * L * (rise * t - drop * t * t))
        for k in range(segs):
            a, b = pts[k], pts[k + 1]
            c = (a + b) / 2
            ax = b - a
            seg = np.linalg.norm(ax)
            ax = ax / seg
            tm = (k + 0.5) / segs
            w = max(2.0, 5.2 * math.sin(math.pi * min(0.95, tm * 0.9 + 0.12)))
            sd = np.cross(ax, up); sd /= max(np.linalg.norm(sd), 1e-6)
            # pelepah (tulang daun)
            s.add(obox(c, ax, sd, np.cross(ax, sd), seg / 2 + 0.3, 0.45, 0.45, mat, part=crown))
            crown = s.prims[-1].part
            # anak daun: helai tipis miring ke depan dan turun, berselang supaya ada celah
            for j in range(3):
                base = a + ax * seg * (j + 0.5) / 3
                for sg in (-1, 1):
                    v = sd * sg * 0.8 - up * 0.45 + ax * 0.45
                    v /= np.linalg.norm(v)
                    nv = np.cross(v, ax); nv /= max(np.linalg.norm(nv), 1e-6)
                    s.add(obox(base + v * w / 2, v, nv, np.cross(v, nv), w / 2, 0.55, 0.3, mat, part=crown))
    # buah kelapa di bawah mahkota
    buah = Mat('#9CB04A', '#6E8A34', '#4A5E24')
    for i in range(4):
        a = i * 1.7
        s.add(ellip(top + np.array([math.cos(a) * 2.2, math.sin(a) * 2.2, -2.8 - (i % 2)]), (1.8, 1.8, 1.9), buah, part=pid))


def build_desa(s):
    s.add(ground_prim(desa_region, [DS['tanah'], DS['sawah'], DS['air'], P['grass']]))
    # pematang (dikes)
    for yy in np.arange(-400, 400, 48):
        for (a, b) in ((-400, -30 - DD), (38 + DD, 400)):
            s.add(box(a, b, yy - 1.5, yy + 1.5, 0, 2, DS['pematang'], outline=False, cast=False))
    for xx in (-110 - DD, -190 - DD, 118 + DD, 198 + DD):
        s.add(box(xx - 1.5, xx + 1.5, -400, 400, 0, 2, DS['pematang'], outline=False, cast=False))
    i0 = len(s.prims)
    # rumah kayu (far side)
    x1, x0, y0, y1 = -40, -96, -60, -4
    s.add(box(x0, x1, y0, y1, 0, 3, DS['pematang']))
    s.add(box(x0, x1, y0, y1, 3, 30, [DS['kayu'], K['kayu_dk'], P['white'], P['glass_off']],
              wall_tex([dict(face='+x', u=(-30, -20), v=(3, 24), mat=1, frame=2, kind='door'),
                        dict(face='+x', u=(-54, -42), v=(12, 22), mat=3, frame=2),
                        dict(face='+y', u=(-86, -74), v=(12, 22), mat=3, frame=2)],
                       extra=lambda Pw, Nw, u, v, code, mi, sh: (mi, np.where((mi == 0) & (np.mod(v, 3) < 0.9), sh + 1, sh)))))
    s.add(gable(x0 - 4, x1 + 6, y0 - 4, y1 + 4, 30, 54, 'y', mats=[DS['atap'], DS['kayu']], tex=roof_tex('genteng', 4, wall=True)))
    # gabah drying on a tarp beside the road
    s.add(box(-36, -24, 20, 60, 0, 0.8, [DS['terpal'], DS['gabah']],
              lambda Pw, Nw: ((np.abs(Pw[:, 0] + 30) < 5).astype(int) * ((Pw[:, 1] > 22) & (Pw[:, 1] < 58)), speckle(Pw[:, 0], Pw[:, 1], 6, 0.1, 0.1, 1)),
              outline=False, cast=False))
    coconut(s, -60, 40, h=58, seed=1)
    coconut(s, -120, -110, h=64, lean=(-0.1, 0.12), seed=2)
    shift_prims(s.prims[i0:], -DD)
    i0 = len(s.prims)
    coconut(s, 70, 120, h=50, lean=(0.12, -0.1), seed=3)
    # gubuk sawah (near side)
    for (a, b) in ((96, -70), (114, -70), (96, -52), (114, -52)):
        s.add(box(a, a + 1.5, b, b + 1.5, 0, 26, DS['batang']))
    s.add(box(96, 115.5, -70, -50.5, 8, 10, DS['kayu']))
    s.add(gable(92, 120, -74, -46, 26, 36, 'y', mats=[DS['atap'], DS['kayu']], tex=roof_tex('genteng', 5, wall=True)))
    # jembatan bambu over the parit
    s.add(box(28, 40, -10, 2, 1, 2.5, DS['batang'],
              lambda Pw, Nw: (0, np.where(np.mod(Pw[:, 1], 2) < 0.7, 1, 0)), outline=True))
    shift_prims(s.prims[i0:], DD)
    # kerbau
    kb = Mat('#7E7A86', '#5E5A66', '#3E3A46')
    s.add(ellip((10, -60, 9), (6, 11, 6), kb))
    pid = s.prims[-1].part
    s.add(ellip((10, -73, 10), (3.6, 4.2, 3.6), kb, part=pid))
    for (a, b) in ((-3, -6), (3, -6), (-3, 6), (3, 6)):
        s.add(box(10 + a - 1, 10 + a + 1, -60 + b - 1, -60 + b + 1, 0, 6, kb, part=pid))
    s.add(obox((10, -74, 14.5), (1, 0, 0.3), (0, 1, 0), (0, 0, 1), 6.5, 0.7, 0.7, Mat('#F2E7C9', '#D8C9A6', '#A8986F'), part=pid))


# ------------------------------------------------------------------ sungai
SG = dict(
    air=Mat('#7FD0D0', '#4FAFB4', '#2F8088'),
    tebing=Mat('#B8A07E', '#9A8260', '#6E5C42'),
    kayu=Mat('#C99A6A', '#A87A4A', '#6E4A2A'),
    kayu2=Mat('#B07A50', '#8A5A38', '#5E3C24'),
    atap=Mat('#9EA8B4', '#7E8896', '#58606C'),
    perahu=Mat('#F2E7C9', '#5F96C8', '#3E6A96'),
    perahu2=Mat('#F06A4E', '#D94F3D', '#8E2E25'),
)


SX0, SX1 = -36, 26       # jalan semen tepi sungai (sedikit dilebarkan)
SBANK, SDEEP, SRUN = 32, 18, 12   # bibir tebing, kedalaman muka air, lebar talud miring


def sungai_region(x, y):
    n = len(x)
    mi = np.zeros(n, int)                    # jalan semen
    sh = 1 + speckle(x, y, 3, 0.04, 0.05, 1)
    sh = np.where(np.mod(y, 36) < 0.8, 2, sh)
    grass = (x < SX0) | (x >= SX1)
    mi = np.where(grass, 1, mi)
    sh = np.where(grass, 1 + grass_tufts(x, y, 5), sh)
    return mi, sh


def water_tex(Pw, Nw):
    x, y = Pw[:, 0], Pw[:, 1]
    rip = hash2(np.floor((x + np.sin(y * 0.08) * 3) / 6), np.floor(y / 2), 8) > 0.9
    edge = x < SBANK + SRUN + 3
    return 0, np.where(edge & (np.mod(y, 7) < 4), 0, np.where(rip, 0, np.where(x > 160, 2, 1)))


def talud_tex(Pw, Nw):
    """Batu kali bersemen pada talud miring; bagian bawah basah lebih gelap."""
    z, y = Pw[:, 2], Pw[:, 1]
    row = np.floor(z / 3.0)
    mortar = (np.mod(z, 3.0) < 0.8) | (np.mod(y + row * 2.7, 5.5) < 0.9)
    wet = z < -SDEEP + 4
    return 0, np.where(mortar, 1, 0) + np.where(wet, 1, 0)


def rumah_panggung(s, y0, y1, wall, seed=0):
    x1, x0 = -36, -98
    for a in np.arange(x0, x1, 15):
        for b in (y0, (y0 + y1) / 2, y1 - 1.5):
            s.add(box(a, a + 1.6, b, b + 1.6, 0, 14, SG['kayu2']))
    s.add(box(x0, x1 + 8, y0, y1, 14, 16, SG['kayu']))
    W = wall
    s.add(box(x0, x1, y0, y1, 16, 42, [W, K['kayu_dk'], P['white'], P['glass_off']],
              wall_tex([dict(face='+x', u=(y0 + 8, y0 + 18), v=(16, 36), mat=1, frame=2, kind='door'),
                        dict(face='+x', u=(y1 - 20, y1 - 8), v=(24, 34), mat=3, frame=2),
                        dict(face='+y', u=(x0 + 10, x0 + 22), v=(24, 34), mat=3, frame=2)],
                       extra=lambda Pw, Nw, u, v, code, mi, sh: (mi, np.where((mi == 0) & (np.mod(u, 4) < 0.9), sh + 1, sh)))))
    s.add(gable(x0 - 4, x1 + 10, y0 - 3, y1 + 3, 42, 60, 'y', mats=[SG['atap'], W, K['karat']], tex=roof_tex('seng', seed, wall=True, rust=0.15)))
    # railing on the porch
    s.add(box(x1 + 7, x1 + 8, y0, y1, 16, 22, SG['kayu2']))
    # stairs
    for k in range(4):
        s.add(box(x1 + 8 + k * 2.5, x1 + 10.5 + k * 2.5, y1 - 14, y1 - 6, 0, 14 - k * 3.5, SG['kayu2']))


def perahu(s, x, y, zw, L=72, W=16, hull=None, roof=None, seed=0):
    """Klotok: lambung kayu runcing di kedua ujung, geladak papan, garis cat, atap di tengah, mesin di buritan."""
    hull = hull or SG['perahu']
    roof = roof or SG['atap']
    kayu = SG['kayu']
    deck = zw + 3.2
    c = np.array([x, y, zw + 1.0])

    def htex(Pw, Nw):
        top = Nw[:, 2] > 0.9
        pz = Pw[:, 2]
        mi = np.where(top, 1, 0)
        sh = np.where(top & (np.mod(Pw[:, 0] - x, 3) < 0.8), 1, 0)
        band = (~top) & (pz > deck - 1.4)
        mi = np.where(band, 2, mi)
        sh = np.where((~top) & (pz < zw + 0.3), sh + 1, sh)
        return mi, sh
    p = ellip(c, (W / 2, L / 2, 4.6), [hull, kayu, Mat('#FFFFFF', '#F2E7C9', '#C2AF86')], htex, zmin=zw - 1.5)
    p.planes.append((np.array([0, 0, 1.0]), deck))
    p.hi[2] = deck
    s.add(p)
    pid = s.prims[-1].part
    # ujung haluan sedikit naik
    s.add(ellip((x, y - L * 0.42, deck), (W * 0.18, L * 0.1, 2.0), hull, zmin=deck - 1, part=pid))
    # tiang dan atap di tengah
    ry0, ry1 = y - L * 0.18, y + L * 0.2
    for (a, b) in ((x - W * 0.3, ry0), (x + W * 0.3, ry0), (x - W * 0.3, ry1), (x + W * 0.3, ry1)):
        s.add(box(a - 0.6, a + 0.6, b - 0.6, b + 0.6, deck, deck + 11, kayu))
    s.add(gable(x - W * 0.42, x + W * 0.42, ry0 - 3, ry1 + 3, deck + 11, deck + 15, 'y', mats=[roof, roof],
                tex=roof_tex('seng', seed, wall=True)))
    # bangku dan mesin
    s.add(box(x - W * 0.3, x + W * 0.3, y - 2, y + 2, deck, deck + 2.5, kayu))
    s.add(box(x - 2.5, x + 2.5, y + L * 0.32, y + L * 0.32 + 6, deck, deck + 4.5, TRIM))
    s.add(cyl((y + L * 0.44, zw + 0.5), 0.6, x - 0.6, x + 0.6, axis=0, mats=TRIM))


def build_sungai(s):
    s.add(ground_prim(sungai_region, [K['cor'], P['grass']], x=(-900, SBANK)))
    # air jauh di bawah jalan
    s.add(box(SBANK, 900, -900, 900, -80, -SDEEP, SG['air'], water_tex, outline=False, cast=False))
    # talud miring dari bibir jalan ke muka air
    k = SDEEP / SRUN
    s.add(Prim([((k, 0, 1), k * SBANK), ((-1, 0, 0), -SBANK), ((0, 0, -1), SDEEP), ((0, 1, 0), 900), ((0, -1, 0), 900)],
               None, Mat('#BDB3A2', '#9C9282', '#6E665A'), talud_tex,
               aabb=((SBANK, -900, -SDEEP), (SBANK + SRUN, 900, 0)), outline=False))
    # pagar pembatas di bibir sungai, terbuka di dermaga
    for a, b in ((-900, -44), (-20, 900)):
        s.add(box(SBANK - 2, SBANK, a, b, 0, 6, [K['putih'], K['plinth']],
                  lambda Pw, Nw: (np.where(Pw[:, 2] < 2.5, 1, 0), 0)))
    i0 = len(s.prims)
    rumah_panggung(s, -150, -84, Mat('#E8D6A8', '#D2BC88', '#A69064'), 1)
    rumah_panggung(s, -70, -4, Mat('#C8E0D4', '#A6C8B8', '#7C9C8E'), 2)
    rumah_panggung(s, 10, 76, Mat('#F0D0C0', '#D8B09E', '#A8847A'), 3)
    rumah_panggung(s, 90, 156, Mat('#D8E4F0', '#B4C6DA', '#8698AE'), 4)
    tree_round(s, -40, 120, r=12, h=18, seed=7)
    shift_prims(s.prims[i0:], -16)            # rumah mundur supaya tangga tidak masuk jalan
    # dermaga sejajar jalan, tiang turun ke air
    for a in np.arange(40, 112, 14):
        for b in (-40, -24):
            s.add(cyl((a, b), 1.4, -SDEEP - 6, -1.5, mats=SG['kayu2']))
    s.add(box(SBANK - 2, 112, -42, -22, -1.5, 0, SG['kayu'],
              lambda Pw, Nw: (0, np.where(np.mod(Pw[:, 0], 4) < 0.8, 1, 0))))
    # perahu kayu (klotok) di muka air: satu sandar di dermaga, satu lewat
    perahu(s, 66, 2, zw=-SDEEP, L=72, W=16, hull=SG['perahu'], seed=1)
    perahu(s, 124, 60, zw=-SDEEP, L=84, W=18, hull=SG['perahu2'], seed=2, roof=Mat('#FFB061', '#EE8A32', '#AD5C1C'))
    # lampu jalan di sisi sungai, lengan ke arah jalan
    for ly in (-110, 140):
        lamp_post(s, SX1 + 2, ly, h=52, arm=10, toward=-1)


DISTRICTS = [
    ('perumahan', 'Perumahan', 'Pastel cerah, rumput hijau segar, aspal abu-abu ungu',
     (1.0, 1.0, 1.0),
     [('Dinding pastel', ['pink', 'cream', 'mint', 'sky']), ('Atap', ['roof_red', 'roof_dk', 'roof_gr']),
      ('Rumput', ['grass']), ('Aspal', ['asph']), ('Kotak surat', ['red'])]),
    ('kampung', 'Perkampungan', 'Hangat dan padat: semen, bata, seng berkarat, cat tembok pudar',
     (1.04, 1.0, 0.94),
     [('Cat pudar', ['cream', 'hijau', 'pink', 'biru']), ('Atap', ['genteng', 'seng', 'karat']),
      ('Semen gang', ['cor']), ('Selokan', ['air']), ('Bata', ['bata'])]),
    ('ruko', 'Ruko', 'Abu-abu beton dengan papan nama warna-warni dan rolling door',
     (0.98, 1.0, 1.03),
     [('Beton', ['beton', 'beton2']), ('Rolling door', ['roll']), ('Papan nama', ['s_red', 's_yel', 's_blu', 's_grn']),
      ('Angkot', ['angkot'])]),
    ('pasar', 'Pasar tradisional', 'Terpal biru dan oranye, kayu lapak, lantai basah gelap',
     (1.03, 1.0, 0.96),
     [('Terpal', ['tp_b', 'tp_o', 'tp_g']), ('Kayu lapak', ['meja']), ('Lantai basah', ['lantai', 'genangan']),
      ('Dagangan', ['tomat', 'sayur', 'jeruk'])]),
    ('desa', 'Jalan desa', 'Hijau sawah, tanah cokelat, langit luas',
     (1.03, 1.03, 0.92),
     [('Sawah', ['sawah']), ('Air sawah', ['air']), ('Tanah', ['tanah', 'pematang']), ('Kayu dan atap', ['kayu', 'atap']),
      ('Gabah', ['gabah'])]),
    ('sungai', 'Pinggir sungai', 'Biru-hijau air, kayu dermaga, rumah panggung',
     (0.97, 1.02, 1.04),
     [('Air', ['air']), ('Kayu dermaga', ['kayu', 'kayu2']), ('Atap seng', ['atap']), ('Tebing', ['tebing']),
      ('Perahu', ['perahu2'])]),
]

LIBS = dict(perumahan=P, kampung=K, ruko=RK, pasar=PS, desa=DS, sungai=SG)


def render_district(key, grade):
    cfg = grade_cfg(grade)
    if key == 'perumahan':
        px, py, _ = PR.PLAYER
        cx, cy = -12, py                      # titik tengah bingkai: sedikit ke sisi seberang dari tengah jalan
        s = Scene(VW, VH, VW / 2 - cx + cy, VH / 2 - (cx + cy) / 2)
        PR.build(s)
        s.render(cfg)
        img = finish_with_sprites(s, [(PR.loper_frame(0, 0), (23, 46), PR.PLAYER)])
    elif key == 'kampung':
        s = Scene(VW, VH, VW / 2 - 12 + 93, VH / 2 - (12 + 93) / 2)
        KP.build(s, 0.0)
        s.render(cfg)
        img = finish_with_sprites(s, [(PR.loper_frame(0, 0), (23, 46), (-14, 93, 0))])
        img = KP.overlays(s, img, 0.0, tint=grade)
    else:
        s = Scene(VW, VH, *dict(ruko=(206, 161), pasar=(200, 139), desa=(200, 129), sungai=(200, 137))[key])
        dict(ruko=build_ruko, pasar=build_pasar, desa=build_desa, sungai=build_sungai)[key](s)
        s.render(cfg)
        pl = dict(ruko=(-28, 0, 0), pasar=(-14, 40, 0), desa=(-14, 40, 0), sungai=(-10, 40, 0))[key]
        img = finish_with_sprites(s, [(PR.loper_frame(0, 0), (23, 46), pl)])
    s.img = img
    return img


if __name__ == '__main__':
    keys = sys.argv[1:] or [d[0] for d in DISTRICTS]
    for d in DISTRICTS:
        if d[0] in keys:
            img = render_district(d[0], d[3])
            save(img, f'distrik_{d[0]}.png', 2)
            print(d[0])
