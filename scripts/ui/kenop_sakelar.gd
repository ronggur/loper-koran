class_name KenopSakelar
extends Control
## Kenop sakelar 22x12 di tombol sakelar layar jeda (kanvas `.sak`, run ui2-semua-layar bagian C1; usulan): digambar dari pola huruf `TampilJeda` (mati = kenop berongga di kiri, nyala =
## kenop terisi di kanan di atas ACCENT), jadi keadaan terbaca dari bentuk dan sisi, bukan hanya warna. Tidak menerima sentuhan (ketukan jatuh ke tombol di bawahnya).

## True bila sakelar nyala.
var nyala: bool = false:
	set(baru):
		if baru != nyala:
			nyala = baru
			queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(Config.JEDA_KENOP_LEBAR_PX, Config.JEDA_KENOP_TINGGI_PX)


## Perintah gambar yang dijalankan `_draw` (dites headless).
func perintah_tampil() -> Array:
	return TampilJeda.perintah_kenop(nyala)


func _draw() -> void:
	for p: Array in perintah_tampil():
		draw_rect(p[0], p[1])
