class_name Bel
extends RefCounted
## Bel sepeda "Kring Kring!", logika murni (GDD 5.4, DESIGN_SPEC 3.8, SOUND_DESIGN 3.3; K-3, AC-14, AC-17 run fase3b-rintangan-skor, usulan).
##
## Ketukan (`ketuk`) dibaca dari tombol bel oleh pemanggil (input dipisah dari logika):
## - ketukan pertama = `KRING`, teks "KRING!" tampil `BEL_TEKS_DETIK`;
## - ketukan kedua selama teks masih tampil = `KRING_KRING` (teks berganti "KRING KRING!"), lalu bel jeda `BEL_JEDA_DETIK`; sisa jeda bisa
##   dibaca sebagai pecahan untuk cincin tombol (`sisa_jeda_pecahan`);
## - ketukan selama jeda bel, atau saat jeda game, = `TOLAK` (tanpa bunyi, tanpa reaksi);
## - "kring" tunggal yang teksnya sudah habis tidak memulai jeda: ketukan berikutnya `KRING` lagi (GDD 5.4: jeda sesudah dua bunyi).
## Waktu ikut `dt` efektif (`JedaSim`), jadi jeda game membekukan teks dan jeda bel (AC-17).
##
## Reaksi dunia (K-3): rintangan dalam jangkauan (`dalam_jangkauan`: dari `BEL_JANGKAUAN_BELAKANG_UBIN` di belakang sampai
## `BEL_JANGKAUAN_UBIN` di depan sepeda, seluruh lebar jalan) bereaksi menurut SATU tabel per jenis (`REAKSI_JENIS`), bukan `if` per entitas:
## anjing penjaga mundur ke halamannya (hanya bila waspada atau mengejar, `AnjingPenjaga.bisa_dengar_bel`), mobil tidak bereaksi. Jenis
## baru (mis. pejalan kaki yang menepi) cukup ditambah ke tabel dan ke penerap reaksinya (`RintanganRute.terapkan_bel`).

enum Bunyi { TOLAK, KRING, KRING_KRING }
## Reaksi rintangan pada bel.
enum Reaksi { TIDAK_ADA, MUNDUR }

## Reaksi per jenis rintangan (nama jenis di data segmen, DATA_SCHEMA 3). Jenis yang tidak ada di tabel = `TIDAK_ADA`.
const REAKSI_JENIS: Dictionary = {
	"anjing_penjaga": Reaksi.MUNDUR,
	"mobil_garasi": Reaksi.TIDAK_ADA,
}


## Keadaan bel.
class Keadaan extends RefCounted:
	## Sisa waktu teks "KRING!" / "KRING KRING!" tampil, detik.
	var teks_detik: float = 0.0
	## True bila teks yang tampil "KRING KRING!".
	var dobel: bool = false
	## Sisa jeda bel, detik.
	var jeda_detik: float = 0.0
	## Jumlah bunyi yang diterima sejak awal rute.
	var jumlah: int = 0

	func salin() -> Keadaan:
		var baru: Keadaan = Keadaan.new()
		baru.teks_detik = teks_detik
		baru.dobel = dobel
		baru.jeda_detik = jeda_detik
		baru.jumlah = jumlah
		return baru


## Hasil satu ketukan.
class Hasil extends RefCounted:
	var keadaan: Keadaan = null
	var bunyi: Bunyi = Bunyi.TOLAK


static func awal() -> Keadaan:
	return Keadaan.new()


## Satu ketukan tombol bel. `jeda_game` true = ditolak (AC-17). Masukan tidak diubah.
static func ketuk(k: Keadaan, jeda_game: bool) -> Hasil:
	var hasil: Hasil = Hasil.new()
	var s: Keadaan = k.salin()
	hasil.keadaan = s
	if jeda_game or sedang_jeda(s):
		return hasil
	if teks_tampil(s) and not s.dobel:
		hasil.bunyi = Bunyi.KRING_KRING
		s.dobel = true
		s.jeda_detik = Config.BEL_JEDA_DETIK
	else:
		hasil.bunyi = Bunyi.KRING
		s.dobel = false
	s.teks_detik = Config.BEL_TEKS_DETIK
	s.jumlah += 1
	return hasil


## Satu langkah `dt` detik (dt efektif: 0 selama jeda game = membeku). Masukan tidak diubah.
static func langkah(k: Keadaan, dt: float) -> Keadaan:
	var s: Keadaan = k.salin()
	if not is_finite(dt) or dt <= 0.0:
		return s
	s.teks_detik = maxf(s.teks_detik - dt, 0.0)
	s.jeda_detik = maxf(s.jeda_detik - dt, 0.0)
	if not teks_tampil(s):
		s.teks_detik = 0.0
		s.dobel = false
	if not sedang_jeda(s):
		s.jeda_detik = 0.0
	return s


## True selama teks bel tampil.
static func teks_tampil(k: Keadaan) -> bool:
	return k.teks_detik > Config.TABRAKAN_TOLERANSI_DETIK


## True selama jeda bel (ketukan ditolak).
static func sedang_jeda(k: Keadaan) -> bool:
	return k.jeda_detik > Config.TABRAKAN_TOLERANSI_DETIK


## Sisa jeda sebagai pecahan 1 (baru mulai) sampai 0 (selesai), untuk cincin tombol (DESIGN_SPEC 3.8).
static func sisa_jeda_pecahan(k: Keadaan) -> float:
	if not sedang_jeda(k) or Config.BEL_JEDA_DETIK <= 0.0:
		return 0.0
	return clampf(k.jeda_detik / Config.BEL_JEDA_DETIK, 0.0, 1.0)


## True bila rintangan di maju `objek_maju` ada dalam jangkauan bel sepeda di maju `sepeda_maju` (inklusif di kedua ujung).
static func dalam_jangkauan(sepeda_maju: float, objek_maju: float) -> bool:
	if not is_finite(sepeda_maju) or not is_finite(objek_maju):
		return false
	var selisih: float = objek_maju - sepeda_maju
	return selisih >= -Config.BEL_JANGKAUAN_BELAKANG_UBIN and selisih <= Config.BEL_JANGKAUAN_UBIN


## Reaksi jenis rintangan `jenis` (nama data) pada bel, dari `REAKSI_JENIS`.
static func reaksi(jenis: String) -> Reaksi:
	return REAKSI_JENIS.get(jenis, Reaksi.TIDAK_ADA)


## True bila ketukan menghasilkan bunyi (bukan `TOLAK`).
static func berbunyi(bunyi: Bunyi) -> bool:
	return bunyi != Bunyi.TOLAK
