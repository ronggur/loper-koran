class_name BilahMilestone
extends Control
## Bilah progres milestone di layar hasil (run fase6a2-reputasi-pelanggan bagian C, AC-13; usulan): garis luar `OUTLINE` 1 px, dasar `UI_PANEL`, isi `ACCENT` sebesar pecahan (paling sedikit 1 px
## bila pecahan > 0). Bilah bukan satu-satunya pembawa informasi: angka "n/target" tampil di sampingnya (bukan warna saja). Tinggi tetap `HASIL_BILAH_TINGGI_PX`, lebar melar.

var _pecahan: float = 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(Config.HASIL_BILAH_LEBAR_MIN_PX, Config.HASIL_BILAH_TINGGI_PX)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Mengatur pecahan isi (0..1) dan menggambar ulang.
func atur(pecahan: float) -> void:
	_pecahan = clampf(pecahan, 0.0, 1.0)
	queue_redraw()


## Pecahan yang sedang digambar (untuk tes).
func pecahan() -> float:
	return _pecahan


## Lebar isi (px) untuk lebar bilah `lebar` (garis luar 1 px di tiap sisi): 0 bila pecahan 0, paling sedikit 1 bila > 0, penuh bila 1.
static func lebar_isi(lebar: int, pecahan_isi: float) -> int:
	var dalam: int = maxi(lebar - 2 * Config.HASIL_BILAH_TEPI_PX, 0)
	if pecahan_isi <= 0.0:
		return 0
	return clampi(maxi(floori(float(dalam) * pecahan_isi), 1), 0, dalam)


func _draw() -> void:
	var lebar: int = roundi(size.x)
	var tinggi: int = roundi(size.y)
	draw_rect(Rect2(0, 0, lebar, tinggi), Palette.OUTLINE)
	var tepi: int = Config.HASIL_BILAH_TEPI_PX
	draw_rect(Rect2(tepi, tepi, maxi(lebar - 2 * tepi, 0), maxi(tinggi - 2 * tepi, 0)), Palette.UI_PANEL)
	var isi: int = lebar_isi(lebar, _pecahan)
	if isi > 0:
		draw_rect(Rect2(tepi, tepi, isi, maxi(tinggi - 2 * tepi, 0)), Palette.ACCENT)
