class_name TesRintangan
extends RefCounted
## Tes logika murni rintangan dan tabrakan run fase3b-rintangan-skor: anjing penjaga (AC-1, AC-14 sisi anjing), mobil keluar garasi (AC-2),
## rintangan dari objek rute (AC-5), tabrakan = jatuh (AC-6, diubah keputusan pemilik 2026-10-17), dan invarian prinsip desain lewat simulasi headless: tanda >= 1,5 detik pada ngebut
## dari semua posisi lateral (AC-3, AC-23 c), jalan keluar selalu ada di 20 rute seed (AC-4), tabrakan tidak menghentikan rute (AC-7,
## AC-23 a), dan ngebut/santai punya harga (AC-23 b, sisi rintangan; sisi skor di `TesSkor`).
##
## Oracle independen (AC-25): angka harapan ditulis literal di sini (langkah, detik, ubin, persegi), dihitung tangan dari `Config` yang
## juga diperiksa literal di `_test_config`; data objek segmen diperiksa dari JSON mentah, bukan dari `RouteBuilder`.

const FOLDER: String = "res://assets/data/routes/perumahan"
## Langkah simulasi rute (detik). Rute penuh x 20 seed: 1/30 cukup halus (sepeda paling jauh 0,2 ubin per langkah).
const DT_RUTE: float = 1.0 / 30.0
## Toleransi pembanding float.
const TOL: float = 0.000001

var _cek: Callable
var _judul: Callable
var _pustaka_cache: Array[SegmenRute] = []


func _init(cek: Callable, judul: Callable) -> void:
	_cek = cek
	_judul = judul


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_test_config()
	_test_anjing_transisi()
	_test_anjing_gerak_literal()
	_test_anjing_separuh_jalan_dan_batas()
	_test_anjing_pulang_dan_selesai()
	_test_anjing_bel_dan_tabrak()
	_test_anjing_deterministik_dan_jeda()
	_test_mobil_literal()
	_test_mobil_dekat_dan_jeda()
	_test_animasi_sesuai_sheet()
	_test_rintangan_dari_rute()
	_test_tabrakan_bentuk()
	_test_tabrakan_aturan()
	_test_jatuh_di_bike_motion()
	_test_frame_jatuh()
	_test_jatuh_di_kotak_mobil_tidak_terkunci()
	_test_rintangan_langkah_tabrak()
	_test_anjing_berhenti_berbahaya()
	_test_peristiwa_lompatan_diam_mengejar()
	_test_tanda_literal()
	_test_tanda_invarian()
	_test_ngebut_santai_punya_harga()
	_test_rute_jalan_keluar_20_seed()
	_test_tenggat_rute_20_seed()
	_test_tabrakan_tidak_menghentikan_rute()


# --- Pembantu ---

func _pustaka() -> Array[SegmenRute]:
	if _pustaka_cache.is_empty():
		_pustaka_cache = PemuatRute.muat_folder(FOLDER).segmen
	return _pustaka_cache


func _rute(benih: int) -> RouteBuilder.Rute:
	return RouteBuilder.bangun(benih, _pustaka()).rute


func _objek(jenis: String, maju: float, jalur: String, tanda: float) -> RouteBuilder.ObjekRute:
	var o: RouteBuilder.ObjekRute = RouteBuilder.ObjekRute.new()
	o.jenis = jenis
	o.maju_ubin = maju
	o.jalur = jalur
	o.tanda_ubin = tanda
	return o


func _satu(jenis: String, maju: float, jalur: String, tanda: float = 9.0) -> RintanganRute.Keadaan:
	var daftar: Array[RouteBuilder.ObjekRute] = [_objek(jenis, maju, jalur, tanda)]
	return RintanganRute.dari_objek(daftar)


func _rect_sama(a: Rect2, b: Rect2) -> bool:
	return a.position.is_equal_approx(b.position) and a.size.is_equal_approx(b.size)


# --- Config ---

func _test_config() -> void:
	_judul.call("Rintangan dan tabrakan: angka Config literal dan geometri yang dijaga (AC-24, K-1)")
	var harapan: Dictionary = {
		"TABRAKAN_SEPEDA_SETENGAH_LATERAL_UBIN": 0.25, "TABRAKAN_SEPEDA_SETENGAH_MAJU_UBIN": 0.4,
		"ANJING_SETENGAH_UBIN": 0.25, "ANJING_RUMAH_LATERAL_UBIN": 2.75, "ANJING_KEJAR_JARAK_UBIN": 0.0,
		"ANJING_KEJAR_PENGALI": 1.25, "ANJING_LAJU_MIN_UD": 2.0, "ANJING_LAJU_MAKS_UD": 4.5, "ANJING_LATERAL_UD": 2.0,
		"ANJING_BATAS_MAJU_UBIN": 3.0, "ANJING_BERHENTI_DETIK": 0.8, "ANJING_PULANG_UD": 2.0, "ANJING_KAGET_DETIK": 0.5,
		"ANJING_MUNDUR_UD": 3.0, "MOBIL_PANJANG_UBIN": 1.5, "MOBIL_SETENGAH_LEBAR_UBIN": 0.375, "MOBIL_BELAKANG_AWAL_UBIN": 2.5,
		"MOBIL_BELAKANG_AKHIR_UBIN": 0.0, "MOBIL_TANDA_DETIK": 1.5, "MOBIL_MUNDUR_UD": 1.0,
		"TABRAKAN_JATUH_DETIK": 1.2, "TABRAKAN_KEBAL_DETIK": 1.0,
	}
	var nilai: Dictionary = (load("res://scripts/config.gd") as GDScript).get_script_constant_map()
	for nama: String in harapan:
		check(nilai.has(nama) and is_equal_approx(float(nilai[nama]), float(harapan[nama])), "Config.%s = %s (BALANCING 6c)" % [nama, harapan[nama]])
	# Satu aturan saja (keputusan pemilik 2026-10-17): oleng 0,6 dan turun ke 1,0 u/d dihapus, bukan dibiarkan tidak terpakai.
	for lama: String in ["TABRAKAN_KECEPATAN_UD", "TABRAKAN_OLENG_DETIK", "TABRAKAN_OLENG_GESER_PX", "TABRAKAN_OLENG_PERIODE_DETIK"]:
		check(not nilai.has(lama), "Config.%s sudah dihapus (oleng diganti jatuh)" % lama)
	# Tepi bentuk di halaman (anjing duduk, mobil parkir) di luar jangkauan sepeda paling tepi (trotoar 2,0 + setengah lebar 0,25).
	var jangkau_sepeda: float = BikeMotion.batas_lateral_ubin() + Config.TABRAKAN_SEPEDA_SETENGAH_LATERAL_UBIN
	check(is_equal_approx(jangkau_sepeda, 2.25), "jangkauan lateral bentuk sepeda di tepi trotoar = 2,25 ubin")
	check(Config.ANJING_RUMAH_LATERAL_UBIN - Config.ANJING_SETENGAH_UBIN > jangkau_sepeda, "anjing yang duduk di halaman (tepi 2,5) tidak bisa disentuh sepeda di trotoar (2,25)")
	check(Config.MOBIL_BELAKANG_AWAL_UBIN > jangkau_sepeda, "mobil parkir (bagasi 2,5) tidak bisa disentuh sepeda di trotoar")
	check(Config.MOBIL_BELAKANG_AKHIR_UBIN >= 0.0, "bagasi mobil berhenti paling jauh di garis tengah (K-1)")
	# Harga kecepatan: anjing lebih cepat dari santai, lebih lambat dari ngebut (AC-23 b).
	check(Config.KECEPATAN_SANTAI_UD * Config.ANJING_KEJAR_PENGALI > Config.KECEPATAN_SANTAI_UD and Config.ANJING_LAJU_MAKS_UD < Config.KECEPATAN_NGEBUT_UD, "anjing menyusul santai (3,75 > 3,0) dan tidak menyusul ngebut (4,5 < 6,0)")


# --- Anjing ---

func _test_anjing_transisi() -> void:
	_judul.call("Anjing penjaga: DIAM -> WASPADA (tanda) -> MENGEJAR, batas inklusif (AC-1)")
	var a: AnjingPenjaga.Keadaan = AnjingPenjaga.baru(20.0, LoperAnim.Sisi.SEBERANG, 9.0)
	check(a.status == AnjingPenjaga.Status.DIAM and is_equal_approx(a.maju_ubin, 20.0) and is_equal_approx(a.lateral_ubin, -2.75), "anjing baru duduk di halaman seberang (-2,75; 20)")
	check(is_equal_approx(AnjingPenjaga.rumah_lateral(LoperAnim.Sisi.DEKAT), 2.75), "halaman anjing dekat di lateral +2,75")
	var b: AnjingPenjaga.Keadaan = AnjingPenjaga.langkah(a, 10.9, 0.0, 3.0, 0.1)
	check(b.status == AnjingPenjaga.Status.DIAM, "sepeda di 10,9 (9,1 ubin di belakang): tetap DIAM")
	b = AnjingPenjaga.langkah(a, 11.0, 0.0, 3.0, 0.1)
	check(b.status == AnjingPenjaga.Status.WASPADA, "sepeda tepat 9 ubin di belakang (11,0): WASPADA (inklusif)")
	check(is_equal_approx(b.maju_ubin, 20.0) and is_equal_approx(b.lateral_ubin, -2.75), "WASPADA: anjing tetap di halaman")
	var c: AnjingPenjaga.Keadaan = AnjingPenjaga.langkah(b, 19.9, 0.0, 3.0, 0.1)
	check(c.status == AnjingPenjaga.Status.WASPADA, "sepeda di 19,9: masih WASPADA (belum lewat)")
	c = AnjingPenjaga.langkah(b, 20.0, 0.0, 3.0, 0.1)
	check(c.status == AnjingPenjaga.Status.MENGEJAR, "sepeda tepat di titik rumah (20,0): MENGEJAR")
	var d: AnjingPenjaga.Keadaan = AnjingPenjaga.langkah(a, 25.0, 0.0, 3.0, 0.1)
	check(d.status == AnjingPenjaga.Status.MENGEJAR, "satu langkah besar dari DIAM dengan sepeda sudah lewat: berantai ke MENGEJAR")
	check(a.status == AnjingPenjaga.Status.DIAM and is_equal_approx(a.detik_status, 0.0), "masukan tidak diubah")
	check(is_equal_approx(AnjingPenjaga.laju_kejar_ud(0.0), 2.0) and is_equal_approx(AnjingPenjaga.laju_kejar_ud(1.0), 2.0) and is_equal_approx(AnjingPenjaga.laju_kejar_ud(3.0), 3.75) and is_equal_approx(AnjingPenjaga.laju_kejar_ud(4.5), 4.5) and is_equal_approx(AnjingPenjaga.laju_kejar_ud(6.0), 4.5) and is_equal_approx(AnjingPenjaga.laju_kejar_ud(NAN), 2.0), "laju kejar: 0 -> 2,0; 1 -> 2,0; 3 -> 3,75; 4,5 -> 4,5; 6 -> 4,5; NaN -> 2,0")


func _test_anjing_gerak_literal() -> void:
	_judul.call("Anjing mengejar: laju mengikuti sepeda, menyamping ke arah sepeda, tidak mendahului (AC-1)")
	var a: AnjingPenjaga.Keadaan = AnjingPenjaga.langkah(AnjingPenjaga.baru(20.0, LoperAnim.Sisi.SEBERANG, 9.0), 20.5, -1.0, 3.0, 0.1)
	check(a.status == AnjingPenjaga.Status.MENGEJAR and is_equal_approx(a.maju_ubin, 20.375) and is_equal_approx(a.lateral_ubin, -2.55), "santai 3,0, dt 0,1: maju 20 + 3,75 x 0,1 = 20,375; lateral -2,75 + 2,0 x 0,1 = -2,55")
	var b: AnjingPenjaga.Keadaan = AnjingPenjaga.langkah(a, 20.4, -1.0, 6.0, 0.1)
	check(is_equal_approx(b.maju_ubin, 20.4), "laju ngebut dijepit 4,5 tetapi tidak mendahului sepeda: maju berhenti di 20,4")
	var c: AnjingPenjaga.Keadaan = AnjingPenjaga.langkah(a, 30.0, -1.0, 6.0, 0.1)
	check(is_equal_approx(c.maju_ubin, 20.825), "sepeda jauh di depan, ngebut: 20,375 + 4,5 x 0,1 = 20,825")
	var d: AnjingPenjaga.Keadaan = AnjingPenjaga.langkah(AnjingPenjaga.baru(20.0, LoperAnim.Sisi.DEKAT, 9.0), 20.5, 1.0, 3.0, 0.1)
	check(is_equal_approx(d.lateral_ubin, 2.55) and is_equal_approx(d.maju_ubin, 20.375), "anjing dekat bergerak ke arah tengah: lateral 2,75 -> 2,55")


func _test_anjing_separuh_jalan_dan_batas() -> void:
	_judul.call("Anjing hanya di separuh jalan sisinya dan berhenti di batas halaman (K-1, AC-1)")
	for sisi: LoperAnim.Sisi in [LoperAnim.Sisi.SEBERANG, LoperAnim.Sisi.DEKAT]:
		var a: AnjingPenjaga.Keadaan = AnjingPenjaga.baru(20.0, sisi, 9.0)
		var paling_tengah: float = 0.0 if sisi == LoperAnim.Sisi.DEKAT else -10.0
		var paling_tengah_min: float = 10.0
		var maju_maks: float = 0.0
		var sepeda: float = 19.0
		var lateral_lawan: float = 2.0 if sisi == LoperAnim.Sisi.SEBERANG else -2.0
		var berhenti_di: float = -1.0
		for i: int in range(120):
			sepeda += 0.05
			a = AnjingPenjaga.langkah(a, sepeda, lateral_lawan, 1.0, 0.05)
			var k: Rect2 = AnjingPenjaga.kotak(a)
			paling_tengah = maxf(paling_tengah, k.end.x)
			paling_tengah_min = minf(paling_tengah_min, k.position.x)
			maju_maks = maxf(maju_maks, a.maju_ubin)
			if berhenti_di < 0.0 and a.status == AnjingPenjaga.Status.BERHENTI:
				berhenti_di = a.maju_ubin
		if sisi == LoperAnim.Sisi.SEBERANG:
			check(is_equal_approx(paling_tengah, 0.0), "anjing seberang mengejar sepeda di separuh lawan: tepi bentuk paling jauh tepat di garis tengah (0), dapat %.4f" % paling_tengah)
		else:
			check(is_equal_approx(paling_tengah_min, 0.0), "anjing dekat: tepi bentuk paling jauh tepat di garis tengah (0), dapat %.4f" % paling_tengah_min)
		check(maju_maks <= 23.0 + TOL and is_equal_approx(berhenti_di, 23.0), "anjing berhenti tepat di batas halaman 20 + 3 = 23 (maks %.3f)" % maju_maks)


func _test_anjing_pulang_dan_selesai() -> void:
	_judul.call("Anjing BERHENTI 0,8 detik, PULANG, lalu DIAM dan tidak mengejar lagi untuk lintasan itu (AC-1)")
	var a: AnjingPenjaga.Keadaan = AnjingPenjaga.baru(20.0, LoperAnim.Sisi.SEBERANG, 9.0)
	a = AnjingPenjaga.langkah(a, 40.0, -1.0, 6.0, 0.1)
	var langkah_berhenti: int = -1
	var langkah_pulang: int = -1
	var langkah_diam: int = -1
	for i: int in range(1, 200):
		var lama: AnjingPenjaga.Status = a.status
		a = AnjingPenjaga.langkah(a, 40.0, -1.0, 6.0, 0.1)
		if a.status == AnjingPenjaga.Status.BERHENTI and lama != AnjingPenjaga.Status.BERHENTI:
			langkah_berhenti = i
		if a.status == AnjingPenjaga.Status.PULANG and lama != AnjingPenjaga.Status.PULANG:
			langkah_pulang = i
		if a.status == AnjingPenjaga.Status.DIAM and lama != AnjingPenjaga.Status.DIAM:
			langkah_diam = i
			break
	# Langkah 0: maju 20,45. Langkah 1..6: +0,45 -> 23,0 di langkah 6 (BERHENTI). 8 langkah x 0,1 = 0,8 -> PULANG di langkah 14.
	check(langkah_berhenti == 6, "ngebut dt 0,1: anjing sampai batas 23 di langkah 6 (dapat %d)" % langkah_berhenti)
	check(langkah_pulang == 14, "BERHENTI 0,8 detik lalu PULANG di langkah 14 (dapat %d)" % langkah_pulang)
	check(langkah_diam > langkah_pulang and a.selesai and is_equal_approx(a.maju_ubin, 20.0) and is_equal_approx(a.lateral_ubin, -2.75), "pulang sampai titik rumah (-2,75; 20), DIAM, selesai")
	var b: AnjingPenjaga.Keadaan = AnjingPenjaga.langkah(a, 15.0, -1.0, 3.0, 0.1)
	check(b.status == AnjingPenjaga.Status.DIAM, "anjing yang selesai tidak waspada lagi walau sepeda di jarak tanda")


func _test_anjing_bel_dan_tabrak() -> void:
	_judul.call("Anjing dan bel (K-3, AC-14): hanya WASPADA atau MENGEJAR yang kaget lalu mundur; tabrakan menghentikan kejaran")
	var diam: AnjingPenjaga.Keadaan = AnjingPenjaga.baru(20.0, LoperAnim.Sisi.SEBERANG, 9.0)
	check(not AnjingPenjaga.bisa_dengar_bel(diam) and AnjingPenjaga.dengar_bel(diam).status == AnjingPenjaga.Status.DIAM, "anjing DIAM tidak bereaksi pada bel")
	var waspada: AnjingPenjaga.Keadaan = AnjingPenjaga.langkah(diam, 12.0, 0.0, 3.0, 0.1)
	var m: AnjingPenjaga.Keadaan = AnjingPenjaga.dengar_bel(waspada)
	check(m.status == AnjingPenjaga.Status.MUNDUR and is_equal_approx(m.kaget_detik, 0.5) and m.selesai and AnjingPenjaga.ikon_seru(m), "WASPADA + bel: MUNDUR, ikon '!' 0,5 detik, selesai")
	check(waspada.status == AnjingPenjaga.Status.WASPADA, "masukan dengar_bel tidak diubah")
	var kejar: AnjingPenjaga.Keadaan = AnjingPenjaga.langkah(waspada, 21.0, -1.0, 3.0, 0.2)
	var mk: AnjingPenjaga.Keadaan = AnjingPenjaga.dengar_bel(kejar)
	check(kejar.status == AnjingPenjaga.Status.MENGEJAR and mk.status == AnjingPenjaga.Status.MUNDUR, "MENGEJAR + bel: MUNDUR")
	# Kaget 0,5 detik: diam di tempat; lalu mundur 3,0 u/d per sumbu.
	var posisi_awal: Vector2 = Vector2(mk.lateral_ubin, mk.maju_ubin)
	var x: AnjingPenjaga.Keadaan = AnjingPenjaga.langkah(mk, 22.0, -1.0, 3.0, 0.4)
	check(Vector2(x.lateral_ubin, x.maju_ubin).is_equal_approx(posisi_awal) and AnjingPenjaga.ikon_seru(x), "0,4 detik pertama kaget: diam, ikon masih tampil")
	x = AnjingPenjaga.langkah(x, 22.0, -1.0, 3.0, 0.2)
	check(not AnjingPenjaga.ikon_seru(x) and is_equal_approx(x.maju_ubin, maxf(posisi_awal.y - 0.3, 20.0)), "langkah 0,2 sesudahnya: 0,1 kaget + 0,1 mundur 3,0 u/d = 0,3 ubin ke rumah")
	check(not AnjingPenjaga.berbahaya(x), "anjing yang mundur tidak berbahaya")
	for i: int in range(40):
		x = AnjingPenjaga.langkah(x, 22.0 + i, -1.0, 3.0, 0.1)
	check(x.status == AnjingPenjaga.Status.DIAM and x.selesai, "sesudah mundur: DIAM dan tidak mengejar lagi untuk lintasan itu")
	for status_lain: AnjingPenjaga.Keadaan in [AnjingPenjaga.kena_tabrak(kejar)]:
		check(status_lain.status == AnjingPenjaga.Status.BERHENTI and not AnjingPenjaga.bisa_dengar_bel(status_lain), "tabrakan: MENGEJAR -> BERHENTI; BERHENTI tidak bereaksi pada bel")
	check(AnjingPenjaga.kena_tabrak(waspada).status == AnjingPenjaga.Status.WASPADA, "kena_tabrak hanya mengubah anjing yang mengejar")
	check(AnjingPenjaga.berbahaya(kejar) and not AnjingPenjaga.berbahaya(waspada) and not AnjingPenjaga.berbahaya(diam), "berbahaya hanya MENGEJAR dan BERHENTI")


func _test_anjing_deterministik_dan_jeda() -> void:
	_judul.call("Anjing: masukan sama = lintasan sama (ROUTE_DESIGN 4 aturan 3); dt 0 membeku (AC-21)")
	var jejak: Array = []
	for ulang: int in range(2):
		var a: AnjingPenjaga.Keadaan = AnjingPenjaga.baru(30.0, LoperAnim.Sisi.DEKAT, 9.0)
		var catatan: Array[Vector3] = []
		var sepeda: float = 15.0
		for i: int in range(300):
			sepeda += 3.0 / 60.0
			a = AnjingPenjaga.langkah(a, sepeda, 0.8, 3.0, 1.0 / 60.0)
			catatan.append(Vector3(a.lateral_ubin, a.maju_ubin, float(a.status)))
		jejak.append(catatan)
	check(jejak[0] == jejak[1], "dua kali jalan dengan masukan identik: 300 langkah posisi dan status identik")
	var w: AnjingPenjaga.Keadaan = AnjingPenjaga.langkah(AnjingPenjaga.baru(20.0, LoperAnim.Sisi.SEBERANG, 9.0), 21.0, -1.0, 3.0, 0.1)
	for dt: float in [0.0, -1.0, NAN, INF]:
		var b: AnjingPenjaga.Keadaan = AnjingPenjaga.langkah(w, 25.0, -1.0, 3.0, dt)
		check(b.status == w.status and is_equal_approx(b.maju_ubin, w.maju_ubin) and is_equal_approx(b.lateral_ubin, w.lateral_ubin) and is_equal_approx(b.detik_status, w.detik_status), "dt %s: anjing tidak berubah (jeda)" % dt)
	var diam: AnjingPenjaga.Keadaan = AnjingPenjaga.baru(20.0, LoperAnim.Sisi.SEBERANG, 9.0)
	check(AnjingPenjaga.langkah(diam, 15.0, 0.0, 3.0, 0.0).status == AnjingPenjaga.Status.DIAM, "dt 0 dengan sepeda di jarak tanda: tidak ada transisi selama jeda")


# --- Mobil ---

func _test_mobil_literal() -> void:
	_judul.call("Mobil keluar garasi: DIAM -> TANDA 1,5 detik -> MUNDUR 1,0 u/d -> BERHENTI di garis tengah (AC-2)")
	var m: MobilGarasi.Keadaan = MobilGarasi.baru(26.0, LoperAnim.Sisi.SEBERANG, 9.0)
	check(m.status == MobilGarasi.Status.DIAM and _rect_sama(MobilGarasi.kotak(m), Rect2(-4.0, 25.625, 1.5, 0.75)), "parkir: bentuk lateral -4,0..-2,5, maju 25,625..26,375")
	check(MobilGarasi.langkah(m, 16.9, 0.5).status == MobilGarasi.Status.DIAM, "sepeda 9,1 ubin di belakang: DIAM")
	var t: MobilGarasi.Keadaan = MobilGarasi.langkah(m, 17.0, 0.5)
	check(t.status == MobilGarasi.Status.TANDA and is_equal_approx(t.detik_status, 0.5) and is_equal_approx(t.belakang_ubin, 2.5), "sepeda tepat 9 ubin: TANDA, belum bergerak")
	t = MobilGarasi.langkah(t, 18.0, 0.5)
	check(t.status == MobilGarasi.Status.TANDA and is_equal_approx(t.detik_status, 1.0), "1,0 detik tanda: masih TANDA")
	t = MobilGarasi.langkah(t, 19.0, 0.5)
	check(t.status == MobilGarasi.Status.MUNDUR and is_equal_approx(t.belakang_ubin, 2.5), "tepat 1,5 detik: MUNDUR, belum bergeser")
	t = MobilGarasi.langkah(t, 20.0, 0.5)
	check(is_equal_approx(t.belakang_ubin, 2.0) and _rect_sama(MobilGarasi.kotak(t), Rect2(-3.5, 25.625, 1.5, 0.75)), "0,5 detik mundur: bagasi 2,0, bentuk -3,5..-2,0")
	var sisa_langkah: int = 0
	while t.status != MobilGarasi.Status.BERHENTI and sisa_langkah < 20:
		t = MobilGarasi.langkah(t, 21.0, 0.5)
		sisa_langkah += 1
	check(sisa_langkah == 4 and is_equal_approx(t.belakang_ubin, 0.0) and _rect_sama(MobilGarasi.kotak(t), Rect2(-1.5, 25.625, 1.5, 0.75)), "4 langkah lagi (2,0 ubin): BERHENTI, bagasi tepat di garis tengah, bentuk -1,5..0")
	for i: int in range(20):
		t = MobilGarasi.langkah(t, 30.0 + i, 0.5)
	check(t.status == MobilGarasi.Status.BERHENTI and MobilGarasi.kotak(t).end.x <= 0.0, "sesudah berhenti tidak pernah melewati garis tengah")
	# Sisa waktu langkah yang melewati batas tanda dipakai bergerak.
	var u: MobilGarasi.Keadaan = MobilGarasi.langkah(m, 17.0, 1.0)
	u = MobilGarasi.langkah(u, 18.0, 1.0)
	check(u.status == MobilGarasi.Status.MUNDUR and is_equal_approx(u.belakang_ubin, 2.0), "dt 1,0: tanda 1,0 + 0,5 lalu sisa 0,5 detik mundur -> bagasi 2,0")
	check(m.status == MobilGarasi.Status.DIAM, "masukan tidak diubah")


func _test_mobil_dekat_dan_jeda() -> void:
	_judul.call("Mobil dekat dicerminkan, tidak bereaksi pada bel, membeku saat jeda (AC-2, K-3, AC-21)")
	var m: MobilGarasi.Keadaan = MobilGarasi.baru(10.0, LoperAnim.Sisi.DEKAT, 9.0)
	check(_rect_sama(MobilGarasi.kotak(m), Rect2(2.5, 9.625, 1.5, 0.75)), "mobil dekat parkir: lateral 2,5..4,0")
	for i: int in range(10):
		m = MobilGarasi.langkah(m, 5.0, 0.5)
	check(m.status == MobilGarasi.Status.BERHENTI and _rect_sama(MobilGarasi.kotak(m), Rect2(0.0, 9.625, 1.5, 0.75)), "mobil dekat berhenti: lateral 0..1,5 (tidak melewati garis tengah)")
	var t: MobilGarasi.Keadaan = MobilGarasi.langkah(MobilGarasi.baru(10.0, LoperAnim.Sisi.SEBERANG, 9.0), 5.0, 0.7)
	for dt: float in [0.0, -0.1, NAN]:
		var b: MobilGarasi.Keadaan = MobilGarasi.langkah(t, 9.0, dt)
		check(b.status == t.status and is_equal_approx(b.detik_status, t.detik_status), "dt %s: tanda mobil membeku" % dt)
	check(Bel.reaksi("mobil_garasi") == Bel.Reaksi.TIDAK_ADA, "tabel bel: mobil tidak bereaksi")
	var r: RintanganRute.Keadaan = _satu("mobil_garasi", 10.0, "seberang")
	r = RintanganRute.langkah(r, 2.0, 0.0, 3.0, 0.5).keadaan
	var hb: RintanganRute.HasilBel = RintanganRute.terapkan_bel(r, 8.0)
	check(hb.bereaksi.is_empty() and hb.keadaan.daftar[0].mobil.status == MobilGarasi.Status.TANDA, "bel di dekat mobil bertanda: mobil tidak bereaksi")


func _test_animasi_sesuai_sheet() -> void:
	_judul.call("Nama animasi rintangan = kunci `anim` di JSON sprite sheet (AC-20 untuk bagian B)")
	for pasangan: Array in [["res://assets/sprites/obstacles/obs_anjing_sheet.json", ["diam", "tanda", "lari", "berhenti"], AnjingPenjaga.ANIMASI.values()], ["res://assets/sprites/obstacles/obs_mobil_garasi_sheet.json", ["parkir", "tanda", "mundur"], MobilGarasi.ANIMASI.values()]]:
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(pasangan[0]))
		var anim: Dictionary = (data as Dictionary).get("anim", {}) if data is Dictionary else {}
		for nama: String in pasangan[1]:
			check(anim.has(nama), "%s memuat animasi '%s'" % [pasangan[0].get_file(), nama])
		for nama: String in pasangan[2]:
			check((pasangan[1] as Array).has(nama), "%s: animasi status '%s' dikenal" % [pasangan[0].get_file(), nama])


# --- Rintangan dari rute (AC-5) ---

func _test_rintangan_dari_rute() -> void:
	_judul.call("Rintangan dibangun dari objek segmen lewat Rute/RouteBuilder (AC-5)")
	# Objek per segmen dari JSON mentah (bukan dari SegmenRute): [jenis, pos, jalur, tanda].
	var mentah: Dictionary = {}
	for nama: String in DirAccess.get_files_at(FOLDER):
		if not nama.ends_with(".json"):
			continue
		var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FOLDER.path_join(nama)))
		mentah[d["id"]] = d["objek"]
	check(mentah.size() == 9, "9 segmen dibaca mentah")
	var total_objek: int = 0
	for id: String in mentah:
		total_objek += (mentah[id] as Array).size()
	check(total_objek == 11, "9 segmen memuat 11 objek rintangan (data: tengah_01 1, tengah_02 2, tengah_03 2, tengah_04 3, tengah_05 3)")
	for benih: int in [Config.RUTE_SEED_DEV, 1, 7, 42]:
		var rute: RouteBuilder.Rute = _rute(benih)
		if rute == null:
			check(false, "seed %d dibangun" % benih)
			continue
		var harapan: Array = []
		for i: int in range(rute.segmen.size()):
			for o: Dictionary in mentah[rute.segmen[i].id]:
				harapan.append([o["jenis"], rute.awal_segmen[i] + float(o["pos"]), o["jalur"], float(o["tanda_ubin"])])
		harapan.sort_custom(func(a: Array, b: Array) -> bool: return a[1] < b[1])
		var r: RintanganRute.Keadaan = RintanganRute.dari_rute(rute)
		var cocok: bool = r.daftar.size() == harapan.size() and harapan.size() == 11
		for i: int in range(mini(r.daftar.size(), harapan.size())):
			var item: RintanganRute.Item = r.daftar[i]
			var h: Array = harapan[i]
			var sisi: LoperAnim.Sisi = LoperAnim.Sisi.SEBERANG if h[2] == "seberang" else LoperAnim.Sisi.DEKAT
			if item.id != i or item.nama_jenis != h[0]:
				cocok = false
			elif h[0] == "anjing_penjaga":
				cocok = cocok and item.jenis == RintanganRute.Jenis.ANJING and is_equal_approx(item.anjing.rumah_maju_ubin, h[1]) and item.anjing.sisi == sisi and is_equal_approx(item.anjing.tanda_ubin, h[3]) and item.anjing.status == AnjingPenjaga.Status.DIAM
			else:
				cocok = cocok and item.jenis == RintanganRute.Jenis.MOBIL and is_equal_approx(item.mobil.maju_ubin, h[1]) and item.mobil.sisi == sisi and is_equal_approx(item.mobil.tanda_ubin, h[3]) and item.mobil.status == MobilGarasi.Status.DIAM
		check(cocok, "seed %d: 11 rintangan = objek segmen (jenis, awal segmen + pos, jalur, tanda), urut maju, semua di awal" % benih)
		check(r.tabrakan.jumlah == 0 and not Tabrakan.kebal(r.tabrakan), "seed %d: tabrakan mulai dari nol" % benih)
	for jenis: String in SegmenRute.JENIS_OBJEK:
		check(RintanganRute.JENIS_DATA.has(jenis) and Bel.REAKSI_JENIS.has(jenis), "jenis objek data '%s' punya mesin keadaan dan baris di tabel reaksi bel" % jenis)


# --- Tabrakan (AC-6) ---

func _test_tabrakan_bentuk() -> void:
	_judul.call("Tabrakan: bentuk sepeda dan irisan (tepi bersentuhan bukan tabrakan)")
	check(_rect_sama(Tabrakan.kotak_sepeda(10.0, -1.0), Rect2(-1.25, 9.6, 0.5, 0.8)), "bentuk sepeda di (-1; 10): lateral -1,25..-0,75, maju 9,6..10,4")
	var a: Rect2 = Rect2(0.0, 0.0, 1.0, 1.0)
	check(Tabrakan.bertumpuk(a, Rect2(0.5, 0.5, 1.0, 1.0)), "irisan berluas = bertumpuk")
	check(not Tabrakan.bertumpuk(a, Rect2(1.0, 0.0, 1.0, 1.0)), "tepi lateral bersentuhan = tidak")
	check(not Tabrakan.bertumpuk(a, Rect2(0.0, 1.0, 1.0, 1.0)), "tepi maju bersentuhan = tidak")
	check(not Tabrakan.bertumpuk(a, Rect2(NAN, 0.0, 1.0, 1.0)), "bentuk NaN = tidak")


func _test_tabrakan_aturan() -> void:
	_judul.call("Tabrakan = jatuh (AC-6, pemilik 2026-10-17): kecepatan 0, jatuh 1,2, kebal 1,0 sejak bangun, tanpa tabrakan ganda")
	var sepeda: Rect2 = Tabrakan.kotak_sepeda(10.0, -1.0)
	var c1: Array[Tabrakan.Kandidat] = [Tabrakan.kandidat(3, "anjing_penjaga", Rect2(-1.2, 9.9, 0.5, 0.5))]
	var c2: Array[Tabrakan.Kandidat] = [Tabrakan.kandidat(5, "mobil_garasi", Rect2(-1.0, 9.8, 1.0, 0.5))]
	var kosong: Array[Tabrakan.Kandidat] = []
	var h: Tabrakan.Hasil = Tabrakan.langkah(Tabrakan.awal(), sepeda, c1, 0.1)
	check(h.tabrak and h.id == 3 and h.jenis == "anjing_penjaga", "tabrakan membawa id dan jenis penyebab (AC-8)")
	check(h.keadaan.jatuh_detik == 1.2 and h.keadaan.kebal_detik == 0.0 and h.keadaan.jumlah == 1, "langkah tabrakan: jatuh 1,2, kebal 0 (belum mulai), jumlah 1")
	check(Tabrakan.jatuh(h.keadaan) and not Tabrakan.kebal(h.keadaan) and Tabrakan.terlindung(h.keadaan) and Tabrakan.lewat_jatuh_detik(h.keadaan) == 0.0, "jatuh, belum kebal, terlindung, lewat jatuh 0")
	# Kecepatan langsung 0, rem padam; lateral dan stamina tetap; masukan tidak diubah.
	var sp: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
	sp.kecepatan_ud = 6.0
	sp.lateral_ubin = -1.0
	sp.stamina = 40.0
	sp.rem_aktif = true
	sp.tahan_rem_detik = 0.5
	var sesudah: BikeMotion.Keadaan = Tabrakan.terapkan_ke_sepeda(sp)
	check(sesudah.kecepatan_ud == 0.0 and not sesudah.rem_aktif and sesudah.tahan_rem_detik == 0.0 and sesudah.lateral_ubin == -1.0 and sesudah.stamina == 40.0, "6,0 -> 0 (jatuh), rem padam, lateral -1,0 dan stamina 40 tetap (tanpa hukuman tambahan)")
	check(sp.kecepatan_ud == 6.0 and sp.rem_aktif and sp.tahan_rem_detik == 0.5, "masukan terapkan_ke_sepeda tidak diubah")
	sp.kecepatan_ud = 0.5
	check(Tabrakan.terapkan_ke_sepeda(sp).kecepatan_ud == 0.0, "kecepatan 0,5 juga jadi 0")
	# Langkah 0,1: selama jatuh (12 langkah = 1,2 detik) rintangan lain yang menyentuh tidak menabrak; bangun tepat di langkah 12, kebal mulai.
	var k: Tabrakan.Keadaan = h.keadaan
	var tabrak_pada: int = -1
	var jatuh_per_langkah: Array[bool] = []
	var kebal_per_langkah: Array[bool] = []
	for i: int in range(1, 31):
		var hh: Tabrakan.Hasil = Tabrakan.langkah(k, sepeda, c2, 0.1)
		k = hh.keadaan
		jatuh_per_langkah.append(Tabrakan.jatuh(k))
		kebal_per_langkah.append(Tabrakan.kebal(k))
		if hh.tabrak and tabrak_pada < 0:
			tabrak_pada = i
	check(jatuh_per_langkah.slice(0, 11) == [true, true, true, true, true, true, true, true, true, true, true] and not jatuh_per_langkah[11], "langkah 0,1: jatuh sampai 1,1 detik, bangun di langkah 12 (1,2 detik)")
	check(not kebal_per_langkah.slice(0, 11).has(true), "selama jatuh belum kebal (kebal dihitung dari bangun)")
	check(not kebal_per_langkah.slice(11, 21).has(false) and not kebal_per_langkah[21], "kebal dari 1,2 sampai 2,1 detik, habis di langkah 22 (2,2 detik = bangun + 1,0)")
	check(tabrak_pada == -1 and k.jumlah == 1 and k.menempel.has(5), "rintangan yang menyentuh sejak masa jatuh menempel: tidak menabrak selama jatuh, kebal, maupun sesudahnya (3,0 detik)")
	# Tepi waktu eksplisit dengan satu langkah besar (tidak bergantung pembagian dt).
	var t1: Tabrakan.Keadaan = Tabrakan.langkah(h.keadaan, sepeda, kosong, 1.1999).keadaan
	check(Tabrakan.jatuh(t1) and is_equal_approx(t1.jatuh_detik, 0.0001) and t1.kebal_detik == 0.0, "1,1999 detik: masih jatuh (sisa 0,0001), belum kebal")
	var t2: Tabrakan.Keadaan = Tabrakan.langkah(h.keadaan, sepeda, kosong, 1.2).keadaan
	check(not Tabrakan.jatuh(t2) and t2.jatuh_detik == 0.0 and t2.kebal_detik == 1.0, "tepat 1,2 detik: bangun, jatuh 0, kebal 1,0 penuh")
	var t3: Tabrakan.Keadaan = Tabrakan.langkah(h.keadaan, sepeda, kosong, 1.5).keadaan
	check(not Tabrakan.jatuh(t3) and is_equal_approx(t3.kebal_detik, 0.7), "satu langkah 1,5 detik: bangun di 1,2, sisa 0,3 dipakai kebal -> kebal 0,7")
	var t3b: Tabrakan.Keadaan = h.keadaan
	for i: int in range(12):
		t3b = Tabrakan.langkah(t3b, sepeda, kosong, 0.1).keadaan
	t3b = Tabrakan.langkah(t3b, sepeda, kosong, 0.3).keadaan
	check(is_equal_approx(t3b.kebal_detik, t3.kebal_detik) and not Tabrakan.jatuh(t3b), "12 x 0,1 lalu 0,3 = satu langkah 1,5 (kebal 0,7)")
	# Rintangan BARU selama jatuh dan selama kebal tidak menabrak; tepat sesudah kebal habis menabrak.
	check(not Tabrakan.langkah(h.keadaan, sepeda, c2, 0.6).tabrak, "0,6 detik sesudah tabrakan (jatuh): rintangan baru tidak menabrak")
	check(not Tabrakan.langkah(t2, sepeda, c2, 0.9999).tabrak, "bangun + 0,9999 detik (kebal): rintangan baru tidak menabrak")
	var t4: Tabrakan.Keadaan = Tabrakan.langkah(t2, sepeda, kosong, 1.0).keadaan
	var h4: Tabrakan.Hasil = Tabrakan.langkah(t4, sepeda, c2, 0.05)
	check(not Tabrakan.kebal(t4) and h4.tabrak and h4.id == 5 and h4.keadaan.jumlah == 2 and h4.keadaan.jatuh_detik == 1.2, "bangun + 1,0 detik: kebal habis, rintangan baru menabrak (jumlah 2, jatuh lagi 1,2)")
	# Rintangan yang sama sesudah terpisah boleh menabrak lagi (sesudah jatuh dan kebal).
	var k4: Tabrakan.Keadaan = h.keadaan
	for i: int in range(25):
		k4 = Tabrakan.langkah(k4, sepeda, c1, 0.1).keadaan
	check(k4.jumlah == 1 and k4.menempel.has(3) and not Tabrakan.terlindung(k4), "rintangan penyebab yang tetap bersentuhan 2,5 detik: satu tabrakan saja")
	k4 = Tabrakan.langkah(k4, Tabrakan.kotak_sepeda(20.0, -1.0), c1, 0.1).keadaan
	check(k4.menempel.is_empty(), "sepeda terpisah: tidak menempel lagi")
	check(Tabrakan.langkah(k4, sepeda, c1, 0.1).tabrak, "sesudah terpisah dan tidak terlindung, rintangan yang sama bisa menabrak lagi")
	# Jeda: dt 0 tidak memajukan jatuh atau kebal dan tidak menabrak.
	var j: Tabrakan.Hasil = Tabrakan.langkah(h.keadaan, sepeda, c2, 0.0)
	check(not j.tabrak and j.keadaan.jatuh_detik == 1.2 and j.keadaan.kebal_detik == 0.0, "dt 0 saat jatuh: jatuh 1,2 membeku, tidak ada tabrakan")
	var jk: Tabrakan.Hasil = Tabrakan.langkah(t2, sepeda, c2, 0.0)
	check(not jk.tabrak and jk.keadaan.kebal_detik == 1.0, "dt 0 saat kebal: kebal 1,0 membeku")
	check(not Tabrakan.langkah(Tabrakan.awal(), sepeda, c1, 0.0).tabrak, "dt 0 tanpa kebal: tetap tidak ada tabrakan baru selama jeda")
	# Kedip kebal mengikuti waktu sejak bangun; selama jatuh sprite tampil penuh.
	check(Tabrakan.alfa_kebal(h.keadaan) == 1.0 and Tabrakan.alfa_kebal(t2) == 1.0, "alfa 1,0 selama jatuh dan tepat saat bangun")
	check(Tabrakan.alfa_kebal(Tabrakan.langkah(t2, sepeda, kosong, 0.15).keadaan) == 0.5, "bangun + 0,15 detik: fase kedip redup 0,5")
	check(is_equal_approx(Tabrakan.lewat_jatuh_detik(Tabrakan.langkah(h.keadaan, sepeda, kosong, 0.45).keadaan), 0.45) and Tabrakan.lewat_jatuh_detik(t2) == 0.0, "lewat jatuh 0,45 sesudah 0,45 detik; 0 sesudah bangun")


func _test_jatuh_di_bike_motion() -> void:
	_judul.call("Jatuh di BikeMotion: kecepatan 0 dan stick diabaikan selama jatuh, sesudah bangun dikayuh lagi dari 0 (pemilik 2026-10-17)")
	# Integrasi murni: Tabrakan memberi sisa jatuh sebagai beku_detik, stick penuh ke atas dan ke sisi dekat ditahan sepanjang jatuh.
	var sepeda: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
	sepeda.kecepatan_ud = 6.0
	sepeda.lateral_ubin = -1.0
	sepeda.stamina = 40.0
	sepeda = Tabrakan.terapkan_ke_sepeda(sepeda)
	var anjing: Array[Tabrakan.Kandidat] = [Tabrakan.kandidat(3, "anjing_penjaga", Rect2(-1.2, 9.9, 0.5, 0.5))]
	var t: Tabrakan.Keadaan = Tabrakan.langkah(Tabrakan.awal(), Tabrakan.kotak_sepeda(10.0, -1.0), anjing, 0.1).keadaan
	var kosong: Array[Tabrakan.Kandidat] = []
	var jarak: float = 0.0
	var diam: bool = true
	for i: int in range(12):
		var hb: BikeMotion.Hasil = BikeMotion.langkah(sepeda, Vector2(1.0, 1.0), 0.1, t.jatuh_detik)
		sepeda = hb.keadaan
		jarak += hb.maju_ubin
		diam = diam and sepeda.kecepatan_ud == 0.0 and hb.maju_ubin == 0.0 and hb.lateral_ud == 0.0
		t = Tabrakan.langkah(t, Tabrakan.kotak_sepeda(10.0, -1.0), kosong, 0.1).keadaan
	check(diam and jarak == 0.0 and sepeda.lateral_ubin == -1.0, "12 langkah x 0,1 jatuh dengan stick penuh atas-dekat: kecepatan 0, jarak 0, lateral tetap -1,0")
	check(sepeda.stamina == 40.0 and not sepeda.rem_aktif, "selama jatuh stamina tidak berubah (40) dan rem tidak aktif")
	check(not Tabrakan.jatuh(t) and t.jatuh_detik == 0.0, "kontrol: sesudah 1,2 detik pemain bangun")
	var hb1: BikeMotion.Hasil = BikeMotion.langkah(sepeda, Vector2(0.0, 1.0), 0.1, t.jatuh_detik)
	check(is_equal_approx(hb1.keadaan.kecepatan_ud, 0.3) and is_equal_approx(hb1.maju_ubin, 0.015), "langkah pertama sesudah bangun: stick berlaku, naik 3,0 u/d^2 dari 0 -> 0,3, maju 0,015")
	# Mode bantu dan stick netral: melanjutkan sendiri ke santai 3,0 dalam 1,0 detik sesudah bangun.
	var santai: BikeMotion.Keadaan = sepeda
	for i: int in range(10):
		santai = BikeMotion.langkah(santai, Vector2.ZERO, 0.1, 0.0).keadaan
	check(is_equal_approx(santai.kecepatan_ud, 3.0), "stick netral (juga mode bantu): 0 -> santai 3,0 tepat 1,0 detik sesudah bangun")
	# Rem dan stamina tidak berubah karena stick ke bawah selama jatuh.
	var rem: BikeMotion.Keadaan = Tabrakan.terapkan_ke_sepeda(BikeMotion.Keadaan.new())
	rem.stamina = 50.0
	for i: int in range(12):
		rem = BikeMotion.langkah(rem, Vector2(0.0, -1.0), 0.1, 1.2 - 0.1 * i).keadaan
	check(not rem.rem_aktif and rem.tahan_rem_detik == 0.0 and rem.stamina == 50.0, "stick bawah penuh 1,2 detik selama jatuh: rem tidak aktif, lama tahan 0, stamina 50 tetap (tanpa +15/d)")
	var rem_menyala: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
	rem_menyala.kecepatan_ud = 0.0
	rem_menyala.rem_aktif = true
	rem_menyala.tahan_rem_detik = 0.5
	var padam: BikeMotion.Keadaan = BikeMotion.langkah(rem_menyala, Vector2(0.0, -1.0), 0.1, 1.0).keadaan
	check(not padam.rem_aktif and padam.tahan_rem_detik == 0.0, "keadaan dengan rem menyala yang masuk jatuh: rem padam dan lama tahan 0 (BikeMotion sendiri, tidak bergantung pemanggil)")
	# Langkah yang melewati akhir jatuh: 0,2 diam lalu 0,3 gerak biasa, sama dengan dua langkah terpisah.
	var nol: BikeMotion.Keadaan = Tabrakan.terapkan_ke_sepeda(BikeMotion.Keadaan.new())
	var gabung: BikeMotion.Hasil = BikeMotion.langkah(nol, Vector2(1.0, 1.0), 0.5, 0.2)
	check(is_equal_approx(gabung.keadaan.kecepatan_ud, 0.9) and is_equal_approx(gabung.maju_ubin, 0.135) and is_equal_approx(gabung.keadaan.lateral_ubin, 0.9) and is_equal_approx(gabung.lateral_ud, 1.8), "dt 0,5 dengan sisa jatuh 0,2: 0,3 detik gerak -> kecepatan 0,9, maju 0,135, lateral 0,9 (lateral efektif 1,8 u/d atas 0,5 detik)")
	var a: BikeMotion.Hasil = BikeMotion.langkah(nol, Vector2(1.0, 1.0), 0.2, 0.2)
	var b: BikeMotion.Hasil = BikeMotion.langkah(a.keadaan, Vector2(1.0, 1.0), 0.3, 0.0)
	check(is_equal_approx(b.keadaan.kecepatan_ud, gabung.keadaan.kecepatan_ud) and is_equal_approx(a.maju_ubin + b.maju_ubin, gabung.maju_ubin) and is_equal_approx(b.keadaan.lateral_ubin, gabung.keadaan.lateral_ubin), "0,2 jatuh + 0,3 gerak dalam dua langkah = satu langkah 0,5")
	# Jeda (dt 0) saat jatuh: stick dianggap netral untuk pose dan tingkat sprite.
	var beku: BikeMotion.Hasil = BikeMotion.langkah(nol, Vector2(0.0, 1.0), 0.0, 1.0)
	check(beku.keadaan.kecepatan_ud == 0.0 and beku.stick_maju == 0.0 and beku.tingkat_sprite == 0, "dt 0 saat jatuh: kecepatan 0, stick maju 0, tingkat sprite santai (stick diabaikan)")
	check(BikeMotion.langkah(nol, Vector2(0.0, 1.0), 0.1, NAN).keadaan.kecepatan_ud > 0.0 and BikeMotion.langkah(nol, Vector2(0.0, 1.0), 0.1, -1.0).keadaan.kecepatan_ud > 0.0, "beku NaN atau negatif = tidak jatuh")
	var biasa: BikeMotion.Hasil = BikeMotion.langkah(BikeMotion.Keadaan.new(), Vector2(0.0, 1.0), 0.1)
	check(is_equal_approx(biasa.keadaan.kecepatan_ud, 3.3), "tanpa argumen beku perilaku lama tetap (3,0 -> 3,3)")


func _test_frame_jatuh() -> void:
	_judul.call("Pemilihan frame jatuh: jatuh_normal 10 fps sekali lalu terjerembab_normal 3 fps berulang, semua arah (pemilik 2026-10-17)")
	# [lewat detik, nama, frame] dengan fps dan jumlah frame dari README jatuh (4 frame 10 fps, 2 frame 3 fps), dihitung tangan.
	var kasus: Array = [[0.0, &"jatuh_normal", 0], [0.05, &"jatuh_normal", 0], [0.1, &"jatuh_normal", 1], [0.25, &"jatuh_normal", 2],
		[0.35, &"jatuh_normal", 3], [0.3999, &"jatuh_normal", 3], [0.4, &"terjerembab_normal", 0], [0.7, &"terjerembab_normal", 0],
		[0.7334, &"terjerembab_normal", 1], [1.0, &"terjerembab_normal", 1], [1.0667, &"terjerembab_normal", 0], [1.2, &"terjerembab_normal", 0]]
	var semua: bool = true
	var beda: Array[String] = []
	for arah: int in range(-2, 3):
		for k: Array in kasus:
			var f: LoperAnim.FrameJatuh = LoperAnim.frame_jatuh(k[0], arah, 10.0, 4, 3.0, 2)
			if f.nama != k[1] or f.frame != k[2]:
				semua = false
				beda.append("arah %d t %.4f: %s f%d" % [arah, k[0], f.nama, f.frame])
	check(semua, "12 saat x 5 arah: nama dan frame sesuai (tepat 0,4 = terjerembab frame 0); beda: %s" % [beda])
	var tengah: LoperAnim.FrameJatuh = LoperAnim.frame_jatuh(0.05, 0, 10.0, 4, 3.0, 2)
	check(is_equal_approx(tengah.progres, 0.5), "0,05 detik: progres frame 0,5")
	check(LoperAnim.frame_jatuh(NAN, 1, 10.0, 4, 3.0, 2).nama == &"jatuh_normal" and LoperAnim.frame_jatuh(-1.0, 1, 10.0, 4, 3.0, 2).frame == 0, "NaN atau negatif = awal jatuh")
	check(LoperAnim.frame_jatuh(0.9, 0, 0.0, 4, 3.0, 2).nama == &"jatuh_normal" and LoperAnim.frame_jatuh(0.9, 0, 10.0, 0, 3.0, 2).frame == 0, "fps atau jumlah frame tidak sah: frame 0 jatuh (tanpa bagi nol)")
	check(LoperAnim.nama_jatuh(-2) == &"jatuh_normal" and LoperAnim.nama_terjerembab(2) == &"terjerembab_normal", "arah diabaikan: semua arah memakai normal (aset arah lain Fase 5)")


## Pemain yang jatuh di dalam bentuk mobil yang sudah berhenti di garis tengah tidak terkunci (keputusan pemilik 2026-10-17): sesudah bangun
## ia dikayuh lagi dan keluar dari bentuk mobil tanpa tabrakan kedua (menempel), lalu melaju normal. Simulasi murni dengan urutan langkah scene.
func _test_jatuh_di_kotak_mobil_tidak_terkunci() -> void:
	_judul.call("Jatuh di dalam bentuk mobil yang berhenti di garis tengah: tidak terkunci, keluar tanpa tabrakan kedua")
	var dt: float = 1.0 / 60.0
	var r: RintanganRute.Keadaan = _satu("mobil_garasi", 20.0, "seberang")
	# Sepeda diam di maju 11 (masuk tanda 9) di separuh dekat sampai mobil berhenti: tanda 1,5 + mundur 2,5 = 4,0 detik.
	for i: int in range(300):
		r = RintanganRute.langkah(r, 11.0, 1.0, 0.0, dt).keadaan
	check(r.daftar[0].mobil.status == MobilGarasi.Status.BERHENTI and _rect_sama(RintanganRute.kotak(r.daftar[0]), Rect2(-1.5, 19.625, 1.5, 0.75)), "kontrol: mobil berhenti, bentuk -1,5..0 x 19,625..20,375")
	for kasus: Array in [["netral", 0.0, 0.0], ["kayuh keras", 1.0, 0.0], ["menyamping ke dekat", 0.0, 1.0]]:
		var sepeda: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
		sepeda.lateral_ubin = -0.75
		var jarak: float = 18.0
		var rr: RintanganRute.Keadaan = r
		var tabrak: int = 0
		var waktu_tabrak: float = -1.0
		var waktu: float = 0.0
		var keluar: float = -1.0
		while waktu < 12.0:
			waktu += dt
			# Sebelum tabrakan stick netral (santai lurus ke mobil); sesudahnya stick kasus.
			var stick: Vector2 = Vector2.ZERO if tabrak == 0 else Vector2(kasus[2], kasus[1])
			var hb: BikeMotion.Hasil = BikeMotion.langkah(sepeda, stick, dt, rr.tabrakan.jatuh_detik)
			sepeda = hb.keadaan
			jarak += hb.maju_ubin
			var hr: RintanganRute.Hasil = RintanganRute.langkah(rr, jarak, sepeda.lateral_ubin, sepeda.kecepatan_ud, dt)
			rr = hr.keadaan
			if hr.tabrak:
				tabrak += 1
				waktu_tabrak = waktu
				sepeda = Tabrakan.terapkan_ke_sepeda(sepeda)
			if tabrak > 0 and keluar < 0.0 and not Tabrakan.bertumpuk(Tabrakan.kotak_sepeda(jarak, sepeda.lateral_ubin), RintanganRute.kotak(rr.daftar[0])):
				keluar = waktu
		var nama: String = kasus[0]
		check(tabrak == 1, "[%s] satu tabrakan saja (dapat %d)" % [nama, tabrak])
		check(keluar > 0.0 and keluar - waktu_tabrak < 3.5, "[%s] keluar dari bentuk mobil %.2f detik sesudah tabrakan (< jatuh 1,2 + kebal 1,0 + 1,3)" % [nama, keluar - waktu_tabrak])
		check(rr.tabrakan.menempel.is_empty() and sepeda.kecepatan_ud > 0.0, "[%s] sesudah keluar: tidak menempel lagi dan tetap melaju (%.2f u/d)" % [nama, sepeda.kecepatan_ud])


func _test_rintangan_langkah_tabrak() -> void:
	_judul.call("RintanganRute.langkah: tabrakan dari bentuk anjing, anjing penyebab berhenti, peristiwa tanda (AC-6, AC-8)")
	var r: RintanganRute.Keadaan = _satu("anjing_penjaga", 20.0, "seberang")
	var kejadian: Array[RintanganRute.Peristiwa] = []
	var hasil_tabrak: RintanganRute.Hasil = null
	var sepeda: float = 5.0
	for i: int in range(400):
		sepeda += 3.0 / 60.0
		var h: RintanganRute.Hasil = RintanganRute.langkah(r, sepeda, -2.0, 3.0, 1.0 / 60.0)
		r = h.keadaan
		for kj: RintanganRute.Kejadian in h.kejadian:
			kejadian.append(kj.peristiwa)
		if h.tabrak and hasil_tabrak == null:
			hasil_tabrak = h
	check(kejadian.slice(0, 2) == [RintanganRute.Peristiwa.ANJING_WASPADA, RintanganRute.Peristiwa.ANJING_MENGEJAR], "peristiwa berurutan: waspada (geram) lalu mengejar (gonggong)")
	check(hasil_tabrak != null and hasil_tabrak.jenis_tabrak == "anjing_penjaga" and hasil_tabrak.id_tabrak == 0, "sepeda santai di trotoar sisi anjing tertabrak anjing (jenis dibawa)")
	check(hasil_tabrak != null and hasil_tabrak.keadaan.daftar[0].anjing.status == AnjingPenjaga.Status.BERHENTI, "anjing penyebab berhenti mengejar sesudah menabrak")
	check(r.tabrakan.jumlah == 1, "satu anjing = satu tabrakan sepanjang lintasan (tanpa ganda)")
	var beku: RintanganRute.Hasil = RintanganRute.langkah(r, sepeda + 5.0, -2.0, 3.0, 0.0)
	check(beku.kejadian.is_empty() and not beku.tabrak and beku.keadaan.daftar[0].anjing.status == r.daftar[0].anjing.status, "dt 0: rintangan dan tabrakan membeku (AC-21)")


## QA-004 iterasi 1: anjing `BERHENTI` di batas halamannya tetap berbahaya (D-2, BALANCING 6c). Kasus nyata: sepeda berhenti tepat di depan
## batas halaman di sisi dekat, anjing berhenti di jalur separuh jalannya, lalu sepeda menyamping ke anjing yang berdiri itu.
func _test_anjing_berhenti_berbahaya() -> void:
	_judul.call("Anjing BERHENTI di batas halaman berbahaya: sepeda yang menyamping ke sana tertabrak (D-2, QA-004)")
	var mengejar: AnjingPenjaga.Keadaan = AnjingPenjaga.langkah(AnjingPenjaga.baru(20.0, LoperAnim.Sisi.SEBERANG, 9.0), 21.0, -1.0, 3.0, 0.1)
	var berhenti: AnjingPenjaga.Keadaan = AnjingPenjaga.kena_tabrak(mengejar)
	check(berhenti.status == AnjingPenjaga.Status.BERHENTI and AnjingPenjaga.berbahaya(berhenti), "anjing BERHENTI: berbahaya")
	var pulang: AnjingPenjaga.Keadaan = berhenti.salin()
	pulang.status = AnjingPenjaga.Status.PULANG
	var mundur: AnjingPenjaga.Keadaan = AnjingPenjaga.dengar_bel(mengejar)
	check(not AnjingPenjaga.berbahaya(pulang) and mundur.status == AnjingPenjaga.Status.MUNDUR and not AnjingPenjaga.berbahaya(mundur), "anjing PULANG dan MUNDUR: tidak berbahaya")
	# Sepeda diam di maju 23,5 lateral +1,0 (separuh dekat), dt 0,125 (pas di float): anjing seberang di 20 langsung mengejar dengan laju bawah
	# 2,0 u/d (sepeda berkecepatan 0), 0,25 ubin per langkah; menyamping 2,0 u/d ke -0,25 (tepi bentuk di garis tengah) dalam 10 langkah dan
	# berhenti di batas maju 20 + 3 = 23 pada langkah 12 (1,5 detik).
	var r: RintanganRute.Keadaan = _satu("anjing_penjaga", 20.0, "seberang")
	var tabrak_sebelum: bool = false
	var langkah_berhenti: int = -1
	for i: int in range(1, 31):
		var h: RintanganRute.Hasil = RintanganRute.langkah(r, 23.5, 1.0, 0.0, 0.125)
		r = h.keadaan
		tabrak_sebelum = tabrak_sebelum or h.tabrak
		if r.daftar[0].anjing.status == AnjingPenjaga.Status.BERHENTI:
			langkah_berhenti = i
			break
	var anjing: AnjingPenjaga.Keadaan = r.daftar[0].anjing
	check(langkah_berhenti == 12 and is_equal_approx(anjing.maju_ubin, 23.0) and is_equal_approx(anjing.lateral_ubin, -0.25) and not tabrak_sebelum, "anjing berhenti di batas halaman (-0,25; 23,0) di langkah 12 (3,0 ubin / 0,25 per langkah), sepeda di sisi dekat tidak tertabrak (dapat langkah %d)" % langkah_berhenti)
	# Sepeda menyamping ke (-0,25; 23,0) selama anjing masih berhenti (0,125 < 0,8 detik): bentuk sepeda -0,5..0 x 22,6..23,4 beririsan
	# dengan bentuk anjing -0,5..0 x 22,75..23,25.
	var hb: RintanganRute.Hasil = RintanganRute.langkah(r, 23.0, -0.25, 0.0, 0.125)
	check(hb.keadaan.daftar[0].anjing.status == AnjingPenjaga.Status.BERHENTI and hb.tabrak and hb.jenis_tabrak == "anjing_penjaga" and hb.id_tabrak == 0, "sepeda menyamping ke anjing yang berhenti di jalurnya: tabrakan dengan anjing_penjaga")


## QA-006 iterasi 1: lompatan DIAM -> MENGEJAR dalam satu langkah (dt besar sesudah lag, atau sepeda masuk jarak tanda dan titik rumah sekaligus)
## tetap memancarkan peristiwa waspada (geram) sebelum mengejar (gonggong), jadi bunyi tanda tidak hilang.
func _test_peristiwa_lompatan_diam_mengejar() -> void:
	_judul.call("Lompatan DIAM -> MENGEJAR dalam satu langkah: peristiwa waspada lalu mengejar (QA-006)")
	for maju: float in [20.0, 25.0]:
		var r: RintanganRute.Keadaan = _satu("anjing_penjaga", 20.0, "seberang")
		var h: RintanganRute.Hasil = RintanganRute.langkah(r, maju, 1.0, 3.0, 0.1)
		var peristiwa: Array[RintanganRute.Peristiwa] = []
		for kj: RintanganRute.Kejadian in h.kejadian:
			peristiwa.append(kj.peristiwa)
		check(r.daftar[0].anjing.status == AnjingPenjaga.Status.DIAM and h.keadaan.daftar[0].anjing.status == AnjingPenjaga.Status.MENGEJAR and peristiwa == [RintanganRute.Peristiwa.ANJING_WASPADA, RintanganRute.Peristiwa.ANJING_MENGEJAR], "anjing DIAM di 20, sepeda langsung di maju %.1f: MENGEJAR dengan peristiwa [waspada, mengejar], dapat %s" % [maju, peristiwa])


# --- Tanda sebelum bahaya (AC-3) ---

## Simulasi satu rintangan di maju 20 dengan sepeda berkecepatan tetap `v` di lateral tetap `l` dari maju 0, langkah `dt`. Mengembalikan
## [langkah tanda, langkah sentuh] (sentuh = bentuk rintangan pertama kali beririsan dengan jalur sepeda, yaitu pita lateral bentuk sepeda
## di sepanjang jalan); -1 bila tidak terjadi. Juga [tepi bentuk paling dekat garis tengah] di indeks 2.
func _tanda_sentuh(jenis: String, jalur: String, v: float, l: float, dt: float, langkah_maks: int) -> Array:
	var r: RintanganRute.Keadaan = _satu(jenis, 20.0, jalur)
	var pita_min: float = l - Config.TABRAKAN_SEPEDA_SETENGAH_LATERAL_UBIN
	var pita_maks: float = l + Config.TABRAKAN_SEPEDA_SETENGAH_LATERAL_UBIN
	var tanda: int = -1
	var sentuh: int = -1
	var tepi: float = -100.0 if jalur == "seberang" else 100.0
	for n: int in range(1, langkah_maks):
		var maju: float = v * dt * n
		r = RintanganRute.langkah(r, maju, l, v, dt).keadaan
		var item: RintanganRute.Item = r.daftar[0]
		var status_tanda: bool = (item.anjing != null and item.anjing.status != AnjingPenjaga.Status.DIAM) or (item.mobil != null and item.mobil.status != MobilGarasi.Status.DIAM)
		if tanda < 0 and status_tanda:
			tanda = n
		var k: Rect2 = RintanganRute.kotak(item)
		tepi = maxf(tepi, k.end.x) if jalur == "seberang" else minf(tepi, k.position.x)
		if sentuh < 0 and k.position.x < pita_maks and pita_min < k.end.x:
			sentuh = n
	return [tanda, sentuh, tepi]


func _test_tanda_literal() -> void:
	_judul.call("Tanda sebelum bahaya, oracle literal (AC-3): dt 1/8, ngebut 6,0 u/d (0,75 ubin per langkah), sepeda di tepi trotoar -2,0")
	# Anjing di maju 20: tanda saat sepeda >= 11 -> langkah 15 (11,25; t 1,875 s). Mengejar saat sepeda >= 20 -> langkah 27 (20,25); anjing
	# bergerak 0,25 ubin per langkah dari -2,75: langkah 27 pusat -2,5 (tepi -2,25 hanya bersentuhan dengan pita -2,25..-1,75), langkah 28
	# pusat -2,25 beririsan -> sentuh t 3,5 s. Selang 1,625 detik >= 1,5.
	var a: Array = _tanda_sentuh("anjing_penjaga", "seberang", 6.0, -2.0, 0.125, 80)
	check(a[0] == 15 and a[1] == 28, "anjing: tanda langkah 15 (1,875 s), sentuh langkah 28 (3,5 s), dapat %s" % [a.slice(0, 2)])
	check(is_equal_approx((a[1] - a[0]) * 0.125, 1.625), "anjing: selang tanda ke bahaya 1,625 detik")
	# Mobil di maju 20: tanda langkah 15; 12 langkah tanda (1,5 s) -> MUNDUR di langkah 26 (sisa 0); bagasi 2,5 - 0,125 per langkah:
	# langkah 27 2,375, langkah 28 2,25 (tepi bersentuhan), langkah 29 2,125 beririsan -> t 3,625 s. Selang 1,75 detik.
	var m: Array = _tanda_sentuh("mobil_garasi", "seberang", 6.0, -2.0, 0.125, 80)
	check(m[0] == 15 and m[1] == 29, "mobil: tanda langkah 15, sentuh langkah 29, dapat %s" % [m.slice(0, 2)])
	check(is_equal_approx((m[1] - m[0]) * 0.125, 1.75), "mobil: selang tanda ke bahaya 1,75 detik")


func _test_tanda_invarian() -> void:
	_judul.call("Tanda >= 1,5 detik pada ngebut untuk semua posisi lateral -2..2 dan tidak lebih pendek pada kecepatan lebih rendah (AC-3, AC-23 c)")
	var dt: float = 1.0 / 60.0
	var terpendek: float = INF
	var semua_sah: bool = true
	var urutan_sah: bool = true
	var separuh_sah: bool = true
	var jumlah_kasus: int = 0
	for jenis: String in ["anjing_penjaga", "mobil_garasi"]:
		for jalur: String in ["seberang", "dekat"]:
			for i: int in range(17):
				var l: float = -2.0 + 0.25 * i
				var selang: Array[float] = []
				for v: float in [Config.KECEPATAN_SANTAI_UD, Config.KECEPATAN_CEPAT_UD, Config.KECEPATAN_NGEBUT_UD]:
					var hasil: Array = _tanda_sentuh(jenis, jalur, v, l, dt, int(40.0 / v / dt))
					jumlah_kasus += 1
					if hasil[0] < 0:
						semua_sah = false
					if jalur == "seberang" and hasil[2] > TOL or jalur == "dekat" and hasil[2] < -TOL:
						separuh_sah = false
					selang.append(INF if hasil[1] < 0 else (hasil[1] - hasil[0]) * dt)
				if selang[0] < 1.5 or selang[1] < 1.5 or selang[2] < 1.5:
					semua_sah = false
				terpendek = minf(terpendek, selang[2])
				# Tak hingga = rintangan tidak pernah sampai ke jalur itu pada kecepatan tersebut (mis. anjing sudah di batas halaman
				# sebelum sampai dekat garis tengah saat sepeda cepat); bandingkan hanya pasangan yang sama-sama terjadi.
				for p: int in range(2):
					if is_finite(selang[p]) and is_finite(selang[p + 1]) and selang[p] + TOL < selang[p + 1]:
						urutan_sah = false
	check(jumlah_kasus == 204, "204 kasus (2 jenis x 2 jalur x 17 lateral x 3 kecepatan)")
	check(semua_sah, "tiap kasus memberi tanda, dan di santai, cepat, dan ngebut selang tanda ke sentuh >= 1,5 detik (terpendek pada ngebut %.3f)" % terpendek)
	check(terpendek >= 1.5 and terpendek < 2.0, "selang terpendek pada ngebut %.3f detik (di tepi trotoar sisi rintangan)" % terpendek)
	check(urutan_sah, "selang santai >= cepat >= ngebut di tiap posisi lateral (bila bahaya terjadi di kedua kecepatan)")
	check(separuh_sah, "rintangan tidak pernah melewati garis tengah: separuh jalan lawan selalu bebas (K-1)")


# --- Ngebut dan santai punya harga (AC-23 b, sisi rintangan) ---

func _test_ngebut_santai_punya_harga() -> void:
	_judul.call("Ngebut punya harga dan santai punya harga (AC-23 b): reaksi lebih pendek saat ngebut, anjing menyusul pemain santai")
	var dt: float = 1.0 / 60.0
	var selang: Dictionary = {}
	var tabrak: Dictionary = {}
	for v: float in [Config.KECEPATAN_SANTAI_UD, Config.KECEPATAN_NGEBUT_UD]:
		var r: RintanganRute.Keadaan = _satu("anjing_penjaga", 20.0, "seberang")
		var tanda: int = -1
		var kejar: int = -1
		var kena: bool = false
		for n: int in range(1, int(30.0 / v / dt)):
			var h: RintanganRute.Hasil = RintanganRute.langkah(r, v * dt * n, -1.0, v, dt)
			r = h.keadaan
			var st: AnjingPenjaga.Status = r.daftar[0].anjing.status
			if tanda < 0 and st == AnjingPenjaga.Status.WASPADA:
				tanda = n
			if kejar < 0 and st == AnjingPenjaga.Status.MENGEJAR:
				kejar = n
			kena = kena or h.tabrak
		selang[v] = (kejar - tanda) * dt
		tabrak[v] = kena
	check(absf(selang[Config.KECEPATAN_SANTAI_UD] - 3.0) < 0.02 and absf(selang[Config.KECEPATAN_NGEBUT_UD] - 1.5) < 0.02, "tanda ke anjing mengejar: santai sekitar 3,0 detik, ngebut sekitar 1,5 detik (dapat %.3f / %.3f)" % [selang[Config.KECEPATAN_SANTAI_UD], selang[Config.KECEPATAN_NGEBUT_UD]])
	check(tabrak[Config.KECEPATAN_SANTAI_UD], "pemain santai di tengah separuh jalan anjing (-1,0) tersusul dan tertabrak anjing")
	check(not tabrak[Config.KECEPATAN_NGEBUT_UD], "pemain ngebut di posisi yang sama lolos dari anjing")


# --- Simulasi rute penuh ---

## Simulasi headless satu rute. `bot` = "bebas" (tetap di sisi bebas rintangan yang relevan) atau "tabrak" (sengaja menuju tiap
## rintangan). `maju_stick` = komponen maju stick (0 = santai). Hasil: Dictionary {tabrak: jumlah, id_tabrak: Dictionary, selesai: jumlah
## `baru_selesai`, waktu, okupansi_ok, separuh_ok, pulih_ok, jarak, kecepatan_min_sebelum_akhir, tenggat (detik), waktu_akhir (jam tenggat
## saat garis akhir), tenggat_lewat (di garis akhir)}. `rem_detik` > 0 = bot berhenti lama dulu: stick ditarik penuh ke bawah (rem) selama
## sekian detik di awal rute, lalu santai (run fase3c-hud-hasil, AC-3).
func _sim_rute(rute: RouteBuilder.Rute, bot: String, maju_stick: float, rem_detik: float = 0.0) -> Dictionary:
	var dt: float = DT_RUTE
	var sepeda: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
	var jarak: float = 0.0
	var r: RintanganRute.Keadaan = RintanganRute.dari_rute(rute)
	var skor: SkorRute.Keadaan = SkorRute.awal()
	var selesai: bool = false
	var jumlah_selesai: int = 0
	var id_tabrak: Dictionary = {}
	var jumlah_tabrak: int = 0
	var combo_putus_ok: bool = true
	var pulih_ok: bool = true
	var detik_sejak_tabrak: float = -1.0
	var pulih_maks: float = 0.0
	var nol_luar_jatuh: bool = false
	var separuh_ok: bool = true
	var bucket: float = 0.25
	var n_bucket: int = int(ceil(rute.panjang_ubin / bucket)) + 8
	# Per bucket maju: tepi bentuk seberang yang paling dekat ke tengah, dan dekat.
	var tepi_seb: PackedFloat64Array = PackedFloat64Array()
	var tepi_dek: PackedFloat64Array = PackedFloat64Array()
	tepi_seb.resize(n_bucket)
	tepi_dek.resize(n_bucket)
	tepi_seb.fill(-100.0)
	tepi_dek.fill(100.0)
	var waktu: float = 0.0
	var waktu_maks: float = rute.panjang_ubin / Config.KECEPATAN_MELAMBAT_UD + 60.0 + rem_detik
	var kec_min: float = INF
	var tenggat: TenggatRute.Keadaan = TenggatRute.awal(rute.panjang_ubin)
	while waktu < waktu_maks:
		waktu += dt
		tenggat = TenggatRute.langkah(tenggat, dt)
		var stick: Vector2 = Vector2(0.0, maju_stick)
		if waktu <= rem_detik:
			stick = Vector2(0.0, -1.0)
		var sasaran: float = _sasaran_bot(bot, r, jarak, id_tabrak)
		stick.x = clampf((sasaran - sepeda.lateral_ubin) / (Config.KECEPATAN_LATERAL_UD * dt), -1.0, 1.0)
		if selesai:
			stick = AkhirRute.stick_akhir()
		var jatuh_awal: bool = Tabrakan.jatuh(r.tabrakan)
		var hb: BikeMotion.Hasil = BikeMotion.langkah(sepeda, stick, dt, r.tabrakan.jatuh_detik)
		sepeda = hb.keadaan
		jarak += hb.maju_ubin
		if not selesai and not jatuh_awal and sepeda.kecepatan_ud <= 0.0:
			nol_luar_jatuh = true
		var hr: RintanganRute.Hasil = RintanganRute.langkah(r, jarak, sepeda.lateral_ubin, sepeda.kecepatan_ud, dt)
		r = hr.keadaan
		if hr.tabrak:
			jumlah_tabrak += 1
			id_tabrak[hr.id_tabrak] = true
			sepeda = Tabrakan.terapkan_ke_sepeda(sepeda)
			skor = SkorRute.nilai(skor, ZonaSasaran.Hasil.KOTAK_SURAT, "uji@%d" % jumlah_tabrak, false, Config.KECEPATAN_SANTAI_UD, false, false).keadaan
			skor = SkorRute.putus_combo(skor)
			combo_putus_ok = combo_putus_ok and skor.beruntun == 0
			detik_sejak_tabrak = 0.0
		elif detik_sejak_tabrak >= 0.0:
			detik_sejak_tabrak += dt
			if sepeda.kecepatan_ud >= Config.KECEPATAN_SANTAI_UD - 0.01:
				pulih_maks = maxf(pulih_maks, detik_sejak_tabrak)
				detik_sejak_tabrak = -1.0
			elif detik_sejak_tabrak > 3.0 and not selesai:
				pulih_ok = false
				detik_sejak_tabrak = -1.0
		if not selesai and waktu > rem_detik:
			kec_min = minf(kec_min, sepeda.kecepatan_ud)
		for item: RintanganRute.Item in r.daftar:
			var k: Rect2 = RintanganRute.kotak(item)
			var seberang: bool = (item.anjing != null and item.anjing.sisi == LoperAnim.Sisi.SEBERANG) or (item.mobil != null and item.mobil.sisi == LoperAnim.Sisi.SEBERANG)
			if seberang and k.end.x > TOL or not seberang and k.position.x < -TOL:
				separuh_ok = false
			var b0: int = maxi(int(floor(k.position.y / bucket)), 0)
			var b1: int = mini(int(floor((k.end.y - TOL) / bucket)), n_bucket - 1)
			for b: int in range(b0, b1 + 1):
				if seberang:
					tepi_seb[b] = maxf(tepi_seb[b], k.end.x)
				else:
					tepi_dek[b] = minf(tepi_dek[b], k.position.x)
		var status: AkhirRute.Status = AkhirRute.periksa(selesai, jarak, rute.panjang_ubin)
		selesai = status.selesai
		if status.baru_selesai:
			jumlah_selesai += 1
			tenggat = TenggatRute.hentikan(tenggat)
		if selesai and sepeda.kecepatan_ud <= 0.0:
			break
	# Jalan keluar (AC-4): di tiap bucket ada pusat sepeda di [-2, 2] (kisi 0,05) yang pitanya tidak beririsan dengan sisi mana pun.
	var okupansi_ok: bool = true
	var r_lat: float = Config.TABRAKAN_SEPEDA_SETENGAH_LATERAL_UBIN
	for b: int in range(n_bucket):
		var ada: bool = false
		for i: int in range(81):
			var l: float = -2.0 + 0.05 * i
			if l - r_lat >= tepi_seb[b] - TOL and l + r_lat <= tepi_dek[b] + TOL:
				ada = true
				break
		if not ada:
			okupansi_ok = false
	return {"tabrak": jumlah_tabrak, "id_tabrak": id_tabrak, "selesai": jumlah_selesai, "waktu": waktu, "okupansi_ok": okupansi_ok, "separuh_ok": separuh_ok, "pulih_ok": pulih_ok, "jarak": jarak, "kec_min": kec_min, "pulih_maks": pulih_maks, "nol_luar_jatuh": nol_luar_jatuh, "combo_putus_ok": combo_putus_ok, "berhenti": selesai and sepeda.kecepatan_ud <= 0.0, "tenggat": tenggat.tenggat_detik, "waktu_akhir": tenggat.waktu_detik, "tenggat_lewat": TenggatRute.lewat(tenggat)}


## Lateral sasaran bot. "bebas": rintangan relevan = titik rumah paling awal di [maju - 3,7, maju + 12]; sasaran sisi lawannya (+-0,5).
## "tabrak": rintangan terdekat yang belum ditabrak di [maju - 4, maju + 12]; sasaran lateral pusatnya dijepit ke [-2, 2].
func _sasaran_bot(bot: String, r: RintanganRute.Keadaan, maju: float, sudah: Dictionary) -> float:
	var pilih: RintanganRute.Item = null
	var rumah_pilih: float = INF
	for item: RintanganRute.Item in r.daftar:
		var rumah: float = item.anjing.rumah_maju_ubin if item.anjing != null else item.mobil.maju_ubin
		if bot == "bebas":
			if rumah - maju >= -3.7 and rumah - maju <= 12.0 and rumah < rumah_pilih:
				pilih = item
				rumah_pilih = rumah
		else:
			if not sudah.has(item.id) and rumah - maju >= -4.0 and rumah - maju <= 12.0 and rumah < rumah_pilih:
				pilih = item
				rumah_pilih = rumah
	if pilih == null:
		return 0.0
	var sisi: LoperAnim.Sisi = pilih.anjing.sisi if pilih.anjing != null else pilih.mobil.sisi
	if bot == "bebas":
		return 0.5 if sisi == LoperAnim.Sisi.SEBERANG else -0.5
	return clampf(RintanganRute.posisi(pilih).x, -2.0, 2.0)


func _test_rute_jalan_keluar_20_seed() -> void:
	_judul.call("Jalan keluar selalu ada di 20 rute seed; pemain santai di sisi bebas tidak pernah bertabrakan (AC-4)")
	var tanpa_tabrak: int = 0
	var okupansi: int = 0
	var separuh: int = 0
	var selesai: int = 0
	var gagal: Array[int] = []
	var ngebut_bersih: int = 0
	for i: int in range(20):
		var benih: int = Config.RUTE_SEED_DEV + i
		var rute: RouteBuilder.Rute = _rute(benih)
		if rute == null:
			gagal.append(benih)
			continue
		var h: Dictionary = _sim_rute(rute, "bebas", 0.0)
		if h["tabrak"] == 0:
			tanpa_tabrak += 1
		else:
			gagal.append(benih)
		# Ngebut (stick penuh; lelah menjepit ke cepat sesudah stamina habis) di sisi bebas juga tanpa tabrakan.
		var hn: Dictionary = _sim_rute(rute, "bebas", 1.0)
		if hn["tabrak"] == 0 and hn["okupansi_ok"]:
			ngebut_bersih += 1
		if h["okupansi_ok"]:
			okupansi += 1
		if h["separuh_ok"]:
			separuh += 1
		if h["selesai"] == 1:
			selesai += 1
	check(tanpa_tabrak == 20, "20 rute: bot santai di sisi bebas tanpa tabrakan (gagal: %s)" % [gagal])
	check(okupansi == 20, "20 rute: di setiap posisi maju ada posisi lateral yang tidak dimasuki rintangan (%d/20)" % okupansi)
	check(separuh == 20, "20 rute: tidak ada rintangan yang melewati garis tengah (%d/20)" % separuh)
	check(selesai == 20, "20 rute: garis akhir tercapai tepat sekali (%d/20)" % selesai)
	check(ngebut_bersih == 20, "20 rute: bot ngebut di sisi bebas juga tanpa tabrakan dan jalan keluar tetap ada (%d/20)" % ngebut_bersih)


## Run fase3c-hud-hasil AC-3, AC-18: bot santai (kecepatan otomatis mode bantu = stick netral) yang tidak berhenti menyelesaikan rute
## sebelum tenggat tanpa tabrakan di 20 seed; bot yang berhenti lama (rem 100 detik) melewati tenggat tetapi tetap menyelesaikan rute,
## garis akhir tepat sekali (tenggat tidak menghentikan rute; santai punya harga bila berhenti lama).
func _test_tenggat_rute_20_seed() -> void:
	_judul.call("Tenggat (AC-3, AC-18): santai tanpa berhenti sempat di 20 seed; berhenti lama lewat tenggat tapi rute tetap selesai")
	var sempat: int = 0
	var gagal: Array[int] = []
	var cadangan_min: float = INF
	for i: int in range(20):
		var benih: int = Config.RUTE_SEED_DEV + i
		var rute: RouteBuilder.Rute = _rute(benih)
		if rute == null:
			gagal.append(benih)
			continue
		var h: Dictionary = _sim_rute(rute, "bebas", 0.0)
		if h["selesai"] == 1 and h["tabrak"] == 0 and not h["tenggat_lewat"] and float(h["waktu_akhir"]) <= float(h["tenggat"]):
			sempat += 1
			cadangan_min = minf(cadangan_min, float(h["tenggat"]) - float(h["waktu_akhir"]))
		else:
			gagal.append(benih)
	check(sempat == 20, "20 rute: santai tanpa berhenti sampai garis akhir sebelum tenggat, tanpa tabrakan (gagal: %s)" % [gagal])
	# Waktu tempuh santai = panjang / 3,0 (77,3 sampai 80 detik) lawan tenggat 89 sampai 92: cadangan paling sedikit sekitar 11 detik.
	check(cadangan_min >= 10.0, "cadangan waktu santai paling sedikit 10 detik (dapat %.2f)" % cadangan_min)
	for benih: int in [Config.RUTE_SEED_DEV, Config.RUTE_SEED_DEV + 1, Config.RUTE_SEED_DEV + 2]:
		var rute: RouteBuilder.Rute = _rute(benih)
		if rute == null:
			check(false, "seed %d dibangun" % benih)
			continue
		var h: Dictionary = _sim_rute(rute, "bebas", 0.0, 100.0)
		check(h["tenggat_lewat"] and float(h["waktu_akhir"]) > float(h["tenggat"]), "seed %d: berhenti 100 detik -> tenggat lewat (jam %.1f dari %d)" % [benih, h["waktu_akhir"], h["tenggat"]])
		check(h["selesai"] == 1 and h["jarak"] >= rute.panjang_ubin and h["berhenti"], "seed %d: sesudah tenggat lewat rute tetap selesai, garis akhir tepat sekali, sepeda berhenti" % benih)


func _test_tabrakan_tidak_menghentikan_rute() -> void:
	_judul.call("Tabrakan tidak menghentikan rute (AC-7, AC-23 a): bot sengaja menabrak setiap rintangan tetap sampai garis akhir")
	for benih: int in [Config.RUTE_SEED_DEV, Config.RUTE_SEED_DEV + 1, Config.RUTE_SEED_DEV + 2]:
		var rute: RouteBuilder.Rute = _rute(benih)
		if rute == null:
			check(false, "seed %d dibangun" % benih)
			continue
		var h: Dictionary = _sim_rute(rute, "tabrak", 0.0)
		check((h["id_tabrak"] as Dictionary).size() == rute.objek.size() and rute.objek.size() == 11, "seed %d: setiap rintangan (%d) ditabrak paling sedikit sekali (dapat %d, total %d tabrakan)" % [benih, rute.objek.size(), (h["id_tabrak"] as Dictionary).size(), h["tabrak"]])
		check(h["tabrak"] <= rute.objek.size() + 2, "seed %d: tanpa tabrakan beruntun berulang (%d tabrakan)" % [benih, h["tabrak"]])
		check(h["selesai"] == 1 and h["jarak"] >= rute.panjang_ubin, "seed %d: garis akhir tercapai, rute_selesai tepat sekali" % benih)
		check(h["berhenti"], "seed %d: sesudah garis akhir sepeda berhenti dengan rem biasa (tidak terkunci di tengah)" % benih)
		check(h["pulih_ok"] and h["pulih_maks"] <= 2.2 + 2.0 * DT_RUTE + TOL, "seed %d: sesudah tiap tabrakan kecepatan kembali ke santai dalam jatuh 1,2 + akselerasi 1,0 = 2,2 detik (terlama %.3f)" % [benih, h["pulih_maks"]])
		check(h["kec_min"] == 0.0 and not h["nol_luar_jatuh"], "seed %d: kecepatan 0 hanya selama jatuh, tidak pernah di luar jatuh sebelum akhir (tidak terkunci)" % benih)
		check(h["combo_putus_ok"], "seed %d: tiap tabrakan memutus combo" % benih)
		check(h["okupansi_ok"] and h["separuh_ok"], "seed %d: bot penabrak pun tidak membuat rintangan menutup seluruh lebar jalan" % benih)
		# Batas atas: santai murni + tiap tabrakan paling mahal jatuh 1,2 + akselerasi penuh 1,0 (sebenarnya tertinggal 0,5) + 5 detik rem dan
		# belok. Hasil 2026-10-17: 98,2 detik untuk santai murni 78,7 dan 11 tabrakan (sekitar 1,7 detik per tabrakan).
		var batas: float = rute.panjang_ubin / Config.KECEPATAN_SANTAI_UD + float(h["tabrak"]) * 2.2 + 5.0
		check(h["waktu"] < batas, "seed %d: rute selesai dalam %.1f detik (< santai murni %.1f + %d tabrakan x 2,2 + 5 = %.1f)" % [benih, h["waktu"], rute.panjang_ubin / Config.KECEPATAN_SANTAI_UD, h["tabrak"], batas])
