class_name TesJedaScene
extends RefCounted
## Tes terpadu jeda run fase1b-umpan-balik (AC-7, D-6; QA-007 run fase1a-gerak): tombol jeda, layar jeda, tanpa lanjut otomatis,
## back Android, `SceneTree.paused` menghentikan sprite, partikel, dan input. Event sentuh sintetis lewat `Input.parse_input_event`
## di viewport 780x360 (pola `tests/tes_gerak_scene.gd`).
##
## Dipanggil dari `tests/run_tests.gd`. Scene dijalankan dengan `set_process(false)` pada akar; gerak lewat `JalanUji.perbarui(DT)`.
## Sprite pemain dan partikel TIDAK dimatikan prosesnya di sini (yang diuji justru bahwa pause pohon menghentikannya).

const BERKAS_JALAN_UJI: String = "res://scenes/dev/jalan_uji.tscn"
const SKALA: int = 3
const DT: float = 1.0 / 60.0
const TITIK_STICK: Vector2 = Vector2(100, 260)
const SWIPE_KIRI: Vector2 = Vector2(440, 200)
const SWIPE_KANAN: Vector2 = Vector2(500, 200)
## Frame proses yang ditunggu saat memeriksa sprite dan partikel berhenti (atau berjalan sebagai kontrol).
const FRAME_AMATI: int = 6

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
	_test_proyek_back()
	await _test_tombol_dan_layar()
	for pemicu: String in ["TOMBOL_EMIT", "TOMBOL_SENTUH", "FOCUS_OUT", "PAUSED", "BACK"]:
		await _test_jeda_lengkap(pemicu)
	await _test_back_dua_kali_dan_urutan()
	await _test_ketuk_jari_kedua()


# --- Pembantu ---

func _siapkan(jendela: Vector2i = Vector2i(2340, 1080)) -> JalanUji:
	_tree.root.size = jendela
	var paket: PackedScene = load(BERKAS_JALAN_UJI) as PackedScene
	var akar: JalanUji = paket.instantiate() as JalanUji
	_tree.root.add_child(akar)
	await _tree.process_frame
	await _tree.process_frame
	akar.set_process(false)
	(_anak(akar, "KontrolTouch") as KontrolTouch).keyboard_aktif = false
	return akar


func _bersihkan(akar: JalanUji) -> void:
	(_anak(akar, "KontrolTouch") as KontrolTouch).keyboard_aktif = OS.has_feature("editor")
	_tree.root.remove_child(akar)
	akar.free()
	check(not _tree.paused, "scene dibuang saat jeda: pause pohon dilepas (_exit_tree)")


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


## Ketukan satu jari (turun lalu naik di titik yang sama).
func _ketuk(posisi_viewport: Vector2) -> void:
	_sentuh(0, posisi_viewport, true)
	_sentuh(0, posisi_viewport, false)


func _langkah(akar: JalanUji, jumlah: int) -> void:
	for i: int in range(jumlah):
		akar.perbarui(DT)


func _tunggu(jumlah: int) -> void:
	for i: int in range(jumlah):
		await _tree.process_frame


## Kirim notifikasi seperti dari platform: FOCUS dan GO_BACK lewat root (jendela), PAUSED/RESUMED lewat SceneTree.
func _kirim(nama: String) -> void:
	match nama:
		"FOCUS_OUT":
			_tree.root.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		"FOCUS_IN":
			_tree.root.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
		"PAUSED":
			_tree.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
		"RESUMED":
			_tree.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
		"BACK":
			_tree.root.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)


## Ringkasan keadaan simulasi untuk dibandingkan sebelum dan sesudah jeda.
func _potret(akar: JalanUji, sepeda: SepedaUji) -> Array:
	return [sepeda.kecepatan_ud, sepeda.jarak_ubin, sepeda.lateral_ubin, sepeda.stamina(), sepeda.keadaan.tahan_rem_detik, akar.geser_dorongan()]


# --- Pengaturan proyek ---

func _test_proyek_back() -> void:
	_judul.call("Jeda: tombol back tidak menutup app (AC-7)")
	check(ProjectSettings.get_setting("application/config/quit_on_go_back", true) == false, "application/config/quit_on_go_back = false di project.godot (back membuka layar jeda, bukan keluar)")
	check(_tree.quit_on_go_back == false, "SceneTree.quit_on_go_back mengikuti pengaturan proyek (false)")


# --- Tombol jeda dan layar jeda: letak, gambar, teks ---

func _test_tombol_dan_layar() -> void:
	_judul.call("Tombol jeda dan layar jeda: area sentuh, gambar, teks (AC-7, D-6, DESIGN_SPEC 3.1)")
	var akar: JalanUji = await _siapkan()
	var hud: HudDev = _anak(akar, "Hud") as HudDev
	var tombol: TombolJeda = _anak(hud, "TombolJeda") as TombolJeda
	var layar: LayarJeda = _anak(akar, "LayarJeda") as LayarJeda
	check(tombol != null and layar != null, "HUD memuat TombolJeda dan scene memuat LayarJeda")
	if tombol == null or layar == null:
		_bersihkan(akar)
		return
	var rect: Rect2 = hud.rect_tombol_jeda()
	check(rect.size.x >= float(Config.HUD_JEDA_SENTUH_PX) and rect.size.y >= float(Config.HUD_JEDA_SENTUH_PX) and Config.HUD_JEDA_SENTUH_PX >= 42, "area sentuh tombol jeda >= 42x42 px game (44 dp di A54), dapat %s" % rect.size)
	var gambar: Rect2 = tombol.rect_gambar()
	check(gambar == Rect2(26, 8, 24, 24), "gambar tombol jeda 24x24 di x 26, y 8 (DESIGN_SPEC 3.1), dapat %s" % gambar)
	check(rect.encloses(gambar), "gambar di dalam area sentuh (%s di %s)" % [gambar, rect])
	check(tombol.text.is_empty() and tombol.icon == null, "tombol jeda tanpa teks dan tanpa PNG (digambar dari kode)")
	check(not layar.tampil() and layar.process_mode == Node.PROCESS_MODE_WHEN_PAUSED and layar.layer > hud.layer, "layar jeda tersembunyi di awal, process_mode WHEN_PAUSED, di atas HUD")
	var judul: Label = _anak(layar, "JudulJeda") as Label
	var lanjut: Button = _anak(layar, "TombolLanjut") as Button
	check(judul.text == "JEDA_JUDUL" and lanjut.text == "JEDA_LANJUT" and tr("JEDA_JUDUL") == "JEDA" and tr("JEDA_LANJUT") == "Lanjut", "teks layar jeda lewat kunci terjemahan (JEDA, Lanjut)")
	var latar: ColorRect = _anak(layar, "Latar") as ColorRect
	check(latar.color == Palette.HUD_PANEL and judul.get_theme_color(&"font_color") == Palette.TEXT, "lapisan gelap HUD_PANEL, judul TEXT (warna dari Palette)")
	akar.minta_jeda()
	await _tunggu(2)
	var r_lanjut: Rect2 = layar.rect_tombol_lanjut()
	var ukuran: Vector2 = akar.get_viewport_rect().size
	check(r_lanjut.size.y >= float(Config.HUD_TOMBOL_TINGGI_PX) and Config.HUD_TOMBOL_TINGGI_PX >= 42 and r_lanjut.size.x >= float(Config.JEDA_TOMBOL_LEBAR_PX), "tombol Lanjut tinggi >= 42 px game, dapat %s" % r_lanjut.size)
	check(Rect2(Vector2.ZERO, ukuran).encloses(r_lanjut) and latar.get_global_rect().size == ukuran, "lapisan jeda menutup seluruh layar (%s) dan tombol Lanjut di dalamnya" % latar.get_global_rect().size)
	akar.minta_lanjut()
	_bersihkan(akar)


# --- Jeda lengkap per pemicu ---

func _test_jeda_lengkap(pemicu: String) -> void:
	_judul.call("Jeda lewat %s: layar jeda, semua berhenti, tanpa lanjut otomatis (AC-7, QA-007)" % pemicu)
	var akar: JalanUji = await _siapkan()
	var sepeda: SepedaUji = _anak(akar, "Sepeda") as SepedaUji
	var kontrol: KontrolTouch = _anak(akar, "KontrolTouch") as KontrolTouch
	var router: TouchRouter = kontrol.router
	var hud: HudDev = _anak(akar, "Hud") as HudDev
	var layar: LayarJeda = _anak(akar, "LayarJeda") as LayarJeda
	var sprite: LoperSprite = _anak(akar, "LoperAgen") as LoperSprite
	var catatan: Array[bool] = []
	akar.jeda_berubah.connect(func(nilai: bool) -> void: catatan.append(nilai))
	# Ngebut dengan stick, lalu lempar yang sedang berjalan.
	_sentuh(1, TITIK_STICK, true)
	_geser(1, TITIK_STICK - Vector2(0, Config.STICK_RADIUS_PX))
	_langkah(akar, 120)
	_sentuh(2, SWIPE_KIRI, true)
	_geser(2, SWIPE_KANAN)
	_sentuh(2, SWIPE_KANAN, false)
	sprite.set_process(false)
	check(sepeda.sedang_melempar() and router.stick_aktif() and sepeda.kecepatan_ud == 6.0, "%s: sebelum jeda ngebut, melempar, stick aktif" % pemicu)
	sepeda.batalkan_lempar()
	sprite.set_process(true)
	# Kontrol: tanpa jeda sprite berputar dengan sendirinya (pemutar bawaan AnimatedSprite2D).
	var progres_awal: float = sprite.frame + sprite.frame_progress
	await _tunggu(FRAME_AMATI)
	check(not is_equal_approx(sprite.frame + sprite.frame_progress, progres_awal), "%s: kontrol: tanpa jeda frame sprite maju (%s -> %s)" % [pemicu, progres_awal, sprite.frame + sprite.frame_progress])
	sepeda.lempar(LoperAnim.Sisi.DEKAT)
	sprite.set_process(false)
	var potret: Array = _potret(akar, sepeda)
	# Jeda.
	match pemicu:
		"TOMBOL_EMIT":
			(_anak(hud, "TombolJeda") as TombolJeda).pressed.emit()
		"TOMBOL_SENTUH":
			_ketuk(hud.rect_tombol_jeda().get_center())
		_:
			_kirim(pemicu)
	check(akar.sedang_jeda() and layar.tampil() and _tree.paused, "%s: layar jeda terbuka dan SceneTree.paused menyala" % pemicu)
	check(catatan == [true], "%s: sinyal jeda_berubah(true) sekali (titik kait Audio), dapat %s" % [pemicu, catatan])
	check(router.jumlah_jari_aktif() == 0 and router.vektor_stick() == Vector2.ZERO and not sepeda.sedang_melempar(), "%s: stick dan swipe dilepas, lempar ditutup" % pemicu)
	check(sepeda.keadaan.tahan_rem_detik == 0.0 and not sepeda.rem_aktif(), "%s: lama tahan rem 0" % pemicu)
	potret[4] = 0.0
	# Tidak ada lanjut otomatis.
	for nama: String in ["FOCUS_IN", "RESUMED", "FOCUS_OUT", "PAUSED", "FOCUS_IN"]:
		_kirim(nama)
	check(akar.sedang_jeda() and layar.tampil() and _tree.paused and catatan == [true], "%s: FOCUS_IN/RESUMED (dan jeda ulang) tidak menutup layar jeda" % pemicu)
	# Simulasi berhenti walau perbarui/_process dipanggil dengan dt besar.
	for dt: float in [DT, 0.1, 5.0, 100.0]:
		akar.perbarui(dt)
		akar._process(dt)
	check(_potret(akar, sepeda) == potret, "%s: perbarui dan _process dengan dt besar tidak mengubah kecepatan, jarak, lateral, stamina, lama tahan rem, dorongan" % pemicu)
	# Sprite berhenti (QA-007): frame dan progres tidak maju walau frame proses berjalan.
	sprite.set_process(true)
	var frame_jeda: int = sprite.frame
	var progres_jeda: float = sprite.frame_progress
	await _tunggu(FRAME_AMATI)
	check(sprite.frame == frame_jeda and sprite.frame_progress == progres_jeda and not sprite.can_process(), "%s: frame AnimatedSprite2D pemain tidak maju selama jeda (QA-007)" % pemicu)
	# Sentuhan di zona stick dan swipe tidak memunculkan apa pun.
	_sentuh(3, TITIK_STICK, true)
	_geser(3, TITIK_STICK - Vector2(0, Config.STICK_RADIUS_PX))
	_sentuh(4, SWIPE_KIRI, true)
	_geser(4, SWIPE_KANAN)
	_sentuh(4, SWIPE_KANAN, false)
	check(router.jumlah_jari_aktif() == 0 and not router.stick_aktif() and router.jumlah_swipe_selesai == 1 and not sepeda.sedang_melempar(), "%s: sentuhan di zona stick dan swipe selama jeda tidak memunculkan stick atau lempar" % pemicu)
	_sentuh(3, TITIK_STICK, false)
	# Lanjut.
	match pemicu:
		"TOMBOL_SENTUH":
			_ketuk(layar.rect_tombol_lanjut().get_center())
		"BACK":
			_kirim("BACK")
		_:
			(_anak(layar, "TombolLanjut") as Button).pressed.emit()
	check(not akar.sedang_jeda() and not layar.tampil() and not _tree.paused and catatan == [true, false], "%s: Lanjut menutup layar jeda, pause pohon lepas, jeda_berubah(false), dapat %s" % [pemicu, catatan])
	sprite.set_process(false)
	akar.perbarui(0.1)
	check(_potret(akar, sepeda) == potret, "%s: langkah pertama sesudah lanjut ber-dt 0 (tidak ada lompatan 0,1 detik)" % pemicu)
	akar.perbarui(DT)
	check(sepeda.kecepatan_ud < potret[0] and sepeda.jarak_ubin > potret[1] and sepeda.jarak_ubin - float(potret[1]) < float(potret[0]) * DT + 0.000001, "%s: langkah berikutnya normal; stick harus disentuh ulang (kecepatan turun ke santai)" % pemicu)
	check(not router.stick_aktif(), "%s: sesudah lanjut stick tidak aktif sampai disentuh ulang" % pemicu)
	# Rem harus ditahan ulang 0,25 detik penuh sesudah lanjut.
	_sentuh(5, TITIK_STICK, true)
	_geser(5, TITIK_STICK + Vector2(0, Config.STICK_RADIUS_PX))
	_langkah(akar, 14)
	check(not sepeda.rem_aktif(), "%s: sesudah lanjut, bawah penuh 14 langkah (0,233 detik): belum rem" % pemicu)
	_langkah(akar, 1)
	check(sepeda.rem_aktif(), "%s: 0,25 detik ditahan ulang: rem aktif" % pemicu)
	_sentuh(5, TITIK_STICK, false)
	# Sprite berputar lagi sesudah lanjut.
	sprite.set_process(true)
	var progres_lanjut: float = sprite.frame + sprite.frame_progress
	await _tunggu(FRAME_AMATI)
	check(not is_equal_approx(sprite.frame + sprite.frame_progress, progres_lanjut), "%s: sesudah lanjut sprite berputar lagi" % pemicu)
	_bersihkan(akar)


# --- Back dua kali dan tombol jeda saat sudah jeda ---

func _test_back_dua_kali_dan_urutan() -> void:
	_judul.call("Jeda: back membalik, tombol jeda saat jeda tidak menutup (AC-7)")
	var akar: JalanUji = await _siapkan()
	var layar: LayarJeda = _anak(akar, "LayarJeda") as LayarJeda
	_kirim("BACK")
	check(akar.sedang_jeda() and layar.tampil(), "back saat berjalan: jeda")
	akar.minta_jeda()
	check(akar.sedang_jeda() and layar.tampil(), "tombol jeda saat sudah jeda: tetap jeda")
	_kirim("BACK")
	check(not akar.sedang_jeda() and not layar.tampil() and not _tree.paused, "back saat jeda: lanjut")
	_kirim("BACK")
	_kirim("FOCUS_OUT")
	_kirim("BACK")
	check(not akar.sedang_jeda(), "back, FOCUS_OUT, back: lanjut (FOCUS_OUT saat jeda tidak membalik)")
	akar.minta_lanjut()
	check(not akar.sedang_jeda(), "Lanjut saat berjalan tidak berpengaruh")
	# Dibuang saat jeda: pause pohon dilepas oleh `_bersihkan` (diperiksa di sana).
	akar.minta_jeda()
	_bersihkan(akar)


# --- Ketukan jari kedua saat jempol lain di stick (temuan Dev run ini: GUI hanya mengikuti jari pertama) ---

func _test_ketuk_jari_kedua() -> void:
	_judul.call("Jeda: tombol jeda dan Lanjut bisa diketuk jari kedua saat jempol di stick (AC-7, TombolSentuh)")
	await _tree.process_frame
	var akar: JalanUji = await _siapkan()
	var hud: HudDev = _anak(akar, "Hud") as HudDev
	var layar: LayarJeda = _anak(akar, "LayarJeda") as LayarJeda
	var router: TouchRouter = (_anak(akar, "KontrolTouch") as KontrolTouch).router
	var tombol: Vector2 = hud.rect_tombol_jeda().get_center()
	var hasil: Array[bool] = []
	# Urutan seperti di HP: ketuk jeda dengan satu jari (jari pertama), ketuk Lanjut, lalu jempol di stick dan jari kedua mengetuk jeda,
	# lalu Lanjut diketuk jari kedua sementara jempol masih menempel (stick sudah dilepas oleh jeda).
	_sentuh(0, tombol, true)
	await _tree.process_frame
	_sentuh(0, tombol, false)
	await _tree.process_frame
	hasil.append(akar.sedang_jeda())
	_sentuh(0, layar.rect_tombol_lanjut().get_center(), true)
	await _tree.process_frame
	_sentuh(0, layar.rect_tombol_lanjut().get_center(), false)
	await _tree.process_frame
	hasil.append(akar.sedang_jeda())
	for putaran: int in range(2):
		_sentuh(0, TITIK_STICK, true)
		await _tree.process_frame
		check(router.stick_aktif(), "putaran %d: jempol di zona stick menjadi stick" % putaran)
		_sentuh(1, tombol, true)
		await _tree.process_frame
		_sentuh(1, tombol, false)
		await _tree.process_frame
		hasil.append(akar.sedang_jeda())
		_sentuh(1, layar.rect_tombol_lanjut().get_center(), true)
		await _tree.process_frame
		_sentuh(1, layar.rect_tombol_lanjut().get_center(), false)
		await _tree.process_frame
		hasil.append(akar.sedang_jeda())
		_sentuh(0, TITIK_STICK, false)
		await _tree.process_frame
	check(hasil == [true, false, true, false, true, false], "ketukan jari pertama dan jari kedua (jempol di stick) membuka dan menutup layar jeda, dapat %s" % [hasil])
	# Jari yang turun di luar tombol lalu bergeser masuk dan naik di dalamnya tidak memicu; turun di dalam lalu naik di luar juga tidak.
	_sentuh(2, tombol + Vector2(0, 60), true)
	_sentuh(2, tombol, false)
	_sentuh(3, tombol, true)
	_geser(3, tombol + Vector2(0, 60))
	_sentuh(3, tombol + Vector2(0, 60), false)
	await _tree.process_frame
	check(not akar.sedang_jeda(), "jari yang hanya naik atau hanya turun di dalam tombol jeda tidak menjeda")
	_bersihkan(akar)
