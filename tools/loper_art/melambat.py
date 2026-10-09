"""Sprite melambat (usulan): lebih lambat dari santai.

Frame gambarnya sama persis dengan santai (5 arah x 4 frame kayuh); yang
berbeda hanya kecepatan putar, 4 fps (santai 8 fps). Pose dan bentuk badan
tidak diubah supaya topi dan siluet tetap sama dengan santai.

    python3 tools/loper_art/melambat.py --sheet docs/design/character/loper_agen/loper_agen.png --out build/loper_art/melambat

Hasil: loper_agen_melambat.png (4x5, sel 46x58), loper_agen_melambat.json,
preview/prev_melambat_<arah>.gif (x4 di atas latar abu, 250 ms per frame).
"""
import argparse, json, os
from PIL import Image

CW, CH = 46, 58
HEADINGS = ['normal', 'serong_kanan', 'kanan', 'serong_kiri', 'kiri']
FPS = 4


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--sheet', default='docs/design/character/loper_agen/loper_agen.png')
    ap.add_argument('--out', default='build/loper_art/melambat')
    a = ap.parse_args()
    sh = Image.open(a.sheet).convert('RGBA')
    sheet = sh.crop((0, 0, 4 * CW, 5 * CH))  # baris santai 0-4
    os.makedirs(os.path.join(a.out, 'preview'), exist_ok=True)
    sheet.save(os.path.join(a.out, 'loper_agen_melambat.png'))
    anims = []
    for ri, h in enumerate(HEADINGS):
        frames = []
        for f in range(4):
            im = Image.new('RGBA', (66, 68), (107, 103, 113, 255))
            im.alpha_composite(sheet.crop((f * CW, ri * CH, (f + 1) * CW, (ri + 1) * CH)), (10, 5))
            frames.append(im.resize((264, 272), Image.NEAREST).convert('RGB'))
        frames[0].save(os.path.join(a.out, 'preview', f'prev_melambat_{h}.gif'), save_all=True,
                       append_images=frames[1:], duration=1000 // FPS, loop=0)
        anims.append({'name': f'melambat_{h}', 'speed': 'melambat', 'heading': h, 'row': ri,
                      'source': f'santai row {ri} frame 0-3, tanpa perubahan gambar',
                      'fps': FPS, 'loop': True,
                      'regions': [[f * CW, ri * CH, CW, CH] for f in range(4)]})
    meta = {'sprite': 'loper_agen_melambat.png', 'cell': [CW, CH], 'columns': 4, 'rows': 5,
            'ground_anchor': [23, 46], 'godot_offset': [0.0, -17.0],
            'status': 'usulan; frame sama persis dengan santai, hanya diputar 4 fps (santai 8 fps)',
            'animations': anims}
    json.dump(meta, open(os.path.join(a.out, 'loper_agen_melambat.json'), 'w'), indent=1, ensure_ascii=False)


if __name__ == '__main__':
    main()
