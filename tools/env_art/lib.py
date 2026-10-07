"""Building blocks for Loper Koran environment mocks (usulan). Units = world px (ubin 32x32)."""
import math
import numpy as np
from engine import *

# ---------------- palet induk (ART_DIRECTION 2.4) + tambahan usulan ----------------
P = dict(
    grass=Mat('#7DBB5A', '#6FAE4F', '#62A046'),
    grass_dk=Mat('#6FAE4F', '#62A046', '#4E8A3C'),
    leaf=Mat('#7DBB5A', '#4F8A4A', '#314D38'),
    leaf2=Mat('#9CC45A', '#6FAE4F', '#3F6B3A'),
    asph=Mat('#77737D', '#6C6872', '#5E5A66'),
    mark=Mat('#FBF6E8', '#F2E7C9', '#C2AF86'),
    walk=Mat('#E6D7B5', '#DCCBA6', '#C2B08A'),
    kerb=Mat('#BDB6C2', '#A9A2AE', '#8A8390'),
    conc=Mat('#D6D0C8', '#C4BDB4', '#9E978E'),
    paper=Mat('#FBF6E8', '#F2E7C9', '#C2AF86'),
    white=Mat('#FFFFFF', '#F2E7C9', '#C2AF86'),
    brick=Mat('#B5523B', '#994532', '#673F31'),
    roof_red=Mat('#C2603F', '#994532', '#673F31'),
    roof_dk=Mat('#7480A3', '#5C6A8C', '#404A62'),
    roof_gr=Mat('#6E8E62', '#4E6E50', '#344B38'),
    wood=Mat('#B47C5F', '#96643C', '#553428'),
    wood_dk=Mat('#96643C', '#6D4334', '#4A2319'),
    metal=Mat('#C4C0C8', '#969AA0', '#67636D'),
    metal_dk=Mat('#5F5B66', '#3D4649', '#221E26'),
    glass=Mat('#BFE3F0', '#9BC4D8', '#5F96C8', glow='#FFD98A'),
    glass_off=Mat('#9BC4D8', '#6F9BB8', '#466E8C'),
    pink=Mat('#F7D9DC', '#F0C8CD', '#BB9C9F'),
    cream=Mat('#FBE6BE', '#F6D6A0', '#C9A979'),
    mint=Mat('#DDEDC0', '#C9E0A5', '#9CAE80'),
    sky=Mat('#C6EAF6', '#AADCF0', '#90BBCC'),
    warm=Mat('#FFE08A', '#FFC94A', '#E98E3F'),
    red=Mat('#F06A4E', '#D94F3D', '#8E2E25'),
    blue=Mat('#7FB2E0', '#5F96C8', '#3E6A96'),
    navy=Mat('#7480A3', '#5C6A8C', '#404A62'),
    skin=Mat('#F2B98C', '#E8A07A', '#B47C5F'),
    soil=Mat('#B08A62', '#94704C', '#6E5038'),
    lamp=Mat('#FFF6D8', '#FFE7A8', '#E9C46A', glow='#FFE9A8'),
    dark=Mat('#3D3446', '#2C2534', '#1C1724'),
    terra=Mat('#D9895E', '#C06A45', '#8A4630'),
)


# ---------------- ground ----------------

def ground_prim(region, mats, x=(-900, 900), y=(-900, 900)):
    """region(x, y) -> (mat index array, tone shift array). Ground top shows 'terang' tone by bake;
    region functions normally add +1 so 'dasar' dominates."""
    def tex(Pw, Nw):
        mi, sh = region(Pw[:, 0], Pw[:, 1])
        return mi, sh
    return box(x[0], x[1], y[0], y[1], -20, 0, mats, tex, outline=False, cast=False, tag='ground')


def speckle(x, y, seed, p_light=0.06, p_dark=0.08, cell=2):
    h = hash2(np.floor(x / cell), np.floor(y / cell), seed)
    return np.where(h < p_light, -1, np.where(h > 1 - p_dark, 1, 0))


def vnoise(x, y, cell, seed=0):
    gx, gy = x / cell, y / cell
    x0, y0 = np.floor(gx), np.floor(gy)
    fx, fy = gx - x0, gy - y0
    fx = fx * fx * (3 - 2 * fx); fy = fy * fy * (3 - 2 * fy)
    a = hash2(x0, y0, seed); b = hash2(x0 + 1, y0, seed)
    c = hash2(x0, y0 + 1, seed); d = hash2(x0 + 1, y0 + 1, seed)
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


def grass_tufts(x, y, seed=3):
    # small 2-3 px tufts: light top, dark below
    cx, cy = np.floor(x / 5), np.floor(y / 5)
    h = hash2(cx, cy, seed)
    fx, fy = x - cx * 5, y - cy * 5
    tuft = (h > 0.78) & (fx < 2) & (fy < 2)
    dark = (h < 0.12) & (fx < 3) & (fy < 1.5)
    return np.where(tuft, -1, np.where(dark, 1, 0))


# ---------------- walls with openings ----------------

def wall_tex(feats, plinth=None, base=0, extra=None):
    """feats: list of dict(face='+x'|'+y', u=(a,b), v=(a,b), mat=i, frame=i or None, kind)
    kind 'window' draws a cross bar, 'nako' horizontal slats, 'door' a handle, 'roll' rolling door."""
    def tex(Pw, Nw):
        u, v, code = face_uv(Pw, Nw)
        mi = np.full(len(Pw), base)
        sh = np.zeros(len(Pw), int)
        if plinth is not None:
            pz, pm = plinth
            mi = np.where(v < pz, pm, mi)
        for f in feats:
            fc = 1 if f['face'] == '+x' else 2
            on = code == fc
            (u0, u1), (v0, v1) = f['u'], f['v']
            inside = on & (u >= u0) & (u < u1) & (v >= v0) & (v < v1)
            fr = f.get('frame')
            if fr is not None:
                inner = inside & (u >= u0 + 1) & (u < u1 - 1) & (v >= v0 + 1) & (v < v1 - 1)
                mi = np.where(inside, fr, mi)
                mi = np.where(inner, f['mat'], mi)
                k = f.get('kind', 'window')
                if k == 'window':
                    cross = inner & ((np.abs(u - (u0 + u1) / 2) < 0.5) | (np.abs(v - (v0 + v1) / 2 - 1) < 0.5))
                    mi = np.where(cross, fr, mi)
                elif k == 'nako':
                    sl = inner & (((v - v0) % 2.5) < 0.8)
                    sh = np.where(sl, sh - 1, sh)
                    mid = inner & (np.abs(u - (u0 + u1) / 2) < 0.5)
                    mi = np.where(mid, fr, mi)
                elif k == 'door':
                    pan = inner & (((v - v0) % 7) < 0.8) & (v > v0 + 2)
                    sh = np.where(pan, sh + 1, sh)
                    hd = inner & (np.abs(u - (u1 - 2.5)) < 0.6) & (np.abs(v - (v0 + v1) / 2) < 0.8)
                    mi = np.where(hd, f.get('handle', fr), mi)
            else:
                mi = np.where(inside, f['mat'], mi)
                if f.get('kind') == 'roll':
                    sl = inside & (((v - v0) % 2) < 1)
                    sh = np.where(sl, sh + 1, sh)
                if f.get('kind') == 'stripe':
                    sl = inside & ((((u - u0) // f.get('w', 3)) % 2) == 1)
                    mi = np.where(sl, f['mat2'], mi)
        if extra is not None:
            mi, sh = extra(Pw, Nw, u, v, code, mi, sh)
        return mi, sh
    return tex


def roof_tex(kind='genteng', seed=1, wall=None, rust=None):
    """Slope faces get tile rows (genteng) or corrugation (seng). Vertical faces -> wall mat index 1."""
    def tex(Pw, Nw):
        z = Pw[:, 2]
        n = len(Pw)
        mi = np.zeros(n, int)
        sh = np.zeros(n, int)
        vert = np.abs(Nw[:, 2]) < 0.2
        if kind == 'genteng':
            sh = np.where(((z * 1.0) % 3.4) < 1.0, 1, 0)
            # staggered vertical seams
            row = np.floor(z / 3.4)
            u = Pw[:, 0] - Pw[:, 1]
            seam = ((u + row * 3) % 6) < 0.9
            sh = np.where(seam & (sh == 0), 1, sh)
        elif kind == 'seng':
            ax = np.abs(Nw[:, 0]) > np.abs(Nw[:, 1])
            along = np.where(ax, Pw[:, 1], Pw[:, 0])
            sh = np.where((along % 3) < 1.2, 1, 0)
            if rust is not None:
                h = hash2(np.floor(along / 4), np.floor(z / 3), seed)
                mi = np.where(h > 1 - rust, 2, mi)
        elif kind == 'flat':
            pass
        if wall is not None:
            mi = np.where(vert, 1, mi)
            sh = np.where(vert, 0, sh)
        return mi, sh
    return tex


def leafy(seed=0, scale=3.0, top_light=True):
    def tex(Pw, Nw):
        h = hash2(np.floor(Pw[:, 0] / scale + Pw[:, 2] / scale), np.floor(Pw[:, 1] / scale - Pw[:, 2] / scale), seed)
        d = Nw @ BAKE
        sh = np.where((h > 0.72) & (d > 0.2), -1, np.where((h < 0.25) & (d < 0.6), 1, 0))
        return 0, sh
    return tex


# ---------------- objects ----------------

def tree_round(s, x, y, r=16, h=26, seed=0, mat=None, trunk=None):
    mat = mat or P['leaf']
    trunk = trunk or P['wood_dk']
    part = None
    s.add(cyl((x, y), 2.2, 0, h, mats=trunk))
    rr = np.array([1.0, 0.9, 0.8])
    s.add(ellip((x, y, h + r * 0.55), (r, r, r * 0.8), mat, leafy(seed)))
    s.add(ellip((x - r * 0.55, y + r * 0.35, h + r * 0.15), (r * 0.62, r * 0.62, r * 0.55), mat, leafy(seed + 1)))
    s.add(ellip((x + r * 0.35, y - r * 0.5, h + r * 0.95), (r * 0.6, r * 0.6, r * 0.5), mat, leafy(seed + 2)))


def bush(s, x, y, r=6, h=None, mat=None, seed=0):
    mat = mat or P['leaf']
    h = h or r * 0.8
    s.add(ellip((x, y, 0), (r, r, h * 1.4), mat, leafy(seed, 2.0), zmin=0))


def pot_plant(s, x, y, r=3, mat=None, pot=None, seed=0):
    pot = pot or P['terra']
    s.add(cyl((x, y), r * 0.8, 0, r * 1.2, mats=pot))
    s.add(ellip((x, y, r * 1.6), (r * 1.1, r * 1.1, r * 1.0), mat or P['leaf2'], leafy(seed, 1.6)))


def kotak_surat(s, x, y, mat=None):
    mat = mat or P['red']
    s.add(box(x - 1, x + 1, y - 1, y + 1, 0, 12, P['metal_dk']))
    s.add(box(x - 3.5, x + 3.5, y - 2.5, y + 2.5, 12, 19, mat,
              wall_tex([dict(face='+x', u=(y - 1.5, y + 1.5), v=(16, 17.2), mat=1)]), ))
    s.prims[-1].mats = [mat, P['metal_dk']]


def tong_sampah(s, x, y, mat=None):
    mat = mat or Mat('#6FBF8F', '#3E9A6A', '#2A6A4A')
    s.add(cyl((x, y), 4, 0, 10, mats=mat))
    s.add(cyl((x, y), 4.6, 10, 12, mats=mat))


def lamp_post(s, x, y, h=56, arm=8, toward=+1, light_r=96):
    s.add(cyl((x, y), 1.4, 0, h, mats=P['metal_dk']))
    s.add(box(x, x + arm * toward if toward > 0 else x, y - 0.8, y + 0.8, h - 2, h, P['metal_dk'])
          if toward > 0 else box(x + arm * toward, x, y - 0.8, y + 0.8, h - 2, h, P['metal_dk']))
    lx = x + arm * toward
    s.add(box(lx - 3, lx + 3, y - 2, y + 2, h - 4, h - 1, [P['metal_dk'], P['lamp']],
              lambda Pw, Nw: (np.where(Pw[:, 2] < h - 3.2, 1, 0), 0)))
    s.lights.append(Light((lx, y, h - 6), light_r, '#FFD27A', 0.95, flat=0.35, zmax=22))


def _conv(planes, lo, hi, mats, tex=None, **kw):
    return Prim(planes, None, mats, tex, aabb=(lo, hi), **kw)


GLASS_CAR = Mat('#8FB4CC', '#5E86A6', '#3A5672')
TIRE = Mat('#4A4650', '#2E2A34', '#1C1822')
RIM = Mat('#E4E2E8', '#B4B2BC', '#7E7C88')
LAMP_F = Mat('#FFF6D8', '#FFE7A8', '#E9C46A')
LAMP_R = Mat('#FF8A6A', '#E0503A', '#9A2E22')
TRIM = Mat('#5A5662', '#3E3A46', '#26222C')


def _wheels(s, x, hw, ys, r=4.6):
    for wy in ys:
        s.add(cyl((wy, r), r, x - hw - 0.6, x + hw + 0.6, axis=0, mats=TIRE))
        pid = s.prims[-1].part
        for sg in (-1, 1):
            a, b = (x + hw + 0.6, x + hw + 0.9) if sg > 0 else (x - hw - 0.9, x - hw - 0.6)
            s.add(cyl((wy, r), r * 0.48, a, b, axis=0, mats=RIM, part=pid))


def _body_tex(x, y, f, hw, hl, wheel_ys, door_us=(), stripe=None, arch=6.6):
    def tex(Pw, Nw):
        px, py, pz = Pw[:, 0], Pw[:, 1], Pw[:, 2]
        u = f * (py - y)
        fy = Nw[:, 1] * f
        mi = np.zeros(len(px), int)
        sh = np.zeros(len(px), int)
        lat = np.abs(px - x)
        front = fy > 0.55
        rear = fy < -0.55
        side = np.abs(Nw[:, 0]) > 0.7
        mi = np.where(front & (lat > hw - 6) & (pz > 7.5) & (pz < 10.5), 1, mi)
        mi = np.where(front & (lat < hw - 7.5) & (pz > 5) & (pz < 9), 3, mi)
        mi = np.where((front | rear) & (pz < 5), 4, mi)
        mi = np.where(rear & (lat > hw - 5) & (pz > 7.5) & (pz < 10.5), 2, mi)
        for wy in wheel_ys:
            rr = np.hypot(py - wy, pz - 4.6)
            mi = np.where(side & (rr < arch), 3, mi)
        for du in door_us:
            sh = np.where(side & (np.abs(u - du) < 0.5) & (pz > 5), sh + 1, sh)
        sh = np.where(side & (pz < 4.6), sh + 1, sh)
        if stripe is not None:
            z0, z1 = stripe
            mi = np.where(side & (pz > z0) & (pz < z1) & (mi == 0), 5, mi)
        return mi, sh
    return tex


def car(s, x, y, along='y', body=None, glass=None, length=58, width=26, front=None):
    """Sedan: bodi bawah dengan sudut ditumpulkan, kabin trapesium (kaca depan dan belakang miring)."""
    body = body or Mat('#E7E9EE', '#C9CDD6', '#8E94A2')
    f = front if front is not None else (1 if x > 0 else -1)
    hl, hw = length / 2, width / 2
    zb, zt = 3.0, 12.0
    Y = np.array([0, f, 0.0])
    planes = [((1, 0, 0), x + hw), ((-1, 0, 0), -(x - hw)), ((0, 0, 1), zt), ((0, 0, -1), -zb),
              (Y, f * y + hl), (-Y, -f * y + hl),
              (np.array([0, f, 1.0]), f * y + hl + zt - 3.5),            # kap depan miring
              (np.array([0, -f, 1.0]), -f * y + hl + zt - 2.5),          # bagasi
              ((1, 0, 1), x + hw + zt - 1.5), ((-1, 0, 1), -(x - hw) + zt - 1.5)]
    for sx in (-1, 1):
        for sy in (-1, 1):
            n = np.array([sx, sy * f, 0.0])
            planes.append((n, sx * x + sy * f * y + hw + hl - 3.0))
    wys = (y + f * hl * 0.6, y - f * hl * 0.62)
    s.add(_conv(planes, (x - hw, y - hl, zb), (x + hw, y + hl, zt),
                [body, LAMP_F, LAMP_R, TRIM, RIM, body], _body_tex(x, y, f, hw, hl, wys, door_us=(hl * 0.05, -hl * 0.32))))
    pid = s.prims[-1].part
    # kabin
    z0, z1 = zt, zt + 9.0
    uf0, uf1 = hl * 0.22, -hl * 0.02      # kaca depan: dari bawah ke atap
    ur0, ur1 = -hl * 0.6, -hl * 0.44      # kaca belakang
    kf = (uf0 - uf1) / (z1 - z0)
    kr = (ur1 - ur0) / (z1 - z0)
    ks = 2.2 / (z1 - z0)
    cp = [((0, 0, 1), z1), ((0, 0, -1), -z0),
          (np.array([0, f, kf]), f * y + uf0 + kf * z0),
          (np.array([0, -f, kr]), -f * y - ur0 + kr * z0),
          (np.array([1, 0, ks]), x + hw - 1.2 + ks * z0), (np.array([-1, 0, ks]), -(x - hw + 1.2) + ks * z0)]
    bu = -hl * 0.18

    def ctex(Pw, Nw):
        pz = Pw[:, 2]
        u = f * (Pw[:, 1] - y)
        roof = Nw[:, 2] > 0.85
        g = (~roof) & (pz > z0 + 1.2) & (pz < z1 - 0.8)
        side = np.abs(Nw[:, 0]) > 0.6
        g &= ~(side & (np.abs(u - bu) < 1.3))
        return np.where(g, 0, 1), 0
    s.add(_conv(cp, (x - hw, y - hl, z0), (x + hw, y + hl, z1), [GLASS_CAR, body], ctex, part=pid))
    _wheels(s, x, hw - 0.2, wys)


def angkot(s, x, y, body=None, length=44, width=22, front=None, stripe=None):
    """Angkot (minibus): kap pendek, kaca depan miring, deret jendela samping, rak atap, pintu geser terbuka."""
    body = body or Mat('#B6E4F2', '#7CC6E2', '#4A8EAE')
    stripe = stripe or Mat('#FFE08A', '#FFC94A', '#C98E2A')
    f = front if front is not None else (1 if x > 0 else -1)
    hl, hw = length / 2, width / 2
    zb, zt = 3.0, 24.0
    Y = np.array([0, f, 0.0])
    kw = 0.55
    planes = [((1, 0, 0), x + hw), ((-1, 0, 0), -(x - hw)), ((0, 0, 1), zt), ((0, 0, -1), -zb),
              (Y, f * y + hl), (-Y, -f * y + hl),
              (np.array([0, f, kw]), f * y + hl - 5 + kw * 12),          # kaca depan miring mulai z 12
              (np.array([0, f, 1.4]), f * y + hl + 1.4 * 9.5),          # ujung kap membulat
              ((1, 0, 1), x + hw + zt - 1.5), ((-1, 0, 1), -(x - hw) + zt - 1.5)]
    for sx in (-1, 1):
        for sy in (-1, 1):
            planes.append((np.array([sx, sy * f, 0.0]), sx * x + sy * f * y + hw + hl - 2.5))
    wys = (y + f * hl * 0.58, y - f * hl * 0.6)
    base = _body_tex(x, y, f, hw, hl, wys, stripe=(9.5, 11.5))

    def tex(Pw, Nw):
        mi, sh = base(Pw, Nw)
        pz = Pw[:, 2]
        u = f * (Pw[:, 1] - y)
        side = np.abs(Nw[:, 0]) > 0.7
        lat = Pw[:, 0] - x
        roof = Nw[:, 2] > 0.85
        winband = side & (pz > 13.5) & (pz < 20.5) & (u < hl - 7)
        pillar = np.mod(u + hl, 9.0) < 1.4
        mi = np.where(winband & ~pillar, 6, mi)
        # pintu geser terbuka di sisi kiri (penumpang naik dari trotoar)
        door = side & (lat * f < 0) & (u > -hl * 0.2) & (u < hl * 0.2) & (pz > 4) & (pz < 21)
        mi = np.where(door, 7, mi)
        ws = (Nw @ np.array([0, f, 0.0]) > 0.3) & (Nw[:, 2] > 0.3) & (pz > 13) & (pz < zt - 1)
        mi = np.where(ws & (np.abs(lat) < hw - 2), 6, mi)
        sh = np.where(roof & ((np.mod(u, 6) < 0.8)), sh + 1, sh)
        return mi, sh
    s.add(_conv(planes, (x - hw, y - hl, zb), (x + hw, y + hl, zt),
                [body, LAMP_F, LAMP_R, TRIM, RIM, stripe, GLASS_CAR, Mat('#4A4450', '#3A3440', '#26222C')], tex))
    _wheels(s, x, hw - 0.2, wys, r=4.4)


def bus_kecil(s, x, y, body=None, upper=None, length=74, width=24, front=None):
    """Bus kecil kota (sedang): bodi kotak tinggi dengan sudut tumpul, kaca depan hampir tegak,
    papan trayek di atas kaca, deret jendela panjang, dua warna, pintu terbuka di depan sisi trotoar."""
    body = body or Mat('#FF9A6A', '#E8683E', '#A44428')
    upper = upper or Mat('#FBF6E8', '#F2E7C9', '#C2AF86')
    f = front if front is not None else (1 if x > 0 else -1)
    hl, hw = length / 2, width / 2
    zb, zt = 3.0, 31.0
    Y = np.array([0, f, 0.0])
    kw = 0.12
    planes = [((1, 0, 0), x + hw), ((-1, 0, 0), -(x - hw)), ((0, 0, 1), zt), ((0, 0, -1), -zb),
              (Y, f * y + hl), (-Y, -f * y + hl),
              (np.array([0, f, kw]), f * y + hl + kw * 13),             # kaca depan sedikit miring
              (np.array([0, f, 1.0]), f * y + hl + zt - 2.5),            # sudut atap depan
              (np.array([0, -f, 1.0]), -f * y + hl + zt - 2.0),
              ((1, 0, 1), x + hw + zt - 1.5), ((-1, 0, 1), -(x - hw) + zt - 1.5)]
    for sx in (-1, 1):
        for sy in (-1, 1):
            planes.append((np.array([sx, sy * f, 0.0]), sx * x + sy * f * y + hw + hl - 2.5))
    wys = (y + f * hl * 0.6, y - f * hl * 0.55)
    base = _body_tex(x, y, f, hw, hl, wys, stripe=(12.5, 14.0), arch=6.2)

    def tex(Pw, Nw):
        mi, sh = base(Pw, Nw)
        pz = Pw[:, 2]
        u = f * (Pw[:, 1] - y)
        lat = Pw[:, 0] - x
        side = np.abs(Nw[:, 0]) > 0.7
        frontf = (Nw @ np.array([0, f, 0.0])) > 0.5
        upperz = (pz > 14) & (mi == 0)
        mi = np.where(upperz, 8, mi)
        win = side & (pz > 16) & (pz < 26) & (u < hl - 3) & (u > -hl + 4)
        pillar = np.mod(u + hl, 11.0) < 1.5
        mi = np.where(win & ~pillar, 6, mi)
        door = side & (lat * f < 0) & (u > hl - 15) & (u < hl - 5) & (pz > 4) & (pz < 27)
        mi = np.where(door, 7, mi)
        ws = frontf & (pz > 14) & (pz < 26) & (np.abs(lat) < hw - 1.5)
        mi = np.where(ws, 6, mi)
        sign = frontf & (pz >= 26.5) & (pz < 29.5) & (np.abs(lat) < hw - 3)
        mi = np.where(sign, 9, mi)
        mi = np.where(sign & text_band(lat * f, pz), 8, mi)
        return mi, sh
    s.add(_conv(planes, (x - hw, y - hl, zb), (x + hw, y + hl, zt),
                [body, LAMP_F, LAMP_R, TRIM, RIM, body, GLASS_CAR, Mat('#4A4450', '#3A3440', '#26222C'), upper,
                 Mat('#3A3440', '#2C2632', '#1C1822')], tex))
    _wheels(s, x, hw - 0.2, wys, r=4.8)


def text_band(u, z):
    """Huruf trayek kecil (pola blok) untuk papan bus."""
    return (np.mod(np.floor(u / 1.0), 4) != 3) & (np.mod(np.floor(u / 4.0), 3) != 2) & (np.abs(z - 28) < 0.9) & \
           (hash2(np.floor(u), np.floor(z), 5) > 0.35)


def motor(s, x, y, body=None, along='y'):
    body = body or P['red']
    s.add(box(x - 2.5, x + 2.5, y - 9, y + 9, 5, 9, body))
    s.add(box(x - 3, x + 3, y - 3, y + 6, 9, 12, P['metal_dk']))  # seat
    s.add(box(x - 1, x + 1, y - 11, y - 8, 9, 17, P['metal_dk']))  # fork / handle
    s.add(box(x - 4, x + 4, y - 11, y - 10, 16, 17, P['metal_dk']))
    for wy in (y - 10, y + 9):
        s.add(cyl((wy, 4), 4, x - 1.2, x + 1.2, axis=0, mats=P['metal_dk']))


def bench(s, x0, x1, y0, y1, h=8, mat=None):
    mat = mat or P['wood']
    s.add(box(x0, x1, y0, y1, h - 1.5, h, mat))
    for (a, b) in ((x0, y0), (x1 - 1, y0), (x0, y1 - 1), (x1 - 1, y1 - 1)):
        s.add(box(a, a + 1, b, b + 1, 0, h - 1.5, mat))


# ---------------- animated details ----------------

def chicken(s, x, y, yaw=0.0, phase=0.0, mode='walk', col=None, tail=None, comb=None, size=1.0):
    """yaw: heading angle in world xy (0 = toward -y, i.e. up-right). phase 0..1."""
    col = col or Mat('#FFFFFF', '#F2E7C9', '#C2AF86')
    tail = tail or col
    comb = comb or Mat('#F06A4E', '#D94F3D', '#8E2E25')
    beak = Mat('#FFD86A', '#F2B33D', '#B97A22')
    f = np.array([math.sin(yaw), -math.cos(yaw), 0.0])     # forward
    r = np.array([math.cos(yaw), math.sin(yaw), 0.0])      # right
    up = np.array([0, 0, 1.0])
    k = size
    base = np.array([x, y, 0.0])
    bob = 0.6 * abs(math.sin(phase * 2 * math.pi)) if mode == 'walk' else 0.0
    peck = 0.0
    if mode == 'peck':
        peck = max(0.0, math.sin(phase * 2 * math.pi))       # 0..1
    R = np.stack([f, r, up])
    body_c = base + up * (6.0 + bob) * k
    s.add(ellip(body_c, (4.6 * k, 3.0 * k, 3.4 * k), col, None, R=R, part=None))
    pid = s.prims[-1].part
    # tail (up and back)
    s.add(ellip(body_c - f * 4.2 * k + up * 2.6 * k, (1.6 * k, 1.4 * k, 2.8 * k), tail, None, R=R, part=pid))
    # head
    hp = body_c + f * (3.6 + 2.0 * peck) * k + up * (3.6 - 6.5 * peck) * k
    s.add(ellip(hp, (2.0 * k, 1.8 * k, 2.0 * k), col, None, R=R, part=pid))
    s.add(ellip(hp + up * 1.9 * k, (1.2 * k, 0.7 * k, 1.0 * k), comb, None, R=R, part=pid))
    s.add(ellip(hp + f * 2.0 * k - up * 0.2 * k, (1.1 * k, 0.6 * k, 0.6 * k), beak, None, R=R, part=pid))
    # legs
    sw = math.sin(phase * 2 * math.pi) if mode == 'walk' else 0.0
    for side, sg in ((-1, 1), (1, -1)):
        foot = base + r * side * 1.2 * k + f * sg * sw * 1.4 * k
        top = body_c - up * 2.4 * k + r * side * 1.0 * k
        c = (foot + top) / 2
        s.add(obox(c, f, r, top - foot, 0.5 * k, 0.5 * k, np.linalg.norm(top - foot) / 2,
                   beak, None, part=pid))


def clothes_line(s, p0, p1, items, sway=0.0, t=0.0, pole_h=None, rope=None):
    """Clothes hanging on a line from p0 to p1 (both (x,y,z)). items: list of (pos 0..1, width, height, mat).
    sway: amplitude in radians; t: animation phase 0..1. Rope is drawn as an overlay."""
    p0, p1 = np.asarray(p0, float), np.asarray(p1, float)
    ax = p1 - p0
    L = np.linalg.norm(ax)
    a = ax / L
    hz = np.cross(a, [0, 0, 1.0]); hz /= np.linalg.norm(hz)   # horizontal, perpendicular to line
    for i, it in enumerate(items):
        pos, w, h, mat = it[:4]
        kind = it[4] if len(it) > 4 else 'kain'
        ang = sway * math.sin(2 * math.pi * (t + i * 0.17))
        down = np.array([0, 0, -1.0]) * math.cos(ang) + hz * math.sin(ang)
        sag = 1.6 * math.sin(math.pi * pos)
        top = p0 + ax * pos + np.array([0, 0, -sag])
        if kind == 'kaus':
            pieces = [(0, 0, w + 5, 4), (0, 0, w, h)]
        elif kind == 'celana':
            pieces = [(0, 0, w, 3), (-w / 4, 0, w / 2 - 0.6, h), (w / 4, 0, w / 2 - 0.6, h)]
        else:
            pieces = [(0, 0, w, h)]
        pid = None
        for (uo, d0, pw, ph) in pieces:
            c = top + a * uo + down * (d0 + ph / 2)
            tex = None
            if kind == 'handuk':
                tex = lambda Pw, Nw, tp=top, dn=down: (0, np.where(np.abs(((Pw - tp) @ dn) - 2.2) < 0.8, -1, 0))
            elif kind == 'sarung':
                tex = lambda Pw, Nw, tp=top, dn=down, ax_=a: (0, np.where((np.mod((Pw - tp) @ ax_, 4) < 1) | (np.mod((Pw - tp) @ dn, 4) < 1), 1, 0))
            s.add(obox(c, a, np.cross(a, down), down, pw / 2, 0.6, ph / 2, mat, tex, cast=True, part=pid))
            pid = s.prims[-1].part
    s.ropes = getattr(s, 'ropes', [])
    s.ropes.append((p0, p1))


def draw_ropes(s, img, col=(46, 40, 54)):
    for p0, p1 in getattr(s, 'ropes', []):
        n = int(np.linalg.norm(p1 - p0) * 1.5) + 2
        for i in range(n + 1):
            t = i / n
            p = p0 + (p1 - p0) * t + np.array([0, 0, -1.6 * math.sin(math.pi * t)])
            sx, sy = s.proj(p)
            X, Y = int(math.floor(sx[0])), int(math.floor(sy[0]))
            if 0 <= X < s.W and 0 <= Y < s.H:
                # only draw if not hidden: compare depth with buffer
                k = Y * s.W + X
                dep = p.sum()
                Pb = s._buf['P'][k]
                if Pb.sum() <= dep + 1.5:
                    img[Y, X] = col
    return img


def wires(s, img, pts, sag=6, col=(38, 33, 46)):
    for p0, p1 in zip(pts[:-1], pts[1:]):
        p0, p1 = np.asarray(p0, float), np.asarray(p1, float)
        n = int(np.linalg.norm(p1 - p0) * 1.6) + 2
        for i in range(n + 1):
            t = i / n
            p = p0 + (p1 - p0) * t + np.array([0, 0, -sag * 4 * t * (1 - t)])
            sx, sy = s.proj(p)
            X, Y = int(math.floor(sx[0])), int(math.floor(sy[0]))
            if 0 <= X < s.W and 0 <= Y < s.H:
                img[Y, X] = col
    return img


def smoke(s, img, src, t, n=7, rise=34, drift=(6, -4), col_hi=(246, 242, 236), col_mid=(214, 208, 206),
          col_lo=(168, 162, 170), tint=(1, 1, 1), seed=0):
    """Pixel smoke puffs rising from src (world). t in 0..1 loops. Three tones lit from the upper left."""
    rng = np.random.default_rng(seed)
    offs = rng.random(n)
    jit = rng.random((n, 2)) * 2 - 1
    tint = np.array(tint, np.float32)
    H, W = img.shape[:2]
    puffs = []
    for i in range(n):
        u = (t + i / n) % 1.0
        z = 2 + rise * u
        wob = math.sin((u * 2.2 + offs[i] * 0.3) * 2 * math.pi) * 2.0
        p = np.array(src, float) + np.array([drift[0] * u * u + wob * 0.7 + jit[i, 0] * 0.6,
                                             drift[1] * u * u - wob * 0.7 + jit[i, 1] * 0.6, z])
        r = 1.8 + 4.4 * u
        a = 0.92 if u < 0.3 else (0.74 if u < 0.55 else (0.5 if u < 0.78 else (0.26 if u < 0.92 else 0.0)))
        puffs.append((p, r, a))
    puffs.sort(key=lambda q: -q[0][2])
    for p, r, a in puffs:
        if a <= 0:
            continue
        sx, sy = s.proj(p)
        cx, cy = sx[0], sy[0]
        x0, x1 = int(cx - r - 1), int(cx + r + 2)
        y0, y1 = int(cy - r - 1), int(cy + r + 2)
        for Y in range(max(0, y0), min(H, y1)):
            for X in range(max(0, x0), min(W, x1)):
                dx, dy = X + 0.5 - cx, Y + 0.5 - cy
                d2 = dx * dx + dy * dy
                if d2 <= r * r:
                    k = dx + dy
                    col = col_hi if k < -0.35 * r else (col_lo if k > 0.5 * r else col_mid)
                    c = np.array(col, np.float32) * tint
                    img[Y, X] = img[Y, X] * (1 - a) + c * a
    return img


ANT_DIR = np.array([0.82, -0.57, 0.0])   # semua antena menghadap arah pemancar yang sama


def antena(s, x, y, z0, z1, n=5, boom=16, seed=0, mat=None, tiang=None):
    """Antena TV Yagi: tiang dari dalam atap, boom mendatar, elemen silang makin pendek ke depan."""
    mat = mat or Mat('#B4B0BA', '#8A8692', '#5A5662')
    tiang = tiang or mat
    rng = np.random.default_rng(seed)
    d = ANT_DIR.copy()
    a = math.atan2(d[1], d[0]) + (rng.random() - 0.5) * 0.25
    d = np.array([math.cos(a), math.sin(a), 0.0])
    side = np.array([-d[1], d[0], 0.0])
    up = np.array([0, 0, 1.0])
    s.add(cyl((x, y), 0.8, z0, z1, mats=tiang))
    pid = s.prims[-1].part
    top = np.array([x, y, z1 - 1.0])
    c = top + d * boom * 0.25
    s.add(obox(c, d, side, up, boom / 2, 0.5, 0.5, mat, part=pid))
    for i in range(n):
        t = i / (n - 1)
        p = top + d * (-boom * 0.25 + boom * t)
        L = 11 - 6 * t
        s.add(obox(p, side, d, up, L / 2, 0.5, 0.45, mat, part=pid))
    # kawat penahan pendek: elemen kedua lebih rendah di tiang
    s.add(obox(top - up * 5 + d * 1.5, side, d, up, 3.5, 0.45, 0.45, mat, part=pid))
