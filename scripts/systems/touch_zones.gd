class_name TouchZones
extends RefCounted
## Zona kontrol sentuh dari lebar viewport dan opsi kidal (DESIGN_SPEC 3.7, GDD 5.2, rule `ui-scenes`).
##
## Bawaan (tangan kanan): zona stick di sisi kiri layar, zona swipe di sisi kanan. Opsi kidal
## mencerminkan keduanya persis. Angka zona ada di `Config.ZONA_*` (diukur dari tepi layar sisi
## stick). Semua tepi zona INKLUSIF: titik tepat di tepi masuk zona, 1 px di luarnya tidak.
## Zona hanya menentukan jari mana yang diklaim saat jari turun (lihat `TouchRouter`).

enum Zona { TIDAK_ADA, STICK, SWIPE }


## Persegi zona stick. `position` = pojok kiri atas, `end` = pojok kanan bawah (kedua tepi inklusif).
static func rect_stick(lebar_viewport: int, kidal: bool) -> Rect2:
	var x_dekat: float = float(Config.ZONA_STICK_X_MIN_PX)
	var x_jauh: float = float(Config.ZONA_STICK_X_MAKS_PX)
	var y_atas: float = float(Config.ZONA_STICK_Y_MIN_PX)
	var y_bawah: float = float(Config.ZONA_STICK_Y_MAKS_PX)
	if kidal:
		return _dari_tepi(float(lebar_viewport) - x_jauh, y_atas, float(lebar_viewport) - x_dekat, y_bawah)
	return _dari_tepi(x_dekat, y_atas, x_jauh, y_bawah)


## Persegi zona swipe. `position` = pojok kiri atas, `end` = pojok kanan bawah (kedua tepi inklusif).
static func rect_swipe(lebar_viewport: int, kidal: bool) -> Rect2:
	var x_dalam: float = float(Config.ZONA_SWIPE_X_MIN_PX)
	var x_luar: float = float(lebar_viewport - Config.ZONA_SWIPE_TEPI_PX)
	var y_atas: float = float(Config.ZONA_SWIPE_Y_MIN_PX)
	var y_bawah: float = float(Config.ZONA_SWIPE_Y_MAKS_PX)
	if kidal:
		return _dari_tepi(float(Config.ZONA_SWIPE_TEPI_PX), y_atas, float(lebar_viewport) - x_dalam, y_bawah)
	return _dari_tepi(x_dalam, y_atas, x_luar, y_bawah)


## Zona tempat `titik` (koordinat viewport game) berada. Kedua zona tidak pernah bertumpuk.
static func zona_di(titik: Vector2, lebar_viewport: int, kidal: bool) -> Zona:
	if di_dalam(titik, rect_stick(lebar_viewport, kidal)):
		return Zona.STICK
	if di_dalam(titik, rect_swipe(lebar_viewport, kidal)):
		return Zona.SWIPE
	return Zona.TIDAK_ADA


## True bila `titik` ada di dalam `zona`, tepi kiri, kanan, atas, dan bawah inklusif.
static func di_dalam(titik: Vector2, zona: Rect2) -> bool:
	var ujung: Vector2 = zona.end
	return titik.x >= zona.position.x and titik.x <= ujung.x and titik.y >= zona.position.y and titik.y <= ujung.y


static func _dari_tepi(x_min: float, y_min: float, x_maks: float, y_maks: float) -> Rect2:
	return Rect2(x_min, y_min, x_maks - x_min, y_maks - y_min)
