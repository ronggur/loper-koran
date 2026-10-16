extends SceneTree
## Probe mode bantu di jendela asli, non-headless (AC-19 run fase2b-bantu-audio): memuat `scenes/dev/jalan_uji.tscn` (scene utama sejak run fase3a-rute = rute.tscn), menekan tombol "Bantu" di HUD,
## mengetuk zona lempar lewat event sentuh sintetis (piksel jendela, seperti dari perangkat), memajukan simulasi, sprite, dan partikel
## dengan langkah tetap `perbarui(1/60)` (bukan waktu dinding), lalu menyimpan tangkapan layar: tombol mode bantu mati dan nyala, koran
## bantu terbang ke kotak surat seberang dan dekat, penanda centang di kotak surat, tanda tanpa sasaran, dan kidal + mode bantu. Titik
## ketukan digambar sebagai titik 2 px game warna `ACCENT` di lapisan probe (bukan bagian game) supaya tangkapan menunjukkan di mana jari
## mengetuk relatif garis jalan. Ketukan seberang di atas garis jalan yang melewati sepeda, ketukan dekat di bawahnya (`BantuLempar.sisi_tap`
## dicetak sebagai kontrol). Mencetak data tiap keadaan dan kotak teks HUD untuk `tools/cek_blok_piksel.py --kecualikan`. Tidak
## interaktif: keluar sendiri lewat `ProbeKeluar`.
##
## Pakai (jendela harus muat di layar monitor):
##   godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_bantu_jendela.gd -- docs/loop/<RUN_ID>/shots
## Berkas: `<lebar>x<tinggi>_bantu_<keadaan>.png`. Periksa ketajaman dunia:
##   python3 tools/cek_blok_piksel.py 3 --kecualikan <kotak teks HUD> <png>   (kotak dicetak probe)

const FRAME_TUNGGU_LAYOUT: int = 5
const DT: float = 1.0 / 60.0
## Titik ketukan relatif titik pijak sepeda di layar (piksel game): seberang di atas garis jalan, dekat di bawahnya, di zona swipe kanan.
const TAP_SEBERANG: Vector2 = Vector2(200, -150)
const TAP_DEKAT: Vector2 = Vector2(200, 30)
## Titik ketukan kidal (zona swipe kiri), piksel game: di atas garis jalan (seberang) dan di bawahnya (dekat).
const TAP_KIDAL_SEBERANG: Vector2 = Vector2(150, 120)
const TAP_KIDAL_DEKAT: Vector2 = Vector2(150, 345)
## Foto koran terbang diambil di pecahan lama terbang ini sesudah jeda lepas (0,5 = sekitar puncak lengkung).
const FOTO_TERBANG_PECAHAN: float = 0.5
## Maju sepeda (ubin) tempat tidak ada kotak surat seberang terjangkau di santai (sama dengan tes AC-5 tanpa sasaran).
const MAJU_TANPA_SASARAN: float = 5.2

var _skala: float = 1.0
var _folder: String = ""
var _awalan: String = ""
var _akar: JalanUji
var _sepeda: SepedaUji
var _hud: HudDev
var _kontrol: KontrolTouch
var _sprite: LoperSprite
var _debu: PancaranPiksel
var _garis: PancaranPiksel
var _gagal: int = 0
var _lapis: CanvasLayer


func _initialize() -> void:
	var argumen: PackedStringArray = OS.get_cmdline_user_args()
	_folder = argumen[0] if argumen.size() > 0 else ""
	var paket: PackedScene = load("res://scenes/dev/jalan_uji.tscn") as PackedScene
	if paket == null:
		push_error("scene utama tidak bisa dimuat")
		await ProbeKeluar.keluar(self, 1)
		return
	_akar = paket.instantiate() as JalanUji
	root.add_child(_akar)
	_lapis = CanvasLayer.new()
	_lapis.layer = 50
	root.add_child(_lapis)
	await _tunggu(FRAME_TUNGGU_LAYOUT)
	_akar.set_process(false)
	var terlihat: Vector2 = root.get_visible_rect().size
	_skala = float(root.size.x) / terlihat.x
	_awalan = "%dx%d" % [root.size.x, root.size.y]
	_sepeda = _akar.find_child("Sepeda", true, false) as SepedaUji
	_hud = _akar.find_child("Hud", true, false) as HudDev
	_kontrol = _akar.find_child("KontrolTouch", true, false) as KontrolTouch
	_sprite = _akar.find_child("LoperAgen", true, false) as LoperSprite
	_sprite.set_process(false)
	_debu = _sepeda.umpan_balik().debu()
	_garis = _sepeda.umpan_balik().garis()
	_debu.set_process(false)
	_garis.set_process(false)
	_kontrol.keyboard_aktif = false
	print("jendela %s: viewport terlihat %dx%d, skala x%s (driver %s, renderer %s)" % [root.size, int(terlihat.x), int(terlihat.y), _skala, DisplayServer.get_name(), RenderingServer.get_current_rendering_method()])
	_cetak_kecualikan("HUD", [_hud.rect_tombol_kidal(), _hud.rect_tombol_bantu(), _hud.rect_panel_kecepatan(), _hud.rect_panel_koran()])

	# --- Tombol mode bantu mati, lalu nyala ---
	await _maju(0.5)
	await _foto("tombol_mati")
	(_akar.find_child("TombolBantu", true, false) as Button).button_pressed = true
	await _tunggu(3)
	print("mode bantu: %s, teks tombol '%s'" % [_akar.mode_bantu(), (_akar.find_child("TombolBantu", true, false) as Button).text])
	await _foto("tombol_nyala")

	# --- Koran bantu ke kotak surat seberang dan dekat (santai, tanpa stick) ---
	await _lempar_bantu(LoperAnim.Sisi.SEBERANG, "seberang", false)
	await _lempar_bantu(LoperAnim.Sisi.DEKAT, "dekat", false)

	# --- Tanpa sasaran: tidak ada kotak surat seberang terjangkau, tanda kecil di titik ketukan ---
	await _maju(Config.LEMPAR_JEDA_DETIK)
	_sepeda.jarak_ubin = MAJU_TANPA_SASARAN
	await _maju(DT)
	var tap: Vector2 = _akar.posisi_layar_sepeda() + TAP_SEBERANG
	var sisa: int = _akar.koran.sisa
	print("tanpa_sasaran: pilihan seberang %s" % [_akar.pilihan_bantu(LoperAnim.Sisi.SEBERANG)])
	_tap(tap)
	await _maju(0.1)
	print("tanpa_sasaran: tap %s, sisi %s, tanda tampil %s di %s, koran %d -> %d, terbang %d" % [tap, LoperAnim.Sisi.keys()[BantuLempar.sisi_tap(tap, _akar.posisi_layar_sepeda())], _kontrol.tanda_tampil(), _kontrol.posisi_tanda(), sisa, _akar.koran.sisa, _akar.koran_terbang().size()])
	if not _kontrol.tanda_tampil() or _akar.koran.sisa != sisa:
		_gagal += 1
	await _foto("tanpa_sasaran")
	_hapus_titik()
	await _maju(1.0)

	# --- Kidal + mode bantu: ketukan di zona kiri ---
	(_akar.find_child("TombolKidal", true, false) as Button).button_pressed = true
	await _tunggu(3)
	_cetak_kecualikan("kidal", [_hud.rect_tombol_kidal(), _hud.rect_tombol_bantu(), _hud.rect_panel_kecepatan(), _hud.rect_panel_koran()])
	await _lempar_bantu(LoperAnim.Sisi.SEBERANG, "kidal_seberang", true)
	await _lempar_bantu(LoperAnim.Sisi.DEKAT, "kidal_dekat", true)
	print("probe selesai, %d keadaan tidak sesuai" % _gagal)
	await ProbeKeluar.keluar(self, 0 if _gagal == 0 else 1)


## Menunggu sampai ada sasaran bantu untuk `sisi`, mengetuk di sisi itu, memotret koran terbang lalu penanda di kotak surat.
func _lempar_bantu(sisi: LoperAnim.Sisi, nama: String, kidal: bool) -> void:
	await _maju(Config.LEMPAR_JEDA_DETIK, false)
	var detik: float = 0.0
	while _akar.pilihan_bantu(sisi) == null and detik < 6.0:
		await _maju(DT, false)
		detik += DT
	var pilihan: BantuLempar.Pilihan = _akar.pilihan_bantu(sisi)
	if pilihan == null:
		print("PERINGATAN %s: tidak ada sasaran bantu dalam 6 detik" % nama)
		_gagal += 1
		return
	var tap: Vector2
	if kidal:
		tap = TAP_KIDAL_SEBERANG if sisi == LoperAnim.Sisi.SEBERANG else TAP_KIDAL_DEKAT
	else:
		tap = _akar.posisi_layar_sepeda() + (TAP_SEBERANG if sisi == LoperAnim.Sisi.SEBERANG else TAP_DEKAT)
	var sisi_tap: LoperAnim.Sisi = BantuLempar.sisi_tap(tap, _akar.posisi_layar_sepeda())
	var sebelum: int = _akar.koran_terbang().size()
	var sisa: int = _akar.koran.sisa
	_tap(tap)
	print("%s: tap %s (sepeda di layar %s), sisi tap %s, sasaran rumah %d sisi %s, koran %d -> %d" % [nama, tap, _akar.posisi_layar_sepeda(), LoperAnim.Sisi.keys()[sisi_tap], pilihan.zona.rumah, LoperAnim.Sisi.keys()[pilihan.zona.sisi], sisa, _akar.koran.sisa])
	if _akar.koran_terbang().size() != sebelum + 1 or sisi_tap != sisi:
		print("PERINGATAN %s: ketukan tidak melempar ke sisi yang diminta" % nama)
		_gagal += 1
		return
	var koran: KoranLempar.Koran = _akar.koran_terbang()[_akar.koran_terbang().size() - 1]
	await _maju(koran.lintasan.jeda_lepas + koran.lintasan.lama_terbang * FOTO_TERBANG_PECAHAN)
	await _foto("%s_terbang" % nama)
	_hapus_titik()
	var batas: int = 0
	while not _koran_ini(koran).mendarat and batas < 120:
		await _maju(DT, false)
		batas += 1
	var mendarat: KoranLempar.Koran = _koran_ini(koran)
	await _maju(DT)
	print("%s: mendarat %s, hasil %s, penanda %s" % [nama, mendarat.mendarat, ZonaSasaran.Hasil.keys()[mendarat.hasil], ZonaSasaran.Penanda.keys()[mendarat.penanda]])
	if mendarat.hasil != ZonaSasaran.Hasil.KOTAK_SURAT or mendarat.penanda != ZonaSasaran.Penanda.CENTANG:
		_gagal += 1
	await _foto("%s_centang" % nama)


## Objek koran terbaru dengan lintasan yang sama dengan `koran` (objek diganti tiap langkah); `koran` sendiri bila sudah selesai.
func _koran_ini(koran: KoranLempar.Koran) -> KoranLempar.Koran:
	for k: KoranLempar.Koran in _akar.koran_terbang():
		if k.lintasan == koran.lintasan:
			return k
	return koran


## Ketukan jari 1 di `posisi` (piksel game), dan titik ketukan di lapisan probe.
func _tap(posisi: Vector2) -> void:
	_hapus_titik()
	for d: Vector2 in [Vector2(-3, 0), Vector2(3, 0), Vector2(0, -3), Vector2(0, 3)]:
		var titik: ColorRect = ColorRect.new()
		titik.color = Palette.ACCENT
		titik.size = Vector2(2, 2)
		titik.position = (posisi + d).round() - Vector2(1, 1)
		_lapis.add_child(titik)
	_sentuh(1, posisi, true)
	_sentuh(1, posisi, false)


func _hapus_titik() -> void:
	for anak: Node in _lapis.get_children():
		anak.queue_free()


func _cetak_kecualikan(nama: String, kotak: Array) -> void:
	var bagian: PackedStringArray = PackedStringArray()
	for k: Rect2 in kotak:
		bagian.append("--kecualikan %d,%d,%d,%d" % [int(k.position.x * _skala), int(k.position.y * _skala), int(k.end.x * _skala) + 1, int(k.end.y * _skala) + 1])
	print("kecualikan teks %s: %s" % [nama, " ".join(bagian)])


func _tunggu(jumlah: int) -> void:
	for i: int in range(jumlah):
		await process_frame


## Memajukan simulasi, sprite, dan partikel `detik` dengan langkah `DT`; menunggu dua frame gambar bila `gambar`.
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
	print("%s: kecepatan %.2f u/d, lateral %.2f, jarak %.2f ubin, mode bantu %s, kidal %s, sisa koran %d, koran tampil %d, tanda %s" % [keadaan, _sepeda.kecepatan_ud, _sepeda.lateral_ubin, _sepeda.jarak_ubin, _akar.mode_bantu(), _kontrol.router.kidal(), _akar.koran.sisa, _akar.koran_terbang().size(), _kontrol.tanda_tampil()])
	if _folder.is_empty():
		return
	var gambar: Image = root.get_texture().get_image()
	var berkas: String = "%s/%s_bantu_%s.png" % [_folder, _awalan, keadaan]
	var galat: int = gambar.save_png(berkas)
	print("tangkapan layar %dx%d (%s) ke %s (kode %d)" % [gambar.get_width(), gambar.get_height(), keadaan, berkas, galat])
