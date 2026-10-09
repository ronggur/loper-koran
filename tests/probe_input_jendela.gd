extends SceneTree
## Probe input di jendela asli, non-headless (run 0B): memuat scene utama, menjalankan skenario sentuh sintetis
## lewat `Input.parse_input_event` (posisi dalam piksel jendela, seperti dari perangkat), dan menyimpan tangkapan
## layar tiap tahap. Tidak interaktif: keluar sendiri. Bukti visual untuk LOG, bukan tes lulus/gagal
## (tes terpadunya ada di `tests/tes_input_scene.gd`).
##
## Pakai (jendela harus muat di layar monitor):
##   godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_input_jendela.gd -- docs/loop/<RUN_ID>/shots/iter1
## Argumen setelah `--` = folder keluaran. Berkas: `<lebar>x<tinggi>_<tahap>.png`. Periksa ketajaman dunia dengan
##   python3 tools/cek_blok_piksel.py <skala> --kecualikan <kotak teks HUD> <png>
## Tahap: awal, dua_jari (stick atas penuh + swipe), serong_seberang, serong_dekat, kidal.

const FRAME_TUNGGU_LAYOUT: int = 5
const FRAME_NGEBUT: int = 90
const FRAME_SERONG: int = 6
const FRAME_KIDAL: int = 60

var _skala: float = 1.0
var _folder: String = ""
var _awalan: String = ""


func _initialize() -> void:
	var argumen: PackedStringArray = OS.get_cmdline_user_args()
	_folder = argumen[0] if argumen.size() > 0 else ""
	var utama: String = str(ProjectSettings.get_setting("application/run/main_scene"))
	var paket: PackedScene = load(utama) as PackedScene
	if paket == null:
		push_error("scene utama '%s' tidak bisa dimuat" % utama)
		quit(1)
		return
	var akar: Node = paket.instantiate()
	root.add_child(akar)
	await _tunggu(FRAME_TUNGGU_LAYOUT)
	var terlihat: Vector2 = root.get_visible_rect().size
	_skala = float(root.size.x) / terlihat.x
	_awalan = "%dx%d" % [root.size.x, root.size.y]
	print("jendela %s: viewport terlihat %dx%d, skala x%s (driver %s)" % [root.size, int(terlihat.x), int(terlihat.y), _skala, DisplayServer.get_name()])
	await _foto("awal")
	var hud: HudDev = akar.find_child("Hud", true, false) as HudDev
	if hud != null:
		for kotak: Rect2 in [hud.rect_tombol_kidal(), hud.rect_panel_kecepatan()]:
			print("kecualikan teks HUD: --kecualikan %d,%d,%d,%d" % [int(kotak.position.x * _skala), int(kotak.position.y * _skala), int(kotak.end.x * _skala) + 1, int(kotak.end.y * _skala) + 1])

	# Stick di zona stick (jempol), digeser ke atas penuh; swipe ditahan di zona swipe.
	_sentuh(0, Vector2(100, 260), true)
	_geser(0, Vector2(100, 225))
	await _tunggu(FRAME_NGEBUT)
	_sentuh(1, Vector2(450, 250), true)
	_geser(1, Vector2(540, 190))
	await _tunggu(2)
	await _foto("dua_jari")

	# Ke seberang: sprite serong selama sepeda masih bergeser ke samping.
	_geser(0, Vector2(65, 260))
	await _tunggu(FRAME_SERONG)
	await _foto("serong_seberang")

	# Ke dekat: melintasi jalan, sprite serong ke sisi dekat.
	_geser(0, Vector2(135, 260))
	await _tunggu(FRAME_SERONG)
	await _foto("serong_dekat")
	_sentuh(1, Vector2(540, 190), false)
	_sentuh(0, Vector2(135, 260), false)
	await _tunggu(FRAME_NGEBUT)

	# Opsi kidal lewat tombol HUD: stick pindah ke kanan, swipe ke kiri, panel kecepatan ikut pindah.
	var tombol: Button = akar.find_child("TombolKidal", true, false) as Button
	if tombol != null:
		tombol.button_pressed = true
		await _tunggu(2)
		var lebar: float = terlihat.x
		_sentuh(2, Vector2(lebar - 100.0, 260), true)
		_geser(2, Vector2(lebar - 100.0, 225))
		_sentuh(3, Vector2(300, 250), true)
		_geser(3, Vector2(210, 190))
		await _tunggu(FRAME_KIDAL)
		await _foto("kidal")
		_sentuh(3, Vector2(210, 190), false)
		_sentuh(2, Vector2(lebar - 100.0, 225), false)
	quit()


func _tunggu(jumlah: int) -> void:
	for i: int in range(jumlah):
		await process_frame


## Event sentuh dengan `posisi_viewport` dalam piksel game; dikali skala menjadi piksel jendela.
func _sentuh(index: int, posisi_viewport: Vector2, tekan: bool) -> void:
	var peristiwa: InputEventScreenTouch = InputEventScreenTouch.new()
	peristiwa.index = index
	peristiwa.position = posisi_viewport * _skala
	peristiwa.pressed = tekan
	Input.parse_input_event(peristiwa)
	Input.flush_buffered_events()


func _geser(index: int, posisi_viewport: Vector2) -> void:
	var peristiwa: InputEventScreenDrag = InputEventScreenDrag.new()
	peristiwa.index = index
	peristiwa.position = posisi_viewport * _skala
	Input.parse_input_event(peristiwa)
	Input.flush_buffered_events()


func _foto(tahap: String) -> void:
	await _tunggu(2)
	if _folder.is_empty():
		return
	var gambar: Image = root.get_texture().get_image()
	var berkas: String = "%s/%s_%s.png" % [_folder, _awalan, tahap]
	var galat: int = gambar.save_png(berkas)
	print("tangkapan layar %dx%d (%s) ke %s (kode %d)" % [gambar.get_width(), gambar.get_height(), tahap, berkas, galat])
