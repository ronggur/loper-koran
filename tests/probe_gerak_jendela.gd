extends SceneTree
## Probe gerak Fase 1 di jendela asli, non-headless (run fase1a-gerak, AC-13): memuat scene utama, menggerakkan stick lewat event
## sentuh sintetis (piksel jendela, seperti dari perangkat), lalu memajukan simulasi dengan `JalanUji.perbarui(1/60)` (bukan waktu
## dinding, jadi keadaannya pasti) dan menyimpan tangkapan layar: stamina penuh, rendah (< 30), lelah, meluncur, melambat, rem
## bergerak dan berhenti (cincin rem `WARN`), lalu kayuh lagi. Di tiap pergantian pose (kayuh -> meluncur -> melambat -> rem ->
## kayuh) mencetak titik pijak dan baris piksel terbawah sprite tepat sebelum dan sesudah berganti, dan menyimpan lembar potongan
## berdampingan. Tidak interaktif: keluar sendiri. Bukti visual untuk LOG; tes otomatisnya di `tests/tes_gerak*.gd`.
##
## Pakai (jendela harus muat di layar monitor):
##   godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_gerak_jendela.gd -- docs/loop/<RUN_ID>/shots
## Berkas: `<lebar>x<tinggi>_<keadaan>.png` dan `lembar_<pergantian>.png`. Periksa ketajaman dunia:
##   python3 tools/cek_blok_piksel.py 3 --kecualikan <kotak teks HUD> <png>   (kotak dicetak probe)

const FRAME_TUNGGU_LAYOUT: int = 5
const DT: float = 1.0 / 60.0
## Potongan sekitar sprite (piksel game): lebar, tinggi, dan jarak titik pijak dari pojok potongan (x dan y).
const POTONG_LEBAR: int = 80
const POTONG_TINGGI: int = 90
const POTONG_X: int = 40
const POTONG_Y: int = 62
const TITIK_STICK: Vector2 = Vector2(100, 260)
## Geseran jari ke bawah tanpa rem (85% jangkauan, komponen bawah 0,82) dan bawah penuh (rem).
const BAWAH_TANPA_REM: float = 0.85

var _skala: float = 1.0
var _folder: String = ""
var _awalan: String = ""
var _akar: JalanUji
var _sepeda: SepedaUji
var _sprite: LoperSprite
var _kontrol: KontrolTouch


func _initialize() -> void:
	var argumen: PackedStringArray = OS.get_cmdline_user_args()
	_folder = argumen[0] if argumen.size() > 0 else ""
	var paket: PackedScene = load(str(ProjectSettings.get_setting("application/run/main_scene"))) as PackedScene
	if paket == null:
		push_error("scene utama tidak bisa dimuat")
		quit(1)
		return
	_akar = paket.instantiate() as JalanUji
	root.add_child(_akar)
	await _tunggu(FRAME_TUNGGU_LAYOUT)
	_akar.set_process(false)
	var terlihat: Vector2 = root.get_visible_rect().size
	_skala = float(root.size.x) / terlihat.x
	_awalan = "%dx%d" % [root.size.x, root.size.y]
	_sepeda = _akar.find_child("Sepeda", true, false) as SepedaUji
	_sprite = _akar.find_child("LoperAgen", true, false) as LoperSprite
	_kontrol = _akar.find_child("KontrolTouch", true, false) as KontrolTouch
	_kontrol.keyboard_aktif = false
	var hud: HudDev = _akar.find_child("Hud", true, false) as HudDev
	print("jendela %s: viewport terlihat %dx%d, skala x%s (driver %s)" % [root.size, int(terlihat.x), int(terlihat.y), _skala, DisplayServer.get_name()])
	for kotak: Rect2 in [hud.rect_tombol_kidal(), hud.rect_panel_kecepatan()]:
		print("kecualikan teks HUD: --kecualikan %d,%d,%d,%d" % [int(kotak.position.x * _skala), int(kotak.position.y * _skala), int(kotak.end.x * _skala) + 1, int(kotak.end.y * _skala) + 1])

	await _maju(2.0)
	await _foto("stamina_penuh")
	# Ngebut sampai stamina di bawah 30, lalu sampai lelah.
	_sentuh(0, TITIK_STICK, true)
	_geser(0, TITIK_STICK - Vector2(0, Config.STICK_RADIUS_PX))
	await _maju_sampai(func() -> bool: return _sepeda.stamina() < 20.0, 20.0)
	await _foto("stamina_rendah")
	await _maju_sampai(func() -> bool: return _sepeda.lelah(), 20.0)
	await _maju(1.0)
	await _foto("stamina_lelah")
	# Stick ke bawah 85%: kayuh (cepat, lelah) -> meluncur -> melambat.
	_geser(0, TITIK_STICK + Vector2(0, Config.STICK_RADIUS_PX * BAWAH_TANPA_REM))
	await _pergantian("kayuh_ke_meluncur")
	await _maju(0.3)
	await _foto("meluncur")
	await _pergantian("meluncur_ke_melambat")
	await _maju(0.5)
	await _foto("melambat")
	# Kayuh lagi ke ngebut sebentar (stamina sudah pulih), lalu bawah penuh: meluncur -> rem bergerak -> rem berhenti.
	_geser(0, TITIK_STICK - Vector2(0, Config.STICK_RADIUS_PX))
	await _maju(2.0)
	_geser(0, TITIK_STICK + Vector2(0, Config.STICK_RADIUS_PX))
	await _pergantian("kayuh_ke_meluncur_rem")
	await _pergantian("meluncur_ke_rem")
	await _maju(0.2)
	await _foto("rem_bergerak")
	await _maju(2.0)
	await _foto("rem_berhenti")
	# Lepas: rem padam, kayuh santai lagi dari 0.
	_sentuh(0, TITIK_STICK + Vector2(0, Config.STICK_RADIUS_PX), false)
	await _pergantian("rem_ke_kayuh")
	await _maju(0.5)
	await _foto("kayuh_lagi")
	quit()


func _tunggu(jumlah: int) -> void:
	for i: int in range(jumlah):
		await process_frame


## Memajukan simulasi `detik` dengan langkah `DT`, lalu menunggu dua frame gambar.
func _maju(detik: float) -> void:
	for i: int in range(roundi(detik / DT)):
		_langkah()
	await _tunggu(2)


func _maju_sampai(syarat: Callable, maks_detik: float) -> void:
	var langkah: int = 0
	while not syarat.call() and float(langkah) * DT < maks_detik:
		_langkah()
		langkah += 1
	await _tunggu(2)


## Satu langkah simulasi. Bila jendela kehilangan fokus (desktop), layar jeda terbuka; probe mencatatnya lalu menekan Lanjut
## (sejak run fase1b-umpan-balik FOCUS_IN tidak melanjutkan).
func _langkah() -> void:
	if _akar.sedang_jeda():
		print("PERINGATAN: layar jeda terbuka (jendela kehilangan fokus); probe melanjutkan lewat minta_lanjut")
		_akar.minta_lanjut()
	_akar.perbarui(DT)


## Memajukan sampai animasi berganti dari pose saat ini; mencetak ukuran tepat sebelum dan sesudah, menyimpan lembar potongan
## (langkah tepat sebelum berganti, langkah pertama sesudah, dan dua langkah sesudahnya).
func _pergantian(tag: String) -> void:
	var awal: StringName = _sprite.animation
	await _tunggu(2)
	_ukur("%s sebelum" % tag)
	var sebelum: Image = _potong()
	var langkah: int = 0
	while langkah < 600:
		_langkah()
		langkah += 1
		await _tunggu(2)
		if _sprite.animation != awal:
			break
		_ukur("%s sebelum" % tag)
		sebelum = _potong()
	_ukur("%s sesudah" % tag)
	var lembar: Array[Image] = [sebelum, _potong()]
	_langkah()
	_langkah()
	await _tunggu(2)
	_ukur("%s sesudah+2" % tag)
	lembar.append(_potong())
	_simpan_lembar(tag, lembar)
	print("pergantian %s: %s -> %s sesudah %d langkah" % [tag, awal, _sprite.animation, langkah])


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


func _origin_layar() -> Vector2:
	return _sprite.get_global_transform_with_canvas().origin


## Mencetak animasi, frame, titik pijak di layar (piksel game), baris piksel terbawah frame yang tampil, dan letak alas di layar
## (titik pijak + baris - 46). Saat pose berganti letak ini hanya boleh bergeser sebesar gerak kamera satu langkah (dorongan).
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
	print("ukur %-30s anim=%-22s frame=%d kecepatan=%.3f titik_pijak_layar=%s baris_terbawah_sel=%d letak_alas_layar_y=%s" % [keadaan, _sprite.animation, _sprite.frame, _sepeda.kecepatan_ud, origin, bawah, origin.y + float(bawah) - 46.0])


func _potong() -> Image:
	var gambar: Image = root.get_texture().get_image()
	var origin: Vector2 = _origin_layar()
	var x0: int = int(origin.x - float(POTONG_X))
	var y0: int = int(origin.y - float(POTONG_Y))
	return gambar.get_region(Rect2i(Vector2i(x0, y0) * int(_skala), Vector2i(POTONG_LEBAR, POTONG_TINGGI) * int(_skala)))


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
	print("tangkapan layar %s: anim=%s frame=%d kecepatan=%.2f stamina=%.1f lelah=%s rem=%s busur_rem=%s ke %s (kode %d)" % [keadaan, _sprite.animation, _sprite.frame, _sepeda.kecepatan_ud, _sepeda.stamina(), _sepeda.lelah(), _sepeda.rem_aktif(), _kontrol.busur_rem_tampil(), berkas, galat])
