class_name PanelTipSisiDekat
extends CanvasLayer
## Panel tip hari 3 (P-6, D-4, AC-12 run fase5d-sisi-dekat bagian B; usulan): satu kotak teks di kolom kiri di bawah kartu misi (sama dengan petunjuk tutorial), label "TIP" dan isi dari
## `TipSisiDekat.KUNCI_TEKS`. Tipis: `RuteMain` memutuskan kapan tampil (`TipSisiDekat`), node ini hanya menampilkan.
##
## TIDAK memblokir input: panel dan semua labelnya `MOUSE_FILTER_IGNORE`, tanpa tombol, jadi stick, swipe, dan bel tetap sampai ke `TouchRouter` (dijaga tes). Zona aman: inset dibaca dari
## `DisplayServer.get_display_safe_area()` di perangkat mobile (`ZonaAman`, sama dengan HUD) dan menggeser panel. Tidak dicerminkan saat kidal (kolom kiri atas bukan zona kontrol, seperti kartu misi).
## Teks lewat kunci terjemahan; warna dari `Palette`.

var _inset: ZonaAman.Inset = ZonaAman.Inset.new()
## Kunci teks yang sedang tampil ("" = tersembunyi; "~" = belum pernah diatur): teks hanya disusun ulang bila berubah (tanpa alokasi per frame).
var _kunci: String = "~"

@onready var _strip: MarginContainer = %StripTip
@onready var _panel: PanelContainer = %PanelTip
@onready var _label: Label = %LabelTip
@onready var _teks: Label = %TeksTip


func _ready() -> void:
	_panel.custom_minimum_size = Vector2(Config.TIP_SISI_DEKAT_LEBAR_PX, 0)
	_panel.add_theme_stylebox_override(&"panel", GayaHud.panel_hud())
	_label.add_theme_color_override(&"font_color", Palette.ACCENT)
	_teks.add_theme_color_override(&"font_color", Palette.TEXT)
	_label.text = tr("RUTE_TIP_LABEL")
	_baca_zona_aman()
	get_viewport().size_changed.connect(_baca_zona_aman)
	_terapkan_tata_letak()
	tampilkan("")


## Menampilkan tip dengan kunci teks `kunci` ("" = tersembunyi).
func tampilkan(kunci: String) -> void:
	if kunci == _kunci:
		return
	_kunci = kunci
	_strip.visible = not kunci.is_empty()
	if not kunci.is_empty():
		_teks.text = tr(kunci)


## True bila tip sedang tampil.
func tampil() -> bool:
	return _strip.visible


## Teks tip yang tampil ("" bila tersembunyi).
func teks() -> String:
	return _teks.text if tampil() else ""


## Persegi panel dalam koordinat viewport game (tes tata letak).
func rect_panel() -> Rect2:
	return _panel.get_global_rect()


## Mengatur inset aman tepi layar (piksel game, `ZonaAman.inset_game`, sama dengan HUD) lalu menata ulang. Null = nol.
func atur_inset(inset: ZonaAman.Inset) -> void:
	_inset = inset if inset != null else ZonaAman.Inset.new()
	_terapkan_tata_letak()


## Semua kontrol yang bisa menelan sentuhan GUI (bukan IGNORE) di layar ini; harus kosong (dijaga tes).
func kontrol_penerima_sentuhan() -> Array[Control]:
	var hasil: Array[Control] = []
	for node: Node in find_children("*", "Control", true, false):
		var kontrol: Control = node as Control
		if kontrol.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			hasil.append(kontrol)
	return hasil


func _baca_zona_aman() -> void:
	if not OS.has_feature("mobile"):
		return
	var aman: Rect2i = DisplayServer.get_display_safe_area()
	atur_inset(ZonaAman.inset_game(aman, DisplayServer.window_get_size(), get_viewport().get_visible_rect().size))


func _terapkan_tata_letak() -> void:
	if _strip == null:
		return
	var geser_x: int = ZonaAman.geser(Config.RADAR_TEPI_PX, _inset.awal_x)
	var geser_atas: int = ZonaAman.geser(Config.HUD_TOMBOL_MARGIN_ATAS_PX, _inset.atas)
	_strip.add_theme_constant_override(&"margin_left", Config.TIP_SISI_DEKAT_X_PX + geser_x)
	_strip.add_theme_constant_override(&"margin_top", Config.TIP_SISI_DEKAT_Y_PX + geser_atas)
