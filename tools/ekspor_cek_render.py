#!/usr/bin/env python3
"""Ekspor build probe render (`scenes/dev/cek_render.tscn` sebagai scene utama) tanpa mengubah repo (D-8 run fase1b-umpan-balik).

Scene utama yang di-commit tetap `res://scenes/dev/jalan_uji.tscn`. Skrip ini mengganti baris `run/main_scene` di
`project.godot` HANYA selama satu perintah ekspor Godot (preset `Android` yang sama), lalu memulihkan berkas byte demi byte
(juga bila ekspor gagal atau dihentikan Ctrl+C). Sesudahnya memeriksa bahwa `project.binary` di dalam hasil ekspor memang
menunjuk ke probe, dan bahwa `project.godot` kembali persis seperti semula. Hanya pustaka standar.

Kenapa bukan `override.cfg`: dicoba 2026-10-14, `override.cfg` di root tidak ikut ke paket (bukan resource) dan tidak
digabung ke `project.binary` saat ekspor, jadi paket tetap membuka `jalan_uji.tscn`. Kenapa bukan argumen baris perintah di
`JalanUji`: cara meneruskan argumen ke APK lewat `adb shell am start` belum bisa dibuktikan tanpa HP, dan menambah jalan dari
game ke probe.

Cara pakai (dari root repo, `godot` 4.7.2 di PATH atau `--godot`):
    python3 tools/ekspor_cek_render.py --pck build/kring-cek-render.pck          # paket saja (tanpa Java)
    python3 tools/ekspor_cek_render.py --apk builds/kring-cek-render-debug.apk   # APK debug probe (butuh template + Java SDK Path)
    godot --main-pack build/kring-cek-render.pck                                 # jalankan paket probe di desktop

APK probe memakai package yang sama (`com.rmh.kring`): memasangnya menimpa app uji di HP (data tetap dengan `adb install -r`).
Pasang ulang APK normal sesudah mengambil bukti (docs/SETUP_ANDROID.md 6.1).

Exit code: 0 bila ekspor berhasil, hasilnya menunjuk ke probe, dan `project.godot` pulih; selain itu 1.
"""
import argparse
import os
import shutil
import subprocess
import sys
import zipfile

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
PROYEK = os.path.join(ROOT, 'project.godot')
PRESET = 'Android'
SCENE_UTAMA = 'res://scenes/dev/jalan_uji.tscn'
SCENE_PROBE = 'res://scenes/dev/cek_render.tscn'
BARIS_UTAMA = 'run/main_scene="%s"' % SCENE_UTAMA
BARIS_PROBE = 'run/main_scene="%s"' % SCENE_PROBE


def scene_di_paket(data):
    """Scene utama yang tercatat di `project.binary` (dicari sebagai teks di dalam byte), atau None."""
    for scene in (SCENE_PROBE, SCENE_UTAMA):
        if scene.encode() in data:
            kunci = data.find(b'application/run/main_scene')
            if kunci >= 0 and data.find(scene.encode(), kunci) - kunci < 64:
                return scene
    return None


def isi_project_binary(jalur, apk):
    if apk:
        with zipfile.ZipFile(jalur) as z:
            return z.read('assets/project.binary')
    with open(jalur, 'rb') as f:
        return f.read()


def main():
    pengurai = argparse.ArgumentParser(description='Ekspor build probe render cek_render tanpa mengubah repo.')
    keluaran = pengurai.add_mutually_exclusive_group(required=True)
    keluaran.add_argument('--pck', help='tulis paket .pck (godot --export-pack)')
    keluaran.add_argument('--apk', help='tulis APK debug (godot --export-debug)')
    pengurai.add_argument('--godot', default=shutil.which('godot') or '/Applications/Godot.app/Contents/MacOS/Godot', help='jalur Godot 4.7.2')
    argumen = pengurai.parse_args()

    with open(PROYEK, 'rb') as f:
        asli = f.read()
    teks = asli.decode('utf-8')
    if teks.count(BARIS_UTAMA) != 1:
        print('GAGAL: project.godot tidak memuat tepat satu baris %s; tidak ada yang diubah' % BARIS_UTAMA)
        return 1
    tujuan = os.path.abspath(argumen.pck or argumen.apk)
    os.makedirs(os.path.dirname(tujuan), exist_ok=True)
    perintah = [argumen.godot, '--headless', '--path', ROOT, '--export-pack' if argumen.pck else '--export-debug', PRESET, tujuan]
    try:
        with open(PROYEK, 'wb') as f:
            f.write(teks.replace(BARIS_UTAMA, BARIS_PROBE).encode('utf-8'))
        print('scene utama sementara: %s' % SCENE_PROBE)
        print('menjalankan: %s' % ' '.join(perintah))
        hasil = subprocess.run(perintah, capture_output=True, text=True)
    finally:
        with open(PROYEK, 'wb') as f:
            f.write(asli)
    keluaran_godot = hasil.stdout + hasil.stderr
    baris_masalah = [b for b in keluaran_godot.splitlines() if 'ERROR' in b or 'WARNING' in b]
    for b in baris_masalah:
        print('godot:', b)
    with open(PROYEK, 'rb') as f:
        pulih = f.read() == asli
    print('project.godot pulih byte demi byte: %s' % ('ya' if pulih else 'TIDAK'))
    if hasil.returncode != 0 or not os.path.isfile(tujuan):
        print('GAGAL: ekspor exit %d' % hasil.returncode)
        print(keluaran_godot[-2000:])
        return 1
    scene = scene_di_paket(isi_project_binary(tujuan, bool(argumen.apk)))
    print('%s: %d byte, scene utama di project.binary = %s' % (tujuan, os.path.getsize(tujuan), scene))
    if not pulih or scene != SCENE_PROBE or baris_masalah:
        print('GAGAL: hasil tidak menunjuk ke probe, project.godot tidak pulih, atau keluaran Godot memuat ERROR/WARNING')
        return 1
    print('lolos: build probe siap; build normal tetap dari project.godot yang di-commit (%s)' % SCENE_UTAMA)
    return 0


if __name__ == '__main__':
    sys.exit(main())
