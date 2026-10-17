class_name HudDev
extends HudDasar
## HUD sementara jalan uji (scene dev; Fase 0 AC-15, Fase 1 run 1A dan 1B, run 2B, run 3B). Sejak run fase3c-hud-hasil scene rute memakai
## `HudRute`; bagian bersama (tombol jeda, panel bawah kecepatan/stamina/koran, tombol bel) ada di `HudDasar`.
##
## Tambahan khusus jalan uji di strip atas (tinggi `Config.HUD_STRIP_ATAS_TINGGI_PX`, di luar kedua zona kontrol, DESIGN_SPEC 3.7, jadi
## sentuhannya tidak pernah menjadi stick atau swipe):
## - Tombol kidal dan tombol mode bantu (D-7 run fase2b-bantu-audio, GDD 5.3): satu baris `BarisTombol` di tengah, jarak
##   `HUD_TOMBOL_JARAK_PX`, ukuran sama, tidak dicerminkan saat kidal. Bawaan mati dan tidak disimpan. Status bantu tampil lewat teks
##   (`HUD_BANTU_MATI` / `HUD_BANTU_NYALA`) selain gaya ditekan, jadi tidak hanya warna. Menekannya memancarkan `kidal_diubah` /
##   `bantu_diubah`. Di scene rute kedua sakelar ada di layar jeda (O-6 run fase3c-hud-hasil); layar jeda jalan uji juga memuatnya.
## - Panel skor dev (run fase3b-rintangan-skor bagian B, AC-13, usulan): `HUD_SKOR_GESER_PX` dari tepi sisi swipe, tiga baris kunci
##   terjemahan `HUD_SKOR`, `HUD_COMBO` (+ label `HUD_COMBO_PUTUS` sesaat), `HUD_KOIN`; kidal dicerminkan. Hanya tampil di scene yang menilai
##   skor (`atur_skor_tampil`; jalan uji tidak), jadi di jalan uji tersembunyi.

## [skor, combo x10, koin, putus] terakhir yang ditampilkan.
var _skor_terakhir: Array = []

@onready var _strip_atas: MarginContainer = %StripAtas
@onready var _tombol_kidal: Button = %TombolKidal
@onready var _tombol_bantu: Button = %TombolBantu
@onready var _baris_tombol: HBoxContainer = %BarisTombol
@onready var _strip_skor: MarginContainer = %StripSkor
@onready var _panel_skor: PanelContainer = %PanelSkor
@onready var _label_skor: Label = %LabelSkor
@onready var _angka_skor: Label = %AngkaSkor
@onready var _label_combo: Label = %LabelCombo
@onready var _label_putus: Label = %LabelPutus
@onready var _angka_combo: Label = %AngkaCombo
@onready var _label_koin: Label = %LabelKoin
@onready var _angka_koin: Label = %AngkaKoin


func _ready() -> void:
	_strip_atas.add_theme_constant_override(&"margin_top", Config.HUD_TOMBOL_MARGIN_ATAS_PX)
	_tombol_kidal.custom_minimum_size = Vector2(Config.HUD_TOMBOL_LEBAR_PX, Config.HUD_TOMBOL_TINGGI_PX)
	_tombol_bantu.custom_minimum_size = Vector2(Config.HUD_TOMBOL_LEBAR_PX, Config.HUD_TOMBOL_TINGGI_PX)
	_baris_tombol.add_theme_constant_override(&"separation", Config.HUD_TOMBOL_JARAK_PX)
	_strip_skor.add_theme_constant_override(&"margin_top", Config.HUD_TOMBOL_MARGIN_ATAS_PX)
	_panel_skor.custom_minimum_size = Vector2(Config.HUD_SKOR_LEBAR_PX, 0)
	_terapkan_gaya()
	_tombol_kidal.toggled.connect(_saat_tombol_kidal)
	_tombol_bantu.toggled.connect(_saat_tombol_bantu)
	super()
	atur_bantu(false)
	tampilkan_skor(0, 0, 0, false)


## Menampilkan skor, pengali combo untuk antaran berikutnya (`SkorRute.pengali_combo(beruntun)`), koin, dan label PUTUS. Diperbarui hanya
## bila berubah.
func tampilkan_skor(skor: int, beruntun: int, koin: int, putus: bool) -> void:
	var kunci: Array = [skor, beruntun, koin, putus]
	if kunci == _skor_terakhir:
		return
	_skor_terakhir = kunci
	_angka_skor.text = tr("HUD_SKOR_ANGKA").format({"n": skor})
	_angka_combo.text = tr("HUD_COMBO_ANGKA").format({"x": "%.1f" % SkorRute.pengali_combo(beruntun)})
	_angka_koin.text = tr("HUD_KOIN_ANGKA").format({"n": koin})
	_label_putus.visible = putus


## Menampilkan atau menyembunyikan panel skor (scene yang tidak menilai skor menyembunyikannya).
func atur_skor_tampil(nilai: bool) -> void:
	_strip_skor.visible = nilai


## True bila panel skor tampil.
func skor_tampil() -> bool:
	return _strip_skor.visible


## Teks angka skor, combo, dan koin yang tampil (untuk tes).
func teks_skor() -> String:
	return _angka_skor.text


func teks_combo() -> String:
	return _angka_combo.text


func teks_koin() -> String:
	return _angka_koin.text


## True bila label PUTUS tampil (untuk tes).
func putus_tampil() -> bool:
	return _label_putus.visible


## Persegi panel skor dalam koordinat viewport game.
func rect_panel_skor() -> Rect2:
	return _panel_skor.get_global_rect()


## Memindahkan panel bawah, tombol bel, dan panel skor ke sisi tangan yang dipakai dan menyamakan tombol (tanpa memancarkan sinyal).
func atur_kidal(nilai: bool) -> void:
	super(nilai)
	_tombol_kidal.set_pressed_no_signal(nilai)
	# Panel skor di strip atas sisi swipe: kanan, kidal kiri (dicerminkan).
	_strip_skor.add_theme_constant_override(&"margin_left", Config.HUD_SKOR_GESER_PX if nilai else 0)
	_strip_skor.add_theme_constant_override(&"margin_right", 0 if nilai else Config.HUD_SKOR_GESER_PX)
	_panel_skor.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if nilai else Control.SIZE_SHRINK_END


## Persegi tombol kidal dalam koordinat viewport game (untuk memeriksa tidak masuk zona kontrol).
func rect_tombol_kidal() -> Rect2:
	return _tombol_kidal.get_global_rect()


## Menyamakan tombol mode bantu dengan `nilai` (ditekan dan teks status) tanpa memancarkan sinyal.
func atur_bantu(nilai: bool) -> void:
	_tombol_bantu.set_pressed_no_signal(nilai)
	_tombol_bantu.text = "HUD_BANTU_NYALA" if nilai else "HUD_BANTU_MATI"


## Persegi tombol mode bantu dalam koordinat viewport game.
func rect_tombol_bantu() -> Rect2:
	return _tombol_bantu.get_global_rect()


func _saat_tombol_kidal(nilai: bool) -> void:
	atur_kidal(nilai)
	kidal_diubah.emit(nilai)


func _saat_tombol_bantu(nilai: bool) -> void:
	atur_bantu(nilai)
	bantu_diubah.emit(nilai)


## Warna dan bentuk panel skor dan tombol strip atas dari `Palette` (DESIGN_SPEC 1.3): garis luar 1 px, sudut tegas.
func _terapkan_gaya() -> void:
	_panel_skor.add_theme_stylebox_override(&"panel", GayaHud.kotak(Palette.HUD_PANEL, Palette.OUTLINE))
	for label: Label in [_label_skor, _label_combo, _label_koin]:
		label.add_theme_color_override(&"font_color", Palette.ACCENT)
	for label: Label in [_angka_skor, _angka_combo, _angka_koin]:
		label.add_theme_color_override(&"font_color", Palette.TEXT)
	_label_putus.add_theme_color_override(&"font_color", Palette.FAIL)
	GayaHud.terapkan_tombol(_tombol_kidal)
	GayaHud.terapkan_tombol(_tombol_bantu)
