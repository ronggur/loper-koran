class_name TesKoranSprite
extends RefCounted
## Tes run fase5a-pasang-aset-gelombang1 bagian B, koran dari sprite (AC-8 sampai AC-12, AC-17 bagian sprite, D-3): definisi sprite (`DefSprite`) = JSON aset, pemilih frame bayangan,
## pemetaan permukaan mendarat, field turunan `KoranLempar.Koran` yang tidak mengubah penilaian (1000 lemparan acak berseed terhadap penilaian ulang dari `ZonaSasaran`), koran
## putar, bayangan, dan koran tergeletak di scene rute sungguhan dengan lemparan nyata, koran terlipat di rumah terantar, dan rujukan aset yang belum dipasang.
##
## Harapan ditulis sebagai literal atau dihitung dengan cara lain dari kode produksi: tabel sprite dari JSON dan literal, proyeksi iso ditulis ulang (layar = ((x - y) x 32, (x + y) x 16),
## y dunia = -maju), geometri zona dari literal `Config.JALAN_UJI_*` (teras seberang [-3,0; 0,0; 0,5; 1,25] relatif awal kavling), dan tabel permukaan jawaban eksplisit.
## Rute seed bawaan 20261016 (ditulis dari data segmen): per_buka_01@6, @10 (bukan pemberi tip), dan @18 (pemberi tip) adalah rumah pelanggan sisi seberang.

const BERKAS_RUTE: String = "res://scenes/rute/rute.tscn"
const BERKAS_JALAN_UJI: String = "res://scenes/dev/jalan_uji.tscn"
const FOLDER_RUTE: String = "res://assets/data/routes/perumahan"
const DT: float = 1.0 / 60.0
const LEBAR: int = 780
## [nama, folder, lebar sel, tinggi sel, frame, pijak x, pijak y]: ditulis dari `ground_anchor`, `cell`, dan `frames` di JSON aset (D-1).
const TABEL: Array = [
	["prop_koran_putar", "props", 10, 10, 4, 5, 5],
	["prop_koran_bayangan", "props", 12, 6, 3, 6, 3],
	["prop_koran_teras", "props", 12, 10, 1, 6, 6],
	["prop_koran_rumput", "props", 12, 10, 1, 6, 6],
	["prop_koran_kotak_surat", "props", 8, 7, 1, -3, 19],
	["prop_koran_terlipat", "props", 14, 10, 1, 7, 5],
	["vfx_debu_roda", "vfx", 18, 10, 6, 14, 7],
	["vfx_garis_kecepatan_a", "vfx", 28, 14, 1, 27, 7],
	["vfx_garis_kecepatan_b", "vfx", 28, 14, 1, 27, 7],
	["vfx_garis_kecepatan_c", "vfx", 28, 14, 1, 27, 7],
	["vfx_bintang_kena", "vfx", 15, 15, 6, 7, 7],
	["vfx_koin_tip", "vfx", 16, 26, 6, 8, 24],
	["mission_kilau", "vfx", 9, 9, 2, 4, 4],
]
## Berkas lama yang tetap ada di folder aset bersama sprite yang dipasang.
const BERKAS_LAMA_PROPS: Array[String] = ["prop_kotak_surat", "prop_kotak_surat_bukan"]

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
	_test_def_sprite_sama_dengan_json()
	_test_def_sprite_murni()
	_test_frame_bayangan()
	_test_permukaan_tabel()
	_test_permukaan_zona_nyata()
	_test_titik_diam_kotak_surat()
	_test_field_turunan_tidak_mengubah_penilaian()
	_test_item_murni()
	_test_skor_60_rute_tetap()
	_test_rujukan_sprite_dan_isi_folder()
	await _test_koran_terbang_di_scene()
	await _test_mendarat_empat_permukaan()
	await _test_terlipat_di_scene()
	await _test_jalan_uji_tetap_placeholder()


# --- Pembantu ---

func _siapkan() -> RuteMain:
	_tree.root.size = Vector2i(2340, 1080)
	var akar: RuteMain = (load(BERKAS_RUTE) as PackedScene).instantiate() as RuteMain
	_tree.root.add_child(akar)
	await _tree.process_frame
	await _tree.process_frame
	akar.set_process(false)
	(akar.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = false
	(akar.find_child("LoperAgen", true, false) as LoperSprite).set_process(false)
	return akar


func _bersihkan(akar: AdeganJalan) -> void:
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


func _baca_json(jalur: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(jalur)) as Dictionary


## Layar (piksel game, dibulatkan) titik dunia (x lateral, y dunia = -maju) dari rumus iso 2:1 ditulis ulang tes.
func _layar(x: float, y_dunia: float) -> Vector2:
	return Vector2(roundf((x - y_dunia) * 32.0), roundf((x + y_dunia) * 16.0))


func _rumah(akar: RuteMain, id: String) -> RouteBuilder.RumahRute:
	for r: RouteBuilder.RumahRute in akar.rute().rumah:
		if r.id == id:
			return r
	return null


func _item_nama(daftar: Array[DefSprite.Item]) -> Array[String]:
	var hasil: Array[String] = []
	for i: DefSprite.Item in daftar:
		hasil.append(i.nama)
	return hasil


## Melempar koran biasa dari sepeda di `maju` (santai, lateral 0,5) ke titik jalan `titik_jalan` (x = lateral, y = maju) dengan lintasan yang dibidik ke titik itu (pencari kekuatan dan arah
## yang sama dengan mode bantu), sampai mendarat. Mengembalikan koran pada langkah ia mendarat; null bila titik tak terjangkau.
func _lempar_ke_titik(akar: RuteMain, maju: float, titik_jalan: Vector2, mendarat: Array[KoranLempar.Koran], lateral: float = 0.5) -> KoranLempar.Koran:
	_taruh(akar, 3.0, lateral, maju)
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


## Melempar ke pusat kotak surat rumah `id_rumah` (lintasan pencari mode bantu dipakai sebagai lemparan biasa), sampai mendarat.
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


# --- Definisi sprite = JSON aset (AC-3, AC-8) ---

func _test_def_sprite_sama_dengan_json() -> void:
	_judul.call("DefSprite: tabel Config sama dengan literal D-1, JSON aset, dan ukuran PNG untuk 13 sprite terpasang (AC-3, D-3 sampai D-6)")
	check(DefSprite.NAMA.size() == TABEL.size() and TABEL.size() == 13, "13 sprite terpasang (daftar D-1)")
	for baris: Array in TABEL:
		var nama: String = baris[0]
		var folder: String = baris[1]
		var json: Dictionary = _baca_json("res://assets/sprites/%s/%s.json" % [folder, nama])
		var sel: Array = json["cell"]
		var pijak: Array = json["ground_anchor"]
		check(DefSprite.NAMA.has(nama) and DefSprite.jalur_png(nama) == "res://assets/sprites/%s/%s.png" % [folder, nama], "%s: nama dikenal dan jalur PNG di folder %s" % [nama, folder])
		check(int(sel[0]) == baris[2] and int(sel[1]) == baris[3] and int(json["frames"]) == baris[4] and int(pijak[0]) == baris[5] and int(pijak[1]) == baris[6], "%s: literal tes sama dengan JSON (sel %s, frame %s, pijak %s)" % [nama, sel, json["frames"], pijak])
		check(DefSprite.sel(nama) == Vector2i(baris[2], baris[3]) and DefSprite.jumlah_frame(nama) == baris[4] and DefSprite.pijak(nama) == Vector2i(baris[5], baris[6]), "%s: DefSprite (Config) = JSON: sel %s, %d frame, pijak %s" % [nama, DefSprite.sel(nama), DefSprite.jumlah_frame(nama), DefSprite.pijak(nama)])
		var tekstur: Texture2D = load(DefSprite.jalur_png(nama)) as Texture2D
		check(tekstur != null and tekstur.get_width() == baris[2] * baris[4] and tekstur.get_height() == baris[3], "%s: PNG %dx%d = sel x frame" % [nama, tekstur.get_width() if tekstur != null else -1, tekstur.get_height() if tekstur != null else -1])
	check(DefSprite.data("tidak_ada").is_empty() and DefSprite.sel("tidak_ada") == Vector2i.ZERO and DefSprite.jumlah_frame("tidak_ada") == 0 and DefSprite.region("tidak_ada", 0) == Rect2i(), "nama tidak dikenal: kosong, tanpa error")
	# Laju animasi dan kilau: sama dengan JSON bila bukan berpacu detik tersendiri.
	check(_baca_json("res://assets/sprites/props/prop_koran_putar.json")["fps"] == int(Config.KORAN_PUTAR_FPS) and _baca_json("res://assets/sprites/vfx/vfx_debu_roda.json")["fps"] == int(Config.UMPAN_DEBU_SPRITE_FPS), "fps koran putar dan debu roda sama dengan JSON (12)")
	check(_baca_json("res://assets/sprites/vfx/vfx_bintang_kena.json")["fps"] == int(Config.UMPAN_BINTANG_FPS) and _baca_json("res://assets/sprites/vfx/vfx_koin_tip.json")["fps"] == int(Config.UMPAN_KOIN_TIP_FPS), "fps bintang kena (15) dan koin tip (10) sama dengan JSON")


func _test_def_sprite_murni() -> void:
	_judul.call("DefSprite: region, pojok, frame loop, dan frame sekali main (literal)")
	check(DefSprite.region("prop_koran_putar", 0) == Rect2i(0, 0, 10, 10) and DefSprite.region("prop_koran_putar", 2) == Rect2i(20, 0, 10, 10) and DefSprite.region("prop_koran_putar", 5) == Rect2i(10, 0, 10, 10) and DefSprite.region("prop_koran_putar", -1) == Rect2i(30, 0, 10, 10), "region koran putar: frame 2 di x=20, frame 5 memutar ke 1, -1 ke 3")
	check(DefSprite.region("vfx_koin_tip", 3) == Rect2i(48, 0, 16, 26) and DefSprite.region("mission_kilau", 1) == Rect2i(9, 0, 9, 9), "region koin tip frame 3 dan kilau frame 1")
	check(DefSprite.pojok("prop_koran_putar", Vector2(100, 50)) == Vector2(95, 45) and DefSprite.pojok("vfx_koin_tip", Vector2(96, -16)) == Vector2(88, -40) and DefSprite.pojok("prop_koran_kotak_surat", Vector2(10, 20)) == Vector2(13, 1), "pojok = titik - pijak (pijak negatif menggeser ke kanan atas)")
	check(DefSprite.pojok("prop_koran_teras", Vector2(10.4, 20.6)) == Vector2(4, 15), "pojok dibulatkan dulu ke piksel game")
	check(DefSprite.frame_loop(0.0, 12.0, 6) == 0 and DefSprite.frame_loop(0.09, 12.0, 6) == 1 and DefSprite.frame_loop(0.49, 12.0, 6) == 5 and DefSprite.frame_loop(0.51, 12.0, 6) == 0 and DefSprite.frame_loop(1.0, 12.0, 6) == 0, "frame loop 12 fps 6 frame: 0, 1, 5, memutar ke 0")
	check(DefSprite.frame_loop(-1.0, 12.0, 6) == 0 and DefSprite.frame_loop(NAN, 12.0, 6) == 0 and DefSprite.frame_loop(1.0, 0.0, 6) == 0 and DefSprite.frame_loop(1.0, 12.0, 0) == 0, "frame loop: waktu negatif, NaN, fps 0, jumlah 0 = frame 0")
	check(DefSprite.frame_sekali(0.0, 15.0, 6) == 0 and DefSprite.frame_sekali(0.07, 15.0, 6) == 1 and DefSprite.frame_sekali(0.39, 15.0, 6) == 5 and DefSprite.frame_sekali(0.5, 15.0, 6) == -1 and DefSprite.frame_sekali(5.0, 15.0, 6) == -1, "frame sekali main 15 fps 6 frame: 0, 1, 5, sesudahnya -1 (tidak berulang)")
	check(DefSprite.frame_sekali(-0.1, 15.0, 6) == -1 and DefSprite.frame_sekali(NAN, 15.0, 6) == -1 and DefSprite.frame_sekali(0.1, 0.0, 6) == -1, "frame sekali main: waktu negatif, NaN, fps 0 = -1")


# --- Bayangan menurut tinggi (AC-9) ---

func _test_frame_bayangan() -> void:
	_judul.call("SpriteKoran.frame_bayangan: tinggi 0 -> 10 px, maksimum -> 6 px, monoton, sama dengan lebar_bayangan_px (AC-9, D-3b)")
	# lebar = clamp(round(10 - 2 x tinggi), 6, 10); frame terdekat dari lebar [10, 8, 6], selisih sama = lebih lebar.
	var tabel: Array = [[0.0, 10, 0], [0.2, 10, 0], [0.5, 9, 0], [0.75, 9, 0], [0.76, 8, 1], [1.0, 8, 1], [1.25, 8, 1], [1.5, 7, 1], [1.75, 7, 1], [1.76, 6, 2], [2.0, 6, 2], [9.0, 6, 2], [-1.0, 10, 0], [NAN, 10, 0], [INF, 10, 0]]
	for baris: Array in tabel:
		var tinggi: float = baris[0]
		check(KoranLempar.lebar_bayangan_px(tinggi) == baris[1] and SpriteKoran.frame_bayangan(tinggi) == baris[2], "tinggi %s: lebar %d, frame %d (dapat lebar %d, frame %d)" % [tinggi, baris[1], baris[2], KoranLempar.lebar_bayangan_px(tinggi), SpriteKoran.frame_bayangan(tinggi)])
	var sebelumnya: int = 0
	var monoton: bool = true
	var sama: bool = true
	var tinggi_sapu: float = 0.0
	var lebar_frame: Array[int] = [10, 8, 6]
	while tinggi_sapu <= 5.0:
		var frame: int = SpriteKoran.frame_bayangan(tinggi_sapu)
		if frame < sebelumnya:
			monoton = false
		sebelumnya = frame
		# Oracle: frame yang lebarnya paling dekat dengan lebar_bayangan_px (tie ke yang lebih lebar).
		var lebar: int = KoranLempar.lebar_bayangan_px(tinggi_sapu)
		var terbaik: int = 0
		for i: int in range(1, 3):
			if absi(lebar - lebar_frame[i]) < absi(lebar - lebar_frame[terbaik]):
				terbaik = i
		if frame != terbaik:
			sama = false
		tinggi_sapu += 0.01
	check(monoton, "frame bayangan tidak pernah kembali ke frame lebih lebar saat tinggi naik (sapuan 0 sampai 5 ubin)")
	check(sama, "frame bayangan selalu frame dengan lebar terdekat ke KoranLempar.lebar_bayangan_px (tanpa rumus kedua)")


# --- Pemetaan permukaan (AC-10) ---

func _test_permukaan_tabel() -> void:
	_judul.call("PermukaanKoran.pilih: tiap jenis zona x pelanggan seberang x kolom ubin, dan tanpa zona (oracle tabel eksplisit, AC-10)")
	var P: Dictionary = {"K": PermukaanKoran.Permukaan.KOTAK_SURAT, "T": PermukaanKoran.Permukaan.TERAS, "R": PermukaanKoran.Permukaan.RUMPUT}
	# Jawaban eksplisit per jenis zona: [jenis, pelanggan_seberang] -> permukaan (sama untuk semua enam kolom, karena zona yang menentukan).
	var jawaban: Array = [
		[ZonaSasaran.Jenis.KOTAK_SURAT, true, "K"], [ZonaSasaran.Jenis.KOTAK_SURAT, false, "T"],
		[ZonaSasaran.Jenis.TERAS, true, "T"], [ZonaSasaran.Jenis.TERAS, false, "T"],
		[ZonaSasaran.Jenis.JENDELA, true, "T"], [ZonaSasaran.Jenis.JENDELA, false, "T"],
		[ZonaSasaran.Jenis.HALAMAN, true, "R"], [ZonaSasaran.Jenis.HALAMAN, false, "R"],
	]
	var cocok: int = 0
	for baris: Array in jawaban:
		for kolom: int in range(6):
			if PermukaanKoran.pilih(true, baris[0], baris[1], kolom as JalanDaur.Kolom) == P[baris[2]]:
				cocok += 1
			else:
				check(false, "zona %s pelanggan_seberang %s kolom %d: harapan %s" % [ZonaSasaran.Jenis.keys()[baris[0]], baris[1], kolom, baris[2]])
	check(cocok == 8 * 6, "48 kombinasi zona x pelanggan seberang x kolom cocok tabel")
	# Tanpa zona: rumput di dua kolom rumput, lantai keras di aspal dan trotoar.
	var tanpa: Array = [
		[JalanDaur.Kolom.RUMPUT_SEBERANG, "R"], [JalanDaur.Kolom.TROTOAR_SEBERANG, "T"], [JalanDaur.Kolom.ASPAL_SEBERANG, "T"],
		[JalanDaur.Kolom.ASPAL_DEKAT, "T"], [JalanDaur.Kolom.TROTOAR_DEKAT, "T"], [JalanDaur.Kolom.RUMPUT_DEKAT, "R"],
	]
	for baris: Array in tanpa:
		check(PermukaanKoran.pilih(false, ZonaSasaran.Jenis.KOTAK_SURAT, true, baris[0]) == P[baris[1]] and PermukaanKoran.pilih(false, ZonaSasaran.Jenis.HALAMAN, false, baris[0]) == P[baris[1]], "tanpa zona di kolom %s: %s (jenis dan pelanggan diabaikan)" % [JalanDaur.Kolom.keys()[baris[0]], baris[1]])
	check(PermukaanKoran.nama_sprite(PermukaanKoran.Permukaan.KOTAK_SURAT) == "prop_koran_kotak_surat" and PermukaanKoran.nama_sprite(PermukaanKoran.Permukaan.TERAS) == "prop_koran_teras" and PermukaanKoran.nama_sprite(PermukaanKoran.Permukaan.RUMPUT) == "prop_koran_rumput", "nama sprite per permukaan")
	# Kolom dari titik: aspal dan trotoar di kedua sisi lantai keras, rumput di |x| >= 2.
	check(JalanDaur.kolom_di(-0.5) == JalanDaur.Kolom.ASPAL_SEBERANG and JalanDaur.kolom_di(-1.5) == JalanDaur.Kolom.TROTOAR_SEBERANG and JalanDaur.kolom_di(-3.5) == JalanDaur.Kolom.RUMPUT_SEBERANG, "kontrol: kolom di -0,5 aspal, -1,5 trotoar, -3,5 rumput")


func _test_permukaan_zona_nyata() -> void:
	_judul.call("PermukaanKoran.dari_zona: zona nyata (seberang dan dekat, pelanggan dan bukan, semua jenis) dan null")
	var kolom: JalanDaur.Kolom = JalanDaur.Kolom.RUMPUT_SEBERANG
	check(PermukaanKoran.dari_zona(null, kolom) == PermukaanKoran.Permukaan.RUMPUT and PermukaanKoran.dari_zona(null, JalanDaur.Kolom.ASPAL_DEKAT) == PermukaanKoran.Permukaan.TERAS, "zona null: menurut kolom")
	# Jawaban eksplisit per kombinasi [sisi, pelanggan, jenis] -> "K", "T", "R".
	var seberang_pelanggan: Array[ZonaSasaran.Zona] = ZonaSasaran.zona_rumah_seberang(0.0, true, 0, "x")
	var seberang_bukan: Array[ZonaSasaran.Zona] = ZonaSasaran.zona_rumah_seberang(0.0, false, 0, "x")
	var dekat_pelanggan: Array[ZonaSasaran.Zona] = ZonaSasaran.zona_rumah_dekat(0.0, true, 0, "x")
	var dekat_bukan: Array[ZonaSasaran.Zona] = ZonaSasaran.zona_rumah_dekat(0.0, false, 0, "x")
	var hasil: Dictionary = {}
	for z: ZonaSasaran.Zona in seberang_pelanggan:
		hasil["sp_%d" % z.jenis] = PermukaanKoran.dari_zona(z, kolom)
	for z: ZonaSasaran.Zona in seberang_bukan:
		hasil["sb_%d" % z.jenis] = PermukaanKoran.dari_zona(z, kolom)
	for z: ZonaSasaran.Zona in dekat_pelanggan:
		hasil["dp_%d" % z.jenis] = PermukaanKoran.dari_zona(z, kolom)
	for z: ZonaSasaran.Zona in dekat_bukan:
		hasil["db_%d" % z.jenis] = PermukaanKoran.dari_zona(z, kolom)
	var K: int = ZonaSasaran.Jenis.KOTAK_SURAT
	var T: int = ZonaSasaran.Jenis.TERAS
	var H: int = ZonaSasaran.Jenis.HALAMAN
	var J: int = ZonaSasaran.Jenis.JENDELA
	check(hasil["sp_%d" % K] == PermukaanKoran.Permukaan.KOTAK_SURAT, "kotak surat pelanggan seberang: bertumpu di kotak surat")
	check(hasil["sb_%d" % K] == PermukaanKoran.Permukaan.TERAS and hasil["dp_%d" % K] == PermukaanKoran.Permukaan.TERAS and hasil["db_%d" % K] == PermukaanKoran.Permukaan.TERAS, "kotak surat bukan pelanggan, dan di sisi dekat (kotak tidak digambar): teras di titik mendarat")
	check(hasil["sp_%d" % T] == PermukaanKoran.Permukaan.TERAS and hasil["sb_%d" % T] == PermukaanKoran.Permukaan.TERAS and hasil["dp_%d" % T] == PermukaanKoran.Permukaan.TERAS and hasil["db_%d" % T] == PermukaanKoran.Permukaan.TERAS, "teras (semua sisi dan status pelanggan): teras")
	check(hasil["sp_%d" % J] == PermukaanKoran.Permukaan.TERAS and hasil["sb_%d" % J] == PermukaanKoran.Permukaan.TERAS, "jendela seberang: teras")
	check(hasil["sp_%d" % H] == PermukaanKoran.Permukaan.RUMPUT and hasil["sb_%d" % H] == PermukaanKoran.Permukaan.RUMPUT and hasil["dp_%d" % H] == PermukaanKoran.Permukaan.RUMPUT and hasil["db_%d" % H] == PermukaanKoran.Permukaan.RUMPUT, "halaman (semua sisi dan status pelanggan): rumput")
	check(not hasil.has("dp_%d" % J), "kontrol: zona dekat tidak punya jendela")


func _test_titik_diam_kotak_surat() -> void:
	_judul.call("PermukaanKoran.titik_diam: kaki kotak surat sasaran = SpriteRumah.titik_kotak_surat_dunia untuk semua rumah pelanggan di 60 rute; selain itu titik mendarat")
	var pustaka: Array[SegmenRute] = PemuatRute.muat_folder(FOLDER_RUTE).segmen
	var jumlah: int = 0
	var cocok: int = 0
	for benih: int in range(1, 61):
		var rute: RouteBuilder.Rute = RouteBuilder.bangun(benih, pustaka).rute
		for r: RouteBuilder.RumahRute in rute.rumah:
			if r.sisi != LoperAnim.Sisi.SEBERANG:
				continue
			for z: ZonaSasaran.Zona in ZonaSasaran.zona_rumah(r):
				if z.jenis != ZonaSasaran.Jenis.KOTAK_SURAT:
					continue
				jumlah += 1
				var titik: Vector2 = PermukaanKoran.titik_diam(PermukaanKoran.Permukaan.KOTAK_SURAT, z, Vector2(9, 9))
				var harapan: Vector2 = SpriteRumah.titik_kotak_surat_dunia(r)
				if titik.distance_to(harapan) < 0.00001:
					cocok += 1
	check(jumlah > 300 and cocok == jumlah, "titik diam kotak surat = kaki kotak surat: %d dari %d rumah seberang (60 rute)" % [cocok, jumlah])
	var z0: ZonaSasaran.Zona = ZonaSasaran.zona_rumah_seberang(4.0, true, 0, "x")[0]
	check(PermukaanKoran.titik_diam(PermukaanKoran.Permukaan.KOTAK_SURAT, z0, Vector2(9, 9)).distance_to(Vector2(-2.125, -5.75)) < 0.00001, "literal: kavling maju 4 -> kaki kotak surat (-2,125; -5,75)")
	check(PermukaanKoran.titik_diam(PermukaanKoran.Permukaan.TERAS, z0, Vector2(1.5, -7.0)) == Vector2(1.5, -7.0) and PermukaanKoran.titik_diam(PermukaanKoran.Permukaan.RUMPUT, null, Vector2(1.5, -7.0)) == Vector2(1.5, -7.0) and PermukaanKoran.titik_diam(PermukaanKoran.Permukaan.KOTAK_SURAT, null, Vector2(1.5, -7.0)) == Vector2(1.5, -7.0), "teras, rumput, dan zona null: titik mendarat apa adanya")


# --- Field turunan tidak mengubah penilaian (AC-10, AC-12) ---

func _test_field_turunan_tidak_mengubah_penilaian() -> void:
	_judul.call("KoranLempar.Koran: field turunan (permukaan, titik_diam) tidak mengubah hasil, antaran, penanda, id_rumah, tepat: 1000 lemparan acak berseed (AC-10)")
	var pustaka: Array[SegmenRute] = PemuatRute.muat_folder(FOLDER_RUTE).segmen
	var rute: RouteBuilder.Rute = RouteBuilder.bangun(20261016, pustaka).rute
	var medan: MedanKoran = MedanKoran.dari_rute(rute)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 5150
	var sama: int = 0
	var permukaan_cocok: int = 0
	var pernah: Dictionary = {}
	var contoh: String = ""
	for i: int in range(1000):
		var r: RouteBuilder.RumahRute = rute.rumah[rng.randi_range(0, rute.rumah.size() - 1)]
		var sepeda: Vector2 = Vector2(rng.randf_range(-1.5, 1.5), -(r.maju_ubin - 3.0))
		var arah: Vector2 = Vector2.from_angle(rng.randf_range(0.0, TAU))
		var l: ThrowSolver.Lintasan = ThrowSolver.hitung(ThrowSolver.swipe_maks_px(float(LEBAR)) * rng.randf_range(0.3, 1.0), float(LEBAR), arah, sepeda, rng.randf_range(0.0, 6.0), rng.randf_range(-1.0, 1.0), 0.1)
		if l == null:
			continue
		# Titik mendarat dibelokkan ke sekitar rumah ini supaya semua jenis zona (dan meleset) sering kena.
		l.titik_mendarat = Vector2(rng.randf_range(-4.0, 4.0), -(r.maju_ubin + rng.randf_range(-1.0, 3.5)))
		var bantu: bool = rng.randi_range(0, 3) == 0
		var bonus: bool = rng.randi_range(0, 1) == 0
		var koran: KoranLempar.Koran = KoranLempar.langkah(KoranLempar.baru(l, bantu), ThrowSolver.lama_total(l) + 0.5, bonus, medan)
		# Penilaian ulang dari ZonaSasaran saja (cara lama, tanpa KoranLempar.langkah).
		var zona: ZonaSasaran.Zona = ZonaSasaran.zona_kena(l.titik_mendarat, medan.zona_sekitar(l.titik_mendarat))
		var hasil: ZonaSasaran.Hasil = ZonaSasaran.hasil_zona(zona)
		var antaran: ZonaSasaran.Antaran = ZonaSasaran.status_antaran(hasil, bonus)
		var id_rumah: String = zona.id_rumah if zona != null else ""
		var tepat: bool = hasil == ZonaSasaran.Hasil.KOTAK_SURAT and not bantu and ZonaSasaran.tepat(zona, l.titik_mendarat)
		if koran.mendarat and koran.hasil == hasil and koran.antaran == antaran and koran.penanda == ZonaSasaran.penanda(antaran) and koran.id_rumah == id_rumah and koran.tepat == tepat and koran.bantu == bantu:
			sama += 1
		elif contoh.is_empty():
			contoh = "lemparan %d: hasil %s/%s antaran %s/%s id '%s'/'%s' tepat %s/%s" % [i, koran.hasil, hasil, koran.antaran, antaran, koran.id_rumah, id_rumah, koran.tepat, tepat]
		# Permukaan dari jawaban ditulis ulang: kotak surat pelanggan seberang -> kotak; halaman -> rumput; zona lain -> teras; tanpa zona -> menurut x.
		var harapan: int = 1
		if zona == null:
			harapan = 2 if absf(l.titik_mendarat.x) >= 2.0 else 1
		elif zona.jenis == ZonaSasaran.Jenis.HALAMAN:
			harapan = 2
		elif zona.jenis == ZonaSasaran.Jenis.KOTAK_SURAT and zona.pelanggan and zona.sisi == LoperAnim.Sisi.SEBERANG:
			harapan = 0
		if int(koran.permukaan) == harapan:
			permukaan_cocok += 1
		pernah["%d:%d" % [int(koran.permukaan), int(hasil)]] = true
	check(sama == 1000, "1000 lemparan acak: hasil, antaran, penanda, id_rumah, tepat, bantu identik dengan penilaian ulang dari ZonaSasaran (%d sama) %s" % [sama, contoh])
	check(permukaan_cocok == 1000, "1000 lemparan acak: permukaan sama dengan aturan ditulis ulang (%d cocok)" % permukaan_cocok)
	check(pernah.size() >= 8, "lemparan acak mencakup banyak kombinasi permukaan x hasil (%d)" % pernah.size())
	var belum: KoranLempar.Koran = KoranLempar.baru(ThrowSolver.hitung(ThrowSolver.swipe_maks_px(float(LEBAR)), float(LEBAR), Vector2(0, -1), Vector2(0, 0), 3.0, 0.0, 0.1), false)
	check(not belum.mendarat and belum.permukaan == PermukaanKoran.Permukaan.TERAS and belum.titik_diam == Vector2.ZERO, "koran belum mendarat: field turunan bawaan (tidak dipakai)")
	var salinan: KoranLempar.Koran = KoranLempar.langkah(belum, 5.0, false, medan)
	check(salinan.salin().permukaan == salinan.permukaan and salinan.salin().titik_diam == salinan.titik_diam and not belum.mendarat, "salin menyalin field turunan; masukan langkah tidak diubah")


# --- Item sprite murni ---

func _test_item_murni() -> void:
	_judul.call("SpriteKoran: item tanah dan udara menurut keadaan koran (murni, AC-8, AC-9)")
	var l: ThrowSolver.Lintasan = ThrowSolver.hitung(ThrowSolver.swipe_maks_px(float(LEBAR)), float(LEBAR), Vector2(0, -1), Vector2(0.5, -5.0), 3.0, 0.0, 0.1)
	var belum: KoranLempar.Koran = KoranLempar.baru(l)
	check(SpriteKoran.item_tanah(belum).is_empty() and SpriteKoran.item_udara(belum).is_empty(), "sebelum lepas: tidak ada bayangan dan tidak ada koran")
	var udara: KoranLempar.Koran = KoranLempar.langkah(belum, 0.1 + l.lama_terbang * 0.5, false, null)
	check(KoranLempar.di_udara(udara), "kontrol: di udara pada setengah terbang")
	var tanah_u: Array[DefSprite.Item] = SpriteKoran.item_tanah(udara)
	var atas_u: Array[DefSprite.Item] = SpriteKoran.item_udara(udara)
	check(_item_nama(tanah_u) == ["prop_koran_bayangan"] and _item_nama(atas_u) == ["prop_koran_putar"], "terbang: satu bayangan di tanah, satu koran putar di udara")
	var p: Vector3 = KoranLempar.posisi(udara)
	check(tanah_u[0].frame == SpriteKoran.frame_bayangan(p.z) and tanah_u[0].pojok == _layar(p.x, p.y) - Vector2(6, 3), "bayangan: frame dari tinggi %.2f, pijak (6, 3) di titik tanah koran" % p.z)
	var pusat_lama: Vector2 = _layar_tinggi(p) - Vector2(4, 6) + Vector2(4, 3)
	check(((atas_u[0].pojok + Vector2(5, 5)) - pusat_lama).length() <= 1.0, "pusat koran putar (pojok + pijak) berselisih <= 1 px dari pusat pola 8x6 lama (%s lawan %s)" % [atas_u[0].pojok + Vector2(5, 5), pusat_lama])
	check(atas_u[0].frame == KoranLempar.frame_putar(udara, 4), "frame putar dari KoranLempar.frame_putar (4 frame, 12 fps)")
	var mendarat: KoranLempar.Koran = KoranLempar.langkah(udara, 5.0, false, null)
	check(mendarat.mendarat and not SpriteKoran.item_tanah(mendarat).is_empty() and _item_nama(SpriteKoran.item_tanah(mendarat)) != ["prop_koran_bayangan"] and SpriteKoran.item_udara(mendarat).is_empty(), "sudah mendarat: tidak ada bayangan, koran tergeletak di tanah (jalan uji: tanpa zona di titik itu)")
	# Koran di kotak surat: lapisan udara, bukan tanah.
	var kotak: KoranLempar.Koran = mendarat.salin()
	kotak.permukaan = PermukaanKoran.Permukaan.KOTAK_SURAT
	kotak.titik_diam = Vector2(-2.125, -5.75)
	check(SpriteKoran.item_tanah(kotak).is_empty() and _item_nama(SpriteKoran.item_udara(kotak)) == ["prop_koran_kotak_surat"], "kotak surat: tidak di lapisan tanah (tertutup kotak surat), di lapisan udara")
	check(SpriteKoran.item_udara(kotak)[0].pojok == _layar(-2.125, -5.75) + Vector2(3, -19), "pojok koran kotak surat = kaki kotak surat + (3, -19) dari pijak (-3, 19)")


## Layar (bulat) titik dunia setinggi z: tanah lalu naik z x 32 piksel (rumus ditulis ulang).
func _layar_tinggi(p: Vector3) -> Vector2:
	return (_layar(p.x, p.y) - Vector2(0, roundf(p.z * 32.0))).round()


# --- Skor tidak berubah (AC-11) ---

func _test_skor_60_rute_tetap() -> void:
	_judul.call("SkorRute tidak diubah: skor dan koin 60 rute dari urutan antaran tetap sama dengan nilai sebelum run (AC-11)")
	var pustaka: Array[SegmenRute] = PemuatRute.muat_folder(FOLDER_RUTE).segmen
	var jumlah_total: int = 0
	var skor_total: int = 0
	var koin_total: int = 0
	var tip_total: int = 0
	for benih: int in range(1, 61):
		var rute: RouteBuilder.Rute = RouteBuilder.bangun(benih, pustaka).rute
		var keadaan: SkorRute.Keadaan = SkorRute.awal()
		var i: int = 0
		for r: RouteBuilder.RumahRute in rute.pelanggan:
			var hasil_zona: ZonaSasaran.Hasil = [ZonaSasaran.Hasil.KOTAK_SURAT, ZonaSasaran.Hasil.TERAS, ZonaSasaran.Hasil.HALAMAN][i % 3]
			var h: SkorRute.Hasil = SkorRute.nilai(keadaan, hasil_zona, r.id, i % 3 == 0, 3.0 + float(i % 4), RouteBuilder.pemberi_tip(rute, r.id), false, i % 7 == 6)
			keadaan = h.keadaan
			if i % 5 == 0:
				keadaan = SkorRute.nilai(keadaan, hasil_zona, r.id, false, 3.0, false, false).keadaan
			i += 1
		jumlah_total += keadaan.jumlah_antar
		skor_total += keadaan.skor
		koin_total += keadaan.koin
		tip_total += keadaan.jumlah_tip
	check(jumlah_total == 1500 and skor_total == 300480 and koin_total == 23110 and tip_total == 122, "antaran %d, skor %d, koin %d, tip %d di 60 rute = nilai sebelum run (1500, 300480, 23110, 122)" % [jumlah_total, skor_total, koin_total, tip_total])


# --- Rujukan aset (AC-17) ---

func _test_rujukan_sprite_dan_isi_folder() -> void:
	_judul.call("Rujukan nama sprite di sumber hanya ke aset terpasang; folder props dan vfx hanya berisi aset terpasang dan berkas lama (AC-2, AC-17)")
	var dikenal: Dictionary = {}
	for nama: String in DefSprite.NAMA:
		dikenal[nama] = true
	for nama: String in BERKAS_LAMA_PROPS:
		dikenal[nama] = true
	dikenal["mission_kucing_sheet"] = true
	dikenal["prop_graybox_kotak_surat"] = true
	var berkas: Array[String] = []
	for akar: String in ["res://scripts", "res://scenes", "res://assets/data", "res://translations"]:
		_kumpulkan(akar, berkas)
	var tes: DirAccess = DirAccess.open("res://tests")
	for nama: String in tes.get_files():
		if nama.ends_with(".gd") and not nama.begins_with("probe_"):
			berkas.append("res://tests/" + nama)
	# Hanya nama di dalam string literal atau jalur (didahului tanda kutip atau garis miring), bukan nama fungsi, variabel, atau berkas skrip (.gd).
	var regex: RegEx = RegEx.create_from_string("(?<=[\"/])((?:prop|vfx|mission)_[a-z_0-9]+)(?![a-z_0-9]|\\.gd)")
	var asing: Array[String] = []
	var total: int = 0
	for jalur: String in berkas:
		if jalur.ends_with("tes_ubin.gd"):
			continue
		for cocok: RegExMatch in regex.search_all(FileAccess.get_file_as_string(jalur)):
			total += 1
			var nama: String = cocok.get_string()
			if not dikenal.has(nama) and not _awalan_dikenal(nama):
				asing.append("%s: %s" % [jalur, nama])
	check(total > 50, "pemindai menemukan banyak rujukan nama aset (%d)" % total)
	check(asing.is_empty(), "tidak ada rujukan nama prop_/vfx_/mission_ di luar aset terpasang: %s" % [asing])
	for folder: String in ["props", "vfx"]:
		var isi: Array[String] = []
		for nama: String in DirAccess.get_files_at("res://assets/sprites/" + folder):
			if nama.ends_with(".png") or nama.ends_with(".json"):
				isi.append(nama.get_basename())
		var harapan: Array[String] = []
		for baris: Array in TABEL:
			if baris[1] == folder:
				harapan.append(baris[0])
		if folder == "props":
			harapan.append_array(BERKAS_LAMA_PROPS)
		isi = _unik(isi)
		isi.sort()
		harapan.sort()
		check(isi == harapan, "folder %s: PNG dan JSON hanya untuk aset terpasang (dapat %s)" % [folder, isi])


## True bila `nama` adalah awalan nama aset yang dikenal (mis. kunci kode "prop_koran_" dari nama tabel atau "vfx_garis_kecepatan" tanpa huruf varian di komentar).
func _awalan_dikenal(nama: String) -> bool:
	for dikenal_nama: String in DefSprite.NAMA + BERKAS_LAMA_PROPS:
		if dikenal_nama.begins_with(nama):
			return true
	return false


func _unik(daftar: Array[String]) -> Array[String]:
	var hasil: Array[String] = []
	for nama: String in daftar:
		if not hasil.has(nama):
			hasil.append(nama)
	return hasil


func _kumpulkan(folder: String, hasil: Array[String]) -> void:
	for nama: String in DirAccess.get_files_at(folder):
		if nama.ends_with(".gd") or nama.ends_with(".tscn") or nama.ends_with(".tres") or nama.ends_with(".json") or nama.ends_with(".csv"):
			hasil.append(folder + "/" + nama)
	for sub: String in DirAccess.get_directories_at(folder):
		_kumpulkan(folder + "/" + sub, hasil)


# --- Scene: koran terbang (AC-8, AC-9) ---

func _test_koran_terbang_di_scene() -> void:
	_judul.call("Scene rute: koran terbang menampilkan 4 frame putar berurutan, pusat sama dengan pola lama, bayangan menurut tinggi di lapisan tanah (AC-8, AC-9)")
	var akar: RuteMain = await _siapkan()
	var tanah: KoranGambar = _anak(akar, "KoranTanah") as KoranGambar
	var udara: KoranGambar = _anak(akar, "KoranUdara") as KoranGambar
	var objek: Node = _anak(akar, "Objek")
	check(tanah.pakai_sprite and udara.pakai_sprite and tanah.lapisan == KoranGambar.Lapisan.TANAH and udara.lapisan == KoranGambar.Lapisan.UDARA, "KoranTanah dan KoranUdara memakai sprite di rute.tscn")
	check(tanah.get_index() < objek.get_index() and udara.get_index() > objek.get_index(), "urutan gambar: koran tanah sebelum objek dunia, koran udara sesudah objek dunia (lapisan UDARA di atas objek)")
	check(tanah.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST and udara.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "node koran memakai filter Nearest")
	# Tekstur harus dimuat di luar _draw (tekstur yang baru dimuat di dalam _draw tergambar putih polos; ditemukan lewat probe jendela) dan dipegang node.
	check(tanah.jumlah_tekstur() == 5 and udara.jumlah_tekstur() == 5, "node koran memegang lima tekstur (putar, bayangan, teras, rumput, kotak surat) sebelum menggambar")
	check(GambarSprite.muat(["prop_koran_putar", "tidak_ada"] as Array[String]).size() == 1, "GambarSprite.muat melewati nama tidak dikenal")
	var mendarat: Array[KoranLempar.Koran] = []
	akar.koran_mendarat.connect(func(k: KoranLempar.Koran) -> void: mendarat.append(k))
	_taruh(akar, 3.0, 0.5, 4.0)
	akar.koran = SisaKoran.awal(30)
	var sepeda: SepedaUji = _sepeda(akar)
	var jeda: float = sepeda.jeda_lepas(LoperAnim.Sisi.SEBERANG)
	var l: ThrowSolver.Lintasan = ThrowSolver.hitung(ThrowSolver.swipe_maks_px(float(LEBAR)), float(LEBAR), Vector2(-0.3, -1.0), sepeda.posisi_dunia(), sepeda.kecepatan_ud, sepeda.lateral_ud, jeda)
	akar.call(&"_lempar", l, false)
	var frame_terlihat: Array[int] = []
	var bayangan_benar: bool = true
	var pusat_benar: bool = true
	var jumlah_udara: int = 0
	var sebelum_lepas_kosong: bool = false
	var cek_mendarat: bool = false
	var mendarat_benar: bool = false
	var tinggi_maks: float = 0.0
	var bayangan_frame_terlihat: Dictionary = {}
	for i: int in range(150):
		akar.perbarui(DT)
		var daftar: Array[KoranLempar.Koran] = akar.koran_terbang()
		if daftar.is_empty():
			break
		var k: KoranLempar.Koran = daftar[0]
		if not KoranLempar.di_udara(k) and not k.mendarat:
			sebelum_lepas_kosong = tanah.item_sprite().is_empty() and udara.item_sprite().is_empty()
		if k.mendarat and not cek_mendarat:
			cek_mendarat = true
			mendarat_benar = _item_nama(udara.item_sprite()).count("prop_koran_putar") == 0 and _item_nama(tanah.item_sprite()).count("prop_koran_bayangan") == 0 and not tanah.item_sprite().is_empty()
		if not KoranLempar.di_udara(k):
			continue
		jumlah_udara += 1
		var p: Vector3 = KoranLempar.posisi(k)
		tinggi_maks = maxf(tinggi_maks, p.z)
		var item_u: Array[DefSprite.Item] = udara.item_sprite()
		var item_t: Array[DefSprite.Item] = tanah.item_sprite()
		if item_u.size() != 1 or item_u[0].nama != "prop_koran_putar" or item_t.size() != 1 or item_t[0].nama != "prop_koran_bayangan":
			bayangan_benar = false
			continue
		if frame_terlihat.is_empty() or frame_terlihat.back() != item_u[0].frame:
			frame_terlihat.append(item_u[0].frame)
		var pusat_lama: Vector2 = _layar_tinggi(p) - Vector2(4, 6) + Vector2(4, 3)
		if ((item_u[0].pojok + Vector2(5, 5)) - pusat_lama).length() > 1.0:
			pusat_benar = false
		var lebar: int = KoranLempar.lebar_bayangan_px(p.z)
		var frame_harapan: int = 0 if lebar >= 9 else 1 if lebar >= 7 else 2
		bayangan_frame_terlihat[item_t[0].frame] = true
		if item_t[0].frame != frame_harapan or item_t[0].pojok != _layar(p.x, p.y) - Vector2(6, 3):
			bayangan_benar = false
	check(jumlah_udara > 10 and tinggi_maks > 1.0, "kontrol: koran terbang %d langkah, tinggi sampai %.2f ubin" % [jumlah_udara, tinggi_maks])
	check(sebelum_lepas_kosong or jeda <= DT, "sebelum lepas (koran masih di tangan): tidak ada bayangan dan tidak ada koran putar")
	check(frame_terlihat.size() >= 8 and frame_terlihat.slice(0, 4) == [frame_terlihat[0], (frame_terlihat[0] + 1) % 4, (frame_terlihat[0] + 2) % 4, (frame_terlihat[0] + 3) % 4], "koran putar berganti frame berurutan 0, 1, 2, 3 memutar: %s" % [frame_terlihat])
	check(pusat_benar, "tiap langkah terbang: pusat gambar koran putar berselisih <= 1 px dari pusat pola lama (AC-8)")
	check(bayangan_benar, "tiap langkah terbang: bayangan di lapisan tanah di titik tanah koran, pijak (6, 3), frame dari tinggi (AC-9)")
	check(bayangan_frame_terlihat.size() >= 2, "bayangan berganti ukuran menurut tinggi sepanjang satu lemparan (%s)" % [bayangan_frame_terlihat.keys()])
	# Sesudah mendarat: tidak ada koran putar dan tidak ada bayangan (diperiksa pada langkah ia mendarat), hanya koran tergeletak.
	check(cek_mendarat and mendarat_benar, "sesudah mendarat: tidak ada koran putar dan tidak ada bayangan, hanya koran tergeletak")
	_langkah(akar, 60)
	check(akar.koran_terbang().is_empty() and tanah.item_sprite().is_empty() and udara.item_sprite().is_empty(), "sesudah penanda habis (0,8 detik): tidak ada sprite koran")
	# Jeda game membekukan frame dan posisi.
	_taruh(akar, 3.0, 0.5, 4.0)
	akar.koran = SisaKoran.awal(30)
	akar.call(&"_lempar", l, false)
	for i: int in range(20):
		akar.perbarui(DT)
	var item_1: DefSprite.Item = udara.item_sprite()[0] if not udara.item_sprite().is_empty() else null
	akar.minta_jeda()
	_langkah(akar, 30)
	var item_2: DefSprite.Item = udara.item_sprite()[0] if not udara.item_sprite().is_empty() else null
	check(item_1 != null and item_2 != null and item_1.frame == item_2.frame and item_1.pojok == item_2.pojok, "jeda game: frame dan posisi koran putar membeku")
	akar.minta_lanjut()
	_langkah(akar, 3)
	var item_3: DefSprite.Item = udara.item_sprite()[0] if not udara.item_sprite().is_empty() else null
	check(item_3 != null and item_3.pojok != item_2.pojok, "sesudah lanjut: koran bergerak lagi")
	_bersihkan(akar)


# --- Scene: mendarat di empat permukaan (AC-10) ---

func _test_mendarat_empat_permukaan() -> void:
	_judul.call("Scene rute: lemparan ke kotak surat, teras, halaman, dan aspal memunculkan sprite kotak_surat, teras, rumput, dan teras dengan pijak sesuai JSON (AC-10)")
	var akar: RuteMain = await _siapkan()
	var tanah: KoranGambar = _anak(akar, "KoranTanah") as KoranGambar
	var udara: KoranGambar = _anak(akar, "KoranUdara") as KoranGambar
	var mendarat: Array[KoranLempar.Koran] = []
	akar.koran_mendarat.connect(func(k: KoranLempar.Koran) -> void: mendarat.append(k))
	var r6: RouteBuilder.RumahRute = _rumah(akar, "per_buka_01@6")
	var r10: RouteBuilder.RumahRute = _rumah(akar, "per_buka_01@10")
	check(r6 != null and r10 != null and r6.pelanggan and r10.pelanggan and r6.sisi == LoperAnim.Sisi.SEBERANG, "kontrol: per_buka_01@6 dan @10 rumah pelanggan sisi seberang")
	# 1. Kotak surat pelanggan seberang: sprite kotak_surat di lapisan udara, pijak = kaki kotak surat.
	var k1: KoranLempar.Koran = await _lempar_ke_kotak(akar, 1.0, "per_buka_01@6", mendarat)
	check(k1 != null and k1.hasil == ZonaSasaran.Hasil.KOTAK_SURAT and k1.permukaan == PermukaanKoran.Permukaan.KOTAK_SURAT, "lemparan ke pusat kotak surat: permukaan KOTAK_SURAT")
	if k1 != null:
		var kaki: Vector2 = _layar(-2.125, -(r6.maju_ubin + 1.75))
		var item: Array[DefSprite.Item] = udara.item_sprite()
		check(_item_nama(item) == ["prop_koran_kotak_surat"] and item[0].pojok == kaki + Vector2(3, -19) and item[0].frame == 0, "koran kotak surat: pojok = kaki kotak surat %s + (3, -19), pijak JSON (-3, 19)" % [kaki])
		check(_item_nama(tanah.item_sprite()).is_empty(), "koran di kotak surat tidak digambar di lapisan tanah")
		check(k1.titik_diam.distance_to(Vector2(-2.125, -(r6.maju_ubin + 1.75))) < 0.00001, "titik diam = kaki kotak surat rumah @6")
	# 2. Teras @10 (bukan pemberi tip): sprite teras di titik mendarat.
	var k2: KoranLempar.Koran = await _lempar_ke_titik(akar, 4.0, Vector2(-2.75, 10.5), mendarat)
	check(k2 != null and k2.hasil == ZonaSasaran.Hasil.TERAS and k2.permukaan == PermukaanKoran.Permukaan.TERAS, "lemparan ke teras @10: permukaan TERAS")
	if k2 != null:
		var titik: Vector2 = _layar(k2.lintasan.titik_mendarat.x, k2.lintasan.titik_mendarat.y)
		var item: Array[DefSprite.Item] = tanah.item_sprite()
		check(_item_nama(item) == ["prop_koran_teras"] and item[0].pojok == titik - Vector2(6, 6) and _item_nama(udara.item_sprite()).count("prop_koran_kotak_surat") == 0, "koran teras di lapisan tanah, pijak (6, 6) di titik mendarat %s" % [titik])
	# 3. Halaman: sprite rumput.
	var k3: KoranLempar.Koran = await _lempar_ke_titik(akar, 4.0, Vector2(-2.4, 10.5), mendarat)
	check(k3 != null and k3.hasil == ZonaSasaran.Hasil.HALAMAN and k3.permukaan == PermukaanKoran.Permukaan.RUMPUT, "lemparan ke halaman: permukaan RUMPUT")
	if k3 != null:
		var titik: Vector2 = _layar(k3.lintasan.titik_mendarat.x, k3.lintasan.titik_mendarat.y)
		var item: Array[DefSprite.Item] = tanah.item_sprite()
		check(_item_nama(item) == ["prop_koran_rumput"] and item[0].pojok == titik - Vector2(6, 6), "koran rumput di titik mendarat, pijak (6, 6)")
	# 4. Aspal (meleset, tanpa zona): lantai keras = teras. Trotoar juga teras. Rumput tanpa zona = rumput.
	var aspal: KoranLempar.Koran = await _lempar_ke_titik(akar, 4.0, Vector2(-0.5, 10.5), mendarat)
	check(aspal != null and aspal.hasil == ZonaSasaran.Hasil.MELESET and aspal.permukaan == PermukaanKoran.Permukaan.TERAS and _item_nama(tanah.item_sprite()) == ["prop_koran_teras"], "koran di aspal (meleset): sprite teras (lantai keras)")
	var trotoar: KoranLempar.Koran = await _lempar_ke_titik(akar, 4.0, Vector2(-1.5, 10.5), mendarat)
	check(trotoar != null and trotoar.hasil == ZonaSasaran.Hasil.MELESET and trotoar.permukaan == PermukaanKoran.Permukaan.TERAS and _item_nama(tanah.item_sprite()) == ["prop_koran_teras"], "koran di trotoar (meleset): sprite teras")
	var rumput: KoranLempar.Koran = await _lempar_ke_titik(akar, 4.0, Vector2(-3.5, 10.5), mendarat, -1.5)
	check(rumput != null and rumput.hasil == ZonaSasaran.Hasil.MELESET and rumput.permukaan == PermukaanKoran.Permukaan.RUMPUT and _item_nama(tanah.item_sprite()) == ["prop_koran_rumput"], "koran di rumput tanpa zona (meleset): sprite rumput")
	# Berturut-turut: kotak_surat, teras, rumput, teras.
	var urutan: Array[int] = []
	for k: KoranLempar.Koran in [k1, k2, k3, aspal]:
		urutan.append(int(k.permukaan) if k != null else -1)
	check(urutan == [0, 1, 2, 1], "berturut-turut: kotak_surat, teras, rumput, teras (aspal)")
	_langkah(akar, 60)
	check(tanah.item_sprite().is_empty() and udara.item_sprite().is_empty(), "koran tergeletak hanya tampil selama penanda (0,8 detik), lalu hilang")
	_bersihkan(akar)


# --- Scene: koran terlipat (AC-11) ---

func _test_terlipat_di_scene() -> void:
	_judul.call("Scene rute: koran terlipat tepat sekali di teras rumah terantar, di atas sprite rumah, hilang bersama rumah, tidak untuk rumah lain (AC-11)")
	var akar: RuteMain = await _siapkan()
	var daur: RumahDaurRute = akar.daur()
	var mendarat: Array[KoranLempar.Koran] = []
	akar.koran_mendarat.connect(func(k: KoranLempar.Koran) -> void: mendarat.append(k))
	var r6: RouteBuilder.RumahRute = _rumah(akar, "per_buka_01@6")
	var r10: RouteBuilder.RumahRute = _rumah(akar, "per_buka_01@10")
	_taruh(akar, 3.0, 0.5, 1.0)
	check(daur.jumlah_terlipat() == 0, "awal: belum ada rumah terantar, tidak ada koran terlipat")
	# Koran tidak sah (meleset di aspal) dan ke rumah bukan pelanggan: tidak memunculkan terlipat.
	await _lempar_ke_titik(akar, 4.0, Vector2(-0.5, 10.5), mendarat)
	check(daur.jumlah_terlipat() == 0, "koran meleset (tidak sah): tidak ada koran terlipat")
	# Antaran sah ke rumah @6: tepat satu terlipat.
	var k1: KoranLempar.Koran = await _lempar_ke_kotak(akar, 1.0, "per_buka_01@6", mendarat)
	check(k1 != null and akar.skor().terantar.has("per_buka_01@6"), "kontrol: rumah @6 terantar di SkorRute")
	var indeks_6: int = akar.rute().rumah.find(r6)
	var indeks_10: int = akar.rute().rumah.find(r10)
	check(daur.jumlah_terlipat() == 1 and daur.indeks_terlipat() == [indeks_6], "rumah @6 terantar: tepat satu koran terlipat, di rumah @6 (dapat %s)" % [daur.indeks_terlipat()])
	var terlipat: Sprite2D = daur.sprite_terlipat(indeks_6)
	if terlipat != null:
		var teras_x: float = -2.75
		var teras_maju: float = r6.maju_ubin + 0.625
		check(terlipat.position == _layar(teras_x, -teras_maju) and terlipat.offset == Vector2(-7, -5) and not terlipat.centered and terlipat.visible, "terlipat di tengah teras seberang (-2,75; maju %.3f): posisi %s, pijak (7, 5)" % [teras_maju, terlipat.position])
		check(terlipat.texture.resource_path == "res://assets/sprites/props/prop_koran_terlipat.png" and terlipat.texture.get_width() == 14 and terlipat.texture.get_height() == 10, "tekstur prop_koran_terlipat 14x10")
		var rumah_sprite: Sprite2D = daur.sprite_rumah(indeks_6)
		check(terlipat.get_parent() == rumah_sprite.get_parent() and (terlipat.get_parent() as Node2D).y_sort_enabled and terlipat.position.y > rumah_sprite.position.y, "urutan gambar: satu induk Y-sort dengan sprite rumah, titik teras lebih bawah dari titik pijak rumah (digambar sesudah rumah)")
		check(terlipat.get_parent() == daur and daur.get_children().filter(func(n: Node) -> bool: return n.name.begins_with("Terlipat_")).size() == 1, "tepat satu node terlipat di jendela daur (tidak ganda)")
	# Beberapa langkah berikutnya (atur_terantar dipanggil tiap langkah): tetap satu node terlipat bergambar di jendela daur, tidak ada node bocor di luar kolam.
	_langkah(akar, 10)
	check(_hitung_node_terlipat(daur) == 1 and daur.jumlah_terlipat() == 1, "sesudah 10 langkah lagi: tepat satu node koran terlipat di induk daur (%d), tanpa kebocoran" % _hitung_node_terlipat(daur))
	# Rumah lain (@10) belum terantar.
	check(not daur.indeks_terlipat().has(indeks_10), "rumah @10 belum terantar: tanpa terlipat")
	# Koran ulang ke rumah terantar (netral): tidak menggandakan.
	await _lempar_ke_kotak(akar, 1.0, "per_buka_01@6", mendarat)
	check(daur.jumlah_terlipat() == 1 and daur.jumlah_node_terlipat() == 1, "koran ulang ke rumah terantar: tetap satu terlipat, satu node")
	_langkah(akar, 10)
	check(_hitung_node_terlipat(daur) == 1, "koran ulang ke rumah terantar lalu 10 langkah: tetap satu node terlipat bergambar (%d)" % _hitung_node_terlipat(daur))
	# Antaran sah kedua ke @10 (teras): dua terlipat.
	await _lempar_ke_titik(akar, 4.0, Vector2(-2.75, 10.5), mendarat)
	check(daur.jumlah_terlipat() == 2 and daur.indeks_terlipat() == [indeks_6, indeks_10], "rumah @10 terantar sesudah antaran teras: dua terlipat, satu per rumah")
	# Di luar jendela daur: hilang bersama rumah. Kembali: muncul lagi, status tetap.
	_taruh(akar, 3.0, 0.5, 150.0)
	check(daur.jumlah_terlipat() == 0 and daur.jumlah_rumah() > 0 and not daur.indeks_tampil().has(indeks_6), "sepeda jauh (maju 150): rumah @6 dan @10 keluar jendela daur, terlipat ikut hilang")
	_taruh(akar, 3.0, 0.5, 8.0)
	check(daur.indeks_terlipat() == [indeks_6, indeks_10] and daur.jumlah_node_terlipat() == 2, "kembali ke maju 8: terlipat muncul lagi di kedua rumah (status terantar tetap), tanpa node baru (kolam dipakai ulang)")
	# Bukan pelanggan dan belum terantar: tidak pernah terlipat walau id masuk daftar.
	var bukan: RouteBuilder.RumahRute = null
	for r: RouteBuilder.RumahRute in akar.rute().rumah:
		if not r.pelanggan and r.maju_ubin > 0.0 and r.maju_ubin < 25.0:
			bukan = r
			break
	check(bukan != null, "kontrol: ada rumah bukan pelanggan di awal rute")
	if bukan != null:
		daur.atur_terantar({bukan.id: true})
		check(daur.jumlah_terlipat() == 0, "id rumah bukan pelanggan dalam daftar terantar: tidak ada terlipat (hanya pelanggan)")
		daur.atur_terantar(akar.skor().terantar)
		check(daur.jumlah_terlipat() == 2, "daftar terantar dikembalikan: dua terlipat lagi")
	# Main lagi: rute baru, skor baru, tidak ada terlipat.
	akar.main_lagi()
	check(daur.jumlah_terlipat() == 0 and akar.skor().terantar.is_empty(), "Main lagi: skor dan rute baru, tidak ada terlipat")
	_bersihkan(akar)


## Banyaknya node Sprite2D bertekstur koran terlipat di induk `daur` (semua anak, termasuk yang tersembunyi di kolam).
func _hitung_node_terlipat(daur: RumahDaurRute) -> int:
	var jumlah: int = 0
	for anak: Node in daur.get_children():
		var sprite: Sprite2D = anak as Sprite2D
		if sprite != null and sprite.texture != null and sprite.texture.resource_path.ends_with("prop_koran_terlipat.png") and sprite.visible:
			jumlah += 1
	return jumlah


# --- Jalan uji tetap placeholder (D-7) ---

func _test_jalan_uji_tetap_placeholder() -> void:
	_judul.call("Jalan uji tetap memakai pola kode untuk koran, debu, dan garis (scenes/dev tidak disentuh, D-7)")
	_tree.root.size = Vector2i(2340, 1080)
	var akar: JalanUji = (load(BERKAS_JALAN_UJI) as PackedScene).instantiate() as JalanUji
	_tree.root.add_child(akar)
	await _tree.process_frame
	await _tree.process_frame
	akar.set_process(false)
	var tanah: KoranGambar = _anak(akar, "KoranTanah") as KoranGambar
	var udara: KoranGambar = _anak(akar, "KoranUdara") as KoranGambar
	check(not tanah.pakai_sprite and not udara.pakai_sprite and tanah.item_sprite().is_empty() and udara.item_sprite().is_empty() and tanah.jumlah_tekstur() == 0, "jalan_uji.tscn: KoranGambar tanpa mode sprite dan tanpa tekstur")
	check(not _sepeda(akar).umpan_balik().pakai_sprite() and _sepeda(akar).umpan_balik().sprite() == null, "jalan_uji.tscn: debu dan garis tetap partikel kode")
	_tree.root.remove_child(akar)
	akar.free()
