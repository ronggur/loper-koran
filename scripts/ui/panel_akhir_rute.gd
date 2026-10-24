class_name PanelAkhirRute
extends CanvasLayer
## Banner "Rute selesai" sesaat sebelum layar hasil (AC-14 run fase3a-rute, K-5; O-11 run fase3c-hud-hasil, usulan) dan banner galat muat.
##
## Tipis: hanya menampilkan dan memancarkan `main_lagi_diminta`; akhir rute diurus `RuteMain` (`AkhirRute`). Banner di tengah atas di
## bawah panel progres HUD (`RUTE_BANNER_MARGIN_ATAS_PX`) dan tidak menerima sentuhan. Sejak run fase3c-hud-hasil tombol "Main lagi"
## rute yang selesai ada di layar hasil (O-11), bukan di sini; tombol di banner ini hanya tampil bersama banner galat (`RUTE_GAGAL_MUAT`:
## rute tidak bisa dimuat atau disusun) supaya pemain bisa mencoba seed berikutnya, bukan menatap jalan kosong. Tombol memakai
## `TombolSentuh` (bisa diketuk jari mana pun walau jempol lain masih di layar) dan tinggi `HUD_TOMBOL_TINGGI_PX`. Teks lewat kunci
## terjemahan (`RUTE_SELESAI`, `RUTE_MAIN_LAGI`, `RUTE_GAGAL_MUAT`), warna dari `Palette`. Tersembunyi sampai rute selesai.
## Tampilan run ui2-semua-layar bagian C1 (kanvas Banner.dc.html, usulan): panel HUD 9-slice, glif status di depan judul (centang `OK` untuk rute selesai, tanda seru `WARN` untuk galat muat: status
## terbaca dari bentuk, bukan warna), tombol "Main lagi" peran utama.

## Tombol "Main lagi" (banner galat) ditekan.
signal main_lagi_diminta

@onready var _bingkai_banner: MarginContainer = %BingkaiBanner
@onready var _banner: PanelContainer = %Banner
@onready var _baris_judul: HBoxContainer = %BarisJudul
@onready var _ikon: TextureRect = %IkonBanner
@onready var _judul: Label = %JudulAkhir
@onready var _tombol: TombolSentuh = %TombolUlang


func _ready() -> void:
	_bingkai_banner.add_theme_constant_override(&"margin_top", Config.RUTE_BANNER_MARGIN_ATAS_PX)
	_banner.add_theme_stylebox_override(&"panel", GayaHud.panel_hud(Config.RUTE_BANNER_PAD_X_PX))
	_baris_judul.add_theme_constant_override(&"separation", Config.RUTE_BANNER_JARAK_PX)
	_judul.add_theme_color_override(&"font_color", Palette.TEXT)
	_judul.text = tr("RUTE_SELESAI")
	_ikon.texture = GayaHud.tekstur("glif_centang_ok")
	_tombol.text = tr("RUTE_MAIN_LAGI")
	_tombol.custom_minimum_size = Vector2(Config.HUD_TOMBOL_LEBAR_PX, Config.HUD_TOMBOL_TINGGI_PX)
	GayaHud.tombol_utama(_tombol)
	_tombol.ditekan.connect(main_lagi_diminta.emit)
	tampilkan(false)


## Menampilkan atau menyembunyikan banner "Rute selesai" (tanpa tombol; Main lagi ada di layar hasil).
func tampilkan(nilai: bool) -> void:
	_judul.text = tr("RUTE_SELESAI")
	_ikon.texture = GayaHud.tekstur("glif_centang_ok")
	_tombol.visible = false
	visible = nilai


## Menampilkan banner galat `RUTE_GAGAL_MUAT` (rute tidak bisa dimuat atau disusun) dan tombol "Main lagi" untuk mencoba seed berikutnya.
## Teks galat rinci hanya ke log developer (`push_error`).
func tampilkan_galat() -> void:
	_judul.text = tr("RUTE_GAGAL_MUAT")
	_ikon.texture = GayaHud.tekstur("glif_seru_warn")
	_tombol.visible = true
	visible = true


## True bila banner sedang tampil.
func tampil() -> bool:
	return visible


## True bila tombol "Main lagi" banner (hanya galat) tampil.
func tombol_tampil() -> bool:
	return visible and _tombol.visible


## Teks banner yang tampil (untuk tes).
func teks_banner() -> String:
	return _judul.text


## Teks tombol "Main lagi" banner galat (untuk tes).
func teks_tombol() -> String:
	return _tombol.text


## Persegi banner dalam koordinat viewport game.
func rect_banner() -> Rect2:
	return _banner.get_global_rect()


## Persegi tombol "Main lagi" banner galat dalam koordinat viewport game.
func rect_tombol() -> Rect2:
	return _tombol.get_global_rect()
