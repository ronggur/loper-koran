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
const BERKAS_SCENE_PEMAIN: String = "res://scenes/entities/loper_agen.tscn"
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
	_test_melambat_dari_stick()
	_test_nama_lempar()
	_test_sisi_dari_swipe()
	_test_lempar_waktu()
	_test_loper_sprite_tingkat()
	_test_loper_sprite_lempar()
	_test_loper_sprite_lempar_semua_kombinasi()
	_test_loper_sprite_lempar_tepi()
	_test_loper_sprite_di_tree()
	_test_loper_sprite_tanpa_frames()
	_test_titik_pijak_sama()


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
	# Terpadu dengan BikeDrive: bawah di luar zona mati memberi melambat_normal sementara kecepatan menuju 1,5 u/d.
	var geser_151: Vector2 = StickMap.petakan(Vector2(0.0, Config.STICK_RADIUS_PX * 0.151))
	var hasil_151: BikeDrive.Hasil = BikeDrive.langkah(3.0, 0.0, geser_151, DT)
	check(hasil_151.tingkat_sprite == LoperAnim.TINGKAT_MELAMBAT, "BikeDrive: stick bawah 15,1% memberi tingkat sprite melambat")
	var hasil_149: BikeDrive.Hasil = BikeDrive.langkah(3.0, 0.0, StickMap.petakan(Vector2(0.0, Config.STICK_RADIUS_PX * 0.149)), DT)
	check(hasil_149.tingkat_sprite == 0 and hasil_149.kecepatan_ud == 3.0, "BikeDrive: stick bawah 14,9% tetap santai 3,0 u/d")
	# Bawah sambil ke samping: melambat dengan arah dari gerak sebenarnya.
	var serong: BikeDrive.Hasil = BikeDrive.langkah(3.0, 0.0, StickMap.petakan(Vector2(Config.STICK_RADIUS_PX * 0.7, Config.STICK_RADIUS_PX * 0.7)), DT)
	check(serong.tingkat_sprite == LoperAnim.TINGKAT_MELAMBAT and LoperAnim.nama_animasi(serong.tingkat_sprite, serong.arah_sprite) == &"melambat_serong_kanan", "stick ke bawah-dekat: melambat_serong_kanan (arah dari gerak), dapat %s" % LoperAnim.nama_animasi(serong.tingkat_sprite, serong.arah_sprite))


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
	_judul.call("Sisi lempar dari swipe (AC-3, D-2)")
	var ambang: float = Config.LEMPAR_SWIPE_AMBANG_PX
	check(ambang == 12.0, "ambang swipe lempar usulan 12 px game")
	var awal: Vector2 = Vector2(450.0, 200.0)
	# Kiri layar = seberang, kanan layar = dekat (GDD 5.2), di berbagai panjang.
	for panjang: float in [12.0, 20.0, 60.0, 200.0]:
		check(LoperAnim.sisi_dari_swipe(awal, awal + Vector2(-panjang, 0.0)) == LoperAnim.Sisi.SEBERANG, "swipe %s px ke kiri layar = SEBERANG" % panjang)
		check(LoperAnim.sisi_dari_swipe(awal, awal + Vector2(panjang, 0.0)) == LoperAnim.Sisi.DEKAT, "swipe %s px ke kanan layar = DEKAT" % panjang)
	# Miring tapi masih dominan datar (tegak lebih kecil): sisi mengikuti tanda gerak datar, naik atau turun.
	check(LoperAnim.sisi_dari_swipe(awal, awal + Vector2(-40.0, -30.0)) == LoperAnim.Sisi.SEBERANG and LoperAnim.sisi_dari_swipe(awal, awal + Vector2(-40.0, 30.0)) == LoperAnim.Sisi.SEBERANG, "kiri-atas dan kiri-bawah (datar dominan) = SEBERANG")
	check(LoperAnim.sisi_dari_swipe(awal, awal + Vector2(40.0, -30.0)) == LoperAnim.Sisi.DEKAT and LoperAnim.sisi_dari_swipe(awal, awal + Vector2(40.0, 30.0)) == LoperAnim.Sisi.DEKAT, "kanan-atas dan kanan-bawah (datar dominan) = DEKAT")
	# Vertikal dominan tidak melempar.
	check(LoperAnim.sisi_dari_swipe(awal, awal + Vector2(0.0, -60.0)) == LoperAnim.Sisi.TIDAK_ADA and LoperAnim.sisi_dari_swipe(awal, awal + Vector2(0.0, 60.0)) == LoperAnim.Sisi.TIDAK_ADA, "swipe lurus ke atas atau ke bawah tidak melempar")
	check(LoperAnim.sisi_dari_swipe(awal, awal + Vector2(-30.0, -40.0)) == LoperAnim.Sisi.TIDAK_ADA and LoperAnim.sisi_dari_swipe(awal, awal + Vector2(30.0, 40.0)) == LoperAnim.Sisi.TIDAK_ADA, "swipe miring dengan gerak tegak lebih besar (kiri-atas 30/40, kanan-bawah 30/40) tidak melempar")
	check(LoperAnim.sisi_dari_swipe(awal, awal + Vector2(-50.0, -50.0)) == LoperAnim.Sisi.TIDAK_ADA and LoperAnim.sisi_dari_swipe(awal, awal + Vector2(50.0, 50.0)) == LoperAnim.Sisi.TIDAK_ADA, "tepat 45 derajat (datar = tegak) ambigu: tidak melempar")
	check(LoperAnim.sisi_dari_swipe(awal, awal + Vector2(51.0, 50.0)) == LoperAnim.Sisi.DEKAT and LoperAnim.sisi_dari_swipe(awal, awal + Vector2(-51.0, 50.0)) == LoperAnim.Sisi.SEBERANG, "sedikit di atas 45 derajat ke arah datar (51/50) melempar")
	# Ambang panjang: 11,99 tidak, tepat 12 ya (inklusif), diukur dari panjang swipe, bukan hanya komponen datar.
	check(LoperAnim.sisi_dari_swipe(awal, awal + Vector2(11.99, 0.0)) == LoperAnim.Sisi.TIDAK_ADA and LoperAnim.sisi_dari_swipe(awal, awal + Vector2(-11.99, 0.0)) == LoperAnim.Sisi.TIDAK_ADA, "swipe 11,99 px (di bawah ambang) tidak melempar, kedua arah")
	check(LoperAnim.sisi_dari_swipe(awal, awal + Vector2(12.0, 0.0)) == LoperAnim.Sisi.DEKAT and LoperAnim.sisi_dari_swipe(awal, awal + Vector2(-12.0, 0.0)) == LoperAnim.Sisi.SEBERANG, "swipe tepat 12 px (di ambang, inklusif) melempar, kedua arah")
	check(LoperAnim.sisi_dari_swipe(awal, awal + Vector2(11.0, 5.0)) == LoperAnim.Sisi.DEKAT, "swipe 11 datar + 5 tegak (panjang 12,08, datar dominan) melempar karena panjangnya melewati ambang")
	check(LoperAnim.sisi_dari_swipe(awal, awal + Vector2(8.5, 8.4)) == LoperAnim.Sisi.TIDAK_ADA, "swipe 8,5 + 8,4 (panjang 11,95) tidak melempar")
	# Tidak bergantung pada posisi awal.
	check(LoperAnim.sisi_dari_swipe(Vector2(0.0, 0.0), Vector2(-20.0, 3.0)) == LoperAnim.Sisi.SEBERANG and LoperAnim.sisi_dari_swipe(Vector2(779.0, 359.0), Vector2(759.0, 357.0)) == LoperAnim.Sisi.SEBERANG, "hasil hanya bergantung pada selisih, bukan letak titik awal")
	# Vektor nol dan nilai tidak sah.
	check(LoperAnim.sisi_dari_swipe(awal, awal) == LoperAnim.Sisi.TIDAK_ADA, "vektor nol (tap tanpa geser) tidak melempar")
	check(LoperAnim.sisi_dari_swipe(Vector2(NAN, 0.0), awal) == LoperAnim.Sisi.TIDAK_ADA and LoperAnim.sisi_dari_swipe(awal, Vector2(NAN, NAN)) == LoperAnim.Sisi.TIDAK_ADA, "NaN pada titik awal atau akhir tidak melempar")
	check(LoperAnim.sisi_dari_swipe(awal, Vector2(INF, 200.0)) == LoperAnim.Sisi.TIDAK_ADA and LoperAnim.sisi_dari_swipe(Vector2(-INF, 0.0), awal) == LoperAnim.Sisi.TIDAK_ADA, "tak hingga pada titik awal atau akhir tidak melempar")
	check(LoperAnim.sisi_dari_swipe(Vector2.ZERO, Vector2(1.0e30, 0.0)) == LoperAnim.Sisi.DEKAT, "swipe sangat panjang tetap hingga dan melempar ke dekat")


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
			# Perubahan tingkat dan arah di tengah lempar disimpan, tidak mengganti gambar (D-4). Lempar kedua diabaikan (D-3).
			pemain.speed_level = 2
			pemain.steer = -1
			check(pemain.animation == &"lempar_kanan_cepat_serong_kanan" and pemain.speed_level == 2 and pemain.steer == -1, "speed_level dan steer berubah di tengah lempar: tersimpan, gambar lempar tidak berganti")
			check(not pemain.lempar(LoperAnim.Sisi.SEBERANG), "lempar(SEBERANG) saat sedang melempar diabaikan (false)")
			check(pemain.animation == &"lempar_kanan_cepat_serong_kanan" and pemain.frame == 0, "lempar yang diabaikan tidak mengulang atau mengganti animasi")
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
	_judul.call("Titik pijak sama: kayuh, melambat, lempar (AC-8)")
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
	# Kontrol negatif: pengukur membedakan sel yang digeser satu piksel ke bawah.
	var geser: Image = Image.create_empty(SEL.x * KOLOM, SEL.y, false, Image.FORMAT_RGBA8)
	geser.blit_rect(kayuh, Rect2i(0, 0, SEL.x * KOLOM, SEL.y - 1), Vector2i(0, 1))
	check(_alas(geser, 0, 0)[0] == int(_alas(kayuh, 0, 0)[0]) + 1, "kontrol negatif: sel yang digeser 1 piksel ke bawah terukur satu baris lebih rendah (pengukur peka)")
	check(_alas(geser, 0, 0)[1] != _alas(kayuh, 0, 0)[1], "kontrol negatif: tapak sel yang digeser berbeda dari aslinya")
