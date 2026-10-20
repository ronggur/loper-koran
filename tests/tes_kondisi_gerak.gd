class_name TesKondisiGerak
extends RefCounted
## Tes `EfekKondisi` terhadap `BikeMotion` nyata dan rute nyata, run fase6a1-bengkel-kondisi (AC-9, AC-10, AC-12, AC-8 bagian lintasan aus, AC-11):
## - identitas: 500 masukan acak berseed, keluaran dengan efek kosong, `EfekKondisi.new()`, dan efek sepeda baru identik bit demi bit dengan sidik emas yang dihitung dari
##   kode gerak SEBELUM ada efek (git HEAD `bike_motion.gd` run 4B, sama dengan keluaran lama untuk 500 masukan yang sama);
## - dominasi satu langkah dan invarian rute 60 seed dengan ban, rem, dan rantai kondisi 0 sejak awal (`BikeMotion` + `RouteBuilder` + `TenggatRute` nyata);
## - rem blong tetap berhenti dalam jarak batas, stick maju selalu menghasilkan kecepatan > 0 di semua kondisi;
## - target aus tiga profil (BALANCING 8) dari bot yang menjalankan `BikeMotion` nyata di rute `RouteBuilder` tanpa tabrakan dan tanpa servis;
## - peringatan mendahului efek pada lintasan aus nyata.
## Tes ini TIDAK menyentuh berkas.

## Sidik emas: sha256 dari bit 64-bit hasil `BikeMotion.langkah` kode SEBELUM efek untuk `SimProfilKondisi.masukan_acak(500, 20261020)`.
const SIDIK_EMAS_GERAK: String = "885da896ef96fd6f01d014fd034076ce86a39707ae82ff491e9ee2a187ac4404"
const DT: float = 1.0 / 60.0
const TOLERANSI: float = 0.000000001

var _cek: Callable
var _judul: Callable


func _init(cek: Callable, judul: Callable) -> void:
	_cek = cek
	_judul = judul


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_test_identitas_bit_demi_bit()
	_test_sumber_gerak()
	_test_dominasi_satu_langkah()
	_test_efek_terukur()
	_test_rem_blong()
	_test_tidak_ada_kebuntuan()
	_test_invarian_rute_semua_rusak()
	_test_target_aus_tiga_profil()
	_test_peringatan_mendahului_efek()


func _kondisi_semua(nilai: float) -> Dictionary:
	var k: Dictionary = {}
	for kom: String in Config.KONDISI_KOMPONEN:
		k[kom] = nilai
	return k


# --- AC-9 ---

func _test_identitas_bit_demi_bit() -> void:
	_judul.call("BikeMotion.langkah: efek kosong atau identitas = keluaran identik bit demi bit dengan gerak lama, 500 masukan acak berseed (AC-9)")
	var masukan: Array[SimProfilKondisi.Masukan] = SimProfilKondisi.masukan_acak(500, 20261020)
	var tanpa: Array[PackedFloat64Array] = []
	var kosong: Array[PackedFloat64Array] = []
	var identitas: Array[PackedFloat64Array] = []
	var baru: Array[PackedFloat64Array] = []
	for m: SimProfilKondisi.Masukan in masukan:
		tanpa.append(SimProfilKondisi.nilai_hasil(BikeMotion.langkah(m.keadaan, m.stick, m.dt, m.beku)))
		kosong.append(SimProfilKondisi.nilai_hasil(BikeMotion.langkah(m.keadaan, m.stick, m.dt, m.beku, null)))
		identitas.append(SimProfilKondisi.nilai_hasil(BikeMotion.langkah(m.keadaan, m.stick, m.dt, m.beku, EfekKondisi.new())))
		baru.append(SimProfilKondisi.nilai_hasil(BikeMotion.langkah(m.keadaan, m.stick, m.dt, m.beku, BikeCondition.efek(BikeCondition.baru()))))
	check(masukan.size() == 500, "500 masukan acak")
	check(SimProfilKondisi.sidik(tanpa) == SIDIK_EMAS_GERAK, "tanpa efek: sidik 500 hasil = sidik emas kode gerak lama (%s)" % SimProfilKondisi.sidik(tanpa))
	check(SimProfilKondisi.sidik(kosong) == SIDIK_EMAS_GERAK, "efek null: sidik = sidik emas")
	check(SimProfilKondisi.sidik(identitas) == SIDIK_EMAS_GERAK, "EfekKondisi.new() (identitas): sidik = sidik emas")
	check(SimProfilKondisi.sidik(baru) == SIDIK_EMAS_GERAK, "efek dari sepeda baru (BikeCondition.efek): sidik = sidik emas")
	var sama: bool = true
	for i: int in range(500):
		if tanpa[i] != identitas[i] or tanpa[i] != baru[i]:
			sama = false
	check(sama, "per masukan: larik nilai identik persis (==) untuk tiga cara memanggil")
	var tidak_identik: int = 0
	for m: SimProfilKondisi.Masukan in masukan.slice(0, 100):
		var e: EfekKondisi = BikeCondition.efek(_kondisi_semua(0.0))
		var rusak: PackedFloat64Array = SimProfilKondisi.nilai_hasil(BikeMotion.langkah(m.keadaan, m.stick, m.dt, m.beku, e))
		if rusak != SimProfilKondisi.nilai_hasil(BikeMotion.langkah(m.keadaan, m.stick, m.dt, m.beku)):
			tidak_identik += 1
	check(tidak_identik >= 40, "pembanding hidup: efek sepeda rusak total mengubah keluaran pada banyak masukan (%d dari 100)" % tidak_identik)
	# Masukan keadaan tidak diubah oleh efek.
	var s: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
	s.kecepatan_ud = 5.0
	BikeMotion.langkah(s, Vector2(0.0, 1.0), 0.5, 0.0, BikeCondition.efek(_kondisi_semua(0.0)))
	check(s.kecepatan_ud == 5.0, "langkah dengan efek tidak mengubah keadaan masukan")


func _test_sumber_gerak() -> void:
	_judul.call("Pemindai sumber: tidak ada angka pengali di bike_motion.gd, semua dari EfekKondisi (AC-9, M-6)")
	var teks: String = FileAccess.get_file_as_string("res://scripts/systems/bike_motion.gd")
	var kode: String = ""
	for baris: String in teks.split("\n"):
		var i: int = baris.find("#")
		kode += (baris if i < 0 else baris.substr(0, i)) + "\n"
	check(not kode.contains("Config.KONDISI_") and not kode.contains("BikeCondition"), "bike_motion.gd tidak merujuk Config.KONDISI_* atau BikeCondition (efek datang sebagai objek EfekKondisi)")
	check(kode.contains("e.pengali_akselerasi") and kode.contains("e.pengali_kecepatan") and kode.contains("e.batas_puncak_ud") and kode.contains("e.pengali_rem") and kode.contains("e.pengali_lateral") and kode.contains("e.pengali_kuras_stamina"), "bike_motion.gd memakai keenam bidang EfekKondisi")
	var re_angka: RegEx = RegEx.create_from_string("(?<![A-Za-z0-9_.])[0-9]+\\.[0-9]+")
	var desimal: Array[String] = []
	for cocok: RegExMatch in re_angka.search_all(kode):
		if cocok.get_string() != "0.0" and cocok.get_string() != "1.0":
			desimal.append(cocok.get_string())
	check(desimal.is_empty(), "bike_motion.gd tidak memuat angka desimal selain 0,0 dan 1,0: %s" % [desimal])


# --- AC-10a ---

func _test_dominasi_satu_langkah() -> void:
	_judul.call("EfekKondisi: dominasi satu langkah, kecepatan, jarak, dan lateral dengan efek <= tanpa efek; rem blong tidak lebih pakem (AC-10a)")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 6101
	var nilai_kondisi: Array[float] = [0.0, 0.1, 0.2, 0.3, 0.34, 0.35, 0.5, 0.7, 1.0]
	var pelanggaran: Array[String] = []
	var dicoba: int = 0
	var rem_dicoba: int = 0
	var rem_pelanggaran: Array[String] = []
	for i: int in range(3000):
		var kond: Dictionary = {"ban": nilai_kondisi[rng.randi() % 9], "rem": nilai_kondisi[rng.randi() % 9], "rantai": nilai_kondisi[rng.randi() % 9]}
		var e: EfekKondisi = BikeCondition.efek(kond)
		var s: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
		s.kecepatan_ud = rng.randf_range(0.0, 6.0)
		s.lateral_ubin = rng.randf_range(-1.0, 1.0)
		s.stamina = rng.randf_range(0.0, 100.0)
		s.lelah = rng.randi() % 4 == 0
		var dt: float = [DT, 0.1, 0.5, 2.0][rng.randi() % 4]
		var stick: Vector2 = Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-0.5, 1.0))
		var lama: BikeMotion.Hasil = BikeMotion.langkah(s, stick, dt)
		var baru: BikeMotion.Hasil = BikeMotion.langkah(s, stick, dt, 0.0, e)
		dicoba += 1
		var salah: Array[String] = []
		if baru.keadaan.kecepatan_ud > lama.keadaan.kecepatan_ud + TOLERANSI:
			salah.append("kecepatan %s > %s" % [baru.keadaan.kecepatan_ud, lama.keadaan.kecepatan_ud])
		if baru.maju_ubin > lama.maju_ubin + TOLERANSI:
			salah.append("jarak %s > %s" % [baru.maju_ubin, lama.maju_ubin])
		if absf(baru.keadaan.lateral_ubin - s.lateral_ubin) > absf(lama.keadaan.lateral_ubin - s.lateral_ubin) + TOLERANSI:
			salah.append("lateral lebih lincah dengan efek")
		if baru.tujuan_ud > lama.tujuan_ud + TOLERANSI:
			salah.append("kecepatan tujuan %s > %s" % [baru.tujuan_ud, lama.tujuan_ud])
		if e.pengali_akselerasi > 1.0 or e.pengali_kecepatan > 1.0 or e.pengali_rem > 1.0 or e.pengali_lateral > 1.0:
			salah.append("pengali di atas 1,0")
		if not salah.is_empty():
			pelanggaran.append("%s %s: %s" % [kond, stick, salah])
		# Rem aktif dari awal: perlambatan efek <= tanpa efek, jadi kecepatan akhir >= dan jarak >= .
		var sr: BikeMotion.Keadaan = s.salin()
		sr.rem_aktif = true
		sr.tahan_rem_detik = Config.REM_TAHAN_DETIK
		var lama_r: BikeMotion.Hasil = BikeMotion.langkah(sr, Vector2(0.0, -1.0), dt)
		var baru_r: BikeMotion.Hasil = BikeMotion.langkah(sr, Vector2(0.0, -1.0), dt, 0.0, e)
		rem_dicoba += 1
		if baru_r.keadaan.kecepatan_ud < lama_r.keadaan.kecepatan_ud - TOLERANSI or baru_r.maju_ubin < lama_r.maju_ubin - TOLERANSI:
			rem_pelanggaran.append("%s: rem efek lebih pakem dari normal" % [kond])
	check(dicoba == 3000 and pelanggaran.is_empty(), "%d langkah acak (kondisi, stick, dt, keadaan): nol pelanggaran dominasi: %s" % [dicoba, pelanggaran.slice(0, 3)])
	check(rem_dicoba == 3000 and rem_pelanggaran.is_empty(), "%d langkah rem aktif: rem rusak tidak pernah berhenti lebih cepat dari normal: %s" % [rem_dicoba, rem_pelanggaran.slice(0, 3)])
	# Pengali monoton terhadap kondisi tiap komponen terpisah (kisi 0,01).
	var monoton: bool = true
	var terakhir: EfekKondisi = BikeCondition.efek(_kondisi_semua(0.0))
	for i: int in range(1, 101):
		var e2: EfekKondisi = BikeCondition.efek(_kondisi_semua(float(i) / 100.0))
		if e2.pengali_akselerasi < terakhir.pengali_akselerasi or e2.pengali_kecepatan < terakhir.pengali_kecepatan or e2.pengali_rem < terakhir.pengali_rem or e2.pengali_lateral < terakhir.pengali_lateral or e2.batas_puncak_ud < terakhir.batas_puncak_ud:
			monoton = false
		terakhir = e2
	check(monoton, "pengali monoton tidak turun saat kondisi naik, kisi 0,01")


## Tiap pengali efek mengubah hasil gerak ke arah yang dijanjikan (efek tidak yatim).
func _test_efek_terukur() -> void:
	_judul.call("EfekKondisi: tiap efek terukur di BikeMotion ke arah yang dijanjikan GDD 12.1 (AC-10, M-6)")
	var rusak: EfekKondisi = BikeCondition.efek(_kondisi_semua(0.0))
	# Rantai putus: akselerasi turun drastis dari diam.
	var diam: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
	diam.kecepatan_ud = 0.0
	var normal: BikeMotion.Hasil = BikeMotion.langkah(diam, Vector2(0.0, 1.0), 1.0)
	var putus: BikeMotion.Hasil = BikeMotion.langkah(diam, Vector2(0.0, 1.0), 1.0, 0.0, BikeCondition.efek({"ban": 1.0, "rem": 1.0, "rantai": 0.0}))
	check(absf(normal.keadaan.kecepatan_ud - 3.0) < TOLERANSI and absf(putus.keadaan.kecepatan_ud - 3.0 * 0.35) < TOLERANSI, "rantai putus: dari diam 1 detik, kecepatan 1,05 (x0,35 dari 3,0 u/d2) bukan 3,0")
	# Rantai putus: puncak dibatasi tetapi tidak di bawah santai.
	var penuh: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
	penuh.kecepatan_ud = 6.0
	var h_puncak: BikeMotion.Hasil = BikeMotion.langkah(penuh, Vector2(0.0, 1.0), 10.0, 0.0, BikeCondition.efek({"ban": 1.0, "rem": 1.0, "rantai": 0.0}))
	check(absf(h_puncak.keadaan.kecepatan_ud - 3.6) < TOLERANSI, "rantai putus: kecepatan puncak turun dari 6,0 ke 3,6 u/d (di atas santai 3,0)")
	var h_santai: BikeMotion.Hasil = BikeMotion.langkah(BikeMotion.Keadaan.new(), Vector2.ZERO, 10.0, 0.0, rusak)
	check(h_santai.keadaan.kecepatan_ud > 0.0 and h_santai.keadaan.kecepatan_ud <= 3.0, "semua rusak, stick netral: masih melaju (kurang dari atau sama dengan santai)")
	# Ban bocor: kecepatan tujuan dan lateral.
	var ban_nol: EfekKondisi = BikeCondition.efek({"ban": 0.0, "rem": 1.0, "rantai": 1.0})
	var h_ban: BikeMotion.Hasil = BikeMotion.langkah(BikeMotion.Keadaan.new(), Vector2.ZERO, 10.0, 0.0, ban_nol)
	check(absf(h_ban.keadaan.kecepatan_ud - 3.0 * 0.92) < TOLERANSI, "ban bocor: stick netral menuju 2,76 u/d bukan 3,0")
	var lat_normal: BikeMotion.Hasil = BikeMotion.langkah(BikeMotion.Keadaan.new(), Vector2(1.0, 0.0), 0.5)
	var lat_ban: BikeMotion.Hasil = BikeMotion.langkah(BikeMotion.Keadaan.new(), Vector2(1.0, 0.0), 0.5, 0.0, ban_nol)
	check(absf(lat_normal.keadaan.lateral_ubin - 1.5) < TOLERANSI and absf(lat_ban.keadaan.lateral_ubin - 1.5 * 0.6) < TOLERANSI, "ban bocor: pindah sisi 0,5 detik = 0,9 ubin bukan 1,5 (sulit belok)")


# --- AC-10c ---

## Jarak berhenti (ubin) dari rem aktif pada kecepatan `v` dengan `efek`, dihitung dengan BikeMotion nyata.
func _jarak_berhenti(v: float, efek: EfekKondisi) -> float:
	var s: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
	s.kecepatan_ud = v
	s.rem_aktif = true
	s.tahan_rem_detik = Config.REM_TAHAN_DETIK
	var jarak: float = 0.0
	var langkah: int = 0
	while s.kecepatan_ud > 0.0 and langkah < 6000:
		var h: BikeMotion.Hasil = BikeMotion.langkah(s, Vector2(0.0, -1.0), DT, 0.0, efek)
		jarak += h.maju_ubin
		s = h.keadaan
		langkah += 1
	return jarak


func _test_rem_blong() -> void:
	_judul.call("Rem blong (kondisi 0): tetap berhenti total dalam jarak batas Config; jarak naik monoton saat rem memburuk (AC-10c)")
	var normal: float = _jarak_berhenti(6.0, null)
	check(absf(normal - 3.6) < 0.000001, "rem normal dari ngebut 6,0 u/d berhenti dalam 3,6 ubin (v^2 / 2a = 36 / 10), dapat %s" % normal)
	var blong: float = _jarak_berhenti(6.0, BikeCondition.efek({"ban": 1.0, "rem": 0.0, "rantai": 1.0}))
	check(blong > normal + 1.0, "rem blong berhenti lebih jauh (%s > %s): kerusakan terasa" % [blong, normal])
	check(blong <= Config.KONDISI_REM_JARAK_MAKS_UBIN + 0.000001, "rem blong dari 6,0 u/d berhenti dalam %s <= %s ubin (batas Config, 2,5x normal)" % [blong, Config.KONDISI_REM_JARAK_MAKS_UBIN])
	check(blong / normal <= 2.5 + 0.000001, "rem blong paling jauh 2,5x jarak normal (rasio %s)" % (blong / normal))
	var terakhir: float = 0.0
	var monoton: bool = true
	for i: int in range(100, -1, -5):
		var jarak: float = _jarak_berhenti(6.0, BikeCondition.efek({"ban": 1.0, "rem": float(i) / 100.0, "rantai": 1.0}))
		if jarak < terakhir - 0.000001:
			monoton = false
		terakhir = jarak
		check(jarak <= Config.KONDISI_REM_JARAK_MAKS_UBIN + 0.000001, "kondisi rem %s: jarak berhenti %s tidak melewati batas" % [float(i) / 100.0, jarak])
	check(monoton, "makin rusak rem, makin jauh jarak berhenti (monoton)")
	for v: float in [1.5, 3.0, 4.5]:
		check(_jarak_berhenti(v, BikeCondition.efek(_kondisi_semua(0.0))) <= Config.KONDISI_REM_JARAK_MAKS_UBIN, "rem blong dari %s u/d berhenti dalam batas" % v)


func _test_tidak_ada_kebuntuan() -> void:
	_judul.call("Stick maju selalu menghasilkan kecepatan > 0 di semua kombinasi kondisi (tidak ada kebuntuan, prinsip 2) (AC-10c)")
	var kisi: Array[float] = [0.0, 0.05, 0.15, 0.25, 0.34, 0.35, 0.5, 0.7, 1.0]
	var kebuntuan: Array[String] = []
	var dicoba: int = 0
	for ban: float in kisi:
		for rem: float in kisi:
			for rantai: float in kisi:
				var e: EfekKondisi = BikeCondition.efek({"ban": ban, "rem": rem, "rantai": rantai})
				var dari_diam: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
				dari_diam.kecepatan_ud = 0.0
				var h: BikeMotion.Hasil = BikeMotion.langkah(dari_diam, Vector2(0.0, 1.0), 0.5, 0.0, e)
				var h2: BikeMotion.Hasil = BikeMotion.langkah(h.keadaan, Vector2(0.0, 1.0), 3.0, 0.0, e)
				var netral: BikeMotion.Hasil = BikeMotion.langkah(dari_diam, Vector2.ZERO, 1.0, 0.0, e)
				dicoba += 1
				if h.keadaan.kecepatan_ud <= 0.0 or h.maju_ubin <= 0.0 or h2.keadaan.kecepatan_ud < Config.KECEPATAN_SANTAI_UD * 0.9 or netral.keadaan.kecepatan_ud <= 0.0:
					kebuntuan.append("%s/%s/%s" % [ban, rem, rantai])
	check(dicoba == 729 and kebuntuan.is_empty(), "729 kombinasi kondisi: dari diam, stick atas atau netral selalu melaju dan 3,5 detik kemudian mencapai >= 90%% santai: %s" % [kebuntuan.slice(0, 3)])


# --- AC-10b ---

func _test_invarian_rute_semua_rusak() -> void:
	_judul.call("Invarian rute: ban, rem, rantai kondisi 0 sejak awal, santai terus (juga kecepatan otomatis mode bantu 3,0 u/d), 60 seed: tiba <= tenggat - cadangan (AC-10b, K-2)")
	var panjang: Array[float] = SimProfilKondisi.panjang_rute(60)
	var gagal: Array[String] = []
	var terlambat_terbaik: float = 1000.0
	var selesai_semua: bool = true
	for i: int in range(60):
		if panjang[i] <= 0.0:
			gagal.append("hari %d rute tidak sah" % (i + 1))
			continue
		var hasil: SimProfilKondisi.HasilSim = SimProfilKondisi.jalankan_rute("santai", panjang[i], _kondisi_semua(0.0), true)
		var tenggat: int = TenggatRute.detik_tenggat(panjang[i])
		var sisa: float = float(tenggat) - hasil.waktu
		terlambat_terbaik = minf(terlambat_terbaik, sisa)
		if not hasil.selesai:
			selesai_semua = false
		if hasil.waktu > float(tenggat) - Config.KONDISI_CADANGAN_TENGGAT_DETIK:
			gagal.append("hari %d: waktu %s > tenggat %d - %s" % [i + 1, hasil.waktu, tenggat, Config.KONDISI_CADANGAN_TENGGAT_DETIK])
	check(selesai_semua, "60 rute selesai (garis akhir tercapai) dengan semua komponen rusak total")
	check(gagal.is_empty(), "60 seed: waktu tempuh <= tenggat - cadangan 2,0 detik: %s" % [gagal.slice(0, 3)])
	check(terlambat_terbaik >= Config.KONDISI_CADANGAN_TENGGAT_DETIK and terlambat_terbaik < 12.0, "sisa waktu terkecil %s detik: cukup (>= cadangan) tetapi kerusakan tetap terasa (< 12 detik)" % terlambat_terbaik)
	# Pembanding: tanpa efek (sepeda baru) selalu lebih cepat dari semua rusak, dan rusak total lebih lambat.
	var baru: SimProfilKondisi.HasilSim = SimProfilKondisi.jalankan_rute("santai", panjang[0], BikeCondition.baru(), true)
	var rusak: SimProfilKondisi.HasilSim = SimProfilKondisi.jalankan_rute("santai", panjang[0], _kondisi_semua(0.0), true)
	check(rusak.waktu > baru.waktu + 1.0, "semua rusak lebih lambat dari sepeda baru (%s > %s detik): efek nyata" % [rusak.waktu, baru.waktu])


# --- AC-12 ---

func _test_target_aus_tiga_profil() -> void:
	_judul.call("Target aus (BALANCING 8): santai >= 12 rute tanpa PERLU_BENGKEL; ngebut + rem sering <= 6 rute; campuran di antaranya, strict (AC-12)")
	var panjang: Array[float] = SimProfilKondisi.panjang_rute(60)
	var kom_santai: Array[String] = []
	var kom_campuran: Array[String] = []
	var kom_ngebut: Array[String] = []
	var santai: int = SimProfilKondisi.rute_pertama_perlu_bengkel("santai", panjang, kom_santai)
	var campuran: int = SimProfilKondisi.rute_pertama_perlu_bengkel("campuran", panjang, kom_campuran)
	var ngebut: int = SimProfilKondisi.rute_pertama_perlu_bengkel("ngebut", panjang, kom_ngebut)
	check(santai == 0 or santai > 12, "santai terus: 12 rute berturut-turut tanpa komponen PERLU_BENGKEL (pertama kali di rute %d)" % santai)
	check(ngebut >= 1 and ngebut <= 6, "ngebut sebisa stamina + rem sering: komponen pertama PERLU_BENGKEL dalam <= 6 rute (rute %d: %s)" % [ngebut, kom_ngebut])
	var skala_santai: int = santai if santai > 0 else 999
	check(ngebut < campuran and campuran < skala_santai, "urutan ketat santai > campuran > ngebut: %d > %d > %d (0 = tidak pernah dalam 60 rute)" % [skala_santai, campuran, ngebut])
	# Santai nyata aus: kondisi turun tetapi bukan nol dan bukan abadi; rem tidak aus sama sekali.
	var k: Dictionary = BikeCondition.baru()
	for i: int in range(12):
		k = SimProfilKondisi.jalankan_rute("santai", panjang[i], k).kondisi
	check(BikeCondition.perlu_bengkel(k).is_empty() and float(k["ban"]) < 0.9 and float(k["rantai"]) < 0.95 and k["rem"] == 1.0, "12 rute santai: ban dan rantai sudah aus tapi tidak PERLU_BENGKEL, rem utuh; dapat %s" % [k])
	# Ngebut: rem sering terpakai (tepi naik berkali-kali per rute).
	var rute_ngebut: SimProfilKondisi.HasilSim = SimProfilKondisi.jalankan_rute("ngebut", panjang[0], BikeCondition.baru())
	check(rute_ngebut.rem_mulai >= 5 and rute_ngebut.selesai, "bot ngebut mengerem >= 5 kali dalam satu rute dan menyelesaikannya (%d kali)" % rute_ngebut.rem_mulai)
	var rute_santai: SimProfilKondisi.HasilSim = SimProfilKondisi.jalankan_rute("santai", panjang[0], BikeCondition.baru())
	check(rute_santai.rem_mulai == 0, "bot santai tidak pernah mengerem")
	# Ngebut punya harga tetapi juga keuntungan (prinsip 1): lebih cepat tiba daripada santai.
	check(rute_ngebut.waktu < rute_santai.waktu - 10.0, "ngebut tiba jauh lebih cepat (%s < %s detik): keuntungan nyata di samping harga aus" % [rute_ngebut.waktu, rute_santai.waktu])


# --- AC-8: peringatan mendahului efek ---

func _test_peringatan_mendahului_efek() -> void:
	_judul.call("Lintasan aus nyata 1,0 sampai efek pertama: peringatan pertama muncul sebelum efek pertama, profil santai dan ngebut (AC-8, prinsip 3)")
	var panjang: Array[float] = SimProfilKondisi.panjang_rute(60)
	for profil: String in ["ngebut", "santai"]:
		var jejak: SimProfilKondisi.Jejak = SimProfilKondisi.Jejak.new()
		var k: Dictionary = BikeCondition.baru()
		var rute_ke: int = 0
		while rute_ke < 60 and jejak.efek_pertama.size() < (3 if profil == "ngebut" else 2):
			k = SimProfilKondisi.jalankan_rute(profil, panjang[rute_ke], k, true, {}, {}, jejak).kondisi
			rute_ke += 1
		var harapan: int = 3 if profil == "ngebut" else 2
		check(jejak.efek_pertama.size() >= harapan, "profil %s: %d komponen mencapai efek dalam %d rute (dapat %s)" % [profil, harapan, rute_ke, jejak.efek_pertama.keys()])
		for kom: String in jejak.efek_pertama:
			var efek_t: float = float(jejak.efek_pertama[kom])
			var ada: bool = jejak.peringatan_pertama.has(kom)
			check(ada and float(jejak.peringatan_pertama[kom]) + Config.KONDISI_PERINGATAN_JEDA_DETIK <= efek_t, "profil %s, %s: peringatan pertama (detik %s) sedikitnya satu jeda sebelum efek pertama (detik %s)" % [profil, kom, jejak.peringatan_pertama.get(kom, -1.0), efek_t])
			check(int(jejak.jumlah_peringatan.get(kom, 0)) >= 2, "profil %s, %s: lebih dari satu peringatan sebelum dan sesudah efek (%d)" % [profil, kom, int(jejak.jumlah_peringatan.get(kom, 0))])
	# Komponen yang tidak dipakai tidak pernah memperingatkan: rem pada profil santai.
	var jejak2: SimProfilKondisi.Jejak = SimProfilKondisi.Jejak.new()
	var k2: Dictionary = BikeCondition.baru()
	for i: int in range(6):
		k2 = SimProfilKondisi.jalankan_rute("santai", panjang[i], k2, true, {}, {}, jejak2).kondisi
	check(not jejak2.jumlah_peringatan.has("rem"), "6 rute santai: rem tidak pernah memperingatkan (tidak dipakai, tanpa peringatan palsu)")
