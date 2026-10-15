class_name TesBunyiLempar
extends RefCounted
## Tes bunyi lempar dan mendarat run fase2b-bantu-audio (AC-9 sisi Godot, AC-10, AC-11, AC-12; D-9 sampai D-12).
## - Murni (`BunyiLempar`): tiap `ZonaSasaran.Hasil` x sakelar jendela -> permukaan, giliran variasi 01 -> 02 -> 03 -> 01 per permukaan,
##   berkas yang dirujuk ada dan terimpor PCM sekali putar, meleset lebih pelan. Oracle ditulis eksplisit di sini (tabel dan nama berkas),
##   bukan dipanggil dari kode yang dites.
## - Autoload `Audio`: pemutar di bus `SFX` dengan volume dari `Config`, giliran independen antar permukaan, tidak ada bunyi baru selama
##   jeda, jeda/background menghentikan "wus" dan bunyi mendarat seketika (stream sungguhan di driver Dummy, `putar_di_driver_dummy`).
## - Scene `jalan_uji.tscn`: tepat satu "wus" per lemparan diterima (swipe dan tap), tidak ada untuk lemparan ditolak (pendek, jeda antar
##   lempar, habis, jeda game, tanpa sasaran, mode bantu mati), tepat satu bunyi mendarat per koran dengan permukaan sesuai hasil, dua
##   koran = dua bunyi bergiliran, jeda menghentikan bunyi seketika tanpa diputar ulang sesudah lanjut.

const BERKAS_JALAN_UJI: String = "res://scenes/dev/jalan_uji.tscn"
const BERKAS_AUDIO: String = "res://scripts/autoload/audio.gd"
const FOLDER: String = "res://assets/audio/sfx/throw/"
const SKALA: int = 3
const DT: float = 1.0 / 60.0
const LEBAR: float = 780.0
const LAJU_SAMPEL: int = 22050
const TOL: float = 0.000001
## Nama permukaan di nama berkas (SOUND_DESIGN 6), ditulis eksplisit per `BunyiLempar.Permukaan`.
const NAMA_PERMUKAAN: Dictionary = {
	BunyiLempar.Permukaan.KOTAK_SURAT: "mailbox",
	BunyiLempar.Permukaan.TERAS: "porch",
	BunyiLempar.Permukaan.RUMPUT: "grass",
	BunyiLempar.Permukaan.MELESET: "miss",
}
## Oracle D-10: [hasil, sakelar jendela, permukaan yang diharapkan].
const TABEL_PERMUKAAN: Array = [
	[ZonaSasaran.Hasil.KOTAK_SURAT, false, BunyiLempar.Permukaan.KOTAK_SURAT],
	[ZonaSasaran.Hasil.KOTAK_SURAT, true, BunyiLempar.Permukaan.KOTAK_SURAT],
	[ZonaSasaran.Hasil.TERAS, false, BunyiLempar.Permukaan.TERAS],
	[ZonaSasaran.Hasil.TERAS, true, BunyiLempar.Permukaan.TERAS],
	[ZonaSasaran.Hasil.HALAMAN, false, BunyiLempar.Permukaan.RUMPUT],
	[ZonaSasaran.Hasil.HALAMAN, true, BunyiLempar.Permukaan.RUMPUT],
	[ZonaSasaran.Hasil.MELESET, false, BunyiLempar.Permukaan.MELESET],
	[ZonaSasaran.Hasil.MELESET, true, BunyiLempar.Permukaan.MELESET],
	[ZonaSasaran.Hasil.BUKAN_PELANGGAN, false, BunyiLempar.Permukaan.MELESET],
	[ZonaSasaran.Hasil.BUKAN_PELANGGAN, true, BunyiLempar.Permukaan.MELESET],
	[ZonaSasaran.Hasil.JENDELA, false, BunyiLempar.Permukaan.MELESET],
	[ZonaSasaran.Hasil.JENDELA, true, BunyiLempar.Permukaan.TERAS],
]
## Oracle hasil -> nama permukaan di berkas untuk koran yang mendarat di scene (sakelar jendela bawaan false = penalti).
const NAMA_HASIL_PENALTI: Dictionary = {
	ZonaSasaran.Hasil.KOTAK_SURAT: "mailbox",
	ZonaSasaran.Hasil.TERAS: "porch",
	ZonaSasaran.Hasil.HALAMAN: "grass",
	ZonaSasaran.Hasil.MELESET: "miss",
	ZonaSasaran.Hasil.BUKAN_PELANGGAN: "miss",
	ZonaSasaran.Hasil.JENDELA: "miss",
}

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
	_test_permukaan()
	_test_variasi()
	_test_berkas()
	_test_autoload_tanpa_tree()
	await _test_pemutar_sungguhan()
	await _test_notifikasi_sendiri()
	await _test_scene_wus()
	await _test_scene_mendarat()
	await _test_scene_jendela()
	await _test_scene_jeda()


# --- Murni ---

func _test_config() -> void:
	_judul.call("Bunyi lempar: volume di Config (D-11, SOUND_DESIGN 6, usulan)")
	check(Config.AUDIO_WUS_VOLUME_DB == -4.0 and Config.AUDIO_MENDARAT_VOLUME_DB == -1.0, "volume wus -4 dB, mendarat -1 dB (BALANCING 2, usulan)")
	check(Config.AUDIO_MENDARAT_VOLUME_DB > Config.AUDIO_KAYUH_VOLUME_DB and Config.AUDIO_MENDARAT_VOLUME_DB <= 0.0, "mendarat di atas kayuhan dan tidak di atas 0 dB (SOUND_DESIGN 6 Level)")


func _test_permukaan() -> void:
	_judul.call("BunyiLempar.permukaan: tiap hasil x sakelar jendela (AC-10, D-10)")
	var semua_hasil: Array = []
	for baris: Array in TABEL_PERMUKAAN:
		var hasil: ZonaSasaran.Hasil = baris[0]
		var bonus: bool = baris[1]
		var harapan: BunyiLempar.Permukaan = baris[2]
		if not semua_hasil.has(hasil):
			semua_hasil.append(hasil)
		check(BunyiLempar.permukaan(hasil, bonus) == harapan, "%s, jendela bonus %s -> %s" % [ZonaSasaran.Hasil.keys()[hasil], bonus, BunyiLempar.Permukaan.keys()[harapan]])
	check(semua_hasil.size() == ZonaSasaran.Hasil.size(), "tabel oracle mencakup semua %d hasil" % ZonaSasaran.Hasil.size())
	# Permukaan tertukar terdeteksi: empat permukaan semuanya terpakai dan berbeda.
	var dipakai: Dictionary = {}
	for baris: Array in TABEL_PERMUKAAN:
		dipakai[BunyiLempar.permukaan(baris[0], baris[1])] = true
	check(dipakai.size() == 4, "keempat permukaan dipakai oleh pemetaan (%d)" % dipakai.size())


func _test_variasi() -> void:
	_judul.call("BunyiLempar: variasi bergiliran 01 -> 02 -> 03 -> 01 per permukaan, tanpa RNG (AC-10, D-10)")
	var urutan: Array[int] = [1, 2, 3, 1, 2, 3, 1]
	for p: BunyiLempar.Permukaan in NAMA_PERMUKAAN:
		var nama: String = NAMA_PERMUKAAN[p]
		check(BunyiLempar.jumlah_variasi(p) == 3, "%s: tiga variasi" % nama)
		var giliran: int = 0
		var benar: bool = true
		var dapat: Array[String] = []
		for i: int in range(urutan.size()):
			var harapan: String = "sfx_land_%s_0%d.wav" % [nama, urutan[i]]
			var berkas: String = BunyiLempar.berkas_mendarat(p, giliran)
			dapat.append(berkas.get_file())
			if berkas != FOLDER + harapan:
				benar = false
			giliran = BunyiLempar.giliran_berikut(p, giliran)
		check(benar, "%s: tujuh giliran = 01 02 03 01 02 03 01, dapat %s" % [nama, dapat])
		check(BunyiLempar.giliran_berikut(p, 0) == 1 and BunyiLempar.giliran_berikut(p, 1) == 2 and BunyiLempar.giliran_berikut(p, 2) == 0, "%s: giliran 0 -> 1 -> 2 -> 0" % nama)
		check(BunyiLempar.berkas_mendarat(p, -1) == FOLDER + "sfx_land_%s_03.wav" % nama and BunyiLempar.berkas_mendarat(p, 4) == FOLDER + "sfx_land_%s_02.wav" % nama, "%s: giliran di luar rentang dibungkus (-1 = 03, 4 = 02)" % nama)
	check(BunyiLempar.BERKAS_WUS == FOLDER + "sfx_throw_whoosh_01.wav", "berkas wus = sfx_throw_whoosh_01.wav")
	# Tanpa RNG: modul tidak memanggil acak.
	var kode: String = FileAccess.get_file_as_string("res://scripts/systems/bunyi_lempar.gd")
	check(not kode.is_empty() and not RegEx.create_from_string("\\b(randi|randf|RandomNumberGenerator|randomize)\\b").search(kode), "bunyi_lempar.gd tanpa RNG")


func _test_berkas() -> void:
	_judul.call("Berkas bunyi lempar: 13 WAV ada, PCM 16-bit mono 22050 Hz sekali putar, meleset lebih pelan (AC-9, AC-10, D-9)")
	var semua: Array[String] = BunyiLempar.semua_berkas()
	var harapan: Array[String] = [FOLDER + "sfx_throw_whoosh_01.wav"]
	for nama: String in ["mailbox", "porch", "grass", "miss"]:
		for v: int in [1, 2, 3]:
			harapan.append(FOLDER + "sfx_land_%s_0%d.wav" % [nama, v])
	check(semua == harapan, "semua_berkas = wus + 4 permukaan x 3 variasi, urut (%d berkas)" % semua.size())
	# [nama permukaan, durasi min, durasi maks] (D-9).
	var rentang: Dictionary = {"whoosh": [0.15, 0.25], "mailbox": [0.15, 0.25], "porch": [0.15, 0.25], "grass": [0.15, 0.20], "miss": [0.12, 0.18]}
	var puncak_miss: int = 0
	var puncak_lain: int = 32768
	for jalur: String in harapan:
		var s: AudioStreamWAV = load(jalur) as AudioStreamWAV
		check(s != null, "%s termuat sebagai AudioStreamWAV" % jalur.get_file())
		if s == null:
			continue
		check(s.format == AudioStreamWAV.FORMAT_16_BITS and not s.stereo and s.mix_rate == LAJU_SAMPEL and s.loop_mode == AudioStreamWAV.LOOP_DISABLED, "%s: PCM 16-bit mono %d Hz, sekali putar" % [jalur.get_file(), LAJU_SAMPEL])
		var impor: String = FileAccess.get_file_as_string(jalur + ".import")
		check(impor.contains("compress/mode=0") and impor.contains("edit/loop_mode=1"), "%s.import: compress/mode=0, edit/loop_mode=1" % jalur.get_file())
		var jenis: String = "whoosh" if jalur.contains("whoosh") else jalur.get_file().split("_")[2]
		var durasi: float = float(s.data.size() / 2) / float(LAJU_SAMPEL)
		var batas: Array = rentang[jenis]
		check(durasi >= float(batas[0]) - TOL and durasi <= float(batas[1]) + TOL, "%s: durasi %.3f detik (%s..%s)" % [jalur.get_file(), durasi, batas[0], batas[1]])
		var puncak: int = 0
		for i: int in range(0, s.data.size(), 2):
			puncak = maxi(puncak, absi(s.data.decode_s16(i)))
		if jenis == "miss":
			puncak_miss = maxi(puncak_miss, puncak)
		elif jenis != "whoosh":
			puncak_lain = mini(puncak_lain, puncak)
	check(puncak_miss > 0 and puncak_miss < puncak_lain, "puncak meleset (%d) di bawah puncak permukaan lain terpelan (%d)" % [puncak_miss, puncak_lain])


# --- Autoload tanpa tree ---

func _test_autoload_tanpa_tree() -> void:
	_judul.call("Audio: pemutar lempar/mendarat di bus SFX, giliran per permukaan, diam selama jeda (AC-10, D-10, D-12)")
	var audio: Node = (load(BERKAS_AUDIO) as GDScript).new() as Node
	var wus: AudioStreamPlayer = audio.call(&"pemutar_wus")
	check(wus != null and wus.bus == &"SFX" and wus.stream.resource_path == FOLDER + "sfx_throw_whoosh_01.wav" and wus.volume_db == Config.AUDIO_WUS_VOLUME_DB, "pemutar wus: bus SFX, stream wus, volume Config")
	var semua_benar: bool = true
	for nama: String in ["mailbox", "porch", "grass", "miss"]:
		for v: int in [1, 2, 3]:
			var jalur: String = FOLDER + "sfx_land_%s_0%d.wav" % [nama, v]
			var p: AudioStreamPlayer = audio.call(&"pemutar_mendarat", jalur)
			if p == null or p.bus != &"SFX" or p.stream.resource_path != jalur or p.volume_db != Config.AUDIO_MENDARAT_VOLUME_DB or p.get_parent() != audio:
				semua_benar = false
	check(semua_benar, "12 pemutar mendarat: anak Audio, bus SFX, satu berkas masing-masing, volume Config")
	audio.call(&"atur_ulang_lempar")
	# Urutan campuran: giliran tiap permukaan independen.
	var urutan: Array = [
		[ZonaSasaran.Hasil.KOTAK_SURAT, false, "sfx_land_mailbox_01.wav"],
		[ZonaSasaran.Hasil.KOTAK_SURAT, false, "sfx_land_mailbox_02.wav"],
		[ZonaSasaran.Hasil.TERAS, false, "sfx_land_porch_01.wav"],
		[ZonaSasaran.Hasil.KOTAK_SURAT, false, "sfx_land_mailbox_03.wav"],
		[ZonaSasaran.Hasil.HALAMAN, false, "sfx_land_grass_01.wav"],
		[ZonaSasaran.Hasil.KOTAK_SURAT, false, "sfx_land_mailbox_01.wav"],
		[ZonaSasaran.Hasil.JENDELA, false, "sfx_land_miss_01.wav"],
		[ZonaSasaran.Hasil.JENDELA, true, "sfx_land_porch_02.wav"],
		[ZonaSasaran.Hasil.BUKAN_PELANGGAN, true, "sfx_land_miss_02.wav"],
		[ZonaSasaran.Hasil.MELESET, false, "sfx_land_miss_03.wav"],
		[ZonaSasaran.Hasil.TERAS, true, "sfx_land_porch_03.wav"],
		[ZonaSasaran.Hasil.MELESET, true, "sfx_land_miss_01.wav"],
	]
	var dapat: Array[String] = []
	var benar: bool = true
	for baris: Array in urutan:
		audio.call(&"putar_mendarat", baris[0], baris[1])
		var terakhir: String = audio.call(&"mendarat_terakhir")
		dapat.append(terakhir.get_file())
		if terakhir != FOLDER + str(baris[2]):
			benar = false
	check(benar, "12 pendaratan campuran: giliran per permukaan independen, dapat %s" % [dapat])
	check(audio.call(&"jumlah_mendarat") == urutan.size() and audio.call(&"jumlah_wus") == 0, "jumlah bunyi mendarat = jumlah pendaratan (%d), tanpa wus" % urutan.size())
	audio.call(&"putar_lempar")
	audio.call(&"putar_lempar")
	check(audio.call(&"jumlah_wus") == 2, "dua lemparan diterima = dua wus")
	check(not audio.call(&"ada_bunyi_lempar"), "tanpa tree: tidak ada stream yang diputar")
	# Jeda: tidak ada bunyi baru, giliran tidak maju.
	audio.call(&"atur_jeda", true)
	audio.call(&"putar_lempar")
	audio.call(&"putar_mendarat", ZonaSasaran.Hasil.KOTAK_SURAT, false)
	check(audio.call(&"jumlah_wus") == 2 and audio.call(&"jumlah_mendarat") == urutan.size(), "selama jeda: tidak ada wus atau bunyi mendarat baru")
	audio.call(&"atur_jeda", false)
	audio.call(&"putar_mendarat", ZonaSasaran.Hasil.KOTAK_SURAT, false)
	check(audio.call(&"mendarat_terakhir") == FOLDER + "sfx_land_mailbox_02.wav", "sesudah jeda giliran berlanjut (mailbox 02), tidak dimakan jeda")
	audio.call(&"atur_ulang_lempar")
	audio.call(&"putar_mendarat", ZonaSasaran.Hasil.KOTAK_SURAT, false)
	check(audio.call(&"mendarat_terakhir") == FOLDER + "sfx_land_mailbox_01.wav" and audio.call(&"jumlah_mendarat") == 1, "atur_ulang_lempar mengembalikan giliran ke 01")
	audio.free()


# --- Pemutar sungguhan (driver Dummy) ---

func _test_pemutar_sungguhan() -> void:
	_judul.call("Audio di tree: wus dan bunyi mendarat berbunyi, berhenti sendiri, jeda menghentikan seketika (AC-12, D-12)")
	var audio: Node = _tree.root.get_node_or_null(^"Audio")
	if audio == null:
		check(false, "autoload Audio ada")
		return
	audio.call(&"atur_ulang_lempar")
	var wus: AudioStreamPlayer = audio.call(&"pemutar_wus")
	var kotak: AudioStreamPlayer = audio.call(&"pemutar_mendarat", FOLDER + "sfx_land_mailbox_01.wav")
	audio.call(&"putar_lempar")
	audio.call(&"putar_mendarat", ZonaSasaran.Hasil.KOTAK_SURAT, false)
	check(wus.playing and kotak.playing and audio.call(&"ada_bunyi_lempar"), "wus dan mendarat kotak surat 01 berbunyi")
	# Sekali putar: berhenti sendiri (wus 0,20 detik, kotak surat 0,17 detik).
	var mulai: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - mulai < 600 and audio.call(&"ada_bunyi_lempar"):
		await _tree.process_frame
	check(not audio.call(&"ada_bunyi_lempar"), "wus dan bunyi mendarat berhenti sendiri (sekali putar), %d ms" % (Time.get_ticks_msec() - mulai))
	# Jeda lewat atur_jeda: berhenti seketika.
	audio.call(&"putar_lempar")
	audio.call(&"putar_mendarat", ZonaSasaran.Hasil.HALAMAN, false)
	check(audio.call(&"ada_bunyi_lempar"), "kontrol: wus dan rumput berbunyi sebelum jeda")
	audio.call(&"atur_jeda", true)
	check(not wus.playing and not audio.call(&"ada_bunyi_lempar"), "atur_jeda(true): wus dan bunyi mendarat berhenti seketika")
	await _tree.process_frame
	audio.call(&"atur_jeda", false)
	await _tree.process_frame
	await _tree.process_frame
	check(not audio.call(&"ada_bunyi_lempar"), "sesudah lanjut: bunyi lama tidak diputar ulang")
	# Jeda lewat perbarui_sepeda(jeda = true) juga menghentikan.
	audio.call(&"putar_lempar")
	audio.call(&"putar_mendarat", ZonaSasaran.Hasil.TERAS, false)
	audio.call(&"perbarui_sepeda", LoperAnim.Pose.KAYUH, 3.0, false, true)
	check(not audio.call(&"ada_bunyi_lempar"), "perbarui_sepeda dengan jeda: bunyi lempar/mendarat berhenti")
	audio.call(&"perbarui_sepeda", LoperAnim.Pose.KAYUH, 3.0, false, false)
	audio.call(&"putar_mendarat", ZonaSasaran.Hasil.MELESET, false)
	audio.call(&"hentikan_lempar")
	check(not audio.call(&"ada_bunyi_lempar"), "hentikan_lempar menghentikan semua")
	audio.call(&"hentikan_sepeda")
	await _tree.process_frame


## `Audio._notification` menghentikan bunyi lempar/mendarat pada PAUSED, FOCUS_OUT, dan tutup jendela lewat jalurnya sendiri (instans
## tersendiri tanpa `JalanUji`, seperti tes bunyi sepeda).
func _test_notifikasi_sendiri() -> void:
	_judul.call("Audio menghentikan wus dan bunyi mendarat sendiri pada PAUSED, FOCUS_OUT, dan tutup jendela (AC-12, D-12)")
	var skrip: GDScript = load(BERKAS_AUDIO) as GDScript
	var kasus: Array = [
		["APPLICATION_PAUSED", Node.NOTIFICATION_APPLICATION_PAUSED],
		["APPLICATION_FOCUS_OUT", Node.NOTIFICATION_APPLICATION_FOCUS_OUT],
		["WM_CLOSE_REQUEST", Node.NOTIFICATION_WM_CLOSE_REQUEST],
	]
	for baris: Array in kasus:
		var nama: String = baris[0]
		var audio: Node = skrip.new() as Node
		audio.name = "AudioUjiLempar"
		audio.set(&"putar_di_driver_dummy", true)
		_tree.root.add_child(audio)
		audio.call(&"putar_lempar")
		audio.call(&"putar_mendarat", ZonaSasaran.Hasil.TERAS, false)
		check(audio.call(&"ada_bunyi_lempar") and (audio.call(&"pemutar_wus") as AudioStreamPlayer).playing, "%s: kontrol: wus dan bunyi teras berbunyi" % nama)
		audio.propagate_notification(baris[1])
		check(not audio.call(&"ada_bunyi_lempar"), "%s: wus dan bunyi mendarat berhenti lewat Audio._notification sendiri" % nama)
		_tree.root.remove_child(audio)
		audio.free()
	await _tree.process_frame


# --- Scene ---

func _siapkan() -> JalanUji:
	_tree.root.size = Vector2i(2340, 1080)
	var akar: JalanUji = (load(BERKAS_JALAN_UJI) as PackedScene).instantiate() as JalanUji
	_tree.root.add_child(akar)
	await _tree.process_frame
	await _tree.process_frame
	akar.set_process(false)
	(_anak(akar, "KontrolTouch") as KontrolTouch).keyboard_aktif = false
	(_anak(akar, "LoperAgen") as LoperSprite).set_process(false)
	var audio: Node = _audio()
	if audio != null:
		audio.call(&"atur_ulang_lempar")
	return akar


func _bersihkan(akar: JalanUji) -> void:
	for i: int in range(8):
		_sentuh(i, Vector2(-50, -50), false)
	if akar.sedang_jeda():
		akar.minta_lanjut()
	(_anak(akar, "KontrolTouch") as KontrolTouch).keyboard_aktif = OS.has_feature("editor")
	_tree.root.remove_child(akar)
	akar.free()


func _audio() -> Node:
	return _tree.root.get_node_or_null(^"Audio")


func _anak(akar: Node, nama: String) -> Node:
	return akar.find_child(nama, true, false)


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


func _langkah(akar: JalanUji, jumlah: int) -> void:
	var sprite: LoperSprite = _anak(akar, "LoperAgen") as LoperSprite
	for i: int in range(jumlah):
		akar.perbarui(DT)
		sprite.maju(DT)


## Swipe ke kiri (arah seberang) sepanjang `panjang` piksel game dari (720, 200), satu langkah di antara turun dan naik.
func _swipe(akar: JalanUji, panjang: float) -> void:
	var awal: Vector2 = Vector2(720, 200)
	var akhir: Vector2 = awal - Vector2(panjang, 0)
	_sentuh(1, awal, true)
	_geser(1, akhir)
	akar.perbarui(DT)
	_sentuh(1, akhir, false)


func _tap(posisi: Vector2) -> void:
	_sentuh(1, posisi, true)
	_sentuh(1, posisi, false)


func _tap_seberang(akar: JalanUji) -> Vector2:
	return akar.posisi_layar_sepeda() + Vector2(200, -150)


func _tunggu_sasaran(akar: JalanUji, sisi: LoperAnim.Sisi) -> bool:
	for i: int in range(240):
		if akar.pilihan_bantu(sisi) != null:
			return true
		_langkah(akar, 1)
	return akar.pilihan_bantu(sisi) != null


func _catat(akar: JalanUji) -> Dictionary:
	var catatan: Dictionary = {"lempar": 0, "mendarat": []}
	akar.koran_dilempar.connect(func(_l: ThrowSolver.Lintasan) -> void: catatan["lempar"] = int(catatan["lempar"]) + 1)
	akar.koran_mendarat.connect(func(k: KoranLempar.Koran) -> void: (catatan["mendarat"] as Array).append(k))
	return catatan


func _test_scene_wus() -> void:
	_judul.call("Scene: tepat satu wus per lemparan diterima, tidak ada untuk lemparan ditolak (AC-11, D-11)")
	var audio: Node = _audio()
	if audio == null:
		check(false, "autoload Audio ada")
		return
	var akar: JalanUji = await _siapkan()
	var catatan: Dictionary = _catat(akar)
	var wus: AudioStreamPlayer = audio.call(&"pemutar_wus")
	var min_px: float = ThrowSolver.swipe_min_px(LEBAR)
	# Ditolak: swipe pendek (di bawah min, mode bantu mati = tidak ada apa-apa).
	_swipe(akar, min_px * 0.5)
	check(audio.call(&"jumlah_wus") == 0 and catatan["lempar"] == 0 and not wus.playing, "swipe pendek: tidak melempar, tanpa wus")
	# Diterima: swipe cukup panjang.
	_swipe(akar, min_px + 40.0)
	check(catatan["lempar"] == 1 and audio.call(&"jumlah_wus") == 1 and wus.playing, "swipe diterima: tepat satu wus, berbunyi saat jari dilepas")
	# Ditolak: jeda antar lempar.
	akar.perbarui(0.1)
	_swipe(akar, min_px + 40.0)
	check(catatan["lempar"] == 1 and audio.call(&"jumlah_wus") == 1, "swipe saat jeda antar lempar: ditolak, tanpa wus")
	# Ditolak: jeda game.
	akar.perbarui(Config.LEMPAR_JEDA_DETIK)
	akar.minta_jeda()
	var router: TouchRouter = (_anak(akar, "KontrolTouch") as KontrolTouch).router
	router.tekan(3, Vector2(720, 200), 0.0)
	router.geser(3, Vector2(720, 200) - Vector2(min_px + 40.0, 0))
	router.lepas(3, Vector2(720, 200) - Vector2(min_px + 40.0, 0), 0.1)
	check(catatan["lempar"] == 1 and audio.call(&"jumlah_wus") == 1, "swipe langsung ke router saat jeda game: ditolak, tanpa wus")
	akar.minta_lanjut()
	akar.perbarui(DT)
	# Ditolak: mode bantu mati, tap.
	_tap(_tap_seberang(akar))
	check(catatan["lempar"] == 1 and audio.call(&"jumlah_wus") == 1, "tap dengan mode bantu mati: tanpa wus")
	# Diterima: tap mode bantu.
	(_anak(akar, "TombolBantu") as Button).button_pressed = true
	check(_tunggu_sasaran(akar, LoperAnim.Sisi.SEBERANG), "ada sasaran seberang")
	_tap(_tap_seberang(akar))
	check(catatan["lempar"] == 2 and audio.call(&"jumlah_wus") == 2 and wus.playing, "tap mode bantu diterima: tepat satu wus")
	# Ditolak: tanpa sasaran (maju 5,2 santai: tidak ada kotak surat seberang terjangkau).
	akar.perbarui(Config.LEMPAR_JEDA_DETIK)
	(_anak(akar, "Sepeda") as SepedaUji).jarak_ubin = 5.2
	akar.perbarui(0.0)
	check(akar.pilihan_bantu(LoperAnim.Sisi.SEBERANG) == null, "kontrol: tidak ada sasaran seberang di maju 5,2")
	_tap(_tap_seberang(akar))
	check(catatan["lempar"] == 2 and audio.call(&"jumlah_wus") == 2, "tap tanpa sasaran: tanpa wus")
	# Ditolak: koran habis.
	var habis: SisaKoran.Keadaan = akar.koran.salin()
	habis.sisa = 0
	habis.sejak_lempar_detik = INF
	akar.koran = habis
	_swipe(akar, min_px + 40.0)
	check(catatan["lempar"] == 2 and audio.call(&"jumlah_wus") == 2, "swipe saat koran habis: tanpa wus")
	_bersihkan(akar)
	audio.call(&"hentikan_lempar")


func _test_scene_mendarat() -> void:
	_judul.call("Scene: tepat satu bunyi mendarat per koran, permukaan sesuai hasil, variasi bergiliran (AC-11, D-10, D-11)")
	var audio: Node = _audio()
	if audio == null:
		check(false, "autoload Audio ada")
		return
	var akar: JalanUji = await _siapkan()
	var catatan: Dictionary = _catat(akar)
	(_anak(akar, "TombolBantu") as Button).button_pressed = true
	# Dua lemparan bantu ke kotak surat: mailbox 01 lalu 02.
	var harapan_kotak: Array[String] = ["sfx_land_mailbox_01.wav", "sfx_land_mailbox_02.wav"]
	for i: int in range(2):
		akar.perbarui(Config.LEMPAR_JEDA_DETIK)
		check(_tunggu_sasaran(akar, LoperAnim.Sisi.SEBERANG), "lemparan bantu %d: ada sasaran seberang" % (i + 1))
		var sebelum: int = audio.call(&"jumlah_mendarat")
		_tap(_tap_seberang(akar))
		var langkah_ke: int = 0
		while (catatan["mendarat"] as Array).size() <= i and langkah_ke < 180:
			_langkah(akar, 1)
			langkah_ke += 1
		check((catatan["mendarat"] as Array).size() == i + 1 and ((catatan["mendarat"] as Array)[i] as KoranLempar.Koran).hasil == ZonaSasaran.Hasil.KOTAK_SURAT, "lemparan bantu %d mendarat di kotak surat" % (i + 1))
		check(audio.call(&"jumlah_mendarat") == sebelum + 1, "lemparan bantu %d: tepat satu bunyi mendarat di langkah mendarat" % (i + 1))
		var terakhir: String = audio.call(&"mendarat_terakhir")
		check(terakhir == FOLDER + harapan_kotak[i] and (audio.call(&"pemutar_mendarat", terakhir) as AudioStreamPlayer).playing, "lemparan bantu %d: %s berbunyi" % [i + 1, harapan_kotak[i]])
		# Penanda masih tampil beberapa langkah: tidak ada bunyi mendarat kedua.
		_langkah(akar, 30)
		check(audio.call(&"jumlah_mendarat") == sebelum + 1, "lemparan bantu %d: 30 langkah sesudah mendarat tetap satu bunyi" % (i + 1))
	# Swipe bebas ke berbagai arah: tiap koran yang mendarat = satu bunyi dengan permukaan dari hasilnya, giliran dicatat oracle sendiri.
	(_anak(akar, "TombolBantu") as Button).button_pressed = false
	var giliran_oracle: Dictionary = {"mailbox": 2, "porch": 0, "grass": 0, "miss": 0}
	var arah: Array[Vector2] = [Vector2(-1, 0), Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, -1), Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1)]
	var cocok: bool = true
	var jumlah_koran: int = (catatan["mendarat"] as Array).size()
	var dapat: Array[String] = []
	for a: Vector2 in arah:
		for kekuatan: float in [0.3, 0.9]:
			akar.perbarui(Config.LEMPAR_JEDA_DETIK)
			var sebelum_bunyi: int = audio.call(&"jumlah_mendarat")
			var awal: Vector2 = Vector2(560, 180)
			var panjang: float = ThrowSolver.swipe_min_px(LEBAR) + kekuatan * 120.0
			_sentuh(1, awal, true)
			_geser(1, awal + a.normalized() * panjang)
			akar.perbarui(DT)
			_sentuh(1, awal + a.normalized() * panjang, false)
			var langkah_ke: int = 0
			while (catatan["mendarat"] as Array).size() == jumlah_koran and langkah_ke < 180:
				_langkah(akar, 1)
				langkah_ke += 1
			if (catatan["mendarat"] as Array).size() != jumlah_koran + 1:
				cocok = false
				continue
			var koran: KoranLempar.Koran = (catatan["mendarat"] as Array)[jumlah_koran]
			jumlah_koran += 1
			var nama: String = NAMA_HASIL_PENALTI[koran.hasil]
			var g: int = giliran_oracle[nama]
			var harapan: String = FOLDER + "sfx_land_%s_0%d.wav" % [nama, [1, 2, 3][g]]
			giliran_oracle[nama] = [1, 2, 0][g]
			dapat.append("%s=%s" % [ZonaSasaran.Hasil.keys()[koran.hasil], (audio.call(&"mendarat_terakhir") as String).get_file()])
			if audio.call(&"jumlah_mendarat") != sebelum_bunyi + 1 or audio.call(&"mendarat_terakhir") != harapan:
				cocok = false
	check(cocok, "16 swipe: tiap koran tepat satu bunyi, permukaan dan giliran sesuai oracle: %s" % [dapat])
	var jenis: Dictionary = {}
	for k: KoranLempar.Koran in catatan["mendarat"]:
		jenis[NAMA_HASIL_PENALTI[k.hasil]] = true
	check(jenis.size() >= 2, "kontrol: swipe mencakup lebih dari satu permukaan (%s)" % [jenis.keys()])
	_bersihkan(akar)
	audio.call(&"hentikan_lempar")


func _test_scene_jendela() -> void:
	_judul.call("Scene: koran mendarat di jendela, bunyi memakai sakelar jendela yang sama dengan penilaian dan penanda (QA-003, D-10)")
	var audio: Node = _audio()
	if audio == null:
		check(false, "autoload Audio ada")
		return
	var akar: JalanUji = await _siapkan()
	var catatan: Dictionary = _catat(akar)
	var sepeda: SepedaUji = _anak(akar, "Sepeda") as SepedaUji
	# Sepeda santai di maju 2, lateral 0. Sasaran: zona jendela seberang rumah 1 (pelanggan), x -3..-2,75, maju 5,5..6,25 (config
	# `JALAN_UJI_SEBERANG_JENDELA_UBIN` + kavling 4), pusat (-2,875, 5,875); teras dan kotak surat tidak menutupinya.
	var k: BikeMotion.Keadaan = sepeda.keadaan.salin()
	k.kecepatan_ud = 3.0
	k.lateral_ubin = 0.0
	sepeda.keadaan = k
	sepeda.jarak_ubin = 2.0
	akar.perbarui(0.0)
	akar.koran = SisaKoran.awal(Config.KORAN_AWAL)
	var jendela: Rect2 = Rect2(-3.0, 5.5, 0.25, 0.75)
	var pusat: Vector2 = Vector2(-2.875, -5.875)
	# Swipe yang mendarat di pusat jendela: kekuatan dan arah tanah dari pembantu solver, diubah ke vektor layar lewat `Iso`.
	var lepas: Vector2 = ThrowSolver.titik_lepas(sepeda.posisi_dunia(), sepeda.kecepatan_ud, sepeda.lateral_ud, sepeda.jeda_lepas(LoperAnim.Sisi.SEBERANG))
	var u: float = BantuLempar.cari_kekuatan(pusat, lepas, sepeda.kecepatan_ud)
	var arah: Vector2 = BantuLempar.arah_ke(pusat, lepas, sepeda.kecepatan_ud, u)
	var awal: Vector2 = Vector2(600, 330)
	var akhir: Vector2 = awal + Iso.dunia_ke_layar(arah).normalized() * ThrowSolver.panjang_untuk_kekuatan(u, LEBAR)
	var rencana: ThrowSolver.Lintasan = akar.lintasan_swipe(awal, akhir)
	var rencana_jalan: Vector2 = Vector2(rencana.titik_mendarat.x, -rencana.titik_mendarat.y) if rencana != null else Vector2.INF
	check(u >= 0.0 and jendela.has_point(rencana_jalan) and Rect2(Vector2.ZERO, Vector2(LEBAR, 360.0)).has_point(akhir), "kontrol: swipe %s -> %s mendarat di zona jendela seberang rumah 1 (titik %s)" % [awal, akhir, rencana_jalan])
	var j: Array[float] = Config.JALAN_UJI_SEBERANG_JENDELA_UBIN
	check(ZonaSasaran.pelanggan_jalan_uji(1) and j[0] == -3.0 and j[1] == 1.5 and j[2] == 0.25 and j[3] == 0.75, "kontrol: rumah 1 pelanggan, zona jendela seberang sesuai config")
	# Swipe turun lalu naik tanpa langkah di antaranya: lintasan dihitung dari posisi lepas dengan keadaan sepeda yang sama.
	_sentuh(1, awal, true)
	_sentuh(1, akhir, false)
	check(int(catatan["lempar"]) == 1, "swipe ke jendela diterima")
	var sebelum: int = audio.call(&"jumlah_mendarat")
	var langkah_ke: int = 0
	while (catatan["mendarat"] as Array).is_empty() and langkah_ke < 180:
		_langkah(akar, 1)
		langkah_ke += 1
	var koran: KoranLempar.Koran = (catatan["mendarat"] as Array)[0] if not (catatan["mendarat"] as Array).is_empty() else null
	check(koran != null and koran.hasil == ZonaSasaran.Hasil.JENDELA, "koran mendarat dan dinilai JENDELA")
	if koran == null:
		_bersihkan(akar)
		audio.call(&"hentikan_lempar")
		return
	# Oracle: permukaan dari tabel D-10 untuk JENDELA dengan nilai sakelar yang sedang dipakai game (bawaan false = penalti = meleset).
	var permukaan: int = -1
	for baris: Array in TABEL_PERMUKAAN:
		if baris[0] == ZonaSasaran.Hasil.JENDELA and baris[1] == Config.JENDELA_KENA_BONUS:
			permukaan = baris[2]
	var nama: String = NAMA_PERMUKAAN[permukaan]
	var harapan: String = FOLDER + "sfx_land_%s_01.wav" % nama
	check(audio.call(&"jumlah_mendarat") == sebelum + 1 and audio.call(&"mendarat_terakhir") == harapan, "jendela (sakelar %s): bunyi %s (dapat %s)" % [Config.JENDELA_KENA_BONUS, harapan.get_file(), (audio.call(&"mendarat_terakhir") as String).get_file()])
	check((koran.penanda == ZonaSasaran.Penanda.SILANG) == (nama == "miss"), "jendela: bunyi sejalan dengan penanda koran itu (penanda %s, bunyi %s)" % [ZonaSasaran.Penanda.keys()[koran.penanda], nama])
	if not Config.JENDELA_KENA_BONUS:
		check(koran.penanda == ZonaSasaran.Penanda.SILANG and nama == "miss", "sakelar bawaan (penalti): penanda silang, bunyi meleset")
	_bersihkan(akar)
	audio.call(&"hentikan_lempar")


func _test_scene_jeda() -> void:
	_judul.call("Scene: jeda dan background menghentikan wus dan bunyi mendarat seketika, tanpa diputar ulang (AC-12, D-12)")
	var audio: Node = _audio()
	if audio == null:
		check(false, "autoload Audio ada")
		return
	var akar: JalanUji = await _siapkan()
	var catatan: Dictionary = _catat(akar)
	var wus: AudioStreamPlayer = audio.call(&"pemutar_wus")
	(_anak(akar, "TombolBantu") as Button).button_pressed = true
	# Jeda saat wus berbunyi.
	check(_tunggu_sasaran(akar, LoperAnim.Sisi.SEBERANG), "ada sasaran seberang")
	_tap(_tap_seberang(akar))
	check(wus.playing, "kontrol: wus berbunyi sesudah tap diterima")
	akar.minta_jeda()
	check(not wus.playing and not audio.call(&"ada_bunyi_lempar"), "jeda saat wus berbunyi: berhenti seketika")
	for i: int in range(4):
		akar.perbarui(0.2)
	check(not audio.call(&"ada_bunyi_lempar") and (catatan["mendarat"] as Array).is_empty(), "selama jeda: koran beku, tidak ada bunyi mendarat")
	akar.minta_lanjut()
	akar.perbarui(DT)
	check(not wus.playing, "sesudah lanjut: wus lama tidak diputar ulang")
	# Koran yang dibekukan lalu mendarat sesudah lanjut: satu bunyi baru; jeda saat bunyi itu berbunyi.
	var sebelum: int = audio.call(&"jumlah_mendarat")
	var langkah_ke: int = 0
	while (catatan["mendarat"] as Array).is_empty() and langkah_ke < 180:
		_langkah(akar, 1)
		langkah_ke += 1
	var terakhir: String = audio.call(&"mendarat_terakhir")
	var pemutar: AudioStreamPlayer = audio.call(&"pemutar_mendarat", terakhir)
	check(audio.call(&"jumlah_mendarat") == sebelum + 1 and pemutar != null and pemutar.playing, "sesudah lanjut koran mendarat: satu bunyi (%s)" % terakhir.get_file())
	akar.minta_jeda()
	check(pemutar != null and not pemutar.playing and not audio.call(&"ada_bunyi_lempar"), "jeda saat bunyi mendarat berbunyi: berhenti seketika")
	akar.minta_lanjut()
	_langkah(akar, 3)
	check(not audio.call(&"ada_bunyi_lempar") and audio.call(&"jumlah_mendarat") == sebelum + 1, "sesudah lanjut: bunyi mendarat lama tidak diputar ulang")
	# Background lewat notifikasi pohon (JalanUji menjeda, Audio berhenti).
	akar.perbarui(Config.LEMPAR_JEDA_DETIK)
	check(_tunggu_sasaran(akar, LoperAnim.Sisi.SEBERANG), "ada sasaran seberang lagi")
	_tap(_tap_seberang(akar))
	check(wus.playing, "kontrol: wus berbunyi lagi")
	_tree.root.propagate_notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(akar.sedang_jeda() and not audio.call(&"ada_bunyi_lempar"), "APPLICATION_PAUSED: layar jeda dan wus berhenti")
	_tree.root.propagate_notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	akar.perbarui(DT)
	check(not audio.call(&"ada_bunyi_lempar"), "RESUMED tanpa Lanjut: tetap diam")
	akar.minta_lanjut()
	akar.perbarui(DT)
	akar.perbarui(Config.LEMPAR_JEDA_DETIK)
	check(_tunggu_sasaran(akar, LoperAnim.Sisi.SEBERANG), "ada sasaran seberang sebelum scene dibuang")
	_tap(_tap_seberang(akar))
	check(wus.playing, "kontrol: wus berbunyi tepat sebelum scene dibuang")
	# Scene dibuang saat bunyi berbunyi: berhenti.
	_bersihkan(akar)
	check(not audio.call(&"ada_bunyi_lempar"), "scene dibuang: bunyi lempar/mendarat berhenti")
	audio.call(&"hentikan_lempar")
	await _tree.process_frame
