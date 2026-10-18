class_name TesMisiRantai
extends RefCounted
## Tes rantai panjang run fase4b-misi-kucing (dipindah dari berkas reproduksi QA iterasi 1 `qa_repro_rantai_hari.gd` dan `qa_repro_rencana_luas.gd`, pola 4A):
## (1) rantai 60 hari: pemain selalu Ambil misi bila ditawarkan, hasil bergantian selesai/gagal; tiap hasil menghasilkan tepat SATU headline lanjutan di hari
## berikutnya, flag kosong sesudahnya, koin/tip/hari tidak pernah turun. (2) rencana kucing untuk 600 hari: sah, rute tidak berubah, titik terakhir <= batas rumah,
## titik berurutan, kucing tidak menimpa zona kotak surat pelanggan, jarak antar titik tercatat. Oracle ditulis ulang tes (tidak memanggil fungsi yang dites
## untuk menentukan benar atau salah).

const FOLDER_RUTE: String = "res://assets/data/routes/perumahan"

var _cek: Callable
var _judul: Callable


func _init(cek: Callable, judul: Callable) -> void:
	_cek = cek
	_judul = judul


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_test_rantai_enam_puluh_hari()
	_test_rencana_enam_ratus_hari()


func _test_rantai_enam_puluh_hari() -> void:
	_judul.call("Rantai 60 hari independen: tiap hasil misi -> tepat satu lanjutan besok, flag kosong sesudahnya, koin tidak turun (AC-9, M-6, M-8)")
	var galat: Array[String] = []
	var pustaka: PemuatHeadline.Pustaka = PemuatHeadline.muat_folder()
	var misi: Array[DataMisi] = PemuatMisi.muat_folder().misi
	var simpanan: Dictionary = DataSave.templat()
	var menunggu: String = ""
	var tampil_lanjutan: Dictionary = {}
	var ambil_ke: int = 0
	var hari_p1: Array[int] = []
	for hari: int in range(1, 61):
		var m: HeadlineManager.Masukan = HeadlineManager.Masukan.new()
		m.hari = hari
		m.flag = DataSave.daftar_flag(simpanan)
		m.headline_jeda = DataSave.daftar_jeda(simpanan, "headline_jeda")
		m.misi_jeda = DataSave.daftar_jeda(simpanan, "misi_jeda")
		m.pustaka = pustaka
		m.misi = misi
		var h: HeadlineManager.Halaman = HeadlineManager.susun(m)
		var lanjutan: Array[String] = []
		for e: HeadlineManager.Entri in [h.utama, h.misi, h.ringan]:
			if e != null and e.jenis == "lanjutan":
				lanjutan.append(e.id)
		if menunggu != "":
			if not lanjutan.has(menunggu):
				galat.append("hari %d: lanjutan %s tidak tampil (ada %s, flag %s)" % [hari, menunggu, lanjutan, m.flag])
		elif not lanjutan.is_empty():
			galat.append("hari %d: lanjutan %s muncul tanpa flag" % [hari, lanjutan])
		var c: DataSave.CatatanHari = DataSave.CatatanHari.new()
		c.hari = hari
		var a: HasilRute.Angka = HasilRute.Angka.new()
		a.koin = 40
		a.koin_tip = 5
		var diambil: String = ""
		if h.misi != null and h.misi.jenis == "misi":
			diambil = h.misi.id
			hari_p1.append(hari)
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
		c.angka = a
		c.misi_diambil = diambil
		var jb: HeadlineManager.JedaBaru = HeadlineManager.catat_jeda(h, diambil)
		c.headline_jeda = jb.headline
		c.misi_jeda = jb.misi
		c.flag_dikonsumsi = HeadlineManager.flag_terpakai(h, pustaka)
		var lama_koin: int = int(simpanan["koin"])
		var lama_hari: int = int(simpanan["hari"])
		simpanan = DataSave.catat_hari(simpanan, c)
		if int(simpanan["koin"]) != lama_koin + a.koin:
			galat.append("hari %d: koin %d bukan %d + %d" % [hari, simpanan["koin"], lama_koin, a.koin])
		if int(simpanan["hari"]) < lama_hari:
			galat.append("hari %d: hari turun" % hari)
		menunggu = ""
		var flag: Array[String] = DataSave.daftar_flag(simpanan)
		if flag.size() > 1:
			galat.append("hari %d: flag > 1: %s" % [hari, flag])
		if flag.size() == 1:
			menunggu = "lanjutan_" + flag[0]
		for id: String in lanjutan:
			tampil_lanjutan[id] = int(tampil_lanjutan.get(id, 0)) + 1
	check(galat.is_empty(), "rantai 60 hari tanpa galat: %s" % [galat.slice(0, 3)])
	check(hari_p1 == [1, 8, 15, 22, 29, 36, 43, 50, 57], "P1 ditawarkan hari 1, 8, 15, ... (jeda 7 hari): %s" % [hari_p1])
	check(tampil_lanjutan.get("lanjutan_kucing_ketemu", 0) == 5 and tampil_lanjutan.get("lanjutan_kucing_belum", 0) == 4, "5 lanjutan 'ketemu' dan 4 'belum' tampil, masing-masing tepat sekali per hasil: %s" % [tampil_lanjutan])
	check(DataSave.daftar_flag(simpanan).is_empty() or hari_p1.back() == 57, "flag kosong di akhir rantai (hasil terakhir hari 57 sudah dikonsumsi hari 58)")


func _test_rencana_enam_ratus_hari() -> void:
	_judul.call("Rencana kucing 600 hari: sah, batas rumah, berurutan, tidak menimpa zona kotak surat, rute tidak berubah (AC-4)")
	var misi: DataMisi = PemuatMisi.muat_folder().cari("p1_kucing")
	var segmen: Array[SegmenRute] = PemuatRute.muat_folder(FOLDER_RUTE).segmen
	var tidak_sah: int = 0
	var melewati_batas: int = 0
	var tidak_berurutan: int = 0
	var menimpa_zona: int = 0
	var rute_berubah: int = 0
	var jarak_min: float = 1000.0
	for hari: int in range(1, 601):
		var rute: RouteBuilder.Rute = RouteBuilder.bangun(SeedHari.rute(hari), segmen).rute
		var sebelum: String = _sidik(rute)
		var rencana: RencanaMisi.Rencana = RencanaMisi.buat(misi, rute, SeedHari.misi(hari))
		if _sidik(rute) != sebelum:
			rute_berubah += 1
		if not rencana.sah():
			tidak_sah += 1
			continue
		for i: int in range(rencana.titik.size()):
			var t: RencanaMisi.Titik = rencana.titik[i]
			if t.indeks_rumah > rencana.batas_rumah:
				melewati_batas += 1
			if i > 0:
				jarak_min = minf(jarak_min, t.maju_ubin - rencana.titik[i - 1].maju_ubin)
				if t.indeks_rumah <= rencana.titik[i - 1].indeks_rumah:
					tidak_berurutan += 1
			var persegi: Rect2 = RencanaMisi.persegi_kucing(t)
			for zona: ZonaSasaran.Zona in ZonaSasaran.zona_rute(rute.rumah):
				if zona.jenis == ZonaSasaran.Jenis.KOTAK_SURAT and zona.pelanggan and zona.persegi.intersects(persegi):
					menimpa_zona += 1
	check(tidak_sah == 0, "600 hari: semua rencana sah (%d tidak sah)" % tidak_sah)
	check(melewati_batas == 0 and tidak_berurutan == 0, "600 hari: titik terakhir <= rumah ke-12 dan titik berurutan (%d melewati, %d tidak berurutan)" % [melewati_batas, tidak_berurutan])
	check(menimpa_zona == 0 and rute_berubah == 0, "600 hari: kucing tidak menimpa zona kotak surat pelanggan dan rute tidak berubah (%d menimpa, %d rute berubah)" % [menimpa_zona, rute_berubah])
	check(jarak_min >= 11.0, "600 hari: jarak maju antar titik tidak kurang dari 11 ubin (terpendek %.2f); jendela terlihat kucing berikut tetap penuh karena ditandai tanpa menunggu kucing sebelumnya" % jarak_min)


func _sidik(rute: RouteBuilder.Rute) -> String:
	var bagian: Array[String] = []
	for r: RouteBuilder.RumahRute in rute.rumah:
		bagian.append("%s@%.2f%d%d" % [r.id, r.maju_ubin, int(r.sisi), 1 if r.pelanggan else 0])
	for o: RouteBuilder.ObjekRute in rute.objek:
		bagian.append("%s@%.2f%s" % [o.jenis, o.maju_ubin, o.jalur])
	return ",".join(bagian) + "|" + str(rute.panjang_ubin)
