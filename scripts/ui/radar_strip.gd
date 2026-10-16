class_name RadarStrip
extends Control
## Satu strip radar di tepi layar (GDD 4.3, DESIGN_SPEC 3.4; AC-5 run fase3c-hud-hasil, usulan): bingkai 9-slice
## `ui_radar_strip_9slice.png` dan penanda `ui_radar_<jenis>[_jangkau].png` dari `tools/ui_art/hud_ikon.py`.
##
## Hanya menggambar: penanda dari `RadarRute.penanda` (diisi `HudRute`), disaring ke `sisi` strip ini (`SEBERANG` = strip di tepi x 0,
## `DEKAT` = strip di tepi x lebar; kidal tidak menukar). Penanda biasa 8x6 di tengah jalur, tepi atasnya `RadarRute.y_penanda_px` di
## jalur di dalam bingkai (atas = jauh, bawah = di samping sepeda, jadi penanda turun saat rumah mendekat). Penanda "masuk jangkauan" 10x8
## (garis luar `TEXT`, +2 px) berpusat di tempat yang sama. Jenis dibedakan bentuk juga: tip bertitik terang, bukan pelanggan berlubang.
## Tidak menerima sentuhan. Letak dan ukuran diatur `HudRute` lewat anchor dan offset.

const TEKSTUR_BINGKAI: Texture2D = preload("res://assets/sprites/ui/ui_radar_strip_9slice.png")
const TEKSTUR_PELANGGAN: Texture2D = preload("res://assets/sprites/ui/ui_radar_pelanggan.png")
const TEKSTUR_TIP: Texture2D = preload("res://assets/sprites/ui/ui_radar_tip.png")
const TEKSTUR_BUKAN: Texture2D = preload("res://assets/sprites/ui/ui_radar_bukan.png")
const TEKSTUR_PELANGGAN_JANGKAU: Texture2D = preload("res://assets/sprites/ui/ui_radar_pelanggan_jangkau.png")
const TEKSTUR_TIP_JANGKAU: Texture2D = preload("res://assets/sprites/ui/ui_radar_tip_jangkau.png")
const TEKSTUR_BUKAN_JANGKAU: Texture2D = preload("res://assets/sprites/ui/ui_radar_bukan_jangkau.png")

## Sisi dunia yang ditampilkan strip ini.
var sisi: LoperAnim.Sisi = LoperAnim.Sisi.SEBERANG

var _penanda: Array[RadarRute.Penanda] = []
var _bingkai: StyleBoxTexture = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_bingkai = StyleBoxTexture.new()
	_bingkai.texture = TEKSTUR_BINGKAI
	_bingkai.set_texture_margin_all(float(Config.RADAR_BINGKAI_PX))


## Mengganti penanda yang tampil: hanya yang sisinya `sisi`. Gambar ulang hanya bila isinya berubah.
func tampilkan(daftar: Array[RadarRute.Penanda]) -> void:
	var baru: Array[RadarRute.Penanda] = []
	for p: RadarRute.Penanda in daftar:
		if p.sisi == sisi:
			baru.append(p)
	if _sama(baru, _penanda):
		return
	_penanda = baru
	queue_redraw()


## Penanda yang sedang tampil di strip ini (untuk tes dan probe).
func penanda_tampil() -> Array[RadarRute.Penanda]:
	return _penanda


## Tekstur penanda `p` (jenis dan jangkau).
static func tekstur(p: RadarRute.Penanda) -> Texture2D:
	match p.jenis:
		RadarRute.Jenis.TIP:
			return TEKSTUR_TIP_JANGKAU if p.jangkau else TEKSTUR_TIP
		RadarRute.Jenis.BUKAN:
			return TEKSTUR_BUKAN_JANGKAU if p.jangkau else TEKSTUR_BUKAN
	return TEKSTUR_PELANGGAN_JANGKAU if p.jangkau else TEKSTUR_PELANGGAN


## Persegi gambar penanda `p` di dalam strip (koordinat lokal strip, piksel bulat).
func rect_lokal(p: RadarRute.Penanda) -> Rect2:
	var bingkai: int = Config.RADAR_BINGKAI_PX
	var lebar: int = Config.RADAR_PENANDA_LEBAR_PX
	var tinggi: int = Config.RADAR_PENANDA_TINGGI_PX
	var jalur: int = roundi(size.y) - bingkai * 2
	var x: int = floori((size.x - float(lebar)) / 2)
	var y: int = bingkai + RadarRute.y_penanda_px(p.vertikal, jalur, tinggi)
	if not p.jangkau:
		return Rect2(x, y, lebar, tinggi)
	var tambah: int = Config.RADAR_JANGKAU_TAMBAH_PX
	var setengah: int = floori(float(tambah) / 2)
	return Rect2(x - setengah, y - setengah, lebar + tambah, tinggi + tambah)


## Persegi gambar penanda `p` dalam koordinat viewport game.
func rect_global(p: RadarRute.Penanda) -> Rect2:
	var lokal: Rect2 = rect_lokal(p)
	return Rect2(get_global_rect().position + lokal.position, lokal.size)


func _draw() -> void:
	if _bingkai != null:
		draw_style_box(_bingkai, Rect2(Vector2.ZERO, size))
	# Yang jauh digambar dulu, jadi penanda yang lebih dekat (lebih penting) di atasnya.
	for p: RadarRute.Penanda in _penanda:
		draw_texture_rect(tekstur(p), rect_lokal(p), false)


func _sama(a: Array[RadarRute.Penanda], b: Array[RadarRute.Penanda]) -> bool:
	if a.size() != b.size():
		return false
	for i: int in range(a.size()):
		if a[i].id_rumah != b[i].id_rumah or a[i].jenis != b[i].jenis or a[i].jangkau != b[i].jangkau or rect_lokal(a[i]) != rect_lokal(b[i]):
			return false
	return true
