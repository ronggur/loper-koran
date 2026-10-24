class_name GarisGanda
extends Control
## Garis ganda di bawah kepala halaman koran (run ui2-semua-layar bagian B; kanvas `.k-ganda`, usulan): garis atas 2 px, celah 1 px, garis bawah 1 px, warna `KORAN_TINTA`, selebar kontrol.
## Bentuk dari `TampilKoran.garis_ganda`. Tinggi minimum = garis + `KORAN_GANDA_JARAK_PX` ruang kosong di bawahnya (jarak garis ke isi, kanvas: 6). Hanya menggambar; tidak menerima sentuhan.


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, TampilKoran.tinggi_garis_ganda() + Config.KORAN_GANDA_JARAK_PX)


func _draw() -> void:
	for r: Rect2i in TampilKoran.garis_ganda(roundi(size.x)):
		draw_rect(Rect2(r), Palette.KORAN_TINTA)
