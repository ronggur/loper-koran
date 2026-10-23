class_name HudRute
extends HudDasar
## HUD rute final (DESIGN_SPEC 3; AC-5, AC-7 sampai AC-9 run fase3c-hud-hasil, O-6 sampai O-8, usulan). Menggantikan HUD dev 3B di scene
## rute. Bagian bersama (tombol jeda kiri atas, panel bawah kecepatan/stamina/koran yang dicerminkan saat kidal, tombol bel) dari
## `HudDasar`. Tambahan:
## - Radar (DESIGN_SPEC 3.4): strip `RadarSeberang` di tepi x 0 dan `RadarDekat` di tepi x lebar, x `RADAR_TEPI_PX`, lebar
##   `RADAR_LEBAR_PX`, y `RADAR_Y_ATAS_PX` sampai `RADAR_Y_BAWAH_PX`. Strip mengikuti sisi dunia: kidal tidak menukar (K-2, AC-4).
## - Panel progres tengah atas (DESIGN_SPEC 3.2, O-8): lebar `HUD_PROGRES_LEBAR_PX`, y `HUD_MARGIN_TEPI_PX`. Baris atas: tenggat di kiri
##   (`HUD_WAKTU` + "1:32" sisa; sesudah lewat `HUD_LEWAT` + "+0:12" berwarna `WARN`: teks berubah, bukan warna saja) dan
##   `HUD_TERKIRIM_ANGKA` "3/25 TERKIRIM" (`ACCENT`) di kanan. Baris bawah: `KotakProgres` (25 kotak, status dari `ProgresRute`, O-12).
## - Panel kanan atas (DESIGN_SPEC 3.3, O-7): tepi kanan `HUD_KANAN_MARGIN_PX` dari tepi layar, y `HUD_MARGIN_TEPI_PX`, dua panel berjarak
##   `HUD_PANEL_JARAK_PX`: koin (ikon `ui_icon_koin` 14 + angka berpemisah ribuan "1.250") lalu skor/combo di slot reputasi (Fase 6). Saat
##   combo putus label `HUD_COMBO` berganti `HUD_COMBO_PUTUS` (`FAIL`) selama label PUTUS tampil, di samping pengali x1.0 (label 3B tetap,
##   lebar panel tidak melompat). Tidak dicerminkan saat kidal (strip atas bukan zona kontrol).
## - Semua panel memakai 9-slice `ui_panel_hud_9slice.png` (`GayaHud.panel_hud`, DESIGN_SPEC 1.3). Tidak ada tombol dev (Kidal, Bantu,
##   Main lagi) di strip atas: Kidal dan Bantu ada di layar jeda (O-6), Main lagi di layar hasil (O-11).
## - Zona aman (AC-9): di perangkat mobile inset dari `DisplayServer.get_display_safe_area()` dibaca saat siap dan saat ukuran viewport
##   berubah (`ZonaAman.inset_game`), lalu tiap tepi digeser sama besar (`HudDasar`). Di desktop/editor inset nol (persegi aman desktop
##   adalah layar monitor, bukan jendela game). Tes memberi inset tiruan lewat `atur_inset`.
## - Baris 2 kanan atas = kondisi sepeda (DESIGN_SPEC 3.3, run fase6a1-bengkel-kondisi bagian B, AC-22 dan AC-23, usulan): satu panel 5 px di bawah baris koin/skor (satu `VBoxContainer`
##   bersama baris 1), berisi `KotakKondisi` ban, rem, rantai (ikon 14 px + tiga kotak 5x5 + tanda "!" `WARN` untuk PERLU_BENGKEL; ikon bergetar dan kotak terisi `WARN` selama peringatan).
##   Hanya menampilkan `KondisiRute.Keadaan`; tidak menerima sentuhan; ikut zona aman bersama baris 1; tidak dicerminkan saat kidal. Panel ini berpotongan dengan zona swipe (y >= 48) tetapi
##   tidak menangkap sentuhan (seperti panel koran, DESIGN_SPEC 3.5): swipe yang dimulai di atasnya tetap melempar.
## - Baris 3 kanan atas = penanda reputasi (DESIGN_SPEC 3.3, run fase6a2-reputasi-pelanggan bagian C, O-10, AC-13 dan AC-14, usulan): satu panel 9-slice di bawah panel kondisi, jarak 5, rata kanan dengannya
##   (tepi kanan 28 + geseran zona aman), berisi ikon `ui_icon_reputasi` 14 px dan angka bulat 0..100 (reputasi Perumahan dari save; berubah hanya di akhir hari, jadi di rute nilainya tetap). Hanya ada bila rute
##   punya keadaan pelanggan (`tampilkan_reputasi` >= 0); tidak menerima sentuhan; tidak dicerminkan saat kidal. Kolom kanan atas tetap di sebelah kanan panel progres dan di dalam strip radar kanan.
## - Kartu misi (DESIGN_SPEC 3.1, run fase4b-misi-kucing, usulan): kiri atas DI BAWAH area sentuh jeda (x `MISI_KARTU_X_PX`, y `MISI_KARTU_Y_PX`, bukan di y 40
##   seperti sketsa karena area sentuh jeda berakhir di y 46): label `MISI_LABEL_KARTU` (`ACCENT`) dan "Kucing 0/1 · 8 rumah" (`MISI_KARTU`). Hanya ada
##   selama misi aktif; saat selesai atau gagal berganti banner `MISI_BANNER_DETIK` (tengah atas di bawah panel progres; hadiah "+75" pada banner
##   selesai) lalu hilang. Petunjuk dari pelanggan tampil sebagai gelembung teks di slot banner yang sama (tidak pernah bersamaan dengan banner).
##   Semuanya hanya menampilkan keadaan `MissionManager`, tidak menerima sentuhan, dan ikut zona aman. Tidak dicerminkan saat kidal.
## Semua angka dari logika murni; HUD hanya menampilkan. Tidak menerima sentuhan kecuali tombol jeda.

var _skor_terakhir: Array = []
var _tenggat_terakhir: Vector2i = Vector2i(-1, -1)
var _terkirim_terakhir: Vector2i = Vector2i(-1, -1)
## Isi misi terakhir yang disusun (kartu, banner, petunjuk): teks hanya disusun ulang bila berubah (tanpa alokasi per frame).
var _kartu_terakhir: Array = []
var _banner_terakhir: Array = []
var _petunjuk_terakhir: String = ""
## Reputasi yang sedang tampil (-1 = penanda tersembunyi).
var _reputasi_terakhir: int = -1

@onready var _radar_seberang: RadarStrip = %RadarSeberang
@onready var _radar_dekat: RadarStrip = %RadarDekat
@onready var _strip_progres: MarginContainer = %StripProgres
@onready var _panel_progres: PanelContainer = %PanelProgres
@onready var _label_waktu: Label = %LabelWaktu
@onready var _angka_waktu: Label = %AngkaWaktu
@onready var _angka_terkirim: Label = %AngkaTerkirim
@onready var _kotak_progres: KotakProgres = %KotakProgres
@onready var _strip_kanan: MarginContainer = %StripKanan
@onready var _baris_kanan: HBoxContainer = %BarisKanan
@onready var _panel_koin: PanelContainer = %PanelKoin
@onready var _ikon_koin: TextureRect = %IkonKoin
@onready var _angka_koin: Label = %AngkaKoin
@onready var _panel_skor: PanelContainer = %PanelSkor
@onready var _panel_kondisi: PanelContainer = %PanelKondisi
@onready var _kotak_kondisi: Dictionary = {"ban": %KotakBan, "rem": %KotakRem, "rantai": %KotakRantai}
@onready var _panel_reputasi: PanelContainer = %PanelReputasi
@onready var _ikon_reputasi: TextureRect = %IkonReputasi
@onready var _angka_reputasi: Label = %AngkaReputasi
@onready var _label_skor: Label = %LabelSkor
@onready var _angka_skor: Label = %AngkaSkor
@onready var _label_combo: Label = %LabelCombo
@onready var _label_putus: Label = %LabelPutus
@onready var _angka_combo: Label = %AngkaCombo
@onready var _penanda_kucing: PenandaKucing = %PenandaKucing
@onready var _strip_misi: MarginContainer = %StripMisi
@onready var _panel_misi: PanelContainer = %PanelMisi
@onready var _label_misi: Label = %LabelMisi
@onready var _isi_misi: Label = %IsiMisi
@onready var _strip_banner: MarginContainer = %StripBanner
@onready var _panel_banner: PanelContainer = %PanelBanner
@onready var _teks_banner: Label = %TeksBanner
@onready var _panel_petunjuk: PanelContainer = %PanelPetunjuk
@onready var _teks_petunjuk: Label = %TeksPetunjuk


func _ready() -> void:
	_radar_seberang.sisi = LoperAnim.Sisi.SEBERANG
	_radar_dekat.sisi = LoperAnim.Sisi.DEKAT
	_panel_progres.custom_minimum_size = Vector2(Config.HUD_PROGRES_LEBAR_PX, 0)
	_panel_skor.custom_minimum_size = Vector2(Config.HUD_SKOR_LEBAR_PX, 0)
	_ikon_koin.custom_minimum_size = Vector2(Config.HUD_IKON_PX, Config.HUD_IKON_PX)
	_ikon_reputasi.custom_minimum_size = Vector2(Config.HUD_IKON_PX, Config.HUD_IKON_PX)
	_baris_kanan.add_theme_constant_override(&"separation", Config.HUD_PANEL_JARAK_PX)
	(%KolomKanan as VBoxContainer).add_theme_constant_override(&"separation", Config.HUD_PANEL_JARAK_PX)
	(%IsiKondisi as HBoxContainer).add_theme_constant_override(&"separation", Config.KONDISI_HUD_ANTAR_KOMPONEN_PX)
	_panel_misi.custom_minimum_size = Vector2(Config.MISI_KARTU_LEBAR_PX, 0)
	_teks_petunjuk.custom_minimum_size = Vector2(Config.MISI_PETUNJUK_LEBAR_PX, 0)
	_terapkan_gaya()
	super()
	tampilkan_skor(0, 0, 0, false)
	var awal: TenggatRute.Keadaan = TenggatRute.Keadaan.new()
	tampilkan_tenggat(awal)
	tampilkan_progres([] as Array[ProgresRute.Status], 0, 0)
	_baca_zona_aman()
	get_viewport().size_changed.connect(_baca_zona_aman)


## Menampilkan skor (pemisah ribuan), pengali combo untuk antaran berikutnya, koin (pemisah ribuan), dan label PUTUS. Diperbarui hanya
## bila berubah.
func tampilkan_skor(skor: int, beruntun: int, koin: int, putus: bool) -> void:
	var kunci: Array = [skor, beruntun, koin, putus]
	if kunci == _skor_terakhir:
		return
	_skor_terakhir = kunci
	var pemisah: String = tr("HUD_PEMISAH_RIBUAN")
	_angka_skor.text = tr("HUD_SKOR_ANGKA").format({"n": HasilRute.ribuan(skor, pemisah)})
	_angka_combo.text = tr("HUD_COMBO_ANGKA").format({"x": "%.1f" % SkorRute.pengali_combo(beruntun)})
	_angka_koin.text = tr("HUD_KOIN_ANGKA").format({"n": HasilRute.ribuan(koin, pemisah)})
	_label_putus.visible = putus
	_label_combo.visible = not putus


## Menampilkan kondisi sepeda (baris 2 kanan atas, DESIGN_SPEC 3.3; AC-22, AC-23): tiga komponen dengan kotak, tanda "!" untuk PERLU_BENGKEL, dan ikon bergetar selama peringatan. Null =
## tanpa kondisi: panel tersembunyi.
func tampilkan_kondisi(k: KondisiRute.Keadaan) -> void:
	_panel_kondisi.visible = k != null
	if k == null:
		return
	for id: String in Config.KONDISI_KOMPONEN:
		var kotak: KotakKondisi = _kotak_kondisi[id]
		kotak.tampilkan(float(k.kondisi.get(id, 1.0)), float(k.kedip.get(id, 0.0)))


## Menampilkan reputasi distrik (baris 3 kanan atas): angka bulat dijepit 0..100; negatif = penanda tersembunyi (rute tanpa keadaan pelanggan). Diperbarui hanya bila berubah.
func tampilkan_reputasi(nilai: int) -> void:
	var kunci: int = -1 if nilai < 0 else clampi(nilai, Config.REPUTASI_MIN, Config.REPUTASI_MAKS)
	if kunci == _reputasi_terakhir:
		return
	_reputasi_terakhir = kunci
	_panel_reputasi.visible = kunci >= 0
	if kunci >= 0:
		_angka_reputasi.text = tr("HUD_REPUTASI_ANGKA").format({"n": kunci})


## True bila penanda reputasi tampil.
func reputasi_tampil() -> bool:
	return _panel_reputasi.visible


## Teks penanda reputasi ("" bila tersembunyi).
func teks_reputasi() -> String:
	return _angka_reputasi.text if _panel_reputasi.visible else ""


## Persegi panel reputasi dalam koordinat viewport game (tes tata letak).
func rect_panel_reputasi() -> Rect2:
	return _panel_reputasi.get_global_rect()


## Satu komponen di panel kondisi (untuk tes dan probe).
func kotak_kondisi(komponen: String) -> KotakKondisi:
	return _kotak_kondisi.get(komponen, null) as KotakKondisi


## Persegi panel kondisi (baris 2 kanan atas) dalam koordinat viewport game (tes tata letak).
func rect_panel_kondisi() -> Rect2:
	return _panel_kondisi.get_global_rect()


## True bila panel kondisi tampil.
func kondisi_tampil() -> bool:
	return _panel_kondisi.visible


## Menampilkan tenggat (O-8): sisa "WAKTU m:ss" sebelum lewat, "LEWAT +m:ss" berwarna `WARN` sesudahnya.
func tampilkan_tenggat(k: TenggatRute.Keadaan) -> void:
	var lewat: bool = TenggatRute.lewat(k)
	var detik: int = TenggatRute.detik_tampil(k)
	var kunci: Vector2i = Vector2i(detik, 1 if lewat else 0)
	if kunci == _tenggat_terakhir:
		return
	_tenggat_terakhir = kunci
	var md: Vector2i = TenggatRute.menit_detik(detik)
	var isi: Dictionary = {"m": md.x, "s": "%02d" % md.y}
	_label_waktu.text = tr("HUD_LEWAT" if lewat else "HUD_WAKTU")
	_angka_waktu.text = tr("HUD_LEWAT_ANGKA" if lewat else "HUD_WAKTU_ANGKA").format(isi)
	_label_waktu.add_theme_color_override(&"font_color", Palette.WARN if lewat else Palette.TEXT_2)
	_angka_waktu.add_theme_color_override(&"font_color", Palette.WARN if lewat else Palette.TEXT)


## Menampilkan kotak progres (`ProgresRute.status`) dan "n/total TERKIRIM".
func tampilkan_progres(status: Array[ProgresRute.Status], terkirim: int, total: int) -> void:
	_kotak_progres.tampilkan(status)
	var kunci: Vector2i = Vector2i(terkirim, total)
	if kunci == _terkirim_terakhir:
		return
	_terkirim_terakhir = kunci
	_angka_terkirim.text = tr("HUD_TERKIRIM_ANGKA").format({"n": terkirim, "total": total})


## Menampilkan penanda radar (`RadarRute.penanda`); tiap strip mengambil sisinya.
func tampilkan_radar(daftar: Array[RadarRute.Penanda]) -> void:
	_radar_seberang.tampilkan(daftar)
	_radar_dekat.tampilkan(daftar)


## Menampilkan misi dari keadaan `k` (`MissionManager`, null = tanpa misi: semuanya tersembunyi) dengan data `misi`: kartu "Kucing 0/1 · 8 rumah" selama aktif,
## banner hasil sesudah selesai atau gagal, gelembung petunjuk dari pelanggan selama `petunjuk_sisa`.
func tampilkan_misi(k: MissionManager.Keadaan, misi: DataMisi) -> void:
	var ada: bool = k != null and misi != null
	var kartu: bool = ada and MissionManager.kartu_tampil(k)
	var banner: bool = ada and MissionManager.banner_tampil(k)
	var petunjuk: bool = ada and MissionManager.petunjuk_tampil(k)
	_strip_misi.visible = kartu
	_panel_banner.visible = banner
	_panel_petunjuk.visible = petunjuk
	if not kartu:
		_kartu_terakhir = []
	if not banner:
		_banner_terakhir = []
	if not petunjuk:
		_petunjuk_terakhir = ""
	if kartu:
		var ditemukan: Vector2i = MissionManager.ditemukan(k)
		var kunci_kartu: Array = [ditemukan, MissionManager.sisa_rumah(k)]
		if kunci_kartu != _kartu_terakhir:
			_kartu_terakhir = kunci_kartu
			_isi_misi.text = tr("MISI_KARTU").format({"label": tr(misi.hud), "n": ditemukan.x, "total": ditemukan.y, "rumah": MissionManager.sisa_rumah(k)})
	if banner:
		var kunci_banner: Array = [k.status, MissionManager.koin_misi(k)]
		if kunci_banner != _banner_terakhir:
			_banner_terakhir = kunci_banner
			if k.status == MissionManager.Status.SELESAI:
				_teks_banner.text = tr("MISI_BANNER_HADIAH").format({"teks": tr(misi.banner_selesai), "koin": MissionManager.koin_misi(k)})
			else:
				_teks_banner.text = tr(misi.banner_gagal)
			_teks_banner.add_theme_color_override(&"font_color", Palette.OK if k.status == MissionManager.Status.SELESAI else Palette.TEXT)
	if petunjuk:
		var kunci_petunjuk: String = str(misi.petunjuk.get("dari_pelanggan", ""))
		if kunci_petunjuk != _petunjuk_terakhir:
			_petunjuk_terakhir = kunci_petunjuk
			_teks_petunjuk.text = tr(kunci_petunjuk)


## Area layar tempat badan kucing misi dan penanda tepi layar boleh berada (`TampilMisi.area`), dari ukuran viewport dan inset zona aman terpasang.
func area_misi() -> Rect2:
	var ukuran: Vector2 = get_viewport().get_visible_rect().size
	return TampilMisi.area(ukuran.x, ukuran.y, geser_awal_x(), geser_atas(), geser_akhir_x())


## Menampilkan penanda tepi layar kucing misi (`TampilMisi.penanda_aktif`; kosong = tidak ada) pada waktu animasi `detik`.
func tampilkan_penanda_kucing(daftar: Array[TampilMisi.Penanda], detik: float) -> void:
	_penanda_kucing.tampilkan(daftar, detik)


## Penanda tepi layar kucing yang sedang tampil (untuk tes dan probe).
func penanda_kucing() -> PenandaKucing:
	return _penanda_kucing


## Teks kartu misi yang tampil ("" bila kartu tersembunyi).
func teks_kartu() -> String:
	return _isi_misi.text if _strip_misi.visible else ""


## Teks banner hasil misi ("" bila tersembunyi).
func teks_banner() -> String:
	return _teks_banner.text if _panel_banner.visible else ""


## Teks gelembung petunjuk ("" bila tersembunyi).
func teks_petunjuk() -> String:
	return _teks_petunjuk.text if _panel_petunjuk.visible else ""


func kartu_tampil() -> bool:
	return _strip_misi.visible


func banner_tampil() -> bool:
	return _panel_banner.visible


func petunjuk_tampil() -> bool:
	return _panel_petunjuk.visible


## Persegi kartu misi, banner, dan gelembung petunjuk dalam koordinat viewport game (tes tata letak).
func rect_kartu() -> Rect2:
	return _panel_misi.get_global_rect()


func rect_banner() -> Rect2:
	return _panel_banner.get_global_rect()


func rect_petunjuk() -> Rect2:
	return _panel_petunjuk.get_global_rect()


## Memindahkan panel bawah dan tombol bel ke sisi tangan yang dipakai; radar dan panel atas tidak berpindah.
func atur_kidal(nilai: bool) -> void:
	super(nilai)
	_terapkan_tata_letak_rute()


## Teks yang tampil (untuk tes dan probe).
func teks_skor() -> String:
	return _angka_skor.text


func teks_combo() -> String:
	return _angka_combo.text


func teks_koin() -> String:
	return _angka_koin.text


## Label dan angka tenggat yang tampil, mis. "WAKTU 1:32" atau "LEWAT +0:12".
func teks_tenggat() -> String:
	return "%s %s" % [_label_waktu.text, _angka_waktu.text]


## Warna angka tenggat (untuk tes: `WARN` sesudah lewat).
func warna_tenggat() -> Color:
	return _angka_waktu.get_theme_color(&"font_color")


func teks_terkirim() -> String:
	return _angka_terkirim.text


## True bila label PUTUS tampil (untuk tes).
func putus_tampil() -> bool:
	return _label_putus.visible


func radar_seberang() -> RadarStrip:
	return _radar_seberang


func radar_dekat() -> RadarStrip:
	return _radar_dekat


func kotak_progres() -> KotakProgres:
	return _kotak_progres


## Persegi elemen dalam koordinat viewport game (tes tata letak).
func rect_radar_seberang() -> Rect2:
	return _radar_seberang.get_global_rect()


func rect_radar_dekat() -> Rect2:
	return _radar_dekat.get_global_rect()


func rect_panel_progres() -> Rect2:
	return _panel_progres.get_global_rect()


func rect_panel_koin() -> Rect2:
	return _panel_koin.get_global_rect()


func rect_panel_skor() -> Rect2:
	return _panel_skor.get_global_rect()


## Tata letak panel atas dan radar dari inset aman (geseran sama besar per tepi, `HudDasar`).
func _terapkan_tata_letak_rute() -> void:
	var atas: int = Config.HUD_MARGIN_TEPI_PX + geser_atas()
	_strip_progres.add_theme_constant_override(&"margin_top", atas)
	_strip_kanan.add_theme_constant_override(&"margin_top", atas)
	_strip_kanan.add_theme_constant_override(&"margin_right", Config.HUD_KANAN_MARGIN_PX + geser_akhir_x())
	_strip_misi.add_theme_constant_override(&"margin_left", Config.MISI_KARTU_X_PX + geser_awal_x())
	_strip_misi.add_theme_constant_override(&"margin_top", Config.MISI_KARTU_Y_PX + geser_atas())
	_strip_banner.add_theme_constant_override(&"margin_top", Config.MISI_BANNER_Y_PX + geser_atas())
	var y_atas: float = float(Config.RADAR_Y_ATAS_PX + geser_atas())
	var y_bawah: float = float(Config.RADAR_Y_BAWAH_PX)
	var tepi_awal: float = float(Config.RADAR_TEPI_PX + geser_awal_x())
	var tepi_akhir: float = float(Config.RADAR_TEPI_PX + geser_akhir_x())
	var lebar: float = float(Config.RADAR_LEBAR_PX)
	_radar_seberang.offset_left = tepi_awal
	_radar_seberang.offset_right = tepi_awal + lebar
	_radar_seberang.offset_top = y_atas
	_radar_seberang.offset_bottom = y_bawah
	_radar_dekat.offset_left = -(tepi_akhir + lebar)
	_radar_dekat.offset_right = -tepi_akhir
	_radar_dekat.offset_top = y_atas
	_radar_dekat.offset_bottom = y_bawah
	_radar_seberang.queue_redraw()
	_radar_dekat.queue_redraw()


## Membaca inset aman perangkat mobile (lihat atas). Desktop dan headless: tidak mengubah inset.
func _baca_zona_aman() -> void:
	if not OS.has_feature("mobile"):
		return
	var aman: Rect2i = DisplayServer.get_display_safe_area()
	atur_inset(ZonaAman.inset_game(aman, DisplayServer.window_get_size(), get_viewport().get_visible_rect().size))


## Panel 9-slice dan warna teks dari `Palette` (DESIGN_SPEC 1.1, 1.3).
func _terapkan_gaya() -> void:
	_panel_progres.add_theme_stylebox_override(&"panel", GayaHud.panel_hud(Config.HUD_PROGRES_PAD_X_PX))
	_panel_koin.add_theme_stylebox_override(&"panel", GayaHud.panel_hud())
	_panel_skor.add_theme_stylebox_override(&"panel", GayaHud.panel_hud())
	_panel_kondisi.add_theme_stylebox_override(&"panel", GayaHud.panel_hud())
	_panel_reputasi.add_theme_stylebox_override(&"panel", GayaHud.panel_hud())
	_angka_reputasi.add_theme_color_override(&"font_color", Palette.TEXT)
	_angka_terkirim.add_theme_color_override(&"font_color", Palette.ACCENT)
	_angka_koin.add_theme_color_override(&"font_color", Palette.TEXT)
	for label: Label in [_label_skor, _label_combo]:
		label.add_theme_color_override(&"font_color", Palette.ACCENT)
	for label: Label in [_angka_skor, _angka_combo]:
		label.add_theme_color_override(&"font_color", Palette.TEXT)
	_label_putus.add_theme_color_override(&"font_color", Palette.FAIL)
	_panel_misi.add_theme_stylebox_override(&"panel", GayaHud.panel_hud())
	_panel_banner.add_theme_stylebox_override(&"panel", GayaHud.panel_hud())
	_panel_petunjuk.add_theme_stylebox_override(&"panel", GayaHud.panel_hud())
	_label_misi.add_theme_color_override(&"font_color", Palette.ACCENT)
	_isi_misi.add_theme_color_override(&"font_color", Palette.TEXT)
	_teks_petunjuk.add_theme_color_override(&"font_color", Palette.TEXT)
