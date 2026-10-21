class_name VfxSepedaGambar
extends Node2D
## Menggambar debu roda dan garis kecepatan dari sprite gelombang 1 (run fase5a bagian B, D-4, ART_DIRECTION 6.7), anak `UmpanBalikSepeda` (ruang lokal sepeda, di belakang sprite pemain).
##
## Node tipis: kapan tampil, alpha, frame, dan acak varian ada di `VfxSepeda` (murni; `UmpanBalikKecepatan` tidak berubah). Di sini hanya waktu: `maju(dt)` memajukan animasi debu
## (detik) dan acak garis (satu frame game per panggilan, RNG berseed `UMPAN_GARIS_SPRITE_BENIH`), dipanggil `_process`, jadi `SceneTree.paused` (jeda game, app di-background)
## membekukan keduanya tanpa lanjut otomatis. `dt` nol, negatif, NaN, atau tak hingga tidak memajukan apa pun. Titik asal node = titik pijak sepeda.

var _kecepatan_ud: float = 0.0
var _rem_aktif: bool = false
var _kurangi_efek: bool = false
var _detik: float = 0.0
var _garis: VfxSepeda.GarisKeadaan = null
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _ada_gambar: bool = false


func _init() -> void:
	_rng.seed = Config.UMPAN_GARIS_SPRITE_BENIH
	_garis = VfxSepeda.garis_awal(_rng)


func _process(delta: float) -> void:
	maju(minf(delta, Config.LANGKAH_WAKTU_MAKS_DETIK))


## Mengisi masukan efek dari kecepatan sebenarnya `kecepatan_ud`, status `rem_aktif`, dan `kurangi_efek` (dipanggil `UmpanBalikSepeda.perbarui`). Tidak memajukan waktu.
func atur(kecepatan_ud: float, rem_aktif: bool, kurangi_efek: bool) -> void:
	if kecepatan_ud == _kecepatan_ud and rem_aktif == _rem_aktif and kurangi_efek == _kurangi_efek:
		return
	_kecepatan_ud = kecepatan_ud
	_rem_aktif = rem_aktif
	_kurangi_efek = kurangi_efek
	queue_redraw()


## Memajukan animasi `dt` detik dan satu frame acak garis. `dt` nol, negatif, NaN, atau tak hingga: tidak berubah.
func maju(dt: float) -> void:
	if not is_finite(dt) or dt <= 0.0:
		return
	_detik += dt
	_garis = VfxSepeda.garis_maju(_garis, _rng)
	if _ada_gambar or not item_sprite().is_empty():
		queue_redraw()


## Item sprite yang sedang digambar (debu lalu garis; untuk tes dan probe).
func item_sprite() -> Array[DefSprite.Item]:
	var hasil: Array[DefSprite.Item] = []
	hasil.append_array(VfxSepeda.item_debu(_kecepatan_ud, _rem_aktif, _kurangi_efek, _detik))
	hasil.append_array(VfxSepeda.item_garis(_kecepatan_ud, _kurangi_efek, _garis))
	return hasil


## Waktu animasi debu sejauh ini, detik (untuk tes).
func detik() -> float:
	return _detik


## Keadaan acak garis sekarang (untuk tes; jangan diubah).
func keadaan_garis() -> VfxSepeda.GarisKeadaan:
	return _garis


func _draw() -> void:
	var daftar: Array[DefSprite.Item] = item_sprite()
	_ada_gambar = not daftar.is_empty()
	GambarSprite.gambar(self, daftar)
