class_name TesUmpanBalik
extends RefCounted
## Tes umpan balik kecepatan run fase1b-umpan-balik: `UmpanBalikKecepatan` murni (AC-2, D-1), `PancaranPiksel` (D-2), dan partikel
## di scene `jalan_uji.tscn` (AC-3): santai tanpa garis, ngebut dengan garis, debu ikut kecepatan, debu rem, batas jumlah, berhenti
## saat jeda, tanpa `GPUParticles2D`, warna dari `Palette`. Scene dijalankan dengan `perbarui(DT)` dan `PancaranPiksel.maju(DT)`.
## Run fase1c-perapian (QA-006, D-5): debu roda di ruang dunia (tertinggal di jalan saat maju dan pindah sisi), garis kecepatan tetap
## di ruang lokal sepeda, debu digambar di belakang sprite pemain. Run fase2a-lemparan (P-1, P-2; QA-001, QA-002 run fase1c-perapian):
## titik gambar debu (`PancaranPiksel.titik_gambar`) dan gambar ulang saat induk bergeser tanpa `maju`.

const BERKAS_JALAN_UJI: String = "res://scenes/dev/jalan_uji.tscn"
const DT: float = 1.0 / 60.0
const SKALA: int = 3
const TITIK_STICK: Vector2 = Vector2(100, 260)
const TOL: float = 0.000001

var _cek: Callable
var _judul: Callable
var _tree: SceneTree


func _init(cek: Callable, judul: Callable, tree: SceneTree) -> void:
	_cek = cek
	_judul = judul
	_tree = tree


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_test_config()
	_test_debu()
	_test_garis()
	_test_masukan_aneh_dan_murni()
	_test_pancaran()
	await _test_scene()
	await _test_scene_jeda()
	await _test_debu_ruang_dunia()
	await _test_titik_gambar_debu()


func _test_config() -> void:
	_judul.call("Umpan balik kecepatan: angka Config (D-1, usulan)")
	check(Config.UMPAN_DEBU_AMBANG_UD == Config.KECEPATAN_SANTAI_UD and Config.UMPAN_DEBU_PENUH_UD == Config.KECEPATAN_NGEBUT_UD, "debu: ambang = santai 3,0, penuh = ngebut 6,0")
	check(Config.UMPAN_GARIS_AMBANG_UD == Config.KECEPATAN_CEPAT_UD and Config.UMPAN_GARIS_PENUH_UD == Config.KECEPATAN_NGEBUT_UD, "garis: ambang = cepat 4,5, penuh = ngebut 6,0")
	check(Config.UMPAN_KURANGI_EFEK == false, "kurangi efek bawaan mati")
	check(Config.UMPAN_DEBU_BATAS > 0 and Config.UMPAN_GARIS_BATAS > 0 and Config.UMPAN_DEBU_BATAS + Config.UMPAN_GARIS_BATAS <= 32, "batas partikel ada dan kecil (debu %d + garis %d <= 32)" % [Config.UMPAN_DEBU_BATAS, Config.UMPAN_GARIS_BATAS])
	check(Config.UMPAN_DEBU_UKURAN_MAKS_PX >= 1 and Config.UMPAN_DEBU_UKURAN_MAKS_PX <= 2, "partikel debu kotak 1-2 px game")


func _test_debu() -> void:
	_judul.call("UmpanBalikKecepatan.laju_debu (AC-2)")
	var minimum: float = Config.UMPAN_DEBU_LAJU_MIN
	var maks: float = Config.UMPAN_DEBU_LAJU_MAKS
	for v: float in [0.0, 0.5, 1.5, 2.99, 2.999999]:
		check(UmpanBalikKecepatan.laju_debu(v, false, false) == 0.0, "kecepatan %s (di bawah ambang 3,0): tanpa debu" % v)
	check(UmpanBalikKecepatan.laju_debu(3.0, false, false) == minimum, "tepat di ambang 3,0 (inklusif): laju minimum %s" % minimum)
	check(absf(UmpanBalikKecepatan.laju_debu(4.5, false, false) - (minimum + maks) / 2) < TOL, "4,5 (separuh): laju tengah %s" % ((minimum + maks) / 2))
	check(absf(UmpanBalikKecepatan.laju_debu(3.75, false, false) - lerpf(minimum, maks, 0.25)) < TOL, "3,75: seperempat jalan (linear)")
	check(UmpanBalikKecepatan.laju_debu(6.0, false, false) == maks, "ngebut 6,0: laju maksimum %s" % maks)
	check(UmpanBalikKecepatan.laju_debu(6.5, false, false) == maks and UmpanBalikKecepatan.laju_debu(100.0, false, false) == maks, "di atas ngebut dijepit ke maksimum")
	var monoton: bool = true
	var lalu: float = -1.0
	for i: int in range(0, 701):
		var nilai: float = UmpanBalikKecepatan.laju_debu(float(i) / 100.0, false, false)
		if nilai < lalu:
			monoton = false
		lalu = nilai
	check(monoton, "laju debu monoton naik 0..7 u/d")
	# Debu rem.
	check(UmpanBalikKecepatan.laju_debu(2.0, true, false) == Config.UMPAN_DEBU_REM_LAJU and UmpanBalikKecepatan.laju_debu(0.01, true, false) == Config.UMPAN_DEBU_REM_LAJU, "rem aktif dan kecepatan > 0 (juga di bawah ambang): debu rem %s/d" % Config.UMPAN_DEBU_REM_LAJU)
	check(UmpanBalikKecepatan.laju_debu(6.0, true, false) == Config.UMPAN_DEBU_REM_LAJU, "rem aktif di 6,0: laju debu rem (tersendiri)")
	check(UmpanBalikKecepatan.laju_debu(0.0, true, false) == 0.0, "rem aktif di kecepatan 0: tanpa debu")
	check(UmpanBalikKecepatan.laju_debu(2.0, false, false) == 0.0, "tanpa rem di 2,0: tanpa debu (debu rem hanya saat rem aktif)")
	# Kurangi efek.
	for kasus: Array in [[3.0, false], [4.5, false], [6.0, false], [2.0, true]]:
		var penuh: float = UmpanBalikKecepatan.laju_debu(kasus[0], kasus[1], false)
		var kurang: float = UmpanBalikKecepatan.laju_debu(kasus[0], kasus[1], true)
		check(absf(kurang - penuh * Config.UMPAN_KURANGI_DEBU_PENGALI) < TOL and kurang < penuh, "kurangi efek di %s (rem %s): debu dikali %s (%s -> %s)" % [kasus[0], kasus[1], Config.UMPAN_KURANGI_DEBU_PENGALI, penuh, kurang])


func _test_garis() -> void:
	_judul.call("UmpanBalikKecepatan.kekuatan_garis (AC-2)")
	for v: float in [0.0, 3.0, 4.0, 4.49, 4.499999]:
		check(UmpanBalikKecepatan.kekuatan_garis(v, false) == 0.0 and UmpanBalikKecepatan.laju_garis(v, false) == 0.0, "kecepatan %s (di bawah 4,5): tanpa garis" % v)
	check(UmpanBalikKecepatan.kekuatan_garis(4.5, false) == Config.UMPAN_GARIS_KEKUATAN_MIN and Config.UMPAN_GARIS_KEKUATAN_MIN > 0.0, "tepat 4,5 (inklusif): garis mulai tampil, kekuatan %s" % Config.UMPAN_GARIS_KEKUATAN_MIN)
	check(UmpanBalikKecepatan.kekuatan_garis(6.0, false) == 1.0, "ngebut 6,0: garis penuh")
	check(absf(UmpanBalikKecepatan.kekuatan_garis(5.25, false) - lerpf(Config.UMPAN_GARIS_KEKUATAN_MIN, 1.0, 0.5)) < TOL, "5,25: separuh jalan (linear)")
	check(absf(UmpanBalikKecepatan.kekuatan_garis(4.875, false) - lerpf(Config.UMPAN_GARIS_KEKUATAN_MIN, 1.0, 0.25)) < TOL, "4,875: seperempat jalan (linear)")
	check(UmpanBalikKecepatan.kekuatan_garis(7.0, false) == 1.0 and UmpanBalikKecepatan.kekuatan_garis(1000.0, false) == 1.0, "di atas ngebut dijepit 1")
	check(absf(UmpanBalikKecepatan.laju_garis(6.0, false) - Config.UMPAN_GARIS_LAJU_MAKS) < TOL and absf(UmpanBalikKecepatan.laju_garis(5.25, false) - UmpanBalikKecepatan.kekuatan_garis(5.25, false) * Config.UMPAN_GARIS_LAJU_MAKS) < TOL, "laju garis = kekuatan x laju maksimum")
	for v: float in [4.5, 5.0, 6.0, 9.0]:
		check(UmpanBalikKecepatan.kekuatan_garis(v, true) == 0.0 and UmpanBalikKecepatan.laju_garis(v, true) == 0.0, "kurangi efek di %s: garis mati" % v)


func _test_masukan_aneh_dan_murni() -> void:
	_judul.call("UmpanBalikKecepatan: masukan aneh dan murni (AC-2)")
	for v: float in [NAN, INF, -INF, -1.0, -0.0001]:
		for rem: bool in [false, true]:
			check(UmpanBalikKecepatan.laju_debu(v, rem, false) == 0.0, "debu: kecepatan %s (rem %s) = 0" % [v, rem])
		check(UmpanBalikKecepatan.kekuatan_garis(v, false) == 0.0 and UmpanBalikKecepatan.laju_garis(v, false) == 0.0, "garis: kecepatan %s = 0" % v)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1505
	var sama: bool = true
	for i: int in range(500):
		var v: float = rng.randf_range(-2.0, 9.0)
		var rem: bool = rng.randi_range(0, 1) == 1
		var kurang: bool = rng.randi_range(0, 1) == 1
		if UmpanBalikKecepatan.laju_debu(v, rem, kurang) != UmpanBalikKecepatan.laju_debu(v, rem, kurang) or UmpanBalikKecepatan.kekuatan_garis(v, kurang) != UmpanBalikKecepatan.kekuatan_garis(v, kurang):
			sama = false
		var debu: float = UmpanBalikKecepatan.laju_debu(v, rem, kurang)
		var garis: float = UmpanBalikKecepatan.kekuatan_garis(v, kurang)
		if debu < 0.0 or debu > maxf(Config.UMPAN_DEBU_LAJU_MAKS, Config.UMPAN_DEBU_REM_LAJU) or garis < 0.0 or garis > 1.0:
			sama = false
	check(sama, "500 masukan acak (seed tetap): hasil sama untuk masukan sama, dalam rentang")


func _test_pancaran() -> void:
	_judul.call("PancaranPiksel: laju, umur, batas, arah (D-2)")
	var p: PancaranPiksel = PancaranPiksel.new()
	p.siapkan(5, 7)
	p.umur_detik = 0.5
	p.kecepatan_px = 60.0
	p.arah = Vector2(-2, 1).normalized()
	p.asal = Vector2(-12, 2)
	p.laju = 10.0
	for i: int in range(7):
		p.maju(DT)
	check(p.jumlah_aktif() == 1, "10/detik selama 7/60 detik: 1 partikel, dapat %d" % p.jumlah_aktif())
	p.laju = 20.0
	for i: int in range(20):
		p.maju(DT)
	check(p.jumlah_aktif() == 5, "20/detik sekitar 0,45 detik (umur 0,5): dibatasi 5 (batas), dapat %d" % p.jumlah_aktif())
	p.laju = 1000.0
	p.maju(DT)
	check(p.jumlah_aktif() == 5, "laju besar tidak melewati batas")
	var sejajar: bool = true
	for pos: Vector2 in p.posisi_partikel():
		var geser: Vector2 = pos - p.asal
		if geser.length() > 0.0001 and absf(geser.normalized().dot(p.arah)) < 0.999:
			sejajar = false
	check(sejajar, "tanpa sebaran: partikel bergerak lurus sejajar jalan (2:1) dari titik muncul")
	p.laju = 0.0
	for i: int in range(31):
		p.maju(DT)
	check(p.jumlah_aktif() == 0, "laju 0: partikel habis setelah umurnya (0,5 detik)")
	for dt: float in [0.0, -1.0, NAN, INF]:
		p.laju = 100.0
		p.maju(dt)
	check(p.jumlah_aktif() == 0, "dt 0, negatif, NaN, tak hingga: tidak memancar")
	p.free()


func _anak(akar: Node, nama: String) -> Node:
	return akar.find_child(nama, true, false)


func _siapkan() -> JalanUji:
	_tree.root.size = Vector2i(2340, 1080)
	var akar: JalanUji = (load(BERKAS_JALAN_UJI) as PackedScene).instantiate() as JalanUji
	_tree.root.add_child(akar)
	await _tree.process_frame
	await _tree.process_frame
	akar.set_process(false)
	(_anak(akar, "KontrolTouch") as KontrolTouch).keyboard_aktif = false
	var umpan: UmpanBalikSepeda = (_anak(akar, "Sepeda") as SepedaUji).umpan_balik()
	umpan.debu().set_process(false)
	umpan.garis().set_process(false)
	return akar


func _bersihkan(akar: JalanUji) -> void:
	(_anak(akar, "KontrolTouch") as KontrolTouch).keyboard_aktif = OS.has_feature("editor")
	_tree.root.remove_child(akar)
	akar.free()


func _sentuh(index: int, posisi_viewport: Vector2, tekan: bool) -> void:
	var peristiwa: InputEventScreenTouch = InputEventScreenTouch.new()
	peristiwa.index = index
	peristiwa.position = posisi_viewport * float(SKALA)
	peristiwa.pressed = tekan
	Input.parse_input_event(peristiwa)
	Input.flush_buffered_events()


func _geser(index: int, posisi_viewport: Vector2) -> void:
	var peristiwa: InputEventScreenDrag = InputEventScreenDrag.new()
	peristiwa.index = index
	peristiwa.position = posisi_viewport * float(SKALA)
	Input.parse_input_event(peristiwa)
	Input.flush_buffered_events()


## Memajukan scene dan partikel `jumlah` langkah; mengembalikan jumlah debu dan garis terbanyak selama itu.
func _maju(akar: JalanUji, jumlah: int) -> Vector2i:
	var umpan: UmpanBalikSepeda = (_anak(akar, "Sepeda") as SepedaUji).umpan_balik()
	var terbanyak: Vector2i = Vector2i.ZERO
	for i: int in range(jumlah):
		akar.perbarui(DT)
		umpan.debu().maju(DT)
		umpan.garis().maju(DT)
		terbanyak = Vector2i(maxi(terbanyak.x, umpan.debu().jumlah_aktif()), maxi(terbanyak.y, umpan.garis().jumlah_aktif()))
	return terbanyak


func _test_scene() -> void:
	_judul.call("Partikel umpan balik di scene: santai, ngebut, rem, batas (AC-3)")
	var akar: JalanUji = await _siapkan()
	var sepeda: SepedaUji = _anak(akar, "Sepeda") as SepedaUji
	var umpan: UmpanBalikSepeda = sepeda.umpan_balik()
	var debu: PancaranPiksel = umpan.debu()
	var garis: PancaranPiksel = umpan.garis()
	# Tanpa GPUParticles2D (juga tanpa CPUParticles2D) di scene permainan.
	var partikel_mesin: int = 0
	var pancaran: int = 0
	var antre: Array[Node] = [akar]
	while not antre.is_empty():
		var n: Node = antre.pop_back()
		if n is GPUParticles2D or n is CPUParticles2D:
			partikel_mesin += 1
		if n is PancaranPiksel:
			pancaran += 1
		antre.append_array(n.get_children())
	check(partikel_mesin == 0 and pancaran == 2, "jalan_uji.tscn tanpa GPUParticles2D/CPUParticles2D; dua PancaranPiksel (debu, garis), dapat %d dan %d" % [partikel_mesin, pancaran])
	check(debu.warna == Color(Palette.TEXT_2, Config.UMPAN_DEBU_ALPHA) and garis.warna == Color(Palette.TEXT, Config.UMPAN_GARIS_ALPHA), "warna debu TEXT_2 dan garis TEXT dari Palette (alpha dari Config)")
	check(debu.batas() == Config.UMPAN_DEBU_BATAS and garis.batas() == Config.UMPAN_GARIS_BATAS, "batas partikel dari Config")
	var jalan: Vector2 = Iso.dunia_ke_layar(Iso.ARAH_MAJU).normalized()
	check(debu.arah.is_equal_approx(-jalan) and garis.arah.is_equal_approx(-jalan), "arah debu dan garis sejajar jalan (2:1) ke belakang")
	# Santai: debu tipis, tanpa garis.
	var santai: Vector2i = _maju(akar, 120)
	check(sepeda.kecepatan_ud == 3.0 and not garis.memancar() and santai.y == 0 and garis.jumlah_aktif() == 0, "santai 3,0: tanpa garis kecepatan")
	check(debu.memancar() and debu.laju == Config.UMPAN_DEBU_LAJU_MIN and santai.x > 0, "santai: debu tipis (laju %s/d, %d partikel)" % [debu.laju, santai.x])
	# Ngebut: garis dan debu lebih banyak; tidak melewati batas.
	_sentuh(0, TITIK_STICK, true)
	_geser(0, TITIK_STICK - Vector2(0, Config.STICK_RADIUS_PX))
	var ngebut: Vector2i = _maju(akar, 180)
	check(sepeda.kecepatan_ud == 6.0 and garis.memancar() and garis.jumlah_aktif() > 0 and ngebut.y > 0, "ngebut 6,0: garis kecepatan memancar (%d garis)" % garis.jumlah_aktif())
	check(debu.laju == Config.UMPAN_DEBU_LAJU_MAKS and ngebut.x > santai.x, "ngebut: debu mengikuti kecepatan (laju %s, terbanyak %d > santai %d)" % [debu.laju, ngebut.x, santai.x])
	check(ngebut.x <= Config.UMPAN_DEBU_BATAS and ngebut.y <= Config.UMPAN_GARIS_BATAS, "jumlah partikel tidak melewati batas Config (debu %d/%d, garis %d/%d)" % [ngebut.x, Config.UMPAN_DEBU_BATAS, ngebut.y, Config.UMPAN_GARIS_BATAS])
	# Laju di scene = rumus murni dari kecepatan sebenarnya (bukan stick): lepas stick, kecepatan turun bertahap.
	_sentuh(0, TITIK_STICK, false)
	_maju(akar, 30)
	check(sepeda.kecepatan_ud > 4.5 and absf(debu.laju - UmpanBalikKecepatan.laju_debu(sepeda.kecepatan_ud, false, false)) < TOL and absf(garis.laju - UmpanBalikKecepatan.laju_garis(sepeda.kecepatan_ud, false)) < TOL, "stick dilepas: laju dari kecepatan sebenarnya %s (bukan stick)" % sepeda.kecepatan_ud)
	_maju(akar, 120)
	check(not garis.memancar(), "kembali santai: garis berhenti")
	# Rem: debu rem.
	_sentuh(0, TITIK_STICK, true)
	_geser(0, TITIK_STICK - Vector2(0, Config.STICK_RADIUS_PX))
	_maju(akar, 120)
	_geser(0, TITIK_STICK + Vector2(0, Config.STICK_RADIUS_PX))
	_maju(akar, 16)
	check(sepeda.rem_aktif() and sepeda.kecepatan_ud > 0.0 and debu.laju == Config.UMPAN_DEBU_REM_LAJU, "rem aktif sambil bergerak: debu rem %s/d" % debu.laju)
	_maju(akar, 180)
	check(sepeda.kecepatan_ud == 0.0 and debu.laju == 0.0 and not garis.memancar(), "rem sampai berhenti: tanpa debu dan garis")
	_maju(akar, 30)
	check(debu.jumlah_aktif() == 0, "berhenti: debu yang tersisa habis")
	_sentuh(0, TITIK_STICK, false)
	# Kurangi efek di scene.
	umpan.kurangi_efek = true
	_sentuh(0, TITIK_STICK, true)
	_geser(0, TITIK_STICK - Vector2(0, Config.STICK_RADIUS_PX))
	var kurang: Vector2i = _maju(akar, 180)
	check(not garis.memancar() and kurang.y == 0 and debu.laju == Config.UMPAN_DEBU_LAJU_MAKS * Config.UMPAN_KURANGI_DEBU_PENGALI, "kurangi efek saat ngebut: tanpa garis, debu dikurangi (%s/d)" % debu.laju)
	_sentuh(0, TITIK_STICK, false)
	_bersihkan(akar)


func _test_scene_jeda() -> void:
	_judul.call("Partikel berhenti saat jeda (AC-3, AC-7)")
	var akar: JalanUji = await _siapkan()
	var sepeda: SepedaUji = _anak(akar, "Sepeda") as SepedaUji
	var debu: PancaranPiksel = sepeda.umpan_balik().debu()
	var garis: PancaranPiksel = sepeda.umpan_balik().garis()
	_sentuh(0, TITIK_STICK, true)
	_geser(0, TITIK_STICK - Vector2(0, Config.STICK_RADIUS_PX))
	_maju(akar, 180)
	# Proses partikel dinyalakan (seperti saat bermain); kontrol: tanpa jeda posisi berubah tiap frame.
	debu.set_process(true)
	garis.set_process(true)
	var sebelum: PackedVector2Array = debu.posisi_partikel()
	await _tree.process_frame
	await _tree.process_frame
	check(debu.posisi_partikel() != sebelum, "kontrol: tanpa jeda debu bergerak dengan sendirinya")
	akar.minta_jeda()
	var debu_jeda: PackedVector2Array = debu.posisi_partikel()
	var garis_jeda: PackedVector2Array = garis.posisi_partikel()
	check(debu_jeda.size() > 0 and garis_jeda.size() > 0, "saat jeda ada partikel hidup (debu %d, garis %d)" % [debu_jeda.size(), garis_jeda.size()])
	for i: int in range(8):
		await _tree.process_frame
	check(debu.posisi_partikel() == debu_jeda and garis.posisi_partikel() == garis_jeda and not debu.can_process() and not garis.can_process(), "selama jeda partikel tidak memancar dan tidak bergerak (jumlah dan posisi tetap)")
	akar.minta_lanjut()
	for i: int in range(3):
		await _tree.process_frame
	check(debu.posisi_partikel() != debu_jeda, "sesudah lanjut partikel bergerak lagi")
	_sentuh(0, TITIK_STICK, false)
	_bersihkan(akar)


# --- Debu roda di ruang dunia (QA-006 run fase1b-umpan-balik, D-5 run fase1c-perapian) ---

## Posisi lateral dunia (ubin) dari posisi global kanvas (`Objek` dan `JalanUji` di titik asal, jadi kanvas = layar dunia `Iso`).
func _lateral(posisi_global: Vector2) -> float:
	return Iso.layar_ke_dunia(posisi_global).x


## Titik muncul debu sekarang (roda belakang sepeda), global.
func _titik_muncul(debu: PancaranPiksel) -> Vector2:
	return debu.get_global_transform() * debu.asal


func _test_debu_ruang_dunia() -> void:
	_judul.call("Debu roda di ruang dunia: tertinggal saat maju dan pindah sisi, muncul di roda, di belakang pemain (QA-006, D-5)")
	var akar: JalanUji = await _siapkan()
	var sepeda: SepedaUji = _anak(akar, "Sepeda") as SepedaUji
	var umpan: UmpanBalikSepeda = sepeda.umpan_balik()
	var debu: PancaranPiksel = umpan.debu()
	var garis: PancaranPiksel = umpan.garis()
	var sprite: LoperSprite = _anak(akar, "LoperAgen") as LoperSprite
	# (e) Urutan gambar: debu anak sepeda sebelum sprite pemain, tanpa top_level, z tidak di atas pemain.
	check(debu.ruang_dunia and not garis.ruang_dunia, "debu di ruang dunia, garis kecepatan tetap di ruang lokal sepeda")
	check(umpan.get_parent() == sepeda and sprite.get_parent() == sepeda and umpan.get_index() < sprite.get_index(), "UmpanBalik anak SepedaUji sebelum LoperAgen (digambar lebih dulu = di belakang pemain)")
	check(not debu.top_level and not umpan.top_level and debu.z_index == 0 and umpan.z_index == 0 and debu.z_as_relative and sprite.z_index >= 0, "debu tanpa top_level dan tanpa z di atas pemain (urutan gambar tetap di belakang sprite)")
	# Ngebut lurus: debu tertinggal jauh di belakang roda (gerak sepeda), bukan hanya sejauh gerak debu sendiri.
	_sentuh(0, TITIK_STICK, true)
	_geser(0, TITIK_STICK - Vector2(0, Config.STICK_RADIUS_PX))
	_maju(akar, 120)
	var terjauh: float = 0.0
	for p: Vector2 in debu.posisi_global_partikel():
		terjauh = maxf(terjauh, p.distance_to(_titik_muncul(debu)))
	var gerak_sendiri: float = Config.UMPAN_DEBU_KECEPATAN_PX * Config.UMPAN_DEBU_UMUR_DETIK + Config.UMPAN_DEBU_SEBARAN_PX
	check(sepeda.kecepatan_ud == 6.0 and debu.jumlah_aktif() >= 4, "kontrol: ngebut 6,0 dengan debu hidup (%d)" % debu.jumlah_aktif())
	check(terjauh > gerak_sendiri * 2.0, "ngebut: debu tertinggal di jalan, terjauh %.1f px dari roda (gerak debu sendiri paling jauh %.1f px)" % [terjauh, gerak_sendiri])
	# (a) Pindah sisi tanpa waktu berlalu: posisi global debu yang sudah ada tidak berubah; garis ikut sepeda.
	var debu_sebelum: PackedVector2Array = debu.posisi_global_partikel()
	var garis_sebelum: PackedVector2Array = garis.posisi_global_partikel()
	var sepeda_sebelum: Vector2 = sepeda.global_position
	sepeda.lateral_ubin = sepeda.lateral_ubin - 0.8 if sepeda.lateral_ubin > 0.0 else sepeda.lateral_ubin + 0.8
	sepeda.gerak(Vector2.ZERO, 0.0)
	var geser_lateral: Vector2 = sepeda.global_position - sepeda_sebelum
	check(geser_lateral.length() > 20.0, "kontrol: sepeda pindah sisi 0,8 ubin = %s px" % geser_lateral)
	check(debu.posisi_global_partikel() == debu_sebelum, "(a) pindah sisi: posisi global debu yang sudah ada tidak ikut bergeser (%d partikel)" % debu_sebelum.size())
	var garis_ikut: bool = garis_sebelum.size() > 0
	var garis_sesudah: PackedVector2Array = garis.posisi_global_partikel()
	for i: int in range(mini(garis_sebelum.size(), garis_sesudah.size())):
		if not (garis_sesudah[i] - garis_sebelum[i]).is_equal_approx(geser_lateral):
			garis_ikut = false
	check(garis_ikut, "garis kecepatan tetap di ruang lokal: ikut bergeser bersama sepeda (efek kamera)")
	# (b) Maju tanpa waktu berlalu: sama.
	sepeda_sebelum = sepeda.global_position
	sepeda.jarak_ubin += 1.5
	sepeda.gerak(Vector2.ZERO, 0.0)
	check((sepeda.global_position - sepeda_sebelum).length() > 40.0, "kontrol: sepeda maju 1,5 ubin = %s px" % (sepeda.global_position - sepeda_sebelum))
	check(debu.posisi_global_partikel() == debu_sebelum, "(b) maju: posisi global debu yang sudah ada tidak ikut maju")
	# Dorongan kamera hanya mengubah transform kanvas (Camera2D), bukan posisi global; debu bergeser di layar sama dengan jalan.
	var kamera: Camera2D = _anak(akar, "Kamera") as Camera2D
	check(kamera != null and kamera.zoom == Vector2.ONE, "kamera tanpa zoom: posisi global = posisi di jalan, dorongan kamera menggeser jalan dan debu bersama")
	# (c) Partikel baru muncul di roda belakang posisi sepeda sekarang.
	debu.kosongkan()
	var langkah: int = 0
	while debu.jumlah_aktif() == 0 and langkah < 30:
		_maju(akar, 1)
		langkah += 1
	var baru: PackedVector2Array = debu.posisi_global_partikel()
	check(baru.size() == 1 and baru[0].distance_to(_titik_muncul(debu)) <= Config.UMPAN_DEBU_SEBARAN_PX + 0.001, "(c) debu baru muncul di roda belakang posisi sepeda sekarang (jarak %.2f px, sebaran %s)" % [baru[0].distance_to(_titik_muncul(debu)) if baru.size() > 0 else -1.0, Config.UMPAN_DEBU_SEBARAN_PX])
	# Pindah sisi sambil ngebut (langkah biasa): jejak debu tertinggal di sisi lama.
	_maju(akar, 30)
	var lateral_awal: float = sepeda.lateral_ubin
	var ke_sisi: float = -1.0 if lateral_awal > 0.0 else 1.0
	_geser(0, TITIK_STICK + Vector2(ke_sisi * Config.STICK_RADIUS_PX, 0))
	_maju(akar, 12)
	var pindah: float = sepeda.lateral_ubin - lateral_awal
	var muncul_lateral: float = _lateral(_titik_muncul(debu))
	var tertinggal: float = 0.0
	for p: Vector2 in debu.posisi_global_partikel():
		tertinggal = maxf(tertinggal, (_lateral(p) - muncul_lateral) * -signf(pindah))
	check(absf(pindah) >= 0.5 and debu.jumlah_aktif() > 0, "kontrol: pindah sisi %.2f ubin dalam 12 langkah sambil berdebu (%d)" % [pindah, debu.jumlah_aktif()])
	check(tertinggal >= 0.45, "pindah sisi sambil ngebut: jejak debu tertinggal di sisi lama (%.2f ubin dari roda sekarang ke arah sisi lama)" % tertinggal)
	check(debu.jumlah_aktif() <= Config.UMPAN_DEBU_BATAS, "(d) jumlah debu tetap <= batas %d" % Config.UMPAN_DEBU_BATAS)
	_sentuh(0, TITIK_STICK, false)
	_bersihkan(akar)


## Titik gambar partikel `p` cocok dengan posisi globalnya: transform global x titik gambar = posisi global dibulatkan, untuk semua partikel.
func _titik_gambar_cocok(p: PancaranPiksel) -> bool:
	var global: PackedVector2Array = p.posisi_global_partikel()
	var ke_global: Transform2D = p.get_global_transform()
	for i: int in range(global.size()):
		if not (ke_global * p.titik_gambar(i)).is_equal_approx(global[i].round()):
			return false
		if p.titik_gambar(i) != p.titik_gambar(i).round():
			return false
	return global.size() > 0


func _test_titik_gambar_debu() -> void:
	_judul.call("Titik gambar debu ruang dunia dan gambar ulang saat induk bergeser tanpa maju (P-1, P-2; QA-001, QA-002 run 1C)")
	var akar: JalanUji = await _siapkan()
	var sepeda: SepedaUji = _anak(akar, "Sepeda") as SepedaUji
	var umpan: UmpanBalikSepeda = sepeda.umpan_balik()
	var debu: PancaranPiksel = umpan.debu()
	var garis: PancaranPiksel = umpan.garis()
	_sentuh(0, TITIK_STICK, true)
	_geser(0, TITIK_STICK - Vector2(0, Config.STICK_RADIUS_PX))
	_maju(akar, 90)
	_sentuh(0, TITIK_STICK, false)
	var transform_debu: Transform2D = debu.get_global_transform()
	check(debu.jumlah_aktif() >= 4 and transform_debu.origin.length() > 100.0, "kontrol: debu hidup (%d) dan sepeda jauh dari titik asal (%s), jadi transform global bukan identitas" % [debu.jumlah_aktif(), transform_debu.origin])
	# P-1: titik yang digambar = posisi global dibulatkan, dibawa ke ruang lokal (bukan posisi global dipakai sebagai lokal).
	check(_titik_gambar_cocok(debu), "(P-1) debu ruang dunia: transform global x titik_gambar(i) = posisi global dibulatkan, untuk semua partikel")
	check(_titik_gambar_cocok(garis) or garis.jumlah_aktif() == 0, "garis kecepatan (ruang lokal): titik_gambar = posisi lokal dibulatkan, ikut induk")
	check(debu.titik_gambar(-1) == Vector2.ZERO and debu.titik_gambar(debu.jumlah_aktif()) == Vector2.ZERO, "indeks di luar rentang = nol")
	# P-2: induk digeser tanpa `maju` (proses debu mati): debu digambar ulang dan titik gambarnya mengikuti.
	var gambar: Array[int] = [0]
	var hitung: Callable = func() -> void: gambar[0] += 1
	debu.draw.connect(hitung)
	await _tree.process_frame
	await _tree.process_frame
	gambar[0] = 0
	var titik_lama: Vector2 = debu.titik_gambar(0)
	var global_lama: Vector2 = debu.posisi_global_partikel()[0]
	sepeda.position += Vector2(32, 16)
	await _tree.process_frame
	await _tree.process_frame
	check(debu.posisi_global_partikel()[0] == global_lama, "kontrol: induk bergeser, posisi global debu tidak berubah (tanpa maju)")
	check(gambar[0] >= 1, "(P-2) induk bergeser tanpa maju: debu digambar ulang (%d kali)" % gambar[0])
	check(debu.titik_gambar(0) == titik_lama - Vector2(32, 16) and _titik_gambar_cocok(debu), "(P-2) titik gambar mengikuti induk: bergeser -(32, 16) di ruang lokal, tetap di tempat yang sama di jalan")
	# Tanpa geseran induk tidak ada gambar ulang dari jalur ini (proses debu mati).
	gambar[0] = 0
	await _tree.process_frame
	await _tree.process_frame
	check(gambar[0] == 0, "kontrol: tanpa geseran dan tanpa maju, debu tidak digambar ulang (%d)" % gambar[0])
	debu.draw.disconnect(hitung)
	_bersihkan(akar)
