class_name HalamanKoran
extends CanvasLayer
## Layar halaman depan koran (DESIGN_SPEC 4 "Halaman depan koran" 🟡, GDD 10.1 dan 10.3, rule `ui-scenes`; AC-21 sampai AC-24 run
## fase4a-koran-hari, usulan): satu-satunya layar terang (kertas krem `KORAN_KERTAS`, tinta gelap `KORAN_TINTA`; kontras teks >= 7:1).
## Tipis: `HariMain` memberi `HeadlineManager.Halaman` (hasil pilihan headline), layar ini hanya menampilkannya dan memancarkan
## `ambil_diminta`, `lewati_diminta`, dan `berangkat_diminta`. Tidak memilih headline dan tidak menyimpan apa pun.
##
## Tata letak (run ui2-semua-layar bagian B, AC-3; kanvas Koran.dc.html dan Koran_*.dc.html, usulan; anchor + Container, tanpa posisi piksel absolut; teks sampai 40 / 60 karakter melar lewat autowrap): kertas dengan tekstur titik
## (`kertas_tile`), kepala (nama koran 32 px Lilita One kiri, "Hari N · Perumahan Melati" kanan) dan garis ganda, lalu dua kolom di dalam zona aman (`TampilKoran.tata`: margin `KORAN_MARGIN_PX` atau inset perangkat bila lebih besar;
## kolom berita | 6 + garis tegak 1 + 6 | kolom misi 236, 280 di lebar 800). Kolom berita: judul bagian (ikon efek 24 bila ada) dan berita utama (foto tinta dua nada bila efeknya jalan diperbaiki atau mati lampu, Lilita One 24),
## berita ringan (Lilita One 16) dengan batang hiasan, sisa ruang untuk kotak hiasan "Iklan baris" (hanya bila muat), dan satu kotak notifikasi save (hanya bila ada; menggantikan "Iklan baris"). Kolom misi: kotak misi
## (`koran_kotak`: ikon kucing, headline, ringkasan, Ambil/Lewati, status pilihan) dan tombol Berangkat 140x42 di zona jempol kanan. Tidak ada tombol jeda. Ukuran huruf mengikuti V-8 (teks utama 12, kecil 11, mini 10, label 10).
##
## Ambil/Lewati (S-7): awalnya tidak ada yang dipilih (sama dengan Lewati); bisa dibolak-balik sebelum Berangkat. Pilihan terbaca dari TEKS status (`KORAN_STATUS_*`), BENTUK (tombol terpilih berongga dengan bingkai tinta tebal dan glif centang,
## tombol lain hanya garis tipis rata; Berangkat terisi tinta penuh dengan panah), bukan warna saja (`TampilKoran`, `GayaHud.tombol_koran`).
## Tanpa misi memenuhi syarat (S-8) tombol Ambil/Lewati tidak tampil dan baris misi memuat teks netral `KORAN_TANPA_MISI`; headline lanjutan tanpa misi (misi_ditunda) tampil sebagai teks tanpa tombol. Berangkat selalu aktif.
## Semua teks lewat kunci terjemahan (data headline membawa KUNCI, diterjemahkan di sini); warna dari `Palette`; font dari `assets/ui/theme.tres`; tekstur dimuat sekali di `_ready` (bukan `_draw`).

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
## Peran bentuk tiap tombol (untuk tes dan penerapan gaya): Ambil, Lewati, Berangkat.
var _peran: Dictionary = {}
var _nama_foto: String = ""
var _nama_ikon_utama: String = ""

@onready var _latar: ColorRect = %Latar
@onready var _kertas: TextureRect = %Kertas
@onready var _batas: MarginContainer = %Batas
@onready var _isi: VBoxContainer = %Isi
@onready var _kepala: HBoxContainer = %Kepala
@onready var _badan: HBoxContainer = %Badan
@onready var _kolom_berita: VBoxContainer = %KolomBerita
@onready var _kolom_misi: VBoxContainer = %KolomMisi
@onready var _bungkus_nama: MarginContainer = %BungkusNama
@onready var _nama: Label = %NamaKoran
@onready var _bungkus_hari: MarginContainer = %BungkusHari
@onready var _hari: Label = %TeksHari
@onready var _garis_atas: GarisGanda = %GarisAtas
@onready var _garis_tengah: ColorRect = %GarisTengah
@onready var _garis_tegak: ColorRect = %GarisTegak
@onready var _baris_judul_utama: HBoxContainer = %BarisJudulUtama
@onready var _ikon_utama: TextureRect = %IkonUtama
@onready var _label_utama: Label = %LabelUtama
@onready var _baris_utama: HBoxContainer = %BarisUtama
@onready var _foto: TextureRect = %FotoUtama
@onready var _teks_utama: Label = %TeksUtama
@onready var _label_ringan: Label = %LabelRingan
@onready var _teks_ringan: Label = %TeksRingan
@onready var _hiasan_berita: GarisHiasan = %HiasanBerita
@onready var _ruang_iklan: Control = %RuangIklan
@onready var _kotak_iklan: KotakIklan = %KotakIklan
@onready var _label_iklan: Label = %LabelIklan
@onready var _hiasan_iklan: GarisHiasan = %HiasanIklan
@onready var _kotak_notifikasi: PanelContainer = %KotakNotifikasi
@onready var _glif_notifikasi: TextureRect = %GlifNotifikasi
@onready var _notifikasi: Label = %Notifikasi
@onready var _panel_misi: PanelContainer = %PanelMisi
@onready var _isi_misi: VBoxContainer = %IsiMisi
@onready var _baris_judul_misi: HBoxContainer = %BarisJudulMisi
@onready var _ikon_misi: TextureRect = %IkonMisi
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
	_kertas.texture = GayaHud.tekstur("kertas_tile")
	_isi.add_theme_constant_override(&"separation", 0)
	_bungkus_nama.add_theme_constant_override(&"margin_top", -Config.KORAN_KEPALA_NAIK_PX)
	_bungkus_nama.add_theme_constant_override(&"margin_bottom", Config.KORAN_KEPALA_BAWAH_PX)
	_bungkus_hari.add_theme_constant_override(&"margin_top", Config.KORAN_HARI_TURUN_PX)
	_badan.add_theme_constant_override(&"separation", Config.KORAN_KOLOM_JARAK_PX)
	_kolom_berita.add_theme_constant_override(&"separation", Config.KORAN_BERITA_JARAK_PX)
	_isi_misi.add_theme_constant_override(&"separation", Config.KORAN_MISI_JARAK_PX)
	_kolom_misi.add_theme_constant_override(&"separation", Config.KORAN_MISI_JARAK_PX)
	_baris_pilih.add_theme_constant_override(&"separation", Config.KORAN_TOMBOL_JARAK_PX)
	for baris: HBoxContainer in [_baris_judul_utama, _baris_judul_misi]:
		baris.add_theme_constant_override(&"separation", Config.KORAN_IKON_JARAK_PX)
	_baris_utama.add_theme_constant_override(&"separation", Config.KORAN_FOTO_JARAK_PX)
	_kotak_notifikasi.get_child(0).add_theme_constant_override(&"separation", Config.KORAN_NOTIF_JARAK_PX)
	_teks_utama.add_theme_constant_override(&"line_spacing", Config.KORAN_JARAK_BARIS_UTAMA_PX)
	for label: Label in [_teks_ringan, _teks_misi]:
		label.add_theme_constant_override(&"line_spacing", Config.KORAN_JARAK_BARIS_JUDUL_PX)
	for label: Label in [_ringkasan, _notifikasi, _tanpa_misi]:
		label.add_theme_constant_override(&"line_spacing", Config.KORAN_JARAK_BARIS_TEKS_PX)
	_garis_tengah.color = Palette.KORAN_GARIS
	_garis_tengah.custom_minimum_size = Vector2(0, Config.KORAN_GARIS_TEGAK_PX)
	_garis_tegak.color = Palette.KORAN_GARIS
	_garis_tegak.custom_minimum_size = Vector2(Config.KORAN_GARIS_TEGAK_PX, 0)
	for label: Label in [_nama, _teks_utama, _teks_ringan, _teks_misi]:
		label.add_theme_color_override(&"font_color", Palette.KORAN_TINTA)
	for label: Label in [_hari, _label_utama, _label_ringan, _label_misi, _label_iklan, _ringkasan, _status, _tanpa_misi, _notifikasi]:
		label.add_theme_color_override(&"font_color", Palette.KORAN_TINTA_2)
	_ikon_misi.texture = GayaHud.tekstur("icon24_kucing")
	_glif_notifikasi.texture = GayaHud.tekstur("glif_seru_tinta2")
	_foto.custom_minimum_size = Vector2(Config.KORAN_FOTO_LEBAR_PX, Config.KORAN_FOTO_TINGGI_PX)
	_panel_misi.add_theme_stylebox_override(&"panel", GayaHud.panel_koran())
	_kotak_notifikasi.add_theme_stylebox_override(&"panel", GayaHud.kotak_notifikasi_koran())
	_kotak_notifikasi.custom_minimum_size = Vector2(0, Config.KORAN_NOTIF_TINGGI_MIN_PX)
	for tombol: TombolSentuh in [_tombol_ambil, _tombol_lewati]:
		tombol.custom_minimum_size = Vector2(Config.UI_TOMBOL_LEBAR_MIN_PX, Config.UI_TOMBOL_TINGGI_PX)
	_tombol_berangkat.custom_minimum_size = Vector2(Config.UI_TOMBOL_LEBAR_UTAMA_PX, Config.UI_TOMBOL_TINGGI_PX)
	_peran[_tombol_berangkat] = TampilKoran.PeranTombol.TINTA
	GayaHud.tombol_koran(_tombol_berangkat, TampilKoran.PeranTombol.TINTA)
	GayaHud.glif_ujung_kanan(_tombol_berangkat, TampilKoran.glif_berangkat(), Config.KORAN_BERANGKAT_JARAK_PX)
	_tombol_ambil.ditekan.connect(_saat_ambil)
	_tombol_lewati.ditekan.connect(_saat_lewati)
	_tombol_berangkat.ditekan.connect(berangkat_diminta.emit)
	_ruang_iklan.resized.connect(_susun_iklan)
	get_viewport().size_changed.connect(_baca_zona_aman)
	get_viewport().size_changed.connect(_terapkan_lebar)
	_baca_zona_aman()
	_terapkan_margin()
	_terapkan_lebar()
	atur_pilihan(Pilihan.BELUM)
	tampilkan_notifikasi("")
	_atur_foto("")


## Mengisi layar dari `halaman` (hasil `HeadlineManager.susun`) untuk hari `hari` di distrik `distrik`. Pilihan misi diatur ulang ke "belum dipilih".
func isi(halaman: HeadlineManager.Halaman, hari: int, distrik: String) -> void:
	var kunci_distrik: String = KUNCI_DISTRIK.get(distrik, "KORAN_DISTRIK_PERUMAHAN")
	_hari.text = tr("KORAN_HARI_DISTRIK").format({"n": hari, "distrik": tr(kunci_distrik)})
	_teks_utama.text = tr(halaman.utama.teks) if halaman.utama != null else ""
	_teks_ringan.text = tr(halaman.ringan.teks) if halaman.ringan != null else ""
	_label_utama.visible = halaman.utama != null
	_teks_utama.visible = halaman.utama != null
	_atur_foto(halaman.utama.efek if halaman.utama != null else "")
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


## Menampilkan satu baris notifikasi save (AC-9) dari KUNCI terjemahan (`SaveManager.ambil_notifikasi`, atau `KORAN_SAVE_GAGAL` dari
## `HariMain`); kunci kosong menyembunyikan baris.
func tampilkan_notifikasi(kunci: String) -> void:
	_notifikasi.text = kunci
	_kotak_notifikasi.visible = not kunci.is_empty()
	_susun_iklan()


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


## Gaya tombol (bingkai 9-slice) saat ini, untuk tes bentuk: gaya `normal` (tekstur menurut peran, `TampilKoran.nama_tekstur_tombol`).
func gaya_tombol(tombol: TombolSentuh) -> StyleBoxTexture:
	return tombol.get_theme_stylebox(&"normal") as StyleBoxTexture


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


## Peran bentuk tombol (`TampilKoran.PeranTombol`): Ambil dan Lewati TERPILIH atau TIPIS menurut pilihan, Berangkat TINTA.
func peran_tombol(tombol: TombolSentuh) -> TampilKoran.PeranTombol:
	return _peran[tombol]


## Nama dasar tekstur foto berita utama yang tampil ("" = tanpa foto) dan ikon 24 judul berita utama ("" = tanpa ikon).
func nama_foto() -> String:
	return _nama_foto


func nama_ikon_utama() -> String:
	return _nama_ikon_utama


## True bila foto berita utama tampil, dan persegi foto, ikon judul, dan kotak "Iklan baris" dalam koordinat viewport game.
func foto_tampil() -> bool:
	return _foto.is_visible_in_tree()


func rect_foto() -> Rect2:
	return _foto.get_global_rect()


func rect_ikon_utama() -> Rect2:
	return _ikon_utama.get_global_rect()


func rect_ikon_misi() -> Rect2:
	return _ikon_misi.get_global_rect()


func iklan_tampil() -> bool:
	return _kotak_iklan.is_visible_in_tree()


func rect_iklan() -> Rect2:
	return _kotak_iklan.get_global_rect()


func rect_ruang_iklan() -> Rect2:
	return _ruang_iklan.get_global_rect()


func rect_notifikasi() -> Rect2:
	return _kotak_notifikasi.get_global_rect()


func notifikasi_tampil() -> bool:
	return _kotak_notifikasi.is_visible_in_tree()


func rect_garis_tegak() -> Rect2:
	return _garis_tegak.get_global_rect()


func rect_garis_ganda() -> Rect2:
	var r: Rect2 = _garis_atas.get_global_rect()
	r.size.y = float(TampilKoran.tinggi_garis_ganda())
	return r


func rect_kolom_berita() -> Rect2:
	return _kolom_berita.get_global_rect()


func rect_kolom_misi() -> Rect2:
	return _kolom_misi.get_global_rect()


## Persegi kontrol hiasan (batang) berita ringan dan batang di kotak iklan.
func hiasan_baris() -> int:
	return _hiasan_berita.baris if _hiasan_berita.visible else 0


func rect_hiasan_berita() -> Rect2:
	return _hiasan_berita.get_global_rect()


## Tata letak murni (`TampilKoran.tata`) untuk viewport dan inset sekarang.
func tata() -> TampilKoran.Tata:
	return TampilKoran.tata(Vector2i(get_viewport().get_visible_rect().size), _inset)


func _semua_label() -> Array[Label]:
	return [_nama, _hari, _label_utama, _teks_utama, _label_ringan, _teks_ringan, _notifikasi, _label_iklan, _label_misi, _teks_misi, _ringkasan, _status, _tanpa_misi]


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


## Bentuk tombol pilihan: terpilih = BERONGGA dengan bingkai tinta tebal dan glif centang gelap; tidak terpilih = garis tipis rata tanpa glif. Berangkat sebaliknya TERISI tinta penuh dengan panah
## (`GayaHud.tombol_koran`), jadi pilihan terbaca sebagai tanda pilihan, bukan aksi utama kedua (QA-010). Bentuk dan glif ditambah teks status membedakan pilihan, bukan warna saja.
func _gaya_pilih(tombol: TombolSentuh, terpilih: bool) -> void:
	var peran: TampilKoran.PeranTombol = TampilKoran.peran_pilih(terpilih)
	_peran[tombol] = peran
	GayaHud.tombol_koran(tombol, peran)
	var glif: String = TampilKoran.glif_pilih(terpilih)
	tombol.icon = GayaHud.tekstur(glif) if glif != "" else null


## Foto dan ikon judul berita utama menurut `efek` (hanya jalan diperbaiki dan mati lampu; selain itu tanpa foto dan tanpa ikon).
func _atur_foto(efek: String) -> void:
	_nama_foto = TampilKoran.foto_untuk_efek(efek)
	_nama_ikon_utama = TampilKoran.ikon_untuk_efek(efek)
	_foto.texture = GayaHud.tekstur(_nama_foto) if _nama_foto != "" else null
	_foto.visible = _nama_foto != ""
	_ikon_utama.texture = GayaHud.tekstur(_nama_ikon_utama) if _nama_ikon_utama != "" else null
	_ikon_utama.visible = _nama_ikon_utama != ""


## Lebar kolom misi menurut lebar viewport (236, 280 di lebar 800); kolom berita mengisi sisanya lewat Container.
func _terapkan_lebar() -> void:
	if _kolom_misi == null:
		return
	_kolom_misi.custom_minimum_size = Vector2(TampilKoran.lebar_misi(roundi(get_viewport().get_visible_rect().size.x)), 0)


## Batang hiasan (atas) dan kotak "Iklan baris" (kiri bawah) berbagi ruang sisa kolom berita (`TampilKoran.ruang`); iklan tidak tampil bila ruang terlalu rendah atau notifikasi save tampil (menggantikannya, kanvas).
func _susun_iklan() -> void:
	if _kotak_iklan == null:
		return
	var ruang: TampilKoran.Ruang = TampilKoran.ruang(Vector2i(roundi(_ruang_iklan.size.x), roundi(_ruang_iklan.size.y)))
	_hiasan_berita.visible = ruang.hiasan_baris > 0
	_hiasan_berita.baris = ruang.hiasan_baris
	_hiasan_berita.position = Vector2(ruang.hiasan.position)
	_hiasan_berita.size = Vector2(ruang.hiasan.size)
	_kotak_iklan.visible = ruang.iklan.size.y > 0 and not _kotak_notifikasi.visible
	_kotak_iklan.position = Vector2(ruang.iklan.position)
	_kotak_iklan.size = Vector2(ruang.iklan.size)
