"""Sepeda loper dari gambar full body (usulan 2026-10-23, permintaan pemilik): tokohnya dibuang, sepedanya disisakan.

Sumber: docs/design/character/loper_agen/loper_agen_fullbody.png (240x292, hasil konversi2, ART_DIRECTION 3.5),
sama dengan papan "Gambar AI baru jadi pixel art · versi 5" di kanvas "Karakter Loper Koran".

Langkah:
  1. tokoh dibuang: semua di atas y 108 (kepala, lengan, koran), warna kulit/kemeja/celana di kolom badan beserta
     garis luarnya yang gelap, sepatu, gantungan kunci, dan bayangan tanah lama
  2. bagian sepeda yang tadinya tertutup tokoh digambar ulang HANYA di piksel yang dibuang (piksel asli tidak diubah):
     sisi kanan roda belakang (profil radial dari bagian roda yang terlihat, jari-jari tiap 30 derajat), batang
     bawah (chainstay), seat stay, seat tube, dua pipa rangka step-through yang menerus dari potongan di kanan,
     tiang dan sadel, gir depan, engkol dan pedal dua sisi; lalu garis luar #1B1226 di tepi bagian baru
  3. sisa piksel lepas dibuang, bayangan tanah baru (#2E3550 alpha 96, seperti gambar full body) di bawah roda
  4. dipotong ke kotak sepeda -> sepeda_besar.png (kepadatan gambar skala besar), lalu versi setengah
     sepeda_kecil.png (mode per blok 2x2, garis luar dirapikan) untuk panggung bengkel

Koordinat khusus untuk gambar sumber ini. Deterministik (numpy dan pillow saja).

  python3 tools/ui_art/redesain/sepeda_fullbody.py            # ke build/ui_art/redesain/
  python3 tools/ui_art/redesain/sepeda_fullbody.py --mock     # juga ke docs/design/redesain/aset/
"""
import argparse
import json
import math
import shutil
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[3]
SUMBER = ROOT / 'docs' / 'design' / 'character' / 'loper_agen' / 'loper_agen_fullbody.png'
MOCK = ROOT / 'docs' / 'design' / 'redesain' / 'aset'

GARIS = (27, 18, 38)
HIJAU = [(89, 155, 95), (61, 127, 80), (46, 99, 70)]
HIJAU_GELAP = (32, 75, 64)
LOGAM = [(201, 192, 198), (142, 130, 144), (92, 82, 98)]
JARI = [(189, 179, 187), (125, 114, 128)]
BAN = [(61, 47, 64), (43, 33, 51)]
BAYANGAN = (46, 53, 80, 96)

KULIT = [(239, 164, 98), (220, 118, 69), (199, 103, 61), (218, 114, 68), (240, 165, 99), (194, 81, 56), (194, 85, 56)]
KEMEJA = [(132, 166, 186), (110, 138, 170), (101, 121, 158), (127, 158, 182), (109, 134, 167)]
CELANA = [(44, 48, 79), (58, 66, 94), (84, 96, 142), (36, 34, 61), (35, 34, 63), (51, 57, 89), (83, 95, 141), (87, 99, 144)]

RODA_BELAKANG = (46, 219, 41.5, 44)      # cx, cy, rx, ry (roda tampak sedikit lonjong)
JARI_SUDUT = [10 + 30 * i for i in range(12)]
BB = (110, 232)                          # poros gir depan
DUDUKAN = (86, 158)                      # pertemuan seat tube dan seat stay di bawah sadel
# titik penanda kondisi di gambar sumber: ban belakang kiri bawah, tuas rem di setang, kotak rantai
TITIK = {'ban': (13, 248), 'rem': (152, 121), 'rantai': (70, 216)}


def buang_tokoh(im):
    H, W = im.shape[:2]
    warna = {tuple(c) for c in KULIT + KEMEJA + CELANA}
    tokoh = np.zeros((H, W), bool)
    for y in range(108, H):
        for x in range(60, 170):
            if im[y, x, 3] == 255 and tuple(int(v) for v in im[y, x, :3]) in warna:
                tokoh[y, x] = True
    m = tokoh.copy()
    m[:108] = True
    badan = np.zeros((H, W), bool)
    badan[108:, 60:170] = True
    terang = im[..., :3].astype(int).mean(-1)
    for _ in range(2):  # garis luar tokoh (piksel gelap yang menempel)
        pad = np.pad(m, 1)
        tetangga = np.zeros_like(m)
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                tetangga |= pad[1 + dy:1 + dy + H, 1 + dx:1 + dx + W]
        m |= tetangga & (terang < 70) & badan
    m[253:, 70:100] = True                          # sepatu kiri
    m[251:, 117:165] = True                         # sepatu kanan
    m[150:190, 114:127] |= im[150:190, 114:127, 3] > 0   # gantungan kunci
    m |= (im[..., 3] > 0) & (im[..., 3] < 255)      # bayangan tanah lama
    out = im.copy()
    out[m] = 0
    return out, m


class Kuas:
    """Menggambar hanya di piksel lubang (bekas tokoh) yang masih kosong atau sudah digambar ulang."""

    def __init__(s, img, lubang):
        s.img, s.lubang = img, lubang
        s.baru = np.zeros(lubang.shape, bool)
        s.padat = np.zeros(lubang.shape, bool)
        s.H, s.W = lubang.shape

    def titik(s, x, y, c, padat=True):
        if 0 <= x < s.W and 0 <= y < s.H and s.lubang[y, x]:
            s.img[y, x] = (*c, 255)
            s.baru[y, x] = True
            if padat:
                s.padat[y, x] = True

    def masker(s, gambar):
        ss = 6
        m = Image.new('L', (s.W * ss, s.H * ss), 0)
        gambar(ImageDraw.Draw(m), ss)
        m = np.asarray(m.resize((s.W, s.H), Image.BOX)) >= 128
        return {(int(x), int(y)) for y, x in zip(*np.nonzero(m))}

    def pipa(s, p0, p1, tebal, nada=HIJAU):
        """Pipa: sisi atas terang, sisi bawah gelap (cahaya kiri atas seperti gambar sumber)."""
        m = s.masker(lambda d, ss: d.line([(p0[0] * ss, p0[1] * ss), (p1[0] * ss, p1[1] * ss)], fill=255, width=int(tebal * ss)))
        for (x, y) in m:
            if (x, y - 1) not in m or (x - 1, y) not in m:
                c = nada[0]
            elif (x, y + 1) not in m or (x + 1, y) not in m:
                c = nada[2]
            else:
                c = nada[1]
            s.titik(x, y, c)

    def garis_luar(s):
        H, W = s.H, s.W
        padat = s.padat
        for y in range(H):
            for x in range(W):
                if s.lubang[y, x] and s.img[y, x, 3] == 0:
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        xx, yy = x + dx, y + dy
                        if 0 <= xx < W and 0 <= yy < H and padat[yy, xx]:
                            s.img[y, x] = (*GARIS, 255)
                            s.baru[y, x] = True
                            break


def roda_belakang(k):
    cx, cy, rx, ry = RODA_BELAKANG
    profil = [(0.80, None), (0.82, LOGAM[2]), (0.89, LOGAM[1]), (0.91, GARIS), (0.99, BAN[1]), (1.03, BAN[0]), (1.06, GARIS)]
    for y in range(k.H):
        for x in range(k.W):
            r = math.hypot((x - cx) / rx, (y - cy) / ry)
            for batas, c in profil:
                if r < batas:
                    if c is not None:
                        k.titik(x, y, c)
                    break
    for a in JARI_SUDUT:
        t = math.radians(a)
        for i in range(10, 81):
            r = i / 100
            x = cx + r * rx * math.cos(t)
            y = cy + r * ry * math.sin(t)
            k.titik(int(round(x)), int(round(y)), JARI[0], padat=False)
            k.titik(int(round(x)), int(round(y)) + 1, JARI[1], padat=False)


def rangka(k):
    k.pipa((47, 216), DUDUKAN, 3)                   # seat stay
    k.pipa((80, 214), (BB[0] - 2, BB[1] - 3), 4)    # chainstay menerus ke gir depan
    k.pipa(BB, DUDUKAN, 5)                          # seat tube
    k.pipa((140, 171), (105, 213), 5)               # pipa step-through atas (lanjutan potongan di kanan)
    k.pipa((140, 185), (108, 224), 5)               # pipa step-through bawah
    k.pipa((86, 158), (82, 146), 2, LOGAM)          # tiang sadel


def sadel(k, asli):
    """Bagian tengah sadel: tiap baris diisi warna kolom kiri sadel yang masih terlihat (x 70)."""
    for y in range(136, 147):
        c = asli[y, 70]
        if c[3] == 0:
            continue
        for x in range(72, 89):
            k.titik(x, y, tuple(int(v) for v in c[:3]))


def gir_dan_engkol(k):
    bx, by = BB
    m = k.masker(lambda d, ss: d.ellipse([(bx - 7.5) * ss, (by - 7.5) * ss, (bx + 7.5) * ss, (by + 7.5) * ss], fill=255))
    for (x, y) in m:
        r = math.hypot(x - bx, y - by)
        c = LOGAM[0] if (r > 5.5 and x + y < bx + by) else (LOGAM[2] if r > 5.5 else LOGAM[1])
        if r < 2:
            c = LOGAM[2]
        k.titik(x, y, c)
    k.pipa((bx, by), (bx - 9, by + 14), 3, [LOGAM[2], LOGAM[2], GARIS])    # engkol sisi seberang (gelap, turun)
    k.pipa((bx - 13, by + 15), (bx - 5, by + 15), 3, [BAN[0], BAN[1], GARIS])
    k.pipa((bx, by), (bx + 10, by - 14), 3, LOGAM)                        # engkol sisi dekat (naik)
    k.pipa((bx + 6, by - 16), (bx + 15, by - 16), 3, [BAN[0], BAN[1], GARIS])


def rapikan_lepas(img, min_px=60):
    """Komponen kecil yang terpisah dari sepeda (sisa kerah, lencana, titik) dibuang."""
    H, W = img.shape[:2]
    isi = img[..., 3] > 0
    label = np.zeros((H, W), int)
    n = 0
    ukuran = {}
    for y in range(H):
        for x in range(W):
            if isi[y, x] and not label[y, x]:
                n += 1
                tumpuk = [(x, y)]
                label[y, x] = n
                k = 0
                while tumpuk:
                    cx, cy = tumpuk.pop()
                    k += 1
                    for dx in (-1, 0, 1):
                        for dy in (-1, 0, 1):
                            xx, yy = cx + dx, cy + dy
                            if 0 <= xx < W and 0 <= yy < H and isi[yy, xx] and not label[yy, xx]:
                                label[yy, xx] = n
                                tumpuk.append((xx, yy))
                ukuran[n] = k
    for lab, k in ukuran.items():
        if k < min_px:
            img[label == lab] = 0
    return img


def bayangan(img):
    H, W = img.shape[:2]
    ss = 4
    m = Image.new('L', (W * ss, H * ss), 0)
    ImageDraw.Draw(m).ellipse([8 * ss, 259 * ss, 232 * ss, 267 * ss], fill=255)
    m = np.asarray(m.resize((W, H), Image.BOX)) >= 128
    kosong = img[..., 3] == 0
    img[m & kosong] = BAYANGAN
    return img


def potong(img):
    ys, xs = np.nonzero(img[..., 3] > 0)
    return img[ys.min():ys.max() + 1, xs.min():xs.max() + 1], (int(xs.min()), int(ys.min()))


def setengah(img):
    """Versi 1/2. Blok 2x2 dengan >= 3 piksel opak selain jari-jari = padat, warna terbanyak (garis luar kalah bila seri); blok dengan
    1-2 piksel opak = garis tipis (jari-jari, kabel), memakai warna paling terang supaya tidak menebal; blok yang
    menyentuh bayangan = bayangan. Garis luar #1B1226 hanya di sekitar blok padat."""
    H, W = img.shape[:2]
    H2, W2 = (H + 1) // 2, (W + 1) // 2
    pad = np.zeros((H2 * 2, W2 * 2, 4), np.uint8)
    pad[:H, :W] = img
    out = np.zeros((H2, W2, 4), np.uint8)
    padat = np.zeros((H2, W2), bool)
    for y in range(H2):
        for x in range(W2):
            blok = [tuple(int(v) for v in pad[2 * y + dy, 2 * x + dx]) for dy in (0, 1) for dx in (0, 1)]
            opak = [b for b in blok if b[3] == 255]
            bukan_jari = [b for b in opak if b[:3] not in JARI]
            if len(bukan_jari) >= 3:
                hitung = {}
                for b in opak:
                    hitung[b] = hitung.get(b, 0) + (1 if b[:3] != GARIS else 0.9)
                out[y, x] = max(sorted(hitung), key=lambda b: hitung[b])
                padat[y, x] = True
            elif opak:
                out[y, x] = max(opak, key=lambda b: (sum(b[:3]), b))
            elif any(0 < b[3] < 255 for b in blok):
                out[y, x] = BAYANGAN
    tepi = np.zeros_like(padat)
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        geser = np.zeros_like(padat)
        ys = slice(max(dy, 0), H2 + min(dy, 0))
        yd = slice(max(-dy, 0), H2 + min(-dy, 0))
        xs = slice(max(dx, 0), W2 + min(dx, 0))
        xd = slice(max(-dx, 0), W2 + min(-dx, 0))
        geser[yd, xd] = padat[ys, xs]
        tepi |= geser
    tepi &= out[..., 3] < 255
    out[tepi] = (*GARIS, 255)
    return out


def main():
    ap = argparse.ArgumentParser(description='Sepeda dari gambar full body (usulan)')
    ap.add_argument('--out', default=str(ROOT / 'build' / 'ui_art' / 'redesain'))
    ap.add_argument('--mock', action='store_true', help='juga salin ke docs/design/redesain/aset/')
    a = ap.parse_args()
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    asli = np.asarray(Image.open(SUMBER).convert('RGBA')).copy()
    img, lubang = buang_tokoh(asli)
    k = Kuas(img, lubang)
    roda_belakang(k)
    rangka(k)
    sadel(k, asli)
    gir_dan_engkol(k)
    k.garis_luar()
    img = rapikan_lepas(k.img)
    img = bayangan(img)
    besar, (x0, y0) = potong(img)
    kecil = setengah(besar)
    hasil = {'sepeda_besar.png': besar, 'sepeda_kecil.png': kecil}
    for nama, arr in hasil.items():
        Image.fromarray(arr).save(out / nama)
    titik = {n: [(x - x0) // 2, (y - y0) // 2] for n, (x, y) in TITIK.items()}
    meta = {'sumber': 'docs/design/character/loper_agen/loper_agen_fullbody.png', 'potong_dari': [x0, y0],
            'besar': list(besar.shape[1::-1]), 'kecil': list(kecil.shape[1::-1]),
            'titik_kecil': titik, 'catatan': 'titik_kecil = tempat penanda kondisi di sepeda_kecil (ban, rem, rantai)'}
    (out / 'sepeda.json').write_text(json.dumps(meta, indent=1, sort_keys=True) + '\n')
    Image.fromarray(besar).resize((besar.shape[1] * 3, besar.shape[0] * 3), Image.NEAREST).save(out / 'sepeda_besar_x3.png')
    if a.mock:
        MOCK.mkdir(parents=True, exist_ok=True)
        for n in ('sepeda_besar.png', 'sepeda_kecil.png', 'sepeda_besar_x3.png', 'sepeda.json'):
            shutil.copyfile(out / n, MOCK / n)
    print('besar', besar.shape[1], 'x', besar.shape[0], '| kecil', kecil.shape[1], 'x', kecil.shape[0])


if __name__ == '__main__':
    main()
