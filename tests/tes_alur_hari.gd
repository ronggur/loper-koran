class_name TesAlurHari
extends RefCounted
## Tes alur satu hari run fase4a-koran-hari (AC-13 sampai AC-20, AC-25): `scenes/hari/hari.tscn` sungguhan dengan `SaveManager` yang disuntik jalur
## sementara (`user://tes_save_4a_alur/`; TIDAK PERNAH menyentuh `user://save.json`, dicek sebelum dan sesudah). Tombol ditekan lewat `ditekan.emit()`,
## rute diselesaikan dengan pembantu tes (sepeda diloncatkan ke dekat garis akhir seperti di `tes_hud_rute_scene`), dan angka hasil dibuat tes
## sendiri (literal) lalu dibandingkan dengan isi save: koin 120 (tip 25), skor 1500, terkirim 3 dari 25.

const BERKAS_HARI: String = "res://scenes/hari/hari.tscn"
const FOLDER_TES: String = "user://tes_save_4a_alur"
const SAVE_ASLI: String = "user://save.json"
const SKRIP_SIMPAN: String = "res://scripts/autoload/save_manager.gd"
const DT: float = 1.0 / 60.0

var _cek: Callable
var _judul: Callable
var _tree: SceneTree
var _simpanan_aktif: Array[Node] = []


func _init(cek: Callable, judul: Callable, tree: SceneTree) -> void:
	_cek = cek
	_judul = judul
	_tree = tree


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	var sebelum: Dictionary = _jejak_save_asli()
	await _test_satu_hari_utuh()
	await _test_simpan_hanya_akhir_hari()
	await _test_ketukan_ganda()
	await _test_tutup_di_tengah_rute()
	await _test_pengaturan_bertahan()
	await _test_back_dan_background()
	await _test_ambil_sama_dengan_lewati()
	await _test_save_rusak_diberitahukan()
	await _test_ready_autoload_tidak_menulis()
	await _test_berangkat_tanpa_memilih()
	await _test_simpan_gagal_tidak_memblokir()
	var sesudah: Dictionary = _jejak_save_asli()
	check(sebelum == sesudah, "user://save.json tidak tersentuh oleh tes alur hari (%s -> %s)" % [sebelum, sesudah])


# --- Pembantu ---

## Mengakhiri hari sejak layar hasil terbuka: "Ke bengkel" (`BUKA_BENGKEL`, run fase6a1-bengkel-kondisi bagian B) lalu "Hari berikutnya" di bengkel tanpa membeli apa pun (K-4: bengkel boleh
## dilewati). Sinkron. Dulu tombol layar hasil mengakhiri hari langsung; sejak bengkel ada, simpan terjadi di bengkel.
func _akhiri_hari(hari: HariMain) -> void:
	hari.rute().layar_hasil().tombol_main_lagi().ditekan.emit()
	hari.bengkel().tombol_hari_berikutnya().ditekan.emit()

func _jejak_save_asli() -> Dictionary:
	var ada: bool = FileAccess.file_exists(SAVE_ASLI)
	return {"ada": ada, "ukuran": FileAccess.get_file_as_bytes(SAVE_ASLI).size() if ada else 0, "sha": FileAccess.get_sha256(SAVE_ASLI) if ada else ""}


func _jalur() -> String:
	return FOLDER_TES.path_join("save.json")


func _bersihkan_folder() -> void:
	var dir: DirAccess = DirAccess.open(FOLDER_TES)
	if dir == null:
		return
	for nama: String in dir.get_files():
		DirAccess.remove_absolute(FOLDER_TES.path_join(nama))
	DirAccess.remove_absolute(FOLDER_TES)


func _tulis_save(teks: String) -> void:
	DirAccess.make_dir_recursive_absolute(FOLDER_TES)
	var berkas: FileAccess = FileAccess.open(_jalur(), FileAccess.WRITE)
	berkas.store_string(teks)
	berkas.close()


## Save sah hari `hari` dengan `ubah` diterapkan ke templat (pembantu fixture).
func _fixture(hari: int, ubah: Dictionary = {}) -> String:
	var s: Dictionary = DataSave.templat()
	s["hari"] = hari
	for kunci: String in ubah:
		s[kunci] = ubah[kunci]
	return DataSave.ke_teks(s)


func _manajer() -> Node:
	var m: Node = (load(SKRIP_SIMPAN) as GDScript).new()
	m.set(&"jalur", _jalur())
	m.set(&"lapor_ke_log", false)
	m.call(&"muat", 1700000000)
	_simpanan_aktif.append(m)
	return m


## Memasang scene hari dengan `SaveManager` sementara yang sudah memuat berkas di `_jalur()`.
func _siapkan(manajer: Node = null) -> HariMain:
	_tree.root.size = Vector2i(2340, 1080)
	var m: Node = manajer if manajer != null else _manajer()
	var hari: HariMain = (load(BERKAS_HARI) as PackedScene).instantiate() as HariMain
	hari.simpanan = m
	hari.panggil_quit = false
	_tree.root.add_child(hari)
	await _tree.process_frame
	await _tree.process_frame
	return hari


func _bersihkan(hari: HariMain) -> void:
	_lepas_jari()
	var rute: RuteMain = hari.rute()
	if rute != null:
		if rute.sedang_jeda():
			rute.minta_lanjut()
		(rute.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = OS.has_feature("editor")
	_tree.root.remove_child(hari)
	hari.free()


func _tutup_manajer(m: Node) -> void:
	_simpanan_aktif.erase(m)
	m.free()


func _lepas_jari() -> void:
	for i: int in range(8):
		var peristiwa: InputEventScreenTouch = InputEventScreenTouch.new()
		peristiwa.index = i
		peristiwa.position = Vector2(-50, -50)
		peristiwa.pressed = false
		Input.parse_input_event(peristiwa)
	Input.flush_buffered_events()


## Mulai rute: Berangkat ditekan, rute dibekukan dari `_process` (langkah manual) supaya deterministik.
func _berangkat(hari: HariMain) -> RuteMain:
	hari.koran().tombol_berangkat().ditekan.emit()
	await _tree.process_frame
	await _tree.process_frame
	var rute: RuteMain = hari.rute()
	rute.set_process(false)
	(rute.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = false
	(rute.find_child("LoperAgen", true, false) as LoperSprite).set_process(false)
	return rute


## Mengisi skor hari ini dengan angka literal (3 pelanggan terantar, koin 120 termasuk tip 25, skor 1500, tepat 2) lalu menyelesaikan rute sampai
## layar hasil terbuka.
func _selesaikan_rute(rute: RuteMain) -> void:
	var skor: SkorRute.Keadaan = rute.skor()
	skor.koin = 120
	skor.koin_tip = 25
	skor.jumlah_tip = 1
	skor.skor = 1500
	skor.jumlah_tepat = 2
	for i: int in range(3):
		skor.terantar[rute.rute().pelanggan[i].id] = true
	var sepeda: SepedaUji = rute.find_child("Sepeda", true, false) as SepedaUji
	var k: BikeMotion.Keadaan = sepeda.keadaan.salin()
	k.kecepatan_ud = Config.KECEPATAN_SANTAI_UD
	sepeda.keadaan = k
	sepeda.jarak_ubin = rute.rute().panjang_ubin - 0.01
	for i: int in range(900):
		if rute.hasil_tampil():
			return
		rute.perbarui(DT)


## Menyelesaikan misi kucing hari ini lewat langkah nyata `RuteMain.perbarui`: tiap kucing lihat dilewati (sepeda diletakkan di depan lalu di sebelah kucing), kucing
## tangkap didekati dan sepeda ditahan diam (kecepatan 0, lateral -1) 100 langkah (1,67 detik >= 1,5 detik). Pembantu tes: posisi dan kecepatan sepeda diatur
## langsung, sisanya (rencana, MissionManager, banner, hadiah) lewat kode asli.
func _selesaikan_misi(rute: RuteMain) -> void:
	var sepeda: SepedaUji = rute.find_child("Sepeda", true, false) as SepedaUji
	for t: RencanaMisi.Titik in rute.rencana_misi().titik:
		_taruh(sepeda, t.maju_ubin - 13.0, 0.5)
		rute.perbarui(DT)
		if t.jenis == "lihat":
			_taruh(sepeda, t.maju_ubin + 0.1, 0.5)
			rute.perbarui(DT)
		else:
			for i: int in range(100):
				_taruh(sepeda, t.maju_ubin - 0.5, 0.0)
				rute.perbarui(DT)


func _taruh(sepeda: SepedaUji, jarak: float, kecepatan: float) -> void:
	var k: BikeMotion.Keadaan = sepeda.keadaan.salin()
	k.kecepatan_ud = kecepatan
	k.lateral_ubin = -1.0
	sepeda.keadaan = k
	sepeda.jarak_ubin = jarak


func _baca_save() -> Dictionary:
	return DataSave.dari_teks(FileAccess.get_file_as_string(_jalur())).state


# --- Alur satu hari (AC-17, AC-25) ---

func _test_satu_hari_utuh() -> void:
	_judul.call("Alur hari: Koran -> Ambil -> Berangkat -> rute -> Hasil -> Hari berikutnya -> Koran hari 2 (AC-17, AC-25)")
	_bersihkan_folder()
	var m: Node = _manajer()
	var hari: HariMain = await _siapkan(m)
	check(hari.galat_data().is_empty(), "data koran sah: %s" % [hari.galat_data()])
	check(hari.status().keadaan == MesinHari.Keadaan.KORAN and hari.status().hari == 1 and hari.koran().tampil() and hari.rute() == null, "mulai di layar koran hari 1, belum ada rute")
	var halaman1: Array[String] = hari.halaman().daftar_id()
	check(hari.halaman().misi != null and hari.halaman().misi.id == "p1_kucing", "hari 1: misi P1 (tutorial)")
	check(hari.koran().teks_tampil()[8] == "Kucing Bu Ratmi Hilang Sejak Semalam", "layar koran menampilkan headline misi P1")
	hari.koran().tombol_ambil().ditekan.emit()
	hari.koran().tombol_lewati().ditekan.emit()
	hari.koran().tombol_ambil().ditekan.emit()
	check(hari.koran().pilihan() == HalamanKoran.Pilihan.AMBIL, "Ambil, Lewati, Ambil: pilihan terakhir AMBIL")
	var rute: RuteMain = await _berangkat(hari)
	check(rute != null and hari.status().keadaan == MesinHari.Keadaan.RUTE and not hari.koran().tampil(), "Berangkat: status RUTE, layar koran tersembunyi, rute ada")
	check(rute.benih() == 21261103 and rute.benih() == SeedHari.rute(1), "seed rute hari 1 = 21261103 (SeedHari, disuntik sebelum rute disusun, bukan seed dev)")
	check(rute.galat_rute().is_empty() and rute.rute().pelanggan.size() == 25, "rute hari 1 tersusun sah dengan 25 pelanggan")
	check(rute.layar_hasil().mode_hari() and hari.misi_diambil() == "p1_kucing", "mode hari menyala dan misi P1 tercatat diambil (tanpa efek di rute)")
	var sidik_hari1: String = _sidik(rute.rute())
	# Run fase6a1-bengkel-kondisi bagian B (AC-4): hari ini memuat SATU belanja supaya contoh save di DATA_SCHEMA 4 memuat servis: rantai aus 0,40 (AUS, belum PERLU_BENGKEL) diservis di bengkel.
	rute.atur_kondisi(KondisiRute.awal({"ban": 1.0, "rem": 1.0, "rantai": 0.4}, {}, 1, hari.toko().upgrade))
	_selesaikan_misi(rute)
	check(rute.keadaan_misi().status == MissionManager.Status.SELESAI and rute.hud_rute().teks_koin() == "75", "misi kucing diselesaikan (langkah nyata RuteMain): HUD koin 75 sebelum antaran (hadiah ikut HUD)")
	await _selesaikan_rute(rute)
	check(rute.hasil_tampil() and hari.status().keadaan == MesinHari.Keadaan.HASIL, "garis akhir terlewati: layar hasil terbuka dan status HASIL")
	check(rute.layar_hasil().teks_tombol() == "Ke bengkel" and rute.layar_hasil().rect_tombol().size.y >= 42.0, "tombol layar hasil 'Ke bengkel' (>= 42 px game) menggantikan 'Main lagi'")
	var angka: HasilRute.Angka = rute.angka_hasil()
	check(angka.terkirim == 3 and angka.meleset == 22 and angka.koin == 195 and angka.koin_tip == 25 and angka.skor == 1500, "angka layar hasil (literal tes): terkirim 3, meleset 22, koin 120 + 75 hadiah misi = 195, tip 25, skor 1500")
	check(angka.koin_misi == 75 and angka.misi_hasil == "selesai" and angka.misi_id == "p1_kucing", "angka hasil membawa misi P1 selesai dengan 75 koin")
	check(rute.layar_hasil().teks_rekap_misi() == "Misi: Kucing ketemu! +75 koin", "layar hasil memuat baris rekap 'Misi: Kucing ketemu! +75 koin'")
	check(m.get(&"jumlah_simpan") == 0 and not FileAccess.file_exists(_jalur()), "sampai layar hasil terbuka belum ada simpan sama sekali")
	var disimpan: Array[int] = [0]
	hari.hari_selesai.connect(func(h: int) -> void: disimpan[0] = h)
	rute.layar_hasil().tombol_main_lagi().ditekan.emit()
	check(hari.status().keadaan == MesinHari.Keadaan.BENGKEL and hari.bengkel() != null and m.get(&"jumlah_simpan") == 0 and hari.bengkel().teks_saldo() == "195", "'Ke bengkel': status BENGKEL, saldo 195 (koin hari ini termasuk hadiah misi), nol simpan")
	hari.bengkel().tombol_servis("rantai").pressed.emit()
	check(hari.bengkel().teks_saldo() == "105" and m.get(&"jumlah_simpan") == 0, "servis rantai 90 koin (150 x 0,6): saldo 105, masih nol simpan")
	hari.bengkel().tombol_hari_berikutnya().ditekan.emit()
	await _tree.process_frame
	check(m.get(&"jumlah_simpan") == 1 and disimpan[0] == 1, "'Hari berikutnya': tepat satu simpan, sinyal hari_selesai(1)")
	var s: Dictionary = _baca_save()
	check(s["hari"] == 2 and s["koin"] == 105 and s["koin_total"] == 195 and s["tip_total"] == 25, "isi save: hari 2, koin 105 (195 - servis 90), koin_total 195, tip_total 25 (dari Angka yang sama, termasuk hadiah misi)")
	check(s["sepeda"]["rantai"] == {"kondisi": 1.0, "level": 0} and s["sepeda"]["servis_total"] == 1 and s["sepeda"]["ban"]["kondisi"] > 0.999 and s["sepeda"]["rem"]["kondisi"] > 0.999, "sepeda: rantai diservis (1,0), servis_total 1, ban dan rem hampir utuh")
	check(s["terakhir"] == {"hari": 1, "terkirim": 3, "meleset": 22, "koin": 195, "tip": 25, "skor": 1500, "koin_misi": 75, "misi_hasil": "selesai", "misi_diambil": "p1_kucing"}, "terakhir = angka layar hasil + misi diambil + hasil misi; dapat %s" % [s["terakhir"]])
	check(s["misi_hasil"] == {"p1_kucing": {"hasil": "selesai", "hari": 1}} and s["tutorial"] == {"selesai": true}, "misi_hasil p1_kucing selesai di hari 1 (riwayat permanen); hari tutorial berakhir: tutorial.selesai true")
	check(s["misi_jeda"] == {"p1_kucing": 8}, "misi P1 diambil hari 1 jeda 7: boleh lagi hari 8; dapat %s" % [s["misi_jeda"]])
	check(s["headline_jeda"].has(halaman1[0]) and s["headline_jeda"].has(halaman1[2]) and s["headline_jeda"].size() == 2, "jeda headline utama dan ringan hari 1 tercatat: %s" % [s["headline_jeda"]])
	check(s["flag"] == ["kucing_ketemu"] and s["pengaturan"] == {"kidal": false, "mode_bantu": false, "suara": 1.0, "musik": 1.0}, "flag kucing_ketemu menunggu tampil besok (M-6) dan pengaturan bawaan tersimpan")
	var contoh: String = FileAccess.get_file_as_string("res://docs/DATA_SCHEMA.md")
	var awal_blok: int = contoh.find("```json", contoh.find("Contoh save nyata setelah hari 1 selesai"))
	var blok: String = contoh.substr(awal_blok + 7, contoh.find("```", awal_blok + 7) - awal_blok - 7)
	var dari_dokumen: Variant = JSON.parse_string(blok)
	var dari_berkas: Variant = JSON.parse_string(FileAccess.get_file_as_string(_jalur()))
	var cocok: bool = typeof(dari_dokumen) == TYPE_DICTIONARY and typeof(dari_berkas) == TYPE_DICTIONARY and (dari_dokumen as Dictionary).size() == (dari_berkas as Dictionary).size()
	var beda: Array[String] = []
	if cocok:
		for kunci: Variant in (dari_dokumen as Dictionary):
			if kunci == "pelanggan":
				for id: Variant in (dari_dokumen as Dictionary)["pelanggan"]:
					if not ((dari_berkas as Dictionary)["pelanggan"] as Dictionary).has(id) or ((dari_dokumen as Dictionary)["pelanggan"] as Dictionary)[id] != ((dari_berkas as Dictionary)["pelanggan"] as Dictionary)[id]:
						beda.append("pelanggan." + str(id))
			elif (dari_dokumen as Dictionary)[kunci] != (dari_berkas as Dictionary).get(kunci):
				beda.append(str(kunci))
	check(cocok and beda.is_empty(), "contoh save di DATA_SCHEMA 4 = isi berkas save nyata sesudah hari 1 (semua field sama; pelanggan: tiap entri contoh sama dengan berkas; selisih: %s)" % [beda])
	check(cocok and ((dari_berkas as Dictionary)["pelanggan"] as Dictionary).size() == 25 and int(((dari_berkas as Dictionary)["reputasi"] as Dictionary)["perumahan"]) == 2, "berkas nyata memuat 25 pelanggan rute hari 1 dan reputasi Perumahan 2 (misi sedang +2, kredit 9 < 30)")
	check(hari.status().keadaan == MesinHari.Keadaan.KORAN and hari.status().hari == 2 and hari.koran().tampil() and hari.rute() == null, "kembali ke layar koran hari 2, rute dibuang")
	check(hari.get_child_count() == 1 + (1 if m.get_parent() == hari else 0), "node rute dibuang dari scene hari (hanya koran yang tersisa)")
	check(hari.koran().teks_tampil()[1] == "Hari 2 · Perumahan Melati", "layar koran hari 2: 'Hari 2 · Perumahan Melati'")
	check(hari.halaman().misi == null and not hari.koran().ada_misi() and hari.koran().teks_tampil()[11] == "Tidak ada misi sampingan hari ini", "hari 2: P1 masih jeda -> baris misi netral tanpa tombol (S-8)")
	check(hari.halaman().ringan.id == "lanjutan_kucing_ketemu" and hari.koran().teks_tampil()[5] == "Kucing Bu Ratmi Sudah Pulang ke Rumah", "hari 2: koran menampilkan lanjutan 'Kucing Bu Ratmi Sudah Pulang ke Rumah' (hasil selesai hari 1)")
	check(hari.halaman().utama.id != halaman1[0] and hari.halaman().ringan.id != halaman1[2], "headline hari 2 berbeda dari hari 1 (jeda headline dihormati)")
	# Oracle halaman hari 2 dari save di berkas: HeadlineManager dengan masukan yang disusun tes dari berkas.
	var masukan: HeadlineManager.Masukan = HeadlineManager.Masukan.new()
	masukan.hari = 2
	masukan.pustaka = PemuatHeadline.muat_folder()
	masukan.misi = PemuatMisi.muat_folder().misi
	for f: Variant in s["flag"]:
		masukan.flag.append(str(f))
	for id: Variant in s["headline_jeda"]:
		masukan.headline_jeda[str(id)] = int(s["headline_jeda"][id])
	for id: Variant in s["misi_jeda"]:
		masukan.misi_jeda[str(id)] = int(s["misi_jeda"][id])
	check(HeadlineManager.susun(masukan).daftar_id() == hari.halaman().daftar_id(), "halaman hari 2 = HeadlineManager atas isi save di berkas (oracle tes)")
	var rute2: RuteMain = await _berangkat(hari)
	check(rute2.benih() == SeedHari.rute(2) and _sidik(rute2.rute()) != sidik_hari1, "rute hari 2 memakai seed hari 2 dan berbeda dari rute hari 1")
	check(hari.jumlah_rute_dibuat == 2, "dua rute dibuat selama dua hari (satu per hari)")
	_bersihkan(hari)
	_tutup_manajer(m)
	_bersihkan_folder()


func _sidik(rute: RouteBuilder.Rute) -> String:
	var bagian: Array[String] = []
	for s: SegmenRute in rute.segmen:
		bagian.append(s.id)
	for r: RouteBuilder.RumahRute in rute.pelanggan:
		bagian.append(r.id)
	return ",".join(bagian)


# --- Simpan hanya di akhir hari (AC-14) ---

func _test_simpan_hanya_akhir_hari() -> void:
	_judul.call("Alur hari: tidak ada simpan di koran, Ambil/Lewati, Berangkat, jeda, background, hasil terbuka (AC-14)")
	_bersihkan_folder()
	var m: Node = _manajer()
	var hari: HariMain = await _siapkan(m)
	var jumlah: Callable = func() -> int: return int(m.get(&"jumlah_simpan"))
	hari.koran().tombol_ambil().ditekan.emit()
	hari.koran().tombol_lewati().ditekan.emit()
	hari.propagate_notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	hari.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(jumlah.call() == 0 and not FileAccess.file_exists(_jalur()), "layar koran, Ambil, Lewati, background: nol simpan, tidak ada berkas")
	var rute: RuteMain = await _berangkat(hari)
	check(jumlah.call() == 0 and not FileAccess.file_exists(_jalur()), "Berangkat: nol simpan")
	rute.minta_jeda()
	await _tree.process_frame
	check(rute.sedang_jeda() and jumlah.call() == 0, "jeda: nol simpan")
	rute.minta_lanjut()
	hari.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(jumlah.call() == 0 and not FileAccess.file_exists(_jalur()), "app ke background di rute: nol simpan")
	rute.minta_lanjut()
	await _selesaikan_rute(rute)
	check(rute.hasil_tampil() and jumlah.call() == 0 and not FileAccess.file_exists(_jalur()), "hasil terbuka: nol simpan")
	_akhiri_hari(hari)
	check(jumlah.call() == 1 and FileAccess.file_exists(_jalur()), "'Hari berikutnya': tepat satu simpan dan berkas ada")
	hari.koran().tombol_lewati().ditekan.emit()
	var rute2: RuteMain = await _berangkat(hari)
	check(jumlah.call() == 1, "hari 2 dimulai: tetap satu simpan")
	await _selesaikan_rute(rute2)
	_akhiri_hari(hari)
	check(jumlah.call() == 2, "satu simpan per hari: dua hari = dua simpan")
	_bersihkan(hari)
	_tutup_manajer(m)
	_bersihkan_folder()


func _test_ketukan_ganda() -> void:
	_judul.call("Alur hari: Berangkat dan 'Hari berikutnya' diketuk berkali-kali tidak menggandakan (AC-16, mutan Berangkat ganda)")
	_bersihkan_folder()
	var m: Node = _manajer()
	var hari: HariMain = await _siapkan(m)
	for i: int in range(4):
		hari.koran().tombol_berangkat().ditekan.emit()
	await _tree.process_frame
	await _tree.process_frame
	var jumlah_rute: int = 0
	for anak: Node in hari.get_children():
		jumlah_rute += 1 if anak is RuteMain else 0
	check(hari.jumlah_rute_dibuat == 1 and jumlah_rute == 1, "Berangkat diketuk empat kali: tepat satu rute (dibuat %d, anak %d)" % [hari.jumlah_rute_dibuat, jumlah_rute])
	var rute: RuteMain = hari.rute()
	rute.set_process(false)
	await _selesaikan_rute(rute)
	# "Ke bengkel" tiga kali: satu bengkel; "Hari berikutnya" di bengkel tiga kali: satu simpan, hari naik sekali (ketukan ganda ditolak MesinHari).
	for i: int in range(3):
		rute.layar_hasil().tombol_main_lagi().ditekan.emit()
	check(hari.status().keadaan == MesinHari.Keadaan.BENGKEL and hari.bengkel() != null and m.get(&"jumlah_simpan") == 0, "'Ke bengkel' diketuk tiga kali: satu bengkel terbuka, belum ada simpan")
	var bengkel: LayarBengkel = hari.bengkel()
	for i: int in range(3):
		bengkel.tombol_hari_berikutnya().ditekan.emit()
		bengkel.hari_berikutnya_diminta.emit()
	await _tree.process_frame
	check(m.get(&"jumlah_simpan") == 1 and hari.status().hari == 2 and int(_baca_save()["hari"]) == 2, "'Hari berikutnya' di bengkel diketuk berkali-kali: satu simpan dan hari 2 (bukan 3 atau 4)")
	_bersihkan(hari)
	_tutup_manajer(m)
	_bersihkan_folder()


# --- Tutup di tengah rute (AC-19) ---

func _test_tutup_di_tengah_rute() -> void:
	_judul.call("Alur hari: app ditutup di tengah rute = tidak ada tulis, hari yang sama dari koran (AC-19)")
	_bersihkan_folder()
	_tulis_save(_fixture(3, {"koin": 500, "tip_total": 40, "flag": ["flag_lama"]}))
	var bita_awal: PackedByteArray = FileAccess.get_file_as_bytes(_jalur())
	var m: Node = _manajer()
	var hari: HariMain = await _siapkan(m)
	var id_koran: Array[String] = hari.halaman().daftar_id()
	check(hari.status().hari == 3 and hari.koran().teks_tampil()[1] == "Hari 3 · Perumahan Melati", "save hari 3 dimuat: koran hari 3")
	hari.koran().tombol_ambil().ditekan.emit()
	var rute: RuteMain = await _berangkat(hari)
	var benih: int = rute.benih()
	var sepeda: SepedaUji = rute.find_child("Sepeda", true, false) as SepedaUji
	sepeda.jarak_ubin = 100.0
	for i: int in range(120):
		rute.perbarui(DT)
	check(not rute.rute_sudah_selesai() and sepeda.jarak_ubin > 100.0, "rute berjalan di tengah (jarak %.1f dari %.0f)" % [sepeda.jarak_ubin, rute.rute().panjang_ubin])
	_bersihkan(hari)
	var jumlah_simpan: int = int(m.get(&"jumlah_simpan"))
	_tutup_manajer(m)
	check(jumlah_simpan == 0 and FileAccess.get_file_as_bytes(_jalur()) == bita_awal, "scene dibuang di tengah rute: tidak ada simpan dan berkas identik byte demi byte")
	var dir: DirAccess = DirAccess.open(FOLDER_TES)
	check(dir.get_files() == PackedStringArray(["save.json"]), "tidak ada berkas sementara atau salinan rusak di folder save: %s" % [dir.get_files()])
	var m2: Node = _manajer()
	var hari2: HariMain = await _siapkan(m2)
	check(hari2.status().hari == 3 and hari2.halaman().daftar_id() == id_koran, "dibuka lagi: hari yang sama dan headline sama (%s)" % [id_koran])
	check(hari2.halaman().misi != null and hari2.koran().pilihan() == HalamanKoran.Pilihan.BELUM, "pilihan Ambil/Lewati diulang dari belum dipilih")
	var rute_lagi: RuteMain = await _berangkat(hari2)
	check(rute_lagi.benih() == benih and benih == SeedHari.rute(3), "seed rute sama (%d = SeedHari.rute(3))" % benih)
	check(m2.get(&"jumlah_simpan") == 0, "membuka lagi dan berangkat tidak menyimpan")
	_bersihkan(hari2)
	_tutup_manajer(m2)
	_bersihkan_folder()


# --- Pengaturan (AC-13) ---

func _test_pengaturan_bertahan() -> void:
	_judul.call("Alur hari: sakelar Kidal/Bantu dari jeda tersimpan di akhir hari dan dibaca sebelum koran (AC-13)")
	_bersihkan_folder()
	var m: Node = _manajer()
	var hari: HariMain = await _siapkan(m)
	var rute: RuteMain = await _berangkat(hari)
	check(not rute.kidal() and not rute.mode_bantu(), "save baru: kidal dan bantu mati")
	rute.minta_jeda()
	await _tree.process_frame
	var jeda: LayarJeda = rute.find_child("LayarJeda", true, false) as LayarJeda
	jeda.sakelar_kidal().ditekan.emit()
	jeda.sakelar_bantu().ditekan.emit()
	check(rute.kidal() and rute.mode_bantu(), "sakelar jeda menyalakan kidal dan bantu")
	rute.minta_lanjut()
	await _selesaikan_rute(rute)
	_akhiri_hari(hari)
	var s: Dictionary = _baca_save()
	check(s["pengaturan"]["kidal"] == true and s["pengaturan"]["mode_bantu"] == true and s["pengaturan"]["suara"] == 1.0, "save berisi kidal dan mode_bantu nyala, suara 1.0 (bawaan)")
	var rute2: RuteMain = await _berangkat(hari)
	check(rute2.kidal() and rute2.mode_bantu(), "hari 2 di sesi yang sama: kidal dan bantu masih menyala")
	check(rute2.find_child("LayarJeda", true, false).call(&"rect_sakelar_kidal") != null, "layar jeda hari 2 ada")
	_bersihkan(hari)
	_tutup_manajer(m)
	var m2: Node = _manajer()
	var hari2: HariMain = await _siapkan(m2)
	check(m2.call(&"pengaturan")["kidal"] == true and hari2.status().hari == 2, "SaveManager baru memuat pengaturan sebelum layar koran dibuat (hari 2, kidal nyala)")
	var rute3: RuteMain = await _berangkat(hari2)
	check(rute3.kidal() and rute3.mode_bantu(), "app dibuka lagi: kidal dan bantu masih menyala di rute hari 2")
	var jeda3: LayarJeda = rute3.find_child("LayarJeda", true, false) as LayarJeda
	rute3.minta_jeda()
	await _tree.process_frame
	check(tr(jeda3.sakelar_kidal().text) == "Kidal: nyala" and tr(jeda3.sakelar_bantu().text) == "Bantu: nyala", "sakelar layar jeda menampilkan 'Kidal: nyala' dan 'Bantu: nyala' dari save")
	rute3.minta_lanjut()
	_bersihkan(hari2)
	_tutup_manajer(m2)
	_bersihkan_folder()


# --- Back dan background (AC-18) ---

func _test_back_dan_background() -> void:
	_judul.call("Alur hari: back Android per layar dan background di koran (AC-18, S-6)")
	_bersihkan_folder()
	var m: Node = _manajer()
	var hari: HariMain = await _siapkan(m)
	var keluar: Array[int] = [0]
	hari.keluar_diminta.connect(func() -> void: keluar[0] += 1)
	hari.propagate_notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	hari.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	hari.propagate_notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check(keluar[0] == 0 and hari.koran().tampil() and hari.status().keadaan == MesinHari.Keadaan.KORAN and m.get(&"jumlah_simpan") == 0, "background dan kembali di layar koran: tidak crash, tidak keluar, tidak menyimpan")
	hari.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(keluar[0] == 1, "back di layar koran: keluar app diminta (satu kali)")
	check(m.get(&"jumlah_simpan") == 0, "keluar dari layar koran tidak menyimpan (tidak ada yang hilang)")
	var rute: RuteMain = await _berangkat(hari)
	hari.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await _tree.process_frame
	check(keluar[0] == 1 and rute.sedang_jeda(), "back di rute: menjeda, tidak keluar")
	hari.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(not rute.sedang_jeda() and keluar[0] == 1, "back lagi saat jeda: lanjut (perilaku 3C tidak berubah)")
	hari.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(rute.sedang_jeda(), "app ke background di rute: tetap menjeda (perilaku 3C)")
	rute.minta_lanjut()
	await _selesaikan_rute(rute)
	check(rute.hasil_tampil(), "layar hasil terbuka")
	hari.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await _tree.process_frame
	check(not rute.sedang_jeda() and keluar[0] == 1 and hari.status().keadaan == MesinHari.Keadaan.HASIL and m.get(&"jumlah_simpan") == 0, "back di layar hasil: diabaikan (tidak jeda, tidak keluar, tidak simpan)")
	_bersihkan(hari)
	_tutup_manajer(m)
	_bersihkan_folder()


# --- Lewati tanpa penalti (AC-20) ---

func _test_ambil_sama_dengan_lewati() -> void:
	_judul.call("Alur hari: Ambil (misi gagal) dan Lewati: koin, tip, hari sama; beda hanya catatan misi, flag, dan jeda misi (AC-20, prinsip 2)")
	var hasil: Array[Dictionary] = []
	for ambil: bool in [true, false]:
		_bersihkan_folder()
		var m: Node = _manajer()
		var hari: HariMain = await _siapkan(m)
		if ambil:
			hari.koran().tombol_ambil().ditekan.emit()
		else:
			hari.koran().tombol_lewati().ditekan.emit()
		var rute: RuteMain = await _berangkat(hari)
		await _selesaikan_rute(rute)
		_akhiri_hari(hari)
		hasil.append(_baca_save())
		_bersihkan(hari)
		_tutup_manajer(m)
	_bersihkan_folder()
	var diambil: Dictionary = hasil[0]
	var dilewati: Dictionary = hasil[1]
	check(diambil["terakhir"]["misi_diambil"] == "p1_kucing" and dilewati["terakhir"]["misi_diambil"] == "", "misi_diambil tercatat hanya bila Ambil")
	check(diambil["koin"] == dilewati["koin"] and diambil["tip_total"] == dilewati["tip_total"] and diambil["hari"] == dilewati["hari"] and diambil["headline_jeda"] == dilewati["headline_jeda"] and diambil["pengaturan"] == dilewati["pengaturan"], "koin, tip_total, hari, jeda headline, dan pengaturan sama untuk Ambil (misi gagal karena sepeda diloncatkan) dan Lewati: gagal tidak mengurangi apa pun")
	check(diambil["flag"] == ["kucing_belum"] and dilewati["flag"] == [] and diambil["misi_hasil"] == {"p1_kucing": {"hasil": "gagal", "hari": 1}} and dilewati["misi_hasil"] == {}, "Ambil + gagal menulis flag kucing_belum dan misi_hasil gagal; Lewati tidak menulis keduanya")
	var a: Dictionary = diambil["terakhir"].duplicate()
	var b: Dictionary = dilewati["terakhir"].duplicate()
	check(a["misi_hasil"] == "gagal" and a["koin_misi"] == 0 and b["misi_hasil"] == "" and b["koin_misi"] == 0, "terakhir: Ambil gagal punya hasil 'gagal' dan koin_misi 0; Lewati hasil ''")
	a.erase("misi_diambil")
	b.erase("misi_diambil")
	a.erase("misi_hasil")
	b.erase("misi_hasil")
	check(a == b, "terakhir sama kecuali misi_diambil dan misi_hasil")
	check(dilewati["misi_jeda"] == {} and diambil["misi_jeda"] == {"p1_kucing": 8}, "hanya misi yang diambil memicu jeda (S-4); Lewati tidak memicu apa pun")
	check(dilewati["koin"] == 120 and dilewati["hari"] == 2, "Lewati: koin tidak berkurang dan hari tetap maju; tidak ada keadaan kalah")


# --- Save rusak (AC-9) ---

func _test_save_rusak_diberitahukan() -> void:
	_judul.call("Alur hari: save rusak diberitahukan satu kali di layar koran, berkas lama disalin (AC-9)")
	_bersihkan_folder()
	_tulis_save("{bukan json")
	var m: Node = _manajer()
	var hari: HariMain = await _siapkan(m)
	var notif_tampil: Callable = func() -> bool: return hari.koran().find_child("Notifikasi", true, false).is_visible_in_tree()
	check(notif_tampil.call() and hari.status().hari == 1, "save rusak: notifikasi satu baris tampil dan permainan mulai dari hari 1")
	check(FileAccess.file_exists(FOLDER_TES.path_join("save.corrupt.1700000000.json")) and FileAccess.get_file_as_string(_jalur()) == "{bukan json", "berkas lama disalin dan belum ditimpa")
	var rute: RuteMain = await _berangkat(hari)
	await _selesaikan_rute(rute)
	_akhiri_hari(hari)
	check(not notif_tampil.call() and hari.status().hari == 2, "notifikasi hanya sekali: hilang di koran hari 2")
	check(DataSave.dari_teks(FileAccess.get_file_as_string(_jalur())).status == DataSave.Status.SAH, "sesudah hari pertama berkas save sah lagi")
	_bersihkan(hari)
	_tutup_manajer(m)
	_bersihkan_folder()


# --- SaveManager._ready tidak menulis (QA-001, AC-8, AC-14) ---

func _test_ready_autoload_tidak_menulis() -> void:
	_judul.call("SaveManager di pohon: _ready (yang berjalan di autoload sungguhan) hanya memuat, tidak pernah menulis (QA-001, AC-14)")
	_bersihkan_folder()
	# Tanpa berkas: masuk pohon (memicu _ready) tidak membuat save.json atau save.tmp. Node yang masuk root baru mendapat _ready sesudah satu frame.
	var m: Node = (load(SKRIP_SIMPAN) as GDScript).new()
	m.set(&"jalur", _jalur())
	m.set(&"lapor_ke_log", false)
	_tree.root.add_child(m)
	await _tree.process_frame
	await _tree.process_frame
	check(m.get(&"jumlah_simpan") == 0 and not FileAccess.file_exists(_jalur()) and not DirAccess.dir_exists_absolute(FOLDER_TES), "_ready tanpa berkas: jumlah_simpan 0, tidak ada save.json, tidak ada folder yang dibuat")
	_tree.root.remove_child(m)
	m.free()
	# Berkas sah: _ready memuatnya (state dari berkas) dan berkas tidak berubah satu byte pun.
	_tulis_save(_fixture(7, {"koin": 321}))
	var bita: PackedByteArray = FileAccess.get_file_as_bytes(_jalur())
	var m2: Node = (load(SKRIP_SIMPAN) as GDScript).new()
	m2.set(&"jalur", _jalur())
	m2.set(&"lapor_ke_log", false)
	_tree.root.add_child(m2)
	await _tree.process_frame
	await _tree.process_frame
	check(m2.call(&"hari") == 7 and m2.get(&"jumlah_simpan") == 0 and FileAccess.get_file_as_bytes(_jalur()) == bita, "_ready di atas save sah: hari 7 termuat, nol simpan, berkas identik byte demi byte")
	_tree.root.remove_child(m2)
	m2.free()
	# Berkas rusak: _ready tidak menimpanya (hanya salinan yang boleh dibuat), nol simpan.
	_tulis_save("{bukan json")
	var m3: Node = (load(SKRIP_SIMPAN) as GDScript).new()
	m3.set(&"jalur", _jalur())
	m3.set(&"lapor_ke_log", false)
	_tree.root.add_child(m3)
	await _tree.process_frame
	await _tree.process_frame
	check(FileAccess.get_file_as_string(_jalur()) == "{bukan json" and m3.get(&"jumlah_simpan") == 0 and not FileAccess.file_exists(FOLDER_TES.path_join("save.tmp")), "_ready di atas save rusak: berkas tidak ditimpa, nol simpan, tidak ada berkas sementara")
	check(m3.call(&"ambil_notifikasi") == "KORAN_SAVE_RUSAK", "_ready di atas save rusak: salinan dibuat dan notifikasi menunggu layar koran")
	_tree.root.remove_child(m3)
	m3.free()
	# Autoload ASLI (terdaftar di project.godot, dibuat di setiap `godot --script`): nol simpan sejak dibuat.
	var asli: Node = _tree.root.get_node_or_null(^"SaveManager")
	check(asli != null and asli.get(&"jumlah_simpan") == 0, "autoload SaveManager asli ada dan belum pernah menyimpan (jumlah_simpan 0)")
	_bersihkan_folder()


# --- Berangkat tanpa memilih = Lewati (QA-002, S-7) ---

func _test_berangkat_tanpa_memilih() -> void:
	_judul.call("Alur hari: Berangkat tanpa menyentuh Ambil/Lewati = Lewati, misi tidak tercatat dan tidak ada jeda (QA-002, S-7)")
	_bersihkan_folder()
	var m: Node = _manajer()
	var hari: HariMain = await _siapkan(m)
	check(hari.halaman().misi != null and hari.koran().pilihan() == HalamanKoran.Pilihan.BELUM, "prasyarat: hari 1 punya misi dan belum ada pilihan")
	var rute: RuteMain = await _berangkat(hari)
	check(rute != null and hari.misi_diambil() == "", "Berangkat langsung dari belum memilih: misi_diambil kosong, dapat '%s'" % hari.misi_diambil())
	await _selesaikan_rute(rute)
	_akhiri_hari(hari)
	var s: Dictionary = _baca_save()
	check(s["terakhir"]["misi_diambil"] == "" and s["misi_jeda"] == {}, "save: terakhir.misi_diambil kosong dan misi_jeda kosong (tidak ada jeda 7 hari); dapat %s / %s" % [s["terakhir"].get("misi_diambil"), s["misi_jeda"]])
	check(hari.halaman().misi != null and hari.halaman().misi.id == "p1_kucing", "hari 2: misi P1 masih boleh tampil (tidak tertahan jeda)")
	_bersihkan(hari)
	_tutup_manajer(m)
	_bersihkan_folder()


# --- Simpan akhir hari gagal tidak memblokir (QA-004, QA-003) ---

func _notif(hari: HariMain) -> Label:
	return hari.koran().find_child("Notifikasi", true, false) as Label


func _test_simpan_gagal_tidak_memblokir() -> void:
	_judul.call("Alur hari: simpan akhir hari gagal dicoba lagi sekali, tidak memblokir alur, dan diberitahukan satu baris netral (QA-004)")
	var teks_gagal: String = "Kemajuan hari ini belum tersimpan; dicoba lagi di akhir hari berikutnya"
	# (a) Gagal sekali (baca-balik pertama salah) lalu coba ulang berhasil: tersimpan, tanpa notifikasi.
	_bersihkan_folder()
	var m: Node = _manajer()
	var panggilan: Array[int] = [0]
	m.set(&"baca_balik", func(p: String) -> String:
		panggilan[0] += 1
		return "salah" if panggilan[0] == 1 else FileAccess.get_file_as_string(p))
	var hari: HariMain = await _siapkan(m)
	var rute: RuteMain = await _berangkat(hari)
	await _selesaikan_rute(rute)
	_akhiri_hari(hari)
	check(m.get(&"jumlah_simpan") == 2 and FileAccess.file_exists(_jalur()) and int(_baca_save()["hari"]) == 2 and int(_baca_save()["koin"]) == 120, "simpan pertama gagal, percobaan ulang berhasil: dua panggilan, berkas hari 2 koin 120")
	check(hari.status().hari == 2 and not _notif(hari).is_visible_in_tree(), "setelah percobaan ulang berhasil: koran hari 2 tanpa notifikasi")
	_bersihkan(hari)
	_tutup_manajer(m)
	# (b) Gagal terus (berkas sementara terhalang): alur jalan, satu baris netral, simpan berikutnya yang berhasil menuliskan semuanya.
	_bersihkan_folder()
	var m2: Node = _manajer()
	var hari2: HariMain = await _siapkan(m2)
	DirAccess.make_dir_recursive_absolute(FOLDER_TES.path_join("save.tmp"))
	var rute2: RuteMain = await _berangkat(hari2)
	await _selesaikan_rute(rute2)
	_akhiri_hari(hari2)
	await _tree.process_frame
	check(m2.get(&"jumlah_simpan") == 2 and not FileAccess.file_exists(_jalur()), "simpan gagal dua kali (awal + satu percobaan ulang), tidak ada berkas save")
	check(hari2.status().hari == 2 and hari2.status().keadaan == MesinHari.Keadaan.KORAN and hari2.koran().tampil(), "alur tidak diblokir: koran hari 2 tampil")
	check(_notif(hari2).is_visible_in_tree() and tr(_notif(hari2).text) == teks_gagal, "satu baris netral KORAN_SAVE_GAGAL tampil di koran hari 2: '%s'" % tr(_notif(hari2).text))
	DirAccess.remove_absolute(FOLDER_TES.path_join("save.tmp"))
	var rute3: RuteMain = await _berangkat(hari2)
	await _selesaikan_rute(rute3)
	_akhiri_hari(hari2)
	await _tree.process_frame
	var s: Dictionary = _baca_save()
	check(int(s["hari"]) == 3 and int(s["koin"]) == 240 and int(s["tip_total"]) == 50, "hari 2 tersimpan sesudah penghalang hilang: kemajuan dua hari ikut tertulis (hari 3, koin 240, tip_total 50)")
	check(hari2.status().hari == 3 and not _notif(hari2).is_visible_in_tree(), "setelah simpan berhasil: notifikasi hilang di koran hari 3")
	_bersihkan(hari2)
	_tutup_manajer(m2)
	# (c) Save lama ada tetapi tidak terbaca (chmod 000): ditahan, teks jujur muncul di koran pertama dan tetap sesudah hari berakhir.
	_bersihkan_folder()
	var isi: String = _fixture(40, {"koin": 9999})
	_tulis_save(isi)
	var terkunci: bool = OS.execute("chmod", ["000", ProjectSettings.globalize_path(_jalur())]) == 0 and FileAccess.open(_jalur(), FileAccess.READ) == null
	if terkunci:
		var m3: Node = _manajer()
		var hari3: HariMain = await _siapkan(m3)
		check(_notif(hari3).is_visible_in_tree() and _notif(hari3).text == "KORAN_SAVE_TIDAK_TERBACA" and hari3.status().hari == 1, "save tidak terbaca: koran hari 1 dengan KORAN_SAVE_TIDAK_TERBACA (permainan mulai dari awal di memori)")
		var rute4: RuteMain = await _berangkat(hari3)
		await _selesaikan_rute(rute4)
		_akhiri_hari(hari3)
		await _tree.process_frame
		check(hari3.status().hari == 2 and _notif(hari3).is_visible_in_tree() and _notif(hari3).text == "KORAN_SAVE_TIDAK_TERBACA", "sesudah hari berakhir: tetap diberi tahu bahwa kemajuan tidak disimpan")
		check(m3.call(&"simpan_ditahan") and m3.get(&"jumlah_simpan") == 1, "simpan ditahan: tanpa percobaan ulang yang percuma (satu panggilan)")
		OS.execute("chmod", ["644", ProjectSettings.globalize_path(_jalur())])
		check(FileAccess.get_file_as_string(_jalur()) == isi and not FileAccess.file_exists(FOLDER_TES.path_join("save.tmp")), "save lama (hari 40, koin 9999) utuh byte demi byte, tidak ada berkas sementara")
		_bersihkan(hari3)
		_tutup_manajer(m3)
	else:
		check(true, "chmod tidak menghalangi baca (mis. berjalan sebagai root): kasus tidak terbaca di alur hari dilewati")
		OS.execute("chmod", ["644", ProjectSettings.globalize_path(_jalur())])
	_bersihkan_folder()
