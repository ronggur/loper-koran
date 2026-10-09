extends SceneTree
## Probe melambat dan lempar koran di jendela asli, non-headless (run sprite-lempar-melambat, AC-8): memuat scene utama,
## menggerakkan stick dan swipe lewat event sentuh sintetis (piksel jendela, seperti dari perangkat), menyimpan tangkapan layar
## tiap keadaan, dan mencetak posisi alas sprite sebelum, saat, dan sesudah lempar. Tidak interaktif: keluar sendiri.
## Bukti visual untuk LOG, bukan tes lulus/gagal (tes otomatisnya di `tests/tes_sprite.gd` dan `tests/tes_input_scene.gd`).
##
## Pakai (jendela harus muat di layar monitor):
##   godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_lempar_jendela.gd -- docs/loop/<RUN_ID>/shots
## Argumen setelah `--` = folder keluaran. Berkas: `<lebar>x<tinggi>_<keadaan>.png` (layar penuh) dan `lembar_<keadaan>.png`
## (potongan sekitar sprite, tiap frame berdampingan, tetap kelipatan bulat skala). Keadaan: `melambat_<arah>`, `lempar_<sisi>_<tingkat>_f0..f3`,
## `lempar_<sisi>_<tingkat>_sesudah`. Waktu lempar dimajukan probe dengan `maju(1/12)` (satu frame per langkah), jadi tiap
## tangkapan tepat satu frame animasi. Periksa ketajaman dunia:
##   python3 tools/cek_blok_piksel.py 3 --kecualikan <kotak teks HUD> <png>   (kotak dicetak probe)

const FRAME_TUNGGU_LAYOUT: int = 5
## Waktu tunggu keadaan mantap (detik dinding): rampa 6,0 -> 1,5 u/d = 2,25 detik, ditambah penghalusan dorongan.
const DETIK_MANTAP: float = 4.0
const DETIK_SERONG: float = 0.2
const LANGKAH_FRAME_LEMPAR: float = 1.0 / 12.0
## Potongan sekitar sprite (piksel game): lebar, tinggi, dan jarak titik pijak dari pojok potongan (x dan y).
const POTONG_LEBAR: int = 80
const POTONG_TINGGI: int = 90
const POTONG_X: int = 40
const POTONG_Y: int = 62
const TITIK_STICK: Vector2 = Vector2(100, 260)
const TITIK_SWIPE_KANAN: Vector2 = Vector2(500, 200)
const TITIK_SWIPE_KIRI: Vector2 = Vector2(440, 200)

var _skala: float = 1.0
var _folder: String = ""
var _awalan: String = ""
var _sprite: LoperSprite
var _sepeda: SepedaUji
var _akar: Node


func _initialize() -> void:
	var argumen: PackedStringArray = OS.get_cmdline_user_args()
	_folder = argumen[0] if argumen.size() > 0 else ""
	var paket: PackedScene = load(str(ProjectSettings.get_setting("application/run/main_scene"))) as PackedScene
	if paket == null:
		push_error("scene utama tidak bisa dimuat")
		quit(1)
		return
	_akar = paket.instantiate()
	root.add_child(_akar)
	await _tunggu(FRAME_TUNGGU_LAYOUT)
	var terlihat: Vector2 = root.get_visible_rect().size
	_skala = float(root.size.x) / terlihat.x
	_awalan = "%dx%d" % [root.size.x, root.size.y]
	_sepeda = _akar.find_child("Sepeda", true, false) as SepedaUji
	_sprite = _akar.find_child("LoperAgen", true, false) as LoperSprite
	var hud: HudDev = _akar.find_child("Hud", true, false) as HudDev
	print("jendela %s: viewport terlihat %dx%d, skala x%s (driver %s)" % [root.size, int(terlihat.x), int(terlihat.y), _skala, DisplayServer.get_name()])
	for kotak: Rect2 in [hud.rect_tombol_kidal(), hud.rect_panel_kecepatan()]:
		print("kecualikan teks HUD: --kecualikan %d,%d,%d,%d" % [int(kotak.position.x * _skala), int(kotak.position.y * _skala), int(kotak.end.x * _skala) + 1, int(kotak.end.y * _skala) + 1])
	await create_timer(DETIK_MANTAP).timeout

	await _urutan_melambat()
	await _urutan_lempar("santai", false)
	await _urutan_lempar("ngebut", true)
	quit()


## Melambat: stick bawah penuh (lurus), bawah-dekat dan bawah-seberang (serong, sebelum lateral membentur tepi jalan), lalu 90 derajat
## kiri dan kanan. Sudut gerak terbesar yang bisa dicapai stick saat melambat = atan(3,0 / 1,5) = 63,4 derajat (< 67,5), jadi 90 derajat
## tidak pernah muncul dari stick; dua tangkapan terakhir mengatur `steer` langsung dengan permainan dihentikan, hanya untuk melihat gambarnya.
func _urutan_melambat() -> void:
	_sentuh(0, TITIK_STICK, true)
	_geser(0, TITIK_STICK + Vector2(0, Config.STICK_RADIUS_PX))
	await create_timer(DETIK_MANTAP).timeout
	await _foto("melambat_normal")
	_geser(0, TITIK_STICK + Vector2(0.7, 0.7) * Config.STICK_RADIUS_PX)
	await create_timer(DETIK_SERONG).timeout
	await _foto("melambat_serong_kanan")
	_geser(0, TITIK_STICK + Vector2(0, Config.STICK_RADIUS_PX))
	await create_timer(DETIK_MANTAP).timeout
	_geser(0, TITIK_STICK + Vector2(-0.7, 0.7) * Config.STICK_RADIUS_PX)
	await create_timer(DETIK_SERONG).timeout
	await _foto("melambat_serong_kiri")
	_sentuh(0, TITIK_STICK, false)
	await create_timer(DETIK_MANTAP).timeout
	_akar.set_process(false)
	_sprite.speed_level = -1
	for arah: Array in [[-2, "melambat_kiri_90"], [2, "melambat_kanan_90"]]:
		_sprite.steer = arah[0]
		await _foto(arah[1])
	_sprite.steer = 0
	_sprite.speed_level = 0
	_akar.set_process(true)
	await create_timer(1.0).timeout


## Lempar kiri (swipe ke kiri layar, sisi seberang) dan kanan (sisi dekat) di satu tingkat, empat frame berurutan tiap lemparan.
func _urutan_lempar(tingkat: String, stick_atas: bool) -> void:
	if stick_atas:
		_sentuh(0, TITIK_STICK, true)
		_geser(0, TITIK_STICK - Vector2(0, Config.STICK_RADIUS_PX))
	await create_timer(DETIK_MANTAP).timeout
	for sisi: Array in [["kiri", TITIK_SWIPE_KANAN, TITIK_SWIPE_KIRI], ["kanan", TITIK_SWIPE_KIRI, TITIK_SWIPE_KANAN]]:
		var tag: String = "lempar_%s_%s" % [sisi[0], tingkat]
		_ukur("%s sebelum" % tag)
		var lembar: Array[Image] = [_potong()]
		_sentuh(1, sisi[1], true)
		_geser(1, sisi[2])
		_sentuh(1, sisi[2], false)
		_sprite.set_process(false)
		for frame: int in range(4):
			if frame > 0:
				_sprite.maju(LANGKAH_FRAME_LEMPAR)
			await _foto("%s_f%d" % [tag, frame])
			_ukur("%s f%d" % [tag, frame])
			lembar.append(_potong())
		_sprite.maju(LANGKAH_FRAME_LEMPAR)
		await _foto("%s_sesudah" % tag)
		_ukur("%s sesudah" % tag)
		lembar.append(_potong())
		_simpan_lembar(tag, lembar)
		await create_timer(0.5).timeout
	if stick_atas:
		_sentuh(0, TITIK_STICK, false)
		await create_timer(DETIK_MANTAP).timeout


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


## Titik pijak sprite di layar, piksel game (bulat di skala bulat).
func _origin_layar() -> Vector2:
	return _sprite.get_global_transform_with_canvas().origin


## Mencetak animasi, frame, titik pijak di layar (piksel game dan piksel jendela), baris piksel terbawah frame yang tampil, dan
## letak baris itu di layar (titik pijak + baris - 46). Selama kayuh -> lempar -> kayuh letak ini tidak boleh berubah.
func _ukur(keadaan: String) -> void:
	var tekstur: AtlasTexture = _sprite.sprite_frames.get_frame_texture(_sprite.animation, _sprite.frame) as AtlasTexture
	var sel: Image = tekstur.atlas.get_image().get_region(Rect2i(tekstur.region))
	var bawah: int = -1
	for y: int in range(sel.get_height() - 1, -1, -1):
		for x: int in range(sel.get_width()):
			if sel.get_pixel(x, y).a > 0.0:
				bawah = y
				break
		if bawah >= 0:
			break
	var origin: Vector2 = _origin_layar()
	print("ukur %-34s anim=%-32s frame=%d titik_pijak_layar=%s (jendela %s) baris_terbawah_sel=%d letak_alas_layar_y=%s" % [keadaan, _sprite.animation, _sprite.frame, origin, origin * _skala, bawah, origin.y + float(bawah) - 46.0])


## Potongan sekitar sprite dari tangkapan layar saat ini, di piksel jendela, selaras kelipatan bulat skala.
func _potong() -> Image:
	var gambar: Image = root.get_texture().get_image()
	var origin: Vector2 = _origin_layar()
	var x0: int = int(origin.x - float(POTONG_X))
	var y0: int = int(origin.y - float(POTONG_Y))
	return gambar.get_region(Rect2i(Vector2i(x0, y0) * int(_skala), Vector2i(POTONG_LEBAR, POTONG_TINGGI) * int(_skala)))


## Menyusun potongan berdampingan: sebelum, f0..f3, sesudah.
func _simpan_lembar(tag: String, potongan: Array[Image]) -> void:
	if _folder.is_empty() or potongan.is_empty():
		return
	var lebar: int = potongan[0].get_width()
	var lembar: Image = Image.create_empty(lebar * potongan.size(), potongan[0].get_height(), false, potongan[0].get_format())
	for i: int in range(potongan.size()):
		lembar.blit_rect(potongan[i], Rect2i(Vector2i.ZERO, potongan[i].get_size()), Vector2i(i * lebar, 0))
	var berkas: String = "%s/lembar_%s.png" % [_folder, tag]
	print("lembar %s: %d potongan, kode %d" % [berkas, potongan.size(), lembar.save_png(berkas)])


func _foto(keadaan: String) -> void:
	await _tunggu(3)
	if _folder.is_empty():
		return
	var gambar: Image = root.get_texture().get_image()
	var berkas: String = "%s/%s_%s.png" % [_folder, _awalan, keadaan]
	var galat: int = gambar.save_png(berkas)
	print("tangkapan layar %dx%d (%s): anim=%s frame=%d ke %s (kode %d)" % [gambar.get_width(), gambar.get_height(), keadaan, _sprite.animation, _sprite.frame, berkas, galat])
