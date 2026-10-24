class_name KotakIklan
extends MarginContainer
## Kotak hiasan "Iklan baris" di sisa ruang bawah kolom berita halaman koran (run ui2-semua-layar bagian B; kanvas `aside`: garis putus 1 px `KORAN_GARIS`, isi 4 6, usulan): label `KORAN_IKLAN_BARIS`
## lalu batang hiasan sebanyak yang muat (`GarisHiasan`). Garis putus digambar dari segmen `GarisSobek.segmen`. Murni hiasan; tidak menerima sentuhan. Letak dan ukuran diatur `HalamanKoran`
## dari `TampilKoran.iklan`.


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tepi: int = Config.UI_GARIS_PX
	add_theme_constant_override(&"margin_left", tepi + Config.KORAN_IKLAN_PAD_X_PX)
	add_theme_constant_override(&"margin_right", tepi + Config.KORAN_IKLAN_PAD_X_PX)
	add_theme_constant_override(&"margin_top", tepi + Config.KORAN_IKLAN_PAD_Y_PX)
	add_theme_constant_override(&"margin_bottom", tepi + Config.KORAN_IKLAN_PAD_Y_PX)


## Persegi goresan garis putus keempat sisi (relatif kotak) untuk ukuran `ukuran`: atas, bawah (mendatar), kiri, kanan (tegak); tebal `UI_GARIS_PX`.
static func goresan(ukuran: Vector2i) -> Array[Rect2i]:
	var hasil: Array[Rect2i] = []
	var tebal: int = Config.UI_GARIS_PX
	for s: Vector2i in GarisSobek.segmen(0, ukuran.x, Config.KORAN_IKLAN_GORES_PX):
		hasil.append(Rect2i(s.x, 0, s.y, tebal))
		hasil.append(Rect2i(s.x, ukuran.y - tebal, s.y, tebal))
	for s: Vector2i in GarisSobek.segmen(0, ukuran.y, Config.KORAN_IKLAN_GORES_PX):
		hasil.append(Rect2i(0, s.x, tebal, s.y))
		hasil.append(Rect2i(ukuran.x - tebal, s.x, tebal, s.y))
	return hasil


func _draw() -> void:
	for r: Rect2i in goresan(Vector2i(roundi(size.x), roundi(size.y))):
		draw_rect(Rect2(r), Palette.KORAN_GARIS)
