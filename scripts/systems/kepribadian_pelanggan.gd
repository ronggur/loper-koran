class_name KepribadianPelanggan
extends RefCounted
## Kepribadian pelanggan sebagai data bertipe beserta validasinya dan pemetaan rumah -> kepribadian (GDD 8; O-4, AC-3 run fase6a2-reputasi-pelanggan, usulan). Logika murni: `parse_entri`
## menerima `Dictionary` (hasil JSON), `periksa_kumpulan` memeriksa aturan antar entri, `dari_id` memetakan id rumah ke kepribadian. Membaca berkas ada di `PemuatPelanggan`.
##
## Empat id permanen (`Config.PELANGGAN_KEPRIBADIAN_ID`), arti tiap id ada di kode (`ReputationManager`, `RouteBuilder`), bobot sebaran ada di data:
## - `biasa`: tanpa efek.
## - `cerewet`: antaran halaman (rumput) tidak memberi kredit reputasi.
## - `pemberi_tip`: pemberi tip persisten (selalu didahulukan di `RouteBuilder` bila masuk rute).
## - `sensitif`: satu-satunya yang bisa berhenti karena tidak terantar.
## Kepribadian rumah = fungsi deterministik dari id rumah (hash FNV-1a atas byte UTF-8 id, sisa bagi jumlah bobot, pencarian kumulatif urut berkas). TIDAK disimpan di save: satu sumber, tidak bisa melenceng.

const BIASA: String = "biasa"
const CEREWET: String = "cerewet"
const PEMBERI_TIP: String = "pemberi_tip"
const SENSITIF: String = "sensitif"
const _FIELD: Array[String] = ["id", "bobot"]


## Satu entri kepribadian yang sudah divalidasi.
class Entri extends RefCounted:
	var id: String = ""
	var bobot: int = 0


## Hasil `parse_entri`: entri (null bila ada galat) dan galat.
class Hasil extends RefCounted:
	var entri: Entri = null
	var galat: Array[String] = []

	func sah() -> bool:
		return galat.is_empty() and entri != null


## Parse dan validasi satu entri: field wajib `id` (salah satu id dikenal) dan `bobot` (bilangan bulat > 0), field asing ditolak.
static func parse_entri(data: Dictionary) -> Hasil:
	var hasil: Hasil = Hasil.new()
	var g: Array[String] = hasil.galat
	ParseData.tolak_field_asing(data, _FIELD, "kepribadian", g)
	var e: Entri = Entri.new()
	e.id = ParseData.teks_wajib(data, "id", "kepribadian", g)
	var label: String = "kepribadian '%s'" % e.id
	if not e.id.is_empty() and not Config.PELANGGAN_KEPRIBADIAN_ID.has(e.id):
		g.append("%s: id tidak dikenal (%s)" % [label, Config.PELANGGAN_KEPRIBADIAN_ID])
	e.bobot = ParseData.bulat_wajib(data, "bobot", label, g)
	if data.has("bobot") and ParseData.bulat(data["bobot"]) and e.bobot <= 0:
		g.append("%s: bobot harus bilangan bulat > 0" % label)
	if g.is_empty():
		hasil.entri = e
	return hasil


## Aturan antar entri (murni): id unik, semua id dikenal ada, jumlah bobot > 0.
static func periksa_kumpulan(daftar: Array[Entri]) -> Array[String]:
	var galat: Array[String] = []
	var terlihat: Dictionary = {}
	var jumlah: int = 0
	for e: Entri in daftar:
		if terlihat.has(e.id):
			galat.append("id kepribadian '%s' ganda" % e.id)
		terlihat[e.id] = true
		jumlah += e.bobot
	for wajib: String in Config.PELANGGAN_KEPRIBADIAN_ID:
		if not terlihat.has(wajib):
			galat.append("kepribadian wajib '%s' tidak ada" % wajib)
	if jumlah <= 0:
		galat.append("jumlah bobot kepribadian harus > 0")
	return galat


## FNV-1a 32 bit atas byte UTF-8 `teks` (tanpa `hash()` Godot dan tanpa RNG).
static func fnv1a_teks(teks: String) -> int:
	var nilai: int = Config.HASH_FNV1A_AWAL
	for b: int in teks.to_utf8_buffer():
		nilai = ((nilai ^ b) * Config.HASH_FNV1A_KALI) & Config.HASH_FNV1A_MASKER
	return nilai


## Kepribadian rumah `id_rumah` dari pustaka `pustaka` (urut berkas): `biasa` bila pustaka kosong atau jumlah bobotnya bukan positif (data rusak tidak menjatuhkan game).
static func dari_id(id_rumah: String, pustaka: Array[Entri]) -> String:
	var jumlah: int = 0
	for e: Entri in pustaka:
		jumlah += maxi(e.bobot, 0)
	if jumlah <= 0:
		return BIASA
	var sisa: int = fnv1a_teks(id_rumah) % jumlah
	for e: Entri in pustaka:
		var bobot: int = maxi(e.bobot, 0)
		if sisa < bobot:
			return e.id
		sisa -= bobot
	return BIASA
