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
## `TEXT` 14% dan garis `TEXT` 70%, knob radius 15 `ACCENT`). Garis putus lama dari titik awal swipe ke jari dihapus di run
## fase2a-lemparan (D-5): penggantinya garis bidik lintasan koran di ruang dunia (`GarisBidik`, diisi `JalanUji`). Saat rem aktif
## (`atur_rem`, diisi `JalanUji` dari `BikeMotion`) busur bawah cincin digambar `WARN` (seperempat lingkaran bawah, bentuk
## yang berbeda dari cincin biasa), hilang saat rem padam.
## Semuanya dirasterisasi per piksel game (`PikselLingkaran`) supaya tepinya tajam di skala bulat.
## Tanda "tidak ada sasaran" mode bantu (D-6 run fase2b-bantu-audio): cincin kecil `PolaPiksel.TANDA_TANPA_SASARAN` (`TEXT_2` bergaris
## `OUTLINE`) berpusat di titik tap selama `Config.BANTU_TANDA_LAMA_DETIK`; dinyalakan `JalanUji` (`tampilkan_tanda`) dan dimajukan dengan
## `dt` efektif (`langkah_tanda`, membeku saat jeda). Perintah gambarnya (`perintah_tanda`) dites headless.

## Pelacak jari. Instance `RefCounted` murni.
var router: TouchRouter = TouchRouter.new()
## Keyboard (panah dan WASD) hanya aktif di build editor, tidak di build ekspor.
var keyboard_aktif: bool = OS.has_feature("editor")

var _tekstur_isi: ImageTexture
var _tekstur_cincin: ImageTexture
var _tekstur_knob: ImageTexture
var _tekstur_busur_rem: ImageTexture
var _rem_aktif: bool = false
var _setengah_cincin: Vector2 = Vector2.ZERO
var _setengah_knob: Vector2 = Vector2.ZERO
var _tanda_posisi: Vector2 = Vector2.ZERO
var _tanda_sisa_detik: float = 0.0


func _ready() -> void:
	var radius_cincin: int = int(Config.STICK_RADIUS_PX)
	_tekstur_isi = _buat_tekstur(radius_cincin, 0, Color(Palette.TEXT, Config.STICK_ISI_ALPHA))
	_tekstur_cincin = _buat_tekstur(radius_cincin, Config.STICK_CINCIN_TEBAL_PX, Color(Palette.TEXT, Config.STICK_GARIS_ALPHA))
	_tekstur_knob = _buat_tekstur(Config.STICK_KNOB_RADIUS_PX, 0, Palette.ACCENT)
	_tekstur_busur_rem = _buat_tekstur_busur(radius_cincin, Config.STICK_CINCIN_TEBAL_PX, Palette.WARN)
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
		lepas_semua()


## Melepas semua jari tanpa mencatat swipe (jeda dari tombol, background, atau back; `JalanUji`). Selama jeda node ini tidak
## menerima sentuhan (`SceneTree.paused`), jadi stick harus disentuh ulang sesudah lanjut.
func lepas_semua() -> void:
	router.batal_semua()
	queue_redraw()


func _draw() -> void:
	if router.stick_aktif():
		var asal: Vector2 = router.asal_stick().round()
		draw_texture(_tekstur_isi, asal - _setengah_cincin)
		draw_texture(_tekstur_cincin, asal - _setengah_cincin)
		var knob: Vector2 = (router.asal_stick() + router.geser_stick_terjepit()).round()
		draw_texture(_tekstur_knob, knob - _setengah_knob)
		# Busur rem digambar di atas knob: saat rem knob selalu di bawah cincin dan akan menutupi bagian tengah busur.
		if _rem_aktif:
			draw_texture(_tekstur_busur_rem, asal - _setengah_cincin)
	GambarPiksel.gambar(self, perintah_tanda())


## Menampilkan tanda "tidak ada sasaran" berpusat di `posisi` (koordinat viewport game) selama `Config.BANTU_TANDA_LAMA_DETIK` (D-6).
func tampilkan_tanda(posisi: Vector2) -> void:
	_tanda_posisi = posisi
	_tanda_sisa_detik = Config.BANTU_TANDA_LAMA_DETIK
	queue_redraw()


## Memajukan waktu tanda `dt` detik (`dt` efektif; 0 saat jeda = membeku). Menggambar ulang saat tanda hilang.
func langkah_tanda(dt: float) -> void:
	var tampil_sebelum: bool = tanda_tampil()
	_tanda_sisa_detik = BantuLempar.sisa_tanda(_tanda_sisa_detik, dt)
	if tampil_sebelum and not tanda_tampil():
		queue_redraw()


## True selama tanda "tidak ada sasaran" tampil.
func tanda_tampil() -> bool:
	return BantuLempar.tanda_tampil(_tanda_sisa_detik)


## Titik tap tempat tanda terakhir dinyalakan, koordinat viewport game.
func posisi_tanda() -> Vector2:
	return _tanda_posisi


## Perintah gambar (`GambarPiksel`) tanda "tidak ada sasaran": pola berpusat di titik tap (pojok = titik - setengah ukuran, dibulatkan),
## `w` = `TEXT_2`. Kosong bila tanda tidak tampil.
func perintah_tanda() -> Array:
	if not tanda_tampil():
		return []
	var ukuran: Vector2i = PolaPiksel.ukuran(PolaPiksel.TANDA_TANPA_SASARAN)
	var pojok: Vector2 = _tanda_posisi.round() - Vector2(floori(float(ukuran.x) / 2), floori(float(ukuran.y) / 2))
	return GambarPiksel.perintah_pola(PolaPiksel.TANDA_TANPA_SASARAN, pojok, Palette.TEXT_2)


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


## Status rem untuk penanda di cincin stick. Menggambar ulang hanya bila berubah.
func atur_rem(aktif: bool) -> void:
	if aktif != _rem_aktif:
		_rem_aktif = aktif
		queue_redraw()


## True bila penanda rem (busur bawah `WARN`) sedang digambar: rem aktif dan stick tampil.
func busur_rem_tampil() -> bool:
	return _rem_aktif and router.stick_aktif()


## Opsi kidal (runtime saja, D-5): menukar zona dan membatalkan jari aktif.
func atur_kidal(nilai: bool) -> void:
	router.atur_kidal(nilai)
	queue_redraw()


func _sinkronkan_lebar() -> void:
	router.lebar_viewport = int(get_viewport_rect().size.x)


func _waktu_detik() -> float:
	return float(Time.get_ticks_msec()) / Config.WAKTU_MS_PER_DETIK


## Tekstur piksel busur bawah cincin (`PikselLingkaran.di_busur_bawah`), sama ukuran dengan tekstur cincin.
func _buat_tekstur_busur(radius: int, tebal: int, warna: Color) -> ImageTexture:
	var sisi: int = PikselLingkaran.sisi(radius)
	var gambar: Image = Image.create_empty(sisi, sisi, false, Image.FORMAT_RGBA8)
	for y: int in range(sisi):
		for x: int in range(sisi):
			if PikselLingkaran.di_busur_bawah(x - radius, y - radius, radius, tebal):
				gambar.set_pixel(x, y, warna)
	return ImageTexture.create_from_image(gambar)


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
