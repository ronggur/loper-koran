class_name GarisBidik
extends Node2D
## Garis bidik lemparan di RUANG DUNIA (D-5 run fase2a-lemparan, DESIGN_SPEC 3.7): titik 2 px tiap 4 px warna `TEXT` sepanjang lintasan
## yang sama persis dengan lemparan (sampel `ThrowSolver.posisi_pada` lewat `KoranLempar.waktu_titik_bidik`, lengkung terlihat), berakhir
## di elips pendaratan 10x5 px di tanah. Bentuk elips (`KoranLempar.Elips`): ke sasaran sah = elips TERISI warna `OK` bergaris luar (bentuk
## berbeda, bukan hanya warna); titik mendarat tertutup rumah dari sudut kamera = cincin PUTUS-PUTUS redup; selain itu cincin `TEXT`.
## Titik garis bidik yang tertutup rumah juga redup (`GARIS_BIDIK_TERTUTUP_ALPHA`), jadi ujung garis di belakang fasad tidak terbaca
## sebagai sasaran di atap (QA-004 iterasi 2; node ini tetap digambar di atas objek dunia, redup = "di balik rumah").
##
## Node tipis: lintasan dan bentuk elips dihitung `JalanUji` tiap frame dari keadaan sepeda sebenarnya (`tampilkan`), node ini hanya
## menyimpan dan menggambar. Anak dunia (ikut kamera), digambar di atas objek dunia. Posisi titik dibulatkan ke piksel game
## (pixel-perfect). Keputusan gambar lewat `warna_titik` dan `perintah_elips` (dites headless).

var _lintasan: ThrowSolver.Lintasan = null
var _bentuk: KoranLempar.Elips = KoranLempar.Elips.BIASA
var _titik: PackedVector2Array = PackedVector2Array()
var _tertutup: PackedByteArray = PackedByteArray()


## Menampilkan garis bidik untuk `lintasan` (null = sembunyikan) dengan bentuk elips `bentuk` (`KoranLempar.bentuk_elips`).
func tampilkan(lintasan: ThrowSolver.Lintasan, bentuk: KoranLempar.Elips) -> void:
	if lintasan == null:
		sembunyikan()
		return
	_lintasan = lintasan
	_bentuk = bentuk
	_titik.clear()
	_tertutup.clear()
	for t: float in KoranLempar.waktu_titik_bidik(lintasan, float(Config.SWIPE_TITIK_JARAK_PX), Config.GARIS_BIDIK_SAMPEL):
		_titik.append(KoranLempar.layar_pada(lintasan, t).round())
		_tertutup.append(1 if KoranLempar.tertutup_pada(lintasan, t) else 0)
	queue_redraw()


## Menyembunyikan garis bidik (jari dilepas, swipe batal, koran habis, jeda antar lempar, jeda game).
func sembunyikan() -> void:
	if _lintasan == null:
		return
	_lintasan = null
	_bentuk = KoranLempar.Elips.BIASA
	_titik.clear()
	_tertutup.clear()
	queue_redraw()


## True bila garis bidik sedang tampil.
func tampil() -> bool:
	return _lintasan != null


## Lintasan yang sedang ditampilkan (null bila tidak tampil).
func lintasan() -> ThrowSolver.Lintasan:
	return _lintasan


## True bila elips menunjukkan sasaran sah (`OK`, terisi).
func elips_sah() -> bool:
	return _lintasan != null and _bentuk == KoranLempar.Elips.SAH


## Bentuk elips yang sedang tampil (`BIASA` bila tidak tampil).
func bentuk_elips() -> KoranLempar.Elips:
	return _bentuk if _lintasan != null else KoranLempar.Elips.BIASA


## Titik akhir garis bidik (ujung lintasan yang ditampilkan): x, y = titik mendarat di dunia (ubin), z = tinggi (0).
func titik_akhir() -> Vector3:
	if _lintasan == null:
		return Vector3.ZERO
	return ThrowSolver.posisi_pada(_lintasan, _lintasan.lama_terbang)


## Titik gambar garis bidik (pusat titik, piksel game ruang dunia, bulat), untuk tes dan probe.
func titik_gambar() -> PackedVector2Array:
	return _titik


## True bila titik garis bidik ke-`i` tertutup rumah dari sudut kamera (digambar redup).
func titik_tertutup(i: int) -> bool:
	return i >= 0 and i < _tertutup.size() and _tertutup[i] != 0


## Warna titik garis bidik ke-`i`: `TEXT`, redup `GARIS_BIDIK_TERTUTUP_ALPHA` bila tertutup rumah.
func warna_titik(i: int) -> Color:
	return Color(Palette.TEXT, Config.GARIS_BIDIK_TERTUTUP_ALPHA) if titik_tertutup(i) else Palette.TEXT


## Pojok kiri atas elips pendaratan (piksel game ruang dunia): elips berpusat di titik mendarat.
func pojok_elips() -> Vector2:
	if _lintasan == null:
		return Vector2.ZERO
	var ukuran: Vector2i = PolaPiksel.ukuran(PolaPiksel.ELIPS_BIASA)
	return Iso.posisi_gambar(_lintasan.titik_mendarat) - Vector2(floori(float(ukuran.x) / 2), floori(float(ukuran.y) / 2))


## Perintah gambar (`GambarPiksel`) elips pendaratan menurut bentuknya; kosong bila tidak tampil.
func perintah_elips() -> Array:
	if _lintasan == null:
		return []
	match _bentuk:
		KoranLempar.Elips.SAH:
			return GambarPiksel.perintah_pola(PolaPiksel.ELIPS_SAH, pojok_elips(), Palette.OK)
		KoranLempar.Elips.TERTUTUP:
			return GambarPiksel.perintah_pola(PolaPiksel.ELIPS_TERTUTUP, pojok_elips(), Palette.TEXT, Config.GARIS_BIDIK_TERTUTUP_ALPHA)
	return GambarPiksel.perintah_pola(PolaPiksel.ELIPS_BIASA, pojok_elips(), Palette.TEXT)


func _draw() -> void:
	if _lintasan == null:
		return
	var sisi: Vector2 = Vector2.ONE * Config.SWIPE_TITIK_UKURAN_PX
	var geser: Vector2 = Vector2.ONE * floori(float(Config.SWIPE_TITIK_UKURAN_PX) / 2)
	for i: int in range(_titik.size()):
		draw_rect(Rect2(_titik[i] - geser, sisi), warna_titik(i))
	GambarPiksel.gambar(self, perintah_elips())
