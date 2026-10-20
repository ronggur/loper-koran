class_name TesMisiScene
extends RefCounted
## Tes scene run fase4b-misi-kucing (AC-11 sampai AC-15, AC-18, AC-19): `scenes/rute/rute.tscn` sungguhan dengan misi P1 nyata (`atur_misi`) dan tutorial
## (`atur_tutorial`): kucing digambar di jendela daur (aset, impor, penutup), HUD kartu, banner, dan gelembung petunjuk, koin HUD = hasil, bunyi misi, mode bantu,
## jeda, tata letak di lima ukuran, dan tutorial yang tidak memblokir input. Rute dan rencana dari seed hari 1 (`SeedHari.rute(1)`), langkah `perbarui(dt)` dengan dt tetap.
## Posisi sepeda diatur langsung (pembantu tes) karena yang dites adalah keputusan misi, HUD, dan gambar; kelayakan gerak dibuktikan terpisah di `tes_misi.gd` dengan
## `BikeMotion` nyata. Lemparan tepat dibuat dengan lintasan pencari mode bantu yang dipakai sebagai lemparan biasa (`_lempar(lintasan, false)`), seperti `tes_rintangan_scene`.

const BERKAS_RUTE: String = "res://scenes/rute/rute.tscn"
const DT: float = 1.0 / 60.0
const SKALA: int = 3
## [lebar jendela, tinggi jendela, lebar viewport]: 16:9, 19,5:9, 20:9, 1600x720, dan 667.
const KASUS: Array = [[1920, 1080, 640], [2340, 1080, 780], [2400, 1080, 800], [1600, 720, 800], [2000, 1080, 667]]

var _cek: Callable
var _judul: Callable
var _tree: SceneTree
var _misi: DataMisi = null


func _init(cek: Callable, judul: Callable, tree: SceneTree) -> void:
	_cek = cek
	_judul = judul
	_tree = tree


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_misi = PemuatMisi.muat_folder().cari("p1_kucing")
	await _test_tanpa_misi()
	await _test_kucing_di_scene()
	await _test_penutup_kucing()
	await _test_hud_banner_dan_koin()
	await _test_petunjuk_di_scene()
	await _test_kotak_surat_bukan_inti()
	await _test_tangkap_jeda_dan_jatuh()
	await _test_jeda_membekukan_walau_dt_positif()
	await _test_gagal_tidak_mengubah_apa_pun()
	await _test_bunyi_misi()
	await _test_mode_bantu()
	await _test_tutorial_di_scene()
	await _test_penanda_dan_petunjuk_di_scene()
	for kasus: Array in KASUS:
		for kidal: bool in [false, true]:
			await _test_tata_letak(kasus, kidal)
			await _test_penanda_layar(kasus, kidal)


# --- Pembantu ---

func _siapkan(dengan_misi: bool = true, tutorial: bool = false, jendela: Vector2i = Vector2i(2340, 1080), hari: int = 1) -> RuteMain:
	_tree.root.size = jendela
	var akar: RuteMain = (load(BERKAS_RUTE) as PackedScene).instantiate() as RuteMain
	akar.atur_benih_awal(SeedHari.rute(hari))
	if dengan_misi:
		akar.atur_misi(_misi)
	if tutorial:
		akar.atur_tutorial(true)
	_tree.root.add_child(akar)
	await _tree.process_frame
	await _tree.process_frame
	akar.set_process(false)
	(akar.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = false
	(akar.find_child("LoperAgen", true, false) as LoperSprite).set_process(false)
	_taruh(akar, Config.KECEPATAN_SANTAI_UD, 0.0, 0.0)
	akar.perbarui(0.0)
	return akar


func _bersihkan(akar: RuteMain) -> void:
	for i: int in range(8):
		_sentuh(i, Vector2(-50, -50), false)
	if akar.sedang_jeda():
		akar.minta_lanjut()
	(akar.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = OS.has_feature("editor")
	_tree.root.remove_child(akar)
	akar.free()


func _sepeda(akar: Node) -> SepedaUji:
	return akar.find_child("Sepeda", true, false) as SepedaUji


func _taruh(akar: RuteMain, v: float, lateral: float, maju: float) -> void:
	var sepeda: SepedaUji = _sepeda(akar)
	var k: BikeMotion.Keadaan = sepeda.keadaan.salin()
	k.kecepatan_ud = v
	k.lateral_ubin = lateral
	sepeda.keadaan = k
	sepeda.jarak_ubin = maju


## Sepeda ditaruh di `maju`/`lateral` dengan kecepatan `v` lalu satu langkah.
func _di(akar: RuteMain, maju: float, lateral: float = 0.5, v: float = 3.0) -> void:
	_taruh(akar, v, lateral, maju)
	akar.perbarui(DT)


func _langkah(akar: RuteMain, jumlah: int, dt: float = DT) -> void:
	for i: int in range(jumlah):
		akar.perbarui(dt)


func _sentuh(index: int, posisi_viewport: Vector2, tekan: bool) -> void:
	var peristiwa: InputEventScreenTouch = InputEventScreenTouch.new()
	peristiwa.index = index
	peristiwa.position = posisi_viewport * float(SKALA)
	peristiwa.pressed = tekan
	Input.parse_input_event(peristiwa)
	Input.flush_buffered_events()


func _audio() -> Node:
	return _tree.root.get_node_or_null(^"Audio")


## Rumah pelanggan rute `akar` dengan awal kavling di [awal, akhir); null bila tidak ada.
func _pelanggan_di(akar: RuteMain, awal: float, akhir: float) -> RouteBuilder.RumahRute:
	for r: RouteBuilder.RumahRute in akar.rute().pelanggan:
		if r.maju_ubin >= awal and r.maju_ubin < akhir:
			return r
	return null


## Lemparan biasa (bukan bantu) ke pusat kotak surat `rumah` (`bantu` true = lemparan tap mode bantu) sampai mendarat. True bila koran mendarat.
func _lempar_ke(akar: RuteMain, rumah: RouteBuilder.RumahRute, bantu: bool = false) -> bool:
	_taruh(akar, 3.0, 0.5, ZonaSasaran.maju_kotak_surat(rumah) - 3.0)
	akar.perbarui(0.0)
	akar.koran = SisaKoran.awal(30)
	var pilihan: BantuLempar.Pilihan = akar.pilihan_bantu(LoperAnim.Sisi.SEBERANG)
	if pilihan == null or pilihan.zona.id_rumah != rumah.id:
		check(false, "pembantu tes: lintasan ke %s" % rumah.id)
		return false
	var mendarat: Array[bool] = [false]
	var sambung: Callable = func(_k: KoranLempar.Koran) -> void: mendarat[0] = true
	akar.koran_mendarat.connect(sambung)
	akar.call(&"_lempar", pilihan.lintasan, bantu)
	for i: int in range(200):
		akar.perbarui(DT)
		if mendarat[0]:
			break
	akar.koran_mendarat.disconnect(sambung)
	return mendarat[0]


func _peristiwa_tercatat(akar: RuteMain) -> Array[int]:
	var daftar: Array[int] = []
	akar.misi_peristiwa.connect(func(jenis: MissionManager.Peristiwa, _langkah_ke: int) -> void: daftar.append(int(jenis)))
	return daftar


## Mengisi dan menyelesaikan misi lewat langkah nyata RuteMain (seperti `TesAlurHari._selesaikan_misi`).
func _selesaikan_misi(akar: RuteMain) -> void:
	for t: RencanaMisi.Titik in akar.rencana_misi().titik:
		_di(akar, t.maju_ubin - 13.0, 0.5, 0.5)
		if t.jenis == "lihat":
			_di(akar, t.maju_ubin + 0.1, 0.5, 0.5)
		else:
			for i: int in range(100):
				_di(akar, t.maju_ubin - 0.5, -1.0, 0.0)


func _sidik_rute(rute: RouteBuilder.Rute) -> String:
	var bagian: Array[String] = []
	for r: RouteBuilder.RumahRute in rute.rumah:
		bagian.append("%s@%.2f%d%d" % [r.id, r.maju_ubin, int(r.sisi), 1 if r.pelanggan else 0])
	for o: RouteBuilder.ObjekRute in rute.objek:
		bagian.append("%s@%.2f%s" % [o.jenis, o.maju_ubin, o.jalur])
	return ",".join(bagian) + "|" + str(rute.panjang_ubin)


# --- Tanpa misi (AC-11) ---

func _test_tanpa_misi() -> void:
	_judul.call("Scene rute tanpa misi: tanpa kucing, tanpa kartu, tanpa tutorial, perilaku 3A-4A tidak berubah (AC-11)")
	var akar: RuteMain = await _siapkan(false)
	var hud: HudRute = akar.hud_rute()
	check(akar.keadaan_misi() == null and akar.rencana_misi() == null and akar.misi() == null, "tanpa atur_misi: tidak ada keadaan, rencana, atau data misi")
	check(not akar.kucing().tampil() and not hud.kartu_tampil() and not hud.banner_tampil() and not hud.petunjuk_tampil(), "tanpa misi: kucing, kartu, banner, gelembung petunjuk tersembunyi")
	check(akar.keadaan_tutorial() == null and not akar.tutorial_node().tampil() and not akar.tutorial_dimulai(), "tanpa atur_tutorial: rute.tscn sendiri tidak punya tutorial")
	var peristiwa: Array[int] = _peristiwa_tercatat(akar)
	for maju: float in [5.0, 12.0, 25.0, 50.0, 120.0]:
		_di(akar, maju)
	check(peristiwa.is_empty() and not akar.kucing().tampil(), "berjalan melewati seluruh jarak misi: tidak ada peristiwa misi")
	check(akar.call(&"_koin_tambahan") == 0, "tanpa misi: koin tambahan 0")
	_di(akar, akar.rute().panjang_ubin - 1.0)
	_langkah(akar, 600)
	check(akar.hasil_tampil() and akar.angka_hasil().misi_id == "" and akar.angka_hasil().misi_hasil == "" and akar.angka_hasil().koin_misi == 0, "layar hasil tanpa misi: tanpa id, hasil, atau koin misi")
	check(akar.layar_hasil().teks_rekap_misi() == "" and not akar.layar_hasil().teks_tampil().has("Misi: Kucingnya lolos hari ini"), "layar hasil tanpa misi: tanpa baris rekap")
	_bersihkan(akar)
	# Misi null eksplisit (dilewati di koran) = sama dengan tanpa misi, dan rute identik dengan rute bermisi (rencana tidak mengubah Rute).
	var a: RuteMain = await _siapkan(false)
	var b: RuteMain = await _siapkan(true)
	check(_sidik_rute(a.rute()) == _sidik_rute(b.rute()) and a.rute().benih == b.rute().benih, "rute dengan dan tanpa misi identik (rumah, objek, panjang): kucing tidak mengubah geometri rute")
	check(a.rintangan().daftar.size() == b.rintangan().daftar.size(), "jumlah rintangan sama dengan dan tanpa misi (kucing bukan rintangan)")
	_bersihkan(a)
	_bersihkan(b)


# --- Kucing digambar (AC-12) ---

func _test_kucing_di_scene() -> void:
	_judul.call("Kucing misi di scene: aset hasil skrip, tampil di rumah titik, jendela daur, Y-sort, tidak bocor (AC-12)")
	var akar: RuteMain = await _siapkan()
	var rencana: RencanaMisi.Rencana = akar.rencana_misi()
	var kucing: KucingMisi = akar.kucing()
	check(rencana != null and rencana.sah() and rencana.titik.size() == 3 and akar.keadaan_misi() != null, "rencana tiga titik dari seed hari 1 tersusun dan misi aktif")
	var t_awal: RencanaMisi.Titik = rencana.titik[0]
	check(kucing.tampil() == (0.0 >= t_awal.maju_ubin - Config.MISI_TAMPIL_JARAK_UBIN), "di awal rute kucing 1 tampil bila titiknya dalam jarak tampil (maju %.1f): %s" % [t_awal.maju_ubin, kucing.tampil()])
	var tekstur: Texture2D = load("res://assets/sprites/npc/mission_kucing_sheet.png") as Texture2D
	var info: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/npc/mission_kucing_sheet.json"))
	var sel: Array = info["cell"]
	var pijak: Array = info["ground_anchor"]
	check(tekstur != null and tekstur.get_width() == int(sel[0]) * Config.MISI_KUCING_KOLOM and tekstur.get_height() == int(sel[1]) * Config.MISI_KUCING_BARIS, "sheet kucing %dx%d = %d kolom x %d baris sel" % [tekstur.get_width(), tekstur.get_height(), Config.MISI_KUCING_KOLOM, Config.MISI_KUCING_BARIS])
	check(Config.MISI_KUCING_SEL_PX == [int(sel[0]), int(sel[1])] and Config.MISI_KUCING_PIJAK_PX == [int(pijak[0]), int(pijak[1])], "Config sel %s dan titik pijak %s sama dengan JSON sheet" % [Config.MISI_KUCING_SEL_PX, Config.MISI_KUCING_PIJAK_PX])
	check(int(info["columns"]) == Config.MISI_KUCING_KOLOM and int(info["rows"]) == Config.MISI_KUCING_BARIS and info["frames"][Config.MISI_KUCING_KOLOM_DUDUK] == "duduk" and info["row_names"][Config.MISI_KUCING_BARIS_HADAP] == "masuk", "JSON: 7 kolom, 4 baris, kolom 0 'duduk', baris 1 'masuk' (menghadap rumah seberang)")
	var impor: String = FileAccess.get_file_as_string("res://assets/sprites/npc/mission_kucing_sheet.png.import")
	check(impor.contains("compress/mode=0") and impor.contains("mipmaps/generate=false") and kucing.badan().texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "impor Lossless, tanpa mipmap, filter Nearest")
	check(kucing.badan().frame == KucingMisi.frame_duduk() and kucing.badan().hframes == 7 and kucing.badan().vframes == 4 and kucing.badan().offset == Vector2(-18, -21) and not kucing.badan().centered, "sprite: frame duduk baris masuk (7), titik pijak (18, 21) di titik asal")
	var t1: RencanaMisi.Titik = rencana.titik[0]
	_di(akar, maxf(t1.maju_ubin - 11.9, 0.0))
	check(kucing.tampil() and kucing.titik() == t1, "dalam jarak tampil sebelum kucing: kucing titik 1 tampil (MISI_TAMPIL_JARAK_UBIN)")
	check(kucing.position == Iso.posisi_gambar(Vector2(t1.lateral_ubin, -t1.maju_ubin)) and kucing.position == KucingMisi.posisi_gambar(t1), "posisi gambar = proyeksi iso titik kucing (lateral, -maju), dibulatkan ke piksel")
	check(kucing.get_parent() == akar.daur() and (kucing.get_parent() as Node2D).y_sort_enabled, "kucing anak induk Y-sort rumah (urutan gambar mengikuti titik pijak)")
	check(kucing.hiasan().get_parent() == kucing and kucing.visible, "hiasan kilau dan ekor menempel di kucing")
	_di(akar, t1.maju_ubin + 0.2)
	check(kucing.titik() != t1 and akar.keadaan_misi().langkah == 1, "kucing titik 1 dilewati: tidak lagi digambar, langkah 2 aktif")
	var t2: RencanaMisi.Titik = rencana.titik[1]
	_di(akar, t2.maju_ubin - 13.0)
	_di(akar, t2.maju_ubin - 11.0)
	check(kucing.tampil() and kucing.titik() == t2, "11 ubin sebelum kucing 2: kucing titik 2 tampil")
	# Jendela daur: kucing tidak pernah di luar jendela rumah.
	var jarak: float = _sepeda(akar).jarak_ubin
	check(kucing.titik().maju_ubin >= jarak - float(Config.RUTE_DAUR_MUNDUR_UBIN) and kucing.titik().maju_ubin <= jarak + float(Config.RUTE_DAUR_MAJU_UBIN), "kucing yang digambar selalu di dalam jendela daur rumah (-20 .. +30 ubin)")
	kucing.tampilkan(rencana.titik[2], 0.0, 0.0, 0.0, true, true)
	check(not kucing.tampil(), "titik di luar jendela daur (sepeda jauh): tidak digambar (tidak bocor)")
	# Hiasan: kilau dan ekor dari kode, dua frame; bar progres hanya bila progres > 0.
	check(KucingHiasan.frame_kilau(0.0) == 0 and KucingHiasan.frame_kilau(0.41) == 1 and KucingHiasan.frame_kilau(0.81) == 0 and KucingHiasan.frame_ekor(0.49) == 0 and KucingHiasan.frame_ekor(0.51) == 1, "kilau berganti frame tiap 0,4 detik dan ekor tiap 0,5 detik (dua frame)")
	check(KucingHiasan.perintah(true, true, 0.0, 0.0) != KucingHiasan.perintah(true, true, 0.0, 0.41) and KucingHiasan.perintah(true, false, 0.0, 0.0).size() < KucingHiasan.perintah(true, true, 0.0, 0.0).size(), "perintah gambar: frame kilau berbeda tiap pergantian, ekor menambah perintah")
	check(KucingHiasan.perintah(false, false, 0.0, 0.0).is_empty() and KucingHiasan.perintah(false, false, 0.5, 0.0).size() > 0, "tanpa kilau, ekor, dan progres: tidak ada gambar; progres menambah bar")
	check(PolaPiksel.KILAU_KUCING_1 != PolaPiksel.KILAU_KUCING_2 and PolaPiksel.EKOR_KUCING_1 != PolaPiksel.EKOR_KUCING_2, "dua frame kilau dan ekor berbeda bentuk")
	# QA-007: kilau dibesarkan (9x9 lalu 11x11, sebelumnya 7x7 dan 9x9), semua baris rata, frame kecil di tengah kotak 11x11 yang sama.
	var rata: bool = true
	for baris: String in PolaPiksel.KILAU_KUCING_1:
		rata = rata and baris.length() == 9
	for baris: String in PolaPiksel.KILAU_KUCING_2:
		rata = rata and baris.length() == 11
	check(rata and PolaPiksel.KILAU_KUCING_1.size() == 9 and PolaPiksel.KILAU_KUCING_2.size() == 11, "kilau: frame 1 berukuran 9x9 dan frame 2 berukuran 11x11 (dibesarkan dari 7x7 dan 9x9)")
	check(Config.MISI_KILAU_POSISI_PX == [-5, -33], "kotak kilau 11x11 berpojok (-5, -33) dari titik pijak: tengah di atas kepala kucing")
	var perintah_1: Array = KucingHiasan.perintah_kilau(0)
	var perintah_2: Array = KucingHiasan.perintah_kilau(1)
	check(perintah_1[0][1] == Vector2(-4.0, -32.0) and perintah_2[0][1] == Vector2(-5.0, -33.0), "frame 9x9 digambar di tengah kotak 11x11 (asal (-4, -32) lawan (-5, -33))")
	# Tanpa PNG baru untuk kilau/ekor: hanya satu PNG kucing di assets/sprites/npc.
	var png: Array[String] = []
	for nama: String in DirAccess.get_files_at("res://assets/sprites/npc"):
		if nama.ends_with(".png"):
			png.append(nama)
	check(png == ["mission_kucing_sheet.png"], "assets/sprites/npc hanya berisi mission_kucing_sheet.png (kilau dan ekor dari kode): %s" % [png])
	_bersihkan(akar)


func _test_penutup_kucing() -> void:
	_judul.call("Kucing lewat penerap penutup yang sama, tidak menimpa sasaran, tidak menambah rintangan (AC-12)")
	var akar: RuteMain = await _siapkan()
	var rencana: RencanaMisi.Rencana = akar.rencana_misi()
	var kucing: KucingMisi = akar.kucing()
	var penerap: PenerapPenutup = akar.penerap_penutup()
	var t1: RencanaMisi.Titik = rencana.titik[0]
	_di(akar, t1.maju_ubin - 8.0)
	check(kucing.tampil(), "kucing 1 tampil")
	var dengan: int = penerap.jumlah()
	kucing.sembunyikan()
	var sebelum: int = penerap.jumlah()
	check(dengan == sebelum + 1, "kucing tampil: terdaftar di SATU penerap penutup (jumlah tanpa kucing %d, dengan %d)" % [sebelum, dengan])
	_di(akar, t1.maju_ubin - 8.0)
	check(kucing.badan().modulate.a == 1.0, "pemain jauh dari kucing: kucing tidak transparan")
	# Pemain tepat di atas tapak kucing menutupinya dari kamera: alfa turun (aturan PenutupPemain, bukan aturan sendiri).
	var pemain: Vector2 = Vector2(t1.lateral_ubin, -t1.maju_ubin)
	var objek: PenutupPemain.Objek = PenutupPemain.buat(RencanaMisi.persegi_kucing(t1), Config.MISI_KUCING_TINGGI_UBIN, "x")
	check(PenutupPemain.menutupi(pemain, objek), "kontrol: pemain di tengah tapak kucing tertutup menurut PenutupPemain")
	_di(akar, t1.maju_ubin - 0.05, t1.lateral_ubin, 0.0)
	check(kucing.tampil() and kucing.titik() == t1, "pemain tepat di titik kucing: kucing 1 masih aktif")
	penerap.terapkan(_sepeda(akar).posisi_dunia())
	check(is_equal_approx(kucing.badan().modulate.a, Config.RUTE_PENUTUP_ALFA), "pemain di tapak kucing: kucing semi-transparan (alfa %.2f)" % kucing.badan().modulate.a)
	_di(akar, t1.maju_ubin + 0.2)
	var jumlah_sekarang: int = penerap.jumlah()
	var tampil_sekarang: bool = kucing.tampil()
	kucing.sembunyikan()
	check(kucing.titik() == null and jumlah_sekarang == penerap.jumlah() + (1 if tampil_sekarang else 0), "kucing 1 dilewati: yang terdaftar di penerap hanya kucing yang sedang tampil (tampil %s, jumlah %d -> %d sesudah disembunyikan)" % [tampil_sekarang, jumlah_sekarang, penerap.jumlah()])
	# Tidak menimpa zona kotak surat pelanggan: 60 seed (pembuktian murni ada di tes_misi.gd; di sini pada rute scene).
	for zona: ZonaSasaran.Zona in ZonaSasaran.zona_rute(akar.rute().rumah):
		if zona.jenis == ZonaSasaran.Jenis.KOTAK_SURAT and zona.pelanggan:
			for t: RencanaMisi.Titik in rencana.titik:
				if zona.persegi.intersects(RencanaMisi.persegi_kucing(t)):
					check(false, "kucing menimpa zona kotak surat %s" % zona.id_rumah)
	check(true, "persegi kucing tidak menimpa zona kotak surat pelanggan di rute hari 1")
	_bersihkan(akar)


# --- HUD, banner, koin (AC-13, AC-14) ---

func _test_hud_banner_dan_koin() -> void:
	_judul.call("HUD misi: kartu, sisa rumah, banner 1,5 detik, koin HUD = hasil (AC-13, AC-14)")
	var akar: RuteMain = await _siapkan()
	var hud: HudRute = akar.hud_rute()
	var rencana: RencanaMisi.Rencana = akar.rencana_misi()
	check(hud.kartu_tampil() and hud.teks_kartu() == "Kucing 0/1 · 12 rumah", "kartu awal: 'Kucing 0/1 · 12 rumah', dapat '%s'" % hud.teks_kartu())
	check(not hud.banner_tampil() and not hud.petunjuk_tampil(), "banner dan gelembung belum tampil")
	# Sisa rumah = 12 - rumah seberang yang akhir kavlingnya sudah dilewati (oracle tes dari rute).
	var seberang: Array[float] = []
	for r: RouteBuilder.RumahRute in akar.rute().rumah:
		if r.sisi == LoperAnim.Sisi.SEBERANG:
			seberang.append(r.maju_ubin + 4.0)
	for maju: float in [3.0, 9.5, 17.0, 26.0]:
		_di(akar, maju)
		var dilewati: int = 0
		for akhir: float in seberang.slice(0, 12):
			if akhir <= maju:
				dilewati += 1
		check(hud.teks_kartu() == "Kucing 0/1 · %d rumah" % (12 - dilewati), "maju %.1f: sisa %d rumah (oracle), kartu '%s'" % [maju, 12 - dilewati, hud.teks_kartu()])
	check(hud.teks_koin() == "0", "sebelum misi selesai koin HUD 0")
	# Selesaikan: banner 'Kucing ketemu! +75', kartu hilang, koin HUD 75.
	var peristiwa: Array[int] = _peristiwa_tercatat(akar)
	_selesaikan_misi(akar)
	check(akar.keadaan_misi().status == MissionManager.Status.SELESAI, "misi selesai lewat langkah nyata")
	check(peristiwa.count(MissionManager.Peristiwa.TERTANGKAP) == 1 and peristiwa.count(MissionManager.Peristiwa.GAGAL) == 0, "tepat satu TERTANGKAP dan tanpa GAGAL")
	check(hud.banner_tampil() and hud.teks_banner() == "Kucing ketemu! +75" and not hud.kartu_tampil(), "banner 'Kucing ketemu! +75' tampil dan kartu hilang")
	check(hud.teks_koin() == "75" and akar.call(&"_koin_tambahan") == 75, "koin HUD 75 sesudah selesai (hadiah K-1 dibayar saat selesai)")
	var lebar_banner: Rect2 = hud.rect_banner()
	check(lebar_banner.size.x > 0.0 and lebar_banner.size.y > 0.0, "banner punya ukuran")
	# Banner hilang sesudah 1,5 detik waktu efektif.
	_langkah(akar, 80)
	check(hud.banner_tampil(), "80 langkah (1,33 detik) kemudian banner masih tampil")
	_langkah(akar, 20)
	check(not hud.banner_tampil() and not hud.kartu_tampil() and hud.teks_koin() == "75", "sesudah 1,5 detik banner hilang; kartu tetap hilang; koin tetap 75")
	_di(akar, akar.rute().panjang_ubin - 1.0)
	_langkah(akar, 600)
	var angka: HasilRute.Angka = akar.angka_hasil()
	check(akar.hasil_tampil() and angka.koin == 75 and angka.koin_misi == 75 and angka.misi_hasil == "selesai", "koin HUD sebelum hasil = HasilRute.Angka.koin = 75 (satu sumber)")
	check(akar.layar_hasil().teks_rekap_misi() == "Misi: Kucing ketemu! +75 koin" and akar.layar_hasil().rect_rekap_misi().size.y > 0.0, "layar hasil: baris rekap 'Misi: Kucing ketemu! +75 koin'")
	_bersihkan(akar)


# --- Petunjuk di scene (AC-5b di scene, K-3) ---

func _test_petunjuk_di_scene() -> void:
	_judul.call("Petunjuk di scene: lemparan tepat memberi gelembung, suara, dan kucing lebih awal; bantu dan tidak tepat tidak (AC-5b, K-3, AC-15)")
	var audio: Node = _audio()
	var akar: RuteMain = await _siapkan()
	var hud: HudRute = akar.hud_rute()
	var rencana: RencanaMisi.Rencana = akar.rencana_misi()
	var t1: RencanaMisi.Titik = rencana.titik[0]
	var rumah: RouteBuilder.RumahRute = _pelanggan_di(akar, 0.0, t1.petunjuk_akhir_ubin)
	check(rumah != null, "ada pelanggan di jendela petunjuk titik 1 (rumah %s)" % [rumah.id if rumah != null else "-"])
	if rumah == null:
		_bersihkan(akar)
		return
	var peristiwa: Array[int] = _peristiwa_tercatat(akar)
	if audio != null:
		audio.call(&"atur_ulang_rute")
	var meong_awal: int = int(audio.call(&"jumlah_bunyi_misi", BunyiMisi.Bunyi.MEONG)) if audio != null else 0
	# Lemparan mode bantu (tap): tidak memberi petunjuk walau mendarat di kotak surat yang sama.
	check(_lempar_ke(akar, rumah, true), "lemparan bantu mendarat")
	check(not hud.petunjuk_tampil() and not peristiwa.has(MissionManager.Peristiwa.PETUNJUK), "lemparan bantu: tanpa petunjuk (K-3)")
	# Lemparan biasa tepat ke pelanggan di jendela langkah 2 (jendela langkah 1 sudah berisi lemparan bantu tadi): petunjuk untuk langkah 2.
	var t2: RencanaMisi.Titik = akar.rencana_misi().titik[1]
	var lain: RouteBuilder.RumahRute = _pelanggan_di(akar, t2.petunjuk_awal_ubin, t2.petunjuk_akhir_ubin)
	check(lain != null, "ada pelanggan di jendela petunjuk titik 2")
	if lain != null:
		check(_lempar_ke(akar, lain, false), "lemparan biasa mendarat")
		check(hud.petunjuk_tampil() and hud.teks_petunjuk() == "Tadi ada kucing lewat ke arah warung" and peristiwa.has(MissionManager.Peristiwa.PETUNJUK), "lemparan tepat di jendela: gelembung 'Tadi ada kucing lewat ke arah warung' dan peristiwa PETUNJUK")
		check(audio == null or int(audio.call(&"jumlah_bunyi_misi", BunyiMisi.Bunyi.MEONG)) == meong_awal + 1, "bunyi meong diputuskan tepat sekali (pasangan visual: gelembung)")
		check(akar.keadaan_misi().petunjuk[1] and not akar.keadaan_misi().petunjuk[0] and akar.keadaan_misi().petunjuk_sisa >= 2.0, "petunjuk tercatat untuk langkah 2 dan gelembung bertahan >= 2 detik (prinsip 3)")
		_langkah(akar, 100)
		check(hud.petunjuk_tampil(), "1,67 detik kemudian gelembung masih tampil")
		_langkah(akar, 70)
		check(not hud.petunjuk_tampil(), "sesudah 2,5 detik gelembung hilang")
	# Lemparan tidak tepat (ke halaman): tidak memberi petunjuk.
	var akar2: RuteMain = await _siapkan()
	var rumah2: RouteBuilder.RumahRute = _pelanggan_di(akar2, 0.0, akar2.rencana_misi().titik[0].petunjuk_akhir_ubin)
	var sepeda2: SepedaUji = _sepeda(akar2)
	_taruh(akar2, 3.0, 0.5, rumah2.maju_ubin - 2.0)
	akar2.perbarui(0.0)
	akar2.koran = SisaKoran.awal(30)
	var mendarat: Array[KoranLempar.Koran] = []
	akar2.koran_mendarat.connect(func(k: KoranLempar.Koran) -> void: mendarat.append(k))
	var halaman: Vector2 = Vector2(Config.JALAN_UJI_SEBERANG_HALAMAN_UBIN[0] + 0.2, -(rumah2.maju_ubin + 0.0))
	var lepas: Vector2 = ThrowSolver.titik_lepas(sepeda2.posisi_dunia(), sepeda2.kecepatan_ud, sepeda2.lateral_ud, sepeda2.jeda_lepas(LoperAnim.Sisi.SEBERANG))
	var u: float = BantuLempar.cari_kekuatan(halaman, lepas, sepeda2.kecepatan_ud)
	if u >= 0.0:
		var lintasan: ThrowSolver.Lintasan = ThrowSolver.hitung(ThrowSolver.panjang_untuk_kekuatan(u, 780.0), 780.0, BantuLempar.arah_ke(halaman, lepas, sepeda2.kecepatan_ud, u), sepeda2.posisi_dunia(), sepeda2.kecepatan_ud, sepeda2.lateral_ud, sepeda2.jeda_lepas(LoperAnim.Sisi.SEBERANG))
		akar2.call(&"_lempar", lintasan, false)
		for i: int in range(200):
			akar2.perbarui(DT)
			if not mendarat.is_empty():
				break
		check(not mendarat.is_empty() and not mendarat[0].tepat and not akar2.hud_rute().petunjuk_tampil() and not akar2.keadaan_misi().petunjuk[0], "lemparan ke halaman (tidak tepat): tanpa petunjuk")
	else:
		check(true, "(titik halaman tidak terjangkau dari posisi uji; dilewati)")
	_bersihkan(akar)
	_bersihkan(akar2)


## Koran yang mendarat di zona kotak surat pelanggan tetapi di luar inti "tepat" TIDAK memberi petunjuk (K-3, AC-5b, QA-003): kena kotak surat bukan berarti tepat.
## Satu-satunya tempat `SkorRute.Hasil.tepat` masuk misi adalah `RuteMain._koran_dinilai`; mutan `tepat or hasil == KOTAK_SURAT` harus merah di sini.
func _test_kotak_surat_bukan_inti() -> void:
	_judul.call("Petunjuk: koran kena kotak surat pelanggan di luar inti tepat tidak memberi petunjuk di scene; kontrol: tepat di inti memberi (K-3, QA-003)")
	var akar: RuteMain = await _siapkan()
	var t1: RencanaMisi.Titik = akar.rencana_misi().titik[0]
	var rumah: RouteBuilder.RumahRute = _pelanggan_di(akar, 0.0, t1.petunjuk_akhir_ubin)
	check(rumah != null, "ada pelanggan di jendela petunjuk titik 1")
	if rumah == null:
		_bersihkan(akar)
		return
	var zona: ZonaSasaran.Zona = null
	for z: ZonaSasaran.Zona in ZonaSasaran.zona_rute(akar.rute().rumah):
		if z.jenis == ZonaSasaran.Jenis.KOTAK_SURAT and z.pelanggan and z.id_rumah == rumah.id:
			zona = z
	check(zona != null and zona.inti.size.x > 0.0, "zona kotak surat pelanggan %s punya inti 'tepat'" % rumah.id)
	if zona == null:
		_bersihkan(akar)
		return
	# Titik di dalam persegi zona tetapi di luar inti (pojok dalam persegi).
	var titik_luar: Vector2 = Vector2.INF
	for geser: Vector2 in [Vector2(0.04, 0.04), Vector2(0.04, 0.0), Vector2(0.0, 0.04), Vector2(0.0, 0.0)]:
		var calon: Vector2 = zona.persegi.position + geser
		if zona.persegi.has_point(calon) and not zona.inti.has_point(calon):
			titik_luar = calon
			break
	check(titik_luar != Vector2.INF, "ada titik di dalam persegi zona kotak surat dan di luar inti: %s" % [titik_luar])
	var sepeda: SepedaUji = _sepeda(akar)
	_taruh(akar, 3.0, 0.5, ZonaSasaran.maju_kotak_surat(rumah) - 2.0)
	akar.perbarui(0.0)
	akar.koran = SisaKoran.awal(30)
	var mendarat: Array[KoranLempar.Koran] = []
	akar.koran_mendarat.connect(func(k: KoranLempar.Koran) -> void: mendarat.append(k))
	var tujuan: Vector2 = Vector2(titik_luar.x, -titik_luar.y)
	var lepas: Vector2 = ThrowSolver.titik_lepas(sepeda.posisi_dunia(), sepeda.kecepatan_ud, sepeda.lateral_ud, sepeda.jeda_lepas(LoperAnim.Sisi.SEBERANG))
	var u: float = BantuLempar.cari_kekuatan(tujuan, lepas, sepeda.kecepatan_ud)
	check(u >= 0.0, "titik luar inti terjangkau dari posisi uji (kekuatan %.3f)" % u)
	if u >= 0.0:
		var lintasan: ThrowSolver.Lintasan = ThrowSolver.hitung(ThrowSolver.panjang_untuk_kekuatan(u, 780.0), 780.0, BantuLempar.arah_ke(tujuan, lepas, sepeda.kecepatan_ud, u), sepeda.posisi_dunia(), sepeda.kecepatan_ud, sepeda.lateral_ud, sepeda.jeda_lepas(LoperAnim.Sisi.SEBERANG))
		akar.call(&"_lempar", lintasan, false)
		for i: int in range(200):
			akar.perbarui(DT)
			if not mendarat.is_empty():
				break
		check(not mendarat.is_empty() and mendarat[0].hasil == ZonaSasaran.Hasil.KOTAK_SURAT and not mendarat[0].tepat and mendarat[0].id_rumah == rumah.id, "premis: koran mendarat di kotak surat pelanggan %s (hasil KOTAK_SURAT) tetapi bukan 'tepat'" % rumah.id)
		check(not akar.hud_rute().petunjuk_tampil() and not akar.keadaan_misi().petunjuk[0] and akar.keadaan_misi().petunjuk_sisa == 0.0, "kena kotak surat di luar inti: tanpa gelembung dan tanpa petunjuk tercatat")
		var peristiwa_petunjuk: int = 0
		for p: bool in akar.keadaan_misi().petunjuk:
			peristiwa_petunjuk += 1 if p else 0
		check(peristiwa_petunjuk == 0, "tidak ada langkah yang mendapat petunjuk (%d)" % peristiwa_petunjuk)
	_bersihkan(akar)
	# Kontrol: lemparan tepat ke rumah yang sama memberi petunjuk (premis tes benar-benar membedakan).
	var kontrol: RuteMain = await _siapkan()
	var rumah_k: RouteBuilder.RumahRute = _pelanggan_di(kontrol, 0.0, kontrol.rencana_misi().titik[0].petunjuk_akhir_ubin)
	check(_lempar_ke(kontrol, rumah_k, false) and kontrol.keadaan_misi().petunjuk[0] and kontrol.hud_rute().petunjuk_tampil(), "kontrol: lemparan tepat di inti ke rumah yang sama memberi petunjuk")
	_bersihkan(kontrol)


# --- Tangkap, jeda, jatuh (AC-5c di scene, AC-13) ---

func _test_tangkap_jeda_dan_jatuh() -> void:
	_judul.call("Tangkap di scene: progres bar, jeda membekukan timer dan banner, jatuh menahan timer (AC-5c, AC-13)")
	var akar: RuteMain = await _siapkan()
	var rencana: RencanaMisi.Rencana = akar.rencana_misi()
	var t1: RencanaMisi.Titik = rencana.titik[0]
	var t2: RencanaMisi.Titik = rencana.titik[1]
	var t3: RencanaMisi.Titik = rencana.titik[2]
	_di(akar, t1.maju_ubin + 0.1, 0.5, 0.5)
	_di(akar, t2.maju_ubin + 0.1, 0.5, 0.5)
	_di(akar, t3.maju_ubin - 8.0, 0.5, 0.5)
	check(akar.kucing().tampil() and akar.kucing().titik() == t3 and akar.keadaan_misi().langkah == 2, "kucing tangkap tampil dan aktif")
	var kilau_awal: int = KucingHiasan.perintah(true, true, 0.0, 0.0).size()
	check(kilau_awal > 0, "kilau dan ekor menghasilkan perintah gambar")
	for i: int in range(45):
		_di(akar, t3.maju_ubin - 0.5, -1.0, 0.0)
	var timer: float = akar.keadaan_misi().timer_detik
	check(absf(timer - 0.75) < 0.001, "45 langkah diam di radius: timer 0,75 detik (dihitung tes: 45 / 60), dapat %.3f" % timer)
	check(KucingHiasan.perintah(true, true, timer / t3.lama_berhenti_detik, 0.0).size() > kilau_awal, "bar progres ikut digambar saat timer berjalan")
	# Jeda: timer dan banner membeku.
	akar.minta_jeda()
	_langkah(akar, 120)
	check(is_equal_approx(akar.keadaan_misi().timer_detik, timer), "saat jeda game timer tangkap tidak maju dan tidak direset (tetap %.3f)" % timer)
	akar.minta_lanjut()
	# Jatuh sesudah tabrakan: timer tidak maju dan tidak direset walau pemain di radius.
	akar.rintangan().tabrakan.jatuh_detik = 50.0
	for i: int in range(30):
		_di(akar, t3.maju_ubin - 0.5, -1.0, 0.0)
		akar.rintangan().tabrakan.jatuh_detik = 50.0
	check(is_equal_approx(akar.keadaan_misi().timer_detik, timer), "saat jatuh timer tetap %.3f (tidak maju, tidak direset)" % timer)
	akar.rintangan().tabrakan.jatuh_detik = 0.0
	for i: int in range(60):
		_di(akar, t3.maju_ubin - 0.5, -1.0, 0.0)
		if akar.keadaan_misi().status != MissionManager.Status.AKTIF:
			break
	check(akar.keadaan_misi().status == MissionManager.Status.SELESAI, "sesudah bangun timer lanjut dari nilai lama dan misi selesai")
	# Banner membeku saat jeda game.
	var sisa: float = akar.keadaan_misi().banner_sisa
	akar.minta_jeda()
	_langkah(akar, 200)
	check(is_equal_approx(akar.keadaan_misi().banner_sisa, sisa) and akar.hud_rute().banner_tampil(), "banner membeku saat jeda game")
	akar.minta_lanjut()
	_bersihkan(akar)


# --- Gagal tidak mengubah apa pun (AC-5d, prinsip 2) ---

func _test_gagal_tidak_mengubah_apa_pun() -> void:
	_judul.call("Gagal di scene: banner tidak menyalahkan, tanpa efek pada koin, tip, skor, tenggat, atau hasil antaran (AC-5d, AC-14, prinsip 2)")
	var peristiwa: Array[int] = []
	var hasil_gagal: Dictionary = {}
	var hasil_tanpa: Dictionary = {}
	for dengan_misi: bool in [true, false]:
		var akar: RuteMain = await _siapkan(dengan_misi)
		if dengan_misi:
			peristiwa = _peristiwa_tercatat(akar)
		var rumah: RouteBuilder.RumahRute = akar.rute().pelanggan[0]
		_lempar_ke(akar, rumah, false)
		var koin_sebelum: int = akar.skor().koin
		var tenggat_awal: float = akar.tenggat().waktu_detik
		var tujuan: float = akar.rencana_misi().maju_batas_ubin + 0.3 if dengan_misi else akar.rencana_misi() == null and 100.0
		_di(akar, 100.0 if not dengan_misi else float(tujuan))
		var hud: HudRute = akar.hud_rute()
		if dengan_misi:
			check(akar.keadaan_misi().status == MissionManager.Status.GAGAL and peristiwa.count(MissionManager.Peristiwa.GAGAL) == 1, "melewati rumah ke-12: misi GAGAL, tepat satu peristiwa")
			check(hud.banner_tampil() and hud.teks_banner() == "Kucingnya lolos hari ini" and not hud.kartu_tampil(), "banner 'Kucingnya lolos hari ini' (tidak menyalahkan), kartu hilang")
			check(not hud.teks_banner().to_lower().contains("gagal") and not hud.teks_banner().to_lower().contains("salah"), "banner gagal tanpa kata 'gagal' atau 'salah'")
			check(hud.teks_koin() == str(koin_sebelum) and akar.call(&"_koin_tambahan") == 0, "koin HUD tetap %d saat gagal (tidak berubah)" % koin_sebelum)
		hasil_gagal[dengan_misi] = [akar.skor().koin, akar.skor().koin_tip, akar.skor().skor, akar.skor().jumlah_tepat, akar.skor().terantar.size()]
		_di(akar, akar.rute().panjang_ubin - 1.0)
		_langkah(akar, 600)
		var a: HasilRute.Angka = akar.angka_hasil()
		hasil_tanpa[dengan_misi] = [a.koin, a.koin_tip, a.skor, a.terkirim, a.meleset, a.jumlah_tepat]
		check(is_equal_approx(tenggat_awal, akar.tenggat().waktu_detik) or akar.tenggat().waktu_detik >= tenggat_awal, "tenggat tidak diubah oleh misi: jam hanya maju oleh waktu (waktu_detik %.3f >= %.3f)" % [akar.tenggat().waktu_detik, tenggat_awal])
		if dengan_misi:
			check(a.misi_hasil == "gagal" and a.koin_misi == 0 and akar.layar_hasil().teks_rekap_misi() == "Misi: Kucingnya lolos hari ini", "hasil: misi gagal, koin misi 0, rekap 'Misi: Kucingnya lolos hari ini'")
			check(akar.hasil_tampil() and akar.keadaan_misi().status != MissionManager.Status.AKTIF, "layar hasil terbuka: misi tidak pernah masih aktif")
		_bersihkan(akar)
	# Langsung ke garis akhir dari awal rute (tanpa melewati rumah ke-12 lebih dulu di langkah terpisah): misi gagal di langkah yang sama dengan akhir rute, sebelum layar hasil (QA-004).
	var loncat: RuteMain = await _siapkan()
	_di(loncat, loncat.rute().panjang_ubin + 0.5)
	check(loncat.keadaan_misi().status == MissionManager.Status.GAGAL, "loncat ke garis akhir: misi GAGAL pada langkah yang sama")
	_langkah(loncat, 600)
	check(loncat.hasil_tampil() and loncat.angka_hasil().misi_hasil == "gagal" and loncat.keadaan_misi().status == MissionManager.Status.GAGAL, "layar hasil terbuka dengan misi gagal (tanpa cabang penutup misi aktif di RuteMain)")
	_bersihkan(loncat)
	check(hasil_gagal[true] == hasil_gagal[false], "skor rute (koin, tip, skor, tepat, terantar) identik dengan dan tanpa misi gagal: %s vs %s" % [hasil_gagal[true], hasil_gagal[false]])
	check(hasil_tanpa[true] == hasil_tanpa[false], "angka layar hasil (koin, tip, skor, terkirim, meleset, tepat) identik dengan dan tanpa misi gagal: %s vs %s" % [hasil_tanpa[true], hasil_tanpa[false]])


# --- Bunyi (AC-15) ---

func _test_bunyi_misi() -> void:
	_judul.call("Bunyi misi: pemetaan peristiwa -> bunyi (murni), bunyi tidak berjalan saat jeda, tiap bunyi punya pasangan visual (AC-15)")
	check(BunyiMisi.berbunyi(MissionManager.Peristiwa.PETUNJUK) and BunyiMisi.dari_peristiwa(MissionManager.Peristiwa.PETUNJUK) == BunyiMisi.Bunyi.MEONG, "PETUNJUK -> meong")
	check(BunyiMisi.dari_peristiwa(MissionManager.Peristiwa.TERLIHAT) == BunyiMisi.Bunyi.TERLIHAT and BunyiMisi.dari_peristiwa(MissionManager.Peristiwa.TERTANGKAP) == BunyiMisi.Bunyi.SELESAI and BunyiMisi.dari_peristiwa(MissionManager.Peristiwa.GAGAL) == BunyiMisi.Bunyi.GAGAL, "TERLIHAT -> terlihat, TERTANGKAP -> selesai, GAGAL -> gagal")
	check(not BunyiMisi.berbunyi(MissionManager.Peristiwa.LANGKAH_SELESAI), "LANGKAH_SELESAI tidak berbunyi sendiri")
	var semua: Array[String] = BunyiMisi.semua_berkas()
	var ada: bool = semua.size() == 4
	for berkas: String in semua:
		ada = ada and FileAccess.file_exists(berkas) and load(berkas) is AudioStream
	check(ada, "keempat berkas bunyi ada dan terbaca sebagai AudioStream")
	check(BunyiMisi.volume_db(BunyiMisi.Bunyi.GAGAL) < BunyiMisi.volume_db(BunyiMisi.Bunyi.SELESAI) and BunyiMisi.volume_db(BunyiMisi.Bunyi.MEONG) == Config.AUDIO_MISI_VOLUME_DB, "bunyi gagal lebih pelan dari bunyi lain (lembut)")
	var audio: Node = _audio()
	if audio == null:
		check(false, "autoload Audio ada")
		return
	var akar: RuteMain = await _siapkan()
	audio.call(&"atur_ulang_rute")
	var rencana: RencanaMisi.Rencana = akar.rencana_misi()
	var terlihat_awal: int = int(audio.call(&"jumlah_bunyi_misi", BunyiMisi.Bunyi.TERLIHAT))
	var t2: RencanaMisi.Titik = rencana.titik[1]
	_di(akar, rencana.titik[0].maju_ubin + 0.1)
	var sesudah_satu: int = int(audio.call(&"jumlah_bunyi_misi", BunyiMisi.Bunyi.TERLIHAT))
	_di(akar, t2.maju_ubin - 11.9)
	check(int(audio.call(&"jumlah_bunyi_misi", BunyiMisi.Bunyi.TERLIHAT)) == maxi(sesudah_satu, terlihat_awal + 2) or int(audio.call(&"jumlah_bunyi_misi", BunyiMisi.Bunyi.TERLIHAT)) >= terlihat_awal + 1, "kucing 2 mulai terlihat: bunyi terlihat bertambah (pasangan visual: kilau)")
	var sesudah_dua: int = int(audio.call(&"jumlah_bunyi_misi", BunyiMisi.Bunyi.TERLIHAT))
	_di(akar, t2.maju_ubin - 8.0)
	check(int(audio.call(&"jumlah_bunyi_misi", BunyiMisi.Bunyi.TERLIHAT)) == sesudah_dua, "bunyi terlihat tidak berulang untuk kucing yang sama")
	# Selama jeda tidak ada bunyi baru (Audio.atur_jeda).
	akar.minta_jeda()
	audio.call(&"putar_misi", BunyiMisi.Bunyi.MEONG)
	check(int(audio.call(&"jumlah_bunyi_misi", BunyiMisi.Bunyi.MEONG)) == 0 and not bool(audio.call(&"ada_bunyi_misi")), "saat jeda: bunyi misi tidak diputuskan dan tidak ada yang berbunyi")
	akar.minta_lanjut()
	_selesaikan_misi(akar)
	check(int(audio.call(&"jumlah_bunyi_misi", BunyiMisi.Bunyi.SELESAI)) == 1 and int(audio.call(&"jumlah_bunyi_misi", BunyiMisi.Bunyi.GAGAL)) == 0, "misi selesai: bunyi selesai tepat sekali, tanpa bunyi gagal")
	check(audio.call(&"bunyi_misi_terakhir") == BunyiMisi.berkas(BunyiMisi.Bunyi.SELESAI), "bunyi misi terakhir = berkas selesai")
	_bersihkan(akar)
	var akar2: RuteMain = await _siapkan()
	audio.call(&"atur_ulang_rute")
	_di(akar2, akar2.rencana_misi().maju_batas_ubin + 0.3)
	check(int(audio.call(&"jumlah_bunyi_misi", BunyiMisi.Bunyi.GAGAL)) == 1 and int(audio.call(&"jumlah_bunyi_misi", BunyiMisi.Bunyi.SELESAI)) == 0, "misi gagal: bunyi gagal tepat sekali")
	audio.call(&"hentikan_lempar")
	_bersihkan(akar2)


# --- Mode bantu (AC-6 di scene, K-3) ---

func _test_mode_bantu() -> void:
	_judul.call("Mode bantu di scene: stick tetap menangkap, tap tidak memberi petunjuk, kecepatan otomatis 3,0 tidak menangkap (AC-6, K-3)")
	var akar: RuteMain = await _siapkan()
	akar.atur_mode_bantu(true)
	var rencana: RencanaMisi.Rencana = akar.rencana_misi()
	var t1: RencanaMisi.Titik = rencana.titik[0]
	var t2: RencanaMisi.Titik = rencana.titik[1]
	var t3: RencanaMisi.Titik = rencana.titik[2]
	_di(akar, t1.maju_ubin + 0.1, 0.5, 3.0)
	_di(akar, t2.maju_ubin + 0.1, 0.5, 3.0)
	for i: int in range(300):
		_di(akar, t3.maju_ubin, -1.0, Config.KECEPATAN_SANTAI_UD)
	check(akar.mode_bantu() and akar.keadaan_misi().status == MissionManager.Status.AKTIF and akar.keadaan_misi().ditangkap == 0, "mode bantu, kecepatan otomatis 3,0 u/d di titik kucing selama 5 detik: tidak menangkap (tanpa auto-tangkap)")
	for i: int in range(100):
		_di(akar, t3.maju_ubin - 0.5, -1.0, 0.0)
	check(akar.keadaan_misi().status == MissionManager.Status.SELESAI, "mode bantu tetap menyala: melambat sendiri (stick) dan berhenti menangkap kucing")
	_bersihkan(akar)


# --- Tutorial di scene (AC-18) ---

func _test_tutorial_di_scene() -> void:
	_judul.call("Tutorial di scene: empat langkah dari keadaan nyata, Lewati, tidak memblokir input, rute.tscn sendiri tanpa tutorial (AC-18)")
	var akar: RuteMain = await _siapkan(true, true)
	var tut: TutorialController = akar.tutorial_node()
	check(akar.keadaan_tutorial() != null and tut.tampil() and tut.teks() == "Dorong stick ke atas untuk ngebut" and tut.teks_langkah() == "PETUNJUK 1/4", "tutorial langkah 1 dari 4 (dengan misi) tampil")
	_di(akar, 3.0, 0.5, 5.0)
	check(tut.teks() == "Tarik stick ke bawah untuk melambat" and tut.teks_langkah() == "PETUNJUK 2/4", "kecepatan 5,0 >= 4,5: langkah 2 (melambat)")
	_di(akar, 4.0, 0.5, 1.8)
	check(tut.teks() == "Lempar koran ke kotak surat", "kecepatan 1,8 <= 2,0: langkah 3 (lempar)")
	# QA-005: teks lempar netral terhadap kidal (zona swipe pindah sisi) dan mode bantu (melempar dengan ketuk): tanpa kata arah layar atau gerakan tertentu.
	var teks_lempar: String = tut.teks().to_lower()
	check(not teks_lempar.contains("kanan") and not teks_lempar.contains("kiri") and not teks_lempar.contains("usap") and not teks_lempar.contains("ketuk") and not teks_lempar.contains("geser"), "teks langkah lempar netral terhadap kidal dan mode bantu (tanpa kanan, kiri, usap, ketuk, geser): '%s'" % tut.teks())
	var rumah: RouteBuilder.RumahRute = akar.rute().pelanggan[0]
	_lempar_ke(akar, rumah, false)
	check(akar.jumlah_lempar() == 1 and akar.keadaan_tutorial().langkah == TutorialLangkah.Langkah.MENEPI and not tut.tampil(), "satu lemparan diterima: langkah 4 (menepi) menunggu kucing tangkap terlihat (belum tampil)")
	var t3: RencanaMisi.Titik = akar.rencana_misi().titik[2]
	_di(akar, akar.rencana_misi().titik[1].maju_ubin + 0.1, 0.5, 3.0)
	_di(akar, t3.maju_ubin - 8.0, 0.5, 3.0)
	check(tut.tampil() and tut.teks() == "Menepi dan berhenti dekat kucing" and tut.teks_langkah() == "PETUNJUK 4/4", "kucing tangkap terlihat: petunjuk menepi tampil")
	_selesaikan_misi(akar)
	check(not tut.tampil() and TutorialLangkah.berakhir(akar.keadaan_tutorial()) and akar.tutorial_dimulai(), "misi berakhir: tutorial selesai dan tersembunyi; tutorial_dimulai tetap true (untuk ditulis di akhir hari)")
	_bersihkan(akar)
	# Lewati.
	var b: RuteMain = await _siapkan(true, true)
	check(b.tutorial_node().tampil() and b.tutorial_node().tombol_lewati().get_global_rect().size.y >= 42.0 and b.tutorial_node().tombol_lewati().get_global_rect().size.x >= 42.0, "tombol Lewati tampil dan >= 42 px game dua sisi")
	b.tutorial_node().tombol_lewati().ditekan.emit()
	check(not b.tutorial_node().tampil() and b.keadaan_tutorial().dilewati and TutorialLangkah.berakhir(b.keadaan_tutorial()), "Lewati: tutorial berakhir seketika dan tersembunyi")
	_di(b, 4.0, 0.5, 5.0)
	check(not b.tutorial_node().tampil(), "sesudah dilewati tidak muncul lagi walau kondisi langkah terpenuhi")
	_bersihkan(b)
	# Tanpa misi: tiga langkah, tanpa langkah menepi.
	var c: RuteMain = await _siapkan(false, true)
	check(c.tutorial_node().teks_langkah() == "PETUNJUK 1/3", "tanpa misi: tiga petunjuk (1/3)")
	_di(c, 3.0, 0.5, 5.0)
	_di(c, 4.0, 0.5, 1.8)
	_lempar_ke(c, c.rute().pelanggan[0], false)
	check(not c.tutorial_node().tampil() and TutorialLangkah.berakhir(c.keadaan_tutorial()), "tanpa misi: sesudah lemparan tutorial selesai (tanpa langkah menepi)")
	_bersihkan(c)
	# rute.tscn sendiri tanpa atur_tutorial: tidak ada tutorial; tidak memblokir input: hanya tombol Lewati yang menerima sentuhan GUI.
	var d: RuteMain = await _siapkan(true, true)
	var penerima: Array[Control] = d.tutorial_node().kontrol_penerima_sentuhan()
	check(penerima.size() == 1 and penerima[0] == d.tutorial_node().tombol_lewati(), "satu-satunya kontrol tutorial yang menerima sentuhan GUI adalah tombol Lewati (panel dan label IGNORE)")
	var router: TouchRouter = d.kontrol_router()
	_sentuh(1, Vector2(100, 260), true)
	check(router.stick_aktif(), "tutorial aktif: sentuhan di zona stick tetap sampai ke router (stick aktif)")
	_sentuh(1, Vector2(100, 260), false)
	var swipe_awal: Vector2 = Vector2(500, 250)
	_sentuh(2, swipe_awal, true)
	check(router.swipe_aktif(), "tutorial aktif: sentuhan di zona swipe tetap sampai ke router (swipe aktif)")
	_sentuh(2, swipe_awal, false)
	var bel: Vector2 = TouchZones.pusat_bel(780, false)
	var kring_awal: int = d.bel().jumlah
	_sentuh(3, bel, true)
	_sentuh(3, bel, false)
	check(TouchZones.zona_di(bel, 780, false) == TouchZones.Zona.BEL and d.bel().jumlah == kring_awal + 1, "ketukan di zona bel saat tutorial aktif tetap berbunyi (sentuhan tidak ditelan)")
	_bersihkan(d)


# --- Penanda tepi layar kucing (M-2', M-3', QA-001, QA-002) ---

## Sepeda ngebut di `maju`/`lateral` sampai dorongan kamera mendekati mantap (langkah berulang di titik yang sama).
func _ngebut_di(akar: RuteMain, maju: float, lateral: float) -> void:
	for i: int in range(45):
		_di(akar, maju, lateral, Config.KECEPATAN_NGEBUT_UD)


## True bila ada penanda HUD untuk titik `titik`.
func _titik_ada(penanda: PenandaKucing, titik: int) -> bool:
	for p: TampilMisi.Penanda in penanda.penanda_tampil():
		if p.titik == titik:
			return true
	return false


## True bila badan kucing titik `t` utuh di area layar untuk keadaan sepeda sekarang.
func _badan_utuh(akar: RuteMain, t: RencanaMisi.Titik) -> bool:
	var sepeda: SepedaUji = _sepeda(akar)
	return TampilMisi.badan_terlihat(TampilMisi.kaki_kucing(akar.posisi_layar_sepeda(), sepeda.lateral_ubin, sepeda.jarak_ubin, t.lateral_ubin, t.maju_ubin), akar.hud_rute().area_misi())


## Penanda yang diharapkan HUD untuk keadaan scene sekarang (fungsi murni yang sama dengan `RuteMain`, masukan dibaca dari node nyata).
func _penanda_diharapkan(akar: RuteMain) -> Array[TampilMisi.Penanda]:
	var ukuran: Vector2 = akar.get_viewport_rect().size
	var sepeda: SepedaUji = _sepeda(akar)
	return TampilMisi.penanda_aktif(akar.keadaan_misi(), TampilMisi.sepeda_layar(ukuran, akar.geser_dorongan()), sepeda.lateral_ubin, sepeda.jarak_ubin, akar.hud_rute().area_misi(), ukuran.y)


func _test_penanda_dan_petunjuk_di_scene() -> void:
	_judul.call("Penanda tepi layar di scene: tampil bila kucing terlihat tetapi badan belum utuh; hilang saat utuh, dilewati, misi berakhir, atau tanpa misi (M-2')")
	var akar: RuteMain = await _siapkan()
	var hud: HudRute = akar.hud_rute()
	var penanda: PenandaKucing = hud.penanda_kucing()
	var rencana: RencanaMisi.Rencana = akar.rencana_misi()
	var t1: RencanaMisi.Titik = rencana.titik[0]
	check(penanda.mouse_filter == Control.MOUSE_FILTER_IGNORE and penanda.get_parent() == hud, "node penanda tepi layar non-interaktif (mouse_filter abaikan), anak HUD rute")
	var t2_awal: RencanaMisi.Titik = rencana.titik[1]
	_ngebut_di(akar, t2_awal.maju_ubin - Config.MISI_TAMPIL_JARAK_UBIN - 0.5, 0.0)
	check(not akar.keadaan_misi().tampil[1] and _titik_ada(penanda, 1) == false, "kucing 2: 0,5 ubin sebelum jarak tampil (%.1f): belum terlihat dan tanpa penanda" % Config.MISI_TAMPIL_JARAK_UBIN)
	_ngebut_di(akar, t2_awal.maju_ubin - Config.MISI_TAMPIL_JARAK_UBIN + 0.1, 0.0)
	check(akar.keadaan_misi().tampil[1] and _titik_ada(penanda, 1), "kucing 2: tepat di dalam jarak tampil: terlihat dan satu penanda untuk titik 1")
	_bersihkan(akar)
	akar = await _siapkan()
	hud = akar.hud_rute()
	penanda = hud.penanda_kucing()
	rencana = akar.rencana_misi()
	t1 = rencana.titik[0]
	_ngebut_di(akar, maxf(t1.maju_ubin - 13.0, 0.0), 2.0)
	check(akar.keadaan_misi().tampil[0] and not _badan_utuh(akar, t1) and _titik_ada(penanda, 0), "kucing 1 13 ubin di depan dari lajur dekat (lateral +2): terlihat, badan belum utuh di layar, satu penanda untuk titik 0")
	var rect: Rect2 = penanda.rect_penanda()[0]
	var layar: Rect2 = Rect2(Vector2.ZERO, akar.get_viewport_rect().size)
	check(layar.encloses(rect) and rect.position.y >= float(Config.MISI_PENANDA_ATAS_PX), "penanda utuh di layar dan di bawah strip HUD atas: %s" % [rect])
	var pusat_diharapkan: Array[TampilMisi.Penanda] = _penanda_diharapkan(akar)
	check(pusat_diharapkan.size() == 1 and pusat_diharapkan[0].titik == 0 and (pusat_diharapkan[0].pusat - penanda.penanda_tampil()[0].pusat).length() <= 2.0, "posisi penanda di HUD = TampilMisi.penanda_aktif dari keadaan nyata sepeda dan kamera (selisih <= 2 piksel: dorongan kamera masih bergeser sedikit tiap langkah)")
	# Rumus kaki kucing sama dengan gambar nyata (kamera, dorongan, pembulatan piksel): selisih kurang dari 2 piksel.
	_ngebut_di(akar, t1.maju_ubin - 8.0, 0.0)
	var kucing: KucingMisi = akar.kucing()
	var sepeda: SepedaUji = _sepeda(akar)
	var sepeda_layar: Vector2 = akar.posisi_layar_sepeda()
	check((TampilMisi.sepeda_layar(akar.get_viewport_rect().size, akar.geser_dorongan()) - sepeda_layar).length() < 2.0, "sepeda di layar menurut TampilMisi = posisi sepeda nyata (selisih %s)" % [TampilMisi.sepeda_layar(akar.get_viewport_rect().size, akar.geser_dorongan()) - sepeda_layar])
	var kaki: Vector2 = TampilMisi.kaki_kucing(sepeda_layar, sepeda.lateral_ubin, sepeda.jarak_ubin, t1.lateral_ubin, t1.maju_ubin)
	var kaki_nyata: Vector2 = kucing.global_position - sepeda.global_position + sepeda_layar
	check(kucing.tampil() and (kaki_nyata - kaki).length() < 2.0, "kaki kucing menurut TampilMisi = titik pijak gambar nyata relatif sepeda (selisih %s)" % [kaki_nyata - kaki])
	# Badan utuh di area: kucing aktif tanpa penanda.
	_ngebut_di(akar, t1.maju_ubin - 4.0, t1.lateral_ubin)
	check(TampilMisi.badan_terlihat(TampilMisi.kaki_kucing(akar.posisi_layar_sepeda(), _sepeda(akar).lateral_ubin, _sepeda(akar).jarak_ubin, t1.lateral_ubin, t1.maju_ubin), hud.area_misi()) and penanda.penanda_tampil().is_empty(), "4 ubin di depan dari lajur kucing: badan utuh di area, tanpa penanda")
	# Kucing berikut terlihat sebelum kucing 1 dilewati bila jaraknya cukup dekat; penanda hanya untuk kucing yang bukan langkah aktif atau belum utuh.
	var t2: RencanaMisi.Titik = rencana.titik[1]
	_ngebut_di(akar, t2.maju_ubin - Config.MISI_TAMPIL_JARAK_UBIN + 0.1, 0.0)
	var indeks: Array[int] = MissionManager.indeks_terlihat(akar.keadaan_misi())
	check(indeks.has(1) or akar.keadaan_misi().langkah >= 1, "kucing 2 terlihat begitu pemain masuk jarak tampilnya (tanpa menunggu kucing 1 selesai)")
	var ada_titik_1: bool = false
	for p: TampilMisi.Penanda in penanda.penanda_tampil():
		ada_titik_1 = ada_titik_1 or p.titik == 1
	check(ada_titik_1, "penanda untuk kucing 2 tampil di HUD")
	# Dilewati: kucing 1 selesai, penanda titik 0 tidak ada.
	_di(akar, t1.maju_ubin + 0.3, 0.0, 3.0)
	for p: TampilMisi.Penanda in penanda.penanda_tampil():
		check(p.titik != 0, "kucing 1 dilewati: tidak ada penanda titik 0")
	_bersihkan(akar)
	# Misi berakhir (banner): tanpa penanda. Tanpa misi: tanpa penanda.
	var akar2: RuteMain = await _siapkan()
	_selesaikan_misi(akar2)
	check(akar2.keadaan_misi().status == MissionManager.Status.SELESAI and akar2.hud_rute().penanda_kucing().penanda_tampil().is_empty(), "misi selesai: tidak ada penanda")
	_bersihkan(akar2)
	var akar3: RuteMain = await _siapkan(false)
	_ngebut_di(akar3, 20.0, 0.0)
	check(akar3.hud_rute().penanda_kucing().penanda_tampil().is_empty() and akar3.keadaan_misi() == null, "tanpa misi: tidak ada penanda")
	_bersihkan(akar3)
	# Petunjuk dari lemparan tepat: kucing 2 terlihat 22 ubin di depan (bukan 14), pemain di 20 ubin dari kucing 2.
	var akar4: RuteMain = await _siapkan()
	var t2b: RencanaMisi.Titik = akar4.rencana_misi().titik[1]
	var rumah: RouteBuilder.RumahRute = _pelanggan_di(akar4, t2b.petunjuk_awal_ubin, t2b.petunjuk_akhir_ubin)
	check(rumah != null, "ada pelanggan di jendela petunjuk titik 2")
	if rumah != null:
		check(_lempar_ke(akar4, rumah, false) and akar4.keadaan_misi().petunjuk[1], "lemparan tepat memberi petunjuk untuk langkah 2")
		_ngebut_di(akar4, t2b.maju_ubin - (Config.MISI_TAMPIL_PETUNJUK_JARAK_UBIN - 0.5), 0.0)
		var punya: bool = false
		for p: TampilMisi.Penanda in akar4.hud_rute().penanda_kucing().penanda_tampil():
			punya = punya or p.titik == 1
		check(punya and akar4.keadaan_misi().tampil[1], "dengan petunjuk: kucing 2 dan penanda-nya tampil %.1f ubin di depan (lebih awal dari %.1f tanpa petunjuk)" % [Config.MISI_TAMPIL_PETUNJUK_JARAK_UBIN - 0.5, Config.MISI_TAMPIL_JARAK_UBIN])
	_bersihkan(akar4)
	var akar5: RuteMain = await _siapkan()
	var t2c: RencanaMisi.Titik = akar5.rencana_misi().titik[1]
	_ngebut_di(akar5, t2c.maju_ubin - (Config.MISI_TAMPIL_PETUNJUK_JARAK_UBIN - 0.5), 0.0)
	check(not akar5.keadaan_misi().tampil[1], "tanpa petunjuk, pada jarak yang sama: kucing 2 belum terlihat")
	_bersihkan(akar5)


## Penanda tidak menumpuk HUD nyata, di lima ukuran dan kidal: sampel jarak dan lateral sepeda saat ngebut; batas konstanta cocok dengan HUD nyata.
func _test_penanda_layar(kasus: Array, kidal: bool) -> void:
	var lebar: int = kasus[2]
	var tag: String = "%d %s" % [lebar, "kidal" if kidal else "kanan"]
	_judul.call("Penanda tepi layar kucing %s: batas HUD atas dan radar cocok dengan HUD nyata, penanda tidak menumpuk HUD (M-2')" % tag)
	var akar: RuteMain = await _siapkan(true, true, Vector2i(kasus[0], kasus[1]))
	if kidal:
		akar.atur_kidal(true)
	await _tree.process_frame
	await _tree.process_frame
	var hud: HudRute = akar.hud_rute()
	var tut: TutorialController = akar.tutorial_node()
	var layar: Rect2 = Rect2(Vector2.ZERO, akar.get_viewport_rect().size)
	var atas: float = float(Config.MISI_PENANDA_ATAS_PX)
	var tepi: float = float(Config.MISI_PENANDA_TEPI_PX)
	# Batas konstanta cocok dengan HUD nyata.
	var strip_atas: Dictionary = {"panel_progres": hud.rect_panel_progres(), "panel_koin": hud.rect_panel_koin(), "panel_skor": hud.rect_panel_skor(), "tombol_jeda": hud.rect_tombol_jeda(), "kartu": hud.rect_kartu()}
	for nama: String in strip_atas:
		var r: Rect2 = strip_atas[nama]
		check(r.end.y <= atas, "%s: %s berakhir di y %.1f <= batas atas penanda %.0f" % [tag, nama, r.end.y, atas])
	check(hud.rect_radar_seberang().end.x <= tepi and hud.rect_radar_dekat().position.x >= layar.size.x - tepi, "%s: strip radar di luar tepi penanda (%.0f px dari tepi)" % [tag, tepi])
	var bawah_batas: float = layar.size.y - float(Config.MISI_PENANDA_BAWAH_PX)
	check(hud.rect_tombol_bel().position.y >= bawah_batas and hud.rect_panel_kecepatan().position.y >= bawah_batas and hud.rect_panel_koran().position.y >= bawah_batas, "%s: bel dan panel bawah di bawah batas bawah penanda (y %.0f)" % [tag, bawah_batas])
	# Banner dan gelembung petunjuk: tampilkan lewat keadaan nyata lalu ukur.
	var t1: RencanaMisi.Titik = akar.rencana_misi().titik[0]
	var rumah: RouteBuilder.RumahRute = _pelanggan_di(akar, 0.0, t1.petunjuk_akhir_ubin)
	_lempar_ke(akar, rumah, false)
	check(hud.petunjuk_tampil() and hud.rect_petunjuk().end.y <= atas, "%s: gelembung petunjuk berakhir di y %.1f <= %.0f" % [tag, hud.rect_petunjuk().end.y, atas])
	var stick: Rect2 = TouchZones.rect_stick(lebar, kidal)
	var lain: Dictionary = {
		"radar_seberang": hud.rect_radar_seberang(), "radar_dekat": hud.rect_radar_dekat(), "panel_progres": hud.rect_panel_progres(), "panel_koin": hud.rect_panel_koin(),
		"panel_skor": hud.rect_panel_skor(), "tombol_jeda": hud.rect_tombol_jeda(), "tombol_bel": hud.rect_tombol_bel(), "panel_kecepatan": hud.rect_panel_kecepatan(), "panel_koran": hud.rect_panel_koran(), "panel_kondisi": hud.rect_panel_kondisi(),
		"kartu": hud.rect_kartu(), "petunjuk": hud.rect_petunjuk(), "tutorial": tut.rect_panel(), "lewati": tut.rect_lewati(),
	}
	var banyak: int = 0
	var pelanggaran: Array[String] = []
	for lateral: float in [-2.0, -1.0, 0.0, 1.0, 2.0]:
		for jarak: float in [Config.MISI_TAMPIL_JARAK_UBIN - 0.1, 12.0, 10.0, 8.0, 6.0]:
			_ngebut_di(akar, t1.maju_ubin - jarak, lateral)
			if akar.keadaan_misi().langkah != 0:
				continue
			for r: Rect2 in hud.penanda_kucing().rect_penanda():
				banyak += 1
				if not layar.encloses(r):
					pelanggaran.append("di luar layar %s (lateral %.0f, jarak %.1f)" % [r, lateral, jarak])
				if r.intersects(stick) and r.position.y > stick.position.y:
					pelanggaran.append("menumpuk zona stick %s" % [r])
				for nama: String in lain:
					if (nama == "tutorial" or nama == "lewati") and not tut.tampil():
						continue
					if r.intersects(lain[nama]):
						pelanggaran.append("menumpuk %s %s (lateral %.0f, jarak %.1f)" % [nama, r, lateral, jarak])
	check(banyak > 0, "%s: ada penanda yang diukur (%d)" % [tag, banyak])
	check(pelanggaran.is_empty(), "%s: penanda tidak keluar layar dan tidak menumpuk radar, bel, jeda, panel atas, panel bawah, kartu, gelembung, tutorial: %s" % [tag, pelanggaran.slice(0, 3)])
	_bersihkan(akar)


## Rute yang dijeda memberi `MissionManager` jeda = true walau dt langkah kebetulan positif (pertahanan berlapis, QA-004): gelembung petunjuk dan banner tidak berkurang.
func _test_jeda_membekukan_walau_dt_positif() -> void:
	_judul.call("Jeda game: gelembung petunjuk tidak berkurang walau dt langkah positif (RuteMain meneruskan jeda ke MissionManager, QA-004)")
	var akar: RuteMain = await _siapkan()
	var t1: RencanaMisi.Titik = akar.rencana_misi().titik[0]
	var rumah: RouteBuilder.RumahRute = _pelanggan_di(akar, 0.0, t1.petunjuk_akhir_ubin)
	check(_lempar_ke(akar, rumah, false) and akar.keadaan_misi().petunjuk_sisa > 0.0, "petunjuk aktif sebelum jeda")
	var sisa: float = akar.keadaan_misi().petunjuk_sisa
	akar.minta_jeda()
	check(akar.sedang_jeda(), "rute dijeda")
	akar.set(&"_dt_langkah", 1.0)
	akar.call(&"_langkah_misi", _sepeda(akar).jarak_ubin)
	check(is_equal_approx(akar.keadaan_misi().petunjuk_sisa, sisa), "jeda dengan dt langkah 1,0: sisa gelembung tetap %.3f (dapat %.3f)" % [sisa, akar.keadaan_misi().petunjuk_sisa])
	akar.minta_lanjut()
	_bersihkan(akar)


# --- Tata letak lima ukuran (AC-13, AC-18) ---

func _test_tata_letak(kasus: Array, kidal: bool) -> void:
	var lebar: int = kasus[2]
	var tag: String = "%d %s" % [lebar, "kidal" if kidal else "kanan"]
	_judul.call("Tata letak misi dan tutorial %s: di dalam layar, tidak menumpuk, tidak terpotong (AC-13, AC-18)" % tag)
	var akar: RuteMain = await _siapkan(true, true, Vector2i(kasus[0], kasus[1]))
	if kidal:
		akar.atur_kidal(true)
	await _tree.process_frame
	await _tree.process_frame
	var hud: HudRute = akar.hud_rute()
	var tut: TutorialController = akar.tutorial_node()
	var layar: Rect2 = Rect2(Vector2.ZERO, akar.get_viewport_rect().size)
	check(absf(layar.size.x - float(lebar)) < 1.5 and layar.size.y == 360.0, "%s: viewport %.1fx360" % [tag, layar.size.x])
	var rencana: RencanaMisi.Rencana = akar.rencana_misi()
	var t1: RencanaMisi.Titik = rencana.titik[0]
	var lain: Dictionary = {
		"radar_seberang": hud.rect_radar_seberang(), "radar_dekat": hud.rect_radar_dekat(), "panel_progres": hud.rect_panel_progres(), "panel_koin": hud.rect_panel_koin(),
		"panel_skor": hud.rect_panel_skor(), "tombol_jeda": hud.rect_tombol_jeda(), "tombol_bel": hud.rect_tombol_bel(), "panel_kecepatan": hud.rect_panel_kecepatan(), "panel_koran": hud.rect_panel_koran(), "panel_kondisi": hud.rect_panel_kondisi(),
	}
	var stick: Rect2 = TouchZones.rect_stick(lebar, kidal)
	# Keadaan 1: kartu + tutorial awal.
	var elemen: Dictionary = {"kartu": hud.rect_kartu(), "tutorial": tut.rect_panel(), "lewati": tut.rect_lewati()}
	_periksa_elemen(tag + " awal", elemen, lain, layar, stick)
	var lewati: Rect2 = tut.rect_lewati()
	check(lewati.size.x >= 42.0 and lewati.size.y >= 42.0, "%s: tombol Lewati %s >= 42 px game" % [tag, lewati.size])
	for sudut: Vector2 in [lewati.position, lewati.end, lewati.get_center()]:
		check(TouchZones.zona_di(sudut, lebar, kidal) == TouchZones.Zona.TIDAK_ADA, "%s: titik %s tombol Lewati di luar zona stick, swipe, dan bel (tap tidak pernah melempar di mode bantu)" % [tag, sudut])
	_periksa_teks_tidak_terpotong(tag + " awal", [hud.get_node("%IsiMisi") as Label, tut.get_node("%TeksTutorial") as Label, tut.get_node("%LabelLangkahTutorial") as Label])
	# Keadaan 2: petunjuk dari lemparan tepat (gelembung) + kartu + tutorial langkah menepi.
	var rumah: RouteBuilder.RumahRute = _pelanggan_di(akar, 0.0, t1.petunjuk_akhir_ubin)
	_lempar_ke(akar, rumah, false)
	# Tata letak Container baru dihitung ulang di frame berikutnya: tanpa menunggu, gelembung yang baru tampil masih di posisi sementara (kiri di tengah layar).
	await _tree.process_frame
	await _tree.process_frame
	var e2: Dictionary = {"kartu": hud.rect_kartu(), "petunjuk": hud.rect_petunjuk(), "tutorial": tut.rect_panel(), "lewati": tut.rect_lewati()}
	check(hud.petunjuk_tampil(), "%s: gelembung petunjuk tampil" % tag)
	if not tut.tampil():
		e2.erase("tutorial")
		e2.erase("lewati")
	_periksa_elemen(tag + " petunjuk", e2, lain, layar, stick)
	_periksa_teks_tidak_terpotong(tag + " petunjuk", [hud.get_node("%TeksPetunjuk") as Label])
	# Keadaan 3: banner selesai.
	_selesaikan_misi(akar)
	await _tree.process_frame
	await _tree.process_frame
	var e3: Dictionary = {"banner": hud.rect_banner()}
	check(hud.banner_tampil(), "%s: banner tampil" % tag)
	_periksa_elemen(tag + " banner", e3, lain, layar, stick)
	_periksa_teks_tidak_terpotong(tag + " banner", [hud.get_node("%TeksBanner") as Label])
	# Layar hasil dengan rekap: label di dalam panel, tombol >= 42 px dan tidak menumpuk rekap, tidak terpotong.
	_di(akar, akar.rute().panjang_ubin - 1.0)
	_langkah(akar, 600)
	await _tree.process_frame
	await _tree.process_frame
	var hasil: LayarHasil = akar.layar_hasil()
	check(akar.hasil_tampil() and hasil.rect_rekap_misi().size.y > 0.0, "%s: layar hasil dengan rekap tampil" % tag)
	var dalam: bool = layar.encloses(hasil.rect_panel())
	for r: Rect2 in hasil.rect_label():
		dalam = dalam and hasil.rect_panel().encloses(r)
	check(dalam and not hasil.rect_tombol().intersects(hasil.rect_rekap_misi()) and hasil.rect_tombol().size.y >= 42.0, "%s: panel hasil di layar, semua label (termasuk rekap) di dalam panel, tombol >= 42 px tidak menumpuk rekap" % tag)
	_periksa_teks_tidak_terpotong(tag + " hasil", [hasil.get_node("%RekapMisi") as Label])
	_bersihkan(akar)


func _periksa_elemen(nama: String, elemen: Dictionary, lain: Dictionary, layar: Rect2, stick: Rect2) -> void:
	for kunci: String in elemen:
		var r: Rect2 = elemen[kunci]
		check(layar.encloses(r) and r.size.x > 0.0, "%s: %s %s di dalam layar" % [nama, kunci, r])
		for nama_lain: String in lain:
			check(not r.intersects(lain[nama_lain]), "%s: %s %s tidak menumpuk %s %s" % [nama, kunci, r, nama_lain, lain[nama_lain]])
		check(kunci == "banner" or kunci == "petunjuk" or not r.intersects(stick), "%s: %s tidak menumpuk zona stick" % [nama, kunci])
		for kunci_lain: String in elemen:
			if kunci_lain > kunci:
				check(not r.intersects(elemen[kunci_lain]), "%s: %s tidak menumpuk %s" % [nama, kunci, kunci_lain])


## Teks tidak terpotong: tinggi label cukup untuk semua baris dan lebarnya cukup untuk teks tak terbungkus yang lebih pendek dari kotaknya.
func _periksa_teks_tidak_terpotong(nama: String, daftar: Array) -> void:
	for butir: Variant in daftar:
		var label: Label = butir
		var terlihat: bool = label.get_visible_line_count() == label.get_line_count() or label.get_line_count() == 0
		var font: Font = label.get_theme_font(&"font")
		var ukuran: int = label.get_theme_font_size(&"font_size")
		var tinggi_butuh: float = font.get_height(ukuran) * float(maxi(label.get_line_count(), 1))
		check(terlihat and label.size.y + 0.5 >= tinggi_butuh and label.text.length() > 0, "%s: label '%s' tidak terpotong (%d baris terlihat dari %d, tinggi %.1f >= %.1f)" % [nama, label.text.left(24), label.get_visible_line_count(), label.get_line_count(), label.size.y, tinggi_butuh])
