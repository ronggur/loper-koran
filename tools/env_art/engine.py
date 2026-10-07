"""Isometric 2:1 pixel-art scene renderer (ray cast, 1x), consistent with tools/loper_art/iso.py.

World: x = screen down-right (sisi dekat side), y = screen down-left (backward), z = up.
Road runs along y, rider travels toward -y (screen up-right). Camera at +x +y +z.
Screen: sx = x - y + ox, sy = (x + y)/2 - z + oy.
Baked tones (terang/dasar/gelap) use the fixed LIGHT of iso.py. Dynamic layer (per time of day):
cast shadows + tint, point lights in quantised bands, emissive windows with pixel glow rings.
"""
import math
import numpy as np
from PIL import Image

OUT = np.array([14, 10, 28], np.float32)
BAKE = np.array([-0.6, 0.8, 1.4]); BAKE /= np.linalg.norm(BAKE)
T_LIGHT, T_DARK = 0.78, -0.12
VIEW = -np.array([1.0, 1.0, 1.0]) / math.sqrt(3)
FAR = 3000.0


def hexc(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


class Mat:
    def __init__(s, light, mid=None, dark=None, glow=None, name=''):
        mid = mid or light
        dark = dark or mid
        s.c = np.array([hexc(light), hexc(mid), hexc(dark)], np.float32)
        s.glow = None if glow is None else np.array(hexc(glow), np.float32)
        s.name = name


def flat(c, glow=None):
    return Mat(c, c, c, glow)


def nrm(v):
    v = np.asarray(v, float)
    return v / np.linalg.norm(v)


class Prim:
    _next = [0]

    def __init__(s, planes=(), quad=None, mats=None, tex=None, part=None, outline=True,
                 cast=True, aabb=None, tag=''):
        s.planes = [(nrm(n), float(d) / np.linalg.norm(n)) for n, d in planes]
        s.quad = quad
        s.mats = mats if isinstance(mats, (list, tuple)) else [mats]
        s.tex = tex
        s.outline = outline
        s.cast = cast
        s.tag = tag
        if part is None:
            Prim._next[0] += 1
            part = Prim._next[0]
        s.part = part
        s.lo, s.hi = np.array(aabb[0], float), np.array(aabb[1], float)

    # ---------- intersection: O (n,3), D (3,) ----------
    def hit(s, O, D):
        n = len(O)
        te = np.full(n, -np.inf)
        tx = np.full(n, np.inf)
        nidx = np.full(n, -1)          # -1 = quadric normal, else plane index
        ok = np.ones(n, bool)
        for j, (pn, pd) in enumerate(s.planes):
            no = O @ pn
            nd = float(pn @ D)
            if nd > 1e-9:
                tx = np.minimum(tx, (pd - no) / nd)
            elif nd < -1e-9:
                tb = (pd - no) / nd
                upd = tb > te
                te = np.where(upd, tb, te)
                nidx = np.where(upd, j, nidx)
            else:
                ok &= no <= pd
        qn = None
        if s.quad is not None:
            kind = s.quad[0]
            if kind == 'ellip':
                _, c, R, r = s.quad  # R: 3x3 rows = local axes
                Ol = ((O - c) @ R.T) / r
                Dl = (R @ D) / r
                a = Dl @ Dl
                b = 2 * Ol @ Dl
                cc = (Ol * Ol).sum(1) - 1
            else:  # cyl: axis index, centre (2,), radius
                _, ax, c2, r = s.quad
                o = [i for i in range(3) if i != ax]
                Ol = (O[:, o] - c2) / r
                Dl = D[o] / r
                a = Dl @ Dl
                b = 2 * Ol @ Dl
                cc = (Ol * Ol).sum(1) - 1
            if a < 1e-12:
                ok &= cc <= 0
            else:
                disc = b * b - 4 * a * cc
                ok &= disc >= 0
                sq = np.sqrt(np.maximum(disc, 0))
                t1 = (-b - sq) / (2 * a)
                t2 = (-b + sq) / (2 * a)
                upd = t1 > te
                te = np.where(upd, t1, te)
                nidx = np.where(upd, -1, nidx)
                tx = np.minimum(tx, t2)
        ok &= te <= tx
        return ok, te, tx, nidx

    def normal(s, P, nidx):
        N = np.zeros((len(P), 3))
        for j, (pn, pd) in enumerate(s.planes):
            m = nidx == j
            N[m] = pn
        m = nidx == -1
        if m.any() and s.quad is not None:
            if s.quad[0] == 'ellip':
                _, c, R, r = s.quad
                Pl = ((P[m] - c) @ R.T) / r
                Nl = Pl / r
                Nw = Nl @ R
            else:
                _, ax, c2, r = s.quad
                o = [i for i in range(3) if i != ax]
                Nw = np.zeros((m.sum(), 3))
                Nw[:, o] = P[m][:, o] - c2
            N[m] = Nw / np.maximum(np.linalg.norm(Nw, axis=1, keepdims=True), 1e-9)
        return N


# ---------------- primitive builders ----------------

def box(x0, x1, y0, y1, z0, z1, mats, tex=None, **kw):
    pl = [((1, 0, 0), x1), ((-1, 0, 0), -x0), ((0, 1, 0), y1), ((0, -1, 0), -y0),
          ((0, 0, 1), z1), ((0, 0, -1), -z0)]
    return Prim(pl, None, mats, tex, aabb=((x0, y0, z0), (x1, y1, z1)), **kw)


def obox(c, u, v, w, hu, hv, hw, mats, tex=None, **kw):
    c = np.asarray(c, float)
    u, v, w = nrm(u), nrm(v), nrm(w)
    pl = []
    for ax, h in ((u, hu), (v, hv), (w, hw)):
        pl.append((ax, ax @ c + h))
        pl.append((-ax, -(ax @ c) + h))
    ext = np.abs(u) * hu + np.abs(v) * hv + np.abs(w) * hw
    return Prim(pl, None, mats, tex, aabb=(c - ext, c + ext), **kw)


def gable(x0, x1, y0, y1, zb, zt, ridge='y', mats=None, tex=None, **kw):
    """Gable roof prism. ridge along y: slopes face +-x."""
    if ridge == 'y':
        xc, hw = (x0 + x1) / 2, (x1 - x0) / 2
        k = (zt - zb) / hw
        pl = [((k, 0, 1), zt + k * xc), ((-k, 0, 1), zt - k * xc)]
    else:
        yc, hw = (y0 + y1) / 2, (y1 - y0) / 2
        k = (zt - zb) / hw
        pl = [((0, k, 1), zt + k * yc), ((0, -k, 1), zt - k * yc)]
    pl += [((1, 0, 0), x1), ((-1, 0, 0), -x0), ((0, 1, 0), y1), ((0, -1, 0), -y0), ((0, 0, -1), -zb)]
    return Prim(pl, None, mats, tex, aabb=((x0, y0, zb), (x1, y1, zt)), **kw)


def hip(x0, x1, y0, y1, zb, zt, inset=None, mats=None, tex=None, **kw):
    """Hip (limasan) roof: four slopes, ridge length set by inset (same slope on all sides)."""
    hx, hy = (x1 - x0) / 2, (y1 - y0) / 2
    xc, yc = (x0 + x1) / 2, (y0 + y1) / 2
    run = min(hx, hy) if inset is None else inset
    k = (zt - zb) / run
    # plane: z + k*(x - (x1 - run)) <= zt  ->  k x + z <= zt + k (x1 - run)
    pl = [((k, 0, 1), zt + k * (x1 - run)), ((-k, 0, 1), zt - k * (x0 + run)),
          ((0, k, 1), zt + k * (y1 - run)), ((0, -k, 1), zt - k * (y0 + run)),
          ((0, 0, -1), -zb), ((0, 0, 1), zt),
          ((1, 0, 0), x1), ((-1, 0, 0), -x0), ((0, 1, 0), y1), ((0, -1, 0), -y0)]
    return Prim(pl, None, mats, tex, aabb=((x0, y0, zb), (x1, y1, zt)), **kw)


def shed(x0, x1, y0, y1, z_hi, z_lo, down='+x', thick=1.5, mats=None, tex=None, **kw):
    """Single-slope roof slab, high edge opposite to `down`."""
    if down in ('+x', '-x'):
        a, b = (x0, x1) if down == '+x' else (x1, x0)
        k = (z_lo - z_hi) / (b - a)          # dz/dx
        n = np.array([-k, 0, 1.0])
        d_top = z_hi - k * a
    else:
        a, b = (y0, y1) if down == '+y' else (y1, y0)
        k = (z_lo - z_hi) / (b - a)
        n = np.array([0, -k, 1.0])
        d_top = z_hi - k * a
    pl = [(n, d_top), (-n, -(d_top - thick)),
          ((1, 0, 0), x1), ((-1, 0, 0), -x0), ((0, 1, 0), y1), ((0, -1, 0), -y0)]
    zmin, zmax = min(z_hi, z_lo) - thick, max(z_hi, z_lo)
    return Prim(pl, None, mats, tex, aabb=((x0, y0, zmin), (x1, y1, zmax)), **kw)


def ellip(c, r, mats, tex=None, R=None, zmin=None, **kw):
    c = np.asarray(c, float)
    r = np.asarray(r if np.ndim(r) else (r, r, r), float)
    R = np.eye(3) if R is None else np.asarray(R, float)
    pl = [] if zmin is None else [((0, 0, -1), -zmin)]
    ext = np.abs(R.T) @ r
    lo = c - ext
    if zmin is not None:
        lo[2] = max(lo[2], zmin)
    return Prim(pl, ('ellip', c, R, r), mats, tex, aabb=(lo, c + ext), **kw)


def cyl(c, r, a0, a1, axis=2, mats=None, tex=None, **kw):
    """Axis-aligned cylinder; c = centre in the two other axes (ordered), a0..a1 along axis."""
    c2 = np.asarray(c, float)
    e = np.zeros(3); e[axis] = 1
    pl = [(e, a1), (-e, -a0)]
    o = [i for i in range(3) if i != axis]
    lo, hi = np.zeros(3), np.zeros(3)
    lo[axis], hi[axis] = a0, a1
    lo[o], hi[o] = c2 - r, c2 + r
    return Prim(pl, ('cyl', axis, c2, r), mats, tex, aabb=(lo, hi), **kw)


def rot_z(a):
    c, s = math.cos(a), math.sin(a)
    return np.array([[c, s, 0], [-s, c, 0], [0, 0, 1.0]])  # rows = local axes in world


# ---------------- helpers for textures ----------------

def hash2(a, b, seed=0):
    a = np.asarray(a, np.int64); b = np.asarray(b, np.int64)
    h = (a * 374761393 + b * 668265263 + seed * 1442695041) & 0xffffffff
    h = ((h ^ (h >> 13)) * 1274126177) & 0xffffffff
    return (h ^ (h >> 16)) / 4294967295.0


def face_uv(P, N):
    """For vertical faces: u along the face (world), v = z. Returns u, v, face code."""
    ax = np.abs(N)
    fx = (ax[:, 0] > 0.7)
    u = np.where(fx, P[:, 1], P[:, 0])
    return u, P[:, 2], np.where(fx, np.sign(N[:, 0]), 2 * np.sign(N[:, 1]))


# ---------------- scene + render ----------------

class Light:
    def __init__(s, pos, radius, color, strength=1.0, flat=0.6, zmax=None):
        s.zmax = zmax
        s.pos = np.asarray(pos, float)
        s.radius = radius
        s.color = np.array(hexc(color), np.float32) / 255
        s.strength = strength
        s.flat = flat  # z squashing for distance


class TimeCfg:
    def __init__(s, name, elev, sun, shade, glow=False, lights_on=False, amb_add=(0, 0, 0),
                 grade=None, shadow_black=False):
        s.name = name
        s.elev = elev
        s.sun = np.array(sun, np.float32)
        s.shade = np.array(shade, np.float32)
        s.glow = glow
        s.lights_on = lights_on
        s.amb_add = np.array(amb_add, np.float32)
        s.grade = grade
        s.shadow_black = shadow_black

    def sun_dir(s):
        # azimuth of the baked light (from screen left), elevation varies with time
        az = np.array([-0.6, 0.8, 0.0]); az /= np.linalg.norm(az)
        e = math.radians(s.elev)
        return np.array([az[0] * math.cos(e), az[1] * math.cos(e), math.sin(e)])


TIMES = {
    'pagi': TimeCfg('pagi', 24, (1.04, 1.0, 0.90), (0.66, 0.70, 0.92)),
    'siang': TimeCfg('siang', 52, (1.0, 1.0, 1.0), (0.60, 0.62, 0.82)),
    'sore': TimeCfg('sore', 20, (1.08, 0.90, 0.72), (0.60, 0.53, 0.76)),
    'malam': TimeCfg('malam', 40, (0.40, 0.46, 0.70), (0.24, 0.26, 0.46), glow=True, lights_on=True),
    'hitam': TimeCfg('hitam', 52, (1.0, 1.0, 1.0), (0.72, 0.72, 0.72), shadow_black=True),
}


class Scene:
    def __init__(s, W, H, ox, oy):
        s.W, s.H, s.ox, s.oy = W, H, ox, oy
        s.prims = []
        s.lights = []          # point lights, active at night (or if always=True)
        s.overlays = []        # callables(img, ctx) drawn after lighting
        s.sprites = []         # (sprite RGBA array, anchor (ax, ay), world pos)
        s.glow_big = []        # world points of lamp bulbs (big halos)

    def add(s, *ps):
        for p in ps:
            if isinstance(p, (list, tuple)):
                s.add(*p)
            else:
                s.prims.append(p)
        return ps

    def proj(s, P):
        P = np.atleast_2d(np.asarray(P, float))
        return P[:, 0] - P[:, 1] + s.ox, (P[:, 0] + P[:, 1]) / 2 - P[:, 2] + s.oy

    def render(s, tcfg, outline=True):
        W, H = s.W, s.H
        py, px = np.mgrid[0:H, 0:W]
        px = px.ravel().astype(float) + 0.5
        py = py.ravel().astype(float) + 0.5
        sx, sy = px - s.ox, py - s.oy
        P0 = np.stack([sy + sx / 2, sy - sx / 2, np.zeros_like(sx)], 1)
        O = P0 - VIEW * FAR
        n = W * H
        tbest = np.full(n, np.inf)
        pbest = np.full(n, -1)
        nbest = np.full(n, -1)
        for i, p in enumerate(s.prims):
            # screen bbox from aabb corners
            cs = np.array([[x, y, z] for x in (p.lo[0], p.hi[0]) for y in (p.lo[1], p.hi[1])
                           for z in (p.lo[2], p.hi[2])])
            csx, csy = s.proj(cs)
            x0, x1 = int(max(0, math.floor(csx.min()) - 1)), int(min(W, math.ceil(csx.max()) + 1))
            y0, y1 = int(max(0, math.floor(csy.min()) - 1)), int(min(H, math.ceil(csy.max()) + 1))
            if x0 >= x1 or y0 >= y1:
                continue
            yy, xx = np.mgrid[y0:y1, x0:x1]
            idx = (yy * W + xx).ravel()
            ok, te, tx, ni = p.hit(O[idx], VIEW)
            better = ok & (te < tbest[idx]) & (te > 0)
            j = idx[better]
            tbest[j] = te[better]
            pbest[j] = i
            nbest[j] = ni[better]
        hitm = pbest >= 0
        P = O + VIEW * np.where(hitm, tbest, 0)[:, None]
        N = np.zeros((n, 3))
        base = np.zeros((n, 3), np.float32)
        glow = np.zeros((n, 3), np.float32)
        isglow = np.zeros(n, bool)
        partb = np.full(n, -1)
        olb = np.zeros(n, bool)
        for i in np.unique(pbest[hitm]):
            p = s.prims[i]
            m = np.where(pbest == i)[0]
            Ni = p.normal(P[m], nbest[m])
            N[m] = Ni
            dd = Ni @ BAKE
            tone = np.where(dd > T_LIGHT, 0, np.where(dd < T_DARK, 2, 1))
            if p.tex is not None:
                mi, sh = p.tex(P[m], Ni)
                mi = np.broadcast_to(np.asarray(mi), (len(m),))
                sh = np.broadcast_to(np.asarray(sh), (len(m),))
            else:
                mi, sh = np.zeros(len(m), int), np.zeros(len(m), int)
            tone = np.clip(tone + sh, 0, 2)
            cols = np.zeros((len(m), 3), np.float32)
            for k in np.unique(mi):
                mk = mi == k
                mat = p.mats[k]
                cols[mk] = mat.c[tone[mk]]
                if mat.glow is not None and tcfg.glow:
                    isglow[m[mk]] = True
                    glow[m[mk]] = mat.glow
            base[m] = cols
            partb[m] = p.part
            olb[m] = p.outline
        s._buf = dict(P=P, N=N, base=base, part=partb, ol=olb, hit=hitm, t=tbest, prim=pbest)

        # ---- dynamic light ----
        Ls = tcfg.sun_dir()
        lit = (N @ Ls) > 0.04
        shadow = np.zeros(n, bool)
        cand = np.where(hitm & lit)[0]
        Os = P[cand] + N[cand] * 0.6 + Ls * 0.4
        occl = np.zeros(len(cand), bool)
        for p in s.prims:
            if not p.cast:
                continue
            below = Os[:, 2] < p.hi[2]
            if not below.any():
                continue
            # sweep in xy between z=max(lo,P.z) and z=hi
            zl = np.maximum(p.lo[2], Os[:, 2])
            s_lo = (zl - Os[:, 2]) / Ls[2]
            s_hi = (p.hi[2] - Os[:, 2]) / Ls[2]
            xa, xb = Os[:, 0] + s_lo * Ls[0], Os[:, 0] + s_hi * Ls[0]
            ya, yb = Os[:, 1] + s_lo * Ls[1], Os[:, 1] + s_hi * Ls[1]
            cnd = below & ~occl & (np.maximum(xa, xb) >= p.lo[0]) & (np.minimum(xa, xb) <= p.hi[0]) & \
                (np.maximum(ya, yb) >= p.lo[1]) & (np.minimum(ya, yb) <= p.hi[1])
            k = np.where(cnd)[0]
            if not len(k):
                continue
            ok, te, tx, _ = p.hit(Os[k], Ls)
            occl[k[ok & (tx > 0.05)]] = True
        shadow[cand[occl]] = True
        shade = hitm & (~lit | shadow)
        s._buf['shade'] = shade
        mult = np.where(shade[:, None], tcfg.shade[None], tcfg.sun[None]).astype(np.float32)
        mult = mult + tcfg.amb_add
        if tcfg.lights_on:
            for L in s.lights:
                d = P - L.pos
                d[:, 2] *= L.flat
                dist = np.sqrt((d * d).sum(1))
                f = 1 - dist / L.radius
                band = np.where(f > 0.66, 1.0, np.where(f > 0.33, 0.62, np.where(f > 0, 0.3, 0)))
                facing = ((L.pos - P) * N).sum(1) > 0
                band = band * facing
                if L.zmax is not None:
                    band = band * (P[:, 2] < L.zmax)
                mult += band[:, None] * L.color[None] * L.strength
        s._mult = mult
        s._tcfg = tcfg
        return s

    def compose(s, extra_shadow=None):
        """Finish image. extra_shadow: bool mask (H*W) of sprite shadows to darken with shade tint."""
        b = s._buf
        tc = s._tcfg
        W, H = s.W, s.H
        mult = s._mult.copy()
        if extra_shadow is not None:
            m = extra_shadow & ~b['shade']
            mult[m] = mult[m] * (tc.shade / tc.sun)
        col = b['base'] * mult
        if tc.shadow_black:
            col = np.where(b['shade'][:, None], b['base'] * 0.72, b['base'])
        img = col.reshape(H, W, 3)
        # emissive + glow rings
        if tc.glow:
            g = s._glowmask()
            if g is not None:
                gm, gc = g
                img = np.where(gm[..., None], gc, img)
                img = s._halo(img, gm, gc, (0.32, 0.18, 0.08))
        # outlines
        img = s._outline(img)
        s.img = np.clip(img, 0, 255)
        return s

    def _glowmask(s):
        # recompute glow colour per pixel
        b = s._buf
        W, H = s.W, s.H
        gm = np.zeros(W * H, bool)
        gc = np.zeros((W * H, 3), np.float32)
        P, N = b['P'], b['N']
        for i, p in enumerate(s.prims):
            if not any(mt.glow is not None for mt in p.mats):
                continue
            m = np.where(b['prim'] == i)[0]
            if not len(m):
                continue
            if p.tex is not None:
                mi, _ = p.tex(P[m], N[m])
                mi = np.broadcast_to(np.asarray(mi), (len(m),))
            else:
                mi = np.zeros(len(m), int)
            for k, mt in enumerate(p.mats):
                if mt.glow is None:
                    continue
                mk = m[mi == k]
                gm[mk] = True
                gc[mk] = mt.glow
        if not gm.any():
            return None
        return gm.reshape(H, W), gc.reshape(H, W, 3)

    def _halo(s, img, gm, gc, alphas):
        H, W = gm.shape
        prev = gm.copy()
        col = gc.copy()
        for a in alphas:
            dil = prev.copy()
            dil[1:] |= prev[:-1]; dil[:-1] |= prev[1:]
            dil[:, 1:] |= prev[:, :-1]; dil[:, :-1] |= prev[:, 1:]
            # propagate colour
            c2 = col.copy()
            for sl_from, sl_to in (((slice(None, -1), slice(None)), (slice(1, None), slice(None))),
                                   ((slice(1, None), slice(None)), (slice(None, -1), slice(None))),
                                   ((slice(None), slice(None, -1)), (slice(None), slice(1, None))),
                                   ((slice(None), slice(1, None)), (slice(None), slice(None, -1)))):
                src = prev[sl_from]
                tgt = c2[sl_to]
                upd = src & ~prev[sl_to]
                tgt[upd] = col[sl_from][upd]
            ring = dil & ~prev
            img = np.where(ring[..., None], img + c2 * a, img)
            prev, col = dil, c2
        return img

    def _outline(s, img):
        b = s._buf
        W, H = s.W, s.H
        part = b['part'].reshape(H, W)
        ol = b['ol'].reshape(H, W)
        dep = (-b['t']).reshape(H, W)
        out = np.zeros((H, W), bool)
        for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
            npart = np.full_like(part, -1)
            nol = np.zeros_like(ol)
            ndep = np.full_like(dep, -1e9)
            ys = slice(max(0, dy), H + min(0, dy)); yd = slice(max(0, -dy), H + min(0, -dy))
            xs = slice(max(0, dx), W + min(0, dx)); xd = slice(max(0, -dx), W + min(0, -dx))
            npart[yd, xd] = part[ys, xs]
            nol[yd, xd] = ol[ys, xs]
            ndep[yd, xd] = dep[ys, xs]
            # background (non-outlined) pixel touching an outlined object
            out |= (~ol) & nol & (npart != part)
            # farther object pixel next to nearer outlined object of another part
            out |= ol & nol & (npart != part) & (ndep - dep > 2.5)
        return np.where(out[..., None], OUT, img)

    # ------------- sprites (pre-rendered, e.g. the player) -------------
    def draw_sprite(s, spr, anchor, world, tint=True):
        """spr: HxWx4 uint8 RGBA; black alpha~71 pixels are the baked ground shadow."""
        sx, sy = s.proj(world)
        x0 = int(round(sx[0])) - anchor[0]
        y0 = int(round(sy[0])) - anchor[1]
        return x0, y0

    def save(s, path, scale=1):
        im = Image.fromarray(s.img.astype(np.uint8), 'RGB')
        if scale != 1:
            im = im.resize((s.W * scale, s.H * scale), Image.NEAREST)
        im.save(path)
        return im


def composite_sprite(scene, spr, anchor, world, shade_tint=True):
    """Render-time compositing of a pre-rendered RGBA sprite: shadow pixels -> shade tint, body -> lit tint."""
    tc = scene._tcfg
    b = scene._buf
    W, H = scene.W, scene.H
    sx, sy = scene.proj(world)
    x0 = int(math.floor(sx[0])) - anchor[0]
    y0 = int(math.floor(sy[0])) - anchor[1]
    h, w = spr.shape[:2]
    shadowmask = np.zeros((H, W), bool)
    body = []
    for yy in range(h):
        for xx in range(w):
            r, g, bb, a = spr[yy, xx]
            X, Y = x0 + xx, y0 + yy
            if a == 0 or not (0 <= X < W and 0 <= Y < H):
                continue
            if a < 200 and r < 10 and g < 10 and bb < 10:
                shadowmask[Y, X] = True
            else:
                body.append((X, Y, np.array([r, g, bb], np.float32)))
    return shadowmask, body, (x0, y0)


def finish_with_sprites(scene, sprites):
    """sprites: list of (spr, anchor, world, depth_key). Returns final image array."""
    W, H = scene.W, scene.H
    tc = scene._tcfg
    smask = np.zeros((H, W), bool)
    bodies = []
    Psum = scene._buf['P'].sum(1).reshape(H, W)
    OLm = scene._buf['ol'].reshape(H, W)
    for spr, anchor, world in sprites:
        m, body, (x0, y0) = composite_sprite(scene, spr, anchor, world)
        gdep = world[0] + world[1]
        ay = y0 + anchor[1]
        # occlusion: drop sprite pixels hidden behind nearer scene geometry
        # only real objects (outlined: walls, poles, roofs) can hide the player; ground never does
        body = [(X, Y, c, bool(OLm[Y, X]) and Psum[Y, X] > gdep + max(0, ay - Y) + 3) for X, Y, c in body]
        ys, xs = np.where(m)
        keep = ~OLm[ys, xs] | (Psum[ys, xs] <= gdep + 3)
        m[:] = False
        m[ys[keep], xs[keep]] = True
        smask |= m
        # light on body: sample lit/shade at the anchor ground pixel
        sx, sy = scene.proj(world)
        X, Y = int(sx[0]), int(sy[0])
        k = Y * W + X
        mult = scene._mult[k] if 0 <= k < W * H else tc.sun
        mult = 0.5 * mult + 0.5 * np.maximum(mult, 1.0) if tc.name != 'malam' else 0.6 * mult + 0.4 * np.float32(0.9)
        bodies.append((body, mult))
    scene.compose(extra_shadow=smask.ravel())
    img = scene.img.copy()
    for body, mult in bodies:
        for X, Y, c, hidden in body:
            v = np.clip(c * mult if not np.allclose(c, OUT) else c, 0, 255)
            # objects in front of the player are drawn semi-transparent (ART_DIRECTION 2.2)
            img[Y, X] = 0.55 * img[Y, X] + 0.45 * v if hidden else v
    scene.img = img
    return img


def shift_prims(prims, dx, dy=0.0):
    """Move primitives by (dx, dy, 0) in world space; textures keep their local look."""
    d = np.array([dx, dy, 0.0])
    for p in prims:
        p.planes = [(n, dd + float(n @ d)) for n, dd in p.planes]
        if p.quad is not None:
            if p.quad[0] == 'ellip':
                _, c, R, r = p.quad
                p.quad = ('ellip', c + d, R, r)
            else:
                _, ax, c2, r = p.quad
                o = [i for i in range(3) if i != ax]
                p.quad = ('cyl', ax, c2 + d[o], r)
        p.lo = p.lo + d
        p.hi = p.hi + d
        if p.tex is not None:
            f = p.tex
            p.tex = (lambda Pw, Nw, f=f: f(Pw - d, Nw))
