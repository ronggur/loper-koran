class_name KoranGambar
extends Node2D
## Gambar koran yang dilempar (D-10 run fase2a-lemparan; ART_DIRECTION 6.2 placeholder dari kode, DESIGN_SPEC 3.6). Dua instans di
## `jalan_uji.tscn`, dibedakan `lapisan`:
## - `TANAH` (di antara ubin tanah dan objek dunia): bayangan elips koran yang terbang (`OUTLINE` alpha `KORAN_BAYANGAN_ALPHA`,
##   mengecil saat tinggi naik) dan koran yang sudah mendarat (tergeletak, frame 0) selama penandanya tampil.
## - `UDARA` (di atas objek dunia): koran gulung 8x6 berputar 4 langkah (`PolaPiksel.KORAN_PUTAR`) di posisi udaranya, dan penanda
##   kena/meleset di atas titik mendarat selama `Config.PENANDA_LAMA_DETIK`: bentuk dari `ZonaSasaran.Penanda` (centang, setengah,
##   bintang, silang kecil), warna `OK` untuk sah, `FAIL` untuk tidak sah.
## Run fase5a bagian B (D-3, usulan): `pakai_sprite` true (scene rute) menggambar koran putar, bayangan menurut tinggi, dan koran tergeletak dari sprite gelombang 1 (`SpriteKoran`,
## `DefSprite`) menggantikan pola kode; penanda kena/meleset tetap dari kode. Bawaan false: jalan uji dan probe lama tetap memakai pola kode (D-7: `scenes/dev/*` tidak disentuh).
## Koran yang bertumpu di kotak surat digambar lapisan `UDARA` (kotak surat ada di lapisan objek, di atas `TANAH`).
## Node tipis: daftar koran dan semua waktunya ada di `JalanUji` + `KoranLempar` (murni). Apa yang digambar diputuskan SATU fungsi statis
## `perintah_koran` (perintah `GambarPiksel`, dites headless; QA-003 iterasi 2); `_draw` hanya menjalankan `perintah_tampil`.
## Posisi gambar dibulatkan ke piksel game (`Iso.posisi_gambar_tinggi`, `Iso.posisi_gambar`).

## Lapisan gambar.
enum Lapisan { TANAH, UDARA }

## Sprite yang dipakai mode sprite.
const SPRITE_PAKAI: Array[String] = ["prop_koran_putar", "prop_koran_bayangan", "prop_koran_teras", "prop_koran_rumput", "prop_koran_kotak_surat"]

@export var lapisan: Lapisan = Lapisan.UDARA
## True: koran dan bayangan dari sprite gelombang 1 (scene rute); false: pola placeholder dari kode (jalan uji).
@export var pakai_sprite: bool = false

var _daftar: Array[KoranLempar.Koran] = []
## Tekstur sprite yang dipegang node (dimuat di `_ready`, bukan di `_draw`; lihat `GambarSprite`).
var _tekstur: Dictionary = {}


func _ready() -> void:
	if pakai_sprite:
		_tekstur = GambarSprite.muat(SPRITE_PAKAI)


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


## Perintah gambar semua koran yang sedang digambar lapisan ini (`perintah_koran` tiap koran, urut). `_draw` menjalankan ini.
func perintah_tampil() -> Array:
	var hasil: Array = []
	for koran: KoranLempar.Koran in _daftar:
		hasil.append_array(perintah_koran(lapisan, koran, pakai_sprite))
	return hasil


## Banyaknya tekstur sprite yang dipegang node (untuk tes).
func jumlah_tekstur() -> int:
	return _tekstur.size()


## Item sprite semua koran yang sedang digambar lapisan ini (mode sprite; kosong bila `pakai_sprite` false). `_draw` menggambar ini dulu, lalu `perintah_tampil`.
func item_sprite() -> Array[DefSprite.Item]:
	var hasil: Array[DefSprite.Item] = []
	if not pakai_sprite:
		return hasil
	for koran: KoranLempar.Koran in _daftar:
		hasil.append_array(SpriteKoran.item_tanah(koran) if lapisan == Lapisan.TANAH else SpriteKoran.item_udara(koran))
	return hasil


func _draw() -> void:
	GambarSprite.gambar(self, item_sprite(), _tekstur)
	GambarPiksel.gambar(self, perintah_tampil())


## Perintah gambar (`GambarPiksel`) lapisan `lapisan_gambar` untuk satu koran; kosong = koran tidak tampil di lapisan ini. `sprite` true (mode sprite): koran dan bayangan tidak digambar
## dari pola (sprite dari `SpriteKoran`), hanya penanda yang tersisa.
## - `TANAH`: koran terbang = bayangan elips di titik TANAH koran (`pojok_bayangan`, lebar `KoranLempar.lebar_bayangan_px`, `OUTLINE`
##   alpha `KORAN_BAYANGAN_ALPHA`); sudah mendarat = koran tergeletak (frame 0) di titik mendarat.
## - `UDARA`: koran terbang = koran berputar (`KoranLempar.frame_putar`) di posisi udaranya; sudah mendarat dan penanda masih tampil =
##   penanda bentuk `ZonaSasaran.Penanda` di atas titik mendarat, warna `warna_penanda`.
static func perintah_koran(lapisan_gambar: Lapisan, koran: KoranLempar.Koran, sprite: bool = false) -> Array:
	if lapisan_gambar == Lapisan.TANAH:
		if sprite:
			return []
		if KoranLempar.di_udara(koran):
			var lebar: int = KoranLempar.lebar_bayangan_px(KoranLempar.posisi(koran).z)
			var warna: Color = Color(Palette.OUTLINE, Config.KORAN_BAYANGAN_ALPHA)
			return GambarPiksel.perintah_rentang(PolaPiksel.rentang_elips(lebar, tinggi_bayangan_px(lebar)), pojok_bayangan(koran), warna)
		if koran.mendarat:
			return GambarPiksel.perintah_pola(PolaPiksel.pola_koran(0), pojok_koran(koran), Palette.TEXT)
		return []
	if KoranLempar.di_udara(koran):
		if sprite:
			return []
		var frame: int = KoranLempar.frame_putar(koran, PolaPiksel.KORAN_PUTAR.size())
		return GambarPiksel.perintah_pola(PolaPiksel.pola_koran(frame), pojok_koran(koran), Palette.TEXT)
	if koran.mendarat and KoranLempar.sisa_penanda(koran) > 0.0:
		return GambarPiksel.perintah_pola(PolaPiksel.pola_penanda(koran.penanda), pojok_penanda(koran), warna_penanda_koran(koran))
	return []


## Tinggi elips bayangan selebar `lebar` piksel: setengahnya, paling sedikit 1 piksel.
static func tinggi_bayangan_px(lebar: int) -> int:
	return maxi(floori(float(lebar) / 2), 1)


## Pojok kiri atas elips bayangan koran (piksel game ruang dunia): elips berpusat di titik TANAH koran (bukan posisi udaranya).
static func pojok_bayangan(koran: KoranLempar.Koran) -> Vector2:
	var p: Vector3 = KoranLempar.posisi(koran)
	var lebar: int = KoranLempar.lebar_bayangan_px(p.z)
	return Iso.posisi_gambar(Vector2(p.x, p.y)) - Vector2(floori(float(lebar) / 2), floori(float(tinggi_bayangan_px(lebar)) / 2))


## Pojok kiri atas penanda (piksel game ruang dunia): kaki penanda `PENANDA_ATAS_PX` di atas titik mendarat, tengah mendatar.
static func pojok_penanda(koran: KoranLempar.Koran) -> Vector2:
	var ukuran: Vector2i = PolaPiksel.ukuran(PolaPiksel.pola_penanda(koran.penanda))
	return Iso.posisi_gambar(koran.lintasan.titik_mendarat) - Vector2(floori(float(ukuran.x) / 2), ukuran.y + Config.PENANDA_ATAS_PX)


## Pojok kiri atas gambar koran (piksel game ruang dunia): di posisi udaranya, atau tergeletak di titik mendarat bila sudah mendarat.
static func pojok_koran(koran: KoranLempar.Koran) -> Vector2:
	var p: Vector3 = KoranLempar.posisi(koran)
	var ukuran: Vector2i = PolaPiksel.ukuran(PolaPiksel.pola_koran(0))
	return Iso.posisi_gambar_tinggi(Vector2(p.x, p.y), p.z) - Vector2(floori(float(ukuran.x) / 2), ukuran.y)


## Warna utama penanda koran yang sudah dinilai: penanda netral (O-1 run fase3b-rintangan-skor, rumah sudah terantar) `TEXT_2` walau
## zonanya sah; selain itu `warna_penanda` dari status antaran (tepat = `OK`, bentuknya yang membedakan dari centang).
static func warna_penanda_koran(koran: KoranLempar.Koran) -> Color:
	if koran.penanda == ZonaSasaran.Penanda.NETRAL:
		return Palette.TEXT_2
	return warna_penanda(koran.antaran)


## Warna utama penanda: `OK` untuk antaran sah (penuh, setengah, bonus), `FAIL` untuk tidak sah. Bentuknya yang membedakan (D-10).
static func warna_penanda(antaran: ZonaSasaran.Antaran) -> Color:
	return Palette.OK if ZonaSasaran.sah(antaran) else Palette.FAIL
