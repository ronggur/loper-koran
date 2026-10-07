"""Sprite produksi pemain: 3 kecepatan x 5 arah x 4 frame kayuh.

    pip install numpy pillow
    python3 tools/loper_art/produce.py --out build/loper_art
    python3 tools/loper_art/produce.py --out build/loper_art --variant e   # varian baju lain (belum diaudit)

Menulis: <nama>.png (sheet 1x), <nama>.json (metadata), <nama>_frames.tres (SpriteFrames Godot 4),
preview/<nama>_x4.png, preview/prev_<animasi>.gif. Nama default `loper_agen`.
Hasil sudah dicek sama persis dengan sheet di docs/design/character/loper_agen/ (2026-10-07).
"""
import argparse
import json
import os
import numpy as np
from PIL import Image
import iso
from iso import render
from base import BASE, SPEED, SPEED_LEAN, HEADINGS, ground
from loper import build, ALL

# sudut pedal kanan per frame, berputar MAJU (searah jarum jam dilihat dari kanan)
PHI = [-40, 230, 140, 50]
# saat ngebut hanya sepeda yang bergoyang; badan pengendara stabil supaya kepala tidak bergetar
ROCK = {'santai': [0, 0, 0, 0], 'cepat': [0, 0, 0, 0], 'ngebut': [-5, 0, 5, 0]}
FPS = {'santai': 8, 'cepat': 10, 'ngebut': 12}
SPEEDS = ['santai', 'cepat', 'ngebut']
DIRS = [h[0] for h in HEADINGS]
BIG, CX, CY = 150, 75, 108
SLUG = {'a': 'merah_klasik', 'b': 'garis_biru', 'c': 'jaket_hijau', 'd': 'kaus_bola',
        'e': 'polo_kuning', 'f': 'batik', 'g': 'hoodie_abu', 'h': 'agen'}


def main():
    ap = argparse.ArgumentParser(description='Render sprite produksi pemain Loper Koran.')
    ap.add_argument('--out', default='build/loper_art', help='folder hasil')
    ap.add_argument('--variant', default='h', choices=sorted(SLUG), help='id varian baju (h = Kemeja Agen)')
    ap.add_argument('--res-dir', default='res://assets/sprites/loper', help='folder sheet di project Godot')
    ap.add_argument('--no-preview', action='store_true', help='lewati GIF dan pratinjau x4')
    args = ap.parse_args()

    variant = BASE if args.variant == 'h' else [v for v in ALL if v['id'] == args.variant][0]
    name = 'loper_' + SLUG[args.variant]
    out = args.out
    os.makedirs(out, exist_ok=True)

    frames = {}
    for sp in SPEEDS:
        for key, yaw, lean, steer in HEADINGS:
            for f, phi in enumerate(PHI):
                iso.POSE['yaw'] = yaw
                iso.POSE['lean'] = lean
                M, sh = build(dict(variant, steer=steer, bike_roll=ROCK[sp][f], **SPEED[sp]), phi)
                c = iso.L2W(np.array([8.5, 0.0, 0.0]))
                frames[(sp, key, f)] = render(M, BIG, BIG, CX - (c[0] - c[1]), CY - (c[0] + c[1]) / 2, shadow_pts=sh)
    iso.POSE['yaw'] = iso.POSE['lean'] = 0

    alpha = np.zeros((BIG, BIG), bool)
    for a in frames.values():
        alpha |= a[..., 3] > 0
    ys, xs = np.where(alpha)
    x0, y0 = xs.min() - 1, ys.min() - 1
    CW, CH = int(xs.max() + 2 - x0), int(ys.max() + 2 - y0)
    CW += CW % 2; CH += CH % 2
    AX, AY = int(CX - x0), int(CY - y0)

    sheet = Image.new('RGBA', (CW * 4, CH * len(SPEEDS) * len(DIRS)), (0, 0, 0, 0))
    anims = []
    row = 0
    for sp in SPEEDS:
        for key in DIRS:
            regions = []
            for f in range(4):
                cell = Image.fromarray(frames[(sp, key, f)][y0:y0 + CH, x0:x0 + CW], 'RGBA')
                sheet.alpha_composite(cell, (f * CW, row * CH))
                regions.append([f * CW, row * CH, CW, CH])
            anims.append(dict(name=f'{sp}_{key}', speed=sp, heading=key, row=row, fps=FPS[sp], loop=True, regions=regions))
            row += 1
    sheet.save(f'{out}/{name}.png')

    meta = dict(
        sprite=f'{name}.png', cell=[CW, CH], columns=4, rows=row,
        ground_anchor=[AX, AY],
        godot_offset=[CW / 2 - AX, CH / 2 - AY],
        note='Ground anchor = titik tengah sepeda di tanah. Dengan centered=true, pakai offset ini supaya origin node ada di tanah (cocok untuk Y-sort).',
        headings={'normal': 'lurus, kanan atas layar', 'serong_kanan': 'kanan layar', 'kanan': 'kanan bawah (sisi dekat)',
                  'serong_kiri': 'atas layar', 'kiri': 'kiri atas (sisi seberang)'},
        animations=anims,
    )
    json.dump(meta, open(f'{out}/{name}.json', 'w'), indent=1, ensure_ascii=False)

    subs, anim_txt, sid = [], [], 0
    for a in anims:
        fr = []
        for (x, y, w, h) in a['regions']:
            sid += 1
            subs.append(f'[sub_resource type="AtlasTexture" id="AtlasTexture_{sid}"]\natlas = ExtResource("1_sheet")\nregion = Rect2({x}, {y}, {w}, {h})\n')
            fr.append('{\n"duration": 1.0,\n"texture": SubResource("AtlasTexture_%d")\n}' % sid)
        anim_txt.append('{\n"frames": [' + ', '.join(fr) + '],\n"loop": true,\n"name": &"%s",\n"speed": %.1f\n}' % (a['name'], a['fps']))
    tres = (f'[gd_resource type="SpriteFrames" load_steps={sid + 2} format=3]\n\n'
            f'[ext_resource type="Texture2D" path="{args.res_dir}/{name}.png" id="1_sheet"]\n\n'
            + '\n'.join(subs) + '\n[resource]\nanimations = [' + ', '.join(anim_txt) + ']\n')
    open(f'{out}/{name}_frames.tres', 'w').write(tres)

    if not args.no_preview:
        pv = f'{out}/preview'
        os.makedirs(pv, exist_ok=True)
        sheet.resize((sheet.width * 4, sheet.height * 4), Image.NEAREST).save(f'{pv}/{name}_x4.png')
        GW, GH = CW + 20, CH + 10
        for a in anims:
            gif = []
            for f in range(4):
                g = Image.fromarray(ground(GW, GH, 10 + AX + 0.5, 5 + AY), 'RGBA')
                cell = sheet.crop((f * CW, a['row'] * CH, (f + 1) * CW, (a['row'] + 1) * CH))
                g.alpha_composite(cell, (10, 5))
                gif.append(g.convert('RGB').resize((GW * 4, GH * 4), Image.NEAREST))
            gif[0].save(f'{pv}/prev_{a["name"]}.gif', save_all=True, append_images=gif[1:],
                        duration=int(1000 / a['fps']), loop=0)

    print(f'{name}: {len(frames)} frame, sel {CW}x{CH}, titik pijak ({AX}, {AY}), sheet {sheet.size[0]}x{sheet.size[1]} -> {out}')


if __name__ == '__main__':
    main()
