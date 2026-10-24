class_name AkhirRute
extends RefCounted
## Akhir rute, logika murni (AC-14 run fase3a-rute, K-5, usulan): garis akhir tercapai tepat sekali, lalu sepeda direm dan input dikunci.
##
## Garis akhir = panjang rute (`RouteBuilder.Rute.panjang_ubin`). Bila jarak tempuh sepeda mencapainya (inklusif) rute selesai; sesudah
## itu `periksa` tidak pernah melaporkan `baru_selesai` lagi sampai rute disusun ulang (pemanggil memulai dari `sudah_selesai` false).
## Rem sesudah garis akhir memakai stick buatan `stick_akhir` (tarik penuh ke bawah) lewat `BikeMotion` biasa, jadi laju rem dan pose
## rem sama dengan rem pemain (`REM_PERLAMBATAN_UD2`); stick sungguhan tidak dibaca lagi (dikunci). Tanpa node, `Time`, atau RNG.
##
## Garis finish dengan portal (run garis-finish-portal bagian B, G-2 sampai G-5, usulan): sesudah garis akhir sepeda TIDAK direm, melainkan melaju
## lurus keluar viewport. Tambahan di berkas ini (kontrak lama `periksa`, `Status`, `tercapai`, `stick_akhir` tidak berubah):
## - Fase (`Fase`): SEBELUM garis, MELAJU_KELUAR (garis tercapai, sepeda belum seluruhnya di luar viewport), SUDAH_KELUAR. Hanya maju (`periksa_keluar`).
## - Gerak: `stick_keluar` (lurus penuh, tanpa belok) dan laju minimum `RUTE_KELUAR_LAJU_MIN_UD` (`laju_dijaga`, `keadaan_dijaga`).
## - Keluar viewport dari geometri nyata, bukan waktu: titik pijak sepeda di layar (`posisi_layar_pijak`, `posisi_layar`), kotak badan
##   `RUTE_KELUAR_BADAN_KIRI_PX` dan `RUTE_KELUAR_BADAN_BAWAH_PX`, dan arah maju dari `Iso` (naik ke kanan atas). `sisa_ubin_keluar` = ubin yang masih harus ditempuh sampai seluruh badan di luar
##   tepi kanan atau tepi atas viewport (mana lebih dulu); "hampir keluar" (sinyal banner) bila sisa <= `RUTE_KELUAR_HAMPIR_UBIN`.
## - Kamera berhenti mengikuti di garis akhir: `posisi_kamera` adalah fungsi murni dari posisi sepeda saat garis tercapai.
## - Portal (`portal_terbuka`): terbuka mulai `RUTE_PORTAL_BUKA_JARAK_UBIN` sebelum garis akhir dan seterusnya.
## Semuanya hanya geometri dan gerak: tidak menyentuh `SkorRute`, `TenggatRute`, `ProgresRute`, `KondisiRute`, atau save (G-5).


## Hasil satu pemeriksaan garis akhir.
class Status extends RefCounted:
	## True sejak garis akhir tercapai (tetap true sesudahnya).
	var selesai: bool = false
	## True hanya pada pemeriksaan yang pertama kali mencapai garis akhir (sinyal `rute_selesai` tepat sekali).
	var baru_selesai: bool = false


## True bila `jarak_ubin` sudah mencapai `panjang_ubin` (inklusif). Panjang tidak positif atau masukan tidak hingga = false.
static func tercapai(jarak_ubin: float, panjang_ubin: float) -> bool:
	if not is_finite(jarak_ubin) or not is_finite(panjang_ubin) or panjang_ubin <= 0.0:
		return false
	return jarak_ubin >= panjang_ubin


## Status sesudah memeriksa `jarak_ubin` terhadap `panjang_ubin`, dari status `sudah_selesai` sebelumnya.
static func periksa(sudah_selesai: bool, jarak_ubin: float, panjang_ubin: float) -> Status:
	var status: Status = Status.new()
	if sudah_selesai:
		status.selesai = true
		return status
	if tercapai(jarak_ubin, panjang_ubin):
		status.selesai = true
		status.baru_selesai = true
	return status


## Vektor stick yang diberikan ke sepeda sesudah garis akhir: lurus ke bawah, penuh (rem).
static func stick_akhir() -> Vector2:
	return Vector2(0.0, Config.RUTE_AKHIR_STICK_Y)


## Fase perjalanan sepeda terhadap garis akhir. Hanya maju (nilai naik): SEBELUM -> MELAJU_KELUAR -> SUDAH_KELUAR.
enum Fase { SEBELUM, MELAJU_KELUAR, SUDAH_KELUAR }


## Hasil satu pemeriksaan keluar viewport (`periksa_keluar`).
class Keluar extends RefCounted:
	## Fase sesudah pemeriksaan (tidak pernah di bawah fase lama).
	var fase: Fase = Fase.SEBELUM
	## True sejak sepeda hampir keluar (sisa <= `RUTE_KELUAR_HAMPIR_UBIN`) sesudah garis akhir; tetap true sesudahnya.
	var hampir_keluar: bool = false
	## True hanya pada pemeriksaan yang pertama kali menjadi hampir keluar (sinyal banner, tepat sekali).
	var baru_hampir_keluar: bool = false
	## True hanya pada pemeriksaan yang pertama kali menjadi SUDAH_KELUAR (tepat sekali).
	var baru_keluar: bool = false
	## Sisa ubin sampai seluruh badan keluar viewport (0 bila sudah; tak hingga bila masukan tidak sah).
	var sisa_ubin: float = INF


## Vektor stick yang diberikan ke sepeda sesudah garis akhir (menggantikan `stick_akhir` di scene rute): lurus ke depan penuh, tanpa belok.
static func stick_keluar() -> Vector2:
	return Vector2(0.0, Config.RUTE_KELUAR_STICK_Y)


## Laju `laju_ud` dinaikkan ke `RUTE_KELUAR_LAJU_MIN_UD` bila di bawahnya (NaN dan negatif = laju minimum). Laju yang lebih tinggi tidak berubah.
static func laju_dijaga(laju_ud: float) -> float:
	if is_nan(laju_ud):
		return Config.RUTE_KELUAR_LAJU_MIN_UD
	return maxf(laju_ud, Config.RUTE_KELUAR_LAJU_MIN_UD)


## Salinan keadaan gerak dengan kecepatan sudah dijaga (`laju_dijaga`); bagian lain sama. Dipanggil sebelum `BikeMotion.langkah` sesudah garis akhir.
## Tujuan stick lurus penuh tidak pernah di bawah laju minimum, jadi kecepatan keluaran langkah juga tidak turun di bawahnya. Keadaan null = keadaan awal.
static func keadaan_dijaga(keadaan: BikeMotion.Keadaan) -> BikeMotion.Keadaan:
	var baru: BikeMotion.Keadaan = keadaan.salin() if keadaan != null else BikeMotion.Keadaan.new()
	baru.kecepatan_ud = laju_dijaga(baru.kecepatan_ud)
	return baru


## Satu langkah gerak sesudah garis akhir: keadaan dijaga, stick `stick_keluar`, lewat `BikeMotion.langkah` biasa (rem tidak pernah aktif).
## `beku_detik` dan `efek` diteruskan apa adanya (jatuh sesudah tabrakan, efek kondisi).
static func langkah_keluar(keadaan: BikeMotion.Keadaan, dt: float, beku_detik: float = 0.0, efek: EfekKondisi = null) -> BikeMotion.Hasil:
	return BikeMotion.langkah(keadaan_dijaga(keadaan), stick_keluar(), dt, beku_detik, efek)


## Titik pijak sepeda di layar (koordinat viewport game) saat kamera mengikuti: sasaran `KAMERA_SEPEDA_*_PECAHAN` dari ukuran viewport ditambah
## geseran dorongan kecepatan `geser_dorongan` (float, tanpa pembulatan; posisi nyata berbeda paling jauh setengah piksel karena kamera dibulatkan).
static func posisi_layar_pijak(ukuran: Vector2, geser_dorongan: Vector2) -> Vector2:
	return Vector2(ukuran.x * Config.KAMERA_SEPEDA_X_PECAHAN, ukuran.y * Config.KAMERA_SEPEDA_Y_PECAHAN) + geser_dorongan


## Posisi kamera yang menaruh sepeda di `posisi_layar_pijak`, dibulatkan ke piksel. `posisi_sepeda` = posisi gambar sepeda di dunia (piksel game).
## Rumus yang sama dengan `AdeganJalan.posisi_kamera`. Sesudah garis akhir nilai ini dihitung SEKALI (posisi sepeda dan geseran saat garis tercapai)
## dan dibekukan: kamera tidak bergeser lagi.
static func posisi_kamera(posisi_sepeda: Vector2, ukuran: Vector2, geser_dorongan: Vector2) -> Vector2:
	return (posisi_sepeda + ukuran / 2 - posisi_layar_pijak(ukuran, geser_dorongan)).round()


## Titik pijak sepeda di layar (koordinat viewport game) untuk kamera di `kamera` (bisa beku). Sama dengan `AdeganJalan.posisi_layar_sepeda`.
static func posisi_layar(posisi_sepeda: Vector2, kamera: Vector2, ukuran: Vector2) -> Vector2:
	return posisi_sepeda - kamera + ukuran / 2


## Ubin sepanjang jalan yang masih harus ditempuh dari pijak di layar `posisi_layar_pijak` sampai SELURUH badan (`RUTE_KELUAR_BADAN_KIRI_PX` dan `RUTE_KELUAR_BADAN_BAWAH_PX`) berada di luar
## viewport berukuran `ukuran`: yang lebih dulu antara tepi kanan (sisi kiri badan melewati tepi) dan tepi atas (sisi bawah badan melewati tepi), karena maju
## = naik ke kanan atas (`Iso.ARAH_MAJU`). 0 bila sudah di luar (menyentuh tepi tanpa piksel terlihat dihitung di luar). Masukan tidak hingga atau ukuran
## tidak positif = tak hingga (tidak pernah dianggap keluar).
static func sisa_ubin_keluar(posisi_layar_pijak_px: Vector2, ukuran: Vector2) -> float:
	if not posisi_layar_pijak_px.is_finite() or not ukuran.is_finite() or ukuran.x <= 0.0 or ukuran.y <= 0.0:
		return INF
	var maju_px: Vector2 = Iso.dunia_ke_layar(Iso.ARAH_MAJU)
	var kiri_px: float = float(Config.RUTE_KELUAR_BADAN_KIRI_PX)
	var bawah_px: float = float(Config.RUTE_KELUAR_BADAN_BAWAH_PX)
	var sampai_kanan: float = (ukuran.x - (posisi_layar_pijak_px.x - kiri_px)) / maju_px.x
	var sampai_atas: float = (posisi_layar_pijak_px.y + bawah_px) / -maju_px.y
	return maxf(minf(sampai_kanan, sampai_atas), 0.0)


## True bila `sisa_ubin` (dari `sisa_ubin_keluar`) menyatakan seluruh badan sudah di luar viewport (sisa 0).
static func sudah_keluar(sisa_ubin: float) -> bool:
	return sisa_ubin <= 0.0


## True bila `sisa_ubin` paling banyak `RUTE_KELUAR_HAMPIR_UBIN` (inklusif): sinyal banner "Rute selesai". NaN = false.
static func hampir_keluar(sisa_ubin: float) -> bool:
	return sisa_ubin <= Config.RUTE_KELUAR_HAMPIR_UBIN


## Fase dan sinyal sesudah memeriksa posisi layar `posisi_layar_pijak_px` di viewport `ukuran`, dari fase `fase_lama` dan `hampir_lama` (sinyal sebelumnya).
## `selesai` = garis akhir sudah tercapai (`Status.selesai`). Fase hanya maju; sebelum `selesai` tidak ada fase yang naik dan tidak ada sinyal. Melompat langsung
## ke SUDAH_KELUAR (langkah besar) tetap memberi `baru_hampir_keluar` pada pemeriksaan yang sama (sisa 0 selalu <= ambang hampir), supaya banner tidak terlewat.
static func periksa_keluar(fase_lama: Fase, hampir_lama: bool, selesai: bool, posisi_layar_pijak_px: Vector2, ukuran: Vector2) -> Keluar:
	var k: Keluar = Keluar.new()
	k.sisa_ubin = sisa_ubin_keluar(posisi_layar_pijak_px, ukuran)
	k.fase = fase_lama
	k.hampir_keluar = hampir_lama or fase_lama == Fase.SUDAH_KELUAR
	if selesai:
		if k.fase == Fase.SEBELUM:
			k.fase = Fase.MELAJU_KELUAR
		if sudah_keluar(k.sisa_ubin):
			k.fase = Fase.SUDAH_KELUAR
		if not k.hampir_keluar and hampir_keluar(k.sisa_ubin):
			k.hampir_keluar = true
			k.baru_hampir_keluar = true
	k.baru_keluar = k.fase == Fase.SUDAH_KELUAR and fase_lama != Fase.SUDAH_KELUAR
	return k


## Rentang ubin sepanjang jalan yang tampak di viewport `ukuran` relatif terhadap pijak di layar `posisi_layar_pijak_px`: x = paling jauh di belakang pijak
## (negatif), y = paling jauh di depan (positif), dari keempat pojok viewport lewat `Iso.layar_ke_dunia`. Tanah dan dunia harus tergambar sejauh ini
## untuk kamera yang beku di garis akhir (G-5). Masukan tidak hingga = (0, 0).
static func rentang_maju_terlihat(posisi_layar_pijak_px: Vector2, ukuran: Vector2) -> Vector2:
	if not posisi_layar_pijak_px.is_finite() or not ukuran.is_finite():
		return Vector2.ZERO
	var belakang: float = INF
	var depan: float = -INF
	for pojok: Vector2 in [Vector2.ZERO, Vector2(ukuran.x, 0.0), Vector2(0.0, ukuran.y), ukuran]:
		var maju: float = -Iso.layar_ke_dunia(pojok - posisi_layar_pijak_px).y
		belakang = minf(belakang, maju)
		depan = maxf(depan, maju)
	return Vector2(belakang, depan)


## Sisa jarak sepeda ke garis akhir, ubin (positif sebelum garis, 0 di garis, negatif sesudahnya). Masukan tidak hingga atau panjang tidak positif = NaN.
static func jarak_ke_garis(jarak_ubin: float, panjang_ubin: float) -> float:
	if not is_finite(jarak_ubin) or not is_finite(panjang_ubin) or panjang_ubin <= 0.0:
		return NAN
	return panjang_ubin - jarak_ubin


## True bila portal terbuka: sepeda paling jauh `RUTE_PORTAL_BUKA_JARAK_UBIN` dari garis akhir (inklusif), dan tetap terbuka sesudah melewatinya
## (jarak ke garis nol atau negatif). Masukan tidak hingga atau panjang tidak positif = NaN dari `jarak_ke_garis`, dan perbandingan dengan NaN selalu false = tertutup.
static func portal_terbuka(jarak_ubin: float, panjang_ubin: float) -> bool:
	var sisa: float = jarak_ke_garis(jarak_ubin, panjang_ubin)
	return sisa <= Config.RUTE_PORTAL_BUKA_JARAK_UBIN


## Frame sprite `prop_portal_satpam` untuk jarak sepeda: 0 tertutup, 1 terbuka (`portal_terbuka`).
static func portal_bingkai(jarak_ubin: float, panjang_ubin: float) -> int:
	return 1 if portal_terbuka(jarak_ubin, panjang_ubin) else 0
