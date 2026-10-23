class_name TesTampilBengkel
extends RefCounted
## Tes pemilihan keadaan layar bengkel tata C, logika murni (`TampilBengkel`, run ui1-komponen-bengkel bagian B, AC-6 dan AC-7): keadaan kartu servis (menonjol, redup, biasa), chip penanda kondisi di
## sepeda, status aksi tombol (aktif, nonaktif bertulis alasan, tidak ada), jejak tingkat upgrade I, II, III, lebar kolom, letak panggung, dan penanda. Oracle independen: angka kanvas
## (Bengkel.dc.html: kolom 48 %, sepeda `sw/2 - 58`, papan `sw/2 - 180`, chip `x - w - 4`, `x + 5`, `x - 10`, `y - 7`, `y + 6`), ambang kondisi BALANCING 8 (AUS di bawah 0,70, PERLU_BENGKEL
## di bawah 0,35), dan `ui_bengkel_sepeda.json` ditulis literal oleh tes, bukan dihitung ulang dengan fungsi yang dites.

var _cek: Callable
var _judul: Callable


func _init(cek: Callable, judul: Callable) -> void:
	_cek = cek
	_judul = judul


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_test_servis_kartu_dan_status()
	_test_servis_ambang_dan_saldo()
	_test_penanda_sepeda()
	_test_aksi_dan_teks_alasan()
	_test_upgrade_tunggal()
	_test_upgrade_bertingkat()
	_test_tingkat_chip_dan_kunci()
	_test_kolom_dan_panggung()
	_test_rect_chip_dan_titik()
	_test_data_sepeda()


func _servis(kondisi: float, harga: int = 100, saldo: int = 1000) -> TampilBengkel.InfoServis:
	return TampilBengkel.servis(kondisi, harga, saldo)


# --- Kartu servis ---

func _test_servis_kartu_dan_status() -> void:
	_judul.call("Bengkel (murni): kartu servis PERLU_BENGKEL menonjol, BAIK redup, AUS biasa; penuh = chip Baik tanpa harga dan tombol; teks status dari tingkat (AC-7)")
	var penuh: TampilBengkel.InfoServis = _servis(1.0)
	check(penuh.penuh and penuh.kartu == KomponenUi.JenisKartu.REDUP and penuh.aksi == TampilBengkel.Aksi.TIDAK_ADA and penuh.harga == 0 and penuh.kunci_status == "" and not penuh.penanda, "kondisi 1,0: penuh, kartu redup, tanpa aksi, tanpa harga, tanpa status, tanpa penanda di sepeda")
	check(penuh.status_chip == KomponenUi.StatusChip.BAIK, "kondisi 1,0: chip pernyataan Baik")
	var baik: TampilBengkel.InfoServis = _servis(0.75, 47)
	check(not baik.penuh and baik.kartu == KomponenUi.JenisKartu.REDUP and baik.aksi == TampilBengkel.Aksi.AKTIF and baik.harga == 47 and baik.kunci_status == "KONDISI_TINGKAT_BAIK" and not baik.penanda, "kondisi 0,75 (BAIK belum penuh): kartu redup tetapi Servis aktif berharga 47, status 'Baik', sepeda bersih")
	var aus: TampilBengkel.InfoServis = _servis(0.5, 60)
	check(aus.kartu == KomponenUi.JenisKartu.BIASA and aus.aksi == TampilBengkel.Aksi.AKTIF and aus.kunci_status == "KONDISI_TINGKAT_AUS" and aus.penanda and aus.status_penanda == KomponenUi.StatusChip.AUS and aus.kunci_penanda == "BENGKEL_PENANDA_AUS", "kondisi 0,50 (AUS): kartu biasa, chip penanda '{nama} aus' bergaya AUS")
	var perlu: TampilBengkel.InfoServis = _servis(0.2, 105)
	check(perlu.kartu == KomponenUi.JenisKartu.MENONJOL and perlu.kunci_status == "KONDISI_TINGKAT_PERLU" and perlu.penanda and perlu.status_penanda == KomponenUi.StatusChip.PERLU_SERVIS and perlu.kunci_penanda == "BENGKEL_PENANDA_PERLU", "kondisi 0,20 (PERLU_BENGKEL): kartu menonjol, status 'Perlu servis', chip penanda '! {nama}' bergaya PERLU_SERVIS")
	var nol: TampilBengkel.InfoServis = _servis(0.0, 120)
	check(nol.kartu == KomponenUi.JenisKartu.MENONJOL and nol.penanda and nol.status_penanda == KomponenUi.StatusChip.PERLU_SERVIS and nol.aksi == TampilBengkel.Aksi.AKTIF, "kondisi 0,0: tetap menonjol dan penanda PERLU, Servis aktif")
	# Tiga jenis kartu berbeda bentuk dan tiga chip penanda berbeda teks (terbaca tanpa warna).
	check(perlu.kartu != aus.kartu and aus.kartu != baik.kartu and perlu.kunci_penanda != aus.kunci_penanda and perlu.kunci_status != aus.kunci_status, "menonjol, biasa, redup berbeda; teks penanda dan status PERLU beda dari AUS (tidak hanya warna)")


func _test_servis_ambang_dan_saldo() -> void:
	_judul.call("Bengkel (murni): ambang kondisi (0,70 dan 0,35 literal BALANCING 8) dan saldo tepat sama dengan harga = aktif, kurang 1 = nonaktif 'Koin kurang' (AC-7c)")
	var kasus: Array = [
		[1.0, KomponenUi.JenisKartu.REDUP, false], [0.70, KomponenUi.JenisKartu.REDUP, false], [0.6999, KomponenUi.JenisKartu.BIASA, true],
		[0.35, KomponenUi.JenisKartu.BIASA, true], [0.3499, KomponenUi.JenisKartu.MENONJOL, true], [0.0, KomponenUi.JenisKartu.MENONJOL, true],
	]
	for k: Array in kasus:
		var info: TampilBengkel.InfoServis = _servis(k[0])
		check(info.kartu == k[1] and info.penanda == k[2], "kondisi %s: kartu %s, penanda %s (dapat %s / %s)" % [k[0], k[1], k[2], info.kartu, info.penanda])
	var pas: TampilBengkel.InfoServis = TampilBengkel.servis(0.3, 84, 84)
	var kurang: TampilBengkel.InfoServis = TampilBengkel.servis(0.3, 84, 83)
	check(pas.aksi == TampilBengkel.Aksi.AKTIF and kurang.aksi == TampilBengkel.Aksi.KURANG, "saldo 84 untuk harga 84: AKTIF; saldo 83: KURANG")
	check(TampilBengkel.servis(1.0, 84, 0).aksi == TampilBengkel.Aksi.TIDAK_ADA and TampilBengkel.servis(1.0, 84, 0).harga == 0, "komponen penuh: tanpa aksi walau saldo 0 (tidak ada tombol Servis)")
	check(TampilBengkel.servis(0.9999995, 84, 0).aksi == TampilBengkel.Aksi.TIDAK_ADA, "kondisi dalam toleransi 1,0 dianggap penuh seperti Economy (kartu tanpa aksi)")
	check(TampilBengkel.servis(0.999, 84, 0).aksi == TampilBengkel.Aksi.KURANG, "kondisi 0,999 belum penuh: tombol ada (nonaktif bila saldo kurang)")


func _test_penanda_sepeda() -> void:
	_judul.call("Bengkel (murni): sisi chip penanda per komponen (ban di depan titik, rem sesudah titik, rantai di bawah) dan titik penanda = Config (AC-6)")
	check(TampilBengkel.SISI_PENANDA == {"ban": TampilBengkel.Sisi.AWAL, "rem": TampilBengkel.Sisi.AKHIR, "rantai": TampilBengkel.Sisi.BAWAH}, "sisi chip: ban AWAL, rem AKHIR, rantai BAWAH")
	check(TampilBengkel.titik_sepeda(0) == Vector2i(5, 68) and TampilBengkel.titik_sepeda(1) == Vector2i(74, 4) and TampilBengkel.titik_sepeda(2) == Vector2i(33, 54), "titik ban (5,68), rem (74,4), rantai (33,54) urut ban, rem, rantai")
	check(Config.KONDISI_KOMPONEN == ["ban", "rem", "rantai"], "urutan komponen ban, rem, rantai (indeks titik sejajar)")


# --- Tombol ---

func _test_aksi_dan_teks_alasan() -> void:
	_judul.call("Bengkel (murni): keadaan aksi dan kunci teks tombol: aktif = teks aksi, nonaktif = 'Koin kurang' (terbaca tanpa warna), tidak ada = tanpa tombol (AC-7)")
	check(TampilBengkel.aksi(true, 600, 600) == TampilBengkel.Aksi.AKTIF and TampilBengkel.aksi(true, 599, 600) == TampilBengkel.Aksi.KURANG and TampilBengkel.aksi(true, 0, 1) == TampilBengkel.Aksi.KURANG, "aksi: 600 untuk 600 aktif, 599 untuk 600 kurang, 0 untuk 1 kurang")
	check(TampilBengkel.aksi(false, 99999, 1) == TampilBengkel.Aksi.TIDAK_ADA and TampilBengkel.aksi(true, 0, 0) == TampilBengkel.Aksi.AKTIF, "tidak tersedia = TIDAK_ADA walau saldo besar; harga 0 dengan saldo 0 = aktif")
	check(TampilBengkel.kunci_tombol(TampilBengkel.Aksi.AKTIF, "BENGKEL_SERVIS") == "BENGKEL_SERVIS" and TampilBengkel.kunci_tombol(TampilBengkel.Aksi.KURANG, "BENGKEL_SERVIS") == "BENGKEL_KOIN_KURANG", "teks tombol: aktif = kunci aksi, kurang = BENGKEL_KOIN_KURANG")
	check(TampilBengkel.kunci_tombol(TampilBengkel.Aksi.KURANG, "BENGKEL_BELI") == "BENGKEL_KOIN_KURANG" and TampilBengkel.kunci_tombol(TampilBengkel.Aksi.AKTIF, "BENGKEL_BELI") == "BENGKEL_BELI", "Beli: sama aturan")
	check(TampilBengkel.KUNCI_AKSI_SERVIS == "BENGKEL_SERVIS" and TampilBengkel.KUNCI_AKSI_BELI == "BENGKEL_BELI" and TampilBengkel.KUNCI_KURANG == "BENGKEL_KOIN_KURANG", "kunci teks aksi literal")


# --- Upgrade ---

func _test_upgrade_tunggal() -> void:
	_judul.call("Bengkel (murni): kartu upgrade satu tingkat: dijual (biasa), saldo kurang (nonaktif), dimiliki (redup, tanpa aksi), tinggi 62, tanpa jejak (AC-7d)")
	var jual: TampilBengkel.InfoUpgrade = TampilBengkel.upgrade([1], [600], 0, 600)
	check(not jual.dimiliki and jual.aksi == TampilBengkel.Aksi.AKTIF and jual.kartu == KomponenUi.JenisKartu.BIASA and jual.harga == 600 and jual.tingkat == 1 and jual.indeks == 0 and not jual.jejak_tampil and jual.tinggi == 62, "level 0, saldo 600: dijual, aktif, kartu biasa, harga 600, tinggi 62, tanpa jejak")
	check(jual.status_tingkat == KomponenUi.StatusChip.TINGKAT_LAIN and jual.jejak == [TampilBengkel.StatusJejak.AKTIF], "chip tingkat netral untuk tingkat tunggal yang belum dimiliki; jejak internal [AKTIF] (tidak ditampilkan)")
	var kurang: TampilBengkel.InfoUpgrade = TampilBengkel.upgrade([1], [600], 0, 599)
	check(kurang.aksi == TampilBengkel.Aksi.KURANG and kurang.kartu == KomponenUi.JenisKartu.BIASA, "saldo 599 untuk 600: nonaktif 'Koin kurang', kartu tetap biasa")
	var milik: TampilBengkel.InfoUpgrade = TampilBengkel.upgrade([1], [600], 1, 0)
	check(milik.dimiliki and milik.aksi == TampilBengkel.Aksi.TIDAK_ADA and milik.kartu == KomponenUi.JenisKartu.REDUP and milik.status_tingkat == KomponenUi.StatusChip.TINGKAT_AKTIF and milik.jejak == [TampilBengkel.StatusJejak.DIMILIKI] and milik.tinggi == 62, "level 1: dimiliki, tanpa aksi walau saldo 0, kartu redup, chip tingkat aksen")
	var lebih: TampilBengkel.InfoUpgrade = TampilBengkel.upgrade([1], [600], 7, 0)
	check(lebih.dimiliki and lebih.indeks == 0 and lebih.aksi == TampilBengkel.Aksi.TIDAK_ADA, "level di save melebihi data (7): tetap dimiliki, indeks tingkat terakhir")
	var kosong: TampilBengkel.InfoUpgrade = TampilBengkel.upgrade([], [], 0, 100)
	check(kosong.jumlah == 0 and kosong.aksi == TampilBengkel.Aksi.TIDAK_ADA and kosong.jejak.is_empty(), "tanpa data tingkat: tidak ada aksi dan jejak (tidak crash)")


func _test_upgrade_bertingkat() -> void:
	_judul.call("Bengkel (murni): upgrade bertingkat I, II, III = satu kartu berganti isi dengan jejak (aktif, tersedia, dimiliki), tinggi 72 (AC-7, kanvas Bengkel_Tingkat)")
	var tingkat: Array[int] = [1, 2, 3]
	var harga: Array[int] = [600, 900, 1500]
	var s0: TampilBengkel.InfoUpgrade = TampilBengkel.upgrade(tingkat, harga, 0, 5000)
	check(s0.indeks == 0 and s0.tingkat == 1 and s0.harga == 600 and s0.jejak == [TampilBengkel.StatusJejak.AKTIF, TampilBengkel.StatusJejak.MENUNGGU, TampilBengkel.StatusJejak.MENUNGGU] and s0.jejak_tampil and s0.tinggi == 72 and not s0.dimiliki, "level 0: tingkat I dijual 600, jejak [aktif, menunggu, menunggu], tinggi 72")
	check(s0.status_tingkat == KomponenUi.StatusChip.TINGKAT_AKTIF, "komponen bertingkat: chip tingkat di ikon bergaya aksen (kanvas Bengkel_Tingkat)")
	var s1: TampilBengkel.InfoUpgrade = TampilBengkel.upgrade(tingkat, harga, 1, 899)
	check(s1.indeks == 1 and s1.tingkat == 2 and s1.harga == 900 and s1.aksi == TampilBengkel.Aksi.KURANG and s1.jejak == [TampilBengkel.StatusJejak.DIMILIKI, TampilBengkel.StatusJejak.AKTIF, TampilBengkel.StatusJejak.MENUNGGU], "level 1, saldo 899: tingkat II dijual 900 nonaktif, jejak [dimiliki, aktif, menunggu]")
	var s2: TampilBengkel.InfoUpgrade = TampilBengkel.upgrade(tingkat, harga, 2, 1500)
	check(s2.indeks == 2 and s2.tingkat == 3 and s2.harga == 1500 and s2.aksi == TampilBengkel.Aksi.AKTIF and s2.jejak == [TampilBengkel.StatusJejak.DIMILIKI, TampilBengkel.StatusJejak.DIMILIKI, TampilBengkel.StatusJejak.AKTIF], "level 2, saldo 1500: tingkat III dijual 1500 aktif, jejak [dimiliki, dimiliki, aktif]")
	var s3: TampilBengkel.InfoUpgrade = TampilBengkel.upgrade(tingkat, harga, 3, 0)
	check(s3.dimiliki and s3.indeks == 2 and s3.tingkat == 3 and s3.kartu == KomponenUi.JenisKartu.REDUP and s3.aksi == TampilBengkel.Aksi.TIDAK_ADA and s3.jejak == [TampilBengkel.StatusJejak.DIMILIKI, TampilBengkel.StatusJejak.DIMILIKI, TampilBengkel.StatusJejak.DIMILIKI], "level 3: semua dimiliki, kartu redup, tingkat III tampil, jejak tiga dimiliki")
	var dua: TampilBengkel.InfoUpgrade = TampilBengkel.upgrade([1, 2], [600, 900], 1, 1000)
	check(dua.jejak_tampil and dua.tinggi == 72 and dua.jejak.size() == 2, "dua tingkat: jejak tampil dengan dua chip")


func _test_tingkat_chip_dan_kunci() -> void:
	_judul.call("Bengkel (murni): chip tingkat dan kunci angka romawi I, II, III (selain itu angka biasa), gaya chip jejak (AC-7)")
	check(TampilBengkel.status_chip_tingkat(false, 1) == KomponenUi.StatusChip.TINGKAT_LAIN and TampilBengkel.status_chip_tingkat(true, 1) == KomponenUi.StatusChip.TINGKAT_AKTIF and TampilBengkel.status_chip_tingkat(false, 2) == KomponenUi.StatusChip.TINGKAT_AKTIF and TampilBengkel.status_chip_tingkat(true, 3) == KomponenUi.StatusChip.TINGKAT_AKTIF, "chip tingkat aksen bila dimiliki atau bertingkat, selain itu netral")
	check(TampilBengkel.status_chip_jejak(TampilBengkel.StatusJejak.AKTIF) == KomponenUi.StatusChip.TINGKAT_AKTIF and TampilBengkel.status_chip_jejak(TampilBengkel.StatusJejak.DIMILIKI) == KomponenUi.StatusChip.TINGKAT_LAIN and TampilBengkel.status_chip_jejak(TampilBengkel.StatusJejak.MENUNGGU) == KomponenUi.StatusChip.TINGKAT_LAIN, "jejak: aktif aksen, dimiliki dan menunggu netral")
	check(TampilBengkel.kunci_tingkat(1) == "BENGKEL_TINGKAT_1" and TampilBengkel.kunci_tingkat(2) == "BENGKEL_TINGKAT_2" and TampilBengkel.kunci_tingkat(3) == "BENGKEL_TINGKAT_3", "tingkat 1, 2, 3 = kunci I, II, III")
	check(TampilBengkel.kunci_tingkat(4) == "BENGKEL_TINGKAT_LAIN" and TampilBengkel.kunci_tingkat(0) == "BENGKEL_TINGKAT_LAIN" and TampilBengkel.kunci_tingkat(-1) == "BENGKEL_TINGKAT_LAIN", "di luar 1..3 = angka biasa")
	check(Config.BENGKEL_JEJAK_MENUNGGU_ALFA == 0.55, "tingkat yang menunggu beralfa 0,55 (kanvas opacity .55)")


# --- Geometri ---

func _test_kolom_dan_panggung() -> void:
	_judul.call("Bengkel (murni): lebar kolom 48 % | 8 | upgrade dan letak papan, sepeda di panggung sama dengan kanvas (AC-6)")
	check(TampilBengkel.lebar_kolom(616) == Vector2i(296, 312), "lebar 640 (isi 616): servis 296, upgrade 312 (kanvas wl 296, wr 312)")
	check(TampilBengkel.lebar_kolom(592) == Vector2i(284, 300), "lebar 640 dengan inset kiri 24 (isi 592): servis 284, upgrade 300 (kanvas keadaan g)")
	check(TampilBengkel.lebar_kolom(776) == Vector2i(372, 396), "lebar 800 (isi 776): servis 372, upgrade 396 (kanvas 800)")
	check(TampilBengkel.lebar_kolom(756) == Vector2i(363, 385), "lebar 780 (isi 756): servis 363 (362,88 dibulatkan), upgrade 385")
	for total: int in [500, 592, 616, 656, 700, 776]:
		var kolom: Vector2i = TampilBengkel.lebar_kolom(total)
		check(kolom.x + 8 + kolom.y == total, "jumlah kolom + jarak 8 = isi (%d)" % total)
	var t640: TampilBengkel.TataPanggung = TampilBengkel.tata_panggung(280, 92)
	check(t640.sepeda == Vector2i(82, 10) and t640.papan == Vector2i(-40, -12), "panggung 280x92 (lebar 640): sepeda (82, 10), papan (-40, -12) (kanvas bx = 140 - 58, by = 92 - 4 - 78, papanX = 140 - 180)")
	var t800: TampilBengkel.TataPanggung = TampilBengkel.tata_panggung(356, 92)
	check(t800.sepeda == Vector2i(120, 10) and t800.papan == Vector2i(-2, -12), "panggung 356x92 (lebar 800): sepeda (120, 10), papan (-2, -12)")
	var tinggi: TampilBengkel.TataPanggung = TampilBengkel.tata_panggung(281, 84)
	check(tinggi.sepeda == Vector2i(82, 2) and tinggi.papan == Vector2i(-40, -20), "panggung 281x84 (lebar ganjil, inset bawah): sepeda (82, 2), papan (-40, -20)")


func _test_rect_chip_dan_titik() -> void:
	_judul.call("Bengkel (murni): letak chip penanda dan titik di panggung mengikuti kanvas dan selalu di dalam panggung (AC-6, AC-9)")
	var tata: TampilBengkel.TataPanggung = TampilBengkel.tata_panggung(280, 92)
	var panggung: Vector2i = Vector2i(280, 92)
	var chip: Vector2i = Vector2i(40, 14)
	check(TampilBengkel.rect_chip(0, tata, chip, panggung) == Rect2i(87 - 40 - 4, 78 - 7, 40, 14), "ban (di depan titik): x = 87 - 40 - 4 = 43, y = 78 - 7 = 71")
	check(TampilBengkel.rect_chip(1, tata, chip, panggung) == Rect2i(156 + 5, 14 - 7, 40, 14), "rem (sesudah titik): x = 156 + 5 = 161, y = 14 - 7 = 7")
	check(TampilBengkel.rect_chip(2, tata, chip, panggung) == Rect2i(115 - 10, 64 + 6, 40, 14), "rantai (di bawah titik): x = 115 - 10 = 105, y = 64 + 6 = 70")
	check(TampilBengkel.rect_titik(0, tata) == Rect2i(87 - 2, 78 - 2, 5, 5) and TampilBengkel.rect_titik(1, tata) == Rect2i(156 - 2, 14 - 2, 5, 5), "titik 3x3 berbingkai 1 px = 5x5 berpusat di titik sepeda")
	# Dijepit: panggung rendah (inset bawah) menaikkan sepeda ke atas dan chip rem tidak keluar di atas; chip ban tidak keluar di kiri.
	var rendah: TampilBengkel.TataPanggung = TampilBengkel.tata_panggung(280, 84)
	var rem_rendah: Rect2i = TampilBengkel.rect_chip(1, rendah, chip, Vector2i(280, 84))
	check(rem_rendah.position.y == 0, "panggung 84: chip rem (y mentah -1) dijepit ke 0 (tidak keluar panggung)")
	var sempit: TampilBengkel.TataPanggung = TampilBengkel.tata_panggung(120, 92)
	var ban_sempit: Rect2i = TampilBengkel.rect_chip(0, sempit, Vector2i(60, 14), Vector2i(120, 92))
	check(ban_sempit.position.x == 2, "panggung sempit: chip ban tidak melewati tepi kiri (x dijepit ke 2)")
	for lebar: int in [200, 280, 300, 356]:
		for tinggi_panggung: int in [78, 84, 92, 100]:
			var tt: TampilBengkel.TataPanggung = TampilBengkel.tata_panggung(lebar, tinggi_panggung)
			for i: int in range(3):
				var r: Rect2i = TampilBengkel.rect_chip(i, tt, chip, Vector2i(lebar, tinggi_panggung))
				check(Rect2i(0, 0, lebar, tinggi_panggung).encloses(r), "chip %d di panggung %dx%d berada di dalam panggung: %s" % [i, lebar, tinggi_panggung, r])


# --- Data sepeda: Config = JSON = PNG ---

func _test_data_sepeda() -> void:
	_judul.call("Bengkel: titik dan ukuran sepeda di Config = ui_bengkel_sepeda.json = sepeda.json docs = ukuran PNG terpasang (AC-2, AC-6)")
	var teks: String = FileAccess.get_file_as_string("res://assets/sprites/ui/ui_bengkel_sepeda.json")
	var data: Variant = JSON.parse_string(teks)
	check(data is Dictionary, "JSON titik sepeda terbaca")
	if not (data is Dictionary):
		return
	var d: Dictionary = data
	var titik: Dictionary = d["titik_kecil"]
	check(Config.BENGKEL_SEPEDA_TITIK == [int(titik["ban"][0]), int(titik["ban"][1]), int(titik["rem"][0]), int(titik["rem"][1]), int(titik["rantai"][0]), int(titik["rantai"][1])], "titik ban, rem, rantai di JSON = Config.BENGKEL_SEPEDA_TITIK (x lalu y)")
	check(Config.BENGKEL_SEPEDA_LEBAR_PX == int(d["kecil"][0]) and Config.BENGKEL_SEPEDA_TINGGI_PX == int(d["kecil"][1]) and Config.BENGKEL_SEPEDA_LEBAR_PX == 116 and Config.BENGKEL_SEPEDA_TINGGI_PX == 78, "ukuran sepeda kecil di JSON = Config = 116x78")
	check(teks == FileAccess.get_file_as_string("res://docs/design/redesain/aset/sepeda.json"), "ui_bengkel_sepeda.json = salinan byte sepeda.json di docs")
	check(Vector2i((load("res://assets/sprites/ui/ui_bengkel_sepeda_kecil.png") as Texture2D).get_size()) == Vector2i(Config.BENGKEL_SEPEDA_LEBAR_PX, Config.BENGKEL_SEPEDA_TINGGI_PX), "PNG sepeda kecil berukuran Config.BENGKEL_SEPEDA_*")
	check(Vector2i((load("res://assets/sprites/ui/ui_bengkel_papan_alat.png") as Texture2D).get_size()) == Vector2i(Config.BENGKEL_PAPAN_LEBAR_PX, Config.BENGKEL_PAPAN_TINGGI_PX) and Config.BENGKEL_PAPAN_LEBAR_PX == 360 and Config.BENGKEL_PAPAN_TINGGI_PX == 104, "PNG papan alat berukuran 360x104 = Config")
	check((load("res://assets/sprites/ui/ui_bengkel_latar_800.png") as Texture2D).get_width() == Config.BENGKEL_LATAR_LEBAR_PX, "PNG latar bengkel selebar Config.BENGKEL_LATAR_LEBAR_PX (800)")
	for id: String in Config.KONDISI_KOMPONEN:
		check(GayaHud.tekstur("icon24_" + id) != null and Vector2i(GayaHud.tekstur("icon24_" + id).get_size()) == Vector2i(Config.BENGKEL_IKON_PX, Config.BENGKEL_IKON_PX), "ikon 24 untuk %s terpasang dan berukuran 24x24" % id)
	check(Vector2i(GayaHud.tekstur("glif_seru_warn").get_size()) == Vector2i(Config.BENGKEL_GLIF_PX, Config.BENGKEL_GLIF_PX), "glif 12 berukuran Config.BENGKEL_GLIF_PX")
