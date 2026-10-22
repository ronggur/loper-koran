class_name TesUbin5b
extends RefCounted
## Tes ubin khusus run fase5b-tembok-dekor bagian C (AC-14, AC-15, AC-16; D-7): pemilihan murni (`UbinKhusus`: baris jalan masuk garasi, simbol sepeda tiap 12 baris, variasi rumput luar
## dari hash FNV-1a), pemasangan di `TanahDaur` (tekstur dan wadah menurut baris mutlak, sel/posisi/jumlah sprite tidak berubah, satu wadah satu tekstur), scene rute (mobil seberang di
## atas ubin masuk, "Main lagi"), tanpa celah dan tanpa pita dengan semua tekstur baru, dan susunan Godot piksel-identik dengan referensi Python.
##
## Harapan ditulis sebagai literal, atau dihitung dengan cara lain dari kode produksi: nilai hash dihitung di Python (`struct` + FNV-1a, nilai ditempel di sini), pemetaan kolom dan simbol
## ditulis ulang per kolom di `_nama_harapan` (tanpa `JalanDaur.kolom_di` dan tanpa `UbinKhusus`), hash tes memakai `PackedByteArray.encode_s32` (bukan geser bit), letak dunia ubin dari piksel
## layar dengan rumus proyeksi 2:1 ditulis ulang, dan susunan referensi dari `tests/data/ubin_potongan_5b.png` (dibuat `tools/tests_cek/uji_aset_pasang_5b.py` dari berkas assets/).

const BERKAS_RUTE: String = "res://scenes/rute/rute.tscn"
const FOLDER_UBIN: String = "res://assets/sprites/tiles/perumahan/"
const REFERENSI: String = "res://tests/data/ubin_potongan_5b.png"
const TINGGI: int = 360
const LEBAR_UJI: Array[int] = [640, 667, 780, 800]
## Nama berkas ubin yang dipakai tes (semuanya ubin dipasang, D-1).
const N_ASPAL_SEBERANG: String = "aspal_seberang"
const N_ASPAL_DEKAT: String = "aspal_dekat"
const N_RUMPUT_SEBERANG: String = "rumput_seberang"
const N_TROTOAR_SEBERANG: String = "trotoar_seberang"
const N_TROTOAR_DEKAT: String = "trotoar_dekat"
const N_RUMPUT_DEKAT: String = "rumput_dekat"
const N_RUMPUT_1: String = "rumput_1"
const N_RUMPUT_2: String = "rumput_2"
const N_RUMPUT_3: String = "rumput_3"
const N_MASUK_TROTOAR: String = "trotoar_seberang_masuk"
const N_MASUK_RUMPUT: String = "rumput_seberang_masuk"
const N_SIMBOL_SEBERANG: String = "trotoar_seberang_simbol"
const N_SIMBOL_DEKAT: String = "trotoar_dekat_simbol"
## Ujung kerb jalan masuk (run fase5c-animasi-simpang, C-F1): baris maju + 1 dari jalan masuk, kolom trotoar dan rumput pertama seberang.
const N_UJUNG_TROTOAR: String = "trotoar_seberang_masuk_ujung"
const N_UJUNG_RUMPUT: String = "rumput_seberang_masuk_ujung"
## Nama wadah baru dan tekstur masing-masing (urut sama dengan `TanahDaur.bangun`).
const WADAH_BARU: Array[String] = ["RumputLuar2", "RumputLuar3", "MasukTrotoarSeberang", "MasukRumputSeberang", "SimbolTrotoarSeberang", "SimbolTrotoarDekat", "UjungTrotoarSeberang", "UjungRumputSeberang"]
const TEKSTUR_WADAH_BARU: Array[String] = [N_RUMPUT_2, N_RUMPUT_3, N_MASUK_TROTOAR, N_MASUK_RUMPUT, N_SIMBOL_SEBERANG, N_SIMBOL_DEKAT, N_UJUNG_TROTOAR, N_UJUNG_RUMPUT]
## Awal nama berkas yang tidak boleh muncul di sumber (disambung supaya berkas ini tidak cocok dengan dirinya sendiri): ubin `aspal_N` dan `*_dekat_masuk` tidak dipasang (D-1, D-4).
const TERLARANG_UBIN: Array[String] = ["tile_perumahan_" + "aspal_1", "tile_perumahan_" + "trotoar_dekat_masuk", "tile_perumahan_" + "rumput_dekat_masuk"]

var _cek: Callable
var _judul: Callable
var _tree: SceneTree
var _gambar: Dictionary = {}


func _init(cek: Callable, judul: Callable, tree: SceneTree) -> void:
	_cek = cek
	_judul = judul
	_tree = tree


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_test_baris_masuk()
	_test_himpunan_baris_masuk()
	_test_baris_masuk_rute_nyata()
	_test_simbol_sepeda()
	_test_hash()
	_test_varian_rumput()
	_test_jenis_ubin()
	_test_kolom_pertama_dan_proporsi()
	_test_tanpa_hash_bawaan()
	_test_tanah_khusus()
	_test_tanah_tanpa_khusus_tetap()
	await _test_scene_rute()
	_test_tanpa_celah()
	_test_tanpa_pita()
	_test_susunan_referensi()
	_test_pemindai_dan_scene_dev()


# --- Pembantu ---

func _tekstur(nama: String) -> Texture2D:
	return load(FOLDER_UBIN + "tile_perumahan_%s.png" % nama) as Texture2D


## `TanahDaur` dengan semua tekstur (15): enam kolom, rumput polos, enam tekstur khusus, dan dua ujung kerb (run 5C). Tanpa ubin simpang (diuji `tes_simpang.gd`).
func _buat_tanah(khusus: bool = true) -> TanahDaur:
	var tanah: TanahDaur = TanahDaur.new()
	tanah.tekstur_kolom_rumput_seberang = _tekstur(N_RUMPUT_SEBERANG)
	tanah.tekstur_kolom_trotoar_seberang = _tekstur(N_TROTOAR_SEBERANG)
	tanah.tekstur_kolom_aspal_seberang = _tekstur(N_ASPAL_SEBERANG)
	tanah.tekstur_kolom_aspal_dekat = _tekstur(N_ASPAL_DEKAT)
	tanah.tekstur_kolom_trotoar_dekat = _tekstur(N_TROTOAR_DEKAT)
	tanah.tekstur_kolom_rumput_dekat = _tekstur(N_RUMPUT_DEKAT)
	tanah.tekstur_rumput_luar = _tekstur(N_RUMPUT_1)
	if khusus:
		tanah.tekstur_rumput_luar_2 = _tekstur(N_RUMPUT_2)
		tanah.tekstur_rumput_luar_3 = _tekstur(N_RUMPUT_3)
		tanah.tekstur_masuk_trotoar_seberang = _tekstur(N_MASUK_TROTOAR)
		tanah.tekstur_masuk_rumput_seberang = _tekstur(N_MASUK_RUMPUT)
		tanah.tekstur_simbol_trotoar_seberang = _tekstur(N_SIMBOL_SEBERANG)
		tanah.tekstur_simbol_trotoar_dekat = _tekstur(N_SIMBOL_DEKAT)
		tanah.tekstur_ujung_trotoar_seberang = _tekstur(N_UJUNG_TROTOAR)
		tanah.tekstur_ujung_rumput_seberang = _tekstur(N_UJUNG_RUMPUT)
	return tanah


func _sprite_ubin(tanah: TanahDaur) -> Array[Sprite2D]:
	var hasil: Array[Sprite2D] = []
	for wadah: Node in tanah.get_children():
		for anak: Node in wadah.get_children():
			hasil.append(anak as Sprite2D)
	return hasil


func _hitung_node(simpul: Node) -> int:
	var jumlah: int = 1
	for anak: Node in simpul.get_children():
		jumlah += _hitung_node(anak)
	return jumlah


## Posisi dunia (ubin) pusat ubin dari posisi layar relatif blok (rumus proyeksi 2:1 ditulis ulang, bukan `Iso`).
func _dunia_dari_layar(layar: Vector2) -> Vector2:
	return Vector2((layar.y / 16.0 + layar.x / 32.0) / 2.0, (layar.y / 16.0 - layar.x / 32.0) / 2.0)


func _gambar_tekstur(tekstur: Texture2D) -> Image:
	var kunci: String = tekstur.resource_path
	if not _gambar.has(kunci):
		var g: Image = tekstur.get_image()
		g.convert(Image.FORMAT_RGBA8)
		_gambar[kunci] = g
	return _gambar[kunci] as Image


func _susun(tanah: TanahDaur, asal: Vector2i, ukuran: Vector2i) -> Image:
	var kanvas: Image = Image.create(ukuran.x, ukuran.y, false, Image.FORMAT_RGBA8)
	kanvas.fill(Color(0, 0, 0, 0))
	for ubin: Sprite2D in _sprite_ubin(tanah):
		var g: Image = _gambar_tekstur(ubin.texture)
		var pojok: Vector2i = Vector2i(ubin.position + tanah.position) - Vector2i(g.get_width() / 2, g.get_height() / 2) - asal
		kanvas.blend_rect(g, Rect2i(Vector2i.ZERO, g.get_size()), pojok)
	return kanvas


## FNV-1a 32 bit atas dua bilangan bulat (oracle tes): empat byte little-endian tiap bilangan lewat `encode_s32`, bukan geser bit seperti `UbinKhusus`.
func _fnv(a: int, b: int) -> int:
	var data: PackedByteArray = PackedByteArray()
	data.resize(8)
	data.encode_s32(0, a)
	data.encode_s32(4, b)
	var h: int = 2166136261
	for byte: int in data:
		h = ((h ^ byte) * 16777619) & 4294967295
	return h


## Nama berkas (tanpa `tile_perumahan_` dan `.png`) yang HARUS dipakai sel berpusat `x` di baris mutlak `baris` (oracle D-7 ditulis per kolom, tanpa `UbinKhusus` dan `JalanDaur`).
func _nama_harapan(x: float, baris: int, masuk: Dictionary, simbol_baris: Array[int]) -> String:
	var ic: int = int(floor(x))
	var ada_masuk: bool = masuk.has(baris)
	# Run 5C (C-F1): baris tepat satu di depan jalan masuk (maju + 1) dan bukan jalan masuk = ujung kerb di dua kolom seberang, menang atas simbol.
	var ujung: bool = masuk.has(baris - 1) and not ada_masuk
	var simbol: bool = simbol_baris.has(baris)
	if absf(x) >= 3.0:
		var v: int = _fnv(ic, baris) % 100
		if v < 12:
			return N_RUMPUT_2
		if v < 20:
			return N_RUMPUT_3
		return N_RUMPUT_1
	if ic == -3:
		if ujung:
			return N_UJUNG_RUMPUT
		return N_MASUK_RUMPUT if ada_masuk else N_RUMPUT_SEBERANG
	if ic == -2:
		if ada_masuk:
			return N_MASUK_TROTOAR
		if ujung:
			return N_UJUNG_TROTOAR
		return N_SIMBOL_SEBERANG if simbol else N_TROTOAR_SEBERANG
	if ic == -1:
		return N_ASPAL_SEBERANG
	if ic == 0:
		return N_ASPAL_DEKAT
	if ic == 1:
		return N_SIMBOL_DEKAT if (simbol and not ada_masuk) else N_TROTOAR_DEKAT
	return N_RUMPUT_DEKAT


## Baris simbol sepeda literal (tiga periode, juga negatif): 6 + 12 k.
func _baris_simbol(dari: int, sampai: int) -> Array[int]:
	var hasil: Array[int] = []
	for b: int in range(dari, sampai + 1):
		if (b - 6) % 12 == 0:
			hasil.append(b)
	return hasil


func _objek(jenis: String, jalur: String, maju: float) -> RouteBuilder.ObjekRute:
	var o: RouteBuilder.ObjekRute = RouteBuilder.ObjekRute.new()
	o.jenis = jenis
	o.jalur = jalur
	o.maju_ubin = maju
	return o


# --- AC-14: pemilihan murni ---

func _test_baris_masuk() -> void:
	_judul.call("Ubin khusus: baris jalan masuk dari titik rumah mobil (AC-14, D-7, oracle tabel)")
	var tabel: Array = [
		# maju mobil, baris
		[17.0, 17], [53.0, 53], [0.0, 0], [1.0, 1], [16.6, 17], [17.4, 17], [17.49, 17], [16.51, 17], [18.2, 18],
		# tepat di batas dua baris: dibuang ke baris di belakang (maju lebih kecil)
		[17.5, 17], [16.5, 16], [0.5, 0], [-0.5, -1], [100.5, 100],
		# sedikit di atas batas: baris di depan
		[17.51, 18], [16.51, 17], [100.51, 101],
	]
	for baris: Array in tabel:
		check(UbinKhusus.baris_masuk(baris[0] as float) == baris[1], "baris_masuk(%s) = %s (dapat %s)" % [baris[0], baris[1], UbinKhusus.baris_masuk(baris[0] as float)])
	# Mobil selebar 0,75 ubin (`MOBIL_SETENGAH_LEBAR_UBIN` 0,375) di titik maju bulat selalu seluruhnya di dalam satu baris (maju - 0,5 sampai maju + 0,5).
	check(Config.MOBIL_SETENGAH_LEBAR_UBIN == 0.375 and Config.MOBIL_PANJANG_UBIN == 1.5, "ukuran mobil tidak berubah (0,375 dan 1,5)")


func _test_himpunan_baris_masuk() -> void:
	_judul.call("Ubin khusus: himpunan baris masuk hanya dari mobil garasi sisi seberang (AC-14)")
	var kosong: Array[RouteBuilder.ObjekRute] = []
	check(UbinKhusus.himpunan_baris_masuk(kosong).is_empty(), "tanpa objek = tanpa baris masuk")
	var satu: Array[RouteBuilder.ObjekRute] = [_objek("mobil_garasi", "seberang", 17.0)]
	check(UbinKhusus.himpunan_baris_masuk(satu) == {17: true}, "satu mobil seberang di maju 17 = {17}")
	var dekat: Array[RouteBuilder.ObjekRute] = [_objek("mobil_garasi", "dekat", 17.0)]
	check(UbinKhusus.himpunan_baris_masuk(dekat).is_empty(), "mobil sisi dekat tidak punya ubin masuk (aset *_dekat_masuk tidak dipasang)")
	var anjing: Array[RouteBuilder.ObjekRute] = [_objek("anjing_penjaga", "seberang", 17.0), _objek("anjing_penjaga", "dekat", 20.0)]
	check(UbinKhusus.himpunan_baris_masuk(anjing).is_empty(), "anjing penjaga tidak punya ubin masuk")
	var campur: Array[RouteBuilder.ObjekRute] = [
		_objek("anjing_penjaga", "seberang", 8.0), _objek("mobil_garasi", "seberang", 17.0), _objek("mobil_garasi", "dekat", 30.0),
		_objek("mobil_garasi", "seberang", 53.0), _objek("anjing_penjaga", "dekat", 60.0),
	]
	check(UbinKhusus.himpunan_baris_masuk(campur) == {17: true, 53: true}, "campuran: hanya dua mobil seberang = {17, 53}")


## Rute nyata: tiap mobil seberang menghasilkan tepat satu baris yang seluruh bentuk mobilnya (maju +- 0,375) ada di dalam baris itu.
func _test_baris_masuk_rute_nyata() -> void:
	_judul.call("Ubin khusus: baris masuk di rute nyata menutup mobil (60 seed, AC-14, D-7)")
	var kumpulan: PemuatRute.Kumpulan = PemuatRute.muat_folder()
	var jumlah_mobil: int = 0
	var salah: int = 0
	var contoh: String = ""
	var rute_dengan_mobil: int = 0
	for i: int in range(60):
		var hasil: RouteBuilder.Hasil = RouteBuilder.bangun(20261016 + 7 * i, kumpulan.segmen)
		if hasil.rute == null:
			salah += 1
			continue
		var himpunan: Dictionary = UbinKhusus.himpunan_baris_masuk(hasil.rute.objek)
		var mobil_seberang: Array[float] = []
		for o: RouteBuilder.ObjekRute in hasil.rute.objek:
			if o.jenis == "mobil_garasi" and o.jalur == "seberang":
				mobil_seberang.append(o.maju_ubin)
		jumlah_mobil += mobil_seberang.size()
		if not mobil_seberang.is_empty():
			rute_dengan_mobil += 1
		if himpunan.size() != mobil_seberang.size():
			salah += 1
			contoh = "seed %d: %d baris untuk %d mobil" % [20261016 + 7 * i, himpunan.size(), mobil_seberang.size()]
		for maju: float in mobil_seberang:
			var baris: int = int(roundf(maju))
			# mobil maju bulat: baris = maju; bentuk maju - 0,375 .. maju + 0,375 di dalam [baris - 0,5, baris + 0,5]
			if not himpunan.has(baris) or maju - 0.375 < float(baris) - 0.5 or maju + 0.375 > float(baris) + 0.5:
				salah += 1
				contoh = "seed %d: mobil maju %s baris %s" % [20261016 + 7 * i, maju, baris]
	check(jumlah_mobil >= 20 and rute_dengan_mobil >= 15, "60 rute nyata memuat cukup mobil seberang (%d mobil di %d rute)" % [jumlah_mobil, rute_dengan_mobil])
	check(salah == 0, "tiap mobil seberang punya satu baris yang memuat seluruh bentuknya: %s" % contoh)


func _test_simbol_sepeda() -> void:
	_judul.call("Ubin khusus: simbol sepeda tiap 12 baris (AC-14, tabel literal tiga periode)")
	check(Config.RUTE_SIMBOL_SEPEDA_SELANG_UBIN == 12, "selang simbol sepeda 12 baris (SPEC D-7)")
	check(Config.RUTE_SIMBOL_SEPEDA_OFFSET_UBIN == 6, "geseran simbol sepeda 6 baris (tetap di config)")
	var literal: Array[int] = [-30, -18, -6, 6, 18, 30, 42]
	var dapat: Array[int] = []
	for b: int in range(-35, 50):
		if UbinKhusus.simbol_di_baris(b):
			dapat.append(b)
	check(dapat == literal, "baris simbol dari -35 sampai 49 = %s (dapat %s)" % [literal, dapat])
	check(not UbinKhusus.simbol_di_baris(0) and UbinKhusus.simbol_di_baris(6) and UbinKhusus.simbol_di_baris(18) and not UbinKhusus.simbol_di_baris(17), "baris 0 dan 17 tidak, 6 dan 18 ya")
	# Selang 11 (mutan) akan menggeser baris ke-3 (30 menjadi 28 atau 33): jarak antar simbol berurutan selalu tepat 12.
	var jarak_ok: bool = true
	for i: int in range(literal.size() - 1):
		if dapat[i + 1] - dapat[i] != 12:
			jarak_ok = false
	check(jarak_ok, "jarak antar simbol berurutan tepat 12 baris")
	var jumlah: int = 0
	for b: int in range(0, 1200):
		if UbinKhusus.simbol_di_baris(b):
			jumlah += 1
	check(jumlah == 100, "100 simbol di 1200 baris pertama (dapat %d)" % jumlah)


func _test_hash() -> void:
	_judul.call("Ubin khusus: FNV-1a atas dua bilangan (oracle nilai dihitung di Python)")
	# (a, b, hasil 32 bit): `struct.pack('<ii', a, b)` lalu FNV-1a 32 bit di Python.
	var tabel: Array = [
		[0, 0, 2615243109], [1, 2, 3738734694], [-4, 0, 2853937378], [-4, 4, 3939278118], [3, 5, 146674515], [5, -7, 2107921090], [-100, 12345, 3340754267],
		[2147483647, 0, 3630398273], [0, -2147483648, 467811045], [-1, -1, 1823345245], [7, 17, 3601695779], [-4, 6, 1249124100], [-4, 7, 2594201109],
		[3, 4, 3096564802], [40, 53, 2582593544], [-33, -12, 2862052374],
	]
	for baris: Array in tabel:
		var dapat: int = UbinKhusus.fnv1a_dua_int(baris[0] as int, baris[1] as int)
		check(dapat == baris[2], "fnv1a_dua_int(%d, %d) = %d (dapat %d)" % [baris[0], baris[1], baris[2], dapat])
		check(_fnv(baris[0] as int, baris[1] as int) == baris[2], "oracle tes _fnv(%d, %d) = nilai Python" % [baris[0], baris[1]])
	check(UbinKhusus.fnv1a_dua_int(1, 2) != UbinKhusus.fnv1a_dua_int(2, 1), "urutan (kolom, baris) berpengaruh")
	check(Config.HASH_FNV1A_AWAL == 2166136261 and Config.HASH_FNV1A_KALI == 16777619 and Config.HASH_FNV1A_MASKER == 4294967295, "konstanta FNV-1a 32 bit baku")


func _test_varian_rumput() -> void:
	_judul.call("Ubin khusus: varian rumput dari hash mod 100 (AC-14, oracle tabel dari Python)")
	check(Config.RUTE_RUMPUT_VARIAN_MOD == 100 and Config.RUTE_RUMPUT_VARIAN_2_PERSEN == 12 and Config.RUTE_RUMPUT_VARIAN_3_PERSEN == 8, "modulus 100, rumput_2 12 persen, rumput_3 8 persen")
	# (kolom, baris, hash mod 100 dari Python, varian harapan): v < 12 rumput_2, v < 20 rumput_3, sisanya rumput_1.
	var tabel: Array = [
		[0, 0, 9, UbinKhusus.Ubin.RUMPUT_2], [1, 2, 94, UbinKhusus.Ubin.BAWAAN], [-4, 0, 78, UbinKhusus.Ubin.BAWAAN], [-4, 4, 18, UbinKhusus.Ubin.RUMPUT_3],
		[3, 5, 15, UbinKhusus.Ubin.RUMPUT_3], [5, -7, 90, UbinKhusus.Ubin.BAWAAN], [-4, 6, 0, UbinKhusus.Ubin.RUMPUT_2], [-4, 7, 9, UbinKhusus.Ubin.RUMPUT_2],
		[3, 4, 2, UbinKhusus.Ubin.RUMPUT_2], [40, 53, 44, UbinKhusus.Ubin.BAWAAN], [-33, -12, 74, UbinKhusus.Ubin.BAWAAN], [7, 17, 79, UbinKhusus.Ubin.BAWAAN],
		[-1, -1, 45, UbinKhusus.Ubin.BAWAAN],
	]
	for baris: Array in tabel:
		var kolom: int = baris[0] as int
		var b: int = baris[1] as int
		check(UbinKhusus.varian_rumput(kolom, b) == baris[3], "varian_rumput(%d, %d) = %s (hash mod 100 = %d)" % [kolom, b, UbinKhusus.Ubin.keys()[baris[3] as int], baris[2]])
	var sama: bool = true
	for kolom: int in range(3, 40):
		for b: int in range(-20, 60):
			if UbinKhusus.varian_rumput(kolom, b) != UbinKhusus.varian_rumput(kolom, b):
				sama = false
	check(sama, "deterministik: panggilan berulang sama")


func _test_jenis_ubin() -> void:
	_judul.call("Ubin khusus: jenis ubin per kolom dan baris (AC-14, oracle tabel literal)")
	var masuk: Dictionary = {17: true, 18: true}
	var dua: Array[RouteBuilder.ObjekRute] = [_objek("mobil_garasi", "seberang", 17.0), _objek("mobil_garasi", "seberang", 18.0)]
	var m: Dictionary = UbinKhusus.himpunan_baris_masuk(dua)
	check(m == masuk, "himpunan uji = {17, 18}")
	var kosong: Dictionary = {}
	var B: UbinKhusus.Ubin = UbinKhusus.Ubin.BAWAAN
	var MASUK: UbinKhusus.Ubin = UbinKhusus.Ubin.MASUK
	var SIMBOL: UbinKhusus.Ubin = UbinKhusus.Ubin.SIMBOL
	# [x, baris, himpunan masuk (true = {17, 18}), harapan]
	var tabel: Array = [
		# baris masuk 17: trotoar seberang dan rumput pertama seberang = MASUK, kolom lain bawaan; kolom luar: hash (-4, 17) mod 100 = 51 (rumput_1) dan (3, 17) = 19 (rumput_3), dari Python
		[-3.5, 17, true, B], [-2.5, 17, true, MASUK], [-1.5, 17, true, MASUK], [-0.5, 17, true, B], [0.5, 17, true, B], [1.5, 17, true, B], [2.5, 17, true, B], [3.5, 17, true, UbinKhusus.Ubin.RUMPUT_3],
		# baris masuk dan simbol sekaligus (18): MASUK menang, tidak ada simbol di kedua trotoar
		[-1.5, 18, true, MASUK], [1.5, 18, true, B], [-2.5, 18, true, MASUK],
		# tanpa mobil di baris itu: simbol di baris 18 di kedua trotoar, tidak ada masuk
		[-1.5, 18, false, SIMBOL], [1.5, 18, false, SIMBOL], [-2.5, 18, false, B], [2.5, 18, false, B],
		# baris biasa: semua kolom pertama bawaan
		[-1.5, 20, true, B], [1.5, 20, true, B], [-2.5, 20, true, B], [-0.5, 18, false, B], [0.5, 18, false, B],
		# baris simbol saja (6, 30, -6)
		[-1.5, 6, false, SIMBOL], [1.5, 30, false, SIMBOL], [1.5, -6, false, SIMBOL], [-1.5, 7, false, B],
		# mobil sisi seberang tidak memengaruhi sisi dekat: rumput dekat pertama tidak pernah MASUK
		[2.5, 17, true, B],
	]
	for baris: Array in tabel:
		var him: Dictionary = masuk if baris[2] else kosong
		var dapat: UbinKhusus.Ubin = UbinKhusus.jenis(baris[0] as float, baris[1] as int, him)
		check(dapat == baris[3], "jenis(x %s, baris %s, masuk %s) = %s (dapat %s)" % [baris[0], baris[1], baris[2], UbinKhusus.Ubin.keys()[baris[3] as int], UbinKhusus.Ubin.keys()[dapat as int]])
	# Kolom luar mengikuti `varian_rumput(lantai x, baris)` di kedua sisi.
	for x: float in [-3.5, -4.5, -10.5, 3.5, 4.5, 50.5]:
		for b: int in [0, 5, 17, -3]:
			check(UbinKhusus.jenis(x, b, masuk) == UbinKhusus.varian_rumput(floori(x), b), "kolom luar x %s baris %s mengikuti varian_rumput(lantai x, baris)" % [x, b])
	# Kolom aspal tidak pernah khusus.
	for x: float in [-0.5, 0.5]:
		for b: int in range(-20, 60):
			if UbinKhusus.jenis(x, b, masuk) != B:
				check(false, "aspal x %s baris %s harus bawaan" % [x, b])
	check(true, "kolom aspal tidak pernah khusus (80 sel)")


func _test_kolom_pertama_dan_proporsi() -> void:
	_judul.call("Ubin khusus: kolom rumput pertama tidak diganti variasi, proporsi variasi 5 sampai 25 persen (AC-14)")
	var masuk: Dictionary = {17: true}
	var ganti: int = 0
	for b: int in range(-600, 600):
		if UbinKhusus.jenis(2.5, b, masuk) != UbinKhusus.Ubin.BAWAAN:
			ganti += 1
		var jenis_seberang: UbinKhusus.Ubin = UbinKhusus.jenis(-2.5, b, masuk)
		if jenis_seberang == UbinKhusus.Ubin.RUMPUT_2 or jenis_seberang == UbinKhusus.Ubin.RUMPUT_3:
			ganti += 1
		if jenis_seberang == UbinKhusus.Ubin.SIMBOL:
			ganti += 1
		# Run 5C (C-F1): baris 18 (maju + 1 dari jalan masuk 17) = ujung kerb, satu-satunya baris lain yang bukan bawaan.
		if b == 18 and jenis_seberang != UbinKhusus.Ubin.UJUNG:
			ganti += 1
		if b != 17 and b != 18 and jenis_seberang != UbinKhusus.Ubin.BAWAAN:
			ganti += 1
	check(ganti == 0, "kolom rumput pertama (-2,5 dan 2,5) tidak pernah rumput_2, rumput_3, atau simbol (1200 baris); masuk hanya di baris 17, ujung kerb hanya di baris 18")
	# 10.000 sel kolom luar: x = 3,5 .. 102,5 (seberang dan dekat bergantian), baris 0 .. 99.
	var hitung: Dictionary = {UbinKhusus.Ubin.BAWAAN: 0, UbinKhusus.Ubin.RUMPUT_2: 0, UbinKhusus.Ubin.RUMPUT_3: 0}
	var total: int = 0
	for i: int in range(100):
		var x: float = 3.5 + float(i)
		if i % 2 == 1:
			x = -x
		for b: int in range(100):
			var jenis: UbinKhusus.Ubin = UbinKhusus.jenis(x, b, {})
			hitung[jenis] = int(hitung[jenis]) + 1
			total += 1
	var r2: float = float(hitung[UbinKhusus.Ubin.RUMPUT_2]) / total
	var r3: float = float(hitung[UbinKhusus.Ubin.RUMPUT_3]) / total
	var r1: float = float(hitung[UbinKhusus.Ubin.BAWAAN]) / total
	check(total == 10000, "10.000 sel kolom luar diperiksa")
	check(r2 >= 0.05 and r2 <= 0.25, "rumput_2 antara 5 dan 25 persen: %.3f" % r2)
	check(r3 >= 0.05 and r3 <= 0.25, "rumput_3 antara 5 dan 25 persen: %.3f" % r3)
	check(r1 > 0.5 and r1 > r2 + r3, "rumput_1 dominan: %.3f" % r1)
	# Oracle independen: hitung proporsi dengan hash tes (encode_s32) pada sel yang sama.
	var o2: int = 0
	var o3: int = 0
	for i: int in range(100):
		var x2: float = 3.5 + float(i)
		if i % 2 == 1:
			x2 = -x2
		for b: int in range(100):
			var v: int = _fnv(int(floor(x2)), b) % 100
			if v < 12:
				o2 += 1
			elif v < 20:
				o3 += 1
	check(o2 == hitung[UbinKhusus.Ubin.RUMPUT_2] and o3 == hitung[UbinKhusus.Ubin.RUMPUT_3], "jumlah rumput_2 (%d) dan rumput_3 (%d) = hitungan oracle tes" % [o2, o3])
	# Tidak ada dua sel bersebelahan yang membentuk pita: panjang barisan variasi berurutan sepanjang jalan paling banyak 6.
	var terpanjang: int = 0
	for i: int in range(3, 60):
		var baris_variasi: int = 0
		for b: int in range(0, 300):
			if UbinKhusus.jenis(float(i) + 0.5, b, {}) != UbinKhusus.Ubin.BAWAAN:
				baris_variasi += 1
				terpanjang = maxi(terpanjang, baris_variasi)
			else:
				baris_variasi = 0
	check(terpanjang <= 6, "barisan variasi rumput berurutan sepanjang jalan paling banyak 6 sel (dapat %d)" % terpanjang)


func _test_tanpa_hash_bawaan() -> void:
	_judul.call("Ubin khusus: tanpa hash() bawaan, RNG, node, atau Godot lain di modul murni (AC-14, AC-20)")
	var teks: String = FileAccess.get_file_as_string("res://scripts/systems/ubin_khusus.gd")
	for kata: String in ["hash(", "randi", "randf", "RandomNumberGenerator", "Time.", "get_tree", "Node2D", "extends Node"]:
		check(not teks.contains(kata), "ubin_khusus.gd tidak memuat %s" % kata)
	check(teks.contains("extends RefCounted") and teks.contains("class_name UbinKhusus"), "UbinKhusus = RefCounted murni")
	check(teks.contains("fnv1a_dua_int") and teks.contains("HASH_FNV1A_AWAL"), "memakai FNV-1a dengan konstanta config")
	var jalan: String = FileAccess.get_file_as_string("res://scripts/systems/jalan_daur.gd")
	check(not jalan.contains("UbinKhusus"), "jalan_daur.gd tidak merujuk UbinKhusus (sel_tanah, kolom_di, jenis_di tidak berubah)")


# --- AC-15: pemasangan di TanahDaur ---

## Cacah sprite yang tidak sesuai oracle di `tanah` untuk jarak `jarak` dan himpunan baris masuk `masuk`. Kembali [salah, total, contoh, per_nama].
func _periksa_tanah(tanah: TanahDaur, jarak: float, masuk: Dictionary, pita_dekat: Dictionary = {}) -> Array:
	var blok: int = int(floor(jarak))
	var simbol: Array[int] = _baris_simbol(blok - 200, blok + 200)
	var salah: int = 0
	var contoh: String = ""
	var per_nama: Dictionary = {}
	var sprite: Array[Sprite2D] = _sprite_ubin(tanah)
	for ubin: Sprite2D in sprite:
		var dunia: Vector2 = _dunia_dari_layar(ubin.position)
		var baris: int = int(round(-dunia.y)) + blok
		var harapan: String = _nama_harapan(dunia.x, baris, masuk, simbol)
		var jalur: String = ubin.texture.resource_path
		var nama: String = jalur.get_file().trim_prefix("tile_perumahan_").trim_suffix(".png")
		per_nama[nama] = int(per_nama.get(nama, 0)) + 1
		# Run 5C: di baris pita simpang dekat rute (`pita_dekat`), sel sisi dekat boleh memakai ubin simpang dekat (letaknya diuji per sel di `tes_simpang.gd`).
		if pita_dekat.has(baris) and dunia.x > 0.0 and nama.begins_with("simpang_dekat_"):
			continue
		if nama != harapan:
			salah += 1
			if contoh.is_empty():
				contoh = "x %s baris %d: tekstur %s harapan %s" % [dunia.x, baris, nama, harapan]
	return [salah, sprite.size(), contoh, per_nama]


func _test_tanah_khusus() -> void:
	_judul.call("Ubin khusus: TanahDaur memasang ubin menurut baris mutlak (AC-15, oracle per kolom)")
	var tanah: TanahDaur = _buat_tanah(true)
	check(tanah.mode_khusus() and tanah.mode_enam_kolom(), "tiga belas tekstur terisi = mode khusus")
	var masuk: Dictionary = {17: true, 18: true, 53: true, 120: true, -3: true}
	tanah.bangun(Config.LAYAR_LEBAR_MAKS_PX, Config.LAYAR_TINGGI_DASAR_PX)
	tanah.atur_baris_masuk(masuk)
	var nama_wadah: Array[String] = []
	for wadah: Node in tanah.get_children():
		nama_wadah.append(String(wadah.name))
	check(nama_wadah == ["RumputSeberang", "TrotoarSeberang", "AspalSeberang", "AspalDekat", "TrotoarDekat", "RumputDekat", "RumputLuar", "RumputLuar2", "RumputLuar3", "MasukTrotoarSeberang", "MasukRumputSeberang", "SimbolTrotoarSeberang", "SimbolTrotoarDekat", "UjungTrotoarSeberang", "UjungRumputSeberang"], "lima belas wadah: tujuh lama + enam wadah 5B + dua ujung kerb 5C (jumlah wadah naik tepat sebanyak tekstur baru): %s" % [nama_wadah])
	# Sel, posisi, dan jumlah sprite sama dengan sebelum run untuk lima lebar (selisih 0).
	var sama_semua: bool = true
	for lebar: int in [640, 667, 780, 800, Config.LAYAR_LEBAR_MAKS_PX]:
		var lama: TanahDaur = _buat_tanah(false)
		lama.bangun(lebar, TINGGI)
		tanah.bangun(lebar, TINGGI)
		tanah.atur_baris_masuk(masuk)
		var harapan: int = JalanDaur.sel_tanah(lebar, TINGGI).size()
		var posisi_lama: Dictionary = {}
		for u: Sprite2D in _sprite_ubin(lama):
			posisi_lama[u.position] = true
		var posisi_baru: Dictionary = {}
		for u: Sprite2D in _sprite_ubin(tanah):
			posisi_baru[u.position] = true
		check(_sprite_ubin(tanah).size() == harapan and _sprite_ubin(lama).size() == harapan, "lebar %d: %d sprite ubin di mode khusus dan tanpa khusus = sel_tanah (%d)" % [lebar, _sprite_ubin(tanah).size(), harapan])
		if posisi_lama != posisi_baru:
			sama_semua = false
		lama.free()
	check(sama_semua, "posisi semua sprite ubin sama dengan sebelum run (lima lebar)")
	tanah.bangun(Config.LAYAR_LEBAR_MAKS_PX, Config.LAYAR_TINGGI_DASAR_PX)
	tanah.atur_baris_masuk(masuk)
	var node_awal: int = _hitung_node(tanah)
	var total_salah: int = 0
	var total_cek: int = 0
	var contoh: String = ""
	var terlihat_masuk: int = 0
	# Banyak jarak, naik dan turun (tanpa bangun ulang): tiap lantai jarak baru menerapkan ulang tekstur, tanpa node baru.
	for jarak: float in [0.0, 0.4, 1.0, 7.99, 8.0, 13.7, 14.0, 15.3, 16.0, 17.0, 50.2, 99.99, 100.0, 237.31, 3.0, -2.5, 0.0, 118.5]:
		tanah.perbarui(jarak)
		var hasil: Array = _periksa_tanah(tanah, jarak, masuk)
		total_salah += hasil[0] as int
		total_cek += hasil[1] as int
		if contoh.is_empty() and (hasil[0] as int) > 0:
			contoh = "jarak %s: %s" % [jarak, hasil[2]]
		var per_nama: Dictionary = hasil[3]
		terlihat_masuk += int(per_nama.get(N_MASUK_TROTOAR, 0))
	check(total_cek > 5000 and total_salah == 0, "tiap sprite ubin memakai tekstur harapan oracle di 18 jarak (naik dan turun): %d salah dari %d (%s)" % [total_salah, total_cek, contoh])
	check(terlihat_masuk > 0, "ubin masuk terlihat di sebagian jarak (%d pengamatan)" % terlihat_masuk)
	check(_hitung_node(tanah) == node_awal, "jumlah node tidak berubah sesudah banyak langkah (tanpa node baru, sprite hanya pindah wadah): %d" % node_awal)
	# Satu wadah satu tekstur dan tekstur wadah baru sesuai.
	for wadah: Node in tanah.get_children():
		var tekstur_wadah: Dictionary = {}
		for anak: Node in wadah.get_children():
			tekstur_wadah[(anak as Sprite2D).texture.resource_path] = true
		check(tekstur_wadah.size() <= 1, "wadah %s memuat paling banyak satu tekstur (gambar tergabung per tekstur, tidak pecah per ubin)" % wadah.name)
	for i: int in range(WADAH_BARU.size()):
		var wadah: Node = tanah.get_node(WADAH_BARU[i])
		for anak: Node in wadah.get_children():
			check((anak as Sprite2D).texture.resource_path == FOLDER_UBIN + "tile_perumahan_%s.png" % TEKSTUR_WADAH_BARU[i], "isi wadah %s = tekstur %s" % [WADAH_BARU[i], TEKSTUR_WADAH_BARU[i]])
			break
	# Satu tanah, rumput luar: ketiga varian muncul.
	tanah.perbarui(0.0)
	var per: Dictionary = (_periksa_tanah(tanah, 0.0, masuk)[3]) as Dictionary
	check(per.has(N_RUMPUT_1) and per.has(N_RUMPUT_2) and per.has(N_RUMPUT_3) and int(per[N_RUMPUT_1]) > int(per[N_RUMPUT_2]) + int(per[N_RUMPUT_3]), "rumput luar: ketiga varian muncul dan rumput_1 dominan: %s" % [per])
	# Mengatur ulang baris masuk menerapkan ulang tanpa perubahan jarak.
	tanah.atur_baris_masuk({})
	check(int((_periksa_tanah(tanah, 0.0, {})[3] as Dictionary).get(N_MASUK_TROTOAR, 0)) == 0, "atur_baris_masuk({}) menghapus semua ubin masuk")
	tanah.atur_baris_masuk({2: true})
	var hasil_baru: Array = _periksa_tanah(tanah, 0.0, {2: true})
	check((hasil_baru[0] as int) == 0 and int((hasil_baru[3] as Dictionary).get(N_MASUK_TROTOAR, 0)) == 1 and int((hasil_baru[3] as Dictionary).get(N_MASUK_RUMPUT, 0)) == 1, "satu baris masuk = tepat satu ubin trotoar masuk dan satu rumput masuk (kolom pertama seberang), %s" % [hasil_baru[3]])
	tanah.free()


func _test_tanah_tanpa_khusus_tetap() -> void:
	_judul.call("Ubin khusus: tanpa tekstur khusus perilaku TanahDaur tidak berubah (AC-15)")
	var tanah: TanahDaur = _buat_tanah(false)
	tanah.bangun(Config.LAYAR_LEBAR_MAKS_PX, Config.LAYAR_TINGGI_DASAR_PX)
	tanah.atur_baris_masuk({17: true})
	tanah.perbarui(14.2)
	var nama: Array[String] = []
	for wadah: Node in tanah.get_children():
		nama.append(String(wadah.name))
	check(not tanah.mode_khusus() and nama == ["RumputSeberang", "TrotoarSeberang", "AspalSeberang", "AspalDekat", "TrotoarDekat", "RumputDekat", "RumputLuar"], "tanpa tekstur khusus: tujuh wadah lama, mode khusus mati (%s)" % [nama])
	var per_nama: Dictionary = {}
	for u: Sprite2D in _sprite_ubin(tanah):
		per_nama[u.texture.resource_path.get_file()] = true
	check(per_nama.size() == 7, "tujuh tekstur lama saja (tanpa masuk, simbol, atau variasi): %s" % [per_nama.keys()])
	tanah.free()
	var tiga: TanahDaur = TanahDaur.new()
	tiga.tekstur_aspal = load("res://assets/sprites/_placeholder/tile_graybox_aspal.png") as Texture2D
	tiga.tekstur_trotoar = load("res://assets/sprites/_placeholder/tile_graybox_trotoar.png") as Texture2D
	tiga.tekstur_rumput = load("res://assets/sprites/_placeholder/tile_graybox_rumput.png") as Texture2D
	tiga.bangun(Config.LAYAR_LEBAR_MAKS_PX, Config.LAYAR_TINGGI_DASAR_PX)
	tiga.atur_baris_masuk({17: true})
	tiga.perbarui(14.2)
	check(not tiga.mode_khusus() and tiga.get_child_count() == 3, "mode graybox (jalan uji, spike, graybox) tetap tiga wadah dan tanpa mode khusus")
	tiga.free()


func _test_scene_rute() -> void:
	_judul.call("Ubin khusus: scene rute memasang ubin masuk di bawah mobil seberang, simbol, variasi, dan Main lagi (AC-15)")
	_tree.root.size = Vector2i(2340, 1080)
	var akar: Node = (load(BERKAS_RUTE) as PackedScene).instantiate()
	_tree.root.add_child(akar)
	await _tree.process_frame
	await _tree.process_frame
	var tanah: TanahDaur = akar.find_child("Tanah", true, false) as TanahDaur
	check(tanah != null and tanah.mode_khusus() and tanah.mode_ujung(), "Tanah di rute.tscn memakai mode khusus dan ujung kerb")
	if tanah == null:
		_tree.root.remove_child(akar)
		akar.free()
		return
	var sprite: Array[Sprite2D] = _sprite_ubin(tanah)
	check(sprite.size() == JalanDaur.sel_tanah(Config.LAYAR_LEBAR_MAKS_PX, Config.LAYAR_TINGGI_DASAR_PX).size(), "scene rute: jumlah sprite ubin tetap = sel_tanah lebar maksimal (%d)" % sprite.size())
	check(tanah.get_child_count() == 49, "scene rute: 49 wadah ubin (7 lama + 6 run 5B + 2 ujung kerb + 18 simpang dekat + 16 simpang seberang run 5C), dapat %d" % tanah.get_child_count())
	# Cari seed yang rutenya punya mobil garasi seberang, lalu susun rute itu di scene.
	var kumpulan: PemuatRute.Kumpulan = PemuatRute.muat_folder()
	var benih: int = -1
	for i: int in range(60):
		var hasil: RouteBuilder.Hasil = RouteBuilder.bangun(20261016 + 7 * i, kumpulan.segmen)
		if hasil.rute != null and not UbinKhusus.himpunan_baris_masuk(hasil.rute.objek).is_empty():
			benih = 20261016 + 7 * i
			break
	check(benih > 0, "ada seed dengan mobil garasi seberang untuk uji scene")
	akar.call("_susun", benih)
	var rute: RouteBuilder.Rute = akar.get("_rute") as RouteBuilder.Rute
	var pita: Dictionary = _pita_dekat(rute)
	var mobil: Array[float] = []
	for o: RouteBuilder.ObjekRute in rute.objek:
		if o.jenis == "mobil_garasi" and o.jalur == "seberang":
			mobil.append(o.maju_ubin)
	check(not mobil.is_empty(), "rute uji memuat mobil garasi seberang (%d)" % mobil.size())
	var masuk: Dictionary = {}
	for maju: float in mobil:
		masuk[int(ceil(maju - 0.5))] = true
	for maju: float in mobil:
		# Sepeda 4 ubin di belakang mobil: baris masuk terlihat.
		tanah.perbarui(maju - 4.0)
		var hasil: Array = _periksa_tanah(tanah, maju - 4.0, masuk, pita)
		check(hasil[0] == 0, "scene rute, mobil di maju %s: semua ubin sesuai oracle (%s)" % [maju, hasil[2]])
		var per_nama: Dictionary = hasil[3]
		check(int(per_nama.get(N_MASUK_TROTOAR, 0)) >= 1 and int(per_nama.get(N_MASUK_RUMPUT, 0)) >= 1, "scene rute, mobil di maju %s: ubin masuk trotoar dan rumput terpasang (%s)" % [maju, per_nama])
		# Ubin masuk tepat di baris mobil: pusat ubin masuk di baris = maju mobil (mobil berdiri di atas ubin masuk), tidak di baris lain.
		var baris_lain: int = 0
		var baris_ok: int = 0
		for wadah_nama: String in ["MasukTrotoarSeberang", "MasukRumputSeberang"]:
			for anak: Node in tanah.get_node(wadah_nama).get_children():
				var d: Vector2 = _dunia_dari_layar((anak as Sprite2D).position)
				var baris: int = int(round(-d.y)) + int(floor(maju - 4.0))
				if absf(float(baris) - maju) < 0.01:
					baris_ok += 1
				else:
					baris_lain += 1
		check(baris_ok == 2 and baris_lain <= 2 * mobil.size(), "scene rute, mobil di maju %s: dua ubin masuk (trotoar dan rumput) tepat di barisnya (ubin masuk di baris lain hanya milik mobil lain)" % maju)
		# Garis pandang: bentuk parkir mobil (lateral -4,0 .. -2,5) berada di atas kolom trotoar dan rumput: pusat -1,5 dan -2,5 punya ubin masuk, -0,5 tidak.
		var kolom_masuk: Dictionary = {}
		for wadah_nama: String in ["MasukTrotoarSeberang", "MasukRumputSeberang"]:
			for anak: Node in tanah.get_node(wadah_nama).get_children():
				var d: Vector2 = _dunia_dari_layar((anak as Sprite2D).position)
				if absf(float(int(round(-d.y)) + int(floor(maju - 4.0))) - maju) < 0.01:
					kolom_masuk[d.x] = true
		check(kolom_masuk.has(-1.5) and kolom_masuk.has(-2.5) and kolom_masuk.size() == 2, "ubin masuk mobil di kolom trotoar (-1,5) dan rumput pertama (-2,5) seberang: %s" % [kolom_masuk.keys()])
	# "Main lagi": rute baru, baris masuk diatur ulang.
	akar.call("main_lagi")
	var rute2: RouteBuilder.Rute = akar.get("_rute") as RouteBuilder.Rute
	var masuk2: Dictionary = {}
	for o: RouteBuilder.ObjekRute in rute2.objek:
		if o.jenis == "mobil_garasi" and o.jalur == "seberang":
			masuk2[int(ceil(o.maju_ubin - 0.5))] = true
	tanah.perbarui(0.0)
	var hasil2: Array = _periksa_tanah(tanah, 0.0, masuk2, _pita_dekat(rute2))
	check(rute2 != rute and hasil2[0] == 0, "sesudah Main lagi: ubin sesuai baris masuk rute baru (%s)" % hasil2[2])
	_tree.root.remove_child(akar)
	akar.free()


## Baris pita simpang sisi dekat rute (`pos` - 1 sampai `pos` + 3, literal D-3 run 5C), untuk `_periksa_tanah`.
func _pita_dekat(rute: RouteBuilder.Rute) -> Dictionary:
	var hasil: Dictionary = {}
	for item: RouteBuilder.SimpangItem in rute.simpang:
		if item.sisi == LoperAnim.Sisi.DEKAT:
			for b: int in range(int(item.maju_ubin) - 1, int(item.maju_ubin) + 4):
				hasil[b] = true
	return hasil


# --- AC-16: tanpa celah dan tanpa pita ---

func _test_tanpa_celah() -> void:
	_judul.call("Ubin khusus: tanpa celah transparan di seluruh viewport dengan semua tekstur baru (AC-16)")
	var tanah: TanahDaur = _buat_tanah(true)
	var lateral: Array[float] = [-BikeMotion.batas_lateral_ubin(), -2.0, 0.0, 1.0, 2.0, BikeMotion.batas_lateral_ubin()]
	var jarak: Array[float] = [0.0, 13.0, 99.99, 237.31]
	var total: int = 0
	var celah_total: int = 0
	var contoh: String = ""
	var khusus_terlihat: int = 0
	for lebar: int in [640, 667, 780, 800, Config.LAYAR_LEBAR_MAKS_PX]:
		tanah.bangun(lebar, TINGGI)
		for jarak_ubin: float in jarak:
			var lantai: int = int(floor(jarak_ubin))
			# Baris masuk dekat sepeda (di depan, di belakang, dan jauh) supaya ubin masuk ada di layar; simbol datang dari baris 6 + 12 k.
			tanah.atur_baris_masuk({lantai + 1: true, lantai + 5: true, lantai + 9: true, lantai - 2: true, lantai + 14: true})
			tanah.perbarui(jarak_ubin)
			for ubin: Sprite2D in _sprite_ubin(tanah):
				var jalur: String = ubin.texture.resource_path
				if jalur.ends_with("_masuk.png") or jalur.ends_with("_ujung.png") or jalur.ends_with("_simbol.png") or jalur.ends_with("rumput_2.png") or jalur.ends_with("rumput_3.png"):
					khusus_terlihat += 1
			for lat: float in lateral:
				var layar_sepeda: Vector2 = Vector2((lat + jarak_ubin) * 32.0, (lat - jarak_ubin) * 16.0)
				for dorong: Vector2 in [Vector2.ZERO, Vector2(Config.DORONGAN_MAJU_PX, -Config.DORONGAN_MAJU_PX / 2.0)]:
					var asal: Vector2i = Vector2i((layar_sepeda - dorong - Vector2(lebar * Config.KAMERA_SEPEDA_X_PECAHAN, TINGGI * Config.KAMERA_SEPEDA_Y_PECAHAN)).round())
					var kanvas: Image = _susun(tanah, asal, Vector2i(lebar, TINGGI))
					var data: PackedByteArray = kanvas.get_data()
					var celah: int = 0
					for i: int in range(3, data.size(), 4):
						if data[i] != 255:
							celah += 1
					total += 1
					celah_total += celah
					if celah > 0 and contoh.is_empty():
						contoh = "lebar %d jarak %s lateral %s dorong %s: %d piksel" % [lebar, jarak_ubin, lat, dorong, celah]
	check(total == 5 * 4 * 6 * 2 and celah_total == 0, "nol piksel transparan di %d viewport (5 lebar, 4 jarak, lateral -2 .. +2, tanpa dan dengan dorongan maju terbesar), ubin masuk, simbol, dan variasi terpasang: %s" % [total, contoh])
	check(khusus_terlihat > 1000, "ubin khusus benar-benar tampil di viewport yang diuji (%d sprite)" % khusus_terlihat)
	tanah.free()


func _test_tanpa_pita() -> void:
	_judul.call("Ubin khusus: rumput_2 dan rumput_3 menyambung ke rumput_1 tanpa pita atau tepi (AC-16)")
	var polos: Image = _gambar_tekstur(_tekstur(N_RUMPUT_1))
	var tepi: Image = _gambar_tekstur(_tekstur(N_RUMPUT_SEBERANG))
	for nama: String in [N_RUMPUT_2, N_RUMPUT_3]:
		var g: Image = _gambar_tekstur(_tekstur(nama))
		check(g.get_width() == 64 and g.get_height() == 32, "%s 64x32" % nama)
		var opak: int = 0
		for y: int in range(32):
			for x: int in range(64):
				if g.get_pixel(x, y).a > 0.999:
					opak += 1
		check(opak == 1024, "%s: belah ketupat 1.024 piksel opak (dapat %d)" % [nama, opak])
		check(g.get_data() != polos.get_data(), "%s beda dari rumput_1 (variasi)" % nama)
		# Warna cincin tepi: hanya warna yang ada di rumput_1 (tanpa warna garis tepi kerb yang ada di rumput_seberang).
		var warna_polos: Dictionary = {}
		var warna_tepi_kerb: Dictionary = {}
		var warna_g: Dictionary = {}
		for y: int in range(32):
			for x: int in range(64):
				if polos.get_pixel(x, y).a > 0.999:
					warna_polos[polos.get_pixel(x, y).to_html(false)] = true
				if tepi.get_pixel(x, y).a > 0.999:
					warna_tepi_kerb[tepi.get_pixel(x, y).to_html(false)] = true
				if g.get_pixel(x, y).a > 0.999:
					warna_g[g.get_pixel(x, y).to_html(false)] = true
		var asing: Array[String] = []
		for warna: String in warna_g:
			if not warna_polos.has(warna):
				asing.append(warna)
		var kerb_saja: Array[String] = []
		for warna: String in asing:
			if warna_tepi_kerb.has(warna) and not warna_polos.has(warna):
				kerb_saja.append(warna)
		check(kerb_saja.is_empty(), "%s tidak memuat warna tepi kerb rumput_seberang yang bukan warna rumput polos: %s" % [nama, kerb_saja])
	# Tanah dengan variasi: periodik per ubin ke dua arah di antara ubin yang SAMA (jenis sama dan bersebelahan = piksel identik di sambungan).
	var tanah: TanahDaur = _buat_tanah(true)
	tanah.bangun(Config.LAYAR_LEBAR_MAKS_PX, TINGGI)
	tanah.perbarui(0.0)
	var lebar: int = Config.LAYAR_LEBAR_MAKS_PX
	var asal: Vector2i = Vector2i(-lebar / 3, -270)
	var kanvas: Image = _susun(tanah, asal, Vector2i(lebar, TINGGI))
	var diperiksa: int = 0
	var beda: int = 0
	# Wilayah rumput luar: untuk tiap piksel, ubin pemiliknya (dari letak dunia) dan ubin di (+32, +16) atau (-32, +16): bila keduanya ubin yang sama jenisnya, piksel harus sama.
	var jenis_ubin: Dictionary = {}
	for u: Sprite2D in _sprite_ubin(tanah):
		var d: Vector2 = _dunia_dari_layar(u.position)
		jenis_ubin[Vector2i(int(floor(d.x)), int(round(-d.y)))] = u.texture.resource_path
	for geser: Vector2i in [Vector2i(32, 16), Vector2i(-32, 16)]:
		for y: int in range(0, TINGGI - 16):
			for x: int in range(maxi(0, -geser.x), lebar - maxi(0, geser.x)):
				var sx: float = x + 0.5 + asal.x
				var sy: float = y + 0.5 + asal.y
				var gx: float = (sy / 16.0 + sx / 32.0) / 2.0
				var gy: float = (sy / 16.0 - sx / 32.0) / 2.0
				var gx2: float = ((sy + geser.y) / 16.0 + (sx + geser.x) / 32.0) / 2.0
				var gy2: float = ((sy + geser.y) / 16.0 - (sx + geser.x) / 32.0) / 2.0
				if not ((gx <= -3.01 and gx2 <= -3.01) or (gx >= 3.01 and gx2 >= 3.01)):
					continue
				var k1: Vector2i = Vector2i(int(floor(gx)), int(round(-gy)))
				var k2: Vector2i = Vector2i(int(floor(gx2)), int(round(-gy2)))
				if not jenis_ubin.has(k1) or not jenis_ubin.has(k2) or jenis_ubin[k1] != jenis_ubin[k2]:
					continue
				diperiksa += 1
				if kanvas.get_pixel(x, y) != kanvas.get_pixel(x + geser.x, y + geser.y):
					beda += 1
	check(diperiksa > 10000, "wilayah rumput luar dengan pasangan ubin sama cukup luas diperiksa (%d piksel)" % diperiksa)
	check(beda == 0, "ubin rumput yang sama bersebelahan: piksel sambungan sama di dua arah (%d beda dari %d)" % [beda, diperiksa])
	tanah.free()


func _test_susunan_referensi() -> void:
	_judul.call("Ubin khusus: susunan Godot piksel-identik dengan referensi Python (masuk, simbol, rumput_2 dan _3; AC-16)")
	var tanah: TanahDaur = _buat_tanah(true)
	tanah.bangun(Config.LAYAR_LEBAR_MAKS_PX, Config.LAYAR_TINGGI_DASAR_PX)
	tanah.atur_baris_masuk({4: true})
	tanah.perbarui(0.0)
	var ref: Image = Image.load_from_file(ProjectSettings.globalize_path(REFERENSI))
	check(ref != null and not ref.is_empty(), "berkas referensi tests/data/ubin_potongan_5b.png terbaca")
	if ref == null or ref.is_empty():
		tanah.free()
		return
	ref.convert(Image.FORMAT_RGBA8)
	var terpilih: Array[Sprite2D] = []
	for u: Sprite2D in _sprite_ubin(tanah):
		var d: Vector2 = _dunia_dari_layar(u.position)
		if absf(d.x) < 4.0 and d.y <= 0.001 and d.y >= -7.001:
			terpilih.append(u)
	check(terpilih.size() == 64, "ada 64 ubin (8 kolom x 8 ubin maju) di potongan, dapat %d" % terpilih.size())
	var x_min: int = 1 << 30
	var y_min: int = 1 << 30
	var khusus: int = 0
	for u: Sprite2D in terpilih:
		x_min = mini(x_min, int(u.position.x) - 32)
		y_min = mini(y_min, int(u.position.y) - 16)
		var f: String = u.texture.resource_path.get_file()
		if f.ends_with("_masuk.png") or f.ends_with("_ujung.png") or f.ends_with("_simbol.png") or f.ends_with("rumput_2.png") or f.ends_with("rumput_3.png"):
			khusus += 1
	check(khusus == 11, "potongan memuat 11 ubin khusus (2 masuk, 2 ujung kerb run 5C, 2 simbol, 5 rumput_2/3), dapat %d" % khusus)
	var kanvas: Image = Image.create(ref.get_width(), ref.get_height(), false, Image.FORMAT_RGBA8)
	kanvas.fill(Color(0, 0, 0, 0))
	for u: Sprite2D in terpilih:
		var g: Image = _gambar_tekstur(u.texture)
		kanvas.blend_rect(g, Rect2i(Vector2i.ZERO, g.get_size()), Vector2i(int(u.position.x) - 32 - x_min, int(u.position.y) - 16 - y_min))
	check(kanvas.get_size() == ref.get_size(), "ukuran susunan = referensi (%s)" % [ref.get_size()])
	check(kanvas.get_data() == ref.get_data(), "susunan TanahDaur 8 ubin maju dengan baris masuk 4 piksel-identik dengan referensi Python (komposisi berkas assets/)")
	tanah.free()


# --- AC-18 (bagian ubin): pemindai rujukan, dan scene dev tidak berubah ---

func _test_pemindai_dan_scene_dev() -> void:
	_judul.call("Ubin khusus: scene dev tidak berubah dan tidak ada rujukan ke aspal_N atau *_dekat_masuk (AC-15, AC-18)")
	for berkas: String in ["res://scenes/dev/jalan_uji.tscn", "res://scenes/dev/graybox.tscn", "res://scenes/dev/spike_sisi_dekat.tscn"]:
		var teks: String = FileAccess.get_file_as_string(berkas)
		check(not teks.contains("tekstur_masuk") and not teks.contains("tekstur_simbol") and not teks.contains("rumput_luar_2") and not teks.contains("tile_perumahan"), "%s tidak memakai ubin khusus (scene dev tidak disentuh)" % berkas.get_file())
	check(not FileAccess.get_file_as_string("res://scripts/dev/cek_render.gd").contains("UbinKhusus"), "cek_render tidak memakai ubin khusus")
	var rute: String = FileAccess.get_file_as_string(BERKAS_RUTE)
	for nama: String in [N_RUMPUT_2, N_RUMPUT_3, N_MASUK_TROTOAR, N_MASUK_RUMPUT, N_SIMBOL_SEBERANG, N_SIMBOL_DEKAT]:
		check(rute.contains("tile_perumahan_%s.png" % nama), "rute.tscn memuat tekstur %s" % nama)
	var tanah: String = FileAccess.get_file_as_string("res://scripts/entities/tanah_daur.gd")
	check(not tanah.contains("func _draw") and not tanah.contains("load(") and not tanah.contains("preload("), "TanahDaur tidak memuat tekstur dan tidak menggambar sendiri (tekstur dari @export, dipegang node, bukan di _draw)")
	var folder: Array[String] = ["res://scripts", "res://scenes", "res://assets/data", "res://translations"]
	var berkas_sumber: Array[String] = []
	for akar: String in folder:
		_kumpulkan(akar, berkas_sumber)
	var temuan: Array[String] = []
	for jalur: String in berkas_sumber:
		var teks: String = FileAccess.get_file_as_string(jalur)
		for kata: String in TERLARANG_UBIN:
			if teks.contains(kata):
				temuan.append("%s memuat %s" % [jalur, kata])
	check(temuan.is_empty(), "tidak ada rujukan ke aspal_N atau *_dekat_masuk: %s" % [temuan])


func _kumpulkan(folder: String, hasil: Array[String]) -> void:
	for nama: String in DirAccess.get_files_at(folder):
		if nama.ends_with(".gd") or nama.ends_with(".tscn") or nama.ends_with(".tres") or nama.ends_with(".json") or nama.ends_with(".csv") or nama.ends_with(".cfg"):
			hasil.append(folder + "/" + nama)
	for sub: String in DirAccess.get_directories_at(folder):
		_kumpulkan(folder + "/" + sub, hasil)
