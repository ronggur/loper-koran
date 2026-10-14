class_name PolaPiksel
extends RefCounted
## Pola piksel placeholder dari kode dan rasterisasi bentuk ke rentang piksel game, logika murni (D-5, D-6, D-10 run fase2a-lemparan
## bagian 1b; ART_DIRECTION 6.2, DESIGN_SPEC 3.5-3.7). Belum ada sheet koran atau penanda di repo, jadi bentuknya ditulis di sini sebagai
## baris teks dan digambar node per piksel game (persegi bulat, tajam di skala bulat). Warna TIDAK ada di sini: tiap huruf adalah peran
## warna yang dipetakan node ke `Palette`:
## - `.` kosong, `o` garis luar (`OUTLINE`), `t` kertas (`TEXT`), `s` nada kedua (`TEXT_2`), `w` warna utama yang diberikan pemanggil
##   (mis. `OK` untuk sah, `FAIL` untuk tidak sah, `TEXT` untuk elips biasa).
## Rentang (`Vector3i`): x = baris (y), y = kolom awal, z = kolom akhir eksklusif, piksel game.

## Koran gulung berputar, 4 langkah putar (0, serong naik, tegak, serong turun), masing-masing 8x6 (ART_DIRECTION 6.2).
const KORAN_PUTAR: Array = [
	["........", ".oooooo.", "otsttsto", "otsttsto", ".oooooo.", "........"],
	["....ooo.", "..ootsto", ".otstoo.", "otsoo...", ".oo.....", "........"],
	["...oo...", "..otto..", "..osso..", "..otto..", "..osso..", "...oo..."],
	[".ooo....", "otstoo..", ".oostto.", "...oosto", ".....oo.", "........"],
]
## Ikon koran HUD 12x12 (DESIGN_SPEC 3.5).
const IKON_KORAN: Array[String] = ["............", "............", ".oooooooooo.", "otsttsttstto", "otsttsttstto", "otsttsttstto", "otsttsttstto", ".oooooooooo.", "............", "............", "............", "............"]
## Elips pendaratan garis bidik 10x5 (DESIGN_SPEC 3.7): biasa = cincin `w` (TEXT).
const ELIPS_BIASA: Array[String] = ["..wwwwww..", ".w......w.", "w........w", ".w......w.", "..wwwwww.."]
## Elips pendaratan saat mengarah ke sasaran sah: elips TERISI `w` (OK) bergaris luar, bentuk berbeda dari elips biasa (D-5).
const ELIPS_SAH: Array[String] = ["..oooooo..", ".owwwwwwo.", "owwwwwwwwo", ".owwwwwwo.", "..oooooo.."]
## Elips pendaratan yang tertutup rumah dari sudut kamera (QA-004): cincin putus-putus `w` (TEXT, digambar redup), bentuk berbeda dari
## elips biasa dan elips sah, supaya tidak terbaca sebagai sasaran di atap atau dinding.
const ELIPS_TERTUTUP: Array[String] = ["..ww..ww..", ".w......w.", "..........", ".w......w.", "..ww..ww.."]
## Penanda sah penuh: centang (D-10).
const PENANDA_CENTANG: Array[String] = ["......ooo", ".....owwo", "oo..owwo.", "owwowwo..", ".owwwo...", "..owo....", "...o....."]
## Penanda sah setengah (halaman): belah ketupat yang hanya terisi separuh.
const PENANDA_SETENGAH: Array[String] = ["...o...", "..owo..", ".owo.o.", "owwo..o", ".owo.o.", "..owo..", "...o..."]
## Penanda sah bonus (jendela dengan sakelar bonus): bintang, berbeda dari centang.
const PENANDA_BINTANG: Array[String] = ["....o....", "...owo...", "oooowoooo", "owwwwwwwo", ".owwwwwo.", "..owwwo..", ".owwowwo.", "owwo.owwo", "ooo...ooo"]
## Penanda tidak sah (meleset, bukan pelanggan, jendela penalti): silang kecil, bukan panel merah besar (DESIGN_SPEC 3.6).
const PENANDA_SILANG: Array[String] = ["oo...oo", "owo.owo", ".owowo.", "..owo..", ".owowo.", "owo.owo", "oo...oo"]
## Penanda rumah bukan pelanggan di halaman (D-6): cakram `w` (RADAR_BUKAN) bergaris luar dengan garis miring, bentuk berbeda dari zona
## pelanggan.
const TANDA_BUKAN_PELANGGAN: Array[String] = ["..ooooo..", ".owwwwoo.", "owwwwoowo", "owwwoowwo", "owwoowwwo", "owoowwwwo", ".oowwwwo.", "..ooooo.."]


## Pola penanda untuk bentuk `penanda` (`ZonaSasaran.Penanda`).
static func pola_penanda(penanda: ZonaSasaran.Penanda) -> Array[String]:
	match penanda:
		ZonaSasaran.Penanda.CENTANG:
			return PENANDA_CENTANG
		ZonaSasaran.Penanda.SETENGAH:
			return PENANDA_SETENGAH
		ZonaSasaran.Penanda.BINTANG:
			return PENANDA_BINTANG
	return PENANDA_SILANG


## Pola koran berputar untuk frame `frame` (dijepit memutar, `posmod`).
static func pola_koran(frame: int) -> Array[String]:
	var hasil: Array[String] = []
	hasil.assign(KORAN_PUTAR[posmod(frame, KORAN_PUTAR.size())])
	return hasil


## Ukuran pola (lebar = panjang baris pertama, tinggi = jumlah baris), piksel game.
static func ukuran(pola: Array[String]) -> Vector2i:
	if pola.is_empty():
		return Vector2i.ZERO
	return Vector2i(pola[0].length(), pola.size())


## Rentang piksel pola untuk satu huruf peran: tiap rentang = deret huruf `huruf` yang berurutan di satu baris.
static func rentang_huruf(pola: Array[String], huruf: String) -> Array[Vector3i]:
	var hasil: Array[Vector3i] = []
	for y: int in range(pola.size()):
		var baris: String = pola[y]
		var awal: int = -1
		for x: int in range(baris.length() + 1):
			var sama: bool = x < baris.length() and baris[x] == huruf
			if sama and awal < 0:
				awal = x
			elif not sama and awal >= 0:
				hasil.append(Vector3i(y, awal, x))
				awal = -1
	return hasil


## Rentang piksel elips terisi selebar `lebar` dan setinggi `tinggi` piksel (bayangan koran), relatif ke pojok kiri atas kotaknya.
## Piksel diisi bila pusatnya di dalam elips; tiap baris paling sedikit satu piksel.
static func rentang_elips(lebar: int, tinggi: int) -> Array[Vector3i]:
	var hasil: Array[Vector3i] = []
	if lebar < 1 or tinggi < 1:
		return hasil
	var rx: float = float(lebar) / 2
	var ry: float = float(tinggi) / 2
	for y: int in range(tinggi):
		var dy: float = (float(y) + 1.0 / 2 - ry) / ry
		var setengah: float = rx * sqrt(maxf(1.0 - dy * dy, 0.0))
		var awal: int = clampi(ceili(rx - setengah - 1.0 / 2), 0, lebar - 1)
		var akhir: int = clampi(ceili(rx + setengah - 1.0 / 2), awal + 1, lebar)
		hasil.append(Vector3i(y, awal, akhir))
	return hasil


## Empat sudut layar (piksel game, ruang dunia) persegi zona dalam koordinat JALAN (x = lateral, y = maju, `ZonaSasaran`).
static func sudut_zona(persegi_jalan: Rect2) -> PackedVector2Array:
	var a: Vector2 = persegi_jalan.position
	var b: Vector2 = persegi_jalan.end
	return PackedVector2Array([
		Iso.dunia_ke_layar(Vector2(a.x, -a.y)),
		Iso.dunia_ke_layar(Vector2(b.x, -a.y)),
		Iso.dunia_ke_layar(Vector2(b.x, -b.y)),
		Iso.dunia_ke_layar(Vector2(a.x, -b.y)),
	])


## Rentang piksel poligon cembung `sudut` (piksel game): piksel diisi bila pusatnya di dalam (tepi kiri inklusif, kanan eksklusif).
## Belah ketupat iso 2:1 menghasilkan tepi bertangga 2x1 yang tajam.
static func rentang_poligon(sudut: PackedVector2Array) -> Array[Vector3i]:
	var hasil: Array[Vector3i] = []
	if sudut.size() <= 2:
		return hasil
	var atas: float = INF
	var bawah: float = -INF
	for p: Vector2 in sudut:
		atas = minf(atas, p.y)
		bawah = maxf(bawah, p.y)
	for y: int in range(floori(atas), ceili(bawah)):
		var tengah: float = float(y) + 1.0 / 2
		var x_min: float = INF
		var x_maks: float = -INF
		for i: int in range(sudut.size()):
			var p: Vector2 = sudut[i]
			var q: Vector2 = sudut[(i + 1) % sudut.size()]
			if (p.y <= tengah and tengah < q.y) or (q.y <= tengah and tengah < p.y):
				var x: float = p.x + (tengah - p.y) * (q.x - p.x) / (q.y - p.y)
				x_min = minf(x_min, x)
				x_maks = maxf(x_maks, x)
		if not is_finite(x_min) or not is_finite(x_maks):
			continue
		var awal: int = ceili(x_min - 1.0 / 2)
		var akhir: int = ceili(x_maks - 1.0 / 2)
		if akhir > awal:
			hasil.append(Vector3i(y, awal, akhir))
	return hasil


## Rentang tepi (garis luar 1 piksel) dari rentang isi: piksel isi yang tetangga atas, bawah, kiri, atau kanannya kosong.
static func rentang_tepi(isi: Array[Vector3i]) -> Array[Vector3i]:
	var per_baris: Dictionary = {}
	for r: Vector3i in isi:
		per_baris[r.x] = r
	var hasil: Array[Vector3i] = []
	for r: Vector3i in isi:
		if not per_baris.has(r.x - 1) or not per_baris.has(r.x + 1):
			hasil.append(r)
			continue
		var atas: Vector3i = per_baris[r.x - 1]
		var bawah: Vector3i = per_baris[r.x + 1]
		var tepi_awal_akhir: int = mini(maxi(maxi(atas.y, bawah.y), r.y + 1), r.z)
		hasil.append(Vector3i(r.x, r.y, tepi_awal_akhir))
		var tepi_akhir_awal: int = maxi(mini(mini(atas.z, bawah.z), r.z - 1), tepi_awal_akhir)
		if tepi_akhir_awal < r.z:
			hasil.append(Vector3i(r.x, tepi_akhir_awal, r.z))
	return hasil
