class_name DeretKoran
extends Control
## Deret ikon koran di panel sisa koran HUD (DESIGN_SPEC 3.5): ikon 12 px dari kode (`PolaPiksel.IKON_KORAN`), paling banyak
## `Config.HUD_KORAN_IKON_MAKS`, ikon terpakai redup `HUD_KORAN_REDUP_ALPHA`. Hanya menggambar; jumlah dari `SisaKoran.ikon_hud` (diisi
## `HudDev`). Ukuran bilangan bulat, tidak menerima sentuhan (sentuhan di panel tetap menjadi swipe).

## Jumlah ikon yang digambar.
var jumlah: int = 0:
	set(baru):
		jumlah = maxi(baru, 0)
		_atur_ukuran()
		queue_redraw()
## Jumlah ikon terang (koran tersisa); sisanya redup.
var terang: int = 0:
	set(baru):
		if baru != terang:
			terang = baru
			queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_atur_ukuran()


## Alpha ikon ke-`i` (dari kiri): 1 untuk koran tersisa (`i < terang`), `HUD_KORAN_REDUP_ALPHA` untuk yang terpakai.
func alpha_ikon(i: int) -> float:
	return 1.0 if i < terang else Config.HUD_KORAN_REDUP_ALPHA


## Perintah gambar (`GambarPiksel`) semua ikon yang tampil, urut dari kiri; `_draw` menjalankan ini (dites headless, QA-003 iterasi 2).
func perintah_tampil() -> Array:
	var hasil: Array = []
	var langkah: int = Config.HUD_KORAN_IKON_PX + Config.HUD_KORAN_IKON_JARAK_PX
	for i: int in range(jumlah):
		hasil.append_array(GambarPiksel.perintah_pola(PolaPiksel.IKON_KORAN, Vector2(i * langkah, 0), Palette.TEXT, alpha_ikon(i)))
	return hasil


func _draw() -> void:
	GambarPiksel.gambar(self, perintah_tampil())


func _atur_ukuran() -> void:
	var lebar: int = Config.HUD_KORAN_IKON_MAKS * Config.HUD_KORAN_IKON_PX + (Config.HUD_KORAN_IKON_MAKS - 1) * Config.HUD_KORAN_IKON_JARAK_PX
	custom_minimum_size = Vector2(lebar, Config.HUD_KORAN_IKON_PX)
