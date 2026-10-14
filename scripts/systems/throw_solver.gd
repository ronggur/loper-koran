class_name ThrowSolver
extends RefCounted
## Lintasan koran dari swipe, logika murni (BALANCING 4, GDD 5.1-5.2, TECH_PLAN Fase 2; D-1 sampai D-4 run fase2a-lemparan).
##
## SATU-SATUNYA sumber lintasan: koran yang terbang, garis bidik, elips pendaratan, dan bayangan semuanya memanggil fungsi di sini
## (`dari_swipe` / `hitung` lalu `posisi_pada`), supaya prediksi dan hasil tidak pernah berbeda. Tanpa node, `Time`, atau RNG;
## masukan tidak diubah, masukan sama = hasil sama. Satuan: posisi dunia dan tinggi dalam ubin (`Iso`: x melintang jalan, positif =
## sisi `dekat`; y = -maju), kecepatan u/d, waktu detik, panjang swipe piksel game.
##
## Rumus (usulan, angka di `Config.LEMPAR_*`):
## - Panjang swipe = komponen MENDATAR |dx|; sisi dari tanda dx (kiri layar = `SEBERANG`, kanan layar = `DEKAT`, kidal tidak mengubah
##   arti); swipe dominan tegak (|dx| <= |dy|) tidak melempar. min = 6%, maks = 35% lebar viewport game saat itu.
##   |dx| < min (toleransi `LEMPAR_SWIPE_TOLERANSI_PX`) = tidak melempar; tepat min melempar (inklusif).
## - u = jepit((|dx| - min) / (maks - min), 0, 1). Jarak ke samping lerp(1,5, 5,0, u) ubin dari titik lepas ke arah sisi
##   (`Iso.ARAH_SEBERANG` / `Iso.ARAH_DEKAT`), lama terbang lerp(0,45, 0,75, u) detik, tinggi puncak lerp(1,0, 1,6, u) ubin.
## - Warisan maju: geser maju selama terbang = kecepatan maju x `LEMPAR_WARISAN_MAJU` (100%) x lama terbang (`Iso.ARAH_MAJU`).
##   Tidak ada warisan lateral selama terbang.
## - Jeda lepas (D-4, rekomendasi SPEC): lintasan dihitung SEKALI saat jari dilepas lalu dibekukan di ruang dunia. Koran baru lepas
##   dari tangan `jeda_lepas` detik kemudian (frame lepas animasi, `LemparWaktu.waktu_lepas`, sekitar 0,17 detik), jadi titik lepas =
##   posisi sepeda saat jari dilepas + kecepatan sepeda (maju dan lateral) x jeda lepas, lateral dijepit ke tepi jalan resmi
##   (`BikeMotion.batas_lateral_ubin`). Garis bidik memakai panggilan yang sama, jadi jeda ini sudah terhitung di prediksi. Sepeda
##   yang mempercepat, mengerem, atau pindah sisi sesudah jari dilepas tidak mengubah lintasan: koran mendarat tepat di prediksi.
## - Lengkung (D-3): tinggi parabola dari `LEMPAR_TINGGI_TANGAN_UBIN` (t = 0) ke 0 (t = lama terbang) dengan maksimum tepat tinggi
##   puncak. Posisi tanah bergerak linear dari titik lepas ke titik mendarat. Proyeksi ke layar hanya di `Iso`.


## Satu lintasan koran yang sudah dibekukan. Dibuat `hitung`; pemanggil hanya membacanya.
class Lintasan extends RefCounted:
	## Sisi lempar (`SEBERANG` atau `DEKAT`).
	var sisi: LoperAnim.Sisi = LoperAnim.Sisi.TIDAK_ADA
	## Kekuatan swipe u, 0 sampai 1.
	var kekuatan: float = 0.0
	## Kecepatan maju sepeda saat jari dilepas (sesudah dibersihkan), u/d.
	var kecepatan_maju_ud: float = 0.0
	## Jeda dari jari dilepas sampai koran lepas dari tangan, detik.
	var jeda_lepas: float = 0.0
	## Titik koran lepas dari tangan (tanah di bawah tangan), dunia, ubin.
	var titik_lepas: Vector2 = Vector2.ZERO
	## Titik koran mendarat, dunia, ubin.
	var titik_mendarat: Vector2 = Vector2.ZERO
	## Jarak ke samping dari titik lepas, ubin.
	var jarak_samping: float = 0.0
	## Geser maju selama terbang (warisan kecepatan maju), ubin.
	var geser_maju: float = 0.0
	## Lama terbang dari lepas sampai mendarat, detik.
	var lama_terbang: float = 0.0
	## Tinggi puncak lengkung, ubin di atas tanah.
	var tinggi_puncak: float = 0.0
	## Tinggi tangan saat lepas, ubin di atas tanah.
	var tinggi_tangan: float = 0.0
	## Koefisien lengkung h(s) = tinggi_tangan + lengkung_b x s - lengkung_a x s^2, s = t / lama_terbang.
	var lengkung_a: float = 0.0
	## Lihat `lengkung_a`.
	var lengkung_b: float = 0.0


## Swipe minimum untuk lebar viewport game `lebar_viewport_px`, piksel game. Lebar tidak sah (bukan bilangan hingga, <= 0) = INF.
static func swipe_min_px(lebar_viewport_px: float) -> float:
	if not _lebar_sah(lebar_viewport_px):
		return INF
	return lebar_viewport_px * Config.LEMPAR_SWIPE_MIN_PECAHAN


## Swipe maksimum yang masih dihitung untuk lebar viewport game, piksel game. Lebar tidak sah = INF.
static func swipe_maks_px(lebar_viewport_px: float) -> float:
	if not _lebar_sah(lebar_viewport_px):
		return INF
	return lebar_viewport_px * Config.LEMPAR_SWIPE_MAKS_PECAHAN


## True bila panjang swipe mendatar `panjang_px` cukup untuk melempar (>= min, inklusif dengan toleransi). NaN, tak hingga, negatif,
## atau lebar tidak sah = false.
static func cukup_panjang(panjang_px: float, lebar_viewport_px: float) -> bool:
	if not is_finite(panjang_px) or panjang_px < 0.0 or not _lebar_sah(lebar_viewport_px):
		return false
	return panjang_px + Config.LEMPAR_SWIPE_TOLERANSI_PX >= swipe_min_px(lebar_viewport_px)


## Kekuatan swipe u (0 sampai 1) dari panjang mendatar; -1 bila tidak melempar (`cukup_panjang` false).
static func kekuatan(panjang_px: float, lebar_viewport_px: float) -> float:
	if not cukup_panjang(panjang_px, lebar_viewport_px):
		return -1
	var bawah: float = swipe_min_px(lebar_viewport_px)
	var atas: float = swipe_maks_px(lebar_viewport_px)
	return clampf((panjang_px - bawah) / (atas - bawah), 0.0, 1.0)


## Sisi lempar dari satu swipe (titik awal dan akhir, piksel game) di viewport selebar `lebar_viewport_px` (GDD 5.2, D-2).
## Kiri layar = `SEBERANG`, kanan layar = `DEKAT`, tidak bergantung opsi kidal (kidal hanya menukar zona). `TIDAK_ADA` bila: titik
## tidak hingga atau NaN; gerak tegak sama besar atau lebih besar dari gerak datar (tepat 45 derajat ambigu); atau |dx| di bawah min.
static func sisi_dari_swipe(awal: Vector2, akhir: Vector2, lebar_viewport_px: float) -> LoperAnim.Sisi:
	if not awal.is_finite() or not akhir.is_finite():
		return LoperAnim.Sisi.TIDAK_ADA
	var geser: Vector2 = akhir - awal
	if absf(geser.x) <= absf(geser.y):
		return LoperAnim.Sisi.TIDAK_ADA
	if not cukup_panjang(absf(geser.x), lebar_viewport_px):
		return LoperAnim.Sisi.TIDAK_ADA
	return LoperAnim.Sisi.SEBERANG if geser.x < 0.0 else LoperAnim.Sisi.DEKAT


## Jarak ke samping untuk kekuatan u (dijepit 0..1; NaN = 0), ubin.
static func jarak_samping_ubin(u: float) -> float:
	return lerpf(Config.LEMPAR_JARAK_MIN_UBIN, Config.LEMPAR_JARAK_MAKS_UBIN, _u_bersih(u))


## Lama terbang untuk kekuatan u (dijepit 0..1; NaN = 0), detik.
static func lama_terbang_detik(u: float) -> float:
	return lerpf(Config.LEMPAR_TERBANG_MIN_DETIK, Config.LEMPAR_TERBANG_MAKS_DETIK, _u_bersih(u))


## Tinggi puncak untuk kekuatan u (dijepit 0..1; NaN = 0), ubin.
static func tinggi_puncak_ubin(u: float) -> float:
	return lerpf(Config.LEMPAR_PUNCAK_MIN_UBIN, Config.LEMPAR_PUNCAK_MAKS_UBIN, _u_bersih(u))


## Arah melintang ke sisi lempar (`Iso.ARAH_SEBERANG` / `Iso.ARAH_DEKAT`); `TIDAK_ADA` = nol.
static func arah_sisi(sisi: LoperAnim.Sisi) -> Vector2:
	match sisi:
		LoperAnim.Sisi.SEBERANG:
			return Iso.ARAH_SEBERANG
		LoperAnim.Sisi.DEKAT:
			return Iso.ARAH_DEKAT
	return Vector2.ZERO


## Titik lepas (D-4): posisi sepeda saat jari dilepas + kecepatan sepeda x jeda lepas; maju searah `Iso.ARAH_MAJU`, lateral searah
## `Iso.ARAH_DEKAT` (negatif = ke seberang) lalu dijepit ke tepi jalan resmi. Kecepatan atau jeda tidak sah dibersihkan (lihat `hitung`).
static func titik_lepas(posisi_sepeda: Vector2, kecepatan_maju_ud: float, kecepatan_lateral_ud: float, jeda_lepas_detik: float) -> Vector2:
	var jeda: float = _tak_negatif(jeda_lepas_detik)
	var maju: Vector2 = Iso.ARAH_MAJU * (_tak_negatif(kecepatan_maju_ud) * jeda)
	var lateral: float = posisi_sepeda.x + Iso.ARAH_DEKAT.x * (_hingga(kecepatan_lateral_ud) * jeda)
	var batas: float = BikeMotion.batas_lateral_ubin()
	return Vector2(clampf(lateral, -batas, batas), posisi_sepeda.y + maju.y)


## Lintasan dari keadaan saat jari dilepas (D-1). `panjang_swipe_px` = |dx| piksel game, `lebar_viewport_px` = lebar viewport game
## saat itu, `posisi_sepeda` dunia (ubin), `kecepatan_maju_ud` kecepatan maju SEBENARNYA (NaN, tak hingga, negatif = 0),
## `kecepatan_lateral_ud` kecepatan lateral efektif (NaN, tak hingga = 0), `jeda_lepas_detik` (NaN, tak hingga, negatif = 0).
## null bila tidak melempar: sisi bukan `SEBERANG`/`DEKAT`, posisi tidak hingga, atau swipe di bawah min.
static func hitung(panjang_swipe_px: float, lebar_viewport_px: float, sisi: LoperAnim.Sisi, posisi_sepeda: Vector2, kecepatan_maju_ud: float, kecepatan_lateral_ud: float, jeda_lepas_detik: float) -> Lintasan:
	if sisi != LoperAnim.Sisi.SEBERANG and sisi != LoperAnim.Sisi.DEKAT:
		return null
	if not posisi_sepeda.is_finite():
		return null
	var u: float = kekuatan(panjang_swipe_px, lebar_viewport_px)
	if u < 0.0:
		return null
	var hasil: Lintasan = Lintasan.new()
	hasil.sisi = sisi
	hasil.kekuatan = u
	hasil.kecepatan_maju_ud = _tak_negatif(kecepatan_maju_ud)
	hasil.jeda_lepas = _tak_negatif(jeda_lepas_detik)
	hasil.titik_lepas = titik_lepas(posisi_sepeda, kecepatan_maju_ud, kecepatan_lateral_ud, jeda_lepas_detik)
	hasil.jarak_samping = jarak_samping_ubin(u)
	hasil.lama_terbang = lama_terbang_detik(u)
	hasil.geser_maju = hasil.kecepatan_maju_ud * Config.LEMPAR_WARISAN_MAJU * hasil.lama_terbang
	hasil.titik_mendarat = hasil.titik_lepas + arah_sisi(sisi) * hasil.jarak_samping + Iso.ARAH_MAJU * hasil.geser_maju
	hasil.tinggi_tangan = maxf(Config.LEMPAR_TINGGI_TANGAN_UBIN, 0.0)
	hasil.tinggi_puncak = maxf(tinggi_puncak_ubin(u), hasil.tinggi_tangan)
	# Parabola h(s) = h0 + b s - a s^2 dengan h(1) = 0 (b = a - h0) dan maksimum H: (a - h0)^2 = 4 a (H - h0), akar yang menaruh
	# puncak di 0 <= s <= 1/2 adalah a = (2H - h0) + 2 sqrt(H (H - h0)).
	var h0: float = hasil.tinggi_tangan
	var puncak: float = hasil.tinggi_puncak
	hasil.lengkung_a = (2 * puncak - h0) + 2 * sqrt(puncak * (puncak - h0))
	hasil.lengkung_b = hasil.lengkung_a - h0
	return hasil


## Lintasan langsung dari swipe (titik awal dan akhir, piksel game): `sisi_dari_swipe` lalu `hitung` dengan |dx|. Panggilan yang
## sama dipakai garis bidik tiap frame dan lemparan saat jari dilepas (D-4). null bila swipe tidak melempar.
static func dari_swipe(awal: Vector2, akhir: Vector2, lebar_viewport_px: float, posisi_sepeda: Vector2, kecepatan_maju_ud: float, kecepatan_lateral_ud: float, jeda_lepas_detik: float) -> Lintasan:
	var sisi: LoperAnim.Sisi = sisi_dari_swipe(awal, akhir, lebar_viewport_px)
	if sisi == LoperAnim.Sisi.TIDAK_ADA:
		return null
	return hitung(absf(akhir.x - awal.x), lebar_viewport_px, sisi, posisi_sepeda, kecepatan_maju_ud, kecepatan_lateral_ud, jeda_lepas_detik)


## Tinggi koran di udara pada `t` detik sejak lepas, ubin (t dijepit 0..lama terbang; NaN = 0).
static func tinggi_pada(lintasan: Lintasan, t: float) -> float:
	if lintasan == null:
		return 0.0
	var s: float = _pecahan(lintasan, t)
	if s >= 1.0:
		return 0.0
	return maxf(lintasan.tinggi_tangan + lintasan.lengkung_b * s - lintasan.lengkung_a * s * s, 0.0)


## Posisi koran pada `t` detik sejak lepas (t dijepit 0..lama terbang; NaN = 0): x, y = posisi tanah di dunia (ubin), z = tinggi
## (ubin). t = 0 di titik lepas setinggi tangan, t = lama terbang tepat di titik mendarat dengan tinggi 0.
static func posisi_pada(lintasan: Lintasan, t: float) -> Vector3:
	if lintasan == null:
		return Vector3.ZERO
	var s: float = _pecahan(lintasan, t)
	var tanah: Vector2 = lintasan.titik_mendarat if s >= 1.0 else lintasan.titik_lepas.lerp(lintasan.titik_mendarat, s)
	return Vector3(tanah.x, tanah.y, tinggi_pada(lintasan, t))


## Waktu terbang (sejak koran lepas dari tangan) dari waktu sejak jari dilepas, detik; negatif = koran masih di tangan.
static func waktu_terbang(lintasan: Lintasan, detik_sejak_jari: float) -> float:
	if lintasan == null:
		return 0.0
	return _hingga(detik_sejak_jari) - lintasan.jeda_lepas


## Lama dari jari dilepas sampai koran mendarat (jeda lepas + lama terbang), detik.
static func lama_total(lintasan: Lintasan) -> float:
	if lintasan == null:
		return 0.0
	return lintasan.jeda_lepas + lintasan.lama_terbang


## True bila koran sudah mendarat `detik_sejak_jari` detik sesudah jari dilepas (inklusif, toleransi `LEMPAR_TOLERANSI_DETIK`).
static func sudah_mendarat(lintasan: Lintasan, detik_sejak_jari: float) -> bool:
	if lintasan == null:
		return false
	return _hingga(detik_sejak_jari) + Config.LEMPAR_TOLERANSI_DETIK >= lama_total(lintasan)


## Posisi koran `detik_sejak_jari` detik sesudah jari dilepas: `posisi_pada(waktu_terbang)` (sebelum lepas = titik lepas setinggi tangan).
static func posisi_sejak_jari(lintasan: Lintasan, detik_sejak_jari: float) -> Vector3:
	return posisi_pada(lintasan, waktu_terbang(lintasan, detik_sejak_jari))


static func _pecahan(lintasan: Lintasan, t: float) -> float:
	if lintasan.lama_terbang <= 0.0 or is_nan(t):
		return 0.0
	return clampf(t / lintasan.lama_terbang, 0.0, 1.0)


static func _lebar_sah(lebar: float) -> bool:
	return is_finite(lebar) and lebar > 0.0


static func _u_bersih(u: float) -> float:
	return 0.0 if is_nan(u) else clampf(u, 0.0, 1.0)


static func _tak_negatif(nilai: float) -> float:
	return nilai if is_finite(nilai) and nilai > 0.0 else 0.0


static func _hingga(nilai: float) -> float:
	return nilai if is_finite(nilai) else 0.0
