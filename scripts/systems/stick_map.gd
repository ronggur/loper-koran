class_name StickMap
extends RefCounted
## Pemetaan geseran jari ke vektor stick, logika murni (BALANCING 2, DESIGN_SPEC 3.7, GDD 5.2).
##
## Masukan: geseran jari dari titik awal stick (stick melayang), piksel game, sumbu layar
## (x positif = kanan, y positif = BAWAH). Keluaran: vektor kontrol dengan panjang 0 sampai 1:
## - x positif = menuju sisi `dekat`, negatif = sisi `seberang` (D-3);
## - y positif = maju/atas, negatif = melambat/bawah.
## Sumbu Y layar dibalik di SATU fungsi saja (`_layar_ke_kontrol`).
## Jangkauan penuh = `Config.STICK_RADIUS_PX`. Zona mati radial `Config.ZONA_MATI_STICK`:
## di dalamnya (batas inklusif, dengan toleransi desimal) vektor nol; di luarnya kekuatan dipetakan
## ulang linear dari 0 di tepi zona mati sampai 1 di jangkauan penuh, tanpa lompatan di batas;
## di atas jangkauan penuh kekuatan dijepit 1, arah dipertahankan.


## Vektor kontrol dari geseran jari (piksel game, sumbu layar). Panjang hasil 0 sampai 1.
static func petakan(geser_layar: Vector2) -> Vector2:
	if not geser_layar.is_finite():
		return Vector2.ZERO
	var rasio: float = geser_layar.length() / Config.STICK_RADIUS_PX
	var mati: float = Config.ZONA_MATI_STICK
	if rasio <= mati or is_equal_approx(rasio, mati):
		return Vector2.ZERO
	var kekuatan: float = (minf(rasio, 1.0) - mati) / (1.0 - mati)
	return _layar_ke_kontrol(geser_layar.normalized() * kekuatan)


## Geseran jari yang dijepit ke jangkauan penuh stick (untuk menggambar knob), sumbu layar.
static func jepit_geser(geser_layar: Vector2) -> Vector2:
	if not geser_layar.is_finite():
		return Vector2.ZERO
	return geser_layar.limit_length(Config.STICK_RADIUS_PX)


## Vektor kontrol dari empat tombol (keyboard hanya untuk tes di editor, rule `ui-scenes`).
## Diagonal dinormalkan supaya panjangnya tidak melebihi 1. Tombol berlawanan saling membatalkan.
static func dari_tombol(ke_seberang: bool, ke_dekat: bool, atas: bool, bawah: bool) -> Vector2:
	var vektor: Vector2 = Vector2(_sumbu(ke_seberang, ke_dekat), _sumbu(bawah, atas))
	return vektor.limit_length(1.0)


## Satu-satunya pembalikan sumbu Y: y layar (bawah positif) menjadi y kontrol (atas positif).
static func _layar_ke_kontrol(vektor_layar: Vector2) -> Vector2:
	return Vector2(vektor_layar.x, -vektor_layar.y)


static func _sumbu(negatif: bool, positif: bool) -> float:
	return (1.0 if positif else 0.0) - (1.0 if negatif else 0.0)
