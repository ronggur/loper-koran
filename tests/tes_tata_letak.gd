class_name TesTataLetak
extends RefCounted
## Tes tata letak paket penyetelan run fase1b-umpan-balik (AC-6, D-7): sepeda di `KAMERA_SEPEDA_Y_PECAHAN`, dorongan maju dan mundur
## penuh, panel kecepatan dengan teks HUD 8 px, tombol kidal dan tombol jeda 42 px, di viewport 640, 780, dan 800, tangan kanan dan
## kidal. Scene sungguhan (`jalan_uji.tscn`), stick lewat keyboard editor yang dinyalakan tes, `perbarui(DT)` dengan dt tetap.
##
## Dipanggil dari `tests/run_tests.gd`. Potongan persegi sprite dengan zona stick di 640 dicetak sebagai baris `[tata_letak]`
## (dicatat di LOG, bukan gagal: layar 16:9 dinilai di HP).

const BERKAS_JALAN_UJI: String = "res://scenes/dev/jalan_uji.tscn"
const BERKAS_RUTE: String = "res://scenes/rute/rute.tscn"
const DT: float = 1.0 / 60.0
## Jendela uji: [lebar jendela, tinggi jendela, lebar viewport] (skala x3).
const KASUS: Array = [[1920, 1080, 640], [2340, 1080, 780], [2400, 1080, 800]]
## Langkah sampai kecepatan dan geseran dorongan mantap (ngebut: 1 detik rampa + 3 detik penghalusan; rem: berhenti + penghalusan).
const LANGKAH_MANTAP: int = 240

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
	_test_angka_paket()
	for kasus: Array in KASUS:
		for kidal: bool in [false, true]:
			await _test_tata_letak(kasus, kidal)
			await _test_tata_letak_rute(kasus, kidal)


func _test_angka_paket() -> void:
	_judul.call("Paket penyetelan pemilik 2026-10-14 (AC-6, D-7)")
	check(Config.HUD_TOMBOL_TINGGI_PX == 42 and Config.HUD_JEDA_SENTUH_PX == 42, "tinggi tombol strip atas dan area sentuh jeda 42 px game (44 dp di A54)")
	check(Config.KAMERA_SEPEDA_Y_PECAHAN == 0.75, "sepeda di 75% tinggi layar (KAMERA_SEPEDA_Y_PECAHAN 0,75)")
	check(Config.KAMERA_SEPEDA_X_PECAHAN == 0.3333, "letak datar sepeda tetap sepertiga kiri (dikunci)")
	check(Config.DORONGAN_MAJU_PX == 36.0 and Config.DORONGAN_MUNDUR_PX == 20.0 and Config.DORONGAN_RESPON_DETIK == 0.35, "dorongan maju 36, mundur 20, respon 0,35 detik")
	check(Config.STICK_RADIUS_PX == 35.0, "radius stick tetap 35 px game")
	var tema: Theme = load("res://assets/ui/theme.tres") as Theme
	check(tema != null and tema.get_font_size(&"font_size", &"HudLabel") == 8, "theme.tres: HudLabel 8 px (DESIGN_SPEC 1.2, paket pemilik)")


func _anak(akar: Node, nama: String) -> Node:
	return akar.find_child(nama, true, false)


## Persegi gambar sprite pemain (sel penuh frame saat ini) dalam koordinat viewport game.
func _rect_sprite(sprite: AnimatedSprite2D) -> Rect2:
	var tekstur: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	var ukuran: Vector2 = tekstur.get_size()
	var lokal: Rect2 = Rect2(sprite.offset - ukuran / 2 if sprite.centered else sprite.offset, ukuran)
	return sprite.get_global_transform_with_canvas() * lokal


func _test_tata_letak(kasus: Array, kidal: bool) -> void:
	var lebar: int = kasus[2]
	var tag: String = "%d %s" % [lebar, "kidal" if kidal else "kanan"]
	_judul.call("Tata letak %s: sepeda, panel, tombol (AC-6)" % tag)
	_tree.root.size = Vector2i(kasus[0], kasus[1])
	var akar: JalanUji = (load(BERKAS_JALAN_UJI) as PackedScene).instantiate() as JalanUji
	_tree.root.add_child(akar)
	await _tree.process_frame
	await _tree.process_frame
	akar.set_process(false)
	var hud: HudDev = _anak(akar, "Hud") as HudDev
	var kontrol: KontrolTouch = _anak(akar, "KontrolTouch") as KontrolTouch
	var sepeda: SepedaUji = _anak(akar, "Sepeda") as SepedaUji
	var sprite: LoperSprite = _anak(akar, "LoperAgen") as LoperSprite
	sprite.set_process(false)
	(_anak(hud, "TombolKidal") as Button).button_pressed = kidal
	await _tree.process_frame
	await _tree.process_frame
	check(kontrol.router.kidal() == kidal, "%s: mode tangan terpasang" % tag)
	var layar: Rect2 = Rect2(Vector2.ZERO, akar.get_viewport_rect().size)
	check(layar.size == Vector2(lebar, 360), "%s: viewport %dx360" % [tag, lebar])
	var panel: Rect2 = hud.rect_panel_kecepatan()
	var stick: Rect2 = TouchZones.rect_stick(lebar, kidal)
	var swipe: Rect2 = TouchZones.rect_swipe(lebar, kidal)
	# (c) Panel bawah di dalam layar dan tidak masuk zona stick.
	check(layar.encloses(panel) and not panel.intersects(stick, true), "%s: panel bawah %s di dalam layar dan tidak masuk zona stick %s" % [tag, panel, stick])
	# (d) Panel sisa koran (DESIGN_SPEC 3.5, run fase2a-lemparan): x 400 dari tepi sisi stick (dicerminkan saat kidal), bawah 8, di dalam
	# layar, tidak menumpuk zona stick, panel kecepatan, tombol jeda, atau tombol kidal; tidak menutupi sprite pemain.
	var koran: Rect2 = hud.rect_panel_koran()
	var x_harapan: float = float(lebar - Config.HUD_PANEL_KORAN_GESER_PX) - koran.size.x if kidal else float(Config.HUD_PANEL_KORAN_GESER_PX)
	check(absf(koran.position.x - x_harapan) <= 1.0 and absf(koran.end.y - float(360 - Config.HUD_MARGIN_TEPI_PX)) <= 1.0, "%s: panel koran %s di x %s (400 dari tepi sisi stick), bawah 8" % [tag, koran, x_harapan])
	check(layar.encloses(koran) and not koran.intersects(stick, true) and not koran.intersects(panel, true), "%s: panel koran di dalam layar, tidak masuk zona stick dan tidak menumpuk panel kecepatan" % tag)
	check(not koran.intersects(hud.rect_tombol_jeda(), true) and not koran.intersects(hud.rect_tombol_kidal(), true), "%s: panel koran tidak menumpuk tombol jeda dan tombol kidal" % tag)
	check(TouchZones.rect_swipe(lebar, kidal).encloses(koran), "%s: panel koran di dalam zona swipe (sentuhannya tetap swipe, AC-8)" % tag)
	# (a) Sprite di dorongan maju penuh dan mundur penuh tidak menabrak panel dan tetap di dalam layar.
	kontrol.keyboard_aktif = true
	var keadaan: Dictionary = {}
	for arah: String in ["maju", "mundur"]:
		var aksi: StringName = &"stick_atas" if arah == "maju" else &"stick_bawah"
		Input.action_press(aksi)
		for i: int in range(LANGKAH_MANTAP):
			akar.perbarui(DT)
		Input.action_release(aksi)
		var target: Vector2 = DoronganKecepatan.geser_target(Config.KECEPATAN_NGEBUT_UD if arah == "maju" else 0.0)
		check(akar.geser_dorongan().distance_to(target) < 0.05, "%s %s: geseran dorongan penuh %s, dapat %s" % [tag, arah, target, akar.geser_dorongan()])
		await _tree.process_frame
		var rect: Rect2 = _rect_sprite(sprite)
		keadaan[arah] = rect
		check(not rect.intersects(panel, true), "%s %s: persegi sprite %s tidak berpotongan dengan panel kecepatan %s (jarak tegak %s px)" % [tag, arah, rect, panel, panel.position.y - rect.end.y])
		check(not rect.intersects(koran, true), "%s %s: persegi sprite %s tidak berpotongan dengan panel koran %s" % [tag, arah, rect, koran])
		check(layar.encloses(rect), "%s %s: persegi sprite %s di dalam layar" % [tag, arah, rect])
		print("[tata_letak] %s %s: sprite %s, panel %s, jarak tegak sprite ke panel %s px" % [tag, arah, rect, panel, panel.position.y - rect.end.y])
		for i: int in range(LANGKAH_MANTAP):
			akar.perbarui(DT)
	kontrol.keyboard_aktif = OS.has_feature("editor")
	if lebar == Config.LAYAR_LEBAR_DASAR_PX:
		for arah: String in ["maju", "mundur"]:
			var potong: Rect2 = (keadaan[arah] as Rect2).intersection(stick)
			print("[tata_letak] %s %s: sprite %s, zona stick %s, potongan %s (luas %d px2)" % [tag, arah, keadaan[arah], stick, potong, int(potong.get_area())])
	# (b) Tombol kidal dan tombol jeda: >= 42x42, di strip atas, tidak bertumpuk, tidak masuk zona stick/swipe (kedua mode tangan).
	var tombol_kidal: Rect2 = hud.rect_tombol_kidal()
	var tombol_jeda: Rect2 = hud.rect_tombol_jeda()
	for pasang: Array in [["kidal", tombol_kidal], ["jeda", tombol_jeda]]:
		var r: Rect2 = pasang[1]
		check(r.size.x >= 42.0 and r.size.y >= 42.0, "%s: area sentuh tombol %s >= 42x42, dapat %s" % [tag, pasang[0], r.size])
		check(r.position.y >= 0.0 and r.end.y <= float(Config.HUD_STRIP_ATAS_TINGGI_PX) and r.position.x >= 0.0 and r.end.x <= float(lebar), "%s: tombol %s di dalam strip atas (%s)" % [tag, pasang[0], r])
		var bebas: bool = true
		for mode: bool in [false, true]:
			if r.intersects(TouchZones.rect_stick(lebar, mode), true) or r.intersects(TouchZones.rect_swipe(lebar, mode), true):
				bebas = false
		check(bebas, "%s: tombol %s tidak masuk zona stick maupun swipe (tangan kanan dan kidal)" % [tag, pasang[0]])
	check(not tombol_kidal.intersects(tombol_jeda, true), "%s: tombol kidal %s dan tombol jeda %s tidak bertumpuk" % [tag, tombol_kidal, tombol_jeda])
	check(tombol_jeda.position == Vector2(17, 4), "%s: tombol jeda tidak dicerminkan saat kidal (tetap x 17, y 4), dapat %s" % [tag, tombol_jeda.position])
	check(not swipe.intersects(stick, true), "%s: zona stick dan swipe tidak bertumpuk" % tag)
	_tree.root.remove_child(akar)
	akar.free()


## Run fase3b-rintangan-skor bagian B (AC-13, AC-15): tombol bel 40x40 dan panel skor HUD dev di scene rute. Harapan literal: tombol bel
## pusat (lebar - 28, 332), kidal (28, 332), persegi 40x40; zona tap bel (kotak luar lingkaran radius 28) tidak menumpuk panel bawah,
## tombol mode bantu, tombol kidal, atau tombol jeda. Panel skor di strip atas (y 4 sampai paling bawah 48), 112 dari tepi sisi swipe
## (kidal dicerminkan), tidak menumpuk tombol strip atas, tombol "Main lagi", atau sprite pemain.
func _test_tata_letak_rute(kasus: Array, kidal: bool) -> void:
	var lebar: int = kasus[2]
	var tag: String = "rute %d %s" % [lebar, "kidal" if kidal else "kanan"]
	_judul.call("Tata letak %s: tombol bel dan panel skor (AC-13, AC-15)" % tag)
	_tree.root.size = Vector2i(kasus[0], kasus[1])
	var akar: RuteMain = (load(BERKAS_RUTE) as PackedScene).instantiate() as RuteMain
	_tree.root.add_child(akar)
	await _tree.process_frame
	await _tree.process_frame
	akar.set_process(false)
	var hud: HudDev = _anak(akar, "Hud") as HudDev
	var sprite: LoperSprite = _anak(akar, "LoperAgen") as LoperSprite
	sprite.set_process(false)
	(_anak(hud, "TombolKidal") as Button).button_pressed = kidal
	await _tree.process_frame
	await _tree.process_frame
	akar.perbarui(0.0)
	await _tree.process_frame
	var layar: Rect2 = Rect2(Vector2.ZERO, akar.get_viewport_rect().size)
	var bel: Rect2 = hud.rect_tombol_bel()
	var bel_harapan: Rect2 = Rect2(8, 312, 40, 40) if kidal else Rect2(lebar - 48, 312, 40, 40)
	check(bel == bel_harapan, "%s: tombol bel %s, dapat %s" % [tag, bel_harapan, bel])
	var pusat: Vector2 = Vector2(28, 332) if kidal else Vector2(lebar - 28, 332)
	check(TouchZones.pusat_bel(lebar, kidal) == pusat and bel.get_center() == pusat, "%s: pusat zona tap bel = pusat tombol %s" % [tag, pusat])
	var zona_bel: Rect2 = Rect2(pusat - Vector2(28, 28), Vector2(56, 56))
	var lain: Array = [["panel kecepatan", hud.rect_panel_kecepatan()], ["panel koran", hud.rect_panel_koran()], ["tombol bantu", hud.rect_tombol_bantu()], ["tombol kidal", hud.rect_tombol_kidal()], ["tombol jeda", hud.rect_tombol_jeda()]]
	for pasang: Array in lain:
		check(not zona_bel.intersects(pasang[1], true) and not bel.intersects(pasang[1], true), "%s: tombol dan zona tap bel %s tidak menumpuk %s %s" % [tag, zona_bel, pasang[0], pasang[1]])
	check(layar.encloses(bel) and not zona_bel.intersects(TouchZones.rect_stick(lebar, kidal), true), "%s: tombol bel di dalam layar, zona bel tidak menyentuh zona stick" % tag)
	var skor: Rect2 = hud.rect_panel_skor()
	var x_harapan: float = float(Config.HUD_SKOR_GESER_PX) if kidal else float(lebar - Config.HUD_SKOR_GESER_PX) - skor.size.x
	check(absf(skor.position.x - x_harapan) <= 1.0 and skor.position.y == 4.0 and skor.end.y <= 48.0, "%s: panel skor %s di x %s, y 4, bawah <= 48 (strip atas)" % [tag, skor, x_harapan])
	for pasang: Array in [["tombol bantu", hud.rect_tombol_bantu()], ["tombol kidal", hud.rect_tombol_kidal()], ["tombol jeda", hud.rect_tombol_jeda()], ["tombol Main lagi", akar.panel_akhir().rect_tombol()]]:
		check(not skor.intersects(pasang[1], true), "%s: panel skor tidak menumpuk %s %s" % [tag, pasang[0], pasang[1]])
	check(not skor.intersects(_rect_sprite(sprite), true) and not bel.intersects(_rect_sprite(sprite), true), "%s: panel skor dan tombol bel tidak menutupi sprite pemain" % tag)
	_tree.root.remove_child(akar)
	akar.free()
