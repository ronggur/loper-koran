"""Mutan nyata bagian CD run 5C: satu perubahan di kode/data/aset asli, tes penuh (Godot + pemeriksa) atau uji Python terkait, lalu git checkout.
Pakai: python3 docs/loop/20261022-fase5c-animasi-simpang/dev_ukur/mutan_cd.py [kode...]"""
import subprocess, re, sys, json
R = '/Users/ronggur/Works/Games/Loper-Koran/apps/loper-koran'
G = 'godot'
PY_SIMPANG = 'python3 tools/tests_cek/uji_aset_simpang.py'
UK = 'scripts/systems/ubin_khusus.gd'
SR = 'scripts/systems/segmen_rute.gd'
RB = 'scripts/systems/route_builder.gd'
TD = 'scripts/entities/tanah_daur.gd'
M = [
("C1", UK, "return baris_masuk_rute.has(baris - Config.RUTE_UJUNG_KERB_BARIS_RELATIF) and not baris_masuk_rute.has(baris)", "return baris_masuk_rute.has(baris + Config.RUTE_UJUNG_KERB_BARIS_RELATIF) and not baris_masuk_rute.has(baris)", "ujung kerb di baris salah (maju - 1)", G),
("C2", UK, "\t\t\tif masuk:\n\t\t\t\treturn Ubin.MASUK\n\t\t\tif ujung:\n\t\t\t\treturn Ubin.UJUNG\n\t\tJalanDaur.Kolom.RUMPUT_DEKAT:", "\t\t\tif masuk:\n\t\t\t\treturn Ubin.MASUK\n\t\tJalanDaur.Kolom.RUMPUT_DEKAT:", "ujung kerb hanya di trotoar (kolom rumput pertama lupa)", G),
("C3", UK, "\t\tJalanDaur.Kolom.TROTOAR_DEKAT:\n\t\t\tif not masuk and simbol_di_baris(baris):", "\t\tJalanDaur.Kolom.TROTOAR_DEKAT:\n\t\t\tif ujung:\n\t\t\t\treturn Ubin.UJUNG\n\t\t\tif not masuk and simbol_di_baris(baris):", "ujung kerb juga di sisi dekat", G),
("C4", TD, "_tekstur_khusus.has(NAMA_UJUNG_TROTOAR_SEBERANG)), _dinamis_x[i]", "false), _dinamis_x[i]", "TanahDaur tidak pernah memasang ujung kerb", G),
("C5", "scripts/config.gd", "const RUTE_UJUNG_KERB_BARIS_RELATIF: int = 1", "const RUTE_UJUNG_KERB_BARIS_RELATIF: int = -1", "konstanta ujung kerb salah", G),
("D1", SR, "if bentuk.position.y >= pita.y or bentuk.end.y <= pita.x:", "if bentuk.position.y > pita.y or bentuk.end.y < pita.x:", "batas pita < jadi <= (sentuh ditolak)", G),
("D2", SR, "\t\tif memotong_pita(pita, sisi, kavling_rumah(r.sisi, float(r.pos))):", "\t\tif false and memotong_pita(pita, sisi, kavling_rumah(r.sisi, float(r.pos))):", "penolakan kavling rumah dilepas", G),
("D3", SR, "\t\tbentuk = bentuk.merge(Rect2(Config.RUTE_TEMBOK_X_UBIN, pos_rumah, 0.0, Config.RUTE_RUMAH_PANJANG_UBIN))", "\t\tbentuk = bentuk", "kavling tanpa tembok", G),
("D4", SR, "if d.sisi != LoperAnim.Sisi.TIDAK_ADA and DekorRute.indeks_jenis(d.jenis) >= 0 and memotong_pita", "if false and memotong_pita", "penolakan dekor dilepas", G),
("D5", SR, "\t\tif memotong_pita(pita, sisi, bentuk_rintangan_diam(o.jenis, float(o.pos), sisi_objek)):", "\t\tif false:", "penolakan rintangan dilepas", G),
("D6", SR, "if o.jenis == \"mobil_garasi\" and sisi_objek == LoperAnim.Sisi.SEBERANG and memotong_pita", "if false and memotong_pita", "penolakan jalan masuk dilepas", G),
("D7", SR, "if ada_panjang and (pita.x < 0.0 or pita.y > float(segmen.panjang)):", "if false:", "penolakan pita di luar segmen dilepas", G),
("D8", SR, "\t\t\t\tif pita_bertumpuk(pita, pita_maju(float(lain.pos))):", "\t\t\t\tif false:", "penolakan dua pita bertumpuk dilepas", G),
("D9", SR, "\t\tif d.has(\"sisi\") and not nama_sisi.is_empty() and item.sisi == LoperAnim.Sisi.TIDAK_ADA:\n\t\t\tg.append(\"%s: sisi '%s' bukan seberang atau dekat (GDD 4.2)\" % [nama, nama_sisi])\n\t\tvar ok_pos", "\t\tvar ok_pos", "sisi tidak dikenal tidak ditolak", G),
("D10", SR, "\t\t_tolak_field_asing(d, _FIELD_SIMPANG, nama, g)\n", "", "field asing simpang tidak ditolak", G),
("D11", SR, "\t\telif not _bulat(d[\"pos\"]):\n\t\t\tg.append(\"%s: 'pos' harus bilangan bulat ubin\" % nama)\n\t\telse:\n\t\t\tok_pos = true\n\t\t\titem.pos", "\t\telif _bulat(d[\"pos\"]) and false:\n\t\t\tg.append(\"%s: 'pos' harus bilangan bulat ubin\" % nama)\n\t\telse:\n\t\t\tok_pos = true\n\t\t\titem.pos", "pos bukan bilangan bulat diterima", G),
("D12", RB, "\t_isi_segmen(rute, urutan)\n", "\t_isi_segmen(rute, urutan)\n\trng.randi_range(0, rute.simpang.size())\n", "simpang ikut memakai RNG rute (mengubah rute dari seed)", G),
("D13", RB, "\t\t\titem.maju_ubin = awal + float(sp.pos)\n", "\t\t\titem.maju_ubin = float(sp.pos)\n", "maju simpang tidak mutlak", G),
("D14", UK, "\tif sisi_sel != entri.x:\n\t\treturn TANPA_SIMPANG\n", "", "ubin simpang di sisi salah juga", G),
("D15", UK, "\treturn KolomSimpang.LENGAN if JalanDaur.rumput_luar(x) else KolomSimpang.RUMPUT", "\treturn KolomSimpang.LENGAN if JalanDaur.rumput_luar(x) and absf(x) < Config.LAYAR_LEBAR_MAKS_PX / Config.UBIN_LEBAR_PX else KolomSimpang.RUMPUT", "lengan tidak diulang sampai kolom terjauh", G),
("D16", UK, "\t\tvar dasar: int = roundi(item.maju_ubin)\n", "\t\tvar dasar: int = roundi(item.maju_ubin) + 1\n", "ubin simpang di baris salah (geser 1)", G),
("D17", TD, "\tif mode_simpang(LoperAnim.Sisi.DEKAT if x >= 0.0 else LoperAnim.Sisi.SEBERANG):\n\t\treturn true\n", "", "kolom aspal dan rumput dekat tidak bisa berganti (mulut aspal hilang)", G),
("D18", "scripts/config.gd", "const RUTE_SIMPANG_PITA_BARIS: Array[int] = [-1, 3]", "const RUTE_SIMPANG_PITA_BARIS: Array[int] = [-1, 2]", "pita terlalu pendek", G),
("D19", "tools/env_art/ubin_perumahan.py", "SIMPANG_SISI_DIPASANG = ['dekat']", "SIMPANG_SISI_DIPASANG = ['dekat', 'seberang']", "ubin simpang seberang yang tidak dipakai ikut tersalin", PY_SIMPANG),
("D20", "assets/sprites/tiles/perumahan/tile_perumahan_simpang_dekat_lengan_mulut_1.png.import", "compress/mode=0\n", "compress/mode=2\n", ".import ubin simpang bukan Lossless", PY_SIMPANG),
("D21", SR, "\t\t\t\tg.append(\"%s: pita %.1f sampai %.1f memotong zona %s rumah %s di pos %d\" % [nama, pita.x, pita.y, ZonaSasaran.Jenis.keys()[zona.jenis], nama_sisi_rumah, r.pos])", "\t\t\t\tpass", "penolakan zona dilepas (dugaan ekuivalen: zona di dalam kavling)", G),
# Sisi seberang (putusan P-6)
("S1", UK, "\t\treturn Config.RUTE_SIMPANG_SEL_SEBERANG\n", "\t\treturn Config.RUTE_SIMPANG_SEL_DEKAT\n", "sisi seberang memakai tabel sel dekat", G),
("S2", "scripts/config.gd", "const RUTE_SIMPANG_SEL_SEBERANG: Array[int] = [3, 2, 3, 3,", "const RUTE_SIMPANG_SEL_SEBERANG: Array[int] = [3, 1, 3, 3,", "sel seberang pertama di kolom salah (trotoar, bukan rumput)", G),
("S3", "scenes/rute/rute.tscn", 'ExtResource("56_simpang_seberang_0"), ExtResource("57_simpang_seberang_1")', 'ExtResource("57_simpang_seberang_1"), ExtResource("56_simpang_seberang_0")', "dua tekstur seberang tertukar di rute.tscn", G),
("S4", "assets/data/routes/perumahan/per_buka_02.json", '{ "pos": 18, "sisi": "seberang" }', '{ "pos": 17, "sisi": "seberang" }', "simpang seberang bergeser satu ubin (pita memotong kavling rumah @14)", G),
("S5", "tools/env_art/ubin_perumahan.py", "SIMPANG_SISI_DIPASANG = ['dekat', 'seberang']", "SIMPANG_SISI_DIPASANG = ['dekat']", "ubin seberang yang dipakai data tidak tersalin", PY_SIMPANG),
]
pilih = sys.argv[1:]
for kode, f, a, b, ket, perintah in M:
    if pilih and kode not in pilih:
        continue
    p = R + '/' + f; s = open(p).read()
    assert s.count(a) == 1, (kode, s.count(a))
    open(p, 'w').write(s.replace(a, b))
    if perintah == G:
        subprocess.run('godot --headless --script res://tests/run_tests.gd > build/mutan.log 2>&1', shell=True, cwd=R)
        log = open(R + '/build/mutan.log', errors='replace').read()
        cek = subprocess.run('python3 tools/cek_keluaran_tes.py build/mutan.log', shell=True, cwd=R, capture_output=True, text=True).stdout.strip()
        ring = re.findall(r'(\d+) lolos, (\d+) gagal', log)
        gagal = [l[:160] for l in log.splitlines() if 'GAGAL' in l][:3]
        err = len(re.findall('SCRIPT ERROR', log))
        hasil = dict(ringkas=ring[-1] if ring else None, script_error=err, pemeriksa=cek.splitlines()[-1] if cek else '', gagal=gagal)
    else:
        h = subprocess.run(perintah, shell=True, cwd=R, capture_output=True, text=True)
        hasil = dict(exit=h.returncode, gagal=[l[:160] for l in h.stdout.splitlines() if 'GAGAL' in l][:3], ringkas=h.stdout.strip().splitlines()[-1] if h.stdout.strip() else h.stderr[-200:])
    subprocess.run(['git', 'checkout', '--', f], cwd=R)
    st = subprocess.run(['git', 'status', '--short'], cwd=R, capture_output=True, text=True).stdout.strip()
    print(json.dumps(dict(kode=kode, file=f, ket=ket, status=st, **hasil), ensure_ascii=False), flush=True)
