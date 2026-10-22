class_name UkurSisiDekat
extends RefCounted
## Oracle piksel sisi dekat run fase5d-sisi-dekat bagian A (AC-6; pola `UkurTembok` dan `UkurPenutupPiksel`): seberapa banyak piksel sasaran sisi dekat dan pemain tertimpa piksel
## OPAK sprite rumah dekat baru (PNG nyata di `assets/sprites/houses/perumahan/`, titik pijak dari JSON `ground_anchor`).
##
## Independen dari kode produksi: proyeksi iso 2:1 ditulis ulang di sini (titik tanah (lateral, maju) -> layar ((lateral + maju) x 32, (lateral - maju) x 16), dibulatkan), letak
## rumah dekat ditulis literal (pusat tapak logika lateral 4,5 + mundur 0,5 = 5,0; maju kavling + 1,0), kotak surat dekat = cermin seberang (lateral +2,125, maju kavling + 1,75; offset sprite
## dari JSON), zona di tanah dirasterisasi sendiri (pusat piksel diproyeksikan balik ke tanah). Urutan gambar = Y-sort: sprite dengan y layar pijak lebih besar digambar sesudah; y SAMA dihitung
## di atas (kasus terburuk). Zona di tanah digambar di bawah semua objek, jadi semua sprite rumah dihitung untuk zona. Pemain = gabungan semua frame berkendara (`UkurPenutupPiksel.topeng_pemain`).
## Satu-satunya fungsi produksi yang dipanggil: `PenutupPemain.menutupi` atas kotak `PenutupPemain.dari_rumah_gambar` (untuk membuktikan kotak penutup = sprite nyata).

const ALFA_OPAK: float = 0.99
const FOLDER_RUMAH: String = "res://assets/sprites/houses/perumahan"
const FOLDER_PROPS: String = "res://assets/sprites/props"
const JENIS: Array[String] = ["limasan", "pelana_lintang", "pelana_sejajar"]
## Letak gambar rumah dekat relatif awal kavling (ditulis literal: tapak logika 3..6 -> pusat 4,5, + mundur 0,5).
const RUMAH_LATERAL: float = 5.0
const RUMAH_MAJU_RELATIF: float = 1.0
## Kotak surat dekat cermin seberang (seberang -2,125; 1,75).
const KOTAK_LATERAL: float = 2.125
const KOTAK_MAJU_RELATIF: float = 1.75
## Zona kotak surat dekat: cermin seberang [-2,75; 1,25; 1,0; 1,25] -> [1,75; 1,25; 1,0; 1,25]; zona dekat lama jalan uji [1,75; 1,25; 0,75; 1,25].
const ZONA_KOTAK_CERMIN: Rect2 = Rect2(1.75, 1.25, 1.0, 1.25)
const ZONA_KOTAK_LAMA: Rect2 = Rect2(1.75, 1.25, 0.75, 1.25)
## Halaman dekat (rumput antara trotoar dan tapak logika): lateral 2..3, maju kavling -0,5 .. +2,5.
const HALAMAN: Rect2 = Rect2(2.0, -0.5, 1.0, 3.0)
## Jarak kavling dua rumah dekat bertetangga paling dekat (`RUTE_PETAK_UBIN`, ditulis literal).
const PETAK: float = 4.0

static var _cache: Dictionary = {}


## Nama sprite rumah dekat (ditulis ulang, bukan `SpriteRumah.nama`).
static func nama_rumah(jenis: String, pelanggan: bool) -> String:
	return "house_perumahan_dekat_%s_%s" % [jenis, "pelanggan" if pelanggan else "bukan"]


## Enam sprite rumah dekat: [jenis, pelanggan].
static func semua_rumah() -> Array:
	var hasil: Array = []
	for j: String in JENIS:
		for p: bool in [true, false]:
			hasil.append([j, p])
	return hasil


static func layar(lateral: float, maju: float) -> Vector2i:
	return Vector2i(roundi((lateral + maju) * 32.0), roundi((lateral - maju) * 16.0))


static func y_urut(lateral: float, maju: float) -> float:
	return (lateral - maju) * 16.0


## Topeng opak PNG dengan pijak dari JSON di sampingnya.
static func topeng(folder: String, nama: String) -> UkurPenutupPiksel.Topeng:
	var kunci: String = folder + "/" + nama
	if _cache.has(kunci):
		return _cache[kunci]
	var json: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("%s/%s.json" % [folder, nama])) as Dictionary
	var jangkar: Array = json["ground_anchor"]
	var gambar: Image = (load("%s/%s.png" % [folder, nama]) as Texture2D).get_image()
	var t: UkurPenutupPiksel.Topeng = UkurPenutupPiksel.Topeng.new()
	t.lebar = gambar.get_width()
	t.tinggi = gambar.get_height()
	t.pijak = Vector2i(int(jangkar[0]), int(jangkar[1]))
	t.data.resize(t.lebar * t.tinggi)
	for y: int in range(t.tinggi):
		for x: int in range(t.lebar):
			t.data[y * t.lebar + x] = 1 if gambar.get_pixel(x, y).a >= ALFA_OPAK else 0
	t.selesai()
	_cache[kunci] = t
	return t


## JSON aset rumah dekat (untuk teras_ubin).
static func json_rumah(jenis: String, pelanggan: bool) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("%s/%s.json" % [FOLDER_RUMAH, nama_rumah(jenis, pelanggan)])) as Dictionary


## Satu sprite rumah dekat di kavling `maju_awal`: [topeng, titik layar pijak, y_urut].
## `lateral` = lateral pijak gambar (bawaan `RUMAH_LATERAL`; kontrol tes memakai nilai lain).
static func sprite_rumah(jenis: String, pelanggan: bool, maju_awal: float, lateral: float = RUMAH_LATERAL) -> Array:
	var maju: float = maju_awal + RUMAH_MAJU_RELATIF
	return [topeng(FOLDER_RUMAH, nama_rumah(jenis, pelanggan)), layar(lateral, maju), y_urut(lateral, maju)]


## Piksel layar yang pusatnya jatuh di persegi tanah `persegi` (lateral, maju; maju sudah mutlak).
static func piksel_tanah(persegi: Rect2) -> Array[Vector2i]:
	var hasil: Array[Vector2i] = []
	var sudut: Array[Vector2i] = [layar(persegi.position.x, persegi.position.y), layar(persegi.end.x, persegi.position.y), layar(persegi.position.x, persegi.end.y), layar(persegi.end.x, persegi.end.y)]
	var lo: Vector2i = sudut[0]
	var hi: Vector2i = sudut[0]
	for s: Vector2i in sudut:
		lo = Vector2i(mini(lo.x, s.x), mini(lo.y, s.y))
		hi = Vector2i(maxi(hi.x, s.x), maxi(hi.y, s.y))
	for y: int in range(lo.y - 1, hi.y + 2):
		for x: int in range(lo.x - 1, hi.x + 2):
			var sx: float = float(x) + 0.5
			var sy: float = float(y) + 0.5
			var l: float = sx / 64.0 + sy / 32.0
			var m: float = sx / 64.0 - sy / 32.0
			if l >= persegi.position.x and l < persegi.end.x and m >= persegi.position.y and m < persegi.end.y:
				hasil.append(Vector2i(x, y))
	return hasil


## Piksel opak sprite kotak surat dekat (oranye bila pelanggan, abu-abu bila bukan) di kavling `maju_awal`, dan y_urut-nya.
static func piksel_kotak(pelanggan: bool, maju_awal: float) -> Array:
	var t: UkurPenutupPiksel.Topeng = topeng(FOLDER_PROPS, "prop_kotak_surat" if pelanggan else "prop_kotak_surat_bukan")
	var titik: Vector2i = layar(KOTAK_LATERAL, maju_awal + KOTAK_MAJU_RELATIF)
	var hasil: Array[Vector2i] = []
	var i: int = 0
	while i < t.titik.size():
		hasil.append(titik + Vector2i(t.titik[i], t.titik[i + 1]))
		i += 2
	return [hasil, y_urut(KOTAK_LATERAL, maju_awal + KOTAK_MAJU_RELATIF)]


## Pecahan `titik` yang tertimpa piksel opak salah satu `sprite` ([topeng, pijak layar, y_urut]) yang digambar di atas `y_acuan` (y_urut >= y_acuan; -INF = semua).
static func pecahan(titik: Array[Vector2i], sprite: Array, y_acuan: float) -> float:
	if titik.is_empty():
		return 0.0
	var kena: int = 0
	for t: Vector2i in titik:
		for s: Array in sprite:
			if (s[2] as float) < y_acuan:
				continue
			var tp: UkurPenutupPiksel.Topeng = s[0]
			var lokal: Vector2i = t - (s[1] as Vector2i)
			if tp.opak(lokal.x, lokal.y):
				kena += 1
				break
	return float(kena) / float(titik.size())


## Ukur satu rumah dekat (`jenis`, `pelanggan`) di kavling `maju_awal` dengan tetangga opsional `tetangga` = [[jenis, pelanggan, selisih kavling], ...].
## Kunci: `kotak_badan` (piksel sprite kotak surat dekat tertimpa), `zona_kotak` (cermin), `zona_kotak_lama`, `halaman`, `teras_tetangga` (lantai teras rumah ini tertimpa rumah lain), dan
## `jumlah_kotak`, `jumlah_zona` (kontrol ukuran). Nilai 0..1.
## `lateral_rumah` = lateral pijak gambar rumah ini (kontrol: 4,5 = tanpa mundur).
static func ukur_sasaran(jenis: String, pelanggan: bool, maju_awal: float, tetangga: Array = [], lateral_rumah: float = RUMAH_LATERAL) -> Dictionary:
	var sendiri: Array = sprite_rumah(jenis, pelanggan, maju_awal, lateral_rumah)
	var semua: Array = [sendiri]
	var lain: Array = []
	for t: Array in tetangga:
		var s: Array = sprite_rumah(t[0], t[1], maju_awal + float(t[2]))
		semua.append(s)
		lain.append(s)
	var kotak: Array = piksel_kotak(pelanggan, maju_awal)
	var zona: Array[Vector2i] = piksel_tanah(Rect2(ZONA_KOTAK_CERMIN.position + Vector2(0.0, maju_awal), ZONA_KOTAK_CERMIN.size))
	var zona_lama: Array[Vector2i] = piksel_tanah(Rect2(ZONA_KOTAK_LAMA.position + Vector2(0.0, maju_awal), ZONA_KOTAK_LAMA.size))
	var halaman: Array[Vector2i] = piksel_tanah(Rect2(HALAMAN.position + Vector2(0.0, maju_awal), HALAMAN.size))
	var teras_json: Array = json_rumah(jenis, pelanggan)["teras_ubin"]
	var teras: Array[Vector2i] = piksel_tanah(Rect2(RUMAH_LATERAL + float(teras_json[0]), maju_awal + RUMAH_MAJU_RELATIF + float(teras_json[1]), float(teras_json[2]), float(teras_json[3])))
	return {
		"kotak_badan": pecahan(kotak[0], semua, kotak[1]),
		"zona_kotak": pecahan(zona, semua, -INF),
		"zona_kotak_lama": pecahan(zona_lama, semua, -INF),
		"halaman": pecahan(halaman, semua, -INF),
		"teras_tetangga": pecahan(teras, lain, -INF),
		"jumlah_kotak": (kotak[0] as Array).size(),
		"jumlah_zona": zona.size(),
		"jumlah_teras": teras.size(),
	}


## Sapu pemain di sekitar rumah dekat (`jenis`, `pelanggan`) di kavling `maju_awal`: lateral `lateral_min`..`lateral_maks` langkah `langkah`, maju kavling -3 .. +5.
## Kunci: `pecahan_maks` (piksel pemain tertimpa / piksel pemain, terbesar), `piksel_maks`, `posisi_maks` (Vector2 lateral, maju), `tumpang` (posisi dengan piksel > 0),
## `tak_tertutup` (posisi tumpang yang kotak penutup produksi TIDAK tandai menutupi), `diperiksa`.
static func sapu_pemain(jenis: String, pelanggan: bool, maju_awal: float, lateral_min: float, lateral_maks: float, langkah: float) -> Dictionary:
	var s: Array = sprite_rumah(jenis, pelanggan, maju_awal)
	var rumah: UkurPenutupPiksel.Topeng = s[0]
	var pemain: UkurPenutupPiksel.Topeng = UkurPenutupPiksel.topeng_pemain()
	var jumlah_pemain: int = pemain.titik.size() / 2
	var buatan: RouteBuilder.RumahRute = RouteBuilder.RumahRute.new()
	buatan.id = "ukur@%s" % [str(maju_awal)]
	buatan.maju_ubin = maju_awal
	buatan.sisi = LoperAnim.Sisi.DEKAT
	buatan.jenis = "dekat_" + jenis
	buatan.pelanggan = pelanggan
	var kotak: PenutupPemain.Objek = PenutupPemain.dari_rumah_gambar(buatan)
	var hasil: Dictionary = {"pecahan_maks": 0.0, "piksel_maks": 0, "posisi_maks": Vector2.ZERO, "tumpang": 0, "tak_tertutup": [], "diperiksa": 0}
	var n_lat: int = roundi((lateral_maks - lateral_min) / langkah)
	var n_maju: int = roundi(8.0 / langkah)
	for i: int in range(n_lat + 1):
		var lateral: float = lateral_min + float(i) * langkah
		for k: int in range(n_maju + 1):
			var maju: float = maju_awal - 3.0 + float(k) * langkah
			hasil["diperiksa"] = int(hasil["diperiksa"]) + 1
			if (s[2] as float) < y_urut(lateral, maju):
				continue
			var piksel: int = UkurPenutupPiksel.hitung_tumpang(rumah, s[1], pemain, layar(lateral, maju))
			if piksel <= 0:
				continue
			hasil["tumpang"] = int(hasil["tumpang"]) + 1
			if not PenutupPemain.menutupi(Vector2(lateral, -maju), kotak):
				(hasil["tak_tertutup"] as Array).append(Vector3(lateral, maju, float(piksel)))
			var p: float = float(piksel) / float(jumlah_pemain)
			if p > float(hasil["pecahan_maks"]):
				hasil["pecahan_maks"] = p
				hasil["piksel_maks"] = piksel
				hasil["posisi_maks"] = Vector2(lateral, maju)
	return hasil
