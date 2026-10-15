class_name TesRute
extends RefCounted
## Tes logika murni rute Fase 3 run fase3a-rute: segmen bertipe dan validasi (`SegmenRute`, AC-1 sampai AC-3), pembaca berkas
## (`PemuatRute`, AC-2), penyusun rute berseed (`RouteBuilder`, AC-5 sampai AC-8), zona sasaran dari data rute (`ZonaSasaran`, AC-9),
## mode bantu di atas zona itu (AC-10), dan aturan penutup pemain (`PenutupPemain`, AC-15).
##
## Oracle independen (pelajaran QA-008 dan QA-001): harapan ditulis sebagai literal di berkas ini (panjang dan pelanggan_boleh tiap
## segmen, koordinat zona, hasil tertutup), dan data berkas nyata diperiksa ulang dari JSON mentah oleh kode di sini, bukan oleh
## `SegmenRute`. Mutan: data rusak yang HARUS ditolak dan Rute yang dirusak yang HARUS ditolak `periksa_rute`.
##
## Dipanggil dari `tests/run_tests.gd` (`TesRute.new(check, judul).jalankan()`). Tanpa node; waktu hanya untuk mengukur AC-8.

const FOLDER: String = "res://assets/data/routes/perumahan"
## Lebar viewport game untuk tes mode bantu.
const LEBAR: float = 780.0
## Jeda lepas animasi lempar: frame 2 dari 4 di 12 fps, detik.
const JEDA_LEPAS: float = 2.0 / 12.0

## Harapan literal berkas nyata (ditulis tangan di sini, bukan dibaca dari data).
const ID_SEGMEN: Array[String] = ["per_buka_01", "per_buka_02", "per_tengah_01", "per_tengah_02", "per_tengah_03", "per_tengah_04", "per_tengah_05", "per_tutup_01", "per_tutup_02"]
const ID_PEMBUKA: Array[String] = ["per_buka_01", "per_buka_02"]
const ID_TENGAH: Array[String] = ["per_tengah_01", "per_tengah_02", "per_tengah_03", "per_tengah_04", "per_tengah_05"]
const ID_PENUTUP: Array[String] = ["per_tutup_01", "per_tutup_02"]
const ID_PADAT: Array[String] = ["per_tengah_04", "per_tengah_05"]
const PANJANG: Dictionary = {
	"per_buka_01": 28, "per_buka_02": 32,
	"per_tengah_01": 36, "per_tengah_02": 32, "per_tengah_03": 40, "per_tengah_04": 36, "per_tengah_05": 36,
	"per_tutup_01": 24, "per_tutup_02": 28,
}
## `pos` rumah seberang yang `pelanggan_boleh: true` per segmen.
const BOLEH: Dictionary = {
	"per_buka_01": [6, 10, 18], "per_buka_02": [6, 10, 22],
	"per_tengah_01": [6, 14, 18, 26, 30], "per_tengah_02": [6, 10, 18, 22, 26], "per_tengah_03": [6, 14, 18, 26, 30, 34],
	"per_tengah_04": [6, 10, 22, 26, 30], "per_tengah_05": [6, 14, 18, 26, 30],
	"per_tutup_01": [6, 14], "per_tutup_02": [6, 10, 18],
}

var _cek: Callable
var _judul: Callable


func _init(cek: Callable, judul: Callable) -> void:
	_cek = cek
	_judul = judul


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_test_segmen_sah_dan_mutan()
	_test_batas_nilai()
	_test_teks_json()
	_test_kumpulan()
	_test_berkas_nyata()
	_test_berkas_nyata_oracle_mentah()
	_test_builder_deterministik()
	_test_builder_struktur()
	_test_builder_pelanggan()
	_test_builder_sapuan()
	_test_builder_pustaka_rusak()
	_test_periksa_rute_mutan()
	_test_rng_global_tidak_disentuh()
	_test_koran_awal()
	_test_waktu_bangun()
	_test_data_ikut_paket()
	_test_zona_rumah_literal()
	_test_zona_rute_dan_penilaian()
	_test_bantu_di_zona_rute()
	_test_penutup_literal()
	_test_penutup_rumah_rute()


# --- Pembantu ---

## Segmen sah minimal untuk dirusak mutan (panjang 32, dua rintangan, satu titik misi).
func _dasar() -> Dictionary:
	return {
		"id": "per_uji_01",
		"distrik": "perumahan",
		"panjang": 32,
		"tag": {"tingkat": "sedang", "sisi_pelanggan": "seberang", "posisi": "tengah"},
		"rumah": [
			{"pos": 2, "sisi": "seberang", "jenis": "limasan", "pelanggan_boleh": false},
			{"pos": 6, "sisi": "seberang", "jenis": "pelana", "pelanggan_boleh": true},
			{"pos": 10, "sisi": "seberang", "jenis": "sayap", "pelanggan_boleh": true},
			{"pos": 8, "sisi": "dekat", "jenis": "dekat_limasan", "pelanggan_boleh": false},
		],
		"objek": [
			{"jenis": "anjing_penjaga", "pos": 14, "jalur": "seberang", "tanda_ubin": 9.0},
			{"jenis": "mobil_garasi", "pos": 22, "jalur": "dekat", "tanda_ubin": 9.0},
		],
		"titik_misi": [{"nama": "atap", "pos": 6, "sisi": "seberang"}],
	}


## Terapkan mutan bernama `kode` ke `d` (satu aturan dilanggar tiap kode).
func _mutasi(d: Dictionary, kode: String) -> void:
	var rumah: Array = d["rumah"]
	var objek: Array = d["objek"]
	var titik: Array = d["titik_misi"]
	var tag: Dictionary = d["tag"]
	match kode:
		"tanpa_id": d.erase("id")
		"tanpa_distrik": d.erase("distrik")
		"tanpa_panjang": d.erase("panjang")
		"tanpa_tag": d.erase("tag")
		"tanpa_rumah": d.erase("rumah")
		"tanpa_objek": d.erase("objek")
		"tanpa_titik_misi": d.erase("titik_misi")
		"id_huruf_besar": d["id"] = "Per_Uji"
		"panjang_23": d["panjang"] = 23
		"panjang_41": d["panjang"] = 41
		"panjang_pecahan": d["panjang"] = 30.5
		"tingkat_salah": tag["tingkat"] = "ramai"
		"posisi_salah": tag["posisi"] = "tengah_dua"
		"sisi_pelanggan_salah": tag["sisi_pelanggan"] = "kiri"
		"sisi_pelanggan_dekat": tag["sisi_pelanggan"] = "dekat"
		"pembuka_padat":
			tag["posisi"] = "pembuka"
			tag["tingkat"] = "padat"
		"penutup_sedang": tag["posisi"] = "penutup"
		"field_asing": d["warna"] = "merah"
		"rumah_sisi_kiri": (rumah[1] as Dictionary)["sisi"] = "kiri"
		"rumah_sisi_kanan": (rumah[3] as Dictionary)["sisi"] = "kanan"
		"rumah_tanpa_pos": (rumah[1] as Dictionary).erase("pos")
		"rumah_pos_1": (rumah[0] as Dictionary)["pos"] = 1
		"rumah_pos_akhir_min_1": (rumah[2] as Dictionary)["pos"] = 31
		"rumah_pos_di_luar": (rumah[2] as Dictionary)["pos"] = 33
		"rumah_pos_pecahan": (rumah[1] as Dictionary)["pos"] = 6.5
		"rumah_jenis_salah": (rumah[1] as Dictionary)["jenis"] = "istana"
		"rumah_jenis_dekat_di_seberang": (rumah[1] as Dictionary)["jenis"] = "dekat_limasan"
		"rumah_jenis_seberang_di_dekat": (rumah[3] as Dictionary)["jenis"] = "limasan"
		"rumah_pelanggan_dekat": (rumah[3] as Dictionary)["pelanggan_boleh"] = true
		"rumah_pelanggan_bukan_bool": (rumah[1] as Dictionary)["pelanggan_boleh"] = "ya"
		"rumah_tanpa_pelanggan_boleh": (rumah[1] as Dictionary).erase("pelanggan_boleh")
		"rumah_pos_sama_sisi_beda": (rumah[3] as Dictionary)["pos"] = 6
		"rumah_petak_sempit": rumah.append({"pos": 12, "sisi": "seberang", "jenis": "limasan", "pelanggan_boleh": false})
		"rumah_field_asing": (rumah[1] as Dictionary)["atap"] = "genteng"
		"objek_jalur_tengah": (objek[0] as Dictionary)["jalur"] = "tengah"
		"objek_jalur_kiri": (objek[0] as Dictionary)["jalur"] = "kiri"
		"objek_jenis_salah": (objek[0] as Dictionary)["jenis"] = "kucing"
		"objek_pos_2": (objek[0] as Dictionary)["pos"] = 2
		"objek_pos_akhir_min_2": (objek[1] as Dictionary)["pos"] = 30
		"objek_rapat_5": objek.append({"jenis": "anjing_penjaga", "pos": 19, "jalur": "dekat", "tanda_ubin": 9.0})
		"objek_tanda_pendek": (objek[0] as Dictionary)["tanda_ubin"] = 8.9
		"objek_tanpa_tanda": (objek[0] as Dictionary).erase("tanda_ubin")
		"titik_tanpa_rumah": (titik[0] as Dictionary)["sisi"] = "dekat"
		"titik_dekat_rintangan":
			(titik[0] as Dictionary)["pos"] = 10
		"titik_sisi_kiri": (titik[0] as Dictionary)["sisi"] = "kiri"
		# Mutan batas yang HARUS diterima (kode berawalan `ok_`).
		"ok_panjang_24":
			d["panjang"] = 24
			objek.clear()
		"ok_panjang_40": d["panjang"] = 40
		"ok_rumah_pos_akhir_min_2": rumah.append({"pos": 30, "sisi": "seberang", "jenis": "limasan", "pelanggan_boleh": false})
		"ok_objek_pos_3":
			(objek[0] as Dictionary)["pos"] = 3
			titik.clear()
		"ok_objek_pos_akhir_min_3": (objek[1] as Dictionary)["pos"] = 29
		"ok_objek_rentang_6": (objek[1] as Dictionary)["pos"] = 20
		"ok_tanda_9_bulat": (objek[0] as Dictionary)["tanda_ubin"] = 9
		"ok_petak_4": rumah.append({"pos": 14, "sisi": "seberang", "jenis": "limasan", "pelanggan_boleh": true})
		"ok_pembuka_tenang":
			tag["posisi"] = "pembuka"
			tag["tingkat"] = "tenang"
			objek.clear()
			titik.clear()
		_: push_error("kode mutan tidak dikenal: %s" % kode)


func _galat_berisi(galat: Array[String], potongan: String) -> bool:
	for g: String in galat:
		if g.contains(potongan):
			return true
	return false


## Rute sah dari seed untuk tes yang membutuhkan data nyata. Gagal = null.
func _rute(benih: int, pustaka: Array[SegmenRute]) -> RouteBuilder.Rute:
	return RouteBuilder.bangun(benih, pustaka).rute


func _pustaka() -> Array[SegmenRute]:
	return PemuatRute.muat_folder(FOLDER).segmen


## Awal tiap segmen dari urutan id (literal `PANJANG`), ubin: oracle independen posisi maju.
func _awal_oracle(urutan: Array[String]) -> Dictionary:
	var awal: Dictionary = {}
	var jumlah: int = 0
	for id: String in urutan:
		awal[id] = jumlah
		jumlah += int(PANJANG[id])
	awal["_total"] = jumlah
	return awal


func _id_urutan(rute: RouteBuilder.Rute) -> Array[String]:
	var hasil: Array[String] = []
	for segmen: SegmenRute in rute.segmen:
		hasil.append(segmen.id)
	return hasil


func _id_pelanggan(rute: RouteBuilder.Rute) -> Array[String]:
	var hasil: Array[String] = []
	for rumah: RouteBuilder.RumahRute in rute.pelanggan:
		hasil.append(rumah.id)
	return hasil


# --- AC-1 sampai AC-3: segmen bertipe dan validasi ---

func _test_segmen_sah_dan_mutan() -> void:
	_judul.call("Segmen: data sah diterima, tiap jenis data rusak ditolak (AC-2, AC-3)")
	var sah: SegmenRute.Hasil = SegmenRute.parse(_dasar())
	check(sah.sah() and sah.galat.is_empty() and sah.segmen != null, "segmen dasar sah: tanpa galat (%s)" % "; ".join(sah.galat))
	if sah.segmen != null:
		var s: SegmenRute = sah.segmen
		check(s.id == "per_uji_01" and s.panjang == 32 and s.rumah.size() == 4 and s.objek.size() == 2 and s.titik_misi.size() == 1, "segmen dasar: id, panjang, jumlah rumah (4), objek (2), titik misi (1) terbaca")
		check(s.tingkat == SegmenRute.Tingkat.SEDANG and s.posisi == SegmenRute.Posisi.TENGAH and s.sisi_pelanggan == "seberang", "segmen dasar: tag terbaca")
		check(s.rumah[1].pos == 6 and s.rumah[1].sisi == LoperAnim.Sisi.SEBERANG and s.rumah[1].jenis == "pelana" and s.rumah[1].pelanggan_boleh, "rumah ke-2: pos 6, seberang, pelana, boleh")
		check(s.rumah[3].sisi == LoperAnim.Sisi.DEKAT and not s.rumah[3].pelanggan_boleh, "rumah dekat terbaca sebagai DEKAT dan bukan pelanggan")
		check(s.objek[1].jalur == "dekat" and is_equal_approx(s.objek[1].tanda_ubin, 9.0) and s.objek[1].jenis == "mobil_garasi", "objek ke-2: mobil_garasi di jalur dekat, tanda 9")
	var tolak: Array[Array] = [
		["tanpa_id", "field wajib 'id'"], ["tanpa_distrik", "field wajib 'distrik'"], ["tanpa_panjang", "field wajib 'panjang'"],
		["tanpa_tag", "field wajib 'tag'"], ["tanpa_rumah", "field wajib 'rumah'"], ["tanpa_objek", "field wajib 'objek'"],
		["tanpa_titik_misi", "field wajib 'titik_misi'"], ["id_huruf_besar", "huruf kecil"],
		["panjang_23", "di luar 24 sampai 40"], ["panjang_41", "di luar 24 sampai 40"], ["panjang_pecahan", "bilangan bulat"],
		["tingkat_salah", "tingkat 'ramai'"], ["posisi_salah", "posisi 'tengah_dua'"],
		["sisi_pelanggan_salah", "sisi_pelanggan 'kiri'"], ["sisi_pelanggan_dekat", "hanya punya pelanggan di sisi seberang"],
		["pembuka_padat", "harus bertingkat tenang"], ["penutup_sedang", "harus bertingkat tenang"], ["field_asing", "field 'warna' tidak dikenal"],
		["rumah_sisi_kiri", "bukan seberang atau dekat"], ["rumah_sisi_kanan", "bukan seberang atau dekat"], ["rumah_tanpa_pos", "field wajib 'pos'"],
		["rumah_pos_1", "di tepi segmen"], ["rumah_pos_akhir_min_1", "di tepi segmen"], ["rumah_pos_di_luar", "di tepi segmen"],
		["rumah_pos_pecahan", "bilangan bulat"], ["rumah_jenis_salah", "tidak dikenal untuk sisi"],
		["rumah_jenis_dekat_di_seberang", "tidak dikenal untuk sisi"], ["rumah_jenis_seberang_di_dekat", "tidak dikenal untuk sisi"],
		["rumah_pelanggan_dekat", "tidak boleh jadi pelanggan"], ["rumah_pelanggan_bukan_bool", "true atau false"],
		["rumah_tanpa_pelanggan_boleh", "field wajib 'pelanggan_boleh'"], ["rumah_pos_sama_sisi_beda", "dipakai dua rumah"],
		["rumah_petak_sempit", "terlalu dekat rumah"], ["rumah_field_asing", "field 'atap' tidak dikenal"],
		["objek_jalur_tengah", "jalur utama harus selalu bersih"], ["objek_jalur_kiri", "bukan seberang, tengah, atau dekat"],
		["objek_jenis_salah", "jenis 'kucing' tidak dikenal"], ["objek_pos_2", "lebih dekat dari 3 ubin ke tepi"],
		["objek_pos_akhir_min_2", "lebih dekat dari 3 ubin ke tepi"], ["objek_rapat_5", "maksimal satu"],
		["objek_tanda_pendek", "kurang dari 9.0"], ["objek_tanpa_tanda", "field wajib 'tanda_ubin'"],
		["titik_tanpa_rumah", "tidak ada rumah sisi dekat"], ["titik_dekat_rintangan", "bersama rintangan"],
		["titik_sisi_kiri", "bukan seberang atau dekat"],
	]
	for kasus: Array in tolak:
		var kode: String = kasus[0]
		var potongan: String = kasus[1]
		var d: Dictionary = _dasar()
		_mutasi(d, kode)
		var hasil: SegmenRute.Hasil = SegmenRute.parse(d)
		check(not hasil.sah() and hasil.segmen == null and _galat_berisi(hasil.galat, potongan), "mutan '%s' ditolak dengan galat memuat '%s' (galat: %s)" % [kode, potongan, "; ".join(hasil.galat)])
	var ganda: Dictionary = _dasar()
	_mutasi(ganda, "objek_jalur_tengah")
	_mutasi(ganda, "rumah_pos_1")
	_mutasi(ganda, "tanpa_distrik")
	var banyak: SegmenRute.Hasil = SegmenRute.parse(ganda)
	check(banyak.galat.size() >= 3 and banyak.segmen == null, "tiga pelanggaran sekaligus: semua dilaporkan (%d galat), segmen null" % banyak.galat.size())


func _test_batas_nilai() -> void:
	_judul.call("Segmen: nilai tepat di batas diterima (AC-2)")
	for kode: String in ["ok_panjang_24", "ok_panjang_40", "ok_rumah_pos_akhir_min_2", "ok_objek_pos_3", "ok_objek_pos_akhir_min_3", "ok_objek_rentang_6", "ok_tanda_9_bulat", "ok_petak_4", "ok_pembuka_tenang"]:
		var d: Dictionary = _dasar()
		_mutasi(d, kode)
		var hasil: SegmenRute.Hasil = SegmenRute.parse(d)
		check(hasil.sah(), "batas '%s' diterima (galat: %s)" % [kode, "; ".join(hasil.galat)])
	check(SegmenRute.sisi_dari_nama("seberang") == LoperAnim.Sisi.SEBERANG and SegmenRute.sisi_dari_nama("dekat") == LoperAnim.Sisi.DEKAT, "nama sisi seberang dan dekat dipetakan ke enum")
	check(SegmenRute.sisi_dari_nama("kiri") == LoperAnim.Sisi.TIDAK_ADA and SegmenRute.sisi_dari_nama("") == LoperAnim.Sisi.TIDAK_ADA, "nama sisi lain (kiri, kosong) = TIDAK_ADA")


func _test_teks_json() -> void:
	_judul.call("Pemuat: teks JSON rusak dan bukan objek ditolak, sumber ikut di galat (AC-2)")
	var rusak: SegmenRute.Hasil = PemuatRute.parse_teks("{\"id\": \"per_x\",", "per_x.json")
	check(not rusak.sah() and rusak.segmen == null and _galat_berisi(rusak.galat, "per_x.json: JSON rusak"), "JSON terpotong ditolak dengan nama berkas (%s)" % "; ".join(rusak.galat))
	var daftar: SegmenRute.Hasil = PemuatRute.parse_teks("[1, 2]", "per_y.json")
	check(not daftar.sah() and _galat_berisi(daftar.galat, "per_y.json: isi berkas harus satu objek"), "JSON array ditolak")
	var kosong: SegmenRute.Hasil = PemuatRute.parse_teks("{}", "per_z.json")
	check(not kosong.sah() and _galat_berisi(kosong.galat, "per_z.json: segmen: field wajib 'id'"), "objek kosong ditolak, galat berawalan nama berkas")
	var baik: SegmenRute.Hasil = PemuatRute.parse_teks(JSON.stringify(_dasar()), "per_uji_01.json")
	check(baik.sah() and baik.segmen.rumah[1].pos == 6, "segmen dasar lewat teks JSON (angka kembali sebagai float) diterima")
	var tak_ada: Array[String] = []
	check(PemuatRute.baca_teks("res://assets/data/routes/perumahan/tidak_ada.json", tak_ada).is_empty() and tak_ada.size() == 1, "berkas yang tidak ada = teks kosong dan satu galat")
	check(PemuatRute.daftar_berkas("res://folder_yang_tidak_ada").is_empty(), "folder yang tidak ada = daftar kosong")


func _test_kumpulan() -> void:
	_judul.call("Pemuat: aturan antar segmen (id ganda, nama berkas, jumlah posisi) (AC-1, AC-2)")
	var daftar: Array[SegmenRute] = []
	for i: int in range(2):
		var d: Dictionary = _dasar()
		d["id"] = "per_buka_%02d" % (i + 1)
		_mutasi(d, "ok_pembuka_tenang")
		_tambah(daftar, d)
	for i: int in range(2):
		var d: Dictionary = _dasar()
		d["id"] = "per_tutup_%02d" % (i + 1)
		(d["tag"] as Dictionary)["posisi"] = "penutup"
		(d["tag"] as Dictionary)["tingkat"] = "tenang"
		d["objek"] = []
		d["titik_misi"] = []
		_tambah(daftar, d)
	for i: int in range(5):
		var d: Dictionary = _dasar()
		d["id"] = "per_tengah_%02d" % (i + 1)
		_tambah(daftar, d)
	var nama: Array[String] = []
	for segmen: SegmenRute in daftar:
		nama.append(segmen.id)
	check(PemuatRute.periksa_kumpulan(daftar, nama).is_empty(), "kumpulan 2 pembuka, 5 tengah, 2 penutup, nama berkas sama dengan id: tanpa galat")
	var ganda: Array[SegmenRute] = _salin(daftar, [])
	ganda.append(daftar[0])
	check(_galat_berisi(PemuatRute.periksa_kumpulan(ganda), "id segmen 'per_buka_01' ganda"), "id ganda ditolak")
	var salah_nama: Array[String] = nama.duplicate()
	salah_nama[2] = "per_lain"
	check(_galat_berisi(PemuatRute.periksa_kumpulan(daftar, salah_nama), "id harus sama dengan nama berkas"), "id berbeda dari nama berkas ditolak")
	check(_galat_berisi(PemuatRute.periksa_kumpulan(_salin(daftar, [0])), "segmen pembuka kurang dari 2 (ada 1)"), "kurang dari 2 pembuka ditolak")
	check(_galat_berisi(PemuatRute.periksa_kumpulan(_salin(daftar, [2])), "segmen penutup kurang dari 2 (ada 1)"), "kurang dari 2 penutup ditolak")
	check(_galat_berisi(PemuatRute.periksa_kumpulan(_salin(daftar, [4])), "segmen tengah kurang dari 5 (ada 4)"), "kurang dari 5 tengah ditolak")


## Parse `d` dan tambahkan ke `daftar` bila sah (gagal parse dicatat, tidak membuat tes lain berhenti).
func _tambah(daftar: Array[SegmenRute], d: Dictionary) -> void:
	var hasil: SegmenRute.Hasil = SegmenRute.parse(d)
	check(hasil.sah(), "segmen pembantu %s sah" % d.get("id", "?"))
	if hasil.segmen != null:
		daftar.append(hasil.segmen)


## Salinan `daftar` tanpa indeks yang tercantum di `buang`.
func _salin(daftar: Array[SegmenRute], buang: Array[int]) -> Array[SegmenRute]:
	var hasil: Array[SegmenRute] = []
	for i: int in range(daftar.size()):
		if not buang.has(i):
			hasil.append(daftar[i])
	return hasil


# --- AC-3: berkas nyata ---

func _test_berkas_nyata() -> void:
	_judul.call("Berkas nyata: 9 segmen per_*.json lolos validasi (AC-1, AC-3)")
	var kumpulan: PemuatRute.Kumpulan = PemuatRute.muat_folder(FOLDER)
	check(kumpulan.sah(), "semua berkas nyata lolos pemuat tanpa galat: %s" % "; ".join(kumpulan.galat))
	check(kumpulan.segmen.size() == 9, "ada 9 segmen (dapat %d)" % kumpulan.segmen.size())
	var berkas: Array[String] = PemuatRute.daftar_berkas(FOLDER)
	var nama_literal: Array[String] = []
	for id: String in ID_SEGMEN:
		nama_literal.append(id + ".json")
	check(berkas == nama_literal, "daftar berkas persis 9 nama yang diharapkan, terurut: %s" % str(berkas))
	var pembuka: int = 0
	var penutup: int = 0
	var tengah: int = 0
	for segmen: SegmenRute in kumpulan.segmen:
		check(PANJANG.has(segmen.id) and segmen.panjang == int(PANJANG[segmen.id]), "%s: panjang %d sama dengan harapan literal" % [segmen.id, segmen.panjang])
		check(segmen.panjang >= 24 and segmen.panjang <= 40, "%s: panjang 24 sampai 40 (AC-1)" % segmen.id)
		check(segmen.distrik == "perumahan" and segmen.sisi_pelanggan == "seberang", "%s: distrik perumahan, pelanggan di seberang" % segmen.id)
		match segmen.posisi:
			SegmenRute.Posisi.PEMBUKA:
				pembuka += 1
				check(ID_PEMBUKA.has(segmen.id) and segmen.tingkat == SegmenRute.Tingkat.TENANG and segmen.objek.is_empty(), "%s: pembuka, tenang, tanpa rintangan" % segmen.id)
			SegmenRute.Posisi.PENUTUP:
				penutup += 1
				check(ID_PENUTUP.has(segmen.id) and segmen.tingkat == SegmenRute.Tingkat.TENANG and segmen.objek.is_empty(), "%s: penutup, tenang, tanpa rintangan" % segmen.id)
			_:
				tengah += 1
				check(ID_TENGAH.has(segmen.id), "%s: tengah" % segmen.id)
	check(pembuka == 2 and penutup == 2 and tengah == 5, "2 pembuka, 2 penutup, 5 tengah (AC-1): %d/%d/%d" % [pembuka, penutup, tengah])
	var padat: Array[String] = []
	for segmen: SegmenRute in kumpulan.segmen:
		if segmen.tingkat == SegmenRute.Tingkat.PADAT:
			padat.append(segmen.id)
	check(padat == ID_PADAT, "segmen padat persis per_tengah_04 dan per_tengah_05: %s" % str(padat))


## Pemeriksaan ulang dari JSON mentah (tanpa `SegmenRute`): oracle independen untuk aturan adil AC-3.
func _test_berkas_nyata_oracle_mentah() -> void:
	_judul.call("Berkas nyata: aturan adil dari JSON mentah, oracle independen (AC-3, ROUTE_DESIGN 4)")
	var total_rumah: int = 0
	var total_objek: int = 0
	var total_boleh: int = 0
	for id: String in ID_SEGMEN:
		var teks: String = FileAccess.get_file_as_string("%s/%s.json" % [FOLDER, id])
		var data: Variant = JSON.parse_string(teks)
		check(typeof(data) == TYPE_DICTIONARY, "%s: JSON mentah terbaca sebagai objek" % id)
		if typeof(data) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = data
		var panjang: int = int(d["panjang"])
		check(d["id"] == id and panjang == int(PANJANG[id]), "%s: id sama dengan nama berkas dan panjang cocok" % id)
		var pos_boleh: Array[int] = []
		var pos_rumah: Dictionary = {}
		var posisi_seberang: Array[int] = []
		var posisi_dekat: Array[int] = []
		for r: Variant in d["rumah"]:
			var rumah: Dictionary = r
			var pos: int = int(rumah["pos"])
			total_rumah += 1
			check(pos >= 2 and pos <= panjang - 2, "%s: rumah pos %d di dalam tepi 2 ubin" % [id, pos])
			check(not pos_rumah.has(pos), "%s: tidak ada dua rumah di pos %d" % [id, pos])
			pos_rumah[pos] = rumah["sisi"]
			check(rumah["sisi"] == "seberang" or rumah["sisi"] == "dekat", "%s: sisi rumah seberang atau dekat (pos %d)" % [id, pos])
			if rumah["sisi"] == "seberang":
				posisi_seberang.append(pos)
			else:
				posisi_dekat.append(pos)
			if rumah["pelanggan_boleh"]:
				total_boleh += 1
				pos_boleh.append(pos)
				check(rumah["sisi"] == "seberang", "%s: pelanggan hanya di sisi seberang (pos %d, GDD 9.1)" % [id, pos])
		pos_boleh.sort()
		var harapan: Array[int] = []
		for p: Variant in BOLEH[id]:
			harapan.append(int(p))
		check(pos_boleh == harapan, "%s: pos pelanggan_boleh = harapan literal %s (dapat %s)" % [id, str(harapan), str(pos_boleh)])
		for daftar: Array[int] in [posisi_seberang, posisi_dekat]:
			daftar.sort()
			for i: int in range(1, daftar.size()):
				check(daftar[i] - daftar[i - 1] >= 4, "%s: rumah sesisi berjarak paling sedikit 4 ubin (%d dan %d)" % [id, daftar[i - 1], daftar[i]])
		var pos_objek: Array[int] = []
		for o: Variant in d["objek"]:
			var objek: Dictionary = o
			var pos: int = int(objek["pos"])
			total_objek += 1
			pos_objek.append(pos)
			check(objek["jalur"] == "seberang" or objek["jalur"] == "dekat", "%s: rintangan pos %d tidak di jalur tengah (jalur utama bersih)" % [id, pos])
			check(pos >= 3 and pos <= panjang - 3, "%s: rintangan pos %d tidak di 2 ubin tepi (dan %d dari sambungan)" % [id, pos, 3])
			check(float(objek["tanda_ubin"]) >= 9.0, "%s: tanda rintangan pos %d paling sedikit 9 ubin" % [id, pos])
		pos_objek.sort()
		for i: int in range(1, pos_objek.size()):
			check(pos_objek[i] - pos_objek[i - 1] >= 6, "%s: dua rintangan berjarak paling sedikit 6 ubin (%d dan %d)" % [id, pos_objek[i - 1], pos_objek[i]])
		for t: Variant in d["titik_misi"]:
			var titik: Dictionary = t
			var pos: int = int(titik["pos"])
			check(pos_rumah.has(pos) and pos_rumah[pos] == titik["sisi"], "%s: titik misi '%s' pos %d berdiri di rumah sisi yang sama" % [id, titik["nama"], pos])
	check(total_rumah == 109, "total rumah di 9 segmen = 109 (73 seberang: 7+8+9+8+10+9+9+6+7, 36 dekat: 3+4+5+4+6+5+4+2+3): %d" % total_rumah)
	check(total_objek == 11, "total rintangan di 9 segmen = 11 (1 + 2 + 2 + 3 + 3): %d" % total_objek)
	check(total_boleh == 3 + 3 + 5 + 5 + 6 + 5 + 5 + 2 + 3, "total rumah pelanggan_boleh = 37: %d" % total_boleh)


# --- AC-5 sampai AC-8: RouteBuilder ---

func _test_builder_deterministik() -> void:
	_judul.call("RouteBuilder: seed sama = rute sama, seed beda = rute beda (AC-5)")
	var pustaka: Array[SegmenRute] = _pustaka()
	var benih: Array[int] = [1, 2, 3, 20261016, 987654321, -5, 0]
	for b: int in benih:
		var a: RouteBuilder.Rute = _rute(b, pustaka)
		var c: RouteBuilder.Rute = _rute(b, pustaka)
		check(a != null and c != null and _id_urutan(a) == _id_urutan(c) and _id_pelanggan(a) == _id_pelanggan(c), "seed %d dibangun dua kali: urutan segmen dan pelanggan identik" % b)
	# Urutan berkas di pustaka tidak boleh memengaruhi hasil (diurutkan menurut id di dalam).
	var terbalik: Array[SegmenRute] = []
	for i: int in range(pustaka.size() - 1, -1, -1):
		terbalik.append(pustaka[i])
	var normal: RouteBuilder.Rute = _rute(77, pustaka)
	var dibalik: RouteBuilder.Rute = _rute(77, terbalik)
	check(normal != null and dibalik != null and _id_urutan(normal) == _id_urutan(dibalik) and _id_pelanggan(normal) == _id_pelanggan(dibalik), "urutan pustaka dibalik: rute seed 77 tetap sama")
	var urutan_berbeda: Dictionary = {}
	var pelanggan_berbeda: Dictionary = {}
	for i: int in range(20):
		var rute: RouteBuilder.Rute = _rute(100 + i, pustaka)
		check(rute != null, "seed %d dibangun" % (100 + i))
		if rute == null:
			continue
		urutan_berbeda[",".join(_id_urutan(rute))] = true
		pelanggan_berbeda[",".join(_id_pelanggan(rute))] = true
	check(urutan_berbeda.size() >= 10, "20 seed menghasilkan paling sedikit 10 urutan segmen berbeda (dapat %d)" % urutan_berbeda.size())
	check(urutan_berbeda.size() > 1 and pelanggan_berbeda.size() >= 15, "20 seed: tidak semua rute sama, dan paling sedikit 15 pilihan pelanggan berbeda (dapat %d)" % pelanggan_berbeda.size())


func _test_builder_struktur() -> void:
	_judul.call("RouteBuilder: 7 segmen berbeda, pembuka-tengah-penutup, tanpa dua padat berurutan, panjang (AC-6)")
	var pustaka: Array[SegmenRute] = _pustaka()
	for i: int in range(20):
		var benih: int = 500 + i * 37
		var rute: RouteBuilder.Rute = _rute(benih, pustaka)
		if rute == null:
			check(false, "seed %d dibangun" % benih)
			continue
		var urutan: Array[String] = _id_urutan(rute)
		var unik: Dictionary = {}
		for id: String in urutan:
			unik[id] = true
		check(urutan.size() == 7 and unik.size() == 7, "seed %d: tepat 7 segmen berbeda (%s)" % [benih, str(urutan)])
		check(ID_PEMBUKA.has(urutan[0]) and ID_PENUTUP.has(urutan[6]), "seed %d: segmen pertama pembuka dan terakhir penutup" % benih)
		var tengah_ok: bool = true
		for j: int in range(1, 6):
			if not ID_TENGAH.has(urutan[j]):
				tengah_ok = false
		check(tengah_ok, "seed %d: segmen ke-2 sampai ke-6 semuanya tengah" % benih)
		var padat_berurutan: bool = false
		for j: int in range(1, 7):
			if ID_PADAT.has(urutan[j]) and ID_PADAT.has(urutan[j - 1]):
				padat_berurutan = true
		check(not padat_berurutan, "seed %d: tidak ada dua segmen padat berurutan" % benih)
		var awal: Dictionary = _awal_oracle(urutan)
		check(is_equal_approx(rute.panjang_ubin, float(awal["_total"])) and rute.panjang_ubin >= 200.0 and rute.panjang_ubin <= 300.0, "seed %d: panjang rute %.0f sama dengan jumlah literal dan di 200 sampai 300" % [benih, rute.panjang_ubin])
		var awal_ok: bool = rute.awal_segmen.size() == 7
		for j: int in range(mini(7, rute.awal_segmen.size())):
			if not is_equal_approx(rute.awal_segmen[j], float(awal[urutan[j]])):
				awal_ok = false
		check(awal_ok, "seed %d: awal tiap segmen = jumlah panjang literal segmen sebelumnya" % benih)


func _test_builder_pelanggan() -> void:
	_judul.call("RouteBuilder: 25 pelanggan seberang, id unik, jarak rata-rata sekitar 9, celah maks 20, koran awal 30 (AC-7)")
	var pustaka: Array[SegmenRute] = _pustaka()
	var jumlah_rata: float = 0.0
	var jumlah_rute: int = 0
	for i: int in range(20):
		var benih: int = 9000 + i
		var rute: RouteBuilder.Rute = _rute(benih, pustaka)
		if rute == null:
			check(false, "seed %d dibangun" % benih)
			continue
		var urutan: Array[String] = _id_urutan(rute)
		var awal: Dictionary = _awal_oracle(urutan)
		check(rute.pelanggan.size() == 25, "seed %d: tepat 25 pelanggan (dapat %d)" % [benih, rute.pelanggan.size()])
		var unik: Dictionary = {}
		var semua_sah: bool = true
		var posisi_maju: Array[float] = []
		for p: RouteBuilder.RumahRute in rute.pelanggan:
			unik[p.id] = true
			var bagian: PackedStringArray = p.id.split("@")
			var ada: bool = bagian.size() == 2 and BOLEH.has(bagian[0]) and (BOLEH[bagian[0]] as Array).has(int(bagian[1]))
			if not ada or p.sisi != LoperAnim.Sisi.SEBERANG or not p.pelanggan_boleh or not p.pelanggan:
				semua_sah = false
			if ada:
				posisi_maju.append(float(awal[bagian[0]]) + float(int(bagian[1])))
		check(unik.size() == 25, "seed %d: id pelanggan unik (%d)" % [benih, unik.size()])
		check(semua_sah, "seed %d: semua pelanggan rumah seberang pelanggan_boleh menurut literal (id <id_segmen>@<pos>)" % benih)
		var urut: bool = true
		var celah_maks: float = 0.0
		for j: int in range(1, posisi_maju.size()):
			if posisi_maju[j] <= posisi_maju[j - 1]:
				urut = false
			celah_maks = maxf(celah_maks, posisi_maju[j] - posisi_maju[j - 1])
		check(urut and posisi_maju.size() == 25, "seed %d: pelanggan terurut menurut maju dan posisinya cocok dengan hitungan literal" % benih)
		check(celah_maks <= 20.0, "seed %d: celah antar pelanggan terpanjang %.1f <= 20 ubin" % [benih, celah_maks])
		var rata: float = (posisi_maju[posisi_maju.size() - 1] - posisi_maju[0]) / 24.0
		check(rata >= 7.5 and rata <= 10.5, "seed %d: jarak rata-rata antar pelanggan %.2f ubin di 7,5 sampai 10,5 (BALANCING 6: sekitar 9)" % [benih, rata])
		check(is_equal_approx(RouteBuilder.rata_jarak_pelanggan(rute), rata), "seed %d: rata_jarak_pelanggan sama dengan hitungan literal" % benih)
		jumlah_rata += rata
		jumlah_rute += 1
		check(rute.koran_awal == 30, "seed %d: koran awal 30 = 25 + 20%%" % benih)
		var jumlah_pelanggan_di_daftar: int = 0
		for rumah: RouteBuilder.RumahRute in rute.rumah:
			if rumah.pelanggan:
				jumlah_pelanggan_di_daftar += 1
		check(jumlah_pelanggan_di_daftar == 25, "seed %d: tepat 25 rumah bertanda pelanggan di daftar rumah" % benih)
	check(jumlah_rute == 20 and jumlah_rata / float(maxi(jumlah_rute, 1)) >= 8.5 and jumlah_rata / float(maxi(jumlah_rute, 1)) <= 9.8, "rata-rata 20 rute dekat 9 ubin: %.2f" % (jumlah_rata / float(maxi(jumlah_rute, 1))))


func _test_builder_sapuan() -> void:
	_judul.call("RouteBuilder: 400 seed dibangun tanpa galat, semua kombinasi pembuka dan penutup muncul (AC-5 sampai AC-7, ROUTE_DESIGN 7)")
	var pustaka: Array[SegmenRute] = _pustaka()
	var gagal: int = 0
	var kombinasi: Dictionary = {}
	var urutan_unik: Dictionary = {}
	var paling_sedikit: int = 99
	var pembuka_terbanyak: int = 0
	var pertama_terjauh: float = 0.0
	var terakhir_ke_akhir: float = 999.0
	for benih: int in range(400):
		var hasil: RouteBuilder.Hasil = RouteBuilder.bangun(benih, pustaka)
		if not hasil.sah():
			gagal += 1
			check(false, "seed %d gagal dibangun: %s" % [benih, "; ".join(hasil.galat)])
			continue
		var urutan: Array[String] = _id_urutan(hasil.rute)
		kombinasi["%s|%s" % [urutan[0], urutan[6]]] = true
		urutan_unik[",".join(urutan)] = true
		if hasil.rute.pelanggan.size() != 25:
			gagal += 1
			continue
		var per_segmen: Dictionary = {}
		for p: RouteBuilder.RumahRute in hasil.rute.pelanggan:
			per_segmen[p.id_segmen] = int(per_segmen.get(p.id_segmen, 0)) + 1
		for id: String in urutan:
			paling_sedikit = mini(paling_sedikit, int(per_segmen.get(id, 0)))
		pembuka_terbanyak = maxi(pembuka_terbanyak, int(per_segmen.get(urutan[0], 0)))
		pertama_terjauh = maxf(pertama_terjauh, hasil.rute.pelanggan[0].maju_ubin)
		terakhir_ke_akhir = minf(terakhir_ke_akhir, hasil.rute.panjang_ubin - hasil.rute.pelanggan[24].maju_ubin)
	check(gagal == 0, "400 seed: semuanya dibangun dengan 25 pelanggan")
	check(paling_sedikit >= 2, "pelanggan tersebar: tiap segmen paling sedikit 2 pelanggan di 400 rute (paling sedikit %d)" % paling_sedikit)
	check(pembuka_terbanyak <= 3, "segmen pembuka paling banyak 3 pelanggan (pemanasan 2-3 berdekatan, ROUTE_DESIGN 5): %d" % pembuka_terbanyak)
	check(pertama_terjauh <= 14.0 and terakhir_ke_akhir <= 14.0 and terakhir_ke_akhir >= 4.0, "pelanggan pertama paling jauh %.0f ubin dari awal dan pelanggan terakhir %.0f ubin dari garis akhir (<= 14, rute tidak berhenti kosong)" % [pertama_terjauh, terakhir_ke_akhir])
	check(kombinasi.size() == 4, "empat kombinasi pembuka x penutup semuanya muncul dan semuanya sah (%d)" % kombinasi.size())
	check(urutan_unik.size() >= 100, "400 seed menghasilkan paling sedikit 100 urutan segmen berbeda dari 288 yang mungkin (%d)" % urutan_unik.size())


func _test_builder_pustaka_rusak() -> void:
	_judul.call("RouteBuilder: pustaka tidak cukup ditolak dengan galat, bukan rute setengah jadi (AC-5)")
	var pustaka: Array[SegmenRute] = _pustaka()
	var tanpa_tengah: Array[SegmenRute] = []
	for segmen: SegmenRute in pustaka:
		if segmen.id != "per_tengah_03":
			tanpa_tengah.append(segmen)
	var h1: RouteBuilder.Hasil = RouteBuilder.bangun(1, tanpa_tengah)
	check(not h1.sah() and h1.rute == null and _galat_berisi(h1.galat, "pustaka tidak cukup"), "4 segmen tengah (butuh 5): ditolak (%s)" % "; ".join(h1.galat))
	var tanpa_pembuka: Array[SegmenRute] = []
	for segmen: SegmenRute in pustaka:
		if segmen.posisi != SegmenRute.Posisi.PEMBUKA:
			tanpa_pembuka.append(segmen)
	var h2: RouteBuilder.Hasil = RouteBuilder.bangun(1, tanpa_pembuka)
	check(not h2.sah() and h2.rute == null, "tanpa segmen pembuka: ditolak")
	var kosong: Array[SegmenRute] = []
	check(not RouteBuilder.bangun(1, kosong).sah(), "pustaka kosong: ditolak")
	# Semua tengah padat: tidak ada susunan tanpa dua padat berurutan.
	var semua_padat: Array[SegmenRute] = []
	for segmen: SegmenRute in pustaka:
		var d: SegmenRute = SegmenRute.new()
		d.id = segmen.id
		d.panjang = segmen.panjang
		d.posisi = segmen.posisi
		d.tingkat = SegmenRute.Tingkat.PADAT if segmen.posisi == SegmenRute.Posisi.TENGAH else SegmenRute.Tingkat.TENANG
		d.rumah = segmen.rumah
		d.objek = segmen.objek
		semua_padat.append(d)
	var h3: RouteBuilder.Hasil = RouteBuilder.bangun(1, semua_padat)
	check(not h3.sah() and _galat_berisi(h3.galat, "dua segmen padat berurutan"), "lima segmen tengah padat semua: tidak ada susunan sah, ditolak (%s)" % "; ".join(h3.galat))
	# Kandidat pelanggan kurang dari 25: hanya rumah di pos 6 yang boleh (7 per rute).
	var sedikit: Array[SegmenRute] = []
	for segmen: SegmenRute in pustaka:
		var d: SegmenRute = SegmenRute.new()
		d.id = segmen.id
		d.panjang = segmen.panjang
		d.posisi = segmen.posisi
		d.tingkat = segmen.tingkat
		d.objek = segmen.objek
		var rumah_baru: Array[SegmenRute.Rumah] = []
		for r: SegmenRute.Rumah in segmen.rumah:
			var salin: SegmenRute.Rumah = SegmenRute.Rumah.new()
			salin.pos = r.pos
			salin.sisi = r.sisi
			salin.jenis = r.jenis
			salin.pelanggan_boleh = r.pelanggan_boleh and r.pos == 6
			rumah_baru.append(salin)
		d.rumah = rumah_baru
		sedikit.append(d)
	# Satu segmen tengah panjang tanpa pelanggan_boleh: celah antar pelanggan pasti di atas 20 ubin di setiap rute (semua tengah dipakai).
	var celah: Array[SegmenRute] = []
	for segmen: SegmenRute in pustaka:
		var d: SegmenRute = SegmenRute.new()
		d.id = segmen.id
		d.panjang = segmen.panjang
		d.posisi = segmen.posisi
		d.tingkat = segmen.tingkat
		d.objek = segmen.objek
		var rumah_celah: Array[SegmenRute.Rumah] = []
		for r: SegmenRute.Rumah in segmen.rumah:
			var salin_celah: SegmenRute.Rumah = SegmenRute.Rumah.new()
			salin_celah.pos = r.pos
			salin_celah.sisi = r.sisi
			salin_celah.jenis = r.jenis
			salin_celah.pelanggan_boleh = r.pelanggan_boleh and segmen.id != "per_tengah_03"
			rumah_celah.append(salin_celah)
		d.rumah = rumah_celah
		celah.append(d)
	var h5: RouteBuilder.Hasil = RouteBuilder.bangun(1, celah)
	check(not h5.sah() and h5.rute == null and _galat_berisi(h5.galat, "tidak ada pilihan pelanggan dengan celah"), "segmen 40 ubin tanpa kandidat: celah > 20 tak bisa dihindari, ditolak oleh pemilih (%s)" % "; ".join(h5.galat))
	var h4: RouteBuilder.Hasil = RouteBuilder.bangun(1, sedikit)
	check(not h4.sah() and _galat_berisi(h4.galat, "kandidat pelanggan 7 kurang dari 25"), "hanya 7 kandidat pelanggan: ditolak (%s)" % "; ".join(h4.galat))


func _test_periksa_rute_mutan() -> void:
	_judul.call("RouteBuilder.periksa_rute: rute yang dirusak ditolak (mutan, AC-6, AC-7)")
	var pustaka: Array[SegmenRute] = _pustaka()
	var asli: RouteBuilder.Rute = _rute(31, pustaka)
	check(asli != null and RouteBuilder.periksa_rute(asli).is_empty(), "rute asli seed 31 lolos periksa_rute")
	if asli == null:
		return
	# 1. Satu pelanggan hilang.
	var hilang: RouteBuilder.RumahRute = asli.pelanggan.pop_back()
	check(_galat_berisi(RouteBuilder.periksa_rute(asli), "pelanggan 24, seharusnya 25"), "mutan: 24 pelanggan ditolak")
	asli.pelanggan.append(hilang)
	# 2. Pelanggan pindah ke sisi dekat.
	var sisi_asli: LoperAnim.Sisi = asli.pelanggan[3].sisi
	asli.pelanggan[3].sisi = LoperAnim.Sisi.DEKAT
	check(_galat_berisi(RouteBuilder.periksa_rute(asli), "bukan rumah seberang yang boleh"), "mutan: pelanggan di sisi dekat ditolak")
	asli.pelanggan[3].sisi = sisi_asli
	# 3. Pelanggan bukan pelanggan_boleh.
	asli.pelanggan[5].pelanggan_boleh = false
	check(_galat_berisi(RouteBuilder.periksa_rute(asli), "bukan rumah seberang yang boleh"), "mutan: pelanggan dari rumah yang tidak boleh ditolak")
	asli.pelanggan[5].pelanggan_boleh = true
	# 4. Segmen ganda.
	var segmen_asli: SegmenRute = asli.segmen[3]
	asli.segmen[3] = asli.segmen[2]
	check(_galat_berisi(RouteBuilder.periksa_rute(asli), "dipakai dua kali"), "mutan: segmen dipakai dua kali ditolak")
	asli.segmen[3] = segmen_asli
	# 5. Pembuka dan penutup tertukar.
	var pertama: SegmenRute = asli.segmen[0]
	asli.segmen[0] = asli.segmen[6]
	asli.segmen[6] = pertama
	check(_galat_berisi(RouteBuilder.periksa_rute(asli), "seharusnya pembuka"), "mutan: penutup di awal rute ditolak")
	asli.segmen[6] = asli.segmen[0]
	asli.segmen[0] = pertama
	# 6. Dua padat berurutan.
	var padat_a: SegmenRute = _segmen_dari(pustaka, "per_tengah_04")
	var padat_b: SegmenRute = _segmen_dari(pustaka, "per_tengah_05")
	var simpan_1: SegmenRute = asli.segmen[1]
	var simpan_2: SegmenRute = asli.segmen[2]
	asli.segmen[1] = padat_a
	asli.segmen[2] = padat_b
	check(_galat_berisi(RouteBuilder.periksa_rute(asli), "segmen padat berurutan"), "mutan: dua segmen padat berurutan ditolak")
	asli.segmen[1] = simpan_1
	asli.segmen[2] = simpan_2
	# 7. Celah antar pelanggan terlalu panjang.
	var maju_asli: float = asli.pelanggan[10].maju_ubin
	asli.pelanggan[10].maju_ubin = asli.pelanggan[9].maju_ubin + 20.5
	check(_galat_berisi(RouteBuilder.periksa_rute(asli), "celah antar pelanggan"), "mutan: celah 20,5 ubin ditolak")
	asli.pelanggan[10].maju_ubin = maju_asli
	# 8. Dua rintangan berdekatan.
	var objek_baru: RouteBuilder.ObjekRute = RouteBuilder.ObjekRute.new()
	objek_baru.jenis = "anjing_penjaga"
	objek_baru.maju_ubin = asli.objek[0].maju_ubin + 5.0
	asli.objek.append(objek_baru)
	check(_galat_berisi(RouteBuilder.periksa_rute(asli), "dua rintangan"), "mutan: dua rintangan 5 ubin berdekatan (di rute) ditolak")
	asli.objek.pop_back()
	# 9. Id rumah ganda.
	var id_asli: String = asli.rumah[1].id
	asli.rumah[1].id = asli.rumah[0].id
	check(_galat_berisi(RouteBuilder.periksa_rute(asli), "ganda"), "mutan: id rumah ganda ditolak")
	asli.rumah[1].id = id_asli
	check(RouteBuilder.periksa_rute(asli).is_empty(), "setelah semua mutan dipulihkan, rute lolos lagi")
	# 10. Jumlah segmen salah.
	var terakhir: SegmenRute = asli.segmen.pop_back()
	check(_galat_berisi(RouteBuilder.periksa_rute(asli), "berisi 6 segmen"), "mutan: 6 segmen ditolak")
	asli.segmen.append(terakhir)


func _segmen_dari(pustaka: Array[SegmenRute], id: String) -> SegmenRute:
	for segmen: SegmenRute in pustaka:
		if segmen.id == id:
			return segmen
	return null


func _test_rng_global_tidak_disentuh() -> void:
	_judul.call("RouteBuilder: tidak memakai RNG global (rule gdscript, AC-5)")
	var pustaka: Array[SegmenRute] = _pustaka()
	seed(424242)
	var sebelum: int = randi()
	seed(424242)
	var rute: RouteBuilder.Rute = _rute(5, pustaka)
	var sesudah: int = randi()
	check(rute != null and sebelum == sesudah, "bangun rute tidak menggeser RNG global (randi sesudah seed sama, %d vs %d)" % [sebelum, sesudah])
	var sumber: String = FileAccess.get_file_as_string("res://scripts/systems/route_builder.gd")
	var kode: PackedStringArray = sumber.split("\n")
	var pelanggaran: Array[String] = []
	for baris: String in kode:
		var tanpa_komentar: String = baris.split("##")[0].split("#")[0]
		for terlarang: String in ["randi()", "randf()", "randomize()", ".shuffle()", "Time.", "OS.get_ticks", "pick_random"]:
			if tanpa_komentar.contains(terlarang):
				pelanggaran.append(terlarang)
	check(pelanggaran.is_empty(), "route_builder.gd tanpa randi/randf/shuffle/Time/pick_random global: %s" % str(pelanggaran))


func _test_koran_awal() -> void:
	_judul.call("RouteBuilder.koran_awal: pelanggan + 20% dibulatkan ke atas (AC-7, BALANCING 4)")
	var kasus: Array[Array] = [[25, 30], [10, 12], [11, 14], [1, 2], [5, 6], [20, 24], [0, 0], [-3, 0], [50, 60], [4, 5], [26, 32]]
	for k: Array in kasus:
		check(RouteBuilder.koran_awal(int(k[0])) == int(k[1]), "koran awal untuk %d pelanggan = %d (dapat %d)" % [k[0], k[1], RouteBuilder.koran_awal(int(k[0]))])
	check(Config.RUTE_PELANGGAN == 25 and Config.RUTE_SEGMEN_PER_RUTE == 7 and Config.RUTE_KORAN_CADANGAN_PERSEN == 20 and Config.KORAN_AWAL == 30, "konstanta Config: 25 pelanggan, 7 segmen, 20%, koran jalan uji 30")


func _test_waktu_bangun() -> void:
	_judul.call("RouteBuilder: memuat berkas dan menyusun satu rute < 1 detik (AC-8, TECH_PLAN 3.7)")
	var mulai: int = Time.get_ticks_usec()
	var kumpulan: PemuatRute.Kumpulan = PemuatRute.muat_folder(FOLDER)
	var hasil: RouteBuilder.Hasil = RouteBuilder.bangun(Config.RUTE_SEED_DEV, kumpulan.segmen)
	var lama_ms: float = float(Time.get_ticks_usec() - mulai) / 1000.0
	check(hasil.sah() and kumpulan.sah(), "rute seed dev dibangun tanpa galat")
	check(lama_ms < 1000.0, "muat 9 berkas + susun satu rute: %.1f ms (< 1000 ms)" % lama_ms)
	print("[waktu_rute] muat + susun satu rute = %.1f ms" % lama_ms)
	var mulai_sapuan: int = Time.get_ticks_usec()
	for benih: int in range(100):
		RouteBuilder.bangun(benih, kumpulan.segmen)
	var rata_ms: float = float(Time.get_ticks_usec() - mulai_sapuan) / 1000.0 / 100.0
	check(rata_ms < 50.0, "susun satu rute (tanpa muat berkas) rata-rata %.2f ms (< 50 ms)" % rata_ms)


## Data segmen harus ikut paket game: tidak ada pola `exclude_filter` preset Android yang mencocokkan berkas segmen (AC-18). Pemeriksaan
## isi paket sungguhan: `godot --headless --path . --export-pack "Android" build/kring-uji.pck` lalu cari `assets/data/routes/perumahan/`.
func _test_data_ikut_paket() -> void:
	_judul.call("Ekspor: berkas segmen tidak dikecualikan preset Android (AC-18)")
	var cfg: ConfigFile = ConfigFile.new()
	var kode: int = cfg.load("res://export_presets.cfg")
	check(kode == OK, "export_presets.cfg terbaca")
	var filter: String = ""
	for bagian: String in cfg.get_sections():
		if bagian.ends_with(".options"):
			continue
		filter = str(cfg.get_value(bagian, "exclude_filter", ""))
	var tercocok: Array[String] = []
	for pola: String in filter.split(","):
		var bersih: String = pola.strip_edges()
		if bersih.is_empty():
			continue
		for id: String in ID_SEGMEN:
			if ("assets/data/routes/perumahan/%s.json" % id).match(bersih):
				tercocok.append("%s -> %s" % [bersih, id])
	check(not filter.is_empty() and tercocok.is_empty(), "tidak ada pola exclude_filter (%s) yang mengecualikan berkas segmen: %s" % [filter, str(tercocok)])
	check(("docs/ROADMAP.md").match("docs/*") and not ("assets/data/routes/perumahan/per_buka_01.json").match("docs/*"), "pencocok pola memang membedakan docs/* dari berkas segmen (kontrol)")


# --- AC-9: zona dari data rute ---

func _persegi_sama(a: Rect2, x: float, y: float, w: float, h: float) -> bool:
	return is_equal_approx(a.position.x, x) and is_equal_approx(a.position.y, y) and is_equal_approx(a.size.x, w) and is_equal_approx(a.size.y, h)


func _test_zona_rumah_literal() -> void:
	_judul.call("Zona rumah dari data rute: koordinat literal di awal kavling 50 (AC-9)")
	var seberang: Array[ZonaSasaran.Zona] = ZonaSasaran.zona_rumah_seberang(50.0, true, 0, "per_uji@6")
	check(seberang.size() == 4, "rumah seberang: 4 zona (kotak surat, halaman, teras, jendela)")
	if seberang.size() == 4:
		check(seberang[0].jenis == ZonaSasaran.Jenis.KOTAK_SURAT and _persegi_sama(seberang[0].persegi, -1.875, 50.875, 0.5, 0.5), "kotak surat seberang di awal 50: [-1,875; 50,875; 0,5 x 0,5]")
		check(seberang[1].jenis == ZonaSasaran.Jenis.HALAMAN and _persegi_sama(seberang[1].persegi, -3.0, 49.5, 1.0, 3.0), "halaman seberang di awal 50: [-3; 49,5; 1 x 3]")
		check(seberang[2].jenis == ZonaSasaran.Jenis.TERAS and _persegi_sama(seberang[2].persegi, -3.0, 50.0, 0.5, 1.25), "teras seberang di awal 50: [-3; 50; 0,5 x 1,25]")
		check(seberang[3].jenis == ZonaSasaran.Jenis.JENDELA and _persegi_sama(seberang[3].persegi, -3.0, 51.5, 0.25, 0.75), "jendela seberang di awal 50: [-3; 51,5; 0,25 x 0,75]")
		check(seberang[0].sisi == LoperAnim.Sisi.SEBERANG and seberang[0].id_rumah == "per_uji@6" and seberang[3].id_rumah == "per_uji@6", "zona seberang bersisi SEBERANG dan membawa id rumah")
	var dekat: Array[ZonaSasaran.Zona] = ZonaSasaran.zona_rumah_dekat(50.0, false, 0, "per_uji@8")
	check(dekat.size() == 3, "rumah dekat: 3 zona (tanpa jendela)")
	if dekat.size() == 3:
		check(dekat[0].jenis == ZonaSasaran.Jenis.KOTAK_SURAT and _persegi_sama(dekat[0].persegi, 1.375, 50.875, 0.5, 0.5), "kotak surat dekat di awal 50: [1,375; 50,875; 0,5 x 0,5]")
		check(dekat[1].jenis == ZonaSasaran.Jenis.HALAMAN and _persegi_sama(dekat[1].persegi, 2.0, 49.5, 1.0, 3.0), "halaman dekat di awal 50: [2; 49,5; 1 x 3]")
		check(dekat[2].jenis == ZonaSasaran.Jenis.TERAS and _persegi_sama(dekat[2].persegi, 2.5, 50.25, 0.5, 1.5), "teras dekat di awal 50: [2,5; 50,25; 0,5 x 1,5]")
		check(not dekat[0].pelanggan and not dekat[1].pelanggan and not dekat[2].pelanggan, "zona rumah dekat bukan pelanggan")
	# Penilaian titik mendarat (dunia: y = -maju), prioritas kotak surat > jendela > teras > halaman.
	var zona: Array[ZonaSasaran.Zona] = ZonaSasaran.zona_rumah_seberang(50.0, true)
	zona.append_array(ZonaSasaran.zona_rumah_dekat(50.0, false))
	var kasus: Array[Array] = [
		[Vector2(-1.7, -51.0), ZonaSasaran.Hasil.KOTAK_SURAT, "tengah kotak surat seberang"],
		[Vector2(-1.875, -50.875), ZonaSasaran.Hasil.KOTAK_SURAT, "tepi min kotak surat inklusif"],
		[Vector2(-1.375, -51.0), ZonaSasaran.Hasil.MELESET, "tepi maks lateral kotak surat eksklusif"],
		[Vector2(-1.7, -51.375), ZonaSasaran.Hasil.MELESET, "tepi maks maju kotak surat eksklusif"],
		[Vector2(-2.6, -49.8), ZonaSasaran.Hasil.HALAMAN, "halaman depan rumah"],
		[Vector2(-2.8, -50.5), ZonaSasaran.Hasil.TERAS, "teras menang atas halaman"],
		[Vector2(-2.9, -51.8), ZonaSasaran.Hasil.JENDELA, "jendela menang atas halaman"],
		[Vector2(-2.9, -49.0), ZonaSasaran.Hasil.MELESET, "di belakang halaman"],
		[Vector2(0.0, -51.0), ZonaSasaran.Hasil.MELESET, "tengah jalan"],
		[Vector2(1.5, -51.0), ZonaSasaran.Hasil.BUKAN_PELANGGAN, "kotak surat rumah dekat bukan pelanggan"],
		[Vector2(2.2, -50.0), ZonaSasaran.Hasil.BUKAN_PELANGGAN, "halaman rumah dekat bukan pelanggan"],
	]
	for k: Array in kasus:
		check(ZonaSasaran.klasifikasi(k[0], zona) == k[1], "titik %s = %s (%s)" % [k[0], ZonaSasaran.Hasil.keys()[k[1]], k[2]])
	var bukan_pelanggan: Array[ZonaSasaran.Zona] = ZonaSasaran.zona_rumah_seberang(50.0, false)
	check(ZonaSasaran.klasifikasi(Vector2(-1.7, -51.0), bukan_pelanggan) == ZonaSasaran.Hasil.BUKAN_PELANGGAN, "kotak surat rumah seberang bukan pelanggan = BUKAN_PELANGGAN (tidak sah)")
	# Zona jalan uji tidak berubah oleh refaktor: kavling 3 (awal 12) sama dengan zona rumah di awal 12.
	var uji: Array[ZonaSasaran.Zona] = ZonaSasaran.zona_jalan_uji(3)
	var rute_12: Array[ZonaSasaran.Zona] = ZonaSasaran.zona_rumah_seberang(12.0, ZonaSasaran.pelanggan_jalan_uji(3), 3)
	rute_12.append_array(ZonaSasaran.zona_rumah_dekat(12.0, true, 3))
	var sama: bool = uji.size() == 7 and rute_12.size() == 7
	for i: int in range(mini(uji.size(), rute_12.size())):
		if uji[i].persegi != rute_12[i].persegi or uji[i].jenis != rute_12[i].jenis or uji[i].pelanggan != rute_12[i].pelanggan or uji[i].sisi != rute_12[i].sisi:
			sama = false
	check(sama, "zona jalan uji kavling 3 = zona rumah di awal 12 (satu geometri, tanpa angka baru)")
	check(ZonaSasaran.zona_rute_rentang([] as Array[RouteBuilder.RumahRute], NAN, 10.0).is_empty(), "rentang dengan batas tidak hingga = kosong")


func _rumah_uji(id: String, maju: float, sisi: LoperAnim.Sisi, pelanggan: bool) -> RouteBuilder.RumahRute:
	var r: RouteBuilder.RumahRute = RouteBuilder.RumahRute.new()
	r.id = id
	r.maju_ubin = maju
	r.sisi = sisi
	r.pelanggan = pelanggan
	r.pelanggan_boleh = pelanggan
	return r


func _test_zona_rute_dan_penilaian() -> void:
	_judul.call("Zona dari rute nyata: kotak surat pelanggan dinilai sah penuh, bukan pelanggan tidak sah, rentang hanya sekitar (AC-9)")
	var daftar: Array[RouteBuilder.RumahRute] = [
		_rumah_uji("a@2", 2.0, LoperAnim.Sisi.SEBERANG, true),
		_rumah_uji("a@6", 6.0, LoperAnim.Sisi.SEBERANG, false),
		_rumah_uji("a@10", 10.0, LoperAnim.Sisi.SEBERANG, true),
		_rumah_uji("a@8", 8.0, LoperAnim.Sisi.DEKAT, false),
		_rumah_uji("a@30", 30.0, LoperAnim.Sisi.SEBERANG, true),
	]
	check(ZonaSasaran.zona_rute(daftar).size() == 4 * 4 + 3, "zona_rute: 4 rumah seberang x 4 + 1 rumah dekat x 3 = 19 zona")
	var jendela: Array[ZonaSasaran.Zona] = ZonaSasaran.zona_rute_rentang(daftar, 5.0, 12.0)
	var id_jendela: Dictionary = {}
	for z: ZonaSasaran.Zona in jendela:
		id_jendela[z.id_rumah] = true
	var kunci: Array = id_jendela.keys()
	kunci.sort()
	check(kunci == ["a@10", "a@2", "a@6", "a@8"], "rentang maju 5 sampai 12 (+ petak 4 di tiap ujung = 1 sampai 16): rumah a@2, a@6, a@8, a@10, bukan a@30: %s" % str(kunci))
	var sempit: Array[ZonaSasaran.Zona] = ZonaSasaran.zona_rute_rentang(daftar, 30.0, 30.0)
	var id_sempit: Dictionary = {}
	for z: ZonaSasaran.Zona in sempit:
		id_sempit[z.id_rumah] = true
	check(id_sempit.keys() == ["a@30"], "rentang di 30: hanya a@30 (%s)" % str(id_sempit.keys()))
	var pustaka: Array[SegmenRute] = _pustaka()
	for benih: int in [3, 14, 159]:
		var rute: RouteBuilder.Rute = _rute(benih, pustaka)
		if rute == null:
			check(false, "seed %d dibangun" % benih)
			continue
		var semua: Array[ZonaSasaran.Zona] = ZonaSasaran.zona_rute(rute.rumah)
		var urutan: Array[String] = _id_urutan(rute)
		var awal: Dictionary = _awal_oracle(urutan)
		var pelanggan_sah: int = 0
		var bukan_tidak_sah: int = 0
		var salah: int = 0
		for rumah: RouteBuilder.RumahRute in rute.rumah:
			var bagian: PackedStringArray = rumah.id.split("@")
			var maju_literal: float = float(awal[bagian[0]]) + float(int(bagian[1]))
			if not is_equal_approx(maju_literal, rumah.maju_ubin):
				salah += 1
			if rumah.sisi == LoperAnim.Sisi.SEBERANG:
				# Pusat kotak surat seberang di awal kavling + (-1,625; 1,125) (literal dari BALANCING 5).
				var titik: Vector2 = Vector2(-1.625, -(maju_literal + 1.125))
				var hasil: ZonaSasaran.Hasil = ZonaSasaran.klasifikasi(titik, semua)
				var antaran: ZonaSasaran.Antaran = ZonaSasaran.status_antaran(hasil, false)
				if rumah.pelanggan:
					if hasil == ZonaSasaran.Hasil.KOTAK_SURAT and antaran == ZonaSasaran.Antaran.SAH_PENUH:
						pelanggan_sah += 1
				else:
					if hasil == ZonaSasaran.Hasil.BUKAN_PELANGGAN and antaran == ZonaSasaran.Antaran.TIDAK_SAH:
						bukan_tidak_sah += 1
			else:
				var titik_dekat: Vector2 = Vector2(1.625, -(maju_literal + 1.125))
				if ZonaSasaran.klasifikasi(titik_dekat, semua) != ZonaSasaran.Hasil.BUKAN_PELANGGAN:
					salah += 1
		var jumlah_seberang_bukan: int = 0
		for rumah: RouteBuilder.RumahRute in rute.rumah:
			if rumah.sisi == LoperAnim.Sisi.SEBERANG and not rumah.pelanggan:
				jumlah_seberang_bukan += 1
		check(salah == 0, "seed %d: posisi maju rumah = literal dan kotak surat dekat selalu BUKAN_PELANGGAN (%d salah)" % [benih, salah])
		check(pelanggan_sah == 25, "seed %d: kotak surat 25 pelanggan = KOTAK_SURAT dan SAH_PENUH (%d)" % [benih, pelanggan_sah])
		check(bukan_tidak_sah == jumlah_seberang_bukan and jumlah_seberang_bukan > 0, "seed %d: kotak surat tiap rumah seberang bukan pelanggan (%d) = BUKAN_PELANGGAN dan TIDAK_SAH" % [benih, jumlah_seberang_bukan])
		check(ZonaSasaran.klasifikasi(Vector2(0.0, -(rute.panjang_ubin + 30.0)), semua) == ZonaSasaran.Hasil.MELESET, "seed %d: titik di luar garis akhir = MELESET" % benih)


# --- AC-10, AC-11 (bagian murni): mode bantu di atas zona rute ---

func _test_bantu_di_zona_rute() -> void:
	_judul.call("Mode bantu di atas zona rute: hanya kotak surat pelanggan seberang, mendarat SAH_PENUH (AC-10, AC-11)")
	var pustaka: Array[SegmenRute] = _pustaka()
	var kecepatan: Array[float] = [3.0, 4.5, 6.0]
	for benih: int in [8, 41]:
		var rute: RouteBuilder.Rute = _rute(benih, pustaka)
		if rute == null:
			check(false, "seed %d dibangun" % benih)
			continue
		var id_pelanggan: Dictionary = {}
		for p: RouteBuilder.RumahRute in rute.pelanggan:
			id_pelanggan[p.id] = true
		var salah_jenis: int = 0
		var salah_nilai: int = 0
		var terpilih: int = 0
		var posisi_uji: int = 0
		var maju: float = 0.0
		while maju < rute.panjang_ubin:
			for v: float in kecepatan:
				var jangkauan: float = BantuLempar.jangkauan_maju_ubin(v, JEDA_LEPAS)
				var zona: Array[ZonaSasaran.Zona] = ZonaSasaran.zona_rute_rentang(rute.rumah, maju, maju + jangkauan)
				for lateral: float in [-0.9, 0.0, 0.9]:
					var posisi: Vector2 = Vector2(lateral, -maju)
					posisi_uji += 1
					var pilihan: BantuLempar.Pilihan = BantuLempar.pilih(LoperAnim.Sisi.SEBERANG, posisi, v, 0.0, JEDA_LEPAS, LEBAR, zona)
					var pilihan_dekat: BantuLempar.Pilihan = BantuLempar.pilih(LoperAnim.Sisi.DEKAT, posisi, v, 0.0, JEDA_LEPAS, LEBAR, zona)
					if pilihan_dekat != null:
						salah_jenis += 1
					if pilihan == null:
						continue
					terpilih += 1
					var hasil: ZonaSasaran.Hasil = ZonaSasaran.klasifikasi(pilihan.lintasan.titik_mendarat, zona)
					var antaran: ZonaSasaran.Antaran = ZonaSasaran.status_antaran(hasil, false)
					if not id_pelanggan.has(pilihan.zona.id_rumah) or pilihan.zona.sisi != LoperAnim.Sisi.SEBERANG or hasil != ZonaSasaran.Hasil.KOTAK_SURAT or antaran != ZonaSasaran.Antaran.SAH_PENUH:
						salah_nilai += 1
					# Prediksi = hasil: titik mendarat di dalam kotak surat pelanggan itu.
					if not ZonaSasaran.memuat(pilihan.zona, pilihan.lintasan.titik_mendarat):
						salah_nilai += 1
			maju += 2.5
		check(salah_jenis == 0, "seed %d: mode bantu tidak pernah memilih sasaran di sisi dekat (rumah dekat bukan pelanggan), %d kasus" % [benih, posisi_uji])
		check(salah_nilai == 0, "seed %d: setiap pilihan = kotak surat pelanggan seberang dari rute, mendarat SAH_PENUH (%d salah dari %d pilihan)" % [benih, salah_nilai, terpilih])
		check(float(terpilih) > float(posisi_uji) / 6.0, "seed %d: mode bantu menemukan sasaran di banyak posisi (%d dari %d)" % [benih, terpilih, posisi_uji])
	# Tepat 3 ubin sebelum kotak surat pelanggan di lateral 0 pada santai: sasaran = pelanggan itu.
	var rute_dev: RouteBuilder.Rute = _rute(Config.RUTE_SEED_DEV, pustaka)
	if rute_dev == null:
		check(false, "rute seed dev dibangun")
		return
	var tepat: int = 0
	var benar: int = 0
	for p: RouteBuilder.RumahRute in rute_dev.pelanggan:
		var maju_sepeda: float = p.maju_ubin + 1.125 - 3.0
		if maju_sepeda < 0.0:
			continue
		tepat += 1
		var zona: Array[ZonaSasaran.Zona] = ZonaSasaran.zona_rute_rentang(rute_dev.rumah, maju_sepeda, maju_sepeda + BantuLempar.jangkauan_maju_ubin(3.0, JEDA_LEPAS))
		var pilihan: BantuLempar.Pilihan = BantuLempar.pilih(LoperAnim.Sisi.SEBERANG, Vector2(0.0, -maju_sepeda), 3.0, 0.0, JEDA_LEPAS, LEBAR, zona)
		if pilihan != null and pilihan.zona.id_rumah == p.id:
			benar += 1
	check(tepat >= 20 and benar == tepat, "tiap pelanggan: 3 ubin sebelum pusat kotak suratnya pada santai, sasaran mode bantu = pelanggan itu (%d dari %d)" % [benar, tepat])


# --- AC-15: penutup pemain ---

func _test_penutup_literal() -> void:
	_judul.call("PenutupPemain: oracle literal untuk menutupi, tidak menutupi, dan tepat di tepi (AC-15, pola tertutup_kotak)")
	# Kotak setinggi 1,0 bertapak lateral 0,5 sampai 1,5 dan maju 3 sampai 5 (koordinat jalan), mis. mobil di jalur dekat.
	var mobil: PenutupPemain.Objek = PenutupPemain.buat(Rect2(0.5, 3.0, 1.0, 2.0), 1.0, "mobil")
	var kasus: Array[Array] = [
		[Vector2(0.0, -4.0), true, "pemain di belakang tengah kotak (d 0,5 sampai 1,0 kena)"],
		[Vector2(0.0, -5.5), true, "pemain di belakang kotak, masih tertutup (d 0,5 sampai 1,0)"],
		[Vector2(0.0, -6.5), false, "pemain terlalu jauh di belakang: sinar naik di atas kotak"],
		[Vector2(0.0, -3.5), false, "tepat di tepi: irisan d hanya satu titik, tidak tertutup"],
		[Vector2(0.0, -3.4), false, "belum sampai tapak"],
		[Vector2(1.0, -4.0), true, "pemain tepat di dalam tapak"],
		[Vector2(-1.0, -4.0), false, "pemain di sisi seberang: sinar ke kamera tidak lewat kotak"],
		[Vector2(1.5, -4.0), false, "tepat di tepi maks lateral tapak (eksklusif) dan lebih dekat kamera"],
	]
	for k: Array in kasus:
		check(PenutupPemain.menutupi(k[0], mobil) == k[1], "%s: titik %s menutupi = %s" % [k[2], k[0], k[1]])
	var rendah: PenutupPemain.Objek = PenutupPemain.buat(Rect2(0.5, 3.0, 1.0, 2.0), 0.5, "rendah")
	check(not PenutupPemain.menutupi(Vector2(0.0, -4.0), rendah), "kotak setinggi 0,5: titik (0, -4) tepat di puncak (d tunggal 0,5) tidak tertutup")
	var kecil: PenutupPemain.Objek = PenutupPemain.buat(Rect2(0.5, 3.0, 1.0, 2.0), 0.4, "kecil")
	check(not PenutupPemain.menutupi(Vector2(0.0, -4.0), kecil) and PenutupPemain.menutupi(Vector2(0.9, -4.0), kecil), "kotak setinggi 0,4: (0, -4) tidak tertutup, (0,9, -4) tertutup (d 0 sampai 0,4)")
	check(not PenutupPemain.menutupi(Vector2(NAN, -4.0), mobil) and not PenutupPemain.menutupi(Vector2(0.0, -4.0), null), "masukan NaN atau objek null = tidak menutupi")
	var daftar: Array[PenutupPemain.Objek] = [mobil, PenutupPemain.buat(Rect2(-6.0, 3.0, 3.0, 3.0), 2.0, "rumah_seberang"), rendah, PenutupPemain.buat(Rect2(0.5, 3.0, 1.0, 2.0), 1.0, "mobil_dua")]
	var indeks: PackedInt32Array = PenutupPemain.indeks_menutupi(Vector2(0.0, -4.0), daftar)
	check(indeks.size() == 2 and indeks[0] == 0 and indeks[1] == 3, "indeks_menutupi: hanya objek 0 dan 3 yang menutupi titik (0, -4): %s" % str(indeks))
	check(PenutupPemain.indeks_menutupi(Vector2(-1.0, -4.0), daftar).is_empty(), "indeks_menutupi di (-1, -4): tidak ada")
	check(is_equal_approx(PenutupPemain.alfa(true), 0.45) and is_equal_approx(PenutupPemain.alfa(false), 1.0), "alfa: menutupi 0,45 (RUTE_PENUTUP_ALFA), tidak menutupi 1,0")
	check(is_equal_approx(Config.RUTE_PENUTUP_ALFA, 0.45), "Config.RUTE_PENUTUP_ALFA = 0,45")


func _test_penutup_rumah_rute() -> void:
	_judul.call("PenutupPemain: tapak rumah rute (literal) dan rumah tidak menutupi pemain di lebar jalan resmi (AC-15)")
	check(_persegi_sama(PenutupPemain.tapak_rumah(LoperAnim.Sisi.SEBERANG, 8.0), -6.0, 7.5, 3.0, 3.0), "tapak rumah seberang di awal 8: [-6; 7,5; 3 x 3]")
	check(_persegi_sama(PenutupPemain.tapak_rumah(LoperAnim.Sisi.DEKAT, 8.0), 3.0, 7.5, 3.0, 3.0), "tapak rumah dekat di awal 8: [3; 7,5; 3 x 3]")
	check(PenutupPemain.tapak_rumah(LoperAnim.Sisi.TIDAK_ADA, 8.0) == Rect2(), "sisi TIDAK_ADA = tapak kosong")
	var pustaka: Array[SegmenRute] = _pustaka()
	var rute: RouteBuilder.Rute = _rute(12, pustaka)
	if rute == null:
		check(false, "rute seed 12 dibangun")
		return
	var objek: Array[PenutupPemain.Objek] = []
	for rumah: RouteBuilder.RumahRute in rute.rumah:
		objek.append(PenutupPemain.dari_rumah(rumah))
	check(objek.size() == rute.rumah.size() and is_equal_approx(objek[0].tinggi_ubin, 2.0) and objek[0].id == rute.rumah[0].id, "dari_rumah: satu objek per rumah, tinggi 2,0, id rumah ikut")
	var menutupi_pada: int = 0
	var maju: float = 0.0
	while maju < rute.panjang_ubin:
		for lateral: float in [-1.0, -0.5, 0.0, 0.5, 1.0]:
			menutupi_pada += PenutupPemain.indeks_menutupi(Vector2(lateral, -maju), objek).size()
		maju += 0.5
	check(menutupi_pada == 0, "rumah kedua sisi tidak menutupi pemain di lateral -1 sampai 1 sepanjang rute (%d)" % menutupi_pada)
	# Tapak dekat di awal 8 = lateral 3 sampai 6, maju 7,5 sampai 10,5. Pemain di lateral 0 dan maju 12: sinar ke kamera (lateral + d,
	# maju - d, z + d) masuk tapak untuk d antara 3,0 dan 4,5, sehingga kotak setinggi 3,5 menutup (z + d <= 3,5 bagi d 3,0 sampai 3,5).
	var tinggi_x: PenutupPemain.Objek = PenutupPemain.buat(PenutupPemain.tapak_rumah(LoperAnim.Sisi.DEKAT, 8.0), 3.5, "tinggi")
	check(PenutupPemain.menutupi(Vector2(0.0, -12.0), tinggi_x), "objek setinggi 3,5 di tapak dekat menutupi pemain di (0, maju 12)")
	check(not PenutupPemain.menutupi(Vector2(0.0, -12.0), PenutupPemain.buat(PenutupPemain.tapak_rumah(LoperAnim.Sisi.DEKAT, 8.0), 3.0, "pas")), "objek setinggi 3,0: sinar tepat di puncak (d tunggal 3,0) tidak tertutup")
	check(not PenutupPemain.menutupi(Vector2(0.0, -9.5), tinggi_x), "pemain di maju 9,5 (tegak lurus tapak): sinar masuk tapak hanya untuk d <= 2,0 padahal butuh d >= 3, tidak tertutup")
