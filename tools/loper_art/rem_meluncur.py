"""Sprite meluncur dan rem (usulan), dari frame kayuh santai.

Meluncur (ART_DIRECTION 3.4): pedal datar, kaki diam. Dasarnya frame santai 2 (engkol mendatar),
badan atas turun 1 px bergantian supaya terlihat bernapas.
Rem: dasar yang sama, badan atas mundur (ke arah belakang sepeda) lalu turun 1 px bergantian
seperti bergetar saat menahan.

Badan atas digeser **kaku** (tanpa meregang) supaya bentuk topi dan kepala tidak berubah dari santai.

    python3 tools/loper_art/rem_meluncur.py --out build/loper_art/rem_meluncur

Hasil: loper_agen_meluncur.png, loper_agen_rem.png (4 kolom x 5 baris, sel 46x58), JSON, dan
preview/prev_<animasi>_<arah>.gif (x4 di atas latar abu).
"""
import argparse, json, os
from PIL import Image

CW, CH = 46, 58
HEADINGS = ['normal', 'serong_kanan', 'kanan', 'serong_kiri', 'kiri']
BASE_FRAME = 2  # engkol mendatar
HIP = {'normal': 29, 'serong_kanan': 28, 'kanan': 28, 'serong_kiri': 29, 'kiri': 29}
BACK = {'normal': (-1, 0), 'serong_kanan': (-1, 0), 'kanan': (-1, 0), 'serong_kiri': (0, 1), 'kiri': (1, 0)}
# warna sepeda dan bayangan, tidak ikut bergeser bersama pengendara
BIKE = {(70, 110, 80), (49, 77, 56), (42, 30, 23), (103, 99, 109), (95, 91, 102), (150, 154, 160),
        (61, 70, 73), (216, 212, 220), (169, 162, 174), (34, 30, 38), (255, 201, 74), (119, 53, 39),
        (109, 67, 52)}
OUTL = (14, 10, 28)

# (geser mundur, geser turun) per frame
MELUNCUR = [(0, 0), (0, 0), (0, 1), (0, 1)]
REM = [(1, 0), (1, 0), (1, 1), (1, 1)]
MELUNCUR_FPS, REM_FPS = 4, 8


def rider_mask(px, h):
    H = HIP[h]
    r = set()
    for y in range(H):
        for x in range(CW):
            p = px[x, y]
            if p[3] > 200 and p[:3] not in BIKE and p[:3] != OUTL:
                r.add((x, y))
    o = set()
    for y in range(H):
        for x in range(CW):
            p = px[x, y]
            if p[3] > 200 and p[:3] == OUTL and any((x + dx, y + dy) in r for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
                o.add((x, y))
    # garis luar yang menyambung ke garis luar pengendara (mis. tonjolan 2x2 di topi) ikut bergeser,
    # dua langkah saja supaya garis luar roda tidak ikut
    for _ in range(2):
        tambah = set()
        for y in range(H):
            for x in range(CW):
                p = px[x, y]
                if p[3] > 200 and p[:3] == OUTL and (x, y) not in o and (x, y) not in r \
                        and any((x + dx, y + dy) in o for dx in (-1, 0, 1) for dy in (-1, 0, 1)):
                    tambah.add((x, y))
        o |= tambah
    return r | o


def shifted(cell, h, back, down):
    px = cell.load()
    m = rider_mask(px, h)
    bx, by = BACK[h]
    dx, dy = bx * back, by * back + down
    out = Image.new('RGBA', (CW, CH), (0, 0, 0, 0))
    op = out.load()
    for y in range(CH):
        for x in range(CW):
            if (x, y) not in m:
                op[x, y] = px[x, y]
    written = set()
    for (x, y) in m:
        nx, ny = x + dx, y + dy
        if 0 <= nx < CW and 0 <= ny < CH:
            op[nx, ny] = px[x, y]
            written.add((nx, ny))
    for (x, y) in m:  # piksel pengendara yang ditinggalkan: pakai sepeda di belakangnya kalau ada
        if (x, y) in written:
            continue
        best = None
        for r in (1, 2):
            for ddy in range(-r, r + 1):
                for ddx in range(-r, r + 1):
                    q = (x + ddx, y + ddy)
                    if 0 <= q[0] < CW and 0 <= q[1] < CH and q not in m and px[q][3] > 200 and px[q][:3] in BIKE:
                        best = px[q]
            if best:
                break
        op[x, y] = best if best else (0, 0, 0, 0)
    return out


def build(sh, name, poses, fps, out):
    sheet = Image.new('RGBA', (4 * CW, 5 * CH), (0, 0, 0, 0))
    anims = []
    for ri, h in enumerate(HEADINGS):
        base = sh.crop((BASE_FRAME * CW, ri * CH, (BASE_FRAME + 1) * CW, (ri + 1) * CH))
        frames = []
        for f, (back, down) in enumerate(poses):
            c = shifted(base, h, back, down)
            sheet.alpha_composite(c, (f * CW, ri * CH))
            im = Image.new('RGBA', (66, 68), (107, 103, 113, 255))
            im.alpha_composite(c, (10, 5))
            frames.append(im.resize((264, 272), Image.NEAREST).convert('RGB'))
        frames[0].save(os.path.join(out, 'preview', f'prev_{name}_{h}.gif'), save_all=True,
                       append_images=frames[1:], duration=1000 // fps, loop=0)
        anims.append({'name': f'{name}_{h}', 'heading': h, 'row': ri, 'fps': fps, 'loop': True,
                      'source': f'santai row {ri} frame {BASE_FRAME}',
                      'regions': [[f * CW, ri * CH, CW, CH] for f in range(4)]})
    sheet.save(os.path.join(out, f'loper_agen_{name}.png'))
    meta = {'sprite': f'loper_agen_{name}.png', 'cell': [CW, CH], 'columns': 4, 'rows': 5,
            'ground_anchor': [23, 46], 'godot_offset': [0.0, -17.0],
            'status': 'usulan; dari frame santai 2, badan atas digeser kaku', 'animations': anims}
    json.dump(meta, open(os.path.join(out, f'loper_agen_{name}.json'), 'w'), indent=1, ensure_ascii=False)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--sheet', default='docs/design/character/loper_agen/loper_agen.png')
    ap.add_argument('--out', default='build/loper_art/rem_meluncur')
    a = ap.parse_args()
    sh = Image.open(a.sheet).convert('RGBA')
    os.makedirs(os.path.join(a.out, 'preview'), exist_ok=True)
    build(sh, 'meluncur', MELUNCUR, MELUNCUR_FPS, a.out)
    build(sh, 'rem', REM, REM_FPS, a.out)


if __name__ == '__main__':
    main()
