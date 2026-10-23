class_name ChipUi
extends PanelContainer
## Chip 9-slice (run ui1-komponen-bengkel bagian B; kanvas ui.css `.chip`; usulan): bingkai `ui_chip_*` menurut gaya, lalu glif 12 atau ikon opsional dan satu teks. Tinggi tetap menurut
## ukuran (14, 18, 24; `KomponenUi.tinggi_chip`). Status chip dipetakan `KomponenUi.chip` (gaya, glif, kunci teks), jadi status terbaca dari bentuk dan teks, tidak hanya warna. Hanya menggambar,
## tidak menerima sentuhan. Dipakai bengkel untuk harga, saldo, Baik, Dimiliki, tingkat, dan penanda kondisi di sepeda; layar lain memakainya di run berikutnya.

var _ukuran: KomponenUi.UkuranChip = KomponenUi.UkuranChip.NORMAL
var _baris: HBoxContainer = null
var _glif: TextureRect = null
var _ikon: TextureRect = null
var _label: Label = null


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_baris = HBoxContainer.new()
	_baris.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_baris.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_baris)
	_glif = _gambar(Config.BENGKEL_GLIF_PX)
	_ikon = _gambar(Config.BENGKEL_KOIN_PX)
	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_baris.add_child(_label)


## Mengatur chip bergaya `gaya` bertulis `teks`, berukuran `ukuran`, dengan glif (nama dasar tekstur `GayaHud.tekstur`, "" = tanpa) dan ikon (null = tanpa) di depan teks.
func atur(gaya: KomponenUi.GayaChip, teks: String, ukuran: KomponenUi.UkuranChip = KomponenUi.UkuranChip.NORMAL, glif: String = "", ikon: Texture2D = null) -> void:
	_ukuran = ukuran
	var kotak: StyleBoxTexture = GayaHud.chip_gaya(gaya, ukuran)
	add_theme_stylebox_override(&"panel", kotak)
	custom_minimum_size = Vector2(0, KomponenUi.tinggi_chip(ukuran))
	_baris.add_theme_constant_override(&"separation", KomponenUi.jarak_chip(ukuran))
	_glif.texture = GayaHud.tekstur(glif) if glif != "" else null
	_glif.visible = glif != ""
	_ikon.texture = ikon
	_ikon.visible = ikon != null
	_label.text = teks
	_label.theme_type_variation = _varian(ukuran)
	_label.add_theme_color_override(&"font_color", KomponenUi.warna_teks_chip(gaya))


## Mengatur chip dari `status` (`KomponenUi.chip`): gaya, glif, dan teks (`tr` kunci status bila `teks` kosong).
func atur_status(status: KomponenUi.StatusChip, ukuran: KomponenUi.UkuranChip = KomponenUi.UkuranChip.NORMAL, teks: String = "", ikon: Texture2D = null) -> void:
	var info: KomponenUi.InfoChip = KomponenUi.chip(status)
	var tampil: String = teks if teks != "" else (tr(info.kunci_teks) if info.kunci_teks != "" else "")
	atur(info.gaya, tampil, ukuran, KomponenUi.nama_glif_chip(info), ikon)


## Label teks chip (untuk tes dan pembacaan teks).
func label() -> Label:
	return _label


## True bila glif (mis. centang) tampil di chip.
func glif_tampil() -> bool:
	return _glif.visible


func teks() -> String:
	return _label.text


func ukuran() -> KomponenUi.UkuranChip:
	return _ukuran


func _gambar(sisi: int) -> TextureRect:
	var gambar: TextureRect = TextureRect.new()
	gambar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gambar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	gambar.custom_minimum_size = Vector2(sisi, sisi)
	gambar.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	gambar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_baris.add_child(gambar)
	_baris.move_child(gambar, 0)
	return gambar


func _varian(ukuran_chip: KomponenUi.UkuranChip) -> StringName:
	match ukuran_chip:
		KomponenUi.UkuranChip.KECIL:
			return &"ChipTeksKecil"
		KomponenUi.UkuranChip.BESAR:
			return &"ChipTeksBesar"
	return &"ChipTeks"
