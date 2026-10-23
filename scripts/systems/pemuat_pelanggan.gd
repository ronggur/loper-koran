class_name PemuatPelanggan
extends RefCounted
## Pemuat data kepribadian pelanggan: membaca `assets/data/customers/kepribadian.json` (array entri) lalu memvalidasinya lewat `KepribadianPelanggan` (DATA_SCHEMA 4b; AC-3 run
## fase6a2-reputasi-pelanggan). SATU-SATUNYA tempat yang membaca berkas kepribadian; `ReputationManager`, `RouteBuilder`, dan scene hanya menerima `KepribadianPelanggan.Entri`
## (rule `gdscript`). Berkas hilang, kosong, atau JSON rusak = galat tanpa crash (pelanggan semua `biasa`). Pola sama dengan `PemuatToko`. Usulan.


## Hasil memuat: entri yang sah (urut berkas) dan semua galat (termasuk antar entri).
class Kumpulan extends RefCounted:
	var entri: Array[KepribadianPelanggan.Entri] = []
	var galat: Array[String] = []

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


## Parse teks JSON (array entri) tanpa menyentuh berkas. `sumber` disisipkan di tiap galat. Entri tidak sah tidak masuk; aturan antar entri dicek bila semua entri sah.
static func parse_teks(teks: String, sumber: String) -> Kumpulan:
	var hasil: Kumpulan = Kumpulan.new()
	var penghurai: JSON = JSON.new()
	if penghurai.parse(teks) != OK:
		hasil.galat.append("%s: JSON rusak di baris %d: %s" % [sumber, penghurai.get_error_line(), penghurai.get_error_message()])
		return hasil
	if typeof(penghurai.data) != TYPE_ARRAY:
		hasil.galat.append("%s: isi berkas harus array kepribadian" % sumber)
		return hasil
	var daftar: Array = penghurai.data
	for butir: Variant in daftar:
		if typeof(butir) != TYPE_DICTIONARY:
			hasil.galat.append("%s: tiap kepribadian harus objek" % sumber)
			continue
		var data: Dictionary = butir
		var satu: KepribadianPelanggan.Hasil = KepribadianPelanggan.parse_entri(data)
		for g: String in satu.galat:
			hasil.galat.append("%s: %s" % [sumber, g])
		if satu.entri != null:
			hasil.entri.append(satu.entri)
	for g: String in KepribadianPelanggan.periksa_kumpulan(hasil.entri):
		hasil.galat.append("%s: %s" % [sumber, g])
	return hasil


## Muat `jalur` (bawaan `Config.PELANGGAN_KEPRIBADIAN_BERKAS`). Bila ada galat, `entri` dikosongkan (semua pelanggan `biasa`, game tetap jalan).
static func muat(jalur: String = Config.PELANGGAN_KEPRIBADIAN_BERKAS) -> Kumpulan:
	var hasil: Kumpulan = Kumpulan.new()
	var teks: String = baca_teks(jalur, hasil.galat)
	if teks.is_empty():
		return hasil
	var satu: Kumpulan = parse_teks(teks, jalur.get_file())
	hasil.galat.append_array(satu.galat)
	if satu.galat.is_empty():
		hasil.entri = satu.entri
	return hasil
