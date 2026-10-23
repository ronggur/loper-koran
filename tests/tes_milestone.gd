class_name TesMilestone
extends RefCounted
## Tes `MilestoneTracker` run fase6a2-reputasi-pelanggan bagian C (AC-12, O-9), logika murni: Config (target menaik, id permanen), progres dari state (hitung sendiri dari bentuk save, bukan memanggil
## fungsi yang dites), tingkat dan batas (tepat di target, di bawah, di atas, kosong, nilai asing), progres dari save nyata (v4 dari fixture lama dan hari yang diterapkan `catat_hari`), pemilihan
## "paling dekat tercapai" (pecahan, seri, urutan, semua emas), "baru tercapai" antara dua state, dan tanpa efek samping (masukan tidak berubah, tidak ada field save baru).

var _cek: Callable
var _judul: Callable


func _init(cek: Callable, judul: Callable) -> void:
	_cek = cek
	_judul = judul


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_test_config()
	_test_batas_tingkat()
	_test_progres_dari_state()
	_test_nilai_asing()
	_test_save_nyata()
	_test_paling_dekat()
	_test_baru_tercapai()
	_test_tanpa_efek_samping()
	_test_tanpa_field_save_baru()


# --- Pembantu ---

## State dengan pelanggan `setia` sebanyak `setia` (id "s@i"), satu `aktif`, `koin_total`, `selesai` misi selesai (dan satu gagal), `servis` servis dan level upgrade `level` (ban, rem, rantai).
func _state(setia: int, koin_total: int, selesai: int, servis: int, level: Array = [0, 0, 0]) -> Dictionary:
	var s: Dictionary = DataSave.templat()
	var pelanggan: Dictionary = {}
	for i: int in range(setia):
		pelanggan["s@%d" % i] = {"status": "setia", "antar": 5, "meleset": 0, "hari_berhenti": 0}
	pelanggan["a@0"] = {"status": "aktif", "antar": 2, "meleset": 0, "hari_berhenti": 0}
	pelanggan["b@0"] = {"status": "berhenti", "antar": 0, "meleset": 2, "hari_berhenti": 4}
	s["pelanggan"] = pelanggan
	s["koin_total"] = koin_total
	var riwayat: Dictionary = {}
	for i: int in range(selesai):
		riwayat["m%d" % i] = {"hasil": "selesai", "hari": i + 1}
	riwayat["gagal_saja"] = {"hasil": "gagal", "hari": 9}
	s["misi_hasil"] = riwayat
	var sepeda: Dictionary = s["sepeda"]
	sepeda["servis_total"] = servis
	for i: int in range(3):
		sepeda[Config.KONDISI_KOMPONEN[i]]["level"] = level[i]
	return s


func _status(s: Dictionary, id: String) -> MilestoneTracker.Status:
	return MilestoneTracker.status(s, id)


# --- Tes ---

func _test_config() -> void:
	_judul.call("Milestone: Config sesuai O-9 (empat milestone x tiga tingkat, target menaik, id permanen)")
	check(Config.MILESTONE_ID == ["pelanggan_tetap", "koin_total", "misi_selesai", "sepeda"], "id milestone permanen dan berurutan")
	check(Config.MILESTONE_TINGKAT == ["perunggu", "perak", "emas"], "tiga tingkat: perunggu, perak, emas")
	check(Config.MILESTONE_TARGET_PELANGGAN_TETAP == [3, 10, 25], "target pelanggan tetap 3/10/25")
	check(Config.MILESTONE_TARGET_KOIN_TOTAL == [1000, 5000, 15000], "target koin total 1000/5000/15000")
	check(Config.MILESTONE_TARGET_MISI_SELESAI == [1, 3, 5], "target misi selesai 1/3/5")
	check(Config.MILESTONE_TARGET_SEPEDA == [1, 4, 10], "target sepeda 1/4/10")
	for id: String in Config.MILESTONE_ID:
		var t: Array[int] = MilestoneTracker.daftar_target(id)
		check(t.size() == 3 and t[0] > 0 and t[0] < t[1] and t[1] < t[2], "%s: tiga target positif dan menaik" % id)
	check(MilestoneTracker.daftar_target("asing").is_empty(), "id asing: daftar target kosong")
	check(Config.MILESTONE_BARU_MAKS_TAMPIL >= 1, "paling sedikit satu tingkat baru boleh tampil")


func _test_batas_tingkat() -> void:
	_judul.call("Milestone: tingkat di batas target (tepat, satu di bawah, satu di atas, nol, sangat besar)")
	var kasus: Array = [
		["pelanggan_tetap", 0, 0], ["pelanggan_tetap", 2, 0], ["pelanggan_tetap", 3, 1], ["pelanggan_tetap", 4, 1], ["pelanggan_tetap", 9, 1], ["pelanggan_tetap", 10, 2],
		["pelanggan_tetap", 24, 2], ["pelanggan_tetap", 25, 3], ["pelanggan_tetap", 26, 3],
		["koin_total", 999, 0], ["koin_total", 1000, 1], ["koin_total", 4999, 1], ["koin_total", 5000, 2], ["koin_total", 14999, 2], ["koin_total", 15000, 3], ["koin_total", 2000000000, 3],
		["misi_selesai", 0, 0], ["misi_selesai", 1, 1], ["misi_selesai", 2, 1], ["misi_selesai", 3, 2], ["misi_selesai", 4, 2], ["misi_selesai", 5, 3], ["misi_selesai", 6, 3],
		["sepeda", 0, 0], ["sepeda", 1, 1], ["sepeda", 3, 1], ["sepeda", 4, 2], ["sepeda", 9, 2], ["sepeda", 10, 3], ["sepeda", 11, 3],
		["asing", 100, 0],
	]
	for k: Array in kasus:
		check(MilestoneTracker.tingkat(k[0], k[1]) == k[2], "tingkat %s pada nilai %d = %d" % [k[0], k[1], k[2]])
	# Status: target berikutnya, pecahan, sisa, tamat.
	var s: MilestoneTracker.Status = _status(_state(0, 4999, 0, 0), "koin_total")
	check(s.tingkat == 1 and s.target == 5000 and s.sisa() == 1 and not s.tamat() and absf(s.pecahan() - 0.9998) < 0.00001, "koin 4999: perunggu, menuju 5000, sisa 1, pecahan 0,9998")
	s = _status(_state(0, 15000, 0, 0), "koin_total")
	check(s.tingkat == 3 and s.target == -1 and s.sisa() == 0 and s.tamat() and s.pecahan() == 1.0, "koin 15000: emas, tamat, tanpa target berikutnya")
	s = _status(_state(0, 0, 0, 0), "misi_selesai")
	check(s.tingkat == 0 and s.target == 1 and s.sisa() == 1 and s.pecahan() == 0.0, "state awal: misi 0 menuju 1")


func _test_progres_dari_state() -> void:
	_judul.call("Milestone: progres diturunkan dari state (setia, koin_total, misi selesai, servis + level)")
	var s: Dictionary = _state(4, 1234, 2, 3, [1, 0, 2])
	check(MilestoneTracker.nilai(s, "pelanggan_tetap") == 4, "hanya status 'setia' dihitung (aktif dan berhenti tidak): 4")
	check(MilestoneTracker.nilai(s, "koin_total") == 1234, "koin_total dibaca apa adanya: 1234")
	check(MilestoneTracker.nilai(s, "misi_selesai") == 2, "hanya hasil 'selesai' dihitung (gagal tidak): 2")
	check(MilestoneTracker.nilai(s, "sepeda") == 3 + 1 + 0 + 2, "sepeda = servis_total 3 + level 1+0+2 = 6")
	check(MilestoneTracker.nilai(s, "asing") == 0, "id asing = 0")
	var semua: Array[MilestoneTracker.Status] = MilestoneTracker.semua(s)
	var urut: Array[String] = []
	for st: MilestoneTracker.Status in semua:
		urut.append(st.id)
	check(urut == Config.MILESTONE_ID, "semua(): urut Config.MILESTONE_ID")
	check(semua[0].tingkat == 1 and semua[1].tingkat == 1 and semua[2].tingkat == 1 and semua[3].tingkat == 2, "tingkat 1/1/1/2 untuk 4 setia, 1234 koin, 2 misi, sepeda 6")


func _test_nilai_asing() -> void:
	_judul.call("Milestone: state kosong dan nilai asing dihitung 0 tanpa galat")
	for id: String in Config.MILESTONE_ID:
		check(MilestoneTracker.nilai({}, id) == 0 and MilestoneTracker.status({}, id).tingkat == 0, "%s: state kosong = 0, tingkat 0" % id)
	var buruk: Dictionary = {
		"pelanggan": "bukan kamus", "koin_total": "seribu", "misi_hasil": [1, 2], "sepeda": 5,
	}
	for id: String in Config.MILESTONE_ID:
		check(MilestoneTracker.nilai(buruk, id) == 0, "%s: tipe salah = 0" % id)
	var campur: Dictionary = {
		"pelanggan": {"a": "setia", "b": {"status": 5}, "c": {"status": "setia"}, "d": null},
		"koin_total": -50,
		"misi_hasil": {"x": "selesai", "y": {"hasil": "selesai"}, "z": {"hasil": ["selesai"]}},
		"sepeda": {"servis_total": -3, "ban": {"level": "dua"}, "rem": {"level": -1}, "rantai": 7},
	}
	check(MilestoneTracker.nilai(campur, "pelanggan_tetap") == 1, "pelanggan: hanya entri kamus ber-status 'setia' dihitung (1 dari 4 entri)")
	check(MilestoneTracker.nilai(campur, "koin_total") == 0, "koin_total negatif = 0")
	check(MilestoneTracker.nilai(campur, "misi_selesai") == 1, "misi_hasil: hanya entri kamus ber-hasil 'selesai' dihitung")
	check(MilestoneTracker.nilai(campur, "sepeda") == 0, "sepeda: servis negatif, level bukan angka, level negatif, komponen bukan kamus = 0")
	var besar: Dictionary = {"koin_total": 9999999999999.0}
	check(MilestoneTracker.nilai(besar, "koin_total") == Config.SAVE_ANGKA_MAKS, "koin_total sangat besar dijepit ke SAVE_ANGKA_MAKS")
	check(MilestoneTracker.nilai({"koin_total": NAN}, "koin_total") == 0, "NaN = 0")
	check(MilestoneTracker.paling_dekat({}) != null and MilestoneTracker.baru_tercapai({}, {}).is_empty(), "state kosong: ada target terdekat, tidak ada yang baru")


func _test_save_nyata() -> void:
	_judul.call("Milestone: progres dari save nyata (fixture 6A1 v3, 4B v2, 4A v1 yang dimigrasi ke v4) dan sesudah satu hari dari DataSave.catat_hari")
	var s6: Dictionary = DataSave.dari_teks(TesSaveV4.SAVE_6A1).state
	# Save 6A1 asli: koin_total 195, servis_total 1, flag kucing_ketemu, misi P1 selesai (cek oracle langsung dari teks).
	var mentah: Dictionary = JSON.parse_string(TesSaveV4.SAVE_6A1)
	var selesai_mentah: int = 0
	for id: String in mentah.get("misi_hasil", {}):
		if str(mentah["misi_hasil"][id].get("hasil", "")) == "selesai":
			selesai_mentah += 1
	var level_mentah: int = 0
	for k: String in Config.KONDISI_KOMPONEN:
		level_mentah += int(mentah["sepeda"][k]["level"])
	check(MilestoneTracker.nilai(s6, "koin_total") == int(mentah["koin_total"]) and int(mentah["koin_total"]) == 195, "6A1: koin_total 195 = nilai mentah")
	check(MilestoneTracker.nilai(s6, "misi_selesai") == selesai_mentah, "6A1: misi selesai sama dengan hitungan mentah (%d)" % selesai_mentah)
	check(MilestoneTracker.nilai(s6, "sepeda") == int(mentah["sepeda"]["servis_total"]) + level_mentah, "6A1: sepeda = servis_total + level mentah")
	check(MilestoneTracker.nilai(s6, "pelanggan_tetap") == 0, "6A1: belum ada pelanggan setia (field v4 awal)")
	var s4b: Dictionary = DataSave.dari_teks(TesSaveV3.SAVE_4B).state
	check(MilestoneTracker.nilai(s4b, "koin_total") == 195 and MilestoneTracker.nilai(s4b, "pelanggan_tetap") == 0 and MilestoneTracker.nilai(s4b, "sepeda") == 0, "4B (v2): koin_total 195, tanpa pelanggan, sepeda 0")
	var s4a: Dictionary = DataSave.dari_teks(TesMisiSave.SAVE_4A).state
	check(MilestoneTracker.nilai(s4a, "koin_total") == 120, "4A (v1): koin_total 120")
	var v0: Dictionary = DataSave.dari_teks('{"hari": 7, "koin": 1500}').state
	check(MilestoneTracker.nilai(v0, "koin_total") == 1500 and MilestoneTracker.status(v0, "koin_total").tingkat == 1, "v0 dengan koin 1500: koin_total 1500 (migrasi) = perunggu")
	# Satu hari nyata: catat_hari menambah koin_total sebesar koin kotor, misi selesai masuk riwayat.
	var angka: HasilRute.Angka = HasilRute.Angka.new()
	angka.pelanggan = 25
	angka.terkirim = 20
	angka.koin = 400
	angka.potongan = 10
	angka.misi_id = "p9_misi_baru"
	angka.misi_hasil = "selesai"
	var catatan: DataSave.CatatanHari = DataSave.CatatanHari.new()
	catatan.hari = 3
	catatan.angka = angka
	var sesudah: Dictionary = DataSave.catat_hari(s4b, catatan)
	check(MilestoneTracker.nilai(sesudah, "koin_total") == 195 + 400, "sesudah hari: koin_total = 195 + koin kotor 400 (potongan tidak mengurangi koin_total)")
	check(MilestoneTracker.nilai(sesudah, "misi_selesai") == MilestoneTracker.nilai(s4b, "misi_selesai") + 1, "sesudah hari: satu misi selesai baru (id belum ada) menambah tepat 1")
	var baru: Array[MilestoneTracker.Capaian] = MilestoneTracker.baru_tercapai(s4b, sesudah)
	var ids: Array[String] = []
	for c: MilestoneTracker.Capaian in baru:
		ids.append(c.id)
	var tingkat_misi_lama: int = MilestoneTracker.tingkat("misi_selesai", MilestoneTracker.nilai(s4b, "misi_selesai"))
	var tingkat_misi_baru: int = MilestoneTracker.tingkat("misi_selesai", MilestoneTracker.nilai(sesudah, "misi_selesai"))
	check(ids.has("misi_selesai") == (tingkat_misi_baru > tingkat_misi_lama), "misi_selesai ada di daftar baru tepat bila tingkatnya naik (lama %d, baru %d)" % [tingkat_misi_lama, tingkat_misi_baru])
	check(ids.has("koin_total") == (MilestoneTracker.tingkat("koin_total", 595) > MilestoneTracker.tingkat("koin_total", 195)) and MilestoneTracker.tingkat("koin_total", 595) == 0, "koin_total 195 -> 595 belum melewati 1000: tidak baru")


func _test_paling_dekat() -> void:
	_judul.call("Milestone: paling dekat tercapai (pecahan terbesar, seri oleh sisa terkecil lalu urutan id, semua emas = null)")
	# Pecahan: pelanggan 2/3 = 0,667; koin 900/1000 = 0,9; misi 0/1 = 0; sepeda 3/4 setelah perunggu = 0,75 -> koin menang.
	var a: Dictionary = _state(2, 900, 0, 1, [2, 0, 0])
	var d: MilestoneTracker.Status = MilestoneTracker.paling_dekat(a)
	check(d != null and d.id == "koin_total", "pecahan terbesar menang: koin 900/1000 (0,9) mengalahkan pelanggan 2/3, sepeda 3/4")
	# Perunggu sudah dapat tidak mengecualikan: milestone yang sudah perunggu menghitung menuju perak.
	var b: Dictionary = _state(0, 1000, 1, 0)
	d = MilestoneTracker.paling_dekat(b)
	check(d != null and d.id == "misi_selesai" and d.target == 3 and d.nilai == 1, "misi 1/3 (0,33) menang atas koin 1000/5000 (0,2): tingkat berikutnya, bukan yang sudah dicapai")
	# Seri pecahan (sama persis): sisa terkecil menang. misi 1/3 = 0,333 dan sepeda... cari pasangan: pelanggan 1/3 dan misi 0... gunakan sepeda 2/4 (0,5) vs koin 2500/5000 (0,5): sisa sepeda 2 < sisa koin 2500.
	var c: Dictionary = _state(0, 2500, 0, 0, [1, 1, 0])
	# sepeda = 0 servis + 2 level = 2 -> tingkat 1 (>=1), menuju 4: 2/4 = 0,5. Koin 2500 -> perunggu, menuju 5000: 0,5.
	d = MilestoneTracker.paling_dekat(c)
	check(d != null and d.id == "sepeda", "seri pecahan 0,5: sepeda (sisa 2) mengalahkan koin_total (sisa 2500)")
	# Seri pecahan dan sisa sama: urutan Config.MILESTONE_ID. Nol semua: misi (sisa 1) dan sepeda (sisa 1) seri pecahan 0 dan sisa 1 -> misi_selesai lebih awal dari sepeda.
	d = MilestoneTracker.paling_dekat(_state(0, 0, 0, 0))
	check(d != null and d.id == "misi_selesai", "semua 0: pecahan seri, sisa 1 seri (misi dan sepeda), urutan id memilih misi_selesai")
	# Deterministik dan tidak bergantung pada urutan kamus: 20 panggilan sama.
	var sama: bool = true
	for i: int in range(20):
		var di: MilestoneTracker.Status = MilestoneTracker.paling_dekat(c)
		if di == null or di.id != "sepeda":
			sama = false
	check(sama, "20 panggilan memberi hasil sama")
	# Yang emas dilewati.
	var e: Dictionary = _state(25, 20000, 5, 10, [0, 0, 0])
	d = MilestoneTracker.paling_dekat(e)
	check(MilestoneTracker.tingkat("pelanggan_tetap", 25) == 3 and d == null, "semua emas: paling_dekat null")
	var f: Dictionary = _state(25, 20000, 5, 3, [0, 0, 0])
	d = MilestoneTracker.paling_dekat(f)
	check(d != null and d.id == "sepeda" and d.nilai == 3 and d.target == 4, "hanya sepeda belum emas: 3/4 satu-satunya kandidat")
	# Pecahan dibandingkan tepat (bilangan bulat): 4999/5000 menang atas 14999/15000? 0,9998 vs 0,99993 -> koin emas belum; pakai: koin 4999 (0,9998) vs pelanggan 24/25 (0,96).
	d = MilestoneTracker.paling_dekat(_state(9, 4999, 0, 0))
	check(d != null and d.id == "koin_total", "4999/5000 (0,9998) mengalahkan pelanggan 9/10 (0,9)")
	# Tingkat tepat di target tidak lagi menjadi kandidat tingkat itu: koin 5000 menuju 15000 (0,333).
	d = MilestoneTracker.paling_dekat(_state(25, 5000, 5, 10))
	check(d != null and d.id == "koin_total" and d.target == 15000 and d.nilai == 5000, "koin tepat 5000: kandidat menuju 15000, bukan 5000")


func _test_baru_tercapai() -> void:
	_judul.call("Milestone: baru tercapai antara dua state (satu entri per milestone, tingkat tertinggi, urut tingkat lalu id, tidak turun)")
	var sebelum: Dictionary = _state(2, 900, 0, 0)
	var sesudah: Dictionary = _state(3, 1100, 0, 0)
	var baru: Array[MilestoneTracker.Capaian] = MilestoneTracker.baru_tercapai(sebelum, sesudah)
	check(baru.size() == 2 and baru[0].id == "pelanggan_tetap" and baru[0].tingkat == 1 and baru[0].tingkat_sebelum == 0 and baru[1].id == "koin_total" and baru[1].tingkat == 1, "setia 3 dan koin 1100 melewati perunggu: dua entri urut id")
	check(MilestoneTracker.baru_tercapai(sesudah, sesudah).is_empty(), "state sama: tidak ada yang baru")
	check(MilestoneTracker.baru_tercapai(sesudah, sebelum).is_empty(), "state mundur: tidak ada yang baru (tingkat tidak turun)")
	# Loncat dua tingkat sekaligus: satu entri dengan tingkat tertinggi.
	baru = MilestoneTracker.baru_tercapai(_state(0, 100, 0, 0), _state(0, 6000, 0, 0))
	check(baru.size() == 1 and baru[0].id == "koin_total" and baru[0].tingkat == 2 and baru[0].tingkat_sebelum == 0, "koin 100 -> 6000: satu entri, tingkat 2 (perak) dari 0")
	# Urut: tingkat tertinggi dulu.
	baru = MilestoneTracker.baru_tercapai(_state(0, 0, 0, 0), _state(3, 6000, 1, 0))
	var urut: Array[String] = []
	for c: MilestoneTracker.Capaian in baru:
		urut.append("%s:%d" % [c.id, c.tingkat])
	check(urut == ["koin_total:2", "pelanggan_tetap:1", "misi_selesai:1"], "urut tingkat tertinggi dulu lalu id: %s" % [urut])
	# Tepat di target hari ini tercapai; satu di bawah tidak.
	check(MilestoneTracker.baru_tercapai(_state(0, 999, 0, 0), _state(0, 999, 0, 0)).is_empty() and MilestoneTracker.baru_tercapai(_state(0, 999, 0, 0), _state(0, 1000, 0, 0)).size() == 1, "999 -> 999 tidak, 999 -> 1000 ya")
	var r: MilestoneTracker.Ringkasan = MilestoneTracker.ringkas(sebelum, sesudah)
	check(r.daftar.size() == 4 and r.baru.size() == 2 and r.terdekat != null and r.terdekat.nilai == MilestoneTracker.nilai(sesudah, r.terdekat.id), "ringkas: 4 status, 2 baru, terdekat dihitung dari state SESUDAH")
	check(MilestoneTracker.nama_tingkat(1) == "perunggu" and MilestoneTracker.nama_tingkat(2) == "perak" and MilestoneTracker.nama_tingkat(3) == "emas" and MilestoneTracker.nama_tingkat(0) == "" and MilestoneTracker.nama_tingkat(4) == "", "nama_tingkat 1..3, di luar rentang kosong")


func _test_tanpa_efek_samping() -> void:
	_judul.call("Milestone: masukan tidak berubah; deterministik (AC-12)")
	var s: Dictionary = _state(5, 3000, 2, 2, [1, 1, 0])
	var t: Dictionary = _state(6, 3200, 2, 3, [1, 1, 0])
	var s0: Dictionary = s.duplicate(true)
	var t0: Dictionary = t.duplicate(true)
	var r1: MilestoneTracker.Ringkasan = MilestoneTracker.ringkas(s, t)
	var r2: MilestoneTracker.Ringkasan = MilestoneTracker.ringkas(s, t)
	check(s == s0 and t == t0, "ringkas tidak mengubah state masukan")
	var sidik1: Array = []
	var sidik2: Array = []
	for st: MilestoneTracker.Status in r1.daftar:
		sidik1.append([st.id, st.nilai, st.tingkat, st.target])
	for st: MilestoneTracker.Status in r2.daftar:
		sidik2.append([st.id, st.nilai, st.tingkat, st.target])
	check(sidik1 == sidik2 and r1.terdekat.id == r2.terdekat.id, "dua panggilan memberi ringkasan sama")


func _test_tanpa_field_save_baru() -> void:
	_judul.call("Milestone: tanpa field save baru (O-9)")
	var t: Dictionary = DataSave.templat()
	var punya_milestone: bool = false
	for k: String in t:
		if k.contains("milestone") or k.contains("lencana"):
			punya_milestone = true
	check(not punya_milestone and Config.SAVE_VERSI == 4, "templat save v4 tidak punya field milestone/lencana; SAVE_VERSI tetap 4")
	var sesudah: Dictionary = DataSave.catat_hari(t, DataSave.CatatanHari.new())
	check(sesudah.keys().size() == t.keys().size(), "catat_hari tidak menambah field")
