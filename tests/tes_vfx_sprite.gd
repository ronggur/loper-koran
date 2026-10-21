class_name TesVfxSprite
extends RefCounted
## Tes run fase5a-pasang-aset-gelombang1 bagian B, efek dari sprite (AC-13 sampai AC-15, D-4 sampai D-6): debu roda dan garis kecepatan (`VfxSepeda`, `VfxSepedaGambar`,
## `UmpanBalikSepeda.atur_sprite`), bintang kena dan koin tip (`VfxAntaran`, `UmpanMelayangGambar`), dan kilau kucing misi (`KucingHiasan.item_kilau`) di scene rute sungguhan dengan lemparan nyata.
##
## Harapan ditulis sebagai literal atau dihitung dengan cara lain dari kode produksi: aturan tampil dari ambang literal (debu: kecepatan >= 3,0 atau rem dengan kecepatan > 0; garis: kecepatan >= 4,5 dan
## bukan kurangi efek), kekuatan garis dari rumus linear ditulis ulang (0,25 sampai 1,0 antara 4,5 dan 6,0), letak gambar dari pijak JSON dan titik asal literal, proyeksi iso ditulis ulang (layar = ((x - y)
## x 32, (x + y) x 16)), dan frame animasi sekali main dari waktu x fps. `UmpanBalikKecepatan` dan konstanta `UMPAN_*` tidak diubah (dites terpisah di `tes_umpan_balik.gd`).

const BERKAS_RUTE: String = "res://scenes/rute/rute.tscn"
const DT: float = 1.0 / 60.0
const SKALA: int = 3
const LEBAR: int = 780
const TITIK_STICK: Vector2 = Vector2(100, 260)
const TOL: float = 0.0001

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
	_test_aturan_tampil_murni()
	_test_garis_acak_murni()
	_test_vfx_antaran_murni()
	_test_node_vfx_sepeda()
	await _test_debu_garis_di_scene()
	await _test_jeda_membekukan_vfx()
	await _test_bintang_dan_koin_di_scene()
	await _test_tip_sesudah_tenggat_tanpa_koin()
	_test_kilau_murni()
	await _test_kilau_di_scene()


# --- Pembantu ---

func _siapkan(dengan_misi: bool = false, misi: DataMisi = null) -> RuteMain:
	_tree.root.size = Vector2i(2340, 1080)
	var akar: RuteMain = (load(BERKAS_RUTE) as PackedScene).instantiate() as RuteMain
	if dengan_misi:
		akar.atur_benih_awal(SeedHari.rute(1))
		akar.atur_misi(misi if misi != null else _misi)
	_tree.root.add_child(akar)
	await _tree.process_frame
	await _tree.process_frame
	akar.set_process(false)
	(akar.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = false
	(akar.find_child("LoperAgen", true, false) as LoperSprite).set_process(false)
	return akar


func _bersihkan(akar: AdeganJalan) -> void:
	for i: int in range(8):
		_sentuh(i, Vector2(-50, -50), false)
	if akar.sedang_jeda():
		akar.minta_lanjut()
	(akar.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = OS.has_feature("editor")
	_tree.root.remove_child(akar)
	akar.free()


func _anak(akar: Node, nama: String) -> Node:
	return akar.find_child(nama, true, false)


func _sepeda(akar: Node) -> SepedaUji:
	return akar.find_child("Sepeda", true, false) as SepedaUji


func _taruh(akar: AdeganJalan, v: float, lateral: float, maju: float) -> void:
	var sepeda: SepedaUji = _sepeda(akar)
	var k: BikeMotion.Keadaan = sepeda.keadaan.salin()
	k.kecepatan_ud = v
	k.lateral_ubin = lateral
	sepeda.keadaan = k
	sepeda.jarak_ubin = maju
	akar.perbarui(0.0)


func _langkah(akar: AdeganJalan, jumlah: int) -> void:
	for i: int in range(jumlah):
		akar.perbarui(DT)


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


func _nama(daftar: Array[DefSprite.Item]) -> Array[String]:
	var hasil: Array[String] = []
	for i: DefSprite.Item in daftar:
		hasil.append(i.nama)
	return hasil


func _layar(x: float, y_dunia: float) -> Vector2:
	return Vector2(roundf((x - y_dunia) * 32.0), roundf((x + y_dunia) * 16.0))


func _lempar_ke_titik(akar: RuteMain, maju: float, titik_jalan: Vector2, mendarat: Array[KoranLempar.Koran]) -> KoranLempar.Koran:
	_taruh(akar, 3.0, 0.5, maju)
	akar.koran = SisaKoran.awal(30)
	var sepeda: SepedaUji = _sepeda(akar)
	var posisi: Vector2 = sepeda.posisi_dunia()
	var jeda: float = sepeda.jeda_lepas(LoperAnim.Sisi.SEBERANG)
	var lepas: Vector2 = ThrowSolver.titik_lepas(posisi, sepeda.kecepatan_ud, sepeda.lateral_ud, jeda)
	var sasaran: Vector2 = Vector2(titik_jalan.x, -titik_jalan.y)
	var u: float = BantuLempar.cari_kekuatan(sasaran, lepas, sepeda.kecepatan_ud)
	if u < 0.0:
		check(false, "pembantu tes: titik %s terjangkau dari maju %.1f" % [titik_jalan, maju])
		return null
	var lebar: float = float(LEBAR)
	var lintasan: ThrowSolver.Lintasan = ThrowSolver.hitung(ThrowSolver.panjang_untuk_kekuatan(u, lebar), lebar, BantuLempar.arah_ke(sasaran, lepas, sepeda.kecepatan_ud, u), posisi, sepeda.kecepatan_ud, sepeda.lateral_ud, jeda)
	var sebelum: int = mendarat.size()
	akar.call(&"_lempar", lintasan, false)
	for i: int in range(150):
		akar.perbarui(DT)
		if mendarat.size() > sebelum:
			return mendarat[sebelum]
	return null


func _lempar_ke_kotak(akar: RuteMain, maju: float, id_rumah: String, mendarat: Array[KoranLempar.Koran]) -> KoranLempar.Koran:
	_taruh(akar, 3.0, 0.5, maju)
	akar.koran = SisaKoran.awal(30)
	var pilihan: BantuLempar.Pilihan = akar.pilihan_bantu(LoperAnim.Sisi.SEBERANG)
	if pilihan == null or pilihan.zona.id_rumah != id_rumah:
		check(false, "pembantu tes: lintasan ke %s dari maju %.1f" % [id_rumah, maju])
		return null
	var sebelum: int = mendarat.size()
	akar.call(&"_lempar", pilihan.lintasan, false)
	for i: int in range(150):
		akar.perbarui(DT)
		if mendarat.size() > sebelum:
			return mendarat[sebelum]
	return null


# --- Debu dan garis: aturan tampil murni (AC-13) ---

func _test_aturan_tampil_murni() -> void:
	_judul.call("VfxSepeda: debu tampil tepat bila laju debu > 0 (ambang 3,0 inklusif, rem, kecepatan 0), garis tepat bila kekuatan > 0 (ambang 4,5 inklusif), kurangi efek (AC-13)")
	# Debu: tampil bila kecepatan > 0 dan (rem aktif, atau kecepatan >= 3,0). Literal ambang dari BALANCING/GDD 15.
	var debu: Array = [
		[0.0, false, false], [0.0, true, false], [1.0, false, false], [2.99, false, false], [2.999999, false, false], [3.0, false, true], [3.000001, false, true], [4.5, false, true], [6.0, false, true], [9.0, false, true],
		[0.001, true, true], [1.0, true, true], [2.0, true, true], [-1.0, false, false], [-1.0, true, false], [NAN, false, false], [NAN, true, false],
	]
	var salah_debu: Array[String] = []
	for baris: Array in debu:
		if VfxSepeda.debu_tampil(baris[0], baris[1], false) != baris[2]:
			salah_debu.append("v %s rem %s" % [baris[0], baris[1]])
		if VfxSepeda.item_debu(baris[0], baris[1], false, 0.0).is_empty() == baris[2]:
			salah_debu.append("item v %s rem %s" % [baris[0], baris[1]])
	check(salah_debu.is_empty(), "debu: 17 kasus (ambang 3,0 inklusif, satu langkah di sisi salah, rem, nol, negatif, NaN) cocok tabel: %s" % [salah_debu])
	# Kurangi efek: debu tetap tampil, alpha dikali pengali (0,5).
	check(VfxSepeda.debu_tampil(4.0, false, true) and VfxSepeda.debu_alfa(true) == 0.5 and VfxSepeda.debu_alfa(false) == 1.0 and VfxSepeda.item_debu(4.0, false, true, 0.0)[0].alfa == 0.5 and VfxSepeda.item_debu(4.0, false, false, 0.0)[0].alfa == 1.0, "kurangi efek: debu tetap tampil dengan alpha 0,5 (penuh bila tidak)")
	# Garis: tampil bila kecepatan >= 4,5 dan bukan kurangi efek; alpha = kekuatan (0,25 di 4,5, 1,0 di 6,0, linear).
	var garis: Array = [[0.0, false], [3.0, false], [4.49, false], [4.4999, false], [4.5, true], [4.5001, true], [5.0, true], [6.0, true], [8.0, true], [-1.0, false], [NAN, false]]
	var salah_garis: Array[String] = []
	var k: VfxSepeda.GarisKeadaan = VfxSepeda.garis_awal(_rng(1))
	for baris: Array in garis:
		if VfxSepeda.garis_tampil(baris[0], false) != baris[1]:
			salah_garis.append("v %s" % baris[0])
		if VfxSepeda.item_garis(baris[0], false, k).is_empty() == baris[1]:
			salah_garis.append("item v %s" % baris[0])
		if VfxSepeda.garis_tampil(baris[0], true) or not VfxSepeda.item_garis(baris[0], true, k).is_empty():
			salah_garis.append("kurangi efek v %s" % baris[0])
	check(salah_garis.is_empty(), "garis: ambang 4,5 inklusif, satu langkah di sisi salah, mati saat kurangi efek: %s" % [salah_garis])
	check(absf(VfxSepeda.garis_alfa(4.5, false) - 0.25) < TOL and absf(VfxSepeda.garis_alfa(5.25, false) - 0.625) < TOL and absf(VfxSepeda.garis_alfa(6.0, false) - 1.0) < TOL and absf(VfxSepeda.garis_alfa(9.0, false) - 1.0) < TOL and VfxSepeda.garis_alfa(4.0, false) == 0.0 and VfxSepeda.garis_alfa(6.0, true) == 0.0, "alpha garis = kekuatan: 0,25 di 4,5, 0,625 di 5,25, 1,0 di 6,0 dan di atasnya, 0 di bawah ambang dan saat kurangi efek")
	check(absf(VfxSepeda.item_garis(5.25, false, k)[0].alfa - 0.625) < TOL, "item garis membawa alpha kekuatan")
	# Letak gambar: debu berpijak (14, 7) di titik roda belakang (-12, 2); garis berujung kepala (27, 7) di (30, -24) digeser tegak lurus jalan.
	var item_debu: DefSprite.Item = VfxSepeda.item_debu(5.0, false, false, 0.0)[0]
	check(item_debu.nama == "vfx_debu_roda" and item_debu.pojok == Vector2(-26, -5) and item_debu.frame == 0, "debu: pojok (-26, -5) = roda belakang (-12, 2) - pijak (14, 7)")
	var tegak: Vector2 = VfxSepeda.arah_tegak()
	check(tegak.is_equal_approx(Vector2(-0.4472136, -0.8944272)) and VfxSepeda.arah_mundur().is_equal_approx(Vector2(-0.8944272, 0.4472136)), "arah mundur dan tegak lurus jalan (2:1): (-0,894; 0,447) dan (-0,447; -0,894)")
	var nol: VfxSepeda.GarisKeadaan = VfxSepeda.GarisKeadaan.new()
	nol.varian = 1
	var item_nol: DefSprite.Item = VfxSepeda.item_garis(6.0, false, nol)[0]
	check(item_nol.nama == "vfx_garis_kecepatan_b" and item_nol.pojok == Vector2(3, -31), "garis varian b tanpa geseran: pojok (3, -31) = kepala (30, -24) - pijak (27, 7)")
	var geser: VfxSepeda.GarisKeadaan = VfxSepeda.GarisKeadaan.new()
	geser.varian = 2
	geser.geser_px = 10.0
	var item_geser: DefSprite.Item = VfxSepeda.item_garis(6.0, false, geser)[0]
	check(item_geser.nama == "vfx_garis_kecepatan_c" and item_geser.pojok == Vector2(-1, -40), "garis varian c digeser 10 px tegak lurus jalan: pojok (-1, -40)")
	# Frame debu berputar (loop 12 fps, 6 frame).
	var frame: Array[int] = []
	for detik: float in [0.0, 0.09, 0.17, 0.26, 0.34, 0.43, 0.51, 1.0]:
		frame.append(VfxSepeda.item_debu(5.0, false, false, detik)[0].frame)
	check(frame == [0, 1, 2, 3, 4, 5, 0, 0], "frame debu loop 12 fps, 6 frame: %s" % [frame])


func _rng(benih: int) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = benih
	return rng


func _test_garis_acak_murni() -> void:
	_judul.call("VfxSepeda: varian garis diacak berseed tiap 2 sampai 3 frame, tiga varian semuanya muncul, benih sama = urutan sama (AC-13)")
	var rng_a: RandomNumberGenerator = _rng(Config.UMPAN_GARIS_SPRITE_BENIH)
	var rng_b: RandomNumberGenerator = _rng(Config.UMPAN_GARIS_SPRITE_BENIH)
	var rng_c: RandomNumberGenerator = _rng(Config.UMPAN_GARIS_SPRITE_BENIH + 1)
	var a: VfxSepeda.GarisKeadaan = VfxSepeda.garis_awal(rng_a)
	var b: VfxSepeda.GarisKeadaan = VfxSepeda.garis_awal(rng_b)
	var c: VfxSepeda.GarisKeadaan = VfxSepeda.garis_awal(rng_c)
	var varian_a: Array[int] = [a.varian]
	var varian_c: Array[int] = [c.varian]
	var sama: bool = a.varian == b.varian and a.sisa_frame == b.sisa_frame and a.geser_px == b.geser_px
	var pernah: Dictionary = {}
	var interval_benar: bool = a.sisa_frame >= 2 and a.sisa_frame <= 3
	var jarak: int = 0
	var sisa_saat_acak: int = a.sisa_frame
	var geser_di_batas: bool = absf(a.geser_px) <= Config.UMPAN_GARIS_SEBARAN_PX
	var jumlah_acak: int = 0
	var geser_beragam: Dictionary = {}
	for i: int in range(600):
		var sebelum: VfxSepeda.GarisKeadaan = a
		a = VfxSepeda.garis_maju(a, rng_a)
		b = VfxSepeda.garis_maju(b, rng_b)
		c = VfxSepeda.garis_maju(c, rng_c)
		jarak += 1
		if sebelum.sisa_frame > 1:
			# Belum waktunya: hanya sisa frame berkurang satu, varian dan geseran tetap.
			if a.sisa_frame != sebelum.sisa_frame - 1 or a.varian != sebelum.varian or a.geser_px != sebelum.geser_px:
				interval_benar = false
		else:
			# Diacak ulang tepat sesudah sisa habis: sisa baru 2 atau 3, dan jaraknya sejak acak sebelumnya = sisa saat itu.
			if a.sisa_frame < 2 or a.sisa_frame > 3 or jarak != sisa_saat_acak:
				interval_benar = false
			jarak = 0
			sisa_saat_acak = a.sisa_frame
			jumlah_acak += 1
			geser_beragam[roundi(a.geser_px)] = true
		if a.varian != b.varian or a.sisa_frame != b.sisa_frame or a.geser_px != b.geser_px:
			sama = false
		if absf(a.geser_px) > Config.UMPAN_GARIS_SEBARAN_PX:
			geser_di_batas = false
		pernah[a.varian] = true
		varian_a.append(a.varian)
		varian_c.append(c.varian)
	check(sama, "benih sama: urutan varian, sisa frame, dan geseran sama persis untuk 600 frame")
	check(varian_a != varian_c, "benih berbeda: urutan varian berbeda")
	check(pernah.size() == 3 and pernah.has(0) and pernah.has(1) and pernah.has(2), "ketiga varian (a, b, c) muncul dalam 600 frame: %s" % [pernah.keys()])
	check(interval_benar and jumlah_acak > 150, "diacak ulang tiap 2 atau 3 frame (%d kali dalam 600 frame, interval benar %s)" % [jumlah_acak, interval_benar])
	check(geser_di_batas and geser_beragam.size() > 10, "geseran tegak lurus jalan dalam +-%s px dan beragam (%d nilai)" % [Config.UMPAN_GARIS_SEBARAN_PX, geser_beragam.size()])
	var asal: VfxSepeda.GarisKeadaan = VfxSepeda.GarisKeadaan.new()
	asal.sisa_frame = 5
	var maju: VfxSepeda.GarisKeadaan = VfxSepeda.garis_maju(asal, _rng(1))
	check(asal.sisa_frame == 5 and maju.sisa_frame == 4 and maju.varian == asal.varian, "garis_maju tidak mengubah masukan dan tidak mengacak sebelum sisa frame habis")


# --- Bintang kena dan koin tip: murni (AC-14) ---

func _test_vfx_antaran_murni() -> void:
	_judul.call("VfxAntaran: sprite koin hanya bila tip sama dengan nilai yang dipanggang (5); bintang 15 fps dan koin 10 fps sekali main (AC-14)")
	check(Config.KOIN_TIP == Config.UMPAN_KOIN_TIP_SPRITE_NILAI and Config.UMPAN_KOIN_TIP_SPRITE_NILAI == 5, "KOIN_TIP = 5 = nilai yang dipanggang di sprite koin (sinkron)")
	check(VfxAntaran.koin_sprite(5) and not VfxAntaran.koin_sprite(0) and not VfxAntaran.koin_sprite(4) and not VfxAntaran.koin_sprite(6) and not VfxAntaran.koin_sprite(-5) and not VfxAntaran.koin_sprite(50), "koin_sprite: hanya tip 5 (0, 4, 6, -5, 50 tidak)")
	var e: UmpanMelayang.Entri = UmpanMelayang.Entri.new()
	e.titik_dunia = Vector2(1.0, -2.0)
	e.ongkos = 15
	e.tip = 5
	e.sisa_detik = 0.8
	# Titik layar (1, -2): ((1+2) x 32, (1-2) x 16) = (96, -16). Bintang pijak (7, 7), koin pijak (8, 24).
	var daftar: Array[DefSprite.Item] = VfxAntaran.item_entri(e)
	check(_nama(daftar) == ["vfx_bintang_kena", "vfx_koin_tip"] and daftar[0].pojok == Vector2(89, -23) and daftar[1].pojok == Vector2(88, -40) and daftar[0].frame == 0 and daftar[1].frame == 0, "muncul: bintang pojok (89, -23), koin pojok (88, -40), frame 0")
	var tanpa_tip: UmpanMelayang.Entri = e
	tanpa_tip.tip = 0
	check(_nama(VfxAntaran.item_entri(tanpa_tip)) == ["vfx_bintang_kena"], "tanpa tip: hanya bintang, tanpa koin")
	e.tip = 6
	check(_nama(VfxAntaran.item_entri(e)) == ["vfx_bintang_kena"] and VfxAntaran.frame_koin(e) == -1, "tip 6 (KOIN_TIP berbeda): sprite koin tidak dipakai (tulisan +5 salah), hanya bintang")
	e.tip = 5
	# Waktu sejak tampil = 0,8 - sisa. Bintang 15 fps: frame 0..5 sampai 0,4 detik; koin 10 fps: sampai 0,6 detik.
	var bintang: Array[int] = []
	var koin: Array[int] = []
	for lewat: float in [0.0, 0.05, 0.08, 0.14, 0.21, 0.28, 0.35, 0.39, 0.41, 0.59, 0.61]:
		e.sisa_detik = 0.8 - lewat
		bintang.append(VfxAntaran.frame_bintang(e))
		koin.append(VfxAntaran.frame_koin(e))
	check(bintang == [0, 0, 1, 2, 3, 4, 5, 5, -1, -1, -1], "frame bintang sekali main (15 fps): %s" % [bintang])
	check(koin == [0, 0, 0, 1, 2, 2, 3, 3, 4, 5, -1], "frame koin sekali main (10 fps): %s" % [koin])
	e.sisa_detik = 0.8
	check(VfxAntaran.item_semua([e, e] as Array[UmpanMelayang.Entri]).size() == 4, "dua entri = empat item")
	var selesai: UmpanMelayang.Entri = e
	selesai.sisa_detik = 0.1
	check(VfxAntaran.item_entri(selesai).is_empty(), "sesudah 0,7 detik: kedua sprite habis (tidak berulang)")


# --- Node VfxSepedaGambar ---

func _test_node_vfx_sepeda() -> void:
	_judul.call("VfxSepedaGambar: dt nol, negatif, NaN, tak hingga tidak memajukan apa pun; satu frame acak per langkah (AC-13)")
	var node: VfxSepedaGambar = VfxSepedaGambar.new()
	var kedua: VfxSepedaGambar = VfxSepedaGambar.new()
	check(node.detik() == 0.0 and node.keadaan_garis().sisa_frame >= 2 and node.keadaan_garis().sisa_frame <= 3, "awal: waktu 0, sisa frame 2 atau 3")
	for dt: float in [0.0, -1.0, NAN, INF, -INF]:
		node.maju(dt)
	check(node.detik() == 0.0 and node.keadaan_garis().sisa_frame == kedua.keadaan_garis().sisa_frame and node.keadaan_garis().varian == kedua.keadaan_garis().varian, "dt tidak sah: waktu dan acak tidak berubah")
	node.atur(6.0, false, false)
	check(node.item_sprite().size() == 2 and node.item_sprite()[0].nama == "vfx_debu_roda" and node.item_sprite()[1].nama.begins_with("vfx_garis_kecepatan_"), "ngebut: item debu dan satu garis")
	var urut_a: Array[int] = []
	var urut_b: Array[int] = []
	for i: int in range(40):
		node.maju(DT)
		kedua.maju(DT)
		urut_a.append(node.keadaan_garis().varian)
		urut_b.append(kedua.keadaan_garis().varian)
	check(is_equal_approx(node.detik(), 40.0 * DT) and urut_a == urut_b, "40 langkah: waktu 40 x dt; dua node berbenih sama memutar varian yang sama")
	node.atur(2.0, false, false)
	check(node.item_sprite().is_empty(), "kecepatan 2,0 tanpa rem: tidak ada gambar")
	node.free()
	kedua.free()


# --- Debu dan garis di scene (AC-13) ---

func _test_debu_garis_di_scene() -> void:
	_judul.call("Scene rute: debu dan garis dari sprite, pemancar kode dimatikan, ikut sepeda; sapuan kecepatan, rem, dan kurangi efek (AC-13, D-4)")
	var akar: RuteMain = await _siapkan()
	var sepeda: SepedaUji = _sepeda(akar)
	var umpan: UmpanBalikSepeda = sepeda.umpan_balik()
	var sprite: VfxSepedaGambar = umpan.sprite()
	check(umpan.pakai_sprite() and sprite != null and sprite.get_parent() == umpan and umpan.get_parent() == sepeda and sprite.position == Vector2.ZERO, "rute.tscn: UmpanBalikSepeda memakai sprite, node VfxSepedaGambar anak umpan balik di titik pijak sepeda")
	check(umpan.get_index() < (_anak(akar, "LoperAgen") as Node).get_index(), "umpan balik digambar sebelum sprite pemain (di belakang pemain)")
	var jumlah_pancaran: int = 0
	var gpu: int = 0
	var antre: Array[Node] = [akar]
	while not antre.is_empty():
		var n: Node = antre.pop_back()
		if n is PancaranPiksel:
			jumlah_pancaran += 1
			if n.visible or n.process_mode != Node.PROCESS_MODE_DISABLED or (n as PancaranPiksel).laju != 0.0 or (n as PancaranPiksel).jumlah_aktif() != 0:
				gpu += 1
		if n is GPUParticles2D or n is CPUParticles2D:
			gpu += 1
		antre.append_array(n.get_children())
	check(jumlah_pancaran == 2 and gpu == 0, "dua pemancar kode (debu, garis) tersembunyi, tanpa proses, laju 0, tanpa partikel hidup, tanpa GPU/CPUParticles2D (dapat %d tidak mati)" % gpu)
	# Sapuan kecepatan lewat UmpanBalikSepeda.perbarui (sumber tunggal): debu tepat bila laju debu > 0, garis tepat bila kekuatan garis > 0.
	var salah: Array[String] = []
	var kecepatan: Array[float] = [0.0, 1.0, 2.99, 3.0, 3.01, 4.0, 4.49, 4.5, 4.51, 5.0, 6.0]
	for v: float in kecepatan:
		for rem: bool in [false, true]:
			umpan.perbarui(v, rem)
			var ada_debu: bool = v > 0.0 and (rem or v >= 3.0)
			var ada_garis: bool = v >= 4.5
			var nama: Array[String] = _nama(sprite.item_sprite())
			if nama.has("vfx_debu_roda") != ada_debu:
				salah.append("debu v %s rem %s" % [v, rem])
			var garis_ada: bool = false
			for n: String in nama:
				if n.begins_with("vfx_garis_kecepatan_"):
					garis_ada = true
			if garis_ada != ada_garis:
				salah.append("garis v %s rem %s" % [v, rem])
	check(salah.is_empty(), "sapuan 11 kecepatan x rem: debu dan garis tampil tepat sesuai ambang (3,0 dan 4,5 inklusif, satu langkah sisi salah): %s" % [salah])
	# Kurangi efek.
	umpan.kurangi_efek = true
	umpan.perbarui(6.0, false)
	var kurang: Array[DefSprite.Item] = sprite.item_sprite()
	check(kurang.size() == 1 and kurang[0].nama == "vfx_debu_roda" and kurang[0].alfa == Config.UMPAN_KURANGI_DEBU_PENGALI, "kurangi efek saat ngebut: garis mati, debu tetap dengan alpha dikali pengali")
	umpan.kurangi_efek = false
	umpan.perbarui(6.0, false)
	check(sprite.item_sprite().size() == 2 and sprite.item_sprite()[0].alfa == 1.0, "tanpa kurangi efek: debu alpha penuh dan garis")
	# Kecepatan 0 tanpa rem: tidak ada gambar; rem dengan kecepatan 0 juga tidak.
	umpan.perbarui(0.0, true)
	check(sprite.item_sprite().is_empty(), "kecepatan 0 (juga dengan rem): tidak ada debu dan garis")
	# Dari gerak nyata (stick): ngebut menyalakan, lepas sampai santai mematikan garis; sprite ikut sepeda saat pindah sisi.
	_sentuh(0, TITIK_STICK, true)
	_geser(0, TITIK_STICK - Vector2(0, Config.STICK_RADIUS_PX))
	for i: int in range(180):
		akar.perbarui(DT)
		sprite.maju(DT)
	check(sepeda.kecepatan_ud == 6.0 and _nama(sprite.item_sprite()).size() == 2 and (_nama(sprite.item_sprite())[0] as String) == "vfx_debu_roda", "gerak nyata ngebut 6,0 (stick): debu dan satu garis tampil")
	var posisi_awal: Vector2 = sprite.global_position
	var sepeda_awal: Vector2 = sepeda.global_position
	sepeda.lateral_ubin = sepeda.lateral_ubin - 0.8 if sepeda.lateral_ubin > 0.0 else sepeda.lateral_ubin + 0.8
	sepeda.gerak(Vector2.ZERO, 0.0)
	var geser_sepeda: Vector2 = sepeda.global_position - sepeda_awal
	check(geser_sepeda.length() > 20.0 and (sprite.global_position - posisi_awal).is_equal_approx(geser_sepeda), "pindah sisi: sprite debu dan garis ikut sepeda (geser %s), tidak tertinggal di dunia" % [geser_sepeda])
	_sentuh(0, TITIK_STICK, false)
	_bersihkan(akar)


func _test_jeda_membekukan_vfx() -> void:
	_judul.call("Scene rute: jeda game dan app di-background membekukan animasi debu dan acak garis, tanpa lanjut otomatis (AC-13)")
	var akar: RuteMain = await _siapkan()
	var umpan: UmpanBalikSepeda = _sepeda(akar).umpan_balik()
	var sprite: VfxSepedaGambar = umpan.sprite()
	umpan.perbarui(6.0, false)
	sprite.set_process(true)
	await _tree.process_frame
	await _tree.process_frame
	var detik_lama: float = sprite.detik()
	check(detik_lama > 0.0, "kontrol: tanpa jeda animasi maju dengan sendirinya (%.4f detik)" % detik_lama)
	for pemicu: String in ["JEDA", "BACKGROUND"]:
		if pemicu == "JEDA":
			akar.minta_jeda()
		else:
			_tree.root.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		var detik_jeda: float = sprite.detik()
		var garis_jeda: VfxSepeda.GarisKeadaan = sprite.keadaan_garis()
		var varian: int = garis_jeda.varian
		var sisa: int = garis_jeda.sisa_frame
		var geser: float = garis_jeda.geser_px
		var item_jeda: Array[DefSprite.Item] = sprite.item_sprite()
		for i: int in range(10):
			await _tree.process_frame
		var item_sesudah: Array[DefSprite.Item] = sprite.item_sprite()
		var sama_item: bool = item_jeda.size() == item_sesudah.size()
		for i: int in range(mini(item_jeda.size(), item_sesudah.size())):
			if item_jeda[i].frame != item_sesudah[i].frame or item_jeda[i].pojok != item_sesudah[i].pojok or item_jeda[i].nama != item_sesudah[i].nama:
				sama_item = false
		check(akar.sedang_jeda() and not sprite.can_process(), "%s: pohon dijeda, node efek tidak berproses" % pemicu)
		check(sprite.detik() == detik_jeda and sama_item, "%s: waktu animasi debu dan frame/pojok tidak berubah selama 10 frame" % pemicu)
		check(sprite.keadaan_garis().varian == varian and sprite.keadaan_garis().sisa_frame == sisa and sprite.keadaan_garis().geser_px == geser, "%s: acak varian garis membeku (varian, sisa frame, geseran tetap)" % pemicu)
		akar.minta_lanjut()
		for i: int in range(4):
			await _tree.process_frame
		check(sprite.detik() > detik_jeda and not akar.sedang_jeda(), "%s: sesudah lanjut animasi berjalan lagi" % pemicu)
	_bersihkan(akar)


# --- Bintang dan koin di scene (AC-14) ---

func _test_bintang_dan_koin_di_scene() -> void:
	_judul.call("Scene rute: antaran sah memutar bintang di titik mendarat, tip memutar koin tanpa baris tip label; tidak sah, netral, dan meleset tidak (AC-14)")
	var akar: RuteMain = await _siapkan()
	var gambar: UmpanMelayangGambar = akar.umpan_gambar()
	var mendarat: Array[KoranLempar.Koran] = []
	akar.koran_mendarat.connect(func(k: KoranLempar.Koran) -> void: mendarat.append(k))
	check(gambar.item_sprite().is_empty(), "awal: tidak ada bintang dan koin")
	# 1. Antaran sah ke kotak surat @6 (tepat, tanpa tip).
	var k1: KoranLempar.Koran = await _lempar_ke_kotak(akar, 1.0, "per_buka_01@6", mendarat)
	var item: Array[DefSprite.Item] = gambar.item_sprite()
	check(k1 != null and _nama(item) == ["vfx_bintang_kena"] and item[0].frame == 0, "antaran sah tanpa tip: satu bintang kena, tanpa koin")
	if k1 != null:
		var titik: Vector2 = _layar(k1.lintasan.titik_mendarat.x, k1.lintasan.titik_mendarat.y)
		check(item[0].pojok == titik - Vector2(7, 7), "bintang berpijak (7, 7) di titik mendarat %s" % [titik])
	check(gambar.teks_tampil() == ["+15\nTEPAT"], "label: '+15 / TEPAT' tanpa baris tip: %s" % [gambar.teks_tampil()])
	# Bintang sekali main: frame naik, hilang sesudah 0,4 detik, label tetap sampai 0,8 detik.
	var frame_lihat: Array[int] = [item[0].frame]
	var hilang_pada: int = -1
	for i: int in range(1, 60):
		akar.perbarui(DT)
		var sekarang: Array[DefSprite.Item] = gambar.item_sprite()
		if sekarang.is_empty():
			if hilang_pada < 0:
				hilang_pada = i
			continue
		if frame_lihat.back() != sekarang[0].frame:
			frame_lihat.append(sekarang[0].frame)
	check(frame_lihat == [0, 1, 2, 3, 4, 5] and hilang_pada >= 24 and hilang_pada <= 25, "bintang sekali main: frame %s, hilang pada langkah ke-%d (0,4 detik = 24 langkah), tidak berulang" % [frame_lihat, hilang_pada])
	check(gambar.teks_tampil().is_empty() and gambar.item_sprite().is_empty(), "sesudah 0,8 detik: label dan sprite habis")
	# 2. Antaran ke teras @18 (pemberi tip): bintang dan koin, label tanpa baris tip.
	var k2: KoranLempar.Koran = await _lempar_ke_titik(akar, 12.0, Vector2(-2.75, 18.5), mendarat)
	var item_tip: Array[DefSprite.Item] = gambar.item_sprite()
	check(k2 != null and k2.id_rumah == "per_buka_01@18" and akar.skor().jumlah_tip == 1 and akar.skor().koin_tip == 5, "kontrol: antaran teras ke pemberi tip: tip 5")
	check(_nama(item_tip) == ["vfx_bintang_kena", "vfx_koin_tip"], "tip: bintang kena dan koin tip sama-sama menyala sekali")
	if k2 != null and item_tip.size() == 2:
		var titik2: Vector2 = _layar(k2.lintasan.titik_mendarat.x, k2.lintasan.titik_mendarat.y)
		check(item_tip[1].pojok == titik2 - Vector2(8, 24) and item_tip[1].frame == 0, "koin berpijak (8, 24) di titik mendarat %s, frame 0" % [titik2])
	check(gambar.teks_tampil() == ["+15"], "label tanpa baris tip (diganti sprite koin): %s" % [gambar.teks_tampil()])
	var frame_koin: Array[int] = [0]
	var koin_hilang: int = -1
	for i: int in range(1, 60):
		akar.perbarui(DT)
		var ada: bool = false
		for it: DefSprite.Item in gambar.item_sprite():
			if it.nama == "vfx_koin_tip":
				ada = true
				if frame_koin.back() != it.frame:
					frame_koin.append(it.frame)
		if not ada and koin_hilang < 0:
			koin_hilang = i
	check(frame_koin == [0, 1, 2, 3, 4, 5] and koin_hilang >= 36 and koin_hilang <= 37, "koin sekali main (10 fps): frame %s, hilang pada langkah ke-%d (0,6 detik = 36 langkah)" % [frame_koin, koin_hilang])
	# 3. Jeda membekukan bintang dan koin.
	var k3: KoranLempar.Koran = await _lempar_ke_titik(akar, 4.0, Vector2(-2.75, 10.5), mendarat)
	check(k3 != null, "kontrol: antaran ke teras berikutnya")
	_langkah(akar, 10)
	var sebelum: Array[DefSprite.Item] = gambar.item_sprite()
	var frame_sebelum: Array[int] = []
	for it: DefSprite.Item in sebelum:
		frame_sebelum.append(it.frame)
	akar.minta_jeda()
	_langkah(akar, 40)
	var frame_jeda: Array[int] = []
	for it: DefSprite.Item in gambar.item_sprite():
		frame_jeda.append(it.frame)
	check(not sebelum.is_empty() and frame_jeda == frame_sebelum, "jeda game 40 langkah: frame bintang dan koin membeku %s" % [frame_jeda])
	akar.minta_lanjut()
	# 4. Koran ulang (netral): tidak menyalakan apa pun. Meleset (aspal, tidak sah): tidak menyalakan apa pun.
	_langkah(akar, 60)
	var ulang: KoranLempar.Koran = await _lempar_ke_kotak(akar, 1.0, "per_buka_01@6", mendarat)
	check(ulang != null and ulang.penanda == ZonaSasaran.Penanda.NETRAL and gambar.item_sprite().is_empty() and gambar.teks_tampil().is_empty(), "koran ulang ke rumah terantar (netral): tidak ada bintang, koin, atau label")
	_langkah(akar, 60)
	var jumlah_skor: int = akar.skor().skor
	var meleset: KoranLempar.Koran = await _lempar_ke_titik(akar, 4.0, Vector2(-0.5, 10.5), mendarat)
	check(meleset != null and meleset.hasil == ZonaSasaran.Hasil.MELESET and akar.skor().skor == jumlah_skor and gambar.item_sprite().is_empty() and gambar.teks_tampil().is_empty(), "koran meleset (tidak sah): tidak ada bintang, koin, atau label")
	_bersihkan(akar)
	# Entri dengan tip bukan 5 (KOIN_TIP berbeda): sprite koin tidak dipakai, baris tip label tampil.
	var akar2: RuteMain = await _siapkan()
	var entri: UmpanMelayang.Entri = UmpanMelayang.Entri.new()
	entri.ongkos = 15
	entri.tip = 6
	entri.sisa_detik = 0.8
	check(akar2.umpan_gambar().teks(entri) == "+15\n%s" % tr("RUTE_UMPAN_TIP").format({"n": 6}) and akar2.umpan_gambar().teks(entri).contains("6"), "tip 6: baris tip label tampil ('%s'), sprite koin tidak dipakai" % akar2.umpan_gambar().teks(entri).replace("\n", " / "))
	entri.tip = 5
	check(akar2.umpan_gambar().teks(entri) == "+15", "tip 5: label hanya '+15' (tip di sprite koin)")
	entri.tip = 0
	check(akar2.umpan_gambar().teks(entri) == "+15", "tanpa tip: label hanya '+15'")
	_bersihkan(akar2)


func _test_tip_sesudah_tenggat_tanpa_koin() -> void:
	_judul.call("Scene rute: sesudah tenggat lewat tip 0, jadi bintang menyala tetapi koin tidak (AC-14)")
	var akar: RuteMain = await _siapkan()
	var gambar: UmpanMelayangGambar = akar.umpan_gambar()
	var mendarat: Array[KoranLempar.Koran] = []
	akar.koran_mendarat.connect(func(k: KoranLempar.Koran) -> void: mendarat.append(k))
	akar.atur_tenggat(TenggatRute.langkah(TenggatRute.awal(akar.rute().panjang_ubin), 91.5))
	var k: KoranLempar.Koran = await _lempar_ke_titik(akar, 12.0, Vector2(-2.75, 18.5), mendarat)
	check(k != null and k.id_rumah == "per_buka_01@18" and akar.skor().jumlah_tip == 0, "kontrol: teras pemberi tip sesudah tenggat: tanpa tip")
	check(_nama(gambar.item_sprite()) == ["vfx_bintang_kena"] and gambar.teks_tampil() == ["+15"], "bintang menyala, koin tidak, label '+15'")
	_bersihkan(akar)


# --- Kilau (AC-15) ---

func _test_kilau_murni() -> void:
	_judul.call("KucingHiasan.item_kilau: sprite mission_kilau 9x9 di tengah kotak 11x11 pojok (-5, -33), ritme 0,4 detik (AC-15, D-6)")
	var f0: Array[DefSprite.Item] = KucingHiasan.item_kilau(true, 0.0)
	var f1: Array[DefSprite.Item] = KucingHiasan.item_kilau(true, 0.4)
	var f2: Array[DefSprite.Item] = KucingHiasan.item_kilau(true, 0.81)
	check(f0.size() == 1 and f0[0].nama == "mission_kilau" and f0[0].frame == 0 and f1[0].frame == 1 and f2[0].frame == 0, "frame kilau 0, 1, 0 pada 0,0; 0,4; 0,81 detik (MISI_KILAU_DETIK = 0,4 tidak berubah)")
	check(Config.MISI_KILAU_DETIK == 0.4 and Config.MISI_KILAU_POSISI_PX == [-5, -33] and Config.MISI_KILAU_KOTAK_PX == [11, 11], "konstanta ritme, posisi, dan kotak kilau tidak berubah")
	check(f0[0].pojok == Vector2(-4, -32) and f1[0].pojok == Vector2(-4, -32), "pojok sprite (-4, -32) = pojok kotak (-5, -33) + geser tengah (1, 1)")
	check(KucingHiasan.item_kilau(false, 0.0).is_empty() and KucingHiasan.item_kilau(false, 5.0).is_empty(), "tanpa petunjuk kilau: tidak ada item")
	check(KucingHiasan.frame_kilau(0.0) == 0 and KucingHiasan.frame_kilau(0.39) == 0 and KucingHiasan.frame_kilau(0.4) == 1 and KucingHiasan.frame_kilau(0.8) == 0 and KucingHiasan.frame_kilau(-1.0) == 0, "frame_kilau lama tidak berubah")


func _test_kilau_di_scene() -> void:
	_judul.call("Scene rute: kilau tampil tepat saat petunjuk visual kilau data misi menyala, di rumput dan trotoar (AC-15)")
	var akar: RuteMain = await _siapkan(true)
	var kucing: KucingMisi = akar.kucing()
	var t1: RencanaMisi.Titik = akar.rencana_misi().titik[0]
	_taruh(akar, 3.0, 0.5, maxf(t1.maju_ubin - 11.0, 0.0))
	akar.perbarui(DT)
	check(kucing.tampil() and kucing.titik() == t1, "kontrol: kucing titik 1 tampil")
	var visual: Array = _misi.petunjuk.get("visual", [])
	check(visual.has("kilau") and visual.has("ekor"), "kontrol: data misi p1_kucing memuat petunjuk visual kilau dan ekor")
	var item: Array[DefSprite.Item] = kucing.hiasan().item_sprite()
	check(item.size() == 1 and item[0].nama == "mission_kilau" and item[0].pojok == Vector2(-4, -32), "petunjuk kilau menyala: satu sprite mission_kilau di pojok (-4, -32) dari titik pijak kucing")
	# Frame mengikuti waktu animasi (waktu efektif); ritme 0,4 detik.
	var frame: Array[int] = []
	for i: int in range(60):
		akar.perbarui(DT)
		var sekarang: Array[DefSprite.Item] = kucing.hiasan().item_sprite()
		if sekarang.size() == 1 and (frame.is_empty() or frame.back() != sekarang[0].frame):
			frame.append(sekarang[0].frame)
	check(frame.size() >= 2 and frame[0] != frame[1], "kilau berganti frame saat waktu berjalan: %s" % [frame])
	# Kilau tampil di rumput atau trotoar: titik kucing (lateral) dalam kolom rumput atau trotoar di kolom ubin tanah.
	var kolom: JalanDaur.Kolom = JalanDaur.kolom_di(t1.lateral_ubin)
	check(kolom == JalanDaur.Kolom.RUMPUT_SEBERANG or kolom == JalanDaur.Kolom.TROTOAR_SEBERANG, "kucing titik 1 berdiri di rumput atau trotoar seberang (kolom %s)" % [JalanDaur.Kolom.keys()[kolom]])
	# Pemanggilan langsung: kilau false = tidak ada sprite; true = ada.
	kucing.tampilkan(t1, _sepeda(akar).jarak_ubin, 0.0, 0.0, false, true)
	check(kucing.hiasan().item_sprite().is_empty(), "tampilkan(kilau false): tidak ada sprite kilau")
	kucing.tampilkan(t1, _sepeda(akar).jarak_ubin, 0.0, 0.0, true, true)
	check(kucing.hiasan().item_sprite().size() == 1, "tampilkan(kilau true): satu sprite kilau")
	_bersihkan(akar)
	# Data misi tanpa kilau dalam petunjuk visual (hanya ekor): kilau tidak tampil dari alur nyata.
	var tanpa: DataMisi = PemuatMisi.muat_folder().cari("p1_kucing")
	tanpa.petunjuk["visual"] = ["ekor"]
	var akar2: RuteMain = await _siapkan(true, tanpa)
	var t2: RencanaMisi.Titik = akar2.rencana_misi().titik[0]
	_taruh(akar2, 3.0, 0.5, maxf(t2.maju_ubin - 11.0, 0.0))
	akar2.perbarui(DT)
	check(akar2.kucing().tampil() and akar2.kucing().hiasan().item_sprite().is_empty(), "petunjuk visual tanpa kilau: kucing tampil tanpa sprite kilau")
	_bersihkan(akar2)
