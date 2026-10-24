"""Ikon HUD 14x14, penanda radar, dan panel HUD 9-slice (usulan; strip radar tanpa bingkai sejak revisi UI pemilik R-3: garis sumbu digambar dari kode).

Ukuran dan token warna mengikuti docs/design/DESIGN_SPEC.md (1.1, 1.3, 3.3, 3.4), palet ART_DIRECTION 2.4.
Pola piksel ditulis sebagai baris teks berisi peran warna, seperti scripts/systems/pola_piksel.gd:
'.' kosong, 'o' garis luar OUTLINE, huruf lain = nada dari palet ikon.

Menjalankan (dari root repo):
    python3 tools/ui_art/hud_ikon.py            # tulis ke build/ui_art/hud/
    python3 tools/ui_art/hud_ikon.py --salin    # lalu salin ke assets/sprites/ui/ dan pratinjau ke docs/design/hud/
Contoh radar di atas layar memakai build/env_art/fase3/layar_fase3.png kalau sudah dirender
(python3 tools/env_art/fase3.py).
"""
import json
import shutil
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / 'build' / 'ui_art' / 'hud'


def hexc(h, a=255):
    h = h.lstrip('#')
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


O = hexc('#0E0A1C')
EMAS = {'L': hexc('#FFE08A'), 'm': hexc('#FFC94A'), 'd': hexc('#E98E3F'), 'w': hexc('#FBF6E8')}
PERAK = {'L': hexc('#C4C0C8'), 'm': hexc('#969AA0'), 'd': hexc('#67636D')}
KARET = {'g': hexc('#5F5B66'), 'G': hexc('#3D4649'), 'k': hexc('#221E26')}
JAHE = {'L': hexc('#FFC94A'), 'm': hexc('#E98E3F'), 'd': hexc('#B5523B'), 'p': hexc('#F0C8CD'), 'w': hexc('#FBF6E8')}

CIRCLE = ["....oooooo....",
          "..oo......oo..",
          ".o..........o.",
          ".o..........o.",
          "o............o",
          "o............o",
          "o............o",
          "o............o",
          "o............o",
          "o............o",
          ".o..........o.",
          ".o..........o.",
          "..oo......oo..",
          "....oooooo...."]


def circle_inside():
    ins = set()
    for y, r in enumerate(CIRCLE):
        idx = [i for i, c in enumerate(r) if c == 'o']
        a, b = min(idx), max(idx)
        if y in (0, 13):
            continue
        for x in range(a + 1, b):
            if r[x] != 'o':
                ins.add((x, y))
    return ins


def gen_koin():
    ins = circle_inside()
    g = [list(r) for r in CIRCLE]
    for (x, y) in ins:
        dx, dy = x - 6.5, y - 6.5
        r = (dx * dx + dy * dy) ** .5
        rim = any((x + ex, y + ey) not in ins for ex, ey in ((1, 0), (-1, 0), (0, 1), (0, -1)))
        if rim:
            g[y][x] = 'L' if dx + dy < 0 else 'd'
        elif 2.6 < r < 3.8:  # cincin timbul di tengah koin
            g[y][x] = 'd' if dx + dy > 0 else 'L'
        else:
            g[y][x] = 'm'
    g[3][4] = 'w'; g[4][3] = 'w'; g[3][5] = 'w'
    return [''.join(r) for r in g], EMAS


def gen_ban():
    ins = circle_inside()
    g = [list(r) for r in CIRCLE]
    for (x, y) in ins:
        dx, dy = x - 6.5, y - 6.5
        r = (dx * dx + dy * dy) ** .5
        if r > 4.6:
            g[y][x] = 'g' if dx + dy < -2 else ('k' if dx + dy > 3 else 'G')
        elif r > 3.7:
            g[y][x] = 'L' if dx + dy < 0 else 'm'
        elif r < 1.3:
            g[y][x] = 'L'
        elif abs(dx) < 0.6 or abs(dy) < 0.6:
            g[y][x] = 'd'   # jari-jari
        else:
            g[y][x] = 'k'
    pal = dict(PERAK); pal.update(KARET)
    return [''.join(r) for r in g], pal


BINTANG = ["......oo......",
           ".....oLmo.....",
           ".....oLmo.....",
           "....oLLmmo....",
           ".ooooLLmmoooo.",
           "oLLLLLLmmmmmmo",
           ".oLLLLLmmmmmo.",
           "..oLLLLmmmmo..",
           "...oLLLmmmo...",
           "...oLLLmmmo...",
           "..oLLLoommdo..",
           "..oLLo..oddo..",
           ".oLoo....oodo.",
           ".oo........oo."]

# tuas rem: setang perak di kiri, klem di tengah, pegangan karet di kanan, tuas melengkung di bawah pegangan
REM = ["..............",
       "..............",
       ".....ooo......",
       "ooooomLmoooooo",
       "oLLLLmLmogggGo",
       "ommmmmLmoGGGko",
       "oooooodooooooo",
       ".....oLdo.....",
       ".....oLLLooo..",
       "......oLLLLLoo",
       ".......oommmdo",
       ".........oooo.",
       "..............",
       ".............."]


def gen_rantai():
    """Dua mata rantai yang saling mengait: A kiri atas, B kanan bawah, A lewat di atas B di satu titik."""
    W = H = 14
    g = [['.'] * W for _ in range(H)]

    def ring(x0, y0, x1, y1):
        px = {}
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                corner = (x in (x0, x1)) and (y in (y0, y1))
                if corner:
                    continue
                edge = x in (x0, x1) or y in (y0, y1)
                c2 = (x in (x0 + 1, x1 - 1)) and (y in (y0 + 1, y1 - 1))
                band = x in (x0 + 1, x1 - 1) or y in (y0 + 1, y1 - 1)
                if edge or c2:
                    px[(x, y)] = 'o'
                elif band:
                    px[(x, y)] = 'L' if (x == x0 + 1 or y == y0 + 1) and not (x == x1 - 1 or y == y1 - 1) else ('d' if (x == x1 - 1 or y == y1 - 1) else 'm')
        return px

    A = ring(0, 2, 8, 8)
    B = ring(5, 5, 13, 11)
    for d in (A, B):
        for k, v in d.items():
            g[k[1]][k[0]] = v
    # A di atas B pada sisi kanan A (kolom 7-8, baris 5-7)
    for k, v in A.items():
        if k[0] >= 6 and 5 <= k[1] <= 7:
            g[k[1]][k[0]] = v
    return [''.join(r) for r in g], PERAK


KUCING = ["..............",
          ".oo........oo.",
          ".oLo......omo.",
          ".oLpo....opmo.",
          ".oLLLoooommmo.",
          ".oLLLLLLmmmmo.",
          "oLLLLLLLmmmmmo",
          "oLLoLLLLmmomdo",
          "oLLoLLLLmmomdo",
          "oLLLLwppwmmmdo",
          ".oLLwwwwwwmdo.",
          "..oLLwwwwmdo..",
          "...oooooooo...",
          ".............."]

# koran HUD 12x12 sudah ada di kode (pola_piksel.gd IKON_KORAN), disalin untuk ditampilkan
KORAN = ["............", "............", ".oooooooooo.", "otsttsttstto", "otsttsttstto", "otsttsttstto",
         "otsttsttstto", ".oooooooooo.", "............", "............", "............", "............"]
KORAN_PAL = {'t': hexc('#FFF3E3'), 's': hexc('#CDB9A3')}


def render(pat, pal):
    h, w = len(pat), len(pat[0])
    im = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    for y, r in enumerate(pat):
        assert len(r) == w, (r, w)
        for x, c in enumerate(r):
            if c == '.':
                continue
            im.putpixel((x, y), O if c == 'o' else pal[c])
    return im


ICONS = {}
p, pal = gen_koin(); ICONS['koin'] = (p, pal)
ICONS['reputasi'] = (BINTANG, EMAS)
p, pal = gen_ban(); ICONS['ban'] = (p, pal)
pr = dict(PERAK); pr.update(KARET); ICONS['rem'] = (REM, pr)
p, pal = gen_rantai(); ICONS['rantai'] = (p, pal)
ICONS['misi_kucing'] = (KUCING, JAHE)

# ----------------------------------------------------------------- radar ----
# Warna penanda pelanggan (revisi UI pemilik R-6, 2026-10-24: stabilo supaya lebih terlihat): (isi 'y', sorot atas 'Y'). `kuning` dipasang (bawaan); `hijau` dan `lama` hanya untuk tangkapan perbandingan
# (`--varian=hijau|lama`); selisih terang isi dan sorot dijaga < 0,05 (`tes_hud_rute_scene`: pelanggan tanpa titik terang, supaya tidak tertukar dengan tip bertitik).
VARIAN = {'kuning': ('#FFF200', '#FFF65A'), 'hijau': ('#39FF14', '#5DFF3F'), 'lama': ('#FFC94A', '#FFE08A')}
varian = 'kuning'
for arg in sys.argv[1:]:
    if arg.startswith('--varian='):
        varian = arg.split('=', 1)[1]
if varian not in VARIAN:
    raise SystemExit('varian tidak dikenal: %s (kuning, hijau, lama)' % varian)
RAD = {'y': hexc(VARIAN[varian][0]), 'Y': hexc(VARIAN[varian][1]), 'g': hexc('#56C46E'), 't': hexc('#FFF3E3'),
       'x': hexc('#E98E3F'), 'X': hexc('#FFC94A'), 'b': hexc('#969AA0')}
PENANDA = {
    'pelanggan': ["oooooooo", "oYYYYYYo", "oyyyyyyo", "oyyyyyyo", "oyyyyyyo", "oooooooo"],
    'tip':       ["oooooooo", "oggggggo", "oggttggo", "oggttggo", "oggggggo", "oooooooo"],
    'misi':      ["...oo...", "..oXXo..", ".oXxxxo.", ".oxxxxo.", "..oxxo..", "...oo..."],
    'bukan':     ["oooooooo", "obbbbbbo", "ob....bo", "ob....bo", "obbbbbbo", "oooooooo"],
}


def besar(pat):
    """Versi masuk jangkauan: +2 px, garis luar TEXT di luar garis luar lama (DESIGN_SPEC 3.4)."""
    w, h = len(pat[0]) + 2, len(pat) + 2
    g = [['.'] * w for _ in range(h)]
    for y, r in enumerate(pat):
        for x, c in enumerate(r):
            g[y + 1][x + 1] = c
    out = [row[:] for row in g]
    for y in range(h):
        for x in range(w):
            if g[y][x] != '.':
                continue
            for ex, ey in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + ex, y + ey
                if 0 <= nx < w and 0 <= ny < h and g[ny][nx] == 'o':
                    out[y][x] = 't'
                    break
    return [''.join(r) for r in out]


def sumbu(h=172):
    """Garis sumbu strip radar (revisi UI pemilik R-3): strip 12 lebar TANPA bingkai dan latar gelap, hanya satu garis OUTLINE selebar 1 px di x 6 sepanjang strip (sama dengan `RadarRute.rect_sumbu`)."""
    im = Image.new('RGBA', (12, h), (0, 0, 0, 0))
    for y in range(h):
        im.putpixel((6, y), O)
    return im


def panel_9slice():
    """Panel HUD 12x12 (DESIGN_SPEC 1.3): HUD_PANEL 84%, garis luar OUTLINE, garis dalam UI_PANEL_RAISED, sudut tumpul 3 px bertingkat."""
    pat = ["...oooooo...",
           ".oorrrrrroo.",
           ".orrffffrro.",
           "orrffffffrro"[:12],
           "orffffffffro",
           "orffffffffro",
           "orffffffffro",
           "orffffffffro",
           "orrffffffrro"[:12],
           ".orrffffrro.",
           ".oorrrrrroo.",
           "...oooooo..."]
    pal = {'r': hexc('#36281E'), 'f': (14, 10, 28, 214)}
    return render(pat, pal)



def radar_contoh(layar, out):
    """Strip radar kiri dan kanan di atas layar contoh Fase 3. Jarak rumah dan jangkauan hanya angka contoh."""
    scene = Image.open(layar).convert('RGBA')
    W = scene.width
    top, bot = 10, 182
    jangkau_radar, jangkau_lempar = 20 * 32, 7 * 32
    scene.alpha_composite(sumbu(bot - top), (4, top))
    scene.alpha_composite(sumbu(bot - top), (W - 16, top))
    # rumah sisi seberang di depan pemain (layar_fase3: pemain di y 150, rumah di -64, -192, -448)
    for dist, kind in ((214, 'pelanggan'), (342, 'tip'), (598, 'misi')):
        pat = besar(PENANDA[kind]) if dist <= jangkau_lempar else PENANDA[kind]
        im = render(pat, RAD)
        cy = bot - 2 - (dist / jangkau_radar) * (bot - top - 4)
        scene.alpha_composite(im, (10 - im.width // 2, int(round(cy - im.height / 2))))
    scene.save(out)
    return scene


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    files = {}
    for n, (p, pal) in ICONS.items():
        im = render(p, pal)
        im.save(OUT_DIR / ('ui_icon_%s.png' % n))
        files[n] = im
    names = list(ICONS)
    sh = Image.new('RGBA', (14 * len(names), 14), (0, 0, 0, 0))
    for i, n in enumerate(names):
        sh.alpha_composite(files[n], (i * 14, 0))
    sh.save(OUT_DIR / 'ui_icon_hud_sheet.png')
    kinds = list(PENANDA)
    rs = Image.new('RGBA', (10 * len(kinds), 16), (0, 0, 0, 0))
    for i, k in enumerate(kinds):
        a = render(PENANDA[k], RAD); a.save(OUT_DIR / ('ui_radar_%s.png' % k))
        b = render(besar(PENANDA[k]), RAD); b.save(OUT_DIR / ('ui_radar_%s_jangkau.png' % k))
        rs.alpha_composite(a, (i * 10 + 1, 1)); rs.alpha_composite(b, (i * 10, 8))
    rs.save(OUT_DIR / 'ui_radar_penanda.png')
    panel_9slice().save(OUT_DIR / 'ui_panel_hud_9slice.png')
    with open(OUT_DIR / 'ui_icon_hud_sheet.json', 'w') as f:
        json.dump({'sprite': 'ui_icon_hud_sheet.png', 'cell': [14, 14], 'order': names,
                   'radar': {'sprite': 'ui_radar_penanda.png', 'cell': [10, 8], 'order': kinds,
                             'rows': ['normal 8x6 (offset 1,1)', 'masuk jangkauan 10x8']},
                   'nine_slice': {'ui_panel_hud_9slice.png': 4},
                   'note': 'Usulan, tools/ui_art/hud_ikon.py. Ikon koran tetap IKON_KORAN di pola_piksel.gd; '
                           'tombol jeda digambar dari kode (tombol_jeda.gd).'}, f, indent=1, ensure_ascii=False)
        f.write('\n')
    # pratinjau: ikon x6 di atas UI_PANEL, penanda radar x8 di atas OUTLINE
    pv = Image.new('RGBA', (20 * (len(names) + 1), 20), (42, 30, 23, 255))
    for i, n in enumerate(names):
        pv.alpha_composite(files[n], (i * 20 + 3, 3))
    pv.alpha_composite(render(KORAN, KORAN_PAL), (len(names) * 20 + 4, 4))
    pv.resize((pv.width * 6, pv.height * 6), Image.NEAREST).save(OUT_DIR / 'pratinjau_ikon_hud.png')
    rv = Image.new('RGBA', (rs.width + 4, rs.height + 4), (14, 10, 28, 255))
    rv.alpha_composite(rs, (2, 2))
    rv.resize((rv.width * 8, rv.height * 8), Image.NEAREST).save(OUT_DIR / 'pratinjau_radar.png')
    layar = ROOT / 'build' / 'env_art' / 'fase3' / 'layar_fase3.png'
    if layar.exists():
        radar_contoh(layar, OUT_DIR / 'radar_contoh.png')
    print('ikon HUD ->', OUT_DIR)
    if '--salin' in sys.argv[1:]:
        ui = ROOT / 'assets' / 'sprites' / 'ui'
        ui.mkdir(parents=True, exist_ok=True)
        for f in sorted(OUT_DIR.glob('ui_*')):
            shutil.copyfile(f, ui / f.name)
        doc = ROOT / 'docs' / 'design' / 'hud'
        doc.mkdir(parents=True, exist_ok=True)
        for n in ('pratinjau_ikon_hud.png', 'pratinjau_radar.png'):
            shutil.copyfile(OUT_DIR / n, doc / n)
        if (OUT_DIR / 'radar_contoh.png').exists():
            im = Image.open(OUT_DIR / 'radar_contoh.png')
            im.resize((im.width * 2, im.height * 2), Image.NEAREST).save(doc / 'radar_contoh.png')
        print('disalin ke assets/sprites/ui/ dan docs/design/hud/')


if __name__ == '__main__':
    main()
