class_name TesBunyiRute
extends RefCounted
## Tes bunyi rute run fase3b-rintangan-skor: nada combo (AC-18, `BunyiLempar.tingkat_nada`/`pitch_nada`), pemetaan peristiwa ke bunyi
## (AC-19, `BunyiRute`), berkas WAV terimpor PCM sekali putar, dan autoload `Audio`: pemutar di bus SFX, variasi bel bergiliran, pitch
## "kring kring!", tidak ada bunyi baru selama jeda, jeda/background menghentikan bunyi rute seketika.
##
## Oracle literal: rasio pitch 2^(n/12) ditulis sebagai angka desimal di sini (bukan dihitung dengan fungsi yang dites), daftar berkas dan
## tabel peristiwa ditulis eksplisit.

const BERKAS_AUDIO: String = "res://scripts/autoload/audio.gd"
const LAJU_SAMPEL: int = 22050
const TOL: float = 0.000001
## 2^(n/12) untuk n = 0..5 (setengah nada), literal.
const PITCH: Array[float] = [1.0, 1.0594630943592953, 1.122462048309373, 1.189207115002721, 1.2599210498948732, 1.3348398541700344]
const BERKAS: Array[String] = [
	"res://assets/audio/sfx/obstacle/sfx_obs_dog_growl.wav",
	"res://assets/audio/sfx/obstacle/sfx_obs_dog_bark_01.wav",
	"res://assets/audio/sfx/obstacle/sfx_obs_car_beep.wav",
	"res://assets/audio/sfx/obstacle/sfx_obs_car_engine.wav",
	"res://assets/audio/sfx/obstacle/sfx_obs_crash_01.wav",
	"res://assets/audio/sfx/bell/sfx_bike_bell_01.wav",
	"res://assets/audio/sfx/bell/sfx_bike_bell_02.wav",
	"res://assets/audio/sfx/bell/sfx_bike_bell_03.wav",
	"res://assets/audio/sfx/ui/sfx_ui_tip_01.wav",
	"res://assets/audio/sfx/ui/sfx_ui_tepat_01.wav",
]

var _cek: Callable
var _judul: Callable
var _tree: SceneTree


func _init(cek: Callable, judul: Callable, tree: SceneTree) -> void:
	_cek = cek
	_judul = judul
	_tree = tree


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_test_config()
	_test_nada_combo()
	_test_nada_dari_skor()
	_test_pemetaan()
	_test_berkas()
	_test_autoload_tanpa_tree()
	await _test_pemutar_sungguhan()
	await _test_notifikasi_sendiri()


func _test_config() -> void:
	_judul.call("Bunyi rute: angka Config (AC-18, AC-19, SOUND_DESIGN 3.1, 3.3, 6)")
	check(Config.AUDIO_COMBO_NADA_MAKS == 5 and is_equal_approx(Config.AUDIO_SETENGAH_NADA_PER_OKTAF, 12.0) and is_equal_approx(Config.AUDIO_RASIO_OKTAF, 2.0) and is_equal_approx(Config.AUDIO_BEL_KEDUA_SETENGAH_NADA, 1.0), "nada combo 5 tingkat, 12 setengah nada per oktaf, rasio oktaf 2, bel kedua +1 setengah nada")
	check(is_equal_approx(Config.AUDIO_BEL_VOLUME_DB, -2.0) and is_equal_approx(Config.AUDIO_RINTANGAN_VOLUME_DB, -3.0) and is_equal_approx(Config.AUDIO_TABRAKAN_VOLUME_DB, -2.0) and is_equal_approx(Config.AUDIO_TIP_VOLUME_DB, -3.0), "volume bel -2, rintangan -3, tabrakan -2, tip/tepat -3 dB")
	check(Config.AUDIO_RINTANGAN_VOLUME_DB > Config.AUDIO_KAYUH_VOLUME_DB and Config.AUDIO_BEL_VOLUME_DB > Config.AUDIO_KAYUH_VOLUME_DB, "peringatan rintangan dan bel di atas kayuhan (SOUND_DESIGN 6)")


func _test_nada_combo() -> void:
	_judul.call("Nada combo (AC-18): rasio 2^(n/12), oracle literal tingkat 0 sampai 6; dijepit 5")
	for n: int in range(7):
		var harapan: float = PITCH[mini(n, 5)]
		check(absf(BunyiLempar.pitch_nada(n) - harapan) < TOL, "tingkat %d -> pitch %.6f" % [n, harapan])
	check(absf(BunyiLempar.pitch_nada(-1) - 1.0) < TOL, "tingkat negatif = nada dasar")
	var tabel: Array = [[0, 0], [1, 0], [2, 1], [3, 2], [6, 5], [7, 5], [30, 5], [-4, 0]]
	for t: Array in tabel:
		check(BunyiLempar.tingkat_nada(t[0]) == t[1], "antaran ke-%d dalam rangkaian -> tingkat %d" % [t[0], t[1]])
	check(absf(BunyiLempar.pitch_mendarat(1) - 1.0) < TOL and absf(BunyiLempar.pitch_mendarat(2) - PITCH[1]) < TOL and absf(BunyiLempar.pitch_mendarat(0) - 1.0) < TOL, "antaran ke-1 nada dasar, ke-2 naik setengah nada, bukan antaran (0) nada dasar")


func _test_nada_dari_skor() -> void:
	_judul.call("Nada combo dari SkorRute: naik tiap antaran sah, bertahan di tingkat 5, meleset tidak naik, putus kembali ke dasar")
	var urutan: Array = [ZonaSasaran.Hasil.KOTAK_SURAT, ZonaSasaran.Hasil.TERAS, ZonaSasaran.Hasil.HALAMAN, ZonaSasaran.Hasil.KOTAK_SURAT, ZonaSasaran.Hasil.KOTAK_SURAT, ZonaSasaran.Hasil.KOTAK_SURAT, ZonaSasaran.Hasil.KOTAK_SURAT, ZonaSasaran.Hasil.MELESET, ZonaSasaran.Hasil.KOTAK_SURAT]
	var harapan: Array[float] = [PITCH[0], PITCH[1], PITCH[2], PITCH[3], PITCH[4], PITCH[5], PITCH[5], 1.0, PITCH[0]]
	var k: SkorRute.Keadaan = SkorRute.awal()
	var dapat: Array[float] = []
	var benar: bool = true
	for i: int in range(urutan.size()):
		var h: SkorRute.Hasil = SkorRute.nilai(k, urutan[i], "n@%d" % i, false, 3.0, false, false)
		k = h.keadaan
		var p: float = BunyiLempar.pitch_mendarat(h.urutan_beruntun)
		dapat.append(snappedf(p, 0.0001))
		if absf(p - harapan[i]) > TOL:
			benar = false
	check(benar, "9 koran: pitch 1,0 / 1,0595 / 1,1225 / 1,1892 / 1,2599 / 1,3348 / 1,3348 / meleset 1,0 / sesudah putus 1,0 (dapat %s)" % [dapat])
	var ulang: SkorRute.Hasil = SkorRute.nilai(k, ZonaSasaran.Hasil.KOTAK_SURAT, "n@0", false, 3.0, false, false)
	check(ulang.status == SkorRute.Status.ULANG and absf(BunyiLempar.pitch_mendarat(ulang.urutan_beruntun) - 1.0) < TOL, "koran ke rumah yang sudah terantar: nada dasar")
	var putus: SkorRute.Keadaan = SkorRute.putus_combo(SkorRute.nilai(SkorRute.nilai(SkorRute.awal(), ZonaSasaran.Hasil.KOTAK_SURAT, "p@1", false, 3.0, false, false).keadaan, ZonaSasaran.Hasil.KOTAK_SURAT, "p@2", false, 3.0, false, false).keadaan)
	check(absf(BunyiLempar.pitch_mendarat(SkorRute.nilai(putus, ZonaSasaran.Hasil.KOTAK_SURAT, "p@3", false, 3.0, false, false).urutan_beruntun) - 1.0) < TOL, "tabrakan memutus combo: antaran berikutnya nada dasar")


func _test_pemetaan() -> void:
	_judul.call("BunyiRute (AC-19): peristiwa rintangan -> bunyi, bel bergiliran, pitch kring kring")
	var tabel: Array = [
		[RintanganRute.Peristiwa.ANJING_WASPADA, true, "sfx_obs_dog_growl.wav"],
		[RintanganRute.Peristiwa.ANJING_MENGEJAR, true, "sfx_obs_dog_bark_01.wav"],
		[RintanganRute.Peristiwa.MOBIL_TANDA, true, "sfx_obs_car_beep.wav"],
		[RintanganRute.Peristiwa.MOBIL_MUNDUR, true, "sfx_obs_car_engine.wav"],
		[RintanganRute.Peristiwa.ANJING_MUNDUR, false, ""],
	]
	check(tabel.size() == RintanganRute.Peristiwa.size(), "tabel oracle mencakup semua %d peristiwa" % RintanganRute.Peristiwa.size())
	for t: Array in tabel:
		var ada: bool = BunyiRute.berbunyi(t[0])
		var nama: String = BunyiRute.berkas(BunyiRute.dari_peristiwa(t[0]), 0).get_file() if ada else ""
		check(ada == t[1] and nama == t[2], "%s -> %s" % [RintanganRute.Peristiwa.keys()[t[0]], t[2] if t[1] else "tanpa bunyi (ikon '!')"])
	var urutan: Array[String] = []
	var giliran: int = 0
	for i: int in range(4):
		urutan.append(BunyiRute.berkas(BunyiRute.Bunyi.BEL, giliran).get_file())
		giliran = BunyiRute.giliran_berikut(BunyiRute.Bunyi.BEL, giliran)
	check(urutan == ["sfx_bike_bell_01.wav", "sfx_bike_bell_02.wav", "sfx_bike_bell_03.wav", "sfx_bike_bell_01.wav"], "bel bergiliran 01, 02, 03, 01 (dapat %s)" % [urutan])
	check(absf(BunyiRute.pitch_bel(Bel.Bunyi.KRING) - 1.0) < TOL and absf(BunyiRute.pitch_bel(Bel.Bunyi.KRING_KRING) - PITCH[1]) < TOL and BunyiRute.pitch_bel(Bel.Bunyi.TOLAK) == 0.0, "pitch bel: kring 1,0, kring kring 1,0595 (+1 setengah nada), tolak 0 (tidak diputar)")
	check(BunyiRute.berkas(BunyiRute.Bunyi.TABRAKAN, 3).get_file() == "sfx_obs_crash_01.wav" and BunyiRute.giliran_berikut(BunyiRute.Bunyi.TIP, 0) == 0, "bunyi satu berkas: giliran tetap berkas itu")
	check(BunyiRute.semua_berkas() == BERKAS, "semua_berkas = 10 berkas urut (obstacle, bell, ui)")
	var kode: String = FileAccess.get_file_as_string("res://scripts/systems/bunyi_rute.gd")
	check(not kode.is_empty() and not RegEx.create_from_string("\\b(randi|randf|RandomNumberGenerator|randomize)\\b").search(kode), "bunyi_rute.gd tanpa RNG")


func _test_berkas() -> void:
	_judul.call("Berkas bunyi rute: 10 WAV terimpor PCM 16-bit mono 22050 Hz sekali putar (AC-19)")
	for jalur: String in BERKAS:
		var s: AudioStreamWAV = load(jalur) as AudioStreamWAV
		check(s != null and s.format == AudioStreamWAV.FORMAT_16_BITS and not s.stereo and s.mix_rate == LAJU_SAMPEL and s.loop_mode == AudioStreamWAV.LOOP_DISABLED, "%s: AudioStreamWAV PCM 16-bit mono 22050 Hz, sekali putar" % jalur.get_file())
		var impor: String = FileAccess.get_file_as_string(jalur + ".import")
		check(impor.contains("compress/mode=0") and impor.contains("edit/loop_mode=1"), "%s.import: compress/mode=0, edit/loop_mode=1" % jalur.get_file())


func _test_autoload_tanpa_tree() -> void:
	_judul.call("Audio: pemutar bunyi rute di bus SFX, giliran bel, pitch, diam selama jeda (AC-19)")
	var audio: Node = (load(BERKAS_AUDIO) as GDScript).new() as Node
	var semua_benar: bool = true
	for jalur: String in BERKAS:
		var p: AudioStreamPlayer = audio.call(&"pemutar_rute", jalur)
		var harapan_db: float = -3.0
		if jalur.contains("bell") or jalur.contains("crash"):
			harapan_db = -2.0
		if p == null or p.bus != &"SFX" or p.stream.resource_path != jalur or not is_equal_approx(p.volume_db, harapan_db) or p.get_parent() != audio:
			semua_benar = false
	check(semua_benar, "10 pemutar bunyi rute: anak Audio, bus SFX, satu berkas, volume Config")
	audio.call(&"atur_ulang_rute")
	audio.call(&"putar_bel", Bel.Bunyi.KRING)
	check(String(audio.call(&"bunyi_rute_terakhir")).get_file() == "sfx_bike_bell_01.wav" and absf(float(audio.call(&"pitch_rute_terakhir")) - 1.0) < TOL, "kring: bel 01, pitch 1,0")
	audio.call(&"putar_bel", Bel.Bunyi.KRING_KRING)
	var bel_02: AudioStreamPlayer = audio.call(&"pemutar_rute", "res://assets/audio/sfx/bell/sfx_bike_bell_02.wav")
	check(String(audio.call(&"bunyi_rute_terakhir")).get_file() == "sfx_bike_bell_02.wav" and absf(bel_02.pitch_scale - PITCH[1]) < TOL, "kring kring: bel 02 diputar dengan pitch 1,0595")
	audio.call(&"putar_bel", Bel.Bunyi.TOLAK)
	check(audio.call(&"jumlah_bunyi_rute", BunyiRute.Bunyi.BEL) == 2, "ketukan ditolak tidak berbunyi (2 bunyi bel)")
	audio.call(&"putar_peristiwa", RintanganRute.Peristiwa.ANJING_WASPADA)
	audio.call(&"putar_peristiwa", RintanganRute.Peristiwa.ANJING_MUNDUR)
	audio.call(&"putar_peristiwa", RintanganRute.Peristiwa.MOBIL_TANDA)
	audio.call(&"putar_tabrakan")
	audio.call(&"putar_tip")
	audio.call(&"putar_tepat")
	check(audio.call(&"jumlah_bunyi_rute", BunyiRute.Bunyi.ANJING_GERAM) == 1 and audio.call(&"jumlah_bunyi_rute", BunyiRute.Bunyi.MOBIL_BIP) == 1 and audio.call(&"jumlah_bunyi_rute", BunyiRute.Bunyi.TABRAKAN) == 1 and audio.call(&"jumlah_bunyi_rute", BunyiRute.Bunyi.TIP) == 1 and audio.call(&"jumlah_bunyi_rute", BunyiRute.Bunyi.TEPAT) == 1, "geram, bip, tabrakan, tip, tepat masing-masing sekali; anjing mundur tanpa bunyi")
	audio.call(&"putar_mendarat", ZonaSasaran.Hasil.KOTAK_SURAT, false, PITCH[3])
	check(absf(float(audio.call(&"pitch_mendarat_terakhir")) - PITCH[3]) < TOL, "putar_mendarat menerima pitch nada combo")
	audio.call(&"putar_mendarat", ZonaSasaran.Hasil.KOTAK_SURAT, false)
	check(absf(float(audio.call(&"pitch_mendarat_terakhir")) - 1.0) < TOL, "putar_mendarat tanpa pitch = nada dasar (perilaku lama)")
	check(not audio.call(&"ada_bunyi_rute"), "tanpa tree: tidak ada stream yang diputar")
	audio.call(&"atur_jeda", true)
	audio.call(&"putar_bel", Bel.Bunyi.KRING)
	audio.call(&"putar_tabrakan")
	check(audio.call(&"jumlah_bunyi_rute", BunyiRute.Bunyi.BEL) == 2 and audio.call(&"jumlah_bunyi_rute", BunyiRute.Bunyi.TABRAKAN) == 1, "selama jeda: tidak ada bunyi rute baru")
	audio.call(&"atur_jeda", false)
	audio.call(&"putar_bel", Bel.Bunyi.KRING)
	check(String(audio.call(&"bunyi_rute_terakhir")).get_file() == "sfx_bike_bell_03.wav", "sesudah jeda giliran bel berlanjut (03)")
	audio.call(&"atur_ulang_rute")
	check(audio.call(&"jumlah_bunyi_rute", BunyiRute.Bunyi.BEL) == 0 and audio.call(&"bunyi_rute_terakhir") == "", "atur_ulang_rute mengosongkan pencacah")
	audio.free()


func _test_pemutar_sungguhan() -> void:
	_judul.call("Audio di tree: bunyi rute berbunyi; jeda dan hentikan_lempar menghentikannya seketika (AC-19, AC-21)")
	var audio: Node = _tree.root.get_node_or_null(^"Audio")
	if audio == null:
		check(false, "autoload Audio ada")
		return
	audio.call(&"atur_ulang_rute")
	audio.call(&"putar_peristiwa", RintanganRute.Peristiwa.MOBIL_TANDA)
	audio.call(&"putar_bel", Bel.Bunyi.KRING)
	var bip: AudioStreamPlayer = audio.call(&"pemutar_rute", "res://assets/audio/sfx/obstacle/sfx_obs_car_beep.wav")
	check(bip.playing and audio.call(&"ada_bunyi_rute"), "bip lampu mundur dan bel berbunyi")
	audio.call(&"atur_jeda", true)
	check(not audio.call(&"ada_bunyi_rute"), "atur_jeda(true): semua bunyi rute berhenti seketika")
	await _tree.process_frame
	audio.call(&"atur_jeda", false)
	await _tree.process_frame
	await _tree.process_frame
	check(not audio.call(&"ada_bunyi_rute"), "sesudah lanjut: bunyi rute lama tidak diputar ulang")
	audio.call(&"putar_tabrakan")
	audio.call(&"perbarui_sepeda", LoperAnim.Pose.KAYUH, 3.0, false, true)
	check(not audio.call(&"ada_bunyi_rute"), "perbarui_sepeda dengan jeda: bunyi rute berhenti")
	audio.call(&"perbarui_sepeda", LoperAnim.Pose.KAYUH, 3.0, false, false)
	audio.call(&"putar_tip")
	check(audio.call(&"ada_bunyi_rute"), "kontrol: tip berbunyi")
	audio.call(&"hentikan_lempar")
	check(not audio.call(&"ada_bunyi_rute"), "hentikan_lempar menghentikan bunyi rute juga")
	audio.call(&"hentikan_sepeda")
	await _tree.process_frame


func _test_notifikasi_sendiri() -> void:
	_judul.call("Audio menghentikan bunyi rute sendiri pada PAUSED, FOCUS_OUT, dan tutup jendela (AC-19)")
	var skrip: GDScript = load(BERKAS_AUDIO) as GDScript
	for baris: Array in [["APPLICATION_PAUSED", Node.NOTIFICATION_APPLICATION_PAUSED], ["APPLICATION_FOCUS_OUT", Node.NOTIFICATION_APPLICATION_FOCUS_OUT], ["WM_CLOSE_REQUEST", Node.NOTIFICATION_WM_CLOSE_REQUEST]]:
		var audio: Node = skrip.new() as Node
		audio.name = "AudioUjiRute"
		audio.set(&"putar_di_driver_dummy", true)
		_tree.root.add_child(audio)
		audio.call(&"putar_bel", Bel.Bunyi.KRING)
		audio.call(&"putar_peristiwa", RintanganRute.Peristiwa.ANJING_WASPADA)
		check(audio.call(&"ada_bunyi_rute"), "%s: kontrol: bel dan geram berbunyi" % baris[0])
		audio.propagate_notification(baris[1])
		check(not audio.call(&"ada_bunyi_rute"), "%s: bunyi rute berhenti lewat Audio._notification" % baris[0])
		_tree.root.remove_child(audio)
		audio.free()
	await _tree.process_frame
