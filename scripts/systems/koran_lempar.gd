class_name KoranLempar
extends RefCounted
## Koran yang sudah dilempar: waktu terbang, mendarat, hasil sasaran, dan lama penanda, logika murni (D-4, D-5, D-10, D-11 run
## fase2a-lemparan bagian 1b). Node (`JalanUji`, `KoranGambar`, `GarisBidik`) hanya menyimpan dan menggambar hasilnya.
##
## Lintasan dihitung SEKALI saat jari dilepas (`ThrowSolver.dari_swipe`) dan dibekukan di objek `Koran`; sesudah itu hanya waktu
## yang maju (`langkah`, dt dari `JedaSim.dt_efektif`, jadi jeda game membekukannya tanpa kode tambahan). Posisi selalu dari
## `ThrowSolver.posisi_sejak_jari`, tidak ada rumus lintasan di sini. Koran tampil di udara mulai jeda lepas (frame lepas animasi,
## `LemparWaktu.waktu_lepas`), tidak bergantung pada sinyal `koran_lepas` sprite: lemparan yang animasinya ditutup jeda game tetap
## terbang sesudah lanjut (D-11). Saat mendarat, titik mendarat dinilai `ZonaSasaran` (zona jalan uji, dari titik saja, tanpa sisi
## lempar; D-4 run fase2-arah-bebas) dengan fungsi yang sama dengan elips garis bidik (`prediksi_antaran`), lalu penanda tampil
## `Config.PENANDA_LAMA_DETIK`. Zona dan kotak penutupnya dari `MedanKoran` (parameter `medan`, run fase3a-rute): null = jalan uji
## seperti sebelumnya, `MedanKoran.dari_rute` = rumah dari data rute; penilaian di scene rute memakai fungsi yang sama.


## Bentuk elips pendaratan garis bidik (D-5; QA-004 iterasi 2): cincin biasa, terisi (sasaran sah), atau putus-putus redup (tertutup rumah).
enum Elips { BIASA, SAH, TERTUTUP }


## Satu koran yang dilempar. Dibuat `baru`, diganti objek baru oleh `langkah`.
class Koran extends RefCounted:
	## Lintasan beku (dari saat jari dilepas).
	var lintasan: ThrowSolver.Lintasan = null
	## Waktu sejak jari dilepas, detik.
	var detik: float = 0.0
	## True sesudah koran mendarat (hasil sudah dinilai).
	var mendarat: bool = false
	## Hasil sasaran di titik mendarat (berlaku bila `mendarat`).
	var hasil: ZonaSasaran.Hasil = ZonaSasaran.Hasil.MELESET
	## Status antaran (berlaku bila `mendarat`).
	var antaran: ZonaSasaran.Antaran = ZonaSasaran.Antaran.TIDAK_SAH
	## Bentuk penanda (berlaku bila `mendarat`).
	var penanda: ZonaSasaran.Penanda = ZonaSasaran.Penanda.SILANG

	## Salinan bebas (lintasan dipakai bersama karena tidak pernah diubah).
	func salin() -> Koran:
		var baru: Koran = Koran.new()
		baru.lintasan = lintasan
		baru.detik = detik
		baru.mendarat = mendarat
		baru.hasil = hasil
		baru.antaran = antaran
		baru.penanda = penanda
		return baru


## Koran baru untuk lintasan yang baru diterima (jari baru dilepas).
static func baru(lintasan: ThrowSolver.Lintasan) -> Koran:
	var koran: Koran = Koran.new()
	koran.lintasan = lintasan
	return koran


## Hasil sasaran di titik mendarat lintasan (zona di sekitar titik itu menurut `medan`; null = jalan uji, `MedanKoran.dari_rute` = rumah rute), dari
## titik mendarat SAJA: arah dan sisi lemparan tidak ikut menilai (D-4 run fase2-arah-bebas). Lintasan null = `MELESET`.
static func hasil_mendarat(lintasan: ThrowSolver.Lintasan, medan: MedanKoran = null) -> ZonaSasaran.Hasil:
	if lintasan == null:
		return ZonaSasaran.Hasil.MELESET
	return ZonaSasaran.klasifikasi(lintasan.titik_mendarat, MedanKoran.zona(medan, lintasan.titik_mendarat))


## Status antaran yang AKAN didapat lintasan ini (elips garis bidik, D-5) dengan sakelar jendela `jendela_bonus`. Sama persis dengan
## penilaian saat koran mendarat (`langkah`).
static func prediksi_antaran(lintasan: ThrowSolver.Lintasan, jendela_bonus: bool, medan: MedanKoran = null) -> ZonaSasaran.Antaran:
	return ZonaSasaran.status_antaran(hasil_mendarat(lintasan, medan), jendela_bonus)


## Bentuk elips pendaratan untuk lintasan ini (D-5, QA-004): `SAH` bila `prediksi_antaran` sah; `TERTUTUP` bila titik mendarat tertutup
## rumah graybox dari sudut kamera (di dalam atau di belakang kotaknya; koran meleset di sana, jadi elips tidak boleh terbaca sebagai
## sasaran di atap atau dinding); selain itu `BIASA`.
static func bentuk_elips(lintasan: ThrowSolver.Lintasan, jendela_bonus: bool, medan: MedanKoran = null) -> Elips:
	if lintasan == null:
		return Elips.BIASA
	if ZonaSasaran.sah(prediksi_antaran(lintasan, jendela_bonus, medan)):
		return Elips.SAH
	if MedanKoran.tertutup(medan, lintasan.titik_mendarat, 0.0):
		return Elips.TERTUTUP
	return Elips.BIASA


## True bila koran lintasan ini pada `t` detik sejak lepas tertutup rumah graybox dari sudut kamera (titik garis bidik redup, QA-004).
static func tertutup_pada(lintasan: ThrowSolver.Lintasan, t: float, medan: MedanKoran = null) -> bool:
	if lintasan == null:
		return false
	var p: Vector3 = ThrowSolver.posisi_pada(lintasan, t)
	return MedanKoran.tertutup(medan, Vector2(p.x, p.y), p.z)


## Satu langkah selama `dt` detik (NaN, tak hingga, negatif = 0, jadi jeda game membeku). Koran yang melewati lama total (jeda lepas +
## lama terbang) pada langkah ini mendarat dan dinilai dengan sakelar jendela `jendela_bonus`. Masukan tidak diubah.
static func langkah(koran: Koran, dt: float, jendela_bonus: bool, medan: MedanKoran = null) -> Koran:
	var baru: Koran = koran.salin()
	if is_finite(dt) and dt > 0.0:
		baru.detik += dt
	if not baru.mendarat and ThrowSolver.sudah_mendarat(baru.lintasan, baru.detik):
		baru.mendarat = true
		baru.hasil = hasil_mendarat(baru.lintasan, medan)
		baru.antaran = ZonaSasaran.status_antaran(baru.hasil, jendela_bonus)
		baru.penanda = ZonaSasaran.penanda(baru.antaran)
	return baru


## True selama koran terbang: sudah lepas dari tangan (waktu terbang >= 0, toleransi sama dengan frame lepas animasi) dan belum mendarat.
static func di_udara(koran: Koran) -> bool:
	if koran.mendarat or koran.lintasan == null:
		return false
	return ThrowSolver.waktu_terbang(koran.lintasan, koran.detik) + Config.LEMPAR_TOLERANSI_DETIK >= 0.0


## Posisi koran: x, y = tanah di dunia (ubin), z = tinggi (ubin). Sesudah mendarat tepat titik mendarat dengan tinggi 0.
static func posisi(koran: Koran) -> Vector3:
	if koran.lintasan == null:
		return Vector3.ZERO
	if koran.mendarat:
		return Vector3(koran.lintasan.titik_mendarat.x, koran.lintasan.titik_mendarat.y, 0.0)
	return ThrowSolver.posisi_sejak_jari(koran.lintasan, koran.detik)


## Sisa waktu penanda kena/meleset, detik: penuh sebelum mendarat, lalu berkurang sejak saat mendarat.
static func sisa_penanda(koran: Koran) -> float:
	if not koran.mendarat:
		return Config.PENANDA_LAMA_DETIK
	return Config.PENANDA_LAMA_DETIK - maxf(koran.detik - ThrowSolver.lama_total(koran.lintasan), 0.0)


## True bila koran sudah mendarat dan penandanya sudah habis (boleh dibuang).
static func selesai(koran: Koran) -> bool:
	return koran.mendarat and sisa_penanda(koran) <= Config.LEMPAR_TOLERANSI_DETIK


## Indeks frame putaran koran (0 sampai `jumlah_frame` - 1) dari waktu terbang dan `Config.KORAN_PUTAR_FPS`; 0 sebelum lepas.
static func frame_putar(koran: Koran, jumlah_frame: int) -> int:
	if jumlah_frame < 1 or koran.lintasan == null:
		return 0
	var terbang: float = ThrowSolver.waktu_terbang(koran.lintasan, koran.detik)
	if terbang <= 0.0:
		return 0
	return posmod(floori(terbang * Config.KORAN_PUTAR_FPS + Config.LEMPAR_TOLERANSI_DETIK), jumlah_frame)


## Lebar elips bayangan koran untuk tinggi `tinggi_ubin`, piksel game: mengecil saat tinggi naik, dijepit ke batas `Config`.
static func lebar_bayangan_px(tinggi_ubin: float) -> int:
	var tinggi: float = tinggi_ubin if is_finite(tinggi_ubin) and tinggi_ubin > 0.0 else 0.0
	var lebar: int = roundi(float(Config.KORAN_BAYANGAN_LEBAR_MAKS_PX) - tinggi * Config.KORAN_BAYANGAN_SUSUT_PX_PER_UBIN)
	return clampi(lebar, Config.KORAN_BAYANGAN_LEBAR_MIN_PX, Config.KORAN_BAYANGAN_LEBAR_MAKS_PX)


## Waktu-waktu (detik sejak lepas) titik garis bidik (D-5): `jumlah_sampel` + 1 sampel `posisi_pada` merata dari 0 sampai lama terbang;
## titik pertama di t = 0, lalu satu titik tiap kali jarak layar yang ditempuh sejak titik sebelumnya mencapai `jarak_px`. Jadi tiap
## titik adalah sampel `ThrowSolver.posisi_pada` (bukan rumus kedua). Kosong bila lintasan null atau masukan tidak sah.
static func waktu_titik_bidik(lintasan: ThrowSolver.Lintasan, jarak_px: float, jumlah_sampel: int) -> PackedFloat32Array:
	var hasil: PackedFloat32Array = PackedFloat32Array()
	if lintasan == null or jumlah_sampel < 1 or not is_finite(jarak_px) or jarak_px <= 0.0:
		return hasil
	hasil.append(0.0)
	var sebelum: Vector2 = layar_pada(lintasan, 0.0)
	var tempuh: float = 0.0
	for i: int in range(1, jumlah_sampel + 1):
		var t: float = lintasan.lama_terbang * float(i) / float(jumlah_sampel)
		var titik: Vector2 = layar_pada(lintasan, t)
		tempuh += sebelum.distance_to(titik)
		sebelum = titik
		if tempuh >= jarak_px:
			hasil.append(t)
			tempuh = 0.0
	return hasil


## Posisi layar (piksel game, float, ruang dunia) koran pada `t` detik sejak lepas: `posisi_pada` lalu proyeksi tinggi `Iso`.
static func layar_pada(lintasan: ThrowSolver.Lintasan, t: float) -> Vector2:
	var p: Vector3 = ThrowSolver.posisi_pada(lintasan, t)
	return Iso.dunia_tinggi_ke_layar(Vector2(p.x, p.y), p.z)
