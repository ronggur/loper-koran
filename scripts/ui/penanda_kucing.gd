class_name PenandaKucing
extends Control
## Penanda tepi layar untuk kucing misi yang belum utuh di layar (M-2' dan M-3', QA-001 dan QA-002 run fase4b-misi-kucing iterasi 2, usulan): panah
## `PolaPiksel.PANAH_KUCING_ATAS` (ke atas atau ke kanan, dua warna bergantian dari kode, bentuk tetap supaya tidak hanya warna) di titik yang dihitung
## `TampilMisi`. Hanya menggambar; menutupi seluruh layar HUD tanpa menerima sentuhan (`mouse_filter` abaikan). Tanpa teks. Perintah gambar disusun
## fungsi statis yang bisa dites headless; `_draw` hanya menjalankannya lewat `GambarPiksel`.

var _penanda: Array[TampilMisi.Penanda] = []
var _detik: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


## Mengganti penanda yang tampil (kosong = tidak ada) dan waktu animasinya. Gambar ulang hanya bila isi atau warna kedip berubah.
func tampilkan(daftar: Array[TampilMisi.Penanda], detik: float) -> void:
	var sama: bool = daftar.size() == _penanda.size() and kedip(detik) == kedip(_detik)
	if sama:
		for i: int in range(daftar.size()):
			if daftar[i].pusat != _penanda[i].pusat or daftar[i].arah != _penanda[i].arah:
				sama = false
				break
	_detik = detik
	if sama:
		return
	_penanda = daftar
	queue_redraw()


## Penanda yang sedang tampil (untuk tes dan probe).
func penanda_tampil() -> Array[TampilMisi.Penanda]:
	return _penanda


## Persegi penanda yang tampil, koordinat viewport game (untuk tes tata letak).
func rect_penanda() -> Array[Rect2]:
	var hasil: Array[Rect2] = []
	for p: TampilMisi.Penanda in _penanda:
		hasil.append(TampilMisi.rect_penanda(p))
	return hasil


## Keadaan kedip (0 atau 1) pada waktu `detik`.
static func kedip(detik: float) -> int:
	return posmod(floori(maxf(detik, 0.0) / Config.MISI_PENANDA_KEDIP_DETIK), 2)


## Perintah gambar penanda `p` pada waktu `detik`: pola panah berpusat di `pusat`, warna `ACCENT` lalu `RADAR_MISI` bergantian.
static func perintah(p: TampilMisi.Penanda, detik: float) -> Array:
	var pola: Array[String] = TampilMisi.pola(p.arah)
	var asal: Vector2 = p.pusat - Vector2(float(pola[0].length() / 2), float(pola.size() / 2))
	return GambarPiksel.perintah_pola(pola, asal, Palette.ACCENT if kedip(detik) == 0 else Palette.RADAR_MISI)


func _draw() -> void:
	for p: TampilMisi.Penanda in _penanda:
		GambarPiksel.gambar(self, perintah(p, _detik))
