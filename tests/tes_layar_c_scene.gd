class_name TesLayarCScene
extends RefCounted
## Tes scene layar jeda, tutorial, banner, dan HUD rute tata ulang (run ui2-semua-layar bagian C, AC-4 sampai AC-7; V-9): `scenes/ui/layar_jeda.tscn`, `tutorial.tscn`, `panel_akhir_rute.tscn` sendiri dan `scenes/rute/rute.tscn`
## di lebar 640, 667, 780, dan 800. Jeda: panel 232 di tengah, tombol >= 42x84 di dalam panel, Lanjut peran utama, sakelar berganti teks, bingkai, dan kenop, lapisan alpha 72 %. Tutorial: label dan titik langkah, glif per
## langkah, Lewati peran tenang. Banner: glif status dan tombol Main lagi peran utama, label "PELANGGAN:" di gelembung petunjuk. HUD: kecepatan dan stamina berdampingan (bar 9 tinggi sejajar, kolom di dalam panel),
## panel bawah sama tinggi (<= 40), tanda ambang ngebut 90 %, stamina FAIL di bawah 30, reputasi di panel baris 2, tidak ada tumpang tindih (kanan, kidal, inset; keadaan terpadat), sentuhan tetap lolos ke router. Harapan literal dari
## kanvas dan SPEC V-9. Tidak menyentuh `user://save.json`.

const BERKAS_JEDA: String = "res://scenes/ui/layar_jeda.tscn"
const BERKAS_TUTORIAL: String = "res://scenes/ui/tutorial.tscn"
const BERKAS_BANNER: String = "res://scenes/ui/panel_akhir_rute.tscn"
const BERKAS_RUTE: String = "res://scenes/rute/rute.tscn"
## [lebar jendela, tinggi jendela, lebar viewport game].
const JENDELA: Array = [[1920, 1080, 640], [2001, 1080, 667], [2340, 1080, 780], [2400, 1080, 800]]
const DT: float = 1.0 / 60.0

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
	for j: Array in JENDELA:
		await _test_jeda(j)
	await _test_jeda_sakelar()
	for j: Array in JENDELA:
		await _test_tutorial(j)
	await _test_banner_akhir()
	for j: Array in JENDELA:
		for kidal: bool in [false, true]:
			for inset: bool in [false, true]:
				await _test_hud(j, kidal, inset)
	await _test_hud_isi()
	await _test_gelembung_petunjuk()
	await _test_sentuhan_panel_bawah()


# --- Pembantu ---

func _pasang(jendela: Array, berkas: String) -> Node:
	_tree.root.size = Vector2i(jendela[0], jendela[1])
	var simpul: Node = (load(berkas) as PackedScene).instantiate()
	_tree.root.add_child(simpul)
	await _tree.process_frame
	await _tree.process_frame
	return simpul


func _lepas(simpul: Node) -> void:
	_tree.root.remove_child(simpul)
	simpul.free()


func _rute(jendela: Array, kidal: bool = false, inset: bool = false) -> RuteMain:
	_tree.root.size = Vector2i(jendela[0], jendela[1])
	var akar: RuteMain = (load(BERKAS_RUTE) as PackedScene).instantiate() as RuteMain
	akar.atur_misi(PemuatMisi.muat_folder().cari("p1_kucing"))
	_tree.root.add_child(akar)
	await _tree.process_frame
	await _tree.process_frame
	akar.set_process(false)
	(akar.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = false
	(akar.find_child("LoperAgen", true, false) as LoperSprite).set_process(false)
	if inset:
		var i: ZonaAman.Inset = ZonaAman.Inset.new()
		i.awal_x = 10
		i.atas = 14
		i.akhir_x = 11
		i.bawah = 20
		akar.hud_rute().atur_inset(i)
	akar.atur_kidal(kidal)
	akar.perbarui(0.0)
	await _tree.process_frame
	return akar


func _bersihkan_rute(akar: RuteMain) -> void:
	for i: int in range(8):
		_sentuh(i, Vector2(-50, -50), false)
	if akar.sedang_jeda():
		akar.minta_lanjut()
	(akar.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = OS.has_feature("editor")
	_tree.root.remove_child(akar)
	akar.free()


func _sentuh(index: int, posisi_viewport: Vector2, tekan: bool) -> void:
	var peristiwa: InputEventScreenTouch = InputEventScreenTouch.new()
	peristiwa.index = index
	peristiwa.position = posisi_viewport * 3.0
	peristiwa.pressed = tekan
	Input.parse_input_event(peristiwa)
	Input.flush_buffered_events()


func _lebar_teks(tombol: Button) -> float:
	var font: Font = tombol.get_theme_font(&"font")
	return font.get_string_size(tombol.tr(tombol.text), HORIZONTAL_ALIGNMENT_LEFT, -1, tombol.get_theme_font_size(&"font_size")).x


# --- Jeda ---

func _test_jeda(j: Array) -> void:
	var lebar: int = j[2]
	var tag: String = "jeda %d" % lebar
	_judul.call("Layar jeda %s: panel 232 di tengah, tombol >= 42x84 di dalam panel, Lanjut peran utama, lapisan 72 %% (AC-4, V-2)" % tag)
	var layar: LayarJeda = await _pasang(j, BERKAS_JEDA) as LayarJeda
	layar.tampilkan(true)
	await _tree.process_frame
	await _tree.process_frame
	var viewport: Rect2 = Rect2(Vector2.ZERO, layar.get_viewport().get_visible_rect().size)
	var panel: Rect2 = layar.rect_panel()
	check(viewport.size == Vector2(lebar, 360), "%s: viewport %dx360" % [tag, lebar])
	check(panel.size.x == 232.0 and absf(panel.get_center().x - viewport.get_center().x) <= 0.5 and absf(panel.get_center().y - viewport.get_center().y) <= 1.0 and viewport.encloses(panel), "%s: panel lebar 232 di tengah layar, dapat %s" % [tag, panel])
	var latar: ColorRect = layar.find_child("Latar", true, false) as ColorRect
	check(is_equal_approx(latar.color.a, 0.72) and Color(latar.color, 1.0) == Color(Palette.HUD_PANEL, 1.0) and latar.get_global_rect().size == viewport.size, "%s: lapisan HUD_PANEL alpha 0,72 menutup seluruh layar" % tag)
	var tombol: Array = [["lanjut", layar.rect_tombol_lanjut()], ["kidal", layar.rect_sakelar_kidal()], ["bantu", layar.rect_sakelar_bantu()]]
	for i: int in range(tombol.size()):
		var r: Rect2 = tombol[i][1]
		check(r.size.y >= 42.0 and r.size.x >= 84.0 and panel.encloses(r), "%s: tombol %s %s >= 42 tinggi, >= 84 lebar, di dalam panel" % [tag, tombol[i][0], r.size])
		for k: int in range(i + 1, tombol.size()):
			check(not r.intersects(tombol[k][1]), "%s: tombol %s dan %s tidak bertumpuk" % [tag, tombol[i][0], tombol[k][0]])
	check(layar.rect_tombol_lanjut().size.x == 216.0 and layar.rect_sakelar_kidal().size.x == 216.0 and layar.rect_sakelar_bantu().position.y - layar.rect_sakelar_kidal().end.y == 6.0 and layar.rect_sakelar_kidal().position.y - layar.rect_tombol_lanjut().end.y == 17.0, "%s: tombol selebar isi panel (216), jarak 6 antar sakelar dan 6 + 5 (garis pemisah 1 + margin 2 + 2) + 6 dari Lanjut" % tag)
	var lanjut: Button = layar.tombol_lanjut()
	var gaya: StyleBoxTexture = lanjut.get_theme_stylebox(&"normal") as StyleBoxTexture
	check(gaya != null and gaya.texture == GayaHud.tekstur("btn_utama") and lanjut.get_theme_color(&"font_color") == Palette.UI_BG, "%s: Lanjut peran utama (bingkai ACCENT, teks gelap)" % tag)
	check(lanjut.icon == GayaHud.tekstur("glif_lanjut_gelap") and lanjut.icon_alignment == HORIZONTAL_ALIGNMENT_RIGHT and lanjut.text == "JEDA_LANJUT", "%s: glif Lanjut gelap di ujung akhir, teks kunci JEDA_LANJUT" % tag)
	var ikon: TextureRect = layar.find_child("IkonJudul", true, false) as TextureRect
	var judul: Label = layar.find_child("JudulJeda", true, false) as Label
	check(ikon.texture == GayaHud.tekstur("glif_jeda_terang") and ikon.get_global_rect().end.x <= judul.get_global_rect().position.x + 0.5 and panel.encloses(ikon.get_global_rect()) and panel.encloses(judul.get_global_rect()), "%s: glif jeda di kiri judul, keduanya di dalam panel" % tag)
	var penerima: Array[String] = []
	for node: Node in layar.find_children("*", "Control", true, false):
		var c: Control = node as Control
		if c.mouse_filter != Control.MOUSE_FILTER_IGNORE and not (c is TombolSentuh) and c.name != &"Latar" and c.name != &"PanelJeda":
			penerima.append(String(c.name))
	check(penerima.is_empty(), "%s: hanya tombol, panel, dan lapisan yang menerima sentuhan: %s" % [tag, penerima])
	# Teks sakelar tidak terpotong: lebar teks muat di antara tepi isi dan kenop.
	for pasang: Array in [[layar.sakelar_kidal(), layar.rect_kenop_kidal(), layar.rect_sakelar_kidal()], [layar.sakelar_bantu(), layar.rect_kenop_bantu(), layar.rect_sakelar_bantu()]]:
		var r_tombol: Rect2 = pasang[2]
		var r_kenop: Rect2 = pasang[1]
		check(r_tombol.encloses(r_kenop) and r_kenop.size == Vector2(22, 12) and _lebar_teks(pasang[0] as Button) <= r_kenop.position.x - r_tombol.position.x - 12.0, "%s: kenop 22x12 di dalam tombol, teks '%s' muat di sebelah kirinya" % [tag, (pasang[0] as Button).text])
	_lepas(layar)


func _test_jeda_sakelar() -> void:
	_judul.call("Layar jeda: sakelar membalik teks, bingkai, dan kenop; status terbaca tanpa warna; sinyal dan atur_* sama dengan sebelumnya (AC-4, V-5)")
	var layar: LayarJeda = await _pasang(JENDELA[2], BERKAS_JEDA) as LayarJeda
	layar.tampilkan(true)
	await _tree.process_frame
	var catatan: Array = []
	layar.kidal_diubah.connect(func(n: bool) -> void: catatan.append(["kidal", n]))
	layar.bantu_diubah.connect(func(n: bool) -> void: catatan.append(["bantu", n]))
	var kidal: Button = layar.sakelar_kidal()
	var bantu: Button = layar.sakelar_bantu()
	check(kidal.text == "JEDA_KIDAL_MATI" and bantu.text == "HUD_BANTU_MATI" and not layar.kenop_kidal().nyala and not layar.kenop_bantu().nyala, "bawaan mati: teks, kenop")
	check((kidal.get_theme_stylebox(&"normal") as StyleBoxTexture).texture == GayaHud.tekstur("btn_biasa") and kidal.get_theme_color(&"font_color") == Palette.TEXT, "sakelar mati: bingkai biasa, teks TEXT")
	var kenop_mati: Array = layar.kenop_kidal().perintah_tampil()
	kidal.ditekan.emit()
	await _tree.process_frame
	check(catatan == [["kidal", true]] and kidal.text == "JEDA_KIDAL_NYALA" and tr(kidal.text) == "Kidal: nyala" and layar.kenop_kidal().nyala and not layar.kenop_bantu().nyala, "ketuk kidal: sinyal kidal_diubah(true), teks 'Kidal: nyala', kenop kidal nyala saja")
	check((kidal.get_theme_stylebox(&"normal") as StyleBoxTexture).texture == GayaHud.tekstur("btn_sakelar_nyala"), "sakelar nyala: bingkai ACCENT (btn_sakelar_nyala)")
	check(layar.kenop_kidal().perintah_tampil() != kenop_mati and layar.kenop_kidal().perintah_tampil() == TampilJeda.perintah_kenop(true), "kenop kidal nyala menggambar pola nyala, berbeda dari mati")
	bantu.ditekan.emit()
	await _tree.process_frame
	check(catatan == [["kidal", true], ["bantu", true]] and tr(bantu.text) == "Bantu: nyala" and layar.kenop_bantu().nyala, "ketuk bantu: sinyal bantu_diubah(true), teks 'Bantu: nyala', kenop nyala")
	kidal.ditekan.emit()
	check(catatan.back() == ["kidal", false] and tr(kidal.text) == "Kidal: mati" and not layar.kenop_kidal().nyala and layar.kenop_kidal().perintah_tampil() == kenop_mati, "ketuk kidal lagi: kembali mati, gambar kenop kembali persis")
	catatan.clear()
	layar.atur_kidal(true)
	layar.atur_bantu(false)
	check(catatan.is_empty() and kidal.text == "JEDA_KIDAL_NYALA" and bantu.text == "HUD_BANTU_MATI" and layar.kenop_kidal().nyala and not layar.kenop_bantu().nyala, "atur_kidal/atur_bantu menyamakan tampilan tanpa sinyal")
	var lanjut_n: Array[int] = [0]
	layar.lanjut_diminta.connect(func() -> void: lanjut_n[0] += 1)
	layar.tombol_lanjut().ditekan.emit()
	check(lanjut_n[0] == 1, "Lanjut memancarkan lanjut_diminta sekali")
	_lepas(layar)


# --- Tutorial ---

func _test_tutorial(j: Array) -> void:
	var lebar: int = j[2]
	var tag: String = "tutorial %d" % lebar
	_judul.call("Tutorial %s: label dan titik langkah, glif per langkah, Lewati peran tenang, tidak menelan sentuhan (AC-5)" % tag)
	var tut: TutorialController = await _pasang(j, BERKAS_TUTORIAL) as TutorialController
	var urutan: Array = [TutorialLangkah.Langkah.KAYUH, TutorialLangkah.Langkah.MELAMBAT, TutorialLangkah.Langkah.LEMPAR, TutorialLangkah.Langkah.MENEPI]
	for ada_misi: bool in [true, false]:
		var total: int = 4 if ada_misi else 3
		for i: int in range(total):
			var k: TutorialLangkah.Keadaan = TutorialLangkah.awal(true, ada_misi)
			k.langkah = urutan[i]
			if ada_misi and urutan[i] == TutorialLangkah.Langkah.MENEPI:
				k.menepi_terlihat = true
			tut.tampilkan_langkah(k)
			await _tree.process_frame
			await _tree.process_frame
			var nomor: Vector2i = TutorialLangkah.nomor(k)
			check(tut.tampil() and tut.teks_langkah() == "PETUNJUK %d/%d" % [nomor.x, nomor.y], "%s langkah %d dari %d: label '%s'" % [tag, nomor.x, nomor.y, tut.teks_langkah()])
			var titik: TitikLangkah = tut.find_child("TitikLangkah", true, false) as TitikLangkah
			var terisi: int = 0
			for p: Array in titik.perintah_tampil():
				if p[1] == Palette.ACCENT:
					terisi += 1
			check(terisi == nomor.x and titik.custom_minimum_size == Vector2(TampilTutorial.lebar_titik(nomor.y), 4), "%s langkah %d dari %d: %d titik terisi (ACCENT), deretan %s" % [tag, nomor.x, nomor.y, nomor.x, titik.custom_minimum_size])
			var ikon: TextureRect = tut.find_child("IkonKalimat", true, false) as TextureRect
			check(ikon.texture == GayaHud.tekstur(TampilTutorial.nama_glif(urutan[i])) and ikon.texture != null, "%s langkah %d: glif %s" % [tag, nomor.x, TampilTutorial.nama_glif(urutan[i])])
			var viewport: Rect2 = Rect2(Vector2.ZERO, tut.get_viewport().get_visible_rect().size)
			var panel: Rect2 = tut.rect_panel()
			check(viewport.encloses(panel) and panel.position == Vector2(26, 88) and panel.size.x == 176.0, "%s langkah %d: panel (26, 88) lebar 176 di dalam layar, dapat %s" % [tag, nomor.x, panel])
			for label: Label in [tut.find_child("LabelLangkahTutorial", true, false) as Label, tut.find_child("TeksTutorial", true, false) as Label]:
				check(panel.encloses(label.get_global_rect()) and label.get_global_rect().size.x + 0.5 >= label.get_minimum_size().x, "%s langkah %d: label '%s' di dalam panel dan tidak terpotong" % [tag, nomor.x, label.text])
	var lewati: Button = tut.tombol_lewati()
	var gaya: StyleBoxTexture = lewati.get_theme_stylebox(&"normal") as StyleBoxTexture
	var r: Rect2 = tut.rect_lewati()
	check(gaya != null and gaya.texture == GayaHud.tekstur("btn_tenang") and lewati.get_theme_color(&"font_color") == Palette.TEXT_2, "%s: Lewati peran tenang (rata, teks TEXT_2)" % tag)
	check(r == Rect2(66, 4, 64, 42), "%s: Lewati (66, 4) 64x42 (pengecualian tertulis DESIGN_SPEC 3.1: di luar zona kontrol), dapat %s" % [tag, r])
	check(tut.kontrol_penerima_sentuhan().size() == 1 and tut.kontrol_penerima_sentuhan()[0] == lewati, "%s: hanya Lewati yang menerima sentuhan" % tag)
	_lepas(tut)


# --- Banner ---

func _test_banner_akhir() -> void:
	_judul.call("Banner Rute selesai dan galat muat: glif status, tombol Main lagi peran utama, di tengah atas, tidak menerima sentuhan (AC-5)")
	for j: Array in JENDELA:
		var tag: String = "banner %d" % j[2]
		var banner: PanelAkhirRute = await _pasang(j, BERKAS_BANNER) as PanelAkhirRute
		var viewport: Rect2 = Rect2(Vector2.ZERO, banner.get_viewport().get_visible_rect().size)
		banner.tampilkan(true)
		await _tree.process_frame
		await _tree.process_frame
		var ikon: TextureRect = banner.find_child("IkonBanner", true, false) as TextureRect
		check(banner.teks_banner() == "Rute selesai" and ikon.texture == GayaHud.tekstur("glif_centang_ok") and not banner.tombol_tampil(), "%s: Rute selesai dengan centang OK, tanpa tombol" % tag)
		var r: Rect2 = banner.rect_banner()
		check(viewport.encloses(r) and absf(r.get_center().x - viewport.get_center().x) <= 0.5 and r.position.y == float(Config.RUTE_BANNER_MARGIN_ATAS_PX) and r.size.y >= 29.0 and r.size.y <= 31.0, "%s: banner di tengah atas y 64 setinggi sekitar 30, dapat %s" % [tag, r])
		banner.tampilkan_galat()
		await _tree.process_frame
		await _tree.process_frame
		check(banner.teks_banner() == "Rute gagal dimuat" and ikon.texture == GayaHud.tekstur("glif_seru_warn") and banner.tombol_tampil(), "%s: galat muat dengan tanda seru WARN dan tombol Main lagi" % tag)
		var t: Rect2 = banner.rect_tombol()
		var gaya: StyleBoxTexture = (banner.find_child("TombolUlang", true, false) as Button).get_theme_stylebox(&"normal") as StyleBoxTexture
		check(gaya.texture == GayaHud.tekstur("btn_utama") and t.size.y >= 42.0 and t.size.x >= 84.0 and banner.rect_banner().encloses(t) and viewport.encloses(banner.rect_banner()), "%s: Main lagi peran utama >= 84x42 di dalam banner, dapat %s" % [tag, t])
		check((banner.find_child("Banner", true, false) as Control).mouse_filter == Control.MOUSE_FILTER_IGNORE and (banner.find_child("BarisJudul", true, false) as Control).mouse_filter == Control.MOUSE_FILTER_IGNORE, "%s: banner tidak menerima sentuhan (hanya tombol Main lagi)" % tag)
		_lepas(banner)


# --- HUD ---

func _keadaan_terpadat(akar: RuteMain) -> void:
	var hud: HudRute = akar.hud_rute()
	var k: KondisiRute.Keadaan = KondisiRute.Keadaan.new()
	k.kondisi = {"ban": 0.2, "rem": 0.3, "rantai": 0.0}
	k.kedip = {"rem": 1.0}
	hud.tampilkan_kondisi(k)
	hud.tampilkan_reputasi(100)
	hud.tampilkan_skor(1234567, 12, 987654, false)
	hud.tampilkan_kecepatan(5.4)
	hud.tampilkan_stamina(12.0, true)
	hud.tampilkan_koran(0, Config.KORAN_AWAL)


func _test_hud(j: Array, kidal: bool, inset: bool) -> void:
	var lebar: int = j[2]
	var tag: String = "hud %d %s %s" % [lebar, "kidal" if kidal else "kanan", "inset" if inset else "tanpa inset"]
	_judul.call("HUD rute %s: kecepatan dan stamina berdampingan, panel bawah sama tinggi, kolom kanan dua baris, tanpa tumpang tindih (AC-6, V-9)" % tag)
	var akar: RuteMain = await _rute(j, kidal, inset)
	var hud: HudRute = akar.hud_rute()
	_keadaan_terpadat(akar)
	await _tree.process_frame
	await _tree.process_frame
	var viewport: Rect2 = Rect2(Vector2.ZERO, akar.get_viewport().get_visible_rect().size)
	var geser_bawah: int = 12 if inset else 0
	var geser_kanan: int = 7 if inset else 0
	var geser_atas: int = 10 if inset else 0
	var panel_k: Rect2 = hud.rect_panel_kecepatan()
	var panel_n: Rect2 = hud.rect_panel_koran()
	var bar_k: Rect2 = hud.rect_bar_kecepatan()
	var bar_s: Rect2 = hud.rect_bar_stamina()
	# Dua bar berdampingan, sejajar, setinggi 9; kolom dan label di dalam panel.
	check(bar_k.size.y == 9.0 and bar_s.size.y == 9.0 and bar_k.position.y == bar_s.position.y and bar_s.position.x >= bar_k.end.x + 8.0 - 0.5 and bar_k.size.x == 111.0 and bar_s.size.x == 89.0, "%s: bar kecepatan (111) dan stamina (89) berdampingan, sejajar, tinggi 9: %s | %s" % [tag, bar_k, bar_s])
	check(panel_k.encloses(bar_k) and panel_k.encloses(bar_s) and panel_k.encloses(hud.rect_kolom_kecepatan()) and panel_k.encloses(hud.rect_kolom_stamina()), "%s: kolom dan bar di dalam panel kecepatan" % tag)
	check(panel_k.size == Vector2(220, 39) and panel_n.size == Vector2(115, 39) and panel_k.end.y == panel_n.end.y and panel_k.position.y == panel_n.position.y, "%s: panel kecepatan 220x39 dan koran 115x39 sama tinggi dan sejajar (tinggi <= 40), dapat %s %s" % [tag, panel_k.size, panel_n.size])
	check(panel_k.end.y == float(360 - 8 - geser_bawah), "%s: panel bawah 8 px dari tepi bawah (+ geser inset)" % tag)
	if kidal:
		check(panel_k.end.x == float(lebar - 196) and panel_n.end.x + 8.0 == panel_k.position.x and panel_n.position.x == float(lebar - 196 - 220 - 8 - 115), "%s: kidal dicerminkan: kecepatan berakhir lebar-196, koran di kirinya dengan celah 8" % tag)
	else:
		check(panel_k.position.x == 196.0 and panel_n.position.x == 424.0 and panel_k.end.x + 8.0 == panel_n.position.x, "%s: tangan kanan: kecepatan di x 196, koran di x 424, celah 8" % tag)
	for label: Label in hud.label_bawah():
		if not label.is_visible_in_tree():
			continue
		var wadah: Rect2 = panel_n if label.name in [&"LabelKoran", &"LabelHabis", &"AngkaKoran"] else panel_k
		check(wadah.encloses(label.get_global_rect()) and label.get_global_rect().size.x + 0.5 >= label.get_minimum_size().x, "%s: label '%s' di dalam panel dan tidak terpotong" % [tag, label.text])
	check(hud.label_bawah()[0].get_theme_font_size(&"font_size") == 10 and hud.label_bawah()[1].get_theme_font_size(&"font_size") == 12 and hud.label_bawah()[6].get_theme_font_size(&"font_size") == 12, "%s: label panel bawah 10 px dan angka 12 px (type variation baru)" % tag)
	# Kolom kanan atas: baris 1 koin + skor di y 8 (+ geser), baris 2 panel kondisi + reputasi 5 px di bawahnya.
	var koin: Rect2 = hud.rect_panel_koin()
	var skor: Rect2 = hud.rect_panel_skor()
	var baris2: Rect2 = hud.rect_panel_kondisi()
	check(koin.position.y == float(8 + geser_atas) and skor.position.y == koin.position.y and koin.end.x + 5.0 == skor.position.x and skor.end.x == float(lebar - 28 - geser_kanan), "%s: baris 1 koin lalu skor, rata kanan 28 + geser" % tag)
	check(baris2.position.y == skor.end.y + 5.0 and baris2.end.x == skor.end.x and baris2.size.y == 24.0, "%s: baris 2 tepat 5 px di bawah baris 1, rata kanan, tinggi 24, dapat %s" % [tag, baris2])
	check(hud.reputasi_tampil() and baris2.encloses(hud.rect_panel_reputasi()) and baris2.size.x == 181.0, "%s: reputasi 100 di dalam panel baris 2 selebar 181 (126 + 6 + 14 + 2 + 19 + 14 + 0)" % tag)
	check(baris2.position.y > hud.rect_panel_progres().end.y, "%s: baris 2 di bawah panel progres (secara mendatar boleh sejajar; y %s > %s)" % [tag, baris2.position.y, hud.rect_panel_progres().end.y])
	# Tidak ada tumpang tindih.
	var pusat_bel: Vector2 = TouchZones.pusat_bel(lebar, kidal, akar.kontrol_router().geser_bel)
	var elemen: Array = [["radar seberang", hud.rect_radar_seberang()], ["radar dekat", hud.rect_radar_dekat()], ["panel progres", hud.rect_panel_progres()], ["panel koin", koin], ["panel skor", skor], ["panel baris 2", baris2],
		["tombol jeda", hud.rect_tombol_jeda()], ["zona bel", Rect2(pusat_bel - Vector2(28, 28), Vector2(56, 56))], ["panel kecepatan", panel_k], ["panel koran", panel_n]]
	var stick: Rect2 = TouchZones.rect_stick(lebar, kidal)
	for a: int in range(elemen.size()):
		var r: Rect2 = elemen[a][1]
		check(viewport.encloses(r) and not r.intersects(stick, true), "%s: %s di dalam layar dan di luar zona stick" % [tag, elemen[a][0]])
		for b: int in range(a + 1, elemen.size()):
			check(not r.intersects(elemen[b][1], true), "%s: %s %s dan %s %s tidak bertumpuk" % [tag, elemen[a][0], r, elemen[b][0], elemen[b][1]])
	# Kartu misi, banner misi, dan gelembung petunjuk (satu per waktu) tidak menumpuk elemen mana pun.
	var rencana: RencanaMisi.Rencana = akar.rencana_misi()
	var misi: DataMisi = PemuatMisi.muat_folder().cari("p1_kucing")
	for kasus: Array in [["petunjuk", MissionManager.Status.AKTIF, 2.5, 0.0], ["banner selesai", MissionManager.Status.SELESAI, 0.0, 1.5], ["banner gagal", MissionManager.Status.GAGAL, 0.0, 1.5]]:
		var m: MissionManager.Keadaan = MissionManager.awal(rencana)
		m.status = kasus[1]
		m.petunjuk_sisa = kasus[2]
		m.banner_sisa = kasus[3]
		hud.tampilkan_misi(m, misi)
		await _tree.process_frame
		await _tree.process_frame
		var tambahan: Array = []
		if hud.kartu_tampil():
			tambahan.append(["kartu misi", hud.rect_kartu()])
		if hud.banner_tampil():
			tambahan.append(["banner misi", hud.rect_banner()])
		if hud.petunjuk_tampil():
			tambahan.append(["petunjuk", hud.rect_petunjuk()])
		check(not tambahan.is_empty(), "%s: %s tampil" % [tag, kasus[0]])
		for t: Array in tambahan:
			check(viewport.encloses(t[1]), "%s: %s di dalam layar" % [tag, t[0]])
			for e: Array in elemen:
				check(not (t[1] as Rect2).intersects(e[1], true), "%s: %s %s tidak menumpuk %s %s" % [tag, t[0], t[1], e[0], e[1]])
	_bersihkan_rute(akar)


func _test_hud_isi() -> void:
	_judul.call("HUD rute: tanda ambang ngebut 90 % bar kecepatan, stamina FAIL di bawah 30, reputasi di panel baris 2, tombol jeda tombol biasa (AC-6, V-9)")
	var akar: RuteMain = await _rute(JENDELA[0])
	var hud: HudRute = akar.hud_rute()
	var bar: BarKecepatan = hud.bar_kecepatan()
	var dalam: float = bar.size.x - 2.0
	check(bar.tanda == 0.9 and hud.bar_stamina().tanda == 0.0, "bar kecepatan bertanda 0,9, bar stamina tanpa tanda")
	check(bar.rect_tanda() == Rect2(1.0 + floorf(dalam * 0.9), 0, 1, 9) and bar.rect_tanda().position.x == 99.0, "tanda 90 %: x 99 di bar 111 (1 + floor(109 x 0,9)), 1 px lebar, setinggi bar")
	hud.tampilkan_stamina(29.9, false)
	check(hud.warna_stamina() == Palette.FAIL, "stamina 29,9: FAIL")
	hud.tampilkan_stamina(30.0, false)
	check(hud.warna_stamina() == Palette.ACCENT, "stamina 30: ACCENT")
	hud.tampilkan_stamina(100.0, false)
	check(hud.warna_stamina() == Palette.ACCENT and is_equal_approx(hud.nilai_stamina(), 1.0), "stamina 100: ACCENT, bar penuh")
	hud.tampilkan_kecepatan(6.0)
	check(is_equal_approx(hud.nilai_kecepatan(), 1.0) and hud.label_bawah()[1].text == "6.0 u/d", "kecepatan 6,0: bar penuh, angka '6.0 u/d'")
	# Reputasi: tampil 0 sampai 100, tersembunyi bila negatif, panel baris 2 mengikuti.
	var k: KondisiRute.Keadaan = KondisiRute.Keadaan.new()
	k.kondisi = {"ban": 1.0, "rem": 1.0, "rantai": 1.0}
	hud.tampilkan_kondisi(k)
	hud.tampilkan_reputasi(0)
	check(hud.reputasi_tampil() and hud.teks_reputasi() == "0" and hud.kondisi_tampil(), "reputasi 0 tampil bersama kondisi")
	var lebar_37: float = 0.0
	hud.tampilkan_reputasi(37)
	await _tree.process_frame
	await _tree.process_frame
	lebar_37 = hud.rect_panel_kondisi().size.x
	hud.tampilkan_reputasi(100)
	await _tree.process_frame
	await _tree.process_frame
	check(hud.rect_panel_kondisi().size.x > lebar_37 and hud.rect_panel_kondisi().size.x <= 190.0, "reputasi 100 sedikit lebih lebar dari 37 (%s > %s) dan panel baris 2 <= 190" % [hud.rect_panel_kondisi().size.x, lebar_37])
	hud.tampilkan_reputasi(-1)
	await _tree.process_frame
	await _tree.process_frame
	check(not hud.reputasi_tampil() and hud.kondisi_tampil() and hud.rect_panel_kondisi().size == Vector2(140, 24), "tanpa reputasi: panel baris 2 kembali 140x24 hanya kondisi")
	hud.tampilkan_kondisi(null)
	check(not hud.kondisi_tampil() and not hud.rect_panel_kondisi().has_point(Vector2(-1, -1)) and not (hud.find_child("PanelKondisi", true, false) as Control).visible, "tanpa kondisi dan tanpa reputasi: panel baris 2 tersembunyi")
	hud.tampilkan_reputasi(50)
	await _tree.process_frame
	check((hud.find_child("PanelKondisi", true, false) as Control).visible and not hud.kondisi_tampil() and hud.reputasi_tampil(), "reputasi saja: panel baris 2 tampil, kotak kondisi tersembunyi")
	for nama: String in ["KotakBan", "KotakRem", "KotakRantai"]:
		check(not (hud.find_child(nama, true, false) as Control).visible, "reputasi saja: %s tersembunyi" % nama)
	# Tombol jeda: bingkai tombol biasa, glif jeda terang, tekan = bingkai tekan dan glif turun 2 px.
	var jeda: TombolJeda = hud.find_child("TombolJeda", true, false) as TombolJeda
	check(jeda.tampilan(false) == ["btn_biasa", Vector2i(6, 5)] and jeda.tampilan(true) == ["btn_biasa_tekan", Vector2i(6, 7)], "tombol jeda: bingkai biasa dan glif (6, 5); ditekan bingkai tekan dan glif (6, 7)")
	check(jeda.bingkai(false).texture == GayaHud.tekstur("btn_biasa") and jeda.bingkai(true).texture == GayaHud.tekstur("btn_biasa_tekan") and jeda.glif() == GayaHud.tekstur("glif_jeda_terang"), "tombol jeda menggambar bingkai biasa (ditekan: bingkai tekan) dan glif jeda terang")
	check(jeda.rect_gambar() == Rect2(26, 8, 24, 24) and hud.rect_tombol_jeda() == Rect2(17, 4, 42, 42), "tombol jeda: gambar 24x24 di (26, 8), area sentuh 42x42 di (17, 4) tidak berubah")
	check(jeda.text.is_empty() and jeda.icon == null, "tombol jeda tanpa teks dan tanpa Button.icon (digambar dari bingkai dan glif)")
	_bersihkan_rute(akar)


func _test_gelembung_petunjuk() -> void:
	_judul.call("Gelembung petunjuk dari pelanggan: label 'PELANGGAN:' (kunci baru) di depan kalimat, lebar baris tetap 170 (AC-5, V-3)")
	for j: Array in JENDELA:
		var akar: RuteMain = await _rute(j)
		var hud: HudRute = akar.hud_rute()
		var m: MissionManager.Keadaan = MissionManager.awal(akar.rencana_misi())
		m.petunjuk_sisa = 2.5
		hud.tampilkan_misi(m, PemuatMisi.muat_folder().cari("p1_kucing"))
		await _tree.process_frame
		await _tree.process_frame
		var label: Label = hud.find_child("LabelPelanggan", true, false) as Label
		var teks: Label = hud.find_child("TeksPetunjuk", true, false) as Label
		var panel: Rect2 = hud.rect_petunjuk()
		check(label.text == "MISI_PETUNJUK_LABEL" and tr(label.text) == "PELANGGAN:" and hud.teks_petunjuk() == "Tadi ada kucing lewat ke arah warung", "%d: label PELANGGAN: dan kalimat petunjuk dari konten (tidak berubah)" % j[2])
		check(label.get_global_rect().end.x <= teks.get_global_rect().position.x and panel.encloses(label.get_global_rect()) and panel.encloses(teks.get_global_rect()) and label.get_theme_color(&"font_color") == Palette.TEXT_2, "%d: label di kiri kalimat, keduanya di dalam gelembung, label TEXT_2" % j[2])
		check(panel.size.x == 184.0 and panel.size.y <= 34.0 and panel.position.y == float(Config.MISI_BANNER_Y_PX), "%d: gelembung selebar 184 (170 + 14) setinggi <= 34 di y 50 (sama dengan sebelum), dapat %s" % [j[2], panel])
		check(hud.petunjuk_tampil() and label.mouse_filter == Control.MOUSE_FILTER_IGNORE and teks.mouse_filter == Control.MOUSE_FILTER_IGNORE, "%d: gelembung tidak menerima sentuhan" % j[2])
		_bersihkan_rute(akar)


func _test_sentuhan_panel_bawah() -> void:
	_judul.call("Sentuhan di panel bawah tetap sampai ke router: jari di tengah panel koran menjadi swipe, jari di tengah panel kecepatan menjadi stick atau swipe menurut zona (AC-6)")
	for j: Array in JENDELA:
		var lebar: int = j[2]
		var akar: RuteMain = await _rute(j)
		var hud: HudRute = akar.hud_rute()
		var router: TouchRouter = akar.kontrol_router()
		for pasang: Array in [["koran", hud.rect_panel_koran()], ["kecepatan", hud.rect_panel_kecepatan()]]:
			var titik: Vector2 = (pasang[1] as Rect2).get_center()
			var zona: TouchZones.Zona = TouchZones.zona_di(titik, lebar, false, akar.kontrol_router().geser_bel)
			_sentuh(5, titik, true)
			var harapan_swipe: bool = zona == TouchZones.Zona.SWIPE
			var harapan_stick: bool = zona == TouchZones.Zona.STICK
			check(router.swipe_aktif() == harapan_swipe and router.stick_aktif() == harapan_stick, "%d: jari di tengah panel %s %s (zona %d): swipe %s stick %s" % [lebar, pasang[0], titik, zona, harapan_swipe, harapan_stick])
			_sentuh(5, titik, false)
		check(pasang_tidak_menangkap(hud), "%d: tidak ada kontrol HUD selain tombol jeda yang menerima sentuhan GUI" % lebar)
		_bersihkan_rute(akar)


func pasang_tidak_menangkap(hud: HudRute) -> bool:
	for node: Node in hud.find_children("*", "Control", true, false):
		var c: Control = node as Control
		if c.mouse_filter != Control.MOUSE_FILTER_IGNORE and not (c is TombolJeda):
			return false
	return true
