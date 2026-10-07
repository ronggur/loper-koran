"""Arsip: gambar full body versi pertama (2026-10-07), 3 nada per warna, sebelum versi detail lima nada.

Digantikan oleh tools/loper_art/fullbody/fullbody.py. Disimpan supaya papan "Full body" di kanvas bisa dirender ulang.

    python3 tools/loper_art/fullbody/arsip/fullbody_v1.py build/loper_art/arsip
"""
import math
import sys
import numpy as np
from PIL import Image
from px2d import Canvas, mat, flat, hexc, OUT, shifted

W, H, G = 184, 168, 158

SKIN = mat('#F2B98C', '#E8A07A', '#B47C5F')
HAIR = mat('#8A5A40', '#6D4334', '#4A2319')
CAP = mat('#FFFFFF', '#F2E7C9', '#C2AF86')
NAVY = mat('#7480A3', '#5C6A8C', '#404A62')
SHIRT = mat('#9BC4D8', '#5F96C8', '#466E8C')
SHOE = mat('#5F5B66', '#3D4649', '#221E26')
SOLE = mat('#FFFFFF', '#F2E7C9', '#C2AF86')
FRAME = mat('#62A046', '#466E50', '#314D38')
TIRE = mat('#3D4649', '#2A1E17', '#2A1E17')
METAL = mat('#C4C0C8', '#969AA0', '#67636D')
DMETAL = mat('#5F5B66', '#3D4649', '#221E26')
SADDLE = mat('#6D4334', '#553428', '#3B2219')
PANNIER = mat('#B5523B', '#994532', '#673F31')
PANNIER_FAR = mat('#994532', '#673F31', '#4A2319')
STRAP = mat('#3B2219', '#2A1E17', '#2A1E17')
BASKET = mat('#B47C5F', '#96643C', '#673F31')
PAPER = mat('#FBF6E8', '#F2E7C9', '#C2AF86')
PAPER2 = mat('#FFFFFF', '#D8D4DC', '#A9A2AE')
BADGE = mat('#FFE08A', '#FFC94A', '#E98E3F')

RA, FA, R = (46, 131), (134, 131), 27
BB = (84, 136)
SC = (72, 97)


def bike(c):
    # ---- ground shadow under the bike
    c.add_shadow(c.ellipse(90, G + 0.5, 66, 3.2))

    # ---- far side: pannier, drivetrain
    c.part('pannier_far', c.poly([(34, 99), (62, 99), (63, 120), (36, 121)]), PANNIER_FAR, group='bike', lw=0, dw=2)
    c.part('chainring', c.ring(BB[0], BB[1], 7.5, 4.5), DMETAL, group='bike', lw=1, dw=1)
    c.part('cog', c.disc(RA[0], RA[1], 3.6), DMETAL, group='bike', lw=1, dw=1)
    chain = c.polyline_mask([(BB[0], BB[1] - 7), (RA[0], RA[1] - 3)]) | c.polyline_mask([(BB[0], BB[1] + 7), (RA[0], RA[1] + 3)])
    c.paint(chain, '#3D4649')
    c.part('crank_far', c.capsule(BB, (76, 147), 1.3), DMETAL, group='bike', lw=0, dw=1)
    c.part('pedal_far', c.rect(71, 146, 80, 148), DMETAL, group='bike', lw=0, dw=1)

    # ---- wheels
    for name, (cx, cy) in (('rear', RA), ('front', FA)):
        c.part(f'tire_{name}', c.ring(cx, cy, R, R - 3.6), TIRE, group='bike', lw=2, dw=1,
               light_dirs=((-1, -1),), dark_dirs=((1, 1),))
        c.part(f'rim_{name}', c.ring(cx, cy, R - 3.6, R - 5.6), METAL, group='bike', lw=1, dw=1, outline=False)
        # spokes
        sp = np.zeros((H, W), bool)
        for i in range(16):
            a = math.radians(i * 22.5 + 6)
            p0 = (cx + 2.5 * math.cos(a), cy + 2.5 * math.sin(a))
            p1 = (cx + (R - 6) * math.cos(a + 0.18), cy + (R - 6) * math.sin(a + 0.18))
            sp |= c.line_mask(p0, p1)
        sp &= ~c.disc(cx, cy, 2.5)
        c.paint(sp & ~c.filled | sp & ~c.parts[f'rim_{name}'] & ~c.parts[f'tire_{name}'], '#7E7A86')
        c.part(f'hub_{name}', c.disc(cx, cy, 3.2), METAL, group='bike', lw=1, dw=1)
        c.px([(cx, cy)], '#3D4649')

    # ---- racks
    rack = c.capsule((36, 99), (70, 99), 0.9) | c.capsule((38, 99), (RA[0], RA[1]), 0.7) | c.capsule((60, 99), (RA[0] + 1, RA[1]), 0.7)
    c.part('rack', rack, METAL, group='bike', lw=0, dw=0, outline=True)

    # ---- frame
    tubes = [
        ('chainstay', BB, RA, 1.4, 1.1),
        ('seatstay', (SC[0] + 1, SC[1] + 2), RA, 1.3, 1.0),
        ('seattube', BB, SC, 2.0, 1.7),
        ('downtube', BB, (123, 101), 2.4, 2.0),
        ('toptube', (SC[0] + 1, SC[1]), (121, 95), 1.8, 1.7),
    ]
    for name, a, b, r0, r1 in tubes:
        c.part(name, c.capsule(a, b, r0, r1), FRAME, group='bike', lw=1, dw=1,
               light_dirs=((0, -1), (-1, 0)), dark_dirs=((0, 1), (1, 0)))
    c.part('headtube', c.capsule((121, 92), (124, 105), 2.4), FRAME, group='bike', lw=1, dw=1)
    c.part('fork', c.chain([(124, 105), (128, 118), (133, 130)], 1.8, 1.2), FRAME, group='bike', lw=1, dw=1)
    c.part('bb', c.disc(BB[0], BB[1], 3.2), DMETAL, group='bike', lw=1, dw=1)
    # seatpost + saddle
    c.part('seatpost', c.capsule(SC, (70, 90), 1.1), METAL, group='bike', lw=1, dw=0)
    c.part('saddle', c.poly([(60, 87), (64, 85), (72, 86), (80, 87), (80, 89), (72, 90), (63, 91), (60, 90)]),
           SADDLE, group='bike', lw=2, dw=2)

    # ---- near side crank, pedal, kickstand
    c.part('crank', c.capsule(BB, (92, 125), 1.4), METAL, group='bike', lw=1, dw=1)
    c.part('pedal', c.rect(88, 123, 97, 126), DMETAL, group='bike', lw=1, dw=1)
    c.part('kick', c.capsule((79, 139), (71, 156), 1.0), DMETAL, group='bike', lw=0, dw=1)

    # ---- near pannier + papers
    for i, (x0, top) in enumerate(((35, 91), (40, 89), (45, 92))):
        c.part(f'ppaper{i}', c.capsule((x0 + 2, top), (x0 + 2, 101), 2.4), PAPER if i != 1 else PAPER2,
               group='bike', lw=1, dw=1)
    body = c.poly([(31, 101), (59, 101), (60, 103), (60, 123), (58, 125), (33, 125), (31, 123)])
    c.part('pannier', body, PANNIER, group='bike', lw=2, dw=3)
    flap = c.poly([(30, 99), (60, 99), (61, 101), (61, 111), (58, 113), (33, 113), (30, 111)])
    c.part('flap', flap, PANNIER, group='bike', lw=2, dw=2, cast=1)
    c.part('strap', c.rect(44, 106, 46, 118), STRAP, group='bike', flat_tone=1, outline=False)
    c.part('buckle', c.rect(43, 114, 47, 116), METAL, group='bike', lw=1, dw=1, outline=True)
    c.tone_pix(c.rect(31, 120, 59, 120) & c.parts['pannier'], 2)

    # ---- handlebar, bell, headlamp
    c.part('stem', c.capsule((121, 93), (120, 87), 1.3), METAL, group='bike', lw=1, dw=1)
    bar = c.chain([(121, 87), (116, 85), (110, 86)], 1.1)
    c.part('bar', bar, METAL, group='bike', lw=1, dw=1)
    c.part('grip', c.capsule((105, 86), (111, 86), 1.6), DMETAL, group='bike', lw=1, dw=1)
    c.part('bell', c.ellipse(116.5, 82.5, 2.3, 2.0), mat('#FFE08A', '#FFC94A', '#D9A33A'), group='bike', lw=1, dw=1)

    # small headlamp instead of the front basket
    c.part('lamp', c.ellipse(126.5, 96, 3.0, 2.6), METAL, group='bike', lw=1, dw=1)
    c.part('lens', c.ellipse(128.3, 96, 1.6, 2.0), mat('#FFF7D6', '#FFE89A', '#E8C060'), group='bike', lw=1, dw=0)


def character(c):
    c.add_shadow(c.ellipse(87, G + 0.5, 22, 3.6))
    g = 'ch'

    # ---- far arm (viewer's right): hand on the grip
    c.part('uarm_r', c.capsule((97, 58), (103, 72), 3.7, 3.3), SKIN, group=g)
    c.part('farm_r', c.capsule((103, 72), (107, 83), 3.2, 2.7), SKIN, group=g, cast=1)
    c.part('hand_r', c.ellipse(108.5, 86, 3.4, 3.5), SKIN, group=g, cast=1)
    c.px([(107, 88), (109, 88)], SKIN[2])
    c.part('wrist', c.capsule((105, 80.5), (108.5, 79.5), 1.2) & c.parts['farm_r'], BADGE, group=g, lw=1, dw=1, outline=False)
    c.part('sleeve_r', c.capsule((97, 58), (101, 66), 4.8, 4.6), SHIRT, group=g, cast=1)
    c.tone_pix(c.line_mask((97, 69), (104, 66)) & c.parts['sleeve_r'], 2)

    # ---- jogger pants (long, navy) with gathered cuffs, then shoes
    legR = c.capsule((93, 102), (97, 124), 7.0, 5.8) | c.capsule((97, 124), (99, 142), 5.8, 4.2)
    legL = c.capsule((80, 102), (77, 124), 7.0, 5.8) | c.capsule((77, 124), (77, 143), 5.8, 4.2)
    pelvis = c.poly([(74, 95), (99, 95), (100, 104), (73, 104)])
    pants = legR | legL | pelvis
    c.part('pants', pants, NAVY, group=g, lw=2, dw=3, cast=1)
    c.tone_pix(c.line_mask((87, 106), (87, 99)), 2)
    for x0, y0 in ((74, 136), (95, 135)):
        c.tone_pix(c.line_mask((x0, y0), (x0 + 3, y0 + 1)) | c.line_mask((x0 + 3, y0 + 1), (x0 + 6, y0)), 2)  # stacking folds
    for nm, (x, y) in (('r', (99, 142)), ('l', (77, 143))):
        cuff = c.poly([(x - 3, y), (x + 3, y), (x + 3.5, y + 3), (x - 3.5, y + 3)])
        c.part(f'cuff_{nm}', cuff, NAVY, group=g, lw=1, dw=1, cast=1)
        c.tone_pix(cuff & ((c.xx.astype(int) % 2) == 0), 2)
    c.part('sole_r', c.poly([(95, 151), (110, 151), (110, 154), (108, 156), (95, 156)]), SOLE, group=g, lw=1, dw=1)
    c.part('shoe_r', c.poly([(95, 145), (101, 144), (106, 147), (109, 150), (109, 152), (95, 153)]), SHOE, group=g, lw=2, dw=1, cast=1)
    c.part('sole_l', c.poly([(67, 152), (82, 152), (83, 155), (82, 157), (68, 157), (66, 155)]), SOLE, group=g, lw=1, dw=1)
    c.part('shoe_l', c.poly([(73, 146), (81, 146), (82, 149), (82, 153), (67, 154), (67, 152), (70, 149)]), SHOE, group=g, lw=2, dw=1, cast=1)
    c.px([(76, 148), (78, 148), (77, 149), (99, 146), (101, 146), (100, 147)], '#F2E7C9')   # laces

    # ---- torso (shirt)
    torso = c.poly([(73, 55), (99, 55), (101, 60), (100, 70), (98, 82), (100, 97), (96, 99), (88, 100), (78, 99), (73, 97), (75, 82), (73, 70), (72, 60)])
    c.part('torso', torso, SHIRT, group=g, lw=2, dw=3, cast=2)
    # placket, buttons, pocket, badge, folds
    c.tone_pix(c.line_mask((88, 60), (89, 98)), 2)
    for yy in (65, 73, 81, 89):
        c.px([(90, yy)], '#FBF6E8')
    pocket = c.rect(91, 66, 96, 72)
    c.tone_pix(pocket & ~c.rect(92, 67, 95, 72), 2)
    c.part('badge', c.rect(92, 62, 96, 63), BADGE, group=g, lw=0, dw=0, outline=False)
    c.tone_pix(c.line_mask((78, 86), (80, 96)) | c.line_mask((96, 74), (95, 86)), 2)
    c.tone_pix(c.rect(73, 98, 100, 100) & torso, 2)

    # neck + collar
    c.part('neck', c.capsule((87, 47), (88, 56), 3.7), SKIN, group=g, lw=1, dw=2)
    c.tone_pix(c.rect(84, 50, 92, 52), 2)
    c.part('collar_l', c.poly([(80, 53), (86, 54), (88, 61), (83, 59)]), SHIRT, group=g, lw=2, dw=1, cast=1)
    c.part('collar_r', c.poly([(96, 53), (90, 54), (89, 61), (93, 59)]), SHIRT, group=g, lw=2, dw=1, cast=1)

    # ---- head (turned slightly to viewer's right)
    # brim behind the head, pointing back (viewer's left)
    c.part('brim', c.poly([(64, 36), (66, 34), (77, 32), (78, 36), (67, 39), (64, 38)]), NAVY, group=g, lw=1, dw=1,
           light_dirs=((0, -1),), dark_dirs=((0, 1),))
    skull = c.ellipse(86, 37, 11.4, 12)
    jaw = c.poly([(78, 40), (97, 40), (96, 45), (91, 50), (87, 50), (81, 46)])
    head = skull | jaw
    c.part('head', head, SKIN, group=g, lw=2, dw=3)
    # hair: back of the head on the viewer's left, sideburn on the far side
    edge = lambda x: 33 + 0.022 * (x - 86.5) ** 2
    hair = head & (c.xx <= 79) & (c.yy >= 30) & (c.yy <= 45)
    hair |= head & (c.xx >= 96) & (c.yy >= 32) & (c.yy <= 39)
    c.part('hair', hair, HAIR, group=g, lw=1, dw=2)
    c.part('ear', c.ellipse(78.5, 41.5, 2.4, 3.3), SKIN, group=g, lw=1, dw=1)
    c.px([(78, 41), (78, 42)], SKIN[2])
    # backwards cap: crown dome, navy band along the bottom edge, strap opening at the forehead
    dome = c.ellipse(86.3, 33.5, 12.4, 10.2)
    below = c.yy > (33 + 0.022 * (c.xx - 86.5) ** 2)
    crown = dome & ~below
    c.part('cap', crown, CAP, group=g, lw=2, dw=3)
    bandm = crown & (c.yy > (31 + 0.022 * (c.xx - 86.5) ** 2))
    c.part('band', bandm, NAVY, group=g, lw=1, dw=1, outline=False, cast=1, cast_dirs=((0, 1),))
    hole = c.ellipse(88, 33.5, 3.6, 6.4) & ~below & (c.yy >= 27)
    c.part('tuft', hole, HAIR, group=g, lw=1, dw=1)
    c.px([(87, 28), (87, 29), (89, 30), (88, 31)], HAIR[0])
    c.part('strap', c.rect(85, 32, 91, 33) & ~below, NAVY, group=g, lw=0, dw=0, outline=False)
    c.px([(88, 32)], METAL[0])
    # panel seams on the crown
    c.tone_pix(c.line_mask((88, 24), (88, 27)) | c.line_mask((80, 25), (78, 30)), 2)

    # face: eyes, brows, nose, smile, cheeks
    for ex in (83, 92):
        c.px([(ex, 39), (ex + 1, 39), (ex, 40), (ex + 1, 40), (ex, 41), (ex + 1, 41)], '#2A1E17')
        c.px([(ex, 39)], '#FFFFFF')
    c.px([(82, 37), (83, 36), (84, 36), (91, 36), (92, 36), (93, 37)], HAIR[2])
    c.px([(90, 43), (90, 44)], SKIN[2])
    c.px([(86, 46), (87, 47), (88, 47), (89, 47), (90, 47), (91, 46)], '#7E3929')
    c.px([(87, 46), (88, 46), (89, 46), (90, 46)], '#FFFFFF')

    # ---- near arm raised with folded newspaper
    paper = c.poly([(45, 10), (65, 12), (64, 34), (44, 32)])
    c.part('news', paper, PAPER, group=g, lw=1, dw=2)
    c.part('news_mast', c.poly([(46, 13), (63, 15), (63, 18), (46, 16)]), mat('#5C6A8C', '#404A62', '#2E3550'), group=g, flat_tone=1, outline=False)
    for yy in (20, 23, 26, 29):
        c.tone_pix(c.line_mask((47, yy), (55, yy + 1)), 2)
    c.part('news_photo', c.poly([(57, 20), (62, 21), (62, 28), (57, 27)]), mat('#A9A2AE', '#969AA0', '#67636D'), group=g, flat_tone=1, outline=False)
    c.part('uarm_l', c.capsule((74, 58), (62, 47), 3.8, 3.4), SKIN, group=g)
    c.part('farm_l', c.capsule((62, 47), (58.5, 35), 3.3, 2.8), SKIN, group=g)
    c.part('hand_l', c.ellipse(57.5, 31.5, 3.5, 3.7), SKIN, group=g)
    c.px([(56, 30), (57, 30)], SKIN[2])
    c.part('sleeve_l', c.capsule((75, 58), (68, 51), 5.0, 4.6), SHIRT, group=g, cast=1)
    c.tone_pix(c.line_mask((65, 52), (70, 46)) & c.parts['sleeve_l'], 2)


def render():
    c = Canvas(W, H)
    bike(c)
    character(c)
    return c.image()


if __name__ == '__main__':
    import os
    out = sys.argv[1] if len(sys.argv) > 1 else 'build/loper_art/arsip'
    os.makedirs(out, exist_ok=True)
    im = render()
    im.save(f'{out}/loper_agen_fullbody_v1.png')
    im.resize((W * 5, H * 5), Image.NEAREST).save(f'{out}/loper_agen_fullbody_v1_x5.png')
    print(f'loper_agen_fullbody_v1: {W}x{H} -> {out}')
