class_name DataHeadline
extends RefCounted
## Satu headline (berita utama, berita ringan, atau lanjutan) sebagai data bertipe beserta validasinya (DATA_SCHEMA 2, CONTENT_GUIDE 2; AC-2
## run fase4a-koran-hari). Logika murni: `parse` menerima `Dictionary` dari berkas `jenis`, menolak data tidak sah (headline null bila ada
## galat). Membaca berkas ada di `PemuatHeadline`. `teks` adalah KUNCI terjemahan (S-2); panjang (<= 40) dan gaya diperiksa terhadap teks
## hasil terjemahan.
## - `jenis` harus sama dengan jenis berkas; `efek` wajib dan hanya di `utama` (salah satu dari delapan kunci GDD 10.7; di 4A efek hanya dicatat,
##   S-5); `bobot` >= 1 (peluang relatif); `jeda` >= 0 (hari sebelum boleh muncul lagi, dihitung dari hari headline DITAMPILKAN, S-4).
## - `lanjutan`: wajib `syarat.flag` dan `slot` (`misi` atau `ringan`); bila `slot` = `misi`, tepat satu dari `misi` (id misi lanjutan yang ada di
##   data misi) atau `misi_ditunda: true` (misi lanjutan baru ada di 4B; headline tetap tampil di baris misi tanpa tombol Ambil/Lewati).
## - Rujukan flag dan id antar berkas diperiksa `PemuatHeadline.periksa_silang`. Id headline tidak pernah diganti; menonaktifkan = `aktif: false`.
## Usulan.

const JENIS: Array[String] = ["utama", "ringan", "lanjutan"]
const SLOT: Array[String] = ["misi", "ringan"]
const _FIELD_DASAR: Array[String] = ["id", "jenis", "teks", "distrik", "syarat", "bobot", "jeda", "aktif"]
const _FIELD_UTAMA: Array[String] = ["efek"]
const _FIELD_LANJUTAN: Array[String] = ["slot", "misi", "misi_ditunda"]


## Hasil `parse`: headline (null bila ada galat) dan daftar galat.
class Hasil extends RefCounted:
	var headline: DataHeadline = null
	var galat: Array[String] = []

	func sah() -> bool:
		return galat.is_empty() and headline != null


var id: String = ""
## `utama`, `ringan`, atau `lanjutan`.
var jenis: String = ""
var aktif: bool = true
## Kunci terjemahan teks headline.
var teks: String = ""
## Distrik yang boleh memunculkannya; kosong = semua.
var distrik: Array[String] = []
var syarat: Dictionary = {}
var bobot: int = Config.HEADLINE_BOBOT_MIN
var jeda: int = 0
## Kunci efek dunia (hanya `utama`).
var efek: String = ""
## `misi` atau `ringan` (hanya `lanjutan`): baris halaman koran yang ditempati.
var slot: String = ""
## Id misi lanjutan (hanya `lanjutan` slot `misi`), atau "".
var misi: String = ""
## True bila misi lanjutannya belum dibuat (4B).
var misi_ditunda: bool = false


## Parse dan validasi satu headline dari berkas berjenis `jenis_berkas`; `penerjemah` seperti di `DataMisi.parse`.
static func parse(data: Dictionary, jenis_berkas: String, penerjemah: Callable = Callable()) -> Hasil:
	var hasil: Hasil = Hasil.new()
	var g: Array[String] = hasil.galat
	var dikenal: Array[String] = _FIELD_DASAR.duplicate()
	if jenis_berkas == "utama":
		dikenal.append_array(_FIELD_UTAMA)
	if jenis_berkas == "lanjutan":
		dikenal.append_array(_FIELD_LANJUTAN)
	ParseData.tolak_field_asing(data, dikenal, "headline", g)
	var h: DataHeadline = DataHeadline.new()
	h.id = ParseData.teks_wajib(data, "id", "headline", g)
	if not h.id.is_empty() and not ParseData.nama_sah(h.id):
		g.append("headline: id '%s' harus huruf kecil, angka, dan garis bawah, dimulai huruf" % h.id)
	var label: String = "headline '%s'" % h.id
	h.jenis = ParseData.teks_wajib(data, "jenis", label, g)
	if not h.jenis.is_empty() and h.jenis != jenis_berkas:
		g.append("%s: jenis '%s' tidak sama dengan jenis berkas '%s'" % [label, h.jenis, jenis_berkas])
	h.aktif = ParseData.bool_opsional(data, "aktif", true, label, g)
	h.teks = ParseData.teks_wajib(data, "teks", label, g)
	AturanTeks.periksa_headline(h.teks, "teks", label, penerjemah, g)
	_parse_distrik(data, h, label, g)
	h.syarat = ParseData.syarat(data, label, false, g)
	h.bobot = ParseData.bulat_wajib(data, "bobot", label, g)
	if data.has("bobot") and ParseData.bulat(data["bobot"]) and h.bobot < Config.HEADLINE_BOBOT_MIN:
		g.append("%s: bobot harus >= %d" % [label, Config.HEADLINE_BOBOT_MIN])
	h.jeda = ParseData.bulat_wajib(data, "jeda", label, g)
	if data.has("jeda") and ParseData.bulat(data["jeda"]) and h.jeda < 0:
		g.append("%s: jeda tidak boleh negatif" % label)
	if jenis_berkas == "utama":
		h.efek = ParseData.teks_wajib(data, "efek", label, g)
		if not h.efek.is_empty() and not Config.EFEK_DUNIA_DIKENAL.has(h.efek):
			g.append("%s: efek '%s' tidak dikenal (GDD 10.7: %s)" % [label, h.efek, Config.EFEK_DUNIA_DIKENAL])
	if jenis_berkas == "lanjutan":
		_parse_lanjutan(data, h, label, g)
	if g.is_empty():
		hasil.headline = h
	return hasil


static func _parse_distrik(data: Dictionary, h: DataHeadline, label: String, g: Array[String]) -> void:
	for d: Variant in ParseData.daftar_wajib(data, "distrik", label, g):
		if typeof(d) == TYPE_STRING and Config.DISTRIK_DIKENAL.has(d):
			h.distrik.append(d)
		else:
			g.append("%s: distrik %s tidak dikenal (%s)" % [label, d, Config.DISTRIK_DIKENAL])


static func _parse_lanjutan(data: Dictionary, h: DataHeadline, label: String, g: Array[String]) -> void:
	if not h.syarat.has("flag"):
		g.append("%s: headline lanjutan wajib punya syarat.flag" % label)
	h.slot = ParseData.teks_wajib(data, "slot", label, g)
	if not h.slot.is_empty() and not SLOT.has(h.slot):
		g.append("%s: slot '%s' harus salah satu dari %s" % [label, h.slot, SLOT])
	h.misi = ParseData.teks_opsional(data, "misi", label, g)
	if not h.misi.is_empty() and not ParseData.nama_sah(h.misi):
		g.append("%s: misi '%s' bukan id yang sah" % [label, h.misi])
	h.misi_ditunda = ParseData.bool_opsional(data, "misi_ditunda", false, label, g)
	if h.slot == "misi" and h.misi.is_empty() == (not h.misi_ditunda):
		g.append("%s: slot misi wajib punya tepat satu dari 'misi' (id misi lanjutan) atau 'misi_ditunda': true" % label)
	if h.slot == "ringan" and (not h.misi.is_empty() or h.misi_ditunda):
		g.append("%s: slot ringan tidak boleh punya 'misi' atau 'misi_ditunda'" % label)
