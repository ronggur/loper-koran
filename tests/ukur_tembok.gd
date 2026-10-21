class_name UkurTembok
extends RefCounted
## Pengukur piksel sasaran sisi dekat yang tertutup tembok, pembantu tes dan probe (run fase5b-tembok-dekor bagian B1, AC-8; pola `SpikeSisiDekat.sasaran_tertutup`).
##
## Rute buatan: satu rumah sisi `dekat` pelanggan di kavling `maju_awal_ubin` (rute perumahan nyata tidak punya pelanggan dekat). Gambar dihitung dari
## fungsi produksi yang sama dengan scene rute (`TembokDekat.potongan`/`titik_dunia`, `SpriteRumah.pusat_gambar_dunia`, `Iso.posisi_gambar`) dan
## piksel PNG aslinya; hanya piksel OPAK (alfa penuh) yang dihitung, bayangan tanah beralfa sebagian tidak. "Menimpa" = piksel sasaran yang
## tertimpa piksel opak sprite yang digambar di DEPANNYA menurut Y-sort (posisi tegak pijak lebih besar); zona digambar di tanah, di bawah semua objek,
## jadi semua sprite dihitung untuk zona. Kunci hasil: `kotak_badan` (badan sprite kotak surat), `zona_kotak`, `zona_teras`, `zona_halaman`, tiap satu untuk tembok
## (modul dan tiang) dan `rumah_*` untuk sprite rumah; sufiks `_geom` = semua piksel opak yang berimpit, tanpa aturan urutan gambar. Nilai 0..1.

const ALFA_OPAK: float = 0.99
const FOLDER_KOTAK: String = "res://assets/sprites/props/prop_kotak_surat.png"
## Pojok kiri atas sprite kotak surat dari titik pijaknya (offset di `scenes/entities/kotak_surat.tscn`).
const OFFSET_KOTAK: Vector2i = Vector2i(-10, -26)

static var _gambar: Dictionary = {}


## Rumah dekat pelanggan buatan di `maju_awal_ubin` dengan `jenis` (mis. `dekat_limasan`).
static func rumah_buatan(maju_awal_ubin: float, jenis: String) -> RouteBuilder.RumahRute:
	var rumah: RouteBuilder.RumahRute = RouteBuilder.RumahRute.new()
	rumah.id_segmen = "ukur"
	rumah.pos = int(maju_awal_ubin)
	rumah.id = "ukur@%s" % [str(maju_awal_ubin)]
	rumah.maju_ubin = maju_awal_ubin
	rumah.sisi = LoperAnim.Sisi.DEKAT
	rumah.jenis = jenis
	rumah.pelanggan_boleh = true
	rumah.pelanggan = true
	return rumah


## Hasil ukur untuk rumah dekat di `maju_awal_ubin` bertembok varian `varian` dan atap `jenis`.
static func ukur(maju_awal_ubin: float, jenis: String, varian: String) -> Dictionary:
	var rumah: RouteBuilder.RumahRute = rumah_buatan(maju_awal_ubin, jenis)
	# Sprite gambar: [gambar, pojok kiri atas, y_urut], tembok dan rumah terpisah.
	var tembok: Array = []
	for potong: TembokDekat.Potongan in TembokDekat.potongan(rumah):
		var nama: String = potong.nama if potong.tiang else TembokDekat.nama_modul(varian)
		var titik: Vector2 = Iso.posisi_gambar(TembokDekat.titik_dunia(potong))
		tembok.append([_muat(TembokDekat.jalur_png(nama)), Vector2i(titik) - TembokDekat.pijak(), titik.y])
	var nama_rumah: String = SpriteRumah.nama_rumah(rumah)
	var titik_rumah: Vector2 = Iso.posisi_gambar(SpriteRumah.pusat_gambar_dunia(rumah))
	var daftar_rumah: Array = [[_muat(SpriteRumah.jalur_png(nama_rumah)), Vector2i(titik_rumah) - SpriteRumah.titik_pijak(nama_rumah), titik_rumah.y]]
	var zona_jenis: Dictionary = {}
	for zona: ZonaSasaran.Zona in ZonaSasaran.zona_rumah(rumah):
		zona_jenis[zona.jenis] = zona
	var pusat: Vector2 = (zona_jenis[ZonaSasaran.Jenis.KOTAK_SURAT] as ZonaSasaran.Zona).persegi.get_center()
	var titik_kotak: Vector2 = Iso.posisi_gambar(Vector2(pusat.x, -pusat.y))
	var pojok_kotak: Vector2i = Vector2i(titik_kotak) + OFFSET_KOTAK
	var badan: Array[Vector2i] = []
	var gambar_kotak: Image = _muat(FOLDER_KOTAK)
	for y: int in range(gambar_kotak.get_height()):
		for x: int in range(gambar_kotak.get_width()):
			if gambar_kotak.get_pixel(x, y).a >= ALFA_OPAK:
				badan.append(pojok_kotak + Vector2i(x, y))
	var hasil: Dictionary = {}
	for sasaran: Array in [["kotak_badan", badan, titik_kotak.y], ["zona_kotak", _piksel_zona(zona_jenis[ZonaSasaran.Jenis.KOTAK_SURAT]), -INF], ["zona_teras", _piksel_zona(zona_jenis[ZonaSasaran.Jenis.TERAS]), -INF], ["zona_halaman", _piksel_zona(zona_jenis[ZonaSasaran.Jenis.HALAMAN]), -INF]]:
		var nama_kunci: String = sasaran[0]
		var titik: Array[Vector2i] = sasaran[1]
		var acuan: float = sasaran[2]
		hasil[nama_kunci] = _pecahan(titik, tembok, acuan)
		hasil[nama_kunci + "_geom"] = _pecahan(titik, tembok, -INF)
		hasil["rumah_" + nama_kunci] = _pecahan(titik, daftar_rumah, acuan)
	hasil["jumlah_badan"] = badan.size()
	return hasil


## Pecahan `titik` yang tertimpa piksel opak salah satu sprite di `sprite` (tiap isi [gambar, pojok, y_urut]) yang digambar di depan `y_acuan` (sprite dengan y_urut > y_acuan).
static func _pecahan(titik: Array[Vector2i], sprite: Array, y_acuan: float) -> float:
	if titik.is_empty():
		return 0.0
	var kena: int = 0
	for t: Vector2i in titik:
		for s: Array in sprite:
			if (s[2] as float) <= y_acuan:
				continue
			var gambar: Image = s[0]
			var lokal: Vector2i = t - (s[1] as Vector2i)
			if lokal.x >= 0 and lokal.y >= 0 and lokal.x < gambar.get_width() and lokal.y < gambar.get_height() and gambar.get_pixelv(lokal).a >= ALFA_OPAK:
				kena += 1
				break
	return float(kena) / float(titik.size())


static func _piksel_zona(zona: ZonaSasaran.Zona) -> Array[Vector2i]:
	var hasil: Array[Vector2i] = []
	for r: Vector3i in PolaPiksel.rentang_poligon(PolaPiksel.sudut_zona(zona.persegi)):
		for x: int in range(r.y, r.z):
			hasil.append(Vector2i(x, r.x))
	return hasil


static func _muat(jalur: String) -> Image:
	if not _gambar.has(jalur):
		_gambar[jalur] = (load(jalur) as Texture2D).get_image()
	return _gambar[jalur]
