class_name TesHari
extends RefCounted
## Tes logika murni dan berkas run fase4a-koran-hari bagian A (AC-7 sampai AC-12, AC-14 sampai AC-16, AC-20, AC-25): `SeedHari`, `MesinHari`,
## `DataSave`, dan `SaveManager` (autoload, diuji tanpa scene tree lewat `load(...).new()` dengan jalur berkas disuntik).
##
## Oracle independen (AC-25, pelajaran QA-008 run 2B): seed, tabel transisi, dan hasil `catat_hari` dihitung tes dengan cara lain (literal,
## tabel sendiri, dan variabel berjalan yang dihitung tes), bukan dengan memanggil fungsi yang dites. TIDAK PERNAH menyentuh `user://save.json`:
## seluruh I/O memakai folder sementara `user://tes_save_4a/` yang dihapus lagi, dan keberadaan, ukuran, serta sha256 `user://save.json` dicek
## sebelum dan sesudah (AC-8).

const FOLDER_RUTE: String = "res://assets/data/routes/perumahan"
const SKRIP_SIMPAN: String = "res://scripts/autoload/save_manager.gd"
const SAVE_ASLI: String = "user://save.json"
const FOLDER_TES: String = "user://tes_save_4a"
## Seed rute hari N ditulis ulang di sini: 20261100 + N x 1000003.
const DASAR_RUTE: int = 20261100
const DASAR_HEADLINE: int = 31415926
const LANGKAH: int = 1000003

var _cek: Callable
var _judul: Callable
var _pustaka_cache: Array[SegmenRute] = []


func _init(cek: Callable, judul: Callable) -> void:
	_cek = cek
	_judul = judul


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	var sebelum: Dictionary = _jejak_save_asli()
	_test_config()
	_test_seed_literal()
	_test_seed_enam_puluh_hari()
	_test_mesin_tabel()
	_test_mesin_alur_dan_ganda()
	_test_mesin_back()
	_test_save_templat_dan_bulak_balik()
	_test_save_migrasi_v0()
	_test_save_id_tak_dikenal_dan_nilai_tak_sah()
	_test_save_rusak_dan_terlalu_baru()
	_test_catat_hari_dari_angka()
	_test_catat_hari_progres_tidak_turun()
	_test_lewati_tanpa_penalti()
	_test_save_manager_tulis_baca()
	_test_save_manager_atomik()
	_test_save_manager_rusak()
	_test_save_manager_tidak_terbaca()
	_test_save_manager_baca_balik_dan_rename()
	_test_save_manager_autoload()
	var sesudah: Dictionary = _jejak_save_asli()
	check(sebelum == sesudah, "user://save.json tidak tersentuh oleh tes (ada/ukuran/sha256 sama: %s -> %s) (AC-8)" % [sebelum, sesudah])


# --- Pembantu ---

func _pustaka() -> Array[SegmenRute]:
	if _pustaka_cache.is_empty():
		_pustaka_cache = PemuatRute.muat_folder(FOLDER_RUTE).segmen
	return _pustaka_cache


func _jejak_save_asli() -> Dictionary:
	var ada: bool = FileAccess.file_exists(SAVE_ASLI)
	return {"ada": ada, "ukuran": FileAccess.get_file_as_bytes(SAVE_ASLI).size() if ada else 0, "sha": FileAccess.get_sha256(SAVE_ASLI) if ada else ""}


func _angka(terkirim: int, meleset: int, koin: int, tip: int, skor: int) -> HasilRute.Angka:
	var a: HasilRute.Angka = HasilRute.Angka.new()
	a.pelanggan = terkirim + meleset
	a.terkirim = terkirim
	a.meleset = meleset
	a.koin = koin
	a.koin_tip = tip
	a.jumlah_tip = 1 if tip > 0 else 0
	a.skor = skor
	return a


func _catatan(hari: int, angka: HasilRute.Angka, misi: String = "") -> DataSave.CatatanHari:
	var c: DataSave.CatatanHari = DataSave.CatatanHari.new()
	c.hari = hari
	c.angka = angka
	c.misi_diambil = misi
	return c


func _sidik_rute(rute: RouteBuilder.Rute) -> String:
	var bagian: Array[String] = []
	for s: SegmenRute in rute.segmen:
		bagian.append(s.id)
	for r: RouteBuilder.RumahRute in rute.pelanggan:
		bagian.append(r.id)
	return ",".join(bagian)


func _bersihkan_folder_tes() -> void:
	var dir: DirAccess = DirAccess.open(FOLDER_TES)
	if dir == null:
		return
	for nama: String in dir.get_files():
		DirAccess.remove_absolute(FOLDER_TES.path_join(nama))
	for sub: String in dir.get_directories():
		DirAccess.remove_absolute(FOLDER_TES.path_join(sub))
	DirAccess.remove_absolute(FOLDER_TES)


func _tulis(jalur: String, teks: String) -> void:
	DirAccess.make_dir_recursive_absolute(jalur.get_base_dir())
	var berkas: FileAccess = FileAccess.open(jalur, FileAccess.WRITE)
	berkas.store_string(teks)
	berkas.close()


## Nama berkas salinan rusak (`save.corrupt.*`) di folder tes, terurut.
func _salinan_di_folder() -> Array[String]:
	var hasil: Array[String] = []
	var dir: DirAccess = DirAccess.open(FOLDER_TES)
	if dir == null:
		return hasil
	for nama: String in dir.get_files():
		if nama.begins_with("save.corrupt."):
			hasil.append(nama)
	hasil.sort()
	return hasil


func _manajer() -> Node:
	var skrip: GDScript = load(SKRIP_SIMPAN) as GDScript
	var m: Node = skrip.new()
	m.set(&"jalur", FOLDER_TES.path_join("save.json"))
	m.set(&"lapor_ke_log", false)
	return m


# --- Config ---

func _test_config() -> void:
	_judul.call("Hari, seed, dan save: angka Config literal (AC-7, AC-15)")
	var harapan: Dictionary = {
		"HARI_AWAL": 1, "SEED_HARI_LANGKAH": LANGKAH, "SEED_RUTE_DASAR": DASAR_RUTE, "SEED_HEADLINE_DASAR": DASAR_HEADLINE, "SAVE_VERSI": 4,
		"SAVE_BERKAS": "user://save.json", "SAVE_SEMENTARA_EKSTENSI": "tmp", "SAVE_RUSAK_PENANDA": ".corrupt.", "SAVE_VOLUME_BAWAAN": 1.0,
	}
	var peta: Dictionary = (load("res://scripts/config.gd") as GDScript).get_script_constant_map()
	for nama: String in harapan:
		check(peta.get(nama) == harapan[nama], "Config.%s = %s (literal), dapat %s" % [nama, harapan[nama], peta.get(nama)])


# --- SeedHari (AC-15) ---

func _test_seed_literal() -> void:
	_judul.call("SeedHari: nilai literal dan murni (AC-15)")
	check(SeedHari.rute(1) == 21261103 and SeedHari.rute(2) == 22261106 and SeedHari.rute(60) == 80261280, "seed rute hari 1, 2, 60 = 21261103, 22261106, 80261280 (dasar + hari x langkah)")
	check(SeedHari.headline(1) == 32415929 and SeedHari.headline(5) == 36415941, "seed headline hari 1 dan 5 = 32415929 dan 36415941")
	check(SeedHari.campur(100, 3) == 100 + 3 * LANGKAH, "campur(dasar, hari) = dasar + hari x langkah")
	check(SeedHari.rute(7) == SeedHari.rute(7) and SeedHari.headline(7) == SeedHari.headline(7), "seed hari yang sama selalu sama (murni)")
	check(SeedHari.rute(7) != SeedHari.headline(7), "seed rute dan seed headline hari yang sama berbeda (aliran acak tidak dibagi)")


func _test_seed_enam_puluh_hari() -> void:
	_judul.call("SeedHari: 60 hari rute sah, seed berbeda, hari sama identik (AC-15)")
	var terlihat: Dictionary = {}
	var sidik: Dictionary = {}
	var semua_sah: bool = true
	var identik: bool = true
	var galat_pertama: String = ""
	for hari: int in range(1, 61):
		var benih: int = DASAR_RUTE + hari * LANGKAH
		terlihat[benih] = true
		var a: RouteBuilder.Hasil = RouteBuilder.bangun(SeedHari.rute(hari), _pustaka())
		var b: RouteBuilder.Hasil = RouteBuilder.bangun(SeedHari.rute(hari), _pustaka())
		if not a.sah() or not RouteBuilder.periksa_rute(a.rute).is_empty():
			semua_sah = false
			galat_pertama = "hari %d: %s" % [hari, a.galat]
			continue
		if not b.sah() or _sidik_rute(a.rute) != _sidik_rute(b.rute):
			identik = false
		sidik[_sidik_rute(a.rute)] = true
	check(semua_sah, "rute hari 1 sampai 60 sah lewat RouteBuilder (periksa_rute kosong) %s" % galat_pertama)
	check(terlihat.size() == 60, "60 seed rute berbeda antar hari (oracle: dasar + hari x langkah)")
	check(identik, "rute hari yang sama identik (sidik jari id segmen + pelanggan sama)")
	check(sidik.size() >= 55, "rute antar hari bervariasi: sidik jari berbeda sedikitnya 55 dari 60 hari (dapat %d)" % sidik.size())
	check(SeedHari.rute(1) != Config.RUTE_SEED_DEV and RouteBuilder.bangun(SeedHari.rute(1), _pustaka()).rute.benih == SeedHari.rute(1), "rute hari 1 memakai seed hari (bukan seed dev) dan menyimpannya di Rute.benih")


# --- MesinHari (AC-16) ---

func _test_mesin_tabel() -> void:
	_judul.call("MesinHari: tabel transisi (AC-16, AC-19 run fase6a1-bengkel-kondisi)")
	# Oracle: enam belas pasangan (keadaan, peristiwa); hanya empat yang sah. Sejak run 6A1 "Hari berikutnya" hanya sah dari bengkel (alasan perubahan tes lama: hasil/berikut kini ditolak).
	var K: Dictionary = {"koran": MesinHari.Keadaan.KORAN, "rute": MesinHari.Keadaan.RUTE, "hasil": MesinHari.Keadaan.HASIL, "bengkel": MesinHari.Keadaan.BENGKEL}
	var P: Dictionary = {"berangkat": MesinHari.Peristiwa.BERANGKAT, "hasil": MesinHari.Peristiwa.HASIL_TERBUKA, "berikut": MesinHari.Peristiwa.HARI_BERIKUTNYA, "bengkel": MesinHari.Peristiwa.BUKA_BENGKEL}
	var sah: Dictionary = {"koran/berangkat": "rute", "rute/hasil": "hasil", "hasil/bengkel": "bengkel", "bengkel/berikut": "koran"}
	for k: String in K:
		for p: String in P:
			var status: MesinHari.Status = MesinHari.awal(5)
			status.keadaan = K[k]
			var hasil: MesinHari.Status = MesinHari.terapkan(status, P[p])
			var kunci: String = "%s/%s" % [k, p]
			if sah.has(kunci):
				check(hasil.diterima and hasil.keadaan == K[sah[kunci]], "%s diterima -> %s" % [kunci, sah[kunci]])
				check(MesinHari.boleh(K[k], P[p]), "boleh(%s) true" % kunci)
			else:
				check(not hasil.diterima and hasil.keadaan == K[k] and hasil.hari == 5, "%s ditolak tanpa efek (keadaan dan hari sama)" % kunci)
				check(not MesinHari.boleh(K[k], P[p]), "boleh(%s) false" % kunci)
	var awal: MesinHari.Status = MesinHari.awal(5)
	var ke_hasil: MesinHari.Status = MesinHari.awal(5)
	ke_hasil.keadaan = MesinHari.Keadaan.BENGKEL
	check(MesinHari.terapkan(ke_hasil, MesinHari.Peristiwa.HARI_BERIKUTNYA).hari == 6 and MesinHari.terapkan(awal, MesinHari.Peristiwa.BERANGKAT).hari == 5, "hari naik tepat 1 hanya pada HARI_BERIKUTNYA")
	var salinan_awal: MesinHari.Status = MesinHari.terapkan(awal, MesinHari.Peristiwa.BERANGKAT)
	check(awal.keadaan == MesinHari.Keadaan.KORAN and awal.diterima and salinan_awal != awal, "terapkan tidak mengubah status masukan")


func _test_mesin_alur_dan_ganda() -> void:
	_judul.call("MesinHari: satu hari utuh dan ketukan ganda tidak menggandakan (AC-16, AC-19)")
	var s: MesinHari.Status = MesinHari.awal(3)
	var diterima: int = 0
	for p: MesinHari.Peristiwa in [MesinHari.Peristiwa.BERANGKAT, MesinHari.Peristiwa.BERANGKAT, MesinHari.Peristiwa.HASIL_TERBUKA, MesinHari.Peristiwa.HASIL_TERBUKA,
			MesinHari.Peristiwa.BUKA_BENGKEL, MesinHari.Peristiwa.BUKA_BENGKEL, MesinHari.Peristiwa.HARI_BERIKUTNYA, MesinHari.Peristiwa.HARI_BERIKUTNYA, MesinHari.Peristiwa.HARI_BERIKUTNYA]:
		s = MesinHari.terapkan(s, p)
		if s.diterima:
			diterima += 1
	check(diterima == 4, "dari sembilan peristiwa (tiap peristiwa diketuk dua kali, hari berikutnya tiga kali) hanya empat yang diterima, dapat %d" % diterima)
	check(s.keadaan == MesinHari.Keadaan.KORAN and s.hari == 4, "satu hari utuh berakhir di KORAN hari 4 (hari naik sekali walau 'Hari berikutnya' diketuk tiga kali)")
	var s2: MesinHari.Status = MesinHari.awal(1)
	var jalan: Array[int] = []
	for i: int in range(5):
		s2 = MesinHari.terapkan(MesinHari.terapkan(MesinHari.terapkan(MesinHari.terapkan(s2, MesinHari.Peristiwa.BERANGKAT), MesinHari.Peristiwa.HASIL_TERBUKA), MesinHari.Peristiwa.BUKA_BENGKEL), MesinHari.Peristiwa.HARI_BERIKUTNYA)
		jalan.append(s2.hari)
	check(jalan == [2, 3, 4, 5, 6], "lima hari berturut-turut: hari 2, 3, 4, 5, 6, dapat %s" % [jalan])


func _test_mesin_back() -> void:
	_judul.call("MesinHari: perilaku tombol back per keadaan (S-6, AC-16)")
	check(MesinHari.aksi_back(MesinHari.Keadaan.KORAN) == MesinHari.AksiBack.KELUAR_APP, "back di koran = keluar app")
	check(MesinHari.aksi_back(MesinHari.Keadaan.RUTE) == MesinHari.AksiBack.JEDA_RUTE, "back di rute = jeda")
	check(MesinHari.aksi_back(MesinHari.Keadaan.HASIL) == MesinHari.AksiBack.ABAIKAN, "back di layar hasil = diabaikan")
	check(MesinHari.aksi_back(MesinHari.Keadaan.BENGKEL) == MesinHari.AksiBack.LEWATI_BENGKEL, "back di bengkel = lewati bengkel (sama dengan Hari berikutnya, M-8)")


# --- DataSave (AC-7, AC-10) ---

func _test_save_templat_dan_bulak_balik() -> void:
	_judul.call("DataSave: templat v3 dan bulak-balik teks (AC-7, AC-1 run fase6a1-bengkel-kondisi)")
	var t: Dictionary = DataSave.templat()
	var harapan: Dictionary = {
		"versi": 4, "hari": 1, "koin": 0, "koin_total": 0, "sepeda": {"ban": {"kondisi": 1.0, "level": 0}, "rem": {"kondisi": 1.0, "level": 0}, "rantai": {"kondisi": 1.0, "level": 0}, "servis_total": 0}, "reputasi": {"perumahan": 0}, "pelanggan": {}, "tip_total": 0, "flag": [], "misi_jeda": {}, "headline_jeda": {}, "misi_hasil": {}, "tutorial": {"selesai": false}, "terakhir": {},
		"pengaturan": {"kidal": false, "mode_bantu": false, "suara": 1.0, "musik": 1.0},
	}
	check(t == harapan, "templat = save baru: versi 4, hari 1, koin 0, tanpa flag, pengaturan bawaan; dapat %s" % [t])
	var hasil: DataSave.Hasil = DataSave.dari_teks(DataSave.ke_teks(t))
	check(hasil.status == DataSave.Status.SAH and hasil.state == t, "templat -> teks -> state bulak-balik sama (status SAH)")
	var t2: Dictionary = DataSave.templat()
	t2["hari"] = 12
	t2["koin"] = 3400
	t2["koin_total"] = 3400  # v3: koin_total tidak pernah di bawah saldo
	t2["flag"] = ["kucing_belum"]
	t2["pengaturan"]["kidal"] = true
	var h2: DataSave.Hasil = DataSave.dari_teks(DataSave.ke_teks(t2))
	check(h2.status == DataSave.Status.SAH and h2.state == t2, "state terisi bulak-balik sama (angka JSON float kembali jadi int)")
	check(typeof(h2.state["hari"]) == TYPE_INT and typeof(h2.state["koin"]) == TYPE_INT, "hari dan koin hasil baca bertipe int, bukan float")
	check(DataSave.ke_teks(t2) == DataSave.ke_teks(t2.duplicate(true)), "teks save berurut kunci: isi sama = teks sama byte demi byte")


func _test_save_migrasi_v0() -> void:
	_judul.call("DataSave: migrasi v0 -> v3 tanpa kehilangan data sah (AC-10)")
	# Fixture v0: save sebelum ada `versi`, hanya sebagian field.
	var v0: String = '{"hari": 7, "koin": 1500, "flag": ["kucing_belum", "flag_lama"], "pengaturan": {"kidal": true, "mode_bantu": true}}'
	var hasil: DataSave.Hasil = DataSave.dari_teks(v0)
	var s: Dictionary = hasil.state
	check(hasil.status == DataSave.Status.SAH, "fixture v0 terbaca SAH, bukan rusak")
	check(s["versi"] == 4, "versi menjadi 4 (SAVE_VERSI)")
	check(s["hari"] == 7 and s["koin"] == 1500, "hari 7 dan koin 1500 dipertahankan")
	check(s["flag"] == ["kucing_belum", "flag_lama"], "flag dipertahankan (termasuk yang tidak dikenal data)")
	check(s["pengaturan"]["kidal"] == true and s["pengaturan"]["mode_bantu"] == true, "pengaturan kidal dan mode_bantu dipertahankan")
	check(s["pengaturan"]["suara"] == 1.0 and s["pengaturan"]["musik"] == 1.0, "volume yang belum ada mendapat bawaan 1.0 dari templat")
	check(s["tip_total"] == 0 and s["misi_jeda"] == {} and s["headline_jeda"] == {} and s["terakhir"] == {}, "field baru mendapat nilai bawaan templat")
	check(s["misi_hasil"] == {} and s["tutorial"] == {"selesai": false}, "field v2 (misi_hasil, tutorial) mendapat nilai bawaan templat")
	var mentah: Dictionary = {"hari": 4, "flag": ["a"]}
	var salinan: Dictionary = mentah.duplicate(true)
	var m: Dictionary = DataSave.migrasi(mentah)
	check(mentah == salinan and m["versi"] == 4 and m["hari"] == 4, "migrasi tidak mengubah masukan dan menaikkan versi")
	check(DataSave.migrasi(m) == m, "migrasi save yang sudah v3 tidak mengubah apa pun (idempoten)")


func _test_save_id_tak_dikenal_dan_nilai_tak_sah() -> void:
	_judul.call("DataSave: id tak dikenal dibiarkan, nilai tidak sah dijepit tanpa crash (AC-10)")
	var d: Dictionary = DataSave.templat()
	d["flag"] = ["flag_hantu"]
	d["misi_jeda"] = {"misi_hantu": 99}
	d["headline_jeda"] = {"utama_hantu": 40}
	var s: Dictionary = DataSave.migrasi(d)
	check(s["flag"] == ["flag_hantu"] and s["misi_jeda"] == {"misi_hantu": 99} and s["headline_jeda"] == {"utama_hantu": 40}, "id misi, headline, dan flag yang tidak ada di data dibiarkan di save")
	var buruk: Dictionary = {
		"versi": 2, "hari": -5, "koin": -10, "tip_total": 1.0e30, "flag": [1, null, "a", "a", ""], "misi_jeda": {"x": "abc", "y": 5.0, "z": -3},
		"headline_jeda": {"p": null}, "terakhir": {"hari": "x", "koin": -4, "misi_diambil": 7},
		"pengaturan": {"kidal": "ya", "mode_bantu": 1, "suara": 5, "musik": "keras"},
	}
	var b: Dictionary = DataSave.migrasi(buruk)
	check(b["hari"] == 1 and b["koin"] == 0 and b["tip_total"] == Config.SAVE_ANGKA_MAKS, "hari negatif -> 1, koin negatif -> 0, bilangan raksasa dijepit ke batas")
	check(b["flag"] == ["a"], "flag: hanya teks tidak kosong, tanpa duplikat; dapat %s" % [b["flag"]])
	check(b["misi_jeda"] == {"y": 5, "z": 0}, "jeda: nilai bukan angka dibuang, negatif dijepit 0; dapat %s" % [b["misi_jeda"]])
	check(b["headline_jeda"] == {}, "jeda bernilai null dibuang")
	check(b["terakhir"] == {"hari": 0, "terkirim": 0, "meleset": 0, "koin": 0, "tip": 0, "skor": 0, "koin_misi": 0, "misi_diambil": "", "misi_hasil": ""}, "terakhir tidak sah dibawa ke bawaan; dapat %s" % [b["terakhir"]])
	check(b["pengaturan"] == {"kidal": false, "mode_bantu": false, "suara": 1.0, "musik": 1.0}, "pengaturan tidak sah: bool salah tipe -> false, volume 5 dijepit 1.0, teks -> 1.0; dapat %s" % [b["pengaturan"]])
	check(typeof(DataSave.migrasi({"hari": NAN, "koin": INF})["hari"]) == TYPE_INT, "NaN dan tak hingga tidak crash (jadi bilangan bulat sah)")


func _test_save_rusak_dan_terlalu_baru() -> void:
	_judul.call("DataSave: save rusak dan versi lebih baru dikenali (AC-9)")
	var rusak: Dictionary = {
		"kosong": "", "spasi": "   \n", "bukan JSON": "{hari: 1", "bukan objek": "[1, 2, 3]", "angka saja": "42", "hari teks": '{"hari": "tiga"}',
		"koin teks": '{"versi": 2, "koin": "banyak"}', "flag objek": '{"versi": 2, "flag": {}}', "pengaturan daftar": '{"pengaturan": []}',
		"misi_jeda daftar": '{"misi_jeda": [1]}', "versi teks": '{"versi": "satu"}', "terakhir angka": '{"terakhir": 5}',
	}
	for nama: String in rusak:
		var h: DataSave.Hasil = DataSave.dari_teks(rusak[nama])
		check(h.status == DataSave.Status.RUSAK and h.perlu_salinan() and h.state == DataSave.templat() and not h.alasan.is_empty(), "%s: RUSAK, perlu disalin, state bawaan, ada alasan" % nama)
	var baru: DataSave.Hasil = DataSave.dari_teks('{"versi": 5, "koin": 777}')
	check(baru.status == DataSave.Status.TERLALU_BARU and baru.perlu_salinan() and baru.state == DataSave.templat(), "versi 5 (lebih baru dari 4): TERLALU_BARU, perlu disalin, state bawaan")
	check(DataSave.dari_teks('{"versi": 4.0, "hari": 3}').status == DataSave.Status.SAH, "versi 4.0 (float dari JSON) sama dengan 4: SAH")
	check(DataSave.dari_teks('{"versi": 0, "hari": 3}').status == DataSave.Status.SAH, "versi 0 eksplisit: SAH (dimigrasi)")
	check(not DataSave.dari_teks(DataSave.ke_teks(DataSave.templat())).perlu_salinan(), "save sah tidak perlu disalin")


# --- catat_hari (AC-11, AC-12, AC-20) ---

func _test_catat_hari_dari_angka() -> void:
	_judul.call("DataSave.catat_hari: dicatat dari HasilRute.Angka yang sama (AC-12)")
	var state: Dictionary = DataSave.templat()
	state["hari"] = 4
	state["koin"] = 1000
	state["tip_total"] = 50
	state["flag"] = ["lama"]
	state["misi_jeda"] = {"p1_kucing": 11}
	var asli: Dictionary = state.duplicate(true)
	var angka: HasilRute.Angka = _angka(18, 7, 120, 25, 1500)
	var c: DataSave.CatatanHari = _catatan(4, angka, "p1_kucing")
	c.headline_jeda = {"utama_x": 9}
	c.misi_jeda = {"p1_kucing": 11, "misi_baru": 5}
	c.flag_baru = ["baru"]
	c.kidal = true
	c.mode_bantu = true
	var s: Dictionary = DataSave.catat_hari(state, c)
	check(state == asli, "catat_hari tidak mengubah state masukan")
	check(s["hari"] == 5, "hari = hari dimainkan + 1")
	check(s["koin"] == 1000 + 120, "koin = 1000 + angka.koin (koin sudah termasuk tip)")
	check(s["tip_total"] == 50 + 25, "tip_total = 50 + angka.koin_tip")
	check(s["terakhir"] == {"hari": 4, "terkirim": 18, "meleset": 7, "koin": 120, "tip": 25, "skor": 1500, "koin_misi": 0, "misi_hasil": "", "misi_diambil": "p1_kucing"}, "terakhir = angka layar hasil + hari + misi_diambil; dapat %s" % [s["terakhir"]])
	check(s["flag"] == ["lama", "baru"], "flag baru ditambahkan, flag lama tetap")
	check(s["misi_jeda"] == {"p1_kucing": 11, "misi_baru": 5} and s["headline_jeda"] == {"utama_x": 9}, "jeda digabung (nilai terbesar menang)")
	check(s["pengaturan"]["kidal"] == true and s["pengaturan"]["mode_bantu"] == true, "sakelar kidal dan bantu dari jeda ikut tersimpan (AC-13)")
	check(s["versi"] == 4 and DataSave.dari_teks(DataSave.ke_teks(s)).state == s, "hasil catat_hari tetap save v4 yang sah dan bulak-balik")
	var tanpa_angka: Dictionary = DataSave.catat_hari(DataSave.templat(), DataSave.CatatanHari.new())
	check(tanpa_angka["hari"] == 2 and tanpa_angka["koin"] == 0, "catatan tanpa angka tidak crash dan tidak menambah koin")


func _test_catat_hari_progres_tidak_turun() -> void:
	_judul.call("DataSave.catat_hari: progres tidak turun atas deretan hari acak berseed vs oracle (AC-11, QA-008)")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 424242
	var state: Dictionary = DataSave.templat()
	# Oracle: variabel berjalan yang dihitung tes sendiri.
	var o_hari: int = 1
	var o_koin: int = 0
	var o_tip: int = 0
	var o_flag: Array[String] = []
	var o_jeda_misi: Dictionary = {}
	var o_jeda_headline: Dictionary = {}
	var daftar_flag: Array[String] = ["a", "b", "c", "d"]
	var daftar_id: Array[String] = ["m1", "m2", "h1", "h2"]
	var turun: Array[String] = []
	var salah_oracle: Array[String] = []
	for langkah: int in range(300):
		var hari_main: int = rng.randi_range(1, 40)
		var koin: int = 0 if rng.randf() < 0.25 else rng.randi_range(0, 500)
		var tip: int = mini(koin, rng.randi_range(0, 60))
		var c: DataSave.CatatanHari = _catatan(hari_main, _angka(rng.randi_range(0, 25), rng.randi_range(0, 25), koin, tip, rng.randi_range(0, 4000)), "")
		if rng.randf() < 0.3:
			c.flag_baru = [daftar_flag[rng.randi_range(0, 3)]]
		var id: String = daftar_id[rng.randi_range(0, 3)]
		var jeda_nilai: int = rng.randi_range(0, 60)
		if id.begins_with("m"):
			c.misi_jeda = {id: jeda_nilai}
		else:
			c.headline_jeda = {id: jeda_nilai}
		var sebelum: Dictionary = state
		state = DataSave.catat_hari(state, c)
		o_hari = maxi(o_hari, hari_main + 1)
		o_koin += koin
		o_tip += tip
		for f: String in c.flag_baru:
			if not o_flag.has(f):
				o_flag.append(f)
		if id.begins_with("m"):
			o_jeda_misi[id] = maxi(int(o_jeda_misi.get(id, 0)), jeda_nilai)
		else:
			o_jeda_headline[id] = maxi(int(o_jeda_headline.get(id, 0)), jeda_nilai)
		if int(state["hari"]) < int(sebelum["hari"]) or int(state["koin"]) < int(sebelum["koin"]) or int(state["tip_total"]) < int(sebelum["tip_total"]):
			turun.append("langkah %d: hari/koin/tip turun" % langkah)
		var flag_sebelum: Array = sebelum["flag"]
		for f: Variant in flag_sebelum:
			if not (state["flag"] as Array).has(f):
				turun.append("langkah %d: flag %s hilang" % [langkah, f])
		for kunci: String in ["misi_jeda", "headline_jeda"]:
			var lama: Dictionary = sebelum[kunci]
			var baru: Dictionary = state[kunci]
			for k: Variant in lama:
				if int(baru.get(k, -1)) < int(lama[k]):
					turun.append("langkah %d: %s[%s] mundur" % [langkah, kunci, k])
		if state["hari"] != o_hari or state["koin"] != o_koin or state["tip_total"] != o_tip or state["flag"] != o_flag or state["misi_jeda"] != o_jeda_misi or state["headline_jeda"] != o_jeda_headline:
			salah_oracle.append("langkah %d" % langkah)
	check(turun.is_empty(), "300 hari acak: hari, koin, tip_total, flag, dan jeda tidak pernah turun: %s" % [turun.slice(0, 3)])
	check(salah_oracle.is_empty(), "300 hari acak: state sama dengan oracle (maks hari + 1, jumlah koin, jumlah tip, gabungan flag, jeda maks): %s" % [salah_oracle.slice(0, 3)])
	var nol: Dictionary = DataSave.templat()
	nol["koin"] = 800
	var setelah_nol: Dictionary = DataSave.catat_hari(nol, _catatan(1, _angka(0, 25, 0, 0, 0), ""))
	check(setelah_nol["koin"] == 800 and setelah_nol["hari"] == 2, "hari dengan koin 0 tidak mengurangi koin (prinsip 2) dan hari tetap maju")
	var negatif: Dictionary = DataSave.catat_hari(nol, _catatan(1, _angka(0, 0, -50, -9, 0), ""))
	check(negatif["koin"] == 800 and negatif["tip_total"] == 0, "angka koin negatif (tidak seharusnya ada) tidak pernah mengurangi koin atau tip")
	var mundur: Dictionary = DataSave.catat_hari(DataSave.migrasi({"hari": 10}), _catatan(2, _angka(1, 0, 15, 0, 100), ""))
	check(mundur["hari"] == 10, "mencatat hari lama (2) pada save hari 10 tidak memundurkan hari")


func _test_lewati_tanpa_penalti() -> void:
	_judul.call("Lewati tanpa penalti: Ambil dan Lewati menghasilkan save yang sama kecuali misi_diambil (AC-20, prinsip 2)")
	var state: Dictionary = DataSave.templat()
	state["koin"] = 300
	var angka: HasilRute.Angka = _angka(20, 5, 330, 30, 2100)
	var ambil: Dictionary = DataSave.catat_hari(state, _catatan(1, angka, "p1_kucing"))
	var lewati: Dictionary = DataSave.catat_hari(state, _catatan(1, angka, ""))
	var ambil_tanpa: Dictionary = ambil.duplicate(true)
	var lewati_tanpa: Dictionary = lewati.duplicate(true)
	(ambil_tanpa["terakhir"] as Dictionary).erase("misi_diambil")
	(lewati_tanpa["terakhir"] as Dictionary).erase("misi_diambil")
	check(ambil_tanpa == lewati_tanpa, "Ambil dan Lewati dengan Angka yang sama: seluruh save sama kecuali terakhir.misi_diambil")
	check(ambil["terakhir"]["misi_diambil"] == "p1_kucing" and lewati["terakhir"]["misi_diambil"] == "", "misi_diambil tercatat hanya bila diambil")
	check(lewati["koin"] == 300 + 330 and lewati["hari"] == 2, "Lewati tidak mengurangi koin dan hari tetap maju")
	var sah: Array[String] = ["versi", "hari", "koin", "koin_total", "tip_total", "sepeda", "reputasi", "pelanggan", "flag", "misi_jeda", "headline_jeda", "misi_hasil", "tutorial", "terakhir", "pengaturan"]
	var asing: Array[String] = []
	for kunci: Variant in lewati:
		if not sah.has(str(kunci)):
			asing.append(str(kunci))
	check(asing.is_empty(), "save tidak punya field keadaan kalah, game over, atau hukuman (hanya field v4): %s" % [asing])


# --- SaveManager (AC-7, AC-8, AC-9, AC-14) ---

func _test_save_manager_tulis_baca() -> void:
	_judul.call("SaveManager: tulis, baca, dan hitungan simpan (AC-7, AC-8, AC-14)")
	_bersihkan_folder_tes()
	var m: Node = _manajer()
	var jalur: String = FOLDER_TES.path_join("save.json")
	m.call(&"muat")
	check(m.get(&"status_muat") == DataSave.Status.BARU and m.get(&"state") == DataSave.templat() and m.call(&"ambil_notifikasi") == "", "tanpa berkas: state bawaan, status BARU, tanpa notifikasi")
	check(m.get(&"jumlah_simpan") == 0 and not FileAccess.file_exists(jalur), "muat tidak menulis apa pun")
	var c: DataSave.CatatanHari = _catatan(1, _angka(20, 5, 330, 30, 2100), "p1_kucing")
	c.kidal = true
	var berhasil: bool = m.call(&"akhiri_hari", c)
	check(berhasil and m.get(&"jumlah_simpan") == 1, "akhiri_hari menyimpan tepat satu kali dan berhasil")
	check(FileAccess.file_exists(jalur) and not FileAccess.file_exists(FOLDER_TES.path_join("save.tmp")), "berkas save ada dan berkas sementara tidak tertinggal")
	var terbaca: DataSave.Hasil = DataSave.dari_teks(FileAccess.get_file_as_string(jalur))
	check(terbaca.status == DataSave.Status.SAH and terbaca.state == m.get(&"state"), "isi berkas = state di memori (bulak-balik)")
	check(terbaca.state["hari"] == 2 and terbaca.state["koin"] == 330 and terbaca.state["tip_total"] == 30 and terbaca.state["pengaturan"]["kidal"] == true, "isi berkas: hari 2, koin 330, tip_total 30, kidal tersimpan")
	var m2: Node = _manajer()
	m2.call(&"muat")
	check(m2.get(&"state") == m.get(&"state") and m2.call(&"hari") == 2 and m2.call(&"pengaturan")["kidal"] == true, "SaveManager baru memuat state yang sama (hari 2, kidal nyala) dari berkas")
	var kali: Array[int] = [0]
	m2.connect(&"disimpan", func() -> void: kali[0] += 1)
	m2.call(&"simpan")
	check(kali[0] == 1 and m2.get(&"jumlah_simpan") == 1, "sinyal disimpan dipancarkan sekali per simpan yang berhasil")
	m.free()
	m2.free()
	_bersihkan_folder_tes()


func _test_save_manager_atomik() -> void:
	_judul.call("SaveManager: tulis atomik lewat berkas sementara, berkas lama utuh bila gagal (AC-8)")
	_bersihkan_folder_tes()
	var m: Node = _manajer()
	var jalur: String = FOLDER_TES.path_join("save.json")
	var lama: String = DataSave.ke_teks(DataSave.migrasi({"hari": 9, "koin": 123}))
	_tulis(jalur, lama)
	m.call(&"muat")
	var state: Dictionary = m.get(&"state")
	state["koin"] = 99999
	m.set(&"state", state)
	# Berkas sementara tidak bisa dibuat (di jalurnya ada folder): simpan harus gagal dan berkas lama harus utuh. Tulis langsung ke berkas
	# utama (tanpa berkas sementara) akan menimpa berkas lama dan lolos, jadi ini membuktikan tulis atomik.
	DirAccess.make_dir_recursive_absolute(FOLDER_TES.path_join("save.tmp"))
	var hasil: bool = m.call(&"simpan")
	check(not hasil, "simpan gagal bila berkas sementara tidak bisa dibuat")
	check(FileAccess.get_file_as_string(jalur) == lama, "berkas save lama utuh byte demi byte sesudah simpan yang gagal")
	DirAccess.remove_absolute(FOLDER_TES.path_join("save.tmp"))
	check(m.call(&"simpan") and DataSave.dari_teks(FileAccess.get_file_as_string(jalur)).state["koin"] == 99999, "sesudah penghalang hilang, simpan berhasil dan menimpa berkas lama")
	check(not FileAccess.file_exists(FOLDER_TES.path_join("save.tmp")), "berkas sementara dipindah, tidak tertinggal")
	var sumber: String = FileAccess.get_file_as_string(SKRIP_SIMPAN)
	check(sumber.contains("SAVE_SEMENTARA_EKSTENSI") and sumber.contains("rename_absolute"), "kode SaveManager menulis ke berkas sementara lalu rename (bukan tulis langsung)")
	m.free()
	_bersihkan_folder_tes()


func _test_save_manager_rusak() -> void:
	_judul.call("SaveManager: save rusak dan versi lebih baru disalin dulu, tidak ditimpa diam-diam (AC-9)")
	_bersihkan_folder_tes()
	var jalur: String = FOLDER_TES.path_join("save.json")
	var kasus: Dictionary = {"bukan JSON": "{ini bukan json", "versi lebih baru": '{"versi": 99, "koin": 777}', "bukan objek": "[1,2]"}
	for nama: String in kasus:
		_bersihkan_folder_tes()
		_tulis(jalur, kasus[nama])
		var m: Node = _manajer()
		m.call(&"muat", 1700000000)
		var salinan: String = FOLDER_TES.path_join("save.corrupt.1700000000.json")
		check(m.get(&"state") == DataSave.templat(), "%s: mulai dari state bawaan" % nama)
		check(m.get(&"jalur_salinan_rusak") == salinan and FileAccess.file_exists(salinan) and FileAccess.get_file_as_string(salinan) == kasus[nama], "%s: berkas lama disalin utuh ke save.corrupt.<detik>.json" % nama)
		check(FileAccess.get_file_as_string(jalur) == kasus[nama], "%s: muat sendiri tidak menimpa berkas lama" % nama)
		check(m.call(&"ambil_notifikasi") == "KORAN_SAVE_RUSAK" and m.call(&"ambil_notifikasi") == "", "%s: notifikasi KORAN_SAVE_RUSAK untuk layar koran tepat sekali" % nama)
		check(m.get(&"jumlah_simpan") == 0, "%s: muat tidak memanggil simpan" % nama)
		# QA-008: peluncuran berulang dengan berkas rusak yang sama (belum ditimpa) memakai salinan yang ada, tidak membuat salinan baru.
		m.call(&"muat", 1700000099)
		var salinan_baru: Array[String] = _salinan_di_folder()
		check(salinan_baru == [salinan.get_file()] and m.get(&"jalur_salinan_rusak") == salinan and m.call(&"ambil_notifikasi") == "KORAN_SAVE_RUSAK", "%s: muat ulang berkas rusak yang sama (detik berbeda) memakai salinan yang ada, tidak menumpuk: %s" % [nama, salinan_baru])
		for i: int in range(5):
			m.call(&"muat", 1700000100 + i)
		check(_salinan_di_folder().size() == 1, "%s: enam peluncuran berturut-turut = tepat satu salinan (QA-008)" % nama)
		# Isi berbeda di detik yang sama: salinan baru, salinan lama tidak ditimpa.
		_tulis(jalur, kasus[nama] + " ")
		m.call(&"muat", 1700000000)
		var salinan2: String = FOLDER_TES.path_join("save.corrupt.1700000000_2.json")
		check(FileAccess.file_exists(salinan) and FileAccess.file_exists(salinan2) and m.get(&"jalur_salinan_rusak") == salinan2 and FileAccess.get_file_as_string(salinan) == kasus[nama], "%s: isi berbeda di detik yang sama = salinan kedua, yang pertama tidak ditimpa" % nama)
		m.call(&"muat", 1700000500)
		check(_salinan_di_folder().size() == 2 and m.get(&"jalur_salinan_rusak") == salinan2, "%s: berkas kedua yang sama juga tidak digandakan" % nama)
		m.free()
	_bersihkan_folder_tes()
	var bersih: Node = _manajer()
	_tulis(FOLDER_TES.path_join("save.json"), DataSave.ke_teks(DataSave.templat()))
	bersih.call(&"muat", 1700000000)
	check(bersih.call(&"ambil_notifikasi") == "" and bersih.get(&"jalur_salinan_rusak") == "" and bersih.get(&"status_muat") == DataSave.Status.SAH, "save sah: tanpa notifikasi dan tanpa salinan")
	bersih.free()
	_bersihkan_folder_tes()


## Mengubah izin berkas atau folder lewat `chmod` (macOS dan Linux). True bila perintah berhasil.
func _izin(jalur: String, mode: String) -> bool:
	return OS.execute("chmod", [mode, ProjectSettings.globalize_path(jalur)]) == 0


func _nama_di_folder() -> Array[String]:
	var hasil: Array[String] = []
	var dir: DirAccess = DirAccess.open(FOLDER_TES)
	if dir != null:
		for nama: String in dir.get_files():
			hasil.append(nama)
	hasil.sort()
	return hasil


func _test_save_manager_tidak_terbaca() -> void:
	_judul.call("SaveManager: save yang tidak terbaca atau tidak bisa disalin TIDAK ditimpa, notifikasi jujur (AC-9, QA-003)")
	_bersihkan_folder_tes()
	var jalur: String = FOLDER_TES.path_join("save.json")
	var isi: String = DataSave.ke_teks(DataSave.migrasi({"hari": 40, "koin": 9999}))
	# Kasus 1: berkas save sah ADA tetapi tidak bisa dibuka (chmod 000) -> bukan "kosong". Jangan ditimpa, jangan dianggap rusak.
	_tulis(jalur, isi)
	var m: Node = _manajer()
	var terkunci: bool = _izin(jalur, "000") and FileAccess.open(jalur, FileAccess.READ) == null
	if terkunci:
		m.call(&"muat", 1700000000)
		check(m.get(&"status_muat") == DataSave.Status.TIDAK_TERBACA and m.get(&"state") == DataSave.templat(), "berkas ada tetapi tidak bisa dibuka: status TIDAK_TERBACA (bukan RUSAK), state bawaan di memori")
		check(m.get(&"jalur_salinan_rusak") == "" and m.call(&"simpan_ditahan"), "tidak terbaca: tidak ada salinan, simpan ditahan")
		check(m.call(&"ambil_notifikasi") == "KORAN_SAVE_TIDAK_TERBACA" and m.call(&"ambil_notifikasi") == "", "notifikasi jujur KORAN_SAVE_TIDAK_TERBACA (bukan 'salinannya disimpan'), tepat sekali")
		var hari1: DataSave.CatatanHari = _catatan(1, _angka(3, 22, 120, 25, 1500))
		check(not m.call(&"akhiri_hari", hari1) and not m.call(&"simpan") and m.get(&"jumlah_simpan") == 2, "akhiri_hari dan simpan ditolak (false) selama ditahan; panggilan tetap dihitung")
		check(m.call(&"hari") == 2, "kemajuan tetap di memori (hari 2) walau tidak tersimpan")
		_izin(jalur, "644")
		check(FileAccess.get_file_as_string(jalur) == isi, "berkas lama utuh byte demi byte: progres hari 40, koin 9999 tidak hilang (rule save-system)")
		check(_nama_di_folder() == ["save.json"], "tidak ada berkas sementara atau salinan yang dibuat: %s" % [_nama_di_folder()])
		m.call(&"muat", 1700000001)
		check(m.get(&"status_muat") == DataSave.Status.SAH and m.call(&"hari") == 40 and not m.call(&"simpan_ditahan") and m.call(&"ambil_notifikasi") == "", "izin pulih lalu muat lagi: save terbaca (hari 40), simpan tidak lagi ditahan")
	else:
		check(true, "chmod tidak menghalangi baca (mis. berjalan sebagai root): kasus tidak terbaca dilewati")
		_izin(jalur, "644")
	m.free()
	# Kasus 2: berkas terbaca tetapi rusak DAN salinannya gagal dibuat (folder tanpa izin tulis) -> jangan ditimpa, notifikasi jujur.
	_bersihkan_folder_tes()
	_tulis(jalur, "{bukan json")
	var m2: Node = _manajer()
	var folder_terkunci: bool = _izin(FOLDER_TES, "555")
	var bisa_tulis: bool = false
	if folder_terkunci:
		var coba: FileAccess = FileAccess.open(FOLDER_TES.path_join("coba.tmp"), FileAccess.WRITE)
		bisa_tulis = coba != null
		if coba != null:
			coba.close()
			DirAccess.remove_absolute(FOLDER_TES.path_join("coba.tmp"))
	if folder_terkunci and not bisa_tulis:
		m2.call(&"muat", 1700000000)
		check(m2.get(&"status_muat") == DataSave.Status.RUSAK and m2.get(&"jalur_salinan_rusak") == "" and m2.call(&"simpan_ditahan"), "rusak dan salinan gagal: tidak ada salinan, simpan ditahan")
		check(m2.call(&"ambil_notifikasi") == "KORAN_SAVE_TIDAK_TERBACA", "notifikasi KORAN_SAVE_TIDAK_TERBACA, bukan KORAN_SAVE_RUSAK yang mengaku salinan tersimpan")
		_izin(FOLDER_TES, "755")
		check(not m2.call(&"akhiri_hari", _catatan(1, _angka(1, 0, 10, 0, 100))), "folder sudah bisa ditulis lagi, tetapi simpan tetap ditahan sepanjang sesi (berkas rusak belum aman)")
		check(FileAccess.get_file_as_string(jalur) == "{bukan json" and _nama_di_folder() == ["save.json"], "berkas rusak tidak ditimpa dan tidak ada berkas lain: %s" % [_nama_di_folder()])
		m2.call(&"muat", 1700000000)
		check(m2.get(&"jalur_salinan_rusak") != "" and not m2.call(&"simpan_ditahan") and m2.call(&"ambil_notifikasi") == "KORAN_SAVE_RUSAK", "buka lagi dengan folder bisa ditulis: salinan dibuat, notifikasi KORAN_SAVE_RUSAK, simpan terbuka")
	else:
		check(true, "folder tanpa izin tulis tidak menghalangi (mis. berjalan sebagai root): kasus salinan gagal dilewati")
	_izin(FOLDER_TES, "755")
	m2.free()
	_bersihkan_folder_tes()


func _test_save_manager_baca_balik_dan_rename() -> void:
	_judul.call("SaveManager: baca-balik berkas sementara dan rename yang gagal membiarkan berkas lama utuh (AC-8, QA-006)")
	_bersihkan_folder_tes()
	var jalur: String = FOLDER_TES.path_join("save.json")
	var sementara: String = FOLDER_TES.path_join("save.tmp")
	var lama: String = DataSave.ke_teks(DataSave.migrasi({"hari": 9, "koin": 123}))
	_tulis(jalur, lama)
	var m: Node = _manajer()
	m.call(&"muat")
	var diminta: Array[String] = []
	# Pembaca yang menyuntik isi berbeda (meniru tulisan terpotong): simpan harus gagal, berkas lama utuh, berkas sementara dibuang.
	m.set(&"baca_balik", func(p: String) -> String:
		diminta.append(p)
		return "terpotong")
	check(not m.call(&"simpan"), "baca-balik berbeda dari yang ditulis: simpan gagal (false)")
	check(diminta == [sementara], "pemeriksaan baca-balik membaca berkas sementara %s, dapat %s" % [sementara, diminta])
	check(FileAccess.get_file_as_string(jalur) == lama and not FileAccess.file_exists(sementara), "berkas save lama utuh byte demi byte dan berkas sementara dibuang")
	# Pembaca yang mengembalikan isi benar: simpan berhasil lewat jalur yang sama.
	m.set(&"baca_balik", func(p: String) -> String: return FileAccess.get_file_as_string(p))
	check(m.call(&"simpan") and DataSave.dari_teks(FileAccess.get_file_as_string(jalur)).state == m.get(&"state"), "pembaca suntikan yang benar: simpan berhasil dan isi = state")
	m.set(&"baca_balik", Callable())
	# Rename gagal (jalur save ditempati folder berisi): simpan false, berkas sementara tidak tertinggal.
	_bersihkan_folder_tes()
	DirAccess.make_dir_recursive_absolute(jalur)
	_tulis(jalur.path_join("isi.txt"), "x")
	m.call(&"muat")
	check(not m.call(&"simpan"), "rename gagal (jalur save ditempati folder): simpan false")
	check(FileAccess.file_exists(jalur.path_join("isi.txt")) and not FileAccess.file_exists(sementara), "berkas sementara dibuang dan isi folder penghalang utuh")
	DirAccess.remove_absolute(jalur.path_join("isi.txt"))
	DirAccess.remove_absolute(jalur)
	m.free()
	_bersihkan_folder_tes()


func _test_save_manager_autoload() -> void:
	_judul.call("SaveManager: autoload terdaftar dan tidak merujuk autoload lain (AC-7)")
	var daftar: Dictionary = {}
	for properti: Dictionary in ProjectSettings.get_property_list():
		var nama: String = properti["name"]
		if nama.begins_with("autoload/"):
			daftar[nama.trim_prefix("autoload/")] = str(ProjectSettings.get_setting(nama))
	check(daftar.get("SaveManager", "") == "*res://scripts/autoload/save_manager.gd", "autoload SaveManager = *res://scripts/autoload/save_manager.gd, dapat '%s'" % daftar.get("SaveManager", ""))
	var sumber: String = FileAccess.get_file_as_string(SKRIP_SIMPAN)
	var rujukan: Array[String] = []
	for lain: String in daftar:
		if lain != "SaveManager" and (sumber.contains(lain + ".") or sumber.contains("/root/" + lain)):
			rujukan.append(lain)
	check(rujukan.is_empty() and not sumber.contains("get_node") and not sumber.contains("/root/"), "save_manager.gd tidak merujuk autoload lain: %s" % [rujukan])
	check(not sumber.contains("class_name"), "save_manager.gd tanpa class_name (tidak bentrok dengan nama autoload)")
	var m: Node = load(SKRIP_SIMPAN).new()
	check(m.get(&"jalur") == "user://save.json" and m.get(&"jumlah_simpan") == 0, "SaveManager tanpa scene tree: jalur bawaan user://save.json, belum menyimpan apa pun")
	m.free()
