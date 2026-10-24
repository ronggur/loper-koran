class_name TesGarisFinish
extends RefCounted
## Tes garis finish dengan portal, bagian B (logika murni, run garis-finish-portal; G-2 sampai G-5, AC-3, AC-4, AC-7 tingkat murni).
##
## Oracle independen (rule `testing`): angka ditulis literal dari hitungan tangan atau skrip Python terpisah (titik pijak = 0,3333 x lebar viewport + geseran dorongan,
## tinggi 0,75 x 360; maju satu ubin = (+32, -16) px; kotak badan kiri 18, kanan 16, atas 43, bawah 8 dari titik pijak), bukan salinan rumus implementasi.
## Satu bagian kecil memakai scene (`jalan_uji.tscn`) hanya untuk membuktikan bahwa rumus kamera dan titik pijak di `AkhirRute` sama dengan kamera nyata.

const BERKAS_JALAN_UJI: String = "res://scenes/dev/jalan_uji.tscn"
const BERKAS_AKHIR_RUTE: String = "res://scripts/systems/akhir_rute.gd"
const DT: float = 1.0 / 60.0
const TOL: float = 0.0006
## Lebar viewport yang dihasilkan layar 16:9, sekitar 19,2:9, 19,5:9, dan 20:9 (tinggi selalu 360).
const LEBAR: Array[int] = [640, 693, 780, 800]
## Sprite pemain yang boleh tampak sesudah garis akhir: animasi arah lurus kayuh, melambat, meluncur, rem, dan berhenti. Berkas JSON/PNG sheet masing-masing.
const SHEET_BADAN: Array = [
	["loper_agen", ["santai_normal", "cepat_normal", "ngebut_normal"]],
	["loper_agen_melambat", ["melambat_normal"]],
	["loper_agen_meluncur", ["meluncur_normal"]],
	["loper_agen_rem", ["rem_normal"]],
	["loper_agen_berhenti", ["berhenti_normal"]],
]
## Nama kelas yang tidak boleh muncul di kode (di luar komentar) `akhir_rute.gd`: skor, tenggat, progres, radar, kondisi, misi, dan save tidak disentuh (G-5).
const KELAS_TERLARANG: Array[String] = ["SkorRute", "TenggatRute", "ProgresRute", "RadarRute", "KondisiRute", "BikeCondition", "MissionManager", "SaveManager", "DataSave", "HasilRute", "RouteBuilder"]

## Tiap baris: [lebar viewport, nama, pijak x, pijak y, sisa ubin keluar, belakang terlihat, depan terlihat]. Pijak = (lebar x 0,3333, 270) + geseran dorongan
## (melambat v 1,5 = (-20, +10), santai = (0, 0), ngebut v 6,0 = (+36, -18)). Dihitung skrip Python terpisah; semuanya keluar lewat tepi KANAN.
const TABEL_VIEWPORT: Array = [
	[640, "melambat", 193.3120, 280.0, 14.5215, -5.5205, 15.7295],
	[640, "santai", 213.3120, 270.0, 13.8965, -6.1455, 15.1045],
	[640, "ngebut", 249.3120, 252.0, 12.7715, -7.2705, 13.9795],
	[693, "melambat", 210.9769, 280.0, 15.6257, -5.7965, 16.2816],
	[693, "santai", 230.9769, 270.0, 15.0007, -6.4215, 15.6566],
	[693, "ngebut", 266.9769, 252.0, 13.8757, -7.5465, 14.5316],
	[780, "melambat", 239.9740, 280.0, 17.4383, -6.2496, 17.1879],
	[780, "santai", 259.9740, 270.0, 16.8133, -6.8746, 16.5629],
	[780, "ngebut", 295.9740, 252.0, 15.6883, -7.9996, 15.4379],
	[800, "melambat", 246.6400, 280.0, 17.8550, -6.3537, 17.3963],
	[800, "santai", 266.6400, 270.0, 17.2300, -6.9787, 16.7713],
	[800, "ngebut", 302.6400, 252.0, 16.1050, -8.1037, 15.6463],
]

var _cek: Callable
var _judul: Callable
var _tree: SceneTree


func _init(cek: Callable, judul: Callable, tree: SceneTree) -> void:
	_cek = cek
	_judul = judul
	_tree = tree


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_test_status_lama_tetap()
	_test_stick_dan_laju_dijaga()
	_test_gerak_lurus_bike_motion()
	_test_badan_sama_dengan_sprite()
	_test_geometri_keluar_tabel()
	_test_periksa_keluar_tabel()
	_test_periksa_keluar_fuzz()
	_test_simulasi_keluar()
	_test_portal()
	_test_kamera_beku_murni()
	_test_siap_tampil_kombinasi()
	_test_invarian_g5()
	await _test_kamera_dan_pijak_di_scene()


func _ukuran(lebar: int) -> Vector2:
	return Vector2(float(lebar), 360.0)


# --- Kontrak lama tidak rusak ---

func _test_status_lama_tetap() -> void:
	_judul.call("Garis akhir: kontrak lama (periksa/Status/stick_akhir) tidak berubah, baru_selesai tepat sekali")
	var jumlah_baru: int = 0
	var selesai: bool = false
	for langkah: int in range(0, 600):
		var status: AkhirRute.Status = AkhirRute.periksa(selesai, float(langkah) * 0.5, 236.0)
		selesai = status.selesai
		if status.baru_selesai:
			jumlah_baru += 1
	check(jumlah_baru == 1 and selesai, "jarak 0..299,5 melewati 236: baru_selesai tepat 1 kali (dapat %d)" % jumlah_baru)
	check(AkhirRute.stick_akhir() == Vector2(0.0, -1.0), "stick_akhir lama tetap rem penuh (0, -1)")
	check(AkhirRute.stick_keluar() == Vector2(0.0, 1.0), "stick_keluar = lurus ke depan penuh (0, +1), bukan rem")
	check(AkhirRute.stick_keluar() != AkhirRute.stick_akhir() and AkhirRute.stick_keluar().x == 0.0, "stick_keluar tanpa komponen belok")


# --- Laju minimum dan gerak lurus ---

func _test_stick_dan_laju_dijaga() -> void:
	_judul.call("Laju dijaga minimal 3,0 u/d: dari laju 0, rendah, pas, tinggi, NaN, negatif; tidak mengubah yang lebih tinggi")
	check(Config.RUTE_KELUAR_LAJU_MIN_UD == 3.0, "laju minimum keluar = 3,0 u/d (santai)")
	check(AkhirRute.laju_dijaga(0.0) == 3.0, "laju 0 -> 3,0")
	check(AkhirRute.laju_dijaga(1.5) == 3.0, "laju 1,5 -> 3,0")
	check(AkhirRute.laju_dijaga(2.999) == 3.0, "laju 2,999 -> 3,0")
	check(AkhirRute.laju_dijaga(3.0) == 3.0, "laju 3,0 tetap 3,0 (batas inklusif)")
	check(AkhirRute.laju_dijaga(3.001) == 3.001, "laju 3,001 tidak diubah")
	check(AkhirRute.laju_dijaga(4.5) == 4.5 and AkhirRute.laju_dijaga(6.0) == 6.0, "laju tinggi (4,5 dan 6,0) tidak diubah")
	check(AkhirRute.laju_dijaga(NAN) == 3.0 and AkhirRute.laju_dijaga(-2.0) == 3.0, "NaN dan negatif -> 3,0")
	var asli: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
	asli.kecepatan_ud = 0.5
	asli.lateral_ubin = -1.25
	asli.stamina = 42.0
	asli.rem_aktif = true
	asli.tahan_rem_detik = 0.4
	asli.lelah = true
	var dijaga: BikeMotion.Keadaan = AkhirRute.keadaan_dijaga(asli)
	check(asli.kecepatan_ud == 0.5, "keadaan_dijaga tidak mengubah keadaan masukan")
	check(dijaga.kecepatan_ud == 3.0 and dijaga.lateral_ubin == -1.25 and dijaga.stamina == 42.0 and dijaga.rem_aktif and dijaga.tahan_rem_detik == 0.4 and dijaga.lelah, "keadaan_dijaga hanya mengubah kecepatan")
	check(AkhirRute.keadaan_dijaga(null).kecepatan_ud == 3.0, "keadaan null = keadaan awal (santai 3,0)")


## Efek kondisi terburuk yang masih mungkin: ban 0,92, batas puncak rantai 3,0 (tidak di bawah santai), akselerasi 0,35, rem 0,4, lateral 0,6.
func _efek_terburuk() -> EfekKondisi:
	var e: EfekKondisi = EfekKondisi.new()
	e.pengali_kecepatan = 0.92
	e.batas_puncak_ud = 3.0
	e.pengali_akselerasi = 0.35
	e.pengali_rem = 0.4
	e.pengali_lateral = 0.6
	return e


func _test_gerak_lurus_bike_motion() -> void:
	_judul.call("BikeMotion nyata: sesudah garis akhir sepeda tidak berbelok, tidak merem, tidak turun dari laju minimum (semua laju awal, efek, lateral, lelah)")
	var efek_daftar: Array = [null, _efek_terburuk()]
	var laju_awal: Array = [0.0, 1.5, 2.9, 3.0, 4.5, 6.0]
	var lateral_awal: Array = [-2.0, -1.3, 0.0, 1.9]
	var semua_ok: bool = true
	var jumlah_kasus: int = 0
	for e: Variant in efek_daftar:
		for lelah: bool in [false, true]:
			for v0: float in laju_awal:
				for lat: float in lateral_awal:
					var k: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
					k.kecepatan_ud = v0
					k.lateral_ubin = lat
					k.lelah = lelah
					k.stamina = 0.0 if lelah else 100.0
					# Rem aktif dari sebelum garis akhir: harus padam begitu stick keluar dipakai.
					k.rem_aktif = v0 < 1.0
					k.tahan_rem_detik = 1.0 if k.rem_aktif else 0.0
					var jarak: float = 0.0
					for i: int in range(600):
						var h: BikeMotion.Hasil = AkhirRute.langkah_keluar(k, DT, 0.0, e as EfekKondisi)
						k = h.keadaan
						jarak += h.maju_ubin
						if k.kecepatan_ud < 3.0 - 0.000001 or k.rem_aktif or k.tahan_rem_detik != 0.0 or k.lateral_ubin != lat or h.lateral_ud != 0.0:
							semua_ok = false
						if h.pose == LoperAnim.Pose.REM or h.pose == LoperAnim.Pose.BERHENTI or h.arah_sprite != 0 or h.stick_maju != 1.0 or h.maju_ubin <= 0.0:
							semua_ok = false
					if jarak < 3.0 * 10.0 - 0.001:
						semua_ok = false
					jumlah_kasus += 1
	check(semua_ok, "%d kasus x 600 langkah: kecepatan >= 3,0, rem padam, lateral tetap, tanpa belok, pose bukan rem/berhenti, jarak maju tiap langkah > 0" % jumlah_kasus)
	# Jarak literal. Tanpa efek: dari 3,0 menuju 6,0 dengan akselerasi 3,0 u/d2 selama 1 detik = rata-rata 4,5 u/d x 1 detik = 4,5 ubin.
	check(is_equal_approx(_jarak_satu_detik(3.0, null), 4.5), "tanpa efek, dari 3,0 selama 1 detik: 4,5 ubin (dapat %f)" % _jarak_satu_detik(3.0, null))
	check(is_equal_approx(_jarak_satu_detik(0.0, null), 4.5), "dari laju 0: dinaikkan ke 3,0 lebih dulu, hasil sama 4,5 ubin")
	check(is_equal_approx(_jarak_satu_detik(6.0, null), 6.0), "dari 6,0 tetap 6,0 selama 1 detik = 6,0 ubin (tidak direm, tidak melambat)")
	check(is_equal_approx(_jarak_satu_detik(0.0, _efek_terburuk()), 3.0), "efek terburuk (puncak 3,0) dari laju 0: tetap 3,0 u/d = 3,0 ubin per detik")
	# Telemetri: kecepatan awal langkah yang dilaporkan sudah dijaga (bukan 0).
	var kosong: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
	kosong.kecepatan_ud = 0.0
	check(AkhirRute.langkah_keluar(kosong, DT).kecepatan_awal_ud == 3.0, "kecepatan awal langkah dari laju 0 = 3,0")
	check(kosong.kecepatan_ud == 0.0, "langkah_keluar tidak mengubah keadaan masukan")


func _jarak_satu_detik(v0: float, e: EfekKondisi) -> float:
	var k: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
	k.kecepatan_ud = v0
	var jarak: float = 0.0
	for i: int in range(60):
		var h: BikeMotion.Hasil = AkhirRute.langkah_keluar(k, DT, 0.0, e)
		k = h.keadaan
		jarak += h.maju_ubin
	return jarak


# --- Kotak badan = sprite nyata ---

func _test_badan_sama_dengan_sprite() -> void:
	_judul.call("Kotak badan RUTE_KELUAR_BADAN_KIRI_PX dan RUTE_KELUAR_BADAN_BAWAH_PX = gabungan piksel buram sprite pemain nyata (kayuh, melambat, meluncur, rem, berhenti; arah lurus)")
	var x_min: int = 1000000
	var x_maks: int = -1000000
	var y_min: int = 1000000
	var y_maks: int = -1000000
	var diukur: int = 0
	for entri: Array in SHEET_BADAN:
		var dasar: String = entri[0]
		var teks: String = FileAccess.get_file_as_string("res://assets/sprites/loper/%s.json" % dasar)
		var json: Variant = JSON.parse_string(teks)
		var tekstur: Texture2D = load("res://assets/sprites/loper/%s.png" % dasar) as Texture2D
		if not (json is Dictionary) or tekstur == null:
			check(false, "%s: JSON dan PNG sheet bisa dimuat" % dasar)
			continue
		var gambar: Image = tekstur.get_image()
		var pijak: Array = (json as Dictionary)["ground_anchor"]
		for animasi: Dictionary in (json as Dictionary)["animations"]:
			if not (entri[1] as Array).has(animasi["name"]):
				continue
			diukur += 1
			for wilayah: Array in animasi["regions"]:
				for y: int in range(int(wilayah[1]), int(wilayah[1]) + int(wilayah[3])):
					for x: int in range(int(wilayah[0]), int(wilayah[0]) + int(wilayah[2])):
						if gambar.get_pixel(x, y).a > 0.0:
							var rx: int = x - int(wilayah[0]) - int(pijak[0])
							var ry: int = y - int(wilayah[1]) - int(pijak[1])
							x_min = mini(x_min, rx)
							x_maks = maxi(x_maks, rx)
							y_min = mini(y_min, ry)
							y_maks = maxi(y_maks, ry)
	check(diukur == 7, "tujuh animasi arah lurus terukur (dapat %d)" % diukur)
	check(-x_min == Config.RUTE_KELUAR_BADAN_KIRI_PX and y_maks == Config.RUTE_KELUAR_BADAN_BAWAH_PX, "badan terukur kiri %d bawah %d = config kiri %d bawah %d" % [-x_min, y_maks, Config.RUTE_KELUAR_BADAN_KIRI_PX, Config.RUTE_KELUAR_BADAN_BAWAH_PX])
	check(-x_min == 18 and x_maks == 16 and -y_min == 43 and y_maks == 8, "literal terukur kiri 18, kanan 16, atas 43, bawah 8")


# --- Geometri keluar viewport ---

func _test_geometri_keluar_tabel() -> void:
	_judul.call("Keluar viewport: titik pijak, sisa ubin, tepi keluar (kanan), dan rentang terlihat di 4 lebar x 3 geseran (oracle Python)")
	check(DoronganKecepatan.geser_target(1.5).is_equal_approx(Vector2(-20.0, 10.0)) and DoronganKecepatan.geser_target(6.0).is_equal_approx(Vector2(36.0, -18.0)), "geseran dorongan 1,5 u/d (-20, 10) dan 6,0 u/d (36, -18)")
	for baris: Array in TABEL_VIEWPORT:
		var ukuran: Vector2 = _ukuran(int(baris[0]))
		var nama: String = "%d %s" % [baris[0], baris[1]]
		var geser: Vector2 = Vector2.ZERO
		if baris[1] == "melambat":
			geser = Vector2(-20.0, 10.0)
		elif baris[1] == "ngebut":
			geser = Vector2(36.0, -18.0)
		var pijak: Vector2 = AkhirRute.posisi_layar_pijak(ukuran, geser)
		check(absf(pijak.x - float(baris[2])) < TOL and absf(pijak.y - float(baris[3])) < TOL, "%s: pijak (%.4f, %.4f), oracle (%.4f, %.1f)" % [nama, pijak.x, pijak.y, baris[2], baris[3]])
		var sisa: float = AkhirRute.sisa_ubin_keluar(pijak, ukuran)
		check(absf(sisa - float(baris[4])) < TOL, "%s: sisa %.4f ubin, oracle %.4f" % [nama, sisa, baris[4]])
		var rentang: Vector2 = AkhirRute.rentang_maju_terlihat(pijak, ukuran)
		check(absf(rentang.x - float(baris[5])) < TOL and absf(rentang.y - float(baris[6])) < TOL, "%s: terlihat belakang %.4f depan %.4f, oracle %.4f dan %.4f" % [nama, rentang.x, rentang.y, baris[5], baris[6]])
		# Tepi keluar: pada sisa itu sisi kiri badan tepat di tepi kanan viewport (keluar lewat KANAN), sedangkan sisi bawah badan masih di bawah tepi atas.
		var di_tepi: Vector2 = pijak + Vector2(32.0, -16.0) * sisa
		check(absf((di_tepi.x - 18.0) - ukuran.x) < 0.001 and di_tepi.y + 8.0 > 0.0, "%s: keluar lewat tepi kanan setelah %.2f ubin; di sana badan kiri x = %.3f (lebar %d), bawah badan y = %.3f > 0" % [nama, sisa, di_tepi.x - 18.0, int(ukuran.x), di_tepi.y + 8.0])
		check(not AkhirRute.sudah_keluar(AkhirRute.sisa_ubin_keluar(pijak + Vector2(32.0, -16.0) * (sisa - 0.01), ukuran)), "%s: 0,01 ubin sebelum itu belum keluar" % nama)
		check(AkhirRute.sudah_keluar(AkhirRute.sisa_ubin_keluar(pijak + Vector2(32.0, -16.0) * sisa, ukuran)), "%s: tepat di tepi sudah keluar (inklusif)" % nama)
	# Tepi atas bisa menang di layar sangat lebar/pendek: pijak (100, 100) pada 640x360 -> atas (100+8)/16 = 6,75 ubin; kanan (640-82)/32 = 17,4375.
	check(is_equal_approx(AkhirRute.sisa_ubin_keluar(Vector2(100.0, 100.0), Vector2(640.0, 360.0)), 6.75), "pijak (100, 100): tepi atas lebih dulu, 6,75 ubin")
	check(is_equal_approx(AkhirRute.sisa_ubin_keluar(Vector2(466.0, 300.0), Vector2(640.0, 360.0)), 6.0), "pijak (466, 300): tepi kanan (640-448)/32 = 6,0 ubin")
	check(AkhirRute.sisa_ubin_keluar(Vector2(700.0, 200.0), Vector2(640.0, 360.0)) == 0.0, "sudah lewat tepi kanan: sisa 0 (tidak negatif)")
	check(AkhirRute.sisa_ubin_keluar(Vector2(300.0, -20.0), Vector2(640.0, 360.0)) == 0.0, "sudah lewat tepi atas: sisa 0")
	check(is_equal_approx(AkhirRute.sisa_ubin_keluar(Vector2(-100.0, 200.0), Vector2(640.0, 360.0)), 13.0), "pijak di luar sisi barat viewport: tetap dihitung ke tepi atas, (200+8)/16 = 13,0 ubin")
	check(is_inf(AkhirRute.sisa_ubin_keluar(Vector2(NAN, 100.0), Vector2(640.0, 360.0))) and is_inf(AkhirRute.sisa_ubin_keluar(Vector2(100.0, INF), Vector2(640.0, 360.0))), "pijak NaN atau tak hingga: sisa tak hingga")
	check(is_inf(AkhirRute.sisa_ubin_keluar(Vector2(100.0, 100.0), Vector2(0.0, 360.0))) and is_inf(AkhirRute.sisa_ubin_keluar(Vector2(100.0, 100.0), Vector2(640.0, -1.0))) and is_inf(AkhirRute.sisa_ubin_keluar(Vector2(100.0, 100.0), Vector2(NAN, 360.0))), "ukuran tidak positif atau NaN: sisa tak hingga")
	check(not AkhirRute.sudah_keluar(INF) and not AkhirRute.sudah_keluar(NAN) and AkhirRute.sudah_keluar(0.0) and AkhirRute.sudah_keluar(-0.5), "sudah_keluar: 0 dan negatif ya; tak hingga dan NaN tidak")
	check(AkhirRute.hampir_keluar(6.0) and AkhirRute.hampir_keluar(0.0) and not AkhirRute.hampir_keluar(6.0001) and not AkhirRute.hampir_keluar(INF) and not AkhirRute.hampir_keluar(NAN), "hampir_keluar: <= 6,0 ubin (inklusif); 6,0001, tak hingga, NaN tidak")
	check(Config.RUTE_KELUAR_HAMPIR_UBIN == 6.0, "ambang hampir keluar = 6,0 ubin")


# --- periksa_keluar ---

## Satu baris: [fase_lama, hampir_lama, selesai, pijak, fase, hampir, baru_hampir, baru_keluar, label]; viewport 640x360.
func _test_periksa_keluar_tabel() -> void:
	_judul.call("periksa_keluar: fase hanya maju, hampir keluar tepat sekali, keluar tepat sekali (tabel literal, 640x360)")
	var fs: AkhirRute.Fase = AkhirRute.Fase.SEBELUM
	var fm: AkhirRute.Fase = AkhirRute.Fase.MELAJU_KELUAR
	var fk: AkhirRute.Fase = AkhirRute.Fase.SUDAH_KELUAR
	var tabel: Array = [
		[fs, false, false, Vector2(100.0, 100.0), fs, false, false, false, "belum selesai, di dalam"],
		[fs, false, false, Vector2(700.0, 200.0), fs, false, false, false, "belum selesai walau posisi di luar: tidak ada fase maupun sinyal"],
		[fs, false, true, Vector2(100.0, 100.0), fm, false, false, false, "garis tercapai, jauh dari tepi (sisa 6,75): melaju keluar"],
		[fm, false, true, Vector2(100.0, 98.0), fm, false, false, false, "sisa 6,625: belum hampir"],
		[fm, false, true, Vector2(100.0, 88.0), fm, true, true, false, "sisa tepat 6,0: hampir keluar (inklusif), sinyal baru"],
		[fm, true, true, Vector2(100.0, 87.9), fm, true, false, false, "sudah hampir: tidak ada sinyal kedua"],
		[fm, true, true, Vector2(100.0, -7.9), fm, true, false, false, "sisa 0,0063 ubin: belum keluar"],
		[fm, true, true, Vector2(100.0, -8.0), fk, true, false, true, "sisa 0: sudah keluar, sinyal baru"],
		[fk, true, true, Vector2(100.0, -50.0), fk, true, false, false, "sudah keluar: tidak ada sinyal kedua"],
		[fk, true, true, Vector2(100.0, 300.0), fk, true, false, false, "posisi kembali ke dalam: fase tidak turun"],
		[fk, false, true, Vector2(100.0, 300.0), fk, true, false, false, "fase keluar tanpa catatan hampir: tidak ada sinyal hampir baru"],
		[fs, false, true, Vector2(700.0, 200.0), fk, true, true, true, "langkah besar langsung ke luar: hampir dan keluar pada pemeriksaan yang sama"],
		[fm, true, false, Vector2(100.0, 300.0), fm, true, false, false, "selesai false setelah fase naik: fase dan sinyal tidak mundur"],
		[fs, false, true, Vector2(657.9, 200.0), fm, true, true, false, "kanan: sisa 0,0031 ubin (hampir, belum keluar)"],
		[fs, false, true, Vector2(658.0, 200.0), fk, true, true, true, "kanan: pijak x = 640 + 18 = tepat keluar"],
		[fm, false, true, Vector2(466.0, 300.0), fm, true, true, false, "kanan: sisa tepat 6,0 hampir"],
		[fm, false, true, Vector2(NAN, 100.0), fm, false, false, false, "pijak NaN: tidak ada kemajuan"],
	]
	for baris: Array in tabel:
		var k: AkhirRute.Keluar = AkhirRute.periksa_keluar(baris[0], baris[1], baris[2], baris[3], Vector2(640.0, 360.0))
		check(k.fase == baris[4] and k.hampir_keluar == baris[5] and k.baru_hampir_keluar == baris[6] and k.baru_keluar == baris[7], "%s: fase %d hampir %s baru_hampir %s baru_keluar %s" % [baris[8], k.fase, k.hampir_keluar, k.baru_hampir_keluar, k.baru_keluar])
	var tak_sah: AkhirRute.Keluar = AkhirRute.periksa_keluar(AkhirRute.Fase.MELAJU_KELUAR, false, true, Vector2(100.0, 100.0), Vector2.ZERO)
	check(tak_sah.fase == AkhirRute.Fase.MELAJU_KELUAR and not tak_sah.hampir_keluar and is_inf(tak_sah.sisa_ubin), "ukuran viewport nol: tidak pernah dianggap keluar")


func _test_periksa_keluar_fuzz() -> void:
	_judul.call("periksa_keluar fuzz berseed: fase tidak pernah turun; sinyal hampir dan keluar paling banyak sekali per rangkaian")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20261024
	var pelanggaran: int = 0
	var rangkaian_dengan_keluar: int = 0
	for r: int in range(300):
		var ukuran: Vector2 = _ukuran(LEBAR[rng.randi_range(0, LEBAR.size() - 1)])
		var fase: AkhirRute.Fase = AkhirRute.Fase.SEBELUM
		var hampir: bool = false
		var jumlah_hampir: int = 0
		var jumlah_keluar: int = 0
		var pernah_selesai: bool = false
		for langkah: int in range(80):
			var selesai: bool = rng.randf() < 0.3 if not pernah_selesai else rng.randf() < 0.9
			pernah_selesai = pernah_selesai or selesai
			var pijak: Vector2 = Vector2(rng.randf_range(-100.0, ukuran.x + 120.0), rng.randf_range(-80.0, 400.0))
			var k: AkhirRute.Keluar = AkhirRute.periksa_keluar(fase, hampir, selesai, pijak, ukuran)
			if k.fase < fase or (hampir and not k.hampir_keluar) or (k.baru_keluar and k.fase != AkhirRute.Fase.SUDAH_KELUAR) or (k.baru_keluar and not k.hampir_keluar):
				pelanggaran += 1
			if not pernah_selesai and (k.fase != AkhirRute.Fase.SEBELUM or k.baru_hampir_keluar or k.baru_keluar):
				pelanggaran += 1
			jumlah_hampir += 1 if k.baru_hampir_keluar else 0
			jumlah_keluar += 1 if k.baru_keluar else 0
			fase = k.fase
			hampir = k.hampir_keluar
		if jumlah_hampir > 1 or jumlah_keluar > 1 or (jumlah_keluar == 1 and jumlah_hampir != 1):
			pelanggaran += 1
		rangkaian_dengan_keluar += 1 if jumlah_keluar == 1 else 0
	check(pelanggaran == 0, "300 rangkaian x 80 langkah acak: 0 pelanggaran (dapat %d)" % pelanggaran)
	check(rangkaian_dengan_keluar > 50, "fuzz benar-benar menjangkau fase keluar (%d dari 300 rangkaian)" % rangkaian_dengan_keluar)


# --- Simulasi lengkap dengan BikeMotion nyata ---

func _test_simulasi_keluar() -> void:
	_judul.call("Simulasi keluar dengan BikeMotion nyata di 4 viewport: banner (hampir) tepat sekali sebelum keluar, jarak tambahan = sisa geometri, waktu keluar")
	var kombinasi: int = 0
	var semua_ok: bool = true
	var catatan: String = ""
	for lebar: int in LEBAR:
		for v0: float in [0.0, 1.5, 3.0, 4.5, 6.0]:
			for pakai_terburuk: bool in [false, true]:
				var ukuran: Vector2 = _ukuran(lebar)
				var efek: EfekKondisi = _efek_terburuk() if pakai_terburuk else null
				var k: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
				k.kecepatan_ud = v0
				var pijak: Vector2 = AkhirRute.posisi_layar_pijak(ukuran, DoronganKecepatan.geser_target(v0))
				var sisa_awal: float = AkhirRute.sisa_ubin_keluar(pijak, ukuran)
				var fase: AkhirRute.Fase = AkhirRute.Fase.SEBELUM
				var hampir: bool = false
				var jarak: float = 0.0
				var langkah_hampir: int = -1
				var langkah_keluar: int = -1
				var sisa_saat_hampir: float = -1.0
				var jarak_saat_keluar: float = -1.0
				var jumlah_hampir: int = 0
				var jumlah_keluar: int = 0
				for i: int in range(3000):
					var h: BikeMotion.Hasil = AkhirRute.langkah_keluar(k, DT, 0.0, efek)
					k = h.keadaan
					jarak += h.maju_ubin
					pijak += Vector2(32.0, -16.0) * h.maju_ubin
					var hasil: AkhirRute.Keluar = AkhirRute.periksa_keluar(fase, hampir, true, pijak, ukuran)
					fase = hasil.fase
					hampir = hasil.hampir_keluar
					if hasil.baru_hampir_keluar:
						jumlah_hampir += 1
						langkah_hampir = i
						sisa_saat_hampir = sisa_awal - jarak
					if hasil.baru_keluar:
						jumlah_keluar += 1
						langkah_keluar = i
						jarak_saat_keluar = jarak
					if fase == AkhirRute.Fase.SUDAH_KELUAR:
						break
				var maks_langkah: float = 6.0 * DT + 0.000001
				var ok: bool = jumlah_hampir == 1 and jumlah_keluar == 1 and langkah_hampir < langkah_keluar and fase == AkhirRute.Fase.SUDAH_KELUAR
				ok = ok and jarak_saat_keluar >= sisa_awal - 0.000001 and jarak_saat_keluar < sisa_awal + maks_langkah
				ok = ok and sisa_saat_hampir <= 6.0 + 0.000001 and sisa_saat_hampir > 6.0 - maks_langkah
				if not ok:
					semua_ok = false
					catatan += " [lebar %d v0 %.1f terburuk %s: hampir %d keluar %d langkah %d/%d jarak %.3f sisa awal %.3f sisa hampir %.3f]" % [lebar, v0, pakai_terburuk, jumlah_hampir, jumlah_keluar, langkah_hampir, langkah_keluar, jarak_saat_keluar, sisa_awal, sisa_saat_hampir]
				kombinasi += 1
	check(semua_ok, "%d kombinasi (4 lebar x 5 laju awal x 2 efek): hampir 1x lalu keluar 1x, jarak saat keluar = sisa geometri (selisih < 1 langkah), sisa saat hampir 5,9 sampai 6,0.%s" % [kombinasi, catatan])
	# Waktu literal untuk 640 santai (efek tidak ada, dari 3,0): 1 detik percepatan 3->6 menempuh 4,5 ubin, sisa 13,8965 - 4,5 = 9,3965 ubin pada 6,0 u/d = 1,5661 detik: 2,5661 detik = langkah ke-154 (indeks 153).
	var k2: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
	var pijak2: Vector2 = AkhirRute.posisi_layar_pijak(Vector2(640.0, 360.0), Vector2.ZERO)
	var fase2: AkhirRute.Fase = AkhirRute.Fase.SEBELUM
	var hampir2: bool = false
	var indeks_keluar: int = -1
	for i: int in range(1000):
		var h2: BikeMotion.Hasil = AkhirRute.langkah_keluar(k2, DT)
		k2 = h2.keadaan
		pijak2 += Vector2(32.0, -16.0) * h2.maju_ubin
		var hasil2: AkhirRute.Keluar = AkhirRute.periksa_keluar(fase2, hampir2, true, pijak2, Vector2(640.0, 360.0))
		fase2 = hasil2.fase
		hampir2 = hasil2.hampir_keluar
		if hasil2.baru_keluar:
			indeks_keluar = i
			break
	check(indeks_keluar >= 152 and indeks_keluar <= 154, "640x360 santai tanpa efek: keluar di langkah indeks %d (oracle 153 +-1)" % indeks_keluar)
	# Laju minimum terburuk (efek puncak 3,0 u/d konstan): 13,8965 ubin / 3,0 = 4,632 detik = 278 langkah.
	var k3: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
	var pijak3: Vector2 = AkhirRute.posisi_layar_pijak(Vector2(640.0, 360.0), Vector2.ZERO)
	var fase3: AkhirRute.Fase = AkhirRute.Fase.SEBELUM
	var hampir3: bool = false
	var indeks3: int = -1
	for i: int in range(1000):
		var h3: BikeMotion.Hasil = AkhirRute.langkah_keluar(k3, DT, 0.0, _efek_terburuk())
		k3 = h3.keadaan
		pijak3 += Vector2(32.0, -16.0) * h3.maju_ubin
		var hasil3: AkhirRute.Keluar = AkhirRute.periksa_keluar(fase3, hampir3, true, pijak3, Vector2(640.0, 360.0))
		fase3 = hasil3.fase
		hampir3 = hasil3.hampir_keluar
		if hasil3.baru_keluar:
			indeks3 = i
			break
	check(indeks3 >= 276 and indeks3 <= 279, "640x360 santai, efek terburuk (3,0 u/d): keluar di langkah indeks %d (oracle 277 +-1)" % indeks3)


# --- Portal ---

func _test_portal() -> void:
	_judul.call("Portal: tertutup jauh, terbuka tepat 6 ubin sebelum garis (inklusif), tetap terbuka sesudah melewatinya; masukan tidak sah tertutup")
	check(Config.RUTE_PORTAL_BUKA_JARAK_UBIN == 6.0, "jarak buka portal = 6,0 ubin")
	check(not AkhirRute.portal_terbuka(0.0, 240.0), "di awal rute: tertutup")
	check(not AkhirRute.portal_terbuka(233.99, 240.0), "6,01 ubin sebelum garis: tertutup")
	check(AkhirRute.portal_terbuka(234.0, 240.0), "tepat 6,0 ubin sebelum garis: terbuka (inklusif)")
	check(AkhirRute.portal_terbuka(239.9, 240.0), "0,1 ubin sebelum garis: terbuka")
	check(AkhirRute.portal_terbuka(240.0, 240.0), "tepat di garis: terbuka")
	check(AkhirRute.portal_terbuka(245.0, 240.0) and AkhirRute.portal_terbuka(260.0, 240.0) and AkhirRute.portal_terbuka(100000.0, 240.0), "sesudah garis: tetap terbuka")
	check(not AkhirRute.portal_terbuka(NAN, 240.0) and not AkhirRute.portal_terbuka(INF, 240.0) and not AkhirRute.portal_terbuka(-INF, 240.0), "jarak NaN atau tak hingga: tertutup")
	check(not AkhirRute.portal_terbuka(235.0, NAN) and not AkhirRute.portal_terbuka(235.0, INF) and not AkhirRute.portal_terbuka(235.0, 0.0) and not AkhirRute.portal_terbuka(235.0, -240.0), "panjang rute NaN, tak hingga, nol, atau negatif: tertutup")
	check(AkhirRute.portal_bingkai(100.0, 240.0) == 0 and AkhirRute.portal_bingkai(234.0, 240.0) == 1 and AkhirRute.portal_bingkai(250.0, 240.0) == 1 and AkhirRute.portal_bingkai(NAN, 240.0) == 0, "frame sprite: 0 tertutup, 1 terbuka")
	check(is_equal_approx(AkhirRute.jarak_ke_garis(234.0, 240.0), 6.0) and is_equal_approx(AkhirRute.jarak_ke_garis(245.0, 240.0), -5.0) and is_nan(AkhirRute.jarak_ke_garis(NAN, 240.0)) and is_nan(AkhirRute.jarak_ke_garis(1.0, 0.0)), "jarak_ke_garis: 6, -5, NaN")
	# Berseed: jarak yang selalu naik tidak pernah membuat portal tertutup lagi, dan portal terbuka tepat di jarak >= panjang - 6.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20261025
	var pelanggaran: int = 0
	for r: int in range(200):
		var panjang: float = rng.randf_range(100.0, 400.0)
		var jarak: float = 0.0
		var pernah_terbuka: bool = false
		while jarak < panjang + 40.0:
			jarak += rng.randf_range(0.0, 0.5)
			var terbuka: bool = AkhirRute.portal_terbuka(jarak, panjang)
			if pernah_terbuka and not terbuka:
				pelanggaran += 1
			if terbuka != (jarak >= panjang - 6.0):
				pelanggaran += 1
			pernah_terbuka = pernah_terbuka or terbuka
		if not pernah_terbuka:
			pelanggaran += 1
	check(pelanggaran == 0, "200 rute acak: portal tidak pernah menutup lagi dan terbuka tepat di >= panjang - 6 (0 pelanggaran, dapat %d)" % pelanggaran)


# --- Kamera beku ---

func _test_kamera_beku_murni() -> void:
	_judul.call("Kamera beku: fungsi murni dari posisi sepeda saat garis tercapai; sepeda berpindah ke kanan atas di layar selama kamera diam")
	var ukuran: Vector2 = Vector2(640.0, 360.0)
	# Pijak (213,312, 270); sepeda di dunia (1000, -500): kamera = (1000 + 320 - 213,312, -500 + 180 - 270) = (1106,688, -590) -> (1107, -590).
	var kamera: Vector2 = AkhirRute.posisi_kamera(Vector2(1000.0, -500.0), ukuran, Vector2.ZERO)
	check(kamera == Vector2(1107.0, -590.0), "kamera di garis akhir (640, tanpa geseran) = (1107, -590), dapat %s" % kamera)
	check(AkhirRute.posisi_kamera(Vector2(1000.0, -500.0), ukuran, Vector2(36.0, -18.0)) == Vector2(1071.0, -572.0), "dengan geseran ngebut (36, -18): kamera (1071, -572)")
	var layar0: Vector2 = AkhirRute.posisi_layar(Vector2(1000.0, -500.0), kamera, ukuran)
	check(layar0.is_equal_approx(Vector2(213.0, 270.0)), "pijak di layar tepat sesudah beku (213, 270), dapat %s" % layar0)
	# Maju 10 ubin = (+320, -160) px: kamera tidak ikut.
	var layar10: Vector2 = AkhirRute.posisi_layar(Vector2(1320.0, -660.0), kamera, ukuran)
	check(layar10.is_equal_approx(Vector2(533.0, 110.0)), "10 ubin sesudah garis, kamera beku: pijak (533, 110), dapat %s" % layar10)
	check(AkhirRute.posisi_kamera(Vector2(1000.0, -500.0), ukuran, Vector2.ZERO) == kamera, "fungsi murni: masukan sama = kamera sama")
	# Kamera beku dari posisi di garis, bukan dari posisi akhir: kamera dari posisi lain berbeda.
	check(AkhirRute.posisi_kamera(Vector2(1320.0, -660.0), ukuran, Vector2.ZERO) != kamera, "kamera dari posisi sepeda yang lain berbeda (beku harus dari titik garis)")
	check(Config.KAMERA_SEPEDA_X_PECAHAN == 0.3333 and Config.KAMERA_SEPEDA_Y_PECAHAN == 0.75, "pecahan kamera yang dipakai oracle: 0,3333 dan 0,75")


# --- siap_tampil ---

func _test_siap_tampil_kombinasi() -> void:
	_judul.call("HasilRute.siap_tampil: semua kombinasi selesai x keluar x koran (AC-4)")
	var terbang: KoranLempar.Koran = KoranLempar.Koran.new()
	var mendarat: KoranLempar.Koran = KoranLempar.Koran.new()
	mendarat.mendarat = true
	var tanpa: Array[KoranLempar.Koran] = []
	var sudah: Array[KoranLempar.Koran] = [mendarat]
	var campur: Array[KoranLempar.Koran] = [mendarat, terbang]
	var masih: Array[KoranLempar.Koran] = [terbang]
	# [selesai, keluar, koran, harapan]
	var tabel: Array = [
		[true, true, tanpa, true], [true, true, sudah, true], [true, true, campur, false], [true, true, masih, false],
		[true, false, tanpa, false], [true, false, sudah, false], [true, false, campur, false], [true, false, masih, false],
		[false, true, tanpa, false], [false, true, sudah, false], [false, true, campur, false], [false, true, masih, false],
		[false, false, tanpa, false], [false, false, sudah, false], [false, false, campur, false], [false, false, masih, false],
	]
	var salah: int = 0
	for baris: Array in tabel:
		if HasilRute.siap_tampil(baris[0], baris[1], baris[2]) != baris[3]:
			salah += 1
	check(salah == 0, "16 kombinasi sesuai tabel literal (salah %d)" % salah)
	# Sambungan ke fase: siap hanya bila fase SUDAH_KELUAR.
	var k: AkhirRute.Keluar = AkhirRute.periksa_keluar(AkhirRute.Fase.MELAJU_KELUAR, true, true, Vector2(100.0, -50.0), Vector2(640.0, 360.0))
	check(HasilRute.siap_tampil(true, k.fase == AkhirRute.Fase.SUDAH_KELUAR, tanpa), "fase SUDAH_KELUAR dari periksa_keluar -> siap")
	var belum: AkhirRute.Keluar = AkhirRute.periksa_keluar(AkhirRute.Fase.MELAJU_KELUAR, true, true, Vector2(100.0, 50.0), Vector2(640.0, 360.0))
	check(not HasilRute.siap_tampil(true, belum.fase == AkhirRute.Fase.SUDAH_KELUAR, tanpa), "fase MELAJU_KELUAR -> belum")


# --- G-5 pada tingkat murni ---

func _test_invarian_g5() -> void:
	_judul.call("G-5 (murni): AkhirRute tidak merujuk skor, tenggat, progres, radar, kondisi, misi, hasil, atau save; langkah tidak mengubah masukan")
	var teks: String = FileAccess.get_file_as_string(BERKAS_AKHIR_RUTE)
	check(teks.length() > 1000, "akhir_rute.gd terbaca")
	var kode: String = ""
	for baris: String in teks.split("\n"):
		var potong: String = baris.strip_edges()
		if potong.begins_with("##") or potong.begins_with("#"):
			continue
		kode += baris + "\n"
	var ketemu: Array[String] = []
	for nama: String in KELAS_TERLARANG:
		if kode.contains(nama):
			ketemu.append(nama)
	check(ketemu.is_empty(), "kode akhir_rute.gd tidak memuat kelas skor/tenggat/progres/radar/kondisi/misi/hasil/save: %s" % [ketemu])
	check(not kode.contains("Time.") and not kode.contains("randi") and not kode.contains("randf") and not kode.contains("RandomNumberGenerator"), "tanpa Time atau RNG")
	var k: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
	k.kecepatan_ud = 1.0
	k.stamina = 55.0
	var h: BikeMotion.Hasil = AkhirRute.langkah_keluar(k, DT)
	check(k.kecepatan_ud == 1.0 and k.stamina == 55.0 and h.keadaan != k, "langkah_keluar memberi keadaan baru, masukan tetap")
	var status: AkhirRute.Status = AkhirRute.periksa(true, 9999.0, 236.0)
	check(status.selesai and not status.baru_selesai, "jarak jauh sesudah garis: status tetap selesai, tanpa sinyal baru_selesai kedua")
	# Dinamis dengan modul nyata: 10 detik gerak keluar (ngebut) sesudah garis tidak mengubah kondisi sepeda, jam tenggat, progres, dan radar.
	var daftar_toko: Array[DataToko] = []
	var awal_kondisi: KondisiRute.Keadaan = KondisiRute.awal({"ban": 0.5, "rem": 0.5, "rantai": 0.5}, {}, 1, daftar_toko)
	var beku: KondisiRute.Keadaan = awal_kondisi
	var jalan: KondisiRute.Keadaan = awal_kondisi
	var sepeda: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
	sepeda.kecepatan_ud = 6.0
	for i: int in range(600):
		var gerak: BikeMotion.Hasil = AkhirRute.langkah_keluar(sepeda, DT, 0.0, beku.efek)
		sepeda = gerak.keadaan
		beku = KondisiRute.langkah(beku, gerak, DT, null, true).keadaan
		jalan = KondisiRute.langkah(jalan, gerak, DT, null, false).keadaan
	check(beku.kondisi == awal_kondisi.kondisi and beku.jumlah_peringatan == awal_kondisi.jumlah_peringatan, "kondisi sepeda sesudah garis (selesai): 600 langkah gerak keluar tidak mengubah kondisi")
	check(jalan.kondisi != awal_kondisi.kondisi, "kontrol: gerak yang sama TANPA bendera selesai memang mengikis kondisi (uji ini bisa gagal)")
	var tenggat: TenggatRute.Keadaan = TenggatRute.hentikan(TenggatRute.langkah(TenggatRute.awal(240.0), 70.0))
	var tenggat_sesudah: TenggatRute.Keadaan = tenggat
	for i: int in range(600):
		tenggat_sesudah = TenggatRute.langkah(tenggat_sesudah, DT)
	check(tenggat_sesudah.waktu_detik == tenggat.waktu_detik and tenggat_sesudah.waktu_detik == 70.0 and not TenggatRute.lewat(tenggat_sesudah), "jam tenggat berhenti di garis: 70,0 detik tetap sesudah 10 detik gerak keluar")
	var pustaka: Array[SegmenRute] = PemuatRute.muat_folder("res://assets/data/routes/perumahan").segmen
	var rute: RouteBuilder.Rute = RouteBuilder.bangun(7, pustaka).rute
	check(rute != null and rute.panjang_ubin > 0.0, "rute nyata seed 7 tersusun")
	if rute != null:
		var terantar: Dictionary = {rute.pelanggan[0].id: true, rute.pelanggan[3].id: true}
		var di_garis: Array[ProgresRute.Status] = ProgresRute.status(rute, rute.panjang_ubin, terantar, true)
		var jauh: Array[ProgresRute.Status] = ProgresRute.status(rute, rute.panjang_ubin + 17.9, terantar, true)
		check(di_garis == jauh and ProgresRute.jumlah_terkirim(rute, terantar) == 2, "progres 25 rumah sama di garis dan 17,9 ubin sesudahnya")
		for bantu: bool in [false, true]:
			var radar_garis: Array[RadarRute.Penanda] = RadarRute.penanda(rute, rute.panjang_ubin, terantar, bantu, false)
			var radar_jauh: Array[RadarRute.Penanda] = RadarRute.penanda(rute, rute.panjang_ubin + 17.9, terantar, bantu, false)
			check(radar_garis.size() == radar_jauh.size() and radar_jauh.is_empty(), "radar (bantu %s) kosong di garis dan 17,9 ubin sesudahnya: tidak ada rumah di depan garis akhir" % bantu)


# --- Scene: rumus kamera dan titik pijak = kamera nyata ---

func _test_kamera_dan_pijak_di_scene() -> void:
	_judul.call("Scene jalan_uji: AkhirRute.posisi_kamera = kamera nyata dan posisi_layar_pijak = posisi_layar_sepeda (selisih <= 0,5 piksel) di 3 lebar, laju santai dan ngebut")
	var kasus: Array = [[Vector2i(1920, 1080), 640], [Vector2i(2340, 1080), 780], [Vector2i(2400, 1080), 800]]
	for entri: Array in kasus:
		_tree.root.size = entri[0]
		var paket: PackedScene = load(BERKAS_JALAN_UJI) as PackedScene
		var akar: JalanUji = paket.instantiate() as JalanUji
		_tree.root.add_child(akar)
		await _tree.process_frame
		await _tree.process_frame
		akar.set_process(false)
		(akar.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = false
		var sepeda: SepedaUji = akar.find_child("Sepeda", true, false) as SepedaUji
		var ukuran: Vector2 = akar.get_viewport_rect().size
		check(int(ukuran.x) == int(entri[1]), "jendela %s: viewport selebar %d (dapat %d)" % [entri[0], entri[1], int(ukuran.x)])
		for laju: float in [3.0, 6.0, 1.5]:
			sepeda.kecepatan_ud = laju
			for i: int in range(90):
				akar.perbarui(DT)
			var geser: Vector2 = akar.geser_dorongan()
			var kamera_nyata: Vector2 = akar.posisi_kamera()
			var kamera_murni: Vector2 = AkhirRute.posisi_kamera(sepeda.position, ukuran, geser)
			check(kamera_nyata == kamera_murni, "lebar %d laju awal %.1f: kamera nyata %s = murni %s" % [int(ukuran.x), laju, kamera_nyata, kamera_murni])
			var layar_nyata: Vector2 = akar.posisi_layar_sepeda()
			var layar_murni: Vector2 = AkhirRute.posisi_layar_pijak(ukuran, geser)
			check(absf(layar_nyata.x - layar_murni.x) <= 0.5 and absf(layar_nyata.y - layar_murni.y) <= 0.5, "lebar %d laju awal %.1f: pijak nyata %s, murni %s" % [int(ukuran.x), laju, layar_nyata, layar_murni])
			check(AkhirRute.posisi_layar(sepeda.position, kamera_nyata, ukuran).is_equal_approx(layar_nyata), "lebar %d: posisi_layar murni = posisi_layar_sepeda" % int(ukuran.x))
		(akar.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = OS.has_feature("editor")
		_tree.root.remove_child(akar)
		akar.free()
