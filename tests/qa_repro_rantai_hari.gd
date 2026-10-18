extends SceneTree
## QA iterasi 1 run 4B (bukan bagian run_tests.gd): rantai 60 hari independen. Pemain selalu Ambil misi bila ditawarkan; hasil bergantian selesai/gagal.
## Oracle: tiap hasil misi menghasilkan tepat SATU headline lanjutan di hari berikutnya dan flag kosong sesudahnya; koin/tip/hari tidak pernah turun.

func _init() -> void:
	var galat: int = 0
	var pustaka: PemuatHeadline.Pustaka = PemuatHeadline.muat_folder()
	var misi: Array[DataMisi] = PemuatMisi.muat_folder().misi
	var state: Dictionary = DataSave.templat()
	var menunggu: String = ""
	var tampil_lanjutan: Dictionary = {}
	var ambil_ke: int = 0
	for hari: int in range(1, 61):
		var m: HeadlineManager.Masukan = HeadlineManager.Masukan.new()
		m.hari = hari
		m.flag = DataSave.daftar_flag(state)
		m.headline_jeda = DataSave.daftar_jeda(state, "headline_jeda")
		m.misi_jeda = DataSave.daftar_jeda(state, "misi_jeda")
		m.pustaka = pustaka
		m.misi = misi
		var h: HeadlineManager.Halaman = HeadlineManager.susun(m)
		var lanjutan: Array[String] = []
		for e: HeadlineManager.Entri in [h.utama, h.misi, h.ringan]:
			if e != null and e.jenis == "lanjutan":
				lanjutan.append(e.id)
		if menunggu != "":
			if not lanjutan.has(menunggu):
				galat += 1
				print("GAGAL hari %d: lanjutan %s tidak tampil (ada %s, flag %s)" % [hari, menunggu, lanjutan, m.flag])
		elif not lanjutan.is_empty():
			galat += 1
			print("GAGAL hari %d: lanjutan %s muncul tanpa flag" % [hari, lanjutan])
		var c: DataSave.CatatanHari = DataSave.CatatanHari.new()
		c.hari = hari
		var a: HasilRute.Angka = HasilRute.Angka.new()
		a.koin = 40
		a.koin_tip = 5
		var diambil: String = ""
		if h.misi != null and h.misi.jenis == "misi":
			diambil = h.misi.id
			var data: DataMisi = null
			for d: DataMisi in misi:
				if d.id == diambil:
					data = d
			a.misi_id = diambil
			a.misi_hasil = "selesai" if ambil_ke % 2 == 0 else "gagal"
			ambil_ke += 1
			if a.misi_hasil == "selesai":
				a.koin_misi = data.hadiah_koin()
				a.koin += a.koin_misi
			c.flag_baru = [MissionManager.flag_hasil(data, a.misi_hasil)]
			print("hari %d: ambil %s -> %s" % [hari, diambil, a.misi_hasil])
		c.angka = a
		c.misi_diambil = diambil
		var jb: HeadlineManager.JedaBaru = HeadlineManager.catat_jeda(h, diambil)
		c.headline_jeda = jb.headline
		c.misi_jeda = jb.misi
		c.flag_dikonsumsi = HeadlineManager.flag_terpakai(h, pustaka)
		var lama_koin: int = int(state["koin"])
		state = DataSave.catat_hari(state, c)
		if int(state["koin"]) != lama_koin + a.koin:
			galat += 1
			print("GAGAL hari %d: koin %d bukan %d + %d" % [hari, state["koin"], lama_koin, a.koin])
		menunggu = ""
		var flag: Array[String] = DataSave.daftar_flag(state)
		if flag.size() > 1:
			galat += 1
			print("GAGAL hari %d: flag > 1: %s" % [hari, flag])
		if flag.size() == 1:
			menunggu = "lanjutan_" + flag[0]
		for id: String in lanjutan:
			tampil_lanjutan[id] = int(tampil_lanjutan.get(id, 0)) + 1
	print("lanjutan tampil: %s ; save akhir flag=%s misi_hasil=%s" % [tampil_lanjutan, state["flag"], state["misi_hasil"]])
	print("%d galat" % galat)
	quit(1 if galat > 0 else 0)
