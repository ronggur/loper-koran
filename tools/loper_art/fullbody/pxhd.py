"""HD pixel-art painter: 5-tone hue-shifted ramps, volumetric (inflated) shading, coloured inner lines,
selective outlines and coloured cast/ground shadows. Light from the upper-left."""
import math
import numpy as np
from PIL import Image, ImageDraw
from scipy.ndimage import distance_transform_edt

OUT = (0x1B, 0x12, 0x26)
L = np.array([-0.50, -0.64, 0.59])
L = L / np.linalg.norm(L)


def hexc(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def ramp(*cols):
    assert len(cols) == 5
    return tuple(hexc(c) for c in cols)


def mix(a, b, t):
    return tuple(int(round(a[i] * (1 - t) + b[i] * t)) for i in range(3))


def shifted(m, dx, dy):
    """out[y, x] = m[y + dy, x + dx] (False outside)."""
    H, W = m.shape
    o = np.zeros_like(m)
    ys0, ys1 = max(0, -dy), min(H, H - dy)
    xs0, xs1 = max(0, -dx), min(W, W - dx)
    if ys1 > ys0 and xs1 > xs0:
        o[ys0:ys1, xs0:xs1] = m[ys0 + dy:ys1 + dy, xs0 + dx:xs1 + dx]
    return o


N4 = ((1, 0), (-1, 0), (0, 1), (0, -1))


class Canvas:
    def __init__(self, W, H):
        self.W, self.H = W, H
        self.yy, self.xx = np.mgrid[0:H, 0:W].astype(float)
        self.filled = np.zeros((H, W), bool)
        self.col = np.zeros((H, W, 3), np.uint8)
        self.is_out = np.zeros((H, W), bool)
        self.group = np.full((H, W), '', object)
        self.rid = np.full((H, W), -1, int)
        self.tone = np.zeros((H, W), int)
        self.ramps = []
        self.shadow = np.zeros((H, W), bool)
        self.parts = {}

    # ---------------- shapes ----------------
    def ellipse(self, cx, cy, rx, ry, rot=0.0):
        x, y = self.xx - cx, self.yy - cy
        if rot:
            c, s = math.cos(math.radians(rot)), math.sin(math.radians(rot))
            x, y = x * c + y * s, -x * s + y * c
        return (x / rx) ** 2 + (y / ry) ** 2 <= 1.0

    def capsule(self, p0, p1, r0, r1=None):
        r1 = r0 if r1 is None else r1
        (x0, y0), (x1, y1) = p0, p1
        dx, dy = x1 - x0, y1 - y0
        L2 = dx * dx + dy * dy or 1e-9
        t = np.clip(((self.xx - x0) * dx + (self.yy - y0) * dy) / L2, 0, 1)
        d = np.hypot(self.xx - (x0 + t * dx), self.yy - (y0 + t * dy))
        return d <= r0 + (r1 - r0) * t

    def chain(self, pts, radii):
        if not isinstance(radii, (list, tuple)):
            radii = [radii] * len(pts)
        m = np.zeros((self.H, self.W), bool)
        for i in range(len(pts) - 1):
            m |= self.capsule(pts[i], pts[i + 1], radii[i], radii[i + 1])
        return m

    def poly(self, pts):
        im = Image.new('L', (self.W, self.H), 0)
        ImageDraw.Draw(im).polygon([tuple(map(float, p)) for p in pts], fill=1, outline=1)
        return np.array(im, bool)

    def ring(self, cx, cy, ro, ri):
        d = np.hypot(self.xx - cx, self.yy - cy)
        return (d <= ro) & (d > ri)

    def disc(self, cx, cy, r):
        return np.hypot(self.xx - cx, self.yy - cy) <= r

    def line(self, pts, w=1):
        im = Image.new('L', (self.W, self.H), 0)
        ImageDraw.Draw(im).line([tuple(map(float, p)) for p in pts], fill=1, width=w)
        return np.array(im, bool)

    def rect(self, x0, y0, x1, y1):
        return (self.xx >= x0) & (self.xx <= x1) & (self.yy >= y0) & (self.yy <= y1)

    # ---------------- painting ----------------
    def add_shadow(self, m):
        self.shadow |= m

    def _I_tube(self, pts, radii):
        if not isinstance(radii, (list, tuple)):
            radii = [radii] * len(pts)
        best = np.full((self.H, self.W), np.inf)
        S = np.zeros((self.H, self.W))
        PX = np.zeros((self.H, self.W))
        PY = np.zeros((self.H, self.W))
        for i in range(len(pts) - 1):
            (x0, y0), (x1, y1) = pts[i], pts[i + 1]
            dx, dy = x1 - x0, y1 - y0
            ln = math.hypot(dx, dy) or 1e-9
            t = np.clip(((self.xx - x0) * dx + (self.yy - y0) * dy) / (ln * ln), 0, 1)
            r = radii[i] + (radii[i + 1] - radii[i]) * t
            ex, ey = self.xx - (x0 + t * dx), self.yy - (y0 + t * dy)
            px, py = -dy / ln, dx / ln
            sd = ex * px + ey * py
            score = np.hypot(ex, ey) / r
            m = score < best
            best[m] = score[m]
            S[m] = np.clip(sd / r, -1, 1)[m]
            PX[m], PY[m] = px, py
        nz = np.sqrt(np.maximum(0, 1 - S * S))
        return S * PX * L[0] + S * PY * L[1] + nz * L[2]

    def _I_ellip(self, cx, cy, rx, ry):
        nx = (self.xx - cx) / rx
        ny = (self.yy - cy) / ry
        rr = np.sqrt(nx * nx + ny * ny)
        f = np.where(rr > 1, 1 / np.maximum(rr, 1e-9), 1.0)
        nx, ny = nx * f, ny * f
        nz = np.sqrt(np.maximum(0, 1 - nx * nx - ny * ny))
        return nx * L[0] + ny * L[1] + nz * L[2]

    def _shade(self, mask, round_r, amb, th):
        if isinstance(round_r, tuple) and round_r[0] == 'tube':
            I = self._I_tube(round_r[1], round_r[2]) + amb
        elif isinstance(round_r, tuple) and round_r[0] == 'ellip':
            I = self._I_ellip(*round_r[1:]) + amb
        else:
            d = distance_transform_edt(mask)
            r = float(round_r if round_r else max(d.max(), 1.0))
            dd = np.minimum(d, r)
            h = np.sqrt(np.maximum(0.0, 2 * r * dd - dd * dd))
            gy, gx = np.gradient(h)
            nz = np.ones_like(h)
            nrm = np.sqrt(gx * gx + gy * gy + nz)
            I = (-gx * L[0] - gy * L[1] + L[2]) / nrm + amb
        tone = np.full(mask.shape, 4, int)
        tone[I > th[3]] = 3
        tone[I > th[2]] = 2
        tone[I > th[1]] = 1
        tone[I > th[0]] = 0
        return tone, I

    def part(self, name, mask, rp, group='', round_r=None, amb=0.0, th=(0.93, 0.74, 0.40, 0.08),
             outline=True, cast=0, cast_tones=1, sel_out=True, flat=None, no_hi=False, inner=None, min_tone=0,
             sub=None, max_tone=4, no_line_against=None):
        mask = mask.copy()
        if not mask.any():
            self.parts[name] = mask
            return mask
        rid = len(self.ramps)
        self.ramps.append(rp)
        if flat is not None:
            tone = np.full(mask.shape, flat, int)
            I = np.zeros(mask.shape)
        elif sub is not None:
            # shade each sub-volume on its own, later ones win where they overlap
            tone = np.full(mask.shape, 2, int)
            I = np.zeros(mask.shape)
            for sm, rr in sub:
                sm = sm & mask
                t2, i2 = self._shade(sm, rr, amb, th)
                tone[sm] = t2[sm]
                I[sm] = i2[sm]
        else:
            tone, I = self._shade(mask, round_r, amb, th)
        if no_hi:
            tone[tone == 0] = 1
        tone = np.clip(tone, min_tone, max_tone)

        # cast shadow (ambient occlusion) onto earlier pixels of the same group
        if cast:
            cs = np.zeros_like(mask)
            for dx, dy in ((1, 1), (1, 0), (0, 1)):
                for k in range(1, cast + 1):
                    cs |= shifted(mask, -dx * k, -dy * k)
            cs &= self.filled & ~mask & ~self.is_out & (self.group == group) & (self.rid >= 0)
            ys, xs = np.where(cs)
            for y, x in zip(ys, xs):
                t = min(4, self.tone[y, x] + cast_tones)
                self.tone[y, x] = t
                self.col[y, x] = self.ramps[self.rid[y, x]][t]

        # outline pixels
        boundary = np.zeros_like(mask)
        touch_empty = np.zeros_like(mask)
        for dx, dy in N4:
            outside = mask & ~shifted(mask, dx, dy)
            boundary |= outside & ~shifted(self.is_out, dx, dy)
            touch_empty |= outside & ~shifted(self.filled, dx, dy)
        edge = np.zeros_like(mask)
        edge[0, :] = edge[-1, :] = edge[:, 0] = edge[:, -1] = True
        touch_empty |= mask & edge
        if no_line_against is not None:
            ag = np.zeros_like(mask)
            for m_ in no_line_against:
                ag |= m_
            ag &= ~mask
            skip = np.zeros_like(mask)
            for dx, dy in N4:
                skip |= mask & ~shifted(mask, dx, dy) & shifted(ag, dx, dy)
            boundary &= ~skip
        if outline is False:
            boundary[:] = False
        elif outline == 'outer':
            boundary &= touch_empty

        cols = np.array(rp, np.uint8)[tone]
        self.col[mask] = cols[mask]
        self.rid[mask] = rid
        self.tone[mask] = tone[mask]
        self.is_out[mask] = False
        self.group[mask] = group
        self.filled |= mask

        inner_c = inner if inner is not None else mix(rp[4], OUT, 0.35)
        lit_c = mix(rp[4], OUT, 0.15)
        b_in = boundary & ~touch_empty
        b_sil = boundary & touch_empty
        self.col[b_in] = inner_c
        if sel_out and flat is None:
            lit = b_sil & (I > 0.55)
            self.col[b_sil & ~lit] = OUT
            self.col[lit] = lit_c
        else:
            self.col[b_sil] = OUT
        self.is_out[boundary] = True
        self.parts[name] = mask
        return mask

    def retone(self, mask, tone=None, delta=None, restrict=None):
        sel = mask & self.filled & ~self.is_out & (self.rid >= 0)
        if restrict is not None:
            sel &= restrict
        ys, xs = np.where(sel)
        for y, x in zip(ys, xs):
            t = tone if tone is not None else int(np.clip(self.tone[y, x] + delta, 0, 4))
            self.tone[y, x] = t
            self.col[y, x] = self.ramps[self.rid[y, x]][t]

    def stroke(self, pts, tone=None, delta=None, restrict=None, w=1):
        self.retone(self.line(pts, w), tone=tone, delta=delta, restrict=restrict)

    def paint(self, mask, color, as_outline=False):
        c = hexc(color) if isinstance(color, str) else tuple(color)
        self.col[mask] = c
        self.filled |= mask
        self.is_out[mask] = as_outline
        self.rid[mask] = -1

    def px(self, pts, color):
        c = hexc(color) if isinstance(color, str) else tuple(color)
        for x, y in pts:
            x, y = int(x), int(y)
            if 0 <= x < self.W and 0 <= y < self.H:
                self.col[y, x] = c
                self.filled[y, x] = True
                self.is_out[y, x] = False
                self.rid[y, x] = -1

    def bounce(self, group, tone_from=4, tone_to=3):
        """Reflected light: darkest pixels right next to the outline on the shadow side go one step lighter."""
        sel = self.filled & ~self.is_out & (self.rid >= 0) & (self.group == group) & (self.tone == tone_from)
        nb = shifted(self.is_out, 1, 0) | shifted(self.is_out, 0, 1)
        sel &= nb
        ys, xs = np.where(sel)
        for y, x in zip(ys, xs):
            self.tone[y, x] = tone_to
            self.col[y, x] = self.ramps[self.rid[y, x]][tone_to]

    def image(self, shadow_col=(0x2E, 0x35, 0x50), shadow_a=96):
        rgba = np.zeros((self.H, self.W, 4), np.uint8)
        sh = self.shadow & ~self.filled
        rgba[sh, :3] = shadow_col
        rgba[sh, 3] = shadow_a
        rgba[self.filled, :3] = self.col[self.filled]
        rgba[self.filled, 3] = 255
        return Image.fromarray(rgba, 'RGBA')
