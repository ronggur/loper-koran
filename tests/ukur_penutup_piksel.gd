class_name UkurPenutupPiksel
extends RefCounted
## Pengukur piksel dekor lawan pemain dan rintangan, pembantu tes (run fase5b-tembok-dekor iterasi 2, QA-001, P-6; pola `UkurDekor`).
##
## Bukti bahwa pemain tidak pernah hilang di balik piksel opak dekor dan rintangan di jalur selalu terlihat, dihitung dari PNG nyata dan matematika proyeksi isometrik 2:1 yang ditulis
## sendiri di sini (bukan `Iso`): titik tanah (lateral, maju) jatuh di layar (x, y) = ((lateral + maju) * 32, (lateral - maju) * 16) piksel game, satu ubin tinggi = 32 piksel, dibulatkan ke piksel.
## Piksel yang dihitung hanya yang OPAK (alfa penuh); bayangan tanah beralfa sebagian tidak. Urutan gambar = Y-sort: sprite dengan y layar lebih besar digambar sesudah (di atas); y SAMA
## dihitung sebagai di atas (kasus terburuk). Pemain = gabungan semua frame sheet berkendara (`SHEET_PEMAIN`: kayuh, melambat, meluncur, rem, lempar; sel 46 x 58, pijak dari JSON), jadi
## pose mana pun yang sedang tampil tercakup. Pose jatuh (sheet 114 x 68) TIDAK dihitung: lihat catatan di LOG iterasi 2.
## "Tertutup" = satu-satunya fungsi produksi yang diuji di sini, `PenutupPemain.menutupi` atas `PenutupPemain.dari_dekor` (kotak penutup); selebihnya hitungan sendiri.

const ALFA_OPAK: float = 0.99
const FOLDER_PEMAIN: String = "res://assets/sprites/loper"
const FOLDER_PROPS: String = "res://assets/sprites/props"
const FOLDER_RINTANGAN: String = "res://assets/sprites/obstacles"
## Sheet berkendara pemain (tanpa jatuh).
const SHEET_PEMAIN: Array[String] = ["loper_agen", "loper_agen_melambat", "loper_agen_meluncur", "loper_agen_rem", "loper_agen_lempar"]
## Kanvas gabungan frame: sisi dan pijaknya (cukup untuk semua sel).
const KANVAS: int = 400
const KANVAS_PIJAK: int = 200
## Satu ubin dalam piksel proyeksi: lebar x 32, tinggi y 16 per ubin lateral/maju.
const PX_X: float = 32.0
const PX_Y: float = 16.0

static var _cache: Dictionary = {}


## Topeng piksel opak dalam kanvas dengan titik pijak, untuk menghitung tumpang tindih.
class Topeng extends RefCounted:
	var lebar: int = 0
	var tinggi: int = 0
	## 1 = opak, indeks y * lebar + x.
	var data: PackedByteArray = PackedByteArray()
	var pijak: Vector2i = Vector2i.ZERO
	## Koordinat piksel opak relatif pijak, berpasangan (dx, dy).
	var titik: PackedInt32Array = PackedInt32Array()
	## Kotak pembatas piksel opak relatif pijak.
	var batas: Rect2i = Rect2i()

	func opak(dx: int, dy: int) -> bool:
		var x: int = dx + pijak.x
		var y: int = dy + pijak.y
		if x < 0 or y < 0 or x >= lebar or y >= tinggi:
			return false
		return data[y * lebar + x] == 1

	func selesai() -> void:
		titik = PackedInt32Array()
		var min_x: int = lebar
		var min_y: int = tinggi
		var maks_x: int = -1
		var maks_y: int = -1
		for y: int in range(tinggi):
			for x: int in range(lebar):
				if data[y * lebar + x] == 1:
					titik.append(x - pijak.x)
					titik.append(y - pijak.y)
					min_x = mini(min_x, x)
					min_y = mini(min_y, y)
					maks_x = maxi(maks_x, x)
					maks_y = maxi(maks_y, y)
		if maks_x >= 0:
			batas = Rect2i(min_x - pijak.x, min_y - pijak.y, maks_x - min_x + 1, maks_y - min_y + 1)


## Titik layar (piksel game, dibulatkan) titik tanah (lateral, maju) ubin.
static func layar(lateral: float, maju: float) -> Vector2i:
	return Vector2i(roundi((lateral + maju) * PX_X), roundi((lateral - maju) * PX_Y))


## y layar tidak dibulatkan (urutan gambar).
static func y_urut(lateral: float, maju: float) -> float:
	return (lateral - maju) * PX_Y


static func _json(jalur: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(jalur)) as Dictionary


static func _gambar(jalur: String) -> Image:
	return (load(jalur) as Texture2D).get_image()


## Topeng satu PNG (satu frame) dengan pijak dari JSON `ground_anchor` di sampingnya.
static func topeng_prop(nama: String) -> Topeng:
	var kunci: String = "prop:" + nama
	if _cache.has(kunci):
		return _cache[kunci]
	var json: Dictionary = _json("%s/%s.json" % [FOLDER_PROPS, nama])
	var jangkar: Array = json["ground_anchor"]
	var gambar: Image = _gambar("%s/%s.png" % [FOLDER_PROPS, nama])
	var t: Topeng = Topeng.new()
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


## Gabungan semua frame sheet `jalur_png` (sel `cell` dari JSON, kolom berjajar) di kanvas bersama dengan pijak `ground_anchor`; `cermin_juga` menambah frame yang dicerminkan mendatar.
static func topeng_sheet(jalur_png: String, jalur_json: String, cermin_juga: bool) -> Topeng:
	var kunci: String = "sheet:%s:%s" % [jalur_png, cermin_juga]
	if _cache.has(kunci):
		return _cache[kunci]
	var json: Dictionary = _json(jalur_json)
	var sel: Array = json["cell"]
	var jangkar: Array = json["ground_anchor"]
	var lebar_sel: int = int(sel[0])
	var tinggi_sel: int = int(sel[1])
	var ax: int = int(jangkar[0])
	var ay: int = int(jangkar[1])
	var gambar: Image = _gambar(jalur_png)
	var t: Topeng = Topeng.new()
	t.lebar = KANVAS
	t.tinggi = KANVAS
	t.pijak = Vector2i(KANVAS_PIJAK, KANVAS_PIJAK)
	t.data.resize(KANVAS * KANVAS)
	var kolom: int = gambar.get_width() / lebar_sel
	var baris: int = gambar.get_height() / tinggi_sel
	for r: int in range(baris):
		for c: int in range(kolom):
			for y: int in range(tinggi_sel):
				for x: int in range(lebar_sel):
					if gambar.get_pixel(c * lebar_sel + x, r * tinggi_sel + y).a < ALFA_OPAK:
						continue
					t.data[(KANVAS_PIJAK - ay + y) * KANVAS + KANVAS_PIJAK - ax + x] = 1
					if cermin_juga:
						# Cermin mendatar dalam kotak sel yang sama (flip_h Godot membalik tekstur di tempat, pijak tidak ikut bergeser).
						t.data[(KANVAS_PIJAK - ay + y) * KANVAS + KANVAS_PIJAK - ax + (lebar_sel - 1 - x)] = 1
	t.selesai()
	_cache[kunci] = t
	return t


## Gabungan semua pose berkendara pemain.
static func topeng_pemain() -> Topeng:
	if _cache.has("pemain"):
		return _cache["pemain"]
	var gabung: Topeng = Topeng.new()
	gabung.lebar = KANVAS
	gabung.tinggi = KANVAS
	gabung.pijak = Vector2i(KANVAS_PIJAK, KANVAS_PIJAK)
	gabung.data.resize(KANVAS * KANVAS)
	for nama: String in SHEET_PEMAIN:
		var t: Topeng = topeng_sheet("%s/%s.png" % [FOLDER_PEMAIN, nama], "%s/%s.json" % [FOLDER_PEMAIN, nama], false)
		for i: int in range(t.data.size()):
			if t.data[i] == 1:
				gabung.data[i] = 1
	gabung.selesai()
	_cache["pemain"] = gabung
	return gabung


static func topeng_anjing() -> Topeng:
	return topeng_sheet(FOLDER_RINTANGAN + "/obs_anjing_sheet.png", FOLDER_RINTANGAN + "/obs_anjing_sheet.json", true)


static func topeng_mobil() -> Topeng:
	return topeng_sheet(FOLDER_RINTANGAN + "/obs_mobil_garasi_sheet.png", FOLDER_RINTANGAN + "/obs_mobil_garasi_sheet.json", false)


## Banyaknya piksel opak `atas` (digambar di titik layar `pos_atas`) yang berimpit dengan piksel opak `bawah` (di `pos_bawah`); berhenti di `batas_hitung` (0 = hitung semua).
static func hitung_tumpang(atas: Topeng, pos_atas: Vector2i, bawah: Topeng, pos_bawah: Vector2i, batas_hitung: int = 0) -> int:
	var a: Rect2i = Rect2i(atas.batas.position + pos_atas, atas.batas.size)
	var b: Rect2i = Rect2i(bawah.batas.position + pos_bawah, bawah.batas.size)
	if not a.intersects(b):
		return 0
	var irisan: Rect2i = a.intersection(b)
	var jumlah: int = 0
	var titik: PackedInt32Array = bawah.titik
	var n: int = titik.size()
	var i: int = 0
	while i < n:
		var wx: int = titik[i] + pos_bawah.x
		var wy: int = titik[i + 1] + pos_bawah.y
		i += 2
		if wx < irisan.position.x or wy < irisan.position.y or wx >= irisan.end.x or wy >= irisan.end.y:
			continue
		if atas.opak(wx - pos_atas.x, wy - pos_atas.y):
			jumlah += 1
			if batas_hitung > 0 and jumlah >= batas_hitung:
				return jumlah
	return jumlah


## Dekor buatan di maju `maju_ubin` untuk jenis, varian, sisi tertentu (lateral dan id seperti `RouteBuilder`).
static func dekor_buatan(jenis: String, varian: String, sisi: LoperAnim.Sisi, maju_ubin: float) -> RouteBuilder.DekorItem:
	var d: RouteBuilder.DekorItem = RouteBuilder.DekorItem.new()
	d.jenis = jenis
	d.varian = varian
	d.sisi = sisi
	d.pos = int(maju_ubin)
	d.maju_ubin = maju_ubin
	d.lateral_ubin = DekorRute.lateral(jenis, sisi)
	d.id = "ukur:%s@%d" % [jenis, d.pos]
	return d


## Nama berkas sprite dekor (tanpa ekstensi), ditulis ulang di sini (bukan `DekorRute.nama_sprite`): tong logam; pohon per varian; lampu `lengan` per sisi.
static func nama_prop(d: RouteBuilder.DekorItem) -> String:
	if d.jenis == "tong_sampah":
		return "prop_tong_sampah_logam"
	if d.jenis == "pohon":
		return "prop_pohon_" + d.varian
	return "prop_lampu_lengan_" + ("seberang" if d.sisi == LoperAnim.Sisi.SEBERANG else "dekat")


## Lateral pusat dekor, ditulis ulang di sini (bukan `DekorRute.lateral`): sisi dekat pohon dan tong 2,5, lampu 2,25; sisi seberang tong 2,5, pohon 2,75, lampu 2,625 (negatif).
static func lateral_dekor(d: RouteBuilder.DekorItem) -> float:
	if d.sisi == LoperAnim.Sisi.SEBERANG:
		var besar_seberang: float = 2.5
		if d.jenis == "pohon":
			besar_seberang = 2.75
		elif d.jenis == "lampu_jalan":
			besar_seberang = 2.625
		return -besar_seberang
	return 2.25 if d.jenis == "lampu_jalan" else 2.5


## Sapu pemain di sekitar dekor `d`: lateral -2,0 sampai 2,0 (langkah `langkah_lateral`) dan maju dari `d.maju_ubin - jangkau` sampai `+ jangkau` (langkah `langkah_maju`). Hasil:
## `tumpang` (jumlah posisi dengan piksel opak dekor di atas piksel pemain pada alfa 1,0), `posisi_tumpang` (daftar Vector3 lateral, maju, piksel untuk semuanya), `tak_tertutup` (daftar Vector3 lateral, maju, piksel untuk posisi tumpang yang kotak penutupnya TIDAK
## menutupi), `tertutup_tumpang` (posisi tumpang yang tertutup), `tertutup_total`, `diperiksa`, `piksel_maks` (terbesar di antara tak_tertutup).
## `kotak`: kotak penutup yang diuji; null = `PenutupPemain.dari_dekor(d)`. `lateral_pakai`: lateral pusat dekor yang dipakai; 0 = `lateral_dekor(d)` (kontrol lateral lama).
static func sapu_pemain(d: RouteBuilder.DekorItem, langkah_lateral: float, langkah_maju: float, jangkau: float, kotak: PenutupPemain.Objek = null, lateral_pakai: float = 0.0) -> Dictionary:
	var objek: PenutupPemain.Objek = kotak if kotak != null else PenutupPemain.dari_dekor(d)
	var topeng_dekor: Topeng = topeng_prop(nama_prop(d))
	var pemain: Topeng = topeng_pemain()
	var ld: float = lateral_dekor(d) if lateral_pakai == 0.0 else lateral_pakai
	var pos_dekor: Vector2i = layar(ld, d.maju_ubin)
	var y_dekor: float = y_urut(ld, d.maju_ubin)
	var hasil: Dictionary = {"tumpang": 0, "tak_tertutup": [], "posisi_tumpang": [], "tertutup_tumpang": 0, "tertutup_total": 0, "diperiksa": 0, "piksel_maks": 0}
	var n_lateral: int = roundi(2.0 / langkah_lateral)
	var n_maju: int = roundi(jangkau / langkah_maju)
	for i: int in range(-n_lateral, n_lateral + 1):
		var lateral: float = float(i) * langkah_lateral
		for k: int in range(-n_maju, n_maju + 1):
			var maju: float = d.maju_ubin + float(k) * langkah_maju
			hasil["diperiksa"] = int(hasil["diperiksa"]) + 1
			var tutup: bool = PenutupPemain.menutupi(Vector2(lateral, -maju), objek)
			if tutup:
				hasil["tertutup_total"] = int(hasil["tertutup_total"]) + 1
			if y_dekor < y_urut(lateral, maju):
				continue
			var piksel: int = hitung_tumpang(topeng_dekor, pos_dekor, pemain, layar(lateral, maju))
			if piksel <= 0:
				continue
			hasil["tumpang"] = int(hasil["tumpang"]) + 1
			(hasil["posisi_tumpang"] as Array).append(Vector3(lateral, maju, float(piksel)))
			if tutup:
				hasil["tertutup_tumpang"] = int(hasil["tertutup_tumpang"]) + 1
			else:
				(hasil["tak_tertutup"] as Array).append(Vector3(lateral, maju, float(piksel)))
				hasil["piksel_maks"] = maxi(int(hasil["piksel_maks"]), piksel)
	return hasil


## Posisi pusat rintangan yang bisa dicapai (koordinat jalan, ubin) untuk objek `jenis` (`anjing_penjaga` atau `mobil_garasi`) di titik rumah `pos` jalur `jalur` (`seberang` atau `dekat`):
## - anjing: dari halaman (lateral +-`ANJING_RUMAH_LATERAL_UBIN`) sampai setengah jalannya (pusat paling dekat garis tengah = `ANJING_SETENGAH_UBIN`), maju dari `pos` sampai `pos + ANJING_BATAS_MAJU_UBIN`;
## - mobil: pusat bentuk dari parkir (`MOBIL_BELAKANG_AWAL_UBIN`) sampai berhenti (`MOBIL_BELAKANG_AKHIR_UBIN`), maju tetap di `pos`.
static func posisi_rintangan(jenis: String, pos: float, jalur: String, langkah: float) -> Array[Vector2]:
	var hasil: Array[Vector2] = []
	var sisi: LoperAnim.Sisi = LoperAnim.Sisi.SEBERANG if jalur == "seberang" else LoperAnim.Sisi.DEKAT
	if jenis == "anjing_penjaga":
		var arah: float = -1.0 if sisi == LoperAnim.Sisi.SEBERANG else 1.0
		var n_lateral: int = roundi((Config.ANJING_RUMAH_LATERAL_UBIN - Config.ANJING_SETENGAH_UBIN) / langkah)
		var n_maju: int = roundi(Config.ANJING_BATAS_MAJU_UBIN / langkah)
		for i: int in range(n_lateral + 1):
			for k: int in range(n_maju + 1):
				hasil.append(Vector2(arah * (Config.ANJING_RUMAH_LATERAL_UBIN - float(i) * langkah), pos + float(k) * langkah))
	elif jenis == "mobil_garasi":
		var n: int = roundi((Config.MOBIL_BELAKANG_AWAL_UBIN - Config.MOBIL_BELAKANG_AKHIR_UBIN) / langkah)
		for i: int in range(n + 1):
			var k: MobilGarasi.Keadaan = MobilGarasi.baru(pos, sisi, 0.0)
			k.belakang_ubin = Config.MOBIL_BELAKANG_AWAL_UBIN - float(i) * langkah
			hasil.append(MobilGarasi.kotak(k).get_center())
	return hasil


## Sapu rintangan `jenis` di `pos` jalur `jalur` melawan dekor `d`: banyaknya posisi rintangan yang pikselnya tertimpa piksel opak dekor (dekor digambar di atasnya menurut Y-sort), piksel terbanyak
## dan posisinya. Kunci: `tumpang`, `piksel_maks`, `posisi_terburuk`, `diperiksa`.
static func sapu_rintangan(d: RouteBuilder.DekorItem, jenis: String, pos: float, jalur: String, langkah: float) -> Dictionary:
	var topeng_dekor: Topeng = topeng_prop(nama_prop(d))
	var topeng_rintangan: Topeng = topeng_anjing() if jenis == "anjing_penjaga" else topeng_mobil()
	var ld: float = lateral_dekor(d)
	var pos_dekor: Vector2i = layar(ld, d.maju_ubin)
	var y_dekor: float = y_urut(ld, d.maju_ubin)
	var hasil: Dictionary = {"tumpang": 0, "piksel_maks": 0, "posisi_terburuk": Vector2.ZERO, "diperiksa": 0}
	for p: Vector2 in posisi_rintangan(jenis, pos, jalur, langkah):
		hasil["diperiksa"] = int(hasil["diperiksa"]) + 1
		if y_dekor < y_urut(p.x, p.y):
			continue
		var piksel: int = hitung_tumpang(topeng_dekor, pos_dekor, topeng_rintangan, layar(p.x, p.y))
		if piksel > 0:
			hasil["tumpang"] = int(hasil["tumpang"]) + 1
			if piksel > int(hasil["piksel_maks"]):
				hasil["piksel_maks"] = piksel
				hasil["posisi_terburuk"] = p
	return hasil
