#!/usr/bin/env python3
"""Mutan bagian C run 5D (AC-19): paket, pemindai rujukan, dan dokumen-tes. Satu perubahan, runner tes_export (jalan_export.gd), pulihkan, git status bersih.

Pakai dari root repo: python3 docs/loop/20261022-fase5d-sisi-dekat/dev_ukur/mutan_c.py <jalur jalan_export.gd> [C1 C2 ...]
jalan_export.gd: SceneTree yang menjalankan TesExport.new(cek, judul).jalankan() dan mencetak "N lolos, M gagal".
"""
import os
import re
import shutil
import subprocess
import sys

RUMAH = 'assets/sprites/houses/perumahan/'
TEMBOK = RUMAH + 'house_' + 'tembok_polos.png'


def ganti(jalur, lama, baru, semua=False):
    s = open(jalur, encoding='utf-8').read()
    assert s.count(lama) >= 1 and (semua or s.count(lama) == 1), (jalur, lama, s.count(lama))
    open(jalur, 'w', encoding='utf-8').write(s.replace(lama, baru))


def pulih(jalur):
    subprocess.run(['git', 'checkout', '--', jalur], check=True)


MUTAN = {
    'C1': ('aset tembok ikut tersalin ke assets/ (PNG tembok muncul lagi)',
           lambda: shutil.copy(RUMAH + 'house_perumahan_dekat_limasan_bukan.png', TEMBOK),
           lambda: os.remove(TEMBOK)),
    'C2': ('.import rumah dekat bukan Lossless (compress/mode=2)',
           lambda: ganti(RUMAH + 'house_perumahan_dekat_pelana_sejajar_pelanggan.png.import', 'compress/mode=0', 'compress/mode=2'),
           lambda: pulih(RUMAH + 'house_perumahan_dekat_pelana_sejajar_pelanggan.png.import')),
    'C3': ('pemindai: config.gd merujuk rumah dekat yang tidak dipasang (komentar)',
           lambda: ganti('scripts/config.gd', 'const RUTE_RUMAH_DEKAT_MUNDUR_UBIN', '## lihat house_perumahan_dekat_' + 'pelana_gudang_bukan\nconst RUTE_RUMAH_DEKAT_MUNDUR_UBIN'),
           lambda: pulih('scripts/config.gd')),
    'C4': ('pemindai: rute.tscn merujuk kotak surat dekat yang tidak dipasang',
           lambda: open('scenes/rute/rute.tscn', 'a', encoding='utf-8').write('; prop_kotak_surat_' + 'dekat\n'),
           lambda: pulih('scenes/rute/rute.tscn')),
    'C5': ('preset: satu rumah dekat dikecualikan dari paket',
           lambda: ganti('export_presets.cfg', 'exclude_filter="docs/*, ', 'exclude_filter="' + RUMAH + 'house_perumahan_dekat_limasan_bukan.png, docs/*, '),
           lambda: pulih('export_presets.cfg')),
    'C6': ('kunci tip RUTE_TIP_SISI_DEKAT hilang dari ui.csv',
           lambda: ganti('translations/ui.csv', 'RUTE_TIP_SISI_DEKAT,Mulai hari ini pelanggan ada di kedua sisi jalan\n', ''),
           lambda: pulih('translations/ui.csv')),
    'C7': ('data segmen: satu rumah dekat pelanggan_boleh jadi false (jumlah 34 berubah)',
           lambda: ganti('assets/data/routes/perumahan/per_buka_01.json', '{ "pos": 8, "sisi": "dekat", "jenis": "dekat_limasan", "pelanggan_boleh": true }', '{ "pos": 8, "sisi": "dekat", "jenis": "dekat_limasan", "pelanggan_boleh": false }'),
           lambda: pulih('assets/data/routes/perumahan/per_buka_01.json')),
    'C8': ('JSON rumah dekat kehilangan teras_ubin',
           lambda: ganti(RUMAH + 'house_perumahan_dekat_limasan_bukan.json', '"teras_ubin"', '"teras_ubinx"'),
           lambda: pulih(RUMAH + 'house_perumahan_dekat_limasan_bukan.json')),
    'C9': ('tag sisi_pelanggan per_tutup_02 jadi seberang (tidak sesuai isi)',
           lambda: ganti('assets/data/routes/perumahan/per_tutup_02.json', '"sisi_pelanggan": "dua_sisi"', '"sisi_pelanggan": "seberang"'),
           lambda: pulih('assets/data/routes/perumahan/per_tutup_02.json')),
    'C10': ('dokumen-tes: bagian 8.16 hilang dari SETUP_ANDROID (judul jadi 8.17)',
            lambda: ganti('docs/SETUP_ANDROID.md', '### 8.16 Uji pelanggan', '### 8.17 Uji pelanggan'),
            lambda: pulih('docs/SETUP_ANDROID.md')),
    'C11': ('dokumen-tes: ROADMAP kehilangan riwayat tembok',
            lambda: ganti('docs/ROADMAP.md', 'Riwayat (diganti, tetap dicatat)', 'Riwayat'),
            lambda: pulih('docs/ROADMAP.md')),
    'C12': ('dokumen-tes: GDD kuota 8 atau 9 jadi 7 atau 10',
            lambda: ganti('docs/GDD.md', '8 atau 9 dari 25', '7 atau 10 dari 25', semua=True),
            lambda: pulih('docs/GDD.md')),
    'C13': ('dokumen-tes: AGENTS.md mendaftar lagi TembokDekat sebagai ada',
            lambda: ganti('AGENTS.md', 'Fase 5 run 5B: dekor pinggir jalan', 'Fase 5 run 5B: tembok sisi dekat (`TembokDekat`, `VarianTembok`), dekor pinggir jalan'),
            lambda: pulih('AGENTS.md')),
}


def jalankan(kode, runner):
    label, terapkan, kembalikan = MUTAN[kode]
    terapkan()
    try:
        r = subprocess.run(['godot', '--headless', '--path', '.', '--script', runner], capture_output=True, text=True)
        log = r.stdout + r.stderr
    finally:
        kembalikan()
    m = re.findall(r'(\d+) lolos, (\d+) gagal', log)
    gagal = [l for l in log.splitlines() if l.startswith('GAGAL')]
    galat = 'SCRIPT ERROR' in log or 'Parse Error' in log
    mati = bool(gagal) or galat or bool(m and int(m[-1][1]) > 0)
    bersih = subprocess.run(['git', 'status', '--porcelain'], capture_output=True, text=True).stdout
    bersih = [b for b in bersih.splitlines() if '.claude' not in b and 'tests/tes_export.gd' not in b and 'assets/LICENSES.md' not in b and 'dev_ukur' not in b]
    print(kode, 'MATI' if mati else 'HIDUP!!', m[-1] if m else '?', '| bersih' if not bersih else '| KOTOR %s' % bersih, '|', label, '|', (gagal[0][:150] if gagal else ''))


if __name__ == '__main__':
    runner = sys.argv[1]
    pilih = sys.argv[2:] or list(MUTAN)
    for k in pilih:
        jalankan(k, runner)
