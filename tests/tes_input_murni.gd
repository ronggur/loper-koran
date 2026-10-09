class_name TesInputMurni
extends RefCounted
## Tes logika murni run 0B (AC-5 sampai AC-10, AC-13 fungsi tombol): zona sentuh, stick, pelacak jari, gerak
## sepeda, proyeksi isometrik, stick ke animasi, jalan tanpa ujung, dan cakram piksel stick.
##
## Dipanggil dari `tests/run_tests.gd` (`TesInputMurni.new(check, judul).jalankan()`), memakai `check` milik runner supaya
## hitungan lolos/gagal dan ringkasan tetap satu. Semua tes tanpa node: waktu dan RNG adalah parameter (rule `testing`).

const LEBAR_UJI: Array[int] = [640, 780, 800]
const TINGGI: int = 360
## Titik contoh di dalam zona stick (bawaan, tangan kanan) dan zona swipe, lebar viewport 780.
const TITIK_STICK: Vector2 = Vector2(100, 260)
const TITIK_SWIPE: Vector2 = Vector2(450, 200)

var _cek: Callable
var _judul: Callable


func _init(cek: Callable, judul: Callable) -> void:
	_cek = cek
	_judul = judul


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_test_touch_zones()
	_test_stick_map()
	_test_tombol_keyboard()
	_test_touch_router()
	_test_bike_drive()
	_test_iso()
	_test_stick_ke_animasi()
	_test_jalan_daur()
	_test_piksel_lingkaran()


# --- AC-5: TouchZones (DESIGN_SPEC 3.7) ---

func _test_touch_zones() -> void:
	_judul.call("TouchZones")
	check(Config.ZONA_STICK_X_MIN_PX == 8 and Config.ZONA_STICK_X_MAKS_PX == 192, "Config: zona stick x 8-192 dari tepi sisi stick (DESIGN_SPEC 3.7)")
	check(Config.ZONA_STICK_Y_MIN_PX == 186 and Config.ZONA_STICK_Y_MAKS_PX == 352, "Config: zona stick y 186-352 (DESIGN_SPEC 3.7)")
	check(Config.ZONA_SWIPE_X_MIN_PX == 210 and Config.ZONA_SWIPE_TEPI_PX == 20, "Config: zona swipe mulai x 210, berakhir 20 dari tepi layar (DESIGN_SPEC 3.7)")
	check(Config.ZONA_SWIPE_Y_MIN_PX == 48 and Config.ZONA_SWIPE_Y_MAKS_PX == 352, "Config: zona swipe y 48-352 (DESIGN_SPEC 3.7)")
	for lebar: int in LEBAR_UJI:
		var tag: String = "lebar %d" % lebar
		var w: float = float(lebar)
		# Tangan kanan (bawaan): stick di sisi kiri layar, swipe di sisi kanan.
		var stick: Rect2 = TouchZones.rect_stick(lebar, false)
		var swipe: Rect2 = TouchZones.rect_swipe(lebar, false)
		check(stick.position == Vector2(8, 186) and stick.end == Vector2(192, 352), "%s: zona stick = x 8-192, y 186-352, dapat %s-%s" % [tag, stick.position, stick.end])
		check(swipe.position == Vector2(210, 48) and swipe.end == Vector2(w - 20, 352), "%s: zona swipe = x 210-(lebar-20), y 48-352, dapat %s-%s" % [tag, swipe.position, swipe.end])
		# Kidal: dicerminkan persis.
		var stick_kidal: Rect2 = TouchZones.rect_stick(lebar, true)
		var swipe_kidal: Rect2 = TouchZones.rect_swipe(lebar, true)
		check(stick_kidal.position == Vector2(w - 192, 186) and stick_kidal.end == Vector2(w - 8, 352), "%s kidal: zona stick = x (lebar-192)-(lebar-8), dapat %s-%s" % [tag, stick_kidal.position, stick_kidal.end])
		check(swipe_kidal.position == Vector2(20, 48) and swipe_kidal.end == Vector2(w - 210, 352), "%s kidal: zona swipe = x 20-(lebar-210), dapat %s-%s" % [tag, swipe_kidal.position, swipe_kidal.end])
		check(stick_kidal.position.x == w - stick.end.x and stick_kidal.end.x == w - stick.position.x, "%s: zona stick kidal adalah cermin tepat zona stick bawaan" % tag)
		check(swipe_kidal.position.x == w - swipe.end.x and swipe_kidal.end.x == w - swipe.position.x, "%s: zona swipe kidal adalah cermin tepat zona swipe bawaan" % tag)
		check(not stick.intersects(swipe, true) and not stick_kidal.intersects(swipe_kidal, true), "%s: zona stick dan swipe tidak bertumpuk (bawaan maupun kidal)" % tag)
		# Tepi tiap zona: di dalam dan di luar 1 px.
		for kidal: bool in [false, true]:
			var mode: String = "kidal" if kidal else "bawaan"
			var tengah_y: float = 250.0
			for ujung: Array in [[TouchZones.rect_stick(lebar, kidal), TouchZones.Zona.STICK, "stick"], [TouchZones.rect_swipe(lebar, kidal), TouchZones.Zona.SWIPE, "swipe"]]:
				var zona: Rect2 = ujung[0]
				var peran: int = ujung[1]
				var nama: String = ujung[2]
				var x_min: float = zona.position.x
				var x_maks: float = zona.end.x
				var y_min: float = zona.position.y
				var y_maks: float = zona.end.y
				var tengah_x: float = (x_min + x_maks) / 2
				check(TouchZones.zona_di(Vector2(x_min, tengah_y), lebar, kidal) == peran, "%s %s: tepi %s sebelah dalam (x = %s) masuk zona" % [tag, mode, nama, x_min])
				check(TouchZones.zona_di(Vector2(x_min - 1, tengah_y), lebar, kidal) != peran, "%s %s: 1 px di luar tepi %s (x = %s) bukan zona %s" % [tag, mode, nama, x_min - 1, nama])
				check(TouchZones.zona_di(Vector2(x_maks, tengah_y), lebar, kidal) == peran, "%s %s: tepi %s sebelah luar (x = %s) masuk zona" % [tag, mode, nama, x_maks])
				check(TouchZones.zona_di(Vector2(x_maks + 1, tengah_y), lebar, kidal) != peran, "%s %s: 1 px di luar tepi %s (x = %s) bukan zona %s" % [tag, mode, nama, x_maks + 1, nama])
				check(TouchZones.zona_di(Vector2(tengah_x, y_min), lebar, kidal) == peran, "%s %s: tepi atas %s (y = %s) masuk zona" % [tag, mode, nama, y_min])
				check(TouchZones.zona_di(Vector2(tengah_x, y_min - 1), lebar, kidal) != peran, "%s %s: 1 px di atas zona %s (y = %s) bukan zona %s" % [tag, mode, nama, y_min - 1, nama])
				check(TouchZones.zona_di(Vector2(tengah_x, y_maks), lebar, kidal) == peran, "%s %s: tepi bawah %s (y = %s) masuk zona" % [tag, mode, nama, y_maks])
				check(TouchZones.zona_di(Vector2(tengah_x, y_maks + 1), lebar, kidal) != peran, "%s %s: 1 px di bawah zona %s (y = %s) bukan zona %s" % [tag, mode, nama, y_maks + 1, nama])
				check(TouchZones.zona_di(Vector2(x_min, y_min), lebar, kidal) == peran and TouchZones.zona_di(Vector2(x_maks, y_maks), lebar, kidal) == peran, "%s %s: pojok zona %s inklusif" % [tag, mode, nama])
			# Titik di luar kedua zona.
			var di_luar: Array[Vector2] = [Vector2(400, 10), Vector2(400, 47), Vector2(0, 0), Vector2(w - 1, 0), Vector2(w - 1, TINGGI - 1), Vector2(0, TINGGI - 1), Vector2(5, 300), Vector2(w - 5, 300)]
			for titik: Vector2 in di_luar:
				check(TouchZones.zona_di(titik, lebar, kidal) == TouchZones.Zona.TIDAK_ADA, "%s %s: titik %s di luar kedua zona" % [tag, mode, titik])
		# Celah di antara stick dan swipe tidak masuk zona mana pun.
		check(TouchZones.zona_di(Vector2(200, 300), lebar, false) == TouchZones.Zona.TIDAK_ADA, "%s: celah stick-swipe (x 200) bukan zona mana pun" % tag)
		check(TouchZones.zona_di(Vector2(w - 200, 300), lebar, true) == TouchZones.Zona.TIDAK_ADA, "%s kidal: celah stick-swipe bukan zona mana pun" % tag)
	# Strip atas HUD (y < 48) bebas dari kedua zona di semua lebar dan kedua mode.
	var bebas: bool = true
	for lebar: int in LEBAR_UJI:
		for kidal: bool in [false, true]:
			for x: int in range(0, lebar, 4):
				for y: int in range(0, Config.HUD_STRIP_ATAS_TINGGI_PX, 4):
					if TouchZones.zona_di(Vector2(x, y), lebar, kidal) != TouchZones.Zona.TIDAK_ADA:
						bebas = false
	check(bebas, "strip atas (y < 48) tidak masuk zona stick maupun swipe di semua lebar dan kedua mode (DESIGN_SPEC 3.7, rule ui-scenes)")


# --- AC-6: StickMap (BALANCING 2, DESIGN_SPEC 3.7) ---

func _test_stick_map() -> void:
	_judul.call("StickMap")
	var radius: float = Config.STICK_RADIUS_PX
	check(radius == 35.0, "radius penuh stick 35 px (DESIGN_SPEC 3.7, usulan)")
	# Zona mati radial 15%: 14,9 dan 15,0 persen nol, 15,1 persen kecil tapi positif.
	for arah: Vector2 in [Vector2(1, 0), Vector2(0, -1), Vector2(-1, 0), Vector2(0, 1), Vector2(1, 1).normalized(), Vector2(-3, 4).normalized()]:
		var tag: String = "arah %s" % arah
		check(StickMap.petakan(arah * radius * 0.149) == Vector2.ZERO, "%s: 14,9%% radius = vektor nol (zona mati 15%%)" % tag)
		check(StickMap.petakan(arah * radius * 0.150) == Vector2.ZERO, "%s: 15,0%% radius = vektor nol (batas zona mati inklusif)" % tag)
		var kecil: float = StickMap.petakan(arah * radius * 0.151).length()
		check(kecil > 0.0 and kecil < 0.01, "%s: 15,1%% radius = kekuatan kecil di atas nol, dapat %s" % [tag, kecil])
		check(is_equal_approx(StickMap.petakan(arah * radius).length(), 1.0), "%s: 100%% radius = kekuatan 1,0" % tag)
		var lewat: Vector2 = StickMap.petakan(arah * radius * 1.5)
		check(is_equal_approx(lewat.length(), 1.0), "%s: 150%% radius dijepit ke kekuatan 1,0" % tag)
		var diharapkan: Vector2 = Vector2(arah.x, -arah.y)
		check(lewat.is_equal_approx(diharapkan), "%s: arah dipertahankan saat dijepit (sumbu Y dibalik): %s, dapat %s" % [tag, diharapkan, lewat])
		var penuh: Vector2 = StickMap.petakan(arah * radius)
		check(penuh.is_equal_approx(diharapkan), "%s: arah dipertahankan di 100%%: %s, dapat %s" % [tag, diharapkan, penuh])
	# Pemetaan ulang linear tanpa lompatan.
	check(is_equal_approx(StickMap.petakan(Vector2(radius * 0.575, 0)).length(), 0.5), "57,5%% radius (tengah antara 15%% dan 100%%) = kekuatan 0,5 (linear)")
	var terakhir: float = 0.0
	var maks_lompat: float = 0.0
	var monoton: bool = true
	for langkah: int in range(1, 1501):
		var rasio: float = float(langkah) / 1000.0
		var sekarang: float = StickMap.petakan(Vector2(radius * rasio, 0)).length()
		maks_lompat = maxf(maks_lompat, absf(sekarang - terakhir))
		if sekarang < terakhir - 0.0000001:
			monoton = false
		terakhir = sekarang
	check(monoton, "kekuatan stick monoton naik terhadap jarak jari 0..150%")
	check(maks_lompat < 0.0013, "kekuatan stick tanpa lompatan di batas zona mati dan jangkauan penuh (lompat terbesar per 0,1%% = %s)" % maks_lompat)
	# Sumbu Y layar dibalik di satu fungsi: jari ke atas layar = maju positif.
	check(StickMap.petakan(Vector2(0, -radius)).is_equal_approx(Vector2(0, 1)), "jari ke atas layar (y negatif) = stick maju positif (0, 1)")
	check(StickMap.petakan(Vector2(0, radius)).is_equal_approx(Vector2(0, -1)), "jari ke bawah layar = stick melambat negatif (0, -1)")
	check(StickMap.petakan(Vector2(radius, 0)).is_equal_approx(Vector2(1, 0)), "jari ke kanan layar = lateral positif (sisi dekat, D-3)")
	check(StickMap.petakan(Vector2(-radius, 0)).is_equal_approx(Vector2(-1, 0)), "jari ke kiri layar = lateral negatif (sisi seberang, D-3)")
	# Masukan aneh.
	check(StickMap.petakan(Vector2.ZERO) == Vector2.ZERO, "geseran nol = vektor nol")
	check(StickMap.petakan(Vector2(NAN, 0)) == Vector2.ZERO and StickMap.petakan(Vector2(0, INF)) == Vector2.ZERO, "geseran NaN atau tak hingga = vektor nol (tidak merusak gerak)")
	check(StickMap.jepit_geser(Vector2(100, 0)).length() <= radius + 0.0001 and StickMap.jepit_geser(Vector2(10, 0)) == Vector2(10, 0), "geseran untuk knob dijepit ke radius dan tidak diubah di dalamnya")


# --- AC-13: fungsi tombol keyboard (hanya editor) ---

func _test_tombol_keyboard() -> void:
	_judul.call("Tombol keyboard ke vektor stick")
	check(StickMap.dari_tombol(false, false, false, false) == Vector2.ZERO, "tanpa tombol = vektor nol")
	check(StickMap.dari_tombol(false, false, true, false) == Vector2(0, 1), "tombol atas = (0, 1) maju")
	check(StickMap.dari_tombol(false, false, false, true) == Vector2(0, -1), "tombol bawah = (0, -1) melambat")
	check(StickMap.dari_tombol(false, true, false, false) == Vector2(1, 0), "tombol sisi dekat = (1, 0)")
	check(StickMap.dari_tombol(true, false, false, false) == Vector2(-1, 0), "tombol sisi seberang = (-1, 0)")
	check(StickMap.dari_tombol(true, true, false, false) == Vector2.ZERO and StickMap.dari_tombol(false, false, true, true) == Vector2.ZERO, "tombol berlawanan saling membatalkan")
	check(StickMap.dari_tombol(true, true, true, true) == Vector2.ZERO, "keempat tombol sekaligus = nol")
	var panjang_maks: float = 0.0
	for bit: int in range(16):
		var v: Vector2 = StickMap.dari_tombol(bit & 1 != 0, bit & 2 != 0, bit & 4 != 0, bit & 8 != 0)
		panjang_maks = maxf(panjang_maks, v.length())
	check(panjang_maks <= 1.0 + 0.000001, "semua 16 kombinasi tombol menghasilkan panjang paling banyak 1 (diagonal tidak lebih cepat), terbesar %s" % panjang_maks)
	var diagonal: Vector2 = StickMap.dari_tombol(true, false, true, false)
	check(is_equal_approx(diagonal.length(), 1.0) and diagonal.x < 0.0 and diagonal.y > 0.0, "atas + sisi seberang = diagonal panjang 1 ke seberang-maju, dapat %s" % diagonal)


# --- AC-7: TouchRouter ---

func _router(lebar: int = 780) -> TouchRouter:
	var router: TouchRouter = TouchRouter.new()
	router.lebar_viewport = lebar
	return router


func _test_touch_router() -> void:
	_judul.call("TouchRouter")
	_router_a_stick_melayang()
	_router_b_dua_jari()
	_router_c_jari_kedua_di_zona_stick()
	_router_d_jari_diangkat()
	_router_e_index_tak_dikenal_dan_ganda()
	_router_e2_index_negatif()
	_router_f_mulai_di_luar_zona()
	_router_g_zona_hanya_saat_turun()
	_router_h_kidal()
	_router_i_batal_semua()
	_router_lain()


func _router_a_stick_melayang() -> void:
	var r: TouchRouter = _router()
	r.tekan(0, TITIK_STICK, 0.0)
	check(r.stick_aktif() and not r.swipe_aktif() and r.jumlah_jari_aktif() == 1, "7a: satu jari turun di zona stick -> stick aktif saja")
	check(r.asal_stick() == TITIK_STICK, "7a: stick melayang, titik asal = titik sentuh %s, dapat %s" % [TITIK_STICK, r.asal_stick()])
	check(r.vektor_stick() == Vector2.ZERO, "7a: tepat di titik asal vektor nol")
	r.geser(0, TITIK_STICK + Vector2(0, -35))
	check(r.vektor_stick().is_equal_approx(Vector2(0, 1)), "7a: geser ke atas sejauh radius = (0, 1), dapat %s" % r.vektor_stick())
	r.geser(0, TITIK_STICK + Vector2(0, -90))
	check(r.vektor_stick().is_equal_approx(Vector2(0, 1)) and r.geser_stick_terjepit().length() <= Config.STICK_RADIUS_PX + 0.0001, "7a: geser jauh melewati radius dijepit ke (0, 1) dan knob dijepit ke radius")
	r.geser(0, TITIK_STICK + Vector2(35, 0))
	check(r.vektor_stick().is_equal_approx(Vector2(1, 0)), "7a: geser ke kanan layar sejauh radius = (1, 0), dapat %s" % r.vektor_stick())
	r.geser(0, TITIK_STICK + Vector2(-17.5, 17.5))
	var v: Vector2 = r.vektor_stick()
	check(v.x < 0.0 and v.y < 0.0, "7a: geser ke kiri-bawah layar = lateral negatif dan melambat negatif, dapat %s" % v)
	# Titik asal mengikuti titik sentuh, bukan titik tetap, walau di tepi zona.
	var r2: TouchRouter = _router()
	r2.tekan(5, Vector2(8, 186), 0.0)
	check(r2.stick_aktif() and r2.asal_stick() == Vector2(8, 186), "7a: sentuhan tepat di pojok zona tetap diklaim dan menjadi titik asal")


func _router_b_dua_jari() -> void:
	for stick_dulu: bool in [true, false]:
		var urutan: String = "stick lebih dulu" if stick_dulu else "swipe lebih dulu"
		var r: TouchRouter = _router()
		if stick_dulu:
			r.tekan(0, TITIK_STICK, 1.0)
			r.tekan(1, TITIK_SWIPE, 1.0)
		else:
			r.tekan(1, TITIK_SWIPE, 1.0)
			r.tekan(0, TITIK_STICK, 1.0)
		check(r.stick_aktif() and r.swipe_aktif() and r.jumlah_jari_aktif() == 2, "7b (%s): dua jari bersamaan, masing-masing punya slot" % urutan)
		check(r.asal_stick() == TITIK_STICK and r.awal_swipe() == TITIK_SWIPE, "7b (%s): titik awal stick dan swipe sesuai jarinya masing-masing" % urutan)
		r.geser(1, TITIK_SWIPE + Vector2(60, -40))
		check(r.vektor_stick() == Vector2.ZERO and r.posisi_swipe() == TITIK_SWIPE + Vector2(60, -40), "7b (%s): menggeser swipe tidak mengubah stick" % urutan)
		r.geser(0, TITIK_STICK + Vector2(0, -35))
		check(r.vektor_stick().is_equal_approx(Vector2(0, 1)) and r.posisi_swipe() == TITIK_SWIPE + Vector2(60, -40), "7b (%s): menggeser stick tidak mengubah swipe" % urutan)
		r.lepas(1, TITIK_SWIPE + Vector2(60, -40), 1.5)
		check(r.stick_aktif() and r.vektor_stick().is_equal_approx(Vector2(0, 1)) and not r.swipe_aktif(), "7b (%s): mengangkat jari swipe tidak mematikan stick" % urutan)
		r.tekan(1, TITIK_SWIPE, 2.0)
		r.lepas(0, TITIK_STICK, 2.5)
		check(not r.stick_aktif() and r.swipe_aktif() and r.vektor_stick() == Vector2.ZERO, "7b (%s): mengangkat jari stick tidak mematikan swipe" % urutan)


func _router_c_jari_kedua_di_zona_stick() -> void:
	var r: TouchRouter = _router()
	r.tekan(0, TITIK_STICK, 0.0)
	r.geser(0, TITIK_STICK + Vector2(0, -35))
	r.tekan(1, Vector2(60, 300), 0.1)
	check(r.jumlah_jari_aktif() == 1 and r.asal_stick() == TITIK_STICK, "7c: jari kedua di zona stick saat stick aktif diabaikan, stick pertama utuh")
	r.geser(1, Vector2(60, 200))
	check(r.vektor_stick().is_equal_approx(Vector2(0, 1)), "7c: menggeser jari kedua yang diabaikan tidak mengubah stick")
	r.lepas(1, Vector2(60, 200), 0.3)
	check(r.stick_aktif() and r.vektor_stick().is_equal_approx(Vector2(0, 1)), "7c: mengangkat jari kedua yang diabaikan tidak melepas stick pertama")
	r.lepas(0, TITIK_STICK, 0.5)
	r.tekan(1, Vector2(60, 300), 0.6)
	check(r.stick_aktif() and r.asal_stick() == Vector2(60, 300), "7c: setelah stick pertama lepas, jari baru bisa mengambil slot")
	# Jari kedua di zona swipe saat swipe sudah aktif diabaikan juga.
	var s: TouchRouter = _router()
	s.tekan(0, TITIK_SWIPE, 0.0)
	s.tekan(1, Vector2(300, 100), 0.1)
	check(s.jumlah_jari_aktif() == 1 and s.awal_swipe() == TITIK_SWIPE, "7c: jari kedua di zona swipe saat swipe aktif diabaikan")


func _router_d_jari_diangkat() -> void:
	var r: TouchRouter = _router()
	var hasil: Array = []
	r.swipe_selesai.connect(func(awal: Vector2, akhir: Vector2, durasi: float) -> void: hasil.append([awal, akhir, durasi]))
	r.tekan(0, TITIK_STICK, 0.0)
	r.geser(0, TITIK_STICK + Vector2(0, -35))
	r.lepas(0, TITIK_STICK + Vector2(0, -35), 0.5)
	check(not r.stick_aktif() and r.vektor_stick() == Vector2.ZERO and r.jumlah_jari_aktif() == 0, "7d: jari stick diangkat -> vektor nol dan slot bebas")
	check(hasil.is_empty() and r.jumlah_swipe_selesai == 0, "7d: mengangkat jari stick tidak mencatat swipe")
	r.tekan(7, Vector2(50, 250), 1.0)
	check(r.stick_aktif() and r.asal_stick() == Vector2(50, 250), "7d: sesudah stick lepas, jari baru bisa mengklaim stick")
	# Swipe: titik awal, akhir, durasi dari parameter waktu, dicatat sekali.
	r.tekan(1, TITIK_SWIPE, 10.0)
	r.geser(1, TITIK_SWIPE + Vector2(30, -20))
	r.lepas(1, TITIK_SWIPE + Vector2(80, -50), 10.75)
	check(hasil.size() == 1 and r.jumlah_swipe_selesai == 1, "7d: swipe selesai tercatat tepat sekali, dapat %d" % hasil.size())
	if hasil.size() == 1:
		check(hasil[0][0] == TITIK_SWIPE and hasil[0][1] == TITIK_SWIPE + Vector2(80, -50), "7d: titik awal dan titik akhir swipe sesuai")
		check(is_equal_approx(hasil[0][2], 0.75), "7d: durasi swipe dari parameter waktu = 0,75 detik, dapat %s" % hasil[0][2])
	check(not r.swipe_aktif() and r.stick_aktif(), "7d: swipe selesai membebaskan slot swipe dan stick tidak terganggu")
	r.lepas(1, TITIK_SWIPE, 11.0)
	check(hasil.size() == 1 and r.jumlah_swipe_selesai == 1, "7d: lepas kedua dengan index yang sama tidak mencatat swipe lagi")
	r.tekan(1, Vector2(300, 100), 12.0)
	r.lepas(1, Vector2(300, 100), 11.0)
	check(hasil.size() == 2 and is_equal_approx(hasil[1][2], 0.0), "7d: durasi tidak pernah negatif walau parameter waktu mundur")


func _router_e_index_tak_dikenal_dan_ganda() -> void:
	var r: TouchRouter = _router()
	r.geser(9, Vector2(100, 100))
	r.lepas(9, Vector2(100, 100), 1.0)
	r.batal(9)
	check(r.jumlah_jari_aktif() == 0 and r.jumlah_swipe_selesai == 0, "7e: drag, lepas, dan batal dengan index yang tidak pernah turun diabaikan tanpa efek")
	r.tekan(0, TITIK_STICK, 0.0)
	r.tekan(0, Vector2(60, 300), 0.1)
	check(r.jumlah_jari_aktif() == 1 and r.asal_stick() == TITIK_STICK, "7e: turun dobel dengan index sama tidak membuat slot ganda dan tidak memindahkan titik asal")
	r.tekan(0, TITIK_SWIPE, 0.2)
	check(not r.swipe_aktif(), "7e: index yang sedang stick tidak bisa sekaligus mengklaim swipe")
	r.geser(8, TITIK_STICK + Vector2(0, -35))
	check(r.vektor_stick() == Vector2.ZERO, "7e: drag dengan index lain tidak menggerakkan stick")
	r.tekan(-1, TITIK_SWIPE, 0.3)
	r.tekan(3, Vector2(NAN, 5), 0.3)
	check(not r.swipe_aktif() and r.jumlah_jari_aktif() == 1, "7e: index negatif dan posisi NaN diabaikan")


## QB-001: `index` negatif sama dengan sentinel slot kosong (-1) dan tidak boleh terbaca "cocok".
func _router_e2_index_negatif() -> void:
	# Stick aktif, slot swipe kosong: lepas(-1) dulu mencatat swipe palsu (awal nol, akhir sembarang).
	var r: TouchRouter = _router()
	var hasil: Array = []
	r.swipe_selesai.connect(func(awal: Vector2, akhir: Vector2, durasi: float) -> void: hasil.append([awal, akhir, durasi]))
	r.tekan(0, TITIK_STICK, 1.0)
	r.lepas(-1, Vector2(500, 200), 2.0)
	check(r.jumlah_swipe_selesai == 0 and hasil.is_empty(), "QB-001: lepas(-1) saat stick aktif tidak mencatat swipe palsu dan tidak memancarkan sinyal")
	check(r.stick_aktif() and r.asal_stick() == TITIK_STICK and not r.swipe_aktif(), "QB-001: lepas(-1) tidak melepas stick dan tidak membuat swipe aktif")
	r.geser(-1, Vector2(500, 200))
	check(r.posisi_swipe() == Vector2.ZERO and r.awal_swipe() == Vector2.ZERO and not r.swipe_aktif(), "QB-001: geser(-1) tidak menulis posisi swipe walau swipe tidak aktif")
	r.batal(-1)
	check(r.stick_aktif() and r.jumlah_jari_aktif() == 1, "QB-001: batal(-1) tidak melepas jari yang aktif")
	r.geser(0, TITIK_STICK + Vector2(0, -35))
	check(r.vektor_stick().is_equal_approx(Vector2(0, 1)), "QB-001: stick tetap bekerja normal sesudah masukan index -1")
	# Sebaliknya: swipe aktif, slot stick kosong: geser(-1) tidak boleh menulis posisi stick.
	var s: TouchRouter = _router()
	s.tekan(1, TITIK_SWIPE, 1.0)
	s.geser(-1, Vector2(300, 100))
	s.lepas(-1, Vector2(300, 100), 2.0)
	s.batal(-1)
	check(s.swipe_aktif() and s.posisi_swipe() == TITIK_SWIPE and s.jumlah_swipe_selesai == 0, "QB-001: swipe aktif tidak terganggu geser(-1), lepas(-1), dan batal(-1)")
	check(s.get("_posisi_stick") == Vector2.ZERO and not s.stick_aktif(), "QB-001: geser(-1) tidak menulis posisi stick saat stick tidak aktif")
	s.tekan(2, TITIK_STICK, 2.0)
	check(s.stick_aktif() and s.asal_stick() == TITIK_STICK and s.vektor_stick() == Vector2.ZERO, "QB-001: stick yang diklaim sesudahnya mulai bersih (titik asal = titik sentuh, vektor nol)")
	# Dua slot kosong: tidak ada efek samping apa pun.
	var k: TouchRouter = _router()
	k.lepas(-1, Vector2(100, 100), 1.0)
	k.geser(-1, Vector2(100, 100))
	k.batal(-1)
	k.tekan(-1, TITIK_STICK, 1.0)
	check(k.jumlah_jari_aktif() == 0 and k.jumlah_swipe_selesai == 0, "QB-001: index -1 pada router kosong tidak berefek (tekan, geser, lepas, batal)")


func _router_f_mulai_di_luar_zona() -> void:
	var r: TouchRouter = _router()
	for awal: Vector2 in [Vector2(400, 10), Vector2(200, 300), Vector2(3, 3)]:
		r.tekan(2, awal, 0.0)
		check(r.jumlah_jari_aktif() == 0, "7f: sentuhan mulai di luar kedua zona %s tidak diklaim" % awal)
		r.geser(2, TITIK_STICK)
		r.geser(2, TITIK_SWIPE)
		check(r.jumlah_jari_aktif() == 0 and r.vektor_stick() == Vector2.ZERO, "7f: digeser masuk zona tetap tidak diklaim (mulai di %s)" % awal)
		r.lepas(2, TITIK_SWIPE, 1.0)
		check(r.jumlah_swipe_selesai == 0, "7f: lepas di dalam zona swipe tidak mencatat swipe (mulai di %s)" % awal)


func _router_g_zona_hanya_saat_turun() -> void:
	var r: TouchRouter = _router()
	r.tekan(0, TITIK_STICK, 0.0)
	r.tekan(1, TITIK_SWIPE, 0.0)
	r.geser(0, Vector2(450, 250))
	check(r.stick_aktif() and r.swipe_aktif(), "7g: jari stick digeser ke zona swipe tetap stick, swipe lama tetap swipe")
	check(r.asal_stick() == TITIK_STICK and r.vektor_stick().x > 0.99, "7g: jari stick di zona swipe tetap menggerakkan stick (geseran jauh ke kanan = lateral penuh), dapat %s" % r.vektor_stick())
	r.geser(1, Vector2(100, 260))
	check(r.posisi_swipe() == Vector2(100, 260) and r.asal_stick() == TITIK_STICK, "7g: jari swipe digeser ke zona stick tetap swipe dan tidak menjadi stick kedua")
	check(r.jumlah_jari_aktif() == 2, "7g: tetap dua jari aktif")


func _router_h_kidal() -> void:
	var r: TouchRouter = _router()
	check(not r.kidal(), "7h: bawaan tangan kanan")
	r.atur_kidal(true)
	check(r.kidal(), "7h: opsi kidal menyala")
	# Zona lama stick bawaan sekarang bagian zona swipe, bukan stick.
	r.tekan(0, Vector2(100, 260), 0.0)
	check(not r.stick_aktif() and r.swipe_aktif(), "7h: sentuhan di zona stick lama tidak diklaim sebagai stick (kini zona swipe)")
	r.batal_semua()
	r.tekan(0, Vector2(680, 260), 0.0)
	check(r.stick_aktif() and r.asal_stick() == Vector2(680, 260), "7h: zona stick kini di sisi kanan layar (680, 260)")
	r.batal_semua()
	r.tekan(0, Vector2(330, 200), 0.0)
	check(r.swipe_aktif() and not r.stick_aktif(), "7h: zona swipe kini di sisi kiri layar (330, 200)")
	r.batal_semua()
	r.tekan(0, Vector2(600, 20), 0.0)
	check(r.jumlah_jari_aktif() == 0, "7h: strip atas tetap bebas dari kedua zona saat kidal")
	# Mengganti kidal membatalkan semua jari aktif.
	var hasil: Array = []
	r.swipe_selesai.connect(func(awal: Vector2, akhir: Vector2, durasi: float) -> void: hasil.append([awal, akhir, durasi]))
	r.tekan(1, Vector2(680, 260), 1.0)
	r.tekan(2, Vector2(330, 200), 1.0)
	r.geser(1, Vector2(680, 225))
	check(r.jumlah_jari_aktif() == 2 and r.vektor_stick().is_equal_approx(Vector2(0, 1)), "7h: dua jari aktif di mode kidal")
	r.atur_kidal(false)
	check(r.jumlah_jari_aktif() == 0 and r.vektor_stick() == Vector2.ZERO and hasil.is_empty(), "7h: mengganti kidal membatalkan semua jari aktif tanpa mencatat swipe")
	r.tekan(1, TITIK_STICK, 2.0)
	r.atur_kidal(false)
	check(r.stick_aktif(), "7h: menyetel kidal ke nilai yang sama tidak membatalkan jari")
	# Zona mengikuti lebar viewport.
	var sempit: TouchRouter = _router(640)
	sempit.tekan(0, Vector2(630, 200), 0.0)
	check(not sempit.swipe_aktif(), "7h: lebar 640: x 630 di luar zona swipe (berakhir di 620)")
	var lebar: TouchRouter = _router(800)
	lebar.tekan(0, Vector2(630, 200), 0.0)
	check(lebar.swipe_aktif(), "7h: lebar 800: x 630 di dalam zona swipe (berakhir di 780)")


func _router_i_batal_semua() -> void:
	var r: TouchRouter = _router()
	var hasil: Array = []
	r.swipe_selesai.connect(func(awal: Vector2, akhir: Vector2, durasi: float) -> void: hasil.append([awal, akhir, durasi]))
	r.tekan(0, TITIK_STICK, 0.0)
	r.tekan(1, TITIK_SWIPE, 0.0)
	r.geser(0, TITIK_STICK + Vector2(0, -35))
	check(r.vektor_stick().is_equal_approx(Vector2(0, 1)), "7i: stick aktif sebelum dibatalkan")
	r.batal_semua()
	check(r.jumlah_jari_aktif() == 0 and r.vektor_stick() == Vector2.ZERO and r.geser_stick_terjepit() == Vector2.ZERO, "7i: batal_semua() melepas semua jari dan menolkan vektor")
	check(hasil.is_empty() and r.jumlah_swipe_selesai == 0, "7i: batal_semua() tidak mencatat swipe")
	r.lepas(0, TITIK_STICK, 1.0)
	r.lepas(1, TITIK_SWIPE, 1.0)
	check(hasil.is_empty(), "7i: lepas susulan dari jari yang sudah dibatalkan diabaikan")
	r.tekan(0, TITIK_STICK, 2.0)
	r.tekan(1, TITIK_SWIPE, 2.0)
	check(r.jumlah_jari_aktif() == 2, "7i: sesudah batal_semua() jari baru bisa mengambil kedua slot")
	r.tekan(2, Vector2(60, 300), 3.0)
	r.batal(0)
	check(not r.stick_aktif() and r.swipe_aktif() and hasil.is_empty(), "7i: batal(index) melepas satu jari tanpa mencatat swipe")


func _router_lain() -> void:
	var r: TouchRouter = _router()
	r.tekan(0, TITIK_SWIPE, 0.0)
	r.batal(0)
	check(not r.swipe_aktif() and r.jumlah_swipe_selesai == 0, "batal(index) pada jari swipe tidak mencatat swipe")
	check(r.vektor_stick() == Vector2.ZERO and r.geser_stick_terjepit() == Vector2.ZERO, "tanpa stick aktif, vektor dan geseran knob nol")


# --- AC-8: BikeDrive (BALANCING 2) ---

func _test_bike_drive() -> void:
	_judul.call("BikeDrive")
	check(Config.JALAN_LEBAR_UBIN == 2.0, "lebar jalan placeholder 2 ubin (BALANCING 2, usulan)")
	check(BikeDrive.batas_lateral_ubin() == 1.0, "batas geser lateral = setengah lebar jalan = 1 ubin ke tiap sisi")
	# Kecepatan target.
	check(BikeDrive.kecepatan_target_ud(0.0) == 3.0, "stick netral -> target 3,0 u/d (santai)")
	check(is_equal_approx(BikeDrive.kecepatan_target_ud(0.5), 4.5), "stick atas 0,5 -> target 4,5 u/d (linear santai ke ngebut)")
	check(BikeDrive.kecepatan_target_ud(1.0) == 6.0, "stick atas penuh -> target 6,0 u/d (ngebut)")
	check(BikeDrive.kecepatan_target_ud(-1.0) == 1.5, "stick bawah penuh -> target 1,5 u/d (melambat)")
	check(is_equal_approx(BikeDrive.kecepatan_target_ud(-0.5), 2.25), "stick bawah 0,5 -> target 2,25 u/d (linear santai ke melambat)")
	check(BikeDrive.kecepatan_target_ud(7.0) == 6.0 and BikeDrive.kecepatan_target_ud(-7.0) == 1.5 and BikeDrive.kecepatan_target_ud(NAN) == 3.0, "target dijepit untuk stick di luar -1..1 dan NaN dianggap netral")
	# Akselerasi, perlambatan, dan batas.
	var h: BikeDrive.Hasil = BikeDrive.langkah(3.0, 0.0, Vector2(0, 1), 1.0 / 60.0)
	check(is_equal_approx(h.kecepatan_ud, 3.0 + 3.0 / 60.0), "akselerasi 3,0 u/d2: satu langkah 1/60 detik menambah 0,05 u/d, dapat %s" % h.kecepatan_ud)
	var v: float = 3.0
	for i: int in range(60):
		v = BikeDrive.langkah(v, 0.0, Vector2(0, 1), 1.0 / 60.0).kecepatan_ud
	check(is_equal_approx(v, 6.0), "dari 3,0 ke ngebut butuh 1 detik (3,0 u/d2), dapat %s" % v)
	for i: int in range(120):
		v = BikeDrive.langkah(v, 0.0, Vector2(0, 1), 1.0 / 60.0).kecepatan_ud
	check(v == 6.0, "kecepatan tidak melampaui ngebut walau stick tetap penuh, dapat %s" % v)
	h = BikeDrive.langkah(6.0, 0.0, Vector2.ZERO, 1.0)
	check(is_equal_approx(h.kecepatan_ud, 4.0), "perlambatan 2,0 u/d2: dari 6,0 netral 1 detik = 4,0, dapat %s" % h.kecepatan_ud)
	h = BikeDrive.langkah(6.0, 0.0, Vector2.ZERO, 100.0)
	check(h.kecepatan_ud == 3.0, "dt besar tidak melewati target (turun): 6,0 -> tepat 3,0, dapat %s" % h.kecepatan_ud)
	h = BikeDrive.langkah(3.0, 0.0, Vector2(0, 1), 100.0)
	check(h.kecepatan_ud == 6.0, "dt besar tidak melewati target (naik): 3,0 -> tepat 6,0, dapat %s" % h.kecepatan_ud)
	h = BikeDrive.langkah(3.0, 0.0, Vector2(0, -1), 100.0)
	check(h.kecepatan_ud == 1.5, "stick bawah penuh dengan dt besar berhenti di 1,5 (tidak di bawah KECEPATAN_MELAMBAT_UD), dapat %s" % h.kecepatan_ud)
	# QB-002: naik ke target MENENGAH tidak boleh melewati target. Batas atas clampf (6,0) hanya menutupi kasus target ngebut.
	h = BikeDrive.langkah(3.0, 0.0, Vector2(0, 0.5), 1.0)
	check(is_equal_approx(h.kecepatan_ud, 4.5), "target menengah, dt besar: dari 3,0 dengan stick atas 0,5 selama 1 detik = 4,5 u/d (bukan 6,0), dapat %s" % h.kecepatan_ud)
	h = BikeDrive.langkah(3.0, 0.0, Vector2(0, 0.5), 100.0)
	check(is_equal_approx(h.kecepatan_ud, 4.5), "target menengah, dt sangat besar = tepat 4,5 u/d, dapat %s" % h.kecepatan_ud)
	h = BikeDrive.langkah(4.4, 0.0, Vector2(0, 0.5), 0.1)
	check(is_equal_approx(h.kecepatan_ud, 4.5), "dt 0,1 dari 0,1 u/d di bawah target 4,5: berhenti di 4,5, tidak 4,7, dapat %s" % h.kecepatan_ud)
	h = BikeDrive.langkah(6.0, 0.0, Vector2(0, 0.5), 1.0)
	check(is_equal_approx(h.kecepatan_ud, 4.5), "turun ke target menengah: dari 6,0 dengan stick atas 0,5 selama 1 detik = 4,5 u/d (tidak di bawah target), dapat %s" % h.kecepatan_ud)
	var melewati: bool = false
	for atas: float in [0.1, 0.25, 0.5, 0.75, 0.9, -0.25, -0.5, -0.9]:
		var tujuan: float = BikeDrive.kecepatan_target_ud(atas)
		for selisih: float in [-1.0, -0.5, -0.1, -0.01, 0.0, 0.01, 0.1, 0.5, 1.0]:
			for dt_uji: float in [0.016, 0.1, 0.5, 1.0, 100.0]:
				var awal: float = clampf(tujuan + selisih, Config.KECEPATAN_MELAMBAT_UD, Config.KECEPATAN_NGEBUT_UD)
				var hasil_uji: BikeDrive.Hasil = BikeDrive.langkah(awal, 0.0, Vector2(0, atas), dt_uji)
				# Dari bawah target tidak boleh melewati; dari atas tidak boleh di bawah; selalu mendekat atau tetap.
				if awal <= tujuan and hasil_uji.kecepatan_ud > tujuan + 0.000001:
					melewati = true
				if awal >= tujuan and hasil_uji.kecepatan_ud < tujuan - 0.000001:
					melewati = true
	check(not melewati, "sapuan: stick atas -0,9..0,9 x selisih awal x dt 0,016..100 detik: kecepatan tidak pernah melewati target dari arah mana pun")
	h = BikeDrive.langkah(4.2, 0.4, Vector2(1, 1), 0.0)
	check(h.kecepatan_ud == 4.2 and h.lateral_ubin == 0.4 and h.maju_ubin == 0.0 and h.lateral_ud == 0.0, "dt = 0: kecepatan, lateral, dan jarak tidak berubah")
	for dt_aneh: float in [-1.0, NAN, INF]:
		h = BikeDrive.langkah(4.2, 0.4, Vector2(1, 1), dt_aneh)
		check(h.kecepatan_ud == 4.2 and h.lateral_ubin == 0.4 and h.maju_ubin == 0.0, "dt %s dianggap 0: keadaan tidak berubah" % dt_aneh)
	# Lateral: geser bebas dibatasi lebar jalan.
	h = BikeDrive.langkah(3.0, 0.0, Vector2(1, 0), 0.1)
	check(is_equal_approx(h.lateral_ubin, 0.3) and is_equal_approx(h.lateral_ud, 3.0), "lateral = sumbu datar x 3,0 u/d x dt: 0,1 detik ke sisi dekat = +0,3 ubin, 3,0 u/d")
	h = BikeDrive.langkah(3.0, 0.0, Vector2(-0.5, 0), 0.2)
	check(is_equal_approx(h.lateral_ubin, -0.3) and is_equal_approx(h.lateral_ud, -1.5), "stick datar -0,5 selama 0,2 detik = -0,3 ubin ke sisi seberang")
	var lat: float = 0.0
	for i: int in range(120):
		lat = BikeDrive.langkah(3.0, lat, Vector2(1, 0), 1.0 / 60.0).lateral_ubin
	check(lat == 1.0, "lateral dijepit di tepi jalan sisi dekat (+1 ubin) setelah 2 detik, dapat %s" % lat)
	for i: int in range(120):
		lat = BikeDrive.langkah(3.0, lat, Vector2(-1, 0), 1.0 / 60.0).lateral_ubin
	check(lat == -1.0, "lateral dijepit di tepi jalan sisi seberang (-1 ubin), dapat %s" % lat)
	h = BikeDrive.langkah(3.0, 1.0, Vector2(1, 0), 0.1)
	check(h.lateral_ubin == 1.0 and h.lateral_ud == 0.0, "menekan keluar tepi jalan: tidak bergeser dan kecepatan lateral efektif 0")
	h = BikeDrive.langkah(3.0, 5.0, Vector2.ZERO, 0.1)
	check(h.lateral_ubin == 1.0, "posisi lateral di luar jalan dikembalikan ke tepi jalan")
	# Diagonal: maju dan lateral dalam satu langkah.
	h = BikeDrive.langkah(3.0, 0.0, Vector2(-0.7, 0.7), 0.1)
	check(h.kecepatan_ud > 3.0 and h.lateral_ubin < 0.0 and h.maju_ubin > 0.0, "diagonal: kecepatan naik dan lateral bergeser dalam satu langkah (%s, %s)" % [h.kecepatan_ud, h.lateral_ubin])
	# Jarak maju = integral kecepatan (trapesium), tepat untuk rampa linear.
	var jarak: float = 0.0
	v = 3.0
	for i: int in range(60):
		var langkah: BikeDrive.Hasil = BikeDrive.langkah(v, 0.0, Vector2(0, 1), 1.0 / 60.0)
		v = langkah.kecepatan_ud
		jarak += langkah.maju_ubin
	check(absf(jarak - 4.5) < 0.0001, "jarak 1 detik rampa 3,0 -> 6,0 = 4,5 ubin (rata-rata 4,5 u/d), dapat %s" % jarak)
	# Murni dan deterministik, batas aman untuk rangkaian acak dengan seed tetap.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20261009
	var kec: float = 3.0
	var lat2: float = 0.0
	var aman: bool = true
	var sama: bool = true
	for i: int in range(2000):
		var stick: Vector2 = Vector2(rng.randf_range(-1.5, 1.5), rng.randf_range(-1.5, 1.5))
		var dt: float = rng.randf_range(0.0, 0.3)
		var a: BikeDrive.Hasil = BikeDrive.langkah(kec, lat2, stick, dt)
		var b: BikeDrive.Hasil = BikeDrive.langkah(kec, lat2, stick, dt)
		if a.kecepatan_ud != b.kecepatan_ud or a.lateral_ubin != b.lateral_ubin or a.arah_sprite != b.arah_sprite:
			sama = false
		if a.kecepatan_ud < Config.KECEPATAN_MELAMBAT_UD or a.kecepatan_ud > Config.KECEPATAN_NGEBUT_UD or absf(a.lateral_ubin) > 1.0 or a.maju_ubin < 0.0:
			aman = false
		kec = a.kecepatan_ud
		lat2 = a.lateral_ubin
	check(sama, "BikeDrive deterministik: masukan sama (2000 rangkaian acak seed tetap) menghasilkan keluaran sama")
	check(aman, "kecepatan selalu di antara melambat dan ngebut, lateral di dalam jalan, jarak tidak negatif (2000 rangkaian acak)")


# --- AC-9: Iso (ART_DIRECTION 2.2) ---

func _test_iso() -> void:
	_judul.call("Iso")
	check(Iso.dunia_ke_layar(Vector2(1, 0)) == Vector2(32, 16), "satu ubin di sumbu x dunia = (+32, +16) px layar, dapat %s" % Iso.dunia_ke_layar(Vector2(1, 0)))
	check(Iso.dunia_ke_layar(Vector2(0, 1)) == Vector2(-32, 16), "satu ubin di sumbu y dunia = (-32, +16) px layar, dapat %s" % Iso.dunia_ke_layar(Vector2(0, 1)))
	check(Iso.dunia_ke_layar(Vector2.ZERO) == Vector2.ZERO, "titik nol dunia = titik nol layar")
	var maju: Vector2 = Iso.dunia_ke_layar(Iso.ARAH_MAJU)
	check(maju == Vector2(32, -16), "maju (-y dunia) = (+32, -16): naik ke kanan atas, dapat %s" % maju)
	check(maju.x > 0.0 and maju.y < 0.0 and maju.x == -2.0 * maju.y, "maju naik ke kanan atas dengan kemiringan tepat 1:2")
	var dekat: Vector2 = Iso.dunia_ke_layar(Iso.ARAH_DEKAT)
	var seberang: Vector2 = Iso.dunia_ke_layar(Iso.ARAH_SEBERANG)
	check(dekat.x > 0.0 and dekat.y > 0.0 and dekat == Vector2(32, 16), "lateral positif (+x, sisi dekat) turun ke kanan, dapat %s" % dekat)
	check(seberang == Vector2(-32, -16), "lateral negatif (sisi seberang) naik ke kiri, dapat %s" % seberang)
	var semua_tepat: bool = true
	for n: int in range(101):
		if Iso.dunia_ke_layar(Iso.ARAH_MAJU * float(n)) != Vector2(32.0 * n, -16.0 * n):
			semua_tepat = false
	check(semua_tepat, "100 ubin maju berturut-turut selalu tepat (+32, -16) per ubin")
	# Bolak-balik dunia -> layar -> dunia dan sebaliknya (RNG seed tetap).
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 64
	var bolak_balik: bool = true
	var linear: bool = true
	for i: int in range(300):
		var titik: Vector2 = Vector2(rng.randf_range(-500.0, 500.0), rng.randf_range(-500.0, 500.0))
		# Vector2 berpresisi tunggal (float32): di koordinat sampai 16000 px galat per komponen sekitar 0,002 px.
		if Iso.layar_ke_dunia(Iso.dunia_ke_layar(titik)).distance_to(titik) > 0.001:
			bolak_balik = false
		if Iso.dunia_ke_layar(Iso.layar_ke_dunia(titik)).distance_to(titik) > 0.05:
			bolak_balik = false
		var lain: Vector2 = Vector2(rng.randf_range(-50.0, 50.0), rng.randf_range(-50.0, 50.0))
		if Iso.dunia_ke_layar(titik + lain).distance_to(Iso.dunia_ke_layar(titik) + Iso.dunia_ke_layar(lain)) > 0.05:
			linear = false
	check(bolak_balik, "dunia -> layar -> dunia dan layar -> dunia -> layar mengembalikan titik awal (300 titik acak seed tetap)")
	check(linear, "proyeksi linear: jumlah dua posisi dunia diproyeksikan sama dengan jumlah proyeksinya")
	var bulat: Vector2 = Iso.posisi_gambar(Vector2(0.3, 0.1))
	check(bulat == bulat.round() and bulat == Vector2(6, 6), "posisi gambar dibulatkan ke piksel: (0,3, 0,1) ubin = (6, 6) px, dapat %s" % bulat)
	check(Iso.posisi_gambar(Vector2(1, 0)) == Vector2(32, 16), "posisi gambar tepat untuk posisi ubin bulat")


# --- AC-10: stick -> BikeDrive -> LoperAnim (terpadu, tanpa node) ---

## Menjalankan `langkah` berulang: mengembalikan hasil langkah terakhir. `v0` dan `lat0` = keadaan awal.
func _jalankan(stick: Vector2, jumlah: int, dt: float, v0: float = 3.0, lat0: float = 0.0) -> BikeDrive.Hasil:
	var v: float = v0
	var lat: float = lat0
	var hasil: BikeDrive.Hasil = null
	for i: int in range(jumlah):
		hasil = BikeDrive.langkah(v, lat, stick, dt)
		v = hasil.kecepatan_ud
		lat = hasil.lateral_ubin
	return hasil


func _animasi(h: BikeDrive.Hasil) -> StringName:
	return LoperAnim.nama_animasi(h.tingkat_sprite, h.arah_sprite)


func _test_stick_ke_animasi() -> void:
	_judul.call("Stick ke gerak ke animasi (terpadu)")
	var dt: float = 1.0 / 60.0
	# (a) netral
	var a: BikeDrive.Hasil = _jalankan(Vector2.ZERO, 60, dt)
	check(a.kecepatan_ud == 3.0 and _animasi(a) == &"santai_normal", "10a: stick netral -> 3,0 u/d dan santai_normal, dapat %s %s" % [a.kecepatan_ud, _animasi(a)])
	# (b) atas penuh lurus
	var b: BikeDrive.Hasil = _jalankan(Vector2(0, 1), 120, dt)
	check(b.kecepatan_ud == 6.0 and _animasi(b) == &"ngebut_normal", "10b: atas penuh lurus -> 6,0 u/d dan ngebut_normal, dapat %s %s" % [b.kecepatan_ud, _animasi(b)])
	# Tingkat mengikuti kekuatan stick: 0,33 cepat, 0,80 cepat, 0,81 ngebut.
	check(_animasi(_jalankan(Vector2(0, 0.34), 1, dt)) == &"cepat_normal" and _animasi(_jalankan(Vector2(0, 0.32), 1, dt)) == &"santai_normal", "10b: kekuatan stick 0,34 = cepat, 0,32 = santai (ambang 33%)")
	check(_animasi(_jalankan(Vector2(0, 0.79), 1, dt)) == &"cepat_normal" and _animasi(_jalankan(Vector2(0, 0.81), 1, dt)) == &"ngebut_normal", "10b: kekuatan stick 0,79 = cepat, 0,81 = ngebut (ambang 80%; batas tepat 0,80 dites di LoperAnim karena Vector2 berpresisi tunggal)")
	# (c) bawah penuh
	var c: BikeDrive.Hasil = _jalankan(Vector2(0, -1), 1, dt)
	check(_animasi(c) == &"santai_normal", "10c: bawah penuh = santai_normal (stick negatif = santai), dapat %s" % _animasi(c))
	c = _jalankan(Vector2(0, -1), 120, dt)
	check(c.kecepatan_ud == 1.5 and _animasi(c) == &"santai_normal", "10c: bawah penuh turun ke 1,5 u/d dan tetap santai_normal, dapat %s %s" % [c.kecepatan_ud, _animasi(c)])
	# (d) kiri penuh tanpa maju: 45 derajat, serong seberang
	var d: BikeDrive.Hasil = _jalankan(Vector2(-1, 0), 1, dt)
	check(is_equal_approx(d.kecepatan_ud, 3.0) and is_equal_approx(d.lateral_ud, -3.0), "10d: kiri penuh tanpa maju: maju 3,0 dan lateral -3,0 u/d (sudut 45 derajat), dapat %s dan %s" % [d.kecepatan_ud, d.lateral_ud])
	check(d.arah_sprite == -1 and _animasi(d) == &"santai_serong_kiri", "10d: kiri penuh = serong seberang (santai_serong_kiri), dapat %s" % _animasi(d))
	d = _jalankan(Vector2(-1, 0), 10, dt)
	check(_animasi(d) == &"santai_serong_kiri", "10d: tetap serong seberang selama lateral belum membentur tepi jalan (setelah 10 langkah)")
	d = _jalankan(Vector2(-1, 0), 60, dt)
	check(d.lateral_ubin == -1.0 and d.arah_sprite == 0, "10d: setelah membentur tepi jalan seberang lateral nyata 0 -> sprite kembali normal (arah dari gerak sebenarnya, D-4)")
	# (e) kanan penuh: serong dekat
	var e: BikeDrive.Hasil = _jalankan(Vector2(1, 0), 1, dt)
	check(e.arah_sprite == 1 and _animasi(e) == &"santai_serong_kanan", "10e: kanan penuh = serong dekat (santai_serong_kanan), dapat %s" % _animasi(e))
	# Lateral murni sangat lambat (stick datar kecil) tetap normal bila sudut di bawah 22,5 derajat.
	var f0: BikeDrive.Hasil = _jalankan(Vector2(0.1, 0), 1, dt)
	check(f0.arah_sprite == 0, "10: lateral kecil (stick datar 0,1: sudut 5,7 derajat) = normal")
	# (f) diagonal atas-seberang tepat di batas 22,5 derajat.
	var diagonal: Vector2 = StickMap.dari_tombol(true, false, true, false)
	var kec_target: float = BikeDrive.kecepatan_target_ud(diagonal.y)
	var f: BikeDrive.Hasil = _jalankan(diagonal, 1, dt, kec_target)
	var sudut: float = rad_to_deg(atan2(absf(f.lateral_ud), f.kecepatan_ud))
	check(absf(sudut - 22.5) < 0.000001, "10f: diagonal keyboard atas + seberang pada kecepatan target (%s u/d) bergerak tepat 22,5 derajat dari arah jalan, dapat %s" % [kec_target, sudut])
	check(f.arah_sprite == -1 and _animasi(f) == &"cepat_serong_kiri", "10f: tepat di batas 22,5 derajat hasilnya serong seberang (cepat_serong_kiri): batas bawah serong inklusif dengan toleransi 1e-6 derajat (LoperAnim.besar_arah_dari_sudut), dapat %s" % _animasi(f))
	var sedikit_kurang: BikeDrive.Hasil = _jalankan(Vector2(diagonal.x * 0.99, diagonal.y), 1, dt, kec_target)
	check(sedikit_kurang.arah_sprite == 0, "10f: lateral 1%% lebih kecil dari batas -> sudut di bawah 22,5 derajat -> normal (batas tidak berkedip karena derau)")
	var sedikit_lebih: BikeDrive.Hasil = _jalankan(Vector2(diagonal.x * 1.01, diagonal.y), 1, dt, kec_target)
	check(sedikit_lebih.arah_sprite == -1, "10f: lateral 1%% lebih besar dari batas -> serong seberang")
	# Stick kiri tidak mengubah tingkat kecuali ada komponen atas (tingkat dari kekuatan ke atas, D-4).
	check(_jalankan(Vector2(-1, 0), 1, dt).tingkat_sprite == 0 and _jalankan(Vector2(-1, 0.5), 1, dt).tingkat_sprite == 1, "tingkat sprite dari komponen atas stick: kiri penuh santai, kiri + atas 0,5 cepat")


# --- Jalan tanpa ujung (AC-11): logika murni ---

func _test_jalan_daur() -> void:
	_judul.call("JalanDaur")
	# Jenis ubin menurut jarak dari garis tengah jalan, simetris.
	for sisi: float in [-1.0, 1.0]:
		check(JalanDaur.jenis_di(0.5 * sisi) == JalanDaur.Jenis.ASPAL, "x %s = aspal" % (0.5 * sisi))
		check(JalanDaur.jenis_di(1.5 * sisi) == JalanDaur.Jenis.TROTOAR, "x %s = trotoar" % (1.5 * sisi))
		check(JalanDaur.jenis_di(2.5 * sisi) == JalanDaur.Jenis.RUMPUT and JalanDaur.jenis_di(40.5 * sisi) == JalanDaur.Jenis.RUMPUT, "x %s dan seterusnya = rumput" % (2.5 * sisi))
		check(JalanDaur.jenis_di(1.0 * sisi) == JalanDaur.Jenis.TROTOAR and JalanDaur.jenis_di(2.0 * sisi) == JalanDaur.Jenis.RUMPUT, "batas aspal-trotoar (x %s) dan trotoar-rumput dihitung ke jenis luar" % (1.0 * sisi))
	# Cakupan: tiap titik layar di jendela pandang punya ubin, untuk semua lebar dan posisi sepeda.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	for lebar: int in LEBAR_UJI:
		var sel: PackedVector2Array = JalanDaur.sel_tanah(lebar, TINGGI)
		var kamus: Dictionary = {}
		for pusat: Vector2 in sel:
			kamus[pusat] = true
		check(sel.size() > 200 and sel.size() < 900, "lebar %d: blok tanah memuat sejumlah ubin yang wajar (%d)" % [lebar, sel.size()])
		check(kamus.size() == sel.size(), "lebar %d: tidak ada ubin kembar di blok tanah" % lebar)
		var semua_ada: bool = true
		var contoh_gagal: String = ""
		for lateral: float in [-1.0, -0.37, 0.0, 0.62, 1.0]:
			for pecahan: float in [0.0, 0.25, 0.5, 0.999]:
				var posisi_sepeda: float = 123.0 + pecahan
				var sepeda_layar: Vector2 = Iso.dunia_ke_layar(Vector2(lateral, -posisi_sepeda))
				var asal_blok: Vector2 = Iso.dunia_ke_layar(Vector2(0, -floorf(posisi_sepeda)))
				for i: int in range(150):
					var rel: Vector2 = Vector2(rng.randf_range(-float(lebar) * Config.KAMERA_SEPEDA_X_PECAHAN, float(lebar) * (1.0 - Config.KAMERA_SEPEDA_X_PECAHAN)), rng.randf_range(-float(TINGGI) * Config.KAMERA_SEPEDA_Y_PECAHAN, float(TINGGI) * (1.0 - Config.KAMERA_SEPEDA_Y_PECAHAN)))
					var dunia: Vector2 = Iso.layar_ke_dunia(sepeda_layar + rel - asal_blok)
					var pusat: Vector2 = Vector2(floorf(dunia.x) + 0.5, roundf(dunia.y) + 0.0)
					if not kamus.has(pusat):
						semua_ada = false
						contoh_gagal = "lateral %s pecahan %s titik %s" % [lateral, pecahan, rel]
		check(semua_ada, "lebar %d: seluruh jendela pandang tertutup ubin di semua posisi sepeda (tidak ada ujung terlihat); gagal di %s" % [lebar, contoh_gagal])
	# Daur objek berkala.
	var periode: int = Config.JALAN_UJI_RUMAH_PERIODE_UBIN
	var mundur: int = Config.JALAN_UJI_DAUR_MUNDUR_UBIN
	var maju: int = Config.JALAN_UJI_DAUR_MAJU_UBIN
	var jumlah: int = JalanDaur.jumlah_slot(mundur, maju, periode)
	check(periode == 4 and jumlah == 9, "daur: periode 4 ubin, slot cukup untuk 12 ubin belakang dan 16 depan = 9, dapat periode %d slot %d" % [periode, jumlah])
	var baik: bool = true
	var tercakup: bool = true
	var sebelumnya: Dictionary = {}
	var maks_ganti: int = 0
	var jarak: float = 0.0
	while jarak < 300.0:
		var pertama: int = JalanDaur.indeks_pertama(jarak, periode, mundur)
		var sekarang: Dictionary = {}
		var terkecil: int = 1000000
		var terbesar: int = -1000000
		for slot: int in range(jumlah):
			var indeks: int = JalanDaur.indeks_slot(pertama, slot, jumlah)
			sekarang[slot] = indeks
			terkecil = mini(terkecil, indeks)
			terbesar = maxi(terbesar, indeks)
			if posmod(indeks, jumlah) != slot:
				baik = false
		if terkecil != pertama or terbesar != pertama + jumlah - 1:
			baik = false
		var jarak_kecil: float = JalanDaur.maju_objek_ubin(terkecil, periode, 0.0)
		var jarak_besar: float = JalanDaur.maju_objek_ubin(terbesar, periode, 0.0)
		if jarak_kecil > jarak - float(mundur) + float(periode) or jarak_besar < jarak + float(maju):
			tercakup = false
		var ganti: int = 0
		for slot: int in sekarang:
			if sebelumnya.has(slot) and sebelumnya[slot] != sekarang[slot]:
				ganti += 1
		maks_ganti = maxi(maks_ganti, ganti)
		sebelumnya = sekarang
		jarak += 0.37
	check(baik, "daur: tiap slot memegang nomor yang kongruen dengan slotnya dan nomor berurutan tanpa kembar")
	check(tercakup, "daur: objek selalu menutup dari %d ubin di belakang sampai %d ubin di depan sepeda" % [mundur, maju])
	check(maks_ganti <= 1, "daur: dalam satu langkah paling banyak satu slot pindah (tidak ada lompatan), terbanyak %d" % maks_ganti)
	check(JalanDaur.indeks_pertama(-0.5, 4, 0) == -1 and JalanDaur.indeks_pertama(3.99, 4, 0) == 0 and JalanDaur.indeks_pertama(4.0, 4, 0) == 1, "indeks pertama membulat ke bawah (floor), termasuk jarak negatif")


# --- Cakram piksel stick (AC-14) ---

func _test_piksel_lingkaran() -> void:
	_judul.call("PikselLingkaran")
	var radius: int = int(Config.STICK_RADIUS_PX)
	check(PikselLingkaran.sisi(radius) == 71 and PikselLingkaran.sisi(Config.STICK_KNOB_RADIUS_PX) == 31, "sisi persegi cincin 71 px dan knob 31 px")
	check(PikselLingkaran.di_dalam(0, 0, radius) and PikselLingkaran.di_dalam(radius, 0, radius) and not PikselLingkaran.di_dalam(radius + 1, 0, radius), "pusat dan titik di jari-jari masuk cakram, 1 px di luarnya tidak")
	var simetris: bool = true
	var luas: int = 0
	for dy: int in range(-radius - 2, radius + 3):
		for dx: int in range(-radius - 2, radius + 3):
			var ada: bool = PikselLingkaran.di_dalam(dx, dy, radius)
			if ada != PikselLingkaran.di_dalam(-dx, dy, radius) or ada != PikselLingkaran.di_dalam(dx, -dy, radius) or ada != PikselLingkaran.di_dalam(dy, dx, radius):
				simetris = false
			if ada:
				luas += 1
	check(simetris, "cakram simetris terhadap sumbu dan diagonal")
	var luas_ideal: float = PI * float(radius * radius + radius)
	check(absf(float(luas) - luas_ideal) / luas_ideal < 0.01, "luas cakram mendekati pi (r^2 + r) (dalam 1%%): %d piksel dibanding %s" % [luas, luas_ideal])
	check(not PikselLingkaran.di_cincin(0, 0, radius, 2) and PikselLingkaran.di_cincin(radius, 0, radius, 2) and PikselLingkaran.di_cincin(radius - 1, 0, radius, 2) and not PikselLingkaran.di_cincin(radius - 2, 0, radius, 2), "cincin tebal 2 px: pusat kosong, dua piksel terluar terisi, dalamnya kosong")
