#!/usr/bin/env python3
"""Ekspor build probe render (`scenes/dev/cek_render.tscn` sebagai scene utama) tanpa mengubah repo (D-8 run fase1b-umpan-balik,
D-4 run fase1c-perapian).

Scene utama yang di-commit tetap `res://scenes/hari/hari.tscn`, dan preset `Android` di `export_presets.cfg` mengecualikan
berkas probe (`POLA_PROBE`) dari build normal lewat `exclude_filter` (QA-004 run fase1b-umpan-balik: APK normal tanpa probe).
Skrip ini, HANYA selama satu perintah ekspor Godot (preset yang sama): mengganti baris `run/main_scene` di `project.godot` ke
probe, dan melepas `POLA_PROBE` dari `exclude_filter` preset. Sesudahnya kedua berkas dipulihkan byte demi byte di `finally`
(juga bila Godot gagal, tidak ditemukan, atau dihentikan Ctrl+C), lalu diperiksa: hasil ekspor memuat berkas probe, `project.binary`
di dalamnya menunjuk ke probe, dan kedua berkas kembali persis seperti semula. Hanya pustaka standar.

Kenapa bukan `override.cfg`: dicoba 2026-10-14, `override.cfg` di root tidak ikut ke paket (bukan resource) dan tidak
digabung ke `project.binary` saat ekspor, jadi paket tetap membuka scene utama (`hari.tscn`). Kenapa bukan argumen baris perintah di
`JalanUji`: cara meneruskan argumen ke APK lewat `adb shell am start` belum bisa dibuktikan tanpa HP, dan menambah jalan dari
game ke probe.

Cara pakai (dari root repo, `godot` 4.7.2 di PATH atau `--godot`):
    python3 tools/ekspor_cek_render.py --pck build/kring-cek-render.pck          # paket saja (tanpa Java)
    python3 tools/ekspor_cek_render.py --apk builds/kring-cek-render-debug.apk   # APK debug probe (butuh template + Java SDK Path)
    godot --main-pack build/kring-cek-render.pck                                 # jalankan paket probe di desktop

APK probe memakai package yang sama (`com.rmh.kring`): memasangnya menimpa app uji di HP (data tetap dengan `adb install -r`).
Pasang ulang APK normal sesudah mengambil bukti (docs/SETUP_ANDROID.md 6.1).

`POLA_PROBE` harus sama dengan pola probe di `exclude_filter` preset; `tests/tes_export.gd` menjaga keduanya tidak berpisah.

Exit code: 0 bila ekspor berhasil, hasilnya memuat probe dan menunjuk ke probe, dan `project.godot` serta `export_presets.cfg`
pulih; selain itu 1.
"""
import argparse
import os
import shutil
import subprocess
import sys
import zipfile

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
PROYEK = os.path.join(ROOT, 'project.godot')
BERKAS_PRESET = os.path.join(ROOT, 'export_presets.cfg')
PRESET = 'Android'
SCENE_UTAMA = 'res://scenes/hari/hari.tscn'
SCENE_PROBE = 'res://scenes/dev/cek_render.tscn'
BARIS_UTAMA = 'run/main_scene="%s"' % SCENE_UTAMA
BARIS_PROBE = 'run/main_scene="%s"' % SCENE_PROBE
# Berkas probe yang dikecualikan dari build normal oleh `exclude_filter` preset dan dilepas sementara di sini (relatif ke root).
POLA_PROBE = ['scenes/dev/cek_render.tscn', 'scripts/dev/cek_render.gd', 'assets/shaders/warna_bayangan.gdshader']
# Potongan nama yang harus ada di hasil ekspor probe (scene diekspor sebagai `.remap`, skrip sebagai `.gdc`).
BUKTI_PROBE = ['scenes/dev/cek_render.tscn', 'scripts/dev/cek_render.gd', 'assets/shaders/warna_bayangan.gdshader']
AWALAN_FILTER = 'exclude_filter="'


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


def nama_di_hasil(jalur, apk):
    """Teks yang memuat nama berkas di hasil ekspor: daftar entri APK, atau seluruh byte paket .pck (tabel berkasnya tidak dienkripsi)."""
    if apk:
        with zipfile.ZipFile(jalur) as z:
            return '\n'.join(z.namelist()).encode()
    with open(jalur, 'rb') as f:
        return f.read()


def filter_tanpa_probe(teks_preset):
    """Isi `export_presets.cfg` dengan `POLA_PROBE` dilepas dari satu-satunya baris `exclude_filter`, atau (None, alasan)."""
    baris = teks_preset.split('\n')
    indeks = [i for i, b in enumerate(baris) if b.startswith(AWALAN_FILTER) and b.endswith('"')]
    if len(indeks) != 1:
        return None, 'export_presets.cfg harus memuat tepat satu baris exclude_filter, dapat %d' % len(indeks)
    i = indeks[0]
    bagian = [p.strip() for p in baris[i][len(AWALAN_FILTER):-1].split(',') if p.strip()]
    hilang = [p for p in POLA_PROBE if p not in bagian]
    if hilang:
        return None, 'exclude_filter preset tidak memuat pola probe %s (build normal akan memuat probe)' % ', '.join(hilang)
    baris[i] = AWALAN_FILTER + ', '.join(p for p in bagian if p not in POLA_PROBE) + '"'
    return '\n'.join(baris), ''


def main():
    pengurai = argparse.ArgumentParser(description='Ekspor build probe render cek_render tanpa mengubah repo.')
    keluaran = pengurai.add_mutually_exclusive_group(required=True)
    keluaran.add_argument('--pck', help='tulis paket .pck (godot --export-pack)')
    keluaran.add_argument('--apk', help='tulis APK debug (godot --export-debug)')
    pengurai.add_argument('--godot', default=shutil.which('godot') or '/Applications/Godot.app/Contents/MacOS/Godot', help='jalur Godot 4.7.2')
    argumen = pengurai.parse_args()

    with open(PROYEK, 'rb') as f:
        asli = f.read()
    with open(BERKAS_PRESET, 'rb') as f:
        asli_preset = f.read()
    teks = asli.decode('utf-8')
    if teks.count(BARIS_UTAMA) != 1:
        print('GAGAL: project.godot tidak memuat tepat satu baris %s; tidak ada yang diubah' % BARIS_UTAMA)
        return 1
    preset_probe, alasan = filter_tanpa_probe(asli_preset.decode('utf-8'))
    if preset_probe is None:
        print('GAGAL: %s; tidak ada yang diubah' % alasan)
        return 1
    tujuan = os.path.abspath(argumen.pck or argumen.apk)
    os.makedirs(os.path.dirname(tujuan), exist_ok=True)
    if os.path.exists(tujuan):
        os.remove(tujuan)
    perintah = [argumen.godot, '--headless', '--path', ROOT, '--export-pack' if argumen.pck else '--export-debug', PRESET, tujuan]
    hasil = None
    galat_jalan = ''
    try:
        with open(PROYEK, 'wb') as f:
            f.write(teks.replace(BARIS_UTAMA, BARIS_PROBE).encode('utf-8'))
        with open(BERKAS_PRESET, 'wb') as f:
            f.write(preset_probe.encode('utf-8'))
        print('scene utama sementara: %s' % SCENE_PROBE)
        print('exclude_filter sementara tanpa: %s' % ', '.join(POLA_PROBE))
        print('menjalankan: %s' % ' '.join(perintah))
        try:
            hasil = subprocess.run(perintah, capture_output=True, text=True)
        except OSError as galat:
            galat_jalan = str(galat)
    finally:
        with open(PROYEK, 'wb') as f:
            f.write(asli)
        with open(BERKAS_PRESET, 'wb') as f:
            f.write(asli_preset)
    with open(PROYEK, 'rb') as f:
        pulih = f.read() == asli
    with open(BERKAS_PRESET, 'rb') as f:
        pulih_preset = f.read() == asli_preset
    print('project.godot pulih byte demi byte: %s' % ('ya' if pulih else 'TIDAK'))
    print('export_presets.cfg pulih byte demi byte: %s' % ('ya' if pulih_preset else 'TIDAK'))
    if hasil is None:
        print('GAGAL: Godot tidak bisa dijalankan (%s): %s' % (argumen.godot, galat_jalan))
        return 1
    keluaran_godot = hasil.stdout + hasil.stderr
    baris_masalah = [b for b in keluaran_godot.splitlines() if 'ERROR' in b or 'WARNING' in b]
    for b in baris_masalah:
        print('godot:', b)
    if hasil.returncode != 0 or not os.path.isfile(tujuan):
        print('GAGAL: ekspor exit %d atau berkas hasil tidak ada' % hasil.returncode)
        print(keluaran_godot[-2000:])
        return 1
    apk = bool(argumen.apk)
    scene = scene_di_paket(isi_project_binary(tujuan, apk))
    nama = nama_di_hasil(tujuan, apk)
    tanpa_bukti = [b for b in BUKTI_PROBE if b.encode() not in nama]
    print('%s: %d byte, scene utama di project.binary = %s' % (tujuan, os.path.getsize(tujuan), scene))
    print('berkas probe di hasil ekspor: %s' % ('semua ada' if not tanpa_bukti else 'TIDAK ADA ' + ', '.join(tanpa_bukti)))
    if not pulih or not pulih_preset or scene != SCENE_PROBE or tanpa_bukti or baris_masalah:
        print('GAGAL: hasil tidak memuat atau tidak menunjuk ke probe, berkas repo tidak pulih, atau keluaran Godot memuat ERROR/WARNING')
        return 1
    print('lolos: build probe siap; build normal tetap dari project.godot dan export_presets.cfg yang di-commit (%s, tanpa probe)' % SCENE_UTAMA)
    return 0


if __name__ == '__main__':
    sys.exit(main())
