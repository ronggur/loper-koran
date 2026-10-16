class_name TombolBel
extends Control
## Gambar tombol bel di HUD (DESIGN_SPEC 3.8; AC-15, AC-16 run fase3b-rintangan-skor bagian B, usulan): 40x40 dari
## `assets/sprites/ui/ui_bel_tombol.png` (`tools/ui_art/bel.py --salin`): diam, ditekan, dan cincin jeda berkurang.
##
## Hanya gambar: tidak menerima sentuhan (`MOUSE_FILTER_IGNORE`). Sentuhan bel dibaca `TouchRouter` dari zona tap bel (lingkaran radius
## `BEL_ZONA_RADIUS_PX` di pusat tombol, `TouchZones.pusat_bel`) supaya hanya sentuhan yang DIMULAI di sana yang membunyikan bel dan dua jari
## dilacak lewat `index`. Letak (pojok kanan bawah, kidal kiri bawah) diatur `HudDev` lewat anchor. Frame dipilih `Bel.frame_tombol`.

const TEKSTUR: Texture2D = preload("res://assets/sprites/ui/ui_bel_tombol.png")

var _frame: int = Bel.FRAME_DIAM


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(Config.BEL_TOMBOL_UKURAN_PX, Config.BEL_TOMBOL_UKURAN_PX)


## Mengganti frame (`Bel.frame_tombol`). Gambar ulang hanya bila berubah.
func atur_frame(frame: int) -> void:
	if frame == _frame:
		return
	_frame = frame
	queue_redraw()


## Frame yang sedang digambar (untuk tes).
func frame() -> int:
	return _frame


func _draw() -> void:
	var sisi: float = float(Config.BEL_TOMBOL_UKURAN_PX)
	draw_texture_rect_region(TEKSTUR, Rect2(Vector2.ZERO, Vector2(sisi, sisi)), Rect2(Vector2(sisi * _frame, 0), Vector2(sisi, sisi)))
