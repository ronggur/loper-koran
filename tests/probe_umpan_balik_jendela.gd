extends SceneTree
## Probe umpan balik dan penyetelan run fase1b-umpan-balik di jendela asli, non-headless (AC-9): memuat `scenes/dev/jalan_uji.tscn` (scene utama sejak run fase3a-rute = rute.tscn), menggerakkan
## stick lewat event sentuh sintetis (piksel jendela), memajukan simulasi dan partikel dengan langkah tetap `perbarui(1/60)` dan
## `PancaranPiksel.maju(1/60)` (bukan waktu dinding), lalu menyimpan tangkapan layar: santai (debu tipis, tanpa garis), ngebut
## (garis + debu, dorongan maju penuh), pindah sisi sambil ngebut (run fase1c-perapian, D-5: jejak debu tertinggal di sisi lama karena
## debu di ruang dunia), rem (debu rem), dorongan mundur penuh (rem berhenti), layar jeda, dan kidal. Mencetak jumlah partikel, letak
## sepeda, persegi tombol dan panel, dan kotak teks HUD untuk `tools/cek_blok_piksel.py --kecualikan`.
## Tidak interaktif: keluar sendiri.
##
## Pakai (jendela harus muat di layar monitor; 2340x1080 = viewport 780, 1920x1080 = 640):
##   godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_umpan_balik_jendela.gd -- docs/loop/<RUN_ID>/shots
##   godot --path . --resolution 1920x1080 --position 0,0 --script res://tests/probe_umpan_balik_jendela.gd -- docs/loop/<RUN_ID>/shots
## Berkas: `<lebar>x<tinggi>_<keadaan>.png`. Periksa ketajaman dunia dan partikel:
##   python3 tools/cek_blok_piksel.py 3 --kecualikan <kotak teks HUD> <png>   (kotak dicetak probe)

const FRAME_TUNGGU_LAYOUT: int = 5
const DT: float = 1.0 / 60.0
const TITIK_STICK: Vector2 = Vector2(100, 260)

var _skala: float = 1.0
var _folder: String = ""
var _awalan: String = ""
var _akar: JalanUji
var _sepeda: SepedaUji
var _hud: HudDev
var _layar_jeda: LayarJeda
var _debu: PancaranPiksel
var _garis: PancaranPiksel


func _initialize() -> void:
	var argumen: PackedStringArray = OS.get_cmdline_user_args()
	_folder = argumen[0] if argumen.size() > 0 else ""
	var paket: PackedScene = load("res://scenes/dev/jalan_uji.tscn") as PackedScene
	if paket == null:
		push_error("scene utama tidak bisa dimuat")
		await ProbeKeluar.keluar(self, 1)
		return
	_akar = paket.instantiate() as JalanUji
	root.add_child(_akar)
	await _tunggu(FRAME_TUNGGU_LAYOUT)
	_akar.set_process(false)
	var terlihat: Vector2 = root.get_visible_rect().size
	_skala = float(root.size.x) / terlihat.x
	_awalan = "%dx%d" % [root.size.x, root.size.y]
	_sepeda = _akar.find_child("Sepeda", true, false) as SepedaUji
	_hud = _akar.find_child("Hud", true, false) as HudDev
	_layar_jeda = _akar.find_child("LayarJeda", true, false) as LayarJeda
	_debu = _sepeda.umpan_balik().debu()
	_garis = _sepeda.umpan_balik().garis()
	_debu.set_process(false)
	_garis.set_process(false)
	(_akar.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = false
	print("jendela %s: viewport terlihat %dx%d, skala x%s (driver %s, renderer %s)" % [root.size, int(terlihat.x), int(terlihat.y), _skala, DisplayServer.get_name(), RenderingServer.get_current_rendering_method()])
	print("tombol jeda %s (gambar %s), tombol kidal %s, panel kecepatan %s" % [_hud.rect_tombol_jeda(), (_akar.find_child("TombolJeda", true, false) as TombolJeda).rect_gambar(), _hud.rect_tombol_kidal(), _hud.rect_panel_kecepatan()])
	_cetak_kecualikan("HUD", [_hud.rect_tombol_kidal(), _hud.rect_panel_kecepatan()])

	await _maju(2.0)
	await _foto("santai")
	_sentuh(0, TITIK_STICK, true)
	_geser(0, TITIK_STICK - Vector2(0, Config.STICK_RADIUS_PX))
	await _maju(3.0)
	await _foto("ngebut")
	# Pindah sisi sambil ngebut: stick ke samping 0,25 detik (lateral 3 u/d), lalu kembali ke atas penuh sebelum rem.
	_geser(0, TITIK_STICK + Vector2(Config.STICK_RADIUS_PX, 0))
	await _maju(0.25)
	await _foto("pindah_sisi")
	_geser(0, TITIK_STICK - Vector2(0, Config.STICK_RADIUS_PX))
	await _maju(1.5)
	# Bawah penuh: meluncur 0,25 detik lalu rem; foto saat rem masih bergerak (debu rem).
	_geser(0, TITIK_STICK + Vector2(0, Config.STICK_RADIUS_PX))
	await _maju(0.45)
	await _foto("rem")
	await _maju(3.0)
	await _foto("rem_berhenti")
	_sentuh(0, TITIK_STICK + Vector2(0, Config.STICK_RADIUS_PX), false)
	await _maju(2.0)
	# Layar jeda (dibuka dengan tombol jeda), lalu lanjut.
	(_akar.find_child("TombolJeda", true, false) as TombolJeda).pressed.emit()
	await _tunggu(3)
	var judul: Control = _akar.find_child("JudulJeda", true, false) as Control
	_cetak_kecualikan("layar jeda", [judul.get_global_rect(), _layar_jeda.rect_tombol_lanjut(), _hud.rect_tombol_kidal(), _hud.rect_panel_kecepatan()])
	await _foto("jeda")
	_akar.minta_lanjut()
	# Kidal: tombol kidal, panel pindah ke kanan, stick di kanan bawah; ngebut.
	(_akar.find_child("TombolKidal", true, false) as Button).button_pressed = true
	await _tunggu(3)
	_cetak_kecualikan("kidal", [_hud.rect_tombol_kidal(), _hud.rect_panel_kecepatan()])
	var titik_kidal: Vector2 = Vector2(root.get_visible_rect().size.x - TITIK_STICK.x, TITIK_STICK.y)
	_sentuh(1, titik_kidal, true)
	_geser(1, titik_kidal - Vector2(0, Config.STICK_RADIUS_PX))
	await _maju(3.0)
	await _foto("kidal_ngebut")
	_sentuh(1, titik_kidal, false)
	await ProbeKeluar.keluar(self)


func _cetak_kecualikan(nama: String, kotak: Array) -> void:
	var bagian: PackedStringArray = PackedStringArray()
	for k: Rect2 in kotak:
		bagian.append("--kecualikan %d,%d,%d,%d" % [int(k.position.x * _skala), int(k.position.y * _skala), int(k.end.x * _skala) + 1, int(k.end.y * _skala) + 1])
	print("kecualikan teks %s: %s" % [nama, " ".join(bagian)])


func _tunggu(jumlah: int) -> void:
	for i: int in range(jumlah):
		await process_frame


## Memajukan simulasi dan partikel `detik` dengan langkah `DT`, lalu menunggu dua frame gambar.
func _maju(detik: float) -> void:
	for i: int in range(roundi(detik / DT)):
		if _akar.sedang_jeda():
			print("PERINGATAN: layar jeda terbuka (jendela kehilangan fokus); probe melanjutkan lewat minta_lanjut")
			_akar.minta_lanjut()
		_akar.perbarui(DT)
		_debu.maju(DT)
		_garis.maju(DT)
	await _tunggu(2)


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


func _foto(keadaan: String) -> void:
	await _tunggu(3)
	var layar: Vector2 = _sepeda.get_global_transform_with_canvas().origin
	print("%s: kecepatan %.2f u/d, lateral %.2f ubin, rem %s, debu %d (laju %.1f/d), garis %d (laju %.1f/d), sepeda di layar %s, dorongan %s, jeda %s" % [keadaan, _sepeda.kecepatan_ud, _sepeda.lateral_ubin, _sepeda.rem_aktif(), _debu.jumlah_aktif(), _debu.laju, _garis.jumlah_aktif(), _garis.laju, layar, _akar.geser_dorongan(), _akar.sedang_jeda()])
	if _folder.is_empty():
		return
	var gambar: Image = root.get_texture().get_image()
	var berkas: String = "%s/%s_%s.png" % [_folder, _awalan, keadaan]
	var galat: int = gambar.save_png(berkas)
	print("tangkapan layar %dx%d (%s) ke %s (kode %d)" % [gambar.get_width(), gambar.get_height(), keadaan, berkas, galat])
