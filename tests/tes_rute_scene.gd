class_name TesRuteScene
extends RefCounted
## Tes scene rute run fase3a-rute bagian B (AC-10 sampai AC-16): `scenes/rute/rute.tscn` sungguhan, event sentuh sintetis lewat
## `Input.parse_input_event` (pola `tests/tes_bantu_scene.gd`), langkah `perbarui(dt)` dengan dt tetap. Bagian murni (jendela daur, akhir
## rute, medan, nama sprite) dites tanpa scene di `_test_murni`.
## Harapan ditulis sebagai literal atau dihitung tes dengan cara lain dari kode produksi (QA-008 run 2A, QA-001 run 2B):
## - Rute seed bawaan: id segmen, panjang, jumlah rumah, id dan jarak pelanggan pertama, ke-9, dan terakhir ditulis literal (nilai dari
##   `RouteBuilder` sendiri sudah diuji literal di `tes_rute.gd`; di sini dijaga bahwa scene memakainya).
## - Rumah digambar: jendela [maju - 20, maju + 30] dipindai linear (bukan pencarian biner `JendelaRute`), nama tekstur, titik pijak dari
##   JSON aset yang dibaca tes, dan letak layar dari rumus proyeksi iso 2:1 ditulis ulang (tapak seberang tengah x -4,5, dekat +4,5; maju
##   awal kavling + 1,0), kotak surat sasaran di halaman: x -2,125 dan maju awal kavling + 1,75.
## - Zona: koordinat zona rumah tertentu literal (kotak surat seberang di halaman, x -2,75 sampai -1,75, maju pos + 1,25 sampai 2,5), dan
##   titik yang di jalan uji kotak surat tetapi di rute meleset.
## - Mode bantu: kisi keadaan (tiga kecepatan, beberapa pelanggan dan jarak) lawan `BantuLempar.pilih` yang dipanggil tes dengan daftar
##   zona SELURUH rute (bukan jendela).

const BERKAS_RUTE: String = "res://scenes/rute/rute.tscn"
const FOLDER_RUMAH: String = "res://assets/sprites/houses/perumahan"
const SKALA: int = 3
const DT: float = 1.0 / 60.0
const TITIK_STICK: Vector2 = Vector2(100, 260)
## Seed bawaan rute dev dan berikutnya (ditulis literal, `Config.RUTE_SEED_DEV` = 20261016).
const SEED_DEV: int = 20261016
const SEED_BERIKUT: int = 20261017
const ID_SEGMEN_DEV: Array[String] = ["per_buka_01", "per_tengah_04", "per_tengah_03", "per_tengah_05", "per_tengah_01", "per_tengah_02", "per_tutup_02"]
const ID_SEGMEN_BERIKUT: Array[String] = ["per_buka_01", "per_tengah_05", "per_tengah_03", "per_tengah_02", "per_tengah_01", "per_tengah_04", "per_tutup_02"]
const PANJANG_RUTE: float = 236.0
const JUMLAH_RUMAH: int = 89
const JEDA_LEPAS_HARAPAN: float = 2.0 / 12.0
const LEBAR: float = 780.0
const TOL: float = 0.000001
## Jendela daur yang diharapkan (ubin): [belakang, depan] sepeda. Sama dengan `Config.RUTE_DAUR_*`, ditulis ulang.
const DAUR_MUNDUR: float = 20.0
const DAUR_MAJU: float = 30.0

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
	_test_murni()
	await _test_rute_dari_data()
	await _test_rumah_digambar()
	await _test_jendela_daur_bergerak()
	await _test_tanpa_area_kotak()
	await _test_zona_dari_data()
	await _test_koran_tanpa_isi_ulang()
	for v: float in [Config.KECEPATAN_SANTAI_UD, Config.KECEPATAN_CEPAT_UD, Config.KECEPATAN_NGEBUT_UD]:
		await _test_bantu_kisi(v)
	await _test_swipe_dinilai_zona_rute()
	await _test_garis_bidik_titik_redup()
	await _test_akhir_rute()
	await _test_akhir_koran_terbang_dinilai()
	await _test_main_lagi()
	await _test_main_lagi_ketuk()
	await _test_galat_muat_terlihat()
	await _test_tekstur_dimuat_di_atur_rute()
	await _test_jeda()
	await _test_penutup()
	for kasus: Array in [[1920, 1080, 640], [2340, 1080, 780], [2400, 1080, 800]]:
		await _test_tata_letak_akhir(kasus)


# --- Pembantu ---

func _siapkan(jendela: Vector2i = Vector2i(2340, 1080)) -> RuteMain:
	_tree.root.size = jendela
	var akar: RuteMain = (load(BERKAS_RUTE) as PackedScene).instantiate() as RuteMain
	_tree.root.add_child(akar)
	await _tree.process_frame
	await _tree.process_frame
	akar.set_process(false)
	(_anak(akar, "KontrolTouch") as KontrolTouch).keyboard_aktif = false
	_sprite(akar)
	return akar


func _bersihkan(akar: RuteMain) -> void:
	_lepas_semua_jari()
	if akar.sedang_jeda():
		akar.minta_lanjut()
	(_anak(akar, "KontrolTouch") as KontrolTouch).keyboard_aktif = OS.has_feature("editor")
	_tree.root.remove_child(akar)
	akar.free()


func _anak(akar: Node, nama: String) -> Node:
	return akar.find_child(nama, true, false)


func _sprite(akar: RuteMain) -> LoperSprite:
	var sprite: LoperSprite = _anak(akar, "LoperAgen") as LoperSprite
	sprite.set_process(false)
	return sprite


func _sepeda(akar: RuteMain) -> SepedaUji:
	return _anak(akar, "Sepeda") as SepedaUji


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


func _lepas_semua_jari() -> void:
	for i: int in range(8):
		_sentuh(i, Vector2(-50, -50), false)


func _tap(posisi: Vector2, index: int = 1) -> void:
	_sentuh(index, posisi, true)
	_sentuh(index, posisi, false)


func _langkah(akar: RuteMain, jumlah: int, dt: float = DT) -> void:
	var sprite: LoperSprite = _sprite(akar)
	for i: int in range(jumlah):
		akar.perbarui(dt)
		sprite.maju(dt)


func _catat(akar: RuteMain) -> Dictionary:
	var catatan: Dictionary = {"lempar": [], "mendarat": [], "tanpa": [], "selesai": 0, "disusun": 0}
	akar.koran_dilempar.connect(func(l: ThrowSolver.Lintasan) -> void: (catatan["lempar"] as Array).append(l))
	akar.koran_mendarat.connect(func(k: KoranLempar.Koran) -> void: (catatan["mendarat"] as Array).append(k))
	akar.bantu_tanpa_sasaran.connect(func(p: Vector2) -> void: (catatan["tanpa"] as Array).append(p))
	akar.rute_selesai.connect(func() -> void: catatan["selesai"] = int(catatan["selesai"]) + 1)
	akar.rute_disusun.connect(func(_r: RouteBuilder.Rute) -> void: catatan["disusun"] = int(catatan["disusun"]) + 1)
	return catatan


## Mode bantu dinyalakan lewat sakelar layar jeda (O-6 run fase3c-hud-hasil; HUD rute tidak punya tombol dev).
func _nyalakan_bantu(akar: RuteMain) -> void:
	if not akar.mode_bantu():
		(_anak(akar, "LayarJeda") as LayarJeda).sakelar_bantu().ditekan.emit()


## Langkah sampai layar hasil terbuka (paling banyak `maks` langkah). True bila terbuka.
func _sampai_hasil(akar: RuteMain, maks: int = 600) -> bool:
	for i: int in range(maks):
		if akar.hasil_tampil():
			return true
		_langkah(akar, 1)
	return akar.hasil_tampil()


## Rute oracle: dimuat dan disusun tes sendiri dari folder segmen (tanpa jalur scene).
func _rute_oracle(benih: int) -> RouteBuilder.Rute:
	var kumpulan: PemuatRute.Kumpulan = PemuatRute.muat_folder()
	var hasil: RouteBuilder.Hasil = RouteBuilder.bangun(benih, kumpulan.segmen)
	return hasil.rute


## Indeks rumah dalam jendela daur, dipindai linear (oracle independen dari pencarian biner `JendelaRute`).
func _indeks_harapan(rute: RouteBuilder.Rute, jarak: float) -> Array[int]:
	var hasil: Array[int] = []
	for i: int in range(rute.rumah.size()):
		var m: float = rute.rumah[i].maju_ubin
		if m >= jarak - DAUR_MUNDUR and m <= jarak + DAUR_MAJU:
			hasil.append(i)
	return hasil


func _taruh_sepeda(akar: RuteMain, v: float, lateral: float, lateral_ud: float, maju: float) -> void:
	var sepeda: SepedaUji = _sepeda(akar)
	var k: BikeMotion.Keadaan = sepeda.keadaan.salin()
	k.kecepatan_ud = v
	k.lateral_ubin = lateral
	sepeda.keadaan = k
	sepeda.jarak_ubin = maju
	akar.perbarui(0.0)
	sepeda.lateral_ud = lateral_ud
	akar.koran = SisaKoran.awal(30)


func _dekat(a: Vector2, b: Vector2, tol: float = TOL) -> bool:
	return absf(a.x - b.x) <= tol and absf(a.y - b.y) <= tol


## Posisi gambar (piksel game) titik dunia (lateral, maju) di tanah: proyeksi iso 2:1 ditulis ulang, dibulatkan.
func _layar(lateral: float, maju: float) -> Vector2:
	return Vector2(roundf((lateral + maju) * 32.0), roundf((lateral - maju) * 16.0))


func _tap_seberang(akar: RuteMain) -> Vector2:
	return akar.posisi_layar_sepeda() + Vector2(200, -150)


func _sisi_harapan(tap: Vector2, sepeda: Vector2) -> LoperAnim.Sisi:
	var d: float = (tap.y - sepeda.y) + (tap.x - sepeda.x) / 2.0
	return LoperAnim.Sisi.SEBERANG if d < 0.0 else LoperAnim.Sisi.DEKAT


func _sampai_mendarat(akar: RuteMain, catatan: Dictionary, lintasan: ThrowSolver.Lintasan) -> KoranLempar.Koran:
	for i: int in range(roundi(2.5 / DT)):
		_langkah(akar, 1)
		for k: KoranLempar.Koran in catatan["mendarat"]:
			if k.lintasan == lintasan:
				return k
	return null


# --- Bagian murni ---

func _test_murni() -> void:
	_judul.call("Rute scene: jendela daur, akhir rute, medan sasaran, dan nama sprite (murni)")
	var daftar: Array[RouteBuilder.RumahRute] = []
	for m: int in [0, 2, 4, 6, 8, 10]:
		var r: RouteBuilder.RumahRute = RouteBuilder.RumahRute.new()
		r.maju_ubin = float(m)
		daftar.append(r)
	check(JendelaRute.rentang(daftar, 2.0, 8.0) == Vector2i(1, 5), "jendela [2, 8] = indeks 1 sampai 4 (kedua ujung inklusif)")
	check(JendelaRute.rentang(daftar, 2.5, 7.9) == Vector2i(2, 4), "jendela [2,5; 7,9] = indeks 2 dan 3")
	check(JendelaRute.rentang(daftar, 4.0, 4.0) == Vector2i(2, 3), "jendela [4, 4] = satu rumah")
	check(JendelaRute.rentang(daftar, 3.0, 3.0) == Vector2i(2, 2), "jendela [3, 3] kosong (tidak ada rumah)")
	check(JendelaRute.rentang(daftar, -5.0, -1.0) == Vector2i(0, 0) and JendelaRute.rentang(daftar, 11.0, 20.0) == Vector2i(6, 6), "jendela di luar rute = kosong di ujung")
	check(JendelaRute.rentang(daftar, -100.0, 100.0) == Vector2i(0, 6), "jendela mencakup seluruh daftar")
	check(JendelaRute.rentang(daftar, 8.0, 2.0) == Vector2i.ZERO and JendelaRute.rentang(daftar, NAN, 5.0) == Vector2i.ZERO and JendelaRute.rentang(daftar, 0.0, INF) == Vector2i.ZERO, "jendela terbalik atau tidak hingga = kosong")
	var kosong: Array[RouteBuilder.RumahRute] = []
	check(JendelaRute.rentang(kosong, 0.0, 10.0) == Vector2i.ZERO, "daftar kosong = jendela kosong")
	check(JendelaRute.rentang_sekitar(daftar, 30.0) == Vector2i(5, 6) and JendelaRute.rentang_sekitar(daftar, 40.0) == Vector2i(6, 6) and JendelaRute.rentang_sekitar(daftar, 5.0) == Vector2i(0, 6), "rentang_sekitar memakai jendela daur 20 di belakang dan 30 di depan (jarak 30: hanya maju 10; jarak 40: kosong)")

	check(not AkhirRute.tercapai(235.99, 236.0) and AkhirRute.tercapai(236.0, 236.0) and AkhirRute.tercapai(240.0, 236.0), "garis akhir tercapai di jarak >= panjang (inklusif)")
	check(not AkhirRute.tercapai(NAN, 236.0) and not AkhirRute.tercapai(10.0, 0.0) and not AkhirRute.tercapai(INF, 236.0), "garis akhir: NaN, panjang 0, dan tak hingga tidak pernah tercapai")
	var belum: AkhirRute.Status = AkhirRute.periksa(false, 100.0, 236.0)
	var baru: AkhirRute.Status = AkhirRute.periksa(false, 236.0, 236.0)
	var lama: AkhirRute.Status = AkhirRute.periksa(true, 500.0, 236.0)
	check(not belum.selesai and not belum.baru_selesai, "belum sampai: tidak selesai")
	check(baru.selesai and baru.baru_selesai, "mencapai garis: selesai dan baru selesai")
	check(lama.selesai and not lama.baru_selesai, "sudah selesai: tetap selesai, tidak baru lagi (sinyal tepat sekali)")
	check(AkhirRute.stick_akhir() == Vector2(0.0, -1.0), "stick akhir = lurus ke bawah penuh (rem)")

	check(SpriteRumah.nama("limasan", true) == "house_perumahan_limasan_pelanggan" and SpriteRumah.nama("dekat_pelana_lintang", false) == "house_perumahan_dekat_pelana_lintang_bukan", "nama sprite = house_perumahan_<jenis>_<pelanggan|bukan>")
	var seberang: RouteBuilder.RumahRute = RouteBuilder.RumahRute.new()
	seberang.sisi = LoperAnim.Sisi.SEBERANG
	seberang.jenis = "sayap"
	seberang.pelanggan_boleh = true
	seberang.pelanggan = false
	check(SpriteRumah.nama_rumah(seberang) == "house_perumahan_sayap_bukan", "rumah seberang pelanggan_boleh yang tidak terpilih = _bukan")
	seberang.pelanggan = true
	check(SpriteRumah.nama_rumah(seberang) == "house_perumahan_sayap_pelanggan", "rumah seberang terpilih = _pelanggan")
	var dekat: RouteBuilder.RumahRute = RouteBuilder.RumahRute.new()
	dekat.sisi = LoperAnim.Sisi.DEKAT
	dekat.jenis = "dekat_limasan"
	dekat.pelanggan = true
	check(SpriteRumah.nama_rumah(dekat) == "house_perumahan_dekat_limasan_pelanggan", "rumah dekat terpilih = _pelanggan (sejak run 5D bagian B pelanggan juga di sisi dekat)")
	dekat.pelanggan = false
	check(SpriteRumah.nama_rumah(dekat) == "house_perumahan_dekat_limasan_bukan", "rumah dekat yang tidak terpilih = _bukan")
	check(SpriteRumah.titik_pijak("house_perumahan_pelana_bukan") == Vector2i(96, 148) and SpriteRumah.titik_pijak("tidak_ada") == Vector2i(-1, -1), "titik pijak sprite dikenal dan tidak dikenal")
	_test_tabel_sprite()

	var titik: Vector2 = Vector2(-2.0, -9.5)
	var ids_baru: Array[String] = []
	for z: ZonaSasaran.Zona in MedanKoran.zona(null, titik):
		ids_baru.append("%d:%d" % [z.jenis, z.rumah])
	var ids_lama: Array[String] = []
	for z: ZonaSasaran.Zona in ZonaSasaran.zona_jalan_uji_sekitar(9.5):
		ids_lama.append("%d:%d" % [z.jenis, z.rumah])
	check(ids_baru == ids_lama and not ids_baru.is_empty(), "MedanKoran null = zona jalan uji sekitar titik (perilaku run 2A dan 2B tidak berubah)")
	check(MedanKoran.tertutup(null, Vector2(-1.5, -1.0), 0.0) == ZonaSasaran.tertutup_rumah_jalan_uji(Vector2(-1.5, -1.0), 0.0), "MedanKoran null: tertutup = rumah graybox jalan uji")


## Tabel titik pijak di Config = ground_anchor di JSON aset, dan nama sprite = berkas PNG di folder (12 sprite).
func _test_tabel_sprite() -> void:
	var nama_berkas: Array[String] = []
	var dir: DirAccess = DirAccess.open(FOLDER_RUMAH)
	check(dir != null, "folder sprite rumah ada")
	if dir == null:
		return
	for berkas: String in dir.get_files():
		if berkas.ends_with(".png") and berkas.begins_with("house_perumahan_"):
			nama_berkas.append(berkas.get_basename())
	nama_berkas.sort()
	var tabel: Array[String] = []
	for n: String in Config.RUTE_RUMAH_SPRITE:
		tabel.append(n)
	tabel.sort()
	check(nama_berkas == tabel and tabel.size() == 12, "RUTE_RUMAH_SPRITE = 12 berkas PNG sprite rumah (%d berkas)" % nama_berkas.size())
	check(Config.RUTE_RUMAH_PIJAK_PX.size() == Config.RUTE_RUMAH_SPRITE.size() * 2, "RUTE_RUMAH_PIJAK_PX berisi dua nilai (x, y) per sprite")
	var salah: Array[String] = []
	for n: String in Config.RUTE_RUMAH_SPRITE:
		var json: Variant = JSON.parse_string(FileAccess.get_file_as_string("%s/%s.json" % [FOLDER_RUMAH, n]))
		if typeof(json) != TYPE_DICTIONARY:
			salah.append("%s: JSON rusak" % n)
			continue
		var jangkar: Array = (json as Dictionary)["ground_anchor"]
		var dari_tabel: Vector2i = SpriteRumah.titik_pijak(n)
		if dari_tabel != Vector2i(int(jangkar[0]), int(jangkar[1])):
			salah.append("%s: tabel %s, JSON %s" % [n, dari_tabel, jangkar])
		var tekstur: Texture2D = load("%s/%s.png" % [FOLDER_RUMAH, n]) as Texture2D
		var ukuran: Array = (json as Dictionary)["size"]
		if tekstur == null or tekstur.get_width() != int(ukuran[0]) or tekstur.get_height() != int(ukuran[1]):
			salah.append("%s: ukuran PNG tidak sama dengan JSON" % n)
	check(salah.is_empty(), "titik pijak dan ukuran sprite di Config = JSON aset: %s" % [salah])


# --- Rute dari data (AC-12, AC-13) ---

func _test_rute_dari_data() -> void:
	_judul.call("Scene rute: rute seed bawaan dari data, koran awal 30, tombol Main lagi tersembunyi (AC-12, AC-13)")
	var akar: RuteMain = await _siapkan()
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/hari/hari.tscn" and ResourceLoader.exists(BERKAS_RUTE), "hari.tscn adalah run/main_scene (run fase4a-koran-hari) dan rute.tscn tetap ada untuk dijalankan sendiri")
	check(akar.galat_rute().is_empty(), "rute tersusun tanpa galat: %s" % [akar.galat_rute()])
	check(Config.RUTE_SEED_DEV == SEED_DEV and akar.benih() == SEED_DEV, "seed bawaan = Config.RUTE_SEED_DEV = 20261016 (literal)")
	var rute: RouteBuilder.Rute = akar.rute()
	var ids: Array[String] = []
	for s: SegmenRute in rute.segmen:
		ids.append(s.id)
	check(ids == ID_SEGMEN_DEV, "urutan segmen seed bawaan = literal %s (dapat %s)" % [ID_SEGMEN_DEV, ids])
	check(rute.panjang_ubin == PANJANG_RUTE and rute.rumah.size() == JUMLAH_RUMAH and rute.pelanggan.size() == 25, "rute: panjang 236, 89 rumah, 25 pelanggan (dapat %s, %d, %d)" % [rute.panjang_ubin, rute.rumah.size(), rute.pelanggan.size()])
	check(rute.pelanggan[0].id == "per_buka_01@6" and rute.pelanggan[0].maju_ubin == 6.0 and rute.pelanggan[8].id == "per_tengah_03@14" and rute.pelanggan[8].maju_ubin == 78.0 and rute.pelanggan[24].id == "per_tutup_02@18" and rute.pelanggan[24].maju_ubin == 226.0, "pelanggan ke-1, ke-9, dan ke-25 literal (id dan jarak maju)")
	check(rute.koran_awal == 30 and akar.koran.sisa == 30 and akar.koran.penuh == 30, "koran awal rute = 30 dari data (sisa %d)" % akar.koran.sisa)
	var hud: HudDasar = _anak(akar, "Hud") as HudDasar
	check(hud is HudRute and hud.teks_koran() == "30" and hud.ikon_koran() == Vector2i(8, 8), "HUD koran menampilkan 30 dan delapan ikon terang")
	var oracle: RouteBuilder.Rute = _rute_oracle(SEED_DEV)
	var sama: bool = oracle != null and oracle.rumah.size() == rute.rumah.size()
	if sama:
		for i: int in range(rute.rumah.size()):
			if oracle.rumah[i].id != rute.rumah[i].id or oracle.rumah[i].pelanggan != rute.rumah[i].pelanggan or oracle.rumah[i].maju_ubin != rute.rumah[i].maju_ubin:
				sama = false
	check(sama, "rumah di scene = rute yang disusun tes dari folder segmen yang sama (id, pelanggan, jarak)")
	check(not akar.panel_akhir().tampil() and not akar.rute_sudah_selesai() and not akar.layar_hasil().tampil(), "banner dan layar hasil tersembunyi di awal rute")
	check(akar.medan() != null and (akar.medan() as MedanKoran).adalah_rute(), "penilaian koran memakai medan rute (bukan zona jalan uji)")
	_bersihkan(akar)


func _test_rumah_digambar() -> void:
	_judul.call("Scene rute: rumah dan kotak surat digambar dari data, sprite, titik pijak, Y-sort (AC-12)")
	var akar: RuteMain = await _siapkan()
	var rute: RouteBuilder.Rute = _rute_oracle(SEED_DEV)
	var objek: Node2D = _anak(akar, "Objek") as Node2D
	check(objek.y_sort_enabled and _sepeda(akar).get_parent() == objek, "Objek induk Y-sort, sepeda anak langsungnya")
	for jarak: float in [0.0, 100.0, 200.0, 236.0]:
		_taruh_sepeda(akar, 3.0, 0.0, 0.0, jarak)
		var harapan: Array[int] = _indeks_harapan(rute, jarak)
		var tampil: Array[int] = akar.daur().indeks_tampil()
		check(tampil == harapan and not harapan.is_empty(), "jarak %.0f: rumah digambar = rumah dalam [maju - 20, maju + 30] (%d rumah, dapat %d)" % [jarak, harapan.size(), tampil.size()])
		check(tampil.size() < JUMLAH_RUMAH, "jarak %.0f: bukan seluruh rute sekaligus (%d dari 89)" % [jarak, tampil.size()])
		var salah: Array[String] = []
		var kotak_harapan: int = 0
		for i: int in harapan:
			var rumah: RouteBuilder.RumahRute = rute.rumah[i]
			var seberang: bool = rumah.sisi == LoperAnim.Sisi.SEBERANG
			var nama: String = "house_perumahan_%s_%s" % [rumah.jenis, "pelanggan" if seberang and rumah.pelanggan else "bukan"]
			var sprite: Sprite2D = akar.daur().sprite_rumah(i)
			if sprite == null:
				salah.append("%s: tidak ada sprite" % rumah.id)
				continue
			if sprite.texture == null or sprite.texture.resource_path != "%s/%s.png" % [FOLDER_RUMAH, nama]:
				salah.append("%s: tekstur %s, harap %s" % [rumah.id, sprite.texture.resource_path if sprite.texture != null else "null", nama])
			var json: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("%s/%s.json" % [FOLDER_RUMAH, nama]))
			var jangkar: Array = json["ground_anchor"]
			if sprite.offset != -Vector2(float(jangkar[0]), float(jangkar[1])) or sprite.centered:
				salah.append("%s: offset %s, harap %s" % [rumah.id, sprite.offset, -Vector2(float(jangkar[0]), float(jangkar[1]))])
			# Run fase5d-sisi-dekat (K-1, P-1): sprite rumah dekat digambar 0,5 ubin lebih jauh dari jalan (tapak logika tetap 3,0 sampai 6,0, pusat 4,5): 5,0 (run 5B: 5,75).
			var tengah_x: float = -4.5 if seberang else 5.0
			var letak: Vector2 = _layar(tengah_x, rumah.maju_ubin + 1.0)
			if sprite.position != letak:
				salah.append("%s: posisi %s, harap %s" % [rumah.id, sprite.position, letak])
			if sprite.get_parent() != objek or not sprite.visible:
				salah.append("%s: bukan anak Objek atau tersembunyi" % rumah.id)
			var kotak: Node2D = akar.daur().kotak_surat(i)
			if seberang and rumah.pelanggan:
				kotak_harapan += 1
				if kotak == null or kotak.position != _layar(-2.125, rumah.maju_ubin + 1.75) or not kotak.visible:
					salah.append("%s: kotak surat %s" % [rumah.id, kotak.position if kotak != null else "tidak ada"])
			elif kotak != null:
				salah.append("%s: kotak surat di rumah bukan pelanggan" % rumah.id)
		check(salah.is_empty(), "jarak %.0f: tekstur, titik pijak, posisi layar, dan kotak surat tiap rumah sesuai data: %s" % [jarak, salah.slice(0, 4)])
		check(akar.daur().jumlah_kotak_surat() == kotak_harapan, "jarak %.0f: kotak surat hanya di rumah pelanggan (%d, dapat %d)" % [jarak, kotak_harapan, akar.daur().jumlah_kotak_surat()])
	# Rumah dekat selalu _bukan dan seberang tidak terpilih _bukan di data nyata (kontrol agar tes tidak kosong).
	var seberang_bukan: int = 0
	var dekat_ada: int = 0
	for rumah: RouteBuilder.RumahRute in rute.rumah:
		if rumah.sisi == LoperAnim.Sisi.SEBERANG and not rumah.pelanggan:
			seberang_bukan += 1
		if rumah.sisi == LoperAnim.Sisi.DEKAT:
			dekat_ada += 1
	check(seberang_bukan == 34 and dekat_ada == 30, "kontrol data: 34 rumah seberang bukan pelanggan dan 30 rumah dekat ada (dapat %d, %d)" % [seberang_bukan, dekat_ada])
	var anak_gambar: int = 0
	for anak: Node in objek.get_children():
		if anak is CanvasItem and (anak as CanvasItem).visible:
			anak_gambar += 1
	# Run fase3b-rintangan-skor: rintangan kini digambar, tetapi di dalam satu node induk `Rintangan` (anak Y-sort Objek), jadi anak Objek =
	# rumah (tembok sisi dekat run 5B dilepas run 5D) + kotak surat (oranye pelanggan dan abu-abu bukan pelanggan seberang, 2026-10-17) + sepeda + node Rintangan (rintangan sendiri
	# dites di `tes_rintangan_scene.gd`) + node Dekor (induk dekor pinggir jalan, run fase5b B2; dites di `tes_dekor.gd`) + node Portal (run garis-finish-portal bagian C; dites di `tes_garis_finish_scene.gd`).
	check(anak_gambar == akar.daur().jumlah_rumah() + akar.daur().jumlah_kotak_surat() + akar.daur().jumlah_kotak_surat_bukan() + 4 and akar.rintangan_daur().get_parent() == objek and akar.dekor_daur().get_parent() == objek, "tidak ada node lain yang digambar di Objek (rumah, kotak surat oranye dan abu-abu, sepeda, induk rintangan, induk dekor, portal garis finish): %d" % anak_gambar)
	_bersihkan(akar)


func _test_jendela_daur_bergerak() -> void:
	_judul.call("Scene rute: jendela daur mengikuti sepeda sepanjang rute, node dipakai ulang (AC-12)")
	var akar: RuteMain = await _siapkan()
	var rute: RouteBuilder.Rute = _rute_oracle(SEED_DEV)
	var salah: Array[String] = []
	var maks_tampil: int = 0
	var maks_node: int = 0
	# 95 titik (jarak sampai 235): sesudah garis akhir dunia dibekukan (run garis-finish-portal, G-5), jadi jendela daur di sana dites di `tes_garis_finish_scene.gd`.
	for langkah: int in range(0, 95):
		var jarak: float = float(langkah) * 2.5
		_taruh_sepeda(akar, 3.0, 0.0, 0.0, jarak)
		var tampil: Array[int] = akar.daur().indeks_tampil()
		if tampil != _indeks_harapan(rute, jarak):
			salah.append("jarak %.1f: %s" % [jarak, tampil.size()])
		maks_tampil = maxi(maks_tampil, tampil.size())
		maks_node = maxi(maks_node, akar.daur().jumlah_node_rumah())
		if akar.penerap_penutup().jumlah() != tampil.size() + akar.rintangan_daur().jumlah_tampil() + _jumlah_dekor_penutup(akar) + 1:
			salah.append("jarak %.1f: penerap %d, tampil %d" % [jarak, akar.penerap_penutup().jumlah(), tampil.size()])
	check(salah.is_empty(), "sepanjang rute (95 titik): rumah digambar = jendela oracle dan didaftarkan ke penerap penutup: %s" % [salah.slice(0, 3)])
	check(maks_tampil <= 30 and maks_tampil >= 20, "paling banyak %d rumah sekaligus (jendela, bukan 89)" % maks_tampil)
	check(maks_node <= 30, "node rumah dipakai ulang dari kolam (paling banyak %d node dibuat, 89 rumah)" % maks_node)
	_bersihkan(akar)


func _test_tanpa_area_kotak() -> void:
	_judul.call("Scene rute: TIDAK ada persegi area kotak surat di tanah (keputusan pemilik 2026-10-22: persegi membuat pemain mengira hanya area itu yang dinilai)")
	check(not ResourceLoader.exists("res://scripts/entities/area_kotak_gambar.gd"), "skrip penggambar area kotak surat (area_kotak_gambar.gd) sudah dihapus")
	var kelas_area: Array[String] = []
	for kelas: Dictionary in ProjectSettings.get_global_class_list():
		if str(kelas.get("class", "")) == "AreaKotakGambar":
			kelas_area.append(str(kelas.get("path", "")))
	check(kelas_area.is_empty(), "tidak ada kelas global AreaKotakGambar: %s" % [kelas_area])
	var akar: RuteMain = await _siapkan()
	var rute: RouteBuilder.Rute = _rute_oracle(SEED_DEV)
	check(_anak(akar, "AreaKotak") == null, "scene rute tidak punya simpul AreaKotak")
	# Lapisan tanah di bawah objek dunia hanya ubin tanah dan koran yang tergeletak: tidak ada penggambar lain di antara Tanah dan Objek.
	var tanah: Node = _anak(akar, "Tanah")
	var objek: Node = _anak(akar, "Objek")
	var di_antara: Array[String] = []
	for anak: Node in akar.get_children():
		if anak.get_index() > tanah.get_index() and anak.get_index() < objek.get_index():
			di_antara.append(String(anak.name))
	check(di_antara == ["KoranTanah"], "di antara Tanah dan Objek hanya KoranTanah (dapat %s)" % [di_antara])
	var kontrol_pelanggan: int = 0
	for jarak: float in [0.0, 50.0, 100.0, 150.0, 200.0, 236.0]:
		_taruh_sepeda(akar, 3.0, 0.0, 0.0, jarak)
		for i: int in _indeks_harapan(rute, jarak):
			if rute.rumah[i].pelanggan and rute.rumah[i].sisi == LoperAnim.Sisi.SEBERANG:
				kontrol_pelanggan += 1
		var penggambar: Array[String] = _penggambar_area(akar)
		check(penggambar.is_empty(), "jarak %.0f: tidak ada simpul penggambar area/zona (AreaKotakGambar, ZonaGambar) di scene rute: %s" % [jarak, penggambar])
	check(kontrol_pelanggan > 0, "kontrol: jendela yang diperiksa memuat rumah pelanggan seberang (%d)" % kontrol_pelanggan)
	akar.main_lagi()
	check(_anak(akar, "AreaKotak") == null and _penggambar_area(akar).is_empty(), "sesudah Main lagi: tetap tanpa penggambar area kotak surat")
	_bersihkan(akar)


## Simpul di bawah `akar` yang skripnya penggambar area atau zona di tanah (berkas area_kotak_gambar atau kelas `ZonaGambar`).
func _penggambar_area(akar: Node) -> Array[String]:
	var hasil: Array[String] = []
	var antre: Array[Node] = [akar]
	while not antre.is_empty():
		var n: Node = antre.pop_back()
		var skrip: Script = n.get_script() as Script
		if skrip != null:
			var jalur: String = skrip.resource_path
			if jalur.get_file().begins_with("area_kotak") or jalur.get_file() == "zona_gambar.gd" or n is ZonaGambar:
				hasil.append("%s (%s)" % [n.name, jalur])
		antre.append_array(n.get_children())
	return hasil


# --- Zona dan penilaian dari data rute (AC-9, AC-10) ---

func _test_zona_dari_data() -> void:
	_judul.call("Scene rute: zona penilaian dari data rute, bukan zona jalan uji (AC-9, AC-10)")
	var akar: RuteMain = await _siapkan()
	var medan: MedanKoran = akar.medan()
	var rute: RouteBuilder.Rute = akar.rute()
	var uji: Array = [
		["kotak surat pelanggan per_tengah_03@14 (maju 78)", Vector2(-2.25, -79.875), ZonaSasaran.Hasil.KOTAK_SURAT],
		["teras pelanggan per_tengah_03@14", Vector2(-2.75, -78.5), ZonaSasaran.Hasil.TERAS],
		["halaman pelanggan per_tengah_03@14 (sebelum area kotak surat)", Vector2(-2.25, -78.0), ZonaSasaran.Hasil.HALAMAN],
		["kotak surat pelanggan per_buka_01@6 (maju 6)", Vector2(-2.25, -7.875), ZonaSasaran.Hasil.KOTAK_SURAT],
		["tengah jalan", Vector2(0.0, -79.0), ZonaSasaran.Hasil.MELESET],
		["titik yang di jalan uji kotak surat (kavling 1, bagian di atas trotoar) tapi di rute tidak ada rumah", Vector2(-1.9, -5.875), ZonaSasaran.Hasil.MELESET],
	]
	for kasus: Array in uji:
		var titik: Vector2 = kasus[1]
		var hasil: ZonaSasaran.Hasil = ZonaSasaran.klasifikasi(titik, medan.zona_sekitar(titik))
		check(hasil == kasus[2], "%s: %s (dapat %s)" % [kasus[0], ZonaSasaran.Hasil.keys()[kasus[2]], ZonaSasaran.Hasil.keys()[hasil]])
	var bukan_seberang: RouteBuilder.RumahRute = null
	var dekat: RouteBuilder.RumahRute = null
	for rumah: RouteBuilder.RumahRute in rute.rumah:
		if bukan_seberang == null and rumah.sisi == LoperAnim.Sisi.SEBERANG and not rumah.pelanggan and rumah.pelanggan_boleh:
			bukan_seberang = rumah
		if dekat == null and rumah.sisi == LoperAnim.Sisi.DEKAT and rumah.maju_ubin > 20.0:
			dekat = rumah
	check(bukan_seberang != null and dekat != null, "kontrol data: ada rumah seberang pelanggan_boleh yang tidak terpilih dan rumah dekat")
	if bukan_seberang != null and dekat != null:
		var t1: Vector2 = Vector2(-2.25, -(bukan_seberang.maju_ubin + 1.875))
		var t2: Vector2 = Vector2(2.5, -(dekat.maju_ubin + 1.0))
		check(ZonaSasaran.klasifikasi(t1, medan.zona_sekitar(t1)) == ZonaSasaran.Hasil.BUKAN_PELANGGAN, "kotak surat rumah seberang yang tidak terpilih (%s) = BUKAN_PELANGGAN" % bukan_seberang.id)
		check(ZonaSasaran.klasifikasi(t2, medan.zona_sekitar(t2)) == ZonaSasaran.Hasil.BUKAN_PELANGGAN, "halaman rumah dekat (%s) = BUKAN_PELANGGAN (rute hari 1: tanpa pelanggan sisi dekat)" % dekat.id)
	# Elips TERTUTUP: titik mendarat di balik atap rumah dari kamera iso (rumah rute kedua sisi, bukan hanya graybox seberang).
	if dekat != null:
		# Titik (2,9; maju + 1,0): sinar ke kamera bergeser d = 1,0 .. 1,5 masuk kotak sprite rumah dekat (badan mulai lateral 3,906, tinggi >= 1,56), jadi tertutup menurut sprite nyata (run 5D bagian B, AC-10).
		var di_balik_dekat: Vector2 = Vector2(2.9, -(dekat.maju_ubin + 1.0))
		var l_dekat: ThrowSolver.Lintasan = ThrowSolver.Lintasan.new()
		l_dekat.titik_mendarat = di_balik_dekat
		check(medan.tertutup_titik(di_balik_dekat, 0.0) and not medan.tertutup_titik(Vector2(0.0, di_balik_dekat.y), 0.0), "halaman rumah dekat %s tertutup badan rumah dari kamera (sinar ke kamera bergeser masuk kotak sprite nyata), tengah jalan tidak" % dekat.id)
		check(KoranLempar.bentuk_elips(l_dekat, false, medan) == KoranLempar.Elips.TERTUTUP and KoranLempar.bentuk_elips(l_dekat, false) == KoranLempar.Elips.SAH, "elips di balik rumah dekat = TERTUTUP di medan rute (BUKAN_PELANGGAN), sedangkan zona jalan uji di titik yang sama = SAH (halaman pelanggan dekat)")
	var seberang_tertutup: Vector2 = Vector2(-4.5, -(rute.pelanggan[8].maju_ubin + 1.0))
	check(medan.tertutup_titik(seberang_tertutup, 0.0), "titik di dalam tapak rumah seberang (pelanggan ke-9) tertutup")
	# Penilaian koran sungguhan memakai medan yang sama: lintasan bersintetis mendarat di kotak surat.
	var lintasan: ThrowSolver.Lintasan = ThrowSolver.Lintasan.new()
	lintasan.titik_mendarat = Vector2(-1.9, -79.875)
	check(KoranLempar.hasil_mendarat(lintasan, medan) == ZonaSasaran.Hasil.KOTAK_SURAT and KoranLempar.hasil_mendarat(lintasan) == ZonaSasaran.Hasil.MELESET, "KoranLempar.hasil_mendarat: medan rute = KOTAK_SURAT, tanpa medan (jalan uji) di titik yang sama meleset")
	# Mode bantu tidak pernah memilih rumah bukan pelanggan atau sisi dekat (AC-10), sepanjang rute, tiga kecepatan.
	var salah: Array[String] = []
	for v: float in [3.0, 4.5, 6.0]:
		for maju: float in range(0, 236, 3):
			_taruh_sepeda(akar, v, 0.0, 0.0, float(maju))
			for sisi: LoperAnim.Sisi in [LoperAnim.Sisi.SEBERANG, LoperAnim.Sisi.DEKAT]:
				var pilihan: BantuLempar.Pilihan = akar.pilihan_bantu(sisi)
				if pilihan == null:
					continue
				var id: String = pilihan.zona.id_rumah
				var terpilih: bool = false
				for r: RouteBuilder.RumahRute in rute.pelanggan:
					if r.id == id:
						terpilih = true
				if sisi == LoperAnim.Sisi.DEKAT or not terpilih or pilihan.zona.sisi != LoperAnim.Sisi.SEBERANG or not pilihan.zona.pelanggan:
					salah.append("v %.1f maju %d %s: %s" % [v, maju, LoperAnim.Sisi.keys()[sisi], id])
	check(salah.is_empty(), "mode bantu hanya memilih kotak surat pelanggan seberang dari rute (3 kecepatan x 79 posisi): %s" % [salah.slice(0, 3)])
	_bersihkan(akar)


func _test_koran_tanpa_isi_ulang() -> void:
	_judul.call("Scene rute: tidak ada isi ulang koran jalan uji (AC-13)")
	var akar: RuteMain = await _siapkan()
	akar.koran = SisaKoran.awal(1)
	var catatan: Dictionary = _catat(akar)
	_nyalakan_bantu(akar)
	_taruh_sepeda(akar, 3.0, 0.0, 0.0, 6.0)
	akar.koran = SisaKoran.awal(1)
	_tap(_tap_seberang(akar))
	check((catatan["lempar"] as Array).size() == 1 and akar.koran.sisa == 0, "koran terakhir dilempar: sisa 0")
	# Sepeda menempuh jauh melewati 16 ubin (ambang isi ulang jalan uji, `JALAN_UJI_ISI_ULANG_UBIN`) dan jauh lebih.
	for i: int in range(12):
		_sepeda(akar).jarak_ubin += 8.0
		_langkah(akar, 2)
	check(akar.koran.sisa == 0 and akar.koran.penuh == 1, "96 ubin sesudah habis: sisa tetap 0 (tidak ada isi ulang jalan uji), dapat %d" % akar.koran.sisa)
	var hud: HudDasar = _anak(akar, "Hud") as HudDasar
	check(hud.penanda_habis_tampil() and hud.teks_koran() == "0", "HUD: penanda habis tampil dan angka 0")
	_bersihkan(akar)


# --- Mode bantu di scene (AC-11) ---

func _test_bantu_kisi(v: float) -> void:
	_judul.call("Scene rute: kisi mode bantu v %.1f lawan BantuLempar.pilih dari masukan tes, mendarat di kotak surat pelanggan (AC-10, AC-11)" % v)
	var akar: RuteMain = await _siapkan()
	var rute: RouteBuilder.Rute = _rute_oracle(SEED_DEV)
	var semua_zona: Array[ZonaSasaran.Zona] = ZonaSasaran.zona_rute(rute.rumah)
	# Rintangan dikosongkan: kisi ini menguji sasaran mode bantu, dan sejak tabrakan = jatuh (keputusan pemilik 2026-10-17) tabrakan dengan
	# anjing atau mobil di sepanjang kisi menolak tap berikutnya. Penolakan lemparan selama jatuh dites di `TesRintanganScene`.
	akar.set(&"_rintangan", RintanganRute.Keadaan.new())
	var catatan: Dictionary = _catat(akar)
	_nyalakan_bantu(akar)
	var salah: Array[String] = []
	var keadaan: int = 0
	var bersasaran: int = 0
	var tanpa: int = 0
	var mendarat_sah: int = 0
	var indeks_pelanggan: Array[int] = [0, 3, 8, 12, 17, 20, 24]
	# Run fase3b-rintangan-skor (O-1, O-4): antaran pertama ke tiap rumah = centang (bantu tidak pernah tepat), koran berikutnya ke rumah yang
	# sama = penanda netral. Rumah terantar dicatat tes sendiri.
	var terantar: Dictionary = {}
	for ip: int in indeks_pelanggan:
		var pusat_maju: float = rute.pelanggan[ip].maju_ubin
		for selisih: float in [-6.0, -3.0, -1.0, 0.0, 2.0]:
			var maju: float = pusat_maju + selisih
			for lateral: float in [-0.8, 0.0, 0.8]:
				keadaan += 1
				_taruh_sepeda(akar, v, lateral, 0.0, maju)
				var tag: String = "v %.1f lateral %.1f maju %.1f (pelanggan %s)" % [v, lateral, maju, rute.pelanggan[ip].id]
				var harapan: BantuLempar.Pilihan = BantuLempar.pilih(LoperAnim.Sisi.SEBERANG, Vector2(lateral, -maju), v, 0.0, JEDA_LEPAS_HARAPAN, LEBAR, semua_zona)
				var tap: Vector2 = _tap_seberang(akar)
				var sebelum: int = (catatan["lempar"] as Array).size()
				var tanpa_sebelum: int = (catatan["tanpa"] as Array).size()
				_tap(tap)
				var lempar: Array = catatan["lempar"] as Array
				if harapan == null:
					tanpa += 1
					if lempar.size() != sebelum or (catatan["tanpa"] as Array).size() != tanpa_sebelum + 1:
						salah.append("%s: harap tanpa sasaran" % tag)
					continue
				bersasaran += 1
				if lempar.size() != sebelum + 1:
					salah.append("%s: harap melempar ke %s" % [tag, harapan.zona.id_rumah])
					continue
				var l: ThrowSolver.Lintasan = lempar[sebelum]
				if not _dekat(l.titik_mendarat, harapan.lintasan.titik_mendarat, 0.0001) or not _dekat(l.titik_lepas, harapan.lintasan.titik_lepas, 0.0001):
					salah.append("%s: lintasan beda dari oracle" % tag)
					continue
				var k: KoranLempar.Koran = _sampai_mendarat(akar, catatan, l)
				var penanda_harapan: ZonaSasaran.Penanda = ZonaSasaran.Penanda.NETRAL if terantar.has(harapan.zona.id_rumah) else ZonaSasaran.Penanda.CENTANG
				terantar[harapan.zona.id_rumah] = true
				if k == null or k.hasil != ZonaSasaran.Hasil.KOTAK_SURAT or k.penanda != penanda_harapan or k.antaran != ZonaSasaran.Antaran.SAH_PENUH:
					salah.append("%s: tidak dinilai KOTAK_SURAT sah penuh" % tag)
				else:
					mendarat_sah += 1
				var zona_kena: ZonaSasaran.Zona = ZonaSasaran.zona_kena(l.titik_mendarat, semua_zona)
				if zona_kena == null or zona_kena.id_rumah != harapan.zona.id_rumah or zona_kena.jenis != ZonaSasaran.Jenis.KOTAK_SURAT or not zona_kena.pelanggan:
					salah.append("%s: zona kena bukan kotak surat pelanggan %s" % [tag, harapan.zona.id_rumah])
	check(salah.is_empty(), "v %.1f: %d keadaan, tap di scene = oracle (lintasan, penilaian, atau tanda tanpa sasaran); salah %d: %s" % [v, keadaan, salah.size(), salah.slice(0, 4)])
	check(bersasaran > 20 and tanpa > 0 and mendarat_sah == bersasaran, "v %.1f: kisi mencakup keadaan bersasaran (%d, semua mendarat sah %d) dan tanpa sasaran (%d)" % [v, bersasaran, mendarat_sah, tanpa])
	_bersihkan(akar)


func _test_swipe_dinilai_zona_rute() -> void:
	_judul.call("Scene rute: swipe manual dinilai dengan zona rute, prediksi garis bidik = hasil (AC-11, prinsip run 2A)")
	var akar: RuteMain = await _siapkan()
	var rute: RouteBuilder.Rute = _rute_oracle(SEED_DEV)
	var semua_zona: Array[ZonaSasaran.Zona] = ZonaSasaran.zona_rute(rute.rumah)
	var catatan: Dictionary = _catat(akar)
	var garis: GarisBidik = akar.garis_bidik()
	var salah: Array[String] = []
	var sah: int = 0
	var jumlah: int = 0
	var awal: Vector2 = Vector2(300, 220)
	for sudut: float in [20.0, 40.0, 60.0, 80.0, 100.0, 120.0, 140.0, 200.0, 230.0, 260.0, 290.0, 320.0]:
		for panjang: float in [50.0, 80.0, 110.0]:
			jumlah += 1
			_taruh_sepeda(akar, 3.0, 0.0, 0.0, 70.0 + float(jumlah))
			akar.koran = SisaKoran.awal(30)
			var akhir: Vector2 = awal + Vector2(cos(deg_to_rad(sudut)), -sin(deg_to_rad(sudut))) * panjang
			var sebelum: int = (catatan["lempar"] as Array).size()
			_sentuh(1, awal, true)
			_geser(1, akhir)
			_langkah(akar, 1)
			var prediksi_sah: bool = garis.elips_sah()
			var tampil: bool = garis.tampil()
			_sentuh(1, akhir, false)
			var lempar: Array = catatan["lempar"] as Array
			if lempar.size() != sebelum + 1:
				if tampil:
					salah.append("sudut %.0f panjang %.0f: garis bidik tampil tetapi tidak melempar" % [sudut, panjang])
				continue
			var l: ThrowSolver.Lintasan = lempar[sebelum]
			var k: KoranLempar.Koran = _sampai_mendarat(akar, catatan, l)
			if k == null:
				salah.append("sudut %.0f panjang %.0f: tidak mendarat" % [sudut, panjang])
				continue
			var harapan: ZonaSasaran.Hasil = ZonaSasaran.klasifikasi(l.titik_mendarat, semua_zona)
			if k.hasil != harapan:
				salah.append("sudut %.0f panjang %.0f: hasil %s, oracle %s" % [sudut, panjang, ZonaSasaran.Hasil.keys()[k.hasil], ZonaSasaran.Hasil.keys()[harapan]])
			if prediksi_sah != ZonaSasaran.sah(k.antaran):
				salah.append("sudut %.0f panjang %.0f: elips sah %s tetapi antaran %s" % [sudut, panjang, prediksi_sah, ZonaSasaran.Antaran.keys()[k.antaran]])
			if ZonaSasaran.sah(k.antaran):
				sah += 1
	check(salah.is_empty(), "%d swipe: hasil = oracle zona seluruh rute, elips garis bidik = antaran: %s" % [jumlah, salah.slice(0, 4)])
	check((catatan["lempar"] as Array).size() >= 20, "kontrol: banyak swipe benar-benar melempar (%d dari %d)" % [(catatan["lempar"] as Array).size(), jumlah])
	_bersihkan(akar)


## QA-002 (Q22): titik garis bidik yang redup menurut rumah RUTE (medan rute), bukan rumah graybox jalan uji.
func _test_garis_bidik_titik_redup() -> void:
	_judul.call("Scene rute: titik garis bidik redup menurut rumah rute (QA-002, AC-15)")
	var akar: RuteMain = await _siapkan()
	var garis: GarisBidik = akar.garis_bidik()
	var medan: MedanKoran = akar.medan()
	var salah: int = 0
	var tampil: int = 0
	var redup: int = 0
	var beda_graybox: int = 0
	var awal: Vector2 = Vector2(300, 220)
	for maju: float in [60.0, 62.0, 64.0, 66.0, 68.0, 70.0]:
		for sudut: float in [100.0, 120.0, 140.0, 160.0, 180.0]:
			for panjang: float in [110.0, 170.0, 200.0, 230.0]:
				_taruh_sepeda(akar, 3.0, 0.0, 0.0, maju)
				var akhir: Vector2 = awal + Vector2(cos(deg_to_rad(sudut)), -sin(deg_to_rad(sudut))) * panjang
				_sentuh(1, awal, true)
				_geser(1, akhir)
				_langkah(akar, 1)
				if garis.tampil():
					tampil += 1
					var waktu: PackedFloat32Array = KoranLempar.waktu_titik_bidik(garis.lintasan(), float(Config.SWIPE_TITIK_JARAK_PX), Config.GARIS_BIDIK_SAMPEL)
					if waktu.size() != garis.titik_gambar().size():
						salah += 1
					for i: int in range(mini(waktu.size(), garis.titik_gambar().size())):
						var p: Vector3 = ThrowSolver.posisi_pada(garis.lintasan(), waktu[i])
						var harapan: bool = medan.tertutup_titik(Vector2(p.x, p.y), p.z)
						if garis.titik_tertutup(i) != harapan:
							salah += 1
						if harapan:
							redup += 1
						if harapan != ZonaSasaran.tertutup_rumah_jalan_uji(Vector2(p.x, p.y), p.z):
							beda_graybox += 1
				_sentuh(1, akhir, false)
				akar.koran = SisaKoran.awal(30)
				_langkah(akar, 1)
	check(tampil >= 60, "kontrol: garis bidik tampil pada banyak swipe (%d dari 120)" % tampil)
	check(salah == 0, "tiap titik garis bidik redup tepat bila titiknya tertutup rumah rute (medan.tertutup_titik), salah %d" % salah)
	check(redup >= 1 and beda_graybox >= 1, "kontrol: ada titik redup menurut rumah rute (%d) dan ada yang berbeda dari rumah graybox jalan uji (%d)" % [redup, beda_graybox])
	_bersihkan(akar)

# --- Akhir rute (AC-14) ---

func _test_akhir_rute() -> void:
	_judul.call("Scene rute: akhir rute, sinyal tepat sekali, rem, stick dikunci, banner dan tombol (AC-14)")
	var akar: RuteMain = await _siapkan()
	var catatan: Dictionary = _catat(akar)
	var sepeda: SepedaUji = _sepeda(akar)
	_nyalakan_bantu(akar)
	# Ngebut mendekati garis, stick ditahan ke atas.
	_taruh_sepeda(akar, 6.0, 0.0, 0.0, PANJANG_RUTE - 3.0)
	_sentuh(0, TITIK_STICK, true)
	_geser(0, TITIK_STICK + Vector2(0, -40))
	_langkah(akar, 2)
	check(not akar.rute_sudah_selesai() and (catatan["selesai"] as int) == 0 and not akar.panel_akhir().tampil(), "3 ubin sebelum garis: belum selesai, tanpa sinyal, banner tersembunyi")
	var lateral_sebelum: float = sepeda.lateral_ubin
	_langkah(akar, 30)
	check(akar.rute_sudah_selesai() and (catatan["selesai"] as int) == 1, "melewati garis akhir: selesai dan rute_selesai tepat sekali (%d)" % catatan["selesai"])
	check(sepeda.jarak_ubin >= PANJANG_RUTE, "sepeda sudah mencapai garis akhir (%.2f >= 236)" % sepeda.jarak_ubin)
	check(not akar.panel_akhir().tampil() and akar.fase_keluar() == AkhirRute.Fase.MELAJU_KELUAR, "di garis akhir banner BELUM tampil (G-3: muncul saat sepeda hampir keluar) dan fase melaju keluar")
	check(not akar.layar_hasil().tampil(), "layar hasil belum terbuka selagi sepeda masih melaju sesudah garis")
	check(tr("RUTE_SELESAI") == "Rute selesai" and tr("RUTE_MAIN_LAGI") == "Main lagi", "kunci RUTE_SELESAI dan RUTE_MAIN_LAGI diterjemahkan")
	# Stick ke atas tetap ditahan, tetapi dikunci: sepeda TIDAK direm, melaju keluar viewport, banner muncul saat hampir keluar, lalu layar hasil terbuka (G-2 sampai G-4).
	var rem_terlihat: bool = false
	var laju_min: float = INF
	var banner_terlihat: bool = false
	var banner_benar: bool = true
	for i: int in range(60 * 20):
		_langkah(akar, 1)
		rem_terlihat = rem_terlihat or sepeda.rem_aktif()
		laju_min = minf(laju_min, sepeda.kecepatan_ud)
		if akar.panel_akhir().tampil() and not akar.hasil_tampil():
			banner_terlihat = true
			banner_benar = banner_benar and akar.panel_akhir().teks_banner() == "Rute selesai" and not akar.panel_akhir().tombol_tampil()
		if akar.hasil_tampil():
			break
	check(akar.hasil_tampil() and akar.layar_hasil().tampil() and akar.fase_keluar() == AkhirRute.Fase.SUDAH_KELUAR, "layar hasil terbuka sesudah sepeda keluar viewport (bukan sesudah berhenti)")
	check(banner_terlihat and banner_benar and not akar.panel_akhir().tampil(), "banner 'Rute selesai' (kunci terjemahan, tanpa tombol) tampil saat hampir keluar dan disembunyikan saat hasil terbuka (O-11, G-3)")
	check(not rem_terlihat and laju_min >= Config.RUTE_KELUAR_LAJU_MIN_UD - 0.0001, "sepeda tidak pernah direm sesudah garis dan lajunya tidak turun di bawah laju minimum (terendah %.3f)" % laju_min)
	_langkah(akar, 120)
	check(sepeda.lateral_ubin == lateral_sebelum and akar.hasil_tampil(), "stick ke atas yang masih ditahan tidak membelokkan sepeda sesudah akhir (stick dikunci)")
	# Stick ke samping dan atas, jari baru: tidak mengubah apa pun.
	_sentuh(0, TITIK_STICK, false)
	_sentuh(2, TITIK_STICK, true)
	_geser(2, TITIK_STICK + Vector2(40, 0))
	_langkah(akar, 30)
	check(sepeda.lateral_ubin == lateral_sebelum and not akar.sedang_jeda(), "stick ke samping sesudah akhir: tidak berpindah jalur")
	_sentuh(2, TITIK_STICK, false)
	# Lemparan baru ditolak (tap mode bantu dan swipe), koran tidak berkurang.
	var sisa: int = akar.koran.sisa
	var tanpa_sebelum: int = (catatan["tanpa"] as Array).size()
	_taruh_di_dekat_pelanggan_terakhir(akar)
	_tap(_tap_seberang(akar))
	_sentuh(3, Vector2(300, 220), true)
	_geser(3, Vector2(360, 160))
	_langkah(akar, 1)
	check(not akar.garis_bidik().tampil(), "sesudah akhir rute garis bidik tidak tampil")
	_sentuh(3, Vector2(360, 160), false)
	check(akar.koran.sisa == sisa and (catatan["lempar"] as Array).is_empty() and (catatan["tanpa"] as Array).size() == tanpa_sebelum, "sesudah akhir rute: tap bantu dan swipe tidak melempar (sisa %d, lempar %d)" % [akar.koran.sisa, (catatan["lempar"] as Array).size()])
	check((catatan["selesai"] as int) == 1, "sinyal rute_selesai tetap satu kali sesudah semua itu")
	# Jeda (app ke background) tetap bekerja di layar hasil; back Android di layar hasil diabaikan (O-11: tidak memulai ulang diam-diam dan
	# tidak membuka layar jeda di atas hasil).
	akar._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(akar.sedang_jeda() and _tree.paused, "kehilangan fokus menjeda di layar hasil")
	akar._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(not akar.sedang_jeda() and not _tree.paused, "back saat layar jeda terbuka di atas hasil: melanjutkan (perilaku jeda biasa)")
	var benih_hasil: int = akar.benih()
	akar._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(not akar.sedang_jeda() and akar.layar_hasil().tampil() and akar.benih() == benih_hasil, "back Android di layar hasil diabaikan: tidak jeda, hasil tetap, seed tetap")
	_langkah(akar, 10)
	check((catatan["selesai"] as int) == 1 and akar.rute_sudah_selesai(), "sinyal rute_selesai tetap tepat sekali sesudah jeda dan lanjut")
	_bersihkan(akar)


## Menaruh sepeda dekat pelanggan terakhir (ada sasaran bantu), memakai keadaan sepeda langsung tanpa membuka kunci akhir rute.
func _taruh_di_dekat_pelanggan_terakhir(akar: RuteMain) -> void:
	var sepeda: SepedaUji = _sepeda(akar)
	sepeda.jarak_ubin = 220.0
	akar.koran = SisaKoran.awal(30)


func _test_akhir_koran_terbang_dinilai() -> void:
	_judul.call("Scene rute: koran yang sudah terbang saat garis akhir tercapai tetap mendarat dan dinilai (AC-14)")
	var akar: RuteMain = await _siapkan()
	var catatan: Dictionary = _catat(akar)
	_nyalakan_bantu(akar)
	_taruh_sepeda(akar, 3.0, 0.0, 0.0, 221.0)
	_tap(_tap_seberang(akar))
	var lempar: Array = catatan["lempar"] as Array
	check(lempar.size() == 1, "tap bantu 5 ubin sebelum pelanggan terakhir (maju 226) melempar")
	if lempar.size() == 1:
		var l: ThrowSolver.Lintasan = lempar[0]
		# Sepeda dipindah ke garis akhir selagi koran terbang: rute selesai, koran tetap mendarat dan dinilai.
		_sepeda(akar).jarak_ubin = PANJANG_RUTE
		_langkah(akar, 1)
		check(akar.rute_sudah_selesai() and (catatan["selesai"] as int) == 1, "garis akhir tercapai selagi koran terbang")
		check(akar.koran_terbang().size() == 1, "koran masih terbang saat rute selesai")
		var hasil_saat_terbang: bool = false
		for i: int in range(60):
			if not akar.koran_terbang().is_empty() and not akar.koran_terbang()[0].mendarat:
				hasil_saat_terbang = hasil_saat_terbang or akar.hasil_tampil()
			_langkah(akar, 1)
			if akar.koran_terbang().is_empty() or akar.koran_terbang()[0].mendarat:
				break
		check(not hasil_saat_terbang, "layar hasil tidak terbuka selama koran masih terbang (O-11)")
		var k: KoranLempar.Koran = _sampai_mendarat(akar, catatan, l)
		check(k != null and k.hasil == ZonaSasaran.Hasil.KOTAK_SURAT and k.penanda == ZonaSasaran.Penanda.CENTANG, "koran mendarat sesudah akhir rute dan dinilai KOTAK_SURAT centang (pelanggan terakhir)")
		check((catatan["mendarat"] as Array).size() == 1 and (catatan["selesai"] as int) == 1, "satu pendaratan dan satu sinyal rute_selesai")
	_bersihkan(akar)


func _test_main_lagi() -> void:
	_judul.call("Scene rute: Main lagi memakai seed berikutnya dan mengembalikan keadaan (AC-13, AC-14)")
	var akar: RuteMain = await _siapkan()
	var catatan: Dictionary = _catat(akar)
	var sepeda: SepedaUji = _sepeda(akar)
	_nyalakan_bantu(akar)
	_taruh_sepeda(akar, 3.0, 0.0, 0.0, 70.0)
	_tap(_tap_seberang(akar))
	_langkah(akar, 5)
	var sisa: int = akar.koran.sisa
	check(sisa == 29 and akar.koran_terbang().size() == 1, "kontrol: satu koran dilempar sebelum Main lagi")
	sepeda.jarak_ubin = PANJANG_RUTE
	check(_sampai_hasil(akar) and akar.rute_sudah_selesai(), "kontrol: rute selesai dan layar hasil terbuka")
	akar.layar_hasil().tombol_main_lagi().pressed.emit()
	check(akar.benih() == SEED_BERIKUT, "Main lagi: seed + 1 = 20261017 (dapat %d)" % akar.benih())
	var ids: Array[String] = []
	for s: SegmenRute in akar.rute().segmen:
		ids.append(s.id)
	check(ids == ID_SEGMEN_BERIKUT and ids != ID_SEGMEN_DEV, "rute baru = literal seed 20261017, beda dari rute lama: %s" % [ids])
	check(not akar.rute_sudah_selesai() and not akar.panel_akhir().tampil() and not akar.layar_hasil().tampil(), "banner dan layar hasil tersembunyi lagi")
	check(sepeda.jarak_ubin == 0.0 and sepeda.kecepatan_ud == Config.KECEPATAN_SANTAI_UD and sepeda.lateral_ubin == 0.0 and sepeda.stamina() == Config.STAMINA_MAKS, "sepeda kembali ke awal: jarak 0, santai, lateral 0, stamina penuh")
	check(akar.koran.sisa == 30 and akar.koran.penuh == 30 and akar.koran_terbang().is_empty(), "koran kembali 30, koran terbang dibuang")
	check((catatan["disusun"] as int) == 1, "rute_disusun dipancarkan sekali untuk rute baru")
	check(akar.daur().indeks_tampil() == _indeks_harapan(akar.rute(), 0.0), "rumah digambar ulang untuk awal rute baru")
	check(akar.medan() != null and (akar.medan() as MedanKoran).adalah_rute(), "medan penilaian dibangun ulang dari rute baru")
	_langkah(akar, 30)
	check(not akar.rute_sudah_selesai() and (catatan["selesai"] as int) == 1, "rute baru berjalan normal, sinyal lama tidak terulang")
	sepeda.jarak_ubin = PANJANG_RUTE
	_langkah(akar, 3)
	check((catatan["selesai"] as int) == 2 and akar.rute_sudah_selesai(), "rute baru bisa selesai lagi: sinyal kedua tepat sekali")
	check(_sampai_hasil(akar), "rute baru: layar hasil terbuka lagi")
	_bersihkan(akar)


## Ketukan sentuh sungguhan (bukan `pressed.emit()`) pada tombol "Main lagi" layar hasil lewat jalur `TombolSentuh` (QA run 3A iterasi 1;
## tombol pindah ke layar hasil di run fase3c-hud-hasil, O-11).
func _test_main_lagi_ketuk() -> void:
	_judul.call("Scene rute: ketukan sentuh pada tombol Main lagi layar hasil menyusun ulang rute dengan seed berikutnya (AC-13, O-11)")
	var akar: RuteMain = await _siapkan()
	var seed_awal: int = akar.benih()
	_sepeda(akar).jarak_ubin = PANJANG_RUTE
	check(_sampai_hasil(akar), "kontrol: layar hasil terbuka")
	await _tree.process_frame
	await _tree.process_frame
	var tombol: Rect2 = akar.layar_hasil().rect_tombol()
	check(tombol.size.x >= 42.0 and tombol.size.y >= 42.0, "kontrol: tombol Main lagi >= 42 px game (%s)" % tombol.size)
	_tap(tombol.position + tombol.size / 2.0, 5)
	await _tree.process_frame
	check(seed_awal == SEED_DEV and akar.benih() == SEED_BERIKUT, "ketukan sentuh pada tombol memakai seed berikutnya (%d -> %d)" % [seed_awal, akar.benih()])
	check(not akar.layar_hasil().tampil() and not akar.panel_akhir().tampil(), "layar hasil dan banner tersembunyi lagi sesudah ketukan")
	_bersihkan(akar)


## QA-006 (b): rute gagal dimuat tidak membiarkan pemain menatap jalan kosong; banner `RUTE_GAGAL_MUAT` tampil, bukan "Rute selesai".
func _test_galat_muat_terlihat() -> void:
	_judul.call("Scene rute: rute gagal dimuat menampilkan pesan galat di layar (QA-006)")
	var akar: RuteMain = await _siapkan()
	check(tr("RUTE_GAGAL_MUAT") == "Rute gagal dimuat", "kunci RUTE_GAGAL_MUAT diterjemahkan: %s" % tr("RUTE_GAGAL_MUAT"))
	check(akar.galat_rute().is_empty() and not akar.panel_akhir().tampil(), "kontrol: rute baik, tanpa galat dan tanpa banner")
	check(akar.lapor_galat_ke_log, "galat rute dicatat ke log developer secara bawaan (push_error); hanya tes yang mematikannya (QA-008 run 3A)")
	akar.lapor_galat_ke_log = false
	var pustaka: Array[SegmenRute] = akar._pustaka
	var rusak: Array[SegmenRute] = [pustaka[0]]
	akar._pustaka = rusak
	akar.main_lagi()
	check(not akar.galat_rute().is_empty() and akar.rute().rumah.is_empty(), "pustaka tidak cukup: galat tercatat dan rute kosong")
	check(akar.panel_akhir().tampil() and akar.panel_akhir().teks_banner() == "Rute gagal dimuat", "banner galat tampil dengan teks RUTE_GAGAL_MUAT (dapat '%s')" % akar.panel_akhir().teks_banner())
	check(akar.panel_akhir().tombol_tampil() and akar.panel_akhir().teks_tombol() == "Main lagi", "banner galat membawa tombol Main lagi (mencoba seed berikutnya)")
	check(not (_anak(akar, "KontrolTouch") as KontrolTouch).is_processing_input(), "galat: kontrol sentuh tidak membaca sentuhan (tombol galat di zona swipe bukan tap atau swipe)")
	_langkah(akar, 10)
	check(akar.panel_akhir().teks_banner() == "Rute gagal dimuat" and not akar.rute_sudah_selesai(), "rute kosong tidak langsung dinyatakan selesai (banner tetap galat)")
	akar._pustaka = pustaka
	akar.main_lagi()
	check(akar.galat_rute().is_empty() and not akar.panel_akhir().tampil() and (_anak(akar, "KontrolTouch") as KontrolTouch).is_processing_input(), "Main lagi dengan pustaka pulih: banner hilang, kontrol sentuh aktif lagi")
	_sepeda(akar).jarak_ubin = akar.rute().panjang_ubin
	_langkah(akar, 3)
	check(akar.rute_sudah_selesai() and akar.panel_akhir().teks_banner() == "Rute selesai", "rute pulih selesai dengan banner \"Rute selesai\" (bukan teks galat)")
	_bersihkan(akar)


## QA-006 (c): semua PNG jenis rumah rute dimuat di `atur_rute`, bukan di tengah frame saat rumah pertama jenis itu muncul.
func _test_tekstur_dimuat_di_atur_rute() -> void:
	_judul.call("Scene rute: PNG semua jenis rumah rute dimuat saat rute diatur (QA-006)")
	var akar: RuteMain = await _siapkan()
	var jenis: Dictionary = {}
	for r: RouteBuilder.RumahRute in akar.rute().rumah:
		jenis[SpriteRumah.nama_rumah(r)] = true
	check(jenis.size() >= 6, "kontrol: rute memakai banyak jenis sprite rumah (%d)" % jenis.size())
	check(akar.daur().jumlah_tekstur_dimuat() == jenis.size(), "sebelum sepeda bergerak, tekstur dimuat = jenis sprite di rute (%d dari %d)" % [akar.daur().jumlah_tekstur_dimuat(), jenis.size()])
	var sebelum: int = akar.daur().jumlah_tekstur_dimuat()
	var sepeda: SepedaUji = _sepeda(akar)
	for jarak: int in range(0, 237, 4):
		sepeda.jarak_ubin = float(jarak)
		akar.perbarui(0.0)
	check(akar.daur().jumlah_tekstur_dimuat() == sebelum, "tidak ada tekstur baru dimuat sepanjang rute (%d)" % akar.daur().jumlah_tekstur_dimuat())
	_bersihkan(akar)


# --- Jeda (AC-16) ---

func _test_jeda() -> void:
	_judul.call("Scene rute: jeda membekukan sepeda dan koran terbang, tanpa lanjut otomatis (AC-16)")
	var akar: RuteMain = await _siapkan()
	var catatan: Dictionary = _catat(akar)
	var sepeda: SepedaUji = _sepeda(akar)
	_nyalakan_bantu(akar)
	_taruh_sepeda(akar, 3.0, 0.0, 0.0, 70.0)
	_tap(_tap_seberang(akar))
	_langkah(akar, 5)
	var koran: KoranLempar.Koran = akar.koran_terbang()[0]
	var waktu: float = koran.detik
	var jarak: float = sepeda.jarak_ubin
	akar.minta_jeda()
	check(akar.sedang_jeda() and _tree.paused, "tombol jeda membuka layar jeda dan menjeda pohon")
	_langkah(akar, 120)
	check(sepeda.jarak_ubin == jarak and akar.koran_terbang().size() == 1 and akar.koran_terbang()[0].detik == waktu, "dua detik jeda: sepeda dan koran terbang membeku")
	akar.perbarui(0.016)
	akar._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check(akar.sedang_jeda(), "RESUMED tidak melanjutkan otomatis")
	akar.minta_lanjut()
	_langkah(akar, 1, 0.016)
	check(sepeda.jarak_ubin == jarak, "langkah pertama sesudah lanjut ber-dt 0 (jarak tidak berubah)")
	_langkah(akar, 1, 0.016)
	check(sepeda.jarak_ubin > jarak and akar.koran_terbang()[0].detik > waktu, "langkah berikutnya normal: sepeda dan koran maju")
	akar._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(akar.sedang_jeda(), "kehilangan fokus menjeda")
	akar.minta_lanjut()
	check((catatan["selesai"] as int) == 0, "jeda tidak memancarkan rute_selesai")
	_bersihkan(akar)


# --- Penutup pemain (AC-15) ---

func _test_penutup() -> void:
	_judul.call("Scene rute: satu penerap penutup menurunkan alfa objek yang menutupi pemain (AC-15)")
	var akar: RuteMain = await _siapkan()
	var penerap: PenerapPenutup = akar.penerap_penutup()
	var sepeda: SepedaUji = _sepeda(akar)
	check(penerap != null and penerap.get_parent() == akar, "ada tepat satu penerap penutup di scene rute")
	var pencacah: int = 0
	for anak: Node in akar.find_children("*", "PenerapPenutup", true, false):
		pencacah += 1
	check(pencacah == 1, "hanya satu simpul PenerapPenutup di seluruh scene (%d)" % pencacah)
	_taruh_sepeda(akar, 3.0, 0.5, 0.0, 100.0)
	# Rumah rute di jendela daur terdaftar ke penerap yang sama; tidak ada yang menutupi pemain di jalan resmi (D-8 run 3A).
	check(penerap.jumlah() == akar.daur().jumlah_rumah() + akar.rintangan_daur().jumlah_tampil() + _jumlah_dekor_penutup(akar) + 1 and akar.daur().jumlah_rumah() > 0, "rumah, rintangan, pohon/lampu (run fase5b B2) di jendela daur, dan satu portal garis finish terdaftar ke penerap (%d)" % penerap.jumlah())
	var menutupi_nyata: int = 0
	for lateral: float in [-1.0, 0.0, 1.0]:
		for maju: int in range(0, 237, 2):
			var k: BikeMotion.Keadaan = sepeda.keadaan.salin()
			k.lateral_ubin = lateral
			sepeda.keadaan = k
			sepeda.jarak_ubin = float(maju)
			akar.perbarui(0.0)
			# Pohon dan lampu sisi dekat memang semi-transparan di lajur bila tajuk atau lengannya menimpa pemain (iterasi 2 run fase5b, P-6; dibuktikan piksel di `TesDekorPiksel`); yang dihitung di sini rumah dan rintangan.
			var dekor_menutupi: int = 0
			for i: int in akar.dekor_daur().indeks_tampil():
				if akar.dekor_daur().sprite_dekor(i).modulate.a < 1.0:
					dekor_menutupi += 1
			menutupi_nyata += penerap.jumlah_menutupi() - dekor_menutupi
	check(menutupi_nyata == 0, "rute nyata: tidak ada rumah atau rintangan yang menutupi pemain di lebar jalan resmi (0 kejadian dari 357 posisi), dapat %d" % menutupi_nyata)
	# Objek uji yang menutupi: tapak 3 x 6 mulai lateral 1,0 dan maju 3 di belakang sampai 3 di depan pemain, tinggi 2,0.
	_taruh_sepeda(akar, 3.0, 0.5, 0.0, 100.0)
	var gambar: Sprite2D = Sprite2D.new()
	akar.daur().add_child(gambar)
	penerap.daftarkan(gambar, PenutupPemain.buat(Rect2(1.0, 97.0, 3.0, 6.0), 2.0, "uji"))
	akar.perbarui(0.0)
	check(is_equal_approx(gambar.modulate.a, 0.45) and penerap.jumlah_menutupi() == 1, "objek yang menutupi: alfa 0,45 lewat langkah scene (tanpa memanggil terapkan langsung), dapat %.2f" % gambar.modulate.a)
	var k2: BikeMotion.Keadaan = sepeda.keadaan.salin()
	k2.lateral_ubin = -1.0
	sepeda.keadaan = k2
	akar.perbarui(0.0)
	check(gambar.modulate.a == 1.0 and penerap.jumlah_menutupi() == 0, "pemain di lateral -1,0 (tepat di tepi): objek tidak menutupi, alfa 1,0")
	var k3: BikeMotion.Keadaan = sepeda.keadaan.salin()
	k3.lateral_ubin = -0.9
	sepeda.keadaan = k3
	akar.perbarui(0.0)
	check(is_equal_approx(gambar.modulate.a, 0.45), "pemain di lateral -0,9: menutupi lagi (alfa 0,45)")
	penerap.lepas(gambar)
	check(gambar.modulate.a == 1.0 and penerap.jumlah() == akar.daur().jumlah_rumah() + akar.rintangan_daur().jumlah_tampil() + _jumlah_dekor_penutup(akar) + 1, "objek dilepas dari penerap: alfa kembali 1,0")
	gambar.queue_free()
	_bersihkan(akar)


# --- Tata letak banner dan tombol (ui-scenes) ---

func _test_tata_letak_akhir(kasus: Array) -> void:
	var lebar: int = kasus[2]
	_judul.call("Scene rute: banner akhir dan banner galat tidak menutupi HUD rute, tombol galat >= 42 px, lebar %d (ui-scenes)" % lebar)
	var akar: RuteMain = await _siapkan(Vector2i(kasus[0], kasus[1]))
	akar.panel_akhir().tampilkan_galat()
	await _tree.process_frame
	await _tree.process_frame
	var hud: HudRute = akar.hud_rute()
	var tombol: Rect2 = akar.panel_akhir().rect_tombol()
	var banner: Rect2 = akar.panel_akhir().rect_banner()
	var layar: Rect2 = Rect2(Vector2.ZERO, Vector2(float(lebar), 360.0))
	for kidal: bool in [false, true]:
		check(not banner.intersects(TouchZones.rect_stick(lebar, kidal), true), "kidal %s: banner (dan tombol galat di dalamnya) di luar zona stick (%s)" % [kidal, banner])
	var menyentuh: Array[String] = []
	var simpul: Node = _anak(akar, "Banner")
	while simpul != null and simpul != akar.panel_akhir():
		if simpul is Control and (simpul as Control).mouse_filter != Control.MOUSE_FILTER_IGNORE:
			menyentuh.append(simpul.name)
		simpul = simpul.get_parent()
	check(menyentuh.is_empty(), "banner dan wadahnya mengabaikan sentuhan (tidak mencuri swipe di zona swipe): %s" % [menyentuh])
	check(layar.encloses(tombol) and layar.encloses(banner) and banner.encloses(tombol), "tombol galat di dalam banner, keduanya di dalam viewport %d x 360" % lebar)
	check(tombol.size.y >= float(Config.HUD_TOMBOL_TINGGI_PX) and tombol.size.x >= float(Config.HUD_TOMBOL_LEBAR_PX), "ukuran tombol >= tombol HUD (%s)" % tombol.size)
	var hud_rect: Array = [["tombol jeda", hud.rect_tombol_jeda()], ["panel progres", hud.rect_panel_progres()], ["panel koin", hud.rect_panel_koin()], ["panel skor", hud.rect_panel_skor()], ["radar seberang", hud.rect_radar_seberang()], ["radar dekat", hud.rect_radar_dekat()], ["panel kecepatan", hud.rect_panel_kecepatan()], ["panel koran", hud.rect_panel_koran()], ["tombol bel", hud.rect_tombol_bel()]]
	for pasang: Array in hud_rect:
		check(not banner.intersects(pasang[1], true), "banner tidak menutupi %s %s" % [pasang[0], pasang[1]])
	akar.panel_akhir().tampilkan(true)
	await _tree.process_frame
	var banner_selesai: Rect2 = akar.panel_akhir().rect_banner()
	for pasang: Array in hud_rect:
		check(not banner_selesai.intersects(pasang[1], true), "banner Rute selesai tidak menutupi %s" % pasang[0])
	_bersihkan(akar)


## Banyaknya pohon dan lampu dekor yang sedang digambar (hanya keduanya di sisi dekat yang didaftarkan ke penerap penutup, run fase5b-tembok-dekor B2 dan iterasi 2).
func _jumlah_dekor_penutup(akar: RuteMain) -> int:
	var jumlah: int = 0
	for i: int in akar.dekor_daur().indeks_tampil():
		var butir: RouteBuilder.DekorItem = akar.rute().dekor[i]
		if DekorRute.menutupi(butir.jenis, butir.varian, butir.sisi):
			jumlah += 1
	return jumlah
