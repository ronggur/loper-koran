class_name KotakKondisi
extends Control
## Satu komponen sepeda di HUD rute dan layar bengkel (DESIGN_SPEC 3.3; AC-22, AC-23, AC-25 run fase6a1-bengkel-kondisi bagian B, usulan): ikon 14 px (`ui_icon_ban/rem/rantai`), tiga kotak 5x5
## (`TampilKondisi.kotak`), dan tanda "!" `WARN` untuk PERLU_BENGKEL. Saat peringatan (`kedip_sisa` > 0) ikon bergetar (`TampilKondisi.getar`) dan kotak terisi berwarna `WARN`. Ruang tanda "!" selalu
## disediakan supaya panel tidak melompat. Hanya menggambar; tidak menerima sentuhan. Status terbaca tanpa warna: jumlah kotak terisi, kotak hilang berongga, "!", dan getar.

## Id komponen yang digambar (`Config.KONDISI_KOMPONEN`), diatur scene.
@export var komponen: String = "ban"

const _IKON: Dictionary = {
	"ban": preload("res://assets/sprites/ui/ui_icon_ban.png"),
	"rem": preload("res://assets/sprites/ui/ui_icon_rem.png"),
	"rantai": preload("res://assets/sprites/ui/ui_icon_rantai.png"),
}

var _kondisi: float = 1.0
var _kedip_sisa: float = 0.0
## Kunci gambar terakhir: gambar ulang hanya bila berubah (tanpa alokasi per frame).
var _kunci: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = ukuran()


## Ukuran satu komponen, piksel game: ikon + jarak + tiga kotak + jarak + ruang tanda "!".
static func ukuran() -> Vector2:
	var kotak: int = Config.KONDISI_KOTAK_BAIK * Config.KONDISI_HUD_KOTAK_PX + (Config.KONDISI_KOTAK_BAIK - 1) * Config.KONDISI_HUD_KOTAK_JARAK_PX
	return Vector2(Config.HUD_IKON_PX + Config.KONDISI_HUD_IKON_JARAK_PX + kotak + Config.KONDISI_HUD_SERU_JARAK_PX + Config.KONDISI_HUD_SERU_LEBAR_PX, Config.HUD_IKON_PX)


## Menampilkan kondisi `kondisi` (0..1) dengan sisa waktu peringatan `kedip_sisa` (detik). Gambar ulang hanya bila tingkat gambar berubah.
func tampilkan(kondisi: float, kedip_sisa: float) -> void:
	_kondisi = BikeCondition.jepit(kondisi)
	_kedip_sisa = maxf(kedip_sisa, 0.0)
	var kunci: Array = [TampilKondisi.kotak(_kondisi, _kedip_sisa > 0.0), TampilKondisi.tanda_seru(_kondisi), TampilKondisi.getar(_kedip_sisa)]
	if kunci == _kunci:
		return
	_kunci = kunci
	queue_redraw()


## Isi tiga kotak yang tampil (`TampilKondisi.Kotak`, untuk tes).
func kotak_tampil() -> Array[TampilKondisi.Kotak]:
	return TampilKondisi.kotak(_kondisi, _kedip_sisa > 0.0)


## True bila tanda "!" tampil (untuk tes).
func seru_tampil() -> bool:
	return TampilKondisi.tanda_seru(_kondisi)


## Geseran mendatar ikon saat ini, piksel game (untuk tes).
func getar_tampil() -> int:
	return TampilKondisi.getar(_kedip_sisa)


## Warna isi kotak `kotak` (`Palette`): PENUH `TEXT`, PENUH_WARN `WARN`, KOSONG `UI_PANEL_RAISED`.
static func warna(kotak: TampilKondisi.Kotak) -> Color:
	match kotak:
		TampilKondisi.Kotak.PENUH:
			return Palette.TEXT
		TampilKondisi.Kotak.PENUH_WARN:
			return Palette.WARN
	return Palette.UI_PANEL_RAISED


## Perintah gambar (`GambarPiksel`) tiga kotak dan tanda "!"; `_draw` menjalankan ini. Ikon digambar terpisah (tekstur).
func perintah_tampil() -> Array:
	var hasil: Array = []
	var awal_kotak: int = Config.HUD_IKON_PX + Config.KONDISI_HUD_IKON_JARAK_PX
	var tegak: float = float(Config.HUD_IKON_PX - Config.KONDISI_HUD_KOTAK_PX) / 2
	var kotak: Array[TampilKondisi.Kotak] = kotak_tampil()
	for i: int in range(kotak.size()):
		var pola: Array[String] = PolaPiksel.KOTAK_KONDISI_KOSONG if kotak[i] == TampilKondisi.Kotak.KOSONG else PolaPiksel.KOTAK_KONDISI_PENUH
		var x: float = float(awal_kotak + i * (Config.KONDISI_HUD_KOTAK_PX + Config.KONDISI_HUD_KOTAK_JARAK_PX))
		hasil.append_array(GambarPiksel.perintah_pola(pola, Vector2(x, floorf(tegak)), warna(kotak[i])))
	if seru_tampil():
		var x_seru: float = float(awal_kotak + Config.KONDISI_HUD_SERU_JARAK_PX + Config.KONDISI_HUD_KOTAK_JARAK_PX * 2 + Config.KONDISI_HUD_KOTAK_PX * Config.KONDISI_KOTAK_BAIK)
		var tinggi_seru: int = PolaPiksel.TANDA_SERU_KONDISI.size()
		hasil.append_array(GambarPiksel.perintah_pola(PolaPiksel.TANDA_SERU_KONDISI, Vector2(x_seru, floorf(float(Config.HUD_IKON_PX - tinggi_seru) / 2)), Palette.WARN))
	return hasil


func _draw() -> void:
	var ikon: Texture2D = _IKON.get(komponen, null)
	if ikon != null:
		draw_texture(ikon, Vector2(float(TampilKondisi.getar(_kedip_sisa)), 0.0))
	GambarPiksel.gambar(self, perintah_tampil())
