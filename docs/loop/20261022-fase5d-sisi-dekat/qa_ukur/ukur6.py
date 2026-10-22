#!/usr/bin/env python3
"""QA1 AC-6: ukur tumpang tindih sisi dekat dari PNG/JSON, proyeksi iso ditulis sendiri, rute nyata (dump QA)."""
import json, sys, math
import numpy as np
from PIL import Image
R = '/Users/ronggur/Works/Games/Loper-Koran/apps/loper-koran/assets/sprites/'
DUMP = '/private/tmp/claude-501/-Users-ronggur-Works-Games-Loper-Koran-apps-loper-koran/ede651fa-6106-4ad1-a67e-c27dcc2dfc44/scratchpad/dump_qa_head.json'

def sprite(path):
    base = R + path
    a = np.array(Image.open(base + '.png').convert('RGBA'))[:, :, 3] >= 252
    j = json.load(open(base + '.json'))
    return a, tuple(j['ground_anchor']), j

def layar(lat, maju):
    return (round((lat + maju) * 32.0), round((lat - maju) * 16.0))

def yurut(lat, maju):
    return (lat - maju) * 16.0

SPR = {}
def rumah_sprite(sisi, jenis, pelanggan):
    k = (sisi, jenis, pelanggan)
    if k not in SPR:
        SPR[k] = sprite('houses/perumahan/house_perumahan_%s_%s' % (jenis, 'pelanggan' if pelanggan else 'bukan'))
    return SPR[k]

# gabungan pemain
def topeng_pemain():
    pts = set()
    for n in ['loper_agen', 'loper_agen_melambat', 'loper_agen_meluncur', 'loper_agen_rem', 'loper_agen_lempar']:
        a, anc, j = sprite('loper/' + n)
        cw, ch = j['cell']
        for ry in range(a.shape[0] // ch):
            for cx in range(a.shape[1] // cw):
                cell = a[ry * ch:(ry + 1) * ch, cx * cw:(cx + 1) * cw]
                ys, xs = np.nonzero(cell)
                for y, x in zip(ys, xs):
                    pts.add((x - anc[0], y - anc[1]))
    return np.array(sorted(pts))
PEMAIN = topeng_pemain()

def ada_opak(spr, pijak_layar, pts):
    a, anc, _ = spr
    lx = pts[:, 0] - pijak_layar[0] + anc[0]
    ly = pts[:, 1] - pijak_layar[1] + anc[1]
    ok = (lx >= 0) & (ly >= 0) & (lx < a.shape[1]) & (ly < a.shape[0])
    hasil = np.zeros(len(pts), bool)
    hasil[ok] = a[ly[ok], lx[ok]]
    return hasil

def piksel_tanah(lat0, m0, w, p):
    lo = layar(lat0, m0)  # perkiraan, scan kotak
    cs = [layar(lat0, m0), layar(lat0 + w, m0), layar(lat0, m0 + p), layar(lat0 + w, m0 + p)]
    xs = [c[0] for c in cs]; ys = [c[1] for c in cs]
    X, Y = np.meshgrid(np.arange(min(xs) - 1, max(xs) + 2), np.arange(min(ys) - 1, max(ys) + 2))
    sx = X + 0.5; sy = Y + 0.5
    l = sx / 64.0 + sy / 32.0; m = sx / 64.0 - sy / 32.0
    ok = (l >= lat0) & (l < lat0 + w) & (m >= m0) & (m < m0 + p)
    return np.stack([X[ok], Y[ok]], 1)

rutes = json.load(open(DUMP))
MAKS = dict(kotak=0.0, zona=0.0, halaman=0.0, teras=0.0)
pl = {}
laporan = {}
for seed, d in list(rutes.items())[:100]:
    r = d['rute']
    rumah = r['rumah']
    sprites = []  # (spr, layar, y)
    for h in rumah:
        sisi_dekat = h['sisi'] == 2
        jenis = h['jenis']
        lat = 5.0 if sisi_dekat else -4.5
        maju = h['maju_ubin'] + 1.0
        for pel in (True, False):
            pass
        h['_pos'] = (lat, maju)
    # variasi terburuk: dua varian per rumah dihitung terpisah (pelanggan = True dan False)
    for varian in (True, False):
        spr_list = []
        for h in rumah:
            lat, maju = h['_pos']
            spr_list.append((rumah_sprite(h['sisi'], h['jenis'], varian), layar(lat, maju), yurut(lat, maju), h))
        # kotak surat spr
        kp = sprite('props/prop_kotak_surat' if varian else 'props/prop_kotak_surat_bukan')
        for h in rumah:
            if h['sisi'] != 2:
                continue
            m0 = h['maju_ubin']
            near = [s for s in spr_list if abs(s[3]['maju_ubin'] - m0) < 14]
            # kotak: piksel opak
            a, anc, _ = kp
            ys, xs = np.nonzero(a)
            tit = layar(2.125, m0 + 1.75)
            pts = np.stack([xs - anc[0] + tit[0], ys - anc[1] + tit[1]], 1)
            yref = yurut(2.125, m0 + 1.75)
            kena = np.zeros(len(pts), bool)
            for s in near:
                if s[2] >= yref:
                    kena |= ada_opak(s[0], s[1], pts)
            MAKS['kotak'] = max(MAKS['kotak'], kena.mean())
            # zona kotak, halaman
            for nama, (l0, mm, w, p) in dict(zona=(1.75, m0 + 1.25, 1.0, 1.25), halaman=(2.0, m0 - 0.5, 1.90625, 3.0)).items():
                pts = piksel_tanah(l0, mm, w, p)
                kena = np.zeros(len(pts), bool)
                for s in near:
                    kena |= ada_opak(s[0], s[1], pts)
                MAKS[nama] = max(MAKS[nama], kena.mean())
                laporan.setdefault(nama, []).append(kena.mean())
            # teras
            terj = rumah_sprite(2, h['jenis'], varian)[2]['teras_ubin']
            lat, maju = h['_pos']
            pts = piksel_tanah(5.0 + terj[0], m0 + 1.0 + terj[1], terj[2], terj[3])
            kena = np.zeros(len(pts), bool)
            for s in near:
                if s[3] is h:
                    continue
                kena |= ada_opak(s[0], s[1], pts)
            MAKS['teras'] = max(MAKS['teras'], kena.mean())
            # pemain
            for lateral in [x * 0.125 for x in range(-8, 17)]:
                for k in range(0, 65):
                    maju = m0 - 3 + k * 0.125
                    lay = layar(lateral, maju)
                    pts = PEMAIN + np.array(lay)
                    yp = yurut(lateral, maju)
                    kena = np.zeros(len(pts), bool)
                    for s in near:
                        if s[2] >= yp:
                            kena |= ada_opak(s[0], s[1], pts)
                    f = kena.mean()
                    kk = round(lateral, 3)
                    if f > pl.get(kk, (0,))[0]:
                        pl[kk] = (f, seed, h['id'], round(maju, 3), varian)
print('MAKS', MAKS)
for k in sorted(pl):
    print('pemain lateral', k, pl[k])
