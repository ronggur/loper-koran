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


func _draw() -> void:
	var langkah: int = Config.HUD_KORAN_IKON_PX + Config.HUD_KORAN_IKON_JARAK_PX
	for i: int in range(jumlah):
		var alpha: float = 1.0 if i < terang else Config.HUD_KORAN_REDUP_ALPHA
		GambarPiksel.pola(self, PolaPiksel.IKON_KORAN, Vector2(i * langkah, 0), Palette.TEXT, alpha)


func _atur_ukuran() -> void:
	var lebar: int = Config.HUD_KORAN_IKON_MAKS * Config.HUD_KORAN_IKON_PX + (Config.HUD_KORAN_IKON_MAKS - 1) * Config.HUD_KORAN_IKON_JARAK_PX
	custom_minimum_size = Vector2(lebar, Config.HUD_KORAN_IKON_PX)
