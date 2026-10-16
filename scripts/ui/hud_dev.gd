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
## (rule `ui-scenes`).
## Panel sisa koran (DESIGN_SPEC 3.5, run fase2a-lemparan): di samping panel kecepatan dalam satu baris (`BarisBawah`, celah = x 400 dikurangi
## ujung panel kecepatan), label `HUD_KORAN`, angka sisa, dan deret ikon (`DeretKoran`, `SisaKoran.ikon_hud`); saat habis label
## `HUD_KORAN_HABIS` tampil (penanda teks, bukan hanya warna) dan semua ikon redup. Saat kidal baris dicerminkan: panel kecepatan menempel
## 210 dari tepi kanan dan panel koran di sebelah kirinya. Panel tidak menerima sentuhan: swipe yang mulai di atasnya tetap swipe.
## Tombol jeda (`TombolJeda`, DESIGN_SPEC 3.1, run fase1b-umpan-balik): kiri atas, area sentuh `Config.HUD_JEDA_SENTUH_PX` persegi di
## strip atas dengan gambar 24×24 di x `HUD_JEDA_GAMBAR_X_PX`, y `HUD_JEDA_GAMBAR_Y_PX`; tidak dicerminkan saat kidal (strip atas
## bebas dari kontrol). Menekannya memancarkan `jeda_diminta` (layar jeda ada di `JalanUji`).
## Tombol mode bantu (D-7 run fase2b-bantu-audio, GDD 5.3): sakelar di strip atas di samping tombol kidal (satu baris `BarisTombol` di
## tengah, jarak `HUD_TOMBOL_JARAK_PX`), ukuran sama dengan tombol kidal, tidak dicerminkan saat kidal. Bawaan mati dan tidak disimpan
## (belum ada save). Status tampil lewat teks (`HUD_BANTU_MATI` / `HUD_BANTU_NYALA`) selain gaya ditekan, jadi tidak hanya warna.
## Menekannya memancarkan `bantu_diubah`.
## Run fase3b-rintangan-skor bagian B (AC-13, AC-15, usulan; HUD rute final di Run 3C):
## - Panel skor (`PanelSkor`) di strip atas sisi swipe, `HUD_SKOR_GESER_PX` dari tepi (tempat tombol dev "Main lagi" di sisi itu tetap
##   bebas), tiga baris kunci terjemahan: `HUD_SKOR` + angka, `HUD_COMBO` + pengali berikutnya (`HUD_COMBO_ANGKA`, "x1.3") dan label
##   `HUD_COMBO_PUTUS` (`FAIL`) sesaat sesudah combo putus (penanda teks, bukan hanya warna), `HUD_KOIN` + angka. Kidal: dicerminkan ke sisi
##   lain (sisi swipe kidal). Hanya tampil di scene yang menilai skor (`atur_skor_tampil`; jalan uji tidak).
## - Tombol bel (`TombolBel`) 40x40 di pojok bawah sisi swipe (kontainer `StripBel` lebar penuh di tepi bawah), pusat
##   `BEL_TOMBOL_PUSAT_TEPI_PX` dari tepi samping dan bawah; kidal dicerminkan.
##   Hanya gambar: sentuhannya dibaca `TouchRouter` (zona tap bel), frame dari `tampilkan_bel`.

## Tombol kidal diubah: True = zona ditukar untuk tangan kiri.
signal kidal_diubah(nilai: bool)
## Tombol jeda ditekan.
signal jeda_diminta
## Tombol mode bantu diubah: True = mode bantu menyala.
signal bantu_diubah(nilai: bool)

var _angka_terakhir: String = ""
var _koran_terakhir: Vector2i = Vector2i(-1, -1)
## [skor, combo x10, koin, putus] terakhir yang ditampilkan.
var _skor_terakhir: Array = []

@onready var _strip_atas: MarginContainer = %StripAtas
@onready var _panel_bawah: MarginContainer = %PanelBawah
@onready var _baris_bawah: HBoxContainer = %BarisBawah
@onready var _panel_kecepatan: PanelContainer = %PanelKecepatan
@onready var _panel_koran: PanelContainer = %PanelKoran
@onready var _label_koran: Label = %LabelKoran
@onready var _label_habis: Label = %LabelHabis
@onready var _angka_koran: Label = %AngkaKoran
@onready var _deret_koran: DeretKoran = %DeretKoran
@onready var _label_angka: Label = %LabelAngka
@onready var _label_judul: Label = %LabelKecepatan
@onready var _bar: BarKecepatan = %BarKecepatan
@onready var _label_stamina: Label = %LabelStamina
@onready var _label_lelah: Label = %LabelLelah
@onready var _bar_stamina: BarKecepatan = %BarStamina
@onready var _tombol_kidal: Button = %TombolKidal
@onready var _tombol_bantu: Button = %TombolBantu
@onready var _baris_tombol: HBoxContainer = %BarisTombol
@onready var _strip_jeda: MarginContainer = %StripJeda
@onready var _tombol_jeda: TombolJeda = %TombolJeda
@onready var _strip_skor: MarginContainer = %StripSkor
@onready var _panel_skor: PanelContainer = %PanelSkor
@onready var _label_skor: Label = %LabelSkor
@onready var _angka_skor: Label = %AngkaSkor
@onready var _label_combo: Label = %LabelCombo
@onready var _label_putus: Label = %LabelPutus
@onready var _angka_combo: Label = %AngkaCombo
@onready var _label_koin: Label = %LabelKoin
@onready var _angka_koin: Label = %AngkaKoin
@onready var _strip_bel: MarginContainer = %StripBel
@onready var _tombol_bel: TombolBel = %TombolBel


func _ready() -> void:
	_strip_atas.add_theme_constant_override(&"margin_top", Config.HUD_TOMBOL_MARGIN_ATAS_PX)
	_tombol_kidal.custom_minimum_size = Vector2(Config.HUD_TOMBOL_LEBAR_PX, Config.HUD_TOMBOL_TINGGI_PX)
	_tombol_bantu.custom_minimum_size = Vector2(Config.HUD_TOMBOL_LEBAR_PX, Config.HUD_TOMBOL_TINGGI_PX)
	_baris_tombol.add_theme_constant_override(&"separation", Config.HUD_TOMBOL_JARAK_PX)
	_panel_kecepatan.custom_minimum_size = Vector2(Config.HUD_PANEL_KECEPATAN_LEBAR_PX, 0)
	var celah: int = Config.HUD_PANEL_KORAN_GESER_PX - Config.HUD_PANEL_KECEPATAN_GESER_PX - Config.HUD_PANEL_KECEPATAN_LEBAR_PX
	_baris_bawah.add_theme_constant_override(&"separation", celah)
	# Area sentuh jeda dipusatkan mendatar pada gambarnya; tepi atasnya sejajar tombol kidal.
	var sisa: float = float(Config.HUD_JEDA_SENTUH_PX - Config.HUD_JEDA_GAMBAR_PX) / 2
	var tepi_jeda: int = Config.HUD_JEDA_GAMBAR_X_PX - floori(sisa)
	_strip_jeda.add_theme_constant_override(&"margin_left", tepi_jeda)
	_strip_jeda.add_theme_constant_override(&"margin_top", Config.HUD_TOMBOL_MARGIN_ATAS_PX)
	_tombol_jeda.geser_gambar = Vector2(Config.HUD_JEDA_GAMBAR_X_PX - tepi_jeda, Config.HUD_JEDA_GAMBAR_Y_PX - Config.HUD_TOMBOL_MARGIN_ATAS_PX)
	_strip_skor.add_theme_constant_override(&"margin_top", Config.HUD_TOMBOL_MARGIN_ATAS_PX)
	_panel_skor.custom_minimum_size = Vector2(Config.HUD_SKOR_LEBAR_PX, 0)
	_terapkan_gaya()
	_tombol_kidal.toggled.connect(_saat_tombol_kidal)
	_tombol_bantu.toggled.connect(_saat_tombol_bantu)
	_tombol_jeda.ditekan.connect(jeda_diminta.emit)
	atur_kidal(false)
	atur_bantu(false)
	tampilkan_kecepatan(Config.KECEPATAN_SANTAI_UD)
	tampilkan_stamina(Config.STAMINA_MAKS, false)
	tampilkan_koran(Config.KORAN_AWAL, Config.KORAN_AWAL)
	tampilkan_skor(0, 0, 0, false)
	tampilkan_bel(false, 0.0)


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


## Frame tombol bel dari jari yang menahan tombol (`ditekan`) dan sisa jeda bel (`Bel.sisa_jeda_pecahan`).
func tampilkan_bel(ditekan: bool, pecahan_jeda: float) -> void:
	_tombol_bel.atur_frame(Bel.frame_tombol(ditekan, pecahan_jeda))


## Frame tombol bel yang digambar (untuk tes).
func frame_bel() -> int:
	return _tombol_bel.frame()


## Persegi tombol bel dalam koordinat viewport game.
func rect_tombol_bel() -> Rect2:
	return _tombol_bel.get_global_rect()


## Persegi panel skor dalam koordinat viewport game.
func rect_panel_skor() -> Rect2:
	return _panel_skor.get_global_rect()


## Menampilkan sisa koran: angka, deret ikon (terpakai redup), dan label `HUD_KORAN_HABIS` saat habis. Diperbarui hanya bila berubah.
func tampilkan_koran(sisa: int, penuh: int) -> void:
	var kunci: Vector2i = Vector2i(sisa, penuh)
	if kunci == _koran_terakhir:
		return
	_koran_terakhir = kunci
	var ikon: Vector2i = SisaKoran.ikon_hud(sisa, penuh, Config.HUD_KORAN_IKON_MAKS)
	_deret_koran.jumlah = ikon.x
	_deret_koran.terang = ikon.y
	_angka_koran.text = tr("HUD_KORAN_ANGKA").format({"n": maxi(sisa, 0)})
	_label_habis.visible = sisa <= 0


## Angka sisa koran yang tampil (untuk tes).
func teks_koran() -> String:
	return _angka_koran.text


## [jumlah ikon, ikon terang] deret koran yang tampil (untuk tes).
func ikon_koran() -> Vector2i:
	return Vector2i(_deret_koran.jumlah, _deret_koran.terang)


## True bila penanda habis tampil (untuk tes).
func penanda_habis_tampil() -> bool:
	return _label_habis.visible


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
	_baris_bawah.size_flags_horizontal = Control.SIZE_SHRINK_END if nilai else Control.SIZE_SHRINK_BEGIN
	_baris_bawah.move_child(_panel_koran, 0 if nilai else -1)
	# Panel skor di strip atas sisi swipe: kanan, kidal kiri (dicerminkan).
	_strip_skor.add_theme_constant_override(&"margin_left", Config.HUD_SKOR_GESER_PX if nilai else 0)
	_strip_skor.add_theme_constant_override(&"margin_right", 0 if nilai else Config.HUD_SKOR_GESER_PX)
	_panel_skor.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if nilai else Control.SIZE_SHRINK_END
	# Tombol bel: pojok bawah sisi swipe (StripBel lebar penuh di tepi bawah), pusat BEL_TOMBOL_PUSAT_TEPI_PX dari tepi samping dan bawah.
	var tepi_bel: int = Config.BEL_TOMBOL_PUSAT_TEPI_PX - floori(float(Config.BEL_TOMBOL_UKURAN_PX) / 2)
	_strip_bel.add_theme_constant_override(&"margin_left", tepi_bel if nilai else 0)
	_strip_bel.add_theme_constant_override(&"margin_right", 0 if nilai else tepi_bel)
	_strip_bel.add_theme_constant_override(&"margin_bottom", tepi_bel)
	_tombol_bel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if nilai else Control.SIZE_SHRINK_END


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


## Persegi area sentuh tombol jeda dalam koordinat viewport game.
func rect_tombol_jeda() -> Rect2:
	return _tombol_jeda.get_global_rect()


## Persegi panel kecepatan dalam koordinat viewport game.
func rect_panel_kecepatan() -> Rect2:
	return _panel_kecepatan.get_global_rect()


## Persegi panel sisa koran dalam koordinat viewport game.
func rect_panel_koran() -> Rect2:
	return _panel_koran.get_global_rect()


func _saat_tombol_kidal(nilai: bool) -> void:
	atur_kidal(nilai)
	kidal_diubah.emit(nilai)


func _saat_tombol_bantu(nilai: bool) -> void:
	atur_bantu(nilai)
	bantu_diubah.emit(nilai)


## Warna dan bentuk panel dan tombol dari `Palette` (DESIGN_SPEC 1.3): garis luar 1 px, sudut tegas.
func _terapkan_gaya() -> void:
	_panel_kecepatan.add_theme_stylebox_override(&"panel", GayaHud.kotak(Palette.HUD_PANEL, Palette.OUTLINE))
	_panel_koran.add_theme_stylebox_override(&"panel", GayaHud.kotak(Palette.HUD_PANEL, Palette.OUTLINE))
	_label_koran.add_theme_color_override(&"font_color", Palette.ACCENT)
	_label_habis.add_theme_color_override(&"font_color", Palette.FAIL)
	_angka_koran.add_theme_color_override(&"font_color", Palette.TEXT)
	_label_judul.add_theme_color_override(&"font_color", Palette.ACCENT)
	_label_angka.add_theme_color_override(&"font_color", Palette.TEXT)
	_label_stamina.add_theme_color_override(&"font_color", Palette.ACCENT)
	_label_lelah.add_theme_color_override(&"font_color", Palette.FAIL)
	_panel_skor.add_theme_stylebox_override(&"panel", GayaHud.kotak(Palette.HUD_PANEL, Palette.OUTLINE))
	for label: Label in [_label_skor, _label_combo, _label_koin]:
		label.add_theme_color_override(&"font_color", Palette.ACCENT)
	for label: Label in [_angka_skor, _angka_combo, _angka_koin]:
		label.add_theme_color_override(&"font_color", Palette.TEXT)
	_label_putus.add_theme_color_override(&"font_color", Palette.FAIL)
	GayaHud.terapkan_tombol(_tombol_kidal)
	GayaHud.terapkan_tombol(_tombol_bantu)
