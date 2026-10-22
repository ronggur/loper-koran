#!/usr/bin/env python3
"""Mutan bagian E run 5C (AC-22, AC-27): satu perubahan pada berkas asli, run_tests.gd penuh + pemeriksa, lalu dikembalikan.

Pakai dari root repo: python3 docs/loop/20261022-fase5c-animasi-simpang/dev_ukur/mutan_e.py [E1 E2 ...]
"""
import os
import re
import shutil
import subprocess
import sys

AKAR = os.getcwd()
UBIN = 'assets/sprites/tiles/perumahan/'
TAK = UBIN + 'tile_perumahan_' + 'simpang_dekat_aspal_dekat_depan_2.png'


def ganti(jalur, lama, baru):
    s = open(jalur, encoding='utf-8').read()
    assert s.count(lama) == 1, (jalur, lama)
    open(jalur, 'w', encoding='utf-8').write(s.replace(lama, baru))


def pulih(jalur):
    subprocess.run(['git', 'checkout', '--', jalur], check=True)


MUTAN = {
    'E1': ('export_presets.cfg: loper/* dikecualikan dari paket',
           lambda: ganti('export_presets.cfg', 'exclude_filter="docs/*, ', 'exclude_filter="assets/sprites/loper/*, docs/*, '),
           lambda: pulih('export_presets.cfg')),
    'E2': ('satu ubin simpang seberang dikecualikan dari paket',
           lambda: ganti('export_presets.cfg', 'exclude_filter="docs/*, ', 'exclude_filter="' + UBIN + 'tile_perumahan_simpang_seberang_lengan_mulut_1.png, docs/*, '),
           lambda: pulih('export_presets.cfg')),
    'E3': ('ubin simpang tak dipasang ikut ada di assets/ (tersalin)',
           lambda: shutil.copy(UBIN + 'tile_perumahan_simpang_dekat_aspal_dekat_mulut_1.png', TAK),
           lambda: os.remove(TAK)),
    'E4': ('rujukan ke ubin simpang tak dipasang di scripts/config.gd (komentar)',
           lambda: ganti('scripts/config.gd', 'const RUTE_SIMPANG_LEBAR_MULUT_UBIN', '## lihat tile_perumahan_' + 'simpang_dekat_aspal_dekat_depan_2\nconst RUTE_SIMPANG_LEBAR_MULUT_UBIN'),
           lambda: pulih('scripts/config.gd')),
    'E5': ('rujukan ke ujung kerb sisi dekat di rute.tscn (komentar)',
           lambda: open('scenes/rute/rute.tscn', 'a', encoding='utf-8').write('; tile_perumahan_' + 'trotoar_dekat_masuk_ujung\n'),
           lambda: pulih('scenes/rute/rute.tscn')),
    'E6': ('sheet pemain bangkit diimpor lossy (.import compress/mode=1)',
           lambda: ganti('assets/sprites/loper/loper_agen_bangkit.png.import', 'compress/mode=0', 'compress/mode=1'),
           lambda: pulih('assets/sprites/loper/loper_agen_bangkit.png.import')),
    'E7': ('JSON sheet kucing columns 9 jadi 8',
           lambda: ganti('assets/sprites/npc/mission_kucing_sheet.json', '"columns": 9', '"columns": 8'),
           lambda: pulih('assets/sprites/npc/mission_kucing_sheet.json')),
}


def jalankan(kode):
    label, terapkan, kembalikan = MUTAN[kode]
    terapkan()
    try:
        r = subprocess.run('godot --headless --script res://tests/run_tests.gd 2>&1', shell=True, capture_output=True, text=True)
        log = r.stdout
    finally:
        kembalikan()
    m = re.search(r'(\d+) lolos, (\d+) gagal', log)
    gagal = [l for l in log.splitlines() if 'GAGAL' in l]
    ringkas = '%s/%s' % (m.group(1), m.group(2)) if m else 'tanpa ringkasan'
    status = 'MATI' if (not m or int(m.group(2)) > 0) else 'HIDUP'
    contoh = gagal[0][:200] if gagal else ''
    print('| %s | %s | %s %s | %s |' % (kode, label, ringkas, status, contoh))
    st = subprocess.run(['git', 'status', '--short'], capture_output=True, text=True).stdout
    print('   git status sesudah:', st.strip().replace('\n', '; ') or 'bersih')
    sys.stdout.flush()


if __name__ == '__main__':
    for k in (sys.argv[1:] or list(MUTAN)):
        jalankan(k)
