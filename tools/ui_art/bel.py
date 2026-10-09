"""Aset bel "Kring Kring!" (usulan, 2026-10-09): tombol bel HUD, efek "kring" di atas setang,
dan ikon "!" untuk warga atau hewan yang mendengar bel.

    python3 tools/ui_art/bel.py --out build/ui_art/bel

Hasil 1x (piksel asli, yang dipakai di Godot):
  tombol_bel.png        3 keadaan 40x40 berjajar: diam, ditekan, jeda (cincin = sisa jeda)
  vfx_bel.png           garis getar, 4 frame 16x16, 12 fps, titik jangkar (3, 12) = titik bel
  teks_kring.png        teks "KRING!", 2 frame berjajar (terang, redup)
  teks_kring_kring.png  teks "KRING KRING!", 2 frame berjajar (terang, redup)
  ikon_seru.png         ikon "!" 11x13, titik jangkar (5, 12) = 2 px di atas kepala
Pratinjau (preview/): tombol x4, frame efek x6, teks x6, GIF efek di atas sprite rute
(satu dan dua kali kring), penempatan tombol di mock HUD dan zona kontrol, ikon "!" di atas ayam.

Warna dari palet induk (ART_DIRECTION 2.4) dan token UI (DESIGN_SPEC 1.1).
Butuh numpy dan pillow.
"""
import argparse
import math
import os

import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


def hexc(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


OUT = hexc("0E0A1C")
TEXT = hexc("FFF3E3")
TEXT_2 = hexc("CDB9A3")
ACCENT = hexc("FFB22E")
RAISED = hexc("36281E")
HUD_PANEL = hexc("0E0A1C", 214)  # 84%
Y_HI = hexc("FFE08A")
Y_BASE = hexc("FFC94A")
Y_SH = hexc("E98E3F")
WARN = hexc("FF8A3D")
ASPAL = hexc("6C6872")
ASPAL_2 = hexc("67636D")

# titik bel di sel sprite rute 46x58 (loper_agen.png), per baris animasi santai
BELL_ANCHOR = {0: (33, 24), 2: (28, 30)}  # 0 = santai_normal, 2 = santai_kanan


def canvas(w, h):
    return np.zeros((h, w, 4), np.uint8)


def put(c, x, y, col):
    if 0 <= y < c.shape[0] and 0 <= x < c.shape[1]:
        c[y, x] = col


def outline(c, col=OUT, diag=True):
    """Garis luar 1 px di sekeliling piksel yang terisi."""
    a = c[..., 3] > 0
    h, w = a.shape
    pad = np.pad(a, 1)
    n = np.zeros_like(a)
    offs = [(-1, 0), (1, 0), (0, -1), (0, 1)]
    if diag:
        offs += [(-1, -1), (-1, 1), (1, -1), (1, 1)]
    for dy, dx in offs:
        n |= pad[1 + dy:1 + dy + h, 1 + dx:1 + dx + w]
    c[n & ~a] = col
    return c


def paste(dst, src, x0, y0):
    h, w = src.shape[:2]
    for y in range(h):
        for x in range(w):
            if src[y, x, 3]:
                put(dst, x0 + x, y0 + y, tuple(src[y, x]))


def to_img(c):
    return Image.fromarray(c, "RGBA")


def big(img, s):
    return img.resize((img.width * s, img.height * s), Image.NEAREST)


# ---------------------------------------------------------------- ikon bel 20x19
BELL_SHAPE = [
    "........##........",
    ".......####.......",
    "......######......",
    ".....########.....",
    "....##########....",
    "....##########....",
    "...############...",
    "...############...",
    "...############...",
    "...############...",
    "..##############..",
    "..##############..",
    ".################.",
    "##################",
    "##################",
    ".......####.......",
    "........##........",
]


def bell_icon():
    h, w = len(BELL_SHAPE), len(BELL_SHAPE[0])
    c = canvas(w + 2, h + 2)
    for y, row in enumerate(BELL_SHAPE):
        xs = [x for x, v in enumerate(row) if v == "#"]
        x0, x1 = xs[0], xs[-1]
        span = max(1, x1 - x0)
        for x in xs:
            t = (x - x0) / span
            col = Y_HI if t < 0.30 else (Y_BASE if t < 0.72 else Y_SH)
            if y >= 13:                        # bibir bel
                col = Y_SH if (y == 14 or t > 0.72) else Y_BASE
            if y >= 15:                        # pemukul
                col = Y_SH
            c[y + 1, x + 1] = col
    for y in range(6, 11):                     # kilau tegak di kiri
        c[y + 1, 6] = TEXT
    c[5, 7] = TEXT
    return outline(c, diag=False)


# ---------------------------------------------------------------- tombol 40x40
def button(state, progress=0.5):
    S = 40
    c = canvas(S, S)
    cx = cy = S / 2
    for y in range(S):
        for x in range(S):
            d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
            if d > 19.5:
                continue
            if d > 18.5:
                col = OUT
            elif d > 17.5:
                col = {"diam": TEXT, "ditekan": ACCENT, "jeda": RAISED}[state]
                if state == "jeda":
                    ang = (math.degrees(math.atan2(x + 0.5 - cx, -(y + 0.5 - cy))) + 360) % 360
                    if ang <= progress * 360:
                        col = ACCENT
            elif d > 16.5:
                col = RAISED
            else:
                col = HUD_PANEL if state != "ditekan" else hexc("2A1E17", 230)
            c[y, x] = col
    icon = bell_icon()
    ih, iw = icon.shape[:2]
    ix, iy = (S - iw) // 2, (S - ih) // 2
    if state == "jeda":
        # ikon redup: dicampur 45% dengan panel, tetap piksel penuh
        for y in range(ih):
            for x in range(iw):
                if icon[y, x, 3]:
                    base = np.array(c[iy + y, ix + x, :3], int)
                    top = np.array(icon[y, x, :3], int)
                    c[iy + y, ix + x, :3] = (base * 55 + top * 45) // 100
        return c
    paste(c, icon, ix, iy + (1 if state == "ditekan" else 0))
    if state == "ditekan":                     # garis getar kecil di kiri dan kanan ikon
        for (x, y) in [(6, 14), (5, 15), (6, 24), (5, 23), (33, 14), (34, 15), (33, 24), (34, 23)]:
            put(c, x, y, TEXT)
    return c


# ---------------------------------------------------------------- huruf 3x5 (N 4x5)
GLYPH = {
    "K": ["#.#", "#.#", "##.", "#.#", "#.#"],
    "R": ["##.", "#.#", "##.", "#.#", "#.#"],
    "I": ["###", ".#.", ".#.", ".#.", "###"],
    "N": ["#..#", "##.#", "#.##", "#..#", "#..#"],
    "G": [".##", "#..", "#.#", "#.#", ".##"],
    "!": ["#", "#", "#", ".", "#"],
    " ": ["..", "..", "..", "..", ".."],
}


def word(text, dim=False):
    w = sum(len(GLYPH[ch][0]) + 1 for ch in text) - 1
    c = canvas(w + 2, 7)
    hi, base, line = (Y_HI, Y_BASE, OUT) if not dim else (Y_BASE, Y_SH, RAISED)
    x0 = 1
    for ch in text:
        g = GLYPH[ch]
        for r, row in enumerate(g):
            for k, v in enumerate(row):
                if v == "#":
                    c[1 + r, x0 + k] = hi if r < 2 else base
        x0 += len(g[0]) + 1
    return outline(c, col=line)


def label(text):
    """Dua frame berjajar: terang, lalu redup (frame terakhir sebelum hilang)."""
    a, b = word(text), word(text, dim=True)
    out = canvas(a.shape[1] * 2, a.shape[0])
    out[:, :a.shape[1]] = a
    out[:, a.shape[1]:] = b
    return out


# ---------------------------------------------------------------- efek kring
# Garis getar ")" di sisi kanan bel, jauh dari badan pengendara. Teks "KRING!" sprite terpisah
# yang naik 1 px per frame selama 4 frame (frame terakhir versi redup). Kring kedua (ketuk lagi
# selama teks masih tampil) mengulang garis getar dan mengganti teks jadi "KRING KRING!".
FW, FH, AX, AY = 16, 16, 3, 12            # ukuran frame dan titik jangkar (= titik bel)
TEXT_DX, TEXT_DY = 3, -16                  # pojok kiri atas teks, relatif ke titik bel


def arc(c, r, col):
    pts = set()
    for a in np.arange(-80, 25, 3):
        t = math.radians(a)
        pts.add((int(round(AX + 0.5 + r * math.cos(t))), int(round(AY + 0.5 + r * math.sin(t)))))
    for x, y in pts:
        put(c, x, y, col)


def vfx_frames():
    spec = [  # (busur: radius dan warna, kilat di bel)
        ([(3, TEXT)], True),
        ([(3, TEXT), (6, TEXT)], False),
        ([(6, TEXT), (9, Y_HI)], False),
        ([(9, TEXT_2)], False),
    ]
    frames = []
    for arcs, flash in spec:
        c = canvas(FW, FH)
        for r, col in arcs:
            arc(c, r, col)
        if flash:
            for (x, y) in [(AX, AY), (AX + 1, AY), (AX, AY - 1), (AX + 1, AY - 1)]:
                put(c, x, y, TEXT)
        frames.append(outline(c, diag=False))
    return frames


def sheet(frames):
    out = canvas(len(frames) * FW, FH)
    for i, f in enumerate(frames):
        out[:, i * FW:(i + 1) * FW] = f
    return out


# ---------------------------------------------------------------- ikon "!"
def seru():
    c = canvas(11, 13)
    for y in range(1, 10):
        for x in range(1, 10):
            if (x in (1, 9)) and (y in (1, 9)):
                continue
            c[y, x] = TEXT
    for y in (2, 3, 4, 5, 6):
        c[y, 5] = WARN
    c[8, 5] = WARN
    c[10, 5] = TEXT  # ekor kecil
    return outline(c, diag=False)


# ---------------------------------------------------------------- pratinjau
def sprite_cell(row, col=0):
    sh = Image.open(os.path.join(ROOT, "docs/design/character/loper_agen/loper_agen.png")).convert("RGBA")
    return sh.crop((col * 46, row * 58, col * 46 + 46, row * 58 + 58))


def road(W, H):
    img = Image.new("RGBA", (W, H), ASPAL)
    d = ImageDraw.Draw(img)
    for k in range(-4, 14):
        d.line([(k * 16, H), (k * 16 + 32, H - 16)], fill=ASPAL_2)
    return img


def gif_on_sprite(path, row, double, scale=6):
    """Sprite rute (4 frame kayuh) + efek kring di atas aspal, 12 fps."""
    ticks = [to_img(f) for f in vfx_frames()]
    one, one_dim = to_img(word("KRING!")), to_img(word("KRING!", dim=True))
    two, two_dim = to_img(word("KRING KRING!")), to_img(word("KRING KRING!", dim=True))
    bx, by = BELL_ANCHOR[row]
    W, H, ox, oy = 110, 64, 8, 6
    taps = [1, 4] if double else [1]
    n = taps[-1] + 8
    seq = []
    for i in range(n):
        img = road(W, H)
        img.alpha_composite(sprite_cell(row, i % 4), (ox, oy))
        last = max([t for t in taps if t <= i], default=None)
        if last is not None:
            f = i - last
            if f < len(ticks):
                img.alpha_composite(ticks[f], (ox + bx - AX, oy + by - AY))
            second = double and last == taps[-1]
            # teks muncul 1 frame setelah ketukan; pada kring kedua teks langsung diganti
            k = f if second else f - 1
            if 0 <= k <= 3:
                t = (two if k < 3 else two_dim) if second else (one if k < 3 else one_dim)
                img.alpha_composite(t, (ox + bx + TEXT_DX, oy + by + TEXT_DY - k))
        seq.append(big(img, scale))
    seq[0].save(path, save_all=True, append_images=seq[1:], duration=83, loop=0, disposal=2)


def dashed_rect(d, x0, y0, x1, y1, col, step=24, dash=14, width=3):
    for (a, b) in [((x0, y0), (x1, y0)), ((x1, y0), (x1, y1)), ((x1, y1), (x0, y1)), ((x0, y1), (x0, y0))]:
        L = math.hypot(b[0] - a[0], b[1] - a[1])
        for i in range(int(L // step) + 1):
            s, e = i * step / L, min(1, (i * step + dash) / L)
            d.line([(a[0] + (b[0] - a[0]) * s, a[1] + (b[1] - a[1]) * s),
                    (a[0] + (b[0] - a[0]) * e, a[1] + (b[1] - a[1]) * e)], fill=col, width=width)


def placement(base, out_png, zones):
    """Tombol (x2) di pojok kanan bawah mock 1600x720 (kanvas dasar 800x360 x2).
    Pusat tombol di (772, 332) piksel dasar; zona tap radius 28."""
    img = base.convert("RGBA").crop((0, 0, 1600, 720))
    d = ImageDraw.Draw(img)
    cx, cy = 772 * 2, 332 * 2
    if zones:
        dashed_rect(d, 16, 372, 384, 704, TEXT)          # zona stick
        dashed_rect(d, 420, 96, 1560, 704, TEXT)         # zona swipe
        r = 56
        for i in range(0, 360, 20):
            d.arc([cx - r, cy - r, cx + r, cy + r], start=i, end=i + 12, fill=ACCENT, width=3)
    img.alpha_composite(big(to_img(button("diam")), 2), (cx - 40, cy - 40))
    img.save(out_png)


def chicken_preview(out_png):
    im = Image.open(os.path.join(ROOT, "docs/design/environment/detail_ayam.webp")).convert("RGBA")
    im = im.resize((im.width // 5, im.height // 5), Image.NEAREST)  # kembali ke 1x
    s = to_img(seru())
    im.alpha_composite(s, (30, 4))     # di atas ayam putih
    im.alpha_composite(s, (63, 5))     # di atas ayam cokelat
    big(im, 5).save(out_png)


def main():
    ap = argparse.ArgumentParser(description="Aset bel Kring Kring! (usulan)")
    ap.add_argument("--out", default="build/ui_art/bel")
    out = ap.parse_args().out
    pv = os.path.join(out, "preview")
    os.makedirs(pv, exist_ok=True)

    tb = canvas(120, 40)
    for i, s in enumerate([button("diam"), button("ditekan"), button("jeda", 0.5)]):
        tb[:, i * 40:(i + 1) * 40] = s
    to_img(tb).save(os.path.join(out, "tombol_bel.png"))
    show = road(136, 48)
    show.alpha_composite(to_img(tb), (8, 4))
    big(show, 4).save(os.path.join(pv, "tombol_bel_x4.png"))

    fr = vfx_frames()
    to_img(sheet(fr)).save(os.path.join(out, "vfx_bel.png"))
    to_img(label("KRING!")).save(os.path.join(out, "teks_kring.png"))
    to_img(label("KRING KRING!")).save(os.path.join(out, "teks_kring_kring.png"))
    strip = Image.new("RGBA", (len(fr) * (FW + 4) + 4, FH + 8), ASPAL)
    for i, f in enumerate(fr):
        strip.alpha_composite(to_img(f), (4 + i * (FW + 4), 4))
    big(strip, 6).save(os.path.join(pv, "vfx_bel_frames_x6.png"))
    lab = Image.new("RGBA", (58, 22), ASPAL)
    lab.alpha_composite(to_img(word("KRING!")), (3, 3))
    lab.alpha_composite(to_img(word("KRING KRING!")), (3, 12))
    big(lab, 6).save(os.path.join(pv, "teks_kring_x6.png"))

    to_img(seru()).save(os.path.join(out, "ikon_seru.png"))
    chicken_preview(os.path.join(pv, "reaksi_ayam_x5.png"))

    gif_on_sprite(os.path.join(pv, "kring_normal_x6.gif"), 0, False)
    gif_on_sprite(os.path.join(pv, "kring_kring_normal_x6.gif"), 0, True)
    gif_on_sprite(os.path.join(pv, "kring_kanan_x6.gif"), 2, False)

    placement(Image.open(os.path.join(ROOT, "docs/design/screens/hud-rute.png")),
              os.path.join(pv, "penempatan_hud.png"), False)
    sc = Image.open(os.path.join(ROOT, "docs/design/source/scene.png"))
    placement(big(sc.convert("RGBA"), 4), os.path.join(pv, "penempatan_kontrol.png"), True)
    print("selesai ->", out)


if __name__ == "__main__":
    main()
