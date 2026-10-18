class_name DataMisi
extends RefCounted
## Satu misi sampingan sebagai data bertipe beserta validasinya (DATA_SCHEMA 1, GDD 10.3 sampai 10.6; AC-1 run fase4a-koran-hari). Logika murni:
## `parse` menerima `Dictionary` (hasil JSON), mengembalikan misi dan daftar galat, dan MENOLAK data tidak sah (misi null bila ada galat).
## Membaca berkas ada di `PemuatMisi`. Teks pemain (`headline`, `ringkasan`, `hud`, `petunjuk.dari_pelanggan`) adalah KUNCI terjemahan (S-2,
## rule `content-data`); batas panjang diperiksa terhadap teks hasil terjemahan: headline 40, ringkasan 60, label HUD 14, petunjuk 50.
## Field khusus template (`target`, `langkah`, `petunjuk`, `batas`) diperiksa tipenya untuk semua template; template `cari` diperiksa penuh
## (AC-1 run fase4b-misi-kucing, `_periksa_cari`): target (objek, jumlah >= 1, sisi), langkah (>= 2, jenis lihat/tangkap, titik dikenal, langkah
## pertama `rumah_dari_mulai` dan sisanya `rumah_dari_sebelumnya` berupa rentang [min, maks] bulat 1 <= min <= maks, langkah terakhir `tangkap`
## dengan `radius_ubin` dan `lama_berhenti_detik` > 0, tepat `target.jumlah` langkah tangkap, jumlah maks rentang <= `batas.rumah`), petunjuk
## (visual tidak kosong, suara, dari_pelanggan), dan batas.rumah >= 1. Template lain menyusul di fase yang membuatnya.
## Teks banner selesai dan gagal (`banner`, 4B) juga kunci terjemahan, paling banyak 24 karakter.
## Id misi tidak pernah diganti; menonaktifkan = `aktif: false`, bukan menghapus. Usulan.

const _FIELD: Array[String] = ["id", "aktif", "template", "headline", "ringkasan", "hud", "distrik", "rep_min", "syarat", "target", "langkah", "petunjuk", "batas", "hadiah", "gagal", "flag_lanjut", "jeda", "lanjutan_dari", "banner"]
const _FIELD_PETUNJUK_TEKS: String = "dari_pelanggan"
const _FIELD_FLAG: Array[String] = ["selesai", "gagal"]
const _FIELD_BANNER: Array[String] = ["selesai", "gagal"]
const _FIELD_TARGET: Array[String] = ["objek", "jumlah", "sisi"]
const _FIELD_LANGKAH: Array[String] = ["jenis", "titik", "rumah_dari_mulai", "rumah_dari_sebelumnya", "radius_ubin", "lama_berhenti_detik"]
const _FIELD_PETUNJUK: Array[String] = ["visual", "suara", "dari_pelanggan"]
const _FIELD_BATAS: Array[String] = ["rumah"]
const _FIELD_HADIAH: Array[String] = ["tingkat", "tambahan", "tokoh"]
const _JENIS_TANGKAP: String = "tangkap"
const _JENIS_LIHAT: String = "lihat"


## Satu langkah misi Cari yang sudah divalidasi (`langkah_cari`).
class LangkahCari extends RefCounted:
	## `lihat` atau `tangkap`.
	var jenis: String = ""
	## Nama titik (`Config.MISI_TITIK_DIKENAL`).
	var titik: String = ""
	## Rentang selisih rumah seberang dari titik sebelumnya (atau dari rumah pertama rute untuk langkah pertama): [min, maks], bulat.
	var rumah_min: int = 1
	var rumah_maks: int = 1
	## Hanya `tangkap`: jarak tangkap dari titik kucing, ubin, dan lama berhenti berturut-turut, detik.
	var radius_ubin: float = 0.0
	var lama_berhenti_detik: float = 0.0


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
## Kunci terjemahan banner selesai dan gagal di rute (4B, CONTENT_GUIDE 3: paling banyak `MISI_BANNER_PANJANG_MAKS` karakter, gagal tidak menyalahkan).
var banner_selesai: String = ""
var banner_gagal: String = ""
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
	if misi.template == "cari":
		_periksa_cari(misi, label, g)
	_parse_flag(data, misi, label, g)
	_parse_banner(data, misi, label, penerjemah, g)
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


static func _parse_banner(data: Dictionary, misi: DataMisi, label: String, penerjemah: Callable, g: Array[String]) -> void:
	var banner: Dictionary = ParseData.kamus_wajib(data, "banner", label, g)
	if not data.has("banner") or typeof(data["banner"]) != TYPE_DICTIONARY:
		return
	ParseData.tolak_field_asing(banner, _FIELD_BANNER, label + " banner", g)
	misi.banner_selesai = ParseData.teks_wajib(banner, "selesai", label + " banner", g)
	AturanTeks.periksa_kunci(misi.banner_selesai, Config.MISI_BANNER_PANJANG_MAKS, "banner.selesai", label, penerjemah, g)
	misi.banner_gagal = ParseData.teks_wajib(banner, "gagal", label + " banner", g)
	AturanTeks.periksa_kunci(misi.banner_gagal, Config.MISI_BANNER_PANJANG_MAKS, "banner.gagal", label, penerjemah, g)


# --- Template Cari (AC-1 run fase4b-misi-kucing) ---

## Langkah template Cari sebagai objek bertipe (data sudah divalidasi `parse`; dipakai `RencanaMisi`). Kosong bila bukan Cari.
func langkah_cari() -> Array[LangkahCari]:
	var hasil: Array[LangkahCari] = []
	if template != "cari":
		return hasil
	for butir: Variant in langkah:
		var d: Dictionary = butir
		var l: LangkahCari = LangkahCari.new()
		l.jenis = str(d["jenis"])
		l.titik = str(d["titik"])
		var rentang: Array = d["rumah_dari_mulai"] if d.has("rumah_dari_mulai") else d["rumah_dari_sebelumnya"]
		l.rumah_min = int(roundf(float(rentang[0])))
		l.rumah_maks = int(roundf(float(rentang[1])))
		if l.jenis == _JENIS_TANGKAP:
			l.radius_ubin = float(d["radius_ubin"])
			l.lama_berhenti_detik = float(d["lama_berhenti_detik"])
		hasil.append(l)
	return hasil


## Batas rumah misi (`batas.rumah`), 0 bila tidak ada.
func batas_rumah() -> int:
	return int(roundf(float(batas.get("rumah", 0))))


## Jumlah target yang harus ditangkap (`target.jumlah`), 0 bila tidak ada.
func target_jumlah() -> int:
	return int(roundf(float(target.get("jumlah", 0))))


## Koin hadiah misi menurut tingkatnya (`Config.MISI_HADIAH_KOIN`), 0 bila tingkat tidak dikenal.
func hadiah_koin() -> int:
	var indeks: int = Config.MISI_TINGKAT_HADIAH.find(str(hadiah.get("tingkat", "")))
	return Config.MISI_HADIAH_KOIN[indeks] if indeks >= 0 else 0


static func _periksa_cari(misi: DataMisi, label: String, g: Array[String]) -> void:
	var batas_rumah_nilai: int = _periksa_batas(misi, label, g)
	var jumlah_target: int = _periksa_target(misi, label, g)
	_periksa_langkah(misi, label, jumlah_target, batas_rumah_nilai, g)
	_periksa_petunjuk(misi, label, g)
	_periksa_hadiah(misi, label, g)


static func _periksa_batas(misi: DataMisi, label: String, g: Array[String]) -> int:
	ParseData.tolak_field_asing(misi.batas, _FIELD_BATAS, label + " batas", g)
	if not misi.batas.has("rumah"):
		g.append("%s: batas.rumah wajib untuk template cari" % label)
		return 0
	if not ParseData.bulat(misi.batas["rumah"]) or int(roundf(float(misi.batas["rumah"]))) < 1:
		g.append("%s: batas.rumah harus bilangan bulat >= 1" % label)
		return 0
	return int(roundf(float(misi.batas["rumah"])))


static func _periksa_target(misi: DataMisi, label: String, g: Array[String]) -> int:
	var t: Dictionary = misi.target
	ParseData.tolak_field_asing(t, _FIELD_TARGET, label + " target", g)
	for kunci: String in _FIELD_TARGET:
		if not t.has(kunci):
			g.append("%s: target.%s wajib untuk template cari" % [label, kunci])
	if t.has("objek") and (typeof(t["objek"]) != TYPE_STRING or not Config.MISI_TARGET_OBJEK_DIKENAL.has(t["objek"])):
		g.append("%s: target.objek harus salah satu dari %s" % [label, Config.MISI_TARGET_OBJEK_DIKENAL])
	if t.has("sisi") and (typeof(t["sisi"]) != TYPE_STRING or not Config.MISI_SISI_DIKENAL.has(t["sisi"])):
		g.append("%s: target.sisi harus salah satu dari %s" % [label, Config.MISI_SISI_DIKENAL])
	if t.has("jumlah"):
		if not ParseData.bulat(t["jumlah"]) or int(roundf(float(t["jumlah"]))) < 1:
			g.append("%s: target.jumlah harus bilangan bulat >= 1" % label)
		else:
			return int(roundf(float(t["jumlah"])))
	return 0


static func _periksa_langkah(misi: DataMisi, label: String, jumlah_target: int, batas_rumah_nilai: int, g: Array[String]) -> void:
	if misi.langkah.size() < 2:
		g.append("%s: langkah template cari paling sedikit 2 (dapat %d)" % [label, misi.langkah.size()])
	var jumlah_tangkap: int = 0
	var total_maks: int = 0
	var rentang_sah: bool = true
	for i: int in range(misi.langkah.size()):
		var nama: String = "%s langkah %d" % [label, i + 1]
		if typeof(misi.langkah[i]) != TYPE_DICTIONARY:
			g.append("%s: harus objek" % nama)
			rentang_sah = false
			continue
		var d: Dictionary = misi.langkah[i]
		ParseData.tolak_field_asing(d, _FIELD_LANGKAH, nama, g)
		var jenis: String = str(d.get("jenis", ""))
		if typeof(d.get("jenis")) != TYPE_STRING or not Config.MISI_LANGKAH_JENIS_DIKENAL.has(jenis):
			g.append("%s: jenis harus salah satu dari %s" % [nama, Config.MISI_LANGKAH_JENIS_DIKENAL])
		if typeof(d.get("titik")) != TYPE_STRING or not Config.MISI_TITIK_DIKENAL.has(str(d.get("titik", ""))):
			g.append("%s: titik harus salah satu dari %s" % [nama, Config.MISI_TITIK_DIKENAL])
		var kunci_rentang: String = "rumah_dari_mulai" if i == 0 else "rumah_dari_sebelumnya"
		var kunci_lain: String = "rumah_dari_sebelumnya" if i == 0 else "rumah_dari_mulai"
		if d.has(kunci_lain):
			g.append("%s: %s dipakai langkah %s (langkah ini memakai %s)" % [nama, kunci_lain, "berikutnya" if i == 0 else "pertama", kunci_rentang])
		var maks: int = _periksa_rentang(d, kunci_rentang, nama, g)
		if maks < 0:
			rentang_sah = false
		else:
			total_maks += maks
		if jenis == _JENIS_TANGKAP:
			jumlah_tangkap += 1
			_periksa_angka_positif(d, "radius_ubin", nama, g)
			_periksa_angka_positif(d, "lama_berhenti_detik", nama, g)
		elif jenis == _JENIS_LIHAT and (d.has("radius_ubin") or d.has("lama_berhenti_detik")):
			g.append("%s: radius_ubin dan lama_berhenti_detik hanya untuk langkah tangkap" % nama)
	if not misi.langkah.is_empty() and typeof(misi.langkah[misi.langkah.size() - 1]) == TYPE_DICTIONARY:
		var terakhir: Dictionary = misi.langkah[misi.langkah.size() - 1]
		if str(terakhir.get("jenis", "")) != _JENIS_TANGKAP:
			g.append("%s: langkah terakhir harus 'tangkap'" % label)
	if jumlah_target > 0 and jumlah_tangkap != jumlah_target:
		g.append("%s: jumlah langkah tangkap (%d) harus sama dengan target.jumlah (%d)" % [label, jumlah_tangkap, jumlah_target])
	if rentang_sah and batas_rumah_nilai > 0 and total_maks > batas_rumah_nilai:
		g.append("%s: jumlah maks rentang rumah (%d) melebihi batas.rumah (%d)" % [label, total_maks, batas_rumah_nilai])


## Memeriksa `d[kunci]` = [min, maks] bulat 1 <= min <= maks. Mengembalikan maks, atau -1 bila tidak sah.
static func _periksa_rentang(d: Dictionary, kunci: String, nama: String, g: Array[String]) -> int:
	if not d.has(kunci):
		g.append("%s: %s wajib" % [nama, kunci])
		return -1
	var r: Variant = d[kunci]
	if typeof(r) != TYPE_ARRAY or (r as Array).size() != 2 or not ParseData.bulat((r as Array)[0]) or not ParseData.bulat((r as Array)[1]):
		g.append("%s: %s harus [min, maks] bilangan bulat" % [nama, kunci])
		return -1
	var daftar: Array = r
	var terkecil: int = int(roundf(float(daftar[0])))
	var terbesar: int = int(roundf(float(daftar[1])))
	if terkecil < 1 or terkecil > terbesar:
		g.append("%s: %s harus memenuhi 1 <= min <= maks" % [nama, kunci])
		return -1
	return terbesar


static func _periksa_angka_positif(d: Dictionary, kunci: String, nama: String, g: Array[String]) -> void:
	if not d.has(kunci):
		g.append("%s: %s wajib untuk langkah tangkap" % [nama, kunci])
	elif not ParseData.angka(d[kunci]) or float(d[kunci]) <= 0.0:
		g.append("%s: %s harus angka > 0" % [nama, kunci])


static func _periksa_petunjuk(misi: DataMisi, label: String, g: Array[String]) -> void:
	var p: Dictionary = misi.petunjuk
	ParseData.tolak_field_asing(p, _FIELD_PETUNJUK, label + " petunjuk", g)
	for kunci: String in _FIELD_PETUNJUK:
		if not p.has(kunci):
			g.append("%s: petunjuk.%s wajib untuk template cari" % [label, kunci])
	if p.has("visual"):
		var v: Variant = p["visual"]
		if typeof(v) != TYPE_ARRAY or (v as Array).is_empty():
			g.append("%s: petunjuk.visual harus daftar tidak kosong" % label)
		else:
			for butir: Variant in (v as Array):
				if typeof(butir) != TYPE_STRING or not Config.MISI_PETUNJUK_VISUAL_DIKENAL.has(butir):
					g.append("%s: petunjuk.visual memuat '%s' yang tidak dikenal (%s)" % [label, butir, Config.MISI_PETUNJUK_VISUAL_DIKENAL])
	if p.has("suara") and (typeof(p["suara"]) != TYPE_STRING or not Config.MISI_PETUNJUK_SUARA_DIKENAL.has(p["suara"])):
		g.append("%s: petunjuk.suara harus salah satu dari %s" % [label, Config.MISI_PETUNJUK_SUARA_DIKENAL])


static func _periksa_hadiah(misi: DataMisi, label: String, g: Array[String]) -> void:
	ParseData.tolak_field_asing(misi.hadiah, _FIELD_HADIAH, label + " hadiah", g)
	for kunci: String in ["tambahan", "tokoh"]:
		if misi.hadiah.has(kunci) and typeof(misi.hadiah[kunci]) != TYPE_STRING:
			g.append("%s: hadiah.%s harus teks" % [label, kunci])
