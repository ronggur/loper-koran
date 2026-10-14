class_name ZonaGambar
extends Node2D
## Tampilan zona sasaran placeholder jalan uji di bidang tanah (D-6 run fase2a-lemparan bagian 1b; usulan, bukan aset final). Data zona dari
## `ZonaSasaran.zona_jalan_uji` (sama dengan yang dipakai penilaian), digambar sebagai belah ketupat iso per piksel game:
## - halaman: garis tepi `TEXT` alpha `ZONA_GARIS_ALPHA` (rumput tetap terlihat);
## - teras: isi `UI_PANEL_RAISED` bergaris `OUTLINE`;
## - jendela (sisi seberang): strip tanah sempit di kaki fasad, isi `TEXT_2` bergaris `OUTLINE` (model placeholder 2D);
## - kotak surat sisi dekat: kotak datar `ACCENT` bergaris `OUTLINE` (sisi seberang sudah punya kotak surat graybox);
## - rumah bukan pelanggan: garis halaman dan isi teras `RADAR_BUKAN`, ditambah tanda lingkaran bergaris miring datar di halaman (bentuk,
##   bukan hanya warna).
## Sisi dekat hanya placeholder datar tanpa fasad dan tanpa jendela supaya lempar ke sisi dekat bisa diuji; ini TIDAK memutuskan cara
## menampilkan rumah di sisi dekat (ROADMAP 5).
## Node di antara ubin tanah dan objek dunia (di bawah rumah, sepeda, dan koran). Kavling yang digambar sama dengan slot rumah
## `ObjekDaur` (`JalanDaur`); gambar ulang hanya saat kavling pertama berganti. Pola rentang dihitung sekali per jenis kavling. Apa yang
## digambar diputuskan `perintah_kavling_tampil` (perintah `GambarPiksel`, dites headless; QA-003 iterasi 2); `_draw` hanya menjalankannya.

## Kavling pertama yang sedang digambar.
var _pertama: int = -1
## Rentang gambar kavling 0 untuk pelanggan dan bukan pelanggan: Array of [Array[Vector3i], Color].
var _pola_pelanggan: Array = []
var _pola_bukan: Array = []


func _ready() -> void:
	_pola_pelanggan = perintah_kavling(true)
	_pola_bukan = perintah_kavling(false)
	perbarui(0.0)


## Menyiapkan kavling untuk sepeda yang sudah menempuh `jarak_ubin`; gambar ulang hanya bila kavling pertama berganti.
func perbarui(jarak_ubin: float) -> void:
	var pertama: int = JalanDaur.indeks_pertama(jarak_ubin, Config.JALAN_UJI_RUMAH_PERIODE_UBIN, Config.JALAN_UJI_DAUR_MUNDUR_UBIN)
	if pertama == _pertama:
		return
	_pertama = pertama
	queue_redraw()


## Nomor kavling yang sedang digambar (urut).
func kavling_tampil() -> Array[int]:
	var hasil: Array[int] = []
	var jumlah: int = JalanDaur.jumlah_slot(Config.JALAN_UJI_DAUR_MUNDUR_UBIN, Config.JALAN_UJI_DAUR_MAJU_UBIN, Config.JALAN_UJI_RUMAH_PERIODE_UBIN)
	for i: int in range(jumlah):
		hasil.append(_pertama + i)
	return hasil


## Perintah gambar (`GambarPiksel`) kavling bernomor `indeks`: pola kavling pelanggan atau bukan pelanggan menurut
## `ZonaSasaran.pelanggan_jalan_uji` (sama dengan penilaian), digeser ke letak kavling itu di jalan.
func perintah_kavling_tampil(indeks: int) -> Array:
	var geser: Vector2 = Iso.posisi_gambar(Vector2(0.0, -float(indeks * Config.JALAN_UJI_RUMAH_PERIODE_UBIN)))
	var daftar: Array = _pola_pelanggan if ZonaSasaran.pelanggan_jalan_uji(indeks) else _pola_bukan
	var hasil: Array = []
	for perintah: Array in daftar:
		hasil.append([perintah[0], geser, perintah[1]])
	return hasil


## Perintah gambar semua kavling yang tampil (urut). `_draw` menjalankan ini.
func perintah_tampil() -> Array:
	var hasil: Array = []
	for indeks: int in kavling_tampil():
		hasil.append_array(perintah_kavling_tampil(indeks))
	return hasil


func _draw() -> void:
	GambarPiksel.gambar(self, perintah_tampil())


## Perintah gambar kavling 0 (rumah seberang pelanggan atau bukan): [rentang, warna], urut dari bawah ke atas. Publik untuk tes.
static func perintah_kavling(pelanggan: bool) -> Array:
	var hasil: Array = []
	var tengah_halaman: Vector2 = Vector2.ZERO
	for zona: ZonaSasaran.Zona in ZonaSasaran.zona_jalan_uji(0):
		# Status pelanggan hanya berlaku untuk rumah sisi seberang; kavling sisi dekat selalu pelanggan (`ZonaSasaran.zona_jalan_uji`).
		var langganan: bool = pelanggan or zona.sisi == LoperAnim.Sisi.DEKAT
		var garis_halaman: Color = Color(Palette.TEXT if langganan else Palette.RADAR_BUKAN, Config.ZONA_GARIS_ALPHA)
		var isi: Array[Vector3i] = PolaPiksel.rentang_poligon(PolaPiksel.sudut_zona(zona.persegi))
		var tepi: Array[Vector3i] = PolaPiksel.rentang_tepi(isi)
		match zona.jenis:
			ZonaSasaran.Jenis.HALAMAN:
				hasil.append([tepi, garis_halaman])
				if zona.sisi == LoperAnim.Sisi.SEBERANG:
					# Tanda di antara tengah halaman dan tepi depannya (sisi jalan), supaya tidak tertutup dinding rumah di belakangnya.
					var tengah: Vector2 = zona.persegi.get_center()
					var lateral: float = (tengah.x + zona.persegi.end.x) / 2
					tengah_halaman = Iso.posisi_gambar(Vector2(lateral, -tengah.y))
			ZonaSasaran.Jenis.TERAS:
				hasil.append([isi, Palette.UI_PANEL_RAISED if langganan else Palette.RADAR_BUKAN])
				hasil.append([tepi, Palette.OUTLINE])
			ZonaSasaran.Jenis.JENDELA:
				hasil.append([isi, Palette.TEXT_2])
				hasil.append([tepi, Palette.OUTLINE])
			ZonaSasaran.Jenis.KOTAK_SURAT:
				if zona.sisi == LoperAnim.Sisi.DEKAT:
					hasil.append([isi, Palette.ACCENT])
					hasil.append([tepi, Palette.OUTLINE])
	if not pelanggan:
		var ukuran: Vector2i = PolaPiksel.ukuran(PolaPiksel.TANDA_BUKAN_PELANGGAN)
		var pojok: Vector2 = tengah_halaman - Vector2(floori(float(ukuran.x) / 2), floori(float(ukuran.y) / 2))
		for huruf: String in ["o", "w"]:
			var rentang: Array[Vector3i] = PolaPiksel.rentang_huruf(PolaPiksel.TANDA_BUKAN_PELANGGAN, huruf)
			var tergeser: Array[Vector3i] = []
			for r: Vector3i in rentang:
				tergeser.append(Vector3i(r.x + int(pojok.y), r.y + int(pojok.x), r.z + int(pojok.x)))
			hasil.append([tergeser, GambarPiksel.warna_huruf(huruf, Palette.RADAR_BUKAN)])
	return hasil
