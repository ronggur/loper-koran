class_name TesLempar
extends RefCounted
## Tes logika murni run fase2a-lemparan bagian 1a: `ThrowSolver` (AC-2 rumus D-2, AC-3 lengkung D-3, AC-4 prediksi = hasil D-4,
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
	_test_sisa_koran()
	_test_jeda_antar_lempar()
	_test_isi_ulang()


# --- Pembantu ---

func _dekat(a: float, b: float, tol: float = TOL) -> bool:
	return absf(a - b) <= tol


func _dekat_v(a: Vector2, b: Vector2, tol: float = TOL) -> bool:
	return absf(a.x - b.x) <= tol and absf(a.y - b.y) <= tol


## Panjang swipe untuk kekuatan u di lebar `lebar` (min + u x (maks - min)).
func _panjang(u: float, lebar: float) -> float:
	return ThrowSolver.swipe_min_px(lebar) + u * (ThrowSolver.swipe_maks_px(lebar) - ThrowSolver.swipe_min_px(lebar))


func _jeda_lepas() -> float:
	return LemparWaktu.waktu_lepas(FPS_LEMPAR, FRAME_LEMPAR, Config.LEMPAR_FRAME_LEPAS)


func _sama(a: ThrowSolver.Lintasan, b: ThrowSolver.Lintasan) -> bool:
	return a.sisi == b.sisi and a.kekuatan == b.kekuatan and a.titik_lepas == b.titik_lepas and a.titik_mendarat == b.titik_mendarat and a.lama_terbang == b.lama_terbang and a.tinggi_puncak == b.tinggi_puncak and a.lengkung_a == b.lengkung_a and a.lengkung_b == b.lengkung_b and a.jeda_lepas == b.jeda_lepas


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
	_judul.call("Panjang swipe = |dx| terhadap lebar viewport: min 6%, maks 35%, inklusif di min (AC-2, D-2)")
	for lebar: float in LEBAR:
		var bawah: float = ThrowSolver.swipe_min_px(lebar)
		var atas: float = ThrowSolver.swipe_maks_px(lebar)
		check(_dekat(bawah, lebar * 0.06) and _dekat(atas, lebar * 0.35), "lebar %s: min %s px, maks %s px (ikut lebar)" % [lebar, bawah, atas])
		check(ThrowSolver.kekuatan(bawah, lebar) == 0.0, "lebar %s: tepat min = u 0 (melempar, inklusif)" % lebar)
		check(ThrowSolver.kekuatan(bawah - 0.01, lebar) == -1.0 and not ThrowSolver.cukup_panjang(bawah - 0.01, lebar), "lebar %s: 0,01 px di bawah min tidak melempar" % lebar)
		check(_dekat(ThrowSolver.kekuatan((bawah + atas) / 2, lebar), 0.5), "lebar %s: tengah min-maks = u 0,5" % lebar)
		check(ThrowSolver.kekuatan(atas, lebar) == 1.0 and ThrowSolver.kekuatan(atas * 3, lebar) == 1.0, "lebar %s: tepat maks dan 3x maks = u 1 (dijepit)" % lebar)
		# Presisi tunggal: |dx| dari Vector2 tepat di min tetap melempar.
		var dari_vektor: float = absf((Vector2(400.0, 200.0) + Vector2(bawah, 0.0)).x - 400.0)
		check(ThrowSolver.cukup_panjang(dari_vektor, lebar), "lebar %s: |dx| dari Vector2 (presisi tunggal, %s) di min tetap melempar" % [lebar, dari_vektor])
	# Swipe yang sama berbeda kekuatan di lebar berbeda (min/maks ikut lebar).
	check(ThrowSolver.cukup_panjang(40.0, 640.0) and not ThrowSolver.cukup_panjang(40.0, 780.0), "40 px melempar di 640 (min 38,4) tetapi tidak di 780 (min 46,8)")
	check(ThrowSolver.kekuatan(224.0, 640.0) == 1.0 and ThrowSolver.kekuatan(224.0, 800.0) < 1.0, "224 px = maks di 640 (35%), belum maks di 800 (280)")
	for lebar_salah: float in [0.0, -640.0, NAN, INF]:
		check(not ThrowSolver.cukup_panjang(100.0, lebar_salah) and ThrowSolver.kekuatan(100.0, lebar_salah) == -1.0, "lebar viewport tidak sah (%s): tidak melempar" % lebar_salah)
	for panjang_salah: float in [NAN, INF, -60.0]:
		check(ThrowSolver.kekuatan(panjang_salah, 780.0) == -1.0, "panjang swipe tidak sah (%s): tidak melempar" % panjang_salah)


# --- Rumus D-2 di empat kecepatan, kedua sisi ---

func _test_rumus() -> void:
	_judul.call("ThrowSolver: jarak, lama terbang, puncak, warisan maju, tanpa warisan lateral (AC-2, D-2)")
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
					var l: ThrowSolver.Lintasan = ThrowSolver.hitung(_panjang(u, lebar), lebar, sisi, posisi, v, 0.0, 0.0)
					if l == null:
						check(false, "%s u %s: lintasan ada" % [tag, u])
						continue
					var ok_angka: bool = _dekat(l.kekuatan, u) and _dekat(l.jarak_samping, t[1]) and _dekat(l.lama_terbang, t[2]) and _dekat(l.tinggi_puncak, t[3])
					check(ok_angka, "%s u %s: jarak %s, lama %s, puncak %s (dapat %s, %s, %s)" % [tag, u, t[1], t[2], t[3], l.jarak_samping, l.lama_terbang, l.tinggi_puncak])
					var lateral: float = l.titik_mendarat.x - l.titik_lepas.x
					var maju: float = -(l.titik_mendarat.y - l.titik_lepas.y)
					check(_dekat(lateral, tanda * t[1]), "%s u %s: geser lateral %s ubin ke arah sisi (tanda benar), dapat %s" % [tag, u, tanda * t[1], lateral])
					check(_dekat(maju, v * t[2]) and _dekat(l.geser_maju, v * t[2]), "%s u %s: geser maju = kecepatan x lama terbang = %s, dapat %s" % [tag, u, v * t[2], maju])
				# Di atas maks dijepit = tepat maks.
				var lebih: ThrowSolver.Lintasan = ThrowSolver.hitung(ThrowSolver.swipe_maks_px(lebar) * 1.5, lebar, sisi, posisi, v, 0.0, 0.0)
				check(lebih != null and _dekat(lebih.jarak_samping, 5.0) and _dekat(lebih.lama_terbang, 0.75) and _dekat(lebih.tinggi_puncak, 1.6), "%s: swipe 1,5x maks dijepit ke 5,0 / 0,75 / 1,6" % tag)
				# Di bawah min: tidak ada lintasan.
				check(ThrowSolver.hitung(ThrowSolver.swipe_min_px(lebar) - 0.5, lebar, sisi, posisi, v, 0.0, 0.0) == null, "%s: swipe di bawah min = tidak ada lintasan" % tag)
	# Tanpa warisan lateral selama terbang: kecepatan lateral hanya menggeser titik lepas (jeda lepas), bukan selama terbang.
	var tanpa: ThrowSolver.Lintasan = ThrowSolver.hitung(_panjang(0.5, 780.0), 780.0, LoperAnim.Sisi.DEKAT, Vector2(0.0, 0.0), 4.5, 0.0, 0.0)
	var dengan: ThrowSolver.Lintasan = ThrowSolver.hitung(_panjang(0.5, 780.0), 780.0, LoperAnim.Sisi.DEKAT, Vector2(0.0, 0.0), 4.5, 3.0, 0.0)
	check(tanpa.titik_mendarat == dengan.titik_mendarat, "jeda lepas 0: kecepatan lateral 3 u/d tidak mengubah titik mendarat (tanpa warisan lateral), %s lawan %s" % [tanpa.titik_mendarat, dengan.titik_mendarat])
	var jeda: float = _jeda_lepas()
	var dengan_jeda: ThrowSolver.Lintasan = ThrowSolver.hitung(_panjang(0.5, 780.0), 780.0, LoperAnim.Sisi.SEBERANG, Vector2(0.0, 0.0), 4.5, -3.0, jeda)
	check(_dekat(dengan_jeda.titik_mendarat.x - dengan_jeda.titik_lepas.x, -3.25), "dengan jeda lepas: geser lateral selama terbang tetap tepat jarak samping (-3,25), dapat %s" % (dengan_jeda.titik_mendarat.x - dengan_jeda.titik_lepas.x))
	# Sisi hanya seberang / dekat.
	check(ThrowSolver.hitung(100.0, 780.0, LoperAnim.Sisi.TIDAK_ADA, Vector2.ZERO, 3.0, 0.0, 0.0) == null and ThrowSolver.hitung(100.0, 780.0, 7 as LoperAnim.Sisi, Vector2.ZERO, 3.0, 0.0, 0.0) == null, "sisi TIDAK_ADA atau di luar enum: tidak ada lintasan")
	check(ThrowSolver.arah_sisi(LoperAnim.Sisi.SEBERANG) == Iso.ARAH_SEBERANG and ThrowSolver.arah_sisi(LoperAnim.Sisi.DEKAT) == Iso.ARAH_DEKAT and ThrowSolver.arah_sisi(LoperAnim.Sisi.TIDAK_ADA) == Vector2.ZERO, "arah sisi dari Iso.ARAH_SEBERANG / ARAH_DEKAT")
	# dari_swipe = sisi_dari_swipe + hitung(|dx|).
	var awal: Vector2 = Vector2(600.0, 200.0)
	var akhir: Vector2 = Vector2(480.0, 230.0)
	var a: ThrowSolver.Lintasan = ThrowSolver.dari_swipe(awal, akhir, 780.0, posisi, 3.0, 0.5, jeda)
	var b: ThrowSolver.Lintasan = ThrowSolver.hitung(120.0, 780.0, LoperAnim.Sisi.SEBERANG, posisi, 3.0, 0.5, jeda)
	check(a != null and b != null and _sama(a, b), "dari_swipe (kiri layar, |dx| 120) = hitung(120, seberang)")
	check(ThrowSolver.dari_swipe(awal, Vector2(600.0, 100.0), 780.0, posisi, 3.0, 0.0, jeda) == null and ThrowSolver.dari_swipe(awal, awal + Vector2(40.0, 0.0), 780.0, posisi, 3.0, 0.0, jeda) == null, "dari_swipe: tegak dominan atau |dx| di bawah min = null")


func _test_masukan_aneh_dan_murni() -> void:
	_judul.call("ThrowSolver: masukan NaN, tak hingga, negatif aman; murni (AC-2)")
	var p: float = _panjang(0.5, 780.0)
	var nol: ThrowSolver.Lintasan = ThrowSolver.hitung(p, 780.0, LoperAnim.Sisi.DEKAT, Vector2.ZERO, 0.0, 0.0, 0.0)
	for v: float in [NAN, INF, -INF, -3.0]:
		var l: ThrowSolver.Lintasan = ThrowSolver.hitung(p, 780.0, LoperAnim.Sisi.DEKAT, Vector2.ZERO, v, 0.0, 0.0)
		check(l != null and l.geser_maju == 0.0 and l.titik_mendarat == nol.titik_mendarat, "kecepatan maju %s dianggap 0 (tanpa geser maju)" % v)
	for vl: float in [NAN, INF, -INF]:
		var l: ThrowSolver.Lintasan = ThrowSolver.hitung(p, 780.0, LoperAnim.Sisi.DEKAT, Vector2.ZERO, 0.0, vl, 0.5)
		check(l != null and l.titik_lepas == Vector2.ZERO, "kecepatan lateral %s dianggap 0" % vl)
	for j: float in [NAN, INF, -0.5]:
		var l: ThrowSolver.Lintasan = ThrowSolver.hitung(p, 780.0, LoperAnim.Sisi.DEKAT, Vector2.ZERO, 6.0, 3.0, j)
		check(l != null and l.jeda_lepas == 0.0 and l.titik_lepas == Vector2.ZERO, "jeda lepas %s dianggap 0" % j)
	for pos: Vector2 in [Vector2(NAN, 0.0), Vector2(0.0, INF)]:
		check(ThrowSolver.hitung(p, 780.0, LoperAnim.Sisi.DEKAT, pos, 3.0, 0.0, 0.0) == null, "posisi sepeda tidak hingga (%s): tidak ada lintasan" % pos)
	# Murni: masukan sama = hasil sama; masukan Vector2 tidak berubah.
	var posisi: Vector2 = Vector2(-0.5, -12.25)
	var salinan: Vector2 = posisi
	var x: ThrowSolver.Lintasan = ThrowSolver.hitung(p, 780.0, LoperAnim.Sisi.SEBERANG, posisi, 4.5, -1.0, 0.1667)
	var y: ThrowSolver.Lintasan = ThrowSolver.hitung(p, 780.0, LoperAnim.Sisi.SEBERANG, posisi, 4.5, -1.0, 0.1667)
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
	var l: ThrowSolver.Lintasan = ThrowSolver.hitung(_panjang(0.0, 640.0), 640.0, LoperAnim.Sisi.DEKAT, Vector2(0.2, -10.0), 6.0, 3.0, jeda)
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
		var l: ThrowSolver.Lintasan = ThrowSolver.hitung(_panjang(u, 780.0), 780.0, LoperAnim.Sisi.SEBERANG, Vector2(0.3, -5.0), 4.5, 0.0, 0.0)
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
			var ulang: ThrowSolver.Lintasan = ThrowSolver.hitung(150.0, 780.0, bidik.sisi, Vector2(keadaan_lepas.lateral_ubin, -jarak_lepas), keadaan_lepas.kecepatan_ud, 0.0, 0.0)
			check(ulang.titik_mendarat.distance_to(bidik.titik_mendarat) > 0.05, "%s (kontrol): lintasan yang dihitung ulang saat frame lepas dari keadaan baru meleset %.3f ubin dari prediksi" % [tag, ulang.titik_mendarat.distance_to(bidik.titik_mendarat)])


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
	_judul.call("Zona sasaran: tiap jenis, tepi inklusif/eksklusif, meleset, bukan pelanggan, sisi salah (AC-5, D-6)")
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
	check(ZonaSasaran.klasifikasi(_titik(-1.75, 0.25), S, daftar) == ZonaSasaran.Hasil.KOTAK_SURAT, "titik di kotak surat = KOTAK_SURAT")
	check(ZonaSasaran.klasifikasi(_titik(-2.5, 1.5), S, daftar) == ZonaSasaran.Hasil.TERAS, "titik di teras = TERAS")
	check(ZonaSasaran.klasifikasi(_titik(-2.5, 3.5), S, daftar) == ZonaSasaran.Hasil.HALAMAN, "titik di halaman = HALAMAN")
	check(ZonaSasaran.klasifikasi(_titik(-2.9, 5.5), S, daftar) == ZonaSasaran.Hasil.JENDELA, "titik di strip jendela = JENDELA")
	check(ZonaSasaran.klasifikasi(_titik(-2.5, 7.5), S, daftar) == ZonaSasaran.Hasil.BUKAN_PELANGGAN, "teras rumah bukan pelanggan = BUKAN_PELANGGAN")
	check(ZonaSasaran.klasifikasi(_titik(2.5, 0.5), D, daftar) == ZonaSasaran.Hasil.HALAMAN, "halaman sisi dekat = HALAMAN untuk lemparan ke dekat")
	check(ZonaSasaran.klasifikasi(_titik(-2.5, 2.5), S, daftar) == ZonaSasaran.Hasil.MELESET and ZonaSasaran.klasifikasi(_titik(0.0, 0.0), S, daftar) == ZonaSasaran.Hasil.MELESET, "titik di luar semua zona (celah, jalan) = MELESET")
	check(ZonaSasaran.klasifikasi(_titik(-1.75, 0.25), D, daftar) == ZonaSasaran.Hasil.MELESET and ZonaSasaran.klasifikasi(_titik(2.5, 0.5), S, daftar) == ZonaSasaran.Hasil.MELESET, "sisi salah (zona seberang untuk lemparan ke dekat, dan sebaliknya) = MELESET")
	check(ZonaSasaran.klasifikasi(Vector2(NAN, 0.0), S, daftar) == ZonaSasaran.Hasil.MELESET and ZonaSasaran.klasifikasi(Vector2(-1.75, INF), S, daftar) == ZonaSasaran.Hasil.MELESET, "titik tidak hingga = MELESET")
	check(ZonaSasaran.klasifikasi(_titik(-1.75, 0.25), S, [] as Array[ZonaSasaran.Zona]) == ZonaSasaran.Hasil.MELESET, "tanpa zona = MELESET")
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
	check(ZonaSasaran.zona_kena(_titik(-1.75, 0.25), S, daftar) == kotak and ZonaSasaran.zona_kena(_titik(0.0, 0.0), S, daftar) == null, "zona_kena mengembalikan zona yang menang atau null")
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
		check(ZonaSasaran.klasifikasi(p, S, daftar) == ZonaSasaran.Hasil.KOTAK_SURAT, "empat zona tumpang tindih (urutan %s) = KOTAK_SURAT" % [u.map(func(z: ZonaSasaran.Zona) -> int: return int(z.jenis))])
	var tiga: Array[ZonaSasaran.Zona] = [h, t, j]
	check(ZonaSasaran.klasifikasi(p, S, tiga) == ZonaSasaran.Hasil.JENDELA, "tanpa kotak surat: JENDELA menang atas teras dan halaman")
	var dua: Array[ZonaSasaran.Zona] = [h, t]
	var dua_balik: Array[ZonaSasaran.Zona] = [t, h]
	check(ZonaSasaran.klasifikasi(p, S, dua) == ZonaSasaran.Hasil.TERAS and ZonaSasaran.klasifikasi(p, S, dua_balik) == ZonaSasaran.Hasil.TERAS, "teras menang atas halaman, kedua urutan")
	var jt: Array[ZonaSasaran.Zona] = [t, j]
	check(ZonaSasaran.klasifikasi(p, S, jt) == ZonaSasaran.Hasil.JENDELA, "jendela menang atas teras")
	var kj: Array[ZonaSasaran.Zona] = [j, k]
	check(ZonaSasaran.klasifikasi(p, S, kj) == ZonaSasaran.Hasil.KOTAK_SURAT, "kotak surat menang atas jendela")
	# Prioritas dulu, baru status pelanggan: kotak surat rumah bukan pelanggan di atas halaman pelanggan = bukan pelanggan.
	var kb: ZonaSasaran.Zona = _zona(-3.0, 0.0, 2.0, 2.0, ZonaSasaran.Jenis.KOTAK_SURAT, S, false)
	var campur: Array[ZonaSasaran.Zona] = [h, kb]
	check(ZonaSasaran.klasifikasi(p, S, campur) == ZonaSasaran.Hasil.BUKAN_PELANGGAN, "zona prioritas tertinggi milik rumah bukan pelanggan = BUKAN_PELANGGAN")
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
	check(ZonaSasaran.klasifikasi_jalan_uji(halaman_awal, LoperAnim.Sisi.SEBERANG) == ZonaSasaran.Hasil.HALAMAN, "titik halaman kavling 5 yang menjorok ke kavling 4 tetap HALAMAN")


## Keterjangkauan (AC-5): tiap zona di jalan uji bisa dikenai dari suatu posisi lateral di dalam jalan pada santai, cepat, dan ngebut
## dengan swipe di rentang min-maks. Titik mendarat dicari lewat ThrowSolver sungguhan; posisi maju sepeda digeser supaya titik itu jatuh
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
						var coba: ThrowSolver.Lintasan = ThrowSolver.hitung(_panjang(u, lebar), lebar, zona.sisi, Vector2(lateral, 0.0), v, 0.0, jeda)
						var jalan: Vector2 = ZonaSasaran.ke_jalan(coba.titik_mendarat)
						if jalan.x < zona.persegi.position.x or jalan.x >= zona.persegi.end.x:
							continue
						# Geser sepeda sepanjang jalan supaya titik mendarat di tengah zona (maju).
						var geser: float = zona.persegi.get_center().y - jalan.y
						var l: ThrowSolver.Lintasan = ThrowSolver.hitung(_panjang(u, lebar), lebar, zona.sisi, Vector2(lateral, -geser), v, 0.0, jeda)
						if ZonaSasaran.zona_kena(l.titik_mendarat, zona.sisi, ZonaSasaran.zona_jalan_uji_sekitar(ZonaSasaran.ke_jalan(l.titik_mendarat).y)) == null:
							continue
						if ZonaSasaran.klasifikasi_jalan_uji(l.titik_mendarat, zona.sisi) == diharapkan:
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
