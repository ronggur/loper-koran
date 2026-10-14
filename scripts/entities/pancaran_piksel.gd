class_name PancaranPiksel
extends Node2D
## Pemancar partikel piksel sederhana (D-2 run fase1b-umpan-balik): debu roda dan garis kecepatan, digambar sendiri di `_draw`.
##
## Bukan `GPUParticles2D` (lebih aman di renderer Compatibility dan HP kelas bawah) dan bukan `CPUParticles2D`: posisi partikel
## CPUParticles2D tidak dibulatkan ke piksel game, jadi dengan stretch `canvas_items` x3 kotaknya jatuh di antara blok piksel.
## Di sini tiap partikel adalah kotak 1-2 px game (atau garis bertangga 2:1 sepanjang `panjang_px`) di posisi yang dibulatkan,
## warnanya dari `Palette` (diisi pemilik node). Partikel bergerak lurus searah `arah` (sejajar jalan), umurnya `umur_detik`,
## jumlah hidup paling banyak `batas` (larik dipesan sekali di `siapkan`, tanpa alokasi per frame). Laju pancar (`laju`, per detik)
## diisi tiap langkah oleh pemilik dari `UmpanBalikKecepatan`. Acak memakai `RandomNumberGenerator` bernih tetap (deterministik).
## Waktu dimajukan `maju(dt)` dari `_process`, jadi `SceneTree.paused` menghentikan pancaran dan gerak.
##
## Dua ruang (QA-006 run fase1b-umpan-balik, D-5 run fase1c-perapian):
## - `ruang_dunia` false (bawaan, garis kecepatan): posisi partikel di ruang lokal node, jadi partikel ikut bergeser bersama induk.
## - `ruang_dunia` true (debu roda): saat dipancarkan, titik muncul (`asal` lokal) diubah ke posisi global (kanvas, sama dengan
##   ruang dunia jalan; kamera tidak termasuk) dan disimpan di sana. Sesudahnya partikel diam di jalan: bergerak hanya karena
##   `arah` x `kecepatan_px` miliknya, tidak ikut sepeda maju, pindah sisi, atau dorongan kamera. `_draw` menggambar posisi itu
##   kembali ke ruang lokal node dengan transform global terbalik, jadi node tetap di tempatnya di pohon (urutan gambar tidak
##   berubah: tetap di belakang sprite pemain). Bukan `top_level`, karena `top_level` juga memindah urutan gambar ke atas.
##   Induk hanya boleh bergeser (tanpa putar atau skala), seperti `SepedaUji`.

## Laju pancar, partikel per detik. 0 = tidak memancar (partikel yang masih hidup tetap habis umurnya).
var laju: float = 0.0
## Umur satu partikel, detik.
var umur_detik: float = 0.0
## Kecepatan partikel searah `arah`, piksel game per detik.
var kecepatan_px: float = 0.0
## Arah gerak (satuan). Induk hanya bergeser, jadi arah sama di ruang lokal dan ruang dunia.
var arah: Vector2 = Vector2.ZERO
## Titik muncul, ruang lokal (juga saat `ruang_dunia`: diubah ke posisi global saat partikel dipancarkan).
var asal: Vector2 = Vector2.ZERO
## Sebaran titik muncul tegak lurus `arah`, plus-minus piksel game.
var sebaran_px: float = 0.0
## Sisi kotak terbesar, piksel game (acak 1 sampai nilai ini). Diabaikan bila `panjang_px` > 0.
var ukuran_maks_px: int = 1
## Panjang garis bertangga 2:1 (lebar datar), piksel game. 0 = kotak.
var panjang_px: int = 0
## Warna partikel (dari `Palette`, boleh dengan alpha).
var warna: Color = Color(Palette.TEXT, 0.0)
## True: partikel yang sudah dipancarkan diam di ruang dunia (tidak ikut induk bergeser); lihat penjelasan di atas.
var ruang_dunia: bool = false:
	set(nilai):
		ruang_dunia = nilai
		set_notify_transform(nilai)
		kosongkan()

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


func _notification(what: int) -> void:
	# Ruang dunia: induk bergeser = letak gambar partikel di ruang lokal berubah walau partikel diam, juga tanpa `maju` (mis. sepeda
	# dipasang ulang saat jeda, atau `_process` mati). Dites (P-2 run fase2a-lemparan): induk digeser tanpa `maju` = digambar ulang.
	if what == NOTIFICATION_TRANSFORM_CHANGED and ruang_dunia:
		queue_redraw()


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


## Salinan posisi partikel hidup dalam ruang simpannya (lokal, atau global bila `ruang_dunia`; untuk tes, bukan tiap frame).
func posisi_partikel() -> PackedVector2Array:
	return _posisi.slice(0, _jumlah)


## Salinan posisi global (kanvas) partikel hidup, apa pun ruang simpannya (untuk tes dan probe; bukan untuk dipakai tiap frame).
func posisi_global_partikel() -> PackedVector2Array:
	var hasil: PackedVector2Array = _posisi.slice(0, _jumlah)
	if not ruang_dunia:
		var ke_global: Transform2D = get_global_transform()
		for i: int in range(hasil.size()):
			hasil[i] = ke_global * hasil[i]
	return hasil


func _pancar() -> void:
	if _jumlah >= _batas:
		return
	var tegak: Vector2 = Vector2(-arah.y, arah.x)
	var muncul: Vector2 = asal + tegak * _rng.randf_range(-sebaran_px, sebaran_px)
	_posisi[_jumlah] = get_global_transform() * muncul if ruang_dunia else muncul
	_umur[_jumlah] = 0.0
	_ukuran[_jumlah] = _rng.randi_range(1, maxi(ukuran_maks_px, 1))
	_jumlah += 1


## Titik gambar partikel ke-`i` (0 sampai `jumlah_aktif() - 1`) di ruang lokal node, piksel game bulat; dipakai `_draw` (QA-001 run
## fase1c-perapian, P-1 run fase2a-lemparan). Ruang dunia: posisi global dibulatkan ke piksel game dulu, lalu dibawa ke ruang lokal
## dengan transform global terbalik (induk di piksel bulat, jadi tetap bulat), sehingga transform global x titik gambar = posisi global
## dibulatkan. Ruang lokal: posisi tersimpan dibulatkan. Indeks di luar rentang = nol.
func titik_gambar(i: int) -> Vector2:
	if i < 0 or i >= _jumlah:
		return Vector2.ZERO
	var ke_lokal: Transform2D = get_global_transform().affine_inverse() if ruang_dunia else Transform2D.IDENTITY
	return (ke_lokal * _posisi[i].round()).round()


func _draw() -> void:
	for i: int in range(_jumlah):
		var p: Vector2 = titik_gambar(i)
		if panjang_px <= 0:
			draw_rect(Rect2(p, Vector2.ONE * float(_ukuran[i])), warna)
			continue
		# Garis bertangga 2:1 searah jalan naik ke kanan atas: tiap anak tangga 2 px datar, 1 px tegak.
		for j: int in range(ceili(float(panjang_px) / 2)):
			draw_rect(Rect2(p + Vector2(j * 2, -j), Vector2(2, 1)), warna)
