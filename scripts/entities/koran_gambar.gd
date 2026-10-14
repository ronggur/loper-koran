class_name KoranGambar
extends Node2D
## Gambar koran yang dilempar (D-10 run fase2a-lemparan; ART_DIRECTION 6.2 placeholder dari kode, DESIGN_SPEC 3.6). Dua instans di
## `jalan_uji.tscn`, dibedakan `lapisan`:
## - `TANAH` (di antara ubin tanah dan objek dunia): bayangan elips koran yang terbang (`OUTLINE` alpha `KORAN_BAYANGAN_ALPHA`,
##   mengecil saat tinggi naik) dan koran yang sudah mendarat (tergeletak, frame 0) selama penandanya tampil.
## - `UDARA` (di atas objek dunia): koran gulung 8x6 berputar 4 langkah (`PolaPiksel.KORAN_PUTAR`) di posisi udaranya, dan penanda
##   kena/meleset di atas titik mendarat selama `Config.PENANDA_LAMA_DETIK`: bentuk dari `ZonaSasaran.Penanda` (centang, setengah,
##   bintang, silang kecil), warna `OK` untuk sah, `FAIL` untuk tidak sah.
## Node tipis: daftar koran dan semua waktunya ada di `JalanUji` + `KoranLempar` (murni); node hanya menggambar `tampilkan(daftar)`.
## Posisi gambar dibulatkan ke piksel game (`Iso.posisi_gambar_tinggi`, `Iso.posisi_gambar`).

## Lapisan gambar.
enum Lapisan { TANAH, UDARA }

@export var lapisan: Lapisan = Lapisan.UDARA

var _daftar: Array[KoranLempar.Koran] = []


## Mengganti daftar koran yang digambar (dipanggil `JalanUji` tiap langkah). Gambar ulang hanya bila ada yang berubah atau tampil.
func tampilkan(daftar: Array[KoranLempar.Koran]) -> void:
	if daftar.is_empty() and _daftar.is_empty():
		return
	_daftar = daftar
	queue_redraw()


## Jumlah koran yang sedang digambar lapisan ini (terbang, atau tergeletak/penanda yang masih tampil).
func jumlah_tampil() -> int:
	var jumlah: int = 0
	for koran: KoranLempar.Koran in _daftar:
		if KoranLempar.di_udara(koran) or koran.mendarat:
			jumlah += 1
	return jumlah


## Pojok kiri atas gambar koran di udara (piksel game ruang dunia), atau penanda bila sudah mendarat; untuk tes dan probe.
func pojok_koran(koran: KoranLempar.Koran) -> Vector2:
	var p: Vector3 = KoranLempar.posisi(koran)
	var ukuran: Vector2i = PolaPiksel.ukuran(PolaPiksel.pola_koran(0))
	return Iso.posisi_gambar_tinggi(Vector2(p.x, p.y), p.z) - Vector2(floori(float(ukuran.x) / 2), ukuran.y)


func _draw() -> void:
	for koran: KoranLempar.Koran in _daftar:
		if lapisan == Lapisan.TANAH:
			_gambar_tanah(koran)
		else:
			_gambar_udara(koran)


func _gambar_tanah(koran: KoranLempar.Koran) -> void:
	var p: Vector3 = KoranLempar.posisi(koran)
	var tanah: Vector2 = Iso.posisi_gambar(Vector2(p.x, p.y))
	if KoranLempar.di_udara(koran):
		var lebar: int = KoranLempar.lebar_bayangan_px(p.z)
		var tinggi: int = maxi(floori(float(lebar) / 2), 1)
		var asal: Vector2 = tanah - Vector2(floori(float(lebar) / 2), floori(float(tinggi) / 2))
		GambarPiksel.rentang(self, PolaPiksel.rentang_elips(lebar, tinggi), asal, Color(Palette.OUTLINE, Config.KORAN_BAYANGAN_ALPHA))
	elif koran.mendarat:
		GambarPiksel.pola(self, PolaPiksel.pola_koran(0), pojok_koran(koran), Palette.TEXT)


func _gambar_udara(koran: KoranLempar.Koran) -> void:
	if KoranLempar.di_udara(koran):
		GambarPiksel.pola(self, PolaPiksel.pola_koran(KoranLempar.frame_putar(koran, PolaPiksel.KORAN_PUTAR.size())), pojok_koran(koran), Palette.TEXT)
	elif koran.mendarat and KoranLempar.sisa_penanda(koran) > 0.0:
		var pola: Array[String] = PolaPiksel.pola_penanda(koran.penanda)
		var ukuran: Vector2i = PolaPiksel.ukuran(pola)
		var tanah: Vector2 = Iso.posisi_gambar(koran.lintasan.titik_mendarat)
		var pojok: Vector2 = tanah - Vector2(floori(float(ukuran.x) / 2), ukuran.y + Config.PENANDA_ATAS_PX)
		GambarPiksel.pola(self, pola, pojok, warna_penanda(koran.antaran))


## Warna utama penanda: `OK` untuk antaran sah (penuh, setengah, bonus), `FAIL` untuk tidak sah. Bentuknya yang membedakan (D-10).
static func warna_penanda(antaran: ZonaSasaran.Antaran) -> Color:
	return Palette.OK if ZonaSasaran.sah(antaran) else Palette.FAIL
