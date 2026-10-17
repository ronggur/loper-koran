class_name DataMisi
extends RefCounted
## Satu misi sampingan sebagai data bertipe beserta validasinya (DATA_SCHEMA 1, GDD 10.3 sampai 10.6; AC-1 run fase4a-koran-hari). Logika murni:
## `parse` menerima `Dictionary` (hasil JSON), mengembalikan misi dan daftar galat, dan MENOLAK data tidak sah (misi null bila ada galat).
## Membaca berkas ada di `PemuatMisi`. Teks pemain (`headline`, `ringkasan`, `hud`, `petunjuk.dari_pelanggan`) adalah KUNCI terjemahan (S-2,
## rule `content-data`); batas panjang diperiksa terhadap teks hasil terjemahan: headline 40, ringkasan 60, label HUD 14, petunjuk 50.
## Field khusus template (`target`, `langkah`, `petunjuk`, `batas`) di 4A hanya diperiksa tipenya; aturan template Cari ditambah di 4B.
## Id misi tidak pernah diganti; menonaktifkan = `aktif: false`, bukan menghapus. Usulan.

const _FIELD: Array[String] = ["id", "aktif", "template", "headline", "ringkasan", "hud", "distrik", "rep_min", "syarat", "target", "langkah", "petunjuk", "batas", "hadiah", "gagal", "flag_lanjut", "jeda", "lanjutan_dari"]
const _FIELD_PETUNJUK_TEKS: String = "dari_pelanggan"
const _FIELD_FLAG: Array[String] = ["selesai", "gagal"]


## Hasil `parse`: misi (null bila ada galat) dan daftar galat.
class Hasil extends RefCounted:
	var misi: DataMisi = null
	var galat: Array[String] = []

	func sah() -> bool:
		return galat.is_empty() and misi != null


var id: String = ""
var aktif: bool = true
var template: String = ""
## Kunci terjemahan headline, ringkasan satu baris, dan label HUD.
var headline: String = ""
var ringkasan: String = ""
var hud: String = ""
var distrik: String = ""
var rep_min: int = 0
var syarat: Dictionary = {}
var target: Dictionary = {}
var langkah: Array = []
var petunjuk: Dictionary = {}
var batas: Dictionary = {}
var hadiah: Dictionary = {}
var gagal: Dictionary = {}
## Flag yang ditulis saat selesai dan saat gagal (dibaca headline besok).
var flag_selesai: String = ""
var flag_gagal: String = ""
## Hari sebelum boleh muncul lagi (dihitung dari hari misi DIAMBIL, S-4).
var jeda: int = 0
## Id misi asal bila ini misi lanjutan ("" bila misi biasa); misi lanjutan tidak ikut undian biasa.
var lanjutan_dari: String = ""


## Parse dan validasi satu misi dari `data`; `penerjemah` (Callable kunci -> teks, tidak sah = TranslationServer) untuk memeriksa teks.
static func parse(data: Dictionary, penerjemah: Callable = Callable()) -> Hasil:
	var hasil: Hasil = Hasil.new()
	var g: Array[String] = hasil.galat
	ParseData.tolak_field_asing(data, _FIELD, "misi", g)
	var misi: DataMisi = DataMisi.new()
	misi.id = ParseData.teks_wajib(data, "id", "misi", g)
	if not misi.id.is_empty() and not ParseData.nama_sah(misi.id):
		g.append("misi: id '%s' harus huruf kecil, angka, dan garis bawah, dimulai huruf" % misi.id)
	var label: String = "misi '%s'" % misi.id
	misi.aktif = ParseData.bool_opsional(data, "aktif", true, label, g)
	misi.template = ParseData.teks_wajib(data, "template", label, g)
	if not misi.template.is_empty() and not Config.MISI_TEMPLATE_DIKENAL.has(misi.template):
		g.append("%s: template '%s' tidak dikenal (%s)" % [label, misi.template, Config.MISI_TEMPLATE_DIKENAL])
	misi.headline = ParseData.teks_wajib(data, "headline", label, g)
	AturanTeks.periksa_headline(misi.headline, "headline", label, penerjemah, g)
	misi.ringkasan = ParseData.teks_wajib(data, "ringkasan", label, g)
	AturanTeks.periksa_kunci(misi.ringkasan, Config.MISI_RINGKASAN_PANJANG_MAKS, "ringkasan", label, penerjemah, g)
	misi.hud = ParseData.teks_wajib(data, "hud", label, g)
	AturanTeks.periksa_kunci(misi.hud, Config.MISI_HUD_PANJANG_MAKS, "hud", label, penerjemah, g)
	misi.distrik = ParseData.teks_wajib(data, "distrik", label, g)
	if not misi.distrik.is_empty() and not Config.DISTRIK_DIKENAL.has(misi.distrik):
		g.append("%s: distrik '%s' tidak dikenal (%s)" % [label, misi.distrik, Config.DISTRIK_DIKENAL])
	misi.rep_min = ParseData.bulat_wajib(data, "rep_min", label, g)
	if data.has("rep_min") and ParseData.bulat(data["rep_min"]) and misi.rep_min < 0:
		g.append("%s: rep_min tidak boleh negatif" % label)
	misi.syarat = ParseData.syarat(data, label, true, g)
	misi.target = ParseData.kamus_wajib(data, "target", label, g)
	misi.langkah = ParseData.daftar_wajib(data, "langkah", label, g)
	misi.petunjuk = ParseData.kamus_wajib(data, "petunjuk", label, g)
	if misi.petunjuk.has(_FIELD_PETUNJUK_TEKS):
		if typeof(misi.petunjuk[_FIELD_PETUNJUK_TEKS]) == TYPE_STRING:
			AturanTeks.periksa_kunci(misi.petunjuk[_FIELD_PETUNJUK_TEKS], Config.MISI_PETUNJUK_PANJANG_MAKS, "petunjuk.dari_pelanggan", label, penerjemah, g)
		else:
			g.append("%s: petunjuk.dari_pelanggan harus kunci terjemahan (teks)" % label)
	misi.batas = ParseData.kamus_wajib(data, "batas", label, g)
	misi.hadiah = ParseData.kamus_wajib(data, "hadiah", label, g)
	if data.has("hadiah") and typeof(data["hadiah"]) == TYPE_DICTIONARY:
		var tingkat: Variant = misi.hadiah.get("tingkat")
		if typeof(tingkat) != TYPE_STRING or not Config.MISI_TINGKAT_HADIAH.has(tingkat):
			g.append("%s: hadiah.tingkat harus salah satu dari %s (GDD 10.5)" % [label, Config.MISI_TINGKAT_HADIAH])
	misi.gagal = ParseData.kamus_wajib(data, "gagal", label, g)
	_parse_flag(data, misi, label, g)
	misi.jeda = ParseData.bulat_wajib(data, "jeda", label, g)
	if data.has("jeda") and ParseData.bulat(data["jeda"]) and misi.jeda < 0:
		g.append("%s: jeda tidak boleh negatif" % label)
	misi.lanjutan_dari = ParseData.teks_opsional(data, "lanjutan_dari", label, g)
	if not misi.lanjutan_dari.is_empty() and not ParseData.nama_sah(misi.lanjutan_dari):
		g.append("%s: lanjutan_dari '%s' bukan id yang sah" % [label, misi.lanjutan_dari])
	if g.is_empty():
		hasil.misi = misi
	return hasil


static func _parse_flag(data: Dictionary, misi: DataMisi, label: String, g: Array[String]) -> void:
	var flag: Dictionary = ParseData.kamus_wajib(data, "flag_lanjut", label, g)
	if not data.has("flag_lanjut") or typeof(data["flag_lanjut"]) != TYPE_DICTIONARY:
		return
	ParseData.tolak_field_asing(flag, _FIELD_FLAG, label + " flag_lanjut", g)
	var nilai: Array[String] = []
	for kunci: String in _FIELD_FLAG:
		var teks: String = ParseData.teks_wajib(flag, kunci, label + " flag_lanjut", g)
		if not teks.is_empty() and not ParseData.nama_sah(teks):
			g.append("%s: flag_lanjut.%s '%s' harus id huruf kecil dan garis bawah" % [label, kunci, teks])
		nilai.append(teks)
	misi.flag_selesai = nilai[0]
	misi.flag_gagal = nilai[1]
