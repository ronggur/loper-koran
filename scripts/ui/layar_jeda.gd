class_name LayarJeda
extends CanvasLayer
## Layar jeda sementara (D-6 run fase1b-umpan-balik, DESIGN_SPEC 4 "Jeda" versi sementara): lapisan gelap `HUD_PANEL` di atas jalan,
## judul `JEDA_JUDUL`, tombol `JEDA_LANJUT`, dan (O-6 run fase3c-hud-hasil, sampai layar pengaturan ada) sakelar Kidal dan Bantu.
##
## Tipis: hanya menampilkan dan memancarkan `lanjut_diminta`, `kidal_diubah`, dan `bantu_diubah`; status jeda diurus adegan (`JedaSim`),
## status kidal dan bantu disamakan adegan lewat `atur_kidal` / `atur_bantu` (tanpa sinyal). `process_mode` di scene = `WHEN_PAUSED`:
## selama `SceneTree.paused` hanya layar ini yang menerima sentuhan. Tata letak anchor + Container, warna dari `Palette` (`GayaHud` untuk
## tombol), teks lewat kunci terjemahan. Tinggi tombol `Config.HUD_TOMBOL_TINGGI_PX` (>= 44 dp di A54). Semua tombol `TombolSentuh`: bisa
## diketuk jari mana pun walau jempol lain masih menempel di layar.
## Sakelar (O-6): satu ketukan membalik status. Status terbaca dari teks (`JEDA_KIDAL_MATI` / `JEDA_KIDAL_NYALA`, `HUD_BANTU_MATI` /
## `HUD_BANTU_NYALA`) dan dari bingkai (`ACCENT` saat nyala), bukan warna saja. Bawaan mati, tidak disimpan (belum ada save).

## Tombol "Lanjut" ditekan.
signal lanjut_diminta
## Sakelar kidal diketuk: nilai baru.
signal kidal_diubah(nilai: bool)
## Sakelar mode bantu diketuk: nilai baru.
signal bantu_diubah(nilai: bool)

var _kidal: bool = false
var _bantu: bool = false

@onready var _latar: ColorRect = %Latar
@onready var _judul: Label = %JudulJeda
@onready var _tombol_lanjut: TombolSentuh = %TombolLanjut
@onready var _baris_sakelar: HBoxContainer = %BarisSakelar
@onready var _sakelar_kidal: TombolSentuh = %SakelarKidal
@onready var _sakelar_bantu: TombolSentuh = %SakelarBantu


func _ready() -> void:
	_latar.color = Palette.HUD_PANEL
	_judul.add_theme_color_override(&"font_color", Palette.TEXT)
	_baris_sakelar.add_theme_constant_override(&"separation", Config.HUD_TOMBOL_JARAK_PX)
	for tombol: TombolSentuh in [_tombol_lanjut, _sakelar_kidal, _sakelar_bantu]:
		tombol.custom_minimum_size = Vector2(Config.JEDA_TOMBOL_LEBAR_PX, Config.HUD_TOMBOL_TINGGI_PX)
		GayaHud.terapkan_tombol(tombol)
	_gaya_garis(_tombol_lanjut, false)
	_tombol_lanjut.ditekan.connect(lanjut_diminta.emit)
	_sakelar_kidal.ditekan.connect(_saat_sakelar_kidal)
	_sakelar_bantu.ditekan.connect(_saat_sakelar_bantu)
	atur_kidal(false)
	atur_bantu(false)


## Menampilkan atau menyembunyikan layar jeda.
func tampilkan(nilai: bool) -> void:
	visible = nilai


## True bila layar jeda sedang tampil.
func tampil() -> bool:
	return visible


## Menyamakan sakelar kidal dengan `nilai` (teks dan bingkai) tanpa memancarkan sinyal.
func atur_kidal(nilai: bool) -> void:
	_kidal = nilai
	_sakelar_kidal.text = "JEDA_KIDAL_NYALA" if nilai else "JEDA_KIDAL_MATI"
	_gaya_garis(_sakelar_kidal, nilai)


## Menyamakan sakelar mode bantu dengan `nilai` (teks dan bingkai) tanpa memancarkan sinyal.
func atur_bantu(nilai: bool) -> void:
	_bantu = nilai
	_sakelar_bantu.text = "HUD_BANTU_NYALA" if nilai else "HUD_BANTU_MATI"
	_gaya_garis(_sakelar_bantu, nilai)


## Persegi tombol "Lanjut" dalam koordinat viewport game (untuk tes dan probe).
func rect_tombol_lanjut() -> Rect2:
	return _tombol_lanjut.get_global_rect()


## Persegi sakelar kidal dan bantu dalam koordinat viewport game (untuk tes dan probe).
func rect_sakelar_kidal() -> Rect2:
	return _sakelar_kidal.get_global_rect()


func rect_sakelar_bantu() -> Rect2:
	return _sakelar_bantu.get_global_rect()


## Sakelar (untuk tes: `ditekan.emit()`).
func sakelar_kidal() -> TombolSentuh:
	return _sakelar_kidal


func sakelar_bantu() -> TombolSentuh:
	return _sakelar_bantu


func _saat_sakelar_kidal() -> void:
	atur_kidal(not _kidal)
	kidal_diubah.emit(_kidal)


func _saat_sakelar_bantu() -> void:
	atur_bantu(not _bantu)
	bantu_diubah.emit(_bantu)


## Di atas lapisan gelap garis `OUTLINE` tidak terlihat; garis `TEXT` seperti tombol jeda supaya terbaca sebagai tombol, `ACCENT` saat
## sakelar nyala (bersama teks status).
func _gaya_garis(tombol: TombolSentuh, nyala: bool) -> void:
	var garis: Color = Palette.ACCENT if nyala else Palette.TEXT
	var isi: Color = Palette.UI_PANEL_RAISED if nyala else Palette.HUD_PANEL
	tombol.add_theme_stylebox_override(&"normal", GayaHud.kotak(isi, garis))
	tombol.add_theme_stylebox_override(&"hover", GayaHud.kotak(isi, garis))
	tombol.add_theme_color_override(&"font_color", Palette.ACCENT if nyala else Palette.TEXT)
	tombol.add_theme_color_override(&"font_hover_color", Palette.ACCENT if nyala else Palette.TEXT)
