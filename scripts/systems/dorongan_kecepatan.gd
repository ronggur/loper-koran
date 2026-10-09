class_name DoronganKecepatan
extends RefCounted
## Dorongan kecepatan: sepeda maju sedikit di bingkai layar saat ngebut dan tertarik mundur saat melambat (GDD 15).
##
## Logika murni. Kecepatan sebenarnya (bukan stick) menentukan geseran target: nol di kecepatan santai, naik linear ke
## `Config.DORONGAN_MAJU_PX` di kecepatan ngebut, turun linear ke `-Config.DORONGAN_MUNDUR_PX` di kecepatan melambat,
## dijepit di luar rentang itu. Geseran SEJAJAR arah jalan di layar: persis kemiringan 2:1 naik ke kanan atas (diturunkan
## dari `Iso`, bukan angka sendiri), jadi sepeda tampak maju atau mundur menyusuri jalan, bukan melayang ke samping.
## Hanya tampilan: posisi dunia dan posisi sprite sepeda tidak berubah, kamera yang bergeser (`JalanUji`). Keadaan geseran
## yang dihaluskan disimpan oleh node, bukan di sini; waktu (`dt`) selalu parameter. Besar geseran adalah usulan awal yang
## disetel di HP; karena sepeda yang maju di layar memperpendek jalan yang terlihat di depan, besarnya sengaja kecil.


## Geseran target sepeda di layar, piksel game, untuk kecepatan maju `kecepatan_ud` (u/d). Nol di kecepatan santai,
## positif (naik ke kanan atas) di atasnya, negatif (turun ke kiri bawah) di bawahnya. NaN dianggap santai.
static func geser_target(kecepatan_ud: float) -> Vector2:
	if is_nan(kecepatan_ud):
		return Vector2.ZERO
	var santai: float = Config.KECEPATAN_SANTAI_UD
	var v: float = clampf(kecepatan_ud, Config.KECEPATAN_MELAMBAT_UD, Config.KECEPATAN_NGEBUT_UD)
	var datar: float = 0.0
	if v >= santai:
		datar = Config.DORONGAN_MAJU_PX * (v - santai) / (Config.KECEPATAN_NGEBUT_UD - santai)
	else:
		datar = -Config.DORONGAN_MUNDUR_PX * (santai - v) / (santai - Config.KECEPATAN_MELAMBAT_UD)
	var arah_jalan: Vector2 = Iso.dunia_ke_layar(Iso.ARAH_MAJU)
	return Vector2(datar, datar * arah_jalan.y / arah_jalan.x)


## Satu langkah penghalusan eksponensial dari geseran `sekarang` ke `target` selama `dt` detik. Bebas framerate
## (dua langkah `dt / 2` sama dengan satu langkah `dt`), tidak pernah melewati target (alpha di antara 0 dan 1),
## dan `dt` sangat besar mendekati target. `dt` nol, negatif, NaN, atau tak hingga: tidak berubah. Geseran awal yang
## bukan bilangan hingga dipulihkan ke target.
static func haluskan(sekarang: Vector2, target: Vector2, dt: float) -> Vector2:
	if not target.is_finite():
		return sekarang if sekarang.is_finite() else Vector2.ZERO
	if not sekarang.is_finite():
		return target
	if not is_finite(dt) or dt <= 0.0:
		return sekarang
	var alpha: float = 1.0 - exp(-dt / Config.DORONGAN_RESPON_DETIK)
	return sekarang.lerp(target, clampf(alpha, 0.0, 1.0))
