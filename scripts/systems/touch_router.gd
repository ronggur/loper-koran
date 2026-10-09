class_name TouchRouter
extends RefCounted
## Pelacak jari untuk stick dan swipe, logika murni tanpa node (GDD 5.2, DESIGN_SPEC 3.7, rule `ui-scenes`).
##
## Instance `RefCounted`: node input hanya menerjemahkan `InputEvent` menjadi panggilan `tekan`, `geser`,
## `lepas`, `batal`, dan `batal_semua`. Tiap jari dilacak lewat `index`-nya sendiri, karena stick dan swipe
## aktif bersamaan. Aturan:
## - zona hanya menentukan klaim saat jari TURUN (`TouchZones`); jari yang sudah mengklaim tetap stick atau
##   swipe walau digeser ke zona lain, dan sentuhan yang mulai di luar kedua zona tidak pernah diklaim;
## - stick melayang: titik asal = titik sentuh pertama, vektor mengikuti geseran (`StickMap`);
## - satu slot per peran: jari kedua di zona yang slotnya terisi diabaikan, tidak mengganggu yang pertama;
## - jari dengan `index` tak dikenal (drag atau lepas tanpa turun) dan turun ganda dengan `index` sama diabaikan;
## - waktu selalu parameter (`waktu_detik`), tidak pernah memanggil `Time`.
## Koordinat semuanya dalam ruang viewport game (bukan piksel jendela).

## Satu swipe selesai: titik awal, titik akhir (koordinat viewport game), durasi dari parameter waktu.
signal swipe_selesai(awal: Vector2, akhir: Vector2, durasi_detik: float)

const TIDAK_ADA: int = -1

## Lebar viewport game saat ini, piksel. Diperbarui node input sebelum meneruskan event.
var lebar_viewport: int = Config.LAYAR_LEBAR_DASAR_PX
## Jumlah swipe yang selesai sejak instance dibuat (tiap swipe dicatat tepat sekali).
var jumlah_swipe_selesai: int = 0

var _kidal: bool = false
var _index_stick: int = TIDAK_ADA
var _asal_stick: Vector2 = Vector2.ZERO
var _posisi_stick: Vector2 = Vector2.ZERO
var _index_swipe: int = TIDAK_ADA
var _awal_swipe: Vector2 = Vector2.ZERO
var _posisi_swipe: Vector2 = Vector2.ZERO
var _waktu_awal_swipe: float = 0.0


## Opsi kidal: True menukar zona. Mengganti nilai membatalkan semua jari aktif.
func atur_kidal(nilai: bool) -> void:
	if nilai == _kidal:
		return
	_kidal = nilai
	batal_semua()


func kidal() -> bool:
	return _kidal


## Jari turun. Mengklaim stick atau swipe menurut zona tempat jari turun, bila slotnya kosong.
func tekan(index: int, posisi: Vector2, waktu_detik: float) -> void:
	if index < 0 or not posisi.is_finite():
		return
	if index == _index_stick or index == _index_swipe:
		return
	match TouchZones.zona_di(posisi, lebar_viewport, _kidal):
		TouchZones.Zona.STICK:
			if _index_stick == TIDAK_ADA:
				_index_stick = index
				_asal_stick = posisi
				_posisi_stick = posisi
		TouchZones.Zona.SWIPE:
			if _index_swipe == TIDAK_ADA:
				_index_swipe = index
				_awal_swipe = posisi
				_posisi_swipe = posisi
				_waktu_awal_swipe = waktu_detik


## Jari bergeser. Hanya jari yang sudah mengklaim yang berpengaruh. `index` negatif sama dengan sentinel
## `TIDAK_ADA` dan harus ditolak di awal, kalau tidak slot yang kosong ikut terbaca "cocok".
func geser(index: int, posisi: Vector2) -> void:
	if index < 0 or not posisi.is_finite():
		return
	if index == _index_stick:
		_posisi_stick = posisi
	elif index == _index_swipe:
		_posisi_swipe = posisi


## Jari diangkat. Stick: vektor kembali nol dan slot bebas. Swipe: hasilnya dicatat tepat sekali.
## `index` negatif ditolak (sentinel `TIDAK_ADA`), kalau tidak slot swipe yang kosong tercatat sebagai swipe palsu.
func lepas(index: int, posisi: Vector2, waktu_detik: float) -> void:
	if index < 0:
		return
	if index == _index_stick:
		_bebaskan_stick()
	elif index == _index_swipe:
		var akhir: Vector2 = posisi if posisi.is_finite() else _posisi_swipe
		var durasi: float = maxf(0.0, waktu_detik - _waktu_awal_swipe) if is_finite(waktu_detik) else 0.0
		var awal: Vector2 = _awal_swipe
		_bebaskan_swipe()
		jumlah_swipe_selesai += 1
		swipe_selesai.emit(awal, akhir, durasi)


## Satu jari dibatalkan sistem (mis. gestur sistem mengambil alih): dilepas tanpa mencatat swipe.
func batal(index: int) -> void:
	if index < 0:
		return
	if index == _index_stick:
		_bebaskan_stick()
	elif index == _index_swipe:
		_bebaskan_swipe()


## Melepas semua jari tanpa mencatat swipe. Dipanggil saat app di-background, kehilangan fokus, atau kidal berganti.
func batal_semua() -> void:
	_bebaskan_stick()
	_bebaskan_swipe()


func stick_aktif() -> bool:
	return _index_stick != TIDAK_ADA


func swipe_aktif() -> bool:
	return _index_swipe != TIDAK_ADA


## Jumlah jari yang sedang diklaim (0 sampai 2).
func jumlah_jari_aktif() -> int:
	return (1 if stick_aktif() else 0) + (1 if swipe_aktif() else 0)


## Vektor kontrol stick (panjang 0 sampai 1, y positif = atas), nol bila stick tidak aktif (`StickMap`).
func vektor_stick() -> Vector2:
	if not stick_aktif():
		return Vector2.ZERO
	return StickMap.petakan(_posisi_stick - _asal_stick)


## Titik asal stick melayang (titik sentuh pertama), koordinat viewport game.
func asal_stick() -> Vector2:
	return _asal_stick


## Geseran jari dari titik asal yang dijepit ke jangkauan stick, sumbu layar (untuk menggambar knob).
func geser_stick_terjepit() -> Vector2:
	if not stick_aktif():
		return Vector2.ZERO
	return StickMap.jepit_geser(_posisi_stick - _asal_stick)


## Titik awal swipe yang sedang ditahan, koordinat viewport game.
func awal_swipe() -> Vector2:
	return _awal_swipe


## Posisi jari swipe saat ini, koordinat viewport game.
func posisi_swipe() -> Vector2:
	return _posisi_swipe


func _bebaskan_stick() -> void:
	_index_stick = TIDAK_ADA
	_asal_stick = Vector2.ZERO
	_posisi_stick = Vector2.ZERO


func _bebaskan_swipe() -> void:
	_index_swipe = TIDAK_ADA
	_awal_swipe = Vector2.ZERO
	_posisi_swipe = Vector2.ZERO
	_waktu_awal_swipe = 0.0
