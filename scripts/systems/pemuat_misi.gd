class_name PemuatMisi
extends RefCounted
## Pemuat data misi: membaca berkas `assets/data/missions/*.json` (array misi per distrik) lalu memvalidasinya lewat `DataMisi.parse`
## (DATA_SCHEMA 1; AC-1 run fase4a-koran-hari). SATU-SATUNYA tempat yang membaca berkas misi; UI, entitas, dan `HeadlineManager` hanya menerima
## `DataMisi` (rule `gdscript`). Fungsi pembacaan (`baca_teks`, `daftar_berkas`) dipisah dari `parse_teks` dan `periksa_kumpulan`, yang murni,
## supaya data rusak bisa dites tanpa berkas. Pola sama dengan `PemuatRute`. Usulan, belum dikunci.

## Folder data misi di resource project (ikut paket game).
const FOLDER: String = "res://assets/data/missions"
## Ekstensi berkas misi.
const EKSTENSI: String = "json"


## Hasil memuat banyak misi: misi yang sah (urut berkas, lalu urutan di berkas) dan semua galat (termasuk antar misi).
class Kumpulan extends RefCounted:
	var misi: Array[DataMisi] = []
	var galat: Array[String] = []

	## True bila tidak ada galat.
	func sah() -> bool:
		return galat.is_empty()

	## Misi dengan id `id`, atau null.
	func cari(id: String) -> DataMisi:
		for m: DataMisi in misi:
			if m.id == id:
				return m
		return null


## Isi satu berkas sebagai teks (galat dikembalikan di `galat`, teks kosong bila gagal). Satu-satunya fungsi yang menyentuh berkas.
static func baca_teks(jalur: String, galat: Array[String]) -> String:
	if not FileAccess.file_exists(jalur):
		galat.append("%s: berkas tidak ada" % jalur)
		return ""
	var teks: String = FileAccess.get_file_as_string(jalur)
	if teks.is_empty():
		galat.append("%s: berkas kosong atau tidak terbaca" % jalur)
	return teks


## Nama berkas `*.json` di `folder`, diurutkan (urutan DirAccess tidak dijamin).
static func daftar_berkas(folder: String) -> Array[String]:
	var hasil: Array[String] = []
	var dir: DirAccess = DirAccess.open(folder)
	if dir == null:
		return hasil
	for nama: String in dir.get_files():
		if nama.get_extension() == EKSTENSI:
			hasil.append(nama)
	hasil.sort()
	return hasil


## Parse satu berkas misi (array) dari teks JSON (murni). `sumber` (nama berkas) disisipkan di tiap galat. Misi yang tidak sah tidak masuk.
static func parse_teks(teks: String, sumber: String, penerjemah: Callable = Callable()) -> Kumpulan:
	var hasil: Kumpulan = Kumpulan.new()
	var penghurai: JSON = JSON.new()
	if penghurai.parse(teks) != OK:
		hasil.galat.append("%s: JSON rusak di baris %d: %s" % [sumber, penghurai.get_error_line(), penghurai.get_error_message()])
		return hasil
	if typeof(penghurai.data) != TYPE_ARRAY:
		hasil.galat.append("%s: isi berkas harus array misi" % sumber)
		return hasil
	var daftar: Array = penghurai.data
	for butir: Variant in daftar:
		if typeof(butir) != TYPE_DICTIONARY:
			hasil.galat.append("%s: tiap misi harus objek" % sumber)
			continue
		var data: Dictionary = butir
		var satu: DataMisi.Hasil = DataMisi.parse(data, penerjemah)
		for g: String in satu.galat:
			hasil.galat.append("%s: %s" % [sumber, g])
		if satu.misi != null:
			hasil.misi.append(satu.misi)
	return hasil


## Aturan antar misi (murni): id unik. Rujukan `lanjutan_dari` harus id misi yang ada.
static func periksa_kumpulan(daftar: Array[DataMisi]) -> Array[String]:
	var galat: Array[String] = []
	var terlihat: Dictionary = {}
	for m: DataMisi in daftar:
		if terlihat.has(m.id):
			galat.append("id misi '%s' ganda" % m.id)
		terlihat[m.id] = true
	for m: DataMisi in daftar:
		if not m.lanjutan_dari.is_empty() and not terlihat.has(m.lanjutan_dari):
			galat.append("misi '%s': lanjutan_dari '%s' bukan id misi yang ada" % [m.id, m.lanjutan_dari])
	return galat


## Muat semua misi `*.json` di `folder`: tiap berkas diparse, galat dikumpulkan, lalu aturan antar misi diperiksa.
static func muat_folder(folder: String = FOLDER, penerjemah: Callable = Callable()) -> Kumpulan:
	var hasil: Kumpulan = Kumpulan.new()
	var daftar_nama: Array[String] = daftar_berkas(folder)
	if daftar_nama.is_empty():
		hasil.galat.append("%s: tidak ada berkas *.%s" % [folder, EKSTENSI])
		return hasil
	for nama: String in daftar_nama:
		var teks: String = baca_teks(folder.path_join(nama), hasil.galat)
		if teks.is_empty():
			continue
		var satu: Kumpulan = parse_teks(teks, nama, penerjemah)
		hasil.galat.append_array(satu.galat)
		hasil.misi.append_array(satu.misi)
	hasil.galat.append_array(periksa_kumpulan(hasil.misi))
	return hasil
