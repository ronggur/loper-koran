extends SceneTree
# QA: identitas lengkap rute (teks penuh) untuk seed/hari. Mode via argumen: main | null | kosong (HEAD keadaan kosong) | keadaan
func _ident(rute: RouteBuilder.Rute) -> String:
	var b: Array[String] = []
	b.append("panjang=%d;koran=%d;tenggat=%s;hari=%d" % [int(rute.panjang_ubin), rute.koran_awal, str(TenggatRute.awal(rute.panjang_ubin).tenggat_detik), rute.hari])
	var ids: Array[String] = []
	for s: SegmenRute in rute.segmen: ids.append(s.id)
	b.append("S=" + ",".join(ids))
	var pel: Array[String] = []
	for p: RouteBuilder.RumahRute in rute.pelanggan: pel.append(p.id)
	b.append("P=" + ",".join(pel))
	var tip: Array = rute.id_pemberi_tip.keys(); tip.sort()
	b.append("T=" + ",".join(PackedStringArray(tip)))
	var ob: Array[String] = []
	for o: RouteBuilder.ObjekRute in rute.objek: ob.append("%s@%s@%d@%s" % [o.jenis, o.id_segmen, int(o.maju_ubin), o.jalur])
	b.append("O=" + ";".join(ob))
	var ms: Array[String] = []
	for t: RouteBuilder.TitikMisiRute in rute.titik_misi: ms.append("%s@%d@%d" % [t.nama, int(t.maju_ubin), t.sisi])
	b.append("M=" + ";".join(ms))
	var dk: Array[String] = []
	for d: RouteBuilder.DekorItem in rute.dekor: dk.append(d.id)
	b.append("D=" + ",".join(dk))
	var rm: Array[String] = []
	for r: RouteBuilder.RumahRute in rute.rumah: rm.append("%s:%d:%s:%s:%s" % [r.id, int(r.maju_ubin), r.jenis, str(r.pelanggan), str(r.pemberi_tip)])
	b.append("R=" + ",".join(rm))
	return "\n".join(b)

func _initialize() -> void:
	var mode: String = OS.get_cmdline_user_args()[0]
	var out: String = OS.get_cmdline_user_args()[1]
	var pustaka: Array[SegmenRute] = PemuatRute.muat_folder("res://assets/data/routes/perumahan").segmen
	var f: FileAccess = FileAccess.open(out, FileAccess.WRITE)
	var rng := RandomNumberGenerator.new(); rng.seed = 987654321
	var seeds: Array[int] = []
	for i in range(1, 41): seeds.append(i * 104729)
	for i in range(40): seeds.append(rng.randi())
	var hari_list: Array[int] = [1, 2, 3, 4, 7, 12]
	if mode == "main" or mode == "null":
		for h in hari_list:
			for s in seeds:
				var hasil := RouteBuilder.bangun(s, pustaka, h)
				f.store_line("%d/%d %s" % [s, h, _ident(hasil.rute) if hasil.sah() else "GALAT"])
	quit()
