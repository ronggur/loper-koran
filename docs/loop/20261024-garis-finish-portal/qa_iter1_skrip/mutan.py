import subprocess, sys, time, json, os
WT = os.path.dirname(os.path.abspath(__file__)) + '/qa_mut'
M = [
 ("M01 hampir_ubin 6->0.5", "scripts/config.gd", "const RUTE_KELUAR_HAMPIR_UBIN: float = 6.0", "const RUTE_KELUAR_HAMPIR_UBIN: float = 0.5"),
 ("M02 portal buka 6->60", "scripts/config.gd", "const RUTE_PORTAL_BUKA_JARAK_UBIN: float = 6.0", "const RUTE_PORTAL_BUKA_JARAK_UBIN: float = 60.0"),
 ("M03 laju min 3->0.5", "scripts/config.gd", "const RUTE_KELUAR_LAJU_MIN_UD: float = 3.0", "const RUTE_KELUAR_LAJU_MIN_UD: float = 0.5"),
 ("M04 sisa_ubin tanda kiri_px", "scripts/systems/akhir_rute.gd", "(posisi_layar_pijak_px.x - kiri_px)", "(posisi_layar_pijak_px.x + kiri_px)"),
 ("M05 portal_terbuka <= jadi <", "scripts/systems/akhir_rute.gd", "return sisa <= Config.RUTE_PORTAL_BUKA_JARAK_UBIN", "return sisa < Config.RUTE_PORTAL_BUKA_JARAK_UBIN"),
 ("M06 siap_tampil abaikan koran terbang", "scripts/systems/hasil_rute.gd", "if not k.mendarat:", "if false:"),
 ("M07 portal diperbarui jarak 0", "scripts/entities/rute_main.gd", "\t_portal.perbarui(_sepeda.jarak_ubin)\n", "\t_portal.perbarui(0.0)\n"),
 ("M08 bel diizinkan selalu", "scripts/entities/rute_main.gd", "func _bel_diizinkan() -> bool:\n\treturn not _selesai", "func _bel_diizinkan() -> bool:\n\treturn true"),
 ("M09 kamera_beku tak direset di kembalikan_awal", "scripts/entities/adegan_jalan.gd", "\t_kamera_beku = false\n\t_koran_tanah", "\t_koran_tanah"),
 ("M10 set_process_input(true) dihapus di _susun", "scripts/entities/rute_main.gd", "\t_kontrol.set_process_input(true)\n", "\tpass\n"),
 ("M11 _hampir_keluar tidak direset", "scripts/entities/rute_main.gd", "\t_fase = AkhirRute.Fase.SEBELUM\n\t_hampir_keluar = false\n", "\t_fase = AkhirRute.Fase.SEBELUM\n"),
 ("M12 banner muncul saat sudah keluar", "scripts/entities/rute_main.gd", "if keluar.baru_hampir_keluar:", "if keluar.baru_keluar:"),
 ("M13 tutorial tidak beku", "scripts/entities/rute_main.gd", "if _tutorial == null or _selesai:", "if _tutorial == null:"),
 ("M14 rintangan aktif sesudah garis", "scripts/entities/adegan_jalan.gd", "if not _rintangan_aktif():", "if false:"),
 ("M15 hampir_keluar <= jadi <", "scripts/systems/akhir_rute.gd", "return sisa_ubin <= Config.RUTE_KELUAR_HAMPIR_UBIN", "return sisa_ubin < Config.RUTE_KELUAR_HAMPIR_UBIN"),
 ("M16 tinggi penutup portal 1.78->0.5", "scripts/config.gd", "const RUTE_PORTAL_TINGGI_UBIN: float = 1.78125", "const RUTE_PORTAL_TINGGI_UBIN: float = 0.5"),
 ("M17 lateral portal -2 -> 2", "scripts/config.gd", "const RUTE_PORTAL_LATERAL_UBIN: float = -2.0", "const RUTE_PORTAL_LATERAL_UBIN: float = 2.0"),
 ("M18 bunyi sepeda tidak senyap saat hasil", "scripts/entities/rute_main.gd", "func _sepeda_senyap() -> bool:\n\treturn _hasil_tampil", "func _sepeda_senyap() -> bool:\n\treturn false"),
 ("M19 jarak dunia ikut sepeda", "scripts/entities/rute_main.gd", "return _jarak_beku if _selesai else _sepeda.jarak_ubin", "return _sepeda.jarak_ubin"),
 ("M20 badan kiri 18->0", "scripts/config.gd", "const RUTE_KELUAR_BADAN_KIRI_PX: int = 18", "const RUTE_KELUAR_BADAN_KIRI_PX: int = 0"),
 ("M21 lempar diizinkan selalu", "scripts/entities/rute_main.gd", "func _lempar_diizinkan() -> bool:\n\treturn not _selesai", "func _lempar_diizinkan() -> bool:\n\treturn true"),
 ("M22 stick sungguhan terbaca sesudah garis", "scripts/entities/rute_main.gd", "\t\treturn AkhirRute.stick_keluar()\n\treturn super()", "\treturn super()"),
 ("M23 laju dijaga tidak diterapkan", "scripts/entities/rute_main.gd", "\t\t_sepeda.keadaan = AkhirRute.keadaan_dijaga(_sepeda.keadaan)", "\t\tpass"),
 ("M24 kamera tidak dibekukan", "scripts/entities/rute_main.gd", "\t\t_bekukan_kamera()\n", "\t\tpass\n"),
 ("M25 portal dihapus dari penerap saat atur_rute", "scripts/entities/portal_garis.gd", "\t\tpenerap.daftarkan(self, kotak_penutup(panjang_ubin))\n", "\t\tpass\n"),
 ("M26 frame portal terbalik", "scripts/systems/akhir_rute.gd", "return 1 if portal_terbuka(jarak_ubin, panjang_ubin) else 0", "return 0 if portal_terbuka(jarak_ubin, panjang_ubin) else 1"),
]
sel = sys.argv[1:] 
hasil = []
for nama, f, old, new in M:
    if sel and nama[:3] not in sel: continue
    p = os.path.join(WT, f)
    s = open(p).read()
    if s.count(old) != 1:
        hasil.append((nama, "TIDAK_VALID count=%d" % s.count(old))); print(nama, hasil[-1][1], flush=True); continue
    open(p, 'w').write(s.replace(old, new))
    t0 = time.time()
    try:
        log = os.path.join(WT, 'build', 'mut.log')
        os.makedirs(os.path.dirname(log), exist_ok=True)
        with open(log, 'w') as fh:
            r = subprocess.run(['godot', '--headless', '--script', 'res://tests/run_tests.gd'], cwd=WT, stdout=fh, stderr=subprocess.STDOUT, timeout=1200)
        rc = r.returncode
    except subprocess.TimeoutExpired:
        rc = 'timeout'
    pc = subprocess.run(['python3', 'tools/cek_keluaran_tes.py', log], cwd=WT, capture_output=True, text=True)
    tertangkap = (rc != 0) or (pc.returncode != 0)
    ket = pc.stdout.strip().splitlines()[-1] if pc.stdout.strip() else pc.stderr.strip()[-100:]
    hasil.append((nama, "TERTANGKAP" if tertangkap else "LOLOS", rc, ket[:120], int(time.time() - t0)))
    print(hasil[-1], flush=True)
    subprocess.run(['git', 'checkout', '--', f], cwd=WT)
json.dump(hasil, open(os.path.join(os.path.dirname(WT), 'mutan_hasil.json'), 'w'), indent=1)
