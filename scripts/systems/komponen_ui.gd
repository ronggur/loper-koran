class_name KomponenUi
extends RefCounted
## Pemilihan keadaan komponen UI redesain sebagai data murni (run ui1-komponen-bengkel bagian A, AC-4 dan AC-5; docs/design/redesain/README.md 3 dan 4; usulan):
## tombol (empat peran x normal/ditekan/nonaktif), kartu (biasa/menonjol/redup), dan chip (status -> gaya + glif + kunci teks). `GayaHud` hanya mewujudkan pilihan ini
## jadi `StyleBoxTexture`. Tanpa node, `Time`, atau RNG. Setiap keadaan terbaca TANPA warna: tombol nonaktif rata tanpa bibir (tekstur sendiri), diarsir, teksnya tipis dan
## berganti alasan; kartu menonjol dipasangkan dengan chip "!" + teks, kartu redup dengan chip centang + teks; chip membawa glif dan teks sendiri.

## Peran tombol (README redesain 3 butir 4): utama = aksi utama (ACCENT), biasa = aksi biasa, sakelar = nyala/mati, tenang = lewati atau bahaya ringan.
enum Peran { UTAMA, BIASA, SAKELAR, TENANG }
## Keadaan tombol: NONAKTIF menang atas DITEKAN (tombol nonaktif tidak punya keadaan tekan).
enum KeadaanTombol { NORMAL, DITEKAN, NONAKTIF }
## Jenis kartu: MENONJOL = butuh perhatian (garis dalam WARN), REDUP = selesai atau sudah dimiliki, BIASA = selain itu.
enum JenisKartu { BIASA, MENONJOL, REDUP }
## Gaya chip menurut bingkai (`ui_chip_*.png`): GELAP harga dan saldo, OK baik, WARN perlu servis, NETRAL aus dan dimiliki, AKSEN tingkat aktif.
enum GayaChip { GELAP, OK, WARN, NETRAL, AKSEN }
## Glif di dalam chip: TANPA, CENTANG (selesai atau baik), SERU ("!" perlu perhatian).
enum GlifChip { TANPA, CENTANG, SERU }
## Status yang dipetakan ke chip. TINGKAT_AKTIF dan TINGKAT_LAIN = jejak tingkat upgrade (I, II, III).
enum StatusChip { HARGA, BAIK, AUS, PERLU_SERVIS, DIMILIKI, TINGKAT_AKTIF, TINGKAT_LAIN }
## Ukuran chip: tinggi 14, 18, atau 24 (`Config.UI_CHIP_TINGGI_*`).
enum UkuranChip { KECIL, NORMAL, BESAR }


## Isi satu chip: gaya bingkai, glif, dan kunci teks terjemahan ("" bila teksnya diberikan pemanggil, mis. angka harga atau I/II/III).
class InfoChip extends RefCounted:
	var gaya: KomponenUi.GayaChip
	var glif: KomponenUi.GlifChip
	var kunci_teks: String


	func _init(gaya_chip: KomponenUi.GayaChip, glif_chip: KomponenUi.GlifChip, kunci: String) -> void:
		gaya = gaya_chip
		glif = glif_chip
		kunci_teks = kunci


## Keadaan tombol dari status aktif dan tekan: nonaktif menang.
static func keadaan_tombol(aktif: bool, ditekan: bool) -> KeadaanTombol:
	if not aktif:
		return KeadaanTombol.NONAKTIF
	return KeadaanTombol.DITEKAN if ditekan else KeadaanTombol.NORMAL


## Nama dasar tekstur bingkai tombol (tanpa awalan `ui_` dan `.png`). Nonaktif satu bingkai untuk semua peran; sakelar mati memakai bingkai biasa, sakelar nyala bingkai ACCENT,
## sakelar ditekan memakai `btn_biasa_tekan` (kanvas tidak punya sakelar_tekan).
static func nama_tekstur_tombol(peran: Peran, keadaan: KeadaanTombol, nyala: bool = false) -> String:
	if keadaan == KeadaanTombol.NONAKTIF:
		return "btn_nonaktif"
	var tekan: bool = keadaan == KeadaanTombol.DITEKAN
	match peran:
		Peran.UTAMA:
			return "btn_utama_tekan" if tekan else "btn_utama"
		Peran.BIASA:
			return "btn_biasa_tekan" if tekan else "btn_biasa"
		Peran.SAKELAR:
			if tekan:
				return "btn_biasa_tekan"
			return "btn_sakelar_nyala" if nyala else "btn_biasa"
	return "btn_tenang_tekan" if tekan else "btn_tenang"


## Tambahan margin isi di luar tepi 9-slice: `Vector2i(atas, bawah)`. Utama, biasa, dan sakelar punya bibir 2 px: normal teks naik (bawah +2), ditekan teks turun (atas +2),
## jadi teks turun 2 px seperti wajahnya. Tenang dan nonaktif rata tanpa bibir: tidak ada geseran.
static func margin_isi_tombol(peran: Peran, keadaan: KeadaanTombol) -> Vector2i:
	if keadaan == KeadaanTombol.NONAKTIF or peran == Peran.TENANG:
		return Vector2i.ZERO
	if keadaan == KeadaanTombol.DITEKAN:
		return Vector2i(Config.UI_TOMBOL_TEKAN_GESER_PX, 0)
	return Vector2i(0, Config.UI_TOMBOL_TEKAN_GESER_PX)


## Warna teks tombol dari `Palette`: utama gelap di atas ACCENT, biasa TEXT (ACCENT saat ditekan), sakelar TEXT, tenang TEXT_2 (TEXT saat ditekan), nonaktif TEXT_2.
static func warna_teks_tombol(peran: Peran, keadaan: KeadaanTombol) -> Color:
	if keadaan == KeadaanTombol.NONAKTIF:
		return Palette.TEXT_2
	var tekan: bool = keadaan == KeadaanTombol.DITEKAN
	match peran:
		Peran.UTAMA:
			return Palette.UI_BG
		Peran.BIASA:
			return Palette.ACCENT if tekan else Palette.TEXT
		Peran.SAKELAR:
			return Palette.TEXT
	return Palette.TEXT if tekan else Palette.TEXT_2


## True bila teks tombol memakai bobot SemiBold; tenang dan nonaktif memakai Regular (kanvas `.btn.tenang,.btn.nonaktif{font-weight:400}`), jadi nonaktif tidak sekadar lebih redup.
static func teks_tebal(peran: Peran, keadaan: KeadaanTombol) -> bool:
	return keadaan != KeadaanTombol.NONAKTIF and peran != Peran.TENANG


## Teks yang tampil di tombol: tombol nonaktif bertulis `alasan` ("Koin kurang") bila alasan ada, selain itu `teks`. Alasan memberi tahu kenapa mati tanpa mengandalkan warna.
static func teks_tombol(teks: String, aktif: bool, alasan: String) -> String:
	if not aktif and alasan != "":
		return alasan
	return teks


## Kartu servis menurut tingkat kondisi komponen: PERLU_BENGKEL menonjol, BAIK redup, AUS biasa.
static func kartu_servis(tingkat: BikeCondition.Tingkat) -> JenisKartu:
	match tingkat:
		BikeCondition.Tingkat.PERLU_BENGKEL:
			return JenisKartu.MENONJOL
		BikeCondition.Tingkat.BAIK:
			return JenisKartu.REDUP
	return JenisKartu.BIASA


## Kartu upgrade: yang sudah dimiliki redup, selain itu biasa.
static func kartu_upgrade(dimiliki: bool) -> JenisKartu:
	return JenisKartu.REDUP if dimiliki else JenisKartu.BIASA


## Nama dasar tekstur kartu (tanpa `ui_` dan `.png`).
static func nama_tekstur_kartu(jenis: JenisKartu) -> String:
	match jenis:
		JenisKartu.MENONJOL:
			return "kartu_menonjol"
		JenisKartu.REDUP:
			return "kartu_redup"
	return "kartu_biasa"


## Isi chip untuk `status`: gaya bingkai, glif, dan kunci teks. BAIK = centang + "Baik", PERLU_SERVIS = "!" + "Perlu servis", AUS = teks "Aus" tanpa glif, DIMILIKI = centang + "Dimiliki".
## HARGA dan tingkat tidak punya kunci (angka atau I/II/III diberikan pemanggil). Status yang berbeda selalu beda glif atau teks, tidak hanya warna.
static func chip(status: StatusChip) -> InfoChip:
	match status:
		StatusChip.BAIK:
			return InfoChip.new(GayaChip.OK, GlifChip.CENTANG, "BENGKEL_BAIK")
		StatusChip.AUS:
			return InfoChip.new(GayaChip.NETRAL, GlifChip.TANPA, "KONDISI_TINGKAT_AUS")
		StatusChip.PERLU_SERVIS:
			return InfoChip.new(GayaChip.WARN, GlifChip.SERU, "KONDISI_TINGKAT_PERLU")
		StatusChip.DIMILIKI:
			return InfoChip.new(GayaChip.NETRAL, GlifChip.CENTANG, "BENGKEL_DIMILIKI")
		StatusChip.TINGKAT_AKTIF:
			return InfoChip.new(GayaChip.AKSEN, GlifChip.TANPA, "")
		StatusChip.TINGKAT_LAIN:
			return InfoChip.new(GayaChip.NETRAL, GlifChip.TANPA, "")
	return InfoChip.new(GayaChip.GELAP, GlifChip.TANPA, "")


## Status chip untuk tingkat kondisi komponen sepeda.
static func status_chip_servis(tingkat: BikeCondition.Tingkat) -> StatusChip:
	match tingkat:
		BikeCondition.Tingkat.PERLU_BENGKEL:
			return StatusChip.PERLU_SERVIS
		BikeCondition.Tingkat.AUS:
			return StatusChip.AUS
	return StatusChip.BAIK


## Nama dasar tekstur bingkai chip (tanpa `ui_` dan `.png`).
static func nama_tekstur_chip(gaya: GayaChip) -> String:
	match gaya:
		GayaChip.OK:
			return "chip_ok"
		GayaChip.WARN:
			return "chip_warn"
		GayaChip.NETRAL:
			return "chip_netral"
		GayaChip.AKSEN:
			return "chip_aksen"
	return "chip_gelap"


## Nama dasar tekstur glif chip yang terpasang (warna sudah tertanam di sheet glif12): centang hijau di chip OK, centang abu di chip NETRAL, "!" oranye di chip WARN. "" bila tidak ada glif.
static func nama_glif_chip(info: InfoChip) -> String:
	match info.glif:
		GlifChip.CENTANG:
			return "glif_centang_ok" if info.gaya == GayaChip.OK else "glif_centang_teks2"
		GlifChip.SERU:
			return "glif_seru_warn"
	return ""


## Tinggi chip menurut ukuran, piksel game (`Config.UI_CHIP_TINGGI_*`).
static func tinggi_chip(ukuran: UkuranChip) -> int:
	match ukuran:
		UkuranChip.KECIL:
			return Config.UI_CHIP_TINGGI_KECIL_PX
		UkuranChip.BESAR:
			return Config.UI_CHIP_TINGGI_BESAR_PX
	return Config.UI_CHIP_TINGGI_PX


## Jarak isi chip ke samping di luar tepi 9-slice, piksel game.
static func pad_x_chip(ukuran: UkuranChip) -> int:
	match ukuran:
		UkuranChip.KECIL:
			return Config.UI_CHIP_PAD_X_KECIL_PX
		UkuranChip.BESAR:
			return Config.UI_CHIP_PAD_X_BESAR_PX
	return Config.UI_CHIP_PAD_X_PX
