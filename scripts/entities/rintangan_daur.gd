class_name RintanganDaur
extends Node2D
## Rintangan rute digambar hidup (AC-20 run fase3b-rintangan-skor bagian B, usulan): anjing penjaga dan mobil keluar garasi dari keadaan
## `RintanganRute` (logika murni), jendela daur di sekitar sepeda.
##
## Node tipis: perilaku, posisi, nama animasi, arah cermin, dan ikon "!" semuanya dibaca dari `RintanganRute` tiap langkah; node ini hanya
## memasang sprite. Anak dari induk Y-sort rumah dan sepeda (`RumahDaurRute`, `y_sort_enabled`), dengan `y_sort_enabled` sendiri, jadi
## sprite rintangan diurutkan bersama rumah, kotak surat, dan sepeda menurut posisi tegak titik pijaknya (titik pijak sheet = proyeksi titik
## (0, 0, 0) model di `tools/env_art/fase3.py`: pusat anjing, pusat tapak mobil = `RintanganRute.posisi`). Hanya rintangan yang posisinya di
## jendela `RUTE_DAUR_MUNDUR_UBIN` di belakang sampai `RUTE_DAUR_MAJU_UBIN` di depan sepeda punya node; node dipakai ulang dari kolam per jenis.
## Sprite dari `scenes/entities/anjing_penjaga.tscn` dan `mobil_garasi.tscn` (SpriteFrames dari `assets/sprites/obstacles/*_sheet.png`,
## titik pijak dan animasi dari JSON sheet, dijaga tes). Alfa penutup pemain diurus SATU `PenerapPenutup`: tiap rintangan yang tampil
## didaftarkan dengan kotak `RintanganRute.kotak` setinggi `RintanganRute.tinggi_penutup` (kotak diperbarui tiap langkah karena rintangan
## bergerak) dan dilepas saat dibuang.

@export var adegan_anjing: PackedScene
@export var adegan_mobil: PackedScene
## Penerap penutup pemain (diisi scene rute).
var penerap: PenerapPenutup = null

## Id rintangan -> sprite yang sedang dipakai.
var _node: Dictionary = {}
## Jenis (`RintanganRute.Jenis`) -> Array[AnimatedSprite2D] kolam bebas.
var _bebas: Dictionary = {}


## Memasang, memperbarui, dan melepas sprite supaya sesuai keadaan `k` dan sepeda yang sudah menempuh `jarak_ubin`.
func perbarui(k: RintanganRute.Keadaan, jarak_ubin: float) -> void:
	var tampil: Array[RintanganRute.Item] = RintanganRute.di_rentang(k, jarak_ubin - Config.RUTE_DAUR_MUNDUR_UBIN, jarak_ubin + Config.RUTE_DAUR_MAJU_UBIN)
	var ada: Dictionary = {}
	for item: RintanganRute.Item in tampil:
		ada[item.id] = true
	# Lepas dulu, baru pasang: node yang dibuang langkah ini langsung dipakai ulang dari kolam.
	for id: int in _node.keys():
		if not ada.has(id):
			_lepas(id)
	for item: RintanganRute.Item in tampil:
		var sprite: AnimatedSprite2D = _node.get(item.id) as AnimatedSprite2D
		if sprite == null:
			sprite = _pasang(item)
		_atur(sprite, item)


## Melepas semua sprite ke kolam (rute disusun ulang).
func lepas_semua() -> void:
	for id: int in _node.keys():
		_lepas(id)


## Banyaknya rintangan yang sedang digambar.
func jumlah_tampil() -> int:
	return _node.size()


## Id rintangan yang sedang digambar, urut.
func id_tampil() -> Array[int]:
	var hasil: Array[int] = []
	for id: int in _node.keys():
		hasil.append(id)
	hasil.sort()
	return hasil


## Sprite rintangan ber-id `id`, atau null bila tidak sedang digambar.
func sprite_rintangan(id: int) -> AnimatedSprite2D:
	return _node.get(id) as AnimatedSprite2D


## Ikon "!" sprite anjing (anak `Seru`), atau null.
static func ikon_seru(sprite: AnimatedSprite2D) -> Sprite2D:
	return sprite.get_node_or_null(^"Seru") as Sprite2D if sprite != null else null


## Banyaknya node sprite yang pernah dibuat (terpakai + kolam), untuk memeriksa tidak ada kebocoran node.
func jumlah_node() -> int:
	var jumlah: int = _node.size()
	for daftar: Array in _bebas.values():
		jumlah += daftar.size()
	return jumlah


func _atur(sprite: AnimatedSprite2D, item: RintanganRute.Item) -> void:
	var p: Vector2 = RintanganRute.posisi(item)
	sprite.position = Iso.posisi_gambar(Vector2(p.x, -p.y))
	var anim: StringName = StringName(RintanganRute.animasi(item))
	if sprite.animation != anim:
		sprite.play(anim)
	sprite.flip_h = RintanganRute.cermin_sprite(item)
	var seru: Sprite2D = ikon_seru(sprite)
	if seru != null:
		seru.position = Vector2(0, -Config.RINTANGAN_SERU_ATAS_PX)
		seru.visible = RintanganRute.ikon_seru(item)
	if penerap != null:
		penerap.daftarkan(sprite, PenutupPemain.buat(RintanganRute.kotak(item), RintanganRute.tinggi_penutup(item), "rintangan_%d" % item.id))


func _pasang(item: RintanganRute.Item) -> AnimatedSprite2D:
	var kolam: Array = _bebas.get(item.jenis, [])
	var sprite: AnimatedSprite2D = kolam.pop_back() as AnimatedSprite2D if not kolam.is_empty() else _buat(item.jenis)
	sprite.name = "Rintangan_%d_%s" % [item.id, item.nama_jenis]
	sprite.set_meta(&"jenis", item.jenis)
	sprite.modulate.a = PenutupPemain.alfa(false)
	sprite.visible = true
	_node[item.id] = sprite
	return sprite


func _lepas(id: int) -> void:
	var sprite: AnimatedSprite2D = _node.get(id) as AnimatedSprite2D
	_node.erase(id)
	if sprite == null:
		return
	if penerap != null:
		penerap.lepas(sprite)
	sprite.visible = false
	var jenis: int = int(sprite.get_meta(&"jenis", RintanganRute.Jenis.ANJING))
	if not _bebas.has(jenis):
		_bebas[jenis] = []
	(_bebas[jenis] as Array).append(sprite)


func _buat(jenis: RintanganRute.Jenis) -> AnimatedSprite2D:
	var adegan: PackedScene = adegan_mobil if jenis == RintanganRute.Jenis.MOBIL else adegan_anjing
	var sprite: AnimatedSprite2D = adegan.instantiate() as AnimatedSprite2D
	add_child(sprite)
	return sprite
