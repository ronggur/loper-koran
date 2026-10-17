class_name Tabrakan
extends RefCounted
## Aturan tabrakan sepeda dengan rintangan, logika murni (BALANCING 6; keputusan pemilik 2026-10-17 "tabrakan = jatuh" menggantikan
## oleng K-1 run fase3b-rintangan-skor; usulan).
##
## Bentuk = persegi di bidang tanah (koordinat jalan: x = lateral, y = maju, ubin). Dua bentuk bertabrakan bila irisannya berluas (tepi
## yang hanya bersentuhan tidak dihitung). Satu tabrakan = pemain JATUH:
## - kecepatan sepeda langsung 0, rem padam (`terapkan_ke_sepeda`); lateral dan stamina tetap (stamina tidak dihukum);
## - jatuh `TABRAKAN_JATUH_DETIK` sejak tabrakan: kecepatan tetap 0 dan stick diabaikan (`jatuh_detik` -> `BikeMotion.langkah(..., beku_detik)`),
##   lemparan ditolak (pemilik), sprite memutar jatuh lalu terjerembab (`LoperAnim.frame_jatuh` dengan `lewat_jatuh_detik`);
## - bangun: sepeda dikayuh lagi dari 0 dengan akselerasi biasa, jadi waktu jatuh + akselerasi = harga tabrakan;
## - kebal `TABRAKAN_KEBAL_DETIK` dihitung dari saat BANGUN (bukan dari tabrakan): tidak ada tabrakan kedua dari rintangan mana pun, juga
##   tidak selama jatuh, jadi pemain yang bangun di samping rintangan (mis. mobil yang berhenti di garis tengah) sempat menjauh;
## - combo putus (`SkorRute.putus_combo`, dipanggil pemilik) dan rute tidak berhenti (prinsip 2). Tanpa batas tabrakan, tanpa game over.
## Tanpa tabrakan ganda: rintangan yang sudah bersentuhan dengan sepeda saat tabrakan, selama jatuh, atau selama kebal ("menempel") tidak
## memicu tabrakan lagi sampai sepeda terpisah darinya, jadi pemain yang jatuh di dalam bentuk mobil yang diam bisa keluar tanpa jatuh
## lagi walau kebal sudah habis. Waktu ikut `dt` (jeda = 0, membeku); langkah yang melewati akhir jatuh memakai sisa waktunya untuk kebal,
## jadi hasil tidak bergantung pada pembagian `dt`. Masukan tidak diubah.


## Satu rintangan yang bisa ditabrak langkah ini.
class Kandidat extends RefCounted:
	var id: int = 0
	## Jenis dari data segmen (`anjing_penjaga`, `mobil_garasi`), dibawa ke peristiwa tabrakan (AC-8).
	var jenis: String = ""
	var kotak: Rect2 = Rect2()


## Keadaan tabrakan sepeda.
class Keadaan extends RefCounted:
	## Sisa jatuh, detik (0 = tidak jatuh).
	var jatuh_detik: float = 0.0
	## Sisa kebal, detik (mulai saat bangun).
	var kebal_detik: float = 0.0
	## Id rintangan yang masih bersentuhan sejak tabrakan, selama jatuh, atau selama kebal.
	var menempel: Array[int] = []
	## Jumlah tabrakan sejak awal rute.
	var jumlah: int = 0

	func salin() -> Keadaan:
		var baru: Keadaan = Keadaan.new()
		baru.jatuh_detik = jatuh_detik
		baru.kebal_detik = kebal_detik
		baru.menempel = menempel.duplicate()
		baru.jumlah = jumlah
		return baru


## Hasil satu langkah.
class Hasil extends RefCounted:
	var keadaan: Keadaan = null
	## True bila langkah ini terjadi tabrakan baru.
	var tabrak: bool = false
	## Id dan jenis rintangan penyebab (berlaku bila `tabrak`).
	var id: int = -1
	var jenis: String = ""


static func awal() -> Keadaan:
	return Keadaan.new()


## Kandidat baru.
static func kandidat(id: int, jenis: String, kotak: Rect2) -> Kandidat:
	var c: Kandidat = Kandidat.new()
	c.id = id
	c.jenis = jenis
	c.kotak = kotak
	return c


## Bentuk tabrakan sepeda dengan pusat di (`lateral_ubin`, `maju_ubin`).
static func kotak_sepeda(maju_ubin: float, lateral_ubin: float) -> Rect2:
	var setengah: Vector2 = Vector2(Config.TABRAKAN_SEPEDA_SETENGAH_LATERAL_UBIN, Config.TABRAKAN_SEPEDA_SETENGAH_MAJU_UBIN)
	return Rect2(Vector2(lateral_ubin, maju_ubin) - setengah, setengah + setengah)


## True bila dua bentuk beririsan dengan luas (tepi yang hanya bersentuhan = false). Bentuk tidak hingga = false.
static func bertumpuk(a: Rect2, b: Rect2) -> bool:
	if not (a.position.is_finite() and a.size.is_finite() and b.position.is_finite() and b.size.is_finite()):
		return false
	return a.position.x < b.end.x and b.position.x < a.end.x and a.position.y < b.end.y and b.position.y < a.end.y


## True selama jatuh (kecepatan 0, stick dan lemparan diabaikan).
static func jatuh(k: Keadaan) -> bool:
	return k.jatuh_detik > Config.TABRAKAN_TOLERANSI_DETIK


## Lama sejak tabrakan selama jatuh, detik (0 sampai `TABRAKAN_JATUH_DETIK`); 0 bila tidak jatuh. Dipakai pemilih frame sprite jatuh.
static func lewat_jatuh_detik(k: Keadaan) -> float:
	if not jatuh(k):
		return 0.0
	return clampf(Config.TABRAKAN_JATUH_DETIK - k.jatuh_detik, 0.0, Config.TABRAKAN_JATUH_DETIK)


## True selama kebal (sesudah bangun).
static func kebal(k: Keadaan) -> bool:
	return k.kebal_detik > Config.TABRAKAN_TOLERANSI_DETIK


## True bila tidak bisa terjadi tabrakan baru: selama jatuh atau kebal.
static func terlindung(k: Keadaan) -> bool:
	return jatuh(k) or kebal(k)


## Satu langkah `dt` detik: waktu jatuh dan kebal maju (`_majukan_waktu`), lalu bentuk sepeda `kotak_sepeda_ini` diperiksa terhadap
## `daftar` (urut daftar; yang pertama menang). `dt` nol, negatif, atau tidak hingga = tidak ada yang berubah dan tidak ada tabrakan baru (jeda).
static func langkah(k: Keadaan, kotak_sepeda_ini: Rect2, daftar: Array[Kandidat], dt: float) -> Hasil:
	var hasil: Hasil = Hasil.new()
	var s: Keadaan = k.salin()
	hasil.keadaan = s
	if not is_finite(dt) or dt <= 0.0:
		return hasil
	_majukan_waktu(s, dt)
	var kena: Array[Kandidat] = []
	for c: Kandidat in daftar:
		if c != null and bertumpuk(kotak_sepeda_ini, c.kotak):
			kena.append(c)
	var masih: Array[int] = []
	for id: int in s.menempel:
		for c: Kandidat in kena:
			if c.id == id and not masih.has(id):
				masih.append(id)
	s.menempel = masih
	if terlindung(s):
		_tempel(s, kena)
		return hasil
	for c: Kandidat in kena:
		if s.menempel.has(c.id):
			continue
		hasil.tabrak = true
		hasil.id = c.id
		hasil.jenis = c.jenis
		s.jatuh_detik = Config.TABRAKAN_JATUH_DETIK
		s.kebal_detik = 0.0
		s.jumlah += 1
		_tempel(s, kena)
		return hasil
	return hasil


## Keadaan sepeda sesudah tabrakan (jatuh): kecepatan 0, rem padam dan lama tahan rem 0; lateral dan stamina tetap. Masukan tidak diubah.
static func terapkan_ke_sepeda(sepeda: BikeMotion.Keadaan) -> BikeMotion.Keadaan:
	var baru: BikeMotion.Keadaan = sepeda.salin()
	baru.kecepatan_ud = 0.0
	baru.rem_aktif = false
	baru.tahan_rem_detik = 0.0
	return baru


## Alpha sprite pemain selama kebal: kedip `TABRAKAN_KEDIP_ALFA` pada fase ganjil (tiap `TABRAKAN_KEDIP_PERIODE_DETIK` sejak bangun), 1,0
## pada fase genap dan saat tidak kebal (juga selama jatuh: sprite jatuh tampil penuh).
static func alfa_kebal(k: Keadaan) -> float:
	if not kebal(k) or Config.TABRAKAN_KEDIP_PERIODE_DETIK <= 0.0:
		return 1.0
	var fase: int = floori((Config.TABRAKAN_KEBAL_DETIK - k.kebal_detik) / Config.TABRAKAN_KEDIP_PERIODE_DETIK + Config.TABRAKAN_TOLERANSI_DETIK)
	return Config.TABRAKAN_KEDIP_ALFA if posmod(fase, 2) == 1 else 1.0


## Memajukan waktu `dt` (> 0): selama jatuh sisa jatuh berkurang; langkah yang mencapai akhir jatuh (dengan toleransi) menyetel jatuh ke 0
## dan memulai kebal penuh dikurangi sisa waktu langkah sesudah bangun. Tidak jatuh: sisa kebal berkurang.
static func _majukan_waktu(s: Keadaan, dt: float) -> void:
	if s.jatuh_detik > 0.0:
		if dt + Config.TABRAKAN_TOLERANSI_DETIK >= s.jatuh_detik:
			var sesudah_bangun: float = maxf(dt - s.jatuh_detik, 0.0)
			s.jatuh_detik = 0.0
			s.kebal_detik = maxf(Config.TABRAKAN_KEBAL_DETIK - sesudah_bangun, 0.0)
		else:
			s.jatuh_detik -= dt
		return
	s.kebal_detik = maxf(s.kebal_detik - dt, 0.0)


static func _tempel(s: Keadaan, kena: Array[Kandidat]) -> void:
	for c: Kandidat in kena:
		if not s.menempel.has(c.id):
			s.menempel.append(c.id)
