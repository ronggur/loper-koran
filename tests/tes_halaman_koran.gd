class_name TesHalamanKoran
extends RefCounted
## Tes layar halaman depan koran run fase4a-koran-hari (AC-21 sampai AC-24): `scenes/koran/halaman_koran.tscn` sungguhan di lebar viewport 640, 780,
## 800 (16:9, 19,5:9, 20:9) dan 1600x720, dengan halaman nyata hari 1 dan hari 2, teks terpanjang yang sah (headline 40, ringkasan 60 karakter
## huruf lebar), tanpa misi (S-8), lanjutan tanpa misi, dan inset aman. Tes tata letak diukur dengan font nyata (autowrap).
## Harapan ditulis literal atau dihitung tes sendiri: kontras dengan rumus WCAG yang ditulis ulang di sini, teks dari konten.csv/ui.csv literal.

const BERKAS_KORAN: String = "res://scenes/koran/halaman_koran.tscn"
const SKALA_JENDELA: Array = [[1920, 1080, 640], [2340, 1080, 780], [2400, 1080, 800], [1600, 720, 800]]
const TINGGI_VIEWPORT: float = 360.0
const TOMBOL_MIN_PX: float = 42.0
## Variasi tema yang sah di layar koran sejak run ui2-semua-layar bagian B (V-8: nama koran Lilita 32, teks utama 12, kecil 11, mini tebal 10, label 10; headline Lilita 24 dan 16 tidak berubah).
const VARIASI_SAH: Array[String] = ["LayarAngkaBesar", "JudulBesar", "JudulLayar", "LayarLabel", "LayarTeksUtama", "LayarTeksKecil", "LayarTeksMiniTebal"]

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
	_test_kontras()
	await _test_isi_nyata()
	await _test_tata_letak_semua_ukuran()
	await _test_tampilan_baru()
	await _test_hari_panjang()
	await _test_gaya_tombol_koran()
	await _test_tata_sapuan()
	await _test_ambil_lewati()
	await _test_tanpa_misi()
	await _test_notifikasi_dan_zona_aman()
	await _test_font_dan_warna()
	await _test_tanpa_tombol_jeda()


# --- Pembantu ---

func _siapkan(jendela: Vector2i = Vector2i(2340, 1080)) -> HalamanKoran:
	_tree.root.size = jendela
	var koran: HalamanKoran = (load(BERKAS_KORAN) as PackedScene).instantiate() as HalamanKoran
	_tree.root.add_child(koran)
	await _tree.process_frame
	await _tree.process_frame
	return koran


func _bersihkan(koran: HalamanKoran) -> void:
	_tree.root.remove_child(koran)
	koran.free()


func _semua(akar: Node, daftar: Array[Node] = []) -> Array[Node]:
	daftar.append(akar)
	for anak: Node in akar.get_children():
		_semua(anak, daftar)
	return daftar


func _luminans(warna: Color) -> float:
	var saluran: Array[float] = []
	for c: float in [warna.r, warna.g, warna.b]:
		saluran.append(c / 12.92 if c <= 0.04045 else pow((c + 0.055) / 1.055, 2.4))
	return 0.2126 * saluran[0] + 0.7152 * saluran[1] + 0.0722 * saluran[2]


## Rasio kontras WCAG antara dua warna.
func _kontras(a: Color, b: Color) -> float:
	var la: float = _luminans(a)
	var lb: float = _luminans(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func _familia(font: Font) -> String:
	if font is FontVariation:
		return (font as FontVariation).base_font.resource_path
	return font.resource_path


func _luas_tumpang(a: Rect2, b: Rect2) -> float:
	var i: Rect2 = a.intersection(b)
	return maxf(i.size.x, 0.0) * maxf(i.size.y, 0.0)


# --- Kontras (AC-21) ---

func _test_kontras() -> void:
	_judul.call("Layar koran: token krem dan kontras WCAG (AC-21)")
	check(_kontras(Color("#000000"), Color("#FFFFFF")) > 20.99 and _kontras(Color("#777777"), Color("#FFFFFF")) < 4.6, "rumus WCAG di tes benar (hitam/putih 21:1, abu #777 di putih < 4,6:1)")
	check(Palette.KORAN_KERTAS.to_html(false) == "f2e7c9", "KORAN_KERTAS = #F2E7C9 (krem DESIGN_SPEC 4)")
	var pasangan: Array = [
		["TINTA di KERTAS", Palette.KORAN_TINTA, Palette.KORAN_KERTAS, 7.0],
		["TINTA_2 di KERTAS", Palette.KORAN_TINTA_2, Palette.KORAN_KERTAS, 7.0],
		["TINTA di KERTAS_2", Palette.KORAN_TINTA, Palette.KORAN_KERTAS_2, 7.0],
		["TINTA_2 di KERTAS_2", Palette.KORAN_TINTA_2, Palette.KORAN_KERTAS_2, 7.0],
		["KERTAS di TINTA (tombol terpilih dan Berangkat)", Palette.KORAN_KERTAS, Palette.KORAN_TINTA, 7.0],
		["KERTAS di TINTA_2 (tombol ditekan)", Palette.KORAN_KERTAS, Palette.KORAN_TINTA_2, 7.0],
		["GARIS di KERTAS (komponen UI)", Palette.KORAN_GARIS, Palette.KORAN_KERTAS, 3.0],
		["GARIS di KERTAS_2 (komponen UI)", Palette.KORAN_GARIS, Palette.KORAN_KERTAS_2, 3.0],
	]
	check(Config.KORAN_KONTRAS_TEKS_MIN == 7.0 and Config.KORAN_KONTRAS_GARIS_MIN == 3.0, "batas kontras di Config = 7:1 teks dan 3:1 komponen")
	for p: Array in pasangan:
		var rasio: float = _kontras(p[1], p[2])
		check(rasio >= float(p[3]), "kontras %s = %.2f:1 (paling sedikit %.0f:1)" % [p[0], rasio, p[3]])


# --- Isi (AC-21, AC-24) ---

func _test_isi_nyata() -> void:
	_judul.call("Layar koran: isi hari 1 nyata lewat kunci terjemahan, blok teks tetap (AC-21, AC-23, AC-24)")
	var koran: HalamanKoran = await _siapkan()
	koran.isi(HalamanUji.nyata(1), 1, "perumahan")
	await _tree.process_frame
	var teks: Array[String] = koran.teks_tampil()
	check(teks[0] == "Warta Kring" and teks[1] == "Hari 1 · Perumahan Melati", "nama koran 'Warta Kring' dan 'Hari 1 · Perumahan Melati' (kunci KORAN_NAMA, KORAN_HARI_DISTRIK, KORAN_DISTRIK_PERUMAHAN)")
	check(teks[2] == "BERITA UTAMA" and teks[4] == "BERITA RINGAN" and teks[7] == "MISI SAMPINGAN", "label BERITA UTAMA, BERITA RINGAN, MISI SAMPINGAN (DESIGN_SPEC 5)")
	check(teks[8] == "Kucing Bu Ratmi Hilang Sejak Semalam" and teks[9] == "Cari kucing di sisi seberang sebelum 12 rumah", "baris misi hari 1: headline dan ringkasan satu baris dari data P1")
	check(teks[10] == "Belum dipilih; berangkat = dilewati", "status awal: belum dipilih (sama dengan Lewati, S-7)")
	check(koran.teks_tombol() == ["Ambil", "Lewati", "Berangkat"], "tombol 'Ambil', 'Lewati', 'Berangkat' (kata kerja satu kata, DESIGN_SPEC 5)")
	var halaman: HeadlineManager.Halaman = HalamanUji.nyata(1)
	check(teks[3] == tr(halaman.utama.teks) and teks[5] == tr(halaman.ringan.teks) and not teks[3].is_empty() and not teks[5].is_empty(), "berita utama dan ringan hari 1 = teks terjemahan dari HeadlineManager")
	# AC-24: tiga headline + satu ringkasan + tiga tombol, tanpa paragraf.
	var terlihat: Array[String] = []
	var terpanjang: int = 0
	for label: Node in _semua(koran):
		if label is Label and (label as Label).is_visible_in_tree() and not (label as Label).text.is_empty():
			terlihat.append((label as Label).text)
			terpanjang = maxi(terpanjang, tr((label as Label).text).length())
	check(terlihat.size() <= 11, "blok teks tetap kecil: nama, hari, tiga label, tiga headline, ringkasan, status (%d teks, notifikasi tersembunyi)" % terlihat.size())
	check(terpanjang <= 60, "teks terpanjang di layar paling banyak 60 karakter (ringkasan), tidak ada paragraf; dapat %d" % terpanjang)
	check(koran.ada_misi() and koran.tombol_ambil().is_visible_in_tree() and koran.tombol_lewati().is_visible_in_tree() and koran.tombol_berangkat().is_visible_in_tree(), "tiga tombol tampil saat ada misi")
	_bersihkan(koran)


# --- Tata letak (AC-22) ---

func _kasus_halaman() -> Dictionary:
	return {
		"hari 1": HalamanUji.nyata(1),
		"hari 2 (tanpa misi nyata)": HalamanUji.nyata(2),
		"teks terpanjang": HalamanUji.terpanjang(),
		"tanpa misi": HalamanUji.tanpa_misi(),
		"lanjutan tanpa misi": HalamanUji.lanjutan_tanpa_misi(),
	}


func _test_tata_letak_semua_ukuran() -> void:
	_judul.call("Layar koran: tata letak di 640, 780, 800, 1600x720 termasuk teks terpanjang (AC-22)")
	var terjemahan: Translation = HalamanUji.pasang_terjemahan()
	for ukuran: Array in SKALA_JENDELA:
		var lebar: float = float(ukuran[2])
		var koran: HalamanKoran = await _siapkan(Vector2i(ukuran[0], ukuran[1]))
		var viewport: Rect2 = Rect2(Vector2.ZERO, _tree.root.get_visible_rect().size)
		check(is_equal_approx(viewport.size.x, lebar) and is_equal_approx(viewport.size.y, TINGGI_VIEWPORT), "jendela %dx%d: viewport game %dx360 (skala bulat)" % [ukuran[0], ukuran[1], int(lebar)])
		var aman: Rect2 = viewport.grow_individual(-float(Config.KORAN_MARGIN_PX), -float(Config.KORAN_MARGIN_PX), -float(Config.KORAN_MARGIN_PX), -float(Config.KORAN_MARGIN_PX))
		for tombol: Button in [koran.tombol_ambil(), koran.tombol_lewati(), koran.tombol_berangkat()]:
			check(tombol.custom_minimum_size.x >= TOMBOL_MIN_PX and tombol.custom_minimum_size.y >= TOMBOL_MIN_PX, "%dx%d: ukuran minimum tombol %s >= 42 px game dua sisi, tidak bergantung pada panjang teks: %s" % [ukuran[0], ukuran[1], tombol.name, tombol.custom_minimum_size])
		var kasus: Dictionary = _kasus_halaman()
		for nama: String in kasus:
			koran.isi(kasus[nama], 12, "perumahan")
			await _tree.process_frame
			await _tree.process_frame
			var label_kasus: String = "%dx%d (%s)" % [ukuran[0], ukuran[1], nama]
			var kontrol: Array[Rect2] = [koran.rect_tombol_berangkat()]
			if koran.ada_misi():
				kontrol.append(koran.rect_tombol_ambil())
				kontrol.append(koran.rect_tombol_lewati())
			for r: Rect2 in kontrol:
				check(r.size.x >= TOMBOL_MIN_PX and r.size.y >= TOMBOL_MIN_PX, "%s: tombol >= 42 px game dua sisi (%s)" % [label_kasus, r.size])
				check(aman.encloses(r), "%s: tombol di dalam zona aman (margin 12): %s" % [label_kasus, r])
			for i: int in range(kontrol.size()):
				for j: int in range(i + 1, kontrol.size()):
					check(_luas_tumpang(kontrol[i], kontrol[j]) == 0.0, "%s: tombol %d dan %d tidak tumpang tindih" % [label_kasus, i, j])
			for simpul: Node in koran.find_children("*", "Label", true, false):
				var teks_label: Label = simpul as Label
				if not teks_label.is_visible_in_tree():
					continue
				var r: Rect2 = teks_label.get_global_rect()
				# Kotak baris nama koran (Lilita 32) dinaikkan `KORAN_KEPALA_NAIK_PX` di atas margin seperti kanvas; tinta huruf tetap di dalam zona aman.
				var aman_label: Rect2 = aman.grow_individual(0.0, float(Config.KORAN_KEPALA_NAIK_PX), 0.0, 0.0) if teks_label.name == &"NamaKoran" else aman
				check(aman_label.encloses(r), "%s: label %s di dalam zona aman: %s" % [label_kasus, teks_label.name, r])
				for k: Rect2 in kontrol:
					check(_luas_tumpang(r, k) < 0.5, "%s: label %s tidak tumpang tindih tombol %s" % [label_kasus, r, k])
			for ukur: Dictionary in koran.ukur_label():
				check(float(ukur["dibutuhkan"]) <= float(ukur["tersedia"]) + 1.0 and int(ukur["garis"]) == int(ukur["terlihat"]), "%s: teks %s tidak terpotong (butuh %.0f dari %.0f, %d baris)" % [label_kasus, ukur["nama"], ukur["dibutuhkan"], ukur["tersedia"], ukur["garis"]])
			var berangkat: Rect2 = koran.rect_tombol_berangkat()
			check(berangkat.get_center().x >= lebar * 0.5 and berangkat.get_center().y >= TINGGI_VIEWPORT * 0.5, "%s: Berangkat di zona jempol kanan bawah (pusat %s)" % [label_kasus, berangkat.get_center()])
			if koran.ada_misi():
				check(koran.rect_panel_misi().encloses(koran.rect_tombol_ambil()) and koran.rect_panel_misi().encloses(koran.rect_tombol_lewati()), "%s: Ambil dan Lewati di dalam panel misi" % label_kasus)
				check(_luas_tumpang(koran.rect_panel_misi(), berangkat) == 0.0, "%s: panel misi tidak menutupi Berangkat" % label_kasus)
		_bersihkan(koran)
	HalamanUji.lepas_terjemahan(terjemahan)
	check(tr("TES_KORAN_UTAMA_PANJANG") == "TES_KORAN_UTAMA_PANJANG", "terjemahan sintetis tes dilepas lagi")
	check(HalamanUji.TEKS_UTAMA.length() == 40 and HalamanUji.TEKS_MISI.length() == 40 and HalamanUji.TEKS_RINGAN.length() == 40 and HalamanUji.TEKS_RINGKASAN.length() == 60, "teks sintetis terpanjang tepat di batas: headline 40 dan ringkasan 60 karakter; dapat %d, %d, %d, %d" % [HalamanUji.TEKS_UTAMA.length(), HalamanUji.TEKS_MISI.length(), HalamanUji.TEKS_RINGAN.length(), HalamanUji.TEKS_RINGKASAN.length()])


# --- Tampilan baru run ui2-semua-layar bagian B (AC-3) ---

func _test_gaya_tombol_koran() -> void:
	_judul.call("Layar koran: gaya tombol koran tiap keadaan: bingkai normal dan ditekan, geseran isi bibir 2 px, warna teks (AC-3, kanvas .k-tinta .k-tipis .k-pilih)")
	var koran: HalamanKoran = await _siapkan()
	koran.isi(HalamanUji.nyata(1), 1, "perumahan")
	await _tree.process_frame
	var berangkat: TombolSentuh = koran.tombol_berangkat()
	var normal: StyleBoxTexture = berangkat.get_theme_stylebox(&"normal") as StyleBoxTexture
	var tekan: StyleBoxTexture = berangkat.get_theme_stylebox(&"pressed") as StyleBoxTexture
	check(normal.texture == GayaHud.tekstur("koran_btn_tinta") and tekan.texture == GayaHud.tekstur("koran_btn_tinta_tekan") and berangkat.get_theme_stylebox(&"hover_pressed") == tekan, "Berangkat: bingkai normal koran_btn_tinta, ditekan koran_btn_tinta_tekan")
	check(normal.content_margin_top == 6.0 and normal.content_margin_bottom == 8.0 and tekan.content_margin_top == 8.0 and tekan.content_margin_bottom == 6.0, "Berangkat: normal teks naik (isi atas 6, bawah 8), ditekan teks turun 2 px (atas 8, bawah 6)")
	check(normal.texture_margin_left == 4.0 and normal.texture_margin_top == 6.0 and normal.texture_margin_bottom == 6.0 and normal.texture_margin_right == 4.0, "Berangkat: slice 9-slice tombol 6/4/6/4 (Config.UI_TOMBOL_SLICE_*)")
	check(berangkat.get_theme_color(&"font_color") == Palette.KORAN_KERTAS and berangkat.get_theme_color(&"font_pressed_color") == Palette.KORAN_KERTAS, "Berangkat: teks KORAN_KERTAS normal dan ditekan")
	for tombol: TombolSentuh in [koran.tombol_ambil(), koran.tombol_lewati()]:
		var tipis: StyleBoxTexture = tombol.get_theme_stylebox(&"normal") as StyleBoxTexture
		var tekan_pilih: StyleBoxTexture = tombol.get_theme_stylebox(&"pressed") as StyleBoxTexture
		check(tipis.texture == GayaHud.tekstur("koran_btn_tipis") and tekan_pilih.texture == GayaHud.tekstur("koran_btn_terpilih"), "%s: normal koran_btn_tipis, ditekan koran_btn_terpilih (menekan memilih)" % tombol.name)
		check(tipis.content_margin_top == 6.0 and tipis.content_margin_bottom == 6.0 and tekan_pilih.content_margin_top == 6.0 and tekan_pilih.content_margin_bottom == 6.0, "%s: pilihan rata tanpa bibir (isi atas dan bawah 6 di kedua keadaan)" % tombol.name)
		check(tombol.get_theme_color(&"font_color") == Palette.KORAN_TINTA_2 and tombol.get_theme_color(&"font_pressed_color") == Palette.KORAN_TINTA, "%s: teks TINTA_2 normal, TINTA saat ditekan" % tombol.name)
	koran.tombol_ambil().ditekan.emit()
	var terpilih: StyleBoxTexture = koran.tombol_ambil().get_theme_stylebox(&"normal") as StyleBoxTexture
	check(terpilih.texture == GayaHud.tekstur("koran_btn_terpilih") and (koran.tombol_ambil().get_theme_stylebox(&"pressed") as StyleBoxTexture).texture == GayaHud.tekstur("koran_btn_terpilih") and koran.tombol_ambil().get_theme_color(&"font_color") == Palette.KORAN_TINTA, "Ambil terpilih: bingkai terpilih normal dan ditekan, teks TINTA")
	check(Config.KORAN_FOTO_LEBAR_PX == int(GayaHud.tekstur("foto_jalan").get_size().x) and Config.KORAN_FOTO_TINGGI_PX == int(GayaHud.tekstur("foto_jalan").get_size().y) and Config.KORAN_FOTO_LEBAR_PX == int(GayaHud.tekstur("foto_lampu").get_size().x) and Config.KORAN_FOTO_TINGGI_PX == int(GayaHud.tekstur("foto_lampu").get_size().y), "ukuran foto di Config = ukuran kedua PNG foto")
	check(Config.KORAN_IKON_PX == int(GayaHud.tekstur("icon24_kucing").get_size().x) and Config.UI_TOMBOL_LEBAR_UTAMA_PX == 140 and Config.UI_TOMBOL_TINGGI_PX == 42, "ukuran ikon 24 di Config = PNG; Berangkat 140x42")
	_bersihkan(koran)


func _test_hari_panjang() -> void:
	_judul.call("Layar koran: teks hari yang sangat panjang berelipsis di kanan kepala dan tidak melebarkan layar (AC-7)")
	for ukuran: Array in SKALA_JENDELA:
		var koran: HalamanKoran = await _siapkan(Vector2i(ukuran[0], ukuran[1]))
		var t: TampilKoran.Tata = koran.tata()
		koran.isi(HalamanUji.nyata(1), 1, "perumahan")
		await _tree.process_frame
		await _tree.process_frame
		var lebar_normal: float = koran.rect_isi().size.x
		var hari: Label = koran.find_child("TeksHari", true, false) as Label
		check(hari.get_global_rect().end.x <= float(t.margin_awal + t.lebar_isi) + 0.5 and hari.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT, "lebar %d: 'Hari 1 · Perumahan Melati' rata kanan di dalam isi" % ukuran[2])
		koran.isi(HalamanUji.nyata(1), 1234567890123456, "perumahan")
		await _tree.process_frame
		await _tree.process_frame
		check(is_equal_approx(koran.rect_isi().size.x, lebar_normal) and hari.get_global_rect().end.x <= float(t.margin_awal + t.lebar_isi) + 0.5, "lebar %d: nomor hari 16 digit: isi tidak melebar (%.0f), label tetap di dalam isi" % [ukuran[2], koran.rect_isi().size.x])
		check(hari.get_global_rect().position.x >= koran.find_child("NamaKoran", true, false).get_global_rect().end.x - 0.5, "lebar %d: label hari tidak menimpa nama koran" % ukuran[2])
		check(is_equal_approx(koran.rect_tombol_berangkat().position.x, float(t.berangkat.position.x)), "lebar %d: Berangkat tidak bergeser" % ukuran[2])
		_bersihkan(koran)

func _test_tampilan_baru() -> void:
	_judul.call("Layar koran: kertas bertekstur, foto dan ikon per efek, kolom misi 236/280, garis tegak, Berangkat 140x42 kanan bawah, kotak iklan (AC-3)")
	var terjemahan: Translation = HalamanUji.pasang_terjemahan()
	for ukuran: Array in SKALA_JENDELA:
		var koran: HalamanKoran = await _siapkan(Vector2i(ukuran[0], ukuran[1]))
		var lebar: int = int(ukuran[2])
		var t: TampilKoran.Tata = koran.tata()
		var etiket: String = "lebar %d" % lebar
		var kertas: TextureRect = koran.find_child("Kertas", true, false) as TextureRect
		check(kertas.texture == GayaHud.tekstur("kertas_tile") and kertas.stretch_mode == TextureRect.STRETCH_TILE and kertas.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "%s: tekstur titik kertas diulang (tile) tanpa penghalusan" % etiket)
		check(kertas.get_global_rect().size == _tree.root.get_visible_rect().size, "%s: tekstur kertas menutup seluruh layar" % etiket)
		koran.isi(HalamanUji.nyata(1), 1, "perumahan")
		await _tree.process_frame
		await _tree.process_frame
		check(is_equal_approx(koran.rect_kolom_misi().size.x, float(t.lebar_misi)) and t.lebar_misi == (280 if lebar >= 800 else 236), "%s: kolom misi %d (236, 280 di lebar 800)" % [etiket, t.lebar_misi])
		check(is_equal_approx(koran.rect_kolom_berita().size.x, float(t.lebar_berita)) and is_equal_approx(koran.rect_garis_tegak().position.x, float(t.x_garis)) and is_equal_approx(koran.rect_garis_tegak().size.x, 1.0), "%s: kolom berita %d, garis tegak 1 px di x %d" % [etiket, t.lebar_berita, t.x_garis])
		check(is_equal_approx(koran.rect_kolom_misi().position.x, float(t.x_misi)), "%s: kolom misi mulai x %d (6 + garis 1 + 6 dari berita)" % [etiket, t.x_misi])
		check(koran.rect_tombol_berangkat() == Rect2(t.berangkat) and koran.rect_tombol_berangkat().size == Vector2(140.0, 42.0), "%s: Berangkat 140x42 di kanan bawah (%s)" % [etiket, koran.rect_tombol_berangkat()])
		check(is_equal_approx(koran.rect_garis_ganda().size.x, float(t.lebar_isi)) and is_equal_approx(koran.rect_garis_ganda().position.y, 46.0) and is_equal_approx(koran.rect_garis_ganda().size.y, 4.0), "%s: garis ganda selebar isi, 4 px, di y 46 (kanvas)" % etiket)
		# Foto jalan: 100x62 di kiri headline, ikon kerucut 24x24 di judul, headline tidak menimpa foto.
		koran.isi(HalamanUji.dengan_efek(HalamanUji.nyata(1), "jalan_diperbaiki"), 1, "perumahan")
		await _tree.process_frame
		await _tree.process_frame
		check(koran.foto_tampil() and koran.nama_foto() == "foto_jalan" and koran.rect_foto().size == Vector2(100.0, 62.0), "%s: efek jalan_diperbaiki: foto jalan 100x62 tampil" % etiket)
		check(koran.nama_ikon_utama() == "icon24_kerucut" and koran.rect_ikon_utama().size == Vector2(24.0, 24.0), "%s: ikon kerucut 24x24 di judul berita utama" % etiket)
		var teks_utama: Label = koran.find_child("TeksUtama", true, false) as Label
		check(teks_utama.get_global_rect().position.x >= koran.rect_foto().end.x + 7.9 and is_equal_approx(teks_utama.get_global_rect().position.y, koran.rect_foto().position.y), "%s: headline 8 px di kanan foto, sejajar atas foto" % etiket)
		koran.isi(HalamanUji.dengan_efek(HalamanUji.nyata(1), "mati_lampu"), 1, "perumahan")
		await _tree.process_frame
		check(koran.nama_foto() == "foto_lampu" and koran.nama_ikon_utama() == "icon24_bohlam" and koran.foto_tampil(), "%s: efek mati_lampu: foto lampu dan ikon bohlam" % etiket)
		koran.isi(HalamanUji.dengan_efek(HalamanUji.nyata(1), "hajatan"), 1, "perumahan")
		await _tree.process_frame
		await _tree.process_frame
		check(not koran.foto_tampil() and koran.nama_foto() == "" and koran.nama_ikon_utama() == "" and not koran.find_child("IkonUtama", true, false).is_visible_in_tree(), "%s: efek hajatan: tanpa foto dan tanpa ikon" % etiket)
		check(is_equal_approx(teks_utama.get_global_rect().position.x, koran.rect_kolom_berita().position.x), "%s: tanpa foto headline mulai di tepi kolom" % etiket)
		check(koran.rect_ikon_misi().size == Vector2(24.0, 24.0), "%s: ikon kucing 24x24 di kotak misi" % etiket)
		# Kotak iklan: hari 1 di kiri bawah kolom berita, 220x54, kotak notifikasi menggantikannya.
		koran.isi(HalamanUji.nyata(1), 1, "perumahan")
		await _tree.process_frame
		await _tree.process_frame
		var iklan: Rect2 = koran.rect_iklan()
		check(koran.iklan_tampil() and iklan.size == Vector2(220.0, 54.0) and is_equal_approx(iklan.position.x, koran.rect_kolom_berita().position.x), "%s: kotak iklan 220x54 di kiri kolom berita (%s)" % [etiket, iklan])
		check(is_equal_approx(iklan.end.y, koran.rect_ruang_iklan().end.y), "%s: kotak iklan menempel di dasar ruang sisa" % etiket)
		check(koran.rect_hiasan_berita().size.y == 12.0 and koran.hiasan_baris() == 3 and koran.rect_hiasan_berita().end.y <= iklan.position.y, "%s: tiga baris hiasan (12 px) di atas kotak iklan" % etiket)
		check(koran.find_child("LabelIklan", true, false).text == "KORAN_IKLAN_BARIS" and tr("KORAN_IKLAN_BARIS") == "IKLAN BARIS", "%s: label iklan lewat kunci KORAN_IKLAN_BARIS = 'IKLAN BARIS'" % etiket)
		koran.tampilkan_notifikasi("KORAN_SAVE_GAGAL")
		check(not koran.iklan_tampil() and koran.notifikasi_tampil(), "%s: seketika saat notifikasi tampil, iklan tersembunyi (tanpa menunggu tata letak)" % etiket)
		await _tree.process_frame
		await _tree.process_frame
		check(not koran.iklan_tampil() and koran.notifikasi_tampil() and koran.rect_notifikasi().size.y >= float(Config.KORAN_NOTIF_TINGGI_MIN_PX) - 0.5, "%s: notifikasi menggantikan iklan, kotak setinggi minimal 42" % etiket)
		check(koran.rect_notifikasi().end.y <= koran.rect_isi().end.y + 0.5 and _luas_tumpang(koran.rect_notifikasi(), koran.rect_tombol_berangkat()) == 0.0, "%s: kotak notifikasi di dalam isi dan tidak menutupi Berangkat" % etiket)
		koran.tampilkan_notifikasi("")
		await _tree.process_frame
		await _tree.process_frame
		check(koran.iklan_tampil(), "%s: notifikasi hilang: iklan kembali" % etiket)
		_bersihkan(koran)
	HalamanUji.lepas_terjemahan(terjemahan)


## Sapuan semua kasus x empat ukuran x save x inset: kolom tidak meluap ke bawah, elemen tidak saling menimpa, iklan hanya tampil bila tidak menumpuk.
func _test_tata_sapuan() -> void:
	_judul.call("Layar koran: sapuan semua kasus, ukuran, notifikasi, dan inset: tanpa tumpang tindih dan tanpa meluap (AC-3, AC-7)")
	var terjemahan: Translation = HalamanUji.pasang_terjemahan()
	var inset: ZonaAman.Inset = ZonaAman.Inset.new()
	inset.awal_x = 24
	inset.akhir_x = 24
	inset.atas = 12
	inset.bawah = 16
	var kasus: Dictionary = {
		"hari 1": HalamanUji.nyata(1),
		"hari 2": HalamanUji.nyata(2),
		"terpanjang foto jalan": HalamanUji.terpanjang(),
		"terpanjang tanpa foto": HalamanUji.dengan_efek(HalamanUji.terpanjang(), "hajatan"),
		"terpanjang foto lampu": HalamanUji.dengan_efek(HalamanUji.terpanjang(), "mati_lampu"),
		"tanpa misi": HalamanUji.tanpa_misi(),
		"lanjutan": HalamanUji.lanjutan_tanpa_misi(),
	}
	var notif: Array[String] = ["", "KORAN_SAVE_RUSAK", "KORAN_SAVE_TIDAK_TERBACA", "KORAN_SAVE_GAGAL"]
	var jumlah: int = 0
	for ukuran: Array in SKALA_JENDELA:
		var koran: HalamanKoran = await _siapkan(Vector2i(ukuran[0], ukuran[1]))
		for dengan_inset: bool in [false, true]:
			koran.atur_inset(inset if dengan_inset else null)
			var t: TampilKoran.Tata = koran.tata()
			var aman: Rect2 = Rect2(float(t.margin_awal), float(t.margin_atas), float(t.lebar_isi), 360.0 - float(t.margin_atas) - float(t.margin_bawah))
			for nama: String in kasus:
				for kunci: String in notif:
					koran.isi(kasus[nama], 12, "perumahan")
					koran.tampilkan_notifikasi(kunci)
					await _tree.process_frame
					await _tree.process_frame
					var etiket: String = "%dx%d inset %s (%s, notif '%s')" % [ukuran[0], ukuran[1], dengan_inset, nama, kunci]
					jumlah += 1
					check(koran.rect_kolom_berita().end.y <= aman.end.y + 0.5 and koran.rect_kolom_misi().end.y <= aman.end.y + 0.5, "%s: kolom tidak meluap ke bawah (berita %.1f, misi %.1f, batas %.1f)" % [etiket, koran.rect_kolom_berita().end.y, koran.rect_kolom_misi().end.y, aman.end.y])
					check(koran.rect_tombol_berangkat() == Rect2(t.berangkat), "%s: Berangkat tepat di kanan bawah isi" % etiket)
					var elemen: Dictionary = {}
					for simpul: Node in koran.find_children("*", "Label", true, false):
						var label: Label = simpul as Label
						if label.is_visible_in_tree() and label.text != "":
							elemen["label " + String(label.name)] = label.get_global_rect()
					elemen["tombol Berangkat"] = koran.rect_tombol_berangkat()
					if koran.ada_misi():
						elemen["tombol Ambil"] = koran.rect_tombol_ambil()
						elemen["tombol Lewati"] = koran.rect_tombol_lewati()
					if koran.foto_tampil():
						elemen["foto"] = koran.rect_foto()
					if koran.nama_ikon_utama() != "":
						elemen["ikon utama"] = koran.rect_ikon_utama()
					elemen["ikon misi"] = koran.rect_ikon_misi()
					if koran.iklan_tampil():
						elemen["kotak iklan"] = koran.rect_iklan()
					if koran.notifikasi_tampil():
						elemen["kotak notifikasi"] = koran.rect_notifikasi()
					var kunci_elemen: Array = elemen.keys()
					var tumpang: Array[String] = []
					var luar: Array[String] = []
					for i: int in range(kunci_elemen.size()):
						var a: String = kunci_elemen[i]
						var batas: Rect2 = aman.grow_individual(0.0, float(Config.KORAN_KEPALA_NAIK_PX), 0.0, 0.0) if a == "label NamaKoran" else aman
						if not batas.grow(0.5).encloses(elemen[a]):
							luar.append(a)
						for j: int in range(i + 1, kunci_elemen.size()):
							var b: String = kunci_elemen[j]
							var anak_kotak: bool = (a == "kotak iklan" and b == "label LabelIklan") or (b == "kotak iklan" and a == "label LabelIklan") or (a == "kotak notifikasi" and b == "label Notifikasi") or (b == "kotak notifikasi" and a == "label Notifikasi")
							if not anak_kotak and _luas_tumpang(elemen[a], elemen[b]) > 0.5:
								tumpang.append("%s x %s" % [a, b])
					check(luar.is_empty(), "%s: semua elemen di dalam zona aman %s" % [etiket, luar])
					check(tumpang.is_empty(), "%s: tidak ada elemen bertumpuk %s" % [etiket, tumpang])
					check(not (koran.iklan_tampil() and koran.notifikasi_tampil()), "%s: iklan dan notifikasi tidak tampil bersamaan" % etiket)
					for ukur: Dictionary in koran.ukur_label():
						if float(ukur["dibutuhkan"]) > float(ukur["tersedia"]) + 1.0 or int(ukur["garis"]) != int(ukur["terlihat"]):
							check(false, "%s: teks %s terpotong" % [etiket, ukur["nama"]])
		_bersihkan(koran)
	check(jumlah == 4 * 2 * 7 * 4, "sapuan memeriksa 224 kombinasi (%d)" % jumlah)
	HalamanUji.lepas_terjemahan(terjemahan)


# --- Ambil/Lewati (AC-23, S-7) ---

func _test_ambil_lewati() -> void:
	_judul.call("Layar koran: Ambil/Lewati bisa dibolak-balik, status dari teks dan bentuk (AC-23, S-7)")
	var koran: HalamanKoran = await _siapkan()
	koran.isi(HalamanUji.nyata(1), 1, "perumahan")
	await _tree.process_frame
	var sinyal: Dictionary = {"ambil": 0, "lewati": 0, "berangkat": 0}
	koran.ambil_diminta.connect(func() -> void: sinyal["ambil"] += 1)
	koran.lewati_diminta.connect(func() -> void: sinyal["lewati"] += 1)
	koran.berangkat_diminta.connect(func() -> void: sinyal["berangkat"] += 1)
	check(koran.pilihan() == HalamanKoran.Pilihan.BELUM, "awalnya tidak ada yang dipilih")
	var tipis: Texture2D = GayaHud.tekstur("koran_btn_tipis")
	var terpilih: Texture2D = GayaHud.tekstur("koran_btn_terpilih")
	check(koran.gaya_tombol(koran.tombol_ambil()).texture == tipis and koran.gaya_tombol(koran.tombol_lewati()).texture == tipis and koran.peran_tombol(koran.tombol_ambil()) == TampilKoran.PeranTombol.TIPIS, "awal: kedua tombol hanya garis tipis (bingkai koran_btn_tipis, 1 px)")
	check(koran.tombol_ambil().icon == null and koran.tombol_lewati().icon == null, "awal: tidak ada glif centang di tombol pilihan")
	var status_belum: String = koran.teks_status()
	koran.tombol_ambil().ditekan.emit()
	var status_ambil: String = koran.teks_status()
	check(koran.pilihan() == HalamanKoran.Pilihan.AMBIL and sinyal["ambil"] == 1 and sinyal["lewati"] == 0, "ketuk Ambil: terpilih AMBIL, sinyal sekali")
	check(status_ambil == "Misi diambil" and status_ambil != status_belum, "teks status berubah: '%s'" % status_ambil)
	check(koran.gaya_tombol(koran.tombol_ambil()).texture == terpilih and koran.gaya_tombol(koran.tombol_lewati()).texture == tipis and koran.peran_tombol(koran.tombol_ambil()) == TampilKoran.PeranTombol.TERPILIH, "bentuk berubah: Ambil berongga dengan bingkai tinta 3 px (koran_btn_terpilih), Lewati tetap garis tipis (bukan hanya warna)")
	check(koran.tombol_ambil().icon == GayaHud.tekstur("glif_centang_gelap") and koran.tombol_lewati().icon == null, "Ambil terpilih bercentang (glif), Lewati tidak")
	check(koran.gaya_tombol(koran.tombol_berangkat()).texture == GayaHud.tekstur("koran_btn_tinta") and koran.gaya_tombol(koran.tombol_ambil()).texture != koran.gaya_tombol(koran.tombol_berangkat()).texture and koran.peran_tombol(koran.tombol_berangkat()) == TampilKoran.PeranTombol.TINTA, "Ambil terpilih (berongga) berbeda bentuk dari Berangkat (terisi tinta penuh): pilihan tidak terbaca sebagai aksi utama kedua (QA-010)")
	check(koran.tombol_berangkat().icon == GayaHud.tekstur("glif_panah_terang"), "Berangkat berpanah")
	koran.tombol_lewati().ditekan.emit()
	check(koran.pilihan() == HalamanKoran.Pilihan.LEWATI and koran.teks_status() == "Misi dilewati" and sinyal["lewati"] == 1, "dibolak-balik ke Lewati: status 'Misi dilewati'")
	check(koran.gaya_tombol(koran.tombol_lewati()).texture == terpilih and koran.gaya_tombol(koran.tombol_ambil()).texture == tipis and koran.tombol_lewati().icon != null and koran.tombol_ambil().icon == null, "bentuk mengikuti: Lewati berongga bingkai tebal dan bercentang, Ambil kembali garis tipis tanpa centang")
	for i: int in range(3):
		koran.tombol_ambil().ditekan.emit()
		koran.tombol_lewati().ditekan.emit()
	check(koran.pilihan() == HalamanKoran.Pilihan.LEWATI and sinyal["ambil"] == 4 and sinyal["lewati"] == 4, "bolak-balik tiga kali lagi: selalu mengikuti ketukan terakhir, tiap ketukan satu sinyal")
	check(status_belum != status_ambil and status_ambil != koran.teks_status() and status_belum != koran.teks_status(), "tiga keadaan punya tiga teks status berbeda")
	check(sinyal["berangkat"] == 0 and koran.tombol_berangkat().is_visible_in_tree() and not koran.tombol_berangkat().disabled, "Berangkat selalu aktif (tidak tergantung pilihan)")
	koran.tombol_berangkat().ditekan.emit()
	check(sinyal["berangkat"] == 1, "ketuk Berangkat memancarkan berangkat_diminta")
	koran.isi(HalamanUji.nyata(1), 1, "perumahan")
	check(koran.pilihan() == HalamanKoran.Pilihan.BELUM and koran.teks_status() == status_belum, "mengisi ulang halaman mengembalikan ke belum dipilih")
	_bersihkan(koran)


func _test_tanpa_misi() -> void:
	_judul.call("Layar koran: tanpa misi tombol Ambil/Lewati tidak tampil, Berangkat tetap bekerja (S-8, AC-23)")
	var koran: HalamanKoran = await _siapkan()
	var berangkat: Array[int] = [0]
	koran.berangkat_diminta.connect(func() -> void: berangkat[0] += 1)
	koran.isi(HalamanUji.tanpa_misi(), 3, "perumahan")
	await _tree.process_frame
	check(not koran.ada_misi() and not koran.tombol_ambil().is_visible_in_tree() and not koran.tombol_lewati().is_visible_in_tree(), "tanpa misi: tombol Ambil dan Lewati tidak tampil")
	check(koran.teks_tampil()[11] == "Tidak ada misi sampingan hari ini" and koran.find_child("TanpaMisi", true, false).is_visible_in_tree(), "teks netral KORAN_TANPA_MISI tampil (keadaan sah, bukan galat)")
	check(koran.tombol_berangkat().is_visible_in_tree(), "Berangkat tetap tampil")
	koran.tombol_berangkat().ditekan.emit()
	check(berangkat[0] == 1, "Berangkat tetap bekerja tanpa misi")
	var terjemahan: Translation = HalamanUji.pasang_terjemahan()
	koran.isi(HalamanUji.lanjutan_tanpa_misi(), 4, "perumahan")
	await _tree.process_frame
	check(not koran.ada_misi() and not koran.tombol_ambil().is_visible_in_tree() and koran.teks_tampil()[8] == HalamanUji.TEKS_LANJUTAN and not koran.find_child("TanpaMisi", true, false).is_visible_in_tree(), "lanjutan tanpa misi (misi_ditunda): headline tampil di baris misi tanpa tombol dan tanpa teks 'tidak ada misi'")
	HalamanUji.lepas_terjemahan(terjemahan)
	_bersihkan(koran)


func _test_notifikasi_dan_zona_aman() -> void:
	_judul.call("Layar koran: notifikasi save rusak satu baris dan inset aman menggeser margin (AC-9, AC-22)")
	var koran: HalamanKoran = await _siapkan(Vector2i(2340, 1080))
	koran.isi(HalamanUji.nyata(1), 1, "perumahan")
	await _tree.process_frame
	check(not koran.rect_label_tampil().is_empty(), "label tampil")
	var teks_rusak: String = "Data simpanan lama tidak terbaca; salinannya disimpan dan permainan mulai dari awal"
	check(koran.teks_tampil().count(teks_rusak) == 0, "tanpa notifikasi: teks save tidak ada di daftar teks")
	var rect_notif: Array[Rect2] = koran.rect_label_tampil()
	koran.tampilkan_notifikasi("KORAN_SAVE_RUSAK")
	await _tree.process_frame
	await _tree.process_frame
	check(koran.notifikasi_tampil() and koran.teks_tampil().count(teks_rusak) == 1 and koran.rect_label_tampil().size() == rect_notif.size(), "notifikasi save rusak menambah tepat satu baris teks (kunci KORAN_SAVE_RUSAK) dan menggantikan label kotak 'Iklan baris' (kanvas: iklan = tanpa save)")
	check(not koran.iklan_tampil(), "kotak 'Iklan baris' tersembunyi selama notifikasi tampil")
	for ukur: Dictionary in koran.ukur_label():
		check(float(ukur["dibutuhkan"]) <= float(ukur["tersedia"]) + 1.0, "dengan notifikasi: teks %s tidak terpotong" % ukur["nama"])
	# Dua kunci notifikasi baru (QA-003, QA-004): terjemahan ada, satu baris, panjang tidak terpotong, dan jujur (tidak mengaku menyimpan salinan).
	for kunci: String in ["KORAN_SAVE_TIDAK_TERBACA", "KORAN_SAVE_GAGAL"]:
		koran.tampilkan_notifikasi(kunci)
		await _tree.process_frame
		await _tree.process_frame
		var teks_notif: String = tr(kunci)
		check(teks_notif != kunci and koran.teks_tampil().count(teks_notif) == 1 and koran.rect_label_tampil().size() == rect_notif.size(), "%s: terjemahan ada dan tampil tepat satu baris" % kunci)
		check(not teks_notif.to_lower().contains("salinannya disimpan"), "%s: tidak mengaku menyimpan salinan" % kunci)
		for ukur: Dictionary in koran.ukur_label():
			check(float(ukur["dibutuhkan"]) <= float(ukur["tersedia"]) + 1.0, "%s: teks %s tidak terpotong" % [kunci, ukur["nama"]])
		var rect_berangkat: Rect2 = koran.rect_tombol_berangkat()
		check(Rect2(Vector2.ZERO, _tree.root.get_visible_rect().size).encloses(rect_berangkat), "%s: Berangkat tetap di dalam layar" % kunci)
	koran.tampilkan_notifikasi("")
	check(koran.teks_tampil().count(teks_rusak) == 0 and not koran.find_child("Notifikasi", true, false).is_visible_in_tree(), "kunci kosong menyembunyikan baris notifikasi")
	var inset: ZonaAman.Inset = ZonaAman.Inset.new()
	inset.awal_x = 30
	inset.akhir_x = 26
	inset.atas = 20
	inset.bawah = 18
	koran.atur_inset(inset)
	await _tree.process_frame
	await _tree.process_frame
	var viewport: Rect2 = Rect2(Vector2.ZERO, _tree.root.get_visible_rect().size)
	var aman: Rect2 = viewport.grow_individual(-30.0, -20.0, -26.0, -18.0)
	check(aman.encloses(koran.rect_isi()) and aman.encloses(koran.rect_tombol_berangkat()), "dengan inset aman (30, 20, 26, 18): isi dan Berangkat di dalam zona aman perangkat")
	var asli: Rect2 = viewport.grow_individual(-12.0, -12.0, -12.0, -12.0)
	check(is_equal_approx(koran.rect_isi().position.x, 30.0) and is_equal_approx(koran.rect_isi().end.x, viewport.size.x - 26.0) and asli.encloses(koran.rect_isi()), "margin = max(12, inset): kiri 30 dan kanan 26 (lebih besar dari 12), atas 20, bawah 18")
	koran.atur_inset(null)
	await _tree.process_frame
	await _tree.process_frame
	check(is_equal_approx(koran.rect_isi().position.x, 12.0) and is_equal_approx(koran.rect_isi().position.y, 12.0), "inset null = margin dasar 12")
	_bersihkan(koran)


func _test_font_dan_warna() -> void:
	_judul.call("Layar koran: font hanya Lilita One dan Lexend, ukuran huruf V-8, warna teks dari token dan kontras >= 7:1 (AC-21, AC-3, AC-6b)")
	var koran: HalamanKoran = await _siapkan()
	koran.isi(HalamanUji.nyata(1), 1, "perumahan")
	koran.tampilkan_notifikasi("KORAN_SAVE_RUSAK")
	await _tree.process_frame
	await _tree.process_frame
	var nama_lilita: Array[String] = ["NamaKoran", "TeksUtama", "TeksRingan", "TeksMisi"]
	# Ukuran huruf V-8 (piksel game): nama 32, headline 24 dan 16 (tidak naik), teks utama 12, kecil 11, mini tebal 10, label 10.
	var ukuran_harapan: Dictionary = {"NamaKoran": 32, "TeksUtama": 24, "TeksRingan": 16, "TeksMisi": 16, "TeksHari": 12, "TanpaMisi": 12, "Ringkasan": 11, "Notifikasi": 11, "StatusMisi": 10, "LabelUtama": 10, "LabelRingan": 10, "LabelMisi": 10, "LabelIklan": 10}
	var jumlah: int = 0
	var ditemui: Array[String] = []
	var kotak_notif: Rect2 = koran.rect_notifikasi()
	for node: Node in _semua(koran):
		if node is Label:
			var label: Label = node as Label
			jumlah += 1
			ditemui.append(String(label.name))
			var familia: String = _familia(label.get_theme_font(&"font"))
			if nama_lilita.has(String(label.name)):
				check(familia.contains("lilita_one"), "%s: headline dan nama koran memakai Lilita One" % label.name)
			else:
				check(familia.contains("lexend"), "%s: teks selain headline memakai Lexend" % label.name)
			check(VARIASI_SAH.has(String(label.theme_type_variation)), "%s: variasi tema dikenal (%s)" % [label.name, label.theme_type_variation])
			check(ukuran_harapan.has(String(label.name)) and label.get_theme_font_size(&"font_size") == int(ukuran_harapan[String(label.name)]), "%s: ukuran huruf %d (V-8)" % [label.name, label.get_theme_font_size(&"font_size")])
			var warna: Color = label.get_theme_color(&"font_color")
			var di_panel: bool = koran.rect_panel_misi().encloses(label.get_global_rect()) or kotak_notif.encloses(label.get_global_rect())
			var latar: Color = Palette.KORAN_KERTAS_2 if di_panel else Palette.KORAN_KERTAS
			check(warna == Palette.KORAN_TINTA or warna == Palette.KORAN_TINTA_2, "%s: warna teks = token KORAN_TINTA atau KORAN_TINTA_2" % label.name)
			check(_kontras(warna, latar) >= Config.KORAN_KONTRAS_TEKS_MIN, "%s: kontras %.2f:1 terhadap latarnya (>= 7:1)" % [label.name, _kontras(warna, latar)])
		elif node is Button:
			var tombol: Button = node as Button
			check(_familia(tombol.get_theme_font(&"font")).contains("lexend"), "%s: teks tombol memakai Lexend" % tombol.name)
			check(tombol.get_theme_font_size(&"font_size") == 12 and tombol.theme_type_variation == &"TombolPeran", "%s: huruf tombol 12 (V-8, TombolPeran)" % tombol.name)
			var isi_tombol: Color = _isi_peran(koran.peran_tombol(tombol as TombolSentuh))
			var warna_tombol: Color = tombol.get_theme_color(&"font_color")
			check(_kontras(warna_tombol, isi_tombol) >= Config.KORAN_KONTRAS_TEKS_MIN, "%s: kontras teks tombol terhadap isinya %.2f:1 (>= 7:1)" % [tombol.name, _kontras(warna_tombol, isi_tombol)])
			check(warna_tombol == TampilKoran.warna_teks_tombol(koran.peran_tombol(tombol as TombolSentuh), false), "%s: warna teks tombol dari TampilKoran" % tombol.name)
			var warna_tekan: Color = tombol.get_theme_color(&"font_pressed_color")
			var isi_tekan: Color = _isi_peran(TampilKoran.PeranTombol.TERPILIH) if koran.peran_tombol(tombol as TombolSentuh) != TampilKoran.PeranTombol.TINTA else Palette.KORAN_TINTA
			check(_kontras(warna_tekan, isi_tekan) >= Config.KORAN_KONTRAS_TEKS_MIN, "%s: kontras teks tombol saat ditekan >= 7:1 (%.2f:1)" % [tombol.name, _kontras(warna_tekan, isi_tekan)])
			check(tombol.get_theme_stylebox(&"normal") is StyleBoxTexture and tombol.get_theme_stylebox(&"pressed") is StyleBoxTexture, "%s: bingkai 9-slice (StyleBoxTexture) normal dan ditekan" % tombol.name)
	# Garis tombol terhadap kertas (komponen UI >= 3:1): TINTA terhadap kertas, tipis memakai KORAN_GARIS di atas KERTAS_2.
	check(_kontras(Palette.KORAN_TINTA, Palette.KORAN_KERTAS) >= Config.KORAN_KONTRAS_GARIS_MIN and _kontras(Palette.KORAN_GARIS, Palette.KORAN_KERTAS) >= Config.KORAN_KONTRAS_GARIS_MIN, "garis tombol tinta dan tipis terhadap kertas >= 3:1")
	check(jumlah == 13 and ditemui.has("LabelIklan") and ditemui.has("Notifikasi"), "pemindai memeriksa 13 label layar koran (%d: %s)" % [jumlah, ditemui])
	check(koran.get_node("Latar").get("color") == Palette.KORAN_KERTAS, "latar layar = token KORAN_KERTAS")
	_bersihkan(koran)


## Warna isi bingkai tombol koran menurut peran (tinta penuh, kertas kedua, kertas terang berongga): dasar kontras teks tombol.
func _isi_peran(peran: TampilKoran.PeranTombol) -> Color:
	match peran:
		TampilKoran.PeranTombol.TINTA:
			return Palette.KORAN_TINTA
		TampilKoran.PeranTombol.TERPILIH:
			return Palette.KORAN_KERTAS
	return Palette.KORAN_KERTAS_2


func _test_tanpa_tombol_jeda() -> void:
	_judul.call("Layar koran: tidak ada tombol jeda atau kontrol sentuh gameplay (AC-22)")
	var koran: HalamanKoran = await _siapkan()
	var terlarang: Array[String] = []
	for node: Node in _semua(koran):
		if node is TombolJeda or node is KontrolTouch or String(node.name).to_lower().contains("jeda"):
			terlarang.append(String(node.name))
	check(terlarang.is_empty(), "tidak ada tombol jeda, stick, atau kontrol sentuh di layar koran: %s" % [terlarang])
	var tombol: Array[String] = []
	for node: Node in _semua(koran):
		if node is Button:
			tombol.append(String(node.name))
	check(tombol == ["TombolAmbil", "TombolLewati", "TombolBerangkat"], "tepat tiga tombol: %s" % [tombol])
	_bersihkan(koran)
