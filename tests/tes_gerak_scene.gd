class_name TesGerakScene
extends RefCounted
## Tes terpadu run fase1a-gerak yang butuh scene tree (AC-8 jeda, AC-9 HUD dan cincin rem, AC-10 kabel scene): event sentuh
## sintetis lewat `Input.parse_input_event` di viewport 780x360 (pola run 0B, `tests/tes_input_scene.gd`).
##
## Dipanggil dari `tests/run_tests.gd` (`await TesGerakScene.new(check, judul, self).jalankan()`). Scene dijalankan dengan
## `set_process(false)`; gerak lewat `JalanUji.perbarui(DT)` dengan `dt` tetap, waktu lempar lewat `LoperSprite.maju(DT)`.

const BERKAS_JALAN_UJI: String = "res://scenes/dev/jalan_uji.tscn"
const SKALA: int = 3
const DT: float = 1.0 / 60.0
## Titik sentuh stick (tangan kanan) dan swipe di viewport 780x360.
const TITIK_STICK: Vector2 = Vector2(100, 260)
const SWIPE_KIRI: Vector2 = Vector2(440, 200)
const SWIPE_KANAN: Vector2 = Vector2(500, 200)

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
	await _test_hud_stamina_dan_bar()
	await _test_rem_di_scene()
	await _test_meluncur_lalu_melambat()
	await _test_dua_jari_rem_dan_meluncur()
	await _test_stamina_di_scene()
	await _test_kidal_rem()
	await _test_jeda()
	await _test_jeda_di_tengah_tahan_rem()


# --- Pembantu (sama dengan `tests/tes_input_scene.gd`) ---

func _siapkan(jendela: Vector2i = Vector2i(2340, 1080)) -> JalanUji:
	_tree.root.size = jendela
	var paket: PackedScene = load(BERKAS_JALAN_UJI) as PackedScene
	var akar: JalanUji = paket.instantiate() as JalanUji
	_tree.root.add_child(akar)
	await _tree.process_frame
	await _tree.process_frame
	akar.set_process(false)
	(_anak(akar, "KontrolTouch") as KontrolTouch).keyboard_aktif = false
	_sprite(akar)
	return akar


func _bersihkan(akar: JalanUji) -> void:
	(_anak(akar, "KontrolTouch") as KontrolTouch).keyboard_aktif = OS.has_feature("editor")
	_tree.root.remove_child(akar)
	akar.free()


func _anak(akar: Node, nama: String) -> Node:
	return akar.find_child(nama, true, false)


func _sprite(akar: JalanUji) -> LoperSprite:
	var sprite: LoperSprite = _anak(akar, "LoperAgen") as LoperSprite
	sprite.set_process(false)
	return sprite


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
	for i: int in range(jumlah):
		akar.perbarui(DT)


## Swipe sintetis: turun, geser, angkat. `_process` sprite dimatikan sesudahnya (lempar menyalakannya).
func _swipe(akar: JalanUji, index: int, dari: Vector2, ke: Vector2) -> void:
	_sentuh(index, dari, true)
	_geser(index, ke)
	_sentuh(index, ke, false)
	_sprite(akar)


func _selesaikan_lempar(sprite: LoperSprite) -> void:
	for i: int in range(60):
		if not sprite.sedang_melempar():
			return
		sprite.maju(DT)


# --- AC-9: HUD stamina dan bar kecepatan ---

func _test_hud_stamina_dan_bar() -> void:
	_judul.call("HUD: bar stamina di bawah bar kecepatan (AC-9)")
	var akar: JalanUji = await _siapkan()
	var hud: HudDev = _anak(akar, "Hud") as HudDev
	var bar_kecepatan: BarKecepatan = _anak(hud, "BarKecepatan") as BarKecepatan
	var bar_stamina: BarKecepatan = _anak(hud, "BarStamina") as BarKecepatan
	var label_stamina: Label = _anak(hud, "LabelStamina") as Label
	var label_lelah: Label = _anak(hud, "LabelLelah") as Label
	var panel: PanelContainer = _anak(hud, "PanelKecepatan") as PanelContainer
	check(bar_stamina != null and label_stamina != null and label_lelah != null, "HUD memuat LabelStamina, LabelLelah, dan BarStamina")
	if bar_stamina == null or label_stamina == null or label_lelah == null:
		_bersihkan(akar)
		return
	var r_kec: Rect2 = bar_kecepatan.get_global_rect()
	var r_sta: Rect2 = bar_stamina.get_global_rect()
	check(r_sta.position.y >= r_kec.end.y and is_equal_approx(r_sta.size.x, r_kec.size.x) and r_sta.size.y == float(Config.HUD_BAR_TINGGI_PX), "bar stamina di bawah bar kecepatan, selebar, tinggi 7 px (kecepatan %s, stamina %s)" % [r_kec, r_sta])
	check(panel.get_global_rect().encloses(r_sta) and panel.get_global_rect().end.y <= 360.0 - float(Config.HUD_MARGIN_TEPI_PX) + 0.5, "bar stamina di dalam panel bawah, panel tetap 8 px dari tepi bawah (%s)" % panel.get_global_rect())
	check(label_stamina.text == "HUD_STAMINA" and tr(label_stamina.text) == "STAMINA" and label_lelah.text == "HUD_LELAH" and tr(label_lelah.text) == "LELAH", "label stamina dan lelah memakai kunci terjemahan (STAMINA, LELAH)")
	check(label_stamina.get_theme_color(&"font_color") == Palette.ACCENT, "label STAMINA berwarna ACCENT")
	_langkah(akar, 1)
	check(hud.nilai_stamina() == 1.0 and hud.warna_stamina() == Palette.ACCENT and not hud.penanda_lelah_tampil(), "stamina penuh: bar penuh, ACCENT, tanpa penanda lelah")
	hud.tampilkan_stamina(30.0, false)
	check(hud.warna_stamina() == Palette.ACCENT and is_equal_approx(hud.nilai_stamina(), 0.3), "stamina tepat 30: masih ACCENT (FAIL hanya di bawah 30)")
	hud.tampilkan_stamina(29.9, false)
	check(hud.warna_stamina() == Palette.FAIL, "stamina 29,9: FAIL")
	hud.tampilkan_stamina(0.0, true)
	check(hud.warna_stamina() == Palette.FAIL and hud.nilai_stamina() == 0.0 and hud.penanda_lelah_tampil() and label_lelah.is_visible_in_tree(), "lelah: penanda teks LELAH tampil (bukan hanya warna), bar kosong")
	hud.tampilkan_stamina(10.0, false)
	check(not hud.penanda_lelah_tampil(), "tidak lelah: penanda hilang")
	hud.tampilkan_kecepatan(0.0)
	check(hud.nilai_kecepatan() == 0.0 and (_anak(hud, "LabelAngka") as Label).text == tr("HUD_KECEPATAN_ANGKA").format({"v": "0.0"}), "bar kecepatan menerima 0 u/d: kosong, angka 0.0")
	_bersihkan(akar)


# --- AC-10: rem di scene ---

func _test_rem_di_scene() -> void:
	_judul.call("Rem di scene: stick bawah penuh ditahan (AC-10, AC-9 cincin)")
	var akar: JalanUji = await _siapkan()
	var sepeda: SepedaUji = _anak(akar, "Sepeda") as SepedaUji
	var kontrol: KontrolTouch = _anak(akar, "KontrolTouch") as KontrolTouch
	var hud: HudDev = _anak(akar, "Hud") as HudDev
	_langkah(akar, 30)
	_sentuh(0, TITIK_STICK, true)
	_geser(0, TITIK_STICK + Vector2(0, Config.STICK_RADIUS_PX))
	check(kontrol.vektor_stick().is_equal_approx(Vector2(0, -1)), "jari ke bawah sejauh jangkauan penuh = (0, -1)")
	_langkah(akar, 14)
	check(not sepeda.rem_aktif() and not kontrol.busur_rem_tampil() and sepeda.nama_animasi() == &"meluncur_normal", "0,233 detik ditahan: belum rem, cincin biasa, meluncur_normal, dapat %s" % sepeda.nama_animasi())
	_langkah(akar, 1)
	check(sepeda.rem_aktif() and kontrol.busur_rem_tampil() and sepeda.nama_animasi() == &"rem_normal", "0,25 detik ditahan: rem aktif, busur bawah cincin WARN tampil, rem_normal, dapat %s" % sepeda.nama_animasi())
	_langkah(akar, 60)
	var jarak_henti: float = sepeda.jarak_ubin
	_langkah(akar, 30)
	check(sepeda.kecepatan_ud == 0.0 and sepeda.jarak_ubin == jarak_henti and sepeda.nama_animasi() == &"rem_normal" and kontrol.busur_rem_tampil(), "rem ditahan: sepeda berhenti (0 u/d, jarak tetap), rem_normal, busur tetap tampil")
	check(hud.nilai_kecepatan() == 0.0, "HUD menampilkan kecepatan 0")
	_sentuh(0, TITIK_STICK + Vector2(0, Config.STICK_RADIUS_PX), false)
	_langkah(akar, 1)
	check(not sepeda.rem_aktif() and not kontrol.busur_rem_tampil(), "jari diangkat: rem padam dan busur hilang")
	_langkah(akar, 60)
	check(sepeda.kecepatan_ud == 3.0 and sepeda.jarak_ubin > jarak_henti and sepeda.nama_animasi() == &"santai_normal", "1 detik sesudah lepas: jalan lagi santai 3,0 u/d, santai_normal")
	# Stick bawah sebentar (0,2 detik) lalu dilepas: meluncur, tidak pernah rem.
	_sentuh(0, TITIK_STICK, true)
	_geser(0, TITIK_STICK + Vector2(0, Config.STICK_RADIUS_PX))
	_langkah(akar, 12)
	check(not sepeda.rem_aktif() and sepeda.nama_animasi() == &"meluncur_normal", "bawah penuh 0,2 detik: meluncur_normal, tidak rem")
	_sentuh(0, TITIK_STICK + Vector2(0, Config.STICK_RADIUS_PX), false)
	_langkah(akar, 30)
	check(not sepeda.rem_aktif() and sepeda.nama_animasi() == &"santai_normal", "dilepas sebelum 0,25 detik: tidak pernah rem, kembali santai")
	_bersihkan(akar)


func _test_meluncur_lalu_melambat() -> void:
	_judul.call("Meluncur lalu melambat di scene (AC-10, D-7)")
	var akar: JalanUji = await _siapkan()
	var sepeda: SepedaUji = _anak(akar, "Sepeda") as SepedaUji
	var sprite: LoperSprite = _sprite(akar)
	_sentuh(0, TITIK_STICK, true)
	_geser(0, TITIK_STICK - Vector2(0, Config.STICK_RADIUS_PX))
	_langkah(akar, 120)
	check(sepeda.kecepatan_ud == 6.0 and sepeda.nama_animasi() == &"ngebut_normal" and is_equal_approx(sprite.speed_scale, 1.0), "ngebut mantap: ngebut_normal, laju kayuh 1")
	_geser(0, TITIK_STICK + Vector2(0, Config.STICK_RADIUS_PX * 0.85))
	_langkah(akar, 3)
	check(sepeda.nama_animasi() == &"meluncur_normal" and is_equal_approx(sprite.speed_scale, 1.0), "stick bawah 85%% dari ngebut: meluncur_normal (kaki diam, laju 1), dapat %s" % sepeda.nama_animasi())
	var urutan: Array[StringName] = [sepeda.nama_animasi()]
	for i: int in range(240):
		akar.perbarui(DT)
		if urutan[-1] != sepeda.nama_animasi():
			urutan.append(sepeda.nama_animasi())
	check(urutan == [&"meluncur_normal", &"melambat_normal"], "meluncur sampai tujuan lalu melambat_normal, sekali ganti, dapat %s" % [urutan])
	check(not sepeda.rem_aktif(), "stick bawah 85% tidak pernah rem")
	# Laju kayuh mengikuti kecepatan saat mempercepat dari kecepatan rendah (D-8).
	_geser(0, TITIK_STICK - Vector2(0, Config.STICK_RADIUS_PX))
	_langkah(akar, 1)
	var rendah: float = sprite.speed_scale
	_langkah(akar, 30)
	check(sepeda.nama_animasi() == &"ngebut_normal" and rendah < sprite.speed_scale and sprite.speed_scale < 1.0 and is_equal_approx(sprite.speed_scale, sepeda.kecepatan_ud / Config.KECEPATAN_NGEBUT_UD), "mempercepat ke ngebut: laju kayuh = kecepatan / 6,0 dan naik (%s -> %s)" % [rendah, sprite.speed_scale])
	_sentuh(0, TITIK_STICK, false)
	_bersihkan(akar)


func _test_dua_jari_rem_dan_meluncur() -> void:
	_judul.call("Dua jari: swipe tetap melempar selama rem dan meluncur (AC-10)")
	var akar: JalanUji = await _siapkan()
	var sepeda: SepedaUji = _anak(akar, "Sepeda") as SepedaUji
	var kontrol: KontrolTouch = _anak(akar, "KontrolTouch") as KontrolTouch
	var router: TouchRouter = kontrol.router
	_sentuh(0, TITIK_STICK, true)
	_geser(0, TITIK_STICK + Vector2(0, Config.STICK_RADIUS_PX))
	_langkah(akar, 20)
	check(sepeda.rem_aktif() and sepeda.nama_animasi() == &"rem_normal", "rem aktif sebelum swipe")
	_swipe(akar, 1, SWIPE_KIRI, SWIPE_KANAN)
	var sprite: LoperSprite = _sprite(akar)
	check(sepeda.sedang_melempar() and sepeda.nama_animasi() == &"lempar_kanan_santai_normal", "swipe ke kanan saat rem: lempar_kanan_santai_normal (dari rem memakai santai), dapat %s" % sepeda.nama_animasi())
	_langkah(akar, 10)
	check(router.stick_aktif() and sepeda.rem_aktif() and kontrol.busur_rem_tampil(), "selama melempar stick tetap aktif dan rem tetap aktif")
	_selesaikan_lempar(sprite)
	check(not sepeda.sedang_melempar() and sepeda.nama_animasi() == &"rem_normal", "lempar selesai: kembali ke rem_normal")
	_sentuh(0, TITIK_STICK + Vector2(0, Config.STICK_RADIUS_PX), false)
	_langkah(akar, 120)
	# Meluncur: dari ngebut, stick bawah 85%, swipe ke kiri.
	_sentuh(0, TITIK_STICK, true)
	_geser(0, TITIK_STICK - Vector2(0, Config.STICK_RADIUS_PX))
	_langkah(akar, 120)
	_geser(0, TITIK_STICK + Vector2(0, Config.STICK_RADIUS_PX * 0.85))
	_langkah(akar, 3)
	check(sepeda.nama_animasi() == &"meluncur_normal", "meluncur sebelum swipe")
	_swipe(akar, 2, SWIPE_KANAN, SWIPE_KIRI)
	sprite = _sprite(akar)
	check(sepeda.sedang_melempar() and sepeda.nama_animasi() == &"lempar_kiri_santai_normal", "swipe ke kiri saat meluncur: lempar_kiri_santai_normal, dapat %s" % sepeda.nama_animasi())
	_langkah(akar, 5)
	_selesaikan_lempar(sprite)
	check(router.stick_aktif() and sepeda.nama_animasi() == &"meluncur_normal", "lempar selesai saat masih meluncur: kembali ke meluncur_normal, stick tetap aktif, dapat %s" % sepeda.nama_animasi())
	_sentuh(0, TITIK_STICK, false)
	_bersihkan(akar)


func _test_stamina_di_scene() -> void:
	_judul.call("Stamina di scene: ngebut terus, FAIL di bawah 30, lelah (AC-10, AC-9)")
	var akar: JalanUji = await _siapkan()
	var sepeda: SepedaUji = _anak(akar, "Sepeda") as SepedaUji
	var hud: HudDev = _anak(akar, "Hud") as HudDev
	_sentuh(0, TITIK_STICK, true)
	_geser(0, TITIK_STICK - Vector2(0, Config.STICK_RADIUS_PX))
	_langkah(akar, 120)
	check(hud.nilai_stamina() < 1.0 and is_equal_approx(hud.nilai_stamina(), sepeda.stamina() / 100.0) and hud.warna_stamina() == Palette.ACCENT, "ngebut 2 detik: bar stamina turun (%s) dan masih ACCENT" % hud.nilai_stamina())
	var langkah: int = 0
	while sepeda.stamina() >= 30.0 and langkah < 1200:
		akar.perbarui(DT)
		langkah += 1
	check(hud.warna_stamina() == Palette.FAIL and not hud.penanda_lelah_tampil() and not sepeda.lelah(), "stamina di bawah 30 (%s): bar FAIL, belum lelah" % sepeda.stamina())
	while not sepeda.lelah() and langkah < 1200:
		akar.perbarui(DT)
		langkah += 1
	check(sepeda.lelah() and hud.penanda_lelah_tampil() and sepeda.stamina() == 0.0, "stamina habis: lelah, penanda LELAH tampil")
	_langkah(akar, 60)
	check(sepeda.kecepatan_ud == Config.KECEPATAN_CEPAT_UD and sepeda.nama_animasi() == &"cepat_normal", "lelah: kecepatan dijepit 4,5 dan sprite cepat_normal walau stick atas penuh, dapat %s %s" % [sepeda.kecepatan_ud, sepeda.nama_animasi()])
	_geser(0, TITIK_STICK + Vector2(0, Config.STICK_RADIUS_PX * 0.85))
	_langkah(akar, 100)
	check(sepeda.lelah() and sepeda.stamina() > 20.0, "meluncur 1,67 detik: stamina naik (%s), masih lelah" % sepeda.stamina())
	_langkah(akar, 30)
	check(not sepeda.lelah() and not hud.penanda_lelah_tampil() and hud.warna_stamina() == Palette.ACCENT, "meluncur sekitar 2 detik: stamina >= 30 (%s), lelah padam, bar kembali ACCENT" % sepeda.stamina())
	_sentuh(0, TITIK_STICK, false)
	_bersihkan(akar)


func _test_kidal_rem() -> void:
	_judul.call("Kidal: rem dari stick di kanan, panel HUD pindah sisi (AC-10, AC-9)")
	var akar: JalanUji = await _siapkan()
	var sepeda: SepedaUji = _anak(akar, "Sepeda") as SepedaUji
	var kontrol: KontrolTouch = _anak(akar, "KontrolTouch") as KontrolTouch
	var hud: HudDev = _anak(akar, "Hud") as HudDev
	var panel_kanan: Rect2 = hud.rect_panel_kecepatan()
	var tombol: Button = _anak(hud, "TombolKidal") as Button
	tombol.button_pressed = true
	await _tree.process_frame
	var panel_kidal: Rect2 = hud.rect_panel_kecepatan()
	var bar_stamina: Control = _anak(hud, "BarStamina") as Control
	check(kontrol.router.kidal() and panel_kidal.position.x > panel_kanan.position.x and panel_kidal.encloses(bar_stamina.get_global_rect()), "kidal: panel kecepatan dan stamina pindah ke sisi kanan bersama (%s -> %s)" % [panel_kanan.position, panel_kidal.position])
	var titik: Vector2 = Vector2(780.0 - TITIK_STICK.x, TITIK_STICK.y)
	_sentuh(0, titik, true)
	_geser(0, titik + Vector2(0, Config.STICK_RADIUS_PX))
	_langkah(akar, 15)
	check(sepeda.rem_aktif() and kontrol.busur_rem_tampil() and sepeda.nama_animasi() == &"rem_normal", "kidal: stick di kanan bawah penuh 0,25 detik = rem, busur tampil")
	_geser(0, titik + Vector2(-Config.STICK_RADIUS_PX, 0))
	_langkah(akar, 3)
	check(not sepeda.rem_aktif() and sepeda.lateral_ubin < 0.0, "kidal: geser ke kiri layar tetap ke sisi seberang (lateral negatif, arti sumbu tidak berubah) dan memutus rem")
	_sentuh(0, titik, false)
	tombol.button_pressed = false
	await _tree.process_frame
	_bersihkan(akar)


# --- AC-8: jeda ---

func _test_jeda() -> void:
	_judul.call("Jeda: PAUSED dan FOCUS_OUT menghentikan simulasi, lanjut tanpa lompatan (AC-8, D-6)")
	for urutan: Array in [["FOCUS_OUT", "FOCUS_IN"], ["PAUSED", "RESUMED"]]:
		var akar: JalanUji = await _siapkan()
		var sepeda: SepedaUji = _anak(akar, "Sepeda") as SepedaUji
		var kontrol: KontrolTouch = _anak(akar, "KontrolTouch") as KontrolTouch
		var router: TouchRouter = kontrol.router
		var tag: String = "%s/%s" % urutan
		_sentuh(0, TITIK_STICK, true)
		_geser(0, TITIK_STICK - Vector2(0, Config.STICK_RADIUS_PX))
		_langkah(akar, 120)
		_swipe(akar, 1, SWIPE_KIRI, SWIPE_KANAN)
		var sprite: LoperSprite = _sprite(akar)
		check(sepeda.sedang_melempar() and router.stick_aktif() and sepeda.kecepatan_ud == 6.0, "%s: sebelum jeda ngebut, melempar, stick aktif" % tag)
		var v: float = sepeda.kecepatan_ud
		var jarak: float = sepeda.jarak_ubin
		var stamina: float = sepeda.stamina()
		var dorongan: Vector2 = akar.geser_dorongan()
		_kirim(urutan[0])
		check(akar.sedang_jeda() and router.jumlah_jari_aktif() == 0 and router.vektor_stick() == Vector2.ZERO, "%s: jeda, stick dan swipe dilepas" % tag)
		check(not sepeda.sedang_melempar() and sprite.animation != &"lempar_kanan_ngebut_normal", "%s: lempar ditutup" % tag)
		for dt: float in [DT, 0.1, 5.0, 100.0]:
			akar.perbarui(dt)
			akar._process(dt)
		check(sepeda.kecepatan_ud == v and sepeda.jarak_ubin == jarak and sepeda.stamina() == stamina and akar.geser_dorongan() == dorongan and sepeda.keadaan.tahan_rem_detik == 0.0, "%s: perbarui dan _process dengan dt besar tidak mengubah kecepatan, jarak, stamina, lama tahan rem, dorongan" % tag)
		_kirim(urutan[1])
		check(not akar.sedang_jeda(), "%s: lanjut otomatis" % tag)
		akar.perbarui(0.1)
		check(sepeda.kecepatan_ud == v and sepeda.jarak_ubin == jarak and sepeda.stamina() == stamina and akar.geser_dorongan() == dorongan, "%s: langkah pertama sesudah lanjut ber-dt 0 (tidak ada lompatan, juga tidak 0,1 detik)" % tag)
		akar.perbarui(DT)
		check(sepeda.kecepatan_ud < v and sepeda.jarak_ubin > jarak and sepeda.jarak_ubin - jarak < v * DT + 0.000001, "%s: langkah berikutnya normal (stick sudah lepas: kecepatan turun, maju satu langkah %s ubin)" % [tag, sepeda.jarak_ubin - jarak])
		_bersihkan(akar)


## Kirim notifikasi aplikasi seperti dari platform (FOCUS lewat root, PAUSED/RESUMED lewat SceneTree).
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


func _test_jeda_di_tengah_tahan_rem() -> void:
	_judul.call("Jeda di tengah tahan rem: sesudah lanjut rem tidak langsung aktif (AC-8)")
	var akar: JalanUji = await _siapkan()
	var sepeda: SepedaUji = _anak(akar, "Sepeda") as SepedaUji
	var kontrol: KontrolTouch = _anak(akar, "KontrolTouch") as KontrolTouch
	_sentuh(0, TITIK_STICK, true)
	_geser(0, TITIK_STICK + Vector2(0, Config.STICK_RADIUS_PX))
	_langkah(akar, 12)
	check(not sepeda.rem_aktif() and sepeda.keadaan.tahan_rem_detik > 0.19, "ditahan 0,2 detik: belum rem")
	_kirim("FOCUS_OUT")
	check(sepeda.keadaan.tahan_rem_detik == 0.0 and not sepeda.rem_aktif() and not kontrol.busur_rem_tampil(), "jeda: lama tahan rem kembali 0")
	_kirim("PAUSED")
	_kirim("RESUMED")
	_kirim("FOCUS_IN")
	_sentuh(1, TITIK_STICK, true)
	_geser(1, TITIK_STICK + Vector2(0, Config.STICK_RADIUS_PX))
	_langkah(akar, 1 + 6)
	check(not sepeda.rem_aktif(), "sesudah lanjut, jari baru ditahan 0,1 detik: rem belum aktif (hitungan mulai dari 0, bukan 0,3)")
	_langkah(akar, 9)
	check(sepeda.rem_aktif(), "ditahan 0,25 detik penuh sesudah lanjut: rem aktif")
	# Jeda saat rem sudah aktif: rem padam, busur hilang, dan sesudah lanjut tidak ada rem tersisa.
	_kirim("FOCUS_OUT")
	check(not sepeda.rem_aktif() and not kontrol.busur_rem_tampil(), "jeda saat rem aktif: rem padam, busur hilang")
	_kirim("FOCUS_IN")
	_langkah(akar, 2)
	check(not sepeda.rem_aktif(), "sesudah lanjut tanpa jari: tidak ada rem yang tersisa")
	_bersihkan(akar)
