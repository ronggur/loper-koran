class_name UkurDekor
extends RefCounted
## Pengukur piksel dekor yang menimpa sasaran seberang, pembantu tes dan probe (run fase5b-tembok-dekor bagian B2, AC-12; pola `UkurTembok`).
##
## Tata letak nyata satu segmen (rumah seberang dan dekor, maju relatif ke awal segmen; letak layar tidak bergantung pada awal segmen karena maju bulat bergeser kelipatan satu ubin): gambar dihitung
## dari fungsi produksi yang sama dengan scene rute (`DekorRute.titik_dunia`, `DekorRute.pijak`, `SpriteRumah.titik_kotak_surat_dunia`, `Iso.posisi_gambar`) dan piksel PNG aslinya; hanya piksel OPAK
## (alfa penuh) yang dihitung, bayangan tanah beralfa sebagian tidak. Sasaran per rumah seberang (hanya yang `pelanggan_boleh` bila diminta): badan sprite kotak surat sasaran, zona kotak surat, zona teras.
## Kunci hasil (nilai 0..1, terburuk di semua rumah): `kotak_badan` (hanya dekor yang digambar di DEPAN kotak surat menurut Y-sort: posisi tegak pijak lebih besar), `zona_kotak`, `zona_teras` (semua
## dekor, zona digambar di tanah di bawah semua objek), dan `*_geom` = badan tanpa aturan urutan. `jumlah_rumah` dan `jumlah_dekor` = banyaknya yang diukur.

const ALFA_OPAK: float = 0.99
const JALUR_KOTAK: String = "res://assets/sprites/props/prop_kotak_surat.png"
## Pojok kiri atas sprite kotak surat dari titik pijaknya (offset di `scenes/entities/kotak_surat.tscn`).
const OFFSET_KOTAK: Vector2i = Vector2i(-10, -26)

static var _gambar: Dictionary = {}


## Ukur satu segmen. `hanya_pelanggan_boleh` true = hanya rumah seberang yang `pelanggan_boleh` jadi sasaran (AC-12); false = semua rumah seberang.
static func ukur(segmen: SegmenRute, hanya_pelanggan_boleh: bool = true) -> Dictionary:
	var sprite_dekor: Array = []
	for d: SegmenRute.Dekor in segmen.dekor:
		var nama: String = DekorRute.nama_sprite(d.jenis, d.varian, d.sisi)
		var titik: Vector2 = Iso.posisi_gambar(DekorRute.titik_dunia(d.jenis, d.sisi, float(d.pos)))
		sprite_dekor.append([_muat(DekorRute.jalur_png(nama)), Vector2i(titik) - DekorRute.pijak(nama), titik.y])
	var hasil: Dictionary = {"kotak_badan": 0.0, "kotak_badan_geom": 0.0, "zona_kotak": 0.0, "zona_teras": 0.0, "jumlah_rumah": 0, "jumlah_dekor": sprite_dekor.size()}
	var kotak: Image = _muat(JALUR_KOTAK)
	for r: SegmenRute.Rumah in segmen.rumah:
		if r.sisi != LoperAnim.Sisi.SEBERANG or (hanya_pelanggan_boleh and not r.pelanggan_boleh):
			continue
		var rumah: RouteBuilder.RumahRute = RouteBuilder.RumahRute.new()
		rumah.sisi = r.sisi
		rumah.maju_ubin = float(r.pos)
		rumah.pelanggan = true
		hasil["jumlah_rumah"] = int(hasil["jumlah_rumah"]) + 1
		var titik_kotak: Vector2 = Iso.posisi_gambar(SpriteRumah.titik_kotak_surat_dunia(rumah))
		var pojok: Vector2i = Vector2i(titik_kotak) + OFFSET_KOTAK
		var badan: Array[Vector2i] = []
		for y: int in range(kotak.get_height()):
			for x: int in range(kotak.get_width()):
				if kotak.get_pixel(x, y).a >= ALFA_OPAK:
					badan.append(pojok + Vector2i(x, y))
		_maks(hasil, "kotak_badan", _pecahan(badan, sprite_dekor, titik_kotak.y))
		_maks(hasil, "kotak_badan_geom", _pecahan(badan, sprite_dekor, -INF))
		for zona: ZonaSasaran.Zona in ZonaSasaran.zona_rumah(rumah):
			if zona.jenis == ZonaSasaran.Jenis.KOTAK_SURAT:
				_maks(hasil, "zona_kotak", _pecahan(_piksel_zona(zona), sprite_dekor, -INF))
			elif zona.jenis == ZonaSasaran.Jenis.TERAS:
				_maks(hasil, "zona_teras", _pecahan(_piksel_zona(zona), sprite_dekor, -INF))
	return hasil


static func _maks(hasil: Dictionary, kunci: String, nilai: float) -> void:
	hasil[kunci] = maxf(float(hasil[kunci]), nilai)


## Pecahan `titik` yang tertimpa piksel opak salah satu sprite di `sprite` (tiap isi [gambar, pojok, y_urut]) yang digambar di depan `y_acuan` (y_urut > y_acuan).
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
