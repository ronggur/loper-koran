class_name ZonaAman
extends RefCounted
## Zona aman HUD (cutout kamera, bilah gestur), logika murni (rule `ui-scenes`; AC-9 run fase3c-hud-hasil, usulan).
##
## - `inset_game`: inset aman dari `DisplayServer.get_display_safe_area()` (piksel LAYAR) diubah ke piksel GAME per tepi, memakai skala dan
##   tepi kosong (letterbox) dari stretch `canvas_items` + skala bulat: skala = min(layar / viewport) per sumbu, tepi kosong = sisa layar
##   dibagi dua. Inset tiap tepi dibulatkan ke atas (cutout tidak boleh menutupi satu piksel game pun) dan tidak pernah negatif.
## - `margin(spec, inset)` = max(margin DESIGN_SPEC, inset): satu-satunya aturan margin tepi.
## - `geser(spec, inset)` = margin - spec: berapa piksel elemen HUD di satu tepi digeser ke dalam. Semua elemen yang menempel tepi yang sama
##   digeser SAMA BESAR dengan acuan elemen terluar tepi itu (kiri dan kanan: strip radar x 4; atas: area sentuh tombol jeda y 4; bawah:
##   panel bawah dan tombol bel 8), jadi jarak antar elemen tetap dan tiap elemen tetap paling sedikit sejauh inset dari tepi.
## Tanpa node; pemanggil (HUD) membaca `DisplayServer` sendiri dan memberikan angkanya.


## Inset aman per tepi, piksel game (tidak negatif). `awal_x` = tepi layar x 0, `akhir_x` = tepi layar x lebar.
class Inset extends RefCounted:
	var awal_x: int = 0
	var atas: int = 0
	var akhir_x: int = 0
	var bawah: int = 0

	## True bila semua tepi 0.
	func nol() -> bool:
		return awal_x == 0 and atas == 0 and akhir_x == 0 and bawah == 0


## Inset aman dalam piksel game dari persegi aman `aman` (piksel layar), ukuran layar `layar` (piksel), dan ukuran viewport game `viewport`.
## Masukan kosong atau tidak sah = inset nol.
static func inset_game(aman: Rect2i, layar: Vector2i, viewport: Vector2) -> Inset:
	var hasil: Inset = Inset.new()
	if aman.size.x <= 0 or aman.size.y <= 0 or layar.x <= 0 or layar.y <= 0 or viewport.x <= 0.0 or viewport.y <= 0.0:
		return hasil
	var skala: float = minf(float(layar.x) / viewport.x, float(layar.y) / viewport.y)
	if skala <= 0.0:
		return hasil
	var kosong: Vector2 = (Vector2(layar) - viewport * skala) / 2
	hasil.awal_x = _ke_game(float(aman.position.x) - kosong.x, skala)
	hasil.atas = _ke_game(float(aman.position.y) - kosong.y, skala)
	hasil.akhir_x = _ke_game(float(layar.x - aman.end.x) - kosong.x, skala)
	hasil.bawah = _ke_game(float(layar.y - aman.end.y) - kosong.y, skala)
	return hasil


## Margin tepi = max(`spec_px`, `inset_px`).
static func margin(spec_px: int, inset_px: int) -> int:
	return maxi(spec_px, inset_px)


## Geseran ke dalam elemen yang margin DESIGN_SPEC-nya `spec_px` bila inset tepi itu `inset_px` (0 bila inset tidak melewati margin).
static func geser(spec_px: int, inset_px: int) -> int:
	return margin(spec_px, inset_px) - spec_px


## Piksel layar `layar_px` (sudah dikurangi tepi kosong) ke piksel game, dibulatkan ke atas, tidak negatif.
static func _ke_game(layar_px: float, skala: float) -> int:
	if not is_finite(layar_px) or layar_px <= 0.0:
		return 0
	return ceili(layar_px / skala - Config.ZONA_AMAN_TOLERANSI_PX)
