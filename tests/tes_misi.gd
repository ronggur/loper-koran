class_name TesMisi
extends RefCounted
## Tes logika murni run fase4b-misi-kucing bagian A (AC-1 sampai AC-6, AC-12 bagian zona, AC-19): validasi data Cari (`DataMisi`, `PemuatMisi`),
## `RencanaMisi` (rencana kucing dari seed), dan `MissionManager` (lihat, petunjuk, tangkap, gagal, selesai, mode bantu).
##
## Oracle independen (AC-19, pelajaran QA-008 run 2B): rentang rumah, jarak tampil, ambang tangkap, dan hitungan timer ditulis ulang tes sebagai literal
## atau penjumlahan tes sendiri (bukan memanggil fungsi yang dites); posisi rumah seberang dihitung ulang dari `Rute.rumah` dengan penyaringan tes. Data
## buruk dibuat dengan mengubah SATU aturan pada salinan berkas nyata `p1_kucing`, lalu dilewatkan ke `PemuatMisi.parse_teks` (jalur yang sama dengan berkas).

const FOLDER_MISI: String = "res://assets/data/missions"
const FOLDER_RUTE: String = "res://assets/data/routes/perumahan"
const BERKAS_KONTEN: String = "res://translations/konten.csv"
const DT: float = 1.0 / 60.0

var _cek: Callable
var _judul: Callable
var _misi_cache: DataMisi = null
var _pustaka_cache: Array[SegmenRute] = []


func _init(cek: Callable, judul: Callable) -> void:
	_cek = cek
	_judul = judul


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_test_config()
	_test_data_nyata()
	_test_data_cari_ditolak()
	_test_data_banner_dan_hadiah()
	_test_rencana_enam_puluh_hari()
	_test_rencana_menghindari_mobil()
	_test_rencana_tidak_sah()
	_test_manager_lihat_dan_jendela()
	_test_manager_petunjuk()
	_test_manager_tangkap_ambang()
	_test_manager_tangkap_jatuh_jeda()
	_test_manager_gagal()
	_test_manager_selesai_sekali_dan_banner()
	_test_manager_tidak_mengubah_masukan()
	_test_manager_mode_bantu()
	_test_layak_dari_bike_motion()
	_test_hasil_rute_dan_hadiah()


# --- Pembantu ---

func _pustaka() -> Array[SegmenRute]:
	if _pustaka_cache.is_empty():
		_pustaka_cache = PemuatRute.muat_folder(FOLDER_RUTE).segmen
	return _pustaka_cache


func _misi_nyata() -> DataMisi:
	if _misi_cache == null:
		_misi_cache = PemuatMisi.muat_folder(FOLDER_MISI).cari("p1_kucing")
	return _misi_cache


func _teks_nyata() -> String:
	return FileAccess.get_file_as_string(FOLDER_MISI.path_join("perumahan.json"))


## Salinan data mentah p1_kucing dari berkas nyata (Dictionary, siap diubah).
func _mentah() -> Dictionary:
	var daftar: Array = JSON.parse_string(_teks_nyata())
	var d: Dictionary = daftar[0]
	return d.duplicate(true)


## Galat parse untuk `data` mentah lewat jalur berkas (`PemuatMisi.parse_teks`) dengan terjemahan nyata atau `kamus` sintetis.
func _galat(data: Dictionary, kamus: Dictionary = {}) -> String:
	var tl: Callable = Callable()
	if not kamus.is_empty():
		var dasar: Dictionary = _csv_konten()
		dasar.merge(kamus, true)
		tl = func(kunci: String) -> String: return str(dasar.get(kunci, kunci))
	var teks: String = JSON.stringify([data])
	return "; ".join(PemuatMisi.parse_teks(teks, "buruk.json", tl).galat)


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


func _titik(jenis: String, maju: float, awal: float, akhir: float, radius: float = 0.0, lama: float = 0.0) -> RencanaMisi.Titik:
	var t: RencanaMisi.Titik = RencanaMisi.Titik.new()
	t.jenis = jenis
	t.nama = "atap"
	t.lateral_ubin = -2.0
	t.maju_ubin = maju
	t.maju_rumah_ubin = maju - 0.5
	t.petunjuk_awal_ubin = awal
	t.petunjuk_akhir_ubin = akhir
	t.radius_ubin = radius
	t.lama_berhenti_detik = lama
	return t


## Rencana sintetis: kucing di maju 20, 40 (lihat) dan 60 (tangkap, radius 2, 1,5 detik); jendela petunjuk [0, 19,5), [19,5, 39,5), [39,5, 59,5);
## dua belas rumah berakhir tiap 8 ubin (batas 96), panjang rute 200.
func _rencana(maju_batas: float = 96.0, panjang: float = 200.0) -> RencanaMisi.Rencana:
	var r: RencanaMisi.Rencana = RencanaMisi.Rencana.new()
	r.id_misi = "p1_kucing"
	r.batas_rumah = 12
	r.jumlah_seberang = 14
	r.maju_batas_ubin = maju_batas
	r.panjang_ubin = panjang
	r.hadiah_koin = 75
	r.target = 1
	for i: int in range(12):
		r.akhir_kavling_ubin.append(float(8 * (i + 1)))
	r.titik.append(_titik("lihat", 20.0, 0.0, 19.5))
	r.titik.append(_titik("lihat", 40.0, 19.5, 39.5))
	r.titik.append(_titik("tangkap", 60.0, 39.5, 59.5, 2.0, 1.5))
	return r


func _masukan(maju: float, lateral: float = -1.0, kecepatan: float = 3.0, dt: float = DT) -> MissionManager.Masukan:
	var m: MissionManager.Masukan = MissionManager.Masukan.new()
	m.maju_ubin = maju
	m.lateral_ubin = lateral
	m.kecepatan_ud = kecepatan
	m.dt = dt
	return m


func _lemparan(maju_rumah: float, tepat: bool = true, bantu: bool = false, kotak: bool = true) -> MissionManager.Lemparan:
	var l: MissionManager.Lemparan = MissionManager.Lemparan.new()
	l.maju_rumah_ubin = maju_rumah
	l.tepat = tepat
	l.bantu = bantu
	l.kotak_pelanggan = kotak
	return l


## Satu langkah; mengembalikan hasil dan memasang keadaan baru ke `kotak[0]`.
func _langkah(kotak: Array, m: MissionManager.Masukan) -> MissionManager.Hasil:
	var h: MissionManager.Hasil = MissionManager.langkah(kotak[0], m)
	kotak[0] = h.keadaan
	return h


func _keadaan(rencana: RencanaMisi.Rencana = null) -> Array:
	return [MissionManager.awal(rencana if rencana != null else _rencana())]


func _tanpa_komentar_dan_ruang(teks: String) -> String:
	return teks.strip_edges()


# --- Config ---

func _test_config() -> void:
	_judul.call("Misi 4B: angka Config literal (AC-21, rule balancing)")
	var harapan: Dictionary = {
		"MISI_HADIAH_KOIN": [45, 75, 120], "MISI_TAMPIL_JARAK_UBIN": 12.0, "MISI_TAMPIL_PETUNJUK_JARAK_UBIN": 18.0, "MISI_TAMPIL_DETIK_MIN": 2.0,
		"MISI_TANGKAP_KECEPATAN_MAKS_UD": 1.5, "MISI_BANNER_DETIK": 1.5, "MISI_PETUNJUK_DETIK": 2.5, "MISI_BANNER_PANJANG_MAKS": 24,
		"MISI_KUCING_LATERAL_UBIN": -2.0, "MISI_KUCING_MAJU_UBIN": 0.5, "MISI_KUCING_GOYANG_LATERAL_UBIN": 0.25, "MISI_KUCING_GOYANG_MAJU_UBIN": 0.25, "SEED_MISI_SELISIH": 4093, "MISI_KUCING_JAUH_MOBIL_UBIN": 6.0,
		"MISI_TITIK_DIKENAL": ["atap", "bawah_mobil_tamu", "balik_pot"],
	}
	var peta: Dictionary = (load("res://scripts/config.gd") as GDScript).get_script_constant_map()
	for nama: String in harapan:
		check(peta.get(nama) == harapan[nama], "Config.%s = %s (literal), dapat %s" % [nama, harapan[nama], peta.get(nama)])
	check(Config.MISI_TANGKAP_KECEPATAN_MAKS_UD == Config.KECEPATAN_MELAMBAT_UD, "ambang kecepatan tangkap = kecepatan melambat (tingkat meluncur, M-4: tanpa tombol baru)")
	check(Config.MISI_TINGKAT_HADIAH.size() == Config.MISI_HADIAH_KOIN.size(), "tiap tingkat hadiah punya koin (sejajar)")
	check(SeedHari.misi(1) == SeedHari.rute(1) + 4093 and SeedHari.misi(7) == 21261103 + 6 * 1000003 + 4093, "SeedHari.misi(hari) = seed rute hari itu + 4093 (aliran acak sendiri)")


# --- Data (AC-1) ---

func _test_data_nyata() -> void:
	_judul.call("DataMisi Cari: berkas nyata p1_kucing lolos penuh (AC-1)")
	var kumpulan: PemuatMisi.Kumpulan = PemuatMisi.muat_folder(FOLDER_MISI)
	check(kumpulan.sah() and kumpulan.cari("p1_kucing") != null, "perumahan.json sah dan id p1_kucing tidak berubah: %s" % [kumpulan.galat])
	var m: DataMisi = _misi_nyata()
	check(m != null and m.template == "cari" and m.batas_rumah() == 12 and m.target_jumlah() == 1 and m.hadiah_koin() == 75, "p1: Cari, batas 12 rumah, target 1, hadiah tingkat sedang = 75 koin (K-1)")
	var langkah: Array[DataMisi.LangkahCari] = m.langkah_cari()
	var ok: bool = langkah.size() == 3
	if ok:
		ok = langkah[0].jenis == "lihat" and langkah[0].titik == "atap" and langkah[0].rumah_min == 3 and langkah[0].rumah_maks == 4
		ok = ok and langkah[1].jenis == "lihat" and langkah[1].titik == "bawah_mobil_tamu" and langkah[1].rumah_min == 3 and langkah[1].rumah_maks == 4
		ok = ok and langkah[2].jenis == "tangkap" and langkah[2].titik == "balik_pot" and langkah[2].radius_ubin == 2.0 and langkah[2].lama_berhenti_detik == 1.5
	check(ok, "langkah_cari: lihat atap [3,4], lihat bawah_mobil_tamu [3,4], tangkap balik_pot [3,4] radius 2,0 selama 1,5 detik")
	check(m.flag_selesai == "kucing_ketemu" and m.flag_gagal == "kucing_belum" and m.jeda == 7, "flag_lanjut kucing_ketemu / kucing_belum dan jeda 7 tidak berubah")
	check(m.banner_selesai == "MISI_P1_KUCING_SELESAI" and m.banner_gagal == "MISI_P1_KUCING_GAGAL", "banner selesai dan gagal berupa kunci terjemahan")
	var lain: DataMisi = DataMisi.new()
	check(lain.langkah_cari().is_empty() and lain.hadiah_koin() == 0 and lain.batas_rumah() == 0 and lain.target_jumlah() == 0, "misi kosong: tanpa langkah, hadiah 0")


func _test_data_cari_ditolak() -> void:
	_judul.call("DataMisi Cari: satu data buruk per aturan ditolak dengan galat yang jelas (AC-1)")
	check(_galat(_mentah()) == "", "kontrol: salinan berkas nyata tanpa perubahan sah")
	# Tiap kasus: nama, fungsi pengubah satu aturan, kata yang harus ada di galat.
	var kasus: Array = [
		["target.objek tidak dikenal", func(d: Dictionary) -> void: d["target"]["objek"] = "anjing", "target.objek"],
		["target.objek bukan teks", func(d: Dictionary) -> void: d["target"]["objek"] = 3, "target.objek"],
		["target.jumlah 0", func(d: Dictionary) -> void: d["target"]["jumlah"] = 0, "target.jumlah"],
		["target.jumlah pecahan", func(d: Dictionary) -> void: d["target"]["jumlah"] = 1.5, "target.jumlah"],
		["target.sisi tidak dikenal", func(d: Dictionary) -> void: d["target"]["sisi"] = "kiri", "target.sisi"],
		["target.sisi hilang", func(d: Dictionary) -> void: d["target"].erase("sisi"), "target.sisi wajib"],
		["target field asing", func(d: Dictionary) -> void: d["target"]["warna"] = "oren", "tidak dikenal"],
		["langkah hanya satu", func(d: Dictionary) -> void: d["langkah"] = [d["langkah"][2]], "paling sedikit 2"],
		["langkah jenis tak dikenal", func(d: Dictionary) -> void: d["langkah"][0]["jenis"] = "terbang", "jenis harus"],
		["langkah titik tak dikenal", func(d: Dictionary) -> void: d["langkah"][1]["titik"] = "sumur", "titik harus"],
		["langkah pertama tanpa rumah_dari_mulai", func(d: Dictionary) -> void: d["langkah"][0] = {"jenis": "lihat", "titik": "atap", "rumah_dari_sebelumnya": [3, 4]}, "rumah_dari_mulai wajib"],
		["langkah kedua memakai rumah_dari_mulai", func(d: Dictionary) -> void: d["langkah"][1] = {"jenis": "lihat", "titik": "atap", "rumah_dari_mulai": [3, 4]}, "rumah_dari_sebelumnya wajib"],
		["rentang min lebih besar dari maks", func(d: Dictionary) -> void: d["langkah"][0]["rumah_dari_mulai"] = [4, 3], "1 <= min <= maks"],
		["rentang min 0", func(d: Dictionary) -> void: d["langkah"][0]["rumah_dari_mulai"] = [0, 2], "1 <= min <= maks"],
		["rentang pecahan", func(d: Dictionary) -> void: d["langkah"][0]["rumah_dari_mulai"] = [2.5, 3], "bilangan bulat"],
		["rentang tiga angka", func(d: Dictionary) -> void: d["langkah"][0]["rumah_dari_mulai"] = [3, 4, 5], "[min, maks]"],
		["langkah terakhir bukan tangkap", func(d: Dictionary) -> void: d["langkah"][2] = {"jenis": "lihat", "titik": "balik_pot", "rumah_dari_sebelumnya": [3, 4]}, "langkah terakhir harus 'tangkap'"],
		["tangkap tanpa radius", func(d: Dictionary) -> void: d["langkah"][2].erase("radius_ubin"), "radius_ubin wajib"],
		["tangkap radius 0", func(d: Dictionary) -> void: d["langkah"][2]["radius_ubin"] = 0, "radius_ubin harus angka > 0"],
		["tangkap radius negatif", func(d: Dictionary) -> void: d["langkah"][2]["radius_ubin"] = -1.0, "radius_ubin harus angka > 0"],
		["tangkap tanpa lama", func(d: Dictionary) -> void: d["langkah"][2].erase("lama_berhenti_detik"), "lama_berhenti_detik wajib"],
		["tangkap lama 0", func(d: Dictionary) -> void: d["langkah"][2]["lama_berhenti_detik"] = 0, "lama_berhenti_detik harus angka > 0"],
		["lihat dengan radius", func(d: Dictionary) -> void: d["langkah"][0]["radius_ubin"] = 2.0, "hanya untuk langkah tangkap"],
		["jumlah tangkap tidak sama dengan target.jumlah", func(d: Dictionary) -> void: d["target"]["jumlah"] = 2, "target.jumlah"],
		["jumlah maks rentang melebihi batas.rumah", func(d: Dictionary) -> void: d["batas"]["rumah"] = 11, "melebihi batas.rumah"],
		["batas.rumah hilang", func(d: Dictionary) -> void: d["batas"] = {}, "batas.rumah wajib"],
		["batas.rumah 0", func(d: Dictionary) -> void: d["batas"]["rumah"] = 0, "batas.rumah harus"],
		["batas.rumah pecahan", func(d: Dictionary) -> void: d["batas"]["rumah"] = 12.5, "batas.rumah harus"],
		["batas field asing", func(d: Dictionary) -> void: d["batas"]["detik"] = 30, "tidak dikenal"],
		["petunjuk.visual kosong", func(d: Dictionary) -> void: d["petunjuk"]["visual"] = [], "petunjuk.visual harus daftar tidak kosong"],
		["petunjuk.visual tidak dikenal", func(d: Dictionary) -> void: d["petunjuk"]["visual"] = ["kilau", "api"], "petunjuk.visual memuat 'api'"],
		["petunjuk.suara tidak dikenal", func(d: Dictionary) -> void: d["petunjuk"]["suara"] = "gonggong", "petunjuk.suara"],
		["petunjuk.dari_pelanggan hilang", func(d: Dictionary) -> void: d["petunjuk"].erase("dari_pelanggan"), "petunjuk.dari_pelanggan wajib"],
		["petunjuk.dari_pelanggan kunci tidak ada", func(d: Dictionary) -> void: d["petunjuk"]["dari_pelanggan"] = "KUNCI_HILANG", "tidak ada"],
		["petunjuk field asing", func(d: Dictionary) -> void: d["petunjuk"]["bau"] = "x", "tidak dikenal"],
		["hadiah field asing", func(d: Dictionary) -> void: d["hadiah"]["koin"] = 75, "tidak dikenal"],
		["hadiah tingkat tidak dikenal", func(d: Dictionary) -> void: d["hadiah"]["tingkat"] = "raksasa", "hadiah.tingkat"],
		["banner hilang", func(d: Dictionary) -> void: d.erase("banner"), "banner"],
		["banner.gagal hilang", func(d: Dictionary) -> void: d["banner"].erase("gagal"), "gagal"],
		["banner kunci tidak ada", func(d: Dictionary) -> void: d["banner"]["selesai"] = "KUNCI_HILANG", "tidak ada"],
	]
	for butir: Array in kasus:
		var d: Dictionary = _mentah()
		(butir[1] as Callable).call(d)
		var g: String = _galat(d)
		check(g != "" and g.contains(butir[2]), "%s ditolak dengan galat yang menyebut '%s'; dapat '%s'" % [butir[0], butir[2], g])
		check(PemuatMisi.parse_teks(JSON.stringify([d]), "buruk.json").misi.is_empty(), "%s: misi tidak ikut dimuat (objek null)" % butir[0])
	# Panjang teks petunjuk (50) dan banner (24) pada teks hasil terjemahan: tepat di batas diterima, satu lebih ditolak.
	var tepat_petunjuk: String = "x".repeat(50)
	check(_galat(_mentah(), {"MISI_P1_KUCING_PETUNJUK": tepat_petunjuk}) == "", "petunjuk tepat 50 karakter diterima")
	check(_galat(_mentah(), {"MISI_P1_KUCING_PETUNJUK": tepat_petunjuk + "y"}).contains("lebih panjang dari 50"), "petunjuk 51 karakter ditolak")
	check(_galat(_mentah(), {"MISI_P1_KUCING_SELESAI": "A".repeat(24)}) == "", "banner selesai tepat 24 karakter diterima (CONTENT_GUIDE 3)")
	check(_galat(_mentah(), {"MISI_P1_KUCING_SELESAI": "A".repeat(25)}).contains("lebih panjang dari 24"), "banner selesai 25 karakter ditolak (panjang banner divalidasi)")
	check(_galat(_mentah(), {"MISI_P1_KUCING_GAGAL": "A".repeat(25)}).contains("lebih panjang dari 24"), "banner gagal 25 karakter ditolak")
	# Template lain tidak dipaksa memenuhi aturan Cari (target/langkah hanya diperiksa tipenya).
	var lain: Dictionary = _mentah()
	lain["template"] = "antar_khusus"
	lain["target"] = {}
	lain["langkah"] = []
	check(_galat(lain) == "", "template selain cari: target dan langkah kosong tetap lolos (aturan Cari hanya untuk Cari)")
	# Semua aturan terkumpul sekaligus (bukan berhenti di galat pertama).
	var banyak: Dictionary = _mentah()
	banyak["target"]["jumlah"] = 0
	banyak["batas"]["rumah"] = 0
	banyak["petunjuk"]["visual"] = []
	check(_galat(banyak).count(";") >= 2, "beberapa pelanggaran dilaporkan sekaligus: %s" % _galat(banyak))
	# Penguji teks kuantitatif dari CSV (oracle tes): banner nyata dan label kartu tidak melebihi batas.
	var csv: Dictionary = _csv_konten()
	check(String(csv["MISI_P1_KUCING_SELESAI"]).length() <= 24 and String(csv["MISI_P1_KUCING_GAGAL"]).length() <= 24, "teks banner nyata <= 24 karakter (hitung ulang tes dari CSV)")
	check(String(csv["MISI_P1_KUCING_HUD"]).length() <= 14 and String(csv["MISI_P1_KUCING_PETUNJUK"]).length() <= 50, "label HUD nyata <= 14 dan petunjuk <= 50 karakter")
	check(not String(csv["MISI_P1_KUCING_GAGAL"]).to_lower().contains("gagal") and not String(csv["MISI_P1_KUCING_GAGAL"]).to_lower().contains("salah"), "banner gagal tidak menyalahkan (tanpa kata 'gagal' atau 'salah')")


func _test_data_banner_dan_hadiah() -> void:
	_judul.call("DataMisi: hadiah per tingkat (K-1) dan teks kartu HUD (AC-2, AC-14)")
	for pasangan: Array in [["kecil", 45], ["sedang", 75], ["besar", 120]]:
		var d: Dictionary = _mentah()
		d["hadiah"]["tingkat"] = pasangan[0]
		var hasil: DataMisi.Hasil = DataMisi.parse(d)
		check(hasil.sah() and hasil.misi.hadiah_koin() == pasangan[1], "tingkat %s = %d koin (GDD 14.1: 45 / 75 / 120)" % [pasangan[0], pasangan[1]])
	var kartu: String = tr("MISI_KARTU").format({"label": tr("MISI_P1_KUCING_HUD"), "n": 0, "total": 1, "rumah": 8})
	check(kartu == "Kucing 0/1 · 8 rumah", "kartu HUD misi: 'Kucing 0/1 · 8 rumah' (DESIGN_SPEC 3.1), dapat '%s'" % kartu)
	check(tr("MISI_LABEL_KARTU") == "MISI SAMPINGAN" and tr("MISI_LABEL_KARTU").length() <= 14, "label kartu 'MISI SAMPINGAN' (<= 14 karakter)")
	check(tr("MISI_BANNER_HADIAH").format({"teks": tr("MISI_P1_KUCING_SELESAI"), "koin": 75}) == "Kucing ketemu! +75", "banner selesai membawa hadiah: 'Kucing ketemu! +75'")
	var rekap_ok: String = tr("HASIL_MISI_SELESAI").format({"teks": tr("MISI_P1_KUCING_SELESAI"), "koin": 75})
	var rekap_gagal: String = tr("HASIL_MISI_GAGAL").format({"teks": tr("MISI_P1_KUCING_GAGAL")})
	check(rekap_ok == "Misi: Kucing ketemu! +75 koin" and rekap_gagal == "Misi: Kucingnya lolos hari ini", "rekap hasil: 'Misi: Kucing ketemu! +75 koin' dan 'Misi: Kucingnya lolos hari ini'")


# --- Rencana (AC-4) ---

## Oracle: rumah seberang rute dihitung ulang tes (penyaringan sisi sendiri).
func _seberang(rute: RouteBuilder.Rute) -> Array:
	var hasil: Array = []
	for r: RouteBuilder.RumahRute in rute.rumah:
		if r.sisi == LoperAnim.Sisi.SEBERANG:
			hasil.append(r)
	return hasil


func _sidik_rencana(r: RencanaMisi.Rencana) -> String:
	var bagian: Array[String] = []
	for t: RencanaMisi.Titik in r.titik:
		bagian.append("%s:%d:%s:%s:%.2f:%.2f" % [t.jenis, t.indeks_rumah, t.id_rumah, t.nama, t.maju_ubin, t.lateral_ubin])
	return ",".join(bagian) + "|%.2f|%.2f|%d" % [r.maju_batas_ubin, r.panjang_ubin, r.jumlah_seberang]


func _sidik_rute(rute: RouteBuilder.Rute) -> String:
	var bagian: Array[String] = []
	for r: RouteBuilder.RumahRute in rute.rumah:
		bagian.append("%s@%.1f%d%d" % [r.id, r.maju_ubin, int(r.sisi), 1 if r.pelanggan else 0])
	for o: RouteBuilder.ObjekRute in rute.objek:
		bagian.append("%s@%.1f%s" % [o.jenis, o.maju_ubin, o.jalur])
	return ",".join(bagian) + "|" + str(rute.panjang_ubin)


func _test_rencana_enam_puluh_hari() -> void:
	_judul.call("RencanaMisi: 60 hari sah, deterministik, di rumah seberang, batas 12, tidak identik, tidak menimpa sasaran (AC-4, AC-12)")
	var misi: DataMisi = _misi_nyata()
	var sidik: Dictionary = {}
	var semua_sah: bool = true
	var deterministik: bool = true
	var rute_utuh: bool = true
	var dalam_rentang: bool = true
	var di_seberang: bool = true
	var tanpa_mobil: bool = true
	var tidak_menimpa: bool = true
	var batas_ok: bool = true
	var posisi_ok: bool = true
	var jendela_ok: bool = true
	var catatan: Array[String] = []
	for hari: int in range(1, 61):
		var hasil: RouteBuilder.Hasil = RouteBuilder.bangun(SeedHari.rute(hari), _pustaka())
		var rute: RouteBuilder.Rute = hasil.rute
		var sebelum: String = _sidik_rute(rute)
		var benih: int = SeedHari.misi(hari)
		var r1: RencanaMisi.Rencana = RencanaMisi.buat(misi, rute, benih)
		var r2: RencanaMisi.Rencana = RencanaMisi.buat(misi, rute, benih)
		if not r1.sah() or r1.titik.size() != 3:
			semua_sah = false
			catatan.append("hari %d tidak sah" % hari)
			continue
		sidik[_sidik_rencana(r1)] = true
		deterministik = deterministik and _sidik_rencana(r1) == _sidik_rencana(r2)
		rute_utuh = rute_utuh and _sidik_rute(rute) == sebelum
		var seberang: Array = _seberang(rute)
		var sebelumnya: int = 0
		for i: int in range(3):
			var t: RencanaMisi.Titik = r1.titik[i]
			var selisih: int = t.indeks_rumah - sebelumnya
			dalam_rentang = dalam_rentang and selisih >= 3 and selisih <= 4
			sebelumnya = t.indeks_rumah
			var rumah: RouteBuilder.RumahRute = seberang[t.indeks_rumah - 1]
			di_seberang = di_seberang and rumah.sisi == LoperAnim.Sisi.SEBERANG and rumah.id == t.id_rumah and is_equal_approx(t.maju_rumah_ubin, rumah.maju_ubin)
			var selisih_maju: float = t.maju_ubin - rumah.maju_ubin
			var laterals: Array[float] = [-2.25, -2.0, -1.75]
			var majus: Array[float] = [0.25, 0.5, 0.75]
			posisi_ok = posisi_ok and _anggota(selisih_maju, majus) and _anggota(t.lateral_ubin, laterals)
			for o: RouteBuilder.ObjekRute in rute.objek:
				if o.jenis == "mobil_garasi" and o.jalur == "seberang" and absf(o.maju_ubin - t.maju_ubin) < 6.0:
					tanpa_mobil = false
			var persegi: Rect2 = RencanaMisi.persegi_kucing(t)
			for zona: ZonaSasaran.Zona in ZonaSasaran.zona_rute(rute.rumah):
				if zona.jenis == ZonaSasaran.Jenis.KOTAK_SURAT and zona.pelanggan and zona.persegi.intersects(persegi):
					tidak_menimpa = false
			var awal_diharapkan: float = 0.0 if i == 0 else r1.titik[i - 1].maju_rumah_ubin
			jendela_ok = jendela_ok and is_equal_approx(t.petunjuk_awal_ubin, awal_diharapkan) and is_equal_approx(t.petunjuk_akhir_ubin, t.maju_rumah_ubin)
		batas_ok = batas_ok and r1.titik[2].indeks_rumah <= 12 and r1.batas_rumah == 12
		batas_ok = batas_ok and r1.jumlah_seberang == seberang.size() and r1.akhir_kavling_ubin.size() == 12
		batas_ok = batas_ok and is_equal_approx(r1.maju_batas_ubin, float((seberang[11] as RouteBuilder.RumahRute).maju_ubin) + 4.0)
	check(semua_sah, "rencana hari 1 sampai 60 sah, tiga titik: %s" % [catatan.slice(0, 3)])
	check(deterministik, "benih sama = rencana sama (dua kali buat per hari)")
	check(rute_utuh, "rencana tidak mengubah Rute (rumah, objek, panjang sama sebelum dan sesudah)")
	check(dalam_rentang, "selisih rumah tiap titik dalam rentang data [3,4] (indeks dihitung ulang tes dari rumah seberang)")
	check(di_seberang, "titik di rumah sisi seberang, id rumah dan awal kavling cocok dengan rumah seberang urutan ke-N")
	check(posisi_ok, "kucing di lateral -2,25 / -2,0 / -1,75 dan maju awal kavling + 0,25 / 0,5 / 0,75 (goyangan acak berseed, literal tes)")
	check(batas_ok, "titik terakhir <= rumah ke-12 (batas), maju_batas = akhir kavling rumah seberang ke-12 (kavling 4 ubin), 12 akhir kavling tercatat")
	check(tanpa_mobil, "tidak ada titik dalam 6 ubin dari mobil garasi seberang (60 seed)")
	check(tidak_menimpa, "persegi kucing tidak menimpa zona kotak surat pelanggan mana pun (60 seed)")
	check(jendela_ok, "jendela petunjuk titik ke-i = [rumah titik sebelumnya (0 untuk pertama), rumah titik ini)")
	check(sidik.size() == 60, "tidak ada dua rencana yang seluruhnya identik di 60 hari (%d rencana berbeda)" % sidik.size())
	# Rencana tanpa mengubah misi, dan benih lain menghasilkan variasi (bukan konstan).
	var rute1: RouteBuilder.Rute = RouteBuilder.bangun(SeedHari.rute(1), _pustaka()).rute
	var variasi: Dictionary = {}
	for benih: int in range(40):
		variasi[_sidik_rencana(RencanaMisi.buat(misi, rute1, benih))] = true
	check(variasi.size() >= 3, "40 benih pada rute yang sama menghasilkan sedikitnya 3 rencana berbeda (acak berseed, bukan konstan): %d" % variasi.size())


func _rute_sintetis(jumlah_seberang: int, mobil_pada: Array[float] = []) -> RouteBuilder.Rute:
	var rute: RouteBuilder.Rute = RouteBuilder.Rute.new()
	rute.panjang_ubin = float(jumlah_seberang * 6 + 20)
	for i: int in range(jumlah_seberang):
		var r: RouteBuilder.RumahRute = RouteBuilder.RumahRute.new()
		r.id = "x@%d" % i
		r.sisi = LoperAnim.Sisi.SEBERANG
		r.maju_ubin = float(2 + 6 * i)
		rute.rumah.append(r)
		var d: RouteBuilder.RumahRute = RouteBuilder.RumahRute.new()
		d.id = "d@%d" % i
		d.sisi = LoperAnim.Sisi.DEKAT
		d.maju_ubin = float(4 + 6 * i)
		rute.rumah.append(d)
	for m: float in mobil_pada:
		var o: RouteBuilder.ObjekRute = RouteBuilder.ObjekRute.new()
		o.jenis = "mobil_garasi"
		o.jalur = "seberang"
		o.maju_ubin = m
		rute.objek.append(o)
	return rute


func _anggota(nilai: float, daftar: Array[float]) -> bool:
	for x: float in daftar:
		if is_equal_approx(nilai, x):
			return true
	return false


func _test_rencana_menghindari_mobil() -> void:
	_judul.call("RencanaMisi: titik menghindari mobil garasi seberang, rumah dekat tidak dihitung (AC-4)")
	var misi: DataMisi = _misi_nyata()
	# Rumah seberang di maju 2, 8, 14, ... (6 ubin sekali). Mobil di maju 26,5 (rumah ke-5): rumah ke-4, 5, 6 terlalu dekat (< 6,25 dari mobil), jadi
	# titik pertama harus rumah ke-3 dan titik kedua rumah ke-7 (mundur dari pilihan acak yang terblokir).
	var rute: RouteBuilder.Rute = _rute_sintetis(14, [26.5])
	var dipakai_4: bool = false
	var semua_sah: bool = true
	for benih: int in range(60):
		var r: RencanaMisi.Rencana = RencanaMisi.buat(misi, rute, benih)
		semua_sah = semua_sah and r.sah()
		for t: RencanaMisi.Titik in r.titik:
			dipakai_4 = dipakai_4 or absf(t.maju_ubin - 26.5) < 6.0
	check(semua_sah and not dipakai_4, "60 benih: rencana tetap sah (mundur dari pilihan terblokir) dan tidak ada titik dalam 6 ubin dari mobil seberang di maju 26,5")
	# Rumah dekat tidak dihitung sebagai "rumah" misi: indeks mengacu rumah seberang saja.
	var r_satu: RencanaMisi.Rencana = RencanaMisi.buat(misi, _rute_sintetis(14), 7)
	var maju_seberang_sah: bool = true
	for t: RencanaMisi.Titik in r_satu.titik:
		maju_seberang_sah = maju_seberang_sah and (t.maju_rumah_ubin - 2.0) / 6.0 == float(t.indeks_rumah - 1) and t.id_rumah.begins_with("x@")
	check(maju_seberang_sah, "indeks rumah menghitung rumah seberang saja (rumah dekat dilewati)")
	# Mobil di jalur dekat tidak memengaruhi, mobil jauh tidak memengaruhi.
	var rute_dekat: RouteBuilder.Rute = _rute_sintetis(14)
	var o: RouteBuilder.ObjekRute = RouteBuilder.ObjekRute.new()
	o.jenis = "mobil_garasi"
	o.jalur = "dekat"
	o.maju_ubin = 20.5
	rute_dekat.objek.append(o)
	var anjing: RouteBuilder.ObjekRute = RouteBuilder.ObjekRute.new()
	anjing.jenis = "anjing_penjaga"
	anjing.jalur = "seberang"
	anjing.maju_ubin = 20.5
	rute_dekat.objek.append(anjing)
	check(RencanaMisi.buat(misi, rute_dekat, 7).titik.size() == RencanaMisi.buat(misi, _rute_sintetis(14), 7).titik.size() and _sidik_rencana(RencanaMisi.buat(misi, rute_dekat, 7)) == _sidik_rencana(RencanaMisi.buat(misi, _rute_sintetis(14), 7)), "mobil di jalur dekat dan anjing seberang tidak mengubah rencana (hanya mobil garasi seberang)")
	# Rumah yang pasti terblokir (mobil di tiap rumah ke-3 dan ke-4): mundur ke pilihan lain atau rencana tidak sah, tidak pernah titik di dekat mobil.
	var mobil_banyak: RouteBuilder.Rute = _rute_sintetis(14, [14.5, 20.5, 26.5, 32.5, 38.5])
	var r_banyak: RencanaMisi.Rencana = RencanaMisi.buat(misi, mobil_banyak, 3)
	var jauh: bool = r_banyak.sah() or r_banyak.titik.is_empty()
	for t: RencanaMisi.Titik in r_banyak.titik:
		for m: float in [14.5, 20.5, 26.5, 32.5, 38.5]:
			jauh = jauh and absf(t.maju_ubin - m) >= 6.0
	check(jauh, "banyak mobil: kalaupun rencana ditemukan, tidak ada titik dalam 6 ubin dari mobil")


func _test_rencana_tidak_sah() -> void:
	_judul.call("RencanaMisi: tidak ada susunan sah = rencana kosong, bukan crash")
	var misi: DataMisi = _misi_nyata()
	check(not RencanaMisi.buat(misi, _rute_sintetis(5), 1).sah(), "rumah seberang kurang dari yang dibutuhkan: rencana tidak sah")
	check(not RencanaMisi.buat(null, _rute_sintetis(14), 1).sah() and not RencanaMisi.buat(misi, null, 1).sah(), "misi null atau rute null: rencana tidak sah")
	var bukan_cari: Dictionary = _mentah()
	bukan_cari["template"] = "kumpul"
	var hasil: DataMisi.Hasil = DataMisi.parse(bukan_cari)
	check(not RencanaMisi.buat(hasil.misi, _rute_sintetis(14), 1).sah(), "template selain Cari: tidak ada rencana")
	# Rute dengan tepat 10 rumah seberang: batas 12 tidak bisa dicapai, batas = akhir rute; titik tetap dalam rumah yang ada.
	var pendek: RencanaMisi.Rencana = RencanaMisi.buat(misi, _rute_sintetis(10), 3)
	if pendek.sah():
		check(pendek.titik[2].indeks_rumah <= 10 and is_equal_approx(pendek.maju_batas_ubin, pendek.panjang_ubin), "rute 10 rumah seberang: titik <= rumah ke-10 dan batas = akhir rute")
	else:
		check(true, "rute 10 rumah seberang: rencana tidak sah diterima (rentang 3-4 x 3 tidak muat)")
	var sah_luas: RencanaMisi.Rencana = RencanaMisi.buat(misi, _rute_sintetis(14), 3)
	check(sah_luas.sah() and sah_luas.hadiah_koin == 75 and sah_luas.target == 1 and sah_luas.id_misi == "p1_kucing", "rencana membawa id misi, hadiah 75 koin, dan target 1")
	var kosong: RencanaMisi.Rencana = RencanaMisi.Rencana.new()
	check(not kosong.sah(), "Rencana baru (kosong) tidak sah")


# --- MissionManager: lihat dan jendela tampil (AC-5a) ---

func _test_manager_lihat_dan_jendela() -> void:
	_judul.call("MissionManager: lihat selesai bila kucing sudah tampil dan dilewati; jendela tampil >= 2,0 detik pada ngebut (AC-5a)")
	var k: Array = _keadaan()
	var h: MissionManager.Hasil = _langkah(k, _masukan(7.9))
	check(h.kejadian.is_empty() and MissionManager.kucing_tampil(k[0]) == -1, "maju 7,9 (kucing di 20, jarak tampil 12): belum tampil, tanpa peristiwa")
	h = _langkah(k, _masukan(8.0))
	check(h.ada(MissionManager.Peristiwa.TERLIHAT) and h.jumlah(MissionManager.Peristiwa.TERLIHAT) == 1 and MissionManager.kucing_tampil(k[0]) == 0, "maju 8,0 tepat (inklusif): kucing titik 1 tampil, satu peristiwa TERLIHAT")
	h = _langkah(k, _masukan(12.0))
	check(h.kejadian.is_empty(), "TERLIHAT tidak berulang untuk kucing yang sama")
	h = _langkah(k, _masukan(19.99))
	check(not h.ada(MissionManager.Peristiwa.LANGKAH_SELESAI) and k[0].langkah == 0, "maju 19,99: kucing belum dilewati, langkah lihat belum selesai")
	h = _langkah(k, _masukan(20.0))
	check(h.ada(MissionManager.Peristiwa.LANGKAH_SELESAI) and k[0].langkah == 1 and k[0].status == MissionManager.Status.AKTIF, "maju 20,0: kucing dilewati, langkah lihat 1 selesai, langkah 2 aktif")
	check(MissionManager.kucing_tampil(k[0]) == -1, "kucing titik 1 hilang sesudah dilewati; titik 2 belum tampil")
	# Loncat jauh melewati dua kucing lihat sekaligus: keduanya selesai berurutan (kucing sempat 'tampil' di langkah yang sama).
	var k2: Array = _keadaan()
	h = _langkah(k2, _masukan(45.0))
	check(h.jumlah(MissionManager.Peristiwa.LANGKAH_SELESAI) == 2 and h.jumlah(MissionManager.Peristiwa.TERLIHAT) == 2 and k2[0].langkah == 2, "loncat ke maju 45: dua langkah lihat selesai berurutan, dua kucing sempat terlihat (ketiga baru tampil di 48); dapat %d selesai" % h.jumlah(MissionManager.Peristiwa.LANGKAH_SELESAI))
	# Jendela tampil: simulasi per langkah waktu pada KECEPATAN_NGEBUT (6,0 u/d): lama kucing terlihat sebelum dilewati.
	var k3: Array = _keadaan()
	var maju: float = 0.0
	var frame_terlihat: int = -1
	var frame_lewat: int = -1
	var frame: int = 0
	while frame_lewat < 0 and frame < 2000:
		maju += 6.0 * DT
		var hh: MissionManager.Hasil = _langkah(k3, _masukan(maju, -1.0, 6.0))
		if hh.ada(MissionManager.Peristiwa.TERLIHAT) and frame_terlihat < 0:
			frame_terlihat = frame
		if hh.ada(MissionManager.Peristiwa.LANGKAH_SELESAI) and frame_lewat < 0:
			frame_lewat = frame
		frame += 1
	var lama: float = float(frame_lewat - frame_terlihat) * DT
	check(frame_terlihat >= 0 and frame_lewat > frame_terlihat and lama >= 2.0 - DT, "ngebut 6,0 u/d: kucing terlihat %.3f detik sebelum dilewati (>= 2,0 detik, prinsip 3)" % lama)
	check(MissionManager.detik_tampil_min() >= Config.MISI_TAMPIL_DETIK_MIN - 0.000001 and is_equal_approx(MissionManager.detik_tampil_min(), 12.0 / 6.0), "detik_tampil_min() = 12 / 6,0 = 2,0 dan >= MISI_TAMPIL_DETIK_MIN")
	check(MissionManager.detik_tampil(3.0) == 4.0 and MissionManager.detik_tampil(0.0) == INF and MissionManager.detik_tampil(6.0, true) == 3.0, "detik_tampil: 12 / 3 = 4 detik, diam = tak hingga, dengan petunjuk 18 / 6 = 3 detik")
	# Kucing tidak pernah tampil bila misi tidak aktif lagi, dan keadaan tanpa rencana tidak crash.
	var kosong: Array = [MissionManager.awal(null)]
	var hk: MissionManager.Hasil = _langkah(kosong, _masukan(10.0))
	check(hk.kejadian.is_empty() and not MissionManager.kartu_tampil(kosong[0]), "tanpa rencana: tidak ada peristiwa dan kartu tidak tampil")
	var nan: Array = _keadaan()
	var hn: MissionManager.Hasil = _langkah(nan, _masukan(NAN))
	check(hn.kejadian.is_empty() and nan[0].status == MissionManager.Status.AKTIF, "posisi NaN diabaikan tanpa crash")


# --- Petunjuk (AC-5b, K-3) ---

func _test_manager_petunjuk() -> void:
	_judul.call("MissionManager: petunjuk hanya dari lemparan tepat di jendela langkah, sekali per langkah, bukan dari bantu (AC-5b, K-3)")
	var m: MissionManager.Masukan = _masukan(5.0)
	m.lemparan.append(_lemparan(10.0))
	var k: Array = _keadaan()
	var h: MissionManager.Hasil = _langkah(k, m)
	check(h.jumlah(MissionManager.Peristiwa.PETUNJUK) == 1 and k[0].petunjuk[0] and MissionManager.petunjuk_tampil(k[0]), "lemparan tepat ke rumah di jendela langkah 1: satu PETUNJUK, gelembung tampil")
	check(is_equal_approx(k[0].petunjuk_sisa, 2.5) and k[0].petunjuk_sisa >= 2.0, "gelembung petunjuk bertahan 2,5 detik (>= 2 detik, prinsip 3)")
	var m2: MissionManager.Masukan = _masukan(5.5)
	m2.lemparan.append(_lemparan(12.0))
	h = _langkah(k, m2)
	check(h.jumlah(MissionManager.Peristiwa.PETUNJUK) == 0, "petunjuk tidak berulang pada langkah yang sama (sekali per langkah)")
	# Syarat satu per satu (tiap mutan syarat harus terlihat): bukan tepat, bantu, bukan kotak pelanggan, di luar jendela.
	var ditolak: Array = [
		["lemparan tidak tepat", _lemparan(10.0, false)],
		["lemparan mode bantu (tap), walau tepat (K-3)", _lemparan(10.0, true, true)],
		["bukan kotak surat pelanggan", _lemparan(10.0, true, false, false)],
		["rumah sebelum jendela (maju -1)", _lemparan(-1.0)],
		["rumah tepat di akhir jendela (eksklusif, 19,5)", _lemparan(19.5)],
		["rumah sesudah jendela (30)", _lemparan(30.0)],
	]
	for butir: Array in ditolak:
		var kk: Array = _keadaan()
		var mm: MissionManager.Masukan = _masukan(5.0)
		mm.lemparan.append(butir[1])
		var hh: MissionManager.Hasil = _langkah(kk, mm)
		check(hh.jumlah(MissionManager.Peristiwa.PETUNJUK) == 0 and not kk[0].petunjuk[0], "%s: tidak memberi petunjuk" % butir[0])
	var batas_awal: Array = _keadaan()
	var mb: MissionManager.Masukan = _masukan(5.0)
	mb.lemparan.append(_lemparan(0.0))
	check(_langkah(batas_awal, mb).jumlah(MissionManager.Peristiwa.PETUNJUK) == 1, "rumah tepat di awal jendela (0,0, inklusif) memberi petunjuk")
	# Kucing sudah tampil: petunjuk tidak diberikan lagi (kucing sudah terlihat).
	var sudah: Array = _keadaan()
	_langkah(sudah, _masukan(9.0))
	var ms: MissionManager.Masukan = _masukan(9.5)
	ms.lemparan.append(_lemparan(10.0))
	check(_langkah(sudah, ms).jumlah(MissionManager.Peristiwa.PETUNJUK) == 0, "kucing langkah ini sudah tampil: tidak ada petunjuk")
	# Petunjuk membuat kucing tampil lebih awal (18 vs 12 ubin).
	var awal: Array = _keadaan()
	var mp: MissionManager.Masukan = _masukan(0.5)
	mp.lemparan.append(_lemparan(10.0))
	var hp: MissionManager.Hasil = _langkah(awal, mp)
	check(hp.jumlah(MissionManager.Peristiwa.PETUNJUK) == 1 and MissionManager.kucing_tampil(awal[0]) == -1, "petunjuk di maju 0,5: kucing (20) belum tampil (batas 18 -> maju 2,0)")
	_langkah(awal, _masukan(1.99))
	check(MissionManager.kucing_tampil(awal[0]) == -1, "dengan petunjuk: maju 1,99 belum tampil")
	var ht: MissionManager.Hasil = _langkah(awal, _masukan(2.0))
	check(ht.ada(MissionManager.Peristiwa.TERLIHAT) and MissionManager.kucing_tampil(awal[0]) == 0, "dengan petunjuk: tampil tepat di maju 2,0 (20 - 18), lebih awal dari 8,0 tanpa petunjuk")
	# Petunjuk langkah berikut memakai jendela langkah itu; lemparan untuk jendela langkah 2 saat langkah 1 aktif tidak memberi petunjuk.
	var dua: Array = _keadaan()
	var md: MissionManager.Masukan = _masukan(5.0)
	md.lemparan.append(_lemparan(30.0))
	check(_langkah(dua, md).jumlah(MissionManager.Peristiwa.PETUNJUK) == 0 and not dua[0].petunjuk[1], "lemparan di jendela langkah 2 saat langkah 1 aktif: belum petunjuk (jendela = langkah aktif)")
	_langkah(dua, _masukan(20.0))
	var m3: MissionManager.Masukan = _masukan(21.0)
	m3.lemparan.append(_lemparan(30.0))
	var h3: MissionManager.Hasil = _langkah(dua, m3)
	check(h3.jumlah(MissionManager.Peristiwa.PETUNJUK) == 1 and dua[0].petunjuk[1], "langkah 2 aktif: lemparan tepat di jendela [19,5, 39,5) memberi petunjuk langkah 2")
	# Sesudah selesai atau gagal tidak ada petunjuk baru.
	var selesai: Array = _keadaan(_rencana(30.0))
	_langkah(selesai, _masukan(40.0))
	var ma: MissionManager.Masukan = _masukan(41.0)
	ma.lemparan.append(_lemparan(30.0))
	check(selesai[0].status == MissionManager.Status.GAGAL and _langkah(selesai, ma).jumlah(MissionManager.Peristiwa.PETUNJUK) == 0, "sesudah gagal: lemparan tepat tidak memberi petunjuk")
	# Gelembung petunjuk berkurang oleh dt dan membeku saat jeda.
	var gel: Array = _keadaan()
	var mg: MissionManager.Masukan = _masukan(1.0)
	mg.lemparan.append(_lemparan(10.0))
	_langkah(gel, mg)
	_langkah(gel, _masukan(1.0, -1.0, 3.0, 1.0))
	check(is_equal_approx(gel[0].petunjuk_sisa, 1.5), "gelembung berkurang sebesar dt (2,5 - 1,0 = 1,5)")
	var mj: MissionManager.Masukan = _masukan(1.0, -1.0, 3.0, 1.0)
	mj.jeda = true
	_langkah(gel, mj)
	check(is_equal_approx(gel[0].petunjuk_sisa, 1.5), "saat jeda game gelembung membeku")
	_langkah(gel, _masukan(1.0, -1.0, 3.0, 2.0))
	check(not MissionManager.petunjuk_tampil(gel[0]), "gelembung habis sesudah 2,5 detik waktu efektif")


# --- Tangkap (AC-5c) ---

## Menjalankan `n` langkah ber-`dt` pada masukan yang sama; mengembalikan semua hasil terakhir.
func _ulang(kotak: Array, n: int, lateral: float, maju: float, kec: float, dt: float, jatuh: bool = false, jeda: bool = false) -> MissionManager.Hasil:
	var terakhir: MissionManager.Hasil = null
	for i: int in range(n):
		var m: MissionManager.Masukan = _masukan(maju, lateral, kec, dt)
		m.jatuh = jatuh
		m.jeda = jeda
		terakhir = _langkah(kotak, m)
	return terakhir


func _siap_tangkap() -> Array:
	var k: Array = _keadaan()
	_langkah(k, _masukan(50.0))
	return k


func _test_manager_tangkap_ambang() -> void:
	_judul.call("MissionManager: tangkap berturut-turut, ambang radius dan kecepatan inklusif, reset saat keluar (AC-5c, M-4)")
	# Pemain di (lateral -2, maju 60) = tepat di kucing. dt 0,5: tiga langkah = 1,5 detik tepat (>=).
	var k: Array = _siap_tangkap()
	check(k[0].langkah == 2 and MissionManager.kucing_tampil(k[0]) == 2, "kucing titik 3 (tangkap) tampil dan aktif sesudah dua langkah lihat")
	var h: MissionManager.Hasil = _ulang(k, 2, -2.0, 60.0, 0.0, 0.5)
	check(h.kejadian.is_empty() and is_equal_approx(k[0].timer_detik, 1.0), "1,0 detik berturut-turut: belum tertangkap (timer 1,0)")
	h = _ulang(k, 1, -2.0, 60.0, 0.0, 0.5)
	check(h.ada(MissionManager.Peristiwa.TERTANGKAP) and h.ada(MissionManager.Peristiwa.LANGKAH_SELESAI) and k[0].status == MissionManager.Status.SELESAI, "tepat 1,5 detik (>=): TERTANGKAP, langkah selesai, misi SELESAI")
	check(k[0].ditangkap == 1 and MissionManager.ditemukan(k[0]) == Vector2i(1, 1), "ditemukan 1/1")
	# Satu langkah waktu di sisi salah: 1,49 detik tidak cukup.
	var k2: Array = _siap_tangkap()
	h = _ulang(k2, 2, -2.0, 60.0, 0.0, 0.5)
	h = _ulang(k2, 1, -2.0, 60.0, 0.0, 0.49)
	check(not h.ada(MissionManager.Peristiwa.TERTANGKAP) and k2[0].status == MissionManager.Status.AKTIF, "1,49 detik: belum tertangkap (satu langkah di sisi salah ambang waktu)")
	# Reset saat keluar radius: dua langkah di dalam, satu di luar, dua di dalam = tidak tertangkap; tiga di dalam sesudahnya = tertangkap.
	var k3: Array = _siap_tangkap()
	_ulang(k3, 2, -2.0, 60.0, 0.0, 0.5)
	_ulang(k3, 1, -2.0, 63.0, 0.0, 0.5)
	check(is_equal_approx(k3[0].timer_detik, 0.0), "keluar radius: timer kembali 0")
	h = _ulang(k3, 2, -2.0, 60.0, 0.0, 0.5)
	check(not h.ada(MissionManager.Peristiwa.TERTANGKAP), "dua langkah di dalam sesudah reset: belum (tidak berturut-turut sejak awal)")
	h = _ulang(k3, 1, -2.0, 60.0, 0.0, 0.5)
	check(h.ada(MissionManager.Peristiwa.TERTANGKAP), "tiga langkah berturut-turut sesudah reset: tertangkap")
	# Reset saat terlalu cepat.
	var k4: Array = _siap_tangkap()
	_ulang(k4, 2, -2.0, 60.0, 1.0, 0.5)
	_ulang(k4, 1, -2.0, 60.0, 3.0, 0.5)
	check(is_equal_approx(k4[0].timer_detik, 0.0), "kecepatan di atas ambang: timer kembali 0")
	# Radius inklusif: jarak tepat 2,0 masuk, 2,001 keluar. Kecepatan 1,5 masuk, 1,51 keluar.
	var k5: Array = _siap_tangkap()
	_ulang(k5, 1, -2.0, 62.0, 0.0, 0.5)
	check(is_equal_approx(k5[0].timer_detik, 0.5), "jarak tepat 2,0 ubin (maju +2,0): di dalam radius (inklusif)")
	_ulang(k5, 1, -2.0, 62.01, 0.0, 0.5)
	check(is_equal_approx(k5[0].timer_detik, 0.0), "jarak 2,01 ubin: di luar radius")
	var k6: Array = _siap_tangkap()
	_ulang(k6, 1, -2.0, 60.0, 1.5, 0.5)
	check(is_equal_approx(k6[0].timer_detik, 0.5), "kecepatan tepat 1,5 u/d: boleh (<= ambang, inklusif)")
	_ulang(k6, 1, -2.0, 60.0, 1.51, 0.5)
	check(is_equal_approx(k6[0].timer_detik, 0.0), "kecepatan 1,51 u/d: terlalu cepat, timer 0")
	# Jarak dihitung dua sumbu (lateral dan maju): (lateral 0 = 2,0 dari -2) masuk, (lateral 0, maju +1) keluar.
	var k7: Array = _siap_tangkap()
	_ulang(k7, 1, 0.0, 60.0, 0.0, 0.5)
	check(is_equal_approx(k7[0].timer_detik, 0.5), "lateral 0 (jarak 2,0 dari kucing di -2): di dalam radius")
	_ulang(k7, 1, 0.0, 61.0, 0.0, 0.5)
	check(is_equal_approx(k7[0].timer_detik, 0.0), "lateral 0 dan maju +1 (jarak 2,24): di luar radius (dua sumbu)")
	var k8: Array = _siap_tangkap()
	_ulang(k8, 1, 1.0, 60.0, 0.0, 0.5)
	check(is_equal_approx(k8[0].timer_detik, 0.0), "dari lajur dekat (lateral +1, jarak 3,0): tidak bisa menangkap")
	# Dengan dt kecil realistis (1/60) 90 langkah mencapai 1,5 detik (toleransi derau float).
	var k9: Array = _siap_tangkap()
	var langkah_ke: int = 0
	var tertangkap: bool = false
	while not tertangkap and langkah_ke < 200:
		var hh: MissionManager.Hasil = _ulang(k9, 1, -2.0, 60.0, 0.0, DT)
		tertangkap = hh.ada(MissionManager.Peristiwa.TERTANGKAP)
		langkah_ke += 1
	check(tertangkap and langkah_ke == 90, "dt 1/60: tertangkap pada langkah ke-90 (1,5 detik) dengan toleransi derau float; dapat langkah %d" % langkah_ke)
	# Kucing harus sudah tampil: tangkap tidak berlaku sebelum kucing titik 3 terlihat (langkah lihat belum selesai).
	var belum: Array = _keadaan()
	var hb: MissionManager.Hasil = _ulang(belum, 5, -2.0, 60.0, 0.0, 0.5)
	check(hb.jumlah(MissionManager.Peristiwa.TERTANGKAP) == 0 or belum[0].langkah >= 2, "loncatan langsung ke titik 3: langkah lihat dilewati berurutan sebelum tangkap dihitung")


func _test_manager_tangkap_jatuh_jeda() -> void:
	_judul.call("MissionManager: saat jatuh dan saat jeda timer tidak maju dan tidak direset (AC-5c, M-4)")
	var k: Array = _siap_tangkap()
	_ulang(k, 2, -2.0, 60.0, 0.0, 0.5)
	_ulang(k, 3, -2.0, 60.0, 0.0, 0.5, true)
	check(is_equal_approx(k[0].timer_detik, 1.0), "tiga langkah jatuh di dalam radius: timer tetap 1,0 (tidak maju, tidak direset)")
	var h: MissionManager.Hasil = _ulang(k, 1, -2.0, 60.0, 0.0, 0.5)
	check(h.ada(MissionManager.Peristiwa.TERTANGKAP), "sesudah bangun satu langkah lagi: 1,0 + 0,5 = 1,5 tertangkap")
	var k2: Array = _siap_tangkap()
	_ulang(k2, 2, -2.0, 60.0, 0.0, 0.5)
	_ulang(k2, 4, -2.0, 70.0, 5.0, 0.5, true)
	check(is_equal_approx(k2[0].timer_detik, 1.0), "jatuh di luar radius dan terlalu cepat: timer tetap tidak direset")
	var k3: Array = _siap_tangkap()
	_ulang(k3, 2, -2.0, 60.0, 0.0, 0.5)
	_ulang(k3, 4, -2.0, 60.0, 0.0, 0.5, false, true)
	check(is_equal_approx(k3[0].timer_detik, 1.0) and k3[0].status == MissionManager.Status.AKTIF, "empat langkah saat jeda game: timer tetap 1,0 dan misi aktif")
	_ulang(k3, 1, -2.0, 60.0, 0.0, 0.5)
	check(k3[0].status == MissionManager.Status.SELESAI, "lanjut dari jeda: 1,0 + 0,5 menyelesaikan misi")
	# dt 0 (jeda game memberi dt efektif 0) tidak memajukan timer walau syarat terpenuhi.
	var k4: Array = _siap_tangkap()
	_ulang(k4, 10, -2.0, 60.0, 0.0, 0.0)
	check(is_equal_approx(k4[0].timer_detik, 0.0), "dt 0: timer tidak maju")
	_ulang(k4, 1, -2.0, 60.0, 0.0, NAN)
	check(is_equal_approx(k4[0].timer_detik, 0.0), "dt NaN: timer tidak maju (tidak crash)")


# --- Gagal (AC-5d, M-5) ---

func _test_manager_gagal() -> void:
	_judul.call("MissionManager: gagal bila rumah ke-12 terlewati atau rute berakhir; tidak menyentuh koin/tip/skor (AC-5d, M-5)")
	var k: Array = _keadaan()
	var h: MissionManager.Hasil = _langkah(k, _masukan(95.99))
	check(h.jumlah(MissionManager.Peristiwa.GAGAL) == 0 and k[0].status == MissionManager.Status.AKTIF, "maju 95,99 (akhir kavling rumah ke-12 = 96): belum gagal")
	check(k[0].dilewati == 11 and MissionManager.sisa_rumah(k[0]) == 1, "sisa rumah 1 sebelum rumah ke-12 terlewati (12 - 11 dilewati)")
	h = _langkah(k, _masukan(96.0))
	check(h.jumlah(MissionManager.Peristiwa.GAGAL) == 1 and k[0].status == MissionManager.Status.GAGAL, "maju 96,0: rumah ke-12 terlewati, tepat satu GAGAL")
	check(MissionManager.sisa_rumah(k[0]) == 0 and MissionManager.nama_hasil(k[0]) == "gagal", "sisa rumah 0 dan hasil 'gagal'")
	check(MissionManager.koin_misi(k[0]) == 0 and not MissionManager.kartu_tampil(k[0]), "gagal: koin misi 0 dan kartu hilang")
	check(is_equal_approx(k[0].banner_sisa, 1.5) and MissionManager.banner_tampil(k[0]), "banner gagal tampil 1,5 detik (MISI_BANNER_DETIK)")
	h = _langkah(k, _masukan(97.0))
	check(h.kejadian.is_empty(), "sesudah gagal tidak ada peristiwa baru (GAGAL tidak berulang)")
	var h2: MissionManager.Hasil = _ulang(k, 3, -2.0, 60.0, 0.0, 0.5)
	check(h2.jumlah(MissionManager.Peristiwa.TERTANGKAP) == 0 and k[0].status == MissionManager.Status.GAGAL, "sesudah gagal, berhenti di dekat kucing tidak menangkap")
	# Rute berakhir sebelum selesai: batas di luar rute.
	var k2: Array = _keadaan(_rencana(500.0, 100.0))
	h = _langkah(k2, _masukan(99.9))
	check(h.jumlah(MissionManager.Peristiwa.GAGAL) == 0, "maju 99,9 di rute 100: belum gagal")
	h = _langkah(k2, _masukan(100.0))
	check(h.jumlah(MissionManager.Peristiwa.GAGAL) == 1 and k2[0].status == MissionManager.Status.GAGAL, "garis akhir rute (100) tercapai sebelum selesai: GAGAL")
	# Tangkap yang selesai pada langkah yang sama dengan melewati batas menang (tangkap diproses dulu).
	var k3: Array = _keadaan(_rencana(60.4, 200.0))
	_langkah(k3, _masukan(45.0))
	_ulang(k3, 2, -2.0, 60.0, 0.0, 0.5)
	var h3: MissionManager.Hasil = _ulang(k3, 1, -2.0, 60.4, 0.0, 0.5)
	check(h3.ada(MissionManager.Peristiwa.TERTANGKAP) and not h3.ada(MissionManager.Peristiwa.GAGAL) and k3[0].status == MissionManager.Status.SELESAI, "tertangkap pada langkah yang sama dengan melewati batas: selesai, bukan gagal")
	# Invarian prinsip 2: kelas ini tidak punya akses ke koin/tip/skor; hasil gagal hanya status, hadiah 0.
	var sk: SkorRute.Keadaan = SkorRute.awal()
	sk.koin = 300
	sk.koin_tip = 40
	sk.skor = 1200
	var koin_sebelum: int = sk.koin
	var g: Array = _keadaan()
	_langkah(g, _masukan(300.0))
	check(g[0].status == MissionManager.Status.GAGAL and sk.koin == koin_sebelum and sk.koin_tip == 40 and sk.skor == 1200 and MissionManager.koin_misi(g[0]) == 0, "misi gagal tidak mengubah koin, tip, atau skor rute dan tidak membayar hadiah")
	# Jarak dilewati dihitung dari akhir kavling rumah.
	var d: Array = _keadaan()
	_langkah(d, _masukan(8.0))
	check(d[0].dilewati == 1 and MissionManager.sisa_rumah(d[0]) == 11, "akhir kavling rumah ke-1 (8) dilewati: sisa 11")
	_langkah(d, _masukan(40.0))
	check(d[0].dilewati == 5 and MissionManager.sisa_rumah(d[0]) == 7, "maju 40: lima rumah dilewati, sisa 7")


# --- Selesai sekali dan banner ---

func _test_manager_selesai_sekali_dan_banner() -> void:
	_judul.call("MissionManager: selesai tepat sekali, hadiah, banner 1,5 detik membeku saat jeda (AC-5e, AC-13)")
	var k: Array = _siap_tangkap()
	var terhitung: int = 0
	for i: int in range(40):
		var h: MissionManager.Hasil = _ulang(k, 1, -2.0, 60.0, 0.0, 0.5)
		terhitung += h.jumlah(MissionManager.Peristiwa.TERTANGKAP)
	check(terhitung == 1 and k[0].ditangkap == 1, "TERTANGKAP muncul tepat sekali walau pemain terus berhenti di sana (40 langkah)")
	check(MissionManager.koin_misi(k[0]) == 75 and MissionManager.nama_hasil(k[0]) == "selesai", "selesai: koin misi 75, hasil 'selesai'")
	var b: Array = _siap_tangkap()
	_ulang(b, 3, -2.0, 60.0, 0.0, 0.5)
	check(MissionManager.banner_tampil(b[0]) and is_equal_approx(b[0].banner_sisa, 1.5), "banner tampil 1,5 detik tepat saat selesai (belum berkurang pada langkah yang menyalakannya)")
	var m: MissionManager.Masukan = _masukan(60.0, -2.0, 0.0, 1.0)
	m.jeda = true
	_langkah(b, m)
	check(is_equal_approx(b[0].banner_sisa, 1.5), "saat jeda game banner membeku")
	_langkah(b, _masukan(60.0, -2.0, 0.0, 1.0))
	check(is_equal_approx(b[0].banner_sisa, 0.5) and MissionManager.banner_tampil(b[0]), "1 detik efektif: sisa banner 0,5 detik")
	_langkah(b, _masukan(60.0, -2.0, 0.0, 1.0))
	check(not MissionManager.banner_tampil(b[0]) and b[0].banner_sisa == 0.0, "sesudah 1,5 detik efektif banner hilang")
	check(not MissionManager.kartu_tampil(b[0]) and MissionManager.kucing_tampil(b[0]) == -1, "sesudah selesai kartu dan kucing tidak tampil")
	# flag_hasil dan hasil null aman.
	var misi: DataMisi = _misi_nyata()
	check(MissionManager.flag_hasil(misi, "selesai") == "kucing_ketemu" and MissionManager.flag_hasil(misi, "gagal") == "kucing_belum" and MissionManager.flag_hasil(misi, "") == "" and MissionManager.flag_hasil(null, "selesai") == "", "flag_hasil: selesai -> kucing_ketemu, gagal -> kucing_belum, hasil lain/null -> ''")
	check(MissionManager.nama_hasil(null) == "" and MissionManager.koin_misi(null) == 0 and MissionManager.sisa_rumah(null) == 0 and MissionManager.ditemukan(null) == Vector2i.ZERO, "keadaan null aman")
	var aktif: Array = _keadaan()
	check(MissionManager.nama_hasil(aktif[0]) == "" and MissionManager.koin_misi(aktif[0]) == 0 and MissionManager.kartu_tampil(aktif[0]) and MissionManager.sisa_rumah(aktif[0]) == 12 and MissionManager.ditemukan(aktif[0]) == Vector2i(0, 1), "misi aktif: hasil '', koin 0, kartu tampil, sisa 12 rumah, 0/1")


func _test_manager_tidak_mengubah_masukan() -> void:
	_judul.call("MissionManager: tidak mengubah keadaan, rencana, atau masukan (AC-5f)")
	var rencana: RencanaMisi.Rencana = _rencana()
	var k: MissionManager.Keadaan = MissionManager.awal(rencana)
	var m: MissionManager.Masukan = _masukan(25.0)
	m.lemparan.append(_lemparan(10.0))
	var tampil_sebelum: Array = k.tampil.duplicate()
	var petunjuk_sebelum: Array = k.petunjuk.duplicate()
	var h: MissionManager.Hasil = MissionManager.langkah(k, m)
	check(k.langkah == 0 and k.tampil == tampil_sebelum and k.petunjuk == petunjuk_sebelum and k.status == MissionManager.Status.AKTIF and k.timer_detik == 0.0 and k.dilewati == 0, "keadaan masukan tidak berubah (Hasil.keadaan objek baru)")
	check(h.keadaan != k and h.keadaan.langkah == 1, "hasil membawa keadaan baru yang maju")
	check(m.maju_ubin == 25.0 and m.lemparan.size() == 1 and m.dt == DT and rencana.titik.size() == 3 and rencana.titik[0].maju_ubin == 20.0, "masukan dan rencana tidak berubah")
	var lagi: MissionManager.Hasil = MissionManager.langkah(k, m)
	check(lagi.keadaan.langkah == h.keadaan.langkah and lagi.kejadian.size() == h.kejadian.size() and lagi.keadaan.petunjuk == h.keadaan.petunjuk, "fungsi murni: masukan sama menghasilkan hasil sama")


func _test_manager_mode_bantu() -> void:
	_judul.call("MissionManager: mode bantu tidak memberi petunjuk, kecepatan otomatis 3,0 di atas ambang tangkap, stick tetap bisa menangkap (AC-6, K-3)")
	var k: Array = _keadaan()
	var m: MissionManager.Masukan = _masukan(5.0)
	m.lemparan.append(_lemparan(10.0, true, true))
	check(_langkah(k, m).jumlah(MissionManager.Peristiwa.PETUNJUK) == 0, "lemparan tap mode bantu (bantu=true) tidak menghasilkan PETUNJUK")
	# Kecepatan otomatis mode bantu = santai 3,0 u/d: tidak pernah menangkap walau berada di titik kucing (tidak ada tangkap otomatis).
	var o: Array = _siap_tangkap()
	var h: MissionManager.Hasil = _ulang(o, 600, -2.0, 60.0, Config.KECEPATAN_SANTAI_UD, DT)
	check(Config.KECEPATAN_SANTAI_UD > Config.MISI_TANGKAP_KECEPATAN_MAKS_UD and o[0].status == MissionManager.Status.AKTIF and o[0].ditangkap == 0, "kecepatan otomatis mode bantu 3,0 u/d (> 1,5): sepuluh detik di titik kucing tidak menangkap (K-3 tanpa auto-tangkap)")
	# Pemain yang melambat sendiri dengan stick tetap bisa menangkap (kecepatan 1,5 u/d, mode bantu menyala tidak mengubah masukan manager).
	var s: Array = _siap_tangkap()
	var selesai: MissionManager.Hasil = _ulang(s, 91, -2.0, 60.0, 1.5, DT)
	check(s[0].status == MissionManager.Status.SELESAI and selesai != null, "melambat sendiri ke 1,5 u/d: tertangkap walau mode bantu menyala (manager tidak membedakan)")


# --- Kelayakan dari BikeMotion (AC-5c, "tanpa menebak") ---

func _test_layak_dari_bike_motion() -> void:
	_judul.call("Kelayakan: misi nyata bisa diselesaikan dari lajur seberang dengan BikeMotion, tanpa menebak (M-4)")
	var misi: DataMisi = _misi_nyata()
	var terselesaikan: int = 0
	var gagal_hari: Array[int] = []
	for hari: int in range(1, 31):
		var rute: RouteBuilder.Rute = RouteBuilder.bangun(SeedHari.rute(hari), _pustaka()).rute
		var rencana: RencanaMisi.Rencana = RencanaMisi.buat(misi, rute, SeedHari.misi(hari))
		var k: MissionManager.Keadaan = MissionManager.awal(rencana)
		var sepeda: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
		var jarak: float = 0.0
		var t3: RencanaMisi.Titik = rencana.titik[2]
		# Pemain: santai ke lateral -1,0 (tepi aspal seberang), lalu stick bawah penuh 2 ubin sebelum kucing ketiga (rem sampai berhenti ~1,3 ubin; melewati 1,5 u/d di jalan menuju 0).
		for langkah_ke: int in range(20000):
			var stick: Vector2 = Vector2.ZERO
			if sepeda.lateral_ubin > -1.0:
				stick.x = -1.0
			if jarak >= t3.maju_ubin - 2.0:
				stick.y = -1.0
			var hb: BikeMotion.Hasil = BikeMotion.langkah(sepeda, stick, DT)
			sepeda = hb.keadaan
			jarak += hb.maju_ubin
			var m: MissionManager.Masukan = _masukan(jarak, sepeda.lateral_ubin, sepeda.kecepatan_ud)
			k = MissionManager.langkah(k, m).keadaan
			if k.status != MissionManager.Status.AKTIF:
				break
		if k.status == MissionManager.Status.SELESAI:
			terselesaikan += 1
		else:
			gagal_hari.append(hari)
	check(terselesaikan == 30, "30 rute nyata: pemain yang menepi ke lateral -1,0 dan melambat dengan stick (BikeMotion nyata) selalu menangkap; gagal di hari %s" % [gagal_hari])
	# Pemain yang tidak pernah melambat (stick netral, 3,0 u/d) tidak pernah menangkap: kasus mode bantu tanpa upaya.
	var rute1: RouteBuilder.Rute = RouteBuilder.bangun(SeedHari.rute(1), _pustaka()).rute
	var rencana1: RencanaMisi.Rencana = RencanaMisi.buat(misi, rute1, SeedHari.misi(1))
	var k1: MissionManager.Keadaan = MissionManager.awal(rencana1)
	var s1: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
	var j1: float = 0.0
	for langkah_ke: int in range(20000):
		var hb1: BikeMotion.Hasil = BikeMotion.langkah(s1, Vector2(-1.0 if s1.lateral_ubin > -1.0 else 0.0, 0.0), DT)
		s1 = hb1.keadaan
		j1 += hb1.maju_ubin
		k1 = MissionManager.langkah(k1, _masukan(j1, s1.lateral_ubin, s1.kecepatan_ud)).keadaan
		if k1.status != MissionManager.Status.AKTIF:
			break
	check(k1.status == MissionManager.Status.GAGAL and k1.ditangkap == 0, "tanpa melambat (stick netral, 3,0 u/d) di lajur seberang: misi berakhir GAGAL (tidak ada tangkap otomatis)")
	# Dari lajur dekat (lateral +1) kucing di lateral -2,25..-1,75 berjarak >= 2,75: tidak bisa ditangkap dari sana.
	var k2: MissionManager.Keadaan = MissionManager.awal(rencana1)
	var s2: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
	var j2: float = 0.0
	for langkah_ke: int in range(20000):
		var stick2: Vector2 = Vector2(1.0 if s2.lateral_ubin < 1.0 else 0.0, -1.0 if j2 >= rencana1.titik[2].maju_ubin - 2.0 else 0.0)
		var hb2: BikeMotion.Hasil = BikeMotion.langkah(s2, stick2, DT)
		s2 = hb2.keadaan
		j2 += hb2.maju_ubin
		k2 = MissionManager.langkah(k2, _masukan(j2, s2.lateral_ubin, s2.kecepatan_ud)).keadaan
		if k2.status != MissionManager.Status.AKTIF:
			break
	check(k2.status == MissionManager.Status.AKTIF and k2.ditangkap == 0 and k2.timer_detik == 0.0, "berhenti di lajur dekat (lateral +1, jarak >= 2,75 dari kucing): 333 detik tidak menangkap (misi tetap aktif)")


# --- HasilRute dan hadiah (AC-14, AC-16) ---

func _test_hasil_rute_dan_hadiah() -> void:
	_judul.call("HasilRute.dari: koin_misi hanya bila selesai, masuk koin; gagal dan tanpa misi tidak mengubah apa pun (K-1, AC-14, AC-16)")
	var rute: RouteBuilder.Rute = RouteBuilder.bangun(SeedHari.rute(1), _pustaka()).rute
	var sk: SkorRute.Keadaan = SkorRute.awal()
	sk.koin = 120
	sk.koin_tip = 25
	sk.skor = 1500
	var rencana: RencanaMisi.Rencana = _rencana()
	var selesai: MissionManager.Keadaan = MissionManager.awal(rencana)
	selesai.status = MissionManager.Status.SELESAI
	var gagal: MissionManager.Keadaan = MissionManager.awal(rencana)
	gagal.status = MissionManager.Status.GAGAL
	var aktif: MissionManager.Keadaan = MissionManager.awal(rencana)
	var tanpa: HasilRute.Angka = HasilRute.dari(sk, rute, null)
	check(tanpa.koin == 120 and tanpa.koin_misi == 0 and tanpa.misi_id == "" and tanpa.misi_hasil == "", "tanpa misi: koin 120, tanpa id/hasil/koin misi (tidak ada baris rekap)")
	var a_selesai: HasilRute.Angka = HasilRute.dari(sk, rute, null, selesai)
	check(a_selesai.koin == 195 and a_selesai.koin_misi == 75 and a_selesai.koin_tip == 25 and a_selesai.misi_hasil == "selesai" and a_selesai.misi_id == "p1_kucing", "misi selesai: koin 120 + 75 = 195, tip tetap 25, hasil 'selesai'")
	var a_gagal: HasilRute.Angka = HasilRute.dari(sk, rute, null, gagal)
	check(a_gagal.koin == 120 and a_gagal.koin_misi == 0 and a_gagal.misi_hasil == "gagal" and a_gagal.misi_id == "p1_kucing", "misi gagal: koin tetap 120 (tidak berkurang, hadiah 0), hasil 'gagal'")
	var a_aktif: HasilRute.Angka = HasilRute.dari(sk, rute, null, aktif)
	check(a_aktif.koin == 120 and a_aktif.koin_misi == 0 and a_aktif.misi_hasil == "", "misi masih aktif: tidak ada hadiah, hasil ''")
	check(sk.koin == 120, "HasilRute.dari tidak mengubah SkorRute.Keadaan masukan")
	var rencana_kecil: RencanaMisi.Rencana = _rencana()
	rencana_kecil.hadiah_koin = 45
	var kecil: MissionManager.Keadaan = MissionManager.awal(rencana_kecil)
	kecil.status = MissionManager.Status.SELESAI
	check(HasilRute.dari(sk, rute, null, kecil).koin == 165, "hadiah mengikuti rencana (45 koin tingkat kecil: 120 + 45 = 165)")
