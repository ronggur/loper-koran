import subprocess,sys,json,os
R='/Users/ronggur/Works/Games/Loper-Koran/apps/loper-koran'
M=[
("M01 benih hiasan konstan 0","scripts/systems/hiasan_rute.gd","rng.seed = rute.benih + Config.RUTE_HIASAN_SEED_SELISIH","rng.seed = 0"),
("M02 panjang hiasan 20","scripts/config.gd","const RUTE_HIASAN_PANJANG_UBIN: int = 32","const RUTE_HIASAN_PANJANG_UBIN: int = 20"),
("M03 laju keluar 3,0","scripts/config.gd","const RUTE_KELUAR_LAJU_MIN_UD: float = 6.0","const RUTE_KELUAR_LAJU_MIN_UD: float = 3.0"),
("M04 lelah tidak dipadamkan","scripts/systems/akhir_rute.gd","\tbaru.lelah = false\n","\tbaru.lelah = baru.lelah\n"),
("M05 stamina tidak dikembalikan","scripts/systems/akhir_rute.gd","\t\tbaru.stamina = minf(stamina_garis, Config.STAMINA_MAKS)\n","\t\tbaru.stamina = baru.stamina\n"),
("M06 efek kondisi tidak dilepas","scripts/entities/rute_main.gd","return null if _selesai else super()","return super()"),
("M07 hiasan masuk Rute.pelanggan","scripts/systems/hiasan_rute.gd","\t\t\thiasan.rumah.append(rumah)\n","\t\t\thiasan.rumah.append(rumah)\n\t\t\tif r.pelanggan_boleh:\n\t\t\t\thiasan.pelanggan.append(rumah)\n"),
("M08 hiasan tidak dibangun ulang saat disusun","scripts/entities/rute_main.gd","_hiasan = HiasanRute.bangun(_rute, _pustaka) if not gagal else RouteBuilder.Rute.new()","_hiasan = HiasanRute.bangun(_rute, _pustaka) if (not gagal and _hiasan.panjang_ubin == 0.0) else _hiasan"),
("M09 R-5 tinggi tinta angka 15","scripts/config.gd","const HASIL_REPUTASI_TINTA_ANGKA_PX: int = 17","const HASIL_REPUTASI_TINTA_ANGKA_PX: int = 15"),
("M10 R-6 tip jadi kuning","scripts/ui/palette.gd",'const RADAR_TIP: Color = Color("#56C46E")','const RADAR_TIP: Color = Color("#FFF200")'),
("M11 R-7 garis bar geser 1 px","scripts/systems/tampil_hud.gd","\tvar tengah: int = tinggi_bar / 2\n","\tvar tengah: int = tinggi_bar / 2 + 1\n"),
("M12 R-1 pad kanan glif diabaikan","scripts/ui/gaya_hud.gd","return maxi(tombol.icon.get_width() - terpakai.end.x, 0)","return 0"),
("M13 R-3 sumbu radar geser 1 px","scripts/systems/radar_rute.gd","\tvar tengah: int = lebar_strip / 2\n","\tvar tengah: int = lebar_strip / 2 + 1\n"),
("M14 stamina garis diisi penuh","scripts/entities/rute_main.gd","_stamina_garis = _sepeda.stamina()","_stamina_garis = Config.STAMINA_MAKS"),
("M15 dekor hiasan tanpa penerap","scripts/entities/rute_main.gd","\t_dekor_hiasan.penerap = _penerap\n","\t_dekor_hiasan.penerap = null\n"),
("M16 hiasan mulai 5 ubin sesudah garis","scripts/systems/hiasan_rute.gd","\tvar awal: float = rute.panjang_ubin\n","\tvar awal: float = rute.panjang_ubin + 5.0\n"),
("M17 hiasan boleh dua padat berurutan","scripts/systems/hiasan_rute.gd","if not longgar and sebelumnya != null and calon.tingkat","if false and sebelumnya != null and calon.tingkat"),
("M18 lateral dekor hiasan 0","scripts/systems/hiasan_rute.gd","butir.lateral_ubin = DekorRute.lateral(d.jenis, d.sisi)","butir.lateral_ubin = 0.0"),
("M19 R-2 baris tidak diratakan","scripts/ui/layar_hasil.gd","\t_ratakan_baseline(hasil.label, hasil.nilai)\n","\t\n"),
("M20 stamina garis tidak diteruskan","scripts/entities/rute_main.gd","AkhirRute.keadaan_dijaga(_sepeda.keadaan, _stamina_garis)","AkhirRute.keadaan_dijaga(_sepeda.keadaan)"),
]
def run(subset=True):
    script='res://tests/qa2_subset.gd' if subset else 'res://tests/run_tests.gd'
    p=subprocess.run(['godot','--headless','--script',script],cwd=R,capture_output=True,text=True,timeout=1500)
    open(R+'/build/mut.log','w').write(p.stdout+p.stderr)
    c=subprocess.run(['python3','tools/cek_keluaran_tes.py','build/mut.log'],cwd=R,capture_output=True,text=True)
    return c.returncode, (c.stdout+c.stderr).strip().split('\n')[0][:200]
sel=sys.argv[1:] 
for nama,f,a,b in M:
    if sel and nama.split()[0] not in sel: continue
    path=os.path.join(R,f); s=open(path).read()
    if s.count(a)!=1:
        print(nama,'TIDAK VALID: kemunculan',s.count(a)); continue
    open(path,'w').write(s.replace(a,b))
    try:
        rc,msg=run(os.environ.get("QA_FULL")!="1")
    finally:
        subprocess.run(['git','checkout','--',f],cwd=R)
    print(nama,'TERTANGKAP' if rc!=0 else 'LOLOS(subset)',msg,flush=True)
