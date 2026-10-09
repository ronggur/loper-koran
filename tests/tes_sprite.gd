class_name TesSprite
extends RefCounted
## Tes sprite pemain run sprite-lempar-melambat: `SpriteFrames` gabungan 38 animasi (AC-2), pemilih animasi melambat dan
## lempar (AC-3), `LoperSprite` (AC-4). Wiring stick dan swipe di scene uji ada di `tests/tes_input_scene.gd` (AC-5).
##
## Dipanggil dari `tests/run_tests.gd` (`TesSprite.new(check, judul, tree).jalankan()`), memakai `check` milik runner supaya
## hitungan lolos/gagal dan ringkasan tetap satu. Waktu selalu parameter: node dijalankan lewat `LoperSprite.maju(dt)` dengan `dt`
## tetap, tidak pernah menunggu waktu nyata (rule `testing`).

const FOLDER_ASET: String = "res://assets/sprites/loper/"
const FOLDER_SUMBER: String = "res://docs/design/character/loper_agen/"
const BERKAS_FRAMES: String = "res://assets/sprites/loper/loper_agen_frames.tres"
## Tiga sheet: nama berkas JSON di aset, JSON sumber, PNG di aset dan sumber, jumlah animasi, jumlah baris, fps tiap animasi dibaca dari JSON.
const SHEET: Array = [
	{"tag": "kayuh", "json": "loper_agen.json", "png": "loper_agen.png", "sumber": "", "animasi": 15, "baris": 15},
	{"tag": "melambat", "json": "loper_agen_melambat.json", "png": "loper_agen_melambat.png", "sumber": "melambat/", "animasi": 5, "baris": 5},
	{"tag": "lempar", "json": "loper_agen_lempar.json", "png": "loper_agen_lempar.png", "sumber": "lempar/", "animasi": 18, "baris": 18},
]
const SEL: Vector2i = Vector2i(46, 58)
const KOLOM: int = 4
const DT: float = 1.0 / 60.0

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
	_test_aset_dan_frames()


## JSON sheet sebagai Dictionary (aset di repo), atau kosong bila gagal dibaca.
func _baca_json(nama: String) -> Dictionary:
	var hasil: Variant = JSON.parse_string(FileAccess.get_file_as_string(FOLDER_ASET + nama))
	return hasil if hasil is Dictionary else {}


# --- AC-2: aset tersalin byte-identik dan SpriteFrames gabungan 38 animasi ---

func _test_aset_dan_frames() -> void:
	_judul.call("Aset melambat dan lempar, SpriteFrames gabungan (AC-2)")
	# PNG dan JSON di assets/ harus byte-identik dengan sumber di docs/design/ (aset tidak diedit dengan tangan, rule `art-assets`).
	for sheet: Dictionary in SHEET:
		for nama: String in [sheet["png"], sheet["json"]]:
			var aset: PackedByteArray = FileAccess.get_file_as_bytes(FOLDER_ASET + nama)
			var sumber: PackedByteArray = FileAccess.get_file_as_bytes(FOLDER_SUMBER + String(sheet["sumber"]) + nama)
			check(aset.size() > 0 and aset == sumber, "%s: salinan di assets/sprites/loper byte-identik dengan sumber di docs/design (%d byte)" % [nama, aset.size()])
		var impor: ConfigFile = ConfigFile.new()
		var galat: int = impor.load(FOLDER_ASET + String(sheet["png"]) + ".import")
		check(galat == OK, "%s punya .import ter-commit" % sheet["png"])
		if galat == OK:
			check(int(impor.get_value("params", "compress/mode", -1)) == 0 and impor.get_value("params", "mipmaps/generate", true) == false and int(impor.get_value("params", "detect_3d/compress_to", -1)) == 0, "%s: impor Lossless, tanpa mipmap, tanpa kompresi VRAM 3D" % sheet["png"])

	var frames: SpriteFrames = load(BERKAS_FRAMES) as SpriteFrames
	check(frames != null, "loper_agen_frames.tres termuat sebagai SpriteFrames")
	if frames == null:
		return
	# Urutan animasi di berkas .tres: kayuh (15), melambat (5), lempar (18), masing-masing menurut urutan JSON.
	var nama_diharapkan: Array[String] = []
	var jumlah_json: int = 0
	for sheet: Dictionary in SHEET:
		var json: Dictionary = _baca_json(String(sheet["json"]))
		check(not json.is_empty(), "%s terbaca sebagai Dictionary" % sheet["json"])
		var daftar: Array = json.get("animations", [])
		check(daftar.size() == int(sheet["animasi"]), "%s mendaftar %d animasi, dapat %d" % [sheet["json"], sheet["animasi"], daftar.size()])
		for entri: Dictionary in daftar:
			nama_diharapkan.append(String(entri["name"]))
		jumlah_json += daftar.size()
	check(jumlah_json == 38 and nama_diharapkan.size() == 38, "tiga JSON sumber mendaftar 15 + 5 + 18 = 38 animasi, dapat %d" % jumlah_json)
	var nama_di_berkas: Array[String] = _nama_urut_di_tres(FileAccess.get_file_as_string(BERKAS_FRAMES))
	check(nama_di_berkas == nama_diharapkan, "urutan animasi di .tres = urutan JSON (kayuh, melambat, lempar); dapat %d nama" % nama_di_berkas.size())
	var nama_frames: PackedStringArray = frames.get_animation_names()
	check(nama_frames.size() == 38, "SpriteFrames memuat tepat 38 animasi, dapat %d" % nama_frames.size())
	var tanpa_ganda: Dictionary = {}
	for nama: String in nama_frames:
		tanpa_ganda[nama] = true
	check(tanpa_ganda.size() == 38, "38 nama animasi berbeda semua")

	# Tiap animasi cocok dengan JSON-nya: 4 frame, region, atlas, fps, loop.
	for sheet: Dictionary in SHEET:
		var json: Dictionary = _baca_json(String(sheet["json"]))
		var daftar: Array = json.get("animations", [])
		var jalur_sheet: String = FOLDER_ASET + String(sheet["png"])
		var tag: String = String(sheet["tag"])
		var ukuran: Texture2D = load(jalur_sheet) as Texture2D
		check(ukuran != null and ukuran.get_size() == Vector2(SEL.x * KOLOM, SEL.y * int(sheet["baris"])), "%s: ukuran sheet %s = 4 kolom x %d baris x sel 46x58" % [tag, ukuran.get_size() if ukuran != null else "?", sheet["baris"]])
		check(_sama_angka(json.get("cell", []), [float(SEL.x), float(SEL.y)]) and int(json.get("columns", 0)) == KOLOM and int(json.get("rows", 0)) == int(sheet["baris"]), "%s: JSON memuat sel 46x58, 4 kolom, %d baris" % [tag, sheet["baris"]])
		check(_sama_angka(json.get("ground_anchor", []), [23.0, 46.0]) and _sama_angka(json.get("godot_offset", []), [0.0, -17.0]), "%s: titik pijak (23, 46) dan offset (0, -17) sama dengan sheet kayuh (tidak melompat saat berganti)" % tag)
		var baris_ke: int = 0
		for entri: Dictionary in daftar:
			var nama: StringName = StringName(entri["name"])
			check(frames.has_animation(nama), "[%s] animasi '%s' dari JSON ada di SpriteFrames" % [tag, nama])
			if not frames.has_animation(nama):
				continue
			check(frames.get_frame_count(nama) == 4, "[%s] '%s' punya 4 frame" % [tag, nama])
			var loop_harapan: bool = tag != "lempar"
			check(frames.get_animation_loop(nama) == loop_harapan and bool(entri["loop"]) == loop_harapan, "[%s] '%s': loop = %s (kayuh dan melambat berulang, lempar sekali)" % [tag, nama, loop_harapan])
			var fps_json: float = entri["fps"]
			check(is_equal_approx(frames.get_animation_speed(nama), fps_json), "[%s] fps '%s' sama dengan JSON (%s)" % [tag, nama, fps_json])
			var fps_harapan: float = _fps_diharapkan(tag, String(entri.get("speed", "")))
			check(is_equal_approx(fps_json, fps_harapan), "[%s] fps '%s' = %s (kayuh 8/10/12, melambat 4, lempar 12)" % [tag, nama, fps_harapan])
			check(int(entri["row"]) == baris_ke, "[%s] '%s' di baris sheet %d sesuai urutan" % [tag, nama, baris_ke])
			baris_ke += 1
			var regions: Array = entri["regions"]
			check(regions.size() == 4, "[%s] JSON '%s' memuat 4 region" % [tag, nama])
			for i: int in range(mini(4, regions.size())):
				var tekstur: AtlasTexture = frames.get_frame_texture(nama, i) as AtlasTexture
				if tekstur == null:
					check(false, "[%s] frame %d '%s' adalah AtlasTexture" % [tag, i, nama])
					continue
				var r: Array = regions[i]
				var harapan: Rect2 = Rect2(r[0], r[1], r[2], r[3])
				check(tekstur.region == harapan, "[%s] region frame %d '%s' = %s (JSON), dapat %s" % [tag, i, nama, harapan, tekstur.region])
				check(tekstur.atlas != null and tekstur.atlas.resource_path == jalur_sheet, "[%s] frame %d '%s' memakai atlas %s" % [tag, i, nama, jalur_sheet])
				check(is_equal_approx(frames.get_frame_duration(nama, i), 1.0), "[%s] frame %d '%s' berdurasi relatif 1,0" % [tag, i, nama])
			if tag == "lempar":
				check(int(entri["release_frame"]) == 2, "[lempar] '%s': release_frame = 2 (frame Lepas, README lempar), dapat %s" % [nama, entri["release_frame"]])
				check(String(nama) == "lempar_%s_%s_%s" % [entri["side"], entri["speed"], entri["heading"]], "[lempar] nama '%s' = lempar_<sisi>_<kecepatan>_<arah> dari kolom JSON" % nama)
			if tag == "melambat":
				check(String(nama) == "melambat_%s" % entri["heading"], "[melambat] nama '%s' = melambat_<arah>" % nama)
		check(baris_ke == int(sheet["animasi"]), "[%s] semua %d baris sheet terpakai" % [tag, sheet["animasi"]])
	var json_lempar: Dictionary = _baca_json("loper_agen_lempar.json")
	check(int(json_lempar.get("release_frame", -1)) == 2, "loper_agen_lempar.json: release_frame global = 2")


## Nama animasi di teks `.tres` menurut urutan penulisan (`"name": &"..."`).
func _nama_urut_di_tres(teks: String) -> Array[String]:
	var hasil: Array[String] = []
	var re: RegEx = RegEx.create_from_string("\"name\": &\"([^\"]+)\"")
	for cocok: RegExMatch in re.search_all(teks):
		hasil.append(cocok.get_string(1))
	return hasil


## fps yang diharapkan: kayuh 8/10/12 menurut kecepatan, melambat 4, lempar 12 (BALANCING 2, README sprite).
func _fps_diharapkan(tag: String, kecepatan: String) -> float:
	if tag == "melambat":
		return 4.0
	if tag == "lempar":
		return 12.0
	var fps_kayuh: Dictionary = {"santai": 8.0, "cepat": 10.0, "ngebut": 12.0}
	return float(fps_kayuh.get(kecepatan, -1.0))


## True bila `nilai` (angka dari JSON, bertipe float) sama panjang dan sama isi dengan `harapan`.
func _sama_angka(nilai: Array, harapan: Array[float]) -> bool:
	if nilai.size() != harapan.size():
		return false
	for i: int in range(harapan.size()):
		if not is_equal_approx(float(nilai[i]), harapan[i]):
			return false
	return true
