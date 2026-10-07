"""Gambar full body skala besar: loper anak muda dan sepedanya (294x283 px).

Gaya skala besar: lima nada per warna, garis dalam berwarna, bayangan berwarna (ART_DIRECTION 3.5).
Desain terpilih 2026-10-07: celana jogger, tanpa keranjang depan, kepala terpisah tanpa leher
(digambar di layer sendiri, celah GAP px di atas kerah terbuka), koran dijepit di sisi kiri bawah
di depan lengan.

    python3 tools/loper_art/fullbody/fullbody.py --out build/loper_art/fullbody
    python3 tools/loper_art/fullbody/fullbody.py --out build/loper_art/fullbody --layers   # + layer kepala dan badan
"""
import math
import os
import sys
import numpy as np
from PIL import Image
from scipy.ndimage import distance_transform_edt, label
from pxhd import Canvas, ramp, hexc, mix, OUT, shifted

W, H, G = 368, 336, 316

SKIN = ramp('#FFD9B4', '#F6BE92', '#E8A07A', '#C47A5E', '#8E4F46')
HAIR = ramp('#9C6B4C', '#7A4E38', '#5C3829', '#41271F', '#2A1819')
CAP = ramp('#FFFFFF', '#F8F2E3', '#E7DDC6', '#BDB2A8', '#857C8E')
NAVY = ramp('#93A1C6', '#7282AB', '#57658E', '#3F4A72', '#2A3154')
SHIRT = ramp('#C4E4F3', '#92C5E5', '#5F96C8', '#45709F', '#2E4B79')
BADGE = ramp('#FFF2AC', '#FFDC70', '#FFC94A', '#E39539', '#B4632E')
SHOE = ramp('#86828F', '#64606C', '#474651', '#302F3B', '#1F1D28')
SOLE = ramp('#FFFFFF', '#FBF6E8', '#ECE2C7', '#C8B797', '#9A8870')
SOCK = ramp('#FFFFFF', '#F6F3EE', '#E3DDD6', '#BDB4B4', '#8F8792')
FRAME = ramp('#94D06E', '#71B150', '#4F8B47', '#3A6A43', '#264733')
TIRE = ramp('#5E5965', '#46414D', '#322D37', '#241F2A', '#18141D')
METAL = ramp('#F4F2F7', '#CBC8D3', '#A09DAA', '#706D7C', '#4A4758')
DMETAL = ramp('#7E7A88', '#5F5B69', '#45424F', '#302E3A', '#1F1D28')
SADDLE = ramp('#A06E52', '#7E513C', '#5E3A2B', '#442921', '#2D1B18')
PANNIER = ramp('#E5876A', '#CC6A4E', '#AA4E3B', '#813B33', '#58282A')
PANNIER_FAR = ramp('#AA4E3B', '#8E4236', '#73372F', '#58282A', '#3E1D21')
STRAP = ramp('#5E3A2B', '#4A2D24', '#3B231E', '#2D1B18', '#1F1214')
PAPER = ramp('#FFFFFF', '#FCF7EA', '#EEE5CB', '#CABD9F', '#9B8D76')
PAPER2 = ramp('#FFFFFF', '#F4F2F6', '#DEDAE2', '#B5AFBC', '#8A8394')
BELL = ramp('#FFF3B0', '#FFDE72', '#F5BD3F', '#CC8A33', '#94592A')
LENS = ramp('#FFFFFF', '#FFF7D6', '#FFE89A', '#E8C060', '#B48A3E')
INK = hexc('#3E3A4D')

RA, FA, R = (92, 262), (268, 262), 54
BB = (168, 272)
SC = (144, 194)


def fold(c, pts, restrict, dark=3, light=1):
    """Cloth fold: a shade line with a lit edge on the light side (upper-left)."""
    c.stroke([(x - 1, y - 1) for x, y in pts], tone=light, restrict=restrict)
    c.stroke(pts, tone=dark, restrict=restrict)


def bike(c):
    g = 'bike'
    c.add_shadow(c.ellipse(180, G + 1, 132, 6.5))

    # ---- far side: pannier, drivetrain
    c.part('pannier_far', c.poly([(68, 197), (124, 197), (126, 240), (72, 242)]), PANNIER_FAR, g, round_r=6)
    ring = c.ring(BB[0], BB[1], 15, 9)
    c.part('chainring', ring, DMETAL, g, round_r=3)
    teeth = np.zeros_like(ring)
    for i in range(32):
        a = i * math.tau / 32
        teeth |= c.disc(BB[0] + 15.5 * math.cos(a), BB[1] + 15.5 * math.sin(a), 0.8)
    c.paint(teeth & ~c.filled, DMETAL[3])
    c.part('cog', c.disc(RA[0], RA[1], 7.2), DMETAL, g, round_r=3)
    chain = c.line([(BB[0], BB[1] - 14), (RA[0], RA[1] - 7)], 2) | c.line([(BB[0], BB[1] + 14), (RA[0], RA[1] + 7)], 2)
    c.paint(chain, DMETAL[3])
    links = np.zeros_like(chain)
    for t in np.linspace(0.05, 0.95, 18):
        for (x0, y0), (x1, y1) in (((BB[0], BB[1] - 14), (RA[0], RA[1] - 7)), ((BB[0], BB[1] + 14), (RA[0], RA[1] + 7))):
            links |= c.disc(x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, 0.6)
    c.paint(links & chain, DMETAL[1])
    c.part('crank_far', c.capsule(BB, (152, 294), 2.4), DMETAL, g, round_r=2)
    c.part('pedal_far', c.rect(142, 292, 160, 297), DMETAL, g, round_r=2)

    # ---- wheels
    for nm, (cx, cy) in (('rear', RA), ('front', FA)):
        tire = c.ring(cx, cy, R, R - 7)
        c.part(f'tire_{nm}', tire, TIRE, g, round_r=3.5)
        # tread: small knobs along the outer edge
        tread = np.zeros_like(tire)
        for i in range(72):
            a = i * math.tau / 72
            tread |= c.disc(cx + (R - 1.6) * math.cos(a), cy + (R - 1.6) * math.sin(a), 0.7)
        c.retone(tread & tire, delta=1)
        c.part(f'rim_{nm}', c.ring(cx, cy, R - 7, R - 11), METAL, g, round_r=2, outline='outer')
        c.retone(c.ring(cx, cy, R - 10, R - 11) & c.parts[f'rim_{nm}'], delta=1)
        sp = np.zeros_like(tire)
        for i in range(24):
            a = i * math.tau / 24
            side = 1 if i % 2 else -1
            p0 = (cx + 5 * math.cos(a + side * 0.9), cy + 5 * math.sin(a + side * 0.9))
            p1 = (cx + (R - 11) * math.cos(a), cy + (R - 11) * math.sin(a))
            sp |= c.line([p0, p1])
        sp &= ~c.disc(cx, cy, 5) & ~c.filled
        c.paint(sp, '#9C99A8')
        c.part(f'hub_{nm}', c.disc(cx, cy, 6.2), METAL, g, round_r=3)
        c.part(f'axle_{nm}', c.disc(cx, cy, 2.2), DMETAL, g, flat=2, outline=False)

    # ---- rear rack
    rack = c.capsule((70, 197), (140, 197), 1.8) | c.capsule((76, 197), (RA[0], RA[1]), 1.4) | c.capsule((120, 197), (RA[0] + 2, RA[1]), 1.4)
    c.part('rack', rack, METAL, g, round_r=1.5)

    # ---- frame
    tubes = [('chainstay', BB, RA, 2.8, 2.2), ('seatstay', (SC[0] + 2, SC[1] + 4), RA, 2.6, 2.0),
             ('seattube', BB, SC, 4.0, 3.4), ('downtube', BB, (246, 202), 4.8, 4.0),
             ('toptube', (SC[0] + 2, SC[1]), (242, 190), 3.6, 3.4)]
    for nm, a, b, r0, r1 in tubes:
        c.part(nm, c.capsule(a, b, r0, r1), FRAME, g, round_r=r0)
    # decal on the down tube
    d0 = (BB[0] + (246 - BB[0]) * 0.42, BB[1] + (202 - BB[1]) * 0.42)
    d1 = (BB[0] + (246 - BB[0]) * 0.62, BB[1] + (202 - BB[1]) * 0.62)
    c.paint(c.line([(d0[0] - 0.5, d0[1] - 1), (d1[0] - 0.5, d1[1] - 1)], 2) & c.parts['downtube'] & ~c.is_out, PAPER[2])
    c.paint(c.line([(d0[0] + 1, d0[1] + 1.5), (d1[0] + 1, d1[1] + 1.5)], 1) & c.parts['downtube'] & ~c.is_out, PANNIER[2])
    c.part('headtube', c.capsule((242, 184), (248, 210), 5.0), FRAME, g, round_r=4)
    c.part('fork', c.chain([(248, 210), (256, 236), (266, 260)], [3.6, 3.0, 2.4]), FRAME, g, round_r=3)
    c.part('bb', c.disc(BB[0], BB[1], 6.4), DMETAL, g, round_r=4)
    # seatpost, springs, saddle
    c.part('seatpost', c.capsule(SC, (140, 180), 2.2), METAL, g, round_r=2)
    springs = np.zeros((H, W), bool)
    for sx in (124, 132):
        pts = [(sx + (1.5 if k % 2 else -1.5), 181 + k * 1.6) for k in range(6)]
        springs |= c.line(pts)
    c.paint(springs, METAL[2])
    c.part('saddle', c.poly([(118, 175), (126, 170), (144, 171), (162, 174), (162, 179), (146, 181), (126, 184), (118, 181)]),
           SADDLE, g, round_r=4)
    c.stroke([(122, 180), (146, 178), (159, 176)], delta=-1, restrict=c.parts['saddle'])

    # ---- near crank, pedal, kickstand
    c.part('crank', c.capsule(BB, (190, 250), 2.6), METAL, g, round_r=2)
    c.part('pedal', c.rect(183, 247, 200, 252), DMETAL, g, round_r=2)
    c.part('kick', c.capsule((158, 278), (142, 312), 2.0), DMETAL, g, round_r=2)
    c.part('kickfoot', c.rect(136, 311, 147, 314), DMETAL, g, round_r=1)

    # ---- near pannier with newspapers
    for i, (x0, top, rp) in enumerate(((70, 180, PAPER), (80, 176, PAPER2), (90, 182, PAPER))):
        pm = c.capsule((x0 + 4, top), (x0 + 4, 204), 5.0)
        c.part(f'ppaper{i}', pm, rp, g, round_r=4)
        for yy in range(top + 2, 200, 4):
            c.retone(c.rect(x0 + 2, yy, x0 + 6, yy) & pm, tone=3)
    body = c.poly([(62, 202), (118, 202), (120, 206), (120, 246), (116, 250), (66, 250), (62, 246)])
    c.part('pannier', body, PANNIER, g, round_r=7)
    flap = c.poly([(59, 197), (120, 197), (122, 201), (122, 222), (117, 227), (65, 227), (59, 222)])
    c.part('flap', flap, PANNIER, g, round_r=5, cast=2)
    stitch = np.zeros((H, W), bool)
    for x in range(64, 118, 3):
        stitch |= c.rect(x, 223, x, 223)
    for y in range(201, 222, 3):
        stitch |= c.rect(63, y, 63, y) | c.rect(118, y, 118, y)
    c.retone(stitch & flap, tone=1)
    c.stroke([(66, 243), (116, 243)], delta=1, restrict=c.parts['pannier'])
    c.part('strap', c.rect(88, 210, 92, 238), STRAP, g, round_r=2)
    c.part('buckle', c.rect(85, 228, 95, 233), METAL, g, round_r=2)
    c.paint(c.rect(89, 230, 91, 231), DMETAL[3])

    # ---- handlebar, bell, headlamp
    c.part('stem', c.capsule((242, 186), (240, 174), 2.6), METAL, g, round_r=2)
    c.part('bar', c.chain([(242, 174), (232, 170), (220, 172)], 2.2), METAL, g, round_r=2)
    grip = c.capsule((209, 172), (222, 172), 3.4)
    c.part('grip', grip, DMETAL, g, round_r=3)
    for x in range(211, 222, 2):
        c.retone(c.rect(x, 169, x, 175) & grip, delta=1)
    c.part('bell', c.ellipse(233, 164.5, 4.8, 4.2), BELL, g, round_r=4)
    c.part('lamp', c.ellipse(253, 192, 6.0, 5.2), METAL, g, round_r=4)
    c.part('lens', c.ellipse(256.5, 192, 3.2, 4.0), LENS, g, round_r=3)


def character(c, pants='jogger', hmask=None):
    g = 'ch'
    c.add_shadow(c.ellipse(176, G + 1, 46, 7))

    # ---- far arm (viewer's right), hand on the grip
    c.part('uarm_r', c.capsule((194, 116), (206, 144), 7.4, 6.6), SKIN, g, round_r=('tube', [(194, 116), (206, 144)], [7.4, 6.6]))
    c.part('farm_r', c.capsule((206, 144), (213, 164), 6.4, 5.4), SKIN, g, cast=2, round_r=('tube', [(206, 144), (213, 164)], [6.4, 5.4]))
    c.part('wrist_r', c.capsule((206, 158), (218, 155), 2.4) & c.parts['farm_r'], BADGE, g, round_r=2, outline=False)
    hand = c.ellipse(216, 172, 7.0, 7.2) | c.ellipse(219, 175, 4.0, 4.4)
    c.part('hand_r', hand, SKIN, g, cast=2)
    for x in (213, 216, 219):
        c.stroke([(x, 175), (x + 1, 179)], tone=3, restrict=hand)
    c.part('sleeve_r', c.capsule((194, 117), (202, 132), 9.8, 9.2), SHIRT, g, cast=2)
    c.stroke([(193, 139), (209, 132)], tone=3, restrict=c.parts['sleeve_r'])

    # ---- legs, socks, shoes, pants
    kneeL, ankL = (154, 248), (154, 296)
    kneeR, ankR = (194, 248), (198, 294)
    if pants == '3/4':
        for nm, knee, ank in (('R', kneeR, ankR), ('L', kneeL, ankL)):
            calf = (knee[0] + (ank[0] - knee[0]) * 0.35, knee[1] + 16)
            c.part(f'shin_{nm}', c.chain([knee, calf, ank], [7.2, 7.8, 5.0]), SKIN, g, cast=1, round_r=('tube', [knee, calf, ank], [7.2, 7.8, 5.0]))
        for nm, ank in (('R', ankR), ('L', ankL)):
            c.part(f'sock_{nm}', c.capsule((ank[0], ank[1] - 6), (ank[0], ank[1] + 2), 5.6), SOCK, g, round_r=4)
            c.stroke([(ank[0] - 5, ank[1] - 5), (ank[0] + 5, ank[1] - 5)], delta=1, restrict=c.parts[f'sock_{nm}'])
    # shoes (far first)
    c.part('sole_R', c.poly([(189, 302), (221, 302), (221, 308), (217, 312), (189, 312)]), SOLE, g, round_r=3)
    shoeR = c.poly([(189, 290), (201, 288), (211, 293), (218, 299), (220, 303), (189, 306)])
    c.part('shoe_R', shoeR, SHOE, g, round_r=6, cast=2)
    c.part('sole_L', c.poly([(133, 305), (165, 305), (167, 311), (165, 315), (137, 315), (131, 311)]), SOLE, g, round_r=3)
    shoeL = c.poly([(146, 292), (162, 292), (165, 298), (165, 307), (133, 309), (133, 305), (139, 298)])
    c.part('shoe_L', shoeL, SHOE, g, round_r=6, cast=2)
    for sh, pts in ((shoeR, [(194, 292), (198, 291), (196, 294), (200, 293), (198, 296), (202, 295)]),
                    (shoeL, [(150, 295), (154, 294), (152, 297), (156, 296), (153, 299), (157, 298)])):
        c.px(pts, SOLE[1])
    c.stroke([(208, 296), (217, 302)], tone=1, restrict=shoeR)      # toe cap highlight
    c.stroke([(134, 306), (142, 300)], tone=1, restrict=shoeL)
    for x in range(137, 165, 4):
        c.retone(c.rect(x, 312, x + 1, 312) & c.parts['sole_L'], tone=3)
    for x in range(192, 219, 4):
        c.retone(c.rect(x, 309, x + 1, 309) & c.parts['sole_R'], tone=3)

    if pants == 'jogger':
        pR = [(186, 200), (190, 226), (194, 250), (197, 282)]; rR = [14, 13, 11.5, 8.2]
        pL = [(160, 200), (156, 226), (154, 250), (154, 283)]; rL = [14, 13, 11.5, 8.2]
        legR, legL = c.chain(pR, rR), c.chain(pL, rL)
        pelvis = c.poly([(146, 188), (202, 188), (204, 212), (146, 212)])
        pm = legR | legL | pelvis
        c.part('pants', pm, NAVY, g, sub=[(pelvis, 10), (legR, ('tube', pR, rR)), (legL, ('tube', pL, rL))], cast=2)
        # cuffs
        for nm, ank in (('R', (197, 284)), ('L', (154, 285))):
            x0, y0 = ank
            cuff = c.poly([(x0 - 6, y0 - 1), (x0 + 6, y0 - 1), (x0 + 7, y0 + 5), (x0 - 7, y0 + 5)])
            c.part(f'cuff_{nm}', cuff, NAVY, g, round_r=5, cast=1)
            for x in range(int(ank[0]) - 7, int(ank[0]) + 8, 2):
                c.retone(c.rect(x, ank[1] - 2, x, ank[1] + 6) & cuff, delta=1)
        # stacking folds above the cuffs, knee and thigh creases
        for (x0, y0) in ((148, 277), (149, 268), (190, 276), (191, 267)):
            fold(c, [(x0, y0), (x0 + 5, y0 + 2), (x0 + 10, y0)], pm)
        fold(c, [(159, 238), (153, 249)], pm)
        fold(c, [(196, 236), (200, 247)], pm)
        fold(c, [(172, 214), (166, 228)], pm)
        fold(c, [(178, 214), (183, 226)], pm)
        c.stroke([(149, 202), (153, 218)], tone=4, restrict=pm)   # pocket openings
        c.stroke([(199, 202), (196, 218)], tone=4, restrict=pm)
        draw = c.line([(172, 199), (171, 213)]) | c.line([(178, 199), (179, 211)])
        c.paint(draw, SOCK[2])
        c.px([(171, 214), (171, 215), (179, 212), (179, 213)], METAL[1])
    else:
        pR = [(186, 200), (190, 226), (194, 250), (195, 264)]; rR = [14, 13.5, 12.5, 12.5]
        pL = [(160, 200), (156, 226), (154, 250), (154, 266)]; rL = [14, 13.5, 12.5, 12.5]
        legR, legL = c.chain(pR, rR), c.chain(pL, rL)
        legR &= c.yy <= 268
        legL &= c.yy <= 270
        pelvis = c.poly([(146, 188), (202, 188), (204, 212), (146, 212)])
        pm = legR | legL | pelvis
        c.part('pants', pm, NAVY, g, sub=[(pelvis, 10), (legR, ('tube', pR, rR)), (legL, ('tube', pL, rL))], cast=2)
        # turned-up hems
        for nm, (x0, x1, y0) in (('R', (182, 208, 259), ), ('L', (141, 167, 261), )):
            hem = c.rect(x0, y0, x1, y0 + 7) & c.parts['pants']
            c.retone(hem, tone=1)
            c.stroke([(x0, y0), (x1, y0)], tone=4, restrict=c.parts['pants'])
            c.stroke([(x0, y0 + 4), (x1, y0 + 4)], tone=2, restrict=hem)
        # cargo pocket on the near (viewer's left) thigh
        pocket = c.rect(141, 222, 153, 240) & legL
        c.retone(pocket, delta=-1)
        c.stroke([(141, 222), (153, 222)], tone=4, restrict=pm)
        c.stroke([(141, 227), (153, 227)], tone=3, restrict=pm)
        c.stroke([(141, 240), (153, 240)], tone=4, restrict=pm)
        c.px([(147, 225)], METAL[1])
        fold(c, [(159, 242), (153, 251)], pm)
        fold(c, [(196, 238), (200, 248)], pm)
        fold(c, [(172, 214), (166, 228)], pm)
        fold(c, [(178, 214), (183, 226)], pm)
        c.stroke([(199, 202), (196, 218)], tone=4, restrict=pm)

    # ---- torso (shirt)
    torso = c.poly([(146, 112), (162, 109), (190, 109), (198, 112), (202, 120), (200, 140), (196, 164), (200, 194), (192, 199), (176, 201),
                    (156, 199), (146, 195), (150, 164), (146, 140), (144, 120)])
    c.part('torso', torso, SHIRT, g, round_r=11, cast=3)
    # placket and buttons
    plk = c.line([(177, 120), (178, 200)], 4) & torso
    c.retone(plk, tone=1)
    c.stroke([(175, 121), (176, 200)], tone=3, restrict=torso)
    for yy in (130, 146, 162, 178, 192):
        c.px([(178, yy), (179, yy)], CAP[1])
        c.px([(178, yy + 1), (179, yy + 1)], SHIRT[4])
    # pocket with badge
    pk = c.rect(183, 133, 195, 148)
    c.stroke([(183, 133), (183, 148), (195, 148), (195, 133)], tone=4, restrict=torso)
    c.stroke([(183, 137), (195, 137)], tone=3, restrict=torso)
    c.part('badge', c.rect(184, 125, 195, 129), BADGE, g, round_r=2, outline=True)
    c.paint(c.rect(186, 127, 193, 127), BADGE[3])
    # folds
    for pts in ([(152, 142), (156, 160), (158, 176)], [(195, 152), (190, 168)], [(193, 178), (187, 193)],
                [(160, 185), (165, 196)]):
        fold(c, pts, torso)
    c.stroke([(147, 196), (176, 200), (199, 196)], tone=4, restrict=torso)

    # ---- shirt collar, top button open, no neck. A collar hugs the base of the neck: about one and a
    # half neck widths across, its two leaves fold down beside the opening and end in points.
    clear = distance_transform_edt(~hmask) <= GAP
    back = c.poly([(166, 107.5), (171, 104.5), (181, 104.5), (186, 107.5), (184, 110), (168, 110)]) & ~clear
    lab, n = label(back)                                                        # drop slivers left beside the chin
    for k in range(1, n + 1):
        if (lab == k).sum() < 8:
            back &= lab != k
    c.part('collar_back', back, SHIRT, g, round_r=2)
    c.retone(back, tone=2)
    opening = c.poly([(168.5, 109), (184, 109), (176.5, 121)]) & ~clear & ~back
    c.part('chest', opening, SKIN, g, round_r=('ellip', 175, 112, 9, 8), amb=-0.02, max_tone=3)
    c.retone(opening & (shifted(back | clear, 0, -1)), tone=3)                  # shade under the collar
    flap_r = c.poly([(185.5, 107.5), (188, 108.5), (190, 114), (189, 122), (187, 123), (177.5, 119.5), (182.5, 112)]) & ~clear
    flap_l = c.poly([(167, 107.5), (164.5, 108.5), (162.5, 114), (163.5, 122), (165.5, 123), (175.5, 119.5), (170, 112)]) & ~clear
    c.part('flap_r', flap_r, SHIRT, g, round_r=3, amb=0.04, cast=2)
    c.part('flap_l', flap_l, SHIRT, g, round_r=3, amb=0.20, cast=2)
    c.retone(flap_l & c.line([(166, 109), (170.5, 113), (174.5, 119)]), tone=0)    # lit roll along the opening
    c.retone(flap_r & c.line([(186.5, 109), (182, 113), (178.5, 119)]), tone=1)
    c.retone(flap_l & c.line([(164.5, 121), (166, 122)]), delta=1)                  # points a step darker
    c.retone(flap_r & c.line([(188, 121), (187, 122)]), delta=1)
    collar = back | opening | flap_l | flap_r

    # ---- today's newspaper held out to the side, gripped at its lower-left edge (fingers in front)
    th = math.radians(7)
    U, V = (math.cos(th), -math.sin(th)), (math.sin(th), math.cos(th))
    T0, PW, PH = (74, 62), 48, 62
    FV = PH - 14                     # v of the top finger

    def P(u, v):
        return (T0[0] + u * U[0] + v * V[0], T0[1] + u * U[1] + v * V[1])

    du = (c.xx - T0[0]) * U[0] + (c.yy - T0[1]) * U[1]
    dv = (c.xx - T0[0]) * V[0] + (c.yy - T0[1]) * V[1]

    def R(u0, v0, u1, v1):
        return (du >= u0) & (du <= u1) & (dv >= v0) & (dv <= v1)

    # arm behind the paper: from the shoulder down-left to the elbow, forearm up-left to the fist
    SH, EL, WR = (147, 117), (120, 130), P(9, FV + 13)
    c.part('uarm_l', c.capsule(SH, EL, 7.4, 6.8), SKIN, g, round_r=('tube', [SH, EL], [7.4, 6.8]))
    c.part('farm_l', c.capsule(EL, WR, 6.4, 5.4), SKIN, g, cast=1, round_r=('tube', [EL, WR], [6.4, 5.4]))
    c.part('news_back', R(2, 1.5, PW + 2, PH + 1.5), PAPER2, g, flat=2, cast=1)
    paper = R(0, 0, PW, PH)
    c.part('news', paper, PAPER, g, round_r=6, amb=0.04, cast=1)
    c.retone(R(PW - 2, 0, PW, PH) & paper, delta=1)
    c.part('mast', R(3, 3, PW - 3, 13), NAVY, g, flat=2, outline=False)
    font = {'K': ['1001', '1010', '1100', '1100', '1010', '1001'],
            'O': ['0110', '1001', '1001', '1001', '1001', '0110'],
            'R': ['1110', '1001', '1001', '1110', '1010', '1001'],
            'A': ['0110', '1001', '1001', '1111', '1001', '1001'],
            'N': ['1001', '1101', '1101', '1011', '1011', '1001']}
    for i, ch in enumerate('KORAN'):
        ox, oy = P(12 + 5 * i, 5.2)
        ox, oy = int(round(ox)), int(round(oy))
        for r_, row in enumerate(font[ch]):
            c.px([(ox + k, oy + r_) for k, b in enumerate(row) if b == '1'], PAPER[0])
    c.paint(R(3, 16, 29, 18.4) & paper, INK)                     # headline
    c.paint(R(32, 16, PW - 3, 18.4) & paper, INK)
    c.paint(c.line([P(3, 21.5), P(PW - 3, 21.5)]) & paper, mix(INK, PAPER[1], 0.45))
    TXT = mix(INK, PAPER[1], 0.5)
    rng = np.random.RandomState(7)
    for col0, col1, v0, v1 in ((3, 23, 24, PH - 3), (27, PW - 3, 24, 33)):
        for v in range(v0, v1, 2):
            u = col0
            while u < col1:
                ln = rng.randint(3, 8)
                c.paint(c.line([P(u, v), P(min(u + ln, col1), v)]) & paper, TXT)
                u += ln + 2
    c.paint(c.line([P(25, 23.5), P(25, PH - 3)]) & paper, PAPER[2])
    photo = R(27, 35, PW - 3, PH - 3) & paper
    c.paint(photo, '#4A4758')
    c.paint(R(27, PH - 8, PW - 3, PH - 3) & photo, '#6A6676')
    c.paint(R(27, 35, PW - 3, 41) & photo, '#5E5A6B')                 # lighter sky
    hx, hy = P(36, 44)
    c.paint((c.disc(hx, hy, 2.6) | c.ellipse(hx + 0.6, hy + 9, 6.2, 4.2)) & photo, '#A09DAA')   # portrait
    c.paint(c.disc(hx - 0.8, hy - 0.8, 1.0) & photo, '#C9C6D1')

    # fist: back of the hand, four fingers stacked over the paper edge, thumb on top pointing up-right
    bx, by = P(6.5, FV + 6.5)
    c.part('fist', c.ellipse(bx, by, 6.4, 8.2, rot=-7), SKIN, g, round_r=('ellip', bx - 1, by - 2, 7, 9), amb=0.06, max_tone=3)
    for k in (3, 2, 1, 0):
        v = FV + 3.4 * k
        a, b = P(1.2, v), P(10.2, v + 0.4)
        c.part(f'finger{k}', c.capsule(a, b, 1.95), SKIN, g, round_r=('tube', [a, b], [1.95, 1.95]),
               amb=0.08 - 0.05 * k, max_tone=3, cast=1)
    tp = [P(2.4, FV - 1.0), P(6.6, FV - 3.4), P(10.0, FV - 1.2)]
    c.part('thumb_l', c.chain(tp, [2.4, 2.2, 1.9]), SKIN, g, round_r=('tube', tp, [2.4, 2.2, 1.9]), amb=0.08, max_tone=3, cast=1)
    c.part('sleeve_l', c.capsule((149, 115), (137, 121), 9.6, 8.8), SHIRT, g, cast=2,
           no_line_against=[c.parts['torso'], c.parts['collar_back'], c.parts['flap_l']])
    c.stroke([(140, 112), (136, 128)], tone=3, restrict=c.parts['sleeve_l'])


def head(c):
    g = 'ch'
    # ---- head
    c.part('brim', c.poly([(127, 72), (132, 67), (154, 63), (156, 72), (134, 78), (127, 76)]), NAVY, g, round_r=3)
    # back of the head (hair) on the viewer's left: the face contour ends at the ear, not behind it
    back = c.poly([(150, 64), (162, 60), (163, 80), (162, 85), (158, 87), (154, 85), (151, 79), (150, 72)])
    c.part('backhair', back, HAIR, g, round_r=6)
    for pts in ([(153, 68), (152, 78)], [(157, 66), (156, 76)]):
        c.stroke(pts, tone=1, restrict=back)
    face = c.poly([(160, 60), (161, 70), (161, 80), (161, 88), (162, 92), (165, 95.5), (169, 98.5), (173, 100.5),
                   (177, 101.5), (181, 101), (185, 99), (189, 95.5), (192, 91), (194, 85), (195.5, 79), (196, 73),
                   (195.5, 66), (194, 60), (190, 55), (182, 52), (170, 52), (163, 55)])
    c.part('head', face, SKIN, g, round_r=('ellip', 178, 80, 24, 28), amb=0.12, max_tone=3, cast=3, cast_tones=1)
    edge_y = 66 + 0.011 * (c.xx - 173) ** 2
    side = face & (c.xx <= 164.5 - (c.yy - 66) * 0.18) & (c.yy <= 80)
    side |= face & (c.xx >= 193) & (c.yy <= 73)
    c.part('hair', side, HAIR, g, round_r=3, outline=False)
    # ear sits where the jaw line ends; no dark ring around it
    ear = c.ellipse(157.5, 83, 4.4, 6.6) | c.ellipse(159, 89.5, 2.4, 2.4)
    c.part('ear', ear, SKIN, g, round_r=('ellip', 156, 82, 6, 8), amb=0.1, outline=False, max_tone=3)
    # ear: mid tone body, lit rim on the upper-left, C-shaped inner fold, darker where it meets the cheek
    from scipy.ndimage import binary_erosion
    c.retone(ear, tone=2)
    rim = ear & ~binary_erosion(ear) & (c.xx <= 158.5)
    c.retone(rim, tone=1)
    c.stroke([(158, 79), (156.5, 81), (156.5, 85), (158, 87)], tone=3, restrict=ear)
    c.stroke([(159, 82), (159, 84)], tone=4, restrict=ear)
    c.stroke([(161, 79), (162, 84), (161, 90)], tone=3, restrict=ear)
    # cap
    dome = c.ellipse(172.6, 67, 24.8, 20.4)
    below = c.yy > (66 + 0.011 * (c.xx - 173) ** 2)
    crown = dome & ~below
    c.part('cap', crown, CAP, g, round_r=14)
    bandm = crown & (c.yy > (61 + 0.011 * (c.xx - 173) ** 2))
    c.part('band', bandm, NAVY, g, round_r=3, outline=False, cast=2)
    c.stroke([(176, 47), (176, 56)], tone=3, restrict=crown)
    c.stroke([(161, 50), (155, 60)], tone=3, restrict=crown)
    c.stroke([(190, 50), (195, 58)], tone=3, restrict=crown)
    c.part('capbtn', c.disc(173, 46.5, 2.3), CAP, g, round_r=2)
    hole = c.ellipse(177, 67, 7.4, 13) & ~below & (c.yy >= 54)
    c.part('tuft', hole, HAIR, g, round_r=4)
    for pts in ([(174, 57), (176, 62), (175, 66)], [(178, 56), (180, 62)], [(181, 59), (182, 64)]):
        c.stroke(pts, tone=1, restrict=hole)
    c.part('strap', c.rect(169, 63, 185, 66) & ~below, NAVY, g, round_r=2, outline=False)
    c.px([(176, 64), (177, 64), (176, 65), (177, 65)], METAL[1])

    # ---- face
    DARK = hexc('#2A1819')
    IRIS = hexc('#4A2D24')
    # features placed for a ~30 degree turn: near eye left of centre, far eye close to the far cheek
    for ex, wdt in ((172, 4), (189, 3)):
        c.px([(x, 75) for x in range(ex, ex + wdt)], DARK)                               # upper lid
        for yy in range(76, 83):
            c.px([(x, yy) for x in range(ex, ex + wdt)], IRIS)
        c.px([(ex, 76), (ex + 1, 76), (ex, 77), (ex + 1, 77)], '#FFFFFF')
        c.px([(x, 82) for x in range(ex + 1, ex + wdt)], hexc('#9C6B4C'))
        c.px([(ex + wdt - 1, 79)], hexc('#FFFFFF'))
    c.px([(x, 70) for x in range(170, 177)] + [(x, 69) for x in range(172, 176)], HAIR[2])     # brows
    c.px([(x, 69) for x in range(187, 193)] + [(193, 70)], HAIR[2])
    c.px([(185, 85)], SKIN[1])                                                        # nose
    c.px([(187, 82), (187, 83), (188, 84), (188, 85), (188, 86), (187, 87)], SKIN[3])
    c.px([(184, 89), (185, 89)], SKIN[4])
    c.px([(178, 91), (189, 91)] + [(x, 92) for x in range(179, 189)], '#7E3929')                 # smile
    c.px([(x, 93) for x in range(180, 188)], '#FFFFFF')
    c.px([(179, 93), (188, 93)] + [(x, 94) for x in range(180, 188)], '#9C3F33')
    c.px([(x, 95) for x in range(182, 186)], '#C47A5E')
    c.px([(168, 87), (169, 87), (170, 87), (192, 87), (193, 87)], '#F09C80')

HEAD_DY, GAP = 6, 2


def render(pants, head_dy=None, gap=None, layers=False):
    """Head is drawn on its own layer and placed HEAD_DY px lower, floating GAP px above the collar."""
    global GAP
    dy = HEAD_DY if head_dy is None else head_dy
    if gap is not None:
        GAP = gap
    hc = Canvas(W, H)
    head(hc)
    hc.bounce('ch')
    himg = np.array(hc.image())
    hlayer = np.zeros_like(himg)
    hlayer[dy:] = himg[:H - dy]
    c = Canvas(W, H)
    bike(c)
    character(c, pants, hlayer[..., 3] > 0)
    c.bounce('ch')
    body = c.image()
    head_im = Image.fromarray(hlayer, 'RGBA')
    if layers:
        return body, head_im
    out = body.copy()
    out.alpha_composite(head_im)
    return out


CROP = (34, 47, 294, 283)   # x, y, w, h of the published image


if __name__ == '__main__':
    import argparse
    ap = argparse.ArgumentParser(description='Render gambar full body skala besar (pemain + sepeda).')
    ap.add_argument('--out', default='build/loper_art/fullbody')
    ap.add_argument('--pants', default='jogger', choices=['jogger', '3/4'], help='jogger = desain terpilih (2026-10-07)')
    ap.add_argument('--layers', action='store_true', help='juga simpan layer kepala dan badan terpisah')
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)
    x0, y0, w, h = CROP
    box = (x0, y0, x0 + w, y0 + h)
    name = 'loper_agen_fullbody' + ('' if args.pants == 'jogger' else '_34')
    body_im, head_im = render(args.pants, layers=True)
    im = body_im.copy()
    im.alpha_composite(head_im)
    im = im.crop(box)
    im.save(f'{args.out}/{name}.png')
    im.resize((w * 3, h * 3), Image.NEAREST).save(f'{args.out}/{name}_x3.png')
    if args.layers:
        body_im.crop(box).save(f'{args.out}/{name}_body.png')
        head_im.crop(box).save(f'{args.out}/{name}_head.png')
    print(f'{name}: {w}x{h} -> {args.out}')
