class_name DataToko
extends RefCounted
## Satu upgrade bengkel sebagai data bertipe beserta validasinya (DATA_SCHEMA 6, GDD 12.4; run fase6a1-bengkel-kondisi, AC-17 dan AC-18, M-10; usulan). Logika murni: `parse`
## menerima `Dictionary` (hasil JSON), mengembalikan upgrade dan daftar galat, dan MENOLAK data tidak sah (upgrade null bila ada galat). Membaca berkas ada di `PemuatToko`.
## Teks pemain (`nama`, `deskripsi`) adalah KUNCI terjemahan (rule `content-data`), batas panjangnya diperiksa terhadap teks terjemahan.
## Efek = daftar {jenis, nilai} dari daftar tertutup `Config.TOKO_EFEK_JENIS` dengan nilai dalam rentang aman `TOKO_EFEK_MIN`/`TOKO_EFEK_MAKS` (tidak ada jenis yang menaikkan
## kecepatan puncak, tanpa power creep) dan komponen yang sesuai (`TOKO_EFEK_KOMPONEN`). Level N dimiliki bila level komponen >= N; efek tingkat-tingkat yang dimiliki dikalikan.
## Id upgrade tidak pernah diganti; tidak ada upgrade yang dihapus dari berkas, hanya ditambah.

const _FIELD: Array[String] = ["id", "komponen", "level", "harga", "nama", "deskripsi", "efek"]
const _FIELD_EFEK: Array[String] = ["jenis", "nilai"]
## Kunci hasil `pengali_efek` yang dibaca `BikeCondition.efek`.
const KUNCI_PENGALI_BUKAN_AUS: Array[String] = ["pengali_rem", "pengali_lateral", "pengali_kuras_stamina"]


## Satu efek upgrade yang sudah divalidasi.
class EfekUpgrade extends RefCounted:
	var jenis: String = ""
	var nilai: float = 1.0


## Hasil `parse`: upgrade (null bila ada galat) dan daftar galat.
class Hasil extends RefCounted:
	var upgrade: DataToko = null
	var galat: Array[String] = []

	func sah() -> bool:
		return galat.is_empty() and upgrade != null


var id: String = ""
var komponen: String = ""
var level: int = 1
var harga: int = 0
## Kunci terjemahan nama dan deskripsi.
var nama: String = ""
var deskripsi: String = ""
var efek: Array[EfekUpgrade] = []


## Parse dan validasi satu upgrade dari `data`; `penerjemah` (Callable kunci -> teks, tidak sah = TranslationServer) untuk memeriksa teks.
static func parse(data: Dictionary, penerjemah: Callable = Callable()) -> Hasil:
	var hasil: Hasil = Hasil.new()
	var g: Array[String] = hasil.galat
	ParseData.tolak_field_asing(data, _FIELD, "upgrade", g)
	var u: DataToko = DataToko.new()
	u.id = ParseData.teks_wajib(data, "id", "upgrade", g)
	if not u.id.is_empty() and not ParseData.nama_sah(u.id):
		g.append("upgrade: id '%s' harus huruf kecil, angka, dan garis bawah, dimulai huruf" % u.id)
	var label: String = "upgrade '%s'" % u.id
	u.komponen = ParseData.teks_wajib(data, "komponen", label, g)
	if not u.komponen.is_empty() and not Config.KONDISI_KOMPONEN.has(u.komponen):
		g.append("%s: komponen '%s' tidak dikenal (%s)" % [label, u.komponen, Config.KONDISI_KOMPONEN])
	u.level = ParseData.bulat_wajib(data, "level", label, g)
	if data.has("level") and ParseData.bulat(data["level"]) and u.level < 1:
		g.append("%s: level harus bilangan bulat >= 1" % label)
	u.harga = ParseData.bulat_wajib(data, "harga", label, g)
	if data.has("harga") and ParseData.bulat(data["harga"]) and u.harga < 1:
		g.append("%s: harga harus bilangan bulat >= 1 koin" % label)
	u.nama = ParseData.teks_wajib(data, "nama", label, g)
	AturanTeks.periksa_kunci(u.nama, Config.TOKO_NAMA_PANJANG_MAKS, "nama", label, penerjemah, g)
	u.deskripsi = ParseData.teks_wajib(data, "deskripsi", label, g)
	AturanTeks.periksa_kunci(u.deskripsi, Config.TOKO_DESKRIPSI_PANJANG_MAKS, "deskripsi", label, penerjemah, g)
	var daftar: Array = ParseData.daftar_wajib(data, "efek", label, g)
	if data.has("efek") and typeof(data["efek"]) == TYPE_ARRAY and daftar.is_empty():
		g.append("%s: efek tidak boleh kosong (upgrade tanpa efek tidak ada gunanya)" % label)
	for butir: Variant in daftar:
		if typeof(butir) != TYPE_DICTIONARY:
			g.append("%s: tiap efek harus objek {jenis, nilai}" % label)
			continue
		var e: EfekUpgrade = _parse_efek(butir, u.komponen, label, g)
		if e != null:
			u.efek.append(e)
	if g.is_empty():
		hasil.upgrade = u
	return hasil


## Satu efek: jenis dikenal, nilai berhingga dalam rentang aman, komponen sesuai jenisnya.
static func _parse_efek(data: Dictionary, komponen: String, label: String, g: Array[String]) -> EfekUpgrade:
	ParseData.tolak_field_asing(data, _FIELD_EFEK, label + " efek", g)
	var jenis: String = ParseData.teks_wajib(data, "jenis", label + " efek", g)
	if not data.has("nilai") or not ParseData.angka(data["nilai"]):
		g.append("%s: efek '%s' harus punya 'nilai' angka berhingga" % [label, jenis])
		return null
	var nilai: float = float(data["nilai"])
	var indeks: int = Config.TOKO_EFEK_JENIS.find(jenis)
	if indeks < 0:
		if not jenis.is_empty():
			g.append("%s: jenis efek '%s' tidak dikenal (%s)" % [label, jenis, Config.TOKO_EFEK_JENIS])
		return null
	if nilai < Config.TOKO_EFEK_MIN[indeks] or nilai > Config.TOKO_EFEK_MAKS[indeks]:
		g.append("%s: nilai efek '%s' = %s di luar rentang aman %s sampai %s" % [label, jenis, nilai, Config.TOKO_EFEK_MIN[indeks], Config.TOKO_EFEK_MAKS[indeks]])
		return null
	var syarat_komponen: String = Config.TOKO_EFEK_KOMPONEN[indeks]
	if not syarat_komponen.is_empty() and not komponen.is_empty() and komponen != syarat_komponen:
		g.append("%s: efek '%s' hanya untuk komponen '%s', bukan '%s'" % [label, jenis, syarat_komponen, komponen])
		return null
	var e: EfekUpgrade = EfekUpgrade.new()
	e.jenis = jenis
	e.nilai = nilai
	return e


## True bila upgrade ini dimiliki pada `level_komponen` (level komponen >= level upgrade).
func dimiliki(level_komponen: int) -> bool:
	return level_komponen >= level


## Pengali efek upgrade yang dimiliki, per jenis bukan-aus (`KUNCI_PENGALI_BUKAN_AUS`): jenis -> hasil kali nilai (1,0 bila tidak ada). `level` = komponen -> level di save.
static func pengali_efek(daftar: Array[DataToko], level_komponen: Dictionary) -> Dictionary:
	var hasil: Dictionary = {}
	for kunci: String in KUNCI_PENGALI_BUKAN_AUS:
		hasil[kunci] = 1.0
	for u: DataToko in daftar:
		if not u.dimiliki(int(level_komponen.get(u.komponen, 0))):
			continue
		for e: EfekUpgrade in u.efek:
			if hasil.has(e.jenis):
				hasil[e.jenis] = float(hasil[e.jenis]) * e.nilai
	return hasil


## Pengali aus per komponen dari upgrade yang dimiliki: komponen -> hasil kali nilai `pengali_aus` (1,0 bila tidak ada).
static func pengali_aus(daftar: Array[DataToko], level_komponen: Dictionary) -> Dictionary:
	var hasil: Dictionary = {}
	for k: String in Config.KONDISI_KOMPONEN:
		hasil[k] = 1.0
	for u: DataToko in daftar:
		if not u.dimiliki(int(level_komponen.get(u.komponen, 0))):
			continue
		for e: EfekUpgrade in u.efek:
			if e.jenis == "pengali_aus" and hasil.has(u.komponen):
				hasil[u.komponen] = float(hasil[u.komponen]) * e.nilai
	return hasil
