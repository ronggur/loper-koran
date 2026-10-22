class_name TesSisiDekatB
extends RefCounted
## Tes run fase5d-sisi-dekat bagian B, bagian murni (AC-7, AC-8, AC-10 zona): data segmen pelanggan dekat dan validasinya, `RouteBuilder` dari hari, zona sasaran dekat cermin seberang.
##
## Oracle independen: geometri zona ditulis literal (cermin zona seberang) atau dari JSON aset rumah dekat (`teras_ubin`, `penutup_ubin`); fungsi klasifikasi oracle di sini TIDAK memanggil `ZonaSasaran`.
## Golden hari 1 (`GOLDEN_HARI1`) dihitung di `main` (53408cf) oleh skrip Python dari dump pustaka `main` sebelum perubahan run ini (LOG bagian B), jadi membuktikan rute hari 1 dan 2 identik `main`
## pada segmen, rumah (id, maju, jenis), pelanggan, pemberi tip, rintangan, titik misi, dekor, panjang, koran awal, dan tenggat.

const FOLDER_RUTE: String = "res://assets/data/routes/perumahan"
const FOLDER_RUMAH: String = "res://assets/sprites/houses/perumahan"
const SEED_DEV: int = 20261016
const JENIS: Array[String] = ["limasan", "pelana_lintang", "pelana_sejajar"]
## Sidik FNV-1a identitas rute hari 1 untuk seed 20261016 + 7 i (i = 0 sampai 59), dihitung di `main` sebelum run ini.
const GOLDEN_HARI1: Array[int] = [
	3967928094, 3860906097, 792529368, 2401174464, 1617699712, 924133265, 559152637, 2241518040, 1457076888, 1228844126,
	2301078601, 393307116, 3749813761, 185784315, 2322342853, 2834251575, 921460440, 798382137, 1952423217, 1949859357,
	1923745743, 1120917020, 188365207, 3692416911, 4240116287, 864345606, 1083406507, 1991348239, 3089725385, 648044336,
	747641685, 193504403, 3581766720, 961117383, 2873197892, 2112396650, 4207327696, 1634895115, 1736846428, 3307168423,
	1048233641, 1115754071, 2077385557, 3462472070, 528264006, 312767168, 2070988016, 302548317, 573254790, 3949663822,
	3539251283, 3994892823, 523422264, 2154364752, 766546240, 1003094786, 4165709520, 3814200931, 3317520305, 2908798930,
]
## Sebaran jumlah pelanggan dekat hari 3 sampai 102 (SeedHari.rute): 8 -> 54 rute, 9 -> 46 rute (diukur 2026-10-22; golden regresi RNG).
const SEBARAN_100_HARI: Dictionary = {8: 54, 9: 46}
## Rumah dekat yang BUKAN kandidat pelanggan (zona kotak suratnya beririsan dengan anjing dekat): [segmen, pos].
const DEKAT_BUKAN_BOLEH: Array = [["per_tengah_02", 12], ["per_tengah_03", 28]]
## Anjing di jalur dekat per segmen (pos): literal dari berkas data.
const ANJING_DEKAT: Dictionary = {"per_tengah_02": [14], "per_tengah_03": [30], "per_tengah_04": [28], "per_tengah_05": [20]}

var _cek: Callable
var _judul: Callable


func _init(cek: Callable, judul: Callable) -> void:
	_cek = cek
	_judul = judul


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_test_zona_literal()
	_test_zona_oracle_grid()
	_test_data_nyata()
	_test_validasi_segmen()
	_test_hari_1_2_identik()
	_test_hari_ke_atas()
	_test_periksa_rute_hari()
	_test_kandidat_kurang()


# --- Pembantu ---

func _sama(a: Rect2, x: float, y: float, w: float, h: float) -> bool:
	return is_equal_approx(a.position.x, x) and is_equal_approx(a.position.y, y) and is_equal_approx(a.size.x, w) and is_equal_approx(a.size.y, h)


func _json_rumah(jenis: String, pelanggan: bool) -> Dictionary:
	var nama: String = "house_perumahan_dekat_%s_%s" % [jenis, "pelanggan" if pelanggan else "bukan"]
	return JSON.parse_string(FileAccess.get_file_as_string("%s/%s.json" % [FOLDER_RUMAH, nama])) as Dictionary


func _pustaka() -> Array[SegmenRute]:
	return PemuatRute.muat_folder(FOLDER_RUTE).segmen


func _fnv(teks: String) -> int:
	var nilai: int = 2166136261
	for b: int in teks.to_utf8_buffer():
		nilai = nilai ^ b
		nilai = (nilai * 16777619) & 4294967295
	return nilai


## Identitas rute (hanya bilangan bulat dan teks; sama dengan skrip Python penghitung golden).
func _identitas(rute: RouteBuilder.Rute) -> String:
	var bagian: Array[String] = []
	bagian.append("panjang=%d;koran=%d;tenggat=%d" % [int(rute.panjang_ubin), rute.koran_awal, int(TenggatRute.awal(rute.panjang_ubin).tenggat_detik)])
	var ids: Array[String] = []
	for s: SegmenRute in rute.segmen:
		ids.append(s.id)
	bagian.append("S=" + ",".join(ids))
	var pel: Array[String] = []
	for p: RouteBuilder.RumahRute in rute.pelanggan:
		pel.append(p.id)
	bagian.append("P=" + ",".join(pel))
	var tip: Array = rute.id_pemberi_tip.keys()
	tip.sort()
	bagian.append("T=" + ",".join(PackedStringArray(tip)))
	var objek: Array[String] = []
	for o: RouteBuilder.ObjekRute in rute.objek:
		objek.append("%s@%s@%d@%s" % [o.jenis, o.id_segmen, int(o.maju_ubin), o.jalur])
	bagian.append("O=" + ";".join(objek))
	var misi: Array[String] = []
	for t: RouteBuilder.TitikMisiRute in rute.titik_misi:
		misi.append("%s@%d@%d" % [t.nama, int(t.maju_ubin), t.sisi])
	bagian.append("M=" + ";".join(misi))
	var dekor: Array[String] = []
	for d: RouteBuilder.DekorItem in rute.dekor:
		dekor.append(d.id)
	bagian.append("D=" + ",".join(dekor))
	var rumah: Array[String] = []
	for r: RouteBuilder.RumahRute in rute.rumah:
		rumah.append("%s:%d:%s" % [r.id, int(r.maju_ubin), r.jenis])
	bagian.append("R=" + ",".join(rumah))
	return "\n".join(bagian)


## Klasifikasi oracle titik dunia (x lateral, y = -maju) terhadap rumah dekat di awal kavling `awal`: literal cermin seberang + JSON aset. Tanpa `ZonaSasaran`.
## 0 meleset, 1 kotak surat, 2 teras, 3 halaman, 5 bukan pelanggan.
func _kelas_oracle(titik: Vector2, awal: float, pelanggan: bool, teras: Array, penutup_lateral: float) -> int:
	var lat: float = titik.x
	var maju: float = -titik.y
	var kena: int = 0
	if lat >= 1.75 and lat < 2.75 and maju >= awal + 1.25 and maju < awal + 2.5:
		kena = 1
	elif lat >= 5.0 + float(teras[0]) and lat < 5.0 + float(teras[0]) + float(teras[2]) and maju >= awal + 1.0 + float(teras[1]) and maju < awal + 1.0 + float(teras[1]) + float(teras[3]):
		kena = 2
	elif lat >= 2.0 and lat < 5.0 + penutup_lateral and maju >= awal - 0.5 and maju < awal + 2.5:
		kena = 3
	if kena != 0 and not pelanggan:
		return 5
	return kena


# --- AC-10: zona ---

func _test_zona_literal() -> void:
	_judul.call("Zona rumah dekat di rute = cermin seberang: koordinat literal di awal kavling 50 (AC-10, P-5)")
	var z: Array[ZonaSasaran.Zona] = ZonaSasaran.zona_rumah_dekat_rute(50.0, true, 0, "per_uji@8")
	check(z.size() == 3, "tiga zona dekat (kotak surat, halaman, teras; tanpa jendela)")
	if z.size() != 3:
		return
	check(z[0].jenis == ZonaSasaran.Jenis.KOTAK_SURAT and _sama(z[0].persegi, 1.75, 51.25, 1.0, 1.25), "kotak surat dekat [1,75; 51,25; 1,0 x 1,25] = cermin seberang [-2,75; 51,25; 1,0 x 1,25]")
	check(z[1].jenis == ZonaSasaran.Jenis.HALAMAN and _sama(z[1].persegi, 2.0, 49.5, 1.90625, 3.0), "halaman dekat [2,0; 49,5; 1,90625 x 3,0]: sampai badan rumah (pijak 5,0 - 1,09375 = 3,90625)")
	check(z[2].jenis == ZonaSasaran.Jenis.TERAS and _sama(z[2].persegi, 3.1875, 49.625, 0.875, 0.9375), "teras dekat dari geometri teras menjorok: pijak gambar (5,0; 51,0) + teras_ubin [-1,8125; -1,375; 0,875; 0,9375]")
	check(_sama(z[0].inti, 2.0, 51.625, 0.5, 0.5), "inti tepat kotak surat dekat [2,0; 51,625; 0,5 x 0,5] = cermin inti seberang")
	check(z[0].sisi == LoperAnim.Sisi.DEKAT and z[0].pelanggan and z[0].id_rumah == "per_uji@8" and z[2].id_rumah == "per_uji@8", "zona bersisi DEKAT, pelanggan, membawa id rumah")
	var seberang: Array[ZonaSasaran.Zona] = ZonaSasaran.zona_rumah_seberang(50.0, true)
	check(is_equal_approx(-(seberang[0].persegi.position.x + seberang[0].persegi.size.x), z[0].persegi.position.x) and seberang[0].persegi.size == z[0].persegi.size, "kotak surat dekat adalah cermin kotak surat seberang (ukuran sama)")
	var json: Dictionary = _json_rumah("limasan", true)
	var t: Array = json["teras_ubin"]
	check(Config.RUTE_RUMAH_DEKAT_TERAS_UBIN == ([float(t[0]), float(t[1]), float(t[2]), float(t[3])] as Array[float]), "Config.RUTE_RUMAH_DEKAT_TERAS_UBIN = teras_ubin JSON aset")
	var penutup: Array = json["penutup_ubin"]
	check(is_equal_approx(5.0 + float(penutup[0]), 3.90625) and is_equal_approx(2.0 + Config.RUTE_DEKAT_HALAMAN_UBIN[2], 3.90625), "tepi halaman dekat = pijak 5,0 + penutup_ubin[0] JSON = 3,90625")
	check(is_equal_approx(ZonaSasaran.maju_kotak_surat(_rumah(50.0, LoperAnim.Sisi.DEKAT)), 51.875), "maju_kotak_surat rumah dekat = awal + 1,875 (pusat zona kotak surat)")
	var bukan: Array[ZonaSasaran.Zona] = ZonaSasaran.zona_rumah_dekat_rute(50.0, false)
	check(not bukan[0].pelanggan and ZonaSasaran.klasifikasi(Vector2(2.25, -51.875), bukan) == ZonaSasaran.Hasil.BUKAN_PELANGGAN, "rumah dekat bukan pelanggan: kotak surat = BUKAN_PELANGGAN")
	var tetangga: Array[ZonaSasaran.Zona] = ZonaSasaran.zona_rumah_dekat_rute(54.0, true)
	var tumpang: int = 0
	for a: ZonaSasaran.Zona in z:
		for b: ZonaSasaran.Zona in tetangga:
			if a.persegi.intersects(b.persegi):
				tumpang += 1
	check(tumpang == 0, "zona dua rumah dekat bertetangga (petak 4 ubin) tidak bertumpuk")
	var salah_sisi: int = 0
	for a: ZonaSasaran.Zona in z:
		for b: ZonaSasaran.Zona in seberang:
			if a.persegi.intersects(b.persegi):
				salah_sisi += 1
	check(salah_sisi == 0, "zona dekat dan seberang tidak bertumpuk")
	var jalan_uji: Array[ZonaSasaran.Zona] = ZonaSasaran.zona_rumah_dekat(50.0, false)
	check(_sama(jalan_uji[0].persegi, 1.75, 51.25, 0.75, 1.25) and _sama(jalan_uji[2].persegi, 2.5, 50.25, 0.5, 1.5), "zona dekat JALAN UJI (placeholder) tidak berubah")


func _rumah(awal: float, sisi: LoperAnim.Sisi, jenis: String = "dekat_limasan", pelanggan: bool = true) -> RouteBuilder.RumahRute:
	var r: RouteBuilder.RumahRute = RouteBuilder.RumahRute.new()
	r.id = "uji@%d" % int(awal)
	r.maju_ubin = awal
	r.sisi = sisi
	r.jenis = jenis
	r.pelanggan = pelanggan
	r.pelanggan_boleh = true
	return r


func _test_zona_oracle_grid() -> void:
	_judul.call("Penilaian titik mendarat di rumah dekat: klasifikasi game = oracle independen (literal + JSON) di grid 1/16 ubin, pelanggan dan bukan (AC-10)")
	var json: Dictionary = _json_rumah("pelana_lintang", true)
	var teras: Array = json["teras_ubin"]
	var pen: float = float((json["penutup_ubin"] as Array)[0])
	var beda: int = 0
	var jumlah: int = 0
	var hitung: Dictionary = {}
	for pelanggan: bool in [true, false]:
		var zona: Array[ZonaSasaran.Zona] = ZonaSasaran.zona_rumah_dekat_rute(40.0, pelanggan, 0, "o@40")
		for i: int in range(97):
			for k: int in range(97):
				var titik: Vector2 = Vector2(-1.0 + float(i) / 16.0, -(38.0 + float(k) / 16.0))
				var harap: int = _kelas_oracle(titik, 40.0, pelanggan, teras, pen)
				var dapat: ZonaSasaran.Hasil = ZonaSasaran.klasifikasi(titik, zona)
				var dapat_kelas: int = 0
				match dapat:
					ZonaSasaran.Hasil.KOTAK_SURAT: dapat_kelas = 1
					ZonaSasaran.Hasil.TERAS: dapat_kelas = 2
					ZonaSasaran.Hasil.HALAMAN: dapat_kelas = 3
					ZonaSasaran.Hasil.BUKAN_PELANGGAN: dapat_kelas = 5
				jumlah += 1
				hitung[dapat_kelas] = int(hitung.get(dapat_kelas, 0)) + 1
				if harap != dapat_kelas:
					beda += 1
	check(beda == 0, "klasifikasi %d titik grid: 0 beda dari oracle (%d beda)" % [jumlah, beda])
	check(int(hitung.get(1, 0)) > 100 and int(hitung.get(2, 0)) > 100 and int(hitung.get(3, 0)) > 1000 and int(hitung.get(5, 0)) > 1000 and int(hitung.get(0, 0)) > 1000, "kontrol: grid memuat kotak surat, teras, halaman, bukan pelanggan, dan meleset: %s" % [hitung])


# --- AC-7: data ---

func _data_mentah(id: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("%s/%s.json" % [FOLDER_RUTE, id])) as Dictionary


func _test_data_nyata() -> void:
	_judul.call("Data segmen nyata: kandidat pelanggan dekat, pengecualian anjing, kotak surat dekat bebas dekor dan simpang (AC-7)")
	var kumpulan: PemuatRute.Kumpulan = PemuatRute.muat_folder(FOLDER_RUTE)
	check(kumpulan.galat.is_empty() and kumpulan.segmen.size() == 9, "9 segmen nyata sah, 0 galat: %s" % [kumpulan.galat])
	var bukan_boleh: Array = []
	var boleh: int = 0
	var tumpang_anjing: Array = []
	var tumpang_dekor: int = 0
	var tumpang_pita: int = 0
	for berkas: String in PemuatRute.daftar_berkas(FOLDER_RUTE):
		var d: Dictionary = _data_mentah(berkas.get_basename())
		check(d["tag"]["sisi_pelanggan"] == "dua_sisi", "%s: tag sisi_pelanggan dua_sisi (ada rumah boleh di dua sisi)" % berkas)
		for r: Variant in d["rumah"]:
			var rumah: Dictionary = r
			if rumah["sisi"] != "dekat":
				continue
			var pos: float = float(rumah["pos"])
			if rumah["pelanggan_boleh"]:
				boleh += 1
			else:
				bukan_boleh.append([d["id"], int(pos)])
			# Oracle literal: zona kotak surat dekat lateral 1,75 .. 2,75, maju pos + 1,25 .. pos + 2,5; anjing lateral 2,5 .. 3,0, maju p -+ 0,25.
			var kotak: Rect2 = Rect2(1.75, pos + 1.25, 1.0, 1.25)
			for o: Variant in d["objek"]:
				var objek: Dictionary = o
				if objek["jalur"] == "dekat" and objek["jenis"] == "anjing_penjaga":
					var p: float = float(objek["pos"])
					if Rect2(2.5, p - 0.25, 0.5, 0.5).intersects(kotak):
						tumpang_anjing.append([d["id"], int(pos)])
			for x: Variant in d.get("dekor", []):
				var dekor: Dictionary = x
				if dekor["sisi"] != "dekat":
					continue
				var setengah: float = 0.125 if dekor["jenis"] == "lampu_jalan" else 0.25
				var lateral: float = 2.25 if dekor["jenis"] == "lampu_jalan" else 2.5
				var tapak: Rect2 = Rect2(lateral - setengah, float(dekor["pos"]) - setengah, setengah * 2.0, setengah * 2.0)
				if tapak.intersects(kotak):
					tumpang_dekor += 1
			for sp: Variant in d.get("simpang", []):
				var simpang: Dictionary = sp
				if simpang["sisi"] != "dekat":
					continue
				var s: float = float(simpang["pos"])
				if s - 1.5 < pos + 2.5 and s + 3.5 > pos - 0.5:
					tumpang_pita += 1
	check(boleh == 34 and bukan_boleh.size() == 2, "34 dari 36 rumah dekat pelanggan_boleh (dapat %d, bukan %d)" % [boleh, bukan_boleh.size()])
	check(bukan_boleh == DEKAT_BUKAN_BOLEH, "rumah dekat bukan kandidat persis %s (dapat %s)" % [DEKAT_BUKAN_BOLEH, bukan_boleh])
	check(tumpang_anjing == DEKAT_BUKAN_BOLEH, "oracle literal: rumah dekat yang zona kotak suratnya beririsan dengan anjing dekat = tepat dua rumah bukan kandidat (dapat %s)" % [tumpang_anjing])
	check(tumpang_dekor == 0 and tumpang_pita == 0, "kotak surat dekat semua rumah bebas dekor (%d) dan pita simpang (%d)" % [tumpang_dekor, tumpang_pita])
	# Jalan masuk garasi hanya di lateral negatif: tidak pernah menjangkau zona dekat (lateral positif).
	var jalan_masuk_dekat: int = 0
	for pos: int in range(3, 41):
		if SegmenRute.bentuk_jalan_masuk(float(pos)).end.x > 0.0:
			jalan_masuk_dekat += 1
	check(jalan_masuk_dekat == 0, "jalan masuk garasi berakhir di lateral <= 0 untuk semua pos: tidak menjangkau zona kotak surat dekat")


func _segmen_dasar() -> Dictionary:
	return {
		"id": "uji_b", "distrik": "perumahan", "panjang": 32,
		"tag": {"tingkat": "tenang", "sisi_pelanggan": "dua_sisi", "posisi": "tengah"},
		"rumah": [
			{"pos": 6, "sisi": "seberang", "jenis": "limasan", "pelanggan_boleh": true},
			{"pos": 10, "sisi": "dekat", "jenis": "dekat_limasan", "pelanggan_boleh": true},
		],
		"objek": [],
		"titik_misi": [],
	}


func _galat(d: Dictionary) -> Array[String]:
	return SegmenRute.parse(d).galat


func _memuat(d: Dictionary, kata: String) -> bool:
	for g: String in _galat(d):
		if g.contains(kata):
			return true
	return false


func _test_validasi_segmen() -> void:
	_judul.call("Validasi segmen: kotak surat dekat tidak bertumpuk dengan rintangan, dekor, simpang; tag sisi_pelanggan sesuai isi (AC-7, tes negatif satu per satu + positif)")
	check(_galat(_segmen_dasar()).is_empty(), "segmen dasar dua sisi sah")
	# Rintangan.
	var anjing: Dictionary = _segmen_dasar()
	anjing["objek"] = [{"jenis": "anjing_penjaga", "pos": 12, "jalur": "dekat", "tanda_ubin": 9}]
	check(_memuat(anjing, "menimpa zona kotak surat atau teras rumah dekat pelanggan di pos 10"), "negatif: anjing dekat @12 menimpa zona kotak surat rumah dekat pelanggan @10 ditolak")
	var anjing_jauh: Dictionary = _segmen_dasar()
	anjing_jauh["objek"] = [{"jenis": "anjing_penjaga", "pos": 11, "jalur": "dekat", "tanda_ubin": 9}]
	check(_galat(anjing_jauh).is_empty(), "positif: anjing dekat @11 hanya menyentuh tepi zona (maju 11,25) sah")
	var anjing_bukan: Dictionary = _segmen_dasar()
	anjing_bukan["objek"] = [{"jenis": "anjing_penjaga", "pos": 12, "jalur": "dekat", "tanda_ubin": 9}]
	((anjing_bukan["rumah"] as Array)[1] as Dictionary)["pelanggan_boleh"] = false
	(anjing_bukan["tag"] as Dictionary)["sisi_pelanggan"] = "seberang"
	check(_galat(anjing_bukan).is_empty(), "positif: rumah dekat bukan kandidat boleh berbagi halaman dengan anjing @12 (kotak surat abu-abu hiasan)")
	var anjing_seberang: Dictionary = _segmen_dasar()
	anjing_seberang["objek"] = [{"jenis": "anjing_penjaga", "pos": 12, "jalur": "seberang", "tanda_ubin": 9}]
	check(_galat(anjing_seberang).is_empty(), "positif: anjing seberang @12 tidak menyentuh zona dekat")
	var mobil: Dictionary = _segmen_dasar()
	mobil["objek"] = [{"jenis": "mobil_garasi", "pos": 10, "jalur": "dekat", "tanda_ubin": 9}]
	check(_memuat(mobil, "mobil_garasi di pos 10 (jalur dekat) menimpa zona kotak surat atau teras rumah dekat pelanggan di pos 10"), "negatif: lintasan mobil garasi dekat @10 menimpa teras/kotak surat dekat ditolak")
	# Dekor (aturan lama, geometri zona baru).
	var pohon: Dictionary = _segmen_dasar()
	pohon["dekor"] = [{"jenis": "pohon", "pos": 12, "sisi": "dekat", "varian": "rindang"}]
	check(_memuat(pohon, "menimpa zona teras atau kotak surat rumah dekat di pos 10"), "negatif: pohon dekat @12 di kotak surat dekat ditolak")
	var lampu: Dictionary = _segmen_dasar()
	lampu["dekor"] = [{"jenis": "lampu_jalan", "pos": 12, "sisi": "dekat", "varian": "lengan"}]
	check(_memuat(lampu, "menimpa zona teras atau kotak surat rumah dekat di pos 10"), "negatif: lampu dekat @12 (lateral 2,25 di dalam 1,75 .. 2,75) ditolak")
	var pohon_ok: Dictionary = _segmen_dasar()
	pohon_ok["dekor"] = [{"jenis": "pohon", "pos": 8, "sisi": "dekat", "varian": "rindang"}]
	check(_galat(pohon_ok).is_empty(), "positif: pohon dekat @8 (maju 7,75 .. 8,25) jauh dari kotak surat sah")
	# Simpang.
	var simpang: Dictionary = _segmen_dasar()
	simpang["simpang"] = [{"pos": 9, "sisi": "dekat"}]
	check(_memuat(simpang, "memotong zona KOTAK_SURAT rumah dekat di pos 10"), "negatif: simpang dekat @9 (pita 7,5 .. 12,5) memotong zona kotak surat dekat ditolak")
	var simpang_seb: Dictionary = _segmen_dasar()
	simpang_seb["simpang"] = [{"pos": 14, "sisi": "seberang"}]
	check(_galat(simpang_seb).is_empty(), "positif: simpang seberang @14 tidak menyentuh rumah dekat")
	# Tag.
	var tag_a: Dictionary = _segmen_dasar()
	((tag_a["rumah"] as Array)[1] as Dictionary)["pelanggan_boleh"] = false
	check(_memuat(tag_a, "sisi_pelanggan 'dua_sisi' tidak sesuai isi"), "negatif: dua_sisi tanpa rumah dekat yang boleh ditolak")
	var tag_b: Dictionary = _segmen_dasar()
	(tag_b["tag"] as Dictionary)["sisi_pelanggan"] = "seberang"
	check(_memuat(tag_b, "sisi_pelanggan 'seberang' tidak sesuai isi"), "negatif: seberang padahal ada rumah dekat yang boleh ditolak")
	var tag_c: Dictionary = _segmen_dasar()
	(tag_c["tag"] as Dictionary)["sisi_pelanggan"] = "dekat"
	check(_memuat(tag_c, "sisi_pelanggan 'dekat' tidak sesuai isi"), "negatif: dekat padahal ada rumah seberang yang boleh ditolak")
	var tag_d: Dictionary = _segmen_dasar()
	((tag_d["rumah"] as Array)[0] as Dictionary)["pelanggan_boleh"] = false
	(tag_d["tag"] as Dictionary)["sisi_pelanggan"] = "dekat"
	check(_galat(tag_d).is_empty(), "positif: dekat bila hanya rumah dekat yang boleh sah")
	var tag_e: Dictionary = _segmen_dasar()
	((tag_e["rumah"] as Array)[0] as Dictionary)["pelanggan_boleh"] = false
	check(_memuat(tag_e, "sisi_pelanggan 'dua_sisi' tidak sesuai isi"), "negatif: dua_sisi tanpa rumah seberang yang boleh ditolak")
	var tag_f: Dictionary = _segmen_dasar()
	((tag_f["rumah"] as Array)[1] as Dictionary)["pelanggan_boleh"] = false
	(tag_f["tag"] as Dictionary)["sisi_pelanggan"] = "seberang"
	check(_galat(tag_f).is_empty(), "positif: seberang bila tidak ada rumah dekat yang boleh sah")
	check(SegmenRute.rintangan_menimpa_zona_dekat("anjing_penjaga", 12.0, LoperAnim.Sisi.DEKAT, 10.0, LoperAnim.Sisi.DEKAT) and not SegmenRute.rintangan_menimpa_zona_dekat("anjing_penjaga", 12.0, LoperAnim.Sisi.DEKAT, 10.0, LoperAnim.Sisi.SEBERANG) and not SegmenRute.rintangan_menimpa_zona_dekat("kucing", 12.0, LoperAnim.Sisi.DEKAT, 10.0, LoperAnim.Sisi.DEKAT), "rintangan_menimpa_zona_dekat: hanya rumah dekat, jenis dikenal")


# --- AC-8: RouteBuilder dari hari ---

func _test_hari_1_2_identik() -> void:
	_judul.call("RouteBuilder hari 1 dan 2: rute identik main (60 seed, golden dihitung di main), tanpa pelanggan dekat; tanpa hari = hari 1 (AC-8, D-2)")
	var pustaka: Array[SegmenRute] = _pustaka()
	var cocok: int = 0
	var salah: Array[int] = []
	var sama_hari: int = 0
	var dekat_total: int = 0
	var boleh_dekat_ada: int = 0
	for i: int in range(60):
		var seed_i: int = SEED_DEV + 7 * i
		var tanpa: RouteBuilder.Hasil = RouteBuilder.bangun(seed_i, pustaka)
		var h1: RouteBuilder.Hasil = RouteBuilder.bangun(seed_i, pustaka, 1)
		var h2: RouteBuilder.Hasil = RouteBuilder.bangun(seed_i, pustaka, 2)
		if tanpa.sah() and _fnv(_identitas(tanpa.rute)) == GOLDEN_HARI1[i]:
			cocok += 1
		else:
			salah.append(i)
		if h1.sah() and h2.sah() and _identitas(h1.rute) == _identitas(tanpa.rute) and _identitas(h2.rute) == _identitas(tanpa.rute):
			sama_hari += 1
		dekat_total += RouteBuilder.jumlah_dekat(tanpa.rute) + RouteBuilder.jumlah_dekat(h2.rute)
		for r: RouteBuilder.RumahRute in tanpa.rute.rumah:
			if r.sisi == LoperAnim.Sisi.DEKAT and r.pelanggan_boleh:
				boleh_dekat_ada += 1
	check(cocok == 60 and GOLDEN_HARI1.size() == 60, "60 rute tanpa hari: identitas = golden main (%d cocok, salah di %s)" % [cocok, salah])
	check(sama_hari == 60, "bangun tanpa hari = hari 1 = hari 2 untuk seed yang sama (%d dari 60)" % sama_hari)
	check(dekat_total == 0 and boleh_dekat_ada > 0, "hari 1 dan 2: 0 pelanggan dekat walau rumah dekat boleh (%d rumah dekat boleh di data)" % boleh_dekat_ada)
	check(not RouteBuilder.hari_ada_pelanggan_dekat(1) and not RouteBuilder.hari_ada_pelanggan_dekat(2) and RouteBuilder.hari_ada_pelanggan_dekat(3) and RouteBuilder.hari_ada_pelanggan_dekat(4) and RouteBuilder.hari_ada_pelanggan_dekat(102), "hari mulai pelanggan dekat = 3 (2 tidak, 3 ya)")


func _test_hari_ke_atas() -> void:
	_judul.call("RouteBuilder hari >= 3: tepat 8 atau 9 dari 25 di sisi dekat, 100 hari (3..102), celah gabungan <= 20, deterministik dari seed hari (AC-8)")
	var pustaka: Array[SegmenRute] = _pustaka()
	var u: UkurHariDekat.Hasil = UkurHariDekat.ukur(3, 102, pustaka)
	print("ukur hari 3..102: n=%d gagal=%d sebaran=%s celah_gabungan=%s seberang=%s dekat=%s tenggat=%s panjang=%s" % [u.n, u.gagal, u.sebaran, u.celah_gabungan, u.celah_seberang, u.celah_dekat, u.tenggat, u.panjang])
	check(u.n == 100 and u.gagal == 0, "100 hari semuanya sah (gagal %d)" % u.gagal)
	check(u.sebaran == SEBARAN_100_HARI, "jumlah dekat per rute hanya 8 atau 9, sebaran %s = golden %s" % [u.sebaran, SEBARAN_100_HARI])
	check(u.pelanggan_total_salah == 0 and u.dekat_bukan_boleh == 0, "tiap rute tepat 25 pelanggan, semuanya rumah pelanggan_boleh")
	check(u.celah_gabungan[2] <= Config.RUTE_PELANGGAN_JARAK_MAKS_UBIN and u.celah_dekat[0] > 0.0 and u.celah_gabungan[0] > 0.0, "celah gabungan maks %.1f <= 20 dan min %.1f > 0" % [u.celah_gabungan[2], u.celah_gabungan[0]])
	var h3: RouteBuilder.Hasil = RouteBuilder.bangun(SeedHari.rute(3), pustaka, 3)
	var h3b: RouteBuilder.Hasil = RouteBuilder.bangun(SeedHari.rute(3), pustaka, 3)
	var h50: RouteBuilder.Hasil = RouteBuilder.bangun(SeedHari.rute(3), pustaka, 50)
	var h2: RouteBuilder.Hasil = RouteBuilder.bangun(SeedHari.rute(3), pustaka, 2)
	check(h3.sah() and _identitas(h3.rute) == _identitas(h3b.rute), "seed sama + hari sama = rute sama")
	check(_identitas(h3.rute) == _identitas(h50.rute) and h3.rute.hari == 3 and h50.rute.hari == 50, "hari tidak ikut seed: hari 3 dan hari 50 dengan seed sama = rute sama (hanya ambang hari)")
	check(_identitas(h3.rute) != _identitas(h2.rute) and RouteBuilder.jumlah_dekat(h2.rute) == 0, "seed sama: hari 2 tanpa pelanggan dekat berbeda dari hari 3")
	var campur: int = 0
	var urut: bool = true
	for p: RouteBuilder.RumahRute in h3.rute.pelanggan:
		if p.sisi == LoperAnim.Sisi.DEKAT:
			campur += 1
	for i: int in range(1, h3.rute.pelanggan.size()):
		if h3.rute.pelanggan[i].maju_ubin < h3.rute.pelanggan[i - 1].maju_ubin:
			urut = false
	check(campur == RouteBuilder.jumlah_dekat(h3.rute) and urut, "daftar pelanggan gabungan urut maju (dua sisi bercampur)")
	var koran: bool = h3.rute.koran_awal == 30 and h3.rute.id_pemberi_tip.size() == 7
	check(koran, "koran awal 30 dan 7 pemberi tip (25 pelanggan) tidak berubah")
	var misi_seberang: bool = true
	var rencana_data: DataMisi = null
	for t: RouteBuilder.TitikMisiRute in h3.rute.titik_misi:
		if t.sisi != LoperAnim.Sisi.SEBERANG:
			misi_seberang = false
	check(misi_seberang and rencana_data == null, "titik misi data tetap di rumah seberang")


func _test_periksa_rute_hari() -> void:
	_judul.call("RouteBuilder.periksa_rute diperluas: pelanggan dekat hanya hari >= 3, rumah dekat boleh, kuota 8-9, celah gabungan (mutan, AC-8)")
	var pustaka: Array[SegmenRute] = _pustaka()
	var r: RouteBuilder.Rute = RouteBuilder.bangun(SeedHari.rute(5), pustaka, 5).rute
	check(r != null and RouteBuilder.periksa_rute(r).is_empty() and r.hari == 5, "rute hari 5 lolos periksa_rute")
	if r == null:
		return
	# 1. Hari diganti 2: ada pelanggan dekat.
	r.hari = 2
	check(_berisi(RouteBuilder.periksa_rute(r), "punya %d pelanggan dekat, seharusnya 0" % RouteBuilder.jumlah_dekat(r)) and _berisi(RouteBuilder.periksa_rute(r), "bukan rumah yang boleh untuk hari 2"), "mutan: pelanggan dekat di hari 2 ditolak")
	r.hari = 5
	# 2. Satu pelanggan dekat ditukar dengan seberang (kuota 7 atau 10).
	var dekat_idx: int = -1
	for i: int in range(r.pelanggan.size()):
		if r.pelanggan[i].sisi == LoperAnim.Sisi.DEKAT:
			dekat_idx = i
			break
	var kuota: int = RouteBuilder.jumlah_dekat(r)
	var asli_sisi: LoperAnim.Sisi = r.pelanggan[dekat_idx].sisi
	r.pelanggan[dekat_idx].sisi = LoperAnim.Sisi.SEBERANG
	var ganti: int = RouteBuilder.jumlah_dekat(r)
	check(ganti == kuota - 1, "kontrol: jumlah dekat turun satu")
	if kuota == 8:
		check(_berisi(RouteBuilder.periksa_rute(r), "punya 7 pelanggan dekat, seharusnya 8 sampai 9"), "mutan: 7 pelanggan dekat ditolak")
	r.pelanggan[dekat_idx].sisi = asli_sisi
	# 3. Dekat 0 di hari 5: semua dekat dijadikan seberang.
	var dikembalikan: Array[LoperAnim.Sisi] = []
	for p: RouteBuilder.RumahRute in r.pelanggan:
		dikembalikan.append(p.sisi)
		if p.sisi == LoperAnim.Sisi.DEKAT:
			p.sisi = LoperAnim.Sisi.SEBERANG
	check(_berisi(RouteBuilder.periksa_rute(r), "punya 0 pelanggan dekat, seharusnya 8 sampai 9"), "mutan: 0 pelanggan dekat di hari 5 ditolak")
	for i: int in range(r.pelanggan.size()):
		r.pelanggan[i].sisi = dikembalikan[i]
	# 4. Pelanggan dekat bukan pelanggan_boleh.
	r.pelanggan[dekat_idx].pelanggan_boleh = false
	check(_berisi(RouteBuilder.periksa_rute(r), "bukan rumah yang boleh untuk hari 5"), "mutan: pelanggan dekat dari rumah tidak boleh ditolak")
	r.pelanggan[dekat_idx].pelanggan_boleh = true
	# 5. Celah gabungan > 20.
	var tengah: int = r.pelanggan.size() / 2
	var maju_asli: float = r.pelanggan[tengah].maju_ubin
	r.pelanggan[tengah].maju_ubin = r.pelanggan[tengah - 1].maju_ubin + 21.0
	check(_berisi(RouteBuilder.periksa_rute(r), "melebihi 20.0"), "mutan: celah gabungan 21 ubin ditolak")
	r.pelanggan[tengah].maju_ubin = maju_asli
	check(RouteBuilder.periksa_rute(r).is_empty(), "rute dipulihkan lolos lagi")


func _berisi(galat: Array[String], kata: String) -> bool:
	for g: String in galat:
		if g.contains(kata):
			return true
	return false


func _test_kandidat_kurang() -> void:
	_judul.call("RouteBuilder hari 3: kandidat dekat kurang dari kuota ditolak dengan galat, hari 2 tetap jalan (AC-8)")
	var tanpa_dekat: Array[SegmenRute] = []
	for s: SegmenRute in _pustaka():
		var d: Dictionary = _data_mentah(s.id)
		for r: Variant in d["rumah"]:
			(r as Dictionary)["pelanggan_boleh"] = false if (r as Dictionary)["sisi"] == "dekat" else (r as Dictionary)["pelanggan_boleh"]
		(d["tag"] as Dictionary)["sisi_pelanggan"] = "seberang"
		var hasil: SegmenRute.Hasil = SegmenRute.parse(d)
		check(hasil.sah(), "%s tanpa kandidat dekat tetap sah (%s)" % [s.id, hasil.galat])
		tanpa_dekat.append(hasil.segmen)
	var h3: RouteBuilder.Hasil = RouteBuilder.bangun(SeedHari.rute(3), tanpa_dekat, 3)
	check(not h3.sah() and h3.rute == null and _berisi(h3.galat, "kandidat pelanggan dekat 0 (butuh"), "hari 3 tanpa kandidat dekat ditolak: %s" % ["; ".join(h3.galat)])
	var h2: RouteBuilder.Hasil = RouteBuilder.bangun(SeedHari.rute(2), tanpa_dekat, 2)
	check(h2.sah() and RouteBuilder.jumlah_dekat(h2.rute) == 0, "hari 2 tanpa kandidat dekat tetap sah")
