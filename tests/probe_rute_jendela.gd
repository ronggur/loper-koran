extends SceneTree
## Probe scene rute di jendela asli, non-headless (AC-12 sampai AC-15 run fase3a-rute): memuat `scenes/rute/rute.tscn` (scene utama),
## memajukan simulasi, sprite, dan partikel dengan langkah tetap `perbarui(1/60)` (bukan waktu dinding), lalu menyimpan tangkapan
## layar: awal rute, tengah rute dengan rumah dan kotak surat, objek uji yang menutupi pemain (semi-transparan; rumah rute di tepi
## jalan praktis tidak pernah menutupi, D-8 run 3A, jadi probe menaruh satu rumah uji lebih dekat ke jalan), mode bantu (koran bantu ke
## kotak surat pelanggan dan centang), garis finish dengan portal (run garis-finish-portal bagian C: portal tertutup jauh dan mendekat, terbuka, sepeda tepat di garis, keluar dalam tiga tahap,
## banner saat hampir keluar, layar hasil di atas dunia portal; Bagian F: hiasan perumahan di depan portal, sepeda keluar dengan laju ngebut), "Main lagi" (seed berikutnya, kamera mengikuti lagi, portal tertutup), dan kidal. Titik ketukan digambar sebagai titik 2 px game warna `ACCENT` di lapisan probe (bukan bagian game). Mencetak data tiap
## keadaan dan kotak teks HUD untuk `tools/cek_blok_piksel.py --kecualikan`. Tidak interaktif: keluar sendiri lewat `ProbeKeluar`.
##
## Pakai (jendela harus muat di layar monitor):
##   godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_rute_jendela.gd -- docs/loop/<RUN_ID>/shots
##   godot --path . --resolution 1600x720 --position 0,0 --script res://tests/probe_rute_jendela.gd -- docs/loop/<RUN_ID>/shots
## Berkas: `<lebar>x<tinggi>_rute_<keadaan>.png`.

const BERKAS_RUTE: String = "res://scenes/rute/rute.tscn"
const BERKAS_RUMAH_UJI: String = "res://assets/sprites/houses/perumahan/house_perumahan_dekat_limasan_bukan.png"
const FRAME_TUNGGU_LAYOUT: int = 5
const DT: float = 1.0 / 60.0
## Titik ketukan relatif titik pijak sepeda di layar (piksel game): seberang di atas garis jalan, di zona swipe kanan.
const TAP_SEBERANG: Vector2 = Vector2(200, -150)
const TAP_KIDAL_SEBERANG: Vector2 = Vector2(150, 120)
## Maju sepeda (ubin) untuk foto tengah rute.
const MAJU_TENGAH: float = 92.0
## Foto koran terbang diambil di pecahan lama terbang ini sesudah jeda lepas.
const FOTO_TERBANG_PECAHAN: float = 0.5

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
var _lapis: CanvasLayer


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
	_lapis = CanvasLayer.new()
	_lapis.layer = 50
	root.add_child(_lapis)
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
	var rute: RouteBuilder.Rute = _akar.rute()
	print("jendela %s: viewport terlihat %dx%d, skala x%s (driver %s, renderer %s)" % [root.size, int(terlihat.x), int(terlihat.y), _skala, DisplayServer.get_name(), RenderingServer.get_current_rendering_method()])
	print("rute: seed %d, %d segmen, panjang %.0f ubin, %d rumah, %d pelanggan, koran awal %d, galat %s" % [_akar.benih(), rute.segmen.size(), rute.panjang_ubin, rute.rumah.size(), rute.pelanggan.size(), rute.koran_awal, _akar.galat_rute()])
	_cetak_kecualikan("HUD", [_hud.rect_tombol_jeda(), _hud.rect_panel_progres(), _hud.rect_panel_kecepatan(), _hud.rect_panel_koran()])

	# --- Awal rute ---
	await _maju(0.5)
	await _foto("awal")

	# --- Tengah rute: rumah dan kotak surat dari data ---
	_sepeda.jarak_ubin = MAJU_TENGAH
	await _maju(0.5)
	await _foto("tengah")

	# --- Objek uji yang menutupi pemain (rumah uji 2 ubin lebih dekat ke jalan dari rumah dekat biasa) ---
	var uji: Sprite2D = _taruh_rumah_uji()
	await _maju(DT)
	var menutupi: int = _akar.penerap_penutup().jumlah_menutupi()
	print("objek uji: menutupi %d, alfa %.2f" % [menutupi, uji.modulate.a])
	if menutupi != 1 or not is_equal_approx(uji.modulate.a, Config.RUTE_PENUTUP_ALFA):
		_gagal += 1
	await _foto("menutupi")
	_akar.penerap_penutup().lepas(uji)
	uji.queue_free()
	await _maju(DT)

	# --- Mode bantu: koran bantu ke kotak surat pelanggan seberang ---
	_akar.atur_mode_bantu(true)
	await _tunggu(3)
	_sepeda.jarak_ubin = float(_akar.rute().pelanggan[8].maju_ubin) - 5.0
	await _maju(Config.LEMPAR_JEDA_DETIK)
	await _lempar_bantu("bantu", false)

	# --- Portal garis finish (run garis-finish-portal bagian C): tertutup jauh, masih tertutup, terbuka ---
	var panjang: float = _akar.rute().panjang_ubin
	_akar.atur_mode_bantu(false)
	await _tunggu(3)
	await _ke_sebelum_garis(panjang - 15.0)
	await _periksa_portal("portal_jauh", 0)
	await _ke_sebelum_garis(panjang - 7.0)
	await _periksa_portal("portal_tertutup_mendekat", 0)
	await _ke_sebelum_garis(panjang - 4.0)
	await _periksa_portal("portal_terbuka", 1)

	# --- Garis akhir: sepeda tepat di garis, kamera beku, banner belum tampil ---
	await _sampai(func() -> bool: return _akar.rute_sudah_selesai(), 6.0)
	var kamera_garis: Vector2 = _akar.find_child("Kamera", true, false).position
	print("garis: selesai %s, fase %s, banner tampil %s, kamera beku %s, jarak %.2f dari %.0f" % [_akar.rute_sudah_selesai(), AkhirRute.Fase.keys()[_akar.fase_keluar()], _akar.panel_akhir().tampil(), _akar.kamera_beku(), _sepeda.jarak_ubin, panjang])
	if not _akar.rute_sudah_selesai() or _akar.panel_akhir().tampil() or not _akar.kamera_beku() or _akar.hasil_tampil():
		_gagal += 1
	# Bagian F (F-1): hiasan perumahan tetap tergambar di depan portal sementara kamera beku.
	print("hiasan di garis: %d rumah, %d dekor tergambar (rute hiasan %d rumah, %d dekor), kotak surat oranye hiasan %d" % [_akar.rumah_hiasan().jumlah_rumah(), _akar.dekor_hiasan().jumlah_tampil(), _akar.hiasan().rumah.size(), _akar.hiasan().dekor.size(), _akar.rumah_hiasan().jumlah_kotak_surat()])
	if _akar.rumah_hiasan().jumlah_rumah() < 3 or _akar.dekor_hiasan().jumlah_tampil() < 1 or _akar.rumah_hiasan().jumlah_kotak_surat() != 0:
		_gagal += 1
	await _foto("garis")

	# --- Keluar: tiga tahap (sepeda melewati portal, hampir keluar dengan banner, setengah badan di luar layar) lalu layar hasil ---
	await _maju(0.5)
	await _foto("keluar_1")
	await _sampai(func() -> bool: return _akar.hampir_keluar(), 6.0)
	_cetak_kecualikan("banner", [_hud.rect_tombol_jeda(), _hud.rect_panel_progres(), _hud.rect_panel_kecepatan(), _hud.rect_panel_koran(), _akar.panel_akhir().rect_banner()])
	print("hampir keluar: sisa %.2f ubin, banner tampil %s, hasil tampil %s, fase %s" % [_sisa_keluar(), _akar.panel_akhir().tampil(), _akar.hasil_tampil(), AkhirRute.Fase.keys()[_akar.fase_keluar()]])
	if not _akar.panel_akhir().tampil() or _akar.hasil_tampil() or _sisa_keluar() <= 0.0:
		_gagal += 1
	await _foto("keluar_2_banner")
	await _sampai(func() -> bool: return _sisa_keluar() < 1.5, 6.0)
	await _foto("keluar_3")
	await _sampai(func() -> bool: return _akar.hasil_tampil(), 6.0)
	print("hasil: tampil %s, banner tampil %s, fase %s, sepeda di layar %s (sisa %.2f), kamera %s (garis %s)" % [_akar.hasil_tampil(), _akar.panel_akhir().tampil(), AkhirRute.Fase.keys()[_akar.fase_keluar()], _akar.posisi_layar_sepeda(), _sisa_keluar(), _akar.find_child("Kamera", true, false).position, kamera_garis])
	if not _akar.hasil_tampil() or _akar.panel_akhir().tampil() or _sisa_keluar() > 0.0 or _akar.find_child("Kamera", true, false).position != kamera_garis:
		_gagal += 1
	await _maju(0.5)
	if _akar.rumah_hiasan().jumlah_rumah() < 3:
		_gagal += 1
	await _foto("hasil")

	# --- Main lagi: seed berikutnya, kamera mengikuti lagi, portal tertutup ---
	var seed_awal: int = _akar.benih()
	_akar.main_lagi()
	await _maju(0.5)
	print("main lagi: seed %d -> %d, jarak %.2f, koran %d, banner tampil %s, kamera beku %s, portal bingkai %d" % [seed_awal, _akar.benih(), _sepeda.jarak_ubin, _akar.koran.sisa, _akar.panel_akhir().tampil(), _akar.kamera_beku(), _akar.portal().bingkai()])
	if _akar.benih() != seed_awal + 1 or _akar.koran.sisa != _akar.rute().koran_awal or _akar.panel_akhir().tampil() or _akar.kamera_beku() or _akar.portal().bingkai() != 0 or _akar.hasil_tampil():
		_gagal += 1
	await _foto("main_lagi")

	# --- Kidal: zona tertukar, garis, banner, dan layar hasil ---
	_akar.atur_kidal(true)
	await _tunggu(3)
	panjang = _akar.rute().panjang_ubin
	await _ke_sebelum_garis(panjang - 5.0)
	await _sampai(func() -> bool: return _akar.rute_sudah_selesai(), 6.0)
	await _foto("kidal_garis")
	await _sampai(func() -> bool: return _akar.hampir_keluar(), 6.0)
	_cetak_kecualikan("kidal", [_hud.rect_tombol_jeda(), _hud.rect_panel_progres(), _hud.rect_panel_kecepatan(), _hud.rect_panel_koran(), _akar.panel_akhir().rect_banner()])
	await _foto("kidal_banner")
	await _sampai(func() -> bool: return _akar.hasil_tampil(), 6.0)
	await _maju(0.5)
	await _foto("kidal_hasil")
	print("probe selesai, %d keadaan tidak sesuai" % _gagal)
	await ProbeKeluar.keluar(self, 0 if _gagal == 0 else 1)


## Rumah uji di dekat jalan: tapak 2 ubin lebih dekat ke jalan dari rumah sisi dekat biasa, di depan-belakang sepeda sehingga sinar
## ke kamera dari kaki pemain melewatinya (`PenutupPemain`). Didaftarkan ke penerap yang sama dengan rumah rute.
func _taruh_rumah_uji() -> Sprite2D:
	var posisi: Vector2 = _sepeda.posisi_dunia()
	var tapak: Rect2 = Rect2(Config.RUTE_RUMAH_DEKAT_X_UBIN - 2.0, -posisi.y - 1.5, Config.RUTE_RUMAH_DALAM_UBIN, Config.RUTE_RUMAH_PANJANG_UBIN)
	var objek: PenutupPemain.Objek = PenutupPemain.buat(tapak, Config.RUTE_RUMAH_TINGGI_UBIN, "uji")
	var gambar: Sprite2D = Sprite2D.new()
	gambar.texture = load(BERKAS_RUMAH_UJI) as Texture2D
	gambar.centered = false
	gambar.offset = -Vector2(97, 123)
	var pusat: Vector2 = tapak.get_center()
	gambar.position = Iso.posisi_gambar(Vector2(pusat.x, -pusat.y))
	_akar.daur().add_child(gambar)
	_akar.penerap_penutup().daftarkan(gambar, objek)
	return gambar


## Mengetuk zona swipe (mode bantu menyala), memotret koran terbang lalu penanda di kotak surat pelanggan.
func _lempar_bantu(nama: String, kidal: bool) -> void:
	var detik: float = 0.0
	while _akar.pilihan_bantu(LoperAnim.Sisi.SEBERANG) == null and detik < 6.0:
		await _maju(DT, false)
		detik += DT
	var pilihan: BantuLempar.Pilihan = _akar.pilihan_bantu(LoperAnim.Sisi.SEBERANG)
	if pilihan == null:
		print("PERINGATAN %s: tidak ada sasaran bantu dalam 6 detik" % nama)
		_gagal += 1
		return
	var tap: Vector2 = TAP_KIDAL_SEBERANG if kidal else _akar.posisi_layar_sepeda() + TAP_SEBERANG
	var sebelum: int = _akar.koran_terbang().size()
	var sisa: int = _akar.koran.sisa
	_tap(tap)
	print("%s: tap %s, sasaran %s, koran %d -> %d" % [nama, tap, pilihan.zona.id_rumah, sisa, _akar.koran.sisa])
	if _akar.koran_terbang().size() != sebelum + 1:
		print("PERINGATAN %s: ketukan tidak melempar" % nama)
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


## Menaruh sepeda di `jarak` ubin (santai, lateral 0), lalu memajukan setengah detik supaya dunia dan portal menyesuaikan.
func _ke_sebelum_garis(jarak: float) -> void:
	var k: BikeMotion.Keadaan = _sepeda.keadaan.salin()
	k.kecepatan_ud = Config.KECEPATAN_SANTAI_UD
	k.lateral_ubin = 0.0
	_sepeda.keadaan = k
	_sepeda.jarak_ubin = jarak
	await _maju(0.3)


## Memajukan langkah demi langkah sampai `kondisi` benar (paling lama `maks_detik`); keadaan tidak sesuai bila tidak tercapai.
func _sampai(kondisi: Callable, maks_detik: float) -> void:
	var langkah: int = 0
	while not bool(kondisi.call()) and float(langkah) * DT < maks_detik:
		await _maju(DT, false)
		langkah += 1
	if not bool(kondisi.call()):
		print("PERINGATAN: kondisi tidak tercapai dalam %.1f detik" % maks_detik)
		_gagal += 1
	await _tunggu(2)


## Sisa ubin sampai seluruh badan sepeda di luar viewport (`AkhirRute.sisa_ubin_keluar` dari posisi layar nyata).
func _sisa_keluar() -> float:
	return AkhirRute.sisa_ubin_keluar(_akar.posisi_layar_sepeda(), _akar.get_viewport_rect().size)


## Portal bingkai `harapan` (0 tertutup, 1 terbuka) pada jarak sepeda sekarang, dan foto `keadaan`.
func _periksa_portal(keadaan: String, harapan: int) -> void:
	var portal: PortalGaris = _akar.portal()
	print("%s: sisa ke garis %.2f ubin, bingkai %d (harapan %d), portal tampil %s, di layar %s" % [keadaan, _akar.rute().panjang_ubin - _sepeda.jarak_ubin, portal.bingkai(), harapan, portal.visible, portal.get_global_transform_with_canvas().origin])
	if portal.bingkai() != harapan or not portal.visible:
		_gagal += 1
	await _foto(keadaan)


func _koran_ini(koran: KoranLempar.Koran) -> KoranLempar.Koran:
	for k: KoranLempar.Koran in _akar.koran_terbang():
		if k.lintasan == koran.lintasan:
			return k
	return koran


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
	print("%s: kecepatan %.2f u/d, lateral %.2f, jarak %.2f ubin, mode bantu %s, kidal %s, sisa koran %d, rumah tampil %d, kotak surat %d, menutupi %d" % [keadaan, _sepeda.kecepatan_ud, _sepeda.lateral_ubin, _sepeda.jarak_ubin, _akar.mode_bantu(), _kontrol.router.kidal(), _akar.koran.sisa, _akar.daur().jumlah_rumah(), _akar.daur().jumlah_kotak_surat(), _akar.penerap_penutup().jumlah_menutupi()])
	if _folder.is_empty():
		return
	var gambar: Image = root.get_texture().get_image()
	var berkas: String = "%s/%s_rute_%s.png" % [_folder, _awalan, keadaan]
	var galat: int = gambar.save_png(berkas)
	print("tangkapan layar %dx%d (%s) ke %s (kode %d)" % [gambar.get_width(), gambar.get_height(), keadaan, berkas, galat])
