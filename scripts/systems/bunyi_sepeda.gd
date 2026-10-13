class_name BunyiSepeda
extends RefCounted
## Keputusan bunyi sepeda (SOUND_DESIGN 3.2, D-3 run fase1b-umpan-balik), logika murni. Dipakai autoload `Audio`.
##
## Masukan selalu keadaan SEBENARNYA dari `BikeMotion` (pose sprite, kecepatan, rem aktif) ditambah status jeda; tanpa node,
## tanpa waktu, tanpa RNG. Tiga keputusan:
## - **Loop aktif** (`loop_aktif`): jeda = diam; rem aktif = diam (bunyi rem sekali, lalu diam); kecepatan 0 (atau tidak sah) = diam;
##   pose `MELUNCUR` = loop freewheel; selain itu (kayuh dan melambat) = loop kayuhan.
## - **Pitch kayuhan** (`pitch_kayuh`): linear per potong dari kecepatan sebenarnya, santai 3,0 -> `Config.AUDIO_KAYUH_PITCH_SANTAI`
##   (1,0), cepat 4,5 -> `AUDIO_KAYUH_PITCH_CEPAT` (1,15), ngebut 6,0 -> `AUDIO_KAYUH_PITCH_NGEBUT` (1,3); dijepit di luar rentang
##   (melambat tetap 1,0). NaN = pitch santai.
## - **Pemicu rem** (`rem_dipicu`): hanya di **tepi naik** rem aktif (sebelumnya padam, sekarang aktif), tidak diulang selama rem
##   ditahan, dan dipicu lagi sesudah rem padam lalu aktif lagi. Tidak dipicu selama jeda (tidak ada bunyi rem tertunda yang menyusul
##   sesudah lanjut, D-5) dan tidak dipicu di kecepatan 0 (tidak ada roda yang berdecit; sama dengan debu rem, `UmpanBalikKecepatan`).
##   Pemanggil menyimpan status rem langkah sebelumnya, juga selama jeda.

## Loop bunyi sepeda yang berbunyi.
enum Loop { DIAM, KAYUH, FREEWHEEL }


## Loop yang aktif untuk `pose` (`LoperAnim.Pose`), kecepatan sebenarnya `kecepatan_ud`, `rem_aktif`, dan `jeda`.
static func loop_aktif(pose: LoperAnim.Pose, kecepatan_ud: float, rem_aktif: bool, jeda: bool) -> Loop:
	if jeda or rem_aktif or pose == LoperAnim.Pose.REM:
		return Loop.DIAM
	if not is_finite(kecepatan_ud) or kecepatan_ud <= 0.0:
		return Loop.DIAM
	if pose == LoperAnim.Pose.MELUNCUR:
		return Loop.FREEWHEEL
	return Loop.KAYUH


## `pitch_scale` loop kayuhan dari kecepatan sebenarnya `kecepatan_ud`, linear per potong, dijepit ke pitch santai..ngebut.
static func pitch_kayuh(kecepatan_ud: float) -> float:
	if is_nan(kecepatan_ud) or kecepatan_ud <= Config.KECEPATAN_SANTAI_UD:
		return Config.AUDIO_KAYUH_PITCH_SANTAI
	if kecepatan_ud <= Config.KECEPATAN_CEPAT_UD:
		var t: float = (kecepatan_ud - Config.KECEPATAN_SANTAI_UD) / (Config.KECEPATAN_CEPAT_UD - Config.KECEPATAN_SANTAI_UD)
		return lerpf(Config.AUDIO_KAYUH_PITCH_SANTAI, Config.AUDIO_KAYUH_PITCH_CEPAT, t)
	if kecepatan_ud < Config.KECEPATAN_NGEBUT_UD:
		var u: float = (kecepatan_ud - Config.KECEPATAN_CEPAT_UD) / (Config.KECEPATAN_NGEBUT_UD - Config.KECEPATAN_CEPAT_UD)
		return lerpf(Config.AUDIO_KAYUH_PITCH_CEPAT, Config.AUDIO_KAYUH_PITCH_NGEBUT, u)
	return Config.AUDIO_KAYUH_PITCH_NGEBUT


## True bila bunyi rem sekali putar dimainkan pada langkah ini: rem baru menyala (`rem_sebelum` padam, `rem_sekarang` aktif),
## kecepatan sebenarnya masih di atas 0, dan tidak sedang jeda.
static func rem_dipicu(rem_sebelum: bool, rem_sekarang: bool, kecepatan_ud: float, jeda: bool) -> bool:
	if jeda or rem_sebelum or not rem_sekarang:
		return false
	return is_finite(kecepatan_ud) and kecepatan_ud > 0.0
