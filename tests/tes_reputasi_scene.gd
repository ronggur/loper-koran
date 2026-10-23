class_name TesReputasiScene
extends RefCounted
## Tes scene reputasi, pelanggan, dan milestone run fase6a2-reputasi-pelanggan bagian C (AC-6, AC-12 sampai AC-14, O-8 sampai O-10): penanda reputasi di HUD rute (angka, tersembunyi tanpa keadaan,
## tidak menerima sentuhan, tidak menumpuk elemen HUD lain di empat ukuran, samping dan kidal, dengan inset), kolom samping layar hasil (reputasi + perubahan, pelanggan hanya yang bukan nol, milestone paling
## dekat, tingkat baru tercapai, tanpa nama pelanggan, empat ukuran, kasus terpadat), integrasi `RuteMain` (hasil reputasi dan milestone dari state save, denting hanya bila ada tingkat baru), dan tiga
## alur hari end-to-end dari `hari.tscn` (pemain rajin enam hari, pemain buruk tiga hari minus, milestone melompat sampai emas). `SaveManager` disuntik jalur sementara `user://tes_reputasi_scene/`;
## `user://save.json` TIDAK pernah disentuh (dicek sebelum dan sesudah).
##
## Harapan ditulis literal atau dihitung dengan cara lain (hitung kredit dan poin sendiri dari angka yang dipasang), bukan memanggil fungsi yang dites.

const BERKAS_RUTE: String = "res://scenes/rute/rute.tscn"
const BERKAS_HASIL: String = "res://scenes/ui/layar_hasil.tscn"
const BERKAS_HARI: String = "res://scenes/hari/hari.tscn"
const FOLDER_TES: String = "user://tes_reputasi_scene"
const SAVE_ASLI: String = "user://save.json"
const SKRIP_SIMPAN: String = "res://scripts/autoload/save_manager.gd"
const DT: float = 1.0 / 60.0
## [lebar jendela, tinggi jendela, lebar viewport game].
const UKURAN: Array = [[1600, 720, 800], [1920, 1080, 640], [2340, 1080, 780], [2400, 1080, 800]]

var _cek: Callable
var _judul: Callable
var _tree: SceneTree
var _simpanan_aktif: Array[Node] = []
var _kepribadian: Array[KepribadianPelanggan.Entri] = PemuatPelanggan.muat().entri


func _init(cek: Callable, judul: Callable, tree: SceneTree) -> void:
	_cek = cek
	_judul = judul
	_tree = tree


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	var sebelum: Dictionary = _jejak_save_asli()
	await _test_hud_reputasi()
	await _test_hud_tanpa_keadaan()
	await _test_layar_hasil_kanan()
	_test_bilah()
	for u: Array in UKURAN:
		await _test_layar_hasil_ukuran(u)
	await _test_rute_nyata()
	await _test_bunyi_milestone()
	await _test_alur_rajin()
	await _test_alur_buruk()
	await _test_alur_emas()
	var sesudah: Dictionary = _jejak_save_asli()
	check(sebelum == sesudah, "user://save.json tidak tersentuh oleh tes reputasi scene (%s -> %s)" % [sebelum, sesudah])


# --- Pembantu ---

func _jejak_save_asli() -> Dictionary:
	var ada: bool = FileAccess.file_exists(SAVE_ASLI)
	return {"ada": ada, "ukuran": FileAccess.get_file_as_bytes(SAVE_ASLI).size() if ada else 0, "sha": FileAccess.get_sha256(SAVE_ASLI) if ada else ""}


func _anak(akar: Node, nama: String) -> Node:
	return akar.find_child(nama, true, false)


func _sepeda(akar: Node) -> SepedaUji:
	return akar.find_child("Sepeda", true, false) as SepedaUji


func _state(reputasi: int) -> Dictionary:
	var s: Dictionary = DataSave.templat()
	s["reputasi"] = {"perumahan": reputasi}
	return s


func _siapkan(state: Dictionary, jendela: Vector2i = Vector2i(2340, 1080), hari: int = 1) -> RuteMain:
	_tree.root.size = jendela
	var akar: RuteMain = (load(BERKAS_RUTE) as PackedScene).instantiate() as RuteMain
	akar.atur_hari(hari)
	if not state.is_empty():
		akar.atur_pelanggan(state, _kepribadian)
	_tree.root.add_child(akar)
	await _tree.process_frame
	await _tree.process_frame
	akar.set_process(false)
	(_anak(akar, "KontrolTouch") as KontrolTouch).keyboard_aktif = false
	(_anak(akar, "LoperAgen") as LoperSprite).set_process(false)
	return akar


func _bersihkan(akar: AdeganJalan) -> void:
	if akar.sedang_jeda():
		akar.minta_lanjut()
	(_anak(akar, "KontrolTouch") as KontrolTouch).keyboard_aktif = OS.has_feature("editor")
	_tree.root.remove_child(akar)
	akar.free()


func _langkah(akar: AdeganJalan, jumlah: int) -> void:
	for i: int in range(jumlah):
		akar.perbarui(DT)


## Penanda reputasi di dalam layar dan tidak menumpuk elemen HUD lain; mengembalikan daftar pelanggaran (kosong = benar).
func _pelanggaran_hud(akar: RuteMain) -> Array[String]:
	var hud: HudRute = akar.hud_rute()
	var masalah: Array[String] = []
	var layar: Rect2 = Rect2(Vector2.ZERO, _tree.root.get_visible_rect().size)
	var panel: Rect2 = hud.rect_panel_reputasi()
	var lebar: int = roundi(layar.size.x)
	var pusat_bel: Vector2 = TouchZones.pusat_bel(lebar, akar.kidal(), akar.kontrol_router().geser_bel)
	var lain: Dictionary = {
		"radar seberang": hud.rect_radar_seberang(), "radar dekat": hud.rect_radar_dekat(), "panel progres": hud.rect_panel_progres(), "panel koin": hud.rect_panel_koin(), "panel skor": hud.rect_panel_skor(),
		"panel kondisi": hud.rect_panel_kondisi(), "tombol jeda": hud.rect_tombol_jeda(), "zona bel": Rect2(pusat_bel - Vector2(28, 28), Vector2(56, 56)), "panel kecepatan": hud.rect_panel_kecepatan(),
		"panel koran": hud.rect_panel_koran(), "zona stick": TouchZones.rect_stick(lebar, akar.kidal()),
		"kartu misi": Rect2(Vector2(Config.MISI_KARTU_X_PX, Config.MISI_KARTU_Y_PX), Vector2(Config.MISI_KARTU_LEBAR_PX, 28)),
		"banner misi": Rect2(Vector2(layar.size.x * 0.5 - 120.0, Config.MISI_BANNER_Y_PX), Vector2(240, 26)),
	}
	if not layar.encloses(panel):
		masalah.append("di luar layar %s" % panel)
	for nama: String in lain:
		if panel.intersects(lain[nama]):
			masalah.append("menumpuk %s" % nama)
	return masalah


func _atur_inset(akar: RuteMain, awal_x: int, atas: int, akhir_x: int, bawah: int) -> void:
	var inset: ZonaAman.Inset = ZonaAman.Inset.new()
	inset.awal_x = awal_x
	inset.akhir_x = akhir_x
	inset.atas = atas
	inset.bawah = bawah
	akar.hud_rute().atur_inset(inset)


# --- HUD ---

func _test_hud_reputasi() -> void:
	_judul.call("HUD rute: penanda reputasi (angka bulat 0..100, ikon) di baris 3 samping atas, tidak menumpuk elemen lain di empat ukuran, samping dan kidal, dengan inset (O-10, AC-13, AC-14)")
	for u: Array in UKURAN:
		var akar: RuteMain = await _siapkan(_state(37), Vector2i(u[0], u[1]))
		var hud: HudRute = akar.hud_rute()
		check(hud.reputasi_tampil() and hud.teks_reputasi() == "37", "%d: penanda reputasi tampil '37', dapat '%s'" % [u[0], hud.teks_reputasi()])
		var samping: Rect2 = hud.rect_panel_reputasi()
		var kondisi: Rect2 = hud.rect_panel_kondisi()
		check(absf(samping.end.x - kondisi.end.x) < 0.5 and samping.position.y >= kondisi.end.y + float(Config.HUD_PANEL_JARAK_PX) - 0.5 and samping.size.x >= float(Config.HUD_IKON_PX), "%d: rata samping dengan panel kondisi, di bawahnya berjarak 5: %s di bawah %s" % [u[0], samping, kondisi])
		check(_pelanggaran_hud(akar).is_empty(), "%d samping: tanpa pelanggaran tata letak: %s" % [u[0], _pelanggaran_hud(akar)])
		akar.atur_kidal(true)
		akar.perbarui(0.0)
		check(hud.rect_panel_reputasi() == samping, "%d kidal: penanda reputasi tidak dicerminkan (posisi sama)" % u[0])
		check(_pelanggaran_hud(akar).is_empty(), "%d kidal: tanpa pelanggaran tata letak: %s" % [u[0], _pelanggaran_hud(akar)])
		akar.atur_kidal(false)
		_atur_inset(akar, 20, 16, 24, 18)
		akar.perbarui(0.0)
		await _tree.process_frame
		var geser: Rect2 = hud.rect_panel_reputasi()
		var kondisi_geser: Rect2 = hud.rect_panel_kondisi()
		check(geser.position.y > samping.position.y and geser.end.x < samping.end.x, "%d inset: penanda turun dan masuk dari tepi: %s -> %s" % [u[0], samping, geser])
		check(geser.position.y - samping.position.y == kondisi_geser.position.y - kondisi.position.y and geser.end.x - samping.end.x == kondisi_geser.end.x - kondisi.end.x, "%d inset: penanda bergeser sama besar dengan panel kondisi (satu kolom): %s -> %s" % [u[0], samping, geser])
		check(geser.end.x <= float(u[2]) - 20.0 and geser.position.y >= 8.0 + 12.0, "%d inset: penanda di dalam zona aman (samping paling jauh %.0f, atas paling dekat 20)" % [u[0], float(u[2]) - 20.0])
		check(_pelanggaran_hud(akar).is_empty(), "%d inset: tanpa pelanggaran tata letak: %s" % [u[0], _pelanggaran_hud(akar)])
		_bersihkan(akar)


func _test_hud_tanpa_keadaan() -> void:
	_judul.call("HUD rute: tanpa keadaan pelanggan tersembunyi; 0 dan 100 tampil apa adanya; nilai tidak berubah selama rute; tidak menerima sentuhan")
	var sendiri: RuteMain = await _siapkan({})
	check(not sendiri.hud_rute().reputasi_tampil() and sendiri.hud_rute().teks_reputasi() == "", "rute yang dijalankan sendiri: penanda reputasi tersembunyi")
	_bersihkan(sendiri)
	for nilai: int in [0, 100]:
		var akar: RuteMain = await _siapkan(_state(nilai))
		check(akar.hud_rute().reputasi_tampil() and akar.hud_rute().teks_reputasi() == str(nilai), "reputasi %d tampil '%d'" % [nilai, nilai])
		_bersihkan(akar)
	var di_luar: RuteMain = await _siapkan(_state(50))
	di_luar.hud_rute().tampilkan_reputasi(150)
	check(di_luar.hud_rute().teks_reputasi() == "100", "reputasi di atas 100 dijepit tampil '100', dapat '%s'" % di_luar.hud_rute().teks_reputasi())
	di_luar.hud_rute().tampilkan_reputasi(-5)
	check(not di_luar.hud_rute().reputasi_tampil(), "reputasi negatif = penanda tersembunyi")
	_bersihkan(di_luar)
	var akar2: RuteMain = await _siapkan(_state(55))
	_langkah(akar2, 300)
	check(akar2.hud_rute().teks_reputasi() == "55", "reputasi tetap 55 selama rute berjalan (berubah hanya di akhir hari)")
	var panel: PanelContainer = _anak(akar2.hud_rute(), "PanelReputasi") as PanelContainer
	var semua_abaikan: bool = panel.mouse_filter == Control.MOUSE_FILTER_IGNORE
	for c: Node in [_anak(akar2.hud_rute(), "IsiReputasi"), _anak(akar2.hud_rute(), "IkonReputasi"), _anak(akar2.hud_rute(), "AngkaReputasi")]:
		semua_abaikan = semua_abaikan and (c as Control).mouse_filter == Control.MOUSE_FILTER_IGNORE
	check(semua_abaikan, "panel reputasi dan isinya MOUSE_FILTER_IGNORE (tidak menangkap sentuhan)")
	var ikon: TextureRect = _anak(akar2.hud_rute(), "IkonReputasi") as TextureRect
	check(ikon.texture != null and ikon.texture.get_size() == Vector2(14, 14), "ikon reputasi 14x14 (ui_icon_reputasi)")
	_bersihkan(akar2)


# --- Layar hasil ---

func _angka(terkirim: int, koin: int, terbuang: int) -> HasilRute.Angka:
	var a: HasilRute.Angka = HasilRute.Angka.new()
	a.pelanggan = 25
	a.terkirim = terkirim
	a.meleset = 25 - terkirim
	a.koin = koin
	a.skor = 1000
	a.lempar_terbuang = terbuang
	a.potongan = terbuang * Config.KOIN_POTONGAN_KORAN_MELESET
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
			p.id_rumah = "per_buka_01@%d" % n
			h.peristiwa.append(p)
	return h


func _ms_state(setia: int, koin_total: int, misi: int, servis: int, level: int) -> Dictionary:
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
	s["sepeda"]["ban"]["level"] = level
	return s


func _layar() -> LayarHasil:
	var l: LayarHasil = (load(BERKAS_HASIL) as PackedScene).instantiate() as LayarHasil
	_tree.root.add_child(l)
	return l


func _test_layar_hasil_kanan() -> void:
	_judul.call("Layar hasil: kolom samping (reputasi + perubahan, pelanggan bukan nol, milestone paling dekat, tingkat baru) dan tanpa keduanya tidak berubah (AC-13)")
	_tree.root.size = Vector2i(2340, 1080)
	# Tanpa data: kolom samping tersembunyi dan teks sama dengan layar lama.
	var tanpa: LayarHasil = _layar()
	await _tree.process_frame
	tanpa.isi(_angka(20, 300, 0))
	var teks_lama: Array[String] = tanpa.teks_tampil()
	check(not tanpa.kanan_tampil() and tanpa.teks_reputasi() == "" and tanpa.teks_pelanggan().is_empty() and tanpa.teks_target() == "" and tanpa.teks_baru().is_empty(), "tanpa reputasi dan milestone: kolom samping tersembunyi")
	check(teks_lama == ["Hasil antaran", "Terkirim", "20/25", "Tip", "+0 dari 0 pelanggan", "Koin", "300", "Skor", "1.000", "Tepat", "0", "Meleset", "5", "Sampai sebelum tenggat"], "tanpa data: teks layar hanya bagian lama: %s" % [teks_lama])
	tanpa.queue_free()
	# Hari biasa.
	var l: LayarHasil = _layar()
	await _tree.process_frame
	l.isi(_angka(22, 380, 0), null, [] as Array[String], 120, _rep(10, 12, [3, 0, 0, 0]), MilestoneTracker.ringkas(_ms_state(1, 700, 0, 0, 0), _ms_state(1, 1080, 0, 0, 0)))
	check(l.kanan_tampil() and l.teks_reputasi() == "12 (+2)", "reputasi '12 (+2)', dapat '%s'" % l.teks_reputasi())
	check(l.teks_pelanggan() == ["Pelanggan baru: 3"], "hanya pelanggan baru 3 (setia, berhenti, kembali nol tidak tampil): %s" % [l.teks_pelanggan()])
	check(l.teks_target() == "Pelanggan tetap · Perunggu 1/3" and is_equal_approx(l.pecahan_bilah(), 1.0 / 3.0), "milestone terdekat: pelanggan tetap 1/3 menuju perunggu (pecahan 1/3, bukan koin 1080/5000=0,22): '%s' %.3f" % [l.teks_target(), l.pecahan_bilah()])
	check(l.teks_baru() == ["Baru: Koin terkumpul · Perunggu"], "tingkat baru: koin 700 -> 1080 melewati 1000: %s" % [l.teks_baru()])
	check(l.tekstur_target() == l.LENCANA[0] and l.tekstur_baru() == [l.LENCANA[0]], "lencana: target menuju perunggu (indeks 0) dan baru perunggu")
	check(l.teks_tampil().has("Reputasi 12 (+2)"), "teks_tampil memuat baris reputasi")
	# Warna perubahan: naik OK, nol dan turun TEXT_2.
	var nilai: Label = l.find_child("NilaiReputasi", true, false) as Label
	check(nilai.get_theme_color(&"font_color") == Palette.OK, "reputasi naik: nilai berwarna OK")
	l.isi(_angka(20, 300, 0), null, [] as Array[String], -1, _rep(30, 29, [0, 0, 1, 0]), null)
	check(l.teks_reputasi() == "29 (-1)" and nilai.get_theme_color(&"font_color") == Palette.TEXT_2, "reputasi turun: '29 (-1)' netral TEXT_2 (bukan merah): '%s'" % l.teks_reputasi())
	check(l.teks_pelanggan() == ["Berhenti berlangganan: 1"] and l.teks_target() == "" and l.teks_baru().is_empty(), "tanpa milestone: bagian target dan baru tersembunyi; berhenti 1 tampil: %s" % [l.teks_pelanggan()])
	l.isi(_angka(20, 300, 0), null, [] as Array[String], -1, _rep(50, 50, [0, 0, 0, 0]), null)
	check(l.teks_reputasi() == "50 (+0)" and l.teks_pelanggan().is_empty(), "perubahan nol: '50 (+0)' dan bagian pelanggan tersembunyi")
	check(nilai.get_theme_color(&"font_color") == Palette.TEXT_2, "perubahan nol: nilai netral TEXT_2 (hanya kenaikan yang OK)")
	# Empat jenis.
	l.isi(_angka(20, 300, 0), null, [] as Array[String], -1, _rep(30, 29, [2, 1, 1, 1]), null)
	check(l.teks_pelanggan() == ["Pelanggan baru: 2", "Jadi pelanggan tetap: 1", "Berhenti berlangganan: 1", "Berlangganan lagi: 1"], "empat jenis tampil urut: %s" % [l.teks_pelanggan()])
	# Tanpa nama pelanggan: tidak ada id rumah ("@") atau nama di teks.
	var semua: String = " ".join(l.teks_tampil())
	check(not semua.contains("@") and not semua.contains("per_buka"), "teks tidak memuat id rumah atau nama pelanggan")
	# Tiga tingkat baru dibatasi MILESTONE_BARU_MAKS_TAMPIL (3) walau empat milestone naik; tertinggi dulu.
	var ringkas: MilestoneTracker.Ringkasan = MilestoneTracker.ringkas(_ms_state(0, 0, 0, 0, 0), _ms_state(3, 6000, 1, 4, 0))
	check(ringkas.baru.size() == 4, "kontrol: empat milestone naik sekaligus")
	l.isi(_angka(20, 300, 0), null, [] as Array[String], -1, _rep(30, 32, [0, 0, 0, 0]), ringkas)
	check(l.teks_baru().size() == Config.MILESTONE_BARU_MAKS_TAMPIL and l.teks_baru()[0] == "Baru: Koin terkumpul · Perak" and l.tekstur_baru()[0] == l.LENCANA[1], "tampil paling banyak 3, tertinggi dulu (koin perak): %s" % [l.teks_baru()])
	# Semua emas.
	l.isi(_angka(25, 500, 0), null, [] as Array[String], -1, _rep(90, 92, [0, 0, 0, 0]), MilestoneTracker.ringkas(_ms_state(25, 20000, 5, 10, 0), _ms_state(25, 20500, 5, 10, 0)))
	check(l.teks_target() == "Semua target sudah emas" and l.pecahan_bilah() == -1.0 and l.teks_baru().is_empty(), "semua emas: teks tamat, tanpa bilah, tanpa baru: '%s'" % l.teks_target())
	# Angka besar: pemisah ribuan.
	l.isi(_angka(20, 300, 0), null, [] as Array[String], -1, _rep(50, 51, [0, 0, 0, 0]), MilestoneTracker.ringkas(_ms_state(0, 5100, 5, 10, 0), _ms_state(0, 5100, 5, 10, 0)))
	check(l.teks_target() == "Koin terkumpul · Emas 5.100/15.000", "koin 5100 menuju emas 15000 dengan pemisah ribuan: '%s'" % l.teks_target())
	l.queue_free()


func _test_bilah() -> void:
	_judul.call("BilahMilestone: lebar isi menurut pecahan (bilah bukan satu-satunya pembawa informasi, tetap tepat)")
	check(BilahMilestone.lebar_isi(100, 0.0) == 0 and BilahMilestone.lebar_isi(100, 1.0) == 98 and BilahMilestone.lebar_isi(100, 0.5) == 49, "lebar 100: pecahan 0 -> 0, 1 -> 98, 0,5 -> 49")
	check(BilahMilestone.lebar_isi(100, 0.001) == 1 and BilahMilestone.lebar_isi(100, 0.9999) == 97, "pecahan sangat kecil tetap 1 px; 0,9999 belum penuh (97)")
	check(BilahMilestone.lebar_isi(1, 1.0) == 0 and BilahMilestone.lebar_isi(0, 0.5) == 0, "bilah tanpa ruang dalam = 0")


func _test_layar_hasil_ukuran(u: Array) -> void:
	_judul.call("Layar hasil %dx%d (viewport %d): kasus terpadat (potongan + rekap misi + tiga baris kondisi + saldo dijepit + reputasi + empat pelanggan + milestone + tiga baru + tenggat lewat) muat, tombol >= 42 px (AC-14)" % [u[0], u[1], u[2]])
	_tree.root.size = Vector2i(u[0], u[1])
	var l: LayarHasil = _layar()
	await _tree.process_frame
	await _tree.process_frame
	var angka: HasilRute.Angka = _angka(2, 150, 25)
	angka.tenggat_lewat = true
	angka.detik_lewat = 72
	angka.misi_hasil = "selesai"
	angka.koin_misi = 75
	var misi: DataMisi = PemuatMisi.muat_folder().cari("p1_kucing")
	var ringkas: MilestoneTracker.Ringkasan = MilestoneTracker.ringkas(_ms_state(2, 990, 0, 0, 0), _ms_state(10, 5100, 1, 4, 0))
	l.atur_mode_hari(true)
	l.isi(angka, misi, ["ban", "rem", "rantai"] as Array[String], 10, _rep(55, 53, [4, 3, 2, 1]), ringkas)
	l.tampilkan(true)
	await _tree.process_frame
	await _tree.process_frame
	var layar: Rect2 = Rect2(Vector2.ZERO, _tree.root.get_visible_rect().size)
	var panel: Rect2 = l.rect_panel()
	var tombol: Rect2 = l.rect_tombol()
	check(layar.encloses(panel) and panel.encloses(tombol), "%d: panel %s di dalam layar %s dan tombol di dalam panel" % [u[0], panel, layar])
	check(tombol.size.y >= 42.0 and tombol.size.x >= 96.0, "%d: tombol 'Ke bengkel' >= 42 px game dan terlihat penuh: %s" % [u[0], tombol.size])
	var dalam: bool = true
	var tumpang: bool = false
	for r: Rect2 in l.rect_label():
		dalam = dalam and panel.encloses(r)
		tumpang = tumpang or r.intersects(tombol)
	check(dalam and not tumpang, "%d: semua label utama di dalam panel dan tidak menumpuk tombol" % u[0])
	var samping: Rect2 = l.rect_panel_kanan()
	var isi_kanan: Array[Rect2] = l.rect_isi_kanan()
	dalam = panel.encloses(samping) and not samping.intersects(tombol)
	for r: Rect2 in isi_kanan:
		dalam = dalam and samping.encloses(r)
		tumpang = tumpang or r.intersects(tombol)
	check(dalam and not tumpang and isi_kanan.size() >= 14, "%d: kolom samping dan %d isinya di dalam panel samping dan tidak menumpuk tombol" % [u[0], isi_kanan.size()])
	check(panel.size.y <= layar.size.y - 2.0 * float(Config.HUD_MARGIN_TEPI_PX), "%d: tinggi panel %.0f muat dengan margin tepi di %.0f" % [u[0], panel.size.y, layar.size.y])
	# Inset aman terbesar yang dipakai probe (utama 20, atas 16, samping 24, bawah 18): panel dan tombol tetap di dalam zona aman.
	var aman: Rect2 = Rect2(Vector2(20, 16), layar.size - Vector2(44, 34))
	check(aman.encloses(panel) and aman.encloses(tombol), "%d: panel dan tombol di dalam zona aman 20/16/24/18" % u[0])
	check(l.teks_reputasi() == "53 (-2)" and l.teks_pelanggan().size() == 4 and l.teks_baru().size() == 3, "%d: reputasi, empat pelanggan, tiga baru tampil" % u[0])
	# Tanpa kolom samping (rute yang dijalankan sendiri): kasus yang sama tetap muat dan tidak melar (lebar sekitar 300, bukan hasil autowrap yang runtuh).
	angka.misi_hasil = ""
	l.isi(angka, null, ["ban", "rem", "rantai"] as Array[String], 10)
	await _tree.process_frame
	await _tree.process_frame
	var polos: Rect2 = l.rect_panel()
	check(not l.kanan_tampil() and polos.size.x >= 296.0 and polos.size.x <= 310.0 and polos.size.y <= 300.0 and layar.encloses(polos) and l.rect_tombol().size.y >= 42.0, "%d: tanpa kolom samping dan tanpa rekap misi panel %s tetap sekitar 300 lebar dan di dalam layar" % [u[0], polos.size])
	l.queue_free()


# --- RuteMain nyata ---

## Menyelesaikan rute sampai layar hasil dengan skor literal: `koin` kotor, `terbuang`, dan `antar` pelanggan pertama terantar dengan kualitas `kualitas`.
func _selesaikan(rute: RuteMain, koin: int, terbuang: int, antar: int, kualitas: int = SkorRute.Kualitas.TEPAT) -> void:
	var skor: SkorRute.Keadaan = rute.skor()
	skor.koin = koin
	skor.terbuang = terbuang
	skor.skor = 900
	for i: int in range(antar):
		var id: String = rute.rute().pelanggan[i].id
		skor.terantar[id] = true
		skor.kualitas[id] = kualitas
	var sepeda: SepedaUji = _sepeda(rute)
	var k: BikeMotion.Keadaan = sepeda.keadaan.salin()
	k.kecepatan_ud = Config.KECEPATAN_SANTAI_UD
	sepeda.keadaan = k
	sepeda.jarak_ubin = rute.rute().panjang_ubin - 0.01
	for i: int in range(900):
		if rute.hasil_tampil():
			return
		rute.perbarui(DT)


func _test_rute_nyata() -> void:
	_judul.call("RuteMain: hasil reputasi dan milestone dari state save, kolom samping terisi; rute tanpa keadaan tanpa keduanya (AC-6, AC-13)")
	var s: Dictionary = _state(20)
	s["koin_total"] = 940
	var akar: RuteMain = await _siapkan(s, Vector2i(2340, 1080), 3)
	check(akar.hasil_milestone() == null and akar.hasil_reputasi() == null, "sebelum layar hasil: tidak ada hasil")
	# 20 antaran tepat: kredit 20 x 4 = 80, 80 / 30 = 2 poin (dihitung sendiri).
	_selesaikan(akar, 300, 2, 20)
	var rep: ReputationManager.Hasil = akar.hasil_reputasi()
	var ms: MilestoneTracker.Ringkasan = akar.hasil_milestone()
	check(rep != null and ms != null and rep.reputasi_sebelum == 20 and rep.reputasi_sesudah == 22 and rep.perubahan == 2, "20 antaran tepat: reputasi 20 -> 22 (+2)")
	check(akar.layar_hasil().kanan_tampil() and akar.layar_hasil().teks_reputasi() == "22 (+2)", "layar hasil: '22 (+2)', dapat '%s'" % akar.layar_hasil().teks_reputasi())
	var koin_total: MilestoneTracker.Status = null
	for st: MilestoneTracker.Status in ms.daftar:
		if st.id == "koin_total":
			koin_total = st
	check(koin_total != null and koin_total.nilai == 940 + 300 and koin_total.tingkat == 1, "milestone koin_total sesudah hari = 940 + koin kotor 300 = 1240 (potongan 10 tidak mengurangi), perunggu")
	check(ms.baru.size() == 1 and ms.baru[0].id == "koin_total" and ms.baru[0].tingkat == 1, "tingkat baru: tepat satu, koin_total perunggu")
	check(akar.layar_hasil().teks_baru() == ["Baru: Koin terkumpul · Perunggu"], "layar hasil memuat baris baru: %s" % [akar.layar_hasil().teks_baru()])
	check(akar.hasil_milestone() == ms and akar.hasil_reputasi() == rep, "hasil tetap objek yang sama sesudah dibaca lagi (dihitung sekali)")
	_bersihkan(akar)
	# Tanpa keadaan pelanggan.
	var sendiri: RuteMain = await _siapkan({})
	_selesaikan(sendiri, 100, 0, 5)
	check(sendiri.hasil_milestone() == null and sendiri.hasil_reputasi() == null and not sendiri.layar_hasil().kanan_tampil(), "rute tanpa keadaan: tanpa hasil reputasi dan milestone, kolom samping tersembunyi")
	_bersihkan(sendiri)


func _test_bunyi_milestone() -> void:
	_judul.call("Bunyi milestone: denting hanya bila ada tingkat baru tercapai, tepat sekali per hari (AC-15)")
	var audio: Node = _tree.root.get_node_or_null(^"Audio")
	if audio == null:
		check(false, "autoload Audio ada")
		return
	var dummy_lama: bool = bool(audio.get(&"putar_di_driver_dummy"))
	audio.set(&"putar_di_driver_dummy", true)
	var s1: Dictionary = _state(0)
	s1["koin_total"] = 950
	var a1: RuteMain = await _siapkan(s1)
	var n0: int = int(audio.call(&"jumlah_bunyi_milestone"))
	_selesaikan(a1, 100, 0, 0)
	check(int(audio.call(&"jumlah_bunyi_milestone")) == n0 + 1 and a1.hasil_milestone().baru.size() == 1, "950 + 100 = 1050 melewati 1000: satu denting")
	var pemutar: AudioStreamPlayer = audio.call(&"pemutar_milestone")
	check(pemutar != null and pemutar.bus == &"SFX" and is_equal_approx(pemutar.volume_db, Config.AUDIO_MILESTONE_VOLUME_DB) and pemutar.playing, "pemutar di bus SFX, volume Config, sedang berbunyi")
	audio.call(&"hentikan_lempar")
	check(not pemutar.playing, "hentikan_lempar menghentikan denting")
	_bersihkan(a1)
	var s2: Dictionary = _state(0)
	s2["koin_total"] = 100
	var a2: RuteMain = await _siapkan(s2)
	var n1: int = int(audio.call(&"jumlah_bunyi_milestone"))
	_selesaikan(a2, 100, 0, 0)
	check(int(audio.call(&"jumlah_bunyi_milestone")) == n1 and a2.hasil_milestone().baru.is_empty(), "100 + 100 = 200 tidak melewati milestone: tanpa denting")
	_bersihkan(a2)
	audio.set(&"putar_di_driver_dummy", dummy_lama)
	check(BunyiMilestone.berbunyi(1) and BunyiMilestone.berbunyi(3) and not BunyiMilestone.berbunyi(0), "BunyiMilestone.berbunyi: hanya bila ada tingkat baru")


# --- Alur hari ---

func _jalur() -> String:
	return FOLDER_TES.path_join("save.json")


func _bersihkan_folder() -> void:
	var dir: DirAccess = DirAccess.open(FOLDER_TES)
	if dir == null:
		return
	for nama: String in dir.get_files():
		DirAccess.remove_absolute(FOLDER_TES.path_join(nama))
	DirAccess.remove_absolute(FOLDER_TES)


func _tulis_save(s: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(FOLDER_TES)
	var berkas: FileAccess = FileAccess.open(_jalur(), FileAccess.WRITE)
	berkas.store_string(DataSave.ke_teks(s))
	berkas.close()


func _baca_save() -> Dictionary:
	return DataSave.dari_teks(FileAccess.get_file_as_string(_jalur())).state


func _manajer() -> Node:
	var m: Node = (load(SKRIP_SIMPAN) as GDScript).new()
	m.set(&"jalur", _jalur())
	m.set(&"lapor_ke_log", false)
	m.call(&"muat", 1700000000)
	_simpanan_aktif.append(m)
	return m


func _siapkan_hari(m: Node) -> HariMain:
	_tree.root.size = Vector2i(2340, 1080)
	var hari: HariMain = (load(BERKAS_HARI) as PackedScene).instantiate() as HariMain
	hari.simpanan = m
	hari.panggil_quit = false
	_tree.root.add_child(hari)
	await _tree.process_frame
	await _tree.process_frame
	return hari


func _berangkat(hari: HariMain) -> RuteMain:
	hari.koran().tombol_berangkat().ditekan.emit()
	await _tree.process_frame
	await _tree.process_frame
	var rute: RuteMain = hari.rute()
	rute.set_process(false)
	(_anak(rute, "KontrolTouch") as KontrolTouch).keyboard_aktif = false
	(_anak(rute, "LoperAgen") as LoperSprite).set_process(false)
	return rute


func _bersihkan_hari(hari: HariMain) -> void:
	var rute: RuteMain = hari.rute()
	if rute != null:
		if rute.sedang_jeda():
			rute.minta_lanjut()
		(_anak(rute, "KontrolTouch") as KontrolTouch).keyboard_aktif = OS.has_feature("editor")
	_tree.root.remove_child(hari)
	hari.free()


func _tutup_manajer(m: Node) -> void:
	_simpanan_aktif.erase(m)
	m.free()


## Satu hari penuh dari koran sampai "Hari berikutnya" (tanpa belanja): selesaikan rute dengan skor literal, lewati bengkel. Mengembalikan kamus hasil yang dicatat tes.
func _satu_hari(hari: HariMain, koin: int, terbuang: int, antar: int) -> Dictionary:
	var rute: RuteMain = await _berangkat(hari)
	var hasil: Dictionary = {"hud_reputasi": rute.hud_rute().teks_reputasi(), "hari": hari.status().hari}
	var audio: Node = _tree.root.get_node_or_null(^"Audio")
	var bunyi_awal: int = int(audio.call(&"jumlah_bunyi_milestone")) if audio != null else 0
	_selesaikan(rute, koin, terbuang, antar)
	hasil["bunyi"] = (int(audio.call(&"jumlah_bunyi_milestone")) - bunyi_awal) if audio != null else -1
	var layar: LayarHasil = rute.layar_hasil()
	hasil["rep"] = layar.teks_reputasi()
	hasil["baru"] = layar.teks_baru()
	hasil["target"] = layar.teks_target()
	hasil["pelanggan"] = layar.teks_pelanggan()
	hasil["hasil_rep"] = rute.hasil_reputasi()
	hasil["hasil_ms"] = rute.hasil_milestone()
	hasil["tombol"] = layar.tombol_main_lagi().text
	hasil["teks"] = layar.teks_tampil()
	layar.tombol_main_lagi().ditekan.emit()
	var bengkel: LayarBengkel = hari.bengkel()
	hasil["bengkel_ada"] = bengkel != null
	if bengkel != null:
		bengkel.tombol_hari_berikutnya().ditekan.emit()
	hasil["save"] = _baca_save()
	return hasil


func _test_alur_rajin() -> void:
	_judul.call("Alur hari 1: pemain rajin enam hari (25 antaran tepat, koin 300 per hari): reputasi naik 3 per hari, HUD hari berikutnya = save, denting koin_total tepat saat melewati 1000 di hari 4, save tanpa field milestone")
	_bersihkan_folder()
	_tulis_save(DataSave.templat())
	var m: Node = _manajer()
	var hari: HariMain = await _siapkan_hari(m)
	var audio: Node = _tree.root.get_node_or_null(^"Audio")
	var rep_save: int = 0
	var koin_total: int = 0
	for h: int in range(1, 7):
		var r: Dictionary = await _satu_hari(hari, 300, 0, 25)
		# Kredit 25 x 4 = 100; 100 / 30 = 3 poin tiap hari (dihitung sendiri); reputasi hari h = 3h.
		var rep_diharap: int = mini(rep_save + 3, 100)
		var rep: ReputationManager.Hasil = r["hasil_rep"]
		var save: Dictionary = r["save"]
		check(r["hari"] == h and r["hud_reputasi"] == str(rep_save), "hari %d: HUD menampilkan reputasi save kemarin (%d), dapat '%s'" % [h, rep_save, r["hud_reputasi"]])
		check(rep != null and rep.perubahan == 3 and r["rep"] == "%d (+3)" % rep_diharap, "hari %d: layar hasil '%d (+3)', dapat '%s'" % [h, rep_diharap, r["rep"]])
		check(int(save["reputasi"]["perumahan"]) == rep_diharap and int(save["hari"]) == h + 1, "hari %d: save reputasi %d dan hari %d" % [h, rep_diharap, h + 1])
		check(r["bengkel_ada"] and r["tombol"] == "BENGKEL_BUKA", "hari %d: alur Hasil -> Bengkel -> Hari berikutnya berjalan" % h)
		koin_total += 300
		check(int(save["koin_total"]) == koin_total, "hari %d: koin_total %d" % [h, koin_total])
		var tingkat_koin_baru: bool = koin_total >= 1000 and koin_total - 300 < 1000
		var ada_koin: bool = false
		for t: String in r["baru"]:
			ada_koin = ada_koin or t.begins_with("Baru: Koin terkumpul")
		check(ada_koin == tingkat_koin_baru, "hari %d: baris 'Baru: Koin terkumpul' tampil tepat saat total melewati 1000 (hari 4): %s" % [h, r["baru"]])
		if audio != null:
			var harap_bunyi: int = 1 if not r["baru"].is_empty() else 0
			check(r["bunyi"] == harap_bunyi, "hari %d: denting %d kali (tepat satu bila ada baris Baru, selain itu nol): %s" % [h, harap_bunyi, r["baru"]])
		var punya_milestone: bool = false
		for k: String in save:
			punya_milestone = punya_milestone or k.contains("milestone")
		check(not punya_milestone, "hari %d: save tanpa field milestone" % h)
		rep_save = rep_diharap
	check(rep_save == 18, "enam hari rajin: reputasi 18 (3 per hari)")
	var akhir: Dictionary = _baca_save()
	var jumlah_setia: int = 0
	for id: String in akhir["pelanggan"]:
		if akhir["pelanggan"][id]["status"] == "setia":
			jumlah_setia += 1
	check(akhir["pelanggan"].size() > 0, "pelanggan tetap tercatat di save sesudah enam hari (%d entri, %d setia)" % [akhir["pelanggan"].size(), jumlah_setia])
	_bersihkan_hari(hari)
	_tutup_manajer(m)
	_bersihkan_folder()


func _test_alur_buruk() -> void:
	_judul.call("Alur hari 2: pemain buruk tiga hari (tanpa antaran, 25 koran terbuang): hari minus netral, reputasi tidak pernah di bawah 0, tidak ada tingkat baru, tidak ada jalan buntu")
	_bersihkan_folder()
	var s: Dictionary = DataSave.templat()
	s["koin"] = 60
	s["koin_total"] = 60
	s["reputasi"] = {"perumahan": 1}
	_tulis_save(s)
	var m: Node = _manajer()
	var hari: HariMain = await _siapkan_hari(m)
	var rep_save: int = 1
	for h: int in range(1, 4):
		var r: Dictionary = await _satu_hari(hari, 0, 25, 0)
		var save: Dictionary = r["save"]
		var rep: ReputationManager.Hasil = r["hasil_rep"]
		check(r["hud_reputasi"] == str(rep_save), "hari %d: HUD reputasi %d" % [h, rep_save])
		check(rep.reputasi_sesudah >= 0 and rep.reputasi_sesudah <= rep_save and rep.perubahan <= 0, "hari %d: reputasi tidak naik dan tidak di bawah 0 (%d -> %d)" % [h, rep.reputasi_sebelum, rep.reputasi_sesudah])
		check(int(save["reputasi"]["perumahan"]) == rep.reputasi_sesudah and int(save["reputasi"]["perumahan"]) >= 0, "hari %d: save reputasi %d sama dengan layar hasil" % [h, int(save["reputasi"]["perumahan"])])
		check(int(save["koin"]) == 0 and int(save["koin_total"]) == 60 and int(save["hari"]) == h + 1, "hari %d: saldo dijepit 0, koin_total tetap 60, hari %d (hari berikutnya tidak buntu)" % [h, h + 1])
		check(r["baru"].is_empty() and r["bengkel_ada"], "hari %d: tidak ada tingkat baru; bengkel tetap terbuka" % h)
		check(not " ".join(r["teks"]).to_lower().contains("gagal"), "hari %d: layar hasil hari minus netral, tanpa kata 'gagal': %s" % [h, r["teks"]])
		rep_save = int(save["reputasi"]["perumahan"])
	_bersihkan_hari(hari)
	_tutup_manajer(m)
	_bersihkan_folder()


func _test_alur_emas() -> void:
	_judul.call("Alur hari 3: koin_total 14900 + 200 melewati emas, 24 pelanggan setia dan 4 misi selesai belum emas: hanya koin_total yang baru, terdekat pelanggan tetap 24/25, denting sekali")
	_bersihkan_folder()
	var s: Dictionary = _ms_state(24, 14900, 4, 0, 0)
	s["koin"] = 500
	_tulis_save(s)
	var m: Node = _manajer()
	var hari: HariMain = await _siapkan_hari(m)
	var audio: Node = _tree.root.get_node_or_null(^"Audio")
	var r: Dictionary = await _satu_hari(hari, 200, 0, 0)
	var ms: MilestoneTracker.Ringkasan = r["hasil_ms"]
	var ids: Array[String] = []
	for c: MilestoneTracker.Capaian in ms.baru:
		ids.append("%s:%d" % [c.id, c.tingkat])
	check(ids == ["koin_total:3"], "hanya koin_total emas yang baru (pelanggan tetap 24 < 25, misi 4 < 5): %s" % [ids])
	check(r["baru"] == ["Baru: Koin terkumpul · Emas"], "layar hasil: 'Baru: Koin terkumpul · Emas': %s" % [r["baru"]])
	check(ms.terdekat != null and ms.terdekat.id == "pelanggan_tetap" and ms.terdekat.nilai == 24 and ms.terdekat.target == 25, "terdekat: pelanggan tetap 24/25 (0,96) menuju emas")
	check(r["target"] == "Pelanggan tetap · Emas 24/25", "teks target: '%s'" % r["target"])
	if audio != null:
		check(r["bunyi"] == 1, "denting tepat sekali: %s" % r["bunyi"])
	check(int(r["save"]["koin_total"]) == 15100, "save koin_total 15100")
	_bersihkan_hari(hari)
	_tutup_manajer(m)
	_bersihkan_folder()
