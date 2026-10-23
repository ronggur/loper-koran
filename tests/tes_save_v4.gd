class_name TesSaveV4
extends RefCounted
## Tes save v4 run fase6a2-reputasi-pelanggan bagian A (AC-5, AC-6): `reputasi` {distrik: 0..100} dan `pelanggan` {id rumah: {status, antar, meleset, hari_berhenti}}. Migrasi dari empat fixture nyata
## (save 6A1 v3 = contoh DATA_SCHEMA 4 sebelum run ini, 4B v2, 4A v1, v0), invarian save-system (versi lebih baru tidak ditimpa, tipe salah = rusak, nilai tak sah dijepit, id dibiarkan), bulak-balik
## byte demi byte, `catat_hari` menerapkan `ReputationManager` tepat sekali dan fuzz 300 hari. Jalur uji `user://tes_save_v4/` (TIDAK pernah menyentuh `user://save.json`).

const SKRIP_SIMPAN: String = "res://scripts/autoload/save_manager.gd"
const SAVE_ASLI: String = "user://save.json"
const FOLDER_TES: String = "user://tes_save_v4"
## Save 6A1 asli (format v3) persis seperti contoh DATA_SCHEMA 4 sebelum run ini: hari 2, saldo 105, koin_total 195, satu servis.
const SAVE_6A1: String = """{
	"flag": [
		"kucing_ketemu"
	],
	"hari": 2,
	"headline_jeda": {
		"ringan_mangga": 4,
		"utama_jalan_diperbaiki": 5
	},
	"koin": 105,
	"koin_total": 195,
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
	"sepeda": {
		"ban": {
			"kondisi": 1.0,
			"level": 0
		},
		"rantai": {
			"kondisi": 1.0,
			"level": 0
		},
		"rem": {
			"kondisi": 1.0,
			"level": 0
		},
		"servis_total": 1
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
	"versi": 3
}"""

var _cek: Callable
var _judul: Callable
var _kep: Array[KepribadianPelanggan.Entri] = []
var _id_boleh: Array[String] = []


func _init(cek: Callable, judul: Callable) -> void:
	_cek = cek
	_judul = judul


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	var sebelum: Dictionary = _jejak_save_asli()
	_kep = PemuatPelanggan.muat().entri
	for s: SegmenRute in PemuatRute.muat_folder("res://assets/data/routes/perumahan").segmen:
		for r: SegmenRute.Rumah in s.rumah:
			if r.pelanggan_boleh:
				_id_boleh.append("%s@%d" % [s.id, r.pos])
	_test_config_dan_templat()
	_test_migrasi_fixture()
	_test_tipe_salah_dan_versi_baru()
	_test_normalisasi()
	_test_bulak_balik()
	_test_catat_hari_sekali()
	_test_catat_hari_fuzz()
	_test_save_manager_v4()
	var sesudah: Dictionary = _jejak_save_asli()
	check(sebelum == sesudah, "user://save.json tidak tersentuh oleh tes save v4 (%s -> %s) (AC-17)" % [sebelum, sesudah])


func _jejak_save_asli() -> Dictionary:
	var ada: bool = FileAccess.file_exists(SAVE_ASLI)
	return {"ada": ada, "ukuran": FileAccess.get_file_as_bytes(SAVE_ASLI).size() if ada else 0, "sha": FileAccess.get_sha256(SAVE_ASLI) if ada else ""}


func _bersihkan_folder() -> void:
	var dir: DirAccess = DirAccess.open(FOLDER_TES)
	if dir == null:
		return
	for nama: String in dir.get_files():
		DirAccess.remove_absolute(FOLDER_TES.path_join(nama))
	DirAccess.remove_absolute(FOLDER_TES)


func _entri(status: String, antar: int = 0, meleset: int = 0, hari_berhenti: int = 0) -> Dictionary:
	return {"status": status, "antar": antar, "meleset": meleset, "hari_berhenti": hari_berhenti}


# --- AC-5 ---

func _test_config_dan_templat() -> void:
	_judul.call("Save v4: SAVE_VERSI 4, templat memuat reputasi awal dan pelanggan kosong (AC-5)")
	var t: Dictionary = DataSave.templat()
	check(Config.SAVE_VERSI == 4 and t["versi"] == 4, "Config.SAVE_VERSI = 4 dan templat versi 4")
	check(t["reputasi"] == {"perumahan": Config.REPUTASI_AWAL} and Config.REPUTASI_AWAL == 0, "templat: reputasi {perumahan: 0}")
	check(t["pelanggan"] == {}, "templat: pelanggan kosong")
	check(DataSave.dari_teks(DataSave.ke_teks(t)).state == t, "templat bulak-balik sama")


func _test_migrasi_fixture() -> void:
	_judul.call("Save v4: migrasi dari save 6A1 (v3) asli, 4B (v2), 4A (v1), dan v0 tanpa kehilangan field lama (AC-5)")
	var asli_6a1: Dictionary = JSON.parse_string(SAVE_6A1)
	var h6: DataSave.Hasil = DataSave.dari_teks(SAVE_6A1)
	check(h6.status == DataSave.Status.SAH and not h6.perlu_salinan(), "save 6A1 terbaca SAH, tidak perlu disalin")
	var s6: Dictionary = h6.state
	# Oracle: bentuk v3 yang sama dengan hanya `versi`, `reputasi`, dan `pelanggan` ditambah tangan, hanya dinormalisasi (tanpa langkah migrasi).
	var langsung: Dictionary = asli_6a1.duplicate(true)
	langsung["versi"] = 4
	langsung["reputasi"] = {"perumahan": 0}
	langsung["pelanggan"] = {}
	var harapan: Dictionary = DataSave.dari_teks(JSON.stringify(langsung)).state
	check(s6 == harapan and DataSave.ke_teks(s6) == DataSave.ke_teks(harapan), "migrasi 6A1 = save yang sama ditambah reputasi dan pelanggan awal, tanpa perubahan lain")
	var kunci_lama: Array[String] = []
	for k: String in asli_6a1:
		kunci_lama.append(k)
		check(s6.has(k), "field v3 '%s' masih ada" % k)
	check(s6.size() == kunci_lama.size() + 2, "hanya dua field baru (reputasi, pelanggan) yang ditambahkan")
	check(s6["versi"] == 4 and s6["reputasi"] == {"perumahan": 0} and s6["pelanggan"] == {}, "6A1 -> v4: reputasi awal 0, pelanggan kosong")
	check(s6["koin"] == 105 and s6["koin_total"] == 195 and s6["sepeda"]["servis_total"] == 1 and s6["hari"] == 2 and s6["flag"] == ["kucing_ketemu"], "angka kunci 6A1 dipertahankan (saldo 105, total 195, servis 1, hari 2, flag)")
	check(DataSave.migrasi(s6) == s6, "migrasi save v4 idempoten")
	var mentah: Dictionary = JSON.parse_string(SAVE_6A1)
	var salinan: Dictionary = mentah.duplicate(true)
	DataSave.migrasi(mentah)
	check(mentah == salinan, "migrasi tidak mengubah masukan")
	# v2 (4B)
	var h4b: DataSave.Hasil = DataSave.dari_teks(TesSaveV3.SAVE_4B)
	var s4b: Dictionary = h4b.state
	check(h4b.status == DataSave.Status.SAH and s4b["versi"] == 4 and s4b["koin"] == 195 and s4b["koin_total"] == 195 and s4b["reputasi"] == {"perumahan": 0} and s4b["pelanggan"] == {} and s4b["flag"] == ["kucing_ketemu"] and s4b["tutorial"] == {"selesai": true}, "4B (v2) -> v4: field v2 dan v3 dipertahankan, reputasi dan pelanggan awal")
	# v1 (4A)
	var h4a: DataSave.Hasil = DataSave.dari_teks(TesMisiSave.SAVE_4A)
	var s4a: Dictionary = h4a.state
	check(h4a.status == DataSave.Status.SAH and s4a["versi"] == 4 and s4a["koin"] == 120 and s4a["koin_total"] == 120 and s4a["tip_total"] == 25 and s4a["hari"] == 2 and s4a["reputasi"] == {"perumahan": 0} and s4a["pelanggan"] == {}, "4A (v1) -> v4: hari 2, koin 120, tip 25, reputasi dan pelanggan awal")
	# v0
	var v0: DataSave.Hasil = DataSave.dari_teks('{"hari": 7, "koin": 1500, "flag": ["kucing_belum", "flag_lama"], "pengaturan": {"kidal": true, "mode_bantu": true}}')
	check(v0.status == DataSave.Status.SAH and v0.state["versi"] == 4 and v0.state["hari"] == 7 and v0.state["koin"] == 1500 and v0.state["flag"] == ["kucing_belum", "flag_lama"] and v0.state["pengaturan"]["kidal"] == true and v0.state["reputasi"] == {"perumahan": 0}, "v0 -> v4: hari, koin, flag, pengaturan dipertahankan")
	var kosong: Dictionary = DataSave.dari_teks('{"versi": 3}').state
	check(kosong["reputasi"] == {"perumahan": 0} and kosong["pelanggan"] == {}, "v3 tanpa isi: reputasi dan pelanggan bawaan")
	# save v3 yang membawa reputasi/pelanggan (mis. diedit): migrasi menimpa dengan awal (v3 tidak mengenalnya)
	var liar: Dictionary = DataSave.migrasi({"versi": 3, "reputasi": {"perumahan": 77}, "pelanggan": {"a@1": {"status": "setia"}}})
	check(liar["reputasi"] == {"perumahan": 0} and liar["pelanggan"] == {}, "field v4 di save berversi 3 tidak dipercaya: diganti awal")


func _test_tipe_salah_dan_versi_baru() -> void:
	_judul.call("Save v4: tipe salah = rusak, versi lebih baru tidak ditimpa (AC-5, rule save-system)")
	for teks: String in ['{"versi": 4, "reputasi": 5}', '{"versi": 4, "reputasi": []}', '{"versi": 4, "pelanggan": 3}', '{"versi": 4, "pelanggan": [1]}', '{"versi": 4, "reputasi": "tinggi"}']:
		var h: DataSave.Hasil = DataSave.dari_teks(teks)
		check(h.status == DataSave.Status.RUSAK and h.perlu_salinan() and h.state == DataSave.templat(), "%s: RUSAK, perlu disalin, state bawaan" % teks)
	for versi: int in [5, 6, 99]:
		var h2: DataSave.Hasil = DataSave.dari_teks('{"versi": %d, "reputasi": {"perumahan": 50}}' % versi)
		check(h2.status == DataSave.Status.TERLALU_BARU and h2.perlu_salinan() and h2.state == DataSave.templat(), "versi %d: TERLALU_BARU, perlu disalin, state bawaan" % versi)
	# lewat SaveManager jalur uji: berkas v5 tidak diubah dan disalin
	_bersihkan_folder()
	DirAccess.make_dir_recursive_absolute(FOLDER_TES)
	var jalur: String = FOLDER_TES.path_join("save.json")
	var isi: String = '{"versi": 5, "reputasi": {"perumahan": 50}, "masa_depan": true}'
	var f: FileAccess = FileAccess.open(jalur, FileAccess.WRITE)
	f.store_string(isi)
	f.close()
	var m: Node = (load(SKRIP_SIMPAN) as GDScript).new()
	m.set(&"jalur", jalur)
	m.set(&"lapor_ke_log", false)
	m.call(&"muat", 1234)
	var salinan: String = str(m.get(&"jalur_salinan_rusak"))
	check(m.get(&"status_muat") == DataSave.Status.TERLALU_BARU and not salinan.is_empty() and FileAccess.get_file_as_string(salinan) == isi, "versi 5: disalin utuh")
	check(FileAccess.get_file_as_string(jalur) == isi and (m.get(&"state") as Dictionary) == DataSave.templat(), "berkas versi 5 tidak diubah oleh muat; permainan mulai dari state bawaan")
	m.free()
	_bersihkan_folder()


func _test_normalisasi() -> void:
	_judul.call("Save v4: nilai tak sah dijepit atau diganti bawaan, id dibiarkan (AC-5)")
	var s: Dictionary = DataSave.migrasi({
		"versi": 4,
		"reputasi": {"perumahan": 150, "ruko": -9, "pasar": "tinggi", "desa": 12.7, "": 5, "sungai": null},
		"pelanggan": {
			"a@1": {"status": "galak", "antar": -4, "meleset": 5000, "hari_berhenti": 9, "ekstra": true},
			"b@2": {"status": "berhenti", "antar": 2.0, "meleset": 2, "hari_berhenti": -5},
			"c@3": {"status": "setia", "antar": "banyak", "hari_berhenti": 12},
			"d@4": 7,
			"": {"status": "aktif"},
			"id_tak_ada_di_data@99": {"status": "berhenti", "antar": 1, "meleset": 3, "hari_berhenti": 4},
		},
	})
	var rep: Dictionary = s["reputasi"]
	check(rep["perumahan"] == 100 and rep["ruko"] == 0 and rep["pasar"] == 0 and rep["desa"] == 12 and rep["sungai"] == 0 and not rep.has(""), "reputasi: 150 -> 100, -9 -> 0, teks -> 0, 12,7 -> 12, null -> 0, id kosong dibuang")
	check(DataSave.migrasi({"versi": 4, "reputasi": {"ruko": 5}})["reputasi"] == {"ruko": 5, "perumahan": 0}, "distrik awal selalu ada, distrik lain dibiarkan")
	var p: Dictionary = s["pelanggan"]
	check(p["a@1"] == _entri("aktif", 0, Config.PELANGGAN_HITUNG_MAKS, 0), "status asing -> aktif, antar negatif -> 0, meleset raksasa dijepit, hari_berhenti bukan-berhenti -> 0, field asing dibuang; dapat %s" % [p["a@1"]])
	check(p["b@2"] == _entri("berhenti", 2, 2, 0), "berhenti dengan hari_berhenti negatif -> 0; antar 2.0 -> 2")
	check(p["c@3"] == _entri("setia", 0, 0, 0), "antar teks -> 0; setia dengan hari_berhenti -> 0")
	check(not p.has("d@4") and not p.has(""), "entri bukan objek dan id kosong dibuang")
	check(p["id_tak_ada_di_data@99"] == _entri("berhenti", 1, 3, 4), "id yang tidak ada di data dibiarkan apa adanya (rule save-system)")
	check(DataSave.migrasi(s) == s, "hasil normalisasi stabil (idempoten)")


func _test_bulak_balik() -> void:
	_judul.call("Save v4: bulak-balik teks byte demi byte, kunci terurut (AC-5)")
	var s: Dictionary = DataSave.templat()
	s["reputasi"] = {"perumahan": 37, "ruko": 4}
	s["pelanggan"] = {"per_buka_01@6": _entri("setia", 8, 0, 0), "per_tengah_02@12": _entri("berhenti", 3, 2, 5), "per_tutup_01@30": _entri("aktif", 1, 1, 0)}
	var teks: String = DataSave.ke_teks(s)
	var h: DataSave.Hasil = DataSave.dari_teks(teks)
	check(h.status == DataSave.Status.SAH and h.state == s and DataSave.ke_teks(h.state) == teks, "teks -> state -> teks sama byte demi byte")
	check(teks.find("\"pelanggan\"") > teks.find("\"misi_jeda\"") and teks.find("\"reputasi\"") > teks.find("\"pelanggan\""), "kunci teks terurut abjad (misi_jeda < pelanggan < reputasi)")
	check(teks.contains("\"hari_berhenti\": 5") and not teks.contains("37.0") and not teks.contains("\"antar\": 8.0"), "angka bulat tercetak sebagai bilangan bulat, bukan desimal")


# --- AC-6 ---

func _catatan_hari(hari: int, koin: int, pel: ReputationManager.Catatan) -> DataSave.CatatanHari:
	var c: DataSave.CatatanHari = DataSave.CatatanHari.new()
	c.hari = hari
	var a: HasilRute.Angka = HasilRute.Angka.new()
	a.pelanggan = 25
	a.terkirim = 10
	a.meleset = 15
	a.koin = koin
	a.skor = 100
	c.angka = a
	c.pelanggan = pel
	c.kepribadian = _kep
	return c


func _test_catat_hari_sekali() -> void:
	_judul.call("catat_hari v4 menerapkan ReputationManager tepat sekali per hari (AC-6)")
	var sens: String = ""
	for id: String in _id_boleh:
		if KepribadianPelanggan.dari_id(id, _kep) == KepribadianPelanggan.SENSITIF:
			sens = id
			break
	var lain: String = _id_boleh[0] if _id_boleh[0] != sens else _id_boleh[1]
	var pel: ReputationManager.Catatan = ReputationManager.Catatan.new()
	pel.hari = 3
	for d: Array in [[lain, true, SkorRute.Kualitas.TEPAT], [sens, false, -1]]:
		var r: ReputationManager.CatatanRumah = ReputationManager.CatatanRumah.new()
		r.id = d[0]
		r.terantar = d[1]
		r.kualitas = d[2]
		pel.rumah.append(r)
	var awal: Dictionary = DataSave.templat()
	awal["hari"] = 3
	awal["reputasi"] = {"perumahan": 20}
	awal["pelanggan"] = {sens: _entri("aktif", 0, 1, 0)}
	var langsung: ReputationManager.Hasil = ReputationManager.terapkan(awal, pel, _kep)
	var baru: Dictionary = DataSave.catat_hari(awal, _catatan_hari(3, 300, pel))
	check(baru["reputasi"] == langsung.state["reputasi"] and baru["pelanggan"] == langsung.state["pelanggan"], "reputasi dan pelanggan di save = hasil ReputationManager.terapkan yang sama")
	check(baru["reputasi"]["perumahan"] == 20 + langsung.perubahan and baru["pelanggan"][sens]["status"] == "berhenti" and baru["pelanggan"][lain]["status"] == "aktif", "contoh: sensitif berhenti (-1), antaran tepat 4 kredit (0 poin): reputasi 19")
	check(baru["hari"] == 4 and baru["koin"] == 300 and baru["koin_total"] == 300, "hari maju satu dan koin masuk persis sekali")
	# tanpa catatan pelanggan: reputasi dan pelanggan tidak berubah
	var tanpa: Dictionary = DataSave.catat_hari(awal, _catatan_hari(3, 0, null))
	check(tanpa["reputasi"] == awal["reputasi"] and tanpa["pelanggan"] == awal["pelanggan"], "catatan.pelanggan null: reputasi dan pelanggan tidak berubah")
	# masukan tidak diubah
	var salinan: Dictionary = awal.duplicate(true)
	DataSave.catat_hari(awal, _catatan_hari(3, 300, pel))
	check(awal == salinan, "catat_hari tidak mengubah state masukan")
	# dua hari berbeda = dua penerapan (bukan idempoten per panggilan; satu panggilan = satu penerapan)
	var hari2: Dictionary = DataSave.catat_hari(baru, _catatan_hari(4, 300, pel))
	check(hari2["pelanggan"][lain]["antar"] == baru["pelanggan"][lain]["antar"] + 1, "hari berikutnya menerapkan sekali lagi (antar bertambah satu)")
	# hari tidak mundur dan koin_total hanya naik
	check(hari2["hari"] > baru["hari"] and hari2["koin_total"] >= baru["koin_total"], "hari dan koin_total hanya naik")
	# reputasi tidak pernah di bawah 0 lewat catat_hari
	var nol: Dictionary = awal.duplicate(true)
	nol["reputasi"] = {"perumahan": 0}
	check(DataSave.catat_hari(nol, _catatan_hari(3, 0, pel))["reputasi"]["perumahan"] == 0, "penalti pada reputasi 0 tetap 0")


func _test_catat_hari_fuzz() -> void:
	_judul.call("catat_hari v4: fuzz 300 hari, invarian reputasi, pelanggan, hari, koin_total, dan bulak-balik (AC-5, AC-6)")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 40404
	var state: Dictionary = DataSave.templat()
	var salah: Array[String] = []
	var hari_lalu: int = 1
	var total_lalu: int = 0
	for hari: int in range(1, 301):
		var pel: ReputationManager.Catatan = ReputationManager.Catatan.new()
		pel.hari = hari
		for i: int in range(25):
			var r: ReputationManager.CatatanRumah = ReputationManager.CatatanRumah.new()
			r.id = _id_boleh[rng.randi_range(0, _id_boleh.size() - 1)]
			r.terantar = rng.randf() < 0.6
			r.kualitas = rng.randi_range(0, 4) if r.terantar else -1
			pel.rumah.append(r)
		if rng.randf() < 0.15:
			var m: ReputationManager.CatatanMisi = ReputationManager.CatatanMisi.new()
			m.selesai = rng.randf() < 0.5
			m.gagal = not m.selesai
			m.tingkat = ["kecil", "sedang", "besar"][rng.randi_range(0, 2)]
			m.setia = rng.randf() < 0.5
			m.id_rumah = _id_boleh[rng.randi_range(0, _id_boleh.size() - 1)]
			m.gagal_reputasi = rng.randi_range(0, 1)
			pel.misi = m
		state = DataSave.catat_hari(state, _catatan_hari(hari, rng.randi_range(0, 400), pel))
		var rep: int = int(state["reputasi"]["perumahan"])
		if rep < 0 or rep > 100:
			salah.append("hari %d reputasi %d" % [hari, rep])
		if int(state["hari"]) < hari_lalu or int(state["koin_total"]) < total_lalu:
			salah.append("hari %d progres turun" % hari)
		hari_lalu = int(state["hari"])
		total_lalu = int(state["koin_total"])
		for id: Variant in state["pelanggan"]:
			var e: Dictionary = state["pelanggan"][id]
			if not Config.PELANGGAN_STATUS.has(e["status"]) or int(e["antar"]) < 0 or int(e["meleset"]) < 0 or (e["status"] != "berhenti" and int(e["hari_berhenti"]) != 0):
				salah.append("hari %d entri %s rusak" % [hari, id])
		if not salah.is_empty():
			break
	check(salah.is_empty(), "300 hari: reputasi 0..100, hari dan koin_total hanya naik, entri pelanggan sah (%s)" % [salah])
	check(DataSave.dari_teks(DataSave.ke_teks(state)).state == state and DataSave.migrasi(state) == state, "state akhir bulak-balik dan stabil")


func _test_save_manager_v4() -> void:
	_judul.call("SaveManager (jalur uji): akhiri_hari menulis reputasi dan pelanggan sekali; berkas terbaca sebagai v4 (AC-6)")
	_bersihkan_folder()
	DirAccess.make_dir_recursive_absolute(FOLDER_TES)
	var jalur: String = FOLDER_TES.path_join("save.json")
	var f: FileAccess = FileAccess.open(jalur, FileAccess.WRITE)
	f.store_string(SAVE_6A1)
	f.close()
	var m: Node = (load(SKRIP_SIMPAN) as GDScript).new()
	m.set(&"jalur", jalur)
	m.set(&"lapor_ke_log", false)
	m.call(&"muat")
	var state: Dictionary = m.get(&"state")
	check(m.get(&"status_muat") == DataSave.Status.SAH and state["versi"] == 4 and state["reputasi"] == {"perumahan": 0} and m.get(&"jumlah_simpan") == 0, "memuat save 6A1: dimigrasi ke v4 di memori, nol simpan")
	check(FileAccess.get_file_as_string(jalur) == SAVE_6A1, "berkas 6A1 belum diubah sampai akhiri_hari")
	var pel: ReputationManager.Catatan = ReputationManager.Catatan.new()
	pel.hari = 2
	var r: ReputationManager.CatatanRumah = ReputationManager.CatatanRumah.new()
	r.id = _id_boleh[0]
	r.terantar = true
	r.kualitas = SkorRute.Kualitas.TERAS
	pel.rumah.append(r)
	check(m.call(&"akhiri_hari", _catatan_hari(2, 120, pel)) == true and m.get(&"jumlah_simpan") == 1, "akhiri_hari menulis tepat satu kali")
	var terbaca: DataSave.Hasil = DataSave.dari_teks(FileAccess.get_file_as_string(jalur))
	check(terbaca.status == DataSave.Status.SAH and terbaca.state["versi"] == 4 and terbaca.state["pelanggan"].has(_id_boleh[0]) and terbaca.state["pelanggan"][_id_boleh[0]] == _entri("aktif", 1, 0, 0) and terbaca.state["hari"] == 3, "berkas: v4, pelanggan tercatat, hari 3; dapat %s" % [terbaca.state["pelanggan"]])
	check(FileAccess.get_file_as_string(jalur) == DataSave.ke_teks(terbaca.state), "berkas yang ditulis sama byte demi byte dengan ke_teks(state)")
	m.free()
	_bersihkan_folder()
