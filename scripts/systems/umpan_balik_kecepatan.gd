class_name UmpanBalikKecepatan
extends RefCounted
## Umpan balik kecepatan visual (GDD 15, D-1 run fase1b-umpan-balik): laju debu roda dan kekuatan garis kecepatan, logika murni.
##
## Masukan selalu kecepatan SEBENARNYA (u/d), bukan stick, ditambah status rem dan saklar kurangi efek. Tanpa node, tanpa waktu,
## tanpa RNG: hasil sama untuk masukan sama. Kecepatan NaN, tak hingga, atau negatif dianggap tidak sah dan menghasilkan 0.
## - **Debu roda** (partikel per detik): di bawah `Config.UMPAN_DEBU_AMBANG_UD` (santai 3,0) tidak berdebu; dari ambang (inklusif)
##   naik linear dari `UMPAN_DEBU_LAJU_MIN` ke `UMPAN_DEBU_LAJU_MAKS` di `UMPAN_DEBU_PENUH_UD` (ngebut 6,0), dijepit di atasnya.
##   Selama rem aktif dan kecepatan > 0 laju = `UMPAN_DEBU_REM_LAJU` (debu rem, laju tersendiri); kecepatan 0 = tanpa debu.
## - **Garis kecepatan** (kekuatan 0..1): 0 di bawah `UMPAN_GARIS_AMBANG_UD` (cepat 4,5); dari ambang (inklusif) naik linear dari
##   `UMPAN_GARIS_KEKUATAN_MIN` ke 1 di `UMPAN_GARIS_PENUH_UD` (ngebut 6,0), dijepit. Laju pancar garis = kekuatan x
##   `UMPAN_GARIS_LAJU_MAKS`.
## - **Kurangi efek** (rule `ui-scenes`): garis mati (0) dan laju debu dikali `UMPAN_KURANGI_DEBU_PENGALI`.


## Laju pancar debu roda, partikel per detik, dari kecepatan sebenarnya `kecepatan_ud`, status `rem_aktif`, dan `kurangi_efek`.
static func laju_debu(kecepatan_ud: float, rem_aktif: bool, kurangi_efek: bool) -> float:
	if not is_finite(kecepatan_ud) or kecepatan_ud <= 0.0:
		return 0.0
	var laju: float = 0.0
	if rem_aktif:
		laju = Config.UMPAN_DEBU_REM_LAJU
	elif kecepatan_ud >= Config.UMPAN_DEBU_AMBANG_UD:
		var t: float = _pecahan(kecepatan_ud, Config.UMPAN_DEBU_AMBANG_UD, Config.UMPAN_DEBU_PENUH_UD)
		laju = lerpf(Config.UMPAN_DEBU_LAJU_MIN, Config.UMPAN_DEBU_LAJU_MAKS, t)
	if kurangi_efek:
		laju *= Config.UMPAN_KURANGI_DEBU_PENGALI
	return laju


## Kekuatan garis kecepatan, 0 sampai 1, dari kecepatan sebenarnya `kecepatan_ud`. 0 bila `kurangi_efek`.
static func kekuatan_garis(kecepatan_ud: float, kurangi_efek: bool) -> float:
	if kurangi_efek or not is_finite(kecepatan_ud) or kecepatan_ud < Config.UMPAN_GARIS_AMBANG_UD:
		return 0.0
	var t: float = _pecahan(kecepatan_ud, Config.UMPAN_GARIS_AMBANG_UD, Config.UMPAN_GARIS_PENUH_UD)
	return lerpf(Config.UMPAN_GARIS_KEKUATAN_MIN, 1.0, t)


## Laju pancar garis kecepatan, garis per detik (kekuatan x `Config.UMPAN_GARIS_LAJU_MAKS`).
static func laju_garis(kecepatan_ud: float, kurangi_efek: bool) -> float:
	return kekuatan_garis(kecepatan_ud, kurangi_efek) * Config.UMPAN_GARIS_LAJU_MAKS


## Posisi `nilai` di antara `awal` dan `akhir` sebagai pecahan 0..1, dijepit.
static func _pecahan(nilai: float, awal: float, akhir: float) -> float:
	return clampf((nilai - awal) / (akhir - awal), 0.0, 1.0)
