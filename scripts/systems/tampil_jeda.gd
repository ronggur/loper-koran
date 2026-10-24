class_name TampilJeda
extends RefCounted
## Pemilihan tampilan layar jeda sebagai data murni (run ui2-semua-layar bagian C1, AC-4, V-2; kanvas Jeda.dc.html; usulan): lapisan 72 %, kunci teks dan bingkai sakelar
## menurut keadaan, glif, dan kenop sakelar 22x12 yang digambar dari pola huruf (bukan PNG). `LayarJeda` dan `KenopSakelar` hanya mewujudkan pilihan ini.
## Tanpa node, `Time`, atau RNG. Keadaan sakelar terbaca TANPA warna: teks "nyala"/"mati" berganti, bingkai berganti (ACCENT), kenop berpindah sisi dan bentuk
## (mati: kenop berongga di kiri dan kotak kosong di kanan; nyala: kenop terisi di kanan dan garis tegak di kiri).

## Kenop mati 22x12: `o` OUTLINE, `s` TEXT_2, `g` UI_BG (gelap), `.` transparan. Dari `.sak` di kanvas `ui.css`.
const KENOP_MATI: Array[String] = [
	"oooooooooooooooooooooo",
	"osssssssssssssssssssso",
	"osggggggggggggggggggso",
	"osgssssssgggggggggggso",
	"osgsggggsgggggssssggso",
	"osgsggggsgggggsggsggso",
	"osgsggggsgggggsggsggso",
	"osgsggggsgggggssssggso",
	"osgssssssgggggggggggso",
	"osggggggggggggggggggso",
	"osssssssssssssssssssso",
	"oooooooooooooooooooooo",
]
## Kenop nyala 22x12: `o` OUTLINE, `a` ACCENT, `t` TEXT, `g` UI_BG. Dari `.sak.on` di kanvas.
const KENOP_NYALA: Array[String] = [
	"oooooooooooooooooooooo",
	"oaaaaaaaaaaaaaaaaaaaao",
	"oaaaaaaaaaaaaaaaaaaaao",
	"oaaaagaaaaaaaooooooaao",
	"oaaaagaaaaaaaottttoaao",
	"oaaaagaaaaaaaottttoaao",
	"oaaaagaaaaaaaottttoaao",
	"oaaaagaaaaaaaottttoaao",
	"oaaaagaaaaaaaooooooaao",
	"oaaaaaaaaaaaaaaaaaaaao",
	"oaaaaaaaaaaaaaaaaaaaao",
	"oooooooooooooooooooooo",
]


## Warna lapisan di atas jalan: `HUD_PANEL` dengan alpha `JEDA_LAPISAN_ALPHA` (V-2). Token `HUD_PANEL` sendiri tidak berubah.
static func warna_lapisan() -> Color:
	return Color(Palette.HUD_PANEL, Config.JEDA_LAPISAN_ALPHA)


## Kunci teks sakelar kidal menurut keadaan.
static func kunci_teks_kidal(nyala: bool) -> String:
	return "JEDA_KIDAL_NYALA" if nyala else "JEDA_KIDAL_MATI"


## Kunci teks sakelar mode bantu menurut keadaan.
static func kunci_teks_bantu(nyala: bool) -> String:
	return "HUD_BANTU_NYALA" if nyala else "HUD_BANTU_MATI"


## Nama dasar tekstur bingkai sakelar (`KomponenUi.nama_tekstur_tombol`): mati bingkai biasa, nyala bingkai ACCENT.
static func nama_bingkai_sakelar(nyala: bool) -> String:
	return KomponenUi.nama_tekstur_tombol(KomponenUi.Peran.SAKELAR, KomponenUi.KeadaanTombol.NORMAL, nyala)


## Nama dasar tekstur glif di samping judul JEDA.
static func nama_glif_judul() -> String:
	return "glif_jeda_terang"


## Nama dasar tekstur glif di tombol Lanjut (gelap di atas ACCENT).
static func nama_glif_lanjut() -> String:
	return "glif_lanjut_gelap"


## Pola kenop menurut keadaan.
static func pola_kenop(nyala: bool) -> Array[String]:
	return KENOP_NYALA if nyala else KENOP_MATI


## Warna huruf pola kenop dari `Palette`; huruf lain (termasuk `.`) transparan.
static func warna_kenop(huruf: String) -> Color:
	match huruf:
		"o":
			return Palette.OUTLINE
		"s":
			return Palette.TEXT_2
		"a":
			return Palette.ACCENT
		"t":
			return Palette.TEXT
		"g":
			return Palette.UI_BG
	return Color(Palette.OUTLINE, 0.0)


## Perintah gambar kenop: satu `[Rect2, Color]` per rentang mendatar sewarna di tiap baris pola (huruf `.` dilewati), urut dari atas dan kiri. Piksel game bilangan bulat.
static func perintah_kenop(nyala: bool) -> Array:
	var hasil: Array = []
	var pola: Array[String] = pola_kenop(nyala)
	for y: int in range(pola.size()):
		var baris: String = pola[y]
		var x: int = 0
		while x < baris.length():
			var huruf: String = baris[x]
			var akhir: int = x
			while akhir + 1 < baris.length() and baris[akhir + 1] == huruf:
				akhir += 1
			if huruf != ".":
				hasil.append([Rect2(float(x), float(y), float(akhir - x + 1), 1.0), warna_kenop(huruf)])
			x = akhir + 1
	return hasil
