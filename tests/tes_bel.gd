class_name TesBel
extends RefCounted
## Tes logika murni bel "Kring Kring!" run fase3b-rintangan-skor (AC-14, AC-17 bagian logika; K-3, GDD 5.4, DESIGN_SPEC 3.8).
##
## Oracle literal: urutan ketukan, detik, jangkauan, dan tabel reaksi ditulis eksplisit di sini. Input tombol bel (zona tap, dua jari,
## kidal) ada di bagian B (scene dan `TouchRouter`).

var _cek: Callable
var _judul: Callable


func _init(cek: Callable, judul: Callable) -> void:
	_cek = cek
	_judul = judul


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_test_config()
	_test_ketukan_literal()
	_test_jeda_game_dan_beku()
	_test_jangkauan_dan_tabel()
	_test_reaksi_rintangan()
	_test_bel_mencegah_tabrakan()


func _test_config() -> void:
	_judul.call("Bel: angka Config literal (AC-24, GDD 5.4)")
	check(is_equal_approx(Config.BEL_TEKS_DETIK, 0.5) and is_equal_approx(Config.BEL_JEDA_DETIK, 1.0) and is_equal_approx(Config.BEL_JANGKAUAN_UBIN, 4.0) and is_equal_approx(Config.BEL_JANGKAUAN_BELAKANG_UBIN, 1.0), "teks 0,5 detik, jeda 1,0 detik, jangkauan 4,0 ubin di depan dan 1,0 di belakang")


func _test_ketukan_literal() -> void:
	_judul.call("Bel (AC-14): kring, kring kring selama teks tampil, jeda 1,0 detik menolak ketukan, kring tunggal tanpa jeda")
	var k: Bel.Keadaan = Bel.awal()
	var h: Bel.Hasil = Bel.ketuk(k, false)
	check(h.bunyi == Bel.Bunyi.KRING and is_equal_approx(h.keadaan.teks_detik, 0.5) and not h.keadaan.dobel and not Bel.sedang_jeda(h.keadaan) and h.keadaan.jumlah == 1, "ketukan pertama: KRING, teks 0,5 detik, tanpa jeda")
	check(k.jumlah == 0 and is_equal_approx(k.teks_detik, 0.0), "masukan tidak diubah")
	k = Bel.langkah(h.keadaan, 0.3)
	check(Bel.teks_tampil(k) and is_equal_approx(k.teks_detik, 0.2), "0,3 detik kemudian teks masih tampil (sisa 0,2)")
	h = Bel.ketuk(k, false)
	check(h.bunyi == Bel.Bunyi.KRING_KRING and h.keadaan.dobel and is_equal_approx(h.keadaan.jeda_detik, 1.0) and is_equal_approx(Bel.sisa_jeda_pecahan(h.keadaan), 1.0) and h.keadaan.jumlah == 2, "ketukan kedua selama teks: KRING_KRING, teks berganti dobel, jeda 1,0 (cincin penuh)")
	k = Bel.langkah(h.keadaan, 0.5)
	check(not Bel.teks_tampil(k) and is_equal_approx(k.jeda_detik, 0.5) and is_equal_approx(Bel.sisa_jeda_pecahan(k), 0.5), "0,5 detik kemudian: teks habis, sisa jeda 0,5 (cincin setengah)")
	h = Bel.ketuk(k, false)
	check(h.bunyi == Bel.Bunyi.TOLAK and h.keadaan.jumlah == 2 and is_equal_approx(h.keadaan.jeda_detik, 0.5), "ketukan selama jeda: TOLAK tanpa bunyi, jeda tidak diulang")
	k = Bel.langkah(k, 0.49)
	check(Bel.ketuk(k, false).bunyi == Bel.Bunyi.TOLAK, "sisa jeda 0,01: masih TOLAK")
	k = Bel.langkah(k, 0.01)
	check(not Bel.sedang_jeda(k) and is_equal_approx(Bel.sisa_jeda_pecahan(k), 0.0), "tepat 1,0 detik sesudah kring kring: jeda habis")
	h = Bel.ketuk(k, false)
	check(h.bunyi == Bel.Bunyi.KRING, "sesudah jeda: ketukan = KRING lagi")
	var tunggal: Bel.Keadaan = Bel.langkah(h.keadaan, 0.5)
	var h2: Bel.Hasil = Bel.ketuk(tunggal, false)
	check(h2.bunyi == Bel.Bunyi.KRING and not Bel.sedang_jeda(h2.keadaan), "kring tunggal yang teksnya sudah habis (0,5 detik) tidak memulai jeda: ketukan berikut KRING lagi")
	var nyaris: Bel.Keadaan = Bel.langkah(h.keadaan, 0.4999)
	check(Bel.ketuk(nyaris, false).bunyi == Bel.Bunyi.KRING_KRING, "0,4999 detik sesudah kring: masih KRING_KRING")
	check(Bel.berbunyi(Bel.Bunyi.KRING) and Bel.berbunyi(Bel.Bunyi.KRING_KRING) and not Bel.berbunyi(Bel.Bunyi.TOLAK), "berbunyi: KRING dan KRING_KRING ya, TOLAK tidak")


func _test_jeda_game_dan_beku() -> void:
	_judul.call("Bel dan jeda game (AC-17): tidak bisa dibunyikan saat jeda; teks dan jeda bel membeku dengan dt 0")
	var h: Bel.Hasil = Bel.ketuk(Bel.awal(), true)
	check(h.bunyi == Bel.Bunyi.TOLAK and h.keadaan.jumlah == 0 and not Bel.teks_tampil(h.keadaan), "ketukan saat jeda game: TOLAK, tanpa teks")
	var dobel: Bel.Keadaan = Bel.ketuk(Bel.ketuk(Bel.awal(), false).keadaan, false).keadaan
	for dt: float in [0.0, -1.0, NAN, INF]:
		var b: Bel.Keadaan = Bel.langkah(dobel, dt)
		check(is_equal_approx(b.jeda_detik, 1.0) and is_equal_approx(b.teks_detik, 0.5) and b.dobel, "dt %s: jeda bel dan teks membeku" % dt)
	check(Bel.ketuk(dobel, true).bunyi == Bel.Bunyi.TOLAK, "jeda game selama jeda bel: tetap TOLAK")


func _test_jangkauan_dan_tabel() -> void:
	_judul.call("Jangkauan bel dan tabel reaksi per jenis (AC-14, K-3)")
	var tabel: Array = [[14.0, true], [14.01, false], [10.0, true], [9.0, true], [8.99, false], [12.5, true], [NAN, false]]
	for t: Array in tabel:
		check(Bel.dalam_jangkauan(10.0, t[0]) == t[1], "sepeda di 10, rintangan di %s: dalam jangkauan %s" % [t[0], t[1]])
	check(not Bel.dalam_jangkauan(NAN, 10.0), "sepeda NaN: tidak")
	check(Bel.reaksi("anjing_penjaga") == Bel.Reaksi.MUNDUR and Bel.reaksi("mobil_garasi") == Bel.Reaksi.TIDAK_ADA and Bel.reaksi("pejalan_kaki") == Bel.Reaksi.TIDAK_ADA, "tabel: anjing MUNDUR, mobil TIDAK_ADA, jenis tak dikenal TIDAK_ADA")
	var kunci: Array = Bel.REAKSI_JENIS.keys()
	kunci.sort()
	var jenis: Array = SegmenRute.JENIS_OBJEK.duplicate()
	jenis.sort()
	check(kunci == jenis, "tabel reaksi memuat tepat jenis objek data (%s)" % [kunci])


## Rintangan uji: anjing seberang di maju 20 dan mobil seberang di maju 34, tanda 9.
func _uji() -> RintanganRute.Keadaan:
	var a: RouteBuilder.ObjekRute = RouteBuilder.ObjekRute.new()
	a.jenis = "anjing_penjaga"
	a.maju_ubin = 20.0
	a.jalur = "seberang"
	a.tanda_ubin = 9.0
	var m: RouteBuilder.ObjekRute = RouteBuilder.ObjekRute.new()
	m.jenis = "mobil_garasi"
	m.maju_ubin = 34.0
	m.jalur = "seberang"
	m.tanda_ubin = 9.0
	var daftar: Array[RouteBuilder.ObjekRute] = [a, m]
	return RintanganRute.dari_objek(daftar)


func _test_reaksi_rintangan() -> void:
	_judul.call("Reaksi bel di RintanganRute (K-3): anjing waspada/mengejar dalam jangkauan mundur; anjing diam dan mobil tidak")
	var awal: RintanganRute.Keadaan = _uji()
	var diam: RintanganRute.HasilBel = RintanganRute.terapkan_bel(awal, 17.0)
	check(diam.bereaksi.is_empty() and diam.keadaan.daftar[0].anjing.status == AnjingPenjaga.Status.DIAM, "anjing DIAM 3 ubin di depan: tidak bereaksi")
	var w: RintanganRute.Keadaan = RintanganRute.langkah(awal, 12.0, -1.0, 3.0, 0.1).keadaan
	check(w.daftar[0].anjing.status == AnjingPenjaga.Status.WASPADA, "sepeda di 12: anjing WASPADA")
	var jauh: RintanganRute.HasilBel = RintanganRute.terapkan_bel(w, 12.0)
	check(jauh.bereaksi.is_empty() and jauh.keadaan.daftar[0].anjing.status == AnjingPenjaga.Status.WASPADA, "anjing 8 ubin di depan (di luar 4): tidak bereaksi")
	var dekat: RintanganRute.HasilBel = RintanganRute.terapkan_bel(w, 16.0)
	check(dekat.bereaksi == [0] and dekat.keadaan.daftar[0].anjing.status == AnjingPenjaga.Status.MUNDUR and RintanganRute.ikon_seru(dekat.keadaan.daftar[0]), "anjing tepat 4 ubin di depan: MUNDUR dengan ikon '!'")
	check(dekat.kejadian.size() == 1 and dekat.kejadian[0].peristiwa == RintanganRute.Peristiwa.ANJING_MUNDUR, "peristiwa ANJING_MUNDUR untuk visual")
	check(w.daftar[0].anjing.status == AnjingPenjaga.Status.WASPADA, "masukan terapkan_bel tidak diubah")
	# Anjing mengejar sedikit di belakang sepeda (dalam 1,0 ubin) bereaksi; 1,5 ubin di belakang tidak.
	var k: RintanganRute.Keadaan = RintanganRute.langkah(w, 20.0, -1.0, 3.0, 0.1).keadaan
	check(k.daftar[0].anjing.status == AnjingPenjaga.Status.MENGEJAR, "sepeda lewat: anjing MENGEJAR")
	var maju_anjing: float = k.daftar[0].anjing.maju_ubin
	check(RintanganRute.terapkan_bel(k, maju_anjing + 0.9).bereaksi == [0], "anjing mengejar 0,9 ubin di belakang sepeda: mundur")
	check(RintanganRute.terapkan_bel(k, maju_anjing + 1.5).bereaksi.is_empty(), "anjing mengejar 1,5 ubin di belakang: di luar jangkauan")
	# Mobil bertanda dalam jangkauan: tidak bereaksi (tabel).
	var mobil: RintanganRute.Keadaan = RintanganRute.langkah(awal, 26.0, 1.0, 3.0, 0.1).keadaan
	check(mobil.daftar[1].mobil.status == MobilGarasi.Status.TANDA, "sepeda di 26: mobil TANDA")
	var hm: RintanganRute.HasilBel = RintanganRute.terapkan_bel(mobil, 31.0)
	check(not hm.bereaksi.has(1) and hm.keadaan.daftar[1].mobil.status == MobilGarasi.Status.TANDA, "mobil dalam jangkauan bel tidak bereaksi")


func _test_bel_mencegah_tabrakan() -> void:
	_judul.call("Bel berguna (K-3): pemain santai di separuh jalan anjing yang membunyikan bel tidak dikejar; tanpa bel tertabrak")
	for pakai_bel: bool in [false, true]:
		var r: RintanganRute.Keadaan = _uji()
		var bel: Bel.Keadaan = Bel.awal()
		var tabrak: int = 0
		var dikejar: bool = false
		var dt: float = 1.0 / 60.0
		for n: int in range(1, 600):
			var maju: float = 3.0 * dt * n
			var h: RintanganRute.Hasil = RintanganRute.langkah(r, maju, -1.0, 3.0, dt)
			r = h.keadaan
			if h.tabrak and h.jenis_tabrak == "anjing_penjaga":
				tabrak += 1
			bel = Bel.langkah(bel, dt)
			if pakai_bel and absf(maju - 17.0) < dt * 1.5:
				var ketuk: Bel.Hasil = Bel.ketuk(bel, false)
				bel = ketuk.keadaan
				if Bel.berbunyi(ketuk.bunyi):
					r = RintanganRute.terapkan_bel(r, maju).keadaan
			if r.daftar[0].anjing.status == AnjingPenjaga.Status.MENGEJAR:
				dikejar = true
		if pakai_bel:
			check(tabrak == 0 and not dikejar, "dengan bel 3 ubin sebelum anjing: anjing mundur, tidak pernah mengejar, tanpa tabrakan")
		else:
			check(tabrak == 1 and dikejar, "tanpa bel: anjing mengejar dan menabrak pemain santai di sisinya")
