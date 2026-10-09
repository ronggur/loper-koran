class_name LoperAnim
extends RefCounted
## Pemilih animasi sprite pemain, logika murni tanpa node (BALANCING 2, ART_DIRECTION 3.2).
##
## Nama animasi di `loper_agen_frames.tres` berbentuk `<tingkat>_<arah>`:
## - tingkat 0 = santai, 1 = cepat, 2 = ngebut;
## - arah -2 = kiri (90 derajat), -1 = serong_kiri, 0 = normal, 1 = serong_kanan, 2 = kanan.
##
## Catatan nama: `kiri` / `kanan` di nama animasi berasal dari sprite aset yang dikunci
## (ART_DIRECTION 3.2) dan mengikuti arah pelempar, bukan arah layar: kanan (positif) =
## sisi `dekat`, kiri (negatif) = sisi `seberang` (GDD 4.2). Di luar nama animasi, kode
## memakai `seberang` / `dekat`. Ambang dan sudut dibaca dari `Config`.

const NAMA_TINGKAT: Array[String] = ["santai", "cepat", "ngebut"]
const NAMA_ARAH: Dictionary = {
	-2: "kiri",
	-1: "serong_kiri",
	0: "normal",
	1: "serong_kanan",
	2: "kanan",
}


## Tingkat sprite dari kekuatan stick ke atas. `kekuatan` dijepit ke 0 sampai 1.
## Kurang dari `SPRITE_AMBANG_CEPAT` = 0 (santai); sampai `SPRITE_AMBANG_NGEBUT` inklusif
## = 1 (cepat); di atasnya = 2 (ngebut). Stick ke bawah (negatif) = santai. NaN = santai.
static func tingkat_dari_stick(kekuatan: float) -> int:
	if is_nan(kekuatan):
		return 0
	var k: float = clampf(kekuatan, 0.0, 1.0)
	if k < Config.SPRITE_AMBANG_CEPAT:
		return 0
	if k <= Config.SPRITE_AMBANG_NGEBUT:
		return 1
	return 2


## Besar arah sprite (0, 1, atau 2) dari sudut gerak terhadap arah jalan, derajat.
## Kurang dari `SPRITE_SUDUT_SERONG_DERAJAT` = 0 (normal); sampai `SPRITE_SUDUT_SIKU_DERAJAT`
## inklusif = 1 (serong); di atasnya = 2 (90 derajat). Batas bersifat inklusif dengan
## toleransi `SPRITE_SUDUT_TOLERANSI_DERAJAT` supaya derau desimal tidak membalik hasil.
static func besar_arah_dari_sudut(sudut_derajat: float) -> int:
	var sudut: float = absf(sudut_derajat)
	if sudut < Config.SPRITE_SUDUT_SERONG_DERAJAT - Config.SPRITE_SUDUT_TOLERANSI_DERAJAT:
		return 0
	if sudut <= Config.SPRITE_SUDUT_SIKU_DERAJAT + Config.SPRITE_SUDUT_TOLERANSI_DERAJAT:
		return 1
	return 2


## Arah sprite bertanda (-2 sampai 2) dari gerak sebenarnya, bukan dari stick (BALANCING 2).
## `maju` = komponen searah jalan (positif = maju), `lateral` = komponen melintang jalan
## (positif = ke sisi `dekat`, negatif = ke sisi `seberang`), satuan bebas (mis. u/d).
## Aturan yang ditetapkan:
## - sudut = sudut antara vektor gerak dan arah jalan, 0 sampai 180 derajat;
## - tanda hasil mengikuti tanda `lateral`;
## - lateral nol (termasuk vektor nol): 0, sprite tampil normal. Ini juga berlaku untuk mundur
##   murni, karena tanda tidak bisa ditentukan dan sprite tidak punya animasi mundur;
## - gerak mundur (maju negatif) dengan lateral: sudutnya lebih dari 90 derajat, jadi hasilnya
##   +-2 sesuai tanda lateral.
static func arah_dari_gerak(maju: float, lateral: float) -> int:
	if is_nan(maju) or is_nan(lateral):
		return 0
	if is_zero_approx(lateral):
		return 0
	var sudut: float = rad_to_deg(atan2(absf(lateral), maju))
	var besar: int = besar_arah_dari_sudut(sudut)
	return besar if lateral > 0.0 else -besar


## Jepit tingkat ke 0 sampai 2.
static func jepit_tingkat(tingkat: int) -> int:
	return clampi(tingkat, 0, NAMA_TINGKAT.size() - 1)


## Jepit arah ke -2 sampai 2.
static func jepit_arah(arah: int) -> int:
	return clampi(arah, -2, 2)


## Nama animasi di SpriteFrames untuk tingkat dan arah (keduanya dijepit ke jangkauannya).
static func nama_animasi(tingkat: int, arah: int) -> StringName:
	var nama_tingkat: String = NAMA_TINGKAT[jepit_tingkat(tingkat)]
	var nama_arah: String = NAMA_ARAH[jepit_arah(arah)]
	return StringName("%s_%s" % [nama_tingkat, nama_arah])


## Pengali kecepatan putar animasi dari laju kayuh. Tidak pernah negatif (animasi tidak
## diputar mundur) dan NaN dianggap 0.
static func skala_kayuh(laju_kayuh: float) -> float:
	if is_nan(laju_kayuh):
		return 0.0
	return maxf(laju_kayuh, 0.0)
