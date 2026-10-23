extends SceneTree
func _initialize() -> void:
	var pustaka: Array[SegmenRute] = PemuatRute.muat_folder("res://assets/data/routes/perumahan").segmen
	var kep: Array[KepribadianPelanggan.Entri] = PemuatPelanggan.muat().entri
	var ids: Array[String] = []
	var seg_ids: Dictionary = {}
	for seg in pustaka:
		seg_ids[seg.id] = []
		for rm in seg.rumah:
			if rm.pelanggan_boleh:
				var id := "%s@%d" % [seg.id, rm.pos]
				ids.append(id); seg_ids[seg.id].append(id)
	var rng := RandomNumberGenerator.new(); rng.seed = 424242
	var N: int = int(OS.get_cmdline_user_args()[0])
	var nama := ["semua_berhenti", "campur_acak", "realistis_sensitif", "lubang_segmen", "separuh_berhenti", "berhenti+kembali"]
	for profil in range(6):
		var gagal := 0; var salah_ukuran := 0; var salah_dekat := 0; var salah_celah := 0; var terpaksa := 0; var tak_tercatat := 0; var bocor := 0
		var tot_terpaksa := 0; var maxms := 0.0; var summs := 0.0; var salah_periksa := 0
		for iter in range(N):
			var pel := PelangganRute.new(); pel.kepribadian = kep
			var hari: int = rng.randi_range(3, 80)
			var sens: Array[String] = []
			for id in ids:
				if pel.kepribadian_dari(id) == "sensitif": sens.append(id)
			for id in ids:
				var st: String = ["aktif", "setia", "baru"][rng.randi_range(0, 2)]
				if st == "baru": continue
				pel.pelanggan[id] = {"status": st, "antar": 5, "meleset": 0, "hari_berhenti": 0}
			var berhenti_set: Array[String] = []
			match profil:
				0: berhenti_set.assign(ids)
				1:
					for id in ids:
						if rng.randf() < 0.35: berhenti_set.append(id)
				2:
					sens.shuffle()
					berhenti_set.assign(sens.slice(0, rng.randi_range(0, sens.size())))
				3:
					var keys := seg_ids.keys()
					var sg: String = keys[rng.randi_range(0, keys.size() - 1)]
					berhenti_set.assign(seg_ids[sg])
				4:
					for id in ids:
						if rng.randf() < 0.5: berhenti_set.append(id)
				5:
					for id in ids:
						if rng.randf() < 0.5: berhenti_set.append(id)
			for id in berhenti_set:
				var hb: int = hari - 1
				if profil == 5 and rng.randf() < 0.3: hb = hari - 3 - rng.randi_range(0, 5)
				pel.pelanggan[id] = {"status": "berhenti", "antar": 0, "meleset": 2, "hari_berhenti": hb}
			var t0 := Time.get_ticks_usec()
			var h := RouteBuilder.bangun(rng.randi(), pustaka, hari, pel)
			var ms := (Time.get_ticks_usec() - t0) / 1000.0
			maxms = maxf(maxms, ms); summs += ms
			if not h.sah(): gagal += 1; continue
			var r = h.rute
			if r.pelanggan.size() != 25: salah_ukuran += 1
			var nd := 0
			for p in r.pelanggan: if p.sisi == LoperAnim.Sisi.DEKAT: nd += 1
			if nd < 8 or nd > 9: salah_dekat += 1
			var xs: Array[float] = []
			for p in r.pelanggan: xs.append(p.maju_ubin)
			xs.sort()
			for i in range(1, xs.size()):
				if xs[i] - xs[i - 1] > Config.RUTE_PELANGGAN_JARAK_MAKS_UBIN + 0.0001: salah_celah += 1; break
			if not RouteBuilder.periksa_rute(r).is_empty(): salah_periksa += 1
			var nyata: Array[String] = []
			for p in r.pelanggan:
				if pel.status(p.id) == "berhenti" and not pel.calon_kembali(p.id, hari): nyata.append(p.id)
			var tercatat: Array = r.get("berhenti_terpaksa") if r.get("berhenti_terpaksa") != null else []
			if not nyata.is_empty(): terpaksa += 1; tot_terpaksa += nyata.size()
			for id in nyata: if not tercatat.has(id): tak_tercatat += 1
			for id in tercatat: if not nyata.has(id): bocor += 1
		print("%s N=%d gagal=%d ukuran!=25:%d dekat!=8-9:%d celah>20:%d periksa:%d | rute_dg_berhenti_terpaksa=%d (rumah %d) tak_tercatat=%d tercatat_tapi_bukan=%d | ms rata=%.2f maks=%.1f" % [nama[profil], N, gagal, salah_ukuran, salah_dekat, salah_celah, salah_periksa, terpaksa, tot_terpaksa, tak_tercatat, bocor, summs / N, maxms])
	quit()
