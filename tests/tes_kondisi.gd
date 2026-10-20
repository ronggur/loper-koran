class_name TesKondisi
extends RefCounted
## Tes logika murni `BikeCondition` run fase6a1-bengkel-kondisi (AC-5 sampai AC-8, AC-11): tingkat dan kotak dari ambang (sapuan 0,00..1,00), aus dari telemetri `BikeMotion`
## nyata dan tulisan tangan, urutan aus ngebut > cepat > santai > 0, rem hanya aus saat dipakai, kerusakan tabrakan dari urutan `Tabrakan.langkah` nyata (satu pengurangan, tidak
## pernah BAIK langsung ke PERLU_BENGKEL, kondisi 0 tetap 0), tanda peringatan (jeda, tidak palsu, jeda game), efek (rentang, monoton, identitas di atas ambang), dan `SeedHari.kondisi`.
##
## Oracle independen: ambang ditulis literal di sini (dari BALANCING 8) dan tingkat dihitung tes sendiri dengan perbandingan langsung, bukan dengan memanggil fungsi yang dites; nilai
## aus di titik patah kecepatan (1,5 / 3,0 / 4,5 / 5,25 / 6,0 u/d) dihitung tangan dari koefisien Config. Tes ini TIDAK menyentuh berkas.

const DT: float = 1.0 / 60.0
const AMBANG_AUS: float = 0.7
const AMBANG_PERLU: float = 0.35
const TOLERANSI: float = 0.000000001

var _cek: Callable
var _judul: Callable


func _init(cek: Callable, judul: Callable) -> void:
	_cek = cek
	_judul = judul


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_test_config()
	_test_tingkat_sapuan()
	_test_rapikan_dan_bulatkan()
	_test_aus_titik_patah()
	_test_aus_telemetri_nyata_vs_tangan()
	_test_aus_urutan_dan_rem()
	_test_kecepatan_awal_telemetri()
	_test_tabrakan_komponen()
	_test_tabrakan_satu_pengurangan()
	_test_tabrakan_tidak_melompati_aus()
	_test_peringatan()
	_test_efek_sapuan()
	_test_efek_upgrade_dan_masukan_aneh()
	_test_seed()
	_test_sumber_tanpa_mode_bantu()


func _kondisi_semua(nilai: float) -> Dictionary:
	var k: Dictionary = {}
	for kom: String in Config.KONDISI_KOMPONEN:
		k[kom] = nilai
	return k


func _tele(maju: float, dt: float, v_awal: float, rem_aktif: bool = false, rem_mulai: bool = false) -> BikeCondition.Telemetri:
	var t: BikeCondition.Telemetri = BikeCondition.Telemetri.new()
	t.dt = dt
	t.maju_ubin = maju
	t.kecepatan_awal_ud = v_awal
	t.rem_aktif = rem_aktif
	t.rem_mulai = rem_mulai
	return t


# --- Config (BALANCING 8, usulan) ---

func _test_config() -> void:
	_judul.call("Kondisi sepeda: angka Config literal dan urutan ambang (M-1, M-2, BALANCING 8)")
	check(Config.KONDISI_KOMPONEN == ["ban", "rem", "rantai"], "id komponen permanen ban, rem, rantai (M-1; setang dan lampu dicadangkan, tidak dipakai)")
	check(Config.KONDISI_AMBANG_AUS == AMBANG_AUS and Config.KONDISI_AMBANG_PERLU_BENGKEL == AMBANG_PERLU, "ambang AUS 0,70 dan PERLU_BENGKEL 0,35 (BALANCING 8)")
	check(Config.KONDISI_AMBANG_AUS > Config.KONDISI_AMBANG_PERLU_BENGKEL and Config.KONDISI_AMBANG_PERLU_BENGKEL > 0.0 and Config.KONDISI_AMBANG_AUS < 1.0, "0 < ambang efek < ambang peringatan < 1 (peringatan mendahului efek, prinsip 3)")
	check(Config.KONDISI_KOTAK_BAIK == 3 and Config.KONDISI_KOTAK_AUS == 2 and Config.KONDISI_KOTAK_PERLU_BENGKEL == 1, "kotak HUD 3 / 2 / 1 (DESIGN_SPEC 3.3)")
	check(Config.KONDISI_TABRAKAN_BOBOT.size() == Config.KONDISI_KOMPONEN.size() and Config.KONDISI_TABRAKAN_BOBOT == [50, 20, 30], "bobot tabrakan sejajar komponen: ban 50, rem 20, rantai 30 (M-4)")
	check(Config.KONDISI_TABRAKAN_KERUSAKAN == 0.3, "kerusakan satu tabrakan 0,30")
	check(Config.KONDISI_TABRAKAN_KERUSAKAN > 0.0 and Config.KONDISI_TABRAKAN_KERUSAKAN < Config.KONDISI_AMBANG_AUS - Config.KONDISI_AMBANG_PERLU_BENGKEL, "satu tabrakan lebih kecil dari lebar tingkat AUS: tidak bisa melompati AUS (M-4)")
	check(Config.KONDISI_EFEK_LANTAI > 0.0 and Config.KONDISI_EFEK_LANTAI < 1.0, "lantai pengali efek di antara 0 dan 1")
	for nilai: float in [Config.KONDISI_EFEK_BAN_KECEPATAN_MIN, Config.KONDISI_EFEK_BAN_LATERAL_MIN, Config.KONDISI_EFEK_REM_MIN, Config.KONDISI_EFEK_RANTAI_AKSELERASI_MIN]:
		check(nilai >= Config.KONDISI_EFEK_LANTAI and nilai < 1.0, "pengali terburuk %s di antara lantai dan 1,0 (hanya menghambat)" % nilai)
	check(Config.KONDISI_EFEK_RANTAI_PUNCAK_MIN_UD >= Config.KECEPATAN_SANTAI_UD and Config.KONDISI_EFEK_RANTAI_PUNCAK_MIN_UD < Config.KECEPATAN_NGEBUT_UD, "batas puncak rantai putus tidak di bawah santai dan di bawah ngebut (M-6)")
	check(Config.KONDISI_CADANGAN_TENGGAT_DETIK == 2.0 and Config.KONDISI_REM_JARAK_MAKS_UBIN == 9.0, "cadangan tenggat 2,0 detik dan jarak berhenti rem blong paling jauh 9,0 ubin (2,5 kali 3,6)")
	check(Config.KONDISI_PERINGATAN_JEDA_DETIK == 6.0 and Config.KONDISI_PERINGATAN_KECEPATAN_MIN_UD == 3.0, "jeda peringatan 6,0 detik; ban dan rantai memperingatkan mulai santai 3,0 u/d")
	# Koefisien aus: ngebut jauh di atas santai (prinsip 1), santai kecil tetapi bukan nol.
	for pasangan: Array in [[Config.KONDISI_AUS_BAN_SANTAI_PER_UBIN, Config.KONDISI_AUS_BAN_CEPAT_PER_UBIN, Config.KONDISI_AUS_BAN_NGEBUT_PER_UBIN], [Config.KONDISI_AUS_RANTAI_SANTAI_PER_UBIN, Config.KONDISI_AUS_RANTAI_CEPAT_PER_UBIN, Config.KONDISI_AUS_RANTAI_NGEBUT_PER_UBIN]]:
		check(pasangan[0] > 0.0 and pasangan[0] < pasangan[1] and pasangan[1] < pasangan[2] and pasangan[2] >= 2.0 * pasangan[0], "aus per ubin: 0 < santai < cepat < ngebut dan ngebut >= 2x santai: %s" % [pasangan])
	check(Config.KONDISI_AUS_REM_PER_PENGEREMAN > 0.0 and Config.KONDISI_AUS_REM_PER_DETIK > 0.0, "rem aus tiap pengereman dan tiap detik rem aktif (> 0)")
	check(Config.KONDISI_PEMBULATAN_PEMBAGI == 10000.0, "kondisi di save dibulatkan 4 desimal")


# --- Tingkat dan kotak (AC-5) ---

func _test_tingkat_sapuan() -> void:
	_judul.call("BikeCondition: tingkat dan kotak dari ambang, sapuan 0,00..1,00 langkah 0,01 (AC-5)")
	var rank_terakhir: int = 99
	var monoton: bool = true
	var kotak_terakhir: int = 99
	var kotak_monoton: bool = true
	var sama_oracle: bool = true
	var kotak_oracle: bool = true
	for i: int in range(100, -1, -1):
		var k: float = float(i) / 100.0
		# Oracle: perbandingan langsung terhadap literal 0,70 dan 0,35.
		var harapan: BikeCondition.Tingkat = BikeCondition.Tingkat.PERLU_BENGKEL
		if k >= AMBANG_AUS:
			harapan = BikeCondition.Tingkat.BAIK
		elif k >= AMBANG_PERLU:
			harapan = BikeCondition.Tingkat.AUS
		var nyata: BikeCondition.Tingkat = BikeCondition.tingkat(k)
		if nyata != harapan:
			sama_oracle = false
		var rank: int = int(nyata)
		if rank_terakhir != 99 and rank < rank_terakhir:
			monoton = false
		rank_terakhir = rank
		var kotak: int = BikeCondition.kotak_terisi(k)
		var kotak_harapan: int = 3 if harapan == BikeCondition.Tingkat.BAIK else (2 if harapan == BikeCondition.Tingkat.AUS else (1 if k > 0.0 else 0))
		if kotak != kotak_harapan:
			kotak_oracle = false
		if kotak_terakhir != 99 and kotak > kotak_terakhir:
			kotak_monoton = false
		kotak_terakhir = kotak
	check(sama_oracle, "tingkat tiap kondisi 0,00..1,00 sama dengan oracle (BAIK >= 0,70; AUS >= 0,35; selebihnya PERLU_BENGKEL)")
	check(monoton, "tingkat monoton: kondisi turun tidak pernah membaik")
	check(kotak_oracle and kotak_monoton, "kotak terisi 3 / 2 / 1 (0 di kondisi 0) dan tidak bertambah saat kondisi turun")
	check(BikeCondition.tingkat(0.7) == BikeCondition.Tingkat.BAIK and BikeCondition.tingkat(0.6999) == BikeCondition.Tingkat.AUS, "ambang AUS inklusif: 0,70 BAIK, 0,6999 AUS")
	check(BikeCondition.tingkat(0.35) == BikeCondition.Tingkat.AUS and BikeCondition.tingkat(0.3499) == BikeCondition.Tingkat.PERLU_BENGKEL, "ambang PERLU_BENGKEL inklusif: 0,35 AUS, 0,3499 PERLU_BENGKEL")
	check(BikeCondition.tingkat(1.5) == BikeCondition.Tingkat.BAIK and BikeCondition.tingkat(-1.0) == BikeCondition.Tingkat.PERLU_BENGKEL and BikeCondition.tingkat(NAN) == BikeCondition.Tingkat.BAIK, "kondisi di luar 0..1 dijepit; NaN = baru")
	var campur: Dictionary = {"ban": 0.2, "rem": 0.9, "rantai": 0.0}
	check(BikeCondition.perlu_bengkel(campur) == ["ban", "rantai"], "perlu_bengkel: ban dan rantai (urut komponen)")
	check(BikeCondition.perlu_bengkel(BikeCondition.baru()).is_empty() and BikeCondition.perlu_bengkel({}).is_empty(), "sepeda baru dan kamus kosong: tidak ada yang perlu bengkel")


func _test_rapikan_dan_bulatkan() -> void:
	_judul.call("BikeCondition: rapikan dan pembulatan kondisi (AC-2, M-7)")
	var asal: Dictionary = {"ban": -3.0, "rem": 7, "rantai": "x", "setang": 0.1}
	var r: Dictionary = BikeCondition.rapikan(asal)
	check(r == {"ban": 0.0, "rem": 1.0, "rantai": 1.0}, "rapikan: dijepit 0..1, bukan angka = 1,0, id asing dibuang; dapat %s" % [r])
	check(asal == {"ban": -3.0, "rem": 7, "rantai": "x", "setang": 0.1}, "rapikan tidak mengubah masukan")
	check(BikeCondition.rapikan({}) == BikeCondition.baru() and BikeCondition.baru() == {"ban": 1.0, "rem": 1.0, "rantai": 1.0}, "kamus kosong = sepeda baru")
	check(BikeCondition.jepit(INF) == 1.0 and BikeCondition.jepit(-INF) == 0.0 and BikeCondition.jepit(NAN) == 1.0, "tak hingga dijepit, NaN = 1,0")
	check(BikeCondition.bulatkan(0.123456) == 0.1235 and BikeCondition.bulatkan(0.30000000000000004) == 0.3 and BikeCondition.bulatkan(0.99996) == 1.0, "bulatkan: 4 desimal (0,1235; 0,3; 0,99996 jadi 1,0)")
	check(JSON.stringify({"k": BikeCondition.bulatkan(0.30000000000000004)}) == '{"k":0.3}', "kondisi terbulatkan tercetak 0.3 di JSON (teks save stabil)")


# --- Aus (AC-6) ---

func _test_aus_titik_patah() -> void:
	_judul.call("BikeCondition.aus: tarif per ubin di titik patah kecepatan, dihitung tangan (AC-6)")
	# Oracle tangan dari koefisien Config: santai 3,0 -> 0,00015 / 0,00011; cepat 4,5 -> 0,0003; ngebut 6,0 -> 0,0006 / 0,0007.
	var kasus: Array = [
		[0.0, 0.0, 0.0],
		[1.5, 0.00015 / 2.0, 0.00011 / 2.0],
		[3.0, 0.00015, 0.00011],
		[4.5, 0.0003, 0.0003],
		[5.25, (0.0003 + 0.0006) / 2.0, (0.0003 + 0.0007) / 2.0],
		[6.0, 0.0006, 0.0007],
		[9.0, 0.0006, 0.0007],
	]
	for baris: Array in kasus:
		check(absf(BikeCondition.aus_per_ubin("ban", baris[0]) - baris[1]) < TOLERANSI, "ban %s u/d: %s per ubin, dapat %s" % [baris[0], baris[1], BikeCondition.aus_per_ubin("ban", baris[0])])
		check(absf(BikeCondition.aus_per_ubin("rantai", baris[0]) - baris[2]) < TOLERANSI, "rantai %s u/d: %s per ubin, dapat %s" % [baris[0], baris[2], BikeCondition.aus_per_ubin("rantai", baris[0])])
	check(BikeCondition.aus_per_ubin("rem", 4.0) == 0.0 and BikeCondition.aus_per_ubin("setang", 4.0) == 0.0, "rem dan komponen asing tidak aus per ubin")
	check(BikeCondition.aus_per_ubin("ban", NAN) == 0.0 and BikeCondition.aus_per_ubin("ban", -2.0) == 0.0 and BikeCondition.aus_per_ubin("ban", INF) == 0.0, "kecepatan tidak sah = 0")
	# Aus satu langkah: 3,0 u/d selama satu detik = 3 ubin.
	var k: Dictionary = BikeCondition.aus(BikeCondition.baru(), _tele(3.0, 1.0, 3.0))
	check(absf(float(k["ban"]) - (1.0 - 3.0 * 0.00015)) < TOLERANSI and absf(float(k["rantai"]) - (1.0 - 3.0 * 0.00011)) < TOLERANSI and k["rem"] == 1.0, "tiga ubin pada santai: ban 1 - 3 x 0,00015, rantai 1 - 3 x 0,00011, rem utuh; dapat %s" % [k])
	var tanpa_dt: Dictionary = BikeCondition.aus({"ban": 0.5, "rem": 0.5, "rantai": 0.5}, _tele(3.0, 0.0, 3.0, true, true))
	check(tanpa_dt == {"ban": 0.5, "rem": 0.5, "rantai": 0.5}, "dt nol (jeda game) tidak aus walau rem aktif")
	for dt_buruk: float in [-1.0, NAN, INF]:
		check(BikeCondition.aus({"ban": 0.5, "rem": 0.5, "rantai": 0.5}, _tele(3.0, dt_buruk, 3.0)) == {"ban": 0.5, "rem": 0.5, "rantai": 0.5}, "dt %s tidak aus" % dt_buruk)
	var bawah: Dictionary = BikeCondition.aus({"ban": 0.0001, "rem": 0.0, "rantai": 0.0}, _tele(30.0, 1.0, 6.0, true, true))
	check(bawah["ban"] == 0.0 and bawah["rem"] == 0.0 and bawah["rantai"] == 0.0, "kondisi tidak pernah di bawah 0")
	# Pengali aus upgrade memperlambat tetapi tidak meniadakan.
	var lambat: Dictionary = BikeCondition.aus(BikeCondition.baru(), _tele(3.0, 1.0, 3.0), {"ban": 0.5})
	check(absf(float(lambat["ban"]) - (1.0 - 3.0 * 0.00015 * 0.5)) < TOLERANSI and absf(float(lambat["rantai"]) - float(k["rantai"])) < TOLERANSI, "pengali aus ban 0,5 menghemat separuh aus ban saja")


func _rekam_telemetri(profil: String, detik: float) -> Array[Dictionary]:
	var catatan: Array[Dictionary] = []
	var s: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
	var t: float = 0.0
	while t < detik:
		var h: BikeMotion.Hasil = BikeMotion.langkah(s, SimProfilKondisi.stick(profil, s, t), DT)
		catatan.append({"dt": DT, "maju": h.maju_ubin, "v_awal": h.kecepatan_awal_ud, "rem_aktif": h.keadaan.rem_aktif, "rem_mulai": h.rem_mulai})
		s = h.keadaan
		t += DT
	return catatan


func _test_aus_telemetri_nyata_vs_tangan() -> void:
	_judul.call("BikeCondition.aus: telemetri BikeMotion nyata = telemetri tulisan tangan, deterministik, tanpa menghitung ulang gerak (AC-6)")
	for profil: String in ["santai", "campuran", "ngebut"]:
		var catatan: Array[Dictionary] = _rekam_telemetri(profil, 60.0)
		var dari_nyata: Dictionary = BikeCondition.baru()
		var dari_tangan: Dictionary = BikeCondition.baru()
		var s: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
		var t: float = 0.0
		for c: Dictionary in catatan:
			var h: BikeMotion.Hasil = BikeMotion.langkah(s, SimProfilKondisi.stick(profil, s, t), DT)
			dari_nyata = BikeCondition.aus(dari_nyata, BikeCondition.telemetri(h, DT))
			dari_tangan = BikeCondition.aus(dari_tangan, _tele(float(c["maju"]), float(c["dt"]), float(c["v_awal"]), bool(c["rem_aktif"]), bool(c["rem_mulai"])))
			s = h.keadaan
			t += DT
		check(dari_nyata == dari_tangan, "profil %s 60 detik: aus dari Hasil nyata = aus dari telemetri tulisan tangan; dapat %s dan %s" % [profil, dari_nyata, dari_tangan])
		var ulang: Dictionary = BikeCondition.baru()
		for c: Dictionary in catatan:
			ulang = BikeCondition.aus(ulang, _tele(float(c["maju"]), float(c["dt"]), float(c["v_awal"]), bool(c["rem_aktif"]), bool(c["rem_mulai"])))
		check(ulang == dari_tangan, "profil %s: urutan telemetri sama menghasilkan aus sama persis (deterministik)" % profil)
	# Mode bantu mengunci kecepatan santai (stick netral): aus profil santai di scene bantu = aus telemetri santai (K-2, AC-11).
	var bantu: Dictionary = SimProfilKondisi.jalankan_rute("santai", 100.0, BikeCondition.baru(), false).kondisi
	check(absf(float(bantu["ban"]) - (1.0 - 100.0 * 0.00015)) < 0.00001 and absf(float(bantu["rantai"]) - (1.0 - 100.0 * 0.00011)) < 0.00001 and bantu["rem"] == 1.0, "santai 100 ubin: ban 1 - 100 x 0,00015, rantai 1 - 100 x 0,00011, rem utuh (sama untuk mode bantu); dapat %s" % [bantu])


func _test_aus_urutan_dan_rem() -> void:
	_judul.call("BikeCondition.aus: urutan ngebut > cepat > santai > 0, rem hanya aus saat dipakai, lepas stick sebelum 0,25 detik tidak dihitung (AC-6)")
	var sebelum: Dictionary = BikeCondition.baru()
	for kom: String in ["ban", "rantai"]:
		var hasil: Array[float] = []
		for v: float in [1.5, 3.0, 4.5, 6.0]:
			var k: Dictionary = BikeCondition.aus(sebelum, _tele(v * 10.0, 10.0, v))
			hasil.append(1.0 - float(k[kom]))
		check(hasil[0] > 0.0 and hasil[0] < hasil[1] and hasil[1] < hasil[2] and hasil[2] < hasil[3], "%s: aus per 10 detik naik tegas 1,5 < 3,0 < 4,5 < 6,0 u/d, dapat %s" % [kom, hasil])
		# Per ubin yang sama (100 ubin): rasio ngebut / santai >= 2,0, oracle tanpa angka tabel.
		var santai: float = 1.0 - float(BikeCondition.aus(sebelum, _tele(100.0, 100.0 / 3.0, 3.0))[kom])
		var ngebut: float = 1.0 - float(BikeCondition.aus(sebelum, _tele(100.0, 100.0 / 6.0, 6.0))[kom])
		check(santai > 0.0 and ngebut / santai >= 2.0, "%s: 100 ubin ngebut aus >= 2x santai (rasio %s) dan santai bukan nol" % [kom, ngebut / santai if santai > 0.0 else -1.0])
		# Sama untuk jarak sama walau dt dipecah.
		var terpecah: Dictionary = sebelum
		for i: int in range(100):
			terpecah = BikeCondition.aus(terpecah, _tele(1.0, 1.0 / 6.0, 6.0))
		check(absf(float(terpecah[kom]) - float(BikeCondition.aus(sebelum, _tele(100.0, 100.0 / 6.0, 6.0))[kom])) < 0.000001, "%s: aus tidak bergantung pada pembagian dt (jarak dan kecepatan sama)" % kom)
	# Rem: tanpa rem aktif tidak aus sama sekali.
	var tanpa_rem: Dictionary = BikeCondition.baru()
	for i: int in range(1000):
		tanpa_rem = BikeCondition.aus(tanpa_rem, _tele(0.1, DT, 6.0))
	check(tanpa_rem["rem"] == 1.0, "1000 langkah ngebut tanpa rem aktif: kondisi rem tetap 1,0 persis")
	check(SimProfilKondisi.jalankan_rute("santai", 236.0, BikeCondition.baru()).kondisi["rem"] == 1.0, "satu rute santai penuh (BikeMotion nyata): rem tetap 1,0 persis")
	var diam: Dictionary = BikeCondition.aus(BikeCondition.baru(), _tele(0.0, 1.0, 0.0, true, false))
	check(diam["rem"] == 1.0, "rem aktif saat sepeda sudah diam (kecepatan awal 0) tidak aus")
	# Pulsa tarik ke bawah dari 4,5 u/d dengan BikeMotion nyata.
	for pulsa: Array in [[0.1, false], [0.2, false], [0.3, true], [0.5, true], [2.0, true]]:
		var s: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
		s.kecepatan_ud = 4.5
		var k: Dictionary = BikeCondition.baru()
		var mulai: int = 0
		var t: float = 0.0
		while t < 3.0:
			var stick: Vector2 = Vector2(0.0, -1.0) if t < float(pulsa[0]) else Vector2.ZERO
			var h: BikeMotion.Hasil = BikeMotion.langkah(s, stick, DT)
			if h.rem_mulai:
				mulai += 1
			k = BikeCondition.aus(k, BikeCondition.telemetri(h, DT))
			s = h.keadaan
			t += DT
		var aus_rem: bool = float(k["rem"]) < 1.0
		check(aus_rem == bool(pulsa[1]), "tarik ke bawah %s detik: rem %s (ambang tahan 0,25 detik); kondisi rem %s" % [pulsa[0], "aus" if pulsa[1] else "tidak aus", k["rem"]])
		check(mulai == (1 if bool(pulsa[1]) else 0), "tarik ke bawah %s detik: tepi naik rem tepat %d kali, dapat %d" % [pulsa[0], 1 if pulsa[1] else 0, mulai])
	# Dua pengereman terpisah = dua tepi naik.
	var s2: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
	s2.kecepatan_ud = 6.0
	var mulai2: int = 0
	var t2: float = 0.0
	while t2 < 8.0:
		var tarik: bool = (t2 >= 0.0 and t2 < 0.6) or (t2 >= 4.0 and t2 < 4.6)
		var h2: BikeMotion.Hasil = BikeMotion.langkah(s2, Vector2(0.0, -1.0) if tarik else Vector2(0.0, 1.0), DT)
		if h2.rem_mulai:
			mulai2 += 1
		s2 = h2.keadaan
		t2 += DT
	check(mulai2 == 2, "dua pengereman terpisah menghasilkan dua tepi naik rem, dapat %d" % mulai2)
	# Satu pengereman memakan: per pengereman + per detik (oracle tangan).
	var satu: Dictionary = BikeCondition.aus(BikeCondition.baru(), _tele(1.0, 0.5, 4.0, true, true))
	check(absf(float(satu["rem"]) - (1.0 - 0.006 - 0.01 * 0.5)) < TOLERANSI, "satu langkah rem mulai 0,5 detik: 1 - 0,006 - 0,01 x 0,5, dapat %s" % satu["rem"])


func _test_kecepatan_awal_telemetri() -> void:
	_judul.call("BikeMotion.Hasil.kecepatan_awal_ud adalah kecepatan SEBELUM langkah; aus rem per detik pada langkah pengereman yang berakhir di 0 tetap dihitung (QA-006, QM13)")
	var s: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
	s.kecepatan_ud = 4.5
	var rusak_urutan: int = 0
	var langkah_henti: BikeMotion.Hasil = null
	var sebelum_henti: BikeMotion.Keadaan = null
	for i: int in range(240):
		var h: BikeMotion.Hasil = BikeMotion.langkah(s, Vector2(0.0, -1.0), DT)
		if h.kecepatan_awal_ud != s.kecepatan_ud:
			rusak_urutan += 1
		if langkah_henti == null and h.keadaan.kecepatan_ud == 0.0 and s.kecepatan_ud > 0.0:
			langkah_henti = h
			sebelum_henti = s
		s = h.keadaan
	check(rusak_urutan == 0, "240 langkah tarik ke bawah dari 4,5 u/d: kecepatan_awal_ud tiap langkah = kecepatan keadaan sebelum langkah (bukan sesudahnya); langkah menyimpang %d" % rusak_urutan)
	check(langkah_henti != null, "kontrol: pengereman dari 4,5 u/d berakhir di 0 dalam 4 detik")
	if langkah_henti == null:
		return
	check(langkah_henti.kecepatan_awal_ud == sebelum_henti.kecepatan_ud and langkah_henti.kecepatan_awal_ud > 0.0 and langkah_henti.keadaan.rem_aktif, "langkah yang berakhir di 0: kecepatan awal %s > 0 dan rem aktif" % langkah_henti.kecepatan_awal_ud)
	var aus: Dictionary = BikeCondition.aus(BikeCondition.baru(), BikeCondition.telemetri(langkah_henti, DT))
	check(absf((1.0 - float(aus["rem"])) - Config.KONDISI_AUS_REM_PER_DETIK * DT) < TOLERANSI, "langkah pengereman yang berakhir di 0: rem aus tepat 0,01 x dt (%s), dapat %s" % [Config.KONDISI_AUS_REM_PER_DETIK * DT, 1.0 - float(aus["rem"])])


# --- Tabrakan (AC-7) ---

func _test_tabrakan_komponen() -> void:
	_judul.call("BikeCondition.komponen_tabrakan: deterministik dari (hari, nomor), sebaran mendekati bobot Config (AC-7)")
	check(BikeCondition.komponen_tabrakan(7, 0) == BikeCondition.komponen_tabrakan(7, 0) and BikeCondition.komponen_tabrakan(7, 3) == BikeCondition.komponen_tabrakan(7, 3), "hari dan nomor sama = komponen sama")
	var hitung: Dictionary = {"ban": 0, "rem": 0, "rantai": 0}
	var beda_nomor: bool = false
	var beda_hari: bool = false
	for hari: int in range(1, 1001):
		for nomor: int in range(10):
			hitung[BikeCondition.komponen_tabrakan(hari, nomor)] += 1
		if BikeCondition.komponen_tabrakan(hari, 0) != BikeCondition.komponen_tabrakan(hari, 1):
			beda_nomor = true
		if BikeCondition.komponen_tabrakan(hari, 0) != BikeCondition.komponen_tabrakan(hari + 1, 0):
			beda_hari = true
	var total: float = 10000.0
	# Toleransi tertulis: tiga poin persen dari 10000 sampel (simpangan baku sekitar 0,5 poin persen).
	check(absf(float(hitung["ban"]) / total - 0.5) < 0.03 and absf(float(hitung["rem"]) / total - 0.2) < 0.03 and absf(float(hitung["rantai"]) / total - 0.3) < 0.03, "10000 tabrakan: sebaran ban 50%% / rem 20%% / rantai 30%% dengan toleransi 3 poin persen, dapat %s" % [hitung])
	check(beda_nomor and beda_hari, "nomor tabrakan berbeda dan hari berbeda memberi pilihan berbeda (bukan satu nilai tetap)")


## Satu tabrakan nyata dari `Tabrakan.langkah`: hasil dengan `tabrak` true dan `jumlah` 1.
func _hasil_tabrak() -> Tabrakan.Hasil:
	var kotak: Rect2 = Tabrakan.kotak_sepeda(0.0, 0.0)
	var daftar: Array[Tabrakan.Kandidat] = [Tabrakan.kandidat(1, "anjing_penjaga", kotak)]
	return Tabrakan.langkah(Tabrakan.awal(), kotak, daftar, DT)


func _test_tabrakan_satu_pengurangan() -> void:
	_judul.call("BikeCondition.tabrakan: satu tabrakan = satu pengurangan, jatuh, kebal, dan menempel tidak menggandakan, urutan Tabrakan.langkah nyata (AC-7)")
	var kotak: Rect2 = Tabrakan.kotak_sepeda(0.0, 0.0)
	var jauh: Rect2 = Tabrakan.kotak_sepeda(50.0, 0.0)
	var hari: int = 5
	# Skenario: rintangan A menempel 10 detik; A pergi; rintangan B di detik 14; C muncul saat kebal B (detik 16,0 sampai 16,4) dan menempel sampai detik 22.
	var t: Tabrakan.Keadaan = Tabrakan.awal()
	var kondisi: Dictionary = BikeCondition.baru()
	var jumlah_tabrak: int = 0
	var langkah: int = 0
	var total_langkah: int = 24 * 60
	while langkah < total_langkah:
		var detik: float = float(langkah) * DT
		var daftar: Array[Tabrakan.Kandidat] = [Tabrakan.kandidat(9, "anjing_penjaga", jauh)]
		if detik < 10.0:
			daftar.append(Tabrakan.kandidat(1, "anjing_penjaga", kotak))
		if detik >= 14.0 and detik < 16.4:
			daftar.append(Tabrakan.kandidat(2, "mobil_garasi", kotak))
		if detik >= 16.0 and detik < 22.0:
			daftar.append(Tabrakan.kandidat(3, "anjing_penjaga", kotak))
		var h: Tabrakan.Hasil = Tabrakan.langkah(t, kotak, daftar, DT)
		t = h.keadaan
		if h.tabrak:
			jumlah_tabrak += 1
		kondisi = BikeCondition.tabrakan(kondisi, hari, h)
		langkah += 1
	# B (id 2) menabrak di 14,0, bangun 15,2, kebal sampai 16,2; C (id 3) muncul di 16,0 saat masih kebal lalu menempel sampai 22,0: tidak menabrak lagi.
	check(jumlah_tabrak == 2, "A (menempel 10 detik) satu tabrakan, B satu tabrakan, C muncul saat kebal dan menempel: total 2 tabrakan, dapat %d" % jumlah_tabrak)
	check(t.jumlah == 2, "Tabrakan.Keadaan.jumlah = 2")
	var berkurang: float = 0.0
	for kom: String in Config.KONDISI_KOMPONEN:
		berkurang += 1.0 - float(kondisi[kom])
	check(absf(berkurang - 2.0 * 0.3) < 0.000001, "dua tabrakan mengurangi tepat 2 x 0,30 kondisi seluruhnya, dapat %s dari %s" % [berkurang, kondisi])
	# Tanpa tabrak: tidak ada perubahan; masukan tidak berubah.
	var tidak: Tabrakan.Hasil = Tabrakan.langkah(Tabrakan.awal(), jauh, [Tabrakan.kandidat(1, "x", kotak)], DT)
	var awal: Dictionary = {"ban": 0.9, "rem": 0.8, "rantai": 0.7}
	check(not tidak.tabrak and BikeCondition.tabrakan(awal, hari, tidak) == awal, "tanpa tabrakan baru kondisi tidak berubah")
	var satu: Tabrakan.Hasil = _hasil_tabrak()
	var asli: Dictionary = awal.duplicate()
	var sesudah: Dictionary = BikeCondition.tabrakan(awal, hari, satu)
	var diubah: Array[String] = []
	for kom: String in Config.KONDISI_KOMPONEN:
		if sesudah[kom] != awal[kom]:
			diubah.append(kom)
	check(satu.tabrak and satu.keadaan.jumlah == 1 and diubah.size() == 1 and diubah[0] == BikeCondition.komponen_tabrakan(hari, 0), "satu tabrakan: tepat satu komponen berubah, yaitu komponen yang dipilih seed hari + nomor 0; dapat %s" % [diubah])
	check(awal == asli, "tabrakan tidak mengubah kamus masukan")
	check(absf(float(sesudah[diubah[0]]) - (float(awal[diubah[0]]) - 0.3)) < 0.000001, "pengurangan sebesar KONDISI_TABRAKAN_KERUSAKAN 0,30")
	# Kondisi 0 tetap 0.
	var nol: Dictionary = BikeCondition.tabrakan(_kondisi_semua(0.0), hari, satu)
	check(nol == _kondisi_semua(0.0), "kondisi 0 tetap 0 (clamp)")
	# Nomor tabrakan = jumlah - 1 memilih komponen berbeda untuk tabrakan kedua (bila seed beda).
	var kedua: Tabrakan.Hasil = _hasil_tabrak()
	kedua.keadaan.jumlah = 4
	var k4: Dictionary = BikeCondition.tabrakan(BikeCondition.baru(), hari, kedua)
	check(float(k4[BikeCondition.komponen_tabrakan(hari, 3)]) < 1.0, "tabrakan keempat (jumlah 4) memakai nomor 3 untuk memilih komponen")


func _test_tabrakan_tidak_melompati_aus() -> void:
	_judul.call("BikeCondition.tabrakan: tidak pernah BAIK langsung ke PERLU_BENGKEL, kisi 0,01 semua komponen (M-4, AC-7)")
	var satu: Tabrakan.Hasil = _hasil_tabrak()
	var pelanggaran: Array[String] = []
	var dicoba: int = 0
	var komponen_terlihat: Dictionary = {}
	for hari: int in range(1, 31):
		var kom: String = BikeCondition.komponen_tabrakan(hari, 0)
		komponen_terlihat[kom] = true
		for i: int in range(101):
			var k: float = float(i) / 100.0
			var awal: Dictionary = _kondisi_semua(k)
			var sesudah: Dictionary = BikeCondition.tabrakan(awal, hari, satu)
			dicoba += 1
			if BikeCondition.tingkat(k) == BikeCondition.Tingkat.BAIK and BikeCondition.tingkat(float(sesudah[kom])) == BikeCondition.Tingkat.PERLU_BENGKEL:
				pelanggaran.append("hari %d %s k=%s -> %s" % [hari, kom, k, sesudah[kom]])
			if float(sesudah[kom]) > k or float(sesudah[kom]) < 0.0:
				pelanggaran.append("hari %d %s k=%s kondisi %s di luar jangkauan" % [hari, kom, k, sesudah[kom]])
	check(komponen_terlihat.size() == 3, "30 hari uji menjangkau ketiga komponen (ban, rem, rantai)")
	check(dicoba == 30 * 101 and pelanggaran.is_empty(), "%d kombinasi kondisi x hari: tidak ada BAIK -> PERLU_BENGKEL dalam satu tabrakan: %s" % [dicoba, pelanggaran.slice(0, 3)])
	# Dari BAIK terendah (0,70) satu tabrakan jatuh ke AUS (0,40), bukan PERLU_BENGKEL.
	var dari_baik: Dictionary = BikeCondition.tabrakan(_kondisi_semua(0.7), 3, satu)
	var terpilih: String = BikeCondition.komponen_tabrakan(3, 0)
	check(BikeCondition.tingkat(float(dari_baik[terpilih])) == BikeCondition.Tingkat.AUS, "dari 0,70 (BAIK terendah) satu tabrakan berakhir di AUS, bukan PERLU_BENGKEL; dapat %s" % dari_baik[terpilih])


# --- Peringatan (AC-8) ---

func _pakai(v: float, rem: bool) -> BikeCondition.Pemakaian:
	var p: BikeCondition.Pemakaian = BikeCondition.Pemakaian.new()
	p.kecepatan_ud = v
	p.rem_aktif = rem
	return p


func _test_peringatan() -> void:
	_judul.call("BikeCondition.langkah_peringatan: tidak di BAIK, tepat saat dipakai di AUS, jeda ditegakkan, tidak palsu, beku saat jeda game (AC-8, M-5)")
	# BAIK: tidak pernah, walau dipakai penuh.
	for k: float in [1.0, 0.9, 0.7]:
		var status: BikeCondition.StatusPeringatan = BikeCondition.status_peringatan_awal()
		var jumlah: int = 0
		for i: int in range(10000):
			var p: BikeCondition.HasilPeringatan = BikeCondition.langkah_peringatan(status, _kondisi_semua(k), _pakai(6.0, true), DT)
			status = p.status
			jumlah += p.komponen.size()
		check(jumlah == 0, "kondisi %s (BAIK) dipakai 10000 langkah: nol peringatan" % k)
	# AUS dan PERLU_BENGKEL dipakai: langsung di langkah pertama, jeda ditegakkan.
	for k: float in [0.69, 0.5, 0.35, 0.34, 0.0]:
		var status2: BikeCondition.StatusPeringatan = BikeCondition.status_peringatan_awal()
		var waktu: Dictionary = {}
		var t: float = 0.0
		for i: int in range(10000):
			t += DT
			var p2: BikeCondition.HasilPeringatan = BikeCondition.langkah_peringatan(status2, _kondisi_semua(k), _pakai(6.0, true), DT)
			status2 = p2.status
			for kom: String in p2.komponen:
				if not waktu.has(kom):
					waktu[kom] = []
				(waktu[kom] as Array).append(t)
		var rapi: bool = waktu.size() == 3
		var pertama_langsung: bool = true
		var jeda_ok: bool = true
		for kom: String in waktu:
			var daftar: Array = waktu[kom]
			if absf(float(daftar[0]) - DT) > 0.000001:
				pertama_langsung = false
			for j: int in range(1, daftar.size()):
				if float(daftar[j]) - float(daftar[j - 1]) < Config.KONDISI_PERINGATAN_JEDA_DETIK - 0.000001:
					jeda_ok = false
			if daftar.size() < 25 or daftar.size() > 29:
				rapi = false
		check(rapi and pertama_langsung and jeda_ok, "kondisi %s dipakai 10000 langkah (167 detik): tiap komponen memperingatkan di langkah pertama lalu tiap >= 6 detik (sekitar 28 kali)" % k)
	# Tidak dipakai: tidak ada peringatan palsu.
	var status3: BikeCondition.StatusPeringatan = BikeCondition.status_peringatan_awal()
	var palsu: int = 0
	for i: int in range(3000):
		var p3: BikeCondition.HasilPeringatan = BikeCondition.langkah_peringatan(status3, _kondisi_semua(0.2), _pakai(0.0, false), DT)
		status3 = p3.status
		palsu += p3.komponen.size()
	check(palsu == 0, "komponen aus yang tidak dipakai (diam, tanpa rem): nol peringatan palsu")
	var p4: BikeCondition.HasilPeringatan = BikeCondition.langkah_peringatan(BikeCondition.status_peringatan_awal(), _kondisi_semua(0.5), _pakai(5.0, false), DT)
	check(p4.komponen == ["ban", "rantai"], "melaju tanpa rem: hanya ban mendesis dan rantai berisik, rem diam; dapat %s" % [p4.komponen])
	var p5: BikeCondition.HasilPeringatan = BikeCondition.langkah_peringatan(BikeCondition.status_peringatan_awal(), _kondisi_semua(0.5), _pakai(2.0, true), DT)
	check(p5.komponen == ["rem"], "rem aktif di bawah santai: hanya rem berdecit; dapat %s" % [p5.komponen])
	var p6: BikeCondition.HasilPeringatan = BikeCondition.langkah_peringatan(BikeCondition.status_peringatan_awal(), {"ban": 0.5, "rem": 1.0, "rantai": 1.0}, _pakai(5.0, true), DT)
	check(p6.komponen == ["ban"], "hanya komponen yang aus yang memperingatkan; dapat %s" % [p6.komponen])
	# Jeda game (dt 0, negatif, NaN, tak hingga): tidak ada peringatan dan waktu tidak maju.
	var status7: BikeCondition.StatusPeringatan = BikeCondition.status_peringatan_awal()
	for dt_buruk: float in [0.0, -1.0, NAN, INF]:
		var p7: BikeCondition.HasilPeringatan = BikeCondition.langkah_peringatan(status7, _kondisi_semua(0.2), _pakai(6.0, true), dt_buruk)
		check(p7.komponen.is_empty() and p7.status.sejak_detik == status7.sejak_detik, "dt %s: tidak ada peringatan dan waktu beku" % dt_buruk)
	# Masukan tidak berubah.
	var awal: BikeCondition.StatusPeringatan = BikeCondition.status_peringatan_awal()
	var salinan: Dictionary = awal.sejak_detik.duplicate()
	BikeCondition.langkah_peringatan(awal, _kondisi_semua(0.2), _pakai(6.0, true), 1.0)
	check(awal.sejak_detik == salinan, "langkah_peringatan tidak mengubah status masukan")


# --- Efek (AC-9, AC-10a bagian murni) ---

func _daftar_pengali(e: EfekKondisi) -> Array[float]:
	return [e.pengali_akselerasi, e.pengali_kecepatan, e.pengali_rem, e.pengali_lateral]


func _test_efek_sapuan() -> void:
	_judul.call("BikeCondition.efek: rentang, monoton, tepat 1,0 di atas ambang efek, peringatan mendahului efek pertama (AC-5, AC-10a)")
	var terakhir: Array[float] = [0.0, 0.0, 0.0, 0.0]
	var puncak_terakhir: float = 0.0
	var di_rentang: bool = true
	var monoton: bool = true
	var identitas_atas: bool = true
	var menghambat_bawah: bool = true
	for i: int in range(0, 101):
		var k: float = float(i) / 100.0
		var e: EfekKondisi = BikeCondition.efek(_kondisi_semua(k))
		var pengali: Array[float] = _daftar_pengali(e)
		for j: int in range(pengali.size()):
			if pengali[j] < Config.KONDISI_EFEK_LANTAI - TOLERANSI or pengali[j] > 1.0:
				di_rentang = false
			if pengali[j] < terakhir[j] - TOLERANSI:
				monoton = false
			terakhir[j] = pengali[j]
		if e.batas_puncak_ud < Config.KECEPATAN_SANTAI_UD or e.batas_puncak_ud > Config.KECEPATAN_NGEBUT_UD:
			di_rentang = false
		if e.batas_puncak_ud < puncak_terakhir - TOLERANSI:
			monoton = false
		puncak_terakhir = e.batas_puncak_ud
		if k >= AMBANG_PERLU:
			if not e.identitas() or e.pengali_akselerasi != 1.0 or e.pengali_kecepatan != 1.0 or e.pengali_rem != 1.0 or e.pengali_lateral != 1.0 or e.batas_puncak_ud != Config.KECEPATAN_NGEBUT_UD:
				identitas_atas = false
		elif e.identitas() or e.pengali_akselerasi >= 1.0 or e.pengali_kecepatan >= 1.0 or e.pengali_rem >= 1.0 or e.pengali_lateral >= 1.0 or e.batas_puncak_ud >= Config.KECEPATAN_NGEBUT_UD:
			menghambat_bawah = false
	# Sapuan naik: efek pertama (kondisi terendah yang masih identitas ada di atas) terjadi di bawah ambang efek.
	var k_identitas_terendah: float = 1.0
	for i: int in range(100, -1, -1):
		if BikeCondition.efek(_kondisi_semua(float(i) / 100.0)).identitas():
			k_identitas_terendah = float(i) / 100.0
	check(di_rentang, "semua pengali di antara lantai dan 1,0; batas puncak di antara santai dan ngebut, untuk kondisi 0,00..1,00")
	check(monoton, "pengali monoton tidak turun terhadap kondisi (kondisi membaik = tidak lebih menghambat)")
	check(identitas_atas, "kondisi >= 0,35: semua pengali tepat 1,0 dan batas puncak tepat ngebut (efek tepat nol di atas ambang)")
	check(menghambat_bawah, "kondisi < 0,35: semua pengali kurang dari 1,0 (efek menghambat muncul)")
	check(k_identitas_terendah == AMBANG_PERLU and AMBANG_AUS > k_identitas_terendah, "kondisi identitas terendah = ambang efek 0,35 dan ambang peringatan 0,70 lebih tinggi: tanda AUS mendahului efek pertama")
	# Nilai terburuk di kondisi 0 (oracle tangan dari BALANCING 8).
	var nol: EfekKondisi = BikeCondition.efek(_kondisi_semua(0.0))
	check(absf(nol.pengali_kecepatan - 0.92) < TOLERANSI and absf(nol.pengali_lateral - 0.6) < TOLERANSI and absf(nol.pengali_rem - 0.4) < TOLERANSI and absf(nol.pengali_akselerasi - 0.35) < TOLERANSI and absf(nol.batas_puncak_ud - 3.6) < TOLERANSI, "kondisi 0: kecepatan x0,92, lateral x0,60, rem x0,40, akselerasi x0,35, puncak 3,6 u/d")
	# Pertengahan ramp (kondisi 0,175 = setengah ambang efek): linear dari 1,0 ke nilai terburuk (oracle tangan), tanpa lompatan di ambang.
	var tengah: EfekKondisi = BikeCondition.efek(_kondisi_semua(0.175))
	check(absf(tengah.pengali_kecepatan - 0.96) < TOLERANSI and absf(tengah.pengali_lateral - 0.8) < TOLERANSI and absf(tengah.pengali_rem - 0.7) < TOLERANSI and absf(tengah.pengali_akselerasi - 0.675) < TOLERANSI and absf(tengah.batas_puncak_ud - 4.8) < TOLERANSI, "kondisi 0,175: kecepatan x0,96, lateral x0,80, rem x0,70, akselerasi x0,675, puncak 4,8 u/d (setengah jalan, linear)")
	var dekat_ambang: EfekKondisi = BikeCondition.efek(_kondisi_semua(0.34))
	check(absf(dekat_ambang.pengali_kecepatan - (0.92 + 0.08 * 0.34 / 0.35)) < TOLERANSI and dekat_ambang.pengali_kecepatan > 0.99 and dekat_ambang.pengali_rem > 0.98, "kondisi 0,34 (tepat di bawah ambang efek 0,35): efek nyaris nol, tanpa lompatan (kecepatan %s)" % dekat_ambang.pengali_kecepatan)
	# Komponen berdiri sendiri: hanya komponennya yang berefek.
	var hanya_ban: EfekKondisi = BikeCondition.efek({"ban": 0.0, "rem": 1.0, "rantai": 1.0})
	check(hanya_ban.pengali_kecepatan < 1.0 and hanya_ban.pengali_lateral < 1.0 and hanya_ban.pengali_rem == 1.0 and hanya_ban.pengali_akselerasi == 1.0 and hanya_ban.batas_puncak_ud == Config.KECEPATAN_NGEBUT_UD, "hanya ban rusak: kecepatan tujuan dan lateral turun, rem dan rantai utuh")
	var hanya_rem: EfekKondisi = BikeCondition.efek({"ban": 1.0, "rem": 0.0, "rantai": 1.0})
	check(hanya_rem.pengali_rem < 1.0 and hanya_rem.pengali_kecepatan == 1.0 and hanya_rem.pengali_akselerasi == 1.0, "hanya rem rusak: hanya perlambatan rem turun")
	var hanya_rantai: EfekKondisi = BikeCondition.efek({"ban": 1.0, "rem": 1.0, "rantai": 0.0})
	check(hanya_rantai.pengali_akselerasi < 1.0 and hanya_rantai.batas_puncak_ud < Config.KECEPATAN_NGEBUT_UD and hanya_rantai.pengali_rem == 1.0 and hanya_rantai.pengali_kecepatan == 1.0, "hanya rantai rusak: akselerasi dan batas puncak turun")
	check(BikeCondition.efek(BikeCondition.baru()).identitas() and BikeCondition.efek({}).identitas(), "sepeda baru dan kamus kosong: efek identitas")


func _test_efek_upgrade_dan_masukan_aneh() -> void:
	_judul.call("BikeCondition.efek: pengali upgrade dikalikan, masukan tidak sah diabaikan (M-6, M-10)")
	var upg: Dictionary = {"pengali_rem": 1.2, "pengali_lateral": 1.15, "pengali_kuras_stamina": 0.85}
	var baru: EfekKondisi = BikeCondition.efek(BikeCondition.baru(), upg)
	check(absf(baru.pengali_rem - 1.2) < TOLERANSI and absf(baru.pengali_lateral - 1.15) < TOLERANSI and absf(baru.pengali_kuras_stamina - 0.85) < TOLERANSI, "sepeda baru dengan upgrade: rem 1,2, lateral 1,15, kuras stamina 0,85")
	check(baru.pengali_kecepatan == 1.0 and baru.batas_puncak_ud == Config.KECEPATAN_NGEBUT_UD and baru.pengali_akselerasi == 1.0, "upgrade tidak menaikkan kecepatan puncak (tanpa power creep) dan tidak mengubah kecepatan tujuan atau akselerasi")
	var rusak: EfekKondisi = BikeCondition.efek(_kondisi_semua(0.0), upg)
	check(absf(rusak.pengali_rem - 0.4 * 1.2) < TOLERANSI and absf(rusak.pengali_lateral - 0.6 * 1.15) < TOLERANSI, "kondisi 0 dengan upgrade: efek kerusakan dikali pengali upgrade")
	for buruk: Variant in [0.0, -2.0, NAN, INF, "abc", null]:
		var e: EfekKondisi = BikeCondition.efek(BikeCondition.baru(), {"pengali_rem": buruk, "pengali_lateral": buruk, "pengali_kuras_stamina": buruk})
		check(e.identitas(), "pengali upgrade tidak sah (%s) diabaikan = 1,0" % [buruk])
	check(BikeCondition.efek({"ban": NAN, "rem": "x", "rantai": -4.0}).pengali_akselerasi == BikeCondition.efek({"ban": 1.0, "rem": 1.0, "rantai": 0.0}).pengali_akselerasi, "kondisi tidak sah dirapikan dulu (NaN dan teks = 1,0, negatif = 0)")


func _test_seed() -> void:
	_judul.call("SeedHari.kondisi: nilai literal, murni, aliran sendiri (M-4)")
	check(SeedHari.kondisi(1) == 28182821 and SeedHari.kondisi(2) == 29182824 and SeedHari.kondisi(60) == 87182998, "seed kondisi hari 1, 2, 60 = 28182821, 29182824, 87182998 (27182818 + hari x 1000003)")
	check(SeedHari.kondisi(9) == SeedHari.kondisi(9) and SeedHari.kondisi(9) != SeedHari.kondisi(10), "hari sama seed sama, hari beda seed beda")
	var berbeda: bool = true
	for hari: int in range(1, 61):
		if SeedHari.kondisi(hari) == SeedHari.rute(hari) or SeedHari.kondisi(hari) == SeedHari.headline(hari) or SeedHari.kondisi(hari) == SeedHari.misi(hari):
			berbeda = false
	check(berbeda, "seed kondisi tidak sama dengan seed rute, headline, atau misi (aliran acak sendiri)")


func _test_sumber_tanpa_mode_bantu() -> void:
	_judul.call("Pemindai sumber: bike_condition.gd dan economy.gd tidak menyebut mode bantu (K-2, AC-11), tanpa Time/randi/node (AC-5)")
	for berkas: String in ["res://scripts/systems/bike_condition.gd", "res://scripts/systems/economy.gd", "res://scripts/systems/efek_kondisi.gd", "res://scripts/systems/data_toko.gd", "res://scripts/systems/pemuat_toko.gd"]:
		var teks: String = FileAccess.get_file_as_string(berkas)
		var kode: String = _tanpa_komentar(teks).to_lower()
		check(not teks.is_empty(), "%s terbaca" % berkas.get_file())
		check(not kode.contains("bantu"), "%s: kode tidak menyebut mode bantu (satu ekonomi untuk semua pemain)" % berkas.get_file())
		check(not kode.contains("randi(") and not kode.contains("randf(") and not kode.contains("time.") and not kode.contains("extends node"), "%s: tanpa randi/randf global, Time, atau Node (logika murni, rule gdscript)" % berkas.get_file())
		check(not kode.contains("adservice") and not kode.contains("iklan"), "%s: tanpa rujukan iklan (AC-16)" % berkas.get_file())
	var contoh: String = "var x = 1 # bantu\n## bantu"
	check(not _tanpa_komentar(contoh).to_lower().contains("bantu"), "pemindai membuang komentar (supaya tes ini tidak lolos kosong)")
	check(_tanpa_komentar("var bantu: bool = false").to_lower().contains("bantu"), "pemindai mengenali kata di kode")


## Teks `teks` tanpa komentar `#` (sisa baris) agar penjelasan tentang aturan tidak ikut dipindai.
func _tanpa_komentar(teks: String) -> String:
	var baris_kode: Array[String] = []
	for baris: String in teks.split("\n"):
		var i: int = baris.find("#")
		baris_kode.append(baris if i < 0 else baris.substr(0, i))
	return "\n".join(baris_kode)
