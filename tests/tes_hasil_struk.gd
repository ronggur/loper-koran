class_name TesHasilStruk
extends RefCounted
## Tes layar hasil struk di scene (run ui2-semua-layar bagian A, AC-2, AC-7, AC-10, AC-11): `scenes/ui/layar_hasil.tscn` dengan data buatan (`HasilRute.Angka`, `ReputationManager.Hasil`, `MilestoneTracker.Ringkasan`)
## di enam ukuran jendela: struk 9-slice bergerigi dan takik di tepi luar, angka "Terkirim" dan "Koin" 32 px, ikon dan glif, rekap misi (selesai sesudah baris berhasil, gagal sesudah tenggat; nama unik `%RekapMisi`
## tetap ada sesudah dipindah), kolom samping (lebar 236 dan 300, sejajar struk bila muat, sejajar judul bila tidak, tidak menutupi tombol), struk tanpa samping yang digeser dari tombol, tombol aksi 140x42 kanan bawah
## (peran utama, sinyal), inset aman, huruf V-8, kontras token teks >= 7:1 di atas isi struk dan kartu, dan teks panjang yang berbungkus kata. Tidak menyentuh `user://save.json`.

const BERKAS_HASIL: String = "res://scenes/ui/layar_hasil.tscn"
## [lebar jendela, tinggi jendela, lebar viewport game].
const JENDELA: Array = [[1920, 1080, 640], [2001, 1080, 667], [2100, 1080, 700], [2340, 1080, 780], [2400, 1080, 800], [1600, 720, 800]]

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
	_test_aset_dan_gaya()
	await _test_struk_dan_angka()
	await _test_takik_menempel_tepi()
	await _test_rekap_misi_posisi_dan_nama_unik()
	await _test_kolom_sejajar_atau_naik()
	await _test_tanpa_samping_digeser()
	await _test_tombol_aksi()
	for jendela: Array in JENDELA:
		await _test_kasus_terpadat(jendela)
	await _test_inset_terpadat()
	await _test_kontras_dan_huruf()
	await _test_teks_panjang()


# --- Pembantu ---

func _angka(terkirim: int, koin: int, terbuang: int = 0) -> HasilRute.Angka:
	var a: HasilRute.Angka = HasilRute.Angka.new()
	a.pelanggan = 25
	a.terkirim = terkirim
	a.meleset = 25 - terkirim
	a.koin = koin
	a.skor = 14780
	a.lempar_terbuang = terbuang
	a.potongan = terbuang * Config.KOIN_POTONGAN_KORAN_MELESET
	return a


func _angka_padat() -> HasilRute.Angka:
	var a: HasilRute.Angka = _angka(2, 150, 25)
	a.tenggat_lewat = true
	a.detik_lewat = 72
	a.misi_hasil = "selesai"
	a.koin_misi = 75
	a.koin_tip = 15
	a.jumlah_tip = 2
	return a


func _rep(sebelum: int, sesudah: int, jumlah: Array) -> ReputationManager.Hasil:
	var h: ReputationManager.Hasil = ReputationManager.Hasil.new()
	h.reputasi_sebelum = sebelum
	h.reputasi_sesudah = sesudah
	h.perubahan = sesudah - sebelum
	var jenis: Array = [ReputationManager.Jenis.BARU, ReputationManager.Jenis.SETIA, ReputationManager.Jenis.BERHENTI, ReputationManager.Jenis.KEMBALI]
	for i: int in range(4):
		for n: int in range(int(jumlah[i])):
			var p: ReputationManager.Peristiwa = ReputationManager.Peristiwa.new()
			p.jenis = jenis[i]
			p.id_rumah = "x@%d" % n
			h.peristiwa.append(p)
	return h


func _ms(setia: int, koin_total: int, misi: int, servis: int) -> Dictionary:
	var s: Dictionary = DataSave.templat()
	var pelanggan: Dictionary = {}
	for i: int in range(setia):
		pelanggan["s@%d" % i] = {"status": "setia", "antar": 5, "meleset": 0, "hari_berhenti": 0}
	s["pelanggan"] = pelanggan
	s["koin_total"] = koin_total
	var riwayat: Dictionary = {}
	for i: int in range(misi):
		riwayat["m%d" % i] = {"hasil": "selesai", "hari": i + 1}
	s["misi_hasil"] = riwayat
	s["sepeda"]["servis_total"] = servis
	return s


func _padat_ringkas() -> MilestoneTracker.Ringkasan:
	return MilestoneTracker.ringkas(_ms(2, 990, 0, 0), _ms(10, 5100, 1, 4))


## Ringkasan ringan: satu target dan satu tingkat baru (koin 700 -> 1080 melewati 1000).
func _ringan_ringkas() -> MilestoneTracker.Ringkasan:
	return MilestoneTracker.ringkas(_ms(7, 700, 0, 0), _ms(7, 1080, 0, 0))


func _layar(jendela: Vector2i) -> LayarHasil:
	_tree.root.size = jendela
	var l: LayarHasil = (load(BERKAS_HASIL) as PackedScene).instantiate() as LayarHasil
	_tree.root.add_child(l)
	await _tree.process_frame
	return l


func _tampil(l: LayarHasil) -> void:
	l.tampilkan(true)
	await _tree.process_frame
	await _tree.process_frame
	await _tree.process_frame


func _buang(l: LayarHasil) -> void:
	_tree.root.remove_child(l)
	l.free()


func _misi() -> DataMisi:
	return PemuatMisi.muat_folder().cari("p1_kucing")


func _luminans(w: Color) -> float:
	var kanal: Array[float] = []
	for c: float in [w.r, w.g, w.b]:
		kanal.append(c / 12.92 if c <= 0.03928 else pow((c + 0.055) / 1.055, 2.4))
	return 0.2126 * kanal[0] + 0.7152 * kanal[1] + 0.0722 * kanal[2]


func _kontras(a: Color, b: Color) -> float:
	var la: float = _luminans(a)
	var lb: float = _luminans(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


# --- Aset dan gaya ---

func _test_aset_dan_gaya() -> void:
	_judul.call("Hasil (struk): aset terpasang, GayaHud.struk 9-slice tepi mendatar diulang, tema LayarAngkaBesar Lilita 32 (AC-10, AC-11)")
	var s: StyleBoxTexture = GayaHud.struk()
	check(s.texture == GayaHud.tekstur("struk") and s.get_texture_margin(SIDE_LEFT) == float(Config.UI_PANEL_SLICE_PX) and s.get_texture_margin(SIDE_BOTTOM) == float(Config.UI_PANEL_SLICE_PX), "struk: tekstur terpasang, tepi 9-slice = UI_PANEL_SLICE_PX")
	check(s.axis_stretch_horizontal == StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT and s.axis_stretch_vertical == StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT, "struk: tepi bergerigi diulang (TILE_FIT, seperti border-image round kanvas)")
	check(s.content_margin_left == 12.0 and s.content_margin_right == 12.0 and s.content_margin_top == 10.0 and s.content_margin_bottom == 10.0, "struk: isi berjarak 12 samping, 10 atas dan bawah (kanvas padding 8 + tepi 4, atas 6 + 4)")
	var kustom: StyleBoxTexture = GayaHud.struk(20, 6, 7)
	check(kustom.content_margin_left == 20.0 and kustom.content_margin_top == 6.0 and kustom.content_margin_bottom == 7.0, "struk dengan jarak isi kustom")
	var tema: Theme = load("res://assets/ui/theme.tres")
	check(tema.get_type_variation_base(&"LayarAngkaBesar") == &"Label" and tema.get_font_size(&"font_size", &"LayarAngkaBesar") == 32, "variation LayarAngkaBesar: Label 32")
	check(tema.get_font(&"font", &"LayarAngkaBesar") == tema.get_font(&"font", &"LayarJudul"), "angka besar 32 memakai Lilita One yang sama dengan judul (tanpa font baru)")
	for nama: String in ["struk", "struk_takik", "icon24_koin", "icon24_bintang", "lencana32_emas", "glif_naik_ok", "glif_turun_teks2", "glif_seru_warn", "glif_centang_ok", "glif_centang_teks2"]:
		check(GayaHud.tekstur(nama) != null, "tekstur %s dimuat di GayaHud" % nama)


# --- Struk ---

func _test_struk_dan_angka() -> void:
	_judul.call("Hasil (struk): struk bergerigi, angka Terkirim dan Koin 32 px, ikon koin 24, glif centang hijau hanya bila semua terantar, baris berhasil dan netral berurut (AC-2)")
	var l: LayarHasil = await _layar(Vector2i(1920, 1080))
	l.isi(_angka(22, 355, 3), null, [] as Array[String], 120, _rep(10, 12, [1, 0, 0, 0]), _padat_ringkas())
	await _tampil(l)
	var struk: PanelContainer = l.find_child("PanelStruk", true, false) as PanelContainer
	check((struk.get_theme_stylebox(&"panel") as StyleBoxTexture).texture == GayaHud.tekstur("struk"), "struk memakai tekstur struk terpasang")
	var terkirim: Label = l.find_child("NilaiTerkirim", true, false) as Label
	var koin: Label = l.find_child("NilaiKoin", true, false) as Label
	check(terkirim.get_theme_font_size(&"font_size") == 32 and koin.get_theme_font_size(&"font_size") == 32 and terkirim.theme_type_variation == &"LayarAngkaBesar", "angka Terkirim dan Koin 32 px (LayarAngkaBesar)")
	check(terkirim.text == "22/25" and koin.text == "355" and koin.get_theme_color(&"font_color") == Palette.ACCENT and terkirim.get_theme_color(&"font_color") == Palette.TEXT, "teks angka dari HasilRute.Angka: '22/25' TEXT dan '355' ACCENT")
	var ikon_koin: TextureRect = l.find_child("IkonKoin", true, false) as TextureRect
	check(ikon_koin.texture == GayaHud.tekstur("icon24_koin") and ikon_koin.size.x >= 24.0, "ikon koin 24 di samping angka Koin")
	var glif: TextureRect = l.find_child("GlifTerkirim", true, false) as TextureRect
	check(glif.texture == GayaHud.tekstur("glif_centang_teks2"), "22 dari 25: centang abu-abu")
	l.isi(_angka(25, 510), null, [] as Array[String])
	check(glif.texture == GayaHud.tekstur("glif_centang_ok"), "25 dari 25: centang hijau")
	l.isi(_angka(0, 0), null, [] as Array[String])
	check(glif.texture == GayaHud.tekstur("glif_centang_teks2"), "0 dari 25: centang abu-abu")
	check(l.teks_tampil().slice(0, 4) == ["Hasil antaran", "Terkirim", "0/25", "Tip"], "urutan teks tetap: judul, Terkirim, nilai, Tip (API tes lama)")
	_buang(l)


func _test_takik_menempel_tepi() -> void:
	_judul.call("Hasil (struk): takik tiket di garis sobek menempel di tepi luar struk (kiri apa adanya, kanan dicerminkan), dua garis sobek memisahkan berhasil dari netral (AC-2)")
	var l: LayarHasil = await _layar(Vector2i(1920, 1080))
	l.isi(_angka(22, 355, 3), null, [] as Array[String], 120, _rep(10, 12, [1, 0, 0, 0]), _padat_ringkas())
	await _tampil(l)
	var struk: Rect2 = l.rect_panel()
	for nama: String in ["SobekAtas", "SobekBawah"]:
		var sobek: GarisSobek = l.find_child(nama, true, false) as GarisSobek
		var takik: Array[Rect2] = sobek.rect_takik()
		var g: Vector2 = sobek.get_global_rect().position
		var awal: Rect2 = Rect2(g + takik[0].position, takik[0].size)
		var akhir: Rect2 = Rect2(g + takik[1].position, takik[1].size)
		check(is_equal_approx(awal.position.x, struk.position.x) and is_equal_approx(akhir.end.x, struk.end.x), "%s: takik awal menempel tepi awal struk (%.1f) dan takik akhir menempel tepi akhir (%.1f)" % [nama, struk.position.x, struk.end.x])
		check(awal.size == Vector2(6, 10) and akhir.size == Vector2(6, 10) and struk.encloses(awal) and struk.encloses(akhir), "%s: takik 6x10 di dalam struk" % nama)
		check(is_equal_approx(sobek.size.y, float(Config.HASIL_SOBEK_TINGGI_PX)) and takik[0].position.y >= 0.0 and takik[0].end.y <= sobek.size.y, "%s: setinggi %d dan takik di dalam tinggi garis" % [nama, Config.HASIL_SOBEK_TINGGI_PX])
	var atas: Control = l.find_child("SobekAtas", true, false) as Control
	var bawah: Control = l.find_child("SobekBawah", true, false) as Control
	var tip: Rect2 = l.rect_label()[5]
	check(atas.get_global_rect().position.y < tip.position.y and bawah.get_global_rect().position.y > tip.position.y, "sobek atas di atas baris Tip, sobek bawah di bawah baris berhasil")
	check(bawah.get_global_rect().end.y <= l.rect_label()[l.rect_label().size() - 1].end.y, "baris netral dan sesudahnya di bawah sobek bawah")
	_buang(l)


func _test_rekap_misi_posisi_dan_nama_unik() -> void:
	_judul.call("Hasil (struk): rekap misi selesai (hijau, bercentang) sesudah baris berhasil, gagal (netral, tanpa glif) sesudah tenggat; %RekapMisi tetap ditemukan sesudah dipindah (regresi hilangnya pemilik node)")
	var l: LayarHasil = await _layar(Vector2i(1920, 1080))
	var selesai: HasilRute.Angka = _angka(22, 355)
	selesai.misi_hasil = "selesai"
	selesai.koin_misi = 75
	l.isi(selesai, _misi(), [] as Array[String])
	await _tampil(l)
	var rekap: Label = l.get_node("%RekapMisi") as Label
	var baris: Control = rekap.get_parent() as Control
	var daftar: Control = l.find_child("DaftarBerhasil", true, false) as Control
	var sobek: Control = l.find_child("SobekBawah", true, false) as Control
	check(baris.get_index() == daftar.get_index() + 1 and sobek.get_index() == baris.get_index() + 1, "misi selesai: tepat sesudah baris berhasil, sebelum sobek bawah")
	check(rekap.get_theme_color(&"font_color") == Palette.OK and (l.get_node("%GlifMisi") as TextureRect).visible and l.teks_rekap_misi() == "Misi: Kucing ketemu! +75 koin", "misi selesai: hijau OK, glif centang tampil, teks dari kunci banner")
	var gagal: HasilRute.Angka = _angka(22, 355)
	gagal.misi_hasil = "gagal"
	l.isi(gagal, _misi(), [] as Array[String])
	await _tampil(l)
	var tenggat: Control = l.find_child("TeksTenggat", true, false) as Control
	check(l.get_node_or_null("%RekapMisi") != null and l.get_node("%RekapMisi") == rekap, "%RekapMisi masih ditemukan sesudah dipindah ke bawah tenggat")
	check(baris.get_index() == tenggat.get_index() + 1, "misi gagal: tepat sesudah teks tenggat")
	check(rekap.get_theme_color(&"font_color") == Palette.TEXT_2 and not (l.get_node("%GlifMisi") as TextureRect).visible and l.teks_rekap_misi() == "Misi: Kucingnya lolos hari ini", "misi gagal: netral TEXT_2 tanpa glif, tanpa kata gagal ('lolos')")
	l.isi(selesai, _misi(), [] as Array[String])
	await _tampil(l)
	check(baris.get_index() == daftar.get_index() + 1 and l.get_node_or_null("%RekapMisi") != null, "dipindah kembali ke atas: posisi dan nama unik tetap")
	l.isi(_angka(22, 355), null, [] as Array[String])
	check(l.teks_rekap_misi() == "" and not baris.visible, "tanpa misi: baris rekap tersembunyi")
	_buang(l)


# --- Kolom samping ---

func _test_kolom_sejajar_atau_naik() -> void:
	_judul.call("Hasil (struk): kolom samping sejajar struk (kartu pertama di y struk) bila muat di atas tombol, naik sejajar judul bila tidak; selalu di atas tombol dan tidak menutupi struk (AC-2)")
	var l: LayarHasil = await _layar(Vector2i(1920, 1080))
	l.isi(_angka(22, 355, 3), null, [] as Array[String], 120, _rep(10, 12, [1, 0, 0, 0]), _ringan_ringkas())
	await _tampil(l)
	var struk: Rect2 = l.rect_panel()
	var kartu: Array[Rect2] = l.rect_kartu()
	check(is_equal_approx(kartu[0].position.y, struk.position.y), "kasus ringan: kartu reputasi sejajar atas struk (y %.1f = %.1f)" % [kartu[0].position.y, struk.position.y])
	check(is_equal_approx(l.rect_judul().position.y, 12.0) and is_equal_approx(struk.position.y, 44.0), "judul y 12 dan struk y 44 (kanvas 44 = 12 + 32)")
	l.isi(_angka_padat(), _misi(), ["ban", "rem", "rantai"] as Array[String], 10, _rep(55, 53, [4, 3, 2, 1]), _padat_ringkas())
	await _tampil(l)
	var kolom: Rect2 = l.rect_panel_kanan()
	check(is_equal_approx(kolom.position.y, 12.0) and kolom.end.y <= float(l.tata().batas_bawah_kolom) + 0.5 and not kolom.intersects(l.rect_tombol()) and not kolom.intersects(l.rect_panel()), "kasus terpadat: kolom naik ke y 12, berakhir y %.1f <= %d, tidak menutupi tombol atau struk" % [kolom.end.y, l.tata().batas_bawah_kolom])
	check(l.teks_baru().size() == 3 and l.teks_pelanggan().size() == 4 and l.rect_kartu().size() == 3, "tiga kartu, empat baris pelanggan, tiga tingkat baru tampil")
	l.isi(_angka(22, 355, 3), null, [] as Array[String], 120, _rep(10, 12, [1, 0, 0, 0]), _ringan_ringkas())
	await _tampil(l)
	check(is_equal_approx(l.rect_kartu()[0].position.y, l.rect_panel().position.y), "kembali ke kasus ringan: kolom sejajar struk lagi")
	_buang(l)
	var l8: LayarHasil = await _layar(Vector2i(2400, 1080))
	l8.isi(_angka(22, 355, 3), null, [] as Array[String], 120, _rep(10, 12, [1, 0, 0, 0]), _padat_ringkas())
	await _tampil(l8)
	check(is_equal_approx(l8.rect_panel_kanan().size.x, 300.0) and is_equal_approx(l8.rect_panel().size.x, 466.0), "lebar 800: kolom 300 dan struk 466")
	_buang(l8)
	var l6: LayarHasil = await _layar(Vector2i(1920, 1080))
	l6.isi(_angka(22, 355, 3), null, [] as Array[String], 120, _rep(10, 12, [1, 0, 0, 0]), _padat_ringkas())
	await _tampil(l6)
	check(is_equal_approx(l6.rect_panel_kanan().size.x, 236.0) and is_equal_approx(l6.rect_panel().size.x, 370.0), "lebar 640: kolom 236 dan struk 370")
	_buang(l6)


func _test_tanpa_samping_digeser() -> void:
	_judul.call("Hasil (struk): tanpa data reputasi struk 360 ke tengah (x 140 di 640); kasus terpadat digeser ke kiri (x 122) supaya tidak menutupi tombol (AC-2)")
	var l: LayarHasil = await _layar(Vector2i(1920, 1080))
	l.isi(_angka(22, 355, 3))
	await _tampil(l)
	check(not l.kanan_tampil() and is_equal_approx(l.rect_panel().size.x, 360.0) and is_equal_approx(l.rect_panel().position.x, 140.0), "tanpa samping, rendah: struk 360 di tengah x 140: %s" % l.rect_panel())
	l.isi(_angka_padat(), _misi(), ["ban", "rem", "rantai"] as Array[String], 10)
	await _tampil(l)
	check(is_equal_approx(l.rect_panel().position.x, 122.0) and not l.rect_panel().intersects(l.rect_tombol()), "tanpa samping, terpadat: digeser ke x 122 dan tidak menutupi tombol: %s %s" % [l.rect_panel(), l.rect_tombol()])
	l.isi(_angka(22, 355, 3))
	await _tampil(l)
	check(is_equal_approx(l.rect_panel().position.x, 140.0), "kembali rendah: tengah lagi (x 140)")
	_buang(l)
	var l8: LayarHasil = await _layar(Vector2i(2400, 1080))
	l8.isi(_angka_padat(), _misi(), ["ban", "rem", "rantai"] as Array[String], 10)
	await _tampil(l8)
	check(is_equal_approx(l8.rect_panel().position.x, 220.0) and not l8.rect_panel().intersects(l8.rect_tombol()), "800 terpadat tanpa samping: tetap di tengah x 220 (tombol jauh di x 648)")
	_buang(l8)


# --- Tombol aksi ---

func _test_tombol_aksi() -> void:
	_judul.call("Hasil (struk): tombol aksi utama 140x42 di kanan bawah (margin 12), peran utama, 'Ke bengkel' atau 'Main lagi', memancarkan sinyal tepat sekali (AC-2, AC-7)")
	for jendela: Array in JENDELA:
		var l: LayarHasil = await _layar(Vector2i(jendela[0], jendela[1]))
		l.isi(_angka(22, 355))
		await _tampil(l)
		var t: Rect2 = l.rect_tombol()
		check(absf(t.size.x - 140.0) < 0.5 and absf(t.size.y - 42.0) < 0.5 and absf(t.end.x - float(jendela[2] - 12)) < 0.5 and absf(t.end.y - 348.0) < 0.5, "lebar %d: tombol 140x42 berakhir (%d, 348): %s" % [jendela[2], jendela[2] - 12, t])
		check((l.tombol_main_lagi().get_theme_stylebox(&"normal") as StyleBoxTexture).texture == GayaHud.tekstur("btn_utama") and l.teks_tombol() == "Main lagi", "lebar %d: peran utama (btn_utama) dan teks 'Main lagi'" % jendela[2])
		_buang(l)
	var l2: LayarHasil = await _layar(Vector2i(1920, 1080))
	l2.isi(_angka(22, 355))
	l2.atur_mode_hari(true)
	await _tampil(l2)
	var n_bengkel: Array[int] = [0, 0]
	l2.bengkel_diminta.connect(func() -> void: n_bengkel[0] += 1)
	l2.main_lagi_diminta.connect(func() -> void: n_bengkel[1] += 1)
	l2.tombol_main_lagi().pressed.emit()
	check(l2.teks_tombol() == "Ke bengkel" and n_bengkel == [1, 0], "mode hari: 'Ke bengkel' memancarkan bengkel_diminta sekali, bukan main_lagi_diminta")
	l2.atur_mode_hari(false)
	await _tree.process_frame
	l2.tombol_main_lagi().pressed.emit()
	check(n_bengkel == [1, 1], "mode rute sendiri: main_lagi_diminta sekali")
	_buang(l2)


# --- Ukuran jendela ---

func _test_kasus_terpadat(jendela: Array) -> void:
	_judul.call("Hasil (struk) %dx%d (viewport %d): kasus terpadat tanpa dan dengan kolom samping muat di 360 tinggi, tidak bertumpuk, tidak terpotong, tombol >= 42x84 (AC-2, AC-7)" % [jendela[0], jendela[1], jendela[2]])
	var layar: Rect2 = Rect2(Vector2.ZERO, Vector2(jendela[2], 360))
	for dengan_samping: bool in [true, false]:
		var l: LayarHasil = await _layar(Vector2i(jendela[0], jendela[1]))
		var rep: ReputationManager.Hasil = _rep(55, 53, [4, 3, 2, 1]) if dengan_samping else null
		var ms: MilestoneTracker.Ringkasan = _padat_ringkas() if dengan_samping else null
		l.atur_mode_hari(true)
		l.isi(_angka_padat(), _misi(), ["ban", "rem", "rantai"] as Array[String], 10, rep, ms)
		await _tampil(l)
		var tag: String = "%d %s" % [jendela[2], "dengan samping" if dengan_samping else "tanpa samping"]
		var struk: Rect2 = l.rect_panel()
		var tombol: Rect2 = l.rect_tombol()
		var kolom: Rect2 = l.rect_panel_kanan()
		check(layar.encloses(struk) and layar.encloses(tombol) and layar.encloses(l.rect_judul()) and (not dengan_samping or layar.encloses(kolom)), "%s: struk %s, tombol %s, judul di dalam layar" % [tag, struk, tombol])
		check(not struk.intersects(tombol) and (not dengan_samping or (not kolom.intersects(tombol) and not kolom.intersects(struk))), "%s: struk, kolom, dan tombol tidak bertumpuk" % tag)
		var dalam: bool = true
		for r: Rect2 in l.rect_label():
			dalam = dalam and struk.encloses(r) and r.size.x > 0.0
		check(dalam, "%s: semua label di dalam struk" % tag)
		var isi_kolom: bool = true
		for r: Rect2 in l.rect_isi_kanan():
			isi_kolom = isi_kolom and kolom.encloses(r)
		check(isi_kolom and (not dengan_samping or l.rect_isi_kanan().size() >= 20), "%s: %d isi kolom di dalam kolom" % [tag, l.rect_isi_kanan().size()])
		var terpotong: Array[String] = []
		for simpul: Node in l.find_children("*", "Label", true, false):
			var label: Label = simpul as Label
			if not label.is_visible_in_tree() or label.text == "":
				continue
			if label.get_visible_line_count() != label.get_line_count() or label.size.y + 0.5 < float(label.get_line_count()) * float(label.get_line_height()):
				terpotong.append(label.text)
			var lebar_teks: float = label.get_theme_font(&"font").get_string_size(tr(label.text), HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size(&"font_size")).x
			if label.autowrap_mode == TextServer.AUTOWRAP_OFF and label.size.x + 0.5 < lebar_teks:
				terpotong.append(label.text)
		check(terpotong.is_empty(), "%s: tidak ada teks terpotong: %s" % [tag, terpotong])
		check(tombol.size.y >= 42.0 and tombol.size.x >= 84.0, "%s: tombol >= 42 tinggi dan >= 84 lebar" % tag)
		_buang(l)


func _test_inset_terpadat() -> void:
	_judul.call("Hasil (struk): kasus terpadat dengan inset aman 36/24/16/20 di 640: struk, kolom, judul, dan tombol di dalam zona aman, tidak bertumpuk (AC-2, inset aman)")
	var inset: ZonaAman.Inset = ZonaAman.Inset.new()
	inset.awal_x = 36
	inset.akhir_x = 24
	inset.atas = 16
	inset.bawah = 20
	var l: LayarHasil = await _layar(Vector2i(1920, 1080))
	l.atur_inset(inset)
	l.atur_mode_hari(true)
	l.isi(_angka_padat(), _misi(), ["ban", "rem", "rantai"] as Array[String], 10, _rep(55, 53, [4, 3, 2, 1]), _padat_ringkas())
	await _tampil(l)
	var aman: Rect2 = Rect2(Vector2(36, 16), Vector2(580, 324))
	for nama: String in ["struk", "kolom", "tombol", "judul"]:
		var r: Rect2 = {"struk": l.rect_panel(), "kolom": l.rect_panel_kanan(), "tombol": l.rect_tombol(), "judul": l.rect_judul()}[nama]
		check(aman.grow(0.5).encloses(r), "inset: %s %s di dalam zona aman %s" % [nama, r, aman])
	check(not l.rect_panel_kanan().intersects(l.rect_tombol()) and not l.rect_panel().intersects(l.rect_tombol()) and not l.rect_panel().intersects(l.rect_panel_kanan()), "inset: struk, kolom, dan tombol tidak bertumpuk")
	check(absf(l.rect_tombol().end.x - 616.0) < 0.5 and absf(l.rect_tombol().end.y - 340.0) < 0.5, "tombol berakhir (616, 340) = layar - inset akhir dan bawah: %s" % l.rect_tombol())
	check(is_equal_approx(l.rect_judul().position.x, 36.0) and is_equal_approx(l.rect_judul().position.y, 16.0), "judul mulai di (36, 16) = inset awal dan atas")
	_buang(l)


# --- Kontras dan huruf ---

func _test_kontras_dan_huruf() -> void:
	_judul.call("Hasil (struk): huruf V-8 (judul 24, angka 32, baris berhasil 12, netral 11, label 10) dan kontras token teks >= 7:1 di atas isi struk dan kartu; WARN bukan warna teks (6,91:1) (AC-6b, AC-7)")
	var l: LayarHasil = await _layar(Vector2i(1920, 1080))
	l.isi(_angka_padat(), _misi(), ["ban"] as Array[String], 10, _rep(55, 53, [4, 3, 2, 1]), _padat_ringkas())
	await _tampil(l)
	var judul: Label = l.find_child("JudulHasil", true, false) as Label
	check(judul.get_theme_font_size(&"font_size") == 24 and (l.find_child("LabelTerkirim", true, false) as Label).get_theme_font_size(&"font_size") == 10, "judul 24 dan label Terkirim 10")
	var ukuran: Dictionary = {}
	for simpul: Node in l.find_children("*", "Label", true, false):
		var label: Label = simpul as Label
		if label.is_visible_in_tree() and label.text != "":
			ukuran[tr(label.text)] = label.get_theme_font_size(&"font_size")
	check(ukuran.get("Tip") == 12 and ukuran.get("Skor") == 12 and ukuran.get("Meleset") == 11 and ukuran.get("Koran terbuang") == 11 and ukuran.get("Pelanggan baru") == 11, "baris berhasil 12 dan baris netral/pelanggan 11: %s" % [ukuran])
	var isi_struk: Color = GayaHud.tekstur("struk").get_image().get_pixel(6, 6)
	var isi_kartu: Color = GayaHud.tekstur("kartu_biasa").get_image().get_pixel(6, 6)
	var terburuk: float = 99.0
	for warna: Color in [Palette.TEXT, Palette.TEXT_2, Palette.ACCENT, Palette.OK]:
		terburuk = minf(terburuk, minf(_kontras(warna, isi_struk), _kontras(warna, isi_kartu)))
		terburuk = minf(terburuk, _kontras(warna, Palette.UI_BG))
	check(terburuk >= 7.0, "TEXT, TEXT_2, ACCENT, OK di atas isi struk, kartu, dan UI_BG: terburuk %.2f >= 7" % terburuk)
	check(_kontras(Palette.WARN, isi_struk) < 7.0, "kontrol: WARN di atas isi struk %.2f < 7, jadi tidak dipakai sebagai warna teks" % _kontras(Palette.WARN, isi_struk))
	for nama: String in LayarHasil.NAMA_KONDISI:
		var kondisi: Label = l.find_child(nama, true, false) as Label
		check(kondisi.get_theme_color(&"font_color") == Palette.TEXT, "baris kondisi %s: teks TEXT (glif seru yang berwarna WARN)" % nama)
	check(l.teks_kondisi() == ["Ban perlu servis"] and (((l.find_child("KondisiSatu", true, false) as Label).get_parent() as HBoxContainer).get_child(0) as TextureRect).texture == GayaHud.tekstur("glif_seru_warn"), "baris kondisi: glif '!' di depan teks (terbaca tanpa warna)")
	_buang(l)


func _test_teks_panjang() -> void:
	_judul.call("Hasil (struk): teks panjang berbungkus kata, tidak melebarkan struk atau kolom: angka koin 10 digit, nama milestone panjang, tenggat panjang di 640, 700, 800 (AC-7)")
	for jendela: Array in [[1920, 1080, 640], [2100, 1080, 700], [2400, 1080, 800]]:
		var l: LayarHasil = await _layar(Vector2i(jendela[0], jendela[1]))
		var a: HasilRute.Angka = _angka(25, 2147483647, 99999)
		a.tenggat_lewat = true
		a.detik_lewat = 3599
		a.skor = 2147483647
		a.koin_tip = 2147483647
		a.jumlah_tip = 25
		l.isi(a, null, [] as Array[String], 10, _rep(88, 100, [12, 0, 0, 0]), _padat_ringkas())
		await _tampil(l)
		var tag: String = "%d koin 10 digit" % jendela[2]
		var tata: TampilHasil.Tata = l.tata()
		check(absf(l.rect_panel().size.x - float(tata.lebar_struk)) < 0.5 and absf(l.rect_panel_kanan().size.x - float(tata.lebar_kolom)) < 0.5, "%s: struk dan kolom tetap selebar tata (%d dan %d)" % [tag, tata.lebar_struk, tata.lebar_kolom])
		var di_dalam: bool = true
		for r: Rect2 in l.rect_label():
			di_dalam = di_dalam and l.rect_panel().encloses(r)
		check(di_dalam and not l.rect_panel().intersects(l.rect_tombol()) and not l.rect_panel_kanan().intersects(l.rect_tombol()), "%s: label di dalam struk, struk dan kolom tidak menutupi tombol" % tag)
		check(l.teks_tampil().has("2.147.483.647") and l.teks_reputasi() == "100 (+12)", "%s: angka dengan pemisah ribuan dan reputasi 100 tampil" % tag)
		_buang(l)
