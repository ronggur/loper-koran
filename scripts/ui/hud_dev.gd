class_name HudDev
extends CanvasLayer
## HUD sementara (Fase 0 AC-15, Fase 1 run 1A dan 1B): panel kecepatan dan stamina di bawah, tombol jeda dan tombol kidal di strip atas.
##
## `CanvasLayer` terpisah dari dunia. Tata letak memakai anchor dan Container (bukan posisi piksel absolut):
## panel kecepatan menempel di bawah dengan margin dari tepi layar sisi stick (DESIGN_SPEC 3.5) dan pindah
## sisi saat kidal; tombol kidal ada di strip atas (tinggi `Config.HUD_STRIP_ATAS_TINGGI_PX`), di luar kedua
## zona kontrol (DESIGN_SPEC 3.7), jadi sentuhannya tidak pernah menjadi stick atau swipe. Teks hanya kunci
## terjemahan (`translations/ui.csv`); warna dari `Palette` lewat skrip, font dari `assets/ui/theme.tres`.
## Panel bawah memuat dua bar (DESIGN_SPEC 3.5): kecepatan (isi `TEXT`) dan stamina (isi `ACCENT`, `FAIL` di bawah
## `Config.HUD_STAMINA_AMBANG_RENDAH`). Saat lelah label `HUD_LELAH` tampil di samping label stamina: penanda bukan warna
## (rule `ui-scenes`). Panel koran belum ada di run ini.
## Tombol jeda (`TombolJeda`, DESIGN_SPEC 3.1, run fase1b-umpan-balik): kiri atas, area sentuh `Config.HUD_JEDA_SENTUH_PX` persegi di
## strip atas dengan gambar 24×24 di x `HUD_JEDA_GAMBAR_X_PX`, y `HUD_JEDA_GAMBAR_Y_PX`; tidak dicerminkan saat kidal (strip atas
## bebas dari kontrol). Menekannya memancarkan `jeda_diminta` (layar jeda ada di `JalanUji`).

## Tombol kidal diubah: True = zona ditukar untuk tangan kiri.
signal kidal_diubah(nilai: bool)
## Tombol jeda ditekan.
signal jeda_diminta

var _angka_terakhir: String = ""

@onready var _strip_atas: MarginContainer = %StripAtas
@onready var _panel_bawah: MarginContainer = %PanelBawah
@onready var _panel_kecepatan: PanelContainer = %PanelKecepatan
@onready var _label_angka: Label = %LabelAngka
@onready var _label_judul: Label = %LabelKecepatan
@onready var _bar: BarKecepatan = %BarKecepatan
@onready var _label_stamina: Label = %LabelStamina
@onready var _label_lelah: Label = %LabelLelah
@onready var _bar_stamina: BarKecepatan = %BarStamina
@onready var _tombol_kidal: Button = %TombolKidal
@onready var _strip_jeda: MarginContainer = %StripJeda
@onready var _tombol_jeda: TombolJeda = %TombolJeda


func _ready() -> void:
	_strip_atas.add_theme_constant_override(&"margin_top", Config.HUD_TOMBOL_MARGIN_ATAS_PX)
	_tombol_kidal.custom_minimum_size = Vector2(Config.HUD_TOMBOL_LEBAR_PX, Config.HUD_TOMBOL_TINGGI_PX)
	_panel_kecepatan.custom_minimum_size = Vector2(Config.HUD_PANEL_KECEPATAN_LEBAR_PX, 0)
	# Area sentuh jeda dipusatkan mendatar pada gambarnya; tepi atasnya sejajar tombol kidal.
	var sisa: float = float(Config.HUD_JEDA_SENTUH_PX - Config.HUD_JEDA_GAMBAR_PX) / 2
	var tepi_jeda: int = Config.HUD_JEDA_GAMBAR_X_PX - floori(sisa)
	_strip_jeda.add_theme_constant_override(&"margin_left", tepi_jeda)
	_strip_jeda.add_theme_constant_override(&"margin_top", Config.HUD_TOMBOL_MARGIN_ATAS_PX)
	_tombol_jeda.geser_gambar = Vector2(Config.HUD_JEDA_GAMBAR_X_PX - tepi_jeda, Config.HUD_JEDA_GAMBAR_Y_PX - Config.HUD_TOMBOL_MARGIN_ATAS_PX)
	_terapkan_gaya()
	_tombol_kidal.toggled.connect(_saat_tombol_kidal)
	_tombol_jeda.ditekan.connect(jeda_diminta.emit)
	atur_kidal(false)
	tampilkan_kecepatan(Config.KECEPATAN_SANTAI_UD)
	tampilkan_stamina(Config.STAMINA_MAKS, false)


## Menampilkan kecepatan (u/d) di bar dan angka. Angka hanya diperbarui bila teksnya berubah.
func tampilkan_kecepatan(kecepatan_ud: float) -> void:
	_bar.nilai = kecepatan_ud / Config.KECEPATAN_NGEBUT_UD
	var angka: String = "%.1f" % kecepatan_ud
	if angka != _angka_terakhir:
		_angka_terakhir = angka
		_label_angka.text = tr("HUD_KECEPATAN_ANGKA").format({"v": angka})


## Menampilkan stamina (0..`Config.STAMINA_MAKS`) di bar: isi `ACCENT`, `FAIL` di bawah `Config.HUD_STAMINA_AMBANG_RENDAH`.
## `lelah` menampilkan label `HUD_LELAH` (penanda teks, bukan hanya warna).
func tampilkan_stamina(stamina: float, lelah: bool) -> void:
	_bar_stamina.nilai = stamina / Config.STAMINA_MAKS
	_bar_stamina.warna_isi = Palette.FAIL if stamina < Config.HUD_STAMINA_AMBANG_RENDAH else Palette.ACCENT
	_label_lelah.visible = lelah


## Warna isi bar stamina saat ini (untuk tes).
func warna_stamina() -> Color:
	return _bar_stamina.warna_isi


## Isi bar stamina saat ini, 0 sampai 1 (untuk tes).
func nilai_stamina() -> float:
	return _bar_stamina.nilai


## Isi bar kecepatan saat ini, 0 sampai 1 (untuk tes).
func nilai_kecepatan() -> float:
	return _bar.nilai


## True bila penanda lelah tampil (untuk tes).
func penanda_lelah_tampil() -> bool:
	return _label_lelah.visible


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


## Persegi area sentuh tombol jeda dalam koordinat viewport game.
func rect_tombol_jeda() -> Rect2:
	return _tombol_jeda.get_global_rect()


## Persegi panel kecepatan dalam koordinat viewport game.
func rect_panel_kecepatan() -> Rect2:
	return _panel_kecepatan.get_global_rect()


func _saat_tombol_kidal(nilai: bool) -> void:
	atur_kidal(nilai)
	kidal_diubah.emit(nilai)


## Warna dan bentuk panel dan tombol dari `Palette` (DESIGN_SPEC 1.3): garis luar 1 px, sudut tegas.
func _terapkan_gaya() -> void:
	_panel_kecepatan.add_theme_stylebox_override(&"panel", GayaHud.kotak(Palette.HUD_PANEL, Palette.OUTLINE))
	_label_judul.add_theme_color_override(&"font_color", Palette.ACCENT)
	_label_angka.add_theme_color_override(&"font_color", Palette.TEXT)
	_label_stamina.add_theme_color_override(&"font_color", Palette.ACCENT)
	_label_lelah.add_theme_color_override(&"font_color", Palette.FAIL)
	GayaHud.terapkan_tombol(_tombol_kidal)
