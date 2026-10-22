class_name TesSprite
extends RefCounted
## Tes sprite pemain run sprite-lempar-melambat: `SpriteFrames` gabungan (AC-2; 48 animasi sejak run fase1a-gerak D-9, dengan
## meluncur dan rem; 50 sejak 2026-10-17 dengan jatuh_normal dan terjerembab_normal; 68 sejak Fase 5C dengan jatuh dan terjerembab lima arah,
## bangkit, dan berhenti), pemilih animasi melambat dan lempar (AC-3), `LoperSprite` (AC-4) termasuk pose meluncur dan rem. Wiring stick dan swipe di scene uji ada di `tests/tes_input_scene.gd` (AC-5).
##
## Dipanggil dari `tests/run_tests.gd` (`TesSprite.new(check, judul, tree).jalankan()`), memakai `check` milik runner supaya
## hitungan lolos/gagal dan ringkasan tetap satu. Waktu selalu parameter: node dijalankan lewat `LoperSprite.maju(dt)` dengan `dt`
## tetap, tidak pernah menunggu waktu nyata (rule `testing`).

const FOLDER_ASET: String = "res://assets/sprites/loper/"
const FOLDER_SUMBER: String = "res://docs/design/character/loper_agen/"
const BERKAS_FRAMES: String = "res://assets/sprites/loper/loper_agen_frames.tres"
const BERKAS_SCENE_PEMAIN: String = "res://scenes/entities/loper_agen.tscn"
## Lima sheet: nama berkas JSON di aset, JSON sumber, PNG di aset dan sumber, jumlah animasi, jumlah baris, fps tiap animasi dibaca dari JSON.
## Meluncur dan rem ditambah di run fase1a-gerak (D-9), urutan sesudah lempar.
const SHEET: Array = [
	{"tag": "kayuh", "json": "loper_agen.json", "png": "loper_agen.png", "sumber": "", "animasi": 15, "baris": 15},
	{"tag": "melambat", "json": "loper_agen_melambat.json", "png": "loper_agen_melambat.png", "sumber": "melambat/", "animasi": 5, "baris": 5},
	{"tag": "lempar", "json": "loper_agen_lempar.json", "png": "loper_agen_lempar.png", "sumber": "lempar/", "animasi": 18, "baris": 18},
	{"tag": "meluncur", "json": "loper_agen_meluncur.json", "png": "loper_agen_meluncur.png", "sumber": "rem_meluncur/", "animasi": 5, "baris": 5},
	{"tag": "rem", "json": "loper_agen_rem.json", "png": "loper_agen_rem.png", "sumber": "rem_meluncur/", "animasi": 5, "baris": 5},
]
## Jumlah animasi di SpriteFrames gabungan: 15 kayuh + 5 melambat + 18 lempar + 5 meluncur + 5 rem + 10 jatuh + 5 bangkit + 5 berhenti.
const JUMLAH_ANIMASI: int = 68
## Urutan arah di sheet Fase 5C (baris), sama dengan sheet kayuh.
const ARAH_5C: Array[String] = ["normal", "serong_kanan", "kanan", "serong_kiri", "kiri"]
## Sheet Fase 5C (usulan): jatuh (sejak 2026-10-17 arah normal saja di sel 114x68; Fase 5C lima arah di sel 140x88, titik pijak (70, 61)),
## bangkit (sel 140x88), berhenti (sel kayuh 46x58). Satu baris per arah. Harapan literal dari README di `docs/design/character/loper_agen/<tag>/`:
## animasi = [awalan nama, frame sheet, fps, loop]; nama lengkap `<awalan>_<arah>`. Semua offset Godot (0, -17) sama dengan sheet kayuh.
const SHEET_5C: Array = [
	{"tag": "jatuh", "png": "loper_agen_jatuh.png", "json": "loper_agen_jatuh.json", "sel": Vector2i(140, 88), "kolom": 5, "pijak": Vector2i(70, 61),
		"animasi": [["jatuh", [0, 1, 2, 3], 10.0, false], ["terjerembab", [3, 4], 3.0, true]]},
	{"tag": "bangkit", "png": "loper_agen_bangkit.png", "json": "loper_agen_bangkit.json", "sel": Vector2i(140, 88), "kolom": 6, "pijak": Vector2i(70, 61),
		"animasi": [["bangkit", [0, 1, 2, 3, 4, 5], 10.0, false]]},
	{"tag": "berhenti", "png": "loper_agen_berhenti.png", "json": "loper_agen_berhenti.json", "sel": Vector2i(46, 58), "kolom": 2, "pijak": Vector2i(23, 46),
		"animasi": [["berhenti", [0, 1], 3.0, true]]},
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
	_test_melambat_dari_stick()
	_test_nama_lempar()
	_test_sisi_dari_swipe()
	_test_lempar_waktu()
	_test_loper_sprite_tingkat()
	_test_loper_sprite_pose()
	_test_loper_sprite_jatuh()
	_test_loper_sprite_lempar()
	_test_loper_sprite_lempar_menyela()
	_test_loper_sprite_lempar_semua_kombinasi()
	_test_loper_sprite_lempar_tepi()
	_test_loper_sprite_di_tree()
	_test_loper_sprite_tanpa_frames()
	_test_titik_pijak_sama()


## JSON sheet sebagai Dictionary (aset di repo), atau kosong bila gagal dibaca.
func _baca_json(nama: String) -> Dictionary:
	var hasil: Variant = JSON.parse_string(FileAccess.get_file_as_string(FOLDER_ASET + nama))
	return hasil if hasil is Dictionary else {}


# --- AC-2: aset tersalin byte-identik dan SpriteFrames gabungan (50 animasi sejak 2026-10-17) ---

func _test_aset_dan_frames() -> void:
	_judul.call("Aset melambat, lempar, meluncur, rem, SpriteFrames gabungan (AC-2, AC-7 run fase1a-gerak)")
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
	# Urutan animasi di berkas .tres: kayuh (15), melambat (5), lempar (18), meluncur (5), rem (5), masing-masing menurut urutan JSON.
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
	for sheet: Dictionary in SHEET_5C:
		for arah: String in ARAH_5C:
			for entri: Array in sheet["animasi"]:
				nama_diharapkan.append("%s_%s" % [entri[0], arah])
		jumlah_json += (_baca_json(String(sheet["json"])).get("animations", []) as Array).size()
	check(jumlah_json == JUMLAH_ANIMASI and nama_diharapkan.size() == JUMLAH_ANIMASI, "delapan JSON sumber mendaftar 15 + 5 + 18 + 5 + 5 + 10 + 5 + 5 = 68 animasi, dapat %d" % jumlah_json)
	var nama_di_berkas: Array[String] = _nama_urut_di_tres(FileAccess.get_file_as_string(BERKAS_FRAMES))
	check(nama_di_berkas == nama_diharapkan, "urutan animasi di .tres = urutan JSON (kayuh, melambat, lempar, meluncur, rem, jatuh, bangkit, berhenti); dapat %d nama" % nama_di_berkas.size())
	var nama_frames: PackedStringArray = frames.get_animation_names()
	check(nama_frames.size() == JUMLAH_ANIMASI, "SpriteFrames memuat tepat 68 animasi, dapat %d" % nama_frames.size())
	var tanpa_ganda: Dictionary = {}
	for nama: String in nama_frames:
		tanpa_ganda[nama] = true
	check(tanpa_ganda.size() == JUMLAH_ANIMASI, "68 nama animasi berbeda semua")

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
			check(frames.get_animation_loop(nama) == loop_harapan and bool(entri["loop"]) == loop_harapan, "[%s] '%s': loop = %s (kayuh, melambat, meluncur, rem berulang; lempar sekali)" % [tag, nama, loop_harapan])
			var fps_json: float = entri["fps"]
			check(is_equal_approx(frames.get_animation_speed(nama), fps_json), "[%s] fps '%s' sama dengan JSON (%s)" % [tag, nama, fps_json])
			var fps_harapan: float = _fps_diharapkan(tag, String(entri.get("speed", "")))
			check(is_equal_approx(fps_json, fps_harapan), "[%s] fps '%s' = %s (kayuh 8/10/12, melambat 4, lempar 12, meluncur 4, rem 8)" % [tag, nama, fps_harapan])
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
			if tag == "melambat" or tag == "meluncur" or tag == "rem":
				check(String(nama) == "%s_%s" % [tag, entri["heading"]], "[%s] nama '%s' = %s_<arah>" % [tag, nama, tag])
		check(baris_ke == int(sheet["animasi"]), "[%s] semua %d baris sheet terpakai" % [tag, sheet["animasi"]])
	var json_lempar: Dictionary = _baca_json("loper_agen_lempar.json")
	check(int(json_lempar.get("release_frame", -1)) == 2, "loper_agen_lempar.json: release_frame global = 2")
	_test_aset_5c(frames)


## Sheet Fase 5C (jatuh, bangkit, berhenti; usulan): salinan byte-identik dengan sumber, impor, ukuran dan sel, titik pijak dengan offset (0, -17)
## sama dengan sheet kayuh (jarak titik pijak ke tengah sel: 61 - 44 = 46 - 29 = 17), animasi per arah di SpriteFrames gabungan, dan frame
## terakhir bangkit = kayuh santai frame 0 (piksel sama, titik pijak sama) supaya `santai_<arah>` menyusul tanpa lompatan.
func _test_aset_5c(frames: SpriteFrames) -> void:
	for sheet: Dictionary in SHEET_5C:
		var tag: String = String(sheet["tag"])
		for nama: String in [String(sheet["png"]), String(sheet["json"])]:
			var aset: PackedByteArray = FileAccess.get_file_as_bytes(FOLDER_ASET + nama)
			var sumber: PackedByteArray = FileAccess.get_file_as_bytes(FOLDER_SUMBER + tag + "/" + nama)
			check(aset.size() > 0 and aset == sumber, "%s: salinan di assets/sprites/loper byte-identik dengan sumber %s/ (%d byte)" % [nama, tag, aset.size()])
		var impor: ConfigFile = ConfigFile.new()
		var galat: int = impor.load(FOLDER_ASET + String(sheet["png"]) + ".import")
		check(galat == OK and int(impor.get_value("params", "compress/mode", -1)) == 0 and impor.get_value("params", "mipmaps/generate", true) == false, "%s: .import ter-commit, Lossless, tanpa mipmap" % sheet["png"])
		var sel: Vector2i = sheet["sel"]
		var pijak: Vector2i = sheet["pijak"]
		var kolom: int = int(sheet["kolom"])
		var jalur: String = FOLDER_ASET + String(sheet["png"])
		var tekstur: Texture2D = load(jalur) as Texture2D
		var ukuran: Vector2 = Vector2(sel.x * kolom, sel.y * ARAH_5C.size())
		check(tekstur != null and tekstur.get_size() == ukuran, "sheet %s %s (%d kolom x 5 arah x sel %dx%d), dapat %s" % [tag, ukuran, kolom, sel.x, sel.y, tekstur.get_size() if tekstur != null else "?"])
		var json: Dictionary = _baca_json(String(sheet["json"]))
		check(_sama_angka(json.get("cell", []), [float(sel.x), float(sel.y)]) and int(json.get("columns", 0)) == kolom and int(json.get("rows", 0)) == ARAH_5C.size(), "JSON %s: sel %dx%d, %d kolom, 5 baris" % [tag, sel.x, sel.y, kolom])
		check(_sama_angka(json.get("ground_anchor", []), [float(pijak.x), float(pijak.y)]) and _sama_angka(json.get("godot_offset", []), [0.0, -17.0]), "JSON %s: titik pijak %s, offset (0, -17) sama dengan kayuh" % [tag, pijak])
		check(pijak.x * 2 == sel.x and pijak.y - sel.y / 2 == 46 - 58 / 2, "titik pijak %s di tengah sel mendatar dan 17 px di bawah tengah sel, sama dengan kayuh (23, 46) di sel 46x58" % tag)
		for baris: int in range(ARAH_5C.size()):
			for entri: Array in sheet["animasi"]:
				var nama: StringName = StringName("%s_%s" % [entri[0], ARAH_5C[baris]])
				var urutan: Array = entri[1]
				check(frames.has_animation(nama), "animasi '%s' ada di SpriteFrames gabungan" % nama)
				if not frames.has_animation(nama):
					continue
				check(frames.get_frame_count(nama) == urutan.size() and is_equal_approx(frames.get_animation_speed(nama), float(entri[2])) and frames.get_animation_loop(nama) == bool(entri[3]), "'%s': %d frame, %s fps, loop %s" % [nama, urutan.size(), entri[2], entri[3]])
				for i: int in range(mini(urutan.size(), frames.get_frame_count(nama))):
					var t: AtlasTexture = frames.get_frame_texture(nama, i) as AtlasTexture
					var harapan: Rect2 = Rect2(int(urutan[i]) * sel.x, baris * sel.y, sel.x, sel.y)
					check(t != null and t.region == harapan and t.atlas != null and t.atlas.resource_path == jalur, "'%s' frame %d = region %s di sheet %s" % [nama, i, harapan, tag])
	# Bangkit frame 5 = kayuh santai frame 0, ditempel di (70 - 23, 61 - 46) = (47, 15) dalam sel 140x88; di luar itu kosong.
	var kayuh: Image = (load(FOLDER_ASET + "loper_agen.png") as Texture2D).get_image()
	var bangkit: Image = (load(FOLDER_ASET + "loper_agen_bangkit.png") as Texture2D).get_image()
	for baris: int in range(ARAH_5C.size()):
		var akhir: Image = bangkit.get_region(Rect2i(5 * 140, baris * 88, 140, 88))
		var sama: bool = true
		for y: int in range(88):
			for x: int in range(140):
				var di_kayuh: bool = x >= 47 and x < 47 + 46 and y >= 15 and y < 15 + 58
				var c: Color = akhir.get_pixel(x, y)
				if di_kayuh:
					# Piksel transparan dibandingkan dari alfa saja: impor Godot (fix alpha border) bisa mengubah RGB piksel transparan.
					var k: Color = kayuh.get_pixel(x - 47, baris * 58 + y - 15)
					if c.a8 != k.a8 or (k.a8 != 0 and c != k):
						sama = false
				elif c.a8 != 0:
					sama = false
		check(sama, "bangkit_%s frame 5 = santai_%s frame 0 piksel demi piksel (titik pijak sama, tanpa lompatan)" % [ARAH_5C[baris], ARAH_5C[baris]])


## Nama animasi di teks `.tres` menurut urutan penulisan (`"name": &"..."`).
func _nama_urut_di_tres(teks: String) -> Array[String]:
	var hasil: Array[String] = []
	var re: RegEx = RegEx.create_from_string("\"name\": &\"([^\"]+)\"")
	for cocok: RegExMatch in re.search_all(teks):
		hasil.append(cocok.get_string(1))
	return hasil


## fps yang diharapkan: kayuh 8/10/12 menurut kecepatan, melambat 4, lempar 12, meluncur 4, rem 8 (BALANCING 2, README sprite).
func _fps_diharapkan(tag: String, kecepatan: String) -> float:
	if tag == "melambat" or tag == "meluncur":
		return 4.0
	if tag == "rem":
		return 8.0
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


# --- AC-3: LoperAnim murni ---

## Tingkat sprite dari geseran jari tegak lurus ke bawah (`persen` dari jangkauan stick) lewat rantai StickMap -> LoperAnim.
func _tingkat_bawah(persen: float) -> int:
	var hasil: Vector2 = StickMap.petakan(Vector2(0.0, Config.STICK_RADIUS_PX * persen / 100.0))
	return LoperAnim.tingkat_dari_stick(hasil.y)


func _test_melambat_dari_stick() -> void:
	_judul.call("Melambat dari stick (AC-3, D-1)")
	# Nama animasi melambat untuk lima arah, semuanya ada di SpriteFrames.
	var frames: SpriteFrames = load(BERKAS_FRAMES) as SpriteFrames
	var diharapkan: Dictionary = {-2: "melambat_kiri", -1: "melambat_serong_kiri", 0: "melambat_normal", 1: "melambat_serong_kanan", 2: "melambat_kanan"}
	for arah: int in diharapkan:
		var nama: StringName = LoperAnim.nama_animasi(LoperAnim.TINGKAT_MELAMBAT, arah)
		check(String(nama) == String(diharapkan[arah]), "tingkat melambat arah %d = '%s', dapat '%s'" % [arah, diharapkan[arah], nama])
		check(frames != null and frames.has_animation(nama), "animasi '%s' ada di SpriteFrames" % nama)
	check(LoperAnim.jepit_tingkat(-9) == LoperAnim.TINGKAT_MELAMBAT and LoperAnim.jepit_tingkat(9) == 2 and LoperAnim.jepit_tingkat(-1) == -1 and LoperAnim.jepit_tingkat(0) == 0, "jepit_tingkat: -9 -> -1, 9 -> 2, -1 dan 0 tetap")
	# Zona mati 15% (BALANCING 2): 14,9% dan 15,0% ke bawah tidak, 15,1% ya. Rantai penuh StickMap.petakan -> tingkat_dari_stick.
	check(_tingkat_bawah(0.0) == 0 and _tingkat_bawah(14.9) == 0, "stick ke bawah 0% dan 14,9% (di dalam zona mati) = santai, bukan melambat")
	check(_tingkat_bawah(15.0) == 0, "stick ke bawah tepat 15,0% (tepi zona mati, inklusif) = santai")
	check(_tingkat_bawah(15.1) == LoperAnim.TINGKAT_MELAMBAT, "stick ke bawah 15,1% (tepat di luar zona mati) = melambat")
	check(_tingkat_bawah(50.0) == LoperAnim.TINGKAT_MELAMBAT and _tingkat_bawah(100.0) == LoperAnim.TINGKAT_MELAMBAT and _tingkat_bawah(300.0) == LoperAnim.TINGKAT_MELAMBAT, "stick ke bawah 50%, 100%, dan di atas jangkauan = melambat")
	# Stick ke atas atau ke samping tidak pernah melambat.
	var tidak_pernah: bool = true
	for persen: float in [14.9, 15.1, 50.0, 100.0]:
		var geser: float = Config.STICK_RADIUS_PX * persen / 100.0
		if LoperAnim.tingkat_dari_stick(StickMap.petakan(Vector2(0.0, -geser)).y) < 0:
			tidak_pernah = false
		if LoperAnim.tingkat_dari_stick(StickMap.petakan(Vector2(geser, 0.0)).y) < 0 or LoperAnim.tingkat_dari_stick(StickMap.petakan(Vector2(-geser, 0.0)).y) < 0:
			tidak_pernah = false
	check(tidak_pernah, "stick ke atas (14,9 sampai 100%) dan ke samping murni tidak pernah melambat")
	# Fungsi murni di batas nol: nol dan -0,0 bukan melambat, negatif sekecil apa pun ya.
	check(LoperAnim.tingkat_dari_stick(0.0) == 0 and LoperAnim.tingkat_dari_stick(-0.0) == 0, "komponen maju tepat nol (dan -0,0) = santai")
	check(LoperAnim.tingkat_dari_stick(-0.000001) == LoperAnim.TINGKAT_MELAMBAT and LoperAnim.tingkat_dari_stick(-1.0) == LoperAnim.TINGKAT_MELAMBAT, "komponen maju negatif sekecil 1e-6 sampai -1 = melambat")
	check(LoperAnim.tingkat_dari_stick(NAN) == 0, "NaN tetap santai, bukan melambat")
	# Terpadu dengan BikeMotion (sejak run fase1a-gerak; dulu BikeDrive): bawah 15,1% memberi tujuan 2,998 u/d, kecepatan 3,0 sudah
	# di dalam toleransi pose, jadi pose kayuh tingkat melambat (melambat_normal), bukan meluncur (D-7).
	var awal: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
	var geser_151: Vector2 = StickMap.petakan(Vector2(0.0, Config.STICK_RADIUS_PX * 0.151))
	var hasil_151: BikeMotion.Hasil = BikeMotion.langkah(awal, geser_151, DT)
	check(hasil_151.tingkat_sprite == LoperAnim.TINGKAT_MELAMBAT and hasil_151.pose == LoperAnim.Pose.KAYUH, "BikeMotion: stick bawah 15,1% memberi tingkat sprite melambat dengan pose kayuh (melambat_normal)")
	var hasil_149: BikeMotion.Hasil = BikeMotion.langkah(awal, StickMap.petakan(Vector2(0.0, Config.STICK_RADIUS_PX * 0.149)), DT)
	check(hasil_149.tingkat_sprite == 0 and hasil_149.keadaan.kecepatan_ud == 3.0, "BikeMotion: stick bawah 14,9% tetap santai 3,0 u/d")
	# Bawah sambil ke samping: dari 3,0 u/d kecepatan masih jauh di atas tujuan (1,95) = meluncur serong; di tujuan = melambat serong.
	var stick_serong: Vector2 = StickMap.petakan(Vector2(Config.STICK_RADIUS_PX * 0.7, Config.STICK_RADIUS_PX * 0.7))
	var serong: BikeMotion.Hasil = BikeMotion.langkah(awal, stick_serong, DT)
	var nama_serong: StringName = LoperAnim.nama_animasi_pose(serong.pose, serong.tingkat_sprite, serong.arah_sprite)
	check(serong.tingkat_sprite == LoperAnim.TINGKAT_MELAMBAT and nama_serong == &"meluncur_serong_kanan", "stick ke bawah-dekat dari 3,0 u/d: meluncur_serong_kanan (arah dari gerak, D-7), dapat %s" % nama_serong)
	var di_tujuan: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
	di_tujuan.kecepatan_ud = BikeMotion.kecepatan_tujuan_ud(stick_serong.y)
	serong = BikeMotion.langkah(di_tujuan, stick_serong, DT)
	nama_serong = LoperAnim.nama_animasi_pose(serong.pose, serong.tingkat_sprite, serong.arah_sprite)
	check(nama_serong == &"melambat_serong_kanan", "stick ke bawah-dekat di kecepatan tujuan: melambat_serong_kanan, dapat %s" % nama_serong)


func _test_nama_lempar() -> void:
	_judul.call("Nama animasi lempar (AC-3, D-3)")
	var frames: SpriteFrames = load(BERKAS_FRAMES) as SpriteFrames
	var nama_kecepatan: Dictionary = {0: "santai", 1: "cepat", 2: "ngebut"}
	var nama_arah: Dictionary = {-1: "serong_kiri", 0: "normal", 1: "serong_kanan"}
	var nama_sisi: Dictionary = {LoperAnim.Sisi.SEBERANG: "kiri", LoperAnim.Sisi.DEKAT: "kanan"}
	var terlihat: Dictionary = {}
	var semua_ada: bool = true
	for sisi: LoperAnim.Sisi in [LoperAnim.Sisi.SEBERANG, LoperAnim.Sisi.DEKAT]:
		for tingkat: int in range(LoperAnim.TINGKAT_MELAMBAT, 3):
			for arah: int in range(-2, 3):
				var nama: StringName = LoperAnim.nama_lempar(sisi, tingkat, arah)
				terlihat[nama] = true
				if frames == null or not frames.has_animation(nama):
					semua_ada = false
				# Aturan D-3: melambat memakai santai, arah 90 derajat memakai serong di sisi yang sama.
				var tingkat_pakai: int = maxi(tingkat, 0)
				var arah_pakai: int = clampi(arah, -1, 1)
				var harapan: String = "lempar_%s_%s_%s" % [nama_sisi[sisi], nama_kecepatan[tingkat_pakai], nama_arah[arah_pakai]]
				check(String(nama) == harapan, "lempar (sisi %d, tingkat %d, arah %d) = '%s', dapat '%s'" % [sisi, tingkat, arah, harapan, nama])
	check(semua_ada, "semua 40 kombinasi (2 sisi x tingkat melambat+3 x 5 arah) menghasilkan nama yang ada di SpriteFrames")
	check(terlihat.size() == 18, "40 kombinasi menghasilkan tepat 18 nama berbeda (semua animasi lempar terpakai), dapat %d" % terlihat.size())
	# Contoh eksplisit (bukan hasil rumus yang sama).
	check(LoperAnim.nama_lempar(LoperAnim.Sisi.SEBERANG, 0, 0) == &"lempar_kiri_santai_normal", "seberang, santai, normal = lempar_kiri_santai_normal")
	check(LoperAnim.nama_lempar(LoperAnim.Sisi.DEKAT, 2, 0) == &"lempar_kanan_ngebut_normal", "dekat, ngebut, normal = lempar_kanan_ngebut_normal")
	check(LoperAnim.nama_lempar(LoperAnim.Sisi.DEKAT, LoperAnim.TINGKAT_MELAMBAT, 0) == &"lempar_kanan_santai_normal", "melambat jatuh ke santai: dekat, melambat, normal = lempar_kanan_santai_normal")
	check(LoperAnim.nama_lempar(LoperAnim.Sisi.SEBERANG, 1, 2) == &"lempar_kiri_cepat_serong_kanan", "arah +2 (90 derajat ke dekat) jatuh ke serong_kanan di sisi yang sama (seberang, cepat) = lempar_kiri_cepat_serong_kanan")
	check(LoperAnim.nama_lempar(LoperAnim.Sisi.DEKAT, 1, -2) == &"lempar_kanan_cepat_serong_kiri", "arah -2 jatuh ke serong_kiri: lempar_kanan_cepat_serong_kiri")
	check(LoperAnim.nama_lempar(LoperAnim.Sisi.SEBERANG, 9, -9) == &"lempar_kiri_ngebut_serong_kiri", "tingkat dan arah di luar jangkauan dijepit dulu: (9, -9) = lempar_kiri_ngebut_serong_kiri")
	check(LoperAnim.nama_lempar(LoperAnim.Sisi.SEBERANG, -9, 9) == &"lempar_kiri_santai_serong_kanan", "(-9, 9) = melambat -> santai, arah +2 -> serong_kanan")
	# Tanpa sisi: nama kosong (tidak ada animasi).
	check(LoperAnim.nama_lempar(LoperAnim.Sisi.TIDAK_ADA, 0, 0) == &"", "Sisi.TIDAK_ADA menghasilkan nama kosong")
	check(LoperAnim.nama_lempar(7 as LoperAnim.Sisi, 0, 0) == &"" and LoperAnim.nama_lempar(-1 as LoperAnim.Sisi, 0, 0) == &"", "nilai sisi yang tidak dikenal (7, -1) menghasilkan nama kosong")
	check(LoperAnim.tingkat_untuk_lempar(-1) == 0 and LoperAnim.tingkat_untuk_lempar(0) == 0 and LoperAnim.tingkat_untuk_lempar(2) == 2 and LoperAnim.tingkat_untuk_lempar(-9) == 0, "tingkat_untuk_lempar: melambat dan di bawahnya -> 0, lainnya tetap")
	check(LoperAnim.arah_untuk_lempar(2) == 1 and LoperAnim.arah_untuk_lempar(-2) == -1 and LoperAnim.arah_untuk_lempar(1) == 1 and LoperAnim.arah_untuk_lempar(0) == 0 and LoperAnim.arah_untuk_lempar(9) == 1, "arah_untuk_lempar: +-2 -> +-1 (tanda dipertahankan), lainnya tetap")


func _test_sisi_dari_swipe() -> void:
	# Run fase2a-lemparan (D-2): fungsi pindah dari `LoperAnim` ke `ThrowSolver`; ambang 12 px diganti 6% lebar viewport game (inklusif).
	# Run fase2-arah-bebas (D-1 sampai D-3): tidak ada lagi sudut yang ditolak (tegak dominan dan tepat 45 derajat dulu TIDAK_ADA); sisi
	# dari komponen melintang arah tanah `Iso.layar_ke_dunia(v)` dan ambang dari |v| penuh. Kasus Run 2A diganti dengan harapan arah bebas.
	_judul.call("Sisi lempar dari swipe: arah bebas, ambang |v| 6% (AC-3 run sprite-lempar-melambat, D-2 Run 2A, AC-4 run fase2-arah-bebas)")
	var lebar: float = 780.0
	var ambang: float = ThrowSolver.swipe_min_px(lebar)
	check(is_equal_approx(ambang, 46.8), "ambang swipe lempar di lebar 780 = 6%% = 46,8 px game, dapat %s" % ambang)
	var awal: Vector2 = Vector2(450.0, 200.0)
	# Kiri layar murni = seberang (sedikit ke belakang), kanan layar murni = dekat (ke depan), di berbagai panjang.
	for panjang: float in [47.0, 60.0, 200.0, 400.0]:
		check(ThrowSolver.sisi_dari_swipe(awal, awal + Vector2(-panjang, 0.0), lebar) == LoperAnim.Sisi.SEBERANG, "swipe %s px ke kiri layar = SEBERANG" % panjang)
		check(ThrowSolver.sisi_dari_swipe(awal, awal + Vector2(panjang, 0.0), lebar) == LoperAnim.Sisi.DEKAT, "swipe %s px ke kanan layar = DEKAT" % panjang)
	# Miring: sisi dari x tanah = (dy / 16 + dx / 32) / 2, jadi garis pemisahnya searah sumbu jalan di layar (kemiringan 1:2), bukan tegak.
	check(ThrowSolver.sisi_dari_swipe(awal, awal + Vector2(-80.0, -60.0), lebar) == LoperAnim.Sisi.SEBERANG and ThrowSolver.sisi_dari_swipe(awal, awal + Vector2(80.0, -60.0), lebar) == LoperAnim.Sisi.SEBERANG, "kiri atas dan kanan atas yang lebih curam dari jalan = SEBERANG (di depan)")
	check(ThrowSolver.sisi_dari_swipe(awal, awal + Vector2(80.0, 60.0), lebar) == LoperAnim.Sisi.DEKAT and ThrowSolver.sisi_dari_swipe(awal, awal + Vector2(-80.0, 60.0), lebar) == LoperAnim.Sisi.DEKAT, "kanan bawah dan kiri bawah yang lebih curam dari jalan = DEKAT (di belakang)")
	# Tegak dan 45 derajat kini melempar (dulu ditolak).
	check(ThrowSolver.sisi_dari_swipe(awal, awal + Vector2(0.0, -60.0), lebar) == LoperAnim.Sisi.SEBERANG and ThrowSolver.sisi_dari_swipe(awal, awal + Vector2(0.0, 60.0), lebar) == LoperAnim.Sisi.DEKAT, "swipe lurus ke atas = SEBERANG, ke bawah = DEKAT (tidak ditolak lagi)")
	check(ThrowSolver.sisi_dari_swipe(awal, awal + Vector2(-60.0, -80.0), lebar) == LoperAnim.Sisi.SEBERANG and ThrowSolver.sisi_dari_swipe(awal, awal + Vector2(60.0, 80.0), lebar) == LoperAnim.Sisi.DEKAT, "swipe miring tegak (60/80) melempar")
	check(ThrowSolver.sisi_dari_swipe(awal, awal + Vector2(-50.0, -50.0), lebar) == LoperAnim.Sisi.SEBERANG and ThrowSolver.sisi_dari_swipe(awal, awal + Vector2(50.0, 50.0), lebar) == LoperAnim.Sisi.DEKAT, "tepat 45 derajat tidak ambigu lagi: kiri atas SEBERANG, kanan bawah DEKAT")
	check(ThrowSolver.sisi_dari_swipe(awal, awal + Vector2(51.0, 50.0), lebar) == LoperAnim.Sisi.DEKAT and ThrowSolver.sisi_dari_swipe(awal, awal + Vector2(-51.0, 50.0), lebar) == LoperAnim.Sisi.DEKAT, "51/50 ke bawah: DEKAT di kedua arah datar (bawah lebih curam dari jalan)")
	# Ambang: |v| penuh.
	check(ThrowSolver.sisi_dari_swipe(awal, awal + Vector2(46.7, 0.0), lebar) == LoperAnim.Sisi.TIDAK_ADA and ThrowSolver.sisi_dari_swipe(awal, awal + Vector2(0.0, -46.7), lebar) == LoperAnim.Sisi.TIDAK_ADA, "swipe 46,7 px (di bawah 46,8) tidak melempar, datar maupun tegak")
	check(ThrowSolver.sisi_dari_swipe(awal, awal + Vector2(ambang, 0.0), lebar) == LoperAnim.Sisi.DEKAT and ThrowSolver.sisi_dari_swipe(awal, awal - Vector2(ambang, 0.0), lebar) == LoperAnim.Sisi.SEBERANG and ThrowSolver.sisi_dari_swipe(awal, awal - Vector2(0.0, ambang), lebar) == LoperAnim.Sisi.SEBERANG, "swipe tepat di ambang (presisi tunggal Vector2) melempar, datar dan tegak (inklusif)")
	check(ThrowSolver.sisi_dari_swipe(awal, awal + Vector2(46.0, 20.0), lebar) == LoperAnim.Sisi.DEKAT, "46 datar + 20 tegak (|v| 50,2 di atas ambang) melempar: yang dihitung |v|, bukan |dx|")
	# Tidak bergantung pada posisi awal.
	check(ThrowSolver.sisi_dari_swipe(Vector2(0.0, 0.0), Vector2(-60.0, 3.0), lebar) == LoperAnim.Sisi.SEBERANG and ThrowSolver.sisi_dari_swipe(Vector2(779.0, 359.0), Vector2(719.0, 357.0), lebar) == LoperAnim.Sisi.SEBERANG, "hasil hanya bergantung pada selisih, bukan letak titik awal")
	# Vektor nol dan nilai tidak sah.
	check(ThrowSolver.sisi_dari_swipe(awal, awal, lebar) == LoperAnim.Sisi.TIDAK_ADA, "vektor nol (tap tanpa geser) tidak melempar")
	check(ThrowSolver.sisi_dari_swipe(Vector2(NAN, 0.0), awal, lebar) == LoperAnim.Sisi.TIDAK_ADA and ThrowSolver.sisi_dari_swipe(awal, Vector2(NAN, NAN), lebar) == LoperAnim.Sisi.TIDAK_ADA, "NaN pada titik awal atau akhir tidak melempar")
	check(ThrowSolver.sisi_dari_swipe(awal, Vector2(INF, 200.0), lebar) == LoperAnim.Sisi.TIDAK_ADA and ThrowSolver.sisi_dari_swipe(Vector2(-INF, 0.0), awal, lebar) == LoperAnim.Sisi.TIDAK_ADA, "tak hingga pada titik awal atau akhir tidak melempar")
	check(ThrowSolver.sisi_dari_swipe(Vector2.ZERO, Vector2(1.0e30, 0.0), lebar) == LoperAnim.Sisi.DEKAT, "swipe sangat panjang tetap hingga dan melempar ke dekat")


# --- LemparWaktu: garis waktu animasi lempar (murni) ---

## Menjalankan `langkah` berulang dengan `dt` tetap sampai selesai (atau `maks` langkah). Mengembalikan
## {"langkah": jumlah, "lepas_di": nomor langkah lepas, "lepas": berapa kali, "frame": urutan frame per langkah}.
func _putar(dt: float, maks: int = 1000) -> Dictionary:
	var waktu: float = 0.0
	var jumlah_lepas: int = 0
	var lepas_di: int = -1
	var urutan: Array[int] = []
	var nomor: int = 0
	while nomor < maks:
		nomor += 1
		var hasil: LemparWaktu.Langkah = LemparWaktu.langkah(waktu, dt, 12.0, 4, Config.LEMPAR_FRAME_LEPAS)
		waktu = hasil.waktu
		urutan.append(hasil.frame)
		if hasil.lepas:
			jumlah_lepas += 1
			lepas_di = nomor
		if hasil.selesai:
			break
	return {"langkah": nomor, "lepas_di": lepas_di, "lepas": jumlah_lepas, "frame": urutan, "waktu": waktu}


func _test_lempar_waktu() -> void:
	_judul.call("Garis waktu lempar (LemparWaktu)")
	check(Config.LEMPAR_FRAME_LEPAS == 2, "Config.LEMPAR_FRAME_LEPAS = 2 (indeks frame Lepas)")
	check(is_equal_approx(LemparWaktu.durasi(12.0, 4), 1.0 / 3.0), "durasi 4 frame pada 12 fps = 1/3 detik")
	check(LemparWaktu.durasi(0.0, 4) == 0.0 and LemparWaktu.durasi(-12.0, 4) == 0.0 and LemparWaktu.durasi(NAN, 4) == 0.0 and LemparWaktu.durasi(12.0, 0) == 0.0 and LemparWaktu.durasi(INF, 4) == 0.0, "durasi dengan fps nol, negatif, NaN, tak hingga, atau tanpa frame = 0")
	# frame_di di batas frame (12 fps: frame n mulai di n/12 detik).
	check(LemparWaktu.frame_di(0.0, 12.0, 4) == 0 and LemparWaktu.frame_di(1.0 / 12.0 - 0.001, 12.0, 4) == 0, "frame_di: 0 detik dan sedikit sebelum 1/12 = frame 0")
	check(LemparWaktu.frame_di(1.0 / 12.0, 12.0, 4) == 1 and LemparWaktu.frame_di(2.0 / 12.0 - 0.001, 12.0, 4) == 1, "frame_di: tepat 1/12 = frame 1 (batas masuk frame berikutnya)")
	check(LemparWaktu.frame_di(2.0 / 12.0, 12.0, 4) == 2 and LemparWaktu.frame_di(3.0 / 12.0, 12.0, 4) == 3, "frame_di: tepat 2/12 = frame 2 (Lepas), 3/12 = frame 3")
	check(LemparWaktu.frame_di(4.0 / 12.0, 12.0, 4) == 3 and LemparWaktu.frame_di(100.0, 12.0, 4) == 3 and LemparWaktu.frame_di(1.0e300, 12.0, 4) == 3, "frame_di dijepit ke frame terakhir (4/12, 100 detik, 1e300)")
	check(LemparWaktu.frame_di(-1.0, 12.0, 4) == 0 and LemparWaktu.frame_di(NAN, 12.0, 4) == 0 and LemparWaktu.frame_di(INF, 12.0, 4) == 0, "frame_di: waktu negatif, NaN, tak hingga = frame 0")
	# Putaran dengan dt tetap 1/60: frame berganti tiap 5 langkah, lepas di langkah 10, selesai di langkah 20 (tepat, walau float menumpuk).
	var enam_puluh: Dictionary = _putar(1.0 / 60.0)
	var urutan: Array[int] = enam_puluh["frame"]
	check(enam_puluh["langkah"] == 20, "dt 1/60: selesai tepat di langkah 20 (4 frame x 5 langkah), dapat %d" % enam_puluh["langkah"])
	check(enam_puluh["lepas"] == 1 and enam_puluh["lepas_di"] == 10, "dt 1/60: lepas tepat sekali, di langkah 10 (frame 2 pertama tampil), dapat %d kali di langkah %d" % [enam_puluh["lepas"], enam_puluh["lepas_di"]])
	check(urutan.slice(0, 4) == [0, 0, 0, 0] and urutan[4] == 1 and urutan[9] == 2 and urutan[14] == 3 and urutan[19] == 3, "dt 1/60: frame 0 selama langkah 1-4, frame 1 mulai langkah 5, frame 2 mulai langkah 10, frame 3 mulai langkah 15")
	for dt: float in [0.01, 1.0 / 30.0, 0.05, 1.0 / 24.0, 0.0125]:
		var hasil: Dictionary = _putar(dt)
		var frame: Array[int] = hasil["frame"]
		var naik: bool = true
		for i: int in range(1, frame.size()):
			if frame[i] < frame[i - 1]:
				naik = false
		var langkah_total: int = int(ceilf((1.0 / 3.0) / dt - 0.000001))
		check(hasil["lepas"] == 1 and hasil["langkah"] == langkah_total and naik and frame[frame.size() - 1] == 3, "dt %s: lepas tepat sekali, selesai di langkah %d (dapat %d), frame tidak pernah mundur" % [dt, langkah_total, hasil["langkah"]])
		var langkah_lepas: int = int(ceilf((2.0 / 12.0) / dt - 0.000001))
		check(hasil["lepas_di"] == langkah_lepas, "dt %s: lepas di langkah %d (waktu pertama >= 2/12 detik), dapat %d" % [dt, langkah_lepas, hasil["lepas_di"]])
	# Batas inklusif TEPAT (posisi frame persis bilangan bulat, dihitung dengan toleransi yang sama): frame 2 dan akhir animasi sudah tercapai.
	var tol: float = Config.LEMPAR_TOLERANSI_DETIK
	var batas_tepat: bool = true
	var batas_kurang: bool = true
	for fps_batas: float in [1.0, 2.0, 4.0, 8.0, 12.0]:
		var tepat_akhir: LemparWaktu.Langkah = LemparWaktu.langkah(0.0, 4.0 / fps_batas - tol, fps_batas, 4, 2)
		var tepat_lepas: LemparWaktu.Langkah = LemparWaktu.langkah(0.0, 2.0 / fps_batas - tol, fps_batas, 4, 2)
		var kurang_akhir: LemparWaktu.Langkah = LemparWaktu.langkah(0.0, 4.0 / fps_batas - 2.0 * tol, fps_batas, 4, 2)
		var kurang_lepas: LemparWaktu.Langkah = LemparWaktu.langkah(0.0, 2.0 / fps_batas - 2.0 * tol, fps_batas, 4, 2)
		if not (tepat_akhir.selesai and tepat_akhir.frame == 3 and tepat_lepas.lepas and tepat_lepas.frame == 2):
			batas_tepat = false
		if kurang_akhir.selesai or kurang_lepas.lepas or kurang_akhir.frame != 3 or kurang_lepas.frame != 1:
			batas_kurang = false
	check(batas_tepat, "tepat di batas (posisi frame 2,0 dan 4,0): lepas dan selesai tercapai (inklusif), untuk fps 1, 2, 4, 8, 12")
	check(batas_kurang, "sedikit di bawah batas (2 x toleransi): belum lepas dan belum selesai")
	# dt besar melompati frame: lepas dan selesai tetap tepat sekali.
	var satu_lompat: LemparWaktu.Langkah = LemparWaktu.langkah(0.0, 1.0, 12.0, 4, 2)
	check(satu_lompat.lepas and satu_lompat.selesai and satu_lompat.frame == 3 and is_equal_approx(satu_lompat.waktu, 1.0 / 3.0) and satu_lompat.progres == 1.0, "satu dt 1 detik: lepas dan selesai pada langkah yang sama, frame 3, waktu dijepit ke durasi")
	var sangat_besar: LemparWaktu.Langkah = LemparWaktu.langkah(0.0, 1.0e300, 12.0, 4, 2)
	check(sangat_besar.lepas and sangat_besar.selesai and sangat_besar.frame == 3, "dt 1e300: lepas dan selesai, frame 3 (dijepit sebelum jadi int)")
	var lompat_lepas: LemparWaktu.Langkah = LemparWaktu.langkah(0.0, 0.2, 12.0, 4, 2)
	check(lompat_lepas.lepas and not lompat_lepas.selesai and lompat_lepas.frame == 2, "dt 0,2 dari awal (melewati frame 1): lepas, frame 2, belum selesai")
	# Setelah selesai, langkah berikutnya tidak melepas lagi.
	var lagi: LemparWaktu.Langkah = LemparWaktu.langkah(satu_lompat.waktu, 0.1, 12.0, 4, 2)
	check(not lagi.lepas and lagi.selesai and lagi.frame == 3, "langkah sesudah selesai: tidak lepas lagi, tetap selesai di frame 3")
	var sesudah_lepas: LemparWaktu.Langkah = LemparWaktu.langkah(lompat_lepas.waktu, 0.02, 12.0, 4, 2)
	check(not sesudah_lepas.lepas and sesudah_lepas.frame == 2, "langkah kecil sesudah lepas: tidak lepas lagi (satu kali)")
	# dt tidak sah tidak memajukan waktu.
	for dt_buruk: float in [0.0, -1.0, NAN, INF, -INF]:
		var diam: LemparWaktu.Langkah = LemparWaktu.langkah(0.05, dt_buruk, 12.0, 4, 2)
		check(is_equal_approx(diam.waktu, 0.05) and not diam.lepas and not diam.selesai and diam.frame == 0, "dt %s tidak memajukan waktu" % dt_buruk)
	var dari_awal: LemparWaktu.Langkah = LemparWaktu.langkah(NAN, 0.0, 12.0, 4, 2)
	check(dari_awal.waktu == 0.0 and dari_awal.frame == 0 and not dari_awal.selesai, "waktu awal NaN dianggap 0")
	var negatif: LemparWaktu.Langkah = LemparWaktu.langkah(-5.0, 0.0, 12.0, 4, 2)
	check(negatif.waktu == 0.0 and negatif.frame == 0, "waktu awal negatif dianggap 0")
	# fps atau jumlah frame tidak sah: langsung selesai tanpa melepas (tidak menggantung).
	for tidak_sah: Array in [[0.0, 4], [-1.0, 4], [NAN, 4], [INF, 4], [12.0, 0], [12.0, -3]]:
		var sia: LemparWaktu.Langkah = LemparWaktu.langkah(0.0, DT, tidak_sah[0], tidak_sah[1], 2)
		check(sia.selesai and not sia.lepas and sia.frame == 0, "fps %s dan %d frame tidak sah: langsung selesai tanpa lepas" % [tidak_sah[0], tidak_sah[1]])
	# frame_lepas di luar jangkauan: 0 diperlakukan 1 (frame 0 sudah tampil saat mulai), di atas frame terakhir tidak pernah lepas.
	var nol: LemparWaktu.Langkah = LemparWaktu.langkah(0.0, 1.0 / 12.0, 12.0, 4, 0)
	check(nol.lepas and nol.frame == 1, "frame_lepas 0 diperlakukan sebagai 1: lepas saat frame 1 tampil")
	var jauh: LemparWaktu.Langkah = LemparWaktu.langkah(0.0, 1.0, 12.0, 4, 9)
	check(not jauh.lepas and jauh.selesai, "frame_lepas 9 (di luar 4 frame) tidak pernah lepas, tetap selesai")
	# Sifat umum pada 200 putaran dengan dt acak (seed tetap): lepas tepat sekali, selesai tepat sekali, frame tidak mundur, waktu menaik dan <= durasi.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20261009
	var semua_sifat: bool = true
	var contoh_gagal: String = ""
	for putaran: int in range(200):
		var waktu: float = 0.0
		var jumlah_lepas: int = 0
		var jumlah_selesai: int = 0
		var frame_lalu: int = 0
		for langkah_ke: int in range(400):
			var dt: float = rng.randf_range(0.0, 0.08)
			var hasil: LemparWaktu.Langkah = LemparWaktu.langkah(waktu, dt, 12.0, 4, 2)
			if hasil.lepas:
				jumlah_lepas += 1
			if hasil.selesai:
				jumlah_selesai += 1
			if hasil.frame < frame_lalu or hasil.waktu < waktu or hasil.waktu > 1.0 / 3.0 + 0.000001:
				semua_sifat = false
				contoh_gagal = "putaran %d langkah %d" % [putaran, langkah_ke]
			frame_lalu = hasil.frame
			waktu = hasil.waktu
			if hasil.selesai:
				break
		if jumlah_lepas != 1 or jumlah_selesai != 1:
			semua_sifat = false
			contoh_gagal = "putaran %d: lepas %d selesai %d" % [putaran, jumlah_lepas, jumlah_selesai]
	check(semua_sifat, "200 putaran dt acak: lepas tepat sekali, selesai tepat sekali, frame tidak mundur, waktu menaik dan dijepit ke durasi (%s)" % contoh_gagal)


# --- AC-4: LoperSprite ---

## Pemain baru dari scene (belum masuk scene tree).
func _pemain_baru() -> LoperSprite:
	var paket: PackedScene = load(BERKAS_SCENE_PEMAIN) as PackedScene
	return paket.instantiate() as LoperSprite


## Menyambung sinyal `koran_lepas` dan `lempar_selesai` ke catatan: tiap entri [jenis, sisi atau animasi, frame saat sinyal].
func _catat(pemain: LoperSprite) -> Array:
	var catatan: Array = []
	pemain.koran_lepas.connect(func(sisi: LoperAnim.Sisi) -> void: catatan.append(["lepas", int(sisi), pemain.frame, pemain.animation]))
	pemain.lempar_selesai.connect(func() -> void: catatan.append(["selesai", -1, pemain.frame, pemain.animation]))
	return catatan


## Jumlah entri catatan berjenis `jenis`.
func _hitung(catatan: Array, jenis: String) -> int:
	var jumlah: int = 0
	for entri: Array in catatan:
		if entri[0] == jenis:
			jumlah += 1
	return jumlah


func _test_loper_sprite_tingkat() -> void:
	_judul.call("LoperSprite: tingkat melambat (AC-4)")
	var pemain: LoperSprite = _pemain_baru()
	var frames: SpriteFrames = pemain.sprite_frames
	check(frames != null and pemain.speed_level == 0 and pemain.animation == &"santai_normal", "pemain mulai santai_normal")
	pemain.speed_level = -1
	check(pemain.speed_level == -1 and pemain.animation == &"melambat_normal", "speed_level -1 memilih melambat_normal, dapat '%s'" % pemain.animation)
	check(is_equal_approx(frames.get_animation_speed(pemain.animation), 4.0), "animasi melambat berkecepatan 4 fps (santai 8 fps)")
	for arah: int in range(-2, 3):
		pemain.steer = arah
		check(pemain.animation == LoperAnim.nama_animasi(-1, arah) and String(pemain.animation).begins_with("melambat_"), "melambat arah %d memilih '%s'" % [arah, LoperAnim.nama_animasi(-1, arah)])
	pemain.speed_level = -9
	check(pemain.speed_level == -1, "speed_level -9 dijepit ke -1 (melambat)")
	pemain.speed_level = 9
	check(pemain.speed_level == 2, "speed_level 9 tetap dijepit ke 2 (ngebut)")
	# Fase kayuh dijaga saat berganti dari santai ke melambat dan sebaliknya.
	pemain.steer = 0
	pemain.speed_level = 0
	pemain.set_frame_and_progress(2, 0.4)
	pemain.speed_level = -1
	check(pemain.animation == &"melambat_normal" and pemain.frame == 2 and is_equal_approx(pemain.frame_progress, 0.4), "santai -> melambat menjaga frame (2) dan progres (0,4) kayuh")
	pemain.speed_level = 0
	check(pemain.animation == &"santai_normal" and pemain.frame == 2 and is_equal_approx(pemain.frame_progress, 0.4), "melambat -> santai menjaga frame dan progres")
	pemain.free()


## Jatuh di `LoperSprite` (keputusan pemilik 2026-10-17): frame dari lama sejak tabrakan untuk semua arah, lempar ditolak dan lempar berjalan
## ditutup, pose/tingkat/arah tersimpan tanpa mengganti gambar, bangun kembali ke animasi pose saat itu dan diputar lagi.
func _test_loper_sprite_jatuh() -> void:
	_judul.call("LoperSprite: jatuh, terjerembab, lalu bangkit per arah, kembali ke kayuh sesudahnya (pemilik 2026-10-17, Fase 5C)")
	var pemain: LoperSprite = _pemain_baru()
	# Jatuh 4 frame 10 fps (0-0,4), terjerembab 3 fps (0,4-0,6), bangkit 6 frame 10 fps di 0,6 detik terakhir jatuh 1,2 detik.
	var kasus: Array = [[0.0, "jatuh", 0], [0.15, "jatuh", 1], [0.35, "jatuh", 3], [0.4, "terjerembab", 0], [0.55, "terjerembab", 0], [0.6, "bangkit", 0], [0.8, "bangkit", 2], [1.15, "bangkit", 5]]
	var semua: bool = true
	var beda: Array[String] = []
	for arah: int in range(-2, 3):
		pemain.steer = arah
		for k: Array in kasus:
			pemain.atur_jatuh(true, k[0])
			var harapan: StringName = StringName("%s_%s" % [k[1], LoperAnim.NAMA_ARAH[arah]])
			if pemain.animation != harapan or pemain.frame != k[2] or pemain.is_playing() or not pemain.sedang_jatuh():
				semua = false
				beda.append("arah %d t %.2f: %s f%d" % [arah, k[0], pemain.animation, pemain.frame])
	check(semua, "5 arah x 8 saat: jatuh_<arah>/terjerembab_<arah>/bangkit_<arah> dengan frame dari waktu, sprite dijeda; beda: %s" % [beda])
	pemain.atur_jatuh(true, 0.2)
	pemain.speed_level = 2
	pemain.steer = 1
	pemain.pose = LoperAnim.Pose.REM
	check(pemain.animation == &"jatuh_kanan" and pemain.frame == 2, "selama jatuh (masuk di arah kanan) mengubah pose, tingkat, dan arah tidak mengganti gambar, dapat %s" % pemain.animation)
	check(not pemain.lempar(LoperAnim.Sisi.DEKAT) and not pemain.sedang_melempar(), "lempar ditolak selama jatuh")
	pemain.pose = LoperAnim.Pose.KAYUH
	pemain.atur_jatuh(false, 0.0)
	check(not pemain.sedang_jatuh() and pemain.animation == &"ngebut_serong_kanan" and pemain.is_playing(), "bangun: langsung ke animasi kayuh pose saat itu (ngebut_serong_kanan) dan diputar, dapat %s" % pemain.animation)
	pemain.atur_jatuh(false, 0.0)
	check(pemain.animation == &"ngebut_serong_kanan", "atur_jatuh(false) saat tidak jatuh tidak mengubah apa pun")
	# Lempar yang berjalan ditutup saat jatuh, tanpa sinyal.
	var sinyal: Array[String] = []
	pemain.koran_lepas.connect(func(_s: LoperAnim.Sisi) -> void: sinyal.append("lepas"))
	pemain.lempar_selesai.connect(func() -> void: sinyal.append("selesai"))
	check(pemain.lempar(LoperAnim.Sisi.SEBERANG), "kontrol: lempar dimulai sebelum jatuh")
	pemain.atur_jatuh(true, 0.0)
	check(not pemain.sedang_melempar() and pemain.animation == LoperAnim.nama_jatuh(pemain.steer) and sinyal.is_empty(), "jatuh menutup lempar yang berjalan tanpa koran_lepas/lempar_selesai (jatuh_<arah>, dapat %s)" % pemain.animation)
	pemain.free()


## Pose meluncur dan rem di `LoperSprite` (D-7 run fase1a-gerak): nama animasi, fps, frame dijaga, lempar dari pose memakai santai.
func _test_loper_sprite_pose() -> void:
	_judul.call("LoperSprite: pose meluncur dan rem (AC-6 run fase1a-gerak)")
	var pemain: LoperSprite = _pemain_baru()
	var frames: SpriteFrames = pemain.sprite_frames
	check(pemain.pose == LoperAnim.Pose.KAYUH, "pose bawaan = kayuh")
	for pose: LoperAnim.Pose in [LoperAnim.Pose.MELUNCUR, LoperAnim.Pose.REM]:
		pemain.pose = pose
		for tingkat: int in range(LoperAnim.TINGKAT_MELAMBAT, 3):
			pemain.speed_level = tingkat
			for arah: int in range(-2, 3):
				pemain.steer = arah
				var harapan: StringName = LoperAnim.nama_animasi_pose(pose, tingkat, arah)
				check(pemain.animation == harapan and frames.has_animation(harapan), "pose %d tingkat %d arah %d memilih '%s' (tingkat diabaikan), dapat '%s'" % [pose, tingkat, arah, harapan, pemain.animation])
	pemain.speed_level = 0
	pemain.steer = 0
	pemain.pose = LoperAnim.Pose.MELUNCUR
	check(pemain.animation == &"meluncur_normal" and is_equal_approx(frames.get_animation_speed(pemain.animation), 4.0), "meluncur_normal 4 fps")
	pemain.pose = LoperAnim.Pose.REM
	check(pemain.animation == &"rem_normal" and is_equal_approx(frames.get_animation_speed(pemain.animation), 8.0), "rem_normal 8 fps")
	pemain.pose = LoperAnim.Pose.KAYUH
	check(pemain.animation == &"santai_normal", "kembali ke pose kayuh: santai_normal")
	# Frame dijaga saat berganti kayuh <-> meluncur <-> rem (keempatnya 4 frame).
	pemain.set_frame_and_progress(3, 0.25)
	pemain.pose = LoperAnim.Pose.MELUNCUR
	check(pemain.animation == &"meluncur_normal" and pemain.frame == 3 and is_equal_approx(pemain.frame_progress, 0.25), "kayuh -> meluncur menjaga frame 3 dan progres 0,25")
	pemain.pose = LoperAnim.Pose.REM
	check(pemain.animation == &"rem_normal" and pemain.frame == 3, "meluncur -> rem menjaga frame")
	# Lempar dari rem dan meluncur memakai santai, apa pun tingkatnya; sesudah lempar kembali ke pose.
	pemain.speed_level = 2
	check(pemain.lempar(LoperAnim.Sisi.DEKAT) and pemain.animation == &"lempar_kanan_santai_normal", "lempar dari rem (tingkat ngebut tersimpan) memakai santai: lempar_kanan_santai_normal, dapat %s" % pemain.animation)
	pemain.batalkan_lempar()
	check(pemain.animation == &"rem_normal", "lempar ditutup: kembali ke rem_normal")
	pemain.pose = LoperAnim.Pose.MELUNCUR
	pemain.steer = -1
	check(pemain.lempar(LoperAnim.Sisi.SEBERANG) and pemain.animation == &"lempar_kiri_santai_serong_kiri", "lempar dari meluncur serong seberang: lempar_kiri_santai_serong_kiri, dapat %s" % pemain.animation)
	pemain.batalkan_lempar()
	pemain.pose = LoperAnim.Pose.KAYUH
	check(pemain.lempar(LoperAnim.Sisi.SEBERANG) and pemain.animation == &"lempar_kiri_ngebut_serong_kiri", "kontrol: dari kayuh ngebut, lempar tetap ngebut")
	pemain.batalkan_lempar()
	pemain.free()


func _test_loper_sprite_lempar() -> void:
	_judul.call("LoperSprite: lempar sekali, sinyal, kembali ke kayuh (AC-4, D-3, D-4, D-5)")
	var pemain: LoperSprite = _pemain_baru()
	var catatan: Array = _catat(pemain)
	pemain.speed_level = 1
	pemain.steer = 1
	check(not pemain.sedang_melempar(), "awalnya tidak sedang melempar")
	check(pemain.lempar(LoperAnim.Sisi.DEKAT), "lempar(DEKAT) dimulai (true)")
	check(pemain.sedang_melempar() and pemain.animation == &"lempar_kanan_cepat_serong_kanan", "memainkan lempar_kanan_cepat_serong_kanan (sisi dekat, cepat, serong dekat), dapat '%s'" % pemain.animation)
	check(pemain.frame == 0 and not pemain.is_playing() and not pemain.sprite_frames.get_animation_loop(pemain.animation), "mulai di frame 0, tidak diputar pemutar bawaan, animasi tidak loop")
	check(catatan.is_empty(), "tidak ada sinyal saat lempar baru dimulai")
	# Langkah demi langkah dengan dt tetap 1/60: frame berganti tiap 5 langkah, koran lepas di langkah 10 (frame 2), selesai di langkah 20.
	var urutan_frame: Array[int] = []
	var nama_dalam: bool = true
	for langkah: int in range(1, 20):
		pemain.maju(DT)
		urutan_frame.append(pemain.frame)
		if pemain.animation != &"lempar_kanan_cepat_serong_kanan":
			nama_dalam = false
		if langkah == 3:
			# Perubahan tingkat dan arah di tengah lempar disimpan, tidak mengganti gambar (D-4). Sejak run fase2a-lemparan (D-9) lempar
			# kedua tidak lagi ditolak sprite (penolakan pindah ke jeda antar lempar `SisaKoran`); perilaku menyela dites di
			# `_test_loper_sprite_lempar_menyela`.
			pemain.speed_level = 2
			pemain.steer = -1
			check(pemain.animation == &"lempar_kanan_cepat_serong_kanan" and pemain.speed_level == 2 and pemain.steer == -1, "speed_level dan steer berubah di tengah lempar: tersimpan, gambar lempar tidak berganti")
		if langkah == 9:
			check(_hitung(catatan, "lepas") == 0, "sampai langkah 9 (frame 1) koran belum lepas")
		if langkah == 10:
			check(_hitung(catatan, "lepas") == 1 and pemain.frame == 2, "langkah 10: koran_lepas tepat sekali saat frame 2 tampil")
	check(nama_dalam, "selama 19 langkah animasi tetap lempar_kanan_cepat_serong_kanan")
	check(urutan_frame.slice(0, 4) == [0, 0, 0, 0] and urutan_frame[4] == 1 and urutan_frame[8] == 1 and urutan_frame[9] == 2 and urutan_frame[13] == 2 and urutan_frame[14] == 3 and urutan_frame[18] == 3, "frame 0 langkah 1-4, frame 1 langkah 5-9, frame 2 langkah 10-14, frame 3 langkah 15-19")
	check(pemain.sedang_melempar() and _hitung(catatan, "selesai") == 0, "sampai langkah 19 masih melempar, belum selesai")
	pemain.maju(DT)
	check(not pemain.sedang_melempar() and _hitung(catatan, "selesai") == 1, "langkah 20: lempar_selesai tepat sekali")
	check(pemain.animation == &"ngebut_serong_kiri" and pemain.is_playing(), "sprite kembali ke kayuh dengan tingkat dan arah TERKINI (ngebut_serong_kiri, bukan cepat_serong_kanan dari saat mulai) dan berputar lagi, dapat '%s'" % pemain.animation)
	check(pemain.frame == 0 and pemain.frame_progress == 0.0, "indeks frame dilanjutkan dari frame lempar terakhir (3, progres penuh): kayuh melanjutkan ke frame 0 (kaki lanjut ke fase berikutnya), dapat frame %d progres %s" % [pemain.frame, pemain.frame_progress])
	check(catatan.size() == 2 and catatan[0][0] == "lepas" and catatan[1][0] == "selesai", "urutan sinyal: koran_lepas lalu lempar_selesai, masing-masing sekali (%d entri)" % catatan.size())
	check(catatan[0][1] == int(LoperAnim.Sisi.DEKAT) and catatan[0][2] == 2 and catatan[0][3] == &"lempar_kanan_cepat_serong_kanan", "koran_lepas membawa sisi DEKAT, frame 2, dan animasi lempar saat dipancarkan")
	check(String(catatan[1][3]) == "ngebut_serong_kiri", "lempar_selesai dipancarkan sesudah sprite kembali ke kayuh (animasi '%s')" % catatan[1][3])
	for i: int in range(40):
		pemain.maju(DT)
	check(catatan.size() == 2 and pemain.animation == &"ngebut_serong_kiri", "sesudah selesai, maju tidak memancarkan sinyal lagi dan tidak mengganti animasi")
	# Setelah selesai lempar baru boleh lagi, mulai dari frame 0, sisi seberang.
	check(pemain.lempar(LoperAnim.Sisi.SEBERANG) and pemain.animation == &"lempar_kiri_ngebut_serong_kiri" and pemain.frame == 0, "lempar berikutnya sesudah selesai dimulai dari frame 0: lempar_kiri_ngebut_serong_kiri")
	for i: int in range(20):
		pemain.maju(DT)
	check(catatan.size() == 4 and catatan[2][1] == int(LoperAnim.Sisi.SEBERANG) and catatan[3][0] == "selesai", "lempar kedua juga memancarkan koran_lepas (SEBERANG) dan lempar_selesai tepat sekali")
	pemain.free()


## D-9 run fase2a-lemparan: sprite tidak lagi menolak lempar sendiri. Lempar baru saat lempar lama masih berjalan menutup lempar lama
## dulu (koran_lepas yang belum terjadi dipancarkan sekali, lalu lempar_selesai), lalu mulai dari frame 0: tiap lempar tetap memancarkan
## koran_lepas dan lempar_selesai tepat sekali, animasi tidak rusak. `jeda_lepas` = waktu frame lepas animasi yang akan dipakai.
func _test_loper_sprite_lempar_menyela() -> void:
	_judul.call("LoperSprite: lempar menyela lempar yang berjalan (D-9 run fase2a-lemparan)")
	var pemain: LoperSprite = _pemain_baru()
	var catatan: Array = _catat(pemain)
	check(is_equal_approx(pemain.jeda_lepas(LoperAnim.Sisi.DEKAT), 2.0 / 12.0) and is_equal_approx(pemain.jeda_lepas(LoperAnim.Sisi.SEBERANG), 2.0 / 12.0), "jeda lepas = frame lepas 2 di 12 fps (LemparWaktu.waktu_lepas), dapat %s" % pemain.jeda_lepas(LoperAnim.Sisi.DEKAT))
	check(pemain.jeda_lepas(LoperAnim.Sisi.TIDAK_ADA) == 0.0, "jeda lepas sisi kosong = 0")
	# (a) Menyela SEBELUM frame lepas: koran_lepas lama dipancarkan saat disela.
	check(pemain.lempar(LoperAnim.Sisi.DEKAT), "lempar pertama (dekat) dimulai")
	for i: int in range(3):
		pemain.maju(DT)
	check(_hitung(catatan, "lepas") == 0, "3 langkah: belum lepas")
	check(pemain.lempar(LoperAnim.Sisi.SEBERANG), "lempar kedua (seberang) saat lempar pertama berjalan: dimulai (true), tidak ditolak sprite")
	check(catatan.size() == 2 and catatan[0][0] == "lepas" and catatan[0][1] == int(LoperAnim.Sisi.DEKAT) and catatan[1][0] == "selesai", "lempar pertama ditutup dengan koran_lepas (dekat) lalu lempar_selesai, masing-masing sekali, dapat %s" % [catatan])
	check(pemain.sedang_melempar() and pemain.animation == &"lempar_kiri_santai_normal" and pemain.frame == 0 and not pemain.is_playing(), "lempar kedua mulai dari frame 0 (lempar_kiri_santai_normal), tidak diputar pemutar bawaan")
	for i: int in range(20):
		pemain.maju(DT)
	check(catatan.size() == 4 and catatan[2][0] == "lepas" and catatan[2][1] == int(LoperAnim.Sisi.SEBERANG) and catatan[2][2] == 2 and catatan[3][0] == "selesai", "lempar kedua: koran_lepas (seberang) di frame 2 lalu lempar_selesai, masing-masing sekali")
	check(not pemain.sedang_melempar() and pemain.animation == &"santai_normal" and pemain.is_playing(), "sesudah lempar kedua kembali ke santai_normal yang berputar")
	# (b) Menyela SESUDAH frame lepas: koran_lepas lama TIDAK dipancarkan dua kali.
	catatan.clear()
	pemain.lempar(LoperAnim.Sisi.DEKAT)
	for i: int in range(12):
		pemain.maju(DT)
	check(_hitung(catatan, "lepas") == 1 and pemain.sedang_melempar(), "12 langkah: koran sudah lepas sekali, masih melempar")
	check(pemain.lempar(LoperAnim.Sisi.DEKAT), "lempar baru sesudah frame lepas dimulai")
	check(_hitung(catatan, "lepas") == 1 and _hitung(catatan, "selesai") == 1, "koran_lepas lama tidak diulang; lempar_selesai lama sekali")
	for i: int in range(20):
		pemain.maju(DT)
	check(_hitung(catatan, "lepas") == 2 and _hitung(catatan, "selesai") == 2, "dua lempar = 2 koran_lepas dan 2 lempar_selesai")
	# (c) batalkan_lempar tetap tanpa sinyal (jeda game, D-11), dan lempar sesudahnya normal.
	catatan.clear()
	pemain.lempar(LoperAnim.Sisi.SEBERANG)
	pemain.maju(DT)
	pemain.batalkan_lempar()
	check(catatan.is_empty() and not pemain.sedang_melempar(), "batalkan_lempar menutup tanpa sinyal")
	pemain.lempar(LoperAnim.Sisi.SEBERANG)
	for i: int in range(20):
		pemain.maju(DT)
	check(_hitung(catatan, "lepas") == 1 and _hitung(catatan, "selesai") == 1, "lempar sesudah batal memancarkan sinyalnya sekali (penanda lepas direset saat batal)")
	pemain.free()


## Semua kombinasi sisi x tingkat (melambat sampai ngebut) x arah (-2 sampai 2): animasi benar, sekali putar, sinyal sekali.
func _test_loper_sprite_lempar_semua_kombinasi() -> void:
	_judul.call("LoperSprite: lempar untuk semua kombinasi")
	var pemain: LoperSprite = _pemain_baru()
	var catatan: Array = _catat(pemain)
	var jumlah: int = 0
	var salah: Array[String] = []
	for sisi: LoperAnim.Sisi in [LoperAnim.Sisi.SEBERANG, LoperAnim.Sisi.DEKAT]:
		for tingkat: int in range(LoperAnim.TINGKAT_MELAMBAT, 3):
			for arah: int in range(-2, 3):
				pemain.speed_level = tingkat
				pemain.steer = arah
				var nama: StringName = LoperAnim.nama_lempar(sisi, tingkat, arah)
				var sebelum: int = catatan.size()
				var mulai: bool = pemain.lempar(sisi)
				var benar_nama: bool = pemain.animation == nama
				var langkah_selesai: int = 0
				for langkah: int in range(1, 40):
					pemain.maju(DT)
					if not pemain.sedang_melempar():
						langkah_selesai = langkah
						break
				var baru: Array = catatan.slice(sebelum)
				var urut_benar: bool = baru.size() == 2 and baru[0][0] == "lepas" and baru[0][1] == int(sisi) and baru[0][2] == 2 and baru[0][3] == nama and baru[1][0] == "selesai"
				var kayuh_benar: bool = pemain.animation == LoperAnim.nama_animasi(tingkat, arah) and pemain.is_playing()
				jumlah += 1
				if not (mulai and benar_nama and langkah_selesai == 20 and urut_benar and kayuh_benar):
					salah.append("sisi %d tingkat %d arah %d (mulai %s nama %s selesai di %d urut %s kayuh %s)" % [sisi, tingkat, arah, mulai, benar_nama, langkah_selesai, urut_benar, kayuh_benar])
	check(jumlah == 40, "40 kombinasi dicoba (2 sisi x 4 tingkat x 5 arah), dapat %d" % jumlah)
	check(salah.is_empty(), "tiap kombinasi: animasi lempar benar, selesai tepat di langkah 20, koran_lepas sekali (frame 2, sisi benar) lalu lempar_selesai sekali, kembali ke kayuh; salah: %s" % "; ".join(salah))
	pemain.free()


func _test_loper_sprite_lempar_tepi() -> void:
	_judul.call("LoperSprite: tepi (sisi kosong, dt tidak sah, dt besar, batal, re-entrancy, pedal_rate)")
	var node: LoperSprite = _pemain_baru()
	var catatan: Array = _catat(node)
	# Lempar selalu mulai dari frame 0, progres 0, apa pun fase kayuh saat swipe dilepas.
	node.set_frame_and_progress(2, 0.5)
	node.lempar(LoperAnim.Sisi.DEKAT)
	check(node.frame == 0 and node.frame_progress == 0.0, "lempar dimulai dari frame 0 progres 0 walau kayuh sedang di frame 2 progres 0,5, dapat frame %d progres %s" % [node.frame, node.frame_progress])
	node.batalkan_lempar()
	catatan.clear()
	# Sisi kosong atau tidak dikenal tidak melempar.
	check(not node.lempar(LoperAnim.Sisi.TIDAK_ADA) and not node.sedang_melempar() and node.animation == &"santai_normal", "lempar(TIDAK_ADA) tidak melakukan apa pun")
	check(not node.lempar(7 as LoperAnim.Sisi) and not node.sedang_melempar(), "lempar dengan nilai sisi tak dikenal tidak melakukan apa pun")
	# maju tanpa lempar tidak memicu apa pun.
	node.maju(5.0)
	check(catatan.is_empty() and node.animation == &"santai_normal", "maju(5) saat tidak melempar tidak melakukan apa pun")
	# dt nol, negatif, NaN, tak hingga tidak memajukan.
	node.lempar(LoperAnim.Sisi.SEBERANG)
	for dt_buruk: float in [0.0, -1.0, NAN, INF]:
		node.maju(dt_buruk)
	check(node.sedang_melempar() and node.frame == 0 and catatan.is_empty(), "dt 0, -1, NaN, tak hingga tidak memajukan lempar (masih frame 0, tanpa sinyal)")
	# Satu dt besar: koran_lepas lalu lempar_selesai pada panggilan yang sama, masing-masing sekali.
	node.maju(10.0)
	check(not node.sedang_melempar() and catatan.size() == 2 and catatan[0][0] == "lepas" and catatan[1][0] == "selesai", "satu maju(10) menghasilkan koran_lepas lalu lempar_selesai, sekali masing-masing")
	check(node.animation == &"santai_normal" and node.is_playing(), "dan kembali ke santai_normal yang berputar")
	catatan.clear()
	# Batal sebelum lepas: tidak ada koran_lepas, tidak ada lempar_selesai.
	node.lempar(LoperAnim.Sisi.DEKAT)
	for i: int in range(6):
		node.maju(DT)
	node.batalkan_lempar()
	check(node.animation == &"santai_normal" and node.frame == 1 and absf(node.frame_progress - 0.2) < 0.001, "batalkan_lempar 6 langkah (frame 1, progres 0,2): kayuh melanjutkan dari frame dan progres yang sama, dapat frame %d progres %s" % [node.frame, node.frame_progress])
	for i: int in range(40):
		node.maju(DT)
	check(not node.sedang_melempar() and catatan.is_empty() and node.animation == &"santai_normal" and node.is_playing(), "batalkan_lempar sebelum lepas: tanpa koran_lepas dan tanpa lempar_selesai, kembali ke kayuh yang berputar")
	# Batal sesudah lepas: koran_lepas yang sudah terjadi tetap sekali, tidak ada lempar_selesai.
	node.lempar(LoperAnim.Sisi.DEKAT)
	for i: int in range(12):
		node.maju(DT)
	node.batalkan_lempar()
	for i: int in range(40):
		node.maju(DT)
	check(_hitung(catatan, "lepas") == 1 and _hitung(catatan, "selesai") == 0 and not node.sedang_melempar(), "batalkan_lempar sesudah lepas: koran_lepas tetap sekali, lempar_selesai tidak dipancarkan")
	node.batalkan_lempar()
	check(not node.sedang_melempar() and catatan.size() == 1, "batalkan_lempar saat tidak melempar tidak melakukan apa pun")
	# Re-entrancy: pendengar koran_lepas membatalkan lempar -> lempar_selesai tidak dipancarkan.
	var node2: LoperSprite = _pemain_baru()
	var catatan2: Array = []
	node2.koran_lepas.connect(func(_sisi: LoperAnim.Sisi) -> void:
		catatan2.append("lepas")
		node2.batalkan_lempar())
	node2.lempar_selesai.connect(func() -> void: catatan2.append("selesai"))
	node2.lempar(LoperAnim.Sisi.DEKAT)
	node2.maju(10.0)
	check(catatan2 == ["lepas"] and not node2.sedang_melempar(), "pendengar koran_lepas yang membatalkan lempar mencegah lempar_selesai (tidak ada sinyal ganda)")
	node2.free()
	# Re-entrancy: pendengar lempar_selesai langsung melempar lagi -> berhasil karena keadaan sudah dibersihkan sebelum sinyal.
	var node3: LoperSprite = _pemain_baru()
	var hitung3: Array[int] = [0, 0]
	node3.koran_lepas.connect(func(_sisi: LoperAnim.Sisi) -> void: hitung3[0] += 1)
	node3.lempar_selesai.connect(func() -> void:
		hitung3[1] += 1
		if hitung3[1] == 1:
			node3.lempar(LoperAnim.Sisi.SEBERANG))
	node3.lempar(LoperAnim.Sisi.DEKAT)
	node3.maju(10.0)
	check(node3.sedang_melempar() and node3.animation == &"lempar_kiri_santai_normal" and hitung3 == [1, 1], "pendengar lempar_selesai boleh langsung melempar lagi (lempar berantai) tanpa sinyal ganda")
	node3.maju(10.0)
	check(not node3.sedang_melempar() and hitung3 == [2, 2], "lempar berantai selesai: total 2 koran_lepas dan 2 lempar_selesai")
	node3.free()
	# Lempar tidak bergantung pada laju kayuh: pedal_rate 0 tidak membekukan lempar.
	var node4: LoperSprite = _pemain_baru()
	var catatan4: Array = _catat(node4)
	node4.pedal_rate = 0.0
	node4.lempar(LoperAnim.Sisi.DEKAT)
	for i: int in range(20):
		node4.maju(DT)
	check(catatan4.size() == 2 and not node4.sedang_melempar(), "pedal_rate 0 tidak membekukan lempar: selesai di langkah 20 dengan dua sinyal")
	check(node4.speed_scale == 0.0, "speed_scale kayuh tetap mengikuti pedal_rate (0) sesudah lempar")
	node4.free()
	node.free()


func _test_loper_sprite_di_tree() -> void:
	_judul.call("LoperSprite: di scene tree (proses hanya saat melempar, delta dijepit)")
	var root: Window = _tree.root
	var pemain: LoperSprite = _pemain_baru()
	var catatan: Array = _catat(pemain)
	root.add_child(pemain)
	check(pemain.is_playing() and not pemain.is_processing(), "di scene tree animasi kayuh berjalan dan _process mati saat tidak melempar (tanpa biaya per frame)")
	pemain.speed_level = 2
	check(pemain.lempar(LoperAnim.Sisi.SEBERANG), "lempar di dalam scene tree dimulai")
	check(pemain.is_processing() and not pemain.is_playing(), "selama melempar _process menyala dan pemutar bawaan berhenti")
	# Delta besar (kembali dari background) dijepit ke LANGKAH_WAKTU_MAKS_DETIK = 0,1 detik: baru frame 1, belum lepas.
	pemain._process(5.0)
	check(pemain.sedang_melempar() and pemain.frame == 1 and catatan.is_empty(), "_process(5,0) hanya memajukan %s detik (frame 1), tidak langsung selesai" % Config.LANGKAH_WAKTU_MAKS_DETIK)
	pemain._process(5.0)
	check(pemain.sedang_melempar() and pemain.frame == 2 and _hitung(catatan, "lepas") == 1, "_process(5,0) kedua: 0,2 detik, frame 2, koran_lepas sekali, belum selesai")
	pemain._process(5.0)
	check(pemain.sedang_melempar() and pemain.frame == 3 and _hitung(catatan, "lepas") == 1 and _hitung(catatan, "selesai") == 0, "_process(5,0) ketiga: 0,3 detik, frame 3, belum selesai (durasi 0,333 detik)")
	pemain._process(5.0)
	check(not pemain.sedang_melempar() and _hitung(catatan, "selesai") == 1 and not pemain.is_processing() and pemain.is_playing() and pemain.animation == &"ngebut_normal", "_process(5,0) keempat: 0,4 detik, selesai, _process mati lagi, kembali ke ngebut_normal yang berputar")
	# Notifikasi app di-background dibatalkan oleh pemilik (JalanUji); node sendiri aman bila dikeluarkan dari tree saat melempar.
	pemain.lempar(LoperAnim.Sisi.DEKAT)
	root.remove_child(pemain)
	pemain.maju(DT)
	check(pemain.sedang_melempar(), "node yang dikeluarkan dari tree tidak error dan lempar tetap bisa dimajukan manual")
	pemain.free()
	# Memanggil lempar dan maju pada node yang belum pernah masuk tree tidak menghasilkan ERROR/WARNING (keluaran dicek pemeriksa).
	var luar: LoperSprite = _pemain_baru()
	check(luar.lempar(LoperAnim.Sisi.DEKAT) and not luar.is_inside_tree(), "lempar di luar scene tree berhasil")
	luar.maju(1.0)
	check(not luar.sedang_melempar(), "maju di luar scene tree menyelesaikan lempar")
	luar.free()


## Q-001 (run 0A): `sprite_frames` null aman, dan frames yang dipasang kemudian diterapkan.
func _test_loper_sprite_tanpa_frames() -> void:
	_judul.call("LoperSprite: sprite_frames kosong (Q-001)")
	var root: Window = _tree.root
	var frames: SpriteFrames = load(BERKAS_FRAMES) as SpriteFrames
	# (a) LoperSprite.new() tanpa frames masuk tree: dulu ERROR 'There is no animation with name default'.
	var kosong: LoperSprite = LoperSprite.new()
	root.add_child(kosong)
	check(kosong.is_inside_tree() and not kosong.is_playing() and not kosong.is_processing(), "LoperSprite tanpa sprite_frames masuk tree tanpa error dan tidak berputar")
	check(not kosong.lempar(LoperAnim.Sisi.DEKAT) and not kosong.sedang_melempar(), "lempar tanpa sprite_frames mengembalikan false")
	kosong.maju(1.0)
	kosong.batalkan_lempar()
	kosong.speed_level = 2
	kosong.steer = -2
	kosong.pedal_rate = 1.5
	check(not kosong.is_playing() and kosong.speed_level == 2 and kosong.steer == -2, "mengubah speed_level, steer, pedal_rate, maju, dan batal tanpa sprite_frames aman")
	# Frames dipasang kemudian: animasi sesuai tingkat/arah yang diubah selama kosong, dan berputar.
	kosong.sprite_frames = frames
	check(kosong.animation == &"ngebut_kiri" and kosong.is_playing(), "frames dipasang sesudah speed_level/steer diubah: animasi ngebut_kiri diterapkan dan berputar, dapat '%s' playing %s" % [kosong.animation, kosong.is_playing()])
	root.remove_child(kosong)
	kosong.free()
	# (b) Skenario repro 0A: frames dicopot lalu dipasang lagi di tengah perubahan tingkat.
	var p: LoperSprite = _pemain_baru()
	p.speed_level = 2
	p.steer = -2
	root.add_child(p)
	p.sprite_frames = null
	p.speed_level = 1
	check(not p.is_playing(), "frames dicopot: tidak berputar")
	p.sprite_frames = frames
	check(p.animation == &"cepat_kiri" and p.is_playing(), "frames dipasang lagi: animasi mengikuti speed_level 1 (cepat_kiri) dan berputar lagi (repro Q-001b), dapat '%s' playing %s" % [p.animation, p.is_playing()])
	# (c) Frames dicopot di tengah lempar: lempar dibatalkan tanpa sinyal, tidak menggantung.
	var catatan: Array = _catat(p)
	p.lempar(LoperAnim.Sisi.DEKAT)
	for i: int in range(3):
		p.maju(DT)
	p.sprite_frames = null
	check(not p.sedang_melempar() and not p.is_processing() and catatan.is_empty(), "frames dicopot saat melempar: lempar berakhir tanpa sinyal dan _process mati")
	p.maju(1.0)
	p.sprite_frames = frames
	check(p.animation == &"cepat_kiri" and p.is_playing() and catatan.is_empty(), "frames dipasang lagi sesudahnya: kayuh berputar, tidak ada sinyal sisa")
	# (d) Frames diganti SpriteFrames lain tanpa animasi lempar: lempar ditolak (warning hanya untuk animasi kayuh yang hilang, jadi tidak diuji di sini).
	root.remove_child(p)
	p.free()


# --- AC-8: titik pijak sama (sprite tidak melompat saat berganti animasi) ---

## Baris piksel terbawah yang tidak transparan dalam sel (kolom `frame`, baris `baris`) dan himpunan piksel tidak transparan
## di tiga baris terbawahnya (tapak roda dan bayangan). -1 bila sel kosong.
func _alas(gambar: Image, frame: int, baris: int) -> Array:
	var x0: int = frame * SEL.x
	var y0: int = baris * SEL.y
	var bawah: int = -1
	for y: int in range(SEL.y - 1, -1, -1):
		for x: int in range(SEL.x):
			if gambar.get_pixel(x0 + x, y0 + y).a > 0.0:
				bawah = y
				break
		if bawah >= 0:
			break
	var tapak: Array[Vector2i] = []
	for y: int in range(bawah - 2, bawah + 1):
		for x: int in range(SEL.x):
			if y >= 0 and gambar.get_pixel(x0 + x, y0 + y).a > 0.0:
				tapak.append(Vector2i(x, y))
	return [bawah, tapak]


## Alas (baris terbawah dan tapak tiga baris terbawah) tiap frame lempar sama dengan frame kayuh sumbernya (`source_row`), dan
## frame melambat identik piksel demi piksel dengan santai. Sel, titik pijak (23, 46), dan offset sama untuk ketiga sheet
## (dites di AC-2). Jadi gambar sprite tidak bergeser vertikal maupun horizontal di alas saat kayuh -> lempar -> kayuh.
func _test_titik_pijak_sama() -> void:
	_judul.call("Titik pijak sama: kayuh, melambat, lempar, meluncur, rem (AC-8, AC-13 run fase1a-gerak)")
	var kayuh: Image = (load(FOLDER_ASET + "loper_agen.png") as Texture2D).get_image()
	var melambat: Image = (load(FOLDER_ASET + "loper_agen_melambat.png") as Texture2D).get_image()
	var lempar: Image = (load(FOLDER_ASET + "loper_agen_lempar.png") as Texture2D).get_image()
	var json: Dictionary = _baca_json("loper_agen_lempar.json")
	var frame_dicek: int = 0
	var alas_beda: Array[String] = []
	var tapak_beda: Array[String] = []
	var alas_terukur: Dictionary = {}
	for entri: Dictionary in json.get("animations", []):
		for frame: int in range(4):
			var a_lempar: Array = _alas(lempar, frame, int(entri["row"]))
			var a_kayuh: Array = _alas(kayuh, frame, int(entri["source_row"]))
			frame_dicek += 1
			alas_terukur[String(entri["heading"])] = a_kayuh[0]
			if a_lempar[0] != a_kayuh[0] or a_lempar[0] < 0:
				alas_beda.append("%s f%d (%d lawan %d)" % [entri["name"], frame, a_lempar[0], a_kayuh[0]])
			if a_lempar[1] != a_kayuh[1]:
				tapak_beda.append("%s f%d" % [entri["name"], frame])
	check(frame_dicek == 72, "72 frame lempar dibandingkan dengan frame kayuh sumbernya (18 animasi x 4), dapat %d" % frame_dicek)
	check(alas_beda.is_empty(), "baris alas (piksel terbawah) tiap frame lempar = frame kayuh sumbernya: %s" % "; ".join(alas_beda))
	check(tapak_beda.is_empty(), "tapak tiga baris terbawah (roda dan bayangan) tiap frame lempar sama persis dengan kayuh sumbernya: %s" % "; ".join(tapak_beda))
	check(alas_terukur == {"normal": 54, "serong_kanan": 50, "serong_kiri": 56}, "baris piksel terbawah (indeks dari atas sel 46x58, titik pijak y 46) per arah: normal 54, serong_kanan 50, serong_kiri 56, dapat %s" % alas_terukur)
	var identik: bool = true
	for baris: int in range(5):
		for frame: int in range(4):
			var rect: Rect2i = Rect2i(frame * SEL.x, baris * SEL.y, SEL.x, SEL.y)
			if melambat.get_region(rect).get_data() != kayuh.get_region(rect).get_data():
				identik = false
	check(identik, "20 frame melambat identik piksel demi piksel dengan baris santai di sheet kayuh (hanya fps berbeda)")
	# Meluncur dan rem (run fase1a-gerak, AC-13): tiap frame berasal dari santai frame 2 (`source` di JSON) dengan badan atas
	# digeser kaku; alas (piksel terbawah) dan tapak tiga baris terbawah harus sama dengan santai frame 2 dan baris terbawahnya sama
	# dengan keempat frame santai, jadi sprite tidak melompat saat berganti kayuh <-> meluncur <-> rem.
	for tag: String in ["meluncur", "rem"]:
		var gambar: Image = (load(FOLDER_ASET + "loper_agen_%s.png" % tag) as Texture2D).get_image()
		var json_pose: Dictionary = _baca_json("loper_agen_%s.json" % tag)
		var dicek: int = 0
		var beda: Array[String] = []
		for entri: Dictionary in json_pose.get("animations", []):
			var baris: int = int(entri["row"])
			check(String(entri.get("source", "")) == "santai row %d frame 2" % baris, "[%s] '%s' bersumber santai baris %d frame 2, dapat '%s'" % [tag, entri["name"], baris, entri.get("source", "")])
			var acuan: Array = _alas(kayuh, 2, baris)
			for frame: int in range(4):
				dicek += 1
				var ukur: Array = _alas(gambar, frame, baris)
				if ukur[0] != acuan[0] or ukur[0] < 0 or ukur[1] != acuan[1]:
					beda.append("%s f%d (%d lawan %d)" % [entri["name"], frame, ukur[0], acuan[0]])
				for frame_kayuh: int in range(4):
					if int(_alas(kayuh, frame_kayuh, baris)[0]) != int(ukur[0]):
						beda.append("%s f%d lawan santai f%d" % [entri["name"], frame, frame_kayuh])
		check(dicek == 20, "[%s] 20 frame dibandingkan (5 arah x 4), dapat %d" % [tag, dicek])
		check(beda.is_empty(), "[%s] alas dan tapak tiap frame = santai frame 2, baris terbawah = keempat frame santai (tidak melompat): %s" % [tag, "; ".join(beda)])
	# Kontrol negatif: pengukur membedakan sel yang digeser satu piksel ke bawah.
	var geser: Image = Image.create_empty(SEL.x * KOLOM, SEL.y, false, Image.FORMAT_RGBA8)
	geser.blit_rect(kayuh, Rect2i(0, 0, SEL.x * KOLOM, SEL.y - 1), Vector2i(0, 1))
	check(_alas(geser, 0, 0)[0] == int(_alas(kayuh, 0, 0)[0]) + 1, "kontrol negatif: sel yang digeser 1 piksel ke bawah terukur satu baris lebih rendah (pengukur peka)")
	check(_alas(geser, 0, 0)[1] != _alas(kayuh, 0, 0)[1], "kontrol negatif: tapak sel yang digeser berbeda dari aslinya")
