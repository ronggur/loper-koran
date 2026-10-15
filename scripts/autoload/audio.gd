extends Node
## Autoload `Audio` (TECH_PLAN 3.1, SOUND_DESIGN 3.1, 3.2, 4.2, dan 6; D-3 dan D-5 run fase1b-umpan-balik, D-10 sampai D-12 run
## fase2b-bantu-audio): bunyi sepeda placeholder dan bunyi lempar/mendarat placeholder.
##
## Tiga pemutar di bus `Sepeda` (`default_bus_layout.tres`: `Sepeda` -> `SFX` -> `Master`): loop kayuhan (pitch mengikuti
## kecepatan), loop freewheel (meluncur), dan decit rem sekali putar. Keputusan ada di `BunyiSepeda` (logika murni); node ini
## hanya menyalakan, mematikan, dan mengatur pitch pemutar.
##
## Bunyi lempar dan mendarat (D-10, D-11 run fase2b-bantu-audio) di bus `SFX`: satu pemutar "wus" dan satu pemutar per berkas mendarat
## (empat permukaan x tiga variasi), jadi variasi yang bergiliran tidak pernah memotong bunyi permukaan lain dan stream tidak pernah
## diganti saat berbunyi. `putar_lempar` dipanggil sekali per lemparan yang DITERIMA (`JalanUji.koran_dilempar`), `putar_mendarat`
## sekali per koran yang mendarat (`JalanUji.koran_mendarat`) dengan hasil sasaran dan sakelar jendela; permukaan dan berkas dipilih
## `BunyiLempar` (logika murni), pencacah giliran variasi per permukaan disimpan di sini. Selama jeda tidak ada bunyi lempar/mendarat
## baru, dan jeda, background, kehilangan fokus, atau tutup jendela menghentikan yang sedang berbunyi seketika (D-12), lewat jalur yang
## sama dengan decit rem.
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
## Bus bunyi lempar dan mendarat (D-11: bukan bus `Sepeda`, jadi tidak ikut nasib bunyi kayuhan).
const BUS_LEMPAR: StringName = &"SFX"
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
var _wus: AudioStreamPlayer
## Pemutar bunyi mendarat per berkas (`BunyiLempar.BERKAS_MENDARAT`): String jalur berkas -> AudioStreamPlayer.
var _pemutar_mendarat: Dictionary = {}
## Giliran variasi berikutnya per permukaan (`BunyiLempar.Permukaan` -> int, 0 = variasi 01).
var _giliran: Dictionary = {}
var _jumlah_wus: int = 0
var _jumlah_mendarat: int = 0
var _mendarat_terakhir: String = ""


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_kayuh = _buat_pemutar(&"PemutarKayuh", BERKAS_KAYUH, Config.AUDIO_KAYUH_VOLUME_DB)
	_freewheel = _buat_pemutar(&"PemutarFreewheel", BERKAS_FREEWHEEL, Config.AUDIO_FREEWHEEL_VOLUME_DB)
	_rem = _buat_pemutar(&"PemutarRem", BERKAS_REM, Config.AUDIO_REM_VOLUME_DB)
	_wus = _buat_pemutar(&"PemutarWus", BunyiLempar.BERKAS_WUS, Config.AUDIO_WUS_VOLUME_DB, BUS_LEMPAR)
	for berkas: String in BunyiLempar.semua_berkas():
		if berkas != BunyiLempar.BERKAS_WUS:
			var nama: StringName = StringName("PemutarMendarat_" + berkas.get_file().get_basename())
			_pemutar_mendarat[berkas] = _buat_pemutar(nama, berkas, Config.AUDIO_MENDARAT_VOLUME_DB, BUS_LEMPAR)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_CLOSE_REQUEST:
		_hentikan_pemutar()
		_hentikan_pemutar_lempar()


## Satu langkah bunyi sepeda dari keadaan sebenarnya: `pose` (`LoperAnim.Pose`), `kecepatan_ud`, `rem_aktif`, dan `jeda`.
## Decit rem dimainkan hanya di tepi naik rem (`BunyiSepeda.rem_dipicu`); status rem selalu dicatat, juga selama jeda.
func perbarui_sepeda(pose: LoperAnim.Pose, kecepatan_ud: float, rem_aktif: bool, jeda: bool) -> void:
	var picu: bool = BunyiSepeda.rem_dipicu(_rem_sebelum, rem_aktif, kecepatan_ud, jeda)
	_rem_sebelum = rem_aktif
	_jeda = jeda
	if jeda:
		_hentikan_pemutar_lempar()
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
## berhenti seketika, termasuk decit rem, begitu juga "wus" dan bunyi mendarat yang sedang berbunyi (D-12). Saat lanjut tidak ada yang
## langsung berbunyi: `perbarui_sepeda` berikutnya yang menentukan, dan bunyi lempar/mendarat lama tidak diputar ulang.
func atur_jeda(jeda: bool) -> void:
	_jeda = jeda
	if jeda:
		_loop = BunyiSepeda.Loop.DIAM
		_hentikan_pemutar()
		_hentikan_pemutar_lempar()


## Lemparan diterima (D-11): satu "wus". Tidak ada bunyi baru selama jeda (lemparan juga tidak bisa diterima saat jeda).
func putar_lempar() -> void:
	if _jeda:
		return
	_jumlah_wus += 1
	if _boleh_putar():
		_wus.play()


## Koran mendarat dengan hasil `hasil` (`ZonaSasaran.Hasil`) dan sakelar jendela `jendela_bonus` (D-10, D-11): satu bunyi permukaan,
## variasi bergiliran per permukaan. Tidak ada bunyi baru selama jeda (koran beku, jadi tidak mendarat).
func putar_mendarat(hasil: ZonaSasaran.Hasil, jendela_bonus: bool) -> void:
	if _jeda:
		return
	var p: BunyiLempar.Permukaan = BunyiLempar.permukaan(hasil, jendela_bonus)
	var giliran: int = _giliran.get(p, 0)
	var berkas: String = BunyiLempar.berkas_mendarat(p, giliran)
	_giliran[p] = BunyiLempar.giliran_berikut(p, giliran)
	_jumlah_mendarat += 1
	_mendarat_terakhir = berkas
	if _boleh_putar():
		(_pemutar_mendarat[berkas] as AudioStreamPlayer).play()


## Menghentikan "wus" dan bunyi mendarat yang sedang berbunyi (scene pemilik keluar, atau sebelum Godot keluar).
func hentikan_lempar() -> void:
	_hentikan_pemutar_lempar()


## Mengembalikan pencacah bunyi lempar/mendarat dan giliran variasi ke awal (variasi 01). Untuk tes.
func atur_ulang_lempar() -> void:
	_giliran.clear()
	_jumlah_wus = 0
	_jumlah_mendarat = 0
	_mendarat_terakhir = ""


## Berapa kali "wus" diputuskan sejak autoload dibuat atau `atur_ulang_lempar` (untuk tes).
func jumlah_wus() -> int:
	return _jumlah_wus


## Berapa kali bunyi mendarat diputuskan sejak autoload dibuat atau `atur_ulang_lempar` (untuk tes).
func jumlah_mendarat() -> int:
	return _jumlah_mendarat


## Jalur berkas bunyi mendarat terakhir yang dipilih ("" bila belum ada).
func mendarat_terakhir() -> String:
	return _mendarat_terakhir


## True bila "wus" atau salah satu bunyi mendarat sedang berbunyi.
func ada_bunyi_lempar() -> bool:
	if _wus.playing:
		return true
	for pemutar: AudioStreamPlayer in _pemutar_mendarat.values():
		if pemutar.playing:
			return true
	return false


## Pemutar "wus" (untuk tes dan probe).
func pemutar_wus() -> AudioStreamPlayer:
	return _wus


## Pemutar bunyi mendarat untuk jalur `berkas` (`BunyiLempar.BERKAS_MENDARAT`), atau null (untuk tes dan probe).
func pemutar_mendarat(berkas: String) -> AudioStreamPlayer:
	return _pemutar_mendarat.get(berkas, null) as AudioStreamPlayer


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


## True bila salah satu pemutar sepeda sedang berbunyi (bunyi lempar/mendarat: `ada_bunyi_lempar`).
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


func _buat_pemutar(nama: StringName, berkas: String, volume_db: float, bus: StringName = BUS_SEPEDA) -> AudioStreamPlayer:
	var pemutar: AudioStreamPlayer = AudioStreamPlayer.new()
	pemutar.name = nama
	pemutar.stream = load(berkas) as AudioStream
	pemutar.bus = bus
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


func _hentikan_pemutar_lempar() -> void:
	_wus.stop()
	for pemutar: AudioStreamPlayer in _pemutar_mendarat.values():
		pemutar.stop()
