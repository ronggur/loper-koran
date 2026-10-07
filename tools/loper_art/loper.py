"""Model pengendara + sepeda dari kapsul, bola, dan kotak.

Koordinat lokal (a, b, c) = (maju, kanan, atas) dalam unit dunia (1 ubin = 32 unit).
build(cfg, phi_deg) mengembalikan (Model, titik bayangan). phi_deg = sudut pedal kanan.
VARIANTS (a-d, dengan tas selempang) dan VARIANTS_NOBAG (e-h) adalah varian baju; h = Kemeja Agen.
"""
import math
import numpy as np
import iso
from iso import Model, mat, flat, hexc, L2W, W2L, LIGHT

R = 6.5
REAR = np.array([0.0, 0.0, R])
FRONT = np.array([17.0, 0.0, R])
BB = np.array([6.6, 0.0, 5.6])
S = np.array([5.0, 0.0, 15.0])
HT = np.array([14.5, 0.0, 15.4])
HB = np.array([15.1, 0.0, 12.6])
HIP_C = np.array([3.0, 0.0, 18.3])
SHOULDER_C = np.array([7.6, 0.0, 27.3])
HEAD = np.array([9.6, 0.0, 34.0])
HR = 4.5

SKINS = {
    'sawo': mat('#d89a6c', '#b47c5f', '#8a5a40'),
    'terang': mat('#f2b98c', '#e8a07a', '#b47c5f'),
}
HAIR = mat('#8a5a40', '#6d4334', '#4a2319')
GRAY = mat('#c4c0c8', '#969aa0', '#67636d')
DARK = mat('#5f5b66', '#3d4649', '#221e26')
TIRE = flat('#2a1e17')
PAPER = mat('#fbf6e8', '#f2e7c9', '#c2af86')
PAPER2 = mat('#ffffff', '#d8d4dc', '#a9a2ae')


def v(a, b, c):
    return np.array([a, b, c], float)


def leg_ik(hip, foot, l1, l2):
    """2-link IK in the (a,c) plane, knee bends forward (+a)."""
    ha, hc = hip[0], hip[2]
    fa, fc = foot[0], foot[2]
    dx, dy = fa - ha, fc - hc
    d = min(math.hypot(dx, dy), l1 + l2 - 1e-3)
    base = math.atan2(dy, dx)
    k = math.acos(max(-1, min(1, (l1 * l1 + d * d - l2 * l2) / (2 * l1 * d))))
    best = None
    for sg in (1, -1):
        ang = base + sg * k
        ka, kc = ha + l1 * math.cos(ang), hc + l1 * math.sin(ang)
        if best is None or ka > best[0]:
            best = (ka, kc)
    return v(best[0], (hip[1] + foot[1]) / 2, best[1])


def stripes(m1, m2, period=2):
    def f(P, N):
        d = N @ LIGHT
        z = np.floor(P[:, 2] + 0.5).astype(int)
        use2 = (z % period) == 0
        out = np.empty((len(P), 3), np.uint8)
        for m, sel in ((m1, ~use2), (m2, use2)):
            o = np.empty((sel.sum(), 3), np.uint8)
            dd = d[sel]
            o[:] = m[1]
            o[dd > 0.78] = m[0]
            o[dd < -0.12] = m[2]
            out[sel] = o
        return out
    return f


def band(m1, m2, z0, z1):
    def f(P, N):
        d = N @ LIGHT
        sel2 = (P[:, 2] >= z0) & (P[:, 2] < z1)
        out = np.empty((len(P), 3), np.uint8)
        for m, sel in ((m1, ~sel2), (m2, sel2)):
            o = np.empty((sel.sum(), 3), np.uint8)
            dd = d[sel]
            o[:] = m[1]
            o[dd > 0.78] = m[0]
            o[dd < -0.12] = m[2]
            out[sel] = o
        return out
    return f


DEF_HIP, DEF_SHOULDER, DEF_HEAD = HIP_C.copy(), SHOULDER_C.copy(), HEAD.copy()


def arm_ik(s, h, l1=5.6, l2=5.0):
    d = h - s
    L = np.linalg.norm(d)
    if L >= l1 + l2 - 1e-3:
        return s + d * l1 / (l1 + l2)
    x = (l1 * l1 - l2 * l2 + L * L) / (2 * L)
    hgt = math.sqrt(max(l1 * l1 - x * x, 0))
    u = d / L
    perp = np.array([-u[2], 0.0, u[0]])      # in the a-c plane
    if perp[0] > 0:
        perp = -perp                        # elbow points backward
    return s + u * x + perp * hgt


def build(cfg, phi_deg=-40):
    global HIP_C, SHOULDER_C, HEAD
    HIP_C = np.array(cfg.get('hip', DEF_HIP), float)
    SHOULDER_C = np.array(cfg.get('shoulder', DEF_SHOULDER), float)
    HEAD = np.array(cfg.get('head', DEF_HEAD), float)
    M = Model()
    steer = math.radians(cfg.get('steer', 0.0))
    if steer:
        ax = (HT - HB) / np.linalg.norm(HT - HB)
        K = np.array([[0, -ax[2], ax[1]], [ax[2], 0, -ax[0]], [-ax[1], ax[0], 0]])
        Rm = np.eye(3) + math.sin(steer) * K + (1 - math.cos(steer)) * K @ K

        def xf(P, N):
            return (P - HB) @ Rm.T + HB, N @ Rm.T

        def steer_pt(p):
            return (np.asarray(p, float) - HB) @ Rm.T + HB
    else:
        xf = None

        def steer_pt(p):
            return np.asarray(p, float)

    rr = math.radians(cfg.get('bike_roll', 0.0))   # bike rocks under the rider (sprint)
    Rr = np.array([[1, 0, 0], [0, math.cos(rr), math.sin(rr)], [0, -math.sin(rr), math.cos(rr)]]).T

    def roll_pt(p):
        return np.asarray(p, float) @ Rr if rr else np.asarray(p, float)

    def make_xf(on_front):
        if not on_front and not rr:
            return None

        def f(P, N):
            if on_front and xf is not None:
                P, N = xf(P, N)
            if rr:
                P, N = P @ Rr, N @ Rr
            return P, N
        return f

    def front(on):
        M.xf = make_xf(on)

    def rider():
        M.xf = None
    skin = SKINS[cfg['skin']]
    phi = math.radians(phi_deg)

    # ---------------- bike ----------------
    p_tire = M.part('tire', outline=False)
    p_rim = M.part('rim', outline=False)
    p_frame = M.part('frame', outline=False)
    p_bar = M.part('bar', outline=False)
    for C in (REAR, FRONT):
        front(C is FRONT)
        M.ring(C, R - 1.0, R, 0.45, TIRE, p_tire)
        M.ring(C, R - 1.55, R - 1.15, 0.2, GRAY, p_rim)
        M.sphere(C, 0.6, GRAY, p_rim)
    front(False)
    fr = cfg['bike']
    fr = (fr[1], fr[1], fr[2])          # two tones only: thin tubes stay clean
    if cfg.get('fenders', False):
        M.ring(REAR, R + 0.5, R + 0.9, 0.45, fr, p_frame, a0=40, a1=170)
        M.ring(FRONT, R + 0.5, R + 0.9, 0.45, fr, p_frame, a0=30, a1=140)
    # chainring + chain + right crank (camera side)
    M.ring(BB, 1.3, 2.0, 0.25, GRAY, p_rim, lat=1.3)
    M.capsule(BB + v(0, 1.3, 2.0), REAR + v(0, 1.3, 0.9), 0.2, DARK, p_rim, step=0.15)
    M.capsule(BB + v(0, 1.3, -2.0), REAR + v(0, 1.3, -0.9), 0.2, DARK, p_rim, step=0.15)
    # frame tubes
    tubes = [(BB, S, 0.5), (S + v(0, 0, 0.2), HT, 0.45), (BB, HB, 0.5),
             (BB + v(0, 0.7, 0), REAR + v(0, 0.7, 0), 0.4), (BB + v(0, -0.7, 0), REAR + v(0, -0.7, 0), 0.4),
             (S + v(0, 0.6, 0), REAR + v(0, 0.7, 0), 0.4), (S + v(0, -0.6, 0), REAR + v(0, -0.7, 0), 0.4),
             (HT, HB, 0.6)]
    for a, b, r in tubes:
        M.capsule(a, b, r, fr, p_frame)
    front(True)
    for a, b, r in ((HB + v(0, 0.8, 0), FRONT + v(0, 0.8, 0), 0.36), (HB + v(0, -0.8, 0), FRONT + v(0, -0.8, 0), 0.36)):
        M.capsule(a, b, r, fr, p_frame)
    front(False)
    # seatpost + saddle
    M.capsule(S, v(4.6, 0, 16.4), 0.4, GRAY, p_bar)
    p_saddle = M.part('saddle')
    M.box(v(4.3, 0, 16.7), v(1, 0, 0), v(0, 1, 0), v(0, 0, 1), 1.9, 1.0, 0.45, mat('#553428', '#3b2219', '#2a1e17'), p_saddle)
    # stem + handlebar
    front(True)
    M.capsule(HT, v(14.3, 0, 17.6), 0.4, GRAY, p_bar)
    M.capsule(v(14.2, -3.6, 17.7), v(14.2, 3.6, 17.7), 0.38, DARK, p_bar)
    M.capsule(v(13.6, 3.0, 17.8), v(13.6, 3.9, 17.8), 0.55, DARK, p_bar)
    M.capsule(v(13.6, -3.0, 17.8), v(13.6, -3.9, 17.8), 0.55, DARK, p_bar)
    if cfg.get('lamp'):
        p_l = M.part('lamp')
        M.box(v(15.6, 0, 15.0), v(1, 0, 0), v(0, 1, 0), v(0, 0, 1), 0.7, 0.8, 0.7, mat('#ffffff', '#f2e7c9', '#c2af86'), p_l)
        M.box(v(16.35, 0, 15.0), v(1, 0, 0), v(0, 1, 0), v(0, 0, 1), 0.08, 0.5, 0.45, flat('#ffc94a'), p_l, bias=0.3)
    front(False)

    # rack
    p_rack = M.part('rack', outline=False)
    M.box(v(-0.2, 0, 13.6), v(1, 0, 0), v(0, 1, 0), v(0, 0, 1), 3.6, 1.4, 0.25, DARK, p_rack)
    for bb in (1.0, -1.0):
        M.capsule(v(-2.8, bb, 13.4), REAR + v(0, bb, 0), 0.25, DARK, p_rack)
        M.capsule(v(2.6, bb, 13.4), REAR + v(0, bb, 0), 0.25, DARK, p_rack)
    if cfg.get('rear_reflector'):
        M.box(v(-3.9, 0, 13.3), v(1, 0, 0), v(0, 1, 0), v(0, 0, 1), 0.15, 0.8, 0.4, flat('#d94f3d'), p_rack, bias=0.2)

    # panniers (both sides of the rack) with newspapers
    pan = cfg['pannier']
    for side in (1, -1):
        pp = M.part(f'pannier{side}')
        pc = v(0.1, side * 2.5, 10.6)
        M.box(pc, v(1, 0, 0), v(0, 1, 0), v(0, 0, 1), 3.0, 0.95, 3.0, pan, pp)
        rim = M.part(f'pannier_rim{side}')
        M.box(pc + v(0, 0, 2.55), v(1, 0, 0), v(0, 1, 0), v(0, 0, 1), 3.05, 1.0, 0.45,
              tuple(tuple(max(0, int(ch * 0.78)) for ch in col) for col in pan), rim, bias=0.05)
        # strap on the outer face
        sp = M.part(f'pannier_strap{side}', outline=False)
        for sa in (-1.4, 1.6):
            M.box(pc + v(sa, side * 1.0, -0.2), v(1, 0, 0), v(0, 1, 0), v(0, 0, 1), 0.35, 0.08, 2.4,
                  cfg['pannier_strap'], sp, bias=0.15)
        # newspapers sticking out (folded stacks)
        for k, (pa, tilt) in enumerate(((-1.7, 0.0), (0.0, 0.0), (1.8, 0.0))):
            pz = M.part(f'paper{side}{k}')
            h = 2.0 + (0.6 if k == 1 else 0) + (0.3 if (k == 0) == (side > 0) else 0)
            M.box(pc + v(pa, 0, 3.0 + h / 2 - 0.6), v(1, 0, 0), v(0, 1, 0), v(0, 0, 1), 0.65, 0.75, h / 2 + 0.3,
                  PAPER if k != 1 else PAPER2, pz)

    # ---------------- rider ----------------
    rider()
    pants = cfg['pants']
    shirt = cfg['shirt']
    long_pants = cfg.get('long_pants', False)
    # pedals / feet
    crank = 3.0
    for side, ph in ((1, phi), (-1, phi + math.pi)):
        pedal = BB + v(crank * math.cos(ph), side * 2.6, crank * math.sin(ph))
        pc = M.part(f'crank{side}', outline=False)
        front(False)
        M.capsule(BB + v(0, side * 1.5, 0), pedal + v(0, -side * 0.6, 0), 0.4, GRAY, pc)
        M.box(pedal + v(0, 0, -0.3), v(1, 0, 0), v(0, 1, 0), v(0, 0, 1), 1.0, 0.8, 0.25, DARK, pc)
        rider()
        hip = HIP_C + v(0, side * 1.6, 0)
        ankle = roll_pt(pedal + v(-0.6, 0, 1.3))
        knee = leg_ik(hip, ankle, 8.0, 8.1)
        p_leg = M.part(f'leg{side}')
        p_shin = M.part(f'shin{side}')
        p_shoe = M.part(f'shoe{side}')
        M.capsule(hip, knee, 1.45, pants, p_leg)
        if long_pants:
            M.capsule(knee, ankle, 1.15, pants, p_shin)
        else:
            cut = knee + (hip - knee) * 0.12
            M.capsule(cut, ankle, 1.0, skin, p_shin)
            M.capsule(hip, knee + (hip - knee) * 0.18, 1.5, pants, p_leg)
            if cfg.get('socks'):
                M.capsule(ankle + (knee - ankle) * 0.22, ankle, 1.05, cfg['socks'], p_shin, bias=0.05)
        M.box(ankle + v(0.9, 0, -0.9), v(1, 0, 0), v(0, 1, 0), v(0, 0, 1), 1.75, 0.95, 0.85, cfg['shoes'], p_shoe)

    # seat (butt) + torso
    p_torso = M.part('torso')
    M.capsule(HIP_C + v(-0.2, -1.4, 0.1), HIP_C + v(-0.2, 1.4, 0.1), 2.0, pants, p_torso)
    w = SHOULDER_C - HIP_C
    Ld = np.linalg.norm(w)
    w = w / Ld
    vv = np.array([-w[2], 0, w[0]])  # backward-up (toward the back)
    if vv[0] > 0:
        vv = -vv
    mid = (HIP_C + SHOULDER_C) / 2 + vv * 0.1
    M.box(mid, vv, v(0, 1, 0), w, 1.85, 2.35, Ld / 2, cfg.get('shirt_fn', shirt), p_torso, hv_end=2.9)

    if cfg.get('crossbag', True):
        # crossbody bag: strap across the back from left shoulder to right hip, bag on right hip
        p_strap = M.part('strap', outline=False)
        back = lambda p: p + vv * 1.95
        s0 = back(SHOULDER_C + v(0, -2.3, 0) - w * 0.8)
        s1 = back(HIP_C + v(0, 2.4, 0) + w * 2.4)
        M.capsule(s0, s1, 0.42, cfg['strap'], p_strap, bias=0.3)
        M.capsule(SHOULDER_C + v(0, -2.3, 0.4) - w * 0.6 + vv * 1.6, SHOULDER_C + v(0, -2.3, 0.4) - w * 0.6 - vv * 1.6, 0.42,
                  cfg['strap'], p_strap, bias=0.3)
        p_bag = M.part('crossbag')
        bc = HIP_C + v(-0.6, 3.3, 2.4)
        M.box(bc, v(1, 0, 0), v(0, 1, 0), v(0, 0, 1), 1.9, 0.75, 1.7, cfg['bag'], p_bag)
        p_flap = M.part('crossbag_flap')
        M.box(bc + v(0, 0.12, 0.75), v(1, 0, 0), v(0, 1, 0), v(0, 0, 1), 1.95, 0.75, 0.95,
              tuple(tuple(max(0, int(ch * 0.8)) for ch in col) for col in cfg['bag']), p_flap, bias=0.05)
        p_bpaper = M.part('crossbag_paper')
        M.box(bc + v(-1.0, 0, 2.0), v(1, 0, 0), v(0, 1, 0), v(0, 0, 1), 0.55, 0.5, 0.8, PAPER, p_bpaper)
    if cfg.get('hood'):
        p_hood = M.part('hood')
        M.sphere(SHOULDER_C + vv * 1.9 + v(-0.2, 0, 0.3), 1.9, shirt, p_hood)
    if cfg.get('basket'):
        front(True)
        p_bk = M.part('basket')
        M.box(v(16.9, 0, 16.4), v(1, 0, 0), v(0, 1, 0), v(0, 0, 1), 1.6, 2.1, 1.3, mat('#dccba6', '#bfa67c', '#96643c'), p_bk)
        M.box(v(16.9, 0, 17.55), v(1, 0, 0), v(0, 1, 0), v(0, 0, 1), 1.65, 2.15, 0.3, mat('#b47c5f', '#96643c', '#673f31'), M.part('basket_rim'), bias=0.05)
        for k, bb in enumerate((-1.0, 0.8)):
            M.box(v(16.7, bb, 18.3 + 0.3 * k), v(1, 0, 0), v(0, 1, 0), v(0, 0, 1), 0.7, 0.75, 1.0, PAPER if k == 0 else PAPER2, M.part(f'basket_paper{k}'))
        rider()

    # arms
    for side in (1, -1):
        sh = SHOULDER_C + v(-0.2, side * 3.2, -0.6)
        hand = roll_pt(steer_pt(v(13.6, side * 3.3, 18.2)))
        elbow = v(10.9, side * 3.6, 22.4)
        if cfg.get('arm_ik'):
            elbow = arm_ik(sh, hand) + v(0, side * 0.5, 0)
        pa = M.part(f'arm{side}')
        pf = M.part(f'forearm{side}')
        if cfg.get('long_sleeves'):
            M.capsule(sh, elbow, 1.15, shirt, pa)
            M.capsule(elbow, hand, 0.95, shirt, pf)
        else:
            M.capsule(sh + (elbow - sh) * 0.35, elbow, 0.9, skin, pa)
            M.capsule(sh, sh + (elbow - sh) * 0.5, 1.3, shirt, pa)
            M.capsule(elbow, hand, 0.85, skin, pf)
        M.sphere(hand, 0.95, skin, pf)

    # neck + head + hair + ear + eye
    pn = M.part('neck')
    M.capsule(SHOULDER_C + v(0.4, 0, 0.0), HEAD + v(-0.2, 0, -2.8), 1.25, skin, pn)
    ph = M.part('head')
    hair_line = HEAD[2] + 0.6

    def headmat(P, N):
        d = N @ LIGHT
        Lc = W2L(P)
        a = Lc[:, 0]
        z = Lc[:, 2]
        is_hair = (a < HEAD[0] - 0.5) & (z > HEAD[2] - 2.2)
        out = np.empty((len(P), 3), np.uint8)
        for m, sel in ((skin, ~is_hair), (HAIR, is_hair)):
            o = np.empty((sel.sum(), 3), np.uint8)
            dd = d[sel]
            o[:] = m[1]
            o[dd > 0.78] = m[0]
            o[dd < -0.12] = m[2]
            out[sel] = o
        return out
    M.sphere(HEAD, HR, headmat, ph, bias=1.6)
    pe = M.part('ear', outline=False)
    M.sphere(HEAD + v(-0.3, HR - 0.2, -0.3), 0.75, skin, pe, bias=1.8)
    pey = M.part('eye', outline=False)
    cam = W2L(np.array([1.0, 1.0, 1.0]))
    cam = cam / np.linalg.norm(cam)
    front_ok = cam[0] > 0.2
    if front_ok:
        ch = np.array([cam[0], cam[1], 0.0]); ch /= np.linalg.norm(ch)
        f = np.array([1.0, 0.0, 0.0]) + ch; f /= np.linalg.norm(f)
        base = math.atan2(f[1], f[0])
        eyes = [np.array([math.cos(base + s * 0.45), math.sin(base + s * 0.45), 0.2]) for s in (1, -1)]
    else:
        eyes = [np.array([0.42, 0.88, 0.02])]
    for ed in eyes:
        ed = ed / np.linalg.norm(ed)
        if ed @ cam < 0.05:
            continue
        M.capsule(HEAD + ed * (HR - 0.05) + v(0, 0, -0.25), HEAD + ed * (HR - 0.05) + v(0, 0, 0.35), 0.36, flat('#0e0a1c'), pey, bias=2.0)
    if front_ok:
        pm = M.part('mouth', outline=False)
        md = np.array([0.95, 0.12, -0.3]); md /= np.linalg.norm(md)
        mc = HEAD + md * (HR - 0.05)
        M.capsule(mc + v(0, -0.7, 0.15), mc + v(0, 0, -0.1), 0.28, flat('#7e3929'), pm, bias=2.0)
        M.capsule(mc + v(0, 0, -0.1), mc + v(0, 0.7, 0.15), 0.28, flat('#7e3929'), pm, bias=2.0)

    # ---- backwards cap ----
    cap = cfg['cap']
    pc = M.part('cap')
    brim_m = cfg.get('brim') or tuple(tuple(max(0, int(ch * 0.72)) for ch in col) for col in cap)

    def rim_z(a):
        return HEAD[2] + 0.6 - 0.28 * (HEAD[0] - a) + 0.42 * np.maximum(a - HEAD[0], 0)

    def capmat(P, N):
        Lc = W2L(P)
        a, b, z = Lc[:, 0], Lc[:, 1], Lc[:, 2]
        d = N @ LIGHT
        band = z < rim_z(a) + 0.55
        gap = np.zeros(len(P), bool)
        out = np.empty((len(P), 3), np.uint8)
        for m, sel in ((cap, ~band & ~gap), (brim_m, band & ~gap), (HAIR, gap)):
            o = np.empty((sel.sum(), 3), np.uint8)
            dd = d[sel]
            o[:] = m[1]
            o[dd > 0.78] = m[0]
            o[dd < -0.12] = m[2]
            out[sel] = o
        return out
    M.sphere(HEAD + v(0, 0, 0.05), HR + 0.08, capmat, pc, keep=lambda P, N: P[:, 2] > rim_z(P[:, 0]), bias=1.7)
    # brim points backwards (toward -a), slightly drooping
    pb = M.part('brim')
    brim_c = HEAD + v(-HR - 0.45, 0, -0.35)
    bu = np.array([1.0, 0, 0.45]); bu /= np.linalg.norm(bu)
    M.box(brim_c, bu, v(0, 1, 0), np.array([-bu[2], 0, bu[0]]), 1.15 * HR / 3.6, 2.0 * HR / 3.6, 0.3, brim_m, pb, bias=1.9)

    lean = iso.POSE['lean']
    iso.POSE['lean'] = 0.0
    shadow = M.ground_ellipse((8.5, 0.6), 13.0, 4.2)
    iso.POSE['lean'] = lean
    return M, shadow


VARIANTS = [
    dict(id='a', name='Merah Klasik', skin='terang',
         cap=mat('#e86a55', '#d94f3d', '#a24935'),
         shirt=mat('#ffb366', '#e98e3f', '#b5523b'),
         pants=mat('#7480a3', '#5c6a8c', '#404a62'),
         shoes=mat('#fbf6e8', '#f2e7c9', '#bfa67c'), socks=None,
         bike=mat('#9bc4d8', '#5f96c8', '#466e8c'),
         pannier=mat('#b47c5f', '#96643c', '#673f31'), pannier_strap=flat('#3b2219'),
         bag=mat('#dccba6', '#bfa67c', '#96643c'), strap=flat('#673f31')),
    dict(id='b', name='Garis Biru', skin='sawo',
         cap=mat('#7480a3', '#5c6a8c', '#404a62'),
         shirt=mat('#ffffff', '#f2e7c9', '#c2af86'),
         shirt_fn=None,
         pants=mat('#d5c4a1', '#bfa67c', '#96643c'),
         shoes=mat('#994532', '#7a4b3a', '#553428'), socks=mat('#ffffff', '#f2e7c9', '#c2af86'),
         bike=mat('#62a046', '#466e50', '#314d38'),
         pannier=mat('#dccba6', '#bfa67c', '#96643c'), pannier_strap=flat('#553428'),
         bag=mat('#b47c5f', '#96643c', '#673f31'), strap=flat('#553428')),
    dict(id='c', name='Jaket Hijau', skin='terang', long_sleeves=True, long_pants=True, lamp=True,
         rear_reflector=True,
         cap=mat('#ffe08a', '#ffc94a', '#e98e3f'),
         shirt=mat('#7dbb5a', '#62a046', '#3f6348'),
         pants=mat('#6c6872', '#4e5a77', '#2e3550'),
         shoes=mat('#994532', '#673f31', '#4a2319'), socks=None,
         bike=mat('#e86a55', '#d94f3d', '#994532'),
         pannier=mat('#7480a3', '#5c6a8c', '#404a62'), pannier_strap=flat('#2a1e17'),
         bag=mat('#f6b26b', '#e98e3f', '#b5523b'), strap=flat('#7e3929')),
    dict(id='d', name='Kaus Bola', skin='sawo', fenders=False,
         cap=mat('#5c6a8c', '#404a62', '#2e3550'),
         shirt=mat('#ffffff', '#f2e7c9', '#c2af86'),
         pants=mat('#e86a55', '#d94f3d', '#a24935'),
         shoes=mat('#5f5b66', '#3d4649', '#221e26'), socks=mat('#ffffff', '#f2e7c9', '#c2af86'),
         bike=mat('#ffe08a', '#ffc94a', '#d9a33a'),
         pannier=mat('#b5523b', '#994532', '#673f31'), pannier_strap=flat('#2a1e17'),
         bag=mat('#7480a3', '#5c6a8c', '#404a62'), strap=flat('#2e3550')),
]
VARIANTS[1]['shirt_fn'] = stripes(mat('#ffffff', '#f2e7c9', '#c2af86'), mat('#7fa9d9', '#5f96c8', '#466e8c'), 2)
VARIANTS[3]['shirt_fn'] = band(mat('#ffffff', '#f2e7c9', '#c2af86'), mat('#e86a55', '#d94f3d', '#a24935'), 23.0, 25.2)
for vv_ in VARIANTS:
    if vv_.get('shirt_fn') is None:
        vv_.pop('shirt_fn', None)


def batik(m1, m2):
    def f(P, N):
        d = N @ LIGHT
        zi = np.floor(P[:, 2]).astype(int)
        di = np.floor(P[:, 0] - P[:, 1]).astype(int)
        sel2 = (zi % 2 == 0) & ((di + zi // 2) % 2 == 0)
        out = np.empty((len(P), 3), np.uint8)
        for m, sel in ((m1, ~sel2), (m2, sel2)):
            o = np.empty((sel.sum(), 3), np.uint8)
            dd = d[sel]
            o[:] = m[1]
            o[dd > 0.78] = m[0]
            o[dd < -0.12] = m[2]
            out[sel] = o
        return out
    return f


VARIANTS_NOBAG = [
    dict(id='e', name='Polo Kuning', skin='sawo', crossbag=False, basket=True,
         cap=mat('#6fae4f', '#466e50', '#314d38'),
         shirt=mat('#ffe08a', '#ffc94a', '#d9a33a'),
         pants=mat('#7480a3', '#5c6a8c', '#404a62'),
         shoes=mat('#5f5b66', '#3d4649', '#221e26'), socks=mat('#ffffff', '#f2e7c9', '#c2af86'),
         bike=mat('#f6b26b', '#e98e3f', '#b5523b'),
         pannier=mat('#b47c5f', '#96643c', '#673f31'), pannier_strap=flat('#3b2219')),
    dict(id='f', name='Batik', skin='terang', crossbag=False,
         cap=mat('#f6b26b', '#e98e3f', '#b5523b'),
         shirt=mat('#b47c5f', '#96643c', '#673f31'),
         pants=mat('#dccba6', '#bfa67c', '#96643c'),
         shoes=mat('#994532', '#673f31', '#4a2319'), socks=None,
         bike=mat('#a24935', '#7e3929', '#4a2319'),
         pannier=mat('#6a8a5a', '#466e50', '#314d38'), pannier_strap=flat('#2a1e17')),
    dict(id='g', name='Hoodie Abu', skin='sawo', crossbag=False, hood=True, long_sleeves=True, long_pants=True,
         cap=mat('#e86a55', '#d94f3d', '#a24935'),
         shirt=mat('#c4c0c8', '#a9a2ae', '#6c6872'),
         pants=mat('#7480a3', '#5c6a8c', '#404a62'),
         shoes=mat('#ffffff', '#f2e7c9', '#bfa67c'), socks=None,
         bike=mat('#5f5b66', '#3d4649', '#221e26'),
         pannier=mat('#f6b26b', '#e98e3f', '#b5523b'), pannier_strap=flat('#2a1e17')),
    dict(id='h', name='Kemeja Agen', skin='terang', crossbag=False, basket=True,
         cap=mat('#ffffff', '#f2e7c9', '#c2af86'), brim=mat('#7480a3', '#5c6a8c', '#404a62'),
         shirt=mat('#9bc4d8', '#5f96c8', '#466e8c'),
         pants=mat('#7480a3', '#5c6a8c', '#404a62'),
         shoes=mat('#5f5b66', '#3d4649', '#221e26'), socks=None,
         bike=mat('#62a046', '#466e50', '#314d38'),
         pannier=mat('#b5523b', '#994532', '#673f31'), pannier_strap=flat('#2a1e17')),
]
VARIANTS_NOBAG[1]['shirt_fn'] = batik(mat('#b47c5f', '#96643c', '#673f31'), mat('#fbf6e8', '#f2e7c9', '#c2af86'))
ALL = VARIANTS + VARIANTS_NOBAG
