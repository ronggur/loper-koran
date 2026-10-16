class_name Tabrakan
extends RefCounted
## Aturan tabrakan sepeda dengan rintangan, logika murni (BALANCING 6, K-1 dan AC-6 run fase3b-rintangan-skor, usulan).
##
## Bentuk = persegi di bidang tanah (koordinat jalan: x = lateral, y = maju, ubin). Dua bentuk bertabrakan bila irisannya berluas (tepi
## yang hanya bersentuhan tidak dihitung). Satu tabrakan:
## - kecepatan sepeda langsung turun ke `TABRAKAN_KECEPATAN_UD` bila lebih tinggi (`terapkan_ke_sepeda`), stamina tidak dihukum;
## - oleng `TABRAKAN_OLENG_DETIK`: selama oleng kecepatan tidak bisa naik (`oleng` -> `BikeMotion.langkah(..., tahan_naik)`), lateral dan
##   lemparan tetap bisa;
## - kebal `TABRAKAN_KEBAL_DETIK` dihitung dari saat tabrakan: tidak ada tabrakan kedua dari rintangan mana pun;
## - combo putus (`SkorRute.putus_combo`, dipanggil pemilik) dan rute tidak berhenti (prinsip 2).
## Tanpa tabrakan ganda: rintangan yang sudah bersentuhan dengan sepeda saat tabrakan atau selama kebal ("menempel") tidak memicu
## tabrakan lagi sampai sepeda terpisah darinya, jadi sepeda yang melewati mobil yang ditabraknya tidak tertabrak berulang sesudah
## kebal habis. Waktu ikut `dt` (jeda = 0, membeku). Masukan tidak diubah.


## Satu rintangan yang bisa ditabrak langkah ini.
class Kandidat extends RefCounted:
	var id: int = 0
	## Jenis dari data segmen (`anjing_penjaga`, `mobil_garasi`), dibawa ke peristiwa tabrakan (AC-8).
	var jenis: String = ""
	var kotak: Rect2 = Rect2()


## Keadaan tabrakan sepeda.
class Keadaan extends RefCounted:
	## Sisa oleng, detik.
	var oleng_detik: float = 0.0
	## Sisa kebal, detik.
	var kebal_detik: float = 0.0
	## Id rintangan yang masih bersentuhan sejak tabrakan atau selama kebal.
	var menempel: Array[int] = []
	## Jumlah tabrakan sejak awal rute.
	var jumlah: int = 0

	func salin() -> Keadaan:
		var baru: Keadaan = Keadaan.new()
		baru.oleng_detik = oleng_detik
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


## True selama oleng (kecepatan tidak bisa naik).
static func oleng(k: Keadaan) -> bool:
	return k.oleng_detik > Config.TABRAKAN_TOLERANSI_DETIK


## True selama kebal.
static func kebal(k: Keadaan) -> bool:
	return k.kebal_detik > Config.TABRAKAN_TOLERANSI_DETIK


## Satu langkah `dt` detik: sisa oleng dan kebal berkurang, lalu bentuk sepeda `kotak_sepeda_ini` diperiksa terhadap `daftar` (urut
## daftar; yang pertama menang). `dt` nol, negatif, atau tidak hingga = tidak ada yang berubah dan tidak ada tabrakan baru (jeda).
static func langkah(k: Keadaan, kotak_sepeda_ini: Rect2, daftar: Array[Kandidat], dt: float) -> Hasil:
	var hasil: Hasil = Hasil.new()
	var s: Keadaan = k.salin()
	hasil.keadaan = s
	if not is_finite(dt) or dt <= 0.0:
		return hasil
	s.oleng_detik = maxf(s.oleng_detik - dt, 0.0)
	s.kebal_detik = maxf(s.kebal_detik - dt, 0.0)
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
	if kebal(s):
		_tempel(s, kena)
		return hasil
	for c: Kandidat in kena:
		if s.menempel.has(c.id):
			continue
		hasil.tabrak = true
		hasil.id = c.id
		hasil.jenis = c.jenis
		s.oleng_detik = Config.TABRAKAN_OLENG_DETIK
		s.kebal_detik = Config.TABRAKAN_KEBAL_DETIK
		s.jumlah += 1
		_tempel(s, kena)
		return hasil
	return hasil


## Keadaan sepeda sesudah tabrakan: kecepatan turun ke `TABRAKAN_KECEPATAN_UD` bila lebih tinggi; lateral, stamina, dan rem tetap.
## Masukan tidak diubah.
static func terapkan_ke_sepeda(sepeda: BikeMotion.Keadaan) -> BikeMotion.Keadaan:
	var baru: BikeMotion.Keadaan = sepeda.salin()
	baru.kecepatan_ud = minf(baru.kecepatan_ud, Config.TABRAKAN_KECEPATAN_UD)
	return baru


static func _tempel(s: Keadaan, kena: Array[Kandidat]) -> void:
	for c: Kandidat in kena:
		if not s.menempel.has(c.id):
			s.menempel.append(c.id)
