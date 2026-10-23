"""Komponen UI redesain (usulan 2026-10-23, kanvas Claude Design "UI Loper Koran — Redesain").

Merender semua aset gambar baru di kanvas sebagai PNG 1x: bingkai 9-slice tombol/panel/kartu/chip/struk
(versi gelap dan versi koran), tile isi, ikon 24x24, lencana 32x32, glif 12x12 satu warna, sepeda loper
tampak samping, papan alat bengkel, dan foto berita koran. Palet: token DESIGN_SPEC 1.1 + palet induk
ART_DIRECTION 2.4, tanpa anti-aliasing. Bentuk digambar sebagai mask (supersampling lalu ambang 50 %),
diberi tiga nada dengan cahaya dari kiri atas, lalu garis luar 1 px #0E0A1C.

Belum ada yang disalin ke assets/: porting ke Godot dikerjakan bertahap (docs/design/redesain/README.md).

Menjalankan (dari root repo, butuh pillow):
    python3 tools/ui_art/redesain/komponen.py                 # tulis ke build/ui_art/redesain/
    python3 tools/ui_art/redesain/komponen.py --mock          # juga salin ke docs/design/redesain/aset/ + lembar pratinjau
"""
import argparse
import json
import math
import shutil
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[3]
_ap = argparse.ArgumentParser(description='Komponen UI redesain (usulan)')
_ap.add_argument('--out', default=str(ROOT / 'build' / 'ui_art' / 'redesain'))
_ap.add_argument('--mock', action='store_true', help='salin hasil ke docs/design/redesain/aset/ dan tulis lembar pratinjau')
ARGS = _ap.parse_args()
OUT = Path(ARGS.out)
OUT.mkdir(parents=True, exist_ok=True)
MOCK = ROOT / 'docs' / 'design' / 'redesain' / 'aset'


def hx(h, a=255):
    h = h.lstrip('#')
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


T = {k: hx(v) for k, v in dict(
    UI_BG='#1C130F', UI_PANEL='#2A1E17', UI_PANEL_RAISED='#36281E', OUTLINE='#0E0A1C',
    TEXT='#FFF3E3', TEXT_2='#CDB9A3', ACCENT='#FFB22E', OK='#56C46E', FAIL='#D94F3D', WARN='#FF8A3D',
    KORAN_KERTAS='#F2E7C9', KORAN_KERTAS_2='#E6D8B1', KORAN_TINTA='#1C130F', KORAN_TINTA_2='#4A3A2C',
    KORAN_GARIS='#7A6642').items()}
O = T['OUTLINE']
KREM = [hx('#FBF6E8'), hx('#F2E7C9'), hx('#C2AF86')]
KAYU = [hx('#B47C5F'), hx('#96643C'), hx('#553428')]
LOGAM = [hx('#C4C0C8'), hx('#969AA0'), hx('#67636D')]
LOGAM_G = [hx('#5F5B66'), hx('#3D4649'), hx('#221E26')]
HANGAT = [hx('#FFE08A'), hx('#FFC94A'), hx('#E98E3F')]
BATA = [hx('#B5523B'), hx('#994532'), hx('#673F31')]
HIJAU = [hx('#6FAE4F'), hx('#466E50'), hx('#314D38')]
BIRU = [hx('#9BC4D8'), hx('#5F96C8'), hx('#466E8C')]
PINK = hx('#F0C8CD')
META = {}


# ------------------------------------------------------------------ alat gambar
class Kanvas:
    def __init__(s, w, h):
        s.w, s.h = w, h
        s.px = {}
        s.solid = set()

    def mask(s, fn, ss=8):
        im = Image.new('L', (s.w * ss, s.h * ss), 0)
        d = ImageDraw.Draw(im)
        fn(d, ss)
        im = im.resize((s.w, s.h), Image.BOX)
        return {(x, y) for y in range(s.h) for x in range(s.w) if im.getpixel((x, y)) >= 128}

    def part(s, m, tones, outline=True, flat=False):
        L, M, D = tones if len(tones) == 3 else (tones[0],) * 3
        for (x, y) in m:
            if flat:
                c = M
            elif (x - 1, y) not in m or (x, y - 1) not in m:
                c = L
            elif (x + 1, y) not in m or (x, y + 1) not in m:
                c = D
            else:
                c = M
            s.px[(x, y)] = c
        if outline:
            s.solid |= m
        else:
            s.solid -= m

    def put(s, x, y, c):
        s.px[(x, y)] = c

    def outline(s):
        add = []
        for y in range(s.h):
            for x in range(s.w):
                if (x, y) in s.solid:
                    continue
                if any((x + a, y + b) in s.solid for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                    add.append((x, y))
        for p in add:
            s.px[p] = O

    def image(s):
        im = Image.new('RGBA', (s.w, s.h), (0, 0, 0, 0))
        for (x, y), c in s.px.items():
            if 0 <= x < s.w and 0 <= y < s.h:
                im.putpixel((x, y), c)
        return im


def L(d, ss, pts, w):
    d.line([(x * ss, y * ss) for x, y in pts], fill=255, width=max(1, int(w * ss)), joint='curve')
    for x, y in (pts[0], pts[-1]):
        r = w * ss / 2
        d.ellipse([x * ss - r, y * ss - r, x * ss + r, y * ss + r], fill=255)


def C(d, ss, cx, cy, r):
    d.ellipse([(cx - r) * ss, (cy - r) * ss, (cx + r) * ss, (cy + r) * ss], fill=255)


def P(d, ss, pts):
    d.polygon([(x * ss, y * ss) for x, y in pts], fill=255)


def R(d, ss, x0, y0, x1, y1, rad=0):
    d.rounded_rectangle([x0 * ss, y0 * ss, x1 * ss, y1 * ss], radius=rad * ss, fill=255)


def annulus(k, cx, cy, r0, r1):
    a = k.mask(lambda d, ss: C(d, ss, cx, cy, r1))
    b = k.mask(lambda d, ss: C(d, ss, cx, cy, r0))
    return a - b


def star_pts(cx, cy, ro, ri, rot=-90):
    pts = []
    for i in range(10):
        r = ro if i % 2 == 0 else ri
        a = math.radians(rot + i * 36)
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


# ------------------------------------------------------------------ ikon 24
def ikon_koin(n=24):
    k = Kanvas(n, n); c = n / 2
    k.part(k.mask(lambda d, ss: C(d, ss, c, c, n / 2 - 1.5)), HANGAT)
    ring = annulus(k, c, c, n * 0.24, n * 0.32)
    for (x, y) in ring:
        k.put(x, y, HANGAT[2] if (x - c) + (y - c) > 0 else HANGAT[0])
    k.outline()
    for p in ((7, 5), (6, 6), (5, 7)):
        k.put(*p, KREM[0])
    return k.image()


def ikon_bintang(n=24, tones=HANGAT):
    k = Kanvas(n, n)
    m = k.mask(lambda d, ss: P(d, ss, star_pts(n / 2, n / 2 + 1, n / 2 - 1.2, n * 0.2)))
    k.part(m, tones)
    for (x, y) in m:  # sisi kanan bintang lebih gelap (cahaya kiri atas)
        if x >= n / 2 and k.px[(x, y)] == tones[1]:
            k.put(x, y, tones[2])
        if x < n / 2 and k.px[(x, y)] == tones[1] and y < n / 2 + 2:
            k.put(x, y, tones[0])
    k.outline()
    return k.image()


def ikon_ban(n=24):
    k = Kanvas(n, n); c = n / 2
    k.part(annulus(k, c, c, n * 0.30, n / 2 - 1.2), LOGAM_G)
    k.part(annulus(k, c, c, n * 0.22, n * 0.30), LOGAM)
    k.outline()
    for i in range(8):  # jari-jari
        a = math.radians(i * 45 + 22)
        for t in range(2, int(n * 0.22)):
            k.put(int(round(c - .5 + t * math.cos(a))), int(round(c - .5 + t * math.sin(a))), LOGAM[2])
    hub = k.mask(lambda d, ss: C(d, ss, c, c, 2.2))
    k.part(hub, LOGAM, outline=False)
    for i in range(12):  # kembang ban
        a = math.radians(i * 30)
        k.put(int(c - .5 + (n / 2 - 2.2) * math.cos(a)), int(c - .5 + (n / 2 - 2.2) * math.sin(a)), LOGAM_G[2])
    return k.image()


def ikon_rem(n=24):
    k = Kanvas(n, n)
    k.part(k.mask(lambda d, ss: L(d, ss, [(2, 9), (14, 9)], 3.2)), LOGAM)          # setang
    k.part(k.mask(lambda d, ss: R(d, ss, 13.5, 6.8, 22, 11.4, 1.5)), LOGAM_G)       # pegangan karet
    k.part(k.mask(lambda d, ss: R(d, ss, 8, 5, 12, 13.5, 1)), LOGAM)                 # klem
    k.part(k.mask(lambda d, ss: P(d, ss, [(10.5, 12.5), (12.5, 12.5), (21.5, 16.2), (22, 18.6), (20.4, 19), (11, 15.5)])), LOGAM)  # tuas
    k.outline()
    for t in range(9):  # kabel
        k.put(9 - t // 2 - (1 if t > 5 else 0), 14 + t, LOGAM_G[1])
    return k.image()


def ikon_rantai(n=24):
    k = Kanvas(n, n)
    ringA = k.mask(lambda d, ss: d.rounded_rectangle([1.5 * ss, 4 * ss, 14.5 * ss, 13.5 * ss], radius=4.5 * ss, outline=255, width=int(2.8 * ss)))
    ringB = k.mask(lambda d, ss: d.rounded_rectangle([9.5 * ss, 10.5 * ss, 22.5 * ss, 20 * ss], radius=4.5 * ss, outline=255, width=int(2.8 * ss)))
    k.part(ringB, LOGAM)
    k.part(ringA, LOGAM)
    over = {p for p in ringB if p[1] >= 12 and p[0] >= 10 and p[0] <= 12}  # B lewat di atas A di sisi kiri bawah
    k.part(over, LOGAM)
    k.outline()
    for p in ringA & ringB:
        if p[0] > 12:
            k.put(*p, LOGAM[0])
    return k.image()


def ikon_kucing(n=24):
    k = Kanvas(n, n)
    JAHE = [HANGAT[1], HANGAT[2], BATA[0]]
    m = k.mask(lambda d, ss: (d.ellipse([3 * ss, 7 * ss, 21 * ss, 21.5 * ss], fill=255),
                              P(d, ss, [(3.5, 1.5), (10, 8), (3, 12)]), P(d, ss, [(20.5, 1.5), (14, 8), (21, 12)])))
    k.part(m, JAHE)
    k.part(k.mask(lambda d, ss: d.ellipse([7.5 * ss, 13.5 * ss, 16.5 * ss, 20.5 * ss], fill=255)), [KREM[0], KREM[0], KREM[2]], outline=True)
    k.outline()
    for p in ((5, 5), (5, 6), (6, 7), (18, 5), (18, 6), (17, 7)):
        k.put(*p, PINK)
    for x, y in ((8, 11), (9, 11), (8, 12), (9, 12), (14, 11), (15, 11), (14, 12), (15, 12)):
        k.put(x, y, O)
    k.put(11, 15, PINK); k.put(12, 15, PINK); k.put(11, 16, O); k.put(12, 16, O)
    for x in (10, 11, 12, 13):
        k.put(x, 8, BATA[0])
    k.put(11, 9, BATA[0]); k.put(12, 9, BATA[0])
    return k.image()


def ikon_kerucut(n=24):
    k = Kanvas(n, n)
    k.part(k.mask(lambda d, ss: P(d, ss, [(10.5, 2), (13.5, 2), (18, 19), (6, 19)])), [HANGAT[2], BATA[0], BATA[1]])
    k.part(k.mask(lambda d, ss: R(d, ss, 3, 18.5, 21, 21.5, 0.5)), [BATA[0], BATA[1], BATA[2]])
    k.outline()
    for y, (x0, x1) in ((8, (9, 15)), (9, (9, 15)), (13, (8, 16)), (14, (8, 16))):
        for x in range(x0, x1):
            if (x, y) in k.px and k.px[(x, y)] != O:
                k.put(x, y, KREM[0] if x < 12 else KREM[1])
    return k.image()


def ikon_bohlam(n=24):
    k = Kanvas(n, n)
    k.part(k.mask(lambda d, ss: (C(d, ss, 12, 9.5, 7.5), P(d, ss, [(8, 12), (16, 12), (14.5, 17), (9.5, 17)]))), [LOGAM[0], hx('#C4C0C8'), LOGAM[2]])
    k.part(k.mask(lambda d, ss: R(d, ss, 9, 16.5, 15, 21.5, 1)), LOGAM_G)
    k.outline()
    for p in ((10, 9), (11, 10), (12, 11), (13, 10), (14, 9)):  # filamen putus
        k.put(*p, LOGAM_G[1])
    k.put(12, 12, LOGAM_G[1]); k.put(9, 5, KREM[0]); k.put(8, 6, KREM[0])
    for y in (18, 20):
        for x in range(9, 15):
            k.put(x, y, LOGAM_G[2])
    return k.image()


def lencana(n, metal, tingkat):
    k = Kanvas(n, n); s = n / 24
    pita = [BIRU[1], BIRU[1], BIRU[2]]
    k.part(k.mask(lambda d, ss: P(d, ss, [(5 * s, 0), (11 * s, 0), (13 * s, 10 * s), (8 * s, 11 * s)])), pita)
    k.part(k.mask(lambda d, ss: P(d, ss, [(13 * s, 0), (19 * s, 0), (16 * s, 11 * s), (11 * s, 10 * s)])), [BIRU[0], BIRU[0], BIRU[2]])
    k.part(k.mask(lambda d, ss: C(d, ss, 12 * s, 15 * s, 8.6 * s)), metal)
    k.part(k.mask(lambda d, ss: P(d, ss, star_pts(12 * s, 15.4 * s, 4.6 * s, 2 * s))), [metal[2], metal[2], metal[2]], outline=False)
    k.outline()
    for i in range(tingkat):  # titik tingkat di pita: 1/2/3, terbaca tanpa warna
        x = int(round((12 - (tingkat - 1) * 1.6 + i * 3.2) * s))
        y = int(3 * s)
        k.put(x - 1 if n > 24 else x, y, T['TEXT'])
        if n > 24:
            k.put(x, y, T['TEXT']); k.put(x - 1, y + 1, T['TEXT']); k.put(x, y + 1, T['TEXT'])
    return k.image()


def lencana_kunci(n):
    """Belum didapat: siluet berongga, garis TEXT_2 putus-putus."""
    k = Kanvas(n, n); s = n / 24
    m = k.mask(lambda d, ss: C(d, ss, 12 * s, 15 * s, 8.6 * s)) | k.mask(lambda d, ss: P(d, ss, [(5 * s, 0), (19 * s, 0), (15 * s, 10 * s), (9 * s, 10 * s)]))
    for (x, y) in m:
        edge = any((x + a, y + b) not in m for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1)))
        if edge and (x + y) % 2 == 0:
            k.put(x, y, T['TEXT_2'])
    return k.image()


PERUNGGU = KAYU
PERAK = LOGAM
EMAS = HANGAT


# ------------------------------------------------------------------ glif 12 (satu warna)
GLIF = {
    'panah': ["............", "............", "......#.....", "......##....", "......###...", ".#########..",
              ".#########..", "......###...", "......##....", "......#.....", "............", "............"],
    'centang': ["............", "............", "..........#.", ".........##.", "........##..", ".#.....##...",
                ".##...##....", "..##.##.....", "...###......", "....#.......", "............", "............"],
    'lanjut': ["............", "...#........", "...##.......", "...###......", "...####.....", "...#####....",
               "...#####....", "...####.....", "...###......", "...##.......", "...#........", "............"],
    'seru': ["............", ".....##.....", ".....##.....", ".....##.....", ".....##.....", ".....##.....",
             ".....##.....", "............", ".....##.....", ".....##.....", "............", "............"],
    'naik': ["............", "............", "............", ".....##.....", "....####....", "...######...",
             "..########..", ".##########.", "............", "............", "............", "............"],
    'turun': ["............", "............", "............", "............", ".##########.", "..########..",
              "...######...", "....####....", ".....##.....", "............", "............", "............"],
    'jeda': ["............", "............", "...##..##...", "...##..##...", "...##..##...", "...##..##...",
             "...##..##...", "...##..##...", "...##..##...", "...##..##...", "............", "............"],
    'silang': ["............", "............", "..#......#..", "..##....##..", "...##..##...", "....####....",
               ".....##.....", "....####....", "...##..##...", "..##....##..", "..#......#..", "............"],
}


def glif_kunci():
    k = Kanvas(12, 12)
    m = k.mask(lambda d, ss: (C(d, ss, 8.4, 3.6, 3.3), L(d, ss, [(7.6, 4.4), (2.2, 9.8)], 2.6)))
    m -= k.mask(lambda d, ss: (C(d, ss, 10.3, 1.7, 1.9), P(d, ss, [(8.4, 3.6), (10, 0), (12, 2)])))
    return ["".join('#' if (x, y) in m else '.' for x in range(12)) for y in range(12)]


GLIF['kunci'] = glif_kunci()
GLIF_WARNA = [('gelap', T['UI_BG']), ('terang', T['TEXT']), ('teks2', T['TEXT_2']), ('ok', T['OK']),
              ('warn', T['WARN']), ('aksen', T['ACCENT']), ('tinta2', T['KORAN_TINTA_2'])]


# ------------------------------------------------------------------ 9-slice
def stepped_mask(w, h, corner=3, top=0):
    """Persegi dengan sudut tumpul bertingkat (profil 3 px seperti panel HUD)."""
    prof = {3: [3, 1, 1], 2: [2, 1], 1: [1], 0: []}[corner]
    m = set()
    for y in range(top, h):
        yy = y - top
        hh = h - top
        inset = 0
        if yy < len(prof):
            inset = prof[yy]
        elif hh - 1 - yy < len(prof):
            inset = prof[hh - 1 - yy]
        for x in range(inset, w - inset):
            m.add((x, y))
    return m


def ring_layers(m):
    """Lapisan dari luar ke dalam (erosi 4-tetangga)."""
    layers = []
    cur = set(m)
    while cur:
        edge = {p for p in cur if any((p[0] + a, p[1] + b) not in cur for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1)))}
        layers.append(edge)
        cur -= edge
    return layers


def nine(name, w, h, rings, fill, corner=3, lip=0, lipc=None, pressed=False, slices=None, note=''):
    """rings: daftar warna dari luar ke dalam; tiap item satu warna atau (atas, samping, bawah)."""
    top = lip if pressed else 0
    face_h = h - lip if not pressed else h
    m = stepped_mask(w, face_h if not pressed else h, corner, top)
    im = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    layers = ring_layers(m)
    ys = [p[1] for p in m]
    y0, y1 = min(ys), max(ys)
    for i, layer in enumerate(layers):
        if i < len(rings):
            col = rings[i]
            for (x, y) in layer:
                if isinstance(col, tuple) and len(col) == 3 and isinstance(col[0], tuple):
                    c = col[0] if y - y0 <= i + 1 and (y - y0) <= (y1 - y) else (col[2] if (y1 - y) <= i + 1 else col[1])
                else:
                    c = col
                im.putpixel((x, y), c)
        else:
            for p in layer:
                im.putpixel(p, fill)
    if lip and not pressed:
        # bibir bawah: baris di bawah wajah tombol, dibatasi garis luar
        lm = stepped_mask(w, h, corner, 0)
        for (x, y) in lm:
            if y >= face_h:
                edge = any((x + a, y + b) not in lm for a, b in ((1, 0), (-1, 0), (0, 1)))
                im.putpixel((x, y), O if edge else lipc)
        for x in range(w):  # sambungan wajah-bibir: garis luar wajah tetap tampak sebagai lekuk
            if im.getpixel((x, face_h - 1))[3] and x in (0, w - 1):
                pass
    im.save(OUT / f'{name}.png')
    META[name] = dict(size=[w, h], slice=slices, note=note)
    return im


def gen_nine():
    U = T
    rim_btn = (U['TEXT_2'], U['TEXT_2'], hx('#96643C'))
    # Tombol: 12x16, slice atas 6 bawah 6 kiri 4 kanan 4, bibir 2 px (terasa bisa ditekan)
    sl = [6, 4, 6, 4]
    nine('btn_utama', 12, 16, [O, (HANGAT[0], HANGAT[1], HANGAT[2])], U['ACCENT'], lip=2, lipc=hx('#E98E3F'), slices=sl, note='Aksi utama: isi ACCENT, sisi atas #FFE08A, bibir #E98E3F')
    nine('btn_utama_tekan', 12, 16, [O, U['ACCENT']], U['ACCENT'], lip=2, pressed=True, slices=sl, note='Ditekan: wajah turun 2 px, bibir hilang')
    nine('btn_biasa', 12, 16, [O, rim_btn], U['UI_PANEL_RAISED'], lip=2, lipc=U['UI_BG'], slices=sl, note='Aksi biasa: isi UI_PANEL_RAISED, sisi atas TEXT_2')
    nine('btn_biasa_tekan', 12, 16, [O, U['ACCENT']], U['UI_PANEL_RAISED'], lip=2, pressed=True, slices=sl, note='Ditekan: turun 2 px, bingkai ACCENT')
    nine('btn_sakelar_nyala', 12, 16, [O, U['ACCENT']], U['UI_PANEL_RAISED'], lip=2, lipc=U['UI_BG'], slices=sl, note='Sakelar nyala: bingkai ACCENT + kenop kanan + teks "nyala"')
    nine('btn_tenang', 12, 16, [O, hx('#67636D')], U['UI_PANEL'], lip=0, slices=sl, note='Lewati / bahaya ringan: rata, tanpa bibir')
    nine('btn_tenang_tekan', 12, 16, [O, U['TEXT_2']], U['UI_PANEL_RAISED'], slices=sl, note='Tenang ditekan')
    nine('btn_nonaktif', 12, 16, [U['UI_PANEL_RAISED'], U['UI_PANEL']], U['UI_PANEL'], lip=0, slices=sl, note='Nonaktif: rata, garis redup, isi diarsir (tile), teks alasan')
    # Panel layar dan kartu: 12x12 slice 4
    s4 = [4, 4, 4, 4]
    nine('panel_layar', 12, 12, [O, U['UI_PANEL_RAISED']], U['UI_PANEL'], slices=s4, note='Panel layar penuh')
    nine('kartu_biasa', 12, 12, [O, (hx('#553428'), U['UI_PANEL_RAISED'], U['UI_PANEL_RAISED'])], U['UI_PANEL'], slices=s4, note='Kartu biasa: garis dalam atas #553428')
    nine('kartu_menonjol', 12, 12, [O, U['WARN'], U['UI_PANEL']], U['UI_PANEL'], slices=s4, note='Kartu butuh perhatian: garis dalam WARN 1 px + tanda "!"')
    nine('kartu_redup', 12, 12, [U['UI_PANEL_RAISED']], U['UI_BG'], slices=s4, note='Kartu selesai/redup: rata, tanpa garis luar gelap')
    nine('panel_hud', 12, 12, [O, (U['UI_PANEL_RAISED'], U['UI_PANEL_RAISED'], U['UI_PANEL_RAISED'])], (14, 10, 28, 214), slices=s4, note='Panel HUD (tetap, sama dengan ui_panel_hud_9slice)')
    # Chip: 8x8 slice 3, sudut 1 px
    s3 = [3, 3, 3, 3]
    nine('chip_gelap', 8, 8, [O, U['UI_PANEL_RAISED']], U['UI_BG'], corner=1, slices=s3, note='Chip harga/saldo')
    nine('chip_ok', 8, 8, [O, U['OK']], U['UI_BG'], corner=1, slices=s3, note='Chip status Baik (+ centang)')
    nine('chip_warn', 8, 8, [O, U['WARN']], U['UI_BG'], corner=1, slices=s3, note='Chip Perlu servis (+ "!")')
    nine('chip_netral', 8, 8, [O, U['TEXT_2']], U['UI_BG'], corner=1, slices=s3, note='Chip Dimiliki / tingkat')
    nine('chip_aksen', 8, 8, [O, U['ACCENT']], U['UI_BG'], corner=1, slices=s3, note='Chip tingkat aktif')
    # Koran (layar terang): sudut 1 px, kesan cetak
    nine('koran_kotak', 12, 12, [U['KORAN_GARIS'], U['KORAN_KERTAS'], U['KORAN_GARIS']], U['KORAN_KERTAS_2'], corner=0, slices=s4, note='Kotak misi: garis ganda KORAN_GARIS')
    nine('koran_btn_tinta', 12, 16, [U['KORAN_TINTA'], U['KORAN_TINTA']], U['KORAN_TINTA'], corner=1, lip=2, lipc=U['KORAN_GARIS'], slices=sl, note='Berangkat: tinta penuh, bayangan cetak KORAN_GARIS 2 px')
    nine('koran_btn_tinta_tekan', 12, 16, [U['KORAN_TINTA'], U['KORAN_TINTA_2']], U['KORAN_TINTA'], corner=1, lip=2, pressed=True, slices=sl, note='Berangkat ditekan')
    nine('koran_btn_tipis', 12, 16, [U['KORAN_GARIS']], U['KORAN_KERTAS_2'], corner=1, slices=sl, note='Ambil/Lewati tidak terpilih: garis 1 px')
    nine('koran_btn_terpilih', 12, 16, [U['KORAN_TINTA'], U['KORAN_TINTA'], U['KORAN_TINTA']], U['KORAN_KERTAS'], corner=1, slices=sl, note='Terpilih: BERONGGA, bingkai tinta 3 px')
    # Struk / tiket hasil: tepi bergerigi
    pat = ["..o...o...o.", ".oUo.oUo.oUo", "oUUUoUUUoUUo"] + ["oUUUUUUUUUUo"] * 6 + ["oUUUoUUUoUUo", ".oUo.oUo.oUo", "..o...o...o."]
    pat[1] = pat[1][:11] + 'o'
    im = Image.new('RGBA', (12, 12), (0, 0, 0, 0))
    for y, r in enumerate(pat):
        for x, ch in enumerate(r):
            if ch == 'o':
                im.putpixel((x, y), O)
            elif ch == 'U':
                im.putpixel((x, y), T['UI_PANEL'])
    im.save(OUT / 'struk.png')
    META['struk'] = dict(size=[12, 12], slice=[4, 4, 4, 4], note='Struk hasil: tepi atas/bawah bergerigi, 9-slice mode ulang (tile)')
    # arsir nonaktif dan tekstur kertas
    t = Image.new('RGBA', (4, 4), T['UI_PANEL'])
    for i in range(4):
        t.putpixel((i, 3 - i), T['UI_PANEL_RAISED'])
    t.save(OUT / 'arsir_nonaktif.png'); META['arsir_nonaktif'] = dict(size=[4, 4], note='Tile isi tombol nonaktif')
    t = Image.new('RGBA', (4, 4), T['KORAN_KERTAS'])
    t.putpixel((1, 1), T['KORAN_KERTAS_2']); t.putpixel((3, 3), T['KORAN_KERTAS_2'])
    t.save(OUT / 'kertas_tile.png'); META['kertas_tile'] = dict(size=[4, 4], note='Tekstur titik kertas koran')
    # takik tiket (setengah lingkaran UI_BG)
    pat = ["oooo..", "UUUoo.", "UUUUo.", "UUUUUo", "UUUUUo", "UUUUUo", "UUUUUo", "UUUUo.", "UUUoo.", "oooo.."]
    im = Image.new('RGBA', (6, 10), (0, 0, 0, 0))
    for y, r in enumerate(pat):
        for x, ch in enumerate(r):
            if ch == 'o':
                im.putpixel((x, y), O)
            elif ch == 'U':
                im.putpixel((x, y), T['UI_BG'])
    im.save(OUT / 'struk_takik.png'); META['struk_takik'] = dict(size=[6, 10], note='Takik tiket di garis sobek (dicerminkan untuk sisi kanan)')


# ------------------------------------------------------------------ sepeda tampak samping
def sepeda():
    W, H = 124, 72
    k = Kanvas(W, H)
    RW, FW, BB = (28, 49), (96, 49), (58, 52)
    tire = lambda c: annulus(k, c[0], c[1], 18.2, 21.4)
    rim = lambda c: annulus(k, c[0], c[1], 16.6, 18.2)
    for c in (RW,):
        k.part(tire(c), LOGAM_G); k.part(rim(c), LOGAM)
    k.part(k.mask(lambda d, ss: d.arc([(RW[0] - 23.6) * ss, (RW[1] - 23.6) * ss, (RW[0] + 23.6) * ss, (RW[1] + 23.6) * ss], 230, 330, fill=255, width=int(1.8 * ss))), HIJAU)
    # rantai dan gir belakang (di belakang rangka)
    k.part(k.mask(lambda d, ss: C(d, ss, RW[0], RW[1], 3.2)), LOGAM)
    chain = k.mask(lambda d, ss: (L(d, ss, [(RW[0], RW[1] - 3.4), (BB[0], BB[1] - 6.4)], 1.4), L(d, ss, [(RW[0], RW[1] + 3.2), (BB[0], BB[1] + 6.4)], 1.4)))
    k.part(chain, [LOGAM_G[0], LOGAM_G[1], LOGAM_G[2]], outline=False)
    # tas pelana + koran (depan roda belakang)
    k.part(k.mask(lambda d, ss: L(d, ss, [(10, 26), (46, 26)], 2)), LOGAM)                 # rak
    k.part(k.mask(lambda d, ss: L(d, ss, [(16, 26), (RW[0], RW[1])], 1.6)), LOGAM)
    for x, y0, h, tone in ((16, 13, 13, KREM), (22, 11, 15, LOGAM), (28, 14, 12, KREM)):
        k.part(k.mask(lambda d, ss, x=x, y0=y0, h=h: R(d, ss, x, y0, x + 5, y0 + h, 1.5)), tone)
    k.part(k.mask(lambda d, ss: R(d, ss, 9, 24, 38, 46, 2)), BATA)                         # tas
    k.part(k.mask(lambda d, ss: R(d, ss, 9, 24, 38, 31, 2)), [BATA[0], BATA[0], BATA[2]])  # tutup tas
    k.part(k.mask(lambda d, ss: R(d, ss, 22, 28, 25, 39, 0)), LOGAM_G)                       # tali
    k.part(k.mask(lambda d, ss: R(d, ss, 21, 34, 26, 37, 0)), LOGAM)                         # gesper
    # rangka hijau
    G = HIJAU
    tubes = [([BB, (52, 22)], 2.8), ([(52, 27), (85, 25)], 2.6), ([BB, (87, 34)], 3.0), ([BB, RW], 2.2), ([(52, 27), RW], 2.0)]
    for pts, w in tubes:
        k.part(k.mask(lambda d, ss, pts=pts, w=w: L(d, ss, pts, w)), G)
    k.part(k.mask(lambda d, ss: L(d, ss, [(84, 22), (88, 35)], 3.4)), G)                   # head tube
    k.part(k.mask(lambda d, ss: L(d, ss, [(88, 34), FW], 2.4)), G)                          # garpu
    # sadel dan tiang
    k.part(k.mask(lambda d, ss: L(d, ss, [(52, 23), (51, 18)], 1.8)), LOGAM)
    k.part(k.mask(lambda d, ss: P(d, ss, [(42, 15.5), (58, 14.5), (60, 17.5), (53, 20), (44, 19)])), KAYU)
    # gir depan + engkol + pedal
    k.part(annulus(k, BB[0], BB[1], 2, 6.8), LOGAM)
    k.part(k.mask(lambda d, ss: L(d, ss, [BB, (63, 60)], 2)), LOGAM)
    k.part(k.mask(lambda d, ss: R(d, ss, 60, 59.5, 67, 62, 0.5)), LOGAM_G)
    k.part(k.mask(lambda d, ss: L(d, ss, [(56, 54), (50, 65)], 1.6)), LOGAM_G)             # standar
    # roda depan
    k.part(tire(FW), LOGAM_G); k.part(rim(FW), LOGAM)
    k.part(k.mask(lambda d, ss: L(d, ss, [(88, 34), FW], 2.4)), G)
    # spatbor
    for c, a0, a1 in ((FW, 215, 330),):
        k.part(k.mask(lambda d, ss, c=c, a0=a0, a1=a1: d.arc([(c[0] - 23.6) * ss, (c[1] - 23.6) * ss, (c[0] + 23.6) * ss, (c[1] + 23.6) * ss], a0, a1, fill=255, width=int(1.8 * ss))), G)
    # setang, pegangan, tuas rem, bel, rem depan
    k.part(k.mask(lambda d, ss: L(d, ss, [(85, 23), (83, 14)], 2.2)), LOGAM)
    k.part(k.mask(lambda d, ss: L(d, ss, [(83, 14), (77, 12.5), (72, 14)], 2)), LOGAM)
    k.part(k.mask(lambda d, ss: R(d, ss, 68.5, 12.5, 74, 16, 1.2)), LOGAM_G)
    k.part(k.mask(lambda d, ss: L(d, ss, [(78, 15), (72.5, 18.5)], 1.4)), LOGAM)
    k.part(k.mask(lambda d, ss: C(d, ss, 80, 11, 1.8)), HANGAT)
    k.part(k.mask(lambda d, ss: P(d, ss, [(88, 26), (93, 26.2), (94, 29.5), (87.5, 29.5)])), LOGAM)  # kaliper rem depan
    k.outline()
    # jari-jari tanpa garis luar
    for c in (RW, FW):
        for i in range(12):
            a = math.radians(i * 30 + 8)
            for t in range(3, 17):
                p = (int(round(c[0] - .5 + t * math.cos(a))), int(round(c[1] - .5 + t * math.sin(a))))
                if p not in k.px:
                    k.put(*p, LOGAM[2])
        for p in k.mask(lambda d, ss, c=c: C(d, ss, c[0], c[1], 2)):
            k.put(*p, LOGAM[0])
    # kabel rem depan
    for p in k.mask(lambda d, ss: L(d, ss, [(76, 16.5), (82, 21), (88, 26)], 1)):
        if p not in k.px:
            k.put(*p, LOGAM_G[1])
    im = k.image()
    im.save(OUT / 'sepeda_samping.png')
    titik = {'ban_belakang': [RW[0] - 21, RW[1]], 'ban_depan': [FW[0] + 21, FW[1]], 'rem': [91, 27], 'rantai': [42, 49]}
    META['sepeda_samping'] = dict(size=[W, H], titik=titik, note='Sepeda loper tampak samping, hadap kanan, cahaya kiri atas. Titik tandai: ban, rem, rantai')
    return titik


# ------------------------------------------------------------------ papan alat bengkel
def papan_alat(W=360, H=104):
    k = Kanvas(W, H)
    base = T['UI_PANEL']
    for y in range(H):
        for x in range(W):
            k.put(x, y, base)
    for y in range(4, H - 4, 6):
        for x in range(4 + (y // 6 % 2) * 3, W - 3, 6):
            k.put(x, y, T['UI_BG'])
    tone = [hx('#553428'), T['UI_PANEL_RAISED'], T['UI_BG']]
    # kunci pas, palu, obeng, tang, ban cadangan, pompa
    k.part(k.mask(lambda d, ss: (L(d, ss, [(18, 14), (18, 50)], 3), C(d, ss, 18, 12, 5))) - k.mask(lambda d, ss: C(d, ss, 18, 8.5, 3)), tone, outline=False)
    k.part(k.mask(lambda d, ss: (L(d, ss, [(36, 14), (36, 52)], 2.6), R(d, ss, 29, 9, 43, 15, 1))), tone, outline=False)
    k.part(k.mask(lambda d, ss: (L(d, ss, [(54, 10), (54, 30)], 4), L(d, ss, [(54, 30), (54, 46)], 1.4))), tone, outline=False)
    k.part(k.mask(lambda d, ss: (L(d, ss, [(68, 12), (74, 46)], 2.4), L(d, ss, [(80, 12), (74, 46)], 2.4))), tone, outline=False)
    k.part(annulus(k, W - 46, 34, 14, 20), tone, outline=False)
    k.part(k.mask(lambda d, ss: (R(d, ss, W - 86, 14, W - 80, 54, 1), L(d, ss, [(W - 88, 12), (W - 78, 12)], 2))), tone, outline=False)
    # rak bawah dengan kaleng
    k.part(k.mask(lambda d, ss: R(d, ss, 0, 58, W, 61, 0)), tone, outline=False)
    for x in (12, 24, W - 30, 120, 230):
        k.part(k.mask(lambda d, ss, x=x: R(d, ss, x, 49, x + 8, 58, 1)), tone, outline=False)
    # lantai
    for y in range(H - 14, H):
        for x in range(W):
            k.put(x, y, T['UI_BG'] if y > H - 14 else T['UI_PANEL_RAISED'])
    for x in range(0, W, 16):
        for y in range(H - 13, H):
            k.put(x, y, T['UI_PANEL'])
    im = k.image(); im.save(OUT / 'papan_alat.png')
    META['papan_alat'] = dict(size=[W, H], note='Latar panel sepeda: papan peralatan + rak + lantai, nada rendah (hanya UI_BG, UI_PANEL, UI_PANEL_RAISED, #553428)')


# ------------------------------------------------------------------ foto koran (tinta)
def foto_jalan(W=100, H=62):
    INK, INK2, P2, P1 = T['KORAN_TINTA'], T['KORAN_TINTA_2'], T['KORAN_KERTAS_2'], T['KORAN_KERTAS']
    im = Image.new('RGBA', (W, H), P2)
    for y in range(H):
        for x in range(W):
            road = (x * 0.5 + 20 < y + 18) and (x * 0.5 - 6 > y - 30)
            if road and (x + y) % 2 == 0:
                im.putpixel((x, y), INK2)
            elif not road and y < 20 and (x % 3 == 0 and y % 3 == 0):
                im.putpixel((x, y), INK2)
    def cone(cx, by, h=14):
        for y in range(by - h, by):
            half = (y - (by - h)) * 0.32 + 0.5
            for x in range(int(cx - half), int(cx + half) + 1):
                stripe = (by - h + 5 <= y <= by - h + 6) or (by - h + 9 <= y <= by - h + 10)
                im.putpixel((x, y), P1 if stripe else INK)
        for x in range(int(cx - 6), int(cx + 7)):
            im.putpixel((x, by), INK); im.putpixel((x, by - 1), INK)
    cone(28, 52); cone(46, 44, 12); cone(64, 36, 10)
    for x in range(58, 92):  # palang
        y = int(26 - (x - 58) * 0.25)
        for t in range(4):
            im.putpixel((x, y + t), INK if ((x // 4) % 2 == 0) else P1)
        if x in (60, 88):
            for t in range(4, 14):
                im.putpixel((x, y + t), INK)
    for x in range(W):
        im.putpixel((x, 0), INK); im.putpixel((x, H - 1), INK)
    for y in range(H):
        im.putpixel((0, y), INK); im.putpixel((W - 1, y), INK)
    im.save(OUT / 'foto_jalan.png')
    META['foto_jalan'] = dict(size=[W, H], note='Foto berita utama "Jalan Sedang Diperbaiki": tinta 2 nada di atas KORAN_KERTAS_2')


def foto_lampu(W=100, H=62):
    INK, INK2, P2, P1 = T['KORAN_TINTA'], T['KORAN_TINTA_2'], T['KORAN_KERTAS_2'], T['KORAN_KERTAS']
    im = Image.new('RGBA', (W, H), P2)
    for y in range(H):
        for x in range(W):
            if y < 40 and (x + y) % 2 == 0:
                im.putpixel((x, y), INK2)
            if y >= 48 and (x * 3 + y) % 5 == 0:
                im.putpixel((x, y), INK2)
    for y in range(6, 50):
        for x in (30, 31, 32):
            im.putpixel((x, y), INK)
    for x in range(22, 41):
        im.putpixel((x, 10), INK); im.putpixel((x, 11), INK)
    for x in range(0, 30):
        im.putpixel((x, 14 + int(abs(x - 15) ** 1.2 / 6)), INK)
    for x in range(33, W):
        y = 14 + int(((x - 33) / 6) ** 1.4)
        if y < H - 1:
            im.putpixel((x, y), INK)
    for y in range(36, 46):  # rumah gelap
        for x in range(58, 92):
            im.putpixel((x, y), INK)
    for x in range(62, 70):
        for y in (39, 40):
            im.putpixel((x, y), INK2)
    for x in range(W):
        im.putpixel((x, 0), INK); im.putpixel((x, H - 1), INK)
    for y in range(H):
        im.putpixel((0, y), INK); im.putpixel((W - 1, y), INK)
    im.save(OUT / 'foto_lampu.png')
    META['foto_lampu'] = dict(size=[W, H], note='Foto berita utama "Mati Lampu": tiang dan kabel')


# ------------------------------------------------------------------ main
def sheet(imgs, cell, name, note):
    w = cell * len(imgs)
    sh = Image.new('RGBA', (w, cell), (0, 0, 0, 0))
    for i, im in enumerate(imgs):
        sh.alpha_composite(im, (i * cell, 0))
    sh.save(OUT / f'{name}.png')
    return sh


ik = [('koin', ikon_koin()), ('bintang', ikon_bintang()), ('ban', ikon_ban()), ('rem', ikon_rem()), ('rantai', ikon_rantai()),
      ('kucing', ikon_kucing()), ('kerucut', ikon_kerucut()), ('bohlam', ikon_bohlam()),
      ('lencana_perunggu', lencana(24, PERUNGGU, 1)), ('lencana_perak', lencana(24, PERAK, 2)), ('lencana_emas', lencana(24, EMAS, 3)), ('lencana_belum', lencana_kunci(24))]
sheet([i for _, i in ik], 24, 'ikon24', '')
META['ikon24'] = dict(size=[24 * len(ik), 24], urutan=[n for n, _ in ik], note='Ikon besar 24x24 (sheet), garis luar 1 px, 3 nada, cahaya kiri atas')
l32 = [('perunggu', lencana(32, PERUNGGU, 1)), ('perak', lencana(32, PERAK, 2)), ('emas', lencana(32, EMAS, 3)), ('belum', lencana_kunci(32))]
sheet([i for _, i in l32], 32, 'lencana32', '')
META['lencana32'] = dict(size=[128, 32], urutan=[n for n, _ in l32], note='Lencana milestone 32x32; tingkat juga ditandai 1/2/3 titik di pita')

names = list(GLIF.keys())
gs = Image.new('RGBA', (12 * len(names), 12 * len(GLIF_WARNA)), (0, 0, 0, 0))
for r, (_, col) in enumerate(GLIF_WARNA):
    for c, n in enumerate(names):
        for y, row in enumerate(GLIF[n]):
            for x, ch in enumerate(row):
                if ch == '#':
                    gs.putpixel((c * 12 + x, r * 12 + y), col)
gs.save(OUT / 'glif12.png')
META['glif12'] = dict(size=list(gs.size), kolom=names, baris=[n for n, _ in GLIF_WARNA], note='Glif satu warna 12x12; di Godot satu PNG putih + modulate')

gen_nine()
sepeda(); papan_alat(); foto_jalan(); foto_lampu()
(OUT / 'meta.json').write_text(json.dumps(META, indent=1, sort_keys=True) + '\n')


def lembar(nama, items, skala, latar=(54, 40, 30, 255), jarak=4):
    """Lembar pratinjau: aset ditata berderet, diperbesar bulat tanpa penghalusan."""
    lebar = sum(i.width for i in items) + jarak * (len(items) + 1)
    tinggi = max(i.height for i in items) + jarak * 2
    kan = Image.new('RGBA', (lebar, tinggi), latar)
    x = jarak
    for im in items:
        kan.alpha_composite(im.convert('RGBA'), (x, jarak))
        x += im.width + jarak
    kan.resize((lebar * skala, tinggi * skala), Image.NEAREST).save(OUT / nama)


def buka(n):
    return Image.open(OUT / f'{n}.png')


lembar('lembar_9slice_x6.png', [buka(n) for n in ('btn_utama', 'btn_utama_tekan', 'btn_biasa', 'btn_biasa_tekan', 'btn_sakelar_nyala',
       'btn_tenang', 'btn_tenang_tekan', 'btn_nonaktif', 'panel_layar', 'kartu_biasa', 'kartu_menonjol', 'kartu_redup', 'panel_hud',
       'chip_gelap', 'chip_ok', 'chip_warn', 'chip_netral', 'chip_aksen', 'koran_kotak', 'koran_btn_tinta', 'koran_btn_tinta_tekan',
       'koran_btn_tipis', 'koran_btn_terpilih', 'struk', 'struk_takik')], 6)
lembar('lembar_ikon_x4.png', [buka('ikon24'), buka('lencana32'), buka('glif12')], 4)
lembar('lembar_sepeda_x3.png', [buka('papan_alat'), buka('sepeda_samping'), buka('foto_jalan'), buka('foto_lampu')], 3)

if ARGS.mock:
    MOCK.mkdir(parents=True, exist_ok=True)
    for p in sorted(OUT.iterdir()):
        if p.suffix in ('.png', '.json'):
            shutil.copyfile(p, MOCK / p.name)
print('ok', len(META), 'aset ->', OUT, '(+ docs)' if ARGS.mock else '')
