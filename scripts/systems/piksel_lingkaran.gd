class_name PikselLingkaran
extends RefCounted
## Cakram dan cincin berbasis piksel untuk tampilan stick, logika murni (DESIGN_SPEC 3.7, rule `art-assets`).
##
## Stick digambar sebagai tekstur piksel dengan tepi bergerigi tegas (tanpa anti-alias) supaya setiap
## piksel game menjadi blok skala x skala yang tajam. Piksel (dx, dy) dihitung dari piksel pusat.


## True bila piksel pada selisih (dx, dy) dari pusat ada di dalam cakram berjari-jari `radius`.
static func di_dalam(dx: int, dy: int, radius: int) -> bool:
	return dx * dx + dy * dy <= radius * radius + radius


## True bila piksel ada di cincin: di dalam cakram `radius` tetapi di luar cakram `radius - tebal`.
static func di_cincin(dx: int, dy: int, radius: int, tebal: int) -> bool:
	return di_dalam(dx, dy, radius) and not di_dalam(dx, dy, radius - tebal)


## Sisi persegi (piksel) yang memuat cakram berjari-jari `radius`, piksel pusat di tengah.
static func sisi(radius: int) -> int:
	return radius * 2 + 1
