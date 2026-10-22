class_name TesKucingDitangkap
extends RefCounted
## Tes pose kucing ditangkap (run 20261022-fase5c-animasi-simpang, bagian B: AC-9, AC-10): pemilih frame murni `PoseKucing` dengan oracle literal, JSON sheet =
## konstanta, garis tanah pose sama, dan di scene rute: duduk selama progres 0 dan langkah lihat, ditangkap (dua frame 3 fps) selama progres tangkap > 0, jeda
## membekukan frame, posisi, offset, kotak badan, penutup, dan hiasan tidak berubah antar pose.
##
## Dipanggil dari `tests/run_tests.gd`. Tidak menyentuh berkas save.

const BERKAS_RUTE: String = "res://scenes/rute/rute.tscn"
const BERKAS_JSON: String = "res://assets/sprites/npc/mission_kucing_sheet.json"
const BERKAS_PNG: String = "res://assets/sprites/npc/mission_kucing_sheet.png"
const DT: float = 1.0 / 60.0
## Frame Sprite2D harapan (baris 1 "masuk" x 9 kolom): duduk 9, ditangkap_1 16, ditangkap_2 17.
const F_DUDUK: int = 9
const F_TANGKAP_1: int = 16
const F_TANGKAP_2: int = 17

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
	_test_json_dan_png()
	await _test_scene()


func _test_murni() -> void:
	_judul.call("PoseKucing: duduk, ditangkap dua frame 3 fps hanya di langkah tangkap dengan progres > 0 (AC-9 run 5C, oracle literal)")
	var kasus: Array = [
		["tangkap", 0.0, 0.0, F_DUDUK], ["tangkap", 0.0, 0.5, F_DUDUK], ["tangkap", 0.000000001, 0.0, F_TANGKAP_1], ["tangkap", 1.0, 0.0, F_TANGKAP_1],
		["tangkap", 0.5, 0.3333, F_TANGKAP_1], ["tangkap", 0.5, 1.0 / 3.0, F_TANGKAP_2], ["tangkap", 0.5, 0.5, F_TANGKAP_2], ["tangkap", 0.5, 2.0 / 3.0, F_TANGKAP_1],
		["tangkap", 0.5, 1.0, F_TANGKAP_2], ["tangkap", 0.5, 10.0, F_TANGKAP_1], ["tangkap", 0.5, NAN, F_TANGKAP_1], ["tangkap", 0.5, -2.0, F_TANGKAP_1], ["tangkap", 0.5, -0.2, F_TANGKAP_1],
		["tangkap", NAN, 0.5, F_DUDUK], ["tangkap", -0.2, 0.5, F_DUDUK], ["tangkap", INF, 0.5, F_DUDUK],
		["lihat", 0.5, 0.5, F_DUDUK], ["lihat", 1.0, 0.0, F_DUDUK], ["", 0.5, 0.5, F_DUDUK], ["kabur", 0.5, 0.5, F_DUDUK], ["petunjuk", 0.5, 0.5, F_DUDUK], ["Tangkap", 0.5, 0.5, F_DUDUK],
	]
	var beda: Array[String] = []
	for k: Array in kasus:
		var f: int = PoseKucing.frame(k[0], k[1], k[2])
		if f != int(k[3]):
			beda.append("%s p%s t%s: %d (harap %d)" % [k[0], k[1], k[2], f, k[3]])
	check(beda.is_empty(), "%d kasus literal (progres 0/0+/1, batas 1/3 detik, NaN, langkah lain); beda: %s" % [kasus.size(), beda])
	# Waktu dari langkah 1/60 yang dijumlahkan (seperti `_detik_misi`): 100 langkah = 5/3 detik (jumlah float 1,6666666666666656, x 3 = 4,9999999999999964)
	# = segmen ke-5 = frame kedua berkat toleransi (tanpa toleransi segmen ke-4).
	var t: float = 0.0
	for i: int in range(100):
		t += DT
	check(t < 5.0 / 3.0 and PoseKucing.frame("tangkap", 0.5, t) == F_TANGKAP_2, "100 langkah 1/60 dijumlahkan (%.17f) = frame kedua (toleransi batas)" % t)
	var urutan: Array[int] = []
	for i: int in range(120):
		var f: int = PoseKucing.frame("tangkap", 0.5, float(i) / 60.0)
		if urutan.is_empty() or urutan[urutan.size() - 1] != f:
			urutan.append(f)
	var harapan_urut: Array[int] = [16, 17, 16, 17, 16, 17]
	check(urutan == harapan_urut, "2 detik: berganti tiap 1/3 detik (6 segmen), dapat %s" % [urutan])
	check(PoseKucing.kolom("tangkap", 0.5, 0.0) == 7 and PoseKucing.kolom("tangkap", 0.5, 0.4) == 8 and PoseKucing.kolom("tangkap", 0.0, 0.4) == 0, "kolom 7, 8, dan 0 (duduk)")
	check(PoseKucing.frame("tangkap", 0.7, 0.25) == PoseKucing.frame("tangkap", 0.7, 0.25), "waktu sama (jeda) = frame sama")


func _test_json_dan_png() -> void:
	_judul.call("Sheet kucing: JSON = konstanta (9 kolom, ditangkap kolom 7-8, 3 fps), garis tanah pose sama (AC-10 run 5C)")
	var json: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BERKAS_JSON)) as Dictionary
	var frames: Array = json["frames"]
	check(int(json["columns"]) == 9 and Config.MISI_KUCING_KOLOM == 9 and frames.size() == 9, "JSON columns 9 = MISI_KUCING_KOLOM = jumlah frames")
	check(Config.MISI_KUCING_KOLOM_DITANGKAP == [7, 8] and frames[7] == "ditangkap_1" and frames[8] == "ditangkap_2", "kolom ditangkap [7, 8] = frames ditangkap_1/_2")
	check((json["anim"] as Dictionary).get("ditangkap", []) == [frames[7], frames[8]], "anim.ditangkap = [ditangkap_1, ditangkap_2]")
	check(Config.MISI_KUCING_DITANGKAP_FPS == 3.0 and float((json["fps"] as Dictionary).get("ditangkap", 0)) == Config.MISI_KUCING_DITANGKAP_FPS, "fps.ditangkap 3 = MISI_KUCING_DITANGKAP_FPS")
	check(Config.MISI_KUCING_BARIS_HADAP == 1 and json["row_names"][1] == "masuk" and frames[0] == "duduk", "baris hadap 1 = masuk, kolom 0 = duduk")
	var img: Image = (load(BERKAS_PNG) as Texture2D).get_image()
	var bawah: Array[int] = []
	for kolom: int in [0, 7, 8]:
		var paling_bawah: int = -1
		for y: int in range(38):
			for x: int in range(46):
				if img.get_pixel(kolom * 46 + x, 38 + y).a8 >= 250:
					paling_bawah = y
		bawah.append(paling_bawah)
	check(bawah[0] >= 0 and bawah[0] == bawah[1] and bawah[1] == bawah[2], "baris masuk: piksel opak terbawah duduk, ditangkap_1, ditangkap_2 sama (garis tanah tidak melompat), dapat %s" % [bawah])


func _test_scene() -> void:
	_judul.call("Scene rute: kucing duduk lalu ditangkap selama progres > 0, jeda membekukan, posisi dan hiasan tidak berubah (AC-9, AC-10 run 5C)")
	_tree.root.size = Vector2i(2340, 1080)
	var misi: DataMisi = PemuatMisi.muat_folder().cari("p1_kucing")
	var akar: RuteMain = (load(BERKAS_RUTE) as PackedScene).instantiate() as RuteMain
	akar.atur_benih_awal(SeedHari.rute(1))
	akar.atur_misi(misi)
	_tree.root.add_child(akar)
	await _tree.process_frame
	await _tree.process_frame
	akar.set_process(false)
	(akar.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = false
	(akar.find_child("LoperAgen", true, false) as LoperSprite).set_process(false)
	var sepeda: SepedaUji = akar.find_child("Sepeda", true, false) as SepedaUji
	var kucing: KucingMisi = akar.kucing()
	var rencana: RencanaMisi.Rencana = akar.rencana_misi()
	# Langkah lihat: kucing tampil, selalu duduk.
	var salah_lihat: Array[String] = []
	var t1: RencanaMisi.Titik = rencana.titik[0]
	for i: int in range(240):
		_letakkan(sepeda, t1.maju_ubin - 9.0 + float(i) * 0.05, 0.5, Config.KECEPATAN_SANTAI_UD)
		akar.perbarui(DT)
		if kucing.tampil() and kucing.badan().frame != F_DUDUK:
			salah_lihat.append("%d: %d" % [i, kucing.badan().frame])
	check(salah_lihat.is_empty(), "langkah lihat: frame duduk selalu; salah %s" % [salah_lihat])
	for t: RencanaMisi.Titik in [rencana.titik[0], rencana.titik[1]]:
		_letakkan(sepeda, t.maju_ubin + 0.5, 0.5, Config.KECEPATAN_SANTAI_UD)
		akar.perbarui(DT)
	var t3: RencanaMisi.Titik = rencana.titik[2]
	# Mendekat cepat (progres 0): duduk.
	_letakkan(sepeda, t3.maju_ubin - 4.0, 0.5, Config.KECEPATAN_SANTAI_UD)
	akar.perbarui(DT)
	var posisi_duduk: Vector2 = kucing.position
	var offset_duduk: Vector2 = kucing.badan().offset
	var rect_duduk: Rect2 = kucing.rect_badan()
	var kilau_duduk: Array = _kilau(kucing)
	check(akar.keadaan_misi().langkah == 2 and kucing.tampil() and akar.keadaan_misi().timer_detik == 0.0 and kucing.badan().frame == F_DUDUK, "langkah tangkap, progres 0: duduk (frame %d)" % kucing.badan().frame)
	# Diam di dekat kucing: progres naik, frame ditangkap bergantian.
	var frame_terlihat: Dictionary = {}
	var salah: Array[String] = []
	var langkah_berganti: Array[int] = []
	var lalu: int = -1
	for i: int in range(60):
		_letakkan(sepeda, t3.maju_ubin - 1.2, -1.0, 0.0)
		akar.perbarui(DT)
		var timer: float = akar.keadaan_misi().timer_detik
		var f: int = kucing.badan().frame
		frame_terlihat[f] = true
		var harap_tangkap: bool = timer > 0.0
		if harap_tangkap != (f == F_TANGKAP_1 or f == F_TANGKAP_2):
			salah.append("%d timer %.3f frame %d" % [i, timer, f])
		if kucing.position != posisi_duduk or kucing.badan().offset != offset_duduk or kucing.rect_badan() != rect_duduk:
			salah.append("%d posisi/offset/kotak berubah" % i)
		if lalu >= 0 and f != lalu:
			langkah_berganti.append(i)
		lalu = f
	check(salah.is_empty() and frame_terlihat.has(F_TANGKAP_1) and frame_terlihat.has(F_TANGKAP_2), "60 langkah diam: frame ditangkap iff progres > 0, kedua frame tampil, posisi %s offset %s kotak tetap; salah %s" % [posisi_duduk, offset_duduk, salah])
	var jarak_ganti: Array[int] = []
	for j: int in range(1, langkah_berganti.size()):
		jarak_ganti.append(langkah_berganti[j] - langkah_berganti[j - 1])
	check(not jarak_ganti.is_empty() and jarak_ganti.all(func(d: int) -> bool: return d == 20), "berganti tiap 20 langkah (3 fps), jarak %s" % [jarak_ganti])
	check(kilau_duduk.size() == 1 and _kilau(kucing) == kilau_duduk, "hiasan kilau: satu item sprite, nama dan pojok sama dengan saat duduk %s, dapat %s" % [kilau_duduk, _kilau(kucing)])
	check(KucingHiasan.perintah_progres(akar.keadaan_misi().timer_detik / t3.lama_berhenti_detik).size() > 0, "bar progres tetap dari KucingHiasan.perintah_progres (tidak diubah run 5C)")
	# Jeda membekukan frame.
	var sebelum: Array = [kucing.badan().frame, akar.keadaan_misi().timer_detik]
	akar.minta_jeda()
	for i: int in range(90):
		_letakkan(sepeda, t3.maju_ubin - 1.2, -1.0, 0.0)
		akar.perbarui(DT)
	# Waktu dinding berjalan sekitar 1/3 detik selama jeda: frame tetap (pose dari waktu animasi misi, bukan waktu dinding).
	OS.delay_msec(340)
	_letakkan(sepeda, t3.maju_ubin - 1.2, -1.0, 0.0)
	akar.perbarui(DT)
	check(akar.sedang_jeda() and [kucing.badan().frame, akar.keadaan_misi().timer_detik] == sebelum, "90 langkah jeda + 0,34 detik waktu dinding: frame dan timer tetap %s" % [sebelum])
	akar.minta_lanjut()
	_tree.root.remove_child(akar)
	akar.free()


## Posisi item kilau (posisi pojok dan nama sprite) hiasan kucing.
func _kilau(kucing: KucingMisi) -> Array:
	var hasil: Array = []
	for item: DefSprite.Item in kucing.hiasan().item_sprite():
		hasil.append([item.nama, item.pojok])
	return hasil


func _letakkan(sepeda: SepedaUji, maju: float, lateral: float, v: float) -> void:
	sepeda.jarak_ubin = maxf(maju, 0.0)
	var k: BikeMotion.Keadaan = sepeda.keadaan.salin()
	k.lateral_ubin = lateral
	k.kecepatan_ud = v
	sepeda.keadaan = k
