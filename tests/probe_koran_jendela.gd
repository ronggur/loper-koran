extends SceneTree
## Probe lemparan koran run fase2a-lemparan di jendela asli, non-headless (AC-12): memuat scene utama, menggerakkan stick dan swipe lewat
## event sentuh sintetis (piksel jendela, seperti dari perangkat), memajukan simulasi, sprite, dan partikel dengan langkah tetap
## `perbarui(1/60)` (bukan waktu dinding), lalu menyimpan tangkapan layar: garis bidik pendek dan panjang ke kedua sisi di santai dan
## ngebut (elips biasa dan elips sasaran sah), koran di puncak lengkung dengan bayangan, penanda kena kotak surat, teras, halaman, sisi
## dekat, jendela (penalti ringan), rumah bukan pelanggan, meleset, HUD koran sebagian/habis/terisi ulang, dan kidal. Panjang swipe
## untuk tiap sasaran dicari dengan `JalanUji.lintasan_swipe` + `KoranLempar.hasil_mendarat` (fungsi yang sama dengan game), jadi
## tangkapan menunjukkan sasaran yang benar-benar dikenai. Mencetak data tiap keadaan dan kotak teks HUD untuk
## `tools/cek_blok_piksel.py --kecualikan`. Tidak interaktif: keluar sendiri lewat `ProbeKeluar`.
##
## Pakai (jendela harus muat di layar monitor; 2340x1080 = viewport 780, 1920x1080 = 640):
##   godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_koran_jendela.gd -- docs/loop/<RUN_ID>/shots
## Berkas: `<lebar>x<tinggi>_koran_<keadaan>.png`. Periksa ketajaman dunia:
##   python3 tools/cek_blok_piksel.py 3 --kecualikan <kotak teks HUD> <png>   (kotak dicetak probe)

const FRAME_TUNGGU_LAYOUT: int = 5
const DT: float = 1.0 / 60.0
const TITIK_STICK: Vector2 = Vector2(100, 260)
## Tinggi jari swipe (piksel game) dan jarak titik awal swipe dari tepi zona.
const SWIPE_Y: float = 200.0
const SWIPE_AWAL_DEKAT_X: float = 230.0
const SWIPE_AWAL_SEBERANG_DARI_KANAN: float = 40.0
## Paling lama mencari panjang swipe untuk satu sasaran sambil sepeda maju, detik.
const CARI_DETIK: float = 6.0

var _skala: float = 1.0
var _folder: String = ""
var _awalan: String = ""
var _akar: JalanUji
var _sepeda: SepedaUji
var _hud: HudDev
var _sprite: LoperSprite
var _debu: PancaranPiksel
var _garis: PancaranPiksel
var _lebar: float = 0.0
var _gagal: int = 0


func _initialize() -> void:
	var argumen: PackedStringArray = OS.get_cmdline_user_args()
	_folder = argumen[0] if argumen.size() > 0 else ""
	var paket: PackedScene = load(str(ProjectSettings.get_setting("application/run/main_scene"))) as PackedScene
	if paket == null:
		push_error("scene utama tidak bisa dimuat")
		await ProbeKeluar.keluar(self, 1)
		return
	_akar = paket.instantiate() as JalanUji
	root.add_child(_akar)
	await _tunggu(FRAME_TUNGGU_LAYOUT)
	_akar.set_process(false)
	var terlihat: Vector2 = root.get_visible_rect().size
	_lebar = terlihat.x
	_skala = float(root.size.x) / terlihat.x
	_awalan = "%dx%d" % [root.size.x, root.size.y]
	_sepeda = _akar.find_child("Sepeda", true, false) as SepedaUji
	_hud = _akar.find_child("Hud", true, false) as HudDev
	_sprite = _akar.find_child("LoperAgen", true, false) as LoperSprite
	_sprite.set_process(false)
	_debu = _sepeda.umpan_balik().debu()
	_garis = _sepeda.umpan_balik().garis()
	_debu.set_process(false)
	_garis.set_process(false)
	(_akar.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = false
	print("jendela %s: viewport terlihat %dx%d, skala x%s (driver %s, renderer %s)" % [root.size, int(terlihat.x), int(terlihat.y), _skala, DisplayServer.get_name(), RenderingServer.get_current_rendering_method()])
	_cetak_kecualikan("HUD", [_hud.rect_tombol_kidal(), _hud.rect_panel_kecepatan(), _hud.rect_panel_koran()])

	# --- Santai (3,0 u/d): garis bidik pendek dan sasaran di sisi seberang ---
	await _maju(1.0)
	_tahan(LoperAnim.Sisi.SEBERANG, ThrowSolver.swipe_min_px(_lebar) + 2.0)
	await _maju(0.05)
	await _foto("bidik_pendek_seberang_santai")
	await _lempar_ke(LoperAnim.Sisi.SEBERANG, ZonaSasaran.Hasil.KOTAK_SURAT, "kotak_surat", true)
	await _lempar_ke(LoperAnim.Sisi.SEBERANG, ZonaSasaran.Hasil.TERAS, "teras", false)
	await _lempar_ke(LoperAnim.Sisi.SEBERANG, ZonaSasaran.Hasil.HALAMAN, "halaman", false)
	await _lempar_ke(LoperAnim.Sisi.SEBERANG, ZonaSasaran.Hasil.JENDELA, "jendela_penalti", false)
	await _lempar_ke(LoperAnim.Sisi.SEBERANG, ZonaSasaran.Hasil.BUKAN_PELANGGAN, "bukan_pelanggan", false)
	await _lempar_ke(LoperAnim.Sisi.SEBERANG, ZonaSasaran.Hasil.MELESET, "meleset", false)
	_tahan(LoperAnim.Sisi.DEKAT, ThrowSolver.swipe_maks_px(_lebar))
	await _maju(0.05)
	await _foto("bidik_panjang_dekat_santai")
	_lepas_swipe_tanpa_lempar()

	# --- Ngebut (6,0 u/d): garis bidik pendek dan panjang ke kedua sisi, sasaran sisi dekat ---
	_sentuh(0, TITIK_STICK, true)
	_geser(0, TITIK_STICK - Vector2(0, Config.STICK_RADIUS_PX))
	await _maju(2.5)
	_tahan(LoperAnim.Sisi.DEKAT, ThrowSolver.swipe_min_px(_lebar) + 2.0)
	await _maju(0.05)
	await _foto("bidik_pendek_dekat_ngebut")
	_tahan(LoperAnim.Sisi.SEBERANG, ThrowSolver.swipe_maks_px(_lebar))
	await _maju(0.05)
	await _foto("bidik_panjang_seberang_ngebut")
	_lepas_swipe_tanpa_lempar()
	await _lempar_ke(LoperAnim.Sisi.DEKAT, ZonaSasaran.Hasil.KOTAK_SURAT, "dekat_kotak_surat_ngebut", true)
	_sentuh(0, TITIK_STICK, false)
	await _maju(2.0)

	# --- HUD koran habis, lalu terisi ulang sesudah 16 ubin (alat uji jalan uji) ---
	while _akar.koran.sisa > 0:
		_akar.koran = SisaKoran.langkah(SisaKoran.terima(_akar.koran, _sepeda.jarak_ubin).keadaan, Config.LEMPAR_JEDA_DETIK)
	_tahan(LoperAnim.Sisi.SEBERANG, ThrowSolver.swipe_maks_px(_lebar))
	await _maju(0.05)
	print("habis: sisa %d, garis bidik tampil %s, teks '%s', penanda habis %s" % [_akar.koran.sisa, _akar.garis_bidik().tampil(), _hud.teks_koran(), _hud.penanda_habis_tampil()])
	await _foto("hud_habis")
	_lepas_swipe_tanpa_lempar()
	await _maju(Config.JALAN_UJI_ISI_ULANG_UBIN / Config.KECEPATAN_SANTAI_UD + 0.2)
	print("isi ulang: sisa %d, teks '%s'" % [_akar.koran.sisa, _hud.teks_koran()])
	await _foto("hud_isi_ulang")

	# --- Kidal: zona swipe di kiri layar, arti arah tidak berubah ---
	(_akar.find_child("TombolKidal", true, false) as Button).button_pressed = true
	await _tunggu(3)
	_cetak_kecualikan("kidal", [_hud.rect_tombol_kidal(), _hud.rect_panel_kecepatan(), _hud.rect_panel_koran()])
	var awal_kidal: Vector2 = Vector2(_lebar - Config.ZONA_SWIPE_X_MIN_PX - SWIPE_AWAL_SEBERANG_DARI_KANAN, SWIPE_Y)
	_sentuh(1, awal_kidal, true)
	_geser(1, awal_kidal - Vector2(ThrowSolver.swipe_maks_px(_lebar) * 0.6, 0))
	await _maju(0.05)
	await _foto("kidal_bidik_seberang")
	_lepas_swipe_tanpa_lempar()
	print("probe selesai, %d sasaran tidak ditemukan" % _gagal)
	await ProbeKeluar.keluar(self, 0 if _gagal == 0 else 1)


## Titik awal swipe ke `sisi` (tangan kanan): ke seberang mulai dekat tepi kanan zona dan bergerak ke kiri, ke dekat sebaliknya.
func _awal_swipe(sisi: LoperAnim.Sisi) -> Vector2:
	if sisi == LoperAnim.Sisi.SEBERANG:
		return Vector2(_lebar - Config.ZONA_SWIPE_TEPI_PX - SWIPE_AWAL_SEBERANG_DARI_KANAN, SWIPE_Y)
	return Vector2(SWIPE_AWAL_DEKAT_X, SWIPE_Y)


func _akhir_swipe(sisi: LoperAnim.Sisi, dx: float) -> Vector2:
	return _awal_swipe(sisi) + Vector2(-dx if sisi == LoperAnim.Sisi.SEBERANG else dx, 0)


## Menahan jari swipe (index 1) dengan |dx| = `dx` ke `sisi` (turun bila belum, lalu geser).
func _tahan(sisi: LoperAnim.Sisi, dx: float) -> void:
	var router: TouchRouter = (_akar.find_child("KontrolTouch", true, false) as KontrolTouch).router
	if not router.swipe_aktif():
		_sentuh(1, _awal_swipe(sisi), true)
	elif router.awal_swipe().distance_to(_awal_swipe(sisi)) > 1.0:
		_lepas_swipe_tanpa_lempar()
		_sentuh(1, _awal_swipe(sisi), true)
	_geser(1, _akhir_swipe(sisi, dx))


## Mengangkat jari swipe tanpa melempar: digeser kembali ke titik awal (|dx| 0) lalu diangkat.
func _lepas_swipe_tanpa_lempar() -> void:
	var router: TouchRouter = (_akar.find_child("KontrolTouch", true, false) as KontrolTouch).router
	if router.swipe_aktif():
		var awal: Vector2 = router.awal_swipe()
		_geser(1, awal)
		_sentuh(1, awal, false)


## Panjang swipe (piksel game) yang membuat koran mendarat dengan hasil `sasaran` dari keadaan sepeda SAAT INI, atau -1.
func _cari_dx(sisi: LoperAnim.Sisi, sasaran: ZonaSasaran.Hasil) -> float:
	var dx: float = ceilf(ThrowSolver.swipe_min_px(_lebar))
	while dx <= ThrowSolver.swipe_maks_px(_lebar):
		var lintasan: ThrowSolver.Lintasan = _akar.lintasan_swipe(_awal_swipe(sisi), _akhir_swipe(sisi, dx))
		if lintasan != null and KoranLempar.hasil_mendarat(lintasan) == sasaran:
			return dx
		dx += 1.0
	return -1.0


## Mencari swipe untuk `sasaran` sambil sepeda maju, menahan garis bidik ke sana (foto bila `foto_bidik`), melempar, memotret koran di
## puncak lengkung (bila `foto_bidik`) dan penanda sesudah mendarat.
func _lempar_ke(sisi: LoperAnim.Sisi, sasaran: ZonaSasaran.Hasil, nama: String, foto_bidik: bool) -> void:
	var dx: float = -1.0
	var kena: bool = false
	var garis: GarisBidik = _akar.garis_bidik()
	# Jari ditahan di panjang yang mengenai sasaran menurut keadaan saat ini, lalu satu langkah: garis bidik dihitung ulang dari keadaan
	# baru. Jari dilepas hanya bila garis bidik yang TAMPIL (keadaan yang juga dipakai lemparan) mengarah ke sasaran.
	for i: int in range(roundi(CARI_DETIK / DT)):
		dx = _cari_dx(sisi, sasaran)
		if dx > 0.0 and SisaKoran.boleh_lempar(_akar.koran):
			_tahan(sisi, dx)
		else:
			_lepas_swipe_tanpa_lempar()
		await _maju(DT, false)
		if garis.tampil() and KoranLempar.hasil_mendarat(garis.lintasan()) == sasaran:
			kena = true
			break
	if not kena:
		print("PERINGATAN: sasaran %s tidak ditemukan dalam %s detik" % [nama, CARI_DETIK])
		_lepas_swipe_tanpa_lempar()
		_gagal += 1
		return
	await _tunggu(2)
	print("%s: |dx| %.1f px, garis bidik tampil %s, elips sah %s (bentuk %s), titik akhir %s, sisa koran %d" % [nama, dx, garis.tampil(), garis.elips_sah(), KoranLempar.Elips.keys()[garis.bentuk_elips()], garis.titik_akhir(), _akar.koran.sisa])
	if foto_bidik:
		await _foto("bidik_%s" % nama)
	var sisa_sebelum: int = _akar.koran.sisa
	_sentuh(1, _akhir_swipe(sisi, dx), false)
	var terbang: Array[KoranLempar.Koran] = _akar.koran_terbang()
	if _akar.koran.sisa != sisa_sebelum - 1 or terbang.is_empty():
		print("PERINGATAN: lemparan %s tidak diterima" % nama)
		_gagal += 1
		return
	var lintasan: ThrowSolver.Lintasan = terbang[terbang.size() - 1].lintasan
	if foto_bidik:
		var puncak_s: float = lintasan.lengkung_b / (lintasan.lengkung_a * 2.0)
		await _maju(lintasan.jeda_lepas + puncak_s * lintasan.lama_terbang)
		var koran: KoranLempar.Koran = _akar.koran_terbang()[_akar.koran_terbang().size() - 1]
		print("%s puncak: posisi %s (tinggi %.2f ubin, puncak %.2f), bayangan %d px" % [nama, KoranLempar.posisi(koran), KoranLempar.posisi(koran).z, lintasan.tinggi_puncak, KoranLempar.lebar_bayangan_px(KoranLempar.posisi(koran).z)])
		await _foto("puncak_%s" % nama)
	var mendarat: Array = []
	var sambung: Callable = func(k: KoranLempar.Koran) -> void: mendarat.append(k)
	_akar.koran_mendarat.connect(sambung)
	var langkah: int = 0
	while mendarat.is_empty() and langkah < roundi(2.0 / DT):
		await _maju(DT, false)
		langkah += 1
	_akar.koran_mendarat.disconnect(sambung)
	if mendarat.is_empty():
		print("PERINGATAN: koran %s tidak mendarat" % nama)
		_gagal += 1
		return
	var hasil: KoranLempar.Koran = mendarat[0]
	await _maju(0.15)
	print("%s mendarat: hasil %s (diharapkan %s), antaran %s, penanda %s, titik %s = prediksi %s" % [nama, ZonaSasaran.Hasil.keys()[hasil.hasil], ZonaSasaran.Hasil.keys()[sasaran], ZonaSasaran.Antaran.keys()[hasil.antaran], ZonaSasaran.Penanda.keys()[hasil.penanda], KoranLempar.posisi(hasil), lintasan.titik_mendarat])
	if hasil.hasil != sasaran:
		_gagal += 1
	await _foto("kena_%s" % nama)
	await _maju(Config.PENANDA_LAMA_DETIK)


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


func _geser(index: int, posisi_viewport: Vector2) -> void:
	var peristiwa: InputEventScreenDrag = InputEventScreenDrag.new()
	peristiwa.index = index
	peristiwa.position = posisi_viewport * _skala
	Input.parse_input_event(peristiwa)
	Input.flush_buffered_events()


func _foto(keadaan: String) -> void:
	await _tunggu(3)
	print("%s: kecepatan %.2f u/d, lateral %.2f, jarak %.2f ubin, sisa koran %d (HUD '%s', ikon %s, habis %s), koran tampil %d, garis bidik %s (elips sah %s, bentuk %s)" % [keadaan, _sepeda.kecepatan_ud, _sepeda.lateral_ubin, _sepeda.jarak_ubin, _akar.koran.sisa, _hud.teks_koran(), _hud.ikon_koran(), _hud.penanda_habis_tampil(), _akar.koran_terbang().size(), _akar.garis_bidik().tampil(), _akar.garis_bidik().elips_sah(), KoranLempar.Elips.keys()[_akar.garis_bidik().bentuk_elips()]])
	if _folder.is_empty():
		return
	var gambar: Image = root.get_texture().get_image()
	var berkas: String = "%s/%s_koran_%s.png" % [_folder, _awalan, keadaan]
	var galat: int = gambar.save_png(berkas)
	print("tangkapan layar %dx%d (%s) ke %s (kode %d)" % [gambar.get_width(), gambar.get_height(), keadaan, berkas, galat])
