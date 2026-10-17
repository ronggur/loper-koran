"""Lampu jalan dan pohon (usulan).

Lampu: tujuh jenis, masing-masing mati dan nyala, lengan menghadap jalan dari sisi seberang (ke kanan bawah) atau
dari sisi dekat (ke kiri atas). Pohon: lima jenis yang sudah ada di lib/kampung/districts dirender sebagai sprite
tunggal, ditambah enam jenis baru. Layar contoh memakai ubin dari ubin_perumahan.py (tata letak game), siang
dan malam.

    python3 tools/env_art/lampu_pohon.py        # ke build/env_art/lampu_pohon/
"""
import json
import math

import numpy as np
from PIL import Image

from engine import *          # noqa: F401,F403
from lib import *             # noqa: F401,F403
from lib import _limb, _leaf_tex
import perumahan as PR
import fase3 as F3
import kampung as KP
import districts as DI
import ubin_perumahan as UB

OUT_DIR = PR.OUT / 'lampu_pohon'
OUT_DIR.mkdir(parents=True, exist_ok=True)


def _json(path, data):
    with open(path, 'w') as f:
        json.dump(data, f, indent=1, ensure_ascii=False)
        f.write('\n')


# ------------------------------------------------- transformasi (sama dengan kendaraan.py) ----
def rz(deg):
    a = math.radians(deg)
    c, s_ = round(math.cos(a), 12), round(math.sin(a), 12)
    return np.array([[c, -s_, 0], [s_, c, 0], [0, 0, 1.0]])


def geser(prims, v):
    v = np.asarray(v, float)
    for p in prims:
        p.planes = [(n, d + float(n @ v)) for n, d in p.planes]
        if p.quad is not None:
            if p.quad[0] == 'ellip':
                _, c, R, r = p.quad
                p.quad = ('ellip', c + v, R, r)
            else:
                _, ax, c2, r = p.quad
                o = [i for i in range(3) if i != ax]
                p.quad = ('cyl', ax, c2 + v[o], r)
        p.lo, p.hi = p.lo + v, p.hi + v
        if p.tex is not None:
            f = p.tex
            p.tex = (lambda Pw, Nw, f=f, v=v: f(Pw - v, Nw))


def xform_into(s, tmp, A, t):
    """dunia = A @ lokal + t (A rotasi kelipatan 90 derajat di sumbu z)."""
    t = np.asarray(t, float)
    for p in tmp.prims:
        p.planes = [(A @ n, d + float((A @ n) @ t)) for n, d in p.planes]
        if p.quad is not None:
            if p.quad[0] == 'ellip':
                _, c, R, r = p.quad
                p.quad = ('ellip', A @ c + t, R @ A.T, r)
            else:
                _, ax, c2, r = p.quad
                e = np.zeros(3); e[ax] = 1
                c3 = np.zeros(3); o = [i for i in range(3) if i != ax]; c3[o] = c2
                ne = A @ e
                nax = int(np.argmax(np.abs(ne)))
                w = A @ c3 + t
                no = [i for i in range(3) if i != nax]
                p.quad = ('cyl', nax, w[no], r)
        cs = np.array([[x, y, z] for x in (p.lo[0], p.hi[0]) for y in (p.lo[1], p.hi[1]) for z in (p.lo[2], p.hi[2])])
        w = cs @ A.T + t
        p.lo, p.hi = w.min(0), w.max(0)
        if p.tex is not None:
            f = p.tex
            p.tex = (lambda Pw, Nw, f=f: f((Pw - t) @ A, Nw @ A))
        s.prims.append(p)


def pack(frames, names, fname, meta):
    left = max(o[0] for _, o in frames); top = max(o[1] for _, o in frames)
    right = max(a.shape[1] - o[0] for a, o in frames); bottom = max(a.shape[0] - o[1] for a, o in frames)
    cw, ch = left + right, top + bottom
    sheet = Image.new('RGBA', (cw * len(frames), ch), (0, 0, 0, 0))
    for i, (a, o) in enumerate(frames):
        sheet.alpha_composite(Image.fromarray(a, 'RGBA'), (i * cw + left - o[0], top - o[1]))
    sheet.save(OUT_DIR / (fname + '.png'))
    m = {'sprite': fname + '.png', 'cell': [cw, ch], 'columns': len(frames), 'rows': 1,
         'ground_anchor': [left, top], 'frames': names}
    m.update(meta)
    _json(OUT_DIR / (fname + '.json'), m)
    return sheet, (cw, ch)


# ======================================================================= lampu ====
TIANG = Mat('#7A7684', '#5F5B66', '#3D3A46')
TIANG_HIJAU = Mat('#6E9E84', '#4E7A64', '#34544A')
BETON = Mat('#D6D0C8', '#B4AEA6', '#8A847C')
BAMBU = Mat('#EAD48E', '#C9A85A', '#8A6E34')
SENG = Mat('#C4C0C8', '#969AA0', '#67636D')
PANEL = Mat('#5E7AA8', '#3E5688', '#26385E')
KACA_LAMPU = Mat('#E4EEF2', '#C2D2DA', '#94A6B0')
LAMPU_MATI = Mat('#C4CAD4', '#9AA2B0', '#6E7686')
LAMPU_NYALA = Mat('#FFFFFF', '#FFFBEA', '#FFF0C0', glow='#FFE9A8')
LAMPU_NYALA_HANGAT = Mat('#FFFBEA', '#FFE89A', '#FFD060', glow='#FFD27A')
WARNA_CAHAYA = {'putih': '#FFF2D0', 'hangat': '#FFD27A'}


def _cyl_tegak(s, x, y, r, z0, z1, mat, part=None):
    s.add(cyl((x, y), r, z0, z1, mats=mat, part=part))
    return s.prims[-1].part


def _tiang_meruncing(s, x, y, z0, z1, r0, r1, mat, n=6):
    pid = None
    for i in range(n):
        a, b = z0 + (z1 - z0) * i / n, z0 + (z1 - z0) * (i + 1) / n + 0.3
        r = r0 + (r1 - r0) * (i + 0.5) / n
        pid = _cyl_tegak(s, x, y, r, a, b, mat, pid)
    return pid


def _lengkung(s, a, b, tinggi, r, mat, pid, n=5):
    """Batang melengkung dari a ke b dengan puncak busur `tinggi` di atas garis lurusnya."""
    a, b = np.asarray(a, float), np.asarray(b, float)
    pts = [a + (b - a) * t + np.array([0, 0, tinggi * 4 * t * (1 - t)]) for t in np.linspace(0, 1, n + 1)]
    for p, q in zip(pts[:-1], pts[1:]):
        _limb(s, p, q, r, mat, pid)
    return pts


def lampu(s, jenis, nyala=False):
    """Lampu di koordinat lokal: kaki tiang di (0, 0), lengan ke +x (ke arah jalan). Mengembalikan titik cahaya."""
    L = LAMPU_NYALA if nyala else LAMPU_MATI
    LH = LAMPU_NYALA_HANGAT if nyala else LAMPU_MATI
    titik = []
    if jenis == 'lengan':                 # PJU perumahan: tiang besi, lengan lurus pendek (bentuk lib.lamp_post)
        h = 56
        pid = _cyl_tegak(s, 0, 0, 1.4, 0, h, P['metal_dk'])
        _cyl_tegak(s, 0, 0, 2.2, 0, 4, P['metal_dk'], pid)
        s.add(box(0, 12, -0.8, 0.8, h - 2, h, P['metal_dk'], part=pid))
        s.add(box(9, 15, -2, 2, h - 4, h - 1, [P['metal_dk'], L], lambda Pw, Nw: (np.where(Pw[:, 2] < h - 3.2, 1, 0), 0), part=pid))
        titik.append(((12, 0, h - 6), 'putih'))
    elif jenis == 'lengkung':             # PJU jalan besar: tiang meruncing, lengan melengkung, kepala LED pipih
        h = 64
        pid = _tiang_meruncing(s, 0, 0, 0, h, 2.0, 1.2, TIANG)
        _cyl_tegak(s, 0, 0, 2.8, 0, 5, TIANG, pid)
        pts = _lengkung(s, (0, 0, h - 2), (16, 0, h + 1), 6, 0.8, TIANG, pid)
        th = math.radians(-8)
        s.add(obox((19.5, 0, h + 0.4), (math.cos(th), 0, math.sin(th)), (0, 1, 0), (-math.sin(th), 0, math.cos(th)),
                   5.0, 2.4, 0.9, [TIANG, L], lambda Pw, Nw: (np.where((Nw[:, 2] < -0.5) | (Pw[:, 2] < h + 0.2 - 0.06 * (Pw[:, 0] - 19.5)), 1, 0), 0), part=pid))
        titik.append(((19, 0, h - 2), 'putih'))
    elif jenis == 'ganda':                # median jalan lebar: dua lengan ke dua arah
        h = 62
        pid = _tiang_meruncing(s, 0, 0, 0, h, 2.0, 1.3, TIANG)
        _cyl_tegak(s, 0, 0, 3.0, 0, 6, BETON, pid)
        for sg in (-1, 1):
            _lengkung(s, (0, 0, h - 2), (sg * 15, 0, h + 1), 5, 0.8, TIANG, pid)
            s.add(box(sg * 15 - 4.5, sg * 15 + 4.5, -2.2, 2.2, h - 0.2, h + 1.6, [TIANG, L],
                      lambda Pw, Nw: (np.where((Nw[:, 2] < -0.5) | (Pw[:, 2] < h + 0.6), 1, 0), 0), part=pid))
            titik.append(((sg * 15, 0, h - 3), 'putih'))
    elif jenis == 'taman':                # lampu taman / gerbang kompleks: tiang pendek berhias, lentera
        h = 30
        pid = _cyl_tegak(s, 0, 0, 2.6, 0, 3, HITAM_L, None)
        _cyl_tegak(s, 0, 0, 1.6, 3, 5, HITAM_L, pid)
        _cyl_tegak(s, 0, 0, 1.0, 5, h, HITAM_L, pid)
        s.add(box(-2.6, 2.6, -2.6, 2.6, h, h + 1, HITAM_L, part=pid))
        s.add(box(-2.2, 2.2, -2.2, 2.2, h + 1, h + 7, [HITAM_L, LH],
                  lambda Pw, Nw: (np.where((np.abs(Nw[:, 2]) < 0.5) & (np.mod(Pw[:, 0] + Pw[:, 1] + 20, 4.4) > 0.9), 1, 0), 0),
                  part=pid))
        s.add(hip(-3.2, 3.2, -3.2, 3.2, h + 7, h + 10, mats=[HITAM_L], part=pid))
        _cyl_tegak(s, 0, 0, 0.6, h + 10, h + 12, HITAM_L, pid)
        titik.append(((0, 0, h + 4), 'hangat'))
    elif jenis == 'tiang_beton':          # perkampungan: tiang beton listrik dengan bohlam berkap seng
        h = 70
        pid = None
        s.add(box(-1.8, 1.8, -1.8, 1.8, 0, h, BETON))
        pid = s.prims[-1].part
        s.add(box(-1, 1, -10, 10, h - 6, h - 4, P['metal_dk'], part=pid))       # palang kabel sejajar jalan
        for yy in (-8, 8):
            _cyl_tegak(s, 0, yy, 0.7, h - 4, h - 2.5, KACA_LAMPU, pid)              # isolator
        _limb(s, (1.8, 0, 46), (10, 0, 48), 0.5, P['metal_dk'], pid)
        _limb(s, (10, 0, 48), (10, 0, 45.5), 0.35, P['metal_dk'], pid)
        s.add(hip(6.5, 13.5, -3.5, 3.5, 44.0, 46.0, mats=[SENG], part=pid))      # kap seng
        s.add(ellip((10, 0, 43.6), (1.2, 1.2, 1.4), LH, None, part=pid))
        titik.append(((10, 0, 42), 'hangat'))
    elif jenis == 'bambu':                # desa: tiang bambu, bohlam berkap seng di ujung lengan bambu
        h = 44
        pid = None
        for i in range(8):
            z0, z1 = h * i / 8, h * (i + 1) / 8
            s.add(cyl((0.15 * i, 0), 1.3, z0, z1 + 0.2, mats=BAMBU,
                      tex=lambda Pw, Nw, z1=z1: (0, np.where(z1 - Pw[:, 2] < 0.7, 1, 0)), part=pid))
            pid = s.prims[-1].part
        _limb(s, (1.0, 0, h - 4), (11, 0, h - 1), 0.75, BAMBU, pid)
        _limb(s, (11, 0, h - 1), (11, 0, h - 4), 0.3, P['metal_dk'], pid)
        s.add(hip(8.0, 14.0, -3.0, 3.0, h - 5.6, h - 3.6, mats=[SENG], part=pid))
        s.add(ellip((11, 0, h - 6.6), (1.1, 1.1, 1.3), LH, None, part=pid))
        titik.append(((11, 0, h - 8), 'hangat'))
    elif jenis == 'surya':                # PJU tenaga surya: panel miring di puncak, baterai di tiang, kepala LED
        h = 54
        pid = _tiang_meruncing(s, 0, 0, 0, h, 1.7, 1.1, TIANG)
        _cyl_tegak(s, 0, 0, 2.6, 0, 4, BETON, pid)
        s.add(box(-1.8, 1.8, -2.4, 2.4, 30, 38, TIANG_HIJAU, part=pid))            # kotak baterai
        th = math.radians(28)
        def grid(Pw, Nw):
            top = Nw[:, 2] > 0.5
            g = top & ((np.mod(Pw[:, 1] + 30, 3.0) < 0.5) | (np.mod(Pw[:, 0] + 30, 3.0) < 0.5))
            return np.where(top & ~g, 0, 1), 0
        s.add(obox((-1.0, 0, h + 3.5), (math.cos(th), 0, -math.sin(th)), (0, 1, 0), (math.sin(th), 0, math.cos(th)),
                   6.0, 5.0, 0.6, [PANEL, P['metal']], grid, part=pid))
        s.add(box(0, 10, -0.7, 0.7, h - 4, h - 2.6, TIANG, part=pid))
        s.add(box(7, 14, -2.0, 2.0, h - 5, h - 3.4, [TIANG, L], lambda Pw, Nw: (np.where((Nw[:, 2] < -0.5) | (Pw[:, 2] < h - 4.3), 1, 0), 0), part=pid))
        titik.append(((10.5, 0, h - 7), 'putih'))
    return titik


HITAM_L = Mat('#5A5662', '#3E3A46', '#26222C')
LAMPU_URUT = ['lengan', 'lengkung', 'ganda', 'taman', 'tiang_beton', 'bambu', 'surya']
LAMPU_INFO = {
    'lengan': 'PJU perumahan, tiang besi dan lengan lurus (bentuk lib.lamp_post)',
    'lengkung': 'PJU jalan besar: tiang meruncing, lengan melengkung, kepala LED pipih (ruko)',
    'ganda': 'Dua lengan di median atau tengah jalan lebar (ruko)',
    'taman': 'Lampu taman berlentera di gerbang kompleks dan pos satpam',
    'tiang_beton': 'Tiang beton listrik dengan bohlam berkap seng (perkampungan)',
    'bambu': 'Tiang bambu dengan bohlam berkap seng (desa, pinggir sungai)',
    'surya': 'PJU tenaga surya: panel miring, kotak baterai (desa, perumahan baru)',
}


def lampu_v(s, jenis, x, y, sisi='seberang', nyala=False):
    """sisi seberang: lengan ke +x (kanan bawah, ke jalan). sisi dekat: lengan ke -x (kiri atas)."""
    tmp = F3._Tmp()
    titik = lampu(tmp, jenis, nyala)
    A = rz(0 if sisi == 'seberang' else 180)
    xform_into(s, tmp, A, (x, y, 0))
    out = []
    for p, w in titik:
        q = A @ np.asarray(p, float) + np.array([x, y, 0])
        out.append((q, w))
    return out


def pasang_cahaya(s, titik, r=64, kuat=0.95):
    for q, w in titik:
        s.lights.append(Light(tuple(q), r, WARNA_CAHAYA[w], kuat, flat=0.35, zmax=22))


# ======================================================================= pohon ====
DAUN_FLAMBOYAN = Mat('#9CCC5A', '#5E9A44', '#36623A')
BUNGA_FLAMBOYAN = Mat('#F06A4E', '#C8382E', '#8E2422')
DAUN_PUCUK = Mat('#8CC860', '#4F8A4A', '#2E5236')
PUCUK_MERAH = Mat('#F7A8A8', '#E0605A', '#A8383A')
BATANG_PALEM = Mat('#D6D0C8', '#ACA69E', '#7E7870')
LEHER_PALEM = Mat('#9CCC5A', '#6FAE4F', '#3F6E3A')
DAUN_PALEM = Mat('#8CC860', '#5E9A44', '#36623A')
BATANG_PEPAYA = Mat('#C4C8A0', '#9A9E78', '#6E7254')
DAUN_PEPAYA = Mat('#9CD46A', '#5FA24A', '#36703A')
BUAH_PEPAYA = Mat('#B4DC6A', '#7FAE44', '#4E7A2C')
BUAH_MATANG = Mat('#FFC27A', '#F2944A', '#B0602C')
BAMBU_HIJAU = Mat('#C4D86A', '#93AE48', '#5E7A2E')
DAUN_BAMBU = Mat('#A8D46A', '#6EA24A', '#3E6A34')
DAUN_BERINGIN = Mat('#6FAE4F', '#3F7A44', '#24482C')
AKAR = Mat('#8A6A4E', '#6D4C34', '#4A3020')


def _gumpal(s, blobs, mat, tex, part=None):
    for c, rr in blobs:
        s.add(ellip(c, rr, mat, tex, part=part))
        part = part or s.prims[-1].part
    return part


def pohon_flamboyan(s, x, y, seed=0):
    """Flamboyan: batang pendek bercabang lebar, tajuk payung datar, bunga merah di permukaan atas."""
    rng = np.random.default_rng(seed)
    pid = _cyl_tegak(s, x, y, 2.4, 0, 16, BARK)
    base = np.array([x, y, 15.0])
    for i in range(5):
        a = 2 * math.pi * i / 5 + rng.random() * 0.5
        tip = base + np.array([math.cos(a) * 15, math.sin(a) * 15, 8 + rng.random() * 3])
        _limb(s, base, tip, 1.1, BARK, pid)

    def tex(Pw, Nw):
        cell = np.floor(Pw / 1.6)
        h = hash2(cell[:, 0] + cell[:, 2] * 7, cell[:, 1] - cell[:, 2] * 3, seed + 41)
        d = Nw @ BAKE
        bunga = (h > 0.74) & (Nw[:, 2] > 0.35)
        sh = np.where((h < 0.2) & (d < 0.7), 1, np.where((h > 0.5) & (d > 0.4), -1, 0))
        return np.where(bunga, 1, 0), np.where(bunga, np.clip(sh, -1, 0), sh)
    blobs = [((x, y, 26), (13, 13, 4.2))]
    for i in range(9):
        a = 2 * math.pi * i / 9 + rng.random() * 0.4
        rr = 7 + rng.random() * 2
        blobs.append(((x + math.cos(a) * 15, y + math.sin(a) * 15, 23.5 + rng.random() * 2.5), (rr, rr, 3.3)))
    _gumpal(s, blobs, [DAUN_FLAMBOYAN, BUNGA_FLAMBOYAN], tex)


def pohon_pucuk_merah(s, x, y, seed=0):
    """Pucuk merah: perdu tinggi lonjong rapat, daun muda merah di pucuk bagian atas."""
    pid = _cyl_tegak(s, x, y, 1.2, 0, 6, BARK)

    def tex(Pw, Nw):
        cell = np.floor(Pw / 1.5)
        h = hash2(cell[:, 0] + cell[:, 2] * 5, cell[:, 1] - cell[:, 2] * 3, seed + 9)
        merah = ((Pw[:, 2] > 30) & (h > 0.35)) | ((Pw[:, 2] > 20) & (h > 0.8) & (Nw[:, 2] > 0.3))
        d = Nw @ BAKE
        sh = np.where((h < 0.22) & (d < 0.7), 1, np.where((h > 0.82) & (d > 0.3), -1, 0))
        return np.where(merah, 1, 0), sh
    blobs = [((x, y, 11), (8.0, 8.0, 7.0)), ((x, y, 20), (8.4, 8.4, 7.5)), ((x, y, 29), (6.8, 6.8, 6.2)),
             ((x + 3.4, y - 2, 16), (4.8, 4.8, 5.0)), ((x - 3.6, y + 2.6, 23), (4.6, 4.6, 5.0)), ((x, y, 35.5), (3.8, 3.8, 3.4))]
    _gumpal(s, blobs, [DAUN_PUCUK, PUCUK_MERAH], tex)


def _pelepah(s, top, n, L, mat, seed, rise=(0.25, 0.4), drop=(0.75, 1.0), lebar=4.5, segs=6):
    """Pelepah palem melengkung dengan anak daun berbentuk V (cara sama dengan districts.coconut)."""
    rng = np.random.default_rng(seed)
    up = np.array([0, 0, 1.0])
    crown = None
    for i in range(n):
        yaw = 2 * math.pi * i / n + rng.random() * 0.35
        hd = np.array([math.cos(yaw), math.sin(yaw), 0.0])
        Li = L * (0.85 + rng.random() * 0.25)
        ri = rise[0] + rng.random() * (rise[1] - rise[0])
        di = drop[0] + rng.random() * (drop[1] - drop[0])
        pts = [top + hd * Li * t + up * Li * (ri * t - di * t * t) for t in np.linspace(0, 1, segs + 1)]
        for k in range(segs):
            a, b = pts[k], pts[k + 1]
            ax = b - a; seg = np.linalg.norm(ax); ax = ax / seg
            tm = (k + 0.5) / segs
            w = max(1.6, lebar * math.sin(math.pi * min(0.95, tm * 0.9 + 0.12)))
            sd = np.cross(ax, up); sd /= max(np.linalg.norm(sd), 1e-6)
            s.add(obox((a + b) / 2, ax, sd, np.cross(ax, sd), seg / 2 + 0.3, 0.45, 0.45, mat, part=crown))
            crown = s.prims[-1].part
            for j in range(3):
                bs = a + ax * seg * (j + 0.5) / 3
                for sg in (-1, 1):
                    v = sd * sg * 0.8 - up * 0.45 + ax * 0.45
                    v /= np.linalg.norm(v)
                    nv = np.cross(v, ax); nv /= max(np.linalg.norm(nv), 1e-6)
                    s.add(obox(bs + v * w / 2, v, nv, np.cross(v, nv), w / 2, 0.55, 0.3, mat, part=crown))
    return crown


def pohon_palem_raja(s, x, y, seed=0):
    """Palem raja: batang lurus abu-abu licin sedikit menggembung, leher hijau, pelepah melengkung."""
    h = 58
    pid = None
    for i in range(10):
        z0, z1 = h * i / 10, h * (i + 1) / 10 + 0.3
        r = 2.3 + 0.5 * math.sin(math.pi * min(1, (i + 0.5) / 7)) - 0.05 * i
        s.add(cyl((x, y), r, z0, z1, mats=BATANG_PALEM,
                  tex=lambda Pw, Nw, z0=z0: (0, np.where(np.mod(Pw[:, 2], 4.5) < 0.5, 1, 0)), part=pid))
        pid = s.prims[-1].part
    _cyl_tegak(s, x, y, 2.0, h, h + 9, LEHER_PALEM, pid)
    _pelepah(s, np.array([x, y, h + 9.5]), 7, 24, DAUN_PALEM, seed, rise=(0.3, 0.5), drop=(0.7, 0.9), lebar=4.0)


def pohon_pepaya(s, x, y, seed=0):
    """Pepaya: batang ramping bergaris bekas daun, payung daun menjari di puncak, buah bergerombol."""
    h = 38
    rng = np.random.default_rng(seed)
    pid = None
    for i in range(6):
        z0, z1 = h * i / 6, h * (i + 1) / 6 + 0.3
        s.add(cyl((x + 0.12 * i, y), 1.5 - 0.1 * i, z0, z1, mats=BATANG_PEPAYA,
                  tex=lambda Pw, Nw: (0, np.where(np.mod(Pw[:, 2], 2.2) < 0.45, 1, 0)), part=pid))
        pid = s.prims[-1].part
    top = np.array([x + 0.7, y, h])
    tex = _leaf_tex(seed + 5, 1.5)
    crown = None
    for i in range(8):
        yaw = 2 * math.pi * i / 8 + rng.random() * 0.4
        el = 0.35 + rng.random() * 0.35 if i % 2 else 0.05 + rng.random() * 0.2
        d = np.array([math.cos(yaw) * math.cos(el), math.sin(yaw) * math.cos(el), math.sin(el)])
        tip = top + d * 11
        _limb(s, top, tip, 0.4, BATANG_PEPAYA, pid)
        sd = np.cross(d, [0, 0, 1.0]); sd /= np.linalg.norm(sd)
        nrm_ = np.cross(sd, d)
        dl = d - np.array([0, 0, 0.35]); dl /= np.linalg.norm(dl)
        s.add(ellip(tip + dl * 4.0, (5.6, 5.0, 1.0), DAUN_PEPAYA, tex, R=np.stack([dl, sd, np.cross(sd, dl)]), part=crown))
        crown = s.prims[-1].part
    for i in range(6):
        a = i * 1.1
        m = BUAH_MATANG if i in (1, 4) else BUAH_PEPAYA
        s.add(ellip(top + np.array([math.cos(a) * 1.8, math.sin(a) * 1.8, -2.2 - (i % 3) * 1.4]), (1.4, 1.4, 2.1), m, None, part=pid))


def pohon_bambu(s, x, y, seed=0):
    """Rumpun bambu: banyak batang ramping beruas condong ke luar, jumbai daun lebat terkulai di bagian atas."""
    rng = np.random.default_rng(seed)
    tex = _leaf_tex(seed + 13, 1.4)
    crown = None
    for i in range(12):
        a = 2 * math.pi * i / 12 + rng.random() * 0.4
        r0 = 1.0 + rng.random() * 2.4
        lean = 0.1 + rng.random() * 0.16
        H = 54 + rng.random() * 16
        base = np.array([x + math.cos(a) * r0, y + math.sin(a) * r0, 0])
        out = np.array([math.cos(a), math.sin(a), 0])
        pts = [base + out * (H * lean * t + 9 * t ** 2.2) + np.array([0, 0, H * t * (1 - 0.12 * t ** 2)])
               for t in np.linspace(0, 1, 10)]
        pid = None
        for k in range(9):
            p0, p1 = pts[k], pts[k + 1]
            u, v, w = _frame(p1 - p0)
            s.add(obox((p0 + p1) / 2, u, v, w, 0.8, 0.8, np.linalg.norm(p1 - p0) / 2, BAMBU_HIJAU,
                       (lambda Pw, Nw, z1=p1[2]: (0, np.where(np.abs(Pw[:, 2] - z1) < 0.6, 1, 0))), part=pid))
            pid = s.prims[-1].part
        for k in range(4, 10):
            c = pts[k] + out * 2.5 + np.array([0, 0, -1.5])
            rr = 3.8 + 1.4 * (k / 9)
            s.add(ellip(c, (rr, rr, 2.4), DAUN_BAMBU, tex, part=crown))
            crown = s.prims[-1].part


def _frame(w):
    w = np.asarray(w, float); w = w / np.linalg.norm(w)
    u = np.cross(w, [0, 0, 1.0])
    if np.linalg.norm(u) < 1e-6:
        u = np.array([1.0, 0, 0])
    u /= np.linalg.norm(u)
    v = np.cross(w, u)
    return u, v, w


def pohon_beringin(s, x, y, seed=0):
    """Beringin besar: batang lebar berbanir, cabang mendatar, tajuk sangat lebar, akar gantung."""
    rng = np.random.default_rng(seed)
    pid = _cyl_tegak(s, x, y, 5.0, 0, 22, BARK)
    for i in range(5):                                         # banir
        a = 2 * math.pi * i / 5 + 0.3
        _limb(s, (x, y, 6), (x + math.cos(a) * 8, y + math.sin(a) * 8, 0.5), 1.8, BARK, pid)
    base = np.array([x, y, 20.0])
    tips = []
    for i in range(6):
        a = 2 * math.pi * i / 6 + rng.random() * 0.4
        tip = base + np.array([math.cos(a) * 24, math.sin(a) * 24, 10 + rng.random() * 4])
        _limb(s, base, tip, 2.0, BARK, pid)
        tips.append(tip)
    for t in tips:                                             # akar gantung dari cabang
        for k in range(3):
            p = base + (t - base) * (0.45 + 0.22 * k)
            _limb(s, p, np.array([p[0], p[1], 0.5]), 0.35, AKAR, None)
    tex = _leaf_tex(seed + 21, 2.4)
    blobs = [((x, y, 44), (20, 20, 12))]
    for i in range(11):
        a = 2 * math.pi * i / 11 + rng.random() * 0.3
        rr = 10 + rng.random() * 3
        blobs.append(((x + math.cos(a) * 26, y + math.sin(a) * 26, 34 + rng.random() * 6), (rr, rr, rr * 0.75)))
    for t in tips:
        blobs.append((tuple(t + np.array([0, 0, 6])), (9, 9, 7)))
    crown = None
    for k, (c, rr) in enumerate(blobs):
        s.add(ellip(c, rr, DAUN_BERINGIN, tex, part=None if k else crown))
        crown = crown or s.prims[-1].part


POHON = {
    'rindang': (lambda s, seed=0: tree_rindang(s, 0, 0, seed=seed), 'Rindang (mangga, kersen): tajuk lebar bergumpal', 'lama'),
    'glodokan': (lambda s, seed=0: tree_glodokan(s, 0, 0, seed=seed), 'Glodokan tiang: ramping dan tinggi', 'lama'),
    'ketapang': (lambda s, seed=0: tree_ketapang(s, 0, 0, seed=seed), 'Ketapang kencana: tajuk bertingkat seperti payung', 'lama'),
    'kelapa': (lambda s, seed=0: DI.coconut(s, 0, 0, seed=seed), 'Kelapa: batang melengkung bercincin, berbuah', 'lama'),
    'pisang': (lambda s, seed=0: KP.banana(s, 0, 0, seed=seed), 'Pisang: batang semu, daun lebar terkulai', 'lama'),
    'flamboyan': (lambda s, seed=0: pohon_flamboyan(s, 0, 0, seed), 'Flamboyan: payung datar dengan bunga merah', 'baru'),
    'pucuk_merah': (lambda s, seed=0: pohon_pucuk_merah(s, 0, 0, seed), 'Pucuk merah: perdu tinggi, daun muda merah', 'baru'),
    'palem_raja': (lambda s, seed=0: pohon_palem_raja(s, 0, 0, seed), 'Palem raja: batang abu-abu licin, leher hijau', 'baru'),
    'pepaya': (lambda s, seed=0: pohon_pepaya(s, 0, 0, seed), 'Pepaya: batang ramping, daun menjari, buah bergerombol', 'baru'),
    'bambu': (lambda s, seed=0: pohon_bambu(s, 0, 0, seed), 'Rumpun bambu: batang beruas condong ke luar', 'baru'),
    'beringin': (lambda s, seed=0: pohon_beringin(s, 0, 0, seed), 'Beringin besar: banir, akar gantung, tajuk sangat lebar', 'baru'),
}
POHON_URUT = list(POHON)


# ====================================================================== ekspor ====
def ekspor_lampu():
    out = {}
    for j in LAMPU_URUT:
        sisi_list = ['seberang'] if j in ('ganda', 'taman') else ['seberang', 'dekat']
        frames, names = [], []
        for sisi in sisi_list:
            for nyala in (False, True):
                a, o, _, _ = F3.render_sprite(lambda s, j=j, sisi=sisi, nyala=nyala: lampu_v(s, j, 0, 0, sisi, nyala) and None,
                                              extra_px=(54, 28), pad=4)
                frames.append((a, o)); names.append('%s_%s' % (sisi, 'nyala' if nyala else 'mati'))
        sheet, cell = pack(frames, names, 'prop_lampu_%s_sheet' % j, {
            'note': 'Usulan, tools/env_art/lampu_pohon.py. %s. seberang = lengan ke kanan bawah (dipasang di sisi '
                    'seberang), dekat = lengan ke kiri atas. nyala = kepala lampu terang; cahaya di tanah dari Light2D game.' % LAMPU_INFO[j]})
        out[j] = (sheet, cell)
    return out


def ekspor_pohon():
    out = {}
    for nm in POHON_URUT:
        fn, info, _ = POHON[nm]
        a, o, _, _ = F3.render_sprite(lambda s, fn=fn: fn(s, 3), extra_px=(70, 34), pad=4)
        Image.fromarray(a, 'RGBA').save(OUT_DIR / ('prop_pohon_%s.png' % nm))
        _json(OUT_DIR / ('prop_pohon_%s.json' % nm), {'sprite': 'prop_pohon_%s.png' % nm, 'size': [a.shape[1], a.shape[0]],
                                                    'ground_anchor': list(o), 'note': 'Usulan. ' + info + '. Titik pijak = pangkal batang.'})
        out[nm] = (a, o)
    return out


# =============================================================== layar contoh ====
LAYAR_POHON = [(-150, -256, 'rindang', 1), (-150, -128, 'flamboyan', 2), (-150, 0, 'palem_raja', 3),
               (-150, 128, 'pucuk_merah', 4), (-150, 256, 'glodokan', 5),
               (98, -208, 'ketapang', 6), (98, -80, 'pepaya', 7), (98, 48, 'pisang', 8), (98, 176, 'kelapa', 9)]
LAYAR_LAMPU = [(-72, -180, 'lengan', 'seberang'), (-72, 60, 'surya', 'seberang'), (72, -40, 'lengkung', 'dekat'),
               (-76, 220, 'taman', 'seberang'), (72, 120, 'tiang_beton', 'dekat')]


def build_layar(s, malam=False):
    rng = np.random.default_rng(7)
    UB.build_jalan(s, y_range=(-900, 900), masuk=None)
    # rumah sisi seberang (halaman 40 unit dari kerb luar), rumah sisi dekat dari belakang
    for i, yc in enumerate([-320, -192, -64, 64, 192, 320]):
        F3.house_far_v(s, yc, PR.WALLS[i], PR.ROOFS[i], seed=i, kind=PR.HOUSE_TYPES[i % 3], pelanggan=True, kotak=False)
    for i, yc in enumerate([-272, -144, -16, 112, 240]):
        PR.house_near(s, yc + 0, PR.WALLS[(i + 3) % 8], PR.ROOFS[(i + 2) % 8], seed=i)
    for x, y, nm, sd in LAYAR_POHON:
        st = len(s.prims)
        POHON[nm][0](s, sd)
        geser(s.prims[st:], (x, y, 0))
    titik = []
    for x, y, j, sisi in LAYAR_LAMPU:
        titik += lampu_v(s, j, x, y, sisi, nyala=malam)
    if malam:
        pasang_cahaya(s, titik)
    return titik


def render_layar(tname, out):
    W, H, ox, oy = 640, 360, 300, 192
    s = Scene(W, H, ox, oy)
    build_layar(s, malam=(tname == 'malam'))
    s.render(TIMES[tname])
    sprites = [(PR.loper_frame(5, 1), (23, 46), (-16, 110, 0))]
    img = finish_with_sprites(s, sprites)
    im = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), 'RGB')
    im.save(OUT_DIR / out)
    return im


if __name__ == '__main__':
    ekspor_lampu()
    ekspor_pohon()
    render_layar('siang', 'layar_lampu_pohon_siang.png')
    render_layar('malam', 'layar_lampu_pohon_malam.png')
    print('selesai ->', OUT_DIR)
