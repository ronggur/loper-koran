class_name ProgresRute
extends RefCounted
## Status kotak progres per pelanggan di panel HUD tengah atas, logika murni (DESIGN_SPEC 3.2; O-12 dan AC-7 run fase3c-hud-hasil, usulan).
##
## Satu kotak per pelanggan, urut sesuai rute (`RouteBuilder.Rute.pelanggan`). Status:
## - `TERKIRIM`: rumah sudah terantar (`SkorRute.Keadaan.terantar`).
## - `TERLEWAT`: belum terantar dan pusat kotak suratnya LEBIH dari `HUD_PROGRES_TERLEWAT_UBIN` (3,0) di belakang sepeda (jarak < -3,0;
##   tepat -3,0 belum terlewat), atau rute sudah selesai (garis akhir; sisanya tidak bisa diantar lagi, sama dengan "meleset" layar hasil).
## - `BERIKUTNYA`: SATU pelanggan, yang belum terantar dan terdekat di depan sepeda (jarak >= 0, terkecil); tidak ada sesudah rute selesai.
## - `BELUM`: selainnya (di depan, atau baru dilewati kurang dari 3 ubin dan masih bisa dikenai lemparan ke belakang).
## Tanpa node, `Time`, atau RNG; masukan tidak diubah.

enum Status { BELUM, TERKIRIM, TERLEWAT, BERIKUTNYA }


## Status kotak tiap pelanggan `rute` dengan sepeda di `maju_sepeda_ubin`, rumah terantar `terantar`, dan rute `selesai`. Rute null = kosong.
static func status(rute: RouteBuilder.Rute, maju_sepeda_ubin: float, terantar: Dictionary, selesai: bool) -> Array[Status]:
	var hasil: Array[Status] = []
	if rute == null:
		return hasil
	var berikutnya: int = -1
	var jarak_berikutnya: float = INF
	for i: int in range(rute.pelanggan.size()):
		var rumah: RouteBuilder.RumahRute = rute.pelanggan[i]
		var s: Status = Status.BELUM
		var j: float = RadarRute.jarak(rumah, maju_sepeda_ubin)
		if terantar.has(rumah.id):
			s = Status.TERKIRIM
		elif selesai or j < -Config.HUD_PROGRES_TERLEWAT_UBIN:
			s = Status.TERLEWAT
		elif j >= 0.0 and j < jarak_berikutnya:
			berikutnya = i
			jarak_berikutnya = j
		hasil.append(s)
	if berikutnya >= 0:
		hasil[berikutnya] = Status.BERIKUTNYA
	return hasil


## Jumlah pelanggan terantar di `rute` (terkirim, O-12): pelanggan rute yang id-nya ada di `terantar`.
static func jumlah_terkirim(rute: RouteBuilder.Rute, terantar: Dictionary) -> int:
	if rute == null:
		return 0
	var n: int = 0
	for rumah: RouteBuilder.RumahRute in rute.pelanggan:
		if terantar.has(rumah.id):
			n += 1
	return n
