class_name GambarPiksel
extends RefCounted
## Menggambar pola dan rentang `PolaPiksel` ke `CanvasItem` sebagai persegi piksel game bilangan bulat (tajam di skala bulat), warna dari
## `Palette` (run fase2a-lemparan bagian 1b). Dipakai `GarisBidik`, `KoranGambar`, `ZonaGambar`, dan `DeretKoran`.
##
## Node tidak menggambar langsung dari keputusannya sendiri: tiap node menyusun **perintah gambar** (`perintah_pola`, `perintah_rentang`;
## satu perintah = `[rentang: Array[Vector3i], asal: Vector2, warna: Color]`) lewat fungsi yang bisa dites headless, lalu `_draw` hanya
## menjalankan `gambar` (QA-003 iterasi 2). Rentang per huruf tiap pola dihitung sekali lalu disimpan (`rentang_pola`, QA-006), jadi pola
## yang digambar ulang tiap frame (garis bidik, koran terbang) tidak di-parse ulang.

## Huruf peran yang digambar, urut dari bawah ke atas.
const HURUF: Array[String] = ["o", "t", "s", "w"]

## Simpanan rentang per pola: kunci = isi pola (Array[String]), nilai = Array berisi satu `Array[Vector3i]` (hanya-baca) per huruf `HURUF`.
static var _simpanan: Dictionary = {}


## Warna untuk huruf peran pola (`PolaPiksel`): `o` OUTLINE, `t` TEXT, `s` TEXT_2, `w` = `utama`. Huruf lain = transparan.
static func warna_huruf(huruf: String, utama: Color) -> Color:
	match huruf:
		"o":
			return Palette.OUTLINE
		"t":
			return Palette.TEXT
		"s":
			return Palette.TEXT_2
		"w":
			return utama
	return Color(Palette.OUTLINE, 0.0)


## Rentang piksel pola per huruf peran (urut `HURUF`, `PolaPiksel.rentang_huruf`), dihitung sekali per isi pola lalu disimpan. Hasilnya
## hanya-baca dan dipakai bersama; jangan diubah.
static func rentang_pola(data: Array[String]) -> Array:
	var ada: Variant = _simpanan.get(data)
	if ada != null:
		return ada
	var hasil: Array = []
	for huruf: String in HURUF:
		var daftar: Array[Vector3i] = PolaPiksel.rentang_huruf(data, huruf)
		daftar.make_read_only()
		hasil.append(daftar)
	hasil.make_read_only()
	_simpanan[data.duplicate()] = hasil
	return hasil


## Perintah gambar pola dengan pojok kiri atas di `kiri_atas` (piksel game, dibulatkan), warna utama `utama`, dikali alpha `alpha`. Huruf
## yang tidak ada di pola dilewati.
static func perintah_pola(data: Array[String], kiri_atas: Vector2, utama: Color, alpha: float = 1.0) -> Array:
	var hasil: Array = []
	var asal: Vector2 = kiri_atas.round()
	var per_huruf: Array = rentang_pola(data)
	for i: int in range(HURUF.size()):
		var daftar: Array[Vector3i] = per_huruf[i]
		if daftar.is_empty():
			continue
		var warna: Color = warna_huruf(HURUF[i], utama)
		warna.a *= alpha
		hasil.append([daftar, asal, warna])
	return hasil


## Perintah gambar satu daftar rentang digeser `asal` (piksel game, bilangan bulat) dengan satu warna.
static func perintah_rentang(daftar: Array[Vector3i], asal: Vector2, warna: Color) -> Array:
	return [[daftar, asal, warna]]


## Menjalankan perintah gambar (`perintah_pola`, `perintah_rentang`) ke `kanvas`, urut.
static func gambar(kanvas: CanvasItem, perintah: Array) -> void:
	for p: Array in perintah:
		var daftar: Array[Vector3i] = p[0]
		rentang(kanvas, daftar, p[1], p[2])


## Menggambar pola langsung (`perintah_pola` lalu `gambar`).
static func pola(kanvas: CanvasItem, data: Array[String], kiri_atas: Vector2, utama: Color, alpha: float = 1.0) -> void:
	gambar(kanvas, perintah_pola(data, kiri_atas, utama, alpha))


## Menggambar rentang piksel (`Vector3i` baris, kolom awal, kolom akhir eksklusif) digeser `asal` (piksel game, bilangan bulat).
static func rentang(kanvas: CanvasItem, daftar: Array[Vector3i], asal: Vector2, warna: Color) -> void:
	for r: Vector3i in daftar:
		kanvas.draw_rect(Rect2(asal + Vector2(r.y, r.x), Vector2(r.z - r.y, 1)), warna)
