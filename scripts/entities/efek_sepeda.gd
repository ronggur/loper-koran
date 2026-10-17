class_name EfekSepeda
extends Node2D
## Efek di atas pemain (run fase3b-rintangan-skor bagian B, usulan): ikon kilatan tabrakan selama jatuh (AC-8; oleng diganti jatuh 2026-10-17) dan teks "KRING!" /
## "KRING KRING!" bel (AC-16, DESIGN_SPEC 3.8). Anak `SepedaUji` sesudah sprite pemain, jadi digambar di atasnya; garis getar bel ada di
## node lain di BAWAH sprite (`GetarBel`, README bel: sprite pemain menutupi efek, bukan sebaliknya).
##
## Tipis: kapan dan di mana tampil dihitung `Tabrakan` dan `Bel` (murni). Ikon tabrakan = `PolaPiksel.IKON_TABRAKAN` warna `WARN`, kakinya
## `TABRAKAN_IKON_ATAS_PX` di atas titik pijak (bentuk, jadi terbaca tanpa suara dan tanpa warna). Teks bel = kunci terjemahan `RUTE_KRING` /
## `RUTE_KRING_KRING` (bukan teks di gambar, rule `content-data`), warna `ACCENT` bergaris luar `OUTLINE`, pojok kiri bawahnya di titik bel
## (`BEL_TITIK_PX`) + `BEL_TEKS_GESER_PX`, naik 1 piksel per frame efek (`Bel.naik_teks_px`), redup pada frame terakhir.

const TEMA: Theme = preload("res://assets/ui/theme.tres")

var _ikon_tabrakan: bool = false
var _teks: Label = null


func _ready() -> void:
	_teks = Label.new()
	_teks.name = "TeksBel"
	_teks.theme = TEMA
	_teks.theme_type_variation = &"HudLabel"
	_teks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_teks.add_theme_color_override(&"font_color", Palette.ACCENT)
	_teks.add_theme_color_override(&"font_outline_color", Palette.OUTLINE)
	_teks.add_theme_constant_override(&"outline_size", Config.HUD_TEKS_GARIS_PX)
	_teks.visible = false
	add_child(_teks)


## Menyalakan atau mematikan ikon kilatan tabrakan (selama jatuh). Gambar ulang hanya bila berubah.
func tampilkan_tabrakan(tampil: bool) -> void:
	if tampil == _ikon_tabrakan:
		return
	_ikon_tabrakan = tampil
	queue_redraw()


## True selama ikon kilatan tabrakan tampil.
func ikon_tabrakan_tampil() -> bool:
	return _ikon_tabrakan


## Menampilkan teks bel dari keadaan `b`: tampil selama `Bel.teks_tampil`, "KRING KRING!" bila `dobel`.
func tampilkan_bel(b: Bel.Keadaan) -> void:
	if _teks == null:
		return
	var tampil: bool = Bel.teks_tampil(b)
	_teks.visible = tampil
	if not tampil:
		return
	_teks.text = tr("RUTE_KRING_KRING") if b.dobel else tr("RUTE_KRING")
	_teks.modulate.a = Config.BEL_TEKS_REDUP_ALFA if Bel.teks_redup(b) else 1.0
	var tinggi: float = _teks.get_combined_minimum_size().y
	var kaki: Vector2 = titik_bel() + Vector2(Config.BEL_TEKS_GESER_PX[0], Config.BEL_TEKS_GESER_PX[1] - Bel.naik_teks_px(b))
	_teks.position = kaki - Vector2(0, tinggi)


## Label teks bel (untuk tes dan probe).
func label_bel() -> Label:
	return _teks


## Titik bel relatif titik pijak pemain, piksel game (`BEL_TITIK_PX`).
static func titik_bel() -> Vector2:
	return Vector2(Config.BEL_TITIK_PX[0], Config.BEL_TITIK_PX[1])


## Perintah gambar (`GambarPiksel`) ikon tabrakan: kosong bila tidak jatuh.
func perintah_tabrakan() -> Array:
	if not _ikon_tabrakan:
		return []
	var ukuran: Vector2i = PolaPiksel.ukuran(PolaPiksel.IKON_TABRAKAN)
	var pojok: Vector2 = Vector2(-floori(float(ukuran.x) / 2), -(Config.TABRAKAN_IKON_ATAS_PX + ukuran.y))
	return GambarPiksel.perintah_pola(PolaPiksel.IKON_TABRAKAN, pojok, Palette.WARN)


func _draw() -> void:
	GambarPiksel.gambar(self, perintah_tabrakan())
