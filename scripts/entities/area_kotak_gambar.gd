class_name AreaKotakGambar
extends Node2D
## Area kotak surat rumah pelanggan seberang digambar di tanah scene rute (tindak lanjut uji HP pemilik 2026-10-16, run fase3a-rute;
## usulan, bukan aset final). Sebelumnya hanya kubus graybox oranye yang tergambar, padahal zona penilaian 0,5 x 0,5 (kini 1,0 x 1,5,
## `Config.JALAN_UJI_SEBERANG_KOTAK_SURAT_UBIN`) tidak terlihat: pemain tidak tahu area yang sebenarnya.
##
## Persegi yang digambar = persegi zona kotak surat yang dipakai penilaian (`ZonaSasaran.zona_rumah`), jadi yang terlihat = yang dinilai
## (prediksi = hasil). Bentuk: isi `ACCENT` tipis (`Config.AREA_KOTAK_ISI_ALPHA`) dan garis tepi `OUTLINE` tegas
## (`Config.AREA_KOTAK_TEPI_ALPHA`): terbaca dari garis tepi, tidak hanya warna isi (rule `ui-scenes`). Hanya rumah PELANGGAN sisi seberang
## yang punya area; rumah bukan pelanggan dan semua rumah dekat tidak digambar (keputusan perilaku dan skor tidak berubah).
##
## Rumah yang digambar mengikuti jendela daur yang sama dengan `RumahDaurRute` (`JendelaRute.rentang_sekitar`); gambar ulang hanya saat
## jendela berganti. Node di antara ubin tanah dan objek dunia (di bawah rumah, sepeda, dan koran), seperti `ZonaGambar`. Apa yang
## digambar diputuskan `perintah_tampil` (perintah `GambarPiksel`, dites headless); `_draw` hanya menjalankannya.

var _rumah: Array[RouteBuilder.RumahRute] = []
## Rentang indeks `[awal, akhir)` yang sedang digambar; (-1, -1) = belum ada.
var _tampil: Vector2i = Vector2i(-1, -1)
## Perintah gambar yang sedang berlaku: [rentang, asal, warna] urut dari bawah ke atas.
var _perintah: Array = []


## Mengganti rute: jendela dihitung ulang untuk jarak 0.
func atur_rute(rute: RouteBuilder.Rute) -> void:
	_rumah = rute.rumah
	_tampil = Vector2i(-1, -1)
	perbarui(0.0)


## Menyiapkan area untuk sepeda yang sudah menempuh `jarak_ubin`; gambar ulang hanya bila jendela daur berganti.
func perbarui(jarak_ubin: float) -> void:
	var rentang: Vector2i = JendelaRute.rentang_sekitar(_rumah, jarak_ubin)
	if rentang == _tampil:
		return
	_tampil = rentang
	_perintah = perintah_rentang(_rumah, rentang)
	queue_redraw()


## Indeks rumah (di `Rute.rumah`) yang sedang punya area, urut.
func indeks_tampil() -> Array[int]:
	var hasil: Array[int] = []
	for indeks: int in range(maxi(_tampil.x, 0), maxi(_tampil.y, 0)):
		if punya_area(_rumah[indeks]):
			hasil.append(indeks)
	return hasil


## Banyaknya area yang sedang digambar (satu per rumah pelanggan seberang di jendela).
func jumlah_area() -> int:
	return indeks_tampil().size()


## Perintah gambar semua area yang sedang berlaku (isi lalu garis tepi, per rumah). `_draw` menjalankan ini.
func perintah_tampil() -> Array:
	return _perintah


func _draw() -> void:
	GambarPiksel.gambar(self, _perintah)


## True bila rumah punya area: pelanggan di sisi seberang (rumah bukan pelanggan dan rumah dekat tidak).
static func punya_area(rumah: RouteBuilder.RumahRute) -> bool:
	return rumah.pelanggan and rumah.sisi == LoperAnim.Sisi.SEBERANG


## Perintah gambar (`[rentang, asal, warna]`) area kotak surat satu rumah: isi lalu garis tepi; kosong bila rumah tidak punya area.
## Persegi = zona kotak surat rumah itu yang dipakai penilaian. Publik untuk tes.
static func perintah_rumah(rumah: RouteBuilder.RumahRute) -> Array:
	var hasil: Array = []
	if not punya_area(rumah):
		return hasil
	for zona: ZonaSasaran.Zona in ZonaSasaran.zona_rumah(rumah):
		if zona.jenis != ZonaSasaran.Jenis.KOTAK_SURAT:
			continue
		var isi: Array[Vector3i] = PolaPiksel.rentang_poligon(PolaPiksel.sudut_zona(zona.persegi))
		var tepi: Array[Vector3i] = PolaPiksel.rentang_tepi(isi)
		hasil.append([isi, Vector2.ZERO, Color(Palette.ACCENT, Config.AREA_KOTAK_ISI_ALPHA)])
		hasil.append([tepi, Vector2.ZERO, Color(Palette.OUTLINE, Config.AREA_KOTAK_TEPI_ALPHA)])
	return hasil


## Perintah gambar semua rumah dengan indeks di rentang `[awal, akhir)` pada `daftar`, urut. Publik untuk tes.
static func perintah_rentang(daftar: Array[RouteBuilder.RumahRute], rentang: Vector2i) -> Array:
	var hasil: Array = []
	for indeks: int in range(maxi(rentang.x, 0), mini(rentang.y, daftar.size())):
		hasil.append_array(perintah_rumah(daftar[indeks]))
	return hasil
