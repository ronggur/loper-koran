class_name KucingHiasan
extends Node2D
## Hiasan kucing misi (M-10 run fase4b-misi-kucing, usulan): kilau (dua frame bergantian tiap `MISI_KILAU_DETIK`), ekor (dua frame bergantian tiap `MISI_EKOR_DETIK`), dan bar progres tangkap
## di atas kucing. Pasangan visual petunjuk misi (prinsip 3, ui-scenes: penanda tidak hanya warna). Titik asal node = titik pijak kucing. Run fase5a bagian B (D-6): kilau dari sprite
## `mission_kilau` (9x9, dua frame, krem dengan titik tengah kuning) di tengah kotak `MISI_KILAU_KOTAK_PX` yang pojoknya `MISI_KILAU_POSISI_PX`; ekor dan bar progres tetap dari kode. Urutan gambar:
## ekor, kilau, bar progres (kilau di atas ekor, di bawah progres). Perintah gambar kode dan item sprite disusun fungsi statis yang bisa dites headless; `_draw` hanya menjalankannya
## lewat `GambarPiksel` dan `GambarSprite`. Warna dari `Palette`.

const SPRITE_KILAU: String = "mission_kilau"

var _kilau: bool = false
var _ekor: bool = false
var _progres: float = 0.0
var _detik: float = 0.0


## Mengatur isi hiasan: `kilau` dan `ekor` dari petunjuk visual data misi, `progres` 0..1 (0 = bar tidak tampil), `detik` waktu bebas untuk animasi.
func atur(kilau: bool, ekor: bool, progres: float, detik: float) -> void:
	var baru_progres: float = clampf(progres, 0.0, 1.0) if is_finite(progres) else 0.0
	if kilau == _kilau and ekor == _ekor and baru_progres == _progres and frame_kilau(detik) == frame_kilau(_detik) and frame_ekor(detik) == frame_ekor(_detik):
		_detik = detik
		return
	_kilau = kilau
	_ekor = ekor
	_progres = baru_progres
	_detik = detik
	queue_redraw()


## Indeks frame kilau (0 atau 1) pada waktu `detik`.
static func frame_kilau(detik: float) -> int:
	return posmod(floori(maxf(detik, 0.0) / Config.MISI_KILAU_DETIK), 2)


## Indeks frame ekor (0 atau 1) pada waktu `detik`.
static func frame_ekor(detik: float) -> int:
	return posmod(floori(maxf(detik, 0.0) / Config.MISI_EKOR_DETIK), 2)


## Perintah gambar ekor (`GambarPiksel`) pada waktu `detik`; kosong bila `ekor` false.
static func perintah_ekor(ekor: bool, detik: float) -> Array:
	if not ekor:
		return []
	var pola_ekor: Array[String] = PolaPiksel.EKOR_KUCING_1 if frame_ekor(detik) == 0 else PolaPiksel.EKOR_KUCING_2
	return GambarPiksel.perintah_pola(pola_ekor, Vector2(Config.MISI_EKOR_POSISI_PX[0], Config.MISI_EKOR_POSISI_PX[1]), Palette.RADAR_MISI)


## Item sprite kilau pada waktu `detik` (frame dari `frame_kilau`): sprite 9x9 di tengah kotak `MISI_KILAU_KOTAK_PX` yang pojoknya `MISI_KILAU_POSISI_PX`. Kosong bila `kilau` false.
static func item_kilau(kilau: bool, detik: float) -> Array[DefSprite.Item]:
	var hasil: Array[DefSprite.Item] = []
	if not kilau:
		return hasil
	var sel: Vector2i = DefSprite.sel(SPRITE_KILAU)
	var geser: Vector2 = Vector2((Config.MISI_KILAU_KOTAK_PX[0] - sel.x) / 2, (Config.MISI_KILAU_KOTAK_PX[1] - sel.y) / 2)
	var pojok: Vector2 = Vector2(Config.MISI_KILAU_POSISI_PX[0], Config.MISI_KILAU_POSISI_PX[1]) + geser
	hasil.append(DefSprite.Item.buat(SPRITE_KILAU, frame_kilau(detik), pojok))
	return hasil


## Bar progres tangkap: bingkai `OUTLINE` selebar `MISI_PROGRES_LEBAR_PX`, isi `OK` sebanyak `progres` (pecahan bulat piksel, minimal 1 px bila > 0).
static func perintah_progres(progres: float) -> Array:
	var lebar: int = Config.MISI_PROGRES_LEBAR_PX
	var tinggi: int = Config.MISI_PROGRES_TINGGI_PX
	var awal_x: int = -lebar / 2
	var atas: int = -Config.MISI_PROGRES_ATAS_PX
	var isi: int = clampi(ceili(float(lebar - 2) * clampf(progres, 0.0, 1.0)), 0, lebar - 2)
	var bingkai: Array[Vector3i] = []
	for baris: int in range(tinggi):
		bingkai.append(Vector3i(atas + baris, awal_x, awal_x + lebar))
	var dalam: Array[Vector3i] = []
	for baris: int in range(1, tinggi - 1):
		dalam.append(Vector3i(atas + baris, awal_x + 1, awal_x + 1 + isi))
	var hasil: Array = GambarPiksel.perintah_rentang(bingkai, Vector2.ZERO, Palette.OUTLINE)
	if isi > 0:
		hasil.append_array(GambarPiksel.perintah_rentang(dalam, Vector2.ZERO, Palette.OK))
	return hasil


## Item sprite hiasan yang sedang digambar (kilau; untuk tes dan probe).
func item_sprite() -> Array[DefSprite.Item]:
	return item_kilau(_kilau, _detik)


func _draw() -> void:
	GambarPiksel.gambar(self, perintah_ekor(_ekor, _detik))
	GambarSprite.gambar(self, item_kilau(_kilau, _detik))
	if _progres > 0.0:
		GambarPiksel.gambar(self, perintah_progres(_progres))
