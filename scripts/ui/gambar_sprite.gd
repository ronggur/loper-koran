class_name GambarSprite
extends RefCounted
## Menggambar daftar `DefSprite.Item` ke `CanvasItem` sebagai potongan frame sheet (run fase5a bagian B), seperti `GambarPiksel` untuk pola: node menyusun item lewat fungsi murni yang
## dites headless, `gambar` hanya menjalankannya. Tekstur dimuat lewat `load` (ResourceLoader menyimpan cache, jadi tidak ada simpanan statis di sini yang bocor saat keluar). Filter tekstur
## Nearest datang dari node pemilik (`texture_filter` di scene) dan bawaan proyek (`default_texture_filter=0`). Pojok item sudah bulat (piksel game).


## Tekstur sprite bernama `nama` (null bila tidak dikenal atau tidak bisa dimuat).
static func tekstur(nama: String) -> Texture2D:
	if DefSprite.jumlah_frame(nama) < 1:
		return null
	return load(DefSprite.jalur_png(nama)) as Texture2D


## Menggambar semua item (urut) ke `kanvas`. Item dengan nama tidak dikenal atau alpha 0 dilewati.
static func gambar(kanvas: CanvasItem, daftar: Array) -> void:
	for lain: Variant in daftar:
		var item: DefSprite.Item = lain as DefSprite.Item
		if item == null or item.alfa <= 0.0:
			continue
		var tekstur_item: Texture2D = tekstur(item.nama)
		if tekstur_item == null:
			continue
		var potongan: Rect2i = DefSprite.region(item.nama, item.frame)
		kanvas.draw_texture_rect_region(tekstur_item, Rect2(item.pojok, Vector2(potongan.size)), Rect2(potongan), Color(1.0, 1.0, 1.0, item.alfa))
