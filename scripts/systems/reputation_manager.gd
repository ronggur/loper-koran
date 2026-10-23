class_name ReputationManager
extends RefCounted
## Reputasi per distrik dan status pelanggan tetap, logika murni (GDD 8 dan 10.5, TECH_PLAN Fase 6A; O-4 sampai O-8, AC-1 dan AC-2 run fase6a2-reputasi-pelanggan, usulan).
## Satu fungsi utama, `terapkan`: state save + catatan pelanggan SATU hari -> state baru (`reputasi`, `pelanggan`) dan daftar peristiwa. Masukan tidak diubah, tanpa node, `Time`, atau RNG,
## jadi hasil sama untuk masukan sama. Dipanggil sekali per hari: layar hasil menampilkannya (`RuteMain`) dan `DataSave.catat_hari` menerapkannya ke save.
##
## Status (`state["pelanggan"][id_rumah]` = {status, antar, meleset, hari_berhenti}); rumah tanpa entri = "baru":
## - Tiga tahap per hari: (1) rumah pelanggan rute yang belum punya entri dibuat `aktif` (peristiwa BARU); (2) misi selesai: rumah titik tangkap yang `berhenti` kembali `aktif`
##   (KEMBALI), dan bila hadiah misi bertanda `pelanggan_setia` rumah itu (yang sudah punya entri) menjadi `setia` (SETIA); (3) tiap pelanggan rute: terantar = `antar` + 1 dan `meleset` 0
##   (`berhenti` yang terantar kembali `aktif` dengan `antar` dan `meleset` 0), tidak terantar = `meleset` + 1.
## - `aktif` -> `setia` bila `antar` >= `PELANGGAN_SETIA_ANTAR`. Hanya kepribadian `sensitif` bisa `berhenti`: `meleset` >= `PELANGGAN_BERHENTI_MELESET` (setia: `PELANGGAN_SETIA_BERHENTI_MELESET`)
##   mencatat `hari_berhenti`. Pelanggan yang tidak masuk rute hari itu tidak berubah. "Meleset" di sini = pelanggan rute tidak terantar (bukan potongan koran terbuang).
## Reputasi (0..100): kredit antaran (tepat 4, teras 3, kotak surat 2, halaman 1; `cerewet` tidak memberi kredit halaman) dibagi `REPUTASI_KREDIT_PER_POIN` (bulat ke bawah), ditambah poin misi
## selesai (kecil 1, sedang 2, besar 3) dan dijepit `REPUTASI_NAIK_MAKS_PER_HARI`, dikurangi `gagal.reputasi` misi gagal dan `REPUTASI_BERHENTI_POIN` per pelanggan yang berhenti hari itu.
## Tabrakan dan kondisi sepeda tidak memengaruhi reputasi. Reputasi belum memengaruhi pendapatan di 6A2.

enum Jenis { BARU, SETIA, BERHENTI, KEMBALI }


## Satu pelanggan rute hari ini.
class CatatanRumah extends RefCounted:
	var id: String = ""
	var terantar: bool = false
	## `SkorRute.Kualitas` sebagai bilangan bulat, -1 bila tidak terantar atau tidak tercatat.
	var kualitas: int = -1


## Hasil misi hari ini yang berarti bagi reputasi dan pelanggan.
class CatatanMisi extends RefCounted:
	var id_misi: String = ""
	var selesai: bool = false
	var gagal: bool = false
	## Tingkat hadiah (`Config.MISI_TINGKAT_HADIAH`).
	var tingkat: String = ""
	## Hadiah bertanda `pelanggan_setia` (data misi `hadiah.tambahan`).
	var setia: bool = false
	## Rumah titik tangkap (langkah terakhir rencana).
	var id_rumah: String = ""
	## `gagal.reputasi` data misi, poin yang hilang bila gagal.
	var gagal_reputasi: int = 0


## Catatan pelanggan satu hari: masukan `terapkan`.
class Catatan extends RefCounted:
	var hari: int = Config.HARI_AWAL
	var distrik: String = Config.DISTRIK_AWAL
	var rumah: Array[CatatanRumah] = []
	var misi: CatatanMisi = null


## Satu peristiwa pelanggan hari ini.
class Peristiwa extends RefCounted:
	var jenis: Jenis = Jenis.BARU
	var id_rumah: String = ""


## Hasil `terapkan`.
class Hasil extends RefCounted:
	## Salinan state masukan dengan `reputasi` dan `pelanggan` yang diperbarui (field lain sama).
	var state: Dictionary = {}
	var peristiwa: Array[Peristiwa] = []
	var reputasi_sebelum: int = 0
	var reputasi_sesudah: int = 0
	## `reputasi_sesudah - reputasi_sebelum` (sesudah penjepitan 0..100).
	var perubahan: int = 0
	## Rincian: kredit antaran hari ini, poin dari kredit, poin misi, kenaikan (sesudah pagar harian), pengurangan misi gagal dan pelanggan berhenti.
	var kredit: int = 0
	var poin_antaran: int = 0
	var poin_misi: int = 0
	var naik: int = 0
	var turun_misi: int = 0
	var turun_berhenti: int = 0

	## Jumlah peristiwa jenis `jenis`.
	func jumlah(jenis: Jenis) -> int:
		var n: int = 0
		for p: Peristiwa in peristiwa:
			if p.jenis == jenis:
				n += 1
		return n


## Catatan hari `hari` dari rute `rute`, skor `skor`, data misi `misi` (null = tanpa misi) dan keadaan misi `keadaan` (null atau masih AKTIF = tidak ada hasil misi).
static func catat(rute: RouteBuilder.Rute, skor: SkorRute.Keadaan, hari: int, misi: DataMisi = null, keadaan: MissionManager.Keadaan = null) -> Catatan:
	var c: Catatan = Catatan.new()
	c.hari = hari
	if rute != null:
		for rumah: RouteBuilder.RumahRute in rute.pelanggan:
			var r: CatatanRumah = CatatanRumah.new()
			r.id = rumah.id
			r.terantar = skor != null and skor.terantar.has(rumah.id)
			r.kualitas = SkorRute.kualitas_rumah(skor, rumah.id) if r.terantar else -1
			c.rumah.append(r)
	c.misi = catatan_misi(misi, keadaan)
	return c


## Catatan misi dari data dan keadaan misi; null bila tanpa misi, rencana tidak sah, atau misi masih aktif.
static func catatan_misi(misi: DataMisi, keadaan: MissionManager.Keadaan) -> CatatanMisi:
	if misi == null or keadaan == null or keadaan.rencana == null or not keadaan.rencana.sah() or keadaan.status == MissionManager.Status.AKTIF:
		return null
	var m: CatatanMisi = CatatanMisi.new()
	m.id_misi = misi.id
	m.selesai = keadaan.status == MissionManager.Status.SELESAI
	m.gagal = keadaan.status == MissionManager.Status.GAGAL
	m.tingkat = str(misi.hadiah.get("tingkat", ""))
	m.setia = str(misi.hadiah.get("tambahan", "")) == "pelanggan_setia"
	m.id_rumah = keadaan.rencana.titik[keadaan.rencana.titik.size() - 1].id_rumah
	m.gagal_reputasi = misi.gagal_reputasi()
	return m


## Kredit satu antaran sah berkualitas `kualitas` (`SkorRute.Kualitas`, -1 = tidak tercatat dihitung kotak surat) di rumah berkepribadian `kepribadian`.
static func kredit_antaran(kualitas: int, kepribadian: String) -> int:
	match kualitas:
		SkorRute.Kualitas.TEPAT:
			return Config.REPUTASI_KREDIT_TEPAT
		SkorRute.Kualitas.TERAS:
			return Config.REPUTASI_KREDIT_TERAS
		SkorRute.Kualitas.HALAMAN:
			return 0 if kepribadian == KepribadianPelanggan.CEREWET else Config.REPUTASI_KREDIT_HALAMAN
		SkorRute.Kualitas.JENDELA:
			return Config.REPUTASI_KREDIT_HALAMAN
	return Config.REPUTASI_KREDIT_KOTAK_SURAT


## Poin reputasi misi selesai menurut tingkat (0 bila tingkat tidak dikenal).
static func poin_misi(tingkat: String) -> int:
	var i: int = Config.MISI_TINGKAT_HADIAH.find(tingkat)
	return Config.REPUTASI_MISI_POIN[i] if i >= 0 else 0


## Reputasi distrik `distrik` di state (dijepit 0..100; hilang atau bukan angka = `REPUTASI_AWAL`).
static func reputasi_di(state: Dictionary, distrik: String) -> int:
	var peta: Variant = state.get("reputasi")
	if typeof(peta) != TYPE_DICTIONARY:
		return Config.REPUTASI_AWAL
	var nilai: Variant = (peta as Dictionary).get(distrik, Config.REPUTASI_AWAL)
	if not ParseData.angka(nilai):
		return Config.REPUTASI_AWAL
	return clampi(int(nilai), Config.REPUTASI_MIN, Config.REPUTASI_MAKS)


## Terapkan catatan `catatan` ke state `state` (tidak diubah) dengan pustaka kepribadian `pustaka`. Lihat dokumentasi kelas.
static func terapkan(state: Dictionary, catatan: Catatan, pustaka: Array[KepribadianPelanggan.Entri]) -> Hasil:
	var hasil: Hasil = Hasil.new()
	var baru: Dictionary = state.duplicate(true)
	var peta: Dictionary = {}
	if typeof(baru.get("pelanggan")) == TYPE_DICTIONARY:
		peta = baru["pelanggan"]
	var reputasi: Dictionary = {}
	if typeof(baru.get("reputasi")) == TYPE_DICTIONARY:
		reputasi = baru["reputasi"]
	hasil.reputasi_sebelum = reputasi_di(state, catatan.distrik)
	var diproses: Dictionary = {}
	var rumah_hari: Array[CatatanRumah] = []
	for r: CatatanRumah in catatan.rumah:
		if r.id.is_empty() or diproses.has(r.id):
			continue
		diproses[r.id] = true
		rumah_hari.append(r)
	# Tahap 1: pelanggan baru.
	for r: CatatanRumah in rumah_hari:
		if _entri(peta, r.id).is_empty():
			peta[r.id] = _entri_baru()
			_catat(hasil, Jenis.BARU, r.id)
	# Tahap 2: misi selesai.
	var kembali_hari: Dictionary = {}
	var m: CatatanMisi = catatan.misi
	if m != null and m.selesai and not m.id_rumah.is_empty():
		var e: Dictionary = _entri(peta, m.id_rumah)
		if not e.is_empty():
			if e["status"] == PelangganRute.BERHENTI:
				_kembalikan(e)
				kembali_hari[m.id_rumah] = true
				_catat(hasil, Jenis.KEMBALI, m.id_rumah)
			if m.setia and e["status"] != PelangganRute.SETIA:
				e["status"] = PelangganRute.SETIA
				_catat(hasil, Jenis.SETIA, m.id_rumah)
			peta[m.id_rumah] = e
	# Tahap 3: antaran dan meleset tiap pelanggan rute.
	var kredit: int = 0
	var berhenti_hari: int = 0
	for r: CatatanRumah in rumah_hari:
		var e: Dictionary = _entri(peta, r.id)
		var kepribadian: String = KepribadianPelanggan.dari_id(r.id, pustaka)
		if r.terantar:
			kredit += kredit_antaran(r.kualitas, kepribadian)
		if kembali_hari.has(r.id):
			peta[r.id] = e
			continue
		if r.terantar:
			if e["status"] == PelangganRute.BERHENTI:
				_kembalikan(e)
				_catat(hasil, Jenis.KEMBALI, r.id)
			else:
				e["antar"] = mini(int(e["antar"]) + 1, Config.PELANGGAN_HITUNG_MAKS)
				e["meleset"] = 0
				if e["status"] == PelangganRute.AKTIF and int(e["antar"]) >= Config.PELANGGAN_SETIA_ANTAR:
					e["status"] = PelangganRute.SETIA
					_catat(hasil, Jenis.SETIA, r.id)
		elif e["status"] != PelangganRute.BERHENTI:
			e["meleset"] = mini(int(e["meleset"]) + 1, Config.PELANGGAN_HITUNG_MAKS)
			var batas: int = Config.PELANGGAN_SETIA_BERHENTI_MELESET if e["status"] == PelangganRute.SETIA else Config.PELANGGAN_BERHENTI_MELESET
			if kepribadian == KepribadianPelanggan.SENSITIF and int(e["meleset"]) >= batas:
				e["status"] = PelangganRute.BERHENTI
				e["hari_berhenti"] = clampi(catatan.hari, Config.HARI_AWAL, Config.SAVE_ANGKA_MAKS)
				berhenti_hari += 1
				_catat(hasil, Jenis.BERHENTI, r.id)
		peta[r.id] = e
	# Reputasi.
	hasil.kredit = kredit
	hasil.poin_antaran = floori(float(kredit) / float(Config.REPUTASI_KREDIT_PER_POIN))
	if m != null and m.selesai:
		hasil.poin_misi = poin_misi(m.tingkat)
	hasil.naik = mini(hasil.poin_antaran + hasil.poin_misi, Config.REPUTASI_NAIK_MAKS_PER_HARI)
	if m != null and m.gagal:
		hasil.turun_misi = clampi(m.gagal_reputasi, 0, Config.REPUTASI_MISI_GAGAL_MAKS)
	hasil.turun_berhenti = berhenti_hari * Config.REPUTASI_BERHENTI_POIN
	hasil.reputasi_sesudah = clampi(hasil.reputasi_sebelum + hasil.naik - hasil.turun_misi - hasil.turun_berhenti, Config.REPUTASI_MIN, Config.REPUTASI_MAKS)
	hasil.perubahan = hasil.reputasi_sesudah - hasil.reputasi_sebelum
	reputasi[catatan.distrik] = hasil.reputasi_sesudah
	baru["reputasi"] = reputasi
	baru["pelanggan"] = peta
	hasil.state = baru
	return hasil


# --- Pembantu ---

static func _entri_baru() -> Dictionary:
	return {"status": PelangganRute.AKTIF, "antar": 0, "meleset": 0, "hari_berhenti": 0}


## Entri rumah `id` yang dirapikan (status sah, penghitung bulat >= 0), atau kamus kosong bila tidak ada atau bukan kamus.
static func _entri(peta: Dictionary, id: String) -> Dictionary:
	if not peta.has(id) or typeof(peta[id]) != TYPE_DICTIONARY:
		return {}
	var d: Dictionary = peta[id]
	var status: Variant = d.get("status")
	var hitung: Callable = func(kunci: String, atas: int) -> int:
		var v: Variant = d.get(kunci, 0)
		return clampi(int(v), 0, atas) if ParseData.angka(v) else 0
	return {
		"status": str(status) if typeof(status) == TYPE_STRING and Config.PELANGGAN_STATUS.has(status) else PelangganRute.AKTIF,
		"antar": hitung.call("antar", Config.PELANGGAN_HITUNG_MAKS),
		"meleset": hitung.call("meleset", Config.PELANGGAN_HITUNG_MAKS),
		"hari_berhenti": hitung.call("hari_berhenti", Config.SAVE_ANGKA_MAKS),
	}


## Pelanggan `berhenti` kembali `aktif`: `antar`, `meleset`, dan `hari_berhenti` direset 0.
static func _kembalikan(e: Dictionary) -> void:
	e["status"] = PelangganRute.AKTIF
	e["antar"] = 0
	e["meleset"] = 0
	e["hari_berhenti"] = 0


static func _catat(hasil: Hasil, jenis: Jenis, id_rumah: String) -> void:
	var p: Peristiwa = Peristiwa.new()
	p.jenis = jenis
	p.id_rumah = id_rumah
	hasil.peristiwa.append(p)
