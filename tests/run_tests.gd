extends SceneTree
## Runner tes headless tanpa framework (rule `testing`, TECH_PLAN 3.6).
##
## Jalankan (setelah `godot --headless --import` sekali, supaya `class_name` dikenali):
##   godot --headless --script res://tests/run_tests.gd 2>&1 | tee build/tests.log
##   python3 tools/cek_keluaran_tes.py build/tests.log
## Keluaran: `GAGAL: <label>` untuk tiap kegagalan, lalu satu baris ringkasan `N lolos, M gagal`.
## Exit code 1 bila ada yang gagal. Exit code saja tidak cukup: error skrip tidak mengubahnya,
## jadi pemeriksa keluaran (`tools/cek_keluaran_tes.py`) wajib dipakai juga.

const BERKAS_SHEET: String = "res://assets/sprites/loper/loper_agen.png"
const BERKAS_FRAMES: String = "res://assets/sprites/loper/loper_agen_frames.tres"
const BERKAS_JSON: String = "res://assets/sprites/loper/loper_agen.json"
const BERKAS_CONFIG: String = "res://scripts/config.gd"
const BERKAS_SCENE_PEMAIN: String = "res://scenes/entities/loper_agen.tscn"
const BERKAS_SCENE_UTAMA: String = "res://scenes/dev/graybox.tscn"
const BERKAS_DESIGN_SPEC: String = "res://docs/design/DESIGN_SPEC.md"
const BERKAS_ART_DIRECTION: String = "res://docs/ART_DIRECTION.md"
const BERKAS_GPL: String = "res://assets/palette/loper_master.gpl"

## Ukuran jendela uji layar: [lebar, tinggi, viewport_lebar_diharapkan, viewport_tinggi, skala].
## 1920x1080 = 16:9, 2340x1080 = 19,5:9 (Samsung A54), 2400x1080 = 20:9, sisanya setengah ukuran (x2).
const KASUS_LAYAR: Array = [
	[1920, 1080, 640, 360, 3],
	[2340, 1080, 780, 360, 3],
	[2400, 1080, 800, 360, 3],
	[1280, 720, 640, 360, 2],
	[1560, 720, 780, 360, 2],
	[1600, 720, 800, 360, 2],
	[2560, 1440, 640, 360, 4],
]
## Ukuran jendela yang tidak kelipatan bulat: skala tetap bilangan bulat (sisanya jadi tepi kosong).
const KASUS_LAYAR_PECAHAN: Array = [
	[1170, 540],
	[1500, 700],
	[2000, 900],
	[2310, 1080],
	[2412, 1080],
]

var _lolos: int = 0
var _gagal: int = 0


func _initialize() -> void:
	_test_config_parser()
	_test_tingkat_sprite()
	_test_arah_sprite()
	_test_nama_animasi_dan_frames()
	_test_scene_pemain()
	await process_frame  # root baru ada di scene tree setelah satu frame
	_test_scene_pemain_di_tree()
	await _test_graybox_di_tree()
	_test_pengaturan_proyek()
	_test_layar_integer()
	_test_palet()
	_test_lisensi_font()
	_test_tanpa_hex_di_luar_palet()
	_test_gaya_kode()
	print("%d lolos, %d gagal" % [_lolos, _gagal])
	quit(1 if _gagal > 0 else 0)


## Mencatat satu pemeriksaan. Kegagalan dicetak sebagai `GAGAL: <label>`.
func check(kondisi: bool, label: String) -> void:
	if kondisi:
		_lolos += 1
	else:
		_gagal += 1
		print("GAGAL: %s" % label)


func _judul(teks: String) -> void:
	print("== %s ==" % teks)


# --- a. Parser config.gd (rule `balancing`, BALANCING 1) ---

func _test_config_parser() -> void:
	_judul("Parser config.gd")
	var baik: String = "\n".join([
		"class_name Contoh",
		"extends RefCounted",
		"## komentar dokumentasi",
		"# komentar biasa",
		"",
		"const A: int = 5",
		"const B: float = 3.0",
		"const C: bool = true",
		"const D: String = \"teks, ada koma\"",
		"const E: Array[int] = [1, 2, 3]",
		"const F: Array[float] = [0.5, 1.5]",
		"const G: float = -0.25",
		"const H: Array[String] = [\"a, b\", \"c\"]",
		"const I: int = -7 # komentar di ujung baris",
		"const J: Array[int] = []",
		"const K: float = 1.5e3",
	])
	var hasil: Dictionary = ConfigParser.parse(baik)
	var konstanta: Dictionary = hasil["konstanta"]
	check(ConfigParser.valid(hasil), "contoh baik (int, float, bool, String, array, negatif, komentar ujung baris) lolos tanpa galat: %s" % [hasil["galat"]])
	check(konstanta.size() == 11, "contoh baik memuat 11 konstanta, terbaca %d" % konstanta.size())
	if konstanta.has("A") and konstanta.has("B") and konstanta.has("C") and konstanta.has("D"):
		check(konstanta["A"]["nilai"] == 5 and konstanta["A"]["tipe"] == "int", "int 5 terbaca sebagai int")
		check(is_equal_approx(konstanta["B"]["nilai"], 3.0), "float 3.0 terbaca 3.0")
		check(konstanta["C"]["nilai"] == true, "bool true terbaca true")
		check(konstanta["D"]["nilai"] == "teks, ada koma", "String berkoma terbaca utuh")
	if konstanta.has("E") and konstanta.has("H") and konstanta.has("I") and konstanta.has("J"):
		check(konstanta["E"]["nilai"] == [1, 2, 3], "Array[int] terbaca [1, 2, 3]")
		check(konstanta["H"]["nilai"] == ["a, b", "c"], "Array[String] dengan koma di dalam teks terbaca benar")
		check(konstanta["I"]["nilai"] == -7, "komentar di ujung baris dibuang dan nilai negatif terbaca")
		check(konstanta["J"]["nilai"] == [], "array kosong diterima")

	var buruk: Dictionary = {
		"konstanta multi-baris": "const X: Array[int] = [\n\t1,\n\t2,\n]",
		"ekspresi angka": "const X: int = 2 * 3",
		"ekspresi referensi konstanta + angka": "const X: float = A * 2.0",
		"referensi ke konstanta lain": "const Y: int = X",
		"tanpa tipe": "const X = 5",
		"tipe inferensi (:=)": "const X := 5",
		"nama huruf kecil": "const kecepatan: float = 3.0",
		"nama campur huruf": "const Kecepatan: float = 3.0",
		"float tanpa titik desimal": "const X: float = 3",
		"int diberi nilai float": "const X: int = 3.5",
		"tipe tidak didukung": "const X: Vector2 = 1",
		"bool salah ketik": "const X: bool = TRUE",
		"String tanpa kutip": "const X: String = teks",
		"var di dalam config": "var x: int = 1",
		"fungsi di dalam config": "func f() -> void:\n\tpass",
		"const ditulis dua kali": "const X: int = 1\nconst X: int = 2",
		"const tanpa nilai": "const X: int",
		"array tidak ditutup": "const X: Array[int] = [1, 2",
		"elemen array salah tipe": "const X: Array[int] = [1, 2.5]",
		"baris berindentasi": "\tconst X: int = 1",
		"pemanggilan fungsi": "const X: float = absf(-3.0)",
	}
	for nama: String in buruk:
		var hasil_buruk: Dictionary = ConfigParser.parse(buruk[nama])
		check(not ConfigParser.valid(hasil_buruk), "contoh buruk ditolak: %s" % nama)

	var teks_asli: String = FileAccess.get_file_as_string(BERKAS_CONFIG)
	check(not teks_asli.is_empty(), "scripts/config.gd bisa dibaca")
	var hasil_asli: Dictionary = ConfigParser.parse(teks_asli)
	check(ConfigParser.valid(hasil_asli), "scripts/config.gd asli lolos parser (satu baris, literal): %s" % [hasil_asli["galat"]])
	var konstanta_asli: Dictionary = hasil_asli["konstanta"]
	var skrip_config: GDScript = load(BERKAS_CONFIG) as GDScript
	var peta_config: Dictionary = skrip_config.get_script_constant_map()
	check(konstanta_asli.size() == peta_config.size(), "parser membaca semua konstanta Config (parser %d, GDScript %d)" % [konstanta_asli.size(), peta_config.size()])
	for nama: String in peta_config:
		var ada: bool = konstanta_asli.has(nama)
		check(ada, "konstanta Config.%s terbaca oleh parser" % nama)
		if ada:
			var nilai_parser: Variant = konstanta_asli[nama]["nilai"]
			check(typeof(nilai_parser) == typeof(peta_config[nama]) and nilai_parser == peta_config[nama], "nilai Config.%s sama dengan literal di file" % nama)

	# AC-7: angka awal BALANCING 2 (usulan) dan konstanta layar/ubin.
	check(Config.KECEPATAN_SANTAI_UD == 3.0 and Config.KECEPATAN_CEPAT_UD == 4.5 and Config.KECEPATAN_NGEBUT_UD == 6.0, "kecepatan santai/cepat/ngebut 3,0 / 4,5 / 6,0 u/d (BALANCING 2)")
	check(Config.KECEPATAN_MELAMBAT_UD == 1.5, "kecepatan melambat 1,5 u/d (BALANCING 2)")
	check(Config.AKSELERASI_UD2 == 3.0 and Config.PERLAMBATAN_MELAMBAT_UD2 == 2.0, "akselerasi 3,0 dan perlambatan melambat 2,0 u/d2 (BALANCING 2)")
	check(Config.REM_PERLAMBATAN_UD2 == 5.0 and Config.REM_AMBANG_STICK == 0.90 and Config.REM_TAHAN_DETIK == 0.25, "rem 5,0 u/d2, ambang stick 0,90, tahan 0,25 detik (BALANCING 2)")
	check(Config.ZONA_MATI_STICK == 0.15 and Config.KECEPATAN_LATERAL_UD == 3.0, "zona mati stick 0,15 dan kecepatan lateral 3,0 u/d (BALANCING 2)")
	check(Config.SPRITE_AMBANG_CEPAT == 0.33 and Config.SPRITE_AMBANG_NGEBUT == 0.80, "ambang sprite 0,33 / 0,80 (BALANCING 2)")
	check(Config.SPRITE_SUDUT_SERONG_DERAJAT == 22.5 and Config.SPRITE_SUDUT_SIKU_DERAJAT == 67.5, "sudut sprite 22,5 / 67,5 derajat (BALANCING 2)")
	check(Config.LAYAR_LEBAR_DASAR_PX == 640 and Config.LAYAR_TINGGI_DASAR_PX == 360 and Config.LAYAR_SKALA_PIKSEL == 3, "layar dasar 640x360 skala x3 (ROADMAP 4b)")
	check(Config.UBIN_LEBAR_PX == 64 and Config.UBIN_TINGGI_PX == 32 and Config.UBIN_UNIT_DUNIA == 32, "ubin 64x32 px, 32 unit dunia per ubin (usulan, ART_DIRECTION 11)")
	check(Config.UBIN_LEBAR_PX == 2 * Config.UBIN_TINGGI_PX, "ubin isometrik 2:1 (lebar dua kali tinggi)")


# --- b. Tingkat sprite dari stick (BALANCING 2) ---

func _test_tingkat_sprite() -> void:
	_judul("Tingkat sprite dari stick")
	check(LoperAnim.tingkat_dari_stick(0.0) == 0, "stick netral (0,0) = santai")
	check(LoperAnim.tingkat_dari_stick(0.32) == 0, "kekuatan 0,32 (di bawah 0,33) = santai")
	check(LoperAnim.tingkat_dari_stick(0.329) == 0, "kekuatan 0,329 = santai")
	check(LoperAnim.tingkat_dari_stick(0.33) == 1, "kekuatan tepat 0,33 = cepat (batas bawah inklusif)")
	check(LoperAnim.tingkat_dari_stick(0.5) == 1, "kekuatan 0,5 = cepat")
	check(LoperAnim.tingkat_dari_stick(0.80) == 1, "kekuatan tepat 0,80 = cepat (batas atas inklusif)")
	check(LoperAnim.tingkat_dari_stick(0.81) == 2, "kekuatan 0,81 = ngebut")
	check(LoperAnim.tingkat_dari_stick(1.0) == 2, "kekuatan penuh 1,0 = ngebut")
	check(LoperAnim.tingkat_dari_stick(1.5) == 2, "nilai di atas 1 dijepit ke 1 = ngebut")
	check(LoperAnim.tingkat_dari_stick(100.0) == 2, "nilai sangat besar dijepit = ngebut")
	check(LoperAnim.tingkat_dari_stick(-0.1) == 0, "stick ke bawah (negatif) = santai")
	check(LoperAnim.tingkat_dari_stick(-1.0) == 0, "stick penuh ke bawah = santai")
	check(LoperAnim.tingkat_dari_stick(NAN) == 0, "NaN = santai (tidak jatuh ke ngebut)")
	check(LoperAnim.tingkat_dari_stick(INF) == 2, "tak hingga positif dijepit = ngebut")
	check(LoperAnim.tingkat_dari_stick(-INF) == 0, "tak hingga negatif dijepit = santai")
	# Tingkat tidak pernah turun saat kekuatan naik (monoton).
	var terakhir: int = 0
	var monoton: bool = true
	for langkah: int in range(101):
		var tingkat: int = LoperAnim.tingkat_dari_stick(float(langkah) / 100.0)
		if tingkat < terakhir:
			monoton = false
		terakhir = tingkat
	check(monoton, "tingkat sprite monoton naik terhadap kekuatan stick 0..1")


# --- c. Arah sprite dari gerak (BALANCING 2) ---

## Vektor gerak (maju, lateral) dengan sudut dan laju tertentu. Lateral positif = sisi `dekat`.
func _gerak(sudut_derajat: float, laju: float, ke_dekat: bool) -> Vector2:
	var rad: float = deg_to_rad(sudut_derajat)
	var lateral: float = laju * sin(rad)
	return Vector2(laju * cos(rad), lateral if ke_dekat else -lateral)


func _test_arah_sprite() -> void:
	_judul("Arah sprite dari gerak")
	# Besar arah dari sudut: batas 22,5 dan 67,5 derajat inklusif.
	check(LoperAnim.besar_arah_dari_sudut(0.0) == 0, "sudut 0 = normal")
	check(LoperAnim.besar_arah_dari_sudut(22.4) == 0, "sudut 22,4 = normal")
	check(LoperAnim.besar_arah_dari_sudut(22.5) == 1, "sudut tepat 22,5 = serong (batas bawah inklusif)")
	check(LoperAnim.besar_arah_dari_sudut(45.0) == 1, "sudut 45 = serong")
	check(LoperAnim.besar_arah_dari_sudut(67.5) == 1, "sudut tepat 67,5 = serong (batas atas inklusif)")
	check(LoperAnim.besar_arah_dari_sudut(67.6) == 2, "sudut 67,6 = 90 derajat")
	check(LoperAnim.besar_arah_dari_sudut(90.0) == 2, "sudut 90 = 90 derajat")
	check(LoperAnim.besar_arah_dari_sudut(180.0) == 2, "sudut 180 = 90 derajat")
	check(LoperAnim.besar_arah_dari_sudut(-22.4) == 0 and LoperAnim.besar_arah_dari_sudut(-22.5) == 1, "sudut negatif dibaca nilai mutlaknya (22,4 / 22,5)")
	check(LoperAnim.besar_arah_dari_sudut(-67.5) == 1 and LoperAnim.besar_arah_dari_sudut(-67.6) == 2, "sudut negatif dibaca nilai mutlaknya (67,5 / 67,6)")

	# Dari vektor gerak, di kedua sisi dan beberapa laju (hasil tidak bergantung laju).
	for laju: float in [0.1, 1.0, 3.0, 6.0]:
		for ke_dekat: bool in [true, false]:
			var tanda: int = 1 if ke_dekat else -1
			var sisi: String = "dekat" if ke_dekat else "seberang"
			var g0: Vector2 = _gerak(0.0, laju, ke_dekat)
			check(LoperAnim.arah_dari_gerak(g0.x, g0.y) == 0, "lurus ke depan = normal (laju %s, sisi %s)" % [laju, sisi])
			var g224: Vector2 = _gerak(22.4, laju, ke_dekat)
			check(LoperAnim.arah_dari_gerak(g224.x, g224.y) == 0, "22,4 derajat ke %s = normal (laju %s)" % [sisi, laju])
			var g225: Vector2 = _gerak(22.5, laju, ke_dekat)
			check(LoperAnim.arah_dari_gerak(g225.x, g225.y) == tanda, "22,5 derajat ke %s = serong %d (laju %s)" % [sisi, tanda, laju])
			var g45: Vector2 = _gerak(45.0, laju, ke_dekat)
			check(LoperAnim.arah_dari_gerak(g45.x, g45.y) == tanda, "45 derajat ke %s = serong %d (laju %s)" % [sisi, tanda, laju])
			var g675: Vector2 = _gerak(67.5, laju, ke_dekat)
			check(LoperAnim.arah_dari_gerak(g675.x, g675.y) == tanda, "67,5 derajat ke %s = serong %d (laju %s)" % [sisi, tanda, laju])
			var g676: Vector2 = _gerak(67.6, laju, ke_dekat)
			check(LoperAnim.arah_dari_gerak(g676.x, g676.y) == 2 * tanda, "67,6 derajat ke %s = 90 derajat %d (laju %s)" % [sisi, 2 * tanda, laju])
			var g90: Vector2 = _gerak(90.0, laju, ke_dekat)
			check(LoperAnim.arah_dari_gerak(g90.x, g90.y) == 2 * tanda, "tepat menyamping ke %s = 90 derajat (laju %s)" % [sisi, laju])

	# Tanda: lateral ke sisi dekat positif (animasi `kanan`), ke sisi seberang negatif (`kiri`).
	check(LoperAnim.nama_animasi(0, LoperAnim.arah_dari_gerak(0.0, 1.0)) == &"santai_kanan", "gerak murni ke sisi dekat memilih animasi santai_kanan")
	check(LoperAnim.nama_animasi(0, LoperAnim.arah_dari_gerak(0.0, -1.0)) == &"santai_kiri", "gerak murni ke sisi seberang memilih animasi santai_kiri")
	check(LoperAnim.nama_animasi(2, LoperAnim.arah_dari_gerak(2.0, 1.0)) == &"ngebut_serong_kanan", "maju dengan sedikit ke sisi dekat (26,6 derajat) = ngebut_serong_kanan")
	check(LoperAnim.nama_animasi(1, LoperAnim.arah_dari_gerak(2.0, -1.0)) == &"cepat_serong_kiri", "maju dengan sedikit ke sisi seberang = cepat_serong_kiri")

	# Kasus tepi yang ditetapkan di `##` LoperAnim.arah_dari_gerak.
	check(LoperAnim.arah_dari_gerak(0.0, 0.0) == 0, "vektor nol = normal (0)")
	check(LoperAnim.arah_dari_gerak(5.0, 0.0) == 0, "lurus maju tanpa lateral = 0")
	check(LoperAnim.arah_dari_gerak(-3.0, 0.0) == 0, "mundur murni = 0 (tanda tidak bisa ditentukan)")
	check(LoperAnim.arah_dari_gerak(-3.0, 1.0) == 2, "mundur sambil ke sisi dekat = 90 derajat positif")
	check(LoperAnim.arah_dari_gerak(-3.0, -1.0) == -2, "mundur sambil ke sisi seberang = 90 derajat negatif")
	check(LoperAnim.arah_dari_gerak(0.0, 1.0) == 2 and LoperAnim.arah_dari_gerak(0.0, -1.0) == -2, "diam di jalan sambil bergeser menyamping = 90 derajat")
	check(LoperAnim.arah_dari_gerak(NAN, 1.0) == 0 and LoperAnim.arah_dari_gerak(1.0, NAN) == 0, "NaN pada gerak = 0")
	check(LoperAnim.arah_dari_gerak(1.0, 0.000001) == 0, "lateral nyaris nol (derau) = 0")


# --- d. Nama animasi dan SpriteFrames ---

func _test_nama_animasi_dan_frames() -> void:
	_judul("Nama animasi dan SpriteFrames")
	var frames: SpriteFrames = load(BERKAS_FRAMES) as SpriteFrames
	check(frames != null, "loper_agen_frames.tres termuat sebagai SpriteFrames di Godot 4.7")
	if frames == null:
		return
	var nama_dipakai: Dictionary = {}
	for tingkat: int in range(3):
		for arah: int in range(-2, 3):
			var nama: StringName = LoperAnim.nama_animasi(tingkat, arah)
			nama_dipakai[nama] = true
			check(frames.has_animation(nama), "animasi '%s' (tingkat %d, arah %d) ada di SpriteFrames" % [nama, tingkat, arah])
	check(nama_dipakai.size() == 15, "15 pasangan tingkat x arah menghasilkan 15 nama berbeda, dapat %d" % nama_dipakai.size())
	check(LoperAnim.nama_animasi(9, -9) == &"ngebut_kiri", "tingkat dan arah di luar jangkauan dijepit (9, -9) = ngebut_kiri")
	check(LoperAnim.nama_animasi(-1, 9) == &"santai_kanan", "tingkat dan arah di luar jangkauan dijepit (-1, 9) = santai_kanan")

	var nama_frames: PackedStringArray = frames.get_animation_names()
	check(nama_frames.size() == 15, "SpriteFrames memuat tepat 15 animasi, dapat %d" % nama_frames.size())
	for nama: String in nama_frames:
		check(nama_dipakai.has(StringName(nama)), "animasi SpriteFrames '%s' dipakai LoperAnim (tidak ada animasi yatim)" % nama)

	# Bandingkan dengan metadata sprite (loper_agen.json): fps, loop, region tiap frame.
	var json: Variant = JSON.parse_string(FileAccess.get_file_as_string(BERKAS_JSON))
	check(json is Dictionary, "loper_agen.json terbaca sebagai Dictionary")
	if not json is Dictionary:
		return
	var data: Dictionary = json
	var daftar: Array = data["animations"]
	check(daftar.size() == 15, "loper_agen.json mendaftar 15 animasi")
	var fps_tingkat: Array = [8.0, 10.0, 12.0]
	for entri: Dictionary in daftar:
		var nama: StringName = StringName(entri["name"])
		if not frames.has_animation(nama):
			check(false, "animasi '%s' dari JSON tidak ada di SpriteFrames" % nama)
			continue
		check(frames.get_frame_count(nama) == 4, "animasi '%s' punya 4 frame" % nama)
		check(frames.get_animation_loop(nama), "animasi '%s' berulang (loop)" % nama)
		var fps_json: float = entri["fps"]
		check(is_equal_approx(frames.get_animation_speed(nama), fps_json), "fps animasi '%s' sama dengan JSON (%s)" % [nama, fps_json])
		var indeks_tingkat: int = LoperAnim.NAMA_TINGKAT.find(String(entri["speed"]))
		check(indeks_tingkat >= 0 and is_equal_approx(frames.get_animation_speed(nama), fps_tingkat[indeks_tingkat]), "fps animasi '%s' = 8 / 10 / 12 untuk santai / cepat / ngebut" % nama)
		var regions: Array = entri["regions"]
		check(regions.size() == 4, "JSON animasi '%s' memuat 4 region" % nama)
		for i: int in range(mini(4, regions.size())):
			var frame_tex: AtlasTexture = frames.get_frame_texture(nama, i) as AtlasTexture
			if frame_tex == null:
				check(false, "frame %d animasi '%s' adalah AtlasTexture" % [i, nama])
				continue
			var r: Array = regions[i]
			var diharapkan: Rect2 = Rect2(r[0], r[1], r[2], r[3])
			check(frame_tex.region == diharapkan, "region frame %d animasi '%s' = %s (JSON), dapat %s" % [i, nama, diharapkan, frame_tex.region])
			check(frame_tex.atlas != null and frame_tex.atlas.resource_path == BERKAS_SHEET, "frame %d animasi '%s' memakai atlas %s" % [i, nama, BERKAS_SHEET])
	# Ukuran sheet cocok dengan JSON (4 kolom x 15 baris, sel 46x58).
	var sheet: Texture2D = load(BERKAS_SHEET) as Texture2D
	var sel: Array = data["cell"]
	check(sheet != null and sheet.get_size() == Vector2(float(sel[0]) * float(data["columns"]), float(sel[1]) * float(data["rows"])), "ukuran loper_agen.png = kolom x baris x sel di JSON (184x870)")


# --- e. Scene pemain ---

func _test_scene_pemain() -> void:
	_judul("Scene pemain loper_agen.tscn")
	var paket: PackedScene = load(BERKAS_SCENE_PEMAIN) as PackedScene
	check(paket != null, "loper_agen.tscn termuat sebagai PackedScene")
	if paket == null:
		return
	var pemain: LoperSprite = paket.instantiate() as LoperSprite
	check(pemain != null, "loper_agen.tscn bisa diinstansiasi sebagai LoperSprite (tanpa scene tree)")
	if pemain == null:
		return
	check(pemain.animation == &"santai_normal", "pemain mulai di animasi santai_normal")
	check(pemain.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "node pemain memakai filter Nearest (AC-8)")
	check(pemain.scale == pemain.scale.round(), "skala node pemain bilangan bulat (AC-8)")
	check(pemain.offset == Vector2(0.0, -17.0), "offset (0, -17) menaruh titik pijak (23, 46) sprite di origin node (README sprite)")

	for tingkat: int in range(3):
		for arah: int in range(-2, 3):
			pemain.speed_level = tingkat
			pemain.steer = arah
			check(pemain.animation == LoperAnim.nama_animasi(tingkat, arah), "speed_level %d steer %d memilih '%s', dapat '%s'" % [tingkat, arah, LoperAnim.nama_animasi(tingkat, arah), pemain.animation])

	pemain.speed_level = 9
	check(pemain.speed_level == 2, "speed_level 9 dijepit ke 2")
	pemain.speed_level = -4
	check(pemain.speed_level == 0, "speed_level -4 dijepit ke 0")
	pemain.steer = 7
	check(pemain.steer == 2, "steer 7 dijepit ke 2")
	pemain.steer = -7
	check(pemain.steer == -2, "steer -7 dijepit ke -2")
	pemain.speed_level = 9
	pemain.steer = -7
	check(pemain.animation == &"ngebut_kiri", "nilai di luar jangkauan memilih animasi ujung (ngebut_kiri)")

	pemain.pedal_rate = 1.5
	check(is_equal_approx(pemain.speed_scale, 1.5), "pedal_rate 1,5 mengalikan kecepatan animasi 1,5")
	pemain.pedal_rate = -2.0
	check(pemain.speed_scale >= 0.0, "pedal_rate negatif tidak membuat speed_scale negatif")
	pemain.pedal_rate = NAN
	check(pemain.speed_scale == 0.0, "pedal_rate NaN menjadi speed_scale 0")
	pemain.pedal_rate = 0.0
	check(pemain.speed_scale == 0.0, "pedal_rate 0 menghentikan putaran (speed_scale 0)")

	# Fase kayuh dijaga saat berganti arah atau kecepatan.
	pemain.speed_level = 0
	pemain.steer = 0
	pemain.frame = 2
	pemain.steer = 1
	check(pemain.frame == 2, "frame kayuh dijaga saat arah berganti")
	pemain.free()


## Di dalam scene tree, animasi kayuh berjalan sendiri setelah _ready dan tetap berjalan saat arah berganti.
func _test_scene_pemain_di_tree() -> void:
	var paket: PackedScene = load(BERKAS_SCENE_PEMAIN) as PackedScene
	var di_tree: LoperSprite = paket.instantiate() as LoperSprite
	root.add_child(di_tree)
	check(di_tree.is_inside_tree(), "pemain masuk scene tree")
	check(di_tree.is_playing(), "di dalam scene tree animasi kayuh langsung berjalan")
	di_tree.speed_level = 2
	di_tree.steer = 1
	check(di_tree.is_playing() and di_tree.animation == &"ngebut_serong_kanan", "animasi tetap berjalan saat tingkat dan arah berganti")
	root.remove_child(di_tree)
	di_tree.free()


## Scene utama masuk scene tree beberapa frame tanpa error, dan pemain di dalamnya berjalan.
func _test_graybox_di_tree() -> void:
	_judul("Scene utama graybox di scene tree")
	var paket: PackedScene = load(BERKAS_SCENE_UTAMA) as PackedScene
	if paket == null:
		check(false, "graybox.tscn termuat untuk uji scene tree")
		return
	var akar: Node = paket.instantiate()
	root.add_child(akar)
	await process_frame
	await process_frame
	var pemain: LoperSprite = akar.find_child("LoperAgen", true, false) as LoperSprite
	check(pemain != null, "graybox memuat node LoperAgen bertipe LoperSprite")
	if pemain != null:
		check(pemain.is_playing() and pemain.speed_level == 1, "pemain di graybox berjalan di tingkat cepat")
	var kamera: Camera2D = akar.find_child("Kamera", true, false) as Camera2D
	check(kamera != null and kamera.position == kamera.position.round(), "graybox punya kamera dengan posisi bilangan bulat (piksel tajam)")
	root.remove_child(akar)
	akar.free()


# --- f. Pengaturan proyek dan impor (AC-2, AC-8) ---

func _test_pengaturan_proyek() -> void:
	_judul("Pengaturan proyek dan impor")
	var versi: Dictionary = Engine.get_version_info()
	check(versi["major"] == 4 and versi["minor"] == 7, "Godot 4.7.x (dikunci ROADMAP 4b), dapat %s.%s" % [versi["major"], versi["minor"]])
	check(str(ProjectSettings.get_setting("application/config/name")) == "Kring Kring!", "config/name = Kring Kring! (GDD 5.4)")
	var fitur: PackedStringArray = ProjectSettings.get_setting("application/config/features")
	check(fitur.has("4.7") and fitur.has("GL Compatibility"), "config/features memuat 4.7 dan GL Compatibility, dapat %s" % [fitur])
	check(str(ProjectSettings.get_setting("rendering/renderer/rendering_method")) == "gl_compatibility", "renderer gl_compatibility")
	check(str(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile")) == "gl_compatibility", "renderer mobile gl_compatibility")
	check(int(ProjectSettings.get_setting("display/window/handheld/orientation")) == DisplayServer.SCREEN_LANDSCAPE, "orientasi landscape terkunci (bukan sensor)")
	check(int(ProjectSettings.get_setting("display/window/size/viewport_width")) == Config.LAYAR_LEBAR_DASAR_PX, "viewport_width sama dengan Config.LAYAR_LEBAR_DASAR_PX")
	check(int(ProjectSettings.get_setting("display/window/size/viewport_height")) == Config.LAYAR_TINGGI_DASAR_PX, "viewport_height sama dengan Config.LAYAR_TINGGI_DASAR_PX")
	check(str(ProjectSettings.get_setting("display/window/stretch/mode")) == "canvas_items", "stretch/mode = canvas_items")
	check(str(ProjectSettings.get_setting("display/window/stretch/aspect")) == "expand", "stretch/aspect = expand")
	check(str(ProjectSettings.get_setting("display/window/stretch/scale_mode")) == "integer", "stretch/scale_mode = integer")
	check(bool(ProjectSettings.get_setting("rendering/2d/snap/snap_2d_transforms_to_pixel")), "snap_2d_transforms_to_pixel aktif")
	check(int(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter")) == Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST, "filter tekstur bawaan 2D = Nearest")
	var utama: String = str(ProjectSettings.get_setting("application/run/main_scene"))
	check(utama == BERKAS_SCENE_UTAMA, "scene utama sementara = %s, dapat '%s'" % [BERKAS_SCENE_UTAMA, utama])
	check(ResourceLoader.exists(BERKAS_SCENE_UTAMA), "scene utama ada dan bisa dimuat")

	var bawaan: Dictionary = ProjectSettings.get_setting("importer_defaults/texture", {})
	check(bawaan.get("compress/mode", -1) == 0, "default impor tekstur: Lossless (compress/mode 0)")
	check(bawaan.get("mipmaps/generate", true) == false, "default impor tekstur: tanpa mipmap")
	check(bawaan.get("detect_3d/compress_to", -1) == 0, "default impor tekstur: tanpa kompresi VRAM otomatis untuk 3D")

	var png: Array[String] = _daftar_berkas("res://assets/sprites", ["png"])
	check(png.size() >= 6, "ada PNG sprite pemain dan graybox (loper_agen + 5 placeholder), dapat %d" % png.size())
	for berkas: String in png:
		var impor: ConfigFile = ConfigFile.new()
		var galat: int = impor.load(berkas + ".import")
		check(galat == OK, "%s punya berkas .import (ter-commit)" % berkas)
		if galat != OK:
			continue
		check(int(impor.get_value("params", "compress/mode", -1)) == 0, "%s: impor Lossless" % berkas)
		check(impor.get_value("params", "mipmaps/generate", true) == false, "%s: tanpa mipmap" % berkas)
		check(int(impor.get_value("params", "detect_3d/compress_to", -1)) == 0, "%s: tanpa kompresi VRAM 3D" % berkas)
		var meta: Dictionary = impor.get_value("remap", "metadata", {})
		check(meta.get("vram_texture", true) == false, "%s: tidak diimpor sebagai tekstur VRAM terkompresi" % berkas)

	# Scene graybox: filter efektif Nearest dan skala bulat untuk semua node 2D.
	var graybox: PackedScene = load(BERKAS_SCENE_UTAMA) as PackedScene
	check(graybox != null, "graybox.tscn termuat")
	if graybox != null:
		var akar: Node = graybox.instantiate()
		var semua: Array[Node] = _semua_node(akar)
		var jumlah_sprite: int = 0
		for node: Node in semua:
			if node is Node2D:
				var n2d: Node2D = node as Node2D
				check(n2d.scale == n2d.scale.round(), "graybox: skala bulat pada node '%s'" % n2d.name)
			if node is Sprite2D or node is AnimatedSprite2D:
				jumlah_sprite += 1
				check(_filter_efektif(node as CanvasItem) == CanvasItem.TEXTURE_FILTER_NEAREST, "graybox: filter efektif Nearest pada '%s'" % node.name)
		check(jumlah_sprite >= 10, "graybox memuat sprite ubin, rumah, kotak surat, dan pemain (dapat %d)" % jumlah_sprite)
		akar.free()


## Filter tekstur efektif: naik lewat induk bila node memakai PARENT_NODE, bawaan proyek di puncak.
func _filter_efektif(node: CanvasItem) -> int:
	var sekarang: CanvasItem = node
	while sekarang != null:
		if sekarang.texture_filter != CanvasItem.TEXTURE_FILTER_PARENT_NODE:
			return sekarang.texture_filter
		sekarang = sekarang.get_parent() as CanvasItem
	return CanvasItem.TEXTURE_FILTER_NEAREST if int(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter")) == Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST else CanvasItem.TEXTURE_FILTER_LINEAR


func _semua_node(akar: Node) -> Array[Node]:
	var hasil: Array[Node] = [akar]
	for anak: Node in akar.get_children():
		hasil.append_array(_semua_node(anak))
	return hasil


# --- Layar (AC-13): skala bulat dan ukuran viewport di berbagai rasio ---

func _test_layar_integer() -> void:
	_judul("Layar: skala bulat canvas_items + integer + expand")
	var ukuran_awal: Vector2i = root.size
	for kasus: Array in KASUS_LAYAR:
		var ukuran: Vector2i = Vector2i(kasus[0], kasus[1])
		root.size = ukuran
		var terlihat: Vector2 = root.get_visible_rect().size
		var skala: Vector2 = root.get_final_transform().get_scale()
		var label: String = "%dx%d" % [kasus[0], kasus[1]]
		check(terlihat == Vector2(kasus[2], kasus[3]), "%s: viewport terlihat %dx%d, dapat %s" % [label, kasus[2], kasus[3], terlihat])
		check(skala == Vector2(kasus[4], kasus[4]), "%s: skala x%d (bulat), dapat %s" % [label, kasus[4], skala])
		check(terlihat.y == float(Config.LAYAR_TINGGI_DASAR_PX), "%s: tinggi viewport selalu %d (hanya lebar yang mengikuti rasio)" % [label, Config.LAYAR_TINGGI_DASAR_PX])
		check(terlihat.x >= float(Config.LAYAR_LEBAR_DASAR_PX), "%s: lebar viewport tidak kurang dari 640 (zona aman 16:9 selalu tampil)" % label)
	for kasus: Array in KASUS_LAYAR_PECAHAN:
		root.size = Vector2i(kasus[0], kasus[1])
		var skala: Vector2 = root.get_final_transform().get_scale()
		var label: String = "%dx%d" % [kasus[0], kasus[1]]
		check(skala.x == roundf(skala.x) and skala.y == roundf(skala.y) and skala.x == skala.y, "%s: skala tetap bilangan bulat dan seragam, dapat %s" % [label, skala])
		check(skala.x >= 1.0, "%s: skala tidak di bawah x1" % label)
	root.size = ukuran_awal


# --- g. Palet (DESIGN_SPEC 1.1, ART_DIRECTION 2.4) ---

func _test_palet() -> void:
	_judul("Palet")
	var spek: String = FileAccess.get_file_as_string(BERKAS_DESIGN_SPEC)
	check(not spek.is_empty(), "DESIGN_SPEC.md bisa dibaca")
	var bagian: String = spek.split("### 1.1 Warna")[1].split("### 1.2")[0] if spek.contains("### 1.1 Warna") else ""
	var re_baris: RegEx = RegEx.create_from_string("^\\|\\s*`([A-Z0-9_]+)`\\s*\\|\\s*`#([0-9A-Fa-f]{6})`(?:\\s+alpha\\s+(\\d+)%)?")
	var tabel: Dictionary = {}
	for baris: String in bagian.split("\n"):
		var cocok: RegExMatch = re_baris.search(baris)
		if cocok != null:
			var alpha_persen: float = 100.0
			if not cocok.get_string(3).is_empty():
				alpha_persen = cocok.get_string(3).to_float()
			tabel[cocok.get_string(1)] = {"hex": cocok.get_string(2).to_lower(), "alpha": alpha_persen / 100.0}
	check(tabel.size() == 16, "tabel DESIGN_SPEC 1.1 memuat 16 token (11 warna + 5 radar), terbaca %d" % tabel.size())
	var skrip_palet: GDScript = load("res://scripts/ui/palette.gd") as GDScript
	var peta: Dictionary = skrip_palet.get_script_constant_map()
	check(peta.size() == tabel.size(), "Palette memuat tepat %d token seperti tabel, dapat %d" % [tabel.size(), peta.size()])
	for token: String in tabel:
		check(peta.has(token), "token %s ada di palette.gd" % token)
		if not peta.has(token):
			continue
		var warna: Color = peta[token]
		check(warna.to_html(false) == tabel[token]["hex"], "token %s: hex %s sama dengan DESIGN_SPEC (#%s)" % [token, warna.to_html(false), tabel[token]["hex"]])
		check(is_equal_approx(warna.a, tabel[token]["alpha"]), "token %s: alpha %s sama dengan DESIGN_SPEC (%s)" % [token, warna.a, tabel[token]["alpha"]])
	for token: String in peta:
		check(tabel.has(token), "token Palette.%s ada di tabel DESIGN_SPEC 1.1 (tidak ada token karangan)" % token)

	# Palet induk .gpl: sama dengan tabel ART_DIRECTION 2.4, dan token palet yang berasal dari palet induk ada di dalamnya.
	var seni: String = FileAccess.get_file_as_string(BERKAS_ART_DIRECTION)
	var tabel_induk: String = seni.split("### 2.4 Palet induk (usulan)")[1].split("### 2.5")[0] if seni.contains("### 2.4 Palet induk (usulan)") else ""
	var re_hex: RegEx = RegEx.create_from_string("#([0-9A-Fa-f]{6})")
	var hex_dokumen: Dictionary = {}
	for cocok: RegExMatch in re_hex.search_all(tabel_induk):
		hex_dokumen[cocok.get_string(1).to_lower()] = true
	var hex_gpl: Dictionary = {}
	var jumlah_baris_warna: int = 0
	var re_gpl: RegEx = RegEx.create_from_string("^\\s*(\\d+)\\s+(\\d+)\\s+(\\d+)\\s+.*#([0-9A-Fa-f]{6})\\s*$")
	for baris: String in FileAccess.get_file_as_string(BERKAS_GPL).split("\n"):
		var cocok: RegExMatch = re_gpl.search(baris)
		if cocok == null:
			continue
		jumlah_baris_warna += 1
		var hex: String = cocok.get_string(4).to_lower()
		hex_gpl[hex] = true
		var dari_rgb: Color = Color8(cocok.get_string(1).to_int(), cocok.get_string(2).to_int(), cocok.get_string(3).to_int())
		check(dari_rgb.to_html(false) == hex, "loper_master.gpl: RGB %s,%s,%s cocok dengan hex #%s" % [cocok.get_string(1), cocok.get_string(2), cocok.get_string(3), hex])
	check(hex_dokumen.size() > 40, "tabel ART_DIRECTION 2.4 terbaca (%d warna berbeda)" % hex_dokumen.size())
	check(jumlah_baris_warna >= hex_dokumen.size(), "loper_master.gpl memuat sedikitnya sebanyak warna berbeda di tabel (%d baris, %d warna berbeda)" % [jumlah_baris_warna, hex_dokumen.size()])
	for hex: String in hex_dokumen:
		check(hex_gpl.has(hex), "warna #%s dari ART_DIRECTION 2.4 ada di loper_master.gpl" % hex)
	for hex: String in hex_gpl:
		check(hex_dokumen.has(hex), "warna #%s di loper_master.gpl ada di tabel ART_DIRECTION 2.4" % hex)
	for token: String in ["OUTLINE", "RADAR_PELANGGAN", "RADAR_MISI", "RADAR_BUKAN"]:
		var warna_induk: Color = peta[token]
		check(hex_gpl.has(warna_induk.to_html(false)), "token %s berasal dari palet induk, jadi ada di loper_master.gpl" % token)


# --- Font dan lisensi (AC-11) ---

func _test_lisensi_font() -> void:
	_judul("Font dan lisensi")
	var lisensi: String = FileAccess.get_file_as_string("res://assets/LICENSES.md")
	check(not lisensi.is_empty(), "assets/LICENSES.md ada")
	var font: Array[String] = _daftar_berkas("res://assets/fonts", ["ttf", "otf"])
	check(font.size() == 2, "dua font (Lexend dan Lilita One) ada di assets/fonts, dapat %d" % font.size())
	var ada_lexend: bool = false
	var ada_lilita: bool = false
	for berkas: String in font:
		ada_lexend = ada_lexend or berkas.get_file().begins_with("lexend")
		ada_lilita = ada_lilita or berkas.get_file().begins_with("lilita_one")
		check(lisensi.contains(berkas.get_file()), "%s tercatat di assets/LICENSES.md" % berkas.get_file())
		check(FileAccess.file_exists(berkas.get_base_dir().path_join("OFL.txt")), "%s punya OFL.txt di foldernya" % berkas.get_file())
		check(FileAccess.file_exists(berkas + ".import"), "%s punya berkas .import (ter-commit)" % berkas.get_file())
	check(ada_lexend and ada_lilita, "font yang ada adalah Lexend dan Lilita One (DESIGN_SPEC 1.2)")
	check(lisensi.contains("usulan (belum dikunci)"), "LICENSES.md menandai font sebagai usulan (belum dikunci)")
	check(RegEx.create_from_string("[0-9a-f]{40}").search(lisensi) != null, "LICENSES.md mencatat hash commit hulu (40 heksadesimal)")
	check(lisensi.contains("SIL Open Font License 1.1") and lisensi.contains("https://github.com/google/fonts"), "LICENSES.md mencatat lisensi OFL dan URL sumber")


# --- h. Tanpa hex warna di luar palette.gd, tanpa angka tuning di luar config.gd ---

func _test_tanpa_hex_di_luar_palet() -> void:
	_judul("Tanpa hex di luar palette.gd")
	var re_hex: RegEx = RegEx.create_from_string("#[0-9A-Fa-f]{8}(?![0-9A-Za-z])|#[0-9A-Fa-f]{6}(?![0-9A-Za-z])|#[0-9A-Fa-f]{3}(?![0-9A-Za-z])")
	var re_warna_teks: RegEx = RegEx.create_from_string("Color\\s*\\(\\s*[\"&]|Color\\.html|Color\\.hex|Color\\.from_string|Color8\\s*\\(")
	var re_warna_angka: RegEx = RegEx.create_from_string("Color\\s*\\(")
	var diperiksa: int = 0
	var gd: Array[String] = _daftar_berkas("res://scripts", ["gd"])
	for berkas: String in gd:
		if berkas.ends_with("/palette.gd"):
			continue
		diperiksa += 1
		var teks: String = FileAccess.get_file_as_string(berkas)
		check(re_hex.search(teks) == null, "%s tidak memuat hex warna" % berkas)
		check(re_warna_teks.search(teks) == null, "%s tidak memuat Color(\"...\") / Color.html / Color8" % berkas)
	var scene: Array[String] = _daftar_berkas("res://scenes", ["tscn"]) + _daftar_berkas("res://assets", ["tres", "tscn"])
	for berkas: String in scene:
		diperiksa += 1
		var teks: String = FileAccess.get_file_as_string(berkas)
		check(re_hex.search(teks) == null, "%s tidak memuat hex warna" % berkas)
		check(re_warna_teks.search(teks) == null and re_warna_angka.search(teks) == null, "%s tidak memuat warna literal (Color(...))" % berkas)
	check(diperiksa >= 7, "pemindai hex memeriksa skrip, scene, dan resource (%d berkas)" % diperiksa)
	# Pemindai sendiri harus menangkap contoh yang melanggar (supaya tes ini bukan lolos kosong).
	check(re_hex.search("var w: Color = Color(\"#1C130F\")") != null, "pemindai mengenali hex #RRGGBB")
	check(re_warna_teks.search("var w := Color(\"red\")") != null, "pemindai mengenali Color(\"nama\")")
	check(re_warna_angka.search("modulate = Color(1, 0, 0, 1)") != null, "pemindai mengenali Color(angka) di scene")
	check(re_hex.search("## komentar tanpa warna, 1.0 dan 12345") == null, "pemindai tidak salah mengenali teks biasa")

	_judul("Tanpa angka tuning di luar config.gd")
	var diizinkan: Array[String] = ["0", "1", "2", "-1", "-2", "0.0", "1.0"]
	var re_angka: RegEx = RegEx.create_from_string("(?<![A-Za-z0-9_.])-?[0-9]+(?:\\.[0-9]+)?")
	var dipindai: int = 0
	for folder: String in ["res://scripts/systems", "res://scripts/entities", "res://scripts/ui"]:
		for berkas: String in _daftar_berkas(folder, ["gd"]):
			if berkas.ends_with("/palette.gd"):
				continue
			dipindai += 1
			var pelanggaran: Array[String] = []
			var nomor: int = 0
			for baris: String in FileAccess.get_file_as_string(berkas).split("\n"):
				nomor += 1
				for cocok: RegExMatch in re_angka.search_all(_kode_saja(baris)):
					if not diizinkan.has(cocok.get_string()):
						pelanggaran.append("baris %d: %s" % [nomor, cocok.get_string()])
			check(pelanggaran.is_empty(), "%s: tanpa angka literal di luar config.gd (hanya 0, 1, 2, -1, -2 boleh): %s" % [berkas, "; ".join(pelanggaran)])
	check(dipindai >= 3, "pemindai angka memeriksa skrip systems, entities, dan ui (%d berkas)" % dipindai)
	check(_kode_saja("var x: float = 3.5 # komentar 99") == "var x: float = 3.5 ", "pembersih baris membuang komentar dan teks berkutip")
	check(_kode_saja("print(\"angka 42 di teks\") # 7").find("42") == -1, "pembersih baris membuang isi teks berkutip")


## Baris tanpa komentar `#` dan tanpa isi teks berkutip, untuk dipindai.
func _kode_saja(baris: String) -> String:
	var hasil: String = ""
	var dalam_teks: String = ""
	for i: int in range(baris.length()):
		var c: String = baris[i]
		if dalam_teks != "":
			if c == dalam_teks and (i == 0 or baris[i - 1] != "\\"):
				dalam_teks = ""
			continue
		if c == "\"" or c == "'":
			dalam_teks = c
			continue
		if c == "#":
			break
		hasil += c
	return hasil


# --- Gaya kode (AC-9) dan kebersihan repo (AC-14) ---

func _test_gaya_kode() -> void:
	_judul("Gaya kode GDScript")
	var re_func: RegEx = RegEx.create_from_string("^\\s*(?:static\\s+)?func\\s+\\w+\\s*\\(.*\\)\\s*->\\s*[\\w\\.\\[\\]]+\\s*:\\s*$")
	var re_func_apa_saja: RegEx = RegEx.create_from_string("^\\s*(?:static\\s+)?func\\s+\\w+")
	var re_var_tanpa_tipe: RegEx = RegEx.create_from_string("^\\s*(?:var|const)\\s+\\w+\\s*=")
	var re_untuk_tanpa_tipe: RegEx = RegEx.create_from_string("^\\s*for\\s+\\w+\\s+in\\s")
	var re_sisi: RegEx = RegEx.create_from_string("\\b(?:kiri|kanan)\\b")
	var jumlah: int = 0
	var semua: Array[String] = _daftar_berkas("res://scripts", ["gd"]) + _daftar_berkas("res://tests", ["gd"])
	for berkas: String in semua:
		jumlah += 1
		var pelanggaran: Array[String] = []
		var nomor: int = 0
		for baris: String in FileAccess.get_file_as_string(berkas).split("\n"):
			nomor += 1
			if baris.begins_with(" "):
				pelanggaran.append("baris %d: indentasi spasi (pakai tab)" % nomor)
			if re_func_apa_saja.search(baris) != null and re_func.search(baris) == null:
				pelanggaran.append("baris %d: fungsi tanpa tipe return (-> Tipe)" % nomor)
			if re_var_tanpa_tipe.search(baris) != null:
				pelanggaran.append("baris %d: var/const tanpa tipe eksplisit atau :=" % nomor)
			if re_untuk_tanpa_tipe.search(baris) != null:
				pelanggaran.append("baris %d: variabel for tanpa tipe (for x: Tipe in ...)" % nomor)
			if re_sisi.search(_kode_saja(baris)) != null:
				pelanggaran.append("baris %d: kiri/kanan di kode (pakai seberang/dekat untuk sisi jalan)" % nomor)
		check(pelanggaran.is_empty(), "%s: tab, static typing, dan nama sisi sesuai gaya: %s" % [berkas, "; ".join(pelanggaran)])
	check(jumlah >= 6, "pemeriksa gaya memeriksa skrip dan tes (%d berkas)" % jumlah)
	# Pemeriksa sendiri harus menangkap pelanggaran (supaya bukan lolos kosong).
	check(re_func.search("func f(a: int) -> void:") != null and re_func.search("func f(a: int):") == null, "pemeriksa gaya membedakan fungsi bertipe return dan tanpa")
	check(re_var_tanpa_tipe.search("var x = 5") != null and re_var_tanpa_tipe.search("var x: int = 5") == null and re_var_tanpa_tipe.search("var x := 5") == null, "pemeriksa gaya menangkap var tanpa tipe")
	check(re_untuk_tanpa_tipe.search("for i in range(3):") != null and re_untuk_tanpa_tipe.search("for i: int in range(3):") == null, "pemeriksa gaya menangkap for tanpa tipe")

	_judul("Kebersihan repo")
	var gitignore: String = FileAccess.get_file_as_string("res://.gitignore")
	for pola: String in [".godot/", "build/", "builds/", "*.apk", "*.aab"]:
		check(gitignore.split("\n").has(pola), ".gitignore menutup %s" % pola)


# --- Pembantu berkas ---

## Semua berkas berekstensi tertentu di bawah `folder` (rekursif), diurutkan.
func _daftar_berkas(folder: String, ekstensi: Array[String]) -> Array[String]:
	var hasil: Array[String] = []
	var dir: DirAccess = DirAccess.open(folder)
	if dir == null:
		return hasil
	for nama: String in dir.get_files():
		if ekstensi.has(nama.get_extension()):
			hasil.append(folder.path_join(nama))
	for sub: String in dir.get_directories():
		hasil.append_array(_daftar_berkas(folder.path_join(sub), ekstensi))
	hasil.sort()
	return hasil
