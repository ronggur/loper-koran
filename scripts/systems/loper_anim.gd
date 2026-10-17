class_name LoperAnim
extends RefCounted
## Pemilih animasi sprite pemain, logika murni tanpa node (BALANCING 2, ART_DIRECTION 3.2).
##
## Nama animasi di `loper_agen_frames.tres` (50 animasi, dibangun `tools/loper_art/bangun_frames.py`):
## - kayuh `<tingkat>_<arah>` (15): tingkat 0 = santai, 1 = cepat, 2 = ngebut;
## - melambat `melambat_<arah>` (5): tingkat -1 (`TINGKAT_MELAMBAT`), kayuh 4 fps, gambarnya sama dengan santai;
## - lempar `lempar_<sisi>_<kecepatan>_<arah>` (18): sekali putar 12 fps, kecepatan santai/cepat/ngebut, arah normal dan dua serong;
## - meluncur `meluncur_<arah>` (5): pose `Pose.MELUNCUR`, kaki diam, 4 fps berulang (napas);
## - rem `rem_<arah>` (5): pose `Pose.REM`, kaki diam, badan mundur, 8 fps berulang (getar);
## - jatuh (2, sejak 2026-10-17, keputusan pemilik: tabrakan = jatuh): `jatuh_normal` (4 frame, 10 fps, sekali) lalu
##   `terjerembab_normal` (2 frame, 3 fps, berulang). Baru arah `normal` yang punya gambar, jadi semua arah memakai `normal`
##   (`ARAH_JATUH`); empat arah lain dan animasi bangkit adalah pekerjaan aset Fase 5 (ART_DIRECTION 3.4);
## - arah -2 = kiri (90 derajat), -1 = serong_kiri, 0 = normal, 1 = serong_kanan, 2 = kanan.
##
## Pemilihan pose dari keadaan gerak (D-7 run fase1a-gerak, keputusan pemilik 2026-10-13 "ikuti fisika") dan laju kayuh
## (D-8) juga ada di sini, supaya node (`LoperSprite`, `SepedaUji`) hanya menampilkan.
##
## Catatan nama: `kiri` / `kanan` di nama animasi berasal dari sprite aset yang dikunci
## (ART_DIRECTION 3.2) dan mengikuti arah pelempar, bukan arah layar: kanan (positif) =
## sisi `dekat`, kiri (negatif) = sisi `seberang` (GDD 4.2). Di luar nama animasi, kode
## memakai `seberang` / `dekat`; kata itu hanya boleh muncul di blok `const NAMA_ARAH` dan
## `const NAMA_SISI_LEMPAR` (penjaga di `tests/run_tests.gd`). Ambang dan sudut dibaca dari `Config`.

## Sisi lempar. `TIDAK_ADA` = tidak ada lemparan (swipe tidak sah). Sejak run fase2-arah-bebas arah lemparan bebas (GDD 5.2): sisi
## diambil dari komponen melintang arah tanah swipe (`ThrowSolver.sisi_dari_arah` / `sisi_dari_swipe`; ke seberang = `SEBERANG`,
## ke dekat atau tepat searah jalan = `DEKAT`) dan hanya memilih animasi lempar; penilaian zona dari titik mendarat saja.
enum Sisi { TIDAK_ADA, SEBERANG, DEKAT }
## Pose sprite. `KAYUH` memakai tingkat (`<tingkat>_<arah>` atau `melambat_<arah>` untuk tingkat -1); `MELUNCUR` dan `REM`
## memakai `meluncur_<arah>` dan `rem_<arah>` tanpa tingkat (kaki tidak mengayuh).
enum Pose { KAYUH, MELUNCUR, REM }

## Tingkat sprite di bawah santai (stick ditarik ke bawah): animasi `melambat_<arah>` (D-1 run sprite-lempar-melambat).
const TINGKAT_MELAMBAT: int = -1
const NAMA_MELAMBAT: String = "melambat"
const NAMA_TINGKAT: Array[String] = ["santai", "cepat", "ngebut"]
## Awalan nama animasi untuk pose tanpa kayuh.
const NAMA_POSE: Dictionary = {
	Pose.MELUNCUR: "meluncur",
	Pose.REM: "rem",
}
## Awalan nama animasi jatuh (sekali putar) dan terjerembab (berulang sesudahnya).
const NAMA_JATUH: String = "jatuh"
const NAMA_TERJEREMBAB: String = "terjerembab"
## Satu-satunya arah yang punya gambar jatuh dan terjerembab (0 = `normal`); dipakai untuk semua arah sampai aset Fase 5 ada.
const ARAH_JATUH: int = 0
## Tingkat tertinggi selama lelah (stamina habis, BALANCING 3): cepat.
const TINGKAT_CEPAT: int = 1
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


## Nama animasi jatuh untuk `arah`. Arah diabaikan: semua arah memakai `jatuh_normal` (`ARAH_JATUH`, aset arah lain belum ada).
static func nama_jatuh(_arah: int) -> StringName:
	return StringName("%s_%s" % [NAMA_JATUH, NAMA_ARAH[ARAH_JATUH]])


## Nama animasi terjerembab untuk `arah`. Arah diabaikan: semua arah memakai `terjerembab_normal` (`ARAH_JATUH`).
static func nama_terjerembab(_arah: int) -> StringName:
	return StringName("%s_%s" % [NAMA_TERJEREMBAB, NAMA_ARAH[ARAH_JATUH]])


## Frame sprite jatuh pada satu saat: nama animasi, indeks frame, dan progres di dalam frame (0..1).
class FrameJatuh extends RefCounted:
	var nama: StringName = &""
	var frame: int = 0
	var progres: float = 0.0


## Frame sprite `lewat_detik` sesudah tabrakan (keputusan pemilik 2026-10-17): `jatuh_<arah>` diputar sekali (`n_jatuh` frame pada
## `fps_jatuh`), lalu `terjerembab_<arah>` berulang (`n_terjerembab` frame pada `fps_terjerembab`) sampai pemain bangun. Arah diabaikan
## (`nama_jatuh`). Batas inklusif dengan toleransi `TABRAKAN_TOLERANSI_DETIK`: tepat `n_jatuh / fps_jatuh` detik = frame 0 terjerembab.
## `lewat_detik` NaN atau negatif = 0; fps atau jumlah frame tidak sah = frame 0 animasi jatuh (aman, tanpa bagi nol).
static func frame_jatuh(lewat_detik: float, arah: int, fps_jatuh: float, n_jatuh: int, fps_terjerembab: float, n_terjerembab: int) -> FrameJatuh:
	var f: FrameJatuh = FrameJatuh.new()
	f.nama = nama_jatuh(arah)
	if not (fps_jatuh > 0.0 and n_jatuh > 0 and fps_terjerembab > 0.0 and n_terjerembab > 0):
		return f
	var t: float = lewat_detik if is_finite(lewat_detik) and lewat_detik > 0.0 else 0.0
	var lama_jatuh: float = float(n_jatuh) / fps_jatuh
	var posisi: float = 0.0
	if t + Config.TABRAKAN_TOLERANSI_DETIK < lama_jatuh:
		posisi = t * fps_jatuh
		f.frame = mini(floori(posisi + Config.TABRAKAN_TOLERANSI_DETIK), n_jatuh - 1)
	else:
		f.nama = nama_terjerembab(arah)
		posisi = maxf(t - lama_jatuh, 0.0) * fps_terjerembab
		f.frame = posmod(floori(posisi + Config.TABRAKAN_TOLERANSI_DETIK), n_terjerembab)
	f.progres = clampf(posisi - floorf(posisi + Config.TABRAKAN_TOLERANSI_DETIK), 0.0, 1.0)
	return f


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


## Pose sprite dari keadaan gerak (D-7), urutan prioritas:
## 1. `rem_aktif` -> `REM` (juga saat sudah berhenti di kecepatan 0);
## 2. stick ke bawah (`stick_maju` < 0 sesudah zona mati) dan kecepatan sebenarnya masih di atas `tujuan_ud` lebih dari
##    `Config.POSE_MELUNCUR_TOLERANSI_UD` -> `MELUNCUR` (sedang turun tanpa mengayuh);
## 3. selain itu `KAYUH` (stick ke bawah yang sudah sampai tujuan = tingkat melambat, lihat `tingkat_sprite`).
## NaN pada kecepatan atau tujuan dianggap sudah sampai (tidak meluncur).
static func pose_dari_gerak(rem_aktif: bool, stick_maju: float, kecepatan_ud: float, tujuan_ud: float) -> Pose:
	if rem_aktif:
		return Pose.REM
	if is_nan(stick_maju) or stick_maju >= 0.0:
		return Pose.KAYUH
	if is_nan(kecepatan_ud) or is_nan(tujuan_ud):
		return Pose.KAYUH
	if kecepatan_ud - tujuan_ud > Config.POSE_MELUNCUR_TOLERANSI_UD:
		return Pose.MELUNCUR
	return Pose.KAYUH


## Tingkat sprite dari komponen maju stick (`tingkat_dari_stick`), dijepit ke cepat (`TINGKAT_CEPAT`) selama `lelah` (D-7, BALANCING 3).
static func tingkat_sprite(stick_maju: float, lelah: bool) -> int:
	var tingkat: int = tingkat_dari_stick(stick_maju)
	if lelah:
		return mini(tingkat, TINGKAT_CEPAT)
	return tingkat


## Nama animasi untuk pose, tingkat, dan arah. `KAYUH` = `nama_animasi(tingkat, arah)`; `MELUNCUR` dan `REM` =
## `<pose>_<arah>` (tingkat diabaikan). Arah dijepit ke -2..2. Pose di luar enum dianggap `KAYUH`.
static func nama_animasi_pose(pose: Pose, tingkat: int, arah: int) -> StringName:
	if not NAMA_POSE.has(pose):
		return nama_animasi(tingkat, arah)
	return StringName("%s_%s" % [NAMA_POSE[pose], NAMA_ARAH[jepit_arah(arah)]])


## Tingkat lempar untuk pose: dari meluncur dan rem memakai santai (tidak ada gambar lempar khusus, D-7); dari kayuh
## sama dengan `tingkat_untuk_lempar` (melambat juga santai).
static func tingkat_lempar(pose: Pose, tingkat: int) -> int:
	if NAMA_POSE.has(pose):
		return 0
	return tingkat_untuk_lempar(tingkat)


## Kecepatan nominal animasi kayuh untuk tingkat (dijepit ke -1..2), u/d: melambat 1,5, santai 3,0, cepat 4,5, ngebut 6,0.
static func kecepatan_nominal_ud(tingkat: int) -> float:
	match jepit_tingkat(tingkat):
		TINGKAT_MELAMBAT:
			return Config.KECEPATAN_MELAMBAT_UD
		0:
			return Config.KECEPATAN_SANTAI_UD
		TINGKAT_CEPAT:
			return Config.KECEPATAN_CEPAT_UD
	return Config.KECEPATAN_NGEBUT_UD


## Laju kayuh (D-8): untuk `KAYUH` = kecepatan sebenarnya / kecepatan nominal tingkat animasi, dijepit ke
## [0, `Config.PEDAL_RATE_MAKS`]; NaN atau negatif = 0. `MELUNCUR` dan `REM` tidak dikayuh: 1 (animasinya napas dan getar,
## fps dari `.tres`). Lempar tidak memakai nilai ini (waktunya dari `LemparWaktu`).
static func pedal_rate(pose: Pose, tingkat: int, kecepatan_ud: float) -> float:
	if NAMA_POSE.has(pose):
		return 1.0
	if is_nan(kecepatan_ud):
		return 0.0
	return clampf(kecepatan_ud / kecepatan_nominal_ud(tingkat), 0.0, Config.PEDAL_RATE_MAKS)


## Pengali kecepatan putar animasi dari laju kayuh. Tidak pernah negatif (animasi tidak
## diputar mundur) dan NaN dianggap 0.
static func skala_kayuh(laju_kayuh: float) -> float:
	if is_nan(laju_kayuh):
		return 0.0
	return maxf(laju_kayuh, 0.0)
