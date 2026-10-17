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
## Pusat tombol dan zona tap bel yang diharapkan (masukan uji pemilik 2026-10-17, PR #33: pojok susah dijangkau jempol), koordinat
## viewport game: [lebar, kidal, pusat tanpa inset, pusat dengan inset tiruan awal_x 10 / akhir_x 11 / bawah 20 (geser 6 / 7 / 12)].
## Kanan (lebar - 64, 296), kidal (64, 296): kidal hanya dicerminkan mendatar. Dulu (lebar - 28, 332) / (28, 332), di pojok.
const BEL_HARAPAN: Array = [
	[640, false, Vector2(576, 296), Vector2(569, 284)],
	[640, true, Vector2(64, 296), Vector2(70, 284)],
	[780, false, Vector2(716, 296), Vector2(709, 284)],
	[780, true, Vector2(64, 296), Vector2(70, 284)],
	[800, false, Vector2(736, 296), Vector2(729, 284)],
	[800, true, Vector2(64, 296), Vector2(70, 284)],
]
## Langkah `perbarui(DT)` supaya teks dan jeda bel (0,5 + 1,0 detik) habis sebelum ketukan bel berikutnya diharapkan berbunyi.
const LANGKAH_BEL_REDA: int = 100

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
## pusat dari `BEL_HARAPAN` ((lebar - 64, 296), kidal (64, 296)). Tidak ada tumpang tindih antar elemen (zona tap bel = kotak luar lingkaran radius 28), tidak
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
	var harapan: Array = _bel_harapan(lebar, kidal)
	var pusat: Vector2 = harapan[2]
	var bel_harapan: Rect2 = Rect2(pusat - Vector2(20, 20), Vector2(40, 40))
	check(bel == bel_harapan, "%s: tombol bel %s, dapat %s" % [tag, bel_harapan, bel])
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
	await _test_bel_dijangkau(akar, hud, lebar, kidal, tag)
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
	check(hud.rect_tombol_bel() == Rect2(lebar - 91, 264, 40, 40) and hud.rect_panel_kecepatan().end.y == 340.0, "inset tiruan: tombol bel dan panel bawah naik 12 (bawah 20 dari tepi), bel geser 7 ke kiri")
	check(akar.kontrol_router().geser_bel == Vector2(-7, -12) and TouchZones.pusat_bel(lebar, false, akar.kontrol_router().geser_bel) == hud.rect_tombol_bel().get_center(), "inset tiruan: zona tap bel ikut tombol (geser (-7, -12))")
	# QA-002 iterasi 1: jari sungguhan ke router. (689, 269) ada di tombol bel bergeser (689..729, 264..304), berjarak 25 dari pusat baru
	# (709, 284) dan 38,2 dari pusat tanpa inset (716, 296) (radius 28): harus BEL, bukan swipe.
	await _cek_jari_bel(akar, Vector2(689, 269), "inset tiruan kanan")
	akar.atur_kidal(true)
	await _tree.process_frame
	akar.perbarui(0.0)
	check(hud.rect_tombol_bel() == Rect2(50, 264, 40, 40) and akar.kontrol_router().geser_bel == Vector2(6, -12), "inset tiruan kidal: bel di x 50 (44 + geser 6), zona ikut (6, -12)")
	# Kidal: (76, 264) di tombol (50..90, 264..304), 20,9 dari pusat baru (70, 284), 34,2 dari pusat tanpa inset (64, 296).
	await _cek_jari_bel(akar, Vector2(76, 264), "inset tiruan kidal")
	akar.atur_kidal(false)
	hud.atur_inset(null)
	await _tree.process_frame
	akar.perbarui(0.0)
	check(hud.rect_radar_seberang() == Rect2(4, 10, 12, 172) and akar.kontrol_router().geser_bel == Vector2.ZERO, "inset kembali nol: tata letak semula")
	# Kontrol (tanpa inset): titik yang sama di luar zona bel lama, jadi swipe. Membuktikan titik uji di atas memang bergantung pada geseran.
	var router: TouchRouter = akar.kontrol_router()
	var bel_awal: int = router.jumlah_bel
	_sentuh_layar(7, Vector2(689, 269), true)
	check(router.swipe_aktif() and router.jumlah_bel == bel_awal, "kontrol tanpa inset: jari di (689, 269) menjadi swipe, bukan bel")
	_sentuh_layar(7, Vector2(689, 269), false)
	await _test_zona_aman_atas(akar, hud, lebar)


## Jari sungguhan (event sentuh lewat `KontrolTouch`) turun di `titik` (koordinat viewport game, skala x3): router mengklaimnya sebagai bel,
## bel adegan berbunyi, tidak ada swipe atau stick; setelah diangkat tidak ada swipe/tap yang tercatat.
func _cek_jari_bel(akar: RuteMain, titik: Vector2, tag: String) -> void:
	var router: TouchRouter = akar.kontrol_router()
	var bel_router: int = router.jumlah_bel
	var bel_adegan: int = akar.bel().jumlah
	var swipe_selesai: int = router.jumlah_swipe_selesai
	_sentuh_layar(6, titik, true)
	check(router.jumlah_bel == bel_router + 1 and router.bel_ditahan() and not router.swipe_aktif() and not router.stick_aktif(), "%s: jari di %s diklaim zona bel (bukan swipe/stick)" % [tag, titik])
	check(akar.bel().jumlah == bel_adegan + 1, "%s: bel adegan berbunyi sekali (%d -> %d)" % [tag, bel_adegan, akar.bel().jumlah])
	_sentuh_layar(6, titik, false)
	check(not router.bel_ditahan() and router.jumlah_swipe_selesai == swipe_selesai, "%s: jari diangkat tanpa swipe atau tap" % tag)


## Baris `BEL_HARAPAN` untuk lebar dan mode tangan.
func _bel_harapan(lebar: int, kidal: bool) -> Array:
	for baris: Array in BEL_HARAPAN:
		if baris[0] == lebar and baris[1] == kidal:
			return baris
	check(false, "BEL_HARAPAN tidak punya baris lebar %d kidal %s" % [lebar, kidal])
	return [lebar, kidal, Vector2.ZERO, Vector2.ZERO]


## Masukan review pemilik 2026-10-17 (PR #33): bel di posisi baru terjangkau jempol, tetap di dalam zona swipe sisi lempar, tidak menumpuk
## dengan elemen HUD lain dan tidak masuk zona stick (juga dengan inset aman tiruan), sentuhan sungguhan yang dimulai di zona bel baru
## membunyikan bel dan tidak memulai swipe (walau digeser), dan sentuhan di posisi bel LAMA di pojok kini swipe/tap biasa. Harapan literal.
func _test_bel_dijangkau(akar: RuteMain, hud: HudRute, lebar: int, kidal: bool, tag: String) -> void:
	var harapan: Array = _bel_harapan(lebar, kidal)
	var pusat: Vector2 = harapan[2]
	var router: TouchRouter = akar.kontrol_router()
	_cek_bel_bebas(hud, lebar, kidal, pusat, "%s bel" % tag)
	# Ketukan di pusat membunyikan bel adegan (bel reda dulu supaya tidak sedang jeda bel).
	_langkah(akar, LANGKAH_BEL_REDA)
	await _cek_jari_bel(akar, pusat, "%s bel baru" % tag)
	# Tepi zona radius 28 inklusif: atas dan sisi dalam (ke arah tengah layar) masih bel; 1 px di luarnya swipe.
	var ke_dalam: float = 1.0 if kidal else -1.0
	_cek_klaim_bel(router, pusat + Vector2(0, -28), true, "%s tepi atas zona bel" % tag)
	_cek_klaim_bel(router, pusat + Vector2(28 * ke_dalam, 0), true, "%s tepi dalam zona bel" % tag)
	_cek_klaim_bel(router, pusat + Vector2(0, -29), false, "%s 1 px di atas zona bel" % tag)
	_cek_klaim_bel(router, pusat + Vector2(29 * ke_dalam, 0), false, "%s 1 px di dalam (ke tengah) zona bel" % tag)
	# Jari bel yang digeser jauh ke zona swipe tetap jari bel: tidak ada garis bidik, swipe, atau tap.
	var swipe_awal: int = router.jumlah_swipe_selesai
	var tap_awal: int = router.jumlah_tap_selesai
	_sentuh_layar(8, pusat, true)
	_geser_layar(8, pusat + Vector2(150 * ke_dalam, -120))
	check(router.bel_ditahan() and not router.swipe_aktif(), "%s: jari bel digeser ke %s tetap jari bel, bukan swipe" % [tag, pusat + Vector2(150 * ke_dalam, -120)])
	_sentuh_layar(8, pusat + Vector2(150 * ke_dalam, -120), false)
	check(router.jumlah_swipe_selesai == swipe_awal and router.jumlah_tap_selesai == tap_awal, "%s: jari bel yang digeser lalu diangkat tidak menjadi swipe atau tap" % tag)
	# Posisi bel lama (pojok) kini sentuhan swipe biasa: diklaim swipe, diangkat tanpa geser = tap; tidak membunyikan bel.
	var lama: Vector2 = Vector2(28, 332) if kidal else Vector2(lebar - 28, 332)
	var bel_awal: int = router.jumlah_bel
	_sentuh_layar(9, lama, true)
	check(router.swipe_aktif() and not router.bel_ditahan() and router.jumlah_bel == bel_awal, "%s: sentuhan di posisi bel lama %s kini swipe, bukan bel" % [tag, lama])
	_sentuh_layar(9, lama, false)
	check(router.jumlah_swipe_selesai == swipe_awal + 1 and router.jumlah_tap_selesai == tap_awal + 1 and router.jumlah_bel == bel_awal, "%s: sentuhan di posisi bel lama diangkat = swipe/tap biasa" % tag)
	# Inset aman tiruan (awal_x 10, akhir_x 11, bawah 20): bel ikut bergeser ke pusat literal, tetap bebas dan tetap terklaim.
	var inset: ZonaAman.Inset = ZonaAman.Inset.new()
	inset.awal_x = 10
	inset.akhir_x = 11
	inset.bawah = 20
	hud.atur_inset(inset)
	await _tree.process_frame
	await _tree.process_frame
	akar.perbarui(0.0)
	var pusat_inset: Vector2 = harapan[3]
	check(hud.rect_tombol_bel() == Rect2(pusat_inset - Vector2(20, 20), Vector2(40, 40)) and TouchZones.pusat_bel(lebar, kidal, router.geser_bel) == pusat_inset, "%s inset tiruan: tombol dan zona bel berpusat di %s, dapat %s" % [tag, pusat_inset, hud.rect_tombol_bel()])
	_cek_bel_bebas(hud, lebar, kidal, pusat_inset, "%s inset tiruan bel" % tag)
	_cek_klaim_bel(router, pusat_inset, true, "%s inset tiruan pusat bel" % tag)
	_cek_klaim_bel(router, pusat_inset + Vector2(0, -28), true, "%s inset tiruan tepi atas zona bel" % tag)
	hud.atur_inset(null)
	await _tree.process_frame
	akar.perbarui(0.0)
	check(hud.rect_tombol_bel().get_center() == pusat and router.geser_bel == Vector2.ZERO, "%s: inset kembali nol, bel kembali ke %s" % [tag, pusat])
	_langkah(akar, LANGKAH_BEL_REDA)


## Zona tap bel (kotak luar lingkaran radius 28 di `pusat`) dan tombolnya: di dalam zona swipe sisi lempar, di luar zona stick, tidak
## menumpuk dengan tombol jeda, radar (y 10-182), panel atas, dan panel bawah.
func _cek_bel_bebas(hud: HudRute, lebar: int, kidal: bool, pusat: Vector2, tag: String) -> void:
	var zona_bel: Rect2 = Rect2(pusat - Vector2(28, 28), Vector2(56, 56))
	check(zona_bel.encloses(hud.rect_tombol_bel()), "%s: tombol %s di dalam zona tap %s" % [tag, hud.rect_tombol_bel(), zona_bel])
	check(TouchZones.rect_swipe(lebar, kidal).encloses(zona_bel), "%s: zona tap %s di dalam zona swipe sisi lempar %s" % [tag, zona_bel, TouchZones.rect_swipe(lebar, kidal)])
	check(not zona_bel.intersects(TouchZones.rect_stick(lebar, kidal), true), "%s: zona tap %s tidak masuk zona stick" % [tag, zona_bel])
	var lain: Array = [["tombol jeda", hud.rect_tombol_jeda()], ["radar seberang", hud.rect_radar_seberang()], ["radar dekat", hud.rect_radar_dekat()], ["panel progres", hud.rect_panel_progres()], ["panel koin", hud.rect_panel_koin()], ["panel skor", hud.rect_panel_skor()], ["panel kecepatan", hud.rect_panel_kecepatan()], ["panel koran", hud.rect_panel_koran()]]
	for pasang: Array in lain:
		check(not zona_bel.intersects(pasang[1], true), "%s: zona tap %s tidak menumpuk dengan %s %s" % [tag, zona_bel, pasang[0], pasang[1]])


## Jari sungguhan turun di `titik` lalu diangkat: `bel` True = router mengklaimnya sebagai jari bel (bukan swipe/stick) dan diangkat tanpa
## swipe atau tap; False = router mengklaimnya sebagai swipe, bukan bel.
func _cek_klaim_bel(router: TouchRouter, titik: Vector2, bel: bool, tag: String) -> void:
	var bel_awal: int = router.jumlah_bel
	var swipe_awal: int = router.jumlah_swipe_selesai
	_sentuh_layar(5, titik, true)
	if bel:
		check(router.jumlah_bel == bel_awal + 1 and router.bel_ditahan() and not router.swipe_aktif() and not router.stick_aktif(), "%s: jari di %s diklaim zona bel" % [tag, titik])
	else:
		check(router.jumlah_bel == bel_awal and router.swipe_aktif() and not router.bel_ditahan(), "%s: jari di %s menjadi swipe, bukan bel" % [tag, titik])
	_sentuh_layar(5, titik, false)
	if bel:
		check(router.jumlah_swipe_selesai == swipe_awal, "%s: jari bel di %s diangkat tanpa swipe" % [tag, titik])


func _langkah(akar: RuteMain, n: int) -> void:
	for i: int in range(n):
		akar.perbarui(DT)


## QA-003 iterasi 1: inset aman ATAS tiruan 15 px game (lain 0) -> geseran atas = max(4, 15) - 4 = 11 (acuan area sentuh jeda y 4). Semua
## elemen atas turun 11 sama besar; radar bawah tetap y 182; elemen bawah tidak berubah. Harapan literal.
func _test_zona_aman_atas(akar: RuteMain, hud: HudRute, lebar: int) -> void:
	var inset: ZonaAman.Inset = ZonaAman.Inset.new()
	inset.atas = 15
	hud.atur_inset(inset)
	await _tree.process_frame
	await _tree.process_frame
	akar.perbarui(0.0)
	check(hud.rect_tombol_jeda() == Rect2(17, 15, 42, 42), "inset atas 15: area sentuh jeda turun 11 ke (17, 15), dapat %s" % hud.rect_tombol_jeda())
	check(hud.rect_radar_seberang() == Rect2(4, 21, 12, 161) and hud.rect_radar_dekat() == Rect2(lebar - 16, 21, 12, 161), "inset atas 15: kedua radar mulai y 21 (10 + 11), bawah tetap 182, dapat %s / %s" % [hud.rect_radar_seberang(), hud.rect_radar_dekat()])
	check(hud.rect_panel_progres().position.y == 19.0 and hud.rect_panel_progres().size.x == 260.0, "inset atas 15: panel progres turun ke y 19 (8 + 11), dapat %s" % hud.rect_panel_progres())
	check(hud.rect_panel_skor().position.y == 19.0 and hud.rect_panel_koin().position.y == 19.0 and hud.rect_panel_skor().end.x == float(lebar - 28), "inset atas 15: panel koin dan skor turun ke y 19, tepi kanan tetap 28, dapat %s / %s" % [hud.rect_panel_koin(), hud.rect_panel_skor()])
	check(hud.rect_tombol_bel() == Rect2(lebar - 84, 276, 40, 40) and hud.rect_panel_kecepatan().end.y == 352.0 and akar.kontrol_router().geser_bel == Vector2.ZERO, "inset atas 15: tombol bel, panel bawah, dan zona bel tidak bergeser")
	var atas: Array = [["tombol jeda", hud.rect_tombol_jeda()], ["radar seberang", hud.rect_radar_seberang()], ["radar dekat", hud.rect_radar_dekat()], ["panel progres", hud.rect_panel_progres()], ["panel koin", hud.rect_panel_koin()], ["panel skor", hud.rect_panel_skor()]]
	for i: int in range(atas.size()):
		var a: Rect2 = atas[i][1]
		check(a.position.y >= 15.0, "inset atas 15: %s tidak masuk inset atas (%s)" % [atas[i][0], a])
		for j: int in range(i + 1, atas.size()):
			check(not a.intersects(atas[j][1], true), "inset atas 15: %s dan %s tidak bertumpuk" % [atas[i][0], atas[j][0]])
	hud.atur_inset(null)
	await _tree.process_frame
	akar.perbarui(0.0)
	check(hud.rect_tombol_jeda() == Rect2(17, 4, 42, 42) and hud.rect_radar_seberang() == Rect2(4, 10, 12, 172) and hud.rect_panel_progres().position.y == 8.0, "inset atas kembali nol: tata letak semula")


## Event sentuh layar (jendela x3) untuk jari `index` di `posisi_viewport` (koordinat viewport game).
func _sentuh_layar(index: int, posisi_viewport: Vector2, tekan: bool) -> void:
	var peristiwa: InputEventScreenTouch = InputEventScreenTouch.new()
	peristiwa.index = index
	peristiwa.position = posisi_viewport * 3.0
	peristiwa.pressed = tekan
	Input.parse_input_event(peristiwa)
	Input.flush_buffered_events()


## Event geser layar (jendela x3) untuk jari `index` ke `posisi_viewport` (koordinat viewport game).
func _geser_layar(index: int, posisi_viewport: Vector2) -> void:
	var peristiwa: InputEventScreenDrag = InputEventScreenDrag.new()
	peristiwa.index = index
	peristiwa.position = posisi_viewport * 3.0
	Input.parse_input_event(peristiwa)
	Input.flush_buffered_events()
