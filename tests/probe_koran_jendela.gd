extends SceneTree
## Probe lemparan koran di jendela asli, non-headless (AC-12 run fase2a-lemparan; arah bebas AC-10 run fase2-arah-bebas): memuat scene
## utama, menggerakkan stick dan swipe lewat event sentuh sintetis (piksel jendela, seperti dari perangkat), memajukan simulasi, sprite, dan
## partikel dengan langkah tetap `perbarui(1/60)` (bukan waktu dinding), lalu menyimpan tangkapan layar. Arah bebas: swipe ke ATAS ke
## kotak surat seberang di depan (santai dan ngebut), swipe ke KANAN ke kotak surat sisi dekat, swipe ke KIRI murni (mendarat seberang
## sedikit ke belakang), garis bidik pendek dan panjang ke beberapa arah, koran di puncak lengkung dengan bayangan, penanda kena teras,
## halaman, jendela (penalti ringan), rumah bukan pelanggan, meleset, HUD koran habis/terisi ulang, dan kidal (swipe ke atas dan ke kiri).
## Jalur jari (titik awal ke titik akhir swipe) digambar sebagai titik-titik 2 px game warna `ACCENT` di lapisan probe (bukan bagian
## game) supaya tangkapan menunjukkan garis bidik sejajar arah jari; probe juga mencetak sudut jari dan sudut garis tanah lemparan.
## Panjang dan sudut swipe untuk tiap sasaran dicari dengan `JalanUji.lintasan_swipe` + `KoranLempar.hasil_mendarat` (fungsi yang sama
## dengan game), jadi tangkapan menunjukkan sasaran yang benar-benar dikenai. Mencetak data tiap keadaan dan kotak teks HUD untuk
## `tools/cek_blok_piksel.py --kecualikan`. Tidak interaktif: keluar sendiri lewat `ProbeKeluar`.
##
## Pakai (jendela harus muat di layar monitor; 2340x1080 = viewport 780, 1920x1080 = 640):
##   godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_koran_jendela.gd -- docs/loop/<RUN_ID>/shots
## Berkas: `<lebar>x<tinggi>_koran_<keadaan>.png`. Periksa ketajaman dunia:
##   python3 tools/cek_blok_piksel.py 3 --kecualikan <kotak teks HUD> <png>   (kotak dicetak probe)

const FRAME_TUNGGU_LAYOUT: int = 5
const DT: float = 1.0 / 60.0
const TITIK_STICK: Vector2 = Vector2(100, 260)
## Tinggi jari swipe mendatar (piksel game) dan jarak titik awal swipe dari tepi zona.
const SWIPE_Y: float = 200.0
const SWIPE_AWAL_DEKAT_X: float = 230.0
const SWIPE_AWAL_SEBERANG_DARI_KANAN: float = 40.0
## Titik awal swipe ke atas: tinggi jari (dekat bawah zona swipe) dan letak mendatar sebagai pecahan lebar viewport.
const SWIPE_ATAS_Y: float = 330.0
const SWIPE_ATAS_X_PECAHAN: float = 0.62
## Paling lama mencari swipe untuk satu sasaran sambil sepeda maju, detik.
const CARI_DETIK: float = 6.0
## Langkah pencarian sudut (derajat) dan panjang (piksel game) swipe.
const CARI_SUDUT_LANGKAH: float = 3.0
const CARI_PANJANG_LANGKAH: float = 2.0
## Jarak antar titik jalur jari di lapisan probe, piksel game.
const JARI_TITIK_JARAK: float = 5.0

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
## Lapisan probe untuk jalur jari (titik ColorRect 2x2 di koordinat game bulat).
var _lapis_jari: CanvasLayer


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
	_lapis_jari = CanvasLayer.new()
	_lapis_jari.layer = 50
	root.add_child(_lapis_jari)
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
	var awal_naik: Vector2 = _awal_atas()
	var awal_dekat: Vector2 = Vector2(SWIPE_AWAL_DEKAT_X, SWIPE_Y)
	var awal_seberang: Vector2 = Vector2(_lebar - Config.ZONA_SWIPE_TEPI_PX - SWIPE_AWAL_SEBERANG_DARI_KANAN, SWIPE_Y)

	# --- Santai (3,0 u/d): swipe ke atas ke seberang di depan, ke kanan ke sisi dekat, ke kiri murni ---
	await _maju(1.0)
	_tahan(awal_naik, _akhir_sudut(awal_naik, 90.0, ThrowSolver.swipe_min_px(_lebar) + 2.0))
	await _maju(0.05)
	await _foto("bidik_pendek_atas_santai")
	await _lempar_ke(awal_naik, 60.0, 120.0, _kotak_seberang_depan, "atas_kotak_surat_seberang", true)
	await _lempar_ke(awal_dekat, -20.0, 20.0, _kotak_dekat, "kanan_kotak_surat_dekat", true)
	await _lempar_kiri_murni()
	await _lempar_ke(awal_naik, 30.0, 150.0, _hasil_adalah.bind(ZonaSasaran.Hasil.TERAS), "teras", false)
	await _lempar_ke(awal_naik, 30.0, 150.0, _hasil_adalah.bind(ZonaSasaran.Hasil.HALAMAN), "halaman", false)
	await _lempar_ke(awal_naik, 30.0, 150.0, _hasil_adalah.bind(ZonaSasaran.Hasil.JENDELA), "jendela_penalti", false)
	await _lempar_ke(awal_naik, 30.0, 150.0, _hasil_adalah.bind(ZonaSasaran.Hasil.BUKAN_PELANGGAN), "bukan_pelanggan", false)
	await _lempar_ke(awal_naik, 30.0, 150.0, _hasil_adalah.bind(ZonaSasaran.Hasil.MELESET), "meleset", false)
	_tahan(awal_dekat, _akhir_sudut(awal_dekat, 0.0, ThrowSolver.swipe_maks_px(_lebar)))
	await _maju(0.05)
	await _foto("bidik_panjang_kanan_santai")
	_tahan(awal_naik, _akhir_sudut(awal_naik, 120.0, ThrowSolver.swipe_maks_px(_lebar) * 0.8))
	await _maju(0.05)
	await _foto("bidik_kiri_atas_santai")
	_lepas_swipe_tanpa_lempar()

	# --- Ngebut (6,0 u/d): garis bidik ke beberapa arah, kotak surat seberang di depan dan sisi dekat ---
	_sentuh(0, TITIK_STICK, true)
	_geser(0, TITIK_STICK - Vector2(0, Config.STICK_RADIUS_PX))
	await _maju(2.5)
	_tahan(awal_dekat, _akhir_sudut(awal_dekat, 0.0, ThrowSolver.swipe_min_px(_lebar) + 2.0))
	await _maju(0.05)
	await _foto("bidik_pendek_kanan_ngebut")
	_tahan(awal_naik, _akhir_sudut(awal_naik, 90.0, ThrowSolver.swipe_maks_px(_lebar)))
	await _maju(0.05)
	await _foto("bidik_panjang_atas_ngebut")
	_tahan(awal_naik, _akhir_sudut(awal_naik, 270.0, ThrowSolver.swipe_min_px(_lebar) + 10.0))
	await _maju(0.05)
	await _foto("bidik_bawah_ngebut")
	_lepas_swipe_tanpa_lempar()
	await _lempar_ke(awal_naik, 45.0, 135.0, _kotak_seberang_depan, "atas_kotak_surat_seberang_ngebut", true)
	await _lempar_ke(awal_dekat, -20.0, 20.0, _kotak_dekat, "kanan_kotak_surat_dekat_ngebut", false)
	# --- Berhenti (rem, stick ditarik penuh ke bawah): tanpa warisan maju, garis tanah garis bidik sejajar jari persis ---
	_geser(0, TITIK_STICK + Vector2(0, Config.STICK_RADIUS_PX))
	await _maju(3.0)
	print("berhenti: kecepatan %.2f u/d" % _sepeda.kecepatan_ud)
	for kasus: Array in [["atas_kiri", 120.0], ["atas_kanan", 60.0], ["kiri", 180.0], ["bawah", 270.0]]:
		var asal: Vector2 = awal_naik if kasus[1] < 180.0 else awal_seberang if kasus[1] == 180.0 else Vector2(_awal_atas().x, SWIPE_Y - 60.0)
		var ujung: Vector2 = _akhir_sudut(asal, kasus[1], ThrowSolver.swipe_maks_px(_lebar) * 0.7)
		_tahan(asal, ujung)
		await _maju(0.05)
		_cetak_sejajar("berhenti_%s" % kasus[0], asal, ujung, _akar.garis_bidik().lintasan())
		var l: ThrowSolver.Lintasan = _akar.garis_bidik().lintasan()
		var tanah: Vector2 = Iso.dunia_ke_layar(l.titik_mendarat) - Iso.dunia_ke_layar(l.titik_lepas)
		print("berhenti_%s: garis tanah lepas -> elips di layar %.1f derajat (jari %.1f), geser maju %.3f ubin" % [kasus[0], _sudut(tanah), kasus[1], l.geser_maju])
		await _foto("bidik_sejajar_berhenti_%s" % kasus[0])
	_lepas_swipe_tanpa_lempar()
	_sentuh(0, TITIK_STICK, false)
	await _maju(2.0)

	# --- HUD koran habis, lalu terisi ulang sesudah 16 ubin (alat uji jalan uji) ---
	while _akar.koran.sisa > 0:
		_akar.koran = SisaKoran.langkah(SisaKoran.terima(_akar.koran, _sepeda.jarak_ubin).keadaan, Config.LEMPAR_JEDA_DETIK)
	_tahan(awal_naik, _akhir_sudut(awal_naik, 90.0, ThrowSolver.swipe_maks_px(_lebar)))
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
	var atas_kidal: Vector2 = Vector2(_lebar - _awal_atas().x, SWIPE_ATAS_Y)
	_tahan(atas_kidal, _akhir_sudut(atas_kidal, 90.0, ThrowSolver.swipe_maks_px(_lebar) * 0.6))
	await _maju(0.05)
	await _foto("kidal_bidik_atas")
	var awal_kidal: Vector2 = Vector2(_lebar - Config.ZONA_SWIPE_X_MIN_PX - SWIPE_AWAL_SEBERANG_DARI_KANAN, SWIPE_Y)
	_tahan(awal_kidal, _akhir_sudut(awal_kidal, 180.0, ThrowSolver.swipe_maks_px(_lebar) * 0.6))
	await _maju(0.05)
	await _foto("kidal_bidik_kiri")
	_lepas_swipe_tanpa_lempar()
	print("probe selesai, %d sasaran tidak ditemukan" % _gagal)
	await ProbeKeluar.keluar(self, 0 if _gagal == 0 else 1)


## Titik awal swipe ke atas (tangan kanan): dekat bawah zona swipe, di kanan tengah layar.
func _awal_atas() -> Vector2:
	return Vector2(roundf(_lebar * SWIPE_ATAS_X_PECAHAN), SWIPE_ATAS_Y)


## Titik akhir swipe dari `awal` ke sudut layar `derajat` (0 = kanan, 90 = atas) sepanjang `panjang` piksel game.
func _akhir_sudut(awal: Vector2, derajat: float, panjang: float) -> Vector2:
	return awal + Vector2(cos(deg_to_rad(derajat)), -sin(deg_to_rad(derajat))) * panjang


## Sudut layar (derajat 0 sampai 360, 0 = kanan, 90 = atas) vektor `v`.
func _sudut(v: Vector2) -> float:
	return fposmod(rad_to_deg(atan2(-v.y, v.x)), 360.0)


func _zona_kena(l: ThrowSolver.Lintasan) -> ZonaSasaran.Zona:
	return ZonaSasaran.zona_kena(l.titik_mendarat, ZonaSasaran.zona_jalan_uji_sekitar(ZonaSasaran.ke_jalan(l.titik_mendarat).y))


## Kotak surat seberang rumah pelanggan yang zonanya di depan sepeda (AC-6).
func _kotak_seberang_depan(l: ThrowSolver.Lintasan) -> bool:
	if KoranLempar.hasil_mendarat(l) != ZonaSasaran.Hasil.KOTAK_SURAT:
		return false
	var zona: ZonaSasaran.Zona = _zona_kena(l)
	return zona.sisi == LoperAnim.Sisi.SEBERANG and zona.persegi.position.y > _sepeda.jarak_ubin


func _kotak_dekat(l: ThrowSolver.Lintasan) -> bool:
	return KoranLempar.hasil_mendarat(l) == ZonaSasaran.Hasil.KOTAK_SURAT and _zona_kena(l).sisi == LoperAnim.Sisi.DEKAT


func _hasil_adalah(l: ThrowSolver.Lintasan, hasil: ZonaSasaran.Hasil) -> bool:
	return KoranLempar.hasil_mendarat(l) == hasil


## Menahan jari swipe (index 1) dari `awal` ke `akhir` (turun bila belum atau titik awal lain, lalu geser) dan menggambar jalur jari.
func _tahan(awal: Vector2, akhir: Vector2) -> void:
	var router: TouchRouter = (_akar.find_child("KontrolTouch", true, false) as KontrolTouch).router
	if router.swipe_aktif() and router.awal_swipe().distance_to(awal) > 1.0:
		_lepas_swipe_tanpa_lempar()
	if not router.swipe_aktif():
		_sentuh(1, awal, true)
	_geser(1, akhir)
	_gambar_jari(awal, akhir)


## Mengangkat jari swipe tanpa melempar: digeser kembali ke titik awal (|v| 0, D-5) lalu diangkat.
func _lepas_swipe_tanpa_lempar() -> void:
	var router: TouchRouter = (_akar.find_child("KontrolTouch", true, false) as KontrolTouch).router
	if router.swipe_aktif():
		var awal: Vector2 = router.awal_swipe()
		_geser(1, awal)
		_sentuh(1, awal, false)
	_gambar_jari(Vector2.ZERO, Vector2.ZERO)


## Jalur jari di lapisan probe: titik 2x2 px game (koordinat bulat, blok seragam) tiap `JARI_TITIK_JARAK` dari awal ke akhir, ditambah
## titik 4x4 di awal. Awal = akhir = kosong.
func _gambar_jari(awal: Vector2, akhir: Vector2) -> void:
	for anak: Node in _lapis_jari.get_children():
		anak.free()
	var panjang: float = awal.distance_to(akhir)
	if panjang <= 0.0:
		return
	var jumlah: int = floori(panjang / JARI_TITIK_JARAK)
	for i: int in range(jumlah + 1):
		var titik: ColorRect = ColorRect.new()
		titik.color = Palette.ACCENT
		titik.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ukuran: float = 4.0 if i == 0 else 2.0
		titik.size = Vector2(ukuran, ukuran)
		titik.position = awal.lerp(akhir, float(i) / float(maxi(jumlah, 1)) if i < jumlah else 1.0).round()
		_lapis_jari.add_child(titik)


## Swipe dari `awal` bersudut `sudut_min`..`sudut_maks` (derajat layar) yang lintasannya memenuhi `syarat` dari keadaan sepeda SAAT INI,
## atau `Vector2.INF`. Sudut dicoba dari tengah rentang ke luar (ke atas = sedekat mungkin 90 derajat, ke kanan = 0 derajat).
func _cari(awal: Vector2, sudut_min: float, sudut_maks: float, syarat: Callable) -> Vector2:
	var tengah: float = (sudut_min + sudut_maks) / 2.0
	var urutan: Array[float] = [tengah]
	var geser: float = CARI_SUDUT_LANGKAH
	while tengah + geser <= sudut_maks or tengah - geser >= sudut_min:
		if tengah + geser <= sudut_maks:
			urutan.append(tengah + geser)
		if tengah - geser >= sudut_min:
			urutan.append(tengah - geser)
		geser += CARI_SUDUT_LANGKAH
	for derajat: float in urutan:
		var panjang: float = ceilf(ThrowSolver.swipe_min_px(_lebar))
		while panjang <= ThrowSolver.swipe_maks_px(_lebar):
			var akhir: Vector2 = _akhir_sudut(awal, derajat, panjang)
			var lintasan: ThrowSolver.Lintasan = _akar.lintasan_swipe(awal, akhir)
			if lintasan != null and syarat.call(lintasan):
				return akhir
			panjang += CARI_PANJANG_LANGKAH
	return Vector2.INF


## Mencetak sudut jari dan sudut garis tanah lemparan di layar (`Iso.dunia_ke_layar(arah)`); keduanya harus sama (garis bidik sejajar jari).
func _cetak_sejajar(nama: String, awal: Vector2, akhir: Vector2, l: ThrowSolver.Lintasan) -> void:
	var layar: Vector2 = Iso.dunia_ke_layar(l.arah)
	var silang: float = layar.normalized().cross((akhir - awal).normalized())
	print("%s: jari %.1f derajat |v| %.1f px, garis tanah lemparan %.1f derajat (silang %.6f), sisi %s, arah tanah %s" % [nama, _sudut(akhir - awal), (akhir - awal).length(), _sudut(layar), silang, LoperAnim.Sisi.keys()[l.sisi], l.arah])
	if absf(silang) > 0.0001:
		print("PERINGATAN: %s garis bidik tidak sejajar jari" % nama)
		_gagal += 1


## Mencari swipe dari `awal` bersudut `sudut_min`..`sudut_maks` untuk `syarat` sambil sepeda maju, menahan garis bidik ke sana (foto bila
## `foto_bidik`), melempar, memotret koran di puncak lengkung (bila `foto_bidik`) dan penanda sesudah mendarat.
func _lempar_ke(awal: Vector2, sudut_min: float, sudut_maks: float, syarat: Callable, nama: String, foto_bidik: bool) -> void:
	var akhir: Vector2 = Vector2.INF
	var kena: bool = false
	var garis: GarisBidik = _akar.garis_bidik()
	# Jari ditahan di swipe yang mengenai sasaran menurut keadaan saat ini, lalu satu langkah: garis bidik dihitung ulang dari keadaan
	# baru. Jari dilepas hanya bila garis bidik yang TAMPIL (keadaan yang juga dipakai lemparan) memenuhi syarat.
	for i: int in range(roundi(CARI_DETIK / DT)):
		var coba: Vector2 = _cari(awal, sudut_min, sudut_maks, syarat)
		if coba != Vector2.INF and SisaKoran.boleh_lempar(_akar.koran):
			akhir = coba
			_tahan(awal, akhir)
		else:
			_lepas_swipe_tanpa_lempar()
		await _maju(DT, false)
		if garis.tampil() and syarat.call(garis.lintasan()):
			kena = true
			break
	if not kena:
		print("PERINGATAN: sasaran %s tidak ditemukan dalam %s detik" % [nama, CARI_DETIK])
		_lepas_swipe_tanpa_lempar()
		_gagal += 1
		return
	await _tunggu(2)
	_cetak_sejajar(nama, awal, akhir, garis.lintasan())
	print("%s: garis bidik tampil %s, elips sah %s (bentuk %s), titik akhir %s, sisa koran %d" % [nama, garis.tampil(), garis.elips_sah(), KoranLempar.Elips.keys()[garis.bentuk_elips()], garis.titik_akhir(), _akar.koran.sisa])
	if foto_bidik:
		await _foto("bidik_%s" % nama)
	await _lepas_dan_foto(akhir, nama, foto_bidik, KoranLempar.hasil_mendarat(garis.lintasan()))


## Mengangkat jari di `akhir` (melempar garis bidik yang tampil), memotret puncak (bila `foto_puncak`) dan penanda sesudah mendarat.
func _lepas_dan_foto(akhir: Vector2, nama: String, foto_puncak: bool, sasaran: ZonaSasaran.Hasil) -> void:
	var sisa_sebelum: int = _akar.koran.sisa
	_sentuh(1, akhir, false)
	_gambar_jari(Vector2.ZERO, Vector2.ZERO)
	var terbang: Array[KoranLempar.Koran] = _akar.koran_terbang()
	if _akar.koran.sisa != sisa_sebelum - 1 or terbang.is_empty():
		print("PERINGATAN: lemparan %s tidak diterima" % nama)
		_gagal += 1
		return
	var lintasan: ThrowSolver.Lintasan = terbang[terbang.size() - 1].lintasan
	if foto_puncak:
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
	var relatif: Vector2 = ZonaSasaran.ke_jalan(lintasan.titik_mendarat) - ZonaSasaran.ke_jalan(lintasan.titik_lepas)
	print("%s mendarat: hasil %s (diharapkan %s), antaran %s, penanda %s, titik %s = prediksi %s, relatif titik lepas: lateral %+.2f, maju %+.2f ubin" % [nama, ZonaSasaran.Hasil.keys()[hasil.hasil], ZonaSasaran.Hasil.keys()[sasaran], ZonaSasaran.Antaran.keys()[hasil.antaran], ZonaSasaran.Penanda.keys()[hasil.penanda], KoranLempar.posisi(hasil), lintasan.titik_mendarat, relatif.x, relatif.y])
	if hasil.hasil != sasaran:
		_gagal += 1
	await _foto("kena_%s" % nama)
	await _maju(Config.PENANDA_LAMA_DETIK)


## Swipe ke KIRI MURNI (180 derajat) setengah kekuatan: arah tanah seberang dan mundur; dengan warisan maju santai titik mendarat tetap
## sedikit di belakang titik lepas (dicetak). Foto garis bidik, puncak, dan pendaratan.
func _lempar_kiri_murni() -> void:
	var awal: Vector2 = Vector2(_lebar - Config.ZONA_SWIPE_TEPI_PX - SWIPE_AWAL_SEBERANG_DARI_KANAN, SWIPE_Y)
	var akhir: Vector2 = _akhir_sudut(awal, 180.0, (ThrowSolver.swipe_min_px(_lebar) + ThrowSolver.swipe_maks_px(_lebar)) / 2.0)
	for i: int in range(roundi(1.0 / DT)):
		if SisaKoran.boleh_lempar(_akar.koran):
			break
		await _maju(DT, false)
	_tahan(awal, akhir)
	await _maju(DT)
	var garis: GarisBidik = _akar.garis_bidik()
	if not garis.tampil():
		print("PERINGATAN: garis bidik kiri murni tidak tampil")
		_gagal += 1
		_lepas_swipe_tanpa_lempar()
		return
	var l: ThrowSolver.Lintasan = garis.lintasan()
	_cetak_sejajar("kiri_murni", awal, akhir, l)
	if l.sisi != LoperAnim.Sisi.SEBERANG or l.arah.x >= 0.0 or l.arah.y <= 0.0:
		print("PERINGATAN: kiri murni bukan seberang dan mundur (arah tanah %s)" % l.arah)
		_gagal += 1
	await _foto("bidik_kiri_murni")
	await _lepas_dan_foto(akhir, "kiri_murni", true, KoranLempar.hasil_mendarat(l))


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
