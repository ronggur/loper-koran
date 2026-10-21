#!/usr/bin/env python3
"""QA iterasi 2 (run 5B), verifikasi independen QA-001/P-6/P-7: tidak boleh ada piksel OPAK dekor di atas piksel pemain (alfa objek 1,0) tanpa kotak penutup menutupinya.
Bukan bagian CI. Jalankan dari root repo: python3 docs/loop/20261021-fase5b-tembok-dekor/qa_iter2_piksel.py (butuh numpy, pillow).

Ditulis ulang dari nol, TIDAK memakai kode produksi atau tes Dev:
- proyeksi iso 2:1 sendiri (x layar = (lateral + maju) * 32, y layar = (lateral - maju) * 16);
- kotak penutup: tinggi dan setengah tapak DIBACA dari scripts/config.gd (teks) lalu dihitung sendiri dengan rumus "ada d >= 0 sehingga (lateral + d, maju - d) di tapak dan d <= tinggi",
  titik kaki pemain; hanya dekor sisi dekat yang punya kotak;
- pemain = gabungan semua frame kelima sheet berkendara (pemain tidak pernah flip_h; CERMIN=1 menambah cermin), piksel alfa >= ALFA_PEMAIN (bawaan 128);
- dekor = piksel opak (alfa >= 250) dari PNG props, digambar sesudah pemain bila y layar pijaknya >= y layar pemain (kasus terburuk untuk seri).
Keluaran: per dekor, jumlah posisi (lateral -2..2 langkah 1/16, maju relatif -7..7 langkah 1/32) yang tertimpa opak tanpa kotak menutupi, dan piksel maksimum."""
import json, re, sys, math, os
CERMIN = os.environ.get('CERMIN', '0') == '1'
ALFA_PEMAIN = int(os.environ.get('ALFA_PEMAIN', '128'))
import numpy as np
from PIL import Image

CFG = open('scripts/config.gd').read()

def konstanta(nama):
    m = re.search(r'^const %s[^=]*=\s*(.+)$' % nama, CFG, re.M)
    return json.loads(m.group(1).strip())

TINGGI = konstanta('RUTE_DEKOR_TINGGI_PENUTUP_UBIN')
SETENGAH = konstanta('RUTE_DEKOR_SETENGAH_PENUTUP_UBIN')
LAT_DEKAT = konstanta('RUTE_DEKOR_LATERAL_UBIN')       # tong, pohon, lampu
LAT_SEB = konstanta('RUTE_DEKOR_LATERAL_SEBERANG_UBIN')
SPR = ['prop_tong_sampah_logam', 'prop_pohon_rindang', 'prop_pohon_glodokan', 'prop_pohon_ketapang', 'prop_lampu_lengan_seberang', 'prop_lampu_lengan_dekat']

def bulat(v):
    # Godot Vector2.round(): setengah dibulatkan menjauhi nol
    return int(math.copysign(math.floor(abs(v) + 0.5), v))

def px(lat, maju):
    return (bulat((lat + maju) * 32), bulat((lat - maju) * 16))

def muat_dekor(nama):
    im = np.array(Image.open(f'assets/sprites/props/{nama}.png').convert('RGBA'))
    a = json.load(open(f'assets/sprites/props/{nama}.json'))['ground_anchor']
    return im[:, :, 3] >= 250, tuple(a)

def muat_sheet(png, js, cermin):
    im = np.array(Image.open(png).convert('RGBA'))[:, :, 3] >= ALFA_PEMAIN
    j = json.load(open(js))
    cw, ch = j['cell']; ax, ay = j['ground_anchor']
    H, W = 400, 400
    out = np.zeros((H, W), bool)
    for r in range(im.shape[0] // ch):
        for c in range(im.shape[1] // cw):
            cel = im[r*ch:(r+1)*ch, c*cw:(c+1)*cw]
            for cc in ([cel, cel[:, ::-1]] if cermin else [cel]):
                out[200-ay:200-ay+ch, 200-ax:200-ax+cw] |= cc
    return out

PEMAIN = np.zeros((400, 400), bool)
for n in ['loper_agen', 'loper_agen_melambat', 'loper_agen_meluncur', 'loper_agen_rem', 'loper_agen_lempar']:
    PEMAIN |= muat_sheet(f'assets/sprites/loper/{n}.png', f'assets/sprites/loper/{n}.json', CERMIN)
ys, xs = np.nonzero(PEMAIN)
PBOX = (xs.min()-200, xs.max()-200, ys.min()-200, ys.max()-200)  # relatif pijak

def tertutup(lat, maju, ldk, mdk, tinggi, setengah):
    # titik kaki pemain di (lat, maju); kotak tapak persegi pusat (ldk, mdk) setengah `setengah`, tinggi `tinggi`
    if tinggi <= 0: return False
    x0, x1 = ldk - setengah, ldk + setengah
    m0, m1 = mdk - setengah, mdk + setengah
    # (lat + d) dalam (x0, x1) dan (maju - d) dalam (m0, m1) dan d < tinggi, d >= 0 ; irisan terbuka
    bawah = max(0.0, x0 - lat, maju - m1)
    atas = min(tinggi, x1 - lat, maju - m0)
    return bawah < atas

def tumpang(mask, anchor, ld, md, lat, maju):
    dx, dy = px(ld, md)
    ex, ey = px(lat, maju)
    # origin sprite dekor di layar = (dx - ax, dy - ay); pemain = (ex-200 + ..)
    H, W = mask.shape
    ox, oy = dx - anchor[0], dy - anchor[1]
    # jendela pemain di layar
    px0, py0 = ex - 200, ey - 200
    x0 = max(ox, px0); x1 = min(ox + W, px0 + 400)
    y0 = max(oy, py0); y1 = min(oy + H, py0 + 400)
    if x0 >= x1 or y0 >= y1: return 0
    a = mask[y0-oy:y1-oy, x0-ox:x1-ox]
    b = PEMAIN[y0-py0:y1-py0, x0-px0:x1-px0]
    return int((a & b).sum())

total_gagal = 0
for idx, nama in enumerate(SPR):
    mask, anchor = muat_dekor(nama)
    # sisi: tong dan pohon dua sisi; lampu seberang hanya seberang, lampu dekat hanya dekat
    kombinasi = []
    if 'tong' in nama or 'pohon' in nama:
        jenis_idx = 0 if 'tong' in nama else 1
        kombinasi = [('dekat', LAT_DEKAT[jenis_idx]), ('seberang', -LAT_SEB[jenis_idx])]
    elif 'seberang' in nama:
        kombinasi = [('seberang', -LAT_SEB[2])]
    else:
        kombinasi = [('dekat', LAT_DEKAT[2])]
    for sisi, ld in kombinasi:
        md = 20.0
        tinggi = TINGGI[idx] if sisi == 'dekat' else 0.0
        setengah = SETENGAH[idx] if sisi == 'dekat' else 0.0
        n_tumpang = 0; n_tak = 0; maks = 0; contoh = None; n_diper = 0
        yd = (ld - md) * 16
        for il in range(-32, 33):
            lat = il / 16.0
            for km in range(-7*32, 7*32 + 1):
                maju = md + km / 32.0
                n_diper += 1
                if yd < (lat - maju) * 16 - 1e-9: continue   # dekor digambar sebelum pemain
                n = tumpang(mask, anchor, ld, md, lat, maju)
                if n <= 0: continue
                n_tumpang += 1
                if not tertutup(lat, maju, ld, md, tinggi, setengah):
                    n_tak += 1
                    if n > maks: maks, contoh = n, (lat, round(maju - md, 3))
        status = 'OK' if n_tak == 0 else 'GAGAL'
        total_gagal += n_tak > 0
        print(f'{nama:32s} {sisi:8s} lat {ld:+.3f}  diperiksa {n_diper}  tumpang-piksel {n_tumpang}  tanpa-kotak {n_tak}  piksel-maks {maks} {contoh or ""}  {status}')
print('RINGKAS: GAGAL' if total_gagal else 'RINGKAS: OK (tidak ada piksel opak dekor di atas pemain tanpa kotak menutupi)')
sys.exit(1 if total_gagal else 0)
