class_name TesBantu
extends RefCounted
## Tes logika murni mode bantu run fase2b-bantu-audio: tap di `TouchRouter` (AC-1, D-1), sisi tap `BantuLempar.sisi_tap` (AC-2, D-3),
## pemilihan sasaran `BantuLempar.pilih` (AC-3, D-4), selalu kena dan satu lintasan (AC-4), pembantu `ThrowSolver` baru, rentang zona
## jalan uji, dan waktu tanda tanpa sasaran (D-6).
##
## Oracle independen (pelajaran QA-008): sisi tap dibandingkan dengan rumus garis layar kemiringan 1:2 yang ditulis di sini (bukan
## `ThrowSolver.arah_tanah`); keterjangkauan kotak surat dihitung ulang di tes dengan angka BALANCING 4 yang ditulis literal (jarak
## 1,5..5,0, terbang 0,45..0,75, warisan 100%, tepi jalan 1,0) dan pencuplikan rapat u, bukan memanggil `BantuLempar.cari_kekuatan`.
##
## Dipanggil dari `tests/run_tests.gd` (`TesBantu.new(check, judul).jalankan()`). Tanpa node: waktu selalu parameter.

## Lebar viewport game uji (16:9, 19,5:9, 20:9).
const LEBAR: Array[int] = [640, 780, 800]
## Jeda lepas animasi lempar: frame 2 dari 4 di 12 fps (`LemparWaktu.waktu_lepas`), detik.
const JEDA_LEPAS: float = 2.0 / 12.0
## Lebar viewport untuk tes sasaran.
const LEBAR_SASARAN: float = 780.0

var _cek: Callable
var _judul: Callable


func _init(cek: Callable, judul: Callable) -> void:
	_cek = cek
	_judul = judul


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_test_pembantu_solver()
	_test_tap_ambang()
	_test_tap_tarik_kembali()
	_test_tap_dua_jari_dan_batal()
	_test_tap_kidal()
	_test_sisi_tap()
	_test_rentang_zona()
	_test_sasaran_dasar()
	_test_sasaran_tepi()
	_test_selalu_kena()
	_test_tanda()


# --- Pembantu ---

## Router baru selebar `lebar` dengan perekam sinyal: {"tap": [[posisi, durasi]], "swipe": [[awal, akhir]]}.
func _router(lebar: int, kidal: bool = false) -> Array:
	var router: TouchRouter = TouchRouter.new()
	router.lebar_viewport = lebar
	router.atur_kidal(kidal)
	var catatan: Dictionary = {"tap": [], "swipe": []}
	router.tap_selesai.connect(func(posisi: Vector2, durasi: float) -> void: (catatan["tap"] as Array).append([posisi, durasi]))
	router.swipe_selesai.connect(func(awal: Vector2, akhir: Vector2, _d: float) -> void: (catatan["swipe"] as Array).append([awal, akhir]))
	return [router, catatan]


## Sisi yang DIHARAPKAN dari garis layar (oracle independen D-3): garis searah jalan di layar lewat titik pijak sepeda punya kemiringan
## 1:2 (naik 1 tiap 2 ke kanan). d = (y tap - y sepeda) + (x tap - x sepeda) / 2; d < 0 = di atas garis = SEBERANG, d >= 0 = DEKAT.
func _sisi_harapan(tap: Vector2, sepeda: Vector2) -> LoperAnim.Sisi:
	var d: float = (tap.y - sepeda.y) + (tap.x - sepeda.x) / 2.0
	return LoperAnim.Sisi.SEBERANG if d < 0.0 else LoperAnim.Sisi.DEKAT


## f(u) oracle (angka BALANCING 4 literal): |sasaran - lepas - maju x geser(u)| - jarak(u), dalam koordinat JALAN (x lateral, y maju).
func _f_oracle(pusat_jalan: Vector2, lepas_jalan: Vector2, v: float, u: float) -> float:
	var jarak: float = 1.5 + 3.5 * u
	var geser: float = v * 1.0 * (0.45 + 0.3 * u)
	var r: Vector2 = Vector2(pusat_jalan.x - lepas_jalan.x, pusat_jalan.y - lepas_jalan.y - geser)
	return r.length() - jarak


## Titik lepas oracle dalam koordinat jalan: lateral + vl x jeda dijepit ke +-2 (tepi jalan resmi = tepi trotoar), maju + v x jeda.
func _lepas_oracle(lateral: float, maju: float, v: float, vl: float, jeda: float) -> Vector2:
	return Vector2(clampf(lateral + vl * jeda, -2.0, 2.0), maju + v * jeda)


## Keterjangkauan oracle: 1 = pasti terjangkau (ada perubahan tanda f di [0, 1] dengan jarak aman), 0 = pasti tidak, -1 = di dekat batas
## (|f| di ujung < 0,01: tidak dibandingkan). Dicuplik 200 titik u.
func _terjangkau_oracle(pusat_jalan: Vector2, lepas_jalan: Vector2, v: float) -> int:
	var f0: float = _f_oracle(pusat_jalan, lepas_jalan, v, 0.0)
	var f1: float = _f_oracle(pusat_jalan, lepas_jalan, v, 1.0)
	if absf(f0) < 0.01 or absf(f1) < 0.01:
		return -1
	var ada_positif: bool = false
	var ada_negatif: bool = false
	for i: int in range(201):
		var f: float = _f_oracle(pusat_jalan, lepas_jalan, v, float(i) / 200.0)
		if f >= 0.0:
			ada_positif = true
		if f <= 0.0:
			ada_negatif = true
	return 1 if ada_positif and ada_negatif else 0


func _zona_jalan_uji(indeks: Array[int]) -> Array[ZonaSasaran.Zona]:
	var hasil: Array[ZonaSasaran.Zona] = []
	for i: int in indeks:
		hasil.append_array(ZonaSasaran.zona_jalan_uji(i))
	return hasil


func _nama(p: BantuLempar.Pilihan) -> String:
	if p == null:
		return "null"
	return "rumah %d %s" % [p.zona.rumah, LoperAnim.Sisi.keys()[p.zona.sisi]]


# --- ThrowSolver: pembantu baru ---

func _test_pembantu_solver() -> void:
	_judul.call("ThrowSolver: geser maju dan panjang untuk kekuatan (pembantu mode bantu)")
	check(is_equal_approx(ThrowSolver.geser_maju_ubin(3.0, 0.0), 1.35) and is_equal_approx(ThrowSolver.geser_maju_ubin(6.0, 1.0), 4.5) and is_equal_approx(ThrowSolver.geser_maju_ubin(4.5, 0.5), 2.7), "geser maju = v x 100% x lama terbang: 3,0 di u 0 = 1,35; 6,0 di u 1 = 4,5; 4,5 di u 0,5 = 2,7")
	check(ThrowSolver.geser_maju_ubin(-2.0, 0.5) == 0.0 and ThrowSolver.geser_maju_ubin(NAN, 0.5) == 0.0 and ThrowSolver.geser_maju_ubin(INF, 0.5) == 0.0, "geser maju: kecepatan negatif, NaN, tak hingga = 0")
	check(is_equal_approx(ThrowSolver.panjang_untuk_kekuatan(0.0, 800.0), 48.0) and is_equal_approx(ThrowSolver.panjang_untuk_kekuatan(1.0, 800.0), 280.0) and is_equal_approx(ThrowSolver.panjang_untuk_kekuatan(0.5, 800.0), 164.0), "panjang untuk kekuatan di 800: u 0 = 48, u 1 = 280, u 0,5 = 164 px")
	check(is_equal_approx(ThrowSolver.panjang_untuk_kekuatan(2.0, 800.0), 280.0) and is_equal_approx(ThrowSolver.panjang_untuk_kekuatan(NAN, 800.0), 48.0) and ThrowSolver.panjang_untuk_kekuatan(0.5, 0.0) == INF, "panjang untuk kekuatan: u dijepit, NaN = 0, lebar tidak sah = INF")
	var pulang: bool = true
	for lebar: int in LEBAR:
		for i: int in range(11):
			var u: float = float(i) / 10.0
			if absf(ThrowSolver.kekuatan(ThrowSolver.panjang_untuk_kekuatan(u, float(lebar)), float(lebar)) - u) > 0.00001:
				pulang = false
	check(pulang, "kekuatan(panjang_untuk_kekuatan(u)) = u di 640/780/800")
	var l: ThrowSolver.Lintasan = ThrowSolver.hitung(120.0, 780.0, Iso.ARAH_SEBERANG, Vector2(0.0, -4.0), 4.5, 0.0, JEDA_LEPAS)
	check(l != null and is_equal_approx(l.geser_maju, 4.5 * (0.45 + 0.3 * l.kekuatan)), "hitung memakai geser maju yang sama (v x lama terbang)")


# --- AC-1 tap di TouchRouter ---

func _test_tap_ambang() -> void:
	_judul.call("Tap: |v| maksimum di bawah min 6% = tap, tepat min = swipe (AC-1, D-1)")
	# 800: min = 48 tepat terwakili float, jadi batas inklusif teruji tanpa derau.
	var pasang: Array = _router(800)
	var router: TouchRouter = pasang[0]
	var catatan: Dictionary = pasang[1]
	router.tekan(1, Vector2(400, 200), 0.0)
	router.geser(1, Vector2(447.99, 200))
	router.lepas(1, Vector2(447.99, 200), 0.3)
	check((catatan["tap"] as Array).size() == 1 and (catatan["swipe"] as Array).size() == 1, "800: |v| 47,99 (min - 0,01) = tap; swipe_selesai tetap dipancarkan sekali")
	check((catatan["tap"] as Array).size() == 1 and (catatan["tap"][0][0] as Vector2) == Vector2(400, 200) and is_equal_approx(catatan["tap"][0][1], 0.3), "posisi tap = titik awal sentuhan (400, 200), durasi 0,3")
	router.tekan(1, Vector2(400, 200), 1.0)
	router.geser(1, Vector2(448, 200))
	router.lepas(1, Vector2(448, 200), 1.1)
	check((catatan["tap"] as Array).size() == 1 and (catatan["swipe"] as Array).size() == 2, "800: |v| tepat 48 (min, inklusif) = swipe, bukan tap")
	router.tekan(1, Vector2(400, 200), 2.0)
	router.geser(1, Vector2(400, 200 - 47.9))
	router.lepas(1, Vector2(400, 200 - 47.9), 2.1)
	check((catatan["tap"] as Array).size() == 2, "800: geser tegak 47,9 = tap (|v| penuh, bukan komponen datar)")
	router.tekan(1, Vector2(400, 200), 3.0)
	router.geser(1, Vector2(400 + 30, 200 + 40))
	router.lepas(1, Vector2(400 + 30, 200 + 40), 3.1)
	check((catatan["tap"] as Array).size() == 2, "800: geser serong (30, 40) = |v| 50 >= 48 = swipe (panjang Euklides)")
	router.tekan(1, Vector2(400, 200), 4.0)
	router.lepas(1, Vector2(400, 200), 64.0)
	check((catatan["tap"] as Array).size() == 3, "tap tidak dibatasi durasi (ditahan 60 detik tetap tap)")
	router.tekan(1, Vector2(400, 200), 70.0)
	router.lepas(1, Vector2(460, 200), 70.1)
	check((catatan["tap"] as Array).size() == 3 and router.jumlah_tap_selesai == 3, "lepas di posisi jauh tanpa geser (|v_lepas| 60) bukan tap: posisi lepas ikut dihitung")
	# 640 dan 780: min = 38,4 dan 46,8 (tidak tepat float), toleransi ThrowSolver.
	for lebar: int in [640, 780]:
		var p: Array = _router(lebar)
		var r: TouchRouter = p[0]
		var c: Dictionary = p[1]
		var minimum: float = 0.06 * float(lebar)
		r.tekan(1, Vector2(400, 200), 0.0)
		r.geser(1, Vector2(400 + minimum - 0.01, 200))
		r.lepas(1, Vector2(400 + minimum - 0.01, 200), 0.1)
		r.tekan(1, Vector2(400, 200), 1.0)
		r.geser(1, Vector2(400 + minimum, 200))
		r.lepas(1, Vector2(400 + minimum, 200), 1.1)
		check((c["tap"] as Array).size() == 1 and (c["swipe"] as Array).size() == 2, "%d: min - 0,01 = tap, tepat min %.1f = swipe" % [lebar, minimum])
	check(router.panjang_swipe_maks() == 0.0, "tanpa swipe ditahan: panjang maksimum 0")


func _test_tap_tarik_kembali() -> void:
	_judul.call("Tap: sentuhan yang pernah >= min lalu ditarik kembali bukan tap (AC-1, D-1)")
	var pasang: Array = _router(800)
	var router: TouchRouter = pasang[0]
	var catatan: Dictionary = pasang[1]
	router.tekan(1, Vector2(400, 200), 0.0)
	router.geser(1, Vector2(460, 200))
	check(is_equal_approx(router.panjang_swipe_maks(), 60.0), "panjang maksimum tercatat 60 saat ditahan")
	router.geser(1, Vector2(401, 200))
	check(is_equal_approx(router.panjang_swipe_maks(), 60.0), "panjang maksimum tidak turun saat jari kembali")
	router.lepas(1, Vector2(401, 200), 0.5)
	check((catatan["tap"] as Array).size() == 0 and (catatan["swipe"] as Array).size() == 1, "tarik ke 60 lalu kembali ke 1 px: bukan tap (tetap batal sebagai swipe pendek)")
	router.tekan(1, Vector2(400, 200), 1.0)
	router.geser(1, Vector2(400, 150))
	router.geser(1, Vector2(400, 200))
	router.lepas(1, Vector2(400, 200), 1.5)
	check((catatan["tap"] as Array).size() == 0, "tarik ke atas 50 lalu kembali tepat ke titik awal: bukan tap")
	router.tekan(1, Vector2(400, 200), 2.0)
	router.geser(1, Vector2(440, 200))
	router.geser(1, Vector2(400, 200))
	router.lepas(1, Vector2(400, 200), 2.5)
	check((catatan["tap"] as Array).size() == 1, "geser 40 (< 48) lalu kembali: tap")
	router.tekan(1, Vector2(400, 200), 3.0)
	check(router.panjang_swipe_maks() == 0.0, "sentuhan baru mulai dari panjang maksimum 0")
	router.lepas(1, Vector2(400, 200), 3.1)


func _test_tap_dua_jari_dan_batal() -> void:
	_judul.call("Tap: dua jari, slot swipe terisi, batal, di luar zona (AC-1, D-1)")
	var pasang: Array = _router(780)
	var router: TouchRouter = pasang[0]
	var catatan: Dictionary = pasang[1]
	# Stick + tap bersamaan.
	router.tekan(0, Vector2(100, 260), 0.0)
	router.geser(0, Vector2(100, 225))
	router.tekan(1, Vector2(500, 200), 0.1)
	router.lepas(1, Vector2(500, 200), 0.2)
	check((catatan["tap"] as Array).size() == 1 and router.stick_aktif() and router.vektor_stick().y > 0.9, "stick ditahan + tap jari kedua: tap tercatat, stick tetap aktif ke atas")
	router.lepas(0, Vector2(100, 225), 0.3)
	check((catatan["tap"] as Array).size() == 1, "melepas stick bukan tap")
	# Jari kedua di zona swipe yang terisi diabaikan; jari pertama yang tidak bergeser = tap di posisinya sendiri.
	router.tekan(1, Vector2(500, 200), 1.0)
	router.tekan(2, Vector2(600, 150), 1.1)
	router.lepas(2, Vector2(600, 150), 1.2)
	check((catatan["tap"] as Array).size() == 1, "jari kedua di zona swipe yang terisi: diabaikan, bukan tap")
	router.lepas(1, Vector2(500, 200), 1.3)
	check((catatan["tap"] as Array).size() == 2 and (catatan["tap"][1][0] as Vector2) == Vector2(500, 200), "jari pertama yang diangkat = tap di titik awalnya (500, 200)")
	# batal dan batal_semua di tengah sentuhan.
	router.tekan(1, Vector2(500, 200), 2.0)
	router.batal(1)
	router.lepas(1, Vector2(500, 200), 2.1)
	check((catatan["tap"] as Array).size() == 2 and (catatan["swipe"] as Array).size() == 2, "batal di tengah: bukan tap, lepas sesudahnya diabaikan")
	router.tekan(1, Vector2(500, 200), 3.0)
	router.tekan(0, Vector2(100, 260), 3.0)
	router.batal_semua()
	router.lepas(1, Vector2(500, 200), 3.1)
	router.lepas(0, Vector2(100, 260), 3.1)
	check((catatan["tap"] as Array).size() == 2 and not router.swipe_aktif() and not router.stick_aktif(), "batal_semua di tengah: bukan tap")
	# Sentuhan di luar kedua zona (strip HUD atas) dan di zona stick bukan tap.
	router.tekan(1, Vector2(500, 20), 4.0)
	router.lepas(1, Vector2(500, 20), 4.1)
	router.tekan(1, Vector2(100, 260), 5.0)
	router.lepas(1, Vector2(100, 260), 5.1)
	check((catatan["tap"] as Array).size() == 2, "sentuhan di strip atas (tombol HUD) dan di zona stick: bukan tap")


func _test_tap_kidal() -> void:
	_judul.call("Tap kidal: zona swipe kiri (AC-1)")
	var pasang: Array = _router(780, true)
	var router: TouchRouter = pasang[0]
	var catatan: Dictionary = pasang[1]
	router.tekan(1, Vector2(150, 120), 0.0)
	router.lepas(1, Vector2(150, 120), 0.1)
	check((catatan["tap"] as Array).size() == 1 and (catatan["tap"][0][0] as Vector2) == Vector2(150, 120), "kidal: tap di (150, 120) (hanya zona swipe kidal) tercatat")
	router.tekan(1, Vector2(700, 260), 1.0)
	router.lepas(1, Vector2(700, 260), 1.1)
	check((catatan["tap"] as Array).size() == 1, "kidal: sentuhan di (700, 260) = zona stick kidal, bukan tap")
	router.tekan(1, Vector2(150, 340), 2.0)
	router.lepas(1, Vector2(150, 340), 2.1)
	check((catatan["tap"] as Array).size() == 2, "kidal: (150, 340) (zona stick bila tidak kidal) = tap")
	var p2: Array = _router(780, false)
	var r2: TouchRouter = p2[0]
	var c2: Dictionary = p2[1]
	r2.tekan(1, Vector2(150, 120), 0.0)
	r2.lepas(1, Vector2(150, 120), 0.1)
	r2.tekan(1, Vector2(150, 340), 0.2)
	r2.lepas(1, Vector2(150, 340), 0.3)
	check((c2["tap"] as Array).size() == 0, "tanpa kidal: (150, 120) di luar zona dan (150, 340) zona stick, bukan tap (kontrol)")


# --- AC-2 sisi tap ---

func _test_sisi_tap() -> void:
	_judul.call("Sisi tap dari garis jalan yang melewati sepeda (AC-2, D-3)")
	var sepeda_uji: Array[Vector2] = [Vector2(260, 270), Vector2(213, 270), Vector2(300, 230), Vector2(180, 310.5), Vector2(400, 120)]
	var cocok: bool = true
	var jumlah: int = 0
	var seberang: int = 0
	for sepeda: Vector2 in sepeda_uji:
		for x: int in range(0, 801, 23):
			for y: int in range(0, 361, 19):
				var tap: Vector2 = Vector2(x, y) + Vector2(0.25, 0.25)
				var dapat: LoperAnim.Sisi = BantuLempar.sisi_tap(tap, sepeda)
				jumlah += 1
				if dapat == LoperAnim.Sisi.SEBERANG:
					seberang += 1
				if dapat != _sisi_harapan(tap, sepeda):
					cocok = false
	check(cocok and jumlah > 2000 and seberang > 300 and seberang < jumlah - 300, "sisi tap = sisi garis layar 1:2 lewat sepeda untuk %d tap x 5 posisi sepeda (%d seberang)" % [jumlah, seberang])
	var s: Vector2 = Vector2(260, 270)
	check(BantuLempar.sisi_tap(s + Vector2(0, -30), s) == LoperAnim.Sisi.SEBERANG and BantuLempar.sisi_tap(s + Vector2(0, 30), s) == LoperAnim.Sisi.DEKAT, "tepat di atas sepeda = SEBERANG, tepat di bawah = DEKAT")
	check(BantuLempar.sisi_tap(s + Vector2(40, -20), s) == LoperAnim.Sisi.DEKAT and BantuLempar.sisi_tap(s + Vector2(-40, 20), s) == LoperAnim.Sisi.DEKAT and BantuLempar.sisi_tap(s, s) == LoperAnim.Sisi.DEKAT, "tepat di garis jalan (depan, belakang, titik pijak) = DEKAT")
	check(BantuLempar.sisi_tap(s + Vector2(40, -21), s) == LoperAnim.Sisi.SEBERANG and BantuLempar.sisi_tap(s + Vector2(40, -19), s) == LoperAnim.Sisi.DEKAT, "1 px di atas garis = SEBERANG, 1 px di bawah = DEKAT")
	var tap: Vector2 = Vector2(400, 200)
	check(BantuLempar.sisi_tap(tap, Vector2(260, 300)) == LoperAnim.Sisi.SEBERANG and BantuLempar.sisi_tap(tap, Vector2(260, 220)) == LoperAnim.Sisi.DEKAT, "garis ikut sepeda: tap (400, 200) seberang bila sepeda di (260, 300), dekat bila sepeda di (260, 220)")
	check(BantuLempar.sisi_tap(Vector2(NAN, 1), s) == LoperAnim.Sisi.TIDAK_ADA and BantuLempar.sisi_tap(tap, Vector2(INF, 0)) == LoperAnim.Sisi.TIDAK_ADA, "masukan tidak hingga atau NaN = TIDAK_ADA")


# --- Rentang zona jalan uji ---

func _test_rentang_zona() -> void:
	_judul.call("Zona jalan uji untuk rentang maju (jangkauan mode bantu)")
	var zona: Array[ZonaSasaran.Zona] = ZonaSasaran.zona_jalan_uji_rentang(0.0, 10.5)
	var rumah: Array[int] = []
	for z: ZonaSasaran.Zona in zona:
		if not rumah.has(z.rumah):
			rumah.append(z.rumah)
	check(zona.size() == 35 and str(rumah) == "[-1, 0, 1, 2, 3]", "maju 0 sampai 10,5: kavling -1 sampai 3 (satu cadangan tiap ujung), 35 zona")
	check(ZonaSasaran.zona_jalan_uji_rentang(8.0, 8.0).size() == 21 and ZonaSasaran.zona_jalan_uji_rentang(NAN, 3.0).is_empty(), "rentang satu titik = tiga kavling; NaN = kosong")
	check(is_equal_approx(BantuLempar.jangkauan_maju_ubin(6.0, JEDA_LEPAS), 1.0 + 5.0 + 4.5) and is_equal_approx(BantuLempar.jangkauan_maju_ubin(3.0, JEDA_LEPAS), 0.5 + 5.0 + 2.25) and is_equal_approx(BantuLempar.jangkauan_maju_ubin(0.0, JEDA_LEPAS), 5.0), "jangkauan maju: ngebut 10,5; santai 7,75; berhenti 5,0 ubin (jeda lepas + jarak terjauh + geser terjauh)")
	check(is_equal_approx(BantuLempar.jangkauan_maju_ubin(NAN, NAN), 5.0), "jangkauan maju: masukan tidak sah = 0 kecepatan")


# --- AC-3 pemilihan sasaran ---

func _test_sasaran_dasar() -> void:
	_judul.call("Sasaran: kotak surat pelanggan terdekat di depan, sisi benar (AC-3, D-4)")
	var semua: Array[ZonaSasaran.Zona] = _zona_jalan_uji([-1, 0, 1, 2, 3, 4])
	# m 0,5: kotak surat kavling 0 (pusat maju 1,875) di depan dan terjangkau di santai.
	var p: BantuLempar.Pilihan = BantuLempar.pilih(LoperAnim.Sisi.SEBERANG, Vector2(0.0, -0.5), 3.0, 0.0, JEDA_LEPAS, LEBAR_SASARAN, semua)
	check(p != null and p.zona.rumah == 0 and p.zona.jenis == ZonaSasaran.Jenis.KOTAK_SURAT and p.zona.sisi == LoperAnim.Sisi.SEBERANG and p.zona.pelanggan, "maju 0,5 seberang: kotak surat rumah 0 seberang (dapat %s)" % _nama(p))
	p = BantuLempar.pilih(LoperAnim.Sisi.DEKAT, Vector2(0.0, -0.5), 3.0, 0.0, JEDA_LEPAS, LEBAR_SASARAN, semua)
	check(p != null and p.zona.rumah == 0 and p.zona.sisi == LoperAnim.Sisi.DEKAT and p.zona.jenis == ZonaSasaran.Jenis.KOTAK_SURAT, "maju 0,5 dekat: kotak surat rumah 0 dekat (dapat %s)" % _nama(p))
	# Rumah 1 lebih jauh juga terjangkau; yang terdekat dipilih.
	var pusat_jalan_1: Vector2 = Vector2(-2.25, 5.875)
	check(_terjangkau_oracle(pusat_jalan_1, _lepas_oracle(0.0, 0.5, 3.0, 0.0, JEDA_LEPAS), 3.0) == 1, "kontrol: kotak surat rumah 1 (maju 5,875) juga terjangkau dari maju 0,5 (pilihan terdekat benar-benar memilih)")
	# m 8: rumah 2 seberang bukan pelanggan (2 mod 4 = 2) dilewati ke rumah 3; sisi dekat rumah 2 selalu pelanggan.
	check(not ZonaSasaran.pelanggan_jalan_uji(2) and ZonaSasaran.pelanggan_jalan_uji(3), "kontrol: rumah 2 seberang bukan pelanggan, rumah 3 pelanggan")
	p = BantuLempar.pilih(LoperAnim.Sisi.SEBERANG, Vector2(0.0, -8.0), 3.0, 0.0, JEDA_LEPAS, LEBAR_SASARAN, semua)
	check(p != null and p.zona.rumah == 3 and p.zona.sisi == LoperAnim.Sisi.SEBERANG, "maju 8 seberang: rumah 2 bukan pelanggan dilewati, kotak surat rumah 3 dipilih (dapat %s)" % _nama(p))
	p = BantuLempar.pilih(LoperAnim.Sisi.DEKAT, Vector2(0.0, -8.0), 3.0, 0.0, JEDA_LEPAS, LEBAR_SASARAN, semua)
	check(p != null and p.zona.rumah == 2 and p.zona.sisi == LoperAnim.Sisi.DEKAT, "maju 8 dekat: kotak surat rumah 2 dekat (pelanggan) dipilih, bukan sisi seberang (dapat %s)" % _nama(p))
	# m 2,0: kotak surat rumah 0 (1,875) sudah di belakang walau masih terjangkau; rumah 1 dipilih.
	check(_terjangkau_oracle(Vector2(-2.25, 1.875), _lepas_oracle(0.0, 2.0, 3.0, 0.0, JEDA_LEPAS), 3.0) == 1, "kontrol: kotak surat rumah 0 di belakang (maju 1,875 < 2,0) masih terjangkau lintasan")
	p = BantuLempar.pilih(LoperAnim.Sisi.SEBERANG, Vector2(0.0, -2.0), 3.0, 0.0, JEDA_LEPAS, LEBAR_SASARAN, semua)
	check(p != null and p.zona.rumah == 1, "maju 2,0: kotak surat di belakang sepeda tidak dipilih, rumah 1 di depan (dapat %s)" % _nama(p))
	# Hanya zona sisi lain = null.
	var dekat_saja: Array[ZonaSasaran.Zona] = []
	for z: ZonaSasaran.Zona in semua:
		if z.sisi == LoperAnim.Sisi.DEKAT:
			dekat_saja.append(z)
	check(BantuLempar.pilih(LoperAnim.Sisi.SEBERANG, Vector2(0.0, -0.5), 3.0, 0.0, JEDA_LEPAS, LEBAR_SASARAN, dekat_saja) == null, "hanya zona sisi dekat, tap seberang = null (tidak memilih sisi lain)")
	# Kotak surat terlalu jauh di depan; satu-satunya kandidat bukan pelanggan; daftar kosong.
	var jauh: Array[ZonaSasaran.Zona] = _zona_jalan_uji([5])
	check(_terjangkau_oracle(Vector2(-2.25, 21.875), _lepas_oracle(0.0, 0.5, 3.0, 0.0, JEDA_LEPAS), 3.0) == 0, "kontrol: kotak surat rumah 5 (maju 21,875) tidak terjangkau dari maju 0,5")
	check(BantuLempar.pilih(LoperAnim.Sisi.SEBERANG, Vector2(0.0, -0.5), 3.0, 0.0, JEDA_LEPAS, LEBAR_SASARAN, jauh) == null, "kotak surat terlalu jauh di depan = null")
	check(BantuLempar.pilih(LoperAnim.Sisi.SEBERANG, Vector2(0.0, -8.0), 3.0, 0.0, JEDA_LEPAS, LEBAR_SASARAN, _zona_jalan_uji([2])) == null, "satu-satunya kotak surat seberang di depan bukan pelanggan = null")
	var kosong: Array[ZonaSasaran.Zona] = []
	check(BantuLempar.pilih(LoperAnim.Sisi.SEBERANG, Vector2(0.0, -0.5), 3.0, 0.0, JEDA_LEPAS, LEBAR_SASARAN, kosong) == null, "daftar zona kosong = null")
	check(BantuLempar.pilih(LoperAnim.Sisi.TIDAK_ADA, Vector2(0.0, -0.5), 3.0, 0.0, JEDA_LEPAS, LEBAR_SASARAN, semua) == null and BantuLempar.pilih(LoperAnim.Sisi.SEBERANG, Vector2(NAN, 0.0), 3.0, 0.0, JEDA_LEPAS, LEBAR_SASARAN, semua) == null, "sisi kosong atau posisi NaN = null")
	# Zona teras/halaman/jendela tidak pernah dipilih.
	var bukan_kotak: Array[ZonaSasaran.Zona] = []
	for z: ZonaSasaran.Zona in semua:
		if z.jenis != ZonaSasaran.Jenis.KOTAK_SURAT:
			bukan_kotak.append(z)
	check(BantuLempar.pilih(LoperAnim.Sisi.SEBERANG, Vector2(0.0, -0.5), 3.0, 0.0, JEDA_LEPAS, LEBAR_SASARAN, bukan_kotak) == null, "tanpa zona kotak surat (teras, halaman, jendela saja) = null")


func _test_sasaran_tepi() -> void:
	_judul.call("Sasaran: seri, cek ulang lewat ThrowSolver.hitung (AC-3, AC-4, D-4)")
	var pos: Vector2 = Vector2(0.0, -0.5)
	# Dua kotak surat pelanggan seberang dengan maju pusat sama: selisih lateral ke sepeda terkecil menang, lalu urutan daftar.
	var jauh_lateral: ZonaSasaran.Zona = ZonaSasaran.buat(Rect2(-2.25, 3.0, 0.5, 0.5), LoperAnim.Sisi.SEBERANG, ZonaSasaran.Jenis.KOTAK_SURAT, true, 10)
	var dekat_lateral: ZonaSasaran.Zona = ZonaSasaran.buat(Rect2(-1.75, 3.0, 0.5, 0.5), LoperAnim.Sisi.SEBERANG, ZonaSasaran.Jenis.KOTAK_SURAT, true, 11)
	var daftar: Array[ZonaSasaran.Zona] = [jauh_lateral, dekat_lateral]
	var p: BantuLempar.Pilihan = BantuLempar.pilih(LoperAnim.Sisi.SEBERANG, pos, 3.0, 0.0, JEDA_LEPAS, LEBAR_SASARAN, daftar)
	check(p != null and p.zona == dekat_lateral, "seri maju: selisih lateral ke sepeda terkecil dipilih (rumah 11; dapat %s)" % _nama(p))
	var kembar_a: ZonaSasaran.Zona = ZonaSasaran.buat(Rect2(-1.75, 3.0, 0.5, 0.5), LoperAnim.Sisi.SEBERANG, ZonaSasaran.Jenis.KOTAK_SURAT, true, 20)
	var kembar_b: ZonaSasaran.Zona = ZonaSasaran.buat(Rect2(-1.75, 3.0, 0.5, 0.5), LoperAnim.Sisi.SEBERANG, ZonaSasaran.Jenis.KOTAK_SURAT, true, 21)
	var kembar: Array[ZonaSasaran.Zona] = [kembar_a, kembar_b]
	p = BantuLempar.pilih(LoperAnim.Sisi.SEBERANG, pos, 3.0, 0.0, JEDA_LEPAS, LEBAR_SASARAN, kembar)
	check(p != null and p.zona == kembar_a, "seri penuh: yang pertama di daftar (rumah 20; dapat %s)" % _nama(p))
	# Cek ulang: pusat kotak surat pelanggan tertutup kotak surat bukan pelanggan yang lebih dulu di daftar (zona_kena = bukan pelanggan).
	var penutup: ZonaSasaran.Zona = ZonaSasaran.buat(Rect2(-2.0, 2.75, 1.0, 1.0), LoperAnim.Sisi.SEBERANG, ZonaSasaran.Jenis.KOTAK_SURAT, false, 30)
	var tertutup: Array[ZonaSasaran.Zona] = [penutup, dekat_lateral]
	check(ZonaSasaran.klasifikasi(BantuLempar.pusat_dunia(dekat_lateral), tertutup) == ZonaSasaran.Hasil.BUKAN_PELANGGAN, "kontrol: pusat kotak surat pelanggan dinilai BUKAN_PELANGGAN di daftar ini")
	check(BantuLempar.pilih(LoperAnim.Sisi.SEBERANG, pos, 3.0, 0.0, JEDA_LEPAS, LEBAR_SASARAN, tertutup) == null, "cek ulang: lintasan yang mendarat di zona lain (bukan pelanggan menang) ditolak = null")
	# Zona berukuran nol: pusatnya tidak dimuat (tepi maks eksklusif), cek ulang menolaknya.
	var nol: ZonaSasaran.Zona = ZonaSasaran.buat(Rect2(-1.5, 3.0, 0.0, 0.0), LoperAnim.Sisi.SEBERANG, ZonaSasaran.Jenis.KOTAK_SURAT, true, 40)
	var daftar_nol: Array[ZonaSasaran.Zona] = [nol]
	check(BantuLempar.pilih(LoperAnim.Sisi.SEBERANG, pos, 3.0, 0.0, JEDA_LEPAS, LEBAR_SASARAN, daftar_nol) == null, "cek ulang: zona berukuran nol tidak memuat titik mendarat = null")
	# Batas "di depan" D-4 inklusif (QA-004): pusat tepat di maju sepeda (0,5) = kandidat; sedikit di belakang bukan.
	var sejajar: ZonaSasaran.Zona = ZonaSasaran.buat(Rect2(-2.25, 0.25, 0.5, 0.5), LoperAnim.Sisi.SEBERANG, ZonaSasaran.Jenis.KOTAK_SURAT, true, 50)
	var belakang: ZonaSasaran.Zona = ZonaSasaran.buat(Rect2(-2.25, 0.2499, 0.5, 0.5), LoperAnim.Sisi.SEBERANG, ZonaSasaran.Jenis.KOTAK_SURAT, true, 51)
	check(sejajar.persegi.get_center() == Vector2(-2.0, 0.5) and BantuLempar.kandidat(sejajar, LoperAnim.Sisi.SEBERANG, pos), "di depan inklusif: pusat tepat di maju sepeda 0,5 = kandidat")
	check(not BantuLempar.kandidat(belakang, LoperAnim.Sisi.SEBERANG, pos), "di depan: pusat 0,4999 (di belakang maju sepeda 0,5) bukan kandidat")
	# Sepeda berhenti (titik lepas = posisi, tanpa geser maju): pusat sejajar 2 ubin ke seberang terjangkau (u = 0,5 / 3,5) dan dipilih.
	var daftar_sejajar: Array[ZonaSasaran.Zona] = [sejajar]
	p = BantuLempar.pilih(LoperAnim.Sisi.SEBERANG, pos, 0.0, 0.0, JEDA_LEPAS, LEBAR_SASARAN, daftar_sejajar)
	check(p != null and p.zona == sejajar and absf(p.kekuatan - 0.5 / 3.5) < 0.0001 and _dekat_v(p.lintasan.titik_mendarat, Vector2(-2.0, -0.5)), "di depan inklusif: sepeda berhenti, kotak surat sejajar dipilih dengan u 0,1429 dan mendarat di pusatnya (dapat %s)" % _nama(p))
	var daftar_belakang: Array[ZonaSasaran.Zona] = [belakang]
	check(BantuLempar.pilih(LoperAnim.Sisi.SEBERANG, pos, 0.0, 0.0, JEDA_LEPAS, LEBAR_SASARAN, daftar_belakang) == null, "di depan: kotak surat yang pusatnya sedikit di belakang tidak dipilih walau terjangkau = null")
	# Pencarian u langsung: oracle literal.
	var lepas: Vector2 = ThrowSolver.titik_lepas(Vector2(0.0, -0.5), 3.0, 0.0, JEDA_LEPAS)
	check(_dekat_v(lepas, Vector2(0.0, -1.0)), "kontrol: titik lepas santai dari maju 0,5 = maju 1,0")
	var u: float = BantuLempar.cari_kekuatan(Vector2(-1.625, -5.125), lepas, 3.0)
	check(u >= 0.0 and u <= 1.0 and absf(_f_oracle(Vector2(-1.625, 5.125), Vector2(0.0, 1.0), 3.0, u)) < 0.0001, "cari_kekuatan: f oracle (angka BALANCING 4 literal) ~ 0 di u %.4f" % u)
	check(BantuLempar.cari_kekuatan(Vector2(-1.625, -21.125), lepas, 3.0) == -1.0 and BantuLempar.cari_kekuatan(Vector2(-0.2, -1.2), lepas, 3.0) == -1.0, "cari_kekuatan: terlalu jauh dan terlalu dekat (di bawah jarak 1,5 + geser) = -1")
	check(BantuLempar.cari_kekuatan(Vector2(NAN, 0.0), lepas, 3.0) == -1.0, "cari_kekuatan: sasaran NaN = -1")


func _dekat_v(a: Vector2, b: Vector2, tol: float = 0.0001) -> bool:
	return absf(a.x - b.x) <= tol and absf(a.y - b.y) <= tol


# --- AC-4 selalu kena dan satu lintasan ---

func _test_selalu_kena() -> void:
	_judul.call("Selalu kena: lintasan = ThrowSolver.hitung, mendarat di kotak surat (AC-4, K-3)")
	var kecepatan: Array[float] = [3.0, 3.6, 4.5, 5.25, 6.0]
	var lateral: Array[float] = [-1.0, 0.0, 1.0]
	var lateral_ud: Array[float] = [-3.0, 0.0, 3.0]
	var total: int = 0
	var dipilih: int = 0
	var semua_kena: bool = true
	var semua_hitung: bool = true
	var u_sah: bool = true
	var syarat_kandidat: bool = true
	var terdekat_cocok: bool = true
	var dibandingkan: int = 0
	var gagal_contoh: String = ""
	for v: float in kecepatan:
		for x: float in lateral:
			for vl: float in lateral_ud:
				for sisi: LoperAnim.Sisi in [LoperAnim.Sisi.SEBERANG, LoperAnim.Sisi.DEKAT]:
					for i: int in range(32):
						var maju: float = 4.0 + float(i) * 0.25 + 0.0625
						var pos: Vector2 = Vector2(x, -maju)
						var daftar: Array[ZonaSasaran.Zona] = ZonaSasaran.zona_jalan_uji_rentang(maju, maju + BantuLempar.jangkauan_maju_ubin(v, JEDA_LEPAS))
						var p: BantuLempar.Pilihan = BantuLempar.pilih(sisi, pos, v, vl, JEDA_LEPAS, LEBAR_SASARAN, daftar)
						total += 1
						# Oracle terdekat: kandidat ditulis ulang di tes, keterjangkauan dari f literal.
						var lepas_jalan: Vector2 = _lepas_oracle(x, maju, v, vl, JEDA_LEPAS)
						var harapan: ZonaSasaran.Zona = null
						var ragu: bool = false
						for z: ZonaSasaran.Zona in daftar:
							var pusat: Vector2 = z.persegi.position + z.persegi.size / 2.0
							if z.jenis != ZonaSasaran.Jenis.KOTAK_SURAT or not z.pelanggan or z.sisi != sisi or pusat.y < maju:
								continue
							if harapan != null and (harapan.persegi.position.y + harapan.persegi.size.y / 2.0) <= pusat.y:
								continue
							var t: int = _terjangkau_oracle(pusat, lepas_jalan, v)
							if t == -1:
								ragu = true
							elif t == 1:
								harapan = z
						if not ragu:
							dibandingkan += 1
							if p == null and harapan != null or p != null and p.zona != harapan:
								terdekat_cocok = false
								gagal_contoh = "v %.2f x %.0f vl %.0f %s maju %.4f: dapat %s, harap %s" % [v, x, vl, LoperAnim.Sisi.keys()[sisi], maju, _nama(p), "null" if harapan == null else "rumah %d" % harapan.rumah]
						if p == null:
							continue
						dipilih += 1
						var l: ThrowSolver.Lintasan = p.lintasan
						var ulang: ThrowSolver.Lintasan = ThrowSolver.hitung(ThrowSolver.panjang_untuk_kekuatan(p.kekuatan, LEBAR_SASARAN), LEBAR_SASARAN, l.arah, pos, v, vl, JEDA_LEPAS)
						if ulang == null or ulang.titik_mendarat != l.titik_mendarat or ulang.titik_lepas != l.titik_lepas or ulang.lama_terbang != l.lama_terbang:
							semua_hitung = false
						if ZonaSasaran.klasifikasi(l.titik_mendarat, daftar) != ZonaSasaran.Hasil.KOTAK_SURAT or ZonaSasaran.klasifikasi_jalan_uji(l.titik_mendarat) != ZonaSasaran.Hasil.KOTAK_SURAT or not ZonaSasaran.memuat(p.zona, l.titik_mendarat):
							semua_kena = false
						if p.kekuatan < 0.0 or p.kekuatan > 1.0 or l.kekuatan < 0.0 or l.kekuatan > 1.0:
							u_sah = false
						if not p.zona.pelanggan or p.zona.sisi != sisi or p.zona.jenis != ZonaSasaran.Jenis.KOTAK_SURAT or p.zona.persegi.get_center().y < maju:
							syarat_kandidat = false
	print("[bantu] sasaran ditemukan %d dari %d keadaan, %d dibandingkan dengan oracle" % [dipilih, total, dibandingkan])
	check(float(dipilih) >= float(total) * 0.6 and dipilih < total, "kontrol: sasaran ditemukan di %d dari %d keadaan (5 kecepatan x 3 lateral x 3 kecepatan lateral x 2 sisi x 32 fase dua kavling, termasuk rumah 2 bukan pelanggan, jadi ada juga yang null)" % [dipilih, total])
	check(semua_hitung, "tiap lintasan terpilih = keluaran ThrowSolver.hitung (dihitung ulang dari u, arah, dan keadaan sepeda: titik lepas, mendarat, lama terbang sama)")
	check(semua_kena, "tiap lintasan terpilih mendarat di zona kotak surat itu dan dinilai KOTAK_SURAT (daftar zona dan klasifikasi jalan uji)")
	check(u_sah, "u selalu di [0, 1]")
	check(syarat_kandidat, "tiap sasaran: kotak surat pelanggan di sisi tap, pusat di depan sepeda")
	check(terdekat_cocok and float(dibandingkan) > float(total) * 0.75, "sasaran = kotak surat terjangkau terdekat menurut oracle literal (%d keadaan dibandingkan) %s" % [dibandingkan, gagal_contoh])


# --- D-6 waktu tanda ---

func _test_tanda() -> void:
	_judul.call("Tanda tidak ada sasaran: waktu (D-6)")
	check(is_equal_approx(Config.BANTU_TANDA_LAMA_DETIK, 0.6), "lama tanda 0,6 detik (config)")
	check(is_equal_approx(BantuLempar.sisa_tanda(0.6, 0.25), 0.35) and BantuLempar.sisa_tanda(0.1, 0.25) == 0.0, "sisa tanda berkurang dt, tidak di bawah 0")
	check(BantuLempar.sisa_tanda(0.6, 0.0) == 0.6 and BantuLempar.sisa_tanda(0.6, NAN) == 0.6 and BantuLempar.sisa_tanda(0.6, -1.0) == 0.6, "dt 0, NaN, negatif = membeku (jeda game)")
	check(BantuLempar.tanda_tampil(0.01) and not BantuLempar.tanda_tampil(0.0) and not BantuLempar.tanda_tampil(NAN), "tanda tampil selama sisa > 0")
	check(PolaPiksel.ukuran(PolaPiksel.TANDA_TANPA_SASARAN) == Vector2i(9, 9) and PolaPiksel.TANDA_TANPA_SASARAN != PolaPiksel.PENANDA_SILANG, "pola tanda 9x9, bentuk berbeda dari silang meleset")
