extends SceneTree
## QA iterasi 2 run 4B (bukan bagian run_tests.gd): bukti angka QA-010 dan QA-011. Dijalankan: godot --headless --path . --script res://tests/qa_repro_petunjuk_manfaat.gd
## Mencetak tambahan waktu terlihat terbaik karena petunjuk (lemparan 5 ubin ke depan di rumah pertama jendela, ngebut) dan waktu dari titik nol ke kucing 1 (BikeMotion nyata) untuk 600 hari.

func _init() -> void:
	var misi: DataMisi = PemuatMisi.muat_folder().cari("p1_kucing")
	var segmen: Array[SegmenRute] = PemuatRute.muat_folder("res://assets/data/routes/perumahan").segmen
	var pertama_min: float = 1e9
	var t_min: float = 1e9
	var t_contoh: String = ""
	# Waktu dari titik nol (kecepatan awal santai, stick penuh atas) sampai titik kucing 1, nyata dari BikeMotion.
	var tabel: Dictionary = {}
	var ekstra: Array = [[], [], []]
	var ekstra_max: Array = [[], [], []]
	var gap_hitung: Dictionary = {}
	var tidak_sah: int = 0
	for hari: int in range(1, 601):
		var rute: RouteBuilder.Rute = RouteBuilder.bangun(SeedHari.rute(hari), segmen).rute
		var r: RencanaMisi.Rencana = RencanaMisi.buat(misi, rute, SeedHari.misi(hari))
		if not r.sah():
			tidak_sah += 1
			continue
		var d1: float = r.titik[0].maju_ubin
		pertama_min = minf(pertama_min, d1)
		var k: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
		var maju: float = 0.0
		var t: float = 0.0
		while maju < d1 and t < 30.0:
			var h: BikeMotion.Hasil = BikeMotion.langkah(k, Vector2(0.0, 1.0), 1.0 / 240.0)
			k = h.keadaan
			maju += h.maju_ubin
			t += 1.0 / 240.0
		if t < t_min:
			t_min = t
			t_contoh = "hari %d d1=%.2f" % [hari, d1]
		for i: int in range(3):
			var tt: RencanaMisi.Titik = r.titik[i]
			var h0: float = tt.petunjuk_awal_ubin   # awal jendela (maju rumah)
			var gap: float = tt.maju_ubin - h0
			# Tambahan jarak terlihat terbaik: koran mendarat di rumah pertama jendela, pemain (paling jauh) LEMPAR_JARAK_MAKS di belakang titik pendaratan
			var pemain_paling_awal: float = maxf(h0 - Config.LEMPAR_JARAK_MAKS_UBIN, 0.0)
			var jarak_saat_petunjuk: float = tt.maju_ubin - pemain_paling_awal
			var tambah: float = clampf(minf(jarak_saat_petunjuk, Config.MISI_TAMPIL_PETUNJUK_JARAK_UBIN) - Config.MISI_TAMPIL_JARAK_UBIN, 0.0, 100.0)
			ekstra_max[i].append(tambah / Config.KECEPATAN_NGEBUT_UD)
			# Pemain di titik pendaratan sendiri (lemparan menyamping, ~tegak lurus): jarak = gap
			var tambah2: float = clampf(minf(gap, Config.MISI_TAMPIL_PETUNJUK_JARAK_UBIN) - Config.MISI_TAMPIL_JARAK_UBIN, 0.0, 100.0)
			ekstra[i].append(tambah2 / Config.KECEPATAN_NGEBUT_UD)
			var kunci: String = "%d:%.2f" % [i, snappedf(gap, 0.5)]
			gap_hitung[kunci] = int(gap_hitung.get(kunci, 0)) + 1
	print("tidak sah: ", tidak_sah, " ; kucing1 terdekat dari awal: %.2f ubin" % pertama_min)
	print("waktu terpendek dari titik nol (santai->ngebut, stick penuh) sampai kucing1: %.3f detik (%s)" % [t_min, t_contoh])
	for i: int in range(3):
		var a: Array = ekstra_max[i]
		var b: Array = ekstra[i]
		var mx: float = 0.0
		var rata_mx: float = 0.0
		var ge1: int = 0
		var nol: int = 0
		for v: float in a:
			mx = maxf(mx, v)
			rata_mx += v
			if v >= 1.0:
				ge1 += 1
			if v <= 0.0:
				nol += 1
		var mx2: float = 0.0
		for v: float in b:
			mx2 = maxf(mx2, v)
		print("kucing %d: n=%d; tambahan terbaik (lempar 5 ubin ke depan di rumah pertama jendela) maks %.2f dtk, rata %.2f, >=1,0 dtk di %d plan, 0 di %d plan; (pemain sejajar rumah) maks %.2f dtk" % [i + 1, a.size(), mx, rata_mx / a.size(), ge1, nol, mx2])
	print("gap (titik - awal jendela) histogram: ", gap_hitung)
	quit(0)
