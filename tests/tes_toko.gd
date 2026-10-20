class_name TesToko
extends RefCounted
## Tes data upgrade bengkel run fase6a1-bengkel-kondisi (AC-17, AC-18): `PemuatToko` memuat `assets/data/shop/upgrades.json` nyata (tiga id wajib, harga 500-800, kunci teks ada),
## SATU-SATUNYA pembaca berkas upgrade (pemindai sumber), setiap penolakan validasi dites sendiri-sendiri (id ganda, komponen asing, level 0/negatif/pecahan, urutan level, harga,
## jenis efek asing, nilai di luar rentang, kunci teks hilang atau terlalu panjang, JSON rusak, berkas tidak ada, ...), dan setiap jenis efek punya konsumen yang terukur di
## `BikeMotion`/`BikeCondition`/stamina ke arah yang dijanjikan (efek tidak yatim; tidak ada upgrade yang menaikkan kecepatan puncak atau meniadakan aus). Tes ini TIDAK menyentuh berkas
## save.

const BERKAS: String = "res://assets/data/shop/upgrades.json"
const TOLERANSI: float = 0.000000001

var _cek: Callable
var _judul: Callable


func _init(cek: Callable, judul: Callable) -> void:
	_cek = cek
	_judul = judul


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_test_config()
	_test_data_nyata()
	_test_penolakan_per_field()
	_test_penolakan_antar_upgrade()
	_test_berkas_rusak_dan_hilang()
	_test_penerjemah_panjang()
	_test_satu_pembaca()
	_test_efek_konsumen_terukur()
	_test_tanpa_power_creep()


## Daftar upgrade nyata sebagai larik kamus (bisa diubah per kasus).
func _asli() -> Array:
	return (JSON.parse_string(FileAccess.get_file_as_string(BERKAS)) as Array).duplicate(true)


## Galat dari parse + pemeriksaan antar upgrade untuk `daftar` (larik kamus).
func _galat(daftar: Array) -> Array[String]:
	var k: PemuatToko.Kumpulan = PemuatToko.parse_teks(JSON.stringify(daftar), "uji.json")
	var hasil: Array[String] = []
	hasil.append_array(k.galat)
	hasil.append_array(PemuatToko.periksa_kumpulan(k.upgrade))
	return hasil


func _ubah(indeks: int, field: String, nilai: Variant) -> Array:
	var d: Array = _asli()
	(d[indeks] as Dictionary)[field] = nilai
	return d


func _ditolak(daftar: Array, kata: String, label: String) -> void:
	var g: Array[String] = _galat(daftar)
	var sebut: bool = false
	for baris: String in g:
		if baris.contains(kata):
			sebut = true
	check(not g.is_empty() and sebut, "%s: ditolak dan galat menyebut '%s'; dapat %s" % [label, kata, g.slice(0, 2)])


func _test_config() -> void:
	_judul.call("Toko: angka Config literal (M-10, AC-17)")
	check(Config.TOKO_ID_WAJIB == ["ban_anti_selip", "rem_pakem", "rantai_hemat"], "tiga id wajib permanen: ban_anti_selip, rem_pakem, rantai_hemat")
	check(Config.TOKO_EFEK_JENIS == ["pengali_aus", "pengali_rem", "pengali_lateral", "pengali_kuras_stamina"], "daftar tertutup jenis efek: aus, rem, lateral, kuras stamina")
	check(Config.TOKO_EFEK_MIN.size() == 4 and Config.TOKO_EFEK_MAKS.size() == 4 and Config.TOKO_EFEK_KOMPONEN.size() == 4, "larik rentang dan komponen sejajar daftar jenis")
	check(Config.TOKO_EFEK_MIN == [0.5, 1.0, 1.0, 0.5] and Config.TOKO_EFEK_MAKS == [1.0, 1.5, 1.25, 1.0], "rentang aman: aus 0,5-1,0; rem 1,0-1,5; lateral 1,0-1,25; kuras stamina 0,5-1,0")
	check(Config.TOKO_NAMA_PANJANG_MAKS == 24 and Config.TOKO_DESKRIPSI_PANJANG_MAKS == 48, "nama paling banyak 24 karakter, deskripsi 48")
	var power_creep: bool = false
	for jenis: String in Config.TOKO_EFEK_JENIS:
		if jenis.contains("kecepatan") or jenis.contains("puncak") or jenis.contains("akselerasi"):
			power_creep = true
	check(not power_creep, "tidak ada jenis efek yang menaikkan kecepatan atau akselerasi (tanpa power creep)")
	for i: int in range(4):
		check(Config.TOKO_EFEK_MIN[i] <= Config.TOKO_EFEK_MAKS[i] and (Config.TOKO_EFEK_MIN[i] > 0.0), "rentang jenis %s valid dan positif" % Config.TOKO_EFEK_JENIS[i])
	check(Config.TOKO_EFEK_MIN[0] >= 0.5 and Config.TOKO_EFEK_MAKS[0] <= 1.0, "pengali aus tidak pernah meniadakan aus (>= 0,5) atau mempercepatnya (<= 1,0)")


func _test_data_nyata() -> void:
	_judul.call("Toko: upgrades.json nyata lolos validator; tiga id wajib, harga 500-800, kunci teks ada (AC-17)")
	var k: PemuatToko.Kumpulan = PemuatToko.muat()
	check(k.sah() and k.upgrade.size() == 3, "berkas nyata sah: tiga upgrade, tanpa galat: %s" % [k.galat])
	var peta: Dictionary = {"ban_anti_selip": ["ban", 600], "rem_pakem": ["rem", 500], "rantai_hemat": ["rantai", 700]}
	for id: String in peta:
		var u: DataToko = k.cari(id)
		check(u != null and u.komponen == peta[id][0] and u.harga == peta[id][1] and u.level == 1, "%s: komponen %s harga %d level 1" % [id, peta[id][0], peta[id][1]])
		if u != null:
			check(u.harga >= 500 and u.harga <= 800, "%s: harga %d dalam rentang tingkat 1 (500-800, BALANCING 7)" % [id, u.harga])
			check(AturanTeks.kunci_ada(Callable(), u.nama) and AturanTeks.kunci_ada(Callable(), u.deskripsi), "%s: kunci nama dan deskripsi ada di terjemahan" % id)
			check(AturanTeks.terjemah(u.nama).length() <= Config.TOKO_NAMA_PANJANG_MAKS and AturanTeks.terjemah(u.deskripsi).length() <= Config.TOKO_DESKRIPSI_PANJANG_MAKS, "%s: nama dan deskripsi tidak melewati batas panjang" % id)
			check(not u.efek.is_empty(), "%s: punya efek" % id)
	check(k.cari_level("ban", 1) != null and k.cari_level("ban", 2) == null and k.cari_level("setang", 1) == null, "cari_level: level 1 ban ada, level 2 dan komponen asing tidak")
	check(k.cari("ban_anti_selip").efek[0].jenis == "pengali_lateral" and k.cari("rem_pakem").efek[0].jenis == "pengali_rem", "efek: anti-selip = lateral, pakem = rem")
	check(k.cari("rantai_hemat").efek.size() == 2, "rantai hemat: dua efek (stamina lebih hemat dan aus rantai lebih lambat)")
	# Bentuk berkas: array objek, tab, tanpa field asing.
	var teks: String = FileAccess.get_file_as_string(BERKAS)
	check(JSON.parse_string(teks) is Array and teks.begins_with("["), "berkas berupa array JSON")
	check(_galat(_asli()).is_empty(), "salinan data nyata yang tidak diubah lolos validator (dasar kasus penolakan)")


func _test_penolakan_per_field() -> void:
	_judul.call("Toko: penolakan validasi per field, tiap kasus dites sendiri (AC-17)")
	# id
	var ganda: Array = _asli()
	(ganda[1] as Dictionary)["id"] = "ban_anti_selip"
	_ditolak(ganda, "ganda", "id ganda")
	_ditolak(_ubah(0, "id", "Ban Anti"), "harus huruf kecil", "id berspasi dan huruf besar")
	_ditolak(_ubah(0, "id", "1ban"), "harus huruf kecil", "id diawali angka")
	_ditolak(_ubah(0, "id", ""), "'id' tidak boleh kosong", "id kosong")
	# komponen
	_ditolak(_ubah(0, "komponen", "setang"), "komponen 'setang' tidak dikenal", "komponen asing (setang dicadangkan, belum dibuat)")
	_ditolak(_ubah(0, "komponen", "lampu"), "komponen 'lampu' tidak dikenal", "komponen asing (lampu)")
	_ditolak(_ubah(0, "komponen", 5), "'komponen' harus teks", "komponen bukan teks")
	# level
	_ditolak(_ubah(0, "level", 0), "level harus bilangan bulat >= 1", "level 0")
	_ditolak(_ubah(0, "level", -1), "level harus bilangan bulat >= 1", "level negatif")
	_ditolak(_ubah(0, "level", 1.5), "'level' harus bilangan bulat", "level pecahan")
	_ditolak(_ubah(0, "level", "satu"), "'level' harus bilangan bulat", "level teks")
	# harga
	_ditolak(_ubah(0, "harga", 0), "harga harus bilangan bulat >= 1", "harga 0")
	_ditolak(_ubah(0, "harga", -50), "harga harus bilangan bulat >= 1", "harga negatif")
	_ditolak(_ubah(0, "harga", 99.5), "'harga' harus bilangan bulat", "harga pecahan")
	_ditolak(_ubah(0, "harga", "murah"), "'harga' harus bilangan bulat", "harga teks")
	# teks
	_ditolak(_ubah(0, "nama", "TOKO_KUNCI_HILANG"), "kunci terjemahan", "kunci nama tidak ada")
	_ditolak(_ubah(0, "deskripsi", "TOKO_KUNCI_HILANG"), "kunci terjemahan", "kunci deskripsi tidak ada")
	_ditolak(_ubah(0, "nama", ""), "'nama' tidak boleh kosong", "nama kosong")
	var tanpa_nama: Array = _asli()
	(tanpa_nama[0] as Dictionary).erase("nama")
	_ditolak(tanpa_nama, "field wajib 'nama' tidak ada", "nama hilang")
	var tanpa_harga: Array = _asli()
	(tanpa_harga[0] as Dictionary).erase("harga")
	_ditolak(tanpa_harga, "field wajib 'harga' tidak ada", "harga hilang")
	# efek
	_ditolak(_ubah(0, "efek", []), "efek tidak boleh kosong", "efek kosong")
	_ditolak(_ubah(0, "efek", "banyak"), "'efek' harus daftar", "efek bukan daftar")
	_ditolak(_ubah(0, "efek", [5]), "tiap efek harus objek", "isi efek bukan objek")
	_ditolak(_ubah(0, "efek", [{"jenis": "pengali_kecepatan", "nilai": 1.2}]), "jenis efek 'pengali_kecepatan' tidak dikenal", "jenis efek asing: pengali_kecepatan (menaikkan kecepatan puncak, power creep)")
	_ditolak(_ubah(0, "efek", [{"jenis": "pengali_akselerasi", "nilai": 1.3}]), "jenis efek 'pengali_akselerasi' tidak dikenal", "jenis efek asing: akselerasi")
	_ditolak(_ubah(0, "efek", [{"jenis": "pengali_lateral", "nilai": 1.3}]), "di luar rentang", "nilai di atas rentang aman (lateral 1,3 > 1,25)")
	_ditolak(_ubah(0, "efek", [{"jenis": "pengali_lateral", "nilai": 0.9}]), "di luar rentang", "nilai di bawah rentang aman (lateral 0,9 < 1,0)")
	_ditolak(_ubah(1, "efek", [{"jenis": "pengali_rem", "nilai": 5.0}]), "di luar rentang", "perlambatan rem 5,0 di luar rentang")
	_ditolak(_ubah(2, "efek", [{"jenis": "pengali_aus", "nilai": 0.1}]), "di luar rentang", "pengali aus 0,1 (hampir meniadakan aus)")
	_ditolak(_ubah(2, "efek", [{"jenis": "pengali_aus", "nilai": 0.0}]), "di luar rentang", "pengali aus 0 (meniadakan aus)")
	_ditolak(_ubah(2, "efek", [{"jenis": "pengali_aus", "nilai": 1.5}]), "di luar rentang", "pengali aus 1,5 (mempercepat aus)")
	_ditolak(_ubah(2, "efek", [{"jenis": "pengali_kuras_stamina", "nilai": 0.1}]), "di luar rentang", "kuras stamina 0,1 di bawah rentang")
	_ditolak(_ubah(0, "efek", [{"jenis": "pengali_lateral", "nilai": "besar"}]), "harus punya 'nilai' angka", "nilai efek bukan angka")
	_ditolak(_ubah(0, "efek", [{"jenis": "pengali_lateral"}]), "harus punya 'nilai' angka", "nilai efek hilang")
	_ditolak(_ubah(0, "efek", [{"jenis": "pengali_rem", "nilai": 1.2}]), "hanya untuk komponen 'rem'", "jenis efek rem pada komponen ban")
	_ditolak(_ubah(0, "efek", [{"jenis": "pengali_lateral", "nilai": 1.1, "ekstra": 1}]), "field 'ekstra' tidak dikenal", "field asing di efek")
	_ditolak(_ubah(0, "bonus", 5), "field 'bonus' tidak dikenal", "field asing di upgrade")
	# batas rentang sah: nilai tepat di ujung rentang diterima.
	check(_galat(_ubah(0, "efek", [{"jenis": "pengali_lateral", "nilai": 1.25}])).is_empty() and _galat(_ubah(1, "efek", [{"jenis": "pengali_rem", "nilai": 1.5}])).is_empty() and _galat(_ubah(2, "efek", [{"jenis": "pengali_aus", "nilai": 0.5}, {"jenis": "pengali_kuras_stamina", "nilai": 0.5}])).is_empty(), "nilai tepat di ujung rentang aman diterima (1,25 / 1,5 / 0,5)")


func _test_penolakan_antar_upgrade() -> void:
	_judul.call("Toko: aturan antar upgrade, id wajib dan urutan level per komponen (AC-17)")
	# id wajib hilang
	var tanpa: Array = _asli()
	tanpa.remove_at(1)
	_ditolak(tanpa, "upgrade wajib 'rem_pakem' tidak ada", "id wajib rem_pakem hilang")
	var salah_komponen: Array = _ubah(1, "komponen", "ban")
	(salah_komponen[1] as Dictionary)["efek"] = [{"jenis": "pengali_aus", "nilai": 0.9}]
	_ditolak(salah_komponen, "upgrade wajib 'rem_pakem' harus level 1 untuk komponen 'rem'", "id wajib pada komponen yang salah")
	var level_dua: Array = _ubah(0, "level", 2)
	_ditolak(level_dua, "berurutan", "level 2 tanpa level 1 untuk ban")
	# level berurutan diterima
	var urut: Array = _asli()
	var tambahan: Dictionary = (urut[0] as Dictionary).duplicate(true)
	tambahan["id"] = "ban_dua"
	tambahan["level"] = 2
	tambahan["harga"] = 900
	urut.append(tambahan)
	check(_galat(urut).is_empty(), "level 1 lalu level 2 untuk ban (berurutan) diterima")
	# kembar
	var kembar: Array = _asli()
	var salin: Dictionary = (kembar[0] as Dictionary).duplicate(true)
	salin["id"] = "ban_lain"
	kembar.append(salin)
	_ditolak(kembar, "berurutan", "dua upgrade level 1 untuk ban (kembar)")
	# lompat
	var lompat: Array = _asli()
	var tiga: Dictionary = (lompat[0] as Dictionary).duplicate(true)
	tiga["id"] = "ban_tiga"
	tiga["level"] = 3
	lompat.append(tiga)
	_ditolak(lompat, "berurutan", "level 1 lalu 3 (lompat)")
	# daftar kosong
	_ditolak([], "upgrade wajib 'rem_pakem' tidak ada", "daftar kosong: semua id wajib hilang")
	# bukan array
	var k: PemuatToko.Kumpulan = PemuatToko.parse_teks('{"a": 1}', "uji.json")
	check(not k.sah() and k.upgrade.is_empty() and k.galat[0].contains("array"), "isi berkas objek (bukan array) ditolak: %s" % [k.galat])
	var k2: PemuatToko.Kumpulan = PemuatToko.parse_teks("[1, 2]", "uji.json")
	check(not k2.sah() and k2.galat.size() == 2, "elemen bukan objek ditolak satu per satu")
	# upgrade tidak sah tidak ikut ke daftar upgrade sah.
	var campur: Array = _asli()
	(campur[0] as Dictionary)["harga"] = 0
	var k3: PemuatToko.Kumpulan = PemuatToko.parse_teks(JSON.stringify(campur), "uji.json")
	check(k3.upgrade.size() == 2 and k3.cari("ban_anti_selip") == null, "upgrade tidak sah dibuang dari daftar sah (dua sisanya tetap)")


func _test_berkas_rusak_dan_hilang() -> void:
	_judul.call("Toko: JSON rusak, berkas kosong, dan berkas tidak ada = galat tanpa crash (AC-17)")
	var rusak: PemuatToko.Kumpulan = PemuatToko.parse_teks("[{\"id\": ", "uji.json")
	check(not rusak.sah() and rusak.upgrade.is_empty() and rusak.galat[0].contains("JSON rusak"), "JSON rusak: galat, tanpa upgrade, tanpa crash: %s" % [rusak.galat])
	var hilang: PemuatToko.Kumpulan = PemuatToko.muat("res://assets/data/shop/tidak_ada.json")
	check(not hilang.sah() and hilang.upgrade.is_empty() and hilang.galat[0].contains("tidak ada"), "berkas tidak ada: galat jujur, daftar kosong: %s" % [hilang.galat])
	var kosong: PemuatToko.Kumpulan = PemuatToko.parse_teks("", "uji.json")
	check(not kosong.sah() and kosong.upgrade.is_empty(), "teks kosong: galat")
	check(not hilang.sah() and hilang.cari("rem_pakem") == null, "daftar galat tidak memuat upgrade apa pun (bengkel tampil galat, tetap bisa dilewati, K-4)")
	var daftar_hilang: Array[DataToko] = hilang.upgrade
	var s: Dictionary = DataSave.templat()
	s["koin"] = 5000
	check(not Economy.beli_upgrade(s, "rem_pakem", daftar_hilang).diterima, "dengan data galat tidak ada upgrade yang bisa dibeli (tanpa crash)")


func _test_penerjemah_panjang() -> void:
	_judul.call("Toko: panjang nama dan deskripsi diperiksa terhadap teks terjemahan (AC-17)")
	var panjang: Callable = func(_kunci: String) -> String: return "x".repeat(60)
	var k: PemuatToko.Kumpulan = PemuatToko.parse_teks(FileAccess.get_file_as_string(BERKAS), "uji.json", panjang)
	var nama: bool = false
	var deskripsi: bool = false
	for g: String in k.galat:
		if g.contains("nama") and g.contains("lebih panjang"):
			nama = true
		if g.contains("deskripsi") and g.contains("lebih panjang"):
			deskripsi = true
	check(nama and deskripsi, "teks terjemahan 60 karakter: nama (> 24) dan deskripsi (> 48) ditolak")
	var tepat: Callable = func(kunci: String) -> String: return "n".repeat(24) if kunci.ends_with("_NAMA") else "d".repeat(48)
	check(PemuatToko.parse_teks(FileAccess.get_file_as_string(BERKAS), "uji.json", tepat).galat.is_empty(), "nama tepat 24 dan deskripsi tepat 48 karakter diterima")
	var lewat: Callable = func(kunci: String) -> String: return "n".repeat(25) if kunci.ends_with("_NAMA") else "d".repeat(49)
	check(PemuatToko.parse_teks(FileAccess.get_file_as_string(BERKAS), "uji.json", lewat).galat.size() == 6, "nama 25 dan deskripsi 49 karakter ditolak untuk ketiga upgrade (6 galat)")


func _test_satu_pembaca() -> void:
	_judul.call("Pemindai sumber: PemuatToko satu-satunya pembaca upgrades.json (AC-17, rule gdscript)")
	var pembaca: Array[String] = []
	for folder: String in ["res://scripts", "res://scenes"]:
		for berkas: String in _berkas(folder):
			var teks: String = FileAccess.get_file_as_string(berkas)
			if teks.contains("upgrades.json") or teks.contains("data/shop"):
				pembaca.append(berkas)
	check(pembaca == ["res://scripts/systems/pemuat_toko.gd"], "hanya pemuat_toko.gd menyebut upgrades.json atau data/shop: %s" % [pembaca])
	var kode: String = FileAccess.get_file_as_string("res://scripts/systems/pemuat_toko.gd")
	check(kode.contains("FileAccess") and not FileAccess.get_file_as_string("res://scripts/systems/data_toko.gd").contains("FileAccess") and not FileAccess.get_file_as_string("res://scripts/systems/economy.gd").contains("FileAccess"), "hanya PemuatToko menyentuh berkas; DataToko dan Economy murni")
	var kunci_toko: int = 0
	for baris: String in FileAccess.get_file_as_string("res://translations/konten.csv").split("\n"):
		if baris.begins_with("TOKO_"):
			kunci_toko += 1
	check(kunci_toko == 6, "konten.csv memuat 6 kunci TOKO_ (nama dan deskripsi tiga upgrade), dapat %d" % kunci_toko)


func _berkas(folder: String) -> Array[String]:
	var hasil: Array[String] = []
	var dir: DirAccess = DirAccess.open(folder)
	if dir == null:
		return hasil
	for sub: String in dir.get_directories():
		hasil.append_array(_berkas(folder.path_join(sub)))
	for nama: String in dir.get_files():
		if nama.get_extension() in ["gd", "tscn"]:
			hasil.append(folder.path_join(nama))
	hasil.sort()
	return hasil


# --- AC-18: efek terukur dan tidak yatim ---

func _test_efek_konsumen_terukur() -> void:
	_judul.call("Toko: tiap jenis efek punya konsumen yang terukur ke arah yang dijanjikan; jenis tanpa pengukur gagal (AC-18)")
	var daftar: Array[DataToko] = PemuatToko.muat().upgrade
	# Pengukur per jenis: (nilai efek) -> {dasar, dengan} dan arah yang dijanjikan.
	var pengukur: Dictionary = {
		"pengali_aus": Callable(self, "_ukur_aus"),
		"pengali_rem": Callable(self, "_ukur_rem"),
		"pengali_lateral": Callable(self, "_ukur_lateral"),
		"pengali_kuras_stamina": Callable(self, "_ukur_stamina"),
	}
	for jenis: String in Config.TOKO_EFEK_JENIS:
		check(pengukur.has(jenis), "jenis efek '%s' di validator punya pengukur konsumen (tidak yatim)" % jenis)
		if not pengukur.has(jenis):
			continue
		var indeks: int = Config.TOKO_EFEK_JENIS.find(jenis)
		var nilai_baik: float = Config.TOKO_EFEK_MAKS[indeks] if jenis == "pengali_rem" or jenis == "pengali_lateral" else Config.TOKO_EFEK_MIN[indeks]
		var hasil: Array = (pengukur[jenis] as Callable).call(nilai_baik)
		check(float(hasil[1]) > float(hasil[0]) + TOLERANSI, "%s = %s mengubah hasil gerak ke arah yang dijanjikan: %s vs %s" % [jenis, nilai_baik, hasil[1], hasil[0]])
		# Netral (1,0) tidak mengubah apa pun.
		var netral: Array = (pengukur[jenis] as Callable).call(1.0)
		check(absf(float(netral[1]) - float(netral[0])) < TOLERANSI, "%s = 1,0 netral (tidak mengubah hasil)" % jenis)
	# Upgrade nyata dipetakan ke pengali yang dibaca BikeCondition.
	var level: Dictionary = {"ban": 1, "rem": 1, "rantai": 1}
	var pengali: Dictionary = DataToko.pengali_efek(daftar, level)
	check(absf(float(pengali["pengali_rem"]) - 1.2) < TOLERANSI and absf(float(pengali["pengali_lateral"]) - 1.15) < TOLERANSI and absf(float(pengali["pengali_kuras_stamina"]) - 0.85) < TOLERANSI, "ketiga upgrade nyata dimiliki: rem 1,2, lateral 1,15, kuras stamina 0,85; dapat %s" % [pengali])
	var aus: Dictionary = DataToko.pengali_aus(daftar, level)
	check(aus == {"ban": 1.0, "rem": 1.0, "rantai": 0.8}, "pengali aus upgrade nyata: hanya rantai 0,8; dapat %s" % [aus])
	var nol: Dictionary = DataToko.pengali_efek(daftar, {"ban": 0, "rem": 0, "rantai": 0})
	check(nol == {"pengali_rem": 1.0, "pengali_lateral": 1.0, "pengali_kuras_stamina": 1.0} and DataToko.pengali_aus(daftar, {}) == {"ban": 1.0, "rem": 1.0, "rantai": 1.0}, "level 0 atau kosong: semua pengali 1,0 (belum membeli = tanpa efek)")
	var satu: Dictionary = DataToko.pengali_efek(daftar, {"ban": 1, "rem": 0, "rantai": 0})
	check(satu["pengali_rem"] == 1.0 and absf(float(satu["pengali_lateral"]) - 1.15) < TOLERANSI and satu["pengali_kuras_stamina"] == 1.0, "hanya upgrade yang dimiliki yang berlaku (ban saja: lateral 1,15, lainnya 1,0)")


## Kondisi rantai setelah 100 ubin pada santai: [tanpa pengali aus, dengan pengali aus `nilai` untuk rantai] (kondisi lebih tinggi = aus lebih lambat).
func _ukur_aus(nilai: float) -> Array:
	var t: BikeCondition.Telemetri = BikeCondition.Telemetri.new()
	t.dt = 100.0 / 3.0
	t.maju_ubin = 100.0
	t.kecepatan_awal_ud = 3.0
	var dasar: Dictionary = BikeCondition.aus(BikeCondition.baru(), t)
	var hemat: Dictionary = BikeCondition.aus(BikeCondition.baru(), t, {"rantai": nilai})
	return [float(dasar["rantai"]), float(hemat["rantai"])]


## Jarak berhenti dari 6,0 u/d: [-jarak dasar, -jarak dengan pengali rem] (lebih pendek = nilai lebih besar).
func _ukur_rem(nilai: float) -> Array:
	return [-_jarak_rem(BikeCondition.efek(BikeCondition.baru())), -_jarak_rem(BikeCondition.efek(BikeCondition.baru(), {"pengali_rem": nilai}))]


func _jarak_rem(efek: EfekKondisi) -> float:
	var s: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
	s.kecepatan_ud = 6.0
	s.rem_aktif = true
	s.tahan_rem_detik = Config.REM_TAHAN_DETIK
	var jarak: float = 0.0
	var langkah: int = 0
	while s.kecepatan_ud > 0.0 and langkah < 6000:
		var h: BikeMotion.Hasil = BikeMotion.langkah(s, Vector2(0.0, -1.0), 1.0 / 60.0, 0.0, efek)
		jarak += h.maju_ubin
		s = h.keadaan
		langkah += 1
	return jarak


## Perpindahan lateral dalam 0,5 detik stick penuh ke sisi dekat: [dasar, dengan pengali lateral].
func _ukur_lateral(nilai: float) -> Array:
	var dasar: BikeMotion.Hasil = BikeMotion.langkah(BikeMotion.Keadaan.new(), Vector2(1.0, 0.0), 0.5)
	var upg: BikeMotion.Hasil = BikeMotion.langkah(BikeMotion.Keadaan.new(), Vector2(1.0, 0.0), 0.5, 0.0, BikeCondition.efek(BikeCondition.baru(), {"pengali_lateral": nilai}))
	return [dasar.keadaan.lateral_ubin, upg.keadaan.lateral_ubin]


## Stamina sisa setelah 5 detik ngebut: [dasar, dengan pengali kuras stamina].
func _ukur_stamina(nilai: float) -> Array:
	var s: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
	s.kecepatan_ud = 6.0
	var dasar: BikeMotion.Hasil = BikeMotion.langkah(s, Vector2(0.0, 1.0), 5.0)
	var upg: BikeMotion.Hasil = BikeMotion.langkah(s, Vector2(0.0, 1.0), 5.0, 0.0, BikeCondition.efek(BikeCondition.baru(), {"pengali_kuras_stamina": nilai}))
	return [dasar.keadaan.stamina, upg.keadaan.stamina]


func _test_tanpa_power_creep() -> void:
	_judul.call("Toko: tidak ada upgrade yang menaikkan kecepatan puncak, melewati harga ngebut, atau meniadakan aus (AC-18, M-10)")
	var daftar: Array[DataToko] = PemuatToko.muat().upgrade
	var level: Dictionary = {"ban": 1, "rem": 1, "rantai": 1}
	var e: EfekKondisi = BikeCondition.efek(BikeCondition.baru(), DataToko.pengali_efek(daftar, level))
	check(e.pengali_kecepatan == 1.0 and e.batas_puncak_ud == Config.KECEPATAN_NGEBUT_UD and e.pengali_akselerasi == 1.0, "semua upgrade dimiliki, sepeda baru: kecepatan tujuan, batas puncak, dan akselerasi sama dengan tanpa upgrade")
	var s: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
	var puncak_dasar: float = 0.0
	var puncak_upg: float = 0.0
	var s2: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
	for i: int in range(1200):
		var a: BikeMotion.Hasil = BikeMotion.langkah(s, Vector2(0.0, 1.0), 1.0 / 60.0)
		var b: BikeMotion.Hasil = BikeMotion.langkah(s2, Vector2(0.0, 1.0), 1.0 / 60.0, 0.0, e)
		s = a.keadaan
		s2 = b.keadaan
		puncak_dasar = maxf(puncak_dasar, s.kecepatan_ud)
		puncak_upg = maxf(puncak_upg, s2.kecepatan_ud)
	check(puncak_upg <= puncak_dasar + TOLERANSI and puncak_upg <= Config.KECEPATAN_NGEBUT_UD, "20 detik stick penuh: kecepatan puncak dengan semua upgrade (%s) tidak melebihi tanpa upgrade (%s) atau ngebut 6,0" % [puncak_upg, puncak_dasar])
	# Dengan upgrade ngebut tetap menguras lebih dari santai: stamina setelah 3 detik ngebut masih turun (lebih hemat, tapi tidak gratis).
	var sn: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
	sn.kecepatan_ud = 6.0
	var hemat: BikeMotion.Hasil = BikeMotion.langkah(sn, Vector2(0.0, 1.0), 3.0, 0.0, e)
	check(hemat.keadaan.stamina < Config.STAMINA_MAKS - 20.0, "ngebut dengan rantai hemat tetap menguras stamina (%s dari 100): ngebut masih punya harga" % hemat.keadaan.stamina)
	# Aus tidak ditiadakan: upgrade nyata paling hemat tetap menghasilkan aus > 0 dan >= separuh.
	var pengali_aus: Dictionary = DataToko.pengali_aus(daftar, level)
	var t: BikeCondition.Telemetri = BikeCondition.Telemetri.new()
	t.dt = 100.0 / 3.0
	t.maju_ubin = 100.0
	t.kecepatan_awal_ud = 3.0
	var tanpa: Dictionary = BikeCondition.aus(BikeCondition.baru(), t)
	var dengan: Dictionary = BikeCondition.aus(BikeCondition.baru(), t, pengali_aus)
	var aus_tanpa: float = 1.0 - float(tanpa["rantai"])
	var aus_dengan: float = 1.0 - float(dengan["rantai"])
	check(aus_dengan > 0.0 and aus_dengan < aus_tanpa and aus_dengan >= aus_tanpa * 0.5 - TOLERANSI, "rantai hemat memperlambat aus rantai (%s < %s) tetapi tidak meniadakannya (>= separuh)" % [aus_dengan, aus_tanpa])
	check(1.0 - float(dengan["ban"]) == 1.0 - float(tanpa["ban"]) and dengan["rem"] == 1.0, "komponen lain tidak berubah oleh upgrade rantai")
