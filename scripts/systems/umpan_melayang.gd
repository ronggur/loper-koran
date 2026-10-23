class_name UmpanMelayang
extends RefCounted
## Umpan balik melayang di titik mendarat, logika murni (DESIGN_SPEC 3.6; AC-13 run fase3b-rintangan-skor bagian B, versi minimal usulan).
##
## Tiap antaran sah (`SkorRute.Status.ANTAR`) menambah satu entri di titik mendaratnya: ongkos antar ("+15"), tip bila ada, dan "TEPAT"
## bila tepat. Entri naik `UMPAN_MELAYANG_NAIK_PX` dan memudar selama `UMPAN_MELAYANG_DETIK`; paling banyak `UMPAN_MELAYANG_MAKS`
## sekaligus, yang lama hilang lebih dulu. Koran ulang (netral) dan tidak sah tidak memunculkan entri antaran (ikon penanda kena/meleset cukup, DESIGN_SPEC 3.6),
## tetapi koran terbuang (`SkorRute.hasil_terbuang`, run fase6a2 bagian B, O-3) menambah entri potongan ("-5", `dari_potongan`) di titik mendaratnya: nada netral, tanpa bintang atau koin.
## Waktu ikut `dt` efektif (jeda membekukan). Teksnya disusun node (`UmpanMelayangGambar`) lewat kunci terjemahan; di sini hanya angka.


## Satu umpan balik.
class Entri extends RefCounted:
	## Titik mendarat di dunia (ubin, y dunia = -maju).
	var titik_dunia: Vector2 = Vector2.ZERO
	## Ongkos antar (tanpa tip), koin.
	var ongkos: int = 0
	## Tip, koin (0 = tanpa tip).
	var tip: int = 0
	var tepat: bool = false
	## Potongan koran terbuang, koin (> 0 = entri potongan "-5": tanpa ongkos, tip, TEPAT, bintang, dan koin).
	var potongan: int = 0
	## Sisa waktu tampil, detik.
	var sisa_detik: float = 0.0

	func salin() -> Entri:
		var baru: Entri = Entri.new()
		baru.titik_dunia = titik_dunia
		baru.ongkos = ongkos
		baru.tip = tip
		baru.tepat = tepat
		baru.potongan = potongan
		baru.sisa_detik = sisa_detik
		return baru


## Entri untuk hasil skor `hasil` di titik dunia `titik_dunia`, atau null bila bukan antaran sah.
static func dari_hasil(hasil: SkorRute.Hasil, titik_dunia: Vector2) -> Entri:
	if hasil == null or hasil.status != SkorRute.Status.ANTAR:
		return null
	var e: Entri = Entri.new()
	e.titik_dunia = titik_dunia
	e.tip = hasil.tip
	e.ongkos = hasil.koin_tambah - hasil.tip
	e.tepat = hasil.tepat
	e.sisa_detik = Config.UMPAN_MELAYANG_DETIK
	return e


## Entri potongan `jumlah` koin di titik dunia `titik_dunia` (O-3), atau null bila `jumlah` <= 0.
static func dari_potongan(jumlah: int, titik_dunia: Vector2) -> Entri:
	if jumlah <= 0:
		return null
	var e: Entri = Entri.new()
	e.titik_dunia = titik_dunia
	e.potongan = jumlah
	e.sisa_detik = Config.UMPAN_MELAYANG_DETIK
	return e


## Daftar baru dengan `entri` ditambahkan di akhir; yang paling lama dibuang sampai paling banyak `UMPAN_MELAYANG_MAKS`. Entri null =
## daftar tidak berubah. Masukan tidak diubah.
static func tambah(daftar: Array[Entri], entri: Entri) -> Array[Entri]:
	var hasil: Array[Entri] = daftar.duplicate()
	if entri == null:
		return hasil
	hasil.append(entri)
	while hasil.size() > maxi(Config.UMPAN_MELAYANG_MAKS, 0):
		hasil.remove_at(0)
	return hasil


## Daftar sesudah `dt` detik: sisa waktu berkurang, entri yang habis dibuang. `dt` nol, negatif, atau tidak hingga = tidak berubah. Masukan
## tidak diubah.
static func langkah(daftar: Array[Entri], dt: float) -> Array[Entri]:
	var hasil: Array[Entri] = []
	var maju: bool = is_finite(dt) and dt > 0.0
	for lama: Entri in daftar:
		var e: Entri = lama.salin()
		if maju:
			e.sisa_detik -= dt
		if e.sisa_detik > Config.TABRAKAN_TOLERANSI_DETIK:
			hasil.append(e)
	return hasil


## Geseran naik entri, piksel game: 0 saat muncul sampai `UMPAN_MELAYANG_NAIK_PX` saat habis (dibulatkan ke piksel).
static func naik_px(e: Entri) -> int:
	if Config.UMPAN_MELAYANG_DETIK <= 0.0:
		return 0
	var lewat: float = clampf(1.0 - e.sisa_detik / Config.UMPAN_MELAYANG_DETIK, 0.0, 1.0)
	return roundi(lewat * float(Config.UMPAN_MELAYANG_NAIK_PX))


## Alpha entri: 1,0 saat muncul, turun lurus ke 0 saat habis.
static func alfa(e: Entri) -> float:
	if Config.UMPAN_MELAYANG_DETIK <= 0.0:
		return 0.0
	return clampf(e.sisa_detik / Config.UMPAN_MELAYANG_DETIK, 0.0, 1.0)
