class_name PancaranPiksel
extends Node2D
## Pemancar partikel piksel sederhana (D-2 run fase1b-umpan-balik): debu roda dan garis kecepatan, digambar sendiri di `_draw`.
##
## Bukan `GPUParticles2D` (lebih aman di renderer Compatibility dan HP kelas bawah) dan bukan `CPUParticles2D`: posisi partikel
## CPUParticles2D tidak dibulatkan ke piksel game, jadi dengan stretch `canvas_items` x3 kotaknya jatuh di antara blok piksel.
## Di sini tiap partikel adalah kotak 1-2 px game (atau garis bertangga 2:1 sepanjang `panjang_px`) di posisi yang dibulatkan,
## warnanya dari `Palette` (diisi pemilik node). Partikel bergerak lurus searah `arah` (sejajar jalan) dalam ruang lokal node,
## umurnya `umur_detik`, jumlah hidup paling banyak `batas` (larik dipesan sekali di `siapkan`, tanpa alokasi per frame). Laju
## pancar (`laju`, per detik) diisi tiap langkah oleh pemilik dari `UmpanBalikKecepatan`. Acak memakai `RandomNumberGenerator`
## bernih tetap (deterministik). Waktu dimajukan `maju(dt)` dari `_process`, jadi `SceneTree.paused` menghentikan pancaran dan gerak.

## Laju pancar, partikel per detik. 0 = tidak memancar (partikel yang masih hidup tetap habis umurnya).
var laju: float = 0.0
## Umur satu partikel, detik.
var umur_detik: float = 0.0
## Kecepatan partikel searah `arah`, piksel game per detik.
var kecepatan_px: float = 0.0
## Arah gerak (satuan), ruang lokal.
var arah: Vector2 = Vector2.ZERO
## Titik muncul, ruang lokal.
var asal: Vector2 = Vector2.ZERO
## Sebaran titik muncul tegak lurus `arah`, plus-minus piksel game.
var sebaran_px: float = 0.0
## Sisi kotak terbesar, piksel game (acak 1 sampai nilai ini). Diabaikan bila `panjang_px` > 0.
var ukuran_maks_px: int = 1
## Panjang garis bertangga 2:1 (lebar datar), piksel game. 0 = kotak.
var panjang_px: int = 0
## Warna partikel (dari `Palette`, boleh dengan alpha).
var warna: Color = Color(Palette.TEXT, 0.0)

var _batas: int = 0
var _jumlah: int = 0
var _akumulasi: float = 0.0
var _posisi: PackedVector2Array = PackedVector2Array()
var _umur: PackedFloat32Array = PackedFloat32Array()
var _ukuran: PackedInt32Array = PackedInt32Array()
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


## Memesan larik untuk `batas` partikel dan mengatur benih acak. Partikel lama dibuang.
func siapkan(batas: int, benih: int) -> void:
	_batas = maxi(batas, 0)
	_posisi.resize(_batas)
	_umur.resize(_batas)
	_ukuran.resize(_batas)
	_rng.seed = benih
	kosongkan()


func _process(delta: float) -> void:
	maju(minf(delta, Config.LANGKAH_WAKTU_MAKS_DETIK))


## Memajukan partikel `dt` detik: menua dan bergerak, yang habis umurnya dibuang, lalu memancar sesuai `laju` sampai `batas`.
## `dt` nol, negatif, NaN, atau tak hingga: tidak berubah.
func maju(dt: float) -> void:
	if not is_finite(dt) or dt <= 0.0:
		return
	var i: int = 0
	while i < _jumlah:
		_umur[i] += dt
		if _umur[i] >= umur_detik:
			_jumlah -= 1
			_posisi[i] = _posisi[_jumlah]
			_umur[i] = _umur[_jumlah]
			_ukuran[i] = _ukuran[_jumlah]
			continue
		_posisi[i] += arah * kecepatan_px * dt
		i += 1
	if not is_finite(laju) or laju <= 0.0:
		_akumulasi = 0.0
	else:
		_akumulasi += laju * dt
		while _akumulasi >= 1.0:
			_akumulasi -= 1.0
			_pancar()
	queue_redraw()


## Membuang semua partikel hidup dan sisa pancaran.
func kosongkan() -> void:
	_jumlah = 0
	_akumulasi = 0.0
	queue_redraw()


## Jumlah partikel yang sedang hidup.
func jumlah_aktif() -> int:
	return _jumlah


## Batas jumlah partikel hidup.
func batas() -> int:
	return _batas


## True bila laju pancar di atas 0.
func memancar() -> bool:
	return laju > 0.0


## Salinan posisi partikel hidup (untuk tes; bukan untuk dipakai tiap frame).
func posisi_partikel() -> PackedVector2Array:
	return _posisi.slice(0, _jumlah)


func _pancar() -> void:
	if _jumlah >= _batas:
		return
	var tegak: Vector2 = Vector2(-arah.y, arah.x)
	_posisi[_jumlah] = asal + tegak * _rng.randf_range(-sebaran_px, sebaran_px)
	_umur[_jumlah] = 0.0
	_ukuran[_jumlah] = _rng.randi_range(1, maxi(ukuran_maks_px, 1))
	_jumlah += 1


func _draw() -> void:
	for i: int in range(_jumlah):
		var p: Vector2 = _posisi[i].round()
		if panjang_px <= 0:
			draw_rect(Rect2(p, Vector2.ONE * float(_ukuran[i])), warna)
			continue
		# Garis bertangga 2:1 searah jalan naik ke kanan atas: tiap anak tangga 2 px datar, 1 px tegak.
		for j: int in range(ceili(float(panjang_px) / 2)):
			draw_rect(Rect2(p + Vector2(j * 2, -j), Vector2(2, 1)), warna)
