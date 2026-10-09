class_name HudDev
extends CanvasLayer
## HUD sementara Fase 0 (AC-15): panel kecepatan di bawah dan tombol kidal di strip atas.
##
## `CanvasLayer` terpisah dari dunia. Tata letak memakai anchor dan Container (bukan posisi piksel absolut):
## panel kecepatan menempel di bawah dengan margin dari tepi layar sisi stick (DESIGN_SPEC 3.5) dan pindah
## sisi saat kidal; tombol kidal ada di strip atas (tinggi `Config.HUD_STRIP_ATAS_TINGGI_PX`), di luar kedua
## zona kontrol (DESIGN_SPEC 3.7), jadi sentuhannya tidak pernah menjadi stick atau swipe. Teks hanya kunci
## terjemahan (`translations/ui.csv`); warna dari `Palette` lewat skrip, font dari `assets/ui/theme.tres`.
## Tidak ada panel stamina atau koran di run ini.

## Tombol kidal diubah: True = zona ditukar untuk tangan kiri.
signal kidal_diubah(nilai: bool)

var _angka_terakhir: String = ""

@onready var _strip_atas: MarginContainer = %StripAtas
@onready var _panel_bawah: MarginContainer = %PanelBawah
@onready var _panel_kecepatan: PanelContainer = %PanelKecepatan
@onready var _label_angka: Label = %LabelAngka
@onready var _label_judul: Label = %LabelKecepatan
@onready var _bar: BarKecepatan = %BarKecepatan
@onready var _tombol_kidal: Button = %TombolKidal


func _ready() -> void:
	_strip_atas.add_theme_constant_override(&"margin_top", Config.HUD_TOMBOL_MARGIN_ATAS_PX)
	_tombol_kidal.custom_minimum_size = Vector2(Config.HUD_TOMBOL_LEBAR_PX, Config.HUD_TOMBOL_TINGGI_PX)
	_panel_kecepatan.custom_minimum_size = Vector2(Config.HUD_PANEL_KECEPATAN_LEBAR_PX, 0)
	_terapkan_gaya()
	_tombol_kidal.toggled.connect(_saat_tombol_kidal)
	atur_kidal(false)
	tampilkan_kecepatan(Config.KECEPATAN_SANTAI_UD)


## Menampilkan kecepatan (u/d) di bar dan angka. Angka hanya diperbarui bila teksnya berubah.
func tampilkan_kecepatan(kecepatan_ud: float) -> void:
	_bar.nilai = kecepatan_ud / Config.KECEPATAN_NGEBUT_UD
	var angka: String = "%.1f" % kecepatan_ud
	if angka != _angka_terakhir:
		_angka_terakhir = angka
		_label_angka.text = tr("HUD_KECEPATAN_ANGKA").format({"v": angka})


## Memindahkan panel kecepatan ke sisi tangan yang dipakai dan menyamakan tombol (tanpa memancarkan sinyal).
func atur_kidal(nilai: bool) -> void:
	_tombol_kidal.set_pressed_no_signal(nilai)
	var geser: int = Config.HUD_PANEL_KECEPATAN_GESER_PX
	var tepi: int = Config.HUD_MARGIN_TEPI_PX
	_panel_bawah.add_theme_constant_override(&"margin_left", tepi if nilai else geser)
	_panel_bawah.add_theme_constant_override(&"margin_right", geser if nilai else tepi)
	_panel_bawah.add_theme_constant_override(&"margin_bottom", tepi)
	_panel_kecepatan.size_flags_horizontal = Control.SIZE_SHRINK_END if nilai else Control.SIZE_SHRINK_BEGIN


## Persegi tombol kidal dalam koordinat viewport game (untuk memeriksa tidak masuk zona kontrol).
func rect_tombol_kidal() -> Rect2:
	return _tombol_kidal.get_global_rect()


## Persegi panel kecepatan dalam koordinat viewport game.
func rect_panel_kecepatan() -> Rect2:
	return _panel_kecepatan.get_global_rect()


func _saat_tombol_kidal(nilai: bool) -> void:
	atur_kidal(nilai)
	kidal_diubah.emit(nilai)


## Warna dan bentuk panel dan tombol dari `Palette` (DESIGN_SPEC 1.3): garis luar 1 px, sudut tegas.
func _terapkan_gaya() -> void:
	_panel_kecepatan.add_theme_stylebox_override(&"panel", _kotak(Palette.HUD_PANEL, Palette.OUTLINE))
	_label_judul.add_theme_color_override(&"font_color", Palette.ACCENT)
	_label_angka.add_theme_color_override(&"font_color", Palette.TEXT)
	_tombol_kidal.add_theme_stylebox_override(&"normal", _kotak(Palette.HUD_PANEL, Palette.OUTLINE))
	_tombol_kidal.add_theme_stylebox_override(&"hover", _kotak(Palette.HUD_PANEL, Palette.OUTLINE))
	_tombol_kidal.add_theme_stylebox_override(&"pressed", _kotak(Palette.UI_PANEL_RAISED, Palette.ACCENT))
	_tombol_kidal.add_theme_stylebox_override(&"hover_pressed", _kotak(Palette.UI_PANEL_RAISED, Palette.ACCENT))
	_tombol_kidal.add_theme_color_override(&"font_color", Palette.TEXT)
	_tombol_kidal.add_theme_color_override(&"font_hover_color", Palette.TEXT)
	_tombol_kidal.add_theme_color_override(&"font_pressed_color", Palette.ACCENT)
	_tombol_kidal.add_theme_color_override(&"font_hover_pressed_color", Palette.ACCENT)


func _kotak(isi: Color, garis: Color) -> StyleBoxFlat:
	var kotak: StyleBoxFlat = StyleBoxFlat.new()
	kotak.bg_color = isi
	kotak.border_color = garis
	kotak.set_border_width_all(1)
	kotak.anti_aliasing = false
	kotak.content_margin_left = float(Config.HUD_PANEL_PAD_X_PX)
	kotak.content_margin_right = float(Config.HUD_PANEL_PAD_X_PX)
	kotak.content_margin_top = float(Config.HUD_PANEL_PAD_Y_PX)
	kotak.content_margin_bottom = float(Config.HUD_PANEL_PAD_Y_PX)
	return kotak
