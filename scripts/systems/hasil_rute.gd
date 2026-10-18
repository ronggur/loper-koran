class_name HasilRute
extends RefCounted
## Angka layar hasil satu rute, logika murni dan satu sumber (O-11, O-12, AC-11 run fase3c-hud-hasil, usulan). UI hanya menampilkan.
##
## - Terkirim = pelanggan rute yang terantar (`ProgresRute.jumlah_terkirim` dari `SkorRute.Keadaan.terantar`).
## - Meleset = pelanggan rute yang tidak terantar saat rute selesai = jumlah pelanggan - terkirim.
## - Koin, koin tip, jumlah pemberi tip yang memberi tip, skor, dan jumlah tepat langsung dari `SkorRute.Keadaan`. Hadiah misi (`koin_misi`, hanya bila
##   misi `selesai`, K-1 run fase4b-misi-kucing) ditambahkan ke `koin`; misi gagal tidak mengubah apa pun (prinsip 2). Satu sumber untuk HUD, layar hasil, dan save.
## - Tenggat lewat (bool) dan detik lewat (detik bulat tampilan, `TenggatRute.detik_tampil`; 0 bila tidak lewat) dari `TenggatRute`.
## - Layar hasil boleh terbuka (`siap_tampil`) sesudah garis akhir, saat sepeda sudah berhenti (kecepatan paling tinggi
##   `HASIL_BERHENTI_TOLERANSI_UD`) DAN tidak ada koran yang masih terbang (semua koran yang dilempar sudah mendarat dan dinilai).
## Juga format angka dengan pemisah ribuan ("1.250", DESIGN_SPEC 3.3); pemisahnya diberikan pemanggil dari kunci terjemahan.
## Tanpa node, `Time`, atau RNG; masukan tidak diubah.


## Angka hasil satu rute.
class Angka extends RefCounted:
	var pelanggan: int = 0
	var terkirim: int = 0
	var meleset: int = 0
	var koin: int = 0
	## Bagian `koin` dari tip.
	var koin_tip: int = 0
	## Jumlah antaran yang memberi tip.
	var jumlah_tip: int = 0
	var skor: int = 0
	var jumlah_tepat: int = 0
	var tenggat_lewat: bool = false
	## Detik bulat sesudah tenggat lewat (0 bila tidak lewat).
	var detik_lewat: int = 0
	## Misi sampingan hari ini (run fase4b-misi-kucing, AC-16): id misi aktif ("" bila tanpa misi), hasilnya ("" | `selesai` | `gagal`), dan
	## koin hadiah yang dibayar (hanya `selesai`, K-1). `koin` SUDAH termasuk `koin_misi` (koin rute + tip + misi).
	var misi_id: String = ""
	var misi_hasil: String = ""
	var koin_misi: int = 0


## Angka hasil dari skor `skor`, rute `rute`, dan jam tenggat `tenggat`. Rute null = 0 pelanggan; tenggat null = tidak lewat. `misi` (keadaan
## `MissionManager`, null = tanpa misi) menambah id, hasil, dan koin misi; hanya misi `selesai` menambah koin.
static func dari(skor: SkorRute.Keadaan, rute: RouteBuilder.Rute, tenggat: TenggatRute.Keadaan, misi: MissionManager.Keadaan = null) -> Angka:
	var a: Angka = Angka.new()
	a.pelanggan = rute.pelanggan.size() if rute != null else 0
	a.terkirim = ProgresRute.jumlah_terkirim(rute, skor.terantar)
	a.meleset = maxi(a.pelanggan - a.terkirim, 0)
	a.koin = skor.koin
	a.koin_tip = skor.koin_tip
	a.jumlah_tip = skor.jumlah_tip
	a.skor = skor.skor
	a.jumlah_tepat = skor.jumlah_tepat
	if tenggat != null and TenggatRute.lewat(tenggat):
		a.tenggat_lewat = true
		a.detik_lewat = TenggatRute.detik_tampil(tenggat)
	if misi != null and misi.rencana != null and misi.rencana.sah():
		a.misi_id = misi.rencana.id_misi
		a.misi_hasil = MissionManager.nama_hasil(misi)
		a.koin_misi = MissionManager.koin_misi(misi)
		a.koin += a.koin_misi
	return a


## True bila layar hasil boleh terbuka: rute `selesai`, kecepatan sepeda `kecepatan_ud` paling tinggi `HASIL_BERHENTI_TOLERANSI_UD`, dan
## tidak ada koran di `koran` yang belum mendarat.
static func siap_tampil(selesai: bool, kecepatan_ud: float, koran: Array[KoranLempar.Koran]) -> bool:
	if not selesai or not is_finite(kecepatan_ud) or kecepatan_ud > Config.HASIL_BERHENTI_TOLERANSI_UD:
		return false
	for k: KoranLempar.Koran in koran:
		if not k.mendarat:
			return false
	return true


## Bilangan bulat `n` dengan pemisah ribuan `pemisah` tiap `ANGKA_KELOMPOK_RIBUAN` angka dari kanan ("1250" -> "1.250", "-1250" -> "-1.250").
static func ribuan(n: int, pemisah: String) -> String:
	var angka: String = str(absi(n))
	var hasil: String = ""
	var hitung: int = 0
	for i: int in range(angka.length() - 1, -1, -1):
		if hitung > 0 and hitung % Config.ANGKA_KELOMPOK_RIBUAN == 0:
			hasil = pemisah + hasil
		hasil = angka[i] + hasil
		hitung += 1
	return ("-" + hasil) if n < 0 else hasil
