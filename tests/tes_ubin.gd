class_name TesUbin
extends RefCounted
## Tes ubin tanah enam kolom run fase5a-pasang-aset-gelombang1 (AC-4 sampai AC-7, bagian A): pemetaan kolom `JalanDaur.kolom_di` dan
## `rumput_luar` (murni, oracle literal), `TanahDaur` memasang enam tekstur di scene rute, tanpa celah dan tanpa pita (komposisi piksel),
## jumlah node ubin tidak naik, dan tidak ada referensi ke aset ubin yang tidak dipasang.
##
## Harapan ditulis sebagai literal, atau dihitung dengan cara lain dari kode produksi: kolom dari tabel (x, nama) yang ditulis tangan,
## posisi dunia ubin dari piksel layar dengan rumus proyeksi 2:1 ditulis ulang (x = (sy / 16 + sx / 32) / 2), tekstur dari `resource_path`,
## dan susunan referensi dari `tests/data/ubin_potongan_8_maju.png` (dibuat `tools/tests_cek/uji_aset_pasang_gelombang1.py` dari berkas
## assets/, dibandingkan piksel dengan adegan renderer di sisi Python).
##
## Keputusan tafsir D-2 (dicatat di LOG): batas kolom ada di |x| = 1 dan 2 dan dihitung ke kolom LUAR di kedua sisi (sama dengan `jenis_di`, yang
## tidak berubah), bukan interval setengah terbuka [-2, -1) di sisi seberang. Hanya x = 0 yang tidak simetris (jatuh ke `dekat`).

const BERKAS_RUTE: String = "res://scenes/rute/rute.tscn"
const FOLDER_UBIN: String = "res://assets/sprites/tiles/perumahan/"
const REFERENSI: String = "res://tests/data/ubin_potongan_8_maju.png"
const GRAYBOX: Array[String] = [
	"res://assets/sprites/_placeholder/tile_graybox_aspal.png",
	"res://assets/sprites/_placeholder/tile_graybox_trotoar.png",
	"res://assets/sprites/_placeholder/tile_graybox_rumput.png",
]
## Nama berkas ubin per kolom (pusat -2,5 .. 2,5 ubin) dan ubin polos di luar kolom rumput pertama.
const UBIN_SEBERANG_RUMPUT: String = "tile_perumahan_rumput_seberang.png"
const UBIN_SEBERANG_TROTOAR: String = "tile_perumahan_trotoar_seberang.png"
const UBIN_SEBERANG_ASPAL: String = "tile_perumahan_aspal_seberang.png"
const UBIN_DEKAT_ASPAL: String = "tile_perumahan_aspal_dekat.png"
const UBIN_DEKAT_TROTOAR: String = "tile_perumahan_trotoar_dekat.png"
const UBIN_DEKAT_RUMPUT: String = "tile_perumahan_rumput_dekat.png"
const UBIN_RUMPUT_LUAR: String = "tile_perumahan_rumput_1.png"
## Ubin tambahan run fase5b-tembok-dekor (D-1): variasi rumput polos dan empat ubin khusus. Dicek ada di folder (isi folder) dan sah dirujuk (bagian C: `TanahDaur` mode khusus di `rute.tscn`, diuji `tes_ubin_5b.gd`).
const UBIN_5B: Array[String] = [
	"tile_perumahan_rumput_2.png", "tile_perumahan_rumput_3.png", "tile_perumahan_trotoar_seberang_masuk.png", "tile_perumahan_rumput_seberang_masuk.png",
	"tile_perumahan_trotoar_seberang_simbol.png", "tile_perumahan_trotoar_dekat_simbol.png",
]
## Ubin tambahan run fase5c-animasi-simpang (C-F1 dan simpang T, D-2, P-6): dua ujung kerb jalan masuk seberang, 18 ubin simpang sisi dekat, dan 16 sisi seberang. Ditulis literal;
## letak dan pilihannya diuji `tes_ubin_5b.gd` (ujung) dan `tes_simpang.gd` (simpang).
const UBIN_5C: Array[String] = [
	"tile_perumahan_trotoar_seberang_masuk_ujung.png", "tile_perumahan_rumput_seberang_masuk_ujung.png", "tile_perumahan_simpang_dekat_trotoar_dekat_depan_2.png",
	"tile_perumahan_simpang_dekat_rumput_dekat_depan_2.png", "tile_perumahan_simpang_dekat_lengan_depan_2.png", "tile_perumahan_simpang_dekat_aspal_dekat_depan_1.png",
	"tile_perumahan_simpang_dekat_trotoar_dekat_depan_1.png", "tile_perumahan_simpang_dekat_rumput_dekat_depan_1.png", "tile_perumahan_simpang_dekat_lengan_depan_1.png",
	"tile_perumahan_simpang_dekat_aspal_dekat_mulut_1.png", "tile_perumahan_simpang_dekat_trotoar_dekat_mulut_1.png", "tile_perumahan_simpang_dekat_rumput_dekat_mulut_1.png",
	"tile_perumahan_simpang_dekat_lengan_mulut_1.png", "tile_perumahan_simpang_dekat_aspal_dekat_mulut_2.png", "tile_perumahan_simpang_dekat_trotoar_dekat_mulut_2.png",
	"tile_perumahan_simpang_dekat_rumput_dekat_mulut_2.png", "tile_perumahan_simpang_dekat_lengan_mulut_2.png", "tile_perumahan_simpang_dekat_trotoar_dekat_belakang_1.png",
	"tile_perumahan_simpang_dekat_rumput_dekat_belakang_1.png", "tile_perumahan_simpang_dekat_lengan_belakang_1.png",
	"tile_perumahan_simpang_seberang_rumput_seberang_depan_2.png", "tile_perumahan_simpang_seberang_lengan_depan_2.png", "tile_perumahan_simpang_seberang_trotoar_seberang_depan_1.png",
	"tile_perumahan_simpang_seberang_rumput_seberang_depan_1.png", "tile_perumahan_simpang_seberang_lengan_depan_1.png", "tile_perumahan_simpang_seberang_aspal_seberang_mulut_1.png",
	"tile_perumahan_simpang_seberang_trotoar_seberang_mulut_1.png", "tile_perumahan_simpang_seberang_rumput_seberang_mulut_1.png", "tile_perumahan_simpang_seberang_lengan_mulut_1.png",
	"tile_perumahan_simpang_seberang_aspal_seberang_mulut_2.png", "tile_perumahan_simpang_seberang_trotoar_seberang_mulut_2.png", "tile_perumahan_simpang_seberang_rumput_seberang_mulut_2.png",
	"tile_perumahan_simpang_seberang_lengan_mulut_2.png", "tile_perumahan_simpang_seberang_trotoar_seberang_belakang_1.png", "tile_perumahan_simpang_seberang_rumput_seberang_belakang_1.png",
	"tile_perumahan_simpang_seberang_lengan_belakang_1.png",
]
## Jumlah ubin tanah per lebar viewport (tinggi 360) dari `JalanDaur.sel_tanah` SEBELUM run ini (dihitung dari kode lama, ditulis literal)
## beserta checksum letaknya: sum(int((x + 10) * 2) * 1009 + int(y + 100)).
const SEL_SEBELUM: Array = [[640, 434, 7697851], [667, 450, 8215875], [780, 496, 9313896], [800, 511, 9844926]]
const TINGGI: int = 360
const LEBAR_UJI: Array[int] = [640, 667, 780, 800]
## Tidak boleh ada nama ini di sumber (pemindai AC-17, bagian ubin). Disambung supaya berkas ini tidak cocok dengan dirinya sendiri.
## Run fase5b-tembok-dekor bagian B2: tong sampah logam sah dirujuk (`DekorRute`), hanya `tong_sampah_biru` yang tetap terlarang (D-1, K-2). Bagian B1 run 5B memasang lima tembok; run fase5d-sisi-dekat (P-1) melepasnya lagi, pemindai nama sprite tembok (tidak boleh ada rujukan) ada di `tes_sisi_dekat.gd`.
const TERLARANG: Array[String] = [
	"prop_" + "tong_sampah_biru", "mission_" + "jejak", "mission_" + "mangkuk", "prop_" + "portal", "prop_" + "pos_",
	"vfx_" + "percikan", "polisi_" + "tidur", "perumahan_" + "zebra", "perumahan_" + "genangan",
]

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
	_test_kolom_murni()
	_test_kolom_simetri_dan_jenis()
	_test_rumput_luar()
	_test_sel_tanah_tetap()
	_test_berkas_ubin()
	_test_tanah_enam_tekstur()
	_test_tanah_graybox_tetap()
	await _test_scene_rute()
	_test_tanpa_celah()
	_test_tanpa_pita()
	_test_susunan_referensi()
	_test_tanpa_referensi_tak_dipasang()


# --- Pembantu ---

func _nama_kolom(x: float) -> String:
	return JalanDaur.Kolom.keys()[JalanDaur.kolom_di(x)] as String


func _buat_tanah(enam: bool = true) -> TanahDaur:
	var tanah: TanahDaur = TanahDaur.new()
	if enam:
		tanah.tekstur_kolom_rumput_seberang = load(FOLDER_UBIN + UBIN_SEBERANG_RUMPUT) as Texture2D
		tanah.tekstur_kolom_trotoar_seberang = load(FOLDER_UBIN + UBIN_SEBERANG_TROTOAR) as Texture2D
		tanah.tekstur_kolom_aspal_seberang = load(FOLDER_UBIN + UBIN_SEBERANG_ASPAL) as Texture2D
		tanah.tekstur_kolom_aspal_dekat = load(FOLDER_UBIN + UBIN_DEKAT_ASPAL) as Texture2D
		tanah.tekstur_kolom_trotoar_dekat = load(FOLDER_UBIN + UBIN_DEKAT_TROTOAR) as Texture2D
		tanah.tekstur_kolom_rumput_dekat = load(FOLDER_UBIN + UBIN_DEKAT_RUMPUT) as Texture2D
		tanah.tekstur_rumput_luar = load(FOLDER_UBIN + UBIN_RUMPUT_LUAR) as Texture2D
	else:
		tanah.tekstur_aspal = load(GRAYBOX[0]) as Texture2D
		tanah.tekstur_trotoar = load(GRAYBOX[1]) as Texture2D
		tanah.tekstur_rumput = load(GRAYBOX[2]) as Texture2D
	return tanah


## Semua sprite ubin (di wadah anak langsung) pada `tanah`.
func _sprite_ubin(tanah: TanahDaur) -> Array[Sprite2D]:
	var hasil: Array[Sprite2D] = []
	for wadah: Node in tanah.get_children():
		for anak: Node in wadah.get_children():
			hasil.append(anak as Sprite2D)
	return hasil


## Posisi dunia (ubin) pusat ubin dari posisi layar relatif blok (rumus proyeksi 2:1 ditulis ulang, bukan `Iso`).
func _dunia_dari_layar(layar: Vector2) -> Vector2:
	var x: float = (layar.y / 16.0 + layar.x / 32.0) / 2.0
	var y: float = (layar.y / 16.0 - layar.x / 32.0) / 2.0
	return Vector2(x, y)


func _gambar_tekstur(tekstur: Texture2D) -> Image:
	var kunci: String = tekstur.resource_path
	if not _gambar.has(kunci):
		var g: Image = tekstur.get_image()
		g.convert(Image.FORMAT_RGBA8)
		_gambar[kunci] = g
	return _gambar[kunci] as Image


## Gambar semua sprite ubin ke satu kanvas RGBA seluas `ukuran`, pojok atas kanvas = `asal` (piksel layar).
func _susun(tanah: TanahDaur, asal: Vector2i, ukuran: Vector2i) -> Image:
	var kanvas: Image = Image.create(ukuran.x, ukuran.y, false, Image.FORMAT_RGBA8)
	kanvas.fill(Color(0, 0, 0, 0))
	for ubin: Sprite2D in _sprite_ubin(tanah):
		var g: Image = _gambar_tekstur(ubin.texture)
		var pojok: Vector2i = Vector2i(ubin.position + tanah.position) - Vector2i(g.get_width() / 2, g.get_height() / 2) - asal
		kanvas.blend_rect(g, Rect2i(Vector2i.ZERO, g.get_size()), pojok)
	return kanvas


# --- AC-4: pemetaan kolom ---

func _test_kolom_murni() -> void:
	_judul.call("Ubin enam kolom: pemetaan kolom murni (AC-4, oracle tabel)")
	check(JalanDaur.Kolom.keys() == ["RUMPUT_SEBERANG", "TROTOAR_SEBERANG", "ASPAL_SEBERANG", "ASPAL_DEKAT", "TROTOAR_DEKAT", "RUMPUT_DEKAT"], "enam kolom berurutan dari seberang ke dekat")
	check(JalanDaur.Kolom.RUMPUT_SEBERANG == 0 and JalanDaur.Kolom.ASPAL_DEKAT == 3 and JalanDaur.Kolom.RUMPUT_DEKAT == 5, "nilai enum kolom 0 sampai 5 (urutan KOLOM renderer)")
	var tabel: Array = [
		# pusat ubin
		[-2.5, "RUMPUT_SEBERANG"], [-1.5, "TROTOAR_SEBERANG"], [-0.5, "ASPAL_SEBERANG"], [0.5, "ASPAL_DEKAT"], [1.5, "TROTOAR_DEKAT"], [2.5, "RUMPUT_DEKAT"],
		# di luar kolom rumput pertama dan nilai besar
		[-3.5, "RUMPUT_SEBERANG"], [3.5, "RUMPUT_DEKAT"], [-40.5, "RUMPUT_SEBERANG"], [40.5, "RUMPUT_DEKAT"],
		# batas rumput-trotoar (|x| = 2, ke kolom luar) dan sisinya
		[-2.0001, "RUMPUT_SEBERANG"], [-2.0, "RUMPUT_SEBERANG"], [-1.9999, "TROTOAR_SEBERANG"],
		[1.9999, "TROTOAR_DEKAT"], [2.0, "RUMPUT_DEKAT"], [2.0001, "RUMPUT_DEKAT"],
		# batas trotoar-aspal (|x| = 1, ke kolom luar)
		[-1.0001, "TROTOAR_SEBERANG"], [-1.0, "TROTOAR_SEBERANG"], [-0.9999, "ASPAL_SEBERANG"],
		[0.9999, "ASPAL_DEKAT"], [1.0, "TROTOAR_DEKAT"], [1.0001, "TROTOAR_DEKAT"],
		# garis tengah jalan: nol dan positif = dekat
		[-0.0001, "ASPAL_SEBERANG"], [0.0, "ASPAL_DEKAT"], [0.0001, "ASPAL_DEKAT"],
	]
	for baris: Array in tabel:
		check(_nama_kolom(baris[0] as float) == baris[1], "kolom_di(%s) = %s (dapat %s)" % [baris[0], baris[1], _nama_kolom(baris[0] as float)])
	check(Config.JALAN_LEBAR_UBIN == 2.0 and Config.JALAN_TROTOAR_UBIN == 1.0 and Config.JALAN_RUMPUT_TEPI_UBIN == 1.0, "lebar aspal 2 ubin, trotoar 1 ubin per sisi tidak berubah (K-3), kolom rumput pertama 1 ubin")


func _test_kolom_simetri_dan_jenis() -> void:
	_judul.call("Ubin enam kolom: simetri seberang/dekat dan konsisten dengan jenis_di (AC-4)")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 5301
	var simetri: bool = true
	var jenis_sama: bool = true
	var contoh_salah: String = ""
	var nilai: Array[float] = [0.25, 0.5, 0.75, 0.9999, 1.0, 1.0001, 1.5, 1.9999, 2.0, 2.0001, 2.5, 2.9999, 3.0, 3.5, 7.25, 40.5]
	for i: int in range(300):
		nilai.append(rng.randf_range(0.001, 12.0))
	for x: float in nilai:
		var dekat: String = _nama_kolom(x)
		var seberang: String = _nama_kolom(-x)
		var cermin: String = dekat.replace("_DEKAT", "_SEBERANG")
		if seberang != cermin or not dekat.ends_with("_DEKAT") or not seberang.ends_with("_SEBERANG"):
			simetri = false
			contoh_salah = "%s: %s vs %s" % [x, dekat, seberang]
		var awalan: String = dekat.split("_")[0]
		var jenis_harapan: String = "ASPAL" if x < 1.0 else ("TROTOAR" if x < 2.0 else "RUMPUT")
		if awalan != jenis_harapan or JalanDaur.Jenis.keys()[JalanDaur.jenis_di(x)] != jenis_harapan or JalanDaur.Jenis.keys()[JalanDaur.jenis_di(-x)] != jenis_harapan:
			jenis_sama = false
			contoh_salah = "%s: awalan %s jenis harapan %s" % [x, awalan, jenis_harapan]
	check(simetri, "kolom_di(-x) = cermin seberang/dekat dari kolom_di(x) untuk %d nilai (%s)" % [nilai.size(), contoh_salah])
	check(jenis_sama, "jenis kolom (aspal/trotoar/rumput) sama dengan jenis_di di kedua sisi (%s)" % contoh_salah)
	check(JalanDaur.jenis_di(0.5) == JalanDaur.Jenis.ASPAL and JalanDaur.jenis_di(-1.5) == JalanDaur.Jenis.TROTOAR and JalanDaur.jenis_di(-40.5) == JalanDaur.Jenis.RUMPUT, "jenis_di lama tidak berubah")


func _test_rumput_luar() -> void:
	_judul.call("Ubin enam kolom: rumput di luar kolom pertama memakai ubin polos (D-2)")
	var tabel: Array = [
		[0.5, false], [-0.5, false], [1.5, false], [-1.5, false], [2.0, false], [2.5, false], [-2.5, false], [2.9999, false], [-2.9999, false],
		[3.0, true], [-3.0, true], [3.0001, true], [3.5, true], [-3.5, true], [4.5, true], [-40.5, true], [40.5, true],
	]
	for baris: Array in tabel:
		check(JalanDaur.rumput_luar(baris[0] as float) == baris[1], "rumput_luar(%s) = %s" % [baris[0], baris[1]])


func _test_sel_tanah_tetap() -> void:
	_judul.call("Ubin enam kolom: sel_tanah tidak berubah dari sebelum run (AC-4)")
	for baris: Array in SEL_SEBELUM:
		var lebar: int = baris[0]
		var sel: PackedVector2Array = JalanDaur.sel_tanah(lebar, TINGGI)
		var cs: int = 0
		for p: Vector2 in sel:
			cs += int((p.x + 10.0) * 2) * 1009 + int(p.y + 100.0)
		check(sel.size() == baris[1] and cs == baris[2], "sel_tanah(%d, %d): %d ubin, checksum %d (harapan %d ubin, %d)" % [lebar, TINGGI, sel.size(), cs, baris[1], baris[2]])
	check(BikeMotion.batas_lateral_ubin() == 2.0, "batas tepi jalan resmi tetap 2 ubin")


# --- AC-3 (sisi Godot) dan AC-5 ---

func _test_berkas_ubin() -> void:
	_judul.call("Ubin enam kolom: berkas ubin termuat 64x32 (AC-3)")
	for nama: String in [UBIN_SEBERANG_RUMPUT, UBIN_SEBERANG_TROTOAR, UBIN_SEBERANG_ASPAL, UBIN_DEKAT_ASPAL, UBIN_DEKAT_TROTOAR, UBIN_DEKAT_RUMPUT, UBIN_RUMPUT_LUAR]:
		var tekstur: Texture2D = load(FOLDER_UBIN + nama) as Texture2D
		check(tekstur != null and tekstur.get_width() == 64 and tekstur.get_height() == 32, "%s termuat dan 64x32" % nama)
		var g: Image = _gambar_tekstur(tekstur) if tekstur != null else null
		var opak: int = 0
		if g != null:
			for y: int in range(32):
				for x: int in range(64):
					if g.get_pixel(x, y).a > 0.999:
						opak += 1
		check(opak == 1024, "%s: belah ketupat 1.024 piksel opak (dapat %d)" % [nama, opak])


## Hitung ubin di `tanah` yang memakai tekstur kolom yang benar menurut oracle literal per kolom pusat (setengah ganjil). Kembali [benar, total, contoh salah, per_nama].
func _hitung_tekstur_benar(tanah: TanahDaur) -> Array:
	var sprite: Array[Sprite2D] = _sprite_ubin(tanah)
	var benar: int = 0
	var salah_contoh: String = ""
	var per_nama: Dictionary = {}
	for ubin: Sprite2D in sprite:
		var x: float = _dunia_dari_layar(ubin.position).x
		var harapan: String = UBIN_RUMPUT_LUAR
		if x > -3.0 and x < -2.0:
			harapan = UBIN_SEBERANG_RUMPUT
		elif x > -2.0 and x < -1.0:
			harapan = UBIN_SEBERANG_TROTOAR
		elif x > -1.0 and x < 0.0:
			harapan = UBIN_SEBERANG_ASPAL
		elif x > 0.0 and x < 1.0:
			harapan = UBIN_DEKAT_ASPAL
		elif x > 1.0 and x < 2.0:
			harapan = UBIN_DEKAT_TROTOAR
		elif x > 2.0 and x < 3.0:
			harapan = UBIN_DEKAT_RUMPUT
		var jalur: String = ubin.texture.resource_path
		per_nama[jalur.get_file()] = int(per_nama.get(jalur.get_file(), 0)) + 1
		if jalur == FOLDER_UBIN + harapan:
			benar += 1
		elif UBIN_5B.has(jalur.get_file()) or UBIN_5C.has(jalur.get_file()):
			# Run fase5b-tembok-dekor bagian C: ubin khusus (masuk, simbol, rumput_2 dan _3) menggantikan tekstur kolom di sel tertentu pada TanahDaur mode khusus (scene rute);
			# letak dan pilihannya diuji di tes_ubin_5b.gd (oracle per sel). Di sini cukup bahwa tekstur itu ada di daftar ubin 5B yang dipasang.
			benar += 1
		elif salah_contoh.is_empty():
			salah_contoh = "x %s tekstur %s harapan %s" % [x, jalur.get_file(), harapan]
	return [benar, sprite.size(), salah_contoh, per_nama]


func _test_tanah_enam_tekstur() -> void:
	_judul.call("Ubin enam kolom: TanahDaur memasang tekstur kolom yang benar (AC-5)")
	var tanah: TanahDaur = _buat_tanah(true)
	tanah.bangun(Config.LAYAR_LEBAR_MAKS_PX, Config.LAYAR_TINGGI_DASAR_PX)
	tanah.perbarui(0.0)
	check(tanah.mode_enam_kolom(), "enam tekstur terisi = mode enam kolom")
	var sprite: Array[Sprite2D] = _sprite_ubin(tanah)
	var hitung: Array = _hitung_tekstur_benar(tanah)
	var benar: int = hitung[0]
	var salah_contoh: String = hitung[2]
	var per_nama: Dictionary = hitung[3]
	var bulat: int = 0
	for ubin: Sprite2D in sprite:
		if ubin.position == ubin.position.round():
			bulat += 1
	check(sprite.size() > 300 and benar == sprite.size(), "tiap ubin di kolom x memakai tekstur kolom itu: %d dari %d (%s)" % [benar, sprite.size(), salah_contoh])
	check(bulat == sprite.size(), "posisi semua ubin bilangan bulat (piksel tajam)")
	check(per_nama.size() == 7, "tujuh tekstur terpakai (enam kolom + rumput polos luar), dapat %s" % [per_nama.keys()])
	var nama_wadah: Array[String] = []
	for wadah: Node in tanah.get_children():
		nama_wadah.append(String(wadah.name))
	check(nama_wadah == ["RumputSeberang", "TrotoarSeberang", "AspalSeberang", "AspalDekat", "TrotoarDekat", "RumputDekat", "RumputLuar"], "satu wadah per kolom ditambah RumputLuar (tiap wadah satu tekstur supaya gambar tergabung): %s" % [nama_wadah])
	for wadah: Node in tanah.get_children():
		var tekstur_wadah: Dictionary = {}
		for anak: Node in wadah.get_children():
			tekstur_wadah[(anak as Sprite2D).texture.resource_path] = true
		check(tekstur_wadah.size() == 1, "wadah %s memakai tepat satu tekstur" % wadah.name)
	# tekstur_di mengikuti kolom_di dan rumput_luar
	check(tanah.tekstur_di(-2.5).resource_path.get_file() == UBIN_SEBERANG_RUMPUT and tanah.tekstur_di(2.5).resource_path.get_file() == UBIN_DEKAT_RUMPUT, "tekstur_di: kolom rumput pertama memakai ubin tepi kerb")
	check(tanah.tekstur_di(-3.5).resource_path.get_file() == UBIN_RUMPUT_LUAR and tanah.tekstur_di(3.5).resource_path.get_file() == UBIN_RUMPUT_LUAR, "tekstur_di: kolom rumput di luarnya memakai rumput polos")
	tanah.free()


func _test_tanah_graybox_tetap() -> void:
	_judul.call("Ubin enam kolom: mode graybox (jalan uji, spike) tidak berubah dan jumlah node ubin sama (AC-5, AC-7)")
	var tiga: TanahDaur = _buat_tanah(false)
	var enam: TanahDaur = _buat_tanah(true)
	var ok: bool = true
	for lebar: int in LEBAR_UJI:
		tiga.bangun(lebar, TINGGI)
		enam.bangun(lebar, TINGGI)
		var n3: int = _sprite_ubin(tiga).size()
		var n6: int = _sprite_ubin(enam).size()
		var harapan: int = JalanDaur.sel_tanah(lebar, TINGGI).size()
		check(n3 == harapan and n6 == harapan, "lebar %d: jumlah sprite ubin sama di mode graybox (%d) dan enam kolom (%d) = sel_tanah (%d)" % [lebar, n3, n6, harapan])
		var posisi3: Dictionary = {}
		for u: Sprite2D in _sprite_ubin(tiga):
			posisi3[u.position] = true
		for u: Sprite2D in _sprite_ubin(enam):
			if not posisi3.has(u.position):
				ok = false
	check(ok, "posisi ubin enam kolom = posisi ubin graybox (tidak berubah dari sebelumnya)")
	var nama3: Array[String] = []
	for wadah: Node in tiga.get_children():
		nama3.append(String(wadah.name))
	check(not tiga.mode_enam_kolom() and nama3 == ["Aspal", "Trotoar", "Rumput"], "mode graybox: wadah Aspal, Trotoar, Rumput (jalan uji dan spike tidak berubah)")
	tiga.free()
	enam.free()
	# Jalan uji dan spike tetap graybox; rute tidak lagi merujuk graybox.
	var rute: String = FileAccess.get_file_as_string(BERKAS_RUTE)
	check(not rute.contains("tile_graybox"), "rute.tscn tidak merujuk tile_graybox_* lagi")
	check(rute.contains("tile_perumahan_rumput_seberang.png") and rute.contains("tile_perumahan_rumput_1.png") and rute.contains("tile_perumahan_aspal_dekat.png"), "rute.tscn merujuk ubin perumahan")
	for berkas: String in ["res://scenes/dev/jalan_uji.tscn", "res://scenes/dev/graybox.tscn", "res://scenes/dev/spike_sisi_dekat.tscn"]:
		var teks: String = FileAccess.get_file_as_string(berkas)
		check(teks.contains("tile_graybox_aspal.png") and not teks.contains("tile_perumahan"), "%s tetap graybox (scene dev tidak disentuh)" % berkas.get_file())
	check(FileAccess.get_file_as_string("res://scripts/dev/cek_render.gd").contains("tile_graybox_aspal.png"), "cek_render tetap graybox")
	check(FileAccess.file_exists(GRAYBOX[0]) and FileAccess.file_exists(GRAYBOX[1]) and FileAccess.file_exists(GRAYBOX[2]), "ubin graybox tetap ada (dipakai scene dev)")


func _test_scene_rute() -> void:
	_judul.call("Ubin enam kolom: scene rute memasang enam tekstur (AC-5)")
	_tree.root.size = Vector2i(2340, 1080)
	var akar: Node = (load(BERKAS_RUTE) as PackedScene).instantiate()
	_tree.root.add_child(akar)
	await _tree.process_frame
	await _tree.process_frame
	var tanah: TanahDaur = akar.find_child("Tanah", true, false) as TanahDaur
	check(tanah != null and tanah.mode_enam_kolom(), "Tanah di rute.tscn memakai enam kolom")
	if tanah != null:
		var sprite: Array[Sprite2D] = _sprite_ubin(tanah)
		check(sprite.size() == JalanDaur.sel_tanah(Config.LAYAR_LEBAR_MAKS_PX, Config.LAYAR_TINGGI_DASAR_PX).size(), "scene rute: jumlah sprite ubin = sel_tanah lebar maksimal (%d)" % sprite.size())
		var graybox: int = 0
		var perumahan: int = 0
		for u: Sprite2D in sprite:
			var jalur: String = u.texture.resource_path
			if jalur.contains("tile_graybox"):
				graybox += 1
			if jalur.begins_with(FOLDER_UBIN):
				perumahan += 1
		check(graybox == 0 and perumahan == sprite.size(), "scene rute: semua ubin dari tiles/perumahan, tidak ada graybox")
		var hitung: Array = _hitung_tekstur_benar(tanah)
		# Run fase5b-tembok-dekor bagian C: scene rute memakai mode khusus, jadi selain tujuh tekstur lama muncul rumput_2, rumput_3, dan simbol (jalan masuk hanya bila ada mobil di dekat sepeda).
		var nama_hitung: Dictionary = hitung[3]
		var lama_semua: bool = true
		for nama_lama: String in [UBIN_SEBERANG_RUMPUT, UBIN_SEBERANG_TROTOAR, UBIN_SEBERANG_ASPAL, UBIN_DEKAT_ASPAL, UBIN_DEKAT_TROTOAR, UBIN_DEKAT_RUMPUT, UBIN_RUMPUT_LUAR]:
			if not nama_hitung.has(nama_lama):
				lama_semua = false
		check(int(hitung[0]) == sprite.size() and lama_semua and nama_hitung.size() >= 7 and nama_hitung.size() <= 7 + UBIN_5B.size() + UBIN_5C.size(), "scene rute: tiap ubin memakai tekstur kolomnya atau ubin khusus 5B/5C, ketujuh tekstur lama terpakai: %d dari %d (%s) %s" % [hitung[0], sprite.size(), hitung[2], nama_hitung.keys()])
	_tree.root.remove_child(akar)
	akar.free()


# --- AC-6: tanpa celah dan tanpa pita ---

func _test_tanpa_celah() -> void:
	_judul.call("Ubin enam kolom: tanpa celah transparan di seluruh viewport (AC-6)")
	var tanah: TanahDaur = _buat_tanah(true)
	var lebar_semua: Array[int] = [640, 667, 780, 800, Config.LAYAR_LEBAR_MAKS_PX]
	var lateral: Array[float] = [-BikeMotion.batas_lateral_ubin(), -2.0, 0.0, 1.0, 2.0, BikeMotion.batas_lateral_ubin()]
	var jarak: Array[float] = [0.0, 0.4, 13.0, 99.99, 100.0, 237.31]
	var total: int = 0
	var celah_total: int = 0
	var contoh: String = ""
	for lebar: int in lebar_semua:
		tanah.bangun(lebar, TINGGI)
		for jarak_ubin: float in jarak:
			tanah.perbarui(jarak_ubin)
			for lat: float in lateral:
				# viewport terlihat: sepeda di 1/3 lebar dan 0,75 tinggi (Config), digeser dorongan (kamera = sepeda - sasaran - geser). Dorongan mundur terbesar
				# sengaja tidak dicakup: sel_tanah (tidak berubah, AC-4) tidak memuatnya dan jalan graybox lama punya celah sudut yang sama di lebar 640
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
	check(total == 5 * 6 * 6 * 2 and celah_total == 0, "nol piksel transparan di %d viewport (lebar 640, 667, 780, 800, maks; lateral -2 .. +2; 6 jarak; tanpa dan dengan dorongan maju terbesar): %s" % [total, contoh])
	tanah.free()


func _test_tanpa_pita() -> void:
	_judul.call("Ubin enam kolom: rumput di luar kolom pertama tanpa pita tepi berulang (AC-6, D-2)")
	var tanah: TanahDaur = _buat_tanah(true)
	tanah.bangun(Config.LAYAR_LEBAR_MAKS_PX, TINGGI)
	tanah.perbarui(0.0)
	var lebar: int = Config.LAYAR_LEBAR_MAKS_PX
	var asal: Vector2i = Vector2i(-lebar / 3, -270)
	var kanvas: Image = _susun(tanah, asal, Vector2i(lebar, TINGGI))
	var diperiksa: int = 0
	var beda: int = 0
	# Pergeseran satu ubin melintang (+32, +16) dan satu ubin maju (-32, +16) harus mengembalikan piksel sama di wilayah rumput polos.
	for geser: Vector2i in [Vector2i(32, 16), Vector2i(-32, 16)]:
		for y: int in range(0, TINGGI - 16):
			for x: int in range(maxi(0, -geser.x), lebar - maxi(0, geser.x)):
				var sx: float = x + 0.5 + asal.x
				var sy: float = y + 0.5 + asal.y
				var gx: float = (sy / 16.0 + sx / 32.0) / 2.0
				var gy: float = (sy / 16.0 - sx / 32.0) / 2.0
				var sx2: float = sx + geser.x
				var sy2: float = sy + geser.y
				var gx2: float = (sy2 / 16.0 + sx2 / 32.0) / 2.0
				var luar: bool = (gx <= -3.01 and gx2 <= -3.01) or (gx >= 3.01 and gx2 >= 3.01)
				if not luar:
					continue
				diperiksa += 1
				if kanvas.get_pixel(x, y) != kanvas.get_pixel(x + geser.x, y + geser.y):
					beda += 1
	check(diperiksa > 20000, "wilayah rumput luar cukup luas diperiksa (%d piksel)" % diperiksa)
	check(beda == 0, "rumput luar periodik per ubin ke dua arah: %d piksel beda dari %d (pita tepi kerb berulang = beda)" % [beda, diperiksa])
	# Ubin kolom luar piksel-identik dengan rumput polos (rumput_1), dan beda dari ubin tepi kerb rumput_seberang (yang membawa tepi kerb).
	var polos: Image = _gambar_tekstur(load(FOLDER_UBIN + UBIN_RUMPUT_LUAR) as Texture2D)
	var tepi: Image = _gambar_tekstur(load(FOLDER_UBIN + UBIN_SEBERANG_RUMPUT) as Texture2D)
	var tepi_dekat: Image = _gambar_tekstur(load(FOLDER_UBIN + UBIN_DEKAT_RUMPUT) as Texture2D)
	var sama_luar: bool = true
	for u: Sprite2D in _sprite_ubin(tanah):
		if absf(_dunia_dari_layar(u.position).x) > 3.0:
			if _gambar_tekstur(u.texture).get_data() != polos.get_data():
				sama_luar = false
	check(sama_luar, "semua ubin kolom luar piksel-identik dengan rumput polos rumput_1")
	check(tepi.get_data() != polos.get_data(), "ubin rumput_seberang membawa tepi kerb (beda dari rumput polos), jadi tidak boleh diulang di kolom luar")
	check(tepi_dekat.get_data() == polos.get_data(), "ubin rumput_dekat identik piksel dengan rumput polos (kerb luar sisi dekat tidak menjorok ke kolom rumput)")
	tanah.free()


func _test_susunan_referensi() -> void:
	_judul.call("Ubin enam kolom: susunan Godot piksel-identik dengan referensi Python 8 ubin maju (AC-6)")
	var tanah: TanahDaur = _buat_tanah(true)
	tanah.bangun(Config.LAYAR_LEBAR_MAKS_PX, Config.LAYAR_TINGGI_DASAR_PX)
	tanah.perbarui(0.0)
	var ref: Image = Image.load_from_file(ProjectSettings.globalize_path(REFERENSI))
	check(ref != null and not ref.is_empty(), "berkas referensi tests/data/ubin_potongan_8_maju.png terbaca")
	if ref == null or ref.is_empty():
		tanah.free()
		return
	ref.convert(Image.FORMAT_RGBA8)
	# Kumpulkan hanya ubin pusat x -3,5 .. 3,5 dan maju 0 .. 7 (pusat y 0 .. -7), lalu susun dengan asal yang sama dengan referensi.
	var terpilih: Array[Sprite2D] = []
	for u: Sprite2D in _sprite_ubin(tanah):
		var d: Vector2 = _dunia_dari_layar(u.position)
		if absf(d.x) < 4.0 and d.y <= 0.001 and d.y >= -7.001:
			terpilih.append(u)
	check(terpilih.size() == 64, "ada 64 ubin (8 kolom x 8 ubin maju) di potongan, dapat %d" % terpilih.size())
	var x_min: int = 1 << 30
	var y_min: int = 1 << 30
	for u: Sprite2D in terpilih:
		x_min = mini(x_min, int(u.position.x) - 32)
		y_min = mini(y_min, int(u.position.y) - 16)
	var kanvas: Image = Image.create(ref.get_width(), ref.get_height(), false, Image.FORMAT_RGBA8)
	kanvas.fill(Color(0, 0, 0, 0))
	for u: Sprite2D in terpilih:
		var g: Image = _gambar_tekstur(u.texture)
		kanvas.blend_rect(g, Rect2i(Vector2i.ZERO, g.get_size()), Vector2i(int(u.position.x) - 32 - x_min, int(u.position.y) - 16 - y_min))
	check(kanvas.get_size() == ref.get_size(), "ukuran susunan = referensi (%s)" % [ref.get_size()])
	check(kanvas.get_data() == ref.get_data(), "susunan TanahDaur 8 ubin maju piksel-identik dengan referensi Python (komposisi berkas assets/)")
	tanah.free()


# --- AC-7 dan AC-17 (bagian ubin): aset ubin yang tidak dipasang tidak dirujuk ---

func _test_tanpa_referensi_tak_dipasang() -> void:
	_judul.call("Ubin enam kolom: tidak ada rujukan ke aset yang belum dipasang (AC-7, AC-17 bagian ubin)")
	var folder: Array[String] = ["res://scripts", "res://scenes", "res://assets/data", "res://translations"]
	var berkas: Array[String] = ["res://project.godot", "res://export_presets.cfg"]
	for akar: String in folder:
		_kumpulkan(akar, berkas)
	var tes: DirAccess = DirAccess.open("res://tests")
	for nama: String in tes.get_files():
		if nama.ends_with(".gd") and not nama.begins_with("probe_") and nama != "tes_ubin.gd":
			berkas.append("res://tests/" + nama)
	var temuan: Array[String] = []
	for jalur: String in berkas:
		var teks: String = FileAccess.get_file_as_string(jalur)
		for kata: String in TERLARANG:
			if teks.contains(kata):
				temuan.append("%s memuat %s" % [jalur, kata])
		for nama: String in _rujukan_ubin_tak_dipasang(teks):
			temuan.append("%s memuat %s" % [jalur, nama])
	check(berkas.size() > 100, "pemindai membaca banyak berkas sumber (%d)" % berkas.size())
	check(temuan.is_empty(), "tidak ada rujukan ke aset yang belum dipasang: %s" % [temuan])
	# Run fase5c-animasi-simpang (AC-22): pemindai diperluas ke ubin simpang dan ujung kerb. Contoh buruk sintetis (nama disambung supaya
	# berkas ini sendiri tidak memuatnya) harus tertangkap; nama yang dipasang (`UBIN_5B`, `UBIN_5C`) tidak.
	var awal: String = "tile_perumahan_"
	for buruk: String in ["simpang_dekat_aspal_dekat_depan_2", "simpang_seberang_aspal_seberang_depan_1", "simpang_dekat_lengan_mulut_3", "trotoar_dekat_masuk_ujung", "rumput_dekat_masuk_ujung", "aspal_2", "trotoar_dekat_masuk"]:
		var dapat: Array[String] = _rujukan_ubin_tak_dipasang("var t = \"res://assets/sprites/tiles/perumahan/" + awal + buruk + ".png\"")
		check(dapat.size() == 1 and dapat[0] == awal + buruk,"pemindai menandai ubin tak dipasang %s, dapat %s" % [buruk, dapat])
	var sah: String = ""
	for nama: String in UBIN_5B + UBIN_5C:
		sah += "res://assets/sprites/tiles/perumahan/" + nama + "\n"
	check(_rujukan_ubin_tak_dipasang(sah).is_empty(), "pemindai tidak menandai %d ubin 5B/5C yang dipasang: %s" % [UBIN_5B.size() + UBIN_5C.size(), _rujukan_ubin_tak_dipasang(sah)])
	# Ubin yang dipasang: tujuh PNG run 5A, enam PNG run 5B, dan satu JSON di folder (hasil salin, selain .import/.uid).
	var isi: Array[String] = []
	for nama: String in DirAccess.get_files_at(FOLDER_UBIN):
		if not nama.ends_with(".import") and not nama.ends_with(".uid"):
			isi.append(nama)
	isi.sort()
	var harapan_isi: Array[String] = ["tile_perumahan.json", UBIN_DEKAT_ASPAL, UBIN_DEKAT_RUMPUT, UBIN_DEKAT_TROTOAR, UBIN_RUMPUT_LUAR, UBIN_SEBERANG_ASPAL, UBIN_SEBERANG_RUMPUT, UBIN_SEBERANG_TROTOAR]
	harapan_isi.append_array(UBIN_5B)
	harapan_isi.append_array(UBIN_5C)
	harapan_isi.sort()
	check(isi == harapan_isi, "folder tiles/perumahan hanya berisi ubin yang dipasang: %s" % [isi])


## Nama ubin (tanpa .png) di `teks` yang tidak dipasang: aspal_N, rumput_[02-9] selain rumput_2/3, *_masuk, *_simbol, *_masuk_ujung, dan
## simpang_* yang tidak ada di `UBIN_5B`/`UBIN_5C`. Run fase5b-tembok-dekor bagian C (AC-18): hanya enam nama 5B sah; run fase5c (AC-22): hanya
## 36 nama 5C sah (ujung kerb seberang, simpang yang dipasang). Alternatif simpang dan ujung ditulis lebih dulu supaya tidak terpotong `_masuk`.
func _rujukan_ubin_tak_dipasang(teks: String) -> Array[String]:
	var hasil_nama: Array[String] = []
	var regex: RegEx = RegEx.new()
	regex.compile("tile_perumahan_(simpang_[a-z0-9_]*[0-9]|[a-z_]*_masuk_ujung|aspal_[0-9]|rumput_[02-9]|[a-z_]*_masuk|[a-z_]*_simbol)")
	for hasil: RegExMatch in regex.search_all(teks):
		if UBIN_5B.has(hasil.get_string() + ".png") or UBIN_5C.has(hasil.get_string() + ".png"):
			continue
		hasil_nama.append(hasil.get_string())
	return hasil_nama


func _kumpulkan(folder: String, hasil: Array[String]) -> void:
	for nama: String in DirAccess.get_files_at(folder):
		if nama.ends_with(".gd") or nama.ends_with(".tscn") or nama.ends_with(".tres") or nama.ends_with(".json") or nama.ends_with(".csv") or nama.ends_with(".cfg"):
			hasil.append(folder + "/" + nama)
	for sub: String in DirAccess.get_directories_at(folder):
		_kumpulkan(folder + "/" + sub, hasil)
