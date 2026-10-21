class_name LayarBengkel
extends CanvasLayer
## Layar bengkel (DESIGN_SPEC 4 "Bengkel" sketsa, GDD 12.3 dan 12.4, rule `ui-scenes`; AC-16, AC-25, AC-26 run fase6a1-bengkel-kondisi bagian B, K-1 dan K-4, usulan; dinilai di HP).
## Tipis: `HariMain` memberi state kerja (saldo `koin` = koin save + koin hari ini, `sepeda` = kondisi akhir rute dan level tersimpan) dan daftar upgrade (`PemuatToko`); layar ini hanya
## menampilkan dan, saat tombol ditekan, memanggil `Economy.servis` / `Economy.beli_upgrade` lalu menampilkan hasilnya. Tidak menyimpan apa pun: simpan tepat sekali oleh `HariMain` saat
## "Hari berikutnya" (AC-20). Back Android = "Hari berikutnya" (diurus `HariMain` lewat `MesinHari.aksi_back`).
##
## Tata letak (anchor + Container; margin = max(`BENGKEL_MARGIN_PX`, inset aman perangkat)): judul "Bengkel" (`JudulLayar`) dan saldo (ikon koin + angka berpemisah ribuan) di baris atas; dua kolom:
## SERVIS (kartu ban, rem, rantai: ikon + tiga kotak kondisi + tanda "!" `KotakKondisi`, nama, tingkat dalam teks, harga, tombol "Servis" atau label "Baik" bila penuh; catatan ongkos naik bila >= 2
## komponen PERLU_BENGKEL, GDD 12.3) dan UPGRADE (kartu per upgrade `PemuatToko`: nama, deskripsi satu baris, harga, tombol "Beli" atau label "Dimiliki"); tombol "Hari berikutnya" SELALU aktif
## di kanan bawah (K-4: bengkel boleh dilewati). Tempat iklan hadiah: tidak ada (rule `privacy-ads`, AC-16; Fase 14).
## Tombol nonaktif (saldo kurang) terbaca tanpa warna: teksnya berganti "Koin kurang" dan bingkainya redup; semua tombol >= 42 px game tingginya. Menekan tombol nonaktif lewat `pressed.emit()`
## tidak mengubah apa pun (Economy menolak atomik). Teks hanya kunci terjemahan; warna dari `Palette`; font dari `assets/ui/theme.tres`.

## Tombol "Hari berikutnya" ditekan (atau back Android: `HariMain`).
signal hari_berikutnya_diminta
## Servis diterima: komponen dan harga yang dibayar.
signal servis_dilakukan(komponen: String, harga: int)
## Upgrade dibeli: id dan harga yang dibayar.
signal upgrade_dibeli(id: String, harga: int)

## Skrip autoload `Audio`, hanya untuk tipe (`Audio` tidak merujuk autoload lain, rule `gdscript`).
const SKRIP_AUDIO := preload("res://scripts/autoload/audio.gd")


## Satu kartu servis komponen.
class KartuServis extends RefCounted:
	var panel: PanelContainer = null
	var kotak: KotakKondisi = null
	var nama: Label = null
	var tingkat: Label = null
	var harga: Label = null
	var tombol: TombolSentuh = null
	var label_baik: Label = null


## Satu kartu upgrade.
class KartuUpgrade extends RefCounted:
	var data: DataToko = null
	var panel: PanelContainer = null
	var nama: Label = null
	var deskripsi: Label = null
	var harga: Label = null
	var tombol: TombolSentuh = null
	var label_dimiliki: Label = null


var _state: Dictionary = {}
var _toko: PemuatToko.Kumpulan = PemuatToko.Kumpulan.new()
var _kartu_servis: Dictionary = {}
var _kartu_upgrade: Array[KartuUpgrade] = []
var _inset: ZonaAman.Inset = ZonaAman.Inset.new()
var _audio: SKRIP_AUDIO = null
var _belanja_servis: int = 0
var _belanja_upgrade: int = 0

@onready var _latar: ColorRect = %Latar
@onready var _batas: MarginContainer = %Batas
@onready var _isi: VBoxContainer = %Isi
@onready var _baris_atas: HBoxContainer = %BarisAtas
@onready var _judul: Label = %Judul
@onready var _panel_saldo: PanelContainer = %PanelSaldo
@onready var _ikon_saldo: TextureRect = %IkonSaldo
@onready var _angka_saldo: Label = %AngkaSaldo
@onready var _galat: Label = %Galat
@onready var _kolom: HBoxContainer = %Kolom
@onready var _kolom_servis: VBoxContainer = %KolomServis
@onready var _kolom_upgrade: VBoxContainer = %KolomUpgrade
@onready var _label_servis: Label = %LabelServis
@onready var _label_upgrade: Label = %LabelUpgrade
@onready var _daftar_servis: VBoxContainer = %DaftarServis
@onready var _daftar_upgrade: VBoxContainer = %DaftarUpgrade
@onready var _catatan_ongkos: Label = %CatatanOngkos
@onready var _tombol_hari: TombolSentuh = %TombolHariBerikutnya


func _ready() -> void:
	_audio = get_node_or_null(^"/root/Audio") as SKRIP_AUDIO
	_latar.color = Palette.UI_BG
	_latar.mouse_filter = Control.MOUSE_FILTER_STOP
	_isi.add_theme_constant_override(&"separation", Config.BENGKEL_JARAK_PX)
	_kolom.add_theme_constant_override(&"separation", Config.BENGKEL_JARAK_PX * 2)
	for kolom: VBoxContainer in [_kolom_servis, _kolom_upgrade, _daftar_servis, _daftar_upgrade]:
		kolom.add_theme_constant_override(&"separation", Config.BENGKEL_JARAK_PX)
	_kolom_servis.size_flags_stretch_ratio = Config.BENGKEL_KOLOM_SERVIS_RASIO
	_kolom_upgrade.size_flags_stretch_ratio = Config.BENGKEL_KOLOM_UPGRADE_RASIO
	_judul.add_theme_color_override(&"font_color", Palette.TEXT)
	_label_servis.add_theme_color_override(&"font_color", Palette.ACCENT)
	_label_upgrade.add_theme_color_override(&"font_color", Palette.ACCENT)
	_angka_saldo.add_theme_color_override(&"font_color", Palette.TEXT)
	_galat.add_theme_color_override(&"font_color", Palette.WARN)
	_catatan_ongkos.add_theme_color_override(&"font_color", Palette.TEXT_2)
	_panel_saldo.add_theme_stylebox_override(&"panel", GayaHud.panel_hud())
	_ikon_saldo.custom_minimum_size = Vector2(Config.HUD_IKON_PX, Config.HUD_IKON_PX)
	_tombol_hari.custom_minimum_size = Vector2(Config.BENGKEL_HARI_LEBAR_PX, Config.HUD_TOMBOL_TINGGI_PX)
	_gaya_utama(_tombol_hari)
	_tombol_hari.ditekan.connect(hari_berikutnya_diminta.emit)
	for id: String in Config.KONDISI_KOMPONEN:
		_kartu_servis[id] = _bangun_kartu_servis(id)
	get_viewport().size_changed.connect(_baca_zona_aman)
	_baca_zona_aman()
	_terapkan_margin()


## Mengisi layar dari state kerja `state` (`koin` = saldo, `sepeda` = kondisi dan level) dan data upgrade `toko`. Galat memuat data upgrade ditampilkan jujur dan daftar upgrade kosong; servis
## dan "Hari berikutnya" tetap bisa (K-4).
func isi(state: Dictionary, toko: PemuatToko.Kumpulan) -> void:
	_state = state.duplicate(true)
	_toko = toko if toko != null else PemuatToko.Kumpulan.new()
	_belanja_servis = 0
	_belanja_upgrade = 0
	_galat.visible = not _toko.sah()
	_bangun_upgrade()
	_segarkan()


## State kerja saat ini (salinan): saldo sesudah belanja, kondisi, level, dan `servis_total`.
func state() -> Dictionary:
	return _state.duplicate(true)


## Koin yang sudah dibelanjakan sejak `isi` (servis dan upgrade).
func belanja_koin() -> int:
	return _belanja_servis + _belanja_upgrade


## Mengatur inset aman tepi layar (piksel game, `ZonaAman.inset_game`) lalu menata margin. Null = nol.
func atur_inset(inset: ZonaAman.Inset) -> void:
	_inset = inset if inset != null else ZonaAman.Inset.new()
	_terapkan_margin()


func tampilkan(nilai: bool) -> void:
	visible = nilai


# --- Aksi ---

func _saat_servis(komponen: String) -> void:
	var hasil: Economy.Hasil = Economy.servis(_state, komponen)
	if hasil.diterima:
		_state = hasil.state
		_belanja_servis += hasil.harga
		if _audio != null:
			_audio.putar_servis()
		servis_dilakukan.emit(komponen, hasil.harga)
	_segarkan()


func _saat_beli(id: String) -> void:
	var hasil: Economy.Hasil = Economy.beli_upgrade(_state, id, _toko.upgrade)
	if hasil.diterima:
		_state = hasil.state
		_belanja_upgrade += hasil.harga
		if _audio != null:
			_audio.putar_upgrade()
		upgrade_dibeli.emit(id, hasil.harga)
	_segarkan()


# --- Tampilan ---

## Menyegarkan semua baris dari `_state`: saldo, kondisi, harga, dan status tombol.
func _segarkan() -> void:
	var pemisah: String = tr("HUD_PEMISAH_RIBUAN")
	var saldo: int = Economy.saldo(_state)
	_angka_saldo.text = tr("BENGKEL_SALDO_ANGKA").format({"n": HasilRute.ribuan(saldo, pemisah)})
	var kondisi: Dictionary = Economy.kondisi_dari(_state)
	var level: Dictionary = Economy.level_dari(_state)
	var rusak: int = BikeCondition.perlu_bengkel(kondisi).size()
	for id: String in Config.KONDISI_KOMPONEN:
		var kartu: KartuServis = _kartu_servis[id]
		var c: float = float(kondisi[id])
		kartu.kotak.tampilkan(c, 0.0)
		kartu.nama.text = tr(TampilKondisi.kunci_nama(id))
		kartu.tingkat.text = tr(TampilKondisi.kunci_tingkat(c))
		kartu.tingkat.add_theme_color_override(&"font_color", Palette.WARN if TampilKondisi.tanda_seru(c) else Palette.TEXT_2)
		var penuh: bool = Economy.penuh(c)
		kartu.tombol.visible = not penuh
		kartu.label_baik.visible = penuh
		kartu.harga.visible = not penuh
		if not penuh:
			var harga: int = Economy.harga_servis_state(_state, id)
			kartu.harga.text = tr("BENGKEL_HARGA_ANGKA").format({"n": HasilRute.ribuan(harga, pemisah)})
			_atur_tombol(kartu.tombol, saldo >= harga, "BENGKEL_SERVIS")
	_catatan_ongkos.visible = rusak >= 2
	if _catatan_ongkos.visible:
		_catatan_ongkos.text = tr("BENGKEL_ONGKOS_NAIK").format({"x": "%.2f" % Economy.pengali_ongkos(rusak)})
	for kartu_u: KartuUpgrade in _kartu_upgrade:
		var tingkat: int = int(level.get(kartu_u.data.komponen, 0))
		var dimiliki: bool = tingkat >= kartu_u.data.level
		var terbuka: bool = tingkat == kartu_u.data.level - 1
		kartu_u.panel.visible = dimiliki or terbuka
		kartu_u.tombol.visible = terbuka
		kartu_u.label_dimiliki.visible = dimiliki
		kartu_u.harga.visible = terbuka
		if terbuka:
			kartu_u.harga.text = tr("BENGKEL_HARGA_ANGKA").format({"n": HasilRute.ribuan(kartu_u.data.harga, pemisah)})
			_atur_tombol(kartu_u.tombol, saldo >= kartu_u.data.harga, "BENGKEL_BELI")


## Tombol aksi: aktif bila `mampu` (teks aksi), selain itu nonaktif dengan teks alasan "Koin kurang" (terbaca tanpa warna).
func _atur_tombol(tombol: TombolSentuh, mampu: bool, kunci_aksi: String) -> void:
	tombol.disabled = not mampu
	tombol.text = tr(kunci_aksi if mampu else "BENGKEL_KOIN_KURANG")


## Kartu servis satu komponen: ikon dan kotak kondisi, nama dan tingkat, harga, lalu tombol Servis atau label "Baik".
func _bangun_kartu_servis(id: String) -> KartuServis:
	var kartu: KartuServis = KartuServis.new()
	kartu.panel = PanelContainer.new()
	kartu.panel.name = "Servis_" + id
	kartu.panel.add_theme_stylebox_override(&"panel", _kotak_kartu())
	_daftar_servis.add_child(kartu.panel)
	var baris: HBoxContainer = HBoxContainer.new()
	baris.add_theme_constant_override(&"separation", Config.BENGKEL_JARAK_PX)
	kartu.panel.add_child(baris)
	kartu.kotak = KotakKondisi.new()
	kartu.kotak.komponen = id
	kartu.kotak.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	baris.add_child(kartu.kotak)
	var teks: VBoxContainer = VBoxContainer.new()
	teks.add_theme_constant_override(&"separation", 0)
	teks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	teks.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	baris.add_child(teks)
	kartu.nama = _label("HudLabel", Palette.TEXT)
	kartu.tingkat = _label("TeksKecil", Palette.TEXT_2)
	teks.add_child(kartu.nama)
	teks.add_child(kartu.tingkat)
	kartu.harga = _label("HudLabel", Palette.TEXT)
	kartu.harga.custom_minimum_size = Vector2(Config.BENGKEL_HARGA_LEBAR_PX, 0)
	kartu.harga.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	kartu.harga.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	baris.add_child(kartu.harga)
	var aksi: Control = _bangun_aksi(baris, "BENGKEL_BAIK", "BENGKEL_SERVIS")
	kartu.label_baik = aksi.get_node("LabelAksi") as Label
	kartu.tombol = aksi.get_node("TombolAksi") as TombolSentuh
	kartu.tombol.ditekan.connect(_saat_servis.bind(id))
	return kartu


## Kartu upgrade dari data `toko` (dibangun ulang tiap `isi`).
func _bangun_upgrade() -> void:
	for kartu: KartuUpgrade in _kartu_upgrade:
		kartu.panel.queue_free()
		_daftar_upgrade.remove_child(kartu.panel)
	_kartu_upgrade = []
	for data: DataToko in _toko.upgrade:
		var kartu: KartuUpgrade = KartuUpgrade.new()
		kartu.data = data
		kartu.panel = PanelContainer.new()
		kartu.panel.name = "Upgrade_" + data.id
		kartu.panel.add_theme_stylebox_override(&"panel", _kotak_kartu())
		_daftar_upgrade.add_child(kartu.panel)
		var baris: HBoxContainer = HBoxContainer.new()
		baris.add_theme_constant_override(&"separation", Config.BENGKEL_JARAK_PX)
		kartu.panel.add_child(baris)
		var teks: VBoxContainer = VBoxContainer.new()
		teks.add_theme_constant_override(&"separation", 0)
		teks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		teks.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		baris.add_child(teks)
		kartu.nama = _label("HudLabel", Palette.TEXT)
		kartu.nama.text = tr(data.nama)
		kartu.deskripsi = _label("TeksKecil", Palette.TEXT_2)
		kartu.deskripsi.text = tr(data.deskripsi)
		kartu.deskripsi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		teks.add_child(kartu.nama)
		teks.add_child(kartu.deskripsi)
		kartu.harga = _label("HudLabel", Palette.TEXT)
		kartu.harga.custom_minimum_size = Vector2(Config.BENGKEL_HARGA_LEBAR_PX, 0)
		kartu.harga.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		kartu.harga.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		baris.add_child(kartu.harga)
		var aksi: Control = _bangun_aksi(baris, "BENGKEL_DIMILIKI", "BENGKEL_BELI")
		kartu.label_dimiliki = aksi.get_node("LabelAksi") as Label
		kartu.tombol = aksi.get_node("TombolAksi") as TombolSentuh
		kartu.tombol.ditekan.connect(_saat_beli.bind(data.id))
		_kartu_upgrade.append(kartu)


## Slot aksi di kanan kartu: tombol (>= 42 px) atau label status di tempat yang sama, lebarnya tetap supaya kartu tidak melompat.
func _bangun_aksi(baris: HBoxContainer, kunci_label: String, kunci_tombol: String) -> Control:
	var slot: Control = Control.new()
	slot.custom_minimum_size = Vector2(Config.BENGKEL_TOMBOL_LEBAR_PX, Config.HUD_TOMBOL_TINGGI_PX)
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	baris.add_child(slot)
	var label: Label = _label("HudLabel", Palette.OK)
	label.name = "LabelAksi"
	label.text = tr(kunci_label)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	slot.add_child(label)
	var tombol: TombolSentuh = TombolSentuh.new()
	tombol.name = "TombolAksi"
	tombol.focus_mode = Control.FOCUS_NONE
	tombol.text = tr(kunci_tombol)
	tombol.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_gaya_aksi(tombol)
	slot.add_child(tombol)
	return slot


func _label(varian: StringName, warna: Color) -> Label:
	var label: Label = Label.new()
	label.theme_type_variation = varian
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override(&"font_color", warna)
	return label


func _kotak_kartu() -> StyleBoxFlat:
	return GayaHud.kotak(Palette.UI_PANEL, Palette.OUTLINE)


## Tombol aksi kartu: normal berbingkai `TEXT`, ditekan berbingkai `ACCENT`, nonaktif redup berbingkai `UI_PANEL_RAISED` dengan teks `TEXT_2`.
func _gaya_aksi(tombol: Button) -> void:
	GayaHud.terapkan_tombol(tombol)
	tombol.add_theme_stylebox_override(&"normal", GayaHud.kotak(Palette.UI_PANEL_RAISED, Palette.TEXT))
	tombol.add_theme_stylebox_override(&"hover", GayaHud.kotak(Palette.UI_PANEL_RAISED, Palette.TEXT))
	tombol.add_theme_stylebox_override(&"disabled", GayaHud.kotak(Palette.UI_PANEL, Palette.UI_PANEL_RAISED))
	tombol.add_theme_color_override(&"font_disabled_color", Palette.TEXT_2)


## "Hari berikutnya": aksi utama terisi `ACCENT` dengan teks gelap (kontras tinggi), selalu aktif.
func _gaya_utama(tombol: Button) -> void:
	var normal: StyleBoxFlat = GayaHud.kotak(Palette.ACCENT, Palette.OUTLINE)
	var ditekan: StyleBoxFlat = GayaHud.kotak(Palette.UI_PANEL_RAISED, Palette.ACCENT)
	for nama: StringName in [&"normal", &"hover", &"focus"]:
		tombol.add_theme_stylebox_override(nama, normal)
	for nama: StringName in [&"pressed", &"hover_pressed"]:
		tombol.add_theme_stylebox_override(nama, ditekan)
	for nama: StringName in [&"font_color", &"font_hover_color", &"font_focus_color"]:
		tombol.add_theme_color_override(nama, Palette.UI_BG)
	for nama: StringName in [&"font_pressed_color", &"font_hover_pressed_color"]:
		tombol.add_theme_color_override(nama, Palette.ACCENT)


## Margin layar: max(`BENGKEL_MARGIN_PX`, inset aman) tiap tepi (`ZonaAman.margin`).
func _terapkan_margin() -> void:
	if _batas == null:
		return
	_batas.add_theme_constant_override(&"margin_left", ZonaAman.margin(Config.BENGKEL_MARGIN_PX, _inset.awal_x))
	_batas.add_theme_constant_override(&"margin_right", ZonaAman.margin(Config.BENGKEL_MARGIN_PX, _inset.akhir_x))
	_batas.add_theme_constant_override(&"margin_top", ZonaAman.margin(Config.BENGKEL_MARGIN_PX, _inset.atas))
	_batas.add_theme_constant_override(&"margin_bottom", ZonaAman.margin(Config.BENGKEL_MARGIN_PX, _inset.bawah))


## Inset aman perangkat mobile; desktop dan headless: tidak mengubah inset (sama dengan `HalamanKoran`).
func _baca_zona_aman() -> void:
	if not OS.has_feature("mobile"):
		return
	var aman: Rect2i = DisplayServer.get_display_safe_area()
	atur_inset(ZonaAman.inset_game(aman, DisplayServer.window_get_size(), get_viewport().get_visible_rect().size))


# --- Untuk tes dan probe ---

## Tombol Servis komponen `id`, tombol Beli upgrade `id`, dan tombol "Hari berikutnya".
func tombol_servis(id: String) -> TombolSentuh:
	var kartu: KartuServis = _kartu_servis.get(id)
	return kartu.tombol if kartu != null else null


func tombol_beli(id: String) -> TombolSentuh:
	for kartu: KartuUpgrade in _kartu_upgrade:
		if kartu.data.id == id:
			return kartu.tombol
	return null


func tombol_hari_berikutnya() -> TombolSentuh:
	return _tombol_hari


## Semua tombol yang ada di layar (servis, beli, hari berikutnya), tampil atau tidak.
func semua_tombol() -> Array[TombolSentuh]:
	var hasil: Array[TombolSentuh] = []
	for id: String in Config.KONDISI_KOMPONEN:
		hasil.append((_kartu_servis[id] as KartuServis).tombol)
	for kartu: KartuUpgrade in _kartu_upgrade:
		hasil.append(kartu.tombol)
	hasil.append(_tombol_hari)
	return hasil


## Kartu servis komponen `id` (null bila asing).
func kartu_servis(id: String) -> KartuServis:
	return _kartu_servis.get(id)


## Kartu upgrade untuk id `id` (null bila tidak ada).
func kartu_upgrade(id: String) -> KartuUpgrade:
	for kartu: KartuUpgrade in _kartu_upgrade:
		if kartu.data.id == id:
			return kartu
	return null


## Teks saldo yang tampil, mis. "1.250".
func teks_saldo() -> String:
	return _angka_saldo.text


## Teks judul yang tampil.
func teks_judul() -> String:
	return tr(_judul.text)


## True bila pesan galat data upgrade tampil.
func galat_tampil() -> bool:
	return _galat.visible


## True bila catatan ongkos naik tampil, dan teksnya.
func ongkos_tampil() -> bool:
	return _catatan_ongkos.visible


func teks_ongkos() -> String:
	return _catatan_ongkos.text if _catatan_ongkos.visible else ""


## Jumlah kartu upgrade yang tampil.
func jumlah_upgrade_tampil() -> int:
	var n: int = 0
	for kartu: KartuUpgrade in _kartu_upgrade:
		if kartu.panel.visible:
			n += 1
	return n


## Semua teks yang tampil di layar (sesudah terjemahan), untuk tes: label dan tombol yang terlihat.
func teks_tampil() -> Array[String]:
	var hasil: Array[String] = []
	_kumpul_teks(_latar, hasil)
	return hasil


## Persegi semua kontrol yang tampil (label dan tombol) dalam koordinat viewport game, untuk tes tata letak.
func rect_tampil() -> Array[Rect2]:
	var hasil: Array[Rect2] = []
	_kumpul_rect(_latar, hasil)
	return hasil


func rect_isi() -> Rect2:
	return _isi.get_global_rect()


func rect_tombol_hari() -> Rect2:
	return _tombol_hari.get_global_rect()


func _kumpul_teks(simpul: Node, hasil: Array[String]) -> void:
	for anak: Node in simpul.get_children():
		if anak is Control and not (anak as Control).is_visible_in_tree():
			continue
		if anak is Label or anak is Button:
			hasil.append(tr(anak.get("text")))
		_kumpul_teks(anak, hasil)


func _kumpul_rect(simpul: Node, hasil: Array[Rect2]) -> void:
	for anak: Node in simpul.get_children():
		if anak is Control and not (anak as Control).is_visible_in_tree():
			continue
		if anak is Label or anak is Button or anak is KotakKondisi:
			hasil.append((anak as Control).get_global_rect())
		_kumpul_rect(anak, hasil)
