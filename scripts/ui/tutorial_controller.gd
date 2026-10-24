class_name TutorialController
extends CanvasLayer
## Node tutorial terpandu hari 1 (M-9, AC-18 run fase4b-misi-kucing, usulan; TECH_PLAN Fase 4): menampilkan petunjuk dari `TutorialLangkah` (logika murni) dan
## tombol Lewati. Tipis: keputusan langkah ada di `TutorialLangkah`, node ini hanya menampilkan dan memancarkan `lewati_diminta`. Tampilan run ui2-semua-layar bagian C1 (kanvas Tutorial.dc.html,
## usulan): panel HUD 9-slice lebar `TUTORIAL_PANEL_LEBAR_PX`, label langkah `ACCENT` dengan titik langkah (`TampilTutorial`), glif aksen dan kalimat 10 px; Lewati peran tenang.
##
## TIDAK memblokir input: panel dan semua labelnya `MOUSE_FILTER_IGNORE`; satu-satunya yang menerima sentuhan adalah tombol Lewati (`TombolSentuh`, >= 42 px game,
## membaca sentuhan sendiri di `_input` tanpa menandai event tertangani), jadi stick, swipe, dan bel tetap sampai ke `TouchRouter` (dijaga tes). Tombol
## Lewati ada di strip atas HUD (y < `ZONA_SWIPE_Y_MIN_PX`, di luar zona stick dan swipe): ketukannya tidak pernah menjadi lemparan mode bantu. Petunjuk teks di kolom
## kiri di bawah kartu misi. Zona aman: ikut inset HUD (`atur_inset`). Teks lewat kunci `TUTORIAL_*`; warna dari `Palette`.

## Tombol Lewati ditekan.
signal lewati_diminta

var _inset: ZonaAman.Inset = ZonaAman.Inset.new()

@onready var _strip_lewati: MarginContainer = %StripLewati
@onready var _tombol: TombolSentuh = %TombolLewatiTutorial
@onready var _strip_teks: MarginContainer = %StripTeksTutorial
@onready var _panel: PanelContainer = %PanelTutorial
@onready var _isi: VBoxContainer = %IsiTutorial
@onready var _baris_kalimat: HBoxContainer = %BarisKalimat
@onready var _label_langkah: Label = %LabelLangkahTutorial
@onready var _titik: TitikLangkah = %TitikLangkah
@onready var _ikon: TextureRect = %IkonKalimat
@onready var _teks: Label = %TeksTutorial


func _ready() -> void:
	_tombol.custom_minimum_size = Vector2(Config.TUTORIAL_LEWATI_LEBAR_PX, Config.HUD_TOMBOL_TINGGI_PX)
	GayaHud.tombol_tenang(_tombol)
	_panel.custom_minimum_size = Vector2(Config.TUTORIAL_PANEL_LEBAR_PX, 0)
	_panel.add_theme_stylebox_override(&"panel", GayaHud.panel_hud())
	_isi.add_theme_constant_override(&"separation", Config.TUTORIAL_BARIS_JARAK_PX)
	_baris_kalimat.add_theme_constant_override(&"separation", Config.TUTORIAL_BARIS_JARAK_PX)
	(%BarisLangkah as HBoxContainer).add_theme_constant_override(&"separation", Config.TUTORIAL_LABEL_JARAK_PX)
	_label_langkah.add_theme_color_override(&"font_color", Palette.ACCENT)
	_teks.add_theme_color_override(&"font_color", Palette.TEXT)
	_tombol.ditekan.connect(lewati_diminta.emit)
	_terapkan_tata_letak()
	tampilkan_langkah(null)


## Menampilkan petunjuk langkah sekarang dari `k` (null atau tidak tampil = tersembunyi, termasuk tombol Lewati).
func tampilkan_langkah(k: TutorialLangkah.Keadaan) -> void:
	var tampil_sekarang: bool = k != null and TutorialLangkah.tampil(k)
	_strip_lewati.visible = tampil_sekarang
	_strip_teks.visible = tampil_sekarang
	if not tampil_sekarang:
		return
	var nomor: Vector2i = TutorialLangkah.nomor(k)
	_label_langkah.text = tr("TUTORIAL_LANGKAH").format({"n": nomor.x, "total": nomor.y})
	_titik.atur(nomor.x, nomor.y)
	_ikon.texture = GayaHud.tekstur(TampilTutorial.nama_glif(k.langkah))
	_teks.text = tr(TutorialLangkah.kunci_teks(k))


## Mengatur inset aman tepi layar (piksel game, `ZonaAman.inset_game`, sama dengan HUD) lalu menata ulang. Null = nol.
func atur_inset(inset: ZonaAman.Inset) -> void:
	_inset = inset if inset != null else ZonaAman.Inset.new()
	_terapkan_tata_letak()


## True bila petunjuk sedang tampil.
func tampil() -> bool:
	return _strip_teks.visible


## Teks petunjuk dan label langkah yang tampil ("" bila tersembunyi).
func teks() -> String:
	return _teks.text if tampil() else ""


func teks_langkah() -> String:
	return _label_langkah.text if tampil() else ""


## Tombol Lewati (untuk tes: `ditekan.emit()`).
func tombol_lewati() -> TombolSentuh:
	return _tombol


## Persegi tombol Lewati dan panel petunjuk dalam koordinat viewport game (tes tata letak).
func rect_lewati() -> Rect2:
	return _tombol.get_global_rect()


func rect_panel() -> Rect2:
	return _panel.get_global_rect()


## Semua kontrol yang bisa menelan sentuhan GUI (bukan IGNORE) di layar ini; hanya tombol Lewati yang boleh ada (dijaga tes).
func kontrol_penerima_sentuhan() -> Array[Control]:
	var hasil: Array[Control] = []
	for node: Node in find_children("*", "Control", true, false):
		var kontrol: Control = node as Control
		if kontrol.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			hasil.append(kontrol)
	return hasil


func _terapkan_tata_letak() -> void:
	if _strip_lewati == null:
		return
	var geser_x: int = ZonaAman.geser(Config.RADAR_TEPI_PX, _inset.awal_x)
	var geser_atas: int = ZonaAman.geser(Config.HUD_TOMBOL_MARGIN_ATAS_PX, _inset.atas)
	_strip_lewati.add_theme_constant_override(&"margin_left", Config.TUTORIAL_LEWATI_X_PX + geser_x)
	_strip_lewati.add_theme_constant_override(&"margin_top", Config.HUD_TOMBOL_MARGIN_ATAS_PX + geser_atas)
	_strip_teks.add_theme_constant_override(&"margin_left", Config.TUTORIAL_PANEL_X_PX + geser_x)
	_strip_teks.add_theme_constant_override(&"margin_top", Config.TUTORIAL_PANEL_Y_PX + geser_atas)
