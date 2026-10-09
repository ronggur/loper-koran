extends SceneTree
## Probe dorongan kecepatan di jendela asli, non-headless (GDD 15): memuat scene utama, menahan stick lewat event sentuh
## sintetis (piksel jendela, seperti dari perangkat) sampai kecepatan mantap di tiga keadaan, mencetak posisi sepeda di layar
## (koordinat viewport game), dan menyimpan tangkapan layar tiap keadaan. Tidak interaktif: keluar sendiri.
##
## Pakai (jendela harus muat di layar monitor):
##   godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_dorongan_jendela.gd -- docs/loop/<RUN_ID>/shots/dorongan
## Berkas: `<lebar>x<tinggi>_<keadaan>.png`, keadaan: melambat, santai, ngebut, lepas (kembali ke dasar). Periksa ketajaman dunia
##   python3 tools/cek_blok_piksel.py 3 --kecualikan <kotak teks HUD> <png>
## (kotak teks HUD dicetak probe). Bukti visual untuk LOG; tes terpadunya di `tests/tes_input_scene.gd`.

const FRAME_TUNGGU_LAYOUT: int = 5
## Waktu tunggu tiap keadaan (detik dinding): cukup untuk rampa kecepatan terlama (6,0 -> 1,5 u/d = 2,25 detik) dan
## penghalusan geseran (konstanta 0,35 detik). Memakai waktu, bukan jumlah frame: frame jendela bisa jauh lebih cepat dari 60 fps.
const DETIK_MANTAP: float = 7.0

var _skala: float = 1.0
var _folder: String = ""
var _awalan: String = ""
var _dasar: Vector2 = Vector2.ZERO


func _initialize() -> void:
	var argumen: PackedStringArray = OS.get_cmdline_user_args()
	_folder = argumen[0] if argumen.size() > 0 else ""
	var paket: PackedScene = load(str(ProjectSettings.get_setting("application/run/main_scene"))) as PackedScene
	if paket == null:
		push_error("scene utama tidak bisa dimuat")
		quit(1)
		return
	var akar: Node = paket.instantiate()
	root.add_child(akar)
	await _tunggu(FRAME_TUNGGU_LAYOUT)
	var terlihat: Vector2 = root.get_visible_rect().size
	_skala = float(root.size.x) / terlihat.x
	_awalan = "%dx%d" % [root.size.x, root.size.y]
	_dasar = Vector2(terlihat.x * Config.KAMERA_SEPEDA_X_PECAHAN, terlihat.y * Config.KAMERA_SEPEDA_Y_PECAHAN)
	var sepeda: SepedaUji = akar.find_child("Sepeda", true, false) as SepedaUji
	var hud: HudDev = akar.find_child("Hud", true, false) as HudDev
	print("jendela %s: viewport terlihat %dx%d, skala x%s, posisi dasar sepeda %s (driver %s)" % [root.size, int(terlihat.x), int(terlihat.y), _skala, _dasar, DisplayServer.get_name()])
	for kotak: Rect2 in [hud.rect_tombol_kidal(), hud.rect_panel_kecepatan()]:
		print("kecualikan teks HUD: --kecualikan %d,%d,%d,%d" % [int(kotak.position.x * _skala), int(kotak.position.y * _skala), int(kotak.end.x * _skala) + 1, int(kotak.end.y * _skala) + 1])

	await create_timer(DETIK_MANTAP).timeout
	await _foto("santai", sepeda)
	# Ngebut: stick di zona stick digeser ke atas penuh.
	_sentuh(0, Vector2(100, 260), true)
	_geser(0, Vector2(100, 225))
	await create_timer(DETIK_MANTAP).timeout
	await _foto("ngebut", sepeda)
	# Melambat: stick digeser ke bawah penuh.
	_geser(0, Vector2(100, 295))
	await create_timer(DETIK_MANTAP).timeout
	await _foto("melambat", sepeda)
	# Stick dilepas: kembali ke dasar.
	_sentuh(0, Vector2(100, 295), false)
	await create_timer(DETIK_MANTAP).timeout
	await _foto("lepas", sepeda)
	quit()


func _tunggu(jumlah: int) -> void:
	for i: int in range(jumlah):
		await process_frame


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


func _foto(keadaan: String, sepeda: SepedaUji) -> void:
	await _tunggu(2)
	var layar: Vector2 = sepeda.get_global_transform_with_canvas().origin
	print("%s: kecepatan %.2f u/d, sepeda di layar %s, selisih dari dasar %s" % [keadaan, sepeda.kecepatan_ud, layar, layar - _dasar])
	if _folder.is_empty():
		return
	var gambar: Image = root.get_texture().get_image()
	var berkas: String = "%s/%s_%s.png" % [_folder, _awalan, keadaan]
	var galat: int = gambar.save_png(berkas)
	print("tangkapan layar %dx%d (%s) ke %s (kode %d)" % [gambar.get_width(), gambar.get_height(), keadaan, berkas, galat])
