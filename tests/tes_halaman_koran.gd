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
const VARIASI_SAH: Array[String] = ["JudulBesar", "JudulLayar", "HudLabel", "HudTeks", "TeksKecil"]

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
			var label_rect: Array[Rect2] = koran.rect_label_tampil()
			for r: Rect2 in label_rect:
				check(aman.encloses(r), "%s: label di dalam zona aman: %s" % [label_kasus, r])
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
	var gaya_ambil: StyleBoxFlat = koran.gaya_tombol(koran.tombol_ambil())
	var gaya_lewati: StyleBoxFlat = koran.gaya_tombol(koran.tombol_lewati())
	check(gaya_ambil.bg_color == Palette.KORAN_KERTAS_2 and gaya_lewati.bg_color == Palette.KORAN_KERTAS_2 and gaya_ambil.border_width_left == 1 and gaya_lewati.border_width_left == 1, "awal: kedua tombol hanya garis tipis (1 px) di atas kertas kedua")
	var status_belum: String = koran.teks_status()
	koran.tombol_ambil().ditekan.emit()
	var status_ambil: String = koran.teks_status()
	var ambil_terpilih: StyleBoxFlat = koran.gaya_tombol(koran.tombol_ambil())
	var lewati_biasa: StyleBoxFlat = koran.gaya_tombol(koran.tombol_lewati())
	check(koran.pilihan() == HalamanKoran.Pilihan.AMBIL and sinyal["ambil"] == 1 and sinyal["lewati"] == 0, "ketuk Ambil: terpilih AMBIL, sinyal sekali")
	check(status_ambil == "Misi diambil" and status_ambil != status_belum, "teks status berubah: '%s'" % status_ambil)
	check(ambil_terpilih.bg_color == Palette.KORAN_TINTA and ambil_terpilih.border_width_left == Config.KORAN_BINGKAI_TERPILIH_PX and lewati_biasa.bg_color == Palette.KORAN_KERTAS_2 and lewati_biasa.border_width_left == 1, "bentuk berubah: Ambil terisi gelap dengan bingkai 3 px, Lewati tetap garis tipis (bukan hanya warna)")
	koran.tombol_lewati().ditekan.emit()
	check(koran.pilihan() == HalamanKoran.Pilihan.LEWATI and koran.teks_status() == "Misi dilewati" and sinyal["lewati"] == 1, "dibolak-balik ke Lewati: status 'Misi dilewati'")
	check(koran.gaya_tombol(koran.tombol_lewati()).bg_color == Palette.KORAN_TINTA and koran.gaya_tombol(koran.tombol_ambil()).bg_color == Palette.KORAN_KERTAS_2, "bentuk mengikuti: Lewati terisi, Ambil kembali garis tipis")
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
	var tanpa: int = koran.teks_tampil().count("Data simpanan lama tidak terbaca; salinannya disimpan dan permainan mulai dari awal")
	check(tanpa == 1, "teks notifikasi ada di daftar teks (satu kunci KORAN_SAVE_RUSAK)")
	var rect_notif: Array[Rect2] = koran.rect_label_tampil()
	koran.tampilkan_notifikasi_rusak(true)
	await _tree.process_frame
	await _tree.process_frame
	check(koran.rect_label_tampil().size() == rect_notif.size() + 1, "notifikasi save rusak menambah tepat satu baris teks")
	for ukur: Dictionary in koran.ukur_label():
		check(float(ukur["dibutuhkan"]) <= float(ukur["tersedia"]) + 1.0, "dengan notifikasi: teks %s tidak terpotong" % ukur["nama"])
	koran.tampilkan_notifikasi_rusak(false)
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
	_judul.call("Layar koran: font hanya Lilita One dan Lexend, warna teks dari token dan kontras >= 7:1 (AC-21)")
	var koran: HalamanKoran = await _siapkan()
	koran.isi(HalamanUji.nyata(1), 1, "perumahan")
	await _tree.process_frame
	var nama_lilita: Array[String] = ["NamaKoran", "TeksUtama", "TeksRingan", "TeksMisi"]
	var jumlah: int = 0
	for node: Node in _semua(koran):
		if node is Label:
			var label: Label = node as Label
			jumlah += 1
			var familia: String = _familia(label.get_theme_font(&"font"))
			if nama_lilita.has(String(label.name)):
				check(familia.contains("lilita_one"), "%s: headline dan nama koran memakai Lilita One" % label.name)
			else:
				check(familia.contains("lexend"), "%s: teks selain headline memakai Lexend" % label.name)
			check(VARIASI_SAH.has(String(label.theme_type_variation)) or String(label.theme_type_variation).is_empty(), "%s: variasi tema dikenal (%s)" % [label.name, label.theme_type_variation])
			var warna: Color = label.get_theme_color(&"font_color")
			var latar: Color = Palette.KORAN_KERTAS_2 if koran.rect_panel_misi().encloses(label.get_global_rect()) else Palette.KORAN_KERTAS
			check(warna == Palette.KORAN_TINTA or warna == Palette.KORAN_TINTA_2, "%s: warna teks = token KORAN_TINTA atau KORAN_TINTA_2" % label.name)
			check(_kontras(warna, latar) >= Config.KORAN_KONTRAS_TEKS_MIN, "%s: kontras %.2f:1 terhadap latarnya (>= 7:1)" % [label.name, _kontras(warna, latar)])
		elif node is Button:
			var tombol: Button = node as Button
			check(_familia(tombol.get_theme_font(&"font")).contains("lexend"), "%s: teks tombol memakai Lexend" % tombol.name)
			var normal: StyleBoxFlat = tombol.get_theme_stylebox(&"normal") as StyleBoxFlat
			var warna_tombol: Color = tombol.get_theme_color(&"font_color")
			check(_kontras(warna_tombol, normal.bg_color) >= Config.KORAN_KONTRAS_TEKS_MIN, "%s: kontras teks tombol terhadap isinya %.2f:1 (>= 7:1)" % [tombol.name, _kontras(warna_tombol, normal.bg_color)])
			var ditekan: StyleBoxFlat = tombol.get_theme_stylebox(&"pressed") as StyleBoxFlat
			check(_kontras(tombol.get_theme_color(&"font_pressed_color"), ditekan.bg_color) >= Config.KORAN_KONTRAS_TEKS_MIN, "%s: kontras teks tombol saat ditekan >= 7:1" % tombol.name)
			check(_kontras(normal.border_color, Palette.KORAN_KERTAS_2) >= Config.KORAN_KONTRAS_GARIS_MIN, "%s: garis tombol terhadap kertas >= 3:1" % tombol.name)
	check(jumlah >= 11, "pemindai memeriksa label layar koran (%d)" % jumlah)
	check(koran.get_node("Latar").get("color") == Palette.KORAN_KERTAS, "latar layar = token KORAN_KERTAS")
	_bersihkan(koran)


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
