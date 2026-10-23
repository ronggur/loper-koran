"""Latar layar bengkel (usulan 2026-10-23): ilustrasi AI jadi pixel art 640x360 dan 800x360.

Cara sama dengan tools/loper_art/fullbody/konversi2.py (ART_DIRECTION 3.5, gambar skala besar):

  1. konversi   sumber diskalakan ke kelipatan bulat 640x360 (sel 3x3), palet k-means 30 warna di ruang Lab,
                warna yang dekat dengan palet induk (jarak Lab < 7) ditarik ke palet induk, tiap sel mengambil
                warna terbanyak, piksel lepas dirapikan
  2. rapikan    tekstur berisik: piksel diganti mayoritas 3x3 bila mayoritas >= 5 dan nadanya dekat (beda L < 18),
                empat kali; detail berkontras (lubang papan, garis) tetap
  3. cahaya     cahaya lampu di dinding jadi cincin konsentris bertingkat (ART_DIRECTION 2.3: glow = cincin piksel,
                bukan gradien) dengan tepi papan catur 1 px; hanya piksel berwarna dinding yang diubah
  4. tanaman    tanaman di meja kerja, ambang jendela, dan atas peti dihapus (permintaan pemilik 2026-10-23):
                inpaint lalu ditarik ke palet, bagian berstruktur (kaca, kusen, ambang, tutup peti) disalin dari sekitarnya
  5. lebar 800  80 px kiri dan kanan diisi pantulan tepi adegan (viewport game melebar sampai 800, ART_DIRECTION 7)

Koordinat di langkah 3 dan 4 khusus untuk gambar sumber ini (docs/design/redesain/latar_bengkel/sumber_ai.jpg).
k-means dan inpaint memakai pustaka numerik, jadi hasil bisa berbeda beberapa piksel antar-mesin; berkas di docs/
adalah keluaran resmi (dibuat 2026-10-23), uji hanya memeriksa sifatnya (tools/tests_cek/uji_ui_redesain.py).

Butuh numpy, pillow, opencv-python, scikit-learn.

  python3 tools/ui_art/redesain/latar_bengkel.py                       # tulis ke build/ui_art/redesain/latar_bengkel/
  python3 tools/ui_art/redesain/latar_bengkel.py --mock                # juga ke docs/design/redesain/latar_bengkel/
  python3 tools/ui_art/redesain/latar_bengkel.py --salin               # HANYA menyalin keluaran resmi di docs/ (latar 800) ke assets/sprites/ui/; tidak membuat ulang, tanpa opencv dan scikit-learn
`UI_ART_SALIN_KE` mengganti folder tujuan `--salin` (bawaan assets/sprites/ui/; dipakai uji).
"""
import argparse
import os
import shutil
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(Path(__file__).resolve().parent))
import pasang

SALIN_KE = Path(os.environ.get('UI_ART_SALIN_KE', ROOT / 'assets' / 'sprites' / 'ui'))
# opencv dan scikit-learn hanya dibutuhkan untuk membuat ulang latar; dimuat di main() supaya `--salin` tidak membutuhkannya
cv2 = None
KMeans = None
SUMBER = ROOT / 'docs' / 'design' / 'redesain' / 'latar_bengkel' / 'sumber_ai.jpg'
DOCS = ROOT / 'docs' / 'design' / 'redesain' / 'latar_bengkel'
W, H = 640, 360

INDUK = ['#0E0A1C', '#FBF6E8', '#F2E7C9', '#C2AF86', '#B47C5F', '#96643C', '#553428', '#C4C0C8', '#969AA0',
         '#67636D', '#5F5B66', '#3D4649', '#221E26', '#FFE08A', '#FFC94A', '#E98E3F', '#B5523B', '#994532',
         '#673F31', '#7E3929', '#6FAE4F', '#466E50', '#314D38', '#9BC4D8', '#5F96C8', '#466E8C', '#8A5A40',
         '#6D4334', '#4A2319', '#1C130F', '#2A1E17', '#36281E']

# langkah 3: pusat bola lampu, batas lambrisan, jari-jari cincin dari dalam ke luar
LAMPU = (320, 47)
Y_LAMBRISAN = 194
CINCIN_R = [24, 36, 52, 74, 104]
CINCIN_LUAR = 130
CONTOH_DINDING = (260, 60, 400, 190)        # x0, y0, x1, y1 dinding polos untuk mengenali warna dinding

# langkah 4: kotak tanaman (x0, y0, x1, y1)
TANAMAN = {'kiri': (0, 144, 37, 211), 'ambang': (492, 158, 539, 198), 'kanan': (598, 165, 640, 225)}


def hex2rgb(h):
    h = h.lstrip('#')
    return [int(h[i:i + 2], 16) for i in (0, 2, 4)]


def lab(a):
    a = np.asarray(a)
    return cv2.cvtColor(a.reshape(-1, 1, 3).astype(np.uint8), cv2.COLOR_RGB2LAB).reshape(a.shape[:-1] + (3,)).astype(np.float32)


def snap_ke(pal, a):
    d = ((lab(a)[..., None, :] - lab(pal)[None, None, :, :]) ** 2).sum(-1)
    return pal[d.argmin(-1)]


def konversi(sumber, k=30, jarak_induk=7.0):
    im = Image.open(sumber).convert('RGB')
    sel = max(3, round(im.width / W))
    if im.size != (W * sel, H * sel):
        im = im.resize((W * sel, H * sel), Image.LANCZOS)
    src = cv2.bilateralFilter(np.asarray(im), 7, 30, 7)
    kecil = cv2.resize(src, (W, H), interpolation=cv2.INTER_AREA)
    km = KMeans(n_clusters=k, n_init=4, random_state=7).fit(lab(kecil.reshape(-1, 3))[::3])
    pal_lab = km.cluster_centers_
    induk = np.array([hex2rgb(h) for h in INDUK])
    induk_lab = lab(induk)
    pal = cv2.cvtColor(np.clip(pal_lab, 0, 255).astype(np.uint8).reshape(-1, 1, 3), cv2.COLOR_LAB2RGB).reshape(-1, 3)
    for i in range(len(pal_lab)):
        d = np.linalg.norm(induk_lab - pal_lab[i], axis=1)
        if d.min() < jarak_induk:
            pal[i] = induk[int(d.argmin())]
    lab_src = lab(src.reshape(-1, 3))
    idx = np.empty(len(lab_src), dtype=np.int32)
    for s in range(0, len(lab_src), 400000):
        blk = lab_src[s:s + 400000]
        idx[s:s + 400000] = np.argmin(((blk[:, None, :] - pal_lab[None, :, :]) ** 2).sum(-1), axis=1)
    idx = idx.reshape(H, sel, W, sel).transpose(0, 2, 1, 3).reshape(H, W, sel * sel)
    hitung = np.zeros((H, W, k), dtype=np.int32)
    for c in range(sel * sel):
        np.add.at(hitung, (np.arange(H)[:, None], np.arange(W)[None, :], idx[:, :, c]), 1)
    grid = hitung.argmax(-1)
    for _ in range(2):  # piksel lepas
        g = grid.copy()
        up, dn, lf, rt = np.roll(grid, 1, 0), np.roll(grid, -1, 0), np.roll(grid, 1, 1), np.roll(grid, -1, 1)
        for a1, a2, a3 in ((up, dn, lf), (up, dn, rt), (up, lf, rt), (dn, lf, rt)):
            m = (a1 == a2) & (a2 == a3) & (grid != a1)
            g[m] = a1[m]
        grid = g
    return pal[grid].astype(np.uint8)


def rapikan(img, lolos=4):
    for _ in range(lolos):
        L = lab(img)[..., 0]
        out = img.copy()
        key = (img[..., 0].astype(np.int32) << 16) | (img[..., 1].astype(np.int32) << 8) | img[..., 2]
        pad = np.pad(key, 1, mode='edge')
        nb = np.stack([pad[1 + dy:1 + dy + H, 1 + dx:1 + dx + W] for dy in (-1, 0, 1) for dx in (-1, 0, 1)], -1)
        for y in range(H):
            for x in range(W):
                vals, cnt = np.unique(nb[y, x], return_counts=True)
                j = cnt.argmax()
                if cnt[j] >= 5 and vals[j] != key[y, x]:
                    c = np.array([(vals[j] >> 16) & 255, (vals[j] >> 8) & 255, vals[j] & 255])
                    if abs(lab(c.reshape(1, 3))[0, 0] - L[y, x]) < 18:
                        out[y, x] = c
        img = out
    return img


def cahaya(img):
    """Warna dinding = enam warna terbanyak di contoh dinding polos, diurutkan dari gelap ke terang. Cincin dari
    dalam memakai lima warna dinding paling terang (makin ke luar makin gelap); di luar cincin sampai jari-jari
    CINCIN_LUAR = warna dinding tergelap."""
    x0, y0, x1, y1 = CONTOH_DINDING
    contoh = img[y0:y1, x0:x1].reshape(-1, 3)
    warna, jumlah = np.unique(contoh, axis=0, return_counts=True)
    urut = np.argsort(-jumlah, kind='stable')[:len(CINCIN_R) + 1]
    dinding = [tuple(int(v) for v in warna[i]) for i in urut]
    dinding.sort(key=lambda c: float(lab(np.array([c]))[0, 0]))
    dasar = dinding[0]
    cincin = list(zip(CINCIN_R, reversed(dinding[1:])))
    dset = set(dinding)
    cx, cy = LAMPU
    for y in range(Y_LAMBRISAN):
        for x in range(W):
            if tuple(int(v) for v in img[y, x]) not in dset:
                continue
            r = ((x - cx) ** 2 + (y - cy) ** 2) ** .5
            if r >= CINCIN_LUAR:
                continue
            w = dasar
            for i, (batas, c) in enumerate(cincin):
                if r < batas:
                    if r > batas - 2 and (x + y) % 2 == 0:
                        w = cincin[i + 1][1] if i + 1 < len(cincin) else dasar
                    else:
                        w = c
                    break
            img[y, x] = w
    return img


def hapus_tanaman(img):
    asli = img.copy()
    pal = np.unique(img.reshape(-1, 3), axis=0)
    mask = np.zeros((H, W), np.uint8)
    for (x0, y0, x1, y1) in TANAMAN.values():
        mask[y0:y1, x0:x1] = 255
    inp = cv2.inpaint(img, mask, 5, cv2.INPAINT_TELEA)
    for (x0, y0, x1, y1) in TANAMAN.values():
        img[y0:y1, x0:x1] = snap_ke(pal, inp[y0:y1, x0:x1])
    img[158:186, 503:539] = img[158:186, 567:603]      # kaca kiri bawah dari kaca kanan, baris sama
    img[158:186, 492:503] = img[150, 492:503]          # kusen kiri diteruskan ke bawah
    img[184:198, 492:539] = asli[184:198, 542:589]     # ambang jendela dari bagian yang bersih
    img[165:186, 598:640] = img[160, 598:640]          # kanan: kaca, kusen, dinding dari baris 160
    img[186:198, 598:626] = asli[186:198, 548:576]     # ambang kanan
    img[186:198, 626:640] = img[160, 626:640]
    img[198:225, 598:640] = img[198:225, 590:591]      # dinding dan tutup peti dari kolom 590
    img[144:211, 0:9] = img[144:211, 40:41]            # sisa daun di tepi kiri
    return img


def lebar_800(img):
    ext = np.zeros((H, 800, 3), np.uint8)
    ext[:, 80:720] = img
    ext[:, :80] = img[:, 79::-1]
    ext[:, 720:] = img[:, :W - 81:-1]
    return ext


def main():
    ap = argparse.ArgumentParser(description='Latar bengkel (usulan)')
    ap.add_argument('--sumber', default=str(SUMBER))
    ap.add_argument('--out', default=str(ROOT / 'build' / 'ui_art' / 'redesain' / 'latar_bengkel'))
    ap.add_argument('--mock', action='store_true', help='juga tulis ke docs/design/redesain/latar_bengkel/')
    ap.add_argument('--salin', action='store_true', help='HANYA salin keluaran resmi di docs/ ke assets/sprites/ui/ (tidak membuat ulang)')
    a = ap.parse_args()
    if a.salin:
        SALIN_KE.mkdir(parents=True, exist_ok=True)
        for sumber, tujuan in pasang.LATAR.items():
            shutil.copyfile(ROOT / pasang.FOLDER_LATAR / sumber, SALIN_KE / tujuan)
        print('disalin', len(pasang.LATAR), 'berkas ->', SALIN_KE)
        return
    global cv2, KMeans
    import cv2 as _cv2
    from sklearn.cluster import KMeans as _KMeans
    cv2, KMeans = _cv2, _KMeans
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    img = konversi(a.sumber)
    img = rapikan(img)
    img = cahaya(img)
    img = hapus_tanaman(img)
    hasil = {'bengkel_latar_640.png': img, 'bengkel_latar_800.png': lebar_800(img)}
    for nama, arr in hasil.items():
        Image.fromarray(arr).save(out / nama)
    besar = Image.fromarray(hasil['bengkel_latar_800.png'])
    besar.resize((2400, 1080), Image.NEAREST).save(out / 'bengkel_latar_800_x3.png')
    if a.mock:
        for n in ('bengkel_latar_640.png', 'bengkel_latar_800.png', 'bengkel_latar_800_x3.png'):
            shutil.copyfile(out / n, DOCS / n)
    print('warna', len(np.unique(img.reshape(-1, 3), axis=0)), '->', out, '(+ docs)' if a.mock else '')


if __name__ == '__main__':
    main()
