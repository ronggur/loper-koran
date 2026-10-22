class_name DekorDaur
extends Node2D
## Dekor pinggir jalan rute digambar dari data rute (tong sampah, pohon, lampu jalan; run fase5b-tembok-dekor bagian B2, AC-11, usulan), jendela daur di sekitar sepeda.
##
## Node tipis bergaya `RintanganDaur`: anak induk Y-sort rumah dan sepeda (`RumahDaurRute`), dengan `y_sort_enabled` sendiri, jadi sprite dekor diurutkan bersama rumah, kotak
## surat, rintangan, dan sepeda menurut posisi tegak titik pijaknya (pusat tapak kaki, `DekorRute.titik_dunia`). Hanya dekor yang `maju_ubin`-nya di jendela daur
## (`DekorRute.rentang_sekitar`, `Config.RUTE_DAUR_*`) punya node; sprite dipakai ulang dari kolam, bukan diinstansiasi ulang tiap langkah. Sprite per jenis, varian, dan sisi dari
## `DekorRute.nama_sprite` (PNG di `assets/sprites/props/`), titik pijak dan ukuran sel dari tabel `Config.RUTE_DEKOR_SPRITE*` (dijaga tes = JSON dan PNG). Semua PNG yang dipakai
## rute dimuat sekali di `atur_rute` (bukan di `_draw` atau saat dekor pertama muncul) dan dipegang node ini.
##
## Dekor sisi `dekat` (pohon, lampu, tong sampah) didaftarkan ke SATU `PenerapPenutup` (`PenutupPemain.dari_dekor`, semi-transparan bila menutupi pemain) dan dilepas bersama sprite saat keluar jendela; dekor sisi `seberang`
## hanya gambar. Dekor bukan penghalang: tidak masuk `Tabrakan`, `RintanganRute`, `MedanKoran`, zona, atau penilaian lemparan.

## Penerap penutup pemain (diisi scene rute).
var penerap: PenerapPenutup = null

var _rute: RouteBuilder.Rute = null
## Indeks dekor (di `Rute.dekor`) -> sprite yang sedang dipakai, kolam sprite bebas, tekstur per nama sprite, dan banyaknya pemuatan PNG dari disk.
var _node: Dictionary = {}
var _bebas: Array[Sprite2D] = []
var _tekstur: Dictionary = {}
var _muat: int = 0
## Rentang indeks `[awal, akhir)` yang sedang dipasang; (-1, -1) = belum ada.
var _tampil: Vector2i = Vector2i(-1, -1)


## Mengganti rute: semua sprite dikembalikan ke kolam, semua PNG dekor rute dimuat, lalu dipasang untuk jarak 0.
func atur_rute(rute: RouteBuilder.Rute) -> void:
	for indeks: int in _node.keys():
		_lepas(indeks)
	_rute = rute
	for butir: RouteBuilder.DekorItem in rute.dekor:
		_tekstur_untuk(DekorRute.nama_sprite(butir.jenis, butir.varian, butir.sisi))
	_tampil = Vector2i(-1, -1)
	perbarui(0.0)


## Memasang dan melepas dekor supaya jendela daur sesuai sepeda yang sudah menempuh `jarak_ubin`. Tidak berbuat apa pun bila rentang tidak berubah.
func perbarui(jarak_ubin: float) -> void:
	if _rute == null:
		return
	var rentang: Vector2i = DekorRute.rentang_sekitar(_rute.dekor, jarak_ubin)
	if rentang == _tampil:
		return
	_tampil = rentang
	for indeks: int in _node.keys():
		if indeks < rentang.x or indeks >= rentang.y:
			_lepas(indeks)
	for indeks: int in range(rentang.x, rentang.y):
		if not _node.has(indeks):
			_pasang(indeks)


## Banyaknya dekor yang sedang digambar.
func jumlah_tampil() -> int:
	return _node.size()


## Indeks dekor (di `Rute.dekor`) yang sedang digambar, urut.
func indeks_tampil() -> Array[int]:
	var hasil: Array[int] = []
	for indeks: int in _node.keys():
		hasil.append(indeks)
	hasil.sort()
	return hasil


## Sprite dekor bernomor `indeks`, atau null bila tidak sedang digambar.
func sprite_dekor(indeks: int) -> Sprite2D:
	return _node.get(indeks) as Sprite2D


## Banyaknya node sprite yang pernah dibuat (terpakai + kolam), untuk memeriksa tidak ada kebocoran node.
func jumlah_node() -> int:
	return _node.size() + _bebas.size()


## Banyaknya tekstur yang sudah dimuat (nama sprite berbeda yang dipakai rute; dimuat di `atur_rute`).
func jumlah_tekstur() -> int:
	return _tekstur.size()


## Banyaknya pemuatan PNG dari disk sejak node dibuat (sama dengan jumlah nama sprite berbeda yang dipakai).
func jumlah_muat() -> int:
	return _muat


func _pasang(indeks: int) -> void:
	var butir: RouteBuilder.DekorItem = _rute.dekor[indeks]
	var nama: String = DekorRute.nama_sprite(butir.jenis, butir.varian, butir.sisi)
	var sprite: Sprite2D = _bebas.pop_back() if not _bebas.is_empty() else _buat()
	sprite.texture = _tekstur_untuk(nama)
	sprite.offset = -Vector2(DekorRute.pijak(nama))
	sprite.position = Iso.posisi_gambar(DekorRute.titik_dunia(butir.jenis, butir.sisi, butir.maju_ubin))
	sprite.name = "Dekor_%s" % butir.id.replace("@", "_").replace(":", "_")
	sprite.modulate.a = PenutupPemain.alfa(false)
	sprite.visible = true
	_node[indeks] = sprite
	if penerap != null and DekorRute.menutupi(butir.jenis, butir.varian, butir.sisi):
		penerap.daftarkan(sprite, PenutupPemain.dari_dekor(butir))


func _lepas(indeks: int) -> void:
	var sprite: Sprite2D = _node.get(indeks) as Sprite2D
	_node.erase(indeks)
	if sprite == null:
		return
	if penerap != null:
		penerap.lepas(sprite)
	sprite.visible = false
	_bebas.append(sprite)


func _buat() -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.centered = false
	add_child(sprite)
	return sprite


func _tekstur_untuk(nama: String) -> Texture2D:
	if not _tekstur.has(nama):
		_muat += 1
		_tekstur[nama] = load(DekorRute.jalur_png(nama)) as Texture2D
	return _tekstur[nama]
