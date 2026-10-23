class_name PanggungSepeda
extends Control
## Panggung sepeda layar bengkel (run ui1-komponen-bengkel bagian B; kanvas Bengkel.dc.html; usulan): latar `UI_PANEL` berbingkai gelap 1 px, papan alat 360x104 di dasar (dipotong tengah),
## sepeda kecil 116x78 (dari gambar full body tanpa tokoh), dan penanda kondisi: titik 3x3 di bagian sepeda yang AUS atau PERLU_BENGKEL dengan chip kecil ("! Ban", "Ban aus"). Sepeda yang baik
## tampil bersih. Letak dari `TampilBengkel.tata_panggung` dan `rect_chip` (murni, titik dari `Config.BENGKEL_SEPEDA_TITIK` = `ui_bengkel_sepeda.json`). Tekstur dimuat sekali (const, bukan `_draw`).
## Hanya menggambar; tidak menerima sentuhan.

const TEKSTUR_PAPAN: Texture2D = preload("res://assets/sprites/ui/ui_bengkel_papan_alat.png")
const TEKSTUR_SEPEDA: Texture2D = preload("res://assets/sprites/ui/ui_bengkel_sepeda_kecil.png")

var _isi: Control = null
var _papan: TextureRect = null
var _sepeda: TextureRect = null
## Satu titik dan satu chip per komponen (urut `Config.KONDISI_KOMPONEN`); disembunyikan bila komponen baik.
var _titik: Array[Panel] = []
var _chip: Array[ChipUi] = []
var _kondisi: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_isi = Control.new()
	_isi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_isi.clip_contents = true
	_isi.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_isi)
	_papan = _gambar(TEKSTUR_PAPAN)
	_sepeda = _gambar(TEKSTUR_SEPEDA)
	for i: int in range(Config.KONDISI_KOMPONEN.size()):
		var titik: Panel = Panel.new()
		titik.mouse_filter = Control.MOUSE_FILTER_IGNORE
		titik.visible = false
		_isi.add_child(titik)
		_titik.append(titik)
		var chip: ChipUi = ChipUi.new()
		chip.visible = false
		_isi.add_child(chip)
		_chip.append(chip)
	resized.connect(_susun)
	_susun()


func _draw() -> void:
	draw_rect(Rect2(Vector2(-1, -1), size + Vector2(2, 2)), Palette.OUTLINE)
	draw_rect(Rect2(Vector2.ZERO, size), Palette.UI_PANEL)


## Menampilkan penanda untuk `kondisi` (komponen -> 0..1; komponen yang hilang dianggap baik).
func atur_kondisi(kondisi: Dictionary) -> void:
	_kondisi = kondisi
	_susun()


## Persegi (koordinat global) panggung, sepeda, dan chip penanda komponen `id`; chip kosong bila tidak tampil.
func rect_panggung() -> Rect2:
	return get_global_rect()


func rect_sepeda() -> Rect2:
	return _sepeda.get_global_rect() if _sepeda != null else Rect2()


func rect_chip(id: String) -> Rect2:
	var i: int = Config.KONDISI_KOMPONEN.find(id)
	if i < 0 or not _chip[i].visible:
		return Rect2()
	return _chip[i].get_global_rect()


func chip_tampil(id: String) -> bool:
	var i: int = Config.KONDISI_KOMPONEN.find(id)
	return i >= 0 and _chip[i].visible


func teks_chip(id: String) -> String:
	var i: int = Config.KONDISI_KOMPONEN.find(id)
	return _chip[i].teks() if i >= 0 and _chip[i].visible else ""


## Persegi titik penanda (koordinat global) komponen `id`; kosong bila tidak tampil.
func rect_titik_global(id: String) -> Rect2:
	var i: int = Config.KONDISI_KOMPONEN.find(id)
	if i < 0 or not _titik[i].visible:
		return Rect2()
	return _titik[i].get_global_rect()


func _gambar(tekstur: Texture2D) -> TextureRect:
	var gambar: TextureRect = TextureRect.new()
	gambar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gambar.texture = tekstur
	gambar.stretch_mode = TextureRect.STRETCH_KEEP
	gambar.size = tekstur.get_size()
	_isi.add_child(gambar)
	return gambar


# Menata ulang papan, sepeda, titik, dan chip dari ukuran panggung dan kondisi.
func _susun() -> void:
	if _isi == null:
		return
	var ukuran_panggung: Vector2i = Vector2i(size)
	var tata: TampilBengkel.TataPanggung = TampilBengkel.tata_panggung(ukuran_panggung.x, ukuran_panggung.y)
	_papan.position = Vector2(tata.papan)
	_sepeda.position = Vector2(tata.sepeda)
	for i: int in range(Config.KONDISI_KOMPONEN.size()):
		var id: String = Config.KONDISI_KOMPONEN[i]
		var kondisi: float = float(_kondisi.get(id, 1.0))
		var info: TampilBengkel.InfoServis = TampilBengkel.servis(kondisi, 0, 0)
		_titik[i].visible = info.penanda
		_chip[i].visible = info.penanda
		if not info.penanda:
			continue
		var gaya: KomponenUi.GayaChip = KomponenUi.chip(info.status_penanda).gaya
		var teks: String = tr(info.kunci_penanda).format({"nama": tr(TampilKondisi.kunci_nama(id))})
		_chip[i].atur(gaya, teks, KomponenUi.UkuranChip.KECIL)
		_chip[i].size = _chip[i].get_combined_minimum_size()
		var rect_c: Rect2i = TampilBengkel.rect_chip(i, tata, Vector2i(_chip[i].size), ukuran_panggung)
		_chip[i].position = Vector2(rect_c.position)
		var rect_t: Rect2i = TampilBengkel.rect_titik(i, tata)
		_titik[i].position = Vector2(rect_t.position)
		_titik[i].size = Vector2(rect_t.size)
		_titik[i].add_theme_stylebox_override(&"panel", _gaya_titik(info.status_penanda))


# Titik 3x3 terisi `WARN` (PERLU_BENGKEL) atau `TEXT_2` (AUS) bergaris luar `OUTLINE` 1 px.
func _gaya_titik(status: KomponenUi.StatusChip) -> StyleBoxFlat:
	var hasil: StyleBoxFlat = StyleBoxFlat.new()
	hasil.bg_color = Palette.WARN if status == KomponenUi.StatusChip.PERLU_SERVIS else Palette.TEXT_2
	hasil.border_color = Palette.OUTLINE
	hasil.set_border_width_all(1)
	hasil.anti_aliasing = false
	return hasil
