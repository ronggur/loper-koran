class_name RouteBuilder
extends RefCounted
## Penyusun rute perumahan dari segmen JSON, murni dan deterministik (DATA_SCHEMA 3, ROUTE_DESIGN 1 dan 3, BALANCING 6; AC-5 sampai
## AC-7 run fase3a-rute, usulan). Semua acak dari `RandomNumberGenerator` yang diberi seed: seed sama = rute sama, tanpa `randi()`
## global, `Time`, atau scene tree (rule `gdscript`). Segmen masuk sebagai `SegmenRute` (dari `PemuatRute`), diurutkan menurut `id`
## dulu supaya urutan berkas tidak memengaruhi hasil.
##
## Langkah:
## 1. Segmen: satu `pembuka`, `RUTE_SEGMEN_PER_RUTE - RUTE_SEGMEN_PENGAPIT` segmen `tengah` berbeda, satu `penutup`, tanpa ulang. Urutan tengah dikocok
##    (Fisher-Yates dari RNG rute) sampai tidak ada dua segmen `padat` berurutan (ROUTE_DESIGN 5).
## 2. Rumah, rintangan, dan titik misi diberi posisi maju dari awal rute (awal segmen + `pos`). Id rumah `<id_segmen>@<pos>` (K-3).
## 3. Pelanggan: tepat `RUTE_PELANGGAN` rumah `seberang` yang `pelanggan_boleh`. Target posisi disebar rata dari kandidat pertama ke
##    terakhir dengan goyangan acak `RUTE_PELANGGAN_GOYANG_UBIN`; pencocokan berurutan terbaik (pemrograman dinamis, jumlah selisih
##    mutlak terkecil) memilih kandidat, jadi jarak rata-rata sekitar sebaran rata tetapi ada rumah berurutan lalu sela panjang
##    (ROUTE_DESIGN 3). Celah terpanjang dibatasi `RUTE_PELANGGAN_JARAK_MAKS_UBIN`; bila terlampaui, goyangan diundi ulang.
## 4. Koran awal = pelanggan + `RUTE_KORAN_CADANGAN_PERSEN` persen dibulatkan ke atas (`koran_awal`).


## Satu rumah di rute, dengan posisi maju dari awal rute.
class RumahRute extends RefCounted:
	## `<id_segmen>@<pos>` (K-3: pemetaan ke id save tetap ditunda ke Fase 6).
	var id: String = ""
	var id_segmen: String = ""
	## Ubin dari awal segmen (dari data).
	var pos: int = 0
	## Ubin dari awal rute sampai awal kavling rumah ini.
	var maju_ubin: float = 0.0
	var sisi: LoperAnim.Sisi = LoperAnim.Sisi.TIDAK_ADA
	## Bentuk rumah (`SegmenRute.JENIS_RUMAH_*`).
	var jenis: String = ""
	var pelanggan_boleh: bool = false
	## True bila rumah ini pelanggan rute ini (dipilih dari yang `pelanggan_boleh`).
	var pelanggan: bool = false


## Satu rintangan yang ditandai di rute (perilaku di Run 3B).
class ObjekRute extends RefCounted:
	var jenis: String = ""
	var id_segmen: String = ""
	## Ubin dari awal rute.
	var maju_ubin: float = 0.0
	## `seberang` atau `dekat`.
	var jalur: String = ""
	var tanda_ubin: float = 0.0


## Satu titik misi di rute.
class TitikMisiRute extends RefCounted:
	var nama: String = ""
	var id_segmen: String = ""
	## Ubin dari awal rute.
	var maju_ubin: float = 0.0
	var sisi: LoperAnim.Sisi = LoperAnim.Sisi.TIDAK_ADA


## Satu rute jadi.
class Rute extends RefCounted:
	var benih: int = 0
	## Segmen terpakai, urut dari awal ke akhir rute.
	var segmen: Array[SegmenRute] = []
	## Awal tiap segmen dari awal rute, ubin, sejajar dengan `segmen`.
	var awal_segmen: Array[float] = []
	## Panjang rute = garis akhir, ubin.
	var panjang_ubin: float = 0.0
	## Semua rumah kedua sisi, urut maju.
	var rumah: Array[RumahRute] = []
	var objek: Array[ObjekRute] = []
	var titik_misi: Array[TitikMisiRute] = []
	## Rumah pelanggan, urut maju.
	var pelanggan: Array[RumahRute] = []
	## Koran di awal rute (pelanggan + cadangan).
	var koran_awal: int = 0


## Hasil `bangun`: rute (null bila ada galat) dan daftar galat.
class Hasil extends RefCounted:
	var rute: Rute = null
	var galat: Array[String] = []

	func sah() -> bool:
		return galat.is_empty() and rute != null


## Susun satu rute dari `benih` dan `pustaka` segmen sah. Rute null dan galat terisi bila pustaka tidak cukup atau tidak ada susunan
## yang memenuhi aturan (tanpa dua `padat` berurutan, celah pelanggan, jumlah pelanggan).
static func bangun(benih: int, pustaka: Array[SegmenRute]) -> Hasil:
	var hasil: Hasil = Hasil.new()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = benih
	var urutan: Array[SegmenRute] = _susun_segmen(rng, pustaka, hasil.galat)
	if urutan.is_empty():
		return hasil
	var rute: Rute = Rute.new()
	rute.benih = benih
	_isi_segmen(rute, urutan)
	if not _pilih_pelanggan(rute, rng, hasil.galat):
		return hasil
	rute.koran_awal = koran_awal(rute.pelanggan.size())
	var salah: Array[String] = periksa_rute(rute)
	if not salah.is_empty():
		hasil.galat.append_array(salah)
		return hasil
	hasil.rute = rute
	return hasil


## Koran awal untuk `jumlah_pelanggan`: pelanggan + `RUTE_KORAN_CADANGAN_PERSEN` persen dibulatkan ke atas (BALANCING 4): 25 = 30.
static func koran_awal(jumlah_pelanggan: int) -> int:
	if jumlah_pelanggan <= 0:
		return 0
	return jumlah_pelanggan + ceili(float(jumlah_pelanggan * Config.RUTE_KORAN_CADANGAN_PERSEN) / float(Config.RUTE_KORAN_PERSEN_PENUH))


## Selisih maju antara pelanggan berturut-turut, ubin (jumlah pelanggan - 1 nilai).
static func jarak_pelanggan(rute: Rute) -> Array[float]:
	var hasil: Array[float] = []
	for i: int in range(1, rute.pelanggan.size()):
		hasil.append(rute.pelanggan[i].maju_ubin - rute.pelanggan[i - 1].maju_ubin)
	return hasil


## Rata-rata `jarak_pelanggan` (0 bila kurang dari dua pelanggan).
static func rata_jarak_pelanggan(rute: Rute) -> float:
	var jarak: Array[float] = jarak_pelanggan(rute)
	if jarak.is_empty():
		return 0.0
	var jumlah: float = 0.0
	for j: float in jarak:
		jumlah += j
	return jumlah / float(jarak.size())


## Pemeriksaan akhir sebuah rute (invarian AC-6 dan AC-7). Daftar galat kosong = sah.
static func periksa_rute(rute: Rute) -> Array[String]:
	var galat: Array[String] = []
	if rute.segmen.size() != Config.RUTE_SEGMEN_PER_RUTE:
		galat.append("rute berisi %d segmen, seharusnya %d" % [rute.segmen.size(), Config.RUTE_SEGMEN_PER_RUTE])
		return galat
	var terpakai: Dictionary = {}
	for i: int in range(rute.segmen.size()):
		var segmen: SegmenRute = rute.segmen[i]
		if terpakai.has(segmen.id):
			galat.append("segmen '%s' dipakai dua kali" % segmen.id)
		terpakai[segmen.id] = true
		var harapan: SegmenRute.Posisi = SegmenRute.Posisi.TENGAH
		if i == 0:
			harapan = SegmenRute.Posisi.PEMBUKA
		elif i == rute.segmen.size() - 1:
			harapan = SegmenRute.Posisi.PENUTUP
		if segmen.posisi != harapan:
			galat.append("segmen ke-%d ('%s') berposisi %s, seharusnya %s" % [i, segmen.id, SegmenRute.NAMA_POSISI[segmen.posisi], SegmenRute.NAMA_POSISI[harapan]])
		if i > 0 and segmen.tingkat == SegmenRute.Tingkat.PADAT and rute.segmen[i - 1].tingkat == SegmenRute.Tingkat.PADAT:
			galat.append("segmen padat berurutan: '%s' dan '%s'" % [rute.segmen[i - 1].id, segmen.id])
	if rute.pelanggan.size() != Config.RUTE_PELANGGAN:
		galat.append("pelanggan %d, seharusnya %d" % [rute.pelanggan.size(), Config.RUTE_PELANGGAN])
	var id_terlihat: Dictionary = {}
	for rumah: RumahRute in rute.rumah:
		if id_terlihat.has(rumah.id):
			galat.append("id rumah '%s' ganda" % rumah.id)
		id_terlihat[rumah.id] = true
	for pelanggan: RumahRute in rute.pelanggan:
		if pelanggan.sisi != LoperAnim.Sisi.SEBERANG or not pelanggan.pelanggan_boleh:
			galat.append("pelanggan '%s' bukan rumah seberang yang boleh" % pelanggan.id)
	var jarak: Array[float] = jarak_pelanggan(rute)
	for j: float in jarak:
		if j > Config.RUTE_PELANGGAN_JARAK_MAKS_UBIN:
			galat.append("celah antar pelanggan %.1f ubin melebihi %.1f" % [j, Config.RUTE_PELANGGAN_JARAK_MAKS_UBIN])
	var rintangan: Array[float] = []
	for objek: ObjekRute in rute.objek:
		rintangan.append(objek.maju_ubin)
	rintangan.sort()
	for i: int in range(1, rintangan.size()):
		if rintangan[i] - rintangan[i - 1] < float(Config.RUTE_RINTANGAN_JENDELA_UBIN):
			galat.append("dua rintangan %.1f ubin berdekatan (di %.1f dan %.1f)" % [rintangan[i] - rintangan[i - 1], rintangan[i - 1], rintangan[i]])
	return galat


# --- Langkah penyusunan ---

## Pustaka dikelompokkan per posisi (diurutkan menurut id), lalu urutan 7 segmen diundi sampai sah. Kosong + galat bila gagal.
static func _susun_segmen(rng: RandomNumberGenerator, pustaka: Array[SegmenRute], galat: Array[String]) -> Array[SegmenRute]:
	var kosong: Array[SegmenRute] = []
	var terurut: Array[SegmenRute] = []
	for segmen: SegmenRute in pustaka:
		terurut.append(segmen)
	terurut.sort_custom(func(a: SegmenRute, b: SegmenRute) -> bool: return a.id < b.id)
	var pembuka: Array[SegmenRute] = []
	var tengah: Array[SegmenRute] = []
	var penutup: Array[SegmenRute] = []
	for segmen: SegmenRute in terurut:
		match segmen.posisi:
			SegmenRute.Posisi.PEMBUKA:
				pembuka.append(segmen)
			SegmenRute.Posisi.PENUTUP:
				penutup.append(segmen)
			_:
				tengah.append(segmen)
	var perlu_tengah: int = Config.RUTE_SEGMEN_PER_RUTE - Config.RUTE_SEGMEN_PENGAPIT
	if pembuka.is_empty() or penutup.is_empty() or tengah.size() < perlu_tengah:
		galat.append("pustaka tidak cukup: pembuka %d, tengah %d (butuh %d), penutup %d" % [pembuka.size(), tengah.size(), perlu_tengah, penutup.size()])
		return kosong
	for percobaan: int in range(Config.RUTE_SUSUN_PERCOBAAN_MAKS):
		var urutan: Array[SegmenRute] = []
		urutan.append(pembuka[rng.randi_range(0, pembuka.size() - 1)])
		var kocok: Array[SegmenRute] = _kocok(rng, tengah)
		for i: int in range(perlu_tengah):
			urutan.append(kocok[i])
		urutan.append(penutup[rng.randi_range(0, penutup.size() - 1)])
		if _tanpa_padat_berurutan(urutan):
			return urutan
	galat.append("tidak ada susunan tanpa dua segmen padat berurutan dalam %d percobaan" % Config.RUTE_SUSUN_PERCOBAAN_MAKS)
	return kosong


## Salinan `daftar` yang dikocok Fisher-Yates dari `rng` (bukan `Array.shuffle`, yang memakai RNG global).
static func _kocok(rng: RandomNumberGenerator, daftar: Array[SegmenRute]) -> Array[SegmenRute]:
	var hasil: Array[SegmenRute] = []
	for segmen: SegmenRute in daftar:
		hasil.append(segmen)
	for i: int in range(hasil.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var simpan: SegmenRute = hasil[i]
		hasil[i] = hasil[j]
		hasil[j] = simpan
	return hasil


static func _tanpa_padat_berurutan(urutan: Array[SegmenRute]) -> bool:
	for i: int in range(1, urutan.size()):
		if urutan[i].tingkat == SegmenRute.Tingkat.PADAT and urutan[i - 1].tingkat == SegmenRute.Tingkat.PADAT:
			return false
	return true


## Isi segmen, awal tiap segmen, panjang, rumah, rintangan, dan titik misi dengan posisi maju dari awal rute.
static func _isi_segmen(rute: Rute, urutan: Array[SegmenRute]) -> void:
	var awal: float = 0.0
	for segmen: SegmenRute in urutan:
		rute.segmen.append(segmen)
		rute.awal_segmen.append(awal)
		for r: SegmenRute.Rumah in segmen.rumah:
			var rumah: RumahRute = RumahRute.new()
			rumah.id = "%s@%d" % [segmen.id, r.pos]
			rumah.id_segmen = segmen.id
			rumah.pos = r.pos
			rumah.maju_ubin = awal + float(r.pos)
			rumah.sisi = r.sisi
			rumah.jenis = r.jenis
			rumah.pelanggan_boleh = r.pelanggan_boleh
			rute.rumah.append(rumah)
		for o: SegmenRute.Objek in segmen.objek:
			var objek: ObjekRute = ObjekRute.new()
			objek.jenis = o.jenis
			objek.id_segmen = segmen.id
			objek.maju_ubin = awal + float(o.pos)
			objek.jalur = o.jalur
			objek.tanda_ubin = o.tanda_ubin
			rute.objek.append(objek)
		for t: SegmenRute.TitikMisi in segmen.titik_misi:
			var titik: TitikMisiRute = TitikMisiRute.new()
			titik.nama = t.nama
			titik.id_segmen = segmen.id
			titik.maju_ubin = awal + float(t.pos)
			titik.sisi = t.sisi
			rute.titik_misi.append(titik)
		awal += float(segmen.panjang)
	rute.panjang_ubin = awal
	rute.rumah.sort_custom(_lebih_awal)
	rute.objek.sort_custom(func(a: ObjekRute, b: ObjekRute) -> bool: return a.maju_ubin < b.maju_ubin)
	rute.titik_misi.sort_custom(func(a: TitikMisiRute, b: TitikMisiRute) -> bool: return a.maju_ubin < b.maju_ubin if a.maju_ubin != b.maju_ubin else a.nama < b.nama)


static func _lebih_awal(a: RumahRute, b: RumahRute) -> bool:
	if a.maju_ubin != b.maju_ubin:
		return a.maju_ubin < b.maju_ubin
	return a.id < b.id


## Pilih tepat `RUTE_PELANGGAN` pelanggan dari rumah seberang yang boleh. False + galat bila kandidat kurang atau celah tak bisa dipenuhi.
static func _pilih_pelanggan(rute: Rute, rng: RandomNumberGenerator, galat: Array[String]) -> bool:
	var kandidat: Array[RumahRute] = []
	for rumah: RumahRute in rute.rumah:
		if rumah.sisi == LoperAnim.Sisi.SEBERANG and rumah.pelanggan_boleh:
			kandidat.append(rumah)
	var jumlah: int = Config.RUTE_PELANGGAN
	if kandidat.size() < jumlah:
		galat.append("kandidat pelanggan %d kurang dari %d" % [kandidat.size(), jumlah])
		return false
	var maju: PackedFloat64Array = PackedFloat64Array()
	for rumah: RumahRute in kandidat:
		maju.append(rumah.maju_ubin)
	for percobaan: int in range(Config.RUTE_SUSUN_PERCOBAAN_MAKS):
		var indeks: PackedInt32Array = _cocokkan(maju, jumlah, rng)
		if indeks.size() != jumlah:
			break
		var celah_sah: bool = true
		for i: int in range(1, jumlah):
			if maju[indeks[i]] - maju[indeks[i - 1]] > Config.RUTE_PELANGGAN_JARAK_MAKS_UBIN:
				celah_sah = false
		if not celah_sah:
			continue
		for i: int in indeks:
			kandidat[i].pelanggan = true
			rute.pelanggan.append(kandidat[i])
		return true
	galat.append("tidak ada pilihan pelanggan dengan celah di bawah %.1f ubin dalam %d percobaan" % [Config.RUTE_PELANGGAN_JARAK_MAKS_UBIN, Config.RUTE_SUSUN_PERCOBAAN_MAKS])
	return false


## Pilih `jumlah` indeks dari `maju` (terurut menaik) yang paling dekat ke target tersebar rata + goyangan acak: pencocokan berurutan
## dengan jumlah selisih mutlak terkecil (DP O(jumlah x n)); seri = indeks lebih kecil. Kosong bila n < jumlah.
static func _cocokkan(maju: PackedFloat64Array, jumlah: int, rng: RandomNumberGenerator) -> PackedInt32Array:
	var hasil: PackedInt32Array = PackedInt32Array()
	var n: int = maju.size()
	if n < jumlah or jumlah <= 0:
		return hasil
	var target: PackedFloat64Array = PackedFloat64Array()
	var awal: float = maju[0]
	var akhir: float = maju[n - 1]
	for i: int in range(jumlah):
		var dasar: float = (awal + akhir) / 2
		if jumlah > 1:
			dasar = awal + (akhir - awal) * float(i) / float(jumlah - 1)
		target.append(dasar + rng.randf_range(-Config.RUTE_PELANGGAN_GOYANG_UBIN, Config.RUTE_PELANGGAN_GOYANG_UBIN))
	var biaya: PackedFloat64Array = PackedFloat64Array()
	biaya.resize(jumlah * n)
	var asal: PackedInt32Array = PackedInt32Array()
	asal.resize(jumlah * n)
	for i: int in range(jumlah):
		var terbaik: float = INF
		var idx_terbaik: int = -1
		for j: int in range(n):
			if i > 0 and j > 0:
				var sebelum: float = biaya[(i - 1) * n + (j - 1)]
				if sebelum < terbaik:
					terbaik = sebelum
					idx_terbaik = j - 1
			var selisih: float = absf(maju[j] - target[i])
			if i == 0:
				biaya[i * n + j] = selisih
				asal[i * n + j] = -1
			elif idx_terbaik >= 0:
				biaya[i * n + j] = terbaik + selisih
				asal[i * n + j] = idx_terbaik
			else:
				biaya[i * n + j] = INF
				asal[i * n + j] = -1
	var akhir_j: int = -1
	var biaya_akhir: float = INF
	for j: int in range(n):
		if biaya[(jumlah - 1) * n + j] < biaya_akhir:
			biaya_akhir = biaya[(jumlah - 1) * n + j]
			akhir_j = j
	if akhir_j < 0:
		return hasil
	hasil.resize(jumlah)
	var j_sekarang: int = akhir_j
	for i: int in range(jumlah - 1, -1, -1):
		hasil[i] = j_sekarang
		j_sekarang = asal[i * n + j_sekarang]
	return hasil
