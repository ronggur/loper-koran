import sys, time
import numpy as np
from PIL import Image
from kampung import render, OUT
N = 8
frames = []
t0 = time.time()
for i in range(N):
    im, s = render('sore', i / N, i % 4, 1)
    frames.append(im)
print('render', round(time.time() - t0, 1))
big = [f.resize((1920, 1080), Image.NEAREST) for f in frames]
big[0].save(f'{OUT}/hero_sore.webp', save_all=True, append_images=big[1:], duration=125, loop=0, lossless=True, method=4)
big[0].save(f'{OUT}/hero_sore_f0.png')
frames[0].save(f'{OUT}/hero_sore_1x.png')
import os
print(os.path.getsize(f'{OUT}/hero_sore.webp') // 1024, 'KB')
