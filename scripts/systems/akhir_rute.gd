class_name AkhirRute
extends RefCounted
## Akhir rute, logika murni (AC-14 run fase3a-rute, K-5, usulan): garis akhir tercapai tepat sekali, lalu sepeda direm dan input dikunci.
##
## Garis akhir = panjang rute (`RouteBuilder.Rute.panjang_ubin`). Bila jarak tempuh sepeda mencapainya (inklusif) rute selesai; sesudah
## itu `periksa` tidak pernah melaporkan `baru_selesai` lagi sampai rute disusun ulang (pemanggil memulai dari `sudah_selesai` false).
## Rem sesudah garis akhir memakai stick buatan `stick_akhir` (tarik penuh ke bawah) lewat `BikeMotion` biasa, jadi laju rem dan pose
## rem sama dengan rem pemain (`REM_PERLAMBATAN_UD2`); stick sungguhan tidak dibaca lagi (dikunci). Tanpa node, `Time`, atau RNG.


## Hasil satu pemeriksaan garis akhir.
class Status extends RefCounted:
	## True sejak garis akhir tercapai (tetap true sesudahnya).
	var selesai: bool = false
	## True hanya pada pemeriksaan yang pertama kali mencapai garis akhir (sinyal `rute_selesai` tepat sekali).
	var baru_selesai: bool = false


## True bila `jarak_ubin` sudah mencapai `panjang_ubin` (inklusif). Panjang tidak positif atau masukan tidak hingga = false.
static func tercapai(jarak_ubin: float, panjang_ubin: float) -> bool:
	if not is_finite(jarak_ubin) or not is_finite(panjang_ubin) or panjang_ubin <= 0.0:
		return false
	return jarak_ubin >= panjang_ubin


## Status sesudah memeriksa `jarak_ubin` terhadap `panjang_ubin`, dari status `sudah_selesai` sebelumnya.
static func periksa(sudah_selesai: bool, jarak_ubin: float, panjang_ubin: float) -> Status:
	var status: Status = Status.new()
	if sudah_selesai:
		status.selesai = true
		return status
	if tercapai(jarak_ubin, panjang_ubin):
		status.selesai = true
		status.baru_selesai = true
	return status


## Vektor stick yang diberikan ke sepeda sesudah garis akhir: lurus ke bawah, penuh (rem).
static func stick_akhir() -> Vector2:
	return Vector2(0.0, Config.RUTE_AKHIR_STICK_Y)
