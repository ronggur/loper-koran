class_name HeadlineManager
extends RefCounted
## Pemilih tiga headline halaman depan koran, logika murni (GDD 10.1 dan 10.3, TECH_PLAN Fase 4, DATA_SCHEMA 2; AC-5 dan AC-6 run
## fase4a-koran-hari, usulan). `susun` menerima `Masukan` (hari, distrik, flag, riwayat jeda, pustaka headline dan misi, benih dasar) dan
## mengembalikan `Halaman`: `utama` (dengan `efek`), `misi` (headline + id misi, atau null = tanpa misi yang memenuhi syarat, S-8), dan `ringan`.
## Acak hanya dari `RandomNumberGenerator` berseed hari (`SeedHari.campur(benih_dasar, hari)`), satu aliran per slot (utama, misi, ringan) supaya
## adanya lanjutan di satu slot tidak mengubah undian slot lain: masukan sama = halaman sama persis. Tanpa node, `Time`, atau `randi()` global.
## Masukan tidak diubah.
##
## Aturan:
## - Kandidat harus `aktif`, cocok `distrik` (kosong = semua), memenuhi `syarat` (flag, hari_min, hari_maks, dan untuk misi berita_utama), dan
##   tidak dalam jeda: `headline_jeda[id]` / `misi_jeda[id]` = hari pertama boleh muncul lagi (S-4), kandidat boleh bila `hari` >= nilainya.
##   Misi memakai jeda sejak hari DIAMBIL, headline sejak hari DITAMPILKAN (`catat_jeda`).
## - Lanjutan diprioritaskan: headline `lanjutan` yang `syarat.flag`-nya ada di flag menempati slotnya (`misi` atau `ringan`) sebelum undian biasa.
##   Flag yang tidak dikenal data diabaikan tanpa galat.
## - Undian berbobot `bobot`. Bila SEMUA kandidat headline ada dalam jeda, dipilih yang jedanya paling cepat berakhir (nilai `*_jeda` terkecil;
##   seri: urutan pustaka), bukan galat. Slot misi tidak punya cadangan seperti itu: misi dalam jeda tidak dipilih, tanpa kandidat = slot kosong.
## - Hari `MISI_HARI_TUTORIAL`: slot misi = `MISI_ID_TUTORIAL` (tutorial STORY 6, P1 kucing Bu Ratmi) kecuali ada lanjutan yang memegang slot itu.
## - Efek berita utama hanya dicatat (S-5); tidak diterapkan di 4A.

## Slot halaman: urutan menentukan aliran acak dan selisih seed.
enum Slot { UTAMA, MISI, RINGAN }


## Masukan `susun`.
class Masukan extends RefCounted:
	var hari: int = Config.HARI_AWAL
	var distrik: String = Config.DISTRIK_AWAL
	var flag: Array[String] = []
	## Id headline -> hari pertama boleh muncul lagi.
	var headline_jeda: Dictionary = {}
	## Id misi -> hari pertama boleh muncul lagi.
	var misi_jeda: Dictionary = {}
	var pustaka: PemuatHeadline.Pustaka = null
	var misi: Array[DataMisi] = []
	var benih_dasar: int = Config.SEED_HEADLINE_DASAR
	var reputasi: int = Config.REPUTASI_BAWAAN


## Satu baris halaman.
class Entri extends RefCounted:
	## Id headline (utama, ringan, lanjutan) atau id misi (jenis `misi`).
	var id: String = ""
	## `utama`, `ringan`, `lanjutan`, atau `misi`.
	var jenis: String = ""
	## Kunci terjemahan teks headline.
	var teks: String = ""
	## Kunci terjemahan ringkasan satu baris (hanya baris misi dengan misi).
	var ringkasan: String = ""
	## Kunci efek dunia (hanya berita utama); di 4A hanya dicatat.
	var efek: String = ""
	## Id misi yang bisa diambil di baris ini ("" = baris tanpa tombol Ambil/Lewati).
	var misi_id: String = ""
	## Jeda headline (hari) bila jenisnya headline.
	var jeda: int = 0
	## Jeda misi (hari) bila `misi_id` diambil.
	var jeda_misi: int = 0


## Tiga baris halaman depan hari `hari`; tiap baris bisa null (pool kosong, S-8).
class Halaman extends RefCounted:
	var hari: int = Config.HARI_AWAL
	var utama: Entri = null
	var misi: Entri = null
	var ringan: Entri = null

	## Daftar id headline dan misi yang tampil (urut utama, misi, ringan), untuk perbandingan dan tes.
	func daftar_id() -> Array[String]:
		var hasil: Array[String] = []
		for e: Entri in [utama, misi, ringan]:
			hasil.append(e.id if e != null else "")
		return hasil


## Jeda yang dicatat dari satu halaman (S-4): `headline` (id -> hari pertama boleh lagi) dan `misi`.
class JedaBaru extends RefCounted:
	var headline: Dictionary = {}
	var misi: Dictionary = {}


## Menyusun halaman depan koran untuk `masukan`.
static func susun(masukan: Masukan) -> Halaman:
	var halaman: Halaman = Halaman.new()
	halaman.hari = masukan.hari
	var pustaka: PemuatHeadline.Pustaka = masukan.pustaka if masukan.pustaka != null else PemuatHeadline.Pustaka.new()
	var dasar: int = SeedHari.campur(masukan.benih_dasar, masukan.hari)
	halaman.utama = _susun_utama(masukan, pustaka, _rng(dasar, Slot.UTAMA))
	var efek: String = halaman.utama.efek if halaman.utama != null else ""
	halaman.misi = _susun_misi(masukan, pustaka, efek, _rng(dasar, Slot.MISI))
	halaman.ringan = _susun_ringan(masukan, pustaka, efek, _rng(dasar, Slot.RINGAN))
	return halaman


## Jeda yang harus dicatat sesudah hari `halaman.hari` selesai (S-4): tiap headline yang tampil (utama, ringan, lanjutan) menyimpan
## `hari + jeda`; misi menyimpan `hari + jeda_misi` hanya bila DIAMBIL (`misi_diambil` = id misinya); misi yang dilewati tidak memicu jeda.
static func catat_jeda(halaman: Halaman, misi_diambil: String) -> JedaBaru:
	var hasil: JedaBaru = JedaBaru.new()
	for e: Entri in [halaman.utama, halaman.misi, halaman.ringan]:
		if e == null:
			continue
		if e.jenis != "misi":
			hasil.headline[e.id] = halaman.hari + e.jeda
		if not misi_diambil.is_empty() and e.misi_id == misi_diambil:
			hasil.misi[e.misi_id] = halaman.hari + e.jeda_misi
	return hasil


# --- Slot ---

static func _susun_utama(m: Masukan, pustaka: PemuatHeadline.Pustaka, rng: RandomNumberGenerator) -> Entri:
	var pilihan: DataHeadline = _pilih_headline(m, pustaka.utama, "", rng)
	return _entri_headline(pilihan)


static func _susun_ringan(m: Masukan, pustaka: PemuatHeadline.Pustaka, efek: String, rng: RandomNumberGenerator) -> Entri:
	var lanjutan: DataHeadline = _pilih_lanjutan(m, pustaka, "ringan", efek, rng)
	if lanjutan != null:
		return _entri_headline(lanjutan)
	return _entri_headline(_pilih_headline(m, pustaka.ringan, efek, rng))


static func _susun_misi(m: Masukan, pustaka: PemuatHeadline.Pustaka, efek: String, rng: RandomNumberGenerator) -> Entri:
	var lanjutan: DataHeadline = _pilih_lanjutan(m, pustaka, "misi", efek, rng)
	if lanjutan != null:
		var e: Entri = _entri_headline(lanjutan)
		if not lanjutan.misi.is_empty():
			var terkait: DataMisi = _cari_misi(m.misi, lanjutan.misi)
			if terkait != null:
				e.misi_id = terkait.id
				e.ringkasan = terkait.ringkasan
				e.jeda_misi = terkait.jeda
		return e
	if m.hari == Config.MISI_HARI_TUTORIAL:
		var tutorial: DataMisi = _cari_misi(m.misi, Config.MISI_ID_TUTORIAL)
		if tutorial != null and tutorial.aktif:
			return _entri_misi(tutorial)
	var kandidat: Array[DataMisi] = []
	for misi: DataMisi in m.misi:
		if _misi_boleh(misi, m, efek):
			kandidat.append(misi)
	if kandidat.is_empty():
		return null
	var terpilih: DataMisi = kandidat[rng.randi_range(0, kandidat.size() - 1)]
	return _entri_misi(terpilih)


# --- Penyaringan ---

## Headline lanjutan untuk slot `slot` (`misi` atau `ringan`) yang flag-nya aktif, dipilih berbobot; null bila tidak ada.
static func _pilih_lanjutan(m: Masukan, pustaka: PemuatHeadline.Pustaka, slot: String, efek: String, rng: RandomNumberGenerator) -> DataHeadline:
	var kandidat: Array[DataHeadline] = []
	for h: DataHeadline in pustaka.lanjutan:
		if h.slot == slot and _headline_boleh(h, m, efek, false):
			kandidat.append(h)
	return _undi(kandidat, rng)


## Headline dari `pool`: undian berbobot atas yang tidak dalam jeda; bila semuanya dalam jeda, yang jedanya paling cepat berakhir; null bila pool kosong.
static func _pilih_headline(m: Masukan, pool: Array[DataHeadline], efek: String, rng: RandomNumberGenerator) -> DataHeadline:
	var siap: Array[DataHeadline] = []
	var dalam_jeda: Array[DataHeadline] = []
	for h: DataHeadline in pool:
		if _headline_boleh(h, m, efek, false):
			siap.append(h)
		elif _headline_boleh(h, m, efek, true):
			dalam_jeda.append(h)
	if not siap.is_empty():
		return _undi(siap, rng)
	var paling_cepat: DataHeadline = null
	var hari_cepat: int = Config.SAVE_ANGKA_MAKS
	for h: DataHeadline in dalam_jeda:
		var sampai: int = int(m.headline_jeda.get(h.id, 0))
		if sampai < hari_cepat:
			hari_cepat = sampai
			paling_cepat = h
	return paling_cepat


## True bila `h` aktif, cocok distrik, memenuhi syarat, dan (kecuali `abaikan_jeda`) tidak dalam jeda.
static func _headline_boleh(h: DataHeadline, m: Masukan, efek: String, abaikan_jeda: bool) -> bool:
	if not h.aktif or not _distrik_cocok(h.distrik, m.distrik) or not _syarat_ok(h.syarat, m, efek):
		return false
	return abaikan_jeda or m.hari >= int(m.headline_jeda.get(h.id, 0))


static func _misi_boleh(misi: DataMisi, m: Masukan, efek: String) -> bool:
	if not misi.aktif or misi.distrik != m.distrik or misi.rep_min > m.reputasi or not misi.lanjutan_dari.is_empty():
		return false
	return _syarat_ok(misi.syarat, m, efek) and m.hari >= int(m.misi_jeda.get(misi.id, 0))


static func _distrik_cocok(daftar: Array[String], distrik: String) -> bool:
	return daftar.is_empty() or daftar.has(distrik)


## Syarat: flag ada di flag pemain; hari_min <= hari <= hari_maks; berita_utama sama dengan efek berita utama hari itu.
static func _syarat_ok(syarat: Dictionary, m: Masukan, efek: String) -> bool:
	if syarat.has("flag") and not m.flag.has(syarat["flag"]):
		return false
	if syarat.has("hari_min") and m.hari < int(syarat["hari_min"]):
		return false
	if syarat.has("hari_maks") and m.hari > int(syarat["hari_maks"]):
		return false
	if syarat.has("berita_utama") and efek != syarat["berita_utama"]:
		return false
	return true


## Undian berbobot atas `kandidat` (urutan pustaka menentukan batas kumulatif); null bila kosong.
static func _undi(kandidat: Array[DataHeadline], rng: RandomNumberGenerator) -> DataHeadline:
	if kandidat.is_empty():
		return null
	var total: int = 0
	for h: DataHeadline in kandidat:
		total += h.bobot
	var titik: int = rng.randi_range(0, total - 1)
	for h: DataHeadline in kandidat:
		if titik < h.bobot:
			return h
		titik -= h.bobot
	return kandidat[kandidat.size() - 1]


static func _rng(dasar: int, slot: Slot) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = dasar + int(slot) * Config.SEED_HEADLINE_SLOT_LANGKAH
	return rng


static func _cari_misi(daftar: Array[DataMisi], id: String) -> DataMisi:
	for misi: DataMisi in daftar:
		if misi.id == id:
			return misi
	return null


static func _entri_headline(h: DataHeadline) -> Entri:
	if h == null:
		return null
	var e: Entri = Entri.new()
	e.id = h.id
	e.jenis = h.jenis
	e.teks = h.teks
	e.efek = h.efek
	e.jeda = h.jeda
	return e


static func _entri_misi(misi: DataMisi) -> Entri:
	var e: Entri = Entri.new()
	e.id = misi.id
	e.jenis = "misi"
	e.teks = misi.headline
	e.ringkasan = misi.ringkasan
	e.misi_id = misi.id
	e.jeda_misi = misi.jeda
	return e
