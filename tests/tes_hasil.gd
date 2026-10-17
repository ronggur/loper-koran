class_name TesHasil
extends RefCounted
## Tes logika murni angka layar hasil (AC-11, O-12), syarat layar hasil terbuka (O-11), pemisah ribuan (DESIGN_SPEC 3.3), dan zona aman
## (AC-9) run fase3c-hud-hasil.
##
## Oracle independen (AC-17): angka hasil, inset, dan teks ditulis literal (dihitung tangan), bukan memanggil fungsi yang dites.

var _cek: Callable
var _judul: Callable


func _init(cek: Callable, judul: Callable) -> void:
	_cek = cek
	_judul = judul


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_test_hasil_semua_terantar()
	_test_hasil_meleset_dan_tenggat_lewat()
	_test_siap_tampil()
	_test_ribuan()
	_test_zona_aman_inset()
	_test_zona_aman_margin()


## Rute buatan dengan `n` pelanggan berid "h@<i>" dan pemberi tip "h@0", "h@1".
func _rute(n: int) -> RouteBuilder.Rute:
	var rute: RouteBuilder.Rute = RouteBuilder.Rute.new()
	for i: int in range(n):
		var r: RouteBuilder.RumahRute = RouteBuilder.RumahRute.new()
		r.id = "h@%d" % i
		r.sisi = LoperAnim.Sisi.SEBERANG
		r.pelanggan = true
		r.maju_ubin = float(i * 9)
		rute.rumah.append(r)
		rute.pelanggan.append(r)
	rute.id_pemberi_tip = {"h@0": true, "h@1": true}
	rute.panjang_ubin = 240.0
	return rute


func _test_hasil_semua_terantar() -> void:
	_judul.call("Angka hasil (AC-11): semua 25 terantar sebelum tenggat; oracle literal")
	var rute: RouteBuilder.Rute = _rute(25)
	var k: SkorRute.Keadaan = SkorRute.awal()
	# h@0 teras pemberi tip (tip 5), h@1 kotak surat tepat, sisanya kotak surat, semuanya santai beruntun.
	for i: int in range(25):
		var hasil: ZonaSasaran.Hasil = ZonaSasaran.Hasil.TERAS if i == 0 else ZonaSasaran.Hasil.KOTAK_SURAT
		k = SkorRute.nilai(k, hasil, "h@%d" % i, i == 1, 3.0, RouteBuilder.pemberi_tip(rute, "h@%d" % i), false, false).keadaan
	var tenggat: TenggatRute.Keadaan = TenggatRute.hentikan(TenggatRute.langkah(TenggatRute.awal(240.0), 80.0))
	var a: HasilRute.Angka = HasilRute.dari(k, rute, tenggat)
	# Skor: combo x1,0..x2,0 untuk 25 antaran = 100+110+...+200 (11 antaran) + 14 x 200 = 1650 + 2800 = 4450, lalu antaran ke-2 tepat:
	# 110 x 1,25 = 137,5 -> 138 (bukan 110), jadi 4450 - 110 + 138 = 4478.
	check(a.pelanggan == 25 and a.terkirim == 25 and a.meleset == 0, "terkirim 25/25, meleset 0")
	check(a.koin == 380 and a.koin_tip == 5 and a.jumlah_tip == 1, "koin 25 x 15 + 5 = 380, tip 5 dari 1 pelanggan")
	check(a.skor == 4478 and a.jumlah_tepat == 1, "skor 4478, tepat 1 (dapat %d)" % a.skor)
	check(not a.tenggat_lewat and a.detik_lewat == 0, "sampai di 80 detik dari 92: tenggat tidak lewat, detik lewat 0")


func _test_hasil_meleset_dan_tenggat_lewat() -> void:
	_judul.call("Angka hasil (AC-11): sebagian meleset dan tenggat lewat; tip sesudah tenggat hilang; oracle literal")
	var rute: RouteBuilder.Rute = _rute(25)
	var k: SkorRute.Keadaan = SkorRute.awal()
	# h@0 teras pemberi tip sebelum tenggat (+20), koran meleset (combo putus), h@1 teras pemberi tip SESUDAH tenggat (+15, tanpa tip),
	# h@2 halaman sesudah tenggat (+15, skor 50 x1,1 = 55). Lainnya tidak terantar.
	k = SkorRute.nilai(k, ZonaSasaran.Hasil.TERAS, "h@0", false, 3.0, true, false, false).keadaan
	k = SkorRute.nilai(k, ZonaSasaran.Hasil.MELESET, "", false, 3.0, false, false, false).keadaan
	k = SkorRute.nilai(k, ZonaSasaran.Hasil.TERAS, "h@1", false, 3.0, true, false, true).keadaan
	k = SkorRute.nilai(k, ZonaSasaran.Hasil.HALAMAN, "h@2", false, 3.0, false, false, true).keadaan
	var tenggat: TenggatRute.Keadaan = TenggatRute.hentikan(TenggatRute.langkah(TenggatRute.awal(240.0), 104.0))
	var a: HasilRute.Angka = HasilRute.dari(k, rute, tenggat)
	check(a.terkirim == 3 and a.meleset == 22 and a.pelanggan == 25, "terkirim 3, meleset 25 - 3 = 22")
	check(a.koin == 50 and a.koin_tip == 5 and a.jumlah_tip == 1, "koin 20 + 15 + 15 = 50, tip hanya sebelum tenggat (5, 1 pelanggan)")
	check(a.skor == 255 and a.jumlah_tepat == 0, "skor 100 + 100 + 55 = 255 (combo putus oleh meleset), tepat 0")
	check(a.tenggat_lewat and a.detik_lewat == 12, "104 detik dari 92: tenggat lewat 12 detik")
	# QA-004 iterasi 1: detik lewat pecahan dibulatkan KE ATAS, sama dengan HUD "LEWAT +m:ss" (D-1): 103,25 dari 92 = 11,25 -> 12;
	# 92,01 = 0,01 -> 1; 102,5 = 10,5 -> 11. Ke bawah atau terdekat akan memberi 11 / 0 / 10 atau 11 / 0 / 11.
	for baris: Array in [[103.25, 12], [92.01, 1], [102.5, 11]]:
		var jam: TenggatRute.Keadaan = TenggatRute.hentikan(TenggatRute.langkah(TenggatRute.awal(240.0), baris[0]))
		var hasil_pecahan: HasilRute.Angka = HasilRute.dari(k, rute, jam)
		check(hasil_pecahan.tenggat_lewat and hasil_pecahan.detik_lewat == baris[1], "jam %.2f dari 92: detik lewat di layar hasil %d (ke atas), dapat %d" % [baris[0], baris[1], hasil_pecahan.detik_lewat])
	var kosong: HasilRute.Angka = HasilRute.dari(SkorRute.awal(), null, null)
	check(kosong.pelanggan == 0 and kosong.terkirim == 0 and kosong.meleset == 0 and not kosong.tenggat_lewat, "rute dan tenggat null: semua 0, tidak lewat")
	# Id terantar yang bukan pelanggan rute ini tidak dihitung terkirim.
	var lain: SkorRute.Keadaan = SkorRute.nilai(SkorRute.awal(), ZonaSasaran.Hasil.KOTAK_SURAT, "lain@9", false, 3.0, false, false).keadaan
	check(HasilRute.dari(lain, rute, null).terkirim == 0 and HasilRute.dari(lain, rute, null).meleset == 25, "rumah terantar di luar pelanggan rute tidak dihitung: terkirim 0, meleset 25")


func _test_siap_tampil() -> void:
	_judul.call("Layar hasil terbuka sesudah garis akhir, sepeda berhenti, dan tanpa koran terbang (O-11)")
	var terbang: KoranLempar.Koran = KoranLempar.Koran.new()
	var mendarat: KoranLempar.Koran = KoranLempar.Koran.new()
	mendarat.mendarat = true
	var tanpa: Array[KoranLempar.Koran] = []
	check(HasilRute.siap_tampil(true, 0.0, tanpa), "selesai, berhenti, tanpa koran: siap")
	check(HasilRute.siap_tampil(true, 0.0, [mendarat] as Array[KoranLempar.Koran]), "koran sudah mendarat (penanda masih tampil): siap")
	check(not HasilRute.siap_tampil(true, 0.0, [mendarat, terbang] as Array[KoranLempar.Koran]), "satu koran masih terbang: belum")
	check(not HasilRute.siap_tampil(true, 0.01, tanpa), "sepeda masih bergerak 0,01 u/d: belum")
	check(not HasilRute.siap_tampil(false, 0.0, tanpa), "rute belum selesai: belum")
	check(not HasilRute.siap_tampil(true, NAN, tanpa), "kecepatan NaN: belum")


func _test_ribuan() -> void:
	_judul.call("Pemisah ribuan (DESIGN_SPEC 3.3: \"1.250\")")
	var tabel: Array = [[0, "0"], [7, "7"], [999, "999"], [1000, "1.000"], [1250, "1.250"], [12345, "12.345"], [1234567, "1.234.567"], [-1250, "-1.250"]]
	for baris: Array in tabel:
		check(HasilRute.ribuan(baris[0], ".") == baris[1], "%d -> %s (dapat %s)" % [baris[0], baris[1], HasilRute.ribuan(baris[0], ".")])


func _test_zona_aman_inset() -> void:
	_judul.call("Zona aman (AC-9): inset layar -> piksel game, inset tiruan")
	# Layar 2400x1080 (skala 3, viewport 800x360), cutout 30 px layar di tepi x 0: 30 / 3 = 10 px game.
	var a: ZonaAman.Inset = ZonaAman.inset_game(Rect2i(30, 0, 2370, 1080), Vector2i(2400, 1080), Vector2(800, 360))
	check(a.awal_x == 10 and a.atas == 0 and a.akhir_x == 0 and a.bawah == 0, "cutout 30 px di tepi x 0: inset awal_x 10, lainnya 0")
	# Cutout 31 px di tepi x lebar: 31 / 3 = 10,33 -> 11 (ke atas, cutout tidak boleh menutupi satu piksel game pun).
	var b: ZonaAman.Inset = ZonaAman.inset_game(Rect2i(0, 0, 2369, 1080), Vector2i(2400, 1080), Vector2(800, 360))
	check(b.awal_x == 0 and b.akhir_x == 11, "cutout 31 px di tepi x lebar: inset akhir_x 11")
	# Inset atas 45 px dan bawah 60 px (bilah gestur): 15 dan 20.
	var c: ZonaAman.Inset = ZonaAman.inset_game(Rect2i(0, 45, 2400, 975), Vector2i(2400, 1080), Vector2(800, 360))
	check(c.atas == 15 and c.bawah == 20 and c.awal_x == 0 and c.akhir_x == 0, "inset atas 45 dan bawah 60 px layar: 15 dan 20 px game")
	# Tepi kosong (letterbox) tiruan: layar 2412 dengan viewport 802 x skala 3 = 2406 -> 3 px kosong tiap sisi. Inset 3 px layar ada di
	# dalam tepi kosong -> 0 px game; inset 9 px layar = 6 px di dalam gambar -> 2 px game.
	var d: ZonaAman.Inset = ZonaAman.inset_game(Rect2i(3, 0, 2406, 1080), Vector2i(2412, 1080), Vector2(802, 360))
	check(d.awal_x == 0 and d.akhir_x == 0, "inset di dalam tepi kosong (3 px tiap sisi): 0 px game")
	var e: ZonaAman.Inset = ZonaAman.inset_game(Rect2i(9, 0, 2403, 1080), Vector2i(2412, 1080), Vector2(802, 360))
	check(e.awal_x == 2 and e.akhir_x == 0, "inset 9 px layar dengan tepi kosong 3: (9 - 3) / 3 = 2 px game")
	var nol: ZonaAman.Inset = ZonaAman.inset_game(Rect2i(0, 0, 2340, 1080), Vector2i(2340, 1080), Vector2(780, 360))
	check(nol.nol(), "persegi aman = layar penuh: inset nol")
	check(ZonaAman.inset_game(Rect2i(), Vector2i(2340, 1080), Vector2(780, 360)).nol() and ZonaAman.inset_game(Rect2i(0, 0, 10, 10), Vector2i.ZERO, Vector2(780, 360)).nol(), "masukan kosong: inset nol")


func _test_zona_aman_margin() -> void:
	_judul.call("Zona aman (AC-9): margin = max(margin DESIGN_SPEC, inset); geseran sama untuk satu tepi")
	check(ZonaAman.margin(4, 0) == 4 and ZonaAman.margin(4, 10) == 10 and ZonaAman.margin(28, 10) == 28 and ZonaAman.margin(8, 8) == 8, "margin: 4/0 -> 4, 4/10 -> 10, 28/10 -> 28, 8/8 -> 8")
	check(ZonaAman.geser(4, 0) == 0 and ZonaAman.geser(4, 10) == 6 and ZonaAman.geser(8, 20) == 12 and ZonaAman.geser(4, 3) == 0, "geser: 4/0 -> 0, 4/10 -> 6, 8/20 -> 12, 4/3 -> 0")
