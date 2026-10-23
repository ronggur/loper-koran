extends SceneTree
# QA iter2: golden sendiri. args: out [pakai_null]
func _ident(rute) -> String:
	var b: Array[String] = []
	b.append("panjang=%d;koran=%d;hari=%d" % [int(rute.panjang_ubin), rute.koran_awal, rute.hari])
	var ids: Array[String] = []
	for s in rute.segmen: ids.append(s.id)
	b.append("S=" + ",".join(ids))
	var pel: Array[String] = []
	for p in rute.pelanggan: pel.append(p.id)
	b.append("P=" + ",".join(pel))
	var tip: Array = rute.id_pemberi_tip.keys(); tip.sort()
	b.append("T=" + ",".join(PackedStringArray(tip)))
	var ob: Array[String] = []
	for o in rute.objek: ob.append("%s@%s@%d@%s" % [o.jenis, o.id_segmen, int(o.maju_ubin), o.jalur])
	b.append("O=" + ";".join(ob))
	var ms: Array[String] = []
	for t in rute.titik_misi: ms.append("%s@%d@%d" % [t.nama, int(t.maju_ubin), t.sisi])
	b.append("M=" + ";".join(ms))
	var dk: Array[String] = []
	for d in rute.dekor: dk.append(d.id)
	b.append("D=" + ",".join(dk))
	var rm: Array[String] = []
	for r in rute.rumah: rm.append("%s:%d:%s:%s:%s" % [r.id, int(r.maju_ubin), r.jenis, str(r.pelanggan), str(r.pemberi_tip)])
	b.append("R=" + ",".join(rm))
	return "\n".join(b)
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0]
	var mode: String = args[1]  # main | null | kosong
	var pustaka: Array[SegmenRute] = PemuatRute.muat_folder("res://assets/data/routes/perumahan").segmen
	var f := FileAccess.open(out, FileAccess.WRITE)
	var rng := RandomNumberGenerator.new(); rng.seed = 31337
	var t0 := Time.get_ticks_msec()
	for h in [1, 2]:
		for i in range(150):
			var s: int = rng.randi()
			var hasil
			if mode == "main": hasil = RouteBuilder.bangun(s, pustaka, h)
			elif mode == "null": hasil = RouteBuilder.bangun(s, pustaka, h, null)
			else:
				var pel := PelangganRute.new()
				var r2 := RandomNumberGenerator.new(); r2.seed = s
				var profil: int = r2.randi_range(0, 3)
				for seg in pustaka:
					for rm in seg.rumah:
						var st: String = ["aktif","setia","berhenti","berhenti"][r2.randi_range(0,3)] if profil < 3 else "berhenti"
						pel.pelanggan["%s@%d" % [seg.id, rm.pos]] = {"status": st, "antar": 3, "meleset": 1, "hari_berhenti": 0}
				hasil = RouteBuilder.bangun(s, pustaka, h, pel)
			f.store_line("%d/%d %s" % [s, h, _ident(hasil.rute) if hasil.sah() else "GALAT"])
	f.close()
	print("ms ", Time.get_ticks_msec() - t0)
	quit()
