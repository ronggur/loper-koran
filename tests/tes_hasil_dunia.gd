class_name TesHasilDunia
extends RefCounted
## Tes layar hasil di atas lingkungan yang baru dilalui (run ui2-semua-layar bagian E, V-10, AC-2): lapisan gelap `UI_BG` tembus pandang, struk dan kartu samping transparan sebagian, lapisan dunia yang tidak boleh tembus
## (HUD, tutorial, tip, umpan melayang, lapisan kontrol sentuh) tersembunyi selama layar hasil tampil dan pulih sesudah "Main lagi", layar hasil sendiri tanpa dunia jatuh ke latar gelap polos dan panel buram tanpa galat,
## dan tanpa pemrosesan per frame. Bagian murni: alpha dan faktor gelap dari `Config` (nilai literal), serta kontras TEORETIS terburuk (dunia putih penuh di belakang) untuk semua warna teks di atas lapisan, struk, dan kartu
## dari piksel tekstur nyata dan pencampuran sRGB seperti Godot. Kontras terburuk yang TERUKUR dari tangkapan nyata ada di LOG bagian E (`tools/ukur_kontras_tangkapan.py --jenis hasil`). Tidak menyentuh `user://save.json`.

const BERKAS_RUTE: String = "res://scenes/rute/rute.tscn"
const BERKAS_HASIL: String = "res://scenes/ui/layar_hasil.tscn"
const DT: float = 1.0 / 60.0
const PANJANG_RUTE: float = 236.0

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
	_test_nilai_dan_warna()
	_test_kontras_teoretis_terburuk()
	await _test_layar_sendiri_tanpa_dunia()
	await _test_di_atas_dunia()
	await _test_pulih_sesudah_main_lagi()


# --- Pembantu ---

## Luminans relatif WCAG dari warna sRGB (RGB 0..1).
func _lum(c: Color) -> float:
	var l: Color = c.srgb_to_linear()
	return 0.2126 * l.r + 0.7152 * l.g + 0.0722 * l.b


func _kontras(a: Color, b: Color) -> float:
	var la: float = _lum(a)
	var lb: float = _lum(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


## Pencampuran alpha di ruang sRGB seperti `CanvasItem` Godot: `atas` (dengan alpha) di atas `bawah` buram.
func _campur(atas: Color, bawah: Color) -> Color:
	return Color(bawah.r * (1.0 - atas.a) + atas.r * atas.a, bawah.g * (1.0 - atas.a) + atas.g * atas.a, bawah.b * (1.0 - atas.a) + atas.b * atas.a, 1.0)


func _pusat(tekstur: Texture2D) -> Color:
	var gambar: Image = tekstur.get_image()
	return gambar.get_pixel(gambar.get_width() / 2, gambar.get_height() / 2)


func _siapkan() -> RuteMain:
	_tree.root.size = Vector2i(2340, 1080)
	var akar: RuteMain = (load(BERKAS_RUTE) as PackedScene).instantiate() as RuteMain
	# Hari 3: tip sisi dekat tampil di awal rute, jadi penyembunyiannya di balik layar hasil ikut teruji.
	akar.atur_hari(3)
	_tree.root.add_child(akar)
	await _tree.process_frame
	await _tree.process_frame
	akar.set_process(false)
	(akar.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = false
	(akar.find_child("LoperAgen", true, false) as LoperSprite).set_process(false)
	return akar


func _bersihkan(akar: RuteMain) -> void:
	(akar.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = OS.has_feature("editor")
	_tree.root.remove_child(akar)
	akar.free()


func _sampai_hasil(akar: RuteMain) -> bool:
	var sepeda: SepedaUji = akar.find_child("Sepeda", true, false) as SepedaUji
	var k: BikeMotion.Keadaan = sepeda.keadaan.salin()
	k.kecepatan_ud = Config.KECEPATAN_SANTAI_UD
	k.lateral_ubin = 0.0
	sepeda.keadaan = k
	sepeda.jarak_ubin = PANJANG_RUTE - 0.01
	for i: int in range(600):
		if akar.hasil_tampil():
			return true
		akar.perbarui(DT)
	return akar.hasil_tampil()


func _lapisan_kontrol(akar: RuteMain) -> CanvasLayer:
	return akar.find_child("KontrolTouch", true, false).get_parent() as CanvasLayer


func _umpan(akar: RuteMain) -> CanvasItem:
	return akar.find_child("UmpanMelayang", true, false) as CanvasItem


func _tutorial(akar: RuteMain) -> CanvasLayer:
	return akar.find_child("Tutorial", true, false) as CanvasLayer


# --- Murni ---

func _test_nilai_dan_warna() -> void:
	_judul.call("Hasil V-10 (murni): alpha lapisan, struk, dan kartu dari Config (nilai literal), warna dari token, tanpa dunia = gelap polos buram")
	check(Config.HASIL_LATAR_ALPHA == 0.75 and Config.HASIL_PANEL_ALPHA == 0.72 and Config.HASIL_PANEL_GELAP == 0.5, "Config: lapisan 0,75, panel 0,72, gelap 0,5")
	check(Config.HASIL_ALPHA_TANPA_DUNIA == 1.0 and Config.HASIL_PANEL_GELAP_TANPA_DUNIA == 1.0, "Config: tanpa dunia buram (1,0) dan tanpa penggelapan (1,0)")
	check(Config.HASIL_LATAR_ALPHA <= 0.85 and Config.HASIL_LATAR_ALPHA > 0.5, "lapisan gelap antara 0,5 dan 0,85: dunia masih terlihat (batas atas SPEC bagian E)")
	var latar: Color = TampilHasil.warna_latar(true)
	check(latar.r == Palette.UI_BG.r and latar.g == Palette.UI_BG.g and latar.b == Palette.UI_BG.b and is_equal_approx(latar.a, Config.HASIL_LATAR_ALPHA), "di atas dunia: lapisan UI_BG dengan alpha Config.HASIL_LATAR_ALPHA")
	var polos: Color = TampilHasil.warna_latar(false)
	check(polos.r == Palette.UI_BG.r and polos.g == Palette.UI_BG.g and polos.b == Palette.UI_BG.b and polos.a == 1.0, "tanpa dunia: UI_BG buram penuh (gelap polos)")
	check(TampilHasil.alpha_panel(true) == Config.HASIL_PANEL_ALPHA and TampilHasil.alpha_panel(false) == 1.0, "alpha panel: Config di atas dunia, 1,0 tanpa dunia")
	check(TampilHasil.gelap_panel(true) == Config.HASIL_PANEL_GELAP and TampilHasil.gelap_panel(false) == 1.0, "faktor gelap panel: Config di atas dunia, 1,0 tanpa dunia")
	var m: Color = TampilHasil.modulasi_panel(true)
	check(m == Color(0.5, 0.5, 0.5, 0.72), "modulasi panel di atas dunia: abu-abu 0,5 alpha 0,72")
	check(TampilHasil.modulasi_panel(false) == Color(1, 1, 1, 1), "modulasi panel tanpa dunia: putih buram = tekstur apa adanya")
	check(Palette.UI_BG == Color("#1C130F"), "token UI_BG tidak diubah")


func _test_kontras_teoretis_terburuk() -> void:
	_judul.call("Hasil V-10 (murni): kontras teoretis terburuk >= 7:1 untuk semua warna teks bila dunia di belakang PUTIH PENUH (lebih terang dari rumput, jalan, atau dinding rumah mana pun)")
	var dunia: Color = Color(1, 1, 1, 1)
	var lapisan: Color = _campur(TampilHasil.warna_latar(true), dunia)
	check(_kontras(Palette.TEXT, lapisan) >= 7.0, "judul TEXT di atas lapisan di atas dunia putih: %.2f:1 (>= 7)" % _kontras(Palette.TEXT, lapisan))
	var modul: Color = TampilHasil.modulasi_panel(true)
	var struk_px: Color = _pusat(GayaHud.tekstur("struk"))
	var kartu_px: Color = _pusat(GayaHud.kartu_biasa().texture)
	for kasus: Array in [["struk", struk_px], ["kartu", kartu_px]]:
		var px: Color = kasus[1]
		var dimodulasi: Color = Color(px.r * modul.r, px.g * modul.g, px.b * modul.b, px.a * modul.a)
		var panel: Color = _campur(dimodulasi, lapisan)
		for teks: Array in [["TEXT", Palette.TEXT], ["TEXT_2", Palette.TEXT_2], ["OK", Palette.OK], ["ACCENT", Palette.ACCENT]]:
			var k: float = _kontras(teks[1], panel)
			check(k >= 7.0, "%s: teks %s di atas panel di atas dunia putih: %.2f:1 (>= 7)" % [kasus[0], teks[0], k])
		check(px.a == 1.0, "%s: piksel tengah tekstur buram (1,0): transparansi hanya dari alpha Config" % kasus[0])


# --- Scene ---

func _test_layar_sendiri_tanpa_dunia() -> void:
	_judul.call("Hasil V-10: layar hasil sendiri tanpa rute (tes, probe, dev): latar gelap polos buram, panel buram, tanpa galat, tanpa pemrosesan per frame")
	_tree.root.size = Vector2i(2340, 1080)
	var layar: LayarHasil = (load(BERKAS_HASIL) as PackedScene).instantiate() as LayarHasil
	_tree.root.add_child(layar)
	await _tree.process_frame
	var a: HasilRute.Angka = HasilRute.Angka.new()
	a.pelanggan = 25
	a.terkirim = 20
	a.meleset = 5
	a.koin = 300
	layar.isi(a)
	layar.tampilkan(true)
	await _tree.process_frame
	check(not layar.ada_dunia(), "layar hasil sendiri: ada_dunia() false")
	check(layar.warna_latar() == TampilHasil.warna_latar(false) and layar.warna_latar().a == 1.0, "latar gelap polos buram (UI_BG alpha 1,0)")
	check(layar.alpha_panel() == 1.0, "panel buram (alpha 1,0)")
	check(layar.get_node("LatarHasil").mouse_filter == Control.MOUSE_FILTER_STOP, "latar tetap menangkap sentuhan (tidak tembus ke bawah)")
	check(not layar.is_processing() and not layar.is_physics_processing(), "tanpa pemrosesan per frame")
	layar.atur_dunia(true)
	check(layar.ada_dunia() and is_equal_approx(layar.warna_latar().a, Config.HASIL_LATAR_ALPHA) and is_equal_approx(layar.alpha_panel(), Config.HASIL_PANEL_ALPHA), "atur_dunia(true): lapisan dan panel tembus pandang")
	layar.atur_dunia(false)
	check(not layar.ada_dunia() and layar.warna_latar().a == 1.0 and layar.alpha_panel() == 1.0, "atur_dunia(false) mengembalikan latar polos dan panel buram")
	_tree.root.remove_child(layar)
	layar.free()


func _test_di_atas_dunia() -> void:
	_judul.call("Hasil V-10 (scene rute): layar hasil di atas dunia: lapisan tembus pandang, panel transparan, HUD dan lapisan dunia yang tidak boleh tembus tersembunyi, tombol tetap menerima sentuhan")
	var akar: RuteMain = await _siapkan()
	var layar: LayarHasil = akar.layar_hasil()
	check(layar.ada_dunia(), "layar hasil di dalam RuteMain: ada_dunia() true")
	check(akar.hud_rute().visible and _lapisan_kontrol(akar).visible and _umpan(akar).visible and _tutorial(akar).visible and not layar.tampil(), "sebelum hasil: HUD, lapisan kontrol, umpan melayang, tutorial tampil; layar hasil tertutup")
	akar.perbarui(0.0)
	check(akar.tip_node().tampil(), "sebelum hasil (hari 3): tip sisi dekat tampil")
	check(_sampai_hasil(akar), "layar hasil terbuka sesudah garis akhir")
	await _tree.process_frame
	await _tree.process_frame
	check(layar.tampil() and is_equal_approx(layar.warna_latar().a, Config.HASIL_LATAR_ALPHA) and is_equal_approx(layar.alpha_panel(), Config.HASIL_PANEL_ALPHA), "hasil terbuka: lapisan alpha Config.HASIL_LATAR_ALPHA, panel alpha Config.HASIL_PANEL_ALPHA")
	check(not akar.hud_rute().visible, "HUD (progres, radar, panel bawah, kolom kanan atas, bel, jeda, kartu misi, banner, penanda kucing) tersembunyi: tidak tembus di balik layar hasil")
	check(not _lapisan_kontrol(akar).visible, "lapisan kontrol sentuh (stick, tanda tanpa sasaran) tersembunyi")
	check(not _umpan(akar).visible, "umpan melayang (+15, TEPAT) tersembunyi")
	check(not _tutorial(akar).visible, "tutorial tersembunyi")
	check(not akar.tip_node().tampil(), "tip sisi dekat tersembunyi")
	check(not (akar.find_child("PanelAkhir", true, false) as PanelAkhirRute).tampil(), "banner akhir rute tersembunyi")
	check(not (akar.find_child("KontrolTouch", true, false) as KontrolTouch).is_processing_input(), "kontrol sentuh tidak membaca sentuhan")
	check(layar.get_node("LatarHasil").mouse_filter == Control.MOUSE_FILTER_STOP and layar.layer > 10, "latar menangkap sentuhan dan layar hasil di atas semua lapisan dunia (layer %d)" % layar.layer)
	# Tombol tetap menerima sentuhan: ditekan memancarkan sinyalnya.
	var diminta: Array[int] = [0]
	akar.bengkel_diminta.connect(func() -> void: diminta[0] += 1)
	akar.atur_mode_hari(true)
	layar.tombol_main_lagi().ditekan.emit()
	check(diminta[0] == 1, "tombol layar hasil tetap menerima sentuhan di atas dunia (sinyal 'Ke bengkel')")
	check(not layar.is_processing() and not layar.is_physics_processing(), "layar hasil tanpa pemrosesan per frame")
	# Struk dan ketiga kartu kolom samping memakai pengali yang sama (tidak ada panel yang tertinggal buram).
	var modul: Color = TampilHasil.modulasi_panel(true)
	for nama: String in ["PanelStruk", "KartuReputasi", "KartuPelanggan", "KartuTarget"]:
		var kotak: StyleBoxTexture = layar.find_child(nama, true, false).get_theme_stylebox(&"panel") as StyleBoxTexture
		check(kotak != null and kotak.modulate_color == modul, "%s: modulate_color = abu-abu %.1f alpha %.2f" % [nama, modul.r, modul.a])
	_bersihkan(akar)


func _test_pulih_sesudah_main_lagi() -> void:
	_judul.call("Hasil V-10 (scene rute): Main lagi memulihkan HUD, lapisan kontrol, umpan melayang, tutorial; layar hasil tertutup; hasil kedua berperilaku sama")
	var akar: RuteMain = await _siapkan()
	var layar: LayarHasil = akar.layar_hasil()
	check(_sampai_hasil(akar), "hasil pertama terbuka")
	akar.main_lagi()
	await _tree.process_frame
	await _tree.process_frame
	check(not layar.tampil() and not akar.hasil_tampil(), "Main lagi: layar hasil tertutup")
	check(akar.hud_rute().visible, "Main lagi: HUD pulih")
	check(_lapisan_kontrol(akar).visible, "Main lagi: lapisan kontrol sentuh pulih")
	check(_umpan(akar).visible, "Main lagi: umpan melayang pulih")
	check(_tutorial(akar).visible, "Main lagi: tutorial pulih")
	check((akar.find_child("KontrolTouch", true, false) as KontrolTouch).is_processing_input(), "Main lagi: kontrol sentuh membaca sentuhan lagi")
	check(layar.ada_dunia(), "Main lagi: layar hasil tetap tahu ada dunia")
	check(_sampai_hasil(akar), "hasil kedua terbuka")
	await _tree.process_frame
	check(not akar.hud_rute().visible and not _lapisan_kontrol(akar).visible and not _umpan(akar).visible and is_equal_approx(layar.warna_latar().a, Config.HASIL_LATAR_ALPHA), "hasil kedua: lapisan dunia tersembunyi lagi dan lapisan tembus pandang")
	_bersihkan(akar)
