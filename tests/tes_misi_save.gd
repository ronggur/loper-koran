class_name TesMisiSave
extends RefCounted
## Tes save v2, flag, dan headline lanjutan run fase4b-misi-kucing bagian A (AC-7 sampai AC-9, AC-19): migrasi dari fixture save 4A asli dan v0,
## `DataSave.catat_hari` terhadap oracle terpisah (konsumsi flag, `misi_hasil`, hadiah), `HeadlineManager.flag_terpakai`, dan rantai hari nyata
## (selesai, gagal, dilewati, dua flag, 40 hari) memakai pustaka headline dan misi nyata.
##
## Oracle independen (AC-19): variabel berjalan dan model jadwal P1 dihitung tes sendiri (hari muncul = hari diambil + 7), bukan dengan memanggil
## fungsi yang dites. Tes ini TIDAK menyentuh berkas apa pun (logika murni), jadi `user://save.json` aman.

const FOLDER_MISI: String = "res://assets/data/missions"
const FOLDER_HEADLINE: String = "res://assets/data/headlines"
## Save 4A asli (format v1) persis seperti contoh DATA_SCHEMA 4 sebelum run ini: P1 diambil di hari 1, 3 dari 25 terantar, koin 120 termasuk tip 25.
const SAVE_4A: String = """{
	"flag": [],
	"hari": 2,
	"headline_jeda": {
		"ringan_mangga": 4,
		"utama_jalan_diperbaiki": 5
	},
	"koin": 120,
	"misi_jeda": {
		"p1_kucing": 8
	},
	"pengaturan": {
		"kidal": false,
		"mode_bantu": false,
		"musik": 1.0,
		"suara": 1.0
	},
	"terakhir": {
		"hari": 1,
		"koin": 120,
		"meleset": 22,
		"misi_diambil": "p1_kucing",
		"skor": 1500,
		"terkirim": 3,
		"tip": 25
	},
	"tip_total": 25,
	"versi": 1
}"""

var _cek: Callable
var _judul: Callable
var _misi: Array[DataMisi] = []
var _pustaka: PemuatHeadline.Pustaka = null


func _init(cek: Callable, judul: Callable) -> void:
	_cek = cek
	_judul = judul


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_misi = PemuatMisi.muat_folder(FOLDER_MISI).misi
	_pustaka = PemuatHeadline.muat_folder(FOLDER_HEADLINE)
	_test_migrasi_save_4a()
	_test_migrasi_v0_dan_tak_sah()
	_test_catat_hari_misi_hasil()
	_test_catat_hari_acak_vs_oracle()
	_test_tutorial_selesai()
	_test_flag_terpakai()
	_test_rantai_selesai()
	_test_rantai_gagal()
	_test_rantai_dilewati()
	_test_dua_flag()
	_test_rantai_empat_puluh_hari()
	_test_tabel_dokumen()


# --- Pembantu ---

func _angka(koin: int, tip: int, misi_id: String = "", hasil: String = "", koin_misi: int = 0) -> HasilRute.Angka:
	var a: HasilRute.Angka = HasilRute.Angka.new()
	a.pelanggan = 25
	a.terkirim = 10
	a.meleset = 15
	a.koin = koin
	a.koin_tip = tip
	a.skor = 100
	a.misi_id = misi_id
	a.misi_hasil = hasil
	a.koin_misi = koin_misi
	return a


func _catatan(hari: int, angka: HasilRute.Angka) -> DataSave.CatatanHari:
	var c: DataSave.CatatanHari = DataSave.CatatanHari.new()
	c.hari = hari
	c.angka = angka
	return c


# --- Migrasi (AC-7) ---

func _test_migrasi_save_4a() -> void:
	_judul.call("Save v2: migrasi dari fixture save 4A asli (AC-7)")
	var hasil: DataSave.Hasil = DataSave.dari_teks(SAVE_4A)
	var s: Dictionary = hasil.state
	check(hasil.status == DataSave.Status.SAH and not hasil.perlu_salinan(), "save 4A (v1) terbaca SAH dan tidak perlu disalin: dimigrasi, tidak dihapus")
	check(s["versi"] == Config.SAVE_VERSI, "versi menjadi SAVE_VERSI (v1 -> v2 -> v3 -> v4)")
	check(s["hari"] == 2 and s["koin"] == 120 and s["tip_total"] == 25, "hari 2, koin 120, tip_total 25 dipertahankan (progres tidak hilang)")
	check(s["misi_jeda"] == {"p1_kucing": 8} and s["headline_jeda"] == {"ringan_mangga": 4, "utama_jalan_diperbaiki": 5}, "misi_jeda dan headline_jeda dipertahankan")
	check(s["pengaturan"] == {"kidal": false, "mode_bantu": false, "suara": 1.0, "musik": 1.0}, "pengaturan dipertahankan")
	check(s["flag"] == [], "flag v1 dibiarkan apa adanya (kosong)")
	check(s["misi_hasil"] == {} and s["tutorial"] == {"selesai": false}, "field v2 baru: misi_hasil kosong, tutorial.selesai false")
	check(s["terakhir"] == {"hari": 1, "terkirim": 3, "meleset": 22, "koin": 120, "tip": 25, "skor": 1500, "koin_misi": 0, "misi_hasil": "", "misi_diambil": "p1_kucing"}, "terakhir dipertahankan dan mendapat koin_misi 0 dan misi_hasil ''; dapat %s" % [s["terakhir"]])
	check(DataSave.dari_teks(DataSave.ke_teks(s)).state == s and DataSave.migrasi(s) == s, "hasil migrasi bulak-balik sama dan migrasi v2 idempoten")
	# Save v1 yang punya flag (hanya dari tes, 4A tidak menulis flag): flag dibiarkan, tidak dikonsumsi, tidak dihapus.
	var dengan_flag: Dictionary = JSON.parse_string(SAVE_4A)
	dengan_flag["flag"] = ["kucing_belum", "flag_lama"]
	var s2: Dictionary = DataSave.dari_teks(JSON.stringify(dengan_flag)).state
	check(s2["flag"] == ["kucing_belum", "flag_lama"] and s2["koin"] == 120, "flag v1 (termasuk id yang tidak dikenal data) dan koin tidak dijatuhkan migrasi")
	var v4: DataSave.Hasil = DataSave.dari_teks('{"versi": 5, "koin": 5}')
	check(v4.status == DataSave.Status.TERLALU_BARU and v4.perlu_salinan() and v4.state == DataSave.templat(), "versi 5 (lebih baru dari 4): TERLALU_BARU, disalin, tidak ditimpa diam-diam")
	check(DataSave.dari_teks('{"versi": 2, "hari": 4, "misi_hasil": [], "tutorial": {}}').status == DataSave.Status.RUSAK, "misi_hasil bukan objek = save rusak (tipe kunci salah)")
	check(DataSave.dari_teks('{"versi": 2, "tutorial": 5}').status == DataSave.Status.RUSAK, "tutorial bukan objek = save rusak")


func _test_migrasi_v0_dan_tak_sah() -> void:
	_judul.call("Save v2: v0 ke v2, id tak dikenal dibiarkan, nilai tidak sah dijepit (AC-7)")
	var v0: DataSave.Hasil = DataSave.dari_teks('{"hari": 7, "koin": 1500, "flag": ["kucing_belum", "flag_lama"], "pengaturan": {"kidal": true}}')
	var s: Dictionary = v0.state
	check(v0.status == DataSave.Status.SAH and s["versi"] == Config.SAVE_VERSI and s["hari"] == 7 and s["koin"] == 1500 and s["flag"] == ["kucing_belum", "flag_lama"] and s["pengaturan"]["kidal"] == true, "v0 ke v2: hari, koin, flag, pengaturan dipertahankan")
	check(s["misi_hasil"] == {} and s["tutorial"] == {"selesai": false}, "v0 ke v2: field baru bawaan")
	var d: Dictionary = {
		"versi": 2, "hari": 3,
		"misi_hasil": {"p1_kucing": {"hasil": "selesai", "hari": 1}, "misi_hantu": {"hasil": "gagal", "hari": 5}, "rusak1": {"hasil": "menang", "hari": 2}, "rusak2": 7, "rusak3": {"hari": 2}, "negatif": {"hasil": "gagal", "hari": -4}},
		"tutorial": {"selesai": "ya"},
		"terakhir": {"hari": 2, "misi_hasil": "menang", "koin_misi": -9},
	}
	var n: Dictionary = DataSave.migrasi(d)
	check(n["misi_hasil"].has("p1_kucing") and n["misi_hasil"]["p1_kucing"] == {"hasil": "selesai", "hari": 1}, "misi_hasil sah dipertahankan")
	check(n["misi_hasil"].has("misi_hantu"), "id misi yang tidak ada di data dibiarkan (diabaikan dengan aman, rule save-system)")
	check(not n["misi_hasil"].has("rusak1") and not n["misi_hasil"].has("rusak2") and not n["misi_hasil"].has("rusak3"), "entri misi_hasil bentuk salah (hasil tak dikenal, bukan objek, tanpa hasil) dibuang")
	check(n["misi_hasil"]["negatif"]["hari"] == 1, "hari negatif di misi_hasil dijepit ke 1")
	check(n["tutorial"] == {"selesai": false}, "tutorial.selesai bukan bool -> false")
	check(n["terakhir"]["misi_hasil"] == "" and n["terakhir"]["koin_misi"] == 0, "terakhir.misi_hasil tak dikenal -> '', koin_misi negatif -> 0")
	check(DataSave.tutorial_selesai({"tutorial": {"selesai": true}}) and not DataSave.tutorial_selesai({"tutorial": {"selesai": false}}) and not DataSave.tutorial_selesai({}), "tutorial_selesai membaca state (hilang = false)")


# --- catat_hari (AC-8) ---

func _test_catat_hari_misi_hasil() -> void:
	_judul.call("catat_hari: konsumsi flag, flag baru sesudahnya, misi_hasil, koin_misi, hadiah (AC-8, M-6, M-7)")
	var state: Dictionary = DataSave.templat()
	state["hari"] = 2
	state["koin"] = 500
	state["flag"] = ["kucing_ketemu", "lain"]
	var asli: Dictionary = state.duplicate(true)
	var c: DataSave.CatatanHari = _catatan(2, _angka(195, 25, "p1_kucing", "selesai", 75))
	c.flag_dikonsumsi = ["kucing_ketemu"]
	c.flag_baru = ["kucing_ketemu"]
	var s: Dictionary = DataSave.catat_hari(state, c)
	check(state == asli, "catat_hari tidak mengubah state masukan")
	check(s["flag"] == ["lain", "kucing_ketemu"], "konsumsi dulu lalu tambah: flag baru hari ini tidak ikut terhapus (kucing_ketemu dikonsumsi lalu ditulis lagi); dapat %s" % [s["flag"]])
	check(s["koin"] == 500 + 195 and s["terakhir"]["koin"] == 195 and s["terakhir"]["koin_misi"] == 75 and s["terakhir"]["misi_hasil"] == "selesai", "koin hari = angka.koin (sudah termasuk 75), terakhir mencatat koin_misi 75 dan hasil selesai")
	check(s["misi_hasil"] == {"p1_kucing": {"hasil": "selesai", "hari": 2}}, "misi_hasil[p1_kucing] = selesai di hari 2")
	# Flag yang dikonsumsi tetapi tidak ada: aman. Flag baru ganda: sekali.
	var c2: DataSave.CatatanHari = _catatan(3, _angka(0, 0))
	c2.flag_dikonsumsi = ["tidak_ada", "lain"]
	c2.flag_baru = ["x", "x", ""]
	var s2: Dictionary = DataSave.catat_hari(s, c2)
	check(s2["flag"] == ["kucing_ketemu", "x"], "flag yang tidak ada dikonsumsi tanpa galat; flag baru ganda dan kosong disaring; dapat %s" % [s2["flag"]])
	# selesai tidak pernah ditimpa gagal; gagal boleh diganti selesai.
	var c3: DataSave.CatatanHari = _catatan(9, _angka(100, 0, "p1_kucing", "gagal"))
	var s3: Dictionary = DataSave.catat_hari(s, c3)
	check(s3["misi_hasil"]["p1_kucing"] == {"hasil": "selesai", "hari": 2}, "hasil 'selesai' tidak ditimpa 'gagal' dan hari selesainya tidak bergeser")
	check(s3["koin"] == s["koin"] + 100 and s3["terakhir"]["misi_hasil"] == "gagal" and s3["terakhir"]["koin_misi"] == 0, "hari gagal: koin tetap bertambah dari rute, terakhir.misi_hasil 'gagal', koin_misi 0")
	var gagal_dulu: Dictionary = DataSave.catat_hari(DataSave.templat(), _catatan(1, _angka(50, 0, "p1_kucing", "gagal")))
	check(gagal_dulu["misi_hasil"]["p1_kucing"] == {"hasil": "gagal", "hari": 1}, "hasil gagal tercatat di misi_hasil")
	var jadi_selesai: Dictionary = DataSave.catat_hari(gagal_dulu, _catatan(8, _angka(200, 0, "p1_kucing", "selesai", 75)))
	check(jadi_selesai["misi_hasil"]["p1_kucing"] == {"hasil": "selesai", "hari": 8}, "gagal boleh diganti selesai (hari 8)")
	var gagal_lagi: Dictionary = DataSave.catat_hari(gagal_dulu, _catatan(8, _angka(0, 0, "p1_kucing", "gagal")))
	check(gagal_lagi["misi_hasil"]["p1_kucing"] == {"hasil": "gagal", "hari": 8}, "gagal yang lebih baru memperbarui hari")
	# Tanpa misi: tidak ada catatan misi_hasil, terakhir.misi_hasil '' dan koin_misi 0.
	var tanpa: Dictionary = DataSave.catat_hari(DataSave.templat(), _catatan(1, _angka(120, 25)))
	check(tanpa["misi_hasil"] == {} and tanpa["terakhir"]["misi_hasil"] == "" and tanpa["terakhir"]["koin_misi"] == 0, "tanpa misi: misi_hasil kosong, terakhir.misi_hasil '' dan koin_misi 0")
	# koin_misi hanya dicatat untuk selesai (Angka yang tidak konsisten tidak bocor ke terakhir).
	var aneh: Dictionary = DataSave.catat_hari(DataSave.templat(), _catatan(1, _angka(100, 0, "p1_kucing", "gagal", 75)))
	check(aneh["terakhir"]["koin_misi"] == 0, "koin_misi hanya dicatat bila hasil 'selesai'")
	# Hadiah mengikuti tingkat (satu sumber: DataMisi.hadiah_koin -> rencana -> Angka.koin).
	var p1: DataMisi = null
	for m: DataMisi in _misi:
		if m.id == "p1_kucing":
			p1 = m
	check(p1 != null and p1.hadiah_koin() == 75 and Config.MISI_HADIAH_KOIN[Config.MISI_TINGKAT_HADIAH.find(str(p1.hadiah["tingkat"]))] == 75, "hadiah P1 = 75 koin menurut tingkat sedang (GDD 10.5, GDD 14.1: 45 / 75 / 120)")


func _test_catat_hari_acak_vs_oracle() -> void:
	_judul.call("catat_hari: 400 hari acak berseed vs oracle (progres tidak turun, konsumsi, misi_hasil, koin_misi) (AC-8)")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1812
	var state: Dictionary = DataSave.templat()
	var o_hari: int = 1
	var o_koin: int = 0
	var o_tip: int = 0
	var o_flag: Array = []
	var o_hasil: Dictionary = {}
	var turun: Array[String] = []
	var salah: Array[String] = []
	var daftar_flag: Array[String] = ["kucing_ketemu", "kucing_belum", "f3"]
	var ids: Array[String] = ["p1_kucing", "m2"]
	for langkah: int in range(400):
		var hari: int = rng.randi_range(1, 45)
		var rute_koin: int = 0 if rng.randf() < 0.2 else rng.randi_range(0, 400)
		var tip: int = mini(rute_koin, rng.randi_range(0, 50))
		var pilihan: int = rng.randi_range(0, 2)
		var hasil: String = ["", "selesai", "gagal"][pilihan]
		var id: String = ids[rng.randi_range(0, 1)] if pilihan > 0 else ""
		var hadiah: int = 75 if hasil == "selesai" else 0
		var angka: HasilRute.Angka = _angka(rute_koin + hadiah, tip, id, hasil, hadiah)
		var c: DataSave.CatatanHari = _catatan(hari, angka)
		var baru: Array[String] = []
		if pilihan > 0 and rng.randf() < 0.8:
			baru.append("kucing_ketemu" if hasil == "selesai" else "kucing_belum")
		c.flag_baru = baru
		var konsumsi: Array[String] = []
		for f: String in daftar_flag:
			if rng.randf() < 0.3:
				konsumsi.append(f)
		c.flag_dikonsumsi = konsumsi
		c.tutorial_selesai = rng.randf() < 0.1
		var sebelum: Dictionary = state
		state = DataSave.catat_hari(state, c)
		# Oracle.
		o_hari = maxi(o_hari, hari + 1)
		o_koin += rute_koin + hadiah
		o_tip += tip
		for f2: String in konsumsi:
			o_flag.erase(f2)
		for f3: String in baru:
			if not o_flag.has(f3):
				o_flag.append(f3)
		if pilihan > 0:
			var lama: Variant = o_hasil.get(id)
			var sudah_selesai: bool = typeof(lama) == TYPE_DICTIONARY and (lama as Dictionary)["hasil"] == "selesai"
			if not sudah_selesai:
				o_hasil[id] = {"hasil": hasil, "hari": hari}
		if int(state["hari"]) < int(sebelum["hari"]) or int(state["koin"]) < int(sebelum["koin"]) or int(state["tip_total"]) < int(sebelum["tip_total"]):
			turun.append("langkah %d" % langkah)
		if state["hari"] != o_hari or state["koin"] != o_koin or state["tip_total"] != o_tip or state["flag"] != o_flag or state["misi_hasil"] != o_hasil:
			salah.append("langkah %d" % langkah)
		var selesai_sebelum: Dictionary = sebelum["misi_hasil"]
		for kunci: Variant in selesai_sebelum:
			var entri: Dictionary = selesai_sebelum[kunci]
			if entri["hasil"] == "selesai" and (state["misi_hasil"] as Dictionary)[kunci]["hasil"] != "selesai":
				salah.append("langkah %d: selesai ditimpa" % langkah)
		var t: Dictionary = state["terakhir"]
		if t["koin_misi"] != hadiah or t["misi_hasil"] != hasil or t["koin"] != rute_koin + hadiah:
			salah.append("langkah %d: terakhir" % langkah)
	check(turun.is_empty(), "400 hari acak: hari, koin, tip_total tidak pernah turun: %s" % [turun.slice(0, 3)])
	check(salah.is_empty(), "400 hari acak: state sama dengan oracle (maks hari + 1, koin = rute + hadiah, konsumsi lalu tambah, selesai tidak ditimpa): %s" % [salah.slice(0, 3)])
	check(state["koin"] > 0 and (state["misi_hasil"] as Dictionary).size() == 2, "deretan acak benar-benar mengisi koin dan dua id misi")
	# Gagal / tanpa misi tidak mengurangi apa pun (prinsip 2).
	var dasar: Dictionary = DataSave.templat()
	dasar["koin"] = 700
	dasar["tip_total"] = 40
	for hasil_tes: String in ["gagal", ""]:
		var s: Dictionary = DataSave.catat_hari(dasar, _catatan(3, _angka(0, 0, "p1_kucing" if hasil_tes != "" else "", hasil_tes)))
		check(s["koin"] == 700 and s["tip_total"] == 40 and s["hari"] == 4, "hari '%s' dengan koin 0: koin 700, tip 40, tidak berkurang, hari tetap maju" % hasil_tes)


func _test_tutorial_selesai() -> void:
	_judul.call("Save v2: tutorial.selesai ditulis di akhir hari dan tidak pernah kembali false (M-9)")
	var s: Dictionary = DataSave.catat_hari(DataSave.templat(), _catatan(1, _angka(10, 0)))
	check(s["tutorial"] == {"selesai": false}, "hari tanpa tutorial selesai: tutorial.selesai tetap false")
	var c: DataSave.CatatanHari = _catatan(1, _angka(10, 0))
	c.tutorial_selesai = true
	var s2: Dictionary = DataSave.catat_hari(DataSave.templat(), c)
	check(s2["tutorial"] == {"selesai": true}, "tutorial selesai atau dilewati: tutorial.selesai true")
	var s3: Dictionary = DataSave.catat_hari(s2, _catatan(2, _angka(10, 0)))
	check(s3["tutorial"] == {"selesai": true} and DataSave.tutorial_selesai(s3), "hari berikutnya tanpa catatan tutorial: tetap true (tidak diulang)")


# --- Flag terpakai dan rantai (AC-9) ---

func _entri(jenis: String, id: String) -> HeadlineManager.Entri:
	var e: HeadlineManager.Entri = HeadlineManager.Entri.new()
	e.id = id
	e.jenis = jenis
	return e


func _test_flag_terpakai() -> void:
	_judul.call("HeadlineManager.flag_terpakai: flag dari lanjutan yang tampil (AC-9)")
	var h: HeadlineManager.Halaman = HeadlineManager.Halaman.new()
	check(HeadlineManager.flag_terpakai(h, _pustaka).is_empty() and HeadlineManager.flag_terpakai(null, _pustaka).is_empty() and HeadlineManager.flag_terpakai(h, null).is_empty(), "halaman kosong, null: tidak ada flag terpakai")
	h.utama = _entri("utama", "utama_hajatan")
	h.ringan = _entri("lanjutan", "lanjutan_kucing_ketemu")
	check(HeadlineManager.flag_terpakai(h, _pustaka) == ["kucing_ketemu"], "lanjutan ringan yang tampil memakai flag kucing_ketemu")
	h.misi = _entri("lanjutan", "lanjutan_kucing_belum")
	check(HeadlineManager.flag_terpakai(h, _pustaka) == ["kucing_belum", "kucing_ketemu"], "dua lanjutan tampil: kedua flag terpakai (urut misi lalu ringan)")
	h.misi = _entri("misi", "p1_kucing")
	check(HeadlineManager.flag_terpakai(h, _pustaka) == ["kucing_ketemu"], "misi biasa (jenis misi) tidak mengonsumsi flag")
	h.ringan = _entri("ringan", "lanjutan_kucing_ketemu")
	check(HeadlineManager.flag_terpakai(h, _pustaka).is_empty(), "entri berjenis ringan walau id-nya sama tidak mengonsumsi (hanya jenis lanjutan)")
	h.ringan = _entri("lanjutan", "lanjutan_hantu")
	check(HeadlineManager.flag_terpakai(h, _pustaka).is_empty(), "lanjutan yang tidak ada di pustaka tidak mengonsumsi apa pun")


## Satu hari penuh: halaman dari save, misi diambil bila ditawarkan dan `ambil`, hasil `hasil` (selesai/gagal) bila diambil, lalu catat_hari lengkap.
## Mengembalikan {halaman, state}.
func _jalani_hari(state: Dictionary, ambil: bool, hasil: String, tambah_flag: Array[String] = []) -> Dictionary:
	var hari: int = int(state["hari"])
	var m: HeadlineManager.Masukan = HeadlineManager.Masukan.new()
	m.hari = hari
	m.flag = DataSave.daftar_flag(state)
	for f: String in tambah_flag:
		m.flag.append(f)
	m.headline_jeda = DataSave.daftar_jeda(state, "headline_jeda")
	m.misi_jeda = DataSave.daftar_jeda(state, "misi_jeda")
	m.pustaka = _pustaka
	m.misi = _misi
	var halaman: HeadlineManager.Halaman = HeadlineManager.susun(m)
	var diambil: String = halaman.misi.misi_id if ambil and halaman.misi != null else ""
	var misi_data: DataMisi = null
	for md: DataMisi in _misi:
		if md.id == diambil:
			misi_data = md
	var hasil_efektif: String = hasil if diambil != "" else ""
	var hadiah: int = misi_data.hadiah_koin() if hasil_efektif == "selesai" and misi_data != null else 0
	var jeda: HeadlineManager.JedaBaru = HeadlineManager.catat_jeda(halaman, diambil)
	var c: DataSave.CatatanHari = _catatan(hari, _angka(100 + hadiah, 0, diambil, hasil_efektif, hadiah))
	c.misi_diambil = diambil
	c.headline_jeda = jeda.headline
	c.misi_jeda = jeda.misi
	c.flag_dikonsumsi = HeadlineManager.flag_terpakai(halaman, _pustaka)
	var flag_hasil: String = MissionManager.flag_hasil(misi_data, hasil_efektif)
	if flag_hasil != "":
		c.flag_baru = [flag_hasil]
	return {"halaman": halaman, "state": DataSave.catat_hari(state, c)}


func _awal() -> Dictionary:
	return DataSave.templat()


func _test_rantai_selesai() -> void:
	_judul.call("Rantai nyata: hari 1 ambil P1 -> selesai -> hari 2 'Sudah Pulang' sekali -> hari 3 tidak lagi (AC-9)")
	var h1: Dictionary = _jalani_hari(_awal(), true, "selesai")
	var p1: HeadlineManager.Halaman = h1["halaman"]
	var s1: Dictionary = h1["state"]
	check(p1.misi != null and p1.misi.id == "p1_kucing" and s1["flag"] == ["kucing_ketemu"], "hari 1: P1 ditawarkan dan diambil, selesai -> flag kucing_ketemu menunggu tampil")
	check(s1["koin"] == 175 and s1["misi_hasil"] == {"p1_kucing": {"hasil": "selesai", "hari": 1}} and s1["terakhir"]["koin_misi"] == 75, "koin hari 1 = 100 rute + 75 hadiah; misi_hasil selesai di hari 1")
	var h2: Dictionary = _jalani_hari(s1, true, "selesai")
	var p2: HeadlineManager.Halaman = h2["halaman"]
	check(p2.ringan.id == "lanjutan_kucing_ketemu" and p2.ringan.jenis == "lanjutan", "hari 2: lanjutan 'Kucing Bu Ratmi Sudah Pulang ke Rumah' di slot ringan")
	check(p2.misi == null, "hari 2: slot misi kosong (P1 masih jeda 7 hari)")
	check(h2["state"]["flag"] == [], "flag kucing_ketemu dikonsumsi di akhir hari 2 (tampil sekali)")
	var h3: Dictionary = _jalani_hari(h2["state"], true, "selesai")
	check((h3["halaman"] as HeadlineManager.Halaman).ringan.id != "lanjutan_kucing_ketemu" and (h3["halaman"] as HeadlineManager.Halaman).misi == null, "hari 3: lanjutan tidak tampil lagi")


func _test_rantai_gagal() -> void:
	_judul.call("Rantai nyata: hari 1 ambil -> gagal -> hari 2 'Belum Ditemukan' sekali (slot misi, tanpa tombol) -> hari 3 tidak lagi (AC-9, K-4)")
	var h1: Dictionary = _jalani_hari(_awal(), true, "gagal")
	var s1: Dictionary = h1["state"]
	check(s1["flag"] == ["kucing_belum"] and s1["koin"] == 100 and s1["misi_hasil"] == {"p1_kucing": {"hasil": "gagal", "hari": 1}} and s1["terakhir"]["koin_misi"] == 0, "gagal: flag kucing_belum, koin 100 (hanya dari rute, tidak berkurang), tanpa hadiah")
	var h2: Dictionary = _jalani_hari(s1, true, "gagal")
	var p2: HeadlineManager.Halaman = h2["halaman"]
	check(p2.misi != null and p2.misi.id == "lanjutan_kucing_belum" and p2.misi.jenis == "lanjutan", "hari 2: lanjutan 'Kucing Bu Ratmi Belum Ditemukan' di slot misi")
	check(p2.misi.misi_id == "" , "baris lanjutan tanpa tombol Ambil/Lewati (misi_ditunda: tidak ada misi lanjutan, K-4)")
	check(h2["state"]["flag"] == [] and h2["state"]["koin"] == 200, "flag dikonsumsi di akhir hari 2; koin bertambah dari rute, tidak berkurang")
	var h3: Dictionary = _jalani_hari(h2["state"], true, "gagal")
	var p3: HeadlineManager.Halaman = h3["halaman"]
	check(p3.misi == null and p3.ringan.id != "lanjutan_kucing_ketemu", "hari 3: lanjutan tidak tampil lagi (kucing yang gagal dicari tidak muncul lagi besok, K-4)")


func _test_rantai_dilewati() -> void:
	_judul.call("Rantai nyata: hari 1 dilewati -> tanpa flag; hari 2 dan 3 sesuai tabel CONTENT_GUIDE 8 (AC-9)")
	var h1: Dictionary = _jalani_hari(_awal(), false, "selesai")
	var s1: Dictionary = h1["state"]
	check(s1["flag"] == [] and s1["misi_hasil"] == {} and s1["misi_jeda"] == {} and s1["terakhir"]["misi_hasil"] == "" and s1["koin"] == 100, "dilewati: tanpa flag, tanpa misi_hasil, tanpa jeda misi, koin dari rute saja")
	var h2: Dictionary = _jalani_hari(s1, false, "")
	check((h2["halaman"] as HeadlineManager.Halaman).misi != null and (h2["halaman"] as HeadlineManager.Halaman).misi.id == "p1_kucing", "hari 2: P1 ditawarkan lagi (melewati tidak memicu jeda)")
	var h3: Dictionary = _jalani_hari(h2["state"], false, "")
	check((h3["halaman"] as HeadlineManager.Halaman).misi != null and (h3["halaman"] as HeadlineManager.Halaman).misi.id == "p1_kucing", "hari 3: P1 masih ditawarkan")
	check(h3["state"]["flag"] == [] and h3["state"]["koin"] == 300, "tiga hari dilewati: tanpa flag, koin 300")


func _test_dua_flag() -> void:
	_judul.call("Dua flag aktif sekaligus (tes buatan): tidak crash, menghormati slot, keduanya dikonsumsi (AC-9)")
	var s: Dictionary = DataSave.templat()
	s["hari"] = 5
	s["flag"] = ["kucing_belum", "kucing_ketemu"]
	var h: Dictionary = _jalani_hari(s, true, "gagal")
	var p: HeadlineManager.Halaman = h["halaman"]
	check(p.misi.id == "lanjutan_kucing_belum" and p.ringan.id == "lanjutan_kucing_ketemu", "dua lanjutan menempati slotnya masing-masing (misi, ringan)")
	check(h["state"]["flag"] == [] and h["state"]["hari"] == 6, "kedua flag dikonsumsi")
	var asing: Dictionary = DataSave.templat()
	asing["hari"] = 3
	asing["flag"] = ["flag_hantu", "kucing_ketemu"]
	var h2: Dictionary = _jalani_hari(asing, false, "")
	check((h2["halaman"] as HeadlineManager.Halaman).ringan.id == "lanjutan_kucing_ketemu" and h2["state"]["flag"] == ["flag_hantu"], "flag hantu dibiarkan (tidak dikonsumsi), flag dikenal dikonsumsi")


func _test_rantai_empat_puluh_hari() -> void:
	_judul.call("Rantai 40 hari: P1 muncul lagi sesudah jeda 7 hari, lanjutan tepat sekali per hasil (AC-9, M-8)")
	var state: Dictionary = _awal()
	var muncul_p1: Array[int] = []
	var muncul_lanjutan: Array[int] = []
	var jenis_lanjutan: Array[String] = []
	var kali_hasil: int = 0
	var koin_oracle: int = 0
	var turun: bool = false
	var hasil_hari: Dictionary = {}
	for hari: int in range(1, 41):
		var hasil: String = "selesai" if kali_hasil % 2 == 0 else "gagal"
		var j: Dictionary = _jalani_hari(state, true, hasil)
		var p: HeadlineManager.Halaman = j["halaman"]
		if p.misi != null and p.misi.id == "p1_kucing":
			muncul_p1.append(hari)
			hasil_hari[hari] = hasil
			kali_hasil += 1
			koin_oracle += 100 + (75 if hasil == "selesai" else 0)
		else:
			koin_oracle += 100
		for e: HeadlineManager.Entri in [p.misi, p.ringan]:
			if e != null and e.jenis == "lanjutan":
				muncul_lanjutan.append(hari)
				jenis_lanjutan.append(e.id)
		if int((j["state"] as Dictionary)["koin"]) < int(state["koin"]):
			turun = true
		state = j["state"]
	check(muncul_p1 == [1, 8, 15, 22, 29, 36], "P1 ditawarkan tepat saat jeda 7 hari berakhir (hari diambil + 7): hari %s" % [muncul_p1])
	check(muncul_lanjutan == [2, 9, 16, 23, 30, 37], "lanjutan tampil tepat sekali, sehari sesudah tiap P1 diambil (hari %s), tidak ada tampil ganda atau terlewat" % [muncul_lanjutan])
	var harapan: Array[String] = []
	for hari_p1: int in muncul_p1:
		harapan.append("lanjutan_kucing_ketemu" if hasil_hari[hari_p1] == "selesai" else "lanjutan_kucing_belum")
	check(jenis_lanjutan == harapan, "lanjutan yang tampil sesuai hasil hari sebelumnya (selesai -> Sudah Pulang, gagal -> Belum Ditemukan): %s" % [jenis_lanjutan])
	check(state["flag"] == [] or state["flag"] == ["kucing_ketemu"] or state["flag"] == ["kucing_belum"], "flag akhir: paling banyak hasil hari terakhir yang belum tampil")
	check(state["koin"] == koin_oracle and not turun, "koin 40 hari = oracle tes (100 per hari + hadiah selesai) dan tidak pernah turun")
	check((state["misi_hasil"] as Dictionary)["p1_kucing"]["hasil"] == "selesai", "riwayat permanen: P1 selesai tidak ditimpa gagal sesudahnya")


# --- Tabel di dokumen (CONTENT_GUIDE 8) ---

func _test_tabel_dokumen() -> void:
	_judul.call("CONTENT_GUIDE 8: baris 'setelah ketemu' dan 'setelah gagal' = rantai nyata (AC-9, AC-21)")
	var panduan: String = FileAccess.get_file_as_string("res://docs/CONTENT_GUIDE.md")
	for hasil: String in ["selesai", "gagal"]:
		var state: Dictionary = _jalani_hari(_awal(), true, hasil)["state"]
		for hari: int in [2, 3]:
			var j: Dictionary = _jalani_hari(state, true, hasil)
			var p: HeadlineManager.Halaman = j["halaman"]
			var nama_hasil: String = "setelah ketemu" if hasil == "selesai" else "setelah gagal"
			var baris: String = "| %d (%s) | %s | %s | %s |" % [hari, nama_hasil, tr(p.utama.teks), tr(p.misi.teks) if p.misi != null else "(tidak ada misi)", tr(p.ringan.teks)]
			check(panduan.contains(baris), "tabel CONTENT_GUIDE 8 memuat: %s" % baris)
			state = j["state"]
