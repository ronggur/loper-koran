class_name PemuatHeadline
extends RefCounted
## Pemuat data headline: membaca `assets/data/headlines/{utama,ringan,lanjutan}.json` lalu memvalidasinya lewat `DataHeadline.parse`
## (DATA_SCHEMA 2; AC-2 run fase4a-koran-hari). SATU-SATUNYA tempat yang membaca berkas headline. `periksa_silang` memeriksa aturan antar berkas
## dan terhadap data misi: id unik di seluruh headline DAN misi, `syarat.flag` harus ditulis sedikitnya satu misi (`flag_lanjut`) supaya rujukan
## flag tidak yatim, dan rujukan `misi` headline lanjutan menunjuk misi yang ada. Pola sama dengan `PemuatRute`. Usulan, belum dikunci.

## Folder data headline di resource project (ikut paket game).
const FOLDER: String = "res://assets/data/headlines"
## Ekstensi berkas headline.
const EKSTENSI: String = "json"


## Semua headline sah, dikelompokkan menurut jenis berkas, beserta galat memuat.
class Pustaka extends RefCounted:
	var utama: Array[DataHeadline] = []
	var ringan: Array[DataHeadline] = []
	var lanjutan: Array[DataHeadline] = []
	var galat: Array[String] = []

	## True bila tidak ada galat.
	func sah() -> bool:
		return galat.is_empty()

	## Semua headline (utama, ringan, lanjutan).
	func semua() -> Array[DataHeadline]:
		var hasil: Array[DataHeadline] = []
		hasil.append_array(utama)
		hasil.append_array(ringan)
		hasil.append_array(lanjutan)
		return hasil

	## Daftar untuk jenis `jenis` ("utama", "ringan", "lanjutan").
	func daftar(jenis: String) -> Array[DataHeadline]:
		match jenis:
			"utama":
				return utama
			"ringan":
				return ringan
			_:
				return lanjutan


## Isi satu berkas sebagai teks (galat dikembalikan di `galat`, teks kosong bila gagal). Satu-satunya fungsi yang menyentuh berkas.
static func baca_teks(jalur: String, galat: Array[String]) -> String:
	if not FileAccess.file_exists(jalur):
		galat.append("%s: berkas tidak ada" % jalur)
		return ""
	var teks: String = FileAccess.get_file_as_string(jalur)
	if teks.is_empty():
		galat.append("%s: berkas kosong atau tidak terbaca" % jalur)
	return teks


## Parse satu berkas headline berjenis `jenis` (array) dari teks JSON (murni). Headline yang tidak sah tidak masuk.
static func parse_teks(teks: String, jenis: String, sumber: String, penerjemah: Callable = Callable()) -> Pustaka:
	var hasil: Pustaka = Pustaka.new()
	var penghurai: JSON = JSON.new()
	if penghurai.parse(teks) != OK:
		hasil.galat.append("%s: JSON rusak di baris %d: %s" % [sumber, penghurai.get_error_line(), penghurai.get_error_message()])
		return hasil
	if typeof(penghurai.data) != TYPE_ARRAY:
		hasil.galat.append("%s: isi berkas harus array headline" % sumber)
		return hasil
	var daftar: Array = penghurai.data
	var tujuan: Array[DataHeadline] = hasil.daftar(jenis)
	for butir: Variant in daftar:
		if typeof(butir) != TYPE_DICTIONARY:
			hasil.galat.append("%s: tiap headline harus objek" % sumber)
			continue
		var data: Dictionary = butir
		var satu: DataHeadline.Hasil = DataHeadline.parse(data, jenis, penerjemah)
		for g: String in satu.galat:
			hasil.galat.append("%s: %s" % [sumber, g])
		if satu.headline != null:
			tujuan.append(satu.headline)
	return hasil


## Aturan antar berkas dan terhadap data misi (murni): id unik di seluruh headline dan misi; tiap `syarat.flag` (headline dan misi) ditulis
## sedikitnya satu misi lewat `flag_lanjut`; `misi` headline lanjutan menunjuk misi yang ada.
static func periksa_silang(pustaka: Pustaka, misi: Array[DataMisi]) -> Array[String]:
	var galat: Array[String] = []
	var id_terlihat: Dictionary = {}
	for m: DataMisi in misi:
		if id_terlihat.has(m.id):
			galat.append("id '%s' ganda (misi)" % m.id)
		id_terlihat[m.id] = "misi"
	for h: DataHeadline in pustaka.semua():
		if id_terlihat.has(h.id):
			galat.append("id '%s' ganda (headline %s dan %s)" % [h.id, h.jenis, id_terlihat[h.id]])
		id_terlihat[h.id] = "headline " + h.jenis
	var flag_ditulis: Dictionary = {}
	for m: DataMisi in misi:
		flag_ditulis[m.flag_selesai] = true
		flag_ditulis[m.flag_gagal] = true
	for h: DataHeadline in pustaka.semua():
		if h.syarat.has("flag") and not flag_ditulis.has(h.syarat["flag"]):
			galat.append("headline '%s': syarat.flag '%s' tidak ditulis misi mana pun (flag_lanjut)" % [h.id, h.syarat["flag"]])
		if not h.misi.is_empty() and not _ada_misi(misi, h.misi):
			galat.append("headline '%s': misi '%s' tidak ada di data misi" % [h.id, h.misi])
	for m: DataMisi in misi:
		if m.syarat.has("flag") and not flag_ditulis.has(m.syarat["flag"]):
			galat.append("misi '%s': syarat.flag '%s' tidak ditulis misi mana pun (flag_lanjut)" % [m.id, m.syarat["flag"]])
	return galat


## Muat tiga berkas headline di `folder` (`utama.json`, `ringan.json`, `lanjutan.json`); galat memuat dikumpulkan di `Pustaka.galat`.
## Aturan terhadap data misi dipanggil terpisah lewat `periksa_silang` (pemanggil sudah memegang data misi).
static func muat_folder(folder: String = FOLDER, penerjemah: Callable = Callable()) -> Pustaka:
	var hasil: Pustaka = Pustaka.new()
	for jenis: String in DataHeadline.JENIS:
		var nama: String = "%s.%s" % [jenis, EKSTENSI]
		var teks: String = baca_teks(folder.path_join(nama), hasil.galat)
		if teks.is_empty():
			continue
		var satu: Pustaka = parse_teks(teks, jenis, nama, penerjemah)
		hasil.galat.append_array(satu.galat)
		hasil.daftar(jenis).append_array(satu.daftar(jenis))
	return hasil


static func _ada_misi(misi: Array[DataMisi], id: String) -> bool:
	for m: DataMisi in misi:
		if m.id == id:
			return true
	return false
