class_name SisaKoran
extends RefCounted
## Sisa koran dan jeda antar lemparan, logika murni (BALANCING 4; D-8, D-9, D-11 run fase2a-lemparan).
##
## Keadaan dibuat baru oleh tiap fungsi; masukan tidak diubah. Waktu dan jarak selalu parameter (rule `gdscript`), jadi jeda game
## cukup memberi `dt` 0 (`JedaSim.dt_efektif`): jeda antar lempar dan isi ulang ikut membeku tanpa kode tambahan.
## - Lemparan DITERIMA bila sisa > 0 dan jeda antar lempar sudah lewat: waktu sejak lemparan terakhir diterima >= `LEMPAR_JEDA_DETIK`
##   (inklusif, toleransi `LEMPAR_TOLERANSI_DETIK`; 0,349 ditolak, 0,35 diterima). Diterima = sisa berkurang tepat 1 dan waktu jeda
##   mulai dari 0 (jari dilepas). Ditolak (habis atau masih jeda) = keadaan tidak berubah, koran tidak berkurang.
## - Habis (sisa 0): swipe tidak melempar dan garis bidik tidak tampil (`boleh_lempar` false).
## - Isi ulang khusus jalan uji (`isi_ulang_jalan_uji`, alat uji, bukan aturan game): hanya bila habis, sesudah sepeda menempuh
##   `JALAN_UJI_ISI_ULANG_UBIN` sejak koran habis, sisa kembali penuh.


## Keadaan sisa koran.
class Keadaan extends RefCounted:
	## Koran yang masih bisa dilempar.
	var sisa: int = 0
	## Jumlah penuh (awal rute atau isi ulang).
	var penuh: int = 0
	## Waktu sejak lemparan terakhir diterima, detik. INF = belum pernah melempar.
	var sejak_lempar_detik: float = INF
	## Jarak tempuh sepeda saat koran habis, ubin. NaN = belum habis.
	var habis_di_ubin: float = NAN

	## Salinan bebas.
	func salin() -> Keadaan:
		var baru: Keadaan = Keadaan.new()
		baru.sisa = sisa
		baru.penuh = penuh
		baru.sejak_lempar_detik = sejak_lempar_detik
		baru.habis_di_ubin = habis_di_ubin
		return baru


## Hasil satu percobaan melempar.
class Hasil extends RefCounted:
	## True bila lemparan diterima (koran berkurang 1).
	var diterima: bool = false
	## Keadaan sesudahnya (objek baru).
	var keadaan: Keadaan = null


## Keadaan awal dengan `jumlah` koran (negatif = 0), belum pernah melempar.
static func awal(jumlah: int) -> Keadaan:
	var k: Keadaan = Keadaan.new()
	k.penuh = maxi(jumlah, 0)
	k.sisa = k.penuh
	return k


## True bila jeda antar lempar sudah lewat setelah `sejak_lempar_detik` (inklusif dengan toleransi). NaN dianggap lewat (tidak
## pernah mengunci lemparan).
static func jeda_lewat(sejak_lempar_detik: float) -> bool:
	if is_nan(sejak_lempar_detik):
		return true
	return sejak_lempar_detik + Config.LEMPAR_TOLERANSI_DETIK >= Config.LEMPAR_JEDA_DETIK


## True bila koran habis.
static func habis(keadaan: Keadaan) -> bool:
	return keadaan.sisa <= 0


## True bila swipe sekarang boleh menjadi lemparan (koran ada dan jeda sudah lewat). Garis bidik hanya tampil bila true (D-5).
static func boleh_lempar(keadaan: Keadaan) -> bool:
	return not habis(keadaan) and jeda_lewat(keadaan.sejak_lempar_detik)


## Mencoba menerima satu lemparan saat sepeda sudah menempuh `jarak_ubin` (dicatat bila koran habis karenanya).
static func terima(keadaan: Keadaan, jarak_ubin: float) -> Hasil:
	var hasil: Hasil = Hasil.new()
	var baru: Keadaan = keadaan.salin()
	hasil.keadaan = baru
	if not boleh_lempar(keadaan):
		return hasil
	hasil.diterima = true
	baru.sisa -= 1
	baru.sejak_lempar_detik = 0.0
	if baru.sisa <= 0:
		baru.habis_di_ubin = jarak_ubin if is_finite(jarak_ubin) else 0.0
	return hasil


## Memajukan waktu jeda antar lempar `dt` detik (NaN, tak hingga, negatif, nol = tidak berubah).
static func langkah(keadaan: Keadaan, dt: float) -> Keadaan:
	var baru: Keadaan = keadaan.salin()
	if is_finite(dt) and dt > 0.0:
		baru.sejak_lempar_detik += dt
	return baru


## Alat uji jalan uji (bukan aturan game): bila habis dan sepeda sudah menempuh `JALAN_UJI_ISI_ULANG_UBIN` sejak habis, sisa kembali
## penuh. Selain itu keadaan tidak berubah (salinan).
static func isi_ulang_jalan_uji(keadaan: Keadaan, jarak_ubin: float) -> Keadaan:
	var baru: Keadaan = keadaan.salin()
	if not habis(keadaan) or is_nan(keadaan.habis_di_ubin) or not is_finite(jarak_ubin):
		return baru
	if jarak_ubin - keadaan.habis_di_ubin >= Config.JALAN_UJI_ISI_ULANG_UBIN:
		baru.sisa = baru.penuh
		baru.habis_di_ubin = NAN
	return baru
