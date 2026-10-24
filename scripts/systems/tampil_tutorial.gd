class_name TampilTutorial
extends RefCounted
## Pemilihan tampilan petunjuk tutorial sebagai data murni (run ui2-semua-layar bagian C1, AC-5; kanvas Tutorial.dc.html; usulan): titik langkah (terisi sampai langkah sekarang, sisanya berongga:
## bentuk, bukan hanya warna) dan glif di samping kalimat menurut langkah. `TutorialController` dan `TitikLangkah` hanya mewujudkan pilihan ini; keputusan langkah tetap di `TutorialLangkah`.
## Tanpa node, `Time`, atau RNG.


## Titik langkah: satu elemen per langkah, true = terisi (langkah sekarang dan sebelumnya), false = berongga. `nomor` di luar 0..`total` dijepit; `total` <= 0 = kosong.
static func titik(nomor: int, total: int) -> Array[bool]:
	var hasil: Array[bool] = []
	for i: int in range(maxi(total, 0)):
		hasil.append(i + 1 <= nomor)
	return hasil


## Nama dasar tekstur glif di samping kalimat menurut langkah: kayuh panah naik, melambat panah turun, lempar panah ke kotak surat, menepi tanda seru; semuanya ACCENT.
static func nama_glif(langkah: TutorialLangkah.Langkah) -> String:
	match langkah:
		TutorialLangkah.Langkah.KAYUH:
			return "glif_naik_aksen"
		TutorialLangkah.Langkah.MELAMBAT:
			return "glif_turun_aksen"
		TutorialLangkah.Langkah.LEMPAR:
			return "glif_panah_aksen"
		TutorialLangkah.Langkah.MENEPI:
			return "glif_seru_aksen"
	return ""


## Lebar deretan titik, piksel game: `total` titik berjarak `TUTORIAL_TITIK_JARAK_PX`.
static func lebar_titik(total: int) -> int:
	if total <= 0:
		return 0
	return total * Config.TUTORIAL_TITIK_PX + (total - 1) * Config.TUTORIAL_TITIK_JARAK_PX


## Perintah gambar titik langkah (`[Rect2, Color]`, urut): terisi = cincin gelap `OUTLINE` 1 px di luar titik `ACCENT` 4x4; berongga = bingkai 1 px `TEXT_2` (empat persegi: atas, bawah, kiri, kanan).
## Koordinat dari pojok kiri atas deretan.
static func perintah_titik(nomor: int, total: int) -> Array:
	var hasil: Array = []
	var sisi: float = float(Config.TUTORIAL_TITIK_PX)
	var tebal: float = float(Config.UI_GARIS_PX)
	var penuh: Array[bool] = titik(nomor, total)
	for i: int in range(penuh.size()):
		var x: float = float(i * (Config.TUTORIAL_TITIK_PX + Config.TUTORIAL_TITIK_JARAK_PX))
		if penuh[i]:
			hasil.append([Rect2(x - tebal, -tebal, sisi + 2 * tebal, sisi + 2 * tebal), Palette.OUTLINE])
			hasil.append([Rect2(x, 0.0, sisi, sisi), Palette.ACCENT])
		else:
			hasil.append([Rect2(x, 0.0, sisi, tebal), Palette.TEXT_2])
			hasil.append([Rect2(x, sisi - tebal, sisi, tebal), Palette.TEXT_2])
			hasil.append([Rect2(x, tebal, tebal, sisi - 2 * tebal), Palette.TEXT_2])
			hasil.append([Rect2(x + sisi - tebal, tebal, tebal, sisi - 2 * tebal), Palette.TEXT_2])
	return hasil
