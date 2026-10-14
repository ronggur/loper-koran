class_name GambarPiksel
extends RefCounted
## Menggambar pola dan rentang `PolaPiksel` ke `CanvasItem` sebagai persegi piksel game bilangan bulat (tajam di skala bulat), warna dari
## `Palette` (run fase2a-lemparan bagian 1b). Dipakai `GarisBidik`, `KoranGambar`, `ZonaGambar`, dan `DeretKoran`.


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


## Menggambar pola dengan pojok kiri atas di `kiri_atas` (piksel game, dibulatkan), warna utama `utama`, dikali alpha `alpha`.
static func pola(kanvas: CanvasItem, data: Array[String], kiri_atas: Vector2, utama: Color, alpha: float = 1.0) -> void:
	var asal: Vector2 = kiri_atas.round()
	for huruf: String in ["o", "t", "s", "w"]:
		var warna: Color = warna_huruf(huruf, utama)
		warna.a *= alpha
		rentang(kanvas, PolaPiksel.rentang_huruf(data, huruf), asal, warna)


## Menggambar rentang piksel (`Vector3i` baris, kolom awal, kolom akhir eksklusif) digeser `asal` (piksel game, bilangan bulat).
static func rentang(kanvas: CanvasItem, daftar: Array[Vector3i], asal: Vector2, warna: Color) -> void:
	for r: Vector3i in daftar:
		kanvas.draw_rect(Rect2(asal + Vector2(r.y, r.x), Vector2(r.z - r.y, 1)), warna)
