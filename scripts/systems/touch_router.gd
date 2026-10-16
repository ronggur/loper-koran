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
##
## Tap (mode bantu, GDD 5.3; D-1 run fase2b-bantu-audio): sentuhan yang mengklaim slot swipe dan, SELAMA SELURUH HIDUPNYA, panjang swipe
## |v| (dari titik awal ke posisi mana pun yang pernah dicapai, termasuk posisi lepas) tidak pernah cukup untuk melempar
## (`ThrowSolver.cukup_panjang`: < min 6% lebar viewport; tepat min = swipe). Sentuhan yang pernah mencapai min lalu ditarik kembali
## BUKAN tap (tetap batal). Tap tidak dibatasi durasi. Saat jari tap diangkat, `swipe_selesai` tetap dipancarkan seperti biasa (jalan uji
## menolaknya karena pendek), lalu `tap_selesai` dengan posisi tap = titik awal sentuhan. `batal`/`batal_semua` tidak pernah menjadi tap,
## dan sentuhan yang mulai di luar zona swipe (stick, tombol HUD) tidak pernah diklaim, jadi juga bukan tap.
##
## Bel (AC-15 run fase3b-rintangan-skor, DESIGN_SPEC 3.8): jari yang TURUN di zona tap bel (`TouchZones.Zona.BEL`) memancarkan `bel_ditekan`
## sekali dan dilacak sebagai jari bel (untuk gambar tombol ditekan) sampai diangkat atau batal; jari itu tidak pernah menjadi stick, swipe,
## garis bidik, atau tap mode bantu, walau digeser ke zona lain. Swipe yang dimulai di luar lalu melewati tombol tetap swipe (zona hanya
## dibaca saat turun). Bel tidak memakai slot stick atau swipe, jadi stick + bel dan swipe + bel tidak saling mengganggu.

## Satu swipe selesai: titik awal, titik akhir (koordinat viewport game), durasi dari parameter waktu.
signal swipe_selesai(awal: Vector2, akhir: Vector2, durasi_detik: float)
## Satu tap selesai (D-1): posisi tap = titik awal sentuhan (koordinat viewport game), durasi dari parameter waktu. Dipancarkan sesudah
## `swipe_selesai` untuk sentuhan yang sama.
signal tap_selesai(posisi: Vector2, durasi_detik: float)
## Jari turun di zona tap bel: posisi turun (koordinat viewport game). Tepat sekali per sentuhan.
signal bel_ditekan(posisi: Vector2)

const TIDAK_ADA: int = -1

## Lebar viewport game saat ini, piksel. Diperbarui node input sebelum meneruskan event.
var lebar_viewport: int = Config.LAYAR_LEBAR_DASAR_PX
## Geseran pusat zona tap bel karena zona aman, piksel game (`HudDasar.geser_bel`, diatur adegan; run fase3c-hud-hasil). Bawaan nol.
var geser_bel: Vector2 = Vector2.ZERO
## Jumlah swipe yang selesai sejak instance dibuat (tiap swipe dicatat tepat sekali).
var jumlah_swipe_selesai: int = 0
## Nomor swipe terakhir yang diklaim (naik 1 tiap jari mengklaim slot swipe, tidak berubah saat jari dilepas atau batal). Selama
## `swipe_selesai` dipancarkan, nilainya = nomor swipe yang baru selesai, jadi pemakai bisa mengenali data yang dihitung untuk swipe itu.
var nomor_swipe: int = 0
## Jumlah tap yang selesai sejak instance dibuat.
var jumlah_tap_selesai: int = 0
## Jumlah sentuhan yang turun di zona bel sejak instance dibuat.
var jumlah_bel: int = 0

var _kidal: bool = false
var _index_stick: int = TIDAK_ADA
var _asal_stick: Vector2 = Vector2.ZERO
var _posisi_stick: Vector2 = Vector2.ZERO
var _index_swipe: int = TIDAK_ADA
var _awal_swipe: Vector2 = Vector2.ZERO
var _posisi_swipe: Vector2 = Vector2.ZERO
var _waktu_awal_swipe: float = 0.0
## Panjang swipe |v| terbesar yang pernah dicapai jari swipe yang sedang ditahan, piksel game (D-1).
var _maks_swipe_px: float = 0.0
## Jari terakhir yang turun di zona bel dan belum diangkat; `TIDAK_ADA` bila tidak ada.
var _index_bel: int = TIDAK_ADA


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
	if index == _index_stick or index == _index_swipe or index == _index_bel:
		return
	match TouchZones.zona_di(posisi, lebar_viewport, _kidal, geser_bel):
		TouchZones.Zona.BEL:
			_index_bel = index
			jumlah_bel += 1
			bel_ditekan.emit(posisi)
		TouchZones.Zona.STICK:
			if _index_stick == TIDAK_ADA:
				_index_stick = index
				_asal_stick = posisi
				_posisi_stick = posisi
		TouchZones.Zona.SWIPE:
			if _index_swipe == TIDAK_ADA:
				_index_swipe = index
				nomor_swipe += 1
				_awal_swipe = posisi
				_posisi_swipe = posisi
				_waktu_awal_swipe = waktu_detik
				_maks_swipe_px = 0.0


## Jari bergeser. Hanya jari yang sudah mengklaim yang berpengaruh. `index` negatif sama dengan sentinel
## `TIDAK_ADA` dan harus ditolak di awal, kalau tidak slot yang kosong ikut terbaca "cocok".
func geser(index: int, posisi: Vector2) -> void:
	if index < 0 or not posisi.is_finite():
		return
	if index == _index_stick:
		_posisi_stick = posisi
	elif index == _index_swipe:
		_posisi_swipe = posisi
		_catat_panjang(posisi)


## Jari diangkat. Stick: vektor kembali nol dan slot bebas. Swipe: hasilnya dicatat tepat sekali.
## `index` negatif ditolak (sentinel `TIDAK_ADA`), kalau tidak slot swipe yang kosong tercatat sebagai swipe palsu.
func lepas(index: int, posisi: Vector2, waktu_detik: float) -> void:
	if index < 0:
		return
	if index == _index_bel:
		_index_bel = TIDAK_ADA
	elif index == _index_stick:
		_bebaskan_stick()
	elif index == _index_swipe:
		var akhir: Vector2 = posisi if posisi.is_finite() else _posisi_swipe
		var durasi: float = maxf(0.0, waktu_detik - _waktu_awal_swipe) if is_finite(waktu_detik) else 0.0
		var awal: Vector2 = _awal_swipe
		_catat_panjang(akhir)
		var tap: bool = not ThrowSolver.cukup_panjang(_maks_swipe_px, float(lebar_viewport))
		_bebaskan_swipe()
		jumlah_swipe_selesai += 1
		swipe_selesai.emit(awal, akhir, durasi)
		if tap:
			jumlah_tap_selesai += 1
			tap_selesai.emit(awal, durasi)


## Satu jari dibatalkan sistem (mis. gestur sistem mengambil alih): dilepas tanpa mencatat swipe.
func batal(index: int) -> void:
	if index < 0:
		return
	if index == _index_bel:
		_index_bel = TIDAK_ADA
	elif index == _index_stick:
		_bebaskan_stick()
	elif index == _index_swipe:
		_bebaskan_swipe()


## Melepas semua jari tanpa mencatat swipe. Dipanggil saat app di-background, kehilangan fokus, atau kidal berganti.
func batal_semua() -> void:
	_bebaskan_stick()
	_bebaskan_swipe()
	_index_bel = TIDAK_ADA


## True selama jari yang turun di zona bel masih menempel (tombol bel tampil ditekan).
func bel_ditahan() -> bool:
	return _index_bel != TIDAK_ADA


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


## Panjang swipe |v| terbesar yang sudah dicapai jari swipe yang sedang ditahan, piksel game (0 bila tidak ada swipe).
func panjang_swipe_maks() -> float:
	return _maks_swipe_px


## Mencatat |v| dari titik awal ke `posisi` bila lebih panjang dari yang sudah tercatat (D-1).
func _catat_panjang(posisi: Vector2) -> void:
	var panjang: float = ThrowSolver.panjang_swipe(_awal_swipe, posisi)
	if is_finite(panjang) and panjang > _maks_swipe_px:
		_maks_swipe_px = panjang


func _bebaskan_stick() -> void:
	_index_stick = TIDAK_ADA
	_asal_stick = Vector2.ZERO
	_posisi_stick = Vector2.ZERO


func _bebaskan_swipe() -> void:
	_index_swipe = TIDAK_ADA
	_awal_swipe = Vector2.ZERO
	_posisi_swipe = Vector2.ZERO
	_waktu_awal_swipe = 0.0
	_maks_swipe_px = 0.0
