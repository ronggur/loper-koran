"""Animasi jatuh pemain (usulan): menabrak, terlempar lewat setang, jatuh terjerembab muka ke tanah.

Dipakai dengan renderer yang sama dengan sprite kayuh (iso.py, 3 nada, garis luar #0E0A1C).
Hanya arah `normal` (jalan ke kanan atas). Tinggi sel dan titik pijak mengikuti sheet kayuh, jadi
offset Godot sama: (0, -17).

    python3 tools/loper_art/jatuh.py --out build/loper_art/jatuh
"""
import argparse
import json
import math
import os
import numpy as np
from PIL import Image
import iso
from iso import Model, render, mat, flat, W2L, LIGHT
from loper import (R, REAR, FRONT, BB, S, HT, HB, HR, SKINS, HAIR, GRAY, DARK, TIRE, PAPER, PAPER2, v)
from base import BASE, ground

BIG, CX, CY = 170, 70, 118          # canvas besar; titik pijak (tengah sepeda di tanah) di (CX, CY)
ANCHOR_A = 8.5                      # titik pijak di koordinat lokal sepeda (sama dengan produce.py)
DUST = mat('#fbf6e8', '#f2e7c9', '#dccba6')


# ---------------------------------------------------------------- transforms
def rot_b(deg):
    """Rotasi di bidang (a, c) terhadap sumbu b. + = hidung turun / bagian atas maju."""
    t = math.radians(deg)
    return np.array([[math.cos(t), 0, math.sin(t)], [0, 1, 0], [-math.sin(t), 0, math.cos(t)]])


def rot_a(deg):
    """Rotasi terhadap sumbu a (maju). + = rebah ke kanan, - = rebah ke kiri."""
    t = math.radians(deg)
    return np.array([[1, 0, 0], [0, math.cos(t), math.sin(t)], [0, -math.sin(t), math.cos(t)]])


def rot_c(deg):
    """Rotasi terhadap sumbu c (atas). + = berputar ke kanan."""
    t = math.radians(deg)
    return np.array([[math.cos(t), -math.sin(t), 0], [math.sin(t), math.cos(t), 0], [0, 0, 1]])


def rigid(Rm, pivot, move):
    pivot, move = np.asarray(pivot, float), np.asarray(move, float)

    def f(P, N):
        return (P - pivot) @ Rm.T + pivot + move, N @ Rm.T

    def pt(p):
        return (np.asarray(p, float) - pivot) @ Rm.T + pivot + move
    return f, pt


def bike_pose(pitch=0.0, roll=0.0, move=(0, 0, 0), yaw=0.0):
    """Sepeda: menungging di roda depan (pitch), lalu rebah ke samping (roll), lalu bergeser."""
    Rp = rot_b(pitch)
    Rr = rot_a(roll)
    Ry = rot_c(yaw)
    Rm = Ry @ Rr @ Rp
    pivot = FRONT - v(0, 0, R)          # titik kontak roda depan
    f0, pt0 = rigid(Rm, pivot, (0, 0, 0))
    probe = [REAR + v(R * math.cos(t), s, R * math.sin(t)) for t in np.linspace(0, 2 * math.pi, 24) for s in (-0.45, 0.45)]
    probe += [FRONT + v(R * math.cos(t), s, R * math.sin(t)) for t in np.linspace(0, 2 * math.pi, 24) for s in (-0.45, 0.45)]
    probe += [v(14.2, s * 3.9, 17.7) for s in (-1, 1)] + [v(0.1, s * 3.45, 8.0) for s in (-1, 1)]
    probe += [BB + v(0, s * 3.4, 0) for s in (-1, 1)]
    low = min(pt0(p)[2] for p in probe)
    mv = np.asarray(move, float) + v(0, 0, -low + 0.25 if (pitch or roll) else 0)
    return rigid(Rm, pivot, mv)


# ---------------------------------------------------------------- bike
def draw_bike(M, cfg, xf, phi_deg=-40):
    M.xf = xf
    p_tire = M.part('tire', outline=False)
    p_rim = M.part('rim', outline=False)
    p_frame = M.part('frame', outline=False)
    p_bar = M.part('bar', outline=False)
    for C in (REAR, FRONT):
        M.ring(C, R - 1.0, R, 0.45, TIRE, p_tire)
        M.ring(C, R - 1.55, R - 1.15, 0.2, GRAY, p_rim)
        M.sphere(C, 0.6, GRAY, p_rim)
    fr = cfg['bike']
    fr = (fr[1], fr[1], fr[2])
    M.ring(BB, 1.3, 2.0, 0.25, GRAY, p_rim, lat=1.3)
    M.capsule(BB + v(0, 1.3, 2.0), REAR + v(0, 1.3, 0.9), 0.2, DARK, p_rim, step=0.15)
    M.capsule(BB + v(0, 1.3, -2.0), REAR + v(0, 1.3, -0.9), 0.2, DARK, p_rim, step=0.15)
    tubes = [(BB, S, 0.5), (S + v(0, 0, 0.2), HT, 0.45), (BB, HB, 0.5),
             (BB + v(0, 0.7, 0), REAR + v(0, 0.7, 0), 0.4), (BB + v(0, -0.7, 0), REAR + v(0, -0.7, 0), 0.4),
             (S + v(0, 0.6, 0), REAR + v(0, 0.7, 0), 0.4), (S + v(0, -0.6, 0), REAR + v(0, -0.7, 0), 0.4),
             (HT, HB, 0.6), (HB + v(0, 0.8, 0), FRONT + v(0, 0.8, 0), 0.36), (HB + v(0, -0.8, 0), FRONT + v(0, -0.8, 0), 0.36)]
    for a, b, r in tubes:
        M.capsule(a, b, r, fr, p_frame)
    M.capsule(S, v(4.6, 0, 16.4), 0.4, GRAY, p_bar)
    M.box(v(4.3, 0, 16.7), v(1, 0, 0), v(0, 1, 0), v(0, 0, 1), 1.9, 1.0, 0.45, mat('#553428', '#3b2219', '#2a1e17'), M.part('saddle'))
    M.capsule(HT, v(14.3, 0, 17.6), 0.4, GRAY, p_bar)
    M.capsule(v(14.2, -3.6, 17.7), v(14.2, 3.6, 17.7), 0.38, DARK, p_bar)
    M.capsule(v(13.6, 3.0, 17.8), v(13.6, 3.9, 17.8), 0.55, DARK, p_bar)
    M.capsule(v(13.6, -3.0, 17.8), v(13.6, -3.9, 17.8), 0.55, DARK, p_bar)
    M.sphere(v(14.1, -1.6, 18.15), 0.5, mat('#ffe08a', '#ffc94a', '#d9a33a'), p_bar)
    p_l = M.part('lamp')
    M.box(v(15.6, 0, 15.0), v(1, 0, 0), v(0, 1, 0), v(0, 0, 1), 0.7, 0.8, 0.7, mat('#ffffff', '#f2e7c9', '#c2af86'), p_l)
    M.box(v(16.35, 0, 15.0), v(1, 0, 0), v(0, 1, 0), v(0, 0, 1), 0.08, 0.5, 0.45, flat('#ffc94a'), p_l, bias=0.3)
    p_rack = M.part('rack', outline=False)
    M.box(v(-0.2, 0, 13.6), v(1, 0, 0), v(0, 1, 0), v(0, 0, 1), 3.6, 1.4, 0.25, DARK, p_rack)
    for bb in (1.0, -1.0):
        M.capsule(v(-2.8, bb, 13.4), REAR + v(0, bb, 0), 0.25, DARK, p_rack)
        M.capsule(v(2.6, bb, 13.4), REAR + v(0, bb, 0), 0.25, DARK, p_rack)
    pan = cfg['pannier']
    for side in (1, -1):
        pc = v(0.1, side * 2.5, 10.6)
        M.box(pc, v(1, 0, 0), v(0, 1, 0), v(0, 0, 1), 3.0, 0.95, 3.0, pan, M.part(f'pannier{side}'))
        M.box(pc + v(0, 0, 2.55), v(1, 0, 0), v(0, 1, 0), v(0, 0, 1), 3.05, 1.0, 0.45,
              tuple(tuple(max(0, int(ch * 0.78)) for ch in col) for col in pan), M.part(f'pannier_rim{side}'), bias=0.05)
        sp = M.part(f'pannier_strap{side}', outline=False)
        for sa in (-1.4, 1.6):
            M.box(pc + v(sa, side * 1.0, -0.2), v(1, 0, 0), v(0, 1, 0), v(0, 0, 1), 0.35, 0.08, 2.4, cfg['pannier_strap'], sp, bias=0.15)
    phi = math.radians(phi_deg)
    for side, ph in ((1, phi), (-1, phi + math.pi)):
        pedal = BB + v(3.0 * math.cos(ph), side * 2.6, 3.0 * math.sin(ph))
        pcr = M.part(f'crank{side}', outline=False)
        M.capsule(BB + v(0, side * 1.5, 0), pedal + v(0, -side * 0.6, 0), 0.4, GRAY, pcr)
        M.box(pedal + v(0, 0, -0.3), v(1, 0, 0), v(0, 1, 0), v(0, 0, 1), 1.0, 0.8, 0.25, DARK, pcr)
    M.xf = None


# ---------------------------------------------------------------- props
NAVY = mat('#7480a3', '#5c6a8c', '#404a62')
STAR = mat('#fff3b0', '#ffe08a', '#ffc94a')


def draw_paper(M, c, yaw=0.0, tilt=0.0, k=0):
    """Koran terlipat yang terlempar dari tas: kertas krem dengan pita judul dongker."""
    Rm = rot_c(yaw) @ rot_b(tilt)
    u, w = Rm @ v(1, 0, 0), Rm @ v(0, 0, 1)
    vv = Rm @ v(0, 1, 0)
    c = np.asarray(c, float)
    M.box(c, u, vv, w, 1.9, 1.3, 0.32, PAPER if k % 2 == 0 else PAPER2, M.part(f'loose_paper{k}'))
    M.box(c + u * 1.0 + w * 0.3, u, vv, w, 0.45, 1.15, 0.06, NAVY, M.part(f'loose_mast{k}', outline=False), bias=0.2)


def draw_impact(M, center, n=6, r0=1.1, r1=3.4):
    """Bintang benturan kecil, menghadap kamera."""
    cam = W2L(np.array([1.0, 1.0, 1.0]))
    cam = cam / np.linalg.norm(cam)
    e1 = np.cross(v(0, 0, 1), cam); e1 /= np.linalg.norm(e1)
    e2 = np.cross(cam, e1)
    p = M.part('impact')
    center = np.asarray(center, float)
    for k in range(n):
        t = math.radians(90 + k * 360 / n)
        d = e1 * math.cos(t) + e2 * math.sin(t)
        M.capsule(center + d * r0, center + d * (r1 if k % 2 == 0 else r1 * 0.7), 0.45, STAR, p, bias=3.0)


def draw_dust(M, pts):
    p = M.part('dust')
    for c, r in pts:
        M.sphere(np.asarray(c, float), r, DUST, p, keep=lambda P, N: P[:, 2] >= 0.0)


def cap_mats(cfg):
    cap = cfg['cap']
    brim = cfg.get('brim') or tuple(tuple(max(0, int(ch * 0.72)) for ch in col) for col in cap)
    return cap, brim


def rim(a):
    """Tepi topi terbalik (relatif ke pusat kepala): rendah di belakang, naik di dahi."""
    return 0.6 + 0.28 * np.minimum(a, 0) + 0.42 * np.maximum(a, 0)


def draw_cap(M, cfg, center, Rc):
    """Topi terbalik sebagai benda sendiri. Rc: kolom = sumbu topi (depan kepala, kanan, atas) di koordinat lokal."""
    cap, brim_m = cap_mats(cfg)
    center = np.asarray(center, float)
    Rinv = Rc.T

    def local(P):
        return (W2L(P) - center) @ Rinv.T

    def capmat(P, N):
        h = local(P)
        d = N @ LIGHT
        band = h[:, 2] < rim(h[:, 0]) + 0.55
        out = np.empty((len(P), 3), np.uint8)
        for m, sel in ((cap, ~band), (brim_m, band)):
            o = np.empty((sel.sum(), 3), np.uint8)
            dd = d[sel]
            o[:] = m[1]
            o[dd > 0.78] = m[0]
            o[dd < -0.12] = m[2]
            out[sel] = o
        return out
    pc = M.part('cap')
    D = iso.dirs_for(HR + 0.08)
    p = (HR + 0.08) * D
    keep = p[:, 2] > rim(p[:, 0]) - 0.05
    P = center + p[keep] @ Rc.T
    N = D[keep] @ Rc.T
    M.add_local(P, N, capmat, pc, 1.7)
    # brim to the back of the head, drooping, as on the riding sprite
    bu = Rc @ (np.array([1.0, 0, 0.45]) / math.hypot(1, 0.45))
    bw = Rc @ (np.array([-0.45, 0, 1.0]) / math.hypot(1, 0.45))
    M.box(center + Rc @ v(-HR - 0.45, 0, -0.4), bu, Rc @ v(0, 1, 0), bw, 1.15 * HR / 3.6, 2.0 * HR / 3.6, 0.3,
          brim_m, M.part('brim'), bias=1.9)


# ---------------------------------------------------------------- rider
def draw_rider(M, cfg, J):
    """J: hip, shoulder (titik tengah), head, Rh (orientasi kepala), legs[side] = (knee, ankle, toe_dir),
    arms[side] = (elbow, hand), cap = None | 'head' | (center, Rc), eye (bool)."""
    skin = SKINS[cfg['skin']]
    pants, shirt = cfg['pants'], cfg['shirt']
    HIP, SH, HEAD = (np.asarray(J[k], float) for k in ('hip', 'shoulder', 'head'))
    w = SH - HIP
    Ld = np.linalg.norm(w)
    w = w / Ld
    side_ax = np.asarray(J.get('side', v(0, 1, 0)), float)
    vv = np.cross(w, side_ax)                        # arah punggung
    vv = vv / np.linalg.norm(vv)
    if J.get('flip_back'):
        vv = -vv
    # legs
    for side in (1, -1):
        knee, ankle, toe = (np.asarray(x, float) for x in J['legs'][side])
        hip = HIP + side_ax * side * 1.6
        M.capsule(hip, knee, 1.45, pants, M.part(f'leg{side}'))
        p_shin = M.part(f'shin{side}')
        M.capsule(knee, ankle, 1.15, pants, p_shin)
        cuff = (pants[1], pants[2], tuple(max(0, int(ch * 0.8)) for ch in pants[2]))
        M.capsule(ankle + (knee - ankle) * 0.16, ankle, 1.2, cuff, p_shin, bias=0.05)
        t = toe / np.linalg.norm(toe)
        sole = ankle - knee
        sole = sole / np.linalg.norm(sole)
        up = -sole
        up = up - t * (up @ t)
        up = up / np.linalg.norm(up)
        M.box(ankle + t * 0.9 - up * 0.6, t, np.cross(up, t), up, 1.75, 0.95, 0.85, cfg['shoes'], M.part(f'shoe{side}'))
    # torso + seat
    p_torso = M.part('torso')
    M.capsule(HIP - vv * 0.2 - side_ax * 1.4, HIP - vv * 0.2 + side_ax * 1.4, 2.0, pants, p_torso)
    mid = (HIP + SH) / 2 + vv * 0.1
    M.box(mid, vv, side_ax, w, 1.85, 2.35, Ld / 2, shirt, p_torso, hv_end=2.9)
    # arms
    for side in (1, -1):
        sh = SH + side_ax * side * 3.2 - w * 0.6
        elbow, hand = (np.asarray(x, float) for x in J['arms'][side])
        pa, pf = M.part(f'arm{side}'), M.part(f'forearm{side}')
        M.capsule(sh + (elbow - sh) * 0.35, elbow, 0.9, skin, pa)
        M.capsule(sh, sh + (elbow - sh) * 0.5, 1.3, shirt, pa)
        M.capsule(elbow, hand, 0.85, skin, pf)
        M.sphere(hand, 0.95, skin, pf)
    # head: Rh columns = (muka, kanan, atas kepala) in local coords
    Rh = np.asarray(J['Rh'], float)
    M.capsule(SH + w * 0.3, HEAD - Rh @ v(0.2, 0, 2.8), 1.25, skin, M.part('neck'))

    def headmat(P, N):
        h = (W2L(P) - HEAD) @ Rh
        d = N @ LIGHT
        is_hair = (h[:, 0] < -0.5) & (h[:, 2] > -2.2)
        out = np.empty((len(P), 3), np.uint8)
        for m, sel in ((skin, ~is_hair), (HAIR, is_hair)):
            o = np.empty((sel.sum(), 3), np.uint8)
            dd = d[sel]
            o[:] = m[1]
            o[dd > 0.78] = m[0]
            o[dd < -0.12] = m[2]
            out[sel] = o
        return out
    M.sphere(HEAD, HR, headmat, M.part('head'), bias=1.6)
    M.sphere(HEAD + Rh @ v(-0.3, HR - 0.2, -0.3), 0.75, skin, M.part('ear', outline=False), bias=1.8)
    if J.get('eye'):
        ed = Rh @ (np.array([0.42, 0.88, 0.02]) / np.linalg.norm([0.42, 0.88, 0.02]))
        up = Rh @ v(0, 0, 1)
        M.capsule(HEAD + ed * (HR - 0.05) - up * 0.25, HEAD + ed * (HR - 0.05) + up * 0.35, 0.36, flat('#0e0a1c'),
                  M.part('eye', outline=False), bias=2.0)
    capj = J.get('cap')
    if capj == 'head':
        draw_cap(M, cfg, HEAD + Rh @ v(0, 0, 0.05), Rh)
    elif capj is not None:
        draw_cap(M, cfg, capj[0], capj[1])


def head_frame(face, top):
    """Orientasi kepala dari arah muka dan arah ubun-ubun (kolom: muka, kanan, atas)."""
    f = np.asarray(face, float); f /= np.linalg.norm(f)
    t = np.asarray(top, float); t = t - f * (t @ f); t /= np.linalg.norm(t)
    r = np.cross(t, f)
    return np.stack([f, r, t], 1)


# ---------------------------------------------------------------- key poses
def frames(cfg):
    """Empat pose jatuh + satu variasi untuk loop terjerembab."""
    out = []
    # 0 menabrak: roda depan tertahan, sepeda menungging 16 derajat, pengendara terdorong ke depan
    xf, pt = bike_pose(pitch=22)
    bar = [pt(v(13.6, s * 3.3, 18.2)) for s in (1, -1)]
    hip = pt(v(9.0, 0, 20.2))
    shoulder = hip + v(9.2, 0, 2.0)
    head = shoulder + v(4.0, 0, 1.6)
    J = dict(hip=hip, shoulder=shoulder, head=head, Rh=head_frame(v(1, 0, -0.5), v(0.4, 0, 1)), eye=True, cap='head',
             legs={s: (hip + v(1.6, s * 2.0, -7.8), hip + v(-5.2, s * 2.4, -10.4), v(0.6, 0, -1)) for s in (1, -1)},
             arms={s: (shoulder + v(1.6, s * 4.2, -3.2), bar[0 if s == 1 else 1]) for s in (1, -1)})
    out.append(dict(bike=xf, rider=J, papers=[], dust=[], impact=pt(FRONT + v(R + 1.2, 1.0, 1.6))))

    # 1 terlempar: sepeda menungging, pengendara melayang tinggi di depan setang, menukik dengan tangan ke depan
    xf, pt = bike_pose(pitch=34)
    hip = v(18.0, 0.5, 29.0)
    shoulder = hip + v(9.0, 0, -4.4)
    head = shoulder + v(4.0, 0, -1.4)
    J = dict(hip=hip, shoulder=shoulder, head=head, Rh=head_frame(v(0.6, 0, -1), v(1, 0, 0.6)), eye=True,
             cap=(head + v(-1.4, -1.6, 5.4), head_frame(v(0.3, 0, -1), v(-0.4, 0, 1)) @ rot_b(-30)),
             legs={s: (hip + v(-7.0, s * 1.8, 3.8), hip + v(-14.0, s * 2.0, 7.8), v(-0.4, 0, -1)) for s in (1, -1)},
             arms={s: (shoulder + v(4.4, s * 3.6, -2.4), shoulder + v(8.8, s * 4.2, -4.6)) for s in (1, -1)})
    out.append(dict(bike=xf, rider=J, papers=[((-3.0, 5.0, 21.0), 30, 35, 0), ((5.0, -5.5, 24.0), -40, -20, 1)], dust=[]))

    # 2 mendarat: dada dan muka menghantam tanah, kaki masih terangkat; sepeda mulai rebah
    xf, pt = bike_pose(pitch=8, roll=-48, move=(0.6, -0.4, 0))
    hip = v(31.0, 3.2, 5.2)
    shoulder = hip + v(9.6, 0, -2.4)
    head = shoulder + v(4.2, 0, 1.6)
    J = dict(hip=hip, shoulder=shoulder, head=head, Rh=head_frame(v(0.2, 0, -1), v(1, 0, 0.1)), eye=False,
             cap=(v(head[0] + 6.6, 3.4, 2.4), head_frame(v(1, 0, 0.2), v(0.3, 0.2, 1))),
             legs={s: (hip + v(-6.2, s * 1.9, 5.4), hip + v(-9.4, s * 2.2, 12.6), v(-0.3, 0, -1)) for s in (1, -1)},
             arms={s: (shoulder + v(2.6, s * 5.2, -1.2), shoulder + v(6.4, s * 6.2, -1.3)) for s in (1, -1)})
    out.append(dict(bike=xf, rider=J, papers=[((-3.6, 6.4, 4.4), 60, 40, 0), ((10.0, -6.0, 3.0), -20, 20, 1)],
                    dust=[(v(head[0] + 1.8, 6.6, 0), 1.7), (v(head[0] + 3.6, 0.6, 0), 1.4), (v(hip[0] - 1.0, 7.8, 0), 1.2)]))

    # 3 terjerembab: tengkurap, muka ke tanah, tangan terentang; satu kaki terangkat
    xf, pt = bike_pose(pitch=0, roll=-84, move=(1.0, -0.8, 0))
    hip = v(32.0, 3.6, 2.1)
    shoulder = hip + v(10.0, 0, 0.2)
    head = shoulder + v(4.3, 0, 2.1)
    lying = dict(hip=hip, shoulder=shoulder, head=head, Rh=head_frame(v(0.15, 0, -1), v(1, 0, 0.05)), eye=False,
                 cap=(v(head[0] + 6.0, 4.6, 0.1), head_frame(v(1, 0.3, 0), v(0, 0, 1))),
                 arms={s: (shoulder + v(2.4, s * 5.0, -1.4), shoulder + v(6.0, s * 6.4, -1.2)) for s in (1, -1)})
    papers = [((-3.0, 7.6, 0.35), 55, 0, 0), ((11.0, -7.4, 0.35), -25, 0, 1), ((3.6, 9.4, 0.35), 10, 0, 2)]
    J3 = dict(lying, legs={1: (hip + v(-8.0, 2.2, -0.6), hip + v(-12.0, 2.8, 5.8), v(-0.2, 0, -1)),
                           -1: (hip + v(-8.0, -2.2, -0.8), hip + v(-15.6, -2.6, -0.4), v(-0.5, 0, -0.85))})
    out.append(dict(bike=xf, rider=J3, papers=papers, dust=[]))
    # 4 variasi loop: kaki yang terangkat turun sedikit
    J4 = dict(lying, legs={1: (hip + v(-8.0, 2.2, -0.6), hip + v(-13.6, 2.8, 3.6), v(-0.3, 0, -1)),
                           -1: J3['legs'][-1]})
    out.append(dict(bike=xf, rider=J4, papers=papers, dust=[]))
    return out


def render_frame(cfg, F):
    iso.POSE['yaw'] = iso.POSE['lean'] = 0.0
    M = Model()
    draw_bike(M, cfg, F['bike'])
    for c, yaw, tilt, k in F['papers']:
        draw_paper(M, c, yaw, tilt, k)
    draw_rider(M, cfg, F['rider'])
    if F['dust']:
        draw_dust(M, F['dust'])
    if F.get('impact') is not None:
        draw_impact(M, F['impact'])
    J = F['rider']
    _, pt = None, None
    sh = [M.ground_ellipse((ANCHOR_A, 0.0), 12.0, 4.0)]
    body_c = (np.asarray(J['hip']) + np.asarray(J['shoulder'])) / 2
    if body_c[2] < 8:
        sh.append(M.ground_ellipse((body_c[0], body_c[1]), 9.5, 4.2))
    else:
        sh.append(M.ground_ellipse((body_c[0], body_c[1]), 6.0, 2.6))
    c = iso.L2W(np.array([ANCHOR_A, 0.0, 0.0]))
    return render(M, BIG, BIG, CX - (c[0] - c[1]), CY - (c[0] + c[1]) / 2, shadow_pts=np.concatenate(sh))


ANIMS = [dict(name='jatuh_normal', frames=[0, 1, 2, 3], fps=10, loop=False),
         dict(name='terjerembab_normal', frames=[3, 4], fps=3, loop=True)]


def main():
    ap = argparse.ArgumentParser(description='Render animasi jatuh pemain (usulan).')
    ap.add_argument('--out', default='build/loper_art/jatuh')
    ap.add_argument('--res-dir', default='res://assets/sprites/loper')
    args = ap.parse_args()
    out = args.out
    os.makedirs(out, exist_ok=True)
    cfg = BASE
    imgs = [render_frame(cfg, F) for F in frames(cfg)]
    alpha = np.zeros((BIG, BIG), bool)
    for a in imgs:
        alpha |= a[..., 3] > 0
    ys, xs = np.where(alpha)
    # same anchor offset from the cell centre as the riding sheet (0, +17): AY - CH/2 = 17
    half = int(max(CX - xs.min(), xs.max() + 1 - CX)) + 1
    CW = 2 * half
    AY = max(46, int(CY - ys.min()) + 1)
    CH = 2 * (AY - 17)
    assert ys.max() < CY - AY + CH, 'frame keluar di bawah sel'
    x0, y0 = CX - half, CY - AY
    name = 'loper_agen_jatuh'
    sheet = Image.new('RGBA', (CW * len(imgs), CH), (0, 0, 0, 0))
    for i, a in enumerate(imgs):
        sheet.alpha_composite(Image.fromarray(a[y0:y0 + CH, x0:x0 + CW], 'RGBA'), (i * CW, 0))
    sheet.save(f'{out}/{name}.png')
    anims = []
    for A in ANIMS:
        anims.append(dict(A, regions=[[f * CW, 0, CW, CH] for f in A['frames']]))
    meta = dict(sprite=f'{name}.png', cell=[CW, CH], columns=len(imgs), rows=1, ground_anchor=[half, AY],
                godot_offset=[0, CH / 2 - AY], status='usulan',
                note='Titik pijak = posisi sepeda saat menabrak. Offset sama dengan sheet kayuh, jadi animasi ini bisa masuk SpriteFrames yang sama.',
                animations=anims)
    json.dump(meta, open(f'{out}/{name}.json', 'w'), indent=1, ensure_ascii=False)
    # SpriteFrames snippet (separate resource, same offset as the riding sheet)
    subs, anim_txt, sid = [], [], 0
    for A in anims:
        fr = []
        for (x, y, w, h) in A['regions']:
            sid += 1
            subs.append(f'[sub_resource type="AtlasTexture" id="AtlasTexture_j{sid}"]\natlas = ExtResource("1_sheet")\nregion = Rect2({x}, {y}, {w}, {h})\n')
            fr.append('{\n"duration": 1.0,\n"texture": SubResource("AtlasTexture_j%d")\n}' % sid)
        anim_txt.append('{\n"frames": [' + ', '.join(fr) + '],\n"loop": %s,\n"name": &"%s",\n"speed": %.1f\n}'
                        % ('true' if A['loop'] else 'false', A['name'], A['fps']))
    open(f'{out}/{name}_frames.tres', 'w').write(
        f'[gd_resource type="SpriteFrames" load_steps={sid + 2} format=3]\n\n'
        f'[ext_resource type="Texture2D" path="{args.res_dir}/{name}.png" id="1_sheet"]\n\n'
        + '\n'.join(subs) + '\n[resource]\nanimations = [' + ', '.join(anim_txt) + ']\n')
    pv = f'{out}/preview'
    os.makedirs(pv, exist_ok=True)
    sheet.resize((sheet.width * 4, sheet.height * 4), Image.NEAREST).save(f'{pv}/{name}_x4.png')
    GW, GH = CW + 20, CH + 10
    seq = [0, 1, 2, 3, 4, 3, 4, 3, 4]
    durs = [100, 100, 100, 330, 330, 330, 330, 330, 900]
    gif = []
    for f in seq:
        g = Image.fromarray(ground(GW, GH, 10 + half + 0.5, 5 + AY), 'RGBA')
        g.alpha_composite(sheet.crop((f * CW, 0, (f + 1) * CW, CH)), (10, 5))
        gif.append(g.convert('RGB').resize((GW * 4, GH * 4), Image.NEAREST))
    gif[0].save(f'{pv}/prev_jatuh_normal.gif', save_all=True, append_images=gif[1:], duration=durs, loop=0)
    print(f'{name}: {len(imgs)} frame, sel {CW}x{CH}, titik pijak ({half}, {AY}) -> {out}')


if __name__ == '__main__':
    main()
