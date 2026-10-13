class_name TombolJeda
extends TombolSentuh
## Tombol jeda HUD (DESIGN_SPEC 3.1): area sentuh `Config.HUD_JEDA_SENTUH_PX` persegi (≥ 44 dp di A54), gambar 24×24 digambar dari kode.
##
## Gambar: kotak `HUD_PANEL` dengan garis luar 1 px `TEXT` (supaya terbaca sebagai tombol) dan dua batang `TEXT` 3×10 di tengahnya;
## saat ditekan isinya `UI_PANEL_RAISED`. Area sentuh lebih besar dari gambarnya: gambar diletakkan di `geser_gambar()` dari pojok
## kiri atas tombol (diatur `HudDev` supaya gambar jatuh di x 26, y 8 layar). Tanpa teks dan tanpa PNG; StyleBox tombol kosong.
## Ketukan jari mana pun memicu `ditekan` (`TombolSentuh`), juga saat jempol lain masih di stick.

## Letak pojok kiri atas gambar 24×24 di dalam tombol, piksel game.
var geser_gambar: Vector2 = Vector2.ZERO:
	set(nilai):
		geser_gambar = nilai
		queue_redraw()


func _ready() -> void:
	super()
	focus_mode = Control.FOCUS_NONE
	var kosong: StyleBoxEmpty = StyleBoxEmpty.new()
	for nama: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"focus", &"disabled"]:
		add_theme_stylebox_override(nama, kosong)
	custom_minimum_size = Vector2.ONE * float(Config.HUD_JEDA_SENTUH_PX)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)


func _draw() -> void:
	var sisi: float = float(Config.HUD_JEDA_GAMBAR_PX)
	var kotak: Rect2 = Rect2(geser_gambar, Vector2(sisi, sisi))
	draw_rect(kotak.grow(-1), Palette.UI_PANEL_RAISED if is_pressed() else Palette.HUD_PANEL)
	# Garis luar 1 px sebagai empat persegi supaya tepinya tepat di piksel.
	draw_rect(Rect2(kotak.position, Vector2(sisi, 1)), Palette.TEXT)
	draw_rect(Rect2(kotak.position + Vector2(0, sisi - 1), Vector2(sisi, 1)), Palette.TEXT)
	draw_rect(Rect2(kotak.position, Vector2(1, sisi)), Palette.TEXT)
	draw_rect(Rect2(kotak.position + Vector2(sisi - 1, 0), Vector2(1, sisi)), Palette.TEXT)
	var batang: Vector2 = Vector2(Config.HUD_JEDA_BATANG_LEBAR_PX, Config.HUD_JEDA_BATANG_TINGGI_PX)
	var lebar_pasang: float = batang.x * 2 + float(Config.HUD_JEDA_BATANG_CELAH_PX)
	var awal: Vector2 = (kotak.position + (Vector2(sisi, sisi) - Vector2(lebar_pasang, batang.y)) / 2).floor()
	draw_rect(Rect2(awal, batang), Palette.TEXT)
	draw_rect(Rect2(awal + Vector2(batang.x + float(Config.HUD_JEDA_BATANG_CELAH_PX), 0), batang), Palette.TEXT)


## Persegi gambar 24×24 dalam koordinat viewport game (untuk tes dan probe).
func rect_gambar() -> Rect2:
	var sisi: float = float(Config.HUD_JEDA_GAMBAR_PX)
	return Rect2(get_global_rect().position + geser_gambar, Vector2(sisi, sisi))
