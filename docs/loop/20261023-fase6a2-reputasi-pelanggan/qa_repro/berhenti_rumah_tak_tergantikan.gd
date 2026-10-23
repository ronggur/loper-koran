extends SceneTree
func _initialize() -> void:
	var pustaka: Array[SegmenRute] = PemuatRute.muat_folder("res://assets/data/routes/perumahan").segmen
	var kep: Array[KepribadianPelanggan.Entri] = PemuatPelanggan.muat().entri
	var ids: Array[String] = []
	for seg in pustaka:
		for rm in seg.rumah:
			if rm.pelanggan_boleh: ids.append("%s@%d" % [seg.id, rm.pos])
	var rng := RandomNumberGenerator.new(); rng.seed = 91
	var n := 0
	for iter in range(3000):
		var hari: int = 10
		var benih: int = rng.randi()
		var base := RouteBuilder.bangun(benih, pustaka, hari, null)
		if not base.sah(): continue
		# berhenti = satu rumah yang ada di rute dasar
		var pick: String = base.rute.pelanggan[rng.randi_range(0, 24)].id
		var pel := PelangganRute.new(); pel.kepribadian = kep
		for id in ids: pel.pelanggan[id] = {"status": "aktif", "antar": 1, "meleset": 0, "hari_berhenti": 0}
		pel.pelanggan[pick] = {"status": "berhenti", "antar": 0, "meleset": 2, "hari_berhenti": hari - 1}
		var h := RouteBuilder.bangun(benih, pustaka, hari, pel)
		var chosen := false
		for p in h.rute.pelanggan: if p.id == pick: chosen = true
		if chosen:
			n += 1
			if n <= 5: print("benih ", benih, " pick ", pick, " pelepasan ", h.rute.pelepasan, " dekat ", h.rute.pelanggan.size())
	print("dipilih meski berhenti (rumah di rute dasar): ", n, "/3000")
	quit()
