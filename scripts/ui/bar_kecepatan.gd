class_name BarKecepatan
extends Control
## Bar HUD (DESIGN_SPEC 1.3 dan 3.5), TANPA trek gelap (revisi UI pemilik R-4, 2026-10-24, usulan): bagian kosong hanya satu garis sumbu `OUTLINE` 1 px di tengah tinggi bar sepanjang bar (`TampilHud.rect_sumbu_bar`), isi `warna_isi`
## menutupi sumbu di bagian yang terisi (tinggi isi = tinggi bar - 2 `UI_GARIS_PX`, seperti isi lama di dalam garis luar), dan (opsional) tanda tegak `WARN` di `tanda` (batas ngebut, run ui2-semua-layar bagian C2).
## Bagian terisi dan kosong dibedakan oleh isi 7 px terang (`TEXT`, `ACCENT`, `FAIL`) lawan garis 1 px; panel bawah HUD di belakangnya (`HUD_PANEL`) tidak diubah.
##
## Dipakai untuk kecepatan (isi `TEXT`, bawaan, bertanda di ambang ngebut sebenarnya, 90 %) dan stamina (isi `ACCENT` atau `FAIL`, diatur `HudDev`, tanpa tanda).
## Tingginya `Config.HUD_BAR_TINGGI_PX`; lebar mengikuti container. Hanya menggambar: nilainya (0 sampai 1) dan warnanya
## diisi pemanggil. Ukuran selalu bilangan bulat (isi dibulatkan ke bawah) supaya piksel tajam.

## Isi bar, 0 sampai 1 (dijepit).
var nilai: float = 0.0:
	set(baru):
		nilai = clampf(baru, 0.0, 1.0) if not is_nan(baru) else 0.0
		queue_redraw()
## Letak tanda batas ngebut sebagai pecahan lebar isi (0..1); 0 atau kurang = tanpa tanda. Garis `WARN` selebar 1 px setinggi bar penuh (menembus garis luar), digambar di atas isi.
var tanda: float = 0.0:
	set(baru):
		if baru != tanda:
			tanda = baru
			queue_redraw()
## Warna isi bar, selalu dari `Palette`.
var warna_isi: Color = Palette.TEXT:
	set(baru):
		if baru != warna_isi:
			warna_isi = baru
			queue_redraw()


func _ready() -> void:
	custom_minimum_size.y = float(Config.HUD_BAR_TINGGI_PX)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	draw_rect(Rect2(TampilHud.rect_sumbu_bar(roundi(size.x), roundi(size.y))), Palette.OUTLINE)
	var dalam: Rect2 = Rect2(Vector2.ONE, size - Vector2.ONE * 2)
	var lebar_isi: float = floorf(dalam.size.x * nilai)
	if lebar_isi > 0.0:
		draw_rect(Rect2(dalam.position, Vector2(lebar_isi, dalam.size.y)), warna_isi)
	if tanda > 0.0:
		draw_rect(rect_tanda(), Palette.WARN)


## Persegi tanda batas ngebut dalam koordinat lokal bar (`TampilHud.posisi_tanda`); selebar 1 px, setinggi bar. Dites dan digambar dari sini.
func rect_tanda() -> Rect2:
	var x: int = Config.UI_GARIS_PX + TampilHud.posisi_tanda(size.x - float(Config.UI_GARIS_PX) * 2, tanda)
	return Rect2(float(x), 0.0, float(Config.UI_GARIS_PX), size.y)
