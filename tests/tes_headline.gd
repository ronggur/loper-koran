class_name TesHeadline
extends RefCounted
## Tes data konten dan `HeadlineManager` run fase4a-koran-hari bagian B dan C (AC-1 sampai AC-6, AC-25): `DataMisi`, `DataHeadline`, `PemuatMisi`,
## `PemuatHeadline`, `AturanTeks`, dan `HeadlineManager`.
##
## Oracle independen (AC-25, pelajaran QA-008 run 2B): panjang dan gaya teks headline dihitung ulang tes dari `translations/konten.csv` dengan
## kode tes sendiri (bukan `AturanTeks`); jeda diperiksa dengan model sederhana tes (hari terakhir tampil + jeda); distribusi bobot dihitung dari
## 2000 benih dengan toleransi 4 sigma binomial yang dihitung tes. Pustaka sintetis dibuat langsung dari `DataHeadline` agar kasus tepi terkendali.

const FOLDER_MISI: String = "res://assets/data/missions"
const FOLDER_HEADLINE: String = "res://assets/data/headlines"
const BERKAS_KONTEN: String = "res://translations/konten.csv"
## Delapan kunci efek dunia (GDD 10.7), ditulis ulang di sini.
const EFEK_GDD: Array[String] = ["hajatan", "hujan_deras", "air_pasang", "tujuh_belasan", "pasar_kaget", "jalan_diperbaiki", "panen_raya", "mati_lampu"]
const PENGHUBUNG: Array[String] = ["di", "ke", "dari", "dan", "yang", "untuk", "pada"]

var _cek: Callable
var _judul: Callable
var _misi_cache: PemuatMisi.Kumpulan = null
var _pustaka_cache: PemuatHeadline.Pustaka = null


func _init(cek: Callable, judul: Callable) -> void:
	_cek = cek
	_judul = judul


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_test_config()
	_test_data_nyata_misi()
	_test_data_nyata_headline()
	_test_teks_oracle_csv()
	_test_misi_ditolak()
	_test_headline_ditolak()
	_test_aturan_teks()
	_test_periksa_silang()
	_test_pemuat_berkas_rusak()
	_test_manager_determinisme_dan_variasi()
	_test_manager_hari_satu_dan_misi()
	_test_manager_lanjutan()
	_test_manager_jeda_oracle()
	_test_manager_syarat_dan_distrik()
	_test_manager_bobot()
	_test_manager_semua_dalam_jeda()
	_test_manager_tidak_mengubah_masukan()
	_test_catat_jeda()


# --- Pembantu ---

func _misi_nyata() -> PemuatMisi.Kumpulan:
	if _misi_cache == null:
		_misi_cache = PemuatMisi.muat_folder(FOLDER_MISI)
	return _misi_cache


func _pustaka_nyata() -> PemuatHeadline.Pustaka:
	if _pustaka_cache == null:
		_pustaka_cache = PemuatHeadline.muat_folder(FOLDER_HEADLINE)
	return _pustaka_cache


## Penerjemah sintetis: kunci yang ada di `kamus` diterjemahkan, sisanya dikembalikan apa adanya.
func _tl(kamus: Dictionary) -> Callable:
	return func(kunci: String) -> String: return str(kamus.get(kunci, kunci))


func _csv_konten() -> Dictionary:
	var hasil: Dictionary = {}
	var berkas: FileAccess = FileAccess.open(BERKAS_KONTEN, FileAccess.READ)
	var pertama: bool = true
	while not berkas.eof_reached():
		var baris: PackedStringArray = berkas.get_csv_line()
		if baris.size() < 2:
			continue
		if pertama:
			pertama = false
			continue
		hasil[baris[0]] = baris[1]
	return hasil


func _misi_dasar() -> Dictionary:
	return {
		"id": "m_uji", "template": "cari", "headline": "H", "ringkasan": "R", "hud": "U", "distrik": "perumahan", "rep_min": 0, "syarat": {},
		"target": {}, "langkah": [], "petunjuk": {}, "batas": {"rumah": 12}, "hadiah": {"tingkat": "kecil"}, "gagal": {}, "flag_lanjut": {"selesai": "a_ok", "gagal": "a_gagal"}, "jeda": 3,
	}


func _kamus_dasar() -> Dictionary:
	return {"H": "Kucing Bu Ratmi Hilang", "R": "Cari kucing", "U": "Kucing"}


func _headline_dasar(jenis: String) -> Dictionary:
	var d: Dictionary = {"id": "h_uji", "jenis": jenis, "teks": "H", "distrik": [], "syarat": {}, "bobot": 1, "jeda": 2}
	if jenis == "utama":
		d["efek"] = "hajatan"
	if jenis == "lanjutan":
		d["syarat"] = {"flag": "a_gagal"}
		d["slot"] = "ringan"
	return d


## Galat parse misi untuk `data` dengan penerjemah sintetis `kamus` (kosong = kamus dasar).
func _galat_misi(data: Dictionary, kamus: Dictionary = {}) -> String:
	var k: Dictionary = _kamus_dasar()
	k.merge(kamus, true)
	return "; ".join(DataMisi.parse(data, _tl(k)).galat)


func _galat_headline(data: Dictionary, jenis: String, kamus: Dictionary = {}) -> String:
	var k: Dictionary = _kamus_dasar()
	k.merge(kamus, true)
	return "; ".join(DataHeadline.parse(data, jenis, _tl(k)).galat)


func _hl(id: String, jenis: String, bobot: int = 1, jeda: int = 0, syarat: Dictionary = {}, distrik: Array[String] = [], efek: String = "", slot: String = "", misi: String = "", tunda: bool = false) -> DataHeadline:
	var h: DataHeadline = DataHeadline.new()
	h.id = id
	h.jenis = jenis
	h.teks = "T_" + id
	h.bobot = bobot
	h.jeda = jeda
	h.syarat = syarat
	h.distrik = distrik
	h.efek = efek
	h.slot = slot
	h.misi = misi
	h.misi_ditunda = tunda
	return h


func _ms(id: String, jeda: int = 5, syarat: Dictionary = {}, distrik: String = "perumahan", rep_min: int = 0) -> DataMisi:
	var m: DataMisi = DataMisi.new()
	m.id = id
	m.headline = "MH_" + id
	m.ringkasan = "MR_" + id
	m.hud = "MU_" + id
	m.distrik = distrik
	m.jeda = jeda
	m.syarat = syarat
	m.rep_min = rep_min
	m.flag_selesai = id + "_ok"
	m.flag_gagal = id + "_gagal"
	return m


func _pustaka(utama: Array[DataHeadline], ringan: Array[DataHeadline] = [], lanjutan: Array[DataHeadline] = []) -> PemuatHeadline.Pustaka:
	var p: PemuatHeadline.Pustaka = PemuatHeadline.Pustaka.new()
	p.utama = utama
	p.ringan = ringan
	p.lanjutan = lanjutan
	return p


func _masukan(hari: int, pustaka: PemuatHeadline.Pustaka, misi: Array[DataMisi] = []) -> HeadlineManager.Masukan:
	var m: HeadlineManager.Masukan = HeadlineManager.Masukan.new()
	m.hari = hari
	m.pustaka = pustaka
	m.misi = misi
	return m


func _masukan_nyata(hari: int) -> HeadlineManager.Masukan:
	return _masukan(hari, _pustaka_nyata(), _misi_nyata().misi)


# --- Config ---

func _test_config() -> void:
	_judul.call("Headline dan misi: angka Config literal (AC-1, AC-2)")
	var harapan: Dictionary = {
		"HEADLINE_PANJANG_MAKS": 40, "MISI_RINGKASAN_PANJANG_MAKS": 60, "MISI_HUD_PANJANG_MAKS": 14, "MISI_PETUNJUK_PANJANG_MAKS": 50, "HEADLINE_BOBOT_MIN": 1,
		"MISI_HARI_TUTORIAL": 1, "MISI_ID_TUTORIAL": "p1_kucing", "REPUTASI_BAWAAN": 0, "DISTRIK_AWAL": "perumahan",
	}
	var peta: Dictionary = (load("res://scripts/config.gd") as GDScript).get_script_constant_map()
	for nama: String in harapan:
		check(peta.get(nama) == harapan[nama], "Config.%s = %s (literal), dapat %s" % [nama, harapan[nama], peta.get(nama)])
	check(peta.get("EFEK_DUNIA_DIKENAL") == EFEK_GDD and peta.get("HEADLINE_KATA_PENGHUBUNG") == PENGHUBUNG, "delapan kunci efek dunia (GDD 10.7) dan tujuh kata penghubung (CONTENT_GUIDE 2) sama dengan literal tes")


# --- Data nyata (AC-1 sampai AC-3) ---

func _test_data_nyata_misi() -> void:
	_judul.call("Data nyata: assets/data/missions/perumahan.json lolos PemuatMisi (AC-1)")
	var k: PemuatMisi.Kumpulan = _misi_nyata()
	check(k.sah(), "misi nyata sah, galat: %s" % [k.galat])
	check(k.misi.size() == 1, "satu misi nyata (P1), dapat %d" % k.misi.size())
	var p1: DataMisi = k.cari("p1_kucing")
	check(p1 != null, "misi p1_kucing ada")
	if p1 == null:
		return
	check(p1.aktif and p1.template == "cari" and p1.distrik == "perumahan" and p1.rep_min == 0 and p1.jeda == 7, "p1: aktif, template cari, perumahan, rep_min 0, jeda 7 (DATA_SCHEMA 1)")
	check(p1.hadiah.get("tingkat") == "sedang" and p1.flag_selesai == "kucing_ketemu" and p1.flag_gagal == "kucing_belum", "p1: hadiah sedang (GDD 10.6), flag lanjut kucing_ketemu dan kucing_belum")
	check(int(p1.batas.get("rumah", 0)) == 12 and p1.batas.size() == 1 and p1.langkah.size() == 3 and p1.syarat == {}, "p1: batas 12 rumah, tiga langkah, tanpa syarat")
	check(tr(p1.headline) == "Kucing Bu Ratmi Hilang Sejak Semalam" and tr(p1.hud) == "Kucing" and tr(p1.ringkasan) == "Cari kucing di sisi seberang sebelum 12 rumah", "teks p1 lewat kunci terjemahan = contoh DATA_SCHEMA 1")


func _test_data_nyata_headline() -> void:
	_judul.call("Data nyata: assets/data/headlines/*.json lolos PemuatHeadline (AC-2, AC-3)")
	var p: PemuatHeadline.Pustaka = _pustaka_nyata()
	check(p.sah(), "headline nyata sah, galat: %s" % [p.galat])
	check(p.utama.size() >= 6 and p.ringan.size() >= 8 and p.lanjutan.size() == 2, "isi: >= 6 berita utama (%d), >= 8 ringan (%d), 2 lanjutan (%d)" % [p.utama.size(), p.ringan.size(), p.lanjutan.size()])
	var aktif: int = 0
	var efek: Array[String] = []
	for h: DataHeadline in p.utama:
		aktif += 1 if h.aktif and (h.distrik.is_empty() or h.distrik.has("perumahan")) else 0
		efek.append(h.efek)
	check(aktif >= 2 and aktif <= 5, "pool berita utama aktif untuk perumahan 2 sampai 5 (dapat %d)" % aktif)
	for e: String in EFEK_GDD:
		check(efek.has(e), "efek %s (GDD 10.7) dipakai sebuah berita utama" % e)
	var id_lanjutan: Array[String] = []
	for h: DataHeadline in p.lanjutan:
		id_lanjutan.append(h.id)
	check(id_lanjutan == ["lanjutan_kucing_belum", "lanjutan_kucing_ketemu"], "lanjutan: kucing_belum lalu kucing_ketemu (CONTENT_GUIDE 2), dapat %s" % [id_lanjutan])
	var belum: DataHeadline = p.lanjutan[0]
	var ketemu: DataHeadline = p.lanjutan[1]
	check(belum.syarat == {"flag": "kucing_belum"} and belum.slot == "misi" and belum.misi_ditunda and belum.misi.is_empty(), "kucing_belum: syarat flag kucing_belum, slot misi, misi_ditunda (misi lanjutan 4B)")
	check(ketemu.syarat == {"flag": "kucing_ketemu"} and ketemu.slot == "ringan" and not ketemu.misi_ditunda, "kucing_ketemu: syarat flag kucing_ketemu, slot ringan")
	var salah: Array[String] = PemuatHeadline.periksa_silang(p, _misi_nyata().misi)
	check(salah.is_empty(), "aturan silang lolos (id unik, flag tidak yatim, rujukan misi): %s" % [salah])


func _test_teks_oracle_csv() -> void:
	_judul.call("Teks headline: panjang, huruf kapital, titik, tanda seru dihitung ulang dari konten.csv (AC-2, AC-25)")
	var csv: Dictionary = _csv_konten()
	var kunci_headline: Array[String] = []
	for h: DataHeadline in _pustaka_nyata().semua():
		kunci_headline.append(h.teks)
	for m: DataMisi in _misi_nyata().misi:
		kunci_headline.append(m.headline)
	check(kunci_headline.size() >= 19, "ada 19 kunci headline untuk diperiksa (8 utama + 8 ringan + 2 lanjutan + 1 misi), dapat %d" % kunci_headline.size())
	for kunci: String in kunci_headline:
		check(csv.has(kunci), "kunci %s ada di konten.csv" % kunci)
		var teks: String = csv.get(kunci, "")
		check(teks.length() <= 40 and not teks.is_empty(), "%s: '%s' (%d) paling banyak 40 karakter" % [kunci, teks, teks.length()])
		check(not teks.ends_with(".") and not teks.contains("!!"), "%s: tanpa titik di akhir dan tanpa tanda seru beruntun" % kunci)
		var kata: PackedStringArray = teks.split(" ")
		var kapital: bool = true
		for i: int in range(kata.size()):
			var awal: String = kata[i].substr(0, 1)
			var huruf_besar: bool = awal == awal.to_upper() and awal != awal.to_lower()
			if not huruf_besar and not (i > 0 and PENGHUBUNG.has(kata[i])):
				kapital = false
		check(kapital, "%s: '%s' Huruf Kapital di Awal Kata (penghubung boleh kecil)" % [kunci, teks])
	var ringkasan: String = csv.get("MISI_P1_KUCING_RINGKASAN", "")
	check(ringkasan.length() <= 60 and csv.get("MISI_P1_KUCING_HUD", "").length() <= 14 and csv.get("MISI_P1_KUCING_PETUNJUK", "").length() <= 50, "ringkasan <= 60, label HUD <= 14, petunjuk <= 50 karakter")
	var kunci_json: Array[String] = []
	var re: RegEx = RegEx.create_from_string("\"((?:KORAN|MISI)_[A-Z0-9_]+)\"")
	for folder: String in [FOLDER_MISI, FOLDER_HEADLINE]:
		var dir: DirAccess = DirAccess.open(folder)
		for nama: String in dir.get_files():
			for cocok: RegExMatch in re.search_all(FileAccess.get_file_as_string(folder.path_join(nama))):
				kunci_json.append(cocok.get_string(1))
	check(kunci_json.size() >= 22, "data merujuk 22 kunci terjemahan (dapat %d)" % kunci_json.size())
	for kunci: String in kunci_json:
		check(csv.has(kunci), "kunci %s yang dirujuk data ada di konten.csv" % kunci)
	# Isi konten aman semua umur (CONTENT_GUIDE 1): tanpa kata yang dilarang (kekerasan, politik, SARA, merek).
	var terlarang: Array[String] = ["bunuh", "tembak", "darah", "perang", "pilkada", "partai", "presiden", "coca", "indomie", "gojek", "grab"]
	var ditemukan: Array[String] = []
	for kunci: String in csv:
		for kata_buruk: String in terlarang:
			if str(csv[kunci]).to_lower().contains(kata_buruk):
				ditemukan.append("%s:%s" % [kunci, kata_buruk])
	check(ditemukan.is_empty(), "teks konten tanpa kata kekerasan, politik, atau merek nyata: %s" % [ditemukan])


# --- Penolakan (AC-1, AC-2; mutan 'panjang headline tidak divalidasi') ---

func _test_misi_ditolak() -> void:
	_judul.call("DataMisi: data tidak sah ditolak dengan galat yang menyebut sebabnya (AC-1)")
	check(_galat_misi(_misi_dasar()) == "", "misi dasar sintetis sah (kontrol)")
	check(DataMisi.parse(_misi_dasar(), _tl(_kamus_dasar())).sah(), "misi dasar menghasilkan objek DataMisi")
	for wajib: String in ["id", "template", "headline", "ringkasan", "hud", "distrik", "rep_min", "syarat", "target", "langkah", "petunjuk", "batas", "hadiah", "gagal", "flag_lanjut", "jeda"]:
		var d: Dictionary = _misi_dasar()
		d.erase(wajib)
		var g: String = _galat_misi(d)
		check(g.contains("'%s'" % wajib) and DataMisi.parse(d, _tl(_kamus_dasar())).misi == null, "field wajib '%s' hilang ditolak (misi null)" % wajib)
	var salah_tipe: Dictionary = {"id": 5, "template": 5, "rep_min": "x", "syarat": [], "target": [], "langkah": {}, "petunjuk": [], "batas": 3, "hadiah": 1, "gagal": [], "flag_lanjut": 2, "jeda": "7", "aktif": "ya", "distrik": 4, "headline": 9}
	for kunci: String in salah_tipe:
		var d: Dictionary = _misi_dasar()
		d[kunci] = salah_tipe[kunci]
		check(_galat_misi(d) != "", "field '%s' bertipe salah ditolak" % kunci)
	var asing: Dictionary = _misi_dasar()
	asing["hadiah_ekstra"] = 1
	check(_galat_misi(asing).contains("tidak dikenal"), "field tidak dikenal ditolak")
	for id_buruk: String in ["P1_Kucing", "p1 kucing", "1kucing", "p1-kucing", "_p1", "kucing!"]:
		var d: Dictionary = _misi_dasar()
		d["id"] = id_buruk
		check(_galat_misi(d).contains("huruf kecil"), "id '%s' (bukan huruf kecil dan garis bawah) ditolak" % id_buruk)
	var d_template: Dictionary = _misi_dasar()
	d_template["template"] = "terbang"
	check(_galat_misi(d_template).contains("template"), "template tidak dikenal ditolak")
	for t: String in ["cari", "antar_khusus", "lempar_khusus", "kumpul", "kejar", "jaga"]:
		var d: Dictionary = _misi_dasar()
		d["template"] = t
		check(_galat_misi(d) == "", "template %s (GDD 10.4) diterima" % t)
	# Batas panjang pada teks hasil terjemahan, tepat di batas diterima dan satu karakter lebih ditolak.
	var batas: Array = [["headline", "H", 40], ["ringkasan", "R", 60], ["hud", "U", 14]]
	for b: Array in batas:
		var nama: String = b[0]
		var kunci: String = b[1]
		var maks: int = b[2]
		var persis: String = _teks_kapital(maks)
		check(_galat_misi(_misi_dasar(), {kunci: persis}) == "", "%s tepat %d karakter diterima" % [nama, maks])
		var lebih: String = _teks_kapital(maks + 1)
		check(_galat_misi(_misi_dasar(), {kunci: lebih}).contains("lebih panjang dari %d" % maks), "%s %d karakter ditolak (batas %d, teks hasil terjemahan)" % [nama, maks + 1, maks])
	var d_negatif: Dictionary = _misi_dasar()
	d_negatif["rep_min"] = -1
	check(_galat_misi(d_negatif).contains("negatif"), "rep_min negatif ditolak")
	var d_jeda: Dictionary = _misi_dasar()
	d_jeda["jeda"] = -2
	check(_galat_misi(d_jeda).contains("negatif"), "jeda negatif ditolak")
	var d_kunci: Dictionary = _misi_dasar()
	d_kunci["headline"] = "KUNCI_TIDAK_ADA"
	check(_galat_misi(d_kunci).contains("tidak ada"), "kunci terjemahan yang tidak ada ditolak")
	var d_tingkat: Dictionary = _misi_dasar()
	d_tingkat["hadiah"] = {"tingkat": "raksasa"}
	check(_galat_misi(d_tingkat).contains("hadiah.tingkat"), "hadiah.tingkat di luar kecil/sedang/besar ditolak")
	for tingkat: String in ["kecil", "sedang", "besar"]:
		var d: Dictionary = _misi_dasar()
		d["hadiah"] = {"tingkat": tingkat}
		check(_galat_misi(d) == "", "tingkat %s diterima" % tingkat)
	var d_flag: Dictionary = _misi_dasar()
	d_flag["flag_lanjut"] = {"selesai": "a_ok"}
	check(_galat_misi(d_flag).contains("gagal"), "flag_lanjut tanpa 'gagal' ditolak")
	var d_flag2: Dictionary = _misi_dasar()
	d_flag2["flag_lanjut"] = {"selesai": "a_ok", "gagal": "Salah Ketik"}
	check(_galat_misi(d_flag2).contains("flag_lanjut.gagal"), "flag_lanjut berisi bukan id ditolak")
	var d_syarat: Dictionary = _misi_dasar()
	d_syarat["syarat"] = {"cuaca": "cerah"}
	check(_galat_misi(d_syarat).contains("syarat.cuaca"), "syarat dengan kunci tak dikenal ditolak")
	var d_syarat_ok: Dictionary = _misi_dasar()
	d_syarat_ok["syarat"] = {"berita_utama": "air_pasang", "flag": "a_ok", "hari_min": 3}
	check(_galat_misi(d_syarat_ok) == "", "syarat berita_utama, flag, hari_min diterima")
	var d_syarat_efek: Dictionary = _misi_dasar()
	d_syarat_efek["syarat"] = {"berita_utama": "gempa"}
	check(_galat_misi(d_syarat_efek).contains("berita_utama"), "syarat.berita_utama bukan efek GDD 10.7 ditolak")
	var d_petunjuk: Dictionary = _misi_dasar()
	d_petunjuk["petunjuk"] = {"dari_pelanggan": "H"}
	check(_galat_misi(d_petunjuk, {"H": _teks_kapital(51)}).contains("lebih panjang dari 50"), "petunjuk dari pelanggan > 50 karakter ditolak")
	var d_aktif: Dictionary = _misi_dasar()
	d_aktif["aktif"] = false
	var hasil_aktif: DataMisi.Hasil = DataMisi.parse(d_aktif, _tl(_kamus_dasar()))
	check(hasil_aktif.sah() and not hasil_aktif.misi.aktif, "aktif:false sah (menonaktifkan tanpa menghapus)")
	var k_json: PemuatMisi.Kumpulan = PemuatMisi.parse_teks("{bukan json", "x.json")
	check(not k_json.sah() and k_json.galat[0].contains("JSON rusak"), "JSON rusak: galat menyebut berkas dan sebabnya")
	check(not PemuatMisi.parse_teks("{}", "x.json").sah(), "isi berkas yang bukan array ditolak")
	var ganda: Array[DataMisi] = [_ms("sama"), _ms("sama")]
	check(PemuatMisi.periksa_kumpulan(ganda).size() == 1 and PemuatMisi.periksa_kumpulan(ganda)[0].contains("ganda"), "id misi ganda ditolak")
	var anak: DataMisi = _ms("anak")
	anak.lanjutan_dari = "tidak_ada"
	check(PemuatMisi.periksa_kumpulan([anak]).size() == 1, "lanjutan_dari yang menunjuk misi yang tidak ada ditolak")


## Teks sepanjang `n` karakter berpola Huruf Kapital di Awal Kata ("Aaaaa Aaaaa ...") yang lolos gaya headline.
func _teks_kapital(n: int) -> String:
	var teks: String = ""
	while teks.length() < n:
		if not teks.is_empty():
			teks += " "
		teks += "Aaaaa"
	teks = teks.substr(0, n)
	if teks.ends_with(" "):
		teks = teks.substr(0, n - 1) + "a"
	return teks


func _test_headline_ditolak() -> void:
	_judul.call("DataHeadline: data tidak sah ditolak (AC-2)")
	for jenis: String in ["utama", "ringan", "lanjutan"]:
		check(_galat_headline(_headline_dasar(jenis), jenis) == "", "headline %s dasar sintetis sah (kontrol)" % jenis)
		for wajib: String in ["id", "jenis", "teks", "distrik", "syarat", "bobot", "jeda"]:
			var d: Dictionary = _headline_dasar(jenis)
			d.erase(wajib)
			check(_galat_headline(d, jenis).contains("'%s'" % wajib), "%s: field wajib '%s' hilang ditolak" % [jenis, wajib])
	var d_jenis: Dictionary = _headline_dasar("utama")
	d_jenis["jenis"] = "ringan"
	check(_galat_headline(d_jenis, "utama").contains("jenis"), "jenis tidak sama dengan jenis berkas ditolak")
	var d_efek: Dictionary = _headline_dasar("utama")
	d_efek.erase("efek")
	check(_galat_headline(d_efek, "utama").contains("efek"), "berita utama tanpa efek ditolak")
	d_efek["efek"] = "gempa"
	check(_galat_headline(d_efek, "utama").contains("efek"), "efek di luar delapan kunci GDD 10.7 ditolak")
	for e: String in EFEK_GDD:
		var d: Dictionary = _headline_dasar("utama")
		d["efek"] = e
		check(_galat_headline(d, "utama") == "", "efek %s diterima" % e)
	var d_efek_ringan: Dictionary = _headline_dasar("ringan")
	d_efek_ringan["efek"] = "hajatan"
	check(_galat_headline(d_efek_ringan, "ringan").contains("tidak dikenal"), "efek hanya di berita utama (ringan dengan efek ditolak)")
	var d_bobot: Dictionary = _headline_dasar("ringan")
	d_bobot["bobot"] = 0
	check(_galat_headline(d_bobot, "ringan").contains("bobot"), "bobot 0 ditolak (>= 1)")
	d_bobot["bobot"] = 2.5
	check(_galat_headline(d_bobot, "ringan").contains("bobot"), "bobot pecahan ditolak")
	var d_jeda: Dictionary = _headline_dasar("ringan")
	d_jeda["jeda"] = -1
	check(_galat_headline(d_jeda, "ringan").contains("jeda"), "jeda negatif ditolak")
	var d_distrik: Dictionary = _headline_dasar("ringan")
	d_distrik["distrik"] = ["bulan"]
	check(_galat_headline(d_distrik, "ringan").contains("distrik"), "distrik tidak dikenal ditolak")
	var d_tanpa_flag: Dictionary = _headline_dasar("lanjutan")
	d_tanpa_flag["syarat"] = {}
	check(_galat_headline(d_tanpa_flag, "lanjutan").contains("syarat.flag"), "lanjutan tanpa syarat.flag ditolak")
	var d_slot: Dictionary = _headline_dasar("lanjutan")
	d_slot["slot"] = "utama"
	check(_galat_headline(d_slot, "lanjutan").contains("slot"), "slot lanjutan di luar misi/ringan ditolak")
	var d_misi_kosong: Dictionary = _headline_dasar("lanjutan")
	d_misi_kosong["slot"] = "misi"
	check(_galat_headline(d_misi_kosong, "lanjutan").contains("tepat satu"), "slot misi tanpa 'misi' dan tanpa 'misi_ditunda' ditolak")
	d_misi_kosong["misi_ditunda"] = true
	check(_galat_headline(d_misi_kosong, "lanjutan") == "", "slot misi dengan misi_ditunda true diterima")
	d_misi_kosong["misi"] = "m_uji"
	check(_galat_headline(d_misi_kosong, "lanjutan").contains("tepat satu"), "slot misi dengan 'misi' DAN 'misi_ditunda' ditolak")
	d_misi_kosong.erase("misi_ditunda")
	check(_galat_headline(d_misi_kosong, "lanjutan") == "", "slot misi dengan id misi lanjutan diterima")
	var d_ringan_misi: Dictionary = _headline_dasar("lanjutan")
	d_ringan_misi["misi"] = "m_uji"
	check(_galat_headline(d_ringan_misi, "lanjutan").contains("slot ringan"), "slot ringan dengan 'misi' ditolak")
	var d_asing: Dictionary = _headline_dasar("ringan")
	d_asing["slot"] = "misi"
	check(_galat_headline(d_asing, "ringan").contains("tidak dikenal"), "slot hanya di berita lanjutan (ringan dengan slot ditolak)")
	var d_kunci: Dictionary = _headline_dasar("ringan")
	d_kunci["teks"] = "KUNCI_TIDAK_ADA"
	check(_galat_headline(d_kunci, "ringan").contains("tidak ada"), "kunci terjemahan yang tidak ada ditolak")
	var d_id: Dictionary = _headline_dasar("ringan")
	d_id["id"] = "Ringan Satu"
	check(_galat_headline(d_id, "ringan").contains("huruf kecil"), "id headline bukan huruf kecil dan garis bawah ditolak")
	# Panjang dan gaya pada teks hasil terjemahan.
	check(_galat_headline(_headline_dasar("ringan"), "ringan", {"H": _teks_kapital(40)}) == "", "headline tepat 40 karakter diterima")
	check(_galat_headline(_headline_dasar("ringan"), "ringan", {"H": _teks_kapital(41)}).contains("lebih panjang dari 40"), "headline 41 karakter ditolak (teks hasil terjemahan)")
	var gaya: Dictionary = {
		"huruf kecil": ["hajatan Warga Digelar", "kapital"], "kata kecil di tengah": ["Warga hias Jalan", "kapital"], "titik akhir": ["Warga Hias Jalan.", "titik"],
		"seru beruntun": ["Warga Hias Jalan!!", "seru"], "spasi ganda": ["Warga  Hias Jalan", "spasi"], "penghubung di awal": ["di Jalan Warga", "kapital"],
	}
	for nama: String in gaya:
		var pasangan: Array = gaya[nama]
		check(_galat_headline(_headline_dasar("ringan"), "ringan", {"H": pasangan[0]}) != "", "gaya headline ditolak: %s ('%s')" % [nama, pasangan[0]])
	for baik: String in ["Warga Hias Jalan untuk Tujuh Belasan", "Pasar Kaget Digelar di Ujung Jalan", "Anak Blok 3 Gelar Lomba", "Tetangga Baru Bagi-Bagi Kue ke Warga", "Mati Lampu Semalam, Pagi Masih Redup", "Satu Kejadian!"]:
		check(_galat_headline(_headline_dasar("ringan"), "ringan", {"H": baik}) == "", "gaya headline diterima: '%s'" % baik)
	var p_json: PemuatHeadline.Pustaka = PemuatHeadline.parse_teks("[1, 2]", "ringan", "ringan.json")
	check(not p_json.sah() and p_json.galat.size() == 2, "isi array yang bukan objek ditolak per butir")
	check(not PemuatHeadline.parse_teks("{}", "ringan", "ringan.json").sah() and not PemuatHeadline.parse_teks("{bukan json", "ringan", "ringan.json").sah(), "isi bukan array dan JSON rusak ditolak")


func _test_aturan_teks() -> void:
	_judul.call("AturanTeks: penerjemah disuntik dan kunci yang ada (AC-2)")
	var tl: Callable = _tl({"A": "Halo"})
	check(AturanTeks.kunci_ada(tl, "A") and not AturanTeks.kunci_ada(tl, "B"), "kunci_ada mengenali kunci dengan terjemahan dan menolak yang tidak")
	check(AturanTeks.terjemah_dengan(tl, "A") == "Halo" and AturanTeks.terjemah_dengan(Callable(), "KORAN_NAMA") == AturanTeks.terjemah("KORAN_NAMA"), "terjemah_dengan memakai penerjemah yang diberikan, Callable kosong = TranslationServer")
	check(AturanTeks.terjemah("MISI_P1_KUCING_HUD") == "Kucing", "TranslationServer menerjemahkan kunci konten nyata")


func _test_periksa_silang() -> void:
	_judul.call("PemuatHeadline.periksa_silang: id unik antar headline dan misi, flag tidak yatim, rujukan misi (AC-2)")
	var misi: Array[DataMisi] = [_ms("m_a")]
	var baik: PemuatHeadline.Pustaka = _pustaka([_hl("u_1", "utama", 1, 0, {}, [], "hajatan")], [_hl("r_1", "ringan")], [_hl("l_1", "lanjutan", 1, 0, {"flag": "m_a_gagal"}, [], "", "misi", "", true)])
	check(PemuatHeadline.periksa_silang(baik, misi).is_empty(), "pustaka sintetis yang benar lolos")
	var ganda: PemuatHeadline.Pustaka = _pustaka([_hl("u_1", "utama", 1, 0, {}, [], "hajatan")], [_hl("u_1", "ringan")])
	check(PemuatHeadline.periksa_silang(ganda, misi).size() == 1, "id sama di dua berkas headline ditolak")
	var sama_misi: PemuatHeadline.Pustaka = _pustaka([_hl("m_a", "utama", 1, 0, {}, [], "hajatan")])
	check(PemuatHeadline.periksa_silang(sama_misi, misi).size() == 1, "id headline sama dengan id misi ditolak")
	var yatim: PemuatHeadline.Pustaka = _pustaka([], [], [_hl("l_1", "lanjutan", 1, 0, {"flag": "flag_yatim"}, [], "", "ringan")])
	check(PemuatHeadline.periksa_silang(yatim, misi).size() == 1 and PemuatHeadline.periksa_silang(yatim, misi)[0].contains("flag_yatim"), "syarat.flag yang tidak ditulis misi mana pun ditolak")
	var tanpa_misi: PemuatHeadline.Pustaka = _pustaka([], [], [_hl("l_1", "lanjutan", 1, 0, {"flag": "m_a_ok"}, [], "", "misi", "m_hilang")])
	check(PemuatHeadline.periksa_silang(tanpa_misi, misi).size() == 1, "headline lanjutan yang merujuk misi yang tidak ada ditolak")
	var misi_yatim: DataMisi = _ms("m_b", 5, {"flag": "flag_yatim"})
	check(PemuatHeadline.periksa_silang(_pustaka([]), [misi_yatim]).size() == 1, "syarat.flag misi yang yatim ditolak")
	var d_misi_ganda: Array[DataMisi] = [_ms("m_a"), _ms("m_a")]
	check(not PemuatHeadline.periksa_silang(_pustaka([]), d_misi_ganda).is_empty(), "id misi ganda ditolak")


func _test_pemuat_berkas_rusak() -> void:
	_judul.call("Pemuat: folder atau berkas yang hilang dilaporkan sebagai galat, bukan crash (AC-1, AC-2)")
	var tidak_ada: PemuatMisi.Kumpulan = PemuatMisi.muat_folder("res://assets/data/tidak_ada")
	check(not tidak_ada.sah() and tidak_ada.misi.is_empty(), "folder misi yang tidak ada: galat, daftar kosong")
	var hilang: PemuatHeadline.Pustaka = PemuatHeadline.muat_folder("res://assets/data/tidak_ada")
	check(not hilang.sah() and hilang.galat.size() == 3 and hilang.semua().is_empty(), "folder headline yang tidak ada: tiga galat (tiga berkas), daftar kosong")
	check(PemuatMisi.daftar_berkas(FOLDER_MISI) == ["perumahan.json"], "folder misi nyata berisi perumahan.json")


# --- HeadlineManager (AC-5, AC-6) ---

func _test_manager_determinisme_dan_variasi() -> void:
	_judul.call("HeadlineManager: masukan sama = halaman sama, hari berbeda bisa berbeda (AC-5, AC-6a)")
	var sama: bool = true
	for hari: int in range(1, 41):
		var a: HeadlineManager.Halaman = HeadlineManager.susun(_masukan_nyata(hari))
		for ulang: int in range(5):
			if HeadlineManager.susun(_masukan_nyata(hari)).daftar_id() != a.daftar_id():
				sama = false
	check(sama, "40 hari x 5 pemanggilan berulang: halaman selalu sama persis (tanpa randi() global)")
	var utama: Dictionary = {}
	var ringan: Dictionary = {}
	for hari: int in range(1, 31):
		var h: HeadlineManager.Halaman = HeadlineManager.susun(_masukan_nyata(hari))
		utama[h.utama.id] = true
		ringan[h.ringan.id] = true
	check(utama.size() >= 3 and ringan.size() >= 5, "30 hari tanpa riwayat jeda: >= 3 berita utama berbeda (%d) dan >= 5 berita ringan berbeda (%d)" % [utama.size(), ringan.size()])
	var dasar_lain: HeadlineManager.Masukan = _masukan_nyata(7)
	dasar_lain.benih_dasar = 999
	var berbeda: int = 0
	for hari: int in range(1, 31):
		var m1: HeadlineManager.Masukan = _masukan_nyata(hari)
		var m2: HeadlineManager.Masukan = _masukan_nyata(hari)
		m2.benih_dasar = 999
		if HeadlineManager.susun(m1).daftar_id() != HeadlineManager.susun(m2).daftar_id():
			berbeda += 1
	check(berbeda >= 10, "benih dasar berbeda mengubah halaman di banyak hari (%d dari 30)" % berbeda)
	var halaman: HeadlineManager.Halaman = HeadlineManager.susun(_masukan_nyata(3))
	check(halaman.hari == 3 and halaman.utama != null and halaman.utama.jenis == "utama" and not halaman.utama.efek.is_empty() and halaman.ringan.jenis == "ringan", "halaman: hari, berita utama (dengan efek), dan berita ringan terisi")


func _test_manager_hari_satu_dan_misi() -> void:
	_judul.call("HeadlineManager: hari 1 = P1 (tutorial), misi dalam jeda tidak dipilih, tanpa kandidat = slot kosong (AC-6e, AC-6f, S-8)")
	var h1: HeadlineManager.Halaman = HeadlineManager.susun(_masukan_nyata(1))
	check(h1.misi != null and h1.misi.id == "p1_kucing" and h1.misi.misi_id == "p1_kucing" and h1.misi.jenis == "misi" and h1.misi.jeda_misi == 7, "hari 1: slot misi = p1_kucing (STORY 6), jeda misi 7")
	check(h1.misi.teks == "MISI_P1_KUCING_HEADLINE" and h1.misi.ringkasan == "MISI_P1_KUCING_RINGKASAN", "baris misi membawa kunci headline dan ringkasan misi")
	var hari_dua: HeadlineManager.Masukan = _masukan_nyata(2)
	check(HeadlineManager.susun(hari_dua).misi != null and HeadlineManager.susun(hari_dua).misi.id == "p1_kucing", "hari 2 tanpa riwayat: satu-satunya misi memenuhi syarat dipilih")
	var jeda: HeadlineManager.Masukan = _masukan_nyata(2)
	jeda.misi_jeda = {"p1_kucing": 8}
	check(HeadlineManager.susun(jeda).misi == null, "hari 2 setelah P1 diambil di hari 1 (jeda 7 -> boleh lagi hari 8): slot misi kosong, bukan galat")
	for hari: int in range(2, 8):
		var m: HeadlineManager.Masukan = _masukan_nyata(hari)
		m.misi_jeda = {"p1_kucing": 8}
		check(HeadlineManager.susun(m).misi == null, "hari %d masih dalam jeda misi: tanpa misi" % hari)
	var hari_delapan: HeadlineManager.Masukan = _masukan_nyata(8)
	hari_delapan.misi_jeda = {"p1_kucing": 8}
	check(HeadlineManager.susun(hari_delapan).misi != null, "hari 8 jeda berakhir: P1 boleh lagi")
	var h1_jeda: HeadlineManager.Masukan = _masukan_nyata(1)
	h1_jeda.misi_jeda = {"p1_kucing": 50}
	check(HeadlineManager.susun(h1_jeda).misi != null and HeadlineManager.susun(h1_jeda).misi.id == "p1_kucing", "hari 1 selalu tutorial P1 (hari tutorial mendahului jeda)")
	var tanpa: HeadlineManager.Masukan = _masukan(5, _pustaka_nyata(), [])
	var h_tanpa: HeadlineManager.Halaman = HeadlineManager.susun(tanpa)
	check(h_tanpa.misi == null and h_tanpa.utama != null and h_tanpa.ringan != null, "tanpa data misi: misi null, berita utama dan ringan tetap terisi")
	var nonaktif: DataMisi = _ms("m_off")
	nonaktif.aktif = false
	var hari_tiga: HeadlineManager.Masukan = _masukan(3, _pustaka_nyata(), [nonaktif])
	check(HeadlineManager.susun(hari_tiga).misi == null, "misi nonaktif tidak dipilih")
	var distrik_lain: HeadlineManager.Masukan = _masukan(3, _pustaka_nyata(), [_ms("m_desa", 5, {}, "desa")])
	check(HeadlineManager.susun(distrik_lain).misi == null, "misi distrik lain tidak dipilih")
	var reputasi: HeadlineManager.Masukan = _masukan(3, _pustaka_nyata(), [_ms("m_rep", 5, {}, "perumahan", 3)])
	check(HeadlineManager.susun(reputasi).misi == null, "misi dengan rep_min 3 tidak dipilih saat reputasi 0")
	reputasi.reputasi = 3
	check(HeadlineManager.susun(reputasi).misi != null, "misi dengan rep_min 3 dipilih saat reputasi 3")
	var anak: DataMisi = _ms("m_anak")
	anak.lanjutan_dari = "m_induk"
	check(HeadlineManager.susun(_masukan(3, _pustaka_nyata(), [anak])).misi == null, "misi lanjutan tidak ikut undian biasa")


func _test_manager_lanjutan() -> void:
	_judul.call("HeadlineManager: lanjutan kemarin diprioritaskan, flag tak dikenal diabaikan (AC-6b)")
	for hari: int in [2, 3, 9, 25]:
		var m: HeadlineManager.Masukan = _masukan_nyata(hari)
		m.flag = ["kucing_belum"]
		var h: HeadlineManager.Halaman = HeadlineManager.susun(m)
		check(h.misi != null and h.misi.id == "lanjutan_kucing_belum" and h.misi.jenis == "lanjutan" and h.misi.misi_id == "", "hari %d flag kucing_belum: slot misi = headline lanjutan tanpa misi (misi_ditunda)" % hari)
		var m2: HeadlineManager.Masukan = _masukan_nyata(hari)
		m2.flag = ["kucing_ketemu"]
		var h2: HeadlineManager.Halaman = HeadlineManager.susun(m2)
		check(h2.ringan.id == "lanjutan_kucing_ketemu" and h2.ringan.jenis == "lanjutan", "hari %d flag kucing_ketemu: slot ringan = lanjutan_kucing_ketemu" % hari)
		var kosong: HeadlineManager.Halaman = HeadlineManager.susun(_masukan_nyata(hari))
		check(kosong.misi == null or kosong.misi.id != "lanjutan_kucing_belum", "hari %d tanpa flag: lanjutan tidak muncul" % hari)
		check(kosong.ringan.id != "lanjutan_kucing_ketemu", "hari %d tanpa flag: lanjutan ringan tidak muncul" % hari)
	var asing: HeadlineManager.Masukan = _masukan_nyata(4)
	asing.flag = ["flag_hantu", "lain_lagi"]
	check(HeadlineManager.susun(asing).daftar_id() == HeadlineManager.susun(_masukan_nyata(4)).daftar_id(), "flag yang tidak dikenal data diabaikan tanpa galat (halaman sama dengan tanpa flag)")
	var keduanya: HeadlineManager.Masukan = _masukan_nyata(6)
	keduanya.flag = ["kucing_belum", "kucing_ketemu"]
	var h_dua: HeadlineManager.Halaman = HeadlineManager.susun(keduanya)
	check(h_dua.misi.id == "lanjutan_kucing_belum" and h_dua.ringan.id == "lanjutan_kucing_ketemu", "dua flag aktif: kedua lanjutan menempati slotnya masing-masing")
	var utama_sama: bool = true
	for hari: int in range(1, 15):
		var a: HeadlineManager.Masukan = _masukan_nyata(hari)
		var b: HeadlineManager.Masukan = _masukan_nyata(hari)
		b.flag = ["kucing_belum", "kucing_ketemu"]
		if HeadlineManager.susun(a).utama.id != HeadlineManager.susun(b).utama.id:
			utama_sama = false
	check(utama_sama, "adanya lanjutan tidak mengubah undian berita utama (aliran acak per slot)")
	var dalam_jeda: HeadlineManager.Masukan = _masukan_nyata(5)
	dalam_jeda.flag = ["kucing_belum"]
	dalam_jeda.headline_jeda = {"lanjutan_kucing_belum": 35}
	check(HeadlineManager.susun(dalam_jeda).misi == null or HeadlineManager.susun(dalam_jeda).misi.id != "lanjutan_kucing_belum", "lanjutan yang masih dalam jeda tidak muncul lagi")
	# Lanjutan dengan misi lanjutan yang ada: baris misi membawa misi itu.
	var misi_anak: DataMisi = _ms("m_anak", 4)
	misi_anak.lanjutan_dari = "m_induk"
	var pustaka: PemuatHeadline.Pustaka = _pustaka([_hl("u_1", "utama", 1, 0, {}, [], "hajatan")], [_hl("r_1", "ringan")], [_hl("l_1", "lanjutan", 1, 0, {"flag": "f_1"}, [], "", "misi", "m_anak")])
	var m3: HeadlineManager.Masukan = _masukan(3, pustaka, [_ms("m_induk"), misi_anak])
	m3.flag = ["f_1"]
	var h3: HeadlineManager.Halaman = HeadlineManager.susun(m3)
	check(h3.misi.id == "l_1" and h3.misi.misi_id == "m_anak" and h3.misi.jeda_misi == 4 and h3.misi.ringkasan == "MR_m_anak", "lanjutan slot misi dengan misi lanjutan: misi_id, ringkasan, dan jeda misi dari misi itu")


func _test_manager_jeda_oracle() -> void:
	_judul.call("HeadlineManager: jeda dihormati, model tes sendiri atas 60 hari berantai (AC-6c)")
	var pustaka: PemuatHeadline.Pustaka = _pustaka_nyata()
	var terakhir_sampai: Dictionary = {}
	var pelanggaran: Array[String] = []
	var jumlah_tanpa_alternatif: int = 0
	for hari: int in range(1, 61):
		var m: HeadlineManager.Masukan = _masukan_nyata(hari)
		m.headline_jeda = terakhir_sampai.duplicate()
		var h: HeadlineManager.Halaman = HeadlineManager.susun(m)
		for pasangan: Array in [[h.utama, pustaka.utama], [h.ringan, pustaka.ringan]]:
			var entri: HeadlineManager.Entri = pasangan[0]
			var pool: Array = pasangan[1]
			var tersedia: Array[String] = []
			var kandidat: Array[String] = []
			for butir: Variant in pool:
				var d: DataHeadline = butir
				if not d.aktif or not (d.distrik.is_empty() or d.distrik.has("perumahan")):
					continue
				kandidat.append(d.id)
				if hari >= int(terakhir_sampai.get(d.id, 0)):
					tersedia.append(d.id)
			if entri == null:
				pelanggaran.append("hari %d: baris kosong padahal ada kandidat" % hari)
			elif not tersedia.is_empty() and not tersedia.has(entri.id):
				pelanggaran.append("hari %d: %s dipilih padahal masih jeda sampai %s" % [hari, entri.id, terakhir_sampai.get(entri.id)])
			elif tersedia.is_empty():
				jumlah_tanpa_alternatif += 1
				var paling_cepat: int = 1000000
				for id: String in kandidat:
					paling_cepat = mini(paling_cepat, int(terakhir_sampai.get(id, 0)))
				if int(terakhir_sampai.get(entri.id, 0)) != paling_cepat:
					pelanggaran.append("hari %d: semua dalam jeda tapi %s bukan yang paling cepat berakhir" % [hari, entri.id])
		# Catat jeda dengan model tes: hari + jeda dari data.
		for entri2: HeadlineManager.Entri in [h.utama, h.ringan]:
			var data: DataHeadline = null
			for d2: DataHeadline in pustaka.semua():
				if d2.id == entri2.id:
					data = d2
			terakhir_sampai[entri2.id] = hari + data.jeda
	check(pelanggaran.is_empty(), "60 hari berantai: tidak ada headline yang muncul di dalam jeda selama ada alternatif: %s" % [pelanggaran.slice(0, 3)])
	var ringan_aktif: int = 0
	for d: DataHeadline in pustaka.ringan:
		ringan_aktif += 1 if d.aktif else 0
	check(jumlah_tanpa_alternatif == 0, "pool nyata cukup besar: tidak pernah semua kandidat dalam jeda (%d kali)" % jumlah_tanpa_alternatif)
	# Mutan 'jeda diabaikan' harus terlihat: dengan jeda panjang pada semua kecuali satu, hanya satu yang boleh dipilih.
	var u: Array[DataHeadline] = [_hl("a", "utama", 1, 0, {}, [], "hajatan"), _hl("b", "utama", 1, 0, {}, [], "hajatan"), _hl("c", "utama", 1, 0, {}, [], "hajatan")]
	var kunci_pilih: Dictionary = {}
	for benih: int in range(100):
		var m2: HeadlineManager.Masukan = _masukan(5, _pustaka(u))
		m2.benih_dasar = benih
		m2.headline_jeda = {"a": 9, "b": 9}
		kunci_pilih[HeadlineManager.susun(m2).utama.id] = true
	check(kunci_pilih.keys() == ["c"], "dua dari tiga kandidat dalam jeda: 100 benih berbeda selalu memilih satu yang bebas, dapat %s" % [kunci_pilih.keys()])


func _test_manager_syarat_dan_distrik() -> void:
	_judul.call("HeadlineManager: syarat hari/flag/berita_utama, distrik, aktif dihormati (AC-6c)")
	var hari_min: Array[DataHeadline] = [_hl("u_tua", "utama", 1, 0, {"hari_min": 5}, [], "hajatan"), _hl("u_umum", "utama", 1, 0, {}, [], "hajatan")]
	for hari: int in range(1, 5):
		check(HeadlineManager.susun(_masukan(hari, _pustaka(hari_min))).utama.id == "u_umum", "hari %d: syarat hari_min 5 belum terpenuhi, hanya u_umum" % hari)
	var dapat_tua: bool = false
	for benih: int in range(60):
		var m: HeadlineManager.Masukan = _masukan(6, _pustaka(hari_min))
		m.benih_dasar = benih
		dapat_tua = dapat_tua or HeadlineManager.susun(m).utama.id == "u_tua"
	check(dapat_tua, "hari 6: u_tua ikut undian setelah hari_min terpenuhi")
	var hari_maks: Array[DataHeadline] = [_hl("u_awal", "utama", 1, 0, {"hari_maks": 3}, [], "hajatan"), _hl("u_umum", "utama", 1, 0, {}, [], "hajatan")]
	var pernah_awal_telat: bool = false
	for benih: int in range(60):
		var m: HeadlineManager.Masukan = _masukan(4, _pustaka(hari_maks))
		m.benih_dasar = benih
		pernah_awal_telat = pernah_awal_telat or HeadlineManager.susun(m).utama.id == "u_awal"
	check(not pernah_awal_telat, "hari 4: syarat hari_maks 3 sudah lewat, u_awal tidak pernah dipilih")
	var distrik: Array[DataHeadline] = [_hl("u_desa", "utama", 1, 0, {}, ["desa"], "panen_raya"), _hl("u_semua", "utama", 1, 0, {}, [], "hajatan")]
	var pernah_desa: bool = false
	for benih: int in range(60):
		var m: HeadlineManager.Masukan = _masukan(2, _pustaka(distrik))
		m.benih_dasar = benih
		pernah_desa = pernah_desa or HeadlineManager.susun(m).utama.id == "u_desa"
	check(not pernah_desa, "distrik perumahan: headline distrik desa tidak pernah dipilih; distrik kosong = semua distrik")
	var m_desa: HeadlineManager.Masukan = _masukan(2, _pustaka(distrik))
	m_desa.distrik = "desa"
	var dapat_desa: bool = false
	for benih: int in range(60):
		m_desa.benih_dasar = benih
		dapat_desa = dapat_desa or HeadlineManager.susun(m_desa).utama.id == "u_desa"
	check(dapat_desa, "distrik desa: headline desa ikut undian")
	var nonaktif: Array[DataHeadline] = [_hl("u_off", "utama", 1, 0, {}, [], "hajatan"), _hl("u_on", "utama", 1, 0, {}, [], "hajatan")]
	nonaktif[0].aktif = false
	var pernah_off: bool = false
	for benih: int in range(60):
		var m: HeadlineManager.Masukan = _masukan(2, _pustaka(nonaktif))
		m.benih_dasar = benih
		pernah_off = pernah_off or HeadlineManager.susun(m).utama.id == "u_off"
	check(not pernah_off, "headline aktif:false tidak pernah dipilih")
	var kosong: HeadlineManager.Halaman = HeadlineManager.susun(_masukan(2, _pustaka([])))
	check(kosong.utama == null and kosong.ringan == null and kosong.misi == null, "pool kosong: ketiga baris null, bukan crash")
	check(HeadlineManager.susun(HeadlineManager.Masukan.new()).utama == null, "masukan tanpa pustaka tidak crash")
	var syarat_flag: Array[DataHeadline] = [_hl("u_flag", "utama", 1, 0, {"flag": "f_1"}, [], "hajatan"), _hl("u_umum", "utama", 1, 0, {}, [], "hajatan")]
	var pernah_flag: bool = false
	for benih: int in range(60):
		var m: HeadlineManager.Masukan = _masukan(3, _pustaka(syarat_flag))
		m.benih_dasar = benih
		pernah_flag = pernah_flag or HeadlineManager.susun(m).utama.id == "u_flag"
	check(not pernah_flag, "syarat flag belum aktif: headline tidak dipilih")
	# syarat berita_utama pada misi: hanya muncul bila berita utama hari itu berefek sama.
	var misi_air: DataMisi = _ms("m_air", 5, {"berita_utama": "air_pasang"})
	var pustaka_efek: PemuatHeadline.Pustaka = _pustaka([_hl("u_hajat", "utama", 1, 0, {}, [], "hajatan")])
	check(HeadlineManager.susun(_masukan(3, pustaka_efek, [misi_air])).misi == null, "misi bersyarat berita_utama air_pasang tidak muncul saat berita utama hajatan")
	var pustaka_air: PemuatHeadline.Pustaka = _pustaka([_hl("u_air", "utama", 1, 0, {}, [], "air_pasang")])
	var h_air: HeadlineManager.Halaman = HeadlineManager.susun(_masukan(3, pustaka_air, [misi_air]))
	check(h_air.misi != null and h_air.misi.id == "m_air", "misi bersyarat berita_utama air_pasang muncul saat berita utama air_pasang")


func _test_manager_bobot() -> void:
	_judul.call("HeadlineManager: bobot memengaruhi peluang, distribusi atas 2000 benih (AC-6d)")
	# Oracle: peluang = bobot / jumlah bobot; toleransi 4 sigma binomial dihitung tes.
	var kasus: Array = [[1, 3], [1, 2, 5], [4, 1], [1, 1]]
	for bobot: Array in kasus:
		var u: Array[DataHeadline] = []
		var total: int = 0
		for i: int in range(bobot.size()):
			u.append(_hl("u_%d" % i, "utama", bobot[i], 0, {}, [], "hajatan"))
			total += bobot[i]
		var hitung: Dictionary = {}
		var pustaka: PemuatHeadline.Pustaka = _pustaka(u)
		for benih: int in range(2000):
			var m: HeadlineManager.Masukan = _masukan(3, pustaka)
			m.benih_dasar = benih * 7 + 13
			var id: String = HeadlineManager.susun(m).utama.id
			hitung[id] = int(hitung.get(id, 0)) + 1
		var semua_dalam_toleransi: bool = true
		var ringkas: Array[String] = []
		for i: int in range(bobot.size()):
			var p: float = float(bobot[i]) / float(total)
			var harapan: float = 2000.0 * p
			var toleransi: float = 4.0 * sqrt(2000.0 * p * (1.0 - p))
			var dapat: int = int(hitung.get("u_%d" % i, 0))
			ringkas.append("u_%d=%d (harapan %.0f +- %.0f)" % [i, dapat, harapan, toleransi])
			if absf(float(dapat) - harapan) > toleransi:
				semua_dalam_toleransi = false
		check(semua_dalam_toleransi, "bobot %s: distribusi 2000 benih sesuai peluang dalam 4 sigma: %s" % [bobot, ringkas])
	var nol_peluang: Array[DataHeadline] = [_hl("u_a", "utama", 1, 0, {}, [], "hajatan"), _hl("u_b", "utama", 9, 0, {}, [], "hajatan")]
	var terpilih_a: int = 0
	for benih: int in range(2000):
		var m: HeadlineManager.Masukan = _masukan(3, _pustaka(nol_peluang))
		m.benih_dasar = benih * 7 + 13
		terpilih_a += 1 if HeadlineManager.susun(m).utama.id == "u_a" else 0
	check(terpilih_a > 0 and terpilih_a < 400, "bobot 1 lawan 9: yang berbobot 1 tetap pernah terpilih (%d dari 2000) tapi jauh lebih jarang" % terpilih_a)


func _test_manager_semua_dalam_jeda() -> void:
	_judul.call("HeadlineManager: semua kandidat dalam jeda -> yang jedanya paling cepat berakhir, bukan galat (AC-6c)")
	var u: Array[DataHeadline] = [_hl("u_a", "utama", 1, 0, {}, [], "hajatan"), _hl("u_b", "utama", 1, 0, {}, [], "hajatan"), _hl("u_c", "utama", 1, 0, {}, [], "hajatan")]
	var pilihan: Dictionary = {}
	for benih: int in range(50):
		var m: HeadlineManager.Masukan = _masukan(5, _pustaka(u))
		m.benih_dasar = benih
		m.headline_jeda = {"u_a": 10, "u_b": 7, "u_c": 9}
		pilihan[HeadlineManager.susun(m).utama.id] = true
	check(pilihan.keys() == ["u_b"], "jeda sampai 10, 7, 9: selalu u_b (paling cepat berakhir), dapat %s" % [pilihan.keys()])
	var r: Array[DataHeadline] = [_hl("r_a", "ringan"), _hl("r_b", "ringan")]
	var m2: HeadlineManager.Masukan = _masukan(2, _pustaka(u, r))
	m2.headline_jeda = {"r_a": 6, "r_b": 6, "u_a": 3, "u_b": 3, "u_c": 3}
	var h: HeadlineManager.Halaman = HeadlineManager.susun(m2)
	check(h.utama != null and h.ringan != null, "semua utama dan ringan dalam jeda: tetap ada pilihan (bukan kosong, bukan crash)")
	var m3: HeadlineManager.Masukan = _masukan(2, _pustaka(u))
	m3.headline_jeda = {"u_a": 6, "u_b": 6, "u_c": 6}
	check(HeadlineManager.susun(m3).utama.id == "u_a", "seri jeda: urutan pustaka menentukan (u_a)")


func _test_manager_tidak_mengubah_masukan() -> void:
	_judul.call("HeadlineManager: masukan tidak diubah (AC-6g)")
	var m: HeadlineManager.Masukan = _masukan_nyata(9)
	m.flag = ["kucing_belum", "x"]
	m.headline_jeda = {"utama_hajatan": 12, "ringan_ayam_juara": 11}
	m.misi_jeda = {"p1_kucing": 8}
	var flag_sebelum: Array[String] = m.flag.duplicate()
	var hj_sebelum: Dictionary = m.headline_jeda.duplicate(true)
	var mj_sebelum: Dictionary = m.misi_jeda.duplicate(true)
	var snapshot: Array[String] = _snapshot_pustaka(m.pustaka)
	var jumlah_misi: int = m.misi.size()
	var misi_sebelum: String = "%s|%s|%s" % [m.misi[0].id, m.misi[0].jeda, m.misi[0].syarat]
	HeadlineManager.susun(m)
	HeadlineManager.susun(m)
	check(m.flag == flag_sebelum and m.headline_jeda == hj_sebelum and m.misi_jeda == mj_sebelum and m.hari == 9, "flag, jeda headline, jeda misi, dan hari tidak berubah")
	check(_snapshot_pustaka(m.pustaka) == snapshot and m.misi.size() == jumlah_misi and misi_sebelum == "%s|%s|%s" % [m.misi[0].id, m.misi[0].jeda, m.misi[0].syarat], "pustaka headline dan misi tidak berubah (urutan, bobot, jeda, syarat)")


func _snapshot_pustaka(p: PemuatHeadline.Pustaka) -> Array[String]:
	var hasil: Array[String] = []
	for h: DataHeadline in p.semua():
		hasil.append("%s|%s|%d|%d|%s|%s|%s" % [h.id, h.jenis, h.bobot, h.jeda, h.syarat, h.distrik, h.aktif])
	return hasil


func _test_catat_jeda() -> void:
	_judul.call("HeadlineManager.catat_jeda: jeda dihitung dari hari tampil (headline) dan hari diambil (misi) (S-4)")
	var h: HeadlineManager.Halaman = HeadlineManager.susun(_masukan_nyata(1))
	var diambil: HeadlineManager.JedaBaru = HeadlineManager.catat_jeda(h, "p1_kucing")
	var data_utama: DataHeadline = null
	var data_ringan: DataHeadline = null
	for d: DataHeadline in _pustaka_nyata().semua():
		data_utama = d if d.id == h.utama.id else data_utama
		data_ringan = d if d.id == h.ringan.id else data_ringan
	check(diambil.headline == {h.utama.id: 1 + data_utama.jeda, h.ringan.id: 1 + data_ringan.jeda}, "headline utama dan ringan dicatat hari 1 + jeda masing-masing; dapat %s" % [diambil.headline])
	check(diambil.misi == {"p1_kucing": 1 + 7}, "misi yang diambil dicatat hari 1 + jeda 7 = 8; dapat %s" % [diambil.misi])
	var dilewati: HeadlineManager.JedaBaru = HeadlineManager.catat_jeda(h, "")
	check(dilewati.misi.is_empty() and dilewati.headline == diambil.headline, "misi yang dilewati tidak memicu jeda; jeda headline sama")
	var lain: HeadlineManager.JedaBaru = HeadlineManager.catat_jeda(h, "misi_lain")
	check(lain.misi.is_empty(), "id misi yang tidak tampil hari itu tidak dicatat")
	var tanpa_misi: HeadlineManager.Halaman = HeadlineManager.susun(_masukan(5, _pustaka_nyata(), []))
	check(HeadlineManager.catat_jeda(tanpa_misi, "").misi.is_empty() and HeadlineManager.catat_jeda(tanpa_misi, "p1_kucing").misi.is_empty(), "tanpa baris misi tidak ada jeda misi")
	var m: HeadlineManager.Masukan = _masukan_nyata(3)
	m.flag = ["kucing_belum"]
	var lanjutan: HeadlineManager.JedaBaru = HeadlineManager.catat_jeda(HeadlineManager.susun(m), "")
	check(lanjutan.headline.get("lanjutan_kucing_belum") == 3 + 30, "headline lanjutan yang tampil dicatat hari + jeda (3 + 30)")
