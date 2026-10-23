class_name LayarBengkel
extends CanvasLayer
## Layar bengkel tata C (DESIGN_SPEC 4 "Bengkel", GDD 12.3 dan 12.4, rule `ui-scenes`; AC-6 sampai AC-9 run ui1-komponen-bengkel bagian B, redesain README 3 butir 1 sampai 8, usulan; dinilai di HP).
## Perilaku sama dengan 6A1 (AC-16, AC-20, AC-25, AC-26 run fase6a1-bengkel-kondisi bagian B, K-1 dan K-4): tipis, `HariMain` memberi state kerja (saldo `koin` = koin save + koin hari ini,
## `sepeda` = kondisi akhir rute dan level tersimpan) dan daftar upgrade (`PemuatToko`); layar ini menampilkan dan, saat tombol ditekan, memanggil `Economy.servis` / `Economy.beli_upgrade`.
## Tidak menyimpan apa pun: simpan tepat sekali oleh `HariMain` saat "Hari berikutnya". Back Android = "Hari berikutnya" (`HariMain` lewat `MesinHari.aksi_back`). Tanpa tempat iklan (rule `privacy-ads`).
##
## Tampilan (angka dari kanvas lewat `Config.BENGKEL_*`; pemilihan keadaan di `TampilBengkel`, murni): latar bengkel 800 di tengah; judul "Bengkel" y 12 dan saldo (chip besar berikon koin) di
## baris atas; isi mulai y 46 dalam margin 12 atau inset aman. Kolom servis 48 % | 8 | upgrade. PANEL SERVIS: panggung sepeda (papan alat, sepeda 116x78, chip "! Ban" atau "Ban aus" di bagian
## yang bermasalah; sepeda baik bersih), tiga kartu servis 50 (ikon 24, nama, tiga kotak kondisi 8x8 + "!", teks status, chip harga di sebelah tombol; PERLU_BENGKEL = kartu menonjol, BAIK = redup),
## catatan ongkos naik (tempat tetap 12). KOLOM UPGRADE: satu kartu 62 per komponen (ikon 24 + chip tingkat, nama, deskripsi, chip harga + tombol Beli, atau chip "Dimiliki" dan kartu redup);
## komponen bertingkat (> 1 upgrade di data) tetap satu kartu bergaris jejak I, II, III (72). "Hari berikutnya" 140x42 SELALU aktif di kanan bawah. Tombol nonaktif rata, diarsir, teks alasan
## "Koin kurang"; menekannya lewat `pressed.emit()` tidak mengubah apa pun (Economy menolak atomik). Anchor + Container; teks hanya kunci terjemahan; warna dari `Palette`; komponen dari `GayaHud`.

## Tombol "Hari berikutnya" ditekan (atau back Android: `HariMain`).
signal hari_berikutnya_diminta
## Servis diterima: komponen dan harga yang dibayar.
signal servis_dilakukan(komponen: String, harga: int)
## Upgrade dibeli: id dan harga yang dibayar.
signal upgrade_dibeli(id: String, harga: int)

## Skrip autoload `Audio`, hanya untuk tipe (`Audio` tidak merujuk autoload lain, rule `gdscript`).
const SKRIP_AUDIO := preload("res://scripts/autoload/audio.gd")
const TEKSTUR_KOIN: Texture2D = preload("res://assets/sprites/ui/ui_icon_koin.png")


## Satu kartu servis komponen.
class KartuServis extends RefCounted:
	var komponen: String = ""
	var panel: PanelContainer = null
	var kotak: KotakKondisiBesar = null
	var nama: Label = null
	var tingkat: Label = null
	var chip_harga: ChipUi = null
	var harga: Label = null
	var tombol: TombolSentuh = null
	var chip_baik: ChipUi = null
	var label_baik: Label = null
	var info: TampilBengkel.InfoServis = null


## Satu kartu upgrade (satu per komponen; `data` = tingkat yang sedang tampil).
class KartuUpgrade extends RefCounted:
	var komponen: String = ""
	var tingkat_data: Array[DataToko] = []
	var data: DataToko = null
	var panel: PanelContainer = null
	var nama: Label = null
	var deskripsi: Label = null
	var chip_tingkat: ChipUi = null
	var baris_jejak: HBoxContainer = null
	var jejak: Array[ChipUi] = []
	var chip_harga: ChipUi = null
	var harga: Label = null
	var tombol: TombolSentuh = null
	var chip_dimiliki: ChipUi = null
	var label_dimiliki: Label = null
	var info: TampilBengkel.InfoUpgrade = null


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
@onready var _label_saldo: Label = %LabelSaldo
@onready var _chip_saldo: ChipUi = %ChipSaldo
@onready var _kolom: HBoxContainer = %Kolom
@onready var _panel_servis: PanelContainer = %PanelServis
@onready var _isi_servis: VBoxContainer = %IsiServis
@onready var _label_servis: Label = %LabelServis
@onready var _garis_servis: ColorRect = %GarisServis
@onready var _panggung: PanggungSepeda = %Panggung
@onready var _daftar_servis: VBoxContainer = %DaftarServis
@onready var _baris_catatan: HBoxContainer = %BarisCatatan
@onready var _glif_catatan: TextureRect = %GlifCatatan
@onready var _catatan_ongkos: Label = %CatatanOngkos
@onready var _kolom_upgrade: VBoxContainer = %KolomUpgrade
@onready var _label_upgrade: Label = %LabelUpgrade
@onready var _garis_upgrade: ColorRect = %GarisUpgrade
@onready var _panel_galat: PanelContainer = %PanelGalat
@onready var _glif_galat: TextureRect = %GlifGalat
@onready var _galat: Label = %Galat
@onready var _daftar_upgrade: VBoxContainer = %DaftarUpgrade
@onready var _tombol_hari: TombolSentuh = %TombolHariBerikutnya


func _ready() -> void:
	_audio = get_node_or_null(^"/root/Audio") as SKRIP_AUDIO
	_latar.color = Palette.UI_BG
	_latar.mouse_filter = Control.MOUSE_FILTER_STOP
	_kolom.add_theme_constant_override(&"separation", Config.BENGKEL_KOLOM_JARAK_PX)
	_isi_servis.add_theme_constant_override(&"separation", Config.BENGKEL_PANEL_JARAK_PX)
	_daftar_servis.add_theme_constant_override(&"separation", Config.BENGKEL_PANEL_JARAK_PX)
	_kolom_upgrade.add_theme_constant_override(&"separation", Config.BENGKEL_UPGRADE_JARAK_PX)
	_daftar_upgrade.add_theme_constant_override(&"separation", Config.BENGKEL_UPGRADE_JARAK_PX)
	_baris_atas.custom_minimum_size = Vector2(0, Config.BENGKEL_BARIS_ATAS_PX)
	_panggung.custom_minimum_size = Vector2(0, Config.BENGKEL_PANGGUNG_MIN_PX)
	_baris_catatan.custom_minimum_size = Vector2(0, Config.BENGKEL_CATATAN_TINGGI_PX)
	for bagian: Label in [_label_servis, _label_upgrade]:
		bagian.custom_minimum_size = Vector2(0, Config.BENGKEL_BAGIAN_TINGGI_PX)
		bagian.add_theme_color_override(&"font_color", Palette.ACCENT)
	var pelat: StyleBoxFlat = StyleBoxFlat.new()
	pelat.bg_color = Palette.HUD_PANEL
	pelat.content_margin_left = float(Config.BENGKEL_BAGIAN_PELAT_PAD_PX)
	pelat.content_margin_right = float(Config.BENGKEL_BAGIAN_PELAT_PAD_PX)
	_label_upgrade.add_theme_stylebox_override(&"normal", pelat)
	for garis: ColorRect in [_garis_servis, _garis_upgrade]:
		garis.color = Palette.UI_PANEL_RAISED
	_label_saldo.add_theme_color_override(&"font_color", Palette.TEXT_2)
	_judul.add_theme_color_override(&"font_color", Palette.TEXT)
	_galat.add_theme_color_override(&"font_color", Palette.TEXT)
	_catatan_ongkos.add_theme_color_override(&"font_color", Palette.TEXT_2)
	_glif_catatan.texture = GayaHud.tekstur("glif_seru_warn")
	_glif_galat.texture = GayaHud.tekstur("glif_seru_warn")
	_glif_galat.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var kotak_panel: StyleBoxTexture = GayaHud.panel_layar()
	kotak_panel.set_content_margin_all(float(Config.BENGKEL_PANEL_PAD_PX))
	_panel_servis.add_theme_stylebox_override(&"panel", kotak_panel)
	var kotak_galat: StyleBoxTexture = GayaHud.kartu_menonjol()
	kotak_galat.set_content_margin_all(float(Config.UI_PANEL_SLICE_PX + Config.BENGKEL_GALAT_PAD_PX))
	_panel_galat.add_theme_stylebox_override(&"panel", kotak_galat)
	GayaHud.tombol_utama(_tombol_hari)
	_tombol_hari.icon = GayaHud.tekstur("glif_panah_gelap")
	_tombol_hari.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_tombol_hari.add_theme_constant_override(&"h_separation", Config.UI_CHIP_JARAK_BESAR_PX)
	_tombol_hari.custom_minimum_size = Vector2(Config.BENGKEL_HARI_LEBAR_PX, Config.UI_TOMBOL_TINGGI_PX)
	_tombol_hari.ditekan.connect(hari_berikutnya_diminta.emit)
	for id: String in Config.KONDISI_KOMPONEN:
		_kartu_servis[id] = _bangun_kartu_servis(id)
	get_viewport().size_changed.connect(_baca_zona_aman)
	_baca_zona_aman()
	_susun()


## Mengisi layar dari state kerja `state` (`koin` = saldo, `sepeda` = kondisi dan level) dan data upgrade `toko`. Galat memuat data upgrade ditampilkan jujur dan daftar upgrade kosong; servis
## dan "Hari berikutnya" tetap bisa (K-4).
func isi(state: Dictionary, toko: PemuatToko.Kumpulan) -> void:
	_state = state.duplicate(true)
	_toko = toko if toko != null else PemuatToko.Kumpulan.new()
	_belanja_servis = 0
	_belanja_upgrade = 0
	_panel_galat.visible = not _toko.sah()
	_bangun_upgrade()
	_segarkan()
	_pulihkan_batas.call_deferred()


## State kerja saat ini (salinan): saldo sesudah belanja, kondisi, level, dan `servis_total`.
func state() -> Dictionary:
	return _state.duplicate(true)


## Koin yang sudah dibelanjakan sejak `isi` (servis dan upgrade).
func belanja_koin() -> int:
	return _belanja_servis + _belanja_upgrade


## Mengatur inset aman tepi layar (piksel game, `ZonaAman.inset_game`) lalu menata margin. Null = nol.
func atur_inset(inset: ZonaAman.Inset) -> void:
	_inset = inset if inset != null else ZonaAman.Inset.new()
	_susun()


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

## Menyegarkan semua baris dari `_state`: saldo, kondisi, harga, status tombol, kartu, dan penanda di sepeda.
func _segarkan() -> void:
	var pemisah: String = tr("HUD_PEMISAH_RIBUAN")
	var saldo: int = Economy.saldo(_state)
	_chip_saldo.atur(KomponenUi.GayaChip.GELAP, tr("BENGKEL_SALDO_ANGKA").format({"n": HasilRute.ribuan(saldo, pemisah)}), KomponenUi.UkuranChip.BESAR, "", TEKSTUR_KOIN)
	var kondisi: Dictionary = Economy.kondisi_dari(_state)
	var level: Dictionary = Economy.level_dari(_state)
	var rusak: int = BikeCondition.perlu_bengkel(kondisi).size()
	_panggung.atur_kondisi(kondisi)
	for id: String in Config.KONDISI_KOMPONEN:
		_segarkan_servis(_kartu_servis[id], float(kondisi[id]), saldo, pemisah)
	_baris_catatan_tampil(rusak)
	for kartu_u: KartuUpgrade in _kartu_upgrade:
		_segarkan_upgrade(kartu_u, int(level.get(kartu_u.komponen, 0)), saldo, pemisah)


func _segarkan_servis(kartu: KartuServis, c: float, saldo: int, pemisah: String) -> void:
	var info: TampilBengkel.InfoServis = TampilBengkel.servis(c, Economy.harga_servis_state(_state, kartu.komponen), saldo)
	kartu.info = info
	kartu.kotak.tampilkan(c, 0.0)
	kartu.nama.text = tr(TampilKondisi.kunci_nama(kartu.komponen))
	kartu.tingkat.visible = info.kunci_status != ""
	kartu.tingkat.text = tr(info.kunci_status) if info.kunci_status != "" else ""
	kartu.tingkat.add_theme_color_override(&"font_color", Palette.TEXT if TampilKondisi.tanda_seru(c) else Palette.TEXT_2)
	_gaya_kartu(kartu.panel, info.kartu, Config.BENGKEL_KARTU_PAD_AKHIR_PX + (Config.BENGKEL_KARTU_PAD_AKHIR_PX if info.penuh else 0))
	_tampil_chip(kartu.chip_baik, info.penuh)
	_tampil_chip(kartu.chip_harga, info.aksi != TampilBengkel.Aksi.TIDAK_ADA)
	kartu.tombol.visible = info.aksi != TampilBengkel.Aksi.TIDAK_ADA
	if info.aksi != TampilBengkel.Aksi.TIDAK_ADA:
		kartu.harga.text = tr("BENGKEL_HARGA_ANGKA").format({"n": HasilRute.ribuan(info.harga, pemisah)})
		_atur_tombol(kartu.tombol, info.aksi, TampilBengkel.KUNCI_AKSI_SERVIS, "glif_kunci_terang")


func _segarkan_upgrade(kartu: KartuUpgrade, level_dimiliki: int, saldo: int, pemisah: String) -> void:
	var tingkat: Array[int] = []
	var harga: Array[int] = []
	for d: DataToko in kartu.tingkat_data:
		tingkat.append(d.level)
		harga.append(d.harga)
	var info: TampilBengkel.InfoUpgrade = TampilBengkel.upgrade(tingkat, harga, level_dimiliki, saldo)
	kartu.info = info
	kartu.data = kartu.tingkat_data[info.indeks]
	kartu.nama.text = tr(kartu.data.nama)
	kartu.nama.add_theme_color_override(&"font_color", Palette.TEXT_2 if info.dimiliki else Palette.TEXT)
	kartu.deskripsi.text = tr(kartu.data.deskripsi)
	kartu.panel.custom_minimum_size = Vector2(0, info.tinggi)
	_gaya_kartu(kartu.panel, info.kartu, Config.BENGKEL_KARTU_PAD_AKHIR_PX + (Config.BENGKEL_KARTU_PAD_AKHIR_PX if info.dimiliki else 0))
	kartu.chip_tingkat.atur_status(info.status_tingkat, KomponenUi.UkuranChip.KECIL, tr(TampilBengkel.kunci_tingkat(info.tingkat)).format({"n": info.tingkat}))
	kartu.baris_jejak.visible = info.jejak_tampil
	for i: int in range(kartu.jejak.size()):
		var status: TampilBengkel.StatusJejak = info.jejak[i]
		var angka: String = tr(TampilBengkel.kunci_tingkat(tingkat[i])).format({"n": tingkat[i]})
		var glif: String = "glif_centang_teks2" if status == TampilBengkel.StatusJejak.DIMILIKI else ""
		kartu.jejak[i].atur(KomponenUi.chip(TampilBengkel.status_chip_jejak(status)).gaya, angka, KomponenUi.UkuranChip.KECIL, glif)
	_tampil_chip(kartu.chip_dimiliki, info.dimiliki)
	_tampil_chip(kartu.chip_harga, info.aksi != TampilBengkel.Aksi.TIDAK_ADA)
	kartu.tombol.visible = info.aksi != TampilBengkel.Aksi.TIDAK_ADA
	if info.aksi != TampilBengkel.Aksi.TIDAK_ADA:
		kartu.harga.text = tr("BENGKEL_HARGA_ANGKA").format({"n": HasilRute.ribuan(info.harga, pemisah)})
		_atur_tombol(kartu.tombol, info.aksi, TampilBengkel.KUNCI_AKSI_BELI, "")


## Catatan ongkos naik (GDD 12.3) bila >= 2 komponen PERLU_BENGKEL; tempatnya tetap supaya panel tidak melompat.
func _baris_catatan_tampil(rusak: int) -> void:
	var tampil: bool = rusak >= 2
	_glif_catatan.visible = tampil
	_catatan_ongkos.visible = tampil
	if tampil:
		_catatan_ongkos.text = tr("BENGKEL_ONGKOS_NAIK").format({"x": "%.2f" % Economy.pengali_ongkos(rusak)})


## Tombol aksi: aktif = tombol biasa dengan `glif` (nama dasar tekstur, "" = tanpa) dan teks aksi; nonaktif = rata, diarsir, teks alasan "Koin kurang" (terbaca tanpa warna).
func _atur_tombol(tombol: TombolSentuh, status: TampilBengkel.Aksi, kunci_aksi: String, glif: String) -> void:
	if status == TampilBengkel.Aksi.AKTIF:
		GayaHud.tombol_biasa(tombol)
		tombol.icon = GayaHud.tekstur(glif) if glif != "" else null
	else:
		GayaHud.tombol_nonaktif(tombol)
		tombol.icon = null
	tombol.text = tr(TampilBengkel.kunci_tombol(status, kunci_aksi))


## Kartu servis satu komponen: ikon 24, nama, tiga kotak kondisi + "!" dan teks status, lalu chip harga + tombol Servis atau chip "Baik".
func _bangun_kartu_servis(id: String) -> KartuServis:
	var kartu: KartuServis = KartuServis.new()
	kartu.komponen = id
	kartu.panel = PanelContainer.new()
	kartu.panel.name = "Servis_" + id
	kartu.panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kartu.panel.custom_minimum_size = Vector2(0, Config.BENGKEL_KARTU_SERVIS_PX)
	_daftar_servis.add_child(kartu.panel)
	var baris: HBoxContainer = _baris(Config.BENGKEL_KARTU_JARAK_PX)
	kartu.panel.add_child(baris)
	baris.add_child(_ikon(id))
	var teks: VBoxContainer = VBoxContainer.new()
	teks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	teks.add_theme_constant_override(&"separation", Config.BENGKEL_KARTU_TEKS_JARAK_SERVIS_PX)
	teks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	teks.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	baris.add_child(teks)
	kartu.nama = _label_potong(&"LayarTeksUtama", Palette.TEXT)
	teks.add_child(kartu.nama)
	# Kotak kondisi dan teks status sebaris bila muat; kolom sempit membuat teks status turun ke bawah kotak (tanpa pecah per huruf).
	var status: HFlowContainer = HFlowContainer.new()
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status.add_theme_constant_override(&"h_separation", Config.BENGKEL_KARTU_STATUS_JARAK_PX)
	status.add_theme_constant_override(&"v_separation", Config.BENGKEL_KARTU_STATUS_BARIS_PX)
	teks.add_child(status)
	kartu.kotak = KotakKondisiBesar.new()
	kartu.kotak.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	status.add_child(kartu.kotak)
	kartu.tingkat = _label(&"LayarTeksMini", Palette.TEXT_2)
	kartu.tingkat.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	status.add_child(kartu.tingkat)
	var aksi: HBoxContainer = _baris(Config.BENGKEL_KARTU_JARAK_PX)
	aksi.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	baris.add_child(aksi)
	kartu.chip_harga = _chip_harga()
	kartu.harga = kartu.chip_harga.label()
	aksi.add_child(kartu.chip_harga)
	kartu.tombol = _tombol_aksi()
	kartu.tombol.ditekan.connect(_saat_servis.bind(id))
	aksi.add_child(kartu.tombol)
	kartu.chip_baik = ChipUi.new()
	kartu.chip_baik.atur_status(KomponenUi.StatusChip.BAIK)
	kartu.label_baik = kartu.chip_baik.label()
	aksi.add_child(kartu.chip_baik)
	return kartu


## Kartu upgrade dari data `toko` (dibangun ulang tiap `isi`): satu kartu per komponen, tingkat urut naik.
func _bangun_upgrade() -> void:
	for kartu: KartuUpgrade in _kartu_upgrade:
		kartu.panel.queue_free()
		_daftar_upgrade.remove_child(kartu.panel)
	_kartu_upgrade = []
	for id: String in Config.KONDISI_KOMPONEN:
		var tingkat: Array[DataToko] = []
		for data: DataToko in _toko.upgrade:
			if data.komponen == id:
				tingkat.append(data)
		tingkat.sort_custom(func(a: DataToko, b: DataToko) -> bool: return a.level < b.level)
		if not tingkat.is_empty():
			_kartu_upgrade.append(_bangun_kartu_upgrade(id, tingkat))


func _bangun_kartu_upgrade(id: String, tingkat: Array[DataToko]) -> KartuUpgrade:
	var kartu: KartuUpgrade = KartuUpgrade.new()
	kartu.komponen = id
	kartu.tingkat_data = tingkat
	kartu.data = tingkat[0]
	kartu.panel = PanelContainer.new()
	kartu.panel.name = "Upgrade_" + id
	kartu.panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_daftar_upgrade.add_child(kartu.panel)
	var baris: HBoxContainer = _baris(Config.BENGKEL_KARTU_JARAK_PX)
	kartu.panel.add_child(baris)
	var kolom_ikon: VBoxContainer = VBoxContainer.new()
	kolom_ikon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kolom_ikon.add_theme_constant_override(&"separation", Config.BENGKEL_KARTU_TEKS_JARAK_UPGRADE_PX)
	kolom_ikon.alignment = BoxContainer.ALIGNMENT_CENTER
	kolom_ikon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	baris.add_child(kolom_ikon)
	kolom_ikon.add_child(_ikon(id))
	kartu.chip_tingkat = ChipUi.new()
	kartu.chip_tingkat.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	kolom_ikon.add_child(kartu.chip_tingkat)
	var teks: VBoxContainer = VBoxContainer.new()
	teks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	teks.add_theme_constant_override(&"separation", Config.BENGKEL_KARTU_TEKS_JARAK_UPGRADE_PX)
	teks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	teks.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	baris.add_child(teks)
	kartu.nama = _label_potong(&"LayarTeksUtama", Palette.TEXT)
	teks.add_child(kartu.nama)
	kartu.deskripsi = _label(&"LayarTeksKecil", Palette.TEXT_2)
	kartu.deskripsi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	kartu.deskripsi.max_lines_visible = Config.BENGKEL_DESKRIPSI_BARIS_MAKS
	kartu.deskripsi.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	teks.add_child(kartu.deskripsi)
	kartu.baris_jejak = _baris(Config.BENGKEL_JEJAK_JARAK_PX)
	teks.add_child(kartu.baris_jejak)
	for i: int in range(tingkat.size()):
		var chip: ChipUi = ChipUi.new()
		kartu.baris_jejak.add_child(chip)
		kartu.jejak.append(chip)
	var aksi: HBoxContainer = _baris(Config.BENGKEL_KARTU_JARAK_PX)
	aksi.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	baris.add_child(aksi)
	kartu.chip_harga = _chip_harga()
	kartu.harga = kartu.chip_harga.label()
	aksi.add_child(kartu.chip_harga)
	kartu.tombol = _tombol_aksi()
	kartu.tombol.ditekan.connect(_saat_beli_komponen.bind(kartu))
	aksi.add_child(kartu.tombol)
	kartu.chip_dimiliki = ChipUi.new()
	kartu.chip_dimiliki.atur_status(KomponenUi.StatusChip.DIMILIKI)
	kartu.label_dimiliki = kartu.chip_dimiliki.label()
	aksi.add_child(kartu.chip_dimiliki)
	return kartu


# Membeli tingkat yang sedang tampil pada kartu (id data dari `kartu.data`).
func _saat_beli_komponen(kartu: KartuUpgrade) -> void:
	_saat_beli(kartu.data.id)


func _baris(jarak: int) -> HBoxContainer:
	var baris: HBoxContainer = HBoxContainer.new()
	baris.mouse_filter = Control.MOUSE_FILTER_IGNORE
	baris.add_theme_constant_override(&"separation", jarak)
	return baris


func _ikon(id: String) -> TextureRect:
	var gambar: TextureRect = TextureRect.new()
	gambar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gambar.texture = GayaHud.tekstur("icon24_" + id)
	gambar.custom_minimum_size = Vector2(Config.BENGKEL_IKON_PX, Config.BENGKEL_IKON_PX)
	gambar.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	gambar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return gambar


func _chip_harga() -> ChipUi:
	var chip: ChipUi = ChipUi.new()
	chip.atur(KomponenUi.GayaChip.GELAP, "", KomponenUi.UkuranChip.NORMAL, "", TEKSTUR_KOIN)
	return chip


func _tombol_aksi() -> TombolSentuh:
	var tombol: TombolSentuh = TombolSentuh.new()
	tombol.focus_mode = Control.FOCUS_NONE
	tombol.custom_minimum_size = Vector2(Config.UI_TOMBOL_LEBAR_MIN_PX, Config.UI_TOMBOL_TINGGI_PX)
	tombol.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tombol.add_theme_constant_override(&"h_separation", Config.UI_CHIP_JARAK_BESAR_PX)
	GayaHud.tombol_biasa(tombol)
	return tombol


## Label satu baris yang dipotong dengan elipsis bila kolomnya sempit (QA-001): lebar minimumnya tidak mengikuti teks, jadi nama panjang tidak melebarkan kartu, kolom, atau `Isi`.
func _label_potong(varian: StringName, warna: Color) -> Label:
	var label: Label = _label(varian, warna)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.clip_text = true
	return label


func _label(varian: StringName, warna: Color) -> Label:
	var label: Label = Label.new()
	label.theme_type_variation = varian
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override(&"font_color", warna)
	return label


# Chip dan labelnya tampil atau tersembunyi bersama (label.visible dibaca tes).
func _tampil_chip(chip: ChipUi, nilai: bool) -> void:
	chip.visible = nilai
	chip.label().visible = nilai


# Kartu 9-slice menurut jenis; isi berjarak kiri `BENGKEL_KARTU_PAD_AWAL_PX` (garis + padding) dan kanan `pad_akhir`.
func _gaya_kartu(panel: PanelContainer, jenis: KomponenUi.JenisKartu, pad_akhir: int) -> void:
	var kotak: StyleBoxTexture = GayaHud.kartu(jenis)
	kotak.content_margin_left = float(Config.BENGKEL_KARTU_PAD_AWAL_PX)
	kotak.content_margin_right = float(pad_akhir)
	panel.add_theme_stylebox_override(&"panel", kotak)


## Margin layar: max(`BENGKEL_MARGIN_PX`, inset aman) tiap tepi (`ZonaAman.margin`), lebar kolom servis dan upgrade, dan letak tombol "Hari berikutnya" (kanan bawah, di dalam margin).
func _susun() -> void:
	if _batas == null or not is_inside_tree():
		return
	var awal: int = ZonaAman.margin(Config.BENGKEL_MARGIN_PX, _inset.awal_x)
	var akhir: int = ZonaAman.margin(Config.BENGKEL_MARGIN_PX, _inset.akhir_x)
	var atas: int = ZonaAman.margin(Config.BENGKEL_MARGIN_PX, _inset.atas)
	var bawah: int = ZonaAman.margin(Config.BENGKEL_MARGIN_PX, _inset.bawah)
	_batas.add_theme_constant_override(&"margin_left", awal)
	_batas.add_theme_constant_override(&"margin_right", akhir)
	_batas.add_theme_constant_override(&"margin_top", atas)
	_batas.add_theme_constant_override(&"margin_bottom", bawah)
	var lebar: int = int(get_viewport().get_visible_rect().size.x)
	var kolom: Vector2i = TampilBengkel.lebar_kolom(lebar - awal - akhir)
	_panel_servis.custom_minimum_size = Vector2(kolom.x, 0)
	_tombol_hari.offset_right = -float(akhir)
	_tombol_hari.offset_left = -float(akhir + Config.BENGKEL_HARI_LEBAR_PX)
	_tombol_hari.offset_bottom = -float(bawah)
	_tombol_hari.offset_top = -float(bawah + Config.UI_TOMBOL_TINGGI_PX)
	_batas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


# Label berbungkus kata yang baru tampil sempat menghitung tinggi dengan lebar 0 (satu huruf per baris); `Batas` lalu membesar dan Control menyimpan ukuran besar itu di offsetnya walau tinggi
# minimum sudah turun lagi (isi bergeser ke atas layar). Menegakkan lagi persegi penuh sesudah tata letak selesai.
func _pulihkan_batas() -> void:
	_batas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Inset aman perangkat mobile; desktop dan headless: tidak mengubah inset (sama dengan `HalamanKoran`).
func _baca_zona_aman() -> void:
	if not OS.has_feature("mobile"):
		_susun()
		return
	var aman: Rect2i = DisplayServer.get_display_safe_area()
	atur_inset(ZonaAman.inset_game(aman, DisplayServer.window_get_size(), get_viewport().get_visible_rect().size))


# --- Untuk tes dan probe ---

## Tombol Servis komponen `id`, tombol Beli upgrade `id` (hanya untuk tingkat yang sedang tampil pada kartunya), dan tombol "Hari berikutnya".
func tombol_servis(id: String) -> TombolSentuh:
	var kartu: KartuServis = _kartu_servis.get(id)
	return kartu.tombol if kartu != null else null


func tombol_beli(id: String) -> TombolSentuh:
	var kartu: KartuUpgrade = kartu_upgrade(id)
	return kartu.tombol if kartu != null and kartu.data.id == id else null


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


## Kartu upgrade yang memuat upgrade dengan id `id` (tingkat mana pun komponennya; null bila tidak ada). `kartu.data` = tingkat yang sedang tampil.
func kartu_upgrade(id: String) -> KartuUpgrade:
	for kartu: KartuUpgrade in _kartu_upgrade:
		for data: DataToko in kartu.tingkat_data:
			if data.id == id:
				return kartu
	return null


## Kartu upgrade komponen `komponen` (ban, rem, rantai); null bila data upgrade komponen itu tidak ada.
func kartu_upgrade_komponen(komponen: String) -> KartuUpgrade:
	for kartu: KartuUpgrade in _kartu_upgrade:
		if kartu.komponen == komponen:
			return kartu
	return null


## Panggung sepeda (untuk tes dan probe: persegi sepeda dan chip penanda).
func panggung() -> PanggungSepeda:
	return _panggung


## Teks saldo yang tampil, mis. "1.250".
func teks_saldo() -> String:
	return _chip_saldo.teks()


## Teks judul yang tampil.
func teks_judul() -> String:
	return tr(_judul.text)


## True bila pesan galat data upgrade tampil.
func galat_tampil() -> bool:
	return _panel_galat.visible


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


## Persegi semua kontrol yang tampil (label, tombol, kotak kondisi) dalam koordinat viewport game, untuk tes tata letak.
func rect_tampil() -> Array[Rect2]:
	var hasil: Array[Rect2] = []
	_kumpul_rect(_latar, hasil)
	return hasil


func rect_isi() -> Rect2:
	return _isi.get_global_rect()


## Persegi panel servis dan kolom upgrade (koordinat viewport game).
func rect_panel_servis() -> Rect2:
	return _panel_servis.get_global_rect()


func rect_kolom_upgrade() -> Rect2:
	return _kolom_upgrade.get_global_rect()


## Persegi semua chip (harga, Baik, Dimiliki, tingkat, jejak, saldo) yang tampil, dan persegi kartu pemiliknya (kartu servis dan upgrade), untuk tes tata letak.
func rect_kartu() -> Array[Rect2]:
	var hasil: Array[Rect2] = []
	for id: String in Config.KONDISI_KOMPONEN:
		var kartu: KartuServis = _kartu_servis[id]
		if kartu.panel.is_visible_in_tree():
			hasil.append(kartu.panel.get_global_rect())
	for kartu_u: KartuUpgrade in _kartu_upgrade:
		if kartu_u.panel.is_visible_in_tree():
			hasil.append(kartu_u.panel.get_global_rect())
	return hasil


## Chip yang tampil di dalam kartu `panel`, persegi globalnya.
func rect_chip_di(panel: Control) -> Array[Rect2]:
	var hasil: Array[Rect2] = []
	for chip: Node in panel.find_children("*", "ChipUi", true, false):
		if (chip as ChipUi).is_visible_in_tree():
			hasil.append((chip as ChipUi).get_global_rect())
	return hasil


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
		if anak is Label or anak is Button or anak is KotakKondisiBesar:
			hasil.append((anak as Control).get_global_rect())
		_kumpul_rect(anak, hasil)
