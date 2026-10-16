class_name JendelaRute
extends RefCounted
## Jendela daur rumah rute: rumah mana yang perlu ada (diinstansiasi) di sekitar sepeda, logika murni (AC-12 run fase3a-rute, usulan).
##
## Rute sekitar 250 ubin dengan puluhan rumah; yang digambar hanya rumah yang jarak majunya ada di jendela
## `[maju sepeda - RUTE_DAUR_MUNDUR_UBIN, maju sepeda + RUTE_DAUR_MAJU_UBIN]`. Daftar rumah rute berurut maju (`RouteBuilder`, dijaga
## tes), jadi jendela = rentang indeks yang dicari dengan pencarian biner, bukan pemindaian seluruh rute tiap langkah.


## Rentang indeks `[awal, akhir)` pada `daftar` (urut maju menaik) untuk rumah yang `maju_ubin`-nya di antara `dari_maju_ubin` dan
## `sampai_maju_ubin`, kedua ujung inklusif. Masukan tidak hingga atau terbalik = rentang kosong `(0, 0)`.
static func rentang(daftar: Array[RouteBuilder.RumahRute], dari_maju_ubin: float, sampai_maju_ubin: float) -> Vector2i:
	if not is_finite(dari_maju_ubin) or not is_finite(sampai_maju_ubin) or dari_maju_ubin > sampai_maju_ubin:
		return Vector2i.ZERO
	var awal: int = _batas_bawah(daftar, dari_maju_ubin, false)
	var akhir: int = _batas_bawah(daftar, sampai_maju_ubin, true)
	return Vector2i(awal, maxi(akhir, awal))


## Rentang rumah di sekitar sepeda yang sudah menempuh `jarak_ubin`: jendela daur dari `Config.RUTE_DAUR_*`.
static func rentang_sekitar(daftar: Array[RouteBuilder.RumahRute], jarak_ubin: float) -> Vector2i:
	if not is_finite(jarak_ubin):
		return Vector2i.ZERO
	return rentang(daftar, jarak_ubin - float(Config.RUTE_DAUR_MUNDUR_UBIN), jarak_ubin + float(Config.RUTE_DAUR_MAJU_UBIN))


## Indeks pertama dengan `maju_ubin` >= `nilai` (atau > `nilai` bila `lewati_sama`); `daftar.size()` bila tidak ada.
static func _batas_bawah(daftar: Array[RouteBuilder.RumahRute], nilai: float, lewati_sama: bool) -> int:
	var rendah: int = 0
	var tinggi: int = daftar.size()
	while rendah < tinggi:
		var tengah: int = (rendah + tinggi) / 2
		var maju: float = daftar[tengah].maju_ubin
		var lanjut: bool = maju <= nilai if lewati_sama else maju < nilai
		if lanjut:
			rendah = tengah + 1
		else:
			tinggi = tengah
	return rendah
