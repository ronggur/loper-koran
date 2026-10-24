class_name LayarJeda
extends CanvasLayer
## Layar jeda (D-6 run fase1b-umpan-balik, O-6 run fase3c-hud-hasil; tata ulang run ui2-semua-layar bagian C1, AC-4, V-2; kanvas Jeda.dc.html; usulan): lapisan `HUD_PANEL` alpha 72 % di atas jalan
## (`TampilJeda.warna_lapisan`), panel layar 232 lebar di tengah berisi judul `JEDA_JUDUL` dengan glif jeda, tombol Lanjut (peran utama), garis pemisah, dan sakelar Kidal dan Bantu (peran sakelar,
## sampai layar pengaturan ada).
##
## Tipis: hanya menampilkan dan memancarkan `lanjut_diminta`, `kidal_diubah`, dan `bantu_diubah`; status jeda diurus adegan (`JedaSim`), status kidal dan bantu disamakan adegan lewat `atur_kidal` /
## `atur_bantu` (tanpa sinyal). `process_mode` di scene = `WHEN_PAUSED`: selama `SceneTree.paused` hanya layar ini yang menerima sentuhan. Tata letak anchor + Container, bentuk dari `GayaHud`
## dan `TampilJeda`, teks lewat kunci terjemahan. Tinggi tombol `Config.HUD_TOMBOL_TINGGI_PX` (>= 44 dp di A54). Semua tombol `TombolSentuh`: bisa diketuk jari mana pun walau jempol lain masih
## menempel di layar.
## Sakelar (O-6): satu ketukan membalik status. Status terbaca TANPA warna: teks (`JEDA_KIDAL_MATI` / `JEDA_KIDAL_NYALA`, `HUD_BANTU_MATI` / `HUD_BANTU_NYALA`), bingkai (`ACCENT` saat nyala), dan kenop
## (`KenopSakelar`: sisi dan bentuk berganti). Bawaan mati, tidak disimpan (belum ada save).

## Tombol "Lanjut" ditekan.
signal lanjut_diminta
## Sakelar kidal diketuk: nilai baru.
signal kidal_diubah(nilai: bool)
## Sakelar mode bantu diketuk: nilai baru.
signal bantu_diubah(nilai: bool)

var _kidal: bool = false
var _bantu: bool = false

@onready var _latar: ColorRect = %Latar
@onready var _panel: PanelContainer = %PanelJeda
@onready var _isi: VBoxContainer = %Isi
@onready var _kepala: HBoxContainer = %Kepala
@onready var _ikon_judul: TextureRect = %IkonJudul
@onready var _judul: Label = %JudulJeda
@onready var _tombol_lanjut: TombolSentuh = %TombolLanjut
@onready var _margin_pisah: MarginContainer = %MarginPisah
@onready var _garis_pisah: ColorRect = %GarisPisah
@onready var _sakelar_kidal: TombolSentuh = %SakelarKidal
@onready var _sakelar_bantu: TombolSentuh = %SakelarBantu
@onready var _kenop_kidal: KenopSakelar = %KenopKidal
@onready var _kenop_bantu: KenopSakelar = %KenopBantu


func _ready() -> void:
	_latar.color = TampilJeda.warna_lapisan()
	_panel.custom_minimum_size = Vector2(Config.JEDA_PANEL_LEBAR_PX, 0)
	_panel.add_theme_stylebox_override(&"panel", GayaHud.panel_jeda())
	_isi.add_theme_constant_override(&"separation", Config.JEDA_ISI_JARAK_PX)
	_kepala.custom_minimum_size = Vector2(0, Config.JEDA_KEPALA_TINGGI_PX)
	_kepala.add_theme_constant_override(&"separation", Config.JEDA_KEPALA_JARAK_PX)
	_ikon_judul.texture = GayaHud.tekstur(TampilJeda.nama_glif_judul())
	_judul.add_theme_color_override(&"font_color", Palette.TEXT)
	_margin_pisah.add_theme_constant_override(&"margin_top", Config.JEDA_PISAH_MARGIN_PX)
	_margin_pisah.add_theme_constant_override(&"margin_bottom", Config.JEDA_PISAH_MARGIN_PX)
	_garis_pisah.color = Palette.UI_PANEL_RAISED
	for tombol: TombolSentuh in [_tombol_lanjut, _sakelar_kidal, _sakelar_bantu]:
		tombol.custom_minimum_size = Vector2(Config.JEDA_TOMBOL_LEBAR_PX, Config.HUD_TOMBOL_TINGGI_PX)
	GayaHud.tombol_utama(_tombol_lanjut)
	_tombol_lanjut.icon = GayaHud.tekstur(TampilJeda.nama_glif_lanjut())
	_tombol_lanjut.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_tombol_lanjut.add_theme_constant_override(&"h_separation", Config.JEDA_LANJUT_JARAK_PX)
	_pasang_kenop(_kenop_kidal)
	_pasang_kenop(_kenop_bantu)
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


## Menyamakan sakelar kidal dengan `nilai` (teks, bingkai, kenop) tanpa memancarkan sinyal.
func atur_kidal(nilai: bool) -> void:
	_kidal = nilai
	_sakelar_kidal.text = TampilJeda.kunci_teks_kidal(nilai)
	GayaHud.tombol_sakelar(_sakelar_kidal, nilai, Config.JEDA_SAKELAR_PAD_TAMBAH_PX)
	_kenop_kidal.nyala = nilai


## Menyamakan sakelar mode bantu dengan `nilai` (teks, bingkai, kenop) tanpa memancarkan sinyal.
func atur_bantu(nilai: bool) -> void:
	_bantu = nilai
	_sakelar_bantu.text = TampilJeda.kunci_teks_bantu(nilai)
	GayaHud.tombol_sakelar(_sakelar_bantu, nilai, Config.JEDA_SAKELAR_PAD_TAMBAH_PX)
	_kenop_bantu.nyala = nilai


## Persegi panel jeda dalam koordinat viewport game (untuk tes dan probe).
func rect_panel() -> Rect2:
	return _panel.get_global_rect()


## Persegi tombol "Lanjut" dalam koordinat viewport game (untuk tes dan probe).
func rect_tombol_lanjut() -> Rect2:
	return _tombol_lanjut.get_global_rect()


## Persegi sakelar kidal dan bantu dalam koordinat viewport game (untuk tes dan probe).
func rect_sakelar_kidal() -> Rect2:
	return _sakelar_kidal.get_global_rect()


func rect_sakelar_bantu() -> Rect2:
	return _sakelar_bantu.get_global_rect()


## Persegi kenop sakelar dalam koordinat viewport game (untuk tes dan probe).
func rect_kenop_kidal() -> Rect2:
	return _kenop_kidal.get_global_rect()


func rect_kenop_bantu() -> Rect2:
	return _kenop_bantu.get_global_rect()


## Sakelar (untuk tes: `ditekan.emit()`).
func sakelar_kidal() -> TombolSentuh:
	return _sakelar_kidal


func sakelar_bantu() -> TombolSentuh:
	return _sakelar_bantu


## Kenop sakelar (untuk tes dan probe).
func kenop_kidal() -> KenopSakelar:
	return _kenop_kidal


func kenop_bantu() -> KenopSakelar:
	return _kenop_bantu


## Tombol Lanjut (untuk tes dan probe).
func tombol_lanjut() -> TombolSentuh:
	return _tombol_lanjut


## Persegi judul dalam koordinat viewport game (untuk tes dan probe).
func rect_judul() -> Rect2:
	return _judul.get_global_rect()


func _saat_sakelar_kidal() -> void:
	atur_kidal(not _kidal)
	kidal_diubah.emit(_kidal)


func _saat_sakelar_bantu() -> void:
	atur_bantu(not _bantu)
	bantu_diubah.emit(_bantu)


# Kenop di ujung akhir sakelar: sejajar isi (tepi 9-slice + padding sakelar), tegak di tengah wajah (bibir bawah 2 px membuat wajah naik 1 px).
func _pasang_kenop(kenop: KenopSakelar) -> void:
	var tepi: int = Config.UI_TOMBOL_SLICE_SAMPING_PX + Config.UI_TOMBOL_SAKELAR_PAD_X_PX + Config.JEDA_SAKELAR_PAD_TAMBAH_PX
	kenop.offset_right = float(-tepi)
	kenop.offset_left = float(-tepi - Config.JEDA_KENOP_LEBAR_PX)
	var atas: float = -float(Config.JEDA_KENOP_TINGGI_PX) / 2 - float(Config.UI_GARIS_PX)
	kenop.offset_top = atas
	kenop.offset_bottom = atas + float(Config.JEDA_KENOP_TINGGI_PX)
