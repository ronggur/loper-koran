class_name BantuLempar
extends RefCounted
## Mode bantu: sisi dari tap dan pemilihan sasaran lemparan otomatis, logika murni (GDD 5.3, rule `ui-scenes`; K-1 sampai K-3 dan D-3,
## D-4, D-6 run fase2b-bantu-audio, usulan yang dinilai lewat uji HP).
##
## - Sisi tap (D-3): sisi = `ThrowSolver.sisi_dari_arah(ThrowSolver.arah_tanah(tap - posisi sepeda di layar))`, jadi pemisahnya garis searah
##   jalan di layar yang melewati titik pijak sepeda: di atas garis `SEBERANG`, di bawahnya `DEKAT`, tepat di garis `DEKAT` (aturan sisi
##   arah bebas yang sama, tidak ada aturan sisi kedua). Kidal tidak mengubahnya. Posisi sepeda di layar diberikan scene (kamera ikut).
## - Sasaran (K-3, D-4): kandidat = zona `KOTAK_SURAT` rumah pelanggan di sisi tap yang pusatnya di depan sepeda (maju pusat >= maju
##   sepeda saat tap). Untuk tiap kandidat dicari kekuatan u di [0, 1] dan arah tanah sehingga lintasan mendarat di pusat zona, dengan
##   warisan kecepatan maju dan jeda lepas yang sama dengan swipe. Pencarian u (bisection, `cari_kekuatan`) hanya memakai bagian rumus
##   dari `ThrowSolver` (`titik_lepas`, `jarak_ubin`, `geser_maju_ubin`); lintasan yang dipakai SELALU keluaran `ThrowSolver.hitung` dan
##   titik mendaratnya dicek ulang: zona yang menang di titik itu (`ZonaSasaran.zona_kena`) harus kandidat itu sendiri. Dari kandidat yang
##   terjangkau dipilih yang paling dekat di depan (maju pusat terkecil); seri diputus dengan selisih lateral pusat ke sepeda terkecil,
##   lalu urutan daftar. Tidak ada yang terjangkau = null (tidak melempar, D-6 tanda tanpa sasaran).
## - Jangkauan maju (`jangkauan_maju_ubin`): batas terjauh titik mendarat di depan sepeda, untuk menyiapkan daftar zona di scene.
## Tanpa node, `Time`, atau RNG; masukan tidak diubah.


## Hasil pemilihan sasaran: zona kotak surat yang dipilih dan lintasan `ThrowSolver.hitung` ke pusatnya.
class Pilihan extends RefCounted:
	## Zona kotak surat sasaran.
	var zona: ZonaSasaran.Zona = null
	## Lintasan beku (keluaran `ThrowSolver.hitung`), mendarat di dalam `zona`.
	var lintasan: ThrowSolver.Lintasan = null
	## Kekuatan u hasil pencarian, 0 sampai 1.
	var kekuatan: float = 0.0


## Sisi lempar dari tap di `tap` dengan titik pijak sepeda di `posisi_sepeda_layar` (keduanya koordinat viewport game, D-3). Tap tepat di
## titik pijak sepeda ada di garis = `DEKAT`. Masukan tidak hingga atau NaN = `TIDAK_ADA`.
static func sisi_tap(tap: Vector2, posisi_sepeda_layar: Vector2) -> LoperAnim.Sisi:
	if not tap.is_finite() or not posisi_sepeda_layar.is_finite():
		return LoperAnim.Sisi.TIDAK_ADA
	var arah: Vector2 = ThrowSolver.arah_tanah(tap - posisi_sepeda_layar)
	if arah == Vector2.ZERO:
		return LoperAnim.Sisi.DEKAT
	return ThrowSolver.sisi_dari_arah(arah)


## Pusat zona di dunia (ubin; `Iso`: y dunia = -maju).
static func pusat_dunia(zona: ZonaSasaran.Zona) -> Vector2:
	var pusat: Vector2 = zona.persegi.get_center()
	return Vector2(pusat.x, -pusat.y)


## True bila `zona` kandidat sasaran mode bantu untuk tap ke `sisi` dengan sepeda di `posisi_sepeda` (dunia): kotak surat, rumah
## pelanggan, sisi sama, pusat di depan sepeda (maju pusat >= maju sepeda).
static func kandidat(zona: ZonaSasaran.Zona, sisi: LoperAnim.Sisi, posisi_sepeda: Vector2) -> bool:
	if zona == null or zona.jenis != ZonaSasaran.Jenis.KOTAK_SURAT or not zona.pelanggan or zona.sisi != sisi:
		return false
	return zona.persegi.get_center().y >= -posisi_sepeda.y


## Kekuatan u (0 sampai 1) yang membuat koran dari `titik_lepas` (dunia) dengan kecepatan maju `kecepatan_maju_ud` mendarat tepat di
## `sasaran` (dunia), atau -1 bila tidak terjangkau. Akar f(u) = |R(u)| - jarak(u), R(u) = sasaran - titik lepas - ARAH_MAJU x geser maju(u):
## jarak tanah naik 3,5 ubin per u sedangkan |R| berubah paling banyak geser maju(1) - geser maju(0) (1,8 ubin di ngebut), jadi f turun
## dan akarnya tunggal. Terjangkau bila f(0) >= 0 >= f(1) (toleransi `BANTU_TOLERANSI_UBIN`); akar dicari bisection
## `BANTU_CARI_ULANGAN` kali.
static func cari_kekuatan(sasaran: Vector2, titik_lepas: Vector2, kecepatan_maju_ud: float) -> float:
	if not sasaran.is_finite() or not titik_lepas.is_finite():
		return -1
	var f_bawah: float = _selisih(sasaran, titik_lepas, kecepatan_maju_ud, 0.0)
	var f_atas: float = _selisih(sasaran, titik_lepas, kecepatan_maju_ud, 1.0)
	if f_bawah < -Config.BANTU_TOLERANSI_UBIN or f_atas > Config.BANTU_TOLERANSI_UBIN:
		return -1
	if f_bawah <= Config.BANTU_TOLERANSI_UBIN:
		return 0.0
	if f_atas >= -Config.BANTU_TOLERANSI_UBIN:
		return 1.0
	var bawah: float = 0.0
	var atas: float = 1.0
	for i: int in range(Config.BANTU_CARI_ULANGAN):
		var tengah: float = (bawah + atas) / 2
		if _selisih(sasaran, titik_lepas, kecepatan_maju_ud, tengah) > 0.0:
			bawah = tengah
		else:
			atas = tengah
	return (bawah + atas) / 2


## Arah tanah (vektor satuan, dunia) dari `titik_lepas` ke `sasaran` sesudah dikurangi geser maju warisan untuk kekuatan u: R(u)
## dinormalkan. Nol bila R(u) nol atau tidak hingga.
static func arah_ke(sasaran: Vector2, titik_lepas: Vector2, kecepatan_maju_ud: float, u: float) -> Vector2:
	var r: Vector2 = _sisa_arah(sasaran, titik_lepas, kecepatan_maju_ud, u)
	if not r.is_finite() or r == Vector2.ZERO:
		return Vector2.ZERO
	return r.normalized()


## Sasaran lemparan otomatis untuk tap ke `sisi` (D-4): sepeda di `posisi_sepeda` (dunia), kecepatan maju SEBENARNYA, kecepatan lateral
## efektif langkah terakhir, jeda lepas animasi untuk sisi itu, lebar viewport game, dan `daftar` zona (zona jalan uji di scene; data rute
## di Fase 3). null bila sisi kosong, masukan tidak hingga, atau tidak ada kotak surat pelanggan yang terjangkau di depan pada sisi itu.
static func pilih(sisi: LoperAnim.Sisi, posisi_sepeda: Vector2, kecepatan_maju_ud: float, kecepatan_lateral_ud: float, jeda_lepas_detik: float, lebar_viewport_px: float, daftar: Array[ZonaSasaran.Zona]) -> Pilihan:
	if sisi == LoperAnim.Sisi.TIDAK_ADA or not posisi_sepeda.is_finite():
		return null
	var titik_lepas: Vector2 = ThrowSolver.titik_lepas(posisi_sepeda, kecepatan_maju_ud, kecepatan_lateral_ud, jeda_lepas_detik)
	var terbaik: Pilihan = null
	for zona: ZonaSasaran.Zona in daftar:
		if not kandidat(zona, sisi, posisi_sepeda):
			continue
		if terbaik != null and not _lebih_dekat(zona, terbaik.zona, posisi_sepeda):
			continue
		var pusat: Vector2 = pusat_dunia(zona)
		var u: float = cari_kekuatan(pusat, titik_lepas, kecepatan_maju_ud)
		if u < 0.0:
			continue
		var arah: Vector2 = arah_ke(pusat, titik_lepas, kecepatan_maju_ud, u)
		var lintasan: ThrowSolver.Lintasan = ThrowSolver.hitung(ThrowSolver.panjang_untuk_kekuatan(u, lebar_viewport_px), lebar_viewport_px, arah, posisi_sepeda, kecepatan_maju_ud, kecepatan_lateral_ud, jeda_lepas_detik)
		if lintasan == null or ZonaSasaran.zona_kena(lintasan.titik_mendarat, daftar) != zona:
			continue
		var baru: Pilihan = Pilihan.new()
		baru.zona = zona
		baru.lintasan = lintasan
		baru.kekuatan = u
		terbaik = baru
	return terbaik


## Batas terjauh titik mendarat di depan sepeda, ubin maju: geser selama jeda lepas + jarak tanah terjauh + geser maju terjauh
## (kekuatan 1). Kecepatan atau jeda tidak sah = 0 (seperti `ThrowSolver`).
static func jangkauan_maju_ubin(kecepatan_maju_ud: float, jeda_lepas_detik: float) -> float:
	var lepas: Vector2 = ThrowSolver.titik_lepas(Vector2.ZERO, kecepatan_maju_ud, 0.0, jeda_lepas_detik)
	return -lepas.y + ThrowSolver.jarak_ubin(1.0) + ThrowSolver.geser_maju_ubin(kecepatan_maju_ud, 1.0)


## Sisa waktu tanda "tidak ada sasaran" (D-6) sesudah `dt` detik, detik (tidak kurang dari 0; dt NaN, tak hingga, negatif = 0, jadi jeda
## game membekukannya).
static func sisa_tanda(sisa_detik: float, dt: float) -> float:
	var langkah: float = dt if is_finite(dt) and dt > 0.0 else 0.0
	var sisa: float = sisa_detik if is_finite(sisa_detik) else 0.0
	return maxf(sisa - langkah, 0.0)


## True selama tanda "tidak ada sasaran" masih tampil (sisa lebih dari toleransi `LEMPAR_TOLERANSI_DETIK`).
static func tanda_tampil(sisa_detik: float) -> bool:
	return is_finite(sisa_detik) and sisa_detik > Config.LEMPAR_TOLERANSI_DETIK


## True bila `a` lebih diutamakan dari `b`: maju pusat lebih kecil; seri = selisih lateral pusat ke sepeda lebih kecil; seri lagi = tidak
## (yang lebih dulu di daftar tetap menang).
static func _lebih_dekat(a: ZonaSasaran.Zona, b: ZonaSasaran.Zona, posisi_sepeda: Vector2) -> bool:
	var pa: Vector2 = a.persegi.get_center()
	var pb: Vector2 = b.persegi.get_center()
	if pa.y != pb.y:
		return pa.y < pb.y
	return absf(pa.x - posisi_sepeda.x) < absf(pb.x - posisi_sepeda.x)


## R(u) = sasaran - titik lepas - ARAH_MAJU x geser maju(u).
static func _sisa_arah(sasaran: Vector2, titik_lepas: Vector2, kecepatan_maju_ud: float, u: float) -> Vector2:
	return sasaran - titik_lepas - Iso.ARAH_MAJU * ThrowSolver.geser_maju_ubin(kecepatan_maju_ud, u)


## f(u) = |R(u)| - jarak tanah(u), ubin.
static func _selisih(sasaran: Vector2, titik_lepas: Vector2, kecepatan_maju_ud: float, u: float) -> float:
	return _sisa_arah(sasaran, titik_lepas, kecepatan_maju_ud, u).length() - ThrowSolver.jarak_ubin(u)
