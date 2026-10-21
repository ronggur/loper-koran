class_name UmpanMelayangGambar
extends Node2D
## Menampilkan umpan balik melayang (`UmpanMelayang`, logika murni) di ruang dunia, di atas objek (DESIGN_SPEC 3.6; AC-13 run
## fase3b-rintangan-skor bagian B, versi minimal usulan): satu label per entri, kaki teks `UMPAN_MELAYANG_ATAS_PX` di atas titik mendarat,
## naik dan memudar. Teks dari kunci terjemahan: `RUTE_UMPAN_KOIN` ("+15"), lalu `RUTE_UMPAN_TIP` dan `RUTE_UMPAN_TEPAT` bila ada,
## satu per baris, rata tengah. Warna `OK` bergaris luar `OUTLINE`, font dari `assets/ui/theme.tres` (`HudLabel`).
## Run fase5a bagian B (D-5, usulan): tiap entri juga memutar bintang kena (`vfx_bintang_kena`) di titik mendarat dan, bila tip sama dengan `UMPAN_KOIN_TIP_SPRITE_NILAI`, koin tip
## (`vfx_koin_tip`, tulisan "+5" di sprite) yang naik dari titik mendarat; baris tip label tidak tampil bila sprite koin dipakai (`VfxAntaran`). Sprite digambar di bawah label (`_draw` induk lebih dulu dari anak).

const TEMA: Theme = preload("res://assets/ui/theme.tres")

var _label: Array[Label] = []
var _item: Array[DefSprite.Item] = []
## Tekstur bintang dan koin yang dipegang node (dimuat di `_ready`, bukan di `_draw`; lihat `GambarSprite`).
var _tekstur: Dictionary = {}


func _ready() -> void:
	_tekstur = GambarSprite.muat([VfxAntaran.SPRITE_BINTANG, VfxAntaran.SPRITE_KOIN] as Array[String])


## Menampilkan daftar entri (urut dari yang paling lama). Label dipakai ulang; yang tidak terpakai disembunyikan.
func tampilkan(daftar: Array[UmpanMelayang.Entri]) -> void:
	var ada_sprite: bool = not _item.is_empty()
	_item = VfxAntaran.item_semua(daftar)
	if ada_sprite or not _item.is_empty():
		queue_redraw()
	while _label.size() < daftar.size():
		_label.append(_buat_label())
	for i: int in range(_label.size()):
		var label: Label = _label[i]
		if i >= daftar.size():
			label.visible = false
			continue
		var e: UmpanMelayang.Entri = daftar[i]
		label.text = teks(e)
		label.visible = true
		label.modulate.a = UmpanMelayang.alfa(e)
		var ukuran: Vector2 = label.get_combined_minimum_size()
		var kaki: Vector2 = Iso.posisi_gambar(e.titik_dunia) - Vector2(0, Config.UMPAN_MELAYANG_ATAS_PX + UmpanMelayang.naik_px(e))
		label.position = (kaki - Vector2(ukuran.x / 2, ukuran.y)).round()


## Teks satu entri: "+<ongkos>", lalu tip dan "TEPAT" bila ada, satu per baris. Tip tidak ditulis di label bila ditampilkan sprite koin (`VfxAntaran.koin_sprite`).
func teks(e: UmpanMelayang.Entri) -> String:
	var bagian: PackedStringArray = PackedStringArray([tr("RUTE_UMPAN_KOIN").format({"n": e.ongkos})])
	if e.tip > 0 and not VfxAntaran.koin_sprite(e.tip):
		bagian.append(tr("RUTE_UMPAN_TIP").format({"n": e.tip}))
	if e.tepat:
		bagian.append(tr("RUTE_UMPAN_TEPAT"))
	return "\n".join(bagian)


## Banyaknya tekstur sprite yang dipegang node (untuk tes).
func jumlah_tekstur() -> int:
	return _tekstur.size()


## Item sprite (bintang, koin) yang sedang digambar (untuk tes dan probe).
func item_sprite() -> Array[DefSprite.Item]:
	return _item


func _draw() -> void:
	GambarSprite.gambar(self, _item, _tekstur)


## Banyaknya label yang sedang tampil (untuk tes).
func jumlah_tampil() -> int:
	var jumlah: int = 0
	for label: Label in _label:
		if label.visible:
			jumlah += 1
	return jumlah


## Teks label yang sedang tampil, urut (untuk tes).
func teks_tampil() -> Array[String]:
	var hasil: Array[String] = []
	for label: Label in _label:
		if label.visible:
			hasil.append(label.text)
	return hasil


func _buat_label() -> Label:
	var label: Label = Label.new()
	label.theme = TEMA
	label.theme_type_variation = &"HudLabel"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override(&"font_color", Palette.OK)
	label.add_theme_color_override(&"font_outline_color", Palette.OUTLINE)
	label.add_theme_constant_override(&"outline_size", Config.HUD_TEKS_GARIS_PX)
	label.visible = false
	add_child(label)
	return label
