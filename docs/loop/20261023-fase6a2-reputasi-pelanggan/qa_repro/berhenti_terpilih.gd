extends SceneTree
func _initialize() -> void:
	var pustaka: Array[SegmenRute] = PemuatRute.muat_folder("res://assets/data/routes/perumahan").segmen
	var kep: Array[KepribadianPelanggan.Entri] = PemuatPelanggan.muat().entri
	var ids: Array[String] = []
	for seg in pustaka:
		for rm in seg.rumah:
			if rm.pelanggan_boleh: ids.append("%s@%d" % [seg.id, rm.pos])
	var rng := RandomNumberGenerator.new(); rng.seed = 777
	for nberhenti in [0, 1, 2, 3, 5, 8]:
		for frac_setia in [0.0, 0.4, 0.8]:
			var viol := 0; var tot := 600
			for iter in range(tot):
				var pel := PelangganRute.new(); pel.kepribadian = kep
				var hari: int = rng.randi_range(5, 60)
				var sens: Array[String] = []
				for id in ids:
					if pel.kepribadian_dari(id) == "sensitif": sens.append(id)
				sens.shuffle()
				for id in ids:
					var st := "setia" if rng.randf() < frac_setia else "aktif"
					pel.pelanggan[id] = {"status": st, "antar": 5, "meleset": 0, "hari_berhenti": 0}
				for i in range(mini(nberhenti, sens.size())):
					pel.pelanggan[sens[i]] = {"status": "berhenti", "antar": 0, "meleset": 2, "hari_berhenti": hari - 1}  # bukan calon
				var h := RouteBuilder.bangun(rng.randi(), pustaka, hari, pel)
				if not h.sah(): print("GAGAL"); continue
				for p in h.rute.pelanggan:
					if pel.status(p.id) == "berhenti": viol += 1; break
			print("berhenti=", nberhenti, " setia=", frac_setia, " rute dengan berhenti terpilih ", viol, "/", tot)
	quit()
