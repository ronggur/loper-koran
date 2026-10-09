class_name KontrolTouch
extends Node2D
## Node input sentuh: menerjemahkan `InputEvent` ke `TouchRouter` dan menggambar umpan balik (AC-12, AC-14).
##
## Tipis (rule `gdscript`): semua aturan stick dan swipe ada di `TouchRouter`, `StickMap`, `TouchZones`.
## Dipasang di `CanvasLayer`, jadi koordinat gambar sama dengan koordinat event. Event sentuh dibaca di `_input`
## dan HASILNYA dalam ruang viewport game (640..800 x 360), bukan piksel jendela: Godot menerapkan transformasi
## stretch (`canvas_items`, skala bulat) pada event sebelum `_input`, dan transformasi kamera tidak ikut
## (lihat LOG run 0B+0C). Event tidak ditandai tertangani, jadi tombol HUD di strip atas tetap menerimanya.
## Tidak ada emulasi sentuhan dari mouse di proyek ini; keyboard hanya untuk tes di editor.
##
## Umpan balik (DESIGN_SPEC 3.7, warna dari `Palette`): stick digambar di titik sentuh (cincin radius 35 dengan isi
## `TEXT` 14% dan garis `TEXT` 70%, knob radius 15 `ACCENT`), garis putus dari titik awal swipe ke jari.
## Semuanya dirasterisasi per piksel game (`PikselLingkaran`) supaya tepinya tajam di skala bulat.

## Pelacak jari. Instance `RefCounted` murni.
var router: TouchRouter = TouchRouter.new()
## Keyboard (panah dan WASD) hanya aktif di build editor, tidak di build ekspor.
var keyboard_aktif: bool = OS.has_feature("editor")

var _tekstur_isi: ImageTexture
var _tekstur_cincin: ImageTexture
var _tekstur_knob: ImageTexture
var _setengah_cincin: Vector2 = Vector2.ZERO
var _setengah_knob: Vector2 = Vector2.ZERO


func _ready() -> void:
	var radius_cincin: int = int(Config.STICK_RADIUS_PX)
	_tekstur_isi = _buat_tekstur(radius_cincin, 0, Color(Palette.TEXT, Config.STICK_ISI_ALPHA))
	_tekstur_cincin = _buat_tekstur(radius_cincin, Config.STICK_CINCIN_TEBAL_PX, Color(Palette.TEXT, Config.STICK_GARIS_ALPHA))
	_tekstur_knob = _buat_tekstur(Config.STICK_KNOB_RADIUS_PX, 0, Palette.ACCENT)
	_setengah_cincin = Vector2.ONE * radius_cincin
	_setengah_knob = Vector2.ONE * Config.STICK_KNOB_RADIUS_PX


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var sentuh: InputEventScreenTouch = event
		_sinkronkan_lebar()
		if sentuh.canceled:
			router.batal(sentuh.index)
		elif sentuh.pressed:
			router.tekan(sentuh.index, sentuh.position, _waktu_detik())
		else:
			router.lepas(sentuh.index, sentuh.position, _waktu_detik())
		queue_redraw()
	elif event is InputEventScreenDrag:
		var geser: InputEventScreenDrag = event
		router.geser(geser.index, geser.position)
		queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		router.batal_semua()
		queue_redraw()


func _draw() -> void:
	if router.stick_aktif():
		var asal: Vector2 = router.asal_stick().round()
		draw_texture(_tekstur_isi, asal - _setengah_cincin)
		draw_texture(_tekstur_cincin, asal - _setengah_cincin)
		var knob: Vector2 = (router.asal_stick() + router.geser_stick_terjepit()).round()
		draw_texture(_tekstur_knob, knob - _setengah_knob)
	if router.swipe_aktif():
		_gambar_garis_putus(router.awal_swipe(), router.posisi_swipe())


## Vektor stick yang dipakai gerak: sentuhan bila stick aktif, kalau tidak keyboard (hanya di editor).
func vektor_stick() -> Vector2:
	if router.stick_aktif():
		return router.vektor_stick()
	return vektor_keyboard()


## Vektor dari panah/WASD lewat fungsi murni `StickMap.dari_tombol`. Nol di build ekspor.
func vektor_keyboard() -> Vector2:
	if not keyboard_aktif:
		return Vector2.ZERO
	return StickMap.dari_tombol(
		Input.is_action_pressed(&"stick_ke_seberang"),
		Input.is_action_pressed(&"stick_ke_dekat"),
		Input.is_action_pressed(&"stick_atas"),
		Input.is_action_pressed(&"stick_bawah"))


## Opsi kidal (runtime saja, D-5): menukar zona dan membatalkan jari aktif.
func atur_kidal(nilai: bool) -> void:
	router.atur_kidal(nilai)
	queue_redraw()


func _sinkronkan_lebar() -> void:
	router.lebar_viewport = int(get_viewport_rect().size.x)


func _waktu_detik() -> float:
	return float(Time.get_ticks_msec()) / Config.WAKTU_MS_PER_DETIK


## Garis putus: titik `SWIPE_TITIK_UKURAN_PX` persegi tiap `SWIPE_TITIK_JARAK_PX` dari `dari` ke `ke`.
func _gambar_garis_putus(dari: Vector2, ke: Vector2) -> void:
	var panjang: float = dari.distance_to(ke)
	var arah: Vector2 = dari.direction_to(ke)
	var ukuran: Vector2 = Vector2.ONE * Config.SWIPE_TITIK_UKURAN_PX
	var jarak: float = 0.0
	while jarak <= panjang:
		draw_rect(Rect2((dari + arah * jarak).round(), ukuran), Palette.TEXT)
		jarak += float(Config.SWIPE_TITIK_JARAK_PX)


## Tekstur piksel: cakram penuh (tebal 0) atau cincin selebar `tebal` piksel, berjari-jari `radius`.
func _buat_tekstur(radius: int, tebal: int, warna: Color) -> ImageTexture:
	var sisi: int = PikselLingkaran.sisi(radius)
	var gambar: Image = Image.create_empty(sisi, sisi, false, Image.FORMAT_RGBA8)
	for y: int in range(sisi):
		for x: int in range(sisi):
			var dx: int = x - radius
			var dy: int = y - radius
			var isi: bool = PikselLingkaran.di_dalam(dx, dy, radius) if tebal == 0 else PikselLingkaran.di_cincin(dx, dy, radius, tebal)
			if isi:
				gambar.set_pixel(x, y, warna)
	return ImageTexture.create_from_image(gambar)
