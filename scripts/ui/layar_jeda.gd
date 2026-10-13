class_name LayarJeda
extends CanvasLayer
## Layar jeda sementara (D-6 run fase1b-umpan-balik, DESIGN_SPEC 4 "Jeda" versi sementara): lapisan gelap `HUD_PANEL` di atas jalan,
## judul `JEDA_JUDUL`, dan tombol `JEDA_LANJUT`. Belum ada pengaturan atau keluar ke menu.
##
## Tipis: hanya menampilkan dan memancarkan `lanjut_diminta`; status jeda diurus `JalanUji` (`JedaSim`). `process_mode` di scene =
## `WHEN_PAUSED`: selama `SceneTree.paused` hanya layar ini yang menerima sentuhan. Tata letak anchor + Container, warna dari
## `Palette` (`GayaHud` untuk tombol), teks lewat kunci terjemahan. Tinggi tombol `Config.HUD_TOMBOL_TINGGI_PX` (≥ 44 dp di A54).
## Tombol "Lanjut" adalah `TombolSentuh`: bisa diketuk jari mana pun walau jempol lain masih menempel di layar.

## Tombol "Lanjut" ditekan.
signal lanjut_diminta

@onready var _latar: ColorRect = %Latar
@onready var _judul: Label = %JudulJeda
@onready var _tombol_lanjut: TombolSentuh = %TombolLanjut


func _ready() -> void:
	_latar.color = Palette.HUD_PANEL
	_judul.add_theme_color_override(&"font_color", Palette.TEXT)
	_tombol_lanjut.custom_minimum_size = Vector2(Config.JEDA_TOMBOL_LEBAR_PX, Config.HUD_TOMBOL_TINGGI_PX)
	GayaHud.terapkan_tombol(_tombol_lanjut)
	# Di atas lapisan gelap garis `OUTLINE` tidak terlihat; garis `TEXT` seperti tombol jeda supaya terbaca sebagai tombol.
	_tombol_lanjut.add_theme_stylebox_override(&"normal", GayaHud.kotak(Palette.HUD_PANEL, Palette.TEXT))
	_tombol_lanjut.add_theme_stylebox_override(&"hover", GayaHud.kotak(Palette.HUD_PANEL, Palette.TEXT))
	_tombol_lanjut.ditekan.connect(lanjut_diminta.emit)


## Menampilkan atau menyembunyikan layar jeda.
func tampilkan(nilai: bool) -> void:
	visible = nilai


## True bila layar jeda sedang tampil.
func tampil() -> bool:
	return visible


## Persegi tombol "Lanjut" dalam koordinat viewport game (untuk tes dan probe).
func rect_tombol_lanjut() -> Rect2:
	return _tombol_lanjut.get_global_rect()
