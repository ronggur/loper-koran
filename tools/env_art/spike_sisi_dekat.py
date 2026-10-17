"""Graybox spike rumah sisi dekat (TECH_PLAN Fase 3, run fase3c-hud-hasil AC-14, usulan): aset tiga pendekatan.

Hanya untuk scene dev `scenes/dev/spike_sisi_dekat.tscn` (dikecualikan dari paket ekspor). TIDAK memutuskan pendekatan: pemilik
memutuskan dari tangkapan layar (ROADMAP 5 "Cara menampilkan rumah di sisi dekat").

Pendekatan:
1. `rendah`  : punggung rumah apa adanya tetapi rendah (dinding 18 unit, puncak atap 31 unit, tanpa antena/toren/jemuran) dan
               kontras rendah (warna dicampur `KONTRAS_CAMPUR` ke rumput, termasuk garis luar).
2. `tembok`  : tembok belakang rendah (14 unit) di tepi kavling; rumah di belakangnya = sprite `penuh` yang digeser menjauh oleh scene.
3. `penuh`   : punggung rumah penuh seperti `fase3.py` (tanpa kotak surat di sprite: kotak surat sasaran digambar scene di pusat zona);
               scene membuatnya semi-transparan lewat aturan penutup yang ada (`PenutupPemain` / `PenerapPenutup`).
Rumah bukan pelanggan memakai varian `bukan` yang sudah ada (`assets/sprites/houses/perumahan/house_perumahan_dekat_*_bukan`) untuk
pendekatan 2 dan 3; pendekatan 1 punya varian `bukan` sendiri (rendah).

Tiap sprite ditulis bersama JSON: `ground_anchor` (titik pijak = proyeksi (0,0,0)), `tapak_ubin` [lateral_min, maju_min, lebar,
panjang] relatif titik pijak (lateral positif = menjauh dari jalan, maju positif = arah maju), dan `tinggi_ubin` (puncak benda).
Scene membaca geometri penutup dari JSON ini, jadi tapak dan tinggi hanya ditulis di satu tempat (skrip ini).

Menjalankan (dari root repo, butuh numpy dan pillow):
    python3 tools/env_art/spike_sisi_dekat.py            # render ke build/env_art/spike_sisi_dekat/
    python3 tools/env_art/spike_sisi_dekat.py --salin    # lalu salin PNG + JSON ke assets/sprites/_spike/sisi_dekat/
Hasil deterministik.
"""
import json
import shutil
import sys

import numpy as np
from PIL import Image

from engine import *          # noqa: F401,F403
from lib import *             # noqa: F401,F403
import perumahan as PR
import fase3 as F3

ROOT = PR.ROOT
OUT_DIR = PR.OUT / 'spike_sisi_dekat'
SALIN_KE = ROOT / 'assets/sprites/_spike/sisi_dekat'

UNIT_PER_UBIN = 32.0
# pendekatan 1: rendah dan kontras rendah
RENDAH_DINDING = 18
RENDAH_ATAP_BAWAH = 17
RENDAH_ATAP_PUNCAK = 31
KONTRAS_CAMPUR = 0.40          # bagian warna rumput yang dicampur ke warna rumah (0 = asli)
KONTRAS_ACUAN = np.array([0x6F, 0xAE, 0x4F], np.float32)   # P['grass'] nada dasar
# pendekatan 2: tembok belakang
TEMBOK_TEBAL = 4
TEMBOK_TINGGI = 12
TEMBOK_TUTUP = 14              # puncak tutup (cap) tembok
TEMBOK_PANJANG = 96            # sepanjang kavling 3 ubin
TEMBOK_TIANG_JARAK = 24
TEMBOK_PELANGGAN = Mat('#FBE6BE', '#F6D6A0', '#C9A979')    # krem (= P['cream']), rumah pelanggan
TEMBOK_BUKAN = F3.BUKAN_WALL


def _json(path, data):
    with open(path, 'w') as f:
        json.dump(data, f, indent=1, ensure_ascii=False)
        f.write('\n')


def _bulat(x):
    return round(float(x), 4)


def _simpan(rgba, anchor, fname, note, tapak_unit, tinggi_unit):
    """tapak_unit: (x0, x1, y0, y1) unit dunia relatif titik pijak; y dunia = -maju."""
    x0, x1, y0, y1 = tapak_unit
    Image.fromarray(rgba, 'RGBA').save(OUT_DIR / (fname + '.png'))
    _json(OUT_DIR / (fname + '.json'), {
        'sprite': fname + '.png', 'size': [int(rgba.shape[1]), int(rgba.shape[0])], 'ground_anchor': [int(a) for a in anchor],
        'tapak_ubin': [_bulat(x0 / UNIT_PER_UBIN), _bulat(-y1 / UNIT_PER_UBIN), _bulat((x1 - x0) / UNIT_PER_UBIN),
                       _bulat((y1 - y0) / UNIT_PER_UBIN)],
        'tinggi_ubin': _bulat(tinggi_unit / UNIT_PER_UBIN), 'note': note})


def _kontras_rendah(rgba):
    """Warna objek (alpha 255, termasuk garis luar) dicampur ke rumput; bayangan tanah tidak diubah."""
    hasil = rgba.copy()
    obj = hasil[..., 3] == 255
    rgb = hasil[obj, :3].astype(np.float32)
    hasil[obj, :3] = np.clip(rgb * (1 - KONTRAS_CAMPUR) + KONTRAS_ACUAN * KONTRAS_CAMPUR, 0, 255).astype(np.uint8)
    return hasil


def house_near_rendah(s, yc, wall, roof, seed=0, pelanggan=True, mundur=0):
    """Punggung rumah sisi dekat rendah (satu lantai pendek), atap dari seed seperti `fase3.house_near_v`, tanpa antena, toren,
    jemuran, dan kotak surat."""
    if pelanggan:
        W, R, glass = P[wall], P[roof], P['glass']
    else:
        W, R, glass = F3.BUKAN_WALL, F3.BUKAN_ROOF, F3.TIRAI
    x0, x1 = PR.NX0 + mundur, PR.NX1 + mundur
    y0, y1 = yc - 40, yc + 40
    feats = [
        dict(face='+x', u=(yc - 6, yc + 4), v=(2, 15), mat=1, frame=2, kind='door', handle=4),
        dict(face='+x', u=(yc + 14, yc + 26), v=(9, 15), mat=3, frame=2, kind='nako'),
        dict(face='+x', u=(yc - 30, yc - 20), v=(9, 15), mat=3, frame=2, kind='nako'),
        dict(face='+y', u=(x0 + 22, x0 + 36), v=(8, 15), mat=3, frame=2),
        dict(face='+y', u=(x0 + 52, x0 + 66), v=(8, 15), mat=3, frame=2),
    ]
    mats = [W, P['wood'] if pelanggan else P['wood_dk'], P['white'] if pelanggan else P['conc'], glass, P['metal_dk'], P['conc']]
    s.add(box(x0, x1, y0, y1, 0, RENDAH_DINDING, mats, wall_tex(feats, plinth=(3.5, 5))))
    rt = roof_tex('genteng', seed + 9, wall=True)
    k = seed % 3
    zb, zt = RENDAH_ATAP_BAWAH, RENDAH_ATAP_PUNCAK
    if k == 0:
        s.add(hip(x0 - 5, x1 + 5, y0 - 5, y1 + 5, zb, zt, mats=[R, W], tex=rt))
    elif k == 1:
        s.add(gable(x0 - 4, x1 + 4, y0 - 5, y1 + 5, zb + 1, zt, 'x', mats=[R, W], tex=rt))
        s.add(gable(x0, x1, y0, y1, zb + 1, zt - 3, 'x', mats=W, part=s.prims[-1].part))
    else:
        s.add(gable(x0 - 5, x1 + 5, y0 - 4, y1 + 4, zb + 1, zt, 'y', mats=[R, W], tex=rt))
        s.add(gable(x0, x1, y0, y1, zb + 1, zt - 2, 'y', mats=W, part=s.prims[-1].part))
    # kanopi seng pendek di atas pintu belakang
    s.add(shed(x1, x1 + 10, yc - 12, yc + 10, 16, 14, '+x', 1.5, mats=P['metal'], tex=roof_tex('seng')))


def tembok_belakang(s, pelanggan=True):
    """Tembok belakang rendah sepanjang kavling, berpusat di (0, 0): badan plester, tutup beton, tiang tiap `TEMBOK_TIANG_JARAK`."""
    mat = TEMBOK_PELANGGAN if pelanggan else TEMBOK_BUKAN
    h = TEMBOK_PANJANG / 2
    t = TEMBOK_TEBAL / 2
    s.add(box(-t, t, -h, h, 0, TEMBOK_TINGGI, [mat, P['conc']], wall_tex([], plinth=(2.0, 1))))
    s.add(box(-t - 0.5, t + 0.5, -h, h, TEMBOK_TINGGI, TEMBOK_TUTUP, P['conc']))
    y = -h
    while y <= h + 0.01:
        s.add(box(-t - 1, t + 1, y - 1.5, y + 1.5, 0, TEMBOK_TUTUP + 1, P['conc']))
        y += TEMBOK_TIANG_JARAK


def _tapak_rumah():
    # badan rumah dari house_near_v sesudah digeser ke tengah (cx): x simetris di sekitar 0, y = yc +- 40; atap menjorok 5 unit.
    lebar = PR.NX1 - PR.NX0
    return (-lebar / 2 - 5, lebar / 2 + 5, -45, 45)


def ekspor():
    F3.pasang_antena_varian()
    for nm, seed, wall, roof, bel, antk in F3.RUMAH_DEKAT:
        cx = -(PR.NX0 + PR.NX1) / 2 - F3.MUNDUR_DEKAT
        # 3. penuh: sama dengan fase3 (mundur, toren/jemuran, antena), tanpa kotak surat di sprite
        def b(s, seed=seed, wall=wall, roof=roof, bel=bel, antk=antk):
            st = len(s.prims)
            F3.house_near_v(s, 0, wall, roof, seed=seed, pelanggan=True, kotak=False, mundur=F3.MUNDUR_DEKAT, belakang=bel,
                            antena_kind=antk)
            shift_prims(s.prims[st:], cx, 0)
            s.ropes = [(p0 + np.array([cx, 0, 0]), p1 + np.array([cx, 0, 0])) for p0, p1 in getattr(s, 'ropes', [])]
            F3._no_cast_antena(s, st)
        a, o, _, _ = F3.render_sprite(b, pad=4, extra_px=(34, 18))
        _simpan(a, o, 'spike_dekat_penuh_%s_pelanggan' % nm,
                'Spike sisi dekat pendekatan 3 (usulan, tools/env_art/spike_sisi_dekat.py): punggung rumah penuh seperti '
                'fase3.py, tanpa kotak surat di sprite. Tinggi = puncak atap (antena tidak dihitung).', _tapak_rumah(), 56)
        # 1. rendah dan kontras rendah, pelanggan dan bukan
        for pel in (True, False):
            def r(s, seed=seed, wall=wall, roof=roof, pel=pel):
                st = len(s.prims)
                house_near_rendah(s, 0, wall, roof, seed=seed, pelanggan=pel, mundur=F3.MUNDUR_DEKAT)
                shift_prims(s.prims[st:], cx, 0)
            a, o, _, _ = F3.render_sprite(r, pad=4, extra_px=(20, 10))
            _simpan(_kontras_rendah(a), o, 'spike_dekat_rendah_%s_%s' % (nm, 'pelanggan' if pel else 'bukan'),
                    'Spike sisi dekat pendekatan 1 (usulan): punggung rumah rendah (dinding %d, atap %d unit) dan kontras rendah '
                    '(%d%% warna rumput).' % (RENDAH_DINDING, RENDAH_ATAP_PUNCAK, round(KONTRAS_CAMPUR * 100)),
                    _tapak_rumah(), RENDAH_ATAP_PUNCAK)
    for pel in (True, False):
        a, o, _, _ = F3.render_sprite(lambda s, pel=pel: tembok_belakang(s, pel), pad=4, extra_px=(12, 6))
        t = TEMBOK_TEBAL / 2 + 1
        _simpan(a, o, 'spike_dekat_tembok_%s' % ('pelanggan' if pel else 'bukan'),
                'Spike sisi dekat pendekatan 2 (usulan): tembok belakang rendah %d unit sepanjang kavling; rumah di belakangnya '
                'digambar scene dari sprite pendekatan 3 yang digeser menjauh.' % TEMBOK_TUTUP,
                (-t, t, -TEMBOK_PANJANG / 2, TEMBOK_PANJANG / 2), TEMBOK_TUTUP + 1)


def salin():
    SALIN_KE.mkdir(parents=True, exist_ok=True)
    for p in sorted(OUT_DIR.glob('spike_dekat_*')):
        if p.suffix in ('.png', '.json'):
            shutil.copyfile(p, SALIN_KE / p.name)


if __name__ == '__main__':
    import time
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    t0 = time.time()
    ekspor()
    print('render', round(time.time() - t0, 1), 'detik ->', OUT_DIR)
    if '--salin' in sys.argv[1:]:
        salin()
        print('disalin ke', SALIN_KE)
