class_name TesSkor
extends RefCounted
## Tes logika murni skor, combo, koin, tip, tepat, dan rumah terantar run fase3b-rintangan-skor (AC-9 sampai AC-12, AC-23 b sisi skor;
## K-2, K-4, O-1 sampai O-5).
##
## Oracle independen (AC-25, pelajaran QA-008 run 2B dan QA-001/002 run 3A): skor, koin, pengali, dan persegi inti ditulis literal di sini
## (dihitung tangan dari angka BALANCING 5 dan 7), bukan dengan memanggil fungsi yang dites. Pemberi tip diperiksa atas sapuan seed.

const FOLDER: String = "res://assets/data/routes/perumahan"
const LEBAR: float = 780.0
## Jeda lepas animasi lempar: frame 2 dari 4 di 12 fps, detik.
const JEDA_LEPAS: float = 2.0 / 12.0

var _cek: Callable
var _judul: Callable
var _pustaka_cache: Array[SegmenRute] = []


func _init(cek: Callable, judul: Callable) -> void:
	_cek = cek
	_judul = judul


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_test_config()
	_test_pengali_combo()
	_test_pengali_kecepatan()
	_test_skor_literal()
	_test_urutan_nilai()
	_test_putus_combo_dan_combo_maks()
	_test_koin_tidak_berkurang()
	_test_inti_tepat_literal()
	_test_tepat_lewat_koran()
	_test_pemberi_tip_berseed()
	_test_rute_penuh_375_koin()
	_test_ngebut_skor_lebih_tinggi()


func _pustaka() -> Array[SegmenRute]:
	if _pustaka_cache.is_empty():
		_pustaka_cache = PemuatRute.muat_folder(FOLDER).segmen
	return _pustaka_cache


func _rute(benih: int) -> RouteBuilder.Rute:
	return RouteBuilder.bangun(benih, _pustaka()).rute


func _test_config() -> void:
	_judul.call("Skor dan koin: angka Config literal (AC-24, BALANCING 5 dan 7)")
	var harapan: Dictionary = {
		"SKOR_SASARAN_DASAR": 100, "SKOR_PERSEN_PENUH": 100, "SKOR_PERSEN_HALAMAN": 50, "SKOR_COMBO_AWAL": 1.0, "SKOR_COMBO_LANGKAH": 0.1,
		"SKOR_COMBO_MAKS": 2.0, "SKOR_PENGALI_SANTAI": 1.0, "SKOR_PENGALI_CEPAT": 1.2, "SKOR_PENGALI_NGEBUT": 1.5, "SKOR_TEPAT_PENGALI": 1.25,
		"KOIN_ONGKOS_ANTAR": 15, "KOIN_TIP": 5, "RUTE_PEMBERI_TIP_PERSEN": 30,
	}
	var nilai: Dictionary = (load("res://scripts/config.gd") as GDScript).get_script_constant_map()
	for nama: String in harapan:
		check(nilai.has(nama) and is_equal_approx(float(nilai[nama]), float(harapan[nama])), "Config.%s = %s" % [nama, harapan[nama]])
	check(Config.JALAN_UJI_SEBERANG_KOTAK_SURAT_INTI_UBIN == [-2.5, 1.625, 0.5, 0.5] and Config.JALAN_UJI_DEKAT_KOTAK_SURAT_INTI_UBIN == [1.875, 1.625, 0.5, 0.5], "inti tepat seberang [-2,5; 1,625; 0,5; 0,5], dekat [1,875; 1,625; 0,5; 0,5]")
	# Inti tepat di pusat area kotak surat dan di dalamnya (K-4).
	for pasangan: Array in [[Config.JALAN_UJI_SEBERANG_KOTAK_SURAT_UBIN, Config.JALAN_UJI_SEBERANG_KOTAK_SURAT_INTI_UBIN], [Config.JALAN_UJI_DEKAT_KOTAK_SURAT_UBIN, Config.JALAN_UJI_DEKAT_KOTAK_SURAT_INTI_UBIN]]:
		var area: Rect2 = Rect2(pasangan[0][0], pasangan[0][1], pasangan[0][2], pasangan[0][3])
		var inti: Rect2 = Rect2(pasangan[1][0], pasangan[1][1], pasangan[1][2], pasangan[1][3])
		check(area.get_center().is_equal_approx(inti.get_center()) and area.encloses(inti), "inti %s berpusat sama dengan area %s dan di dalamnya" % [inti, area])


func _test_pengali_combo() -> void:
	_judul.call("Combo (AC-10): x1,0 lalu +0,1 tiap antaran beruntun, maksimum x2,0; antaran yang dinilai memakai pengali sebelum naik")
	var tabel: Array = [[0, 1.0], [1, 1.1], [2, 1.2], [5, 1.5], [9, 1.9], [10, 2.0], [11, 2.0], [40, 2.0], [-3, 1.0]]
	for baris: Array in tabel:
		check(is_equal_approx(SkorRute.pengali_combo(baris[0]), baris[1]), "beruntun sebelum %d -> x%s" % [baris[0], baris[1]])


func _test_pengali_kecepatan() -> void:
	_judul.call("Pengali kecepatan saat lepas (O-5): pita sprite dari kecepatan sebenarnya; santai x1,0, cepat x1,2, ngebut x1,5")
	var tabel: Array = [[0.0, 1.0], [1.5, 1.0], [3.0, 1.0], [3.98, 1.0], [4.0, 1.2], [4.5, 1.2], [5.39, 1.2], [5.41, 1.5], [6.0, 1.5], [NAN, 1.0], [INF, 1.0]]
	for baris: Array in tabel:
		check(is_equal_approx(SkorRute.pengali_kecepatan(baris[0]), baris[1]), "kecepatan %s u/d -> x%s" % [baris[0], baris[1]])


func _test_skor_literal() -> void:
	_judul.call("Skor murni (AC-9): dasar 100 x persen sasaran x combo x kecepatan x tepat, dibulatkan setengah ke atas; oracle literal")
	var H: Dictionary = {"kotak": ZonaSasaran.Hasil.KOTAK_SURAT, "teras": ZonaSasaran.Hasil.TERAS, "halaman": ZonaSasaran.Hasil.HALAMAN, "jendela": ZonaSasaran.Hasil.JENDELA, "meleset": ZonaSasaran.Hasil.MELESET, "bukan": ZonaSasaran.Hasil.BUKAN_PELANGGAN}
	# [hasil, jendela bonus, beruntun sebelum, kecepatan, tepat, skor harapan]
	var tabel: Array = [
		["kotak", false, 0, 3.0, false, 100],
		["kotak", false, 1, 4.5, false, 132],
		["halaman", false, 1, 6.0, false, 83],
		["teras", false, 10, 6.0, false, 300],
		["kotak", false, 0, 3.0, true, 125],
		["kotak", false, 3, 6.0, true, 244],
		["halaman", false, 0, 3.0, false, 50],
		["halaman", false, 0, 3.0, true, 50],
		["teras", false, 0, 3.0, true, 100],
		["jendela", true, 2, 4.5, false, 144],
		["jendela", false, 2, 4.5, false, 0],
		["meleset", false, 5, 6.0, true, 0],
		["bukan", true, 5, 6.0, false, 0],
		["teras", false, 4, 4.5, false, 168],
		["halaman", false, 3, 4.5, false, 78],
		["kotak", false, 20, 1.5, false, 200],
	]
	for t: Array in tabel:
		var dapat: int = SkorRute.skor_antaran(H[t[0]], t[1], t[2], t[3], t[4])
		check(dapat == t[5], "%s (jendela bonus %s), beruntun %d, %s u/d, tepat %s -> %d (dapat %d)" % [t[0], t[1], t[2], t[3], t[4], t[5], dapat])
	check(SkorRute.persen_sasaran(ZonaSasaran.Hasil.HALAMAN, false) == 50 and SkorRute.persen_sasaran(ZonaSasaran.Hasil.TERAS, false) == 100 and SkorRute.persen_sasaran(ZonaSasaran.Hasil.JENDELA, false) == 0 and SkorRute.persen_sasaran(ZonaSasaran.Hasil.JENDELA, true) == 100, "persen sasaran: halaman 50, teras 100, jendela penalti 0, jendela bonus 100")


func _test_urutan_nilai() -> void:
	_judul.call("Urutan antaran (AC-10, AC-11, O-1, O-2): combo, rumah terantar netral, halaman mengunci rumah, tip hanya teras pemberi tip")
	var k: SkorRute.Keadaan = SkorRute.awal()
	var h: SkorRute.Hasil = SkorRute.nilai(k, ZonaSasaran.Hasil.KOTAK_SURAT, "a@6", false, 3.0, true, false)
	check(h.status == SkorRute.Status.ANTAR and h.skor_tambah == 100 and h.koin_tambah == 15 and h.tip == 0 and h.urutan_beruntun == 1 and h.penanda == ZonaSasaran.Penanda.CENTANG, "1. kotak surat rumah a: +100 skor, +15 koin, tanpa tip (tip hanya teras), urutan 1, centang")
	check(k.skor == 0 and k.terantar.is_empty(), "masukan tidak diubah")
	k = h.keadaan
	h = SkorRute.nilai(k, ZonaSasaran.Hasil.TERAS, "b@10", false, 3.0, true, false)
	check(h.skor_tambah == 110 and h.koin_tambah == 20 and h.tip == 5 and h.urutan_beruntun == 2 and is_equal_approx(h.pengali_combo, 1.1), "2. teras rumah b pemberi tip: +110 (x1,1), +15 ongkos +5 tip")
	k = h.keadaan
	h = SkorRute.nilai(k, ZonaSasaran.Hasil.HALAMAN, "c@14", false, 4.5, false, false)
	check(h.skor_tambah == 72 and h.koin_tambah == 15 and h.penanda == ZonaSasaran.Penanda.SETENGAH and h.urutan_beruntun == 3, "3. halaman rumah c, cepat: 50 x combo 1,2 x cepat 1,2 = 72, ongkos penuh 15 (O-2), penanda setengah")
	k = h.keadaan
	h = SkorRute.nilai(k, ZonaSasaran.Hasil.KOTAK_SURAT, "a@6", true, 6.0, true, false)
	check(h.status == SkorRute.Status.ULANG and h.skor_tambah == 0 and h.koin_tambah == 0 and h.penanda == ZonaSasaran.Penanda.NETRAL and h.keadaan.beruntun == 3, "4. koran kedua ke rumah a (sudah terantar): 0 skor, 0 koin, combo tetap 3, penanda netral")
	k = h.keadaan
	h = SkorRute.nilai(k, ZonaSasaran.Hasil.KOTAK_SURAT, "c@14", false, 3.0, false, false)
	check(h.status == SkorRute.Status.ULANG and h.koin_tambah == 0, "5. kotak surat rumah c yang sudah diantar ke halaman: tetap ULANG (halaman mengunci rumah)")
	k = h.keadaan
	h = SkorRute.nilai(k, ZonaSasaran.Hasil.KOTAK_SURAT, "d@18", true, 3.0, false, false)
	check(h.status == SkorRute.Status.ANTAR and h.tepat and h.skor_tambah == 163 and h.penanda == ZonaSasaran.Penanda.TEPAT and h.urutan_beruntun == 4, "6. tepat rumah d, santai, combo x1,3: 100 x 1,3 x 1,25 = 162,5 -> 163, penanda TEPAT, koin sama (15)")
	check(h.koin_tambah == 15, "tepat tidak menambah koin")
	k = h.keadaan
	h = SkorRute.nilai(k, ZonaSasaran.Hasil.MELESET, "", false, 6.0, false, false)
	check(h.status == SkorRute.Status.TIDAK_SAH and h.skor_tambah == 0 and h.koin_tambah == 0 and h.keadaan.beruntun == 0 and h.penanda == ZonaSasaran.Penanda.SILANG and h.urutan_beruntun == 0, "7. meleset: 0, combo putus, silang")
	k = h.keadaan
	h = SkorRute.nilai(k, ZonaSasaran.Hasil.JENDELA, "f@22", false, 3.0, false, false)
	check(h.status == SkorRute.Status.TIDAK_SAH and not SkorRute.terantar(h.keadaan, "f@22"), "8. jendela penalti rumah f: tidak sah, rumah f belum terantar")
	k = h.keadaan
	h = SkorRute.nilai(k, ZonaSasaran.Hasil.KOTAK_SURAT, "f@22", false, 3.0, false, false)
	check(h.status == SkorRute.Status.ANTAR and h.skor_tambah == 100 and h.urutan_beruntun == 1, "9. kotak surat rumah f sesudahnya: antaran sah pertama, combo mulai lagi x1,0")
	k = h.keadaan
	h = SkorRute.nilai(k, ZonaSasaran.Hasil.BUKAN_PELANGGAN, "g@26", false, 3.0, true, true)
	check(h.status == SkorRute.Status.TIDAK_SAH and h.keadaan.beruntun == 0 and not SkorRute.terantar(h.keadaan, "g@26"), "10. rumah bukan pelanggan: tidak sah, combo putus, tidak terantar")
	k = h.keadaan
	h = SkorRute.nilai(k, ZonaSasaran.Hasil.JENDELA, "h@30", false, 3.0, false, true)
	check(h.status == SkorRute.Status.ANTAR and h.skor_tambah == 100 and h.penanda == ZonaSasaran.Penanda.BINTANG and h.koin_tambah == 15, "11. jendela dengan sakelar bonus: sah penuh, bintang, ongkos 15")
	k = h.keadaan
	h = SkorRute.nilai(k, ZonaSasaran.Hasil.KOTAK_SURAT, "a@6", false, 3.0, false, false)
	check(h.status == SkorRute.Status.ULANG, "12. rumah a sudah terantar tetap ULANG sampai rute baru")
	k = h.keadaan
	check(k.skor == 645 and k.koin == 95 and k.jumlah_antar == 6 and k.jumlah_tepat == 1 and k.jumlah_tip == 1, "total: skor 100 + 110 + 72 + 163 + 100 + 100 = 645, koin 15 + 20 + 15 + 15 + 15 + 15 = 95, 6 antaran, 1 tepat, 1 tip (dapat skor %d koin %d)" % [k.skor, k.koin])


func _test_putus_combo_dan_combo_maks() -> void:
	_judul.call("Combo maksimum x2,0 dan putus karena tabrakan (AC-6, AC-10)")
	var k: SkorRute.Keadaan = SkorRute.awal()
	var skor: Array[int] = []
	for i: int in range(14):
		var h: SkorRute.Hasil = SkorRute.nilai(k, ZonaSasaran.Hasil.KOTAK_SURAT, "r@%d" % i, false, 3.0, false, false)
		skor.append(h.skor_tambah)
		k = h.keadaan
	check(skor == [100, 110, 120, 130, 140, 150, 160, 170, 180, 190, 200, 200, 200, 200], "14 antaran beruntun santai: 100, 110, ..., 200, lalu tetap 200 (dapat %s)" % [skor])
	var p: SkorRute.Keadaan = SkorRute.putus_combo(k)
	check(p.beruntun == 0 and p.skor == k.skor and p.koin == k.koin and p.terantar.size() == 14 and k.beruntun == 14, "tabrakan: combo kembali 0 (x1,0); skor, koin, rumah terantar tetap; masukan tidak diubah")
	check(SkorRute.nilai(p, ZonaSasaran.Hasil.KOTAK_SURAT, "baru@1", false, 3.0, false, false).skor_tambah == 100, "antaran sesudah tabrakan: x1,0 lagi")


func _test_koin_tidak_berkurang() -> void:
	_judul.call("Koin dan skor tidak pernah berkurang (prinsip 2, AC-11): 3000 koran acak berseed")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20261017
	var hasil_semua: Array = [ZonaSasaran.Hasil.MELESET, ZonaSasaran.Hasil.KOTAK_SURAT, ZonaSasaran.Hasil.TERAS, ZonaSasaran.Hasil.HALAMAN, ZonaSasaran.Hasil.JENDELA, ZonaSasaran.Hasil.BUKAN_PELANGGAN]
	var k: SkorRute.Keadaan = SkorRute.awal()
	var naik: bool = true
	var koin_sah: bool = true
	for i: int in range(3000):
		var sebelum: SkorRute.Keadaan = k
		if rng.randi_range(0, 9) == 0:
			k = SkorRute.putus_combo(k)
		else:
			var h: SkorRute.Hasil = SkorRute.nilai(k, hasil_semua[rng.randi_range(0, hasil_semua.size() - 1)], "x@%d" % rng.randi_range(0, 40), rng.randi_range(0, 1) == 1, rng.randf_range(0.0, 6.0), rng.randi_range(0, 2) == 0, rng.randi_range(0, 1) == 1)
			if h.koin_tambah != 0 and h.koin_tambah != 15 and h.koin_tambah != 20:
				koin_sah = false
			k = h.keadaan
		if k.koin < sebelum.koin or k.skor < sebelum.skor:
			naik = false
	check(naik, "skor dan koin tidak pernah turun")
	check(koin_sah, "koin per koran hanya 0, 15, atau 20 (15 + tip 5)")
	check(k.terantar.size() <= 41 and k.koin == 15 * k.jumlah_antar + 5 * k.jumlah_tip, "koin = 15 x antaran + 5 x tip; satu antaran per rumah (paling banyak 41 rumah)")


func _test_inti_tepat_literal() -> void:
	_judul.call("Zona inti tepat 0,5 x 0,5 di pusat area kotak surat, kedua sisi, tepi min inklusif / maks eksklusif (AC-12)")
	var seberang: ZonaSasaran.Zona = ZonaSasaran.zona_rumah_seberang(10.0, true, 0, "s@10")[0]
	var dekat: ZonaSasaran.Zona = ZonaSasaran.zona_rumah_dekat(10.0, true, 0, "d@10")[0]
	check(seberang.jenis == ZonaSasaran.Jenis.KOTAK_SURAT and seberang.inti == Rect2(-2.5, 11.625, 0.5, 0.5), "inti seberang kavling 10: lateral -2,5..-2,0, maju 11,625..12,125")
	check(dekat.jenis == ZonaSasaran.Jenis.KOTAK_SURAT and dekat.inti == Rect2(1.875, 11.625, 0.5, 0.5), "inti dekat kavling 10: lateral 1,875..2,375, maju 11,625..12,125")
	check(not ZonaSasaran.zona_rumah_seberang(10.0, true)[1].inti.has_area(), "zona selain kotak surat tanpa inti")
	# [zona, titik jalan (lateral, maju), tepat?, kotak surat?]
	var kasus: Array = [
		[seberang, Vector2(-2.25, 11.875), true, true, "pusat"],
		[seberang, Vector2(-2.5, 11.625), true, true, "pojok min (inklusif)"],
		[seberang, Vector2(-2.0, 11.875), false, true, "tepi lateral maks -2,0 (eksklusif), masih area"],
		[seberang, Vector2(-2.25, 12.125), false, true, "tepi maju maks 12,125 (eksklusif), masih area"],
		[seberang, Vector2(-2.7, 11.3), false, true, "di area, luar inti"],
		[seberang, Vector2(-2.25, 12.6), false, false, "luar area"],
		[dekat, Vector2(2.125, 11.875), true, true, "pusat"],
		[dekat, Vector2(1.875, 11.625), true, true, "pojok min (inklusif)"],
		[dekat, Vector2(2.375, 11.7), false, true, "tepi lateral maks 2,375 (eksklusif), masih area"],
		[dekat, Vector2(1.8, 12.4), false, true, "di area, luar inti"],
	]
	for k: Array in kasus:
		var titik: Vector2 = Vector2(k[1].x, -k[1].y)
		var zona: ZonaSasaran.Zona = k[0]
		check(ZonaSasaran.tepat(zona, titik) == k[2] and ZonaSasaran.memuat(zona, titik) == k[3], "%s %s %s: tepat %s, kotak surat %s" % [LoperAnim.Sisi.keys()[zona.sisi], k[4], k[1], k[2], k[3]])
	var halaman: ZonaSasaran.Zona = ZonaSasaran.zona_rumah_seberang(10.0, true)[1]
	check(not ZonaSasaran.tepat(halaman, Vector2(-2.25, -11.875)) and not ZonaSasaran.tepat(null, Vector2.ZERO) and not ZonaSasaran.tepat(seberang, Vector2(NAN, 0.0)), "zona halaman, null, dan titik NaN tidak pernah tepat")


## Rute uji berisi satu rumah seberang di maju 10 (pelanggan atau bukan).
func _rute_satu_rumah(pelanggan: bool) -> RouteBuilder.Rute:
	var rute: RouteBuilder.Rute = RouteBuilder.Rute.new()
	var r: RouteBuilder.RumahRute = RouteBuilder.RumahRute.new()
	r.id = "uji@10"
	r.maju_ubin = 10.0
	r.sisi = LoperAnim.Sisi.SEBERANG
	r.pelanggan = pelanggan
	r.pelanggan_boleh = true
	rute.rumah = [r]
	rute.panjang_ubin = 40.0
	return rute


## Lintasan buatan yang mendarat di `titik` jalan sesudah 0,5 detik (tanpa jeda lepas), kecepatan saat lepas `v`.
func _lintasan_ke(titik_jalan: Vector2, v: float) -> ThrowSolver.Lintasan:
	var l: ThrowSolver.Lintasan = ThrowSolver.Lintasan.new()
	l.titik_mendarat = Vector2(titik_jalan.x, -titik_jalan.y)
	l.titik_lepas = Vector2(0.0, -titik_jalan.y)
	l.lama_terbang = 0.5
	l.kecepatan_maju_ud = v
	l.sisi = LoperAnim.Sisi.SEBERANG
	return l


func _test_tepat_lewat_koran() -> void:
	_judul.call("Tepat lewat KoranLempar: id rumah dicatat, mode bantu tidak pernah tepat (K-4, O-4)")
	var medan: MedanKoran = MedanKoran.dari_rute(_rute_satu_rumah(true))
	var pusat: KoranLempar.Koran = KoranLempar.langkah(KoranLempar.baru(_lintasan_ke(Vector2(-2.25, 11.875), 3.0)), 1.0, false, medan)
	check(pusat.mendarat and pusat.hasil == ZonaSasaran.Hasil.KOTAK_SURAT and pusat.tepat and pusat.id_rumah == "uji@10", "swipe ke pusat kotak surat pelanggan: KOTAK_SURAT, tepat, id uji@10")
	check(pusat.penanda == ZonaSasaran.Penanda.CENTANG, "penanda zona di KoranLempar tetap centang (penanda tepat dari SkorRute)")
	var bantu: KoranLempar.Koran = KoranLempar.langkah(KoranLempar.baru(_lintasan_ke(Vector2(-2.25, 11.875), 3.0), true), 1.0, false, medan)
	check(bantu.mendarat and bantu.hasil == ZonaSasaran.Hasil.KOTAK_SURAT and not bantu.tepat and bantu.bantu, "mode bantu ke titik yang sama: kotak surat biasa, tidak tepat (O-4)")
	var luar: KoranLempar.Koran = KoranLempar.langkah(KoranLempar.baru(_lintasan_ke(Vector2(-2.7, 11.3), 3.0)), 1.0, false, medan)
	check(luar.hasil == ZonaSasaran.Hasil.KOTAK_SURAT and not luar.tepat, "area di luar inti: kotak surat biasa")
	var bukan: KoranLempar.Koran = KoranLempar.langkah(KoranLempar.baru(_lintasan_ke(Vector2(-2.25, 11.875), 3.0)), 1.0, false, MedanKoran.dari_rute(_rute_satu_rumah(false)))
	check(bukan.hasil == ZonaSasaran.Hasil.BUKAN_PELANGGAN and not bukan.tepat and bukan.id_rumah == "uji@10", "inti rumah bukan pelanggan: BUKAN_PELANGGAN, tidak tepat")
	var meleset: KoranLempar.Koran = KoranLempar.langkah(KoranLempar.baru(_lintasan_ke(Vector2(0.0, 11.0), 3.0)), 1.0, false, medan)
	check(meleset.hasil == ZonaSasaran.Hasil.MELESET and meleset.id_rumah == "" and not meleset.tepat, "jalan: meleset, tanpa id rumah")
	check(KoranLempar.baru(_lintasan_ke(Vector2.ZERO, 3.0)).salin().bantu == false and KoranLempar.baru(_lintasan_ke(Vector2.ZERO, 3.0), true).salin().bantu, "salin membawa tanda bantu")
	var rute: RouteBuilder.Rute = _rute_satu_rumah(true)
	var h1: SkorRute.Hasil = SkorRute.nilai_koran(SkorRute.awal(), pusat, rute, false)
	var h2: SkorRute.Hasil = SkorRute.nilai_koran(SkorRute.awal(), bantu, rute, false)
	check(h1.skor_tambah == 125 and h1.penanda == ZonaSasaran.Penanda.TEPAT and h2.skor_tambah == 100 and h2.penanda == ZonaSasaran.Penanda.CENTANG and h1.koin_tambah == 15 and h2.koin_tambah == 15, "nilai_koran: swipe tepat 125 + penanda TEPAT; bantu 100 + centang; koin sama 15")


func _test_pemberi_tip_berseed() -> void:
	_judul.call("Pemberi tip berseed (O-3, AC-11): 30% dibulatkan ke bawah, seed sama = sama, himpunan bergantung seed")
	check(RouteBuilder.jumlah_pemberi_tip(25) == 7 and RouteBuilder.jumlah_pemberi_tip(10) == 3 and RouteBuilder.jumlah_pemberi_tip(4) == 1 and RouteBuilder.jumlah_pemberi_tip(3) == 0 and RouteBuilder.jumlah_pemberi_tip(0) == 0, "jumlah pemberi tip: 25 -> 7, 10 -> 3, 4 -> 1, 3 -> 0, 0 -> 0")
	var a: RouteBuilder.Rute = _rute(Config.RUTE_SEED_DEV)
	var b: RouteBuilder.Rute = _rute(Config.RUTE_SEED_DEV)
	check(a != null and b != null and a.id_pemberi_tip.keys() == b.id_pemberi_tip.keys(), "seed sama = pemberi tip sama")
	var himpunan: Dictionary = {}
	var semua_sah: bool = true
	for i: int in range(200):
		var r: RouteBuilder.Rute = _rute(1000 + i)
		if r == null:
			semua_sah = false
			continue
		var tip: Array = []
		var id_pelanggan: Dictionary = {}
		for p: RouteBuilder.RumahRute in r.pelanggan:
			id_pelanggan[p.id] = true
			if p.pemberi_tip:
				tip.append(p.id)
		for id: String in r.id_pemberi_tip:
			if not id_pelanggan.has(id):
				semua_sah = false
		for rumah: RouteBuilder.RumahRute in r.rumah:
			if rumah.pemberi_tip and not rumah.pelanggan:
				semua_sah = false
		if tip.size() != 7 or r.id_pemberi_tip.size() != 7 or not RouteBuilder.periksa_rute(r).is_empty():
			semua_sah = false
		tip.sort()
		himpunan[",".join(tip)] = true
	check(semua_sah, "200 seed: tepat 7 pemberi tip, semuanya pelanggan rute itu, rute tetap lolos periksa_rute")
	check(himpunan.size() >= 150, "200 seed memberi paling sedikit 150 himpunan pemberi tip berbeda (dapat %d)" % himpunan.size())
	# Rute dengan pelanggan yang dimutasi sehingga pemberi tip bukan pelanggan harus ditolak periksa_rute.
	var rusak: RouteBuilder.Rute = _rute(Config.RUTE_SEED_DEV)
	for rumah: RouteBuilder.RumahRute in rusak.rumah:
		if not rumah.pelanggan:
			rumah.pemberi_tip = true
			break
	check(not RouteBuilder.periksa_rute(rusak).is_empty(), "mutan: rumah bukan pelanggan bertanda pemberi tip ditolak periksa_rute")
	check(RouteBuilder.pemberi_tip(a, a.id_pemberi_tip.keys()[0]) and not RouteBuilder.pemberi_tip(a, "tidak@ada") and not RouteBuilder.pemberi_tip(null, "x"), "pemberi_tip(rute, id) membaca peta rute")


func _test_rute_penuh_375_koin() -> void:
	_judul.call("Simulasi rute penuh (AC-11): 25 pelanggan terantar semua = 375 koin + tip; satu antaran per pelanggan")
	var rute: RouteBuilder.Rute = _rute(Config.RUTE_SEED_DEV)
	if rute == null:
		check(false, "rute seed dev dibangun")
		return
	var medan: MedanKoran = MedanKoran.dari_rute(rute)
	# 1) Mode bantu santai dari lateral 0, 3 ubin sebelum pusat kotak surat tiap pelanggan: koran sungguhan lewat KoranLempar dan medan rute.
	var k: SkorRute.Keadaan = SkorRute.awal()
	var antar: int = 0
	var tepat: int = 0
	for p: RouteBuilder.RumahRute in rute.pelanggan:
		var maju: float = p.maju_ubin + 1.875 - 3.0
		var zona: Array[ZonaSasaran.Zona] = ZonaSasaran.zona_rute_rentang(rute.rumah, maju, maju + BantuLempar.jangkauan_maju_ubin(3.0, JEDA_LEPAS))
		var pilihan: BantuLempar.Pilihan = BantuLempar.pilih(LoperAnim.Sisi.SEBERANG, Vector2(0.0, -maju), 3.0, 0.0, JEDA_LEPAS, LEBAR, zona)
		if pilihan == null:
			continue
		var koran: KoranLempar.Koran = KoranLempar.langkah(KoranLempar.baru(pilihan.lintasan, true), ThrowSolver.lama_total(pilihan.lintasan) + 0.01, false, medan)
		var h: SkorRute.Hasil = SkorRute.nilai_koran(k, koran, rute, false)
		if h.status == SkorRute.Status.ANTAR and koran.id_rumah == p.id:
			antar += 1
		if h.tepat:
			tepat += 1
		k = h.keadaan
	check(antar == 25 and k.koin == 375 and tepat == 0, "mode bantu ke 25 kotak surat: 25 antaran, 375 koin (tanpa tip, tip hanya teras), 0 tepat (O-4) (dapat %d antaran, %d koin)" % [antar, k.koin])
	check(k.skor == 4450, "skor 25 antaran beruntun santai: 100 + 110 + ... + 200 (1650) + 14 x 200 = 4450 (dapat %d)" % k.skor)
	# Koran kedua ke semua pelanggan: tidak menambah apa pun (O-1).
	var ulang: SkorRute.Keadaan = k
	for p: RouteBuilder.RumahRute in rute.pelanggan:
		ulang = SkorRute.nilai(ulang, ZonaSasaran.Hasil.KOTAK_SURAT, p.id, false, 3.0, p.pemberi_tip, false).keadaan
	check(ulang.koin == 375 and ulang.skor == 4450 and ulang.beruntun == 25, "koran kedua ke 25 rumah yang sudah terantar: koin dan skor tetap, combo tetap")
	# 2) Semua ke teras: 375 + tip pemberi tip (7 x 5).
	var t: SkorRute.Keadaan = SkorRute.awal()
	for p: RouteBuilder.RumahRute in rute.pelanggan:
		t = SkorRute.nilai(t, ZonaSasaran.Hasil.TERAS, p.id, false, 3.0, RouteBuilder.pemberi_tip(rute, p.id), false).keadaan
	check(t.koin == 410 and t.jumlah_tip == 7, "25 teras: 375 ongkos + 7 tip x 5 = 410 koin (dapat %d)" % t.koin)
	check(t.koin >= 300 and k.koin <= 410, "hari rapi 25 rumah di patokan GDD 14.1 (300 sampai 375 ongkos, plus tip)")


func _test_ngebut_skor_lebih_tinggi() -> void:
	_judul.call("Ngebut punya harga dan hadiah (AC-23 b, sisi skor): antaran yang sama memberi skor lebih tinggi saat ngebut")
	var santai: int = SkorRute.nilai(SkorRute.awal(), ZonaSasaran.Hasil.KOTAK_SURAT, "a@1", false, Config.KECEPATAN_SANTAI_UD, false, false).skor_tambah
	var cepat: int = SkorRute.nilai(SkorRute.awal(), ZonaSasaran.Hasil.KOTAK_SURAT, "a@1", false, Config.KECEPATAN_CEPAT_UD, false, false).skor_tambah
	var ngebut: int = SkorRute.nilai(SkorRute.awal(), ZonaSasaran.Hasil.KOTAK_SURAT, "a@1", false, Config.KECEPATAN_NGEBUT_UD, false, false).skor_tambah
	check(santai == 100 and cepat == 120 and ngebut == 150, "kotak surat antaran pertama: santai 100, cepat 120, ngebut 150")
	var koin_santai: int = SkorRute.nilai(SkorRute.awal(), ZonaSasaran.Hasil.KOTAK_SURAT, "a@1", false, Config.KECEPATAN_SANTAI_UD, false, false).koin_tambah
	var koin_ngebut: int = SkorRute.nilai(SkorRute.awal(), ZonaSasaran.Hasil.KOTAK_SURAT, "a@1", false, Config.KECEPATAN_NGEBUT_UD, false, false).koin_tambah
	check(koin_santai == 15 and koin_ngebut == 15, "koin tidak bergantung kecepatan (ekonomi dekat patokan dunia nyata)")
