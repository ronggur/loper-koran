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
## Bunyi rute run 3B (AC-18, AC-19 run fase3b-rintangan-skor) juga di bus `SFX`, satu pemutar per berkas `BunyiRute.BERKAS`: peristiwa
## rintangan (`putar_peristiwa`), tabrakan (`putar_tabrakan`), bel (`putar_bel`, tiga variasi bergiliran, "kring kring!" lebih tinggi), tip
## (`putar_tip`), dan tepat (`putar_tepat`). Bunyi mendarat menerima pitch nada combo (`putar_mendarat(..., pitch)`, `BunyiLempar.pitch_mendarat`).
## Keputusan di `BunyiRute`/`BunyiLempar` (logika murni). Jalur jeda sama: tidak ada bunyi baru selama jeda, dan jeda, background, kehilangan
## fokus, tutup jendela, atau `hentikan_lempar` menghentikan semua bunyi bus SFX (lempar, mendarat, dan rute) seketika.
##
## Bunyi misi run 4B (AC-15 run fase4b-misi-kucing) juga di bus `SFX`, satu pemutar per berkas `BunyiMisi.BERKAS`: peristiwa misi (`putar_misi_peristiwa`:
## meong petunjuk, kucing terlihat, misi selesai, misi gagal). Keputusan di `BunyiMisi` (logika murni); jalur jeda dan background sama dengan bunyi lain.
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
var _pitch_mendarat_terakhir: float = 1.0
## Pemutar bunyi rute per berkas (`BunyiRute.BERKAS`): String jalur -> AudioStreamPlayer.
var _pemutar_rute: Dictionary = {}
## Giliran variasi berikutnya per bunyi rute (`BunyiRute.Bunyi` -> int).
var _giliran_rute: Dictionary = {}
## Jumlah keputusan putar per bunyi rute (`BunyiRute.Bunyi` -> int), untuk tes.
var _jumlah_rute: Dictionary = {}
var _rute_terakhir: String = ""
var _pitch_rute_terakhir: float = 1.0
## Pemutar bunyi misi per berkas (`BunyiMisi.BERKAS`): String jalur -> AudioStreamPlayer, jumlah keputusan putar per bunyi, dan berkas terakhir (untuk tes).
var _pemutar_misi: Dictionary = {}
var _jumlah_misi: Dictionary = {}
var _misi_terakhir: String = ""


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
	for b: BunyiRute.Bunyi in BunyiRute.BERKAS:
		for berkas: String in BunyiRute.BERKAS[b]:
			var nama_rute: StringName = StringName("PemutarRute_" + berkas.get_file().get_basename())
			_pemutar_rute[berkas] = _buat_pemutar(nama_rute, berkas, BunyiRute.volume_db(b), BUS_LEMPAR)
	for b: BunyiMisi.Bunyi in BunyiMisi.BERKAS:
		var berkas_misi: String = BunyiMisi.berkas(b)
		var nama_misi: StringName = StringName("PemutarMisi_" + berkas_misi.get_file().get_basename())
		_pemutar_misi[berkas_misi] = _buat_pemutar(nama_misi, berkas_misi, BunyiMisi.volume_db(b), BUS_LEMPAR)


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
## variasi bergiliran per permukaan, dengan `pitch` nada combo (AC-18; `BunyiLempar.pitch_mendarat`, bawaan nada dasar). Tidak ada bunyi
## baru selama jeda (koran beku, jadi tidak mendarat).
func putar_mendarat(hasil: ZonaSasaran.Hasil, jendela_bonus: bool, pitch: float = 1.0) -> void:
	if _jeda:
		return
	var p: BunyiLempar.Permukaan = BunyiLempar.permukaan(hasil, jendela_bonus)
	var giliran: int = _giliran.get(p, 0)
	var berkas: String = BunyiLempar.berkas_mendarat(p, giliran)
	_giliran[p] = BunyiLempar.giliran_berikut(p, giliran)
	_jumlah_mendarat += 1
	_mendarat_terakhir = berkas
	_pitch_mendarat_terakhir = pitch
	var pemutar: AudioStreamPlayer = _pemutar_mendarat[berkas]
	pemutar.pitch_scale = pitch
	if _boleh_putar():
		pemutar.play()


## Pitch bunyi mendarat terakhir (nada combo, untuk tes).
func pitch_mendarat_terakhir() -> float:
	return _pitch_mendarat_terakhir


## Satu bunyi rute `b` (`BunyiRute.Bunyi`) dengan `pitch`; variasi bergiliran per bunyi. Tidak ada bunyi baru selama jeda.
func putar_rute(b: BunyiRute.Bunyi, pitch: float = 1.0) -> void:
	if _jeda:
		return
	var giliran: int = _giliran_rute.get(b, 0)
	var berkas: String = BunyiRute.berkas(b, giliran)
	_giliran_rute[b] = BunyiRute.giliran_berikut(b, giliran)
	_jumlah_rute[b] = int(_jumlah_rute.get(b, 0)) + 1
	_rute_terakhir = berkas
	_pitch_rute_terakhir = pitch
	var pemutar: AudioStreamPlayer = _pemutar_rute[berkas]
	pemutar.pitch_scale = pitch
	if _boleh_putar():
		pemutar.play()


## Peristiwa rintangan (`RintanganRute.Peristiwa`): geram, gonggong, bip, atau mesin; peristiwa tanpa bunyi diabaikan.
func putar_peristiwa(peristiwa: RintanganRute.Peristiwa) -> void:
	if BunyiRute.berbunyi(peristiwa):
		putar_rute(BunyiRute.dari_peristiwa(peristiwa))


## Tabrakan: satu bunyi tabrakan lembut.
func putar_tabrakan() -> void:
	putar_rute(BunyiRute.Bunyi.TABRAKAN)


## Ketukan bel dengan hasil `bunyi_bel` (`Bel.Bunyi`): "kring" atau "kring kring!" (lebih tinggi); `TOLAK` tidak berbunyi.
func putar_bel(bunyi_bel: Bel.Bunyi) -> void:
	if Bel.berbunyi(bunyi_bel):
		putar_rute(BunyiRute.Bunyi.BEL, BunyiRute.pitch_bel(bunyi_bel))


## Denting tip (berkasnya diawali senyap, jadi terdengar sesudah bunyi mendarat yang diputar bersamaan).
func putar_tip() -> void:
	putar_rute(BunyiRute.Bunyi.TIP)


## Kilau antaran tepat.
func putar_tepat() -> void:
	putar_rute(BunyiRute.Bunyi.TEPAT)


## Bunyi misi `b` (`BunyiMisi.Bunyi`). Tidak ada bunyi baru selama jeda.
func putar_misi(b: BunyiMisi.Bunyi) -> void:
	if _jeda:
		return
	_jumlah_misi[b] = int(_jumlah_misi.get(b, 0)) + 1
	_misi_terakhir = BunyiMisi.berkas(b)
	var pemutar: AudioStreamPlayer = _pemutar_misi[_misi_terakhir]
	if _boleh_putar():
		pemutar.play()


## Peristiwa misi (nilai enum `MissionManager.Peristiwa`, diberikan sebagai bilangan bulat karena autoload tidak merujuk `MissionManager`): meong, terlihat,
## selesai, atau gagal; peristiwa tanpa bunyi (langkah selesai) diabaikan.
func putar_misi_peristiwa(peristiwa: int) -> void:
	if BunyiMisi.berbunyi(peristiwa):
		putar_misi(BunyiMisi.dari_peristiwa(peristiwa))


## Berapa kali bunyi misi `b` diputuskan sejak autoload dibuat (untuk tes).
func jumlah_bunyi_misi(b: BunyiMisi.Bunyi) -> int:
	return int(_jumlah_misi.get(b, 0))


## Jalur berkas bunyi misi terakhir ("" bila belum ada; untuk tes).
func bunyi_misi_terakhir() -> String:
	return _misi_terakhir


## Pemutar bunyi misi untuk jalur `berkas` (`BunyiMisi.BERKAS`), atau null (untuk tes dan probe).
func pemutar_misi(berkas: String) -> AudioStreamPlayer:
	return _pemutar_misi.get(berkas, null) as AudioStreamPlayer


## True bila salah satu bunyi misi sedang berbunyi.
func ada_bunyi_misi() -> bool:
	for pemutar: AudioStreamPlayer in _pemutar_misi.values():
		if pemutar.playing:
			return true
	return false


## Mengembalikan pencacah dan giliran bunyi rute ke awal (untuk tes dan "Main lagi").
func atur_ulang_rute() -> void:
	_giliran_rute.clear()
	_jumlah_rute.clear()
	_rute_terakhir = ""
	_pitch_rute_terakhir = 1.0
	_jumlah_misi.clear()
	_misi_terakhir = ""


## Berapa kali bunyi rute `b` diputuskan sejak autoload dibuat atau `atur_ulang_rute` (untuk tes).
func jumlah_bunyi_rute(b: BunyiRute.Bunyi) -> int:
	return int(_jumlah_rute.get(b, 0))


## Jalur berkas bunyi rute terakhir ("" bila belum ada) dan pitch-nya (untuk tes).
func bunyi_rute_terakhir() -> String:
	return _rute_terakhir


func pitch_rute_terakhir() -> float:
	return _pitch_rute_terakhir


## Pemutar bunyi rute untuk jalur `berkas` (`BunyiRute.BERKAS`), atau null (untuk tes dan probe).
func pemutar_rute(berkas: String) -> AudioStreamPlayer:
	return _pemutar_rute.get(berkas, null) as AudioStreamPlayer


## True bila salah satu bunyi rute sedang berbunyi.
func ada_bunyi_rute() -> bool:
	for pemutar: AudioStreamPlayer in _pemutar_rute.values():
		if pemutar.playing:
			return true
	return false


## Menghentikan semua bunyi bus SFX yang sedang berbunyi: "wus", bunyi mendarat, dan bunyi rute (scene pemilik keluar, atau sebelum Godot
## keluar).
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
	for pemutar: AudioStreamPlayer in _pemutar_rute.values():
		pemutar.stop()
	for pemutar: AudioStreamPlayer in _pemutar_misi.values():
		pemutar.stop()
