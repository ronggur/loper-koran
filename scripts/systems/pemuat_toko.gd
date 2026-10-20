class_name PemuatToko
extends RefCounted
## Pemuat data upgrade bengkel: membaca `assets/data/shop/upgrades.json` (array upgrade) lalu memvalidasinya lewat `DataToko.parse` (DATA_SCHEMA 6; AC-17 run
## fase6a1-bengkel-kondisi). SATU-SATUNYA tempat yang membaca berkas upgrade; layar bengkel, `Economy`, dan `BikeCondition` hanya menerima `DataToko` (rule `gdscript`).
## Pembacaan berkas (`baca_teks`) dipisah dari `parse_teks` dan `periksa_kumpulan`, yang murni, supaya data rusak bisa dites tanpa berkas. Berkas tidak ada, kosong, atau
## JSON rusak = galat tanpa crash (layar bengkel menampilkan kondisi galat yang jujur; bengkel tetap bisa dilewati, K-4). Pola sama dengan `PemuatMisi`. Usulan.

## Berkas data upgrade di resource project (ikut paket game).
const BERKAS: String = "res://assets/data/shop/upgrades.json"


## Hasil memuat upgrade: upgrade yang sah (urut berkas) dan semua galat (termasuk antar upgrade).
class Kumpulan extends RefCounted:
	var upgrade: Array[DataToko] = []
	var galat: Array[String] = []

	## True bila tidak ada galat.
	func sah() -> bool:
		return galat.is_empty()

	## Upgrade dengan id `id`, atau null.
	func cari(id: String) -> DataToko:
		for u: DataToko in upgrade:
			if u.id == id:
				return u
		return null

	## Upgrade level `level` untuk komponen `komponen`, atau null.
	func cari_level(komponen: String, level: int) -> DataToko:
		for u: DataToko in upgrade:
			if u.komponen == komponen and u.level == level:
				return u
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


## Parse berkas upgrade (array) dari teks JSON (murni). `sumber` (nama berkas) disisipkan di tiap galat. Upgrade yang tidak sah tidak masuk.
static func parse_teks(teks: String, sumber: String, penerjemah: Callable = Callable()) -> Kumpulan:
	var hasil: Kumpulan = Kumpulan.new()
	var penghurai: JSON = JSON.new()
	if penghurai.parse(teks) != OK:
		hasil.galat.append("%s: JSON rusak di baris %d: %s" % [sumber, penghurai.get_error_line(), penghurai.get_error_message()])
		return hasil
	if typeof(penghurai.data) != TYPE_ARRAY:
		hasil.galat.append("%s: isi berkas harus array upgrade" % sumber)
		return hasil
	var daftar: Array = penghurai.data
	for butir: Variant in daftar:
		if typeof(butir) != TYPE_DICTIONARY:
			hasil.galat.append("%s: tiap upgrade harus objek" % sumber)
			continue
		var data: Dictionary = butir
		var satu: DataToko.Hasil = DataToko.parse(data, penerjemah)
		for g: String in satu.galat:
			hasil.galat.append("%s: %s" % [sumber, g])
		if satu.upgrade != null:
			hasil.upgrade.append(satu.upgrade)
	return hasil


## Aturan antar upgrade (murni): id unik; level tiap komponen berurutan 1, 2, 3, ... tanpa lompatan atau kembar; semua id wajib (`TOKO_ID_WAJIB`) ada dan masing-masing
## untuk komponen yang sejajar dengan `KONDISI_KOMPONEN` (satu per komponen).
static func periksa_kumpulan(daftar: Array[DataToko]) -> Array[String]:
	var galat: Array[String] = []
	var terlihat: Dictionary = {}
	for u: DataToko in daftar:
		if terlihat.has(u.id):
			galat.append("id upgrade '%s' ganda" % u.id)
		terlihat[u.id] = u
	for k: String in Config.KONDISI_KOMPONEN:
		var level: Array[int] = []
		for u: DataToko in daftar:
			if u.komponen == k:
				level.append(u.level)
		level.sort()
		for i: int in range(level.size()):
			if level[i] != i + 1:
				galat.append("level upgrade komponen '%s' harus berurutan 1, 2, 3, ... tanpa lompatan atau kembar, dapat %s" % [k, level])
				break
	for i: int in range(Config.TOKO_ID_WAJIB.size()):
		var wajib: String = Config.TOKO_ID_WAJIB[i]
		if not terlihat.has(wajib):
			galat.append("upgrade wajib '%s' tidak ada" % wajib)
			continue
		var u: DataToko = terlihat[wajib]
		if u.komponen != Config.KONDISI_KOMPONEN[i] or u.level != 1:
			galat.append("upgrade wajib '%s' harus level 1 untuk komponen '%s'" % [wajib, Config.KONDISI_KOMPONEN[i]])
	return galat


## Muat `jalur` (bawaan `BERKAS`): baca, parse, lalu periksa aturan antar upgrade.
static func muat(jalur: String = BERKAS, penerjemah: Callable = Callable()) -> Kumpulan:
	var hasil: Kumpulan = Kumpulan.new()
	var teks: String = baca_teks(jalur, hasil.galat)
	if teks.is_empty():
		return hasil
	var satu: Kumpulan = parse_teks(teks, jalur.get_file(), penerjemah)
	hasil.galat.append_array(satu.galat)
	hasil.upgrade = satu.upgrade
	hasil.galat.append_array(periksa_kumpulan(hasil.upgrade))
	return hasil
