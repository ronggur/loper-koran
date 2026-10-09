class_name BarKecepatan
extends Control
## Bar kecepatan HUD (DESIGN_SPEC 1.3 dan 3.5): garis luar 1 px `OUTLINE`, latar `UI_PANEL_RAISED`, isi `TEXT`.
##
## Tingginya `Config.HUD_BAR_TINGGI_PX`; lebar mengikuti container. Hanya menggambar: nilainya (0 sampai 1)
## diisi pemanggil. Ukuran selalu bilangan bulat (isi dibulatkan ke bawah) supaya piksel tajam.

## Isi bar, 0 sampai 1 (dijepit).
var nilai: float = 0.0:
	set(baru):
		nilai = clampf(baru, 0.0, 1.0) if not is_nan(baru) else 0.0
		queue_redraw()


func _ready() -> void:
	custom_minimum_size.y = float(Config.HUD_BAR_TINGGI_PX)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Palette.OUTLINE)
	var dalam: Rect2 = Rect2(Vector2.ONE, size - Vector2.ONE * 2)
	draw_rect(dalam, Palette.UI_PANEL_RAISED)
	var lebar_isi: float = floorf(dalam.size.x * nilai)
	if lebar_isi > 0.0:
		draw_rect(Rect2(dalam.position, Vector2(lebar_isi, dalam.size.y)), Palette.TEXT)
