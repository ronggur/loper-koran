class_name TesBengkelTataC
extends RefCounted
## Tes layar bengkel tata C di scene (run ui1-komponen-bengkel bagian B, AC-6 sampai AC-9): `scenes/bengkel/bengkel.tscn` dengan state tulisan tes dan data upgrade nyata (`upgrades.json`) atau data uji bertingkat.
## Keadaan a sampai g dari kanvas (hari pertama, ada rusak, saldo kurang, sesudah beli, terpadat, galat data, inset aman), tingkat upgrade I, II, III (model tampilan, data uji), tombol nonaktif, ukuran minimum
## tombol (>= 42 tinggi dan >= 84 lebar), tanpa teks terpotong, tanpa tumpang tindih, chip di dalam kartu dan panggung sepeda, tanpa scroll, zona aman, enam ukuran jendela (lebar 640, 667, 700, 780, 800 dan 1600x720),
## dan kontras token teks (>= 7:1) di atas isi bingkai yang terpasang. Harga literal dihitung tangan dari BALANCING 7 dan 8.5 (ban 120, rem 80, rantai 150; ongkos naik x1,25 untuk dua rusak, x1,5 untuk tiga).

const BERKAS_BENGKEL: String = "res://scenes/bengkel/bengkel.tscn"
## [lebar jendela, tinggi jendela, lebar viewport game].
const JENDELA: Array = [[1920, 1080, 640], [2001, 1080, 667], [2100, 1080, 700], [2340, 1080, 780], [2400, 1080, 800], [1600, 720, 800]]

var _cek: Callable
var _judul: Callable
var _tree: SceneTree
var _toko: PemuatToko.Kumpulan = PemuatToko.muat()


func _init(cek: Callable, judul: Callable, tree: SceneTree) -> void:
	_cek = cek
	_judul = judul
	_tree = tree


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_test_kontras_token()
	await _test_keadaan_a()
	await _test_keadaan_b()
	await _test_keadaan_c()
	await _test_keadaan_d()
	await _test_keadaan_e()
	await _test_keadaan_f()
	await _test_keadaan_g()
	await _test_tombol_nonaktif_gaya()
	await _test_tingkat_bertingkat()
	await _test_tingkat_bertingkat_tata_letak()
	for jendela: Array in JENDELA:
		for inset_pakai: bool in [false, true]:
			await _test_tata_letak(jendela, inset_pakai, true)
	await _test_hari_berikutnya_dan_back()


# --- Pembantu ---

func _state(koin: int, ban: float = 1.0, rem: float = 1.0, rantai: float = 1.0, level: Array = [0, 0, 0]) -> Dictionary:
	var s: Dictionary = DataSave.templat()
	s["koin"] = koin
	s["koin_total"] = koin
	var sepeda: Dictionary = s["sepeda"]
	var daftar: Array = [ban, rem, rantai]
	for i: int in range(3):
		var entri: Dictionary = sepeda[Config.KONDISI_KOMPONEN[i]]
		entri["kondisi"] = daftar[i]
		entri["level"] = level[i]
	return s


func _bengkel(state: Dictionary, jendela: Vector2i = Vector2i(1920, 1080), toko: PemuatToko.Kumpulan = null, inset: ZonaAman.Inset = null) -> LayarBengkel:
	_tree.root.size = jendela
	var layar: LayarBengkel = (load(BERKAS_BENGKEL) as PackedScene).instantiate() as LayarBengkel
	_tree.root.add_child(layar)
	await _tree.process_frame
	if inset != null:
		layar.atur_inset(inset)
	layar.isi(state, toko if toko != null else _toko)
	await _tree.process_frame
	await _tree.process_frame
	await _tree.process_frame
	return layar


func _buang(layar: LayarBengkel) -> void:
	_tree.root.remove_child(layar)
	layar.free()


func _luminans(w: Color) -> float:
	var kanal: Array[float] = []
	for c: float in [w.r, w.g, w.b]:
		kanal.append(c / 12.92 if c <= 0.03928 else pow((c + 0.055) / 1.055, 2.4))
	return 0.2126 * kanal[0] + 0.7152 * kanal[1] + 0.0722 * kanal[2]


func _kontras(a: Color, b: Color) -> float:
	var la: float = _luminans(a)
	var lb: float = _luminans(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func _piksel(nama: String, x: int, y: int) -> Color:
	return GayaHud.tekstur(nama).get_image().get_pixel(x, y)


func _jenis_kartu(panel: PanelContainer) -> Texture2D:
	return (panel.get_theme_stylebox(&"panel") as StyleBoxTexture).texture


# --- Kontras token (deterministik dari tekstur terpasang) ---

func _test_kontras_token() -> void:
	_judul.call("Bengkel tata C: kontras teks >= 7:1 di atas isi bingkai terpasang (chip, tombol, kartu, panel layar) dari token Palette (AC-9)")
	for gaya: int in KomponenUi.GayaChip.values():
		var isi: Color = _piksel(KomponenUi.nama_tekstur_chip(gaya), 4, 4)
		var teks: Color = KomponenUi.warna_teks_chip(gaya)
		check(_kontras(teks, isi) >= 7.0, "chip %s: teks di atas isi %s kontras %.2f >= 7" % [gaya, isi.to_html(false), _kontras(teks, isi)])
	check(KomponenUi.warna_teks_chip(KomponenUi.GayaChip.GELAP) == Palette.TEXT and KomponenUi.warna_teks_chip(KomponenUi.GayaChip.OK) == Palette.OK and KomponenUi.warna_teks_chip(KomponenUi.GayaChip.WARN) == Palette.WARN and KomponenUi.warna_teks_chip(KomponenUi.GayaChip.NETRAL) == Palette.TEXT_2 and KomponenUi.warna_teks_chip(KomponenUi.GayaChip.AKSEN) == Palette.ACCENT, "warna teks chip: GELAP TEXT, OK OK, WARN WARN, NETRAL TEXT_2, AKSEN ACCENT (literal kanvas ui.css)")
	check(_kontras(KomponenUi.warna_teks_tombol(KomponenUi.Peran.UTAMA, KomponenUi.KeadaanTombol.NORMAL), _piksel("btn_utama", 6, 8)) >= 7.0, "tombol utama: teks gelap di atas isi ACCENT >= 7")
	check(_kontras(KomponenUi.warna_teks_tombol(KomponenUi.Peran.BIASA, KomponenUi.KeadaanTombol.NORMAL), _piksel("btn_biasa", 6, 8)) >= 7.0, "tombol biasa: teks TEXT di atas isinya >= 7")
	check(_kontras(KomponenUi.warna_teks_tombol(KomponenUi.Peran.BIASA, KomponenUi.KeadaanTombol.DITEKAN), _piksel("btn_biasa_tekan", 6, 8)) >= 7.0, "tombol biasa ditekan: teks ACCENT di atas isinya >= 7")
	var arsir: Image = GayaHud.tekstur("arsir_nonaktif").get_image()
	var terburuk: float = 99.0
	for y: int in range(arsir.get_height()):
		for x: int in range(arsir.get_width()):
			terburuk = minf(terburuk, _kontras(Palette.TEXT_2, arsir.get_pixel(x, y)))
	check(terburuk >= 7.0, "tombol nonaktif: teks TEXT_2 di atas piksel arsir terburuk kontras %.2f >= 7" % terburuk)
	for nama: String in ["kartu_biasa", "kartu_menonjol", "kartu_redup", "panel_layar"]:
		var isi: Color = _piksel(nama, 6, 6)
		# WARN di atas UI_PANEL = 6,91:1 (< 7), jadi tidak dipakai sebagai warna teks di atas kartu dan panel (status "Perlu servis" dan galat memakai TEXT; "!" dan bingkai yang berwarna WARN).
		for teks: Color in [Palette.TEXT, Palette.TEXT_2, Palette.ACCENT]:
			check(_kontras(teks, isi) >= 7.0, "%s: teks %s di atas isi %s >= 7 (%.2f)" % [nama, teks.to_html(false), isi.to_html(false), _kontras(teks, isi)])
	check(_kontras(Palette.ACCENT, Palette.HUD_PANEL.blend(Palette.UI_BG)) >= 7.0 and _kontras(Palette.TEXT_2, Palette.UI_PANEL) >= 7.0, "judul bagian (ACCENT di atas pelat HUD_PANEL) dan TEXT_2 di atas UI_PANEL >= 7")


# --- Keadaan a sampai g ---

func _kartu_jenis(layar: LayarBengkel, id: String) -> KomponenUi.JenisKartu:
	return layar.kartu_servis(id).info.kartu


func _test_keadaan_a() -> void:
	_judul.call("Bengkel tata C keadaan a (hari pertama, saldo 375): tiga kartu redup bertanda 'Baik' tanpa tombol, sepeda bersih tanpa penanda, tiga upgrade 'Koin kurang' (AC-7a)")
	var layar: LayarBengkel = await _bengkel(_state(375))
	for id: String in Config.KONDISI_KOMPONEN:
		var kartu: LayarBengkel.KartuServis = layar.kartu_servis(id)
		check(_kartu_jenis(layar, id) == KomponenUi.JenisKartu.REDUP and _jenis_kartu(kartu.panel) == GayaHud.tekstur("kartu_redup") and kartu.chip_baik.visible and not kartu.tombol.visible and not kartu.chip_harga.visible, "%s: kartu redup (tekstur kartu_redup), chip Baik, tanpa tombol dan harga" % id)
		check(not layar.panggung().chip_tampil(id) and layar.panggung().rect_titik_global(id) == Rect2(), "%s: sepeda bersih, tanpa chip dan tanpa titik penanda" % id)
		check(kartu.label_baik.get_theme_color(&"font_color") == Palette.OK and absf(kartu.chip_baik.get_global_rect().size.y - 18.0) < 0.5, "%s: chip Baik bertulisan hijau OK setinggi 18" % id)
	for id: String in ["ban_anti_selip", "rem_pakem", "rantai_hemat"]:
		var tombol: TombolSentuh = layar.tombol_beli(id)
		check(tombol.disabled and tombol.text == "Koin kurang" and layar.kartu_upgrade(id).panel.visible, "%s: tombol nonaktif 'Koin kurang' (saldo 375 < harga)" % id)
		check(_jenis_kartu(layar.kartu_upgrade(id).panel) == GayaHud.tekstur("kartu_biasa"), "%s: kartu upgrade biasa" % id)
	check(layar.teks_saldo() == "375" and layar.jumlah_upgrade_tampil() == 3 and not layar.galat_tampil() and not layar.ongkos_tampil(), "saldo '375', tiga kartu upgrade, tanpa galat, tanpa catatan ongkos")
	_buang(layar)


func _test_keadaan_b() -> void:
	_judul.call("Bengkel tata C keadaan b (ban 0,30 dan rem 0,20 PERLU, rantai 0,60 AUS, saldo 1.000): kartu menonjol, chip '! Ban', '! Rem', 'Rantai aus', harga 105, 80, 75 dengan ongkos x1,25 (AC-7b)")
	var layar: LayarBengkel = await _bengkel(_state(1000, 0.30, 0.20, 0.60))
	check(_kartu_jenis(layar, "ban") == KomponenUi.JenisKartu.MENONJOL and _kartu_jenis(layar, "rem") == KomponenUi.JenisKartu.MENONJOL and _kartu_jenis(layar, "rantai") == KomponenUi.JenisKartu.BIASA, "kartu: ban dan rem menonjol, rantai biasa")
	check(_jenis_kartu(layar.kartu_servis("ban").panel) == GayaHud.tekstur("kartu_menonjol") and _jenis_kartu(layar.kartu_servis("rantai").panel) == GayaHud.tekstur("kartu_biasa"), "tekstur kartu menonjol dan biasa terpasang")
	check(layar.kartu_servis("ban").harga.text == "105 koin" and layar.kartu_servis("rem").harga.text == "80 koin" and layar.kartu_servis("rantai").harga.text == "75 koin", "harga 105, 80, 75 (120 x 0,7 x 1,25; 80 x 0,8 x 1,25; 150 x 0,4 x 1,25)")
	check(layar.ongkos_tampil() and layar.teks_ongkos() == "Banyak yang rusak: ongkos servis x1.25", "catatan ongkos naik x1.25 tampil")
	var p: PanggungSepeda = layar.panggung()
	check(p.teks_chip("ban") == "! Ban" and p.teks_chip("rem") == "! Rem" and p.teks_chip("rantai") == "Rantai aus", "chip di sepeda: '! Ban', '! Rem', 'Rantai aus', dapat '%s' '%s' '%s'" % [p.teks_chip("ban"), p.teks_chip("rem"), p.teks_chip("rantai")])
	check(layar.kartu_servis("ban").kotak.seru_tampil() and layar.kartu_servis("rem").kotak.seru_tampil() and not layar.kartu_servis("rantai").kotak.seru_tampil(), "tanda '!' di kotak kondisi hanya pada komponen PERLU")
	check(layar.kartu_servis("ban").tingkat.text == "Perlu servis" and layar.kartu_servis("rantai").tingkat.text == "Aus", "teks status 'Perlu servis' dan 'Aus' (terbaca tanpa warna)")
	check(layar.kartu_servis("ban").tingkat.get_theme_color(&"font_color") == Palette.TEXT and layar.kartu_servis("rantai").tingkat.get_theme_color(&"font_color") == Palette.TEXT_2, "teks status: 'Perlu servis' TEXT (WARN hanya 6,91:1 di atas kartu), 'Aus' TEXT_2")
	check(p.warna_titik("ban") == Palette.WARN and p.warna_titik("rem") == Palette.WARN and p.warna_titik("rantai") == Palette.TEXT_2, "titik penanda: PERLU berwarna WARN, AUS berwarna TEXT_2")
	for id: String in Config.KONDISI_KOMPONEN:
		check(absf(p.rect_chip(id).size.y - 14.0) < 0.5, "chip penanda %s setinggi 14 (ukuran kecil)" % id)
		check(not layar.tombol_servis(id).disabled and layar.tombol_servis(id).text == "Servis" and layar.tombol_servis(id).icon != null, "%s: tombol Servis aktif berikon kunci" % id)
	_buang(layar)


func _test_keadaan_c() -> void:
	_judul.call("Bengkel tata C keadaan c (saldo 60): ban PERLU harga 84 nonaktif 'Koin kurang', rem AUS harga 32 aktif, tekan tombol nonaktif tidak mengubah apa pun (AC-7c, AC-8)")
	var layar: LayarBengkel = await _bengkel(_state(60, 0.30, 0.60, 1.0))
	var tombol: TombolSentuh = layar.tombol_servis("ban")
	check(tombol.disabled and tombol.text == "Koin kurang" and tombol.icon == null and layar.kartu_servis("ban").harga.text == "84 koin", "ban: harga 84 > 60, tombol nonaktif 'Koin kurang' tanpa ikon")
	check(not layar.tombol_servis("rem").disabled and layar.kartu_servis("rem").harga.text == "32 koin", "rem 0,60: 80 x 0,4 = 32 koin, aktif")
	var sebelum: Dictionary = layar.state()
	tombol.pressed.emit()
	tombol.ditekan.emit()
	for id: String in ["ban_anti_selip", "rem_pakem", "rantai_hemat"]:
		layar.tombol_beli(id).pressed.emit()
	check(layar.state() == sebelum and layar.belanja_koin() == 0, "pressed.emit() dan ditekan.emit() pada semua tombol nonaktif: state identik, belanja 0")
	check(not layar.tombol_hari_berikutnya().disabled, "'Hari berikutnya' tetap aktif")
	_buang(layar)


func _test_keadaan_d() -> void:
	_judul.call("Bengkel tata C keadaan d (sesudah beli ban_anti_selip): kartu redup 'Dimiliki' tanpa harga dan tombol, chip tingkat aksen; yang lain tetap dijual (AC-7d)")
	var layar: LayarBengkel = await _bengkel(_state(1100, 0.6, 1.0, 1.0))
	layar.tombol_beli("ban_anti_selip").pressed.emit()
	await _tree.process_frame
	await _tree.process_frame
	var kartu: LayarBengkel.KartuUpgrade = layar.kartu_upgrade("ban_anti_selip")
	check(kartu.info.dimiliki and _jenis_kartu(kartu.panel) == GayaHud.tekstur("kartu_redup") and kartu.chip_dimiliki.visible and kartu.label_dimiliki.text == "Dimiliki" and not kartu.tombol.visible and not kartu.chip_harga.visible, "ban_anti_selip: kartu redup, chip 'Dimiliki', tanpa tombol dan harga")
	check(kartu.nama.get_theme_color(&"font_color") == Palette.TEXT_2 and layar.kartu_upgrade("rem_pakem").nama.get_theme_color(&"font_color") == Palette.TEXT, "nama upgrade yang dimiliki TEXT_2 (redup), yang dijual TEXT")
	check(kartu.label_dimiliki.get_theme_color(&"font_color") == Palette.TEXT_2 and kartu.chip_tingkat.teks() == "I" and kartu.info.status_tingkat == KomponenUi.StatusChip.TINGKAT_AKTIF, "chip tingkat 'I' beraksen sesudah dimiliki")
	check(layar.state()["koin"] == 500 and layar.teks_saldo() == "500" and not layar.tombol_beli("rem_pakem").disabled and layar.tombol_beli("rantai_hemat").disabled, "saldo 500: rem_pakem (500) tepat terbeli, rantai_hemat (700) nonaktif")
	check(_jenis_kartu(layar.kartu_upgrade("rem_pakem").panel) == GayaHud.tekstur("kartu_biasa"), "kartu upgrade lain tetap biasa")
	_buang(layar)


func _test_keadaan_e() -> void:
	_judul.call("Bengkel tata C keadaan e (terpadat: tiga PERLU, saldo 125.480): harga 162, 96, 158 (ongkos x1,5), saldo enam digit terbaca penuh, tiga chip penanda (AC-7e)")
	var layar: LayarBengkel = await _bengkel(_state(125480, 0.1, 0.2, 0.3))
	var chip_saldo: Control = layar.find_child("ChipSaldo", true, false)
	check(absf(chip_saldo.get_global_rect().size.y - 24.0) < 0.5 and absf(layar.kartu_servis("ban").chip_harga.get_global_rect().size.y - 18.0) < 0.5, "chip saldo setinggi 24 (besar) dan chip harga 18 (normal)")
	check(layar.teks_saldo() == "125.480" and layar.teks_ongkos() == "Banyak yang rusak: ongkos servis x1.50", "saldo '125.480' dan catatan x1.50")
	check(layar.kartu_servis("ban").harga.text == "162 koin" and layar.kartu_servis("rem").harga.text == "96 koin" and layar.kartu_servis("rantai").harga.text == "158 koin", "harga 162, 96, 158 (150 x 0,7 x 1,5 = 157,5 dibulatkan ke atas)")
	for id: String in Config.KONDISI_KOMPONEN:
		check(layar.panggung().chip_tampil(id) and _kartu_jenis(layar, id) == KomponenUi.JenisKartu.MENONJOL, "%s: kartu menonjol dan chip penanda tampil" % id)
	check(layar.panggung().rect_chip("ban") != Rect2() and not layar.panggung().rect_chip("ban").intersects(layar.panggung().rect_chip("rantai")) and not layar.panggung().rect_chip("rem").intersects(layar.panggung().rect_chip("rantai")), "tiga chip penanda tidak saling menumpuk")
	_buang(layar)


func _test_keadaan_f() -> void:
	_judul.call("Bengkel tata C keadaan f (galat data upgrade): pesan WARN tampil, tanpa kartu upgrade, servis dan 'Hari berikutnya' tetap jalan, tata letak tidak meledak (AC-7f)")
	var rusak: PemuatToko.Kumpulan = PemuatToko.parse_teks("{bukan json", "upgrades.json")
	var layar: LayarBengkel = await _bengkel(_state(500, 0.5), Vector2i(1920, 1080), rusak)
	check(layar.galat_tampil() and layar.jumlah_upgrade_tampil() == 0 and layar.rect_isi().size.y <= 336.5, "galat tampil, nol kartu upgrade, isi tidak membengkak (tinggi %.1f)" % layar.rect_isi().size.y)
	check(layar.teks_tampil().has("Daftar upgrade tidak bisa dimuat; servis tetap bisa"), "pesan galat jujur tampil")
	layar.tombol_servis("ban").pressed.emit()
	check(layar.state()["koin"] == 440 and not layar.tombol_hari_berikutnya().disabled, "servis ban 60 koin tetap bisa, 'Hari berikutnya' aktif")
	var terpotong: Array[String] = _teks_terpotong(layar)
	check(terpotong.is_empty(), "tanpa teks terpotong di keadaan galat: %s" % [terpotong])
	_buang(layar)


func _test_keadaan_g() -> void:
	_judul.call("Bengkel tata C keadaan g (margin kiri 36 dan bawah 20 seperti kanvas g, yaitu inset 24 + 12 dan 8 + 12): kolom dari isi yang menyempit, 'Hari berikutnya' di dalam margin (AC-7g)")
	var inset: ZonaAman.Inset = ZonaAman.Inset.new()
	inset.awal_x = 36
	inset.bawah = 20
	var layar: LayarBengkel = await _bengkel(_state(1000, 0.30, 0.20, 0.60), Vector2i(1920, 1080), null, inset)
	check(absf(layar.rect_isi().position.x - 36.0) < 0.5 and absf(layar.rect_isi().position.y - 12.0) < 0.5 and absf(layar.rect_isi().end.y - 340.0) < 0.5, "isi mulai x 36 dan y 12, berakhir y 340: %s" % layar.rect_isi())
	check(absf(layar.rect_panel_servis().size.x - 284.0) < 0.5 and absf(layar.rect_kolom_upgrade().size.x - 300.0) < 0.5, "kolom servis 284 dan upgrade 300 (kanvas keadaan g), dapat %.1f dan %.1f" % [layar.rect_panel_servis().size.x, layar.rect_kolom_upgrade().size.x])
	check(absf(layar.rect_tombol_hari().end.y - 340.0) < 0.5 and absf(layar.rect_tombol_hari().end.x - 628.0) < 0.5, "'Hari berikutnya' berakhir (628, 340): %s" % layar.rect_tombol_hari())
	var p: PanggungSepeda = layar.panggung()
	check(absf(p.rect_sepeda().position.y - p.rect_panggung().position.y - 2.0) < 0.5, "sepeda 2 px dari atas panggung (panggung 84 tinggi, kanvas by = 2): panggung %s sepeda %s" % [p.rect_panggung(), p.rect_sepeda()])
	_buang(layar)


# --- Tombol nonaktif dan peran ---

func _test_tombol_nonaktif_gaya() -> void:
	_judul.call("Bengkel tata C: tombol nonaktif rata dan diarsir (tanpa bibir, tekstur ubin), aktif memakai bingkai biasa; 'Hari berikutnya' utama 140x42 (AC-7, AC-8, AC-9)")
	var layar: LayarBengkel = await _bengkel(_state(60, 0.30, 0.60, 1.0))
	var mati: StyleBoxTexture = layar.tombol_servis("ban").get_theme_stylebox(&"disabled") as StyleBoxTexture
	var normal_mati: StyleBoxTexture = layar.tombol_servis("ban").get_theme_stylebox(&"normal") as StyleBoxTexture
	check(mati != null and mati.axis_stretch_horizontal == StyleBoxTexture.AXIS_STRETCH_MODE_TILE and normal_mati.axis_stretch_vertical == StyleBoxTexture.AXIS_STRETCH_MODE_TILE, "tombol nonaktif: bingkai diarsir (mode ubin) pada semua keadaan")
	var aktif: StyleBoxTexture = layar.tombol_servis("rem").get_theme_stylebox(&"normal") as StyleBoxTexture
	check(aktif.texture == GayaHud.tekstur("btn_biasa") and layar.tombol_servis("rem").get_theme_stylebox(&"pressed") is StyleBoxTexture and (layar.tombol_servis("rem").get_theme_stylebox(&"pressed") as StyleBoxTexture).texture == GayaHud.tekstur("btn_biasa_tekan"), "tombol aktif: bingkai biasa dan biasa_tekan")
	var hari: TombolSentuh = layar.tombol_hari_berikutnya()
	check((hari.get_theme_stylebox(&"normal") as StyleBoxTexture).texture == GayaHud.tekstur("btn_utama") and hari.size.x >= 140.0 and hari.size.y >= 42.0 and hari.icon == GayaHud.tekstur("glif_panah_gelap") and hari.icon_alignment == HORIZONTAL_ALIGNMENT_RIGHT, "'Hari berikutnya': peran utama, 140x42, glif panah gelap")
	check(layar.tombol_servis("ban").size.x >= 84.0 and layar.tombol_servis("ban").size.y >= 42.0 and layar.tombol_servis("rem").size.x >= 84.0, "tombol servis >= 84x42 (nonaktif maupun aktif)")
	_buang(layar)


# --- Upgrade bertingkat (data uji; upgrades.json tidak berubah) ---

func _toko_bertingkat() -> PemuatToko.Kumpulan:
	var k: PemuatToko.Kumpulan = PemuatToko.muat()
	for tingkat: int in [2, 3]:
		var d: DataToko.Hasil = DataToko.parse({
			"id": "ban_anti_selip_%d" % tingkat, "komponen": "ban", "level": tingkat, "harga": 600 + 300 * (tingkat - 1),
			"nama": "TOKO_BAN_ANTI_SELIP_NAMA", "deskripsi": "TOKO_BAN_ANTI_SELIP_DESKRIPSI", "efek": [{"jenis": "pengali_lateral", "nilai": 1.15}],
		})
		if d.upgrade != null:
			k.upgrade.append(d.upgrade)
	return k


func _test_tingkat_bertingkat() -> void:
	_judul.call("Bengkel tata C: upgrade bertingkat I, II, III = tetap tiga kartu, kartu ban berganti isi dengan jejak dan membeli bertahap; kartu setinggi 72 (AC-7, kanvas Bengkel_Tingkat)")
	var toko: PemuatToko.Kumpulan = _toko_bertingkat()
	check(toko.upgrade.size() == 5, "data uji: lima upgrade (ban tiga tingkat)")
	var layar: LayarBengkel = await _bengkel(_state(5000), Vector2i(1920, 1080), toko)
	var kartu: LayarBengkel.KartuUpgrade = layar.kartu_upgrade("ban_anti_selip")
	check(layar.jumlah_upgrade_tampil() == 3 and layar.kartu_upgrade("ban_anti_selip_2") == kartu and layar.kartu_upgrade("ban_anti_selip_3") == kartu, "tetap tiga kartu; tiga tingkat ban satu kartu")
	check(kartu.baris_jejak.visible and kartu.jejak.size() == 3 and kartu.panel.custom_minimum_size.y == 72.0 and layar.kartu_upgrade("rem_pakem").panel.custom_minimum_size.y == 62.0, "kartu ban memakai jejak tiga chip dan tinggi 72; kartu rem tanpa jejak 62")
	check(kartu.jejak[0].teks() == "I" and kartu.jejak[1].teks() == "II" and kartu.jejak[2].teks() == "III" and kartu.chip_tingkat.teks() == "I", "jejak I, II, III dan chip tingkat 'I'")
	check(kartu.jejak[2].modulate.a == 1.0 and kartu.jejak[1].modulate.a == 1.0 and not kartu.jejak[2].glif_tampil() and kartu.jejak[0].glif_tampil() == false and layar.tombol_beli("ban_anti_selip") != null and layar.tombol_beli("ban_anti_selip_2") == null, "chip jejak tidak diredupkan (teks tetap >= 7:1; kanvas opacity .55 ditolak); tombol Beli hanya untuk tingkat yang dijual")
	layar.tombol_beli("ban_anti_selip").pressed.emit()
	await _tree.process_frame
	check(kartu.data.id == "ban_anti_selip_2" and kartu.chip_tingkat.teks() == "II" and kartu.harga.text == "900 koin" and layar.state()["koin"] == 4400 and not kartu.info.dimiliki, "sesudah beli I: kartu berganti ke tingkat II, harga 900, saldo 4.400")
	check(kartu.jejak[0].label().text == "I" and kartu.jejak[0].glif_tampil() and kartu.info.jejak == [TampilBengkel.StatusJejak.DIMILIKI, TampilBengkel.StatusJejak.AKTIF, TampilBengkel.StatusJejak.MENUNGGU], "jejak [dimiliki, aktif, menunggu]")
	layar.tombol_beli("ban_anti_selip_2").pressed.emit()
	await _tree.process_frame
	check(kartu.data.id == "ban_anti_selip_3" and kartu.chip_tingkat.teks() == "III" and kartu.harga.text == "1.200 koin" and layar.tombol_beli("ban_anti_selip_3") != null, "sesudah beli II: kartu berganti ke tingkat III, harga 1.200")
	if layar.tombol_beli("ban_anti_selip_3") != null:
		layar.tombol_beli("ban_anti_selip_3").pressed.emit()
	await _tree.process_frame
	check(layar.state()["koin"] == 5000 - 600 - 900 - 1200 and Economy.level_dari(layar.state())["ban"] == 3 and kartu.info.dimiliki and kartu.chip_dimiliki.visible and not kartu.tombol.visible and _jenis_kartu(kartu.panel) == GayaHud.tekstur("kartu_redup"), "sesudah beli tiga tingkat: saldo 2.300, level 3, kartu redup 'Dimiliki'")
	_buang(layar)


func _test_tingkat_bertingkat_tata_letak() -> void:
	_judul.call("Bengkel tata C: kartu bertingkat (72) tetap muat tanpa scroll dan tanpa tumpang tindih di 640 dan 800, juga bila semua dimiliki (AC-6, AC-9)")
	var toko: PemuatToko.Kumpulan = _toko_bertingkat()
	for level_ban: int in [0, 1, 2, 3]:
		for lebar_jendela: Array in [[1920, 1080], [2400, 1080]]:
			var layar: LayarBengkel = await _bengkel(_state(100, 0.1, 0.2, 0.3, [level_ban, 0, 0]), Vector2i(lebar_jendela[0], lebar_jendela[1]), toko)
			var tag: String = "level ban %d lebar %d" % [level_ban, floori(float(lebar_jendela[0]) / 3.0)]
			var kotak_hari: Rect2 = layar.rect_tombol_hari()
			var salah: Array[String] = []
			for r: Rect2 in layar.rect_kartu():
				if r.intersects(kotak_hari):
					salah.append(str(r))
			check(salah.is_empty(), "%s: kartu tidak menutupi 'Hari berikutnya': %s" % [tag, salah])
			var kolom: Rect2 = layar.rect_kolom_upgrade()
			var kartu_terbawah: float = 0.0
			for kartu: LayarBengkel.KartuUpgrade in [layar.kartu_upgrade("ban_anti_selip"), layar.kartu_upgrade("rem_pakem"), layar.kartu_upgrade("rantai_hemat")]:
				kartu_terbawah = maxf(kartu_terbawah, kartu.panel.get_global_rect().end.y)
			check(kartu_terbawah <= kotak_hari.position.y and kartu_terbawah <= 348.5 and layar.find_children("*", "ScrollContainer", true, false).is_empty() and kolom.size.y > 0.0, "%s: tiga kartu berakhir y %.1f di atas 'Hari berikutnya' (%.1f), tanpa scroll" % [tag, kartu_terbawah, kotak_hari.position.y])
			check(_teks_terpotong(layar).is_empty() and _tumpuk(layar).is_empty(), "%s: tanpa teks terpotong dan tanpa tumpang tindih: %s %s" % [tag, _teks_terpotong(layar), _tumpuk(layar).slice(0, 3)])
			_buang(layar)


# --- Tata letak lintas ukuran ---

## Label yang teksnya terpotong: jumlah baris terlihat berbeda dari jumlah baris, tinggi label kurang dari baris yang dibutuhkan, atau (tanpa bungkus) lebar label kurang dari lebar teks; tombol yang lebarnya kurang dari teks + ikon.
func _teks_terpotong(layar: LayarBengkel) -> Array[String]:
	var hasil: Array[String] = []
	for simpul: Node in layar.find_children("*", "Label", true, false):
		var label: Label = simpul as Label
		if not label.is_visible_in_tree() or label.text == "":
			continue
		if label.get_visible_line_count() != label.get_line_count():
			hasil.append("baris terpotong: " + label.text)
		var tinggi_perlu: float = float(label.get_line_count()) * float(label.get_line_height())
		if label.size.y + 0.5 < tinggi_perlu:
			hasil.append("tinggi kurang: %s (%.1f < %.1f)" % [label.text, label.size.y, tinggi_perlu])
		if label.autowrap_mode == TextServer.AUTOWRAP_OFF and label.size.x + 0.5 < label.get_minimum_size().x:
			hasil.append("lebar kurang: %s (%.1f < %.1f)" % [label.text, label.size.x, label.get_minimum_size().x])
	for simpul: Node in layar.find_children("*", "Button", true, false):
		var tombol: Button = simpul as Button
		if tombol.is_visible_in_tree() and tombol.size.x + 0.5 < tombol.get_minimum_size().x:
			hasil.append("tombol sempit: %s (%.1f < %.1f)" % [tombol.text, tombol.size.x, tombol.get_minimum_size().x])
	return hasil


func _tumpuk(layar: LayarBengkel) -> Array[String]:
	var hasil: Array[String] = []
	var semua: Array[Rect2] = layar.rect_tampil()
	for i: int in range(semua.size()):
		for j: int in range(i + 1, semua.size()):
			if semua[i].intersects(semua[j]):
				hasil.append("%s x %s" % [semua[i], semua[j]])
	return hasil


func _test_tata_letak(jendela: Array, dengan_inset: bool, terpadat: bool) -> void:
	var lebar: int = jendela[2]
	var tag: String = "bengkel tata C %d (%dx%d) %s" % [lebar, jendela[0], jendela[1], "inset" if dengan_inset else "tanpa inset"]
	_judul.call("Tata letak %s: kasus terpadat, di dalam zona aman, tanpa tumpang tindih, tombol >= 42x84, tanpa teks terpotong, chip di dalam kartu dan panggung, tanpa scroll (AC-6, AC-9)" % tag)
	var inset: ZonaAman.Inset = ZonaAman.Inset.new()
	if dengan_inset:
		inset.awal_x = 20
		inset.akhir_x = 24
		inset.atas = 16
		inset.bawah = 18
	var layar: LayarBengkel = await _bengkel(_state(125480, 0.1, 0.2, 0.3), Vector2i(jendela[0], jendela[1]), null, inset)
	var batas_awal: float = float(maxi(Config.BENGKEL_MARGIN_PX, inset.awal_x))
	var batas_akhir: float = float(lebar - maxi(Config.BENGKEL_MARGIN_PX, inset.akhir_x))
	var atas: float = float(maxi(Config.BENGKEL_MARGIN_PX, inset.atas))
	var bawah: float = float(360 - maxi(Config.BENGKEL_MARGIN_PX, inset.bawah))
	var aman: Rect2 = Rect2(batas_awal, atas, batas_akhir - batas_awal, bawah - atas)
	var semua: Array[Rect2] = layar.rect_tampil()
	var di_luar: Array[String] = []
	for r: Rect2 in semua:
		if r.size.x <= 0.0 or r.size.y <= 0.0 or not aman.grow(0.5).encloses(r):
			di_luar.append(str(r))
	check(semua.size() >= 30 and di_luar.is_empty(), "%s: %d elemen, semua di dalam zona aman %s: di luar %s" % [tag, semua.size(), aman, di_luar.slice(0, 3)])
	check(_tumpuk(layar).is_empty(), "%s: tidak ada elemen bertumpuk: %s" % [tag, _tumpuk(layar).slice(0, 3)])
	var kecil: Array[String] = []
	for tombol: TombolSentuh in layar.semua_tombol():
		if not tombol.is_visible_in_tree():
			continue
		var r: Rect2 = tombol.get_global_rect()
		var lebar_min: float = float(Config.BENGKEL_HARI_LEBAR_PX) if tombol == layar.tombol_hari_berikutnya() else 84.0
		if r.size.y < 42.0 or r.size.x < lebar_min:
			kecil.append(str(r))
	check(kecil.is_empty(), "%s: semua tombol >= 42 tinggi dan >= 84 lebar ('Hari berikutnya' 140): %s" % [tag, kecil])
	var terpotong: Array[String] = _teks_terpotong(layar)
	check(terpotong.is_empty(), "%s: tanpa teks terpotong: %s" % [tag, terpotong])
	var chip_luar: Array[String] = []
	for id: String in Config.KONDISI_KOMPONEN:
		var kartu: LayarBengkel.KartuServis = layar.kartu_servis(id)
		for r: Rect2 in layar.rect_chip_di(kartu.panel):
			if not kartu.panel.get_global_rect().grow(0.5).encloses(r):
				chip_luar.append("%s %s" % [id, r])
	for kartu_u: LayarBengkel.KartuUpgrade in [layar.kartu_upgrade("ban_anti_selip"), layar.kartu_upgrade("rem_pakem"), layar.kartu_upgrade("rantai_hemat")]:
		for r: Rect2 in layar.rect_chip_di(kartu_u.panel):
			if not kartu_u.panel.get_global_rect().grow(0.5).encloses(r):
				chip_luar.append("%s %s" % [kartu_u.komponen, r])
	check(chip_luar.is_empty(), "%s: semua chip dan tombol di dalam kartunya: %s" % [tag, chip_luar])
	var p: PanggungSepeda = layar.panggung()
	var luar_panggung: Array[String] = []
	for id: String in Config.KONDISI_KOMPONEN:
		if not p.chip_tampil(id):
			luar_panggung.append("%s tanpa chip" % id)
			continue
		if not p.rect_panggung().grow(0.5).encloses(p.rect_chip(id)):
			luar_panggung.append("chip %s %s di luar panggung %s" % [id, p.rect_chip(id), p.rect_panggung()])
		if not p.rect_sepeda().grow(0.5).encloses(p.rect_titik_global(id).grow(-1)):
			luar_panggung.append("titik %s di luar sepeda" % id)
	check(luar_panggung.is_empty(), "%s: chip kondisi di dalam panggung sepeda, titik di dalam gambar sepeda: %s" % [tag, luar_panggung])
	check(p.rect_sepeda().size == Vector2(Config.BENGKEL_SEPEDA_LEBAR_PX, Config.BENGKEL_SEPEDA_TINGGI_PX), "%s: sepeda berukuran 116x78 piksel game" % tag)
	check(layar.find_children("*", "ScrollContainer", true, false).is_empty() and layar.rect_isi().end.y <= bawah + 0.5, "%s: tanpa scroll, isi berakhir y %.1f <= %.1f" % [tag, layar.rect_isi().end.y, bawah])
	var kolom: Vector2i = TampilBengkel.lebar_kolom(int(batas_akhir - batas_awal))
	check(absf(layar.rect_panel_servis().size.x - float(kolom.x)) < 0.5 and absf(layar.rect_kolom_upgrade().size.x - float(kolom.y)) < 0.5, "%s: kolom servis %d dan upgrade %d (dapat %.1f dan %.1f)" % [tag, kolom.x, kolom.y, layar.rect_panel_servis().size.x, layar.rect_kolom_upgrade().size.x])
	var hari: Rect2 = layar.rect_tombol_hari()
	check(absf(hari.end.x - batas_akhir) < 0.5 and absf(hari.end.y - bawah) < 0.5 and hari.size.is_equal_approx(Vector2(140.0, 42.0)), "%s: 'Hari berikutnya' 140x42 di sudut kanan bawah zona aman: %s" % [tag, hari])
	var mentah: Array[String] = []
	var kunci_mentah: RegEx = RegEx.create_from_string("^[A-Z]+(?:_[A-Z0-9]+)+$")
	for teks: String in layar.teks_tampil():
		if kunci_mentah.search(teks) != null:
			mentah.append(teks)
	check(mentah.is_empty(), "%s: tidak ada kunci terjemahan mentah di layar: %s" % [tag, mentah])
	_buang(layar)


func _test_hari_berikutnya_dan_back() -> void:
	_judul.call("Bengkel tata C: 'Hari berikutnya' selalu aktif dan memancarkan sinyal sekali, juga saat saldo 0 dan semua rusak (AC-8)")
	var layar: LayarBengkel = await _bengkel(_state(0, 0.0, 0.0, 0.0))
	var sinyal: Array[int] = [0]
	layar.hari_berikutnya_diminta.connect(func() -> void: sinyal[0] += 1)
	check(not layar.tombol_hari_berikutnya().disabled and layar.tombol_hari_berikutnya().visible, "saldo 0, tiga komponen 0,0: tombol aktif")
	layar.tombol_hari_berikutnya().ditekan.emit()
	check(sinyal[0] == 1, "ditekan: tepat satu sinyal hari_berikutnya_diminta")
	for id: String in Config.KONDISI_KOMPONEN:
		check(layar.tombol_servis(id).disabled and layar.tombol_servis(id).text == "Koin kurang" and layar.panggung().chip_tampil(id), "%s: nonaktif 'Koin kurang' dan chip penanda tampil" % id)
	_buang(layar)
