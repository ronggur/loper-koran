class_name HalamanKoran
extends CanvasLayer
## Layar halaman depan koran (DESIGN_SPEC 4 "Halaman depan koran" 🟡, GDD 10.1 dan 10.3, rule `ui-scenes`; AC-21 sampai AC-24 run
## fase4a-koran-hari, usulan): satu-satunya layar terang (kertas krem `KORAN_KERTAS`, tinta gelap `KORAN_TINTA`; kontras teks >= 7:1).
## Tipis: `HariMain` memberi `HeadlineManager.Halaman` (hasil pilihan headline), layar ini hanya menampilkannya dan memancarkan
## `ambil_diminta`, `lewati_diminta`, dan `berangkat_diminta`. Tidak memilih headline dan tidak menyimpan apa pun.
##
## Tata letak (anchor + Container, tanpa posisi piksel absolut; teks sampai 40 / 60 karakter melar lewat autowrap): dua kolom di dalam zona
## aman (`ZonaAman`, margin `KORAN_MARGIN_PX` atau inset perangkat bila lebih besar). Kiri: nama koran ("Warta Kring"), "Hari N · Perumahan
## Melati", berita utama (paling besar, Lilita One 24), berita ringan, dan satu baris notifikasi save rusak (hanya bila ada). Kanan: panel misi
## sampingan (headline, ringkasan satu baris, Ambil/Lewati, status pilihan) dan tombol Berangkat di zona jempol kanan. Tidak ada tombol jeda.
##
## Ambil/Lewati (S-7): awalnya tidak ada yang dipilih (sama dengan Lewati); bisa dibolak-balik sebelum Berangkat. Pilihan terbaca dari TEKS
## status (`KORAN_STATUS_*`) dan BENTUK (tombol terpilih terisi gelap dengan bingkai tebal, tombol lain hanya garis tipis), bukan warna saja.
## Tanpa misi memenuhi syarat (S-8) tombol Ambil/Lewati tidak tampil dan baris misi memuat teks netral `KORAN_TANPA_MISI`; headline lanjutan
## tanpa misi (misi_ditunda) tampil sebagai teks tanpa tombol. Berangkat selalu aktif.
## Semua teks lewat kunci terjemahan (data headline membawa KUNCI, diterjemahkan di sini); warna dari `Palette`; font dari `assets/ui/theme.tres`.

## Tombol Ambil ditekan.
signal ambil_diminta
## Tombol Lewati ditekan.
signal lewati_diminta
## Tombol Berangkat ditekan.
signal berangkat_diminta

## Pilihan misi di layar ini.
enum Pilihan { BELUM, AMBIL, LEWATI }

## Kunci nama distrik (satu kunci per nama, placeholder usulan).
const KUNCI_DISTRIK: Dictionary = {"perumahan": "KORAN_DISTRIK_PERUMAHAN"}

var _pilihan: Pilihan = Pilihan.BELUM
var _ada_misi: bool = false
var _inset: ZonaAman.Inset = ZonaAman.Inset.new()

@onready var _latar: ColorRect = %Latar
@onready var _batas: MarginContainer = %Batas
@onready var _isi: HBoxContainer = %Isi
@onready var _kiri: VBoxContainer = %Kiri
@onready var _kanan: VBoxContainer = %Kanan
@onready var _nama: Label = %NamaKoran
@onready var _hari: Label = %TeksHari
@onready var _garis_atas: ColorRect = %GarisAtas
@onready var _garis_tengah: ColorRect = %GarisTengah
@onready var _label_utama: Label = %LabelUtama
@onready var _teks_utama: Label = %TeksUtama
@onready var _label_ringan: Label = %LabelRingan
@onready var _teks_ringan: Label = %TeksRingan
@onready var _notifikasi: Label = %Notifikasi
@onready var _panel_misi: PanelContainer = %PanelMisi
@onready var _isi_misi: VBoxContainer = %IsiMisi
@onready var _label_misi: Label = %LabelMisi
@onready var _teks_misi: Label = %TeksMisi
@onready var _ringkasan: Label = %Ringkasan
@onready var _baris_pilih: HBoxContainer = %BarisPilih
@onready var _tombol_ambil: TombolSentuh = %TombolAmbil
@onready var _tombol_lewati: TombolSentuh = %TombolLewati
@onready var _status: Label = %StatusMisi
@onready var _tanpa_misi: Label = %TanpaMisi
@onready var _tombol_berangkat: TombolSentuh = %TombolBerangkat


func _ready() -> void:
	_latar.color = Palette.KORAN_KERTAS
	_isi.add_theme_constant_override(&"separation", Config.KORAN_JARAK_PX)
	for kolom: VBoxContainer in [_kiri, _kanan]:
		kolom.add_theme_constant_override(&"separation", Config.KORAN_JARAK_PX)
	_kiri.size_flags_stretch_ratio = Config.KORAN_KOLOM_KIRI_RASIO
	_kanan.size_flags_stretch_ratio = Config.KORAN_KOLOM_KANAN_RASIO
	_isi_misi.add_theme_constant_override(&"separation", Config.KORAN_JARAK_PX)
	_baris_pilih.add_theme_constant_override(&"separation", Config.HUD_TOMBOL_JARAK_PX)
	for garis: ColorRect in [_garis_atas, _garis_tengah]:
		garis.color = Palette.KORAN_GARIS
		garis.custom_minimum_size = Vector2(0, Config.KORAN_GARIS_TEBAL_PX)
	for label: Label in [_nama, _teks_utama, _teks_ringan, _teks_misi]:
		label.add_theme_color_override(&"font_color", Palette.KORAN_TINTA)
	for label: Label in [_hari, _label_utama, _label_ringan, _label_misi, _ringkasan, _status, _tanpa_misi, _notifikasi]:
		label.add_theme_color_override(&"font_color", Palette.KORAN_TINTA_2)
	_panel_misi.add_theme_stylebox_override(&"panel", _kotak(Palette.KORAN_KERTAS_2, Palette.KORAN_GARIS, Config.KORAN_GARIS_TEBAL_PX))
	for tombol: TombolSentuh in [_tombol_ambil, _tombol_lewati]:
		tombol.custom_minimum_size = Vector2(Config.KORAN_TOMBOL_PILIH_LEBAR_PX, Config.HUD_TOMBOL_TINGGI_PX)
		tombol.add_theme_font_size_override(&"font_size", Config.KORAN_TOMBOL_HURUF_PX)
	_tombol_berangkat.custom_minimum_size = Vector2(Config.KORAN_TOMBOL_BERANGKAT_LEBAR_PX, Config.HUD_TOMBOL_TINGGI_PX)
	_tombol_berangkat.add_theme_font_size_override(&"font_size", Config.KORAN_TOMBOL_HURUF_PX)
	_gaya_berangkat()
	_tombol_ambil.ditekan.connect(_saat_ambil)
	_tombol_lewati.ditekan.connect(_saat_lewati)
	_tombol_berangkat.ditekan.connect(berangkat_diminta.emit)
	get_viewport().size_changed.connect(_baca_zona_aman)
	_baca_zona_aman()
	_terapkan_margin()
	atur_pilihan(Pilihan.BELUM)
	tampilkan_notifikasi_rusak(false)


## Mengisi layar dari `halaman` (hasil `HeadlineManager.susun`) untuk hari `hari` di distrik `distrik`. Pilihan misi diatur ulang ke "belum dipilih".
func isi(halaman: HeadlineManager.Halaman, hari: int, distrik: String) -> void:
	var kunci_distrik: String = KUNCI_DISTRIK.get(distrik, "KORAN_DISTRIK_PERUMAHAN")
	_hari.text = tr("KORAN_HARI_DISTRIK").format({"n": hari, "distrik": tr(kunci_distrik)})
	_teks_utama.text = tr(halaman.utama.teks) if halaman.utama != null else ""
	_teks_ringan.text = tr(halaman.ringan.teks) if halaman.ringan != null else ""
	_label_utama.visible = halaman.utama != null
	_teks_utama.visible = halaman.utama != null
	_label_ringan.visible = halaman.ringan != null
	_teks_ringan.visible = halaman.ringan != null
	var misi: HeadlineManager.Entri = halaman.misi
	_teks_misi.visible = misi != null
	_teks_misi.text = tr(misi.teks) if misi != null else ""
	_ada_misi = misi != null and not misi.misi_id.is_empty()
	_ringkasan.visible = _ada_misi
	_ringkasan.text = tr(misi.ringkasan) if _ada_misi else ""
	_baris_pilih.visible = _ada_misi
	_status.visible = _ada_misi
	_tanpa_misi.visible = misi == null
	atur_pilihan(Pilihan.BELUM)


## Mengatur pilihan misi dan tampilannya (teks status dan bentuk tombol); tidak memancarkan sinyal.
func atur_pilihan(pilihan_baru: Pilihan) -> void:
	_pilihan = pilihan_baru
	_gaya_pilih(_tombol_ambil, _pilihan == Pilihan.AMBIL)
	_gaya_pilih(_tombol_lewati, _pilihan == Pilihan.LEWATI)
	match _pilihan:
		Pilihan.AMBIL:
			_status.text = tr("KORAN_STATUS_DIAMBIL")
		Pilihan.LEWATI:
			_status.text = tr("KORAN_STATUS_DILEWATI")
		_:
			_status.text = tr("KORAN_STATUS_BELUM")


## Pilihan misi saat ini.
func pilihan() -> Pilihan:
	return _pilihan


## True bila baris misi punya misi yang bisa diambil (tombol Ambil/Lewati tampil).
func ada_misi() -> bool:
	return _ada_misi


## Menampilkan atau menyembunyikan satu baris notifikasi save rusak (AC-9).
func tampilkan_notifikasi_rusak(nilai: bool) -> void:
	_notifikasi.visible = nilai


## Menampilkan atau menyembunyikan layar koran.
func tampilkan(nilai: bool) -> void:
	visible = nilai


## True bila layar koran sedang tampil.
func tampil() -> bool:
	return visible


## Mengatur inset aman tepi layar (piksel game, `ZonaAman.inset_game`) lalu menata margin. Null = nol.
func atur_inset(inset: ZonaAman.Inset) -> void:
	_inset = inset if inset != null else ZonaAman.Inset.new()
	_terapkan_margin()


# --- Untuk tes dan probe ---

## Teks yang tampil (sesudah terjemahan) urut dari atas: nama, hari, label dan teks utama, label dan teks ringan, notifikasi, label dan
## teks misi, ringkasan, tombol Ambil, tombol Lewati, status, teks tanpa misi, tombol Berangkat. Elemen yang disembunyikan ikut dicatat.
func teks_tampil() -> Array[String]:
	var hasil: Array[String] = []
	for label: Label in [_nama, _hari, _label_utama, _teks_utama, _label_ringan, _teks_ringan, _notifikasi, _label_misi, _teks_misi, _ringkasan, _status, _tanpa_misi]:
		hasil.append(tr(label.text))
	for tombol: Button in [_tombol_ambil, _tombol_lewati, _tombol_berangkat]:
		hasil.append(tr(tombol.text))
	return hasil


## Teks tombol Ambil, Lewati, dan Berangkat (sesudah terjemahan).
func teks_tombol() -> Array[String]:
	return [tr(_tombol_ambil.text), tr(_tombol_lewati.text), tr(_tombol_berangkat.text)]


## Teks status pilihan (sesudah terjemahan).
func teks_status() -> String:
	return tr(_status.text)


## Tombol Ambil, Lewati, Berangkat (untuk tes: `ditekan.emit()`).
func tombol_ambil() -> TombolSentuh:
	return _tombol_ambil


func tombol_lewati() -> TombolSentuh:
	return _tombol_lewati


func tombol_berangkat() -> TombolSentuh:
	return _tombol_berangkat


## Gaya tombol (bingkai dan isi) saat ini, untuk tes bentuk: ketebalan bingkai dan warna isi gaya `normal`.
func gaya_tombol(tombol: TombolSentuh) -> StyleBoxFlat:
	return tombol.get_theme_stylebox(&"normal") as StyleBoxFlat


## Persegi kontrol dalam koordinat viewport game.
func rect_tombol_ambil() -> Rect2:
	return _tombol_ambil.get_global_rect()


func rect_tombol_lewati() -> Rect2:
	return _tombol_lewati.get_global_rect()


func rect_tombol_berangkat() -> Rect2:
	return _tombol_berangkat.get_global_rect()


func rect_panel_misi() -> Rect2:
	return _panel_misi.get_global_rect()


## Persegi tiap label yang tampil (untuk tes tumpang tindih dan zona aman).
func rect_label_tampil() -> Array[Rect2]:
	var hasil: Array[Rect2] = []
	for label: Label in _semua_label():
		if label.is_visible_in_tree():
			hasil.append(label.get_global_rect())
	return hasil


## Label yang tampil beserta tinggi teks yang dibutuhkan font (setelah autowrap) dan tinggi yang tersedia (untuk tes teks tidak terpotong).
func ukur_label() -> Array[Dictionary]:
	var hasil: Array[Dictionary] = []
	for label: Label in _semua_label():
		if not label.is_visible_in_tree():
			continue
		hasil.append({"nama": label.name, "teks": label.text, "dibutuhkan": label.get_minimum_size().y, "tersedia": label.size.y, "garis": label.get_line_count(), "terlihat": label.get_visible_line_count()})
	return hasil


## Persegi area isi (di dalam margin aman) dalam koordinat viewport game.
func rect_isi() -> Rect2:
	return _isi.get_global_rect()


func _semua_label() -> Array[Label]:
	return [_nama, _hari, _label_utama, _teks_utama, _label_ringan, _teks_ringan, _notifikasi, _label_misi, _teks_misi, _ringkasan, _status, _tanpa_misi]


# --- Internal ---

func _saat_ambil() -> void:
	atur_pilihan(Pilihan.AMBIL)
	ambil_diminta.emit()


func _saat_lewati() -> void:
	atur_pilihan(Pilihan.LEWATI)
	lewati_diminta.emit()


## Margin kertas: max(`KORAN_MARGIN_PX`, inset aman) tiap tepi (`ZonaAman.margin`).
func _terapkan_margin() -> void:
	if _batas == null:
		return
	_batas.add_theme_constant_override(&"margin_left", ZonaAman.margin(Config.KORAN_MARGIN_PX, _inset.awal_x))
	_batas.add_theme_constant_override(&"margin_right", ZonaAman.margin(Config.KORAN_MARGIN_PX, _inset.akhir_x))
	_batas.add_theme_constant_override(&"margin_top", ZonaAman.margin(Config.KORAN_MARGIN_PX, _inset.atas))
	_batas.add_theme_constant_override(&"margin_bottom", ZonaAman.margin(Config.KORAN_MARGIN_PX, _inset.bawah))


## Inset aman perangkat mobile; desktop dan headless: tidak mengubah inset (sama dengan `HudRute`).
func _baca_zona_aman() -> void:
	if not OS.has_feature("mobile"):
		return
	var aman: Rect2i = DisplayServer.get_display_safe_area()
	atur_inset(ZonaAman.inset_game(aman, DisplayServer.window_get_size(), get_viewport().get_visible_rect().size))


## Kotak bergaris `lebar` px (tanpa anti-alias, sudut tegas) dengan padding yang sama dengan panel HUD.
func _kotak(isi_warna: Color, garis: Color, lebar: int) -> StyleBoxFlat:
	var kotak: StyleBoxFlat = GayaHud.kotak(isi_warna, garis)
	kotak.set_border_width_all(lebar)
	return kotak


## Bentuk tombol pilihan: terpilih = terisi `KORAN_TINTA` dengan bingkai tebal dan teks kertas; tidak terpilih = hanya garis tipis di atas
## kertas kedua dengan teks tinta. Bentuk ini (bukan hanya warna) ditambah teks status membedakan pilihan.
func _gaya_pilih(tombol: TombolSentuh, terpilih: bool) -> void:
	var isi_warna: Color = Palette.KORAN_TINTA if terpilih else Palette.KORAN_KERTAS_2
	var tebal: int = Config.KORAN_BINGKAI_TERPILIH_PX if terpilih else 1
	var teks: Color = Palette.KORAN_KERTAS if terpilih else Palette.KORAN_TINTA
	var normal: StyleBoxFlat = _kotak(isi_warna, Palette.KORAN_GARIS, tebal)
	var ditekan: StyleBoxFlat = _kotak(Palette.KORAN_TINTA_2, Palette.KORAN_GARIS, Config.KORAN_BINGKAI_TERPILIH_PX)
	for nama: StringName in [&"normal", &"hover", &"focus"]:
		tombol.add_theme_stylebox_override(nama, normal)
	for nama: StringName in [&"pressed", &"hover_pressed"]:
		tombol.add_theme_stylebox_override(nama, ditekan)
	for nama: StringName in [&"font_color", &"font_hover_color", &"font_focus_color", &"font_pressed_color", &"font_hover_pressed_color"]:
		tombol.add_theme_color_override(nama, Palette.KORAN_KERTAS if String(nama).contains("pressed") else teks)


## Berangkat: tombol utama selalu terisi tinta dengan bingkai tebal.
func _gaya_berangkat() -> void:
	var normal: StyleBoxFlat = _kotak(Palette.KORAN_TINTA, Palette.KORAN_GARIS, Config.KORAN_BINGKAI_TERPILIH_PX)
	var ditekan: StyleBoxFlat = _kotak(Palette.KORAN_TINTA_2, Palette.KORAN_GARIS, Config.KORAN_BINGKAI_TERPILIH_PX)
	for nama: StringName in [&"normal", &"hover", &"focus"]:
		_tombol_berangkat.add_theme_stylebox_override(nama, normal)
	for nama: StringName in [&"pressed", &"hover_pressed"]:
		_tombol_berangkat.add_theme_stylebox_override(nama, ditekan)
	for nama: StringName in [&"font_color", &"font_hover_color", &"font_focus_color", &"font_pressed_color", &"font_hover_pressed_color"]:
		_tombol_berangkat.add_theme_color_override(nama, Palette.KORAN_KERTAS)
