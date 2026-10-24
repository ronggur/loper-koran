class_name LayarHasil
extends CanvasLayer
## Layar hasil rute sebagai struk antaran (DESIGN_SPEC 4 "Hasil harian", rule `ui-scenes`; AC-2, AC-10, AC-11 run ui2-semua-layar bagian A; kanvas Hasil.dc.html dan Hasil_*.dc.html, README redesain 3 butir 6, usulan;
## dinilai di HP). Isi, angka, teks, sinyal, dan API sama dengan versi sebelumnya (run fase3c-hud-hasil, fase4b, fase6a1, fase6a2): `HasilRute.Angka` tetap satu-satunya sumber angka (layar ini tidak menghitung apa
## pun), teks hanya lewat kunci terjemahan, nada netral (`TEXT_2`, tanpa panel merah, tanpa kata "gagal", tanpa layar kalah; prinsip 2).
##
## Tampilan: judul `HASIL_JUDUL` (Lilita One 24) di kiri atas; STRUK (`GayaHud.struk`, tepi atas dan bawah bergerigi) berisi angka "Terkirim" (n/total, glif centang: hijau bila semua terantar) dan "Koin" (ikon koin)
## 32 px, garis sobek bertakik, lalu baris berhasil (Tip, Skor, Tepat) dan rekap misi selesai, garis sobek, baris netral (Meleset, Koran terbuang, Koin bersih), teks saldo dijepit, tenggat, rekap misi gagal, dan
## baris kondisi sepeda (glif "!" `WARN` + teks `TEXT`: WARN di atas isi struk hanya 6,91:1, di bawah 7:1). KOLOM SAMPING (236, 300 di lebar 800; hanya bila ada hasil reputasi atau ringkasan milestone, selain itu struk 360 ke tengah): kartu reputasi (bintang, angka, chip
## perubahan dengan glif naik/turun), kartu pelanggan (hanya jenis bukan nol), kartu target (lencana 32, nama dan tingkat, bilah + n/target, atau teks tamat), dan tingkat baru tercapai (ikon lencana 24 + teks, paling
## banyak `MILESTONE_BARU_MAKS_TAMPIL`). Tombol aksi utama 140x42 di kanan bawah ("Ke bengkel" di alur hari, "Main lagi" di rute sendiri; `BENGKEL_BUKA` dan `RUTE_MAIN_LAGI`, peran utama). Tata letak dari
## `TampilHasil.tata` (murni): anchor + Container, margin = max(12, inset aman), lentur 640 sampai 800. Teks panjang berbungkus kata (Indonesia sering lebih panjang), tidak pernah terpotong.
##
## Run ui2-semua-layar bagian E (V-10, permintaan pemilik 2026-10-24, usulan): di atas dunia rute (`atur_dunia(true)`, diatur `RuteMain`) latar adalah lapisan gelap `UI_BG` tembus pandang (`HASIL_LATAR_ALPHA`) sehingga jalan, rumah, dan sepeda yang baru dilalui
## terlihat redup, dan struk dan kartu kolom samping transparan sebagian (`HASIL_PANEL_ALPHA`, digelapkan `HASIL_PANEL_GELAP`, lewat `StyleBoxTexture.modulate_color`) dengan kontras teks >= 7:1 terukur di atas latar terburuk. Baris tingkat baru tercapai kini di dalam kartu
## target (tanpa kartu, teks hijau di atas dunia hanya 3,5:1). Tanpa dunia (bawaan: layar hasil sendiri, tes, probe) latar gelap polos buram dan panel buram seperti sebelumnya.
##
## Latar menangkap sentuhan GUI (`MOUSE_FILTER_STOP`); HUD dan kontrol sentuh di bawahnya dimatikan adegan (`RuteMain`) selama layar ini tampil, karena keduanya membaca sentuhan lewat `_input`.
## Run fase6a1-bengkel-kondisi bagian B (AC-24): bila ada komponen sepeda PERLU_BENGKEL, satu baris per komponen (sampai tiga, `KONDISI_HASIL_PERLU`, `WARN`); tombol "Ke bengkel" memancarkan `bengkel_diminta`.
## Run fase6a2-reputasi-pelanggan (AC-11 sampai AC-14): baris "Koran terbuang n koran (-potongan)" dan "Koin bersih" (boleh minus) hanya bila ada koran terbuang; baris "Saldo mulai lagi dari 0" hanya bila saldo save
## benar-benar dijepit 0 (`isi` diberi `saldo_lama`, -1 = tidak diketahui); koin tetap koin kotor.

## Tombol "Main lagi" ditekan (mode rute sendiri, bawaan).
signal main_lagi_diminta
## Tombol "Ke bengkel" ditekan (mode hari, `atur_mode_hari(true)`; run fase4a-koran-hari AC-17, run fase6a1-bengkel-kondisi AC-24: dulu "Hari berikutnya").
signal bengkel_diminta

## Lencana target 32x32 (indeks 0 = perunggu) dan ikon lencana 24x24 tingkat baru (indeks 0 = perunggu), dimuat saat kompilasi (bukan di `_draw`).
const LENCANA: Array[Texture2D] = [
	preload("res://assets/sprites/ui/ui_lencana32_perunggu.png"),
	preload("res://assets/sprites/ui/ui_lencana32_perak.png"),
	preload("res://assets/sprites/ui/ui_lencana32_emas.png"),
]
const LENCANA_BARU: Array[Texture2D] = [
	preload("res://assets/sprites/ui/ui_icon24_lencana_perunggu.png"),
	preload("res://assets/sprites/ui/ui_icon24_lencana_perak.png"),
	preload("res://assets/sprites/ui/ui_icon24_lencana_emas.png"),
]


## Nama simpul tiga baris kondisi (dicari tes lewat `find_child`).
const NAMA_KONDISI: Array[String] = ["KondisiSatu", "KondisiDua", "KondisiTiga"]


## Satu baris struk: label, garis titik-titik, nilai.
class BarisStruk extends RefCounted:
	var baris: HBoxContainer = null
	var label: Label = null
	var nilai: Label = null

	func tampil(nilai_tampil: bool) -> void:
		baris.visible = nilai_tampil


## True bila tombol layar ini "Ke bengkel" (di dalam alur hari), false bila "Main lagi" (rute dijalankan sendiri: probe, tes lama, dev).
var _mode_hari: bool = false
## True bila layar ini di atas dunia rute (diatur `RuteMain`): lapisan gelap tembus pandang dan struk dan kartu transparan sebagian (V-10). Bawaan false: latar gelap polos dan panel buram (layar hasil sendiri).
var _ada_dunia: bool = false
## Kotak 9-slice struk dan kartu kolom samping yang alphanya mengikuti `_ada_dunia`.
var _kotak_panel: Array[StyleBoxTexture] = []
var _inset: ZonaAman.Inset = ZonaAman.Inset.new()
var _tata: TampilHasil.Tata = null
## Teks reputasi "12 (+2)" yang tersimpan untuk tes (layar menampilkan angka dan chip terpisah).
var _teks_reputasi: String = ""
var _baris_tip: BarisStruk = null
var _baris_skor: BarisStruk = null
var _baris_tepat: BarisStruk = null
var _baris_meleset: BarisStruk = null
var _baris_terbuang: BarisStruk = null
var _baris_bersih: BarisStruk = null
## Baris kondisi (dibuat di `_ready`): glif dan teks.
var _baris_kondisi: Array[HBoxContainer] = []
var _teks_kondisi: Array[Label] = []
## Baris tingkat baru tercapai (dibuat di `_ready`): ikon lencana dan teks.
var _baris_baru: Array[HBoxContainer] = []
var _ikon_baru: Array[TextureRect] = []
var _teks_baru: Array[Label] = []
var _label_pelanggan: Array[Label] = []
var _nilai_pelanggan: Array[Label] = []
## Jarak atas kolom samping yang sedang dipakai (`TampilHasil.Tata.kolom_atas`).
var _kolom_atas_dipakai: int = 0
var _susun_antri: bool = false
var _susun_frame: int = -1
var _susun_hitung: int = 0

@onready var _latar: ColorRect = %LatarHasil
@onready var _batas: MarginContainer = %Batas
@onready var _badan: HBoxContainer = %Badan
@onready var _kolom_kiri: VBoxContainer = %KolomKiri
@onready var _judul: Label = %JudulHasil
@onready var _panel: PanelContainer = %PanelStruk
@onready var _isi: VBoxContainer = %IsiStruk
@onready var _baris_angka: HBoxContainer = %BarisAngka
@onready var _label_terkirim: Label = %LabelTerkirim
@onready var _nilai_terkirim: Label = %NilaiTerkirim
@onready var _glif_terkirim: TextureRect = %GlifTerkirim
@onready var _label_koin: Label = %LabelKoin
@onready var _ikon_koin: TextureRect = %IkonKoin
@onready var _nilai_koin: Label = %NilaiKoin
@onready var _sobek_atas: GarisSobek = %SobekAtas
@onready var _sobek_bawah: GarisSobek = %SobekBawah
@onready var _daftar_berhasil: VBoxContainer = %DaftarBerhasil
@onready var _daftar_netral: VBoxContainer = %DaftarNetral
@onready var _baris_misi: HBoxContainer = %BarisMisi
@onready var _glif_misi: TextureRect = %GlifMisi
@onready var _rekap_misi: Label = %RekapMisi
@onready var _teks_saldo_nol: Label = %TeksSaldoNol
@onready var _teks_tenggat: Label = %TeksTenggat
@onready var _kondisi: VBoxContainer = %KondisiHasil
@onready var _tombol: TombolSentuh = %TombolMainLagi
@onready var _kolom_kanan: VBoxContainer = %KolomKanan
@onready var _jarak_kolom: Control = %JarakAtasKolom
@onready var _kartu_reputasi: PanelContainer = %KartuReputasi
@onready var _ikon_reputasi: TextureRect = %IkonReputasiHasil
@onready var _label_reputasi: Label = %LabelReputasi
@onready var _angka_reputasi: Label = %AngkaReputasi
@onready var _chip_reputasi: ChipUi = %ChipReputasi
@onready var _pembungkus_chip: MarginContainer = %PembungkusChip
@onready var _kartu_pelanggan: PanelContainer = %KartuPelanggan
@onready var _judul_pelanggan: Label = %JudulPelanggan
@onready var _daftar_pelanggan: GridContainer = %DaftarPelanggan
@onready var _kartu_target: PanelContainer = %KartuTarget
@onready var _judul_target: Label = %JudulTarget
@onready var _baris_target: HBoxContainer = %BarisTarget
@onready var _ikon_target: TextureRect = %IkonTarget
@onready var _nama_target: Label = %NamaTarget
@onready var _baris_bilah: HBoxContainer = %BarisBilah
@onready var _bilah_target: BilahMilestone = %BilahTarget
@onready var _angka_target: Label = %AngkaTarget
@onready var _teks_tamat: Label = %TeksTamat
@onready var _bagian_baru: VBoxContainer = %BagianBaru


func _ready() -> void:
	_latar.mouse_filter = Control.MOUSE_FILTER_STOP
	_judul.add_theme_color_override(&"font_color", Palette.TEXT)
	_judul.custom_minimum_size = Vector2(0, Config.HASIL_BARIS_ATAS_PX)
	_badan.add_theme_constant_override(&"separation", Config.HASIL_STRUK_KOLOM_JARAK_PX)
	_kolom_kiri.add_theme_constant_override(&"separation", 0)
	for blok: Node in [_label_terkirim.get_parent(), _label_koin.get_parent()]:
		(blok as VBoxContainer).add_theme_constant_override(&"separation", 0)
	var kotak_struk: StyleBoxTexture = GayaHud.struk()
	_kotak_panel.append(kotak_struk)
	_panel.add_theme_stylebox_override(&"panel", kotak_struk)
	_isi.add_theme_constant_override(&"separation", Config.HASIL_STRUK_JARAK_PX)
	_baris_angka.add_theme_constant_override(&"separation", Config.HASIL_ANGKA_JARAK_PX)
	_sobek_atas.atur_pad(Config.HASIL_STRUK_PAD_X_PX, Config.HASIL_STRUK_PAD_X_PX)
	_sobek_bawah.atur_pad(Config.HASIL_STRUK_PAD_X_PX, Config.HASIL_STRUK_PAD_X_PX)
	for label: Label in [_label_terkirim, _label_koin]:
		label.add_theme_color_override(&"font_color", Palette.TEXT_2)
	_nilai_terkirim.add_theme_color_override(&"font_color", Palette.TEXT)
	_nilai_koin.add_theme_color_override(&"font_color", Palette.ACCENT)
	_ikon_koin.texture = GayaHud.tekstur("icon24_koin")
	_glif_misi.texture = GayaHud.tekstur("glif_centang_ok")
	_baris_tip = _bangun_baris(_daftar_berhasil, "HASIL_TIP", &"LayarTeksUtama", Palette.TEXT, Palette.OK)
	_baris_skor = _bangun_baris(_daftar_berhasil, "HASIL_SKOR", &"LayarTeksUtama", Palette.TEXT, Palette.TEXT)
	_baris_tepat = _bangun_baris(_daftar_berhasil, "HASIL_TEPAT", &"LayarTeksUtama", Palette.TEXT, Palette.ACCENT)
	_baris_meleset = _bangun_baris(_daftar_netral, "HASIL_MELESET", &"LayarTeksKecil", Palette.TEXT_2, Palette.TEXT_2)
	_baris_terbuang = _bangun_baris(_daftar_netral, "HASIL_TERBUANG", &"LayarTeksKecil", Palette.TEXT_2, Palette.TEXT_2)
	_baris_bersih = _bangun_baris(_daftar_netral, "HASIL_KOIN_BERSIH", &"LayarTeksKecil", Palette.TEXT_2, Palette.TEXT)
	for daftar: VBoxContainer in [_daftar_berhasil, _daftar_netral]:
		daftar.add_theme_constant_override(&"separation", Config.HASIL_STRUK_JARAK_PX)
	_teks_saldo_nol.add_theme_color_override(&"font_color", Palette.TEXT_2)
	_teks_tenggat.add_theme_color_override(&"font_color", Palette.TEXT_2)
	_baris_misi.add_theme_constant_override(&"separation", Config.UI_CHIP_JARAK_PX)
	_kondisi.add_theme_constant_override(&"separation", Config.HASIL_STRUK_JARAK_PX)
	for i: int in range(Config.KONDISI_KOMPONEN.size()):
		var baris: HBoxContainer = _baris_dengan_glif("glif_seru_warn")
		var teks: Label = _label(&"LayarTeksKecil", Palette.TEXT)
		teks.name = NAMA_KONDISI[i]
		teks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		baris.add_child(teks)
		baris.visible = false
		_kondisi.add_child(baris)
		_baris_kondisi.append(baris)
		_teks_kondisi.append(teks)
	_terapkan_gaya_kanan()
	GayaHud.tombol_utama(_tombol)
	_tombol.custom_minimum_size = Vector2(Config.UI_TOMBOL_LEBAR_UTAMA_PX, Config.UI_TOMBOL_TINGGI_PX)
	_tombol.ditekan.connect(_saat_tombol)
	get_viewport().size_changed.connect(_baca_zona_aman)
	_panel.resized.connect(_ukuran_berubah)
	_kolom_kanan.resized.connect(_ukuran_berubah)
	_terapkan_dunia()
	_baca_zona_aman()
	tampilkan(false)


## Gaya dan simpul kolom samping: kartu 9-slice, label bagian, ikon, chip, baris pelanggan, dan baris tingkat baru tercapai.
func _terapkan_gaya_kanan() -> void:
	_kolom_kanan.add_theme_constant_override(&"separation", Config.HASIL_KARTU_JARAK_PX)
	_jarak_kolom.custom_minimum_size = Vector2(0, Config.HASIL_KOLOM_ATAS_PX)
	for kartu: PanelContainer in [_kartu_reputasi, _kartu_pelanggan, _kartu_target]:
		var kotak: StyleBoxTexture = GayaHud.kartu_biasa()
		kotak.set_content_margin_all(float(Config.UI_PANEL_SLICE_PX + Config.HASIL_KARTU_PAD_PX))
		kartu.add_theme_stylebox_override(&"panel", kotak)
		_kotak_panel.append(kotak)
	_kartu_reputasi.custom_minimum_size = Vector2(0, Config.HASIL_KARTU_REPUTASI_PX)
	for bagian: Control in [_kartu_pelanggan.get_child(0), _kartu_target.get_child(0)]:
		(bagian as VBoxContainer).add_theme_constant_override(&"separation", Config.HASIL_KARTU_BARIS_JARAK_PX)
	_daftar_pelanggan.add_theme_constant_override(&"v_separation", Config.HASIL_KARTU_BARIS_JARAK_PX)
	_daftar_pelanggan.add_theme_constant_override(&"h_separation", Config.UI_CHIP_JARAK_BESAR_PX)
	_bagian_baru.add_theme_constant_override(&"separation", Config.HASIL_BARU_JARAK_PX)
	_baris_target.add_theme_constant_override(&"separation", Config.UI_CHIP_JARAK_BESAR_PX)
	_baris_bilah.add_theme_constant_override(&"separation", Config.UI_CHIP_JARAK_BESAR_PX)
	_ikon_reputasi.texture = GayaHud.tekstur("icon24_bintang")
	_ikon_reputasi.custom_minimum_size = Vector2(Config.HASIL_IKON_BESAR_PX, Config.HASIL_IKON_BESAR_PX)
	_ikon_target.custom_minimum_size = Vector2(Config.HASIL_LENCANA_TARGET_PX, Config.HASIL_LENCANA_TARGET_PX)
	(_nama_target.get_parent() as VBoxContainer).add_theme_constant_override(&"separation", Config.HASIL_KARTU_BARIS_JARAK_PX)
	for label: Label in [_label_reputasi, _judul_pelanggan, _judul_target]:
		label.add_theme_color_override(&"font_color", Palette.TEXT_2)
	_angka_reputasi.add_theme_color_override(&"font_color", Palette.TEXT)
	_nama_target.add_theme_color_override(&"font_color", Palette.TEXT)
	_angka_target.add_theme_color_override(&"font_color", Palette.TEXT)
	_teks_tamat.add_theme_color_override(&"font_color", Palette.TEXT_2)
	for kunci: String in ["HASIL_PELANGGAN_BARU", "HASIL_PELANGGAN_SETIA", "HASIL_PELANGGAN_BERHENTI", "HASIL_PELANGGAN_KEMBALI"]:
		var label_jenis: Label = _label(&"LayarTeksKecil", Palette.TEXT_2)
		label_jenis.text = kunci
		label_jenis.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label_jenis.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var nilai_jenis: Label = _label(&"LayarTeksKecil", Palette.TEXT)
		nilai_jenis.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_daftar_pelanggan.add_child(label_jenis)
		_daftar_pelanggan.add_child(nilai_jenis)
		_label_pelanggan.append(label_jenis)
		_nilai_pelanggan.append(nilai_jenis)
	for i: int in range(Config.MILESTONE_BARU_MAKS_TAMPIL):
		var baris: HBoxContainer = HBoxContainer.new()
		baris.mouse_filter = Control.MOUSE_FILTER_IGNORE
		baris.add_theme_constant_override(&"separation", Config.UI_CHIP_JARAK_BESAR_PX)
		baris.visible = false
		var ikon: TextureRect = TextureRect.new()
		ikon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ikon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		ikon.custom_minimum_size = Vector2(Config.HASIL_IKON_BESAR_PX, Config.HASIL_IKON_BESAR_PX)
		ikon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ikon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var teks: Label = _label(&"LayarTeksKecil", Palette.OK)
		teks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		teks.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		teks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		baris.add_child(ikon)
		baris.add_child(teks)
		_bagian_baru.add_child(baris)
		_baris_baru.append(baris)
		_ikon_baru.append(ikon)
		_teks_baru.append(teks)


## Satu baris struk (label, garis titik-titik, nilai) di `induk`; `varian` font, warna label dan nilai dari Palette.
func _bangun_baris(induk: VBoxContainer, kunci_label: String, varian: StringName, warna_label: Color, warna_nilai: Color) -> BarisStruk:
	var hasil: BarisStruk = BarisStruk.new()
	hasil.baris = HBoxContainer.new()
	hasil.baris.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hasil.baris.add_theme_constant_override(&"separation", Config.UI_CHIP_JARAK_BESAR_PX)
	hasil.label = _label(varian, warna_label)
	hasil.label.text = kunci_label
	hasil.label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	hasil.nilai = _label(&"LayarTeksUtama", warna_nilai)
	hasil.nilai.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hasil.nilai.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	hasil.baris.add_child(hasil.label)
	hasil.baris.add_child(GarisTitik.new())
	hasil.baris.add_child(hasil.nilai)
	induk.add_child(hasil.baris)
	_ratakan_baseline(hasil.label, hasil.nilai)
	return hasil


## Ascent font `label` (piksel game) menurut tema dan ukuran fontnya sekarang.
func _ascent(label: Label) -> float:
	return label.get_theme_font(&"font").get_ascent(label.get_theme_font_size(&"font_size"))


## Meratakan baseline dua label yang rata atas dalam satu baris (revisi UI pemilik R-2): yang ascent-nya lebih kecil diturunkan lewat margin atas gaya `normal` (`TampilHasil.turun_baseline`). Dipanggil sesudah
## kedua label ada di pohon (tema sudah terpecahkan) dan sesudah variasi font masing-masing diatur.
func _ratakan_baseline(a: Label, b: Label) -> void:
	var turun: Vector2i = TampilHasil.turun_baseline(_ascent(a), _ascent(b))
	_geser_atas(a, turun.x)
	_geser_atas(b, turun.y)


func _geser_atas(label: Label, piksel: int) -> void:
	var kotak: StyleBoxEmpty = StyleBoxEmpty.new()
	kotak.content_margin_top = float(piksel)
	label.add_theme_stylebox_override(&"normal", kotak)


## Baris reputasi (R-5, menggantikan perataan garis dasar R-2 untuk baris ini): pusat vertikal tinta label "Reputasi", pusat tinta angka reputasi, dan pusat kotak chip perubahan ("+2") sama (satu garis tengah dengan
## ikon bintang); yang pusatnya lebih tinggi diturunkan lewat margin atas (`TampilHasil.turun_pusat`; chip lewat `PembungkusChip`). Dipanggil lagi tiap `atur` chip.
func _ratakan_reputasi() -> void:
	var tinggi_chip: float = float(KomponenUi.tinggi_chip(_chip_reputasi.ukuran()))
	var pusat: Array[float] = [
		TampilHasil.pusat_tinta(_ascent(_label_reputasi), float(Config.HASIL_REPUTASI_TINTA_LABEL_PX)),
		TampilHasil.pusat_tinta(_ascent(_angka_reputasi), float(Config.HASIL_REPUTASI_TINTA_ANGKA_PX)),
		tinggi_chip / 2,
	]
	var turun: Array[int] = TampilHasil.turun_pusat(pusat)
	_geser_atas(_label_reputasi, turun[0])
	_geser_atas(_angka_reputasi, turun[1])
	_pembungkus_chip.add_theme_constant_override(&"margin_top", turun[2])


## Garis dasar (koordinat viewport game) teks pertama `label` yang rata atas: tepi atas + margin atas gaya `normal` + ascent font. Untuk tes dan probe.
func baseline_label(label: Label) -> float:
	var margin: float = label.get_theme_stylebox(&"normal").get_margin(SIDE_TOP)
	return label.get_global_rect().position.y + margin + _ascent(label)


## Persegi angka dan label reputasi (untuk probe pengukur piksel R-5).
func rect_angka_reputasi() -> Rect2:
	return _angka_reputasi.get_global_rect()


func rect_label_reputasi() -> Rect2:
	return _label_reputasi.get_global_rect()


## Pusat vertikal (koordinat viewport game) tinta label, tinta angka, dan kotak chip baris reputasi (untuk tes dan probe): `Vector3(label, angka, chip)`. Ketiganya harus sama (selisih paling besar 0,5 px karena tinggi tinta ganjil lawan tinggi chip genap).
func pusat_reputasi() -> Vector3:
	var label: float = baseline_label(_label_reputasi) - float(Config.HASIL_REPUTASI_TINTA_LABEL_PX) / 2
	var angka: float = baseline_label(_angka_reputasi) - float(Config.HASIL_REPUTASI_TINTA_ANGKA_PX) / 2
	return Vector3(label, angka, _chip_reputasi.get_global_rect().get_center().y)


## Pasangan (label, nilai) tiap baris struk yang tampil, urut: Tip, Skor, Tepat, Meleset, Koran terbuang, Koin bersih (untuk tes perataan label-nilai).
func pasangan_baris() -> Array[Dictionary]:
	var hasil: Array[Dictionary] = []
	for baris: BarisStruk in [_baris_tip, _baris_skor, _baris_tepat, _baris_meleset, _baris_terbuang, _baris_bersih]:
		if baris.baris.visible:
			hasil.append({"label": baris.label, "nilai": baris.nilai})
	return hasil


## Pasangan (label, nilai) baris jenis pelanggan yang tampil di kartu pelanggan, urut (untuk tes perataan kolom samping).
func pasangan_pelanggan() -> Array[Dictionary]:
	var hasil: Array[Dictionary] = []
	for i: int in range(_label_pelanggan.size()):
		if _label_pelanggan[i].visible and _kartu_pelanggan.visible:
			hasil.append({"label": _label_pelanggan[i], "nilai": _nilai_pelanggan[i]})
	return hasil


## Tepi kanan (koordinat viewport game) tiap nilai kolom samping yang tampil, urut: chip perubahan reputasi, nilai baris pelanggan, nama target, dan angka target. Semuanya harus sama (tepi kanan isi kartu).
func tepi_kanan_samping() -> Array[float]:
	var hasil: Array[float] = []
	if not _kolom_kanan.visible:
		return hasil
	if _kartu_reputasi.visible:
		hasil.append(_chip_reputasi.get_global_rect().end.x)
	for pasangan: Dictionary in pasangan_pelanggan():
		hasil.append((pasangan["nilai"] as Label).get_global_rect().end.x)
	if _kartu_target.visible and not _teks_tamat.visible:
		hasil.append(_nama_target.get_global_rect().end.x)
		hasil.append(_angka_target.get_global_rect().end.x)
	return hasil


## Baris berisi satu glif 12 (nama dasar tekstur) di depan; teks ditambahkan pemanggil.
func _baris_dengan_glif(glif: String) -> HBoxContainer:
	var baris: HBoxContainer = HBoxContainer.new()
	baris.mouse_filter = Control.MOUSE_FILTER_IGNORE
	baris.add_theme_constant_override(&"separation", Config.UI_CHIP_JARAK_PX)
	var gambar: TextureRect = TextureRect.new()
	gambar.texture = GayaHud.tekstur(glif)
	gambar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	gambar.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	gambar.custom_minimum_size = Vector2(Config.HASIL_GLIF_PX, Config.HASIL_GLIF_PX)
	gambar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	gambar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	baris.add_child(gambar)
	return baris


func _label(varian: StringName, warna: Color) -> Label:
	var label: Label = Label.new()
	label.theme_type_variation = varian
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override(&"font_color", warna)
	return label


## Menyatakan ada tidaknya dunia rute di belakang layar ini (V-10; `RuteMain` mengaturnya true). Dengan dunia: lapisan gelap `UI_BG` tembus pandang (alpha `HASIL_LATAR_ALPHA`) dan struk dan kartu transparan sebagian
## (`HASIL_PANEL_ALPHA`). Tanpa dunia (bawaan): latar gelap polos buram dan panel buram, seperti sebelum V-10. Tidak ada pemrosesan per frame: hanya warna lapisan dan pengali kotak yang diubah.
func atur_dunia(ada: bool) -> void:
	_ada_dunia = ada
	_terapkan_dunia()


## True bila layar ini di atas dunia rute.
func ada_dunia() -> bool:
	return _ada_dunia


## Warna lapisan latar yang sedang dipakai (untuk tes dan probe).
func warna_latar() -> Color:
	return _latar.color


## Alpha struk dan kartu kolom samping yang sedang dipakai (untuk tes dan probe).
func alpha_panel() -> float:
	return _kotak_panel[0].modulate_color.a if not _kotak_panel.is_empty() else 1.0


func _terapkan_dunia() -> void:
	_latar.color = TampilHasil.warna_latar(_ada_dunia)
	for kotak: StyleBoxTexture in _kotak_panel:
		kotak.modulate_color = TampilHasil.modulasi_panel(_ada_dunia)


## Mengganti tombol layar ini: true = "Ke bengkel" (alur hari), false = "Main lagi" (bawaan).
func atur_mode_hari(nilai: bool) -> void:
	_mode_hari = nilai
	_tombol.text = "BENGKEL_BUKA" if nilai else "RUTE_MAIN_LAGI"


## True bila tombol layar ini "Ke bengkel".
func mode_hari() -> bool:
	return _mode_hari


func _saat_tombol() -> void:
	if _mode_hari:
		bengkel_diminta.emit()
	else:
		main_lagi_diminta.emit()


## Mengatur inset aman tepi layar (piksel game, `ZonaAman.inset_game`) lalu menata ulang. Null = nol.
func atur_inset(inset: ZonaAman.Inset) -> void:
	_inset = inset if inset != null else ZonaAman.Inset.new()
	_susun()


## Mengisi angka dari `angka` (`HasilRute.dari`). Tidak menghitung ulang apa pun. `misi` (data misi hari ini, null = tanpa misi) memberi teks banner untuk
## baris rekap misi (run fase4b-misi-kucing, AC-16): satu baris bila `angka.misi_hasil` selesai atau gagal, tidak ada baris tanpa misi. `perlu_bengkel` = id komponen sepeda PERLU_BENGKEL
## (`BikeCondition.perlu_bengkel`): satu baris kondisi per komponen, tanpa komponen rusak tidak ada baris (AC-24). `saldo_lama` = saldo save sebelum hari ini (-1 = tidak diketahui, mis. rute yang
## dijalankan sendiri): baris "Saldo mulai lagi dari 0" hanya bila `HasilRute.koin_dijepit` > 0. `reputasi` (`ReputationManager.Hasil` hari ini) dan `milestone` (`MilestoneTracker.Ringkasan`) mengisi kolom samping
## (run 6A2 bagian C); null = bagian itu tidak tampil, keduanya null = kolom samping tersembunyi dan struk ke tengah.
func isi(angka: HasilRute.Angka, misi: DataMisi = null, perlu_bengkel: Array[String] = [], saldo_lama: int = -1, reputasi: ReputationManager.Hasil = null, milestone: MilestoneTracker.Ringkasan = null) -> void:
	var pemisah: String = tr("HUD_PEMISAH_RIBUAN")
	_nilai_terkirim.text = tr("HASIL_TERKIRIM_ANGKA").format({"n": angka.terkirim, "total": angka.pelanggan})
	_glif_terkirim.texture = GayaHud.tekstur(TampilHasil.glif_terkirim(angka.terkirim, angka.pelanggan))
	_nilai_koin.text = tr("HASIL_KOIN_ANGKA").format({"n": HasilRute.ribuan(angka.koin, pemisah)})
	_baris_tip.nilai.text = tr("HASIL_TIP_ANGKA").format({"koin": HasilRute.ribuan(angka.koin_tip, pemisah), "n": angka.jumlah_tip})
	_baris_skor.nilai.text = tr("HASIL_SKOR_ANGKA").format({"n": HasilRute.ribuan(angka.skor, pemisah)})
	_baris_tepat.nilai.text = tr("HASIL_TEPAT_ANGKA").format({"n": angka.jumlah_tepat})
	_baris_meleset.nilai.text = tr("HASIL_MELESET_ANGKA").format({"n": angka.meleset})
	_isi_potongan(angka, saldo_lama, pemisah)
	_isi_rekap_misi(angka, misi)
	_isi_kondisi(perlu_bengkel)
	_isi_kanan(reputasi, milestone)
	if angka.tenggat_lewat:
		var md: Vector2i = TenggatRute.menit_detik(angka.detik_lewat)
		_teks_tenggat.text = tr("HASIL_TENGGAT_LEWAT").format({"m": md.x, "s": "%02d" % md.y})
	else:
		_teks_tenggat.text = tr("HASIL_TENGGAT_SEMPAT")
	_susun()


## Kolom samping (AC-13): reputasi + perubahan (chip), jumlah pelanggan (hanya yang bukan nol), milestone paling dekat, tingkat yang baru tercapai. Bagian tanpa data tersembunyi; tanpa keduanya seluruh kolom tersembunyi.
func _isi_kanan(reputasi: ReputationManager.Hasil, milestone: MilestoneTracker.Ringkasan) -> void:
	_kolom_kanan.visible = TampilHasil.ada_samping(reputasi != null, milestone != null)
	var pemisah: String = tr("HUD_PEMISAH_RIBUAN")
	_kartu_reputasi.visible = reputasi != null
	_kartu_pelanggan.visible = false
	_teks_reputasi = ""
	if reputasi != null:
		_teks_reputasi = tr("HASIL_REPUTASI_ANGKA").format({"n": reputasi.reputasi_sesudah, "d": "%+d" % reputasi.perubahan})
		_angka_reputasi.text = str(reputasi.reputasi_sesudah)
		var delta: TampilHasil.InfoDelta = TampilHasil.delta_reputasi(reputasi.perubahan)
		_chip_reputasi.atur(delta.gaya, delta.teks, KomponenUi.UkuranChip.NORMAL, delta.glif)
		_ratakan_reputasi()
		var jenis: Array = [ReputationManager.Jenis.BARU, ReputationManager.Jenis.SETIA, ReputationManager.Jenis.BERHENTI, ReputationManager.Jenis.KEMBALI]
		var ada: bool = false
		for i: int in range(jenis.size()):
			var n: int = reputasi.jumlah(jenis[i])
			_label_pelanggan[i].visible = n > 0
			_nilai_pelanggan[i].visible = n > 0
			_nilai_pelanggan[i].text = tr("HASIL_PELANGGAN_ANGKA").format({"n": n})
			ada = ada or n > 0
		_kartu_pelanggan.visible = ada
	_kartu_target.visible = milestone != null
	_bagian_baru.visible = false
	if milestone == null:
		return
	var s: MilestoneTracker.Status = milestone.terdekat
	_teks_tamat.visible = s == null
	_baris_target.visible = s != null
	_baris_bilah.visible = s != null
	if s != null:
		_ikon_target.texture = LENCANA[s.tingkat]
		_nama_target.text = tr("HASIL_TARGET_NAMA").format({"nama": tr(kunci_nama_milestone(s.id)), "tingkat": tr(kunci_tingkat(s.tingkat + 1))})
		_bilah_target.atur(s.pecahan())
		_angka_target.text = tr("HASIL_TARGET_ANGKA").format({"n": HasilRute.ribuan(s.nilai, pemisah), "target": HasilRute.ribuan(s.target, pemisah)})
	var tampil: int = mini(milestone.baru.size(), _baris_baru.size())
	_bagian_baru.visible = tampil > 0
	for i: int in range(_baris_baru.size()):
		_baris_baru[i].visible = i < tampil
		if i < tampil:
			var c: MilestoneTracker.Capaian = milestone.baru[i]
			_ikon_baru[i].texture = LENCANA_BARU[clampi(c.tingkat - 1, 0, LENCANA_BARU.size() - 1)]
			_teks_baru[i].text = tr("HASIL_TARGET_BARU").format({"nama": tr(kunci_nama_milestone(c.id)), "tingkat": tr(kunci_tingkat(c.tingkat))})


## Kunci terjemahan nama milestone `id` ("HASIL_MILESTONE_NAMA_<ID>").
static func kunci_nama_milestone(id: String) -> String:
	return TampilHasil.kunci_nama_milestone(id)


## Kunci terjemahan nama tingkat 1..3 ("HASIL_MILESTONE_TINGKAT_<NAMA>").
static func kunci_tingkat(tingkat_ke: int) -> String:
	return TampilHasil.kunci_tingkat(tingkat_ke)


## Baris koran terbuang dan koin bersih (AC-11): tersembunyi bila tidak ada koran terbuang; baris saldo dijepit hanya bila saldo benar-benar dijepit 0 (O-2).
func _isi_potongan(angka: HasilRute.Angka, saldo_lama: int, pemisah: String) -> void:
	var ada: bool = angka.lempar_terbuang > 0
	_baris_terbuang.tampil(ada)
	_baris_bersih.tampil(ada)
	_baris_terbuang.nilai.text = tr("HASIL_TERBUANG_ANGKA").format({"n": angka.lempar_terbuang, "koin": HasilRute.ribuan(angka.potongan, pemisah)})
	_baris_bersih.nilai.text = tr("HASIL_KOIN_BERSIH_ANGKA").format({"n": HasilRute.ribuan(angka.koin_bersih, pemisah)})
	_teks_saldo_nol.visible = saldo_lama >= 0 and HasilRute.koin_dijepit(saldo_lama, angka.koin_bersih) > 0
	_teks_saldo_nol.text = tr("HASIL_SALDO_NOL")


## Baris rekap misi (AC-16): "Misi: Kucing ketemu! +75 koin" (selesai, `OK`, bercentang, di bawah daftar yang berhasil) atau "Misi: Kucingnya lolos hari ini" (gagal, netral `TEXT_2`, tanpa glif, di bawah teks
## tenggat); tanpa misi (atau misi tanpa hasil) baris tersembunyi. Teks dari kunci banner misi dan `angka.koin_misi`, tanpa hitung ulang.
func _isi_rekap_misi(angka: HasilRute.Angka, misi: DataMisi) -> void:
	var selesai: bool = angka.misi_hasil == "selesai"
	var gagal: bool = angka.misi_hasil == "gagal"
	_baris_misi.visible = (selesai or gagal) and misi != null
	if not _baris_misi.visible:
		return
	_glif_misi.visible = selesai
	if selesai:
		_rekap_misi.text = tr("HASIL_MISI_SELESAI").format({"teks": tr(misi.banner_selesai), "koin": HasilRute.ribuan(angka.koin_misi, tr("HUD_PEMISAH_RIBUAN"))})
		_rekap_misi.add_theme_color_override(&"font_color", Palette.OK)
		_rekap_misi.theme_type_variation = &"LayarTeksUtama"
		_taruh_setelah(_baris_misi, _daftar_berhasil)
	else:
		_rekap_misi.text = tr("HASIL_MISI_GAGAL").format({"teks": tr(misi.banner_gagal)})
		_rekap_misi.add_theme_color_override(&"font_color", Palette.TEXT_2)
		_rekap_misi.theme_type_variation = &"LayarTeksKecil"
		_taruh_setelah(_baris_misi, _teks_tenggat)


# Memindahkan `simpul` tepat sesudah `acuan` di isi struk (`move_child`, bukan keluarkan-lalu-masukkan: itu menghapus pemilik node dan nama uniknya, `%RekapMisi`).
func _taruh_setelah(simpul: Control, acuan: Control) -> void:
	var tujuan: int = acuan.get_index()
	_isi.move_child(simpul, tujuan if simpul.get_index() < tujuan else tujuan + 1)


## Baris kondisi sepeda: "Rantai perlu servis" per komponen PERLU_BENGKEL (sampai tiga), teks `TEXT` dengan glif "!" berwarna `WARN`; tanpa komponen rusak seluruh blok tersembunyi.
func _isi_kondisi(perlu_bengkel: Array[String]) -> void:
	var jumlah: int = TampilHasil.jumlah_baris_kondisi(perlu_bengkel.size())
	for i: int in range(_baris_kondisi.size()):
		_baris_kondisi[i].visible = i < jumlah
		if i < jumlah:
			_teks_kondisi[i].text = tr("KONDISI_HASIL_PERLU").format({"komponen": tr(TampilKondisi.kunci_nama(perlu_bengkel[i]))})
	_kondisi.visible = jumlah > 0


## Tata letak dari `TampilHasil.tata`: margin tepi (max 12 dan inset aman), lebar struk dan kolom samping, letak x struk, jarak atas kolom, dan letak tombol aksi utama kanan bawah di dalam margin. Dua kali: sekali dengan
## tinggi yang diketahui sekarang, lalu ditunda satu frame sesudah Container selesai menghitung (tinggi struk dan kolom bergantung pada bungkus kata).
func _susun() -> void:
	if _batas == null or not is_inside_tree():
		return
	var viewport: Vector2i = Vector2i(get_viewport().get_visible_rect().size)
	var tinggi_struk: int = ceili(_panel.size.y)
	var tinggi_kolom: int = ceili(_kolom_kanan.size.y) - (_kolom_atas_dipakai if _jarak_kolom.visible else 0)
	_tata = TampilHasil.tata(viewport, _inset, _kolom_kanan.visible, tinggi_struk, tinggi_kolom)
	_batas.add_theme_constant_override(&"margin_left", _tata.x_struk)
	_batas.add_theme_constant_override(&"margin_right", _tata.margin_akhir)
	_batas.add_theme_constant_override(&"margin_top", _tata.margin_atas)
	_batas.add_theme_constant_override(&"margin_bottom", _tata.margin_bawah)
	_badan.alignment = BoxContainer.ALIGNMENT_BEGIN
	_kolom_kiri.custom_minimum_size = Vector2(_tata.lebar_struk, 0)
	_kolom_kanan.custom_minimum_size = Vector2(_tata.lebar_kolom, 0)
	# Pengisi memakai jarak antar anak kolom juga, jadi tingginya `kolom_atas` dikurangi jarak itu supaya kartu pertama mulai tepat `kolom_atas` di bawah margin atas (sejajar struk).
	_kolom_atas_dipakai = _tata.kolom_atas
	_jarak_kolom.custom_minimum_size = Vector2(0, maxi(_tata.kolom_atas - Config.HASIL_KARTU_JARAK_PX, 0))
	_jarak_kolom.visible = _tata.kolom_atas > 0
	_tombol.offset_right = -float(_tata.margin_akhir)
	_tombol.offset_left = -float(_tata.margin_akhir + _tata.tombol.size.x)
	_tombol.offset_bottom = -float(_tata.margin_bawah)
	_tombol.offset_top = -float(_tata.margin_bawah + _tata.tombol.size.y)
	_batas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


# Label berbungkus kata yang baru tampil sempat menghitung tinggi dengan lebar 0 (satu huruf per baris); `Batas` lalu membesar dan Control menyimpan ukuran besar itu di offsetnya walau tinggi
# minimum sudah turun lagi (isi bergeser ke atas layar). Menata lagi dengan tinggi yang sudah benar dan menegakkan persegi penuh sesudah tata letak selesai (sama dengan `LayarBengkel`).
func _susun_tertunda() -> void:
	_susun_antri = false
	_susun()


# Tinggi struk dan kolom samping baru benar sesudah Container selesai menghitung bungkus kata (satu atau beberapa frame sesudah `isi`): tiap perubahan ukuran keduanya menata ulang sekali, ditunda ke akhir frame.
# Dijaga paling banyak `HASIL_SUSUN_ULANG_MAKS` kali per frame supaya tidak berputar; sisanya dilanjutkan di frame berikutnya.
func _ukuran_berubah() -> void:
	var frame: int = Engine.get_process_frames()
	if frame != _susun_frame:
		_susun_frame = frame
		_susun_hitung = 0
	if _susun_antri:
		return
	if _susun_hitung >= Config.HASIL_SUSUN_ULANG_MAKS:
		# Batas per frame tercapai: lanjutkan di frame berikutnya (sambungan sekali jalan, ikut hilang bila layar dibebaskan).
		if not get_tree().process_frame.is_connected(_ukuran_berubah):
			get_tree().process_frame.connect(_ukuran_berubah, CONNECT_ONE_SHOT)
		return
	_susun_hitung += 1
	_susun_antri = true
	_susun_tertunda.call_deferred()


## Inset aman perangkat mobile; desktop dan headless: tidak mengubah inset (sama dengan `LayarBengkel`).
func _baca_zona_aman() -> void:
	if not OS.has_feature("mobile"):
		_susun()
		return
	var aman: Rect2i = DisplayServer.get_display_safe_area()
	atur_inset(ZonaAman.inset_game(aman, DisplayServer.window_get_size(), get_viewport().get_visible_rect().size))


## Menampilkan atau menyembunyikan layar hasil.
func tampilkan(nilai: bool) -> void:
	visible = nilai
	if nilai:
		_susun()


## True bila layar hasil sedang tampil.
func tampil() -> bool:
	return visible


# --- Untuk tes dan probe ---

## True bila blok baris kondisi tampil (false bila tidak ada komponen PERLU_BENGKEL: blok kosong yang terlihat tetap menambah jarak di struk).
func kondisi_tampil() -> bool:
	return _kondisi.visible


## Teks baris kondisi yang tampil, urut (kosong bila tidak ada komponen rusak).
func teks_kondisi() -> Array[String]:
	var hasil: Array[String] = []
	if not _kondisi.visible:
		return hasil
	for i: int in range(_baris_kondisi.size()):
		if _baris_kondisi[i].visible:
			hasil.append(_teks_kondisi[i].text)
	return hasil


## Persegi tiap baris kondisi yang tampil (label teksnya) dalam koordinat viewport game (tes tata letak).
func rect_kondisi() -> Array[Rect2]:
	var hasil: Array[Rect2] = []
	if not _kondisi.visible:
		return hasil
	for i: int in range(_baris_kondisi.size()):
		if _baris_kondisi[i].visible:
			hasil.append(_baris_kondisi[i].get_global_rect())
	return hasil


## Teks baris rekap misi ("" bila tersembunyi).
func teks_rekap_misi() -> String:
	return _rekap_misi.text if _baris_misi.visible else ""


## Persegi baris rekap misi (label) dalam koordinat viewport game (tes tata letak).
func rect_rekap_misi() -> Rect2:
	return _rekap_misi.get_global_rect()


## Teks koran terbuang, koin bersih, dan saldo dijepit yang tampil, urut ("" bila tersembunyi); untuk tes.
func teks_potongan() -> Array[String]:
	var hasil: Array[String] = []
	if _baris_terbuang.baris.visible:
		hasil.append(_baris_terbuang.nilai.text)
		hasil.append(_baris_bersih.nilai.text)
	if _teks_saldo_nol.visible:
		hasil.append(_teks_saldo_nol.text)
	return hasil


## True bila kolom samping (reputasi, pelanggan, milestone) tampil.
func kanan_tampil() -> bool:
	return _kolom_kanan.visible


## Teks reputasi "12 (+2)" ("" bila tersembunyi).
func teks_reputasi() -> String:
	return _teks_reputasi if _kolom_kanan.visible and _kartu_reputasi.visible else ""


## Chip perubahan reputasi (untuk tes: gaya, glif, dan warna teks).
func chip_reputasi() -> ChipUi:
	return _chip_reputasi


## Baris pelanggan yang tampil, "Label: n" urut baru, jadi tetap, berhenti, kembali (kosong bila tidak ada).
func teks_pelanggan() -> Array[String]:
	var hasil: Array[String] = []
	if not _kolom_kanan.visible or not _kartu_pelanggan.visible:
		return hasil
	for i: int in range(_label_pelanggan.size()):
		if _label_pelanggan[i].visible:
			hasil.append("%s: %s" % [tr(_label_pelanggan[i].text), _nilai_pelanggan[i].text])
	return hasil


## Milestone paling dekat: "Nama · Tingkat 2/10" ("" bila tersembunyi); semua emas = teks tamat.
func teks_target() -> String:
	if not _kolom_kanan.visible or not _kartu_target.visible:
		return ""
	if _teks_tamat.visible:
		return tr(_teks_tamat.text)
	return "%s %s" % [_nama_target.text, _angka_target.text]


## Baris tingkat baru tercapai yang tampil, urut.
func teks_baru() -> Array[String]:
	var hasil: Array[String] = []
	if not _kolom_kanan.visible or not _bagian_baru.visible:
		return hasil
	for i: int in range(_baris_baru.size()):
		if _baris_baru[i].visible:
			hasil.append(_teks_baru[i].text)
	return hasil


## Pecahan bilah milestone yang tampil (-1 bila bilah tersembunyi; untuk tes).
func pecahan_bilah() -> float:
	if _kolom_kanan.visible and _kartu_target.visible and _baris_bilah.visible:
		return _bilah_target.pecahan()
	return -1


## Tekstur lencana target (32x32) dan baris baru (24x24, untuk tes): indeks 0 = perunggu.
func tekstur_target() -> Texture2D:
	return _ikon_target.texture


func tekstur_baru() -> Array[Texture2D]:
	var hasil: Array[Texture2D] = []
	for i: int in range(_baris_baru.size()):
		if _baris_baru[i].visible:
			hasil.append(_ikon_baru[i].texture)
	return hasil


## Persegi kolom samping dan semua simpul kontennya yang tampil (tes tata letak): kolom, label, ikon, chip, bilah.
func rect_panel_kanan() -> Rect2:
	return _kolom_kanan.get_global_rect()


func rect_isi_kanan() -> Array[Rect2]:
	var hasil: Array[Rect2] = []
	if not _kolom_kanan.visible:
		return hasil
	var simpul: Array[Control] = []
	if _kartu_reputasi.visible:
		simpul.append_array([_label_reputasi, _angka_reputasi, _ikon_reputasi, _chip_reputasi])
	if _kartu_pelanggan.visible:
		simpul.append(_judul_pelanggan)
		for i: int in range(_label_pelanggan.size()):
			if _label_pelanggan[i].visible:
				simpul.append_array([_label_pelanggan[i], _nilai_pelanggan[i]])
	if _kartu_target.visible:
		simpul.append(_judul_target)
		if _teks_tamat.visible:
			simpul.append(_teks_tamat)
		else:
			simpul.append_array([_ikon_target, _nama_target, _bilah_target, _angka_target])
	for i: int in range(_baris_baru.size()):
		if _baris_baru[i].visible:
			simpul.append_array([_ikon_baru[i], _teks_baru[i]])
	for c: Control in simpul:
		hasil.append(c.get_global_rect())
	return hasil


## Persegi kartu kolom samping yang tampil (reputasi, pelanggan, target), koordinat viewport game.
func rect_kartu() -> Array[Rect2]:
	var hasil: Array[Rect2] = []
	for kartu: PanelContainer in [_kartu_reputasi, _kartu_pelanggan, _kartu_target]:
		if kartu.is_visible_in_tree():
			hasil.append(kartu.get_global_rect())
	return hasil


## Teks yang tampil (sesudah terjemahan), urut dari atas (untuk tes): judul, lalu pasangan label dan nilai (yang tersembunyi dilewati), lalu teks tenggat.
func teks_tampil() -> Array[String]:
	var hasil: Array[String] = [tr(_judul.text)]
	hasil.append_array([tr(_label_terkirim.text), _nilai_terkirim.text])
	for baris: BarisStruk in [_baris_tip]:
		hasil.append_array([tr(baris.label.text), baris.nilai.text])
	hasil.append_array([tr(_label_koin.text), _nilai_koin.text])
	for baris: BarisStruk in [_baris_skor, _baris_tepat, _baris_meleset, _baris_terbuang, _baris_bersih]:
		if baris.baris.visible:
			hasil.append_array([tr(baris.label.text), baris.nilai.text])
	if _teks_saldo_nol.visible:
		hasil.append(_teks_saldo_nol.text)
	hasil.append(tr(_teks_tenggat.text))
	if _baris_misi.visible:
		hasil.append(_rekap_misi.text)
	hasil.append_array(teks_kondisi())
	if _kolom_kanan.visible:
		if teks_reputasi() != "":
			hasil.append("%s %s" % [tr(_label_reputasi.text), teks_reputasi()])
		hasil.append_array(teks_pelanggan())
		if teks_target() != "":
			hasil.append(teks_target())
		hasil.append_array(teks_baru())
	return hasil


## Teks tombol aksi utama yang tampil (untuk tes).
func teks_tombol() -> String:
	return tr(_tombol.text)


## Tombol aksi utama (untuk tes: `ditekan.emit()`).
func tombol_main_lagi() -> TombolSentuh:
	return _tombol


## Persegi tombol aksi utama, struk, dan judul dalam koordinat viewport game.
func rect_tombol() -> Rect2:
	return _tombol.get_global_rect()


func rect_panel() -> Rect2:
	return _panel.get_global_rect()


func rect_judul() -> Rect2:
	return _judul.get_global_rect()


## Tata letak yang sedang dipakai (`TampilHasil.tata`), untuk probe dan tes.
func tata() -> TampilHasil.Tata:
	return _tata


## Persegi tiap label di dalam struk yang tampil (untuk tes tata letak: semuanya di dalam struk dan layar); judul tidak termasuk (di atas struk, lihat `rect_judul`).
func rect_label() -> Array[Rect2]:
	var hasil: Array[Rect2] = [_label_terkirim.get_global_rect(), _nilai_terkirim.get_global_rect(), _label_koin.get_global_rect(), _nilai_koin.get_global_rect(), _teks_tenggat.get_global_rect()]
	if _teks_saldo_nol.visible:
		hasil.append(_teks_saldo_nol.get_global_rect())
	if _baris_misi.visible:
		hasil.append(_rekap_misi.get_global_rect())
	hasil.append_array(rect_kondisi())
	for baris: BarisStruk in [_baris_tip, _baris_skor, _baris_tepat, _baris_meleset, _baris_terbuang, _baris_bersih]:
		if baris.baris.visible:
			hasil.append(baris.label.get_global_rect())
			hasil.append(baris.nilai.get_global_rect())
	return hasil
