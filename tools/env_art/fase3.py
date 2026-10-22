"""Aset Fase 3 perumahan (usulan): rintangan, rumah pelanggan dan bukan pelanggan di dua sisi jalan, antena TV.

Memakai engine.py, lib.py, dan perumahan.py apa adanya (tidak mengubah mock lama). Model baru:
- anjing(): anjing penjaga, lima pose (duduk, gonggong, lari_1, lari_2, berhenti)
- mobil_mundur(): sedan lib.car() diputar 90 derajat, lampu mundur, cahaya di aspal, asap knalpot
- house_far_v(): rumah sisi seberang, varian pelanggan / bukan pelanggan
- house_near_v(): rumah sisi dekat (terlihat belakang), varian pelanggan / bukan, toren dan jemuran
- antena_v(): enam jenis antena TV
- kotak_surat_oranye(): kotak surat berbentuk lib.kotak_surat() berwarna oranye graybox, sprite tunggal sasaran scene rute
- kotak_surat_bukan(): kotak surat rumah bukan pelanggan sisi seberang, abu-abu logam, lebih rendah dan tanpa celah surat (bukan sasaran)

Menjalankan (dari root repo):
    python3 tools/env_art/fase3.py            # render ke build/env_art/fase3/
    python3 tools/env_art/fase3.py --salin    # render lalu salin ke assets/sprites/ dan docs/design/environment/
`ENV_ART_OUT` mengganti folder build, `ENV_ART_SALIN_KE` mengganti akar tujuan `--salin` (bawaan root repo; dipakai
tools/tests_cek/uji_aset_fase3.py). Hasil sama bit demi bit di semua mesin (mm()/panjang() dari engine.py, tanpa BLAS).
Rincian: tools/env_art/README.md, ART_DIRECTION 6.4-6.6.
"""
import json
import math
import os
import shutil
import sys
from pathlib import Path

import numpy as np
from PIL import Image

from engine import *          # noqa: F401,F403
from lib import *             # noqa: F401,F403
import perumahan as PR

ROOT = PR.ROOT
OUT_DIR = PR.OUT / 'fase3'
SALIN_KE = Path(os.environ.get('ENV_ART_SALIN_KE', ROOT))


# ------------------------------------------------------------ rotasi 90 derajat ----
A90 = np.array([[0, -1, 0], [1, 0, 0], [0, 0, 1.0]])   # lokal (x, y) -> dunia (-y, x)


class _Tmp:
    def __init__(s):
        s.prims, s.lights = [], []

    def add(s, *ps):
        for p in ps:
            if isinstance(p, (list, tuple)):
                s.add(*p)
            else:
                s.prims.append(p)


def rot90_into(s, tmp, t):
    """Pindahkan primitif dari tmp ke scene s dengan dunia = A90 @ lokal + t."""
    A = A90
    t = np.asarray(t, float)
    for p in tmp.prims:
        p.planes = [(mm(A, n), d + float(mm(mm(A, n), t))) for n, d in p.planes]
        if p.quad is not None:
            if p.quad[0] == 'ellip':
                _, c, R, r = p.quad
                p.quad = ('ellip', mm(A, c) + t, mm(R, A.T), r)
            else:
                _, ax, c2, r = p.quad
                e = np.zeros(3); e[ax] = 1
                c3 = np.zeros(3); o = [i for i in range(3) if i != ax]; c3[o] = c2
                ne = mm(A, e); nax = int(np.argmax(np.abs(ne)))
                w = mm(A, c3) + t
                no = [i for i in range(3) if i != nax]
                p.quad = ('cyl', nax, w[no], r)
        cs = np.array([[x, y, z] for x in (p.lo[0], p.hi[0]) for y in (p.lo[1], p.hi[1]) for z in (p.lo[2], p.hi[2])])
        w = mm(cs, A.T) + t
        p.lo, p.hi = w.min(0), w.max(0)
        if p.tex is not None:
            f = p.tex
            p.tex = (lambda Pw, Nw, f=f: f(mm(Pw - t, A), mm(Nw, A)))
        s.prims.append(p)


# ------------------------------------------------------------------ mobil ----
LAMP_MUNDUR = {'parkir': Mat('#E4E2E8', '#C9C6CE', '#9E9AA6'),
               'nyala': Mat('#FFFFFF', '#FFFFFF', '#FFF6D8'),
               'redup': Mat('#FFF6D8', '#FFE7A8', '#E9C46A')}
LAMP_REM_NYALA = Mat('#FFA88A', '#FF6A4A', '#C23A2A')
CAR_BODY = Mat('#F08A6A', '#D9573D', '#8E2E25')


def mobil_mundur(s, x, y, state='nyala', body=None, length=50, width=22):
    """Sedan lib.car() diputar 90 derajat: moncong ke garasi (-x), bagasi ke jalan (+x).
    Lampu belakang dibagi dua: merah di luar, putih (mundur) di dalam."""
    tmp = _Tmp()
    car(tmp, 0.0, 0.0, body=body or CAR_BODY, length=length, width=width, front=1)
    bodyp = tmp.prims[0]
    hw = width / 2
    base = bodyp.tex

    def tex(Pw, Nw, base=base):
        mi, sh = base(Pw, Nw)
        mi = np.array(np.broadcast_to(mi, (len(Pw),)))
        sh = np.array(np.broadcast_to(sh, (len(Pw),)))
        lat = np.abs(Pw[:, 0])
        pz = Pw[:, 2]
        rear = Nw[:, 1] < -0.55
        mi = np.where(rear & (mi == 2), 0, mi)                    # lampu bawaan diganti
        lamp = rear & (pz > 6.2) & (pz < 10.6) & (lat > hw - 9.5) & (lat < hw - 0.8)
        mi = np.where(lamp & (lat >= hw - 5.0), 2, mi)            # merah di luar
        mi = np.where(lamp & (lat < hw - 5.0), 6, mi)             # putih (mundur) di dalam
        sh = np.where(lamp, 0, sh)
        return mi, sh
    bodyp.tex = tex
    rem = LAMP_REM_NYALA if state != 'parkir' else LAMP_R
    bodyp.mats = [bodyp.mats[0], bodyp.mats[1], rem, bodyp.mats[3], bodyp.mats[4], bodyp.mats[5], LAMP_MUNDUR[state]]
    rot90_into(s, tmp, (x, y, 0))
    # titik lampu (dunia) untuk kolam cahaya dan asap
    rear_x = x + length / 2
    return dict(rear_x=rear_x, y=y, hw=hw, state=state, t=0.0 if state == 'nyala' else 0.4)


def kolam_masker(s, info):
    """Piksel tanah di belakang bagasi yang kena lampu mundur: (indeks datar, alpha, warna)."""
    if info['state'] == 'parkir':
        return []
    b = s._buf
    H, W = s.H, s.W
    P = b['P']; prim = b['prim']
    x, y, hw = info['rear_x'], info['y'], info['hw']
    near_len, far_len = (14, 30) if info['state'] == 'nyala' else (10, 0)
    col = (255, 255, 229) if info['state'] == 'nyala' else (255, 231, 168)
    ys, xs = np.mgrid[0:H, 0:W]
    lowz = P[:, 2] < 3.2
    obj = prim >= 0
    dx = P[:, 0] - x
    lat = np.abs(P[:, 1] - y)
    spread = hw - 3 + dx * 0.25
    chk = ((xs + ys).ravel() % 2) == 0
    zn = np.where(obj & lowz & (dx > 0.5) & (dx < near_len) & (lat < spread))[0]
    zf = np.where(obj & lowz & (dx >= near_len) & (dx < near_len + far_len) & (lat < spread) & chk)[0]
    a_near = 0.42 if info['state'] == 'nyala' else 0.3
    return [(zn, a_near, col), (zf, 0.3, col)]


def kolam_cahaya(s, img, info):
    out = img.reshape(-1, 3).copy()
    for idx, a, col in kolam_masker(s, info):
        out[idx] = out[idx] * (1 - a) + np.array(col, np.float32) * a
    return out.reshape(img.shape)


def asap_puffs(s, info, t=0.0):
    """Asap knalpot kecil (2 kepul) di belakang bagasi kiri: daftar (X, Y, rgb, alpha)."""
    if info['state'] == 'parkir':
        return []
    src = np.array([info['rear_x'] + 1.5, info['y'] + info['hw'] - 5, 3.0])
    px = []
    for i, (u, r, a) in enumerate(((0.15 + t, 1.6, 0.9), (0.55 + t, 2.6, 0.6))):
        u = u % 1.0
        p = src + np.array([3 + 7 * u, -1.5 * u, 2 + 7 * u])
        sx, sy = s.proj(p)
        cx, cy = sx[0], sy[0]
        rr = r + 1.2 * u
        for Y in range(int(cy - rr - 1), int(cy + rr + 2)):
            for X in range(int(cx - rr - 1), int(cx + rr + 2)):
                dx, dy = X + 0.5 - cx, Y + 0.5 - cy
                if dx * dx + dy * dy <= rr * rr:
                    k = dx + dy
                    col = (246, 242, 236) if k < -0.35 * rr else ((168, 162, 170) if k > 0.5 * rr else (214, 208, 206))
                    px.append((X, Y, col, a))
    return px


# ------------------------------------------------------------------ anjing ----
BULU = Mat('#F6D2A8', '#E0A874', '#A8724C')
BULU_GELAP = Mat('#C88A5C', '#9A6440', '#5E3A2A')
HIDUNG = Mat('#3D3446', '#2C2534', '#1C1724')
KALUNG = Mat('#F06A4E', '#D94F3D', '#8E2E25')
LIDAH = Mat('#F7A8A8', '#E87878', '#B04A50')


def _limb(s, a, b, r, mat, part):
    a, b = np.asarray(a, float), np.asarray(b, float)
    c = (a + b) / 2
    w = b - a
    L = panjang(w)
    w = w / L
    u = np.cross(w, [0, 0, 1.0])
    if panjang(u) < 1e-6:
        u = np.array([1.0, 0, 0])
    u = u / panjang(u)
    v = np.cross(w, u)
    s.add(obox(c, u, v, w, r, r, L / 2, mat, None, part=part))


def anjing(s, x, y, pose='lari_1', size=1.0):
    """Anjing kampung sedang. pose: duduk | gonggong (menghadap jalan, +x) | lari_1 | lari_2 | berhenti (menghadap maju, -y)."""
    k = size
    yaw = math.pi / 2 if pose in ('duduk', 'gonggong') else 0.0
    f = np.array([math.sin(yaw), -math.cos(yaw), 0.0])     # depan
    r = np.array([math.cos(yaw), math.sin(yaw), 0.0])      # kanan
    up = np.array([0, 0, 1.0])
    base = np.array([x, y, 0.0])

    def R_of(pitch=0.0):
        fp = f * math.cos(pitch) + up * math.sin(pitch)
        upp = np.cross(fp, r)
        if upp[2] < 0:                       # pastikan sumbu atas lokal mengarah ke atas
            upp = -upp
        return np.stack([fp, r, upp])

    if pose == 'duduk':
        body_c = base + up * 7.5 * k - f * 1.0 * k
        Rb = R_of(math.radians(38))
        s.add(ellip(body_c, (6.0 * k, 3.4 * k, 3.6 * k), BULU, None, R=Rb))
        pid = s.prims[-1].part
        s.add(ellip(base - f * 4.0 * k + up * 3.2 * k, (4.0 * k, 3.6 * k, 3.2 * k), BULU, None, R=R_of(), part=pid))  # pinggul duduk
        chest = body_c + f * 3.6 * k + up * 2.6 * k
        head = chest + f * 1.6 * k + up * 5.2 * k
        tail_a, tail_b = base - f * 7.5 * k + up * 1.2 * k, base - f * 7.5 * k + r * 5.0 * k + up * 0.8 * k
        legs = [(chest + r * s_ * 1.6 * k - up * 1.0 * k, base + f * 3.4 * k + r * s_ * 1.7 * k) for s_ in (-1, 1)]
        mouth_open = False
        ear_back = False
    else:
        run = pose.startswith('lari')
        bz = (10.0 if pose == 'lari_1' else 9.0) * k if run else 9.5 * k
        body_c = base + up * bz
        Rb = R_of(math.radians(4 if not run else 0))
        stretch = 7.6 if pose == 'lari_1' else (6.6 if run else 6.8)
        s.add(ellip(body_c, (stretch * k, 3.4 * k, 3.5 * k), BULU, None, R=Rb))
        pid = s.prims[-1].part
        chest = body_c + f * 4.6 * k + up * 0.6 * k
        s.add(ellip(chest, (3.4 * k, 3.4 * k, 3.6 * k), BULU, None, R=R_of(), part=pid))
        head_up = 5.8 if pose in ('gonggong', 'berhenti') else 4.0
        head = chest + f * 3.4 * k + up * head_up * k
        if run:
            tail_a, tail_b = body_c - f * stretch * 0.9 * k + up * 1.2 * k, body_c - f * (stretch + 6.0) * k + up * 3.0 * k
        else:
            tail_a, tail_b = body_c - f * 6.2 * k + up * 1.5 * k, body_c - f * 7.6 * k + up * 7.5 * k
        hip_c = body_c - f * 4.6 * k
        if pose == 'lari_1':      # kaki terentang
            fr = [(chest + r * s_ * 1.6 * k - up * 1.5 * k, base + f * (9.5 + 1.2 * (s_ > 0)) * k + r * s_ * 1.7 * k + up * 1.4 * k) for s_ in (-1, 1)]
            bk = [(hip_c + r * s_ * 1.8 * k - up * 1.0 * k, base - f * (10.5 + 1.2 * (s_ > 0)) * k + r * s_ * 1.8 * k + up * 1.2 * k) for s_ in (-1, 1)]
        elif pose == 'lari_2':    # kaki terkumpul di bawah badan
            fr = [(chest + r * s_ * 1.6 * k - up * 1.5 * k, base + f * (0.5 - 1.0 * (s_ > 0)) * k + r * s_ * 1.7 * k + up * 0.3 * k) for s_ in (-1, 1)]
            bk = [(hip_c + r * s_ * 1.8 * k - up * 1.0 * k, base - f * (1.5 - 1.0 * (s_ > 0)) * k + r * s_ * 1.8 * k + up * 0.3 * k) for s_ in (-1, 1)]
        else:                     # berdiri
            fr = [(chest + r * s_ * 1.6 * k - up * 1.5 * k, base + f * 5.0 * k + r * s_ * 1.7 * k) for s_ in (-1, 1)]
            bk = [(hip_c + r * s_ * 1.8 * k - up * 1.0 * k, base - f * 5.2 * k + r * s_ * 1.8 * k) for s_ in (-1, 1)]
        legs = fr + bk
        mouth_open = pose == 'gonggong'
        ear_back = run
    # kepala, moncong, telinga
    Rh = R_of(math.radians(8))
    s.add(ellip(head, (3.0 * k, 2.8 * k, 2.8 * k), BULU, None, R=Rh, part=pid))
    sn = head + f * 3.0 * k - up * 0.8 * k
    s.add(ellip(sn, (2.0 * k, 1.5 * k, 1.3 * k), BULU, None, R=Rh, part=pid))
    s.add(ellip(sn + f * 1.8 * k + up * 0.4 * k, (0.7 * k, 0.8 * k, 0.6 * k), HIDUNG, None, R=Rh, part=pid))
    if mouth_open:
        s.add(ellip(sn - up * 1.9 * k - f * 0.2 * k, (1.7 * k, 1.2 * k, 0.6 * k), BULU_GELAP, None, R=R_of(math.radians(-25)), part=pid))
        s.add(ellip(sn - up * 1.2 * k + f * 0.2 * k, (1.0 * k, 0.8 * k, 0.4 * k), LIDAH, None, R=Rh, part=pid))
    for s_ in (-1, 1):
        if ear_back:
            ea = head + r * s_ * 1.6 * k + up * 1.8 * k
            eb = ea - f * 3.0 * k + up * 0.6 * k
            _limb(s, ea, eb, 0.75 * k, BULU_GELAP, pid)
        else:
            ea = head + r * s_ * 1.6 * k + up * 2.0 * k - f * 0.4 * k
            eb = ea + up * 2.8 * k + r * s_ * 0.6 * k
            _limb(s, ea, eb, 0.8 * k, BULU_GELAP, pid)
    # mata (sisi kanan, terlihat kamera)
    for s_ in (-1, 1):
        s.add(ellip(head + f * 2.0 * k + r * s_ * 1.3 * k + up * 0.9 * k, (0.5 * k, 0.5 * k, 0.6 * k), HIDUNG, None, part=pid))
    # kalung
    neck = chest + f * 1.0 * k + up * 2.6 * k
    s.add(ellip(neck, (1.3 * k, 3.0 * k, 1.3 * k), KALUNG, None, R=R_of(math.radians(50)), part=pid))
    # ekor
    _limb(s, tail_a, tail_b, 0.9 * k, BULU, pid)
    # kaki: sisi jauh (r negatif) bagian sendiri supaya bergaris terhadap badan
    for i, (a, b) in enumerate(legs):
        side = mm(b - base, r)
        part = pid if side > 0 else None
        _limb(s, a, b, 1.05 * k, BULU, part)
        if part is None:
            part = s.prims[-1].part
        s.add(ellip(b + up * 0.4 * k + f * 0.4 * k, (1.3 * k, 1.1 * k, 0.6 * k), BULU_GELAP, None, R=R_of(), part=part))


# ------------------------------------------------------------------ rumah ----
BUKAN_WALL = Mat('#D2CEC8', '#B4AFA8', '#8E8982')
BUKAN_ROOF = Mat('#8E8A94', '#6E6A76', '#4E4A56')
TIRAI = Mat('#9A93A2', '#7A7384', '#57506A')
BUKAN_TERAS = Mat('#C4BDB4', '#A9A2AE', '#8A8390')


def _teras_v(s, x1, ya, yb, R, seed, kind='shed', h=27, pelanggan=True):
    lantai = P['paper'] if pelanggan else BUKAN_TERAS
    s.add(box(x1, x1 + 15, ya, yb, 0, 2.5, lantai,
              lambda Pw, Nw: (0, np.where((np.mod(Pw[:, 0], 5) < 0.8) | (np.mod(Pw[:, 1], 5) < 0.8), 1, 0)),
              outline=True, cast=False))
    yc = (ya + yb) / 2
    if pelanggan:
        s.add(box(x1 + 3, x1 + 9, yc - 3, yc + 5, 2.5, 3.2, P['red'], outline=False, cast=False))  # keset
    for py in (ya + 1, yb - 3):
        s.add(box(x1 + 12, x1 + 14, py, py + 2, 2.5, h, P['white'] if pelanggan else P['conc']))
    if kind == 'shed':
        s.add(shed(x1 - 2, x1 + 17, ya - 2, yb + 2, h + 3, h - 1, '+x', 2, mats=R, tex=roof_tex('flat')))
    else:
        s.add(box(x1 - 1, x1 + 17, ya - 2, yb + 2, h, h + 3, P['white'] if pelanggan else P['conc']))
    s.add(box(x1 + 0.5, x1 + 2.5, yc - 1, yc + 1, h - 5, h - 3, P['lamp']))


def house_far_v(s, yc, wall, roof, seed=0, kind='limasan', pelanggan=True, kotak=True, antena_kind='auto'):
    """Salinan PR.house_far dengan dua varian. Bukan pelanggan: dinding dan atap kusam, jendela bertirai,
    pintu gelap, teras abu-abu tanpa keset, tanpa kotak surat."""
    if pelanggan:
        W, R = P[wall], P[roof]
        glass, door = P['glass'], P['wood']
    else:
        W, R = BUKAN_WALL, BUKAN_ROOF
        glass, door = TIRAI, P['wood_dk']
    x0, x1 = PR.FX0, PR.FX1
    y0, y1 = yc - 44, yc + 44
    mats = [W, door, P['white'] if pelanggan else P['conc'], glass, P['metal_dk'], P['conc']]
    rt = roof_tex('genteng', seed, wall=True)
    tv = lambda *a, **kw: _teras_v(*a, pelanggan=pelanggan, **kw)
    if kind == 'limasan':
        feats = [
            dict(face='+x', u=(yc + 2, yc + 14), v=(2, 25), mat=1, frame=2, kind='door', handle=4),
            dict(face='+x', u=(yc - 32, yc - 16), v=(12, 25), mat=3, frame=2),
            dict(face='+x', u=(yc + 22, yc + 36), v=(12, 25), mat=3, frame=2),
            dict(face='+y', u=(x0 + 18, x0 + 34), v=(12, 25), mat=3, frame=2),
            dict(face='+y', u=(x0 + 54, x0 + 70), v=(12, 25), mat=3, frame=2)]
        s.add(box(x0, x1, y0, y1, 0, 34, mats, wall_tex(feats, plinth=(3.5, 5))))
        s.add(hip(x0 - 5, x1 + 5, y0 - 5, y1 + 5, 33, 58, mats=[R, W], tex=rt))
        tv(s, x1, yc - 6, yc + 20, R, seed)
        bush_ys = (yc + 24, yc + 31, yc + 38)
        teras = (x1, yc - 6, yc + 20)
        ant = (x0 + 34, yc + 14 - (seed % 2) * 20, 34, 72)
    elif kind == 'pelana':
        y0, y1 = yc - 36, yc + 36
        feats = [
            dict(face='+x', u=(yc + 10, yc + 22), v=(2, 25), mat=1, frame=2, kind='door', handle=4),
            dict(face='+x', u=(yc - 26, yc - 4), v=(12, 25), mat=3, frame=2),
            dict(face='+x', u=(yc - 4, yc + 4), v=(42, 48), mat=4, frame=2, kind='nako'),
            dict(face='+y', u=(x0 + 18, x0 + 34), v=(12, 25), mat=3, frame=2),
            dict(face='+y', u=(x0 + 54, x0 + 70), v=(12, 25), mat=3, frame=2)]
        tex = wall_tex(feats, plinth=(3.5, 5))
        s.add(box(x0, x1, y0, y1, 0, 34, mats, tex))
        s.add(gable(x0 - 4, x1 + 4, y0 - 5, y1 + 5, 34, 62, 'x', mats=[R, W], tex=rt))
        s.add(gable(x0, x1, y0, y1, 34, 59, 'x', mats=mats, tex=tex, part=s.prims[-1].part))
        tv(s, x1, yc + 4, yc + 30, R, seed, kind='dak', h=26)
        bush_ys = (yc - 30, yc - 22)
        teras = (x1, yc + 4, yc + 30)
        ant = (x0 + 30, yc - 12, 50, 80)
    else:  # sayap
        xb = x1 - 16
        feats = [
            dict(face='+x', u=(yc + 6, yc + 18), v=(2, 25), mat=1, frame=2, kind='door', handle=4),
            dict(face='+x', u=(yc + 24, yc + 38), v=(12, 25), mat=3, frame=2),
            dict(face='+y', u=(x0 + 18, x0 + 34), v=(12, 25), mat=3, frame=2),
            dict(face='+y', u=(x0 + 54, x0 + 70), v=(12, 25), mat=3, frame=2)]
        s.add(box(x0, xb, y0, y1, 0, 34, mats, wall_tex(feats, plinth=(3.5, 5))))
        s.add(hip(x0 - 5, xb + 5, y0 - 5, y1 + 5, 33, 56, mats=[R, W], tex=rt))
        wy0, wy1 = y0, yc - 2
        wf = [dict(face='+x', u=(wy0 + 8, wy1 - 8), v=(10, 25), mat=3, frame=2, kind='window'),
              dict(face='+y', u=(xb + 2, x1 - 3), v=(12, 24), mat=3, frame=2)]
        wt = wall_tex(wf, plinth=(3.5, 5))
        s.add(box(xb - 2, x1, wy0, wy1, 0, 33, mats, wt))
        s.add(gable(xb - 6, x1 + 4, wy0 - 3, wy1 + 3, 33, 52, 'x', mats=[R, W], tex=rt))
        s.add(gable(xb - 2, x1, wy0, wy1, 33, 50, 'x', mats=mats, tex=wt, part=s.prims[-1].part))
        tv(s, xb, yc + 2, yc + 26, R, seed, h=26)
        bush_ys = (yc + 30, yc + 37)
        teras = (xb, yc + 2, yc + 26)
        ant = (x0 + 30, yc + 20, 34, 70)
    for i, py in enumerate(bush_ys):
        bush(s, x1 + 4, py, 4.2, seed=seed * 7 + i, mat=None if pelanggan else P['grass_dk'])
    if pelanggan:
        pot_plant(s, x1 + 3, yc - 3 if kind != 'pelana' else yc + 1, 2.6, seed=seed)
        if kotak:
            kotak_surat(s, -PR.EDGE[1] - 5, yc + 24)
    if antena_kind == 'auto':
        antena_kind = kind_for(seed)
    if antena_kind:
        ax, ay, az0, az1 = ant
        if antena_kind.startswith('parabola'):
            az0 = az0 + 2
        antena_v(s, antena_kind, ax, ay, az0, az1, seed=seed)
    return teras


# ---------------------------------------------------------- sprite tunggal ----
def render_sprite(build, tname='siang', pad=6, ground_mats=None, extra_px=(18, 12)):
    """Render objek di atas tanah datar, lalu keluarkan RGBA: objek + garis luar opak, bayangan tanah
    sebagai penanda #000000 alpha 71 (28%), sisa tanah transparan. Titik pijak = proyeksi (0,0,0)."""
    tmp = Scene(8, 8, 0, 0)
    build(tmp)
    lo = np.min([p.lo for p in tmp.prims], 0)
    hi = np.max([p.hi for p in tmp.prims], 0)
    cs = np.array([[x, y, z] for x in (lo[0], hi[0]) for y in (lo[1], hi[1]) for z in (0, hi[2])])
    sx, sy = cs[:, 0] - cs[:, 1], (cs[:, 0] + cs[:, 1]) / 2 - cs[:, 2]
    # ruang ekstra ke kanan bawah untuk bayangan
    x0, x1 = math.floor(sx.min()) - pad, math.ceil(sx.max()) + pad + extra_px[0]
    y0, y1 = math.floor(sy.min()) - pad, math.ceil(sy.max()) + pad + extra_px[1]
    W, H = x1 - x0, y1 - y0
    s = Scene(W, H, -x0, -y0)
    gm = ground_mats or [P['grass']]
    s.add(ground_prim(lambda x, y: (np.zeros(len(x), int), np.ones(len(x), int)), gm))
    extra = build(s)
    s.render(TIMES[tname])
    s.compose()
    img = s.img.copy()
    img = draw_ropes(s, img)
    b = s._buf
    prim = b['prim'].reshape(H, W)
    shade = b['shade'].reshape(H, W)
    rgba = np.zeros((H, W, 4), np.uint8)
    obj = prim > 0
    is_out = np.all(np.abs(img - OUT) < 0.5, axis=2) | np.all(np.abs(img - np.array([46, 40, 54])) < 0.5, axis=2)
    ground = prim == 0
    rgba[obj, :3] = np.clip(img[obj], 0, 255).astype(np.uint8)
    rgba[obj, 3] = 255
    gout = ground & is_out
    rgba[gout, :3] = OUT.astype(np.uint8); rgba[gout, 3] = 255
    gsh = ground & shade & ~is_out
    rgba[gsh] = (0, 0, 0, 71)
    if isinstance(extra, dict) and 'state' in extra:
        flat_rgba = rgba.reshape(-1, 4)
        g = (prim.ravel() == 0) & ~is_out.ravel()
        for idx, a, col in kolam_masker(s, extra):
            idx = idx[g[idx]]
            flat_rgba[idx] = (col[0], col[1], col[2], int(a * 255))
        for X, Y, col, a in asap_puffs(s, extra, extra.get('t', 0.0)):
            if 0 <= X < W and 0 <= Y < H:
                if rgba[Y, X, 3] == 255 and not gout[Y, X]:
                    c = rgba[Y, X, :3] * (1 - a) + np.array(col) * a
                    rgba[Y, X, :3] = c.astype(np.uint8)
                else:
                    rgba[Y, X] = (col[0], col[1], col[2], int(a * 255))
    return rgba, (-x0, -y0), s, extra


# ------------------------------------------------------------- antena TV ----
ANT_ALU = Mat('#C4C0C8', '#8A8692', '#5A5662')
ANT_BAMBU = Mat('#EAD48E', '#C9A85A', '#8A6E34')
ANT_PUTIH = Mat('#FBF6E8', '#DCD6CC', '#A8A2A0')
ANT_JARING = Mat('#6E6A76', '#3D3A46', '#221E26')
ANT_PANEL = Mat('#8E8A94', '#5F5B66', '#3D3A46')
ANT_KINDS = ['yagi', 'yagi_bambu', 'yagi_ganda', 'parabola', 'parabola_jaring', 'panel_digital']


def _ant_dir(seed):
    rng = np.random.default_rng(seed)
    d = ANT_DIR.copy()
    a = math.atan2(d[1], d[0]) + (rng.random() - 0.5) * 0.25
    return np.array([math.cos(a), math.sin(a), 0.0])


def _yagi(s, top, d, n, boom, mat, pid, lmax=11.0):
    side = np.array([-d[1], d[0], 0.0]); up = np.array([0, 0, 1.0])
    s.add(obox(top + d * boom * 0.25, d, side, up, boom / 2, 0.5, 0.5, mat, part=pid))
    for i in range(n):
        t = i / (n - 1)
        p = top + d * (-boom * 0.25 + boom * t)
        L = lmax - (lmax - 5) * t
        s.add(obox(p, side, d, up, L / 2, 0.5, 0.45, mat, part=pid))


def antena_v(s, kind, x, y, z0, z1, seed=0):
    """Enam jenis antena TV (usulan): yagi (lib.antena), yagi di tiang bambu tinggi, dua yagi bertumpuk,
    parabola putih, parabola jaring besar, antena panel digital (DVB-T2) dengan booster."""
    start = len(s.prims)
    _antena_isi(s, kind, x, y, z0, z1, seed)
    for p in s.prims[start:]:
        p.tag = 'antena'


def _antena_isi(s, kind, x, y, z0, z1, seed):
    d = _ant_dir(seed)
    side = np.array([-d[1], d[0], 0.0]); up = np.array([0, 0, 1.0])
    if kind == 'yagi':
        antena(s, x, y, z0, z1, seed=seed)
    elif kind == 'yagi_bambu':
        z1 = z1 + 18
        node = lambda Pw, Nw: (np.where(np.mod(Pw[:, 2], 9) < 1.0, 1, 0), 0)
        s.add(cyl((x, y), 1.1, z0, z1, mats=[ANT_BAMBU, Mat('#B4935A', '#8A6E34', '#5E4A24')], tex=node))
        pid = s.prims[-1].part
        _yagi(s, np.array([x, y, z1 - 1.0]), d, 8, 24, ANT_ALU, pid, lmax=12)
    elif kind == 'yagi_ganda':
        s.add(cyl((x, y), 0.9, z0, z1 + 4, mats=ANT_ALU))
        pid = s.prims[-1].part
        _yagi(s, np.array([x, y, z1 + 3]), d, 6, 18, ANT_ALU, pid)
        a = math.atan2(d[1], d[0]) - 0.35
        d2 = np.array([math.cos(a), math.sin(a), 0.0])
        _yagi(s, np.array([x, y, z1 - 7]), d2, 4, 12, ANT_ALU, pid, lmax=9)
    elif kind in ('parabola', 'parabola_jaring'):
        big = kind == 'parabola_jaring'
        r = 9.0 if big else 7.5
        zc = max(z0 + (14 if big else 10), z1 - (8 if big else 12))   # piringan di atas bubungan
        s.add(cyl((x, y), 0.9, z0, zc - 1, mats=ANT_JARING if big else ANT_ALU))
        pid = s.prims[-1].part
        el = math.radians(42)
        nrm_ = d * math.cos(el) + up * math.sin(el)          # menghadap langit ke arah satelit
        u = side
        v = np.cross(nrm_, u); v = v / panjang(v)
        c = np.array([x, y, zc]) + d * 1.5
        R = np.stack([u, v, nrm_])
        if big:
            def mesh(Pw, Nw, c=c, u=u, v=v):
                q = Pw - c
                a_ = np.floor(mm(q, u) / 1.6); b_ = np.floor(mm(q, v) / 1.6)
                return np.where((np.mod(a_, 2) == 0) | (np.mod(b_, 2) == 0), 0, 1), 0
            s.add(ellip(c, (r, r, 1.4), [ANT_JARING, Mat('#9A96A2', '#6E6A76', '#4E4A56')], mesh, R=R, part=pid))
        else:
            s.add(ellip(c, (r, r, 1.2), ANT_PUTIH, None, R=R, part=pid))
        # lengan dan LNB di depan piringan
        lnb = c + nrm_ * (r * 0.8)
        _limb_part(s, c - v * (r * 0.8), lnb, 0.35, ANT_ALU, pid)
        s.add(obox(lnb, u, v, nrm_, 1.0, 1.0, 1.4, ANT_JARING if not big else ANT_PUTIH, part=pid))
    elif kind == 'panel_digital':
        s.add(cyl((x, y), 0.8, z0, z1 - 6, mats=ANT_ALU))
        pid = s.prims[-1].part
        fn = nrm(d * 0.5 + side)                      # setengah menghadap pemancar, cukup terbaca dari kamera
        fu = nrm(np.cross(up, fn))
        c = np.array([x, y, z1 - 2]) + fn * 1.2
        grid = lambda Pw, Nw, c=c, fu=fu, fn=fn: (np.where((np.mod(np.floor(mm(Pw - c, fu) / 1.5), 2) == 0) & (np.abs(mm(Nw, fn)) > 0.6), 1, 0), 0)
        s.add(obox(c, fu, fn, up, 4.5, 0.6, 5.5, [ANT_PANEL, ANT_ALU], grid, part=pid))
        s.add(obox(np.array([x, y, z1 - 12]) - fn * 1.2, fu, fn, up, 1.4, 1.0, 1.8, ANT_PUTIH, part=pid))  # booster


def _limb_part(s, a, b, r, mat, part):
    _limb(s, a, b, r, mat, part)


def kind_for(seed):
    return ANT_KINDS[seed % len(ANT_KINDS)]


def pasang_antena_varian():
    """Ganti lib.antena di perumahan.py supaya rumah sisi dekat juga memakai variasi."""
    def _v(s, x, y, z0, z1, n=5, boom=16, seed=0, mat=None, tiang=None):
        antena_v(s, kind_for(seed), x, y, z0, z1, seed=seed)
    PR.antena = _v


# ------------------------------------------------------ rumah sisi dekat ----
TOREN = Mat('#7FB2E0', '#5F96C8', '#3E6A96')
TOREN_O = Mat('#FFB061', '#EE8A32', '#AD5C1C')
JEMUR = [Mat('#F7D9DC', '#F0C8CD', '#BB9C9F'), Mat('#FFE08A', '#FFC94A', '#C98E2A'), Mat('#7FB2E0', '#5F96C8', '#3E6A96'),
         Mat('#FFFFFF', '#F2E7C9', '#C2AF86'), Mat('#8FD49A', '#4FA466', '#2F7046')]


def house_near_v(s, yc, wall, roof, seed=0, pelanggan=True, kotak=True, antena_kind='auto', mundur=0,
                 belakang='auto'):
    """Salinan PR.house_near (sisi dekat: yang terlihat dinding belakang) dengan varian pelanggan / bukan.
    mundur: geser rumah menjauh dari jalan (unit dunia) supaya kotak surat di tepi lajur tidak tertutup atap.
    belakang: isi halaman belakang: 'toren', 'jemuran', 'keduanya', None, atau 'auto' (dari seed)."""
    if pelanggan:
        W, R, glass = P[wall], P[roof], P['glass']
    else:
        W, R, glass = BUKAN_WALL, BUKAN_ROOF, TIRAI
    x0, x1 = PR.NX0 + mundur, PR.NX1 + mundur
    y0, y1 = yc - 40, yc + 40
    feats = [
        dict(face='+x', u=(yc - 6, yc + 4), v=(2, 22), mat=1, frame=2, kind='door', handle=4),
        dict(face='+x', u=(yc + 14, yc + 26), v=(13, 22), mat=3, frame=2, kind='nako'),
        dict(face='+x', u=(yc - 30, yc - 20), v=(15, 22), mat=3, frame=2, kind='nako'),
        dict(face='+y', u=(x0 + 22, x0 + 36), v=(12, 24), mat=3, frame=2),
        dict(face='+y', u=(x0 + 52, x0 + 66), v=(12, 24), mat=3, frame=2),
    ]
    mats = [W, P['wood'] if pelanggan else P['wood_dk'], P['white'] if pelanggan else P['conc'], glass, P['metal_dk'], P['conc']]
    s.add(box(x0, x1, y0, y1, 0, 32, mats, wall_tex(feats, plinth=(3.5, 5))))
    rt = roof_tex('genteng', seed + 9, wall=True)
    k = seed % 3
    if k == 0:
        s.add(hip(x0 - 5, x1 + 5, y0 - 5, y1 + 5, 31, 54, mats=[R, W], tex=rt))
    elif k == 1:
        s.add(gable(x0 - 4, x1 + 4, y0 - 5, y1 + 5, 32, 56, 'x', mats=[R, W], tex=rt))
        s.add(gable(x0, x1, y0, y1, 32, 53, 'x', mats=W, part=s.prims[-1].part))
    else:
        s.add(gable(x0 - 5, x1 + 5, y0 - 4, y1 + 4, 32, 52, 'y', mats=[R, W], tex=rt))
        s.add(gable(x0, x1, y0, y1, 32, 50, 'y', mats=W, part=s.prims[-1].part))
    # kanopi seng di atas pintu belakang
    s.add(shed(x1, x1 + 12, yc - 12, yc + 10, 25, 22, '+x', 1.5, mats=P['metal'], tex=roof_tex('seng')))
    for py in (yc - 11, yc + 8):
        s.add(box(x1 + 10, x1 + 11.5, py, py + 1.5, 0, 22, P['metal_dk']))
    # halaman belakang
    if belakang == 'auto':
        belakang = ['toren', 'jemuran', 'keduanya', None][seed % 4]
    if belakang in ('toren', 'keduanya'):
        tx, ty = x1 + 18, yc + 26
        for dx in (-4, 4):
            for dy in (-4, 4):
                s.add(box(tx + dx - 0.7, tx + dx + 0.7, ty + dy - 0.7, ty + dy + 0.7, 0, 16, P['metal_dk']))
        s.add(box(tx - 5, tx + 5, ty - 5, ty + 5, 16, 17.5, P['metal_dk']))
        s.add(cyl((tx, ty), 5.2, 17.5, 28, mats=TOREN_O if (seed % 2) else TOREN))
        s.add(cyl((tx, ty), 2.2, 28, 29.5, mats=TOREN_O if (seed % 2) else TOREN, part=s.prims[-1].part))
    if belakang in ('jemuran', 'keduanya'):
        jx = x1 + 24
        ya, yb = yc - 34, yc + (6 if belakang == 'keduanya' else 30)
        for py in (ya, yb):
            s.add(box(jx - 0.6, jx + 0.6, py - 0.6, py + 0.6, 0, 22, P['metal_dk']))
        items = [(0.15, 6, 9, JEMUR[(seed + 0) % 5], 'kaus'), (0.38, 4, 11, JEMUR[(seed + 1) % 5], 'celana'),
                 (0.6, 7, 10, JEMUR[(seed + 2) % 5], 'handuk'), (0.82, 5, 8, JEMUR[(seed + 3) % 5], 'kaus')]
        clothes_line(s, (jx, ya, 21), (jx, yb, 21), items)
    if pelanggan and kotak:
        kotak_surat(s, PR.EDGE[1] + 5, yc - 26)
    if antena_kind == 'auto':
        antena_kind = kind_for(seed + 20)
    if antena_kind:
        az0 = 32 + (2 if antena_kind.startswith('parabola') else 0)
        antena_v(s, antena_kind, x0 + 50, yc - 8, az0, 68, seed=seed + 20)


# ------------------------------------------- rumah sisi dekat run 5D (teras menjorok) ----
# Koordinat lokal = tengah tapak gambar di (0, 0, 0): x positif menjauh dari jalan (sisi dekat), y positif = mundur sepanjang jalan
# (maju negatif), 32 unit = 1 ubin. Game menaruh titik pijak ini di tengah tapak logika + RUTE_RUMAH_DEKAT_MUNDUR_UBIN (0,5), jadi
# lateral dunia = 5,0 + x / 32. Kamera melihat muka +x (belakang rumah), +y (samping, sisi maju kecil), dan atap; muka -x (depan, ke jalan)
# tersembunyi. Aturan bentuk (run fase5d, AC-3, AC-6): setiap titik rumah (lateral L, tinggi H, ubin) memenuhi L - H >= sekitar 2,8 supaya
# tidak ada piksel yang jatuh di atas zona kotak surat dekat (lateral 1,75..2,75) atau pemain di trotoar dekat (lateral 1..2): sinar ke kamera dari
# titik tanah (l, m) naik satu ubin per ubin lateral. Karena itu badan rumah mundur ke belakang tapak, atap sisi jalan rendah (pelana lintang
# dibuat perisai di ujung jalan; segitiga pelana hanya di belakang), dan teras menjorok ke jalan beratap sandar rendah di ujung maju kecil
# (sisi +y yang terlihat kamera) sehingga lantai, tiang, dan atapnya terbaca dari samping.
DEKAT_BADAN = (-30, 40, -40, 40)          # x0, x1, y0, y1 badan rumah
DEKAT_DINDING_Z = 30                      # tinggi dinding
DEKAT_TERAS = (-58, -30, 14, 44)          # lantai teras: x0 (ujung ke jalan), x1 (kaki dinding depan), y0, y1
DEKAT_TERAS_Z = 2.5                       # tinggi lantai teras
DEKAT_TERAS_ATAP = (27, 21)               # atap sandar teras: tinggi di dinding, tinggi di ujung jalan
DEKAT_ATAP = {'limasan': 52, 'pelana_lintang': 54, 'pelana_sejajar': 50}   # puncak atap per jenis
DEKAT_CUCURAN = 5                         # cucuran atap melewati dinding


def _perisai_jalan(prim, x_ujung, run, z_puncak, z_cucur):
    """Tambah bidang miring di ujung -x prisma pelana lintang: atap perisai (limasan) di sisi jalan, segitiga pelana tinggal di belakang."""
    k = (z_puncak - z_cucur) / run
    n = np.array([-k, 0.0, 1.0])
    d = z_puncak - k * (x_ujung + run)
    prim.planes.append((nrm(n), float(d) / panjang(n)))


def house_near_teras(s, wall, roof, jenis='limasan', seed=0, pelanggan=True, belakang='toren', antena_kind='yagi'):
    """Rumah sisi dekat run 5D (usulan): badan rumah di belakang tapak, atap sisi jalan rendah, teras menjorok ke jalan beratap sandar
    di ujung maju kecil (terbaca dari samping), TANPA kotak surat (kotak surat = sprite terpisah). Pelanggan: warna dinding/atap palet,
    keset merah, pot; bukan pelanggan: kusam abu-abu (BUKAN_WALL, BUKAN_ROOF, tirai), lantai abu-abu, tanpa keset. Kembali: dict geometri
    (unit lokal) untuk JSON: teras, penutup."""
    if pelanggan:
        W, R, glass = P[wall], P[roof], P['glass']
    else:
        W, R, glass = BUKAN_WALL, BUKAN_ROOF, TIRAI
    x0, x1, y0, y1 = DEKAT_BADAN
    zd = DEKAT_DINDING_Z
    feats = [
        dict(face='+x', u=(-6, 4), v=(2, 21), mat=1, frame=2, kind='door', handle=4),
        dict(face='+x', u=(14, 26), v=(12, 21), mat=3, frame=2, kind='nako'),
        dict(face='+x', u=(-30, -20), v=(14, 21), mat=3, frame=2, kind='nako'),
        dict(face='+y', u=(x0 + 8, x0 + 20), v=(9, 22), mat=1, frame=2, kind='door', handle=4),   # pintu samping ke teras
        dict(face='+y', u=(x0 + 32, x0 + 46), v=(11, 22), mat=3, frame=2),
        dict(face='+y', u=(x0 + 54, x0 + 66), v=(11, 22), mat=3, frame=2),
    ]
    mats = [W, P['wood'] if pelanggan else P['wood_dk'], P['white'] if pelanggan else P['conc'], glass, P['metal_dk'], P['conc']]
    tex = wall_tex(feats, plinth=(3.5, 5))
    s.add(box(x0, x1, y0, y1, 0, zd, mats, tex))
    rt = roof_tex('genteng', seed + 9, wall=True)
    c = DEKAT_CUCURAN
    zt = DEKAT_ATAP[jenis]
    if jenis == 'limasan':
        s.add(hip(x0 - c, x1 + c, y0 - c, y1 + c, zd - 1, zt, mats=[R, W], tex=rt))
    elif jenis == 'pelana_lintang':
        s.add(gable(x0 - c, x1 + c, y0 - c, y1 + c, zd, zt, 'x', mats=[R, W], tex=rt))
        atap = s.prims[-1]
        run = (y1 - y0) / 2 + c
        _perisai_jalan(atap, x0 - c, run, zt, zd)
        s.add(gable(x0, x1, y0, y1, zd, zt - 3, 'x', mats=W, tex=tex, part=atap.part))
        _perisai_jalan(s.prims[-1], x0, run - c, zt - 3, zd)
    else:
        s.add(gable(x0 - c, x1 + c, y0 - c + 1, y1 + c - 1, zd, zt, 'y', mats=[R, W], tex=rt))
        s.add(gable(x0, x1, y0, y1, zd, zt - 2, 'y', mats=W, tex=tex, part=s.prims[-1].part))
    # teras menjorok ke jalan di ujung +y: lantai, keset, tiga tiang, atap sandar rendah, lampu
    tx0, tx1, ty0, ty1 = DEKAT_TERAS
    awal_teras = len(s.prims)
    lantai = P['paper'] if pelanggan else BUKAN_TERAS
    s.add(box(tx0, tx1, ty0, ty1, 0, DEKAT_TERAS_Z, lantai,
              lambda Pw, Nw: (0, np.where((np.mod(Pw[:, 0], 5) < 0.8) | (np.mod(Pw[:, 1], 5) < 0.8), 1, 0)),
              outline=True, cast=False))
    yc = (ty0 + ty1) / 2
    if pelanggan:
        s.add(box(tx1 - 9, tx1 - 3, yc - 3, yc + 5, DEKAT_TERAS_Z, 3.2, P['red'], outline=False, cast=False))   # keset di depan pintu samping
    za, zb = DEKAT_TERAS_ATAP
    tiang = P['white'] if pelanggan else P['conc']
    for px, py in ((tx0 + 1, ty1 - 3), (tx0 + 1, ty0 + 1), ((tx0 + tx1) / 2, ty1 - 3)):
        s.add(box(px, px + 2, py, py + 2, DEKAT_TERAS_Z, zb + (za - zb) * (px - tx0) / (tx1 - tx0) - 1, tiang))
    s.add(shed(tx0 - 2, tx1, ty0 - 2, ty1 + 2, za, zb, '-x', 2, mats=R, tex=roof_tex('flat')))
    s.add(box(tx1 - 2.5, tx1 - 0.5, yc - 1, yc + 1, za - 6, za - 4, P['lamp']))
    if pelanggan:
        pot_plant(s, tx0 + 5, ty1 - 6, 2.4, seed=seed)
    for p_ in s.prims[awal_teras:]:
        p_.tag = 'teras'
    # belakang: kanopi seng di atas pintu belakang, toren dan/atau jemuran (seperti house_near_v)
    s.add(shed(x1, x1 + 12, -12, 10, 25, 22, '+x', 1.5, mats=P['metal'], tex=roof_tex('seng')))
    for py in (-11, 8):
        s.add(box(x1 + 10, x1 + 11.5, py, py + 1.5, 0, 22, P['metal_dk']))
    if belakang in ('toren', 'keduanya'):
        tx, ty = x1 + 18, 26
        for dx in (-4, 4):
            for dy in (-4, 4):
                s.add(box(tx + dx - 0.7, tx + dx + 0.7, ty + dy - 0.7, ty + dy + 0.7, 0, 16, P['metal_dk']))
        s.add(box(tx - 5, tx + 5, ty - 5, ty + 5, 16, 17.5, P['metal_dk']))
        s.add(cyl((tx, ty), 5.2, 17.5, 28, mats=TOREN_O if (seed % 2) else TOREN))
        s.add(cyl((tx, ty), 2.2, 28, 29.5, mats=TOREN_O if (seed % 2) else TOREN, part=s.prims[-1].part))
    if belakang in ('jemuran', 'keduanya'):
        jx = x1 + 24
        ya, yb = -34, (6 if belakang == 'keduanya' else 30)
        for py in (ya, yb):
            s.add(box(jx - 0.6, jx + 0.6, py - 0.6, py + 0.6, 0, 22, P['metal_dk']))
        items = [(0.15, 6, 9, JEMUR[(seed + 0) % 5], 'kaus'), (0.38, 4, 11, JEMUR[(seed + 1) % 5], 'celana'),
                 (0.6, 7, 10, JEMUR[(seed + 2) % 5], 'handuk'), (0.82, 5, 8, JEMUR[(seed + 3) % 5], 'kaus')]
        clothes_line(s, (jx, ya, 21), (jx, yb, 21), items)
    if antena_kind:
        az0 = zd + (2 if antena_kind.startswith('parabola') else 0)
        antena_v(s, antena_kind, x0 + 52, -8, az0, 66, seed=seed + 20)
    return dict(teras=(tx0, tx1, ty0, ty1), badan=(x0 - c, x1 + c, y0 - c, y1 + c), puncak=zt)


# ------------------------------------------------------------- layar contoh ----
# status rumah sisi seberang, urutan PR.FAR_YC = [-448, -320, -192, -64, 64, 192, 320, 448]
PELANGGAN = [True, False, True, True, False, True, True, False]
MOBIL_YC = -64            # mobil mundur dari jalan masuk rumah ini
ANJING_YC = 64             # anjing di halaman rumah ini (bukan pelanggan)
KORAN_YC = 192             # koran sudah tergeletak di teras rumah ini
ANJING_SIZE = 1.15
# distrik lanjutan dengan pelanggan di dua sisi (usulan): status rumah sisi dekat, urutan PR.NEAR_YC
NEAR_PELANGGAN = [True, False, True, True, False, True, True]


def build_fase3(s, mobil_state='nyala', anjing_pose='lari_1', anjing_pos=(-84, 12), dua_sisi=False):
    pasang_antena_varian()
    mats = [P['grass'], P['asph'], P['mark'], P['conc']]
    s.add(ground_prim(PR.region, mats))
    far_gaps = [PR.far_drive(yc) for yc in PR.FAR_YC]
    near_gaps = [PR.near_drive(yc) for yc in PR.NEAR_YC]
    for sg, gaps in ((-1, far_gaps), (1, near_gaps)):
        a, b = (PR.SEP if sg > 0 else (-PR.SEP[1], -PR.SEP[0]))
        PR.kerb_with_gaps(s, a, b, 3, P['kerb'], gaps)
        a, b = (PR.BIKE if sg > 0 else (-PR.BIKE[1], -PR.BIKE[0]))
        s.add(box(a, b, -900, 900, 0, 2, [PR.BIKE_MAT, P['mark']], PR.bike_tex, outline=False, cast=False))
        a, b = (PR.EDGE if sg > 0 else (-PR.EDGE[1], -PR.EDGE[0]))
        PR.kerb_with_gaps(s, a, b, 2.6, P['kerb'], gaps)
    teras = {}
    for i, yc in enumerate(PR.FAR_YC):
        teras[yc] = house_far_v(s, yc, PR.WALLS[i], PR.ROOFS[i], seed=i, kind=PR.HOUSE_TYPES[i % 3],
                                pelanggan=PELANGGAN[i])
        if i % 4 != 3:
            tree_perumahan(s, PR.FX1 - 26, yc + 64, TREE_KINDS[i % 3], seed=i)
        else:
            bush(s, PR.FX1 - 10, yc + 62, 6, seed=i)
            bush(s, PR.FX1 - 22, yc + 70, 5, seed=i + 3)
    for i, yc in enumerate(PR.NEAR_YC):
        if dua_sisi:
            house_near_v(s, yc, PR.WALLS[(i + 3) % 8], PR.ROOFS[(i + 2) % 8], seed=i, pelanggan=NEAR_PELANGGAN[i],
                         mundur=22)
        else:
            PR.house_near(s, yc, PR.WALLS[(i + 3) % 8], PR.ROOFS[(i + 2) % 8], seed=i)
        bush(s, PR.NX0 - 10, yc + 10, 5, seed=20 + i)
        if i % 2 == 1:
            tree_perumahan(s, PR.NX1 + 30, yc + 54, TREE_KINDS[(i + 1) % 3], seed=30 + i)
    for i, yc in enumerate([-420, -300, -180, -60, 60, 180]):
        s.add(box(PR.FX0 - 146, PR.FX0 - 64, yc - 40, yc + 40, 0, 32, P[PR.WALLS[(i + 5) % 8]]))
        s.add(hip(PR.FX0 - 151, PR.FX0 - 59, yc - 45, yc + 45, 31, 54, mats=[P[PR.ROOFS[(i + 1) % 8]], P['cream']],
                  tex=roof_tex('genteng', 40 + i, wall=True)))
        if i % 2 == 1:
            antena_v(s, kind_for(40 + i), PR.FX0 - 100, yc + 10, 32, 68, seed=40 + i)
    for i, yc in enumerate([-370, -250, -130, -10, 110]):
        tree_perumahan(s, PR.FX0 - 34, yc, TREE_KINDS[(i + 2) % 3], seed=50 + i)
    s.add(box(PR.NX1 + 50, PR.NX1 + 54, -900, 900, 0, 14, P['conc']))
    for ly in (-256, -18, 256):
        lamp_post(s, -PR.EDGE[1] - 3, ly, h=58, arm=15, toward=+1, light_r=100)
    tong_sampah(s, PR.EDGE[1] + 5, -80 if dua_sisi else -40)
    # mobil keluar garasi: tengah jalan masuk rumah MOBIL_YC, bagasi sudah melewati kerb ke lajur sepeda
    a, b = PR.far_drive(MOBIL_YC)
    info = mobil_mundur(s, -84, (a + b) / 2, mobil_state)
    # anjing penjaga di halaman depan rumah ANJING_YC
    anjing(s, anjing_pos[0], anjing_pos[1], anjing_pose, size=ANJING_SIZE)
    return info, teras


# koran gulung mendatar, frame 0 KORAN_PUTAR di scripts/systems/pola_piksel.gd
KORAN = ["........", ".oooooo.", "otsttsto", "otsttsto", ".oooooo.", "........"]


def koran_sprite():
    kc = {'o': (14, 10, 28, 255), 't': (255, 243, 227, 255), 's': (205, 185, 163, 255)}
    a = np.zeros((6, 8, 4), np.uint8)
    for y, r in enumerate(KORAN):
        for x, ch in enumerate(r):
            if ch in kc:
                a[y, x] = kc[ch]
    return a


def render(tname='siang', W=640, H=360, ox=427, oy=172, batas=False, out='layar_fase3.png', dua_sisi=False):
    s = Scene(W, H, ox, oy)
    info, teras = build_fase3(s, dua_sisi=dua_sisi)
    tc = TIMES[tname]
    s.render(tc)
    x1, ya, yb = teras[KORAN_YC]
    sprites = [(PR.loper_frame(5, 1), (23, 46), PR.PLAYER)]
    img = finish_with_sprites(s, sprites)
    # koran terkirim: ditempel opak di lantai teras (tidak ada yang menutupinya dari kamera)
    kx, ky = s.proj((x1 + 8, (ya + yb) / 2 - 2, 2.5))
    ks = koran_sprite()
    X0, Y0 = int(kx[0]) - 4, int(ky[0]) - 3
    for yy in range(ks.shape[0]):
        for xx in range(ks.shape[1]):
            if ks[yy, xx, 3]:
                img[Y0 + yy, X0 + xx] = ks[yy, xx, :3]
    img = draw_ropes(s, img)
    img = kolam_cahaya(s, img, info)
    for X, Y, col, a in asap_puffs(s, info, 0.0):
        if 0 <= X < W and 0 <= Y < H:
            img[Y, X] = img[Y, X] * (1 - a) + np.array(col, np.float32) * a
    if batas:   # anotasi: batas halaman tempat anjing berhenti (ujung petak rumah 64)
        for xw in np.arange(PR.FX1 + 1, -PR.EDGE[1], 0.5):
            sx, sy = s.proj((xw, -4.0, 0.0))
            X, Y = int(sx[0]), int(sy[0])
            if (int(xw) // 3) % 2 == 0 and 0 <= X < W and 0 <= Y < H:
                img[Y, X] = (255, 178, 46)
    im = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), 'RGB')
    im.save(OUT_DIR / out)
    return im, s




# ------------------------------------------------------------------ ekspor ----
ANJING_POSE = ['duduk', 'gonggong', 'lari_1', 'lari_2', 'berhenti']
MOBIL_STATE = ['parkir', 'nyala', 'redup']
RUMAH_SEBERANG = [('limasan', 'cream', 'roof_red', 'yagi'), ('pelana', 'sky', 'roof_gr', 'yagi_bambu'),
                  ('sayap', 'pink', 'roof_dk', 'parabola')]
# seed rumah sisi dekat menentukan atap: 0 limasan, 1 pelana bubungan tegak lurus jalan, 2 pelana bubungan sejajar jalan
RUMAH_DEKAT = [('limasan', 0, 'mint', 'roof_red', 'toren', 'yagi_ganda'),
               ('pelana_lintang', 1, 'cream', 'roof_dk', 'jemuran', 'panel_digital'),
               ('pelana_sejajar', 2, 'sky', 'roof_red', 'keduanya', 'parabola_jaring')]
MUNDUR_DEKAT = 22       # usulan: rumah sisi dekat mundur 3/4 ubin supaya kotak surat di tepi lajur terlihat


def _json(path, data):
    with open(path, 'w') as f:
        json.dump(data, f, indent=1, ensure_ascii=False)
        f.write('\n')


def pack(frames, names, fname, meta):
    """frames: list (rgba, titik pijak). Sel seragam, titik pijak sama di semua sel."""
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
    return sheet


def _single(a, o, fname, note, extra=None):
    Image.fromarray(a, 'RGBA').save(OUT_DIR / (fname + '.png'))
    data = {'sprite': fname + '.png', 'size': [a.shape[1], a.shape[0]], 'ground_anchor': list(o), 'note': note}
    data.update(extra or {})
    _json(OUT_DIR / (fname + '.json'), data)


UBIN = 32.0


def _persegi_ubin(x0, x1, y0, y1):
    """Persegi lokal renderer (x lateral, y = -maju, unit) -> [lateral_min, maju_min, lebar, panjang] ubin."""
    return [x0 / UBIN, -y1 / UBIN, (x1 - x0) / UBIN, (y1 - y0) / UBIN]


def penutup_dekat(prims):
    """Kotak penutup rumah dekat dari primitif nyata: AABB semua primitif kecuali teras dan antena (unit lokal)."""
    pakai = [p for p in prims if p.tag not in ('teras', 'antena')]
    lo = np.min([p.lo for p in pakai], 0)
    hi = np.max([p.hi for p in pakai], 0)
    return (float(lo[0]), float(hi[0]), float(lo[1]), float(hi[1]), float(hi[2]))


def geometri_dekat_json(geo):
    x0, x1, y0, y1 = geo['teras']
    p = geo['penutup']
    return {'teras_ubin': _persegi_ubin(x0, x1, y0, y1), 'penutup_ubin': _persegi_ubin(p[0], p[1], p[2], p[3]),
            'penutup_tinggi_ubin': p[4] / UBIN}


# Tiga nada oranye = KOTAK_SURAT di tools/env_art/graybox.py (atas, samping, fasad): warna sasaran yang sudah dikenal pemain.
KOTAK_SURAT_ORANYE = Mat('#FFE08A', '#FFC94A', '#E98E3F')


def kotak_surat_oranye(s):
    """Kotak surat sasaran rute: bentuk lib.kotak_surat() (tiang metal_dk + badan dengan celah surat), skala 1x, tanpa
    membesarkan. Titik pijak (0, 0, 0) = kaki tiang di tanah."""
    kotak_surat(s, 0, 0, mat=KOTAK_SURAT_ORANYE)


# Abu-abu logam palet induk (ART_DIRECTION 2.4: `#C4C0C8` · `#969AA0` · `#67636D`), nada atas = RADAR_BUKAN `#969AA0`: lebih redup
# dari oranye sasaran supaya sekilas saat ngebut yang terbaca tetap kotak surat pelanggan.
KOTAK_SURAT_BUKAN = Mat('#969AA0', '#67636D', '#5F5B66')


def kotak_surat_bukan(s):
    """Kotak surat rumah bukan pelanggan sisi seberang (bukan sasaran): bentuk dasar lib.kotak_surat() tetapi tiang lebih pendek
    (8 lawan 12), badan lebih kecil (6 x 4 x 5 lawan 7 x 5 x 7), tanpa celah surat, dan abu-abu. Beda bentuk dan tinggi, bukan hanya
    warna (rule ui-scenes). Titik pijak (0, 0, 0) = kaki tiang di tanah."""
    s.add(box(-1, 1, -1, 1, 0, 8, P['metal_dk']))
    s.add(box(-3, 3, -2, 2, 8, 13, KOTAK_SURAT_BUKAN))


def _no_cast_antena(s, start):
    for p in s.prims[start:]:
        if p.tag == 'antena':
            p.cast = False   # bayangan antena jatuh jauh di rumput, terpisah dari sprite


def ekspor_sprite():
    pasang_antena_varian()
    frames = [render_sprite(lambda s, p=p: anjing(s, 0, 0, p, size=ANJING_SIZE), pad=4, extra_px=(10, 6))[:2]
              for p in ANJING_POSE]
    pack(frames, ANJING_POSE, 'obs_anjing_sheet', {
        'note': 'Usulan, tools/env_art/fase3.py (cahaya siang). duduk dan gonggong menghadap jalan (kanan bawah); '
                'lari_1, lari_2, berhenti menghadap maju (kanan atas). Bayangan = penanda #000000 alpha 28%.',
        'anim': {'diam': ['duduk'], 'tanda': ['gonggong'], 'lari': ['lari_1', 'lari_2'], 'berhenti': ['berhenti']},
        'fps': {'lari': 10}})
    frames = [render_sprite(lambda s, st=st: mobil_mundur(s, 0, 0, st), ground_mats=[P['asph']], extra_px=(46, 24))[:2]
              for st in MOBIL_STATE]
    pack(frames, MOBIL_STATE, 'obs_mobil_garasi_sheet', {
        'note': 'Usulan, tools/env_art/fase3.py. Sedan lib.car() diputar 90 derajat: moncong ke garasi (kiri atas), '
                'bagasi ke jalan (kanan bawah). nyala/redup bergantian 4 fps sebagai tanda; frame nyala dipakai saat '
                'mundur. Cahaya di aspal dan asap knalpot ikut di sel (alpha).',
        'anim': {'parkir': ['parkir'], 'tanda': ['nyala', 'redup'], 'mundur': ['nyala']}, 'fps': {'tanda': 4}})
    for kind, wall, roof, antk in RUMAH_SEBERANG:
        for pel in (True, False):
            def b(s, kind=kind, wall=wall, roof=roof, pel=pel, antk=antk):
                st = len(s.prims)
                house_far_v(s, 0, wall, roof, seed=3, kind=kind, pelanggan=pel, kotak=False, antena_kind=antk)
                shift_prims(s.prims[st:], -(PR.FX0 + PR.FX1) / 2, 0)
                _no_cast_antena(s, st)
            a, o, _, _ = render_sprite(b, pad=4, extra_px=(40, 20))
            _single(a, o, 'house_perumahan_%s_%s' % (kind, 'pelanggan' if pel else 'bukan'),
                    'Usulan, tools/env_art/fase3.py. Rumah sisi seberang, fasad menghadap jalan (kanan bawah). '
                    'Titik pijak = tengah tapak. Termasuk teras, semak, pot, antena; TANPA kotak surat (kotak surat sasaran '
                    'digambar scene di pusat zona kotak surat, run 3A QA-005).')
    for nm, seed, wall, roof, bel, antk in RUMAH_DEKAT:
        for pel in (True, False):
            geo = {}

            def b(s, seed=seed, wall=wall, roof=roof, bel=bel, antk=antk, pel=pel, nm=nm):
                st = len(s.prims)
                geo.update(house_near_teras(s, wall, roof, jenis=nm, seed=seed, pelanggan=pel, belakang=bel, antena_kind=antk))
                geo['penutup'] = penutup_dekat(s.prims[st:])
                _no_cast_antena(s, st)
            a, o, _, _ = render_sprite(b, pad=4, extra_px=(34, 18))
            _single(a, o, 'house_perumahan_dekat_%s_%s' % (nm, 'pelanggan' if pel else 'bukan'),
                    'Usulan run fase5d, tools/env_art/fase3.py house_near_teras: rumah sisi dekat (terlihat belakang dan samping), '
                    'badan di belakang tapak, atap sisi jalan rendah, teras menjorok ke jalan di ujung maju kecil, TANPA kotak surat '
                    '(kotak surat = sprite terpisah). Titik pijak = tengah tapak gambar (game: tengah tapak logika + mundur 0,5 ubin). '
                    'teras_ubin dan penutup_ubin: [lateral_min, maju_min, lebar_lateral, panjang_maju] ubin relatif titik pijak '
                    '(lateral positif menjauh dari jalan); penutup_tinggi_ubin = puncak badan dan atap (tanpa teras dan antena).',
                    extra=geometri_dekat_json(geo))
    a, o, _, _ = render_sprite(kotak_surat_oranye, pad=4, extra_px=(10, 6))
    _single(a, o, 'prop_kotak_surat',
            'Usulan, tools/env_art/fase3.py. Kotak surat sasaran scene rute: bentuk lib.kotak_surat() (tiang dan badan dengan '
            'celah surat) berwarna oranye graybox (placeholder sasaran), skala 1x. Titik pijak = kaki tiang di tanah, '
            'dipasang di pusat zona kotak surat. Bayangan = penanda #000000 alpha 28%.')
    a, o, _, _ = render_sprite(kotak_surat_bukan, pad=4, extra_px=(10, 6))
    _single(a, o, 'prop_kotak_surat_bukan',
            'Usulan, tools/env_art/fase3.py. Kotak surat rumah bukan pelanggan sisi seberang (BUKAN sasaran): lebih rendah '
            'dan lebih kecil dari prop_kotak_surat, tanpa celah surat, abu-abu logam (#969AA0 atas), skala 1x. Titik pijak = '
            'kaki tiang di tanah, dipasang di titik yang sama dengan kotak surat pelanggan. Bayangan = penanda #000000 alpha 28%.')
    # lembar contoh antena di atas potongan atap (tanpa bayangan tanah)
    frames = []
    for k in ANT_KINDS:
        def b(s, k=k):
            s.add(hip(-14, 14, -14, 14, 0, 16, mats=[P['roof_red'], P['cream']], tex=roof_tex('genteng', 2, wall=True)))
            antena_v(s, k, 0, 0, 8, 30 if k.startswith('parabola') else 46, seed=3)
        a, o, _, _ = render_sprite(b, pad=4, extra_px=(24, 10))
        a[(a[..., 3] == 71) & (a[..., :3].sum(-1) == 0)] = 0
        frames.append((a, o))
    pack(frames, ANT_KINDS, 'antena_tv_contoh', {
        'note': 'Usulan, lembar contoh (bukan sprite game): antena ikut dirender bersama rumah.'})


def _rumah_dekat_lama(s, seed, wall, roof, bel, antk, pel):
    """Rumah dekat sebelum run 5D (house_near_v, mundur 22, kotak surat pelanggan terpanggang): hanya untuk lembar banding."""
    st = len(s.prims)
    cx = -(PR.NX0 + PR.NX1) / 2 - MUNDUR_DEKAT
    house_near_v(s, 0, wall, roof, seed=seed, pelanggan=pel, mundur=MUNDUR_DEKAT, belakang=bel, antena_kind=antk)
    shift_prims(s.prims[st:], cx, 0)
    s.ropes = [(p0 + np.array([cx, 0, 0]), p1 + np.array([cx, 0, 0])) for p0, p1 in getattr(s, 'ropes', [])]
    _no_cast_antena(s, st)


def _rumah_dekat_baru(s, seed, wall, roof, bel, antk, pel, nm):
    st = len(s.prims)
    house_near_teras(s, wall, roof, jenis=nm, seed=seed, pelanggan=pel, belakang=bel, antena_kind=antk)
    _no_cast_antena(s, st)


def ekspor_banding():
    """Lembar banding rumah dekat lama (atas) dan baru run 5D (bawah), tiga jenis x pelanggan/bukan, di atas rumput (mock dokumen x2)."""
    sel_w, sel_h = 330, 250
    lembar = Image.new('RGBA', (sel_w * 6, sel_h * 2), (111, 174, 79, 255))
    for baris, baru in enumerate((False, True)):
        kol = 0
        for nm, seed, wall, roof, bel, antk in RUMAH_DEKAT:
            for pel in (True, False):
                if baru:
                    b = lambda s, a=(seed, wall, roof, bel, antk, pel, nm): _rumah_dekat_baru(s, *a)
                else:
                    b = lambda s, a=(seed, wall, roof, bel, antk, pel): _rumah_dekat_lama(s, *a)
                a, o, _, _ = render_sprite(b, pad=4, extra_px=(34, 18))
                im = Image.fromarray(a, 'RGBA')
                lembar.alpha_composite(im, (kol * sel_w + 150 - o[0], baris * sel_h + 160 - o[1]))
                kol += 1
    lembar = lembar.convert('RGB')
    lembar.save(OUT_DIR / 'banding_rumah_dekat.png')


def _region_game(x, y):
    """Tanah tata letak game (config.gd): aspal 2 ubin (lateral -1..1), trotoar 1 ubin tiap sisi, rumput di luar. 32 unit = 1 ubin."""
    n = len(x)
    mi = np.zeros(n, int)
    sh = np.ones(n, int) + grass_tufts(x, y)
    ax = np.abs(x)
    road = ax < 32
    mi = np.where(road, 1, mi)
    sh = np.where(road, 1 + speckle(x, y, 5, 0.03, 0.05, 1), sh)
    dash = road & (ax < 1.2) & ((np.mod(y, 32)) < 16)
    mi = np.where(dash, 2, mi); sh = np.where(dash, 1, sh)
    walk = (ax >= 32) & (ax < 64)
    mi = np.where(walk, 3, mi); sh = np.where(walk, 1, sh)
    return mi, sh


def ekspor_layar_dekat():
    """Layar contoh run 5D dengan tata letak game: sisi dekat halaman terbuka, rumah dekat baru di tengah tapak + mundur 0,5 ubin
    (lateral 5,0), kotak surat oranye/abu-abu cermin seberang (lateral 2,125, maju kavling + 1,75), pemain di trotoar dekat."""
    s = Scene(640, 360, 300, 150)
    s.add(ground_prim(_region_game, [P['grass'], P['asph'], P['mark'], P['conc']]))
    pasang_antena_varian()
    urut = [(0, True), (1, False), (2, True), (0, False), (1, True), (2, False)]
    for i, (j, pel) in enumerate(urut):
        nm, seed, wall, roof, bel, antk = RUMAH_DEKAT[j]
        m = (i - 3) * 4                       # awal kavling, ubin
        st = len(s.prims)
        tali = len(getattr(s, 'ropes', []))
        _rumah_dekat_baru(s, seed, wall, roof, bel, antk, pel, nm)
        geser = np.array([160, -(m + 1.0) * 32, 0])
        shift_prims(s.prims[st:], geser[0], geser[1])
        if hasattr(s, 'ropes'):
            s.ropes = s.ropes[:tali] + [(p0 + geser, p1 + geser) for p0, p1 in s.ropes[tali:]]
        st = len(s.prims)
        (kotak_surat_oranye if pel else kotak_surat_bukan)(s)
        shift_prims(s.prims[st:], 68, -(m + 1.75) * 32)
    s.render(TIMES['siang'])
    sprites = [(PR.loper_frame(5, 1), (23, 46), (48.0, -2.0 * 32, 0))]
    img = finish_with_sprites(s, sprites)
    img = draw_ropes(s, img)
    Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), 'RGB').save(OUT_DIR / 'layar_dekat_5d.png')


def ekspor_layar():
    render(out='layar_fase3.png')
    render(out='layar_dua_sisi.png', dua_sisi=True)
    ekspor_banding()
    ekspor_layar_dekat()


# ------------------------------------------------------------- salin ke repo ----
SALIN_SPRITE = {
    'assets/sprites/props': ['prop_kotak_surat', 'prop_kotak_surat_bukan'],
    'assets/sprites/obstacles': ['obs_anjing_sheet', 'obs_mobil_garasi_sheet'],
    'assets/sprites/houses/perumahan': ['house_perumahan_%s_%s' % (k, p) for k, *_ in RUMAH_SEBERANG
                                        for p in ('pelanggan', 'bukan')] +
                                       ['house_perumahan_dekat_%s_%s' % (k, p) for k, *_ in RUMAH_DEKAT
                                        for p in ('pelanggan', 'bukan')],
}
# mock dokumen diperbesar x2 (docs/design/environment/README.md)
SALIN_MOCK = {'layar_fase3.png': 'fase3_perumahan.png', 'layar_dua_sisi.png': 'fase3_dua_sisi.png',
              'antena_tv_contoh.png': 'fase3_antena_tv.png', 'obs_anjing_sheet.png': 'fase3_anjing.png',
              'obs_mobil_garasi_sheet.png': 'fase3_mobil_garasi.png'}
# lembar banding dan layar contoh run 5D, disalin dengan pembesaran tetangga terdekat (kali)
SALIN_MOCK_5D = {'banding_rumah_dekat.png': ('fase3_rumah_dekat_banding.png', 2), 'layar_dekat_5d.png': ('fase3_layar_dekat_5d.png', 2)}


def salin():
    for folder, names in SALIN_SPRITE.items():
        d = SALIN_KE / folder
        d.mkdir(parents=True, exist_ok=True)
        for n in names:
            for ext in ('.png', '.json'):
                shutil.copyfile(OUT_DIR / (n + ext), d / (n + ext))
    d = SALIN_KE / 'docs/design/environment'
    d.mkdir(parents=True, exist_ok=True)
    for src, dst in SALIN_MOCK.items():
        im = Image.open(OUT_DIR / src)
        im.resize((im.width * 2, im.height * 2), Image.NEAREST).save(d / dst)
    for src, (dst, kali) in SALIN_MOCK_5D.items():
        im = Image.open(OUT_DIR / src)
        im.resize((im.width * kali, im.height * kali), Image.NEAREST).save(d / dst)


if __name__ == '__main__':
    import time
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    t = time.time()
    ekspor_sprite()
    ekspor_layar()
    print('render', round(time.time() - t, 1), 'detik ->', OUT_DIR)
    if '--salin' in sys.argv[1:]:
        salin()
        print('disalin ke assets/sprites/ dan docs/design/environment/')
