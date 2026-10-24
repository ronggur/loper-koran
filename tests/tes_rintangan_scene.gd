class_name TesRintanganScene
extends RefCounted
## Tes run fase3b-rintangan-skor bagian B: rintangan, tabrakan, skor, dan bel di scene rute sungguhan (`scenes/rute/rute.tscn`) plus
## logika murni kecil bagian B (kedip kebal, frame bel, umpan balik melayang, zona bel, pelacak jari bel). Tabrakan = jatuh sejak keputusan
## pemilik 2026-10-17 (oleng dihapus): sprite jatuh lalu terjerembab, kecepatan 0, stick dan lemparan diabaikan, kebal sejak bangun.
## Event sentuh sintetis lewat `Input.parse_input_event` (pola `tes_rute_scene.gd`), langkah `perbarui(dt)` dengan dt tetap.
## Harapan ditulis literal (QA-008 run 2A, QA-001 run 3A):
## - Rintangan rute seed bawaan 20261016 (ditulis dari data segmen): anjing seberang 36, mobil seberang 45, anjing dekat 56, mobil 73,
##   anjing dekat 94, mobil 113, anjing dekat 124, mobil 133, anjing seberang 162, anjing dekat 190, mobil 201 (maju, ubin). Mobil
##   di celah samping rumah (keputusan pemilik 2026-10-17; dulu 46, 74, 114, 132, 202 menembus tapak rumah).
## - Letak layar dari rumus iso 2:1 ditulis ulang: layar = ((lateral + maju) x 32, (lateral - maju) x 16).
## - Skor: tepat santai 100 x 1,25 = 125, antaran kedua (combo x1,1) 110; koin 15 per antaran; nada combo ke-2 = 2^(1/12) = 1,059463.

const BERKAS_RUTE: String = "res://scenes/rute/rute.tscn"
const BERKAS_JALAN_UJI: String = "res://scenes/dev/jalan_uji.tscn"
const BERKAS_ANJING_JSON: String = "res://assets/sprites/obstacles/obs_anjing_sheet.json"
const BERKAS_MOBIL_JSON: String = "res://assets/sprites/obstacles/obs_mobil_garasi_sheet.json"
const BERKAS_BEL_JSON: String = "res://assets/sprites/ui/ui_bel.json"
const SKALA: int = 3
const DT: float = 1.0 / 60.0
const LEBAR: int = 780
const TOL: float = 0.000001
const TITIK_STICK: Vector2 = Vector2(100, 260)
## [jenis data, maju, jalur] rintangan rute seed bawaan, urut id.
const RINTANGAN_DEV: Array = [
	["anjing_penjaga", 36.0, "seberang"], ["mobil_garasi", 45.0, "seberang"], ["anjing_penjaga", 56.0, "dekat"],
	["mobil_garasi", 73.0, "seberang"], ["anjing_penjaga", 94.0, "dekat"], ["mobil_garasi", 113.0, "seberang"],
	["anjing_penjaga", 124.0, "dekat"], ["mobil_garasi", 133.0, "seberang"], ["anjing_penjaga", 162.0, "seberang"],
	["anjing_penjaga", 190.0, "dekat"], ["mobil_garasi", 201.0, "seberang"],
]
const PITCH_NADA_1: float = 1.059463

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
	_test_scene_sprite_rintangan()
	await _test_rintangan_digambar()
	await _test_penutup_rintangan()
	await _test_tabrakan_dari_scene()
	await _test_tabrakan_mobil_dari_scene()
	await _test_bunyi_tanda_rintangan_di_scene()
	await _test_jeda_membekukan()
	await _test_skor_di_scene()
	await _test_bunyi_tip_di_scene()
	await _test_tip_sesudah_tenggat_di_scene()
	await _test_putus_antaran_tidak_sah_di_scene()
	await _test_bel_input()
	await _test_bel_anjing_mundur()
	await _test_main_lagi()
	await _test_jalan_uji()


# --- Pembantu ---

func _siapkan() -> RuteMain:
	_tree.root.size = Vector2i(2340, 1080)
	var akar: RuteMain = (load(BERKAS_RUTE) as PackedScene).instantiate() as RuteMain
	_tree.root.add_child(akar)
	await _tree.process_frame
	await _tree.process_frame
	akar.set_process(false)
	(_anak(akar, "KontrolTouch") as KontrolTouch).keyboard_aktif = false
	(_anak(akar, "LoperAgen") as LoperSprite).set_process(false)
	return akar


func _bersihkan(akar: AdeganJalan) -> void:
	for i: int in range(8):
		_sentuh(i, Vector2(-50, -50), false)
	if akar.sedang_jeda():
		akar.minta_lanjut()
	(_anak(akar, "KontrolTouch") as KontrolTouch).keyboard_aktif = OS.has_feature("editor")
	_tree.root.remove_child(akar)
	akar.free()


func _anak(akar: Node, nama: String) -> Node:
	return akar.find_child(nama, true, false)


func _sepeda(akar: Node) -> SepedaUji:
	return _anak(akar, "Sepeda") as SepedaUji


## HUD rute final (run fase3c-hud-hasil; dulu `HudDev`). Jalan uji memakai `_anak(akar, "Hud") as HudDev`.
func _hud(akar: Node) -> HudRute:
	return _anak(akar, "Hud") as HudRute


## Mode bantu dinyalakan lewat sakelar layar jeda (O-6; HUD rute tidak punya tombol dev).
func _nyalakan_bantu(akar: AdeganJalan) -> void:
	if not akar.mode_bantu():
		(_anak(akar, "LayarJeda") as LayarJeda).sakelar_bantu().ditekan.emit()


## Kidal dinyalakan lewat sakelar layar jeda (O-6).
func _nyalakan_kidal(akar: AdeganJalan) -> void:
	if not akar.kidal():
		(_anak(akar, "LayarJeda") as LayarJeda).sakelar_kidal().ditekan.emit()


func _kontrol(akar: Node) -> KontrolTouch:
	return _anak(akar, "KontrolTouch") as KontrolTouch


func _audio() -> Node:
	return _tree.root.get_node_or_null(^"Audio")


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


func _langkah(akar: AdeganJalan, jumlah: int, dt: float = DT) -> void:
	for i: int in range(jumlah):
		akar.perbarui(dt)


func _taruh(akar: AdeganJalan, v: float, lateral: float, maju: float) -> void:
	var sepeda: SepedaUji = _sepeda(akar)
	var k: BikeMotion.Keadaan = sepeda.keadaan.salin()
	k.kecepatan_ud = v
	k.lateral_ubin = lateral
	sepeda.keadaan = k
	sepeda.jarak_ubin = maju
	akar.perbarui(0.0)


## Letak layar titik (lateral, maju) dari rumus iso 2:1 ditulis ulang tes.
func _layar(lateral: float, maju: float) -> Vector2:
	return Vector2(roundf((lateral + maju) * 32.0), roundf((lateral - maju) * 16.0))


func _baca_json(jalur: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(jalur)) as Dictionary


# --- Murni bagian B ---

func _test_murni() -> void:
	_judul.call("Bagian B murni: kedip kebal, frame bel, umpan melayang, zona dan jari bel")
	var t: Tabrakan.Keadaan = Tabrakan.awal()
	check(Tabrakan.alfa_kebal(t) == 1.0, "tanpa tabrakan: alfa 1,0")
	var kasus_kebal: Array = [[1.0, 1.0], [0.95, 1.0], [0.85, 0.5], [0.75, 1.0], [0.65, 0.5], [0.05, 0.5], [0.0, 1.0]]
	for k: Array in kasus_kebal:
		t.kebal_detik = k[0]
		check(Tabrakan.alfa_kebal(t) == k[1], "kebal sisa %.2f detik: alfa %.1f (kedip tiap 0,1 detik)" % [k[0], k[1]])
	# Bel: frame efek, getar, teks naik, redup, frame tombol.
	var b: Bel.Keadaan = Bel.awal()
	check(Bel.frame_efek(b) == -1 and Bel.frame_getar(b) == -1 and Bel.naik_teks_px(b) == 0 and not Bel.teks_redup(b), "bel diam: tanpa efek")
	b = Bel.ketuk(b, false).keadaan
	check(Bel.frame_efek(b) == 0 and Bel.frame_getar(b) == 0 and Bel.naik_teks_px(b) == 0, "baru diketuk: frame 0, getar 0, teks belum naik")
	var b2: Bel.Keadaan = Bel.langkah(b, 0.26)
	check(Bel.frame_efek(b2) == 3 and Bel.frame_getar(b2) == 3 and Bel.naik_teks_px(b2) == 3, "0,26 detik: frame 3 (12 fps), getar frame terakhir, teks naik 3 px")
	var b3: Bel.Keadaan = Bel.langkah(b, 0.34)
	check(Bel.frame_efek(b3) == 4 and Bel.frame_getar(b3) == -1 and Bel.naik_teks_px(b3) == 4 and not Bel.teks_redup(b3), "0,34 detik: getar habis, teks naik paling banyak 4 px, belum redup")
	var b4: Bel.Keadaan = Bel.langkah(b, 0.45)
	check(Bel.teks_tampil(b4) and Bel.teks_redup(b4) and Bel.naik_teks_px(b4) == 4, "0,45 detik (sisa 0,05 <= satu frame): teks redup")
	var kasus_tombol: Array = [[false, 0.0, 0], [true, 0.0, 1], [true, 1.0, 2], [false, 1.0, 2], [false, 0.9, 2], [false, 0.8, 3], [false, 0.5, 6], [false, 0.13, 8], [false, 0.12, 9], [false, 0.01, 9]]
	for k: Array in kasus_tombol:
		check(Bel.frame_tombol(k[0], k[1]) == k[2], "frame tombol bel: ditekan %s, sisa jeda %.2f -> %d" % [k[0], k[1], k[2]])
	# Umpan balik melayang.
	var hs: SkorRute.Hasil = SkorRute.Hasil.new()
	hs.status = SkorRute.Status.ANTAR
	hs.koin_tambah = 20
	hs.tip = 5
	hs.tepat = false
	var e: UmpanMelayang.Entri = UmpanMelayang.dari_hasil(hs, Vector2(-2.0, -10.0))
	check(e != null and e.ongkos == 15 and e.tip == 5 and not e.tepat and is_equal_approx(e.sisa_detik, 0.8), "antaran teras ke pemberi tip: entri +15, tip 5, 0,8 detik")
	hs.status = SkorRute.Status.ULANG
	check(UmpanMelayang.dari_hasil(hs, Vector2.ZERO) == null, "koran ulang (netral): tanpa umpan balik melayang")
	var daftar: Array[UmpanMelayang.Entri] = []
	for i: int in range(3):
		var baru: UmpanMelayang.Entri = UmpanMelayang.Entri.new()
		baru.ongkos = 10 + i
		baru.sisa_detik = 0.8
		daftar = UmpanMelayang.tambah(daftar, baru)
	check(daftar.size() == 2 and daftar[0].ongkos == 11 and daftar[1].ongkos == 12, "paling banyak dua sekaligus, yang lama hilang lebih dulu")
	var setengah: Array[UmpanMelayang.Entri] = UmpanMelayang.langkah(daftar, 0.4)
	check(setengah.size() == 2 and UmpanMelayang.naik_px(setengah[0]) == 6 and is_equal_approx(UmpanMelayang.alfa(setengah[0]), 0.5) and is_equal_approx(daftar[0].sisa_detik, 0.8), "0,4 detik: naik 6 px, alfa 0,5 (masukan tidak berubah)")
	# QA-012 run 3B (AC-10 run fase3c-hud-hasil, mutan R07): arah naik dijaga oracle literal di awal dan akhir, bukan hanya titik tengah.
	var e_naik: UmpanMelayang.Entri = UmpanMelayang.Entri.new()
	var tabel_naik: Array = [[0.8, 0, 1.0], [0.6, 3, 0.75], [0.2, 9, 0.25], [0.0, 12, 0.0]]
	for baris: Array in tabel_naik:
		e_naik.sisa_detik = baris[0]
		check(UmpanMelayang.naik_px(e_naik) == baris[1] and is_equal_approx(UmpanMelayang.alfa(e_naik), baris[2]), "umpan melayang sisa %s detik: naik %d px (dari titik muncul ke atas), alfa %s" % [baris[0], baris[1], baris[2]])
	check(UmpanMelayang.langkah(daftar, 0.0).size() == 2 and UmpanMelayang.langkah(daftar, 0.81).is_empty(), "dt 0 membeku; sesudah 0,8 detik hilang")
	# Zona bel.
	# Masukan uji pemilik 2026-10-17 (PR #33): pusat 64 dari tepi samping dan 64 dari bawah (dulu 28 dan 28, di pojok); kidal dicerminkan mendatar.
	check(Config.BEL_TOMBOL_PUSAT_SAMPING_PX == 64 and Config.BEL_TOMBOL_PUSAT_BAWAH_PX == 64 and Config.BEL_TOMBOL_UKURAN_PX == 40 and is_equal_approx(Config.BEL_ZONA_RADIUS_PX, 28.0), "Config bel: pusat 64 dari samping, 64 dari bawah, tombol 40, radius zona 28")
	for kasus: Array in [[640, false, Vector2(576, 296)], [640, true, Vector2(64, 296)], [780, false, Vector2(716, 296)], [780, true, Vector2(64, 296)], [800, false, Vector2(736, 296)], [800, true, Vector2(64, 296)]]:
		check(TouchZones.pusat_bel(kasus[0], kasus[1]) == kasus[2], "pusat bel lebar %d kidal %s = %s" % [kasus[0], kasus[1], kasus[2]])
	check(TouchZones.zona_di(Vector2(716, 296), 780, false) == TouchZones.Zona.BEL and TouchZones.zona_di(Vector2(688, 296), 780, false) == TouchZones.Zona.BEL and TouchZones.zona_di(Vector2(687, 296), 780, false) == TouchZones.Zona.SWIPE, "zona bel radius 28 inklusif (x 688 bel, x 687 swipe)")
	check(TouchZones.zona_di(Vector2(716, 268), 780, false) == TouchZones.Zona.BEL and TouchZones.zona_di(Vector2(716, 267), 780, false) == TouchZones.Zona.SWIPE, "tepi atas zona bel y 268 inklusif, y 267 swipe")
	check(TouchZones.zona_di(Vector2(64, 296), 780, true) == TouchZones.Zona.BEL and TouchZones.zona_di(Vector2(716, 296), 780, true) == TouchZones.Zona.STICK, "kidal: bel di (64, 296); (716, 296) jadi zona stick")
	# Pelacak jari bel.
	var r: TouchRouter = TouchRouter.new()
	r.lebar_viewport = 780
	var bel: Array = [0]
	r.bel_ditekan.connect(func(_p: Vector2) -> void: bel[0] = int(bel[0]) + 1)
	r.tekan(0, TITIK_STICK, 0.0)
	r.tekan(1, Vector2(716, 296), 0.0)
	r.tekan(1, Vector2(716, 296), 0.0)
	r.geser(1, Vector2(500, 200))
	check(int(bel[0]) == 1 and r.bel_ditahan() and r.stick_aktif() and not r.swipe_aktif(), "stick + bel: bel berbunyi sekali (turun ganda index sama diabaikan), stick tetap; jari bel yang digeser ke zona swipe tidak jadi swipe")
	r.lepas(1, Vector2(500, 200), 0.1)
	check(not r.bel_ditahan() and r.jumlah_swipe_selesai == 0 and r.jumlah_tap_selesai == 0, "jari bel diangkat: bukan swipe dan bukan tap")
	r.tekan(2, Vector2(600, 200), 0.2)
	r.tekan(3, Vector2(716, 296), 0.2)
	check(int(bel[0]) == 2 and r.swipe_aktif() and r.nomor_swipe == 1, "swipe + bel: swipe tetap jalan (nomor tetap), bel berbunyi")
	r.lepas(3, Vector2(716, 296), 0.3)
	r.geser(2, Vector2(716, 296))
	r.lepas(2, Vector2(716, 296), 0.4)
	check(int(bel[0]) == 2 and r.jumlah_swipe_selesai == 1, "swipe yang melewati dan berakhir di tombol bel tetap swipe, tidak membunyikan bel")
	r.tekan(4, Vector2(716, 296), 0.5)
	r.batal_semua()
	check(not r.bel_ditahan(), "batal_semua melepas jari bel")


# --- Sprite rintangan sesuai sheet (AC-20) ---

func _test_scene_sprite_rintangan() -> void:
	_judul.call("Scene anjing dan mobil: SpriteFrames dari sheet, titik pijak dan animasi dari JSON (AC-20)")
	for pasangan: Array in [["res://scenes/entities/anjing_penjaga.tscn", BERKAS_ANJING_JSON], ["res://scenes/entities/mobil_garasi.tscn", BERKAS_MOBIL_JSON]]:
		var json: Dictionary = _baca_json(pasangan[1])
		var sprite: AnimatedSprite2D = (load(pasangan[0]) as PackedScene).instantiate() as AnimatedSprite2D
		var nama: String = (pasangan[0] as String).get_file()
		var anchor: Array = json["ground_anchor"]
		var sel: Array = json["cell"]
		check(not sprite.centered and sprite.offset == Vector2(-float(anchor[0]), -float(anchor[1])) and sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "%s: titik pijak = ground_anchor JSON %s, Nearest" % [nama, anchor])
		var anim: Dictionary = json["anim"]
		var frames: Array = json["frames"]
		var fps: Dictionary = json.get("fps", {})
		var nama_anim: Array[String] = []
		for a: StringName in sprite.sprite_frames.get_animation_names():
			nama_anim.append(String(a))
		nama_anim.sort()
		var harapan_anim: Array[String] = []
		for a: String in anim.keys():
			harapan_anim.append(a)
		harapan_anim.sort()
		check(nama_anim == harapan_anim, "%s: animasi = kunci anim JSON %s" % [nama, harapan_anim])
		var salah: Array[String] = []
		for a: String in anim.keys():
			var isi: Array = anim[a]
			if sprite.sprite_frames.get_frame_count(a) != isi.size():
				salah.append("%s jumlah" % a)
				continue
			if is_instance_valid(sprite.sprite_frames) and absf(sprite.sprite_frames.get_animation_speed(a) - float(fps.get(a, 5))) > TOL:
				salah.append("%s fps" % a)
			for i: int in range(isi.size()):
				var tekstur: AtlasTexture = sprite.sprite_frames.get_frame_texture(a, i) as AtlasTexture
				var kolom: int = frames.find(isi[i])
				if tekstur == null or tekstur.region != Rect2(kolom * int(sel[0]), 0, int(sel[0]), int(sel[1])) or tekstur.atlas.resource_path != "res://assets/sprites/obstacles/" + String(json["sprite"]):
					salah.append("%s frame %d" % [a, i])
		check(salah.is_empty(), "%s: tiap frame = sel kolom JSON di sheet yang sama, fps dari JSON: %s" % [nama, salah])
		sprite.free()
	var bel: Dictionary = _baca_json(BERKAS_BEL_JSON)
	var getar: Dictionary = bel["getar"]
	check(Config.BEL_GETAR_JANGKAR_PX == [int((getar["anchor"] as Array)[0]), int((getar["anchor"] as Array)[1])] and Config.BEL_GETAR_FRAME == int(getar["frames"]) and Config.BEL_EFEK_FPS == float(getar["fps"]), "Config jangkar, jumlah frame, fps garis getar = ui_bel.json")
	var tombol: Dictionary = bel["tombol"]
	check((tombol["frames"] as Array).size() == Bel.FRAME_JEDA_PERTAMA + Config.BEL_TOMBOL_JEDA_LANGKAH and (tombol["frames"] as Array)[Bel.FRAME_JEDA_PERTAMA] == "jeda_8" and (load("res://assets/sprites/ui/ui_bel_tombol.png") as Texture2D).get_width() == 400, "sheet tombol bel: diam, ditekan, 8 frame jeda (400 px)")


# --- Rintangan digambar dan jendela daur (AC-20) ---

func _test_rintangan_digambar() -> void:
	_judul.call("Scene rute: rintangan dari data digambar hidup, jendela daur, Y-sort, posisi iso (AC-20)")
	var akar: RuteMain = await _siapkan()
	var k: RintanganRute.Keadaan = akar.rintangan()
	var data_ok: bool = k.daftar.size() == RINTANGAN_DEV.size()
	for i: int in range(mini(k.daftar.size(), RINTANGAN_DEV.size())):
		var item: RintanganRute.Item = k.daftar[i]
		var maju: float = item.anjing.rumah_maju_ubin if item.jenis == RintanganRute.Jenis.ANJING else item.mobil.maju_ubin
		if item.nama_jenis != RINTANGAN_DEV[i][0] or maju != RINTANGAN_DEV[i][1]:
			data_ok = false
	check(data_ok, "rintangan scene = objek data rute seed bawaan (11, jenis dan maju literal)")
	var daur: RintanganDaur = akar.rintangan_daur()
	var objek: Node2D = _anak(akar, "Objek") as Node2D
	check(daur.get_parent() == objek and objek.y_sort_enabled and daur.y_sort_enabled and _sepeda(akar).get_parent() == objek, "induk rintangan anak Objek (Y-sort) bersama sepeda dan rumah, y_sort_enabled sendiri")
	var kasus: Array = [[0.0, []], [10.0, [0]], [30.0, [0, 1, 2]], [100.0, [4, 5, 6]], [150.0, [7, 8]], [200.0, [9, 10]]]
	var maks_node: int = 0
	for kk: Array in kasus:
		_taruh(akar, 3.0, 0.5, kk[0])
		var harapan: Array[int] = []
		harapan.assign(kk[1])
		check(daur.id_tampil() == harapan, "jarak %.0f: rintangan tampil %s (jendela maju - 20 sampai maju + 30), dapat %s" % [kk[0], harapan, daur.id_tampil()])
		maks_node = maxi(maks_node, daur.jumlah_node())
	check(maks_node <= 5, "node sprite rintangan dipakai ulang dari kolam (paling banyak %d dibuat)" % maks_node)
	_taruh(akar, 3.0, 0.5, 30.0)
	var anjing: AnimatedSprite2D = daur.sprite_rintangan(0)
	var mobil: AnimatedSprite2D = daur.sprite_rintangan(1)
	var anjing_dekat: AnimatedSprite2D = daur.sprite_rintangan(2)
	check(anjing != null and anjing.position == _layar(-2.75, 36.0) and anjing.position == Vector2(1064, -620) and anjing.animation == &"diam" and not anjing.flip_h, "anjing seberang diam di halaman: layar (1064, -620), animasi diam, tidak dicermin")
	check(mobil != null and mobil.position == _layar(-3.25, 45.0) and mobil.position == Vector2(1336, -772) and mobil.animation == &"parkir", "mobil parkir: pusat tapak lateral -3,25 di layar (1336, -772), animasi parkir")
	check(anjing_dekat != null and anjing_dekat.position == Vector2(1880, -852) and anjing_dekat.flip_h, "anjing dekat diam: layar (1880, -852), dicermin (menghadap sepeda yang datang)")
	check(RintanganDaur.ikon_seru(anjing) != null and not RintanganDaur.ikon_seru(anjing).visible, "ikon ! anjing tersembunyi saat tidak kaget")
	# Hidup: anjing waspada lalu mengejar, mobil tanda lalu mundur.
	_taruh(akar, 3.0, 1.0, 28.0)
	_langkah(akar, 1)
	check(anjing.animation == &"tanda" and akar.rintangan().daftar[0].anjing.status == AnjingPenjaga.Status.WASPADA, "sepeda 8 ubin sebelum anjing: animasi tanda (waspada)")
	_taruh(akar, 3.0, 1.0, 36.2)
	_langkah(akar, 1)
	check(anjing.animation == &"lari" and not anjing.flip_h, "sepeda melewati anjing: animasi lari menghadap maju")
	_taruh(akar, 3.0, 1.0, 38.0)
	_langkah(akar, 1)
	check(mobil.animation == &"tanda", "sepeda 7 ubin sebelum mobil 45 (tanda sejak 36): animasi tanda (lampu mundur berkedip)")
	_langkah(akar, 100)
	check(mobil.animation == &"mundur" and mobil.position != _layar(-3.25, 45.0), "1,7 detik kemudian: animasi mundur, mobil bergeser ke jalan")
	_bersihkan(akar)


# --- Penutup (AC-20: satu PenerapPenutup) ---

func _test_penutup_rintangan() -> void:
	_judul.call("Scene rute: rintangan yang menutupi pemain semi-transparan lewat penerap yang sama (AC-20)")
	var akar: RuteMain = await _siapkan()
	var penerap: PenerapPenutup = akar.penerap_penutup()
	check(akar.find_children("*", "PenerapPenutup", true, false).size() == 1, "hanya satu PenerapPenutup")
	# Mobil 45 sampai berhenti di garis tengah: sepeda ditahan di maju 38,5 sisi dekat.
	for i: int in range(400):
		_taruh(akar, 0.0, 1.5, 38.5)
		akar.perbarui(DT)
	var mobil: RintanganRute.Item = akar.rintangan().daftar[1]
	check(mobil.mobil.status == MobilGarasi.Status.BERHENTI, "mobil seberang berhenti di garis tengah")
	var gambar: AnimatedSprite2D = akar.rintangan_daur().sprite_rintangan(1)
	# Tapak mobil berhenti lateral -1,5..0, maju 44,625..45,375, tinggi 1,0. Kaki di (-2,0; 45,5): titik (+d, -d) untuk d 0,6 = (-1,4; 44,9) di
	# tapak, z 0,6 <= 1,0 -> tertutup. Di lateral +1,0 tidak ada d >= 0 yang masuk tapak.
	_taruh(akar, 0.0, -2.0, 45.5)
	check(is_equal_approx(gambar.modulate.a, 0.45) and penerap.jumlah_menutupi() >= 1, "kaki pemain di balik mobil (-2,0; 45,5): mobil alfa 0,45, dapat %.2f" % gambar.modulate.a)
	_taruh(akar, 0.0, 1.0, 45.5)
	check(gambar.modulate.a == 1.0, "pemain di sisi dekat: mobil alfa 1,0")
	_bersihkan(akar)


# --- Tabrakan dari scene (AC-6, AC-8) ---

func _test_tabrakan_dari_scene() -> void:
	_judul.call("Scene rute: tabrakan = jatuh, jenis penyebab, kecepatan 0, stick dan lemparan diabaikan, bangun, kebal, visual dan bunyi (AC-6, AC-8)")
	var akar: RuteMain = await _siapkan()
	var audio: Node = _audio()
	var tabrak: Array[String] = []
	var kecepatan_saat: Array[float] = []
	var dilempar: Array[ThrowSolver.Lintasan] = []
	akar.tabrakan.connect(func(jenis: String) -> void:
		tabrak.append(jenis)
		kecepatan_saat.append(_sepeda(akar).kecepatan_ud))
	akar.koran_dilempar.connect(func(l: ThrowSolver.Lintasan) -> void: dilempar.append(l))
	var skor: SkorRute.Keadaan = SkorRute.awal()
	skor.beruntun = 3
	akar.set(&"_skor", skor)
	var bunyi_awal: int = int(audio.call(&"jumlah_bunyi_rute", BunyiRute.Bunyi.TABRAKAN)) if audio != null else 0
	_taruh(akar, 3.0, -0.6, 30.0)
	var langkah: int = 0
	while tabrak.is_empty() and langkah < 600:
		akar.perbarui(DT)
		langkah += 1
	var sepeda: SepedaUji = _sepeda(akar)
	var jarak_jatuh: float = sepeda.jarak_ubin
	var lateral_jatuh: float = sepeda.lateral_ubin
	var koran_awal: int = akar.koran.sisa
	check(tabrak == ["anjing_penjaga"], "santai di sisi anjing (lateral -0,6): tabrakan pertama dari anjing_penjaga (sinyal membawa jenis), dapat %s" % [tabrak])
	check(kecepatan_saat.size() == 1 and kecepatan_saat[0] == 0.0, "saat sinyal: kecepatan sudah 0 (jatuh)")
	check(akar.skor().beruntun == 0 and _hud(akar).teks_combo() == "x1.0" and _hud(akar).putus_tampil(), "combo putus: x1.0 dan label PUTUS di HUD")
	check(audio == null or int(audio.call(&"jumlah_bunyi_rute", BunyiRute.Bunyi.TABRAKAN)) == bunyi_awal + 1, "satu bunyi tabrakan")
	check(sepeda.sedang_jatuh() and sepeda.nama_animasi() == &"jatuh_normal" and sepeda.frame_sprite() == 0 and sepeda.efek().ikon_tabrakan_tampil() and sepeda.alfa_sprite() == 1.0, "langkah tabrakan: sprite jatuh_normal frame 0, ikon kilatan tampil, alfa penuh; dapat %s f%d" % [sepeda.nama_animasi(), sepeda.frame_sprite()])
	check(not sepeda.efek().perintah_tabrakan().is_empty(), "ikon kilatan menghasilkan perintah gambar")
	# Stick ditahan penuh ke atas dan ke sisi dekat selama jatuh: diabaikan.
	_sentuh(0, TITIK_STICK, true)
	_geser(0, TITIK_STICK + Vector2(25, -35))
	_langkah(akar, 6)
	check(sepeda.nama_animasi() == &"jatuh_normal" and sepeda.frame_sprite() == 1, "0,1 detik: jatuh_normal frame 1 (10 fps), dapat %s f%d" % [sepeda.nama_animasi(), sepeda.frame_sprite()])
	# Swipe dan tap mode bantu selama jatuh: ditolak, koran tidak berkurang, garis bidik tidak tampil.
	_sentuh(1, Vector2(500, 220), true)
	_geser(1, Vector2(500, 150))
	_langkah(akar, 1)
	check(not akar.garis_bidik().tampil(), "swipe ditahan selama jatuh: garis bidik tidak tampil")
	_sentuh(1, Vector2(500, 150), false)
	akar.atur_mode_bantu(true)
	_sentuh(2, Vector2(600, 200), true)
	_sentuh(2, Vector2(600, 200), false)
	akar.atur_mode_bantu(false)
	check(dilempar.is_empty() and akar.koran.sisa == koran_awal and not sepeda.sedang_melempar(), "swipe dan tap mode bantu selama jatuh ditolak: koran tetap %d, tanpa animasi lempar" % koran_awal)
	_langkah(akar, 17)
	check(sepeda.nama_animasi() == &"terjerembab_normal" and sepeda.frame_sprite() == 0, "0,4 detik: terjerembab_normal frame 0 (3 fps), dapat %s f%d" % [sepeda.nama_animasi(), sepeda.frame_sprite()])
	_langkah(akar, 47)
	check(Tabrakan.jatuh(akar.rintangan().tabrakan) and sepeda.sedang_jatuh() and sepeda.nama_animasi() == &"bangkit_normal" and sepeda.frame_sprite() == 5, "1,183 detik (71 langkah): masih jatuh, bangkit_normal frame terakhir (Fase 5C: bangkit di 0,6 detik terakhir), dapat %s f%d" % [sepeda.nama_animasi(), sepeda.frame_sprite()])
	check(sepeda.kecepatan_ud == 0.0 and sepeda.jarak_ubin == jarak_jatuh and sepeda.lateral_ubin == lateral_jatuh, "selama jatuh: kecepatan 0, jarak dan lateral tidak berubah walau stick penuh ditahan")
	check(not _hud(akar).putus_tampil(), "label PUTUS hilang sesudah 0,8 detik")
	_langkah(akar, 1)
	var t: Tabrakan.Keadaan = akar.rintangan().tabrakan
	check(not Tabrakan.jatuh(t) and Tabrakan.kebal(t) and not sepeda.sedang_jatuh() and not sepeda.efek().ikon_tabrakan_tampil(), "1,2 detik (72 langkah): bangun, kebal mulai, sprite keluar dari jatuh, ikon hilang")
	check(not String(sepeda.nama_animasi()).begins_with("jatuh") and not String(sepeda.nama_animasi()).begins_with("terjerembab"), "sesudah bangun sprite kembali ke animasi kayuh, dapat %s" % sepeda.nama_animasi())
	_langkah(akar, 1)
	check(is_equal_approx(sepeda.kecepatan_ud, 0.05) and sepeda.lateral_ubin > lateral_jatuh and String(sepeda.nama_animasi()).begins_with("ngebut_"), "langkah sesudah bangun: stick berlaku lagi (kecepatan 0,05 = 3,0/60, lateral bergerak, ngebut), dapat %.4f %s" % [sepeda.kecepatan_ud, sepeda.nama_animasi()])
	_langkah(akar, 6)
	check(sepeda.alfa_sprite() == 0.5, "bangun + 0,117 detik: kedip kebal redup 0,5")
	_langkah(akar, 52)
	check(Tabrakan.kebal(akar.rintangan().tabrakan), "bangun + 0,983 detik (59 langkah): masih kebal")
	_langkah(akar, 1)
	check(not Tabrakan.kebal(akar.rintangan().tabrakan) and sepeda.alfa_sprite() == 1.0, "bangun + 1,0 detik (60 langkah): kebal habis, alfa 1,0")
	check(tabrak.size() == 1, "tidak ada tabrakan kedua selama jatuh maupun kebal")
	_sentuh(0, TITIK_STICK, false)
	# Sesudah bangun lemparan diterima lagi.
	akar.koran = SisaKoran.langkah(akar.koran, Config.LEMPAR_JEDA_DETIK)
	_sentuh(1, Vector2(500, 220), true)
	_geser(1, Vector2(500, 150))
	_langkah(akar, 1)
	_sentuh(1, Vector2(500, 150), false)
	check(dilempar.size() == 1 and akar.koran.sisa == koran_awal - 1, "sesudah bangun swipe melempar lagi (koran %d -> %d)" % [koran_awal, akar.koran.sisa])
	_langkah(akar, 600)
	check(sepeda.kecepatan_ud >= 3.0, "tabrakan tidak menghentikan rute: sepeda melaju lagi (%.2f u/d)" % sepeda.kecepatan_ud)
	_bersihkan(akar)


## QA-001 iterasi 1: sinyal `tabrakan` membawa jenis rintangan penyebab yang sebenarnya, bukan hanya anjing (AC-8). Bersama
## `_test_tabrakan_dari_scene` (anjing) kedua jenis data diperiksa dengan harapan literal.
func _test_tabrakan_mobil_dari_scene() -> void:
	_judul.call("Scene rute: tabrakan dengan mobil keluar garasi membawa jenis mobil_garasi (AC-8, QA-001)")
	var akar: RuteMain = await _siapkan()
	var audio: Node = _audio()
	if audio == null:
		check(false, "autoload Audio ada")
		_bersihkan(akar)
		return
	var tabrak: Array[String] = []
	akar.tabrakan.connect(func(jenis: String) -> void: tabrak.append(jenis))
	# Sepeda ditahan di maju 40, separuh dekat (lateral 1,5), 5 detik: anjing seberang 36 mengejar sampai batas 39, berhenti, lalu pulang dan
	# selesai; mobil seberang 45 (tanda 9: sepeda >= 36) tanda 1,5 detik lalu mundur 1,0 u/d sejauh 2,5 ubin dan berhenti di garis tengah.
	for i: int in range(300):
		_taruh(akar, 0.0, 1.5, 40.0)
		akar.perbarui(DT)
	var anjing: AnjingPenjaga.Keadaan = akar.rintangan().daftar[0].anjing
	var mobil: MobilGarasi.Keadaan = akar.rintangan().daftar[1].mobil
	check(tabrak.is_empty() and anjing.status == AnjingPenjaga.Status.DIAM and anjing.selesai and mobil.status == MobilGarasi.Status.BERHENTI, "kontrol: anjing 36 sudah pulang dan selesai, mobil 45 berhenti di jalan, belum ada tabrakan")
	var kotak: Rect2 = MobilGarasi.kotak(mobil)
	check(kotak.position.is_equal_approx(Vector2(-1.5, 44.625)) and kotak.size.is_equal_approx(Vector2(1.5, 0.75)), "mobil berhenti: bentuk lateral -1,5..0 (separuh seberang), maju 44,625..45,375, dapat %s" % kotak)
	var bunyi_awal: int = int(audio.call(&"jumlah_bunyi_rute", BunyiRute.Bunyi.TABRAKAN))
	# Santai di lateral -0,6 dari maju 43: depan bentuk sepeda (maju + 0,4) melewati 44,625 pada langkah ke-25 (0,05 ubin per langkah).
	_taruh(akar, 3.0, -0.6, 43.0)
	var langkah: int = 0
	while tabrak.is_empty() and langkah < 120:
		akar.perbarui(DT)
		langkah += 1
	check(tabrak == ["mobil_garasi"], "santai menabrak mobil yang berhenti di separuh seberang: sinyal membawa jenis mobil_garasi, dapat %s" % [tabrak])
	check(langkah == 25 and akar.rintangan().tabrakan.jumlah == 1 and _sepeda(akar).kecepatan_ud == 0.0 and _sepeda(akar).nama_animasi() == &"jatuh_normal", "tabrakan di langkah 25 (depan sepeda 43,4 + 0,05 x 25 = 44,65 > 44,625), satu tabrakan, kecepatan 0, sprite jatuh_normal (dapat langkah %d)" % langkah)
	check(int(audio.call(&"jumlah_bunyi_rute", BunyiRute.Bunyi.TABRAKAN)) == bunyi_awal + 1, "satu bunyi tabrakan untuk tabrakan mobil")
	_bersihkan(akar)


## Jumlah keputusan bunyi geram, gonggong, bip, mesin di `Audio` (urut itu).
func _hitung_bunyi_tanda(audio: Node) -> Array[int]:
	var hasil: Array[int] = []
	for b: BunyiRute.Bunyi in [BunyiRute.Bunyi.ANJING_GERAM, BunyiRute.Bunyi.ANJING_GONGGONG, BunyiRute.Bunyi.MOBIL_BIP, BunyiRute.Bunyi.MOBIL_MESIN]:
		hasil.append(int(audio.call(&"jumlah_bunyi_rute", b)))
	return hasil


## Selisih dua hitungan bunyi per bunyi.
func _selisih(sekarang: Array[int], awal: Array[int]) -> Array[int]:
	var hasil: Array[int] = []
	for i: int in range(sekarang.size()):
		hasil.append(sekarang[i] - awal[i])
	return hasil


## QA-002 iterasi 1 (bagian bunyi tanda): peristiwa rintangan di scene diputar `Audio` (AC-19, SOUND_DESIGN 4.3): geram saat anjing waspada,
## gonggong saat mengejar, bip saat mobil mulai tanda, mesin saat mobil mulai mundur; masing-masing tepat sekali per peristiwa.
func _test_bunyi_tanda_rintangan_di_scene() -> void:
	_judul.call("Scene rute: bunyi tanda rintangan dari Audio, geram, gonggong, bip, mesin, sekali per peristiwa (AC-19, QA-002)")
	var akar: RuteMain = await _siapkan()
	var audio: Node = _audio()
	if audio == null:
		check(false, "autoload Audio ada")
		_bersihkan(akar)
		return
	var awal: Array[int] = _hitung_bunyi_tanda(audio)
	# Sepeda di separuh dekat (lateral 1,5): anjing seberang 36 (tanda 9) waspada saat sepeda >= 27, mengejar saat >= 36; mobil seberang
	# 45 (tanda 9) tanda juga saat sepeda >= 36 (ambang sama), mundur 1,5 detik (90 langkah) sesudahnya. Tidak ada tabrakan di sisi dekat.
	_taruh(akar, 3.0, 1.5, 26.0)
	_langkah(akar, 1)
	check(_selisih(_hitung_bunyi_tanda(audio), awal) == [0, 0, 0, 0], "maju 26,05 (di luar jarak tanda): belum ada bunyi rintangan")
	_taruh(akar, 3.0, 1.5, 27.0)
	_langkah(akar, 1)
	check(_selisih(_hitung_bunyi_tanda(audio), awal) == [1, 0, 0, 0] and akar.rintangan().daftar[0].anjing.status == AnjingPenjaga.Status.WASPADA, "maju 27,05: anjing 36 waspada, satu geram, dapat %s" % [_selisih(_hitung_bunyi_tanda(audio), awal)])
	_langkah(akar, 30)
	check(_selisih(_hitung_bunyi_tanda(audio), awal) == [1, 0, 0, 0], "30 langkah waspada berikutnya: geram tetap satu kali")
	_taruh(akar, 3.0, 1.5, 35.9)
	_langkah(akar, 1)
	check(_selisih(_hitung_bunyi_tanda(audio), awal) == [1, 0, 0, 0] and akar.rintangan().daftar[1].mobil.status == MobilGarasi.Status.DIAM, "maju 35,95: anjing belum mengejar, mobil 45 belum tanda, dapat %s" % [_selisih(_hitung_bunyi_tanda(audio), awal)])
	_taruh(akar, 3.0, 1.5, 36.0)
	_langkah(akar, 1)
	check(_selisih(_hitung_bunyi_tanda(audio), awal) == [1, 1, 1, 0] and akar.rintangan().daftar[0].anjing.status == AnjingPenjaga.Status.MENGEJAR and akar.rintangan().daftar[1].mobil.status == MobilGarasi.Status.TANDA, "maju 36,05: anjing mengejar (satu gonggong) dan mobil 45 tanda lampu mundur (satu bip), dapat %s" % [_selisih(_hitung_bunyi_tanda(audio), awal)])
	_langkah(akar, 80)
	check(_selisih(_hitung_bunyi_tanda(audio), awal) == [1, 1, 1, 0] and akar.rintangan().daftar[1].mobil.status == MobilGarasi.Status.TANDA, "1,33 detik tanda: belum mundur, belum ada mesin (bip tetap satu)")
	_langkah(akar, 20)
	check(_selisih(_hitung_bunyi_tanda(audio), awal) == [1, 1, 1, 1] and akar.rintangan().daftar[1].mobil.status != MobilGarasi.Status.TANDA, "sesudah 1,5 detik tanda: mobil mundur, satu bunyi mesin, dapat %s" % [_selisih(_hitung_bunyi_tanda(audio), awal)])
	check(akar.rintangan().tabrakan.jumlah == 0, "kontrol: sepeda di separuh dekat tidak bertabrakan")
	_bersihkan(akar)


# --- Jeda (AC-21) ---

func _test_jeda_membekukan() -> void:
	_judul.call("Scene rute: jeda membekukan rintangan, jatuh, kebal, combo, bel, umpan, frame sprite jatuh (AC-21)")
	var akar: RuteMain = await _siapkan()
	var tabrak: Array[String] = []
	akar.tabrakan.connect(func(jenis: String) -> void: tabrak.append(jenis))
	# Rangkaian 2 antaran sebelum tabrakan, supaya tabrakan memutus combo dan label PUTUS tampil (QA-003: tanpa rangkaian label tidak pernah
	# tampil dan pemeriksaan bekunya hampa).
	var skor: SkorRute.Keadaan = SkorRute.awal()
	skor.beruntun = 2
	akar.set(&"_skor", skor)
	_taruh(akar, 3.0, -0.6, 30.0)
	while tabrak.is_empty() and _sepeda(akar).jarak_ubin < 60.0:
		akar.perbarui(DT)
	akar.ketuk_bel()
	_langkah(akar, 3)
	# Satu umpan balik melayang (antaran kotak surat +15) sedang tampil saat jeda dimulai (QA-003: pewaktu umpan ikut dicuplik).
	var hs: SkorRute.Hasil = SkorRute.Hasil.new()
	hs.status = SkorRute.Status.ANTAR
	hs.koin_tambah = 15
	var umpan: Array[UmpanMelayang.Entri] = [UmpanMelayang.dari_hasil(hs, Vector2(-2.25, -38.0))]
	akar.set(&"_umpan", umpan)
	check(akar.putus_tampil() and akar.umpan_melayang().size() == 1 and is_equal_approx(akar.umpan_melayang()[0].sisa_detik, 0.8), "kontrol: label PUTUS dan satu umpan melayang (0,8 detik) tampil saat jeda dimulai")
	var sebelum: Array = _cuplik(akar)
	akar.minta_jeda()
	_langkah(akar, 60)
	check(akar.sedang_jeda() and _cuplik(akar) == sebelum, "60 langkah selama jeda: rintangan, jatuh, kebal, bel, sisa label PUTUS, umpan melayang, frame sprite jatuh tidak berubah")
	check(akar.putus_tampil() and akar.umpan_melayang().size() == 1, "sesudah 1 detik jeda: label PUTUS dan umpan melayang masih tampil")
	check(akar.ketuk_bel() == Bel.Bunyi.TOLAK and akar.bel().jumlah == 1, "bel tidak bisa dibunyikan saat jeda game")
	akar.minta_lanjut()
	_langkah(akar, 1)
	check(_cuplik(akar) == sebelum, "langkah pertama sesudah lanjut ber-dt 0 (tanpa lompatan)")
	_langkah(akar, 1)
	check(_cuplik(akar) != sebelum, "sesudah itu waktu berjalan lagi")
	_bersihkan(akar)


func _cuplik(akar: AdeganJalan) -> Array:
	var hasil: Array = []
	for item: RintanganRute.Item in akar.rintangan().daftar:
		hasil.append(RintanganRute.posisi(item))
		hasil.append(item.anjing.status if item.anjing != null else item.mobil.status)
	var t: Tabrakan.Keadaan = akar.rintangan().tabrakan
	hasil.append_array([t.jatuh_detik, t.kebal_detik, _sepeda(akar).nama_animasi(), _sepeda(akar).frame_sprite(), akar.bel().teks_detik, akar.bel().jeda_detik, akar.putus_tampil(), float(akar.get(&"_putus_detik")), _sepeda(akar).jarak_ubin])
	hasil.append(akar.umpan_melayang().size())
	for e: UmpanMelayang.Entri in akar.umpan_melayang():
		hasil.append(e.sisa_detik)
	return hasil


# --- Skor di scene (AC-9 sampai AC-13, AC-18, AC-19) ---

func _test_skor_di_scene() -> void:
	_judul.call("Scene rute: koran mendarat dinilai SkorRute, penanda tepat/netral, HUD skor, umpan melayang, nada combo (AC-9 sampai AC-13)")
	var akar: RuteMain = await _siapkan()
	var audio: Node = _audio()
	var hud: HudRute = _hud(akar)
	var mendarat: Array[KoranLempar.Koran] = []
	var dinilai: Array[SkorRute.Hasil] = []
	akar.koran_mendarat.connect(func(k: KoranLempar.Koran) -> void: mendarat.append(k))
	akar.skor_dinilai.connect(func(h: SkorRute.Hasil) -> void: dinilai.append(h))
	check(hud.visible and hud.teks_skor() == "0" and hud.teks_combo() == "x1.0" and hud.teks_koin() == "0", "HUD skor tampil di scene rute: 0, x1.0, 0")
	var tepat_awal: int = int(audio.call(&"jumlah_bunyi_rute", BunyiRute.Bunyi.TEPAT)) if audio != null else 0
	# 1. Lemparan biasa (bukan bantu) ke pusat kotak surat per_buka_01@6: tepat.
	var k1: KoranLempar.Koran = await _lempar_ke(akar, 1.0, "per_buka_01@6", false, mendarat)
	check(k1 != null and k1.penanda == ZonaSasaran.Penanda.TEPAT and k1.tepat, "lemparan ke pusat kotak surat: penanda TEPAT")
	check(akar.skor().skor == 125 and akar.skor().koin == 15 and hud.teks_skor() == "125" and hud.teks_combo() == "x1.1" and hud.teks_koin() == "15", "tepat santai: skor 125, koin 15, HUD x1.1 untuk antaran berikutnya")
	check(audio == null or (int(audio.call(&"jumlah_bunyi_rute", BunyiRute.Bunyi.TEPAT)) == tepat_awal + 1 and absf(float(audio.call(&"pitch_mendarat_terakhir")) - 1.0) < TOL), "bunyi mendarat nada dasar + kilau tepat")
	check(akar.umpan_gambar().teks_tampil() == ["+15\nTEPAT"], "umpan balik melayang '+15 / TEPAT', dapat %s" % [akar.umpan_gambar().teks_tampil()])
	check(KoranGambar.warna_penanda_koran(k1) == Palette.OK and PolaPiksel.pola_penanda(ZonaSasaran.Penanda.TEPAT) == ["..ooooo..", ".owwwwwo.", "owooooowo", "owo.o.owo", "owoowoowo", "owo.o.owo", "owooooowo", ".owwwwwo.", "..ooooo.."], "penanda tepat: sasaran 9x9 berbeda bentuk, warna OK")
	# 2. Koran kedua ke rumah yang sama: netral.
	var k2: KoranLempar.Koran = await _lempar_ke(akar, 1.0, "per_buka_01@6", false, mendarat)
	check(k2 != null and k2.penanda == ZonaSasaran.Penanda.NETRAL and akar.skor().skor == 125 and akar.skor().koin == 15 and hud.teks_combo() == "x1.1", "koran ke rumah terantar: penanda netral, skor dan koin tetap, combo tetap x1.1")
	check(k2 != null and KoranGambar.warna_penanda_koran(k2) == Palette.TEXT_2 and PolaPiksel.pola_penanda(ZonaSasaran.Penanda.NETRAL) == ["ooooooo", "owwwwwo", "owwwwwo", "ooooooo"], "penanda netral: garis datar TEXT_2")
	check(akar.umpan_gambar().jumlah_tampil() <= 2, "umpan melayang paling banyak dua")
	# 3. Tap mode bantu ke per_buka_01@10: centang (bantu tidak tepat, O-4), combo x1.1 -> 110.
	_nyalakan_bantu(akar)
	_taruh(akar, 3.0, 0.5, 8.5)
	akar.koran = SisaKoran.awal(30)
	_sentuh(1, akar.posisi_layar_sepeda() + Vector2(200, -150), true)
	_sentuh(1, akar.posisi_layar_sepeda() + Vector2(200, -150), false)
	var k3: KoranLempar.Koran = null
	for i: int in range(150):
		_langkah(akar, 1)
		if mendarat.size() == 3:
			k3 = mendarat[2]
			break
	check(k3 != null and k3.bantu and k3.id_rumah == "per_buka_01@10" and k3.penanda == ZonaSasaran.Penanda.CENTANG and not k3.tepat, "tap bantu ke kotak surat @10: centang, bukan tepat (O-4)")
	check(akar.skor().skor == 235 and akar.skor().koin == 30 and hud.teks_skor() == "235" and hud.teks_combo() == "x1.2" and hud.teks_koin() == "25", "antaran ke-2 beruntun: +110 (x1,1), skor 235, koin kotor 30, HUD x1.2 dan koin bersih 25 (satu koran ulang terbuang -5)")
	check(audio == null or absf(float(audio.call(&"pitch_mendarat_terakhir")) - PITCH_NADA_1) < 0.00001, "nada combo antaran ke-2: pitch 1,059463")
	check(dinilai.size() == 3 and dinilai[0].status == SkorRute.Status.ANTAR and dinilai[1].status == SkorRute.Status.ULANG and dinilai[2].status == SkorRute.Status.ANTAR, "skor_dinilai tepat sekali per koran: antar, ulang, antar")
	_bersihkan(akar)


## Melempar koran biasa (bukan mode bantu) dengan lintasan ke pusat kotak surat rumah `id_rumah` dari sepeda di `maju`, sampai mendarat.
func _lempar_ke(akar: RuteMain, maju: float, id_rumah: String, bantu: bool, mendarat: Array[KoranLempar.Koran]) -> KoranLempar.Koran:
	_taruh(akar, 3.0, 0.5, maju)
	akar.koran = SisaKoran.awal(30)
	var pilihan: BantuLempar.Pilihan = akar.pilihan_bantu(LoperAnim.Sisi.SEBERANG)
	if pilihan == null or pilihan.zona.id_rumah != id_rumah:
		check(false, "pembantu tes: lintasan ke %s dari maju %.1f" % [id_rumah, maju])
		return null
	var sebelum: int = mendarat.size()
	akar.call(&"_lempar", pilihan.lintasan, bantu)
	for i: int in range(150):
		_langkah(akar, 1)
		if mendarat.size() > sebelum:
			return mendarat[sebelum]
	return null


## Melempar koran biasa dari sepeda di `maju` (santai, lateral 0,5) ke titik jalan `titik_jalan` (x = lateral, y = maju) dengan lintasan
## `ThrowSolver.hitung` yang dibidik ke titik itu (pencari kekuatan dan arah yang sama dengan mode bantu), sampai mendarat.
func _lempar_ke_titik(akar: RuteMain, maju: float, titik_jalan: Vector2, mendarat: Array[KoranLempar.Koran]) -> KoranLempar.Koran:
	_taruh(akar, 3.0, 0.5, maju)
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
		_langkah(akar, 1)
		if mendarat.size() > sebelum:
			return mendarat[sebelum]
	return null


## QA-002 iterasi 1 (bagian tip): koran yang mendarat di teras rumah pemberi tip memutar denting tip lewat `Audio` dari scene (AC-19); teras
## rumah bukan pemberi tip tidak. Rute seed bawaan 20261016 (literal dari data): per_buka_01@10 pelanggan bukan pemberi tip, teras lateral
## -3,0..-2,5 x maju 10,0..11,25; per_buka_01@18 pelanggan pemberi tip, teras -3,0..-2,5 x 18,0..19,25.
func _test_bunyi_tip_di_scene() -> void:
	_judul.call("Scene rute: teras pemberi tip memutar denting tip lewat Audio, teras biasa tidak (AC-11, AC-19, QA-002)")
	var akar: RuteMain = await _siapkan()
	var audio: Node = _audio()
	if audio == null:
		check(false, "autoload Audio ada")
		_bersihkan(akar)
		return
	check(not RouteBuilder.pemberi_tip(akar.rute(), "per_buka_01@10") and RouteBuilder.pemberi_tip(akar.rute(), "per_buka_01@18"), "kontrol: @10 bukan pemberi tip, @18 pemberi tip (seed bawaan)")
	var mendarat: Array[KoranLempar.Koran] = []
	akar.koran_mendarat.connect(func(k: KoranLempar.Koran) -> void: mendarat.append(k))
	var tip_awal: int = int(audio.call(&"jumlah_bunyi_rute", BunyiRute.Bunyi.TIP))
	var k1: KoranLempar.Koran = await _lempar_ke_titik(akar, 4.0, Vector2(-2.75, 10.5), mendarat)
	check(k1 != null and k1.hasil == ZonaSasaran.Hasil.TERAS and k1.id_rumah == "per_buka_01@10" and akar.skor().koin == 15, "teras @10 (bukan pemberi tip): antaran teras, koin 15")
	check(int(audio.call(&"jumlah_bunyi_rute", BunyiRute.Bunyi.TIP)) == tip_awal, "teras bukan pemberi tip: tidak ada denting tip")
	var k2: KoranLempar.Koran = await _lempar_ke_titik(akar, 12.0, Vector2(-2.75, 18.5), mendarat)
	check(k2 != null and k2.hasil == ZonaSasaran.Hasil.TERAS and k2.id_rumah == "per_buka_01@18" and akar.skor().koin == 35, "teras @18 (pemberi tip): antaran teras, koin 15 + 15 + tip 5 = 35")
	check(int(audio.call(&"jumlah_bunyi_rute", BunyiRute.Bunyi.TIP)) == tip_awal + 1 and audio.call(&"bunyi_rute_terakhir") == "res://assets/audio/sfx/ui/sfx_ui_tip_01.wav", "teras pemberi tip: satu denting tip (sfx_ui_tip_01.wav) sesudah bunyi mendarat")
	_bersihkan(akar)


## Run fase3c-hud-hasil AC-2 (K-1): teras pemberi tip @18 sesudah tenggat lewat (jam tenggat diatur tes): ongkos 15, skor dan combo jalan,
## tanpa tip, tanpa denting tip, umpan balik melayang tanpa baris "tip +5". Sebelum tenggat (kontrol) tetap +5.
func _test_tip_sesudah_tenggat_di_scene() -> void:
	_judul.call("Scene rute: tip hilang sesudah tenggat lewat; ongkos, skor, combo tetap; tanpa denting dan umpan tip (AC-2, K-1)")
	var akar: RuteMain = await _siapkan()
	var audio: Node = _audio()
	var mendarat: Array[KoranLempar.Koran] = []
	akar.koran_mendarat.connect(func(k: KoranLempar.Koran) -> void: mendarat.append(k))
	var dinilai: Array[SkorRute.Hasil] = []
	akar.skor_dinilai.connect(func(h: SkorRute.Hasil) -> void: dinilai.append(h))
	# Kontrol sebelum tenggat: teras @10 (bukan pemberi tip) lalu teras @18 (pemberi tip): +15 lalu +20.
	check(akar.tenggat().tenggat_detik == 91 and not TenggatRute.lewat(akar.tenggat()), "rute seed bawaan 236 ubin: tenggat 91 detik, belum lewat")
	await _lempar_ke_titik(akar, 4.0, Vector2(-2.75, 10.5), mendarat)
	var tip_awal: int = int(audio.call(&"jumlah_bunyi_rute", BunyiRute.Bunyi.TIP)) if audio != null else 0
	# Tenggat dibuat lewat (jam 91,5 dari 91) tanpa menunggu 91 detik.
	var k: TenggatRute.Keadaan = TenggatRute.langkah(TenggatRute.awal(akar.rute().panjang_ubin), 91.5)
	akar.atur_tenggat(k)
	check(TenggatRute.lewat(akar.tenggat()), "kontrol: tenggat lewat")
	var k2: KoranLempar.Koran = await _lempar_ke_titik(akar, 12.0, Vector2(-2.75, 18.5), mendarat)
	check(k2 != null and k2.hasil == ZonaSasaran.Hasil.TERAS and k2.id_rumah == "per_buka_01@18", "teras @18 (pemberi tip) sesudah tenggat lewat: antaran teras")
	check(akar.skor().koin == 30 and akar.skor().jumlah_tip == 0 and akar.skor().koin_tip == 0, "koin 15 + 15 = 30 (tanpa tip 5), jumlah tip 0 (dapat koin %d)" % akar.skor().koin)
	check(dinilai.size() == 2 and dinilai[1].status == SkorRute.Status.ANTAR and dinilai[1].tip == 0 and dinilai[1].skor_tambah == 110 and akar.skor().beruntun == 2, "sesudah tenggat: antaran sah, skor +110 (combo x1,1), combo naik ke 2, tip 0")
	check(audio == null or int(audio.call(&"jumlah_bunyi_rute", BunyiRute.Bunyi.TIP)) == tip_awal, "sesudah tenggat: tidak ada denting tip")
	check(akar.umpan_gambar().teks_tampil().size() >= 1 and (akar.umpan_gambar().teks_tampil().back() as String) == "+15", "umpan balik melayang sesudah tenggat: '+15' tanpa baris tip (dapat %s)" % [akar.umpan_gambar().teks_tampil()])
	_bersihkan(akar)


## QA-013 run 3B (AC-10 run fase3c-hud-hasil, mutan R13): antaran tidak sah (koran meleset di jalan) yang memutus rangkaian menampilkan label
## PUTUS di HUD rute, pengali kembali x1.0, lalu label hilang sesudah 0,8 detik.
func _test_putus_antaran_tidak_sah_di_scene() -> void:
	_judul.call("Scene rute: koran meleset memutus combo dan menampilkan label PUTUS di HUD rute (QA-013 run 3B)")
	var akar: RuteMain = await _siapkan()
	var hud: HudRute = _hud(akar)
	var mendarat: Array[KoranLempar.Koran] = []
	akar.koran_mendarat.connect(func(k: KoranLempar.Koran) -> void: mendarat.append(k))
	await _lempar_ke(akar, 1.0, "per_buka_01@6", false, mendarat)
	check(akar.skor().beruntun == 1 and hud.teks_combo() == "x1.1" and not hud.putus_tampil(), "kontrol: rangkaian 1, HUD x1.1, tanpa PUTUS")
	var k: KoranLempar.Koran = await _lempar_ke_titik(akar, 4.0, Vector2(-1.0, 9.0), mendarat)
	check(k != null and k.hasil == ZonaSasaran.Hasil.MELESET, "koran mendarat di jalan (lateral -1,0): meleset")
	check(akar.skor().beruntun == 0 and akar.putus_tampil() and hud.putus_tampil() and hud.teks_combo() == "x1.0", "meleset memutus rangkaian: label PUTUS tampil di HUD, pengali x1.0")
	_langkah(akar, 60)
	check(not akar.putus_tampil() and not hud.putus_tampil(), "label PUTUS hilang sesudah 0,8 detik")
	# Meleset tanpa rangkaian (beruntun 0) tidak memunculkan PUTUS.
	await _lempar_ke_titik(akar, 6.0, Vector2(-1.0, 11.0), mendarat)
	check(not hud.putus_tampil(), "meleset tanpa rangkaian: tidak ada label PUTUS")
	_bersihkan(akar)


# --- Bel: input, visual (AC-14 sampai AC-17) ---

func _test_bel_input() -> void:
	_judul.call("Scene rute: tombol bel, zona tap, dua jari, kidal, mode bantu, visual (AC-15, AC-16)")
	var akar: RuteMain = await _siapkan()
	var hud: HudRute = _hud(akar)
	var router: TouchRouter = _kontrol(akar).router
	var sepeda: SepedaUji = _sepeda(akar)
	var bunyi: Array = []
	akar.bel_berbunyi.connect(func(b: Bel.Bunyi, _r: Array[int]) -> void: bunyi.append(b))
	_taruh(akar, 3.0, 0.5, 3.0)
	var swipe_awal: int = router.jumlah_swipe_selesai
	var tap_awal: int = router.jumlah_tap_selesai
	_sentuh(1, Vector2(716, 296), true)
	akar.perbarui(0.0)
	check(bunyi == [Bel.Bunyi.KRING] and hud.frame_bel() == Bel.FRAME_DITEKAN and not router.swipe_aktif(), "sentuhan di pusat bel (716, 296): KRING, tombol ditekan, bukan swipe")
	check(sepeda.efek().label_bel().visible and sepeda.efek().label_bel().text == "KRING!" and sepeda.getar_bel().visible and sepeda.getar_bel().frame == 0, "efek: teks 'KRING!' dan garis getar frame 0")
	_sentuh(1, Vector2(716, 296), false)
	_langkah(akar, 6)
	check(router.jumlah_swipe_selesai == swipe_awal and router.jumlah_tap_selesai == tap_awal and hud.frame_bel() == Bel.FRAME_DIAM, "jari bel diangkat: tidak ada swipe atau tap, tombol diam")
	_sentuh(1, Vector2(694, 304), true)
	_sentuh(1, Vector2(694, 304), false)
	akar.perbarui(0.0)
	check(bunyi == [Bel.Bunyi.KRING, Bel.Bunyi.KRING_KRING] and sepeda.efek().label_bel().text == "KRING KRING!" and hud.frame_bel() == Bel.FRAME_JEDA_PERTAMA, "ketukan kedua selama teks: KRING KRING!, tombol jeda cincin penuh")
	_langkah(akar, 31)
	check(hud.frame_bel() == 6, "sesudah 0,52 detik jeda: cincin separuh (frame 6)")
	_tap(Vector2(716, 296), 2)
	akar.perbarui(0.0)
	check(bunyi.size() == 2 and akar.bel().jumlah == 2, "ketukan selama jeda bel ditolak tanpa bunyi")
	_langkah(akar, 40)
	# Sentuhan 1 px di luar zona bel = swipe.
	_sentuh(3, Vector2(687, 296), true)
	check(router.swipe_aktif() and akar.bel().jumlah == 2, "sentuhan di (687, 296), di luar radius 28: swipe, bukan bel")
	_sentuh(3, Vector2(687, 296), false)
	# Swipe yang dimulai di luar lalu melewati tombol tetap swipe dan melempar.
	var sisa: int = akar.koran.sisa
	_sentuh(4, Vector2(560, 300), true)
	_geser(4, Vector2(716, 296))
	akar.perbarui(DT)
	_sentuh(4, Vector2(716, 296), false)
	check(akar.bel().jumlah == 2 and akar.koran.sisa == sisa - 1, "swipe dari luar yang berakhir di tombol bel: melempar koran, bel tidak berbunyi")
	_langkah(akar, 30)
	# Dua jari: stick + bel, swipe + bel.
	_sentuh(5, TITIK_STICK, true)
	_tap(Vector2(716, 296), 6)
	check(router.stick_aktif() and akar.bel().jumlah == 3, "stick ditahan + ketuk bel: stick tetap, bel berbunyi")
	_sentuh(5, TITIK_STICK, false)
	_langkah(akar, 40)
	_sentuh(5, Vector2(500, 200), true)
	var nomor: int = router.nomor_swipe
	_tap(Vector2(716, 296), 6)
	check(router.swipe_aktif() and router.nomor_swipe == nomor and akar.bel().jumlah == 4, "swipe ditahan + ketuk bel: swipe tetap (nomor sama), bel berbunyi")
	_sentuh(5, Vector2(500, 200), false)
	_langkah(akar, 40)
	# Mode bantu: ketukan bel tidak melempar.
	_nyalakan_bantu(akar)
	_taruh(akar, 3.0, 0.5, 3.0)
	akar.koran = SisaKoran.awal(30)
	_tap(Vector2(716, 296), 7)
	_langkah(akar, 2)
	check(akar.koran.sisa == 30 and akar.koran_terbang().is_empty() and akar.bel().jumlah == 5, "mode bantu: ketuk bel membunyikan bel, tidak memulai tap lempar")
	_langkah(akar, 40)
	# Kidal: bel di kiri bawah.
	_nyalakan_kidal(akar)
	await _tree.process_frame
	await _tree.process_frame
	akar.perbarui(0.0)
	check(hud.rect_tombol_bel() == Rect2(44, 276, 40, 40), "kidal: tombol bel di (44, 276) 40x40, dapat %s" % hud.rect_tombol_bel())
	_tap(Vector2(64, 296), 1)
	check(akar.bel().jumlah == 6, "kidal: ketuk (64, 296) membunyikan bel")
	_sentuh(2, Vector2(716, 296), true)
	check(akar.bel().jumlah == 6 and router.stick_aktif(), "kidal: (716, 296) zona stick, bukan bel")
	_sentuh(2, Vector2(716, 296), false)
	_bersihkan(akar)


func _tap(posisi: Vector2, index: int) -> void:
	_sentuh(index, posisi, true)
	_sentuh(index, posisi, false)


func _test_bel_anjing_mundur() -> void:
	_judul.call("Scene rute: bel membuat anjing waspada dalam jangkauan mundur dengan ikon !, mobil tidak bereaksi (AC-14, K-3)")
	var akar: RuteMain = await _siapkan()
	var reaksi: Array = []
	akar.bel_berbunyi.connect(func(_b: Bel.Bunyi, r: Array[int]) -> void: reaksi.append(r.duplicate()))
	_taruh(akar, 3.0, 0.5, 30.0)
	_langkah(akar, 1)
	check(akar.rintangan().daftar[0].anjing.status == AnjingPenjaga.Status.WASPADA, "sepeda di maju 30: anjing 36 waspada")
	akar.ketuk_bel()
	check(reaksi.size() == 1 and (reaksi[0] as Array).is_empty() and akar.rintangan().daftar[0].anjing.status == AnjingPenjaga.Status.WASPADA, "anjing 6 ubin di depan (> 4): tidak bereaksi")
	_langkah(akar, 40)
	_taruh(akar, 3.0, 0.5, 32.5)
	akar.ketuk_bel()
	akar.perbarui(0.0)
	var anjing: RintanganRute.Item = akar.rintangan().daftar[0]
	var sprite: AnimatedSprite2D = akar.rintangan_daur().sprite_rintangan(0)
	check(reaksi.size() == 2 and reaksi[1] == [0] and anjing.anjing.status == AnjingPenjaga.Status.MUNDUR, "anjing waspada 3,5 ubin di depan: bereaksi (id 0), MUNDUR")
	check(RintanganDaur.ikon_seru(sprite).visible and RintanganDaur.ikon_seru(sprite).position == Vector2(0, -28) and sprite.animation == &"berhenti" and not sprite.flip_h, "ikon ! tampil 28 px di atas anjing yang berdiri kaget")
	_langkah(akar, 36)
	anjing = akar.rintangan().daftar[0]
	check(not RintanganDaur.ikon_seru(sprite).visible and anjing.anjing.status == AnjingPenjaga.Status.DIAM and anjing.anjing.selesai, "0,6 detik: ikon hilang; anjing waspada sudah di halaman, diam dan tidak mengejar lagi")
	_langkah(akar, 300)
	check(akar.rintangan().daftar[0].anjing.status == AnjingPenjaga.Status.DIAM, "sepeda melewati rumahnya: anjing yang sudah mundur tidak mengejar")
	# Anjing yang MENGEJAR (anjing seberang 162): bel membuatnya lari mundur ke rumah (sprite lari dicermin).
	_langkah(akar, 40)
	_taruh(akar, 3.0, 1.0, 161.0)
	_langkah(akar, 30)
	var pengejar: RintanganRute.Item = akar.rintangan().daftar[8]
	check(pengejar.anjing.status == AnjingPenjaga.Status.MENGEJAR and pengejar.anjing.maju_ubin > 162.0, "anjing 162 mengejar sepeda (maju %.2f)" % pengejar.anjing.maju_ubin)
	akar.ketuk_bel()
	akar.perbarui(0.0)
	var sprite_pengejar: AnimatedSprite2D = akar.rintangan_daur().sprite_rintangan(8)
	check(reaksi[reaksi.size() - 1] == [8] and RintanganDaur.ikon_seru(sprite_pengejar).visible, "anjing mengejar dalam jangkauan: bereaksi, ikon !")
	_langkah(akar, 36)
	check(not RintanganDaur.ikon_seru(sprite_pengejar).visible and sprite_pengejar.animation == &"lari" and sprite_pengejar.flip_h and akar.rintangan().daftar[8].anjing.status == AnjingPenjaga.Status.MUNDUR, "0,6 detik: ikon hilang, anjing lari mundur ke halaman (dicermin)")
	# Mobil dalam jangkauan tidak bereaksi.
	_langkah(akar, 40)
	_taruh(akar, 3.0, 1.5, 71.0)
	_langkah(akar, 1)
	var status_mobil: MobilGarasi.Status = akar.rintangan().daftar[3].mobil.status
	var belakang_mobil: float = akar.rintangan().daftar[3].mobil.belakang_ubin
	akar.ketuk_bel()
	var mobil_tetap: bool = akar.rintangan().daftar[3].mobil.status == status_mobil and akar.rintangan().daftar[3].mobil.belakang_ubin == belakang_mobil
	check(reaksi.size() == 4 and (reaksi[3] as Array).is_empty() and mobil_tetap, "mobil 3 ubin di depan (status %s): tidak bereaksi pada bel" % MobilGarasi.Status.keys()[status_mobil])
	_bersihkan(akar)


# --- Main lagi (AC-22) ---

func _test_main_lagi() -> void:
	_judul.call("Scene rute: Main lagi mengatur ulang rintangan, tabrakan, skor, combo, koin, terantar, bel, umpan (AC-22)")
	var akar: RuteMain = await _siapkan()
	var mendarat: Array[KoranLempar.Koran] = []
	akar.koran_mendarat.connect(func(k: KoranLempar.Koran) -> void: mendarat.append(k))
	await _lempar_ke(akar, 1.0, "per_buka_01@6", false, mendarat)
	var tabrak: Array[String] = []
	akar.tabrakan.connect(func(jenis: String) -> void: tabrak.append(jenis))
	_taruh(akar, 3.0, -0.6, 30.0)
	while tabrak.is_empty() and _sepeda(akar).jarak_ubin < 60.0:
		akar.perbarui(DT)
	akar.ketuk_bel()
	check(akar.skor().skor > 0 and not tabrak.is_empty() and akar.bel().jumlah == 1, "sebelum Main lagi: ada skor, tabrakan, dan bel")
	akar.main_lagi()
	var hud: HudRute = _hud(akar)
	var sepeda: SepedaUji = _sepeda(akar)
	var semua_awal: bool = akar.rintangan().daftar.size() > 0
	for item: RintanganRute.Item in akar.rintangan().daftar:
		if item.anjing != null and (item.anjing.status != AnjingPenjaga.Status.DIAM or item.anjing.selesai or item.anjing.maju_ubin != item.anjing.rumah_maju_ubin):
			semua_awal = false
		if item.mobil != null and (item.mobil.status != MobilGarasi.Status.DIAM or item.mobil.belakang_ubin != 2.5):
			semua_awal = false
	check(semua_awal, "rintangan rute baru semua di awal (anjing diam di rumah, mobil parkir)")
	var t: Tabrakan.Keadaan = akar.rintangan().tabrakan
	check(t.jumlah == 0 and t.jatuh_detik == 0.0 and t.kebal_detik == 0.0 and t.menempel.is_empty(), "tabrakan, jatuh, kebal diatur ulang")
	var s: SkorRute.Keadaan = akar.skor()
	check(s.skor == 0 and s.koin == 0 and s.beruntun == 0 and s.terantar.is_empty(), "skor, koin, combo, rumah terantar diatur ulang")
	check(akar.bel().jumlah == 0 and akar.bel().teks_detik == 0.0 and akar.bel().jeda_detik == 0.0 and not sepeda.efek().label_bel().visible, "bel dan teks KRING diatur ulang")
	check(akar.umpan_melayang().is_empty() and not akar.putus_tampil(), "umpan melayang dan label PUTUS kosong")
	check(hud.teks_skor() == "0" and hud.teks_combo() == "x1.0" and hud.teks_koin() == "0" and hud.frame_bel() == Bel.FRAME_DIAM, "HUD skor 0, x1.0, koin 0, tombol bel diam")
	check(not sepeda.sedang_jatuh() and sepeda.nama_animasi() == &"santai_normal" and sepeda.alfa_sprite() == 1.0 and not sepeda.efek().ikon_tabrakan_tampil(), "Main lagi saat jatuh: sprite kembali santai_normal, kedip dan ikon padam, dapat %s" % sepeda.nama_animasi())
	_bersihkan(akar)


# --- Jalan uji tetap jalan (AC-20) ---

func _test_jalan_uji() -> void:
	_judul.call("Jalan uji (scene dev): tanpa rintangan, tanpa panel skor, bel tetap berbunyi (AC-20)")
	_tree.root.size = Vector2i(2340, 1080)
	var akar: JalanUji = (load(BERKAS_JALAN_UJI) as PackedScene).instantiate() as JalanUji
	_tree.root.add_child(akar)
	await _tree.process_frame
	await _tree.process_frame
	akar.set_process(false)
	(_anak(akar, "KontrolTouch") as KontrolTouch).keyboard_aktif = false
	_langkah(akar, 120)
	check(akar.rintangan().daftar.is_empty() and akar.rintangan().tabrakan.jumlah == 0, "jalan uji: tanpa rintangan dan tabrakan")
	check(not (_anak(akar, "Hud") as HudDev).skor_tampil(), "jalan uji: panel skor tersembunyi")
	check(akar.ketuk_bel() == Bel.Bunyi.KRING and _sepeda(akar).efek().label_bel().text == "KRING!", "jalan uji: bel berbunyi dan teks KRING! tampil")
	_bersihkan(akar)
