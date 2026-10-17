class_name TesKotakSurat
extends RefCounted
## Tes sprite kotak surat sasaran scene rute (run art-kotak-surat, usulan): `assets/sprites/props/prop_kotak_surat.png` + `.json`
## dari `tools/env_art/fase3.py`, scene `scenes/entities/kotak_surat.tscn`, dan sambungannya ke `scenes/rute/rute.tscn`.
##
## Harapan ditulis sebagai literal (ukuran 30x39, titik pijak 10,26, nama berkas) atau dihitung dari PNG oleh tes ini, bukan dari
## JSON yang sedang dijaga. Jalan uji sengaja tetap graybox: kubus oranye lama hanya diganti di scene rute.
## Kotak surat abu-abu rumah bukan pelanggan seberang (keputusan pemilik 2026-10-17, usulan): `prop_kotak_surat_bukan.*` (28x33, titik
## pijak 9,20) dan `scenes/entities/kotak_surat_bukan.tscn`, digambar di titik yang sama dengan kotak surat pelanggan, bukan sasaran.

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
const BERKAS_PNG_BUKAN: String = "res://assets/sprites/props/prop_kotak_surat_bukan.png"
const BERKAS_JSON_BUKAN: String = "res://assets/sprites/props/prop_kotak_surat_bukan.json"
const BERKAS_SCENE_BUKAN: String = "res://scenes/entities/kotak_surat_bukan.tscn"
## Ukuran dan titik pijak literal kotak surat abu-abu (lebih rendah dan lebih kecil dari kotak surat sasaran).
const UKURAN_BUKAN: Vector2i = Vector2i(28, 33)
const PIJAK_BUKAN: Vector2i = Vector2i(9, 20)
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
	_test_aset_bukan()
	_test_scene_kotak()
	_test_scene_kotak_bukan()
	_test_paket()
	_test_sambungan_scene()
	await _test_rute_di_scene()


func _baca_json() -> Dictionary:
	var hasil: Variant = JSON.parse_string(FileAccess.get_file_as_string(BERKAS_JSON))
	return hasil as Dictionary if hasil is Dictionary else {}


func _baca_gambar(berkas: String = BERKAS_PNG) -> Image:
	var gambar: Image = Image.new()
	var galat: int = gambar.load_png_from_buffer(FileAccess.get_file_as_bytes(berkas))
	return gambar if galat == OK else null


## Hex (huruf besar, tanpa alfa) semua piksel opak `gambar` -> true.
func _warna_opak(gambar: Image) -> Dictionary:
	var hasil: Dictionary = {}
	for y: int in range(gambar.get_height()):
		for x: int in range(gambar.get_width()):
			var c: Color = gambar.get_pixel(x, y)
			if c.a8 == 255:
				hasil[c.to_html(false).to_upper()] = true
	return hasil


## Tinggi badan di atas titik pijak, piksel: titik pijak y - baris opak teratas.
func _tinggi_di_atas_pijak(gambar: Image, pijak_y: int) -> int:
	for y: int in range(gambar.get_height()):
		for x: int in range(gambar.get_width()):
			if gambar.get_pixel(x, y).a8 == 255:
				return pijak_y - y
	return 0


## Luma terbesar (0..1) piksel opak `gambar`.
func _luma_maks(gambar: Image) -> float:
	var maks: float = 0.0
	for y: int in range(gambar.get_height()):
		for x: int in range(gambar.get_width()):
			var c: Color = gambar.get_pixel(x, y)
			if c.a8 == 255:
				maks = maxf(maks, 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b)
	return maks


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


func _test_aset_bukan() -> void:
	_judul.call("Sprite kotak surat abu-abu rumah bukan pelanggan: JSON, ukuran, titik pijak, warna dan bentuk beda dari sasaran (usulan)")
	var hasil: Variant = JSON.parse_string(FileAccess.get_file_as_string(BERKAS_JSON_BUKAN))
	var json: Dictionary = hasil as Dictionary if hasil is Dictionary else {}
	var gambar: Image = _baca_gambar(BERKAS_PNG_BUKAN)
	var sasaran: Image = _baca_gambar()
	check(not json.is_empty() and gambar != null and sasaran != null, "prop_kotak_surat_bukan.json dan .png terbaca")
	if json.is_empty() or gambar == null or sasaran == null:
		return
	var ukuran: Array = json.get("size", [])
	var pijak: Array = json.get("ground_anchor", [])
	check(json.get("sprite", "") == "prop_kotak_surat_bukan.png" and str(json.get("note", "")).length() > 0, "JSON menyebut sprite prop_kotak_surat_bukan.png dan punya note asal aset")
	check(ukuran.size() == 2 and pijak.size() == 2, "JSON punya size dan ground_anchor dua angka")
	if ukuran.size() != 2 or pijak.size() != 2:
		return
	check(Vector2i(int(ukuran[0]), int(ukuran[1])) == Vector2i(gambar.get_width(), gambar.get_height()) and Vector2i(gambar.get_width(), gambar.get_height()) == UKURAN_BUKAN, "size di JSON = ukuran PNG = literal 28x33")
	check(Vector2i(int(pijak[0]), int(pijak[1])) == PIJAK_BUKAN, "ground_anchor di JSON = literal 9,20")
	var warna: Dictionary = _warna_opak(gambar)
	check(warna.has("969AA0") and warna.has("67636D") and warna.has("0E0A1C"), "PNG memuat abu-abu logam palet induk (969AA0 atas = RADAR_BUKAN, 67636D samping) dan garis luar 0E0A1C")
	check(not warna.has("FFE08A") and not warna.has("FFC94A") and not warna.has("E98E3F"), "PNG tanpa satu pun nada oranye sasaran")
	check(_luma_maks(gambar) < _luma_maks(sasaran) - 0.2, "piksel paling terang abu-abu (luma %.2f) jelas lebih redup dari oranye sasaran (luma %.2f)" % [_luma_maks(gambar), _luma_maks(sasaran)])
	var tinggi_bukan: int = _tinggi_di_atas_pijak(gambar, PIJAK_BUKAN.y)
	var tinggi_sasaran: int = _tinggi_di_atas_pijak(sasaran, PIJAK.y)
	check(tinggi_bukan <= tinggi_sasaran - 5, "bentuk beda, bukan hanya warna: abu-abu %d px di atas titik pijak, sasaran %d px (paling sedikit 5 px lebih rendah)" % [tinggi_bukan, tinggi_sasaran])


func _test_scene_kotak_bukan() -> void:
	_judul.call("Scene kotak surat abu-abu: Sprite2D, Nearest, tanpa centered, offset = -ground_anchor, tanpa warna literal")
	var paket: PackedScene = load(BERKAS_SCENE_BUKAN) as PackedScene
	check(paket != null, "scenes/entities/kotak_surat_bukan.tscn termuat")
	if paket == null:
		return
	var sprite: Sprite2D = paket.instantiate() as Sprite2D
	check(sprite != null, "akar kotak_surat_bukan.tscn bertipe Sprite2D")
	if sprite == null:
		return
	check(sprite.texture != null and sprite.texture.resource_path == BERKAS_PNG_BUKAN, "tekstur = path literal %s" % BERKAS_PNG_BUKAN)
	check(sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST and not sprite.centered and sprite.scale == Vector2.ONE, "Nearest, centered false, skala 1x")
	check(sprite.offset == -Vector2(PIJAK_BUKAN), "offset = -literal 9,20 (kaki tiang jatuh tepat di position node)")
	check(sprite.get_child_count() == 0, "satu sprite tanpa anak")
	sprite.free()
	var teks: String = FileAccess.get_file_as_string(BERKAS_SCENE_BUKAN)
	check(teks.find("Color(") == -1 and teks.find("modulate") == -1 and teks.find("Shader") == -1, "scene tanpa warna literal, modulate, atau shader (warna ada di PNG)")


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
		"assets/sprites/props/prop_kotak_surat_bukan.png",
		"assets/sprites/props/prop_kotak_surat_bukan.json",
		"scenes/entities/kotak_surat_bukan.tscn",
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
	check(FileAccess.file_exists("res://assets/sprites/props/prop_kotak_surat.png.import") and FileAccess.file_exists("res://assets/sprites/props/prop_kotak_surat_bukan.png.import"), "kedua PNG kotak surat punya berkas .import (diimpor Godot)")


## Scene rute memakai sprite baru, jalan uji dan scene graybox tetap graybox (path literal, bukan dari konstanta kode produksi).
func _test_sambungan_scene() -> void:
	_judul.call("Sambungan scene: rute memakai kotak surat berbentuk, jalan uji tetap kubus graybox")
	var rute: Node = (load(BERKAS_RUTE) as PackedScene).instantiate()
	var daur_rute: Node = rute.find_child("Objek", true, false)
	var paket_rute: PackedScene = daur_rute.get("adegan_kotak_surat") as PackedScene if daur_rute != null else null
	check(paket_rute != null and paket_rute.resource_path == BERKAS_SCENE, "rute.tscn: Objek.adegan_kotak_surat = %s (dapat %s)" % [BERKAS_SCENE, paket_rute.resource_path if paket_rute != null else "null"])
	var paket_bukan: PackedScene = daur_rute.get("adegan_kotak_surat_bukan") as PackedScene if daur_rute != null else null
	check(paket_bukan != null and paket_bukan.resource_path == BERKAS_SCENE_BUKAN, "rute.tscn: Objek.adegan_kotak_surat_bukan = %s" % BERKAS_SCENE_BUKAN)
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
	check(teks.find("SpriteRumah.titik_kotak_surat_dunia(rumah)") != -1 and teks.find("_buat_kotak(adegan_kotak_surat)") != -1 and teks.find("_buat_kotak(adegan_kotak_surat_bukan)") != -1, "posisi kotak surat (oranye dan abu-abu) dari SpriteRumah.titik_kotak_surat_dunia, node dari adegan_kotak_surat dan adegan_kotak_surat_bukan")
	check(teks.find("prop_kotak_surat_bukan") == -1, "rumah_daur_rute.gd tidak menyebut berkas sprite kotak surat abu-abu (hanya scene)")
	var scene_teks: String = FileAccess.get_file_as_string(BERKAS_SCENE)
	check(scene_teks.find("Color(") == -1 and scene_teks.find("modulate") == -1 and scene_teks.find("Shader") == -1, "scene kotak surat tanpa warna literal, modulate, atau shader (warna ada di PNG)")


## Kotak surat per jenis rumah di jendela sekarang: [pelanggan seberang, bukan pelanggan seberang, dekat] dan daftar pelanggaran.
## Pelanggan seberang = oranye saja, bukan pelanggan seberang = abu-abu saja di titik yang sama (titik kotak surat di zona), dekat = tidak ada.
func _periksa_kotak_per_rumah(daur: RumahDaurRute, rute: RouteBuilder.Rute, objek: Node, salah: Array[String]) -> Vector3i:
	var hitung: Vector3i = Vector3i.ZERO
	for indeks: int in daur.indeks_tampil():
		var rumah: RouteBuilder.RumahRute = rute.rumah[indeks]
		var oranye: Sprite2D = daur.kotak_surat(indeks) as Sprite2D
		var abu: Sprite2D = daur.kotak_surat_bukan(indeks) as Sprite2D
		if rumah.sisi == LoperAnim.Sisi.DEKAT:
			hitung.z += 1
			if oranye != null or abu != null:
				salah.append("%s: rumah dekat punya kotak surat" % rumah.id)
			continue
		var dipakai: Sprite2D = oranye if rumah.pelanggan else abu
		var lain: Sprite2D = abu if rumah.pelanggan else oranye
		var berkas: String = BERKAS_PNG if rumah.pelanggan else BERKAS_PNG_BUKAN
		var pijak: Vector2i = PIJAK if rumah.pelanggan else PIJAK_BUKAN
		if rumah.pelanggan:
			hitung.x += 1
		else:
			hitung.y += 1
		if lain != null:
			salah.append("%s: pelanggan %s juga punya kotak surat jenis lain" % [rumah.id, rumah.pelanggan])
		if dipakai == null or not dipakai.visible or dipakai.texture == null or dipakai.texture.resource_path != berkas:
			salah.append("%s: pelanggan %s tanpa sprite %s" % [rumah.id, rumah.pelanggan, berkas.get_file()])
			continue
		if dipakai.offset != -Vector2(pijak) or dipakai.get_parent() != objek:
			salah.append("%s: offset %s atau induk salah" % [rumah.id, dipakai.offset])
		# Titik pijak di layar -> dunia (rumus iso ditulis ulang): titik kotak surat seberang literal lateral -2,125, maju pos + 1,75 (sama
		# dengan kotak surat pelanggan dan jalan uji), di dalam zona kotak surat lateral -2,75..-1,75, maju pos + 1,25..pos + 2,5.
		var lateral: float = (dipakai.position.x / SKALA + dipakai.position.y / SETENGAH) / 2.0
		var maju: float = (dipakai.position.x / SKALA - dipakai.position.y / SETENGAH) / 2.0
		if not is_equal_approx(lateral, -2.125) or not is_equal_approx(maju, rumah.maju_ubin + 1.75):
			salah.append("%s: pijak (%.3f, %.3f), bukan titik kotak surat (-2,125; %.3f)" % [rumah.id, lateral, maju, rumah.maju_ubin + 1.75])
	return hitung


func _test_kotak_bukan_di_scene(akar: RuteMain, rute: RouteBuilder.Rute) -> void:
	_judul.call("Scene rute: kotak surat abu-abu di rumah bukan pelanggan seberang, oranye di pelanggan, dekat tanpa kotak surat, jendela daur")
	var daur: RumahDaurRute = akar.daur()
	var objek: Node = akar.find_child("Objek", true, false)
	var area: AreaKotakGambar = akar.find_child("AreaKotak", true, false) as AreaKotakGambar
	var total: Vector3i = Vector3i.ZERO
	var maks_node: int = 0
	var salah: Array[String] = []
	var jendela_salah: Array[String] = []
	for jarak: float in [0.0, 40.0, 90.0, 140.0, 200.0, 240.0, 90.0, 0.0]:
		daur.perbarui(jarak)
		if area != null:
			area.perbarui(jarak)
		var h: Vector3i = _periksa_kotak_per_rumah(daur, rute, objek, salah)
		total += h
		if daur.jumlah_kotak_surat() != h.x or daur.jumlah_kotak_surat_bukan() != h.y:
			jendela_salah.append("jarak %.0f: oranye %d/%d, abu %d/%d" % [jarak, daur.jumlah_kotak_surat(), h.x, daur.jumlah_kotak_surat_bukan(), h.y])
		if area != null and area.jumlah_area() != h.x:
			jendela_salah.append("jarak %.0f: area tanah %d, pelanggan seberang %d" % [jarak, area.jumlah_area(), h.x])
		maks_node = maxi(maks_node, daur.jumlah_node_kotak())
	check(total.x > 0 and total.y > 0 and total.z > 0, "kontrol: jendela yang diperiksa memuat pelanggan seberang (%d), bukan pelanggan seberang (%d), dan rumah dekat (%d)" % [total.x, total.y, total.z])
	check(salah.is_empty(), "pelanggan seberang = oranye saja, bukan pelanggan seberang = abu-abu saja di titik kotak surat yang sama, dekat = tanpa kotak surat: %s" % [salah.slice(0, 3)])
	check(area != null and jendela_salah.is_empty(), "jendela daur: jumlah kotak surat = rumah di jendela, area oranye di tanah hanya untuk pelanggan (tidak untuk abu-abu): %s" % [jendela_salah.slice(0, 3)])
	check(maks_node <= 20, "node kotak surat dipakai ulang dari kolam (paling banyak %d dibuat)" % maks_node)
	# Penilaian dan mode bantu tidak berubah: rumah bukan pelanggan tetap BUKAN_PELANGGAN, mode bantu hanya membidik pelanggan.
	var bukan: RouteBuilder.RumahRute = null
	for r: RouteBuilder.RumahRute in rute.rumah:
		if r.sisi == LoperAnim.Sisi.SEBERANG and not r.pelanggan:
			bukan = r
			break
	check(bukan != null, "kontrol: rute punya rumah bukan pelanggan seberang (%s)" % [bukan.id if bukan != null else "-"])
	if bukan == null:
		return
	var titik: Vector2 = SpriteRumah.titik_kotak_surat_dunia(bukan)
	var medan: MedanKoran = MedanKoran.dari_rute(rute)
	check(ZonaSasaran.klasifikasi(titik, MedanKoran.zona(medan, titik)) == ZonaSasaran.Hasil.BUKAN_PELANGGAN, "koran tepat di kotak surat abu-abu %s dinilai BUKAN_PELANGGAN (0 skor, combo putus, silang)" % bukan.id)
	var dibidik: Array[String] = []
	var sepeda: Vector2 = Vector2(-1.0, -(bukan.maju_ubin - 3.0))
	for z: ZonaSasaran.Zona in ZonaSasaran.zona_rumah(bukan):
		if BantuLempar.kandidat(z, LoperAnim.Sisi.SEBERANG, sepeda):
			dibidik.append(str(z.jenis))
	check(dibidik.is_empty(), "mode bantu tidak pernah membidik kotak surat abu-abu atau zona lain rumah bukan pelanggan: %s" % [dibidik])
	var kontrol: bool = false
	for r: RouteBuilder.RumahRute in rute.pelanggan:
		for z: ZonaSasaran.Zona in ZonaSasaran.zona_rumah(r):
			kontrol = kontrol or BantuLempar.kandidat(z, LoperAnim.Sisi.SEBERANG, Vector2(-1.0, -(r.maju_ubin - 3.0)))
		break
	check(kontrol, "kontrol: kotak surat pelanggan dari posisi relatif yang sama adalah kandidat mode bantu")


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
	_test_kotak_bukan_di_scene(akar, rute)
	if akar.sedang_jeda():
		akar.minta_lanjut()
	_tree.root.remove_child(akar)
	akar.free()
