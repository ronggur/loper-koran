class_name RadarRute
extends RefCounted
## Radar rumah di tepi layar, logika murni (GDD 4.3, 5.3, DESIGN_SPEC 3.4; K-2, O-9, O-10, AC-4 sampai AC-6 run fase3c-hud-hasil, usulan).
##
## Dari rute, jarak maju sepeda, rumah terantar, mode bantu, dan status tenggat -> daftar penanda per strip:
## - Strip = sisi DUNIA rumah: `seberang` = strip kiri, `dekat` = strip kanan. Kidal TIDAK menukar strip (tidak ada parameter kidal).
## - Jarak rumah = jarak maju dari sepeda ke pusat zona kotak suratnya (`ZonaSasaran.maju_kotak_surat`). Tampil bila 0 <= jarak <=
##   `RADAR_JANGKAUAN_UBIN` (kedua tepi INKLUSIF: tepat di samping sepeda dan tepat 30 ubin tampil; sedikit di belakang atau sedikit di
##   atas 30 tidak).
## - Posisi vertikal 0..1 = 1 - jarak / jangkauan: 0 = atas strip (jauh, 30 ubin), 1 = bawah strip (di samping sepeda). Penanda turun
##   saat rumah mendekat.
## - Jenis: pelanggan pemberi tip = `TIP` selama tenggat belum lewat; sesudah lewat tip tidak ada lagi, jadi tampil `PELANGGAN` (O-9).
##   Pelanggan lain = `PELANGGAN`. Rumah bukan pelanggan = `BUKAN`, hanya tampil saat mode bantu menyala (GDD 5.3, D-8 run 2B).
## - Rumah pelanggan yang sudah terantar keluar dari radar (O-9).
## - `jangkau` (O-10): rumah PELANGGAN (jenis `PELANGGAN` atau `TIP`) dengan 0 <= jarak <= jarak lemparan terjauh (5,0, inklusif;
##   dari `ThrowSolver`, satu-satunya pemakai angka lintasan).
##   Rumah bukan pelanggan tidak pernah `jangkau` (bukan sasaran).
## Tanpa node, `Time`, atau RNG; masukan tidak diubah.

enum Jenis { PELANGGAN, TIP, BUKAN }


## Satu penanda radar.
class Penanda extends RefCounted:
	## Sisi dunia rumah (`SEBERANG` = strip kiri, `DEKAT` = strip kanan).
	var sisi: LoperAnim.Sisi = LoperAnim.Sisi.TIDAK_ADA
	var jenis: Jenis = Jenis.PELANGGAN
	## 0 = atas strip (jauh), 1 = bawah strip (di samping sepeda).
	var vertikal: float = 0.0
	## True bila rumah pelanggan ini masuk jangkauan lempar (O-10).
	var jangkau: bool = false
	## Jarak maju dari sepeda ke pusat kotak surat, ubin.
	var jarak_ubin: float = 0.0
	var id_rumah: String = ""


## Jarak maju dari sepeda di `maju_sepeda_ubin` ke pusat kotak surat `rumah`, ubin (negatif = di belakang sepeda).
static func jarak(rumah: RouteBuilder.RumahRute, maju_sepeda_ubin: float) -> float:
	return ZonaSasaran.maju_kotak_surat(rumah) - maju_sepeda_ubin


## True bila rumah berjarak `jarak_ubin` masuk radar: 0 <= jarak <= `RADAR_JANGKAUAN_UBIN` (inklusif). NaN = false.
static func dalam_radar(jarak_ubin: float) -> bool:
	return is_finite(jarak_ubin) and jarak_ubin >= 0.0 and jarak_ubin <= Config.RADAR_JANGKAUAN_UBIN


## Posisi vertikal penanda untuk `jarak_ubin`: 1 - jarak / jangkauan, dijepit 0..1 (0 = atas, jauh).
static func vertikal(jarak_ubin: float) -> float:
	if not is_finite(jarak_ubin) or Config.RADAR_JANGKAUAN_UBIN <= 0.0:
		return 0.0
	return clampf(1.0 - jarak_ubin / Config.RADAR_JANGKAUAN_UBIN, 0.0, 1.0)


## True bila jarak `jarak_ubin` masuk jangkauan lempar: 0 <= jarak <= jarak tanah lemparan terjauh (`ThrowSolver.jarak_ubin(1)` =
## `LEMPAR_JARAK_MAKS_UBIN` 5,0; satu sumber angka lintasan) (inklusif; O-10).
static func dalam_jangkauan_lempar(jarak_ubin: float) -> bool:
	return is_finite(jarak_ubin) and jarak_ubin >= 0.0 and jarak_ubin <= ThrowSolver.jarak_ubin(1.0)


## Jenis penanda rumah `rumah` dengan status tenggat `tenggat_lewat` (O-9).
static func jenis(rumah: RouteBuilder.RumahRute, tenggat_lewat: bool) -> Jenis:
	if not rumah.pelanggan:
		return Jenis.BUKAN
	if rumah.pemberi_tip and not tenggat_lewat:
		return Jenis.TIP
	return Jenis.PELANGGAN


## Penanda radar untuk `rute` dengan sepeda di `maju_sepeda_ubin`, rumah terantar `terantar` (id -> true, `SkorRute.Keadaan.terantar`),
## mode bantu `bantu`, dan status tenggat `tenggat_lewat`. Urut sesuai urutan rumah di rute (maju). Rute null = kosong.
static func penanda(rute: RouteBuilder.Rute, maju_sepeda_ubin: float, terantar: Dictionary, bantu: bool, tenggat_lewat: bool) -> Array[Penanda]:
	var hasil: Array[Penanda] = []
	if rute == null or not is_finite(maju_sepeda_ubin):
		return hasil
	for rumah: RouteBuilder.RumahRute in rute.rumah:
		if rumah.sisi == LoperAnim.Sisi.TIDAK_ADA:
			continue
		if not rumah.pelanggan and not bantu:
			continue
		if rumah.pelanggan and terantar.has(rumah.id):
			continue
		var j: float = jarak(rumah, maju_sepeda_ubin)
		if not dalam_radar(j):
			continue
		var p: Penanda = Penanda.new()
		p.sisi = rumah.sisi
		p.jenis = jenis(rumah, tenggat_lewat)
		p.vertikal = vertikal(j)
		p.jangkau = rumah.pelanggan and dalam_jangkauan_lempar(j)
		p.jarak_ubin = j
		p.id_rumah = rumah.id
		hasil.append(p)
	return hasil


## Tepi atas penanda di dalam jalur strip, piksel game dari tepi atas jalur: `vertikal` x (`tinggi_jalur_px` - `tinggi_penanda_px`),
## dibulatkan. 0 = penanda menempel atas jalur, `tinggi_jalur_px - tinggi_penanda_px` = menempel bawah.
static func y_penanda_px(nilai_vertikal: float, tinggi_jalur_px: int, tinggi_penanda_px: int) -> int:
	var ruang: int = maxi(tinggi_jalur_px - tinggi_penanda_px, 0)
	return roundi(clampf(nilai_vertikal, 0.0, 1.0) * float(ruang))
