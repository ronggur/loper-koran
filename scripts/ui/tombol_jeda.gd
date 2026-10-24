class_name TombolJeda
extends TombolSentuh
## Tombol jeda HUD (DESIGN_SPEC 3.1; tampilan tombol biasa run ui2-semua-layar bagian C2, V-9 H-3, kanvas HUD.dc.html; usulan): area sentuh `Config.HUD_JEDA_SENTUH_PX` persegi (>= 44 dp di A54), gambar 24x24 digambar dari kode.
##
## Gambar: bingkai 9-slice tombol biasa (`ui_btn_biasa`, ditekan `ui_btn_biasa_tekan`: wajah turun 2 px) dengan glif jeda 12x12 (`ui_glif_jeda_terang`) di tengah wajah (`TampilHud.posisi_glif_jeda`). Area sentuh
## lebih besar dari gambarnya: gambar diletakkan di `geser_gambar()` dari pojok kiri atas tombol (diatur `HudDasar` supaya gambar jatuh di x 26, y 8 layar). Tanpa teks; StyleBox tombol kosong, tekstur dimuat di `_ready`.
## Ketukan jari mana pun memicu `ditekan` (`TombolSentuh`), juga saat jempol lain masih di stick.

## Letak pojok kiri atas gambar 24x24 di dalam tombol, piksel game.
var geser_gambar: Vector2 = Vector2.ZERO:
	set(nilai):
		geser_gambar = nilai
		queue_redraw()

var _bingkai_normal: StyleBoxTexture
var _bingkai_tekan: StyleBoxTexture
var _glif: Texture2D


func _ready() -> void:
	super()
	focus_mode = Control.FOCUS_NONE
	var kosong: StyleBoxEmpty = StyleBoxEmpty.new()
	for nama: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"focus", &"disabled"]:
		add_theme_stylebox_override(nama, kosong)
	custom_minimum_size = Vector2.ONE * float(Config.HUD_JEDA_SENTUH_PX)
	_bingkai_normal = GayaHud.bingkai_tombol(KomponenUi.Peran.BIASA, KomponenUi.KeadaanTombol.NORMAL)
	_bingkai_tekan = GayaHud.bingkai_tombol(KomponenUi.Peran.BIASA, KomponenUi.KeadaanTombol.DITEKAN)
	_glif = GayaHud.tekstur(TampilHud.nama_glif_jeda())
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)


func _draw() -> void:
	var sisi: float = float(Config.HUD_JEDA_GAMBAR_PX)
	var kotak: Rect2 = Rect2(geser_gambar, Vector2(sisi, sisi))
	var ditekan: bool = is_pressed()
	draw_style_box(_bingkai_tekan if ditekan else _bingkai_normal, kotak)
	draw_texture(_glif, kotak.position + Vector2(TampilHud.posisi_glif_jeda(ditekan)))


## Persegi gambar 24x24 dalam koordinat viewport game (untuk tes dan probe).
func rect_gambar() -> Rect2:
	var sisi: float = float(Config.HUD_JEDA_GAMBAR_PX)
	return Rect2(get_global_rect().position + geser_gambar, Vector2(sisi, sisi))


## Bingkai dan glif yang digambar untuk keadaan `ditekan` (untuk tes): `[nama tekstur bingkai, posisi glif relatif pojok gambar]`.
func tampilan(ditekan: bool) -> Array:
	return [TampilHud.nama_bingkai_jeda(ditekan), TampilHud.posisi_glif_jeda(ditekan)]
