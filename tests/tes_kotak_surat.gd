class_name TesKotakSurat
extends RefCounted
## Tes sprite kotak surat sasaran scene rute (run art-kotak-surat, usulan): `assets/sprites/props/prop_kotak_surat.png` + `.json`
## dari `tools/env_art/fase3.py`, scene `scenes/entities/kotak_surat.tscn`, dan sambungannya ke `scenes/rute/rute.tscn`.
##
## Harapan ditulis sebagai literal (ukuran 30x39, titik pijak 10,26, nama berkas) atau dihitung dari PNG oleh tes ini, bukan dari
## JSON yang sedang dijaga. Jalan uji sengaja tetap graybox: kubus oranye lama hanya diganti di scene rute.

const NAMA: String = "prop_kotak_surat"
const BERKAS_PNG: String = "res://assets/sprites/props/prop_kotak_surat.png"
const BERKAS_JSON: String = "res://assets/sprites/props/prop_kotak_surat.json"
const BERKAS_SCENE: String = "res://scenes/entities/kotak_surat.tscn"
const BERKAS_RUTE: String = "res://scenes/rute/rute.tscn"
const BERKAS_JALAN_UJI: String = "res://scenes/dev/jalan_uji.tscn"
const BERKAS_GRAYBOX: String = "res://scenes/dev/kotak_surat_graybox.tscn"
const BERKAS_DAUR: String = "res://scripts/entities/rumah_daur_rute.gd"
## Ukuran dan titik pijak literal hasil render `fase3.py` (kaki tiang di tanah, skala 1x, tidak dibesarkan).
const UKURAN: Vector2i = Vector2i(30, 39)
const PIJAK: Vector2i = Vector2i(10, 26)
const SKALA: float = 32.0
const SETENGAH: float = 16.0

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
	_test_aset()
	_test_scene_kotak()
	_test_paket()
	_test_sambungan_scene()
	await _test_rute_di_scene()


func _baca_json() -> Dictionary:
	var hasil: Variant = JSON.parse_string(FileAccess.get_file_as_string(BERKAS_JSON))
	return hasil as Dictionary if hasil is Dictionary else {}


func _baca_gambar() -> Image:
	var gambar: Image = Image.new()
	var galat: int = gambar.load_png_from_buffer(FileAccess.get_file_as_bytes(BERKAS_PNG))
	return gambar if galat == OK else null


func _test_aset() -> void:
	_judul.call("Sprite kotak surat sasaran: JSON, ukuran PNG, dan titik pijak (aset usulan, tools/env_art/fase3.py)")
	var json: Dictionary = _baca_json()
	var gambar: Image = _baca_gambar()
	check(not json.is_empty() and gambar != null, "prop_kotak_surat.json dan .png terbaca")
	if json.is_empty() or gambar == null:
		return
	var ukuran: Array = json.get("size", [])
	var pijak: Array = json.get("ground_anchor", [])
	check(json.get("sprite", "") == "%s.png" % NAMA, "JSON menyebut sprite prop_kotak_surat.png")
	check(ukuran.size() == 2 and pijak.size() == 2, "JSON punya size dan ground_anchor dua angka")
	check(str(json.get("note", "")).length() > 0, "JSON punya note asal aset")
	if ukuran.size() != 2 or pijak.size() != 2:
		return
	check(Vector2i(int(ukuran[0]), int(ukuran[1])) == Vector2i(gambar.get_width(), gambar.get_height()), "size di JSON = ukuran PNG %dx%d" % [gambar.get_width(), gambar.get_height()])
	check(Vector2i(gambar.get_width(), gambar.get_height()) == UKURAN, "ukuran PNG = literal 30x39 (skala 1x, tidak dibesarkan; lib.kotak_surat apa adanya)")
	check(Vector2i(int(pijak[0]), int(pijak[1])) == PIJAK, "ground_anchor di JSON = literal 10,26")
	# Titik pijak dari PNG: ujung bawah belah ketupat tiang = baris opak terbawah (alfa 255, bukan bayangan alfa 71), satu piksel
	# di bawah titik pijak (proyeksi (0,0,0)), kolomnya di dalam 1 piksel dari ground_anchor.x.
	var baris_bawah: int = -1
	var kolom: Array[int] = []
	for y: int in range(gambar.get_height()):
		for x: int in range(gambar.get_width()):
			if gambar.get_pixel(x, y).a8 == 255:
				if y > baris_bawah:
					baris_bawah = y
					kolom = []
				if y == baris_bawah:
					kolom.append(x)
	check(baris_bawah == PIJAK.y + 1, "baris opak terbawah PNG (kaki tiang) satu piksel di bawah ground_anchor.y: %d" % baris_bawah)
	var jumlah_x: int = 0
	for x: int in kolom:
		jumlah_x += x
	var rata: float = float(jumlah_x) / float(maxi(kolom.size(), 1))
	check(absf(rata - float(PIJAK.x)) <= 1.0, "kolom kaki tiang di PNG (rata-rata %.1f) dalam 1 piksel dari ground_anchor.x" % rata)
	# Warna oranye graybox dan garis luar proyek: nada atas dan samping muncul, garis luar 0E0A1C ada.
	var punya_atas: bool = false
	var punya_samping: bool = false
	var punya_garis: bool = false
	for y: int in range(gambar.get_height()):
		for x: int in range(gambar.get_width()):
			var c: Color = gambar.get_pixel(x, y)
			if c.a8 != 255:
				continue
			var hex: String = c.to_html(false).to_upper()
			punya_atas = punya_atas or hex == "FFE08A"
			punya_samping = punya_samping or hex == "FFC94A"
			punya_garis = punya_garis or hex == "0E0A1C"
	check(punya_atas and punya_samping and punya_garis, "PNG memuat nada oranye atas dan samping graybox serta garis luar 0E0A1C (atas %s, samping %s, garis %s)" % [punya_atas, punya_samping, punya_garis])


func _test_scene_kotak() -> void:
	_judul.call("Scene kotak surat: Sprite2D, filter Nearest, tanpa centered, offset = -ground_anchor")
	var paket: PackedScene = load(BERKAS_SCENE) as PackedScene
	check(paket != null, "scenes/entities/kotak_surat.tscn termuat")
	if paket == null:
		return
	var simpul: Node = paket.instantiate()
	var sprite: Sprite2D = simpul as Sprite2D
	check(sprite != null, "akar kotak_surat.tscn bertipe Sprite2D")
	if sprite != null:
		check(sprite.texture != null and sprite.texture.resource_path == BERKAS_PNG, "tekstur = path literal %s" % BERKAS_PNG)
		check(sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "texture_filter = Nearest")
		check(not sprite.centered, "centered = false")
		var pijak: Array = _baca_json().get("ground_anchor", [0, 0])
		check(sprite.offset == -Vector2(float(pijak[0]), float(pijak[1])), "offset %s = -ground_anchor dari JSON" % sprite.offset)
		check(sprite.offset == -Vector2(PIJAK), "offset = -literal 10,26 (kaki tiang jatuh tepat di position node)")
		check(sprite.scale == Vector2.ONE and sprite.rotation == 0.0, "skala 1x tanpa rotasi (pixel-perfect)")
		check(sprite.get_child_count() == 0, "kotak surat satu sprite tanpa anak")
	simpul.free()


## Aset ikut paket game: tidak ada pola `exclude_filter` preset yang mengecualikan sprite, JSON, dan scene.
func _test_paket() -> void:
	_judul.call("Ekspor: sprite dan scene kotak surat tidak dikecualikan preset Android")
	var cfg: ConfigFile = ConfigFile.new()
	check(cfg.load("res://export_presets.cfg") == OK, "export_presets.cfg terbaca")
	var filter: String = ""
	for bagian: String in cfg.get_sections():
		if bagian.ends_with(".options"):
			continue
		filter = str(cfg.get_value(bagian, "exclude_filter", ""))
	var tercocok: Array[String] = []
	var berkas: Array[String] = [
		"assets/sprites/props/prop_kotak_surat.png",
		"assets/sprites/props/prop_kotak_surat.json",
		"scenes/entities/kotak_surat.tscn",
	]
	for pola: String in filter.split(","):
		var bersih: String = pola.strip_edges()
		if bersih.is_empty():
			continue
		for jalur: String in berkas:
			if jalur.match(bersih):
				tercocok.append("%s -> %s" % [bersih, jalur])
	check(not filter.is_empty() and tercocok.is_empty(), "tidak ada pola exclude_filter yang mengecualikan sprite dan scene kotak surat: %s" % [str(tercocok)])
	check("docs/ROADMAP.md".match("docs/*") and not berkas[0].match("docs/*"), "pencocok pola membedakan docs/* dari sprite kotak surat (kontrol)")
	check(FileAccess.file_exists("res://assets/sprites/props/prop_kotak_surat.png.import"), "PNG punya berkas .import (diimpor Godot)")


## Scene rute memakai sprite baru, jalan uji dan scene graybox tetap graybox (path literal, bukan dari konstanta kode produksi).
func _test_sambungan_scene() -> void:
	_judul.call("Sambungan scene: rute memakai kotak surat berbentuk, jalan uji tetap kubus graybox")
	var rute: Node = (load(BERKAS_RUTE) as PackedScene).instantiate()
	var daur_rute: Node = rute.find_child("Objek", true, false)
	var paket_rute: PackedScene = daur_rute.get("adegan_kotak_surat") as PackedScene if daur_rute != null else null
	check(paket_rute != null and paket_rute.resource_path == BERKAS_SCENE, "rute.tscn: Objek.adegan_kotak_surat = %s (dapat %s)" % [BERKAS_SCENE, paket_rute.resource_path if paket_rute != null else "null"])
	rute.free()
	var jalan: Node = (load(BERKAS_JALAN_UJI) as PackedScene).instantiate()
	var paket_jalan: PackedScene = null
	var antre: Array[Node] = [jalan]
	while not antre.is_empty():
		var simpul: Node = antre.pop_back()
		var nilai: Variant = simpul.get("adegan_kotak_surat")
		if nilai is PackedScene:
			paket_jalan = nilai
		antre.append_array(simpul.get_children())
	check(paket_jalan != null and paket_jalan.resource_path == BERKAS_GRAYBOX, "jalan_uji.tscn tetap memakai kotak_surat_graybox.tscn (dapat %s)" % [paket_jalan.resource_path if paket_jalan != null else "null"])
	jalan.free()
	var graybox: Sprite2D = (load(BERKAS_GRAYBOX) as PackedScene).instantiate() as Sprite2D
	check(graybox != null and graybox.texture != null and graybox.texture.resource_path == "res://assets/sprites/_placeholder/prop_graybox_kotak_surat.png", "kotak_surat_graybox.tscn tidak berubah: masih kubus graybox")
	if graybox != null:
		graybox.free()
	# Tanpa angka ajaib baru: skrip daur tidak menyebut sprite atau offset kotak surat; posisi tetap dari titik_kotak_surat_dunia.
	var teks: String = FileAccess.get_file_as_string(BERKAS_DAUR)
	check(teks.find("prop_kotak_surat") == -1 and teks.find("ground_anchor") == -1, "rumah_daur_rute.gd tidak menyebut berkas sprite atau titik pijak kotak surat (hanya scene)")
	check(teks.find("SpriteRumah.titik_kotak_surat_dunia(rumah)") != -1 and teks.find("adegan_kotak_surat.instantiate()") != -1, "posisi kotak surat tetap dari SpriteRumah.titik_kotak_surat_dunia dan node dari adegan_kotak_surat")
	var scene_teks: String = FileAccess.get_file_as_string(BERKAS_SCENE)
	check(scene_teks.find("Color(") == -1 and scene_teks.find("modulate") == -1 and scene_teks.find("Shader") == -1, "scene kotak surat tanpa warna literal, modulate, atau shader (warna ada di PNG)")


func _test_rute_di_scene() -> void:
	_judul.call("Scene rute berjalan: sprite kotak surat di pusat zona, di atas area dan di depan rumahnya")
	_tree.root.size = Vector2i(2340, 1080)
	var akar: RuteMain = (load(BERKAS_RUTE) as PackedScene).instantiate() as RuteMain
	_tree.root.add_child(akar)
	await _tree.process_frame
	await _tree.process_frame
	akar.set_process(false)
	var daur: RumahDaurRute = akar.daur()
	var area: Node = akar.find_child("AreaKotak", true, false)
	var objek: Node = akar.find_child("Objek", true, false)
	check(area != null and objek != null and area.get_index() < objek.get_index(), "AreaKotak digambar sebelum Objek (area di bawah kotak surat)")
	var rute: RouteBuilder.Rute = RouteBuilder.bangun(Config.RUTE_SEED_DEV, PemuatRute.muat_folder().segmen).rute
	var jumlah: int = 0
	var salah: Array[String] = []
	for indeks: int in daur.indeks_tampil():
		var rumah: RouteBuilder.RumahRute = rute.rumah[indeks]
		var kotak: Node2D = daur.kotak_surat(indeks)
		if kotak == null:
			continue
		jumlah += 1
		var sprite: Sprite2D = kotak as Sprite2D
		if sprite == null or sprite.texture == null or sprite.texture.resource_path != BERKAS_PNG:
			salah.append("%s: bukan sprite prop_kotak_surat" % rumah.id)
			continue
		if sprite.offset != -Vector2(PIJAK) or sprite.centered or sprite.get_parent() != objek or sprite.z_index != 0:
			salah.append("%s: offset %s, centered %s, atau induk/z_index salah" % [rumah.id, sprite.offset, sprite.centered])
		# Titik pijak tiang (position node) di layar -> (lateral, maju) dunia, harus di dalam persegi zona kotak surat (ditulis ulang).
		var lateral: float = (sprite.position.x / SKALA + sprite.position.y / SETENGAH) / 2.0
		var maju: float = (sprite.position.x / SKALA - sprite.position.y / SETENGAH) / 2.0
		var di_zona: bool = lateral >= -2.75 and lateral < -1.75 and maju >= rumah.maju_ubin + 1.25 and maju < rumah.maju_ubin + 2.5
		if not di_zona:
			salah.append("%s: pijak tiang (%.3f, %.3f) di luar zona kotak surat" % [rumah.id, lateral, maju])
		# Urutan Y-sort: kotak surat lebih ke bawah di layar daripada pusat tapak rumahnya, jadi tergambar di depan rumah.
		var sprite_rumah: Sprite2D = daur.sprite_rumah(indeks)
		if sprite_rumah == null or sprite.position.y <= sprite_rumah.position.y:
			salah.append("%s: kotak surat tidak di depan sprite rumah (y %s vs %s)" % [rumah.id, sprite.position.y, sprite_rumah.position.y if sprite_rumah != null else "null"])
	check(jumlah > 0, "kontrol: ada kotak surat bersprite baru di jendela awal rute (%d)" % jumlah)
	check(salah.is_empty(), "tiap kotak surat: sprite baru, offset, pijak di zona, di depan rumah: %s" % [salah.slice(0, 3)])
	if akar.sedang_jeda():
		akar.minta_lanjut()
	_tree.root.remove_child(akar)
	akar.free()
