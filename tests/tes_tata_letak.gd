class_name TesTataLetak
extends RefCounted
## Tes tata letak paket penyetelan run fase1b-umpan-balik (AC-6, D-7): sepeda di `KAMERA_SEPEDA_Y_PECAHAN`, dorongan maju dan mundur
## penuh, panel kecepatan dengan teks HUD 8 px, tombol kidal dan tombol jeda 42 px, di viewport 640, 780, dan 800, tangan kanan dan
## kidal. Scene sungguhan (`jalan_uji.tscn`), stick lewat keyboard editor yang dinyalakan tes, `perbarui(DT)` dengan dt tetap.
## Scene rute: HUD rute final dan zona aman tiruan (run fase3c-hud-hasil, `_test_tata_letak_rute`).
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


## HUD rute final (run fase3c-hud-hasil AC-5, AC-8, AC-9; dulu tombol bel dan panel skor HUD dev run 3B). Harapan literal dari DESIGN_SPEC
## 3.1-3.5 dan 3.8: tombol jeda area sentuh (17, 4) 42x42; radar seberang (4, 10) 12x172 dan dekat (lebar - 16, 10) 12x172, tidak ditukar
## saat kidal; panel progres lebar 260 di tengah, y 8; panel skor berakhir 28 dari tepi kanan, y 8, panel koin 5 di kirinya; tombol bel
## pusat (lebar - 28, 332), kidal (28, 332). Tidak ada tumpang tindih antar elemen (zona tap bel = kotak luar lingkaran radius 28), tidak
## ada yang masuk zona stick, panel atas dan radar tidak menutupi sprite pemain (diam dan dorongan maju penuh), panel progres di dalam
## 640 tengah, semua di dalam layar, tidak ada yang menerima sentuhan kecuali tombol jeda. Tanpa tombol dev Kidal, Bantu, Main lagi.
func _test_tata_letak_rute(kasus: Array, kidal: bool) -> void:
	var lebar: int = kasus[2]
	var tag: String = "rute %d %s" % [lebar, "kidal" if kidal else "kanan"]
	_judul.call("Tata letak %s: HUD rute final, radar, tombol bel (AC-5, AC-8, AC-9)" % tag)
	_tree.root.size = Vector2i(kasus[0], kasus[1])
	var akar: RuteMain = (load(BERKAS_RUTE) as PackedScene).instantiate() as RuteMain
	_tree.root.add_child(akar)
	await _tree.process_frame
	await _tree.process_frame
	akar.set_process(false)
	var hud: HudRute = akar.hud_rute()
	var sprite: LoperSprite = _anak(akar, "LoperAgen") as LoperSprite
	sprite.set_process(false)
	akar.atur_kidal(kidal)
	await _tree.process_frame
	await _tree.process_frame
	akar.perbarui(0.0)
	await _tree.process_frame
	check(hud != null and akar.kidal() == kidal, "%s: HUD rute terpasang, mode tangan %s" % [tag, kidal])
	check(_anak(akar, "TombolKidal") == null and _anak(akar, "TombolBantu") == null and _anak(akar, "PanelAkhir").find_child("TombolUlang", true, false) != null and not akar.panel_akhir().tombol_tampil(), "%s: tanpa tombol dev Kidal/Bantu di HUD; tombol banner hanya untuk galat" % tag)
	var layar: Rect2 = Rect2(Vector2.ZERO, akar.get_viewport_rect().size)
	var bel: Rect2 = hud.rect_tombol_bel()
	var bel_harapan: Rect2 = Rect2(8, 312, 40, 40) if kidal else Rect2(lebar - 48, 312, 40, 40)
	check(bel == bel_harapan, "%s: tombol bel %s, dapat %s" % [tag, bel_harapan, bel])
	var pusat: Vector2 = Vector2(28, 332) if kidal else Vector2(lebar - 28, 332)
	check(TouchZones.pusat_bel(lebar, kidal) == pusat and bel.get_center() == pusat and akar.kontrol_router().geser_bel == Vector2.ZERO, "%s: pusat zona tap bel = pusat tombol %s, tanpa geseran zona aman" % [tag, pusat])
	var zona_bel: Rect2 = Rect2(pusat - Vector2(28, 28), Vector2(56, 56))
	check(hud.rect_tombol_jeda() == Rect2(17, 4, 42, 42), "%s: area sentuh tombol jeda (17, 4) 42x42 (tidak dicerminkan), dapat %s" % [tag, hud.rect_tombol_jeda()])
	check(hud.rect_radar_seberang() == Rect2(4, 10, 12, 172), "%s: radar seberang (4, 10) 12x172 (tidak ditukar kidal), dapat %s" % [tag, hud.rect_radar_seberang()])
	check(hud.rect_radar_dekat() == Rect2(lebar - 16, 10, 12, 172), "%s: radar dekat (%d, 10) 12x172, dapat %s" % [tag, lebar - 16, hud.rect_radar_dekat()])
	var progres: Rect2 = hud.rect_panel_progres()
	check(progres.size.x == 260.0 and progres.position.y == 8.0 and absf(progres.get_center().x - float(lebar) / 2) <= 0.5, "%s: panel progres lebar 260, y 8, di tengah (%s)" % [tag, progres])
	var tengah_640: Rect2 = Rect2(float(lebar - 640) / 2, 0, 640, 360)
	check(tengah_640.encloses(progres), "%s: panel progres di dalam 640 tengah" % tag)
	var skor: Rect2 = hud.rect_panel_skor()
	var koin: Rect2 = hud.rect_panel_koin()
	check(skor.end.x == float(lebar - 28) and skor.position.y == 8.0 and skor.size.x >= 72.0, "%s: panel skor berakhir 28 dari tepi kanan, y 8, lebar >= 72 (%s)" % [tag, skor])
	check(koin.end.x + 5.0 == skor.position.x and koin.position.y == 8.0, "%s: panel koin 5 di kiri panel skor, y 8 (%s)" % [tag, koin])
	var elemen: Array = [["tombol jeda", hud.rect_tombol_jeda()], ["radar seberang", hud.rect_radar_seberang()], ["radar dekat", hud.rect_radar_dekat()], ["panel progres", progres], ["panel koin", koin], ["panel skor", skor], ["zona bel", zona_bel], ["panel kecepatan", hud.rect_panel_kecepatan()], ["panel koran", hud.rect_panel_koran()]]
	var stick: Rect2 = TouchZones.rect_stick(lebar, kidal)
	for i: int in range(elemen.size()):
		var a: Rect2 = elemen[i][1]
		check(layar.encloses(a), "%s: %s di dalam layar (%s)" % [tag, elemen[i][0], a])
		check(not a.intersects(stick, true), "%s: %s tidak masuk zona stick" % [tag, elemen[i][0]])
		for j: int in range(i + 1, elemen.size()):
			check(not a.intersects(elemen[j][1], true), "%s: %s %s dan %s %s tidak bertumpuk" % [tag, elemen[i][0], a, elemen[j][0], elemen[j][1]])
	# Panel atas dan radar tidak menutupi sprite pemain, diam dan pada dorongan maju penuh (sepeda bergeser maju di layar).
	var rect_sprite: Rect2 = _rect_sprite(sprite)
	var geser: Vector2 = DoronganKecepatan.geser_target(Config.KECEPATAN_NGEBUT_UD)
	for r: Rect2 in [rect_sprite, Rect2(rect_sprite.position + geser, rect_sprite.size)]:
		for pasang: Array in [["panel progres", progres], ["panel koin", koin], ["panel skor", skor], ["radar seberang", hud.rect_radar_seberang()], ["radar dekat", hud.rect_radar_dekat()], ["tombol bel", bel]]:
			check(not r.intersects(pasang[1], true), "%s: %s tidak menutupi sprite pemain %s" % [tag, pasang[0], r])
	# Hanya tombol jeda yang menerima sentuhan: radar dan panel mengabaikan mouse/sentuh GUI.
	var penangkap: Array[String] = []
	for simpul: Node in hud.find_children("*", "Control", true, false):
		var c: Control = simpul as Control
		if c.mouse_filter != Control.MOUSE_FILTER_IGNORE and not (c is TombolJeda):
			penangkap.append(String(c.name))
	check(penangkap.is_empty(), "%s: elemen HUD rute selain tombol jeda tidak menerima sentuhan: %s" % [tag, penangkap])
	if lebar == 780 and not kidal:
		await _test_zona_aman_tiruan(akar, hud, lebar)
	_tree.root.remove_child(akar)
	akar.free()


## Inset aman tiruan (AC-9): tepi x 0 inset 10, tepi x lebar 11, bawah 20 (atas 0) -> geseran 6, 7, 12. Harapan literal; zona tap bel ikut.
func _test_zona_aman_tiruan(akar: RuteMain, hud: HudRute, lebar: int) -> void:
	var inset: ZonaAman.Inset = ZonaAman.Inset.new()
	inset.awal_x = 10
	inset.akhir_x = 11
	inset.bawah = 20
	hud.atur_inset(inset)
	await _tree.process_frame
	await _tree.process_frame
	akar.perbarui(0.0)
	check(hud.rect_radar_seberang() == Rect2(10, 10, 12, 172) and hud.rect_tombol_jeda() == Rect2(23, 4, 42, 42), "inset tiruan: radar seberang x 10 (= inset), tombol jeda ikut bergeser 6 ke x 23")
	check(hud.rect_radar_dekat() == Rect2(lebar - 23, 10, 12, 172) and hud.rect_panel_skor().end.x == float(lebar - 35), "inset tiruan: radar dekat berakhir 11 dari tepi (inset), panel skor 35 dari tepi")
	check(hud.rect_tombol_bel() == Rect2(lebar - 55, 300, 40, 40) and hud.rect_panel_kecepatan().end.y == 340.0, "inset tiruan: tombol bel dan panel bawah naik 12 (bawah 20 dari tepi), bel 15 dari tepi kanan")
	check(akar.kontrol_router().geser_bel == Vector2(-7, -12) and TouchZones.pusat_bel(lebar, false, akar.kontrol_router().geser_bel) == hud.rect_tombol_bel().get_center(), "inset tiruan: zona tap bel ikut tombol (geser (-7, -12))")
	akar.atur_kidal(true)
	await _tree.process_frame
	akar.perbarui(0.0)
	check(hud.rect_tombol_bel() == Rect2(14, 300, 40, 40) and akar.kontrol_router().geser_bel == Vector2(6, -12), "inset tiruan kidal: bel di x 14 (inset 10 + 4), zona ikut (6, -12)")
	akar.atur_kidal(false)
	hud.atur_inset(null)
	await _tree.process_frame
	akar.perbarui(0.0)
	check(hud.rect_radar_seberang() == Rect2(4, 10, 12, 172) and akar.kontrol_router().geser_bel == Vector2.ZERO, "inset kembali nol: tata letak semula")
