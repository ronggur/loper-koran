class_name TesLempar
extends RefCounted
## Tes logika murni run fase2a-lemparan bagian 1a dan run fase2-arah-bebas (arah bebas: AC-2 arah, AC-3 tanpa sudut ditolak, AC-4 sisi,
## AC-5 zona dari titik mendarat, AC-6 regresi laporan pemilik, AC-8 penjaga aturan lama): `ThrowSolver` (AC-2 rumus D-2, AC-3 lengkung D-3, AC-4 prediksi = hasil D-4,
## bagian murni), tinggi z di `Iso`, `LemparWaktu.waktu_lepas`, `ZonaSasaran` (AC-5 zona, prioritas, sakelar jendela D-7,
## keterjangkauan, penanda D-10), dan `SisaKoran` (AC-6 sisa koran, jeda 0,35, isi ulang jalan uji; D-8, D-9, D-11 bagian murni).
##
## Dipanggil dari `tests/run_tests.gd` (`TesLempar.new(check, judul).jalankan()`), memakai `check` milik runner. Tanpa node: waktu
## selalu parameter (rule `testing`).

## Lebar viewport game yang didukung (16:9, 19,5:9, 20:9).
const LEBAR: Array[float] = [640.0, 780.0, 800.0]
## Kecepatan uji, u/d: berhenti, santai, cepat, ngebut (BALANCING 2).
const KECEPATAN: Array[float] = [0.0, 3.0, 4.5, 6.0]
## Toleransi perbandingan rumus (float64 di skalar, Vector2 berpresisi tunggal di posisi), ubin / detik.
const TOL: float = 0.00001
## Toleransi AC-4 (prediksi = hasil), ubin.
const TOL_PREDIKSI: float = 0.0001
## Sudut swipe uji arah bebas (derajat di layar: 0 = kanan, 90 = atas), termasuk sudut yang ditolak Run 2A (45 sampai 135, AC-2).
const SUDUT_UJI: Array[float] = [0.0, 30.0, 45.0, 60.0, 78.0, 90.0, 100.0, 115.0, 135.0, 150.0, 180.0, 200.0, 225.0, 250.0, 270.0, 290.0, 315.0, 340.0]
## Berkas yang tidak boleh lagi memuat aturan lama "dominan datar" atau |dx| (AC-8).
const BERKAS_JALUR_LEMPAR: Array[String] = ["res://scripts/systems/throw_solver.gd", "res://scripts/systems/zona_sasaran.gd", "res://scripts/systems/koran_lempar.gd", "res://scripts/systems/loper_anim.gd", "res://scripts/entities/jalan_uji.gd", "res://scripts/config.gd"]
## Toleransi tinggi puncak dari sampel rapat (AC-3), ubin.
const TOL_PUNCAK: float = 0.001
## fps dan jumlah frame animasi lempar (`loper_agen_frames.tres`, diperiksa di `_test_waktu_lepas`).
const FPS_LEMPAR: float = 12.0
const FRAME_LEMPAR: int = 4
const BERKAS_FRAMES: String = "res://assets/sprites/loper/loper_agen_frames.tres"
## Nama konstanta lintasan yang hanya boleh dipakai `ThrowSolver` (penjaga AC-4: tidak ada rumus lintasan kedua).
const KONSTANTA_LINTASAN: Array[String] = ["LEMPAR_JARAK_", "LEMPAR_TERBANG_", "LEMPAR_PUNCAK_", "LEMPAR_WARISAN_MAJU", "LEMPAR_TINGGI_TANGAN", "LEMPAR_SWIPE_"]
const BERKAS_SOLVER: String = "res://scripts/systems/throw_solver.gd"
const BERKAS_CONFIG: String = "res://scripts/config.gd"

var _cek: Callable
var _judul: Callable


func _init(cek: Callable, judul: Callable) -> void:
	_cek = cek
	_judul = judul


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_test_config_lempar()
	_test_swipe_lebar()
	_test_rumus()
	_test_arah_bebas()
	_test_tanpa_sudut_ditolak()
	_test_sisi_arah()
	_test_penjaga_aturan_lama()
	_test_masukan_aneh_dan_murni()
	_test_titik_lepas()
	_test_iso_tinggi()
	_test_lengkung()
	_test_waktu_lepas()
	_test_prediksi_hasil()
	_test_penjaga_rumus()
	_test_zona_klasifikasi()
	_test_zona_prioritas()
	_test_antaran_dan_penanda()
	_test_zona_jalan_uji()
	_test_keterjangkauan()
	_test_zona_dari_titik()
	_test_regresi_pemilik()
	_test_sisa_koran()
	_test_jeda_antar_lempar()
	_test_isi_ulang()
	_test_koran_lempar()
	_test_titik_bidik()
	_test_pola_piksel()
	_test_tertutup_rumah()
	_test_bayangan_kontras()


# --- Pembantu ---

func _dekat(a: float, b: float, tol: float = TOL) -> bool:
	return absf(a - b) <= tol


func _dekat_v(a: Vector2, b: Vector2, tol: float = TOL) -> bool:
	return absf(a.x - b.x) <= tol and absf(a.y - b.y) <= tol


## Panjang swipe untuk kekuatan u di lebar `lebar` (min + u x (maks - min)).
func _panjang(u: float, lebar: float) -> float:
	return ThrowSolver.swipe_min_px(lebar) + u * (ThrowSolver.swipe_maks_px(lebar) - ThrowSolver.swipe_min_px(lebar))


## Vektor satuan swipe di layar untuk sudut `derajat` (0 = kanan, 90 = atas; y layar ke bawah).
func _arah_layar(derajat: float) -> Vector2:
	return Vector2(cos(deg_to_rad(derajat)), -sin(deg_to_rad(derajat)))


func _jeda_lepas() -> float:
	return LemparWaktu.waktu_lepas(FPS_LEMPAR, FRAME_LEMPAR, Config.LEMPAR_FRAME_LEPAS)


func _sama(a: ThrowSolver.Lintasan, b: ThrowSolver.Lintasan) -> bool:
	return a.sisi == b.sisi and a.arah == b.arah and a.kekuatan == b.kekuatan and a.titik_lepas == b.titik_lepas and a.titik_mendarat == b.titik_mendarat and a.lama_terbang == b.lama_terbang and a.tinggi_puncak == b.tinggi_puncak and a.lengkung_a == b.lengkung_a and a.lengkung_b == b.lengkung_b and a.jeda_lepas == b.jeda_lepas


# --- Config ---

func _test_config_lempar() -> void:
	_judul.call("Angka lemparan di Config = BALANCING 4 dan 5 (usulan run fase2a-lemparan)")
	check(Config.LEMPAR_SWIPE_MIN_PECAHAN == 0.06 and Config.LEMPAR_SWIPE_MAKS_PECAHAN == 0.35, "swipe min 6%, maks 35% lebar viewport (BALANCING 4)")
	check(Config.LEMPAR_JARAK_MIN_UBIN == 1.5 and Config.LEMPAR_JARAK_MAKS_UBIN == 5.0, "jarak ke samping 1,5 sampai 5,0 ubin")
	check(Config.LEMPAR_TERBANG_MIN_DETIK == 0.45 and Config.LEMPAR_TERBANG_MAKS_DETIK == 0.75, "lama terbang 0,45 sampai 0,75 detik")
	check(Config.LEMPAR_PUNCAK_MIN_UBIN == 1.0 and Config.LEMPAR_PUNCAK_MAKS_UBIN == 1.6, "tinggi puncak 1,0 sampai 1,6 ubin")
	check(Config.LEMPAR_WARISAN_MAJU == 1.0, "warisan kecepatan maju 100%")
	check(Config.LEMPAR_JEDA_DETIK == 0.35 and Config.KORAN_AWAL == 30, "jeda antar lempar 0,35 detik, koran awal 30 (25 pelanggan + 20%)")
	check(Config.PENANDA_LAMA_DETIK == 0.8 and Config.JALAN_UJI_ISI_ULANG_UBIN == 16.0, "penanda 0,8 detik (DESIGN_SPEC 3.6), isi ulang jalan uji sesudah 16 ubin")
	check(Config.JENDELA_KENA_BONUS == false, "sakelar jendela bawaan = penalti ringan (keputusan pemilik 2026-10-14, masih terbuka)")
	check(Config.LEMPAR_TINGGI_TANGAN_UBIN > 0.0 and Config.LEMPAR_TINGGI_TANGAN_UBIN < Config.LEMPAR_PUNCAK_MIN_UBIN, "tinggi tangan di atas tanah dan di bawah puncak terendah (lengkung naik dulu)")
	check(Config.LEMPAR_SWIPE_TOLERANSI_PX > 0.0 and Config.LEMPAR_SWIPE_TOLERANSI_PX < 0.01, "toleransi swipe hanya meredam derau presisi tunggal (< 0,01 px)")
	check(not (load(BERKAS_CONFIG) as Script).get_script_constant_map().has("LEMPAR_SWIPE_AMBANG_PX"), "ambang lama 12 px (LEMPAR_SWIPE_AMBANG_PX) sudah tidak ada (diganti 6% lebar viewport, D-2)")


# --- Swipe terhadap lebar viewport (D-2) ---

func _test_swipe_lebar() -> void:
	_judul.call("Panjang swipe |v| terhadap lebar viewport: min 6%, maks 35%, inklusif di min (D-2 Run 2A dan run fase2-arah-bebas)")
	for lebar: float in LEBAR:
		var bawah: float = ThrowSolver.swipe_min_px(lebar)
		var atas: float = ThrowSolver.swipe_maks_px(lebar)
		check(_dekat(bawah, lebar * 0.06) and _dekat(atas, lebar * 0.35), "lebar %s: min %s px, maks %s px (ikut lebar)" % [lebar, bawah, atas])
		check(ThrowSolver.kekuatan(bawah, lebar) == 0.0, "lebar %s: tepat min = u 0 (melempar, inklusif)" % lebar)
		check(ThrowSolver.kekuatan(bawah - 0.01, lebar) == -1.0 and not ThrowSolver.cukup_panjang(bawah - 0.01, lebar), "lebar %s: 0,01 px di bawah min tidak melempar" % lebar)
		check(_dekat(ThrowSolver.kekuatan((bawah + atas) / 2, lebar), 0.5), "lebar %s: tengah min-maks = u 0,5" % lebar)
		check(ThrowSolver.kekuatan(atas, lebar) == 1.0 and ThrowSolver.kekuatan(atas * 3, lebar) == 1.0, "lebar %s: tepat maks dan 3x maks = u 1 (dijepit)" % lebar)
		# Presisi tunggal: |v| dari Vector2 tepat di min tetap melempar.
		var dari_vektor: float = ThrowSolver.panjang_swipe(Vector2(400.0, 200.0), Vector2(400.0, 200.0) + Vector2(bawah, 0.0))
		check(ThrowSolver.cukup_panjang(dari_vektor, lebar), "lebar %s: |v| dari Vector2 (presisi tunggal, %s) di min tetap melempar" % [lebar, dari_vektor])
	# Swipe yang sama berbeda kekuatan di lebar berbeda (min/maks ikut lebar).
	check(ThrowSolver.cukup_panjang(40.0, 640.0) and not ThrowSolver.cukup_panjang(40.0, 780.0), "40 px melempar di 640 (min 38,4) tetapi tidak di 780 (min 46,8)")
	check(ThrowSolver.kekuatan(224.0, 640.0) == 1.0 and ThrowSolver.kekuatan(224.0, 800.0) < 1.0, "224 px = maks di 640 (35%), belum maks di 800 (280)")
	for lebar_salah: float in [0.0, -640.0, NAN, INF]:
		check(not ThrowSolver.cukup_panjang(100.0, lebar_salah) and ThrowSolver.kekuatan(100.0, lebar_salah) == -1.0, "lebar viewport tidak sah (%s): tidak melempar" % lebar_salah)
	for panjang_salah: float in [NAN, INF, -60.0]:
		check(ThrowSolver.kekuatan(panjang_salah, 780.0) == -1.0, "panjang swipe tidak sah (%s): tidak melempar" % panjang_salah)


# --- Rumus D-2 di empat kecepatan, kedua sisi ---

func _test_rumus() -> void:
	_judul.call("ThrowSolver: jarak, lama terbang, puncak, warisan maju, tanpa warisan lateral, arah melintang murni (D-2)")
	# [u, jarak, lama, puncak]
	var titik: Array = [[0.0, 1.5, 0.45, 1.0], [0.5, 3.25, 0.6, 1.3], [1.0, 5.0, 0.75, 1.6]]
	var posisi: Vector2 = Vector2(0.25, -37.5)
	for lebar: float in LEBAR:
		for v: float in KECEPATAN:
			for sisi: LoperAnim.Sisi in [LoperAnim.Sisi.SEBERANG, LoperAnim.Sisi.DEKAT]:
				var tanda: float = -1.0 if sisi == LoperAnim.Sisi.SEBERANG else 1.0
				var tag: String = "lebar %s, %s u/d, %s" % [lebar, v, "seberang" if tanda < 0.0 else "dekat"]
				for t: Array in titik:
					var u: float = t[0]
					var l: ThrowSolver.Lintasan = ThrowSolver.hitung(_panjang(u, lebar), lebar, ThrowSolver.arah_sisi(sisi), posisi, v, 0.0, 0.0)
					if l == null:
						check(false, "%s u %s: lintasan ada" % [tag, u])
						continue
					var ok_angka: bool = _dekat(l.kekuatan, u) and _dekat(l.jarak, t[1]) and _dekat(l.lama_terbang, t[2]) and _dekat(l.tinggi_puncak, t[3]) and l.sisi == sisi
					check(ok_angka, "%s u %s: jarak %s, lama %s, puncak %s, sisi dari arah (dapat %s, %s, %s)" % [tag, u, t[1], t[2], t[3], l.jarak, l.lama_terbang, l.tinggi_puncak])
					var lateral: float = l.titik_mendarat.x - l.titik_lepas.x
					var maju: float = -(l.titik_mendarat.y - l.titik_lepas.y)
					check(_dekat(lateral, tanda * t[1]), "%s u %s: geser lateral %s ubin ke arah sisi (tanda benar), dapat %s" % [tag, u, tanda * t[1], lateral])
					check(_dekat(maju, v * t[2]) and _dekat(l.geser_maju, v * t[2]), "%s u %s: geser maju = kecepatan x lama terbang = %s, dapat %s" % [tag, u, v * t[2], maju])
				# Di atas maks dijepit = tepat maks.
				var lebih: ThrowSolver.Lintasan = ThrowSolver.hitung(ThrowSolver.swipe_maks_px(lebar) * 1.5, lebar, ThrowSolver.arah_sisi(sisi), posisi, v, 0.0, 0.0)
				check(lebih != null and _dekat(lebih.jarak, 5.0) and _dekat(lebih.lama_terbang, 0.75) and _dekat(lebih.tinggi_puncak, 1.6), "%s: swipe 1,5x maks dijepit ke 5,0 / 0,75 / 1,6" % tag)
				# Di bawah min: tidak ada lintasan.
				check(ThrowSolver.hitung(ThrowSolver.swipe_min_px(lebar) - 0.5, lebar, ThrowSolver.arah_sisi(sisi), posisi, v, 0.0, 0.0) == null, "%s: swipe di bawah min = tidak ada lintasan" % tag)
	# Tanpa warisan lateral selama terbang: kecepatan lateral hanya menggeser titik lepas (jeda lepas), bukan selama terbang.
	var tanpa: ThrowSolver.Lintasan = ThrowSolver.hitung(_panjang(0.5, 780.0), 780.0, Iso.ARAH_DEKAT, Vector2(0.0, 0.0), 4.5, 0.0, 0.0)
	var dengan: ThrowSolver.Lintasan = ThrowSolver.hitung(_panjang(0.5, 780.0), 780.0, Iso.ARAH_DEKAT, Vector2(0.0, 0.0), 4.5, 3.0, 0.0)
	check(tanpa.titik_mendarat == dengan.titik_mendarat, "jeda lepas 0: kecepatan lateral 3 u/d tidak mengubah titik mendarat (tanpa warisan lateral), %s lawan %s" % [tanpa.titik_mendarat, dengan.titik_mendarat])
	var jeda: float = _jeda_lepas()
	var dengan_jeda: ThrowSolver.Lintasan = ThrowSolver.hitung(_panjang(0.5, 780.0), 780.0, Iso.ARAH_SEBERANG, Vector2(0.0, 0.0), 4.5, -3.0, jeda)
	check(_dekat(dengan_jeda.titik_mendarat.x - dengan_jeda.titik_lepas.x, -3.25), "dengan jeda lepas: geser lateral selama terbang tetap tepat jarak tanah (-3,25), dapat %s" % (dengan_jeda.titik_mendarat.x - dengan_jeda.titik_lepas.x))
	# Arah harus ada (pengganti tes sisi TIDAK_ADA Run 2A): arah nol, NaN, atau tak hingga = tidak ada lintasan.
	for arah_salah: Vector2 in [Vector2.ZERO, Vector2(NAN, 0.0), Vector2(INF, 1.0), Vector2(0.0, -INF)]:
		check(ThrowSolver.hitung(100.0, 780.0, arah_salah, Vector2.ZERO, 3.0, 0.0, 0.0) == null, "arah %s: tidak ada lintasan" % arah_salah)
	var panjang_arah: ThrowSolver.Lintasan = ThrowSolver.hitung(100.0, 780.0, Vector2(-3.0, -4.0), Vector2.ZERO, 3.0, 0.0, 0.0)
	check(panjang_arah != null and _dekat_v(panjang_arah.arah, Vector2(-0.6, -0.8)) and panjang_arah.sisi == LoperAnim.Sisi.SEBERANG, "arah tidak satuan dinormalkan (-3, -4) -> (-0,6, -0,8), sisi dari arah = seberang")
	check(ThrowSolver.arah_sisi(LoperAnim.Sisi.SEBERANG) == Iso.ARAH_SEBERANG and ThrowSolver.arah_sisi(LoperAnim.Sisi.DEKAT) == Iso.ARAH_DEKAT and ThrowSolver.arah_sisi(LoperAnim.Sisi.TIDAK_ADA) == Vector2.ZERO, "arah sisi dari Iso.ARAH_SEBERANG / ARAH_DEKAT")
	# dari_swipe = hitung(|v|, arah_tanah(v)) (pengganti sisi_dari_swipe + hitung(|dx|) Run 2A).
	var awal: Vector2 = Vector2(600.0, 200.0)
	var akhir: Vector2 = Vector2(480.0, 230.0)
	var a: ThrowSolver.Lintasan = ThrowSolver.dari_swipe(awal, akhir, 780.0, posisi, 3.0, 0.5, jeda)
	var b: ThrowSolver.Lintasan = ThrowSolver.hitung(ThrowSolver.panjang_swipe(awal, akhir), 780.0, ThrowSolver.arah_tanah(akhir - awal), posisi, 3.0, 0.5, jeda)
	check(a != null and b != null and _sama(a, b) and _dekat(ThrowSolver.panjang_swipe(awal, akhir), sqrt(120.0 * 120.0 + 30.0 * 30.0)), "dari_swipe (120 kiri, 30 bawah) = hitung(|v| 123,7, arah_tanah(v))")
	check(ThrowSolver.dari_swipe(awal, Vector2(600.0, 100.0), 780.0, posisi, 3.0, 0.0, jeda) != null and ThrowSolver.dari_swipe(awal, awal + Vector2(40.0, 0.0), 780.0, posisi, 3.0, 0.0, jeda) == null, "dari_swipe: swipe tegak 100 px melempar (tidak ada sudut ditolak), |v| 40 di bawah min = null")


func _test_masukan_aneh_dan_murni() -> void:
	_judul.call("ThrowSolver: masukan NaN, tak hingga, negatif aman; murni (AC-2)")
	var p: float = _panjang(0.5, 780.0)
	var nol: ThrowSolver.Lintasan = ThrowSolver.hitung(p, 780.0, Iso.ARAH_DEKAT, Vector2.ZERO, 0.0, 0.0, 0.0)
	for v: float in [NAN, INF, -INF, -3.0]:
		var l: ThrowSolver.Lintasan = ThrowSolver.hitung(p, 780.0, Iso.ARAH_DEKAT, Vector2.ZERO, v, 0.0, 0.0)
		check(l != null and l.geser_maju == 0.0 and l.titik_mendarat == nol.titik_mendarat, "kecepatan maju %s dianggap 0 (tanpa geser maju)" % v)
	for vl: float in [NAN, INF, -INF]:
		var l: ThrowSolver.Lintasan = ThrowSolver.hitung(p, 780.0, Iso.ARAH_DEKAT, Vector2.ZERO, 0.0, vl, 0.5)
		check(l != null and l.titik_lepas == Vector2.ZERO, "kecepatan lateral %s dianggap 0" % vl)
	for j: float in [NAN, INF, -0.5]:
		var l: ThrowSolver.Lintasan = ThrowSolver.hitung(p, 780.0, Iso.ARAH_DEKAT, Vector2.ZERO, 6.0, 3.0, j)
		check(l != null and l.jeda_lepas == 0.0 and l.titik_lepas == Vector2.ZERO, "jeda lepas %s dianggap 0" % j)
	for pos: Vector2 in [Vector2(NAN, 0.0), Vector2(0.0, INF)]:
		check(ThrowSolver.hitung(p, 780.0, Iso.ARAH_DEKAT, pos, 3.0, 0.0, 0.0) == null, "posisi sepeda tidak hingga (%s): tidak ada lintasan" % pos)
	# Murni: masukan sama = hasil sama; masukan Vector2 tidak berubah.
	var posisi: Vector2 = Vector2(-0.5, -12.25)
	var salinan: Vector2 = posisi
	var x: ThrowSolver.Lintasan = ThrowSolver.hitung(p, 780.0, Iso.ARAH_SEBERANG, posisi, 4.5, -1.0, 0.1667)
	var y: ThrowSolver.Lintasan = ThrowSolver.hitung(p, 780.0, Iso.ARAH_SEBERANG, posisi, 4.5, -1.0, 0.1667)
	check(x != y and _sama(x, y) and posisi == salinan, "fungsi murni: dua panggilan sama menghasilkan dua objek bernilai sama, masukan tidak berubah")
	check(ThrowSolver.posisi_pada(null, 0.2) == Vector3.ZERO and ThrowSolver.tinggi_pada(null, 0.2) == 0.0 and not ThrowSolver.sudah_mendarat(null, 9.0), "lintasan null aman")


# --- Titik lepas dengan jeda frame lepas (D-4) ---

func _test_titik_lepas() -> void:
	_judul.call("Titik lepas = posisi saat jari dilepas + kecepatan x jeda lepas, lateral dijepit tepi jalan (D-4)")
	var jeda: float = 1.0 / 6.0
	var lepas: Vector2 = ThrowSolver.titik_lepas(Vector2(0.2, -10.0), 6.0, 3.0, jeda)
	check(_dekat_v(lepas, Vector2(0.7, -11.0)), "ngebut 6 u/d + lateral 3 u/d x 1/6 detik: (0,2, -10) -> (0,7, -11), dapat %s" % lepas)
	var tepi_dekat: Vector2 = ThrowSolver.titik_lepas(Vector2(0.9, 0.0), 3.0, 3.0, jeda)
	var tepi_seberang: Vector2 = ThrowSolver.titik_lepas(Vector2(-0.9, 0.0), 3.0, -3.0, jeda)
	var batas: float = BikeMotion.batas_lateral_ubin()
	check(tepi_dekat.x == batas and tepi_seberang.x == -batas, "lateral dijepit ke tepi jalan resmi +-%s, dapat %s dan %s" % [batas, tepi_dekat.x, tepi_seberang.x])
	check(_dekat(tepi_dekat.y, -0.5) and _dekat(tepi_seberang.y, -0.5), "maju tetap dihitung walau lateral dijepit (3 x 1/6 = 0,5)")
	var l: ThrowSolver.Lintasan = ThrowSolver.hitung(_panjang(0.0, 640.0), 640.0, Iso.ARAH_DEKAT, Vector2(0.2, -10.0), 6.0, 3.0, jeda)
	check(l.titik_lepas == lepas and l.jeda_lepas == jeda, "hitung memakai titik_lepas yang sama")
	check(_dekat(ThrowSolver.lama_total(l), jeda + 0.45) and _dekat(ThrowSolver.waktu_terbang(l, jeda + 0.1), 0.1), "lama total = jeda lepas + lama terbang; waktu terbang = detik sejak jari - jeda lepas")
	check(not ThrowSolver.sudah_mendarat(l, jeda + 0.449) and ThrowSolver.sudah_mendarat(l, jeda + 0.45) and ThrowSolver.sudah_mendarat(l, 5.0), "sudah mendarat inklusif di jeda + lama terbang")
	var di_tangan: Vector3 = ThrowSolver.posisi_sejak_jari(l, 0.05)
	check(Vector2(di_tangan.x, di_tangan.y) == lepas and _dekat(di_tangan.z, Config.LEMPAR_TINGGI_TANGAN_UBIN), "sebelum frame lepas: posisi = titik lepas setinggi tangan")


# --- Iso: tinggi z (D-3) ---

func _test_iso_tinggi() -> void:
	_judul.call("Iso: tinggi z menggeser layar (0, -32) px per ubin, posisi gambar bulat (AC-3, D-3)")
	check(Iso.tinggi_ke_layar(1.0) == Vector2(0.0, -32.0) and Iso.tinggi_ke_layar(0.5) == Vector2(0.0, -16.0) and Iso.tinggi_ke_layar(0.0) == Vector2.ZERO, "1 ubin = 32 px ke atas, 0,5 = 16 px, 0 = tanpa geseran")
	check(Iso.tinggi_ke_layar(NAN) == Vector2.ZERO and Iso.tinggi_ke_layar(INF) == Vector2.ZERO, "tinggi tidak hingga = tanpa geseran")
	var dunia: Vector2 = Vector2(-1.3, -7.7)
	check(Iso.dunia_tinggi_ke_layar(dunia, 1.3) == Iso.dunia_ke_layar(dunia) + Vector2(0.0, -41.6), "dunia_tinggi_ke_layar = titik tanah + geseran tinggi")
	var gambar: Vector2 = Iso.posisi_gambar_tinggi(dunia, 1.3)
	check(gambar == gambar.round() and gambar == Iso.dunia_tinggi_ke_layar(dunia, 1.3).round(), "posisi gambar koran di udara dibulatkan ke piksel")
	check(Iso.posisi_gambar_tinggi(dunia, 0.0) == Iso.posisi_gambar(dunia), "tinggi 0 = posisi gambar bayangan di tanah")


# --- Lengkung (AC-3) ---

func _test_lengkung() -> void:
	_judul.call("Lengkung: t 0 di tangan, t lama terbang di titik mendarat, puncak = tinggi puncak, t dijepit (AC-3, D-3)")
	for u: float in [0.0, 0.5, 1.0]:
		var l: ThrowSolver.Lintasan = ThrowSolver.hitung(_panjang(u, 780.0), 780.0, Iso.ARAH_SEBERANG, Vector2(0.3, -5.0), 4.5, 0.0, 0.0)
		var tag: String = "u %s" % u
		var awal: Vector3 = ThrowSolver.posisi_pada(l, 0.0)
		var akhir: Vector3 = ThrowSolver.posisi_pada(l, l.lama_terbang)
		check(Vector2(awal.x, awal.y) == l.titik_lepas and _dekat(awal.z, Config.LEMPAR_TINGGI_TANGAN_UBIN), "%s: t = 0 di titik lepas setinggi tangan (%s)" % [tag, awal.z])
		check(Vector2(akhir.x, akhir.y) == l.titik_mendarat and akhir.z == 0.0, "%s: t = lama terbang TEPAT di titik mendarat, tinggi 0" % tag)
		var tertinggi: float = 0.0
		var naik_turun: bool = true
		var maju_monoton: bool = true
		var sebelum: Vector3 = awal
		for i: int in range(2001):
			var p: Vector3 = ThrowSolver.posisi_pada(l, l.lama_terbang * float(i) / 2000.0)
			tertinggi = maxf(tertinggi, p.z)
			if p.z < -TOL or p.z > l.tinggi_puncak + TOL:
				naik_turun = false
			if p.y > sebelum.y + TOL or p.x > sebelum.x + TOL:
				maju_monoton = false
			sebelum = p
		check(_dekat(tertinggi, l.tinggi_puncak, TOL_PUNCAK), "%s: tinggi tertinggi dari 2001 sampel = puncak %s (toleransi %s), dapat %s" % [tag, l.tinggi_puncak, TOL_PUNCAK, tertinggi])
		var s_puncak: float = l.lengkung_b / (2 * l.lengkung_a)
		check(_dekat(ThrowSolver.tinggi_pada(l, s_puncak * l.lama_terbang), l.tinggi_puncak, TOL) and s_puncak > 0.0 and s_puncak <= 0.5, "%s: puncak analitik (s %s) tepat tinggi puncak, di paruh pertama" % [tag, s_puncak])
		check(naik_turun, "%s: tinggi selalu 0 sampai puncak" % tag)
		check(maju_monoton, "%s: posisi tanah bergerak satu arah (maju dan ke seberang), linear dari lepas ke mendarat" % tag)
		check(ThrowSolver.posisi_pada(l, -0.3) == awal and ThrowSolver.posisi_pada(l, l.lama_terbang + 2.0) == akhir and ThrowSolver.posisi_pada(l, NAN) == awal and ThrowSolver.posisi_pada(l, INF) == akhir, "%s: t di luar rentang dijepit (negatif dan NaN = awal, lebih dan INF = akhir)" % tag)
		var tengah: Vector3 = ThrowSolver.posisi_pada(l, l.lama_terbang / 2)
		check(_dekat_v(Vector2(tengah.x, tengah.y), l.titik_lepas.lerp(l.titik_mendarat, 0.5)), "%s: tengah waktu = tengah jalur tanah (kecepatan tetap)" % tag)


# --- LemparWaktu.waktu_lepas (jeda lepas D-4) ---

func _test_waktu_lepas() -> void:
	_judul.call("Jeda lepas = frame lepas / fps, sama dengan sinyal lepas LemparWaktu (D-4)")
	var frames: SpriteFrames = load(BERKAS_FRAMES) as SpriteFrames
	var nama: StringName = LoperAnim.nama_lempar(LoperAnim.Sisi.SEBERANG, 0, 0)
	check(frames != null and frames.get_animation_speed(nama) == FPS_LEMPAR and frames.get_frame_count(nama) == FRAME_LEMPAR, "animasi lempar 12 fps, 4 frame (dipakai tes ini)")
	var jeda: float = _jeda_lepas()
	check(_dekat(jeda, 2.0 / 12.0), "jeda lepas frame 2 di 12 fps = 0,1667 detik, dapat %s" % jeda)
	check(LemparWaktu.waktu_lepas(12.0, 4, 0) == 1.0 / 12.0 and LemparWaktu.waktu_lepas(0.0, 4, 2) == 0.0 and LemparWaktu.waktu_lepas(NAN, 4, 2) == 0.0 and LemparWaktu.waktu_lepas(12.0, 0, 2) == 0.0, "frame lepas 0 = frame 1; fps atau jumlah frame tidak sah = 0")
	for dt: float in [1.0 / 30.0, 1.0 / 60.0, 1.0 / 240.0]:
		var waktu: float = 0.0
		var lepas_di: float = -1.0
		for i: int in range(60):
			var langkah: LemparWaktu.Langkah = LemparWaktu.langkah(waktu, dt, FPS_LEMPAR, FRAME_LEMPAR, Config.LEMPAR_FRAME_LEPAS)
			waktu = langkah.waktu
			if langkah.lepas:
				lepas_di = waktu
				break
		check(lepas_di >= jeda - Config.LEMPAR_TOLERANSI_DETIK and lepas_di < jeda + dt, "dt %s: sinyal lepas pertama di %s (jeda lepas %s, paling lambat satu langkah sesudahnya)" % [dt, lepas_di, jeda])


# --- Prediksi = hasil (AC-4, bagian murni) ---

func _test_prediksi_hasil() -> void:
	_judul.call("Prediksi = hasil: titik akhir garis bidik saat jari dilepas = titik mendarat koran, sepeda berubah gerak (AC-4, D-4)")
	var jeda: float = _jeda_lepas()
	# [nama, stick sebelum jari dilepas, stick sesudahnya, sisi (arah swipe)]
	var skenario: Array = [
		["mempercepat", Vector2(0.0, 0.0), Vector2(0.0, 1.0), -1.0],
		["mengerem", Vector2(0.0, 1.0), Vector2(0.0, -1.0), 1.0],
		["pindah sisi", Vector2(0.7, 0.5), Vector2(-1.0, 0.0), -1.0],
		["pindah sisi dan ngebut", Vector2(-0.8, 0.0), Vector2(1.0, 1.0), 1.0],
	]
	for dt: float in [1.0 / 30.0, 1.0 / 240.0]:
		for s: Array in skenario:
			var tag: String = "dt 1/%d, %s" % [roundi(1.0 / dt), s[0]]
			var k: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
			var jarak: float = 3.0
			var hasil: BikeMotion.Hasil = null
			for i: int in range(roundi(1.5 / dt)):
				hasil = BikeMotion.langkah(k, s[1], dt)
				k = hasil.keadaan
				jarak += hasil.maju_ubin
			var posisi: Vector2 = Vector2(k.lateral_ubin, -jarak)
			var awal: Vector2 = Vector2(600.0, 200.0)
			var akhir: Vector2 = awal + Vector2(s[3] * 150.0, 10.0)
			# Frame jari dilepas: garis bidik frame ini dan lemparan memakai panggilan yang sama dengan keadaan yang sama.
			var bidik: ThrowSolver.Lintasan = ThrowSolver.dari_swipe(awal, akhir, 780.0, posisi, k.kecepatan_ud, hasil.lateral_ud, jeda)
			var ujung_bidik: Vector3 = ThrowSolver.posisi_pada(bidik, bidik.lama_terbang)
			var lempar: ThrowSolver.Lintasan = ThrowSolver.dari_swipe(awal, akhir, 780.0, posisi, k.kecepatan_ud, hasil.lateral_ud, jeda)
			# Koran disimulasikan frame demi frame sementara sepeda berubah gerak.
			var detik: float = 0.0
			var koran: Vector3 = ThrowSolver.posisi_sejak_jari(lempar, detik)
			var keadaan_lepas: BikeMotion.Keadaan = null
			var jarak_lepas: float = 0.0
			var langkah: int = 0
			while not ThrowSolver.sudah_mendarat(lempar, detik) and langkah < 1000:
				hasil = BikeMotion.langkah(k, s[2], dt)
				k = hasil.keadaan
				jarak += hasil.maju_ubin
				detik += dt
				langkah += 1
				if keadaan_lepas == null and detik + Config.LEMPAR_TOLERANSI_DETIK >= jeda:
					keadaan_lepas = k
					jarak_lepas = jarak
				koran = ThrowSolver.posisi_sejak_jari(lempar, detik)
			check(_dekat_v(Vector2(koran.x, koran.y), Vector2(ujung_bidik.x, ujung_bidik.y), TOL_PREDIKSI) and koran.z == 0.0, "%s: koran mendarat di ujung garis bidik %s (dapat %s, toleransi 1e-4)" % [tag, Vector2(ujung_bidik.x, ujung_bidik.y), Vector2(koran.x, koran.y)])
			# Kontrol: sepeda benar-benar berubah gerak, jadi lintasan yang dihitung ulang di frame lepas dari keadaan baru akan meleset.
			var ulang: ThrowSolver.Lintasan = ThrowSolver.hitung(150.0, 780.0, bidik.arah, Vector2(keadaan_lepas.lateral_ubin, -jarak_lepas), keadaan_lepas.kecepatan_ud, 0.0, 0.0)
			check(ulang.titik_mendarat.distance_to(bidik.titik_mendarat) > 0.05, "%s (kontrol): lintasan yang dihitung ulang saat frame lepas dari keadaan baru meleset %.3f ubin dari prediksi" % [tag, ulang.titik_mendarat.distance_to(bidik.titik_mendarat)])


# --- Arah bebas (run fase2-arah-bebas, D-1 sampai D-3) ---

## AC-2: untuk tiap sudut di `SUDUT_UJI` (termasuk 45, 78, 90, 115, 135, 180, 225, 270, 315) dan panjang di antara min dan maks: melempar,
## (titik mendarat - titik lepas - geser maju warisan) = jarak x arah tanah, dan arah tanah di layar searah dengan v.
func _test_arah_bebas() -> void:
	_judul.call("Arah bebas: arah tanah = Iso.layar_ke_dunia(v) dinormalkan, searah jari di layar, jarak penuh searah itu (AC-2, D-1)")
	var jeda: float = _jeda_lepas()
	var posisi: Vector2 = Vector2(0.25, -7.5)
	for lebar: float in LEBAR:
		for v_maju: float in KECEPATAN:
			var semua_lempar: bool = true
			var semua_jarak: bool = true
			var semua_searah: bool = true
			var semua_arah: bool = true
			var gagal: Array[String] = []
			for derajat: float in SUDUT_UJI:
				for u: float in [0.25, 0.75]:
					var v: Vector2 = _arah_layar(derajat) * _panjang(u, lebar)
					var awal: Vector2 = Vector2(400.0, 200.0)
					var l: ThrowSolver.Lintasan = ThrowSolver.dari_swipe(awal, awal + v, lebar, posisi, v_maju, 0.0, jeda)
					if l == null:
						semua_lempar = false
						gagal.append("%s derajat u %s: tidak melempar" % [derajat, u])
						continue
					var sisa: Vector2 = l.titik_mendarat - l.titik_lepas - Iso.ARAH_MAJU * l.geser_maju
					if not _dekat_v(sisa, l.arah * l.jarak) or not _dekat(l.jarak, ThrowSolver.jarak_ubin(u), 0.0001) or not _dekat(l.geser_maju, v_maju * l.lama_terbang):
						semua_jarak = false
						gagal.append("%s derajat: sisa %s lawan %s" % [derajat, sisa, l.arah * l.jarak])
					var layar: Vector2 = Iso.dunia_ke_layar(l.arah)
					var silang: float = (layar.x * v.y - layar.y * v.x) / (layar.length() * v.length())
					if absf(silang) > 0.00001 or layar.dot(v) <= 0.0:
						semua_searah = false
						gagal.append("%s derajat: silang %s, titik %s" % [derajat, silang, layar.dot(v)])
					# akhir - awal disimpan Vector2 presisi tunggal, jadi v yang dipakai bisa berbeda derau float dari `v` di sini.
					if not _dekat_v(l.arah, ThrowSolver.arah_tanah(v)) or not _dekat(l.arah.length(), 1.0) or l.sisi != ThrowSolver.sisi_dari_arah(l.arah):
						semua_arah = false
						gagal.append("%s derajat: arah %s" % [derajat, l.arah])
			var tag: String = "lebar %s, %s u/d, %d sudut x 2 panjang" % [lebar, v_maju, SUDUT_UJI.size()]
			check(semua_lempar, "%s: semua swipe melempar (tidak ada sudut ditolak) %s" % [tag, gagal])
			check(semua_jarak, "%s: titik mendarat - titik lepas - geser maju = jarak tanah x arah tanah %s" % [tag, gagal])
			check(semua_searah, "%s: Iso.dunia_ke_layar(arah tanah) searah v (silang ~ 0, titik > 0) %s" % [tag, gagal])
			check(semua_arah, "%s: Lintasan.arah = arah_tanah(v) satuan, sisi = sisi_dari_arah(arah) %s" % [tag, gagal])
	# Contoh terhitung tangan: swipe ke kiri murni = seberang SEDIKIT KE BELAKANG di tanah, ke kanan murni = dekat ke depan, ke atas murni =
	# seberang ke depan, ke bawah = dekat ke belakang (Iso: 1 ubin x = (+32, +16) px, 1 ubin y = (-32, +16) px).
	var akar2: float = sqrt(0.5)
	check(_dekat_v(ThrowSolver.arah_tanah(Vector2(-100.0, 0.0)), Vector2(-akar2, akar2)), "kiri murni: arah tanah (-0,707, +0,707) = seberang dan mundur")
	check(_dekat_v(ThrowSolver.arah_tanah(Vector2(100.0, 0.0)), Vector2(akar2, -akar2)), "kanan murni: arah tanah (+0,707, -0,707) = dekat dan maju")
	check(_dekat_v(ThrowSolver.arah_tanah(Vector2(0.0, -100.0)), Vector2(-akar2, -akar2)), "atas murni: arah tanah (-0,707, -0,707) = seberang dan maju")
	check(_dekat_v(ThrowSolver.arah_tanah(Vector2(0.0, 100.0)), Vector2(akar2, akar2)), "bawah murni: arah tanah (+0,707, +0,707) = dekat dan mundur")
	check(_dekat_v(ThrowSolver.arah_tanah(Iso.dunia_ke_layar(Iso.ARAH_SEBERANG)), Iso.ARAH_SEBERANG) and _dekat_v(ThrowSolver.arah_tanah(Iso.dunia_ke_layar(Iso.ARAH_MAJU) * 3.0), Iso.ARAH_MAJU), "kebalikan Iso: swipe searah layar arah seberang / maju memberi arah itu lagi")
	check(ThrowSolver.arah_tanah(Vector2.ZERO) == Vector2.ZERO and ThrowSolver.arah_tanah(Vector2(NAN, 1.0)) == Vector2.ZERO and ThrowSolver.arah_tanah(Vector2(INF, 0.0)) == Vector2.ZERO, "vektor nol, NaN, tak hingga: tanpa arah")
	check(_dekat_v(ThrowSolver.arah_tanah(Vector2(1.0e30, 0.0)), Vector2(akar2, -akar2)), "vektor sangat panjang tetap dinormalkan (tanpa luapan)")


## AC-3: tiap sudut melempar tepat di min, tidak melempar 0,01 px di bawahnya, dijepit u = 1 di atas maks; kekuatan untuk panjang sama
## sama di semua arah (pengganti tes "tegak dominan tidak melempar" Run 2A).
func _test_tanpa_sudut_ditolak() -> void:
	_judul.call("Tanpa sudut ditolak: ambang min inklusif dan maks dijepit sama di semua arah (AC-3, D-2)")
	var awal: Vector2 = Vector2(450.0, 210.0)
	for lebar: float in LEBAR:
		var bawah: float = ThrowSolver.swipe_min_px(lebar)
		var atas: float = ThrowSolver.swipe_maks_px(lebar)
		var tengah: float = _panjang(0.4, lebar)
		var gagal: Array[String] = []
		for derajat: float in SUDUT_UJI:
			var arah: Vector2 = _arah_layar(derajat)
			var tepat: ThrowSolver.Lintasan = ThrowSolver.dari_swipe(awal, awal + arah * bawah, lebar, Vector2.ZERO, 3.0, 0.0, 0.0)
			if tepat == null or tepat.kekuatan > 0.00001 or ThrowSolver.sisi_dari_swipe(awal, awal + arah * bawah, lebar) == LoperAnim.Sisi.TIDAK_ADA:
				gagal.append("%s derajat: tepat min tidak melempar" % derajat)
			var kurang: Vector2 = awal + arah * (bawah - 0.01)
			if ThrowSolver.dari_swipe(awal, kurang, lebar, Vector2.ZERO, 3.0, 0.0, 0.0) != null or ThrowSolver.sisi_dari_swipe(awal, kurang, lebar) != LoperAnim.Sisi.TIDAK_ADA:
				gagal.append("%s derajat: min - 0,01 melempar" % derajat)
			var lebih: ThrowSolver.Lintasan = ThrowSolver.dari_swipe(awal, awal + arah * atas * 1.5, lebar, Vector2.ZERO, 3.0, 0.0, 0.0)
			if lebih == null or lebih.kekuatan != 1.0 or not _dekat(lebih.jarak, Config.LEMPAR_JARAK_MAKS_UBIN):
				gagal.append("%s derajat: 1,5 x maks tidak dijepit ke u 1" % derajat)
			var sedang: ThrowSolver.Lintasan = ThrowSolver.dari_swipe(awal, awal + arah * tengah, lebar, Vector2.ZERO, 3.0, 0.0, 0.0)
			if sedang == null or not _dekat(sedang.kekuatan, 0.4, 0.00001) or not _dekat(sedang.lama_terbang, ThrowSolver.lama_terbang_detik(0.4)) or not _dekat(sedang.tinggi_puncak, ThrowSolver.tinggi_puncak_ubin(0.4)):
				gagal.append("%s derajat: panjang u 0,4 memberi kekuatan berbeda" % derajat)
		check(gagal.is_empty(), "lebar %s, %d sudut: tepat min melempar (u 0), min - 0,01 tidak, 1,5 x maks = u 1, panjang sama = kekuatan sama %s" % [lebar, SUDUT_UJI.size(), gagal])
	# Panjang = |v| penuh, bukan |dx|: 46 datar + 20 tegak (|v| 50,2) melempar di 780 (min 46,8), padahal |dx| 46 di bawah min.
	check(ThrowSolver.sisi_dari_swipe(awal, awal + Vector2(46.0, 20.0), 780.0) != LoperAnim.Sisi.TIDAK_ADA and _dekat(ThrowSolver.panjang_swipe(awal, awal + Vector2(46.0, 20.0)), sqrt(46.0 * 46.0 + 400.0)), "46 datar + 20 tegak (|v| 50,2) melempar: yang dihitung |v|, bukan |dx|")
	check(ThrowSolver.sisi_dari_swipe(awal, awal, 780.0) == LoperAnim.Sisi.TIDAK_ADA and ThrowSolver.dari_swipe(awal, awal, 780.0, Vector2.ZERO, 3.0, 0.0, 0.0) == null, "ketukan tanpa geser (|v| 0) tidak melempar")
	check(is_nan(ThrowSolver.panjang_swipe(Vector2(NAN, 0.0), awal)) and is_nan(ThrowSolver.panjang_swipe(awal, Vector2(0.0, INF))) and ThrowSolver.dari_swipe(Vector2(NAN, 0.0), awal, 780.0, Vector2.ZERO, 3.0, 0.0, 0.0) == null, "titik NaN atau tak hingga: panjang NaN, tidak melempar")
	check(ThrowSolver.sisi_dari_swipe(Vector2.ZERO, Vector2(1.0e30, 0.0), 780.0) == LoperAnim.Sisi.DEKAT and ThrowSolver.dari_swipe(Vector2.ZERO, Vector2(1.0e30, 0.0), 780.0, Vector2.ZERO, 3.0, 0.0, 0.0).kekuatan == 1.0, "swipe sangat panjang (1e30 px) tetap hingga, melempar dengan u 1")


## AC-4 / D-3: sisi dari komponen melintang arah tanah: x < 0 seberang, x > 0 dekat, x = 0 tepat dekat; kidal tidak ada di rumus.
func _test_sisi_arah() -> void:
	_judul.call("Sisi dari arah tanah: x < 0 seberang, x > 0 dekat, x = 0 tepat dekat (AC-4, D-3)")
	var awal: Vector2 = Vector2(450.0, 210.0)
	# Swipe (64, -32) searah sumbu jalan maju di layar: x tanah = (dy / 16 + dx / 32) / 2 = 0 TEPAT.
	var maju: Vector2 = Vector2(64.0, -32.0)
	check(ThrowSolver.arah_tanah(maju).x == 0.0 and ThrowSolver.arah_tanah(-maju).x == 0.0, "kontrol: swipe (64, -32) dan (-64, 32) memberi x tanah tepat 0")
	check(ThrowSolver.sisi_dari_swipe(awal, awal + maju, 780.0) == LoperAnim.Sisi.DEKAT and ThrowSolver.sisi_dari_swipe(awal, awal - maju, 780.0) == LoperAnim.Sisi.DEKAT, "x = 0 tepat (searah jalan maju atau mundur): DEKAT")
	check(ThrowSolver.dari_swipe(awal, awal + maju, 780.0, Vector2.ZERO, 3.0, 0.0, 0.0).sisi == LoperAnim.Sisi.DEKAT, "x = 0 tepat: Lintasan.sisi DEKAT")
	check(ThrowSolver.sisi_dari_swipe(awal, awal + Vector2(64.0, -32.01), 780.0) == LoperAnim.Sisi.SEBERANG and ThrowSolver.arah_tanah(Vector2(64.0, -32.01)).x < 0.0, "x sedikit negatif (64, -32,01): SEBERANG")
	check(ThrowSolver.sisi_dari_swipe(awal, awal + Vector2(64.0, -31.99), 780.0) == LoperAnim.Sisi.DEKAT and ThrowSolver.arah_tanah(Vector2(64.0, -31.99)).x > 0.0, "x sedikit positif (64, -31,99): DEKAT")
	check(ThrowSolver.sisi_dari_arah(Vector2(0.0, -1.0)) == LoperAnim.Sisi.DEKAT and ThrowSolver.sisi_dari_arah(Vector2(-0.0, 1.0)) == LoperAnim.Sisi.DEKAT, "sisi_dari_arah: x = 0 dan x = -0 = DEKAT")
	check(ThrowSolver.sisi_dari_arah(Vector2(-0.000001, 1.0)) == LoperAnim.Sisi.SEBERANG and ThrowSolver.sisi_dari_arah(Vector2(0.000001, -1.0)) == LoperAnim.Sisi.DEKAT, "sisi_dari_arah: x -1e-6 = SEBERANG, x +1e-6 = DEKAT")
	check(ThrowSolver.sisi_dari_arah(Vector2.ZERO) == LoperAnim.Sisi.TIDAK_ADA and ThrowSolver.sisi_dari_arah(Vector2(NAN, 1.0)) == LoperAnim.Sisi.TIDAK_ADA and ThrowSolver.sisi_dari_arah(Vector2(-INF, 0.0)) == LoperAnim.Sisi.TIDAK_ADA, "arah nol, NaN, tak hingga: TIDAK_ADA")
	# Arah layar sehari-hari: kiri, atas, kiri atas = seberang; kanan, bawah, kanan bawah = dekat.
	for kasus: Array in [[180.0, LoperAnim.Sisi.SEBERANG], [90.0, LoperAnim.Sisi.SEBERANG], [135.0, LoperAnim.Sisi.SEBERANG], [78.0, LoperAnim.Sisi.SEBERANG], [0.0, LoperAnim.Sisi.DEKAT], [270.0, LoperAnim.Sisi.DEKAT], [315.0, LoperAnim.Sisi.DEKAT], [12.0, LoperAnim.Sisi.DEKAT]]:
		var v: Vector2 = _arah_layar(kasus[0]) * 100.0
		check(ThrowSolver.sisi_dari_swipe(awal, awal + v, 780.0) == kasus[1], "swipe %s derajat: %s" % [kasus[0], LoperAnim.Sisi.keys()[kasus[1]]])
	# Kidal hanya menukar zona di `TouchZones`: rumus arah dan sisi tidak menerima opsi kidal (tes scene memeriksa kidal lewat sentuhan).
	var argumen: Dictionary = {}
	for m: Dictionary in (load(BERKAS_SOLVER) as Script).get_script_method_list():
		argumen[m["name"]] = (m["args"] as Array).size()
	check(argumen.get("sisi_dari_swipe", -1) == 3 and argumen.get("arah_tanah", -1) == 1 and argumen.get("dari_swipe", -1) == 7, "sisi_dari_swipe (awal, akhir, lebar), arah_tanah (v), dari_swipe tanpa parameter kidal")


## AC-8: tidak ada lagi aturan "dominan datar" atau |dx| di jalur lemparan (teks berkas).
func _test_penjaga_aturan_lama() -> void:
	_judul.call("Penjaga: aturan lama dominan datar dan |dx| sudah tidak ada di jalur lemparan (AC-8)")
	for berkas: String in BERKAS_JALUR_LEMPAR:
		var teks: String = FileAccess.get_file_as_string(berkas)
		check(not teks.is_empty() and not teks.contains("dominan") and not teks.contains("|dx|") and not teks.contains("absf(geser.x)"), "%s: tanpa 'dominan', '|dx|', atau perbandingan |dx| lawan |dy|" % berkas.get_file())


# --- Zona dari titik mendarat (run fase2-arah-bebas, D-4) ---

## Lintasan buatan dengan titik mendarat `titik` dan sisi `sisi` (hanya untuk menguji bahwa penilaian tidak membaca sisi).
func _lintasan_titik(titik: Vector2, sisi: LoperAnim.Sisi) -> ThrowSolver.Lintasan:
	var l: ThrowSolver.Lintasan = ThrowSolver.Lintasan.new()
	l.titik_mendarat = titik
	l.sisi = sisi
	l.arah = ThrowSolver.arah_sisi(sisi)
	return l


func _test_zona_dari_titik() -> void:
	_judul.call("Zona menilai dari titik mendarat saja, tidak bergantung sisi lemparan; zona seberang dan dekat tidak bertumpuk (AC-5, D-4)")
	var sama: bool = true
	var hitung_hasil: Dictionary = {}
	var contoh_beda: String = ""
	for i: int in range(33):
		for j: int in range(65):
			var p: Vector2 = _titik(-4.0 + float(i) * 0.25, -1.0 + float(j) * 0.25)
			var harapan: ZonaSasaran.Hasil = ZonaSasaran.klasifikasi_jalan_uji(p)
			hitung_hasil[harapan] = int(hitung_hasil.get(harapan, 0)) + 1
			for sisi: LoperAnim.Sisi in [LoperAnim.Sisi.SEBERANG, LoperAnim.Sisi.DEKAT, LoperAnim.Sisi.TIDAK_ADA]:
				var l: ThrowSolver.Lintasan = _lintasan_titik(p, sisi)
				for bonus: bool in [false, true]:
					if KoranLempar.hasil_mendarat(l) != harapan or KoranLempar.prediksi_antaran(l, bonus) != ZonaSasaran.status_antaran(harapan, bonus):
						sama = false
						contoh_beda = "%s sisi %s" % [ZonaSasaran.ke_jalan(p), sisi]
	check(sama, "2145 titik x 3 sisi x 2 sakelar: hasil dan antaran sama untuk sisi apa pun = klasifikasi titik saja %s" % contoh_beda)
	check(hitung_hasil.has(ZonaSasaran.Hasil.KOTAK_SURAT) and hitung_hasil.has(ZonaSasaran.Hasil.TERAS) and hitung_hasil.has(ZonaSasaran.Hasil.HALAMAN) and hitung_hasil.has(ZonaSasaran.Hasil.BUKAN_PELANGGAN) and hitung_hasil.has(ZonaSasaran.Hasil.MELESET), "kontrol: kisi titik memuat kotak surat, teras, halaman, bukan pelanggan, meleset (%s)" % [hitung_hasil])
	# Contoh eksplisit: lemparan bersisi DEKAT yang mendarat di kotak surat seberang tetap kena (Run 2A: meleset), dan sebaliknya.
	var seberang: Vector2 = _titik(-1.625, 1.125)
	var dekat: Vector2 = _titik(1.625, 1.125)
	check(KoranLempar.hasil_mendarat(_lintasan_titik(seberang, LoperAnim.Sisi.DEKAT)) == ZonaSasaran.Hasil.KOTAK_SURAT and KoranLempar.prediksi_antaran(_lintasan_titik(seberang, LoperAnim.Sisi.DEKAT), false) == ZonaSasaran.Antaran.SAH_PENUH, "kotak surat seberang dengan sisi lempar DEKAT: KOTAK_SURAT, sah penuh")
	check(KoranLempar.hasil_mendarat(_lintasan_titik(dekat, LoperAnim.Sisi.SEBERANG)) == ZonaSasaran.Hasil.KOTAK_SURAT, "kotak surat dekat dengan sisi lempar SEBERANG: KOTAK_SURAT")
	# Penilaian tidak menerima sisi lempar (penyaring Run 2A dihapus).
	var argumen: Dictionary = {}
	for m: Dictionary in (load("res://scripts/systems/zona_sasaran.gd") as Script).get_script_method_list():
		argumen[m["name"]] = (m["args"] as Array).size()
	check(argumen.get("zona_kena", -1) == 2 and argumen.get("klasifikasi", -1) == 2 and argumen.get("klasifikasi_jalan_uji", -1) == 1, "zona_kena (titik, daftar), klasifikasi (titik, daftar), klasifikasi_jalan_uji (titik): tanpa sisi lempar")
	# Zona seberang dan zona dekat jalan uji tidak bertumpuk (semua pasangan kavling di sekitar), dan tidak ada titik di keduanya.
	var bertumpuk: Array[String] = []
	for a: int in range(-3, 7):
		for b: int in range(-3, 7):
			for za: ZonaSasaran.Zona in ZonaSasaran.zona_jalan_uji(a):
				if za.sisi != LoperAnim.Sisi.SEBERANG:
					continue
				for zb: ZonaSasaran.Zona in ZonaSasaran.zona_jalan_uji(b):
					if zb.sisi == LoperAnim.Sisi.DEKAT and za.persegi.intersects(zb.persegi, true):
						bertumpuk.append("%s/%s" % [za.persegi, zb.persegi])
	check(bertumpuk.is_empty(), "zona seberang dan zona dekat kavling -3..6 tidak bertumpuk (termasuk tepi) %s" % [bertumpuk])
	var di_dua_sisi: int = 0
	for i: int in range(81):
		for j: int in range(81):
			var p: Vector2 = _titik(-4.0 + float(i) * 0.1, -2.0 + float(j) * 0.2)
			var ada_seberang: bool = false
			var ada_dekat: bool = false
			for z: ZonaSasaran.Zona in ZonaSasaran.zona_jalan_uji_sekitar(ZonaSasaran.ke_jalan(p).y):
				if ZonaSasaran.memuat(z, p):
					ada_seberang = ada_seberang or z.sisi == LoperAnim.Sisi.SEBERANG
					ada_dekat = ada_dekat or z.sisi == LoperAnim.Sisi.DEKAT
			if ada_seberang and ada_dekat:
				di_dua_sisi += 1
	check(di_dua_sisi == 0, "6561 titik: tidak ada titik yang dimuat zona seberang dan zona dekat sekaligus")


## AC-6, regresi laporan pemilik (vivo V2108, 2026-10-14: "suka gagal, terutama ke arah kiri"): di santai, cepat, dan ngebut ada swipe
## bersudut layar 45 sampai 135 derajat (rentang yang ditolak Run 2A) yang mendarat di kotak surat SEBERANG pelanggan di depan sepeda,
## dinilai antaran sah. Swipe 78 derajat (kotak surat seberang 2 ubin di depan, tabel SPEC) kini melempar.
func _test_regresi_pemilik() -> void:
	_judul.call("Regresi laporan pemilik: swipe ke atas mengenai kotak surat seberang di depan, tiga kecepatan (AC-6)")
	var lebar: float = 780.0
	var jeda: float = _jeda_lepas()
	var awal: Vector2 = Vector2(500.0, 320.0)
	for v: float in [Config.KECEPATAN_SANTAI_UD, Config.KECEPATAN_CEPAT_UD, Config.KECEPATAN_NGEBUT_UD]:
		var ketemu: String = ""
		for langkah_maju: int in range(16):
			var maju_sepeda: float = float(langkah_maju) * 0.25
			var posisi: Vector2 = Vector2(0.0, -maju_sepeda)
			for derajat: int in range(45, 136):
				var arah: Vector2 = _arah_layar(float(derajat))
				var panjang: float = ceilf(ThrowSolver.swipe_min_px(lebar))
				while panjang <= ThrowSolver.swipe_maks_px(lebar):
					var akhir: Vector2 = awal + arah * panjang
					var l: ThrowSolver.Lintasan = ThrowSolver.dari_swipe(awal, akhir, lebar, posisi, v, 0.0, jeda)
					panjang += 1.0
					if l == null or KoranLempar.hasil_mendarat(l) != ZonaSasaran.Hasil.KOTAK_SURAT:
						continue
					var zona: ZonaSasaran.Zona = ZonaSasaran.zona_kena(l.titik_mendarat, ZonaSasaran.zona_jalan_uji_sekitar(ZonaSasaran.ke_jalan(l.titik_mendarat).y))
					var geser: Vector2 = akhir - awal
					if zona.sisi == LoperAnim.Sisi.SEBERANG and zona.pelanggan and zona.persegi.position.y > maju_sepeda and ZonaSasaran.sah(KoranLempar.prediksi_antaran(l, Config.JENDELA_KENA_BONUS)) and absf(geser.y) >= absf(geser.x):
						ketemu = "sudut %d, |v| %.0f px, sepeda di maju %.2f, kotak surat rumah %d di maju %.3f, sisi lempar %s" % [derajat, panjang - 1.0, maju_sepeda, zona.rumah, zona.persegi.position.y, LoperAnim.Sisi.keys()[l.sisi]]
						break
				if not ketemu.is_empty():
					break
			if not ketemu.is_empty():
				break
		check(not ketemu.is_empty(), "%s u/d: ada swipe 45-135 derajat (ditolak Run 2A) yang mengenai kotak surat seberang pelanggan di depan sepeda, sah (%s)" % [v, ketemu if not ketemu.is_empty() else "TIDAK ADA"])
	# Swipe 78 derajat: |dy| > |dx| (ditolak Run 2A), kini melempar ke seberang dan maju di semua panjang min..maks.
	var arah78: Vector2 = _arah_layar(78.0)
	for u: float in [0.0, 0.5, 1.0]:
		var akhir78: Vector2 = awal + arah78 * _panjang(u, lebar)
		var l78: ThrowSolver.Lintasan = ThrowSolver.dari_swipe(awal, akhir78, lebar, Vector2.ZERO, Config.KECEPATAN_SANTAI_UD, 0.0, jeda)
		check(absf((akhir78 - awal).y) > absf((akhir78 - awal).x) and l78 != null and l78.sisi == LoperAnim.Sisi.SEBERANG and l78.arah.y < 0.0, "swipe 78 derajat u %s (|dy| > |dx|, ditolak Run 2A): melempar ke seberang dan maju" % u)


## Berkas `.gd` di `scripts/` selain `config.gd` dan `throw_solver.gd` yang memakai konstanta lintasan, dari teks (penjaga AC-4).
func _pemakai_rumus(teks_per_berkas: Dictionary) -> Array[String]:
	var hasil: Array[String] = []
	for berkas: String in teks_per_berkas:
		if berkas == BERKAS_SOLVER or berkas == BERKAS_CONFIG:
			continue
		var teks: String = teks_per_berkas[berkas]
		for nama: String in KONSTANTA_LINTASAN:
			if teks.contains("Config." + nama):
				hasil.append("%s -> %s" % [berkas, nama])
	return hasil


func _daftar_gd(folder: String) -> Array[String]:
	var hasil: Array[String] = []
	var dir: DirAccess = DirAccess.open(folder)
	if dir == null:
		return hasil
	for nama: String in dir.get_files():
		if nama.get_extension() == "gd":
			hasil.append(folder.path_join(nama))
	for sub: String in dir.get_directories():
		hasil.append_array(_daftar_gd(folder.path_join(sub)))
	return hasil


func _test_penjaga_rumus() -> void:
	_judul.call("Penjaga: angka lintasan hanya dipakai ThrowSolver (satu sumber lintasan, AC-4)")
	var teks: Dictionary = {}
	for berkas: String in _daftar_gd("res://scripts"):
		teks[berkas] = FileAccess.get_file_as_string(berkas)
	check(teks.size() >= 20 and teks.has(BERKAS_SOLVER), "penjaga memindai seluruh scripts/ (%d berkas)" % teks.size())
	var pemakai: Array[String] = _pemakai_rumus(teks)
	check(pemakai.is_empty(), "tidak ada skrip lain yang memakai angka lintasan (rumus kedua): %s" % [pemakai])
	var buruk: Dictionary = {"res://scripts/ui/garis_bidik.gd": "var jarak: float = lerpf(Config.LEMPAR_JARAK_MIN_UBIN, Config.LEMPAR_JARAK_MAKS_UBIN, u)"}
	check(_pemakai_rumus(buruk).size() == 1, "contoh buruk: garis bidik dengan rumus jarak sendiri tertangkap")
	var buruk_swipe: Dictionary = {"res://scripts/entities/jalan_uji.gd": "if dx >= Config.LEMPAR_SWIPE_MIN_PECAHAN * lebar:"}
	check(_pemakai_rumus(buruk_swipe).size() == 1, "contoh buruk: ambang swipe dihitung di luar ThrowSolver tertangkap")


# --- Zona sasaran (AC-5, D-6) ---

func _zona(x: float, maju: float, lebar: float, panjang: float, jenis: ZonaSasaran.Jenis, sisi: LoperAnim.Sisi = LoperAnim.Sisi.SEBERANG, pelanggan: bool = true) -> ZonaSasaran.Zona:
	return ZonaSasaran.buat(Rect2(x, maju, lebar, panjang), sisi, jenis, pelanggan)


## Titik dunia dari koordinat jalan (lateral, maju).
func _titik(x: float, maju: float) -> Vector2:
	return Vector2(x, -maju)


func _test_zona_klasifikasi() -> void:
	_judul.call("Zona sasaran: tiap jenis, tepi inklusif/eksklusif, meleset, bukan pelanggan (AC-5 Run 2A, D-6)")
	var S: LoperAnim.Sisi = LoperAnim.Sisi.SEBERANG
	var D: LoperAnim.Sisi = LoperAnim.Sisi.DEKAT
	var daftar: Array[ZonaSasaran.Zona] = [
		_zona(-2.0, 0.0, 0.5, 0.5, ZonaSasaran.Jenis.KOTAK_SURAT),
		_zona(-3.0, 1.0, 1.0, 1.0, ZonaSasaran.Jenis.TERAS),
		_zona(-3.0, 3.0, 1.0, 1.0, ZonaSasaran.Jenis.HALAMAN),
		_zona(-3.0, 5.0, 0.25, 1.0, ZonaSasaran.Jenis.JENDELA),
		_zona(-3.0, 7.0, 1.0, 1.0, ZonaSasaran.Jenis.TERAS, S, false),
		_zona(2.0, 0.0, 1.0, 1.0, ZonaSasaran.Jenis.HALAMAN, D),
	]
	check(ZonaSasaran.klasifikasi(_titik(-1.75, 0.25), daftar) == ZonaSasaran.Hasil.KOTAK_SURAT, "titik di kotak surat = KOTAK_SURAT")
	check(ZonaSasaran.klasifikasi(_titik(-2.5, 1.5), daftar) == ZonaSasaran.Hasil.TERAS, "titik di teras = TERAS")
	check(ZonaSasaran.klasifikasi(_titik(-2.5, 3.5), daftar) == ZonaSasaran.Hasil.HALAMAN, "titik di halaman = HALAMAN")
	check(ZonaSasaran.klasifikasi(_titik(-2.9, 5.5), daftar) == ZonaSasaran.Hasil.JENDELA, "titik di strip jendela = JENDELA")
	check(ZonaSasaran.klasifikasi(_titik(-2.5, 7.5), daftar) == ZonaSasaran.Hasil.BUKAN_PELANGGAN, "teras rumah bukan pelanggan = BUKAN_PELANGGAN")
	check(ZonaSasaran.klasifikasi(_titik(2.5, 0.5), daftar) == ZonaSasaran.Hasil.HALAMAN, "halaman sisi dekat = HALAMAN")
	check(ZonaSasaran.klasifikasi(_titik(-2.5, 2.5), daftar) == ZonaSasaran.Hasil.MELESET and ZonaSasaran.klasifikasi(_titik(0.0, 0.0), daftar) == ZonaSasaran.Hasil.MELESET, "titik di luar semua zona (celah, jalan) = MELESET")
	check(ZonaSasaran.klasifikasi(Vector2(NAN, 0.0), daftar) == ZonaSasaran.Hasil.MELESET and ZonaSasaran.klasifikasi(Vector2(-1.75, INF), daftar) == ZonaSasaran.Hasil.MELESET, "titik tidak hingga = MELESET")
	check(ZonaSasaran.klasifikasi(_titik(-1.75, 0.25), [] as Array[ZonaSasaran.Zona]) == ZonaSasaran.Hasil.MELESET, "tanpa zona = MELESET")
	# Tepi: min inklusif, maks eksklusif, di kedua sumbu (lateral dan maju).
	var kotak: ZonaSasaran.Zona = daftar[0]
	check(ZonaSasaran.memuat(kotak, _titik(-2.0, 0.0)), "tepi min lateral dan maju (pojok min) inklusif")
	check(not ZonaSasaran.memuat(kotak, _titik(-1.5, 0.25)), "tepi maks lateral (-1,5) eksklusif")
	check(not ZonaSasaran.memuat(kotak, _titik(-1.75, 0.5)), "tepi maks maju (0,5) eksklusif")
	check(ZonaSasaran.memuat(kotak, _titik(-1.5001, 0.4999)), "tepat di dalam tepi maks = di dalam")
	check(not ZonaSasaran.memuat(kotak, _titik(-2.0001, 0.25)) and not ZonaSasaran.memuat(kotak, _titik(-1.75, -0.0001)), "tepat di luar tepi min = di luar")
	# Dua zona bersebelahan: tepi bersama hanya milik yang di atas (maks eksklusif), tidak pernah dua-duanya.
	var a: ZonaSasaran.Zona = _zona(-3.0, 0.0, 1.0, 1.0, ZonaSasaran.Jenis.HALAMAN)
	var b: ZonaSasaran.Zona = _zona(-3.0, 1.0, 1.0, 1.0, ZonaSasaran.Jenis.HALAMAN)
	check(not ZonaSasaran.memuat(a, _titik(-2.5, 1.0)) and ZonaSasaran.memuat(b, _titik(-2.5, 1.0)), "tepi bersama dua zona bersebelahan hanya dimuat zona sesudahnya")
	# Hasil murni dan zona yang menang.
	check(ZonaSasaran.zona_kena(_titik(-1.75, 0.25), daftar) == kotak and ZonaSasaran.zona_kena(_titik(0.0, 0.0), daftar) == null, "zona_kena mengembalikan zona yang menang atau null")
	check(ZonaSasaran.ke_jalan(Vector2(-1.0, -4.0)) == Vector2(-1.0, 4.0), "koordinat jalan: maju = -y dunia")


func _test_zona_prioritas() -> void:
	_judul.call("Zona tumpang tindih: kotak surat > jendela > teras > halaman, tidak bergantung urutan daftar (AC-5, D-6)")
	var S: LoperAnim.Sisi = LoperAnim.Sisi.SEBERANG
	var k: ZonaSasaran.Zona = _zona(-3.0, 0.0, 2.0, 2.0, ZonaSasaran.Jenis.KOTAK_SURAT)
	var j: ZonaSasaran.Zona = _zona(-3.0, 0.0, 2.0, 2.0, ZonaSasaran.Jenis.JENDELA)
	var t: ZonaSasaran.Zona = _zona(-3.0, 0.0, 2.0, 2.0, ZonaSasaran.Jenis.TERAS)
	var h: ZonaSasaran.Zona = _zona(-3.0, 0.0, 2.0, 2.0, ZonaSasaran.Jenis.HALAMAN)
	var p: Vector2 = _titik(-2.0, 1.0)
	var urutan: Array = [[h, t, j, k], [k, j, t, h], [t, k, h, j], [j, h, k, t]]
	for u: Array in urutan:
		var daftar: Array[ZonaSasaran.Zona] = []
		daftar.assign(u)
		check(ZonaSasaran.klasifikasi(p, daftar) == ZonaSasaran.Hasil.KOTAK_SURAT, "empat zona tumpang tindih (urutan %s) = KOTAK_SURAT" % [u.map(func(z: ZonaSasaran.Zona) -> int: return int(z.jenis))])
	var tiga: Array[ZonaSasaran.Zona] = [h, t, j]
	check(ZonaSasaran.klasifikasi(p, tiga) == ZonaSasaran.Hasil.JENDELA, "tanpa kotak surat: JENDELA menang atas teras dan halaman")
	var dua: Array[ZonaSasaran.Zona] = [h, t]
	var dua_balik: Array[ZonaSasaran.Zona] = [t, h]
	check(ZonaSasaran.klasifikasi(p, dua) == ZonaSasaran.Hasil.TERAS and ZonaSasaran.klasifikasi(p, dua_balik) == ZonaSasaran.Hasil.TERAS, "teras menang atas halaman, kedua urutan")
	var jt: Array[ZonaSasaran.Zona] = [t, j]
	check(ZonaSasaran.klasifikasi(p, jt) == ZonaSasaran.Hasil.JENDELA, "jendela menang atas teras")
	var kj: Array[ZonaSasaran.Zona] = [j, k]
	check(ZonaSasaran.klasifikasi(p, kj) == ZonaSasaran.Hasil.KOTAK_SURAT, "kotak surat menang atas jendela")
	# Prioritas dulu, baru status pelanggan: kotak surat rumah bukan pelanggan di atas halaman pelanggan = bukan pelanggan.
	var kb: ZonaSasaran.Zona = _zona(-3.0, 0.0, 2.0, 2.0, ZonaSasaran.Jenis.KOTAK_SURAT, S, false)
	var campur: Array[ZonaSasaran.Zona] = [h, kb]
	check(ZonaSasaran.klasifikasi(p, campur) == ZonaSasaran.Hasil.BUKAN_PELANGGAN, "zona prioritas tertinggi milik rumah bukan pelanggan = BUKAN_PELANGGAN")
	var prioritas: Array[ZonaSasaran.Jenis] = [ZonaSasaran.Jenis.KOTAK_SURAT, ZonaSasaran.Jenis.JENDELA, ZonaSasaran.Jenis.TERAS, ZonaSasaran.Jenis.HALAMAN]
	check(ZonaSasaran.PRIORITAS == prioritas, "urutan prioritas tertulis: kotak surat, jendela, teras, halaman")


func _test_antaran_dan_penanda() -> void:
	_judul.call("Status antaran, sakelar jendela dua nilai, bentuk penanda (AC-5, AC-9, D-6, D-7, D-10)")
	var H: Dictionary = {
		"kotak surat": ZonaSasaran.Hasil.KOTAK_SURAT, "teras": ZonaSasaran.Hasil.TERAS, "halaman": ZonaSasaran.Hasil.HALAMAN,
		"jendela": ZonaSasaran.Hasil.JENDELA, "bukan pelanggan": ZonaSasaran.Hasil.BUKAN_PELANGGAN, "meleset": ZonaSasaran.Hasil.MELESET,
	}
	# [hasil, antaran penalti, antaran bonus, penanda penalti, penanda bonus]
	var tabel: Array = [
		["kotak surat", ZonaSasaran.Antaran.SAH_PENUH, ZonaSasaran.Antaran.SAH_PENUH, ZonaSasaran.Penanda.CENTANG, ZonaSasaran.Penanda.CENTANG],
		["teras", ZonaSasaran.Antaran.SAH_PENUH, ZonaSasaran.Antaran.SAH_PENUH, ZonaSasaran.Penanda.CENTANG, ZonaSasaran.Penanda.CENTANG],
		["halaman", ZonaSasaran.Antaran.SAH_SETENGAH, ZonaSasaran.Antaran.SAH_SETENGAH, ZonaSasaran.Penanda.SETENGAH, ZonaSasaran.Penanda.SETENGAH],
		["jendela", ZonaSasaran.Antaran.TIDAK_SAH, ZonaSasaran.Antaran.SAH_BONUS, ZonaSasaran.Penanda.SILANG, ZonaSasaran.Penanda.BINTANG],
		["bukan pelanggan", ZonaSasaran.Antaran.TIDAK_SAH, ZonaSasaran.Antaran.TIDAK_SAH, ZonaSasaran.Penanda.SILANG, ZonaSasaran.Penanda.SILANG],
		["meleset", ZonaSasaran.Antaran.TIDAK_SAH, ZonaSasaran.Antaran.TIDAK_SAH, ZonaSasaran.Penanda.SILANG, ZonaSasaran.Penanda.SILANG],
	]
	for baris: Array in tabel:
		var hasil: ZonaSasaran.Hasil = H[baris[0]]
		check(ZonaSasaran.status_antaran(hasil, false) == baris[1] and ZonaSasaran.status_antaran(hasil, true) == baris[2], "%s: antaran penalti %s, bonus %s" % [baris[0], baris[1], baris[2]])
		check(ZonaSasaran.penanda_hasil(hasil, false) == baris[3] and ZonaSasaran.penanda_hasil(hasil, true) == baris[4], "%s: penanda penalti %s, bonus %s" % [baris[0], baris[3], baris[4]])
		check(ZonaSasaran.sah(ZonaSasaran.status_antaran(hasil, false)) == (baris[3] != ZonaSasaran.Penanda.SILANG), "%s: sah (elips OK) tepat bila penandanya bukan silang" % baris[0])
	check(ZonaSasaran.status_antaran(ZonaSasaran.Hasil.JENDELA, Config.JENDELA_KENA_BONUS) == ZonaSasaran.Antaran.TIDAK_SAH, "bawaan Config: jendela = penalti ringan (tidak sah)")
	# Bentuk: tiap antaran sah berbeda dari tidak sah, bonus berbeda dari sah biasa, halaman berbeda dari keduanya.
	var bentuk: Array = [ZonaSasaran.Antaran.TIDAK_SAH, ZonaSasaran.Antaran.SAH_PENUH, ZonaSasaran.Antaran.SAH_SETENGAH, ZonaSasaran.Antaran.SAH_BONUS].map(func(a: ZonaSasaran.Antaran) -> int: return int(ZonaSasaran.penanda(a)))
	var unik: Dictionary = {}
	for b: int in bentuk:
		unik[b] = true
	check(unik.size() == 4, "empat status antaran = empat bentuk penanda berbeda (tidak hanya warna), dapat %s" % [bentuk])
	check(ZonaSasaran.penanda(-3 as ZonaSasaran.Antaran) == ZonaSasaran.Penanda.SILANG and ZonaSasaran.status_antaran(99 as ZonaSasaran.Hasil, true) == ZonaSasaran.Antaran.TIDAK_SAH, "nilai di luar enum = tidak sah, silang")


# --- Data jalan uji ---

func _test_zona_jalan_uji() -> void:
	_judul.call("Zona jalan uji dari Config.JALAN_UJI_* (placeholder, D-6)")
	var data: Dictionary = {
		"SEBERANG_KOTAK_SURAT": Config.JALAN_UJI_SEBERANG_KOTAK_SURAT_UBIN, "SEBERANG_HALAMAN": Config.JALAN_UJI_SEBERANG_HALAMAN_UBIN,
		"SEBERANG_TERAS": Config.JALAN_UJI_SEBERANG_TERAS_UBIN, "SEBERANG_JENDELA": Config.JALAN_UJI_SEBERANG_JENDELA_UBIN,
		"DEKAT_KOTAK_SURAT": Config.JALAN_UJI_DEKAT_KOTAK_SURAT_UBIN, "DEKAT_HALAMAN": Config.JALAN_UJI_DEKAT_HALAMAN_UBIN,
		"DEKAT_TERAS": Config.JALAN_UJI_DEKAT_TERAS_UBIN,
	}
	var tepi_aspal: float = Config.JALAN_LEBAR_UBIN / 2
	for nama: String in data:
		var d: Array[float] = data[nama]
		check(d.size() == 4 and d[2] > 0.0 and d[3] > 0.0, "%s: 4 angka, ukuran positif" % nama)
		var seberang: bool = nama.begins_with("SEBERANG")
		check((d[0] + d[2] <= -tepi_aspal) if seberang else (d[0] >= tepi_aspal), "%s: seluruhnya di sisinya dan di luar aspal (lateral %s sampai %s)" % [nama, d[0], d[0] + d[2]])
	# Teras dan jendela seberang di kaki fasad rumah graybox.
	check(Config.JALAN_UJI_SEBERANG_TERAS_UBIN[0] == Config.JALAN_UJI_RUMAH_X_UBIN and Config.JALAN_UJI_SEBERANG_JENDELA_UBIN[0] == Config.JALAN_UJI_RUMAH_X_UBIN, "teras dan jendela seberang mulai di kaki fasad (x rumah %s)" % Config.JALAN_UJI_RUMAH_X_UBIN)
	var zona: Array[ZonaSasaran.Zona] = ZonaSasaran.zona_jalan_uji(5)
	var jenis_seberang: Array = []
	var jenis_dekat: Array = []
	for z: ZonaSasaran.Zona in zona:
		if z.sisi == LoperAnim.Sisi.SEBERANG:
			jenis_seberang.append(z.jenis)
		elif z.sisi == LoperAnim.Sisi.DEKAT:
			jenis_dekat.append(z.jenis)
		check(z.rumah == 5, "zona kavling 5 bernomor rumah 5")
	check(jenis_seberang.size() == 4 and jenis_seberang.has(ZonaSasaran.Jenis.JENDELA), "seberang: kotak surat, halaman, teras, jendela")
	check(jenis_dekat.size() == 3 and not jenis_dekat.has(ZonaSasaran.Jenis.JENDELA), "dekat: kotak surat, halaman, teras, tanpa jendela (tanpa fasad)")
	check(is_equal_approx(zona[0].persegi.position.y, Config.JALAN_UJI_SEBERANG_KOTAK_SURAT_UBIN[1] + 5.0 * Config.JALAN_UJI_RUMAH_PERIODE_UBIN), "kavling 5 digeser maju 5 x periode")
	# Bukan pelanggan: minimal satu per putaran daur, tidak semua.
	var slot: int = JalanDaur.jumlah_slot(Config.JALAN_UJI_DAUR_MUNDUR_UBIN, Config.JALAN_UJI_DAUR_MAJU_UBIN, Config.JALAN_UJI_RUMAH_PERIODE_UBIN)
	var semua_ada: bool = true
	for mulai: int in range(-20, 20):
		var bukan: int = 0
		for i: int in range(mulai, mulai + slot):
			if not ZonaSasaran.pelanggan_jalan_uji(i):
				bukan += 1
		if bukan < 1 or bukan >= slot:
			semua_ada = false
	check(semua_ada, "tiap %d rumah berurutan (satu putaran daur) ada minimal satu bukan pelanggan dan tidak semua" % slot)
	check(not ZonaSasaran.pelanggan_jalan_uji(Config.JALAN_UJI_BUKAN_PELANGGAN_SISA) and ZonaSasaran.pelanggan_jalan_uji(Config.JALAN_UJI_BUKAN_PELANGGAN_SISA + 1) and not ZonaSasaran.pelanggan_jalan_uji(Config.JALAN_UJI_BUKAN_PELANGGAN_SISA - Config.JALAN_UJI_BUKAN_PELANGGAN_SETIAP), "nomor bukan pelanggan berulang, juga untuk nomor negatif")
	for z: ZonaSasaran.Zona in ZonaSasaran.zona_jalan_uji(Config.JALAN_UJI_BUKAN_PELANGGAN_SISA):
		check(z.pelanggan == (z.sisi == LoperAnim.Sisi.DEKAT), "rumah bukan pelanggan: semua zona seberang bukan pelanggan, kavling dekat tetap pelanggan")
	# Sekitar: kavling tetangga ikut (halaman menjorok ke kavling sebelumnya).
	var sekitar: Array[ZonaSasaran.Zona] = ZonaSasaran.zona_jalan_uji_sekitar(20.1)
	var nomor: Dictionary = {}
	for z: ZonaSasaran.Zona in sekitar:
		nomor[z.rumah] = true
	check(nomor.keys() == [4, 5, 6], "zona sekitar maju 20,1 = kavling 4, 5, 6, dapat %s" % [nomor.keys()])
	check(ZonaSasaran.zona_jalan_uji_sekitar(NAN).is_empty(), "maju tidak hingga = tanpa zona")
	var halaman_awal: Vector2 = _titik(-2.5, 4.0 * 5.0 - 0.25)
	check(ZonaSasaran.klasifikasi_jalan_uji(halaman_awal) == ZonaSasaran.Hasil.HALAMAN, "titik halaman kavling 5 yang menjorok ke kavling 4 tetap HALAMAN")


## Keterjangkauan (AC-5 Run 2A): tiap zona di jalan uji bisa dikenai dari suatu posisi lateral di dalam jalan pada santai, cepat, dan
## ngebut dengan swipe di rentang min-maks, bahkan hanya dengan arah melintang murni (`arah_sisi`, satu arah dari banyak arah bebas). Titik mendarat dicari lewat ThrowSolver sungguhan; posisi maju sepeda digeser supaya titik itu jatuh
## di tengah zona sepanjang jalan (jalan uji tanpa ujung: sepeda bisa di mana saja sepanjang jalan).
func _test_keterjangkauan() -> void:
	_judul.call("Keterjangkauan: tiap zona jalan uji terkena dari lateral di dalam jalan, tiga kecepatan, swipe min-maks (AC-5)")
	var lebar: float = 780.0
	var jeda: float = _jeda_lepas()
	var batas: float = BikeMotion.batas_lateral_ubin()
	for indeks: int in [0, Config.JALAN_UJI_BUKAN_PELANGGAN_SISA]:
		for zona: ZonaSasaran.Zona in ZonaSasaran.zona_jalan_uji(indeks):
			var diharapkan: ZonaSasaran.Hasil = ZonaSasaran.hasil_zona(zona)
			for v: float in [Config.KECEPATAN_SANTAI_UD, Config.KECEPATAN_CEPAT_UD, Config.KECEPATAN_NGEBUT_UD]:
				var kena: String = ""
				for i: int in range(33):
					var lateral: float = lerpf(-batas, batas, float(i) / 32.0)
					for j: int in range(65):
						var u: float = float(j) / 64.0
						var coba: ThrowSolver.Lintasan = ThrowSolver.hitung(_panjang(u, lebar), lebar, ThrowSolver.arah_sisi(zona.sisi), Vector2(lateral, 0.0), v, 0.0, jeda)
						var jalan: Vector2 = ZonaSasaran.ke_jalan(coba.titik_mendarat)
						if jalan.x < zona.persegi.position.x or jalan.x >= zona.persegi.end.x:
							continue
						# Geser sepeda sepanjang jalan supaya titik mendarat di tengah zona (maju).
						var geser: float = zona.persegi.get_center().y - jalan.y
						var l: ThrowSolver.Lintasan = ThrowSolver.hitung(_panjang(u, lebar), lebar, ThrowSolver.arah_sisi(zona.sisi), Vector2(lateral, -geser), v, 0.0, jeda)
						if ZonaSasaran.zona_kena(l.titik_mendarat, ZonaSasaran.zona_jalan_uji_sekitar(ZonaSasaran.ke_jalan(l.titik_mendarat).y)) == null:
							continue
						if ZonaSasaran.klasifikasi_jalan_uji(l.titik_mendarat) == diharapkan:
							kena = "lateral %.3f, u %.3f" % [lateral, u]
							break
					if not kena.is_empty():
						break
				check(not kena.is_empty(), "kavling %d %s %s di %s u/d: terjangkau (%s)" % [indeks, "seberang" if zona.sisi == LoperAnim.Sisi.SEBERANG else "dekat", ZonaSasaran.Jenis.keys()[zona.jenis], v, kena if not kena.is_empty() else "TIDAK"])


# --- Sisa koran dan jeda antar lempar (AC-6, D-8, D-9, D-11) ---

func _test_sisa_koran() -> void:
	_judul.call("Sisa koran: mulai 30, tiap lempar -1 tepat sekali, habis = tidak melempar (AC-6, D-8)")
	var k: SisaKoran.Keadaan = SisaKoran.awal(Config.KORAN_AWAL)
	check(k.sisa == 30 and k.penuh == 30 and SisaKoran.boleh_lempar(k) and not SisaKoran.habis(k), "awal: 30 koran, boleh melempar")
	var semua_tepat: bool = true
	for i: int in range(30):
		var h: SisaKoran.Hasil = SisaKoran.terima(k, float(i))
		if not h.diterima or h.keadaan.sisa != 29 - i:
			semua_tepat = false
		k = SisaKoran.langkah(h.keadaan, Config.LEMPAR_JEDA_DETIK)
	check(semua_tepat and k.sisa == 0 and SisaKoran.habis(k), "30 lemparan diterima, tiap lemparan -1 tepat sekali, sisa 0")
	check(not SisaKoran.boleh_lempar(k), "habis: tidak boleh melempar (tidak ada garis bidik)")
	var lagi: SisaKoran.Hasil = SisaKoran.terima(k, 30.0)
	check(not lagi.diterima and lagi.keadaan.sisa == 0, "habis: swipe tidak melempar, sisa tetap 0 (tidak negatif)")
	check(k.habis_di_ubin == 29.0, "jarak saat habis dicatat (29 ubin)")
	# Murni: masukan tidak berubah.
	var awal: SisaKoran.Keadaan = SisaKoran.awal(5)
	var h1: SisaKoran.Hasil = SisaKoran.terima(awal, 0.0)
	check(awal.sisa == 5 and awal.sejak_lempar_detik == INF and h1.keadaan != awal and h1.keadaan.sisa == 4, "terima tidak mengubah keadaan masukan")
	check(SisaKoran.awal(-3).sisa == 0 and SisaKoran.awal(-3).penuh == 0, "jumlah awal negatif = 0")


func _test_jeda_antar_lempar() -> void:
	_judul.call("Jeda antar lempar 0,35 detik: 0,349 ditolak, 0,35 diterima, swipe selama jeda tidak mengurangi koran (AC-6, D-9, D-11)")
	var k: SisaKoran.Keadaan = SisaKoran.terima(SisaKoran.awal(30), 0.0).keadaan
	check(k.sisa == 29 and k.sejak_lempar_detik == 0.0, "lemparan pertama diterima, jeda mulai dari 0 (jari dilepas)")
	var k349: SisaKoran.Keadaan = SisaKoran.langkah(k, 0.349)
	var tolak: SisaKoran.Hasil = SisaKoran.terima(k349, 0.0)
	check(not SisaKoran.boleh_lempar(k349) and not tolak.diterima and tolak.keadaan.sisa == 29, "0,349 detik: ditolak, koran tidak berkurang")
	check(tolak.keadaan.sejak_lempar_detik == k349.sejak_lempar_detik, "swipe yang ditolak tidak memulai ulang jeda")
	var k35: SisaKoran.Keadaan = SisaKoran.langkah(k349, 0.001)
	var terima: SisaKoran.Hasil = SisaKoran.terima(k35, 0.0)
	check(SisaKoran.boleh_lempar(k35) and terima.diterima and terima.keadaan.sisa == 28, "0,349 + 0,001 = 0,35 detik: diterima (inklusif)")
	check(SisaKoran.boleh_lempar(SisaKoran.langkah(k, 0.35)), "langsung 0,35 detik: diterima")
	# Tepi toleransi: 0,35 - toleransi masih diterima (>=, inklusif), dua kali toleransi di bawahnya ditolak.
	var tepi: float = Config.LEMPAR_JEDA_DETIK - Config.LEMPAR_TOLERANSI_DETIK
	check(SisaKoran.jeda_lewat(tepi) and not SisaKoran.jeda_lewat(tepi - Config.LEMPAR_TOLERANSI_DETIK), "tepi inklusif: %s diterima (perbandingan >=), %s ditolak" % [tepi, tepi - Config.LEMPAR_TOLERANSI_DETIK])
	# Derau float: jumlah langkah kecil yang seharusnya 0,35.
	for kasus: Array in [[60, 21], [240, 84], [30, 10]]:
		var dt: float = 1.0 / float(kasus[0])
		var langkah: int = kasus[1]
		var x: SisaKoran.Keadaan = k
		for i: int in range(langkah - 1):
			x = SisaKoran.langkah(x, dt)
		var sebelum: bool = SisaKoran.boleh_lempar(x)
		x = SisaKoran.langkah(x, dt)
		var batas_30: bool = kasus[0] == 30
		# 1/30: 10 langkah = 0,333 (masih jeda), 11 langkah = 0,367.
		if batas_30:
			check(not SisaKoran.boleh_lempar(x) and SisaKoran.boleh_lempar(SisaKoran.langkah(x, dt)), "dt 1/30: 10 langkah (0,333) masih jeda, 11 langkah boleh")
		else:
			check(not sebelum and SisaKoran.boleh_lempar(x), "dt 1/%d: %d langkah (jumlah float 0,35) boleh, satu langkah sebelumnya belum" % [kasus[0], langkah])
	# Jeda game (D-11): dt 0 (JedaSim) membekukan jeda antar lempar; dt tidak sah tidak memajukan.
	var beku: SisaKoran.Keadaan = SisaKoran.langkah(k, 0.2)
	for dt_salah: float in [0.0, -1.0, NAN, INF]:
		check(SisaKoran.langkah(beku, dt_salah).sejak_lempar_detik == beku.sejak_lempar_detik, "dt %s tidak memajukan jeda antar lempar (jeda game membeku)" % dt_salah)
	check(SisaKoran.jeda_lewat(INF) and SisaKoran.jeda_lewat(NAN), "belum pernah melempar (INF) atau NaN tidak mengunci lemparan")


func _test_isi_ulang() -> void:
	_judul.call("Isi ulang khusus jalan uji: hanya bila habis, sesudah 16 ubin (alat uji, D-8)")
	var k: SisaKoran.Keadaan = SisaKoran.awal(2)
	k = SisaKoran.terima(k, 3.0).keadaan
	k = SisaKoran.terima(SisaKoran.langkah(k, 0.35), 10.0).keadaan
	check(SisaKoran.habis(k) and k.habis_di_ubin == 10.0, "habis di 10 ubin")
	check(SisaKoran.isi_ulang_jalan_uji(k, 25.99).sisa == 0, "baru 15,99 ubin sesudah habis: belum diisi ulang")
	var penuh: SisaKoran.Keadaan = SisaKoran.isi_ulang_jalan_uji(k, 26.0)
	check(penuh.sisa == 2 and is_nan(penuh.habis_di_ubin) and SisaKoran.boleh_lempar(SisaKoran.langkah(penuh, Config.LEMPAR_JEDA_DETIK)), "16 ubin sesudah habis: penuh lagi (2), catatan habis dihapus")
	check(k.sisa == 0, "isi ulang tidak mengubah keadaan masukan")
	var sisa: SisaKoran.Keadaan = SisaKoran.terima(SisaKoran.awal(30), 0.0).keadaan
	check(SisaKoran.isi_ulang_jalan_uji(sisa, 500.0).sisa == 29, "belum habis: tidak diisi ulang walau sudah jauh (isi ulang hanya bila habis)")
	check(SisaKoran.isi_ulang_jalan_uji(k, NAN).sisa == 0 and SisaKoran.isi_ulang_jalan_uji(k, INF).sisa == 0, "jarak tidak hingga: tidak diisi ulang")
	check(SisaKoran.isi_ulang_jalan_uji(penuh, 100.0).sisa == 2, "sesudah diisi ulang tidak terisi lagi (sudah penuh)")


# --- Bagian 1b: KoranLempar (D-4, D-5, D-10, D-11 bagian murni) dan PolaPiksel ---

func _lintasan_uji(u: float, sisi: LoperAnim.Sisi, v: float, maju: float = 10.0) -> ThrowSolver.Lintasan:
	return ThrowSolver.hitung(_panjang(u, 780.0), 780.0, ThrowSolver.arah_sisi(sisi), Vector2(0.2, -maju), v, 0.0, _jeda_lepas())


func _test_koran_lempar() -> void:
	_judul.call("KoranLempar: waktu, lepas, mendarat, penanda, beku saat dt 0 (D-4, D-10, D-11)")
	var l: ThrowSolver.Lintasan = _lintasan_uji(0.5, LoperAnim.Sisi.SEBERANG, 4.5)
	var k: KoranLempar.Koran = KoranLempar.baru(l)
	check(k.lintasan == l and k.detik == 0.0 and not k.mendarat, "koran baru: lintasan beku, detik 0, belum mendarat")
	check(not KoranLempar.di_udara(k) and KoranLempar.posisi(k) == Vector3(l.titik_lepas.x, l.titik_lepas.y, l.tinggi_tangan), "sebelum jeda lepas: belum di udara, di titik lepas setinggi tangan")
	for dt: float in [0.0, -1.0, NAN, INF, -INF]:
		var sama: KoranLempar.Koran = KoranLempar.langkah(k, dt, false)
		check(sama.detik == 0.0 and not sama.mendarat, "dt %s tidak memajukan koran (jeda game membeku)" % dt)
	var maju: KoranLempar.Koran = KoranLempar.langkah(k, 0.1, false)
	check(k.detik == 0.0 and maju != k and is_equal_approx(maju.detik, 0.1), "langkah mengembalikan objek baru, masukan tidak berubah")
	var lepas: KoranLempar.Koran = KoranLempar.langkah(k, l.jeda_lepas, false)
	check(KoranLempar.di_udara(lepas) and KoranLempar.frame_putar(lepas, 4) == 0, "tepat jeda lepas: di udara, frame putar 0")
	check(KoranLempar.frame_putar(KoranLempar.langkah(lepas, 1.0 / 12.0, false), 4) == 1 and KoranLempar.frame_putar(KoranLempar.langkah(lepas, 4.0 / 12.0, false), 4) == 0, "frame putar 12 fps, 4 langkah berulang")
	# Mendarat tepat sekali pada langkah yang melewati lama total, di titik mendarat persis.
	var total: float = ThrowSolver.lama_total(l)
	for dt: float in [1.0 / 30.0, 1.0 / 60.0, 1.0 / 240.0]:
		var c: KoranLempar.Koran = KoranLempar.baru(l)
		var kali: int = 0
		var mendarat_di: float = -1.0
		while c.detik < total + 0.2:
			var baru: KoranLempar.Koran = KoranLempar.langkah(c, dt, false)
			if baru.mendarat and not c.mendarat:
				kali += 1
				mendarat_di = baru.detik
			c = baru
		check(kali == 1 and mendarat_di + 0.000001 >= total and mendarat_di - dt < total, "dt 1/%d: mendarat tepat sekali pada langkah yang melewati jeda lepas + lama terbang (%s, total %s)" % [roundi(1.0 / dt), mendarat_di, total])
		check(KoranLempar.posisi(c) == Vector3(l.titik_mendarat.x, l.titik_mendarat.y, 0.0), "dt 1/%d: posisi sesudah mendarat = titik mendarat persis, tinggi 0" % roundi(1.0 / dt))
	# Penanda: penuh sebelum mendarat, berkurang sejak mendarat, selesai sesudah PENANDA_LAMA_DETIK.
	var d: KoranLempar.Koran = KoranLempar.langkah(k, total, false)
	check(d.mendarat and is_equal_approx(KoranLempar.sisa_penanda(d), Config.PENANDA_LAMA_DETIK) and not KoranLempar.selesai(d), "tepat mendarat: penanda penuh 0,8 detik")
	check(is_equal_approx(KoranLempar.sisa_penanda(KoranLempar.langkah(d, 0.5, false)), Config.PENANDA_LAMA_DETIK - 0.5), "0,5 detik sesudah mendarat: sisa penanda 0,3")
	check(not KoranLempar.selesai(KoranLempar.langkah(d, Config.PENANDA_LAMA_DETIK - 0.01, false)) and KoranLempar.selesai(KoranLempar.langkah(d, Config.PENANDA_LAMA_DETIK, false)), "selesai tepat sesudah 0,8 detik penanda")
	check(not KoranLempar.di_udara(d), "sesudah mendarat tidak di udara")
	# Penilaian di titik mendarat sama dengan prediksi elips (fungsi yang sama), kedua nilai sakelar jendela.
	var cocok: bool = true
	var jumlah_sah: int = 0
	var jumlah_jendela: int = 0
	for maju_ubin: int in range(0, 24):
		for langkah_u: int in range(21):
			var u: float = float(langkah_u) / 20.0
			for sisi: LoperAnim.Sisi in [LoperAnim.Sisi.SEBERANG, LoperAnim.Sisi.DEKAT]:
				var lin: ThrowSolver.Lintasan = _lintasan_uji(u, sisi, 3.0, float(maju_ubin) / 2.0)
				for bonus: bool in [false, true]:
					var akhir: KoranLempar.Koran = KoranLempar.langkah(KoranLempar.baru(lin), ThrowSolver.lama_total(lin), bonus)
					if akhir.antaran != KoranLempar.prediksi_antaran(lin, bonus) or akhir.hasil != ZonaSasaran.klasifikasi_jalan_uji(lin.titik_mendarat) or akhir.penanda != ZonaSasaran.penanda(akhir.antaran):
						cocok = false
					if ZonaSasaran.sah(akhir.antaran):
						jumlah_sah += 1
					if akhir.hasil == ZonaSasaran.Hasil.JENDELA:
						jumlah_jendela += 1
						if (akhir.antaran == ZonaSasaran.Antaran.SAH_BONUS) != bonus:
							cocok = false
	check(cocok, "1008 lintasan x 2 sakelar: hasil, antaran, dan penanda saat mendarat = prediksi elips garis bidik (KoranLempar.prediksi_antaran)")
	check(jumlah_sah > 20 and jumlah_jendela > 0, "kontrol: sampel memuat pendaratan sah (%d) dan jendela (%d)" % [jumlah_sah, jumlah_jendela])
	check(KoranLempar.prediksi_antaran(null, true) == ZonaSasaran.Antaran.TIDAK_SAH and KoranLempar.hasil_mendarat(null) == ZonaSasaran.Hasil.MELESET, "lintasan null = meleset, tidak sah")
	# Bayangan mengecil saat tinggi naik, dijepit.
	check(KoranLempar.lebar_bayangan_px(0.0) == Config.KORAN_BAYANGAN_LEBAR_MAKS_PX and KoranLempar.lebar_bayangan_px(100.0) == Config.KORAN_BAYANGAN_LEBAR_MIN_PX and KoranLempar.lebar_bayangan_px(NAN) == Config.KORAN_BAYANGAN_LEBAR_MAKS_PX, "bayangan: %d px di tanah, %d px paling kecil, NaN = di tanah" % [Config.KORAN_BAYANGAN_LEBAR_MAKS_PX, Config.KORAN_BAYANGAN_LEBAR_MIN_PX])
	check(Config.KORAN_BAYANGAN_LEBAR_MAKS_PX > PolaPiksel.ukuran(PolaPiksel.pola_koran(0)).x and Config.KORAN_BAYANGAN_LEBAR_MIN_PX >= 6, "bayangan koran di tanah lebih lebar dari koran 8 px, paling kecil 6 px (QA-007)")
	var naik: bool = true
	for i: int in range(1, 20):
		if KoranLempar.lebar_bayangan_px(float(i) / 10.0) > KoranLempar.lebar_bayangan_px(float(i - 1) / 10.0):
			naik = false
	check(naik and KoranLempar.lebar_bayangan_px(1.6) < KoranLempar.lebar_bayangan_px(0.7), "bayangan tidak membesar saat tinggi naik (puncak 1,6 lebih kecil dari tangan 0,7)")


func _test_titik_bidik() -> void:
	_judul.call("Titik garis bidik = sampel posisi_pada tiap 4 px (D-5, AC-4)")
	for u: float in [0.0, 0.5, 1.0]:
		for v: float in KECEPATAN:
			var l: ThrowSolver.Lintasan = _lintasan_uji(u, LoperAnim.Sisi.DEKAT, v)
			var waktu: PackedFloat32Array = KoranLempar.waktu_titik_bidik(l, 4.0, Config.GARIS_BIDIK_SAMPEL)
			var tag: String = "u %s, %s u/d" % [u, v]
			check(waktu.size() >= 8 and waktu[0] == 0.0, "%s: titik pertama di t = 0 (titik lepas), %d titik" % [tag, waktu.size()])
			var sampel: bool = true
			var jarak_cukup: bool = true
			for i: int in range(waktu.size()):
				var indeks: float = waktu[i] * float(Config.GARIS_BIDIK_SAMPEL) / l.lama_terbang
				if absf(indeks - roundf(indeks)) > 0.001 or waktu[i] > l.lama_terbang + 0.000001:
					sampel = false
				if i > 0:
					# Jarak sepanjang lengkung (sampel merata di antara dua titik) >= 4 px; jarak lurus >= 2 px (titik 2 px tidak menumpuk).
					var lengkung: float = 0.0
					var n_awal: int = roundi(waktu[i - 1] * float(Config.GARIS_BIDIK_SAMPEL) / l.lama_terbang)
					var n_akhir: int = roundi(waktu[i] * float(Config.GARIS_BIDIK_SAMPEL) / l.lama_terbang)
					for n: int in range(n_awal, n_akhir):
						var t0: float = l.lama_terbang * float(n) / float(Config.GARIS_BIDIK_SAMPEL)
						var t1: float = l.lama_terbang * float(n + 1) / float(Config.GARIS_BIDIK_SAMPEL)
						lengkung += KoranLempar.layar_pada(l, t0).distance_to(KoranLempar.layar_pada(l, t1))
					if lengkung < 4.0 - 0.001 or KoranLempar.layar_pada(l, waktu[i - 1]).distance_to(KoranLempar.layar_pada(l, waktu[i])) < 2.0:
						jarak_cukup = false
			check(sampel, "%s: tiap titik adalah salah satu dari %d sampel merata posisi_pada" % [tag, Config.GARIS_BIDIK_SAMPEL + 1])
			check(jarak_cukup, "%s: titik berurutan berjarak >= 4 px sepanjang lengkung dan >= 2 px lurus di layar" % tag)
			var p: Vector3 = ThrowSolver.posisi_pada(l, 0.3)
			check(KoranLempar.layar_pada(l, 0.3) == Iso.dunia_tinggi_ke_layar(Vector2(p.x, p.y), p.z), "%s: layar_pada = proyeksi Iso posisi_pada" % tag)
	check(KoranLempar.waktu_titik_bidik(null, 4.0, 96).is_empty() and KoranLempar.waktu_titik_bidik(_lintasan_uji(0.5, LoperAnim.Sisi.DEKAT, 3.0), NAN, 96).is_empty() and KoranLempar.waktu_titik_bidik(_lintasan_uji(0.5, LoperAnim.Sisi.DEKAT, 3.0), 4.0, 0).is_empty(), "masukan tidak sah: tanpa titik")


func _test_pola_piksel() -> void:
	_judul.call("PolaPiksel: pola koran, elips, penanda, ikon; rasterisasi zona dan elips (D-5, D-10, DESIGN_SPEC 3.5-3.7)")
	var semua: Dictionary = {"ikon": PolaPiksel.IKON_KORAN, "elips biasa": PolaPiksel.ELIPS_BIASA, "elips sah": PolaPiksel.ELIPS_SAH, "elips tertutup": PolaPiksel.ELIPS_TERTUTUP, "centang": PolaPiksel.PENANDA_CENTANG, "setengah": PolaPiksel.PENANDA_SETENGAH, "bintang": PolaPiksel.PENANDA_BINTANG, "silang": PolaPiksel.PENANDA_SILANG, "bukan pelanggan": PolaPiksel.TANDA_BUKAN_PELANGGAN}
	for f: int in range(PolaPiksel.KORAN_PUTAR.size()):
		semua["koran %d" % f] = PolaPiksel.pola_koran(f)
	for nama: String in semua:
		var pola: Array[String] = []
		pola.assign(semua[nama])
		var persegi: bool = not pola.is_empty()
		var huruf_sah: bool = true
		for baris: String in pola:
			if baris.length() != pola[0].length():
				persegi = false
			for c: String in baris:
				if not ".otsw".contains(c):
					huruf_sah = false
		check(persegi and huruf_sah, "pola %s: semua baris sama panjang, hanya huruf peran . o t s w" % nama)
	check(PolaPiksel.KORAN_PUTAR.size() == 4, "koran berputar 4 langkah")
	var bentuk_koran: Array = []
	for f: int in range(4):
		check(PolaPiksel.ukuran(PolaPiksel.pola_koran(f)) == Vector2i(8, 6), "koran frame %d: 8x6 (ART_DIRECTION 6.2)" % f)
		bentuk_koran.append(_bentuk(PolaPiksel.pola_koran(f)))
	check(_semua_beda(bentuk_koran), "empat frame koran berbeda bentuk (berputar)")
	check(PolaPiksel.pola_koran(5) == PolaPiksel.pola_koran(1) and PolaPiksel.pola_koran(-1) == PolaPiksel.pola_koran(3), "frame di luar jangkauan memutar (posmod)")
	check(PolaPiksel.ukuran(PolaPiksel.ELIPS_BIASA) == Vector2i(10, 5) and PolaPiksel.ukuran(PolaPiksel.ELIPS_SAH) == Vector2i(10, 5), "elips pendaratan 10x5 (DESIGN_SPEC 3.7)")
	check(_bentuk(PolaPiksel.ELIPS_BIASA) != _bentuk(PolaPiksel.ELIPS_SAH) and _jumlah_isi(PolaPiksel.ELIPS_SAH) > _jumlah_isi(PolaPiksel.ELIPS_BIASA) + 10, "elips sah TERISI (bentuk berbeda dari cincin biasa, bukan hanya warna)")
	check(PolaPiksel.ukuran(PolaPiksel.ELIPS_TERTUTUP) == Vector2i(10, 5) and _semua_beda([_bentuk(PolaPiksel.ELIPS_BIASA), _bentuk(PolaPiksel.ELIPS_SAH), _bentuk(PolaPiksel.ELIPS_TERTUTUP)]) and _jumlah_isi(PolaPiksel.ELIPS_TERTUTUP) < _jumlah_isi(PolaPiksel.ELIPS_BIASA), "elips tertutup rumah 10x5, cincin putus-putus: bentuk berbeda dari elips biasa dan sah (QA-004)")
	check(PolaPiksel.ukuran(PolaPiksel.IKON_KORAN) == Vector2i(12, 12), "ikon koran HUD 12x12 (DESIGN_SPEC 3.5)")
	var penanda: Array = []
	for p: ZonaSasaran.Penanda in [ZonaSasaran.Penanda.SILANG, ZonaSasaran.Penanda.CENTANG, ZonaSasaran.Penanda.SETENGAH, ZonaSasaran.Penanda.BINTANG]:
		penanda.append(_bentuk(PolaPiksel.pola_penanda(p)))
	check(_semua_beda(penanda), "empat bentuk penanda (silang, centang, setengah, bintang) berbeda bentuk satu sama lain")
	for hasil: ZonaSasaran.Hasil in ZonaSasaran.Hasil.values():
		for bonus: bool in [false, true]:
			var bentuk: Array = _bentuk(PolaPiksel.pola_penanda(ZonaSasaran.penanda_hasil(hasil, bonus)))
			var sah: bool = ZonaSasaran.sah(ZonaSasaran.status_antaran(hasil, bonus))
			check(sah == (bentuk != _bentuk(PolaPiksel.PENANDA_SILANG)), "hasil %s (bonus %s): bentuk penanda %s silang meleset" % [ZonaSasaran.Hasil.keys()[hasil], bonus, "berbeda dari" if sah else "sama dengan"])
	# Elips terisi: tiap baris ada, simetris, di dalam kotak.
	for ukuran: Vector2i in [Vector2i(8, 4), Vector2i(4, 2), Vector2i(5, 2), Vector2i(10, 5)]:
		var rentang: Array[Vector3i] = PolaPiksel.rentang_elips(ukuran.x, ukuran.y)
		var baik: bool = rentang.size() == ukuran.y
		for r: Vector3i in rentang:
			if r.y < 0 or r.z > ukuran.x or r.z <= r.y or r.y != ukuran.x - r.z:
				baik = false
		check(baik, "elips %s: satu rentang per baris, simetris, di dalam kotak" % ukuran)
	check(PolaPiksel.rentang_elips(0, 4).is_empty(), "elips ukuran 0 kosong")
	# Zona iso: luas piksel = luas belah ketupat (64x32 per ubin persegi = 1024 px), tepi bagian dari isi, sudut bulat.
	for persegi: Rect2 in [Rect2(-3.0, -0.5, 1.0, 3.0), Rect2(1.375, 0.875, 0.5, 0.5), Rect2(-3.0, 1.5, 0.25, 0.75)]:
		var isi: Array[Vector3i] = PolaPiksel.rentang_poligon(PolaPiksel.sudut_zona(persegi))
		var luas: int = 0
		for r: Vector3i in isi:
			luas += r.z - r.y
		var harapan: float = persegi.size.x * persegi.size.y * 1024.0
		check(absf(float(luas) - harapan) <= harapan * 0.05 + 4.0, "zona %s: %d piksel, luas belah ketupat %s" % [persegi, luas, harapan])
		var tepi: Array[Vector3i] = PolaPiksel.rentang_tepi(isi)
		var bagian: bool = true
		var luas_tepi: int = 0
		for t: Vector3i in tepi:
			luas_tepi += t.z - t.y
			var ada: bool = false
			for r: Vector3i in isi:
				if r.x == t.x and t.y >= r.y and t.z <= r.z:
					ada = true
			if not ada:
				bagian = false
		check(bagian and luas_tepi > 0 and luas_tepi < luas, "zona %s: tepi (%d px) bagian dari isi dan lebih kecil" % [persegi, luas_tepi])
	check(PolaPiksel.rentang_poligon(PackedVector2Array([Vector2.ZERO, Vector2.ONE])).is_empty(), "poligon kurang dari 3 sudut kosong")
	check(PolaPiksel.rentang_huruf([".ww.o", "wwwww"], "w") == [Vector3i(0, 1, 3), Vector3i(1, 0, 5)], "rentang huruf: deret huruf berurutan per baris")


## QA-004 (iterasi 2): titik yang tertutup kotak rumah dari sudut kamera iso 2:1 (di dalam atau di belakang kotaknya), elips "tertutup".
func _test_tertutup_rumah() -> void:
	_judul.call("Titik tertutup rumah graybox dari sudut kamera dan bentuk elips (QA-004, D-5)")
	# Tapak uji: lateral -5..-3 (kaki fasad -3), maju 0..3, tinggi 1,5 ubin.
	var tapak: Rect2 = Rect2(-5.0, 0.0, 2.0, 3.0)
	var kasus: Array = [
		[-4.0, 1.5, 0.0, true, "di dalam tapak di tanah"],
		[-4.0, 1.5, 1.0, true, "di dalam kotak setinggi 1 ubin"],
		[-4.0, 1.5, 1.6, false, "di atas atap (lebih tinggi dari kotak)"],
		[-2.5, 1.5, 0.0, false, "di depan fasad (halaman)"],
		[-3.0, 1.5, 0.0, false, "tepat di kaki fasad (tepi tidak tertutup)"],
		[-5.5, 1.0, 0.0, true, "di belakang rumah, masih di balik kotak (d 0,5..1)"],
		[-5.5, 1.0, 1.2, false, "di belakang rumah tetapi lebih tinggi dari garis atap dari kamera"],
		[-7.0, 1.0, 0.0, false, "jauh di belakang rumah (lebih dari tinggi kotak): terlihat"],
		[-5.5, -0.2, 0.0, false, "di belakang dan sebelum rumah: terlihat"],
		[-5.5, 3.6, 0.0, true, "di belakang dan sesudah tapak, masih di balik kotak (d 0,6..1,5)"],
		[-4.0, 3.2, 0.0, true, "sesudah tapak (sisi rumah yang membelakangi kamera): tertutup"],
		[-4.0, -0.2, 0.0, false, "sebelum tapak (sisi samping rumah yang menghadap kamera): terlihat"],
	]
	for k: Array in kasus:
		check(ZonaSasaran.tertutup_kotak(_titik(k[0], k[1]), k[2], tapak, 1.5) == k[3], "%s (lateral %s, maju %s, tinggi %s): tertutup %s" % [k[4], k[0], k[1], k[2], k[3]])
	check(not ZonaSasaran.tertutup_kotak(Vector2(NAN, 0.0), 0.0, tapak, 1.5) and not ZonaSasaran.tertutup_kotak(_titik(-4.0, 1.5), INF, tapak, 1.5) and not ZonaSasaran.tertutup_rumah_jalan_uji(Vector2(INF, 0.0), 0.0), "masukan tidak hingga: tidak tertutup")
	# Proyeksi: titik yang dinyatakan tertutup memang jatuh di titik layar yang sama dengan titik kotak di depannya.
	var p: Vector2 = _titik(-5.5, 1.0)
	var d: float = 0.75
	check(Iso.dunia_tinggi_ke_layar(p, 0.0).is_equal_approx(Iso.dunia_tinggi_ke_layar(p + Vector2(d, d), d)), "dasar aturan: (x, y, z) dan (x + d, y + d, z + d) jatuh di titik layar sama (Iso)")
	# Rumah jalan uji: tapak sama dengan letak graybox ObjekDaur dan ukuran aset.
	check(ZonaSasaran.tapak_rumah_jalan_uji(0) == Rect2(-5.0, -0.5, 2.0, 3.0) and ZonaSasaran.tapak_rumah_jalan_uji(2) == Rect2(-5.0, 7.5, 2.0, 3.0), "tapak rumah jalan uji: lateral -5..-3, maju -0,5..2,5 + 4 per kavling")
	var png: PackedByteArray = FileAccess.get_file_as_bytes("res://assets/sprites/_placeholder/house_graybox_kotak.png")
	var lebar: int = (png[16] << 24) | (png[17] << 16) | (png[18] << 8) | png[19]
	var tinggi: int = (png[20] << 24) | (png[21] << 16) | (png[22] << 8) | png[23]
	var ubin: float = float(Config.JALAN_UJI_RUMAH_PANJANG_UBIN + Config.JALAN_UJI_RUMAH_DALAM_UBIN)
	check(lebar == roundi(ubin * 32.0) + 1 and tinggi == roundi(ubin * 16.0 + Config.JALAN_UJI_RUMAH_TINGGI_UBIN * Config.UBIN_UNIT_DUNIA) + 1, "ukuran kotak rumah di Config (3 x 2 x 1,5 ubin) = ukuran house_graybox_kotak.png %dx%d" % [lebar, tinggi])
	# Zona sasaran di kaki fasad tidak pernah tertutup (tetap terbaca); titik di dalam rumah tertutup.
	var zona_terbuka: bool = true
	for indeks: int in range(-2, 4):
		for zona: ZonaSasaran.Zona in ZonaSasaran.zona_jalan_uji(indeks):
			var r: Rect2 = zona.persegi
			for t: Vector2 in [r.position, r.get_center(), r.end - Vector2(0.001, 0.001), Vector2(r.position.x, r.end.y - 0.001)]:
				if ZonaSasaran.tertutup_rumah_jalan_uji(_titik(t.x, t.y), 0.0):
					zona_terbuka = false
	check(zona_terbuka, "semua zona sasaran jalan uji (kotak surat, halaman, teras, jendela, sisi dekat) tidak tertutup rumah")
	check(ZonaSasaran.tertutup_rumah_jalan_uji(_titik(-4.0, 9.0), 0.0) and ZonaSasaran.tertutup_rumah_jalan_uji(_titik(-4.0, 11.0), 0.0) and not ZonaSasaran.tertutup_rumah_jalan_uji(_titik(-3.2, 7.2), 0.0) and ZonaSasaran.tertutup_rumah_jalan_uji(_titik(-4.0, 3.7), 0.0), "jalan uji: di dalam rumah kavling 2 dan kavling 1 (maju 3,7, dekat batas kavling) dan di celah di baliknya tertutup; celah dekat kaki fasad (lateral -3,2, maju 7,2) terlihat")
	# Bentuk elips lintasan.
	var masuk_rumah: ThrowSolver.Lintasan = ThrowSolver.hitung(ThrowSolver.swipe_maks_px(780.0), 780.0, Iso.ARAH_SEBERANG, _titik(0.0, 7.0), 0.0, 0.0, 0.0)
	var ke_teras: ThrowSolver.Lintasan = null
	var ke_jalan: ThrowSolver.Lintasan = ThrowSolver.hitung(ThrowSolver.swipe_min_px(780.0), 780.0, Iso.ARAH_DEKAT, _titik(-1.0, 3.5), 0.0, 0.0, 0.0)
	for i: int in range(200):
		var l: ThrowSolver.Lintasan = ThrowSolver.hitung(ThrowSolver.swipe_min_px(780.0) + float(i), 780.0, Iso.ARAH_SEBERANG, _titik(0.0, 4.0), 0.0, 0.0, 0.0)
		if l != null and KoranLempar.hasil_mendarat(l) == ZonaSasaran.Hasil.TERAS:
			ke_teras = l
			break
	check(ZonaSasaran.tertutup_rumah_jalan_uji(masuk_rumah.titik_mendarat, 0.0) and KoranLempar.bentuk_elips(masuk_rumah, false) == KoranLempar.Elips.TERTUTUP and KoranLempar.hasil_mendarat(masuk_rumah) == ZonaSasaran.Hasil.MELESET, "lempar maks ke seberang dari tengah jalan mendarat di dalam rumah: meleset, elips TERTUTUP %s" % masuk_rumah.titik_mendarat)
	check(ke_teras != null and KoranLempar.bentuk_elips(ke_teras, false) == KoranLempar.Elips.SAH, "elips ke teras: SAH (sah menang atas aturan tertutup)")
	check(KoranLempar.bentuk_elips(ke_jalan, false) == KoranLempar.Elips.BIASA and KoranLempar.hasil_mendarat(ke_jalan) == ZonaSasaran.Hasil.MELESET, "meleset di tanah terbuka (jalan): elips BIASA")
	check(KoranLempar.bentuk_elips(null, false) == KoranLempar.Elips.BIASA and not KoranLempar.tertutup_pada(null, 0.0), "lintasan null: elips BIASA, tidak tertutup")
	var ada_titik_tertutup: bool = false
	var titik_awal_terbuka: bool = not KoranLempar.tertutup_pada(masuk_rumah, 0.0)
	for t: float in KoranLempar.waktu_titik_bidik(masuk_rumah, 4.0, Config.GARIS_BIDIK_SAMPEL):
		if KoranLempar.tertutup_pada(masuk_rumah, t):
			ada_titik_tertutup = true
	check(ada_titik_tertutup and titik_awal_terbuka and KoranLempar.tertutup_pada(masuk_rumah, masuk_rumah.lama_terbang), "titik garis bidik: awal di tangan terlihat, ujung di dalam rumah tertutup")
	var ada_tinggi_terlihat: bool = false
	for i: int in range(97):
		var t: float = masuk_rumah.lama_terbang * float(i) / 96.0
		var q: Vector3 = ThrowSolver.posisi_pada(masuk_rumah, t)
		if ZonaSasaran.tertutup_rumah_jalan_uji(Vector2(q.x, q.y), 0.0) and not KoranLempar.tertutup_pada(masuk_rumah, t):
			ada_tinggi_terlihat = true
	check(ada_tinggi_terlihat, "titik garis bidik yang tinggi (di atas garis atap dari kamera) tetap terlihat walau titik tanahnya tertutup: tinggi koran ikut dihitung")


## Luminansi relatif WCAG warna sRGB.
func _luminansi(c: Color) -> float:
	var hasil: float = 0.0
	var bobot: Array[float] = [0.2126, 0.7152, 0.0722]
	var kanal: Array[float] = [c.r, c.g, c.b]
	for i: int in range(3):
		var v: float = kanal[i]
		var linear: float = v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)
		hasil += bobot[i] * linear
	return hasil


## QA-007 (iterasi 2): bayangan koran (`OUTLINE` alpha `KORAN_BAYANGAN_ALPHA`, dicampur di ruang sRGB seperti kanvas 2D) di atas warna
## tengah ubin graybox aspal, trotoar, dan rumput (dibaca dari PNG) punya kontras WCAG >= 3:1 (batas komponen non-teks). Keterbacaan di
## layar HP tetap NEEDS-MANUAL.
func _test_bayangan_kontras() -> void:
	_judul.call("Kontras bayangan koran di atas ubin graybox (QA-007)")
	for nama: String in ["aspal", "trotoar", "rumput"]:
		var gambar: Image = Image.new()
		var galat: int = gambar.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/sprites/_placeholder/tile_graybox_%s.png" % nama))
		check(galat == OK and gambar.get_width() > 0, "ubin graybox %s terbaca" % nama)
		if galat != OK:
			continue
		var dasar: Color = gambar.get_pixel(gambar.get_width() / 2, gambar.get_height() / 2)
		var bayangan: Color = dasar.lerp(Palette.OUTLINE, Config.KORAN_BAYANGAN_ALPHA)
		var terang: float = maxf(_luminansi(dasar), _luminansi(bayangan))
		var gelap: float = minf(_luminansi(dasar), _luminansi(bayangan))
		var rasio: float = (terang + 0.05) / (gelap + 0.05)
		check(dasar.a == 1.0 and rasio >= 3.0, "bayangan koran di atas %s %s: kontras %.2f:1 (>= 3:1)" % [nama, dasar.to_html(false), rasio])


## Himpunan piksel tidak kosong pola (bentuk, tanpa warna).
func _bentuk(pola: Array[String]) -> Array:
	var hasil: Array = []
	for y: int in range(pola.size()):
		for x: int in range(pola[y].length()):
			if pola[y][x] != ".":
				hasil.append(Vector2i(x, y))
	return hasil


func _jumlah_isi(pola: Array[String]) -> int:
	return _bentuk(pola).size()


func _semua_beda(daftar: Array) -> bool:
	for i: int in range(daftar.size()):
		for j: int in range(i + 1, daftar.size()):
			if daftar[i] == daftar[j]:
				return false
	return true
