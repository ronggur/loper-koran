class_name RumahDaurRute
extends Node2D
## Rumah dan kotak surat rute digambar dari data rute (AC-12 run fase3a-rute, usulan), jendela daur di sekitar sepeda.
##
## Induk Y-sort seperti `ObjekDaur`: rumah, kotak surat, dan sepeda anak langsungnya, jadi urutan gambar ditentukan posisi tegak titik
## pijak (sama dengan jalan uji). Hanya rumah di jendela `JendelaRute.rentang_sekitar` (`Config.RUTE_DAUR_*`) yang punya node; sprite
## dan kotak surat dipakai ulang dari kolam, bukan diinstansiasi ulang tiap langkah. Sprite = `house_perumahan_<jenis>_<pelanggan|bukan>`
## (`SpriteRumah.nama_rumah`), kotak surat sasaran (oranye) di rumah pelanggan, kotak surat abu-abu (bukan sasaran) di rumah
## bukan pelanggan di titik yang sama (keputusan pemilik 2026-10-17; tanpa area di tanah, penilaian dan mode bantu tidak
## berubah) di KEDUA sisi (run fase5d-sisi-dekat bagian B, D-3: sisi dekat cermin seberang di tepi trotoar dekat), dan titik pijak sprite dihitung dari tapak rumah
## (`SpriteRumah.pusat_tapak_dunia`), bukan dari `maju_ubin`. Tanda rintangan di data tidak digambar. Alfa penutup pemain diurus satu
## penerap (`PenerapPenutup`), bukan node ini: tiap rumah yang muncul didaftarkan ke penerap dan dilepas saat dibuang.
## Run fase5a bagian B (D-3d, usulan): rumah pelanggan yang sudah terantar (`SkorRute.Keadaan.terantar`, hanya dibaca lewat `atur_terantar`) mendapat satu sprite `prop_koran_terlipat` di terasnya
## (`SpriteRumah.titik_teras_dunia`), anak induk Y-sort ini sehingga digambar di atas sprite rumah (titik teras di depan tapak), dipakai ulang dari kolam, dan hilang bersama rumah di luar jendela daur.
## Run fase5d-sisi-dekat bagian B (AC-9): koran terlipat di teras rumah dekat digambar lewat pembungkus `Node2D` di induk Y-sort yang SAMA, diletakkan `RUTE_RUMAH_DEKAT_URUT_TERLIPAT_PX` piksel di depan titik pijak
## sprite rumahnya (teras dekat ada di BELAKANG titik pijak rumah menurut Y-sort, jadi sprite yang diletakkan langsung di titik terasnya tertimpa sprite rumahnya sendiri); sprite terlipat ada di titik teras
## yang sebenarnya sebagai anak pembungkus. Seberang tidak berubah.
## Run fase5d-sisi-dekat bagian A (P-1, keputusan pemilik 2026-10-22): tembok belakang run 5B dilepas, kavling dekat = halaman terbuka; sprite rumah dekat (desain ulang dengan teras
## menjorok, tanpa kotak surat terpanggang) digambar `RUTE_RUMAH_DEKAT_MUNDUR_UBIN` (0,5) lebih jauh dari jalan (`SpriteRumah.pusat_gambar_dunia`) dan didaftarkan ke penerap dengan kotak
## sprite nyata (`PenutupPemain.dari_rumah_gambar`).

## Scene kotak surat sasaran (rumah pelanggan): sprite berbentuk kotak surat, oranye placeholder (`scenes/entities/kotak_surat.tscn`).
@export var adegan_kotak_surat: PackedScene
## Scene kotak surat rumah bukan pelanggan sisi seberang: abu-abu, lebih rendah, tanpa celah surat (`scenes/entities/kotak_surat_bukan.tscn`).
## Hanya hiasan: bukan sasaran, tidak punya zona atau area sendiri (rumah tetap dinilai `BUKAN_PELANGGAN`).
@export var adegan_kotak_surat_bukan: PackedScene
## Penerap penutup pemain (opsional; diisi scene rute). Rumah yang muncul didaftarkan dengan kotak `PenutupPemain.dari_rumah_gambar` (rumah dekat digeser seperti gambarnya, run fase5b B2 P-4).
var penerap: PenerapPenutup = null

var _rute: RouteBuilder.Rute = null
var _tekstur: Dictionary = {}
## Indeks rumah (di `Rute.rumah`) -> sprite rumah yang sedang dipakai.
var _rumah: Dictionary = {}
## Indeks rumah -> kotak surat (hanya rumah pelanggan).
var _kotak: Dictionary = {}
## Indeks rumah -> kotak surat abu-abu (hanya rumah bukan pelanggan seberang).
var _kotak_bukan: Dictionary = {}
var _rumah_bebas: Array[Sprite2D] = []
## Indeks rumah -> sprite koran terlipat (rumah pelanggan terantar yang sedang digambar), kolam sprite bebas, dan id rumah terantar terakhir.
var _terlipat: Dictionary = {}
var _terlipat_bebas: Array[Sprite2D] = []
## Rumah dekat: indeks rumah -> pembungkus Y-sort sprite terlipatnya, dan kolam pembungkus bebas (tiap pembungkus membawa satu sprite terlipat sebagai anak).
var _pembungkus: Dictionary = {}
var _pembungkus_bebas: Array[Node2D] = []
var _terantar: Dictionary = {}
var _kotak_bebas: Array[Node2D] = []
var _kotak_bukan_bebas: Array[Node2D] = []
## Rentang indeks `[awal, akhir)` yang sedang dipasang; (-1, -1) = belum ada.
var _tampil: Vector2i = Vector2i(-1, -1)


## Mengganti rute: semua node rumah dikembalikan ke kolam lalu dipasang ulang untuk jarak 0.
func atur_rute(rute: RouteBuilder.Rute) -> void:
	for indeks: int in _rumah.keys():
		_lepas(indeks)
	_rute = rute
	_terantar = {}
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


## Memberi tahu daftar rumah terantar (id -> true, `SkorRute.Keadaan.terantar`; hanya dibaca): tiap rumah pelanggan di jendela daur yang terantar mendapat koran terlipat di terasnya, yang
## tidak lagi terantar (atau bukan pelanggan) kehilangannya. Dipanggil tiap langkah; murah (hanya rumah di jendela daur).
func atur_terantar(terantar: Dictionary) -> void:
	_terantar = terantar
	for indeks: int in _rumah.keys():
		_sinkron_terlipat(indeks)


## Banyaknya koran terlipat yang sedang digambar.
func jumlah_terlipat() -> int:
	return _terlipat.size()


## Indeks rumah (di `Rute.rumah`) yang sedang menampilkan koran terlipat, urut.
func indeks_terlipat() -> Array[int]:
	var hasil: Array[int] = []
	for indeks: int in _terlipat.keys():
		hasil.append(indeks)
	hasil.sort()
	return hasil


## Sprite koran terlipat rumah bernomor `indeks`, atau null.
func sprite_terlipat(indeks: int) -> Sprite2D:
	return _terlipat.get(indeks) as Sprite2D


## Banyaknya node sprite koran terlipat yang pernah dibuat (terpakai + kolam), untuk memeriksa tidak ada kebocoran node.
func jumlah_node_terlipat() -> int:
	return _terlipat.size() + _terlipat_bebas.size()


## Banyaknya pembungkus Y-sort koran terlipat rumah dekat yang pernah dibuat (terpakai + kolam).
func jumlah_node_pembungkus() -> int:
	return _pembungkus.size() + _pembungkus_bebas.size()


## Pembungkus Y-sort koran terlipat rumah bernomor `indeks` (hanya rumah dekat), atau null.
func pembungkus_terlipat(indeks: int) -> Node2D:
	return _pembungkus.get(indeks) as Node2D


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


## Banyaknya kotak surat abu-abu (rumah bukan pelanggan seberang) yang sedang digambar.
func jumlah_kotak_surat_bukan() -> int:
	return _kotak_bukan.size()


## Kotak surat abu-abu rumah bernomor `indeks`, atau null (pelanggan, sisi dekat, atau tidak sedang digambar).
func kotak_surat_bukan(indeks: int) -> Node2D:
	return _kotak_bukan.get(indeks) as Node2D


## Banyaknya node kotak surat (oranye dan abu-abu) yang pernah dibuat (terpakai + kolam), untuk memeriksa tidak ada kebocoran node.
func jumlah_node_kotak() -> int:
	return _kotak.size() + _kotak_bebas.size() + _kotak_bukan.size() + _kotak_bukan_bebas.size()


## Banyaknya node sprite rumah yang pernah dibuat (terpakai + kolam), untuk memeriksa tidak ada kebocoran node.
func jumlah_node_rumah() -> int:
	return _rumah.size() + _rumah_bebas.size()


func _pasang(indeks: int) -> void:
	var rumah: RouteBuilder.RumahRute = _rute.rumah[indeks]
	var nama: String = SpriteRumah.nama_rumah(rumah)
	var sprite: Sprite2D = _rumah_bebas.pop_back() if not _rumah_bebas.is_empty() else _buat_sprite()
	sprite.texture = _tekstur_untuk(nama)
	sprite.offset = -Vector2(SpriteRumah.titik_pijak(nama))
	sprite.position = Iso.posisi_gambar(SpriteRumah.pusat_gambar_dunia(rumah))
	sprite.name = "Rumah_%s" % rumah.id.replace("@", "_")
	sprite.modulate.a = PenutupPemain.alfa(false)
	sprite.visible = true
	_rumah[indeks] = sprite
	if penerap != null:
		penerap.daftarkan(sprite, PenutupPemain.dari_rumah_gambar(rumah))
	_sinkron_terlipat(indeks)
	if rumah.sisi == LoperAnim.Sisi.TIDAK_ADA:
		return
	if rumah.pelanggan and adegan_kotak_surat != null:
		var kotak: Node2D = _kotak_bebas.pop_back() if not _kotak_bebas.is_empty() else _buat_kotak(adegan_kotak_surat)
		_taruh_kotak(kotak, rumah, "Kotak_%s")
		_kotak[indeks] = kotak
	elif not rumah.pelanggan and adegan_kotak_surat_bukan != null:
		var bukan: Node2D = _kotak_bukan_bebas.pop_back() if not _kotak_bukan_bebas.is_empty() else _buat_kotak(adegan_kotak_surat_bukan)
		_taruh_kotak(bukan, rumah, "KotakBukan_%s")
		_kotak_bukan[indeks] = bukan


## Kotak surat (oranye atau abu-abu) di titik zona kotak surat rumah (`SpriteRumah.titik_kotak_surat_dunia`; dekat = cermin seberang).
func _taruh_kotak(kotak: Node2D, rumah: RouteBuilder.RumahRute, pola_nama: String) -> void:
	kotak.position = Iso.posisi_gambar(SpriteRumah.titik_kotak_surat_dunia(rumah))
	kotak.name = pola_nama % rumah.id.replace("@", "_")
	kotak.visible = true


## Memasang atau melepas koran terlipat rumah `indeks` (yang sedang digambar) sesuai status terantarnya: tepat satu bila rumah pelanggan dan terantar, selain itu tidak ada.
func _sinkron_terlipat(indeks: int) -> void:
	var rumah: RouteBuilder.RumahRute = _rute.rumah[indeks]
	var perlu: bool = rumah.pelanggan and _terantar.has(rumah.id)
	var ada: bool = _terlipat.has(indeks)
	if perlu and not ada:
		var sprite: Sprite2D = _terlipat_bebas.pop_back() if not _terlipat_bebas.is_empty() else _buat_terlipat()
		var titik_teras: Vector2 = Iso.posisi_gambar(SpriteRumah.titik_teras_dunia(rumah))
		if rumah.sisi == LoperAnim.Sisi.DEKAT:
			var pembungkus: Node2D = _pembungkus_bebas.pop_back() if not _pembungkus_bebas.is_empty() else _buat_pembungkus()
			pembungkus.position = Iso.posisi_gambar(SpriteRumah.pusat_gambar_dunia(rumah)) + Vector2(0.0, float(Config.RUTE_RUMAH_DEKAT_URUT_TERLIPAT_PX))
			pembungkus.visible = true
			sprite.reparent(pembungkus, false)
			sprite.position = titik_teras - pembungkus.position
			_pembungkus[indeks] = pembungkus
		else:
			sprite.position = titik_teras
		sprite.name = "Terlipat_%s" % rumah.id.replace("@", "_")
		sprite.visible = true
		_terlipat[indeks] = sprite
	elif not perlu and ada:
		_lepas_terlipat(indeks)


func _lepas_terlipat(indeks: int) -> void:
	var sprite: Sprite2D = _terlipat.get(indeks) as Sprite2D
	_terlipat.erase(indeks)
	var pembungkus: Node2D = _pembungkus.get(indeks) as Node2D
	_pembungkus.erase(indeks)
	if sprite != null:
		sprite.visible = false
		if pembungkus != null:
			sprite.reparent(self, false)
		_terlipat_bebas.append(sprite)
	if pembungkus != null:
		pembungkus.visible = false
		_pembungkus_bebas.append(pembungkus)


## Pembungkus Y-sort koran terlipat rumah dekat: anak induk ini (diurutkan bersama rumah, kotak surat, dan sepeda), membawa sprite terlipat sebagai anak.
func _buat_pembungkus() -> Node2D:
	var pembungkus: Node2D = Node2D.new()
	pembungkus.name = "PembungkusTerlipat"
	add_child(pembungkus)
	return pembungkus


func _buat_terlipat() -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.centered = false
	sprite.texture = GambarSprite.tekstur(SpriteKoran.SPRITE_TERLIPAT)
	sprite.offset = -Vector2(DefSprite.pijak(SpriteKoran.SPRITE_TERLIPAT))
	add_child(sprite)
	return sprite


func _lepas(indeks: int) -> void:
	_lepas_terlipat(indeks)
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
	var bukan: Node2D = _kotak_bukan.get(indeks) as Node2D
	_kotak_bukan.erase(indeks)
	if bukan != null:
		bukan.visible = false
		_kotak_bukan_bebas.append(bukan)


func _buat_sprite() -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.centered = false
	add_child(sprite)
	return sprite


func _buat_kotak(adegan: PackedScene) -> Node2D:
	var kotak: Node2D = adegan.instantiate() as Node2D
	add_child(kotak)
	return kotak


func _tekstur_untuk(nama: String) -> Texture2D:
	if not _tekstur.has(nama):
		_tekstur[nama] = load(SpriteRumah.jalur_png(nama)) as Texture2D
	return _tekstur[nama]

