class_name KondisiRute
extends RefCounted
## Kondisi sepeda selama satu rute, logika murni yang menyambungkan bagian A ke scene (run fase6a1-bengkel-kondisi bagian B, AC-6, AC-8, AC-11, AC-23; usulan): aus dari telemetri
## `BikeMotion` apa adanya (`BikeCondition.aus`), kerusakan tabrakan dari seed hari (`BikeCondition.tabrakan`), tanda peringatan berjeda (`BikeCondition.langkah_peringatan`), dan
## `EfekKondisi` untuk langkah gerak berikutnya dari kondisi dan level upgrade tersimpan. Satu fungsi `langkah` per langkah simulasi; `AdeganJalan` hanya memanggilnya dan menampilkan.
## - Tanpa cabang mode bantu (K-2): masukannya hanya gerak, tabrakan, dan waktu. Mode bantu mengunci kecepatan santai, jadi aus ngebutnya nol dengan sendirinya.
## - Sesudah garis akhir (`selesai`) tidak ada aus, kerusakan, atau peringatan: pengereman otomatis di akhir rute bukan pilihan pemain dan tidak ikut ukuran BALANCING 8.2
##   (bot berhenti di garis akhir). Waktu visual peringatan tetap berjalan sampai habis.
## - `dt` nol, negatif, atau tak hingga (jeda game, langkah pertama sesudah lanjut) = tidak ada aus, peringatan, atau waktu maju (beku).
## Waktu dan RNG tidak dipakai; seed dari `SeedHari.kondisi(hari)` lewat `BikeCondition`.


## Keadaan kondisi satu rute. Diganti objek baru tiap langkah (`salin`), tidak diubah di tempat.
class Keadaan extends RefCounted:
	## Kondisi tiap komponen, id -> 0,0 sampai 1,0.
	var kondisi: Dictionary = {}
	## Level upgrade tersimpan tiap komponen, id -> bilangan bulat (tetap selama rute).
	var level: Dictionary = {}
	## Hari yang dimainkan (seed kerusakan tabrakan).
	var hari: int = Config.HARI_AWAL
	## Pengali efek upgrade bukan-aus (`DataToko.pengali_efek`) dan pengali aus per komponen (`DataToko.pengali_aus`), tetap selama rute.
	var pengali_efek: Dictionary = {}
	var pengali_aus: Dictionary = {}
	## Efek untuk langkah gerak berikutnya, dari `kondisi`.
	var efek: EfekKondisi = EfekKondisi.new()
	var status_peringatan: BikeCondition.StatusPeringatan = BikeCondition.status_peringatan_awal()
	## Sisa waktu visual peringatan per komponen (id -> detik); > 0 = ikon bergetar dan kotak terisi berwarna WARN.
	var kedip: Dictionary = {}
	## Jumlah peristiwa peringatan sejak rute dimulai per komponen (id -> bilangan bulat; untuk tes dan probe).
	var jumlah_peringatan: Dictionary = {}

	func salin() -> Keadaan:
		var baru: Keadaan = Keadaan.new()
		baru.kondisi = kondisi.duplicate()
		baru.level = level
		baru.hari = hari
		baru.pengali_efek = pengali_efek
		baru.pengali_aus = pengali_aus
		baru.efek = efek
		baru.status_peringatan = status_peringatan
		baru.kedip = kedip.duplicate()
		baru.jumlah_peringatan = jumlah_peringatan.duplicate()
		return baru


## Hasil satu langkah: keadaan baru dan komponen yang memunculkan peringatan pada langkah ini (bunyi dan visual dipasangkan oleh pemanggil).
class Hasil extends RefCounted:
	var keadaan: Keadaan = null
	var peringatan: Array[String] = []


## Keadaan awal rute: `kondisi` (id -> 0..1, dirapikan), `level` (id -> level upgrade), hari `hari`, dan `daftar` upgrade yang sah (`PemuatToko`). Efek langsung dari kondisi dan level.
static func awal(kondisi: Dictionary, level: Dictionary, hari: int, daftar: Array[DataToko]) -> Keadaan:
	var k: Keadaan = Keadaan.new()
	k.kondisi = BikeCondition.rapikan(kondisi)
	k.level = {}
	for id: String in Config.KONDISI_KOMPONEN:
		k.level[id] = maxi(int(level.get(id, 0)), 0)
		k.kedip[id] = 0.0
		k.jumlah_peringatan[id] = 0
	k.hari = hari
	k.pengali_efek = DataToko.pengali_efek(daftar, k.level)
	k.pengali_aus = DataToko.pengali_aus(daftar, k.level)
	k.efek = BikeCondition.efek(k.kondisi, k.pengali_efek)
	return k


## Satu langkah sesudah `gerak` (keluaran `BikeMotion.langkah` untuk langkah ini) selama `dt` detik. `tabrakan` = hasil `Tabrakan` langkah ini (null = tidak ada tabrakan). `selesai` = sepeda
## sudah melewati garis akhir (aus, kerusakan, dan peringatan berhenti).
static func langkah(k: Keadaan, gerak: BikeMotion.Hasil, dt: float, tabrakan: Tabrakan.Hasil, selesai: bool) -> Hasil:
	var hasil: Hasil = Hasil.new()
	var baru: Keadaan = k.salin()
	hasil.keadaan = baru
	var waktu: float = dt if is_finite(dt) and dt > 0.0 else 0.0
	for id: String in Config.KONDISI_KOMPONEN:
		baru.kedip[id] = maxf(float(baru.kedip[id]) - waktu, 0.0)
	if selesai:
		return hasil
	baru.kondisi = BikeCondition.aus(baru.kondisi, BikeCondition.telemetri(gerak, waktu), baru.pengali_aus)
	if tabrakan != null:
		baru.kondisi = BikeCondition.tabrakan(baru.kondisi, baru.hari, tabrakan)
	var pakai: BikeCondition.Pemakaian = BikeCondition.Pemakaian.new()
	pakai.kecepatan_ud = gerak.keadaan.kecepatan_ud
	pakai.rem_aktif = gerak.keadaan.rem_aktif
	var peringatan: BikeCondition.HasilPeringatan = BikeCondition.langkah_peringatan(baru.status_peringatan, baru.kondisi, pakai, waktu)
	baru.status_peringatan = peringatan.status
	for id: String in peringatan.komponen:
		baru.kedip[id] = Config.KONDISI_KEDIP_DETIK
		baru.jumlah_peringatan[id] = int(baru.jumlah_peringatan[id]) + 1
		hasil.peringatan.append(id)
	baru.efek = BikeCondition.efek(baru.kondisi, baru.pengali_efek)
	return hasil


## True bila komponen `komponen` sedang dalam waktu visual peringatan.
static func sedang_kedip(k: Keadaan, komponen: String) -> bool:
	return float(k.kedip.get(komponen, 0.0)) > 0.0
