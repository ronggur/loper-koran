class_name GarisTitik
extends Control
## Garis titik-titik penuntun antara label dan nilai satu baris struk hasil (run ui2-semua-layar bagian A; kanvas `border-bottom: 1px dotted` warna `UI_PANEL_RAISED`; usulan): titik 1 px `UI_PANEL_RAISED` tiap
## `HASIL_TITIK_JARAK_PX` di `HASIL_TITIK_DASAR_PX` di atas dasar kontrol. Mengisi sisa lebar baris. Hanya menggambar; tidak menerima sentuhan.


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(0, Config.HASIL_BARIS_TINGGI_PX)


## Letak x titik-titik (piksel game) untuk lebar `lebar`: mulai 0, tiap `jarak`; kosong bila lebar atau jarak tidak positif.
static func letak_titik(lebar: int, jarak: int) -> Array[int]:
	var hasil: Array[int] = []
	if lebar <= 0 or jarak <= 0:
		return hasil
	var x: int = 0
	while x < lebar:
		hasil.append(x)
		x += jarak
	return hasil


func _draw() -> void:
	var y: float = floorf(size.y) - float(Config.HASIL_TITIK_DASAR_PX)
	for x: int in letak_titik(roundi(size.x), Config.HASIL_TITIK_JARAK_PX):
		draw_rect(Rect2(float(x), y, float(Config.UI_GARIS_PX), float(Config.UI_GARIS_PX)), Palette.UI_PANEL_RAISED)
