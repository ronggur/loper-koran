class_name TesReputasi
extends RefCounted
## Tes run fase6a2-reputasi-pelanggan bagian A (AC-1, AC-2, AC-3, AC-7): kepribadian pelanggan (pemuat, validasi, `dari_id`, sebaran 71 rumah), `ReputationManager` (tiap transisi status, reputasi, misi,
## kemurnian), pencatat kualitas di `SkorRute`, validasi `gagal.reputasi` di `DataMisi`, dan laju reputasi `SimEkonomi` untuk tiga profil.
##
## Oracle independen: FNV-1a ditulis ulang di sini dengan angka literal; kredit dan poin dihitung tangan dari tabel BALANCING 7.2 (tepat 4, teras 3, kotak surat 2, halaman 1, 30 kredit per poin).

const FOLDER_RUTE: String = "res://assets/data/routes/perumahan"

var _cek: Callable
var _judul: Callable
var _kep: Array[KepribadianPelanggan.Entri] = []
var _id_boleh: Array[String] = []
var _per_kepribadian: Dictionary = {}


func _init(cek: Callable, judul: Callable) -> void:
	_cek = cek
	_judul = judul


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_kep = PemuatPelanggan.muat().entri
	for s: SegmenRute in PemuatRute.muat_folder(FOLDER_RUTE).segmen:
		for r: SegmenRute.Rumah in s.rumah:
			if r.pelanggan_boleh:
				_id_boleh.append("%s@%d" % [s.id, r.pos])
	_id_boleh.sort()
	for id: String in _id_boleh:
		var k: String = KepribadianPelanggan.dari_id(id, _kep)
		if not _per_kepribadian.has(k):
			_per_kepribadian[k] = []
		(_per_kepribadian[k] as Array).append(id)
	_test_pemuat_nyata()
	_test_validasi_kepribadian()
	_test_dari_id()
	_test_transisi_status()
	_test_antaran_rumah_berhenti()
	_test_misi()
	_test_reputasi()
	_test_kemurnian()
	_test_data_rusak_di_state()
	_test_catat_dari_rute()
	_test_kualitas_skor()
	_test_gagal_reputasi_misi()
	_test_laju_reputasi()


# --- Pembantu ---

func _fnv(teks: String) -> int:
	var nilai: int = 2166136261
	for b: int in teks.to_utf8_buffer():
		nilai = nilai ^ b
		nilai = (nilai * 16777619) & 4294967295
	return nilai


func _id(kepribadian: String, n: int = 0) -> String:
	return (_per_kepribadian[kepribadian] as Array)[n]


func _entri(status: String, antar: int = 0, meleset: int = 0, hari_berhenti: int = 0) -> Dictionary:
	return {"status": status, "antar": antar, "meleset": meleset, "hari_berhenti": hari_berhenti}


func _state(peta: Dictionary, reputasi: int = 10) -> Dictionary:
	var s: Dictionary = DataSave.templat()
	s["pelanggan"] = peta
	s["reputasi"] = {"perumahan": reputasi}
	return s


func _catatan(hari: int, daftar: Array) -> ReputationManager.Catatan:
	var c: ReputationManager.Catatan = ReputationManager.Catatan.new()
	c.hari = hari
	for d: Array in daftar:
		var r: ReputationManager.CatatanRumah = ReputationManager.CatatanRumah.new()
		r.id = d[0]
		r.terantar = d[1]
		r.kualitas = d[2] if d.size() > 2 else (SkorRute.Kualitas.KOTAK_SURAT if r.terantar else -1)
		c.rumah.append(r)
	return c


func _misi(selesai: bool, id_rumah: String, tingkat: String = "sedang", setia: bool = false, gagal_rep: int = 0) -> ReputationManager.CatatanMisi:
	var m: ReputationManager.CatatanMisi = ReputationManager.CatatanMisi.new()
	m.id_misi = "p1_kucing"
	m.selesai = selesai
	m.gagal = not selesai
	m.tingkat = tingkat
	m.setia = setia
	m.id_rumah = id_rumah
	m.gagal_reputasi = gagal_rep
	return m


func _terapkan(state: Dictionary, c: ReputationManager.Catatan) -> ReputationManager.Hasil:
	return ReputationManager.terapkan(state, c, _kep)


func _e(h: ReputationManager.Hasil, id: String) -> Dictionary:
	return (h.state["pelanggan"] as Dictionary).get(id, {})


# --- AC-3: kepribadian ---

func _test_pemuat_nyata() -> void:
	_judul.call("Kepribadian: berkas nyata sah, empat id permanen, bobot > 0 (AC-3)")
	var k: PemuatPelanggan.Kumpulan = PemuatPelanggan.muat()
	check(k.sah() and k.entri.size() == 4, "kepribadian.json sah dengan 4 entri; galat: %s" % [k.galat])
	var ids: Array[String] = []
	for e: KepribadianPelanggan.Entri in k.entri:
		ids.append(e.id)
		check(e.bobot > 0, "bobot %s > 0" % e.id)
	check(ids == ["biasa", "cerewet", "pemberi_tip", "sensitif"], "id permanen dan urutan berkas: %s" % [ids])
	var n: int = 0
	for kunci: String in _per_kepribadian:
		n += (_per_kepribadian[kunci] as Array).size()
	check(n == 71 and _id_boleh.size() == 71, "71 rumah pelanggan_boleh di data nyata")


func _teks(isi: Array) -> String:
	return JSON.stringify(isi)


func _galat(isi: Variant) -> Array[String]:
	return PemuatPelanggan.parse_teks(JSON.stringify(isi), "uji.json").galat


func _dasar() -> Array:
	return [{"id": "biasa", "bobot": 5}, {"id": "cerewet", "bobot": 2}, {"id": "pemberi_tip", "bobot": 2}, {"id": "sensitif", "bobot": 1}]


func _test_validasi_kepribadian() -> void:
	_judul.call("Kepribadian: tiap pelanggaran validasi menghasilkan galat tanpa crash (AC-3)")
	check(_galat(_dasar()).is_empty(), "data dasar uji sah")
	var ganda: Array = _dasar()
	ganda.append({"id": "biasa", "bobot": 3})
	check(not _galat(ganda).is_empty() and ",".join(_galat(ganda)).contains("ganda"), "id ganda ditolak")
	for bobot: Variant in [0, -3, 1.5, "tiga", null, [1]]:
		var d: Array = _dasar()
		d[0]["bobot"] = bobot
		check(not _galat(d).is_empty(), "bobot %s ditolak" % [str(bobot)])
	var asing: Array = _dasar()
	asing[1]["id"] = "galak"
	check(",".join(_galat(asing)).contains("tidak dikenal"), "id asing ditolak")
	var fa: Array = _dasar()
	fa[2]["warna"] = "merah"
	check(",".join(_galat(fa)).contains("warna"), "field asing ditolak")
	var hilang: Array = _dasar()
	hilang.remove_at(3)
	check(",".join(_galat(hilang)).contains("sensitif"), "id wajib yang hilang ditolak")
	check(not _galat([]).is_empty(), "array kosong ditolak (jumlah bobot 0)")
	check(not _galat({"id": "biasa"}).is_empty(), "isi bukan array ditolak")
	check(not _galat([5, "x"]).is_empty(), "entri bukan objek ditolak")
	var rusak: PemuatPelanggan.Kumpulan = PemuatPelanggan.parse_teks("[{ini rusak", "uji.json")
	check(not rusak.galat.is_empty() and rusak.entri.is_empty(), "JSON rusak = galat, tanpa entri, tanpa crash")
	var id_hilang: Array = _dasar()
	id_hilang[0].erase("id")
	check(not _galat(id_hilang).is_empty(), "entri tanpa id ditolak")
	var tanpa: PemuatPelanggan.Kumpulan = PemuatPelanggan.muat("res://assets/data/customers/tidak_ada.json")
	check(not tanpa.galat.is_empty() and tanpa.entri.is_empty() and not tanpa.sah(), "berkas hilang = galat, entri kosong, tanpa crash")
	var kosong_berkas: PemuatPelanggan.Kumpulan = PemuatPelanggan.parse_teks("", "uji.json")
	check(not kosong_berkas.galat.is_empty(), "teks kosong = galat")
	check(KepribadianPelanggan.dari_id("per_buka_01@6", tanpa.entri) == "biasa", "pustaka kosong (berkas hilang) = semua pelanggan biasa, tanpa crash")
	var nol: Array[KepribadianPelanggan.Entri] = []
	var e0: KepribadianPelanggan.Entri = KepribadianPelanggan.Entri.new()
	e0.id = "biasa"
	e0.bobot = 0
	nol.append(e0)
	check(KepribadianPelanggan.dari_id("x@1", nol) == "biasa", "jumlah bobot 0 di memori = biasa, tanpa pembagian nol")


func _test_dari_id() -> void:
	_judul.call("Kepribadian: dari_id deterministik FNV-1a, sebaran 71 rumah sesuai bobot (AC-3)")
	var total: int = 0
	for e: KepribadianPelanggan.Entri in _kep:
		total += e.bobot
	check(KepribadianPelanggan.fnv1a_teks("per_buka_01@6") == _fnv("per_buka_01@6") and KepribadianPelanggan.fnv1a_teks("") == 2166136261, "FNV-1a 32 bit sama dengan oracle (termasuk teks kosong)")
	var salah: int = 0
	for id: String in _id_boleh:
		var sisa: int = _fnv(id) % total
		var harapan: String = ""
		var batas: int = 0
		for e: KepribadianPelanggan.Entri in _kep:
			batas += e.bobot
			if sisa < batas:
				harapan = e.id
				break
		if KepribadianPelanggan.dari_id(id, _kep) != harapan:
			salah += 1
		if KepribadianPelanggan.dari_id(id, _kep) != KepribadianPelanggan.dari_id(id, _kep):
			salah += 1
	check(salah == 0, "dari_id = oracle FNV-1a dan stabil untuk 71 rumah (%d selisih)" % salah)
	for e: KepribadianPelanggan.Entri in _kep:
		var jumlah: int = (_per_kepribadian.get(e.id, []) as Array).size()
		var diharapkan: float = 71.0 * float(e.bobot) / float(total)
		check(absf(float(jumlah) - diharapkan) <= 5.0, "sebaran %s: %d rumah, diharapkan %.1f (toleransi 5 rumah)" % [e.id, jumlah, diharapkan])
	var sama: bool = true
	var terbalik: Array[KepribadianPelanggan.Entri] = []
	for i: int in range(_kep.size() - 1, -1, -1):
		terbalik.append(_kep[i])
	for id: String in _id_boleh:
		if KepribadianPelanggan.dari_id(id, terbalik) != KepribadianPelanggan.dari_id(id, _kep):
			sama = false
	check(not sama, "urutan berkas ikut menentukan pemetaan (pustaka dibalik memberi pemetaan berbeda)")


# --- AC-2: transisi status ---

func _test_transisi_status() -> void:
	_judul.call("Status pelanggan: tiap transisi O-6 (AC-2)")
	var sens: String = _id("sensitif")
	var bias: String = _id("biasa")
	var cer: String = _id("cerewet")
	var tip: String = _id("pemberi_tip")
	# baru
	var h1: ReputationManager.Hasil = _terapkan(_state({}), _catatan(3, [[bias, true]]))
	check(_e(h1, bias) == _entri("aktif", 1, 0, 0) and h1.jumlah(ReputationManager.Jenis.BARU) == 1 and h1.peristiwa.size() == 1, "baru + terantar: aktif, antar 1, satu peristiwa BARU")
	var h1b: ReputationManager.Hasil = _terapkan(_state({}), _catatan(3, [[bias, false]]))
	check(_e(h1b, bias) == _entri("aktif", 0, 1, 0), "baru + tidak terantar: aktif, antar 0, meleset 1")
	# aktif -> setia
	var h2: ReputationManager.Hasil = _terapkan(_state({bias: _entri("aktif", 4, 0)}), _catatan(3, [[bias, true]]))
	check(_e(h2, bias)["status"] == "setia" and _e(h2, bias)["antar"] == 5 and h2.jumlah(ReputationManager.Jenis.SETIA) == 1, "aktif antar 4 + terantar = antar 5 = setia (peristiwa SETIA)")
	var h2b: ReputationManager.Hasil = _terapkan(_state({bias: _entri("aktif", 3, 0)}), _catatan(3, [[bias, true]]))
	check(_e(h2b, bias)["status"] == "aktif" and _e(h2b, bias)["antar"] == 4 and h2b.jumlah(ReputationManager.Jenis.SETIA) == 0, "antar 3 -> 4 masih aktif")
	var h2c: ReputationManager.Hasil = _terapkan(_state({bias: _entri("setia", 9, 0)}), _catatan(3, [[bias, true]]))
	check(_e(h2c, bias)["status"] == "setia" and h2c.jumlah(ReputationManager.Jenis.SETIA) == 0, "setia tetap setia tanpa peristiwa baru")
	# aktif -> berhenti (sensitif)
	var h3: ReputationManager.Hasil = _terapkan(_state({sens: _entri("aktif", 2, 1)}), _catatan(7, [[sens, false]]))
	check(_e(h3, sens)["status"] == "berhenti" and _e(h3, sens)["hari_berhenti"] == 7 and _e(h3, sens)["meleset"] == 2 and h3.jumlah(ReputationManager.Jenis.BERHENTI) == 1, "sensitif aktif meleset 1 + tidak terantar = meleset 2 = berhenti hari 7")
	var h3b: ReputationManager.Hasil = _terapkan(_state({sens: _entri("aktif", 2, 0)}), _catatan(7, [[sens, false]]))
	check(_e(h3b, sens)["status"] == "aktif" and _e(h3b, sens)["meleset"] == 1, "sensitif meleset pertama belum berhenti")
	# setia -> berhenti: lebih sabar satu hari
	var h4: ReputationManager.Hasil = _terapkan(_state({sens: _entri("setia", 8, 1)}), _catatan(7, [[sens, false]]))
	check(_e(h4, sens)["status"] == "setia" and _e(h4, sens)["meleset"] == 2, "sensitif setia meleset 2 masih setia (lebih sabar)")
	var h4b: ReputationManager.Hasil = _terapkan(_state({sens: _entri("setia", 8, 2)}), _catatan(9, [[sens, false]]))
	check(_e(h4b, sens)["status"] == "berhenti" and _e(h4b, sens)["hari_berhenti"] == 9, "sensitif setia meleset 3 = berhenti")
	# bukan sensitif tidak berhenti
	for id: String in [bias, cer, tip]:
		var h5: ReputationManager.Hasil = _terapkan(_state({id: _entri("aktif", 1, 6)}), _catatan(7, [[id, false]]))
		check(_e(h5, id)["status"] == "aktif" and _e(h5, id)["meleset"] == 7 and h5.jumlah(ReputationManager.Jenis.BERHENTI) == 0, "kepribadian %s tidak berhenti walau meleset 7" % KepribadianPelanggan.dari_id(id, _kep))
		var h5s: ReputationManager.Hasil = _terapkan(_state({id: _entri("setia", 9, 8)}), _catatan(7, [[id, false]]))
		check(_e(h5s, id)["status"] == "setia", "setia bukan sensitif tetap setia")
	# antaran mereset meleset
	var h6: ReputationManager.Hasil = _terapkan(_state({sens: _entri("aktif", 2, 1)}), _catatan(7, [[sens, true]]))
	check(_e(h6, sens)["meleset"] == 0 and _e(h6, sens)["antar"] == 3 and _e(h6, sens)["status"] == "aktif", "antaran mereset penghitung meleset berturut-turut")
	# berhenti -> aktif lewat antaran
	var h7: ReputationManager.Hasil = _terapkan(_state({sens: _entri("berhenti", 6, 2, 4)}), _catatan(9, [[sens, true]]))
	check(_e(h7, sens) == _entri("aktif", 0, 0, 0) and h7.jumlah(ReputationManager.Jenis.KEMBALI) == 1 and h7.jumlah(ReputationManager.Jenis.SETIA) == 0, "berhenti + antaran = aktif, antar 0, meleset 0, hari_berhenti 0 (KEMBALI)")
	var h7b: ReputationManager.Hasil = _terapkan(_state({sens: _entri("berhenti", 6, 2, 4)}), _catatan(9, [[sens, false]]))
	check(_e(h7b, sens) == _entri("berhenti", 6, 2, 4) and h7b.peristiwa.is_empty(), "berhenti yang tidak terantar tidak berubah dan tidak mengumpulkan meleset")
	# pelanggan di luar rute hari itu tidak berubah
	var peta: Dictionary = {sens: _entri("berhenti", 3, 2, 2), bias: _entri("aktif", 4, 1, 0), cer: _entri("setia", 9, 2, 0)}
	var h8: ReputationManager.Hasil = _terapkan(_state(peta), _catatan(9, [[tip, true]]))
	check(_e(h8, sens) == peta[sens] and _e(h8, bias) == peta[bias] and _e(h8, cer) == peta[cer] and (h8.state["pelanggan"] as Dictionary).size() == 4, "rumah yang tidak masuk rute hari itu tidak berubah")
	# duplikat id dihitung sekali
	var h9: ReputationManager.Hasil = _terapkan(_state({}), _catatan(3, [[bias, true], [bias, true]]))
	check(_e(h9, bias)["antar"] == 1 and h9.jumlah(ReputationManager.Jenis.BARU) == 1, "id ganda di catatan dihitung sekali")
	# beberapa berhenti sekaligus
	var sens2: String = _id("sensitif", 1)
	var h10: ReputationManager.Hasil = _terapkan(_state({sens: _entri("aktif", 0, 1), sens2: _entri("aktif", 0, 1)}, 10), _catatan(5, [[sens, false], [sens2, false]]))
	check(h10.jumlah(ReputationManager.Jenis.BERHENTI) == 2 and h10.reputasi_sesudah == 8 and h10.turun_berhenti == 2, "dua pelanggan berhenti = reputasi -2")


# --- QA-003: antaran sah ke rumah berhenti memberi kredit ---

func _test_antaran_rumah_berhenti() -> void:
	_judul.call("Rumah berhenti yang terantar: kredit reputasi penuh, kembali aktif, satu peristiwa KEMBALI (O-6, O-8, QA-003)")
	var sens: String = _id("sensitif")
	var per_kualitas: Dictionary = {SkorRute.Kualitas.TEPAT: 4, SkorRute.Kualitas.TERAS: 3, SkorRute.Kualitas.KOTAK_SURAT: 2, SkorRute.Kualitas.HALAMAN: 1}
	for q: int in per_kualitas:
		var h: ReputationManager.Hasil = _terapkan(_state({sens: _entri("berhenti", 6, 2, 4)}, 10), _catatan(9, [[sens, true, q]]))
		check(h.kredit == int(per_kualitas[q]), "rumah berhenti terantar kualitas %d: kredit %d (dapat %d)" % [q, per_kualitas[q], h.kredit])
		check(_e(h, sens) == _entri("aktif", 0, 0, 0) and h.jumlah(ReputationManager.Jenis.KEMBALI) == 1 and h.peristiwa.size() == 1, "rumah berhenti terantar kualitas %d: aktif, penghitung 0, tepat satu peristiwa KEMBALI" % q)
	# Kredit rumah berhenti ikut menentukan poin harian: tujuh rumah aktif tepat (28) + satu rumah berhenti tepat (4) = 32 = +1; tanpa kredit rumah berhenti 28 = 0.
	var ids: Array = _per_kepribadian["biasa"]
	var daftar: Array = _daftar(ids, 7, SkorRute.Kualitas.TEPAT)
	daftar.append([sens, true, SkorRute.Kualitas.TEPAT])
	var peta: Dictionary = {sens: _entri("berhenti", 6, 2, 4)}
	var h8: ReputationManager.Hasil = _terapkan(_state(peta, 10), _catatan(9, daftar))
	check(h8.kredit == 32 and h8.poin_antaran == 1 and h8.perubahan == 1 and _e(h8, sens)["status"] == "aktif", "7 antaran aktif tepat + 1 antaran rumah berhenti tepat = 32 kredit = +1 reputasi, rumah kembali aktif")
	# Rumah berhenti yang tidak terantar: tanpa kredit, tetap berhenti.
	var hn: ReputationManager.Hasil = _terapkan(_state(peta, 10), _catatan(9, [[sens, false]]))
	check(hn.kredit == 0 and _e(hn, sens)["status"] == "berhenti", "rumah berhenti tidak terantar: tanpa kredit, tetap berhenti")
	# Kembali lewat misi dan antaran hari yang sama: kredit antaran tetap diberikan satu kali.
	var c: ReputationManager.Catatan = _catatan(9, [[sens, true, SkorRute.Kualitas.TEPAT]])
	c.misi = _misi(true, sens, "kecil")
	var hm: ReputationManager.Hasil = _terapkan(_state(peta, 10), c)
	check(hm.kredit == 4 and hm.jumlah(ReputationManager.Jenis.KEMBALI) == 1 and _e(hm, sens) == _entri("aktif", 0, 0, 0), "kembali lewat misi dan antaran sekaligus: kredit antaran 4 tetap diberikan, satu KEMBALI")


func _test_misi() -> void:
	_judul.call("Misi dan pelanggan: kembali lewat misi, hadiah pelanggan_setia hanya untuk rumah pelanggan (O-6, AC-2)")
	var sens: String = _id("sensitif")
	var bias: String = _id("biasa")
	var lain: String = _id("biasa", 1)
	var h1: ReputationManager.Hasil = _terapkan(_state({sens: _entri("berhenti", 3, 2, 2)}), _catatan(9, []))
	check(_e(h1, sens)["status"] == "berhenti", "tanpa misi berhenti tetap berhenti")
	var c: ReputationManager.Catatan = _catatan(9, [])
	c.misi = _misi(true, sens)
	var h2: ReputationManager.Hasil = _terapkan(_state({sens: _entri("berhenti", 3, 2, 2)}), c)
	check(_e(h2, sens) == _entri("aktif", 0, 0, 0) and h2.jumlah(ReputationManager.Jenis.KEMBALI) == 1 and h2.jumlah(ReputationManager.Jenis.SETIA) == 0, "misi selesai di rumah berhenti (di luar rute): kembali aktif tanpa tanda setia")
	var c2: ReputationManager.Catatan = _catatan(9, [])
	c2.misi = _misi(true, sens, "sedang", true)
	var h3: ReputationManager.Hasil = _terapkan(_state({sens: _entri("berhenti", 3, 2, 2)}), c2)
	check(_e(h3, sens)["status"] == "setia" and h3.jumlah(ReputationManager.Jenis.KEMBALI) == 1 and h3.jumlah(ReputationManager.Jenis.SETIA) == 1, "misi setia di rumah berhenti: kembali lalu setia")
	var c3: ReputationManager.Catatan = _catatan(9, [[bias, true]])
	c3.misi = _misi(true, bias, "sedang", true)
	var h4: ReputationManager.Hasil = _terapkan(_state({}), c3)
	check(_e(h4, bias)["status"] == "setia" and _e(h4, bias)["antar"] == 1 and h4.jumlah(ReputationManager.Jenis.BARU) == 1, "misi setia di pelanggan rute yang baru: aktif dibuat lalu setia, antaran hari itu tetap dihitung")
	var c4: ReputationManager.Catatan = _catatan(9, [[bias, true]])
	c4.misi = _misi(true, lain, "sedang", true)
	var h5: ReputationManager.Hasil = _terapkan(_state({}), c4)
	check(not (h5.state["pelanggan"] as Dictionary).has(lain) and _e(h5, bias)["status"] == "aktif", "misi setia di rumah yang bukan pelanggan dan tanpa entri: tidak ada efek, tidak ada entri baru")
	var c5: ReputationManager.Catatan = _catatan(9, [])
	c5.misi = _misi(true, lain, "sedang", true)
	var h6: ReputationManager.Hasil = _terapkan(_state({lain: _entri("aktif", 1, 0)}), c5)
	check(_e(h6, lain)["status"] == "setia", "misi setia di rumah yang pernah jadi pelanggan (entri ada) tetapi tidak di rute hari ini: setia")
	var c6: ReputationManager.Catatan = _catatan(9, [])
	c6.misi = _misi(false, sens, "sedang", true, 1)
	var h7: ReputationManager.Hasil = _terapkan(_state({sens: _entri("berhenti", 3, 2, 2)}), c6)
	check(_e(h7, sens)["status"] == "berhenti" and h7.peristiwa.is_empty(), "misi gagal tidak mengubah status pelanggan")
	var c7: ReputationManager.Catatan = _catatan(9, [[sens, true]])
	c7.misi = _misi(true, sens, "kecil", false)
	var h8: ReputationManager.Hasil = _terapkan(_state({sens: _entri("berhenti", 3, 2, 2)}), c7)
	check(_e(h8, sens) == _entri("aktif", 0, 0, 0) and h8.jumlah(ReputationManager.Jenis.KEMBALI) == 1, "misi selesai + antaran di rumah berhenti yang sama: satu KEMBALI, penghitung 0 (tidak dihitung dua kali)")


# --- Reputasi ---

func _test_reputasi() -> void:
	_judul.call("Reputasi: kredit antaran per kualitas, dibagi 30 ke bawah, pagar harian, penjepitan 0..100 (O-8, AC-1)")
	var tepat: int = SkorRute.Kualitas.TEPAT
	var ids: Array = _per_kepribadian["biasa"]
	var cer_ids: Array = _per_kepribadian["cerewet"]
	# 7 tepat = 28 kredit -> 0; 8 tepat = 32 -> 1.
	var h7: ReputationManager.Hasil = _terapkan(_state({}, 10), _catatan(3, _daftar(ids, 7, tepat)))
	check(h7.kredit == 28 and h7.poin_antaran == 0 and h7.reputasi_sesudah == 10, "7 antaran tepat = 28 kredit = 0 poin (bulat ke bawah)")
	var h8: ReputationManager.Hasil = _terapkan(_state({}, 10), _catatan(3, _daftar(ids, 8, tepat)))
	check(h8.kredit == 32 and h8.poin_antaran == 1 and h8.reputasi_sesudah == 11 and h8.perubahan == 1, "8 antaran tepat = 32 kredit = +1")
	var h15: ReputationManager.Hasil = _terapkan(_state({}, 10), _catatan(3, _daftar(ids, 15, tepat)))
	check(h15.kredit == 60 and h15.poin_antaran == 2, "15 antaran tepat = 60 kredit = +2")
	# tiap kualitas
	var per_kualitas: Dictionary = {SkorRute.Kualitas.TEPAT: 4, SkorRute.Kualitas.TERAS: 3, SkorRute.Kualitas.KOTAK_SURAT: 2, SkorRute.Kualitas.HALAMAN: 1, SkorRute.Kualitas.JENDELA: 1}
	for q: int in per_kualitas:
		var hq: ReputationManager.Hasil = _terapkan(_state({}), _catatan(3, _daftar(ids, 2, q)))
		check(hq.kredit == 2 * int(per_kualitas[q]), "kredit kualitas %d per antaran = %d (dapat %d untuk dua)" % [q, per_kualitas[q], hq.kredit])
	# cerewet: halaman tanpa kredit, kualitas lain normal
	var hc: ReputationManager.Hasil = _terapkan(_state({}), _catatan(3, _daftar(cer_ids, 3, SkorRute.Kualitas.HALAMAN)))
	check(hc.kredit == 0, "cerewet: antaran halaman = 0 kredit")
	var hcb: ReputationManager.Hasil = _terapkan(_state({}), _catatan(3, _daftar(cer_ids, 3, SkorRute.Kualitas.TERAS)))
	check(hcb.kredit == 9, "cerewet: antaran teras tetap 3 kredit")
	var hbb: ReputationManager.Hasil = _terapkan(_state({}), _catatan(3, _daftar(ids, 3, SkorRute.Kualitas.HALAMAN)))
	check(hbb.kredit == 3, "biasa: antaran halaman 1 kredit")
	# tidak terantar tidak memberi kredit
	var htk: ReputationManager.Hasil = _terapkan(_state({}), _catatan(3, [[ids[0], false], [ids[1], false]]))
	check(htk.kredit == 0 and htk.perubahan == 0, "pelanggan tidak terantar tidak memberi kredit")
	# poin misi
	for pasangan: Array in [["kecil", 1], ["sedang", 2], ["besar", 3], ["tidak_ada", 0]]:
		var c: ReputationManager.Catatan = _catatan(3, [])
		c.misi = _misi(true, ids[0], pasangan[0])
		var hm: ReputationManager.Hasil = _terapkan(_state({}, 10), c)
		check(hm.poin_misi == pasangan[1] and hm.reputasi_sesudah == 10 + int(pasangan[1]), "misi selesai tingkat %s = +%d" % [pasangan[0], pasangan[1]])
	# misi gagal: gagal.reputasi 0 dan 1, dijepit di 1
	for gr: Array in [[0, 0], [1, 1], [5, 1], [-3, 0]]:
		var cg: ReputationManager.Catatan = _catatan(3, [])
		cg.misi = _misi(false, ids[0], "sedang", false, gr[0])
		var hg: ReputationManager.Hasil = _terapkan(_state({}, 10), cg)
		check(hg.turun_misi == gr[1] and hg.reputasi_sesudah == 10 - int(gr[1]), "misi gagal dengan gagal.reputasi %d = -%d" % [gr[0], gr[1]])
	# pagar harian
	var cp: ReputationManager.Catatan = _catatan(3, _daftar(ids, 30, tepat))
	cp.misi = _misi(true, ids[0], "besar")
	var hp: ReputationManager.Hasil = _terapkan(_state({}, 10), cp)
	check(hp.poin_antaran == 4 and hp.poin_misi == 3 and hp.naik == 6 and hp.perubahan == 6, "kenaikan satu hari dipagari 6 (4 + 3 -> 6)")
	# batas atas dan bawah
	var hatas: ReputationManager.Hasil = _terapkan(_state({}, 99), _catatan(3, _daftar(ids, 30, tepat)))
	check(hatas.reputasi_sesudah == 100 and hatas.perubahan == 1, "reputasi dijepit 100")
	var s_bawah: Dictionary = _state({_id("sensitif"): _entri("aktif", 0, 1), _id("sensitif", 1): _entri("aktif", 0, 1)}, 1)
	var hbawah: ReputationManager.Hasil = _terapkan(s_bawah, _catatan(3, [[_id("sensitif"), false], [_id("sensitif", 1), false]]))
	check(hbawah.reputasi_sesudah == 0 and hbawah.perubahan == -1, "reputasi dijepit 0 (1 - 2 = 0)")
	var hnol: ReputationManager.Hasil = _terapkan(_state({}, 0), _catatan(3, []))
	check(hnol.reputasi_sesudah == 0 and hnol.perubahan == 0, "tanpa kejadian reputasi tidak berubah")
	# distrik lain tidak tersentuh
	var s_lain: Dictionary = _state({}, 10)
	(s_lain["reputasi"] as Dictionary)["ruko"] = 33
	var hl: ReputationManager.Hasil = _terapkan(s_lain, _catatan(3, _daftar(ids, 8, tepat)))
	check((hl.state["reputasi"] as Dictionary)["ruko"] == 33 and (hl.state["reputasi"] as Dictionary)["perumahan"] == 11, "reputasi distrik lain tidak berubah")
	check(ReputationManager.reputasi_di({"reputasi": {"perumahan": 5000}}, "perumahan") == 100 and ReputationManager.reputasi_di({"reputasi": {"perumahan": -4}}, "perumahan") == 0 and ReputationManager.reputasi_di({}, "perumahan") == 0 and ReputationManager.reputasi_di({"reputasi": {"perumahan": "x"}}, "perumahan") == 0, "reputasi_di menjepit 0..100 dan menolak data aneh")


func _daftar(ids: Array, n: int, kualitas: int) -> Array:
	var daftar: Array = []
	for i: int in range(n):
		daftar.append([ids[i % ids.size()] + ("" if i < ids.size() else "#%d" % i), true, kualitas])
	return daftar


func _test_kemurnian() -> void:
	_judul.call("ReputationManager murni: masukan tidak diubah, hasil deterministik, field lain state sama (AC-1)")
	var ids: Array = _per_kepribadian["biasa"]
	var state: Dictionary = _state({ids[0]: _entri("aktif", 4, 0), _id("sensitif"): _entri("aktif", 0, 1)}, 20)
	var salinan: Dictionary = state.duplicate(true)
	var c: ReputationManager.Catatan = _catatan(5, [[ids[0], true, SkorRute.Kualitas.TEPAT], [_id("sensitif"), false], [ids[1], true]])
	c.misi = _misi(true, ids[0], "sedang", true)
	var h1: ReputationManager.Hasil = _terapkan(state, c)
	check(state == salinan, "state masukan tidak diubah")
	var h2: ReputationManager.Hasil = _terapkan(state, c)
	check(h1.state == h2.state and h1.peristiwa.size() == h2.peristiwa.size() and h1.perubahan == h2.perubahan, "masukan sama = hasil sama")
	var lain_sama: bool = true
	for k: String in state:
		if k != "reputasi" and k != "pelanggan" and h1.state[k] != state[k]:
			lain_sama = false
	check(lain_sama, "field state selain reputasi dan pelanggan sama")
	check(h1.reputasi_sesudah >= 0 and h1.reputasi_sesudah <= 100, "reputasi di 0..100")
	# fuzz: 500 hari acak
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 6020
	var s: Dictionary = DataSave.templat()
	var di_luar: int = 0
	var lonjak: int = 0
	var entri_rusak: int = 0
	for hari: int in range(1, 501):
		var daftar: Array = []
		for i: int in range(25):
			var id: String = _id_boleh[rng.randi_range(0, _id_boleh.size() - 1)]
			var ok: bool = rng.randf() < 0.7
			daftar.append([id, ok, rng.randi_range(0, 4) if ok else -1])
		var cf: ReputationManager.Catatan = _catatan(hari, daftar)
		if rng.randf() < 0.2:
			cf.misi = _misi(rng.randf() < 0.6, _id_boleh[rng.randi_range(0, _id_boleh.size() - 1)], ["kecil", "sedang", "besar"][rng.randi_range(0, 2)], rng.randf() < 0.5, rng.randi_range(0, 1))
		var hf: ReputationManager.Hasil = ReputationManager.terapkan(s, cf, _kep)
		s = hf.state
		var rep: int = ReputationManager.reputasi_di(s, "perumahan")
		if rep < 0 or rep > 100:
			di_luar += 1
		if hf.perubahan > 6:
			lonjak += 1
		for id: Variant in s["pelanggan"]:
			var e: Dictionary = s["pelanggan"][id]
			if not Config.PELANGGAN_STATUS.has(e["status"]) or int(e["antar"]) < 0 or int(e["meleset"]) < 0 or (e["status"] != "berhenti" and int(e["hari_berhenti"]) != 0) or (e["status"] == "berhenti" and int(e["hari_berhenti"]) < 1):
				entri_rusak += 1
	check(di_luar == 0 and lonjak == 0 and entri_rusak == 0, "fuzz 500 hari: reputasi selalu 0..100, kenaikan <= 6, entri pelanggan selalu sah (%d, %d, %d)" % [di_luar, lonjak, entri_rusak])


func _test_data_rusak_di_state() -> void:
	_judul.call("ReputationManager menerima entri state yang aneh tanpa crash")
	var bias: String = _id("biasa")
	var aneh: Dictionary = _state({bias: 5, _id("biasa", 1): {"status": "galak", "antar": "x", "meleset": -3}, _id("biasa", 2): {"status": "setia", "antar": 1.0e12}}, 10)
	var h: ReputationManager.Hasil = _terapkan(aneh, _catatan(4, [[bias, true], [_id("biasa", 1), true], [_id("biasa", 2), false]]))
	check(_e(h, bias) == _entri("aktif", 1, 0, 0) and h.jumlah(ReputationManager.Jenis.BARU) == 1, "entri bukan objek = rumah baru")
	check(_e(h, _id("biasa", 1))["status"] == "aktif" and _e(h, _id("biasa", 1))["antar"] == 1, "status asing dibaca aktif, penghitung teks/negatif dibaca 0")
	check(int(_e(h, _id("biasa", 2))["antar"]) <= Config.PELANGGAN_HITUNG_MAKS and _e(h, _id("biasa", 2))["status"] == "setia", "penghitung raksasa dijepit")
	var h2: ReputationManager.Hasil = ReputationManager.terapkan({}, _catatan(1, [[bias, true]]), _kep)
	check(_e(h2, bias)["antar"] == 1 and h2.reputasi_sebelum == 0, "state kosong tanpa field reputasi/pelanggan: dibuat dari awal")


func _test_catat_dari_rute() -> void:
	_judul.call("ReputationManager.catat: catatan dari rute, skor, dan keadaan misi nyata")
	var pustaka: Array[SegmenRute] = PemuatRute.muat_folder(FOLDER_RUTE).segmen
	var rute: RouteBuilder.Rute = RouteBuilder.bangun(SeedHari.rute(5), pustaka, 5).rute
	var skor: SkorRute.Keadaan = SkorRute.awal()
	var yang_kena: Array[String] = [rute.pelanggan[0].id, rute.pelanggan[3].id, rute.pelanggan[10].id]
	skor.terantar[yang_kena[0]] = true
	skor.kualitas[yang_kena[0]] = SkorRute.Kualitas.TEPAT
	skor.terantar[yang_kena[1]] = true
	skor.kualitas[yang_kena[1]] = SkorRute.Kualitas.TERAS
	skor.terantar[yang_kena[2]] = true
	skor.kualitas[yang_kena[2]] = SkorRute.Kualitas.HALAMAN
	skor.terantar["bukan@pelanggan"] = true
	var c: ReputationManager.Catatan = ReputationManager.catat(rute, skor, 5)
	check(c.hari == 5 and c.distrik == "perumahan" and c.rumah.size() == 25 and c.misi == null, "catatan: hari 5, perumahan, 25 pelanggan, tanpa misi")
	var urut_sama: bool = true
	var terantar: int = 0
	for i: int in range(25):
		if c.rumah[i].id != rute.pelanggan[i].id:
			urut_sama = false
		if c.rumah[i].terantar:
			terantar += 1
	check(urut_sama and terantar == 3, "urutan = pelanggan rute; hanya 3 yang terantar; rumah terantar di luar pelanggan rute diabaikan")
	check(c.rumah[0].kualitas == SkorRute.Kualitas.TEPAT and c.rumah[3].kualitas == SkorRute.Kualitas.TERAS and c.rumah[10].kualitas == SkorRute.Kualitas.HALAMAN and c.rumah[1].kualitas == -1, "kualitas tercatat per rumah, -1 untuk yang tidak terantar")
	# misi
	var misi: DataMisi = PemuatMisi.muat_folder().cari("p1_kucing")
	var rencana: RencanaMisi.Rencana = RencanaMisi.buat(misi, rute, SeedHari.misi(5))
	check(rencana.sah(), "rencana misi P1 sah di rute hari 5")
	var keadaan: MissionManager.Keadaan = MissionManager.awal(rencana)
	check(ReputationManager.catatan_misi(misi, keadaan) == null, "misi masih AKTIF = tanpa catatan misi")
	keadaan.status = MissionManager.Status.SELESAI
	var m: ReputationManager.CatatanMisi = ReputationManager.catatan_misi(misi, keadaan)
	check(m != null and m.selesai and not m.gagal and m.tingkat == "sedang" and m.setia and m.gagal_reputasi == 0 and m.id_rumah == rencana.titik[rencana.titik.size() - 1].id_rumah and m.id_misi == "p1_kucing", "misi selesai: tingkat sedang, hadiah pelanggan_setia, rumah titik tangkap terakhir")
	keadaan.status = MissionManager.Status.GAGAL
	var mg: ReputationManager.CatatanMisi = ReputationManager.catatan_misi(misi, keadaan)
	check(mg != null and mg.gagal and not mg.selesai, "misi gagal tercatat gagal")
	check(ReputationManager.catatan_misi(null, keadaan) == null and ReputationManager.catatan_misi(misi, null) == null, "tanpa data atau keadaan misi = tanpa catatan")


func _test_kualitas_skor() -> void:
	_judul.call("SkorRute mencatat kualitas antaran tanpa mengubah skor, koin, atau combo (pencatat saja)")
	var k: SkorRute.Keadaan = SkorRute.awal()
	var tepat: SkorRute.Hasil = SkorRute.nilai(k, ZonaSasaran.Hasil.KOTAK_SURAT, "a@1", true, 3.0, false, false)
	check(SkorRute.kualitas_rumah(tepat.keadaan, "a@1") == SkorRute.Kualitas.TEPAT, "kotak surat tepat = TEPAT")
	var kotak: SkorRute.Hasil = SkorRute.nilai(tepat.keadaan, ZonaSasaran.Hasil.KOTAK_SURAT, "b@1", false, 3.0, false, false)
	check(SkorRute.kualitas_rumah(kotak.keadaan, "b@1") == SkorRute.Kualitas.KOTAK_SURAT and SkorRute.kualitas_rumah(kotak.keadaan, "a@1") == SkorRute.Kualitas.TEPAT, "kotak surat biasa = KOTAK_SURAT; rumah lama tidak berubah")
	var teras: SkorRute.Hasil = SkorRute.nilai(kotak.keadaan, ZonaSasaran.Hasil.TERAS, "c@1", false, 3.0, true, false)
	var halaman: SkorRute.Hasil = SkorRute.nilai(teras.keadaan, ZonaSasaran.Hasil.HALAMAN, "d@1", false, 3.0, false, false)
	var jendela: SkorRute.Hasil = SkorRute.nilai(halaman.keadaan, ZonaSasaran.Hasil.JENDELA, "e@1", false, 3.0, false, true)
	check(SkorRute.kualitas_rumah(jendela.keadaan, "c@1") == SkorRute.Kualitas.TERAS and SkorRute.kualitas_rumah(jendela.keadaan, "d@1") == SkorRute.Kualitas.HALAMAN and SkorRute.kualitas_rumah(jendela.keadaan, "e@1") == SkorRute.Kualitas.JENDELA, "teras, halaman, jendela bonus tercatat")
	var ulang: SkorRute.Hasil = SkorRute.nilai(jendela.keadaan, ZonaSasaran.Hasil.HALAMAN, "a@1", false, 3.0, false, false)
	check(ulang.status == SkorRute.Status.ULANG and SkorRute.kualitas_rumah(ulang.keadaan, "a@1") == SkorRute.Kualitas.TEPAT, "koran ULANG tidak menimpa kualitas antaran pertama")
	var sia: SkorRute.Hasil = SkorRute.nilai(jendela.keadaan, ZonaSasaran.Hasil.MELESET, "", false, 3.0, false, false)
	check(sia.keadaan.kualitas == jendela.keadaan.kualitas and SkorRute.kualitas_rumah(sia.keadaan, "zzz") == -1, "TIDAK_SAH tidak mencatat kualitas; rumah belum terantar = -1")
	var salin: SkorRute.Keadaan = jendela.keadaan.salin()
	salin.kualitas["x@9"] = 0
	check(not jendela.keadaan.kualitas.has("x@9"), "salin Keadaan menyalin kualitas (bukan referensi yang sama)")
	# skor, koin, dan combo sama dengan rumus: 3 antaran pertama
	check(tepat.skor_tambah == 125 and tepat.koin_tambah == 15 and kotak.skor_tambah == 110 and teras.koin_tambah == 20 and jendela.keadaan.jumlah_antar == 5, "skor, koin, dan jumlah antaran tidak berubah oleh pencatatan kualitas (125 tepat, 110 combo 1,1, teras pemberi tip 20 koin)")


func _test_gagal_reputasi_misi() -> void:
	_judul.call("DataMisi: gagal.reputasi 0 atau 1, 'tidak pernah lebih berat' (O-8)")
	var data: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/missions/perumahan.json")) as Array)[0]
	var asli: DataMisi.Hasil = DataMisi.parse(data.duplicate(true))
	check(asli.sah() and asli.misi.gagal_reputasi() == 0, "P1 nyata sah dengan gagal.reputasi 0")
	for nilai: Variant in [0, 1, 1.0]:
		var d: Dictionary = data.duplicate(true)
		d["gagal"] = {"reputasi": nilai}
		var h: DataMisi.Hasil = DataMisi.parse(d)
		check(h.sah() and h.misi.gagal_reputasi() == int(nilai), "gagal.reputasi %s sah" % [str(nilai)])
	for nilai: Variant in [2, -1, 0.5, "satu", null, [1]]:
		var d2: Dictionary = data.duplicate(true)
		d2["gagal"] = {"reputasi": nilai}
		var h2: DataMisi.Hasil = DataMisi.parse(d2)
		check(not h2.sah() and ",".join(h2.galat).contains("gagal.reputasi"), "gagal.reputasi %s ditolak" % [str(nilai)])
	var d3: Dictionary = data.duplicate(true)
	d3["gagal"] = {}
	check(DataMisi.parse(d3).sah() and DataMisi.parse(d3).misi.gagal_reputasi() == 0, "gagal tanpa reputasi = 0")
	# Klem lapis kedua (QA-006): DataMisi dirakit tangan melewati validasi `parse`; nilai di luar 0..REPUTASI_MISI_GAGAL_MAKS dijepit, bukan bilangan = 0.
	check(Config.REPUTASI_MISI_GAGAL_MAKS == 1, "REPUTASI_MISI_GAGAL_MAKS = 1 (misi gagal tidak pernah lebih berat dari -1)")
	var rakit: DataMisi = asli.misi
	for pasangan: Array in [[5, 1], [2, 1], [1, 1], [0, 0], [-4, 0], [0.4, 0], [1.0, 1], ["x", 0], [null, 0]]:
		rakit.gagal = {"reputasi": pasangan[0]}
		check(rakit.gagal_reputasi() == pasangan[1], "rakitan tangan gagal.reputasi %s dijepit menjadi %d (dapat %d)" % [str(pasangan[0]), pasangan[1], rakit.gagal_reputasi()])


# --- AC-7: laju reputasi ---

func _test_laju_reputasi() -> void:
	_judul.call("Laju reputasi (K-3, AC-7): santai mencapai 40 antara hari 16 dan 24; tidak ada profil di bawah 0 atau melonjak > 6")
	var capai: Dictionary = {}
	for profil: String in SimEkonomi.PROFIL:
		var hari_capai: Array[int] = []
		for b: int in range(5):
			var h: SimEkonomi.Hasil = SimEkonomi.jalankan(profil, 40, 1000 + b * 37)
			hari_capai.append(h.hari_capai(40))
			check(h.hari.size() == 40, "%s benih %d: 40 hari berurutan disimulasikan" % [profil, b])
			check(h.reputasi_terkecil() >= 0 and h.perubahan_terbesar() <= 6, "%s benih %d: reputasi tidak di bawah 0 (%d) dan kenaikan harian <= 6 (%d)" % [profil, b, h.reputasi_terkecil(), h.perubahan_terbesar()])
			var naik_mentah_maks: int = 0
			for d: SimEkonomi.HariSim in h.hari:
				naik_mentah_maks = maxi(naik_mentah_maks, d.naik_mentah)
			check(naik_mentah_maks <= 6, "%s: kenaikan mentah (sebelum pagar) juga <= 6 di simulasi (%d)" % [profil, naik_mentah_maks])
		capai[profil] = hari_capai
	for hari: int in capai["santai"]:
		check(hari >= 16 and hari <= 24, "santai mencapai reputasi 40 pada hari %d (16 sampai 24)" % hari)
	var santai_maks: int = (capai["santai"] as Array[int]).max()
	for profil: String in ["campuran", "ngebut"]:
		for hari: int in capai[profil]:
			check(hari == 0 or hari >= (capai["santai"] as Array[int]).min(), "%s tidak lebih cepat dari santai (hari %d)" % [profil, hari])
	var campuran_lambat: bool = true
	for hari: int in capai["campuran"]:
		if hari != 0 and hari <= santai_maks - 4:
			campuran_lambat = false
	check(campuran_lambat, "campuran lebih lambat dari santai karena lebih sering meleset (asumsi akurasi), bukan karena rumus")
