"""Tiny isometric (2:1) point-sampled renderer for pixel-art sprites.

World axes: x = rider's right (screen down-right), y = backward (screen down-left), z = up.
Rider travels toward -y  -> screen up-right.  Camera sits at +x +y +z.
Local bike coords (a, b, c): a = forward, b = right, c = up  -> world (b, -a, c).
"""
import math
import numpy as np
from PIL import Image

OUT = (0x0e, 0x0a, 0x1c)
SHADOW = (0, 0, 0, 71)
T_LIGHT, T_DARK = 0.78, -0.12
LIGHT = np.array([-0.6, 0.8, 1.4])
LIGHT = LIGHT / np.linalg.norm(LIGHT)


def hexc(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def mat(light, mid, dark):
    return (hexc(light), hexc(mid), hexc(dark))


def flat(c):
    c = hexc(c)
    return (c, c, c)


def fib_sphere(n):
    i = np.arange(n) + 0.5
    phi = np.arccos(1 - 2 * i / n)
    th = math.pi * (1 + 5 ** 0.5) * i
    return np.stack([np.cos(th) * np.sin(phi), np.sin(th) * np.sin(phi), np.cos(phi)], 1)


_FIB = {}


def dirs_for(r):
    n = int(max(60, 4 * math.pi * r * r / 0.012))
    n = min(n, 4000)
    if n not in _FIB:
        _FIB[n] = fib_sphere(n)
    return _FIB[n]


POSE = {'yaw': 0.0, 'lean': 0.0}


def L2W(p):
    """local (a fwd, b right, c up) -> world, with yaw (+ = turn right) and lean (+ = lean right)."""
    p = np.asarray(p, float)
    a, b, c = p[..., 0], p[..., 1], p[..., 2]
    L, T = math.radians(POSE['lean']), math.radians(POSE['yaw'])
    b2 = b * math.cos(L) + c * math.sin(L)
    c2 = -b * math.sin(L) + c * math.cos(L)
    x = a * math.sin(T) + b2 * math.cos(T)
    y = -a * math.cos(T) + b2 * math.sin(T)
    return np.stack([x, y, c2], -1)


def W2L(p):
    p = np.asarray(p, float)
    x, y, z = p[..., 0], p[..., 1], p[..., 2]
    L, T = math.radians(POSE['lean']), math.radians(POSE['yaw'])
    a = x * math.sin(T) - y * math.cos(T)
    b2 = x * math.cos(T) + y * math.sin(T)
    b = b2 * math.cos(L) - z * math.sin(L)
    c = b2 * math.sin(L) + z * math.cos(L)
    return np.stack([a, b, c], -1)


class Model:
    def __init__(s):
        s.P, s.N, s.mat, s.pid, s.bias = [], [], [], [], []
        s.parts = []
        s.xf = None

    def part(s, name, outline=True):
        s.parts.append(dict(name=name, outline=outline))
        return len(s.parts) - 1

    def add_local(s, P, N, m, pid, bias=0.0):
        """P, N in local (a,b,c). m: material tuple or callable(Pworld, Nworld)->(n,3)."""
        if s.xf is not None:
            P, N = s.xf(np.asarray(P, float), np.asarray(N, float))
        Pw, Nw = L2W(P), L2W(N)
        s.P.append(Pw)
        s.N.append(Nw)
        s.mat.append((m, len(Pw)))
        s.pid.append(np.full(len(Pw), pid))
        s.bias.append(np.full(len(Pw), bias))

    # ---------- primitives (local coords) ----------
    def capsule(s, p0, p1, r, m, pid, bias=0.0, step=0.18):
        p0, p1 = np.asarray(p0, float), np.asarray(p1, float)
        d = p1 - p0
        Ld = np.linalg.norm(d)
        t = np.arange(0, Ld + 1e-6, step) / Ld if Ld > 1e-6 else np.array([0.0])
        axis = p0[None] + t[:, None] * d[None]
        D = dirs_for(r)
        rs = [r] if r < 0.6 else [r, r - 0.2]
        P = np.concatenate([(axis[:, None, :] + rr * D[None]).reshape(-1, 3) for rr in rs])
        N = np.concatenate([np.repeat(D[None], len(axis), 0).reshape(-1, 3) for _ in rs])
        s.add_local(P, N, m, pid, bias)

    def sphere(s, c, r, m, pid, bias=0.0, keep=None):
        D = dirs_for(r)
        P = np.asarray(c, float)[None] + r * D
        N = D.copy()
        if keep is not None:
            k = keep(P, N)
            P, N = P[k], N[k]
        s.add_local(P, N, m, pid, bias)
        return P, N

    def box(s, c, u, v, w, hu, hv, hw, m, pid, bias=0.0, step=0.2, hv_end=None):
        """Oriented box. hv may taper to hv_end along w (from -hw to +hw)."""
        c, u, v, w = (np.asarray(x, float) for x in (c, u, v, w))
        hv_end = hv if hv_end is None else hv_end
        Ps, Ns = [], []
        su = np.arange(-hu, hu + 1e-6, step)
        sv = np.linspace(-1, 1, max(2, int(2 * max(hv, hv_end) / step) + 1))
        sw = np.arange(-hw, hw + 1e-6, step)

        def hvat(t):
            return hv + (hv_end - hv) * (t + hw) / (2 * hw) if hw > 0 else hv
        # faces +-u
        for sg in (1, -1):
            V, Wt = np.meshgrid(sv, sw)
            HV = hvat(Wt)
            P = c + sg * hu * u + (V * HV)[..., None] * v + Wt[..., None] * w
            Ps.append(P.reshape(-1, 3))
            Ns.append(np.repeat((sg * u)[None], P.size // 3, 0))
        # faces +-v
        for sg in (1, -1):
            U, Wt = np.meshgrid(su, sw)
            P = c + U[..., None] * u + (sg * hvat(Wt))[..., None] * v + Wt[..., None] * w
            Ps.append(P.reshape(-1, 3))
            Ns.append(np.repeat((sg * v)[None], P.size // 3, 0))
        # faces +-w
        for sg in (1, -1):
            hvv = hvat(sg * hw)
            U, V = np.meshgrid(su, np.arange(-hvv, hvv + 1e-6, step))
            P = c + U[..., None] * u + V[..., None] * v + sg * hw * w
            Ps.append(P.reshape(-1, 3))
            Ns.append(np.repeat((sg * w)[None], P.size // 3, 0))
        s.add_local(np.concatenate(Ps), np.concatenate(Ns), m, pid, bias)

    def ring(s, c, R0, R1, hw, m, pid, a0=0, a1=360, bias=0.0, lat=0.0):
        """Ring in the bike plane (a,c), lateral half width hw along b, angles in degrees (0=+a, 90=+c)."""
        c = np.asarray(c, float)
        th = np.radians(np.arange(a0, a1 + 1e-6, 0.8))
        rho = np.arange(R0, R1 + 1e-6, 0.18)
        sb = np.arange(-hw, hw + 1e-6, 0.18)
        TH, RH, SB = np.meshgrid(th, rho, sb, indexing='ij')
        P = np.stack([c[0] + RH * np.cos(TH), c[1] + SB + lat, c[2] + RH * np.sin(TH)], -1).reshape(-1, 3)
        N = np.stack([np.cos(TH), np.zeros_like(TH), np.sin(TH)], -1).reshape(-1, 3)
        s.add_local(P, N, m, pid, bias)

    def ground_ellipse(s, c, ra, rb):
        """returns local points on ground for blob shadow."""
        a = np.arange(-ra, ra + 1e-6, 0.2)
        b = np.arange(-rb, rb + 1e-6, 0.2)
        A, B = np.meshgrid(a, b)
        k = (A / ra) ** 2 + (B / rb) ** 2 <= 1
        P = np.stack([A[k] + c[0], B[k] + c[1], np.zeros(k.sum())], -1)
        return L2W(P)


def shade(m, Nw, Pw):
    if callable(m):
        return m(Pw, Nw)
    d = Nw @ LIGHT
    out = np.empty((len(Nw), 3), np.uint8)
    out[:] = m[1]
    out[d > T_LIGHT] = m[0]
    out[d < T_DARK] = m[2]
    return out


def proj(Pw, ox, oy):
    sx = Pw[:, 0] - Pw[:, 1] + ox
    sy = (Pw[:, 0] + Pw[:, 1]) / 2 - Pw[:, 2] + oy
    return np.floor(sx).astype(int), np.floor(sy).astype(int)


def render(model, W, H, ox, oy, shadow_pts=None, depth_T=1.6):
    P = np.concatenate(model.P)
    N = np.concatenate(model.N)
    pid = np.concatenate(model.pid)
    bias = np.concatenate(model.bias)
    cols = np.concatenate([shade(m, N[i0:i0 + n], P[i0:i0 + n]) for (m, n), i0 in
                           zip(model.mat, np.cumsum([0] + [n for _, n in model.mat])[:-1])])
    ix, iy = proj(P, ox, oy)
    d = P.sum(1) + bias
    ok = (ix >= 0) & (ix < W) & (iy >= 0) & (iy < H)
    ix, iy, d, cols, pid = ix[ok], iy[ok], d[ok], cols[ok], pid[ok]
    idx = iy * W + ix
    order = np.lexsort((-d, idx))
    idx_s = idx[order]
    first = np.unique(idx_s, return_index=True)[1]
    sel = order[first]
    img = np.zeros((H, W, 4), np.uint8)
    depth = np.full((H, W), -1e9)
    part = np.full((H, W), -1)
    img[iy[sel], ix[sel], :3] = cols[sel]
    img[iy[sel], ix[sel], 3] = 255
    depth[iy[sel], ix[sel]] = d[sel]
    part[iy[sel], ix[sel]] = pid[sel]

    # cleanup: a lone pixel whose 4 neighbours share one colour and part takes that colour
    for _ in range(2):
        c = img[..., :3].astype(int)
        key = c[..., 0] * 65536 + c[..., 1] * 256 + c[..., 2]
        nk = [np.roll(key, sh, ax) for sh, ax in ((1, 0), (-1, 0), (1, 1), (-1, 1))]
        npt = [np.roll(part, sh, ax) for sh, ax in ((1, 0), (-1, 0), (1, 1), (-1, 1))]
        same = (nk[0] == nk[1]) & (nk[1] == nk[2]) & (nk[2] == nk[3]) & (nk[0] != key)
        samep = (npt[0] == part) & (npt[1] == part) & (npt[2] == part) & (npt[3] == part)
        fix = same & samep & (part >= 0)
        fix[0, :] = fix[-1, :] = fix[:, 0] = fix[:, -1] = False
        if not fix.any():
            break
        src = np.roll(img, 1, 0)
        img[fix, :3] = src[fix, :3]
    outl = np.array([p['outline'] for p in model.parts])
    filled = part >= 0
    has_ol = np.zeros_like(filled)
    has_ol[filled] = outl[part[filled]]
    new = img.copy()
    # internal outlines: farther pixel next to a nearer, different part
    for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
        nb_part = np.full_like(part, -1)
        nb_depth = np.full_like(depth, -1e9)
        ys = slice(max(0, dy), H + min(0, dy))
        yd = slice(max(0, -dy), H + min(0, -dy))
        xs = slice(max(0, dx), W + min(0, dx))
        xd = slice(max(0, -dx), W + min(0, -dx))
        nb_part[yd, xd] = part[ys, xs]
        nb_depth[yd, xd] = depth[ys, xs]
        nb_ol = np.zeros_like(filled)
        nb_ol[yd, xd] = has_ol[ys, xs]
        m_int = filled & has_ol & (nb_part >= 0) & (nb_part != part) & (nb_depth - depth > depth_T) & nb_ol
        new[m_int, :3] = OUT
        # outer outline
        m_out = (~filled) & nb_ol
        new[m_out, :3] = OUT
        new[m_out, 3] = 255
    img = new
    if shadow_pts is not None:
        sx, sy = proj(shadow_pts, ox + 1, oy + 1)
        ok = (sx >= 0) & (sx < W) & (sy >= 0) & (sy < H)
        sh = np.zeros((H, W), bool)
        sh[sy[ok], sx[ok]] = True
        sh &= img[..., 3] == 0
        img[sh] = SHADOW
    return img


def to_image(arr, scale=1):
    im = Image.fromarray(arr, 'RGBA')
    if scale != 1:
        im = im.resize((im.width * scale, im.height * scale), Image.NEAREST)
    return im
