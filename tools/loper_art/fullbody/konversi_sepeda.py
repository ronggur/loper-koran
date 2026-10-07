"""Perbaikan sepeda di hasil konversi gambar AI loper (dipanggil dari konversi_loper.py).

Hanya empat bagian yang diubah; roda, spakbor, sadel, rak, head tube, garpu, lampu, gir, latar gelap, dan
sepatu tetap piksel gambar AI:

1. frame terlalu panjang dan pipanya patah kalau ditarik garis: bagian belakang sepeda (roda belakang,
   spakbor, rak, sadel, tas) digeser ke depan SHIFT px dengan membuang satu lajur di belakang kaki kiri
   tokoh, lalu pipa frame digambar ulang lurus: top tube dan seat tube dari sadel, down tube dan chainstay
   ke as pedal, seat stay ke poros belakang;
2. engkol tidak segaris: kedua lengan engkol dan pedal digambar ulang pada satu garis melewati as pedal;
3. setang kiri terputus: batang setang disambung dari grip ke stem;
4. tas boncengan bertutup sehingga koran tampak menembus tutup: tas digambar ulang tanpa tutup dengan warna
   kulit yang sama, koran terlihat di dalamnya, dan tas sisi seberang mengintip di kanan atas.

Koordinat khusus untuk gambar sumber docs/design/character/loper_agen/konversi/sumber_ai.jpg
(hasil konversi 266x281 px, sebelum kepala diturunkan).
"""
import math
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage
import pxhd
from pxhd import Canvas, ramp, hexc

# ---------------- geometri gambar AI (px, y ke bawah) ----------------
REAR_AXLE = (42.0, 220.0)            # sebelum digeser
FRONT_AXLE = (218.0, 220.0)
TYRE_R = 40.0
BB = (121.0, 226.0)                  # as pedal (tengah gir), tidak bergeser
SADDLE_BOX = (62, 128, 97, 154)      # sadel, per, dan klem
SADDLE_CLAMP = (83.0, 153.0)         # bawah klem sadel, sebelum digeser
SEAT_Y = 157.0                       # tinggi pertemuan seat tube, top tube dan seat stay
TT_FRONT, DT_FRONT = (187.0, 153.5), (189.0, 161.0)   # sambungan top tube dan down tube di head tube
CUT, SHIFT = 96, 24                  # lajur x 96..119 (di belakang kaki kiri) dibuang; jarak poros 176 -> 152 px
SADDLE_SHIFT = 12                    # sadel maju lebih sedikit supaya tetap terlihat di samping pinggul
CRANK_LEN, CRANK_ANGLE = 22.0, -8.0  # pedal dekat di bawah, sedikit ke belakang; pedal seberang di sela kaki
RING_R = 12.5                        # jari-jari gir (gir dan pelindung rantai tetap dari gambar AI)
BAG_X, RIM_Y = 12, 162               # tepi kiri dan bibir tas dekat, sebelum digeser
FAR_OFFSET = (10, -8)                # tas sisi seberang mengintip ke kanan atas

# ---------------- palet gambar AI ----------------
GREEN = ramp('#7c8f58', '#627848', '#496039', '#33482c', '#21331f')
SILVER = ramp('#f5e6d7', '#c7b6a8', '#8e837f', '#5c5554', '#453f3e')
DARKMET = ramp('#5c5554', '#453f3e', '#343031', '#272424', '#191718')
LEATHER = ramp('#b67347', '#925033', '#783b26', '#61301f', '#482013')
LEATHER_FAR = ramp('#925033', '#783b26', '#61301f', '#482013', '#321307')
PAPER = ramp('#f5e6d7', '#e2d1be', '#c7b6a8', '#ab9b90', '#8e837f')
PAPER_FAR = ramp('#e2d1be', '#c7b6a8', '#ab9b90', '#8e837f', '#756a64')
NAVY, NAVY_FAR, TEXT = hexc('#343d62'), hexc('#2a3154'), hexc('#ab9b90')
OUT_DARK, OUT_GREEN = hexc('#0b0806'), hexc('#141e10')
BG_COLS = ('#3d2a1c', '#3a2b22', '#211610')       # latar gelap gambar AI di dalam sepeda (dipertahankan)


def hsv(a):
    rgb = a[..., :3].astype(float) / 255
    mx, mn = rgb.max(-1), rgb.min(-1)
    d = mx - mn + 1e-9
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    h = np.where(mx == r, (g - b) / d % 6, np.where(mx == g, (b - r) / d + 2, (r - g) / d + 4)) * 60
    return h, np.where(mx > 0, d / (mx + 1e-9), 0), mx


def poly_mask(W, H, pts):
    im = Image.new('L', (W, H), 0)
    ImageDraw.Draw(im).polygon(pts, fill=1, outline=1)
    return np.array(im, bool)


SHOES = (
    [(71, 268), (73, 262), (82, 257), (86, 250), (93, 247), (101, 246), (108, 249), (113, 253), (116, 258),
     (115, 264), (101, 268), (89, 273), (76, 273)],
    [(148, 262), (152, 257), (156, 247), (168, 247), (173, 251), (177, 256), (182, 262), (182, 275),
     (177, 279), (164, 279), (149, 269)],
)


class Img:
    """The converted picture plus masks used by every step."""

    def __init__(self, a):
        self.a = a
        self.H, self.W = a.shape[:2]
        self.yy, self.xx = np.mgrid[0:self.H, 0:self.W]

    def box(self, x0, y0, x1, y1):
        return (self.xx >= x0) & (self.xx <= x1) & (self.yy >= y0) & (self.yy <= y1)

    def solid(self):
        return self.a[..., 3] == 255

    def bg(self):
        m = np.zeros((self.H, self.W), bool)
        for c in BG_COLS:
            m |= np.all(self.a[..., :3] == hexc(c), -1)
        return m & self.solid()

    def empty(self):
        return self.a[..., 3] == 0

    def dist(self, c):
        return np.hypot(self.xx - c[0], self.yy - c[1])

    def fill_from_background(self, hole, ground_y=258):
        """Holes take the nearest background pixel: the dark AI background, the ground shadow or nothing.
        On the ground (below the dark area between the feet) only the shadow or nothing is used."""
        a = self.a
        for rows, cand in ((self.yy < ground_y, self.bg() | (a[..., 3] < 255)), (self.yy >= ground_y, a[..., 3] < 255)):
            h = hole & rows
            if not h.any():
                continue
            cand = cand & ~hole
            _, (iy, ix) = ndimage.distance_transform_edt(~cand, return_indices=True)
            a[h] = a[iy[h], ix[h]]


def rider_mask(im):
    a, solid = im.a, im.solid()
    h, s, v = hsv(a)
    bg = im.bg()
    blue = solid & (h > 195) & (h < 250) & (s > 0.1) & (v > 0.2) & (im.yy >= 100)
    rider = ndimage.binary_fill_holes(blue) & solid                     # kemeja, celana, kancing, tali
    skin = solid & (h > 8) & (h < 45) & (s > 0.3) & (v > 0.4)
    rider |= skin & (im.box(176, 100, 220, 142) | im.box(90, 236, 178, 258))
    rider |= solid & (h > 35) & (h < 60) & (s > 0.5) & im.box(176, 108, 210, 126)   # gelang
    for pts in SHOES:
        rider |= poly_mask(im.W, im.H, pts) & (solid | (a[..., 3] > 0)) & ~bg
    green = solid & (h > 70) & (h < 125) & (s > 0.2)
    rider |= ndimage.binary_dilation(rider) & solid & (v < 0.22) & ~bg & ~green   # garis luar
    rider |= solid & (im.yy < 118)                                       # kepala, lengan, koran di tangan
    return rider


def layer(im):
    return Canvas(im.W, im.H)


def part(c, *args, out=OUT_DARK, **kw):
    pxhd.OUT = out
    try:
        return c.part(*args, **kw)
    finally:
        pxhd.OUT = OUT_DARK


def tube(c, name, p0, p1, r0, r1=None, rp=GREEN, out=OUT_GREEN, group='bike', **kw):
    r1 = r0 if r1 is None else r1
    return part(c, name, c.capsule(p0, p1, r0, r1), rp, group, round_r=('tube', [p0, p1], [r0, r1]), out=out, **kw)


def place(im, c, allow):
    lay = np.array(c.image())
    m = (lay[..., 3] == 255) & allow
    im.a[m] = lay[m]


# ---------------- 1. frame ----------------
def erase_frame(im, rider):
    """Old green tubes (and their dark edges) go; head tube, fork and fenders stay."""
    a = im.a
    h, s, v = hsv(a)
    green = im.solid() & (h > 70) & (h < 125) & (s > 0.2)
    fenders = (np.abs(im.dist(REAR_AXLE) - TYRE_R - 3.5) < 3.5) | (np.abs(im.dist(FRONT_AXLE) - TYRE_R - 3.5) < 3.5)
    head = (im.xx >= 186) & (im.yy < 180) | (im.xx >= 183) & (im.yy >= 180)
    guard = (im.dist(BB) <= RING_R + 4) & (im.yy <= 240)                 # chain guard around the chainring
    tubes = green & ~fenders & ~head & ~guard & ~rider
    edge = ndimage.binary_dilation(tubes, iterations=2) & im.solid() & (v < 0.16) & ~im.bg() & ~rider & ~head
    tyres = (np.abs(im.dist(REAR_AXLE) - TYRE_R + 2.5) < 3.5) | (np.abs(im.dist(FRONT_AXLE) - TYRE_R + 2.5) < 3.5)
    decal = im.box(150, 166, 186, 196) & im.solid() & (v > 0.45) & (s < 0.4) & ~rider & ~head   # old cream band
    hole = tubes | decal | (edge & ~tyres)
    im.fill_from_background(hole)


def draw_frame(im, rider, g):
    c = layer(im)
    RA, SC = g['RA'], g['SC']
    st_top = (SC[0] + (SC[0] - BB[0]) * 3 / (BB[1] - SC[1]), SC[1] - 3)     # seat tube ends just above the cluster
    post = layer(im)
    tube(post, 'seatpost', SC, g['CLAMP'], 1.4, rp=SILVER, out=OUT_DARK)
    place(im, post, ~rider & (im.bg() | im.empty()))
    tube(c, 'chainstay', RA, BB, 2.2, 2.5)
    tube(c, 'seatstay', RA, SC, 2.0, 2.3)
    tube(c, 'seattube', BB, st_top, 3.0, 2.8)
    tube(c, 'downtube', BB, DT_FRONT, 3.4, 3.2)
    tube(c, 'toptube', SC, TT_FRONT, 3.0, 3.0)

    def q(t):
        return (BB[0] + (DT_FRONT[0] - BB[0]) * t, BB[1] + (DT_FRONT[1] - BB[1]) * t)

    band = c.capsule(q(0.69), q(0.79), 5) & c.parts['downtube'] & ~c.is_out   # cream band, as in the AI picture
    ux, uy = DT_FRONT[0] - BB[0], DT_FRONT[1] - BB[1]
    ln = math.hypot(ux, uy)
    side = ((c.xx - BB[0]) * uy - (c.yy - BB[1]) * ux) / ln             # > 0 above the tube axis (lit side)
    for lo, hi, col in ((-9, -1.2, PAPER[2]), (-1.2, 1.2, PAPER[1]), (1.2, 9, PAPER[0])):
        c.paint(band & (side > lo) & (side <= hi), col)
    head = (im.xx >= 186) & (im.yy < 180) | (im.xx >= 183) & (im.yy >= 180)
    ring = im.dist(BB) <= RING_R
    allow = ~rider & ~head & ~(ring & ~im.bg()) & ~im.box(150, 112, 216, 149)
    place(im, c, allow)


# ---------------- 2. rear part forward ----------------
def shifted(m, d):
    out = np.zeros_like(m)
    out[:, d:] = m[:, :-d]
    return out


def shift_rear(im, rider, shift=SHIFT, saddle_shift=SADDLE_SHIFT):
    """Everything behind CUT (except the rider) moves forward; the strip CUT..CUT+shift is dropped.
    The saddle moves less so that it still shows beside the hip."""
    a = im.a
    saddle = im.box(*SADDLE_BOX) & im.solid() & ~rider & ~im.bg()
    saddle_px = a.copy()
    a[saddle] = 0
    src = a.copy()
    shoes = np.zeros_like(rider)
    for pts in SHOES:
        shoes |= poly_mask(im.W, im.H, pts)
    hole_src = rider | ndimage.binary_dilation(shoes, iterations=3)     # never drag shoe edges along
    move = (im.xx < CUT + shift) & (im.yy >= 118) & ~rider
    tgt_src = np.zeros_like(a)
    tgt_src[:, shift:] = src[:, :-shift]
    tgt_hole = np.zeros_like(rider)
    tgt_hole[:, shift:] = hole_src[:, :-shift]
    tgt_hole[:, :shift] = False
    a[move] = tgt_src[move]
    a[move & (im.xx < shift)] = 0
    put = shifted(saddle, saddle_shift) & ~rider
    a[put] = shifted(saddle_px, saddle_shift)[put]
    vacated = shifted(saddle, shift) & ~put & ~rider
    im.fill_from_background((move & tgt_hole & ~put) | vacated)


# ---------------- 3. cranks ----------------
def erase_cranks(im, rider):
    """Old crank arms and pedals go. Inside the chainring the hole is filled from the ring itself, turned by
    one spider arm (72 degrees), so the ring and its spokes stay whole."""
    a = im.a
    h, s, v = hsv(a)
    c = Canvas(im.W, im.H)
    arms = c.capsule((126.0, 206.0), (126.0, 216.0), 2.5) | c.capsule((121.0, 231.0), (130.0, 248.0), 2.6)
    pedals = im.box(118, 198, 136, 208) | im.box(117, 244, 137, 254)
    old = (arms | pedals) & ~rider & im.solid() & ~im.bg() & ~((h > 70) & (h < 125) & (s > 0.2))
    inner = old & (im.dist(BB) <= RING_R)
    t = math.radians(-72)
    dx, dy = im.xx - BB[0], im.yy - BB[1]
    sx = np.clip(np.round(BB[0] + dx * math.cos(t) - dy * math.sin(t)).astype(int), 0, im.W - 1)
    sy = np.clip(np.round(BB[1] + dx * math.sin(t) + dy * math.cos(t)).astype(int), 0, im.H - 1)
    green = (h > 70) & (h < 125) & (s > 0.2)
    ok = inner & ~old[sy, sx] & ~rider[sy, sx] & im.solid()[sy, sx] & ~green[sy, sx]
    a[ok] = a[sy[ok], sx[ok]]
    im.fill_from_background(old & ~ok)
    # the old lower pedal had a see-through shadow pocket under it; without the pedal it reads as a hole
    pocket = im.box(110, 244, 140, 254) & (a[..., 3] < 255) & ~rider
    a[pocket] = (*hexc(BG_COLS[0]), 255)


def draw_cranks(im, rider):
    t = math.radians(CRANK_ANGLE)
    d = (CRANK_LEN * math.sin(t), CRANK_LEN * math.cos(t))
    near, far = (BB[0] + d[0], BB[1] + d[1]), (BB[0] - d[0], BB[1] - d[1])
    ring = (im.dist(BB) <= RING_R) & ~im.bg()
    c = layer(im)
    tube(c, 'farcrank', BB, far, 1.6, 1.4, rp=DARKMET, out=OUT_DARK)
    part(c, 'farpedal', c.rect(far[0] - 6, far[1] - 2.5, far[0] + 6, far[1] + 2.5), DARKMET, 'bike', round_r=2)
    place(im, c, ~rider & ~ring)
    c = layer(im)
    tube(c, 'nearcrank', BB, near, 2.0, 1.8, rp=SILVER, out=OUT_DARK)
    part(c, 'bolt', c.disc(BB[0], BB[1], 2.2), SILVER, 'bike', round_r=2)
    pd = c.rect(near[0] - 6, near[1] - 2.5, near[0] + 6, near[1] + 2.5)
    part(c, 'nearpedal', pd, DARKMET, 'bike', round_r=2)
    c.retone(pd & ~c.is_out & ((c.xx.astype(int) % 3) == 0), tone=0)   # rubber blocks
    place(im, c, ~rider)
    return near, far


# ---------------- 4. handlebar ----------------
def draw_bar(im, rider):
    c = layer(im)
    tube(c, 'bar', (172.0, 127.0), (186.0, 128.0), 1.8, rp=SILVER, out=OUT_DARK)
    place(im, c, ~rider & (im.bg() | im.empty()))


# ---------------- 5. bags ----------------
def paper_sheet(c, name, grp, px, top, sw, tilt, base, pp, navy):
    sk = math.tan(math.radians(tilt))
    off = sk * (base - top)
    pm = c.poly([(px + off, top + 1), (px + 1 + off, top), (px + sw - 1 + off, top), (px + sw + off, top + 1),
                 (px + sw, base), (px, base)])
    part(c, name, pm, pp, grp, flat=1, cast=1)
    inner = pm & ~c.is_out
    y0 = np.where(inner.any(1))[0].min()
    u = c.xx - sk * (base - c.yy)
    c.retone(inner & (c.yy == y0), tone=0)                                  # lit fold
    c.retone(inner & (u > px + sw - 3), tone=2)                             # page edges
    c.paint(inner & (c.yy >= y0 + 2) & (c.yy <= y0 + 3) & (u > px + 1) & (u < px + sw - 4), navy)
    for ty in range(y0 + 6, base, 2):
        c.paint(inner & (c.yy == ty) & (u > px + 2) & (u < px + sw - 5) & (((c.xx.astype(int) + ty) % 7) != 0), TEXT)


def paper_roll(c, name, grp, b, t, pp):
    part(c, name, c.capsule(b, t, 3.8), pp, grp, round_r=('tube', [b, t], [3.8, 3.8]), amb=0.22, cast=1)
    ang = math.degrees(math.atan2(t[1] - b[1], t[0] - b[0]))
    part(c, f'{name}_end', c.ellipse(t[0], t[1], 1.9, 3.8, rot=ang), pp, grp, flat=1)
    c.retone(c.ellipse(t[0], t[1], 1.1, 2.4, rot=ang) & ~c.ellipse(t[0], t[1], 0.5, 1.2, rot=ang) & ~c.is_out, tone=3)
    c.paint(c.ellipse(t[0], t[1], 0.5, 1.0, rot=ang) & ~c.is_out, pp[4])


def draw_bag(c, name, x0, rim, far=False):
    """Open pannier without a lid: dark inside, papers standing in it, leather front wall."""
    rp, pp, navy = (LEATHER_FAR, PAPER_FAR, NAVY_FAR) if far else (LEATHER, PAPER, NAVY)
    w, bot = 44, rim + 41
    grp = name
    back = c.poly([(x0 + 1, rim - 3), (x0 + w - 1, rim - 4), (x0 + w, rim + 4), (x0, rim + 4)])
    part(c, f'{name}_back', back, rp, grp, flat=3)
    c.stroke([(x0 + 2, rim - 2), (x0 + w - 2, rim - 3)], tone=2, restrict=back)
    c.retone(back & ~c.is_out & (c.yy >= rim - 1), tone=4)
    if far:
        for k, (px, top, sw, tilt) in enumerate(((x0 + 22, rim - 9, 16, 4.0), (x0 + 28, rim - 6, 14, -3.0))):
            paper_sheet(c, f'{name}_sheet{k}', grp, px, top, sw, tilt, rim + 4, pp, navy)
    else:
        # two rolled papers leaning back like in the AI picture, folded papers in front of them
        paper_roll(c, f'{name}_roll0', grp, (x0 + 13, rim + 4), (x0 + 2, rim - 17), pp)
        paper_roll(c, f'{name}_roll1', grp, (x0 + 25, rim + 4), (x0 + 19, rim - 24), pp)
        for k, (px, top, sw, tilt) in enumerate(((x0 + 22, rim - 10, 17, 3.0), (x0 + 26, rim - 6, 16, -4.0))):
            paper_sheet(c, f'{name}_sheet{k}', grp, px, top, sw, tilt, rim + 4, pp, navy)
    front = c.poly([(x0, rim), (x0 + w - 2, rim - 1), (x0 + w, rim + 1), (x0 + w, bot - 4), (x0 + w - 4, bot),
                    (x0 + 4, bot), (x0, bot - 4)])
    part(c, f'{name}_front', front, rp, grp, round_r=8, cast=2)
    inside = front & ~c.is_out
    top_row = np.where(inside.any(1))[0].min()
    c.retone(inside & (c.yy <= top_row + 1), tone=0)                        # rolled lit rim
    c.retone(inside & (c.yy == top_row + 2), tone=3)
    c.retone(inside & (c.yy == top_row + 4) & ((c.xx.astype(int) % 3) == 0), tone=1)   # stitching
    if far:
        c.retone(inside & (c.xx >= x0 + w - 3), tone=3)
        sm = c.rect(x0 + 38, rim + 5, x0 + 40, rim + 26) & front             # its strap shows beside the near bag
        part(c, f'{name}_strap', sm, LEATHER_FAR, grp, flat=3, cast=1)
        part(c, f"{name}_buckle", c.rect(x0 + 37, rim + 20, x0 + 41, rim + 23), SILVER, grp, flat=2)
        return
    # front pocket with two buckle straps, like the AI picture (the pocket stays, the big lid is gone)
    pk = c.poly([(x0 + 5, rim + 15), (x0 + 38, rim + 14), (x0 + 39, bot - 5), (x0 + 6, bot - 4)])
    c.retone(pk & inside, delta=1)
    c.retone(pk & ~ndimage.binary_erosion(pk) & inside, tone=4)
    c.retone(pk & inside & (c.yy == rim + 16) & (c.xx > x0 + 6) & (c.xx < x0 + 38), tone=0)
    for sx in (x0 + 11, x0 + 29):
        sm = c.rect(sx, rim + 5, sx + 3, rim + 25) & front
        part(c, f'{name}_strap{sx}', sm, LEATHER, grp, flat=3, cast=1)
        c.retone(sm & ~c.is_out & (c.xx == sx + 1), tone=1)
        bk = c.rect(sx - 1, rim + 19, sx + 4, rim + 23)
        part(c, f'{name}_buckle{sx}', bk, SILVER, grp, round_r=1.5)
        c.paint(c.rect(sx + 1, rim + 20, sx + 2, rim + 22) & ~c.is_out, LEATHER[3])
    side = c.poly([(x0 + w, rim + 1), (x0 + w + 3, rim), (x0 + w + 3, bot - 5), (x0 + w, bot - 3)])
    part(c, f'{name}_side', side & ~front, rp, grp, flat=3)


def erase_old_bag(im, rider):
    """The lid, the rolls above it and the old bag body go; the new bag covers the same place.
    The rear tyre, the fender and the rack next to the bag stay."""
    a = im.a
    h, s, v = hsv(a)
    area = im.solid() & ~rider & im.box(4, 126, 60, 205) & ~im.bg() & ~im.box(50, 150, 75, 166)
    wheel = (im.dist(REAR_AXLE) > TYRE_R - 7) & (im.dist(REAR_AXLE) < TYRE_R + 7.5)
    leather = (h > 5) & (h < 40) & (s > 0.3)
    paper = (s < 0.3) & (v > 0.4)
    metal = (s < 0.3) & (v >= 0.22) & (v <= 0.4) & ~wheel                    # buckles
    bag = area & (leather | paper | metal)
    bag |= area & (v < 0.22) & ndimage.binary_dilation(bag, iterations=2)    # its outline
    bag &= ~(wheel & ~leather)                                                  # tyre and fender pixels are not leather
    # dark shading left of the bag, outside the wheel, was part of the bag too
    left = im.box(0, 126, 14, 205) & im.bg() & (im.dist(REAR_AXLE) > TYRE_R + 7.5) & ~rider
    left |= im.box(4, 126, 50, 159) & im.bg() & ~rider                    # shading of the rolls above the lid
    a[left] = 0
    im.fill_from_background(bag)


def draw_bags(im, rider, shift):
    x0 = BAG_X + shift
    c = layer(im)
    draw_bag(c, 'farbag', x0 + FAR_OFFSET[0], RIM_Y + FAR_OFFSET[1], far=True)
    place(im, c, ~rider & (im.bg() | (im.a[..., 3] < 255)))             # behind wheel, rack and frame
    c = layer(im)
    draw_bag(c, 'nearbag', x0, RIM_Y)
    place(im, c, ~rider)


def fix_bike(img, shift=SHIFT):
    im = Img(np.array(img))
    rider = rider_mask(im)
    erase_frame(im, rider)
    erase_cranks(im, rider)
    erase_old_bag(im, rider)
    shift_rear(im, rider, shift)
    clamp = (SADDLE_CLAMP[0] + SADDLE_SHIFT, SADDLE_CLAMP[1])
    k = (BB[1] - SEAT_Y) / (BB[1] - clamp[1])                    # seat cluster on the line BB -> saddle clamp
    g = dict(RA=(REAR_AXLE[0] + shift, REAR_AXLE[1]), CLAMP=clamp,
             SC=(BB[0] + (clamp[0] - BB[0]) * k, SEAT_Y))
    draw_frame(im, rider, g)
    draw_bags(im, rider, shift)
    draw_cranks(im, rider)
    draw_bar(im, rider)
    return Image.fromarray(im.a, 'RGBA')
