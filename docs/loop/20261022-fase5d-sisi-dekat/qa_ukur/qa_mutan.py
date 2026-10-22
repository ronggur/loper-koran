#!/usr/bin/env python3
import subprocess, sys, re, os
os.chdir('/Users/ronggur/Works/Games/Loper-Koran/apps/loper-koran')
def sub(f, old, new, count=1):
    s = open(f, encoding='utf-8').read()
    assert s.count(old) == count, (f, old, s.count(old))
    open(f, 'w', encoding='utf-8').write(s.replace(old, new))
M = {}
def m(i, f, old, new, desc, runner='godot', count=1):
    M[i] = (f, old, new, desc, runner, count)
m('Q1', 'scripts/systems/route_builder.gd', 'if j > Config.RUTE_PELANGGAN_JARAK_MAKS_UBIN:', 'if j >= Config.RUTE_PELANGGAN_JARAK_MAKS_UBIN:', 'periksa_rute: celah tepat 20 ditolak (> jadi >=)')
m('Q2', 'scripts/systems/route_builder.gd', '''		var indeks_dekat: PackedInt32Array = _cocokkan(maju_dekat, jumlah_dekat_dipilih, rng)
		var indeks_seberang: PackedInt32Array = _cocokkan(maju_seberang, jumlah_seberang, rng)''', '''		var indeks_seberang: PackedInt32Array = _cocokkan(maju_seberang, jumlah_seberang, rng)
		var indeks_dekat: PackedInt32Array = _cocokkan(maju_dekat, jumlah_dekat_dipilih, rng)''', 'urutan konsumsi RNG dekat/seberang tertukar (hari >= 3)')
m('Q3', 'scripts/systems/zona_sasaran.gd', 'Config.RUTE_RUMAH_DEKAT_X_UBIN + Config.RUTE_RUMAH_DALAM_UBIN / 2 + Config.RUTE_RUMAH_DEKAT_MUNDUR_UBIN', 'Config.RUTE_RUMAH_DEKAT_X_UBIN + Config.RUTE_RUMAH_DALAM_UBIN / 2', 'zona teras dekat tanpa mundur 0,5')
m('Q4', 'scripts/config.gd', 'const RUTE_DEKAT_KOTAK_SURAT_INTI_UBIN: Array[float] = [2.0, 1.625, 0.5, 0.5]', 'const RUTE_DEKAT_KOTAK_SURAT_INTI_UBIN: Array[float] = [2.25, 1.625, 0.5, 0.5]', 'inti tepat zona dekat bergeser 0,25')
m('Q5', 'scripts/systems/bantu_lempar.gd', 'return pa.y < pb.y', 'return pa.y > pb.y', 'bantu: pilih sasaran terjauh, bukan terdekat')
m('Q6', 'scripts/ui/hud_rute.gd', '_radar_dekat.sisi = LoperAnim.Sisi.DEKAT', '_radar_dekat.sisi = LoperAnim.Sisi.SEBERANG', 'radar: strip dekat memfilter sisi seberang')
m('Q7', 'scenes/ui/panel_tip_sisi_dekat.tscn', 'mouse_filter = 2', 'mouse_filter = 0', 'panel tip menelan sentuhan (semua mouse_filter 0)', count=5)
m('Q8', 'scripts/systems/penutup_pemain.gd', 'hasil = kotak if not ada else hasil.merge(kotak)', 'hasil = kotak', 'kotak penutup gabungan jenis dekat hanya jenis terakhir')
m('Q9', 'scripts/systems/segmen_rute.gd', 'salah = not (ada_seberang and ada_dekat)', 'salah = not (ada_seberang or ada_dekat)', 'validasi tag dua_sisi cukup salah satu sisi')
m('Q10', 'scripts/entities/hari_main.gd', '_rute.atur_hari(_mesin.hari)', '_rute.atur_hari(_mesin.hari + 1)', 'HariMain meneruskan hari + 1')
m('Q11', 'scripts/config.gd', 'const RUTE_DEKAT_HALAMAN_UBIN: Array[float] = [2.0, -0.5, 1.90625, 3.0]', 'const RUTE_DEKAT_HALAMAN_UBIN: Array[float] = [2.0, -1.0, 1.90625, 3.0]', 'halaman dekat mulai maju -1,0')
m('Q12', 'scripts/entities/rumah_daur_rute.gd', '''		if pembungkus != null:
			sprite.reparent(self, false)
''', '', 'terlipat tidak dikembalikan dari pembungkus saat dilepas (kebocoran induk)')
m('Q13', 'scripts/systems/route_builder.gd', 'if ada_dekat and (dekat < Config.RUTE_DEKAT_KUOTA_MIN or dekat > Config.RUTE_DEKAT_KUOTA_MAKS):', 'if ada_dekat and (dekat < Config.RUTE_DEKAT_KUOTA_MIN or dekat > Config.RUTE_DEKAT_KUOTA_MAKS + 1):', 'periksa_rute: kuota maks longgar 10')
m('Q14', 'scripts/systems/tip_sisi_dekat.gd', 'return is_finite(sisa_detik) and sisa_detik > Config.LEMPAR_TOLERANSI_DETIK', 'return is_finite(sisa_detik)', 'tip tampil selamanya (sisa 0 tetap tampil)')
m('Q15', 'scripts/systems/sprite_rumah.gd', 'return Vector2(lateral, -(rumah.maju_ubin + Config.JALAN_UJI_KOTAK_SURAT_MAJU_UBIN))', 'return Vector2(lateral, -(rumah.maju_ubin + Config.JALAN_UJI_KOTAK_SURAT_MAJU_UBIN + 0.25))', 'sprite kotak surat dekat/seberang bergeser maju 0,25 dari zona')
m('Q16', 'scripts/systems/medan_koran.gd', 'PenutupPemain.dari_rumah_gambar(_rumah[i])', 'PenutupPemain.dari_rumah(_rumah[i])', 'MedanKoran memakai tapak logika lagi untuk tertutup')
m('Q17', 'translations/ui.csv', 'RUTE_TIP_SISI_DEKAT,Mulai hari ini pelanggan ada di kedua sisi jalan', 'RUTE_TIP_SISI_DEKAT,Mulai hari ini pelanggan ada di kedua sisi jalan raya kota dan juga di seluruh gang kecil sekitarnya tanpa kecuali sama sekali', 'teks tip jauh lebih panjang (tata letak)')
m('Q18', 'scripts/entities/rute_main.gd', '_tip_sisa = TipSisiDekat.detik_awal(_hari)', '_tip_sisa = TipSisiDekat.detik_awal(_hari)\n\t\t_tip_sudah = false', '"Main lagi" mengisi ulang tip (tip_sudah dikembalikan)')
m('Q19', 'scripts/systems/zona_sasaran.gd', 'hasil[0].inti = _persegi(Config.RUTE_DEKAT_KOTAK_SURAT_INTI_UBIN, maju_awal_ubin)\n	for zona', 'for zona', 'zona kotak surat dekat tanpa inti (tak ada TEPAT di dekat)')
m('Q20', 'scripts/systems/route_builder.gd', 'var jumlah_dekat_dipilih: int = rng.randi_range(Config.RUTE_DEKAT_KUOTA_MIN, Config.RUTE_DEKAT_KUOTA_MAKS)', 'var jumlah_dekat_dipilih: int = rng.randi_range(Config.RUTE_DEKAT_KUOTA_MIN, Config.RUTE_DEKAT_KUOTA_MAKS) if rute.hari % 2 == 1 else Config.RUTE_DEKAT_KUOTA_MIN', 'kuota genap selalu 8 (sebaran bergantung hari, bukan seed)')
BASE = {'H': '1'}
ids = sys.argv[1:] or list(M)
for i in ids:
    f, old, new, desc, runner, count = M[i]
    sub(f, old, new, count)
    try:
        hasil = []
        for pil in ['B', 'A', 'S', 'R', 'H', 'K']:
            p = subprocess.run(['godot', '--headless', '--path', '.', '--script', 'res://build/qa_runner.gd', '--', pil], capture_output=True, text=True, timeout=900)
            out = p.stdout + p.stderr
            ring = re.findall(r'(\d+) lolos, (\d+) gagal', out)
            err = len(re.findall(r'SCRIPT ERROR|Parse Error', out))
            gagal = [l for l in out.splitlines() if l.startswith('GAGAL')]
            hasil.append((pil, ring[-1] if ring else None, err, gagal[:1]))
            if (ring and ring[-1][1] != BASE.get(pil,'0')) or not ring or err:
                break
        print(i, desc, '=>', 'TERTANGKAP' if any((r[1] is None) or r[1][1] != BASE.get(r[0],'0') or r[2] for r in hasil) else 'LOLOS', hasil, flush=True)
    finally:
        subprocess.run(['git', 'checkout', '--', f], check=True)
        st = subprocess.run(['git', 'status', '--short'], capture_output=True, text=True).stdout.strip().splitlines()
        print('  status:', [l for l in st if '.claude' not in l])
