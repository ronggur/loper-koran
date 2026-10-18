class_name MissionManager
extends RefCounted
## Keadaan misi Cari (kucing P1) selama satu rute, logika murni (M-2 sampai M-5, K-3, AC-3 sampai AC-6 run fase4b-misi-kucing, usulan; GDD 10.2 sampai 10.6).
##
## `langkah` memajukan keadaan dari masukan satu langkah waktu (posisi maju dan lateral pemain, kecepatan, jatuh, jeda, dt efektif, dan lemparan
## yang baru mendarat) dan mengembalikan keadaan BARU beserta peristiwa (`TERLIHAT`, `PETUNJUK`, `LANGKAH_SELESAI`, `TERTANGKAP`, `GAGAL`). Tanpa node,
## `Time`, atau RNG (acak ada di `RencanaMisi`); masukan tidak diubah. Ketepatan lemparan, zona, dan skor TIDAK dihitung ulang di sini: lemparan
## datang apa adanya dari `SkorRute.Hasil` / `KoranLempar.Koran` (K-4 run fase3b-rintangan-skor); `ThrowSolver` dan `SkorRute` tetap sumber.
##
## Perilaku:
## - `lihat` (M-2'): kucing titik ke-i ditandai terlihat (`tampil`, peristiwa `TERLIHAT`) begitu pemain maju ke `MISI_TAMPIL_JARAK_UBIN` (atau
##   `MISI_TAMPIL_PETUNJUK_JARAK_UBIN` bila ada petunjuk) sebelum kucing, untuk SEMUA langkah yang belum selesai (tidak menunggu langkah sebelumnya selesai,
##   supaya jarak antar kucing yang pendek tidak memotong jendela terlihat). "Terlihat" di layar = badan kucing utuh di area layar atau penanda tepi layar
##   (`TampilMisi`, dibuktikan dari geometri layar nyata oleh tes). Langkah `lihat` selesai bila pemain maju melewati titik kucing; selalu bisa
##   diselesaikan tanpa keterampilan. Waktu terlihat sedikitnya `MISI_TAMPIL_DETIK_MIN` (+ cadangan) pada `KECEPATAN_NGEBUT_UD`.
## - Petunjuk (M-3, K-3): lemparan tepat ke kotak surat pelanggan (`Lemparan.tepat` dari skor/koran, bukan lemparan bantu) ke rumah di jendela sebuah langkah
##   (`RencanaMisi.Titik.petunjuk_*`; jendela tiap langkah dari rumah titik sebelumnya sampai sebelum rumah titiknya, tidak bertumpuk) yang belum selesai
##   (langkah aktif atau yang berikutnya, jadi kucingnya belum dilewati), SEKALI per langkah. Pelanggan menunjuk ke arah kucing berikutnya, jadi lemparan ke rumah
##   sebelum kucing yang akan datang tetap berguna walau kucing sebelumnya belum dilewati. Memunculkan gelembung teks (`petunjuk_sisa`), isyarat suara, dan
##   membuat kucing langkah itu terlihat lebih awal (`MISI_TAMPIL_PETUNJUK_JARAK_UBIN`, M-3') bila belum ditandai terlihat; bila sudah, hanya teks dan suara.
##   Tambahan waktu terlihat yang nyata hanya bila petunjuk datang sebelum pemain masuk jarak biasa (`MISI_TAMPIL_JARAK_UBIN`) dari kucing.
## - `tangkap` (M-4): pemain dalam `radius_ubin` dari kucing (tepi inklusif) dan kecepatan paling tinggi `MISI_TANGKAP_KECEPATAN_MAKS_UD` (inklusif)
##   selama `lama_berhenti_detik` BERTURUT-TURUT (timer maju hanya dengan dt efektif); keluar radius atau terlalu cepat mengembalikan timer ke 0; saat
##   jatuh (tabrakan) dan saat jeda timer tidak maju dan tidak direset. Tidak ada tombol baru dan tidak ada tangkap otomatis (K-3: mode bantu tidak
##   mengubah apa pun di sini; kecepatan otomatis mode bantu 3,0 u/d di atas ambang, jadi pemain harus melambat sendiri).
## - Gagal (M-5): pemain melewati akhir kavling rumah ke-`batas.rumah` (dihitung dari rumah seberang pertama rute) atau garis akhir rute sebelum selesai.
##   Gagal TIDAK menyentuh koin, tip, skor, atau tenggat: kelas ini tidak punya akses ke semuanya (invarian prinsip 2).
## - Selesai/gagal terjadi tepat sekali (keadaan terminal); sesudahnya hanya timer banner yang berjalan.

enum Status { AKTIF, SELESAI, GAGAL }
enum Peristiwa { TERLIHAT, PETUNJUK, LANGKAH_SELESAI, TERTANGKAP, GAGAL }


## Satu lemparan yang baru mendarat (diisi pemanggil dari `SkorRute.Hasil` dan `KoranLempar.Koran`, apa adanya).
class Lemparan extends RefCounted:
	## `SkorRute.Hasil.tepat`: antaran sah tepat di inti kotak surat (K-4 run 3B).
	var tepat: bool = false
	## `KoranLempar.Koran.bantu`: lemparan tap mode bantu (tidak pernah memberi petunjuk, K-3).
	var bantu: bool = false
	## True bila koran kena kotak surat rumah pelanggan (`ZonaSasaran.Hasil.KOTAK_SURAT`).
	var kotak_pelanggan: bool = false
	## Awal kavling rumah yang kena, jarak maju dari awal rute, ubin.
	var maju_rumah_ubin: float = 0.0


## Masukan satu langkah waktu.
class Masukan extends RefCounted:
	var maju_ubin: float = 0.0
	var lateral_ubin: float = 0.0
	var kecepatan_ud: float = 0.0
	## Pemain sedang jatuh sesudah tabrakan.
	var jatuh: bool = false
	## Game sedang jeda (layar jeda terbuka).
	var jeda: bool = false
	## Lama langkah, detik (dt efektif).
	var dt: float = 0.0
	var lemparan: Array[Lemparan] = []


## Satu peristiwa misi pada langkah ke-`langkah` (indeks titik).
class Kejadian extends RefCounted:
	var jenis: Peristiwa = Peristiwa.TERLIHAT
	var langkah: int = 0


## Keadaan misi. Diganti objek baru tiap langkah, tidak diubah di tempat.
class Keadaan extends RefCounted:
	var rencana: RencanaMisi.Rencana = null
	var status: Status = Status.AKTIF
	## Indeks langkah aktif; sama dengan jumlah titik bila semua langkah selesai.
	var langkah: int = 0
	## Per titik: kucing sudah tampil, petunjuk sudah dipakai.
	var tampil: Array[bool] = []
	var petunjuk: Array[bool] = []
	## Lama berturut-turut memenuhi syarat tangkap pada langkah aktif, detik.
	var timer_detik: float = 0.0
	## Sisa waktu gelembung petunjuk dan banner hasil, detik.
	var petunjuk_sisa: float = 0.0
	var banner_sisa: float = 0.0
	## Berapa langkah `tangkap` sudah selesai.
	var ditangkap: int = 0
	## Rumah seberang yang sudah dilewati (akhir kavling di belakang pemain), batas `batas_rumah`.
	var dilewati: int = 0

	func salin() -> Keadaan:
		var baru: Keadaan = Keadaan.new()
		baru.rencana = rencana
		baru.status = status
		baru.langkah = langkah
		baru.tampil = tampil.duplicate()
		baru.petunjuk = petunjuk.duplicate()
		baru.timer_detik = timer_detik
		baru.petunjuk_sisa = petunjuk_sisa
		baru.banner_sisa = banner_sisa
		baru.ditangkap = ditangkap
		baru.dilewati = dilewati
		return baru


## Hasil satu langkah: keadaan baru dan peristiwanya (urut terjadinya).
class Hasil extends RefCounted:
	var keadaan: Keadaan = null
	var kejadian: Array[Kejadian] = []

	## True bila ada peristiwa jenis `jenis`.
	func ada(jenis: Peristiwa) -> bool:
		for k: Kejadian in kejadian:
			if k.jenis == jenis:
				return true
		return false

	## Berapa peristiwa jenis `jenis`.
	func jumlah(jenis: Peristiwa) -> int:
		var n: int = 0
		for k: Kejadian in kejadian:
			if k.jenis == jenis:
				n += 1
		return n


## Keadaan awal untuk `rencana` (aktif, langkah pertama).
static func awal(rencana: RencanaMisi.Rencana) -> Keadaan:
	var k: Keadaan = Keadaan.new()
	k.rencana = rencana
	var jumlah: int = rencana.titik.size() if rencana != null else 0
	for i: int in range(jumlah):
		k.tampil.append(false)
		k.petunjuk.append(false)
	return k


## Satu langkah waktu. `keadaan` tidak diubah. Timer gelembung dan banner dikurangi dulu (timer yang baru dinyalakan langkah ini tidak langsung berkurang).
static func langkah(keadaan: Keadaan, masukan: Masukan) -> Hasil:
	var hasil: Hasil = Hasil.new()
	var k: Keadaan = keadaan.salin()
	hasil.keadaan = k
	var dt: float = masukan.dt if is_finite(masukan.dt) and masukan.dt > 0.0 and not masukan.jeda else 0.0
	_kurangi_timer(k, dt)
	var r: RencanaMisi.Rencana = k.rencana
	if k.status != Status.AKTIF or r == null or not r.sah() or not is_finite(masukan.maju_ubin):
		return hasil
	_terapkan_petunjuk(k, masukan, hasil)
	_tandai_terlihat(k, masukan, hasil)
	_majukan(k, masukan, dt, hasil)
	if k.status == Status.AKTIF:
		_cek_gagal(k, masukan, hasil)
	_hitung_dilewati(k, masukan.maju_ubin)
	return hasil


# --- Tampilan (dipakai HUD dan gambar; murni) ---

## Kartu misi di HUD tampil selama misi aktif.
static func kartu_tampil(k: Keadaan) -> bool:
	return k != null and k.rencana != null and k.rencana.sah() and k.status == Status.AKTIF


## Banner hasil tampil sesudah selesai atau gagal selama `MISI_BANNER_DETIK`.
static func banner_tampil(k: Keadaan) -> bool:
	return k != null and k.status != Status.AKTIF and k.banner_sisa > 0.0


## Gelembung petunjuk dari pelanggan tampil.
static func petunjuk_tampil(k: Keadaan) -> bool:
	return k != null and k.status == Status.AKTIF and k.petunjuk_sisa > 0.0


## Indeks titik kucing yang digambar saat ini, atau -1: kucing langkah aktif bila sudah tampil dan misi masih aktif.
static func kucing_tampil(k: Keadaan) -> int:
	if k == null or k.status != Status.AKTIF or k.rencana == null or k.langkah >= k.rencana.titik.size():
		return -1
	return k.langkah if k.tampil[k.langkah] else -1


## Indeks titik yang ditandai terlihat tetapi belum selesai (urut naik), selama misi aktif. Kucing langkah aktif ada di sini bila sudah ditandai; HUD
## memasang penanda tepi layar untuk tiap indeks yang badannya belum utuh di layar (`TampilMisi`), dan hanya kucing langkah aktif yang digambar sebagai badan.
static func indeks_terlihat(k: Keadaan) -> Array[int]:
	var hasil: Array[int] = []
	if k == null or k.status != Status.AKTIF or k.rencana == null:
		return hasil
	for i: int in range(k.langkah, k.rencana.titik.size()):
		if k.tampil[i]:
			hasil.append(i)
	return hasil


## Titik kucing yang digambar saat ini, atau null.
static func titik_tampil(k: Keadaan) -> RencanaMisi.Titik:
	var i: int = kucing_tampil(k)
	return k.rencana.titik[i] if i >= 0 else null


## Sisa rumah sebelum batas (HUD "N rumah"): `batas_rumah` dikurangi rumah seberang yang sudah dilewati, tidak kurang dari 0.
static func sisa_rumah(k: Keadaan) -> int:
	if k == null or k.rencana == null:
		return 0
	return maxi(k.rencana.batas_rumah - k.dilewati, 0)


## Jumlah yang sudah ditemukan dan jumlah target (HUD "0/1").
static func ditemukan(k: Keadaan) -> Vector2i:
	if k == null or k.rencana == null:
		return Vector2i.ZERO
	return Vector2i(k.ditangkap, k.rencana.target)


## Hasil misi sebagai teks untuk simpanan dan layar hasil: "" (masih aktif atau tidak ada misi), `selesai`, atau `gagal`.
static func nama_hasil(k: Keadaan) -> String:
	if k == null:
		return ""
	if k.status == Status.SELESAI:
		return "selesai"
	if k.status == Status.GAGAL:
		return "gagal"
	return ""


## Koin misi yang dibayar: hadiah rencana bila SELESAI, 0 selainnya (gagal tidak pernah membayar atau mengurangi, K-1).
static func koin_misi(k: Keadaan) -> int:
	if k == null or k.rencana == null or k.status != Status.SELESAI:
		return 0
	return k.rencana.hadiah_koin


## Flag lanjutan yang ditulis misi `misi` untuk hasil `hasil` ("selesai" atau "gagal"); "" untuk hasil lain.
static func flag_hasil(misi: DataMisi, hasil: String) -> String:
	if misi == null:
		return ""
	if hasil == "selesai":
		return misi.flag_selesai
	if hasil == "gagal":
		return misi.flag_gagal
	return ""


## Jarak maju kucing mulai terlihat, ubin: `MISI_TAMPIL_PETUNJUK_JARAK_UBIN` bila langkah ini sudah dapat petunjuk, selain itu `MISI_TAMPIL_JARAK_UBIN`.
static func jarak_tampil(petunjuk_dipakai: bool) -> float:
	return Config.MISI_TAMPIL_PETUNJUK_JARAK_UBIN if petunjuk_dipakai else Config.MISI_TAMPIL_JARAK_UBIN


## Lama kucing terlihat sebelum pemain sejajar dengannya pada kecepatan `kecepatan_ud`, detik (jarak tampil / kecepatan). Tak hingga bila diam.
static func detik_tampil(kecepatan_ud: float, petunjuk_dipakai: bool = false) -> float:
	if not is_finite(kecepatan_ud) or kecepatan_ud <= 0.0:
		return INF
	return jarak_tampil(petunjuk_dipakai) / kecepatan_ud


## Lama tampil terpendek: pada `KECEPATAN_NGEBUT_UD` tanpa petunjuk (kasus terburuk, M-2).
static func detik_tampil_min() -> float:
	return detik_tampil(Config.KECEPATAN_NGEBUT_UD, false)


# --- Dalam ---

static func _terapkan_petunjuk(k: Keadaan, m: Masukan, hasil: Hasil) -> void:
	for l: Lemparan in m.lemparan:
		if not l.tepat or l.bantu or not l.kotak_pelanggan:
			continue
		for i: int in range(k.langkah, k.rencana.titik.size()):
			var t: RencanaMisi.Titik = k.rencana.titik[i]
			if l.maju_rumah_ubin < t.petunjuk_awal_ubin or l.maju_rumah_ubin >= t.petunjuk_akhir_ubin:
				continue
			# Jendela tiap langkah tidak bertumpuk, jadi satu rumah hanya milik satu langkah; langkah yang sudah lewat tidak dihitung.
			if not k.petunjuk[i]:
				k.petunjuk[i] = true
				k.petunjuk_sisa = Config.MISI_PETUNJUK_DETIK
				_catat(hasil, Peristiwa.PETUNJUK, i)
			break


## Menandai terlihat tiap langkah yang belum selesai bila pemain sudah masuk jaraknya (M-2'): tidak menunggu langkah sebelumnya selesai, jadi jarak antar
## kucing yang pendek (sampai 11,5 ubin) tidak memotong jendela terlihat.
static func _tandai_terlihat(k: Keadaan, m: Masukan, hasil: Hasil) -> void:
	for i: int in range(k.langkah, k.rencana.titik.size()):
		if not k.tampil[i] and m.maju_ubin >= k.rencana.titik[i].maju_ubin - jarak_tampil(k.petunjuk[i]):
			k.tampil[i] = true
			_catat(hasil, Peristiwa.TERLIHAT, i)


## Memajukan langkah aktif (bisa beberapa langkah `lihat` sekaligus bila pemain meloncat jauh). Kucing langkah aktif sudah ditandai terlihat
## (`_tandai_terlihat`): jarak tampil selalu lebih besar dari nol, jadi pemain yang tiba di titik kucing pasti sudah masuk jarak tampilnya.
static func _majukan(k: Keadaan, m: Masukan, dt: float, hasil: Hasil) -> void:
	var jumlah: int = k.rencana.titik.size()
	while k.status == Status.AKTIF and k.langkah < jumlah:
		var i: int = k.langkah
		var t: RencanaMisi.Titik = k.rencana.titik[i]
		if t.jenis == "lihat":
			if m.maju_ubin < t.maju_ubin:
				return
			_selesaikan_langkah(k, hasil, i)
			continue
		_tangkap(k, t, m, dt, hasil, i)
		return


static func _tangkap(k: Keadaan, t: RencanaMisi.Titik, m: Masukan, dt: float, hasil: Hasil, i: int) -> void:
	if m.jatuh or m.jeda:
		return
	var jarak: float = Vector2(m.lateral_ubin, m.maju_ubin).distance_to(Vector2(t.lateral_ubin, t.maju_ubin))
	var dalam: bool = is_finite(jarak) and jarak <= t.radius_ubin
	var pelan: bool = is_finite(m.kecepatan_ud) and m.kecepatan_ud <= Config.MISI_TANGKAP_KECEPATAN_MAKS_UD + Config.MISI_TANGKAP_TOLERANSI
	if dalam and pelan:
		k.timer_detik += dt
	else:
		k.timer_detik = 0.0
	if k.timer_detik + Config.MISI_TANGKAP_TOLERANSI < t.lama_berhenti_detik:
		return
	k.ditangkap += 1
	_catat(hasil, Peristiwa.TERTANGKAP, i)
	_selesaikan_langkah(k, hasil, i)


static func _selesaikan_langkah(k: Keadaan, hasil: Hasil, i: int) -> void:
	_catat(hasil, Peristiwa.LANGKAH_SELESAI, i)
	k.langkah += 1
	k.timer_detik = 0.0
	if k.langkah >= k.rencana.titik.size():
		k.status = Status.SELESAI
		k.banner_sisa = Config.MISI_BANNER_DETIK
		k.petunjuk_sisa = 0.0


static func _cek_gagal(k: Keadaan, m: Masukan, hasil: Hasil) -> void:
	var r: RencanaMisi.Rencana = k.rencana
	if m.maju_ubin >= r.maju_batas_ubin or m.maju_ubin >= r.panjang_ubin:
		k.status = Status.GAGAL
		k.banner_sisa = Config.MISI_BANNER_DETIK
		k.petunjuk_sisa = 0.0
		_catat(hasil, Peristiwa.GAGAL, mini(k.langkah, r.titik.size() - 1))


static func _hitung_dilewati(k: Keadaan, maju: float) -> void:
	var n: int = 0
	for akhir: float in k.rencana.akhir_kavling_ubin:
		if akhir <= maju:
			n += 1
	k.dilewati = maxi(k.dilewati, n)


## Mengurangi timer gelembung dan banner dengan `dt` efektif (0 saat jeda, jadi membeku).
static func _kurangi_timer(k: Keadaan, dt: float) -> void:
	if dt <= 0.0:
		return
	k.petunjuk_sisa = maxf(k.petunjuk_sisa - dt, 0.0)
	k.banner_sisa = maxf(k.banner_sisa - dt, 0.0)


static func _catat(hasil: Hasil, jenis: Peristiwa, langkah_ke: int) -> void:
	var kejadian: Kejadian = Kejadian.new()
	kejadian.jenis = jenis
	kejadian.langkah = langkah_ke
	hasil.kejadian.append(kejadian)
