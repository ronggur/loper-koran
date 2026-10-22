"""Kendaraan dan kucing (usulan): mobil dan motor, parkir dan berjalan, serta kucing.

Memakai engine.py, lib.py, perumahan.py, dan fase3.py apa adanya. Model baru:
- mobil(): sedan (= bentuk lib.car), hatchback, MPV, pikap bak, angkot (lib.angkot); empat arah,
  lampu mati / jalan / rem / sein
- motor(): matic, bebek, sport, motor sayur; parkir dengan standar samping (miring), jalan dengan pengendara
- kucing(): tujuh pose, lima warna (belang tiga berkalung = kucing misi Bu Ratmi)

Arah (dunia): searah = moncong ke -y (kanan atas, searah pemain, lajur kiri), lawan = ke +y (kiri bawah),
masuk = ke -x (kiri atas, moncong ke rumah sisi seberang), keluar = ke +x (kanan bawah).

    python3 tools/env_art/kendaraan.py          # sheet + layar contoh ke build/env_art/kendaraan/
    python3 tools/env_art/kendaraan.py --salin  # juga menyalin sheet kucing misi (hanya mission_kucing_sheet) ke assets/sprites/npc/

`--salin` (run fase4b-misi-kucing, M-10) menyalin PNG 1x dan JSON titik pijak kucing misi Bu Ratmi saja (belang tiga berkalung); mobil, motor, dan kucing
dekorasi tetap hanya di build/ sampai dipakai. Hasil deterministik di mesin yang sama; render di mesin ini bisa beda sedikit dari mock PR #35
(`docs/design/environment/kendaraan_perumahan.png`, selisih beberapa ratus piksel, drift numpy/pillow), sheet kucing tidak diperiksa terhadap mock itu.
"""
import json
import math
import sys

import numpy as np
from PIL import Image

from engine import *          # noqa: F401,F403
from lib import *             # noqa: F401,F403
from lib import _body_tex, _wheels, _conv
import perumahan as PR
import fase3 as F3

OUT_DIR = PR.OUT / 'kendaraan'
OUT_DIR.mkdir(parents=True, exist_ok=True)

HEAD = {'lawan': 0, 'masuk': 90, 'searah': 180, 'keluar': 270}


def rz(deg):
    a = math.radians(deg)
    c, s_ = round(math.cos(a), 12), round(math.sin(a), 12)
    return np.array([[c, -s_, 0], [s_, c, 0], [0, 0, 1.0]])      # dunia = A @ lokal


def ry(deg):
    a = math.radians(deg)
    c, s_ = math.cos(a), math.sin(a)
    return np.array([[c, 0, s_], [0, 1, 0], [-s_, 0, c]])         # puncak miring ke +x lokal


def geser(prims, v):
    """Geser primitif lokal sebesar v (3,)."""
    v = np.asarray(v, float)
    for p in prims:
        p.planes = [(n, d + float(mm(n, v))) for n, d in p.planes]
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


def xform_into(s, tmp, A, t, k=1.0):
    """Pindahkan primitif tmp ke scene s: dunia = k * A @ lokal + t (A ortonormal, k skala seragam).
    Silinder harus tetap sejajar sumbu."""
    t = np.asarray(t, float)
    for p in tmp.prims:
        p.planes = [(mm(A, n), k * d + float(mm(mm(A, n), t))) for n, d in p.planes]
        if p.quad is not None:
            if p.quad[0] == 'ellip':
                _, c, R, r = p.quad
                p.quad = ('ellip', k * mm(A, c) + t, mm(R, A.T), np.asarray(r, float) * k)
            else:
                _, ax, c2, r = p.quad
                e = np.zeros(3); e[ax] = 1
                c3 = np.zeros(3); o = [i for i in range(3) if i != ax]; c3[o] = c2
                ne = mm(A, e)
                nax = int(np.argmax(np.abs(ne)))
                assert abs(abs(ne[nax]) - 1) < 1e-6, 'silinder harus sejajar sumbu'
                w = k * mm(A, c3) + t
                no = [i for i in range(3) if i != nax]
                p.quad = ('cyl', nax, w[no], r * k)
        cs = np.array([[x, y, z] for x in (p.lo[0], p.hi[0]) for y in (p.lo[1], p.hi[1]) for z in (p.lo[2], p.hi[2])])
        w = k * mm(cs, A.T) + t
        p.lo, p.hi = w.min(0), w.max(0)
        if p.tex is not None:
            f = p.tex
            p.tex = (lambda Pw, Nw, f=f: f(mm(Pw - t, A) / k, mm(Nw, A)))
        s.prims.append(p)


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


def _ellip_along(s, a, b, rr, mat, part, tex=None):
    """Elipsoid memanjang dari a ke b, jari-jari lintang rr (lateral, tinggi)."""
    a, b = np.asarray(a, float), np.asarray(b, float)
    w = b - a
    L = panjang(w)
    w = w / L
    u = np.cross([0, 0, 1.0], w)
    if panjang(u) < 1e-6:
        u = np.array([1.0, 0, 0])
    u = u / panjang(u)
    v = np.cross(w, u)
    s.add(ellip((a + b) / 2, (rr[0], rr[1], L / 2), mat, tex, R=np.stack([u, v, w]), part=part))


# ======================================================================= mobil ====
LAMP_F_NYALA = Mat('#FFFFFF', '#FFFFFF', '#FFF6D8')
LAMP_R_JALAN = Mat('#FF8A6A', '#E8583E', '#A8322A')
LAMP_REM = F3.LAMP_REM_NYALA
SEIN_MATI = Mat('#F2C48A', '#DDA062', '#A86E3A')
SEIN_NYALA = Mat('#FFF0B0', '#FFC94A', '#E98E3F')
JOK = Mat('#4A4450', '#3A3440', '#26222C')

WARNA_MOBIL = {
    'putih': Mat('#FFFFFF', '#E4E6EC', '#A4A8B4'),
    'perak': Mat('#D6D8DE', '#AEB2BC', '#767A88'),
    'hitam': Mat('#6A6676', '#46424F', '#2A2632'),
    'merah': Mat('#F08A6A', '#D9573D', '#8E2E25'),
    'biru': Mat('#8FC0EA', '#5F96C8', '#3E6A96'),
    'hijau': Mat('#A8D0B4', '#6E9E84', '#45685A'),
    'krem': Mat('#FBE6BE', '#E8C893', '#B08E64'),
    'biru_angkot': Mat('#B6E4F2', '#7CC6E2', '#4A8EAE'),
}

# dimensi lokal: L panjang, W lebar, zt tinggi bodi bawah, h tinggi kabin, kap/bagasi = turunan ujung,
# uf/ur = kaca depan/belakang (bawah, atas) sebagai pecahan setengah panjang, pilar = posisi tiang samping
MODEL_MOBIL = {
    'sedan': dict(L=50, W=22, zt=12.0, h=9.0, kap=3.5, bagasi=2.5, uf=(0.22, -0.02), ur=(-0.60, -0.44),
                  pilar=(-0.18,), sudut=3.0, warna='perak'),
    'hatchback': dict(L=40, W=21, zt=11.5, h=9.0, kap=3.0, bagasi=0.8, uf=(0.34, 0.08), ur=(-0.97, -0.82),
                      pilar=(-0.30,), sudut=2.6, warna='merah'),
    'mpv': dict(L=52, W=23, zt=12.5, h=11.0, kap=3.2, bagasi=0.6, uf=(0.46, 0.20), ur=(-0.98, -0.93),
                pilar=(-0.02, -0.52), sudut=2.8, warna='putih'),
    'pikap': dict(L=50, W=22, zt=11.0, h=10.0, kap=2.2, bagasi=0.4, uf=(0.92, 0.74), ur=(0.34, 0.34),
                  pilar=(), sudut=2.4, warna='hitam', bak=True),
    'angkot': dict(warna='biru_angkot', angkot=True),
}
MOBIL_URUT = ['sedan', 'hatchback', 'mpv', 'pikap', 'angkot']
# skala mobil: sedan 50 -> 65 unit, sekitar 2x1 ubin (ART_DIRECTION tabel ukuran), sebanding dengan loper dan motor
SKALA_MOBIL = 1.3


def _lampu_tex(base, hw, state, sr=-1):
    """Bungkus tekstur bodi: lampu sein di sudut luar lampu depan/belakang sisi kanan (sr = tanda x sisi kanan)."""
    def tex(Pw, Nw):
        mi, sh = base(Pw, Nw)
        mi = np.array(np.broadcast_to(mi, (len(Pw),)))
        sh = np.array(np.broadcast_to(sh, (len(Pw),)))
        lat = Pw[:, 0]
        corner = (mi == 1) | (mi == 2)
        outer = np.abs(lat) > hw - 2.4
        mi = np.where(corner & outer, 10, mi)
        if state == 'sein':
            on = corner & outer & (np.sign(lat) == sr)
            mi = np.where(on, 11, mi)
            sh = np.where(on, 0, sh)
        if state in ('rem', 'jalan'):
            sh = np.where(mi == 2, 0, sh)
        return mi, sh
    return tex


def _mats_lampu(mats, state):
    """mats: daftar material bodi asli (indeks 1 lampu depan, 2 lampu belakang). Sein di indeks 10 dan 11."""
    m = list(mats) + [TRIM] * max(0, 10 - len(mats))
    m[1] = LAMP_F_NYALA if state in ('jalan', 'rem') else LAMP_F
    m[2] = {'rem': LAMP_REM, 'jalan': LAMP_R_JALAN}.get(state, LAMP_R)
    return m[:10] + [SEIN_MATI, SEIN_NYALA]


def _mobil_lokal(s, kind, body, state='mati', dz=0.0):
    """Model di koordinat lokal: moncong ke +y, pusat (0, 0). Mengembalikan indeks primitif roda."""
    M = MODEL_MOBIL[kind]
    if M.get('angkot'):
        angkot(s, 0.0, 0.0, body=body, front=1)
        bp = s.prims[0]
        hw = 11.0
        bp.tex = _lampu_tex(bp.tex, hw, state)
        bp.mats = _mats_lampu(bp.mats, state)
        if dz:
            geser([bp], (0, 0, dz))
        return
    f = 1
    L, Wd = M['L'], M['W']
    hl, hw = L / 2, Wd / 2
    zb, zt = 3.0, M['zt']
    Y = np.array([0, 1.0, 0])
    planes = [((1, 0, 0), hw), ((-1, 0, 0), hw), ((0, 0, 1), zt), ((0, 0, -1), -zb),
              (Y, hl), (-Y, hl),
              (np.array([0, 1, 1.0]), hl + zt - M['kap']),
              (np.array([0, -1, 1.0]), hl + zt - M['bagasi']),
              ((1, 0, 1), hw + zt - 1.5), ((-1, 0, 1), hw + zt - 1.5)]
    for sx in (-1, 1):
        for sy in (-1, 1):
            planes.append((np.array([sx, sy, 0.0]), hw + hl - M['sudut']))
    wys = (hl * 0.6, -hl * 0.62)
    doors = tuple(p * hl for p in M['pilar']) + ((hl * 0.05,) if not M.get('bak') else (hl * 0.55,))
    base = _body_tex(0.0, 0.0, f, hw, hl, wys, door_us=doors)
    start = len(s.prims)
    s.add(Prim(planes, None, _mats_lampu([body, LAMP_F, LAMP_R, TRIM, RIM, body], state), _lampu_tex(base, hw, state),
               aabb=((-hw, -hl, zb), (hw, hl, zt))))
    pid = s.prims[-1].part
    # kabin
    z0, z1 = zt, zt + M['h']
    uf0, uf1 = M['uf'][0] * hl, M['uf'][1] * hl
    ur0, ur1 = M['ur'][0] * hl, M['ur'][1] * hl
    kf = (uf0 - uf1) / (z1 - z0)
    kr = (ur1 - ur0) / (z1 - z0)
    ks = 2.2 / (z1 - z0)
    cp = [((0, 0, 1), z1), ((0, 0, -1), -z0),
          (np.array([0, 1, kf]), uf0 + kf * z0),
          (np.array([0, -1, kr]), -ur0 + kr * z0),
          (np.array([1, 0, ks]), hw - 1.2 + ks * z0), (np.array([-1, 0, ks]), hw - 1.2 + ks * z0)]
    pil = [p * hl for p in M['pilar']]

    def ctex(Pw, Nw):
        pz = Pw[:, 2]
        u = Pw[:, 1]
        roof = Nw[:, 2] > 0.85
        g = (~roof) & (pz > z0 + 1.2) & (pz < z1 - 0.8)
        side = np.abs(Nw[:, 0]) > 0.6
        for bu in pil:
            g &= ~(side & (np.abs(u - bu) < 1.3))
        if M.get('bak'):      # dinding belakang kabin pikap: kaca kecil saja
            back = Nw[:, 1] < -0.6
            g &= ~(back & ((np.abs(Pw[:, 0]) > hw - 4.5) | (pz < z0 + 3.5)))
        return np.where(g, 0, 1), 0
    s.add(Prim(cp, None, [GLASS_CAR, body], ctex, aabb=((-hw, -hl, z0), (hw, hl, z1)), part=pid))
    if M.get('bak'):
        bz = zt + 4.5
        b0, b1 = -hl + 0.6, ur0 - 0.5
        bm = [body]
        s.add(box(hw - 1.0, hw, b0, b1, zt, bz, bm, part=pid))
        s.add(box(-hw, -hw + 1.0, b0, b1, zt, bz, bm, part=pid))
        s.add(box(-hw, hw, b0 - 0.6, b0 + 0.4, zt, bz, bm, part=pid))
        s.add(box(-hw, hw, b1 - 1.0, b1, zt, bz + 1.0, [P['metal_dk']], part=pid))
        # muatan: dua karung dan satu tandan pisang
        karung = Mat('#F6EEDB', '#E2D4B4', '#B5A27C')
        s.add(ellip((-3.5, b0 + 8, zt + 3.0), (4.0, 5.0, 3.0), karung, None, R=rot_z(0.2)))
        s.add(ellip((3.8, b0 + 10, zt + 2.8), (3.6, 5.2, 2.8), karung, None, R=rot_z(-0.3)))
        s.add(ellip((0.5, b1 - 4.5, zt + 3.2), (3.2, 3.0, 2.6), Mat('#D8E46A', '#A8BC48', '#6E8A34')))
    nb = len(s.prims)
    if dz:
        geser(s.prims[start:nb], (0, 0, dz))
    _wheels(s, 0.0, hw - 0.2, wys)


def mobil(s, kind, x, y, arah='searah', state='mati', body=None, dz=0.0):
    tmp = F3._Tmp()
    body = body or WARNA_MOBIL[MODEL_MOBIL[kind]['warna']]
    _mobil_lokal(tmp, kind, body, state, dz)
    xform_into(s, tmp, rz(HEAD[arah]), (x, y, 0), SKALA_MOBIL)


FRAME_MOBIL = [('searah', 'mati', 0, 'searah_parkir'), ('searah', 'sein', 0, 'searah_sein'),
               ('searah', 'jalan', 0, 'searah_jalan_1'), ('searah', 'jalan', 1, 'searah_jalan_2'),
               ('searah', 'rem', 0, 'searah_rem'),
               ('lawan', 'mati', 0, 'lawan_parkir'), ('lawan', 'jalan', 0, 'lawan_jalan_1'),
               ('lawan', 'jalan', 1, 'lawan_jalan_2'),
               ('masuk', 'mati', 0, 'masuk_parkir'), ('keluar', 'mati', 0, 'keluar_parkir')]


# ======================================================================= motor ====
BAN = Mat('#4A4650', '#2E2A34', '#1C1822')
VELG = Mat('#D4D2D8', '#A4A2AC', '#6E6C78')
MESIN = Mat('#8A8692', '#5F5B66', '#3D3A46')
HITAM = Mat('#4A4450', '#3A3440', '#26222C')
KULIT = P['skin']
CELANA = Mat('#6A7290', '#4E5672', '#343A52')
SEPATU = Mat('#5A5662', '#3E3A46', '#26222C')
KACA_HELM = Mat('#5E7A96', '#3A5672', '#26384E')
KERANJANG = Mat('#E2C27A', '#C49A50', '#8A6A34')
SAYUR = Mat('#9CD46A', '#5FA24A', '#36703A')
TOMAT = Mat('#FF8A6A', '#E0503A', '#9A2E22')
KANTONG = Mat('#FBF6E8', '#E4DCCC', '#B4AC9C')

WARNA_MOTOR = {
    'merah': Mat('#F08A6A', '#D9573D', '#8E2E25'),
    'biru': Mat('#8FC0EA', '#5F96C8', '#3E6A96'),
    'putih': Mat('#FFFFFF', '#E4E6EC', '#A4A8B4'),
    'hitam': Mat('#6A6676', '#46424F', '#2A2632'),
    'hijau': Mat('#A8D0B4', '#6E9E84', '#45685A'),
    'pink': Mat('#F7D9DC', '#E8B4BC', '#B07C88'),
}
JAKET = {'biru': Mat('#7FB2E0', '#5F96C8', '#3E6A96'), 'hijau': Mat('#A8D0B4', '#6E9E84', '#45685A'),
         'merah': Mat('#F06A4E', '#D94F3D', '#8E2E25'), 'krem': Mat('#FBE6BE', '#E8C893', '#B08E64'),
         'abu': Mat('#C4C0C8', '#969AA0', '#67636D'), 'batik': Mat('#D9895E', '#B0603A', '#7A3E26')}
HELM = {'putih': Mat('#FFFFFF', '#E4E6EC', '#A4A8B4'), 'hitam': Mat('#6A6676', '#46424F', '#2A2632'),
        'merah': Mat('#F08A6A', '#D9573D', '#8E2E25'), 'biru': Mat('#8FC0EA', '#5F96C8', '#3E6A96')}

# geometri lokal motor: moncong +y. roda (y, r), jok (y, z), kaki (y, z), setang (y, z, lebar), condong badan
MODEL_MOTOR = {
    'matic': dict(roda=(7.2, -7.2), r=3.0, jok=(-3.6, 10.0), pijak=(2.6, 4.8), setang=(5.8, 13.0, 3.6),
                  condong=1.2, warna='putih', jaket='biru', helm='hitam'),
    'bebek': dict(roda=(7.6, -7.4), r=3.3, jok=(-3.4, 10.4), pijak=(-0.4, 3.6), setang=(5.6, 13.2, 3.4),
                  condong=1.6, warna='biru', jaket='merah', helm='putih'),
    'sport': dict(roda=(8.2, -8.0), r=3.4, jok=(-2.6, 11.0), pijak=(-2.6, 5.4), setang=(4.6, 12.4, 3.2),
                  condong=5.0, warna='merah', jaket='hitam', helm='merah'),
    'sayur': dict(roda=(7.6, -7.4), r=3.3, jok=(-1.8, 10.4), pijak=(-0.4, 3.6), setang=(5.6, 13.2, 3.4),
                  condong=1.6, warna='hitam', jaket='krem', helm='biru'),
}
MOTOR_URUT = ['matic', 'bebek', 'sport', 'sayur']
# skala motor + pengendara terhadap model lokal: helm pengendara setinggi kepala loper di sprite pemain
# (loper 40 px di atas titik pijak; pengendara model lokal 23 px), jadi x1,7
SKALA_MOTOR = 1.7
JAKET['hitam'] = Mat('#6A6676', '#46424F', '#2A2632')


def _roda(s, y, r, tebal=1.1):
    s.add(ellip((0, y, r), (tebal, r, r), BAN, None))
    pid = s.prims[-1].part
    s.add(ellip((0, y, r), (tebal + 0.15, r * 0.5, r * 0.5), VELG, None, part=pid))


def _badan_motor(s, kind, body, parkir):
    M = MODEL_MOTOR[kind]
    yf, yr = M['roda']
    r = M['r']
    sy, sz = M['jok']
    hy, hz, hw = M['setang']
    _roda(s, yf, r)
    _roda(s, yr, r, 1.5 if kind == 'sport' else 1.1)
    if kind == 'matic':
        s.add(ellip((0, -5.2, 7.2), (2.6, 6.2, 2.6), body, None))                          # bodi belakang
        pid = s.prims[-1].part
        th = math.radians(16)
        s.add(obox((0, 5.4, 8.2), (1, 0, 0), (0, math.cos(th), math.sin(th)), (0, -math.sin(th), math.cos(th)),
                   2.5, 0.9, 4.3, body, part=pid))                                         # tameng depan
        s.add(box(-2.0, 2.0, -2.4, 4.6, 3.6, 4.6, HITAM, part=pid))                       # dek kaki
        s.add(ellip((1.5, -6.6, 4.2), (1.1, 4.4, 1.5), MESIN, None, part=pid))             # CVT kiri
        s.add(ellip((0, yf + 0.2, r + 2.4), (1.5, 3.2, 1.1), body, None, part=pid))        # spakbor depan
    elif kind in ('bebek', 'sayur'):
        s.add(ellip((0, -5.6, 8.0), (2.1, 5.6, 2.0), body, None))
        pid = s.prims[-1].part
        _limb(s, (0, 5.4, 9.0), (0, -0.6, 6.0), 1.1, body, pid)                          # tulang bawah
        th = math.radians(18)
        s.add(obox((0, 5.0, 7.8), (1, 0, 0), (0, math.cos(th), math.sin(th)), (0, -math.sin(th), math.cos(th)),
                   2.1, 0.7, 2.7, body, part=pid))                                         # tameng kecil
        s.add(box(-1.6, 1.6, -3.2, 2.0, 2.4, 6.2, MESIN, part=pid))                       # mesin
        s.add(ellip((0, yf + 0.2, r + 2.2), (1.3, 3.2, 0.9), body, None, part=pid))
        s.add(ellip((0, hy + 0.4, hz - 0.6), (2.4, 1.6, 1.3), body, None, part=pid))       # batok lampu
    else:  # sport
        s.add(ellip((0, 1.6, 10.2), (2.7, 3.8, 1.9), body, None))                           # tangki
        pid = s.prims[-1].part
        s.add(ellip((0, 5.8, 9.6), (2.3, 2.6, 2.6), body, None, part=pid))                 # fairing
        s.add(ellip((0, 6.6, 12.0), (1.6, 1.0, 1.4), GLASS_CAR, None, part=pid))           # kaca kecil
        s.add(box(-1.9, 1.9, -3.4, 3.2, 2.4, 7.6, MESIN, part=pid))
        s.add(ellip((0, -7.0, 11.0), (1.5, 4.4, 1.0), body, None, part=pid))               # buntut tinggi
        s.add(ellip((0, yf + 0.2, r + 2.3), (1.4, 2.8, 0.8), body, None, part=pid))
        _limb(s, (-1.8, -3.0, 4.2), (-1.8, -9.6, 7.6), 0.8, MESIN, pid)                   # knalpot naik
    # jok
    jl = 3.4 if kind == 'sport' else 5.2
    s.add(ellip((0, sy, sz), (2.1, jl, 0.95), HITAM, None, part=pid))
    # setang, garpu, lampu
    _limb(s, (0, yf - 0.6, r), (0, hy + 0.6, hz - 1.0), 0.5, MESIN, pid)
    s.add(obox((0, hy, hz), (1, 0, 0), (0, 1, 0), (0, 0, 1), hw - 1.0, 0.6, 0.5,
               HITAM if kind == 'sport' else body, part=pid))
    for sg in (-1, 1):
        _limb(s, (sg * (hw - 1.0), hy, hz), (sg * hw, hy - 0.4, hz + 0.2), 0.55, HITAM, pid)
    lz = hz - 0.8 if kind != 'sport' else 9.8
    ly = hy + 1.4 if kind != 'sport' else 8.2
    s.add(ellip((0, ly, lz), (1.2, 0.6, 0.7), LAMP_F, None, part=pid))
    s.add(ellip((0, yr - r * 0.9, sz - 1.6 if kind != 'sport' else 10.8), (1.0, 0.5, 0.55), LAMP_R, None, part=pid))
    if kind != 'sport':
        _limb(s, (-1.7, -3.0, 3.6), (-1.7, -10.4, 4.6), 0.7, MESIN, pid)                  # knalpot kanan
    if kind == 'sayur':
        # rak di atas roda belakang, keranjang bambu di kedua sisi berisi sayur
        s.add(box(-2.2, 2.2, -11.6, -5.6, sz - 0.6, sz + 0.2, MESIN, part=pid))
        for sg in (-1, 1):
            def anyam(Pw, Nw):
                return 0, np.where((np.mod(np.floor(Pw[:, 1]) + np.floor(Pw[:, 2]), 2) == 0), 1, 0)
            s.add(box(sg * 2.4 if sg > 0 else -7.4, 7.4 if sg > 0 else -2.4, -12.2, -4.6, 4.8, 10.2,
                      KERANJANG, anyam))
            kp = s.prims[-1].part
            cx = sg * 4.9
            s.add(ellip((cx, -9.8, 10.6), (2.2, 2.4, 1.4), SAYUR, None, part=kp))
            s.add(ellip((cx - 0.6, -6.8, 10.4), (1.6, 2.0, 1.3), SAYUR, None, part=kp))
            s.add(ellip((cx + sg * 1.0, -7.6, 10.9), (0.9, 0.9, 0.9), TOMAT, None, part=kp))
        # kantong plastik di setang
        s.add(ellip((-hw + 0.4, hy - 0.4, hz - 2.4), (1.0, 1.0, 1.6), KANTONG, None))
    if parkir:   # standar samping kiri (+x lokal)
        _limb(s, (1.4, -1.6, 4.0), (3.3, -2.6, 0.3), 0.35, MESIN, pid)
    return pid


def _pengendara(s, kind, jaket, helm):
    M = MODEL_MOTOR[kind]
    sy, sz = M['jok']
    hy, hz, hw = M['setang']
    py, pz = M['pijak']
    c = M['condong']
    hip = np.array([0, sy + 0.8, sz + 1.0])
    sh = hip + np.array([0, c, 6.2 - 0.25 * c])
    _ellip_along(s, hip + np.array([0, 0, -0.4]), sh + np.array([0, 0.2, 0.6]), (2.5, 1.7), jaket, None)
    pid = s.prims[-1].part
    head = sh + np.array([0, 0.6 + 0.15 * c, 2.6])
    s.add(ellip(head, (2.0, 2.1, 2.0), helm, None, part=pid))
    s.add(ellip(head + np.array([0, 1.4, -0.3]), (1.5, 0.9, 0.9), KACA_HELM, None, part=pid))
    for sg in (-1, 1):
        a = sh + np.array([sg * 1.9, 0, -0.5])
        g = np.array([sg * (hw - 0.4), hy - 0.4, hz + 0.2])
        el = (a + g) / 2 + np.array([sg * 0.6, -0.6, -0.8])
        _limb(s, a, el, 0.75, jaket, pid)
        _limb(s, el, g, 0.7, jaket, pid)
        s.add(ellip(g, (0.75, 0.75, 0.75), KULIT, None, part=pid))
        h = hip + np.array([sg * 1.3, 0.4, 0])
        kn = np.array([sg * 2.2, sy + 5.0 + (2.0 if kind == 'sport' else 0), sz + (0.4 if kind == 'matic' else 1.2)])
        ft = np.array([sg * 1.9, py, pz + 0.5])
        _limb(s, h, kn, 0.95, CELANA, pid)
        _limb(s, kn, ft, 0.8, CELANA, pid)
        s.add(ellip(ft + np.array([0, 0.8, 0]), (0.8, 1.4, 0.6), SEPATU, None, part=pid))


def motor_v(s, kind, x, y, arah='searah', jalan=False, dz=0.0, body=None, jaket=None, helm=None):
    M = MODEL_MOTOR[kind]
    body = body or WARNA_MOTOR[M['warna']]
    tmp = F3._Tmp()
    _badan_motor(tmp, kind, body, parkir=not jalan)
    if jalan:
        nr = 4      # dua roda x (ban + velg)
        n0 = len(tmp.prims)
        _pengendara(tmp, kind, jaket or JAKET[M['jaket']], helm or HELM[M['helm']])
        if dz:
            geser(tmp.prims[nr:], (0, 0, dz))
        A = rz(HEAD[arah])
    else:
        A = mm(rz(HEAD[arah]), ry(9.0))
        geser(tmp.prims, (0, 0, -0.25))
    xform_into(s, tmp, A, (x, y, 0), SKALA_MOTOR)


FRAME_MOTOR = [('searah', False, 0, 'searah_parkir'), ('lawan', False, 0, 'lawan_parkir'),
               ('masuk', False, 0, 'masuk_parkir'), ('keluar', False, 0, 'keluar_parkir'),
               ('searah', True, 0, 'searah_jalan_1'), ('searah', True, 0.6, 'searah_jalan_2'),
               ('lawan', True, 0, 'lawan_jalan_1'), ('lawan', True, 0.6, 'lawan_jalan_2')]


# ====================================================================== kucing ====
HIDUNG_K = Mat('#3D3446', '#2C2534', '#1C1724')
KALUNG_K = Mat('#F06A4E', '#D94F3D', '#8E2E25')
LONCENG = Mat('#FFE08A', '#FFC94A', '#C98E2A')
PUTIH_K = Mat('#FFFFFF', '#F2E7C9', '#C2AF86')
# warna: (dasar, corak, pola). pola: loreng | tuksedo | polos | belang_tiga
WARNA_KUCING = {
    'oren': (Mat('#FBC27A', '#E8944A', '#A85E2C'), Mat('#E08A3C', '#B8622A', '#7E4220'), 'loreng'),
    'abu': (Mat('#D2CED6', '#A8A4B0', '#74707E'), Mat('#8A8694', '#64606E', '#46424F'), 'loreng'),
    'tuksedo': (Mat('#5A5462', '#3E3846', '#26222C'), PUTIH_K, 'tuksedo'),
    'putih': (PUTIH_K, PUTIH_K, 'polos'),
    'belang_tiga': (PUTIH_K, Mat('#FBC27A', '#E8944A', '#A85E2C'), 'belang_tiga'),   # kucing misi Bu Ratmi
}
HITAM_K = Mat('#5A5462', '#3E3846', '#26222C')
KUCING_POSE = ['duduk', 'tidur', 'jalan_1', 'jalan_2', 'lari_1', 'lari_2', 'kaget']
# Fase 5C (usulan): kucing misi yang sudah ditangkap, duduk tenang seperti sedang dielus. Hanya sheet kucing misi.
KUCING_POSE_MISI = KUCING_POSE + ['ditangkap_1', 'ditangkap_2']
KUCING_ARAH = ['searah', 'masuk', 'lawan', 'keluar']
KUCING_URUT = ['oren', 'abu', 'tuksedo', 'putih', 'belang_tiga']


def _pola_kucing(warna, perut_z):
    dasar, corak, pola = WARNA_KUCING[warna]
    mats = [dasar, corak, PUTIH_K, HITAM_K]

    def tex(Pw, Nw):
        x, y, z = Pw[:, 0], Pw[:, 1], Pw[:, 2]
        mi = np.zeros(len(x), int)
        if pola == 'loreng':
            g = np.mod(y * 0.85 + z * 0.35, 2.4) < 0.85
            mi = np.where(g & (z > perut_z) & (Nw[:, 2] > -0.3), 1, mi)
        elif pola == 'tuksedo':
            mi = np.where((z < perut_z) & (Nw[:, 2] < 0.2), 2, mi)
        elif pola == 'belang_tiga':
            n1 = vnoise(x * 1.0 + 3, y * 1.0 + z * 0.6, 3.2, seed=7)
            n2 = vnoise(x * 1.0 - 5, y * 1.0 - z * 0.6, 3.0, seed=11)
            mi = np.where(n1 > 0.58, 1, mi)
            mi = np.where(n2 > 0.62, 3, mi)
            mi = np.where(z < perut_z, 0, mi)
        return mi, 0
    return mats, tex


def _kucing_lokal(s, pose, warna, kalung):
    """Kucing kampung di koordinat lokal, moncong ke +y. Dibangun dari elipsoid dan batang seperti ayam dan anjing."""
    f = np.array([0, 1.0, 0]); r = np.array([-1.0, 0, 0]); up = np.array([0, 0, 1.0])
    pola = WARNA_KUCING[warna][2]
    bulu, tex = _pola_kucing(warna, 3.2 if pose != 'tidur' else 1.2)
    kaki_m = bulu
    kaki_tex = tex

    def E(c, rad, R=None, part=None, t=tex):
        s.add(ellip(c, rad, bulu, t, R=R, part=part))
        return s.prims[-1].part

    def L(a, b, rr, part, t=None):
        _ellip_along(s, a, b, (rr, rr), bulu, part, tex if t is None else t)

    def Rp(pitch):
        fp = f * math.cos(pitch) + up * math.sin(pitch)
        return np.stack([fp, r, np.cross(fp, r) * -1])

    O = np.zeros(3)
    ekor_tebal = 0.55
    telinga = (1.0, 0.0, 1.0, (0.55, 0.7, 1.1))      # (samping, maju, naik, jari-jari)
    moncong_turun = 0.5
    mata_tutup = False
    if pose.startswith('ditangkap'):
        # duduk lebih rendah dan membulat, kepala menunduk ke depan, mata terpejam, telinga rileks ke samping,
        # ekor melingkar rapat di depan kaki. Frame 2: ujung ekor bergeser (bergoyang pelan).
        pid = E(O + up * 3.2 + f * 0.1, (2.1, 1.9, 3.0), R=np.stack([r, np.cross(up, r) * -1, up]))
        E(O - f * 1.0 + up * 1.8, (2.7, 2.3, 1.8), part=pid)                                  # pinggul
        head = O + f * 1.5 + up * 6.9
        for sg in (-1, 1):
            L(O + f * 1.4 + r * sg * 0.9 + up * 3.2, O + f * 1.9 + r * sg * 0.9 + up * 0.3, 0.55, pid)
        if pose == 'ditangkap_1':
            tail = [O - f * 2.7 + up * 0.5, O - f * 1.2 + r * 2.6 + up * 0.4, O + f * 2.0 + r * 1.6 + up * 0.4]
        else:          # ujung ekor bergeser dan pangkal ekor sedikit terangkat, supaya terlihat dari belakang juga
            tail = [O - f * 2.8 + up * 0.8, O - f * 1.6 + r * 3.0 + up * 1.4, O + f * 2.3 + r * 0.6 + up * 0.5]
        telinga = (1.15, -0.3, 0.75, (0.55, 0.7, 0.95))
        moncong_turun = 1.0
        mata, mata_tutup = True, True
    elif pose == 'duduk':
        pid = E(O + up * 3.6 + f * 0.2, (2.0, 1.8, 3.4), R=np.stack([r, np.cross(up, r) * -1, up]))
        E(O - f * 1.0 + up * 1.9, (2.6, 2.2, 1.9), part=pid)                                  # pinggul
        head = O + f * 1.0 + up * 7.4
        for sg in (-1, 1):
            L(O + f * 1.4 + r * sg * 0.9 + up * 3.6, O + f * 1.9 + r * sg * 0.9 + up * 0.3, 0.55, pid)
        tail = [O - f * 2.8 + up * 0.5, O - f * 1.6 + r * 2.6 + up * 0.4, O + f * 1.6 + r * 2.4 + up * 0.4]
        mata = True
    elif pose == 'tidur':
        pid = E(O + up * 1.8, (3.4, 3.0, 1.9))
        head = O + f * 2.2 - r * 1.6 + up * 2.2
        tail = [O - f * 2.6 + r * 1.8 + up * 0.7, O + f * 0.6 + r * 3.0 + up * 0.7, O + f * 3.0 + r * 0.6 + up * 0.8]
        mata = False
    elif pose == 'kaget':
        pid = E(O + up * 6.0, (3.6, 1.8, 2.0))
        E(O + up * 7.4, (2.2, 1.9, 1.6), part=pid)                                            # punggung melengkung
        head = O + f * 3.8 + up * 5.6
        _ellip_along(s, O + f * 2.4 + up * 6.0, head, (1.3, 1.3), bulu, pid, tex)
        legs = [(f * 2.4, 1), (f * 2.4, -1), (-f * 2.4, 1), (-f * 2.4, -1)]
        for d, sg in legs:
            L(O + d + r * sg * 0.65 + up * 5.4, O + d * 1.05 + r * sg * 0.65, 0.5, pid)
        tail = [O - f * 3.2 + up * 6.8, O - f * 3.6 + up * 10.0, O - f * 3.0 + up * 12.6]
        ekor_tebal = 0.9
        mata = True
    else:
        run = pose.startswith('lari')
        stretch = {'jalan_1': 3.6, 'jalan_2': 3.6, 'lari_1': 4.4, 'lari_2': 3.2}[pose]
        bz = {'jalan_1': 4.6, 'jalan_2': 4.8, 'lari_1': 4.4, 'lari_2': 4.9}[pose]
        pid = E(O + up * bz, (stretch, 1.8, 1.9 if pose != 'lari_2' else 2.2))
        chest = O + f * (stretch - 1.0) + up * (bz + 0.2)
        hipc = O - f * (stretch - 1.2) + up * bz
        head = chest + f * 1.6 + up * (2.2 if not run else 1.2)
        _ellip_along(s, chest - f * 0.4, head - up * 0.6, (1.3, 1.3), bulu, pid, tex)          # leher
        if pose == 'jalan_1':
            fr = [(chest, f * 1.4, 1), (chest, -f * 0.2, -1)]; bk = [(hipc, -f * 0.6, 1), (hipc, f * 0.8, -1)]
        elif pose == 'jalan_2':
            fr = [(chest, -f * 0.2, 1), (chest, f * 1.4, -1)]; bk = [(hipc, f * 0.8, 1), (hipc, -f * 0.6, -1)]
        elif pose == 'lari_1':
            fr = [(chest, f * (2.6 + 0.8 * (sg > 0)) + up * 1.0, sg) for sg in (-1, 1)]; bk = [(hipc, -f * (2.8 + 0.8 * (sg > 0)) + up * 1.0, sg) for sg in (-1, 1)]
        else:
            fr = [(chest, -f * (0.8 + 0.6 * (sg > 0)) + up * 0.3, sg) for sg in (-1, 1)]; bk = [(hipc, f * (1.0 + 0.6 * (sg > 0)) + up * 0.3, sg) for sg in (-1, 1)]
        for top, off, sg in fr + bk:
            base_pt = np.array([top[0], top[1], 0.0]) + off
            L(top + r * sg * 0.65 - up * 1.0, base_pt + r * sg * 0.65, 0.5, pid)
        if run:
            tail = [hipc - f * 1.6 + up * 0.6, hipc - f * 4.6 + up * 1.4, hipc - f * 7.0 + up * 2.0]
        else:
            tail = [hipc - f * 1.6 + up * 0.8, hipc - f * 3.0 + up * 3.4, hipc - f * 2.4 + up * 6.0]
        mata = True
    # kepala, telinga, mata, hidung
    E(head, (1.9, 1.8, 1.6), part=pid)
    E(head + f * 1.2 - up * moncong_turun, (1.0, 1.1, 0.7), part=pid)                        # moncong
    for sg in (-1, 1):
        a = head + r * sg * telinga[0] + f * telinga[1] + up * telinga[2]
        s.add(ellip(a + up * 0.8, telinga[3], bulu, None, part=pid))                         # telinga
    if mata:
        for sg in (-1, 1):
            if mata_tutup:     # garis mata terpejam: pipih dan sedikit lebih rendah
                s.add(ellip(head + f * 1.5 + r * sg * 0.75 + up * 0.15, (0.45, 0.35, 0.18), HIDUNG_K, None, part=pid))
            else:
                s.add(ellip(head + f * 1.5 + r * sg * 0.75 + up * 0.35, (0.35, 0.35, 0.45), HIDUNG_K, None, part=pid))
    if kalung and mata_tutup:
        # kepala menunduk menutupi leher: kalung sedikit lebih besar dan maju supaya merah dan lonceng tetap terlihat
        nk = head - f * 0.3 - up * 1.4
        s.add(ellip(nk, (1.5, 1.7, 0.55), KALUNG_K, None, part=pid))
        s.add(ellip(nk + f * 1.45 - up * 0.45, (0.55, 0.55, 0.55), LONCENG, None, part=pid))
    elif kalung:
        nk = head - f * 0.8 - up * 1.2
        s.add(ellip(nk, (1.2, 1.5, 0.5), KALUNG_K, None, part=pid))
        s.add(ellip(nk + f * 1.2 - up * 0.4, (0.5, 0.5, 0.5), LONCENG, None, part=pid))
    for a, b in zip(tail[:-1], tail[1:]):
        _ellip_along(s, a, b, (ekor_tebal, ekor_tebal), bulu, pid, tex)
    return pid


def kucing(s, x, y, pose='duduk', warna='oren', arah='searah', kalung=None):
    kalung = (warna == 'belang_tiga') if kalung is None else kalung
    tmp = F3._Tmp()
    _kucing_lokal(tmp, pose, warna, kalung)
    xform_into(s, tmp, rz(HEAD[arah]), (x, y, 0))


# ====================================================================== ekspor ====
def _json(path, data):
    with open(path, 'w') as f:
        json.dump(data, f, indent=1, ensure_ascii=False)
        f.write('\n')


def pack_grid(rows, row_names, col_names, fname, meta):
    """rows: list baris, tiap baris list (rgba, titik pijak). Sel seragam, titik pijak sama di semua sel."""
    flat = [fr for r in rows for fr in r]
    left = max(o[0] for _, o in flat); top = max(o[1] for _, o in flat)
    right = max(a.shape[1] - o[0] for a, o in flat); bottom = max(a.shape[0] - o[1] for a, o in flat)
    cw, ch = left + right, top + bottom
    ncol = max(len(r) for r in rows)
    sheet = Image.new('RGBA', (cw * ncol, ch * len(rows)), (0, 0, 0, 0))
    for j, r in enumerate(rows):
        for i, (a, o) in enumerate(r):
            sheet.alpha_composite(Image.fromarray(a, 'RGBA'), (i * cw + left - o[0], j * ch + top - o[1]))
    sheet.save(OUT_DIR / (fname + '.png'))
    m = {'sprite': fname + '.png', 'cell': [cw, ch], 'columns': ncol, 'rows': len(rows),
         'ground_anchor': [left, top], 'frames': col_names}
    if row_names:
        m['row_names'] = row_names
    m.update(meta)
    _json(OUT_DIR / (fname + '.json'), m)
    return sheet, (cw, ch)


def _spr(build, aspal=True, extra=(30, 16), pad=5):
    a, o, _, _ = F3.render_sprite(build, ground_mats=[P['asph'] if aspal else P['grass']], extra_px=extra, pad=pad)
    return a, o


def ekspor_mobil():
    out = {}
    for kind in MOBIL_URUT:
        fr = [_spr(lambda s, k=kind, a_=a_, st=st, dz=dz: mobil(s, k, 0, 0, a_, st, dz=dz))
              for a_, st, dz, _ in FRAME_MOBIL]
        names = [n for *_, n in FRAME_MOBIL]
        out[kind] = pack_grid([fr], None, names, 'obs_mobil_%s_sheet' % kind, {
            'note': 'Usulan, tools/env_art/kendaraan.py. searah = moncong kanan atas (lajur kiri, searah pemain), '
                    'lawan = moncong kiri bawah, masuk = moncong kiri atas (parkir menghadap rumah sisi seberang), '
                    'keluar = moncong kanan bawah. sein = lampu sein kanan menyala (tanda akan keluar dari parkir).',
            'anim': {'parkir': ['searah_parkir'], 'tanda_keluar': ['searah_parkir', 'searah_sein'],
                     'jalan_searah': ['searah_jalan_1', 'searah_jalan_2'], 'rem': ['searah_rem'],
                     'jalan_lawan': ['lawan_jalan_1', 'lawan_jalan_2']},
            'fps': {'tanda_keluar': 3, 'jalan_searah': 6, 'jalan_lawan': 6}})
    # contoh palette swap: sedan dan MPV parkir searah dalam enam warna
    warna = ['putih', 'perak', 'hitam', 'merah', 'biru', 'hijau']
    rows = []
    for kind in ('sedan', 'hatchback', 'mpv'):
        rows.append([_spr(lambda s, k=kind, w=w: mobil(s, k, 0, 0, 'searah', 'mati', body=WARNA_MOBIL[w])) for w in warna])
    out['warna'] = pack_grid(rows, ['sedan', 'hatchback', 'mpv'], warna, 'contoh_mobil_warna',
                             {'note': 'Lembar contoh palette swap bodi, bukan sprite game.'})
    return out


def ekspor_motor():
    out = {}
    for kind in MOTOR_URUT:
        fr = [_spr(lambda s, k=kind, a_=a_, jl=jl, dz=dz: motor_v(s, k, 0, 0, a_, jl, dz), extra=(16, 10), pad=4)
              for a_, jl, dz, _ in FRAME_MOTOR]
        names = [n for *_, n in FRAME_MOTOR]
        out[kind] = pack_grid([fr], None, names, 'obs_motor_%s_sheet' % kind, {
            'note': 'Usulan, tools/env_art/kendaraan.py. Parkir = standar samping, miring 9 derajat ke kiri motor, '
                    'tanpa pengendara. Jalan = dengan pengendara berhelm, dua frame (bodi naik 1 px). Skala x1,7 dari model lokal supaya pengendara setinggi loper.',
            'anim': {'jalan_searah': ['searah_jalan_1', 'searah_jalan_2'],
                     'jalan_lawan': ['lawan_jalan_1', 'lawan_jalan_2']},
            'fps': {'jalan_searah': 8, 'jalan_lawan': 8}})
    warna = ['merah', 'biru', 'putih', 'hitam', 'hijau', 'pink']
    rows = [[_spr(lambda s, w=w: motor_v(s, 'matic', 0, 0, 'masuk', False, body=WARNA_MOTOR[w]), extra=(16, 10), pad=4)
             for w in warna]]
    jak = list(JAKET)
    rows.append([_spr(lambda s, j=j, i=i: motor_v(s, 'bebek', 0, 0, 'lawan', True, jaket=JAKET[j],
                                                  helm=HELM[list(HELM)[i % 4]]), extra=(16, 10), pad=4)
                 for i, j in enumerate(jak[:6])])
    out['warna'] = pack_grid(rows, ['matic_bodi', 'bebek_pengendara'], warna, 'contoh_motor_warna',
                             {'note': 'Lembar contoh palette swap, bukan sprite game.', 'jaket': jak[:6]})
    return out


def ekspor_kucing():
    out = {}
    for w in KUCING_URUT:
        misi = w == 'belang_tiga'
        poses = KUCING_POSE_MISI if misi else KUCING_POSE
        rows = [[_spr(lambda s, p=p, w=w, a_=a_: kucing(s, 0, 0, p, w, a_), aspal=False, extra=(10, 6), pad=3)
                 for p in poses] for a_ in KUCING_ARAH]
        fname = 'mission_kucing_sheet' if misi else 'npc_kucing_%s_sheet' % w
        anim = {'diam': ['duduk'], 'tidur': ['tidur'], 'jalan': ['jalan_1', 'jalan_2'],
                'lari': ['lari_1', 'lari_2'], 'kaget': ['kaget']}
        fps = {'jalan': 6, 'lari': 10}
        if misi:
            anim['ditangkap'] = ['ditangkap_1', 'ditangkap_2']
            fps['ditangkap'] = 3
        out[w] = pack_grid(rows, KUCING_ARAH, poses, fname, {
            'note': 'Usulan, tools/env_art/kendaraan.py. Baris = arah moncong (searah kanan atas, masuk kiri atas, '
                    'lawan kiri bawah, keluar kanan bawah). ' +
                    ('Kucing misi Bu Ratmi: belang tiga, kalung merah, lonceng.' if w == 'belang_tiga' else
                     'Kucing dekorasi: tanpa kalung.') +
                    (' ditangkap_1/_2 (Fase 5C, usulan): duduk tenang, mata terpejam, kepala menunduk, ekor melingkar; '
                     '3 fps berulang.' if misi else ''),
            'anim': anim, 'fps': fps})
    return out


# ================================================================ layar contoh ====
def build_layar(s):
    F3.pasang_antena_varian()
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
    for i, yc in enumerate(PR.FAR_YC):
        F3.house_far_v(s, yc, PR.WALLS[i], PR.ROOFS[i], seed=i, kind=PR.HOUSE_TYPES[i % 3],
                       pelanggan=F3.PELANGGAN[i])
        if i % 4 != 3:
            tree_perumahan(s, PR.FX1 - 26, yc + 64, TREE_KINDS[i % 3], seed=i)
        else:
            bush(s, PR.FX1 - 10, yc + 62, 6, seed=i)
    for i, yc in enumerate(PR.NEAR_YC):
        PR.house_near(s, yc, PR.WALLS[(i + 3) % 8], PR.ROOFS[(i + 2) % 8], seed=i)
        bush(s, PR.NX0 - 10, yc + 10, 5, seed=20 + i)
        if i % 2 == 1:
            tree_perumahan(s, PR.NX1 + 30, yc + 54, TREE_KINDS[(i + 1) % 3], seed=30 + i)
    for i, yc in enumerate([-420, -300, -180, -60, 60, 180]):
        s.add(box(PR.FX0 - 146, PR.FX0 - 64, yc - 40, yc + 40, 0, 32, P[PR.WALLS[(i + 5) % 8]]))
        s.add(hip(PR.FX0 - 151, PR.FX0 - 59, yc - 45, yc + 45, 31, 54, mats=[P[PR.ROOFS[(i + 1) % 8]], P['cream']],
                  tex=roof_tex('genteng', 40 + i, wall=True)))
    s.add(box(PR.NX1 + 50, PR.NX1 + 54, -900, 900, 0, 14, P['conc']))
    for ly in (-256, -18, 256):
        lamp_post(s, -PR.EDGE[1] - 3, ly, h=58, arm=15, toward=+1, light_r=100)
    # kendaraan dan kucing (titik di dunia dicatat untuk penanda nomor)
    tanda = {}
    a, b = PR.far_drive(-64)
    mobil(s, 'hatchback', -88, (a + b) / 2, 'masuk', 'mati'); tanda[1] = (-88, (a + b) / 2, 28)
    mobil(s, 'mpv', -33, -140, 'searah', 'sein'); tanda[2] = (-33, -140, 32)
    kucing(s, -40, -186, 'duduk', 'belang_tiga', 'keluar'); tanda[3] = (-40, -186, 10)
    mobil(s, 'sedan', -22, -10, 'searah', 'jalan'); tanda[4] = (-22, -10, 30)
    mobil(s, 'angkot', 24, 70, 'lawan', 'jalan'); tanda[5] = (24, 70, 38)
    mobil(s, 'pikap', 33, 196, 'lawan', 'mati'); tanda[6] = (33, 196, 30)
    motor_v(s, 'matic', 32, -120, 'lawan', True); tanda[7] = (32, -120, 20)
    motor_v(s, 'bebek', -30, 236, 'searah', True); tanda[8] = (-30, 236, 20)
    motor_v(s, 'sayur', 22, 262, 'lawan', True); tanda[9] = (22, 262, 22)
    motor_v(s, 'sport', -92, 30, 'masuk', False); tanda[10] = (-92, 30, 16)
    kucing(s, -88, 100, 'tidur', 'oren', 'lawan'); tanda[11] = (-88, 100, 8)
    kucing(s, -96, 300, 'jalan_1', 'tuksedo', 'searah'); tanda[12] = (-96, 300, 10)
    return tanda


def render_layar(tname='siang', W=640, H=360, ox=427, oy=172, out='layar_kendaraan.png'):
    s = Scene(W, H, ox, oy)
    tanda = build_layar(s)
    s.render(TIMES[tname])
    sprites = [(PR.loper_frame(5, 1), (23, 46), PR.PLAYER)]
    img = finish_with_sprites(s, sprites)
    img = draw_ropes(s, img)
    im = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), 'RGB')
    im.save(OUT_DIR / out)
    pos = {k: tuple(float(v[0]) for v in s.proj((x, y, z))) for k, (x, y, z) in tanda.items()}
    _json(OUT_DIR / (out.replace('.png', '_tanda.json')), pos)
    return im, pos


# ----------------------------------------------------------------- salin ke repo ----
SALIN_SPRITE = {
    'assets/sprites/npc': ['mission_kucing_sheet'],
}


def salin():
    import shutil
    for folder, names in SALIN_SPRITE.items():
        d = F3.ROOT / folder
        d.mkdir(parents=True, exist_ok=True)
        for n in names:
            for ext in ('.png', '.json'):
                shutil.copyfile(OUT_DIR / (n + ext), d / (n + ext))


if __name__ == '__main__':
    ekspor_mobil()
    ekspor_motor()
    ekspor_kucing()
    render_layar()
    print('selesai ->', OUT_DIR)
    if '--salin' in sys.argv[1:]:
        salin()
        print('disalin ke assets/sprites/npc/ (hanya mission_kucing_sheet)')
