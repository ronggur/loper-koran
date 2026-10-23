class_name TesSaveV3
extends RefCounted
## Tes save v3 run fase6a1-bengkel-kondisi (AC-1 sampai AC-3): `koin` = saldo, `koin_total`, `sepeda`. Migrasi dari tiga fixture nyata (bentuk save 4B asli dari contoh DATA_SCHEMA 4
## sebelum run ini, save 4A, dan tanpa `versi`), versi > 3 tidak ditimpa (lewat `SaveManager` jalur uji), `sepeda` bertipe salah = rusak, nilai di luar jangkauan dijepit, bulak-balik
## byte demi byte, dan `catat_hari` dengan sepeda akhir dan belanja terhadap oracle variabel berjalan (fuzz berseed). Jalur uji `user://tes_save_v3/` (TIDAK pernah menyentuh `user://save.json`).

const SKRIP_SIMPAN: String = "res://scripts/autoload/save_manager.gd"
const SAVE_ASLI: String = "user://save.json"
const FOLDER_TES: String = "user://tes_save_v3"
## Save 4B asli (format v2) persis seperti contoh DATA_SCHEMA 4 sebelum run ini: hari 2, koin 195, flag kucing_ketemu, P1 selesai.
const SAVE_4B: String = """{
	"flag": [
		"kucing_ketemu"
	],
	"hari": 2,
	"headline_jeda": {
		"ringan_mangga": 4,
		"utama_jalan_diperbaiki": 5
	},
	"koin": 195,
	"misi_hasil": {
		"p1_kucing": {
			"hari": 1,
			"hasil": "selesai"
		}
	},
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
		"koin": 195,
		"koin_misi": 75,
		"meleset": 22,
		"misi_diambil": "p1_kucing",
		"misi_hasil": "selesai",
		"skor": 1500,
		"terkirim": 3,
		"tip": 25
	},
	"tip_total": 25,
	"tutorial": {
		"selesai": true
	},
	"versi": 2
}"""

var _cek: Callable
var _judul: Callable


func _init(cek: Callable, judul: Callable) -> void:
	_cek = cek
	_judul = judul


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	var sebelum: Dictionary = _jejak_save_asli()
	_test_config_dan_templat()
	_test_migrasi_4b()
	_test_migrasi_4a_dan_v0()
	_test_sepeda_tak_sah()
	_test_versi_baru_tidak_ditimpa()
	_test_bulak_balik()
	_test_catat_hari_belanja_dan_sepeda()
	_test_catat_hari_fuzz()
	_test_save_manager_v3()
	var sesudah: Dictionary = _jejak_save_asli()
	check(sebelum == sesudah, "user://save.json tidak tersentuh oleh tes save v3 (ada/ukuran/sha256 sama: %s -> %s) (AC-20)" % [sebelum, sesudah])


func _jejak_save_asli() -> Dictionary:
	var ada: bool = FileAccess.file_exists(SAVE_ASLI)
	return {"ada": ada, "ukuran": FileAccess.get_file_as_bytes(SAVE_ASLI).size() if ada else 0, "sha": FileAccess.get_sha256(SAVE_ASLI) if ada else ""}


func _sepeda_baru() -> Dictionary:
	return {"ban": {"kondisi": 1.0, "level": 0}, "rem": {"kondisi": 1.0, "level": 0}, "rantai": {"kondisi": 1.0, "level": 0}, "servis_total": 0}


func _angka(koin: int, tip: int) -> HasilRute.Angka:
	var a: HasilRute.Angka = HasilRute.Angka.new()
	a.pelanggan = 25
	a.terkirim = 10
	a.meleset = 15
	a.koin = koin
	a.koin_tip = tip
	a.skor = 100
	return a


func _catatan(hari: int, koin: int, tip: int = 0) -> DataSave.CatatanHari:
	var c: DataSave.CatatanHari = DataSave.CatatanHari.new()
	c.hari = hari
	c.angka = _angka(koin, tip)
	return c


func _bersihkan_folder() -> void:
	var dir: DirAccess = DirAccess.open(FOLDER_TES)
	if dir == null:
		return
	for nama: String in dir.get_files():
		DirAccess.remove_absolute(FOLDER_TES.path_join(nama))
	DirAccess.remove_absolute(FOLDER_TES)


# --- AC-1 ---

func _test_config_dan_templat() -> void:
	_judul.call("Save v3: SAVE_VERSI 3 dan templat memuat koin, koin_total, sepeda (AC-1)")
	check(Config.SAVE_VERSI == 4, "Config.SAVE_VERSI = 4 (run 6A2 menaikkan dari 3; tes v3 menjaga migrasi dari v3, bukan versi sekarang)")
	var t: Dictionary = DataSave.templat()
	check(t["versi"] == 4 and t["koin"] == 0 and t["koin_total"] == 0 and t["sepeda"] == _sepeda_baru(), "templat v3: koin 0, koin_total 0, sepeda tiga komponen kondisi 1,0 level 0, servis_total 0; dapat %s" % [t])
	check(DataSave.sepeda_baru() == _sepeda_baru(), "DataSave.sepeda_baru() = sepeda baru")
	check(DataSave.ke_teks(t).contains('"koin_total": 0') and DataSave.ke_teks(t).contains('"servis_total": 0'), "teks templat memuat koin_total dan servis_total")


# --- AC-2 ---

func _test_migrasi_4b() -> void:
	_judul.call("Save v3: migrasi dari fixture save 4B asli (v2, hari 2, koin 195, flag kucing_ketemu) (AC-2)")
	var hasil: DataSave.Hasil = DataSave.dari_teks(SAVE_4B)
	var s: Dictionary = hasil.state
	check(hasil.status == DataSave.Status.SAH and not hasil.perlu_salinan(), "save 4B terbaca SAH, tidak perlu disalin (dimigrasi, tidak dihapus)")
	var harapan: Dictionary = {
		"versi": 4, "hari": 2, "koin": 195, "koin_total": 195, "tip_total": 25, "sepeda": _sepeda_baru(), "reputasi": {"perumahan": 0}, "pelanggan": {}, "flag": ["kucing_ketemu"],
		"misi_jeda": {"p1_kucing": 8}, "headline_jeda": {"ringan_mangga": 4, "utama_jalan_diperbaiki": 5},
		"misi_hasil": {"p1_kucing": {"hasil": "selesai", "hari": 1}}, "tutorial": {"selesai": true},
		"terakhir": {"hari": 1, "terkirim": 3, "meleset": 22, "koin": 195, "tip": 25, "skor": 1500, "koin_misi": 75, "potongan": 0, "misi_hasil": "selesai", "misi_diambil": "p1_kucing"},
		"pengaturan": {"kidal": false, "mode_bantu": false, "suara": 1.0, "musik": 1.0},
	}
	check(s == harapan, "hasil migrasi 4B = oracle tangan: semua field v2 sama, koin_total = 195, sepeda baru; dapat %s" % [s])
	check(s["koin_total"] == s["koin"], "koin_total awal = koin v2")
	for k: String in Config.KONDISI_KOMPONEN:
		check(s["sepeda"][k]["kondisi"] == 1.0 and s["sepeda"][k]["level"] == 0, "sepeda hasil migrasi: %s kondisi 1,0 level 0 (tidak ada kerusakan atau upgrade gratis)" % k)
	check(s["sepeda"]["servis_total"] == 0, "servis_total 0")
	check(DataSave.migrasi(s) == s, "migrasi save v3 idempoten")
	var mentah: Dictionary = JSON.parse_string(SAVE_4B)
	var salinan: Dictionary = mentah.duplicate(true)
	DataSave.migrasi(mentah)
	check(mentah == salinan, "migrasi tidak mengubah masukan")


func _test_migrasi_4a_dan_v0() -> void:
	_judul.call("Save v3: migrasi dari save 4A (v1) dan tanpa versi (v0) (AC-2)")
	var a: Dictionary = DataSave.dari_teks(TesMisiSave.SAVE_4A).state
	check(a["versi"] == 4 and a["hari"] == 2 and a["koin"] == 120 and a["koin_total"] == 120 and a["tip_total"] == 25 and a["sepeda"] == _sepeda_baru(), "4A (v1): hari 2, koin 120, koin_total 120, tip 25, sepeda baru")
	check(a["misi_jeda"] == {"p1_kucing": 8} and a["misi_hasil"] == {} and a["tutorial"] == {"selesai": false}, "4A: jeda dipertahankan, field v2 bawaan")
	var v0: Dictionary = DataSave.dari_teks('{"hari": 7, "koin": 1500, "flag": ["kucing_belum", "flag_lama"], "pengaturan": {"kidal": true}}').state
	check(v0["versi"] == 4 and v0["hari"] == 7 and v0["koin"] == 1500 and v0["koin_total"] == 1500 and v0["flag"] == ["kucing_belum", "flag_lama"] and v0["pengaturan"]["kidal"] == true and v0["sepeda"] == _sepeda_baru(), "v0: hari 7, koin 1500, koin_total 1500, flag dan kidal dipertahankan, sepeda baru; dapat %s" % [v0])
	var kosong: Dictionary = DataSave.dari_teks('{"versi": 2}').state
	check(kosong["koin"] == 0 and kosong["koin_total"] == 0 and kosong["sepeda"] == _sepeda_baru(), "v2 minimal: koin 0, koin_total 0")
	# Save v2 yang memuat sepeda liar (tidak pernah ditulis 4B): diganti sepeda baru, tidak ada upgrade gratis.
	var liar: Dictionary = DataSave.migrasi({"versi": 2, "koin": 50, "sepeda": {"ban": {"kondisi": 0.1, "level": 5}, "servis_total": 9}})
	check(liar["sepeda"] == _sepeda_baru() and liar["koin_total"] == 50, "v2 dengan sepeda liar: sepeda baru (tanpa upgrade atau kerusakan gratis), koin_total = koin")


func _test_sepeda_tak_sah() -> void:
	_judul.call("Save v3: sepeda bertipe salah = rusak; kondisi di luar 0..1 atau bukan angka dijepit; id komponen asing dibiarkan (AC-2)")
	for teks: String in ['{"versi": 3, "sepeda": 5}', '{"versi": 3, "sepeda": []}', '{"versi": 3, "sepeda": {"ban": 5}}', '{"versi": 3, "sepeda": {"rem": "baik"}}', '{"versi": 3, "sepeda": {"rantai": []}}', '{"versi": 3, "sepeda": {"servis_total": "banyak"}}', '{"versi": 3, "koin_total": "x"}']:
		var h: DataSave.Hasil = DataSave.dari_teks(teks)
		check(h.status == DataSave.Status.RUSAK and h.perlu_salinan() and h.state == DataSave.templat(), "%s: RUSAK, disalin, state bawaan" % teks)
	var luar: DataSave.Hasil = DataSave.dari_teks('{"versi": 3, "koin": 10, "koin_total": 10, "sepeda": {"ban": {"kondisi": 7, "level": -3}, "rem": {"kondisi": "abc", "level": 2.0}, "rantai": {"kondisi": -0.4}, "setang": {"kondisi": 0.3, "level": 9}, "servis_total": -4}}')
	var sp: Dictionary = luar.state["sepeda"]
	check(luar.status == DataSave.Status.SAH, "kondisi di luar jangkauan atau bukan angka bukan save rusak")
	check(sp["ban"] == {"kondisi": 1.0, "level": 0} and sp["rem"] == {"kondisi": 1.0, "level": 2} and sp["rantai"] == {"kondisi": 0.0, "level": 0}, "ban 7 -> 1,0 level -3 -> 0; rem 'abc' -> 1,0 level 2; rantai -0,4 -> 0,0; dapat %s" % [sp])
	check(sp["setang"]["kondisi"] == 0.3 and sp["setang"]["level"] == 9 and sp["servis_total"] == 0, "id komponen asing (setang) dibiarkan apa adanya; servis_total negatif -> 0")
	var n: Dictionary = DataSave.migrasi({"versi": 3, "koin": 5, "koin_total": 5, "sepeda": {"ban": {"kondisi": INF, "level": 1}, "rem": {"kondisi": -INF}, "rantai": {"kondisi": NAN}}})
	check(n["sepeda"]["ban"]["kondisi"] == 1.0 and n["sepeda"]["rem"]["kondisi"] == 0.0 and n["sepeda"]["rantai"]["kondisi"] == 1.0, "tak hingga dijepit ke 0..1, NaN = 1,0 (tidak crash)")
	check(DataSave.migrasi({"versi": 3, "koin": 500, "koin_total": 10})["koin_total"] == 500, "koin_total tidak pernah di bawah saldo koin (dinaikkan ke 500)")
	check(DataSave.migrasi({"versi": 3, "koin": -9, "koin_total": -9})["koin"] == 0 and DataSave.migrasi({"versi": 3, "koin": -9, "koin_total": -9})["koin_total"] == 0, "saldo dan total negatif dijepit 0")
	var bulat: Dictionary = DataSave.migrasi({"versi": 3, "sepeda": {"ban": {"kondisi": 0.123456, "level": 0}}})
	check(bulat["sepeda"]["ban"]["kondisi"] == 0.1235, "kondisi dibulatkan 4 desimal (0,123456 -> 0,1235)")


func _test_versi_baru_tidak_ditimpa() -> void:
	_judul.call("Save v3: versi > 3 TIDAK ditimpa, disalin dulu (AC-2, rule save-system)")
	for versi: int in [5, 6, 99]:
		var h: DataSave.Hasil = DataSave.dari_teks('{"versi": %d, "koin": 777}' % versi)
		check(h.status == DataSave.Status.TERLALU_BARU and h.perlu_salinan() and h.state == DataSave.templat(), "versi %d: TERLALU_BARU, perlu disalin, state bawaan" % versi)
	check(DataSave.dari_teks('{"versi": 3, "koin": 777}').status == DataSave.Status.SAH, "versi 3 sah (dimigrasi ke versi sekarang)")
	# Lewat SaveManager jalur uji: berkas versi 4 disalin ke save.corrupt.<waktu>.json dan berkas asli tidak diubah sebelum simpan.
	_bersihkan_folder()
	DirAccess.make_dir_recursive_absolute(FOLDER_TES)
	var jalur: String = FOLDER_TES.path_join("save.json")
	var isi: String = '{"versi": 5, "koin": 777, "masa_depan": true}'
	var f: FileAccess = FileAccess.open(jalur, FileAccess.WRITE)
	f.store_string(isi)
	f.close()
	var m: Node = (load(SKRIP_SIMPAN) as GDScript).new()
	m.set(&"jalur", jalur)
	m.set(&"lapor_ke_log", false)
	m.call(&"muat", 1234)
	var salinan: String = str(m.get(&"jalur_salinan_rusak"))
	check(m.get(&"status_muat") == DataSave.Status.TERLALU_BARU and not salinan.is_empty() and FileAccess.get_file_as_string(salinan) == isi, "versi 5: disalin utuh ke %s" % salinan)
	check(FileAccess.get_file_as_string(jalur) == isi and (m.get(&"state") as Dictionary) == DataSave.templat(), "berkas versi 5 tidak diubah oleh muat; permainan mulai dari state bawaan")
	check(m.call(&"ambil_notifikasi") == "KORAN_SAVE_RUSAK", "pemain diberi tahu satu kali")
	m.free()
	_bersihkan_folder()


func _test_bulak_balik() -> void:
	_judul.call("Save v3: bulak-balik byte demi byte, kondisi terbulatkan tercetak stabil (AC-1)")
	var s: Dictionary = DataSave.templat()
	s["koin"] = 480
	s["koin_total"] = 1210
	s["sepeda"]["ban"]["kondisi"] = BikeCondition.bulatkan(0.30000000000000004)
	s["sepeda"]["rem"]["kondisi"] = BikeCondition.bulatkan(0.1 + 0.2 + 0.1234567)
	s["sepeda"]["rantai"] = {"kondisi": 0.0, "level": 1}
	s["sepeda"]["servis_total"] = 3
	var teks: String = DataSave.ke_teks(s)
	var baca: DataSave.Hasil = DataSave.dari_teks(teks)
	check(baca.status == DataSave.Status.SAH and baca.state == s, "state v3 terisi -> teks -> state sama")
	check(DataSave.ke_teks(baca.state) == teks, "tulis lalu baca lalu tulis lagi: teks sama byte demi byte")
	check(teks.contains('"kondisi": 0.3') and not teks.contains("0.30000000000000004") and teks.contains('"kondisi": 0.4235'), "kondisi tercetak ringkas (0.3, 0.4235), tanpa ekor float")
	var lagi: String = DataSave.ke_teks(DataSave.dari_teks(DataSave.ke_teks(DataSave.dari_teks(teks).state)).state)
	check(lagi == teks, "dua kali bulak-balik tetap sama")
	var hasil_catat: Dictionary = DataSave.catat_hari(s, _catatan(3, 275, 15))
	check(DataSave.ke_teks(DataSave.dari_teks(DataSave.ke_teks(hasil_catat)).state) == DataSave.ke_teks(hasil_catat), "hasil catat_hari juga stabil byte demi byte")


# --- AC-3 ---

func _test_catat_hari_belanja_dan_sepeda() -> void:
	_judul.call("DataSave.catat_hari v3: koin hari masuk saldo dan koin_total sekali, belanja hanya mengurangi saldo, sepeda akhir ditulis (AC-3)")
	var awal: Dictionary = DataSave.dari_teks(SAVE_4B).state
	var asli: Dictionary = awal.duplicate(true)
	var c: DataSave.CatatanHari = _catatan(2, 330, 25)
	c.belanja_koin = 200
	c.sepeda = {"ban": {"kondisi": 0.55555, "level": 0}, "rem": {"kondisi": 1.0, "level": 1}, "rantai": {"kondisi": 0.2, "level": 0}, "servis_total": 2}
	var s: Dictionary = DataSave.catat_hari(awal, c)
	check(awal == asli, "catat_hari tidak mengubah state masukan")
	check(s["hari"] == 3, "hari = hari dimainkan + 1")
	check(s["koin"] == 195 + 330 - 200, "koin (saldo) = 195 + 330 - 200 = 325")
	check(s["koin_total"] == 195 + 330, "koin_total = 195 + 330 (belanja tidak mengurangi)")
	check(s["tip_total"] == 25 + 25, "tip_total hanya naik oleh tip (belanja tidak mengubahnya)")
	check(s["sepeda"]["ban"] == {"kondisi": 0.5556, "level": 0} and s["sepeda"]["rem"] == {"kondisi": 1.0, "level": 1} and s["sepeda"]["rantai"] == {"kondisi": 0.2, "level": 0} and s["sepeda"]["servis_total"] == 2, "sepeda akhir ditulis (kondisi dibulatkan 4 desimal); dapat %s" % [s["sepeda"]])
	# Hari dengan koin 0 dan tanpa belanja tidak mengurangi apa pun.
	var nol: Dictionary = DataSave.catat_hari(s, _catatan(3, 0, 0))
	check(nol["koin"] == s["koin"] and nol["koin_total"] == s["koin_total"] and nol["tip_total"] == s["tip_total"] and nol["sepeda"] == s["sepeda"] and nol["hari"] == 4, "hari koin 0 tanpa belanja: koin, koin_total, tip_total, sepeda sama; hari naik")
	# Sepeda kosong = tidak berubah.
	var tanpa: DataSave.CatatanHari = _catatan(3, 100)
	check(DataSave.catat_hari(s, tanpa)["sepeda"] == s["sepeda"], "catatan tanpa sepeda akhir: sepeda di save tidak berubah")
	# level dan servis_total hanya naik: catatan lebih rendah tidak menurunkan.
	var turun: DataSave.CatatanHari = _catatan(3, 0)
	turun.sepeda = {"rem": {"kondisi": 0.5, "level": 0}, "servis_total": 0}
	var t: Dictionary = DataSave.catat_hari(s, turun)
	check(t["sepeda"]["rem"]["level"] == 1 and t["sepeda"]["servis_total"] == 2 and t["sepeda"]["rem"]["kondisi"] == 0.5 and t["sepeda"]["ban"] == s["sepeda"]["ban"], "level dan servis_total tidak turun; kondisi boleh turun (aus); komponen yang tidak disebut tetap")
	# Belanja melebihi saldo dijepit 0 (tidak pernah negatif).
	var lebih: DataSave.CatatanHari = _catatan(3, 10)
	lebih.belanja_koin = 99999
	check(DataSave.catat_hari(s, lebih)["koin"] == 0 and DataSave.catat_hari(s, lebih)["koin_total"] == s["koin_total"] + 10, "belanja melebihi saldo: koin 0, koin_total tetap naik oleh koin hari")
	var negatif: DataSave.CatatanHari = _catatan(3, 10)
	negatif.belanja_koin = -500
	check(DataSave.catat_hari(s, negatif)["koin"] == int(s["koin"]) + 10, "belanja negatif tidak menambah koin")


func _test_catat_hari_fuzz() -> void:
	_judul.call("DataSave.catat_hari v3: deretan hari acak berseed vs oracle variabel berjalan (AC-3)")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 6102
	var state: Dictionary = DataSave.templat()
	var o_koin: int = 0
	var o_total: int = 0
	var o_tip: int = 0
	var o_hari: int = 1
	var o_servis: int = 0
	var o_level: Dictionary = {"ban": 0, "rem": 0, "rantai": 0}
	var rapi: bool = true
	var galat: String = ""
	for i: int in range(300):
		var koin_hari: int = rng.randi_range(0, 400) if rng.randi() % 5 != 0 else 0
		var tip: int = mini(koin_hari, rng.randi_range(0, 40))
		var c: DataSave.CatatanHari = _catatan(o_hari, koin_hari, tip)
		var belanja: int = rng.randi_range(0, o_koin + koin_hari) if rng.randi() % 2 == 0 else 0
		c.belanja_koin = belanja
		var sepeda: Dictionary = {}
		for k: String in Config.KONDISI_KOMPONEN:
			var naik: bool = rng.randi() % 4 == 0
			sepeda[k] = {"kondisi": rng.randf(), "level": int(o_level[k]) + (1 if naik else 0)}
			if naik:
				o_level[k] = int(o_level[k]) + 1
		o_servis += rng.randi() % 3
		sepeda["servis_total"] = o_servis
		c.sepeda = sepeda
		state = DataSave.catat_hari(state, c)
		o_koin += koin_hari - belanja
		o_total += koin_hari
		o_tip += tip
		o_hari += 1
		var salah: Array[String] = []
		if state["koin"] != o_koin:
			salah.append("koin %s != %d" % [state["koin"], o_koin])
		if state["koin_total"] != o_total:
			salah.append("koin_total %s != %d" % [state["koin_total"], o_total])
		if state["tip_total"] != o_tip:
			salah.append("tip_total")
		if state["hari"] != o_hari:
			salah.append("hari")
		if int(state["koin"]) < 0 or int(state["koin"]) > int(state["koin_total"]):
			salah.append("saldo di luar 0..koin_total")
		if state["sepeda"]["servis_total"] != o_servis:
			salah.append("servis_total")
		for k: String in Config.KONDISI_KOMPONEN:
			var kondisi: float = float(state["sepeda"][k]["kondisi"])
			if state["sepeda"][k]["level"] != o_level[k] or kondisi < 0.0 or kondisi > 1.0 or absf(kondisi - BikeCondition.bulatkan(float(sepeda[k]["kondisi"]))) > 0.0000001:
				salah.append("sepeda " + k)
		if not salah.is_empty():
			rapi = false
			galat = "hari %d: %s" % [o_hari - 1, salah]
			break
	check(rapi, "300 hari acak: koin, koin_total, tip_total, hari, servis_total, level, kondisi sama dengan oracle; saldo 0..koin_total: %s" % galat)
	check(DataSave.dari_teks(DataSave.ke_teks(state)).state == state, "state akhir 300 hari bulak-balik sama")


func _test_save_manager_v3() -> void:
	_judul.call("SaveManager (jalur uji): akhiri_hari v3 menulis saldo, total, dan sepeda sekali; berkas terbaca sebagai v3 (AC-3, AC-20)")
	_bersihkan_folder()
	DirAccess.make_dir_recursive_absolute(FOLDER_TES)
	var jalur: String = FOLDER_TES.path_join("save.json")
	var f: FileAccess = FileAccess.open(jalur, FileAccess.WRITE)
	f.store_string(SAVE_4B)
	f.close()
	var m: Node = (load(SKRIP_SIMPAN) as GDScript).new()
	m.set(&"jalur", jalur)
	m.set(&"lapor_ke_log", false)
	m.call(&"muat")
	var state: Dictionary = m.get(&"state")
	check(m.get(&"status_muat") == DataSave.Status.SAH and state["versi"] == 4 and state["koin_total"] == 195 and m.get(&"jumlah_simpan") == 0, "memuat save 4B: dimigrasi ke v3 di memori, nol simpan")
	check(FileAccess.get_file_as_string(jalur) == SAVE_4B, "berkas 4B belum diubah sampai akhiri_hari")
	var c: DataSave.CatatanHari = _catatan(2, 300, 20)
	c.belanja_koin = 80
	c.sepeda = {"ban": {"kondisi": 1.0, "level": 0}, "rem": {"kondisi": 1.0, "level": 1}, "rantai": {"kondisi": 0.6, "level": 0}, "servis_total": 1}
	check(m.call(&"akhiri_hari", c) == true and m.get(&"jumlah_simpan") == 1, "akhiri_hari menulis tepat satu kali")
	var terbaca: DataSave.Hasil = DataSave.dari_teks(FileAccess.get_file_as_string(jalur))
	check(terbaca.status == DataSave.Status.SAH and terbaca.state["versi"] == 4 and terbaca.state["koin"] == 195 + 300 - 80 and terbaca.state["koin_total"] == 495 and terbaca.state["sepeda"]["rem"]["level"] == 1 and terbaca.state["sepeda"]["rantai"]["kondisi"] == 0.6 and terbaca.state["hari"] == 3, "berkas: v3, koin 415, koin_total 495, rem level 1, rantai 0,6, hari 3; dapat %s" % [terbaca.state])
	check(FileAccess.get_file_as_string(jalur) == DataSave.ke_teks(terbaca.state), "berkas yang ditulis sama byte demi byte dengan ke_teks(state)")
	m.free()
	_bersihkan_folder()
