class_name GayaHud
extends RefCounted
## Gaya panel dan tombol HUD sementara (DESIGN_SPEC 1.3): kotak bergaris luar 1 px, sudut tegas, isi berjarak `HUD_PANEL_PAD_*`.
##
## Dipakai bersama oleh `HudDev` dan `LayarJeda` supaya bentuk tombol sama. Warna selalu dari `Palette`. Panel 9-slice final
## (DESIGN_SPEC 1.3, `ui_panel_hud_9slice.png` dari `tools/ui_art/hud_ikon.py`) dipakai HUD rute (`panel_hud`, run fase3c-hud-hasil).

const TEKSTUR_PANEL_HUD: Texture2D = preload("res://assets/sprites/ui/ui_panel_hud_9slice.png")

## Komponen redesain (run ui1-komponen-bengkel bagian A, usulan; docs/design/redesain/README.md 3 dan 4): bingkai 9-slice tombol, panel, kartu, chip, ikon 24, dan glif 12 yang terpasang,
## kunci = nama berkas tanpa awalan `ui_` dan `.png`. Dimuat SEKALI di sini (bukan di `_draw`). Latar, sepeda, dan papan alat bengkel dimuat layar bengkel sendiri.
const _TEKSTUR: Dictionary = {
	"btn_utama": preload("res://assets/sprites/ui/ui_btn_utama.png"),
	"btn_utama_tekan": preload("res://assets/sprites/ui/ui_btn_utama_tekan.png"),
	"btn_biasa": preload("res://assets/sprites/ui/ui_btn_biasa.png"),
	"btn_biasa_tekan": preload("res://assets/sprites/ui/ui_btn_biasa_tekan.png"),
	"btn_sakelar_nyala": preload("res://assets/sprites/ui/ui_btn_sakelar_nyala.png"),
	"btn_tenang": preload("res://assets/sprites/ui/ui_btn_tenang.png"),
	"btn_tenang_tekan": preload("res://assets/sprites/ui/ui_btn_tenang_tekan.png"),
	"btn_nonaktif": preload("res://assets/sprites/ui/ui_btn_nonaktif.png"),
	"arsir_nonaktif": preload("res://assets/sprites/ui/ui_arsir_nonaktif.png"),
	"panel_layar": preload("res://assets/sprites/ui/ui_panel_layar.png"),
	"kartu_biasa": preload("res://assets/sprites/ui/ui_kartu_biasa.png"),
	"kartu_menonjol": preload("res://assets/sprites/ui/ui_kartu_menonjol.png"),
	"kartu_redup": preload("res://assets/sprites/ui/ui_kartu_redup.png"),
	"chip_gelap": preload("res://assets/sprites/ui/ui_chip_gelap.png"),
	"chip_ok": preload("res://assets/sprites/ui/ui_chip_ok.png"),
	"chip_warn": preload("res://assets/sprites/ui/ui_chip_warn.png"),
	"chip_netral": preload("res://assets/sprites/ui/ui_chip_netral.png"),
	"chip_aksen": preload("res://assets/sprites/ui/ui_chip_aksen.png"),
	"icon24_ban": preload("res://assets/sprites/ui/ui_icon24_ban.png"),
	"icon24_rem": preload("res://assets/sprites/ui/ui_icon24_rem.png"),
	"icon24_rantai": preload("res://assets/sprites/ui/ui_icon24_rantai.png"),
	"glif_seru_warn": preload("res://assets/sprites/ui/ui_glif_seru_warn.png"),
	"glif_centang_ok": preload("res://assets/sprites/ui/ui_glif_centang_ok.png"),
	"glif_centang_teks2": preload("res://assets/sprites/ui/ui_glif_centang_teks2.png"),
	"glif_kunci_terang": preload("res://assets/sprites/ui/ui_glif_kunci_terang.png"),
	"glif_panah_gelap": preload("res://assets/sprites/ui/ui_glif_panah_gelap.png"),
	# Run ui2-semua-layar bagian A (layar hasil struk): struk 9-slice, takik tiket, ikon 24 koin/bintang/lencana, lencana 32, glif naik/turun.
	"struk": preload("res://assets/sprites/ui/ui_struk.png"),
	"struk_takik": preload("res://assets/sprites/ui/ui_struk_takik.png"),
	"icon24_koin": preload("res://assets/sprites/ui/ui_icon24_koin.png"),
	"icon24_bintang": preload("res://assets/sprites/ui/ui_icon24_bintang.png"),
	"icon24_lencana_perunggu": preload("res://assets/sprites/ui/ui_icon24_lencana_perunggu.png"),
	"icon24_lencana_perak": preload("res://assets/sprites/ui/ui_icon24_lencana_perak.png"),
	"icon24_lencana_emas": preload("res://assets/sprites/ui/ui_icon24_lencana_emas.png"),
	"lencana32_perunggu": preload("res://assets/sprites/ui/ui_lencana32_perunggu.png"),
	"lencana32_perak": preload("res://assets/sprites/ui/ui_lencana32_perak.png"),
	"lencana32_emas": preload("res://assets/sprites/ui/ui_lencana32_emas.png"),
	"glif_naik_ok": preload("res://assets/sprites/ui/ui_glif_naik_ok.png"),
	"glif_turun_teks2": preload("res://assets/sprites/ui/ui_glif_turun_teks2.png"),
	# Run ui2-semua-layar bagian B (halaman koran): kotak misi garis ganda, tombol tinta, kertas, foto berita, ikon 24 kucing/kerucut/bohlam, glif centang gelap/panah terang/seru tinta2.
	"koran_kotak": preload("res://assets/sprites/ui/ui_koran_kotak.png"),
	"koran_btn_tinta": preload("res://assets/sprites/ui/ui_koran_btn_tinta.png"),
	"koran_btn_tinta_tekan": preload("res://assets/sprites/ui/ui_koran_btn_tinta_tekan.png"),
	"koran_btn_tipis": preload("res://assets/sprites/ui/ui_koran_btn_tipis.png"),
	"koran_btn_terpilih": preload("res://assets/sprites/ui/ui_koran_btn_terpilih.png"),
	"kertas_tile": preload("res://assets/sprites/ui/ui_kertas_tile.png"),
	"foto_jalan": preload("res://assets/sprites/ui/ui_foto_jalan.png"),
	"foto_lampu": preload("res://assets/sprites/ui/ui_foto_lampu.png"),
	"icon24_kucing": preload("res://assets/sprites/ui/ui_icon24_kucing.png"),
	"icon24_kerucut": preload("res://assets/sprites/ui/ui_icon24_kerucut.png"),
	"icon24_bohlam": preload("res://assets/sprites/ui/ui_icon24_bohlam.png"),
	"glif_centang_gelap": preload("res://assets/sprites/ui/ui_glif_centang_gelap.png"),
	"glif_panah_terang": preload("res://assets/sprites/ui/ui_glif_panah_terang.png"),
	"glif_seru_tinta2": preload("res://assets/sprites/ui/ui_glif_seru_tinta2.png"),
}
## Variasi tema (`assets/ui/theme.tres`) teks tombol: SemiBold 10 untuk utama, biasa, sakelar; Regular 10 untuk tenang dan nonaktif.
const VARIASI_TOMBOL_TEBAL: StringName = &"TombolPeran"
const VARIASI_TOMBOL_TIPIS: StringName = &"TombolTipis"

## Tekstur nonaktif yang tengahnya diganti ubin arsir 4x4 (dibangun sekali, lazy).
static var _tekstur_nonaktif: Texture2D = null


## Kotak `StyleBoxFlat` berisi `isi`, garis luar 1 px `garis`, tanpa anti-alias, padding dari Config.
static func kotak(isi: Color, garis: Color) -> StyleBoxFlat:
	var hasil: StyleBoxFlat = StyleBoxFlat.new()
	hasil.bg_color = isi
	hasil.border_color = garis
	hasil.set_border_width_all(Config.UI_GARIS_PX)
	hasil.anti_aliasing = false
	hasil.content_margin_left = float(Config.HUD_PANEL_PAD_X_PX)
	hasil.content_margin_right = float(Config.HUD_PANEL_PAD_X_PX)
	hasil.content_margin_top = float(Config.HUD_PANEL_PAD_Y_PX)
	hasil.content_margin_bottom = float(Config.HUD_PANEL_PAD_Y_PX)
	return hasil


## Gaya tombol teks HUD: normal dan hover `HUD_PANEL` bergaris `OUTLINE`, ditekan `UI_PANEL_RAISED` bergaris `ACCENT`; teks `TEXT`,
## ditekan `ACCENT`.
static func terapkan_tombol(tombol: Button) -> void:
	tombol.add_theme_stylebox_override(&"normal", kotak(Palette.HUD_PANEL, Palette.OUTLINE))
	tombol.add_theme_stylebox_override(&"hover", kotak(Palette.HUD_PANEL, Palette.OUTLINE))
	tombol.add_theme_stylebox_override(&"pressed", kotak(Palette.UI_PANEL_RAISED, Palette.ACCENT))
	tombol.add_theme_stylebox_override(&"hover_pressed", kotak(Palette.UI_PANEL_RAISED, Palette.ACCENT))
	tombol.add_theme_color_override(&"font_color", Palette.TEXT)
	tombol.add_theme_color_override(&"font_hover_color", Palette.TEXT)
	tombol.add_theme_color_override(&"font_pressed_color", Palette.ACCENT)
	tombol.add_theme_color_override(&"font_hover_pressed_color", Palette.ACCENT)


## Panel HUD 9-slice (DESIGN_SPEC 1.3): latar `HUD_PANEL`, garis luar `OUTLINE`, garis dalam `UI_PANEL_RAISED`, sudut tumpul bertingkat, dari
## tekstur 12x12 dengan tepi `HUD_PANEL_9SLICE_PX`; isi berjarak `pad_x` ke samping dan `HUD_PANEL_PAD_Y_PX` ke atas dan bawah.
static func panel_hud(pad_x: int = Config.HUD_PANEL_PAD_X_PX) -> StyleBoxTexture:
	var hasil: StyleBoxTexture = StyleBoxTexture.new()
	hasil.texture = TEKSTUR_PANEL_HUD
	hasil.set_texture_margin_all(float(Config.HUD_PANEL_9SLICE_PX))
	hasil.content_margin_left = float(pad_x)
	hasil.content_margin_right = float(pad_x)
	hasil.content_margin_top = float(Config.HUD_PANEL_PAD_Y_PX)
	hasil.content_margin_bottom = float(Config.HUD_PANEL_PAD_Y_PX)
	return hasil


## Tekstur komponen terpasang menurut nama dasar (mis. `"btn_utama"`, `"icon24_ban"`, `"glif_seru_warn"`); null bila tidak ada.
static func tekstur(nama: String) -> Texture2D:
	return _TEKSTUR.get(nama, null)


## Tombol aksi utama (`KomponenUi.Peran.UTAMA`): bingkai ACCENT, bibir 2 px, ditekan = wajah dan teks turun 2 px. Mengatur gaya semua keadaan, font, warna teks, dan `disabled = false`.
static func tombol_utama(tombol: Button) -> void:
	_terapkan_peran(tombol, KomponenUi.Peran.UTAMA, false)


## Tombol aksi biasa (`KomponenUi.Peran.BIASA`): bingkai UI_PANEL_RAISED bersisi atas terang, ditekan = bingkai ACCENT dan wajah turun 2 px.
static func tombol_biasa(tombol: Button) -> void:
	_terapkan_peran(tombol, KomponenUi.Peran.BIASA, false)


## Tombol sakelar (`KomponenUi.Peran.SAKELAR`): bingkai biasa saat mati, bingkai ACCENT saat `nyala`; isi diberi jarak samping tambahan untuk kenop atau teks nyala/mati buatan pemanggil.
static func tombol_sakelar(tombol: Button, nyala: bool) -> void:
	_terapkan_peran(tombol, KomponenUi.Peran.SAKELAR, nyala)


## Tombol tenang (`KomponenUi.Peran.TENANG`): rata tanpa bibir, teks Regular TEXT_2 (Lewati, bahaya ringan); ditekan tidak bergeser.
static func tombol_tenang(tombol: Button) -> void:
	_terapkan_peran(tombol, KomponenUi.Peran.TENANG, false)


## Tombol nonaktif: rata, tengah diarsir, teks Regular TEXT_2; mengatur `disabled = true`. Semua keadaan tampil nonaktif. Teks alasan ("Koin kurang") diberikan pemanggil lewat `KomponenUi.teks_tombol`.
## Memanggil `tombol_utama`/`tombol_biasa`/... lagi memulihkan peran aktifnya.
static func tombol_nonaktif(tombol: Button) -> void:
	tombol.disabled = true
	tombol.theme_type_variation = VARIASI_TOMBOL_TIPIS
	var mati: StyleBoxTexture = _kotak_tombol(KomponenUi.Peran.BIASA, KomponenUi.KeadaanTombol.NONAKTIF, false)
	for gaya: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled"]:
		tombol.add_theme_stylebox_override(gaya, mati)
	tombol.add_theme_stylebox_override(&"focus", _kotak_fokus())
	_warna_teks(tombol, Palette.TEXT_2, Palette.TEXT_2)


## Kartu 9-slice menurut jenis (`KomponenUi.JenisKartu`); isi berjarak `UI_PANEL_SLICE_PX` ke semua sisi (pemanggil boleh menimpa `content_margin_*`).
static func kartu(jenis: KomponenUi.JenisKartu) -> StyleBoxTexture:
	return _panel_9slice(KomponenUi.nama_tekstur_kartu(jenis))


static func kartu_biasa() -> StyleBoxTexture:
	return kartu(KomponenUi.JenisKartu.BIASA)


## Kartu butuh perhatian (garis dalam WARN); pasangkan dengan chip "!" + teks (`KomponenUi.chip`).
static func kartu_menonjol() -> StyleBoxTexture:
	return kartu(KomponenUi.JenisKartu.MENONJOL)


## Kartu selesai atau sudah dimiliki: rata, tanpa garis luar gelap.
static func kartu_redup() -> StyleBoxTexture:
	return kartu(KomponenUi.JenisKartu.REDUP)


## Panel layar penuh 9-slice.
static func panel_layar() -> StyleBoxTexture:
	return _panel_9slice("panel_layar")


## Struk hasil 9-slice (run ui2-semua-layar bagian A; kanvas `.pnl.struk`, usulan): tepi atas dan bawah bergerigi, tepi `UI_PANEL_SLICE_PX`, tepi mendatar diulang (`TILE_FIT`, seperti `border-image: round` kanvas supaya gigi rata di tepi kanan).
## Isi berjarak `pad_x` ke samping, `pad_atas` dan `pad_bawah` (sudah termasuk tepi 4).
static func struk(pad_x: int = Config.HASIL_STRUK_PAD_X_PX, pad_atas: int = Config.HASIL_STRUK_PAD_ATAS_PX, pad_bawah: int = Config.HASIL_STRUK_PAD_BAWAH_PX) -> StyleBoxTexture:
	var hasil: StyleBoxTexture = StyleBoxTexture.new()
	hasil.texture = tekstur("struk")
	hasil.set_texture_margin_all(float(Config.UI_PANEL_SLICE_PX))
	hasil.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	hasil.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	hasil.content_margin_left = float(pad_x)
	hasil.content_margin_right = float(pad_x)
	hasil.content_margin_top = float(pad_atas)
	hasil.content_margin_bottom = float(pad_bawah)
	return hasil


## Tombol tinta koran (run ui2-semua-layar bagian B; kanvas `.btn.k-tinta`, `.k-tipis`, `.k-pilih`, usulan): bingkai 9-slice menurut `peran` (`TampilKoran`), teks Lexend SemiBold menurut peran, ditekan = bingkai tekan (TINTA: wajah dan teks turun 2 px).
## Semua keadaan diatur sekali; `disabled = false`. Memanggil lagi dengan peran lain mengganti bentuknya (Ambil/Lewati berganti TIPIS dan TERPILIH).
static func tombol_koran(tombol: Button, peran: TampilKoran.PeranTombol) -> void:
	tombol.disabled = false
	tombol.theme_type_variation = VARIASI_TOMBOL_TEBAL
	var normal: StyleBoxTexture = _kotak_tombol_koran(peran, false)
	var tekan: StyleBoxTexture = _kotak_tombol_koran(peran, true)
	tombol.add_theme_stylebox_override(&"normal", normal)
	tombol.add_theme_stylebox_override(&"hover", normal)
	tombol.add_theme_stylebox_override(&"pressed", tekan)
	tombol.add_theme_stylebox_override(&"hover_pressed", tekan)
	tombol.add_theme_stylebox_override(&"disabled", normal)
	tombol.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
	_warna_teks(tombol, TampilKoran.warna_teks_tombol(peran, false), TampilKoran.warna_teks_tombol(peran, true))


## Kotak misi koran 9-slice garis ganda `KORAN_GARIS` (kanvas `.pnl.koran`): tepi `UI_PANEL_SLICE_PX`, isi berjarak `KORAN_PANEL_PAD_*`.
static func panel_koran() -> StyleBoxTexture:
	var hasil: StyleBoxTexture = StyleBoxTexture.new()
	hasil.texture = tekstur("koran_kotak")
	hasil.set_texture_margin_all(float(Config.UI_PANEL_SLICE_PX))
	hasil.content_margin_left = float(Config.KORAN_PANEL_PAD_X_PX)
	hasil.content_margin_right = float(Config.KORAN_PANEL_PAD_X_PX)
	hasil.content_margin_top = float(Config.KORAN_PANEL_PAD_ATAS_PX)
	hasil.content_margin_bottom = float(Config.KORAN_PANEL_PAD_BAWAH_PX)
	return hasil


## Kotak notifikasi save koran (kanvas: isi KORAN_KERTAS_2, garis 1 px KORAN_GARIS): isi berjarak `KORAN_NOTIF_PAD_*`.
static func kotak_notifikasi_koran() -> StyleBoxFlat:
	var hasil: StyleBoxFlat = kotak(Palette.KORAN_KERTAS_2, Palette.KORAN_GARIS)
	hasil.content_margin_left = float(Config.KORAN_NOTIF_PAD_X_PX)
	hasil.content_margin_right = float(Config.KORAN_NOTIF_PAD_X_PX)
	hasil.content_margin_top = float(Config.KORAN_NOTIF_PAD_Y_PX)
	hasil.content_margin_bottom = float(Config.KORAN_NOTIF_PAD_Y_PX)
	return hasil


## Chip 9-slice untuk `status` (`KomponenUi.chip`) dan `ukuran`: tepi `UI_CHIP_SLICE_PX`, isi berjarak samping `KomponenUi.pad_x_chip`. Tinggi minimum (`KomponenUi.tinggi_chip`) diatur pemanggil lewat `custom_minimum_size`.
static func chip(status: KomponenUi.StatusChip, ukuran: KomponenUi.UkuranChip = KomponenUi.UkuranChip.NORMAL) -> StyleBoxTexture:
	var hasil: StyleBoxTexture = StyleBoxTexture.new()
	hasil.texture = tekstur(KomponenUi.nama_tekstur_chip(KomponenUi.chip(status).gaya))
	hasil.set_texture_margin_all(float(Config.UI_CHIP_SLICE_PX))
	hasil.content_margin_left = float(Config.UI_CHIP_SLICE_PX + KomponenUi.pad_x_chip(ukuran))
	hasil.content_margin_right = hasil.content_margin_left
	hasil.content_margin_top = float(Config.UI_CHIP_SLICE_PX)
	hasil.content_margin_bottom = float(Config.UI_CHIP_SLICE_PX)
	return hasil


## Chip 9-slice menurut `gaya` (bukan status) dan `ukuran`, untuk `ChipUi`: tepi `UI_CHIP_SLICE_PX`, isi berjarak samping `KomponenUi.pad_x_chip` dan atas bawah `KomponenUi.pad_y_chip` (lebih kecil dari tepi supaya tinggi chip tetap menurut ukuran).
static func chip_gaya(gaya: KomponenUi.GayaChip, ukuran: KomponenUi.UkuranChip = KomponenUi.UkuranChip.NORMAL) -> StyleBoxTexture:
	var hasil: StyleBoxTexture = StyleBoxTexture.new()
	hasil.texture = tekstur(KomponenUi.nama_tekstur_chip(gaya))
	hasil.set_texture_margin_all(float(Config.UI_CHIP_SLICE_PX))
	hasil.content_margin_left = float(Config.UI_CHIP_SLICE_PX + KomponenUi.pad_x_chip(ukuran))
	hasil.content_margin_right = hasil.content_margin_left
	hasil.content_margin_top = float(KomponenUi.pad_y_chip(ukuran))
	hasil.content_margin_bottom = hasil.content_margin_top
	return hasil


# Bingkai 9-slice satu keadaan tombol koran: tepi dari `Config.UI_TOMBOL_SLICE_*`, margin isi = tepi + geseran bibir (`TampilKoran.margin_isi_tombol`).
static func _kotak_tombol_koran(peran: TampilKoran.PeranTombol, ditekan: bool) -> StyleBoxTexture:
	var hasil: StyleBoxTexture = StyleBoxTexture.new()
	hasil.texture = tekstur(TampilKoran.nama_tekstur_tombol(peran, ditekan))
	hasil.texture_margin_left = float(Config.UI_TOMBOL_SLICE_SAMPING_PX)
	hasil.texture_margin_right = float(Config.UI_TOMBOL_SLICE_SAMPING_PX)
	hasil.texture_margin_top = float(Config.UI_TOMBOL_SLICE_ATAS_PX)
	hasil.texture_margin_bottom = float(Config.UI_TOMBOL_SLICE_BAWAH_PX)
	var tambah: Vector2i = TampilKoran.margin_isi_tombol(peran, ditekan)
	hasil.content_margin_left = float(Config.UI_TOMBOL_SLICE_SAMPING_PX)
	hasil.content_margin_right = hasil.content_margin_left
	hasil.content_margin_top = float(Config.UI_TOMBOL_SLICE_ATAS_PX + tambah.x)
	hasil.content_margin_bottom = float(Config.UI_TOMBOL_SLICE_BAWAH_PX + tambah.y)
	return hasil


static func _panel_9slice(nama: String) -> StyleBoxTexture:
	var hasil: StyleBoxTexture = StyleBoxTexture.new()
	hasil.texture = tekstur(nama)
	hasil.set_texture_margin_all(float(Config.UI_PANEL_SLICE_PX))
	hasil.set_content_margin_all(float(Config.UI_PANEL_SLICE_PX))
	return hasil


# Satu peran aktif: gaya normal/hover (sama, layar sentuh), pressed/hover_pressed, disabled, focus, warna teks, font, dan `disabled = false`.
static func _terapkan_peran(tombol: Button, peran: KomponenUi.Peran, nyala: bool) -> void:
	tombol.disabled = false
	tombol.theme_type_variation = VARIASI_TOMBOL_TEBAL if KomponenUi.teks_tebal(peran, KomponenUi.KeadaanTombol.NORMAL) else VARIASI_TOMBOL_TIPIS
	var normal: StyleBoxTexture = _kotak_tombol(peran, KomponenUi.KeadaanTombol.NORMAL, nyala)
	var tekan: StyleBoxTexture = _kotak_tombol(peran, KomponenUi.KeadaanTombol.DITEKAN, nyala)
	tombol.add_theme_stylebox_override(&"normal", normal)
	tombol.add_theme_stylebox_override(&"hover", normal)
	tombol.add_theme_stylebox_override(&"pressed", tekan)
	tombol.add_theme_stylebox_override(&"hover_pressed", tekan)
	tombol.add_theme_stylebox_override(&"disabled", _kotak_tombol(peran, KomponenUi.KeadaanTombol.NONAKTIF, nyala))
	tombol.add_theme_stylebox_override(&"focus", _kotak_fokus())
	_warna_teks(tombol, KomponenUi.warna_teks_tombol(peran, KomponenUi.KeadaanTombol.NORMAL), KomponenUi.warna_teks_tombol(peran, KomponenUi.KeadaanTombol.DITEKAN))
	tombol.add_theme_color_override(&"font_disabled_color", KomponenUi.warna_teks_tombol(peran, KomponenUi.KeadaanTombol.NONAKTIF))


static func _warna_teks(tombol: Button, normal: Color, tekan: Color) -> void:
	tombol.add_theme_color_override(&"font_color", normal)
	tombol.add_theme_color_override(&"font_hover_color", normal)
	tombol.add_theme_color_override(&"font_focus_color", normal)
	tombol.add_theme_color_override(&"font_pressed_color", tekan)
	tombol.add_theme_color_override(&"font_hover_pressed_color", tekan)
	tombol.add_theme_color_override(&"font_disabled_color", Palette.TEXT_2)


# Bingkai 9-slice satu keadaan tombol. Tepi dari `Config.UI_TOMBOL_SLICE_*`; margin isi = tepi + geseran bibir (`KomponenUi.margin_isi_tombol`), sakelar + jarak samping.
static func _kotak_tombol(peran: KomponenUi.Peran, keadaan: KomponenUi.KeadaanTombol, nyala: bool) -> StyleBoxTexture:
	var hasil: StyleBoxTexture = StyleBoxTexture.new()
	if keadaan == KomponenUi.KeadaanTombol.NONAKTIF:
		hasil.texture = _tekstur_nonaktif_arsir()
		hasil.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
		hasil.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	else:
		hasil.texture = tekstur(KomponenUi.nama_tekstur_tombol(peran, keadaan, nyala))
	hasil.texture_margin_left = float(Config.UI_TOMBOL_SLICE_SAMPING_PX)
	hasil.texture_margin_right = float(Config.UI_TOMBOL_SLICE_SAMPING_PX)
	hasil.texture_margin_top = float(Config.UI_TOMBOL_SLICE_ATAS_PX)
	hasil.texture_margin_bottom = float(Config.UI_TOMBOL_SLICE_BAWAH_PX)
	var tambah: Vector2i = KomponenUi.margin_isi_tombol(peran, keadaan)
	var pad_x: float = float(Config.UI_TOMBOL_SAKELAR_PAD_X_PX) if peran == KomponenUi.Peran.SAKELAR else 0.0
	hasil.content_margin_left = float(Config.UI_TOMBOL_SLICE_SAMPING_PX) + pad_x
	hasil.content_margin_right = hasil.content_margin_left
	hasil.content_margin_top = float(Config.UI_TOMBOL_SLICE_ATAS_PX + tambah.x)
	hasil.content_margin_bottom = float(Config.UI_TOMBOL_SLICE_BAWAH_PX + tambah.y)
	return hasil


# Fokus: garis ACCENT 1 px di luar tombol berjarak 1 px (kanvas: outline putus-putus; Godot tidak punya garis putus-putus, jadi lurus).
static func _kotak_fokus() -> StyleBoxFlat:
	var hasil: StyleBoxFlat = StyleBoxFlat.new()
	hasil.draw_center = false
	hasil.border_color = Palette.ACCENT
	hasil.set_border_width_all(Config.UI_GARIS_PX)
	hasil.set_expand_margin_all(float(Config.UI_TOMBOL_FOKUS_JARAK_PX))
	hasil.anti_aliasing = false
	return hasil


# `ui_btn_nonaktif.png` dengan sel tengah 4x4 (di dalam tepi 9-slice) diganti ubin `ui_arsir_nonaktif.png`; dengan mode TILE tengah bingkai terarsir. Dibangun sekali.
static func _tekstur_nonaktif_arsir() -> Texture2D:
	if _tekstur_nonaktif != null:
		return _tekstur_nonaktif
	var dasar: Texture2D = tekstur("btn_nonaktif")
	var gambar: Image = dasar.get_image()
	var arsir: Image = tekstur("arsir_nonaktif").get_image()
	gambar.convert(Image.FORMAT_RGBA8)
	arsir.convert(Image.FORMAT_RGBA8)
	gambar.blit_rect(arsir, Rect2i(Vector2i.ZERO, arsir.get_size()), Vector2i(Config.UI_TOMBOL_SLICE_SAMPING_PX, Config.UI_TOMBOL_SLICE_ATAS_PX))
	_tekstur_nonaktif = ImageTexture.create_from_image(gambar)
	return _tekstur_nonaktif
