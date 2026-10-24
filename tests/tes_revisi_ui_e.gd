class_name TesRevisiUiE
extends RefCounted
## Tes revisi UI pemilik (run garis-finish-portal bagian E, R-1 sampai R-4, AC-12; usulan, dinilai di HP):
## - R-1: tombol berglif di ujung kanan (Berangkat, Hari berikutnya, Lanjut): margin isi kiri = kanan (grup teks + glif di tengah), tidak kurang dari `UI_TOMBOL_GLIF_MARGIN_MIN_PX`, teks tidak terpotong (empat lebar viewport), oracle murni literal.
## - R-2: layar hasil: garis dasar label = nilai tiap baris struk dan baris pelanggan, tepi kanan nilai sama (struk dan kolom samping), garis dasar label reputasi = angka = chip; murni (`turun_baseline`, `baseline_chip`).
## - R-3: strip radar tanpa bingkai: tidak ada tekstur bingkai di skrip dan aset, satu garis sumbu 1 px di tengah jalur yang menyentuh penanda, jalur penanda di dalam strip.
## - R-4: bar kecepatan dan stamina tanpa trek: garis sumbu 1 px di tengah tinggi bar sepanjang bar, tanpa warna trek lama; tanda ambang 90 persen tetap setinggi bar.
## Tidak menyentuh `user://save.json`. Pengukuran piksel dari tangkapan nyata ada di probe (`probe_hud_rute_jendela.gd`, `probe_hasil_jendela.gd`) dan di LOG.

const BERKAS_HASIL: String = "res://scenes/ui/layar_hasil.tscn"
const BERKAS_KORAN: String = "res://scenes/koran/halaman_koran.tscn"
const BERKAS_BENGKEL: String = "res://scenes/bengkel/bengkel.tscn"
const BERKAS_JEDA: String = "res://scenes/ui/layar_jeda.tscn"
## [lebar jendela, tinggi jendela, lebar viewport game].
const JENDELA: Array = [[1920, 1080, 640], [2340, 1080, 780], [2400, 1080, 800], [1600, 720, 800]]

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
	_test_panah_murni()
	await _test_panah_scene()
	_test_baseline_murni()
	_test_pusat_murni()
	await _test_pusat_reputasi_scene()
	await _test_hasil_rata()
	_test_radar_murni()
	_test_bar_murni()
	_test_tanpa_bingkai_dan_trek()
	await _test_sumbu_bar_abu()


# --- R-1 ---

func _test_panah_murni() -> void:
	_judul.call("R-1 margin grup glif (murni, oracle literal)")
	# (lebar tombol, lebar teks, lebar glif, jarak, pad kanan glif) -> margin = floor((lebar - teks - jarak - glif + pad) / 2), minimum 8.
	var tabel: Array = [[140, 60, 12, 4, 0, 32], [140, 95, 12, 4, 0, 14], [216, 40, 12, 4, 0, 80], [140, 109, 12, 4, 0, 8], [140, 130, 12, 4, 0, 8], [141, 95, 12, 4, 0, 15], [140, 95, 12, 4, 2, 15], [216, 40, 12, 4, 4, 82]]
	for baris: Array in tabel:
		var dapat: int = KomponenUi.margin_grup_glif(baris[0], baris[1], baris[2], baris[3], baris[4])
		check(dapat == baris[5], "tombol %d, teks %d, glif %d, jarak %d, pad kanan %d -> margin %d (dapat %d)" % [baris[0], baris[1], baris[2], baris[3], baris[4], baris[5], dapat])
	check(Config.UI_TOMBOL_GLIF_MARGIN_MIN_PX == 8, "margin minimum glif tombol 8 px (literal Config)")
	var tidak_pernah_kurang: bool = true
	for lebar: int in range(60, 260, 7):
		for teks: int in range(10, 240, 11):
			tidak_pernah_kurang = tidak_pernah_kurang and KomponenUi.margin_grup_glif(lebar, teks, 12, 4) >= 8
	check(tidak_pernah_kurang, "margin tidak pernah di bawah 8 px untuk semua lebar dan teks")


## Memuat `berkas`, memasangnya di akar dengan jendela `jendela`, menunggu tata letak; mengembalikan simpul.
func _pasang(berkas: String, jendela: Array) -> Node:
	_tree.root.size = Vector2i(int(jendela[0]), int(jendela[1]))
	var simpul: Node = (load(berkas) as PackedScene).instantiate()
	_tree.root.add_child(simpul)
	for i: int in range(4):
		await _tree.process_frame
	return simpul


func _buang(simpul: Node) -> void:
	_tree.root.remove_child(simpul)
	simpul.free()


func _periksa_tombol(nama: String, tombol: Button, jendela: Array) -> void:
	var margin_kiri: float = (tombol.get_theme_stylebox(&"normal") as StyleBox).content_margin_left
	var margin_kanan: float = (tombol.get_theme_stylebox(&"normal") as StyleBox).content_margin_right
	var pad: int = GayaHud.pad_kanan_glif(tombol)
	var teks: int = GayaHud.lebar_teks_tombol(tombol)
	var glif: int = tombol.icon.get_width()
	var jarak: int = tombol.get_theme_constant(&"h_separation")
	var lebar: float = tombol.size.x
	var ket: String = "%s @%dx%d" % [nama, jendela[0], jendela[1]]
	check(tombol.icon != null and tombol.icon_alignment == HORIZONTAL_ALIGNMENT_RIGHT, "%s: glif ada di kanan teks" % ket)
	check(margin_kiri == margin_kanan + float(pad), "%s: margin kiri (%.0f) = margin kanan (%.0f) + kolom kosong kanan tinta glif (%d): jarak teks ke tepi kiri = jarak tinta glif ke tepi kanan" % [ket, margin_kiri, margin_kanan, pad])
	check(tombol.alignment == HORIZONTAL_ALIGNMENT_LEFT, "%s: teks rata kiri, mulai tepat di margin" % ket)
	check(margin_kiri >= float(Config.UI_TOMBOL_GLIF_MARGIN_MIN_PX), "%s: margin %.0f >= minimum %d" % [ket, margin_kiri, Config.UI_TOMBOL_GLIF_MARGIN_MIN_PX])
	check(float(teks + jarak + glif) + margin_kiri + margin_kanan <= lebar + 0.01, "%s: teks %d + jarak %d + glif %d + margin %.0f + %.0f muat di lebar %.0f (tidak terpotong)" % [ket, teks, jarak, glif, margin_kiri, margin_kanan, lebar])
	var sisa: float = lebar - float(teks + jarak + glif) - margin_kiri - margin_kanan
	check(sisa >= -0.01 and sisa <= 1.01, "%s: grup memenuhi isi (sisa %.2f px hanya pembulatan), jadi jarak ke tepi kiri = jarak glif ke tepi kanan" % [ket, sisa])
	check(tombol.get_minimum_size().x <= lebar + 0.01, "%s: tombol tidak lebih kecil dari isinya" % ket)


func _test_panah_scene() -> void:
	_judul.call("R-1 tombol berpanah di tiga layar, empat lebar viewport")
	for jendela: Array in JENDELA:
		var koran: HalamanKoran = await _pasang(BERKAS_KORAN, jendela) as HalamanKoran
		_periksa_tombol("Berangkat", koran.tombol_berangkat(), jendela)
		_buang(koran)
		var bengkel: LayarBengkel = await _pasang(BERKAS_BENGKEL, jendela) as LayarBengkel
		_periksa_tombol("Hari berikutnya", bengkel.tombol_hari_berikutnya(), jendela)
		_buang(bengkel)
		var jeda: LayarJeda = await _pasang(BERKAS_JEDA, jendela) as LayarJeda
		jeda.tampilkan(true)
		await _tree.process_frame
		await _tree.process_frame
		_periksa_tombol("Lanjut", jeda.tombol_lanjut(), jendela)
		_buang(jeda)


# --- R-2 ---

func _test_baseline_murni() -> void:
	_judul.call("R-2 perataan baseline (murni, oracle literal)")
	check(TampilHasil.turun_baseline(10.0, 23.0) == Vector2i(13, 0), "ascent 10 lawan 23: yang kecil turun 13")
	check(TampilHasil.turun_baseline(23.0, 10.0) == Vector2i(0, 13), "kebalikan: yang kedua turun 13")
	check(TampilHasil.turun_baseline(11.0, 11.0) == Vector2i.ZERO, "sama: tidak ada yang turun")
	check(TampilHasil.turun_baseline(11.0, 12.0) == Vector2i(1, 0), "ascent 11 lawan 12 (Meleset: Kecil 11 lawan Utama 12): label turun 1 px")
	check(TampilHasil.turun_baseline(11.4, 11.0) == Vector2i.ZERO, "selisih 0,4 dibulatkan jadi 0")
	check(is_equal_approx(TampilHasil.baseline_chip(18, 3, 15.0, 12.0), 3.0 + (12.0 - 15.0) / 2.0 + 12.0), "baseline chip = pad + (isi - baris) / 2 + ascent")
	check(is_equal_approx(TampilHasil.baseline_chip(18, 3, 12.0, 11.0), 3.0 + 0.0 + 11.0), "isi 12 = baris 12: baseline = pad + ascent")


func _test_pusat_murni() -> void:
	_judul.call("R-5 pusat vertikal baris reputasi (murni, oracle literal)")
	check(is_equal_approx(TampilHasil.pusat_tinta(23.0, 17.0), 14.5), "pusat tinta angka: ascent 23, tinggi tinta 17 -> 14,5 dari tepi atas")
	check(is_equal_approx(TampilHasil.pusat_tinta(11.0, 7.0), 7.5), "pusat tinta label: ascent 11, tinggi 7 -> 7,5")
	check(TampilHasil.turun_pusat([7.5, 14.5, 9.0] as Array[float]) == ([7, 0, 6] as Array[int]), "pusat 7,5 / 14,5 / 9,0: turun 7, 0, dan 6 (14,5 - 9,0 = 5,5 dibulatkan ke 6)")
	check(TampilHasil.turun_pusat([5.0, 5.0, 5.0] as Array[float]) == ([0, 0, 0] as Array[int]), "pusat sama: tidak ada yang turun")
	check(TampilHasil.turun_pusat([] as Array[float]).is_empty(), "masukan kosong: kosong")
	check(TampilHasil.turun_pusat([1.0, NAN] as Array[float]).is_empty() and TampilHasil.turun_pusat([INF, 1.0] as Array[float]).is_empty(), "NaN atau tak hingga: kosong, tidak ada margin liar")
	check(TampilHasil.turun_pusat([3.0, 3.4] as Array[float]) == ([0, 0] as Array[int]), "selisih 0,4 dibulatkan 0")
	check(Config.HASIL_REPUTASI_TINTA_ANGKA_PX == 17 and Config.HASIL_REPUTASI_TINTA_LABEL_PX == 7, "tinggi tinta angka 17 dan label 7 px (terukur dari tangkapan, R-5)")


func _angka_padat() -> HasilRute.Angka:
	var a: HasilRute.Angka = HasilRute.Angka.new()
	a.pelanggan = 25
	a.terkirim = 20
	a.meleset = 5
	a.koin = 150
	a.skor = 14780
	a.lempar_terbuang = 5
	a.potongan = 5 * Config.KOIN_POTONGAN_KORAN_MELESET
	a.koin_tip = 15
	a.jumlah_tip = 2
	a.jumlah_tepat = 9
	return a


func _rep() -> ReputationManager.Hasil:
	var h: ReputationManager.Hasil = ReputationManager.Hasil.new()
	h.reputasi_sebelum = 10
	h.reputasi_sesudah = 12
	h.perubahan = 2
	var jenis: Array = [ReputationManager.Jenis.BARU, ReputationManager.Jenis.SETIA, ReputationManager.Jenis.BERHENTI, ReputationManager.Jenis.KEMBALI]
	for i: int in range(4):
		for n: int in range(i + 1):
			var p: ReputationManager.Peristiwa = ReputationManager.Peristiwa.new()
			p.jenis = jenis[i]
			p.id_rumah = "x@%d_%d" % [i, n]
			h.peristiwa.append(p)
	return h


func _ringkas() -> MilestoneTracker.Ringkasan:
	var a: Dictionary = DataSave.templat()
	var b: Dictionary = DataSave.templat()
	b["koin_total"] = 700
	return MilestoneTracker.ringkas(a, b)


func _test_hasil_rata() -> void:
	_judul.call("R-2 layar hasil: baseline label = nilai, tepi kanan nilai sama (empat lebar viewport)")
	for jendela: Array in JENDELA:
		var layar: LayarHasil = await _pasang(BERKAS_HASIL, jendela) as LayarHasil
		layar.isi(_angka_padat(), null, [], -1, _rep(), _ringkas())
		layar.tampilkan(true)
		for i: int in range(4):
			await _tree.process_frame
		var ket: String = "@%dx%d" % [jendela[0], jendela[1]]
		var pasangan: Array[Dictionary] = layar.pasangan_baris()
		check(pasangan.size() == 6, "%s: enam baris struk tampil (Tip, Skor, Tepat, Meleset, Terbuang, Bersih), dapat %d" % [ket, pasangan.size()])
		var tepi: float = -1.0
		var semua_rata: bool = true
		var semua_kanan: bool = true
		for baris: Dictionary in pasangan:
			var label: Label = baris["label"] as Label
			var nilai: Label = baris["nilai"] as Label
			var selisih: float = absf(layar.baseline_label(label) - layar.baseline_label(nilai))
			if selisih > 0.01:
				semua_rata = false
				print("  baseline beda baris '%s': %.2f vs %.2f" % [label.text, layar.baseline_label(label), layar.baseline_label(nilai)])
			if tepi < 0.0:
				tepi = nilai.get_global_rect().end.x
			elif absf(nilai.get_global_rect().end.x - tepi) > 0.01:
				semua_kanan = false
		check(semua_rata, "%s: baseline label = nilai di semua baris struk (selisih 0)" % ket)
		check(semua_kanan, "%s: tepi kanan nilai sama di semua baris struk (%.1f)" % [ket, tepi])
		var batas_isi: float = layar.rect_panel().end.x - float(Config.HASIL_STRUK_PAD_X_PX)
		check(absf(tepi - batas_isi) < 0.5, "%s: tepi kanan nilai (%.1f) = tepi kanan isi struk (%.1f)" % [ket, tepi, batas_isi])
		var rep: Vector3 = layar.pusat_reputasi()
		check(absf(rep.x - rep.y) <= 0.51 and absf(rep.z - rep.y) <= 0.51, "%s: R-5 pusat tinta label reputasi (%.2f) = angka (%.2f) = pusat chip (%.2f), selisih paling besar 0,5 px" % [ket, rep.x, rep.y, rep.z])
		var pel: Array[Dictionary] = layar.pasangan_pelanggan()
		check(pel.size() == 4, "%s: empat baris pelanggan tampil" % ket)
		var pel_rata: bool = true
		for baris: Dictionary in pel:
			pel_rata = pel_rata and absf(layar.baseline_label(baris["label"] as Label) - layar.baseline_label(baris["nilai"] as Label)) < 0.01
		check(pel_rata, "%s: baseline label = nilai di baris pelanggan" % ket)
		var tepi_akhir: Array[float] = layar.tepi_kanan_samping()
		var akhir_sama: bool = tepi_akhir.size() >= 6
		for x: float in tepi_akhir:
			akhir_sama = akhir_sama and absf(x - tepi_akhir[0]) < 0.51
		check(akhir_sama, "%s: tepi kanan chip, nilai pelanggan, nama dan angka target sama (%d nilai, %.1f)" % [ket, tepi_akhir.size(), tepi_akhir[0] if not tepi_akhir.is_empty() else -1.0])
		_buang(layar)


func _rep_dengan(sesudah: int, ubah: int) -> ReputationManager.Hasil:
	var h: ReputationManager.Hasil = _rep()
	h.reputasi_sesudah = sesudah
	h.reputasi_sebelum = sesudah - ubah
	h.perubahan = ubah
	return h


func _test_pusat_reputasi_scene() -> void:
	_judul.call("R-5 kotak chip reputasi satu garis tengah dengan label dan angka: +2, +0, -3, tiga digit (empat lebar viewport)")
	var kasus: Array = [[12, 2], [0, 0], [97, -3], [100, 12], [8, -8]]
	for jendela: Array in JENDELA:
		for k: Array in kasus:
			var layar: LayarHasil = await _pasang(BERKAS_HASIL, jendela) as LayarHasil
			layar.isi(_angka_padat(), null, [], -1, _rep_dengan(int(k[0]), int(k[1])), _ringkas())
			layar.tampilkan(true)
			for i: int in range(4):
				await _tree.process_frame
			var rep: Vector3 = layar.pusat_reputasi()
			check(absf(rep.x - rep.y) <= 0.51 and absf(rep.z - rep.y) <= 0.51, "@%dx%d reputasi %d (%+d): pusat label %.2f, angka %.2f, chip %.2f" % [jendela[0], jendela[1], k[0], k[1], rep.x, rep.y, rep.z])
			var kartu: Rect2 = layar.rect_kartu()[0]
			check(kartu.grow(0.5).encloses(layar.chip_reputasi().get_global_rect()) and kartu.grow(0.5).encloses(layar.rect_angka_reputasi()), "@%dx%d reputasi %d (%+d): chip dan angka di dalam kartu" % [jendela[0], jendela[1], k[0], k[1]])
			_buang(layar)


# --- R-7 ---

## Kontras WCAG dua warna opak (oracle ditulis ulang).
func _kontras(a: Color, b: Color) -> float:
	var la: float = _luminans(a)
	var lb: float = _luminans(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func _luminans(c: Color) -> float:
	var k: Array[float] = []
	for v: float in [c.r, c.g, c.b]:
		k.append(v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4))
	return 0.2126 * k[0] + 0.7152 * k[1] + 0.0722 * k[2]


func _test_sumbu_bar_abu() -> void:
	_judul.call("R-7 garis tengah bar kecepatan dan stamina abu terang (TEXT_2): token, kontras terhadap panel dan isi, tergambar di bar kosong, isi menutupi garis")
	check(BarKecepatan.warna_sumbu() == Palette.TEXT_2 and BarKecepatan.warna_sumbu().to_html(false) == "cdb9a3", "warna sumbu bar = token Palette.TEXT_2 (#CDB9A3), bukan OUTLINE")
	var dunia: Array = ["#6fae4f", "#4e4a56", "#ffffff", "#f2e7c9", "#4f9a74"]
	var terburuk: float = INF
	var lama_terbaik: float = 0.0
	for hex: String in dunia:
		var panel: Color = Color(Palette.HUD_PANEL.r, Palette.HUD_PANEL.g, Palette.HUD_PANEL.b).lerp(Color(hex), 1.0 - Palette.HUD_PANEL.a)
		terburuk = minf(terburuk, _kontras(Palette.TEXT_2, panel))
		lama_terbaik = maxf(lama_terbaik, _kontras(Palette.OUTLINE, panel))
	check(terburuk >= 6.5 and lama_terbaik < 1.6, "kontras garis TEXT_2 vs panel HUD di atas lima latar dunia: terburuk %.2f:1 (>= 6,5); garis lama OUTLINE terbaiknya hanya %.2f:1" % [terburuk, lama_terbaik])
	check(_kontras(Palette.TEXT_2, Palette.TEXT) < 2.0 and _kontras(Palette.TEXT_2, Palette.ACCENT) < 1.2, "garis vs isi putih %.2f:1 dan oranye %.2f:1: dibedakan tebal (isi 7 px lawan garis 1 px), bukan kontras" % [_kontras(Palette.TEXT_2, Palette.TEXT), _kontras(Palette.TEXT_2, Palette.ACCENT)])
	# Piksel nyata di bar kosong dan terisi ditegakkan probe (`probe_hud_rute_jendela.gd`, `_cek_piksel_hud`): renderer headless tidak menggambar.
	var bar_kosong: BarKecepatan = BarKecepatan.new()
	check(bar_kosong.nilai == 0.0 and FileAccess.get_file_as_string("res://scripts/ui/bar_kecepatan.gd").contains("draw_rect(Rect2(TampilHud.rect_sumbu_bar(roundi(size.x), roundi(size.y))), warna_sumbu())"), "bar stamina kosong (nilai 0) tetap menggambar garis tengah: sumbu digambar tanpa syarat nilai, sebelum isi")
	bar_kosong.free()


# --- R-3 ---

func _test_radar_murni() -> void:
	_judul.call("R-3 strip radar tanpa bingkai: garis sumbu (murni, oracle literal)")
	check(RadarRute.rect_sumbu(12, 172) == Rect2i(6, 0, 1, 172), "strip 12x172: sumbu x 6, lebar 1, setinggi strip")
	check(RadarRute.rect_sumbu(11, 50) == Rect2i(5, 0, 1, 50), "strip 11x50: sumbu x 5")
	check(RadarRute.rect_sumbu(0, 172) == Rect2i() and RadarRute.rect_sumbu(12, 0) == Rect2i(), "ukuran tidak positif: kosong")
	var sumbu: Rect2i = RadarRute.rect_sumbu(Config.RADAR_LEBAR_PX, Config.RADAR_Y_BAWAH_PX - Config.RADAR_Y_ATAS_PX)
	var x_penanda: int = floori((float(Config.RADAR_LEBAR_PX) - float(Config.RADAR_PENANDA_LEBAR_PX)) / 2.0)
	check(sumbu.position.x >= x_penanda and sumbu.position.x < x_penanda + Config.RADAR_PENANDA_LEBAR_PX, "sumbu (x %d) menembus tengah penanda 8 lebar (x %d sampai %d)" % [sumbu.position.x, x_penanda, x_penanda + Config.RADAR_PENANDA_LEBAR_PX - 1])
	var x_jangkau: int = x_penanda - Config.RADAR_JANGKAU_TAMBAH_PX / 2
	check(sumbu.position.x >= x_jangkau and sumbu.position.x < x_jangkau + Config.RADAR_PENANDA_LEBAR_PX + Config.RADAR_JANGKAU_TAMBAH_PX, "sumbu juga di dalam penanda masuk jangkauan 10 lebar")
	check(sumbu.size.x == Config.UI_GARIS_PX and Config.UI_GARIS_PX == 1, "sumbu selebar satu piksel (garis tipis)")
	# Penanda tetap di dalam strip secara vertikal (jalur 2 px dari ujung).
	var strip: RadarStrip = RadarStrip.new()
	strip.size = Vector2(Config.RADAR_LEBAR_PX, Config.RADAR_Y_BAWAH_PX - Config.RADAR_Y_ATAS_PX)
	var di_dalam: bool = true
	for nilai: float in [0.0, 0.25, 0.5, 1.0]:
		for jangkau: bool in [false, true]:
			var p: RadarRute.Penanda = RadarRute.Penanda.new()
			p.vertikal = nilai
			p.jangkau = jangkau
			var r: Rect2 = strip.rect_lokal(p)
			di_dalam = di_dalam and r.position.y >= 0.0 and r.end.y <= strip.size.y and r.position.x >= 0.0 and r.end.x <= strip.size.x
	check(di_dalam, "penanda (biasa dan jangkau) di semua posisi vertikal tetap di dalam strip")
	strip.free()


# --- R-4 ---

func _test_bar_murni() -> void:
	_judul.call("R-4 bar kecepatan dan stamina tanpa trek: garis sumbu (murni, oracle literal)")
	check(TampilHud.rect_sumbu_bar(111, 9) == Rect2i(1, 4, 109, 1), "bar 111x9: sumbu di baris 4 dari x 1, selebar bar dikurangi dua inset (109), setinggi 1")
	check(TampilHud.rect_sumbu_bar(89, 9) == Rect2i(1, 4, 87, 1), "bar 89x9: sumbu baris 4, x 1, lebar 87")
	check(TampilHud.rect_sumbu_bar(0, 9) == Rect2i() and TampilHud.rect_sumbu_bar(50, 0) == Rect2i() and TampilHud.rect_sumbu_bar(2, 9) == Rect2i() and TampilHud.rect_sumbu_bar(3, 9) == Rect2i(1, 4, 1, 1), "ukuran tidak positif atau terlalu sempit untuk dua inset: kosong; lebar 3: satu piksel")
	check(Config.HUD_BAR_TINGGI_PX == 9 and Config.HUD_BAR_TANDA_PECAHAN == 0.9, "tinggi bar 9 dan tanda ambang 0,9 tidak berubah")
	var bar: BarKecepatan = BarKecepatan.new()
	bar.size = Vector2(111, 9)
	bar.tanda = Config.HUD_BAR_TANDA_PECAHAN
	var tanda: Rect2 = bar.rect_tanda()
	check(tanda.size == Vector2(1, 9) and tanda.position.y == 0.0, "tanda ambang 90 persen tetap selebar 1 dan setinggi bar penuh")
	bar.free()


## Pemeriksa sumber: tekstur bingkai radar dan warna trek bar tidak dipakai lagi (mutan menaruhnya kembali tertangkap).
func _test_tanpa_bingkai_dan_trek() -> void:
	_judul.call("R-3 dan R-4: tidak ada bingkai radar dan trek bar lama")
	var radar: String = FileAccess.get_file_as_string("res://scripts/ui/radar_strip.gd")
	check(not radar.contains("ui_radar_strip_9slice") and not radar.contains("draw_style_box") and radar.contains("rect_sumbu"), "radar_strip.gd: tanpa bingkai 9-slice, menggambar garis sumbu")
	var bar: String = FileAccess.get_file_as_string("res://scripts/ui/bar_kecepatan.gd")
	check(not bar.contains("UI_PANEL_RAISED") and bar.contains("rect_sumbu_bar"), "bar_kecepatan.gd: tanpa warna trek UI_PANEL_RAISED, menggambar garis sumbu")
	check(not ResourceLoader.exists("res://assets/sprites/ui/ui_radar_strip_9slice.png"), "aset bingkai strip radar tidak dipasang lagi")
