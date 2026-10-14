class_name GayaHud
extends RefCounted
## Gaya panel dan tombol HUD sementara (DESIGN_SPEC 1.3): kotak bergaris luar 1 px, sudut tegas, isi berjarak `HUD_PANEL_PAD_*`.
##
## Dipakai bersama oleh `HudDev` dan `LayarJeda` supaya bentuk tombol sama. Warna selalu dari `Palette`. Panel 9-slice final
## (DESIGN_SPEC 1.3) menggantikan ini nanti.


## Kotak `StyleBoxFlat` berisi `isi`, garis luar 1 px `garis`, tanpa anti-alias, padding dari Config.
static func kotak(isi: Color, garis: Color) -> StyleBoxFlat:
	var hasil: StyleBoxFlat = StyleBoxFlat.new()
	hasil.bg_color = isi
	hasil.border_color = garis
	hasil.set_border_width_all(1)
	hasil.anti_aliasing = false
	hasil.content_margin_left = float(Config.HUD_PANEL_PAD_X_PX)
	hasil.content_margin_right = float(Config.HUD_PANEL_PAD_X_PX)
	hasil.content_margin_top = float(Config.HUD_PANEL_PAD_Y_PX)
	hasil.content_margin_bottom = float(Config.HUD_PANEL_PAD_Y_PX)
	return hasil


## Gaya tombol teks HUD: normal dan hover `HUD_PANEL` bergaris `OUTLINE`, ditekan `UI_PANEL_RAISED` bergaris `ACCENT`; teks `TEXT`,
## ditekan `ACCENT`.
static func terapkan_tombol(tombol: Button) -> void:
	tombol.add_theme_stylebox_override(&"normal", kotak(Palette.HUD_PANEL, Palette.OUTLINE))
	tombol.add_theme_stylebox_override(&"hover", kotak(Palette.HUD_PANEL, Palette.OUTLINE))
	tombol.add_theme_stylebox_override(&"pressed", kotak(Palette.UI_PANEL_RAISED, Palette.ACCENT))
	tombol.add_theme_stylebox_override(&"hover_pressed", kotak(Palette.UI_PANEL_RAISED, Palette.ACCENT))
	tombol.add_theme_color_override(&"font_color", Palette.TEXT)
	tombol.add_theme_color_override(&"font_hover_color", Palette.TEXT)
	tombol.add_theme_color_override(&"font_pressed_color", Palette.ACCENT)
	tombol.add_theme_color_override(&"font_hover_pressed_color", Palette.ACCENT)
