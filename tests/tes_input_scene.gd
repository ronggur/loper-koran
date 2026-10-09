class_name TesInputScene
extends RefCounted
## Tes terpadu run 0B yang butuh scene tree (AC-11, AC-12, AC-13, AC-15): scene jalan uji, event sentuh sintetis lewat
## `Input.parse_input_event`, kidal, HUD, dan aksi keyboard.
##
## Dipanggil dari `tests/run_tests.gd` (`await TesInputScene.new(check, judul, self).jalankan()`). Scene dijalankan dengan
## `set_process(false)` supaya waktu tidak ikut bergerak sendiri: gerak digerakkan lewat `JalanUji.perbarui(dt)` dengan
## `dt` tetap, jadi hasilnya deterministik. Event sentuh diberi dalam PIKSEL JENDELA (kali skala), seperti dari perangkat;
## yang dibuktikan di sini justru bahwa node input menerimanya di ruang koordinat viewport game.

const BERKAS_JALAN_UJI: String = "res://scenes/dev/jalan_uji.tscn"
## Ukuran jendela yang menghasilkan viewport 640, 780, dan 800 lebar pada skala x3: [lebar jendela, tinggi jendela, lebar viewport].
const KASUS_JENDELA: Array = [[1920, 1080, 640], [2340, 1080, 780], [2400, 1080, 800]]
const SKALA: int = 3
const DT: float = 1.0 / 60.0

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
	await _test_scene_jalan_uji()
	await _test_jalan_tanpa_ujung()
	await _test_input_terpadu()
	await _test_langkah_waktu_dijepit()
	await _test_dorongan_kecepatan_scene()
	await _test_kidal_dan_hud()
	_test_proyek_dan_keyboard()
	await _test_melambat_stick()
	await _test_lempar_swipe()
	await _test_lempar_serong_dan_tepi()
	await _test_lempar_dua_jari()
	await _test_lempar_kidal()
	await _test_lempar_batal()


# --- Pembantu ---

## Membuat scene jalan uji pada jendela `jendela` dan menunggu layout selesai. Proses otomatis dimatikan.
func _siapkan(jendela: Vector2i) -> JalanUji:
	_tree.root.size = jendela
	var paket: PackedScene = load(BERKAS_JALAN_UJI) as PackedScene
	var akar: JalanUji = paket.instantiate() as JalanUji
	_tree.root.add_child(akar)
	await _tree.process_frame
	await _tree.process_frame
	akar.set_process(false)
	return akar


func _bersihkan(akar: JalanUji) -> void:
	_tree.root.remove_child(akar)
	akar.free()


func _anak(akar: Node, nama: String) -> Node:
	return akar.find_child(nama, true, false)


## Event sentuh sintetis: `posisi_viewport` dalam piksel game, dikali skala menjadi piksel jendela seperti dari perangkat.
func _sentuh(index: int, posisi_viewport: Vector2, tekan: bool, batal: bool = false) -> void:
	var peristiwa: InputEventScreenTouch = InputEventScreenTouch.new()
	peristiwa.index = index
	peristiwa.position = posisi_viewport * float(SKALA)
	peristiwa.pressed = tekan
	peristiwa.canceled = batal
	Input.parse_input_event(peristiwa)
	Input.flush_buffered_events()


func _geser(index: int, posisi_viewport: Vector2) -> void:
	var peristiwa: InputEventScreenDrag = InputEventScreenDrag.new()
	peristiwa.index = index
	peristiwa.position = posisi_viewport * float(SKALA)
	Input.parse_input_event(peristiwa)
	Input.flush_buffered_events()


func _langkah(akar: JalanUji, jumlah: int) -> void:
	for i: int in range(jumlah):
		akar.perbarui(DT)


# --- AC-11: scene uji ---

func _test_scene_jalan_uji() -> void:
	_judul.call("Scene jalan uji")
	var akar: JalanUji = await _siapkan(Vector2i(2340, 1080))
	check(akar != null and akar.is_inside_tree(), "jalan_uji.tscn masuk scene tree sebagai JalanUji")
	var kamera: Camera2D = _anak(akar, "Kamera") as Camera2D
	var objek: ObjekDaur = _anak(akar, "Objek") as ObjekDaur
	var tanah: TanahDaur = _anak(akar, "Tanah") as TanahDaur
	var sepeda: SepedaUji = _anak(akar, "Sepeda") as SepedaUji
	var hud: HudDev = _anak(akar, "Hud") as HudDev
	var kontrol: KontrolTouch = _anak(akar, "KontrolTouch") as KontrolTouch
	check(kamera != null and objek != null and tanah != null and sepeda != null and hud != null and kontrol != null, "scene memuat Kamera, Tanah, Objek, Sepeda, Hud, dan KontrolTouch")
	if kamera == null or objek == null or tanah == null or sepeda == null or hud == null or kontrol == null:
		_bersihkan(akar)
		return
	check(ProjectSettings.get_setting("application/run/main_scene") == BERKAS_JALAN_UJI, "jalan_uji.tscn adalah run/main_scene")
	check(kamera.zoom == Vector2.ONE, "kamera tanpa zoom (zoom = 1, skala hanya bulat dari stretch)")
	check(kamera.is_current() and not kamera.position_smoothing_enabled, "kamera aktif, tanpa smoothing (posisi dibulatkan di logika)")
	check(objek.y_sort_enabled and sepeda.get_parent() == objek, "Objek adalah induk Y-sort dan sepeda anak langsungnya (Y-sort memakai titik pijak)")
	var sprite: LoperSprite = sepeda.find_child("LoperAgen", true, false) as LoperSprite
	check(sprite != null and sprite.position == Vector2.ZERO and sprite.offset == Vector2(0, -17), "origin sepeda = titik pijak: sprite di (0, 0) dengan offset (0, -17) (loper_agen.tscn)")
	check(objek.jumlah_slot() == JalanDaur.jumlah_slot(Config.JALAN_UJI_DAUR_MUNDUR_UBIN, Config.JALAN_UJI_DAUR_MAJU_UBIN, Config.JALAN_UJI_RUMAH_PERIODE_UBIN), "Objek memegang jumlah slot rumah sesuai JalanDaur")
	# Semua node 2D: skala bulat, filter efektif Nearest, posisi bilangan bulat untuk yang statis.
	var jumlah_tile: int = 0
	var jumlah_sprite: int = 0
	var bulat: bool = true
	var nearest: bool = true
	var posisi_bulat: bool = true
	var semua: Array[Node] = _semua_node(akar)
	for node: Node in semua:
		if node is Node2D:
			var n2d: Node2D = node as Node2D
			if n2d.scale != n2d.scale.round():
				bulat = false
			if n2d.position != n2d.position.round():
				posisi_bulat = false
		if node is Sprite2D or node is AnimatedSprite2D:
			jumlah_sprite += 1
			if _filter_efektif(node as CanvasItem) != CanvasItem.TEXTURE_FILTER_NEAREST:
				nearest = false
			if node.get_parent() == tanah.get_node("Aspal") or node.get_parent() == tanah.get_node("Trotoar") or node.get_parent() == tanah.get_node("Rumput"):
				jumlah_tile += 1
	check(bulat, "semua node 2D memakai skala bulat")
	check(nearest, "semua sprite memakai filter efektif Nearest")
	check(posisi_bulat, "posisi semua node 2D (ubin, rumah, kotak surat, sepeda, kamera) bilangan bulat (piksel tajam)")
	check(jumlah_tile > 200 and jumlah_sprite > jumlah_tile, "blok tanah memuat ratusan ubin (%d) di samping rumah, kotak surat, dan sepeda" % jumlah_tile)
	check(tanah.get_node("Aspal").get_child_count() > 0 and tanah.get_node("Trotoar").get_child_count() > 0 and tanah.get_node("Rumput").get_child_count() > 0, "ada ubin aspal, trotoar, dan rumput")
	# HUD: CanvasLayer terpisah dari dunia, tanpa posisi piksel absolut pada kontainer utama.
	check(hud is CanvasLayer and hud.get_parent() == akar and hud.layer != 0, "HUD adalah CanvasLayer terpisah dari dunia")
	var strip: MarginContainer = _anak(hud, "StripAtas") as MarginContainer
	var panel_bawah: MarginContainer = _anak(hud, "PanelBawah") as MarginContainer
	check(strip != null and strip.anchor_left == 0.0 and strip.anchor_right == 1.0 and strip.anchor_top == 0.0 and strip.anchor_bottom == 0.0, "HUD: strip atas ber-anchor lebar penuh di tepi atas (bukan posisi piksel)")
	check(panel_bawah != null and panel_bawah.anchor_left == 0.0 and panel_bawah.anchor_right == 1.0 and panel_bawah.anchor_top == 1.0 and panel_bawah.anchor_bottom == 1.0, "HUD: panel bawah ber-anchor lebar penuh di tepi bawah (bukan posisi piksel)")
	var tema: Theme = load("res://assets/ui/theme.tres") as Theme
	check(strip != null and panel_bawah != null and strip.theme == tema and panel_bawah.theme == tema and tema != null, "HUD memakai assets/ui/theme.tres (dipasang di scene, bukan gui/theme/custom: tema proyek memuat font saat impor pertama di clone bersih dan menghasilkan ERROR)")
	check(str(ProjectSettings.get_setting("gui/theme/custom", "")).is_empty(), "gui/theme/custom tidak diisi (impor pertama di clone bersih harus tanpa ERROR)")
	var tanpa_posisi_absolut: bool = true
	var hanya_tombol_menerima: bool = true
	for node: Node in _semua_node(hud):
		if node is Control:
			var kontrol_hud: Control = node as Control
			if kontrol_hud != strip and kontrol_hud != panel_bawah and not kontrol_hud.get_parent() is Container:
				tanpa_posisi_absolut = false
			if not kontrol_hud is Button and kontrol_hud.mouse_filter != Control.MOUSE_FILTER_IGNORE:
				hanya_tombol_menerima = false
	check(tanpa_posisi_absolut, "HUD: semua Control selain dua kontainer anchor ditata oleh Container induknya (tanpa posisi piksel absolut)")
	check(hanya_tombol_menerima, "HUD: hanya tombol yang menerima sentuhan (kontainer, panel, label, dan bar memakai MOUSE_FILTER_IGNORE)")
	# Umpan balik stick (AC-14): tekstur cakram/cincin/knob dirasterisasi per piksel game dengan warna dari Palette.
	var tekstur_isi: ImageTexture = kontrol.get("_tekstur_isi") as ImageTexture
	var tekstur_cincin: ImageTexture = kontrol.get("_tekstur_cincin") as ImageTexture
	var tekstur_knob: ImageTexture = kontrol.get("_tekstur_knob") as ImageTexture
	check(tekstur_isi != null and tekstur_cincin != null and tekstur_knob != null, "KontrolTouch membuat tekstur isi, cincin, dan knob stick")
	if tekstur_isi != null and tekstur_cincin != null and tekstur_knob != null:
		var radius: int = int(Config.STICK_RADIUS_PX)
		var gambar_isi: Image = tekstur_isi.get_image()
		var gambar_cincin: Image = tekstur_cincin.get_image()
		var gambar_knob: Image = tekstur_knob.get_image()
		check(gambar_isi.get_size() == Vector2i(71, 71) and gambar_cincin.get_size() == Vector2i(71, 71) and gambar_knob.get_size() == Vector2i(31, 31), "cincin radius 35 (71 px) dan knob radius 15 (31 px), DESIGN_SPEC 3.7")
		check(_hampir(gambar_isi.get_pixel(radius, radius), Color(Palette.TEXT, Config.STICK_ISI_ALPHA)) and gambar_isi.get_pixel(0, 0).a == 0.0, "isi cincin = TEXT alpha 14%, sudut persegi transparan")
		check(_hampir(gambar_cincin.get_pixel(0, radius), Color(Palette.TEXT, Config.STICK_GARIS_ALPHA)) and _hampir(gambar_cincin.get_pixel(1, radius), Color(Palette.TEXT, Config.STICK_GARIS_ALPHA)) and gambar_cincin.get_pixel(2, radius).a == 0.0 and gambar_cincin.get_pixel(radius, radius).a == 0.0, "garis cincin = TEXT alpha 70% setebal 2 px, bagian dalam kosong")
		check(_hampir(gambar_knob.get_pixel(Config.STICK_KNOB_RADIUS_PX, Config.STICK_KNOB_RADIUS_PX), Palette.ACCENT) and gambar_knob.get_pixel(0, 0).a == 0.0, "knob = ACCENT penuh, sudut transparan")
	var lapisan_kontrol: Node = kontrol.get_parent()
	check(lapisan_kontrol is CanvasLayer and lapisan_kontrol != hud, "node input digambar di CanvasLayer sendiri (koordinat gambar = koordinat event)")
	_bersihkan(akar)

	# Sepeda di sepertiga kiri layar (+-8 px) di tiga lebar, di semua posisi lateral dan jarak.
	for kasus: Array in KASUS_JENDELA:
		var lebar: int = kasus[2]
		akar = await _siapkan(Vector2i(kasus[0], kasus[1]))
		sepeda = _anak(akar, "Sepeda") as SepedaUji
		var ukuran: Vector2 = akar.get_viewport_rect().size
		check(ukuran == Vector2(lebar, 360), "jendela %dx%d -> viewport %dx360, dapat %s" % [kasus[0], kasus[1], lebar, ukuran])
		var simpang: float = 0.0
		var simpang_y: float = 0.0
		for lateral: float in [-1.0, 0.0, 0.7, 1.0]:
			for jarak: float in [0.0, 17.3, 250.75]:
				sepeda.lateral_ubin = lateral
				sepeda.jarak_ubin = jarak
				akar.perbarui(0.0)
				await _tree.process_frame
				var layar: Vector2 = sepeda.get_global_transform_with_canvas().origin
				simpang = maxf(simpang, absf(layar.x - float(lebar) / 3))
				simpang_y = maxf(simpang_y, absf(layar.y - 360.0 * Config.KAMERA_SEPEDA_Y_PECAHAN))
		check(simpang <= 8.0, "lebar %d: sepeda di sepertiga kiri layar (simpangan terbesar %s px, batas 8)" % [lebar, simpang])
		check(simpang_y <= 8.0, "lebar %d: sepeda di sekitar %d%% tinggi layar (simpangan terbesar %s px)" % [lebar, int(Config.KAMERA_SEPEDA_Y_PECAHAN * 100.0), simpang_y])
		_bersihkan(akar)


# --- AC-11: jalan tanpa ujung terlihat (tes di scene sungguhan) ---

func _test_jalan_tanpa_ujung() -> void:
	_judul.call("Jalan tanpa ujung terlihat")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 99
	for kasus: Array in KASUS_JENDELA:
		var lebar: int = kasus[2]
		var akar: JalanUji = await _siapkan(Vector2i(kasus[0], kasus[1]))
		var sepeda: SepedaUji = _anak(akar, "Sepeda") as SepedaUji
		var tanah: TanahDaur = _anak(akar, "Tanah") as TanahDaur
		var kamera: Camera2D = _anak(akar, "Kamera") as Camera2D
		var kontrol: KontrolTouch = _anak(akar, "KontrolTouch") as KontrolTouch
		var objek: ObjekDaur = _anak(akar, "Objek") as ObjekDaur
		kontrol.keyboard_aktif = true
		# 60 detik ngebut lurus: stick atas lewat keyboard editor.
		Input.action_press(&"stick_atas")
		var jarak_awal: float = sepeda.jarak_ubin
		var terisi: bool = true
		var sisa_gagal: String = ""
		for detik: int in range(61):
			if detik > 0:
				_langkah(akar, 60)
			# Setiap detik: seluruh layar tertutup ubin, rumah daur masuk jendela pandang.
			var posisi_ubin: Dictionary = {}
			for anak: Node in tanah.get_children():
				for ubin: Node in anak.get_children():
					posisi_ubin[(ubin as Node2D).position] = true
			var asal_layar: Vector2 = kamera.position - akar.get_viewport_rect().size / 2
			for i: int in range(60):
				var titik: Vector2 = asal_layar + Vector2(rng.randf_range(0.0, float(lebar)), rng.randf_range(0.0, 360.0))
				var dunia: Vector2 = Iso.layar_ke_dunia(titik - tanah.position)
				var pusat: Vector2 = Vector2(floorf(dunia.x) + 0.5, roundf(dunia.y) + 0.0)
				if not posisi_ubin.has(Iso.posisi_gambar(pusat)):
					terisi = false
					sisa_gagal = "detik %d titik %s" % [detik, titik]
		Input.action_release(&"stick_atas")
		var tempuh: float = sepeda.jarak_ubin - jarak_awal
		check(tempuh > 355.0, "lebar %d: 60 detik ngebut menempuh sekitar 358 ubin tanpa ujung (dapat %s)" % [lebar, tempuh])
		check(terisi, "lebar %d: sepanjang 60 detik ngebut seluruh layar selalu tertutup ubin (tidak ada ujung terlihat), gagal: %s" % [lebar, sisa_gagal])
		check(sepeda.kecepatan_ud == 6.0 and sepeda.nama_animasi() == &"ngebut_normal", "lebar %d: 60 detik ngebut: kecepatan 6,0 u/d dan animasi ngebut_normal" % lebar)
		# Penanda gerak: rumah berkala tetap ada di sisi seberang di sekitar sepeda, jaraknya satu periode, dan daur tidak menumpuk.
		var maju_rumah: Array[float] = []
		for anak: Node in objek.get_children():
			if String(anak.name).begins_with("Rumah"):
				var dunia_rumah: Vector2 = Iso.layar_ke_dunia((anak as Node2D).position)
				maju_rumah.append(-dunia_rumah.y)
				check(is_equal_approx(dunia_rumah.x, Config.JALAN_UJI_RUMAH_X_UBIN), "rumah daur di sisi seberang (x %s ubin), dapat %s" % [Config.JALAN_UJI_RUMAH_X_UBIN, dunia_rumah.x])
		maju_rumah.sort()
		var rapi: bool = maju_rumah.size() == objek.jumlah_slot()
		for i: int in range(1, maju_rumah.size()):
			if not is_equal_approx(maju_rumah[i] - maju_rumah[i - 1], float(Config.JALAN_UJI_RUMAH_PERIODE_UBIN)):
				rapi = false
		check(rapi, "lebar %d: rumah berderet tiap %d ubin tanpa celah atau tumpukan (%d rumah)" % [lebar, Config.JALAN_UJI_RUMAH_PERIODE_UBIN, maju_rumah.size()])
		var tercakup: bool = not maju_rumah.is_empty() and maju_rumah[0] <= sepeda.jarak_ubin - float(Config.JALAN_UJI_DAUR_MUNDUR_UBIN) + float(Config.JALAN_UJI_RUMAH_PERIODE_UBIN) and maju_rumah[maju_rumah.size() - 1] >= sepeda.jarak_ubin + float(Config.JALAN_UJI_DAUR_MAJU_UBIN)
		check(tercakup, "lebar %d: rumah daur menutup dari %d ubin di belakang sampai %d ubin di depan sepeda" % [lebar, Config.JALAN_UJI_DAUR_MUNDUR_UBIN, Config.JALAN_UJI_DAUR_MAJU_UBIN])
		kontrol.keyboard_aktif = OS.has_feature("editor")
		_bersihkan(akar)


# --- AC-12: node input, event sintetis ---

func _test_input_terpadu() -> void:
	_judul.call("Input terpadu (event sentuh sintetis, viewport 780x360)")
	var akar: JalanUji = await _siapkan(Vector2i(2340, 1080))
	var sepeda: SepedaUji = _anak(akar, "Sepeda") as SepedaUji
	var kontrol: KontrolTouch = _anak(akar, "KontrolTouch") as KontrolTouch
	var kamera: Camera2D = _anak(akar, "Kamera") as Camera2D
	kontrol.keyboard_aktif = false
	var router: TouchRouter = kontrol.router
	check(akar.get_viewport_rect().size == Vector2(780, 360) and akar.get_viewport().get_final_transform().get_scale() == Vector2(3, 3), "jendela 2340x1080: viewport 780x360 dengan skala x3")
	# Sebelum disentuh: santai, tidak bergerak ke samping.
	_langkah(akar, 30)
	check(sepeda.kecepatan_ud == 3.0 and sepeda.lateral_ubin == 0.0 and sepeda.nama_animasi() == &"santai_normal", "tanpa sentuhan: santai 3,0 u/d, lateral 0, santai_normal")
	# Koordinat: event dalam piksel jendela (300, 780) tiba sebagai (100, 260) di ruang viewport game, juga saat kamera jauh.
	sepeda.jarak_ubin = 300.0
	akar.perbarui(0.0)
	await _tree.process_frame
	check(kamera.position.x > 5000.0, "kamera sudah jauh dari titik asal dunia (%s) sebelum sentuhan diuji" % kamera.position)
	_sentuh(0, Vector2(100, 260), true)
	check(router.stick_aktif() and router.asal_stick() == Vector2(100, 260), "koordinat: sentuhan di piksel jendela (300, 780) tiba di router sebagai (100, 260) di ruang viewport game (bukan piksel jendela, bukan koordinat dunia kamera), dapat %s" % router.asal_stick())
	check(router.lebar_viewport == 780, "router memakai lebar viewport game 780, dapat %d" % router.lebar_viewport)
	_geser(0, Vector2(100, 225))
	check(router.vektor_stick().is_equal_approx(Vector2(0, 1)), "geser ke atas sejauh 35 px game = vektor (0, 1), dapat %s" % router.vektor_stick())
	var posisi_awal: Vector2 = sepeda.position
	var jarak_awal: float = sepeda.jarak_ubin
	_langkah(akar, 90)
	check(sepeda.kecepatan_ud == 6.0, "stick atas penuh 1,5 detik: kecepatan 6,0 u/d, dapat %s" % sepeda.kecepatan_ud)
	check(sepeda.nama_animasi() == &"ngebut_normal", "stick atas penuh: animasi ngebut_normal, dapat %s" % sepeda.nama_animasi())
	check(sepeda.jarak_ubin - jarak_awal > 6.5, "sepeda maju (jarak bertambah %s ubin)" % (sepeda.jarak_ubin - jarak_awal))
	var geser_layar: Vector2 = sepeda.position - posisi_awal
	check(geser_layar.x > 0.0 and geser_layar.y < 0.0 and absf(geser_layar.x + 2.0 * geser_layar.y) <= 2.0, "sepeda naik ke kanan atas dengan kemiringan 1:2 (geser %s)" % geser_layar)
	check(sepeda.position == sepeda.position.round(), "posisi gambar sepeda bilangan bulat")
	# Stick ke seberang: lateral negatif, sprite serong lalu normal setelah membentur tepi jalan.
	_geser(0, Vector2(65, 260))
	check(router.vektor_stick().is_equal_approx(Vector2(-1, 0)), "geser ke kiri layar sejauh 35 px = (-1, 0), dapat %s" % router.vektor_stick())
	_langkah(akar, 6)
	check(sepeda.lateral_ubin < 0.0 and sepeda.nama_animasi() == &"santai_serong_kiri", "stick ke kiri: bergeser ke sisi seberang dan sprite serong seberang (dari gerak nyata), dapat lateral %s animasi %s" % [sepeda.lateral_ubin, sepeda.nama_animasi()])
	_langkah(akar, 120)
	check(sepeda.lateral_ubin == -1.0 and sepeda.nama_animasi() == &"santai_normal" and sepeda.kecepatan_ud == 3.0, "setelah membentur tepi jalan seberang: lateral -1, sprite normal, kecepatan 3,0 u/d, dapat %s" % sepeda.nama_animasi())
	# Dua jari: swipe di zona kanan tidak mengganggu stick.
	_sentuh(1, Vector2(450, 200), true)
	check(router.stick_aktif() and router.swipe_aktif() and router.jumlah_jari_aktif() == 2, "dua jari bersamaan: stick dan swipe aktif")
	_geser(1, Vector2(520, 160))
	check(router.vektor_stick().is_equal_approx(Vector2(-1, 0)) and router.posisi_swipe() == Vector2(520, 160), "menggeser swipe tidak mengubah stick")
	_geser(0, Vector2(100, 225))
	_langkah(akar, 90)
	check(sepeda.kecepatan_ud == 6.0 and router.posisi_swipe() == Vector2(520, 160), "menggeser stick ke atas penuh saat swipe ditahan: sepeda ngebut, swipe tidak terganggu")
	_sentuh(1, Vector2(520, 160), false)
	check(router.jumlah_swipe_selesai == 1 and not router.swipe_aktif() and router.stick_aktif(), "mengangkat jari swipe: swipe tercatat sekali dan stick tetap aktif")
	# Sejak run sprite-lempar-melambat swipe horizontal (70 px ke kanan, 40 px ke atas: datar dominan) melempar ke sisi dekat. Tes lama
	# mengamati animasi kayuh sesudahnya, jadi lempar diperiksa lalu diselesaikan dengan waktu terkontrol (bukan menunggu waktu nyata).
	var pemain_lempar: LoperSprite = _sprite(akar)
	pemain_lempar.set_process(false)
	check(sepeda.sedang_melempar() and sepeda.nama_animasi() == &"lempar_kanan_ngebut_normal", "swipe ke kanan saat ngebut lurus melempar ke sisi dekat: lempar_kanan_ngebut_normal, dapat %s" % sepeda.nama_animasi())
	_langkah(akar, 20)
	check(sepeda.kecepatan_ud == 6.0 and router.stick_aktif() and sepeda.sedang_melempar(), "setelah swipe diangkat sepeda tetap ngebut dan lempar masih berjalan (waktu sprite tidak ikut langkah scene)")
	_selesaikan_lempar(pemain_lempar)
	check(not sepeda.sedang_melempar() and sepeda.nama_animasi() == &"ngebut_normal", "lempar selesai: kembali ke ngebut_normal")
	# Jari stick diangkat: kembali ke santai tanpa gerak sendiri.
	_sentuh(0, Vector2(100, 225), false)
	check(not router.stick_aktif() and router.vektor_stick() == Vector2.ZERO, "mengangkat jari stick: vektor nol dan slot bebas")
	var lateral_sebelum: float = sepeda.lateral_ubin
	_langkah(akar, 150)
	check(sepeda.kecepatan_ud == 3.0 and sepeda.lateral_ubin == lateral_sebelum and sepeda.nama_animasi() == &"santai_normal", "stick dilepas: kembali santai 3,0 u/d, tidak ada geser lateral sendiri, santai_normal")
	# Dua jari, urutan terbalik (swipe lebih dulu).
	_sentuh(5, Vector2(450, 200), true)
	_sentuh(6, Vector2(100, 260), true)
	_geser(6, Vector2(135, 260))
	check(router.stick_aktif() and router.swipe_aktif() and router.vektor_stick().is_equal_approx(Vector2(1, 0)), "dua jari dengan swipe lebih dulu: stick ke sisi dekat (1, 0)")
	_langkah(akar, 6)
	check(sepeda.lateral_ubin > -1.0 and sepeda.nama_animasi() == &"santai_serong_kanan", "stick ke kanan layar: bergeser ke sisi dekat dengan sprite serong dekat, dapat %s" % sepeda.nama_animasi())
	# App di-background atau kehilangan fokus: semua jari dilepas, tidak ada gerak sendiri.
	_tree.root.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(router.jumlah_jari_aktif() == 0 and router.vektor_stick() == Vector2.ZERO, "NOTIFICATION_APPLICATION_FOCUS_OUT melepas semua jari dan menolkan vektor")
	var lateral_fokus: float = sepeda.lateral_ubin
	_langkah(akar, 120)
	check(sepeda.lateral_ubin == lateral_fokus and sepeda.kecepatan_ud == 3.0, "setelah kehilangan fokus tidak ada gerak sendiri, kembali santai")
	_sentuh(7, Vector2(100, 260), true)
	_sentuh(8, Vector2(450, 200), true)
	_tree.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(router.jumlah_jari_aktif() == 0 and router.jumlah_swipe_selesai == 1, "NOTIFICATION_APPLICATION_PAUSED melepas kedua jari tanpa mencatat swipe")
	# Lepas susulan dari jari yang sudah dibatalkan tidak membuat apa-apa.
	_sentuh(7, Vector2(100, 260), false)
	_sentuh(8, Vector2(450, 200), false)
	check(router.jumlah_swipe_selesai == 1 and router.jumlah_jari_aktif() == 0, "lepas susulan dari jari yang sudah dibatalkan diabaikan")
	# Sentuhan dibatalkan sistem (canceled): dilepas tanpa mencatat swipe.
	_sentuh(9, Vector2(450, 200), true)
	_sentuh(9, Vector2(450, 200), false, true)
	check(router.jumlah_swipe_selesai == 1 and not router.swipe_aktif(), "sentuhan canceled dilepas tanpa mencatat swipe")
	# Sentuhan di strip atas (area tombol HUD) tidak diklaim.
	_sentuh(10, Vector2(390, 20), true)
	check(router.jumlah_jari_aktif() == 0, "sentuhan di strip atas (tombol HUD) tidak menjadi stick maupun swipe")
	_sentuh(10, Vector2(390, 20), false)
	# Emulasi sentuhan dari mouse tidak dipasang: event mouse tidak menggerakkan stick.
	var klik: InputEventMouseButton = InputEventMouseButton.new()
	klik.button_index = MOUSE_BUTTON_LEFT
	klik.pressed = true
	klik.position = Vector2(300, 780)
	Input.parse_input_event(klik)
	Input.flush_buffered_events()
	check(router.jumlah_jari_aktif() == 0, "klik mouse di zona stick tidak membuat stick (tidak ada emulasi sentuhan dari mouse)")
	var lepas_klik: InputEventMouseButton = klik.duplicate() as InputEventMouseButton
	lepas_klik.pressed = false
	Input.parse_input_event(lepas_klik)
	Input.flush_buffered_events()
	_bersihkan(akar)


# --- AC-5: melambat dari stick, lempar dari swipe (run sprite-lempar-melambat) ---

## Sprite pemain di scene uji. Waktu lempar dimajukan tes dengan `dt` tetap (`maju`), jadi `_process` sprite dimatikan:
## panggil `_sprite` lagi sesudah tiap swipe, karena `lempar` menyalakan `_process` kembali.
func _sprite(akar: JalanUji) -> LoperSprite:
	var sprite: LoperSprite = _anak(akar, "LoperAgen") as LoperSprite
	sprite.set_process(false)
	return sprite


## Memajukan lempar `jumlah` langkah `DT`. Bila `jumlah` 0, sampai selesai (paling banyak 60 langkah).
func _selesaikan_lempar(sprite: LoperSprite, jumlah: int = 0) -> void:
	for i: int in range(jumlah if jumlah > 0 else 60):
		if not sprite.sedang_melempar():
			return
		sprite.maju(DT)


## Swipe sintetis: jari `index` turun di `dari`, bergeser ke `ke`, diangkat. Lempar (bila ada) dimulai di sini; `_process` sprite dimatikan sesudahnya.
func _swipe(akar: JalanUji, index: int, dari: Vector2, ke: Vector2) -> void:
	_sentuh(index, dari, true)
	_geser(index, ke)
	_sentuh(index, ke, false)
	_sprite(akar).set_process(false)


## Mencatat sinyal sprite: entri [jenis, sisi, animasi saat sinyal].
func _catat_sprite(sprite: LoperSprite) -> Array:
	var catatan: Array = []
	sprite.koran_lepas.connect(func(sisi: LoperAnim.Sisi) -> void: catatan.append(["lepas", int(sisi), sprite.animation]))
	sprite.lempar_selesai.connect(func() -> void: catatan.append(["selesai", -1, sprite.animation]))
	return catatan


func _jumlah(catatan: Array, jenis: String) -> int:
	var hasil: int = 0
	for entri: Array in catatan:
		if entri[0] == jenis:
			hasil += 1
	return hasil


## Stick bawah di scene uji: animasi melambat_* bersama dorongan kecepatan; ambang zona mati 15%.
func _test_melambat_stick() -> void:
	_judul.call("Melambat dari stick di scene uji (AC-5, D-1)")
	var akar: JalanUji = await _siapkan(Vector2i(2340, 1080))
	var sepeda: SepedaUji = _anak(akar, "Sepeda") as SepedaUji
	var kontrol: KontrolTouch = _anak(akar, "KontrolTouch") as KontrolTouch
	var sprite: LoperSprite = _sprite(akar)
	kontrol.keyboard_aktif = false
	var radius: float = Config.STICK_RADIUS_PX
	# Zona mati: 14,9% dan 15,0% ke bawah masih santai, 15,1% sudah melambat (BALANCING 2).
	_sentuh(0, Vector2(100, 260), true)
	_geser(0, Vector2(100, 260.0 + radius * 0.149))
	_langkah(akar, 3)
	check(sepeda.nama_animasi() == &"santai_normal" and sprite.speed_level == 0, "stick ke bawah 14,9%% (zona mati): santai_normal, dapat %s" % sepeda.nama_animasi())
	_geser(0, Vector2(100, 260.0 + radius * 0.150))
	_langkah(akar, 3)
	check(sepeda.nama_animasi() == &"santai_normal", "stick ke bawah tepat 15,0%% (tepi zona mati): santai_normal, dapat %s" % sepeda.nama_animasi())
	_geser(0, Vector2(100, 260.0 + radius * 0.151))
	_langkah(akar, 3)
	check(sepeda.nama_animasi() == &"melambat_normal" and sprite.speed_level == -1, "stick ke bawah 15,1%% (tepat di luar zona mati): melambat_normal, dapat %s" % sepeda.nama_animasi())
	# Stick bawah penuh: melambat_normal, kayuh 4 fps, kecepatan turun ke 1,5 u/d, dorongan kecepatan mundur.
	_geser(0, Vector2(100, 260.0 + radius))
	_langkah(akar, 6)
	check(sepeda.nama_animasi() == &"melambat_normal" and sepeda.kecepatan_ud < 3.0, "stick bawah penuh: melambat_normal dan kecepatan turun (%s u/d)" % sepeda.kecepatan_ud)
	check(is_equal_approx(sprite.sprite_frames.get_animation_speed(sprite.animation), 4.0) and sprite.is_playing(), "melambat berkayuh 4 fps dan berputar")
	_langkah(akar, 114)
	check(sepeda.kecepatan_ud == 1.5 and sepeda.nama_animasi() == &"melambat_normal", "2 detik stick bawah penuh: 1,5 u/d dan tetap melambat_normal, dapat %s %s" % [sepeda.kecepatan_ud, sepeda.nama_animasi()])
	check(akar.geser_dorongan().distance_to(Vector2(-Config.DORONGAN_MUNDUR_PX, Config.DORONGAN_MUNDUR_PX / 2)) < 1.0, "dorongan kecepatan yang sudah ada tetap bekerja bersama melambat: geseran mundur %s" % akar.geser_dorongan())
	# Bawah sambil ke sisi dekat: melambat dengan arah serong dari gerak sebenarnya.
	_geser(0, Vector2(100.0 + radius * 0.7, 260.0 + radius * 0.7))
	_langkah(akar, 4)
	check(sepeda.nama_animasi() == &"melambat_serong_kanan", "stick bawah-dekat: melambat_serong_kanan, dapat %s" % sepeda.nama_animasi())
	# Stick dilepas: tingkat kembali santai.
	_sentuh(0, Vector2(100, 260), false)
	_langkah(akar, 3)
	check(sepeda.nama_animasi() == &"santai_normal" and sprite.speed_level == 0, "stick dilepas: kembali santai_normal")
	kontrol.keyboard_aktif = OS.has_feature("editor")
	_bersihkan(akar)


## Swipe kiri dan kanan di tiga tingkat (stick lurus): lempar_<sisi>_<kecepatan>_normal yang benar, sinyal sekali, kembali ke kayuh.
func _test_lempar_swipe() -> void:
	_judul.call("Lempar dari swipe di scene uji, tiga tingkat (AC-5, D-2, D-3)")
	var akar: JalanUji = await _siapkan(Vector2i(2340, 1080))
	var sepeda: SepedaUji = _anak(akar, "Sepeda") as SepedaUji
	var kontrol: KontrolTouch = _anak(akar, "KontrolTouch") as KontrolTouch
	var sprite: LoperSprite = _sprite(akar)
	var catatan: Array = _catat_sprite(sprite)
	kontrol.keyboard_aktif = false
	var radius: float = Config.STICK_RADIUS_PX
	# [nama tingkat, geseran stick ke atas dalam piksel; 0 = stick tidak disentuh]. 20,125 px = kekuatan 0,5 (cepat).
	var tingkat: Array = [["santai", 0.0], ["cepat", radius * (Config.ZONA_MATI_STICK + (1.0 - Config.ZONA_MATI_STICK) * 0.5)], ["ngebut", radius]]
	var ada_stick: bool = false
	for kasus: Array in tingkat:
		var nama_tingkat: String = kasus[0]
		var tarikan: float = kasus[1]
		if tarikan > 0.0:
			if not ada_stick:
				_sentuh(0, Vector2(100, 260), true)
				ada_stick = true
			_geser(0, Vector2(100, 260.0 - tarikan))
		_langkah(akar, 3)
		check(sepeda.nama_animasi() == StringName("%s_normal" % nama_tingkat), "stick tingkat %s: kayuh %s_normal, dapat %s" % [nama_tingkat, nama_tingkat, sepeda.nama_animasi()])
		# Swipe ke kiri layar -> sisi seberang (kiri), ke kanan layar -> sisi dekat (kanan).
		for arah_swipe: Array in [["kiri", Vector2(500, 200), Vector2(440, 200), LoperAnim.Sisi.SEBERANG], ["kanan", Vector2(440, 200), Vector2(500, 200), LoperAnim.Sisi.DEKAT]]:
			var sebelum: int = catatan.size()
			_swipe(akar, 1, arah_swipe[1], arah_swipe[2])
			var diharapkan: StringName = StringName("lempar_%s_%s_normal" % [arah_swipe[0], nama_tingkat])
			check(sepeda.sedang_melempar() and sepeda.nama_animasi() == diharapkan, "swipe ke %s layar di tingkat %s: %s, dapat %s" % [arah_swipe[0], nama_tingkat, diharapkan, sepeda.nama_animasi()])
			_langkah(akar, 5)
			check(sepeda.nama_animasi() == diharapkan, "gerak sepeda terus (5 langkah scene) tidak mengganti animasi lempar")
			_selesaikan_lempar(sprite)
			var baru: Array = catatan.slice(sebelum)
			check(baru.size() == 2 and baru[0][0] == "lepas" and baru[0][1] == int(arah_swipe[3]) and baru[0][2] == diharapkan and baru[1][0] == "selesai", "swipe ke %s layar di tingkat %s: koran_lepas (sisi %d) lalu lempar_selesai, masing-masing sekali" % [arah_swipe[0], nama_tingkat, int(arah_swipe[3])])
			check(not sepeda.sedang_melempar() and sepeda.nama_animasi() == StringName("%s_normal" % nama_tingkat), "sesudah lempar kembali ke %s_normal" % nama_tingkat)
	check(catatan.size() == 12, "6 swipe menghasilkan 12 sinyal (6 lepas + 6 selesai), dapat %d" % catatan.size())
	if ada_stick:
		_sentuh(0, Vector2(100, 225), false)
	kontrol.keyboard_aktif = OS.has_feature("editor")
	_bersihkan(akar)


## Lempar sambil serong (arah dari gerak sebenarnya), arah 90 derajat, swipe vertikal/pendek/di ambang, swipe di luar zona, swipe saat melempar.
func _test_lempar_serong_dan_tepi() -> void:
	_judul.call("Lempar sambil serong, swipe tidak sah, swipe saat melempar (AC-5, D-2, D-3)")
	var akar: JalanUji = await _siapkan(Vector2i(2340, 1080))
	var sepeda: SepedaUji = _anak(akar, "Sepeda") as SepedaUji
	var kontrol: KontrolTouch = _anak(akar, "KontrolTouch") as KontrolTouch
	var sprite: LoperSprite = _sprite(akar)
	var catatan: Array = _catat_sprite(sprite)
	var router: TouchRouter = kontrol.router
	kontrol.keyboard_aktif = false
	# Stick ke kiri layar (seberang): sprite serong seberang; swipe ke kanan = sisi dekat: lempar_kanan_santai_serong_kiri.
	_sentuh(0, Vector2(100, 260), true)
	_geser(0, Vector2(65, 260))
	_langkah(akar, 6)
	check(sepeda.nama_animasi() == &"santai_serong_kiri", "stick ke kiri: santai_serong_kiri sebelum swipe, dapat %s" % sepeda.nama_animasi())
	_swipe(akar, 1, Vector2(440, 200), Vector2(500, 200))
	check(sepeda.nama_animasi() == &"lempar_kanan_santai_serong_kiri", "swipe ke kanan sambil serong seberang: lempar_kanan_santai_serong_kiri (varian serong yang benar), dapat %s" % sepeda.nama_animasi())
	# Tingkat dan arah berubah selama lempar: gambar lempar tetap, kayuh sesudahnya mengikuti keadaan terkini.
	_geser(0, Vector2(135, 260))
	_langkah(akar, 6)
	check(sepeda.nama_animasi() == &"lempar_kanan_santai_serong_kiri", "stick berbalik ke kanan selama lempar: gambar lempar tidak berganti, dapat %s" % sepeda.nama_animasi())
	_selesaikan_lempar(sprite)
	check(sepeda.nama_animasi() == &"santai_serong_kanan", "sesudah lempar kayuh mengikuti arah TERKINI (santai_serong_kanan), bukan arah saat mulai, dapat %s" % sepeda.nama_animasi())
	# Stick ke kanan: swipe ke kiri = sisi seberang: lempar_kiri_santai_serong_kanan.
	_swipe(akar, 1, Vector2(500, 200), Vector2(440, 200))
	check(sepeda.nama_animasi() == &"lempar_kiri_santai_serong_kanan", "swipe ke kiri sambil serong dekat: lempar_kiri_santai_serong_kanan, dapat %s" % sepeda.nama_animasi())
	_selesaikan_lempar(sprite)
	# Arah 90 derajat belum punya gambar: memakai serong di sisi yang sama (sprite diatur langsung, karena rem Fase 1 belum ada).
	_sentuh(0, Vector2(135, 260), false)
	_langkah(akar, 3)
	sprite.steer = 2
	_swipe(akar, 1, Vector2(440, 200), Vector2(500, 200))
	check(sepeda.nama_animasi() == &"lempar_kanan_santai_serong_kanan", "arah 90 derajat ke dekat + swipe kanan: serong_kanan di sisi yang sama, dapat %s" % sepeda.nama_animasi())
	_selesaikan_lempar(sprite)
	sprite.steer = -2
	_swipe(akar, 1, Vector2(500, 200), Vector2(440, 200))
	check(sepeda.nama_animasi() == &"lempar_kiri_santai_serong_kiri", "arah 90 derajat ke seberang + swipe kiri: serong_kiri, dapat %s" % sepeda.nama_animasi())
	_selesaikan_lempar(sprite)
	_langkah(akar, 3)
	check(sepeda.nama_animasi() == &"santai_normal", "sepeda lurus kembali: santai_normal (arah dipulihkan gerak), dapat %s" % sepeda.nama_animasi())
	# Swipe yang tidak melempar.
	var sebelum: int = catatan.size()
	_swipe(akar, 1, Vector2(450, 250), Vector2(450, 190))
	check(not sepeda.sedang_melempar() and sepeda.nama_animasi() == &"santai_normal", "swipe vertikal ke atas tidak melempar")
	_swipe(akar, 1, Vector2(450, 190), Vector2(450, 250))
	check(not sepeda.sedang_melempar(), "swipe vertikal ke bawah tidak melempar")
	_swipe(akar, 1, Vector2(450, 200), Vector2(480, 240))
	check(not sepeda.sedang_melempar(), "swipe miring dengan gerak tegak lebih besar (30 datar, 40 tegak) tidak melempar")
	_swipe(akar, 1, Vector2(450, 200), Vector2(450 + 11, 200))
	check(not sepeda.sedang_melempar(), "swipe 11 px (di bawah ambang 12) tidak melempar")
	_swipe(akar, 1, Vector2(450, 200), Vector2(450 - 11, 200))
	check(not sepeda.sedang_melempar(), "swipe 11 px ke kiri tidak melempar")
	_swipe(akar, 1, Vector2(450, 200), Vector2(450, 200))
	check(not sepeda.sedang_melempar(), "ketukan tanpa geser (swipe nol) tidak melempar")
	check(router.jumlah_swipe_selesai >= 8 and catatan.size() == sebelum, "swipe tak sah tetap tercatat router (jumlah %d) tetapi tidak ada sinyal sprite" % router.jumlah_swipe_selesai)
	_swipe(akar, 1, Vector2(450, 200), Vector2(450 + 12, 200))
	check(sepeda.sedang_melempar() and sepeda.nama_animasi() == &"lempar_kanan_santai_normal", "swipe tepat 12 px ke kanan (di ambang, inklusif) melempar sisi dekat, dapat %s" % sepeda.nama_animasi())
	_selesaikan_lempar(sprite)
	_swipe(akar, 1, Vector2(450, 200), Vector2(450 - 12, 200))
	check(sepeda.sedang_melempar() and sepeda.nama_animasi() == &"lempar_kiri_santai_normal", "swipe tepat 12 px ke kiri melempar sisi seberang, dapat %s" % sepeda.nama_animasi())
	_selesaikan_lempar(sprite)
	# Swipe yang dimulai di luar zona swipe (strip HUD atas, zona stick) tidak diklaim dan tidak melempar.
	sebelum = catatan.size()
	var jumlah_router: int = router.jumlah_swipe_selesai
	_swipe(akar, 2, Vector2(400, 20), Vector2(500, 20))
	_swipe(akar, 2, Vector2(150, 220), Vector2(60, 220))
	check(not sepeda.sedang_melempar() and router.jumlah_swipe_selesai == jumlah_router and catatan.size() == sebelum, "swipe yang dimulai di strip atas atau zona stick tidak diklaim sebagai swipe dan tidak melempar")
	# Swipe kedua saat masih melempar diabaikan; sesudah selesai swipe baru melempar lagi.
	sebelum = catatan.size()
	_swipe(akar, 1, Vector2(440, 200), Vector2(500, 200))
	_swipe(akar, 1, Vector2(500, 220), Vector2(440, 220))
	check(sepeda.nama_animasi() == &"lempar_kanan_santai_normal", "swipe kedua (ke kiri) saat masih melempar diabaikan: tetap lempar_kanan_santai_normal, dapat %s" % sepeda.nama_animasi())
	_selesaikan_lempar(sprite)
	var baru: Array = catatan.slice(sebelum)
	check(baru.size() == 2 and baru[0][1] == int(LoperAnim.Sisi.DEKAT) and baru[1][0] == "selesai", "hanya lemparan pertama menghasilkan sinyal (koran_lepas sisi dekat, lempar_selesai)")
	_swipe(akar, 1, Vector2(500, 220), Vector2(440, 220))
	check(sepeda.nama_animasi() == &"lempar_kiri_santai_normal", "swipe sesudah lempar selesai melempar lagi (sisi seberang)")
	_selesaikan_lempar(sprite)
	kontrol.keyboard_aktif = OS.has_feature("editor")
	_bersihkan(akar)


## Dua jari: stick menahan ngebut sementara swipe melempar; sepeda tetap bergerak selama lempar.
func _test_lempar_dua_jari() -> void:
	_judul.call("Stick dan swipe bersamaan: sepeda bergerak sambil melempar (AC-5)")
	var akar: JalanUji = await _siapkan(Vector2i(2340, 1080))
	var sepeda: SepedaUji = _anak(akar, "Sepeda") as SepedaUji
	var kontrol: KontrolTouch = _anak(akar, "KontrolTouch") as KontrolTouch
	var sprite: LoperSprite = _sprite(akar)
	var catatan: Array = _catat_sprite(sprite)
	var router: TouchRouter = kontrol.router
	kontrol.keyboard_aktif = false
	_sentuh(0, Vector2(100, 260), true)
	_geser(0, Vector2(100, 225))
	_langkah(akar, 90)
	check(sepeda.kecepatan_ud == 6.0 and sepeda.nama_animasi() == &"ngebut_normal", "ngebut mantap sebelum swipe")
	# Swipe ditahan dulu (jari belum diangkat): tidak ada lempar, stick tetap menggerakkan sepeda.
	_sentuh(1, Vector2(440, 200), true)
	_geser(1, Vector2(500, 200))
	var jarak_awal: float = sepeda.jarak_ubin
	_langkah(akar, 10)
	check(router.jumlah_jari_aktif() == 2 and not sepeda.sedang_melempar() and sepeda.jarak_ubin - jarak_awal > 0.9, "swipe ditahan: dua jari aktif, belum melempar, sepeda terus maju")
	_sentuh(1, Vector2(500, 200), false)
	sprite.set_process(false)
	check(sepeda.sedang_melempar() and sepeda.nama_animasi() == &"lempar_kanan_ngebut_normal", "jari swipe diangkat: lempar_kanan_ngebut_normal")
	# Sepuluh langkah gabungan (scene + sprite) saat melempar: sepeda tetap ngebut dan maju, stick tidak terganggu.
	var jarak_lempar: float = sepeda.jarak_ubin
	for i: int in range(10):
		akar.perbarui(DT)
		sprite.maju(DT)
	check(sepeda.kecepatan_ud == 6.0 and sepeda.jarak_ubin - jarak_lempar > 0.95 and router.stick_aktif(), "selama melempar sepeda tetap ngebut (6,0 u/d) dan maju %s ubin dalam 10 langkah, stick tetap aktif" % (sepeda.jarak_ubin - jarak_lempar))
	check(sepeda.sedang_melempar() and _jumlah(catatan, "lepas") == 1 and sprite.frame == 2, "setengah lempar (10 langkah): koran sudah lepas sekali, masih melempar di frame 2")
	# Stick dilepas di tengah lempar: gambar lempar tidak berganti; sesudah selesai kayuh mengikuti tingkat terkini (santai).
	_sentuh(0, Vector2(100, 225), false)
	for i: int in range(10):
		akar.perbarui(DT)
		sprite.maju(DT)
	check(not sepeda.sedang_melempar() and _jumlah(catatan, "selesai") == 1, "lempar selesai di langkah 20 walau stick dilepas di tengah")
	check(sepeda.nama_animasi() == &"santai_normal" and sepeda.kecepatan_ud > 3.0 and sepeda.kecepatan_ud < 6.0, "sesudah selesai kayuh mengikuti tingkat terkini (santai_normal) sementara kecepatan masih turun dari 6,0 (%s u/d)" % sepeda.kecepatan_ud)
	kontrol.keyboard_aktif = OS.has_feature("editor")
	_bersihkan(akar)


## Kidal menukar zona, bukan arti sisi: swipe ke kiri layar tetap sisi seberang, ke kanan layar tetap sisi dekat.
func _test_lempar_kidal() -> void:
	_judul.call("Kidal tidak mengubah arti sisi lempar (AC-5, D-2)")
	for kasus: Array in KASUS_JENDELA:
		var lebar: int = kasus[2]
		var w: float = float(lebar)
		var tag: String = "lebar %d" % lebar
		var akar: JalanUji = await _siapkan(Vector2i(kasus[0], kasus[1]))
		var sepeda: SepedaUji = _anak(akar, "Sepeda") as SepedaUji
		var kontrol: KontrolTouch = _anak(akar, "KontrolTouch") as KontrolTouch
		var hud: HudDev = _anak(akar, "Hud") as HudDev
		var sprite: LoperSprite = _sprite(akar)
		var catatan: Array = _catat_sprite(sprite)
		var tombol: Button = _anak(hud, "TombolKidal") as Button
		kontrol.keyboard_aktif = false
		# Tangan kanan (bawaan): swipe di sisi kanan layar.
		var x_kanan: float = w - 100.0
		_swipe(akar, 1, Vector2(x_kanan, 200), Vector2(x_kanan - 60.0, 200))
		check(sepeda.nama_animasi() == &"lempar_kiri_santai_normal", "%s tangan kanan: swipe ke kiri layar = lempar_kiri (seberang), dapat %s" % [tag, sepeda.nama_animasi()])
		_selesaikan_lempar(sprite)
		_swipe(akar, 1, Vector2(x_kanan - 60.0, 200), Vector2(x_kanan, 200))
		check(sepeda.nama_animasi() == &"lempar_kanan_santai_normal", "%s tangan kanan: swipe ke kanan layar = lempar_kanan (dekat), dapat %s" % [tag, sepeda.nama_animasi()])
		_selesaikan_lempar(sprite)
		# Kidal: zona swipe pindah ke sisi kiri layar (x 20 sampai lebar - 210); arti sisi tidak berubah.
		tombol.button_pressed = true
		await _tree.process_frame
		await _tree.process_frame
		check(kontrol.router.kidal(), "%s: kidal menyala" % tag)
		sprite = _sprite(akar)
		_swipe(akar, 1, Vector2(300, 200), Vector2(240, 200))
		check(sepeda.nama_animasi() == &"lempar_kiri_santai_normal", "%s kidal: swipe ke kiri layar tetap lempar_kiri (seberang), dapat %s" % [tag, sepeda.nama_animasi()])
		_selesaikan_lempar(sprite)
		_swipe(akar, 1, Vector2(240, 200), Vector2(300, 200))
		check(sepeda.nama_animasi() == &"lempar_kanan_santai_normal", "%s kidal: swipe ke kanan layar tetap lempar_kanan (dekat), dapat %s" % [tag, sepeda.nama_animasi()])
		_selesaikan_lempar(sprite)
		# Swipe di sisi kanan layar sekarang adalah zona stick (kidal): tidak melempar.
		var sebelum: int = catatan.size()
		_swipe(akar, 1, Vector2(w - 100.0, 260), Vector2(w - 160.0, 260))
		check(catatan.size() == sebelum and not sepeda.sedang_melempar(), "%s kidal: gerak di sisi kanan layar (zona stick) tidak melempar" % tag)
		_sentuh(1, Vector2(w - 100.0, 260), true)
		_sentuh(1, Vector2(w - 100.0, 260), false)
		tombol.button_pressed = false
		await _tree.process_frame
		kontrol.keyboard_aktif = OS.has_feature("editor")
		_bersihkan(akar)


## batal_semua / pause / kidal berganti: tidak ada lempar yang tercipta dari swipe yang dibatalkan dan tidak ada lempar yang menggantung.
func _test_lempar_batal() -> void:
	_judul.call("Pembatalan: batal_semua, pause, kidal berganti (AC-5)")
	var akar: JalanUji = await _siapkan(Vector2i(2340, 1080))
	var sepeda: SepedaUji = _anak(akar, "Sepeda") as SepedaUji
	var kontrol: KontrolTouch = _anak(akar, "KontrolTouch") as KontrolTouch
	var hud: HudDev = _anak(akar, "Hud") as HudDev
	var router: TouchRouter = kontrol.router
	var sprite: LoperSprite = _sprite(akar)
	var catatan: Array = _catat_sprite(sprite)
	kontrol.keyboard_aktif = false
	# (a) Swipe ditahan lalu app kehilangan fokus: swipe dibatalkan, jari yang diangkat sesudahnya tidak melempar.
	_sentuh(1, Vector2(440, 200), true)
	_geser(1, Vector2(500, 200))
	_tree.root.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not router.swipe_aktif() and router.jumlah_jari_aktif() == 0, "FOCUS_OUT membatalkan swipe yang ditahan")
	_sentuh(1, Vector2(500, 200), false)
	check(router.jumlah_swipe_selesai == 0 and not sepeda.sedang_melempar() and catatan.is_empty(), "jari swipe diangkat sesudah dibatalkan: tidak tercatat dan tidak melempar")
	# (b) Sama untuk PAUSED lewat SceneTree.
	_sentuh(2, Vector2(440, 200), true)
	_geser(2, Vector2(500, 200))
	_tree.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	_sentuh(2, Vector2(500, 200), false)
	check(router.jumlah_swipe_selesai == 0 and not sepeda.sedang_melempar(), "PAUSED membatalkan swipe yang ditahan: tidak melempar")
	# (c) Kidal berganti saat swipe ditahan -> batal_semua -> tidak melempar.
	_sentuh(3, Vector2(440, 200), true)
	_geser(3, Vector2(500, 200))
	kontrol.atur_kidal(true)
	_sentuh(3, Vector2(500, 200), false)
	check(router.jumlah_swipe_selesai == 0 and not sepeda.sedang_melempar(), "kidal berganti saat swipe ditahan: dibatalkan, tidak melempar")
	kontrol.atur_kidal(false)
	check(hud != null and not router.kidal(), "kembali tangan kanan")
	# (d) Lempar yang sedang berjalan ditutup saat app di-background: tanpa sinyal, kembali ke kayuh, tidak menggantung.
	_swipe(akar, 1, Vector2(440, 200), Vector2(500, 200))
	sprite = _sprite(akar)
	for i: int in range(6):
		sprite.maju(DT)
	check(sepeda.sedang_melempar() and sprite.is_processing() == false, "lempar berjalan (6 langkah, belum lepas)")
	_tree.root.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not sepeda.sedang_melempar() and sepeda.nama_animasi() == &"santai_normal" and sprite.is_playing(), "FOCUS_OUT menutup lempar yang berjalan: kembali ke santai_normal yang berputar")
	for i: int in range(40):
		sprite.maju(DT)
	check(catatan.is_empty(), "lempar yang ditutup sebelum lepas tidak memancarkan koran_lepas maupun lempar_selesai")
	# (e) PAUSED sesudah koran lepas: koran_lepas yang sudah terjadi tetap sekali.
	_swipe(akar, 1, Vector2(500, 200), Vector2(440, 200))
	sprite = _sprite(akar)
	for i: int in range(12):
		sprite.maju(DT)
	_tree.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(not sepeda.sedang_melempar() and _jumlah(catatan, "lepas") == 1 and _jumlah(catatan, "selesai") == 0, "PAUSED sesudah lepas: koran_lepas tetap sekali, tidak ada lempar_selesai, tidak menggantung")
	# (f) Sesudah pembatalan, swipe baru melempar normal.
	_swipe(akar, 1, Vector2(440, 200), Vector2(500, 200))
	sprite = _sprite(akar)
	check(sepeda.sedang_melempar() and sepeda.nama_animasi() == &"lempar_kanan_santai_normal", "swipe sesudah pembatalan melempar normal")
	_selesaikan_lempar(sprite)
	check(_jumlah(catatan, "lepas") == 2 and _jumlah(catatan, "selesai") == 1, "total: 2 koran_lepas dan 1 lempar_selesai (satu lempar ditutup)")
	kontrol.keyboard_aktif = OS.has_feature("editor")
	_bersihkan(akar)


# --- QB-003 dan QB-011: langkah waktu dijepit di scene ---

## `JalanUji._process` menjepit `delta` ke `Config.LANGKAH_WAKTU_MAKS_DETIK`, supaya app yang kembali dari background
## (delta beberapa detik) tidak melompat jauh dan jarak trapesium `BikeDrive` tetap sahih (QB-011).
func _test_langkah_waktu_dijepit() -> void:
	_judul.call("Langkah waktu dijepit di JalanUji._process")
	var batas_waktu: float = Config.LANGKAH_WAKTU_MAKS_DETIK
	var batas_jarak: float = batas_waktu * Config.KECEPATAN_NGEBUT_UD
	check(batas_waktu > 0.0 and batas_waktu <= 0.25, "LANGKAH_WAKTU_MAKS_DETIK wajar (0 sampai 0,25 detik), dapat %s" % batas_waktu)
	var akar: JalanUji = await _siapkan(Vector2i(2340, 1080))
	var sepeda: SepedaUji = _anak(akar, "Sepeda") as SepedaUji
	var kontrol: KontrolTouch = _anak(akar, "KontrolTouch") as KontrolTouch
	kontrol.keyboard_aktif = true
	Input.action_press(&"stick_atas")
	var jarak_awal: float = sepeda.jarak_ubin
	akar._process(5.0)
	var tempuh: float = sepeda.jarak_ubin - jarak_awal
	var kecepatan: float = sepeda.kecepatan_ud
	check(tempuh > 0.0 and tempuh <= batas_jarak + 0.000001, "_process(5,0) menempuh paling banyak LANGKAH_WAKTU_MAKS_DETIK x kecepatan ngebut = %s ubin, dapat %s" % [batas_jarak, tempuh])
	check(kecepatan <= Config.KECEPATAN_SANTAI_UD + Config.AKSELERASI_UD2 * batas_waktu + 0.000001, "_process(5,0) menaikkan kecepatan paling banyak satu langkah terjepit (%s u/d), dapat %s" % [Config.KECEPATAN_SANTAI_UD + Config.AKSELERASI_UD2 * batas_waktu, kecepatan])
	akar._process(0.016)
	check(sepeda.jarak_ubin - jarak_awal - tempuh > 0.0 and sepeda.jarak_ubin - jarak_awal - tempuh < 0.016 * Config.KECEPATAN_NGEBUT_UD + 0.000001, "delta normal (0,016 detik) tidak dijepit dan menambah jarak wajar")
	Input.action_release(&"stick_atas")
	kontrol.keyboard_aktif = OS.has_feature("editor")
	_bersihkan(akar)
	# Kontrol: jalur publik `perbarui` tidak menjepit (jepit ada di `_process`), jadi tes di atas memang membedakan.
	akar = await _siapkan(Vector2i(2340, 1080))
	sepeda = _anak(akar, "Sepeda") as SepedaUji
	kontrol = _anak(akar, "KontrolTouch") as KontrolTouch
	kontrol.keyboard_aktif = true
	Input.action_press(&"stick_atas")
	var jarak_lepas: float = sepeda.jarak_ubin
	akar.perbarui(5.0)
	check(sepeda.jarak_ubin - jarak_lepas > batas_jarak * 10.0, "kontrol: perbarui(5,0) tanpa jepit menempuh jauh lebih dari batas (%s ubin), jadi jepit memang tugas _process" % (sepeda.jarak_ubin - jarak_lepas))
	Input.action_release(&"stick_atas")
	kontrol.keyboard_aktif = OS.has_feature("editor")
	_bersihkan(akar)


# --- Dorongan kecepatan di scene hidup (GDD 15) ---

## Posisi sepeda di layar (koordinat viewport game) dihitung dari posisi kamera: sepeda - (kamera - ukuran / 2).
func _layar_sepeda(sepeda: SepedaUji, kamera: Camera2D, ukuran: Vector2) -> Vector2:
	return sepeda.position - (kamera.position - ukuran / 2)


## Dorongan kecepatan: saat ngebut sepeda maju sedikit di bingkai, saat melambat mundur sedikit, kembali halus ke posisi dasar
## saat santai. Hanya kamera yang bergeser: posisi dunia sepeda, sprite, dan HUD tidak berubah. Tes memakai `dt` tetap 1/60
## dan kecepatan sebenarnya (bukan stick) sebagai penentu geseran.
func _test_dorongan_kecepatan_scene() -> void:
	_judul.call("Dorongan kecepatan di scene (GDD 15)")
	var alpha_frame: float = 1.0 - exp(-DT / Config.DORONGAN_RESPON_DETIK)
	# Batas wajar perpindahan sepeda di layar per frame: geseran target paling jauh (maju + mundur, 2:1 sehingga panjang
	# = datar x sqrt(1,25)) dikali bagian yang ditempuh satu langkah penghalusan, ditambah 1,5 px pembulatan kamera.
	var batas_loncat: float = (Config.DORONGAN_MAJU_PX + Config.DORONGAN_MUNDUR_PX) * sqrt(1.25) * alpha_frame + 1.5
	for kasus: Array in KASUS_JENDELA:
		var lebar: int = kasus[2]
		var tag: String = "lebar %d" % lebar
		var akar: JalanUji = await _siapkan(Vector2i(kasus[0], kasus[1]))
		var sepeda: SepedaUji = _anak(akar, "Sepeda") as SepedaUji
		var kontrol: KontrolTouch = _anak(akar, "KontrolTouch") as KontrolTouch
		var kamera: Camera2D = _anak(akar, "Kamera") as Camera2D
		var hud: HudDev = _anak(akar, "Hud") as HudDev
		kontrol.keyboard_aktif = true
		var ukuran: Vector2 = akar.get_viewport_rect().size
		var dasar: Vector2 = Vector2(ukuran.x * Config.KAMERA_SEPEDA_X_PECAHAN, ukuran.y * Config.KAMERA_SEPEDA_Y_PECAHAN)
		var maju: Vector2 = Vector2(Config.DORONGAN_MAJU_PX, -Config.DORONGAN_MAJU_PX / 2)
		var mundur: Vector2 = Vector2(-Config.DORONGAN_MUNDUR_PX, Config.DORONGAN_MUNDUR_PX / 2)
		var rect_tombol: Rect2 = hud.rect_tombol_kidal()
		var rect_panel: Rect2 = hud.rect_panel_kecepatan()
		var keadaan: Dictionary = {"loncat": 0.0, "bulat": true, "harapan": Vector2.ZERO, "cocok": true, "posisi_dunia": true}
		# Santai mantap: geseran nol, sepeda di posisi dasar.
		keadaan = _jalankan_dorongan(akar, sepeda, kamera, ukuran, 60, keadaan)
		var layar: Vector2 = _layar_sepeda(sepeda, kamera, ukuran)
		check(akar.geser_dorongan() == Vector2.ZERO and sepeda.kecepatan_ud == 3.0, "%s santai mantap: geseran dorongan nol dan kecepatan 3,0 u/d" % tag)
		check(layar.distance_to(dasar) <= 1.0, "%s santai mantap: sepeda di posisi dasar (%s) +-1 px, dapat %s" % [tag, dasar, layar])
		await _tree.process_frame
		check(sepeda.get_global_transform_with_canvas().origin.distance_to(layar) < 0.001, "%s: kamera benar-benar menerapkan geseran (transform kanvas sepeda = %s)" % [tag, layar])
		# Ngebut mantap (stick atas keyboard editor): sepeda maju di bingkai, naik ke kanan atas 2:1.
		Input.action_press(&"stick_atas")
		var x_sebelum: float = layar.x
		var naik_monoton: bool = true
		for i: int in range(240):
			keadaan = _jalankan_dorongan(akar, sepeda, kamera, ukuran, 1, keadaan)
			var x_sekarang: float = _layar_sepeda(sepeda, kamera, ukuran).x
			if x_sekarang < x_sebelum:
				naik_monoton = false
			x_sebelum = x_sekarang
		layar = _layar_sepeda(sepeda, kamera, ukuran)
		check(naik_monoton, "%s: santai -> ngebut: sepeda bergeser maju di layar tanpa mundur sesaat (monoton)" % tag)
		check(sepeda.kecepatan_ud == 6.0 and akar.geser_dorongan().distance_to(maju) < 0.01, "%s ngebut mantap: geseran dorongan = %s (galat < 0,01 px), dapat %s" % [tag, maju, akar.geser_dorongan()])
		check(layar.distance_to(dasar + maju) <= 1.0, "%s ngebut mantap: sepeda di dasar + (28, -14) = %s +-1 px, dapat %s (selisih dari dasar %s)" % [tag, dasar + maju, layar, layar - dasar])
		check(layar.x > dasar.x + 20.0 and layar.y < dasar.y - 10.0, "%s ngebut: sepeda lebih ke kanan dan lebih ke atas daripada posisi dasar (naik ke kanan atas)" % tag)
		var rect_tombol_ngebut: Rect2 = hud.rect_tombol_kidal()
		var rect_panel_ngebut: Rect2 = hud.rect_panel_kecepatan()
		check(rect_tombol_ngebut.position == rect_tombol.position and rect_panel_ngebut.position == rect_panel.position, "%s ngebut: HUD tidak ikut bergeser (tombol dan panel di tempat semula)" % tag)
		# Lepas stick: kecepatan turun bertahap (2 u/d2), geseran mengikuti kecepatan SEBENARNYA, bukan stick.
		Input.action_release(&"stick_atas")
		keadaan = _jalankan_dorongan(akar, sepeda, kamera, ukuran, 6, keadaan)
		check(sepeda.kecepatan_ud > 5.0 and sepeda.kecepatan_ud < 6.0, "%s: 0,1 detik setelah stick dilepas kecepatan masih turun dari 6,0 (%s u/d)" % [tag, sepeda.kecepatan_ud])
		check(akar.geser_dorongan().x > 24.0, "%s: geseran mengikuti kecepatan sebenarnya, bukan stick: 0,1 detik setelah stick dilepas masih %s px (stick nol akan menariknya ke sekitar 21)" % [tag, akar.geser_dorongan().x])
		keadaan = _jalankan_dorongan(akar, sepeda, kamera, ukuran, 360, keadaan)
		layar = _layar_sepeda(sepeda, kamera, ukuran)
		check(sepeda.kecepatan_ud == 3.0 and akar.geser_dorongan().length() < 0.01 and layar.distance_to(dasar) <= 1.0, "%s: stick dilepas lama: kembali halus ke posisi dasar %s +-1 px, dapat %s" % [tag, dasar, layar])
		# Melambat mantap (stick bawah): sepeda mundur sedikit.
		Input.action_press(&"stick_bawah")
		keadaan = _jalankan_dorongan(akar, sepeda, kamera, ukuran, 360, keadaan)
		layar = _layar_sepeda(sepeda, kamera, ukuran)
		check(sepeda.kecepatan_ud == 1.5 and akar.geser_dorongan().distance_to(mundur) < 0.01, "%s melambat mantap: geseran dorongan = %s (galat < 0,01 px), dapat %s" % [tag, mundur, akar.geser_dorongan()])
		check(layar.distance_to(dasar + mundur) <= 1.0, "%s melambat mantap: sepeda di dasar - (20, -10) = %s +-1 px, dapat %s (selisih dari dasar %s)" % [tag, dasar + mundur, layar, layar - dasar])
		check(layar.x < dasar.x - 10.0 and layar.y > dasar.y + 5.0, "%s melambat: sepeda lebih ke kiri dan lebih ke bawah daripada posisi dasar (turun ke kiri bawah)" % tag)
		var rect_panel_lambat: Rect2 = hud.rect_panel_kecepatan()
		check(rect_panel_lambat.position == rect_panel.position and hud.rect_tombol_kidal().position == rect_tombol.position, "%s melambat: HUD tidak ikut bergeser" % tag)
		# Peralihan langsung melambat -> ngebut (lompatan target terbesar): masih halus.
		Input.action_release(&"stick_bawah")
		Input.action_press(&"stick_atas")
		var x_lambat: float = layar.x
		var maju_monoton: bool = true
		for i: int in range(360):
			keadaan = _jalankan_dorongan(akar, sepeda, kamera, ukuran, 1, keadaan)
			var x_baru: float = _layar_sepeda(sepeda, kamera, ukuran).x
			if x_baru < x_lambat:
				maju_monoton = false
			x_lambat = x_baru
		Input.action_release(&"stick_atas")
		layar = _layar_sepeda(sepeda, kamera, ukuran)
		check(maju_monoton and layar.distance_to(dasar + maju) <= 1.0, "%s: melambat -> ngebut langsung: bergeser maju monoton dan tiba di dasar + (28, -14), dapat %s" % [tag, layar])
		# Ukuran seluruh urutan: halus, bulat, posisi dunia dan sprite tak berubah, HUD dan lapisan kontrol tidak bergeser.
		check(keadaan["loncat"] <= batas_loncat, "%s: perpindahan sepeda di layar per frame (dt 1/60) paling besar %s px, batas %s px (geseran total x alpha satu langkah + 1,5 px pembulatan)" % [tag, keadaan["loncat"], batas_loncat])
		check(keadaan["loncat"] > 0.5, "%s: ada perpindahan nyata selama transisi (terbesar %s px per frame), tes tidak lolos kosong" % [tag, keadaan["loncat"]])
		check(keadaan["bulat"], "%s: posisi kamera selalu bilangan bulat sepanjang urutan (tidak ada sub-piksel)" % tag)
		check(keadaan["cocok"], "%s: geseran di scene = DoronganKecepatan.haluskan(sebelumnya, geser_target(kecepatan sebenarnya), dt) di setiap frame" % tag)
		check(keadaan["posisi_dunia"], "%s: posisi sepeda = Iso.posisi_gambar(posisi dunia) sepanjang urutan (dorongan tidak mengubah posisi dunia atau sprite)" % tag)
		check(kamera.zoom == Vector2.ONE and kamera.position == kamera.position.round(), "%s: kamera tanpa zoom dan posisinya bulat" % tag)
		check(hud.offset == Vector2.ZERO and hud.scale == Vector2.ONE and hud.rotation == 0.0 and hud.follow_viewport_enabled == false, "%s: CanvasLayer HUD tidak punya offset, skala, atau rotasi (tidak ikut geseran kamera)" % tag)
		var lapisan_kontrol: CanvasLayer = kontrol.get_parent() as CanvasLayer
		check(lapisan_kontrol != null and lapisan_kontrol.offset == Vector2.ZERO and lapisan_kontrol.scale == Vector2.ONE and lapisan_kontrol.rotation == 0.0, "%s: lapisan kontrol sentuh tidak bergeser (zona stick dan swipe tetap)" % tag)
		kontrol.keyboard_aktif = OS.has_feature("editor")
		_bersihkan(akar)


## Menjalankan `jumlah` langkah dt tetap dan mengumpulkan ukuran: perpindahan layar terbesar per frame, kamera bulat,
## kecocokan geseran dengan rumus murni, dan posisi sepeda = proyeksi posisi dunia. Mengembalikan `keadaan` yang diperbarui.
func _jalankan_dorongan(akar: JalanUji, sepeda: SepedaUji, kamera: Camera2D, ukuran: Vector2, jumlah: int, keadaan: Dictionary) -> Dictionary:
	var harapan: Vector2 = keadaan["harapan"]
	var loncat: float = keadaan["loncat"]
	for i: int in range(jumlah):
		var sebelum: Vector2 = _layar_sepeda(sepeda, kamera, ukuran)
		akar.perbarui(DT)
		var sesudah: Vector2 = _layar_sepeda(sepeda, kamera, ukuran)
		loncat = maxf(loncat, sebelum.distance_to(sesudah))
		harapan = DoronganKecepatan.haluskan(harapan, DoronganKecepatan.geser_target(sepeda.kecepatan_ud), DT)
		if akar.geser_dorongan().distance_to(harapan) > 0.0001:
			keadaan["cocok"] = false
		if kamera.position != kamera.position.round():
			keadaan["bulat"] = false
		if sepeda.position != Iso.posisi_gambar(sepeda.posisi_dunia()):
			keadaan["posisi_dunia"] = false
	keadaan["harapan"] = harapan
	keadaan["loncat"] = loncat
	return keadaan


# --- AC-12/15: kidal dan HUD ---

func _test_kidal_dan_hud() -> void:
	_judul.call("Kidal dan HUD sementara")
	for kasus: Array in KASUS_JENDELA:
		var lebar: int = kasus[2]
		var w: float = float(lebar)
		var tag: String = "lebar %d" % lebar
		var akar: JalanUji = await _siapkan(Vector2i(kasus[0], kasus[1]))
		var hud: HudDev = _anak(akar, "Hud") as HudDev
		var kontrol: KontrolTouch = _anak(akar, "KontrolTouch") as KontrolTouch
		var sepeda: SepedaUji = _anak(akar, "Sepeda") as SepedaUji
		var tombol: Button = _anak(hud, "TombolKidal") as Button
		var router: TouchRouter = kontrol.router
		kontrol.keyboard_aktif = false
		# Tombol di strip atas, di luar kedua zona, berlabel kunci terjemahan.
		check(tombol != null and tombol.text == "HUD_KIDAL" and tombol.toggle_mode, "%s: tombol kidal berlabel kunci HUD_KIDAL dan bisa di-toggle" % tag)
		var rect: Rect2 = hud.rect_tombol_kidal()
		check(rect.end.y < float(Config.HUD_STRIP_ATAS_TINGGI_PX) and rect.position.y >= 0.0, "%s: tombol kidal seluruhnya di strip atas (y %s sampai %s, di bawah 48)" % [tag, rect.position.y, rect.end.y])
		var titik_tombol: Array[Vector2] = [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y), rect.get_center()]
		var di_luar: bool = true
		for titik: Vector2 in titik_tombol:
			for mode: bool in [false, true]:
				if TouchZones.zona_di(titik, lebar, mode) != TouchZones.Zona.TIDAK_ADA:
					di_luar = false
		check(di_luar, "%s: tombol kidal (pojok dan pusat) di luar zona stick dan zona swipe, bawaan maupun kidal" % tag)
		check(rect.size.y >= float(Config.HUD_TOMBOL_TINGGI_PX) - 0.5 and rect.size.x >= float(Config.HUD_TOMBOL_LEBAR_PX) - 0.5, "%s: tombol cukup besar untuk jempol (%s px game)" % [tag, rect.size])
		# Sentuhan di tombol tidak diklaim sebagai stick atau swipe.
		_sentuh(0, rect.get_center(), true)
		check(router.jumlah_jari_aktif() == 0, "%s: sentuhan di tombol kidal tidak menjadi stick atau swipe" % tag)
		_sentuh(0, rect.get_center(), false)
		# Panel kecepatan: bawaan di sisi stick (x 210), tidak menimpa zona stick.
		var panel: Rect2 = hud.rect_panel_kecepatan()
		check(absf(panel.position.x - 210.0) <= 1.0 and absf(panel.size.x - 170.0) <= 1.0, "%s: panel kecepatan bawaan di x 210 selebar 170 (DESIGN_SPEC 3.5), dapat %s" % [tag, panel])
		check(absf(panel.end.y - (360.0 - float(Config.HUD_MARGIN_TEPI_PX))) <= 1.0, "%s: panel kecepatan menempel 8 px dari bawah, dapat y akhir %s" % [tag, panel.end.y])
		check(not panel.intersects(TouchZones.rect_stick(lebar, false)), "%s: panel kecepatan tidak menimpa zona stick" % tag)
		# Toggle kidal: zona dan panel berpindah.
		tombol.button_pressed = true
		await _tree.process_frame
		await _tree.process_frame
		check(router.kidal() and hud.get_node("%TombolKidal").button_pressed, "%s: toggle kidal menyalakan kidal di router" % tag)
		var panel_kidal: Rect2 = hud.rect_panel_kecepatan()
		check(absf(panel_kidal.end.x - (w - 210.0)) <= 1.0 and absf(panel_kidal.size.x - 170.0) <= 1.0, "%s kidal: panel kecepatan pindah ke sisi stick kanan (berakhir di lebar-210), dapat %s" % [tag, panel_kidal])
		check(absf(panel_kidal.end.y - panel.end.y) <= 1.0, "%s kidal: panel tetap di bawah" % tag)
		check(not panel_kidal.intersects(TouchZones.rect_stick(lebar, true)), "%s kidal: panel kecepatan tidak menimpa zona stick kidal" % tag)
		check(hud.rect_tombol_kidal() == rect, "%s kidal: tombol kidal tidak berpindah (tetap di strip atas)" % tag)
		# Stick kini di sisi kanan layar, swipe di kiri.
		_sentuh(1, Vector2(w - 100.0, 260.0), true)
		check(router.stick_aktif() and router.asal_stick() == Vector2(w - 100.0, 260.0), "%s kidal: sentuhan di sisi kanan bawah menjadi stick" % tag)
		_geser(1, Vector2(w - 100.0, 225.0))
		_langkah(akar, 90)
		check(sepeda.kecepatan_ud == 6.0 and sepeda.nama_animasi() == &"ngebut_normal", "%s kidal: stick di kanan menggerakkan sepeda ngebut" % tag)
		_sentuh(2, Vector2(100, 260), true)
		check(router.swipe_aktif() and router.jumlah_jari_aktif() == 2, "%s kidal: sentuhan di sisi kiri menjadi swipe, dua jari bersamaan" % tag)
		# Mengganti kidal membatalkan semua jari.
		tombol.button_pressed = false
		await _tree.process_frame
		await _tree.process_frame
		check(not router.kidal() and router.jumlah_jari_aktif() == 0 and router.vektor_stick() == Vector2.ZERO, "%s: kembali ke tangan kanan membatalkan semua jari aktif" % tag)
		check(absf(hud.rect_panel_kecepatan().position.x - 210.0) <= 1.0, "%s: panel kecepatan kembali ke x 210" % tag)
		_langkah(akar, 150)
		check(sepeda.kecepatan_ud == 3.0, "%s: sesudah jari dibatalkan sepeda kembali santai" % tag)
		# Isi HUD: bar dan angka mengikuti kecepatan, teks lewat kunci terjemahan.
		hud.tampilkan_kecepatan(4.5)
		var bar: BarKecepatan = _anak(hud, "BarKecepatan") as BarKecepatan
		var angka: Label = _anak(hud, "LabelAngka") as Label
		var judul: Label = _anak(hud, "LabelKecepatan") as Label
		check(bar != null and is_equal_approx(bar.nilai, 0.75), "%s: bar kecepatan 4,5 u/d = 75%% dari ngebut" % tag)
		check(angka != null and angka.text == hud.tr("HUD_KECEPATAN_ANGKA").format({"v": "4.5"}) and angka.text.contains("4.5"), "%s: angka kecepatan 4.5 lewat kunci HUD_KECEPATAN_ANGKA, dapat '%s'" % [tag, angka.text if angka != null else ""])
		check(angka != null and judul != null and angka.get_theme_font_size(&"font_size") == 10 and judul.get_theme_font_size(&"font_size") == 6, "%s: ukuran font dari tema: angka 10 (HudAngka), label 6 (HudLabel), DESIGN_SPEC 1.2" % tag)
		check(judul != null and judul.text == "HUD_KECEPATAN", "%s: label judul bar berisi kunci HUD_KECEPATAN (diterjemahkan otomatis oleh Label)" % tag)
		_bersihkan(akar)


# --- AC-13: aksi keyboard dan pengaturan proyek untuk input ---

func _test_proyek_dan_keyboard() -> void:
	_judul.call("Aksi input proyek dan keyboard editor")
	var diharapkan: Dictionary = {
		&"stick_atas": [KEY_UP, KEY_W],
		&"stick_bawah": [KEY_DOWN, KEY_S],
		&"stick_ke_seberang": [KEY_LEFT, KEY_A],
		&"stick_ke_dekat": [KEY_RIGHT, KEY_D],
	}
	for aksi: StringName in diharapkan:
		check(InputMap.has_action(aksi), "aksi InputMap '%s' ada di project.godot" % aksi)
		if not InputMap.has_action(aksi):
			continue
		check(not String(aksi).contains("kiri") and not String(aksi).contains("kanan"), "nama aksi '%s' berbahasa Indonesia tanpa kiri/kanan untuk sisi jalan" % aksi)
		var tombol: Array[int] = []
		for peristiwa: InputEvent in InputMap.action_get_events(aksi):
			if peristiwa is InputEventKey:
				tombol.append(int((peristiwa as InputEventKey).physical_keycode))
		var harus: Array = diharapkan[aksi]
		check(tombol.size() == 2 and tombol.has(int(harus[0])) and tombol.has(int(harus[1])), "aksi '%s' dipetakan ke panah dan WASD (physical keycode), dapat %s" % [aksi, tombol])
	check(not bool(ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse", false)), "tidak ada emulasi sentuhan dari mouse di project.godot (input_devices/pointing/emulate_touch_from_mouse)")
	var kontrol: KontrolTouch = KontrolTouch.new()
	check(kontrol.keyboard_aktif == OS.has_feature("editor"), "keyboard aktif hanya bila OS.has_feature(\"editor\") (nonaktif di build ekspor)")
	# QB-006: penjaga statis. Perbandingan di atas selalu benar di runner (biner editor, fitur `editor` = true), jadi tidak
	# menangkap `var keyboard_aktif: bool = true`. Penjaga di bawah memeriksa SUMBER. BATAS: ini tidak membuktikan perilaku
	# build ekspor; bahwa tag fitur "editor" tidak ada di template ekspor adalah perilaku Godot (dokumentasi OS.has_feature)
	# yang tidak bisa dijalankan di runner editor ini. Bukti perilaku APK sungguhan hanya dari menekan tombol di perangkat.
	var skrip_ui: Dictionary = {}
	for berkas: String in _daftar_gd("res://scripts"):
		skrip_ui[berkas] = FileAccess.get_file_as_string(berkas)
	var pelanggaran: Array[String] = _pelanggaran_keyboard_editor(skrip_ui)
	check(pelanggaran.is_empty(), "keyboard editor: sumber menginisialisasi keyboard_aktif dari OS.has_feature(\"editor\"), memagari vektor_keyboard, dan tidak menyalakannya paksa: %s" % "; ".join(pelanggaran))
	var asli: String = FileAccess.get_file_as_string("res://scripts/ui/kontrol_touch.gd")
	check(not _pelanggaran_keyboard_editor({"res://scripts/ui/kontrol_touch.gd": asli.replace("var keyboard_aktif: bool = OS.has_feature(\"editor\")", "var keyboard_aktif: bool = true")}).is_empty(), "contoh buruk: keyboard_aktif = true sejak awal ditolak")
	check(not _pelanggaran_keyboard_editor({"res://scripts/ui/kontrol_touch.gd": asli.replace("OS.has_feature(\"editor\")", "OS.has_feature(\"debug\")")}).is_empty(), "contoh buruk: fitur lain (debug) menggantikan editor ditolak")
	check(not _pelanggaran_keyboard_editor({"res://scripts/ui/kontrol_touch.gd": asli.replace("	if not keyboard_aktif:\n		return Vector2.ZERO\n", "")}).is_empty(), "contoh buruk: vektor_keyboard tanpa pagar keyboard_aktif ditolak")
	check(not _pelanggaran_keyboard_editor({"res://scripts/ui/kontrol_touch.gd": asli, "res://scripts/ui/lain.gd": "func f() -> void:\n\tkontrol.keyboard_aktif = true\n"}).is_empty(), "contoh buruk: skrip lain menyalakan keyboard_aktif paksa ditolak")
	check(_pelanggaran_keyboard_editor({"res://scripts/ui/kontrol_touch.gd": asli, "res://scripts/ui/lain.gd": "# keyboard_aktif = true di komentar\nfunc f() -> void:\n\tpass\n"}).is_empty(), "kontrol positif: keyboard_aktif = true di komentar tidak dihitung")
	check(not _pelanggaran_keyboard_editor({}).is_empty(), "contoh buruk: tanpa kontrol_touch.gd ditolak (penjaga tidak lolos kosong)")
	kontrol.keyboard_aktif = true
	Input.action_press(&"stick_atas")
	check(kontrol.vektor_keyboard() == Vector2(0, 1) and kontrol.vektor_stick() == Vector2(0, 1), "keyboard aktif: tombol atas menghasilkan vektor stick (0, 1)")
	Input.action_press(&"stick_ke_seberang")
	var diagonal: Vector2 = kontrol.vektor_keyboard()
	check(is_equal_approx(diagonal.length(), 1.0) and diagonal.x < 0.0 and diagonal.y > 0.0, "atas + seberang = diagonal panjang 1, dapat %s" % diagonal)
	kontrol.keyboard_aktif = false
	check(kontrol.vektor_keyboard() == Vector2.ZERO and kontrol.vektor_stick() == Vector2.ZERO, "keyboard nonaktif (build ekspor): tombol ditekan tidak menghasilkan vektor")
	kontrol.keyboard_aktif = true
	kontrol.router.tekan(0, Vector2(100, 260), 0.0)
	kontrol.router.geser(0, Vector2(100, 290))
	check(kontrol.vektor_stick().y < 0.0, "sentuhan yang aktif didahulukan dari keyboard")
	Input.action_release(&"stick_atas")
	Input.action_release(&"stick_ke_seberang")
	kontrol.free()


# --- Pembantu node ---

## Pelanggaran penjaga keyboard-hanya-editor pada `skrip` = {jalur: isi} semua skrip di `scripts/` (QB-006).
func _pelanggaran_keyboard_editor(skrip: Dictionary) -> Array[String]:
	var hasil: Array[String] = []
	var jalur_kontrol: String = "res://scripts/ui/kontrol_touch.gd"
	if not skrip.has(jalur_kontrol):
		hasil.append("kontrol_touch.gd tidak ditemukan")
		return hasil
	var re_awal: RegEx = RegEx.create_from_string("^var keyboard_aktif\\s*:\\s*bool\\s*=\\s*OS\\.has_feature\\(\"editor\"\\)\\s*$")
	var ada_awal: bool = false
	for baris: String in str(skrip[jalur_kontrol]).split("\n"):
		if re_awal.search(_tanpa_komentar(baris).strip_edges()) != null:
			ada_awal = true
	if not ada_awal:
		hasil.append("keyboard_aktif harus diinisialisasi `OS.has_feature(\"editor\")`")
	if not str(skrip[jalur_kontrol]).contains("func vektor_keyboard() -> Vector2:\n\tif not keyboard_aktif:\n\t\treturn Vector2.ZERO\n"):
		hasil.append("vektor_keyboard harus diawali pagar `if not keyboard_aktif: return Vector2.ZERO`")
	var re_paksa: RegEx = RegEx.create_from_string("\\bkeyboard_aktif\\s*=\\s*true\\b")
	for jalur: String in skrip:
		for baris: String in str(skrip[jalur]).split("\n"):
			if re_paksa.search(_tanpa_komentar(baris)) != null:
				hasil.append("%s menyalakan keyboard_aktif = true secara paksa" % jalur)
	return hasil


## Baris tanpa komentar `#` di ujungnya; isi teks berkutip dipertahankan.
func _tanpa_komentar(baris: String) -> String:
	var dalam_teks: String = ""
	for i: int in range(baris.length()):
		var c: String = baris[i]
		if dalam_teks != "":
			if c == dalam_teks and baris[i - 1] != "\\":
				dalam_teks = ""
			continue
		if c == "\"" or c == "'":
			dalam_teks = c
		elif c == "#":
			return baris.substr(0, i)
	return baris


func _daftar_gd(folder: String) -> Array[String]:
	var hasil: Array[String] = []
	var dir: DirAccess = DirAccess.open(folder)
	if dir == null:
		return hasil
	for nama: String in dir.get_files():
		if nama.get_extension() == "gd":
			hasil.append(folder.path_join(nama))
	for sub: String in dir.get_directories():
		hasil.append_array(_daftar_gd(folder.path_join(sub)))
	hasil.sort()
	return hasil


## True bila dua warna sama dalam satu langkah kuantisasi 8-bit.
func _hampir(a: Color, b: Color) -> bool:
	var batas: float = 1.5 / 255.0
	return absf(a.r - b.r) <= batas and absf(a.g - b.g) <= batas and absf(a.b - b.b) <= batas and absf(a.a - b.a) <= batas


func _semua_node(akar: Node) -> Array[Node]:
	var hasil: Array[Node] = [akar]
	for anak: Node in akar.get_children():
		hasil.append_array(_semua_node(anak))
	return hasil


func _filter_efektif(node: CanvasItem) -> int:
	var sekarang: CanvasItem = node
	while sekarang != null:
		if sekarang.texture_filter != CanvasItem.TEXTURE_FILTER_PARENT_NODE:
			return sekarang.texture_filter
		sekarang = sekarang.get_parent() as CanvasItem
	return CanvasItem.TEXTURE_FILTER_NEAREST if int(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter")) == Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST else CanvasItem.TEXTURE_FILTER_LINEAR
