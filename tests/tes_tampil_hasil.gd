class_name TesTampilHasil
extends RefCounted
## Tes pemilihan keadaan dan tata letak layar hasil struk, logika murni (`TampilHasil`, `GarisSobek.segmen`, `GarisTitik.letak_titik`; run ui2-semua-layar bagian A, AC-2): lebar struk dan kolom samping di 640..800,
## margin menurut inset, letak tombol aksi, batas bawah kolom, struk tanpa samping yang digeser dari tombol, kolom sejajar struk hanya bila muat, chip perubahan reputasi, glif "Terkirim", nama tekstur lencana, dan
## geometri garis sobek dan titik-titik. Oracle independen: angka kanvas Hasil.dc.html (margin 12, kolom 236 dan 300, jarak 10, struk 360, tombol 140x42 di kanan bawah dengan margin 12) ditulis literal oleh tes,
## bukan dihitung ulang dengan fungsi yang dites.

var _cek: Callable
var _judul: Callable


func _init(cek: Callable, judul: Callable) -> void:
	_cek = cek
	_judul = judul


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_test_lebar_kolom()
	_test_tata_dengan_samping()
	_test_tata_inset()
	_test_tata_tanpa_samping_dan_geser()
	_test_kolom_atas()
	_test_delta_reputasi()
	_test_glif_dan_lencana()
	_test_samping_dan_kondisi()
	_test_garis_sobek_dan_titik()


func _inset(awal: int, akhir: int, atas: int, bawah: int) -> ZonaAman.Inset:
	var i: ZonaAman.Inset = ZonaAman.Inset.new()
	i.awal_x = awal
	i.akhir_x = akhir
	i.atas = atas
	i.bawah = bawah
	return i


func _test_lebar_kolom() -> void:
	_judul.call("Hasil (murni): lebar kolom samping 236 di bawah 800 dan 300 di lebar 800 ke atas (kanvas Hasil_800, AC-2)")
	for lebar: int in [640, 667, 700, 780, 799]:
		check(TampilHasil.lebar_kolom(lebar) == 236, "lebar %d: kolom 236" % lebar)
	for lebar: int in [800, 801, 1000]:
		check(TampilHasil.lebar_kolom(lebar) == 300, "lebar %d: kolom 300" % lebar)


func _test_tata_dengan_samping() -> void:
	_judul.call("Hasil (murni): tata dengan kolom samping: struk = isi - kolom - 10, tombol 140x42 di kanan bawah dengan margin 12, batas bawah kolom 6 di atas tombol (AC-2)")
	var t: TampilHasil.Tata = TampilHasil.tata(Vector2i(640, 360), null, true)
	check(t.margin_awal == 12 and t.margin_akhir == 12 and t.margin_atas == 12 and t.margin_bawah == 12, "640 tanpa inset: margin 12 di semua tepi")
	check(t.lebar_struk == 370 and t.lebar_kolom == 236 and t.ada_samping, "640: struk 370 (640 - 24 - 236 - 10), kolom 236")
	check(t.tombol == Rect2i(488, 306, 140, 42), "640: tombol (488, 306, 140, 42) = kanan 628, bawah 348: %s" % t.tombol)
	check(t.batas_bawah_kolom == 300 and t.x_struk == 12, "640: kolom harus berakhir di y 300 (306 - 6); struk mulai x 12")
	var t8: TampilHasil.Tata = TampilHasil.tata(Vector2i(800, 360), null, true)
	check(t8.lebar_struk == 466 and t8.lebar_kolom == 300 and t8.tombol == Rect2i(648, 306, 140, 42), "800: struk 466 (800 - 24 - 300 - 10), kolom 300, tombol (648, 306)")
	var t78: TampilHasil.Tata = TampilHasil.tata(Vector2i(780, 360), null, true)
	check(t78.lebar_struk == 510 and t78.lebar_kolom == 236, "780: struk 510 (780 - 24 - 236 - 10), kolom 236")


func _test_tata_inset() -> void:
	_judul.call("Hasil (murni): margin = max(12, inset aman); tombol dan batas kolom mengikuti inset bawah dan akhir (AC-2, inset aman)")
	var t: TampilHasil.Tata = TampilHasil.tata(Vector2i(640, 360), _inset(36, 24, 16, 20), true)
	check(t.margin_awal == 36 and t.margin_akhir == 24 and t.margin_atas == 16 and t.margin_bawah == 20, "inset 36/24/16/20: margin sama dengan inset")
	check(t.lebar_struk == 334 and t.tombol == Rect2i(476, 298, 140, 42) and t.batas_bawah_kolom == 292 and t.x_struk == 36, "inset: struk 334 (640 - 60 - 236 - 10), tombol (476, 298), batas kolom 292, struk x 36")
	var kecil: TampilHasil.Tata = TampilHasil.tata(Vector2i(640, 360), _inset(5, 3, 8, 11), true)
	check(kecil.margin_awal == 12 and kecil.margin_akhir == 12 and kecil.margin_atas == 12 and kecil.margin_bawah == 12, "inset di bawah 12: margin tetap 12")
	var batas: TampilHasil.Tata = TampilHasil.tata(Vector2i(640, 360), _inset(12, 12, 12, 13), true)
	check(batas.margin_bawah == 13 and batas.margin_atas == 12 and batas.tombol.position.y == 305, "inset 13 persis: margin 13 (tepat di atas batas), tombol y 305")


func _test_tata_tanpa_samping_dan_geser() -> void:
	_judul.call("Hasil (murni): tanpa kolom samping struk 360 ke tengah; struk yang cukup tinggi sampai baris tombol digeser ke kiri supaya tidak menutupi tombol (AC-2, tanpa data reputasi)")
	var rendah: TampilHasil.Tata = TampilHasil.tata(Vector2i(640, 360), null, false, 200)
	check(rendah.lebar_struk == 360 and rendah.lebar_kolom == 0 and not rendah.ada_samping and rendah.x_struk == 140, "640, struk 200 tinggi: lebar 360, tengah x 140 ((640 - 360) / 2)")
	var persis: TampilHasil.Tata = TampilHasil.tata(Vector2i(640, 360), null, false, 256)
	check(persis.x_struk == 140, "struk 256: bawah 12 + 32 + 256 = 300 tepat di batas, belum digeser")
	var lewat: TampilHasil.Tata = TampilHasil.tata(Vector2i(640, 360), null, false, 257)
	check(lewat.x_struk == 122, "struk 257: bawah 301 melewati batas, digeser ke kiri: x 122 (tombol 488 - 6 - 360)")
	var lebar: TampilHasil.Tata = TampilHasil.tata(Vector2i(800, 360), null, false, 290)
	check(lebar.x_struk == 220, "800, struk 290: tengah x 220 ((800 - 360) / 2) sudah tidak menutupi tombol (x 648), tidak digeser")
	var sempit: TampilHasil.Tata = TampilHasil.tata(Vector2i(400, 360), null, false, 290)
	check(sempit.lebar_struk == 360 and sempit.x_struk >= 12, "viewport sempit 400: struk 360 tidak digeser ke luar margin awal (x %d)" % sempit.x_struk)
	var kecil: TampilHasil.Tata = TampilHasil.tata(Vector2i(300, 360), null, false, 100)
	check(kecil.lebar_struk == 276, "viewport 300: struk dibatasi lebar isi 276 (300 - 24)")


func _test_kolom_atas() -> void:
	_judul.call("Hasil (murni): kolom samping sejajar struk (32 di bawah margin atas) hanya bila muat di atas tombol; selain itu sejajar judul (AC-2)")
	check(TampilHasil.tata(Vector2i(640, 360), null, true, 190, 150).kolom_atas == 32, "kolom 150 tinggi: sejajar struk (32)")
	check(TampilHasil.tata(Vector2i(640, 360), null, true, 190, 255).kolom_atas == 32, "kolom 255: 255 + 32 = 287 <= 288 muat")
	check(TampilHasil.tata(Vector2i(640, 360), null, true, 190, 256).kolom_atas == 32, "kolom 256: 256 + 32 = 288 tepat muat")
	check(TampilHasil.tata(Vector2i(640, 360), null, true, 190, 257).kolom_atas == 0, "kolom 257: 289 > 288, sejajar judul")
	check(TampilHasil.tata(Vector2i(640, 360), null, true, 290, 275).kolom_atas == 0, "kolom terpadat 275: sejajar judul")
	check(TampilHasil.tata(Vector2i(640, 360), _inset(36, 24, 16, 20), true, 190, 245).kolom_atas == 0, "inset atas 16 dan bawah 20: tersedia 292 - 16 = 276, kolom 245 + 32 = 277 tidak muat")
	check(TampilHasil.tata(Vector2i(640, 360), _inset(36, 24, 16, 20), true, 190, 244).kolom_atas == 32, "inset: kolom 244 + 32 = 276 tepat muat")
	check(TampilHasil.tata(Vector2i(640, 360), null, true).kolom_atas == 32, "tinggi kolom belum diketahui (0): sejajar struk")


func _test_delta_reputasi() -> void:
	_judul.call("Hasil (murni): chip perubahan reputasi: naik = OK dengan glif naik, turun = netral dengan glif turun, nol = netral tanpa glif; tanda eksplisit (AC-2, prinsip 2: turun bukan merah)")
	var naik: TampilHasil.InfoDelta = TampilHasil.delta_reputasi(2)
	check(naik.gaya == KomponenUi.GayaChip.OK and naik.glif == "glif_naik_ok" and naik.teks == "+2", "naik 2: OK, glif naik, '+2'")
	var turun: TampilHasil.InfoDelta = TampilHasil.delta_reputasi(-1)
	check(turun.gaya == KomponenUi.GayaChip.NETRAL and turun.glif == "glif_turun_teks2" and turun.teks == "-1", "turun 1: netral (bukan WARN atau merah), glif turun, '-1'")
	var nol: TampilHasil.InfoDelta = TampilHasil.delta_reputasi(0)
	check(nol.gaya == KomponenUi.GayaChip.NETRAL and nol.glif == "" and nol.teks == "+0", "nol: netral tanpa glif, '+0'")
	check(TampilHasil.delta_reputasi(100).teks == "+100" and TampilHasil.delta_reputasi(-45).teks == "-45", "angka besar: '+100' dan '-45'")
	for p: int in [-3, -1, 0, 1, 7]:
		var info: TampilHasil.InfoDelta = TampilHasil.delta_reputasi(p)
		check(info.teks != "" and (info.glif != "" or p == 0), "perubahan %d: terbaca tanpa warna (teks bertanda%s)" % [p, " dan glif" if p != 0 else ""])
	for nama: String in ["glif_naik_ok", "glif_turun_teks2"]:
		check(GayaHud.tekstur(nama) != null and GayaHud.tekstur(nama).get_width() == 12, "%s terpasang 12x12" % nama)


func _test_glif_dan_lencana() -> void:
	_judul.call("Hasil (murni): glif Terkirim hijau hanya bila SEMUA pelanggan terantar; nama tekstur lencana 32 dan 24 menurut tingkat, dijepit (AC-2)")
	check(TampilHasil.glif_terkirim(25, 25) == "glif_centang_ok" and TampilHasil.glif_terkirim(26, 25) == "glif_centang_ok", "semua terantar: centang hijau")
	check(TampilHasil.glif_terkirim(24, 25) == "glif_centang_teks2" and TampilHasil.glif_terkirim(0, 25) == "glif_centang_teks2", "sebagian atau tak satu pun: centang abu-abu")
	check(TampilHasil.glif_terkirim(0, 0) == "glif_centang_teks2", "tanpa pelanggan: tidak dianggap semua terantar")
	check(TampilHasil.tekstur_lencana32(0) == "lencana32_perunggu" and TampilHasil.tekstur_lencana32(1) == "lencana32_perak" and TampilHasil.tekstur_lencana32(2) == "lencana32_emas", "lencana 32: indeks 0, 1, 2 = perunggu, perak, emas")
	check(TampilHasil.tekstur_lencana32(-1) == "lencana32_perunggu" and TampilHasil.tekstur_lencana32(9) == "lencana32_emas", "lencana 32 dijepit ke 0..2")
	check(TampilHasil.tekstur_lencana24(1) == "icon24_lencana_perunggu" and TampilHasil.tekstur_lencana24(2) == "icon24_lencana_perak" and TampilHasil.tekstur_lencana24(3) == "icon24_lencana_emas", "lencana 24: tingkat 1, 2, 3 = perunggu, perak, emas")
	check(TampilHasil.tekstur_lencana24(0) == "icon24_lencana_perunggu" and TampilHasil.tekstur_lencana24(9) == "icon24_lencana_emas", "lencana 24 dijepit ke 1..3")
	for nama: String in ["lencana32_perunggu", "lencana32_perak", "lencana32_emas"]:
		check(GayaHud.tekstur(nama) != null and GayaHud.tekstur(nama).get_size() == Vector2(32, 32), "%s terpasang 32x32" % nama)
	for nama: String in ["icon24_lencana_perunggu", "icon24_lencana_perak", "icon24_lencana_emas", "icon24_koin", "icon24_bintang"]:
		check(GayaHud.tekstur(nama) != null and GayaHud.tekstur(nama).get_size() == Vector2(24, 24), "%s terpasang 24x24" % nama)
	check(GayaHud.tekstur("struk").get_size() == Vector2(12, 12) and GayaHud.tekstur("struk_takik").get_size() == Vector2(6, 10), "struk 12x12 dan takik 6x10 terpasang (= meta.json)")


func _test_samping_dan_kondisi() -> void:
	_judul.call("Hasil (murni): kolom samping ada bila ada reputasi atau milestone; baris kondisi paling banyak tiga; kunci nama milestone dan tingkat (AC-2)")
	check(TampilHasil.ada_samping(true, true) and TampilHasil.ada_samping(true, false) and TampilHasil.ada_samping(false, true) and not TampilHasil.ada_samping(false, false), "ada_samping = reputasi atau milestone")
	check(TampilHasil.jumlah_baris_kondisi(0) == 0 and TampilHasil.jumlah_baris_kondisi(2) == 2 and TampilHasil.jumlah_baris_kondisi(3) == 3 and TampilHasil.jumlah_baris_kondisi(7) == 3 and TampilHasil.jumlah_baris_kondisi(-1) == 0, "baris kondisi 0, 2, 3, dijepit 3, tidak negatif")
	check(TampilHasil.kunci_nama_milestone("koin_total") == "HASIL_MILESTONE_NAMA_KOIN_TOTAL" and TampilHasil.kunci_tingkat(2) == "HASIL_MILESTONE_TINGKAT_PERAK", "kunci nama milestone dan tingkat")
	check(LayarHasil.kunci_nama_milestone("sepeda") == "HASIL_MILESTONE_NAMA_SEPEDA" and LayarHasil.kunci_tingkat(3) == "HASIL_MILESTONE_TINGKAT_EMAS", "LayarHasil meneruskan ke TampilHasil (API lama tetap)")


func _test_garis_sobek_dan_titik() -> void:
	_judul.call("Hasil (murni): garis sobek putus-putus (goresan 3, celah 3, goresan terakhir dipotong) dan garis titik-titik tiap 2 px (AC-2, kanvas .sobek dan dotted)")
	var dua: Array[Vector2i] = [Vector2i(0, 3), Vector2i(6, 3)]
	check(GarisSobek.segmen(0, 12, 3) == dua, "0..12: dua goresan (0,3) dan (6,3)")
	var dipotong: Array[Vector2i] = [Vector2i(0, 3), Vector2i(6, 2)]
	check(GarisSobek.segmen(0, 8, 3) == dipotong, "0..8: goresan terakhir dipotong di batas (6,2)")
	check(GarisSobek.segmen(10, 10, 3).is_empty() and GarisSobek.segmen(10, 5, 3).is_empty() and GarisSobek.segmen(0, 10, 0).is_empty(), "rentang kosong, terbalik, atau goresan 0: tidak ada segmen")
	var negatif: Array[Vector2i] = [Vector2i(-4, 3), Vector2i(2, 2)]
	check(GarisSobek.segmen(-4, 4, 3) == negatif, "awal negatif (garis dimulai di luar isi): -4..4 = (-4,3) dan (2,2)")
	var titik7: Array[int] = [0, 2, 4, 6]
	var titik1: Array[int] = [0]
	check(GarisTitik.letak_titik(7, 2) == titik7 and GarisTitik.letak_titik(1, 2) == titik1, "titik tiap 2 px dari 0: lebar 7 -> 0, 2, 4, 6; lebar 1 -> 0")
	check(GarisTitik.letak_titik(0, 2).is_empty() and GarisTitik.letak_titik(5, 0).is_empty() and GarisTitik.letak_titik(-3, 2).is_empty(), "lebar atau jarak tidak positif: tidak ada titik")
