class_name LayarHasil
extends CanvasLayer
## Layar hasil rute versi sketsa (DESIGN_SPEC 4 "Hasil harian" 🟡, rule `ui-scenes`; O-11, O-12, AC-12 run fase3c-hud-hasil, usulan).
##
## Layar penuh `UI_BG` dengan panel `UI_PANEL` di tengah, judul `HASIL_JUDUL` (Lilita One, `JudulLayar`), lalu angka dari `HasilRute.Angka`
## (satu sumber; layar ini tidak menghitung apa pun) urut dari yang berhasil: terkirim (n/25), tip, koin, skor, tepat; lalu meleset dan
## status tenggat dengan nada netral (`TEXT_2`, tanpa panel merah, tanpa kata "gagal", tanpa layar kalah; prinsip 2). Tombol `RUTE_MAIN_LAGI`
## (`TombolSentuh`, >= 42 px game) memancarkan `main_lagi_diminta`. Teks lewat kunci terjemahan; kolom nilai melar (autowrap) supaya teks
## Indonesia yang panjang tetap muat di 640, 780, dan 800.
## Latar menangkap sentuhan GUI (`MOUSE_FILTER_STOP`); HUD dan kontrol sentuh di bawahnya dimatikan adegan (`RuteMain`) selama layar ini
## tampil, karena keduanya membaca sentuhan lewat `_input`.

## Tombol "Main lagi" ditekan (mode rute sendiri, bawaan).
signal main_lagi_diminta
## Tombol "Hari berikutnya" ditekan (mode hari, `atur_mode_hari(true)`; run fase4a-koran-hari AC-17).
signal hari_berikutnya_diminta

## True bila tombol layar ini "Hari berikutnya" (di dalam alur hari), false bila "Main lagi" (rute dijalankan sendiri: probe, tes lama, dev).
var _mode_hari: bool = false

@onready var _latar: ColorRect = %LatarHasil
@onready var _panel: PanelContainer = %PanelHasil
@onready var _judul: Label = %JudulHasil
@onready var _isi: VBoxContainer = %IsiHasil
@onready var _daftar_berhasil: GridContainer = %DaftarBerhasil
@onready var _daftar_netral: GridContainer = %DaftarNetral
@onready var _nilai_terkirim: Label = %NilaiTerkirim
@onready var _nilai_tip: Label = %NilaiTip
@onready var _nilai_koin: Label = %NilaiKoin
@onready var _nilai_skor: Label = %NilaiSkor
@onready var _nilai_tepat: Label = %NilaiTepat
@onready var _nilai_meleset: Label = %NilaiMeleset
@onready var _teks_tenggat: Label = %TeksTenggat
@onready var _tombol: TombolSentuh = %TombolMainLagi


func _ready() -> void:
	_latar.color = Palette.UI_BG
	_latar.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_theme_stylebox_override(&"panel", GayaHud.kotak(Palette.UI_PANEL, Palette.OUTLINE))
	_panel.custom_minimum_size = Vector2(Config.HASIL_PANEL_LEBAR_PX, 0)
	_isi.add_theme_constant_override(&"separation", Config.HUD_PANEL_PAD_Y_PX)
	for daftar: GridContainer in [_daftar_berhasil, _daftar_netral]:
		daftar.add_theme_constant_override(&"v_separation", Config.HASIL_JARAK_BARIS_PX)
		daftar.add_theme_constant_override(&"h_separation", Config.HUD_PANEL_PAD_X_PX)
	_judul.add_theme_color_override(&"font_color", Palette.TEXT)
	for label: Node in _daftar_berhasil.get_children():
		(label as Label).add_theme_color_override(&"font_color", Palette.TEXT)
	for label: Node in _daftar_netral.get_children():
		(label as Label).add_theme_color_override(&"font_color", Palette.TEXT_2)
	_teks_tenggat.add_theme_color_override(&"font_color", Palette.TEXT_2)
	for nilai: Label in [_nilai_terkirim, _nilai_tip, _nilai_koin, _nilai_skor, _nilai_tepat]:
		nilai.add_theme_color_override(&"font_color", Palette.ACCENT)
	_tombol.custom_minimum_size = Vector2(Config.HUD_TOMBOL_LEBAR_PX, Config.HUD_TOMBOL_TINGGI_PX)
	GayaHud.terapkan_tombol(_tombol)
	_tombol.add_theme_stylebox_override(&"normal", GayaHud.kotak(Palette.UI_PANEL_RAISED, Palette.TEXT))
	_tombol.add_theme_stylebox_override(&"hover", GayaHud.kotak(Palette.UI_PANEL_RAISED, Palette.TEXT))
	_tombol.ditekan.connect(_saat_tombol)
	tampilkan(false)


## Mengganti tombol layar ini: true = "Hari berikutnya" (alur hari), false = "Main lagi" (bawaan).
func atur_mode_hari(nilai: bool) -> void:
	_mode_hari = nilai
	_tombol.text = "HASIL_HARI_BERIKUTNYA" if nilai else "RUTE_MAIN_LAGI"


## True bila tombol layar ini "Hari berikutnya".
func mode_hari() -> bool:
	return _mode_hari


func _saat_tombol() -> void:
	if _mode_hari:
		hari_berikutnya_diminta.emit()
	else:
		main_lagi_diminta.emit()


## Mengisi angka dari `angka` (`HasilRute.dari`). Tidak menghitung ulang apa pun.
func isi(angka: HasilRute.Angka) -> void:
	var pemisah: String = tr("HUD_PEMISAH_RIBUAN")
	_nilai_terkirim.text = tr("HASIL_TERKIRIM_ANGKA").format({"n": angka.terkirim, "total": angka.pelanggan})
	_nilai_tip.text = tr("HASIL_TIP_ANGKA").format({"koin": HasilRute.ribuan(angka.koin_tip, pemisah), "n": angka.jumlah_tip})
	_nilai_koin.text = tr("HASIL_KOIN_ANGKA").format({"n": HasilRute.ribuan(angka.koin, pemisah)})
	_nilai_skor.text = tr("HASIL_SKOR_ANGKA").format({"n": HasilRute.ribuan(angka.skor, pemisah)})
	_nilai_tepat.text = tr("HASIL_TEPAT_ANGKA").format({"n": angka.jumlah_tepat})
	_nilai_meleset.text = tr("HASIL_MELESET_ANGKA").format({"n": angka.meleset})
	if angka.tenggat_lewat:
		var md: Vector2i = TenggatRute.menit_detik(angka.detik_lewat)
		_teks_tenggat.text = tr("HASIL_TENGGAT_LEWAT").format({"m": md.x, "s": "%02d" % md.y})
	else:
		_teks_tenggat.text = tr("HASIL_TENGGAT_SEMPAT")


## Menampilkan atau menyembunyikan layar hasil.
func tampilkan(nilai: bool) -> void:
	visible = nilai


## True bila layar hasil sedang tampil.
func tampil() -> bool:
	return visible


## Teks yang tampil (sesudah terjemahan), urut dari atas (untuk tes): judul, lalu pasangan label dan nilai, lalu teks tenggat.
func teks_tampil() -> Array[String]:
	var hasil: Array[String] = [tr(_judul.text)]
	for daftar: GridContainer in [_daftar_berhasil, _daftar_netral]:
		for label: Node in daftar.get_children():
			hasil.append(tr((label as Label).text))
	hasil.append(tr(_teks_tenggat.text))
	return hasil


## Teks tombol "Main lagi" yang tampil (untuk tes).
func teks_tombol() -> String:
	return tr(_tombol.text)


## Tombol "Main lagi" (untuk tes: `ditekan.emit()`).
func tombol_main_lagi() -> TombolSentuh:
	return _tombol


## Persegi tombol "Main lagi" dan panel dalam koordinat viewport game.
func rect_tombol() -> Rect2:
	return _tombol.get_global_rect()


func rect_panel() -> Rect2:
	return _panel.get_global_rect()


## Persegi tiap label di panel (untuk tes tata letak: semuanya di dalam panel dan layar).
func rect_label() -> Array[Rect2]:
	var hasil: Array[Rect2] = [_judul.get_global_rect(), _teks_tenggat.get_global_rect()]
	for daftar: GridContainer in [_daftar_berhasil, _daftar_netral]:
		for label: Node in daftar.get_children():
			hasil.append((label as Label).get_global_rect())
	return hasil
