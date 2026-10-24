class_name TesHudRuteScene
extends RefCounted
## Tes scene run fase3c-hud-hasil bagian 1a: HUD rute final (radar, progres, tenggat, koin/skor), sakelar Kidal/Bantu di layar jeda, dan
## layar hasil (AC-3, AC-5 sampai AC-8, AC-11 sampai AC-13, AC-18) di `scenes/rute/rute.tscn` sungguhan, plus smoke test
## `scenes/ui/layar_hasil.tscn` sendiri. Event sentuh sintetis lewat `Input.parse_input_event`, langkah `perbarui(dt)` dengan dt tetap.
## Harapan literal (AC-17), dihitung tangan dari data rute seed bawaan 20261016 (panjang 236, tenggat ceil(236 / 3 x 1,15) = 91):
## - Pelanggan awal: per_buka_01@6 (pusat kotak surat 7,875), @10 (11,875), @18 pemberi tip (19,875); bukan pelanggan dalam 30 ubin:
##   seberang @2, @14, @22, @26, dekat @8, @16, @24.
## - Radar 780: jalur strip 168 px (172 - 2 x 2), ruang penanda 162; penanda @6 di sepeda 0: vertikal 1 - 7,875/30 = 0,7375 ->
##   round(119,475) = 119 -> y 10 + 2 + 119 = 131, x 4 + 2 = 6.

const BERKAS_RUTE: String = "res://scenes/rute/rute.tscn"
const BERKAS_HASIL: String = "res://scenes/ui/layar_hasil.tscn"
const SKALA: int = 3
const DT: float = 1.0 / 60.0
const LEBAR: int = 780
const TITIK_STICK: Vector2 = Vector2(100, 260)
const PANJANG_RUTE: float = 236.0

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
	for kasus: Array in [[1920, 1080, 640], [2340, 1080, 780], [2400, 1080, 800]]:
		await _test_layar_hasil_smoke(kasus)
	await _test_radar_di_layar()
	await _test_radar_bantu_dan_tenggat()
	await _test_progres_di_layar()
	await _test_tenggat_di_hud()
	await _test_koin_skor_hud()
	await _test_sakelar_layar_jeda()
	await _test_hasil_dari_rute()
	await _test_berhenti_lama_lewat_tenggat()
	await _test_main_lagi_mengatur_ulang()


# --- Pembantu ---

func _siapkan(jendela: Vector2i = Vector2i(2340, 1080)) -> RuteMain:
	_tree.root.size = jendela
	var akar: RuteMain = (load(BERKAS_RUTE) as PackedScene).instantiate() as RuteMain
	_tree.root.add_child(akar)
	await _tree.process_frame
	await _tree.process_frame
	akar.set_process(false)
	(_anak(akar, "KontrolTouch") as KontrolTouch).keyboard_aktif = false
	(_anak(akar, "LoperAgen") as LoperSprite).set_process(false)
	# Frame nyata sebelum `set_process(false)` sudah memajukan sepeda dan jam sedikit: kembalikan ke awal rute supaya harapan literal.
	_taruh(akar, Config.KECEPATAN_SANTAI_UD, 0.0, 0.0)
	akar.atur_tenggat(TenggatRute.awal(akar.rute().panjang_ubin))
	akar.perbarui(0.0)
	return akar


func _bersihkan(akar: RuteMain) -> void:
	for i: int in range(8):
		_sentuh(i, Vector2(-50, -50), false)
	if akar.sedang_jeda():
		akar.minta_lanjut()
	(_anak(akar, "KontrolTouch") as KontrolTouch).keyboard_aktif = OS.has_feature("editor")
	_tree.root.remove_child(akar)
	akar.free()


func _anak(akar: Node, nama: String) -> Node:
	return akar.find_child(nama, true, false)


func _sepeda(akar: Node) -> SepedaUji:
	return _anak(akar, "Sepeda") as SepedaUji


func _jeda(akar: Node) -> LayarJeda:
	return _anak(akar, "LayarJeda") as LayarJeda


func _sentuh(index: int, posisi_viewport: Vector2, tekan: bool) -> void:
	var peristiwa: InputEventScreenTouch = InputEventScreenTouch.new()
	peristiwa.index = index
	peristiwa.position = posisi_viewport * float(SKALA)
	peristiwa.pressed = tekan
	Input.parse_input_event(peristiwa)
	Input.flush_buffered_events()


func _geser(index: int, posisi_viewport: Vector2) -> void:
	var peristiwa: InputEventScreenDrag = InputEventScreenDrag.new()
	peristiwa.index = index
	peristiwa.position = posisi_viewport * float(SKALA)
	Input.parse_input_event(peristiwa)
	Input.flush_buffered_events()


func _tap(posisi: Vector2, index: int) -> void:
	_sentuh(index, posisi, true)
	_sentuh(index, posisi, false)


func _langkah(akar: RuteMain, jumlah: int, dt: float = DT) -> void:
	for i: int in range(jumlah):
		akar.perbarui(dt)


func _taruh(akar: RuteMain, v: float, lateral: float, maju: float) -> void:
	var sepeda: SepedaUji = _sepeda(akar)
	var k: BikeMotion.Keadaan = sepeda.keadaan.salin()
	k.kecepatan_ud = v
	k.lateral_ubin = lateral
	sepeda.keadaan = k
	sepeda.jarak_ubin = maju


func _sampai_hasil(akar: RuteMain, maks: int = 600) -> bool:
	for i: int in range(maks):
		if akar.hasil_tampil():
			return true
		akar.perbarui(DT)
	return akar.hasil_tampil()


func _ids(daftar: Array[RadarRute.Penanda]) -> Array[String]:
	var hasil: Array[String] = []
	for p: RadarRute.Penanda in daftar:
		hasil.append(p.id_rumah)
	return hasil


func _cari(daftar: Array[RadarRute.Penanda], id: String) -> RadarRute.Penanda:
	for p: RadarRute.Penanda in daftar:
		if p.id_rumah == id:
			return p
	return null


func _angka(terkirim: int, meleset: int, koin: int, koin_tip: int, jumlah_tip: int, skor: int, tepat: int, lewat: bool, detik: int) -> HasilRute.Angka:
	var a: HasilRute.Angka = HasilRute.Angka.new()
	a.pelanggan = terkirim + meleset
	a.terkirim = terkirim
	a.meleset = meleset
	a.koin = koin
	a.koin_tip = koin_tip
	a.jumlah_tip = jumlah_tip
	a.skor = skor
	a.jumlah_tepat = tepat
	a.tenggat_lewat = lewat
	a.detik_lewat = detik
	return a


# --- Layar hasil sendiri (AC-12, AC-13 smoke test, rule testing) ---

func _test_layar_hasil_smoke(kasus: Array) -> void:
	var lebar: int = kasus[2]
	_judul.call("Layar hasil (smoke, %d): instansiasi, isi angka, teks lewat kunci, urutan dari yang berhasil, tombol Main lagi (AC-12, AC-13)" % lebar)
	_tree.root.size = Vector2i(kasus[0], kasus[1])
	var layar: LayarHasil = (load(BERKAS_HASIL) as PackedScene).instantiate() as LayarHasil
	_tree.root.add_child(layar)
	await _tree.process_frame
	check(not layar.tampil(), "tersembunyi saat dibuat")
	layar.isi(_angka(25, 0, 380, 5, 1, 4478, 1, false, 0))
	layar.tampilkan(true)
	await _tree.process_frame
	await _tree.process_frame
	var harap: Array[String] = ["Hasil antaran", "Terkirim", "25/25", "Tip", "+5 dari 1 pelanggan", "Koin", "380", "Skor", "4.478", "Tepat", "1", "Meleset", "0", "Sampai sebelum tenggat"]
	check(layar.teks_tampil() == harap, "semua terantar sebelum tenggat: %s (dapat %s)" % [harap, layar.teks_tampil()])
	check(tr("HASIL_JUDUL") == "Hasil antaran" and layar.teks_tombol() == "Main lagi", "judul dan tombol lewat kunci terjemahan (HASIL_JUDUL, RUTE_MAIN_LAGI)")
	layar.isi(_angka(3, 22, 1250, 5, 1, 255, 0, true, 12))
	await _tree.process_frame
	var harap2: Array[String] = ["Hasil antaran", "Terkirim", "3/25", "Tip", "+5 dari 1 pelanggan", "Koin", "1.250", "Skor", "255", "Tepat", "0", "Meleset", "22", "Lewat tenggat +0:12; tip sesudahnya tidak ada"]
	check(layar.teks_tampil() == harap2, "sebagian meleset dan tenggat lewat: %s (dapat %s)" % [harap2, layar.teks_tampil()])
	var teks_semua: String = " ".join(layar.teks_tampil()).to_lower()
	check(teks_semua.find("gagal") == -1 and teks_semua.find("kalah") == -1, "nada netral: tanpa kata 'gagal' atau 'kalah' (prinsip 2)")
	var kotak_layar: Rect2 = Rect2(Vector2.ZERO, Vector2(lebar, 360))
	var tombol: Rect2 = layar.rect_tombol()
	check(tombol.size.x >= 42.0 and tombol.size.y >= 42.0 and kotak_layar.encloses(layar.rect_panel()) and kotak_layar.encloses(tombol) and not layar.rect_panel().intersects(tombol), "lebar %d: struk di dalam layar, tombol Main lagi >= 42 px di dalam layar dan tidak menutupi struk (%s; run ui2: tombol kanan bawah di luar struk)" % [lebar, tombol])
	var semua_di_panel: bool = true
	for r: Rect2 in layar.rect_label():
		semua_di_panel = semua_di_panel and layar.rect_panel().encloses(r) and r.size.x > 0.0
	check(semua_di_panel, "lebar %d: semua label (termasuk teks tenggat panjang, autowrap) di dalam panel" % lebar)
	check(Palette.UI_BG == (_anak(layar, "LatarHasil") as ColorRect).color and (_anak(layar, "LatarHasil") as ColorRect).mouse_filter == Control.MOUSE_FILTER_STOP, "latar penuh UI_BG dan menangkap sentuhan GUI")
	var ditekan: Array[int] = [0]
	layar.main_lagi_diminta.connect(func() -> void: ditekan[0] += 1)
	layar.tombol_main_lagi().pressed.emit()
	check(ditekan[0] == 1, "pressed.emit() tombol Main lagi memancarkan main_lagi_diminta tepat sekali")
	_tree.root.remove_child(layar)
	layar.free()


# --- Radar di layar (AC-4 sampai AC-6) ---

func _test_radar_di_layar() -> void:
	_judul.call("Scene rute: radar di layar, penanda turun saat rumah mendekat, jangkau membesar, terantar keluar (AC-4, AC-5)")
	var akar: RuteMain = await _siapkan()
	var hud: HudRute = akar.hud_rute()
	var seb: RadarStrip = hud.radar_seberang()
	var dek: RadarStrip = hud.radar_dekat()
	check(_ids(seb.penanda_tampil()) == (["per_buka_01@6", "per_buka_01@10", "per_buka_01@18"] as Array[String]) and dek.penanda_tampil().is_empty(), "sepeda 0, bantu mati: tiga pelanggan di strip seberang, strip dekat kosong (dapat %s)" % [_ids(seb.penanda_tampil())])
	var p6: RadarRute.Penanda = _cari(seb.penanda_tampil(), "per_buka_01@6")
	var p18: RadarRute.Penanda = _cari(seb.penanda_tampil(), "per_buka_01@18")
	check(p6 != null and seb.rect_global(p6) == Rect2(6, 131, 8, 6) and RadarStrip.tekstur(p6).resource_path.ends_with("ui_radar_pelanggan.png"), "@6 (7,875 ubin): penanda pelanggan 8x6 di (6, 131)")
	check(p18 != null and p18.jenis == RadarRute.Jenis.TIP and seb.rect_global(p18) == Rect2(6, 67, 8, 6) and RadarStrip.tekstur(p18).resource_path.ends_with("ui_radar_tip.png"), "@18 pemberi tip (19,875 ubin): penanda tip bertitik di (6, 67)")
	_taruh(akar, 3.0, 0.0, 3.0)
	akar.perbarui(0.0)
	p6 = _cari(seb.penanda_tampil(), "per_buka_01@6")
	check(p6 != null and p6.jangkau and seb.rect_global(p6) == Rect2(5, 147, 10, 8) and RadarStrip.tekstur(p6).resource_path.ends_with("ui_radar_pelanggan_jangkau.png"), "sepeda 3,0 (@6 4,875 ubin <= 5): penanda jangkau 10x8 di (5, 147), turun dari y 131")
	_taruh(akar, 3.0, 0.0, 8.0)
	akar.perbarui(0.0)
	check(_cari(seb.penanda_tampil(), "per_buka_01@6") == null, "sepeda 8,0: @6 sudah di belakang, keluar dari radar")
	# Terantar keluar: koran tepat ke @10 lalu @10 hilang dari radar walau masih di depan.
	_taruh(akar, 3.0, 0.5, 8.0)
	akar.koran = SisaKoran.awal(30)
	var pilihan: BantuLempar.Pilihan = akar.pilihan_bantu(LoperAnim.Sisi.SEBERANG)
	check(pilihan != null and pilihan.zona.id_rumah == "per_buka_01@10", "kontrol: sasaran @10 dari maju 8")
	if pilihan != null:
		akar.call(&"_lempar", pilihan.lintasan, false)
		for i: int in range(120):
			akar.perbarui(DT)
			if akar.skor().terantar.has("per_buka_01@10"):
				break
		_taruh(akar, 3.0, 0.5, 8.0)
		akar.perbarui(0.0)
		check(akar.skor().terantar.has("per_buka_01@10") and _cari(seb.penanda_tampil(), "per_buka_01@10") == null and _cari(seb.penanda_tampil(), "per_buka_01@18") != null, "@10 terantar: keluar dari radar; @18 tetap")
	# Kidal tidak menukar strip.
	akar.atur_kidal(true)
	akar.perbarui(0.0)
	check(hud.rect_radar_seberang() == Rect2(4, 10, 12, 172) and _cari(seb.penanda_tampil(), "per_buka_01@18") != null and dek.penanda_tampil().is_empty(), "kidal: strip seberang tetap di tepi x 0 dengan pelanggan seberang")
	_bersihkan(akar)


func _test_radar_bantu_dan_tenggat() -> void:
	_judul.call("Scene rute: mode bantu menampilkan bukan pelanggan abu-abu berlubang (langsung berlaku); tip jadi pelanggan sesudah tenggat (AC-6, O-9)")
	var akar: RuteMain = await _siapkan()
	var hud: HudRute = akar.hud_rute()
	var seb: RadarStrip = hud.radar_seberang()
	var dek: RadarStrip = hud.radar_dekat()
	(_jeda(akar)).sakelar_bantu().ditekan.emit()
	check(akar.mode_bantu(), "sakelar bantu layar jeda menyalakan mode bantu")
	akar.perbarui(0.0)
	check(_ids(seb.penanda_tampil()) == (["per_buka_01@2", "per_buka_01@6", "per_buka_01@10", "per_buka_01@14", "per_buka_01@18", "per_buka_01@22", "per_buka_01@26"] as Array[String]), "bantu nyala: seberang 3 pelanggan + 4 bukan (dapat %s)" % [_ids(seb.penanda_tampil())])
	check(_ids(dek.penanda_tampil()) == (["per_buka_01@8", "per_buka_01@16", "per_buka_01@24"] as Array[String]), "bantu nyala: dekat 3 rumah bukan pelanggan (dapat %s)" % [_ids(dek.penanda_tampil())])
	var b8: RadarRute.Penanda = _cari(dek.penanda_tampil(), "per_buka_01@8")
	check(b8 != null and b8.jenis == RadarRute.Jenis.BUKAN and not b8.jangkau and dek.rect_global(b8) == Rect2(766, 121, 8, 6) and RadarStrip.tekstur(b8).resource_path.ends_with("ui_radar_bukan.png"), "@8 dekat (9,875 ubin): penanda bukan berlubang di (766, 121)")
	var img: Image = (load("res://assets/sprites/ui/ui_radar_bukan.png") as Texture2D).get_image()
	check(img.get_pixel(3, 2).a == 0.0 and img.get_pixel(0, 0).a > 0.0, "aset penanda bukan pelanggan berlubang (piksel tengah transparan): bentuk, bukan warna saja")
	var img_tip: Image = (load("res://assets/sprites/ui/ui_radar_tip.png") as Texture2D).get_image()
	var img_pel: Image = (load("res://assets/sprites/ui/ui_radar_pelanggan.png") as Texture2D).get_image()
	var terang_tip: float = img_tip.get_pixel(3, 2).get_luminance() - img_tip.get_pixel(1, 1).get_luminance()
	var terang_pel: float = img_pel.get_pixel(3, 2).get_luminance() - img_pel.get_pixel(1, 1).get_luminance()
	check(terang_tip > 0.1 and terang_pel < 0.05, "aset tip bertitik terang di tengah (selisih terang %.2f); pelanggan tanpa titik terang (%.2f)" % [terang_tip, terang_pel])
	(_jeda(akar)).sakelar_bantu().ditekan.emit()
	akar.perbarui(0.0)
	check(not akar.mode_bantu() and seb.penanda_tampil().size() == 3 and dek.penanda_tampil().is_empty(), "bantu dimatikan di tengah rute: rumah bukan pelanggan langsung hilang")
	akar.atur_tenggat(TenggatRute.langkah(TenggatRute.awal(PANJANG_RUTE), 91.5))
	akar.perbarui(0.0)
	var p18: RadarRute.Penanda = _cari(seb.penanda_tampil(), "per_buka_01@18")
	check(p18 != null and p18.jenis == RadarRute.Jenis.PELANGGAN and RadarStrip.tekstur(p18).resource_path.ends_with("ui_radar_pelanggan.png"), "sesudah tenggat lewat: pemberi tip @18 tampil sebagai pelanggan biasa (O-9)")
	_bersihkan(akar)


# --- Progres (AC-7) ---

func _test_progres_di_layar() -> void:
	_judul.call("Scene rute: kotak progres dan TERKIRIM dari ProgresRute (AC-7, O-12)")
	var akar: RuteMain = await _siapkan()
	var hud: HudRute = akar.hud_rute()
	var belum: ProgresRute.Status = ProgresRute.Status.BELUM
	var lanjut: ProgresRute.Status = ProgresRute.Status.BERIKUTNYA
	var status: Array[ProgresRute.Status] = hud.kotak_progres().status_tampil()
	check(status.size() == 25 and status[0] == lanjut and status.count(belum) == 24 and hud.teks_terkirim() == "0/25 TERKIRIM", "awal: 25 kotak, @6 berikutnya, sisanya belum, '0/25 TERKIRIM'")
	check(hud.kotak_progres().get_global_rect().size == Vector2(248, 8), "baris kotak 25 x 8 + 24 x 2 = 248 x 8 px")
	# Antar @6, lewati @10 (lebih dari 3 ubin di belakang), sepeda di 15,0: @6 terkirim, @10 terlewat, @18 berikutnya.
	_taruh(akar, 3.0, 0.5, 1.0)
	akar.koran = SisaKoran.awal(30)
	var pilihan: BantuLempar.Pilihan = akar.pilihan_bantu(LoperAnim.Sisi.SEBERANG)
	if pilihan != null:
		akar.call(&"_lempar", pilihan.lintasan, false)
		for i: int in range(120):
			akar.perbarui(DT)
			if akar.skor().terantar.has("per_buka_01@6"):
				break
	_taruh(akar, 3.0, 0.5, 15.0)
	akar.perbarui(0.0)
	status = hud.kotak_progres().status_tampil()
	check(status.size() == 25 and status[0] == ProgresRute.Status.TERKIRIM and status[1] == ProgresRute.Status.TERLEWAT and status[2] == lanjut and status[3] == belum, "sepeda 15: @6 terkirim, @10 terlewat (11,875 < 15 - 3), @18 berikutnya, berikutnya belum")
	check(hud.teks_terkirim() == "1/25 TERKIRIM", "'1/25 TERKIRIM' (dapat %s)" % hud.teks_terkirim())
	var perintah: Array = hud.kotak_progres().perintah_tampil()
	check(not perintah.is_empty(), "kotak digambar lewat perintah GambarPiksel (simbol pola PolaPiksel)")
	# QA-005 iterasi 1: warna utama kotak yang benar-benar digambar (DESIGN_SPEC 3.2, harapan literal): terkirim OK, terlewat FAIL,
	# berikutnya ACCENT, belum UI_PANEL_RAISED. Kotak ke-i digambar mulai x = i x (8 + 2).
	var harap_warna: Array = [["terkirim", Palette.OK], ["terlewat", Palette.FAIL], ["berikutnya", Palette.ACCENT], ["belum", Palette.UI_PANEL_RAISED]]
	var semua_warna: Array[Color] = [Palette.OK, Palette.FAIL, Palette.ACCENT, Palette.UI_PANEL_RAISED]
	for i: int in range(harap_warna.size()):
		var warna_kotak: Array[Color] = []
		for p: Array in perintah:
			if p[1] == Vector2(i * 10, 0):
				warna_kotak.append(p[2])
		var lain_ada: bool = false
		for w: Color in semua_warna:
			if w != harap_warna[i][1] and warna_kotak.has(w):
				lain_ada = true
		check(warna_kotak.has(harap_warna[i][1]) and not lain_ada, "kotak %d (%s) digambar dengan warna %s, bukan warna status lain (dapat %s)" % [i, harap_warna[i][0], harap_warna[i][1], warna_kotak])
	check(PolaPiksel.pola_progres(ProgresRute.Status.TERKIRIM) != PolaPiksel.pola_progres(ProgresRute.Status.TERLEWAT) and PolaPiksel.pola_progres(ProgresRute.Status.BERIKUTNYA) != PolaPiksel.pola_progres(ProgresRute.Status.BELUM) and PolaPiksel.pola_progres(ProgresRute.Status.TERKIRIM) != PolaPiksel.pola_progres(ProgresRute.Status.BELUM), "empat status berbeda bentuk (centang, silang, segitiga, garis putus-putus), bukan warna saja")
	_bersihkan(akar)


# --- Tenggat di HUD dan scene (AC-1, AC-3, O-8) ---

func _test_tenggat_di_hud() -> void:
	_judul.call("Scene rute: tenggat 91 detik, jam beku saat jeda, berhenti di garis akhir; HUD WAKTU/LEWAT dengan teks dan warna (AC-1, O-8)")
	var akar: RuteMain = await _siapkan()
	var hud: HudRute = akar.hud_rute()
	check(akar.tenggat().tenggat_detik == 91 and hud.teks_tenggat() == "WAKTU 1:31" and hud.warna_tenggat() == Palette.TEXT, "awal rute 236 ubin: 'WAKTU 1:31' warna TEXT")
	_langkah(akar, 60)
	check(is_equal_approx(akar.tenggat().waktu_detik, 1.0) and hud.teks_tenggat() == "WAKTU 1:30", "1 detik berjalan: 'WAKTU 1:30'")
	akar.minta_jeda()
	_langkah(akar, 120)
	check(is_equal_approx(akar.tenggat().waktu_detik, 1.0), "jeda 2 detik: jam tenggat membeku")
	akar.minta_lanjut()
	akar._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	_langkah(akar, 60)
	check(is_equal_approx(akar.tenggat().waktu_detik, 1.0), "app ke background: jam tenggat membeku")
	akar.minta_lanjut()
	akar.atur_tenggat(TenggatRute.langkah(TenggatRute.awal(PANJANG_RUTE), 103.0))
	akar.perbarui(0.0)
	check(hud.teks_tenggat() == "LEWAT +0:12" and hud.warna_tenggat() == Palette.WARN, "103 detik dari 91: 'LEWAT +0:12' warna WARN (teks berubah, bukan warna saja)")
	_taruh(akar, 3.0, 0.0, PANJANG_RUTE - 0.01)
	_langkah(akar, 2)
	var jam: float = akar.tenggat().waktu_detik
	check(akar.rute_sudah_selesai() and akar.tenggat().berhenti, "garis akhir: jam tenggat berhenti")
	_langkah(akar, 60)
	check(akar.tenggat().waktu_detik == jam, "sesudah garis akhir jam tidak maju")
	_bersihkan(akar)


func _test_koin_skor_hud() -> void:
	_judul.call("HUD rute: koin dengan pemisah ribuan, skor/combo, label PUTUS menggantikan COMBO tanpa melebarkan panel (AC-8, O-7)")
	var akar: RuteMain = await _siapkan()
	var hud: HudRute = akar.hud_rute()
	hud.tampilkan_skor(4478, 3, 1250, false)
	await _tree.process_frame
	var lebar_panel: float = hud.rect_panel_skor().size.x
	check(hud.teks_koin() == "1.250" and hud.teks_skor() == "4.478" and hud.teks_combo() == "x1.3" and not hud.putus_tampil(), "koin '1.250', skor '4.478', combo x1.3")
	hud.tampilkan_skor(4478, 0, 1250, true)
	await _tree.process_frame
	check(hud.putus_tampil() and hud.teks_combo() == "x1.0" and hud.rect_panel_skor().size.x == lebar_panel, "PUTUS tampil di samping x1.0, lebar panel skor tetap (%s)" % hud.rect_panel_skor().size.x)
	check(hud.rect_panel_koin().end.x + 5.0 == hud.rect_panel_skor().position.x, "panel koin tetap 5 px di kiri panel skor")
	check(tr("HUD_PEMISAH_RIBUAN") == ".", "pemisah ribuan lewat kunci terjemahan")
	_bersihkan(akar)


# --- Sakelar Kidal/Bantu di layar jeda (O-6, AC-8) ---

func _test_sakelar_layar_jeda() -> void:
	_judul.call("Layar jeda: sakelar Kidal dan Bantu diketuk sentuhan sungguhan saat jeda; status terbaca dari teks (O-6)")
	var akar: RuteMain = await _siapkan()
	var layar: LayarJeda = _jeda(akar)
	var hud: HudRute = akar.hud_rute()
	akar.minta_jeda()
	await _tree.process_frame
	await _tree.process_frame
	var r_kidal: Rect2 = layar.rect_sakelar_kidal()
	var r_bantu: Rect2 = layar.rect_sakelar_bantu()
	check(r_kidal.size.x >= 42.0 and r_kidal.size.y >= 42.0 and r_bantu.size.x >= 42.0 and r_bantu.size.y >= 42.0 and not r_kidal.intersects(r_bantu, true) and not r_kidal.intersects(layar.rect_tombol_lanjut(), true), "sakelar >= 42 px game, tidak bertumpuk dengan Lanjut")
	check(layar.sakelar_kidal().text == "JEDA_KIDAL_MATI" and tr(layar.sakelar_kidal().text) == "Kidal: mati" and tr(layar.sakelar_bantu().text) == "Bantu: mati", "bawaan: 'Kidal: mati', 'Bantu: mati'")
	_tap(r_kidal.get_center(), 4)
	await _tree.process_frame
	check(akar.kidal() and tr(layar.sakelar_kidal().text) == "Kidal: nyala" and hud.kidal() and akar.sedang_jeda(), "ketuk Kidal saat jeda: kidal nyala (router dan HUD), teks 'Kidal: nyala', tetap jeda")
	_tap(r_bantu.get_center(), 4)
	await _tree.process_frame
	check(akar.mode_bantu() and tr(layar.sakelar_bantu().text) == "Bantu: nyala", "ketuk Bantu saat jeda: mode bantu nyala, teks 'Bantu: nyala'")
	akar.minta_lanjut()
	akar.perbarui(0.0)
	await _tree.process_frame
	check(hud.rect_tombol_bel() == Rect2(44, 276, 40, 40) and hud.rect_panel_kecepatan().end.x == float(LEBAR - Config.HUD_PANEL_KECEPATAN_GESER_PX), "sesudah lanjut: panel bawah dan bel dicerminkan (kidal)")
	# QA-001 iterasi 1: mematikan Kidal lagi lewat sakelar yang sama (satu-satunya jalur kidal di scene rute, O-6), dengan sentuhan sungguhan.
	# Harapan literal tangan kanan 780 (DESIGN_SPEC 3.5, 3.8): bel (696, 276) 40x40, panel kecepatan mulai x 196 (V-9 H-1; dulu 210), radar seberang tetap
	# (4, 10); stick di kiri (100, 260 masuk zona stick kanan), swipe di kanan.
	akar.minta_jeda()
	await _tree.process_frame
	await _tree.process_frame
	_tap(layar.rect_sakelar_kidal().get_center(), 4)
	await _tree.process_frame
	var router: TouchRouter = akar.kontrol_router()
	check(not akar.kidal() and not hud.kidal() and not router.kidal() and tr(layar.sakelar_kidal().text) == "Kidal: mati" and akar.sedang_jeda(), "ketuk Kidal kedua kali saat jeda: kidal mati di adegan, HUD, dan router; teks 'Kidal: mati'; tetap jeda")
	check(akar.mode_bantu() and tr(layar.sakelar_bantu().text) == "Bantu: nyala", "mematikan Kidal tidak menyentuh mode bantu")
	akar.minta_lanjut()
	akar.perbarui(0.0)
	await _tree.process_frame
	check(hud.rect_tombol_bel() == Rect2(696, 276, 40, 40) and hud.rect_panel_kecepatan().position.x == float(Config.HUD_PANEL_KECEPATAN_GESER_PX), "sesudah lanjut: bel kembali (696, 276) dan panel kecepatan kembali mulai x 196 (HUD_PANEL_KECEPATAN_GESER_PX, sisi kanan), dapat %s / %s" % [hud.rect_tombol_bel(), hud.rect_panel_kecepatan()])
	check(hud.rect_radar_seberang() == Rect2(4, 10, 12, 172) and hud.rect_radar_dekat() == Rect2(764, 10, 12, 172), "radar tidak berpindah saat kidal dimatikan")
	_sentuh(0, TITIK_STICK, true)
	check(router.stick_aktif() and not router.swipe_aktif(), "jari turun di (100, 260): stick (zona stick kembali di kiri)")
	_sentuh(0, TITIK_STICK, false)
	_sentuh(1, Vector2(600, 200), true)
	check(router.swipe_aktif() and not router.stick_aktif(), "jari turun di (600, 200): swipe (zona swipe kembali di kanan)")
	_sentuh(1, Vector2(600, 200), false)
	akar.atur_kidal(true)
	akar.atur_kidal(false)
	check(not akar.kidal() and tr(layar.sakelar_kidal().text) == "Kidal: mati", "atur_kidal dari tempat lain menyamakan sakelar layar jeda")
	_bersihkan(akar)


# --- Hasil dari rute (AC-11 sampai AC-13) ---

func _test_hasil_dari_rute() -> void:
	_judul.call("Scene rute: rute selesai -> layar hasil tepat sekali, angka sama dengan SkorRute, HUD dan kontrol tidak menerima sentuhan (AC-12, AC-13)")
	var akar: RuteMain = await _siapkan()
	var dibuka: Array[HasilRute.Angka] = []
	akar.hasil_dibuka.connect(func(a: HasilRute.Angka) -> void: dibuka.append(a))
	# Satu antaran tepat ke @6, lalu ke garis akhir.
	_taruh(akar, 3.0, 0.5, 1.0)
	akar.koran = SisaKoran.awal(30)
	var pilihan: BantuLempar.Pilihan = akar.pilihan_bantu(LoperAnim.Sisi.SEBERANG)
	if pilihan != null:
		akar.call(&"_lempar", pilihan.lintasan, false)
		for i: int in range(120):
			akar.perbarui(DT)
			if akar.skor().terantar.has("per_buka_01@6"):
				break
	_taruh(akar, 3.0, 0.0, PANJANG_RUTE - 0.01)
	check(_sampai_hasil(akar), "layar hasil terbuka sesudah garis akhir dan sepeda berhenti")
	_langkah(akar, 60)
	var a: HasilRute.Angka = akar.angka_hasil()
	var s: SkorRute.Keadaan = akar.skor()
	check(dibuka.size() == 1 and a != null, "hasil_dibuka tepat sekali")
	if a != null:
		check(a.terkirim == 1 and a.meleset == 24 and a.koin == s.koin and a.koin == 15 and a.skor == s.skor and a.skor == 125 and a.jumlah_tepat == 1, "angka hasil = SkorRute: terkirim 1, meleset 24, koin 15, skor 125, tepat 1")
		check(not a.tenggat_lewat, "sampai sebelum tenggat (jam %.1f dari 91)" % akar.tenggat().waktu_detik)
		check(akar.layar_hasil().teks_tampil()[2] == "1/25" and akar.layar_hasil().teks_tampil()[12] == "24", "layar menampilkan '1/25' terkirim dan meleset '24'")
	check(not akar.hud_rute().visible and not (_anak(akar, "KontrolTouch") as KontrolTouch).is_processing_input(), "HUD disembunyikan dan kontrol sentuh tidak membaca sentuhan di bawah layar hasil")
	var router: TouchRouter = akar.kontrol_router()
	var bel_awal: int = akar.bel().jumlah
	_tap(Vector2(38, 25), 3)
	_sentuh(0, TITIK_STICK, true)
	_tap(Vector2(LEBAR - 64, 296), 2)
	akar.perbarui(DT)
	check(not akar.sedang_jeda() and not router.stick_aktif() and akar.bel().jumlah == bel_awal, "ketuk area tombol jeda, stick, dan bel di bawah layar hasil: tidak jeda, stick tidak aktif, bel tidak berbunyi")
	_sentuh(0, TITIK_STICK, false)
	_bersihkan(akar)


func _test_berhenti_lama_lewat_tenggat() -> void:
	_judul.call("Scene rute: pemain berhenti lama (rem) sampai tenggat lewat tetap bisa menyelesaikan rute; rute_selesai tepat sekali; hasil terbuka (AC-3, AC-18)")
	var akar: RuteMain = await _siapkan()
	var selesai: Array[int] = [0]
	akar.rute_selesai.connect(func() -> void: selesai[0] += 1)
	var sepeda: SepedaUji = _sepeda(akar)
	# Rem: stick ditarik penuh ke bawah dan ditahan 95 detik (langkah 0,1 detik).
	_sentuh(0, TITIK_STICK, true)
	_geser(0, TITIK_STICK + Vector2(0, 60))
	_langkah(akar, 950, 0.1)
	check(sepeda.kecepatan_ud == 0.0 and sepeda.jarak_ubin < 2.0, "rem 95 detik: sepeda berhenti di dekat awal (jarak %.2f)" % sepeda.jarak_ubin)
	check(TenggatRute.lewat(akar.tenggat()) and akar.hud_rute().teks_tenggat().begins_with("LEWAT +0:0"), "tenggat lewat saat berhenti: HUD '%s'" % akar.hud_rute().teks_tenggat())
	_sentuh(0, TITIK_STICK, false)
	# Lanjut santai sampai garis akhir (dipercepat ke dekat garis; rute tidak terkunci oleh tenggat).
	_taruh(akar, 3.0, 0.0, PANJANG_RUTE - 5.0)
	_langkah(akar, 150, 0.1)
	check(akar.rute_sudah_selesai() and selesai[0] == 1, "sesudah tenggat lewat rute tetap bisa diselesaikan, rute_selesai tepat sekali")
	check(_sampai_hasil(akar) and akar.angka_hasil().tenggat_lewat and akar.angka_hasil().detik_lewat > 0, "layar hasil terbuka dan mencatat tenggat lewat (%d detik)" % (akar.angka_hasil().detik_lewat if akar.angka_hasil() != null else -1))
	check(akar.skor().koin == 0 and akar.angka_hasil().koin == 0, "koin tidak berkurang di bawah 0 (prinsip 2)")
	_bersihkan(akar)


func _test_main_lagi_mengatur_ulang() -> void:
	_judul.call("Scene rute: Main lagi dari layar hasil -> seed + 1; skor, koin, tenggat, radar, progres, rintangan, bel, oleng diatur ulang (AC-13)")
	var akar: RuteMain = await _siapkan()
	akar.atur_kidal(false)
	var tabrak: Array[String] = []
	akar.tabrakan.connect(func(jenis: String) -> void: tabrak.append(jenis))
	_taruh(akar, 3.0, -0.6, 30.0)
	while tabrak.is_empty() and _sepeda(akar).jarak_ubin < 60.0:
		akar.perbarui(DT)
	akar.ketuk_bel()
	_taruh(akar, 3.0, 0.5, 34.0)
	akar.koran = SisaKoran.awal(30)
	var pilihan: BantuLempar.Pilihan = akar.pilihan_bantu(LoperAnim.Sisi.SEBERANG)
	if pilihan != null:
		akar.call(&"_lempar", pilihan.lintasan, false)
		_langkah(akar, 60)
	akar.atur_tenggat(TenggatRute.langkah(TenggatRute.awal(PANJANG_RUTE), 95.0))
	_taruh(akar, 3.0, 0.0, PANJANG_RUTE - 0.01)
	check(_sampai_hasil(akar) and not tabrak.is_empty() and akar.skor().skor > 0, "kontrol: ada tabrakan, skor, tenggat lewat, layar hasil terbuka")
	akar.layar_hasil().tombol_main_lagi().pressed.emit()
	akar.perbarui(0.0)
	var hud: HudRute = akar.hud_rute()
	check(akar.benih() == 20261017 and not akar.hasil_tampil() and not akar.layar_hasil().tampil(), "Main lagi: seed 20261017, layar hasil tertutup")
	check(akar.tenggat().waktu_detik == 0.0 and not akar.tenggat().berhenti and akar.tenggat().tenggat_detik == TenggatRute.detik_tenggat(akar.rute().panjang_ubin) and hud.teks_tenggat().begins_with("WAKTU "), "tenggat diatur ulang untuk rute baru: jam 0, '%s'" % hud.teks_tenggat())
	check(akar.skor().skor == 0 and akar.skor().koin == 0 and akar.skor().terantar.is_empty() and hud.teks_koin() == "0" and hud.teks_skor() == "0" and hud.teks_combo() == "x1.0", "skor, koin, combo, terantar 0 (HUD juga)")
	var status: Array[ProgresRute.Status] = hud.kotak_progres().status_tampil()
	check(status.size() == 25 and status[0] == ProgresRute.Status.BERIKUTNYA and status.count(ProgresRute.Status.BELUM) == 24 and hud.teks_terkirim() == "0/25 TERKIRIM", "progres diatur ulang: kotak pertama berikutnya, sisanya belum, 0/25")
	var radar_awal: Array[String] = []
	for p: RadarRute.Penanda in RadarRute.penanda(akar.rute(), 0.0, {}, false, false):
		if p.sisi == LoperAnim.Sisi.SEBERANG:
			radar_awal.append(p.id_rumah)
	check(not radar_awal.is_empty() and _ids(hud.radar_seberang().penanda_tampil()) == radar_awal, "radar diatur ulang ke awal rute baru (%s)" % [radar_awal])
	var t: Tabrakan.Keadaan = akar.rintangan().tabrakan
	check(t.jumlah == 0 and t.jatuh_detik == 0.0 and t.kebal_detik == 0.0 and t.menempel.is_empty() and akar.bel().jumlah == 0 and not String(_sepeda(akar).nama_animasi()).begins_with("jatuh") and not String(_sepeda(akar).nama_animasi()).begins_with("terjerembab") and _sepeda(akar).alfa_sprite() == 1.0, "tabrakan, jatuh, kebal, bel, sprite jatuh dan kedip diatur ulang")
	check(hud.visible and (_anak(akar, "KontrolTouch") as KontrolTouch).is_processing_input(), "HUD tampil lagi dan kontrol sentuh membaca sentuhan lagi")
	_bersihkan(akar)
