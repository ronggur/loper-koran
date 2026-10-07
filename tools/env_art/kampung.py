import math, sys
import numpy as np
from PIL import Image
from engine import *
from lib import *
from perumahan import loper_frame, OUT

# ---- palet perkampungan (usulan): hangat, semen, bata, seng berkarat, cat pudar ----
K = dict(
    cor=Mat('#DCD3C4', '#CBC1B0', '#A89E8E'),
    cor_dk=Mat('#BDB3A3', '#A89E8E', '#857C6E'),
    air=Mat('#5E7E78', '#46645F', '#2F4743'),
    lip=Mat('#C9C1B4', '#B2A99B', '#8E8577'),
    teras=Mat('#E9DCC2', '#D9C8A6', '#B49E7A'),
    tanah=Mat('#B8956A', '#9C7A54', '#76593C'),
    cream=Mat('#F4E2BC', '#E6CFA0', '#BBA078'),
    hijau=Mat('#D3E2B0', '#B9CC92', '#8FA06E'),
    pink=Mat('#F1D0C8', '#DDB0A6', '#AE867E'),
    biru=Mat('#CFE2E8', '#A9C8D2', '#7F9EA8'),
    putih=Mat('#F4F0E6', '#E2DCCD', '#B8B0A0'),
    kuning=Mat('#F6E3A0', '#E8CB72', '#BC9E4E'),
    plinth=Mat('#7E9A86', '#5F7C6A', '#43594C'),
    plinth2=Mat('#9A8A7E', '#7C6C62', '#5A4C44'),
    bata=Mat('#C8714F', '#A9563D', '#7C3E2D'),
    genteng=Mat('#C8653F', '#A44E33', '#73372A'),
    genteng2=Mat('#B5704A', '#8F5438', '#643C2C'),
    seng=Mat('#B9B8BE', '#9897A0', '#6F6E78'),
    karat=Mat('#B9764A', '#97593A', '#6D3F2B'),
    kayu=Mat('#B47C5F', '#96643C', '#553428'),
    kayu_dk=Mat('#8A5A40', '#6D4334', '#4A2319'),
    pintu_h=Mat('#7FA88A', '#5E8A6C', '#3F6450'),
    pintu_b=Mat('#7F9EC0', '#5E7EA2', '#40597A'),
    terpal_o=Mat('#F4A04A', '#E07F2C', '#A9561C'),
    terpal_b=Mat('#5E9CD8', '#3E7BBE', '#2A5688'),
    tiang=Mat('#C9C4BC', '#A9A49C', '#7E7972'),
    pisang=Mat('#B6D86A', '#86B648', '#4E7E34'),
    batang=Mat('#A7A66A', '#85844E', '#5C5B36'),
    toren_o=Mat('#F7B25E', '#E8903A', '#A95E22'),
    toren_b=Mat('#7EB4E4', '#4E8CCB', '#30628F'),
    kubah=Mat('#7CC48E', '#4E9E66', '#2F6E46'),
    goods_bg=Mat('#5A4636', '#45352A', '#2E241C'),
    g1=Mat('#F06A4E'), g2=Mat('#FFD86A'), g3=Mat('#6FBF8F'), g4=Mat('#7FB2E0'), g5=Mat('#FFFFFF'),
    sign=Mat('#E0574A', '#C2412F', '#8A2C22'),
)

DX = 10   # gang dilebarkan 2 x 10: 44 -> 64 (2 ubin)

FONT = {
    'W': ['1.1', '1.1', '111', '111', '1.1'], 'A': ['.1.', '1.1', '111', '1.1', '1.1'],
    'R': ['11.', '1.1', '11.', '1.1', '1.1'], 'U': ['1.1', '1.1', '1.1', '1.1', '111'],
    'N': ['1.1', '111', '111', '111', '1.1'], 'G': ['.11', '1..', '1.1', '1.1', '.11'],
    'K': ['1.1', '1.1', '11.', '1.1', '1.1'], 'O': ['111', '1.1', '1.1', '1.1', '111'],
    'P': ['11.', '1.1', '11.', '1..', '1..'], 'S': ['.11', '1..', '.1.', '..1', '11.'],
    'I': ['111', '.1.', '.1.', '.1.', '111'], 'T': ['111', '.1.', '.1.', '.1.', '.1.'],
    'E': ['111', '1..', '11.', '1..', '111'], 'M': ['1.1', '111', '111', '1.1', '1.1'],
    'J': ['..1', '..1', '..1', '1.1', '.1.'], 'L': ['1..', '1..', '1..', '1..', '111'],
    'B': ['11.', '1.1', '11.', '1.1', '11.'], 'D': ['11.', '1.1', '1.1', '1.1', '11.'],
    'Y': ['1.1', '1.1', '.1.', '.1.', '.1.'], 'C': ['.11', '1..', '1..', '1..', '.11'],
    'H': ['1.1', '1.1', '111', '1.1', '1.1'], ' ': ['...'] * 5, 'F': ['111', '1..', '11.', '1..', '1..'],
    'V': ['1.1', '1.1', '1.1', '1.1', '.1.'], '0': ['111', '1.1', '1.1', '1.1', '111'],
}


def text_mask(txt, u, v, u0, v0, step=4, scale=1.0):
    """u grows to the right along the face; returns mask of letter pixels. v0 = top of text."""
    m = np.zeros(len(u), bool)
    for i, ch in enumerate(txt):
        g = FONT.get(ch.upper())
        if g is None:
            continue
        for r, row in enumerate(g):
            for c, cc in enumerate(row):
                if cc == '1':
                    a = u0 + (i * step + c) * scale
                    b = v0 - r * scale
                    m |= (u >= a) & (u < a + scale) & (v <= b) & (v > b - scale)
    return m


def gang_region(x, y):
    n = len(x)
    ax = np.abs(x)
    mi = np.zeros(n, int)            # 0 cor gang
    # cor slabs + cracks + patches
    slab = (np.mod(y, 40) < 0.9)
    crack_h = hash2(np.floor(y / 40), np.floor(x / 12), 7)
    crack = (np.abs(np.mod(y + x * 0.7 * (crack_h - 0.5) * 2, 40) - 20) < 0.6) & (crack_h > 0.62)
    patch = (hash2(np.floor(x / 10), np.floor(y / 10), 9) > 0.9)
    sh = 1 + np.where(slab | crack, 1, 0) + speckle(x, y, 2, 0.04, 0.05, 1)
    mi = np.where(patch & (ax < 20 + DX), 1, mi)
    # gutter water
    gut = (ax >= 22 + DX) & (ax < 28 + DX)
    mi = np.where(gut, 2, mi)
    ripple = hash2(np.floor(x / 2), np.floor(y / 3), 4)
    sh = np.where(gut, np.where(ripple > 0.85, 0, 1), sh)
    # far teras strip (under the raised teras boxes) and near yards
    near = x >= 28 + DX
    g = vnoise(x, y, 18, 12) > 0.56
    mi = np.where(near, np.where(g, 4, 3), mi)
    sh = np.where(near, 1 + np.where(g, grass_tufts(x, y, 6), speckle(x, y, 8, 0.05, 0.08, 2)), sh)
    far = x <= -28 - DX
    g2 = vnoise(x, y, 20, 13) > 0.5
    mi = np.where(far, np.where(g2 & (x < -110 - DX), 4, 3), mi)
    sh = np.where(far, 1 + np.where(g2, grass_tufts(x, y, 7), speckle(x, y, 3, 0.05, 0.06, 2)), sh)
    return mi, sh


def brick_extra(rect, mat_i):
    (u0, u1), (v0, v1) = rect

    def ex(Pw, Nw, u, v, code, mi, sh):
        inside = (u >= u0) & (u < u1) & (v >= v0) & (v < v1) & (code == 1)
        row = np.floor(v / 3)
        mortar = (np.mod(v, 3) < 0.9) | (np.mod(u + row * 3, 6) < 0.9)
        mi = np.where(inside, mat_i, mi)
        sh = np.where(inside & mortar, sh - 1, sh)
        return mi, sh
    return ex


def stain_extra(seed):
    def ex(Pw, Nw, u, v, code, mi, sh):
        h = hash2(np.floor(u / 3), np.floor(v / 4), seed)
        st = (h > 0.86) & (mi == 0) & (v > 4)
        return mi, np.where(st, sh + 1, sh)
    return ex


def chain(*fs):
    def ex(Pw, Nw, u, v, code, mi, sh):
        for f in fs:
            mi, sh = f(Pw, Nw, u, v, code, mi, sh)
        return mi, sh
    return ex


def house_k(s, y0, y1, depth=64, wall='cream', h=34, roof='gable_x', rmat='genteng', door='pintu_h',
            plinth='plinth', kanopi=None, win='nako', seed=0, brick=None, extra_feats=(), opening=None,
            toren=None, sign=None, antenna=None):
    x1 = -40
    x0 = x1 - depth
    W = K[wall]
    yc = (y0 + y1) / 2
    wid = y1 - y0
    mats = [W, K[door or 'pintu_h'], K['putih'], P['glass'], K[plinth or 'plinth'], K['bata'], K['goods_bg'], K['g1'], K['g2'],
            K['g3'], K['g4'], K['kayu_dk']]
    feats = []
    if door:
        dy = y0 + wid * 0.62
        feats.append(dict(face='+x', u=(dy, dy + 10), v=(1, 24), mat=1, frame=11, kind='door', handle=8))
    if win:
        wy = y0 + 6
        feats.append(dict(face='+x', u=(wy, wy + 12), v=(11, 23), mat=3, frame=2, kind=win))
    feats.append(dict(face='+y', u=(x0 + 10, x0 + 22), v=(12, 23), mat=3, frame=2, kind='nako'))
    if h > 50:
        feats.append(dict(face='+x', u=(y0 + 8, y0 + 20), v=(36, 47), mat=3, frame=2, kind='window'))
        feats.append(dict(face='+x', u=(y0 + 28, y0 + 40), v=(36, 47), mat=3, frame=2, kind='window'))
        feats.append(dict(face='+y', u=(x0 + 10, x0 + 22), v=(36, 47), mat=3, frame=2, kind='window'))
    feats += list(extra_feats)
    exs = [stain_extra(seed)]
    if brick:
        exs.append(brick_extra(brick, 5))
    if opening:
        (u0, u1), (v0, v1) = opening

        def goods(Pw, Nw, u, v, code, mi, sh):
            ins = (code == 1) & (u >= u0) & (u < u1) & (v >= v0) & (v < v1)
            shelf = ins & (np.mod(v - v0, 6) < 1)
            item = ins & ~shelf & (np.mod(v - v0, 6) > 2.2) & (hash2(np.floor(u / 1.5), np.floor(v / 6), seed) > 0.25)
            col = 7 + (hash2(np.floor(u / 1.5), np.floor(v / 6), seed + 3) * 4).astype(int)
            mi = np.where(ins, 6, mi)
            mi = np.where(shelf, 11, mi)
            mi = np.where(item, col, mi)
            sh = np.where(ins, 0, sh)
            return mi, sh
        exs.append(goods)
    if sign:
        txt, (u0, v0), smat = sign

        def sg(Pw, Nw, u, v, code, mi, sh):
            m = text_mask(txt, u, v, u0, v0) & (code == 1)
            return np.where(m, 2, mi), np.where(m, 0, sh)
        exs.append(sg)
    s.add(box(x0, x1, y0, y1, 0, h, mats, wall_tex(feats, plinth=(4, 4) if plinth else None, extra=chain(*exs))))
    R = K[rmat]
    kind = 'seng' if rmat in ('seng', 'karat') else 'genteng'
    tx = roof_tex(kind, seed, wall=True, rust=0.18 if rmat == 'seng' else None)
    rm = [R, W, K['karat']]
    if roof == 'gable_x':
        s.add(gable(x0 - 3, x1 + 4, y0 - 2, y1 + 2, h, h + wid * 0.42, 'x', mats=rm, tex=tx))
    elif roof == 'gable_y':
        s.add(gable(x0 - 3, x1 + 4, y0 - 3, y1 + 3, h, h + depth * 0.36, 'y', mats=rm, tex=tx))
    elif roof == 'shed':
        s.add(shed(x0 - 3, x1 + 5, y0 - 2, y1 + 2, h + 12, h + 1, '+x', 2, mats=rm, tex=tx))
        wg = shed(x0, x1, y0, y1, h + 11.5, h + 1.8, '+x', 14, mats=W, part=s.prims[-2].part)
        wg.planes.append((np.array([0, 0, -1.0]), -h))
        wg.lo[2] = h
        s.add(wg)
    elif roof == 'hip':
        s.add(hip(x0 - 4, x1 + 4, y0 - 4, y1 + 4, h, h + 22, mats=rm, tex=tx))
    # teras floor
    s.add(box(x1, -28.5, y0, y1, 0, 1.5, K['teras'],
              lambda Pw, Nw: (0, np.where((np.mod(Pw[:, 1], 6) < 0.8) | (np.mod(Pw[:, 0], 6) < 0.8), 1, 0)),
              outline=False, cast=False))
    # slab bridge over the gutter at the door
    if door:
        dy = y0 + wid * 0.62
        s.add(box(-28.5, -21, dy - 1, dy + 11, 0, 1.2, K['cor_dk'], outline=False, cast=False))
    if kanopi:
        km, ky0, ky1 = kanopi
        s.add(shed(x1 - 1, -29, ky0, ky1, 27, 22, '+x', 1.2, mats=[K[km], K[km], K['karat']],
                   tex=roof_tex('seng', seed + 5, rust=0.12)))
        for py in (ky0 + 1, ky1 - 2):
            s.add(box(-31, -30, py, py + 1, 0, 22, K['kayu_dk']))
    if antenna:
        rise = dict(gable_x=wid * 0.42, gable_y=depth * 0.36, shed=12, hip=22).get(roof, 12)
        antena(s, x0 + depth * 0.4, y0 + wid * 0.35, h, h + rise + 16, seed=seed)
    if toren:
        tx_, ty_, mat = toren
        for (a, b) in ((-4, -4), (3, -4), (-4, 3), (3, 3)):
            s.add(box(tx_ + a, tx_ + a + 1, ty_ + b, ty_ + b + 1, h + 4, h + 14, P['metal_dk']))
        s.add(box(tx_ - 5, tx_ + 5, ty_ - 5, ty_ + 5, h + 14, h + 15, P['metal_dk']))
        s.add(cyl((tx_, ty_), 6, h + 15, h + 27, mats=K[mat]))
        s.add(cyl((tx_, ty_), 3, h + 27, h + 28.5, mats=K[mat]))


def banana(s, x, y, h=24, n=7, seed=0, sway=0.0):
    s.add(cyl((x, y), 2.4, 0, h, mats=K['batang']))
    rng = np.random.default_rng(seed)
    pid = None
    for i in range(n):
        yaw = 2 * math.pi * i / n + rng.random() * 0.5
        droop = 0.35 + rng.random() * 0.45 + sway * math.sin(i)
        L = 13 + rng.random() * 5
        d = np.array([math.cos(yaw) * math.cos(droop), math.sin(yaw) * math.cos(droop), math.sin(droop)])
        base = np.array([x, y, h - 1])
        c = base + d * L / 2
        side = np.cross(d, [0, 0, 1.0]); side /= np.linalg.norm(side)
        nrm_ = np.cross(side, d)
        s.add(obox(c, d, side, nrm_, L / 2, 2.6, 0.5, K['pisang'],
                   lambda Pw, Nw: (0, np.where(np.abs(Nw[:, 2]) < 0.3, 1, 0))))
    s.add(ellip((x, y, h + 3), (3, 3, 5), K['pisang']))


def tiang_listrik(s, x, y, h=86):
    s.add(box(x - 1.6, x + 1.6, y - 1.6, y + 1.6, 0, h, K['tiang']))
    s.add(box(x - 10, x + 10, y - 1, y + 1, h - 6, h - 4, P['metal_dk']))
    return [(x - 9, y, h - 4), (x + 9, y, h - 4)]


def pos_ronda(s, x0, x1, y0, y1):
    for (a, b) in ((x0, y0), (x1 - 1.5, y0), (x0, y1 - 1.5), (x1 - 1.5, y1 - 1.5)):
        s.add(box(a, a + 1.5, b, b + 1.5, 0, 30, K['kayu']))
    s.add(box(x0, x1, y0, y1, 9, 11, K['kayu'],
              lambda Pw, Nw: (0, np.where(np.mod(Pw[:, 1], 4) < 0.8, 1, 0))))
    s.add(gable(x0 - 3, x1 + 3, y0 - 3, y1 + 3, 30, 40, 'y', mats=[K['genteng2'], K['kayu']],
                tex=roof_tex('genteng', 31, wall=True)))
    # kentongan
    s.add(cyl((x1 - 0.5, (y0 + y1) / 2), 1.6, 16, 25, mats=K['kayu_dk']))


def musala(s, x0, x1, y0, y1):
    s.add(box(x0, x1, y0, y1, 0, 40, [K['putih'], K['kubah'], P['glass']],
              wall_tex([dict(face='+x', u=(y0 + 8, y0 + 18), v=(10, 28), mat=1, frame=None),
                        dict(face='+x', u=(y1 - 18, y1 - 8), v=(10, 28), mat=1, frame=None),
                        dict(face='+y', u=(x0 + 8, x0 + 18), v=(10, 28), mat=1, frame=None)])))
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    s.add(hip(x0 - 3, x1 + 3, y0 - 3, y1 + 3, 40, 48, inset=12, mats=K['kubah'], tex=roof_tex('genteng', 3)))
    s.add(cyl((cx, cy), 9, 46, 52, mats=K['putih']))
    s.add(ellip((cx, cy, 52), (10, 10, 11), K['kubah'], zmin=52))
    s.add(cyl((cx, cy), 0.8, 62, 70, mats=K['g2']))


def build(s, t=0.0, with_life=True):
    mats = [K['cor'], K['cor_dk'], K['air'], K['tanah'], P['grass']]
    s.add(ground_prim(gang_region, mats))
    for sg in (-1, 1):
        for a in ((22 + DX, 22.8 + DX), (27.4 + DX, 28.4 + DX)):
            lo, hi = (a[0], a[1]) if sg > 0 else (-a[1], -a[0])
            s.add(box(lo, hi, -900, 900, 0, 1.2, K['lip'], outline=False, cast=False))
    i0 = len(s.prims)
    # ---- sisi seberang: deret rumah rapat ----
    H = [
        dict(y0=-430, y1=-372, wall='putih', roof='gable_x', rmat='genteng', door='pintu_b', seed=1),
        dict(y0=-372, y1=-318, wall='hijau', roof='shed', rmat='seng', seed=2, kanopi=('seng', -370, -320)),
        dict(y0=-268, y1=-214, wall='pink', h=58, roof='hip', rmat='genteng2', seed=3, toren=(-70, -240, 'toren_o')),
        dict(y0=-214, y1=-162, wall='biru', roof='gable_y', rmat='genteng', door='pintu_b', seed=4,
             kanopi=('seng', -212, -164)),
        dict(y0=-162, y1=-110, wall='cream', roof='shed', rmat='seng', seed=5, brick=((-150, -128), (0, 30)),
             plinth='plinth2'),
        dict(y0=-110, y1=-60, wall='hijau', roof='gable_x', rmat='genteng2', seed=6, door='pintu_b'),
        dict(y0=-60, y1=8, wall='kuning', roof='gable_y', rmat='seng', seed=7, door=None, win=None,
             opening=((-52, -10), (4, 26))),
        dict(y0=8, y1=62, wall='biru', roof='gable_x', rmat='genteng', seed=8, toren=(-78, 34, 'toren_b')),
        dict(y0=62, y1=118, wall='pink', roof='shed', rmat='seng', seed=9, kanopi=('karat', 64, 116)),
        dict(y0=118, y1=170, wall='cream', h=56, roof='hip', rmat='genteng', seed=10, door='pintu_b'),
        dict(y0=170, y1=226, wall='hijau', roof='gable_x', rmat='genteng2', seed=11, brick=((184, 210), (0, 18))),
        dict(y0=226, y1=290, wall='putih', roof='shed', rmat='seng', seed=12, kanopi=('seng', 228, 288)),
        dict(y0=290, y1=350, wall='kuning', roof='gable_x', rmat='genteng', seed=13),
        dict(y0=350, y1=420, wall='pink', roof='gable_y', rmat='genteng2', seed=14),
    ]
    for d in H:
        y0, y1 = d.pop('y0'), d.pop('y1')
        if 'toren' not in d and d.get('seed', 0) % 4 != 3:
            d['antenna'] = True
        house_k(s, y0, y1, **d)
    # side alley + pos ronda between -318 and -268
    pos_ronda(s, -66, -36, -306, -280)
    # ---- warung (in front of the kuning house) ----
    wy0, wy1 = -58, -12
    s.add(box(-40, -33, -50, -12, 0, 9, K['kayu'], outline=True))
    s.add(box(-40, -33, -50, -12, 9, 15, [P['glass_off'], K['g1'], K['g2'], K['g3']],
              lambda Pw, Nw: ((hash2(np.floor(Pw[:, 1] / 2), np.floor(Pw[:, 2] / 2), 5) * 4).astype(int) * (Pw[:, 2] < 13.5),
                              0)))
    s.add(box(-38, -30, -6, 3, 0, 9, K['kayu_dk']))             # meja kompor, di luar tenda
    s.add(box(-37, -31, -5, 2, 9, 11, P['metal_dk']))            # kompor
    s.add(ellip((-34, -1.5, 12), (4.2, 4.2, 2.2), P['metal_dk'], zmin=11))  # wajan
    s.smoke_src = (-34, -1.5, 13)

    def terpal(Pw, Nw):
        st = (np.mod(Pw[:, 1], 8) < 4).astype(int)
        return st, 0
    s.add(shed(-41, -24, wy0 - 2, wy1 + 2, 33, 25, '+x', 1.0, mats=[K['terpal_o'], K['terpal_b']], tex=terpal))
    for py in (wy0, wy1 - 1):
        s.add(cyl((-26, py), 0.9, 0, 25.5, mats=K['batang']))
    # papan nama warung
    s.add(box(-26, -24.5, -48, -10, 25, 32, [K['sign'], K['putih'], K['putih']],
              lambda Pw, Nw: (np.where(text_mask('WARUNG', -Pw[:, 1], Pw[:, 2], 17, 30.5) & (Nw[:, 0] > 0.5), 1, 0), 0)))
    # renceng sachet
    for i, py in enumerate(np.arange(-46, -12, 5)):
        c = [K['g1'], K['g2'], K['g4'], K['g3']][i % 4]
        s.add(box(-26.5, -25.5, py, py + 2, 14, 24.5, [c, K['g5']],
                  lambda Pw, Nw: ((np.mod(Pw[:, 2], 3) < 1).astype(int), 0), cast=False))
    # bird cage under kanopi of pink house
    s.add(cyl((-33, 92), 2.6, 13, 18, mats=K['kayu']))
    s.add(ellip((-33, 92, 18), (2.6, 2.6, 2.0), K['kayu'], zmin=18))
    s.cage = ((-33, 92, 20), (-33, 92, 25))
    # potted plants along the far teras
    rng = np.random.default_rng(3)
    for py in (-420, -400, -330, -205, -178, -100, -82, 30, 46, 128, 140, 190, 240, 262, 300, 330):
        pot_plant(s, -36 + rng.random() * 3, py + rng.random() * 4, 2.2 + rng.random(), seed=int(py) & 255,
                  pot=P['terra'] if py % 3 else K['toren_b'])
    motor(s, -34, 104, body=Mat('#7EB4E4', '#4E8CCB', '#30628F'))
    # ---- background row + musala ----
    for i, (y0, y1, wall, rm, rr) in enumerate([(-420, -350, 'cream', 'seng', 'shed'), (-350, -280, 'putih', 'genteng', 'gable_x'),
                                               (-200, -130, 'pink', 'genteng2', 'gable_y'),
                                               (-130, -60, 'biru', 'seng', 'shed'), (-60, 10, 'hijau', 'genteng', 'gable_x'),
                                               (10, 80, 'cream', 'genteng2', 'hip'), (80, 150, 'putih', 'seng', 'shed'),
                                               (150, 220, 'kuning', 'genteng', 'gable_x')]):
        x1, x0 = -116, -186
        Wm = K[wall]
        s.add(box(x0, x1, y0, y1, 0, 32 + (i % 3) * 6, Wm, wall_tex([dict(face='+y', u=(x0 + 20, x0 + 32), v=(12, 23), mat=1, frame=2)]) ))
        s.prims[-1].mats = [Wm, P['glass'], K['putih']]
        hh = 32 + (i % 3) * 6
        R = K[rm]
        tx = roof_tex('seng' if rm == 'seng' else 'genteng', 60 + i, wall=True, rust=0.2)
        if rr == 'shed':
            s.add(shed(x0 - 3, x1 + 3, y0 - 2, y1 + 2, hh + 12, hh + 1, '+x', 2, mats=[R, Wm, K['karat']], tex=tx))
        elif rr == 'gable_x':
            s.add(gable(x0 - 3, x1 + 3, y0 - 2, y1 + 2, hh, hh + 26, 'x', mats=[R, Wm], tex=tx))
        elif rr == 'gable_y':
            s.add(gable(x0 - 3, x1 + 3, y0 - 2, y1 + 2, hh, hh + 24, 'y', mats=[R, Wm], tex=tx))
        else:
            s.add(hip(x0 - 3, x1 + 3, y0 - 3, y1 + 3, hh, hh + 20, mats=[R, Wm], tex=tx))
    # third row (far back) + musala
    for i, (y0, y1, wall, rm, rr) in enumerate([(-430, -360, 'putih', 'genteng', 'gable_y'), (-340, -270, 'kuning', 'seng', 'shed'),
                                               (-250, -180, 'hijau', 'genteng2', 'gable_x'), (-160, -90, 'cream', 'genteng', 'hip'),
                                               (-70, -10, 'pink', 'seng', 'shed'), (80, 150, 'biru', 'genteng', 'gable_x'),
                                               (170, 240, 'putih', 'genteng2', 'hip')]):
        x1, x0 = -206, -276
        Wm = K[wall]
        hh = 30 + (i % 2) * 6
        s.add(box(x0, x1, y0, y1, 0, hh, Wm))
        R = K[rm]
        tx = roof_tex('seng' if rm == 'seng' else 'genteng', 160 + i, wall=True, rust=0.2)
        if rr == 'shed':
            s.add(shed(x0 - 3, x1 + 3, y0 - 2, y1 + 2, hh + 12, hh + 1, '+x', 2, mats=[R, Wm, K['karat']], tex=tx))
        elif rr == 'gable_x':
            s.add(gable(x0 - 3, x1 + 3, y0 - 2, y1 + 2, hh, hh + 26, 'x', mats=[R, Wm], tex=tx))
        elif rr == 'gable_y':
            s.add(gable(x0 - 3, x1 + 3, y0 - 2, y1 + 2, hh, hh + 24, 'y', mats=[R, Wm], tex=tx))
        else:
            s.add(hip(x0 - 3, x1 + 3, y0 - 3, y1 + 3, hh, hh + 20, mats=[R, Wm], tex=tx))
    musala(s, -264, -210, 4, 60)
    tree_round(s, -196, -12, r=17, h=34, seed=71)
    tree_round(s, -198, 238, r=16, h=30, seed=72)
    tree_round(s, -196, -350, r=17, h=30, seed=73)
    tree_round(s, -300, 120, r=18, h=34, seed=74)
    # antennas
    for (ax_, ay_, hh) in ((-150, -96, 54), (-140, 140, 60), (-170, -390, 56)):
        s.add(cyl((ax_, ay_), 0.7, hh - 20, hh + 14, mats=P['metal_dk']))
        s.add(box(ax_ - 0.5, ax_ + 0.5, ay_ - 7, ay_ + 7, hh + 10, hh + 11, P['metal_dk']))
    i1 = len(s.prims)
    shift_prims(s.prims[i0:i1], -DX)
    s.smoke_src = tuple(np.array(s.smoke_src) - [DX, 0, 0])
    s.cage = tuple(tuple(np.array(c) - [DX, 0, 0]) for c in s.cage)
    # ---- sisi dekat: tembok rendah, halaman sempit, deret rumah (terlihat samping/belakang) ----
    gaps = [(-152, -138), (4, 22), (112, 126), (256, 270)]
    segs = []
    ys = -900
    for a, b in gaps:
        segs.append((ys, a)); ys = b
    segs.append((ys, 900))
    for a, b in segs:
        s.add(box(28.4, 31.5, a, b, 0, 13, [K['putih'], K['plinth']],
                  lambda Pw, Nw: (np.where(Pw[:, 2] < 4, 1, 0), 0)))
    NEAR = [(-430, -372, 'kuning', 'genteng'), (-364, -300, 'hijau', 'seng'), (-290, -236, 'pink', 'genteng2'),
            (-226, -162, 'biru', 'genteng'), (-128, -74, 'cream', 'seng'), (-66, -10, 'putih', 'genteng2'),
            (194, 250, 'hijau', 'genteng2'),
            (278, 340, 'biru', 'seng'), (348, 420, 'cream', 'genteng')]
    NEAR2 = NEAR[:6] + [(30, 88, 'pink', 'genteng'), (130, 186, 'kuning', 'seng')] + NEAR[6:]
    for row, (x0, x1, hh) in enumerate(((64, 128, 30), (150, 214, 32))):
        for i, (y0, y1, wall, rm) in enumerate(NEAR if row == 0 else NEAR2):
            if row == 1:
                y0, y1 = y0 + 18, y1 + 18
                wall = ['putih', 'kuning', 'hijau', 'pink', 'biru', 'cream'][i % 6]
                rm = ['seng', 'genteng', 'genteng2'][i % 3]
            Wm = K[wall]
            feats = [dict(face='+x', u=(y0 + 10, y0 + 20), v=(1, 22), mat=1, frame=2, kind='door', handle=3),
                     dict(face='+x', u=(y1 - 26, y1 - 14), v=(12, 22), mat=4, frame=2, kind='nako'),
                     dict(face='+y', u=(x0 + 12, x0 + 24), v=(12, 22), mat=4, frame=2, kind='nako'),
                     dict(face='+y', u=(x1 - 22, x1 - 12), v=(14, 22), mat=4, frame=2, kind='window')]
            s.add(box(x0, x1, y0, y1, 0, hh, [Wm, K['pintu_h'], K['putih'], K['plinth'], P['glass']],
                      wall_tex(feats, plinth=(4, 3), extra=stain_extra(40 + i + row * 20))))
            R = K[rm]
            tx = roof_tex('seng' if rm == 'seng' else 'genteng', 80 + i + row * 20, wall=True, rust=0.2)
            if rm == 'seng':
                s.add(shed(x0 - 3, x1 + 3, y0 - 2, y1 + 2, hh + 3, hh + 13, '+x', 2, mats=[R, Wm, K['karat']], tex=tx))
                wg = shed(x0, x1, y0, y1, hh + 2, hh + 11.5, '+x', 14, mats=Wm, part=s.prims[-2].part)
                wg.planes.append((np.array([0, 0, -1.0]), -hh)); wg.lo[2] = hh
                s.add(wg)
            else:
                s.add(gable(x0 - 3, x1 + 3, y0 - 3, y1 + 3, hh, hh + 20, 'y', mats=[R, Wm], tex=tx))
            if (i + row) % 2 == 0:
                antena(s, (x0 + x1) / 2, y0 + 16, hh, hh + 34, seed=60 + i + row * 20)
    # halaman terbuka: kandang ayam, gentong, kebun kecil, bale bambu
    mesh = lambda Pw, Nw: (0, np.where((np.mod(Pw[:, 0] + Pw[:, 1] + Pw[:, 2], 3) < 0.9) | (np.mod(Pw[:, 0] - Pw[:, 1] + Pw[:, 2], 3) < 0.9), 1, 0))
    s.add(box(84, 106, 46, 70, 0, 2, K['kayu_dk']))
    s.add(box(84, 106, 46, 70, 2, 15, Mat('#8A6A4E', '#5E4632', '#3A2A1E'), mesh))
    for (a, b) in ((84, 46), (104.5, 46), (84, 68.5), (104.5, 68.5)):
        s.add(box(a, a + 1.5, b, b + 1.5, 0, 16, K['kayu']))
    s.add(shed(82, 108, 44, 72, 20, 15, '+x', 1.2, mats=[K['seng'], K['seng'], K['karat']], tex=roof_tex('seng', 77, rust=0.3)))
    s.add(cyl((50, 74), 4.5, 0, 9, mats=Mat('#C9845A', '#A8643E', '#764428')))
    s.add(cyl((50, 74), 3.6, 9, 10.5, mats=Mat('#C9845A', '#A8643E', '#764428')))
    for i, (bx, by) in enumerate([(70 + c * 9, 138 + r * 9) for r in range(4) for c in range(3)]):
        s.add(box(bx - 3.5, bx + 3.5, by - 3.5, by + 3.5, 0, 1.5, K['tanah'], outline=False, cast=False))
        s.add(ellip((bx, by, 1.5), (2.8, 2.8, 4.2), K['pisang'] if i % 3 else P['leaf2'], leafy(i, 1.4), zmin=1.5))
        if i % 4 == 1:
            s.add(ellip((bx + 1, by - 1, 4.5), (0.9, 0.9, 0.9), K['g1']))
    bench(s, 40, 52, 182, 204, h=9, mat=Mat('#D6C08A', '#B89C62', '#86703F'))
    tree_round(s, 120, 214, r=14, h=24, seed=95, mat=P['leaf'])
    for (tx_, ty_) in ((240, -300), (250, -120), (236, 60), (246, 230), (238, 400)):
        tree_round(s, tx_, ty_, r=17, h=28, seed=int(ty_) & 255)
    banana(s, 46, -146, h=30, seed=1)
    banana(s, 48, 262, h=28, seed=2)
    banana(s, 104, 20, h=30, seed=3)
    motor(s, 46, 12, body=Mat('#F06A4E', '#D94F3D', '#8E2E25'))
    # toren on a near roof
    for (a, b) in ((-4, -4), (3, -4), (-4, 3), (3, 3)):
        s.add(box(110 + a, 110 + a + 1, -40 + b, -40 + b + 1, 44, 56, P['metal_dk']))
    s.add(box(104, 116, -46, -34, 56, 57, P['metal_dk']))
    s.add(cyl((110, -40), 6, 57, 69, mats=K['toren_o']))
    s.add(cyl((110, -40), 3, 69, 70.5, mats=K['toren_o']))
    # poles
    s.pole_tops = []
    for py in (-330, -170, 34, 190, 330):
        s.pole_tops.append(tiang_listrik(s, 34, py))
    # yard jemuran on near side (line along x, in the gap between houses)
    s.yard_line = ((40, 108, 24), (124, 108, 24))
    for px_ in (40, 124):
        s.add(box(px_ - 0.7, px_ + 0.7, 107.3, 108.7, 0, 25, K['kayu_dk']))
    # a cat on the near wall
    cat = Mat('#F7B25E', '#E8903A', '#A95E22')
    s.add(ellip((30, -36, 16), (3.6, 2.2, 2.6), cat))
    cid = s.prims[-1].part
    s.add(ellip((30, -40.2, 18.5), (2.0, 2.0, 1.9), cat, part=cid))
    for e in (-1, 1):
        s.add(obox((30 + e * 1.0, -40.6, 20.6), (0, 0, 1), (1, 0, 0), (0, 1, 0), 0.8, 0.5, 0.4, cat, part=cid))
    s.add(obox((30, -31.5, 15), (0, 1, 0.6), (1, 0, 0), (0, -0.6, 1), 3.0, 0.6, 0.6, cat, part=cid))
    i2 = len(s.prims)
    shift_prims(s.prims[i1:i2], DX)
    s.pole_tops = [[tuple(np.array(p) + [DX, 0, 0]) for p in pair] for pair in s.pole_tops]
    s.yard_line = tuple(tuple(np.array(p) + [DX, 0, 0]) for p in s.yard_line)
    if with_life:
        add_life(s, t)


CLOTHES_X = None


def add_life(s, t):
    # jemuran melintang di atas gang (rope along x)
    p0, p1 = (-41 - DX, 34, 44), (33 + DX, 34, 42)
    items = [(0.10, 6, 8, K['g4'], 'kaus'), (0.23, 6, 12, Mat('#F7F2E8', '#E8E0CE', '#B8AE98'), 'handuk'),
             (0.37, 9, 16, Mat('#9E7CC8', '#7E5CA8', '#5A3E80'), 'sarung'),
             (0.52, 6, 9, Mat('#F06A4E', '#D94F3D', '#8E2E25'), 'kaus'), (0.65, 7, 13, Mat('#7F9EC0', '#5E7EA2', '#40597A'), 'celana'),
             (0.78, 5, 8, Mat('#FFE08A', '#FFC94A', '#E98E3F'), 'kaus'), (0.9, 6, 11, Mat('#7FB2E0', '#5F96C8', '#3E6A96'))]
    clothes_line(s, p0, p1, items, sway=0.22, t=t)
    # yard line near side
    a, b = s.yard_line
    items2 = [(0.15, 9, 18, Mat('#F2C46B', '#D8A040', '#9A6A22'), 'sarung'), (0.42, 7, 9, Mat('#F7F2E8', '#E8E0CE', '#B8AE98'), 'kaus'),
              (0.66, 10, 13, Mat('#E8889A', '#C8687A', '#904452'), 'handuk'), (0.88, 6, 10, K['g4'], 'celana')]
    clothes_line(s, a, b, items2, sway=0.18, t=t + 0.3)
    # chickens
    ph = t
    chicken(s, 10, 20, yaw=0.15 + 0.25 * math.sin(2 * math.pi * t), phase=ph * 2, mode='walk')
    chicken(s, -14, -24, yaw=-0.9, phase=ph, mode='peck', col=Mat('#C98A5A', '#A86A3E', '#6E4428'),
            tail=Mat('#4A5A50', '#2E3C34', '#1C2620'))
    chicken(s, 14, 168, yaw=2.2, phase=(ph + 0.4) * 1, mode='peck', col=Mat('#E0794E', '#B9552F', '#7C3820'),
            tail=Mat('#3E6A5A', '#24483C', '#142A22'), size=1.15)
    chicken(s, 66 + DX, 90, yaw=0.3, phase=ph * 2 + 0.5, mode='walk', col=Mat('#FFFFFF', '#F2E7C9', '#C2AF86'))
    chicken(s, 74 + DX, 60, yaw=2.6, phase=ph + 0.2, mode='peck', col=Mat('#E8C890', '#C9A464', '#8E7040'), size=0.9)


def overlays(s, img, t, tint=(1, 1, 1)):
    tint = np.array(tint, np.float32)
    # power + service wires
    tops = s.pole_tops
    left = [p[0] for p in tops]
    right = [p[1] for p in tops]
    wires(s, img, left, sag=7)
    wires(s, img, right, sag=8)
    for i, p in enumerate(left):
        tgt = (-40 - DX, p[1] + 30, 40)
        wires(s, img, [p, tgt], sag=5)
    draw_ropes(s, img)
    # cage hook
    a, b = s.cage
    wires(s, img, [a, b], sag=0, col=(40, 34, 30))
    # kite caught on the wire
    sx, sy = s.proj((34 + DX - 9, -90, 80))
    X, Y = int(sx[0]), int(sy[0])
    kite = [(0, -3), (-1, -2), (0, -2), (1, -2), (-2, -1), (-1, -1), (0, -1), (1, -1), (2, -1), (-1, 0), (0, 0), (1, 0), (0, 1)]
    Hh, Ww = img.shape[:2]
    for dx, dy in kite:
        c = (232, 82, 62) if dy < -1 or (dy == -1 and dx <= 0) else (255, 216, 106)
        if 0 <= Y + dy < Hh and 0 <= X + dx < Ww:
            img[Y + dy, X + dx] = np.array(c) * tint
    for k in range(1, 7):
        if 0 <= Y + 1 + k < Hh and 0 <= X + (k % 2) < Ww:
            img[Y + 1 + k, X + (k % 2)] = np.array((232, 82, 62)) * tint
    smoke(s, img, s.smoke_src, t, n=12, rise=50, drift=(6, -12), tint=tint, seed=2)
    return img


def render(tname='sore', t=0.0, frame=0, scale=1, out=None, W=640, H=360, ox=320, oy=180, player=True):
    s = Scene(W, H, ox, oy)
    build(s, t)
    tc = TIMES[tname]
    s.render(tc)
    sprites = []
    if player:
        sprites.append((loper_frame(0, frame % 4), (23, 46), (-14, 93, 0)))
    img = finish_with_sprites(s, sprites)
    tint = tc.sun if tname != 'malam' else tc.sun * 1.4
    img = overlays(s, img, t, tint=np.clip(tint, 0.5, 1.1))
    im = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), 'RGB')
    if scale != 1:
        im = im.resize((im.width * scale, im.height * scale), Image.NEAREST)
    if out:
        im.save(out)
    return im, s


if __name__ == '__main__':
    import time
    t0 = time.time()
    tn = sys.argv[1] if len(sys.argv) > 1 else 'sore'
    render(tn, 0.0, 0, 2, OUT / f'kampung_{tn}.png')
    print(round(time.time() - t0, 1))
