#!/usr/bin/env python3
"""Membangun `loper_agen_frames.tres` gabungan (kayuh + melambat + lempar) dari tiga JSON sumber.

Hanya pustaka standar Python 3 (tanpa numpy, pillow, atau renderer). Format `.tres` sama dengan
yang ditulis `produce.py` (SpriteFrames Godot 4, satu AtlasTexture per frame, durasi frame 1.0),
jadi 15 animasi kayuh pertama tetap persis seperti sebelumnya dan animasi baru ditambahkan di belakangnya.

    python3 tools/loper_art/bangun_frames.py                       # sumber docs/design/character/loper_agen, hasil assets/sprites/loper
    python3 tools/loper_art/bangun_frames.py --out build/frames    # tulis ke folder lain (mis. untuk dibandingkan)
    python3 tools/loper_art/bangun_frames.py --cek                 # tidak menulis; exit 1 bila isi --out berbeda dari hasil

Yang dilakukan:
    1. Membaca tiga JSON sumber: kayuh (`loper_agen.json`), melambat (`melambat/loper_agen_melambat.json`),
       lempar (`lempar/loper_agen_lempar.json`). Urutan animasi di `.tres` = urutan ketiga berkas, dan di dalam
       tiap berkas urutan `animations`.
    2. Memeriksa JSON: nama animasi unik, tiap region ada di dalam PNG-nya (ukuran dibaca dari header PNG).
    3. Menyalin PNG dan JSON byte demi byte ke folder hasil (aset di repo tidak pernah diedit dengan tangan).
    4. Menulis `loper_agen_frames.tres`: fps dan `loop` tiap animasi dari JSON (lempar tidak berulang).

Deterministik: tanpa cap waktu, urutan tetap, akhir baris `\\n`, jadi dua kali jalan menghasilkan byte yang sama.
Jangan menulis `.tres` dengan tangan; ubah JSON sumber (lewat renderernya) lalu jalankan skrip ini.
"""
import argparse
import json
import os
import shutil
import struct
import sys

# (JSON relatif terhadap folder sumber, id ext_resource di .tres). Id pertama "1_sheet" sama dengan produce.py.
SUMBER = [
    ('loper_agen.json', '1_sheet'),
    ('melambat/loper_agen_melambat.json', '2_melambat'),
    ('lempar/loper_agen_lempar.json', '3_lempar'),
]
BERKAS_HASIL = 'loper_agen_frames.tres'
BAWAAN_SUMBER = 'docs/design/character/loper_agen'
BAWAAN_HASIL = 'assets/sprites/loper'
BAWAAN_RES = 'res://assets/sprites/loper'
TANDA_PNG = b'\x89PNG\r\n\x1a\n'


class Galat(Exception):
    """Masukan sumber tidak sah."""


def ukuran_png(jalur):
    """(lebar, tinggi) dari header IHDR sebuah PNG."""
    with open(jalur, 'rb') as f:
        kepala = f.read(24)
    if len(kepala) < 24 or kepala[:8] != TANDA_PNG or kepala[12:16] != b'IHDR':
        raise Galat(f'{jalur}: bukan PNG')
    return struct.unpack('>II', kepala[16:24])


def baca_sumber(folder_sumber):
    """Daftar (meta, jalur_json, jalur_png, id_ext) untuk tiga sumber, sudah diperiksa."""
    hasil = []
    nama_terlihat = set()
    for rel, id_ext in SUMBER:
        jalur_json = os.path.join(folder_sumber, rel)
        if not os.path.isfile(jalur_json):
            raise Galat(f'{jalur_json}: tidak ada')
        with open(jalur_json, encoding='utf-8') as f:
            meta = json.load(f)
        jalur_png = os.path.join(os.path.dirname(jalur_json), meta['sprite'])
        if not os.path.isfile(jalur_png):
            raise Galat(f'{jalur_png}: tidak ada')
        lebar, tinggi = ukuran_png(jalur_png)
        sel_w, sel_h = meta['cell']
        if (lebar, tinggi) != (sel_w * meta['columns'], sel_h * meta['rows']):
            raise Galat(f'{jalur_png}: ukuran {lebar}x{tinggi} tidak sama dengan kolom x baris x sel di JSON')
        for anim in meta['animations']:
            nama = anim['name']
            if nama in nama_terlihat:
                raise Galat(f'animasi ganda: {nama}')
            nama_terlihat.add(nama)
            if not anim['regions']:
                raise Galat(f'{nama}: tanpa frame')
            for x, y, w, h in anim['regions']:
                if x < 0 or y < 0 or x + w > lebar or y + h > tinggi:
                    raise Galat(f'{nama}: region {[x, y, w, h]} di luar PNG {lebar}x{tinggi}')
        hasil.append((meta, jalur_json, jalur_png, id_ext))
    return hasil


def tulis_tres(sumber, res_dir):
    """Teks `.tres`: satu ext_resource per sheet, satu AtlasTexture per frame, satu resource SpriteFrames."""
    ext, subs, animasi = [], [], []
    nomor = 0
    for meta, _, _, id_ext in sumber:
        ext.append(f'[ext_resource type="Texture2D" path="{res_dir}/{meta["sprite"]}" id="{id_ext}"]\n')
        for anim in meta['animations']:
            frame = []
            for x, y, w, h in anim['regions']:
                nomor += 1
                subs.append(f'[sub_resource type="AtlasTexture" id="AtlasTexture_{nomor}"]\n'
                            f'atlas = ExtResource("{id_ext}")\nregion = Rect2({x}, {y}, {w}, {h})\n')
                frame.append('{\n"duration": 1.0,\n"texture": SubResource("AtlasTexture_%d")\n}' % nomor)
            loop = 'true' if anim['loop'] else 'false'
            animasi.append('{\n"frames": [' + ', '.join(frame) + '],\n"loop": %s,\n"name": &"%s",\n"speed": %.1f\n}'
                           % (loop, anim['name'], anim['fps']))
    return (f'[gd_resource type="SpriteFrames" load_steps={nomor + len(ext) + 1} format=3]\n\n'
            + ''.join(ext) + '\n' + '\n'.join(subs) + '\n[resource]\nanimations = [' + ', '.join(animasi) + ']\n')


def bangun(folder_sumber, folder_hasil, res_dir):
    """Kembalikan {nama berkas: isi bytes} yang seharusnya ada di `folder_hasil` (PNG, JSON, .tres)."""
    sumber = baca_sumber(folder_sumber)
    isi = {}
    for meta, jalur_json, jalur_png, _ in sumber:
        for jalur in (jalur_png, jalur_json):
            with open(jalur, 'rb') as f:
                isi[os.path.basename(jalur)] = f.read()
    isi[BERKAS_HASIL] = tulis_tres(sumber, res_dir).encode('utf-8')
    return isi


def main():
    ap = argparse.ArgumentParser(description='Bangun loper_agen_frames.tres gabungan dari tiga JSON sumber.')
    ap.add_argument('--src', default=BAWAAN_SUMBER, help='folder sumber (berisi loper_agen.json, melambat/, lempar/)')
    ap.add_argument('--out', default=BAWAAN_HASIL, help='folder hasil (PNG, JSON, .tres)')
    ap.add_argument('--res-dir', default=BAWAAN_RES, help='folder sheet di project Godot (untuk path di .tres)')
    ap.add_argument('--cek', action='store_true', help='jangan menulis; exit 1 bila isi --out berbeda dari hasil')
    args = ap.parse_args()
    try:
        isi = bangun(args.src, args.out, args.res_dir)
    except (Galat, KeyError, ValueError) as e:
        print(f'GALAT: {e}', file=sys.stderr)
        return 2
    if args.cek:
        beda = []
        for nama, data in sorted(isi.items()):
            jalur = os.path.join(args.out, nama)
            if not os.path.isfile(jalur) or open(jalur, 'rb').read() != data:
                beda.append(nama)
        if beda:
            print('berbeda dari hasil: ' + ', '.join(beda))
            return 1
        print(f'sama: {len(isi)} berkas di {args.out}')
        return 0
    os.makedirs(args.out, exist_ok=True)
    for nama, data in sorted(isi.items()):
        with open(os.path.join(args.out, nama), 'wb') as f:
            f.write(data)
    anim = isi[BERKAS_HASIL].count(b'"name": &"')
    print(f'{BERKAS_HASIL}: {anim} animasi, {len(isi) - 1} berkas sumber disalin -> {args.out}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
