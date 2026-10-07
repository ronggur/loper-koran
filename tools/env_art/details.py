"""Close-up loops of lively roadside details: jemuran, ayam, asap warung (usulan)."""
import math
import numpy as np
from PIL import Image
from engine import *
from lib import *
from kampung import K
from perumahan import OUT

OUTD = str(OUT) + '/'


def yard_region(x, y):
    g = vnoise(x, y, 14, 3) > 0.5
    mi = np.where(g, 1, 0)
    sh = 1 + np.where(g, grass_tufts(x, y, 2), speckle(x, y, 4, 0.06, 0.08, 2))
    return mi, sh


def gang_floor(x, y):
    sh = 1 + speckle(x, y, 2, 0.04, 0.05, 1) + np.where(np.mod(y, 40) < 0.9, 1, 0)
    return np.zeros(len(x), int), sh


def jemuran(t):
    s = Scene(112, 72, 56, 50)
    s.add(ground_prim(yard_region, [K['tanah'], P['grass']], x=(-200, 200), y=(-200, 200)))
    for px in (-34, 34):
        s.add(box(px - 0.8, px + 0.8, -0.8, 0.8, 0, 27, K['kayu_dk']))
    items = [(0.13, 10, 17, Mat('#F2C46B', '#D8A040', '#9A6A22'), 'sarung'),
             (0.34, 7, 10, Mat('#F7F2E8', '#E8E0CE', '#B8AE98'), 'kaus'),
             (0.53, 9, 12, Mat('#E8889A', '#C8687A', '#904452'), 'handuk'),
             (0.71, 7, 13, Mat('#7F9EC0', '#5E7EA2', '#40597A'), 'celana'),
             (0.88, 6, 9, Mat('#7FC4A0', '#4FA47A', '#2F7452'), 'kaus')]
    clothes_line(s, (-34, 0, 26), (34, 0, 26), items, sway=0.24, t=t)
    s.render(TIMES['siang'])
    img = finish_with_sprites(s, [])
    draw_ropes(s, img)
    return img


def ayam(t):
    s = Scene(112, 64, 56, 34)
    s.add(ground_prim(yard_region, [K['tanah'], P['grass']], x=(-200, 200), y=(-200, 200)))
    chicken(s, -18, 8, yaw=0.5, phase=t * 2, mode='walk')
    chicken(s, 6, -8, yaw=-1.0, phase=t, mode='peck', col=Mat('#C98A5A', '#A86A3E', '#6E4428'),
            tail=Mat('#4A5A50', '#2E3C34', '#1C2620'))
    chicken(s, 20, 14, yaw=2.4, phase=(t + 0.5) % 1, mode='peck', col=Mat('#E0794E', '#B9552F', '#7C3820'),
            tail=Mat('#3E6A5A', '#24483C', '#142A22'), size=1.15)
    s.render(TIMES['siang'])
    return finish_with_sprites(s, [])


def asap(t, tname='siang'):
    s = Scene(96, 96, 34, 78)
    s.add(ground_prim(gang_floor, [P['asph']], x=(-200, 200), y=(-200, 200)))
    s.add(box(-8, 8, -6, 6, 0, 10, K['kayu_dk']))
    s.add(box(-6, 6, -5, 5, 10, 13, P['metal_dk']))
    s.add(ellip((0, 0, 14), (6, 6, 2.6), P['metal_dk'], zmin=13))
    # api kecil di bawah wajan
    flame = [Mat('#FFE08A', '#FFC94A', '#E98E3F', glow='#FFD06A'), Mat('#7FB2E0', '#5F96C8', '#3E6A96')]
    s.add(box(-4, 4, -1, 1, 12, 13.2, flame[1], outline=False))
    s.render(TIMES[tname])
    img = finish_with_sprites(s, [])
    tint = np.clip(TIMES[tname].sun, 0.5, 1.1)
    smoke(s, img, (0, 0, 15), t, n=12, rise=54, drift=(6, -12), tint=tint, seed=2)
    return img


def export(name, fn, n, scale, ms):
    frames = [np.clip(fn(i / n), 0, 255).astype(np.uint8) for i in range(n)]
    ims = [Image.fromarray(f, 'RGB').resize((f.shape[1] * scale, f.shape[0] * scale), Image.NEAREST) for f in frames]
    ims[0].save(OUTD + f'detail_{name}.webp', save_all=True, append_images=ims[1:], duration=ms, loop=0, lossless=True)
    # frame strip at x3 with 6 px gaps
    h, w = frames[0].shape[:2]
    sc = 3
    strip = Image.new('RGB', (n * (w * sc + 6) - 6, h * sc), (42, 30, 23))
    for i, f in enumerate(frames):
        strip.paste(Image.fromarray(f, 'RGB').resize((w * sc, h * sc), Image.NEAREST), (i * (w * sc + 6), 0))
    strip.save(OUTD + f'strip_{name}.png')
    ims[0].save(OUTD + f'detail_{name}_f0.png')
    return ims[0].size, strip.size


if __name__ == '__main__':
    print(export('jemuran', jemuran, 8, 5, 125))
    print(export('ayam', ayam, 8, 5, 125))
    print(export('asap', asap, 12, 5, 110))
