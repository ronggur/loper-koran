extends SceneTree
## Probe rintangan, tabrakan, skor, dan bel di jendela asli, non-headless (AC-26 run fase3b-rintangan-skor bagian B): memuat
## `scenes/rute/rute.tscn` (scene utama), memajukan simulasi, sprite, dan partikel dengan langkah tetap `perbarui(1/60)` (bukan waktu
## dinding), lalu menyimpan tangkapan layar: anjing waspada, anjing mengejar, mobil tanda lampu mundur, mobil di jalan, tabrakan = jatuh (sejak keputusan
## pemilik 2026-10-17: jatuh_normal + kilatan, terjerembab_normal, lalu bangun berkedip kebal), bel "KRING KRING!" + ikon "!" + anjing mundur, penanda tepat dan umpan balik melayang, HUD dev skor/combo/koin, dan kidal (tombol
## bel dan panel skor dicerminkan). Bel diketuk lewat event sentuh sungguhan di zona tap bel (`TouchZones.pusat_bel`). Lemparan "tepat"
## memakai lintasan ke pusat kotak surat (`BantuLempar.pilih`) yang dilempar sebagai lemparan biasa (bukan mode bantu, O-4). Mencetak data
## tiap keadaan dan jumlah keadaan yang tidak sesuai. Tidak interaktif: keluar sendiri lewat `ProbeKeluar`.
##
## Pakai (jendela harus muat di layar monitor):
##   godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_rintangan_jendela.gd -- docs/loop/<RUN_ID>/shots
## Berkas: `<lebar>x<tinggi>_rintangan_<keadaan>.png`.

const BERKAS_RUTE: String = "res://scenes/rute/rute.tscn"
const FRAME_TUNGGU_LAYOUT: int = 5
const DT: float = 1.0 / 60.0

var _skala: float = 1.0
var _folder: String = ""
var _awalan: String = ""
var _akar: RuteMain
var _sepeda: SepedaUji
var _hud: HudRute
var _kontrol: KontrolTouch
var _sprite: LoperSprite
var _debu: PancaranPiksel
var _garis: PancaranPiksel
var _gagal: int = 0
var _tabrakan: Array[String] = []


func _initialize() -> void:
	var argumen: PackedStringArray = OS.get_cmdline_user_args()
	_folder = argumen[0] if argumen.size() > 0 else ""
	var paket: PackedScene = load(BERKAS_RUTE) as PackedScene
	if paket == null:
		push_error("scene rute tidak bisa dimuat")
		await ProbeKeluar.keluar(self, 1)
		return
	_akar = paket.instantiate() as RuteMain
	root.add_child(_akar)
	await _tunggu(FRAME_TUNGGU_LAYOUT)
	_akar.set_process(false)
	var terlihat: Vector2 = root.get_visible_rect().size
	_skala = float(root.size.x) / terlihat.x
	_awalan = "%dx%d" % [root.size.x, root.size.y]
	_sepeda = _akar.find_child("Sepeda", true, false) as SepedaUji
	_hud = _akar.hud_rute()
	_kontrol = _akar.find_child("KontrolTouch", true, false) as KontrolTouch
	_sprite = _akar.find_child("LoperAgen", true, false) as LoperSprite
	_sprite.set_process(false)
	_debu = _sepeda.umpan_balik().debu()
	_garis = _sepeda.umpan_balik().garis()
	_debu.set_process(false)
	_garis.set_process(false)
	_kontrol.keyboard_aktif = false
	_akar.tabrakan.connect(func(jenis: String) -> void: _tabrakan.append(jenis))
	print("jendela %s: viewport terlihat %dx%d, skala x%s (driver %s, renderer %s)" % [root.size, int(terlihat.x), int(terlihat.y), _skala, DisplayServer.get_name(), RenderingServer.get_current_rendering_method()])
	var anjing: RintanganRute.Item = _pertama(RintanganRute.Jenis.ANJING, LoperAnim.Sisi.SEBERANG)
	var mobil: RintanganRute.Item = _pertama(RintanganRute.Jenis.MOBIL, LoperAnim.Sisi.SEBERANG)
	print("rute seed %d: %d rintangan; anjing seberang pertama id %d di maju %.1f, mobil pertama id %d di maju %.1f" % [_akar.benih(), _akar.rintangan().daftar.size(), anjing.id, anjing.anjing.rumah_maju_ubin, mobil.id, mobil.mobil.maju_ubin])

	# --- Anjing waspada lalu mengejar (sepeda santai di lateral -0,8: anjing seberang menyusul) ---
	_taruh(anjing.anjing.rumah_maju_ubin - 10.0, -0.8, Config.KECEPATAN_SANTAI_UD)
	await _maju_sampai(func() -> bool: return _item(anjing.id).anjing.status == AnjingPenjaga.Status.WASPADA, 3.0)
	await _maju(0.3)
	_cek("anjing waspada", _item(anjing.id).anjing.status == AnjingPenjaga.Status.WASPADA)
	await _foto("anjing_waspada")
	await _maju_sampai(func() -> bool: return _item(anjing.id).anjing.status == AnjingPenjaga.Status.MENGEJAR, 4.0)
	await _maju(0.35)
	_cek("anjing mengejar", _item(anjing.id).anjing.status == AnjingPenjaga.Status.MENGEJAR)
	await _foto("anjing_mengejar")

	# --- Mobil: lampu mundur (tanda), lalu di jalan (sepeda di separuh jalan dekat, tidak tertabrak) ---
	_taruh(mobil.mobil.maju_ubin - 10.0, 1.0, Config.KECEPATAN_SANTAI_UD)
	await _maju_sampai(func() -> bool: return _item(mobil.id).mobil.status == MobilGarasi.Status.TANDA, 3.0)
	await _maju(0.2)
	_cek("mobil tanda", _item(mobil.id).mobil.status == MobilGarasi.Status.TANDA)
	await _foto("mobil_tanda")
	await _maju_sampai(func() -> bool: return _item(mobil.id).mobil.belakang_ubin <= 1.0, 4.0)
	_cek("mobil di jalan", _item(mobil.id).mobil.status == MobilGarasi.Status.MUNDUR and _tabrakan.is_empty())
	await _foto("mobil_di_jalan")

	# --- Tabrakan: sepeda di separuh jalan mobil yang sudah berhenti di garis tengah ---
	await _maju_sampai(func() -> bool: return _item(mobil.id).mobil.status == MobilGarasi.Status.BERHENTI, 4.0)
	_taruh(mobil.mobil.maju_ubin - 2.0, -0.6, Config.KECEPATAN_CEPAT_UD)
	await _maju_sampai(func() -> bool: return not _tabrakan.is_empty(), 2.0)
	await _maju(0.1)
	_cek("tabrakan mobil (jatuh_normal, ikon)", _tabrakan == ["mobil_garasi"] and Tabrakan.jatuh(_akar.rintangan().tabrakan) and _sepeda.nama_animasi() == &"jatuh_normal" and _sepeda.efek().ikon_tabrakan_tampil())
	print("tabrakan: %s, kecepatan %.2f, jatuh %s, animasi %s frame %d, alfa %.2f, combo %s putus %s" % [_tabrakan, _sepeda.kecepatan_ud, Tabrakan.jatuh(_akar.rintangan().tabrakan), _sepeda.nama_animasi(), _sepeda.frame_sprite(), _sepeda.alfa_sprite(), _hud.teks_combo(), _hud.putus_tampil()])
	await _foto("tabrakan_jatuh")
	await _maju(0.5)
	_cek("terjerembab (kecepatan 0)", Tabrakan.jatuh(_akar.rintangan().tabrakan) and _sepeda.nama_animasi() == &"terjerembab_normal" and _sepeda.kecepatan_ud == 0.0)
	print("terjerembab: animasi %s frame %d, kecepatan %.2f" % [_sepeda.nama_animasi(), _sepeda.frame_sprite(), _sepeda.kecepatan_ud])
	await _foto("tabrakan_terjerembab")
	await _maju(0.75)
	_cek("bangun berkedip (kebal, kayuh lagi)", not Tabrakan.jatuh(_akar.rintangan().tabrakan) and Tabrakan.kebal(_akar.rintangan().tabrakan) and not _sepeda.sedang_jatuh() and _sepeda.alfa_sprite() == Config.TABRAKAN_KEDIP_ALFA and _tabrakan.size() == 1)
	print("bangun: animasi %s, kecepatan %.2f, alfa %.2f, kebal sisa %.3f" % [_sepeda.nama_animasi(), _sepeda.kecepatan_ud, _sepeda.alfa_sprite(), _akar.rintangan().tabrakan.kebal_detik])
	await _foto("tabrakan_bangun_kedip")
	await _maju(1.5)

	# --- Bel: anjing kedua yang mengejar, dua ketukan di zona bel -> KRING KRING!, ikon "!", lalu anjing mundur ---
	var anjing2: RintanganRute.Item = _pertama(RintanganRute.Jenis.ANJING, LoperAnim.Sisi.SEBERANG, anjing.id)
	_taruh(anjing2.anjing.rumah_maju_ubin - 9.5, 0.6, Config.KECEPATAN_SANTAI_UD)
	await _maju_sampai(func() -> bool: return _item(anjing2.id).anjing.status == AnjingPenjaga.Status.WASPADA, 3.0)
	await _maju_sampai(func() -> bool: return _item(anjing2.id).anjing.status == AnjingPenjaga.Status.MENGEJAR, 4.0)
	await _maju(0.3, false)
	var pusat_bel: Vector2 = TouchZones.pusat_bel(int(_akar.get_viewport_rect().size.x), false)
	_sentuh(5, pusat_bel, true)
	await _maju(DT)
	_sentuh(5, pusat_bel, false)
	await _maju(0.15)
	_sentuh(6, pusat_bel, true)
	await _maju(DT)
	print("bel: jumlah %d, dobel %s, teks tampil %s '%s', frame tombol %d, anjing %s, ikon ! %s" % [_akar.bel().jumlah, _akar.bel().dobel, Bel.teks_tampil(_akar.bel()), _sepeda.efek().label_bel().text, _hud.frame_bel(), AnjingPenjaga.Status.keys()[_item(anjing2.id).anjing.status], RintanganRute.ikon_seru(_item(anjing2.id))])
	_cek("bel kring kring + anjing kaget", _akar.bel().jumlah == 2 and _akar.bel().dobel and _item(anjing2.id).anjing.status == AnjingPenjaga.Status.MUNDUR and RintanganRute.ikon_seru(_item(anjing2.id)))
	await _foto("bel_kring_kring")
	_sentuh(6, pusat_bel, false)
	await _maju(0.6)
	_cek("anjing mundur (bel jeda, cincin)", _item(anjing2.id).anjing.status == AnjingPenjaga.Status.MUNDUR and not RintanganRute.ikon_seru(_item(anjing2.id)) and _hud.frame_bel() >= Bel.FRAME_JEDA_PERTAMA)
	await _foto("bel_anjing_mundur")

	# --- Lemparan tepat dan antaran lain: penanda tepat, umpan balik melayang, HUD skor/combo/koin ---
	await _maju(1.5)
	var dilempar: int = 0
	for ip: int in [4, 5, 6]:
		var pelanggan: RouteBuilder.RumahRute = _akar.rute().pelanggan[ip]
		_taruh(pelanggan.maju_ubin - 5.0, 0.5, Config.KECEPATAN_SANTAI_UD)
		await _maju(Config.LEMPAR_JEDA_DETIK)
		var pilihan: BantuLempar.Pilihan = null
		var detik: float = 0.0
		while detik < 3.0:
			pilihan = _akar.pilihan_bantu(LoperAnim.Sisi.SEBERANG)
			if pilihan != null and pilihan.zona.id_rumah == pelanggan.id:
				break
			await _maju(DT, false)
			detik += DT
		if pilihan == null:
			print("PERINGATAN: tidak ada lintasan ke kotak surat %s" % pelanggan.id)
			_gagal += 1
			continue
		_akar.call(&"_lempar", pilihan.lintasan, false)
		dilempar += 1
		var koran: KoranLempar.Koran = _akar.koran_terbang()[_akar.koran_terbang().size() - 1]
		await _maju(koran.lintasan.jeda_lepas + koran.lintasan.lama_terbang + DT, false)
		await _maju(0.1)
	var terakhir: KoranLempar.Koran = _akar.koran_terbang()[_akar.koran_terbang().size() - 1] if not _akar.koran_terbang().is_empty() else null
	print("tepat: dilempar %d, skor %d, koin %d, beruntun %d, tepat %d, HUD '%s' '%s' '%s', penanda terakhir %s, umpan %s" % [dilempar, _akar.skor().skor, _akar.skor().koin, _akar.skor().beruntun, _akar.skor().jumlah_tepat, _hud.teks_skor(), _hud.teks_combo(), _hud.teks_koin(), ZonaSasaran.Penanda.keys()[terakhir.penanda] if terakhir != null else "-", _akar.umpan_gambar().teks_tampil()])
	_cek("penanda tepat dan HUD skor", terakhir != null and terakhir.penanda == ZonaSasaran.Penanda.TEPAT and _akar.skor().jumlah_tepat == dilempar and _akar.umpan_gambar().jumlah_tampil() >= 1)
	await _foto("tepat_hud_skor")

	# --- Kidal: tombol bel dan panel skor dicerminkan; bel diketuk di pusat kidal ---
	_akar.atur_kidal(true)
	await _tunggu(3)
	await _maju(0.5)
	var pusat_kidal: Vector2 = TouchZones.pusat_bel(int(_akar.get_viewport_rect().size.x), true)
	var jumlah_bel: int = _akar.bel().jumlah
	_sentuh(7, pusat_kidal, true)
	await _maju(DT)
	print("kidal: bel %d -> %d, tombol bel %s, panel skor %s" % [jumlah_bel, _akar.bel().jumlah, _hud.rect_tombol_bel(), _hud.rect_panel_skor()])
	_cek("kidal: bel di kiri berbunyi", _akar.bel().jumlah == jumlah_bel + 1 and absf(_hud.rect_tombol_bel().get_center().x - pusat_kidal.x) <= 1.0)
	await _foto("kidal_bel_skor")
	_sentuh(7, pusat_kidal, false)
	await _maju(DT)
	print("probe selesai, %d keadaan tidak sesuai" % _gagal)
	await ProbeKeluar.keluar(self, 0 if _gagal == 0 else 1)


## Rintangan pertama berjenis `jenis` di sisi `sisi` (urut maju), selain id `kecuali`.
func _pertama(jenis: RintanganRute.Jenis, sisi: LoperAnim.Sisi, kecuali: int = -1) -> RintanganRute.Item:
	for item: RintanganRute.Item in _akar.rintangan().daftar:
		if item.jenis != jenis or item.id == kecuali:
			continue
		var s: LoperAnim.Sisi = item.anjing.sisi if jenis == RintanganRute.Jenis.ANJING else item.mobil.sisi
		if s == sisi:
			return item
	return _akar.rintangan().daftar[0]


func _item(id: int) -> RintanganRute.Item:
	return _akar.rintangan().daftar[id]


func _cek(nama: String, kondisi: bool) -> void:
	print("%s: %s" % [nama, "sesuai" if kondisi else "TIDAK SESUAI"])
	if not kondisi:
		_gagal += 1


## Menaruh sepeda di maju `maju`, lateral `lateral`, kecepatan `v` (keadaan sepeda diganti, rintangan tetap).
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
	await _tunggu(2)


func _tunggu(jumlah: int) -> void:
	for i: int in range(jumlah):
		await process_frame


func _maju(detik: float, gambar: bool = true) -> void:
	for i: int in range(maxi(roundi(detik / DT), 1)):
		if _akar.sedang_jeda():
			print("PERINGATAN: layar jeda terbuka (jendela kehilangan fokus); probe melanjutkan lewat minta_lanjut")
			_akar.minta_lanjut()
		_akar.perbarui(DT)
		_sprite.maju(DT)
		_debu.maju(DT)
		_garis.maju(DT)
	if gambar:
		await _tunggu(2)


func _sentuh(index: int, posisi_viewport: Vector2, tekan: bool) -> void:
	var peristiwa: InputEventScreenTouch = InputEventScreenTouch.new()
	peristiwa.index = index
	peristiwa.position = posisi_viewport * _skala
	peristiwa.pressed = tekan
	Input.parse_input_event(peristiwa)
	Input.flush_buffered_events()


func _foto(keadaan: String) -> void:
	await _tunggu(3)
	print("%s: kecepatan %.2f u/d, lateral %.2f, jarak %.2f ubin, rintangan tampil %d, skor %d, koin %d, kidal %s" % [keadaan, _sepeda.kecepatan_ud, _sepeda.lateral_ubin, _sepeda.jarak_ubin, _akar.rintangan_daur().jumlah_tampil(), _akar.skor().skor, _akar.skor().koin, _kontrol.router.kidal()])
	if _folder.is_empty():
		return
	var gambar: Image = root.get_texture().get_image()
	var berkas: String = "%s/%s_rintangan_%s.png" % [_folder, _awalan, keadaan]
	var galat: int = gambar.save_png(berkas)
	print("tangkapan layar %dx%d (%s) ke %s (kode %d)" % [gambar.get_width(), gambar.get_height(), keadaan, berkas, galat])
