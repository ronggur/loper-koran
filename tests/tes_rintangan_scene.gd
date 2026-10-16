class_name TesRintanganScene
extends RefCounted
## Tes run fase3b-rintangan-skor bagian B: rintangan, tabrakan, skor, dan bel di scene rute sungguhan (`scenes/rute/rute.tscn`) plus
## logika murni kecil bagian B (geser oleng, kedip kebal, frame bel, umpan balik melayang, zona bel, pelacak jari bel).
## Event sentuh sintetis lewat `Input.parse_input_event` (pola `tes_rute_scene.gd`), langkah `perbarui(dt)` dengan dt tetap.
## Harapan ditulis literal (QA-008 run 2A, QA-001 run 3A):
## - Rintangan rute seed bawaan 20261016 (ditulis dari data segmen): anjing seberang 36, mobil seberang 46, anjing dekat 56, mobil 74,
##   anjing dekat 94, mobil 114, anjing dekat 124, mobil 132, anjing seberang 162, anjing dekat 190, mobil 202 (maju, ubin).
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
	["anjing_penjaga", 36.0, "seberang"], ["mobil_garasi", 46.0, "seberang"], ["anjing_penjaga", 56.0, "dekat"],
	["mobil_garasi", 74.0, "seberang"], ["anjing_penjaga", 94.0, "dekat"], ["mobil_garasi", 114.0, "seberang"],
	["anjing_penjaga", 124.0, "dekat"], ["mobil_garasi", 132.0, "seberang"], ["anjing_penjaga", 162.0, "seberang"],
	["anjing_penjaga", 190.0, "dekat"], ["mobil_garasi", 202.0, "seberang"],
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
	await _test_jeda_membekukan()
	await _test_skor_di_scene()
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


func _hud(akar: Node) -> HudDev:
	return _anak(akar, "Hud") as HudDev


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
	_judul.call("Bagian B murni: geser oleng, kedip kebal, frame bel, umpan melayang, zona dan jari bel")
	var t: Tabrakan.Keadaan = Tabrakan.awal()
	check(Tabrakan.geser_oleng_px(t) == 0 and Tabrakan.alfa_kebal(t) == 1.0, "tanpa tabrakan: geser 0, alfa 1,0")
	var kasus_oleng: Array = [[0.6, 1], [0.57, 1], [0.53, -1], [0.47, 1], [0.43, -1], [0.01, -1], [0.0, 0]]
	for k: Array in kasus_oleng:
		t.oleng_detik = k[0]
		check(Tabrakan.geser_oleng_px(t) == k[1], "oleng sisa %.2f detik: geser %d px (bolak-balik tiap 0,05 detik)" % [k[0], k[1]])
	t.oleng_detik = 0.0
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
	check(UmpanMelayang.langkah(daftar, 0.0).size() == 2 and UmpanMelayang.langkah(daftar, 0.81).is_empty(), "dt 0 membeku; sesudah 0,8 detik hilang")
	# Zona bel.
	for kasus: Array in [[640, false, Vector2(612, 332)], [780, false, Vector2(752, 332)], [800, false, Vector2(772, 332)], [800, true, Vector2(28, 332)]]:
		check(TouchZones.pusat_bel(kasus[0], kasus[1]) == kasus[2], "pusat bel lebar %d kidal %s = %s" % [kasus[0], kasus[1], kasus[2]])
	check(TouchZones.zona_di(Vector2(752, 332), 780, false) == TouchZones.Zona.BEL and TouchZones.zona_di(Vector2(724, 332), 780, false) == TouchZones.Zona.BEL and TouchZones.zona_di(Vector2(723, 332), 780, false) == TouchZones.Zona.SWIPE, "zona bel radius 28 inklusif (x 724 bel, x 723 swipe)")
	check(TouchZones.zona_di(Vector2(752, 304), 780, false) == TouchZones.Zona.BEL and TouchZones.zona_di(Vector2(752, 303), 780, false) == TouchZones.Zona.SWIPE, "tepi atas zona bel y 304 inklusif, y 303 swipe")
	check(TouchZones.zona_di(Vector2(28, 332), 780, true) == TouchZones.Zona.BEL and TouchZones.zona_di(Vector2(752, 332), 780, true) == TouchZones.Zona.STICK, "kidal: bel di (28, 332); (752, 332) jadi zona stick")
	# Pelacak jari bel.
	var r: TouchRouter = TouchRouter.new()
	r.lebar_viewport = 780
	var bel: Array = [0]
	r.bel_ditekan.connect(func(_p: Vector2) -> void: bel[0] = int(bel[0]) + 1)
	r.tekan(0, TITIK_STICK, 0.0)
	r.tekan(1, Vector2(752, 332), 0.0)
	r.tekan(1, Vector2(752, 332), 0.0)
	r.geser(1, Vector2(500, 200))
	check(int(bel[0]) == 1 and r.bel_ditahan() and r.stick_aktif() and not r.swipe_aktif(), "stick + bel: bel berbunyi sekali (turun ganda index sama diabaikan), stick tetap; jari bel yang digeser ke zona swipe tidak jadi swipe")
	r.lepas(1, Vector2(500, 200), 0.1)
	check(not r.bel_ditahan() and r.jumlah_swipe_selesai == 0 and r.jumlah_tap_selesai == 0, "jari bel diangkat: bukan swipe dan bukan tap")
	r.tekan(2, Vector2(600, 200), 0.2)
	r.tekan(3, Vector2(752, 332), 0.2)
	check(int(bel[0]) == 2 and r.swipe_aktif() and r.nomor_swipe == 1, "swipe + bel: swipe tetap jalan (nomor tetap), bel berbunyi")
	r.lepas(3, Vector2(752, 332), 0.3)
	r.geser(2, Vector2(752, 332))
	r.lepas(2, Vector2(752, 332), 0.4)
	check(int(bel[0]) == 2 and r.jumlah_swipe_selesai == 1, "swipe yang melewati dan berakhir di tombol bel tetap swipe, tidak membunyikan bel")
	r.tekan(4, Vector2(752, 332), 0.5)
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
	var kasus: Array = [[0.0, []], [10.0, [0]], [30.0, [0, 1, 2]], [100.0, [4, 5, 6]], [150.0, [7, 8]], [200.0, [9, 10]], [240.0, []]]
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
	check(mobil != null and mobil.position == _layar(-3.25, 46.0) and mobil.position == Vector2(1368, -788) and mobil.animation == &"parkir", "mobil parkir: pusat tapak lateral -3,25 di layar (1368, -788), animasi parkir")
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
	check(mobil.animation == &"tanda", "sepeda 8 ubin sebelum mobil: animasi tanda (lampu mundur berkedip)")
	_langkah(akar, 100)
	check(mobil.animation == &"mundur" and mobil.position != _layar(-3.25, 46.0), "1,7 detik kemudian: animasi mundur, mobil bergeser ke jalan")
	_bersihkan(akar)


# --- Penutup (AC-20: satu PenerapPenutup) ---

func _test_penutup_rintangan() -> void:
	_judul.call("Scene rute: rintangan yang menutupi pemain semi-transparan lewat penerap yang sama (AC-20)")
	var akar: RuteMain = await _siapkan()
	var penerap: PenerapPenutup = akar.penerap_penutup()
	check(akar.find_children("*", "PenerapPenutup", true, false).size() == 1, "hanya satu PenerapPenutup")
	# Mobil 46 sampai berhenti di garis tengah: sepeda ditahan di maju 38,5 sisi dekat.
	for i: int in range(400):
		_taruh(akar, 0.0, 1.5, 38.5)
		akar.perbarui(DT)
	var mobil: RintanganRute.Item = akar.rintangan().daftar[1]
	check(mobil.mobil.status == MobilGarasi.Status.BERHENTI, "mobil seberang berhenti di garis tengah")
	var gambar: AnimatedSprite2D = akar.rintangan_daur().sprite_rintangan(1)
	# Tapak mobil berhenti lateral -1,5..0, maju 45,625..46,375, tinggi 1,0. Kaki di (-2,0; 46,5): titik (+d, -d) untuk d 0,6 = (-1,4; 45,9) di
	# tapak, z 0,6 <= 1,0 -> tertutup. Di lateral +1,0 tidak ada d >= 0 yang masuk tapak.
	_taruh(akar, 0.0, -2.0, 46.5)
	check(is_equal_approx(gambar.modulate.a, 0.45) and penerap.jumlah_menutupi() >= 1, "kaki pemain di balik mobil (-2,0; 46,5): mobil alfa 0,45, dapat %.2f" % gambar.modulate.a)
	_taruh(akar, 0.0, 1.0, 46.5)
	check(gambar.modulate.a == 1.0, "pemain di sisi dekat: mobil alfa 1,0")
	_bersihkan(akar)


# --- Tabrakan dari scene (AC-6, AC-8) ---

func _test_tabrakan_dari_scene() -> void:
	_judul.call("Scene rute: tabrakan membawa jenis penyebab, kecepatan, oleng, kebal, combo putus, visual dan bunyi (AC-6, AC-8)")
	var akar: RuteMain = await _siapkan()
	var audio: Node = _audio()
	var tabrak: Array[String] = []
	var kecepatan_saat: Array[float] = []
	akar.tabrakan.connect(func(jenis: String) -> void:
		tabrak.append(jenis)
		kecepatan_saat.append(_sepeda(akar).kecepatan_ud))
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
	check(tabrak == ["anjing_penjaga"], "santai di sisi anjing (lateral -0,6): tabrakan pertama dari anjing_penjaga (sinyal membawa jenis), dapat %s" % [tabrak])
	check(kecepatan_saat.size() == 1 and kecepatan_saat[0] == 1.0, "saat sinyal: kecepatan sudah turun ke 1,0 u/d")
	check(akar.skor().beruntun == 0 and _hud(akar).teks_combo() == "x1.0" and _hud(akar).putus_tampil(), "combo putus: x1.0 dan label PUTUS di HUD")
	check(audio == null or int(audio.call(&"jumlah_bunyi_rute", BunyiRute.Bunyi.TABRAKAN)) == bunyi_awal + 1, "satu bunyi tabrakan")
	check(sepeda.geser_sprite_px() == 1.0 and sepeda.efek().ikon_tabrakan_tampil() and sepeda.alfa_sprite() == 1.0, "langkah tabrakan: sprite bergeser +1 px, ikon kilatan tampil")
	check(not sepeda.efek().perintah_tabrakan().is_empty(), "ikon kilatan menghasilkan perintah gambar")
	_langkah(akar, 8)
	check(sepeda.geser_sprite_px() == 1.0 and sepeda.alfa_sprite() == 0.5 and sepeda.kecepatan_ud == 1.0, "0,133 detik: fase oleng 2 (+1 px), kedip kebal redup 0,5, kecepatan tetap 1,0 (oleng)")
	_langkah(akar, 20)
	check(sepeda.kecepatan_ud == 1.0 and Tabrakan.oleng(akar.rintangan().tabrakan), "0,47 detik: masih oleng, kecepatan tidak naik")
	_langkah(akar, 10)
	check(not Tabrakan.oleng(akar.rintangan().tabrakan) and not sepeda.efek().ikon_tabrakan_tampil() and sepeda.geser_sprite_px() == 0.0, "0,63 detik: oleng habis, ikon hilang, geser 0")
	_langkah(akar, 20)
	check(not _hud(akar).putus_tampil(), "label PUTUS hilang sesudah 0,8 detik")
	check(tabrak.size() == 1, "kebal: tidak ada tabrakan kedua selama 1 detik")
	_langkah(akar, 600)
	check(not sepeda.kecepatan_ud < 1.0, "tabrakan tidak menghentikan rute: sepeda tetap melaju (%.2f u/d)" % sepeda.kecepatan_ud)
	_bersihkan(akar)


# --- Jeda (AC-21) ---

func _test_jeda_membekukan() -> void:
	_judul.call("Scene rute: jeda membekukan rintangan, oleng, kebal, combo, bel, umpan (AC-21)")
	var akar: RuteMain = await _siapkan()
	var tabrak: Array[String] = []
	akar.tabrakan.connect(func(jenis: String) -> void: tabrak.append(jenis))
	_taruh(akar, 3.0, -0.6, 30.0)
	while tabrak.is_empty() and _sepeda(akar).jarak_ubin < 60.0:
		akar.perbarui(DT)
	akar.ketuk_bel()
	_langkah(akar, 3)
	var sebelum: Array = _cuplik(akar)
	akar.minta_jeda()
	_langkah(akar, 60)
	check(akar.sedang_jeda() and _cuplik(akar) == sebelum, "60 langkah selama jeda: rintangan, oleng, kebal, bel, label PUTUS tidak berubah")
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
	hasil.append_array([t.oleng_detik, t.kebal_detik, akar.bel().teks_detik, akar.bel().jeda_detik, akar.putus_tampil(), _sepeda(akar).jarak_ubin])
	return hasil


# --- Skor di scene (AC-9 sampai AC-13, AC-18, AC-19) ---

func _test_skor_di_scene() -> void:
	_judul.call("Scene rute: koran mendarat dinilai SkorRute, penanda tepat/netral, HUD skor, umpan melayang, nada combo (AC-9 sampai AC-13)")
	var akar: RuteMain = await _siapkan()
	var audio: Node = _audio()
	var hud: HudDev = _hud(akar)
	var mendarat: Array[KoranLempar.Koran] = []
	var dinilai: Array[SkorRute.Hasil] = []
	akar.koran_mendarat.connect(func(k: KoranLempar.Koran) -> void: mendarat.append(k))
	akar.skor_dinilai.connect(func(h: SkorRute.Hasil) -> void: dinilai.append(h))
	check(hud.skor_tampil() and hud.teks_skor() == "0" and hud.teks_combo() == "x1.0" and hud.teks_koin() == "0", "HUD skor tampil di scene rute: 0, x1.0, 0")
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
	(_anak(akar, "TombolBantu") as Button).button_pressed = true
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
	check(akar.skor().skor == 235 and akar.skor().koin == 30 and hud.teks_skor() == "235" and hud.teks_combo() == "x1.2" and hud.teks_koin() == "30", "antaran ke-2 beruntun: +110 (x1,1), skor 235, koin 30, HUD x1.2")
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


# --- Bel: input, visual (AC-14 sampai AC-17) ---

func _test_bel_input() -> void:
	_judul.call("Scene rute: tombol bel, zona tap, dua jari, kidal, mode bantu, visual (AC-15, AC-16)")
	var akar: RuteMain = await _siapkan()
	var hud: HudDev = _hud(akar)
	var router: TouchRouter = _kontrol(akar).router
	var sepeda: SepedaUji = _sepeda(akar)
	var bunyi: Array = []
	akar.bel_berbunyi.connect(func(b: Bel.Bunyi, _r: Array[int]) -> void: bunyi.append(b))
	_taruh(akar, 3.0, 0.5, 3.0)
	var swipe_awal: int = router.jumlah_swipe_selesai
	var tap_awal: int = router.jumlah_tap_selesai
	_sentuh(1, Vector2(752, 332), true)
	akar.perbarui(0.0)
	check(bunyi == [Bel.Bunyi.KRING] and hud.frame_bel() == Bel.FRAME_DITEKAN and not router.swipe_aktif(), "sentuhan di pusat bel (752, 332): KRING, tombol ditekan, bukan swipe")
	check(sepeda.efek().label_bel().visible and sepeda.efek().label_bel().text == "KRING!" and sepeda.getar_bel().visible and sepeda.getar_bel().frame == 0, "efek: teks 'KRING!' dan garis getar frame 0")
	_sentuh(1, Vector2(752, 332), false)
	_langkah(akar, 6)
	check(router.jumlah_swipe_selesai == swipe_awal and router.jumlah_tap_selesai == tap_awal and hud.frame_bel() == Bel.FRAME_DIAM, "jari bel diangkat: tidak ada swipe atau tap, tombol diam")
	_sentuh(1, Vector2(730, 340), true)
	_sentuh(1, Vector2(730, 340), false)
	akar.perbarui(0.0)
	check(bunyi == [Bel.Bunyi.KRING, Bel.Bunyi.KRING_KRING] and sepeda.efek().label_bel().text == "KRING KRING!" and hud.frame_bel() == Bel.FRAME_JEDA_PERTAMA, "ketukan kedua selama teks: KRING KRING!, tombol jeda cincin penuh")
	_langkah(akar, 31)
	check(hud.frame_bel() == 6, "sesudah 0,52 detik jeda: cincin separuh (frame 6)")
	_tap(Vector2(752, 332), 2)
	akar.perbarui(0.0)
	check(bunyi.size() == 2 and akar.bel().jumlah == 2, "ketukan selama jeda bel ditolak tanpa bunyi")
	_langkah(akar, 40)
	# Sentuhan 1 px di luar zona bel = swipe.
	_sentuh(3, Vector2(723, 332), true)
	check(router.swipe_aktif() and akar.bel().jumlah == 2, "sentuhan di (723, 332), di luar radius 28: swipe, bukan bel")
	_sentuh(3, Vector2(723, 332), false)
	# Swipe yang dimulai di luar lalu melewati tombol tetap swipe dan melempar.
	var sisa: int = akar.koran.sisa
	_sentuh(4, Vector2(560, 300), true)
	_geser(4, Vector2(752, 332))
	akar.perbarui(DT)
	_sentuh(4, Vector2(752, 332), false)
	check(akar.bel().jumlah == 2 and akar.koran.sisa == sisa - 1, "swipe dari luar yang berakhir di tombol bel: melempar koran, bel tidak berbunyi")
	_langkah(akar, 30)
	# Dua jari: stick + bel, swipe + bel.
	_sentuh(5, TITIK_STICK, true)
	_tap(Vector2(752, 332), 6)
	check(router.stick_aktif() and akar.bel().jumlah == 3, "stick ditahan + ketuk bel: stick tetap, bel berbunyi")
	_sentuh(5, TITIK_STICK, false)
	_langkah(akar, 40)
	_sentuh(5, Vector2(500, 200), true)
	var nomor: int = router.nomor_swipe
	_tap(Vector2(752, 332), 6)
	check(router.swipe_aktif() and router.nomor_swipe == nomor and akar.bel().jumlah == 4, "swipe ditahan + ketuk bel: swipe tetap (nomor sama), bel berbunyi")
	_sentuh(5, Vector2(500, 200), false)
	_langkah(akar, 40)
	# Mode bantu: ketukan bel tidak melempar.
	(_anak(akar, "TombolBantu") as Button).button_pressed = true
	_taruh(akar, 3.0, 0.5, 3.0)
	akar.koran = SisaKoran.awal(30)
	_tap(Vector2(752, 332), 7)
	_langkah(akar, 2)
	check(akar.koran.sisa == 30 and akar.koran_terbang().is_empty() and akar.bel().jumlah == 5, "mode bantu: ketuk bel membunyikan bel, tidak memulai tap lempar")
	_langkah(akar, 40)
	# Kidal: bel di kiri bawah.
	(_anak(akar, "TombolKidal") as Button).button_pressed = true
	await _tree.process_frame
	await _tree.process_frame
	akar.perbarui(0.0)
	check(hud.rect_tombol_bel() == Rect2(8, 312, 40, 40), "kidal: tombol bel di (8, 312) 40x40, dapat %s" % hud.rect_tombol_bel())
	_tap(Vector2(28, 332), 1)
	check(akar.bel().jumlah == 6, "kidal: ketuk (28, 332) membunyikan bel")
	_sentuh(2, Vector2(752, 332), true)
	check(akar.bel().jumlah == 6 and router.stick_aktif(), "kidal: (752, 332) zona stick, bukan bel")
	_sentuh(2, Vector2(752, 332), false)
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
	var hud: HudDev = _hud(akar)
	var sepeda: SepedaUji = _sepeda(akar)
	var semua_awal: bool = akar.rintangan().daftar.size() > 0
	for item: RintanganRute.Item in akar.rintangan().daftar:
		if item.anjing != null and (item.anjing.status != AnjingPenjaga.Status.DIAM or item.anjing.selesai or item.anjing.maju_ubin != item.anjing.rumah_maju_ubin):
			semua_awal = false
		if item.mobil != null and (item.mobil.status != MobilGarasi.Status.DIAM or item.mobil.belakang_ubin != 2.5):
			semua_awal = false
	check(semua_awal, "rintangan rute baru semua di awal (anjing diam di rumah, mobil parkir)")
	var t: Tabrakan.Keadaan = akar.rintangan().tabrakan
	check(t.jumlah == 0 and t.oleng_detik == 0.0 and t.kebal_detik == 0.0 and t.menempel.is_empty(), "tabrakan, oleng, kebal diatur ulang")
	var s: SkorRute.Keadaan = akar.skor()
	check(s.skor == 0 and s.koin == 0 and s.beruntun == 0 and s.terantar.is_empty(), "skor, koin, combo, rumah terantar diatur ulang")
	check(akar.bel().jumlah == 0 and akar.bel().teks_detik == 0.0 and akar.bel().jeda_detik == 0.0 and not sepeda.efek().label_bel().visible, "bel dan teks KRING diatur ulang")
	check(akar.umpan_melayang().is_empty() and not akar.putus_tampil(), "umpan melayang dan label PUTUS kosong")
	check(hud.teks_skor() == "0" and hud.teks_combo() == "x1.0" and hud.teks_koin() == "0" and hud.frame_bel() == Bel.FRAME_DIAM, "HUD skor 0, x1.0, koin 0, tombol bel diam")
	check(sepeda.geser_sprite_px() == 0.0 and sepeda.alfa_sprite() == 1.0 and not sepeda.efek().ikon_tabrakan_tampil(), "visual oleng dan kedip padam")
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
	check(not _hud(akar).skor_tampil(), "jalan uji: panel skor tersembunyi")
	check(akar.ketuk_bel() == Bel.Bunyi.KRING and _sepeda(akar).efek().label_bel().text == "KRING!", "jalan uji: bel berbunyi dan teks KRING! tampil")
	_bersihkan(akar)
