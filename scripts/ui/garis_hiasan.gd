class_name GarisHiasan
extends Control
## Batang hiasan pengganti teks di halaman koran (run ui2-semua-layar bagian B; kanvas: batang 2 px `KORAN_KERTAS_2` di bawah berita ringan, usulan): dua kolom batang, `baris` baris, atau sebanyak yang muat bila
## `baris` = 0 (kotak "Iklan baris"). Bentuk dari `TampilKoran.batang_hiasan`. Murni hiasan: tanpa teks (tidak perlu terjemahan), tidak menerima sentuhan.

## Jumlah baris tetap; 0 = sebanyak yang muat di tinggi kontrol. Tinggi minimum selalu 0 (hiasan tidak pernah memaksa kolom meluap).
var baris: int = 0:
	set(nilai):
		baris = nilai
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL


## Persegi batang yang digambar (relatif kontrol) untuk ukuran sekarang.
func batang() -> Array[Rect2i]:
	var jumlah_baris: int = baris if baris > 0 else TampilKoran.baris_hiasan_muat(roundi(size.y))
	return TampilKoran.batang_hiasan(roundi(size.x), jumlah_baris)


func _draw() -> void:
	for r: Rect2i in batang():
		draw_rect(Rect2(r), Palette.KORAN_KERTAS_2)
