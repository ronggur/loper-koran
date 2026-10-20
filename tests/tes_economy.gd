class_name TesEconomy
extends RefCounted
## Tes logika murni `Economy` run fase6a1-bengkel-kondisi (AC-13 sampai AC-16): harga servis (linear terhadap kondisi, ongkos naik bila banyak komponen PERLU_BENGKEL, pembulatan),
## servis, beli upgrade (level berurutan, tidak dua kali, saldo tepat di ambang), atomik (ditolak = state identik; diterima = tepat satu komponen berubah dan saldo berkurang tepat
## harga; `koin_total` dan `tip_total` tetap), dan fuzz berseed 10.000 transaksi acak berurutan. Oracle: harga dihitung tangan dari BALANCING 7 (ban 120, rem 80, rantai 150; kenaikan
## 0,25 per komponen rusak tambahan), bukan dengan memanggil `Economy`. Tes ini TIDAK menyentuh berkas.

var _cek: Callable
var _judul: Callable


func _init(cek: Callable, judul: Callable) -> void:
	_cek = cek
	_judul = judul


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_test_config()
	_test_harga_servis_literal()
	_test_ongkos_naik()
	_test_servis_diterima()
	_test_servis_ditolak()
	_test_upgrade_nyata()
	_test_upgrade_level_berurutan()
	_test_upgrade_ditolak_atomik()
	_test_fuzz_sepuluh_ribu()


func _state(koin: int, ban: float = 1.0, rem: float = 1.0, rantai: float = 1.0) -> Dictionary:
	var s: Dictionary = DataSave.templat()
	s["koin"] = koin
	s["koin_total"] = koin + 1000
	s["tip_total"] = 77
	s["sepeda"]["ban"]["kondisi"] = ban
	s["sepeda"]["rem"]["kondisi"] = rem
	s["sepeda"]["rantai"]["kondisi"] = rantai
	return s


func _upgrade(id: String, komponen: String, level: int, harga: int) -> DataToko:
	var u: DataToko = DataToko.new()
	u.id = id
	u.komponen = komponen
	u.level = level
	u.harga = harga
	return u


func _daftar_nyata() -> Array[DataToko]:
	return PemuatToko.muat().upgrade


func _test_config() -> void:
	_judul.call("Economy: angka Config literal (BALANCING 7, M-9)")
	check(Config.SERVIS_HARGA_PENUH == [120, 80, 150] and Config.SERVIS_HARGA_PENUH.size() == Config.KONDISI_KOMPONEN.size(), "harga servis penuh ban 120, rem 80, rantai 150 sejajar komponen")
	check(Config.SERVIS_HARGA_MIN == 1 and Config.SERVIS_KENAIKAN_PER_RUSAK == 0.25, "harga minimum 1 koin; kenaikan 0,25 per komponen rusak tambahan")
	check(Config.SERVIS_HARGA_PENUH[0] >= 100 and Config.SERVIS_HARGA_PENUH[0] <= 150, "ban dalam rentang 100-150 (BALANCING 7, tambal ban)")


func _test_harga_servis_literal() -> void:
	_judul.call("Economy.harga_servis: linear terhadap kondisi, minimum 1, kondisi 1,0 tidak bisa diservis (AC-13, M-9)")
	# Oracle tangan: n = 1 komponen PERLU_BENGKEL (tanpa kenaikan).
	var kasus: Array = [
		["ban", 0.0, 120], ["ban", 0.5, 60], ["ban", 0.2, 96], ["ban", 0.25, 90],
		["rem", 0.0, 80], ["rem", 0.3, 56], ["rem", 0.625, 30], ["rem", 0.5, 40],
		["rantai", 0.0, 150], ["rantai", 0.1, 135], ["rantai", 0.5, 75], ["rantai", 0.9, 15],
		["rantai", 0.999, 1], ["ban", 0.9999, 1], ["rem", 0.99996, 1],
		["ban", 1.0, 0], ["rem", 1.0, 0], ["rantai", 1.0, 0], ["ban", 1.2, 0], ["setang", 0.1, 0], ["lampu", 0.0, 0],
	]
	for baris: Array in kasus:
		var harga: int = Economy.harga_servis(baris[0], baris[1], 1)
		check(harga == baris[2], "%s kondisi %s, satu rusak: %d koin (dapat %d)" % [baris[0], baris[1], baris[2], harga])
	# Harga turun monoton saat kondisi naik.
	var terakhir: int = 99999
	var monoton: bool = true
	for i: int in range(0, 101):
		var h: int = Economy.harga_servis("rantai", float(i) / 100.0, 1)
		if h > terakhir:
			monoton = false
		terakhir = h
	check(monoton and Economy.harga_servis("rantai", 0.0, 1) == 150 and Economy.harga_servis("rantai", 1.0, 1) == 0, "harga rantai turun monoton dari 150 (kondisi 0) ke 0 (kondisi 1,0)")


func _test_ongkos_naik() -> void:
	_judul.call("Economy: ongkos naik bila banyak komponen PERLU_BENGKEL; satu komponen tanpa kenaikan (AC-13, GDD 12.3)")
	check(Economy.pengali_ongkos(0) == 1.0 and Economy.pengali_ongkos(1) == 1.0 and Economy.pengali_ongkos(2) == 1.25 and Economy.pengali_ongkos(3) == 1.5, "pengali ongkos 1,0 / 1,0 / 1,25 / 1,5 untuk 0-3 komponen rusak")
	# Ban kondisi 0,2: dasar 96. Dengan 2 rusak 120, dengan 3 rusak 144.
	check(Economy.harga_servis("ban", 0.2, 1) == 96 and Economy.harga_servis("ban", 0.2, 2) == 120 and Economy.harga_servis("ban", 0.2, 3) == 144, "ban 0,2: 96 (1 rusak), 120 (2 rusak), 144 (3 rusak)")
	check(Economy.harga_servis("ban", 0.2, 1) < Economy.harga_servis("ban", 0.2, 3), "servis ban saat 1 komponen PERLU_BENGKEL lebih murah dari saat 3 (kondisi komponen sama), strict")
	# Dari state: hanya ban rusak vs ketiganya rusak.
	var satu: Dictionary = _state(1000, 0.2, 1.0, 1.0)
	var tiga: Dictionary = _state(1000, 0.2, 0.2, 0.2)
	check(Economy.harga_servis_state(satu, "ban") == 96 and Economy.harga_servis_state(tiga, "ban") == 144, "harga_servis_state menghitung jumlah komponen PERLU_BENGKEL dari state: 96 vs 144")
	# AUS (di atas ambang 0,35) tidak menaikkan ongkos: hanya PERLU_BENGKEL yang dihitung.
	var aus_banyak: Dictionary = _state(1000, 0.2, 0.5, 0.5)
	check(Economy.harga_servis_state(aus_banyak, "ban") == 96, "komponen AUS (belum PERLU_BENGKEL) tidak menaikkan ongkos")
	var dua: Dictionary = _state(1000, 0.2, 0.3, 1.0)
	check(Economy.harga_servis_state(dua, "ban") == 120 and Economy.harga_servis_state(dua, "rem") == 70, "dua rusak: ban 96 x 1,25 = 120; rem 0,3: 56 x 1,25 = 70")
	check(Economy.harga_servis_state(satu, "setang") == 0 and Economy.harga_servis_state(satu, "rem") == 0, "komponen asing atau penuh: harga 0 (tidak bisa diservis)")


func _test_servis_diterima() -> void:
	_judul.call("Economy.servis: kondisi 1,0, servis_total + 1, saldo turun tepat harga, koin_total dan tip_total tetap (AC-13, AC-15)")
	var awal: Dictionary = _state(500, 0.2, 0.9, 0.3)
	var asli: Dictionary = awal.duplicate(true)
	var h: Economy.Hasil = Economy.servis(awal, "ban")
	check(awal == asli, "servis tidak mengubah state masukan")
	check(h.diterima and h.alasan == Economy.Alasan.DITERIMA and h.harga == 120, "servis ban 0,2 dengan dua rusak (ban dan rantai): diterima, harga 96 x 1,25 = 120")
	check(h.state["koin"] == 380 and h.state["koin_total"] == asli["koin_total"] and h.state["tip_total"] == 77, "saldo 500 -> 380; koin_total dan tip_total tetap")
	check(h.state["sepeda"]["ban"]["kondisi"] == 1.0 and h.state["sepeda"]["servis_total"] == 1, "ban kembali 1,0; servis_total 0 -> 1")
	check(h.state["sepeda"]["rem"] == asli["sepeda"]["rem"] and h.state["sepeda"]["rantai"] == asli["sepeda"]["rantai"], "komponen lain tidak berubah (tepat satu komponen)")
	check(h.state["sepeda"]["ban"]["level"] == 0, "servis tidak mengubah level upgrade")
	# Setelah ban diservis, tinggal satu rusak: rantai 0,3 turun ke harga satu rusak (105).
	check(Economy.harga_servis_state(h.state, "rantai") == 105, "sesudah ban diservis tinggal rantai rusak: ongkos rantai 150 x 0,7 = 105 tanpa kenaikan")
	# Saldo tepat sama dengan harga sah.
	var tepat: Economy.Hasil = Economy.servis(_state(96, 0.2, 1.0, 1.0), "ban")
	check(tepat.diterima and tepat.state["koin"] == 0 and tepat.harga == 96, "saldo tepat sama dengan harga (96): diterima, saldo 0")
	var kurang: Economy.Hasil = Economy.servis(_state(95, 0.2, 1.0, 1.0), "ban")
	check(not kurang.diterima and kurang.alasan == Economy.Alasan.KOIN_KURANG and kurang.state == _state(95, 0.2, 1.0, 1.0) and kurang.harga == 0, "saldo 95 (kurang 1): ditolak KOIN_KURANG, state identik")
	# Servis berurutan menghemat: tiga servis berturut-turut dari tiga rusak.
	var s3: Dictionary = _state(10000, 0.0, 0.0, 0.0)
	var total: int = 0
	for kom: String in ["ban", "rem", "rantai"]:
		var r: Economy.Hasil = Economy.servis(s3, kom)
		total += r.harga
		s3 = r.state
	# Urutan: ban (120 x 1,5 = 180), rem (80 x 1,25 = 100), rantai (150 x 1,0 = 150) = 430.
	check(total == 430 and s3["sepeda"]["servis_total"] == 3 and s3["koin"] == 10000 - 430, "servis ban, rem, rantai berturut-turut dari tiga rusak total: 180 + 100 + 150 = 430 koin, servis_total 3")


func _test_servis_ditolak() -> void:
	_judul.call("Economy.servis: ditolak (komponen penuh, asing, saldo kurang) = state identik, alasan enum (AC-13, AC-15)")
	var s: Dictionary = _state(1000, 1.0, 0.5, 1.0)
	var penuh: Economy.Hasil = Economy.servis(s, "ban")
	check(not penuh.diterima and penuh.alasan == Economy.Alasan.KOMPONEN_PENUH and penuh.state == s and penuh.harga == 0, "ban 1,0 ditolak KOMPONEN_PENUH, state identik")
	var asing: Economy.Hasil = Economy.servis(s, "setang")
	check(not asing.diterima and asing.alasan == Economy.Alasan.KOMPONEN_TIDAK_DIKENAL and asing.state == s, "komponen asing (setang) ditolak KOMPONEN_TIDAK_DIKENAL")
	var kosong: Economy.Hasil = Economy.servis(s, "")
	check(not kosong.diterima and kosong.alasan == Economy.Alasan.KOMPONEN_TIDAK_DIKENAL and kosong.state == s, "komponen kosong ditolak")
	var nol: Economy.Hasil = Economy.servis(_state(0, 0.5, 0.5, 0.5), "rem")
	check(not nol.diterima and nol.alasan == Economy.Alasan.KOIN_KURANG, "saldo 0 tidak bisa servis")
	check(s["sepeda"]["servis_total"] == 0, "state masukan tidak berubah")
	# State tanpa sepeda (belum dimigrasi) tidak crash.
	var tanpa: Dictionary = {"koin": 50}
	var r: Economy.Hasil = Economy.servis(tanpa, "ban")
	check(not r.diterima and r.alasan == Economy.Alasan.KOMPONEN_PENUH, "state tanpa sepeda dianggap baru: komponen penuh")


func _test_upgrade_nyata() -> void:
	_judul.call("Economy.beli_upgrade: tiga upgrade nyata, saldo tepat di ambang, tidak dua kali (AC-14)")
	var daftar: Array[DataToko] = _daftar_nyata()
	check(daftar.size() == 3, "tiga upgrade nyata dimuat")
	var harga: Dictionary = {}
	for u: DataToko in daftar:
		harga[u.id] = u.harga
	check(harga == {"ban_anti_selip": 600, "rem_pakem": 500, "rantai_hemat": 700}, "harga nyata 600 / 500 / 700 (rentang 500-800)")
	var s: Dictionary = _state(600)
	var h: Economy.Hasil = Economy.beli_upgrade(s, "ban_anti_selip", daftar)
	check(h.diterima and h.harga == 600 and h.state["koin"] == 0 and h.state["sepeda"]["ban"]["level"] == 1, "saldo tepat 600: ban_anti_selip diterima, saldo 0, level ban 1")
	check(h.state["koin_total"] == s["koin_total"] and h.state["tip_total"] == 77 and h.state["sepeda"]["servis_total"] == 0, "koin_total, tip_total, servis_total tidak berubah oleh upgrade")
	check(h.state["sepeda"]["rem"] == s["sepeda"]["rem"] and h.state["sepeda"]["rantai"] == s["sepeda"]["rantai"] and h.state["sepeda"]["ban"]["kondisi"] == 1.0, "tepat satu komponen berubah (hanya level ban)")
	var kurang: Economy.Hasil = Economy.beli_upgrade(_state(599), "ban_anti_selip", daftar)
	check(not kurang.diterima and kurang.alasan == Economy.Alasan.KOIN_KURANG and kurang.state == _state(599), "saldo 599: ditolak KOIN_KURANG, state identik")
	var dua: Economy.Hasil = Economy.beli_upgrade(h.state.duplicate(true), "ban_anti_selip", daftar)
	var kaya: Dictionary = h.state.duplicate(true)
	kaya["koin"] = 5000
	var lagi: Economy.Hasil = Economy.beli_upgrade(kaya, "ban_anti_selip", daftar)
	check(not lagi.diterima and lagi.alasan == Economy.Alasan.SUDAH_DIMILIKI and lagi.state == kaya and not dua.diterima, "sudah dimiliki: tidak bisa dibeli dua kali walau saldo cukup")
	var asing: Economy.Hasil = Economy.beli_upgrade(kaya, "rem_super", daftar)
	check(not asing.diterima and asing.alasan == Economy.Alasan.UPGRADE_TIDAK_DIKENAL and asing.state == kaya, "id tak dikenal ditolak UPGRADE_TIDAK_DIKENAL")
	var kosong_daftar: Economy.Hasil = Economy.beli_upgrade(kaya, "rem_pakem", [])
	check(not kosong_daftar.diterima and kosong_daftar.alasan == Economy.Alasan.UPGRADE_TIDAK_DIKENAL, "daftar upgrade kosong (data galat): tidak ada yang bisa dibeli, tanpa crash")
	# Ketiga bisa dibeli berturut-turut dari saldo cukup.
	var s3: Dictionary = _state(1800)
	for id: String in ["rem_pakem", "ban_anti_selip", "rantai_hemat"]:
		s3 = Economy.beli_upgrade(s3, id, daftar).state
	check(s3["koin"] == 1800 - 1800 and s3["sepeda"]["ban"]["level"] == 1 and s3["sepeda"]["rem"]["level"] == 1 and s3["sepeda"]["rantai"]["level"] == 1, "ketiganya terbeli: saldo 0, tiap komponen level 1")


func _test_upgrade_level_berurutan() -> void:
	_judul.call("Economy.beli_upgrade: level N hanya bila N - 1 dimiliki (AC-14)")
	var daftar: Array[DataToko] = [_upgrade("ban_1", "ban", 1, 100), _upgrade("ban_2", "ban", 2, 300), _upgrade("ban_3", "ban", 3, 900), _upgrade("rem_1", "rem", 1, 50)]
	var s: Dictionary = _state(5000)
	var lompat: Economy.Hasil = Economy.beli_upgrade(s, "ban_2", daftar)
	check(not lompat.diterima and lompat.alasan == Economy.Alasan.LEVEL_TIDAK_BERURUTAN and lompat.state == s, "level 2 tanpa level 1: ditolak LEVEL_TIDAK_BERURUTAN, state identik")
	var tiga: Economy.Hasil = Economy.beli_upgrade(s, "ban_3", daftar)
	check(not tiga.diterima and tiga.alasan == Economy.Alasan.LEVEL_TIDAK_BERURUTAN, "level 3 dari level 0 ditolak")
	var a: Economy.Hasil = Economy.beli_upgrade(s, "ban_1", daftar)
	var b: Economy.Hasil = Economy.beli_upgrade(a.state, "ban_2", daftar)
	var c: Economy.Hasil = Economy.beli_upgrade(b.state, "ban_3", daftar)
	check(a.diterima and b.diterima and c.diterima and c.state["sepeda"]["ban"]["level"] == 3 and c.state["koin"] == 5000 - 100 - 300 - 900, "berurutan 1, 2, 3: diterima, saldo 5000 - 1300")
	var turun: Economy.Hasil = Economy.beli_upgrade(c.state, "ban_1", daftar)
	check(not turun.diterima and turun.alasan == Economy.Alasan.SUDAH_DIMILIKI and turun.state == c.state, "level lebih rendah dari yang dimiliki: SUDAH_DIMILIKI, level tidak turun")
	var lain: Economy.Hasil = Economy.beli_upgrade(s, "rem_1", daftar)
	check(lain.diterima and lain.state["sepeda"]["ban"]["level"] == 0 and lain.state["sepeda"]["rem"]["level"] == 1, "komponen lain mandiri: rem level 1 tanpa menyentuh ban")


func _test_upgrade_ditolak_atomik() -> void:
	_judul.call("Economy: transaksi ditolak = state identik di semua alasan (perbandingan dalam); tanpa efek samping (AC-15)")
	var daftar: Array[DataToko] = _daftar_nyata()
	var s: Dictionary = _state(10, 0.1, 0.4, 0.9)
	var salinan: Dictionary = s.duplicate(true)
	var hasil: Array[Economy.Hasil] = [
		Economy.servis(s, "ban"), Economy.servis(s, "rantai"), Economy.servis(s, "setang"),
		Economy.beli_upgrade(s, "rem_pakem", daftar), Economy.beli_upgrade(s, "nama_aneh", daftar),
	]
	var alasan: Array[Economy.Alasan] = [Economy.Alasan.KOIN_KURANG, Economy.Alasan.KOIN_KURANG, Economy.Alasan.KOMPONEN_TIDAK_DIKENAL, Economy.Alasan.KOIN_KURANG, Economy.Alasan.UPGRADE_TIDAK_DIKENAL]
	for i: int in range(hasil.size()):
		check(not hasil[i].diterima and hasil[i].alasan == alasan[i] and hasil[i].state == salinan and hasil[i].harga == 0, "transaksi ke-%d ditolak dengan alasan %d dan state identik" % [i, alasan[i]])
	check(s == salinan, "state masukan tidak berubah oleh transaksi ditolak")
	hasil[0].state["koin"] = 99999
	check(s["koin"] == 10, "state hasil penolakan adalah salinan (mengubahnya tidak mengubah masukan)")


func _test_fuzz_sepuluh_ribu() -> void:
	_judul.call("Economy: fuzz berseed 10.000 transaksi acak berurutan, invarian saldo, level, servis, koin_total, tip_total (AC-15)")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 6103
	var daftar: Array[DataToko] = _daftar_nyata()
	daftar.append(_upgrade("ban_dua", "ban", 2, 900))
	var ids: Array[String] = ["ban_anti_selip", "rem_pakem", "rantai_hemat", "ban_dua", "tidak_ada"]
	var komponen: Array[String] = ["ban", "rem", "rantai", "setang"]
	var s: Dictionary = _state(rng.randi_range(0, 3000), rng.randf(), rng.randf(), rng.randf())
	var disuntik: int = int(s["koin"])
	var keluar_diterima: int = 0
	var diterima: int = 0
	var ditolak: int = 0
	var pelanggaran: Array[String] = []
	var total_awal: int = int(s["koin_total"])
	for i: int in range(10000):
		# Kadang aus (kondisi turun) dan kadang pemasukan; keduanya di luar Economy.
		if rng.randi() % 7 == 0:
			var kom: String = Config.KONDISI_KOMPONEN[rng.randi() % 3]
			s["sepeda"][kom]["kondisi"] = maxf(float(s["sepeda"][kom]["kondisi"]) - rng.randf() * 0.5, 0.0)
		if rng.randi() % 9 == 0:
			var tambah: int = rng.randi_range(0, 400)
			s["koin"] = int(s["koin"]) + tambah
			disuntik += tambah
		var sebelum: Dictionary = s.duplicate(true)
		var r: Economy.Hasil
		var pilih: int = rng.randi() % 2
		if pilih == 0:
			r = Economy.servis(s, komponen[rng.randi() % 4])
		else:
			r = Economy.beli_upgrade(s, ids[rng.randi() % 5], daftar)
		if r.diterima:
			diterima += 1
			keluar_diterima += r.harga
			# Tepat satu komponen berubah: bandingkan komponen satu per satu.
			var berubah: int = 0
			for kom: String in Config.KONDISI_KOMPONEN:
				if r.state["sepeda"][kom] != sebelum["sepeda"][kom]:
					berubah += 1
			if berubah != 1:
				pelanggaran.append("transaksi %d: %d komponen berubah" % [i, berubah])
			if int(r.state["koin"]) != int(sebelum["koin"]) - r.harga or r.harga < 1:
				pelanggaran.append("transaksi %d: saldo tidak berkurang tepat harga %d (%s -> %s)" % [i, r.harga, sebelum["koin"], r.state["koin"]])
		else:
			ditolak += 1
			if r.state != sebelum:
				pelanggaran.append("transaksi %d ditolak (%d) tetapi state berubah" % [i, r.alasan])
		if int(r.state["koin"]) < 0:
			pelanggaran.append("transaksi %d: saldo negatif" % i)
		if int(r.state["sepeda"]["servis_total"]) < int(sebelum["sepeda"]["servis_total"]):
			pelanggaran.append("transaksi %d: servis_total turun" % i)
		for kom: String in Config.KONDISI_KOMPONEN:
			if int(r.state["sepeda"][kom]["level"]) < int(sebelum["sepeda"][kom]["level"]):
				pelanggaran.append("transaksi %d: level %s turun" % [i, kom])
		if r.state["koin_total"] != total_awal or r.state["tip_total"] != 77:
			pelanggaran.append("transaksi %d: koin_total atau tip_total berubah" % i)
		s = r.state
		if pelanggaran.size() > 5:
			break
	check(pelanggaran.is_empty(), "10000 transaksi: tidak ada pelanggaran invarian: %s" % [pelanggaran.slice(0, 5)])
	check(diterima > 100 and ditolak > 100, "fuzz menjangkau transaksi diterima (%d) dan ditolak (%d)" % [diterima, ditolak])
	check(int(s["koin"]) == disuntik - keluar_diterima, "koin keluar = jumlah harga transaksi diterima: saldo akhir %d = disuntik %d - keluar %d" % [int(s["koin"]), disuntik, keluar_diterima])
	check(int(s["sepeda"]["ban"]["level"]) <= 2 and int(s["sepeda"]["rem"]["level"]) <= 1 and int(s["sepeda"]["rantai"]["level"]) <= 1, "level tidak melebihi level terbesar di daftar")
