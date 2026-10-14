class_name GarisBidik
extends Node2D
## Garis bidik lemparan di RUANG DUNIA (D-5 run fase2a-lemparan, DESIGN_SPEC 3.7): titik 2 px tiap 4 px warna `TEXT` sepanjang lintasan
## yang sama persis dengan lemparan (sampel `ThrowSolver.posisi_pada` lewat `KoranLempar.waktu_titik_bidik`, lengkung terlihat), berakhir
## di elips pendaratan 10x5 px di tanah. Elips mengarah ke sasaran sah = elips TERISI warna `OK` bergaris luar (bentuk berbeda, bukan
## hanya warna); selain itu cincin `TEXT`.
##
## Node tipis: lintasan dihitung `JalanUji` tiap frame dari keadaan sepeda sebenarnya (`tampilkan`), node ini hanya menyimpan dan
## menggambar. Anak dunia (ikut kamera), digambar di atas objek dunia. Posisi titik dibulatkan ke piksel game (pixel-perfect).

var _lintasan: ThrowSolver.Lintasan = null
var _sah: bool = false
var _titik: PackedVector2Array = PackedVector2Array()


## Menampilkan garis bidik untuk `lintasan` (null = sembunyikan); `sah` = titik mendarat di sasaran sah (elips `OK` terisi).
func tampilkan(lintasan: ThrowSolver.Lintasan, sah: bool) -> void:
	if lintasan == null:
		sembunyikan()
		return
	_lintasan = lintasan
	_sah = sah
	_titik.clear()
	for t: float in KoranLempar.waktu_titik_bidik(lintasan, float(Config.SWIPE_TITIK_JARAK_PX), Config.GARIS_BIDIK_SAMPEL):
		_titik.append(KoranLempar.layar_pada(lintasan, t).round())
	queue_redraw()


## Menyembunyikan garis bidik (jari dilepas, swipe batal, koran habis, jeda antar lempar, jeda game).
func sembunyikan() -> void:
	if _lintasan == null:
		return
	_lintasan = null
	_sah = false
	_titik.clear()
	queue_redraw()


## True bila garis bidik sedang tampil.
func tampil() -> bool:
	return _lintasan != null


## Lintasan yang sedang ditampilkan (null bila tidak tampil).
func lintasan() -> ThrowSolver.Lintasan:
	return _lintasan


## True bila elips menunjukkan sasaran sah (`OK`, terisi).
func elips_sah() -> bool:
	return _lintasan != null and _sah


## Titik akhir garis bidik (ujung lintasan yang ditampilkan): x, y = titik mendarat di dunia (ubin), z = tinggi (0).
func titik_akhir() -> Vector3:
	if _lintasan == null:
		return Vector3.ZERO
	return ThrowSolver.posisi_pada(_lintasan, _lintasan.lama_terbang)


## Titik gambar garis bidik (pusat titik, piksel game ruang dunia, bulat), untuk tes dan probe.
func titik_gambar() -> PackedVector2Array:
	return _titik


## Pojok kiri atas elips pendaratan (piksel game ruang dunia): elips berpusat di titik mendarat.
func pojok_elips() -> Vector2:
	if _lintasan == null:
		return Vector2.ZERO
	var ukuran: Vector2i = PolaPiksel.ukuran(PolaPiksel.ELIPS_BIASA)
	return Iso.posisi_gambar(_lintasan.titik_mendarat) - Vector2(floori(float(ukuran.x) / 2), floori(float(ukuran.y) / 2))


func _draw() -> void:
	if _lintasan == null:
		return
	var sisi: Vector2 = Vector2.ONE * Config.SWIPE_TITIK_UKURAN_PX
	var geser: Vector2 = Vector2.ONE * floori(float(Config.SWIPE_TITIK_UKURAN_PX) / 2)
	for p: Vector2 in _titik:
		draw_rect(Rect2(p - geser, sisi), Palette.TEXT)
	if _sah:
		GambarPiksel.pola(self, PolaPiksel.ELIPS_SAH, pojok_elips(), Palette.OK)
	else:
		GambarPiksel.pola(self, PolaPiksel.ELIPS_BIASA, pojok_elips(), Palette.TEXT)
