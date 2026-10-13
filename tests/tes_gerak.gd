class_name TesGerak
extends RefCounted
## Tes logika murni run fase1a-gerak (AC-2 sampai AC-6, AC-8 bagian murni): `BikeMotion` (kecepatan, rem, stamina, lateral),
## pemilih pose dan `pedal_rate` di `LoperAnim`, `JedaSim`, dan busur rem `PikselLingkaran`. Tes `BikeDrive` run 0B yang masih
## relevan dipindah ke sini (lihat LOG run fase1a-gerak, bagian "Tes lama").
##
## Dipanggil dari `tests/run_tests.gd` (`TesGerak.new(check, judul).jalankan()`), memakai `check` milik runner. Tanpa node: waktu
## dan RNG adalah parameter (rule `testing`).

const DT: float = 1.0 / 60.0
const BERKAS_FRAMES: String = "res://assets/sprites/loper/loper_agen_frames.tres"
## Toleransi independensi pembagian dt untuk stamina (integral tepat per bagian), poin stamina.
const TOLERANSI_STAMINA_DT: float = 0.000001
## Toleransi independensi pembagian dt untuk kecepatan dan jarak (rumus tepat), u/d dan ubin.
const TOLERANSI_TEPAT: float = 0.000001

var _cek: Callable
var _judul: Callable


func _init(cek: Callable, judul: Callable) -> void:
	_cek = cek
	_judul = judul


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_test_config_gerak()
	_test_kecepatan()
	_test_masukan_aneh_dan_murni()
	_test_rem_ambang()
	_test_rem_tahan()
	_test_rem_berhenti_dan_lepas()
	_test_rem_diagonal()
	_test_independen_dt()
	_test_stamina_laju()
	_test_stamina_durasi()
	_test_lelah()
	_test_lateral()
	_test_pose()
	_test_pose_dari_langkah()
	_test_pedal_rate()
	_test_jeda_sim()
	_test_busur_rem()


# --- Pembantu ---

## Keadaan baru dengan kecepatan `v`, stamina `stamina`, lateral `lat`.
func _keadaan(v: float = 3.0, stamina: float = 100.0, lat: float = 0.0) -> BikeMotion.Keadaan:
	var k: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
	k.kecepatan_ud = v
	k.stamina = stamina
	k.lateral_ubin = lat
	return k


## Menjalankan `jumlah` langkah `dt` dengan stick tetap dari keadaan `k`. Mengembalikan hasil terakhir (jarak total di `maju_ubin`).
func _jalankan(k: BikeMotion.Keadaan, stick: Vector2, jumlah: int, dt: float = DT) -> BikeMotion.Hasil:
	var hasil: BikeMotion.Hasil = null
	var jarak: float = 0.0
	var keadaan: BikeMotion.Keadaan = k
	for i: int in range(jumlah):
		hasil = BikeMotion.langkah(keadaan, stick, dt)
		keadaan = hasil.keadaan
		jarak += hasil.maju_ubin
	if hasil != null:
		hasil.maju_ubin = jarak
	return hasil


## Detik sampai `syarat` (dipanggil dengan keadaan) pertama kali benar, langkah `dt`, paling lama `maks` detik; -1 bila tidak pernah.
func _waktu_sampai(k: BikeMotion.Keadaan, stick: Vector2, syarat: Callable, maks: float, dt: float = DT) -> float:
	var keadaan: BikeMotion.Keadaan = k
	var langkah: int = 0
	while float(langkah) * dt < maks:
		keadaan = BikeMotion.langkah(keadaan, stick, dt).keadaan
		langkah += 1
		if syarat.call(keadaan):
			return float(langkah) * dt
	return -1.0


func _nama(h: BikeMotion.Hasil) -> StringName:
	return LoperAnim.nama_animasi_pose(h.pose, h.tingkat_sprite, h.arah_sprite)


func _sama_keadaan(a: BikeMotion.Keadaan, b: BikeMotion.Keadaan) -> bool:
	return a.kecepatan_ud == b.kecepatan_ud and a.lateral_ubin == b.lateral_ubin and a.stamina == b.stamina and a.tahan_rem_detik == b.tahan_rem_detik and a.rem_aktif == b.rem_aktif and a.lelah == b.lelah


# --- Config ---

func _test_config_gerak() -> void:
	_judul.call("Config gerak Fase 1 (BALANCING 2-3, usulan)")
	check(Config.STAMINA_MAKS == 100.0 and Config.STAMINA_LAJU_MELUNCUR == 15.0, "stamina maksimum 100, meluncur +15/d (BALANCING 3)")
	check(Config.STAMINA_LAJU_SANTAI == 2.0 and Config.STAMINA_LAJU_CEPAT == -4.0 and Config.STAMINA_LAJU_NGEBUT == -12.0, "laju stamina santai +2, cepat -4, ngebut -12 per detik (BALANCING 3)")
	check(Config.STAMINA_PULIH_AMBANG == 30.0 and Config.HUD_STAMINA_AMBANG_RENDAH == 30.0, "lelah padam di 30, bar stamina FAIL di bawah 30 (BALANCING 3, DESIGN_SPEC 3.5)")
	check(Config.PEDAL_RATE_MAKS == 1.5 and Config.POSE_MELUNCUR_TOLERANSI_UD > 0.0 and Config.POSE_MELUNCUR_TOLERANSI_UD < 0.2, "PEDAL_RATE_MAKS 1,5 dan toleransi pose meluncur kecil (0 < t < 0,2 u/d)")
	check(Config.REM_AMBANG_TOLERANSI > 0.0 and Config.REM_AMBANG_TOLERANSI < 0.0001 and Config.REM_TAHAN_TOLERANSI_DETIK > 0.0 and Config.REM_TAHAN_TOLERANSI_DETIK < 0.0001, "toleransi rem hanya meredam derau presisi (< 1e-4)")
	check(Config.JALAN_LEBAR_UBIN == 2.0 and BikeMotion.batas_lateral_ubin() == 1.0, "lebar aspal 2 ubin, batas tepi jalan resmi +-1 ubin (D-4)")


# --- AC-2: kecepatan (dipindah dari BikeDrive run 0B, diperluas) ---

func _test_kecepatan() -> void:
	_judul.call("BikeMotion: kecepatan (AC-2)")
	check(BikeMotion.kecepatan_tujuan_ud(0.0) == 3.0, "stick netral -> tujuan 3,0 u/d (santai)")
	check(is_equal_approx(BikeMotion.kecepatan_tujuan_ud(0.5), 4.5), "stick atas 0,5 -> tujuan 4,5 u/d")
	check(BikeMotion.kecepatan_tujuan_ud(1.0) == 6.0, "stick atas penuh -> tujuan 6,0 u/d (ngebut)")
	check(BikeMotion.kecepatan_tujuan_ud(-1.0) == 1.5, "stick bawah penuh -> tujuan 1,5 u/d (sebelum rem)")
	check(is_equal_approx(BikeMotion.kecepatan_tujuan_ud(-0.5), 2.25), "stick bawah 0,5 -> tujuan 2,25 u/d")
	check(BikeMotion.kecepatan_tujuan_ud(7.0) == 6.0 and BikeMotion.kecepatan_tujuan_ud(-7.0) == 1.5 and BikeMotion.kecepatan_tujuan_ud(NAN) == 3.0, "tujuan dijepit untuk stick di luar -1..1 dan NaN = netral")
	check(BikeMotion.kecepatan_tujuan_ud(1.0, true) == 4.5 and BikeMotion.kecepatan_tujuan_ud(0.0, true) == 3.0 and BikeMotion.kecepatan_tujuan_ud(-1.0, true) == 1.5, "lelah menjepit tujuan ke cepat 4,5 (santai dan bawah tidak berubah)")
	var h: BikeMotion.Hasil = BikeMotion.langkah(_keadaan(), Vector2(0, 1), DT)
	check(is_equal_approx(h.keadaan.kecepatan_ud, 3.05), "akselerasi 3,0 u/d2: satu langkah 1/60 detik dari 3,0 = 3,05, dapat %s" % h.keadaan.kecepatan_ud)
	h = _jalankan(_keadaan(), Vector2(0, 1), 60)
	check(is_equal_approx(h.keadaan.kecepatan_ud, 6.0), "dari 3,0 ke ngebut butuh 1 detik, dapat %s" % h.keadaan.kecepatan_ud)
	check(absf(h.maju_ubin - 4.5) < 0.0001, "jarak 1 detik rampa 3,0 -> 6,0 = 4,5 ubin, dapat %s" % h.maju_ubin)
	h = _jalankan(_keadaan(), Vector2(0, 1), 180)
	check(h.keadaan.kecepatan_ud == 6.0, "kecepatan tidak melampaui ngebut walau stick tetap penuh (3 detik), dapat %s" % h.keadaan.kecepatan_ud)
	h = BikeMotion.langkah(_keadaan(6.0), Vector2.ZERO, 1.0)
	check(is_equal_approx(h.keadaan.kecepatan_ud, 4.0), "perlambatan 2,0 u/d2: dari 6,0 netral 1 detik = 4,0, dapat %s" % h.keadaan.kecepatan_ud)
	h = BikeMotion.langkah(_keadaan(6.0), Vector2.ZERO, 100.0)
	check(h.keadaan.kecepatan_ud == 3.0, "dt besar tidak melewati tujuan (turun): 6,0 -> tepat 3,0, dapat %s" % h.keadaan.kecepatan_ud)
	h = BikeMotion.langkah(_keadaan(), Vector2(0, 1), 100.0)
	check(h.keadaan.kecepatan_ud == 6.0, "dt besar tidak melewati tujuan (naik): 3,0 -> tepat 6,0")
	check(absf(h.maju_ubin - 598.5) < TOLERANSI_TEPAT, "jarak dt besar tepat: rampa 1 detik (4,5 ubin) + 99 detik x 6,0 = 598,5 ubin (BikeDrive dulu 450, pendekatan), dapat %s" % h.maju_ubin)
	h = BikeMotion.langkah(_keadaan(1.6), Vector2(0, -1), 0.2)
	check(h.keadaan.kecepatan_ud == 1.5 and not h.keadaan.rem_aktif and h.tujuan_ud == 1.5, "bawah penuh sebelum rem aktif (0,2 detik): tujuan 1,5, dari 1,6 berhenti tepat di 1,5, dapat %s" % h.keadaan.kecepatan_ud)
	h = BikeMotion.langkah(_keadaan(), Vector2(0, 0.5), 1.0)
	check(is_equal_approx(h.keadaan.kecepatan_ud, 4.5), "tujuan menengah: dari 3,0 stick atas 0,5 selama 1 detik = 4,5 (bukan 6,0), dapat %s" % h.keadaan.kecepatan_ud)
	h = BikeMotion.langkah(_keadaan(4.4), Vector2(0, 0.5), 0.1)
	check(is_equal_approx(h.keadaan.kecepatan_ud, 4.5), "dt 0,1 dari 4,4 ke tujuan 4,5 berhenti di 4,5, dapat %s" % h.keadaan.kecepatan_ud)
	h = BikeMotion.langkah(_keadaan(6.0), Vector2(0, 0.5), 1.0)
	check(is_equal_approx(h.keadaan.kecepatan_ud, 4.5), "turun ke tujuan menengah: dari 6,0 stick atas 0,5 selama 1 detik = 4,5, dapat %s" % h.keadaan.kecepatan_ud)
	# Sapuan: tidak pernah melewati tujuan dari arah mana pun (stick bawah paling dalam 0,85, di bawah ambang rem).
	var melewati: bool = false
	for atas: float in [0.1, 0.25, 0.5, 0.75, 0.9, -0.25, -0.5, -0.85]:
		var tujuan: float = BikeMotion.kecepatan_tujuan_ud(atas)
		for selisih: float in [-1.0, -0.5, -0.1, -0.01, 0.0, 0.01, 0.1, 0.5, 1.0]:
			for dt_uji: float in [0.016, 0.1, 0.5, 1.0, 100.0]:
				var awal: float = clampf(tujuan + selisih, Config.KECEPATAN_MELAMBAT_UD, Config.KECEPATAN_NGEBUT_UD)
				var akhir: float = BikeMotion.langkah(_keadaan(awal), Vector2(0, atas), dt_uji).keadaan.kecepatan_ud
				if awal <= tujuan and akhir > tujuan + TOLERANSI_TEPAT:
					melewati = true
				if awal >= tujuan and akhir < tujuan - TOLERANSI_TEPAT:
					melewati = true
	check(not melewati, "sapuan stick x selisih x dt 0,016..100: kecepatan tidak pernah melewati tujuan (QB-002 run 0B)")
	# Jarak tepat terhadap integral rampa lalu tetap, untuk dt di dalam dan di luar waktu rampa.
	var galat: float = 0.0
	for atas: float in [0.0, 0.5, 1.0, -0.5, -0.85]:
		var tujuan: float = BikeMotion.kecepatan_tujuan_ud(atas)
		for selisih: float in [-1.0, -0.15, 0.0, 0.15, 1.0]:
			var awal: float = clampf(tujuan + selisih, Config.KECEPATAN_MELAMBAT_UD, Config.KECEPATAN_NGEBUT_UD)
			var laju: float = Config.AKSELERASI_UD2 if awal < tujuan else Config.PERLAMBATAN_MELAMBAT_UD2
			var waktu_rampa: float = absf(tujuan - awal) / laju
			for dt_uji: float in [0.05, 0.1, 0.4, 2.0]:
				var eksak: float = 0.0
				if dt_uji <= waktu_rampa:
					var akhir: float = awal + signf(tujuan - awal) * laju * dt_uji
					eksak = (awal + akhir) / 2 * dt_uji
				else:
					eksak = (awal + tujuan) / 2 * waktu_rampa + tujuan * (dt_uji - waktu_rampa)
				galat = maxf(galat, absf(BikeMotion.langkah(_keadaan(awal), Vector2(0, atas), dt_uji).maju_ubin - eksak))
	check(galat < TOLERANSI_TEPAT, "jarak per langkah tepat (rampa lalu tetap) untuk dt 0,05..2 detik, galat terbesar %s ubin" % galat)


func _test_masukan_aneh_dan_murni() -> void:
	_judul.call("BikeMotion: dt dan stick tidak sah, fungsi murni (AC-2)")
	var k: BikeMotion.Keadaan = _keadaan(4.2, 63.0, 0.4)
	k.tahan_rem_detik = 0.1
	for dt_aneh: float in [0.0, -1.0, NAN, INF, -INF]:
		var h: BikeMotion.Hasil = BikeMotion.langkah(k, Vector2(1, -1), dt_aneh)
		check(_sama_keadaan(h.keadaan, k) and h.maju_ubin == 0.0 and h.lateral_ud == 0.0, "dt %s: kecepatan, lateral, stamina, lama tahan rem, rem, lelah tidak berubah dan jarak 0" % dt_aneh)
	var netral: BikeMotion.Hasil = BikeMotion.langkah(_keadaan(5.0), Vector2.ZERO, 0.1)
	var nan_stick: BikeMotion.Hasil = BikeMotion.langkah(_keadaan(5.0), Vector2(NAN, NAN), 0.1)
	check(_sama_keadaan(nan_stick.keadaan, netral.keadaan), "stick NaN = netral")
	var besar: BikeMotion.Hasil = BikeMotion.langkah(_keadaan(3.0), Vector2(5, 5), 0.1)
	var satu: BikeMotion.Hasil = BikeMotion.langkah(_keadaan(3.0), Vector2(1, 1), 0.1)
	check(_sama_keadaan(besar.keadaan, satu.keadaan), "stick (5, 5) dijepit per komponen = (1, 1)")
	var bawah_besar: BikeMotion.Hasil = _jalankan(_keadaan(3.0), Vector2(0, -7), 30)
	var bawah_satu: BikeMotion.Hasil = _jalankan(_keadaan(3.0), Vector2(0, -1), 30)
	check(_sama_keadaan(bawah_besar.keadaan, bawah_satu.keadaan) and bawah_besar.keadaan.rem_aktif, "stick (0, -7) = (0, -1): rem tetap bekerja")
	var k_aneh: BikeMotion.Keadaan = _keadaan(NAN, NAN, NAN)
	k_aneh.tahan_rem_detik = NAN
	var bersih: BikeMotion.Hasil = BikeMotion.langkah(k_aneh, Vector2.ZERO, 0.0)
	check(bersih.keadaan.kecepatan_ud == 3.0 and bersih.keadaan.stamina == 100.0 and bersih.keadaan.lateral_ubin == 0.0 and bersih.keadaan.tahan_rem_detik == 0.0, "keadaan NaN dibersihkan: santai, stamina penuh, lateral 0, tahan 0")
	var k_luar: BikeMotion.Keadaan = _keadaan(9.0, 150.0, 5.0)
	var jepit: BikeMotion.Hasil = BikeMotion.langkah(k_luar, Vector2.ZERO, 0.0)
	check(jepit.keadaan.kecepatan_ud == 6.0 and jepit.keadaan.stamina == 100.0 and jepit.keadaan.lateral_ubin == 1.0, "keadaan di luar jangkauan dijepit: 9 -> 6 u/d, stamina 150 -> 100, lateral 5 -> 1")
	check(BikeMotion.langkah(null, Vector2.ZERO, DT).keadaan != null, "keadaan null = keadaan awal (tidak crash)")
	# Murni: masukan tidak berubah, hasil objek baru, hasil sama untuk masukan sama (2000 rangkaian acak seed tetap).
	var asli: BikeMotion.Keadaan = _keadaan(4.0, 50.0, 0.2)
	var cadangan: BikeMotion.Keadaan = asli.salin()
	var h1: BikeMotion.Hasil = BikeMotion.langkah(asli, Vector2(0.3, -1), 0.3)
	check(_sama_keadaan(asli, cadangan) and h1.keadaan != asli, "langkah tidak mengubah keadaan masukan dan mengembalikan objek baru")
	var salinan: BikeMotion.Keadaan = asli.salin()
	salinan.stamina = 1.0
	check(asli.stamina == 50.0, "salin() bebas: mengubah salinan tidak mengubah aslinya")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20261013
	var keadaan: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
	var sama: bool = true
	var aman: bool = true
	for i: int in range(2000):
		var stick: Vector2 = Vector2(rng.randf_range(-1.5, 1.5), rng.randf_range(-1.5, 1.5))
		var dt: float = rng.randf_range(0.0, 0.3)
		var a: BikeMotion.Hasil = BikeMotion.langkah(keadaan, stick, dt)
		var b: BikeMotion.Hasil = BikeMotion.langkah(keadaan, stick, dt)
		if not _sama_keadaan(a.keadaan, b.keadaan) or a.maju_ubin != b.maju_ubin or a.pose != b.pose or a.arah_sprite != b.arah_sprite or a.pedal_rate != b.pedal_rate:
			sama = false
		var s: BikeMotion.Keadaan = a.keadaan
		if s.kecepatan_ud < 0.0 or s.kecepatan_ud > 6.0 or absf(s.lateral_ubin) > 1.0 or s.stamina < 0.0 or s.stamina > 100.0 or a.maju_ubin < 0.0 or s.tahan_rem_detik < 0.0:
			aman = false
		if s.kecepatan_ud < Config.KECEPATAN_MELAMBAT_UD - TOLERANSI_TEPAT and not s.rem_aktif and keadaan.kecepatan_ud >= Config.KECEPATAN_MELAMBAT_UD:
			aman = false
		keadaan = s
	check(sama, "BikeMotion deterministik: masukan sama menghasilkan keluaran sama (2000 rangkaian acak seed tetap)")
	check(aman, "kecepatan 0..6, lateral di dalam jalan, stamina 0..100, jarak dan lama tahan tidak negatif; di bawah 1,5 hanya lewat rem (2000 rangkaian acak)")


# --- AC-3: rem (D-2) ---

func _test_rem_ambang() -> void:
	_judul.call("Rem: ambang komponen bawah (AC-3, D-2)")
	check(not BikeMotion.syarat_rem_bawah(0.899), "komponen bawah 0,899 tidak memenuhi syarat rem")
	check(BikeMotion.syarat_rem_bawah(0.90), "komponen bawah 0,90 memenuhi syarat rem (inklusif)")
	check(BikeMotion.syarat_rem_bawah(Config.REM_AMBANG_STICK - Config.REM_AMBANG_TOLERANSI), "tepat di ambang efektif (0,90 - toleransi) memenuhi: batas inklusif (>=, bukan >)")
	check(not BikeMotion.syarat_rem_bawah(Config.REM_AMBANG_STICK - 2.0 * Config.REM_AMBANG_TOLERANSI), "sedikit di bawah ambang efektif tidak memenuhi")
	check(BikeMotion.syarat_rem(Vector2(0, -0.9)) and not BikeMotion.syarat_rem(Vector2(0, -0.899)), "lewat Vector2 berpresisi tunggal: (0, -0,90) memenuhi, (0, -0,899) tidak")
	check(BikeMotion.syarat_rem(Vector2(0, -1)) and not BikeMotion.syarat_rem(Vector2(0, 1)) and not BikeMotion.syarat_rem(Vector2.ZERO) and not BikeMotion.syarat_rem(Vector2(-1, 0)), "bawah penuh memenuhi; atas, netral, dan samping tidak")
	check(not BikeMotion.syarat_rem_bawah(NAN) and not BikeMotion.syarat_rem(Vector2(NAN, NAN)), "NaN tidak memenuhi syarat rem")
	# 0,899 ditahan 5 detik: tidak pernah rem, kecepatan menuju tujuan 1,6515.
	var h: BikeMotion.Hasil = _jalankan(_keadaan(), Vector2(0, -0.899), 300)
	check(not h.keadaan.rem_aktif and h.keadaan.tahan_rem_detik == 0.0 and absf(h.keadaan.kecepatan_ud - BikeMotion.kecepatan_tujuan_ud(-0.899)) < 0.0001, "bawah 0,899 ditahan 5 detik: tidak pernah rem, lama tahan 0, kecepatan di tujuan %s, dapat %s" % [BikeMotion.kecepatan_tujuan_ud(-0.899), h.keadaan.kecepatan_ud])
	h = _jalankan(_keadaan(), Vector2(0, -0.9), 15)
	check(h.keadaan.rem_aktif, "bawah 0,90 ditahan 15 x 1/60 = 0,25 detik: rem aktif")


func _test_rem_tahan() -> void:
	_judul.call("Rem: lama tahan 0,25 detik (AC-3)")
	var h: BikeMotion.Hasil = BikeMotion.langkah(_keadaan(), Vector2(0, -1), 0.249)
	check(not h.keadaan.rem_aktif and is_equal_approx(h.keadaan.tahan_rem_detik, 0.249), "tahan 0,249 detik (satu langkah): belum rem, lama tahan 0,249")
	h = BikeMotion.langkah(_keadaan(), Vector2(0, -1), 0.25)
	check(h.keadaan.rem_aktif, "tahan tepat 0,25 detik (satu langkah): rem aktif")
	check(BikeMotion.tahan_cukup(Config.REM_TAHAN_DETIK - Config.REM_TAHAN_TOLERANSI_DETIK) and not BikeMotion.tahan_cukup(0.249), "tahan_cukup: batas efektif inklusif, 0,249 belum")
	h = _jalankan(_keadaan(), Vector2(0, -1), 14)
	check(not h.keadaan.rem_aktif and h.pose == LoperAnim.Pose.MELUNCUR, "14 langkah 1/60 (0,233 detik): belum rem, pose meluncur")
	h = BikeMotion.langkah(h.keadaan, Vector2(0, -1), DT)
	check(h.keadaan.rem_aktif and h.pose == LoperAnim.Pose.REM, "langkah ke-15 (jumlah float 0,25): rem aktif, pose rem")
	# Lepas (vektor nol) di tengah tahan: lama tahan 0 dan tidak rem.
	h = _jalankan(_keadaan(), Vector2(0, -1), 12)
	h = BikeMotion.langkah(h.keadaan, Vector2.ZERO, DT)
	check(h.keadaan.tahan_rem_detik == 0.0 and not h.keadaan.rem_aktif, "stick dilepas di tengah tahan (0,2 detik): lama tahan kembali 0, tidak rem")
	h = _jalankan(h.keadaan, Vector2(0, -1), 12)
	check(not h.keadaan.rem_aktif, "menahan lagi 0,2 detik sesudah lepas: belum rem (hitungan mulai dari 0)")
	# Naik sesaat di atas ambang (komponen bawah 0,85) lalu kembali: hitungan mulai dari 0.
	h = _jalankan(_keadaan(), Vector2(0, -1), 12)
	h = BikeMotion.langkah(h.keadaan, Vector2(0, -0.85), DT)
	check(h.keadaan.tahan_rem_detik == 0.0, "naik sesaat ke bawah 0,85 (di bawah ambang): lama tahan 0")
	h = _jalankan(h.keadaan, Vector2(0, -1), 14)
	check(not h.keadaan.rem_aktif, "kembali ke bawah penuh 14 langkah (0,233 detik): belum rem")
	h = BikeMotion.langkah(h.keadaan, Vector2(0, -1), DT)
	check(h.keadaan.rem_aktif, "langkah ke-15 sesudah kembali: rem aktif")
	# Ke samping dan ke atas juga memutus.
	for putus: Vector2 in [Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]:
		h = _jalankan(_keadaan(), Vector2(0, -1), 12)
		h = BikeMotion.langkah(h.keadaan, putus, DT)
		check(h.keadaan.tahan_rem_detik == 0.0 and not h.keadaan.rem_aktif, "stick %s di tengah tahan memutus hitungan" % putus)


func _test_rem_berhenti_dan_lepas() -> void:
	_judul.call("Rem: berhenti 5,0 u/d2 sampai 0, lepas (AC-3)")
	var aktif: BikeMotion.Keadaan = _keadaan(3.0)
	aktif.rem_aktif = true
	aktif.tahan_rem_detik = 0.3
	var h: BikeMotion.Hasil = BikeMotion.langkah(aktif, Vector2(0, -1), 0.1)
	check(is_equal_approx(h.keadaan.kecepatan_ud, 2.5) and h.keadaan.rem_aktif, "rem aktif 0,1 detik dari 3,0 = 2,5 u/d (5,0 u/d2), dapat %s" % h.keadaan.kecepatan_ud)
	check(is_equal_approx(h.maju_ubin, 0.275), "jarak 0,1 detik pengereman 3,0 -> 2,5 = 0,275 ubin, dapat %s" % h.maju_ubin)
	h = BikeMotion.langkah(aktif, Vector2(0, -1), 0.6)
	check(h.keadaan.kecepatan_ud == 0.0 and is_equal_approx(h.maju_ubin, 0.9), "rem 0,6 detik dari 3,0: berhenti tepat 0 (tidak negatif), jarak henti v2/2a = 0,9 ubin, dapat %s dan %s" % [h.keadaan.kecepatan_ud, h.maju_ubin])
	h = _jalankan(h.keadaan, Vector2(0, -1), 120)
	check(h.keadaan.kecepatan_ud == 0.0 and h.maju_ubin == 0.0 and h.keadaan.rem_aktif, "rem ditahan 2 detik lagi: tetap 0 u/d, tidak maju, rem tetap aktif")
	check(h.keadaan.kecepatan_ud < Config.KECEPATAN_MELAMBAT_UD, "rem membawa kecepatan di bawah 1,5 (tidak berhenti di KECEPATAN_MELAMBAT_UD)")
	# Dari ngebut: berhenti dalam 6,0 / 5,0 = 1,2 detik sesudah aktif.
	h = _jalankan(_keadaan(6.0), Vector2(0, -1), 15 + 72)
	check(h.keadaan.kecepatan_ud == 0.0, "dari ngebut: 0,25 detik tahan + 1,2 detik rem = berhenti, dapat %s" % h.keadaan.kecepatan_ud)
	# Lepas saat rem aktif: rem padam, kecepatan naik 3,0 u/d2 ke santai.
	var henti: BikeMotion.Keadaan = h.keadaan
	h = BikeMotion.langkah(henti, Vector2.ZERO, 0.5)
	check(not h.keadaan.rem_aktif and h.keadaan.tahan_rem_detik == 0.0 and is_equal_approx(h.keadaan.kecepatan_ud, 1.5), "lepas saat berhenti: rem padam, 0,5 detik kemudian 1,5 u/d (3,0 u/d2), dapat %s" % h.keadaan.kecepatan_ud)
	h = BikeMotion.langkah(henti, Vector2.ZERO, 1.0)
	check(h.keadaan.kecepatan_ud == 3.0 and _nama(h) == &"santai_normal", "lepas: 1 detik kemudian santai 3,0 u/d dan santai_normal")
	var atas: BikeMotion.Hasil = BikeMotion.langkah(henti, Vector2(0, 1), 1.0)
	check(is_equal_approx(atas.keadaan.kecepatan_ud, 3.0) and not atas.keadaan.rem_aktif, "lepas ke atas penuh: naik 3,0 u/d2 dari 0 (1 detik = 3,0)")


func _test_rem_diagonal() -> void:
	_judul.call("Rem: diagonal tidak rem, bawah penuh dengan geser kecil tetap rem (AC-3)")
	var h: BikeMotion.Hasil = _jalankan(_keadaan(), Vector2(0.5, -0.85), 180)
	check(not h.keadaan.rem_aktif and h.keadaan.tahan_rem_detik == 0.0, "diagonal bawah 0,85 + samping 0,5 ditahan 3 detik: tidak rem")
	h = _jalankan(_keadaan(), Vector2(-0.70710678, -0.70710678), 180)
	check(not h.keadaan.rem_aktif, "diagonal 45 derajat penuh (bawah 0,707) ditahan 3 detik: tidak rem")
	var diagonal_jari: Vector2 = StickMap.petakan(Vector2(Config.STICK_RADIUS_PX, Config.STICK_RADIUS_PX))
	check(not BikeMotion.syarat_rem(diagonal_jari), "jari diagonal 45 derajat lewat StickMap (bawah %s) tidak memenuhi syarat" % -diagonal_jari.y)
	var geser_kecil: Vector2 = StickMap.petakan(Vector2(8, Config.STICK_RADIUS_PX))
	check(-geser_kecil.y >= 0.90 and BikeMotion.syarat_rem(geser_kecil), "jari bawah penuh dengan geser datar 8 px (bawah %s >= 0,90) memenuhi syarat" % -geser_kecil.y)
	h = _jalankan(_keadaan(), geser_kecil, 15)
	check(h.keadaan.rem_aktif and h.lateral_ud > 0.0, "bawah penuh dengan geser kecil ke sisi dekat: rem aktif sesudah 0,25 detik, lateral tetap bergerak")
	h = _jalankan(_keadaan(), Vector2(0.3, -0.954), 15)
	check(h.keadaan.rem_aktif, "bawah 0,954 + samping 0,3 (panjang 1): rem")


## Hasil tidak bergantung pada pembagian dt: skenario sama dengan dt 1/30 dan 1/240.
func _skenario(dt: float, stamina: float = 50.0) -> Array:
	var keadaan: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
	keadaan.stamina = stamina
	var jarak: float = 0.0
	# [stick, detik]: ngebut, bawah penuh (rem aktif di tengah langkah 1/30), lepas, bawah 0,5, cepat.
	for bagian: Array in [[Vector2(0, 1), 2.0], [Vector2(0, -1), 1.0], [Vector2.ZERO, 0.7], [Vector2(0, -0.5), 1.3], [Vector2(0.4, 0.5), 3.0]]:
		var jumlah: int = roundi(float(bagian[1]) / dt)
		for i: int in range(jumlah):
			var h: BikeMotion.Hasil = BikeMotion.langkah(keadaan, bagian[0], dt)
			keadaan = h.keadaan
			jarak += h.maju_ubin
	return [keadaan, jarak]


func _test_independen_dt() -> void:
	_judul.call("BikeMotion: hasil tidak bergantung pada pembagian dt (AC-3, D-2)")
	var kasar: Array = _skenario(1.0 / 30.0)
	var halus: Array = _skenario(1.0 / 240.0)
	var a: BikeMotion.Keadaan = kasar[0]
	var b: BikeMotion.Keadaan = halus[0]
	check(absf(a.kecepatan_ud - b.kecepatan_ud) < TOLERANSI_TEPAT, "kecepatan akhir dt 1/30 = dt 1/240 (galat < 1e-6): %s lawan %s" % [a.kecepatan_ud, b.kecepatan_ud])
	check(absf(float(kasar[1]) - float(halus[1])) < 0.0001, "jarak total dt 1/30 = dt 1/240 (galat < 1e-4 ubin): %s lawan %s" % [kasar[1], halus[1]])
	check(absf(a.stamina - b.stamina) < TOLERANSI_STAMINA_DT, "stamina akhir dt 1/30 lawan 1/240 dalam toleransi %s: %s lawan %s" % [TOLERANSI_STAMINA_DT, a.stamina, b.stamina])
	check(absf(a.lateral_ubin - b.lateral_ubin) < TOLERANSI_TEPAT and a.rem_aktif == b.rem_aktif and a.lelah == b.lelah, "lateral, rem, dan lelah sama")
	# Dari stamina penuh: jepit 100 hanya diterapkan di akhir langkah, sedangkan laju di 3,0-3,5 u/d masih positif; selisih
	# karena jepit itu kecil (di bawah 0,01 poin untuk dt 1/30) dan memang sifat jepit, bukan pembagian rampa.
	var penuh_kasar: BikeMotion.Keadaan = _skenario(1.0 / 30.0, 100.0)[0]
	var penuh_halus: BikeMotion.Keadaan = _skenario(1.0 / 240.0, 100.0)[0]
	check(absf(penuh_kasar.stamina - penuh_halus.stamina) < 0.01 and absf(penuh_kasar.kecepatan_ud - penuh_halus.kecepatan_ud) < TOLERANSI_TEPAT, "dari stamina penuh (jepit 100 di awal rampa): dt 1/30 lawan 1/240 berbeda < 0,01 poin (%s lawan %s)" % [penuh_kasar.stamina, penuh_halus.stamina])
	# Langkah yang melewati batas 0,25 detik dibagi: rem mulai tepat di 0,25 detik.
	var satu: BikeMotion.Hasil = BikeMotion.langkah(_keadaan(3.0), Vector2(0, -1), 0.35)
	# 0,25 detik meluncur dari 3,0 (2,0 u/d2) = 2,5, lalu 0,1 detik rem (5,0 u/d2) = 2,0.
	check(is_equal_approx(satu.keadaan.kecepatan_ud, 2.0) and satu.keadaan.rem_aktif, "satu langkah 0,35 detik: 0,25 detik meluncur (3,0 -> 2,5) lalu 0,1 detik rem (-> 2,0), dapat %s" % satu.keadaan.kecepatan_ud)
	var pecah: BikeMotion.Hasil = _jalankan(_keadaan(3.0), Vector2(0, -1), 35, 0.01)
	check(absf(pecah.keadaan.kecepatan_ud - satu.keadaan.kecepatan_ud) < TOLERANSI_TEPAT and absf(pecah.maju_ubin - satu.maju_ubin) < TOLERANSI_TEPAT, "35 langkah 0,01 = satu langkah 0,35 (kecepatan %s lawan %s, jarak %s lawan %s)" % [pecah.keadaan.kecepatan_ud, satu.keadaan.kecepatan_ud, pecah.maju_ubin, satu.maju_ubin])


# --- AC-4: stamina (D-5) ---

func _test_stamina_laju() -> void:
	_judul.call("Stamina: laju per detik (AC-4, D-5)")
	check(BikeMotion.laju_stamina_kecepatan(3.0) == 2.0 and BikeMotion.laju_stamina_kecepatan(4.5) == -4.0 and BikeMotion.laju_stamina_kecepatan(6.0) == -12.0, "laju di 3,0 / 4,5 / 6,0 u/d = +2 / -4 / -12")
	check(is_equal_approx(BikeMotion.laju_stamina_kecepatan(3.75), -1.0) and is_equal_approx(BikeMotion.laju_stamina_kecepatan(5.25), -8.0), "interpolasi linear: 3,75 u/d = -1, 5,25 u/d = -8 (bukan tangga)")
	check(is_equal_approx(BikeMotion.laju_stamina_kecepatan(3.3), 0.8) and is_equal_approx(BikeMotion.laju_stamina_kecepatan(5.7), -10.4), "interpolasi di dekat titik: 3,3 = +0,8, 5,7 = -10,4")
	check(BikeMotion.laju_stamina_kecepatan(0.0) == 2.0 and BikeMotion.laju_stamina_kecepatan(1.5) == 2.0 and BikeMotion.laju_stamina_kecepatan(9.0) == -12.0 and BikeMotion.laju_stamina_kecepatan(NAN) == 2.0, "di bawah santai = +2, di atas ngebut = -12, NaN = +2")
	var monoton: bool = true
	var terakhir: float = INF
	for i: int in range(0, 601):
		var laju: float = BikeMotion.laju_stamina_kecepatan(float(i) / 100.0)
		if laju > terakhir + TOLERANSI_TEPAT:
			monoton = false
		terakhir = laju
	check(monoton, "laju stamina tidak pernah naik saat kecepatan naik (0..6 u/d)")
	check(BikeMotion.laju_stamina(-0.1, false, 6.0) == 15.0 and BikeMotion.laju_stamina(0.0, true, 6.0) == 15.0 and BikeMotion.laju_stamina(0.0, false, 6.0) == -12.0, "stick ke bawah atau rem aktif = +15 walau kecepatan 6,0; netral = dari kecepatan")
	var h: BikeMotion.Hasil = BikeMotion.langkah(_keadaan(3.0, 50.0), Vector2.ZERO, 1.0)
	check(is_equal_approx(h.keadaan.stamina, 52.0), "santai 1 detik dari 50 = 52, dapat %s" % h.keadaan.stamina)
	h = BikeMotion.langkah(_keadaan(6.0, 50.0), Vector2(0, 1), 1.0)
	check(is_equal_approx(h.keadaan.stamina, 38.0), "ngebut 1 detik dari 50 = 38, dapat %s" % h.keadaan.stamina)
	h = BikeMotion.langkah(_keadaan(4.5, 50.0), Vector2(0, 0.5), 1.0)
	check(is_equal_approx(h.keadaan.stamina, 46.0), "cepat 1 detik dari 50 = 46, dapat %s" % h.keadaan.stamina)
	h = BikeMotion.langkah(_keadaan(3.0, 50.0), Vector2(0, -0.5), 1.0)
	check(is_equal_approx(h.keadaan.stamina, 65.0), "stick ke bawah (meluncur/melambat) 1 detik dari 50 = 65, dapat %s" % h.keadaan.stamina)
	var rem: BikeMotion.Keadaan = _keadaan(0.0, 50.0)
	rem.rem_aktif = true
	rem.tahan_rem_detik = 1.0
	h = BikeMotion.langkah(rem, Vector2(0, -1), 1.0)
	check(is_equal_approx(h.keadaan.stamina, 65.0), "rem aktif 1 detik dari 50 = 65, dapat %s" % h.keadaan.stamina)
	# Stamina tepat selama rampa: 3,0 -> 6,0 dalam 1 detik = 0,5 detik rata-rata -1 lalu 0,5 detik rata-rata -8 = -4,5 (bukan -5
	# dari trapesium ujung-ujung, bukan -12 dari laju tujuan). Satu langkah 1 detik = 240 langkah kecil.
	h = BikeMotion.langkah(_keadaan(3.0, 50.0), Vector2(0, 1), 1.0)
	var h_kecil: BikeMotion.Hasil = _jalankan(_keadaan(3.0, 50.0), Vector2(0, 1), 240, 1.0 / 240.0)
	check(is_equal_approx(h.keadaan.stamina, 45.5) and absf(h_kecil.keadaan.stamina - h.keadaan.stamina) < TOLERANSI_TEPAT, "rampa 3,0 -> 6,0 dalam 1 detik: stamina 50 -> 45,5 tepat, satu langkah = 240 langkah (dapat %s dan %s)" % [h.keadaan.stamina, h_kecil.keadaan.stamina])
	h = BikeMotion.langkah(_keadaan(6.0, 50.0), Vector2.ZERO, 2.0)
	check(is_equal_approx(h.keadaan.stamina, 44.25), "rampa turun 6,0 -> 3,0 (1,5 detik) lalu santai 0,5 detik: 50 - 6,75 + 1,0 = 44,25, dapat %s" % h.keadaan.stamina)
	h = BikeMotion.langkah(_keadaan(3.0, 99.0), Vector2(0, -0.5), 1.0)
	check(h.keadaan.stamina == 100.0, "stamina dijepit di 100, dapat %s" % h.keadaan.stamina)
	h = BikeMotion.langkah(_keadaan(6.0, 1.0), Vector2(0, 1), 1.0)
	check(h.keadaan.stamina == 0.0, "stamina dijepit di 0 (tidak negatif), dapat %s" % h.keadaan.stamina)
	h = BikeMotion.langkah(_keadaan(3.0, 100.0), Vector2.ZERO, 1.0)
	check(h.keadaan.stamina == 100.0, "santai di stamina penuh tetap 100")


func _test_stamina_durasi() -> void:
	_judul.call("Stamina: durasi ngebut, cepat, pulih (AC-4, BALANCING 3)")
	var habis: Callable = func(k: BikeMotion.Keadaan) -> bool: return k.stamina <= 0.0
	var penuh: Callable = func(k: BikeMotion.Keadaan) -> bool: return k.stamina >= 100.0
	var t_ngebut: float = _waktu_sampai(_keadaan(), Vector2(0, 1), habis, 60.0)
	check(t_ngebut >= 8.0 and t_ngebut <= 9.5, "dari penuh, ngebut terus (mulai santai) habis dalam 8,0-9,5 detik, dapat %s" % t_ngebut)
	var t_cepat: float = _waktu_sampai(_keadaan(), Vector2(0, 0.5), habis, 60.0)
	check(t_cepat >= 24.0 and t_cepat <= 27.0, "dari penuh, cepat terus habis dalam 24-27 detik, dapat %s" % t_cepat)
	var t_pulih: float = _waktu_sampai(_keadaan(3.0, 0.0), Vector2(0, -0.85), penuh, 30.0)
	check(t_pulih > 0.0 and t_pulih <= 7.0, "dari 0, meluncur penuh (bawah 0,85, tanpa rem) penuh dalam <= 7 detik, dapat %s" % t_pulih)
	var t_santai: float = _waktu_sampai(_keadaan(3.0, 50.0), Vector2.ZERO, habis, 120.0)
	check(t_santai < 0.0, "invarian prinsip 1: santai terus 120 detik tidak pernah menguras stamina sampai habis")
	var santai: BikeMotion.Hasil = _jalankan(_keadaan(3.0, 50.0), Vector2.ZERO, 600)
	check(santai.keadaan.stamina > 50.0, "invarian prinsip 1: santai 10 detik menambah stamina (50 -> %s)" % santai.keadaan.stamina)
	var ngebut: BikeMotion.Hasil = _jalankan(_keadaan(), Vector2(0, 1), 1200)
	check(ngebut.keadaan.lelah and ngebut.keadaan.kecepatan_ud <= Config.KECEPATAN_CEPAT_UD, "invarian prinsip 1: ngebut terus 20 detik tidak bisa dipertahankan (lelah, kecepatan %s <= 4,5)" % ngebut.keadaan.kecepatan_ud)


func _test_lelah() -> void:
	_judul.call("Stamina: lelah menyala di 0, padam di >= 30 (AC-4, D-5)")
	var h: BikeMotion.Hasil = BikeMotion.langkah(_keadaan(6.0, 0.5), Vector2(0, 1), DT)
	check(not h.keadaan.lelah and h.keadaan.stamina > 0.0, "stamina 0,5 -> 0,3 (belum 0): belum lelah")
	h = BikeMotion.langkah(_keadaan(6.0, 0.2), Vector2(0, 1), DT)
	check(h.keadaan.lelah and h.keadaan.stamina == 0.0, "stamina mencapai 0: lelah menyala")
	var lelah: BikeMotion.Keadaan = h.keadaan
	h = BikeMotion.langkah(lelah, Vector2(0, 1), 0.5)
	check(is_equal_approx(h.keadaan.kecepatan_ud, 5.0) and h.tujuan_ud == 4.5, "lelah, stick atas penuh: tujuan 4,5, turun dari 6,0 dengan 2,0 u/d2 (0,5 detik = 5,0), dapat %s" % h.keadaan.kecepatan_ud)
	h = BikeMotion.langkah(lelah, Vector2(0, 1), 2.0)
	check(h.keadaan.kecepatan_ud == 4.5 and h.keadaan.lelah and h.keadaan.stamina == 0.0, "lelah 2 detik ngebut: tertahan di 4,5 dan stamina tetap 0 (-4/d di 4,5, disengaja)")
	check(h.tingkat_sprite == 1 and _nama(h) == &"cepat_normal", "sprite dijepit ke cepat selama lelah: cepat_normal, dapat %s" % _nama(h))
	# Lelah tetap menyala di antara 0 dan 30.
	var k: BikeMotion.Keadaan = _keadaan(3.0, 10.0)
	k.lelah = true
	h = BikeMotion.langkah(k, Vector2.ZERO, 1.0)
	check(h.keadaan.lelah and is_equal_approx(h.keadaan.stamina, 12.0), "stamina 10 -> 12 (santai): lelah tetap (tidak padam di > 0)")
	k = _keadaan(3.0, 26.99)
	k.lelah = true
	h = BikeMotion.langkah(k, Vector2(0, -0.5), 0.2)
	check(h.keadaan.lelah and h.keadaan.stamina < 30.0, "26,99 + 3,0 = 29,99: lelah tetap (padam bukan sebelum 30)")
	k = _keadaan(3.0, 27.0)
	k.lelah = true
	h = BikeMotion.langkah(k, Vector2(0, -0.5), 0.2)
	check(not h.keadaan.lelah and is_equal_approx(h.keadaan.stamina, 30.0), "27 + 3,0 = 30: lelah padam (>= 30), dapat %s" % h.keadaan.stamina)
	k = _keadaan(3.0, 100.0)
	k.lelah = false
	h = BikeMotion.langkah(k, Vector2(0, 1), DT)
	check(not h.keadaan.lelah and h.tingkat_sprite == 2, "tanpa lelah: stick atas penuh = tingkat ngebut")
	# Pulih ke 30 lewat meluncur sekitar 2 detik.
	var pulih: Callable = func(kk: BikeMotion.Keadaan) -> bool: return not kk.lelah
	var t: float = _waktu_sampai(lelah, Vector2(0, -0.85), pulih, 10.0)
	check(t >= 1.9 and t <= 2.1, "dari lelah di 0, meluncur memadamkan lelah dalam sekitar 2 detik (30 / 15), dapat %s" % t)


# --- AC-5: lateral (D-4) ---

func _test_lateral() -> void:
	_judul.call("Lateral analog dengan batas tepi jalan resmi (AC-5, D-4)")
	var h: BikeMotion.Hasil = BikeMotion.langkah(_keadaan(), Vector2(1, 0), 0.1)
	check(is_equal_approx(h.keadaan.lateral_ubin, 0.3) and is_equal_approx(h.lateral_ud, 3.0), "datar 1 x 3,0 u/d x 0,1 detik = +0,3 ubin ke sisi dekat (positif), lateral_ud 3,0")
	h = BikeMotion.langkah(_keadaan(), Vector2(-0.5, 0), 0.2)
	check(is_equal_approx(h.keadaan.lateral_ubin, -0.3) and is_equal_approx(h.lateral_ud, -1.5), "datar -0,5 selama 0,2 detik = -0,3 ubin ke sisi seberang (negatif), lateral_ud -1,5")
	h = _jalankan(_keadaan(), Vector2(1, 0), 120)
	check(h.keadaan.lateral_ubin == 1.0, "dijepit di tepi aspal sisi dekat (+1 ubin)")
	h = _jalankan(h.keadaan, Vector2(-1, 0), 120)
	check(h.keadaan.lateral_ubin == -1.0, "dijepit di tepi aspal sisi seberang (-1 ubin)")
	h = BikeMotion.langkah(_keadaan(3.0, 100.0, 1.0), Vector2(1, 0), 0.1)
	check(h.keadaan.lateral_ubin == 1.0 and h.lateral_ud == 0.0, "terhalang tepi: tidak bergeser dan lateral_ud 0")
	h = BikeMotion.langkah(_keadaan(3.0, 100.0, 0.95), Vector2(1, 0), 0.1)
	check(h.keadaan.lateral_ubin == 1.0 and is_equal_approx(h.lateral_ud, 0.5), "sebagian terhalang: lateral_ud = perpindahan nyata (0,05 / 0,1 = 0,5), dapat %s" % h.lateral_ud)
	h = BikeMotion.langkah(_keadaan(3.0, 100.0, -1.0), Vector2(1, 0), 0.1)
	check(is_equal_approx(h.lateral_ud, 3.0), "dari tepi seberang ke arah dekat: bebas, lateral_ud +3,0")
	h = BikeMotion.langkah(_keadaan(), Vector2(-0.7, 0.7), 0.1)
	check(h.keadaan.kecepatan_ud > 3.0 and h.keadaan.lateral_ubin < 0.0 and h.maju_ubin > 0.0, "diagonal maju + seberang: kecepatan naik, lateral bergeser, maju dalam satu langkah")
	check(_nama(h) == &"cepat_serong_kiri", "diagonal maju + seberang: sprite serong seberang (cepat_serong_kiri), dapat %s" % _nama(h))
	# Lateral tetap bekerja saat berhenti dengan rem (keputusan pemilik: analog bebas): arah 90 derajat dari gerak nyata.
	var rem: BikeMotion.Keadaan = _keadaan(0.0)
	rem.rem_aktif = true
	rem.tahan_rem_detik = 1.0
	h = BikeMotion.langkah(rem, Vector2(0.3, -0.954), DT)
	check(h.keadaan.rem_aktif and h.lateral_ud > 0.0 and h.arah_sprite == 2 and _nama(h) == &"rem_kanan", "berhenti dengan rem sambil geser ke sisi dekat: rem_kanan (90 derajat dari gerak nyata), dapat %s" % _nama(h))
	h = BikeMotion.langkah(rem, Vector2(0, -1), DT)
	check(h.arah_sprite == 0 and _nama(h) == &"rem_normal", "berhenti tanpa lateral: arah normal (rem_normal)")


# --- AC-6: pose dan laju kayuh (D-7, D-8) ---

func _test_pose() -> void:
	_judul.call("LoperAnim: pose dari gerak (AC-6, D-7)")
	var tol: float = Config.POSE_MELUNCUR_TOLERANSI_UD
	check(LoperAnim.pose_dari_gerak(true, -1.0, 3.0, 1.5) == LoperAnim.Pose.REM, "rem aktif, kecepatan 3,0 = REM")
	check(LoperAnim.pose_dari_gerak(true, -1.0, 0.0, 1.5) == LoperAnim.Pose.REM, "rem aktif, sudah berhenti (0) = REM")
	check(LoperAnim.pose_dari_gerak(true, 0.0, 2.0, 3.0) == LoperAnim.Pose.REM, "rem aktif menang atas semua (stick netral)")
	check(LoperAnim.pose_dari_gerak(false, -1.0, 3.0, 1.5) == LoperAnim.Pose.MELUNCUR, "stick bawah, kecepatan 3,0 di atas tujuan 1,5 = MELUNCUR")
	check(LoperAnim.pose_dari_gerak(false, -0.5, 2.0 + tol * 1.01, 2.0) == LoperAnim.Pose.MELUNCUR, "kecepatan di atas tujuan sedikit lebih dari toleransi = MELUNCUR")
	check(LoperAnim.pose_dari_gerak(false, -0.5, 2.0 + tol * 0.99, 2.0) == LoperAnim.Pose.KAYUH, "kecepatan di atas tujuan sedikit kurang dari toleransi = KAYUH (melambat, batas toleransi)")
	check(LoperAnim.pose_dari_gerak(false, -0.5, 2.0, 2.0) == LoperAnim.Pose.KAYUH, "kecepatan tepat di tujuan = KAYUH (melambat)")
	check(LoperAnim.pose_dari_gerak(false, -0.5, 1.6, 2.0) == LoperAnim.Pose.KAYUH, "kecepatan di bawah tujuan (naik) = KAYUH (melambat)")
	check(LoperAnim.pose_dari_gerak(false, 0.0, 6.0, 3.0) == LoperAnim.Pose.KAYUH and LoperAnim.pose_dari_gerak(false, 0.5, 6.0, 4.5) == LoperAnim.Pose.KAYUH, "stick netral atau atas tidak pernah meluncur walau kecepatan di atas tujuan")
	check(LoperAnim.pose_dari_gerak(false, NAN, 6.0, 1.5) == LoperAnim.Pose.KAYUH and LoperAnim.pose_dari_gerak(false, -1.0, NAN, 1.5) == LoperAnim.Pose.KAYUH, "NaN = KAYUH")
	check(LoperAnim.tingkat_sprite(1.0, false) == 2 and LoperAnim.tingkat_sprite(1.0, true) == 1 and LoperAnim.tingkat_sprite(0.5, true) == 1, "lelah menjepit tingkat ngebut ke cepat, cepat tetap cepat")
	check(LoperAnim.tingkat_sprite(0.0, true) == 0 and LoperAnim.tingkat_sprite(-1.0, true) == LoperAnim.TINGKAT_MELAMBAT, "lelah tidak mengubah santai dan melambat")
	check(LoperAnim.nama_animasi_pose(LoperAnim.Pose.REM, 2, -1) == &"rem_serong_kiri" and LoperAnim.nama_animasi_pose(LoperAnim.Pose.MELUNCUR, -1, 9) == &"meluncur_kanan", "nama pose: rem_serong_kiri, meluncur dengan arah dijepit = meluncur_kanan")
	check(LoperAnim.nama_animasi_pose(LoperAnim.Pose.KAYUH, -1, 0) == &"melambat_normal" and LoperAnim.nama_animasi_pose(LoperAnim.Pose.KAYUH, 1, 1) == &"cepat_serong_kanan", "nama pose kayuh = nama_animasi lama")
	check(LoperAnim.tingkat_lempar(LoperAnim.Pose.MELUNCUR, -1) == 0 and LoperAnim.tingkat_lempar(LoperAnim.Pose.REM, 2) == 0 and LoperAnim.tingkat_lempar(LoperAnim.Pose.KAYUH, 2) == 2 and LoperAnim.tingkat_lempar(LoperAnim.Pose.KAYUH, -1) == 0, "lempar dari meluncur dan rem memakai santai, dari kayuh tetap tingkatnya (melambat = santai)")


func _test_pose_dari_langkah() -> void:
	_judul.call("BikeMotion -> pose dan nama animasi (AC-6, D-7)")
	var frames: SpriteFrames = load(BERKAS_FRAMES) as SpriteFrames
	var semua_ada: bool = frames != null
	var kasus: Array = []
	# [label, keadaan awal, stick, jumlah langkah, nama harapan]
	var ngebut: BikeMotion.Keadaan = _keadaan(6.0)
	kasus.append(["rem bergerak (0,3 detik bawah penuh dari ngebut)", ngebut, Vector2(0, -1), 18, &"rem_normal"])
	kasus.append(["rem berhenti (3 detik bawah penuh)", ngebut, Vector2(0, -1), 180, &"rem_normal"])
	kasus.append(["meluncur (bawah 0,85 dari ngebut, 0,5 detik)", ngebut, Vector2(0, -0.85), 30, &"meluncur_normal"])
	kasus.append(["melambat (bawah 0,85 dari ngebut, 4 detik: sudah di tujuan)", ngebut, Vector2(0, -0.85), 240, &"melambat_normal"])
	kasus.append(["kayuh santai", _keadaan(), Vector2.ZERO, 30, &"santai_normal"])
	kasus.append(["kayuh cepat", _keadaan(), Vector2(0, 0.5), 30, &"cepat_normal"])
	kasus.append(["kayuh ngebut", _keadaan(), Vector2(0, 1), 30, &"ngebut_normal"])
	kasus.append(["meluncur serong dekat (dari 3,0, bawah-dekat 0,7)", _keadaan(), Vector2(0.7, -0.7), 3, &"meluncur_serong_kanan"])
	kasus.append(["meluncur serong seberang (dari 3,0, bawah-seberang 0,7)", _keadaan(), Vector2(-0.7, -0.7), 3, &"meluncur_serong_kiri"])
	kasus.append(["rem bergerak serong dekat (dari 3,0, 0,5 detik)", _keadaan(), Vector2(0.3, -0.954), 30, &"rem_serong_kanan"])
	kasus.append(["melambat serong seberang", _keadaan(BikeMotion.kecepatan_tujuan_ud(-0.8)), Vector2(-0.5, -0.8), 6, &"melambat_serong_kiri"])
	for k: Array in kasus:
		var h: BikeMotion.Hasil = _jalankan(k[1], k[2], k[3])
		check(_nama(h) == k[4], "%s: %s, dapat %s (kecepatan %s, tujuan %s)" % [k[0], k[4], _nama(h), h.keadaan.kecepatan_ud, h.tujuan_ud])
		semua_ada = semua_ada and frames.has_animation(_nama(h))
	var lelah: BikeMotion.Keadaan = _keadaan(6.0, 0.0)
	lelah.lelah = true
	var hl: BikeMotion.Hasil = _jalankan(lelah, Vector2(0.3, 1), 6)
	check(_nama(hl) == &"cepat_serong_kanan" or _nama(hl) == &"cepat_normal", "lelah + atas penuh + sedikit dekat: tingkat cepat (bukan ngebut), dapat %s" % _nama(hl))
	# Pergantian berurutan: bawah 0,85 dari ngebut = meluncur sampai tujuan, lalu melambat; tidak berkedip kembali.
	var keadaan: BikeMotion.Keadaan = _keadaan(6.0)
	var urutan: Array[StringName] = []
	for i: int in range(300):
		var h: BikeMotion.Hasil = BikeMotion.langkah(keadaan, Vector2(0, -0.85), DT)
		keadaan = h.keadaan
		if urutan.is_empty() or urutan[-1] != _nama(h):
			urutan.append(_nama(h))
	check(urutan == [&"meluncur_normal", &"melambat_normal"], "bawah 0,85 dari ngebut 5 detik: meluncur_normal lalu melambat_normal, sekali ganti, dapat %s" % [urutan])
	# Semua nama yang dihasilkan langkah acak ada di SpriteFrames.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1013
	keadaan = BikeMotion.Keadaan.new()
	for i: int in range(3000):
		var stick: Vector2 = Vector2(rng.randf_range(-1.2, 1.2), rng.randf_range(-1.2, 1.2))
		var h: BikeMotion.Hasil = BikeMotion.langkah(keadaan, stick, rng.randf_range(0.0, 0.1))
		keadaan = h.keadaan
		semua_ada = semua_ada and frames.has_animation(_nama(h))
	check(semua_ada, "semua nama animasi dari BikeMotion (tabel kasus dan 3000 langkah acak) ada di SpriteFrames")


func _test_pedal_rate() -> void:
	_judul.call("LoperAnim.pedal_rate: laju kayuh mengikuti kecepatan (AC-6, D-8)")
	var kayuh: LoperAnim.Pose = LoperAnim.Pose.KAYUH
	check(LoperAnim.pedal_rate(kayuh, 0, 3.0) == 1.0 and LoperAnim.pedal_rate(kayuh, 1, 4.5) == 1.0 and LoperAnim.pedal_rate(kayuh, 2, 6.0) == 1.0 and LoperAnim.pedal_rate(kayuh, -1, 1.5) == 1.0, "di kecepatan nominal tiap tingkat (3,0 / 4,5 / 6,0 / melambat 1,5) = 1")
	check(LoperAnim.pedal_rate(kayuh, 0, 1.5) == 0.5 and LoperAnim.pedal_rate(kayuh, 2, 3.0) == 0.5 and LoperAnim.pedal_rate(kayuh, -1, 0.75) == 0.5, "di setengah nominal = 0,5")
	check(LoperAnim.pedal_rate(kayuh, 0, 0.0) == 0.0 and LoperAnim.pedal_rate(kayuh, 2, 0.0) == 0.0, "di kecepatan 0 = 0 (kaki diam)")
	check(LoperAnim.pedal_rate(kayuh, 0, 6.0) == Config.PEDAL_RATE_MAKS and LoperAnim.pedal_rate(kayuh, -1, 6.0) == Config.PEDAL_RATE_MAKS, "dijepit di PEDAL_RATE_MAKS (santai di 6,0 = 2 -> 1,5)")
	check(is_equal_approx(LoperAnim.pedal_rate(kayuh, 1, 6.0), 6.0 / 4.5), "lelah di 6,0 dengan tingkat cepat: 1,33 (di bawah batas)")
	check(LoperAnim.pedal_rate(kayuh, 0, -1.0) == 0.0 and LoperAnim.pedal_rate(kayuh, 0, NAN) == 0.0, "negatif dan NaN = 0")
	check(LoperAnim.pedal_rate(LoperAnim.Pose.MELUNCUR, 0, 6.0) == 1.0 and LoperAnim.pedal_rate(LoperAnim.Pose.REM, 2, 0.0) == 1.0 and LoperAnim.pedal_rate(LoperAnim.Pose.REM, 0, 3.0) == 1.0, "meluncur dan rem tidak dikayuh: selalu 1 (fps dari .tres)")
	check(LoperAnim.kecepatan_nominal_ud(-9) == 1.5 and LoperAnim.kecepatan_nominal_ud(9) == 6.0, "kecepatan nominal tingkat dijepit (-9 = melambat, 9 = ngebut)")
	# Terpadu: dari berhenti ke ngebut, pedal_rate naik bersama kecepatan.
	var keadaan: BikeMotion.Keadaan = _keadaan(0.0)
	var naik: bool = true
	var terakhir: float = -1.0
	for i: int in range(150):
		var h: BikeMotion.Hasil = BikeMotion.langkah(keadaan, Vector2(0, 1), DT)
		keadaan = h.keadaan
		if h.pedal_rate < terakhir or absf(h.pedal_rate - h.keadaan.kecepatan_ud / 6.0) > TOLERANSI_TEPAT:
			naik = false
		terakhir = h.pedal_rate
	check(naik and terakhir == 1.0, "dari berhenti ke ngebut: pedal_rate = kecepatan / 6,0, naik monoton sampai 1, dapat akhir %s" % terakhir)


# --- AC-8: jeda (bagian murni) ---

func _test_jeda_sim() -> void:
	_judul.call("JedaSim dan BikeMotion.jeda (AC-8, D-6)")
	for what: int in [Node.NOTIFICATION_APPLICATION_PAUSED, Node.NOTIFICATION_APPLICATION_FOCUS_OUT]:
		check(JedaSim.notifikasi_jeda(what) and JedaSim.jeda_sesudah(false, what) and not JedaSim.baru_lanjut_sesudah(false, true, what), "notifikasi %d menjeda dan mematikan baru_lanjut" % what)
	for what: int in [Node.NOTIFICATION_APPLICATION_RESUMED, Node.NOTIFICATION_APPLICATION_FOCUS_IN]:
		check(JedaSim.notifikasi_lanjut(what) and not JedaSim.jeda_sesudah(true, what) and JedaSim.baru_lanjut_sesudah(true, false, what), "notifikasi %d melanjutkan dan menyalakan baru_lanjut (dari jeda)" % what)
		check(not JedaSim.baru_lanjut_sesudah(false, false, what), "notifikasi %d tanpa jeda sebelumnya tidak menyalakan baru_lanjut" % what)
	check(JedaSim.jeda_sesudah(true, Node.NOTIFICATION_READY) and not JedaSim.jeda_sesudah(false, Node.NOTIFICATION_READY), "notifikasi lain tidak mengubah status jeda")
	check(JedaSim.dt_efektif(true, false, 0.016) == 0.0 and JedaSim.dt_efektif(true, false, 5.0) == 0.0, "selama jeda dt efektif 0 (juga dt besar)")
	check(JedaSim.dt_efektif(false, true, 0.1) == 0.0, "langkah pertama sesudah lanjut dt efektif 0 (bukan LANGKAH_WAKTU_MAKS_DETIK)")
	check(JedaSim.dt_efektif(false, false, 0.016) == 0.016 and JedaSim.dt_efektif(false, false, 5.0) == 5.0, "tanpa jeda dt apa adanya (jepit tetap tugas _process)")
	check(JedaSim.dt_efektif(false, false, NAN) == 0.0 and JedaSim.dt_efektif(false, false, -1.0) == 0.0 and JedaSim.dt_efektif(false, false, INF) == 0.0, "dt NaN, negatif, tak hingga = 0")
	# Urutan Android: FOCUS_OUT, PAUSED, RESUMED, FOCUS_IN.
	var jeda: bool = false
	var baru: bool = false
	var dt_tercatat: Array[float] = []
	for what: int in [Node.NOTIFICATION_APPLICATION_FOCUS_OUT, Node.NOTIFICATION_APPLICATION_PAUSED, Node.NOTIFICATION_APPLICATION_RESUMED, Node.NOTIFICATION_APPLICATION_FOCUS_IN]:
		baru = JedaSim.baru_lanjut_sesudah(jeda, baru, what)
		jeda = JedaSim.jeda_sesudah(jeda, what)
	for i: int in range(2):
		dt_tercatat.append(JedaSim.dt_efektif(jeda, baru, 0.016))
		if not jeda:
			baru = false
	check(not jeda and dt_tercatat == [0.0, 0.016], "urutan FOCUS_OUT, PAUSED, RESUMED, FOCUS_IN: lanjut, langkah pertama 0, berikutnya normal, dapat %s" % [dt_tercatat])
	# BikeMotion.jeda: lama tahan 0, rem padam, lainnya tetap; masukan tidak berubah.
	var k: BikeMotion.Keadaan = _keadaan(2.0, 40.0, 0.3)
	k.tahan_rem_detik = 0.4
	k.rem_aktif = true
	k.lelah = true
	var j: BikeMotion.Keadaan = BikeMotion.jeda(k)
	check(j.tahan_rem_detik == 0.0 and not j.rem_aktif and j.kecepatan_ud == 2.0 and j.stamina == 40.0 and j.lateral_ubin == 0.3 and j.lelah, "BikeMotion.jeda: lama tahan 0 dan rem padam; kecepatan, stamina, lateral, lelah tetap")
	check(k.tahan_rem_detik == 0.4 and k.rem_aktif, "BikeMotion.jeda tidak mengubah masukan")
	var tengah: BikeMotion.Hasil = _jalankan(_keadaan(), Vector2(0, -1), 12)
	var lanjut: BikeMotion.Hasil = _jalankan(BikeMotion.jeda(tengah.keadaan), Vector2(0, -1), 6)
	check(not lanjut.keadaan.rem_aktif, "jeda di tengah tahan rem (0,2 detik), lanjut 0,1 detik: rem tidak langsung aktif")


# --- Busur rem di cincin stick (DESIGN_SPEC 3.7) ---

func _test_busur_rem() -> void:
	_judul.call("PikselLingkaran: busur bawah cincin untuk rem (AC-9)")
	var r: int = int(Config.STICK_RADIUS_PX)
	var t: int = Config.STICK_CINCIN_TEBAL_PX
	check(PikselLingkaran.di_busur_bawah(0, r, r, t), "piksel paling bawah cincin (0, %d) di busur" % r)
	check(not PikselLingkaran.di_busur_bawah(0, -r, r, t) and not PikselLingkaran.di_busur_bawah(r, 0, r, t) and not PikselLingkaran.di_busur_bawah(-r, 0, r, t), "atas, kanan, kiri cincin bukan busur bawah")
	check(not PikselLingkaran.di_busur_bawah(0, r - t - 2, r, t) and not PikselLingkaran.di_busur_bawah(0, 0, r, t), "bagian dalam cincin bukan busur")
	var jumlah: int = 0
	var cincin_bawah: int = 0
	var simetris: bool = true
	for dy: int in range(-r, r + 1):
		for dx: int in range(-r, r + 1):
			if PikselLingkaran.di_busur_bawah(dx, dy, r, t):
				jumlah += 1
				if not PikselLingkaran.di_cincin(dx, dy, r, t) or dy <= 0 or absi(dx) > dy:
					simetris = false
				if not PikselLingkaran.di_busur_bawah(-dx, dy, r, t):
					simetris = false
			elif PikselLingkaran.di_cincin(dx, dy, r, t) and dy > 0 and absi(dx) <= dy:
				cincin_bawah += 1
	check(simetris and cincin_bawah == 0 and jumlah > 0, "busur = semua piksel cincin di seperempat bawah (|dx| <= dy), simetris kiri-kanan (%d piksel)" % jumlah)
