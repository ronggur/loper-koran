class_name BikeCondition
extends RefCounted
## Kondisi sepeda: ban, rem, rantai, logika murni (GDD 12, BALANCING 8; run fase6a1-bengkel-kondisi, M-1 sampai M-6, AC-5 sampai AC-12; usulan, belum diuji di HP).
##
## Kondisi = `Dictionary` id komponen (`Config.KONDISI_KOMPONEN`: `ban`, `rem`, `rantai`) -> `float` 0,0 sampai 1,0 (1,0 = baru). Tanpa node, `Time`, atau
## `randi()`: waktu dan RNG berseed adalah parameter. Semua angka di `Config` (`KONDISI_*`). Masukan tidak pernah diubah; fungsi mengembalikan kamus baru.
## - Tingkat (M-2): BAIK (>= `KONDISI_AMBANG_AUS`), AUS (tanda peringatan, efek masih nol), PERLU_BENGKEL (< `KONDISI_AMBANG_PERLU_BENGKEL`, efek menghambat).
##   Peringatan mendahului efek (ambang peringatan > ambang efek) dan efek tepat 1,0 di semua kondisi >= ambang efek (prinsip 3).
## - Aus (M-3, K-2): dari telemetri `BikeMotion` apa adanya (kecepatan rata-rata langkah, jarak, rem), TANPA menghitung ulang gerak dan TANPA cabang mode bantu: mode bantu
##   mengunci kecepatan santai, jadi aus dari ngebut praktis nol dengan sendirinya. Ban dan rantai aus per ubin menurut kecepatan; rem hanya aus saat dipakai.
## - Tabrakan (M-4): tepi naik dari `Tabrakan.Hasil.tabrak` mengurangi SATU komponen terpilih dari RNG berseed (`SeedHari.kondisi` + nomor tabrakan).
## - Tanda peringatan (M-5): fungsi murni dari (kondisi, pemakaian, waktu sejak peringatan terakhir); bunyi dan visual disambungkan lapisan UI.
## - Efek (M-6): `efek` membuat `EfekKondisi` untuk `BikeMotion.langkah` dari kondisi dan pengali upgrade.

## Tingkat kondisi satu komponen.
enum Tingkat { BAIK, AUS, PERLU_BENGKEL }


## Telemetri satu langkah gerak (dari `BikeMotion.Hasil`) untuk menghitung aus.
class Telemetri extends RefCounted:
	## Lama langkah, detik.
	var dt: float = 0.0
	## Jarak maju selama langkah, ubin.
	var maju_ubin: float = 0.0
	## Kecepatan di awal langkah, u/d.
	var kecepatan_awal_ud: float = 0.0
	## True selama rem aktif di langkah ini.
	var rem_aktif: bool = false
	## True bila rem menjadi aktif di langkah ini (tepi naik).
	var rem_mulai: bool = false


## Pemakaian sepeda saat ini, masukan tanda peringatan.
class Pemakaian extends RefCounted:
	## Kecepatan maju sebenarnya, u/d.
	var kecepatan_ud: float = 0.0
	## True selama rem aktif.
	var rem_aktif: bool = false


## Keadaan jeda antar peringatan: detik sejak peringatan terakhir per komponen. Awal = jeda penuh (peringatan pertama boleh langsung).
class StatusPeringatan extends RefCounted:
	var sejak_detik: Dictionary = {}

	func salin() -> StatusPeringatan:
		var baru: StatusPeringatan = StatusPeringatan.new()
		baru.sejak_detik = sejak_detik.duplicate()
		return baru


## Hasil satu langkah peringatan: status baru dan komponen yang memunculkan peringatan pada langkah ini.
class HasilPeringatan extends RefCounted:
	var status: StatusPeringatan = null
	var komponen: Array[String] = []


## Kondisi sepeda baru: semua komponen 1,0.
static func baru() -> Dictionary:
	var hasil: Dictionary = {}
	for k: String in Config.KONDISI_KOMPONEN:
		hasil[k] = 1.0
	return hasil


## Kondisi `kondisi` yang dirapikan: tiap komponen dikenal ada, angka dijepit 0..1 (NaN dan bukan angka = 1,0). Id asing dibuang. Masukan tidak diubah.
static func rapikan(kondisi: Dictionary) -> Dictionary:
	var hasil: Dictionary = {}
	for k: String in Config.KONDISI_KOMPONEN:
		hasil[k] = jepit(kondisi.get(k, 1.0))
	return hasil


## Satu nilai kondisi dijepit ke 0..1. Bukan angka atau NaN = 1,0 (baru); tak hingga dijepit.
static func jepit(nilai: Variant) -> float:
	var tipe: int = typeof(nilai)
	if tipe != TYPE_INT and tipe != TYPE_FLOAT:
		return 1.0
	var f: float = float(nilai)
	if is_nan(f):
		return 1.0
	return clampf(f, 0.0, 1.0)


## Kondisi dibulatkan ke `KONDISI_PEMBULATAN_PEMBAGI` bagian (4 desimal) untuk save.
static func bulatkan(nilai: float) -> float:
	return roundf(jepit(nilai) * Config.KONDISI_PEMBULATAN_PEMBAGI) / Config.KONDISI_PEMBULATAN_PEMBAGI


## Tingkat kondisi `kondisi` (M-2): BAIK sampai `KONDISI_AMBANG_AUS` (inklusif), AUS di bawahnya sampai `KONDISI_AMBANG_PERLU_BENGKEL` (inklusif), selebihnya PERLU_BENGKEL.
static func tingkat(kondisi: float) -> Tingkat:
	var k: float = jepit(kondisi)
	if k >= Config.KONDISI_AMBANG_AUS:
		return Tingkat.BAIK
	if k >= Config.KONDISI_AMBANG_PERLU_BENGKEL:
		return Tingkat.AUS
	return Tingkat.PERLU_BENGKEL


## Jumlah kotak HUD yang terisi (DESIGN_SPEC 3.3): BAIK tiga, AUS dua, PERLU_BENGKEL satu, nol bila kondisi 0.
static func kotak_terisi(kondisi: float) -> int:
	var k: float = jepit(kondisi)
	match tingkat(k):
		Tingkat.BAIK:
			return Config.KONDISI_KOTAK_BAIK
		Tingkat.AUS:
			return Config.KONDISI_KOTAK_AUS
		_:
			return Config.KONDISI_KOTAK_PERLU_BENGKEL if k > 0.0 else 0


## Id komponen yang PERLU_BENGKEL, urut `KONDISI_KOMPONEN`.
static func perlu_bengkel(kondisi: Dictionary) -> Array[String]:
	var hasil: Array[String] = []
	for k: String in Config.KONDISI_KOMPONEN:
		if tingkat(jepit(kondisi.get(k, 1.0))) == Tingkat.PERLU_BENGKEL:
			hasil.append(k)
	return hasil


## Telemetri langkah dari keluaran `BikeMotion.langkah` dengan `dt` detik.
static func telemetri(hasil: BikeMotion.Hasil, dt: float) -> Telemetri:
	var t: Telemetri = Telemetri.new()
	t.dt = dt
	t.maju_ubin = hasil.maju_ubin
	t.kecepatan_awal_ud = hasil.kecepatan_awal_ud
	t.rem_aktif = hasil.keadaan.rem_aktif
	t.rem_mulai = hasil.rem_mulai
	return t


## Aus ban atau rantai per ubin pada kecepatan rata-rata `kecepatan_ud` (u/d) untuk `komponen` (`ban` atau `rantai`; lainnya 0): di bawah santai sebanding
## kecepatan, linear santai -> cepat -> ngebut, di atas ngebut tetap.
static func aus_per_ubin(komponen: String, kecepatan_ud: float) -> float:
	var santai: float = 0.0
	var cepat: float = 0.0
	var ngebut: float = 0.0
	match komponen:
		"ban":
			santai = Config.KONDISI_AUS_BAN_SANTAI_PER_UBIN
			cepat = Config.KONDISI_AUS_BAN_CEPAT_PER_UBIN
			ngebut = Config.KONDISI_AUS_BAN_NGEBUT_PER_UBIN
		"rantai":
			santai = Config.KONDISI_AUS_RANTAI_SANTAI_PER_UBIN
			cepat = Config.KONDISI_AUS_RANTAI_CEPAT_PER_UBIN
			ngebut = Config.KONDISI_AUS_RANTAI_NGEBUT_PER_UBIN
		_:
			return 0.0
	if not is_finite(kecepatan_ud) or kecepatan_ud <= 0.0:
		return 0.0
	if kecepatan_ud <= Config.KECEPATAN_SANTAI_UD:
		return santai * kecepatan_ud / Config.KECEPATAN_SANTAI_UD
	if kecepatan_ud <= Config.KECEPATAN_CEPAT_UD:
		return lerpf(santai, cepat, (kecepatan_ud - Config.KECEPATAN_SANTAI_UD) / (Config.KECEPATAN_CEPAT_UD - Config.KECEPATAN_SANTAI_UD))
	if kecepatan_ud < Config.KECEPATAN_NGEBUT_UD:
		return lerpf(cepat, ngebut, (kecepatan_ud - Config.KECEPATAN_CEPAT_UD) / (Config.KECEPATAN_NGEBUT_UD - Config.KECEPATAN_CEPAT_UD))
	return ngebut


## Kondisi sesudah satu langkah dengan telemetri `t` (M-3). `pengali_aus` = komponen -> pengali aus dari upgrade (kosong = 1,0). `dt` nol, negatif, atau tak hingga = tidak aus.
## Tidak ada parameter atau cabang mode bantu (K-2).
static func aus(kondisi: Dictionary, t: Telemetri, pengali_aus: Dictionary = {}) -> Dictionary:
	var hasil: Dictionary = rapikan(kondisi)
	if not is_finite(t.dt) or t.dt <= 0.0 or not is_finite(t.maju_ubin):
		return hasil
	var maju: float = maxf(t.maju_ubin, 0.0)
	var rata: float = maju / t.dt
	for k: String in ["ban", "rantai"]:
		hasil[k] = jepit(float(hasil[k]) - maju * aus_per_ubin(k, rata) * _pengali(pengali_aus, k))
	var rem: float = 0.0
	if t.rem_mulai:
		rem += Config.KONDISI_AUS_REM_PER_PENGEREMAN
	if t.rem_aktif and t.kecepatan_awal_ud > 0.0:
		rem += Config.KONDISI_AUS_REM_PER_DETIK * t.dt
	hasil["rem"] = jepit(float(hasil["rem"]) - rem * _pengali(pengali_aus, "rem"))
	return hasil


## Komponen yang rusak pada tabrakan ke-`nomor` (mulai 0) di hari `hari` (M-4): RNG berseed `SeedHari.kondisi(hari)` + nomor x `SEED_KONDISI_NOMOR_LANGKAH`, dipilih menurut bobot
## `KONDISI_TABRAKAN_BOBOT`. Hari dan nomor sama = komponen sama.
static func komponen_tabrakan(hari: int, nomor: int) -> String:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = SeedHari.kondisi(hari) + nomor * Config.SEED_KONDISI_NOMOR_LANGKAH
	var total: int = 0
	for b: int in Config.KONDISI_TABRAKAN_BOBOT:
		total += maxi(b, 0)
	var titik: int = rng.randi_range(0, total - 1)
	for i: int in range(Config.KONDISI_KOMPONEN.size()):
		titik -= maxi(Config.KONDISI_TABRAKAN_BOBOT[i], 0)
		if titik < 0:
			return Config.KONDISI_KOMPONEN[i]
	return Config.KONDISI_KOMPONEN[Config.KONDISI_KOMPONEN.size() - 1]


## Kondisi sesudah langkah `Tabrakan` bernomor tabrakan `hasil.keadaan.jumlah - 1` di hari `hari` (M-4): hanya langkah dengan `tabrak` (tepi naik) mengurangi SATU komponen sebesar
## `KONDISI_TABRAKAN_KERUSAKAN`; jatuh yang berlanjut, kebal, dan menempel tidak menggandakan. Kondisi 0 tetap 0.
static func tabrakan(kondisi: Dictionary, hari: int, hasil: Tabrakan.Hasil) -> Dictionary:
	var baru: Dictionary = rapikan(kondisi)
	if not hasil.tabrak or hasil.keadaan == null:
		return baru
	var k: String = komponen_tabrakan(hari, hasil.keadaan.jumlah - 1)
	baru[k] = jepit(float(baru[k]) - Config.KONDISI_TABRAKAN_KERUSAKAN)
	return baru


## True bila komponen `komponen` dipakai dalam `pemakaian` sehingga tanda peringatannya relevan (M-5): rantai berisik dan ban mendesis saat melaju >= `KONDISI_PERINGATAN_KECEPATAN_MIN_UD`,
## rem berdecit saat rem aktif.
static func dipakai(komponen: String, pemakaian: Pemakaian) -> bool:
	match komponen:
		"rem":
			return pemakaian.rem_aktif
		"ban", "rantai":
			return pemakaian.kecepatan_ud >= Config.KONDISI_PERINGATAN_KECEPATAN_MIN_UD - Config.KONDISI_TOLERANSI
		_:
			return false


## Status peringatan awal: jeda sudah penuh untuk semua komponen, jadi peringatan pertama boleh langsung.
static func status_peringatan_awal() -> StatusPeringatan:
	var s: StatusPeringatan = StatusPeringatan.new()
	for k: String in Config.KONDISI_KOMPONEN:
		s.sejak_detik[k] = Config.KONDISI_PERINGATAN_JEDA_DETIK
	return s


## Satu langkah peringatan selama `dt` detik: waktu sejak peringatan maju, lalu komponen yang AUS atau lebih buruk, sedang dipakai, dan sudah lewat jeda memunculkan peringatan
## (waktunya kembali 0). Tingkat BAIK tidak pernah memperingatkan; komponen yang tidak dipakai tidak pernah memperingatkan (tanpa peringatan palsu). `dt` nol, negatif, atau tak
## hingga (jeda game) = tidak ada peringatan dan waktu tidak maju (beku).
static func langkah_peringatan(status: StatusPeringatan, kondisi: Dictionary, pemakaian: Pemakaian, dt: float) -> HasilPeringatan:
	var hasil: HasilPeringatan = HasilPeringatan.new()
	hasil.status = status.salin()
	if not is_finite(dt) or dt <= 0.0:
		return hasil
	for k: String in Config.KONDISI_KOMPONEN:
		var sejak: float = float(hasil.status.sejak_detik.get(k, Config.KONDISI_PERINGATAN_JEDA_DETIK)) + dt
		hasil.status.sejak_detik[k] = sejak
		if tingkat(jepit(kondisi.get(k, 1.0))) == Tingkat.BAIK or not dipakai(k, pemakaian):
			continue
		if sejak >= Config.KONDISI_PERINGATAN_JEDA_DETIK - Config.KONDISI_TOLERANSI:
			hasil.komponen.append(k)
			hasil.status.sejak_detik[k] = 0.0
	return hasil


## Pecahan efek 0..1 untuk kondisi `kondisi`: 1,0 di semua kondisi >= `KONDISI_AMBANG_PERLU_BENGKEL`, turun linear ke 0 di kondisi 0.
static func pecahan_efek(kondisi: float) -> float:
	var k: float = jepit(kondisi)
	if k >= Config.KONDISI_AMBANG_PERLU_BENGKEL:
		return 1.0
	return k / Config.KONDISI_AMBANG_PERLU_BENGKEL


## Pengali efek antara `minimum` (kondisi 0) dan 1,0 (di ambang efek), tidak di bawah `KONDISI_EFEK_LANTAI`. Monoton naik terhadap kondisi; tepat 1,0 bila tanpa efek.
static func pengali_efek(kondisi: float, minimum: float) -> float:
	var f: float = pecahan_efek(kondisi)
	if f >= 1.0:
		return 1.0
	return clampf(lerpf(minimum, 1.0, f), Config.KONDISI_EFEK_LANTAI, 1.0)


## `EfekKondisi` dari kondisi sepeda dan pengali upgrade (M-6). `pengali_upgrade` memuat kunci `pengali_rem`, `pengali_lateral`, `pengali_kuras_stamina` (kosong = 1,0); pengali aus per
## komponen tidak dipakai di sini (lihat `aus`). Ban: kecepatan tujuan dan lateral; rem: perlambatan; rantai: akselerasi dan batas puncak (tidak di bawah santai).
static func efek(kondisi: Dictionary, pengali_upgrade: Dictionary = {}) -> EfekKondisi:
	var e: EfekKondisi = EfekKondisi.new()
	var ban: float = jepit(kondisi.get("ban", 1.0))
	var rem: float = jepit(kondisi.get("rem", 1.0))
	var rantai: float = jepit(kondisi.get("rantai", 1.0))
	e.pengali_kecepatan = pengali_efek(ban, Config.KONDISI_EFEK_BAN_KECEPATAN_MIN)
	e.pengali_lateral = pengali_efek(ban, Config.KONDISI_EFEK_BAN_LATERAL_MIN) * _pengali(pengali_upgrade, "pengali_lateral")
	e.pengali_rem = pengali_efek(rem, Config.KONDISI_EFEK_REM_MIN) * _pengali(pengali_upgrade, "pengali_rem")
	e.pengali_akselerasi = pengali_efek(rantai, Config.KONDISI_EFEK_RANTAI_AKSELERASI_MIN)
	var f: float = pecahan_efek(rantai)
	e.batas_puncak_ud = Config.KECEPATAN_NGEBUT_UD if f >= 1.0 else maxf(lerpf(Config.KONDISI_EFEK_RANTAI_PUNCAK_MIN_UD, Config.KECEPATAN_NGEBUT_UD, f), Config.KECEPATAN_SANTAI_UD)
	e.pengali_kuras_stamina = _pengali(pengali_upgrade, "pengali_kuras_stamina")
	return e


## Pengali `kunci` di `kamus` (kosong, tidak ada, atau bukan angka berhingga positif = 1,0).
static func _pengali(kamus: Dictionary, kunci: String) -> float:
	var nilai: Variant = kamus.get(kunci, 1.0)
	var tipe: int = typeof(nilai)
	if (tipe != TYPE_INT and tipe != TYPE_FLOAT) or not is_finite(float(nilai)) or float(nilai) <= 0.0:
		return 1.0
	return float(nilai)
