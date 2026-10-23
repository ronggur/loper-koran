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
## Rute keadaan realistis di `_test_berhenti_terpaksa` dan batas persen rute dengan pengecualian `berhenti_terpaksa` (terukur 0 di 2000 rute; batas tertulis di BALANCING 7.2) serta batas rata-rata rumah terpaksa per rute terpaksa.
const REALISTIS_RUTE: int = 300
const BATAS_PERSEN_TERPAKSA: int = 1
const BATAS_TERPAKSA_RATA: int = 3

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
	_test_batas_jeda()
	_test_berhenti_terpaksa()
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
	var terpaksa: int = 0
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
		else:
			diperiksa_aturan += 1
		# (a) berhenti hanya calon kembali, paling banyak 1: berlaku di SEMUA rute, termasuk yang prioritasnya dilepas (QA-001, iterasi 2). Tak ada pengecualian `berhenti_terpaksa`
		# pada keadaan acak ini (berhenti hanya untuk 11 rumah sensitif, jadi selalu ada susunan sah tanpa mereka).
		var berhenti: int = 0
		for r: RouteBuilder.RumahRute in rute.pelanggan:
			if p.status(r.id) == "berhenti":
				berhenti += 1
				if not p.calon_kembali(r.id, hari):
					langgar_a += 1
		if berhenti > 1:
			langgar_a += 1
		if not rute.berhenti_terpaksa.is_empty():
			terpaksa += 1
		# (d) pemberi tip: tepat 7; berkepribadian pemberi_tip didahulukan. Berlaku di semua rute.
		var tip_kepribadian: int = 0
		var tip_kepribadian_tip: int = 0
		for r: RouteBuilder.RumahRute in rute.pelanggan:
			if p.kepribadian_dari(r.id) == "pemberi_tip":
				tip_kepribadian += 1
				if r.pemberi_tip:
					tip_kepribadian_tip += 1
		if rute.id_pemberi_tip.size() != 7 or tip_kepribadian_tip != mini(tip_kepribadian, 7):
			langgar_d += 1
		if rute.pelepasan > 0:
			continue
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

	check(tidak_sah == 0, "semua %d kombinasi menghasilkan rute sah (tidak pernah gagal bangun) (selisih %d)" % [KOMBINASI, tidak_sah])
	check(galat_periksa == 0, "periksa_rute kosong di semua rute (%d galat)" % galat_periksa)
	check(tak_deterministik == 0, "kombinasi sama memberi rute sama persis (%d beda)" % tak_deterministik)
	check(segmen_beda == 0, "susunan segmen sama dengan rute tanpa keadaan (keadaan hanya mengubah pelanggan) (%d beda)" % segmen_beda)
	check(langgar_kuota == 0, "25 pelanggan dan kuota dekat 8 atau 9 di semua rute (%d pelanggaran)" % langgar_kuota)
	check(diperiksa_aturan >= 800, "sebagian besar kombinasi memenuhi aturan tanpa pelepasan prioritas (%d dari %d, pelepasan %d)" % [diperiksa_aturan, KOMBINASI, lepas])
	check(langgar_a == 0, "(a) berhenti tidak dipilih kecuali paling banyak 1 calon kembali, juga di rute yang prioritasnya dilepas (%d rute dilepas, %d pelanggaran)" % [lepas, langgar_a])
	check(lepas > 0 and terpaksa == 0, "pada keadaan acak (berhenti hanya sensitif) tidak ada pengecualian berhenti_terpaksa di %d rute, %d di antaranya dengan pelepasan (terpaksa %d)" % [KOMBINASI, lepas, terpaksa])
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
			if awal.sah() and _ids_pelanggan(awal.rute).has(id):
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
	check(tidak_menunggu.is_empty(), "rumah berhenti belum dipilih sebelum jeda %d hari lewat, dengan atau tanpa pelepasan prioritas (QA-001; pelanggaran: %s)" % [Config.PELANGGAN_KEMBALI_JEDA_HARI, tidak_menunggu])
	check(tidak_muncul.is_empty(), "setiap dari %d rumah berhenti muncul lagi sebagai calon kembali dalam 30 hari sesudah jeda (tidak muncul: %s)" % [_id_boleh.size(), tidak_muncul])
	check(tidak_kembali.is_empty(), "antaran di rute nyata mengembalikan tiap rumah berhenti ke aktif dengan satu peristiwa KEMBALI (gagal: %s)" % [tidak_kembali])
	check(tidak_kembali_misi.is_empty(), "misi selesai di rumah berhenti mengembalikannya ke aktif (gagal: %s)" % [tidak_kembali_misi])


# --- QA-002: batas jeda calon kembali ---

func _test_batas_jeda() -> void:
	_judul.call("Batas jeda calon kembali: tepat PELANGGAN_KEMBALI_JEDA_HARI hari sesudah berhenti sudah calon, satu hari kurang belum (O-7 a, QA-002)")
	var jeda: int = Config.PELANGGAN_KEMBALI_JEDA_HARI
	var hari: int = 40
	var id: String = _id_boleh[0]
	var peta: Callable = func(hari_berhenti: int, status: String = "berhenti") -> PelangganRute:
		return PelangganRute.dari_state({"pelanggan": {id: {"status": status, "antar": 0, "meleset": 2, "hari_berhenti": hari_berhenti}}}, _kepribadian)
	check((peta.call(hari - jeda) as PelangganRute).calon_kembali(id, hari), "berhenti %d hari lalu (tepat jeda) = calon kembali" % jeda)
	check(not (peta.call(hari - jeda + 1) as PelangganRute).calon_kembali(id, hari), "berhenti %d hari lalu (satu hari kurang dari jeda) = bukan calon" % (jeda - 1))
	check((peta.call(hari - jeda - 1) as PelangganRute).calon_kembali(id, hari), "berhenti %d hari lalu (lewat jeda) = calon kembali" % (jeda + 1))
	check(not (peta.call(hari) as PelangganRute).calon_kembali(id, hari), "berhenti hari ini = bukan calon")
	check(not (peta.call(hari - jeda, "aktif") as PelangganRute).calon_kembali(id, hari) and not (peta.call(hari - jeda, "setia") as PelangganRute).calon_kembali(id, hari), "aktif dan setia tidak pernah calon kembali")
	# Lewat RouteBuilder nyata: pada tiap rumah, calon kembali (tepat jeda) masuk rute yang memuat segmennya, satu hari kurang tidak pernah masuk.
	var ada_a: int = 0
	var seharusnya_a: int = 0
	var ada_b: int = 0
	var terpaksa: int = 0
	for rumah_id: String in _id_boleh:
		for k: int in range(2):
			var benih: int = SeedHari.rute(hari) + k * 7919
			var pa: PelangganRute = PelangganRute.dari_state({"pelanggan": {rumah_id: {"status": "berhenti", "antar": 0, "meleset": 2, "hari_berhenti": hari - jeda}}}, _kepribadian)
			var pb: PelangganRute = PelangganRute.dari_state({"pelanggan": {rumah_id: {"status": "berhenti", "antar": 0, "meleset": 2, "hari_berhenti": hari - jeda + 1}}}, _kepribadian)
			var ha: RouteBuilder.Hasil = _bangun(benih, hari, pa)
			var hb: RouteBuilder.Hasil = _bangun(benih, hari, pb)
			if ha.sah():
				terpaksa += ha.rute.berhenti_terpaksa.size()
				var di_segmen: bool = false
				for r: RouteBuilder.RumahRute in ha.rute.rumah:
					if r.id == rumah_id and r.pelanggan_boleh:
						di_segmen = true
				if di_segmen:
					seharusnya_a += 1
					if _ids_pelanggan(ha.rute).has(rumah_id):
						ada_a += 1
			if hb.sah():
				terpaksa += hb.rute.berhenti_terpaksa.size()
				if _ids_pelanggan(hb.rute).has(rumah_id):
					ada_b += 1
	check(seharusnya_a >= 100, "cukup rute memuat rumah calon kembali di segmennya (%d)" % seharusnya_a)
	check(ada_a == seharusnya_a, "calon kembali tepat jeda diprioritaskan di tiap rute yang memuat segmennya (%d dari %d)" % [ada_a, seharusnya_a])
	check(ada_b == 0, "berhenti satu hari kurang dari jeda tidak pernah masuk rute (%d kali masuk)" % ada_b)
	check(terpaksa == 0, "satu rumah berhenti tidak pernah memaksa pengecualian berhenti_terpaksa (%d)" % terpaksa)


# --- QA-001: pengecualian larangan berhenti hanya bila terpaksa, eksplisit, dan sesedikit mungkin ---

## Susunan sah ada tanpa rumah `berhenti` (selain `kembali`)? Oracle sendiri (tanpa kode RouteBuilder): rekursi dengan memo atas (indeks terakhir, jumlah dekat, jumlah seberang) pada kandidat gabungan urut maju.
func _ada_susunan_tanpa(rute: RouteBuilder.Rute, p: PelangganRute, hari: int, kuota_dekat: int) -> bool:
	var kandidat: Array[RouteBuilder.RumahRute] = []
	for r: RouteBuilder.RumahRute in rute.rumah:
		if r.pelanggan_boleh and (p.status(r.id) != "berhenti" or p.calon_kembali(r.id, hari)):
			kandidat.append(r)
	kandidat.sort_custom(func(a: RouteBuilder.RumahRute, b: RouteBuilder.RumahRute) -> bool: return a.maju_ubin < b.maju_ubin or (a.maju_ubin == b.maju_ubin and a.id < b.id))
	var memo: Dictionary = {}
	var k_seberang: int = Config.RUTE_PELANGGAN - kuota_dekat
	var coba: Callable = func(coba_lagi: Callable, i: int, d: int, s: int) -> bool:
		if d == kuota_dekat and s == k_seberang:
			return true
		var kunci: int = (i * 100 + d) * 100 + s
		if memo.has(kunci):
			return memo[kunci]
		var hasil: bool = false
		for j: int in range(i + 1, kandidat.size()):
			if i >= 0 and kandidat[j].maju_ubin - kandidat[i].maju_ubin > Config.RUTE_PELANGGAN_JARAK_MAKS_UBIN:
				break
			var dekat: bool = kandidat[j].sisi == LoperAnim.Sisi.DEKAT
			var nd: int = d + (1 if dekat else 0)
			var ns: int = s + (0 if dekat else 1)
			if nd <= kuota_dekat and ns <= k_seberang and coba_lagi.call(coba_lagi, j, nd, ns):
				hasil = true
				break
		memo[kunci] = hasil
		return hasil
	return coba.call(coba, -1, 0, 0)


func _test_berhenti_terpaksa() -> void:
	_judul.call("Pengecualian larangan berhenti: hanya bila tak ada susunan sah tanpa mereka, tercatat di berhenti_terpaksa, dan jarang (O-7 a, QA-001)")
	# Kasus 1: semua rumah berhenti baru saja (tak ada calon kembali): semua 25 pelanggan terpaksa, semuanya tercatat.
	var p_semua: PelangganRute = _keadaan_seragam("berhenti", 29)
	var tercatat_semua: int = 0
	var uji_semua: int = 0
	for i: int in range(20):
		var h: RouteBuilder.Hasil = _bangun(SeedHari.rute(30) + i * 17, 30, p_semua)
		if not h.sah():
			continue
		uji_semua += 1
		var ids: Array[String] = _ids_pelanggan(h.rute)
		var terdaftar: Array[String] = h.rute.berhenti_terpaksa.duplicate()
		ids.sort()
		terdaftar.sort()
		if ids == terdaftar and h.rute.pelepasan > 0:
			tercatat_semua += 1
	check(uji_semua == 20 and tercatat_semua == 20, "semua berhenti: 25 pelanggan semuanya tercatat berhenti_terpaksa dan pelepasan > 0 (%d dari %d rute)" % [tercatat_semua, uji_semua])
	# Kasus 2: berhenti sebagian besar di satu segmen tengah (lubang): pengecualian hanya bila oracle membuktikan tak ada susunan tanpa mereka.
	var jumlah_wajar: int = 0
	var jumlah_terpaksa: int = 0
	var salah_terpaksa: int = 0
	var salah_tercatat: int = 0
	var jumlah_terpaksa_total: int = 0
	var uji_lubang: int = 0
	var gagal_lubang: int = 0
	var hari: int = 30
	for sid: String in ["per_tengah_01", "per_tengah_03", "per_tengah_05", "per_buka_02", "per_tutup_01"]:
		var peta: Dictionary = {}
		for id: String in _id_boleh:
			if id.begins_with(sid + "@"):
				peta[id] = {"status": "berhenti", "antar": 0, "meleset": 2, "hari_berhenti": hari - 1}
		var p: PelangganRute = PelangganRute.dari_state({"pelanggan": peta}, _kepribadian)
		for i: int in range(16):
			var h: RouteBuilder.Hasil = _bangun(SeedHari.rute(hari) + i * 31, hari, p)
			if not h.sah():
				gagal_lubang += 1
				continue
			var memuat: bool = false
			for sg: SegmenRute in h.rute.segmen:
				if sg.id == sid:
					memuat = true
			if not memuat:
				continue
			uji_lubang += 1
			var dekat: int = _jumlah_sisi(h.rute, LoperAnim.Sisi.DEKAT)
			var tanpa: bool = _ada_susunan_tanpa(h.rute, p, hari, dekat)
			var terpaksa: Array[String] = h.rute.berhenti_terpaksa
			for r: RouteBuilder.RumahRute in h.rute.pelanggan:
				if p.status(r.id) == "berhenti" and not terpaksa.has(r.id):
					salah_tercatat += 1
			if tanpa:
				jumlah_wajar += 1
				if not terpaksa.is_empty():
					salah_terpaksa += 1
			else:
				jumlah_terpaksa += 1
				jumlah_terpaksa_total += terpaksa.size()
				if terpaksa.is_empty():
					salah_terpaksa += 1
	check(gagal_lubang == 0, "rute dengan lubang berhenti tetap sah, tidak pernah gagal bangun (%d gagal dari 80)" % gagal_lubang)
	check(uji_lubang >= 30, "cukup rute memuat segmen yang seluruh rumahnya berhenti (%d)" % uji_lubang)
	check(salah_terpaksa == 0, "pengecualian ada TEPAT bila oracle tak menemukan susunan tanpa rumah berhenti (%d salah; %d rute wajib, %d rute terpaksa)" % [salah_terpaksa, jumlah_wajar, jumlah_terpaksa])
	check(salah_tercatat == 0, "tiap rumah berhenti yang masuk rute tercatat di berhenti_terpaksa (%d tidak tercatat)" % salah_tercatat)
	check(jumlah_terpaksa == 0 or jumlah_terpaksa_total <= jumlah_terpaksa * BATAS_TERPAKSA_RATA, "rumah terpaksa sedikit: rata-rata <= %d per rute terpaksa (%d rumah di %d rute)" % [BATAS_TERPAKSA_RATA, jumlah_terpaksa_total, jumlah_terpaksa])
	# Kasus 3: keadaan realistis (berhenti hanya rumah sensitif, 1..11 rumah, semuanya bukan calon): pengecualian TIDAK PERNAH dipakai (QA-001: sebelumnya 1 sampai 9% rute).
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20261023
	var sensitif: Array[String] = []
	for id: String in _id_boleh:
		if KepribadianPelanggan.dari_id(id, _kepribadian) == KepribadianPelanggan.SENSITIF:
			sensitif.append(id)
	var uji_real: int = 0
	var pakai_real: int = 0
	var bocor_real: int = 0
	for n: int in range(REALISTIS_RUTE):
		var hr: int = rng.randi_range(5, 60)
		var peta_r: Dictionary = {}
		for id: String in _id_boleh:
			peta_r[id] = {"status": "aktif", "antar": 1, "meleset": 0, "hari_berhenti": 0}
		var acak: Array[String] = sensitif.duplicate()
		for i: int in range(acak.size() - 1, 0, -1):
			var j: int = rng.randi_range(0, i)
			var tmp: String = acak[i]
			acak[i] = acak[j]
			acak[j] = tmp
		for i: int in range(rng.randi_range(1, acak.size())):
			peta_r[acak[i]] = {"status": "berhenti", "antar": 0, "meleset": 2, "hari_berhenti": hr - 1}
		var pr: PelangganRute = PelangganRute.dari_state({"pelanggan": peta_r}, _kepribadian)
		var h2: RouteBuilder.Hasil = _bangun(rng.randi_range(1, 2000000000), hr, pr)
		if not h2.sah():
			continue
		uji_real += 1
		if not h2.rute.berhenti_terpaksa.is_empty():
			pakai_real += 1
		for r: RouteBuilder.RumahRute in h2.rute.pelanggan:
			if pr.status(r.id) == "berhenti":
				bocor_real += 1
	check(uji_real == REALISTIS_RUTE, "semua %d rute keadaan realistis sah (%d)" % [REALISTIS_RUTE, uji_real])
	check(bocor_real == 0, "keadaan realistis (hanya rumah sensitif bisa berhenti): tidak ada rumah berhenti baru-baru ini yang masuk rute (%d masuk)" % bocor_real)
	check(pakai_real <= int(REALISTIS_RUTE * BATAS_PERSEN_TERPAKSA / 100.0), "pengecualian berhenti_terpaksa di keadaan realistis paling banyak %d%% rute (terukur %d dari %d)" % [BATAS_PERSEN_TERPAKSA, pakai_real, uji_real])


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
