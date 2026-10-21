class_name GambarSprite
extends RefCounted
## Menggambar daftar `DefSprite.Item` ke `CanvasItem` sebagai potongan frame sheet (run fase5a bagian B), seperti `GambarPiksel` untuk pola: node menyusun item lewat fungsi murni yang
## dites headless, `gambar` hanya menjalankannya.
##
## PENTING (ditemukan lewat probe jendela, tes headless tidak bisa melihatnya): tekstur yang BARU dimuat di dalam `_draw` tergambar sebagai persegi putih polos pada frame itu (Godot 4.7.2,
## Compatibility). Karena itu tekstur dimuat sekali di luar `_draw` (`muat`, dipanggil `_init` atau `_ready` node pemilik) dan disimpan node di larik/kamus miliknya, lalu diberikan ke `gambar`.
## Node harus memegang rujukannya: cache ResourceLoader hanya menyimpan rujukan lemah, jadi tekstur yang tidak dipegang bisa dibuang lalu dimuat ulang di tengah `_draw` (putih lagi).
## Filter tekstur Nearest datang dari node pemilik (`texture_filter` di scene) dan bawaan proyek (`default_texture_filter=0`). Pojok item sudah bulat (piksel game).


## Tekstur sprite bernama `nama` (null bila tidak dikenal atau tidak bisa dimuat). Panggil di luar `_draw`.
static func tekstur(nama: String) -> Texture2D:
	if DefSprite.jumlah_frame(nama) < 1:
		return null
	return load(DefSprite.jalur_png(nama)) as Texture2D


## Memuat semua tekstur `daftar_nama` sekali (kamus nama -> Texture2D) untuk dipegang node pemilik. Nama tidak dikenal dilewati.
static func muat(daftar_nama: Array[String]) -> Dictionary:
	var hasil: Dictionary = {}
	for nama: String in daftar_nama:
		var t: Texture2D = tekstur(nama)
		if t != null:
			hasil[nama] = t
	return hasil


## Satu perintah gambar potongan sprite: tekstur, kotak tujuan (ruang `CanvasItem`), kotak sumber di sheet, dan warna modulasi (putih dengan alpha item).
class Perintah extends RefCounted:
	var tekstur: Texture2D = null
	var tujuan: Rect2 = Rect2()
	var sumber: Rect2 = Rect2()
	var warna: Color = Color(1.0, 1.0, 1.0, 1.0)


## Perintah gambar murni untuk `daftar` (urut) dengan tekstur dari `muatan` (hasil `muat`): item dengan nama yang tidak ada di `muatan`, alpha 0, atau bukan `DefSprite.Item` dilewati. Warna = putih dengan alpha item,
## jadi kurangi-efek debu dan kekuatan garis sampai ke gambar. Tanpa `CanvasItem`, jadi bisa dites headless (alpha yang benar-benar dipakai `gambar` adalah `Perintah.warna`).
static func perintah(daftar: Array, muatan: Dictionary) -> Array[Perintah]:
	var hasil: Array[Perintah] = []
	for lain: Variant in daftar:
		var item: DefSprite.Item = lain as DefSprite.Item
		if item == null or item.alfa <= 0.0 or not muatan.has(item.nama):
			continue
		var potongan: Rect2i = DefSprite.region(item.nama, item.frame)
		var p: Perintah = Perintah.new()
		p.tekstur = muatan[item.nama] as Texture2D
		p.tujuan = Rect2(item.pojok, Vector2(potongan.size))
		p.sumber = Rect2(potongan)
		p.warna = Color(1.0, 1.0, 1.0, item.alfa)
		hasil.append(p)
	return hasil


## Menggambar semua item (urut) ke `kanvas` dengan tekstur dari `muatan` (hasil `muat`) lewat `perintah`. Item dengan nama yang tidak ada di `muatan` atau alpha 0 dilewati.
static func gambar(kanvas: CanvasItem, daftar: Array, muatan: Dictionary) -> void:
	for p: Perintah in perintah(daftar, muatan):
		kanvas.draw_texture_rect_region(p.tekstur, p.tujuan, p.sumber, p.warna)
