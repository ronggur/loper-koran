class_name HudDasar
extends CanvasLayer
## Bagian HUD yang sama di jalan uji (`HudDev`) dan rute (`HudRute`) (run fase3c-hud-hasil, dipisah dari `HudDev`): tombol jeda kiri atas,
## panel bawah kecepatan/stamina dan sisa koran, dan tombol bel. Pewarisnya menambah isi strip atas.
##
## `CanvasLayer` terpisah dari dunia. Tata letak memakai anchor dan Container (bukan posisi piksel absolut):
## - Panel bawah (DESIGN_SPEC 3.5): panel kecepatan menempel di bawah `HUD_PANEL_KECEPATAN_GESER_PX` dari tepi layar sisi stick dan panel
##   sisa koran di sampingnya dalam satu baris (`BarisBawah`, celah = x 400 dikurangi ujung panel kecepatan); keduanya pindah sisi saat kidal
##   (dicerminkan). Dua bar: kecepatan (isi `TEXT`) dan stamina (isi `ACCENT`, `FAIL` di bawah `HUD_STAMINA_AMBANG_RENDAH`); label
##   `HUD_LELAH` saat lelah dan `HUD_KORAN_HABIS` saat koran habis (penanda teks, bukan hanya warna). Panel tidak menerima sentuhan.
## - Tombol jeda (`TombolJeda`, DESIGN_SPEC 3.1): area sentuh `HUD_JEDA_SENTUH_PX` persegi dengan gambar 24x24 di x `HUD_JEDA_GAMBAR_X_PX`,
##   y `HUD_JEDA_GAMBAR_Y_PX`; tidak dicerminkan saat kidal. Menekannya memancarkan `jeda_diminta`.
## - Tombol bel (`TombolBel`) 40x40 di pojok bawah sisi swipe (`StripBel` lebar penuh di tepi bawah), pusat `BEL_TOMBOL_PUSAT_TEPI_PX` dari
##   tepi samping dan bawah; kidal dicerminkan. Hanya gambar: sentuhannya dibaca `TouchRouter`, frame dari `tampilkan_bel`.
## - Zona aman (AC-9 run fase3c-hud-hasil, `ZonaAman`): `atur_inset` menggeser elemen tiap tepi SAMA BESAR, `ZonaAman.geser(acuan, inset)`
##   dengan acuan elemen terluar tepi itu (tepi x: strip radar `RADAR_TEPI_PX`; atas: area sentuh jeda `HUD_TOMBOL_MARGIN_ATAS_PX`; bawah:
##   `HUD_MARGIN_TEPI_PX`). Inset bawaan nol (jalan uji tidak memanggilnya, jadi tata letaknya tetap). Zona tap bel ikut digeser lewat
##   `geser_bel` (diberikan adegan ke `TouchRouter`).
## Teks hanya kunci terjemahan; warna dari `Palette`; font dari `assets/ui/theme.tres`.

## Sakelar kidal di HUD diubah (hanya `HudDev`; rute memakai layar jeda, O-6): True = zona ditukar untuk tangan kiri.
signal kidal_diubah(nilai: bool)
## Tombol jeda ditekan.
signal jeda_diminta
## Sakelar mode bantu di HUD diubah (hanya `HudDev`; rute memakai layar jeda, O-6).
signal bantu_diubah(nilai: bool)

var _angka_terakhir: String = ""
var _koran_terakhir: Vector2i = Vector2i(-1, -1)
var _kidal: bool = false
## Inset aman tepi layar, piksel game (`ZonaAman`); nol bila belum diatur.
var _inset: ZonaAman.Inset = ZonaAman.Inset.new()

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
@onready var _strip_jeda: MarginContainer = %StripJeda
@onready var _tombol_jeda: TombolJeda = %TombolJeda
@onready var _strip_bel: MarginContainer = %StripBel
@onready var _tombol_bel: TombolBel = %TombolBel


func _ready() -> void:
	_panel_kecepatan.custom_minimum_size = Vector2(Config.HUD_PANEL_KECEPATAN_LEBAR_PX, 0)
	var celah: int = Config.HUD_PANEL_KORAN_GESER_PX - Config.HUD_PANEL_KECEPATAN_GESER_PX - Config.HUD_PANEL_KECEPATAN_LEBAR_PX
	_baris_bawah.add_theme_constant_override(&"separation", celah)
	_terapkan_gaya_dasar()
	_tombol_jeda.ditekan.connect(jeda_diminta.emit)
	tampilkan_kecepatan(Config.KECEPATAN_SANTAI_UD)
	tampilkan_stamina(Config.STAMINA_MAKS, false)
	tampilkan_koran(Config.KORAN_AWAL, Config.KORAN_AWAL)
	tampilkan_bel(false, 0.0)
	atur_kidal(false)


# --- Kait untuk pewaris (bawaan: tidak melakukan apa pun) ---

## Menampilkan skor, pengali combo untuk antaran berikutnya (`SkorRute.pengali_combo(beruntun)`), koin, dan label PUTUS.
func tampilkan_skor(_skor: int, _beruntun: int, _koin: int, _putus: bool) -> void:
	pass


## Menampilkan atau menyembunyikan panel skor (jalan uji menyembunyikannya).
func atur_skor_tampil(_nilai: bool) -> void:
	pass


## Menyamakan sakelar mode bantu di HUD (bila ada) dengan `nilai` tanpa memancarkan sinyal.
func atur_bantu(_nilai: bool) -> void:
	pass


# --- Bersama ---

## Memindahkan panel bawah dan tombol bel ke sisi tangan yang dipakai (tanpa memancarkan sinyal). Pewaris menambah bagiannya lewat `super`.
func atur_kidal(nilai: bool) -> void:
	_kidal = nilai
	_terapkan_tata_letak_dasar()


## True bila tata letak kidal terpasang.
func kidal() -> bool:
	return _kidal


## Mengatur inset aman tepi layar (piksel game, `ZonaAman.inset_game`) lalu menata ulang. Null = nol.
func atur_inset(inset: ZonaAman.Inset) -> void:
	_inset = inset if inset != null else ZonaAman.Inset.new()
	atur_kidal(_kidal)


## Inset aman yang terpasang.
func inset() -> ZonaAman.Inset:
	return _inset


## Geseran ke dalam elemen tepi x 0, tepi x lebar, atas, dan bawah (piksel game) dari inset terpasang (`ZonaAman.geser`).
func geser_awal_x() -> int:
	return ZonaAman.geser(Config.RADAR_TEPI_PX, _inset.awal_x)


func geser_akhir_x() -> int:
	return ZonaAman.geser(Config.RADAR_TEPI_PX, _inset.akhir_x)


func geser_atas() -> int:
	return ZonaAman.geser(Config.HUD_TOMBOL_MARGIN_ATAS_PX, _inset.atas)


func geser_bawah() -> int:
	return ZonaAman.geser(Config.HUD_MARGIN_TEPI_PX, _inset.bawah)


## Geseran pusat tombol dan zona tap bel karena zona aman, piksel game (untuk `TouchRouter.geser_bel`): ke dalam dari tepi sisi swipe dan
## ke atas dari tepi bawah.
func geser_bel() -> Vector2:
	var samping: int = geser_awal_x() if _kidal else -geser_akhir_x()
	return Vector2(samping, -geser_bawah())


## Frame tombol bel dari jari yang menahan tombol (`ditekan`) dan sisa jeda bel (`Bel.sisa_jeda_pecahan`).
func tampilkan_bel(ditekan: bool, pecahan_jeda: float) -> void:
	_tombol_bel.atur_frame(Bel.frame_tombol(ditekan, pecahan_jeda))


## Frame tombol bel yang digambar (untuk tes).
func frame_bel() -> int:
	return _tombol_bel.frame()


## Persegi tombol bel dalam koordinat viewport game.
func rect_tombol_bel() -> Rect2:
	return _tombol_bel.get_global_rect()


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


## Persegi area sentuh tombol jeda dalam koordinat viewport game.
func rect_tombol_jeda() -> Rect2:
	return _tombol_jeda.get_global_rect()


## Persegi panel kecepatan dalam koordinat viewport game.
func rect_panel_kecepatan() -> Rect2:
	return _panel_kecepatan.get_global_rect()


## Persegi panel sisa koran dalam koordinat viewport game.
func rect_panel_koran() -> Rect2:
	return _panel_koran.get_global_rect()


## Tata letak bersama dari mode tangan dan inset: tombol jeda, panel bawah, tombol bel.
func _terapkan_tata_letak_dasar() -> void:
	# Area sentuh jeda dipusatkan mendatar pada gambarnya; tepi atasnya sejajar tombol strip atas.
	var sisa: float = float(Config.HUD_JEDA_SENTUH_PX - Config.HUD_JEDA_GAMBAR_PX) / 2
	var tepi_jeda: int = Config.HUD_JEDA_GAMBAR_X_PX - floori(sisa)
	_strip_jeda.add_theme_constant_override(&"margin_left", tepi_jeda + geser_awal_x())
	_strip_jeda.add_theme_constant_override(&"margin_top", Config.HUD_TOMBOL_MARGIN_ATAS_PX + geser_atas())
	_tombol_jeda.geser_gambar = Vector2(Config.HUD_JEDA_GAMBAR_X_PX - tepi_jeda, Config.HUD_JEDA_GAMBAR_Y_PX - Config.HUD_TOMBOL_MARGIN_ATAS_PX)
	var geser: int = Config.HUD_PANEL_KECEPATAN_GESER_PX
	var tepi: int = Config.HUD_MARGIN_TEPI_PX
	_panel_bawah.add_theme_constant_override(&"margin_left", tepi if _kidal else geser)
	_panel_bawah.add_theme_constant_override(&"margin_right", geser if _kidal else tepi)
	_panel_bawah.add_theme_constant_override(&"margin_bottom", tepi + geser_bawah())
	_baris_bawah.size_flags_horizontal = Control.SIZE_SHRINK_END if _kidal else Control.SIZE_SHRINK_BEGIN
	_baris_bawah.move_child(_panel_koran, 0 if _kidal else -1)
	# Tombol bel: pojok bawah sisi swipe (StripBel lebar penuh di tepi bawah), pusat BEL_TOMBOL_PUSAT_TEPI_PX dari tepi samping dan bawah.
	var tepi_bel: int = Config.BEL_TOMBOL_PUSAT_TEPI_PX - floori(float(Config.BEL_TOMBOL_UKURAN_PX) / 2)
	_strip_bel.add_theme_constant_override(&"margin_left", tepi_bel + geser_awal_x() if _kidal else 0)
	_strip_bel.add_theme_constant_override(&"margin_right", 0 if _kidal else tepi_bel + geser_akhir_x())
	_strip_bel.add_theme_constant_override(&"margin_bottom", tepi_bel + geser_bawah())
	_tombol_bel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if _kidal else Control.SIZE_SHRINK_END


## Warna dan bentuk panel bawah dari `Palette` (DESIGN_SPEC 1.3).
func _terapkan_gaya_dasar() -> void:
	_panel_kecepatan.add_theme_stylebox_override(&"panel", GayaHud.kotak(Palette.HUD_PANEL, Palette.OUTLINE))
	_panel_koran.add_theme_stylebox_override(&"panel", GayaHud.kotak(Palette.HUD_PANEL, Palette.OUTLINE))
	_label_koran.add_theme_color_override(&"font_color", Palette.ACCENT)
	_label_habis.add_theme_color_override(&"font_color", Palette.FAIL)
	_angka_koran.add_theme_color_override(&"font_color", Palette.TEXT)
	_label_judul.add_theme_color_override(&"font_color", Palette.ACCENT)
	_label_angka.add_theme_color_override(&"font_color", Palette.TEXT)
	_label_stamina.add_theme_color_override(&"font_color", Palette.ACCENT)
	_label_lelah.add_theme_color_override(&"font_color", Palette.FAIL)
