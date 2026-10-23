class_name TampilKondisiBesar
extends RefCounted
## Geometri dan warna kotak kondisi BESAR (kartu servis bengkel; AC-5 run ui1-komponen-bengkel bagian A; docs/design/redesain/README.md 4, kanvas ui.css `.kk`; usulan) sebagai data murni.
## Tiga kotak 8x8 berjarak 2, tanda "!" 3x9 di kanannya. Isi kotak dan tanda dari `TampilKondisi` (jumlah kotak, PERLU_BENGKEL, peringatan) supaya HUD dan bengkel satu sumber.
## Status terbaca tanpa warna: kotak terisi (terang, bergaris gelap) vs berongga (gelap, bergaris terang), jumlah kotak terisi, dan "!". Versi HUD 5x5 (`KotakKondisi`) tidak berubah.

## Bidang gambar satu kotak: `rect` (piksel game relatif pojok kiri atas komponen), `isi`, `garis` (garis 1 px di tepi `rect`).
class BidangKotak extends RefCounted:
	var rect: Rect2i
	var isi: Color
	var garis: Color


	func _init(persegi: Rect2i, warna_isi: Color, warna_garis: Color) -> void:
		rect = persegi
		isi = warna_isi
		garis = warna_garis


## Ukuran komponen: tiga kotak + jarak + ruang tanda "!" (selalu disediakan supaya kartu tidak melompat saat kondisi berubah), tinggi = tanda "!".
static func ukuran() -> Vector2i:
	var tanda: Vector2i = ukuran_seru()
	var kotak: int = Config.KONDISI_KOTAK_BAIK * Config.KONDISI_BESAR_KOTAK_PX + (Config.KONDISI_KOTAK_BAIK - 1) * Config.KONDISI_BESAR_KOTAK_JARAK_PX
	return Vector2i(kotak + Config.KONDISI_BESAR_SERU_JARAK_PX + tanda.x, maxi(tanda.y, Config.KONDISI_BESAR_KOTAK_PX))


## Ukuran tanda "!" (`PolaPiksel.TANDA_SERU_KONDISI`): 3x9.
static func ukuran_seru() -> Vector2i:
	var pola: Array[String] = PolaPiksel.TANDA_SERU_KONDISI
	return Vector2i(pola[0].length(), pola.size())


## Persegi kotak ke-`indeks` (0 kiri): sejajar tengah tegak terhadap tinggi komponen.
static func rect_kotak(indeks: int) -> Rect2i:
	var x: int = indeks * (Config.KONDISI_BESAR_KOTAK_PX + Config.KONDISI_BESAR_KOTAK_JARAK_PX)
	var y: int = (ukuran().y - Config.KONDISI_BESAR_KOTAK_PX) >> 1
	return Rect2i(x, y, Config.KONDISI_BESAR_KOTAK_PX, Config.KONDISI_BESAR_KOTAK_PX)


## Pojok kiri atas tanda "!" (selalu dihitung; digambar hanya bila `TampilKondisi.tanda_seru`).
static func posisi_seru() -> Vector2i:
	var kotak: int = Config.KONDISI_KOTAK_BAIK * Config.KONDISI_BESAR_KOTAK_PX + (Config.KONDISI_KOTAK_BAIK - 1) * Config.KONDISI_BESAR_KOTAK_JARAK_PX
	return Vector2i(kotak + Config.KONDISI_BESAR_SERU_JARAK_PX, 0)


## Warna isi kotak (`Palette`): PENUH `TEXT`, PENUH_WARN `WARN`, KOSONG `UI_BG` (lubang gelap).
static func warna_isi(kotak: TampilKondisi.Kotak) -> Color:
	match kotak:
		TampilKondisi.Kotak.PENUH:
			return Palette.TEXT
		TampilKondisi.Kotak.PENUH_WARN:
			return Palette.WARN
	return Palette.UI_BG


## Warna garis 1 px kotak: terisi `OUTLINE` (gelap), berongga `TEXT_2` (terang), kebalikan isinya supaya bentuk berongga terbaca dari kontras tepi dan isi.
static func warna_garis(kotak: TampilKondisi.Kotak) -> Color:
	return Palette.TEXT_2 if kotak == TampilKondisi.Kotak.KOSONG else Palette.OUTLINE


## Tiga bidang kotak untuk kondisi `kondisi` (0..1) dan status peringatan `kedip` (urut kiri ke kanan).
static func bidang(kondisi: float, kedip: bool) -> Array[BidangKotak]:
	var hasil: Array[BidangKotak] = []
	var kotak: Array[TampilKondisi.Kotak] = TampilKondisi.kotak(kondisi, kedip)
	for i: int in range(kotak.size()):
		hasil.append(BidangKotak.new(rect_kotak(i), warna_isi(kotak[i]), warna_garis(kotak[i])))
	return hasil
