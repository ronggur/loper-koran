class_name TesRutePelanggan
extends RefCounted
## Tes run fase6a2-reputasi-pelanggan bagian A, AC-4 dan AC-2 (jalan kembali): `RouteBuilder.bangun` dengan keadaan pelanggan (`PelangganRute`, O-7).
##
## Oracle independen dari `RouteBuilder`: golden rute tanpa keadaan dibaca dari `tests/data/golden_rute_main.json` (dihitung `tests/ukur_golden_rute.gd` pada commit yang `route_builder.gd`-nya sama dengan `main`,
## bukan angka tulisan tangan); aturan (a) sampai (e) diperiksa dari rute jadi memakai hitungan sendiri (batas setia = lantai 60% kuota yang dihitung di sini, status dibaca dari keadaan masukan).

const BERKAS_GOLDEN: String = "res://tests/data/golden_rute_main.json"
const SKRIP_UKUR: String = "res://tests/ukur_golden_rute.gd"
const FOLDER_RUTE: String = "res://assets/data/routes/perumahan"
const KOMBINASI: int = 1200

var _cek: Callable
var _judul: Callable
var _pustaka: Array[SegmenRute] = []
var _kepribadian: Array[KepribadianPelanggan.Entri] = []
var _id_boleh: Array[String] = []
var _id_dekat: Dictionary = {}


func _init(cek: Callable, judul: Callable) -> void:
	_cek = cek
	_judul = judul


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_pustaka = PemuatRute.muat_folder(FOLDER_RUTE).segmen
	_kepribadian = PemuatPelanggan.muat().entri
	for s: SegmenRute in _pustaka:
		for r: SegmenRute.Rumah in s.rumah:
			if r.pelanggan_boleh:
				var id: String = "%s@%d" % [s.id, r.pos]
				_id_boleh.append(id)
				_id_dekat[id] = r.sisi == LoperAnim.Sisi.DEKAT
	_id_boleh.sort()
	_test_golden()
	_test_keadaan_kosong_sama_tanpa_keadaan()
	_test_kombinasi_acak()
	_test_batas_baru()
	_test_ekstrem()
	_test_jalan_kembali()
	_test_pemberi_tip()


# --- Pembantu ---

func _golden() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(BERKAS_GOLDEN)) as Dictionary


func _sidik(rute: RouteBuilder.Rute) -> int:
	var skrip: GDScript = load(SKRIP_UKUR)
	return int(skrip.call("fnv", skrip.call("identitas", rute)))


func _identitas(rute: RouteBuilder.Rute) -> String:
	return str(load(SKRIP_UKUR).call("identitas", rute))


func _bangun(benih: int, hari: int, p: PelangganRute) -> RouteBuilder.Hasil:
	return RouteBuilder.bangun(benih, _pustaka, hari, p)


func _ids_pelanggan(rute: RouteBuilder.Rute) -> Array[String]:
	var hasil: Array[String] = []
	for r: RouteBuilder.RumahRute in rute.pelanggan:
		hasil.append(r.id)
	return hasil


## Keadaan acak yang masuk akal: tiap rumah boleh pelanggan mendapat status menurut bobot [baru, aktif, setia, berhenti]; berhenti hanya untuk rumah berkepribadian `sensitif` (yang lain jadi aktif), dengan hari berhenti 1..8 hari sebelum `hari`.
func _keadaan(rng: RandomNumberGenerator, bobot: Array[int], hari: int) -> PelangganRute:
	var peta: Dictionary = {}
	var jumlah: int = 0
	for b: int in bobot:
		jumlah += b
	for id: String in _id_boleh:
		var u: int = rng.randi_range(0, jumlah - 1)
		var k: int = 0
		while u >= bobot[k]:
			u -= bobot[k]
			k += 1
		if k == 3 and KepribadianPelanggan.dari_id(id, _kepribadian) != KepribadianPelanggan.SENSITIF:
			k = 1
		match k:
			1:
				peta[id] = {"status": "aktif", "antar": rng.randi_range(0, 4), "meleset": rng.randi_range(0, 1), "hari_berhenti": 0}
			2:
				peta[id] = {"status": "setia", "antar": rng.randi_range(5, 12), "meleset": 0, "hari_berhenti": 0}
			3:
				peta[id] = {"status": "berhenti", "antar": 0, "meleset": 2, "hari_berhenti": maxi(1, hari - rng.randi_range(1, 8))}
	return PelangganRute.dari_state({"pelanggan": peta}, _kepribadian)


func _keadaan_seragam(status: String, hari_berhenti: int) -> PelangganRute:
	var peta: Dictionary = {}
	for id: String in _id_boleh:
		peta[id] = {"status": status, "antar": 6, "meleset": 0, "hari_berhenti": hari_berhenti if status == "berhenti" else 0}
	return PelangganRute.dari_state({"pelanggan": peta}, _kepribadian)


func _jumlah_sisi(rute: RouteBuilder.Rute, sisi: LoperAnim.Sisi) -> int:
	var n: int = 0
	for r: RouteBuilder.RumahRute in rute.pelanggan:
		if r.sisi == sisi:
			n += 1
	return n


# --- AC-4: golden dan identitas ---

func _test_golden() -> void:
	_judul.call("Golden rute dari main: tanpa keadaan (hari 1..5) dan dengan keadaan di hari 1-2 identik (AC-4, O-7)")
	var g: Dictionary = _golden()
	check(str(g.get("blob_route_builder_main", "")).length() == 40 and int(g.get("jumlah_seed", 0)) == 60, "berkas golden memuat blob route_builder main dan 60 seed")
	var awal: int = int(g["seed_awal"])
	var langkah: int = int(g["seed_langkah"])
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 6020
	var beda_tanpa: int = 0
	var beda_dengan: int = 0
	var total: int = 0
	for hari: int in range(1, 6):
		var daftar: Array = g["sidik"][str(hari)]
		for i: int in range(60):
			var benih: int = awal + langkah * i
			var tanpa: RouteBuilder.Hasil = _bangun(benih, hari, null)
			if not tanpa.sah() or _sidik(tanpa.rute) != int(daftar[i]):
				beda_tanpa += 1
			if hari <= 2:
				var kaya: PelangganRute = _keadaan(rng, [2, 4, 3, 1] as Array[int], hari + 5)
				var dengan: RouteBuilder.Hasil = _bangun(benih, hari, kaya)
				if not dengan.sah() or _sidik(dengan.rute) != int(daftar[i]):
					beda_dengan += 1
			total += 1
	check(total == 300, "300 kombinasi seed x hari dibandingkan")
	check(beda_tanpa == 0, "bangun tanpa keadaan sama dengan golden main di 300 kombinasi seed x hari 1..5 (selisih %d)" % beda_tanpa)
	check(beda_dengan == 0, "bangun dengan keadaan kaya di hari 1 dan 2 sama dengan golden main di 120 kombinasi (selisih %d)" % beda_dengan)


func _test_keadaan_kosong_sama_tanpa_keadaan() -> void:
	_judul.call("Keadaan kosong hari >= 3: pelanggan dan segmen sama dengan tanpa keadaan; kuota dekat 8 atau 9 (O-7)")
	var kosong: PelangganRute = PelangganRute.dari_state({}, _kepribadian)
	var sama: int = 0
	var uji: int = 0
	for i: int in range(80):
		var hari: int = 3 + i % 20
		var benih: int = SeedHari.rute(hari) + i
		var a: RouteBuilder.Hasil = _bangun(benih, hari, null)
		var b: RouteBuilder.Hasil = _bangun(benih, hari, kosong)
		uji += 1
		if a.sah() and b.sah() and _ids_pelanggan(a.rute) == _ids_pelanggan(b.rute) and b.rute.pelepasan == 0:
			sama += 1
	check(sama == uji, "keadaan tanpa entri memberi pelanggan yang sama dengan rute tanpa keadaan di %d dari %d seed (tidak ada pelepasan)" % [sama, uji])


# --- AC-4: aturan pada >= 1000 kombinasi ---

func _test_kombinasi_acak() -> void:
	_judul.call("Aturan O-7 (a) sampai (e) pada %d kombinasi seed, hari, dan keadaan acak (AC-4)" % KOMBINASI)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 60201023
	var profil: Array = [[2, 4, 3, 1], [1, 3, 5, 1], [6, 2, 1, 1], [0, 3, 3, 4], [3, 3, 3, 1], [1, 5, 2, 2]]
	var tidak_sah: int = 0
	var galat_periksa: int = 0
	var tak_deterministik: int = 0
	var segmen_beda: int = 0
	var langgar_a: int = 0
	var langgar_b: int = 0
	var langgar_c: int = 0
	var langgar_d: int = 0
	var langgar_kembali: int = 0
	var langgar_kuota: int = 0
	var lepas: int = 0
	var diperiksa_aturan: int = 0
	var ada_calon: int = 0
	var ada_setia_lebih: int = 0
	for n: int in range(KOMBINASI):
		var hari: int = rng.randi_range(3, 80)
		var benih: int = rng.randi_range(1, 2000000000)
		var bobot: Array[int] = []
		for b: int in (profil[n % profil.size()] as Array):
			bobot.append(b)
		var p: PelangganRute = _keadaan(rng, bobot, hari)
		var hasil: RouteBuilder.Hasil = _bangun(benih, hari, p)
		if not hasil.sah():
			tidak_sah += 1
			continue
		var rute: RouteBuilder.Rute = hasil.rute
		if not RouteBuilder.periksa_rute(rute).is_empty():
			galat_periksa += 1
		var ulang: RouteBuilder.Hasil = _bangun(benih, hari, p)
		if not ulang.sah() or _identitas(ulang.rute) != _identitas(rute):
			tak_deterministik += 1
		var tanpa: RouteBuilder.Hasil = _bangun(benih, hari, null)
		if tanpa.sah():
			var s1: Array[String] = []
			var s2: Array[String] = []
			for s: SegmenRute in tanpa.rute.segmen:
				s1.append(s.id)
			for s: SegmenRute in rute.segmen:
				s2.append(s.id)
			if s1 != s2:
				segmen_beda += 1
		var dekat: int = _jumlah_sisi(rute, LoperAnim.Sisi.DEKAT)
		if dekat < 8 or dekat > 9 or rute.pelanggan.size() != 25:
			langgar_kuota += 1
		if rute.pelepasan > 0:
			lepas += 1
			continue
		diperiksa_aturan += 1
		# (a) berhenti hanya calon kembali, paling banyak 1.
		var berhenti: int = 0
		for r: RouteBuilder.RumahRute in rute.pelanggan:
			if p.status(r.id) == "berhenti":
				berhenti += 1
				if not p.calon_kembali(r.id, hari):
					langgar_a += 1
		if berhenti > 1:
			langgar_a += 1
		# calon kembali yang ada di segmen rute ini: tepat satu terpilih.
		var calon_ada: bool = false
		for r: RouteBuilder.RumahRute in rute.rumah:
			if r.pelanggan_boleh and p.calon_kembali(r.id, hari):
				calon_ada = true
		if calon_ada:
			ada_calon += 1
			if berhenti != 1:
				langgar_kembali += 1
		# (b) setia: paling sedikit min(tersedia, lantai 60% kuota) per sisi (yang di luar prioritas tetap kandidat biasa).
		for sisi: LoperAnim.Sisi in [LoperAnim.Sisi.DEKAT, LoperAnim.Sisi.SEBERANG]:
			var kuota: int = _jumlah_sisi(rute, sisi)
			var batas: int = int(floor(float(kuota) * 0.6))
			var tersedia: int = 0
			var terpilih_setia: int = 0
			for r: RouteBuilder.RumahRute in rute.rumah:
				if r.sisi == sisi and r.pelanggan_boleh and p.status(r.id) == "setia":
					tersedia += 1
			for r: RouteBuilder.RumahRute in rute.pelanggan:
				if r.sisi == sisi and p.status(r.id) == "setia":
					terpilih_setia += 1
			if terpilih_setia < mini(tersedia, batas):
				langgar_b += 1
			if tersedia > batas:
				ada_setia_lebih += 1
		# (c) pelanggan baru paling banyak 6 kecuali pelanggan dikenal kurang.
		var baru: int = 0
		for r: RouteBuilder.RumahRute in rute.pelanggan:
			if p.status(r.id) == "baru":
				baru += 1
		if baru > 6 and not rute.dikenal_kurang:
			langgar_c += 1
		# (d) pemberi tip: tepat 7; berkepribadian pemberi_tip didahulukan.
		var tip_kepribadian: int = 0
		var tip_kepribadian_tip: int = 0
		for r: RouteBuilder.RumahRute in rute.pelanggan:
			if p.kepribadian_dari(r.id) == "pemberi_tip":
				tip_kepribadian += 1
				if r.pemberi_tip:
					tip_kepribadian_tip += 1
		if rute.id_pemberi_tip.size() != 7 or tip_kepribadian_tip != mini(tip_kepribadian, 7):
			langgar_d += 1
	check(tidak_sah == 0, "semua %d kombinasi menghasilkan rute sah (tidak pernah gagal bangun) (selisih %d)" % [KOMBINASI, tidak_sah])
	check(galat_periksa == 0, "periksa_rute kosong di semua rute (%d galat)" % galat_periksa)
	check(tak_deterministik == 0, "kombinasi sama memberi rute sama persis (%d beda)" % tak_deterministik)
	check(segmen_beda == 0, "susunan segmen sama dengan rute tanpa keadaan (keadaan hanya mengubah pelanggan) (%d beda)" % segmen_beda)
	check(langgar_kuota == 0, "25 pelanggan dan kuota dekat 8 atau 9 di semua rute (%d pelanggaran)" % langgar_kuota)
	check(diperiksa_aturan >= 800, "sebagian besar kombinasi memenuhi aturan tanpa pelepasan prioritas (%d dari %d, pelepasan %d)" % [diperiksa_aturan, KOMBINASI, lepas])
	check(langgar_a == 0, "(a) berhenti tidak dipilih kecuali paling banyak 1 calon kembali (%d pelanggaran)" % langgar_a)
	check(ada_calon > 50 and langgar_kembali == 0, "(a) bila ada calon kembali di segmen rute, tepat satu terpilih (%d rute, %d pelanggaran)" % [ada_calon, langgar_kembali])
	check(ada_setia_lebih > 50 and langgar_b == 0, "(b) setia terpilih paling sedikit min(tersedia, 60%% kuota) per sisi (%d rute dengan setia melebihi batas, %d pelanggaran)" % [ada_setia_lebih, langgar_b])
	check(langgar_c == 0, "(c) pelanggan baru paling banyak 6 kecuali pelanggan dikenal kurang (%d pelanggaran)" % langgar_c)
	check(langgar_d == 0, "(d) pemberi tip tepat 7 dan berkepribadian pemberi_tip didahulukan (%d pelanggaran)" % langgar_d)


# --- AC-4: batas pelanggan baru mengikat bila pelanggan dikenal cukup ---

func _test_batas_baru() -> void:
	_judul.call("Batas pelanggan baru (c): mengikat bila pelanggan dikenal cukup, dilonggarkan bila kurang (O-7)")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 31337
	var mengikat: int = 0
	var langgar: int = 0
	var longgar_dipakai: int = 0
	for n: int in range(150):
		var hari: int = rng.randi_range(3, 60)
		var p: PelangganRute = _keadaan(rng, [2, 6, 2, 0] as Array[int], hari)
		var h: RouteBuilder.Hasil = _bangun(rng.randi_range(1, 2000000000), hari, p)
		if not h.sah() or h.rute.pelepasan > 0:
			continue
		var calon_baru: int = 0
		for r: RouteBuilder.RumahRute in h.rute.rumah:
			if r.pelanggan_boleh and p.status(r.id) == "baru":
				calon_baru += 1
		var baru: int = 0
		for r: RouteBuilder.RumahRute in h.rute.pelanggan:
			if p.status(r.id) == "baru":
				baru += 1
		if h.rute.dikenal_kurang:
			longgar_dipakai += 1
			continue
		if calon_baru > 6:
			mengikat += 1
		if baru > 6:
			langgar += 1
	check(mengikat >= 60, "batas baru benar-benar mengikat: %d rute punya lebih dari 6 rumah baru di segmennya, tanpa pelanggan dikenal kurang" % mengikat)
	check(langgar == 0, "pelanggan baru paling banyak 6 di semua rute yang pelanggan dikenalnya cukup (%d pelanggaran)" % langgar)
	# Hari 3 dengan sisi dekat belum dikenal sama sekali: batas dilonggarkan di sisi dekat, jadi rute tetap sah dengan 8 atau 9 pelanggan dekat baru.
	var peta: Dictionary = {}
	for id: String in _id_boleh:
		if not _id_dekat[id]:
			peta[id] = {"status": "aktif", "antar": 1, "meleset": 0, "hari_berhenti": 0}
	var p3: PelangganRute = PelangganRute.dari_state({"pelanggan": peta}, _kepribadian)
	var h3: RouteBuilder.Hasil = _bangun(SeedHari.rute(3), 3, p3)
	check(h3.sah() and h3.rute.dikenal_kurang and _jumlah_sisi(h3.rute, LoperAnim.Sisi.DEKAT) >= 8, "hari 3: sisi dekat belum dikenal = batas baru dilonggarkan, 8 atau 9 pelanggan dekat tetap terpilih")


# --- AC-4: keadaan ekstrem ---

func _test_ekstrem() -> void:
	_judul.call("Keadaan ekstrem: semua berhenti, semua setia, semua aktif, semua baru, hanya dekat berhenti, kandidat kurang (AC-4)")
	var kasus: Dictionary = {
		"semua berhenti lama": _keadaan_seragam("berhenti", 1),
		"semua berhenti baru saja": _keadaan_seragam("berhenti", 29),
		"semua setia": _keadaan_seragam("setia", 0),
		"semua aktif": _keadaan_seragam("aktif", 0),
		"semua baru": PelangganRute.dari_state({}, _kepribadian),
	}
	var peta_dekat: Dictionary = {}
	for id: String in _id_boleh:
		if _id_dekat[id]:
			peta_dekat[id] = {"status": "berhenti", "antar": 0, "meleset": 2, "hari_berhenti": 1}
	kasus["semua dekat berhenti"] = PelangganRute.dari_state({"pelanggan": peta_dekat}, _kepribadian)
	var peta_sedikit: Dictionary = {}
	for i: int in range(0, _id_boleh.size(), 9):
		peta_sedikit[_id_boleh[i]] = {"status": "setia", "antar": 7, "meleset": 0, "hari_berhenti": 0}
	kasus["hanya delapan rumah dikenal"] = PelangganRute.dari_state({"pelanggan": peta_sedikit}, _kepribadian)
	for nama: String in kasus:
		var p: PelangganRute = kasus[nama]
		var tidak_sah: int = 0
		var galat: int = 0
		var tak_det: int = 0
		var lepas: int = 0
		for i: int in range(40):
			var hari: int = 30
			var benih: int = SeedHari.rute(hari) + i * 17
			var h: RouteBuilder.Hasil = _bangun(benih, hari, p)
			if not h.sah():
				tidak_sah += 1
				continue
			if not RouteBuilder.periksa_rute(h.rute).is_empty():
				galat += 1
			if _identitas(_bangun(benih, hari, p).rute) != _identitas(h.rute):
				tak_det += 1
			if h.rute.pelepasan > 0:
				lepas += 1
		check(tidak_sah == 0, "%s: 40 rute semuanya sah, tidak pernah gagal bangun (%d gagal)" % [nama, tidak_sah])
		check(galat == 0 and tak_det == 0, "%s: periksa_rute kosong dan deterministik (%d galat, %d tak deterministik)" % [nama, galat, tak_det])
		if nama == "semua berhenti baru saja":
			check(lepas == 40, "%s: prioritas dan larangan dilepas bertahap (pelepasan > 0 di semua rute)" % nama)
		if nama == "semua baru" or nama == "semua aktif":
			check(lepas == 0, "%s: tidak ada pelepasan (%d dari 40)" % [nama, lepas])
		if nama == "semua setia":
			check(lepas <= 4, "%s: prioritas 60%% kuota jarang perlu dilepas (%d dari 40)" % [nama, lepas])


# --- AC-2: tidak ada keadaan buntu ---

func _test_jalan_kembali() -> void:
	_judul.call("Tidak ada keadaan buntu: tiap rumah berhenti muncul lagi sebagai calon kembali dan kembali aktif lewat antaran atau misi (AC-2)")
	var tidak_muncul: Array[String] = []
	var tidak_menunggu: Array[String] = []
	var tidak_kembali: Array[String] = []
	var tidak_kembali_misi: Array[String] = []
	var hari_mulai: int = 40
	for id: String in _id_boleh:
		var p: PelangganRute = PelangganRute.dari_state({"pelanggan": {id: {"status": "berhenti", "antar": 0, "meleset": 2, "hari_berhenti": hari_mulai - 1}}}, _kepribadian)
		for d: int in range(Config.PELANGGAN_KEMBALI_JEDA_HARI - 1):
			var awal: RouteBuilder.Hasil = _bangun(SeedHari.rute(hari_mulai + d), hari_mulai + d, p)
			if awal.sah() and awal.rute.pelepasan == 0 and _ids_pelanggan(awal.rute).has(id):
				tidak_menunggu.append("%s@+%d" % [id, d])
		var hari_cari: int = hari_mulai
		var ketemu: RouteBuilder.Rute = null
		for d: int in range(1, 31):
			hari_cari = hari_mulai - 1 + Config.PELANGGAN_KEMBALI_JEDA_HARI + d
			var h2: RouteBuilder.Hasil = _bangun(SeedHari.rute(hari_cari), hari_cari, p)
			if h2.sah() and _ids_pelanggan(h2.rute).has(id):
				ketemu = h2.rute
				break
		if ketemu == null:
			tidak_muncul.append(id)
			continue
		var skor: SkorRute.Keadaan = SkorRute.awal()
		skor.terantar[id] = true
		skor.kualitas[id] = SkorRute.Kualitas.KOTAK_SURAT
		var catatan: ReputationManager.Catatan = ReputationManager.catat(ketemu, skor, hari_cari)
		var hasil: ReputationManager.Hasil = ReputationManager.terapkan({"pelanggan": p.pelanggan, "reputasi": {"perumahan": 10}}, catatan, _kepribadian)
		if (hasil.state["pelanggan"] as Dictionary)[id]["status"] != "aktif" or hasil.jumlah(ReputationManager.Jenis.KEMBALI) != 1:
			tidak_kembali.append(id)
		# lewat misi selesai di rumah itu
		var c2: ReputationManager.Catatan = ReputationManager.Catatan.new()
		c2.hari = hari_cari
		c2.misi = ReputationManager.CatatanMisi.new()
		c2.misi.selesai = true
		c2.misi.tingkat = "sedang"
		c2.misi.id_rumah = id
		var h3: ReputationManager.Hasil = ReputationManager.terapkan({"pelanggan": p.pelanggan, "reputasi": {"perumahan": 10}}, c2, _kepribadian)
		if (h3.state["pelanggan"] as Dictionary)[id]["status"] != "aktif":
			tidak_kembali_misi.append(id)
	check(tidak_menunggu.is_empty(), "rumah berhenti belum dipilih sebelum jeda %d hari lewat bila tidak ada pelepasan (pelanggaran: %s)" % [Config.PELANGGAN_KEMBALI_JEDA_HARI, tidak_menunggu])
	check(tidak_muncul.is_empty(), "setiap dari %d rumah berhenti muncul lagi sebagai calon kembali dalam 30 hari sesudah jeda (tidak muncul: %s)" % [_id_boleh.size(), tidak_muncul])
	check(tidak_kembali.is_empty(), "antaran di rute nyata mengembalikan tiap rumah berhenti ke aktif dengan satu peristiwa KEMBALI (gagal: %s)" % [tidak_kembali])
	check(tidak_kembali_misi.is_empty(), "misi selesai di rumah berhenti mengembalikannya ke aktif (gagal: %s)" % [tidak_kembali_misi])


func _test_pemberi_tip() -> void:
	_judul.call("Pemberi tip persisten: rumah berkepribadian pemberi_tip yang masuk rute selalu memberi tip bila jumlahnya <= 7 (O-7 d)")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 77
	var p: PelangganRute = _keadaan(rng, [0, 5, 3, 0] as Array[int], 20)
	var konsisten: int = 0
	var uji: int = 0
	var berbeda_dari_acak: int = 0
	for i: int in range(60):
		var hari: int = 10 + i
		var h: RouteBuilder.Hasil = _bangun(SeedHari.rute(hari), hari, p)
		if not h.sah():
			continue
		uji += 1
		var tip_kep: Array[String] = []
		for r: RouteBuilder.RumahRute in h.rute.pelanggan:
			if p.kepribadian_dari(r.id) == "pemberi_tip":
				tip_kep.append(r.id)
		var semua_tip: bool = true
		for id: String in tip_kep:
			if tip_kep.size() <= 7 and not h.rute.id_pemberi_tip.has(id):
				semua_tip = false
		if semua_tip and h.rute.id_pemberi_tip.size() == 7:
			konsisten += 1
		var tanpa: RouteBuilder.Hasil = _bangun(SeedHari.rute(hari), hari, null)
		if tanpa.sah() and tanpa.rute.id_pemberi_tip.keys() != h.rute.id_pemberi_tip.keys():
			berbeda_dari_acak += 1
	check(uji == 60 and konsisten == uji, "60 rute: pemberi tip selalu 7 dan semua rumah pemberi_tip yang masuk ikut (%d dari %d)" % [konsisten, uji])
	check(berbeda_dari_acak > 0, "pemilihan pemberi tip dengan keadaan berbeda dari pemilihan acak tanpa keadaan")
