class_name GarisSobek
extends Control
## Garis sobek struk hasil (run ui2-semua-layar bagian A; kanvas `.sobek` dan `.takik`; usulan): garis putus-putus `UI_PANEL_RAISED` 1 px di tengah dan dua takik tiket `ui_struk_takik.png` yang menempel di tepi luar
## struk (sisi awal apa adanya, sisi akhir dicerminkan). Kontrol ini berada di dalam isi struk, jadi takik digambar melewati jarak isi ke tepi (`atur_pad`); garis berjarak `HASIL_SOBEK_TEPI_PX` dari tepi dalam.
## Hanya menggambar; tidak menerima sentuhan. Tekstur dimuat sekali (const, bukan `_draw`).

const TEKSTUR_TAKIK: Texture2D = preload("res://assets/sprites/ui/ui_struk_takik.png")

## Jarak isi struk ke tepi luar di sisi awal dan akhir (pad isi), piksel game; takik mulai di tepi luar.
var _pad_awal: int = Config.HASIL_STRUK_PAD_X_PX
var _pad_akhir: int = Config.HASIL_STRUK_PAD_X_PX


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, Config.HASIL_SOBEK_TINGGI_PX)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


## Mengatur jarak isi struk ke tepi luar (sisi awal dan akhir) lalu menggambar ulang.
func atur_pad(awal: int, akhir: int) -> void:
	_pad_awal = awal
	_pad_akhir = akhir
	queue_redraw()


## Persegi takik awal dan akhir relatif kontrol ini (untuk tes tata letak): menempel di tepi luar struk, di tengah tinggi kontrol.
func rect_takik() -> Array[Rect2]:
	var y: float = floorf((size.y - float(Config.HASIL_TAKIK_TINGGI_PX)) / 2)
	var lebar: float = float(Config.HASIL_TAKIK_LEBAR_PX)
	return [Rect2(-float(_pad_awal), y, lebar, float(Config.HASIL_TAKIK_TINGGI_PX)), Rect2(size.x + float(_pad_akhir) - lebar, y, lebar, float(Config.HASIL_TAKIK_TINGGI_PX))]


## Segmen garis putus-putus (awal x, panjang) dari `awal` sampai `akhir` (piksel game): goresan `gores` lalu celah `gores`; goresan terakhir dipotong di `akhir`.
static func segmen(awal: int, akhir: int, gores: int) -> Array[Vector2i]:
	var hasil: Array[Vector2i] = []
	if gores <= 0:
		return hasil
	var x: int = awal
	while x < akhir:
		hasil.append(Vector2i(x, mini(gores, akhir - x)))
		x += 2 * gores
	return hasil


func _draw() -> void:
	var y: int = floori(size.y / 2)
	var tepi_dalam: int = Config.UI_PANEL_SLICE_PX
	var awal: int = -_pad_awal + tepi_dalam + Config.HASIL_SOBEK_TEPI_PX
	var akhir: int = roundi(size.x) + _pad_akhir - tepi_dalam - Config.HASIL_SOBEK_TEPI_PX
	for s: Vector2i in segmen(awal, akhir, Config.HASIL_SOBEK_GORES_PX):
		draw_rect(Rect2(float(s.x), float(y), float(s.y), float(Config.UI_GARIS_PX)), Palette.UI_PANEL_RAISED)
	var takik: Array[Rect2] = rect_takik()
	draw_texture_rect(TEKSTUR_TAKIK, takik[0], false)
	# Sisi kanan dicerminkan lewat skala -1 dari tepi kanan takik (lebar negatif `draw_texture_rect` menggeser persegi ke kanan).
	draw_set_transform(Vector2(takik[1].end.x, 0), 0, Vector2(-1, 1))
	draw_texture_rect(TEKSTUR_TAKIK, Rect2(0.0, takik[1].position.y, takik[1].size.x, takik[1].size.y), false)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
