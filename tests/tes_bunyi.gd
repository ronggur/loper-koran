class_name TesBunyi
extends RefCounted
## Tes bunyi sepeda run fase1b-umpan-balik (AC-4, AC-5 sisi Godot, D-3 sampai D-5): `BunyiSepeda` murni (pitch, loop, tepi naik rem,
## jeda), autoload `Audio` tanpa scene tree, teks `audio.gd` tidak merujuk autoload lain, bus `Sepeda` -> `SFX` -> `Master`, tiga
## stream (format, loop), dan bunyi di scene `jalan_uji.tscn` lewat `/root/Audio` (stream sungguhan diputar di driver Dummy karena
## runner menyalakan `putar_di_driver_dummy`). Scene dijalankan dengan `perbarui(DT)` seperti tes scene lain. Run fase1c-perapian:
## jalur berhenti `Audio` sendiri pada notifikasi app (QA-001 Q02).

const BERKAS_JALAN_UJI: String = "res://scenes/dev/jalan_uji.tscn"
const BERKAS_AUDIO: String = "res://scripts/autoload/audio.gd"
const BERKAS_BUS: String = "res://default_bus_layout.tres"
const FOLDER_BUNYI: String = "res://assets/audio/sfx/bike/"
const DT: float = 1.0 / 60.0
const SKALA: int = 3
const TITIK_STICK: Vector2 = Vector2(100, 260)
const TOL: float = 0.000001
## Laju sampel WAV hasil `tools/audio_art/sintesis_sepeda.py`.
const LAJU_SAMPEL: int = 22050
## Autoload yang direncanakan TECH_PLAN 3.1; `audio.gd` tidak boleh merujuk satu pun (rule `gdscript`, gotcha tes headless).
const AUTOLOAD_RENCANA: Array[String] = ["SaveManager", "DayManager", "RouteBuilder", "MissionManager", "HeadlineManager", "ReputationManager", "BikeCondition", "Economy", "StoryManager", "DistrictUnlock", "EndingEvaluator", "DialogPlayer", "MilestoneTracker", "AdService", "Analytics"]

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
	_test_pitch()
	_test_loop()
	_test_rem_dipicu()
	_test_autoload_tanpa_tree()
	_test_teks_audio()
	_test_bus()
	_test_stream()
	await _test_loop_sungguhan()
	await _test_notifikasi_sendiri()
	await _test_scene()


func _test_config() -> void:
	_judul.call("Bunyi sepeda: angka Config (D-3, SOUND_DESIGN 3.2, usulan)")
	check(Config.AUDIO_KAYUH_PITCH_SANTAI == 1.0 and Config.AUDIO_KAYUH_PITCH_CEPAT == 1.15 and Config.AUDIO_KAYUH_PITCH_NGEBUT == 1.3, "pitch kayuhan 1,0 / 1,15 / 1,3 (SOUND_DESIGN 3.2)")
	check(Config.AUDIO_KAYUH_VOLUME_DB <= 0.0 and Config.AUDIO_FREEWHEEL_VOLUME_DB < Config.AUDIO_KAYUH_VOLUME_DB, "volume kayuhan tidak di atas 0 dB, freewheel lebih pelan dari kayuhan (\"tik-tik-tik\" pelan)")


# --- Pitch kayuhan ---

func _test_pitch() -> void:
	_judul.call("BunyiSepeda.pitch_kayuh: linear per potong, dijepit (AC-4)")
	check(BunyiSepeda.pitch_kayuh(3.0) == 1.0, "santai 3,0 = pitch 1,0")
	check(absf(BunyiSepeda.pitch_kayuh(4.5) - 1.15) < TOL, "cepat 4,5 = pitch 1,15")
	check(BunyiSepeda.pitch_kayuh(6.0) == 1.3, "ngebut 6,0 = pitch 1,3")
	check(absf(BunyiSepeda.pitch_kayuh(3.75) - 1.075) < TOL, "3,75 = 1,075 (separuh santai-cepat, linear, bukan tangga)")
	check(absf(BunyiSepeda.pitch_kayuh(5.25) - 1.225) < TOL, "5,25 = 1,225 (separuh cepat-ngebut, linear)")
	check(absf(BunyiSepeda.pitch_kayuh(3.3) - 1.03) < TOL and absf(BunyiSepeda.pitch_kayuh(5.7) - 1.27) < TOL, "3,3 = 1,03 dan 5,7 = 1,27 (linear di dekat ujung)")
	for v: float in [0.0, 1.5, 2.999, -5.0, -INF, NAN]:
		check(BunyiSepeda.pitch_kayuh(v) == 1.0, "kecepatan %s (di bawah santai, negatif, atau NaN): dijepit ke 1,0" % v)
	for v: float in [6.0001, 7.0, 100.0, INF]:
		check(BunyiSepeda.pitch_kayuh(v) == 1.3, "kecepatan %s (di atas ngebut): dijepit ke 1,3" % v)
	var monoton: bool = true
	var lalu: float = 0.0
	var beda_naik: int = 0
	for i: int in range(0, 801):
		var p: float = BunyiSepeda.pitch_kayuh(float(i) / 100.0)
		if p < lalu or p < 1.0 or p > 1.3:
			monoton = false
		if p > lalu + TOL and i > 0:
			beda_naik += 1
		lalu = p
	check(monoton, "pitch monoton naik terhadap kecepatan 0..8 dan selalu di 1,0..1,3")
	check(beda_naik >= 290, "pitch naik di hampir setiap 0,01 u/d antara 3,0 dan 6,0 (halus, bukan tangga): %d kenaikan" % beda_naik)


# --- Loop aktif ---

func _test_loop() -> void:
	_judul.call("BunyiSepeda.loop_aktif: kayuh, freewheel, diam (AC-4)")
	var kayuh: LoperAnim.Pose = LoperAnim.Pose.KAYUH
	var meluncur: LoperAnim.Pose = LoperAnim.Pose.MELUNCUR
	var rem: LoperAnim.Pose = LoperAnim.Pose.REM
	# [pose, kecepatan, rem aktif, jeda, harapan, label]
	var tabel: Array = [
		[kayuh, 3.0, false, false, BunyiSepeda.Loop.KAYUH, "kayuh santai = loop kayuh"],
		[kayuh, 6.0, false, false, BunyiSepeda.Loop.KAYUH, "kayuh ngebut = loop kayuh"],
		[kayuh, 1.5, false, false, BunyiSepeda.Loop.KAYUH, "melambat (pose kayuh tingkat -1) = loop kayuh"],
		[kayuh, 0.01, false, false, BunyiSepeda.Loop.KAYUH, "kayuh sangat pelan (> 0) = loop kayuh"],
		[meluncur, 4.0, false, false, BunyiSepeda.Loop.FREEWHEEL, "meluncur = loop freewheel"],
		[meluncur, 1.6, false, false, BunyiSepeda.Loop.FREEWHEEL, "meluncur pelan = loop freewheel"],
		[rem, 4.0, true, false, BunyiSepeda.Loop.DIAM, "rem bergerak = diam (decit sekali, bukan loop)"],
		[rem, 0.0, true, false, BunyiSepeda.Loop.DIAM, "rem berhenti = diam"],
		[kayuh, 3.0, true, false, BunyiSepeda.Loop.DIAM, "rem aktif walau pose belum rem = diam"],
		[rem, 3.0, false, false, BunyiSepeda.Loop.DIAM, "pose rem tanpa status rem = diam"],
		[kayuh, 0.0, false, false, BunyiSepeda.Loop.DIAM, "kecepatan 0 tanpa rem = diam"],
		[meluncur, 0.0, false, false, BunyiSepeda.Loop.DIAM, "meluncur di kecepatan 0 = diam"],
		[kayuh, -1.0, false, false, BunyiSepeda.Loop.DIAM, "kecepatan negatif = diam"],
		[kayuh, NAN, false, false, BunyiSepeda.Loop.DIAM, "kecepatan NaN = diam"],
		[kayuh, INF, false, false, BunyiSepeda.Loop.DIAM, "kecepatan tak hingga = diam"],
		[kayuh, 6.0, false, true, BunyiSepeda.Loop.DIAM, "jeda saat ngebut = diam"],
		[meluncur, 4.0, false, true, BunyiSepeda.Loop.DIAM, "jeda saat meluncur = diam"],
		[rem, 4.0, true, true, BunyiSepeda.Loop.DIAM, "jeda saat rem = diam"],
	]
	for baris: Array in tabel:
		var hasil: BunyiSepeda.Loop = BunyiSepeda.loop_aktif(baris[0], baris[1], baris[2], baris[3])
		check(hasil == baris[4], "%s (dapat %s)" % [baris[5], hasil])


# --- Pemicu rem: tepi naik ---

func _test_rem_dipicu() -> void:
	_judul.call("BunyiSepeda.rem_dipicu: hanya di tepi naik, tidak tertunda sesudah jeda (AC-4, D-5)")
	check(BunyiSepeda.rem_dipicu(false, true, 4.0, false), "rem baru menyala saat bergerak: decit dipicu")
	check(not BunyiSepeda.rem_dipicu(true, true, 4.0, false), "rem masih ditahan: tidak dipicu lagi")
	check(not BunyiSepeda.rem_dipicu(true, false, 4.0, false) and not BunyiSepeda.rem_dipicu(false, false, 4.0, false), "rem padam atau tetap padam: tidak dipicu")
	check(not BunyiSepeda.rem_dipicu(false, true, 4.0, true), "tepi naik selama jeda: tidak dipicu")
	check(not BunyiSepeda.rem_dipicu(false, true, 0.0, false), "rem menyala di kecepatan 0: tidak berdecit (tidak ada roda berputar)")
	check(not BunyiSepeda.rem_dipicu(false, true, NAN, false) and not BunyiSepeda.rem_dipicu(false, true, -1.0, false), "kecepatan NaN atau negatif: tidak dipicu")
	# Urutan langkah seperti dijalankan `Audio`: status rem sebelumnya selalu dicatat, juga selama jeda.
	# [rem aktif, jeda]
	var urutan: Array = [[false, false], [false, false], [true, false], [true, false], [true, false], [false, false], [true, false], [true, false], [true, true], [true, true], [true, false], [false, false], [false, true], [true, true], [true, false], [false, false], [true, false]]
	var sebelum: bool = false
	var dipicu: Array[int] = []
	for i: int in range(urutan.size()):
		var langkah: Array = urutan[i]
		if BunyiSepeda.rem_dipicu(sebelum, langkah[0], 4.0, langkah[1]):
			dipicu.append(i)
		sebelum = langkah[0]
	check(dipicu == [2, 6, 16], "urutan: dipicu di tepi naik (2, 6, 16); tidak tiap langkah selama ditahan, tidak tertunda sesudah jeda (10, 14), dapat %s" % [dipicu])


# --- Autoload tanpa scene tree ---

func _test_autoload_tanpa_tree() -> void:
	_judul.call("Autoload Audio: load().new() tanpa scene tree (rule testing, AC-4)")
	var skrip: GDScript = load(BERKAS_AUDIO) as GDScript
	check(skrip != null, "scripts/autoload/audio.gd termuat")
	if skrip == null:
		return
	var audio: Node = skrip.new() as Node
	check(audio != null and not audio.is_inside_tree(), "Audio.new() berhasil tanpa masuk scene tree")
	check(audio.process_mode == Node.PROCESS_MODE_ALWAYS, "Audio PROCESS_MODE_ALWAYS (pemutar tidak di-pause otomatis; jeda dihentikan sendiri, D-5)")
	var pemutar: Array[AudioStreamPlayer] = [audio.call("pemutar_kayuh"), audio.call("pemutar_freewheel"), audio.call("pemutar_rem")]
	var nama: Array[String] = ["sfx_bike_pedal_loop.wav", "sfx_bike_freewheel_loop.wav", "sfx_bike_brake_01.wav"]
	var volume: Array[float] = [Config.AUDIO_KAYUH_VOLUME_DB, Config.AUDIO_FREEWHEEL_VOLUME_DB, Config.AUDIO_REM_VOLUME_DB]
	for i: int in range(pemutar.size()):
		var p: AudioStreamPlayer = pemutar[i]
		check(p != null and p.get_parent() == audio and p.bus == &"Sepeda" and p.stream != null and p.stream.resource_path.ends_with(nama[i]) and p.volume_db == volume[i], "pemutar %s: anak Audio, bus Sepeda, stream %s, volume dari Config" % [i, nama[i]])
	var kayuh: LoperAnim.Pose = LoperAnim.Pose.KAYUH
	var rem: LoperAnim.Pose = LoperAnim.Pose.REM
	audio.call("perbarui_sepeda", kayuh, 6.0, false, false)
	check(audio.call("loop_aktif") == BunyiSepeda.Loop.KAYUH and audio.call("pitch_kayuh") == 1.3, "tanpa tree: keputusan tetap dihitung (ngebut: loop kayuh, pitch 1,3)")
	check(not audio.call("ada_bunyi"), "tanpa tree: tidak ada stream yang diputar")
	for i: int in range(30):
		audio.call("perbarui_sepeda", rem, 4.0, true, false)
	check(audio.call("jumlah_rem_dipicu") == 1 and audio.call("loop_aktif") == BunyiSepeda.Loop.DIAM, "rem ditahan 30 langkah: decit dipicu sekali, loop diam")
	audio.call("atur_jeda", true)
	audio.call("perbarui_sepeda", kayuh, 3.0, false, true)
	audio.call("perbarui_sepeda", rem, 3.0, true, true)
	audio.call("atur_jeda", false)
	audio.call("perbarui_sepeda", rem, 3.0, true, false)
	check(audio.call("jumlah_rem_dipicu") == 1, "rem menyala selama jeda lalu lanjut dengan rem masih aktif: tidak ada decit tertunda")
	audio.call("hentikan_sepeda")
	audio.call("perbarui_sepeda", rem, 3.0, true, false)
	check(audio.call("jumlah_rem_dipicu") == 2, "sesudah hentikan_sepeda status rem dilupakan: rem berikutnya dipicu lagi")
	audio.free()


func _test_teks_audio() -> void:
	_judul.call("Autoload Audio: terdaftar dan tidak merujuk autoload lain (rule gdscript, AC-4)")
	check(ProjectSettings.get_setting("autoload/Audio", "") == "*" + BERKAS_AUDIO, "project.godot mendaftarkan autoload Audio (singleton) = %s" % BERKAS_AUDIO)
	check(_tree.root.get_node_or_null(^"Audio") != null and _tree.root.get_node(^"Audio").get_script().resource_path == BERKAS_AUDIO, "/root/Audio ada saat tes berjalan")
	var nama_autoload: Array[String] = []
	for properti: Dictionary in ProjectSettings.get_property_list():
		var nama: String = properti["name"]
		if nama.begins_with("autoload/"):
			nama_autoload.append(nama.trim_prefix("autoload/"))
	check(nama_autoload.has("Audio"), "daftar autoload terbaca (%s)" % [nama_autoload])
	var kode: String = _kode_tanpa_komentar(FileAccess.get_file_as_string(BERKAS_AUDIO))
	check(not kode.is_empty(), "audio.gd terbaca")
	var dilarang: Array[String] = []
	for nama: String in nama_autoload + AUTOLOAD_RENCANA:
		if RegEx.create_from_string("\\b%s\\b" % nama).search(kode) != null:
			dilarang.append(nama)
	check(dilarang.is_empty(), "audio.gd tidak merujuk autoload (termasuk dirinya sendiri dan yang direncanakan TECH_PLAN 3.1): %s" % [dilarang])
	check(kode.find("/root/") == -1 and kode.find("get_tree().root") == -1, "audio.gd tidak mencari node lain lewat /root")
	# Pemeriksa harus menangkap pelanggaran (bukan lolos kosong).
	check(RegEx.create_from_string("\\bSaveManager\\b").search(_kode_tanpa_komentar("\tSaveManager.simpan()\n")) != null, "pemeriksa menangkap rujukan SaveManager (mutan)")
	check(RegEx.create_from_string("\\bSaveManager\\b").search(_kode_tanpa_komentar("## SaveManager di komentar\n")) == null, "rujukan di komentar tidak dihitung")


## Teks skrip tanpa komentar (baris `#`/`##` dan ujung baris sesudah `#` di luar teks berkutip sederhana).
func _kode_tanpa_komentar(teks: String) -> String:
	var hasil: PackedStringArray = PackedStringArray()
	for baris: String in teks.split("\n"):
		var potong: int = baris.find("#")
		hasil.append(baris if potong < 0 else baris.substr(0, potong))
	return "\n".join(hasil)


# --- Bus audio ---

func _test_bus() -> void:
	_judul.call("Bus audio: Sepeda -> SFX -> Master (SOUND_DESIGN 6, AC-4)")
	check(ProjectSettings.get_setting("audio/buses/default_bus_layout", "") == BERKAS_BUS and FileAccess.file_exists(BERKAS_BUS), "default_bus_layout.tres ada dan dipakai proyek")
	var tata: AudioBusLayout = load(BERKAS_BUS) as AudioBusLayout
	check(tata != null, "default_bus_layout.tres termuat sebagai AudioBusLayout")
	var sfx: int = AudioServer.get_bus_index(&"SFX")
	var sepeda: int = AudioServer.get_bus_index(&"Sepeda")
	check(AudioServer.get_bus_name(0) == &"Master", "bus 0 = Master")
	check(sfx > 0 and AudioServer.get_bus_send(sfx) == &"Master", "bus SFX ada dan dikirim ke Master")
	check(sepeda > sfx and AudioServer.get_bus_send(sepeda) == &"SFX", "bus Sepeda ada (sesudah SFX) dan dikirim ke SFX")
	check(AudioServer.bus_count == 3, "hanya Master, SFX, Sepeda (Ambience, Musik, UI belum perlu; tanpa musik), dapat %d bus" % AudioServer.bus_count)
	for i: int in range(AudioServer.bus_count):
		check(not AudioServer.is_bus_mute(i) and AudioServer.get_bus_volume_db(i) == 0.0 and AudioServer.get_bus_effect_count(i) == 0, "bus %s: tidak diredam, 0 dB, tanpa efek" % AudioServer.get_bus_name(i))


# --- Stream ---

func _test_stream() -> void:
	_judul.call("Stream bunyi sepeda: WAV 16-bit mono, dua loop, satu sekali putar (AC-4, AC-5, SOUND_DESIGN 6)")
	# [berkas, loop, durasi min, durasi maks]
	var daftar: Array = [
		["sfx_bike_pedal_loop.wav", true, 1.0, 1.0],
		["sfx_bike_freewheel_loop.wav", true, 1.0, 1.0],
		["sfx_bike_brake_01.wav", false, 0.3, 0.6],
	]
	for baris: Array in daftar:
		var jalur: String = FOLDER_BUNYI + str(baris[0])
		var s: AudioStreamWAV = load(jalur) as AudioStreamWAV
		check(s != null, "%s termuat sebagai AudioStreamWAV" % baris[0])
		if s == null:
			continue
		var frame: int = s.data.size() / 2
		check(s.format == AudioStreamWAV.FORMAT_16_BITS and not s.stereo and s.mix_rate == LAJU_SAMPEL, "%s: PCM 16-bit mono %d Hz (impor tanpa kompresi)" % [baris[0], LAJU_SAMPEL])
		var durasi: float = float(frame) / float(LAJU_SAMPEL)
		check(durasi >= float(baris[2]) - TOL and durasi <= float(baris[3]) + TOL and absf(s.get_length() - durasi) < 0.001, "%s: durasi %.3f detik (%s..%s)" % [baris[0], durasi, baris[2], baris[3]])
		var impor: String = FileAccess.get_file_as_string(jalur + ".import")
		check(impor.contains("compress/mode=0"), "%s.import: compress/mode=0 (PCM, sama persis dengan WAV hasil skrip)" % baris[0])
		if baris[1]:
			check(s.loop_mode == AudioStreamWAV.LOOP_FORWARD and s.loop_begin == 0 and s.loop_end >= frame - 1, "%s: loop maju dari sampel 0 sampai ujung (%d..%d dari %d)" % [baris[0], s.loop_begin, s.loop_end, frame])
			check(impor.contains("edit/loop_mode=2"), "%s.import: edit/loop_mode=2 (Forward)" % baris[0])
		else:
			check(s.loop_mode == AudioStreamWAV.LOOP_DISABLED, "%s: sekali putar (tanpa loop)" % baris[0])
			check(impor.contains("edit/loop_mode=1"), "%s.import: edit/loop_mode=1 (Disabled)" % baris[0])


## Dua loop benar-benar berulang dan decit rem berhenti sendiri: diputar sungguhan sekitar 1,3 detik (lebih dari satu putaran loop).
func _test_loop_sungguhan() -> void:
	_judul.call("Stream bunyi sepeda diputar: loop tetap berbunyi lewat ujungnya, decit rem berhenti sendiri (AC-4)")
	var audio: Node = _tree.root.get_node_or_null(^"Audio")
	if audio == null:
		check(false, "autoload Audio ada")
		return
	var kayuh: AudioStreamPlayer = audio.call("pemutar_kayuh")
	var freewheel: AudioStreamPlayer = audio.call("pemutar_freewheel")
	var rem: AudioStreamPlayer = audio.call("pemutar_rem")
	kayuh.play()
	freewheel.play()
	rem.play()
	await _tree.process_frame
	check(kayuh.playing and freewheel.playing and rem.playing, "ketiga stream mulai berbunyi")
	var mulai: int = Time.get_ticks_msec()
	var rem_berhenti_ms: int = -1
	while Time.get_ticks_msec() - mulai < 1300:
		await _tree.process_frame
		if rem_berhenti_ms < 0 and not rem.playing:
			rem_berhenti_ms = Time.get_ticks_msec() - mulai
	check(kayuh.playing and freewheel.playing, "sesudah 1,3 detik (lebih dari loop 1,0 detik) kedua loop masih berbunyi")
	check(kayuh.get_playback_position() < 0.6 and freewheel.get_playback_position() < 0.6, "posisi kedua loop kembali ke awal (%.2f, %.2f detik)" % [kayuh.get_playback_position(), freewheel.get_playback_position()])
	check(rem_berhenti_ms > 0 and rem_berhenti_ms < 1000, "decit rem berhenti sendiri (sekitar 0,45 detik), dapat %d ms" % rem_berhenti_ms)
	audio.call("hentikan_sepeda")
	await _tree.process_frame
	check(not audio.call("ada_bunyi"), "hentikan_sepeda menghentikan semua")
	# perbarui_sepeda sendiri (tanpa atur_jeda) juga menghentikan decit dan loop saat jeda.
	audio.call("perbarui_sepeda", LoperAnim.Pose.KAYUH, 4.0, false, false)
	audio.call("perbarui_sepeda", LoperAnim.Pose.REM, 4.0, true, false)
	check(rem.playing and not kayuh.playing, "perbarui_sepeda: tepi naik rem memutar decit, loop diam")
	audio.call("perbarui_sepeda", LoperAnim.Pose.REM, 4.0, true, true)
	check(not audio.call("ada_bunyi"), "perbarui_sepeda dengan jeda (tanpa atur_jeda): decit dan loop berhenti")
	audio.call("hentikan_sepeda")


# --- Jalur berhenti milik Audio sendiri (QA-001 Q02 run fase1b-umpan-balik) ---

## `Audio._notification` menghentikan semua pemutar pada `APPLICATION_PAUSED`, `APPLICATION_FOCUS_OUT`, dan `WM_CLOSE_REQUEST` lewat
## jalurnya sendiri: instans baru di pohon tanpa `JalanUji` (tidak ada sinyal `jeda_berubah`, tidak ada `atur_jeda`). Tiap notifikasi
## dites dengan instans tersendiri supaya mutan yang menghapus salah satunya mati.
func _test_notifikasi_sendiri() -> void:
	_judul.call("Audio berhenti sendiri pada PAUSED, FOCUS_OUT, dan tutup jendela, tanpa JalanUji (QA-001 Q02, rule gdscript)")
	var skrip: GDScript = load(BERKAS_AUDIO) as GDScript
	var kasus: Array = [
		["APPLICATION_PAUSED", Node.NOTIFICATION_APPLICATION_PAUSED],
		["APPLICATION_FOCUS_OUT", Node.NOTIFICATION_APPLICATION_FOCUS_OUT],
		["WM_CLOSE_REQUEST", Node.NOTIFICATION_WM_CLOSE_REQUEST],
	]
	for baris: Array in kasus:
		var nama: String = baris[0]
		var notifikasi: int = baris[1]
		var audio: Node = skrip.new() as Node
		audio.name = "AudioUjiNotifikasi"
		audio.set(&"putar_di_driver_dummy", true)
		_tree.root.add_child(audio)
		audio.call(&"perbarui_sepeda", LoperAnim.Pose.KAYUH, 4.0, false, false)
		(audio.call(&"pemutar_freewheel") as AudioStreamPlayer).play()
		(audio.call(&"pemutar_rem") as AudioStreamPlayer).play()
		var kayuh: AudioStreamPlayer = audio.call(&"pemutar_kayuh")
		var freewheel: AudioStreamPlayer = audio.call(&"pemutar_freewheel")
		var rem: AudioStreamPlayer = audio.call(&"pemutar_rem")
		check(kayuh.playing and freewheel.playing and rem.playing and not audio.call(&"sedang_jeda"), "%s: kontrol: sebelum notifikasi ketiga pemutar berbunyi, tanpa jeda dari pemanggil" % nama)
		audio.propagate_notification(notifikasi)
		check(not kayuh.playing and not freewheel.playing and not rem.playing and not audio.call(&"ada_bunyi"), "%s: semua pemutar sepeda berhenti lewat Audio._notification sendiri (tanpa JalanUji dan jeda_berubah)" % nama)
		_tree.root.remove_child(audio)
		audio.free()
	await _tree.process_frame


# --- Scene: bunyi mengikuti gerak, rem sekali, jeda diam ---

func _test_scene() -> void:
	_judul.call("Bunyi di jalan_uji.tscn: kayuh/freewheel/rem dari keadaan sebenarnya, jeda diam (AC-4, AC-7, D-5)")
	var audio: Node = _tree.root.get_node_or_null(^"Audio")
	if audio == null:
		check(false, "autoload Audio ada")
		return
	var kayuh: AudioStreamPlayer = audio.call("pemutar_kayuh")
	var freewheel: AudioStreamPlayer = audio.call("pemutar_freewheel")
	var rem: AudioStreamPlayer = audio.call("pemutar_rem")
	_tree.root.size = Vector2i(2340, 1080)
	var akar: JalanUji = (load(BERKAS_JALAN_UJI) as PackedScene).instantiate() as JalanUji
	_tree.root.add_child(akar)
	await _tree.process_frame
	await _tree.process_frame
	akar.set_process(false)
	var kontrol: KontrolTouch = akar.find_child("KontrolTouch", true, false) as KontrolTouch
	kontrol.keyboard_aktif = false
	var sepeda: SepedaUji = akar.find_child("Sepeda", true, false) as SepedaUji
	var jumlah_awal: int = audio.call("jumlah_rem_dipicu")
	_langkah(akar, 30)
	check(sepeda.kecepatan_ud == 3.0 and kayuh.playing and not freewheel.playing and not rem.playing and kayuh.pitch_scale == 1.0, "santai: loop kayuh berbunyi, pitch 1,0")
	_sentuh(0, TITIK_STICK, true)
	_geser(0, TITIK_STICK - Vector2(0, Config.STICK_RADIUS_PX))
	_langkah(akar, 30)
	var pitch_naik: float = kayuh.pitch_scale
	check(sepeda.kecepatan_ud > 3.0 and sepeda.kecepatan_ud < 6.0 and absf(pitch_naik - BunyiSepeda.pitch_kayuh(sepeda.kecepatan_ud)) < 0.0001 and pitch_naik > 1.0 and pitch_naik < 1.3, "mempercepat (%.2f u/d): pitch mengikuti kecepatan sebenarnya (%.3f)" % [sepeda.kecepatan_ud, pitch_naik])
	_langkah(akar, 60)
	check(sepeda.kecepatan_ud == 6.0 and kayuh.playing and absf(kayuh.pitch_scale - 1.3) < 0.0001, "ngebut: loop kayuh, pitch 1,3 (presisi tunggal), dapat %s" % kayuh.pitch_scale)
	# Bawah sebagian: meluncur (kecepatan turun tanpa mengayuh) = freewheel.
	_geser(0, TITIK_STICK + Vector2(0, Config.STICK_RADIUS_PX * 0.6))
	_langkah(akar, 10)
	check(sepeda.pose() == LoperAnim.Pose.MELUNCUR and freewheel.playing and not kayuh.playing, "meluncur: loop freewheel, kayuhan berhenti")
	# Bawah penuh ditahan: rem aktif sesudah 0,25 detik; decit sekali, loop diam.
	_geser(0, TITIK_STICK + Vector2(0, Config.STICK_RADIUS_PX))
	_langkah(akar, 14)
	check(not sepeda.rem_aktif() and audio.call("jumlah_rem_dipicu") == jumlah_awal, "bawah penuh 14 langkah: rem belum aktif, decit belum")
	_langkah(akar, 1)
	check(sepeda.rem_aktif() and audio.call("jumlah_rem_dipicu") == jumlah_awal + 1 and rem.playing and not kayuh.playing and not freewheel.playing, "rem aktif: decit dipicu sekali, loop diam")
	_langkah(akar, 90)
	check(sepeda.rem_aktif() and sepeda.kecepatan_ud == 0.0 and audio.call("jumlah_rem_dipicu") == jumlah_awal + 1, "rem ditahan 90 langkah sampai berhenti: decit tidak diulang tiap langkah")
	check(not kayuh.playing and not freewheel.playing, "berhenti dengan rem: loop tetap diam")
	# Lepas: rem padam, kayuh lagi; tahan lagi: decit lagi.
	_sentuh(0, TITIK_STICK + Vector2(0, Config.STICK_RADIUS_PX), false)
	_langkah(akar, 30)
	check(not sepeda.rem_aktif() and sepeda.kecepatan_ud > 0.0 and kayuh.playing, "rem dilepas: kayuh lagi")
	_sentuh(0, TITIK_STICK, true)
	_geser(0, TITIK_STICK + Vector2(0, Config.STICK_RADIUS_PX))
	_langkah(akar, 15)
	check(sepeda.rem_aktif() and audio.call("jumlah_rem_dipicu") == jumlah_awal + 2 and rem.playing, "rem padam lalu aktif lagi: decit dipicu lagi")
	# Jeda saat decit masih berbunyi: semua berhenti, termasuk decit.
	akar.minta_jeda()
	check(audio.call("sedang_jeda") and not kayuh.playing and not freewheel.playing and not rem.playing and not audio.call("ada_bunyi"), "jeda: semua bunyi sepeda berhenti, termasuk decit rem yang sedang berbunyi")
	await _tree.process_frame
	await _tree.process_frame
	check(not audio.call("ada_bunyi"), "jeda: tetap diam sesudah frame berjalan")
	for i: int in range(5):
		akar.perbarui(0.1)
	check(not audio.call("ada_bunyi"), "jeda: perbarui dengan dt besar tidak menyalakan bunyi")
	_sentuh(0, TITIK_STICK, false)
	akar.minta_lanjut()
	await _tree.process_frame
	check(not rem.playing and audio.call("jumlah_rem_dipicu") == jumlah_awal + 2, "lanjut: tidak ada decit rem lama yang menyusul")
	_langkah(akar, 2)
	check(not audio.call("sedang_jeda") and not rem.playing and audio.call("jumlah_rem_dipicu") == jumlah_awal + 2, "langkah sesudah lanjut: bunyi dari keadaan sekarang, tanpa decit")
	_langkah(akar, 20)
	check(kayuh.playing and sepeda.kecepatan_ud > 0.0, "sesudah lanjut sepeda jalan lagi: loop kayuh berbunyi")
	# Background lewat notifikasi: jeda, semua berhenti.
	_tree.root.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(akar.sedang_jeda() and not audio.call("ada_bunyi"), "FOCUS_OUT: layar jeda dan semua bunyi berhenti")
	_tree.root.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	_langkah(akar, 5)
	check(not audio.call("ada_bunyi"), "FOCUS_IN tanpa Lanjut: tetap diam")
	akar.minta_lanjut()
	_langkah(akar, 5)
	check(kayuh.playing, "Lanjut sesudah background: kayuh lagi")
	# Scene dibuang: bunyi berhenti.
	kontrol.keyboard_aktif = OS.has_feature("editor")
	_tree.root.remove_child(akar)
	akar.free()
	check(not audio.call("ada_bunyi") and audio.call("loop_aktif") == BunyiSepeda.Loop.DIAM, "scene dibuang: semua bunyi sepeda berhenti")
	await _tree.process_frame


func _langkah(akar: JalanUji, jumlah: int) -> void:
	for i: int in range(jumlah):
		akar.perbarui(DT)


func _sentuh(index: int, posisi_viewport: Vector2, tekan: bool) -> void:
	var peristiwa: InputEventScreenTouch = InputEventScreenTouch.new()
	peristiwa.index = index
	peristiwa.position = posisi_viewport * float(SKALA)
	peristiwa.pressed = tekan
	Input.parse_input_event(peristiwa)
	Input.flush_buffered_events()


func _geser(index: int, posisi_viewport: Vector2) -> void:
	var peristiwa: InputEventScreenDrag = InputEventScreenDrag.new()
	peristiwa.index = index
	peristiwa.position = posisi_viewport * float(SKALA)
	Input.parse_input_event(peristiwa)
	Input.flush_buffered_events()
