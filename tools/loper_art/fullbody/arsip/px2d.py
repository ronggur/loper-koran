"""Small 2D pixel-art painter: parts built from shapes, 3-tone shading, 1px outline, cast shadows.

Coordinates are pixel coordinates (x right, y down); a pixel (x, y) is inside a shape when its
integer coordinate satisfies the shape test. Light comes from the upper-left (ART_DIRECTION 2.1).
"""
import math
import numpy as np
from PIL import Image, ImageDraw

OUT = (0x0E, 0x0A, 0x1C)


def hexc(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def mat(l, b, d):
    return (hexc(l), hexc(b), hexc(d))


def flat(c):
    c = hexc(c)
    return (c, c, c)


def shifted(m, dx, dy):
    """out[y, x] = m[y + dy, x + dx] (False outside)."""
    H, W = m.shape
    o = np.zeros_like(m)
    ys0, ys1 = max(0, -dy), min(H, H - dy)
    xs0, xs1 = max(0, -dx), min(W, W - dx)
    if ys1 > ys0 and xs1 > xs0:
        o[ys0:ys1, xs0:xs1] = m[ys0 + dy:ys1 + dy, xs0 + dx:xs1 + dx]
    return o


class Canvas:
    def __init__(self, W, H):
        self.W, self.H = W, H
        self.yy, self.xx = np.mgrid[0:H, 0:W].astype(float)
        self.filled = np.zeros((H, W), bool)
        self.col = np.zeros((H, W, 3), np.uint8)
        self.is_out = np.zeros((H, W), bool)
        self.group = np.full((H, W), '', object)
        self.matid = np.full((H, W), -1, int)
        self.tone = np.zeros((H, W), int)
        self.mats = []
        self.shadow = np.zeros((H, W), bool)
        self.parts = {}

    # ---------- shapes ----------
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
        px, py = x0 + t * dx, y0 + t * dy
        d = np.hypot(self.xx - px, self.yy - py)
        return d <= r0 + (r1 - r0) * t

    def chain(self, pts, r0, r1=None):
        r1 = r0 if r1 is None else r1
        m = np.zeros((self.H, self.W), bool)
        n = len(pts) - 1
        for i in range(n):
            a = r0 + (r1 - r0) * i / n
            b = r0 + (r1 - r0) * (i + 1) / n
            m |= self.capsule(pts[i], pts[i + 1], a, b)
        return m

    def poly(self, pts):
        im = Image.new('L', (self.W, self.H), 0)
        ImageDraw.Draw(im).polygon([tuple(p) for p in pts], fill=1, outline=1)
        return np.array(im, bool)

    def ring(self, cx, cy, ro, ri):
        d = np.hypot(self.xx - cx, self.yy - cy)
        return (d <= ro) & (d > ri)

    def disc(self, cx, cy, r):
        return np.hypot(self.xx - cx, self.yy - cy) <= r

    def line_mask(self, p0, p1, w=1):
        im = Image.new('L', (self.W, self.H), 0)
        ImageDraw.Draw(im).line([tuple(p0), tuple(p1)], fill=1, width=w)
        return np.array(im, bool)

    def polyline_mask(self, pts, w=1):
        im = Image.new('L', (self.W, self.H), 0)
        ImageDraw.Draw(im).line([tuple(p) for p in pts], fill=1, width=w)
        return np.array(im, bool)

    def rect(self, x0, y0, x1, y1):
        return (self.xx >= x0) & (self.xx <= x1) & (self.yy >= y0) & (self.yy <= y1)

    # ---------- painting ----------
    def add_shadow(self, m):
        self.shadow |= m

    def part(self, name, mask, m, group='', lw=2, dw=3, light_dirs=((-1, 0), (0, -1)),
             dark_dirs=((1, 0), (0, 1)), outline=True, cast=0, cast_dirs=((1, 1), (1, 0), (0, 1)),
             extra_dark=None, extra_light=None, flat_tone=None, inner_out=None):
        mask = mask & ~np.zeros_like(mask)
        if not mask.any():
            return mask
        mid = len(self.mats)
        self.mats.append(m)
        tone = np.ones(mask.shape, int)
        if flat_tone is None:
            dark = np.zeros_like(mask)
            for dx, dy in dark_dirs:
                for k in range(1, dw + 1):
                    dark |= ~shifted(mask, dx * k, dy * k)
            light = np.zeros_like(mask)
            for dx, dy in light_dirs:
                for k in range(1, lw + 1):
                    light |= ~shifted(mask, dx * k, dy * k)
            tone[light & mask] = 0
            tone[dark & mask] = 2
        else:
            tone[:] = flat_tone
        if extra_light is not None:
            tone[extra_light & mask] = 0
        if extra_dark is not None:
            tone[extra_dark & mask] = 2

        # cast shadow onto earlier pixels of the same group
        if cast:
            cs = np.zeros_like(mask)
            for dx, dy in cast_dirs:
                for k in range(1, cast + 1):
                    cs |= shifted(mask, -dx * k, -dy * k)
            cs &= self.filled & ~mask & ~self.is_out & (self.group == group)
            ys, xs = np.where(cs)
            for y, x in zip(ys, xs):
                mi = self.matid[y, x]
                if mi >= 0:
                    self.tone[y, x] = 2
                    self.col[y, x] = self.mats[mi][2]

        # outline: boundary pixels whose outside neighbours are not all outline already
        boundary = np.zeros_like(mask)
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nb = shifted(mask, dx, dy)
            outside = mask & ~nb
            nb_out = shifted(self.is_out, dx, dy)
            boundary |= outside & ~nb_out
        if outline is False:
            boundary[:] = False
        elif outline == 'outer':
            # only where the outside neighbour is empty canvas
            ob = np.zeros_like(mask)
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                ob |= mask & ~shifted(mask, dx, dy) & ~shifted(self.filled, dx, dy)
            boundary &= ob

        empty_before = ~self.filled
        touch_empty = np.zeros_like(mask)
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            touch_empty |= mask & ~shifted(mask, dx, dy) & shifted(empty_before, dx, dy)
        # pixels at the canvas border count as touching empty space
        edge = np.zeros_like(mask)
        edge[0, :] = edge[-1, :] = True
        edge[:, 0] = edge[:, -1] = True
        touch_empty |= mask & edge

        cols = np.array(m, np.uint8)[tone]
        self.col[mask] = cols[mask]
        self.matid[mask] = mid
        self.tone[mask] = tone[mask]
        self.is_out[mask] = False
        self.group[mask] = group
        self.filled |= mask
        if inner_out is not None:
            # silhouette edges stay OUT, edges against already-painted pixels use inner_out
            ic = hexc(inner_out) if isinstance(inner_out, str) else inner_out
            self.col[boundary & ~touch_empty] = ic
            self.col[boundary & touch_empty] = OUT
        else:
            self.col[boundary] = OUT
        self.is_out[boundary] = True
        self.parts[name] = mask
        return mask

    def tone_pix(self, mask, tone):
        """Re-tone existing material pixels (folds, creases)."""
        sel = mask & self.filled & ~self.is_out & (self.matid >= 0)
        ys, xs = np.where(sel)
        for y, x in zip(ys, xs):
            self.tone[y, x] = tone
            self.col[y, x] = self.mats[self.matid[y, x]][tone]

    def paint(self, mask, color, outline=False):
        c = hexc(color) if isinstance(color, str) else color
        self.col[mask] = c
        self.filled |= mask
        self.is_out[mask] = outline
        self.matid[mask] = -1

    def px(self, pts, color):
        c = hexc(color) if isinstance(color, str) else color
        for x, y in pts:
            if 0 <= x < self.W and 0 <= y < self.H:
                self.col[y, x] = c
                self.filled[y, x] = True
                self.is_out[y, x] = (c == OUT)
                self.matid[y, x] = -1

    def erase(self, mask):
        self.filled &= ~mask
        self.is_out &= ~mask

    # ---------- output ----------
    def image(self):
        rgba = np.zeros((self.H, self.W, 4), np.uint8)
        sh = self.shadow & ~self.filled
        rgba[sh] = (0, 0, 0, 71)
        rgba[self.filled, :3] = self.col[self.filled]
        rgba[self.filled, 3] = 255
        return Image.fromarray(rgba, 'RGBA')
