extends Node
## Autoload `Audio` (TECH_PLAN 3.1, SOUND_DESIGN 3.2 dan 6; D-3 dan D-5 run fase1b-umpan-balik): bunyi sepeda placeholder.
##
## Tiga pemutar di bus `Sepeda` (`default_bus_layout.tres`: `Sepeda` -> `SFX` -> `Master`): loop kayuhan (pitch mengikuti
## kecepatan), loop freewheel (meluncur), dan decit rem sekali putar. Keputusan ada di `BunyiSepeda` (logika murni); node ini
## hanya menyalakan, mematikan, dan mengatur pitch pemutar.
##
## **Tidak merujuk autoload lain** (rule `gdscript`): semua data datang dari pemanggil sebagai argumen. Pemilik sepeda (`JalanUji`)
## memanggil `perbarui_sepeda` tiap langkah, menyambungkan sinyal `jeda_berubah` ke `atur_jeda`, dan memanggil `hentikan_sepeda`
## saat keluar dari pohon.
##
## Jeda (D-5): node ini `PROCESS_MODE_ALWAYS`, jadi pemutar TIDAK ikut di-pause otomatis oleh `SceneTree.paused` (yang akan
## melanjutkan decit rem lama saat pohon lanjut). Saat jeda semua pemutar dihentikan (`stop`), termasuk decit rem yang sedang
## berbunyi; sesudah lanjut bunyi kembali dari keadaan sekarang pada `perbarui_sepeda` berikutnya, tanpa decit rem lama. App
## di-background atau kehilangan fokus juga menghentikan semua bunyi sepeda di sini (rule `gdscript`), walau tanpa `JalanUji`.
## Pemutar dibuat di `_init`, jadi `load(...).new()` tanpa scene tree (tes) aman: keputusan tetap dihitung, tidak ada yang diputar.
##
## Driver audio `Dummy` (`--headless`, CI) tidak punya keluaran suara, jadi di sana stream tidak diputar (keputusan tetap dihitung)
## kecuali `putar_di_driver_dummy` dinyalakan (tes). Alasannya: playback yang masih aktif saat Godot keluar paksa (`--quit-after`)
## tidak sempat dilepas AudioServer dan tercetak sebagai `ObjectDB instances were leaked` dan `resources still in use` (diuji
## 2026-10-14: AudioServer baru melepas playback yang dihentikan sesudah driver mencampur lagi). Tes yang menyalakannya wajib
## menghentikan bunyi dan menunggu sebentar (runner: 0,25 detik) sebelum `quit()`.

const BUS_SEPEDA: StringName = &"Sepeda"
const BERKAS_KAYUH: String = "res://assets/audio/sfx/bike/sfx_bike_pedal_loop.wav"
const BERKAS_FREEWHEEL: String = "res://assets/audio/sfx/bike/sfx_bike_freewheel_loop.wav"
const BERKAS_REM: String = "res://assets/audio/sfx/bike/sfx_bike_brake_01.wav"
## Nama driver audio tanpa keluaran suara (`AudioServer.get_driver_name()` saat `--headless`).
const DRIVER_DUMMY: String = "Dummy"

## True: stream tetap diputar walau driver audio `Dummy` (hanya untuk tes headless; lihat penjelasan di atas).
var putar_di_driver_dummy: bool = false

var _kayuh: AudioStreamPlayer
var _freewheel: AudioStreamPlayer
var _rem: AudioStreamPlayer
var _loop: BunyiSepeda.Loop = BunyiSepeda.Loop.DIAM
var _pitch: float = Config.AUDIO_KAYUH_PITCH_SANTAI
var _rem_sebelum: bool = false
var _jeda: bool = false
var _jumlah_rem: int = 0


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_kayuh = _buat_pemutar(&"PemutarKayuh", BERKAS_KAYUH, Config.AUDIO_KAYUH_VOLUME_DB)
	_freewheel = _buat_pemutar(&"PemutarFreewheel", BERKAS_FREEWHEEL, Config.AUDIO_FREEWHEEL_VOLUME_DB)
	_rem = _buat_pemutar(&"PemutarRem", BERKAS_REM, Config.AUDIO_REM_VOLUME_DB)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_CLOSE_REQUEST:
		_hentikan_pemutar()


## Satu langkah bunyi sepeda dari keadaan sebenarnya: `pose` (`LoperAnim.Pose`), `kecepatan_ud`, `rem_aktif`, dan `jeda`.
## Decit rem dimainkan hanya di tepi naik rem (`BunyiSepeda.rem_dipicu`); status rem selalu dicatat, juga selama jeda.
func perbarui_sepeda(pose: LoperAnim.Pose, kecepatan_ud: float, rem_aktif: bool, jeda: bool) -> void:
	var picu: bool = BunyiSepeda.rem_dipicu(_rem_sebelum, rem_aktif, kecepatan_ud, jeda)
	_rem_sebelum = rem_aktif
	_jeda = jeda
	_loop = BunyiSepeda.loop_aktif(pose, kecepatan_ud, rem_aktif, jeda)
	_pitch = BunyiSepeda.pitch_kayuh(kecepatan_ud)
	if picu:
		_jumlah_rem += 1
	if not _boleh_putar():
		return
	_kayuh.pitch_scale = _pitch
	_atur_putar(_kayuh, _loop == BunyiSepeda.Loop.KAYUH)
	_atur_putar(_freewheel, _loop == BunyiSepeda.Loop.FREEWHEEL)
	if jeda:
		_rem.stop()
	elif picu:
		_rem.play()


## Layar jeda dibuka (`true`) atau ditutup (`false`); disambungkan ke `JalanUji.jeda_berubah`. Saat jeda semua bunyi sepeda
## berhenti seketika, termasuk decit rem. Saat lanjut tidak ada yang langsung berbunyi: `perbarui_sepeda` berikutnya yang menentukan.
func atur_jeda(jeda: bool) -> void:
	_jeda = jeda
	if jeda:
		_loop = BunyiSepeda.Loop.DIAM
		_hentikan_pemutar()


## Pemilik sepeda keluar dari pohon (ganti scene, tes selesai): semua bunyi sepeda berhenti dan status rem dilupakan.
func hentikan_sepeda() -> void:
	_loop = BunyiSepeda.Loop.DIAM
	_rem_sebelum = false
	_jeda = false
	_hentikan_pemutar()


## Loop yang sedang aktif menurut keputusan terakhir (`BunyiSepeda.Loop`).
func loop_aktif() -> BunyiSepeda.Loop:
	return _loop


## Pitch loop kayuhan menurut keputusan terakhir.
func pitch_kayuh() -> float:
	return _pitch


## Berapa kali decit rem sudah dipicu sejak autoload dibuat (untuk tes).
func jumlah_rem_dipicu() -> int:
	return _jumlah_rem


## True selama layar jeda terbuka menurut pemanggil terakhir.
func sedang_jeda() -> bool:
	return _jeda


## True bila salah satu pemutar sepeda sedang berbunyi.
func ada_bunyi() -> bool:
	return _kayuh.playing or _freewheel.playing or _rem.playing


## Pemutar loop kayuhan (untuk tes dan probe).
func pemutar_kayuh() -> AudioStreamPlayer:
	return _kayuh


## Pemutar loop freewheel (untuk tes dan probe).
func pemutar_freewheel() -> AudioStreamPlayer:
	return _freewheel


## Pemutar decit rem (untuk tes dan probe).
func pemutar_rem() -> AudioStreamPlayer:
	return _rem


func _buat_pemutar(nama: StringName, berkas: String, volume_db: float) -> AudioStreamPlayer:
	var pemutar: AudioStreamPlayer = AudioStreamPlayer.new()
	pemutar.name = nama
	pemutar.stream = load(berkas) as AudioStream
	pemutar.bus = BUS_SEPEDA
	pemutar.volume_db = volume_db
	add_child(pemutar)
	return pemutar


## True bila stream boleh benar-benar diputar: di dalam scene tree, dan driver audio punya keluaran (atau tes memintanya).
func _boleh_putar() -> bool:
	return is_inside_tree() and (putar_di_driver_dummy or AudioServer.get_driver_name() != DRIVER_DUMMY)


func _atur_putar(pemutar: AudioStreamPlayer, aktif: bool) -> void:
	if aktif and not pemutar.playing:
		pemutar.play()
	elif not aktif and pemutar.playing:
		pemutar.stop()


func _hentikan_pemutar() -> void:
	_kayuh.stop()
	_freewheel.stop()
	_rem.stop()
