class_name TitikLangkah
extends Control
## Deretan titik langkah petunjuk tutorial (kanvas Tutorial.dc.html, run ui2-semua-layar bagian C1; usulan): terisi sampai langkah sekarang, sisanya berongga (`TampilTutorial`). Hanya menggambar;
## tidak menerima sentuhan.

var _nomor: int = 0
var _total: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_atur_ukuran()


## Mengatur langkah sekarang (`nomor`, mulai 1) dan jumlah langkah (`total`).
func atur(nomor: int, total: int) -> void:
	_nomor = nomor
	_total = total
	_atur_ukuran()
	queue_redraw()


## Perintah gambar yang dijalankan `_draw` (dites headless).
func perintah_tampil() -> Array:
	return TampilTutorial.perintah_titik(_nomor, _total)


func _draw() -> void:
	for p: Array in perintah_tampil():
		draw_rect(p[0], p[1])


func _atur_ukuran() -> void:
	custom_minimum_size = Vector2(TampilTutorial.lebar_titik(_total), Config.TUTORIAL_TITIK_PX)
