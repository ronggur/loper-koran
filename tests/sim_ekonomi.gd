class_name SimEkonomi
extends RefCounted
## Simulasi ekonomi dan reputasi berhari-hari (run fase6a2-reputasi-pelanggan, AC-7, K-3; BALANCING 7.2, rule `testing`): menjalankan hari berurutan di sistem NYATA (`RouteBuilder` dengan keadaan pelanggan,
## `SkorRute`, `RencanaMisi`, `ReputationManager` lewat `DataSave.catat_hari`) untuk tiga profil bot dan melaporkan reputasi per hari. Tanpa node, tanpa berkas save, deterministik dari seed.
##
## ASUMSI YANG DIUMUMKAN (bukan hasil ukur; dinilai di HP): fisika lemparan dan gerak tidak disimulasikan. Tiap profil melempar sekali ke tiap pelanggan rute dengan peluang hasil tetap (`AKURASI`:
## tepat, kotak surat, teras, halaman; sisanya meleset) dan, bila meleset dan masih ada koran cadangan, mengulang sekali dengan peluang `PELUANG_ULANG`. Profil membedakan akurasi (santai paling teliti, ngebut paling sembarangan), bukan
## jumlah pelanggan yang dijangkau: rute selalu dilewati sampai garis akhir. Misi P1 muncul tiap `MISI_SELANG_HARI` hari (jeda misi 7 hari) dan diselesaikan dengan peluang `PELUANG_MISI`; tabrakan dan
## kondisi sepeda tidak memengaruhi reputasi (O-8) jadi tidak disimulasikan.

const PROFIL: Array[String] = ["santai", "campuran", "ngebut"]
## Peluang hasil satu lemparan per profil: [tepat, kotak surat (bukan tepat), teras, halaman]; sisanya meleset.
const AKURASI: Dictionary = {
	"santai": [0.35, 0.35, 0.12, 0.04],
	"campuran": [0.20, 0.35, 0.13, 0.07],
	"ngebut": [0.10, 0.30, 0.12, 0.08],
}
## Peluang mengulang lemparan yang meleset (bila masih ada koran cadangan) per profil: ngebut sering tidak sempat mengulang.
const PELUANG_ULANG: Dictionary = {"santai": 1.0, "campuran": 0.8, "ngebut": 0.5}
## Peluang misi yang muncul diselesaikan per profil.
const PELUANG_MISI: Dictionary = {"santai": 0.8, "campuran": 0.6, "ngebut": 0.4}
## Selang hari misi P1 muncul (hari 1, 9, 17, ...): jeda misi 7 hari ditambah satu hari.
const MISI_SELANG_HARI: int = 8
const SEED_DASAR: int = 90210
const KECEPATAN_LEPAS_UD: float = 3.0
const TARGET_REPUTASI: int = 40


## Satu hari simulasi.
class HariSim extends RefCounted:
	var hari: int = 0
	var reputasi: int = 0
	var perubahan: int = 0
	## Kenaikan sebelum pagar harian dan penjepitan (kredit + misi), untuk melihat apakah pagar bekerja.
	var naik_mentah: int = 0
	var terkirim: int = 0
	var jumlah_baru: int = 0
	var jumlah_setia: int = 0
	var jumlah_berhenti: int = 0
	var jumlah_kembali: int = 0
	var setia_total: int = 0
	var berhenti_total: int = 0
	var misi_selesai: bool = false
	var pelepasan: int = 0


## Hasil simulasi satu profil.
class Hasil extends RefCounted:
	var profil: String = ""
	var hari: Array[HariSim] = []
	var state_akhir: Dictionary = {}

	## Hari pertama reputasi >= `nilai` (0 bila tidak pernah).
	func hari_capai(nilai: int) -> int:
		for h: HariSim in hari:
			if h.reputasi >= nilai:
				return h.hari
		return 0

	func perubahan_terbesar() -> int:
		var m: int = -1000
		for h: HariSim in hari:
			m = maxi(m, h.perubahan)
		return m

	func perubahan_terkecil() -> int:
		var m: int = 1000
		for h: HariSim in hari:
			m = mini(m, h.perubahan)
		return m

	func reputasi_terkecil() -> int:
		var m: int = 1000
		for h: HariSim in hari:
			m = mini(m, h.reputasi)
		return m

	func rata_perubahan(sampai_hari: int) -> float:
		var jumlah: float = 0.0
		var n: int = 0
		for h: HariSim in hari:
			if h.hari <= sampai_hari:
				jumlah += float(h.perubahan)
				n += 1
		return jumlah / float(maxi(n, 1))


static var _pustaka_cache: Array[SegmenRute] = []
static var _misi_cache: DataMisi = null
static var _kepribadian_cache: Array[KepribadianPelanggan.Entri] = []


static func _muat() -> void:
	if _pustaka_cache.is_empty():
		_pustaka_cache = PemuatRute.muat_folder("res://assets/data/routes/perumahan").segmen
		_kepribadian_cache = PemuatPelanggan.muat().entri
		_misi_cache = PemuatMisi.muat_folder().cari(Config.MISI_ID_TUTORIAL)


## Jalankan `jumlah_hari` hari berurutan untuk `profil` dari save baru. `benih` mengubah undian lemparan (bukan rute, yang selalu `SeedHari.rute`).
static func jalankan(profil: String, jumlah_hari: int, benih: int = SEED_DASAR) -> Hasil:
	_muat()
	var hasil: Hasil = Hasil.new()
	hasil.profil = profil
	var state: Dictionary = DataSave.templat()
	var akurasi: Array = AKURASI[profil]
	for hari: int in range(1, jumlah_hari + 1):
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = SeedHari.campur(benih + PROFIL.find(profil) * 101, hari)
		var p: PelangganRute = PelangganRute.dari_state(state, _kepribadian_cache)
		var h: RouteBuilder.Hasil = RouteBuilder.bangun(SeedHari.rute(hari), _pustaka_cache, hari, p)
		if not h.sah():
			continue
		var rute: RouteBuilder.Rute = h.rute
		var skor: SkorRute.Keadaan = SkorRute.awal()
		var cadangan: int = rute.koran_awal - rute.pelanggan.size()
		for rumah: RouteBuilder.RumahRute in rute.pelanggan:
			var percobaan: int = 2
			while percobaan > 0:
				percobaan -= 1
				var u: float = rng.randf()
				var hasil_zona: ZonaSasaran.Hasil = ZonaSasaran.Hasil.MELESET
				var tepat: bool = false
				if u < float(akurasi[0]):
					hasil_zona = ZonaSasaran.Hasil.KOTAK_SURAT
					tepat = true
				elif u < float(akurasi[0]) + float(akurasi[1]):
					hasil_zona = ZonaSasaran.Hasil.KOTAK_SURAT
				elif u < float(akurasi[0]) + float(akurasi[1]) + float(akurasi[2]):
					hasil_zona = ZonaSasaran.Hasil.TERAS
				elif u < float(akurasi[0]) + float(akurasi[1]) + float(akurasi[2]) + float(akurasi[3]):
					hasil_zona = ZonaSasaran.Hasil.HALAMAN
				var id: String = rumah.id if hasil_zona != ZonaSasaran.Hasil.MELESET else ""
				skor = SkorRute.nilai(skor, hasil_zona, id, tepat, KECEPATAN_LEPAS_UD, RouteBuilder.pemberi_tip(rute, rumah.id), false).keadaan
				if hasil_zona != ZonaSasaran.Hasil.MELESET:
					break
				if cadangan <= 0 or rng.randf() >= float(PELUANG_ULANG[profil]):
					break
				cadangan -= 1
		var catatan: ReputationManager.Catatan = ReputationManager.catat(rute, skor, hari)
		var misi_selesai: bool = false
		if _misi_cache != null and (hari - 1) % MISI_SELANG_HARI == 0:
			var rencana: RencanaMisi.Rencana = RencanaMisi.buat(_misi_cache, rute, SeedHari.misi(hari))
			if rencana.sah():
				var m: ReputationManager.CatatanMisi = ReputationManager.CatatanMisi.new()
				m.id_misi = _misi_cache.id
				m.selesai = rng.randf() < float(PELUANG_MISI[profil])
				m.gagal = not m.selesai
				m.tingkat = str(_misi_cache.hadiah.get("tingkat", ""))
				m.setia = str(_misi_cache.hadiah.get("tambahan", "")) == "pelanggan_setia"
				m.id_rumah = rencana.titik[rencana.titik.size() - 1].id_rumah
				m.gagal_reputasi = _misi_cache.gagal_reputasi()
				catatan.misi = m
				misi_selesai = m.selesai
		var rep: ReputationManager.Hasil = ReputationManager.terapkan(state, catatan, _kepribadian_cache)
		var c: DataSave.CatatanHari = DataSave.CatatanHari.new()
		c.hari = hari
		c.angka = HasilRute.dari(skor, rute, null, null)
		c.pelanggan = catatan
		c.kepribadian = _kepribadian_cache
		state = DataSave.catat_hari(state, c)
		var sim: HariSim = HariSim.new()
		sim.hari = hari
		sim.reputasi = ReputationManager.reputasi_di(state, Config.DISTRIK_AWAL)
		sim.perubahan = rep.perubahan
		sim.naik_mentah = rep.poin_antaran + rep.poin_misi
		sim.terkirim = c.angka.terkirim
		sim.jumlah_baru = rep.jumlah(ReputationManager.Jenis.BARU)
		sim.jumlah_setia = rep.jumlah(ReputationManager.Jenis.SETIA)
		sim.jumlah_berhenti = rep.jumlah(ReputationManager.Jenis.BERHENTI)
		sim.jumlah_kembali = rep.jumlah(ReputationManager.Jenis.KEMBALI)
		sim.misi_selesai = misi_selesai
		sim.pelepasan = rute.pelepasan
		var peta: Dictionary = state["pelanggan"]
		for id: Variant in peta:
			var st: String = str((peta[id] as Dictionary)["status"])
			if st == PelangganRute.SETIA:
				sim.setia_total += 1
			elif st == PelangganRute.BERHENTI:
				sim.berhenti_total += 1
		hasil.hari.append(sim)
	hasil.state_akhir = state
	return hasil


## Laporan teks satu profil (satu baris per hari) untuk BALANCING.
static func laporan(hasil: Hasil) -> String:
	var baris: Array[String] = ["profil %s: reputasi %d dicapai hari %d, perubahan %d..%d, rata-rata 20 hari pertama %.2f" % [hasil.profil, TARGET_REPUTASI, hasil.hari_capai(TARGET_REPUTASI), hasil.perubahan_terkecil(), hasil.perubahan_terbesar(), hasil.rata_perubahan(20)]]
	for h: HariSim in hasil.hari:
		baris.append("  hari %2d rep %3d (%+d) terkirim %2d baru %2d setia+ %d berhenti+ %d kembali+ %d setia_total %2d berhenti_total %d misi %s lepas %d" % [h.hari, h.reputasi, h.perubahan, h.terkirim, h.jumlah_baru, h.jumlah_setia, h.jumlah_berhenti, h.jumlah_kembali, h.setia_total, h.berhenti_total, "ya" if h.misi_selesai else "-", h.pelepasan])
	return "\n".join(baris)
