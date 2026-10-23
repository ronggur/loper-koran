class_name TesKomponenUi
extends RefCounted
## Tes komponen UI redesain run ui1-komponen-bengkel bagian A (AC-4 dan AC-5): pemilihan keadaan tombol/kartu/chip (`KomponenUi`, murni), wujud `GayaHud` (StyleBoxTexture dari
## aset terpasang, tepi 9-slice = `meta.json`), kotak kondisi besar (`TampilKondisiBesar`, `KotakKondisiBesar`), dan bahwa fungsi lama `GayaHud` tidak berubah.
##
## Oracle independen: ambang kondisi, ukuran, warna acuan, dan tepi 9-slice ditulis literal dari kanvas (README redesain 4, ui.css, meta.json), bukan dihitung ulang dengan fungsi yang dites.
## "Terbaca tanpa warna" diuji dengan membuang warna: keadaan yang berbeda harus tetap berbeda pada tekstur/margin/bobot/glif/teks, dan isi kotak kondisi harus beda luminans.

var _cek: Callable
var _judul: Callable

const PERAN: Array = [KomponenUi.Peran.UTAMA, KomponenUi.Peran.BIASA, KomponenUi.Peran.SAKELAR, KomponenUi.Peran.TENANG]
const KEADAAN: Array = [KomponenUi.KeadaanTombol.NORMAL, KomponenUi.KeadaanTombol.DITEKAN, KomponenUi.KeadaanTombol.NONAKTIF]
const STATUS: Array = [KomponenUi.StatusChip.HARGA, KomponenUi.StatusChip.BAIK, KomponenUi.StatusChip.AUS, KomponenUi.StatusChip.PERLU_SERVIS,
		KomponenUi.StatusChip.DIMILIKI, KomponenUi.StatusChip.TINGKAT_AKTIF, KomponenUi.StatusChip.TINGKAT_LAIN]
const BERKAS_META: String = "res://docs/design/redesain/aset/meta.json"


func _init(cek: Callable, judul: Callable) -> void:
	_cek = cek
	_judul = judul


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_test_config_dan_meta()
	_test_tombol_pilihan()
	_test_tombol_tanpa_warna()
	_test_kartu()
	_test_chip()
	_test_gaya_tombol()
	_test_gaya_panel_kartu_chip()
	_test_arsir_nonaktif()
	_test_gaya_lama_tak_berubah()
	_test_kondisi_besar_geometri()
	_test_kondisi_besar_warna()
	_test_kondisi_besar_node()
	_test_theme()


# Luminans relatif (Rec. 709) untuk "tanpa warna": hanya terang gelap yang tersisa.
func _lum(w: Color) -> float:
	return 0.2126 * w.r + 0.7152 * w.g + 0.0722 * w.b


func _meta() -> Dictionary:
	var f: FileAccess = FileAccess.open(BERKAS_META, FileAccess.READ)
	if f == null:
		return {}
	var hasil: Variant = JSON.parse_string(f.get_as_text())
	return hasil if hasil is Dictionary else {}


# --- Config dan meta.json ---

func _test_config_dan_meta() -> void:
	_judul.call("Komponen UI: tepi 9-slice Config = meta.json, ukuran tekstur terpasang sesuai (AC-2, AC-4)")
	var meta: Dictionary = _meta()
	check(not meta.is_empty(), "meta.json redesain terbaca")
	if meta.is_empty():
		return
	var tombol: Array = meta["btn_utama"]["slice"]
	# Urutan slice CSS: atas, kanan, bawah, kiri.
	check(Config.UI_TOMBOL_SLICE_ATAS_PX == int(tombol[0]) and Config.UI_TOMBOL_SLICE_SAMPING_PX == int(tombol[1]) and Config.UI_TOMBOL_SLICE_BAWAH_PX == int(tombol[2]) and int(tombol[1]) == int(tombol[3]),
		"slice tombol meta.json (atas/kanan/bawah/kiri) = Config.UI_TOMBOL_SLICE_*")
	check(Config.UI_PANEL_SLICE_PX == int(meta["panel_layar"]["slice"][0]) and Config.UI_PANEL_SLICE_PX == int(meta["kartu_menonjol"]["slice"][0]), "slice panel dan kartu = Config.UI_PANEL_SLICE_PX")
	check(Config.UI_CHIP_SLICE_PX == int(meta["chip_ok"]["slice"][0]), "slice chip = Config.UI_CHIP_SLICE_PX")
	check(Config.UI_TOMBOL_SLICE_ATAS_PX == 6 and Config.UI_TOMBOL_SLICE_SAMPING_PX == 4 and Config.UI_PANEL_SLICE_PX == 4 and Config.UI_CHIP_SLICE_PX == 3, "angka literal dari kanvas: tombol 6/4, panel 4, chip 3")
	check(Config.UI_TOMBOL_TINGGI_PX == 42 and Config.UI_TOMBOL_LEBAR_MIN_PX == 84 and Config.UI_TOMBOL_LEBAR_UTAMA_PX == 140, "tombol 42 tinggi, lebar minimum 84, aksi utama 140 (README redesain 4, ui-scenes)")
	check(Config.UI_CHIP_TINGGI_KECIL_PX == 16 and Config.UI_CHIP_TINGGI_PX == 20 and Config.UI_CHIP_TINGGI_BESAR_PX == 26, "chip tinggi 16/20/26 (V-8: huruf 10/12/14, tinggi baris Lexend 13/15/18)")
	check(Config.UI_TOMBOL_TEKAN_GESER_PX == 2, "ditekan = turun 2 px")
	# Ukuran tekstur terpasang = meta.json (tidak ada tekstur salah pasang).
	var salah: Array[String] = []
	for nama: String in ["btn_utama", "btn_utama_tekan", "btn_biasa", "btn_biasa_tekan", "btn_sakelar_nyala", "btn_tenang", "btn_tenang_tekan", "btn_nonaktif", "arsir_nonaktif",
			"panel_layar", "kartu_biasa", "kartu_menonjol", "kartu_redup", "chip_gelap", "chip_ok", "chip_warn", "chip_netral", "chip_aksen"]:
		var tekstur: Texture2D = GayaHud.tekstur(nama)
		var ukuran: Array = meta[nama]["size"]
		if tekstur == null or tekstur.get_width() != int(ukuran[0]) or tekstur.get_height() != int(ukuran[1]):
			salah.append(nama)
	check(salah.is_empty(), "ukuran 18 tekstur terpasang = meta.json (salah: %s)" % [salah])
	check(GayaHud.tekstur("tidak_ada") == null, "nama tekstur tidak dikenal -> null")
	for ikon: String in ["icon24_ban", "icon24_rem", "icon24_rantai"]:
		var t: Texture2D = GayaHud.tekstur(ikon)
		check(t != null and t.get_width() == 24 and t.get_height() == 24, "%s 24x24" % ikon)
	for glif: String in ["glif_seru_warn", "glif_centang_ok", "glif_centang_teks2", "glif_kunci_terang", "glif_panah_gelap"]:
		var t: Texture2D = GayaHud.tekstur(glif)
		check(t != null and t.get_width() == 12 and t.get_height() == 12, "%s 12x12" % glif)


# --- Pilihan keadaan tombol (murni) ---

func _test_tombol_pilihan() -> void:
	_judul.call("Komponen UI: pilihan keadaan tombol (4 peran x normal/ditekan/nonaktif) murni")
	check(KomponenUi.keadaan_tombol(true, false) == KomponenUi.KeadaanTombol.NORMAL, "aktif tidak ditekan = NORMAL")
	check(KomponenUi.keadaan_tombol(true, true) == KomponenUi.KeadaanTombol.DITEKAN, "aktif ditekan = DITEKAN")
	check(KomponenUi.keadaan_tombol(false, false) == KomponenUi.KeadaanTombol.NONAKTIF, "nonaktif tidak ditekan = NONAKTIF")
	check(KomponenUi.keadaan_tombol(false, true) == KomponenUi.KeadaanTombol.NONAKTIF, "nonaktif menang atas ditekan (tombol mati tidak punya keadaan tekan)")
	var nama: Dictionary = {
		[KomponenUi.Peran.UTAMA, KomponenUi.KeadaanTombol.NORMAL]: "btn_utama",
		[KomponenUi.Peran.UTAMA, KomponenUi.KeadaanTombol.DITEKAN]: "btn_utama_tekan",
		[KomponenUi.Peran.BIASA, KomponenUi.KeadaanTombol.NORMAL]: "btn_biasa",
		[KomponenUi.Peran.BIASA, KomponenUi.KeadaanTombol.DITEKAN]: "btn_biasa_tekan",
		[KomponenUi.Peran.SAKELAR, KomponenUi.KeadaanTombol.NORMAL]: "btn_biasa",
		[KomponenUi.Peran.SAKELAR, KomponenUi.KeadaanTombol.DITEKAN]: "btn_biasa_tekan",
		[KomponenUi.Peran.TENANG, KomponenUi.KeadaanTombol.NORMAL]: "btn_tenang",
		[KomponenUi.Peran.TENANG, KomponenUi.KeadaanTombol.DITEKAN]: "btn_tenang_tekan",
	}
	for kunci: Array in nama:
		check(KomponenUi.nama_tekstur_tombol(kunci[0], kunci[1]) == nama[kunci], "tekstur peran %d keadaan %d = %s" % [kunci[0], kunci[1], nama[kunci]])
	check(KomponenUi.nama_tekstur_tombol(KomponenUi.Peran.SAKELAR, KomponenUi.KeadaanTombol.NORMAL, true) == "btn_sakelar_nyala", "sakelar nyala = bingkai sakelar_nyala")
	check(KomponenUi.nama_tekstur_tombol(KomponenUi.Peran.SAKELAR, KomponenUi.KeadaanTombol.DITEKAN, true) == "btn_biasa_tekan", "sakelar nyala ditekan = biasa_tekan (kanvas tidak punya sakelar_tekan)")
	check(KomponenUi.nama_tekstur_tombol(KomponenUi.Peran.UTAMA, KomponenUi.KeadaanTombol.NORMAL, true) == "btn_utama", "parameter nyala hanya berlaku untuk sakelar")
	for p: KomponenUi.Peran in PERAN:
		check(KomponenUi.nama_tekstur_tombol(p, KomponenUi.KeadaanTombol.NONAKTIF) == "btn_nonaktif", "peran %d nonaktif = satu bingkai btn_nonaktif" % p)
		check(KomponenUi.nama_tekstur_tombol(p, KomponenUi.KeadaanTombol.NONAKTIF, true) == "btn_nonaktif", "peran %d nonaktif + nyala tetap btn_nonaktif" % p)
	# Margin isi: bibir 2 px (utama/biasa/sakelar) menggeser teks 2 px ke bawah saat ditekan; tenang dan nonaktif rata.
	for p: KomponenUi.Peran in [KomponenUi.Peran.UTAMA, KomponenUi.Peran.BIASA, KomponenUi.Peran.SAKELAR]:
		var normal: Vector2i = KomponenUi.margin_isi_tombol(p, KomponenUi.KeadaanTombol.NORMAL)
		var tekan: Vector2i = KomponenUi.margin_isi_tombol(p, KomponenUi.KeadaanTombol.DITEKAN)
		check(normal == Vector2i(0, 2) and tekan == Vector2i(2, 0), "peran %d: margin isi normal (0,2), ditekan (2,0)" % p)
		check((tekan.x - tekan.y) - (normal.x - normal.y) == 4, "peran %d: titik tengah teks turun 2 px (selisih margin 4 / 2)" % p)
		check(tekan.x + tekan.y == normal.x + normal.y, "peran %d: tinggi area isi sama saat ditekan (tombol tidak berubah tinggi)" % p)
	check(KomponenUi.margin_isi_tombol(KomponenUi.Peran.TENANG, KomponenUi.KeadaanTombol.NORMAL) == Vector2i.ZERO and KomponenUi.margin_isi_tombol(KomponenUi.Peran.TENANG, KomponenUi.KeadaanTombol.DITEKAN) == Vector2i.ZERO, "tenang rata: tidak ada geseran")
	for p: KomponenUi.Peran in PERAN:
		check(KomponenUi.margin_isi_tombol(p, KomponenUi.KeadaanTombol.NONAKTIF) == Vector2i.ZERO, "nonaktif rata peran %d: tanpa geseran" % p)
	# Warna teks dari Palette (oracle literal token DESIGN_SPEC 1.1).
	check(KomponenUi.warna_teks_tombol(KomponenUi.Peran.UTAMA, KomponenUi.KeadaanTombol.NORMAL) == Color("#1C130F"), "teks utama gelap #1C130F di atas ACCENT")
	check(KomponenUi.warna_teks_tombol(KomponenUi.Peran.BIASA, KomponenUi.KeadaanTombol.NORMAL) == Color("#FFF3E3") and KomponenUi.warna_teks_tombol(KomponenUi.Peran.BIASA, KomponenUi.KeadaanTombol.DITEKAN) == Color("#FFB22E"), "teks biasa TEXT, ditekan ACCENT")
	check(KomponenUi.warna_teks_tombol(KomponenUi.Peran.TENANG, KomponenUi.KeadaanTombol.NORMAL) == Color("#CDB9A3") and KomponenUi.warna_teks_tombol(KomponenUi.Peran.TENANG, KomponenUi.KeadaanTombol.DITEKAN) == Color("#FFF3E3"), "teks tenang TEXT_2, ditekan TEXT")
	check(KomponenUi.warna_teks_tombol(KomponenUi.Peran.SAKELAR, KomponenUi.KeadaanTombol.NORMAL) == Color("#FFF3E3"), "teks sakelar TEXT")
	for p: KomponenUi.Peran in PERAN:
		check(KomponenUi.warna_teks_tombol(p, KomponenUi.KeadaanTombol.NONAKTIF) == Color("#CDB9A3"), "teks nonaktif peran %d TEXT_2" % p)


func _test_tombol_tanpa_warna() -> void:
	_judul.call("Komponen UI: tombol terbaca tanpa warna (bentuk, bobot, margin, teks alasan)")
	# Tanpa warna: tanda tangan = (tekstur, margin isi, tebal). Tiap keadaan aktif lawan nonaktif, dan normal lawan ditekan, harus berbeda.
	for p: KomponenUi.Peran in PERAN:
		var tanda: Dictionary = {}
		for k: KomponenUi.KeadaanTombol in KEADAAN:
			tanda[k] = [KomponenUi.nama_tekstur_tombol(p, k), KomponenUi.margin_isi_tombol(p, k), KomponenUi.teks_tebal(p, k)]
		check(tanda[KomponenUi.KeadaanTombol.NORMAL] != tanda[KomponenUi.KeadaanTombol.DITEKAN], "peran %d: normal dan ditekan berbeda tanpa warna (tekstur/margin)" % p)
		check(tanda[KomponenUi.KeadaanTombol.NORMAL] != tanda[KomponenUi.KeadaanTombol.NONAKTIF] and tanda[KomponenUi.KeadaanTombol.DITEKAN] != tanda[KomponenUi.KeadaanTombol.NONAKTIF],
			"peran %d: nonaktif beda dari aktif tanpa warna (bingkai rata sendiri)" % p)
	check(KomponenUi.teks_tebal(KomponenUi.Peran.UTAMA, KomponenUi.KeadaanTombol.NORMAL) and KomponenUi.teks_tebal(KomponenUi.Peran.BIASA, KomponenUi.KeadaanTombol.DITEKAN) and KomponenUi.teks_tebal(KomponenUi.Peran.SAKELAR, KomponenUi.KeadaanTombol.NORMAL), "utama/biasa/sakelar SemiBold")
	check(not KomponenUi.teks_tebal(KomponenUi.Peran.TENANG, KomponenUi.KeadaanTombol.NORMAL), "tenang Regular")
	for p: KomponenUi.Peran in PERAN:
		check(not KomponenUi.teks_tebal(p, KomponenUi.KeadaanTombol.NONAKTIF), "nonaktif peran %d Regular" % p)
	# Teks alasan menggantikan teks aksi hanya saat nonaktif dan alasan ada.
	check(KomponenUi.teks_tombol("Servis", true, "Koin kurang") == "Servis", "aktif: teks aksi tetap, alasan diabaikan")
	check(KomponenUi.teks_tombol("Servis", false, "Koin kurang") == "Koin kurang", "nonaktif: teks berganti alasan")
	check(KomponenUi.teks_tombol("Servis", false, "") == "Servis", "nonaktif tanpa alasan: teks aksi tetap (tidak jadi kosong)")
	check(KomponenUi.teks_tombol("", false, "Koin kurang") == "Koin kurang" and KomponenUi.teks_tombol("", true, "") == "", "teks kosong ditangani")
	# Bahkan bila warna dibuang, teks nonaktif tidak memakai warna yang sama dengan teks utama (kontras terang gelap).
	check(_lum(KomponenUi.warna_teks_tombol(KomponenUi.Peran.BIASA, KomponenUi.KeadaanTombol.NORMAL)) > _lum(KomponenUi.warna_teks_tombol(KomponenUi.Peran.BIASA, KomponenUi.KeadaanTombol.NONAKTIF)), "teks biasa lebih terang dari teks nonaktif")


# --- Kartu ---

func _test_kartu() -> void:
	_judul.call("Komponen UI: pilihan kartu (menonjol bila PERLU_BENGKEL, redup bila BAIK atau Dimiliki, biasa selain itu)")
	check(KomponenUi.kartu_servis(BikeCondition.Tingkat.PERLU_BENGKEL) == KomponenUi.JenisKartu.MENONJOL, "PERLU_BENGKEL = menonjol")
	check(KomponenUi.kartu_servis(BikeCondition.Tingkat.BAIK) == KomponenUi.JenisKartu.REDUP, "BAIK = redup")
	check(KomponenUi.kartu_servis(BikeCondition.Tingkat.AUS) == KomponenUi.JenisKartu.BIASA, "AUS = biasa")
	check(KomponenUi.kartu_upgrade(true) == KomponenUi.JenisKartu.REDUP and KomponenUi.kartu_upgrade(false) == KomponenUi.JenisKartu.BIASA, "upgrade: dimiliki redup, selain itu biasa")
	# Sapuan kondisi 0,00..1,00 per 0,01 termasuk titik batas, oracle ambang literal 0,70 dan 0,35 (BALANCING 8).
	var salah: Array[String] = []
	for i: int in range(101):
		var k: float = float(i) / 100.0
		var harap: KomponenUi.JenisKartu = KomponenUi.JenisKartu.REDUP if k >= 0.7 else (KomponenUi.JenisKartu.BIASA if k >= 0.35 else KomponenUi.JenisKartu.MENONJOL)
		if KomponenUi.kartu_servis(BikeCondition.tingkat(k)) != harap:
			salah.append(str(k))
	check(salah.is_empty(), "kartu servis sapuan 0..1 sesuai ambang 0,70/0,35 (salah: %s)" % [salah])
	check(KomponenUi.kartu_servis(BikeCondition.tingkat(0.0)) == KomponenUi.JenisKartu.MENONJOL and KomponenUi.kartu_servis(BikeCondition.tingkat(1.0)) == KomponenUi.JenisKartu.REDUP, "batas 0 menonjol dan 1 redup")
	check(KomponenUi.kartu_servis(BikeCondition.tingkat(NAN)) == KomponenUi.JenisKartu.REDUP, "kondisi NaN dianggap baik (BikeCondition.jepit) -> redup, tidak menonjol palsu")
	check(KomponenUi.nama_tekstur_kartu(KomponenUi.JenisKartu.BIASA) == "kartu_biasa" and KomponenUi.nama_tekstur_kartu(KomponenUi.JenisKartu.MENONJOL) == "kartu_menonjol" and KomponenUi.nama_tekstur_kartu(KomponenUi.JenisKartu.REDUP) == "kartu_redup", "nama tekstur tiga kartu")
	# Tanpa warna: pasangan (kartu, chip) tiga tingkat berbeda satu sama lain pada glif atau teks, dan kartu menonjol selalu bersama "!".
	var pasangan: Array = []
	for tingkat: BikeCondition.Tingkat in [BikeCondition.Tingkat.BAIK, BikeCondition.Tingkat.AUS, BikeCondition.Tingkat.PERLU_BENGKEL]:
		var info: KomponenUi.InfoChip = KomponenUi.chip(KomponenUi.status_chip_servis(tingkat))
		pasangan.append([info.glif, info.kunci_teks])
	check(pasangan[0] != pasangan[1] and pasangan[1] != pasangan[2] and pasangan[0] != pasangan[2], "BAIK/AUS/PERLU_BENGKEL beda glif atau teks (tidak hanya warna)")
	check(KomponenUi.chip(KomponenUi.status_chip_servis(BikeCondition.Tingkat.PERLU_BENGKEL)).glif == KomponenUi.GlifChip.SERU, "kartu menonjol dipasangkan dengan glif seru")
	check(KomponenUi.chip(KomponenUi.status_chip_servis(BikeCondition.Tingkat.BAIK)).glif == KomponenUi.GlifChip.CENTANG, "kartu redup (baik) dipasangkan dengan centang")


# --- Chip ---

func _test_chip() -> void:
	_judul.call("Komponen UI: chip status -> gaya + glif + teks, terbaca tanpa warna")
	var baik: KomponenUi.InfoChip = KomponenUi.chip(KomponenUi.StatusChip.BAIK)
	check(baik.gaya == KomponenUi.GayaChip.OK and baik.glif == KomponenUi.GlifChip.CENTANG and baik.kunci_teks == "BENGKEL_BAIK", "BAIK = ok + centang + 'Baik'")
	var perlu: KomponenUi.InfoChip = KomponenUi.chip(KomponenUi.StatusChip.PERLU_SERVIS)
	check(perlu.gaya == KomponenUi.GayaChip.WARN and perlu.glif == KomponenUi.GlifChip.SERU and perlu.kunci_teks == "KONDISI_TINGKAT_PERLU", "PERLU_SERVIS = warn + seru + 'Perlu servis'")
	var aus: KomponenUi.InfoChip = KomponenUi.chip(KomponenUi.StatusChip.AUS)
	check(aus.gaya == KomponenUi.GayaChip.NETRAL and aus.glif == KomponenUi.GlifChip.TANPA and aus.kunci_teks == "KONDISI_TINGKAT_AUS", "AUS = netral + teks 'Aus'")
	var milik: KomponenUi.InfoChip = KomponenUi.chip(KomponenUi.StatusChip.DIMILIKI)
	check(milik.gaya == KomponenUi.GayaChip.NETRAL and milik.glif == KomponenUi.GlifChip.CENTANG and milik.kunci_teks == "BENGKEL_DIMILIKI", "DIMILIKI = netral + centang + 'Dimiliki'")
	check(KomponenUi.chip(KomponenUi.StatusChip.HARGA).gaya == KomponenUi.GayaChip.GELAP and KomponenUi.chip(KomponenUi.StatusChip.HARGA).kunci_teks == "", "HARGA = gelap, teks angka dari pemanggil")
	check(KomponenUi.chip(KomponenUi.StatusChip.TINGKAT_AKTIF).gaya == KomponenUi.GayaChip.AKSEN and KomponenUi.chip(KomponenUi.StatusChip.TINGKAT_LAIN).gaya == KomponenUi.GayaChip.NETRAL, "tingkat aktif aksen, lain netral")
	# Kunci teks ada di ui.csv (terjemahan).
	var csv: String = FileAccess.get_file_as_string("res://translations/ui.csv")
	for kunci: String in ["BENGKEL_BAIK", "BENGKEL_DIMILIKI", "KONDISI_TINGKAT_AUS", "KONDISI_TINGKAT_PERLU", "BENGKEL_KOIN_KURANG"]:
		check(csv.contains("\n%s," % kunci), "kunci terjemahan %s ada di ui.csv" % kunci)
	# Dua status dengan gaya yang sama harus beda glif atau teks (warna bukan satu-satunya pembeda).
	var tabrakan: Array[String] = []
	for a: KomponenUi.StatusChip in STATUS:
		for b: KomponenUi.StatusChip in STATUS:
			if a >= b:
				continue
			var ia: KomponenUi.InfoChip = KomponenUi.chip(a)
			var ib: KomponenUi.InfoChip = KomponenUi.chip(b)
			if ia.gaya == ib.gaya and ia.glif == ib.glif and ia.kunci_teks == ib.kunci_teks and a != KomponenUi.StatusChip.TINGKAT_AKTIF and a != KomponenUi.StatusChip.TINGKAT_LAIN:
				tabrakan.append("%d/%d" % [a, b])
	check(tabrakan.is_empty(), "status chip bergaya sama beda glif atau teks (tabrakan: %s)" % [tabrakan])
	# Jejak tingkat: aktif vs lain beda gaya bingkai (aksen vs netral) DAN huruf I/II/III dari pemanggil -> tidak bergantung warna saja (teks tingkat dipasang pemanggil, diuji di bagian B).
	check(KomponenUi.nama_tekstur_chip(KomponenUi.GayaChip.GELAP) == "chip_gelap" and KomponenUi.nama_tekstur_chip(KomponenUi.GayaChip.OK) == "chip_ok" and KomponenUi.nama_tekstur_chip(KomponenUi.GayaChip.WARN) == "chip_warn"
		and KomponenUi.nama_tekstur_chip(KomponenUi.GayaChip.NETRAL) == "chip_netral" and KomponenUi.nama_tekstur_chip(KomponenUi.GayaChip.AKSEN) == "chip_aksen", "nama tekstur lima gaya chip")
	check(KomponenUi.nama_glif_chip(baik) == "glif_centang_ok" and KomponenUi.nama_glif_chip(milik) == "glif_centang_teks2" and KomponenUi.nama_glif_chip(perlu) == "glif_seru_warn" and KomponenUi.nama_glif_chip(aus) == "", "glif chip: centang hijau, centang abu, seru oranye, tanpa")
	for status: KomponenUi.StatusChip in STATUS:
		var nama: String = KomponenUi.nama_glif_chip(KomponenUi.chip(status))
		check(nama == "" or GayaHud.tekstur(nama) != null, "glif chip status %d terpasang" % status)
	check(KomponenUi.status_chip_servis(BikeCondition.Tingkat.BAIK) == KomponenUi.StatusChip.BAIK and KomponenUi.status_chip_servis(BikeCondition.Tingkat.AUS) == KomponenUi.StatusChip.AUS
		and KomponenUi.status_chip_servis(BikeCondition.Tingkat.PERLU_BENGKEL) == KomponenUi.StatusChip.PERLU_SERVIS, "tingkat -> status chip")
	check(KomponenUi.tinggi_chip(KomponenUi.UkuranChip.KECIL) == 16 and KomponenUi.tinggi_chip(KomponenUi.UkuranChip.NORMAL) == 20 and KomponenUi.tinggi_chip(KomponenUi.UkuranChip.BESAR) == 26, "tinggi chip 16/20/26 (V-8)")
	check(KomponenUi.pad_x_chip(KomponenUi.UkuranChip.KECIL) == 1 and KomponenUi.pad_x_chip(KomponenUi.UkuranChip.NORMAL) == 2 and KomponenUi.pad_x_chip(KomponenUi.UkuranChip.BESAR) == 4, "padding chip 1/2/4")


# --- Wujud GayaHud ---

func _test_gaya_tombol() -> void:
	_judul.call("GayaHud: lima fungsi tombol memasang StyleBoxTexture 9-slice, margin, warna, dan font (AC-4)")
	for peran: int in range(5):
		var tombol: Button = Button.new()
		match peran:
			0:
				GayaHud.tombol_utama(tombol)
			1:
				GayaHud.tombol_biasa(tombol)
			2:
				GayaHud.tombol_sakelar(tombol, false)
			3:
				GayaHud.tombol_tenang(tombol)
			4:
				GayaHud.tombol_nonaktif(tombol)
		for gaya: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled"]:
			var kotak: StyleBox = tombol.get_theme_stylebox(gaya)
			check(kotak is StyleBoxTexture, "tombol %d: gaya %s adalah StyleBoxTexture" % [peran, gaya])
			if kotak is StyleBoxTexture:
				var st: StyleBoxTexture = kotak
				check(st.get_texture_margin(SIDE_LEFT) == 4.0 and st.get_texture_margin(SIDE_RIGHT) == 4.0 and st.get_texture_margin(SIDE_TOP) == 6.0 and st.get_texture_margin(SIDE_BOTTOM) == 6.0,
					"tombol %d gaya %s: tepi 9-slice 4/6/4/6 (meta.json)" % [peran, gaya])
		check(tombol.get_theme_stylebox(&"focus") is StyleBoxFlat, "tombol %d: fokus = garis ACCENT" % peran)
		check(tombol.disabled == (peran == 4), "tombol %d: disabled %s" % [peran, peran == 4])
		check(tombol.theme_type_variation == (GayaHud.VARIASI_TOMBOL_TIPIS if peran >= 3 else GayaHud.VARIASI_TOMBOL_TEBAL), "tombol %d: variasi font %s" % [peran, tombol.theme_type_variation])
		tombol.free()
	# Margin isi: utama normal teks naik 2, ditekan turun 2; tenang rata.
	var utama: Button = Button.new()
	GayaHud.tombol_utama(utama)
	var n: StyleBoxTexture = utama.get_theme_stylebox(&"normal")
	var t: StyleBoxTexture = utama.get_theme_stylebox(&"pressed")
	check(n.get_content_margin(SIDE_TOP) == 6.0 and n.get_content_margin(SIDE_BOTTOM) == 8.0, "utama normal: isi atas 6, bawah 8 (bibir 2)")
	check(t.get_content_margin(SIDE_TOP) == 8.0 and t.get_content_margin(SIDE_BOTTOM) == 6.0, "utama ditekan: isi atas 8, bawah 6 (teks turun 2 px)")
	check(n.get_content_margin(SIDE_LEFT) == 4.0 and n.get_content_margin(SIDE_RIGHT) == 4.0, "isi tombol berjarak samping 4")
	check(n.texture == GayaHud.tekstur("btn_utama") and t.texture == GayaHud.tekstur("btn_utama_tekan"), "tekstur utama normal dan ditekan")
	check(utama.get_theme_color(&"font_color") == Palette.UI_BG and utama.get_theme_color(&"font_pressed_color") == Palette.UI_BG, "warna teks utama = UI_BG")
	utama.free()
	var tenang: Button = Button.new()
	GayaHud.tombol_tenang(tenang)
	var tn: StyleBoxTexture = tenang.get_theme_stylebox(&"normal")
	var tt: StyleBoxTexture = tenang.get_theme_stylebox(&"pressed")
	check(tn.get_content_margin(SIDE_TOP) == tt.get_content_margin(SIDE_TOP) and tn.get_content_margin(SIDE_BOTTOM) == tt.get_content_margin(SIDE_BOTTOM) and tn.get_content_margin(SIDE_TOP) == 6.0, "tenang rata: margin sama saat ditekan")
	check(tenang.get_theme_color(&"font_color") == Palette.TEXT_2 and tenang.get_theme_color(&"font_pressed_color") == Palette.TEXT, "tenang teks TEXT_2, ditekan TEXT")
	tenang.free()
	var sakelar_mati: Button = Button.new()
	GayaHud.tombol_sakelar(sakelar_mati, false)
	var sakelar_nyala: Button = Button.new()
	GayaHud.tombol_sakelar(sakelar_nyala, true)
	var sm: StyleBoxTexture = sakelar_mati.get_theme_stylebox(&"normal")
	var sn: StyleBoxTexture = sakelar_nyala.get_theme_stylebox(&"normal")
	check(sm.texture == GayaHud.tekstur("btn_biasa") and sn.texture == GayaHud.tekstur("btn_sakelar_nyala"), "sakelar mati = bingkai biasa, nyala = bingkai nyala")
	check(sm.get_content_margin(SIDE_LEFT) == 8.0 and sn.get_content_margin(SIDE_RIGHT) == 8.0, "sakelar: jarak samping tambahan 4 (isi 8)")
	check(sakelar_nyala.get_theme_stylebox(&"pressed").texture == GayaHud.tekstur("btn_biasa_tekan"), "sakelar ditekan memakai biasa_tekan")
	sakelar_mati.free()
	sakelar_nyala.free()
	# Peran bisa diganti pada tombol yang sama: nonaktif lalu biasa memulihkan.
	var campur: Button = Button.new()
	GayaHud.tombol_nonaktif(campur)
	check(campur.disabled, "tombol_nonaktif mematikan tombol")
	GayaHud.tombol_biasa(campur)
	check(not campur.disabled and campur.get_theme_stylebox(&"normal").texture == GayaHud.tekstur("btn_biasa") and campur.theme_type_variation == GayaHud.VARIASI_TOMBOL_TEBAL, "tombol_biasa memulihkan tombol aktif dan font tebal")
	GayaHud.tombol_nonaktif(campur)
	check(campur.get_theme_color(&"font_disabled_color") == Palette.TEXT_2 and campur.get_theme_color(&"font_color") == Palette.TEXT_2, "nonaktif: semua keadaan teks TEXT_2")
	campur.free()


func _test_gaya_panel_kartu_chip() -> void:
	_judul.call("GayaHud: kartu, panel layar, dan chip (StyleBoxTexture, tepi 9-slice, margin isi)")
	var daftar: Dictionary = {"kartu_biasa": GayaHud.kartu_biasa(), "kartu_menonjol": GayaHud.kartu_menonjol(), "kartu_redup": GayaHud.kartu_redup(), "panel_layar": GayaHud.panel_layar()}
	for nama: String in daftar:
		var st: StyleBoxTexture = daftar[nama]
		check(st.texture == GayaHud.tekstur(nama), "%s: tekstur benar" % nama)
		check(st.get_texture_margin(SIDE_LEFT) == 4.0 and st.get_texture_margin(SIDE_TOP) == 4.0 and st.get_texture_margin(SIDE_RIGHT) == 4.0 and st.get_texture_margin(SIDE_BOTTOM) == 4.0, "%s: tepi 9-slice 4" % nama)
		check(st.get_content_margin(SIDE_LEFT) == 4.0 and st.get_content_margin(SIDE_BOTTOM) == 4.0, "%s: isi berjarak 4" % nama)
	check(GayaHud.kartu(KomponenUi.JenisKartu.MENONJOL).texture == GayaHud.tekstur("kartu_menonjol"), "kartu(jenis) memilih tekstur menurut jenis")
	for status: KomponenUi.StatusChip in STATUS:
		for ukuran: KomponenUi.UkuranChip in [KomponenUi.UkuranChip.KECIL, KomponenUi.UkuranChip.NORMAL, KomponenUi.UkuranChip.BESAR]:
			var st: StyleBoxTexture = GayaHud.chip(status, ukuran)
			var info: KomponenUi.InfoChip = KomponenUi.chip(status)
			check(st.texture == GayaHud.tekstur(KomponenUi.nama_tekstur_chip(info.gaya)), "chip %d/%d: bingkai sesuai gaya" % [status, ukuran])
			check(st.get_texture_margin(SIDE_LEFT) == 3.0 and st.get_content_margin(SIDE_TOP) == 3.0 and st.get_content_margin(SIDE_LEFT) == 3.0 + float(KomponenUi.pad_x_chip(ukuran)), "chip %d/%d: tepi 3 dan isi 3 + padding samping" % [status, ukuran])
			# Tinggi chip = 2 x tepi + tinggi baris teks: 18 - 6 = 12 (Lexend 10 baris 12), 14 - 6 = 8, 24 - 6 = 18.
			check(KomponenUi.tinggi_chip(ukuran) - 2 * Config.UI_CHIP_SLICE_PX >= 8, "chip %d/%d: tinggi memberi ruang baris teks >= 8" % [status, ukuran])
	var tes_ukuran: StyleBoxTexture = GayaHud.chip(KomponenUi.StatusChip.BAIK)
	check(tes_ukuran.get_minimum_size().x == 2.0 * (3.0 + 2.0), "ukuran minimum chip normal = 2 x (3 + 2) lebar")


func _test_arsir_nonaktif() -> void:
	_judul.call("GayaHud: tombol nonaktif diarsir (tengah bingkai diganti ubin 4x4, mode ubin) dan satu tekstur dibangun sekali")
	var tombol: Button = Button.new()
	GayaHud.tombol_nonaktif(tombol)
	var st: StyleBoxTexture = tombol.get_theme_stylebox(&"disabled")
	check(st.axis_stretch_horizontal == StyleBoxTexture.AXIS_STRETCH_MODE_TILE and st.axis_stretch_vertical == StyleBoxTexture.AXIS_STRETCH_MODE_TILE, "nonaktif memakai mode ubin")
	var gambar: Image = st.texture.get_image()
	var arsir: Image = GayaHud.tekstur("arsir_nonaktif").get_image()
	arsir.convert(Image.FORMAT_RGBA8)
	gambar.convert(Image.FORMAT_RGBA8)
	var sama: bool = true
	for y: int in range(4):
		for x: int in range(4):
			if gambar.get_pixel(4 + x, 6 + y) != arsir.get_pixel(x, y):
				sama = false
	check(sama, "sel tengah 4x4 bingkai nonaktif = ubin arsir")
	var dasar: Image = GayaHud.tekstur("btn_nonaktif").get_image()
	dasar.convert(Image.FORMAT_RGBA8)
	check(gambar.get_pixel(0, 3) == dasar.get_pixel(0, 3) and gambar.get_pixel(11, 12) == dasar.get_pixel(11, 12) and gambar.get_pixel(5, 0) == dasar.get_pixel(5, 0), "tepi bingkai nonaktif tidak berubah (hanya tengah diarsir)")
	var warna_tengah: Dictionary = {}
	for y: int in range(4):
		for x: int in range(4):
			warna_tengah[gambar.get_pixel(4 + x, 6 + y)] = true
	check(warna_tengah.size() == 2, "arsir punya tepat dua nada di tengah (bentuk diagonal, bukan warna datar)")
	var lain: Button = Button.new()
	GayaHud.tombol_nonaktif(lain)
	check(lain.get_theme_stylebox(&"disabled").texture == st.texture, "tekstur nonaktif dibangun sekali (dipakai bersama)")
	tombol.free()
	lain.free()


func _test_gaya_lama_tak_berubah() -> void:
	_judul.call("GayaHud: fungsi lama (kotak, terapkan_tombol, panel_hud) tidak berubah (AC-4)")
	var k: StyleBoxFlat = GayaHud.kotak(Palette.HUD_PANEL, Palette.OUTLINE)
	check(k.bg_color == Palette.HUD_PANEL and k.border_color == Palette.OUTLINE and k.border_width_left == 1 and not k.anti_aliasing, "kotak: isi, garis 1 px, tanpa anti-alias")
	check(k.content_margin_left == float(Config.HUD_PANEL_PAD_X_PX) and k.content_margin_top == float(Config.HUD_PANEL_PAD_Y_PX), "kotak: padding dari Config")
	var b: Button = Button.new()
	GayaHud.terapkan_tombol(b)
	var normal: StyleBoxFlat = b.get_theme_stylebox(&"normal")
	var tekan: StyleBoxFlat = b.get_theme_stylebox(&"pressed")
	check(normal.bg_color == Palette.HUD_PANEL and normal.border_color == Palette.OUTLINE and tekan.bg_color == Palette.UI_PANEL_RAISED and tekan.border_color == Palette.ACCENT, "terapkan_tombol: normal HUD_PANEL/OUTLINE, ditekan UI_PANEL_RAISED/ACCENT")
	check(b.get_theme_color(&"font_color") == Palette.TEXT and b.get_theme_color(&"font_pressed_color") == Palette.ACCENT and b.theme_type_variation == &"", "terapkan_tombol: warna teks, tanpa variasi tema baru")
	check(not b.disabled, "terapkan_tombol tidak menyentuh disabled")
	b.free()
	var p: StyleBoxTexture = GayaHud.panel_hud()
	check(p.get_texture_margin(SIDE_LEFT) == float(Config.HUD_PANEL_9SLICE_PX) and p.content_margin_left == float(Config.HUD_PANEL_PAD_X_PX) and p.content_margin_top == float(Config.HUD_PANEL_PAD_Y_PX), "panel_hud: tepi dan padding sama")
	check(GayaHud.panel_hud(11).content_margin_right == 11.0, "panel_hud(pad_x) tetap menerima padding samping")
	check(GayaHud.TEKSTUR_PANEL_HUD.get_width() == 12 and GayaHud.TEKSTUR_PANEL_HUD.get_height() == 12, "tekstur panel HUD lama tetap 12x12")


# --- Kotak kondisi besar (AC-5) ---

func _test_kondisi_besar_geometri() -> void:
	_judul.call("Kotak kondisi besar: 8x8, jarak 2, tanda '!' 3x9; HUD 5x5 tidak berubah (AC-5)")
	check(Config.KONDISI_BESAR_KOTAK_PX == 8 and Config.KONDISI_BESAR_KOTAK_JARAK_PX == 2, "kotak 8x8 jarak 2 (README redesain 4)")
	check(TampilKondisiBesar.ukuran_seru() == Vector2i(3, 9), "tanda '!' 3x9")
	check(TampilKondisiBesar.ukuran() == Vector2i(3 * 8 + 2 * 2 + 2 + 3, 9), "ukuran komponen 33x9 (3 kotak + 2 jarak + 2 + tanda), ruang '!' selalu disediakan")
	check(TampilKondisiBesar.rect_kotak(0) == Rect2i(0, 0, 8, 8) and TampilKondisiBesar.rect_kotak(1) == Rect2i(10, 0, 8, 8) and TampilKondisiBesar.rect_kotak(2) == Rect2i(20, 0, 8, 8), "posisi tiga kotak x = 0, 10, 20")
	check(TampilKondisiBesar.posisi_seru() == Vector2i(30, 0), "tanda '!' mulai x 30 (28 + jarak 2)")
	var rb: Rect2i = TampilKondisiBesar.rect_kotak(2)
	check(rb.end.x + 2 == TampilKondisiBesar.posisi_seru().x and TampilKondisiBesar.posisi_seru().x + 3 == TampilKondisiBesar.ukuran().x, "tanda '!' tepat di kanan kotak ketiga dan memenuhi lebar komponen")
	check(KotakKondisi.ukuran() == Vector2(float(Config.HUD_IKON_PX + Config.KONDISI_HUD_IKON_JARAK_PX + 3 * 5 + 2 * Config.KONDISI_HUD_KOTAK_JARAK_PX + Config.KONDISI_HUD_SERU_JARAK_PX + Config.KONDISI_HUD_SERU_LEBAR_PX), float(Config.HUD_IKON_PX)),
		"KotakKondisi HUD 14 px tidak berubah ukurannya")
	check(Config.KONDISI_HUD_KOTAK_PX == 5, "kotak HUD tetap 5x5")
	check(TampilKondisiBesar.bidang(1.0, false).size() == 3, "tiga bidang kotak")


func _test_kondisi_besar_warna() -> void:
	_judul.call("Kotak kondisi besar: jumlah terisi, berongga = AUS/hilang, WARN, terbaca tanpa warna (AC-5)")
	var salah: Array[String] = []
	for i: int in range(101):
		var k: float = float(i) / 100.0
		var terisi: int = 3 if k >= 0.7 else (2 if k >= 0.35 else (1 if k > 0.0 else 0))
		var bidang: Array[TampilKondisiBesar.BidangKotak] = TampilKondisiBesar.bidang(k, false)
		var hitung: int = 0
		var urut: bool = true
		for j: int in range(3):
			var penuh: bool = bidang[j].isi != Palette.UI_BG
			if penuh:
				hitung += 1
			if penuh != (j < terisi):
				urut = false
		var warn: bool = k < 0.35
		var warna_ok: bool = true
		for j: int in range(terisi):
			if (bidang[j].isi == Palette.WARN) != warn:
				warna_ok = false
		if hitung != terisi or not urut or not warna_ok:
			salah.append(str(k))
	check(salah.is_empty(), "sapuan 0..1: terisi dari kiri sebanyak 3/2/1/0 dan berwarna WARN hanya saat PERLU_BENGKEL (salah: %s)" % [salah])
	# Peringatan (kedip) mewarnai kotak terisi WARN walau kondisi baik.
	var kedip: Array[TampilKondisiBesar.BidangKotak] = TampilKondisiBesar.bidang(1.0, true)
	check(kedip[0].isi == Palette.WARN and kedip[1].isi == Palette.WARN and kedip[2].isi == Palette.WARN, "peringatan mewarnai kotak terisi WARN")
	# Terbaca tanpa warna: luminans isi terisi (TEXT, WARN) jauh di atas isi berongga (UI_BG); garis berongga lebih terang dari garis terisi.
	check(_lum(TampilKondisiBesar.warna_isi(TampilKondisi.Kotak.PENUH)) - _lum(TampilKondisiBesar.warna_isi(TampilKondisi.Kotak.KOSONG)) > 0.5, "PENUH jauh lebih terang dari KOSONG (luminans)")
	check(_lum(TampilKondisiBesar.warna_isi(TampilKondisi.Kotak.PENUH_WARN)) - _lum(TampilKondisiBesar.warna_isi(TampilKondisi.Kotak.KOSONG)) > 0.25, "PENUH_WARN jauh lebih terang dari KOSONG (luminans)")
	check(_lum(TampilKondisiBesar.warna_garis(TampilKondisi.Kotak.KOSONG)) > _lum(TampilKondisiBesar.warna_garis(TampilKondisi.Kotak.PENUH)) + 0.3, "garis berongga terang, garis terisi gelap (bentuk berongga terbaca dari tepi)")
	check(TampilKondisiBesar.warna_isi(TampilKondisi.Kotak.PENUH) == Color("#FFF3E3") and TampilKondisiBesar.warna_isi(TampilKondisi.Kotak.PENUH_WARN) == Color("#FF8A3D") and TampilKondisiBesar.warna_isi(TampilKondisi.Kotak.KOSONG) == Color("#1C130F"), "warna isi literal kanvas: TEXT, WARN, UI_BG")
	check(TampilKondisiBesar.warna_garis(TampilKondisi.Kotak.PENUH) == Color("#0E0A1C") and TampilKondisiBesar.warna_garis(TampilKondisi.Kotak.KOSONG) == Color("#CDB9A3"), "warna garis literal kanvas: OUTLINE terisi, TEXT_2 berongga")
	check(TampilKondisiBesar.bidang(NAN, false)[0].isi == Palette.TEXT, "kondisi NaN = baik (tiga kotak penuh), tidak jatuh ke kosong")


func _test_kondisi_besar_node() -> void:
	_judul.call("KotakKondisiBesar (node): isi tampil = TampilKondisi, '!' hanya PERLU_BENGKEL, gambar ulang hanya bila berubah")
	var node: KotakKondisiBesar = KotakKondisiBesar.new()
	node.tampilkan(1.0)
	check(node.kotak_tampil() == [TampilKondisi.Kotak.PENUH, TampilKondisi.Kotak.PENUH, TampilKondisi.Kotak.PENUH] and not node.seru_tampil(), "baik: tiga penuh, tanpa '!'")
	node.tampilkan(0.5)
	check(node.kotak_tampil() == [TampilKondisi.Kotak.PENUH, TampilKondisi.Kotak.PENUH, TampilKondisi.Kotak.KOSONG] and not node.seru_tampil(), "aus: dua penuh + satu berongga, tanpa '!'")
	node.tampilkan(0.2)
	check(node.kotak_tampil() == [TampilKondisi.Kotak.PENUH_WARN, TampilKondisi.Kotak.KOSONG, TampilKondisi.Kotak.KOSONG] and node.seru_tampil(), "perlu bengkel: satu WARN + dua berongga + '!'")
	node.tampilkan(0.0)
	check(node.kotak_tampil() == [TampilKondisi.Kotak.KOSONG, TampilKondisi.Kotak.KOSONG, TampilKondisi.Kotak.KOSONG] and node.seru_tampil(), "kondisi 0: tiga berongga + '!'")
	node.tampilkan(0.9, true)
	check(node.kotak_tampil() == [TampilKondisi.Kotak.PENUH_WARN, TampilKondisi.Kotak.PENUH_WARN, TampilKondisi.Kotak.PENUH_WARN], "peringatan: kotak terisi WARN")
	node.free()
	var hud: KotakKondisi = KotakKondisi.new()
	hud.tampilkan(0.2, 0.0)
	check(hud.kotak_tampil() == [TampilKondisi.Kotak.PENUH_WARN, TampilKondisi.Kotak.KOSONG, TampilKondisi.Kotak.KOSONG] and hud.seru_tampil() and KotakKondisi.warna(TampilKondisi.Kotak.KOSONG) == Palette.UI_PANEL_RAISED,
		"KotakKondisi HUD 14 px tidak berubah perilaku dan warnanya")
	hud.free()


# --- Tema ---

func _test_theme() -> void:
	_judul.call("Tema: type variation baru U-3 dengan skala V-8 (utama 12, kecil 11, mini 10, label 10, judul 24, chip 12/10/14, tombol 12); variation lama tidak berubah")
	var tema: Theme = load("res://assets/ui/theme.tres")
	check(tema != null, "theme.tres termuat")
	if tema == null:
		return
	var ukuran: Dictionary = {&"LayarTeksUtama": ["Label", 12], &"LayarTeksKecil": ["Label", 11], &"LayarTeksMini": ["Label", 10], &"LayarLabel": ["Label", 10], &"LayarJudul": ["Label", 24],
			&"ChipTeks": ["Label", 12], &"ChipTeksKecil": ["Label", 10], &"ChipTeksBesar": ["Label", 14], &"TombolPeran": ["Button", 12], &"TombolTipis": ["Button", 12]}
	for nama: StringName in ukuran:
		var info: Array = ukuran[nama]
		check(tema.get_type_variation_base(nama) == StringName(info[0]), "variation %s berdasar %s" % [nama, info[0]])
		check(tema.get_font_size(&"font_size", nama) == int(info[1]), "variation %s ukuran font %d" % [nama, info[1]])
		check(tema.get_font(&"font", nama) != null, "variation %s punya font" % nama)
	check(tema.get_font(&"font", &"LayarJudul") == tema.get_font(&"font", &"JudulBesar"), "judul layar 24 memakai Lilita One yang sama dengan JudulBesar")
	check(tema.get_font(&"font", &"LayarTeksUtama") == tema.get_font(&"font", &"HudAngka") and tema.get_font(&"font", &"LayarTeksKecil") == tema.get_font(&"font", &"TeksKecil"), "teks utama SemiBold dan kecil Regular = font variation yang ada")
	check(tema.get_font(&"font", &"TombolPeran") != tema.get_font(&"font", &"TombolTipis"), "tombol tebal dan tipis beda bobot font")
	check(tema.get_font_size(&"font_size", &"HudAngka") == 10 and tema.get_font_size(&"font_size", &"HudLabel") == 8 and tema.get_font_size(&"font_size", &"HudTeks") == 8
		and tema.get_font_size(&"font_size", &"JudulBesar") == 24 and tema.get_font_size(&"font_size", &"JudulLayar") == 16 and tema.get_font_size(&"font_size", &"TeksKecil") == 7, "variation lama tidak berubah")
