class_name TesAnimasi5c
extends RefCounted
## Tes animasi pemain Fase 5C (run 20261022-fase5c-animasi-simpang, bagian A: AC-2 sampai AC-6): celah `LoperAnim.frame_jatuh` dan `pose_dari_gerak`
## (oracle literal), titik pijak tidak melompat di semua animasi dan di urutan kayuh -> jatuh -> terjerembab -> bangkit -> kayuh dan rem -> berhenti -> kayuh
## (oracle dari JSON sheet, bukan dari kode yang diuji), bangkit -> kayuh piksel-identik, arah jatuh ditahan sampai bangun di scene rute, lama jatuh
## tidak berubah oleh bangkit, lempar dari BERHENTI, jeda membekukan bangkit, Main lagi tanpa sisa jatuh, dan BERHENTI di skenario tangkap kucing.
##
## Dipanggil dari `tests/run_tests.gd`. Tidak menyentuh berkas save.

const BERKAS_RUTE: String = "res://scenes/rute/rute.tscn"
const BERKAS_PEMAIN: String = "res://scenes/entities/loper_agen.tscn"
const FOLDER_LOPER: String = "res://assets/sprites/loper/"
const DT: float = 1.0 / 60.0
const SKALA: int = 3
const TITIK_STICK: Vector2 = Vector2(100, 260)
## Awalan nama animasi -> JSON sheet sumber gambarnya (oracle pijak: `cell` dan `ground_anchor` dibaca dari JSON ini), ditulis ulang di sini.
const SHEET_AWALAN: Array = [
	["santai_", "loper_agen.json"], ["cepat_", "loper_agen.json"], ["ngebut_", "loper_agen.json"], ["melambat_", "loper_agen_melambat.json"],
	["lempar_", "loper_agen_lempar.json"], ["meluncur_", "loper_agen_meluncur.json"], ["rem_", "loper_agen_rem.json"], ["jatuh_", "loper_agen_jatuh.json"],
	["terjerembab_", "loper_agen_jatuh.json"], ["bangkit_", "loper_agen_bangkit.json"], ["berhenti_", "loper_agen_berhenti.json"],
]
const NAMA_ARAH: Dictionary = {-2: "kiri", -1: "serong_kiri", 0: "normal", 1: "serong_kanan", 2: "kanan"}

var _cek: Callable
var _judul: Callable
var _tree: SceneTree
var _json: Dictionary = {}
var _gambar: Dictionary = {}


func _init(cek: Callable, judul: Callable, tree: SceneTree) -> void:
	_cek = cek
	_judul = judul
	_tree = tree


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_test_celah_frame_jatuh()
	_test_celah_pose_berhenti()
	await _test_pijak_semua_animasi()
	await _test_pijak_urutan_per_arah()
	await _test_bangkit_ke_kayuh_piksel()
	await _test_lempar_dari_berhenti()
	await _test_scene_jatuh_arah_ditahan()
	await _test_scene_lama_jatuh_tanpa_bangkit()
	await _test_scene_jeda_bangkit()
	await _test_scene_main_lagi_saat_jatuh()
	await _test_scene_berhenti_tangkap()


# --- AC-4: celah LoperAnim ---

func _test_celah_frame_jatuh() -> void:
	_judul.call("LoperAnim.frame_jatuh: batas bangkit, terjerembab 0,2 detik, frame terakhir ditahan, arah dijepit, NaN (AC-4 run 5C)")
	check(Config.TABRAKAN_JATUH_DETIK == 1.2 and Config.TABRAKAN_TOLERANSI_DETIK == 0.000001, "kontrol: lama jatuh 1,2 detik dan toleransi 0,000001 (angka oracle di bawah)")
	# jatuh 4 frame 10 fps (0,4 detik), terjerembab 2 frame 3 fps, bangkit 6 frame 10 fps, total 1,2 -> mulai bangkit 1,2 - 0,6 = 0,6.
	var f: LoperAnim.FrameJatuh = LoperAnim.frame_jatuh(0.6, 0, 10.0, 4, 3.0, 2, 10.0, 6, 1.2)
	check(f.nama == &"bangkit_normal" and f.frame == 0 and f.progres == 0.0, "tepat 0,6 detik = bangkit frame 0 progres 0 (batas inklusif), dapat %s f%d p%.3f" % [f.nama, f.frame, f.progres])
	f = LoperAnim.frame_jatuh(0.6 - 0.0000005, 0, 10.0, 4, 3.0, 2, 10.0, 6, 1.2)
	check(f.nama == &"bangkit_normal" and f.frame == 0, "0,6 - 0,5 toleransi = bangkit frame 0 (dalam toleransi), dapat %s" % f.nama)
	var tepat_toleransi: float = 0.6 - Config.TABRAKAN_TOLERANSI_DETIK
	f = LoperAnim.frame_jatuh(tepat_toleransi, 0, 10.0, 4, 3.0, 2, 10.0, 6, 1.2)
	check(tepat_toleransi + Config.TABRAKAN_TOLERANSI_DETIK == 0.6 and f.nama == &"bangkit_normal" and f.frame == 0, "0,6 - toleransi persis (t + toleransi = 0,6) = bangkit frame 0 (batas >=), dapat %s" % f.nama)
	f = LoperAnim.frame_jatuh(0.6 - 0.000002, 0, 10.0, 4, 3.0, 2, 10.0, 6, 1.2)
	check(f.nama == &"terjerembab_normal" and f.frame == 0, "0,6 - 2 x toleransi = terjerembab frame 0, dapat %s f%d" % [f.nama, f.frame])
	var harapan: Array = [[0.65, &"bangkit_normal", 0, 0.5], [0.7, &"bangkit_normal", 1, 0.0], [0.95, &"bangkit_normal", 3, 0.5], [1.15, &"bangkit_normal", 5, 0.5],
		[1.2, &"bangkit_normal", 5, 0.0], [1.5, &"bangkit_normal", 5, 0.0], [9.0, &"bangkit_normal", 5, 0.0], [0.4, &"terjerembab_normal", 0, 0.0], [0.5, &"terjerembab_normal", 0, 0.3]]
	var beda: Array[String] = []
	for k: Array in harapan:
		f = LoperAnim.frame_jatuh(k[0], 0, 10.0, 4, 3.0, 2, 10.0, 6, 1.2)
		if f.nama != k[1] or f.frame != k[2] or absf(f.progres - float(k[3])) > 0.000001:
			beda.append("t %.3f: %s f%d p%.3f" % [k[0], f.nama, f.frame, f.progres])
	check(beda.is_empty(), "bangkit 10 fps dari 0,6, frame terakhir (5) ditahan dengan progres 0 sejak 1,2 sampai bangun; beda: %s" % [beda])
	# Hitungan langkah 60 fps selama 1,2 detik (72 langkah, t = i/60): jatuh 24, terjerembab 12 (= 0,2 detik), bangkit 36.
	var hitung: Dictionary = {"jatuh": 0, "terjerembab": 0, "bangkit": 0}
	for i: int in range(72):
		var awalan: String = String(LoperAnim.frame_jatuh(float(i) / 60.0, 1, 10.0, 4, 3.0, 2, 10.0, 6, 1.2).nama).get_slice("_", 0)
		hitung[awalan] = int(hitung[awalan]) + 1
	check(hitung == {"jatuh": 24, "terjerembab": 12, "bangkit": 36}, "72 langkah 60 fps: jatuh 24, terjerembab 12 (0,2 detik, P-4), bangkit 36, dapat %s" % [hitung])
	# Bangkit lebih panjang dari sisa: total 0,5 -> mulai = maxf(0,5 - 0,6, 0,4) = 0,4.
	check(LoperAnim.frame_jatuh(0.39, 0, 10.0, 4, 3.0, 2, 10.0, 6, 0.5).nama == &"jatuh_normal", "total 0,5: 0,39 masih jatuh (bangkit tidak mulai sebelum jatuh selesai; maxf)")
	f = LoperAnim.frame_jatuh(0.45, 0, 10.0, 4, 3.0, 2, 10.0, 6, 0.5)
	check(f.nama == &"bangkit_normal" and f.frame == 0 and absf(f.progres - 0.5) < 0.000001, "total 0,5: 0,45 = bangkit frame 0 progres 0,5 (mulai 0,4), dapat %s f%d p%.3f" % [f.nama, f.frame, f.progres])
	# Arah dijepit.
	var jepit: Array = [[-3, 0.1, &"jatuh_kiri"], [7, 0.1, &"jatuh_kanan"], [-3, 0.45, &"terjerembab_kiri"], [7, 0.45, &"terjerembab_kanan"], [-3, 0.9, &"bangkit_kiri"], [7, 0.9, &"bangkit_kanan"]]
	var beda_jepit: Array[String] = []
	for k: Array in jepit:
		var nama: StringName = LoperAnim.frame_jatuh(k[1], k[0], 10.0, 4, 3.0, 2, 10.0, 6, 1.2).nama
		if nama != k[2]:
			beda_jepit.append("%d %.2f: %s" % [k[0], k[1], nama])
	check(beda_jepit.is_empty(), "arah -3 -> kiri dan 7 -> kanan untuk jatuh, terjerembab, bangkit; beda: %s" % [beda_jepit])
	check(LoperAnim.nama_animasi_pose(LoperAnim.Pose.BERHENTI, 2, -3) == &"berhenti_kiri" and LoperAnim.nama_animasi_pose(LoperAnim.Pose.BERHENTI, -1, 7) == &"berhenti_kanan", "berhenti: arah dijepit (-3 kiri, 7 kanan), tingkat diabaikan")
	# NaN / negatif / tak hingga = awal jatuh.
	for t: float in [NAN, -0.5, -INF, INF]:
		f = LoperAnim.frame_jatuh(t, 0, 10.0, 4, 3.0, 2, 10.0, 6, 1.2)
		check(f.nama == &"jatuh_normal" and f.frame == 0 and f.progres == 0.0, "lewat %s = jatuh_normal frame 0 progres 0, dapat %s f%d" % [t, f.nama, f.frame])
	# Tanpa bangkit: perilaku lama (terjerembab berulang).
	check(LoperAnim.frame_jatuh(1.0, 0, 10.0, 4, 3.0, 2, 10.0, 0, 1.2).nama == &"terjerembab_normal" and LoperAnim.frame_jatuh(1.0, 0, 10.0, 4, 3.0, 2, 10.0, 6, INF).frame == 1
		and LoperAnim.frame_jatuh(1.0, 0, 10.0, 4, 3.0, 2, 0.0, 6, 1.2).nama == &"terjerembab_normal", "n bangkit 0, total INF, atau fps 0: terjerembab (frame 1 di 1,0 detik: 0,6 x 3 = 1,8)")


func _test_celah_pose_berhenti() -> void:
	_judul.call("LoperAnim.pose_dari_gerak: BERHENTI hanya dengan rem dan kecepatan <= 0,05, NaN = REM (AC-4 run 5C)")
	check(Config.POSE_MELUNCUR_TOLERANSI_UD == 0.05, "kontrol: toleransi pose 0,05 u/d")
	check(LoperAnim.pose_dari_gerak(true, -1.0, 0.05, 1.5) == LoperAnim.Pose.BERHENTI, "rem, 0,05 = BERHENTI (batas inklusif)")
	check(LoperAnim.pose_dari_gerak(true, -1.0, 0.0500001, 1.5) == LoperAnim.Pose.REM, "rem, 0,0500001 = REM")
	check(LoperAnim.pose_dari_gerak(true, -1.0, NAN, 1.5) == LoperAnim.Pose.REM, "rem, NaN = REM")
	check(LoperAnim.pose_dari_gerak(true, -1.0, -0.001, 1.5) == LoperAnim.Pose.BERHENTI, "rem, negatif kecil = BERHENTI")
	var pernah: bool = false
	for stick: float in [-1.0, -0.95, -0.5, 0.0, 0.5, 1.0, NAN]:
		for v: float in [-1.0, 0.0, 0.03, 0.05, 1.0, 3.0, NAN]:
			for tujuan: float in [0.0, 1.5, 3.0, NAN]:
				if LoperAnim.pose_dari_gerak(false, stick, v, tujuan) == LoperAnim.Pose.BERHENTI:
					pernah = true
	check(not pernah, "tanpa rem tidak pernah BERHENTI (7 stick x 7 kecepatan x 4 tujuan)")
	check(LoperAnim.tingkat_lempar(LoperAnim.Pose.BERHENTI, 2) == 0 and LoperAnim.pedal_rate(LoperAnim.Pose.BERHENTI, 0, 0.0) == 1.0, "BERHENTI: lempar tingkat santai, laju kayuh 1")


# --- Pembantu pijak dan gambar ---

func _baca_json(nama: String) -> Dictionary:
	if not _json.has(nama):
		_json[nama] = JSON.parse_string(FileAccess.get_file_as_string(FOLDER_LOPER + nama)) as Dictionary
	return _json[nama]


## JSON sheet untuk animasi `nama` dari tabel awalan (bukan dari kode yang diuji).
func _json_animasi(nama: String) -> Dictionary:
	for baris: Array in SHEET_AWALAN:
		if nama.begins_with(String(baris[0])):
			return _baca_json(String(baris[1]))
	return {}


## Titik pijak dunia sprite saat ini: posisi global + offset - ukuran frame / 2 (centered) + `ground_anchor` JSON sheet animasinya. Juga memeriksa ukuran
## frame = `cell` JSON. Mengembalikan Vector2(INF, INF) bila ukuran tidak cocok.
func _pijak(s: AnimatedSprite2D) -> Vector2:
	var json: Dictionary = _json_animasi(String(s.animation))
	var t: Texture2D = s.sprite_frames.get_frame_texture(s.animation, s.frame)
	if json.is_empty() or t == null:
		return Vector2(INF, INF)
	var sel: Array = json["cell"]
	var jangkar: Array = json["ground_anchor"]
	if t.get_size() != Vector2(float(sel[0]), float(sel[1])):
		return Vector2(INF, INF)
	var kiri_atas: Vector2 = s.global_position + s.offset - (t.get_size() / 2.0 if s.centered else Vector2.ZERO)
	return kiri_atas + Vector2(float(jangkar[0]), float(jangkar[1]))


## Gambar frame saat ini dan pojok kiri atasnya di dunia.
func _gambar_dunia(s: AnimatedSprite2D) -> Array:
	var t: AtlasTexture = s.sprite_frames.get_frame_texture(s.animation, s.frame) as AtlasTexture
	var jalur: String = t.atlas.resource_path
	if not _gambar.has(jalur):
		_gambar[jalur] = t.atlas.get_image()
	var img: Image = (_gambar[jalur] as Image).get_region(Rect2i(t.region))
	var kiri_atas: Vector2 = s.global_position + s.offset - (t.get_size() / 2.0 if s.centered else Vector2.ZERO)
	return [img, Vector2i(kiri_atas.round())]


## Banyaknya piksel yang berbeda antara dua gambar dunia (alfa beda, atau warna beda bila alfa > 0) pada gabungan kotaknya.
func _beda_piksel(a: Array, b: Array) -> int:
	var ia: Image = a[0]
	var ib: Image = b[0]
	var pa: Vector2i = a[1]
	var pb: Vector2i = b[1]
	var gabung: Rect2i = Rect2i(pa, ia.get_size()).merge(Rect2i(pb, ib.get_size()))
	var beda: int = 0
	for y: int in range(gabung.position.y, gabung.end.y):
		for x: int in range(gabung.position.x, gabung.end.x):
			var ca: Color = _piksel(ia, x - pa.x, y - pa.y)
			var cb: Color = _piksel(ib, x - pb.x, y - pb.y)
			if ca.a8 != cb.a8 or (ca.a8 != 0 and ca != cb):
				beda += 1
	return beda


func _piksel(img: Image, x: int, y: int) -> Color:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return Color(0, 0, 0, 0)
	return img.get_pixel(x, y)


func _pemain_di_tree(posisi: Vector2) -> Array:
	var induk: Node2D = Node2D.new()
	induk.position = posisi
	var pemain: LoperSprite = (load(BERKAS_PEMAIN) as PackedScene).instantiate() as LoperSprite
	induk.add_child(pemain)
	_tree.root.add_child(induk)
	await _tree.process_frame
	pemain.set_process(false)
	pemain.pause()
	return [induk, pemain]


# --- AC-2: pijak ---

func _test_pijak_semua_animasi() -> void:
	_judul.call("Titik pijak: semua 68 animasi, semua frame, pijak dunia = titik asal node (oracle dari JSON sheet, AC-2 run 5C)")
	var pasang: Array = await _pemain_di_tree(Vector2(123, 45))
	var pemain: LoperSprite = pasang[1]
	check(pemain.centered and pemain.offset == Vector2(0, -17), "kontrol: sprite pemain centered, offset (0, -17)")
	var salah: Array[String] = []
	var jumlah: int = 0
	for nama: String in pemain.sprite_frames.get_animation_names():
		pemain.animation = StringName(nama)
		for i: int in range(pemain.sprite_frames.get_frame_count(nama)):
			pemain.set_frame_and_progress(i, 0.0)
			jumlah += 1
			var p: Vector2 = _pijak(pemain)
			if p != Vector2(123, 45):
				salah.append("%s f%d %s" % [nama, i, p])
	check(jumlah == 262 and salah.is_empty(), "262 frame: pijak = (123, 45) dan ukuran frame = sel JSON; salah: %s" % [salah])
	pasang[0].queue_free()
	await _tree.process_frame


func _test_pijak_urutan_per_arah() -> void:
	_judul.call("Titik pijak lima arah: kayuh -> jatuh -> terjerembab -> bangkit -> kayuh, dan rem -> berhenti -> kayuh, tiap langkah 60 fps (AC-2 run 5C)")
	var pasang: Array = await _pemain_di_tree(Vector2(40, 70))
	var pemain: LoperSprite = pasang[1]
	for arah: int in range(-2, 3):
		pemain.atur_jatuh(false, 0.0)
		pemain.pose = LoperAnim.Pose.KAYUH
		pemain.speed_level = 0
		pemain.steer = arah
		pemain.set_frame_and_progress(3, 0.5)
		var urutan: Array[String] = ["%s:%d" % [pemain.animation, pemain.frame]]
		var salah: Array[String] = []
		if _pijak(pemain) != Vector2(40, 70):
			salah.append("kayuh sebelum")
		for i: int in range(73):
			pemain.atur_jatuh(true, float(i) / 60.0)
			if _pijak(pemain) != Vector2(40, 70):
				salah.append("%s f%d" % [pemain.animation, pemain.frame])
			var tanda: String = "%s:%d" % [pemain.animation, pemain.frame]
			if urutan[urutan.size() - 1] != tanda:
				urutan.append(tanda)
		pemain.atur_jatuh(false, 0.0)
		urutan.append("%s:%d" % [pemain.animation, pemain.frame])
		if _pijak(pemain) != Vector2(40, 70):
			salah.append("kayuh sesudah")
		var h: String = NAMA_ARAH[arah]
		var harapan: Array[String] = ["santai_%s:3" % h, "jatuh_%s:0" % h, "jatuh_%s:1" % h, "jatuh_%s:2" % h, "jatuh_%s:3" % h, "terjerembab_%s:0" % h]
		for b: int in range(6):
			harapan.append("bangkit_%s:%d" % [h, b])
		harapan.append("santai_%s:0" % h)
		check(salah.is_empty() and urutan == harapan, "arah %s: pijak tetap di semua frame dan urutan %s (sesudah bangun frame 0), dapat %s; salah %s" % [h, harapan, urutan, salah])
		# Rem -> berhenti -> kayuh.
		var salah_rem: Array[String] = []
		for pose: LoperAnim.Pose in [LoperAnim.Pose.REM, LoperAnim.Pose.BERHENTI, LoperAnim.Pose.KAYUH]:
			pemain.pose = pose
			for i: int in range(pemain.sprite_frames.get_frame_count(pemain.animation)):
				pemain.set_frame_and_progress(i, 0.0)
				if _pijak(pemain) != Vector2(40, 70):
					salah_rem.append("%s f%d" % [pemain.animation, i])
		check(salah_rem.is_empty() and pemain.animation == StringName("santai_" + h), "arah %s: rem -> berhenti -> kayuh pijak tetap, salah %s" % [h, salah_rem])
	pasang[0].queue_free()
	await _tree.process_frame


# --- AC-3: bangkit -> kayuh piksel ---

func _test_bangkit_ke_kayuh_piksel() -> void:
	_judul.call("Bangkit -> kayuh: frame terakhir bangkit dan frame pertama sesudah bangun piksel-identik di dunia, lima arah (AC-3 run 5C)")
	var pasang: Array = await _pemain_di_tree(Vector2(200, 100))
	var pemain: LoperSprite = pasang[1]
	for arah: int in range(-2, 3):
		pemain.atur_jatuh(false, 0.0)
		pemain.pose = LoperAnim.Pose.KAYUH
		pemain.speed_level = 0
		pemain.steer = arah
		pemain.atur_jatuh(true, 1.2)
		var akhir_bangkit: Array = _gambar_dunia(pemain)
		var nama_b: StringName = pemain.animation
		pemain.atur_jatuh(false, 0.0)
		var sesudah: Array = _gambar_dunia(pemain)
		var beda: int = _beda_piksel(akhir_bangkit, sesudah)
		check(nama_b == StringName("bangkit_" + NAMA_ARAH[arah]) and pemain.frame == 0 and beda == 0, "arah %s: %s f5 -> %s f%d, %d piksel beda" % [NAMA_ARAH[arah], nama_b, pemain.animation, pemain.frame, beda])
		# Kontrol: frame kayuh lain memang berbeda (tes ini mampu melihat lompatan frame).
		pemain.set_frame_and_progress(3, 0.0)
		check(_beda_piksel(akhir_bangkit, _gambar_dunia(pemain)) > 0, "kontrol arah %s: santai frame 3 berbeda dari frame terakhir bangkit" % NAMA_ARAH[arah])
	pasang[0].queue_free()
	await _tree.process_frame


# --- AC-5: lempar dari BERHENTI ---

func _test_lempar_dari_berhenti() -> void:
	_judul.call("Lempar dari pose BERHENTI memakai tingkat santai (AC-5 run 5C)")
	var pasang: Array = await _pemain_di_tree(Vector2.ZERO)
	var pemain: LoperSprite = pasang[1]
	var harapan: Dictionary = {-2: "serong_kiri", -1: "serong_kiri", 0: "normal", 1: "serong_kanan", 2: "serong_kanan"}
	var beda: Array[String] = []
	for arah: int in range(-2, 3):
		for sisi: LoperAnim.Sisi in [LoperAnim.Sisi.SEBERANG, LoperAnim.Sisi.DEKAT]:
			pemain.batalkan_lempar()
			pemain.speed_level = 2
			pemain.steer = arah
			pemain.pose = LoperAnim.Pose.BERHENTI
			var nama_awal: StringName = pemain.animation
			pemain.lempar(sisi)
			var h: String = "lempar_%s_santai_%s" % ["kiri" if sisi == LoperAnim.Sisi.SEBERANG else "kanan", harapan[arah]]
			if nama_awal != StringName("berhenti_" + NAMA_ARAH[arah]) or pemain.animation != StringName(h):
				beda.append("%d %d: %s -> %s" % [arah, sisi, nama_awal, pemain.animation])
	check(beda.is_empty(), "10 kasus: dari berhenti_<arah> lempar = lempar_<sisi>_santai_<arah lempar> walau tingkat ngebut; beda %s" % [beda])
	pemain.batalkan_lempar()
	pasang[0].queue_free()
	await _tree.process_frame


# --- Scene ---

func _siapkan(misi: DataMisi = null, hari: int = 0) -> RuteMain:
	_tree.root.size = Vector2i(2340, 1080)
	var akar: RuteMain = (load(BERKAS_RUTE) as PackedScene).instantiate() as RuteMain
	if misi != null:
		akar.atur_benih_awal(SeedHari.rute(hari))
		akar.atur_misi(misi)
	_tree.root.add_child(akar)
	await _tree.process_frame
	await _tree.process_frame
	akar.set_process(false)
	(akar.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = false
	(akar.find_child("LoperAgen", true, false) as LoperSprite).set_process(false)
	return akar


func _bersihkan(akar: RuteMain) -> void:
	for i: int in range(4):
		_sentuh(i, Vector2(-50, -50), false)
	if akar.sedang_jeda():
		akar.minta_lanjut()
	(akar.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = OS.has_feature("editor")
	_tree.root.remove_child(akar)
	akar.free()


func _sentuh(index: int, posisi_viewport: Vector2, tekan: bool) -> void:
	var e: InputEventScreenTouch = InputEventScreenTouch.new()
	e.index = index
	e.position = posisi_viewport * float(SKALA)
	e.pressed = tekan
	Input.parse_input_event(e)
	Input.flush_buffered_events()


func _geser(index: int, posisi_viewport: Vector2) -> void:
	var e: InputEventScreenDrag = InputEventScreenDrag.new()
	e.index = index
	e.position = posisi_viewport * float(SKALA)
	Input.parse_input_event(e)
	Input.flush_buffered_events()


func _taruh(akar: RuteMain, v: float, lateral: float, maju: float) -> void:
	var sepeda: SepedaUji = akar.find_child("Sepeda", true, false) as SepedaUji
	var k: BikeMotion.Keadaan = sepeda.keadaan.salin()
	k.kecepatan_ud = v
	k.lateral_ubin = lateral
	sepeda.keadaan = k
	sepeda.jarak_ubin = maju
	akar.perbarui(0.0)


## Menabrak anjing seberang pertama: sepeda santai di (lateral, maju), stick digeser `geser_x` piksel ke samping (0 = netral). Mengembalikan jumlah langkah
## sampai tabrakan (-1 bila tidak terjadi dalam 900 langkah). Jari stick tetap ditekan; dilepas pemanggil lewat `_bersihkan`.
func _tabrak(akar: RuteMain, lateral: float, maju: float, geser_x: float) -> int:
	var tabrak: Array[String] = []
	akar.tabrakan.connect(func(j: String) -> void: tabrak.append(j))
	_taruh(akar, Config.KECEPATAN_SANTAI_UD, lateral, maju)
	if geser_x != 0.0:
		_sentuh(0, TITIK_STICK, true)
		_geser(0, TITIK_STICK + Vector2(geser_x, 0))
	var n: int = 0
	while tabrak.is_empty() and n < 900:
		akar.perbarui(DT)
		n += 1
	return n if not tabrak.is_empty() else -1


func _test_scene_jatuh_arah_ditahan() -> void:
	_judul.call("Scene rute: jatuh ke arah gerak saat tabrakan dan ditahan sampai bangun; pijak tetap; bangun piksel-identik (AC-2, AC-3 run 5C, temuan A-F2)")
	for kasus: Array in [[-0.6, 30.0, 0.0, "normal"], [0.0, 35.0, -25.0, "serong_kiri"]]:
		var akar: RuteMain = await _siapkan()
		var sepeda: SepedaUji = akar.find_child("Sepeda", true, false) as SepedaUji
		var sprite: LoperSprite = akar.find_child("LoperAgen", true, false) as LoperSprite
		var n: int = _tabrak(akar, kasus[0], kasus[1], kasus[2])
		var h: String = kasus[3]
		var pijak_awal: Vector2 = _pijak(sprite)
		var salah: Array[String] = []
		var nama: Array[String] = ["%s:%d" % [sprite.animation, sprite.frame]]
		var gambar_lalu: Array = _gambar_dunia(sprite)
		var beda_bangun: int = -1
		for i: int in range(72):
			akar.perbarui(DT)
			if _pijak(sprite) != pijak_awal or pijak_awal != sprite.global_position:
				salah.append("langkah %d %s f%d %s" % [i + 1, sprite.animation, sprite.frame, _pijak(sprite)])
			var tanda: String = "%s:%d" % [sprite.animation, sprite.frame]
			if nama[nama.size() - 1] != tanda:
				nama.append(tanda)
			if not sprite.sedang_jatuh() and beda_bangun < 0:
				beda_bangun = _beda_piksel(gambar_lalu, _gambar_dunia(sprite))
			gambar_lalu = _gambar_dunia(sprite)
		var harapan: Array[String] = ["jatuh_%s:0" % h, "jatuh_%s:1" % h, "jatuh_%s:2" % h, "jatuh_%s:3" % h, "terjerembab_%s:0" % h]
		for b: int in range(6):
			harapan.append("bangkit_%s:%d" % [h, b])
		harapan.append("santai_%s:0" % h)
		check(n > 0 and nama == harapan, "%s: tabrakan langkah %d, urutan animasi %s, dapat %s" % [h, n, harapan, nama])
		check(salah.is_empty(), "%s: pijak dunia tetap %s dari langkah tabrakan sampai bangun (= posisi sepeda); salah %s" % [h, pijak_awal, salah])
		check(beda_bangun == 0, "%s: langkah bangun piksel-identik dengan frame terakhir bangkit, beda %d" % [h, beda_bangun])
		_bersihkan(akar)


## Bangkit tidak mengubah lama jatuh: jalur yang sama dengan SpriteFrames tanpa animasi bangkit memberi keadaan `Tabrakan`, alfa, jatuh, dan gerak yang sama tiap langkah.
func _test_scene_lama_jatuh_tanpa_bangkit() -> void:
	_judul.call("Scene rute: bangkit tidak mengubah lama jatuh, kebal, kedip, atau saat bangun (dibanding SpriteFrames tanpa bangkit, AC-5 run 5C)")
	var jejak: Array = []
	for tanpa_bangkit: bool in [false, true]:
		var akar: RuteMain = await _siapkan()
		var sprite: LoperSprite = akar.find_child("LoperAgen", true, false) as LoperSprite
		var sepeda: SepedaUji = akar.find_child("Sepeda", true, false) as SepedaUji
		if tanpa_bangkit:
			var salinan: SpriteFrames = sprite.sprite_frames.duplicate() as SpriteFrames
			for h: String in NAMA_ARAH.values():
				salinan.remove_animation(StringName("bangkit_" + h))
			sprite.sprite_frames = salinan
		var n: int = _tabrak(akar, -0.6, 30.0, 0.0)
		var catatan: Array = [n]
		var bangun: int = -1
		var kebal_habis: int = -1
		var ada_bangkit: bool = false
		for i: int in range(150):
			akar.perbarui(DT)
			var t: Tabrakan.Keadaan = akar.rintangan().tabrakan
			catatan.append([t.jatuh_detik, t.kebal_detik, sprite.modulate.a, sprite.sedang_jatuh(), sepeda.kecepatan_ud, sepeda.jarak_ubin])
			ada_bangkit = ada_bangkit or String(sprite.animation).begins_with("bangkit")
			if bangun < 0 and not sprite.sedang_jatuh():
				bangun = i + 1
			if kebal_habis < 0 and bangun > 0 and not Tabrakan.kebal(t):
				kebal_habis = i + 1
		check(bangun == 72 and kebal_habis == 132 and ada_bangkit == not tanpa_bangkit, "%s: bangun di langkah 72 (1,2 detik), kebal habis di langkah 132 (+1,0 detik), bangkit %s" % ["tanpa bangkit" if tanpa_bangkit else "dengan bangkit", ada_bangkit])
		jejak.append(catatan)
		_bersihkan(akar)
	check(jejak[0] == jejak[1], "150 langkah: jatuh, kebal, alfa kedip, sedang_jatuh, kecepatan, dan jarak identik dengan dan tanpa bangkit")


func _test_scene_jeda_bangkit() -> void:
	_judul.call("Scene rute: jeda membekukan bangkit (animasi, frame, progres), lanjut tanpa lompatan (AC-5 run 5C)")
	var akar: RuteMain = await _siapkan()
	var sprite: LoperSprite = akar.find_child("LoperAgen", true, false) as LoperSprite
	_tabrak(akar, -0.6, 30.0, 0.0)
	for i: int in range(50):
		akar.perbarui(DT)
	var sebelum: Array = [sprite.animation, sprite.frame, sprite.frame_progress, akar.rintangan().tabrakan.jatuh_detik]
	check(sprite.animation == &"bangkit_normal" and sprite.frame == 2, "kontrol: 50 langkah sesudah tabrakan = bangkit_normal frame 2, dapat %s f%d" % [sprite.animation, sprite.frame])
	akar.minta_jeda()
	for i: int in range(120):
		akar.perbarui(DT)
	var selama: Array = [sprite.animation, sprite.frame, sprite.frame_progress, akar.rintangan().tabrakan.jatuh_detik]
	check(akar.sedang_jeda() and selama == sebelum, "120 langkah jeda: %s sama dengan sebelum jeda %s" % [selama, sebelum])
	akar.minta_lanjut()
	akar.perbarui(DT)
	check([sprite.animation, sprite.frame, sprite.frame_progress, akar.rintangan().tabrakan.jatuh_detik] == sebelum, "langkah pertama sesudah lanjut ber-dt 0: tidak melompat")
	for i: int in range(22):
		akar.perbarui(DT)
	check(not sprite.sedang_jatuh() and sprite.animation == &"santai_normal" and sprite.frame == 0, "bangun tetap 72 langkah efektif sesudah tabrakan (tanpa langkah jeda), dapat %s f%d" % [sprite.animation, sprite.frame])
	_bersihkan(akar)


func _test_scene_main_lagi_saat_jatuh() -> void:
	_judul.call("Scene rute: Main lagi di tengah jatuh/bangkit tidak menyisakan animasi jatuh atau arah jatuh (AC-5 run 5C)")
	for langkah: int in [10, 30, 60]:
		var akar: RuteMain = await _siapkan()
		var sprite: LoperSprite = akar.find_child("LoperAgen", true, false) as LoperSprite
		_tabrak(akar, 0.0, 35.0, -25.0)
		for i: int in range(langkah):
			akar.perbarui(DT)
		var tengah: StringName = sprite.animation
		_sentuh(0, TITIK_STICK, false)
		akar.main_lagi()
		var nama: String = String(sprite.animation)
		check(not sprite.sedang_jatuh() and nama == "santai_normal" and sprite.frame == 0 and sprite.is_playing() and not Tabrakan.jatuh(akar.rintangan().tabrakan),
			"Main lagi pada langkah %d (%s): santai_normal frame 0 diputar, tidak jatuh, dapat %s" % [langkah, tengah, nama])
		akar.perbarui(DT)
		check(not String(sprite.animation).begins_with("jatuh") and not String(sprite.animation).begins_with("terjerembab") and not String(sprite.animation).begins_with("bangkit"), "langkah sesudah Main lagi: tanpa animasi jatuh, dapat %s" % sprite.animation)
		_bersihkan(akar)


## AC-6: menepi lalu rem sampai diam di dekat kucing langkah `tangkap`: pose BERHENTI selama rem ditahan di kecepatan 0, progres tangkap berjalan.
func _test_scene_berhenti_tangkap() -> void:
	_judul.call("Scene rute dengan misi: rem sampai diam di dekat kucing tangkap = pose BERHENTI, progres tangkap berjalan (AC-6 run 5C)")
	var misi: DataMisi = PemuatMisi.muat_folder().cari("p1_kucing")
	var akar: RuteMain = await _siapkan(misi, 1)
	var sepeda: SepedaUji = akar.find_child("Sepeda", true, false) as SepedaUji
	var rencana: RencanaMisi.Rencana = akar.rencana_misi()
	var t3: RencanaMisi.Titik = rencana.titik[2]
	check(t3.jenis == "tangkap", "kontrol: titik 3 = langkah tangkap")
	# Langkah lihat 1 dan 2 dianggap selesai dengan melewati titiknya.
	for t: RencanaMisi.Titik in [rencana.titik[0], rencana.titik[1]]:
		_taruh(akar, Config.KECEPATAN_SANTAI_UD, 0.5, t.maju_ubin + 0.5)
		akar.perbarui(DT)
	_taruh(akar, Config.KECEPATAN_SANTAI_UD, -1.0, t3.maju_ubin - 2.0)
	_sentuh(0, TITIK_STICK, true)
	_geser(0, TITIK_STICK + Vector2(0, Config.STICK_RADIUS_PX))
	var n: int = 0
	while sepeda.kecepatan_ud > 0.0 and n < 300:
		akar.perbarui(DT)
		n += 1
	for i: int in range(20):
		akar.perbarui(DT)
	var timer: float = akar.keadaan_misi().timer_detik
	check(sepeda.kecepatan_ud == 0.0 and sepeda.rem_aktif() and sepeda.pose() == LoperAnim.Pose.BERHENTI and String(sepeda.nama_animasi()).begins_with("berhenti_"),
		"rem ditahan sampai 0 u/d: pose BERHENTI (%s), dapat pose %d" % [sepeda.nama_animasi(), sepeda.pose()])
	check(akar.keadaan_misi().langkah == 2 and timer > 0.0 and absf(sepeda.jarak_ubin - t3.maju_ubin) <= t3.radius_ubin, "progres tangkap berjalan selama berhenti (timer %.3f detik, jarak ke kucing %.2f)" % [timer, absf(sepeda.jarak_ubin - t3.maju_ubin)])
	_sentuh(0, TITIK_STICK, false)
	_bersihkan(akar)
