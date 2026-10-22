class_name TesSisiDekat
extends RefCounted
## Tes run fase5d-sisi-dekat bagian A (AC-3 sampai AC-6; menggantikan `tes_tembok.gd` run 5B karena tembok sisi dekat dilepas, P-1): halaman terbuka tanpa tembok, rumah dekat
## didesain ulang (teras menjorok, tanpa kotak surat terpanggang) digambar mundur 0,5 ubin, kotak penutup = sprite nyata, Y-sort, dan ukur piksel sasaran dan pemain.
##
## Harapan ditulis literal atau dihitung tes dengan cara lain dari kode produksi:
## - Tabel `Config` dibandingkan dengan JSON dan ukuran PNG aset (hasil `tools/env_art/fase3.py`).
## - Letak gambar: proyeksi iso 2:1 ditulis ulang (`_layar`), pusat gambar rumah dekat literal (tapak logika 3..6 -> 4,5, + mundur 0,5 = 5,0).
## - Geometri logika tidak berubah: 1000 lemparan acak berseed ke rute nyata = checksum yang dihitung SEBELUM run 5B (commit 41cc11b), sama dengan tes tembok lama.
## - Ukur piksel AC-6: `UkurSisiDekat` (oracle piksel independen, PNG nyata). Batas atas = sasaran SPEC (kotak surat 0, zona <= 5%, pemain lajur 0, trotoar 0) dan angka terukur
##   2026-10-22 sebagai batas regresi (zona kotak 2,58%, halaman 32,6%, teras tertimpa tetangga 24,4%). Kontrol: rumah tanpa mundur (lateral 4,5) memang terukur menutupi.

const BERKAS_RUTE: String = "res://scenes/rute/rute.tscn"
const FOLDER_RUMAH: String = "res://assets/sprites/houses/perumahan"
const FOLDER_RUTE: String = "res://assets/data/routes/perumahan"
const SEED_DEV: int = 20261016
const JENIS: Array[String] = ["limasan", "pelana_lintang", "pelana_sejajar"]
## Pijak (x, y) dan ukuran PNG rumah dekat dari JSON aset run 5D (ditulis literal; pelanggan dan bukan sama).
const PIJAK_DEKAT: Dictionary = {"limasan": [110, 127, 257, 204], "pelana_lintang": [110, 126, 258, 204], "pelana_sejajar": [110, 122, 257, 200]}
## Kotak penutup per jenis [lateral_min, maju_min, lebar, panjang, tinggi] relatif pijak gambar (literal dari JSON aset).
const PENUTUP_DEKAT: Dictionary = {
	"limasan": [-1.09375, -1.40625, 3.06875, 2.8125, 1.625],
	"pelana_lintang": [-1.09375, -1.40625, 3.1125, 2.8125, 1.6875],
	"pelana_sejajar": [-1.09375, -1.375, 3.1125, 2.75, 1.5625],
}
const TERAS_DEKAT: Array[float] = [-1.8125, -1.375, 0.875, 0.9375]
## Checksum 1000 lemparan acak berseed ke rute seed 20261016 dihitung di commit 41cc11b (sebelum run 5B; tes tembok lama): [lemparan, jumlah zona, tertutup, checksum].
const GOLDEN_LEMPAR: Array[int] = [1000, 11137, 339, 992255826]
## Batas regresi AC-6 (angka terukur 2026-10-22, `UkurSisiDekat`, kasus terburuk antarjenis dan antartetangga): zona kotak surat cermin, zona dekat lama, halaman, teras.
const BATAS_ZONA_KOTAK: float = 0.0258
const BATAS_ZONA_KOTAK_LAMA: float = 0.0
const BATAS_HALAMAN: float = 0.3256
const BATAS_TERAS_TETANGGA: float = 0.2441

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
	_test_konstanta()
	_test_aset_sama_dengan_config()
	_test_geometri()
	_test_lemparan_identik()
	_test_ukur_sasaran()
	_test_ukur_pemain()
	_test_rujukan_tanpa_tembok()
	await _test_scene()


func _test_konstanta() -> void:
	_judul.call("Run 5D: mundur rumah dekat 0,5 (pemilik 2026-10-22), konstanta tembok dibuang, geometri logika tetap (AC-4)")
	check(Config.RUTE_RUMAH_DEKAT_MUNDUR_UBIN == 0.5, "RUTE_RUMAH_DEKAT_MUNDUR_UBIN = 0,5 (literal; dulu 1,25 dengan tembok)")
	check(Config.RUTE_RUMAH_DEKAT_X_UBIN == 3.0 and Config.RUTE_RUMAH_PANJANG_UBIN == 3.0 and Config.RUTE_RUMAH_DALAM_UBIN == 3.0 and Config.RUTE_RUMAH_TINGGI_UBIN == 2.0, "konstanta tapak logika tidak berubah: kaki fasad dekat 3,0, rumah 3x3x2")
	var sumber: String = FileAccess.get_file_as_string("res://scripts/config.gd")
	check(not sumber.contains("RUTE_TEMBOK") and not sumber.contains("SPRITE_TEMBOK"), "config.gd tidak lagi memuat RUTE_TEMBOK_* dan SPRITE_TEMBOK*")
	check(Config.RUTE_RUMAH_DEKAT_JENIS == (["dekat_limasan", "dekat_pelana_lintang", "dekat_pelana_sejajar"] as Array[String]), "tiga jenis rumah dekat, urut tetap")


func _test_aset_sama_dengan_config() -> void:
	_judul.call("Rumah dekat baru: pijak, kotak penutup, teras di Config = JSON aset = PNG; tanpa kotak surat terpanggang (AC-3, AC-5)")
	var salah: Array[String] = []
	for j: String in JENIS:
		for p: String in ["pelanggan", "bukan"]:
			var nama: String = "house_perumahan_dekat_%s_%s" % [j, p]
			var json: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("%s/%s.json" % [FOLDER_RUMAH, nama])) as Dictionary
			var gambar: Image = (load("%s/%s.png" % [FOLDER_RUMAH, nama]) as Texture2D).get_image()
			var harap: Array = PIJAK_DEKAT[j]
			var jangkar: Array = json["ground_anchor"]
			if int(jangkar[0]) != harap[0] or int(jangkar[1]) != harap[1] or gambar.get_width() != harap[2] or gambar.get_height() != harap[3]:
				salah.append("%s: pijak %s ukuran %dx%d" % [nama, jangkar, gambar.get_width(), gambar.get_height()])
			if SpriteRumah.titik_pijak(nama) != Vector2i(harap[0], harap[1]):
				salah.append("%s: Config pijak %s" % [nama, SpriteRumah.titik_pijak(nama)])
			var penutup: Array = (json["penutup_ubin"] as Array) + [json["penutup_tinggi_ubin"]]
			var k: int = Config.RUTE_RUMAH_DEKAT_JENIS.find("dekat_" + j)
			var tabel: Array = [Config.RUTE_RUMAH_DEKAT_PENUTUP_LATERAL_UBIN[k], Config.RUTE_RUMAH_DEKAT_PENUTUP_MAJU_UBIN[k], Config.RUTE_RUMAH_DEKAT_PENUTUP_LEBAR_UBIN[k], Config.RUTE_RUMAH_DEKAT_PENUTUP_PANJANG_UBIN[k], Config.RUTE_RUMAH_DEKAT_PENUTUP_TINGGI_UBIN[k]]
			if penutup != PENUTUP_DEKAT[j] or tabel != PENUTUP_DEKAT[j]:
				salah.append("%s: penutup JSON %s Config %s" % [nama, penutup, tabel])
			if json["teras_ubin"] != TERAS_DEKAT or Config.RUTE_RUMAH_DEKAT_TERAS_UBIN != TERAS_DEKAT:
				salah.append("%s: teras %s" % [nama, json["teras_ubin"]])
			if not String(json["note"]).contains("TANPA kotak surat"):
				salah.append("%s: catatan kotak surat" % nama)
	check(salah.is_empty(), "enam sprite rumah dekat: pijak, ukuran, penutup, teras = literal, Config = JSON: %s" % [salah])


func _test_geometri() -> void:
	_judul.call("Letak gambar dan kotak penutup rumah dekat: pusat gambar = tapak + 0,5; kotak = sprite nyata per jenis; logika tetap (AC-4, AC-5)")
	var dekat: RouteBuilder.RumahRute = _rumah(8.0, LoperAnim.Sisi.DEKAT, "dekat_limasan")
	check(SpriteRumah.pusat_tapak_dunia(dekat) == Vector2(4.5, -9.0) and SpriteRumah.pusat_gambar_dunia(dekat) == Vector2(5.0, -9.0), "pusat gambar rumah dekat di maju 8 = (5,0; -9) = tapak (4,5) + 0,5")
	check(PenutupPemain.tapak_rumah(LoperAnim.Sisi.DEKAT, 8.0) == Rect2(3.0, 7.5, 3.0, 3.0) and PenutupPemain.dari_rumah(dekat).tinggi_ubin == 2.0, "tapak logika rumah dekat tidak berubah (3,0; 7,5) 3x3 tinggi 2")
	for j: String in JENIS:
		var r: RouteBuilder.RumahRute = _rumah(8.0, LoperAnim.Sisi.DEKAT, "dekat_" + j)
		var p: Array = PENUTUP_DEKAT[j]
		var harap: Rect2 = Rect2(5.0 + float(p[0]), 9.0 + float(p[1]), float(p[2]), float(p[3]))
		var o: PenutupPemain.Objek = PenutupPemain.dari_rumah_gambar(r)
		check(o.tapak.is_equal_approx(harap) and is_equal_approx(o.tinggi_ubin, float(p[4])), "kotak penutup gambar %s di maju 8 = %s tinggi %.4f (dapat %s %.4f)" % [j, harap, p[4], o.tapak, o.tinggi_ubin])
	var seberang: RouteBuilder.RumahRute = _rumah(8.0, LoperAnim.Sisi.SEBERANG, "limasan")
	check(PenutupPemain.dari_rumah_gambar(seberang).tapak == Rect2(-6.0, 7.5, 3.0, 3.0) and PenutupPemain.dari_rumah_gambar(seberang).tinggi_ubin == 2.0, "rumah seberang: kotak gambar = tapak logika, tinggi 2 (tidak berubah)")
	var gabung: Rect2 = PenutupPemain.tapak_rumah_gambar(LoperAnim.Sisi.DEKAT, 8.0)
	check(is_equal_approx(gabung.position.x, 3.90625) and is_equal_approx(gabung.position.y, 7.59375) and is_equal_approx(gabung.end.y, 10.40625) and is_equal_approx(gabung.end.x, 7.01875), "tapak gambar dekat tanpa jenis = gabungan tiga jenis (3,906..7,019 x 7,594..10,406): %s" % gabung)
	check(SegmenRute.kavling_rumah(LoperAnim.Sisi.DEKAT, 8.0).position.y == 7.5 and SegmenRute.kavling_rumah(LoperAnim.Sisi.DEKAT, 8.0).end.y == 10.5, "kavling rumah dekat maju 8 = 7,5 .. 10,5 (tanpa tembok sampai 11)")


func _test_lemparan_identik() -> void:
	_judul.call("1000 lemparan acak berseed ke rute nyata: penilaian dan tertutup identik dengan sebelum tembok (geometri logika tidak berubah, AC-4)")
	var rute: RouteBuilder.Rute = RouteBuilder.bangun(SEED_DEV, PemuatRute.muat_folder(FOLDER_RUTE).segmen).rute
	var medan: MedanKoran = MedanKoran.dari_rute(rute)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7311
	var jumlah_zona: int = 0
	var tertutup: int = 0
	var checksum: int = 0
	for i: int in range(1000):
		var r: RouteBuilder.RumahRute = rute.rumah[rng.randi_range(0, rute.rumah.size() - 1)]
		var titik: Vector2 = Vector2(rng.randf_range(-4.5, 4.5), -(r.maju_ubin + rng.randf_range(-1.0, 3.5)))
		var zona: Array[ZonaSasaran.Zona] = medan.zona_sekitar(titik)
		jumlah_zona += zona.size()
		var kena: ZonaSasaran.Zona = ZonaSasaran.zona_kena(titik, zona)
		var hasil: int = int(ZonaSasaran.hasil_zona(kena))
		var kode: int = hasil * 131 + (_jumlah_huruf(kena.id_rumah) if kena != null else 7)
		var tutup: bool = medan.tertutup_titik(titik, rng.randf_range(0.0, 1.0))
		if tutup:
			tertutup += 1
		checksum = (checksum * 31 + kode + (1 if tutup else 0)) % 2147483647
	check(jumlah_zona == GOLDEN_LEMPAR[1] and tertutup == GOLDEN_LEMPAR[2] and checksum == GOLDEN_LEMPAR[3], "zona %d, tertutup %d, checksum %d = nilai sebelum run 5B %s" % [jumlah_zona, tertutup, checksum, GOLDEN_LEMPAR])


func _test_ukur_sasaran() -> void:
	_judul.call("AC-6 oracle piksel: kotak surat dekat 0%, zona kotak surat dekat <= 5%, halaman dan teras dicatat; enam sprite x tetangga enam sprite di +-4 ubin")
	var maks: Dictionary = {"kotak_badan": 0.0, "zona_kotak": 0.0, "zona_kotak_lama": 0.0, "halaman": 0.0, "teras_tetangga": 0.0}
	var jumlah: int = 0
	var kosong: int = 0
	for r: Array in UkurSisiDekat.semua_rumah():
		var daftar: Array = [[]]
		for n: Array in UkurSisiDekat.semua_rumah():
			for d: float in [-4.0, 4.0]:
				daftar.append([[n[0], n[1], d]])
		for tetangga: Array in daftar:
			for m: float in [8.0, 12.5]:
				var h: Dictionary = UkurSisiDekat.ukur_sasaran(r[0], r[1], m, tetangga)
				jumlah += 1
				if int(h["jumlah_kotak"]) < 100 or int(h["jumlah_zona"]) < 1000 or int(h["jumlah_teras"]) < 500:
					kosong += 1
				for kunci: String in maks.keys():
					maks[kunci] = maxf(float(maks[kunci]), float(h[kunci]))
	check(jumlah == 6 * 13 * 2 and kosong == 0, "%d pengukuran (6 sprite x (sendiri + 12 tetangga) x 2 kavling), tiap sasaran punya cukup piksel" % jumlah)
	check(float(maks["kotak_badan"]) == 0.0, "sprite kotak surat dekat (oranye/abu-abu, cermin 2,125; 1,75): 0%% tertimpa rumah dekat (terburuk %.4f)" % maks["kotak_badan"])
	check(float(maks["zona_kotak"]) <= 0.05 and float(maks["zona_kotak"]) <= BATAS_ZONA_KOTAK, "zona kotak surat dekat cermin: <= 5%% dan <= %.2f%% terukur (dapat %.4f)" % [BATAS_ZONA_KOTAK * 100.0, maks["zona_kotak"]])
	check(float(maks["zona_kotak_lama"]) <= BATAS_ZONA_KOTAK_LAMA + 0.0177 , "zona kotak surat dekat lama (jalan uji): <= 1,77%% (dapat %.4f)" % maks["zona_kotak_lama"])
	check(float(maks["halaman"]) <= BATAS_HALAMAN, "halaman dekat tertimpa rumah <= %.2f%% (dapat %.4f; terlihat >= 67%%)" % [BATAS_HALAMAN * 100.0, maks["halaman"]])
	check(float(maks["teras_tetangga"]) <= BATAS_TERAS_TETANGGA, "lantai teras rumah dekat tertimpa rumah tetangga <= %.2f%% (dapat %.4f; catatan untuk zona teras bagian B)" % [BATAS_TERAS_TETANGGA * 100.0, maks["teras_tetangga"]])
	# Kontrol: rumah yang sama tanpa mundur (lateral 4,5) dan tanpa desain teras rendah memang menutupi zona.
	var kontrol: Dictionary = UkurSisiDekat.ukur_sasaran("pelana_lintang", true, 8.0, [], 3.75)
	check(float(kontrol["kotak_badan"]) > 0.0 and float(kontrol["zona_kotak"]) > 0.05, "kontrol: rumah digambar 1,25 ubin lebih dekat ke jalan terukur menutupi kotak surat (%.3f) dan zona (%.3f)" % [kontrol["kotak_badan"], kontrol["zona_kotak"]])


func _test_ukur_pemain() -> void:
	_judul.call("AC-6 oracle piksel: pemain di lajur dekat dan trotoar dekat 0% tertimpa rumah dekat; kotak penutup sprite nyata menandai tiap tumpang")
	var lajur: float = 0.0
	var trotoar: float = 0.0
	var tak: int = 0
	var diperiksa: int = 0
	for r: Array in UkurSisiDekat.semua_rumah():
		var a: Dictionary = UkurSisiDekat.sapu_pemain(r[0], r[1], 8.0, 0.0, 1.0, 0.125)
		var b: Dictionary = UkurSisiDekat.sapu_pemain(r[0], r[1], 8.0, 1.0, 2.0, 0.125)
		lajur = maxf(lajur, float(a["pecahan_maks"]))
		trotoar = maxf(trotoar, float(b["pecahan_maks"]))
		tak += (a["tak_tertutup"] as Array).size() + (b["tak_tertutup"] as Array).size()
		diperiksa += int(a["diperiksa"]) + int(b["diperiksa"])
	check(diperiksa == 6 * 2 * 9 * 65, "sapuan pemain: %d posisi (6 sprite x 2 pita x 9 lateral x 65 maju)" % diperiksa)
	check(lajur == 0.0, "pemain di lajur dekat (lateral 0..1): 0%% tertimpa rumah dekat (dapat %.4f)" % lajur)
	check(trotoar == 0.0, "pemain di trotoar dekat (lateral 1..2): 0%% tertimpa rumah dekat tanpa pudar (dapat %.4f)" % trotoar)
	check(tak == 0, "tidak ada posisi tumpang yang tidak ditandai kotak penutup (%d)" % tak)
	# Kontrol: pemain di luar jalan (lateral 2..3,5, di halaman) memang tertimpa sebagian rumah dan kotak penutup sprite nyata menandai semuanya.
	var luar: Dictionary = UkurSisiDekat.sapu_pemain("pelana_lintang", false, 8.0, 2.5, 3.5, 0.25)
	check(float(luar["pecahan_maks"]) > 0.0 and int(luar["tumpang"]) > 0, "kontrol: pemain buatan di halaman (lateral 2,5..3,5) terukur tertimpa (%.3f, %d posisi)" % [luar["pecahan_maks"], luar["tumpang"]])


func _test_rujukan_tanpa_tembok() -> void:
	_judul.call("Tembok sisi dekat dilepas: tidak ada berkas, kelas, atau rujukan nama sprite tembok (AC-4)")
	var awalan: String = "house_" + "tembok_"
	var berkas: Array[String] = []
	for akar: String in ["res://scripts", "res://scenes", "res://assets/data", "res://translations"]:
		_kumpulkan(akar, berkas)
	for nama: String in DirAccess.get_files_at("res://tests"):
		if nama.ends_with(".gd") and not nama.begins_with("probe_"):
			berkas.append("res://tests/" + nama)
	var asing: Array[String] = []
	for jalur: String in berkas:
		var teks: String = FileAccess.get_file_as_string(jalur)
		if teks.contains(awalan) or teks.contains("Tembok" + "Dekat") or teks.contains("Varian" + "Tembok"):
			asing.append(jalur)
	check(berkas.size() > 100 and asing.is_empty(), "%d berkas dipindai, tidak ada rujukan sprite tembok atau dua kelas tembok lama: %s" % [berkas.size(), asing])
	var png: Array[String] = []
	for nama: String in DirAccess.get_files_at(FOLDER_RUMAH):
		if nama.begins_with(awalan):
			png.append(nama)
	check(png.is_empty(), "assets/sprites/houses/perumahan tidak memuat berkas tembok: %s" % [png])
	check(not FileAccess.file_exists("res://scripts/systems/tembok_dekat.gd") and not FileAccess.file_exists("res://scripts/systems/varian_tembok.gd"), "tembok_dekat.gd dan varian_tembok.gd dihapus")


func _test_scene() -> void:
	_judul.call("Scene rute: rumah dekat baru di (5,0; maju + 1), tanpa tembok, kotak penutup sprite nyata di penerap, Y-sort dengan sepeda, koran udara di atas Objek (AC-4, AC-5)")
	_tree.root.size = Vector2i(2340, 1080)
	var akar: RuteMain = (load(BERKAS_RUTE) as PackedScene).instantiate() as RuteMain
	_tree.root.add_child(akar)
	await _tree.process_frame
	await _tree.process_frame
	akar.set_process(false)
	(akar.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = false
	(akar.find_child("LoperAgen", true, false) as LoperSprite).set_process(false)
	var rute: RouteBuilder.Rute = akar.rute()
	var daur: RumahDaurRute = akar.daur()
	var objek: Node2D = akar.find_child("Objek", true, false) as Node2D
	var penerap: PenerapPenutup = akar.penerap_penutup()
	var salah: Array[String] = []
	var jumlah_dekat: int = 0
	var tembok: int = 0
	for jarak: float in [0.0, 60.0, 130.0, 200.0]:
		_taruh_sepeda(akar, jarak, 2.0)
		for anak: Node in objek.get_children():
			if String(anak.name).begins_with("Tembok"):
				tembok += 1
		for i: int in daur.indeks_tampil():
			var r: RouteBuilder.RumahRute = rute.rumah[i]
			if r.sisi != LoperAnim.Sisi.DEKAT:
				continue
			jumlah_dekat += 1
			var s: Sprite2D = daur.sprite_rumah(i)
			var j: String = r.jenis.trim_prefix("dekat_")
			var harap: Array = PIJAK_DEKAT[j]
			if s.position != _layar(5.0, r.maju_ubin + 1.0) or s.offset != -Vector2(harap[0], harap[1]):
				salah.append("%s: posisi %s offset %s" % [r.id, s.position, s.offset])
			if s.texture.resource_path != "%s/house_perumahan_dekat_%s_bukan.png" % [FOLDER_RUMAH, j]:
				salah.append("%s: tekstur %s" % [r.id, s.texture.resource_path])
			if s.get_parent() != objek or not objek.y_sort_enabled:
				salah.append("%s: bukan anak Objek Y-sort" % r.id)
			var o: PenutupPemain.Objek = penerap.objek_untuk(s)
			var p: Array = PENUTUP_DEKAT[j]
			var kotak: Rect2 = Rect2(5.0 + float(p[0]), r.maju_ubin + 1.0 + float(p[1]), float(p[2]), float(p[3]))
			if o == null or not o.tapak.is_equal_approx(kotak) or not is_equal_approx(o.tinggi_ubin, float(p[4])):
				salah.append("%s: kotak penerap %s" % [r.id, o.tapak if o != null else null])
			# Sepeda di trotoar dekat tidak pernah ditutup rumah dekat: alfa 1,0.
			if s.modulate.a != 1.0:
				salah.append("%s: alfa %.2f saat sepeda di trotoar dekat" % [r.id, s.modulate.a])
	check(jumlah_dekat >= 10 and tembok == 0, "scene: %d rumah dekat diperiksa, 0 node tembok" % jumlah_dekat)
	check(salah.is_empty(), "rumah dekat: letak (5,0; maju + 1), offset pijak, tekstur _bukan, anak Objek Y-sort, kotak penerap = sprite nyata, alfa 1,0 di trotoar: %s" % [salah.slice(0, 4)])
	var sepeda: Node2D = akar.find_child("Sepeda", true, false) as Node2D
	check(sepeda.get_parent() == objek, "sepeda anak Objek Y-sort yang sama dengan rumah (urutan gambar dari posisi tegak)")
	var udara: Node = akar.find_child("KoranUdara", true, false)
	check(udara != null and udara.get_index() > objek.get_index() and udara.get_parent() == objek.get_parent(), "KoranUdara digambar sesudah Objek: koran terbang ke sasaran dekat tidak pernah tertimpa rumah")
	(akar.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = OS.has_feature("editor")
	_tree.root.remove_child(akar)
	akar.free()


func _rumah(maju: float, sisi: LoperAnim.Sisi, jenis: String) -> RouteBuilder.RumahRute:
	var r: RouteBuilder.RumahRute = RouteBuilder.RumahRute.new()
	r.id_segmen = "x"
	r.pos = int(maju)
	r.id = "x@%d" % r.pos
	r.maju_ubin = maju
	r.sisi = sisi
	r.jenis = jenis
	return r


func _layar(lateral: float, maju: float) -> Vector2:
	return Vector2(roundf((lateral + maju) * 32.0), roundf((lateral - maju) * 16.0))


func _jumlah_huruf(teks: String) -> int:
	var j: int = 0
	for i: int in range(teks.length()):
		j += teks.unicode_at(i) * (i + 1)
	return j % 1000


func _kumpulkan(folder: String, hasil: Array[String]) -> void:
	for berkas: String in DirAccess.get_files_at(folder):
		if berkas.ends_with(".gd") or berkas.ends_with(".tscn") or berkas.ends_with(".json") or berkas.ends_with(".csv"):
			hasil.append("%s/%s" % [folder, berkas])
	for sub: String in DirAccess.get_directories_at(folder):
		_kumpulkan("%s/%s" % [folder, sub], hasil)


func _taruh_sepeda(akar: RuteMain, maju: float, lateral: float = 0.0) -> void:
	var sepeda: SepedaUji = akar.find_child("Sepeda", true, false) as SepedaUji
	var k: BikeMotion.Keadaan = sepeda.keadaan.salin()
	k.kecepatan_ud = 3.0
	k.lateral_ubin = lateral
	sepeda.keadaan = k
	sepeda.jarak_ubin = maju
	akar.perbarui(0.0)
