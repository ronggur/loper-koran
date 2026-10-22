extends SceneTree
## Probe animasi pemain Fase 5C di jendela asli, non-headless (AC-8 run 20261022-fase5c-animasi-simpang): memuat `scenes/rute/rute.tscn` dengan misi P1 (hari 1),
## memajukan simulasi dengan langkah tetap `perbarui(1/60)`, lalu memotret:
## - tabrakan nyata dengan anjing (arah normal dan serong kiri: stick ditahan ke sisi seberang): jatuh, terjerembab, bangkit tengah, bangkit frame terakhir, dan
##   langkah bangun (transisi bangkit -> kayuh);
## - jatuh, terjerembab, dan bangkit untuk kelima arah di satu titik rute (sprite dipasang langsung lewat `LoperSprite.atur_jatuh` sesudah sepeda ditaruh, karena
##   tabrakan nyata hanya memberi arah gerak saat itu);
## - rem -> berhenti (stick bawah penuh ditahan) di jalan dan di titik tangkap kucing (menepi, progres tangkap berjalan, pose kucing ditangkap);
## - satu jatuh nyata dalam mode kidal.
## Tiap keadaan memeriksa nama animasi dan titik pijak (posisi global + offset - ukuran frame / 2 + `ground_anchor` JSON sheet = posisi sepeda) dan mencetak
## "TIDAK SESUAI" bila bergeser; jumlahnya dicetak di akhir dan harus 0. Keluar lewat `ProbeKeluar`.
##
## Pakai (jendela harus muat di layar monitor):
##   godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_animasi_pemain_jendela.gd -- docs/loop/<RUN_ID>/shots/iter<N>
##   (juga 1920x1080, 2400x1080, 1600x720)
## Berkas: `<lebar>x<tinggi>_animasi_<keadaan>.png`.

const BERKAS_RUTE: String = "res://scenes/rute/rute.tscn"
const FOLDER_LOPER: String = "res://assets/sprites/loper/"
const FRAME_TUNGGU_LAYOUT: int = 5
const DT: float = 1.0 / 60.0
const TITIK_STICK: Vector2 = Vector2(100, 260)
const NAMA_ARAH: Dictionary = {-2: "kiri", -1: "serong_kiri", 0: "normal", 1: "serong_kanan", 2: "kanan"}
const SHEET_AWALAN: Array = [
	["santai_", "loper_agen.json"], ["cepat_", "loper_agen.json"], ["ngebut_", "loper_agen.json"], ["melambat_", "loper_agen_melambat.json"],
	["lempar_", "loper_agen_lempar.json"], ["meluncur_", "loper_agen_meluncur.json"], ["rem_", "loper_agen_rem.json"], ["jatuh_", "loper_agen_jatuh.json"],
	["terjerembab_", "loper_agen_jatuh.json"], ["bangkit_", "loper_agen_bangkit.json"], ["berhenti_", "loper_agen_berhenti.json"],
]

var _skala: float = 1.0
var _folder: String = ""
var _awalan: String = ""
var _akar: RuteMain
var _sepeda: SepedaUji
var _sprite: LoperSprite
var _kontrol: KontrolTouch
var _debu: PancaranPiksel
var _garis: PancaranPiksel
var _gagal: int = 0
var _tabrakan: Array[String] = []
var _json: Dictionary = {}


func _initialize() -> void:
	var argumen: PackedStringArray = OS.get_cmdline_user_args()
	_folder = argumen[0] if argumen.size() > 0 else ""
	# --- 1. Tabrakan nyata dengan anjing seberang pertama di rute seed bawaan scene (geometri sama dengan `TesAnimasi5c`): arah normal (stick netral)
	# dan serong kiri (stick ke seberang); tiap kasus di scene baru supaya anjingnya belum pernah mengejar.
	for kasus: Array in [[-0.6, 30.0, 0.0, 0], [0.0, 35.0, -25.0, -1]]:
		await _pasang(false)
		await _tabrakan_nyata(kasus[0], kasus[1], kasus[2], kasus[3])
	await _pasang(true)

	# --- 2. Lima arah di satu titik rute (sprite dipasang langsung) ---
	_taruh(14.0, 0.0, 0.0)
	for arah: int in range(-2, 3):
		var h: String = NAMA_ARAH[arah]
		for kasus: Array in [[0.2, "jatuh"], [0.5, "terjerembab"], [0.9, "bangkit"]]:
			_sprite.atur_jatuh(false, 0.0)
			_sprite.steer = arah
			_sprite.atur_jatuh(true, float(kasus[0]))
			_periksa("%s_%s" % [kasus[1], h], StringName("%s_%s" % [kasus[1], h]))
			await _foto("arah_%s_%s" % [h, kasus[1]])
	_sprite.atur_jatuh(false, 0.0)

	# --- 3. Rem -> berhenti di jalan ---
	_taruh(20.0, 0.5, Config.KECEPATAN_SANTAI_UD)
	_sentuh(0, TITIK_STICK, true)
	_geser(0, TITIK_STICK + Vector2(0, Config.STICK_RADIUS_PX))
	await _maju(0.4, false)
	_periksa("rem bergerak", &"rem_normal")
	await _foto("rem_bergerak")
	await _maju_sampai(func() -> bool: return _sepeda.kecepatan_ud == 0.0, 4.0)
	await _maju(0.2, false)
	_periksa("berhenti", &"berhenti_normal")
	await _foto("berhenti")
	_sentuh(0, TITIK_STICK, false)
	await _maju(0.5, false)
	_periksa("kayuh sesudah berhenti", &"santai_normal")
	await _foto("berhenti_lalu_kayuh")

	# --- 4. Berhenti di titik tangkap kucing (menepi lalu rem sampai diam) ---
	var rencana: RencanaMisi.Rencana = _akar.rencana_misi()
	for t: RencanaMisi.Titik in [rencana.titik[0], rencana.titik[1]]:
		_taruh(t.maju_ubin + 0.5, 0.5, Config.KECEPATAN_SANTAI_UD)
		await _maju(DT, false)
	var t3: RencanaMisi.Titik = rencana.titik[2]
	_taruh(t3.maju_ubin - 2.9, -1.0, Config.KECEPATAN_SANTAI_UD)
	_sentuh(0, TITIK_STICK, true)
	_geser(0, TITIK_STICK + Vector2(0, Config.STICK_RADIUS_PX))
	await _maju_sampai(func() -> bool: return _sepeda.kecepatan_ud == 0.0, 4.0)
	await _maju(0.3, false)
	var timer: float = _akar.keadaan_misi().timer_detik
	_periksa("berhenti di titik tangkap", &"berhenti_normal")
	_cek("progres tangkap berjalan dan kucing ditangkap (frame %d, timer %.2f)" % [_akar.kucing().badan().frame, timer], timer > 0.0 and PoseKucing.ditangkap(t3.jenis, timer / t3.lama_berhenti_detik) and _akar.kucing().badan().frame == PoseKucing.frame(t3.jenis, timer / t3.lama_berhenti_detik, float(_akar.get(&"_detik_misi"))))
	await _foto("berhenti_tangkap_kucing")
	_sentuh(0, TITIK_STICK, false)
	await _maju(DT, false)

	# --- 5. Kidal: satu jatuh nyata ---
	await _pasang(false)
	_akar.atur_kidal(true)
	await _tunggu(3)
	_taruh(30.0, -0.6, Config.KECEPATAN_SANTAI_UD)
	_tabrakan.clear()
	await _maju_sampai(func() -> bool: return not _tabrakan.is_empty(), 6.0)
	await _maju(0.25, false)
	_periksa("kidal jatuh", &"jatuh_normal")
	await _foto("kidal_jatuh")
	await _maju(0.6, false)
	_periksa("kidal bangkit", &"bangkit_normal")
	await _foto("kidal_bangkit")
	print("probe selesai, %d keadaan tidak sesuai" % _gagal)
	await ProbeKeluar.keluar(self, 0 if _gagal == 0 else 1)


## Memasang scene rute baru (yang lama dibuang): `dengan_misi` = misi P1 di rute hari 1, selain itu rute seed bawaan scene tanpa misi.
func _pasang(dengan_misi: bool) -> void:
	if _akar != null:
		root.remove_child(_akar)
		_akar.free()
	_akar = (load(BERKAS_RUTE) as PackedScene).instantiate() as RuteMain
	if dengan_misi:
		_akar.atur_benih_awal(SeedHari.rute(1))
		_akar.atur_misi(PemuatMisi.muat_folder().cari("p1_kucing"))
	root.add_child(_akar)
	await _tunggu(FRAME_TUNGGU_LAYOUT)
	_akar.set_process(false)
	_skala = float(root.size.x) / root.get_visible_rect().size.x
	_awalan = "%dx%d" % [root.size.x, root.size.y]
	_sepeda = _akar.find_child("Sepeda", true, false) as SepedaUji
	_sprite = _akar.find_child("LoperAgen", true, false) as LoperSprite
	_kontrol = _akar.find_child("KontrolTouch", true, false) as KontrolTouch
	_sprite.set_process(false)
	_debu = _sepeda.umpan_balik().debu()
	_garis = _sepeda.umpan_balik().garis()
	_debu.set_process(false)
	_garis.set_process(false)
	_kontrol.keyboard_aktif = false
	_akar.tabrakan.connect(func(j: String) -> void: _tabrakan.append(j))
	print("jendela %s: skala x%s, rute seed %d, misi %s" % [root.size, _skala, _akar.benih(), dengan_misi])


## Tabrakan nyata dengan anjing seberang pertama dari (lateral, maju) dengan stick digeser `geser_x`; memotret jatuh, terjerembab, bangkit, dan bangun; memeriksa arah ditahan dan pijak tetap tiap langkah.
func _tabrakan_nyata(lateral: float, maju: float, geser_x: float, arah: int) -> void:
	var h: String = NAMA_ARAH[arah]
	_taruh(maju, lateral, Config.KECEPATAN_SANTAI_UD)
	_tabrakan.clear()
	if geser_x != 0.0:
		_sentuh(0, TITIK_STICK, true)
		_geser(0, TITIK_STICK + Vector2(geser_x, 0))
	await _maju_sampai(func() -> bool: return not _tabrakan.is_empty(), 6.0)
	print("tabrakan %s: %s di lateral %.2f maju %.2f, animasi %s" % [h, _tabrakan, _sepeda.lateral_ubin, _sepeda.jarak_ubin, _sprite.animation])
	_cek("tabrakan %s terjadi dengan jatuh_%s" % [h, h], not _tabrakan.is_empty() and _sprite.animation == StringName("jatuh_" + h))
	var pijak: Vector2 = _pijak()
	var urutan: Array[String] = []
	var bergeser: int = 0
	var frame_bangun: String = ""
	var foto: Dictionary = {1: "jatuh", 26: "terjerembab", 50: "bangkit_tengah", 71: "bangkit_akhir", 72: "bangun"}
	for i: int in range(1, 73):
		await _maju(DT, false)
		if _pijak() != pijak or pijak != _sprite.global_position:
			bergeser += 1
		var tanda: String = String(_sprite.animation).get_slice("_", 0)
		if urutan.is_empty() or urutan[urutan.size() - 1] != tanda:
			urutan.append(tanda)
		if not String(_sprite.animation).ends_with("_" + h) and _sprite.sedang_jatuh():
			bergeser += 1000
		if i == 72:
			frame_bangun = "%s:%d" % [_sprite.animation, _sprite.frame]
		if foto.has(i):
			await _foto("tabrak_%s_%s" % [h, foto[i]])
	print("tabrakan %s: urutan %s, langkah bangun %s, pijak %s" % [h, urutan, frame_bangun, pijak])
	_cek("tabrakan %s: pijak tetap, arah ditahan (pelanggaran %d)" % [h, bergeser], bergeser == 0)
	var harapan: Array[String] = ["jatuh", "terjerembab", "bangkit", "santai"]
	_cek("tabrakan %s: urutan jatuh -> terjerembab -> bangkit -> santai frame 0" % h, urutan == harapan and frame_bangun == "santai_%s:0" % h)
	_sentuh(0, TITIK_STICK, false)
	await _maju(1.2, false)


func _json_animasi(nama: String) -> Dictionary:
	for baris: Array in SHEET_AWALAN:
		if nama.begins_with(String(baris[0])):
			var berkas: String = String(baris[1])
			if not _json.has(berkas):
				_json[berkas] = JSON.parse_string(FileAccess.get_file_as_string(FOLDER_LOPER + berkas))
			return _json[berkas]
	return {}


## Titik pijak dunia sprite dari JSON sheet animasinya (Vector2(INF, INF) bila ukuran frame bukan sel JSON).
func _pijak() -> Vector2:
	var json: Dictionary = _json_animasi(String(_sprite.animation))
	var t: Texture2D = _sprite.sprite_frames.get_frame_texture(_sprite.animation, _sprite.frame)
	if json.is_empty() or t == null or t.get_size() != Vector2(float(json["cell"][0]), float(json["cell"][1])):
		return Vector2(INF, INF)
	return _sprite.global_position + _sprite.offset - t.get_size() / 2.0 + Vector2(float(json["ground_anchor"][0]), float(json["ground_anchor"][1]))


func _periksa(keadaan: String, animasi: StringName) -> void:
	var p: Vector2 = _pijak()
	print("%s: animasi %s f%d, pijak %s, sepeda %s" % [keadaan, _sprite.animation, _sprite.frame, p, _sprite.global_position])
	_cek("%s: animasi %s" % [keadaan, animasi], _sprite.animation == animasi)
	_cek("%s: pijak = posisi sepeda" % keadaan, p == _sprite.global_position)


func _cek(nama: String, kondisi: bool) -> void:
	if not kondisi:
		print("TIDAK SESUAI: %s" % nama)
		_gagal += 1


func _taruh(maju: float, lateral: float, v: float) -> void:
	var k: BikeMotion.Keadaan = _sepeda.keadaan.salin()
	k.kecepatan_ud = v
	k.lateral_ubin = lateral
	_sepeda.keadaan = k
	_sepeda.jarak_ubin = maju
	_akar.perbarui(0.0)


func _maju_sampai(syarat: Callable, batas_detik: float) -> void:
	var detik: float = 0.0
	while not bool(syarat.call()) and detik < batas_detik:
		await _maju(DT, false)
		detik += DT


func _tunggu(jumlah: int) -> void:
	for i: int in range(jumlah):
		await process_frame


func _maju(detik: float, gambar: bool = true) -> void:
	for i: int in range(maxi(roundi(detik / DT), 1)):
		if _akar.sedang_jeda():
			print("PERINGATAN: layar jeda terbuka (jendela kehilangan fokus); probe melanjutkan lewat minta_lanjut")
			_akar.minta_lanjut()
		_akar.perbarui(DT)
		_debu.maju(DT)
		_garis.maju(DT)
	if gambar:
		await _tunggu(2)


func _sentuh(index: int, posisi_viewport: Vector2, tekan: bool) -> void:
	var e: InputEventScreenTouch = InputEventScreenTouch.new()
	e.index = index
	e.position = posisi_viewport * _skala
	e.pressed = tekan
	Input.parse_input_event(e)
	Input.flush_buffered_events()


func _geser(index: int, posisi_viewport: Vector2) -> void:
	var e: InputEventScreenDrag = InputEventScreenDrag.new()
	e.index = index
	e.position = posisi_viewport * _skala
	Input.parse_input_event(e)
	Input.flush_buffered_events()


func _foto(keadaan: String) -> void:
	await _tunggu(3)
	if _folder.is_empty():
		return
	var gambar: Image = root.get_texture().get_image()
	var berkas: String = "%s/%s_animasi_%s.png" % [_folder, _awalan, keadaan]
	var galat: int = gambar.save_png(berkas)
	print("tangkapan layar %dx%d (%s) ke %s (kode %d)" % [gambar.get_width(), gambar.get_height(), keadaan, berkas, galat])
