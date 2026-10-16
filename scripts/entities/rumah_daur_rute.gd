class_name RumahDaurRute
extends Node2D
## Rumah dan kotak surat rute digambar dari data rute (AC-12 run fase3a-rute, usulan), jendela daur di sekitar sepeda.
##
## Induk Y-sort seperti `ObjekDaur`: rumah, kotak surat, dan sepeda anak langsungnya, jadi urutan gambar ditentukan posisi tegak titik
## pijak (sama dengan jalan uji). Hanya rumah di jendela `JendelaRute.rentang_sekitar` (`Config.RUTE_DAUR_*`) yang punya node; sprite
## dan kotak surat dipakai ulang dari kolam, bukan diinstansiasi ulang tiap langkah. Sprite = `house_perumahan_<jenis>_<pelanggan|bukan>`
## (`SpriteRumah.nama_rumah`), kotak surat sasaran hanya di rumah pelanggan, dan titik pijak sprite dihitung dari tapak rumah
## (`SpriteRumah.pusat_tapak_dunia`), bukan dari `maju_ubin`. Tanda rintangan di data tidak digambar. Alfa penutup pemain diurus satu
## penerap (`PenerapPenutup`), bukan node ini: tiap rumah yang muncul didaftarkan ke penerap dan dilepas saat dibuang.

## Scene kotak surat sasaran (rumah pelanggan): sprite berbentuk kotak surat, oranye placeholder (`scenes/entities/kotak_surat.tscn`).
@export var adegan_kotak_surat: PackedScene
## Penerap penutup pemain (opsional; diisi scene rute). Rumah yang muncul didaftarkan dengan kotak `PenutupPemain.dari_rumah`.
var penerap: PenerapPenutup = null

var _rute: RouteBuilder.Rute = null
var _tekstur: Dictionary = {}
## Indeks rumah (di `Rute.rumah`) -> sprite rumah yang sedang dipakai.
var _rumah: Dictionary = {}
## Indeks rumah -> kotak surat (hanya rumah pelanggan).
var _kotak: Dictionary = {}
var _rumah_bebas: Array[Sprite2D] = []
var _kotak_bebas: Array[Node2D] = []
## Rentang indeks `[awal, akhir)` yang sedang dipasang; (-1, -1) = belum ada.
var _tampil: Vector2i = Vector2i(-1, -1)


## Mengganti rute: semua node rumah dikembalikan ke kolam lalu dipasang ulang untuk jarak 0.
func atur_rute(rute: RouteBuilder.Rute) -> void:
	for indeks: int in _rumah.keys():
		_lepas(indeks)
	_rute = rute
	# Semua PNG jenis rumah yang dipakai rute dimuat sekarang, bukan di tengah frame saat rumah pertama jenis itu muncul.
	for r: RouteBuilder.RumahRute in rute.rumah:
		_tekstur_untuk(SpriteRumah.nama_rumah(r))
	_tampil = Vector2i(-1, -1)
	perbarui(0.0)


## Memasang dan melepas rumah supaya jendela daur sesuai sepeda yang sudah menempuh `jarak_ubin`. Tidak melakukan apa pun bila
## rentang tidak berubah.
func perbarui(jarak_ubin: float) -> void:
	if _rute == null:
		return
	var rentang: Vector2i = JendelaRute.rentang_sekitar(_rute.rumah, jarak_ubin)
	if rentang == _tampil:
		return
	_tampil = rentang
	for indeks: int in _rumah.keys():
		if indeks < rentang.x or indeks >= rentang.y:
			_lepas(indeks)
	for indeks: int in range(rentang.x, rentang.y):
		if not _rumah.has(indeks):
			_pasang(indeks)


## Banyaknya rumah yang sedang digambar.
func jumlah_rumah() -> int:
	return _rumah.size()


## Banyaknya tekstur rumah yang sudah dimuat (jenis berbeda yang dipakai rute; dimuat di `atur_rute`).
func jumlah_tekstur_dimuat() -> int:
	return _tekstur.size()


## Banyaknya kotak surat yang sedang digambar.
func jumlah_kotak_surat() -> int:
	return _kotak.size()


## Indeks rumah (di `Rute.rumah`) yang sedang digambar, urut.
func indeks_tampil() -> Array[int]:
	var hasil: Array[int] = []
	for indeks: int in _rumah.keys():
		hasil.append(indeks)
	hasil.sort()
	return hasil


## Sprite rumah bernomor `indeks` (di `Rute.rumah`), atau null bila tidak sedang digambar.
func sprite_rumah(indeks: int) -> Sprite2D:
	return _rumah.get(indeks) as Sprite2D


## Kotak surat rumah bernomor `indeks`, atau null (bukan pelanggan atau tidak sedang digambar).
func kotak_surat(indeks: int) -> Node2D:
	return _kotak.get(indeks) as Node2D


## Banyaknya node sprite rumah yang pernah dibuat (terpakai + kolam), untuk memeriksa tidak ada kebocoran node.
func jumlah_node_rumah() -> int:
	return _rumah.size() + _rumah_bebas.size()


func _pasang(indeks: int) -> void:
	var rumah: RouteBuilder.RumahRute = _rute.rumah[indeks]
	var nama: String = SpriteRumah.nama_rumah(rumah)
	var sprite: Sprite2D = _rumah_bebas.pop_back() if not _rumah_bebas.is_empty() else _buat_sprite()
	sprite.texture = _tekstur_untuk(nama)
	sprite.offset = -Vector2(SpriteRumah.titik_pijak(nama))
	sprite.position = Iso.posisi_gambar(SpriteRumah.pusat_tapak_dunia(rumah))
	sprite.name = "Rumah_%s" % rumah.id.replace("@", "_")
	sprite.modulate.a = PenutupPemain.alfa(false)
	sprite.visible = true
	_rumah[indeks] = sprite
	if penerap != null:
		penerap.daftarkan(sprite, PenutupPemain.dari_rumah(rumah))
	if rumah.pelanggan and rumah.sisi == LoperAnim.Sisi.SEBERANG and adegan_kotak_surat != null:
		var kotak: Node2D = _kotak_bebas.pop_back() if not _kotak_bebas.is_empty() else _buat_kotak()
		kotak.position = Iso.posisi_gambar(SpriteRumah.titik_kotak_surat_dunia(rumah))
		kotak.name = "Kotak_%s" % rumah.id.replace("@", "_")
		kotak.visible = true
		_kotak[indeks] = kotak


func _lepas(indeks: int) -> void:
	var sprite: Sprite2D = _rumah.get(indeks) as Sprite2D
	_rumah.erase(indeks)
	if sprite != null:
		if penerap != null:
			penerap.lepas(sprite)
		sprite.visible = false
		_rumah_bebas.append(sprite)
	var kotak: Node2D = _kotak.get(indeks) as Node2D
	_kotak.erase(indeks)
	if kotak != null:
		kotak.visible = false
		_kotak_bebas.append(kotak)


func _buat_sprite() -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.centered = false
	add_child(sprite)
	return sprite


func _buat_kotak() -> Node2D:
	var kotak: Node2D = adegan_kotak_surat.instantiate() as Node2D
	add_child(kotak)
	return kotak


func _tekstur_untuk(nama: String) -> Texture2D:
	if not _tekstur.has(nama):
		_tekstur[nama] = load(SpriteRumah.jalur_png(nama)) as Texture2D
	return _tekstur[nama]
