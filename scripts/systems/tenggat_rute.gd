class_name TenggatRute
extends RefCounted
## Tenggat rute, logika murni dan satu sumber (GDD 5.1, BALANCING 6; K-1 dan AC-1 run fase3c-hud-hasil, usulan).
##
## - Tenggat (detik bulat) = ceil(panjang rute / `KECEPATAN_SANTAI_UD` x `TENGGAT_PENGALI`), dihitung dari rute, bukan angka tetap.
##   Pembulatan ke atas memakai toleransi `TENGGAT_TOLERANSI_DETIK`, jadi 240 / 3,0 x 1,15 = 92,0 tetap 92 walau derau float membuatnya
##   sedikit di atas 92 (232 -> 89, 236 -> 91, 240 -> 92).
## - Jam (`waktu_detik`) maju dengan `dt` efektif (0 saat jeda atau background: beku, rule `gdscript`) dan berhenti di garis akhir
##   (`hentikan`; langkah yang mencapai garis masih dihitung).
## - Lewat = waktu LEBIH dari tenggat (lebih dari toleransi): tepat di tenggat (sisa 0) BELUM lewat. Sesudah lewat rute tetap berjalan;
##   satu-satunya konsekuensi adalah tip hilang (`SkorRute.nilai`, K-1), tanpa potong koin dan tanpa game over (prinsip 2).
## - Tampilan: sisa (sebelum lewat) atau detik lewat (sesudahnya) dibulatkan ke atas ke detik bulat (`detik_tampil`), dipecah ke menit dan
##   detik (`menit_detik`). Teksnya disusun UI lewat kunci terjemahan.
## Tanpa node, `Time`, atau RNG; masukan tidak diubah.


## Keadaan jam tenggat satu rute.
class Keadaan extends RefCounted:
	## Tenggat rute ini, detik bulat (`detik_tenggat`).
	var tenggat_detik: int = 0
	## Waktu sejak rute dimulai (dt efektif), detik.
	var waktu_detik: float = 0.0
	## True sesudah garis akhir: jam tidak maju lagi.
	var berhenti: bool = false

	func salin() -> Keadaan:
		var baru: Keadaan = Keadaan.new()
		baru.tenggat_detik = tenggat_detik
		baru.waktu_detik = waktu_detik
		baru.berhenti = berhenti
		return baru


## Tenggat (detik bulat) untuk rute sepanjang `panjang_ubin`. Panjang tidak positif atau tidak hingga = 0.
static func detik_tenggat(panjang_ubin: float) -> int:
	if not is_finite(panjang_ubin) or panjang_ubin <= 0.0 or Config.KECEPATAN_SANTAI_UD <= 0.0:
		return 0
	var detik: float = panjang_ubin / Config.KECEPATAN_SANTAI_UD * Config.TENGGAT_PENGALI
	return maxi(ceili(detik - Config.TENGGAT_TOLERANSI_DETIK), 0)


## Keadaan awal untuk rute sepanjang `panjang_ubin`: jam 0, belum berhenti.
static func awal(panjang_ubin: float) -> Keadaan:
	var k: Keadaan = Keadaan.new()
	k.tenggat_detik = detik_tenggat(panjang_ubin)
	return k


## Keadaan sesudah `dt` detik efektif. `dt` nol, negatif, atau tidak hingga, atau jam sudah berhenti = tidak berubah.
static func langkah(k: Keadaan, dt: float) -> Keadaan:
	var baru: Keadaan = k.salin()
	if not baru.berhenti and is_finite(dt) and dt > 0.0:
		baru.waktu_detik += dt
	return baru


## Keadaan dengan jam berhenti (garis akhir tercapai). Waktu tidak berubah.
static func hentikan(k: Keadaan) -> Keadaan:
	var baru: Keadaan = k.salin()
	baru.berhenti = true
	return baru


## True bila waktu sudah LEBIH dari tenggat (lebih dari `TENGGAT_TOLERANSI_DETIK`). Tepat di tenggat = belum lewat.
static func lewat(k: Keadaan) -> bool:
	return k.waktu_detik > float(k.tenggat_detik) + Config.TENGGAT_TOLERANSI_DETIK


## Sisa waktu sampai tenggat, detik (0 bila sudah lewat; tidak pernah negatif).
static func sisa_detik(k: Keadaan) -> float:
	return maxf(float(k.tenggat_detik) - k.waktu_detik, 0.0)


## Lama sesudah tenggat lewat, detik (0 bila belum lewat).
static func detik_lewat(k: Keadaan) -> float:
	if not lewat(k):
		return 0.0
	return k.waktu_detik - float(k.tenggat_detik)


## Detik bulat yang ditampilkan: sisa sebelum lewat, detik lewat sesudahnya, keduanya dibulatkan ke atas (toleransi derau float). Awal
## rute = tenggat penuh; tepat di tenggat = 0; 0,01 detik sesudah lewat = 1.
static func detik_tampil(k: Keadaan) -> int:
	var nilai: float = detik_lewat(k) if lewat(k) else sisa_detik(k)
	return maxi(ceili(nilai - Config.TENGGAT_TOLERANSI_DETIK), 0)


## Detik bulat `detik` dipecah ke menit dan detik (x = menit, y = detik 0..59) untuk teks "m:ss". Negatif = 0.
static func menit_detik(detik: int) -> Vector2i:
	var n: int = maxi(detik, 0)
	return Vector2i(n / Config.WAKTU_DETIK_PER_MENIT, n % Config.WAKTU_DETIK_PER_MENIT)
