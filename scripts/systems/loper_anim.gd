class_name LoperAnim
extends RefCounted
## Pemilih animasi sprite pemain, logika murni tanpa node (BALANCING 2, ART_DIRECTION 3.2).
##
## Nama animasi di `loper_agen_frames.tres` (38 animasi, dibangun `tools/loper_art/bangun_frames.py`):
## - kayuh `<tingkat>_<arah>` (15): tingkat 0 = santai, 1 = cepat, 2 = ngebut;
## - melambat `melambat_<arah>` (5): tingkat -1 (`TINGKAT_MELAMBAT`), kayuh 4 fps, gambarnya sama dengan santai;
## - lempar `lempar_<sisi>_<kecepatan>_<arah>` (18): sekali putar 12 fps, kecepatan santai/cepat/ngebut, arah normal dan dua serong;
## - arah -2 = kiri (90 derajat), -1 = serong_kiri, 0 = normal, 1 = serong_kanan, 2 = kanan.
##
## Catatan nama: `kiri` / `kanan` di nama animasi berasal dari sprite aset yang dikunci
## (ART_DIRECTION 3.2) dan mengikuti arah pelempar, bukan arah layar: kanan (positif) =
## sisi `dekat`, kiri (negatif) = sisi `seberang` (GDD 4.2). Di luar nama animasi, kode
## memakai `seberang` / `dekat`; kata itu hanya boleh muncul di blok `const NAMA_ARAH` dan
## `const NAMA_SISI_LEMPAR` (penjaga di `tests/run_tests.gd`). Ambang dan sudut dibaca dari `Config`.

## Sisi lempar. `TIDAK_ADA` = tidak ada lemparan (swipe tidak sah). Swipe ke kiri layar = `SEBERANG`, ke kanan layar = `DEKAT` (GDD 5.2).
enum Sisi { TIDAK_ADA, SEBERANG, DEKAT }

## Tingkat sprite di bawah santai (stick ditarik ke bawah): animasi `melambat_<arah>` (D-1 run sprite-lempar-melambat).
const TINGKAT_MELAMBAT: int = -1
const NAMA_MELAMBAT: String = "melambat"
const NAMA_TINGKAT: Array[String] = ["santai", "cepat", "ngebut"]
const NAMA_ARAH: Dictionary = {
	-2: "kiri",
	-1: "serong_kiri",
	0: "normal",
	1: "serong_kanan",
	2: "kanan",
}
## Nama sisi di animasi lempar (aset yang dikunci): seberang = kiri pelempar, dekat = kanan pelempar.
const NAMA_SISI_LEMPAR: Dictionary = {
	Sisi.SEBERANG: "kiri",
	Sisi.DEKAT: "kanan",
}


## Tingkat sprite dari kekuatan stick ke atas, SESUDAH zona mati (`StickMap` sudah menolkan 15% pertama).
## Negatif (stick ditarik ke bawah, komponen maju di bawah nol) = `TINGKAT_MELAMBAT` (-1). Nol sampai di bawah
## `SPRITE_AMBANG_CEPAT` = 0 (santai); sampai `SPRITE_AMBANG_NGEBUT` inklusif = 1 (cepat); di atasnya = 2 (ngebut).
## `kekuatan` ke atas dijepit ke 1. NaN = santai. Stick netral atau naik tidak pernah melambat (D-1).
static func tingkat_dari_stick(kekuatan: float) -> int:
	if is_nan(kekuatan):
		return 0
	if kekuatan < 0.0:
		return TINGKAT_MELAMBAT
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


## Jepit tingkat ke -1 (melambat) sampai 2 (ngebut).
static func jepit_tingkat(tingkat: int) -> int:
	return clampi(tingkat, TINGKAT_MELAMBAT, NAMA_TINGKAT.size() - 1)


## Jepit arah ke -2 sampai 2.
static func jepit_arah(arah: int) -> int:
	return clampi(arah, -2, 2)


## Nama animasi kayuh di SpriteFrames untuk tingkat dan arah (keduanya dijepit ke jangkauannya).
## Tingkat -1 memilih `melambat_<arah>`.
static func nama_animasi(tingkat: int, arah: int) -> StringName:
	var nama_arah: String = NAMA_ARAH[jepit_arah(arah)]
	var jepitan: int = jepit_tingkat(tingkat)
	if jepitan == TINGKAT_MELAMBAT:
		return StringName("%s_%s" % [NAMA_MELAMBAT, nama_arah])
	return StringName("%s_%s" % [NAMA_TINGKAT[jepitan], nama_arah])


## Tingkat yang dipakai animasi lempar: tidak ada lempar melambat, jadi melambat memakai santai (D-3).
static func tingkat_untuk_lempar(tingkat: int) -> int:
	return maxi(jepit_tingkat(tingkat), 0)


## Arah yang dipakai animasi lempar: arah 90 derajat belum punya gambar, jadi jatuh ke serong di sisi yang sama (D-3).
static func arah_untuk_lempar(arah: int) -> int:
	return clampi(jepit_arah(arah), -1, 1)


## Nama animasi lempar `lempar_<sisi>_<kecepatan>_<arah>` untuk sisi lempar, tingkat sprite, dan arah sprite saat ini (D-3).
## Tingkat melambat memakai santai, arah 90 derajat memakai serong di sisi yang sama. `Sisi.TIDAK_ADA` = nama kosong.
static func nama_lempar(sisi: Sisi, tingkat: int, arah: int) -> StringName:
	if not NAMA_SISI_LEMPAR.has(sisi):
		return &""
	var nama_tingkat: String = NAMA_TINGKAT[tingkat_untuk_lempar(tingkat)]
	var nama_arah: String = NAMA_ARAH[arah_untuk_lempar(arah)]
	return StringName("lempar_%s_%s_%s" % [NAMA_SISI_LEMPAR[sisi], nama_tingkat, nama_arah])


## Sisi lempar dari satu swipe: titik awal dan akhir dalam piksel game (GDD 5.2, D-2 run sprite-lempar-melambat).
## Swipe ke kiri layar = `SEBERANG`, ke kanan layar = `DEKAT`, tidak bergantung opsi kidal (kidal hanya menukar zona).
## Tidak melempar (`TIDAK_ADA`) bila: titik tidak hingga atau NaN; panjang swipe kurang dari `LEMPAR_SWIPE_AMBANG_PX`
## (tepat di ambang melempar); atau gerak tegak sama besar atau lebih besar dari gerak datar (vertikal dominan, 45 derajat
## tepat dianggap ambigu dan tidak melempar).
static func sisi_dari_swipe(awal: Vector2, akhir: Vector2) -> Sisi:
	if not awal.is_finite() or not akhir.is_finite():
		return Sisi.TIDAK_ADA
	var geser: Vector2 = akhir - awal
	if geser.length() < Config.LEMPAR_SWIPE_AMBANG_PX:
		return Sisi.TIDAK_ADA
	if absf(geser.x) <= absf(geser.y):
		return Sisi.TIDAK_ADA
	return Sisi.SEBERANG if geser.x < 0.0 else Sisi.DEKAT


## Pengali kecepatan putar animasi dari laju kayuh. Tidak pernah negatif (animasi tidak
## diputar mundur) dan NaN dianggap 0.
static func skala_kayuh(laju_kayuh: float) -> float:
	if is_nan(laju_kayuh):
		return 0.0
	return maxf(laju_kayuh, 0.0)
