class_name MobilGarasi
extends RefCounted
## Mobil keluar garasi perumahan, mesin keadaan murni (GDD 9.3, ROUTE_DESIGN 4; AC-2, AC-3 run fase3b-rintangan-skor, usulan).
##
## Tanpa node, `Time`, atau RNG; `langkah` tidak mengubah masukannya. Mobil mundur tegak lurus jalan dari garasi di sisi jalurnya; bentuknya
## persegi di bidang tanah: melintang dari bagasi (`belakang_ubin` dari garis tengah) sepanjang `MOBIL_PANJANG_UBIN` ke arah rumah, sepanjang
## jalan selebar 2 x `MOBIL_SETENGAH_LEBAR_UBIN` di sekitar titik rumah. Koordinat jalan: lateral negatif = `seberang`, maju dari awal rute.
##
## Pola (D-1 run ini, satu pola sederhana yang bisa dipelajari; angka di `Config.MOBIL_*`):
## - `DIAM`: parkir di garasi, bagasi `MOBIL_BELAKANG_AWAL_UBIN` dari garis tengah (di luar jangkauan sepeda di tepi trotoar).
## - `TANDA` (lampu mundur berkedip + bip): sepeda masuk `tanda_ubin` (data segmen) di belakang titik rumah. Mobil belum bergerak.
## - `MUNDUR`: sesudah `MOBIL_TANDA_DETIK` di `TANDA` (waktu, bukan jarak: tanda selalu sama lamanya di semua kecepatan), bagasi mundur
##   `MOBIL_MUNDUR_UD` menuju garis tengah. Sisa waktu langkah yang melewati batas tanda dipakai bergerak (tidak bergantung pembagian `dt`).
## - `BERHENTI`: bagasi sampai `MOBIL_BELAKANG_AKHIR_UBIN` (garis tengah). Mobil tetap di sana, menutup separuh jalan sisinya sampai rute
##   disusun ulang; separuh lain selalu bebas (K-1). Tidak pernah melewati garis tengah.
## Mobil tidak bereaksi pada bel (K-3) dan selalu padat (bentuknya yang menentukan tabrakan).

enum Status { DIAM, TANDA, MUNDUR, BERHENTI }

## Nama animasi di `assets/sprites/obstacles/obs_mobil_garasi_sheet.json` (`anim`) per status.
const ANIMASI: Dictionary = {
	Status.DIAM: "parkir",
	Status.TANDA: "tanda",
	Status.MUNDUR: "mundur",
	Status.BERHENTI: "mundur",
}


## Keadaan satu mobil.
class Keadaan extends RefCounted:
	var status: Status = Status.DIAM
	var sisi: LoperAnim.Sisi = LoperAnim.Sisi.SEBERANG
	## Titik rumah: maju dari awal rute, ubin (pusat mobil sepanjang jalan, tetap).
	var maju_ubin: float = 0.0
	var tanda_ubin: float = 0.0
	## Jarak bagasi dari garis tengah, ubin (positif, menurun saat mundur).
	var belakang_ubin: float = 0.0
	## Lama di status sekarang, detik.
	var detik_status: float = 0.0

	func salin() -> Keadaan:
		var baru: Keadaan = Keadaan.new()
		baru.status = status
		baru.sisi = sisi
		baru.maju_ubin = maju_ubin
		baru.tanda_ubin = tanda_ubin
		baru.belakang_ubin = belakang_ubin
		baru.detik_status = detik_status
		return baru


## Mobil baru parkir di garasi titik rumah `maju_ubin`, jalur `sisi`, jarak tanda `tanda_ubin`.
static func baru(maju_ubin: float, sisi: LoperAnim.Sisi, tanda_ubin: float) -> Keadaan:
	var k: Keadaan = Keadaan.new()
	k.sisi = sisi
	k.maju_ubin = maju_ubin
	k.tanda_ubin = tanda_ubin
	k.belakang_ubin = Config.MOBIL_BELAKANG_AWAL_UBIN
	return k


## Satu langkah `dt` detik dengan sepeda di maju `sepeda_maju`. `dt` nol, negatif, atau tidak hingga = tidak berubah. Masukan tidak diubah.
static func langkah(k: Keadaan, sepeda_maju: float, dt: float) -> Keadaan:
	var s: Keadaan = k.salin()
	if not is_finite(dt) or dt <= 0.0:
		return s
	if s.status == Status.DIAM and is_finite(sepeda_maju) and sepeda_maju >= s.maju_ubin - s.tanda_ubin:
		_ganti(s, Status.TANDA)
	var sisa: float = dt
	if s.status == Status.TANDA:
		var butuh: float = maxf(Config.MOBIL_TANDA_DETIK - s.detik_status, 0.0)
		if sisa + Config.TABRAKAN_TOLERANSI_DETIK < butuh:
			s.detik_status += sisa
			return s
		sisa = maxf(sisa - butuh, 0.0)
		_ganti(s, Status.MUNDUR)
	if s.status == Status.MUNDUR:
		s.detik_status += sisa
		s.belakang_ubin = move_toward(s.belakang_ubin, Config.MOBIL_BELAKANG_AKHIR_UBIN, Config.MOBIL_MUNDUR_UD * sisa)
		if s.belakang_ubin <= Config.MOBIL_BELAKANG_AKHIR_UBIN:
			s.belakang_ubin = Config.MOBIL_BELAKANG_AKHIR_UBIN
			_ganti(s, Status.BERHENTI)
		return s
	s.detik_status += sisa
	return s


## Bentuk tabrakan di bidang tanah, koordinat jalan (x = lateral, y = maju), ubin.
static func kotak(k: Keadaan) -> Rect2:
	var dekat_tengah: float = k.belakang_ubin
	var jauh: float = k.belakang_ubin + Config.MOBIL_PANJANG_UBIN
	var lateral_min: float = dekat_tengah
	var lateral_maks: float = jauh
	if k.sisi == LoperAnim.Sisi.SEBERANG:
		lateral_min = -jauh
		lateral_maks = -dekat_tengah
	var setengah: float = Config.MOBIL_SETENGAH_LEBAR_UBIN
	return Rect2(lateral_min, k.maju_ubin - setengah, lateral_maks - lateral_min, setengah + setengah)


## Mobil selalu padat (bentuknya yang menentukan tabrakan).
static func berbahaya(_k: Keadaan) -> bool:
	return true


## Nama animasi sprite untuk status sekarang (`ANIMASI`).
static func animasi(k: Keadaan) -> String:
	return ANIMASI[k.status]


static func _ganti(s: Keadaan, status: Status) -> void:
	s.status = status
	s.detik_status = 0.0
