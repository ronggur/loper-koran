"""Animasi pemain Fase 5C (usulan): jatuh dan terjerembab lima arah, bangkit, dan berhenti dengan kaki turun.

Dipakai dengan renderer yang sama dengan sprite kayuh dan jatuh normal (iso.py, 3 nada, garis luar #0E0A1C).
Pose jatuh diambil dari jatuh.py tanpa diubah; arah lain diputar lewat yaw yang sama dengan base.HEADINGS,
jadi arah kiri dan kanan digambar sendiri (tidak dicerminkan).

Sel jatuh dan bangkit 140x88, titik pijak (70, 61) = posisi sepeda saat menabrak, untuk kelima arah.
AY - CH/2 = 17, jadi offset Godot tetap (0, -17) seperti sheet kayuh.

    python3 tools/loper_art/fase5c.py --out build/loper_art/fase5c
"""
import argparse
import json
import math
import os
import numpy as np
from PIL import Image
import iso
from iso import Model, render
import jatuh as JT
from jatuh import rot_c, bike_pose, draw_bike, draw_paper, draw_rider, draw_dust, draw_impact, head_frame, ANCHOR_A
from loper import v, build
from base import BASE, HEADINGS, ground

DIRS = [h[0] for h in HEADINGS]
YAW = {h[0]: h[1] for h in HEADINGS}
LEAN = {h[0]: h[2] for h in HEADINGS}
STEER = {h[0]: h[3] for h in HEADINGS}

CW, CH, AX, AY = 140, 88, 70, 61            # sel jatuh/bangkit
BIG, CX, CY = 240, 120, 140                 # kanvas kerja (lebih besar dari sel supaya luapan terdeteksi
PIVOT = v(17.0, 0.0, 0.0)                   # titik kontak roda depan: poros putar tubuh untuk TWIST

# Arah serong_kiri (atas layar): tubuh tengkurap lurus ke atas layar terbaca seperti orang berdiri.
# Tubuh diputar sedikit di tanah supaya miring di layar (usulan; arah lain 0).
TWIST = {'normal': 0, 'serong_kanan': 0, 'kanan': 0, 'serong_kiri': 30, 'kiri': 0}
TWIST_SCALE = [0.0, 0.5, 1.0, 1.0, 1.0]     # per frame jatuh 0-4


# ---------------------------------------------------------------- util
def _rot_pts(R, p, pivot):
    return (np.asarray(p, float) - pivot) @ R.T + pivot


def twist_rider(J, deg, pivot=PIVOT):
    """Putar seluruh tubuh (sendi, kepala, topi) di sumbu atas terhadap pivot."""
    if not deg:
        return J
    R = rot_c(deg)
    o = dict(J)
    for k in ('hip', 'shoulder', 'head'):
        o[k] = _rot_pts(R, J[k], pivot)
    o['Rh'] = R @ np.asarray(J['Rh'], float)
    o['side'] = R @ np.asarray(J.get('side', v(0, 1, 0)), float)
    o['legs'] = {s: (_rot_pts(R, kn, pivot), _rot_pts(R, an, pivot), R @ np.asarray(t, float))
                 for s, (kn, an, t) in J['legs'].items()}
    o['arms'] = {s: (_rot_pts(R, e, pivot), _rot_pts(R, h, pivot)) for s, (e, h) in J['arms'].items()}
    cap = J.get('cap')
    if cap is not None and cap != 'head':
        o['cap'] = (_rot_pts(R, cap[0], pivot), R @ np.asarray(cap[1], float))
    return o


def twist_papers(papers, deg, pivot=PIVOT):
    if not deg:
        return papers
    R = rot_c(deg)
    return [(tuple(_rot_pts(R, c, pivot)), yaw + deg, tilt, k) for c, yaw, tilt, k in papers]


def render_frame(F, yaw, shadow_extra=None):
    """Seperti jatuh.render_frame, dengan yaw arah. F: bike, rider, papers, dust, impact (opsional)."""
    iso.POSE['yaw'], iso.POSE['lean'] = yaw, 0.0
    M = Model()
    draw_bike(M, BASE, F['bike'])
    for c, pyaw, tilt, k in F['papers']:
        draw_paper(M, c, pyaw, tilt, k)
    if F.get('rider') is not None:
        draw_rider(M, BASE, F['rider'])
    if F.get('dust'):
        draw_dust(M, F['dust'])
    if F.get('impact') is not None:
        draw_impact(M, F['impact'])
    sh = [M.ground_ellipse(F.get('bike_shadow', (ANCHOR_A, 0.0)), 12.0, 4.0)]
    J = F.get('rider')
    if J is not None:
        body_c = (np.asarray(J['hip']) + np.asarray(J['shoulder'])) / 2
        if F.get('standing'):
            sh.append(M.ground_ellipse((body_c[0], body_c[1]), 4.5, 3.6))
        elif body_c[2] < 8:
            sh.append(M.ground_ellipse((body_c[0], body_c[1]), 9.5, 4.2))
        else:
            sh.append(M.ground_ellipse((body_c[0], body_c[1]), 6.0, 2.6))
    c = iso.L2W(np.array([ANCHOR_A, 0.0, 0.0]))
    img = render(M, BIG, BIG, CX - (c[0] - c[1]), CY - (c[0] + c[1]) / 2, shadow_pts=np.concatenate(sh))
    iso.POSE['yaw'] = iso.POSE['lean'] = 0.0
    return img


def crop_cell(img, name=''):
    """Potong sel CWxCH dengan titik pijak (AX, AY); gagal kalau ada piksel di luar sel."""
    a = img[..., 3] > 0
    y0, x0 = CY - AY, CX - AX
    inside = np.zeros_like(a)
    inside[y0:y0 + CH, x0:x0 + CW] = True
    out = int((a & ~inside).sum())
    assert out == 0, f'{name}: {out} piksel keluar dari sel {CW}x{CH}'
    return img[y0:y0 + CH, x0:x0 + CW].copy()


# ---------------------------------------------------------------- jatuh
def jatuh_frames(heading):
    """Lima pose jatuh.py (0-3 jatuh, 4 variasi terjerembab), dengan putaran tubuh khusus arah."""
    base = JT.frames(BASE)
    out = []
    for i, F in enumerate(base):
        d = TWIST[heading] * TWIST_SCALE[i]
        G = dict(F)
        G['rider'] = twist_rider(F['rider'], d)
        G['papers'] = twist_papers(F['papers'], d)
        if F['dust']:
            R = rot_c(d)
            G['dust'] = [(_rot_pts(R, c, PIVOT), r) for c, r in F['dust']]
        out.append(G)
    return out


def render_jatuh(heading):
    return [crop_cell(render_frame(F, YAW[heading]), f'jatuh_{heading}[{i}]') for i, F in enumerate(jatuh_frames(heading))]


def jatuh_sheet_row(heading, old_sheet=None):
    """Lima sel jatuh untuk satu arah. Arah normal diambil dari sheet lama (114x68) tanpa render ulang."""
    if heading == 'normal' and old_sheet is not None:
        cells = []
        for i in range(5):
            c = np.zeros((CH, CW, 4), np.uint8)
            c[AY - 51:AY + 17, AX - 57:AX + 57] = old_sheet[:, i * 114:(i + 1) * 114]
            cells.append(c)
        return cells
    return render_jatuh(heading)


# ---------------------------------------------------------------- bangkit
def _limbs(hip, side_ax, knee_ankle_toe):
    return {s: knee_ankle_toe(s) for s in (1, -1)}


def bangkit_poses(heading):
    """b0 bertumpu tangan, b1 berlutut (topi dipungut), b2 berdiri berbalik ke sepeda,
    b3 meraih setang, b4 menegakkan sepeda. b5 = kayuh santai frame 0 (ditempel dari sheet kayuh)."""
    tw = TWIST[heading]
    papers = JT.frames(BASE)[3]['papers']
    lie_bike = dict(pitch=0, roll=-84, move=(1.0, -0.8, 0))
    out = []

    # b0: tangan menumpu tanah, dada terangkat, kaki masih lurus di tanah
    hip = v(32.0, 3.6, 2.6)
    sh = hip + v(8.6, 0, 5.2)
    head = sh + v(3.9, 0, 3.4)
    J = dict(hip=hip, shoulder=sh, head=head, Rh=head_frame(v(1, 0, -0.35), v(0.45, 0, 1)), eye=True,
             cap=(v(52.3, 4.6, 0.1), head_frame(v(1, 0.3, 0), v(0, 0, 1))),
             legs={s: (hip + v(-8.0, s * 2.0, -1.0), hip + v(-15.4, s * 2.4, -0.9), v(-0.3, 0, -1)) for s in (1, -1)},
             arms={s: (sh + v(-0.6, s * 4.6, -3.0), sh + v(0.8, s * 4.8, -6.6)) for s in (1, -1)})
    out.append(dict(bike=bike_pose(**lie_bike)[0], rider=twist_rider(J, tw), papers=twist_papers(papers, tw), dust=[]))

    # b1: berlutut satu kaki, badan tegak, topi di tangan kanan
    hip = v(33.0, 3.6, 9.2)
    sh = hip + v(1.2, 0, 10.0)
    head = sh + v(1.4, 0, 5.3)
    hand_r = sh + v(2.8, 4.4, -8.6)
    J = dict(hip=hip, shoulder=sh, head=head, Rh=head_frame(v(1, 0, -0.15), v(0.1, 0, 1)), eye=True,
             cap=(hand_r + v(0.6, 0.4, 1.6), head_frame(v(0.2, 1, 0), v(0, 0, 1))),
             legs={1: (hip + v(6.6, 2.0, -1.4), hip + v(6.4, 2.4, -8.4), v(1, 0, 0)),
                   -1: (hip + v(1.0, -2.0, -8.0), hip + v(-6.6, -2.4, -7.6), v(-0.3, 0, -1))},
             arms={1: (sh + v(1.8, 4.6, -4.6), hand_r), -1: (sh + v(1.0, -4.4, -4.6), sh + v(4.2, -4.0, -8.0))})
    out.append(dict(bike=bike_pose(**lie_bike)[0], rider=twist_rider(J, tw), papers=twist_papers(papers, tw), dust=[]))

    # b2: berdiri, topi sudah di kepala, berbalik dan melangkah kembali ke sepeda (menghadap -a)
    hip = v(25.0, -1.0, 16.4)
    sh = hip + v(-0.6, 0, 10.0)
    head = sh + v(-0.6, 0, 5.4)
    side = v(0, -1, 0)
    J = dict(hip=hip, shoulder=sh, head=head, side=side, Rh=head_frame(v(-1, 0, -0.1), v(0, 0, 1)), eye=True, cap='head',
             legs={1: (hip + v(-3.0, -1.6, -7.8), hip + v(-4.4, -1.6, -15.4), v(-1, 0, 0)),
                   -1: (hip + v(2.4, 1.6, -7.8), hip + v(4.8, 1.6, -14.6), v(-1, 0, -0.4))},
             arms={1: (sh + v(1.6, -3.8, -4.8), sh + v(2.8, -4.0, -9.4)), -1: (sh + v(-1.6, 3.8, -4.8), sh + v(-3.4, 4.0, -9.0))})
    out.append(dict(bike=bike_pose(**lie_bike)[0], rider=twist_rider(J, tw * 0.5), papers=twist_papers(papers, tw),
                    dust=[], standing=True))

    # b3: membungkuk di sisi kiri sepeda, kedua tangan meraih setang dan sadel; sepeda mulai terangkat
    xf, pt = bike_pose(pitch=0, roll=-52, move=(0.6, -0.5, 0))
    hip = v(8.4, -10.6, 15.6)
    sh = hip + v(4.0, 2.6, 8.0)
    head = sh + v(2.4, 1.4, 4.4)
    grip = pt(v(13.6, -3.3, 18.2))
    seat = pt(v(4.3, 0, 16.7))
    J = dict(hip=hip, shoulder=sh, head=head, Rh=head_frame(v(0.6, 0.5, -0.6), v(0.4, 0.3, 1)), eye=True, cap='head',
             legs={1: (hip + v(1.6, 1.0, -7.8), hip + v(0.8, 1.2, -15.6), v(1, 0.3, 0)),
                   -1: (hip + v(-1.0, -1.0, -7.8), hip + v(-2.4, -1.2, -15.4), v(1, 0, 0))},
             arms={1: (sh + v(-1.6, 4.0, -3.0), seat + v(0, 0, 0.9)), -1: (sh + v(1.6, -1.4, -4.4), grip)})
    out.append(dict(bike=xf, rider=J, papers=papers, dust=[], standing=True))

    # b4: sepeda hampir tegak, pemain berdiri di sisi kiri dengan tangan di setang, siap naik
    xf, pt = bike_pose(pitch=0, roll=-12, move=(0.2, -0.1, 0))
    hip = v(7.6, -6.4, 16.3)
    sh = hip + v(1.2, 1.0, 9.9)
    head = sh + v(1.6, 0, 5.3)
    J = dict(hip=hip, shoulder=sh, head=head, Rh=head_frame(v(1, 0, -0.1), v(0.1, 0, 1)), eye=True, cap='head',
             legs={1: (hip + v(1.4, 1.2, -7.9), hip + v(1.8, 1.4, -15.5), v(1, 0, 0)),
                   -1: (hip + v(-1.2, -1.2, -7.9), hip + v(-1.8, -1.4, -15.4), v(1, 0, 0))},
             arms={s: (sh + v(2.4, s * 3.2 + (1.2 if s < 0 else 0), -4.6), pt(v(13.6, s * 3.3, 18.2))) for s in (1, -1)})
    out.append(dict(bike=xf, rider=J, papers=papers, dust=[], standing=True))
    return out


def kayuh0_cell(kayuh_sheet, heading):
    """Kayuh santai frame 0 (sel 46x58, titik pijak (23, 46)) ditempel di sel bangkit."""
    row = DIRS.index(heading)          # baris 0-4 = santai
    c = np.zeros((CH, CW, 4), np.uint8)
    c[AY - 46:AY + 12, AX - 23:AX + 23] = kayuh_sheet[row * 58:(row + 1) * 58, 0:46]
    return c


def render_bangkit(heading, kayuh_sheet):
    cells = [crop_cell(render_frame(F, YAW[heading]), f'bangkit_{heading}[{i}]') for i, F in enumerate(bangkit_poses(heading))]
    return cells + [kayuh0_cell(kayuh_sheet, heading)]


# ---------------------------------------------------------------- berhenti
KW, KH, KAX, KAY = 46, 58, 23, 46            # sel kayuh
KBIG, KCX, KCY = 150, 75, 108                # kanvas kerja produce.py (titik pijak sama)
BERHENTI_PHI = -160                          # pedal kiri di depan (phi + 180 = 20), siap dikayuh
BERHENTI_ROLL = 7                            # sepeda condong ke kanan, ke kaki yang turun
BERHENTI_FPS = 3


def berhenti_cfg():
    """Kaki kanan turun ke tanah di kanan sepeda (sisi kamera, jadi terlihat di arah default); badan tetap tegak dan
    sedikit bergeser ke kanan ikut sepeda. Revisi 2026-10-22: sebelumnya kaki kiri, tertutup sepeda di arah normal."""
    from loper import DEF_HIP, DEF_SHOULDER, DEF_HEAD
    shift = v(0.4, 1.4, -0.3)
    return dict(BASE, bike_roll=BERHENTI_ROLL,
                hip=tuple(DEF_HIP + shift), shoulder=tuple(DEF_SHOULDER + shift + v(0, 0.3, 0)),
                head=tuple(DEF_HEAD + shift + v(0, 0.3, 0)),
                foot_down=dict(side=1, ankle=(7.6, 7.6, 1.75)),
                arm_ik=True)          # siku dihitung dari bahu ke tangan (tangan ikut sepeda yang condong)


def render_berhenti(heading):
    """Frame 0: kaki turun, frame 1: badan atas turun 1 px (bernapas), digeser kaku seperti rem_meluncur.py."""
    import rem_meluncur as RM
    iso.POSE['yaw'], iso.POSE['lean'] = YAW[heading], 0.0
    M, sh = build(dict(berhenti_cfg(), steer=STEER[heading]), BERHENTI_PHI)
    c = iso.L2W(np.array([8.5, 0.0, 0.0]))
    img = render(M, KBIG, KBIG, KCX - (c[0] - c[1]), KCY - (c[0] + c[1]) / 2, shadow_pts=sh)
    iso.POSE['yaw'] = iso.POSE['lean'] = 0.0
    a = img[..., 3] > 0
    y0, x0 = KCY - KAY, KCX - KAX
    inside = np.zeros_like(a); inside[y0:y0 + KH, x0:x0 + KW] = True
    assert not (a & ~inside).any(), f'berhenti_{heading}: keluar dari sel 46x58'
    f0 = img[y0:y0 + KH, x0:x0 + KW].copy()
    f1 = np.array(RM.shifted(Image.fromarray(f0, 'RGBA'), heading, 0, 1))
    return [f0, f1]


# ---------------------------------------------------------------- ekspor
FPS = {'jatuh': 10, 'terjerembab': 3, 'bangkit': 10, 'berhenti': BERHENTI_FPS}


def _sheet(rows, cw, ch):
    sh = Image.new('RGBA', (cw * max(len(r) for r in rows), ch * len(rows)), (0, 0, 0, 0))
    for j, r in enumerate(rows):
        for i, c in enumerate(r):
            sh.alpha_composite(Image.fromarray(c, 'RGBA'), (i * cw, j * ch))
    return sh


def _tres(name, anims, res_dir, prefix):
    subs, txt, sid = [], [], 0
    for A in anims:
        fr = []
        for (x, y, w, h) in A['regions']:
            sid += 1
            subs.append(f'[sub_resource type="AtlasTexture" id="AtlasTexture_{prefix}{sid}"]\natlas = ExtResource("1_sheet")\n'
                        f'region = Rect2({x}, {y}, {w}, {h})\n')
            fr.append('{\n"duration": 1.0,\n"texture": SubResource("AtlasTexture_%s%d")\n}' % (prefix, sid))
        txt.append('{\n"frames": [' + ', '.join(fr) + '],\n"loop": %s,\n"name": &"%s",\n"speed": %.1f\n}'
                   % ('true' if A['loop'] else 'false', A['name'], A['fps']))
    return (f'[gd_resource type="SpriteFrames" load_steps={sid + 2} format=3]\n\n'
            f'[ext_resource type="Texture2D" path="{res_dir}/{name}.png" id="1_sheet"]\n\n'
            + '\n'.join(subs) + '\n[resource]\nanimations = [' + ', '.join(txt) + ']\n')


def _write(out, name, sheet, cell, anchor, anims, note, res_dir, prefix):
    sheet.save(f'{out}/{name}.png')
    meta = dict(sprite=f'{name}.png', cell=list(cell), columns=sheet.width // cell[0], rows=sheet.height // cell[1],
                ground_anchor=list(anchor), godot_offset=[cell[0] / 2 - anchor[0], cell[1] / 2 - anchor[1]],
                status='usulan Fase 5C', note=note, animations=anims)
    json.dump(meta, open(f'{out}/{name}.json', 'w'), indent=1, ensure_ascii=False)
    open(f'{out}/{name}_frames.tres', 'w').write(_tres(name, anims, res_dir, prefix))


def main():
    ap = argparse.ArgumentParser(description='Render animasi pemain Fase 5C (usulan).')
    ap.add_argument('--out', default='build/loper_art/fase5c')
    ap.add_argument('--kayuh', default='assets/sprites/loper/loper_agen.png', help='sheet kayuh (untuk frame akhir bangkit)')
    ap.add_argument('--jatuh-lama', default='assets/sprites/loper/loper_agen_jatuh.png',
                    help='sheet jatuh arah normal 114x68 (dipotong ulang ke sel baru, tidak dirender ulang)')
    ap.add_argument('--res-dir', default='res://assets/sprites/loper')
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    kay = np.array(Image.open(a.kayuh).convert('RGBA'))
    oldj = np.array(Image.open(a.jatuh_lama).convert('RGBA'))

    # jatuh + terjerembab: baris = arah, kolom 0-3 jatuh, 4 variasi terjerembab
    rows, anims = [], []
    for r, h in enumerate(DIRS):
        rows.append(jatuh_sheet_row(h, oldj))
        reg = lambda fs: [[f * CW, r * CH, CW, CH] for f in fs]
        anims.append(dict(name=f'jatuh_{h}', heading=h, row=r, fps=FPS['jatuh'], loop=False, frames=[0, 1, 2, 3], regions=reg([0, 1, 2, 3])))
        anims.append(dict(name=f'terjerembab_{h}', heading=h, row=r, fps=FPS['terjerembab'], loop=True, frames=[3, 4], regions=reg([3, 4])))
    _write(a.out, 'loper_agen_jatuh', _sheet(rows, CW, CH), (CW, CH), (AX, AY), anims,
           'Titik pijak = posisi sepeda saat menabrak. Sel 140x88 untuk kelima arah (arah normal = sheet 114x68 lama, '
           'piksel sama, dipotong ulang). Offset sama dengan sheet kayuh (0, -17). serong_kiri: tubuh diputar 30 derajat '
           'di tanah supaya tengkurapnya terbaca.', a.res_dir, 'j')

    # bangkit: 6 frame, frame 5 = kayuh santai frame 0
    rows, anims = [], []
    for r, h in enumerate(DIRS):
        rows.append(render_bangkit(h, kay))
        anims.append(dict(name=f'bangkit_{h}', heading=h, row=r, fps=FPS['bangkit'], loop=False, frames=list(range(6)),
                          regions=[[f * CW, r * CH, CW, CH] for f in range(6)]))
    _write(a.out, 'loper_agen_bangkit', _sheet(rows, CW, CH), (CW, CH), (AX, AY), anims,
           'Dari terjerembab: bertumpu tangan, berlutut (topi dipungut), berdiri dan kembali ke sepeda, meraih setang, '
           'menegakkan sepeda, lalu kayuh santai frame 0 (piksel sama dengan sheet kayuh). 0,6 detik. Koran yang '
           'berserakan hilang di frame terakhir. Lanjut ke santai_<arah> tanpa geser titik pijak.', a.res_dir, 'b')

    # berhenti: 2 frame, sel kayuh
    rows, anims = [], []
    for r, h in enumerate(DIRS):
        rows.append(render_berhenti(h))
        anims.append(dict(name=f'berhenti_{h}', heading=h, row=r, fps=FPS['berhenti'], loop=True, frames=[0, 1],
                          regions=[[f * KW, r * KH, KW, KH] for f in range(2)]))
    _write(a.out, 'loper_agen_berhenti', _sheet(rows, KW, KH), (KW, KH), (KAX, KAY), anims,
           'Kaki kanan turun ke tanah (sisi kamera), sepeda condong 7 derajat ke kanan, pedal kiri di depan. Frame 1: badan atas turun '
           '1 px (bernapas), digeser kaku seperti rem_meluncur.py.', a.res_dir, 's')
    print('fase5c ->', a.out)


if __name__ == '__main__':
    main()
