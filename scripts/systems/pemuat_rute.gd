class_name PemuatRute
extends RefCounted
## Pemuat segmen rute: membaca berkas JSON lalu memvalidasinya lewat `SegmenRute.parse` (DATA_SCHEMA 3, AC-2 run fase3a-rute).
## SATU-SATUNYA tempat yang membaca berkas segmen; UI, entitas, dan `RouteBuilder` hanya menerima `SegmenRute` (rule `gdscript`).
## Fungsi pembacaan (`baca_teks`, `daftar_berkas`) dipisah dari `parse_teks` dan `periksa_kumpulan`, yang murni, supaya data rusak bisa
## dites tanpa berkas. Usulan, belum dikunci.

## Folder segmen distrik perumahan di resource project (ikut paket game, `export_presets.cfg` tidak mengecualikannya).
const FOLDER_PERUMAHAN: String = "res://assets/data/routes/perumahan"
## Ekstensi berkas segmen.
const EKSTENSI: String = "json"
## Awalan nama berkas segmen perumahan (`per_*.json`, DATA_SCHEMA 3).
const AWALAN_PERUMAHAN: String = "per_"


## Hasil memuat banyak segmen: segmen yang sah (urut id) dan semua galat (termasuk antar segmen).
class Kumpulan extends RefCounted:
	var segmen: Array[SegmenRute] = []
	var galat: Array[String] = []

	## True bila tidak ada galat.
	func sah() -> bool:
		return galat.is_empty()


## Isi satu berkas sebagai teks (galat dikembalikan di `galat`, teks kosong bila gagal). Satu-satunya fungsi yang menyentuh berkas.
static func baca_teks(jalur: String, galat: Array[String]) -> String:
	if not FileAccess.file_exists(jalur):
		galat.append("%s: berkas tidak ada" % jalur)
		return ""
	var teks: String = FileAccess.get_file_as_string(jalur)
	if teks.is_empty():
		galat.append("%s: berkas kosong atau tidak terbaca" % jalur)
	return teks


## Nama berkas `per_*.json` di `folder`, diurutkan (urutan DirAccess tidak dijamin).
static func daftar_berkas(folder: String, awalan: String = AWALAN_PERUMAHAN) -> Array[String]:
	var hasil: Array[String] = []
	var dir: DirAccess = DirAccess.open(folder)
	if dir == null:
		return hasil
	for nama: String in dir.get_files():
		if nama.get_extension() == EKSTENSI and nama.begins_with(awalan):
			hasil.append(nama)
	hasil.sort()
	return hasil


## Parse satu segmen dari teks JSON (murni). `sumber` (nama berkas) disisipkan di tiap galat.
static func parse_teks(teks: String, sumber: String) -> SegmenRute.Hasil:
	var penghurai: JSON = JSON.new()
	var kode: int = penghurai.parse(teks)
	if kode != OK:
		var gagal: SegmenRute.Hasil = SegmenRute.Hasil.new()
		gagal.galat.append("%s: JSON rusak di baris %d: %s" % [sumber, penghurai.get_error_line(), penghurai.get_error_message()])
		return gagal
	if typeof(penghurai.data) != TYPE_DICTIONARY:
		var bukan: SegmenRute.Hasil = SegmenRute.Hasil.new()
		bukan.galat.append("%s: isi berkas harus satu objek segmen" % sumber)
		return bukan
	var data: Dictionary = penghurai.data
	var hasil: SegmenRute.Hasil = SegmenRute.parse(data)
	var diberi_sumber: Array[String] = []
	for g: String in hasil.galat:
		diberi_sumber.append("%s: %s" % [sumber, g])
	hasil.galat = diberi_sumber
	return hasil


## Aturan antar segmen (murni): id unik, id sama dengan nama berkas bila `nama_berkas` diberikan (sejajar dengan `daftar`, tanpa
## ekstensi), dan jumlah minimum per posisi (AC-1: sekurangnya dua pembuka, dua penutup, dan cukup segmen tengah untuk satu rute).
static func periksa_kumpulan(daftar: Array[SegmenRute], nama_berkas: Array[String] = []) -> Array[String]:
	var galat: Array[String] = []
	var terlihat: Dictionary = {}
	var jumlah: Array[int] = [0, 0, 0]
	for i: int in range(daftar.size()):
		var segmen: SegmenRute = daftar[i]
		if terlihat.has(segmen.id):
			galat.append("id segmen '%s' ganda" % segmen.id)
		terlihat[segmen.id] = true
		if i < nama_berkas.size() and nama_berkas[i] != segmen.id:
			galat.append("berkas '%s' berisi id '%s' (id harus sama dengan nama berkas)" % [nama_berkas[i], segmen.id])
		jumlah[segmen.posisi] += 1
	if jumlah[SegmenRute.Posisi.PEMBUKA] < 2:
		galat.append("segmen pembuka kurang dari 2 (ada %d)" % jumlah[SegmenRute.Posisi.PEMBUKA])
	if jumlah[SegmenRute.Posisi.PENUTUP] < 2:
		galat.append("segmen penutup kurang dari 2 (ada %d)" % jumlah[SegmenRute.Posisi.PENUTUP])
	var perlu_tengah: int = Config.RUTE_SEGMEN_PER_RUTE - 2
	if jumlah[SegmenRute.Posisi.TENGAH] < perlu_tengah:
		galat.append("segmen tengah kurang dari %d (ada %d), satu rute butuh %d segmen" % [perlu_tengah, jumlah[SegmenRute.Posisi.TENGAH], Config.RUTE_SEGMEN_PER_RUTE])
	return galat


## Muat semua segmen `per_*.json` di `folder` (hasil diurutkan menurut nama berkas): tiap berkas diparse, galat dikumpulkan, lalu
## aturan antar segmen diperiksa. Segmen yang tidak sah tidak masuk daftar.
static func muat_folder(folder: String = FOLDER_PERUMAHAN) -> Kumpulan:
	var hasil: Kumpulan = Kumpulan.new()
	var nama_berkas: Array[String] = []
	var daftar_nama: Array[String] = daftar_berkas(folder)
	if daftar_nama.is_empty():
		hasil.galat.append("%s: tidak ada berkas %s*.%s" % [folder, AWALAN_PERUMAHAN, EKSTENSI])
		return hasil
	for nama: String in daftar_nama:
		var jalur: String = folder.path_join(nama)
		var teks: String = baca_teks(jalur, hasil.galat)
		if teks.is_empty():
			continue
		var satu: SegmenRute.Hasil = parse_teks(teks, nama)
		hasil.galat.append_array(satu.galat)
		if satu.segmen != null:
			hasil.segmen.append(satu.segmen)
			nama_berkas.append(nama.get_basename())
	hasil.galat.append_array(periksa_kumpulan(hasil.segmen, nama_berkas))
	return hasil
