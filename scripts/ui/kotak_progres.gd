class_name KotakProgres
extends Control
## Baris kotak progres pelanggan di panel progres HUD rute (DESIGN_SPEC 3.2; AC-7 run fase3c-hud-hasil, usulan): satu kotak 8x8 per
## pelanggan berjarak 2, urut sesuai rute, pola dari `PolaPiksel.pola_progres` (simbol centang, silang, segitiga, atau garis putus-putus;
## bukan warna saja). Status dari `ProgresRute.status` (diisi `HudRute`); hanya menggambar, tidak menerima sentuhan.

var _status: Array[ProgresRute.Status] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_atur_ukuran()


## Mengganti status kotak. Gambar ulang hanya bila berubah.
func tampilkan(status: Array[ProgresRute.Status]) -> void:
	if status == _status:
		return
	_status = status.duplicate()
	_atur_ukuran()
	queue_redraw()


## Status kotak yang tampil (untuk tes).
func status_tampil() -> Array[ProgresRute.Status]:
	return _status


## Warna utama kotak berstatus `status` (`Palette`, DESIGN_SPEC 3.2).
static func warna(status: ProgresRute.Status) -> Color:
	match status:
		ProgresRute.Status.TERKIRIM:
			return Palette.OK
		ProgresRute.Status.TERLEWAT:
			return Palette.FAIL
		ProgresRute.Status.BERIKUTNYA:
			return Palette.ACCENT
	return Palette.UI_PANEL_RAISED


## Perintah gambar (`GambarPiksel`) semua kotak, urut dari awal rute; `_draw` menjalankan ini.
func perintah_tampil() -> Array:
	var hasil: Array = []
	var langkah: int = Config.HUD_PROGRES_KOTAK_PX + Config.HUD_PROGRES_JARAK_PX
	for i: int in range(_status.size()):
		hasil.append_array(GambarPiksel.perintah_pola(PolaPiksel.pola_progres(_status[i]), Vector2(i * langkah, 0), warna(_status[i])))
	return hasil


func _draw() -> void:
	GambarPiksel.gambar(self, perintah_tampil())


func _atur_ukuran() -> void:
	var n: int = maxi(_status.size(), Config.RUTE_PELANGGAN)
	var lebar: int = n * Config.HUD_PROGRES_KOTAK_PX + (n - 1) * Config.HUD_PROGRES_JARAK_PX
	custom_minimum_size = Vector2(lebar, Config.HUD_PROGRES_KOTAK_PX)
