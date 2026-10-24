class_name TesTampilKoran
extends RefCounted
## Tes pemilihan keadaan dan tata letak halaman koran, logika murni (`TampilKoran`, `KotakIklan.goresan`, `GarisHiasan`; run ui2-semua-layar bagian B, AC-3): lebar kolom misi 236 dan 280, margin menurut inset,
## letak garis tegak dan Berangkat, peran dan tekstur dan warna dan geseran isi tombol (tinta, tipis, terpilih), glif centang, foto dan ikon per efek, pembagian ruang hiasan dan iklan, batang hiasan, garis ganda,
## dan goresan garis putus kotak iklan. Oracle independen: angka kanvas Koran.dc.html (margin 12, kolom misi 236 dan 280, jarak 6 + garis 1 + 6, Berangkat 140x42, foto 100x62, iklan 220x54, garis ganda 2 + 1 + 1,
## batang hiasan 2 px berjarak 3 dan 10) ditulis literal oleh tes, bukan dihitung ulang dengan fungsi yang dites.

var _cek: Callable
var _judul: Callable


func _init(cek: Callable, judul: Callable) -> void:
	_cek = cek
	_judul = judul


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_test_lebar_misi()
	_test_tata()
	_test_tata_inset()
	_test_peran_dan_tekstur()
	_test_warna_dan_geseran()
	_test_glif()
	_test_foto_dan_ikon()
	_test_iklan_dan_ruang()
	_test_hiasan_dan_garis()
	_test_goresan_iklan()


func _inset(awal: int, akhir: int, atas: int, bawah: int) -> ZonaAman.Inset:
	var i: ZonaAman.Inset = ZonaAman.Inset.new()
	i.awal_x = awal
	i.akhir_x = akhir
	i.atas = atas
	i.bawah = bawah
	return i


func _test_lebar_misi() -> void:
	_judul.call("Koran (murni): lebar kolom misi 236 di bawah 800 dan 280 di lebar 800 ke atas (kanvas Koran_800, AC-3)")
	for lebar: int in [640, 667, 700, 780, 799]:
		check(TampilKoran.lebar_misi(lebar) == 236, "lebar %d: kolom misi 236" % lebar)
	for lebar: int in [800, 801, 1000]:
		check(TampilKoran.lebar_misi(lebar) == 280, "lebar %d: kolom misi 280" % lebar)


func _test_tata() -> void:
	_judul.call("Koran (murni): tata kolom berita | 6 + garis 1 + 6 | misi, Berangkat 140x42 kanan bawah margin 12 (AC-3)")
	var t: TampilKoran.Tata = TampilKoran.tata(Vector2i(640, 360), null)
	check(t.margin_awal == 12 and t.margin_akhir == 12 and t.margin_atas == 12 and t.margin_bawah == 12, "640 tanpa inset: margin 12 di semua tepi")
	check(t.lebar_isi == 616 and t.lebar_misi == 236 and t.lebar_berita == 367, "640: isi 616, misi 236, berita 367 (616 - 236 - 13)")
	check(t.x_garis == 385 and t.x_misi == 392, "640: garis tegak x 385 (12 + 367 + 6), kolom misi x 392 (385 + 1 + 6)")
	check(t.berangkat == Rect2i(488, 306, 140, 42), "640: Berangkat (488, 306, 140, 42): kanan 628, bawah 348: %s" % t.berangkat)
	check(t.x_misi + t.lebar_misi == 628, "640: kolom misi berakhir di tepi kanan isi (628)")
	var t8: TampilKoran.Tata = TampilKoran.tata(Vector2i(800, 360), null)
	check(t8.lebar_isi == 776 and t8.lebar_misi == 280 and t8.lebar_berita == 483, "800: isi 776, misi 280, berita 483 (776 - 280 - 13)")
	check(t8.x_garis == 501 and t8.x_misi == 508 and t8.berangkat == Rect2i(648, 306, 140, 42), "800: garis x 501 (12 + 483 + 6), misi x 508, Berangkat (648, 306)")
	var t78: TampilKoran.Tata = TampilKoran.tata(Vector2i(780, 360), null)
	check(t78.lebar_misi == 236 and t78.lebar_berita == 507, "780: misi 236, berita 507 (756 - 236 - 13)")


func _test_tata_inset() -> void:
	_judul.call("Koran (murni): margin = max(12, inset aman) per tepi, inset kecil tidak mengecilkan margin (AC-3, kanvas Koran_inset)")
	var t: TampilKoran.Tata = TampilKoran.tata(Vector2i(640, 360), _inset(36, 24, 16, 20))
	check(t.margin_awal == 36 and t.margin_akhir == 24 and t.margin_atas == 16 and t.margin_bawah == 20, "inset (36, 24, 16, 20): margin mengikuti inset")
	check(t.lebar_isi == 580 and t.lebar_berita == 331 and t.x_garis == 373, "inset: isi 580, berita 331, garis x 373 (36 + 331 + 6)")
	check(t.berangkat == Rect2i(476, 298, 140, 42), "inset: Berangkat (476, 298): kanan 616, bawah 340: %s" % t.berangkat)
	var kecil: TampilKoran.Tata = TampilKoran.tata(Vector2i(640, 360), _inset(5, 8, 0, 11))
	check(kecil.margin_awal == 12 and kecil.margin_akhir == 12 and kecil.margin_atas == 12 and kecil.margin_bawah == 12, "inset di bawah 12: margin tetap 12")
	var batas: TampilKoran.Tata = TampilKoran.tata(Vector2i(640, 360), _inset(12, 12, 12, 13))
	check(batas.margin_awal == 12 and batas.margin_bawah == 13, "inset 12 tepat: 12; inset 13: 13")


func _test_peran_dan_tekstur() -> void:
	_judul.call("Koran (murni): peran tombol pilihan dan nama tekstur bingkai (AC-3: tinta, tipis, terpilih berongga)")
	check(TampilKoran.peran_pilih(true) == TampilKoran.PeranTombol.TERPILIH and TampilKoran.peran_pilih(false) == TampilKoran.PeranTombol.TIPIS, "terpilih = TERPILIH, tidak = TIPIS")
	check(TampilKoran.nama_tekstur_tombol(TampilKoran.PeranTombol.TINTA, false) == "koran_btn_tinta", "TINTA normal = koran_btn_tinta")
	check(TampilKoran.nama_tekstur_tombol(TampilKoran.PeranTombol.TINTA, true) == "koran_btn_tinta_tekan", "TINTA ditekan = koran_btn_tinta_tekan")
	check(TampilKoran.nama_tekstur_tombol(TampilKoran.PeranTombol.TIPIS, false) == "koran_btn_tipis", "TIPIS normal = koran_btn_tipis")
	check(TampilKoran.nama_tekstur_tombol(TampilKoran.PeranTombol.TIPIS, true) == "koran_btn_terpilih", "TIPIS ditekan = bingkai terpilih (menekan memilih)")
	check(TampilKoran.nama_tekstur_tombol(TampilKoran.PeranTombol.TERPILIH, false) == "koran_btn_terpilih", "TERPILIH normal = koran_btn_terpilih")
	check(TampilKoran.nama_tekstur_tombol(TampilKoran.PeranTombol.TERPILIH, true) == "koran_btn_terpilih", "TERPILIH ditekan = koran_btn_terpilih (tidak berubah)")
	var nama: Array[String] = []
	for peran: TampilKoran.PeranTombol in [TampilKoran.PeranTombol.TINTA, TampilKoran.PeranTombol.TIPIS, TampilKoran.PeranTombol.TERPILIH]:
		var n: String = TampilKoran.nama_tekstur_tombol(peran, false)
		check(GayaHud.tekstur(n) != null, "tekstur %s terpasang di GayaHud" % n)
		nama.append(n)
	check(nama[0] != nama[1] and nama[1] != nama[2] and nama[0] != nama[2], "tiga peran punya tiga bingkai berbeda (bentuk, bukan hanya warna)")


func _test_warna_dan_geseran() -> void:
	_judul.call("Koran (murni): warna teks tombol dari token dan geseran isi tombol tinta 2 px (kanvas .k-tinta, .k-tipis, .k-pilih)")
	check(TampilKoran.warna_teks_tombol(TampilKoran.PeranTombol.TINTA, false) == Palette.KORAN_KERTAS and TampilKoran.warna_teks_tombol(TampilKoran.PeranTombol.TINTA, true) == Palette.KORAN_KERTAS, "TINTA: teks KORAN_KERTAS normal dan ditekan")
	check(TampilKoran.warna_teks_tombol(TampilKoran.PeranTombol.TIPIS, false) == Palette.KORAN_TINTA_2, "TIPIS normal: teks KORAN_TINTA_2")
	check(TampilKoran.warna_teks_tombol(TampilKoran.PeranTombol.TIPIS, true) == Palette.KORAN_TINTA, "TIPIS ditekan: teks KORAN_TINTA (bingkai berganti terpilih)")
	check(TampilKoran.warna_teks_tombol(TampilKoran.PeranTombol.TERPILIH, false) == Palette.KORAN_TINTA and TampilKoran.warna_teks_tombol(TampilKoran.PeranTombol.TERPILIH, true) == Palette.KORAN_TINTA, "TERPILIH: teks KORAN_TINTA")
	check(TampilKoran.margin_isi_tombol(TampilKoran.PeranTombol.TINTA, false) == Vector2i(0, 2), "TINTA normal: teks naik (bawah +2)")
	check(TampilKoran.margin_isi_tombol(TampilKoran.PeranTombol.TINTA, true) == Vector2i(2, 0), "TINTA ditekan: teks turun 2 px (atas +2)")
	for peran: TampilKoran.PeranTombol in [TampilKoran.PeranTombol.TIPIS, TampilKoran.PeranTombol.TERPILIH]:
		check(TampilKoran.margin_isi_tombol(peran, false) == Vector2i.ZERO and TampilKoran.margin_isi_tombol(peran, true) == Vector2i.ZERO, "pilihan rata tanpa bibir: tidak ada geseran isi")


func _test_glif() -> void:
	_judul.call("Koran (murni): glif tombol: centang gelap hanya pada pilihan terpilih, panah terang pada Berangkat (AC-3, terbaca tanpa warna)")
	check(TampilKoran.glif_pilih(true) == "glif_centang_gelap" and TampilKoran.glif_pilih(false) == "", "centang hanya bila terpilih")
	check(TampilKoran.glif_berangkat() == "glif_panah_terang", "Berangkat: panah terang")
	for nama: String in ["glif_centang_gelap", "glif_panah_terang", "glif_seru_tinta2"]:
		check(GayaHud.tekstur(nama) != null and GayaHud.tekstur(nama).get_size() == Vector2(12, 12), "%s terpasang 12x12" % nama)


func _test_foto_dan_ikon() -> void:
	_judul.call("Koran (murni): foto dan ikon berita utama menurut efek dunia; baru jalan diperbaiki dan mati lampu yang punya (Spesifikasi.dc.html)")
	check(TampilKoran.foto_untuk_efek("jalan_diperbaiki") == "foto_jalan" and TampilKoran.ikon_untuk_efek("jalan_diperbaiki") == "icon24_kerucut", "jalan diperbaiki: foto jalan, ikon kerucut")
	check(TampilKoran.foto_untuk_efek("mati_lampu") == "foto_lampu" and TampilKoran.ikon_untuk_efek("mati_lampu") == "icon24_bohlam", "mati lampu: foto lampu, ikon bohlam")
	for efek: String in ["hajatan", "hujan_deras", "air_pasang", "tujuh_belasan", "pasar_kaget", "panen_raya", "", "tidak_dikenal"]:
		check(TampilKoran.foto_untuk_efek(efek) == "" and TampilKoran.ikon_untuk_efek(efek) == "", "efek '%s': tanpa foto dan tanpa ikon" % efek)
	check(Config.EFEK_DUNIA_DIKENAL.has("jalan_diperbaiki") and Config.EFEK_DUNIA_DIKENAL.has("mati_lampu"), "kedua efek berfoto adalah efek dunia yang dikenal")
	for nama: String in ["foto_jalan", "foto_lampu"]:
		check(GayaHud.tekstur(nama) != null and GayaHud.tekstur(nama).get_size() == Vector2(100, 62), "%s terpasang 100x62" % nama)
		check(GayaHud.tekstur(nama).get_size() == Vector2(float(Config.KORAN_FOTO_LEBAR_PX), float(Config.KORAN_FOTO_TINGGI_PX)), "%s: ukuran PNG = Config.KORAN_FOTO_LEBAR_PX x KORAN_FOTO_TINGGI_PX" % nama)
	for nama: String in ["icon24_kerucut", "icon24_bohlam", "icon24_kucing"]:
		check(GayaHud.tekstur(nama) != null and GayaHud.tekstur(nama).get_size() == Vector2(24, 24), "%s terpasang 24x24" % nama)


func _test_iklan_dan_ruang() -> void:
	_judul.call("Koran (murni): kotak iklan 220x54 di kiri bawah ruang sisa, hanya bila muat; hiasan didahulukan, iklan dikorbankan lebih dulu (AC-3)")
	check(TampilKoran.iklan(Vector2i(367, 200)) == Rect2i(0, 146, 220, 54), "ruang 367x200: iklan 220x54 di dasar (y 146)")
	check(TampilKoran.iklan(Vector2i(180, 100)) == Rect2i(0, 46, 180, 54), "ruang lebih sempit dari 220: lebar mengikuti ruang (180)")
	check(TampilKoran.iklan(Vector2i(367, 40)) == Rect2i(0, 0, 220, 40), "ruang 40 tinggi: iklan memakai seluruh tinggi (40)")
	check(TampilKoran.iklan(Vector2i(367, 28)) == Rect2i(0, 0, 220, 28), "ruang 28 tepat (minimum): iklan tampil")
	check(TampilKoran.iklan(Vector2i(367, 27)).size.y == 0, "ruang 27: iklan tidak tampil")
	check(TampilKoran.iklan(Vector2i(0, 100)).size.y == 0 and TampilKoran.iklan(Vector2i(-5, 100)).size.y == 0, "lebar nol atau negatif: iklan tidak tampil")
	var luas: TampilKoran.Ruang = TampilKoran.ruang(Vector2i(367, 200))
	check(luas.hiasan_baris == 3 and luas.hiasan == Rect2i(0, 0, 367, 12), "ruang 367x200: tiga baris hiasan (tinggi 12) di atas")
	check(luas.iklan == Rect2i(0, 146, 220, 54), "ruang 200: iklan tetap 220x54 di dasar, di bawah hiasan (146 >= 12 + 6)")
	var sedang: TampilKoran.Ruang = TampilKoran.ruang(Vector2i(367, 60))
	check(sedang.hiasan_baris == 3 and sedang.iklan == Rect2i(0, 18, 220, 42), "ruang 60: hiasan 12 + jarak 6, iklan mengisi sisa 42 (y 18)")
	var pas: TampilKoran.Ruang = TampilKoran.ruang(Vector2i(367, 46))
	check(pas.hiasan_baris == 3 and pas.iklan == Rect2i(0, 18, 220, 28), "ruang 46: sisa 28 tepat, iklan tampil")
	var kurang: TampilKoran.Ruang = TampilKoran.ruang(Vector2i(367, 45))
	check(kurang.hiasan_baris == 3 and kurang.iklan.size.y == 0, "ruang 45: sisa 27, iklan tidak tampil, hiasan tetap")
	var sempit: TampilKoran.Ruang = TampilKoran.ruang(Vector2i(367, 7))
	check(sempit.hiasan_baris == 2 and sempit.hiasan == Rect2i(0, 0, 367, 7) and sempit.iklan.size.y == 0, "ruang 7: dua baris hiasan (2 + 3 + 2), tanpa iklan")
	var satu: TampilKoran.Ruang = TampilKoran.ruang(Vector2i(367, 2))
	check(satu.hiasan_baris == 1 and satu.hiasan == Rect2i(0, 0, 367, 2), "ruang 2: satu baris hiasan")
	var nol: TampilKoran.Ruang = TampilKoran.ruang(Vector2i(367, 1))
	check(nol.hiasan_baris == 0 and nol.hiasan.size.y == 0 and nol.iklan.size.y == 0, "ruang 1: tidak ada apa-apa")
	var negatif: TampilKoran.Ruang = TampilKoran.ruang(Vector2i(367, -4))
	check(negatif.hiasan_baris == 0 and negatif.iklan.size.y == 0, "ruang negatif: tidak ada apa-apa, tanpa galat")


func _test_hiasan_dan_garis() -> void:
	_judul.call("Koran (murni): batang hiasan dua kolom 2 px berjarak 3 dan 10 dengan pola lebar 100 100 100 80 60 100 persen, dan garis ganda 2 + 1 + 1 (kanvas)")
	var batang: Array[Rect2i] = TampilKoran.batang_hiasan(367, 3)
	check(batang.size() == 6, "tiga baris dua kolom = enam batang: %d" % batang.size())
	if batang.size() == 6:
		check(batang[0] == Rect2i(0, 0, 178, 2) and batang[1] == Rect2i(188, 0, 178, 2), "baris 1: dua batang penuh (kolom 178 = (367 - 10) / 2): %s %s" % [batang[0], batang[1]])
		check(batang[2] == Rect2i(0, 5, 178, 2) and batang[3] == Rect2i(188, 5, 142, 2), "baris 2: kiri penuh, kanan 80 persen (142), y 5 (2 + 3): %s %s" % [batang[2], batang[3]])
		check(batang[4] == Rect2i(0, 10, 107, 2) and batang[5] == Rect2i(188, 10, 178, 2), "baris 3: kiri 60 persen (107), kanan penuh, y 10: %s %s" % [batang[4], batang[5]])
	check(TampilKoran.batang_hiasan(367, 1).size() == 2 and TampilKoran.batang_hiasan(367, 2).size() == 4, "baris maksimum membatasi jumlah batang (1 baris = 2, 2 baris = 4)")
	check(TampilKoran.batang_hiasan(367, 9).size() == 6, "lebih banyak baris dari pola: paling banyak enam batang")
	check(TampilKoran.batang_hiasan(367, 0).is_empty() and TampilKoran.batang_hiasan(10, 3).is_empty() and TampilKoran.batang_hiasan(0, 3).is_empty(), "nol baris, lebar kurang dari jarak kolom, atau lebar nol: kosong")
	check(TampilKoran.baris_hiasan_muat(0) == 0 and TampilKoran.baris_hiasan_muat(1) == 0 and TampilKoran.baris_hiasan_muat(2) == 1 and TampilKoran.baris_hiasan_muat(6) == 1, "baris muat: tinggi 0, 1 = 0; 2 sampai 6 = 1")
	check(TampilKoran.baris_hiasan_muat(7) == 2 and TampilKoran.baris_hiasan_muat(11) == 2 and TampilKoran.baris_hiasan_muat(12) == 3, "baris muat: tinggi 7 = 2, 11 = 2, 12 = 3")
	check(TampilKoran.tinggi_hiasan(0) == 0 and TampilKoran.tinggi_hiasan(1) == 2 and TampilKoran.tinggi_hiasan(2) == 7 and TampilKoran.tinggi_hiasan(3) == 12, "tinggi hiasan 0, 2, 7, 12 untuk 0 sampai 3 baris")
	var ganda: Array[Rect2i] = TampilKoran.garis_ganda(616)
	check(ganda.size() == 2 and ganda[0] == Rect2i(0, 0, 616, 2) and ganda[1] == Rect2i(0, 3, 616, 1), "garis ganda: 2 px di y 0, celah 1, 1 px di y 3: %s" % [ganda])
	check(TampilKoran.tinggi_garis_ganda() == 4, "tinggi garis ganda 4")


func _test_goresan_iklan() -> void:
	_judul.call("Koran (murni): goresan garis putus kotak iklan 1 px, goresan 3 celah 3 pada empat sisi")
	var g: Array[Rect2i] = KotakIklan.goresan(Vector2i(20, 12))
	var mendatar: Array[Rect2i] = []
	var tegak: Array[Rect2i] = []
	for r: Rect2i in g:
		if r.size.y == 1:
			mendatar.append(r)
		if r.size.x == 1:
			tegak.append(r)
	check(mendatar.size() == 8 and tegak.size() == 4, "lebar 20 tinggi 12: empat goresan atas dan empat bawah (mendatar %d), dua goresan tegak di kiri dan dua di kanan (%d)" % [mendatar.size(), tegak.size()])
	check(mendatar.has(Rect2i(0, 0, 3, 1)) and mendatar.has(Rect2i(6, 0, 3, 1)) and mendatar.has(Rect2i(18, 0, 2, 1)), "sisi atas: goresan 3 di x 0, 6, ... dan goresan terakhir dipotong di lebar (18, panjang 2)")
	check(mendatar.has(Rect2i(0, 11, 3, 1)) and mendatar.has(Rect2i(18, 11, 2, 1)), "sisi bawah di y 11 (tinggi - 1)")
	check(tegak.has(Rect2i(0, 0, 1, 3)) and tegak.has(Rect2i(0, 6, 1, 3)) and tegak.has(Rect2i(19, 0, 1, 3)) and tegak.has(Rect2i(19, 6, 1, 3)), "sisi kiri (x 0) dan kanan (x 19): goresan tegak 3 di y 0 dan 6")
	check(KotakIklan.goresan(Vector2i(0, 0)).is_empty(), "kotak kosong: tanpa goresan")
