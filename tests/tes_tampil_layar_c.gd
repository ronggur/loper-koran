class_name TesTampilLayarC
extends RefCounted
## Tes pemilihan tampilan layar jeda, tutorial, dan HUD rute, logika murni (`TampilJeda`, `TampilTutorial`, `TampilHud`; run ui2-semua-layar bagian C, AC-4 sampai AC-6): lapisan 72 %, kunci teks dan bingkai sakelar,
## pola kenop 22x12 (mati dan nyala berbeda bentuk, bukan hanya warna), titik langkah tutorial, glif per langkah, warna stamina di ambang 30, tanda 80 % bar kecepatan, margin dan urutan panel bawah (kidal dicerminkan),
## bingkai dan glif tombol jeda HUD, dan isi baris 2 kolom kanan atas (reputasi berbagi panel kondisi). Oracle independen: angka kanvas (kenop `.sak`, margin 196 dan 8, glif 12 di wajah 24, titik 4 jarak 2) ditulis literal.

var _cek: Callable
var _judul: Callable


func _init(cek: Callable, judul: Callable) -> void:
	_cek = cek
	_judul = judul


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func _b(isi: Array) -> Array[bool]:
	var hasil: Array[bool] = []
	for nilai: Variant in isi:
		hasil.append(bool(nilai))
	return hasil


func jalankan() -> void:
	_test_lapisan_dan_kunci()
	_test_kenop()
	_test_titik_dan_glif_tutorial()
	_test_stamina_dan_tanda()
	_test_panel_bawah()
	_test_tombol_jeda_hud()
	_test_baris2()


func _test_lapisan_dan_kunci() -> void:
	_judul.call("Layar jeda murni: lapisan 72 %, kunci teks dan bingkai sakelar menurut keadaan, glif")
	var l: Color = TampilJeda.warna_lapisan()
	check(is_equal_approx(l.a, 0.72) and Color(l, 1.0) == Color(Palette.HUD_PANEL, 1.0), "lapisan jeda = warna HUD_PANEL dengan alpha 0,72 (V-2)")
	check(is_equal_approx(Palette.HUD_PANEL.a, 0.84), "token HUD_PANEL tetap alpha 0,84 (tidak diubah)")
	check(TampilJeda.kunci_teks_kidal(false) == "JEDA_KIDAL_MATI" and TampilJeda.kunci_teks_kidal(true) == "JEDA_KIDAL_NYALA", "kunci teks kidal mati dan nyala")
	check(TampilJeda.kunci_teks_bantu(false) == "HUD_BANTU_MATI" and TampilJeda.kunci_teks_bantu(true) == "HUD_BANTU_NYALA", "kunci teks bantu mati dan nyala")
	check(TampilJeda.nama_bingkai_sakelar(false) == "btn_biasa" and TampilJeda.nama_bingkai_sakelar(true) == "btn_sakelar_nyala", "bingkai sakelar mati = tombol biasa, nyala = bingkai ACCENT")
	check(TampilJeda.nama_glif_judul() == "glif_jeda_terang" and TampilJeda.nama_glif_lanjut() == "glif_lanjut_gelap", "glif judul jeda terang dan Lanjut gelap")
	check(Config.JEDA_PANEL_LEBAR_PX == 232 and Config.JEDA_KENOP_LEBAR_PX == 22 and Config.JEDA_KENOP_TINGGI_PX == 12, "panel 232 lebar, kenop 22x12 (kanvas Jeda.dc.html)")


func _test_kenop() -> void:
	_judul.call("Kenop sakelar: pola 22x12, mati dan nyala berbeda bentuk, perintah gambar = pola")
	for nyala: bool in [false, true]:
		var pola: Array[String] = TampilJeda.pola_kenop(nyala)
		var rapi: bool = pola.size() == 12
		for baris: String in pola:
			rapi = rapi and baris.length() == 22
		check(rapi, "pola kenop %s 22x12" % ("nyala" if nyala else "mati"))
		# Perintah gambar dibentangkan kembali jadi piksel dan harus sama dengan pola.
		var piksel: Dictionary = {}
		for p: Array in TampilJeda.perintah_kenop(nyala):
			var r: Rect2 = p[0]
			for x: int in range(int(r.size.x)):
				piksel[Vector2i(int(r.position.x) + x, int(r.position.y))] = p[1]
		var sama: bool = true
		for y: int in range(12):
			for x: int in range(22):
				var huruf: String = pola[y][x]
				var ada: bool = piksel.has(Vector2i(x, y))
				if huruf == "." and ada:
					sama = false
				elif huruf != "." and (not ada or piksel[Vector2i(x, y)] != TampilJeda.warna_kenop(huruf)):
					sama = false
		check(sama, "perintah gambar kenop %s sama persis dengan pola (warna per huruf)" % ("nyala" if nyala else "mati"))
	var mati: Array[String] = TampilJeda.pola_kenop(false)
	var nyala_pola: Array[String] = TampilJeda.pola_kenop(true)
	check(mati != nyala_pola, "kenop mati dan nyala berbeda")
	# Kenop mati: kenop berongga 6x6 di kiri (piksel (4,4) gelap, (3,3) tepi TEXT_2) dan kotak kosong 4x4 di kanan; nyala: kenop terisi 6x6 di kanan (TEXT di (14,4)) di atas ACCENT dan garis tegak di (5, 3..8).
	check(mati[3][3] == "s" and mati[4][4] == "g" and mati[4][14] == "s" and mati[5][15] == "g", "mati: kenop berongga di kiri dan kotak kosong di kanan")
	check(nyala_pola[3][13] == "o" and nyala_pola[4][14] == "t" and nyala_pola[7][17] == "t" and nyala_pola[3][5] == "g" and nyala_pola[8][5] == "g" and nyala_pola[9][5] == "a", "nyala: kenop terisi TEXT di kanan, garis tegak gelap di kiri (3..8)")
	check(nyala_pola[1][1] == "a" and mati[1][1] == "s", "nyala beralas ACCENT, mati beralas cincin TEXT_2")
	check(TampilJeda.warna_kenop("a") == Palette.ACCENT and TampilJeda.warna_kenop("t") == Palette.TEXT and TampilJeda.warna_kenop("s") == Palette.TEXT_2 and TampilJeda.warna_kenop("o") == Palette.OUTLINE and TampilJeda.warna_kenop("g") == Palette.UI_BG and TampilJeda.warna_kenop(".").a == 0.0, "warna huruf kenop dari Palette, titik transparan")


func _test_titik_dan_glif_tutorial() -> void:
	_judul.call("Tutorial murni: titik langkah (terisi sampai langkah sekarang) dan glif per langkah")
	check(TampilTutorial.titik(1, 4) == _b([true, false, false, false]), "langkah 1 dari 4: satu titik terisi")
	check(TampilTutorial.titik(3, 4) == _b([true, true, true, false]), "langkah 3 dari 4: tiga titik terisi")
	check(TampilTutorial.titik(4, 4) == _b([true, true, true, true]), "langkah 4 dari 4: semua terisi")
	check(TampilTutorial.titik(2, 3) == _b([true, true, false]), "tanpa misi: tiga titik")
	check(TampilTutorial.titik(0, 3) == _b([false, false, false]) and TampilTutorial.titik(9, 2) == _b([true, true]) and TampilTutorial.titik(1, 0).is_empty() and TampilTutorial.titik(1, -3).is_empty(), "nomor di luar rentang dijepit, total <= 0 kosong")
	check(TampilTutorial.lebar_titik(4) == 4 * 4 + 3 * 2 and TampilTutorial.lebar_titik(0) == 0, "lebar empat titik 22 px (titik 4, jarak 2)")
	check(TampilTutorial.nama_glif(TutorialLangkah.Langkah.KAYUH) == "glif_naik_aksen" and TampilTutorial.nama_glif(TutorialLangkah.Langkah.MELAMBAT) == "glif_turun_aksen" and TampilTutorial.nama_glif(TutorialLangkah.Langkah.LEMPAR) == "glif_panah_aksen" and TampilTutorial.nama_glif(TutorialLangkah.Langkah.MENEPI) == "glif_seru_aksen" and TampilTutorial.nama_glif(TutorialLangkah.Langkah.SELESAI) == "", "glif per langkah, selesai tanpa glif")
	var p: Array = TampilTutorial.perintah_titik(1, 4)
	# Terisi: cincin OUTLINE 6x6 di (-1,-1) lalu isi ACCENT 4x4 di (0,0); tiga berongga: masing-masing empat persegi TEXT_2.
	check(p.size() == 2 + 3 * 4, "perintah titik: 2 untuk titik terisi, 4 per titik berongga (%d)" % p.size())
	check(p[0][0] == Rect2(-1, -1, 6, 6) and p[0][1] == Palette.OUTLINE and p[1][0] == Rect2(0, 0, 4, 4) and p[1][1] == Palette.ACCENT, "titik terisi: cincin gelap 1 px dan isi ACCENT 4x4")
	check(p[2][0] == Rect2(6, 0, 4, 1) and p[2][1] == Palette.TEXT_2 and p[3][0] == Rect2(6, 3, 4, 1) and p[4][0] == Rect2(6, 1, 1, 2) and p[5][0] == Rect2(9, 1, 1, 2), "titik berongga kedua di x 6: bingkai 1 px TEXT_2 (atas, bawah, kiri, kanan)")


func _test_stamina_dan_tanda() -> void:
	_judul.call("Panel bawah murni: warna stamina di ambang 30 dan tanda 80 % bar kecepatan")
	check(TampilHud.warna_stamina(29.99) == Palette.FAIL and TampilHud.warna_stamina(0.0) == Palette.FAIL and TampilHud.warna_stamina(10.0) == Palette.FAIL, "stamina di bawah 30: FAIL")
	check(TampilHud.warna_stamina(30.0) == Palette.ACCENT and TampilHud.warna_stamina(100.0) == Palette.ACCENT and TampilHud.warna_stamina(30.01) == Palette.ACCENT, "stamina 30 ke atas: ACCENT (tepat 30 belum FAIL)")
	check(Config.HUD_STAMINA_AMBANG_RENDAH == 30.0 and Config.HUD_BAR_TANDA_PECAHAN == 0.8 and Config.HUD_BAR_TINGGI_PX == 9, "ambang 30, tanda 0,8, bar 9 tinggi")
	check(TampilHud.posisi_tanda(109.0, 0.8) == 87 and TampilHud.posisi_tanda(87.0, 0.8) == 69 and TampilHud.posisi_tanda(100.0, 0.8) == 80, "tanda 80 % dibulatkan ke bawah (109 -> 87, 87 -> 69, 100 -> 80)")
	check(TampilHud.posisi_tanda(100.0, 1.5) == 100 and TampilHud.posisi_tanda(100.0, 0.0) == 0 and TampilHud.posisi_tanda(0.0, 0.8) == 0 and TampilHud.posisi_tanda(NAN, 0.8) == 0 and TampilHud.posisi_tanda(100.0, -0.2) == 0, "tanda: pecahan > 1 dijepit, nol atau tidak sah = 0")


func _test_panel_bawah() -> void:
	_judul.call("Panel bawah murni: margin menurut tangan (kidal dicerminkan) dan urutan panel koran")
	check(TampilHud.margin_bawah(false) == Vector2i(196, 8) and TampilHud.margin_bawah(true) == Vector2i(8, 196), "margin kiri/kanan: tangan kanan (196, 8), kidal (8, 196)")
	check(not TampilHud.koran_di_awal(false) and TampilHud.koran_di_awal(true), "koran di akhir (kanan) bawaan, di awal (kiri) saat kidal")
	check(Config.HUD_PANEL_KECEPATAN_GESER_PX == 196 and Config.HUD_PANEL_KECEPATAN_LEBAR_PX == 220 and Config.HUD_PANEL_KORAN_GESER_PX == 424, "geser 196, lebar 220, koran mulai 424 (celah 8)")
	check(Config.HUD_PANEL_BAWAH_PAD_X_PX * 2 + Config.HUD_BAWAH_KOLOM_KECEPATAN_PX + Config.HUD_BAWAH_KOLOM_JARAK_PX + Config.HUD_BAWAH_KOLOM_STAMINA_PX == Config.HUD_PANEL_KECEPATAN_LEBAR_PX, "lebar panel = 2 x pad + kolom kecepatan + jarak + kolom stamina (220)")
	check(Config.HUD_PANEL_KORAN_GESER_PX - Config.HUD_PANEL_KECEPATAN_GESER_PX - Config.HUD_PANEL_KECEPATAN_LEBAR_PX == 8, "celah panel kecepatan ke panel koran 8")
	check(Config.HUD_PANEL_KECEPATAN_GESER_PX > Config.ZONA_STICK_X_MAKS_PX, "panel kecepatan mulai di luar zona stick (x > 192)")


func _test_tombol_jeda_hud() -> void:
	_judul.call("Tombol jeda HUD murni: bingkai tombol biasa, glif di tengah wajah (turun 2 px saat ditekan)")
	check(TampilHud.nama_bingkai_jeda(false) == "btn_biasa" and TampilHud.nama_bingkai_jeda(true) == "btn_biasa_tekan", "bingkai tombol biasa, ditekan = btn_biasa_tekan")
	check(TampilHud.nama_glif_jeda() == "glif_jeda_terang", "glif jeda terang")
	check(TampilHud.posisi_glif_jeda(false) == Vector2i(6, 5) and TampilHud.posisi_glif_jeda(true) == Vector2i(6, 7), "glif 12x12 di (6, 5) normal dan (6, 7) ditekan di dalam wajah 24x24 (kanvas)")
	check(Config.HUD_JEDA_SENTUH_PX == 42 and Config.HUD_JEDA_GAMBAR_PX == 24 and Config.HUD_JEDA_GAMBAR_X_PX == 26 and Config.HUD_JEDA_GAMBAR_Y_PX == 8, "area sentuh 42, gambar 24 di (26, 8) tidak berubah (DESIGN_SPEC 3.1)")


func _test_baris2() -> void:
	_judul.call("Kolom kanan murni: baris 2 memuat kondisi dan reputasi dalam satu panel")
	check(TampilHud.kunci_reputasi(37) == 37 and TampilHud.kunci_reputasi(0) == 0 and TampilHud.kunci_reputasi(100) == 100 and TampilHud.kunci_reputasi(150) == 100 and TampilHud.kunci_reputasi(-1) == -1 and TampilHud.kunci_reputasi(-5) == -1, "kunci reputasi: dijepit 0..100, negatif = tersembunyi")
	check(TampilHud.reputasi_tampil(0) and TampilHud.reputasi_tampil(100) and not TampilHud.reputasi_tampil(-1), "reputasi 0 tetap tampil; hanya negatif yang menyembunyikan")
	check(TampilHud.baris2_tampil(true, -1) and TampilHud.baris2_tampil(true, 50) and TampilHud.baris2_tampil(false, 50) and not TampilHud.baris2_tampil(false, -1), "panel baris 2 tampil bila ada kondisi atau reputasi")
