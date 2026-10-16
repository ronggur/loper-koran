class_name SkorRute
extends RefCounted
## Skor, combo, koin, tip, dan status rumah terantar satu rute, logika murni dan satu sumber (BALANCING 5 dan 7, GDD 8 dan 14.1; K-2, K-4,
## O-1 sampai O-5, AC-9 sampai AC-12 run fase3b-rintangan-skor, usulan).
##
## Skor dan koin dua besaran terpisah (K-2): skor tidak menjadi koin dan sebaliknya. Satu koran yang mendarat dinilai `nilai`:
## - `ANTAR`: antaran sah pertama ke rumah pelanggan (kotak surat, teras, halaman, jendela dengan sakelar bonus). Rumah jadi terantar (O-1).
##   Skor = `SKOR_SASARAN_DASAR` x persen sasaran (penuh 100, halaman 50) x pengali combo x pengali kecepatan saat lepas (O-5) x
##   `SKOR_TEPAT_PENGALI` bila tepat (K-4). Dihitung bilangan bulat (persen dan persepuluh, `_persen`) lalu dibulatkan ke bilangan bulat
##   terdekat, setengah ke atas. Koin = `KOIN_ONGKOS_ANTAR` (juga halaman, O-2) + `KOIN_TIP` bila teras ke pemberi tip (O-3) dan tenggat
##   belum lewat (K-1 run fase3c-hud-hasil: sesudah tenggat lewat ongkos, skor, dan combo tetap, tip 0 dan `jumlah_tip` tidak naik).
## - `ULANG`: koran ke zona rumah yang sudah terantar: 0 skor, 0 koin, combo tidak putus dan tidak naik, penanda netral (O-1).
## - `TIDAK_SAH`: meleset, bukan pelanggan, jendela dengan sakelar penalti: 0 skor, 0 koin, combo putus. Koin tidak pernah berkurang.
## Combo (AC-10): pengali = `SKOR_COMBO_AWAL` + `SKOR_COMBO_LANGKAH` x antaran sah beruntun SEBELUM antaran ini, dijepit `SKOR_COMBO_MAKS`;
## antaran yang sedang dinilai memakai pengali sebelum naik, lalu rangkaian bertambah satu. Jadi antaran ke-1 x1,0, ke-2 x1,1, ke-11 dan
## seterusnya x2,0. Putus (`TIDAK_SAH`, atau tabrakan lewat `putus_combo`) mengembalikan ke x1,0.
## Pengali kecepatan dari kecepatan SEBENARNYA saat koran dilepas (`ThrowSolver.Lintasan.kecepatan_maju_ud`) dengan pita yang sama dengan
## pita sprite: kecepatan dipetakan ke kekuatan setara (santai 0, ngebut 1) lalu `LoperAnim.tingkat_dari_stick` (ambang 0,33 dan 0,80),
## jadi santai di bawah sekitar 3,99 u/d, cepat sampai 5,4, ngebut di atasnya; melambat = santai.

enum Status { TIDAK_SAH, ANTAR, ULANG }


## Keadaan skor satu rute.
class Keadaan extends RefCounted:
	var skor: int = 0
	var koin: int = 0
	## Antaran sah beruntun sejak combo terakhir putus.
	var beruntun: int = 0
	## Id rumah yang sudah terantar (id -> true).
	var terantar: Dictionary = {}
	var jumlah_antar: int = 0
	var jumlah_tepat: int = 0
	var jumlah_tip: int = 0
	## Bagian `koin` yang berasal dari tip (untuk layar hasil, run fase3c-hud-hasil).
	var koin_tip: int = 0

	func salin() -> Keadaan:
		var baru: Keadaan = Keadaan.new()
		baru.skor = skor
		baru.koin = koin
		baru.beruntun = beruntun
		baru.terantar = terantar.duplicate()
		baru.jumlah_antar = jumlah_antar
		baru.jumlah_tepat = jumlah_tepat
		baru.jumlah_tip = jumlah_tip
		baru.koin_tip = koin_tip
		return baru


## Hasil menilai satu koran.
class Hasil extends RefCounted:
	var keadaan: Keadaan = null
	var status: Status = Status.TIDAK_SAH
	var skor_tambah: int = 0
	## Koin tambahan (ongkos antar + tip).
	var koin_tambah: int = 0
	## Bagian tip dari `koin_tambah`.
	var tip: int = 0
	## True bila antaran ini tepat (dan dihitung tepat).
	var tepat: bool = false
	## Urutan antaran ini dalam rangkaian combo (1 = pertama); 0 bila bukan `ANTAR`. Dipakai nada combo (`BunyiLempar.tingkat_nada`).
	var urutan_beruntun: int = 0
	## Pengali combo yang dipakai antaran ini (dan, untuk HUD, pengali sesudahnya ada di `pengali_combo(keadaan.beruntun)`).
	var pengali_combo: float = 1.0
	var pengali_kecepatan: float = 1.0
	## Bentuk penanda akhir di titik mendarat.
	var penanda: ZonaSasaran.Penanda = ZonaSasaran.Penanda.SILANG


static func awal() -> Keadaan:
	return Keadaan.new()


## Pengali combo untuk antaran dengan `beruntun_sebelum` antaran sah beruntun sebelumnya.
static func pengali_combo(beruntun_sebelum: int) -> float:
	return float(_combo_persen(beruntun_sebelum)) / float(Config.SKOR_PERSEN_PENUH)


## Pita kecepatan saat lepas dari kecepatan sebenarnya (0 santai, 1 cepat, 2 ngebut; melambat dan NaN = 0), pita sama dengan sprite.
static func tingkat_kecepatan(kecepatan_ud: float) -> int:
	if not is_finite(kecepatan_ud):
		return 0
	var kekuatan: float = (kecepatan_ud - Config.KECEPATAN_SANTAI_UD) / (Config.KECEPATAN_NGEBUT_UD - Config.KECEPATAN_SANTAI_UD)
	return maxi(LoperAnim.tingkat_dari_stick(kekuatan), 0)


## Pengali skor kecepatan saat lepas (O-5).
static func pengali_kecepatan(kecepatan_ud: float) -> float:
	var tingkat: int = tingkat_kecepatan(kecepatan_ud)
	if tingkat > LoperAnim.TINGKAT_CEPAT:
		return Config.SKOR_PENGALI_NGEBUT
	if tingkat == LoperAnim.TINGKAT_CEPAT:
		return Config.SKOR_PENGALI_CEPAT
	return Config.SKOR_PENGALI_SANTAI


## Persen skor sasaran untuk hasil `hasil` dengan sakelar jendela `jendela_bonus`: penuh 100, halaman 50, tidak sah 0.
static func persen_sasaran(hasil: ZonaSasaran.Hasil, jendela_bonus: bool) -> int:
	match ZonaSasaran.status_antaran(hasil, jendela_bonus):
		ZonaSasaran.Antaran.SAH_PENUH, ZonaSasaran.Antaran.SAH_BONUS:
			return Config.SKOR_PERSEN_PENUH
		ZonaSasaran.Antaran.SAH_SETENGAH:
			return Config.SKOR_PERSEN_HALAMAN
	return 0


## Skor satu antaran sah (tanpa memperhatikan status rumah): lihat rumus di atas. 0 bila hasil tidak sah.
static func skor_antaran(hasil: ZonaSasaran.Hasil, jendela_bonus: bool, beruntun_sebelum: int, kecepatan_ud: float, tepat: bool) -> int:
	var persen: int = persen_sasaran(hasil, jendela_bonus)
	if persen <= 0:
		return 0
	var tepat_persen: int = _persen(Config.SKOR_TEPAT_PENGALI) if tepat and hasil == ZonaSasaran.Hasil.KOTAK_SURAT else Config.SKOR_PERSEN_PENUH
	var pembilang: int = Config.SKOR_SASARAN_DASAR * persen * _combo_persen(beruntun_sebelum) * _persen(pengali_kecepatan(kecepatan_ud)) * tepat_persen
	var penuh: int = Config.SKOR_PERSEN_PENUH
	return roundi(float(pembilang) / float(penuh * penuh * penuh * penuh))


## Menilai satu koran yang mendarat: hasil zona `hasil`, id rumah zona `id_rumah`, `tepat` (`KoranLempar.Koran.tepat`, sudah false untuk
## mode bantu), kecepatan saat lepas `kecepatan_ud`, `pemberi_tip` (rumah itu, `RouteBuilder.pemberi_tip`), sakelar jendela, dan
## `tenggat_lewat` (`TenggatRute.lewat` saat koran mendarat; true = tip tidak diberikan, K-1). Masukan tidak diubah.
static func nilai(k: Keadaan, hasil: ZonaSasaran.Hasil, id_rumah: String, tepat: bool, kecepatan_ud: float, pemberi_tip: bool, jendela_bonus: bool, tenggat_lewat: bool = false) -> Hasil:
	var h: Hasil = Hasil.new()
	var s: Keadaan = k.salin()
	h.keadaan = s
	h.pengali_kecepatan = pengali_kecepatan(kecepatan_ud)
	h.pengali_combo = pengali_combo(s.beruntun)
	var antaran: ZonaSasaran.Antaran = ZonaSasaran.status_antaran(hasil, jendela_bonus)
	var rumah_pelanggan: bool = hasil != ZonaSasaran.Hasil.MELESET and hasil != ZonaSasaran.Hasil.BUKAN_PELANGGAN
	if rumah_pelanggan and id_rumah != "" and s.terantar.has(id_rumah):
		h.status = Status.ULANG
		h.penanda = ZonaSasaran.Penanda.NETRAL
		return h
	if not ZonaSasaran.sah(antaran):
		h.status = Status.TIDAK_SAH
		h.penanda = ZonaSasaran.Penanda.SILANG
		s.beruntun = 0
		return h
	h.status = Status.ANTAR
	h.tepat = tepat and hasil == ZonaSasaran.Hasil.KOTAK_SURAT
	h.skor_tambah = skor_antaran(hasil, jendela_bonus, s.beruntun, kecepatan_ud, h.tepat)
	h.tip = Config.KOIN_TIP if pemberi_tip and hasil == ZonaSasaran.Hasil.TERAS and not tenggat_lewat else 0
	h.koin_tambah = Config.KOIN_ONGKOS_ANTAR + h.tip
	h.penanda = ZonaSasaran.Penanda.TEPAT if h.tepat else ZonaSasaran.penanda(antaran)
	s.skor += h.skor_tambah
	s.koin += h.koin_tambah
	s.beruntun += 1
	h.urutan_beruntun = s.beruntun
	s.jumlah_antar += 1
	if h.tepat:
		s.jumlah_tepat += 1
	if h.tip > 0:
		s.jumlah_tip += 1
		s.koin_tip += h.tip
	if id_rumah != "":
		s.terantar[id_rumah] = true
	return h


## Menilai koran `koran` (`KoranLempar.Koran` yang sudah mendarat) di rute `rute` (pemberi tip dari `RouteBuilder.pemberi_tip`), dengan
## status tenggat saat mendarat `tenggat_lewat` (K-1).
static func nilai_koran(k: Keadaan, koran: KoranLempar.Koran, rute: RouteBuilder.Rute, jendela_bonus: bool, tenggat_lewat: bool = false) -> Hasil:
	var kecepatan: float = koran.lintasan.kecepatan_maju_ud if koran.lintasan != null else 0.0
	return nilai(k, koran.hasil, koran.id_rumah, koran.tepat, kecepatan, RouteBuilder.pemberi_tip(rute, koran.id_rumah), jendela_bonus, tenggat_lewat)


## Combo putus karena tabrakan (AC-6): rangkaian kembali 0 (pengali x1,0). Skor, koin, dan rumah terantar tetap. Masukan tidak diubah.
static func putus_combo(k: Keadaan) -> Keadaan:
	var s: Keadaan = k.salin()
	s.beruntun = 0
	return s


## True bila rumah `id_rumah` sudah terantar.
static func terantar(k: Keadaan, id_rumah: String) -> bool:
	return k.terantar.has(id_rumah)


## Pengali combo dalam persen (100 = x1,0) untuk `beruntun_sebelum` antaran beruntun sebelumnya, dijepit maksimum.
static func _combo_persen(beruntun_sebelum: int) -> int:
	var n: int = maxi(beruntun_sebelum, 0)
	return mini(_persen(Config.SKOR_COMBO_AWAL) + n * _persen(Config.SKOR_COMBO_LANGKAH), _persen(Config.SKOR_COMBO_MAKS))


## Pengali `nilai` dalam persen bilangan bulat (1,25 -> 125).
static func _persen(nilai_pengali: float) -> int:
	return roundi(nilai_pengali * float(Config.SKOR_PERSEN_PENUH))
