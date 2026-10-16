class_name PanelAkhirRute
extends CanvasLayer
## Banner sementara "Rute selesai" dan tombol dev "Main lagi" (AC-14 run fase3a-rute, K-5, usulan; bukan layar hasil).
##
## Tipis: hanya menampilkan dan memancarkan `main_lagi_diminta`; akhir rute diurus `RuteMain` (`AkhirRute`). Banner di tengah atas di
## bawah strip HUD dan tidak menerima sentuhan; tombol di pojok kanan atas strip HUD, di luar zona stick dan swipe (`ZONA_SWIPE_Y_MIN_PX`
## sama dengan tinggi strip) dan jauh dari tombol jeda, kidal, dan bantu, supaya tidak tersentuh tak sengaja (rule `ui-scenes`). Tombol
## memakai `TombolSentuh` (bisa diketuk jari mana pun walau jempol lain masih di layar) dan tinggi `HUD_TOMBOL_TINGGI_PX`. Teks lewat
## kunci terjemahan (`RUTE_SELESAI`, `RUTE_MAIN_LAGI`, `RUTE_GAGAL_MUAT`), warna dari `Palette`. Tersembunyi sampai rute selesai.

## Tombol "Main lagi" ditekan.
signal main_lagi_diminta

@onready var _bingkai_banner: MarginContainer = %BingkaiBanner
@onready var _banner: PanelContainer = %Banner
@onready var _judul: Label = %JudulAkhir
@onready var _bingkai_tombol: MarginContainer = %BingkaiTombol
@onready var _tombol: TombolSentuh = %TombolUlang


func _ready() -> void:
	_bingkai_banner.add_theme_constant_override(&"margin_top", Config.RUTE_BANNER_MARGIN_ATAS_PX)
	_bingkai_tombol.add_theme_constant_override(&"margin_top", Config.HUD_TOMBOL_MARGIN_ATAS_PX)
	_bingkai_tombol.add_theme_constant_override(&"margin_right", Config.RUTE_TOMBOL_ULANG_MARGIN_PX)
	_banner.add_theme_stylebox_override(&"panel", GayaHud.kotak(Palette.HUD_PANEL, Palette.TEXT))
	_judul.add_theme_color_override(&"font_color", Palette.TEXT)
	_judul.text = tr("RUTE_SELESAI")
	_tombol.text = tr("RUTE_MAIN_LAGI")
	_tombol.custom_minimum_size = Vector2(Config.HUD_TOMBOL_LEBAR_PX, Config.HUD_TOMBOL_TINGGI_PX)
	GayaHud.terapkan_tombol(_tombol)
	_tombol.ditekan.connect(main_lagi_diminta.emit)
	tampilkan(false)


## Menampilkan atau menyembunyikan banner "Rute selesai" dan tombol.
func tampilkan(nilai: bool) -> void:
	_judul.text = tr("RUTE_SELESAI")
	visible = nilai


## Menampilkan banner galat `RUTE_GAGAL_MUAT` (rute tidak bisa dimuat atau disusun) dan tombol "Main lagi" untuk mencoba seed berikutnya.
## Teks galat rinci hanya ke log developer (`push_error`); pemain tidak dibiarkan menatap jalan kosong tanpa penjelasan.
func tampilkan_galat() -> void:
	_judul.text = tr("RUTE_GAGAL_MUAT")
	visible = true


## True bila banner dan tombol sedang tampil.
func tampil() -> bool:
	return visible


## Teks banner yang tampil (untuk tes).
func teks_banner() -> String:
	return _judul.text


## Teks tombol "Main lagi" (untuk tes).
func teks_tombol() -> String:
	return _tombol.text


## Persegi banner dalam koordinat viewport game.
func rect_banner() -> Rect2:
	return _banner.get_global_rect()


## Persegi tombol "Main lagi" dalam koordinat viewport game.
func rect_tombol() -> Rect2:
	return _tombol.get_global_rect()
