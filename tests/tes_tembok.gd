class_name TesTembok
extends RefCounted
## Tes run fase5b-tembok-dekor bagian B1, tembok sisi dekat (AC-4 sampai AC-8, AC-18 bagian tembok, D-2 dan D-3).
##
## Harapan ditulis sebagai literal atau dihitung tes dengan cara lain dari kode produksi:
## - Hash varian: nilai FNV-1a 32 bit untuk 12 id (vektor uji standar dan id rumah dekat nyata) dihitung di luar kode (skrip Python), ditulis literal.
## - Geometri modul: rumah dekat di maju m menghasilkan modul di m, m+1, m+2 (ujung belakang) dan tiang di m (arah rantai: lihat `TembokDekat`);
##   letak layar dari proyeksi iso 2:1 ditulis ulang (`_layar`).
## - Geometri tidak berubah (D-2): tapak rumah, zona rumah dekat, dan konstanta ditulis literal; 1000 lemparan acak berseed ke rute nyata dibandingkan dengan
##   checksum yang dihitung di kode SEBELUM run ini (commit 41cc11b).
## - Sasaran tidak tertutup (AC-8): pecahan piksel opak dari `UkurTembok`; nilai nol dijaga nol, nilai tidak nol (zona kotak surat dan teras) dicatat sebagai literal
##   hasil ukur dengan label BLOCKED (temuan untuk orchestrator, geometri tembok tidak digeser: keputusan pemilik).

const BERKAS_RUTE: String = "res://scenes/rute/rute.tscn"
const FOLDER_RUMAH: String = "res://assets/sprites/houses/perumahan"
const FOLDER_RUTE: String = "res://assets/data/routes/perumahan"
const SEED_DEV: int = 20261016
const DT: float = 1.0 / 60.0
const SKALA: int = 3
## Jendela daur (ubin), ditulis ulang dari `Config.RUTE_DAUR_*`.
const DAUR_MUNDUR: float = 20.0
const DAUR_MAJU: float = 30.0
## Nama lima sprite tembok yang sah dirujuk kode (hanya ini).
const NAMA_SAH: Array[String] = ["house_tembok_polos", "house_tembok_bata", "house_tembok_besi", "house_tembok_pot", "house_tembok_tiang"]
## FNV-1a 32 bit (id, nilai, indeks varian mod 4) dihitung di Python (`h ^= byte; h = h * 16777619 & 0xFFFFFFFF`, awal 2166136261), bukan oleh kode yang diuji.
const ORACLE_HASH: Array = [
	["", 2166136261, 1],
	["a", 3826002220, 0],
	["abc", 440920331, 3],
	["per_buka_01@8", 3212429950, 2],
	["per_buka_01@16", 3064473949, 1],
	["per_buka_01@24", 2728480284, 0],
	["per_buka_02@4", 3721452679, 3],
	["per_tengah_01@32", 2266993227, 3],
	["per_tengah_03@36", 119534277, 1],
	["per_tengah_04@12", 397220800, 0],
	["per_tutup_02@20", 3374254604, 0],
	["rumah_é@4", 412762447, 3],
]
## Banyaknya varian untuk 36 rumah dekat di sembilan segmen nyata (id `<id_segmen>@<pos>`), dihitung di Python: polos, bata, besi, pot.
const ORACLE_JUMLAH_VARIAN: Array[int] = [7, 9, 10, 10]
## Checksum 1000 lemparan acak berseed ke rute seed 20261016 (rute 89 rumah) dihitung di commit 41cc11b, sebelum tembok: [lemparan, jumlah zona, tertutup, checksum].
const GOLDEN_LEMPAR: Array[int] = [1000, 11137, 339, 992255826]

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
	_test_hash_varian()
	_test_varian_data_nyata()
	_test_modul_murni()
	_test_sprite_sama_dengan_json()
	_test_geometri_tidak_berubah()
	_test_lemparan_identik()
	_test_sasaran_tidak_tertutup()
	_test_rujukan_dan_pemisahan()
	await _test_scene_tembok()
	await _test_jendela_daur_dan_tekstur()


# --- Varian (AC-5) ---

func _test_hash_varian() -> void:
	_judul.call("VarianTembok: FNV-1a 32 bit atas byte UTF-8, oracle dihitung di Python (AC-5)")
	var cocok_hash: int = 0
	var cocok_varian: int = 0
	var salah: Array[String] = []
	for baris: Array in ORACLE_HASH:
		var id: String = baris[0]
		if VarianTembok.fnv1a_32(id) == int(baris[1]):
			cocok_hash += 1
		else:
			salah.append("%s: %d, harap %d" % [id, VarianTembok.fnv1a_32(id), int(baris[1])])
		if VarianTembok.indeks(id) == int(baris[2]) and VarianTembok.pilih(id) == Config.RUTE_TEMBOK_VARIAN[int(baris[2])]:
			cocok_varian += 1
	check(ORACLE_HASH.size() >= 8 and cocok_hash == ORACLE_HASH.size(), "hash %d id (vektor standar, id nyata, UTF-8 non-ASCII) = oracle Python %s" % [cocok_hash, salah])
	check(cocok_varian == ORACLE_HASH.size(), "indeks dan nama varian (mod 4) = oracle untuk %d id" % cocok_varian)
	check(Config.RUTE_TEMBOK_VARIAN == (["polos", "bata", "besi", "pot"] as Array[String]), "urutan nama varian tetap: polos, bata, besi, pot")
	check(VarianTembok.pilih("per_buka_01@8") == VarianTembok.pilih("per_buka_01@8") and VarianTembok.fnv1a_32("x") == VarianTembok.fnv1a_32("x"), "deterministik: id sama = varian sama, dua kali panggil")
	# Hash buatan sendiri: bukan `String.hash()` dan bukan RNG (sumber murni).
	var sumber: String = FileAccess.get_file_as_string("res://scripts/systems/varian_tembok.gd")
	var kode: String = _tanpa_komentar(sumber)
	check(not kode.contains(".hash(") and not kode.contains("randi") and not kode.contains("randf") and not kode.contains("RandomNumberGenerator"), "varian_tembok.gd tidak memakai hash() atau RNG")
	var beda_dengan_hash: int = 0
	for baris: Array in ORACLE_HASH:
		if (baris[0] as String).hash() != int(baris[1]):
			beda_dengan_hash += 1
	check(beda_dengan_hash >= ORACLE_HASH.size() - 1, "kontrol: String.hash() bukan nilai FNV-1a (hash() tidak boleh dipakai)")


func _test_varian_data_nyata() -> void:
	_judul.call("Varian di sembilan segmen nyata: keempat muncul, sebaran sama dengan oracle Python (AC-5)")
	var kumpulan: PemuatRute.Kumpulan = PemuatRute.muat_folder(FOLDER_RUTE)
	var jumlah: Dictionary = {"polos": 0, "bata": 0, "besi": 0, "pot": 0}
	var rumah_dekat: int = 0
	for segmen: SegmenRute in kumpulan.segmen:
		for r: SegmenRute.Rumah in segmen.rumah:
			if r.sisi == LoperAnim.Sisi.DEKAT:
				rumah_dekat += 1
				jumlah[VarianTembok.pilih("%s@%d" % [segmen.id, r.pos])] += 1
	check(kumpulan.segmen.size() == 9 and rumah_dekat == 36, "sembilan segmen, 36 rumah dekat (dapat %d segmen, %d rumah)" % [kumpulan.segmen.size(), rumah_dekat])
	check(jumlah["polos"] == ORACLE_JUMLAH_VARIAN[0] and jumlah["bata"] == ORACLE_JUMLAH_VARIAN[1] and jumlah["besi"] == ORACLE_JUMLAH_VARIAN[2] and jumlah["pot"] == ORACLE_JUMLAH_VARIAN[3], "sebaran varian polos/bata/besi/pot = 7/9/10/10 (dapat %s)" % [jumlah])
	# Rute utuh: dua jalan dengan seed sama memberi rangkaian varian sama; seed lain tetap memuat keempatnya.
	var urutan_a: Array[String] = _varian_rute(SEED_DEV, kumpulan.segmen)
	var urutan_b: Array[String] = _varian_rute(SEED_DEV, kumpulan.segmen)
	check(urutan_a == urutan_b and urutan_a.size() == 30, "seed rute sama = rangkaian varian sama (30 rumah dekat di rute dev, dapat %d)" % urutan_a.size())
	var semua: Dictionary = {}
	for v: String in urutan_a:
		semua[v] = true
	check(semua.size() == 4, "keempat varian muncul di rute dev (%s)" % [semua.keys()])
	var id_unik: Dictionary = {}
	for benih: int in range(1, 61):
		for r: RouteBuilder.RumahRute in RouteBuilder.bangun(benih, kumpulan.segmen).rute.rumah:
			if r.sisi == LoperAnim.Sisi.DEKAT:
				id_unik[r.id] = VarianTembok.pilih(r.id)
	check(id_unik.size() == 36, "60 rute: 36 id rumah dekat berbeda (satu per rumah di data), varian tergantung id saja (%d)" % id_unik.size())


# --- Modul murni (AC-4) ---

func _test_modul_murni() -> void:
	_judul.call("TembokDekat: modul dan tiang per rumah dekat, oracle literal (AC-4, D-3)")
	var rumah: RouteBuilder.RumahRute = _rumah("per_buka_01", 8, 100.0, LoperAnim.Sisi.DEKAT, "dekat_limasan")
	var daftar: Array[TembokDekat.Potongan] = TembokDekat.potongan(rumah)
	check(TembokDekat.jumlah_modul() == 3 and daftar.size() == 4, "rumah dekat: tiga modul dan satu tiang (dapat %d potongan)" % daftar.size())
	var harapan_maju: Array[float] = [100.0, 101.0, 102.0]
	var varian: String = "besi"
	check(VarianTembok.pilih(rumah.id) == varian, "id per_buka_01@8: varian besi (oracle)")
	var rapi: bool = daftar.size() == 4
	if rapi:
		for i: int in range(3):
			rapi = rapi and not daftar[i].tiang and daftar[i].varian == varian and daftar[i].nama == "house_tembok_besi" and is_equal_approx(daftar[i].maju_ubin, harapan_maju[i]) and is_equal_approx(daftar[i].lateral_ubin, 3.125)
		rapi = rapi and daftar[3].tiang and daftar[3].nama == "house_tembok_tiang" and daftar[3].varian == "" and is_equal_approx(daftar[3].maju_ubin, 100.0) and is_equal_approx(daftar[3].lateral_ubin, 3.125)
	check(rapi, "modul di maju 100, 101, 102 (ujung belakang), lateral 3,125, satu varian untuk ketiganya; tiang di maju 100 (ujung belakang rantai)")
	# Titik dunia (y dunia = -maju): modul berjangkar di ujung depannya (maju + 1), tiang di maju sendiri.
	if rapi:
		check(_sama(TembokDekat.titik_dunia(daftar[0]), Vector2(3.125, -101.0)) and _sama(TembokDekat.titik_dunia(daftar[1]), Vector2(3.125, -102.0)) and _sama(TembokDekat.titik_dunia(daftar[2]), Vector2(3.125, -103.0)) and _sama(TembokDekat.titik_dunia(daftar[3]), Vector2(3.125, -100.0)), "titik pijak dunia: modul (3,125; -101), (3,125; -102), (3,125; -103), tiang (3,125; -100)")
		# Rantai menyambung: tiap potongan berikutnya (maju mengecil) digeser (-32, +16) px di layar dari pendahulunya.
		var layar: Array[Vector2] = []
		for p: TembokDekat.Potongan in [daftar[2], daftar[1], daftar[0], daftar[3]]:
			layar.append(Iso.posisi_gambar(TembokDekat.titik_dunia(p)))
		check(layar[1] - layar[0] == Vector2(-32, 16) and layar[2] - layar[1] == Vector2(-32, 16) and layar[3] - layar[2] == Vector2(-32, 16), "rantai menyambung dari depan ke belakang: tiap modul berikutnya dan tiang bergeser (-32, +16) px (JSON aset: modul berikut digeser (-32, +16))")
	var seberang: RouteBuilder.RumahRute = _rumah("per_buka_01", 6, 40.0, LoperAnim.Sisi.SEBERANG, "pelana")
	check(TembokDekat.potongan(seberang).is_empty() and TembokDekat.potongan(null).is_empty() and TembokDekat.potongan(_rumah("x", 1, 1.0, LoperAnim.Sisi.TIDAK_ADA, "")).is_empty(), "rumah seberang, null, dan sisi kosong tidak punya tembok")
	# Satu varian per RUMAH, bukan per modul: untuk semua id nyata ketiga modul berjenis sama.
	var satu_varian: bool = true
	for baris: Array in ORACLE_HASH:
		var r: RouteBuilder.RumahRute = _rumah("x", 1, 10.0, LoperAnim.Sisi.DEKAT, "dekat_limasan")
		r.id = baris[0]
		var modul: Array[TembokDekat.Potongan] = TembokDekat.potongan(r)
		satu_varian = satu_varian and modul[0].varian == modul[1].varian and modul[1].varian == modul[2].varian and modul[0].varian == Config.RUTE_TEMBOK_VARIAN[int(baris[2])]
	check(satu_varian, "tiap id: ketiga modul satu varian = varian id (oracle)")
	check(TembokDekat.semua_nama() == NAMA_SAH, "semua_nama: empat modul urut varian, lalu tiang (%s)" % [TembokDekat.semua_nama()])
	check(TembokDekat.jalur_png("house_tembok_pot") == "res://assets/sprites/houses/perumahan/house_tembok_pot.png", "jalur PNG tembok di folder rumah perumahan")


func _test_sprite_sama_dengan_json() -> void:
	_judul.call("Sprite tembok: tabel Config = JSON aset = ukuran PNG untuk lima sprite (AC-4, AC-7; pola DefSprite)")
	check(Config.SPRITE_TEMBOK == ([46, 46, 1, 41, 25] as Array[int]) and TembokDekat.sel() == Vector2i(46, 46) and TembokDekat.pijak() == Vector2i(41, 25), "Config.SPRITE_TEMBOK: sel 46x46, 1 frame, pijak (41, 25) (literal)")
	for nama: String in NAMA_SAH:
		var json: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("%s/%s.json" % [FOLDER_RUMAH, nama]))
		var sel: Array = json["cell"]
		var pijak: Array = json["ground_anchor"]
		check(int(sel[0]) == 46 and int(sel[1]) == 46 and int(json["frames"]) == 1 and int(pijak[0]) == 41 and int(pijak[1]) == 25, "%s: JSON sel %s frame %s pijak %s = literal tes" % [nama, sel, json["frames"], pijak])
		check(TembokDekat.sel() == Vector2i(int(sel[0]), int(sel[1])) and TembokDekat.pijak() == Vector2i(int(pijak[0]), int(pijak[1])), "%s: Config = JSON" % nama)
		var tekstur: Texture2D = load(TembokDekat.jalur_png(nama)) as Texture2D
		check(tekstur != null and tekstur.get_width() == 46 and tekstur.get_height() == 46, "%s: PNG %dx%d = sel" % [nama, tekstur.get_width() if tekstur != null else -1, tekstur.get_height() if tekstur != null else -1])
	var geser: Vector2 = Iso.dunia_ke_layar(Vector2(0.0, 1.0))
	check(Vector2(Config.SPRITE_TEMBOK_GESER_PX[0], Config.SPRITE_TEMBOK_GESER_PX[1]) == geser and geser == Vector2(-32, 16) and Config.RUTE_TEMBOK_MODUL_UBIN == 1.0, "geser modul (-32, +16) px = satu ubin mundur menurut Iso, panjang modul 1 ubin")


# --- Geometri tidak berubah (AC-6, D-2) ---

func _test_geometri_tidak_berubah() -> void:
	_judul.call("Geometri logika tidak berubah: tapak rumah, zona, konstanta; hanya gambar rumah dekat bergeser (AC-6, D-2)")
	check(Config.RUTE_TEMBOK_X_UBIN == 3.125 and Config.RUTE_RUMAH_DEKAT_MUNDUR_UBIN == 1.25, "konstanta baru: tembok x 3,125 dan mundur 1,25 (literal)")
	check(Config.RUTE_RUMAH_DEKAT_X_UBIN == 3.0 and Config.RUTE_RUMAH_PANJANG_UBIN == 3.0 and Config.RUTE_RUMAH_DALAM_UBIN == 3.0 and Config.RUTE_RUMAH_TINGGI_UBIN == 2.0, "konstanta lama tidak berubah: kaki fasad dekat 3,0, rumah 3x3x2")
	check(is_equal_approx(Config.RUTE_TEMBOK_X_UBIN - Config.RUTE_RUMAH_DEKAT_X_UBIN, 0.125), "selisih pusat tembok dari kaki fasad = 0,125 ubin (setengah tebal 4 unit)")
	check(PenutupPemain.tapak_rumah(LoperAnim.Sisi.DEKAT, 8.0) == Rect2(3.0, 7.5, 3.0, 3.0), "tapak rumah dekat di maju 8: (3,0; 7,5) 3x3 (tidak ikut mundur)")
	check(PenutupPemain.tapak_rumah(LoperAnim.Sisi.SEBERANG, 8.0) == Rect2(-6.0, 7.5, 3.0, 3.0), "tapak rumah seberang di maju 8: (-6,0; 7,5) 3x3")
	check(PenutupPemain.tapak_rumah(LoperAnim.Sisi.TIDAK_ADA, 8.0) == Rect2(), "sisi kosong: persegi kosong")
	var dekat: RouteBuilder.RumahRute = _rumah("x", 8, 8.0, LoperAnim.Sisi.DEKAT, "dekat_limasan")
	check(PenutupPemain.dari_rumah(dekat).tapak == Rect2(3.0, 7.5, 3.0, 3.0) and PenutupPemain.dari_rumah(dekat).tinggi_ubin == 2.0, "kotak penutup rumah dekat = tapak lama setinggi 2 ubin")
	check(SpriteRumah.pusat_tapak_dunia(dekat) == Vector2(4.5, -9.0) and SpriteRumah.pusat_gambar_dunia(dekat) == Vector2(5.75, -9.0), "pusat gambar rumah dekat = pusat tapak (4,5; -9) + mundur 1,25 = (5,75; -9)")
	var seberang: RouteBuilder.RumahRute = _rumah("x", 8, 8.0, LoperAnim.Sisi.SEBERANG, "limasan")
	check(SpriteRumah.pusat_gambar_dunia(seberang) == SpriteRumah.pusat_tapak_dunia(seberang) and SpriteRumah.pusat_tapak_dunia(seberang) == Vector2(-4.5, -9.0), "rumah seberang: pusat gambar = pusat tapak (-4,5; -9), tidak bergeser")
	var zona: Array[ZonaSasaran.Zona] = ZonaSasaran.zona_rumah(dekat)
	check(zona.size() == 3 and zona[0].persegi == Rect2(1.75, 9.25, 0.75, 1.25) and zona[1].persegi == Rect2(2.0, 7.5, 1.0, 3.0) and zona[2].persegi == Rect2(2.5, 8.25, 0.5, 1.5), "zona rumah dekat di maju 8 tidak berubah: kotak surat, halaman, teras (literal)")
	var rute: RouteBuilder.Rute = RouteBuilder.bangun(SEED_DEV, PemuatRute.muat_folder(FOLDER_RUTE).segmen).rute
	var medan: MedanKoran = MedanKoran.dari_rute(rute)
	check(medan.adalah_rute() and medan.zona_sekitar(Vector2(0.0, -40.0)).size() == ZonaSasaran.zona_rute(rute.rumah.slice(JendelaRute.rentang(rute.rumah, 40.0 - 4.0, 40.0 + 4.0).x, JendelaRute.rentang(rute.rumah, 40.0 - 4.0, 40.0 + 4.0).y)).size(), "MedanKoran: zona di sekitar titik = zona rumah rute saja (tidak ada zona tembok)")


func _test_lemparan_identik() -> void:
	_judul.call("1000 lemparan acak berseed ke rute nyata: penilaian dan penutup identik dengan sebelum run (AC-6)")
	var pustaka: Array[SegmenRute] = PemuatRute.muat_folder(FOLDER_RUTE).segmen
	var rute: RouteBuilder.Rute = RouteBuilder.bangun(SEED_DEV, pustaka).rute
	var medan: MedanKoran = MedanKoran.dari_rute(rute)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7311
	var jumlah_zona: int = 0
	var tertutup: int = 0
	var checksum: int = 0
	var lempar: int = 0
	var cocok_ulang: int = 0
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
		lempar += 1
		# Penilaian ulang dari ZonaSasaran saja (daftar zona seluruh rute, bukan jendela medan).
		var semua: Array[ZonaSasaran.Zona] = ZonaSasaran.zona_rute_rentang(rute.rumah, -titik.y - 2.0, -titik.y + 2.0)
		if int(ZonaSasaran.klasifikasi(titik, semua)) == hasil:
			cocok_ulang += 1
	check(lempar == GOLDEN_LEMPAR[0] and jumlah_zona == GOLDEN_LEMPAR[1] and tertutup == GOLDEN_LEMPAR[2] and checksum == GOLDEN_LEMPAR[3], "lemparan %d, zona %d, tertutup %d, checksum %d = nilai sebelum run %s" % [lempar, jumlah_zona, tertutup, checksum, GOLDEN_LEMPAR])
	check(cocok_ulang == 1000, "penilaian MedanKoran = penilaian ulang dari ZonaSasaran untuk 1000 lemparan (%d sama)" % cocok_ulang)


# --- Sasaran tidak tertutup (AC-8) ---

func _test_sasaran_tidak_tertutup() -> void:
	_judul.call("Sasaran sisi dekat vs tembok: pecahan piksel opak yang menimpa (rute buatan, 4 varian x 3 jenis rumah x posisi kavling; AC-8)")
	var jenis: Array[String] = ["dekat_limasan", "dekat_pelana_lintang", "dekat_pelana_sejajar"]
	var posisi: Array[float] = [8.0, 9.0, 12.0, 12.5, 40.25]
	var maks_badan: float = 0.0
	var maks_badan_geom: float = 0.0
	var badan_kosong: int = 0
	# Per varian: [terkecil, terbesar] pecahan zona kotak surat dan teras di semua jenis rumah dan posisi.
	var batas: Dictionary = {}
	for varian: String in Config.RUTE_TEMBOK_VARIAN:
		batas[varian] = {"zona_kotak": [INF, -INF], "zona_teras": [INF, -INF]}
	var jumlah_ukur: int = 0
	for j: String in jenis:
		for varian: String in Config.RUTE_TEMBOK_VARIAN:
			for m: float in posisi:
				var h: Dictionary = UkurTembok.ukur(m, j, varian)
				jumlah_ukur += 1
				maks_badan = maxf(maks_badan, float(h["kotak_badan"]))
				maks_badan_geom = maxf(maks_badan_geom, float(h["kotak_badan_geom"]))
				if int(h["jumlah_badan"]) > 40:
					badan_kosong += 1
				for kunci: String in ["zona_kotak", "zona_teras"]:
					var rentang: Array = batas[varian][kunci]
					rentang[0] = minf(rentang[0], float(h[kunci]))
					rentang[1] = maxf(rentang[1], float(h[kunci]))
	check(jumlah_ukur == 60 and badan_kosong == 60, "60 pengukuran (4 varian x 3 jenis x 5 posisi), badan kotak surat punya > 40 piksel opak di tiap pengukuran")
	check(maks_badan == 0.0 and maks_badan_geom == 0.0, "badan kotak surat sasaran dekat: 0%% tertimpa tembok dan tiang untuk semua varian, jenis, posisi (terburuk %.4f, tanpa urutan gambar %.4f)" % [maks_badan, maks_badan_geom])
	# Zona di tanah: BLOCKED (AC-8 menuntut 0%). Nilai terukur dicatat; tidak identik antar posisi (kisi piksel sama untuk kelipatan 1 ubin).
	var hasil_kotak: Array[int] = []
	var hasil_teras: Array[int] = []
	for varian: String in Config.RUTE_TEMBOK_VARIAN:
		hasil_kotak.append(roundi(float(batas[varian]["zona_kotak"][1]) * 1000.0))
		hasil_teras.append(roundi(float(batas[varian]["zona_teras"][1]) * 1000.0))
	# [polos, bata, besi, pot]: nilai terukur 2026-10-21 (LOG B1, temuan BLOCKED); berubah = geometri tembok atau aset berubah.
	check(hasil_kotak == ([17, 17, 17, 131] as Array[int]), "BLOCKED AC-8 (terukur, bukan 0%%): zona kotak surat dekat tertimpa polos/bata/besi/pot = 1,7/1,7/1,7/13,1%% (per mil, dapat %s)" % [hasil_kotak])
	check(hasil_teras == ([895, 895, 823, 975] as Array[int]), "BLOCKED AC-8 (terukur, bukan 0%%): zona teras dekat tertimpa polos/bata/besi/pot = 89,5/89,5/82,3/97,5%% (per mil, dapat %s)" % [hasil_teras])
	var sama_di_posisi: bool = true
	for varian: String in Config.RUTE_TEMBOK_VARIAN:
		sama_di_posisi = sama_di_posisi and (batas[varian]["zona_kotak"][0] as float) == (batas[varian]["zona_kotak"][1] as float) and (batas[varian]["zona_teras"][0] as float) == (batas[varian]["zona_teras"][1] as float)
	check(sama_di_posisi, "pecahan zona sama di semua jenis rumah dan posisi kavling (tembok tidak bergantung jenis atap atau posisi)")


# --- Rujukan dan pemisahan (AC-7, AC-18) ---

func _test_rujukan_dan_pemisahan() -> void:
	_judul.call("Rujukan nama tembok hanya lima sprite sah; tembok tidak menyentuh tabrakan, rintangan, penutup, medan, zona (AC-7, AC-18)")
	var berkas: Array[String] = []
	for akar: String in ["res://scripts", "res://scenes", "res://assets/data", "res://translations"]:
		_kumpulkan(akar, berkas)
	var tes: DirAccess = DirAccess.open("res://tests")
	for nama: String in tes.get_files():
		if nama.ends_with(".gd") and not nama.begins_with("probe_"):
			berkas.append("res://tests/" + nama)
	var regex: RegEx = RegEx.create_from_string("house_tembok_[a-z_0-9]+")
	var asing: Array[String] = []
	var total: int = 0
	for jalur: String in berkas:
		for cocok: RegExMatch in regex.search_all(FileAccess.get_file_as_string(jalur)):
			total += 1
			if not NAMA_SAH.has(cocok.get_string()):
				asing.append("%s: %s" % [jalur, cocok.get_string()])
	check(total > 10, "pemindai menemukan rujukan nama tembok (%d)" % total)
	check(asing.is_empty(), "tidak ada rujukan house_tembok_* di luar lima nama sah: %s" % [asing])
	var folder: Array[String] = []
	for nama: String in DirAccess.get_files_at(FOLDER_RUMAH):
		if nama.begins_with("house_tembok_") and nama.ends_with(".png"):
			folder.append(nama.get_basename())
	folder.sort()
	var harapan: Array[String] = NAMA_SAH.duplicate()
	harapan.sort()
	check(folder == harapan, "folder houses/perumahan memuat tepat lima PNG tembok: %s" % [folder])
	# Tembok hanya dirujuk satu entitas gambar; tidak ada di logika tabrakan, rintangan, penutup, medan, zona, skor.
	var bersih: Array[String] = []
	for jalur: String in ["scripts/systems/tabrakan.gd", "scripts/systems/rintangan_rute.gd", "scripts/systems/penutup_pemain.gd", "scripts/systems/medan_koran.gd", "scripts/systems/zona_sasaran.gd", "scripts/systems/skor_rute.gd", "scripts/systems/throw_solver.gd", "scripts/systems/bike_motion.gd", "scripts/systems/tenggat_rute.gd", "scripts/entities/penerap_penutup.gd", "scripts/entities/rintangan_daur.gd"]:
		var teks: String = FileAccess.get_file_as_string("res://" + jalur).to_lower()
		if teks.contains("tembok") or teks.contains("rumah_dekat_mundur"):
			bersih.append(jalur)
	check(bersih.is_empty(), "logika tabrakan, rintangan, penutup, medan, zona, skor, lempar, gerak, tenggat tidak merujuk tembok: %s" % [bersih])
	var pengguna: Array[String] = []
	for jalur: String in berkas:
		if jalur.begins_with("res://scripts") and jalur.ends_with(".gd") and FileAccess.get_file_as_string(jalur).contains("TembokDekat.") and not jalur.ends_with("tembok_dekat.gd"):
			pengguna.append(jalur)
	check(pengguna == (["res://scripts/entities/rumah_daur_rute.gd"] as Array[String]), "satu-satunya pengguna TembokDekat di scripts adalah RumahDaurRute: %s" % [pengguna])


# --- Scene (AC-6, AC-7) ---

func _test_scene_tembok() -> void:
	_judul.call("Scene rute: tembok per rumah dekat, letak piksel, Y-sort, bukan penutup, rumah dekat digeser, seberang tetap (AC-6, AC-7)")
	var akar: RuteMain = await _siapkan()
	var rute: RouteBuilder.Rute = RouteBuilder.bangun(SEED_DEV, PemuatRute.muat_folder(FOLDER_RUTE).segmen).rute
	var objek: Node2D = akar.find_child("Objek", true, false) as Node2D
	var daur: RumahDaurRute = akar.daur()
	var salah: Array[String] = []
	var jumlah_dekat: int = 0
	var jumlah_seberang: int = 0
	var jarak_uji: Array[float] = [0.0, 60.0, 130.0, 200.0, 236.0]
	for jarak: float in jarak_uji:
		_taruh_sepeda(akar, jarak)
		var dekat_di_jendela: int = 0
		for i: int in daur.indeks_tampil():
			var r: RouteBuilder.RumahRute = rute.rumah[i]
			var tembok: Array[Sprite2D] = daur.sprite_tembok(i)
			var rumah_sprite: Sprite2D = daur.sprite_rumah(i)
			if r.sisi == LoperAnim.Sisi.SEBERANG:
				jumlah_seberang += 1
				if not tembok.is_empty():
					salah.append("%s: rumah seberang bertembok" % r.id)
				if rumah_sprite.position != _layar(-4.5, r.maju_ubin + 1.0):
					salah.append("%s: rumah seberang bergeser %s" % [r.id, rumah_sprite.position])
				continue
			jumlah_dekat += 1
			dekat_di_jendela += 1
			if tembok.size() != 4:
				salah.append("%s: %d sprite tembok" % [r.id, tembok.size()])
				continue
			var varian: String = _varian_oracle(r.id)
			for k: int in range(4):
				var s: Sprite2D = tembok[k]
				var nama: String = "house_tembok_tiang" if k == 3 else "house_tembok_" + varian
				# Letak: modul k berjangkar di maju + k + 1 (ujung depan), tiang di maju; lateral 3,125; ditulis ulang dari proyeksi iso.
				var maju_jangkar: float = r.maju_ubin if k == 3 else r.maju_ubin + float(k) + 1.0
				if s.texture == null or s.texture.resource_path != "%s/%s.png" % [FOLDER_RUMAH, nama]:
					salah.append("%s[%d]: tekstur %s, harap %s" % [r.id, k, s.texture.resource_path if s.texture != null else "null", nama])
				if s.position != _layar(3.125, maju_jangkar) or s.offset != Vector2(-41, -25) or s.centered or not s.visible:
					salah.append("%s[%d]: posisi %s offset %s, harap %s" % [r.id, k, s.position, s.offset, _layar(3.125, maju_jangkar)])
				if s.get_parent() != objek or s.z_index != 0 or s.modulate.a != 1.0 or s.y_sort_enabled:
					salah.append("%s[%d]: bukan anak Objek biasa (z_index %d, alfa %.2f)" % [r.id, k, s.z_index, s.modulate.a])
				# Y-sort: tembok digambar sebelum rumah di belakangnya (posisi tegak lebih kecil), rumah menimpa tembok.
				if not (s.position.y < rumah_sprite.position.y):
					salah.append("%s[%d]: urutan Y tembok %.0f tidak di bawah rumah %.0f" % [r.id, k, s.position.y, rumah_sprite.position.y])
			# Rumah dekat: tergambar di letak lama + (40, +20) px (1,25 ubin menjauh), tanpa kotak surat.
			var lama: Vector2 = _layar(4.5, r.maju_ubin + 1.0)
			if rumah_sprite.position != lama + Vector2(40, 20) or rumah_sprite.position != _layar(5.75, r.maju_ubin + 1.0):
				salah.append("%s: rumah dekat di %s, harap letak lama %s + (40, 20)" % [r.id, rumah_sprite.position, lama])
			if daur.kotak_surat(i) != null or daur.kotak_surat_bukan(i) != null or r.pelanggan:
				salah.append("%s: rumah dekat punya kotak surat atau pelanggan" % r.id)
		check(daur.jumlah_tembok() == 4 * dekat_di_jendela, "jarak %.0f: %d sprite tembok = 4 x %d rumah dekat di jendela" % [jarak, daur.jumlah_tembok(), dekat_di_jendela])
	check(jumlah_dekat >= 20 and jumlah_seberang >= 20, "kontrol: tes menyentuh banyak rumah dekat (%d) dan seberang (%d)" % [jumlah_dekat, jumlah_seberang])
	check(salah.is_empty(), "tembok: tekstur, letak piksel, bukan penutup, Y-sort di bawah rumah, rumah dekat digeser (40, 20), seberang tetap: %s" % [salah.slice(0, 4)])
	# Bukan penutup: tidak terdaftar ke penerap (jumlah = rumah + rintangan), alfa tembok 1,0 di semua titik penyapuan pemain.
	var penerap: PenerapPenutup = akar.penerap_penutup()
	var alfa_salah: Array[String] = []
	for jarak: float in [20.0, 80.0, 150.0, 220.0]:
		for lateral: float in [-2.0, 0.0, 1.0, 2.0]:
			_taruh_sepeda(akar, jarak, lateral)
			if penerap.jumlah() != daur.jumlah_rumah() + akar.rintangan_daur().jumlah_tampil():
				alfa_salah.append("jarak %.0f: penerap %d, rumah %d" % [jarak, penerap.jumlah(), daur.jumlah_rumah()])
			for i: int in daur.indeks_tampil():
				for s: Sprite2D in daur.sprite_tembok(i):
					if s.modulate.a != 1.0:
						alfa_salah.append("%d lateral %.0f: alfa tembok %.2f" % [i, lateral, s.modulate.a])
	check(alfa_salah.is_empty(), "tembok tidak didaftarkan ke PenerapPenutup (jumlah terdaftar = rumah + rintangan) dan alfanya selalu 1,0: %s" % [alfa_salah.slice(0, 3)])
	# Tapak logika rumah dekat tidak ikut bergeser: pemain di lateral 2,0 tidak pernah menutupi; kotak penutup literal.
	var kotak: PenutupPemain.Objek = PenutupPemain.dari_rumah(rute.rumah[_indeks_dekat_pertama(rute)])
	check(kotak.tapak.position.x == 3.0 and kotak.tapak.size == Vector2(3.0, 3.0), "kotak penutup rumah dekat di rute nyata tetap di lateral 3,0 (x %.2f)" % kotak.tapak.position.x)
	_bersihkan(akar)


func _test_jendela_daur_dan_tekstur() -> void:
	_judul.call("Jendela daur tembok: node tidak tumbuh saat rute digulir, tekstur dimuat sekali, kolam dipakai ulang (AC-7)")
	var akar: RuteMain = await _siapkan()
	var rute: RouteBuilder.Rute = RouteBuilder.bangun(SEED_DEV, PemuatRute.muat_folder(FOLDER_RUTE).segmen).rute
	var daur: RumahDaurRute = akar.daur()
	# Tekstur: satu per nama sprite yang dipakai rute (varian terpakai + tiang), dimuat di atur_rute sebelum rumah pertama muncul.
	var nama_pakai: Dictionary = {"house_tembok_tiang": true}
	for r: RouteBuilder.RumahRute in rute.rumah:
		if r.sisi == LoperAnim.Sisi.DEKAT:
			nama_pakai["house_tembok_" + _varian_oracle(r.id)] = true
	check(daur.jumlah_tekstur_tembok() == nama_pakai.size() and nama_pakai.size() == 5, "tekstur tembok dimuat di atur_rute: %d nama (empat varian + tiang) sebelum digulir" % daur.jumlah_tekstur_tembok())
	var puncak: int = 0
	var puncak_oracle: int = 0
	var node_naik: int = 0
	var sebelumnya: int = daur.jumlah_node_tembok()
	var tembok_salah: Array[String] = []
	for jarak: int in range(0, 237):
		_taruh_sepeda(akar, float(jarak))
		var dekat: int = 0
		for r: RouteBuilder.RumahRute in rute.rumah:
			if r.sisi == LoperAnim.Sisi.DEKAT and r.maju_ubin >= float(jarak) - DAUR_MUNDUR and r.maju_ubin <= float(jarak) + DAUR_MAJU:
				dekat += 1
		puncak_oracle = maxi(puncak_oracle, dekat)
		puncak = maxi(puncak, daur.jumlah_tembok())
		if daur.jumlah_tembok() != 4 * dekat:
			tembok_salah.append("jarak %d: %d sprite, harap %d" % [jarak, daur.jumlah_tembok(), 4 * dekat])
		if daur.jumlah_node_tembok() > sebelumnya:
			node_naik += 1
			sebelumnya = daur.jumlah_node_tembok()
	check(tembok_salah.is_empty(), "237 titik gulir: sprite tembok = 4 x rumah dekat di jendela daur (sapuan linear): %s" % [tembok_salah.slice(0, 3)])
	check(puncak == 4 * puncak_oracle and puncak_oracle >= 5 and puncak_oracle < 30, "puncak sprite tembok %d = 4 x puncak rumah dekat %d (< 30 rumah dekat seluruh rute)" % [puncak, puncak_oracle])
	check(daur.jumlah_node_tembok() == puncak, "node tembok yang pernah dibuat (%d) = puncak pemakaian (%d): kolam dipakai ulang, tidak ada node di luar jendela" % [daur.jumlah_node_tembok(), puncak])
	check(daur.jumlah_muat_tembok() == 5, "PNG tembok dimuat dari disk tepat lima kali (satu per nama) selama seluruh gulir: %d" % daur.jumlah_muat_tembok())
	check(node_naik >= 1 and daur.jumlah_tekstur_tembok() == 5, "tekstur tetap lima sesudah digulir seluruh rute (%d), node tumbuh hanya sampai puncak" % daur.jumlah_tekstur_tembok())
	# Anak Objek bertembok: node di luar jendela tidak hidup; sesudah digulir ke ujung, hanya yang terpakai terlihat.
	var terlihat: int = 0
	var objek: Node2D = akar.find_child("Objek", true, false) as Node2D
	for anak: Node in objek.get_children():
		if anak is Sprite2D and (anak as Sprite2D).visible and String(anak.name).begins_with("Tembok"):
			terlihat += 1
	check(terlihat == daur.jumlah_tembok(), "node Tembok* terlihat di Objek (%d) = sprite tembok terpakai (%d)" % [terlihat, daur.jumlah_tembok()])
	# Ganti rute (Main lagi): semua kembali ke kolam lalu dipasang ulang, jumlah node tetap.
	var sebelum_node: int = daur.jumlah_node_tembok()
	daur.atur_rute(RouteBuilder.bangun(SEED_DEV + 1, PemuatRute.muat_folder(FOLDER_RUTE).segmen).rute)
	check(daur.jumlah_node_tembok() >= sebelum_node and daur.jumlah_node_tembok() <= sebelum_node + 4 * 6, "ganti rute: sprite dikembalikan ke kolam dan dipakai ulang (%d -> %d node)" % [sebelum_node, daur.jumlah_node_tembok()])
	_bersihkan(akar)


# --- Pembantu ---

func _rumah(id_segmen: String, pos: int, maju: float, sisi: LoperAnim.Sisi, jenis: String) -> RouteBuilder.RumahRute:
	var r: RouteBuilder.RumahRute = RouteBuilder.RumahRute.new()
	r.id_segmen = id_segmen
	r.pos = pos
	r.id = "%s@%d" % [id_segmen, pos]
	r.maju_ubin = maju
	r.sisi = sisi
	r.jenis = jenis
	return r


func _sama(a: Vector2, b: Vector2) -> bool:
	return absf(a.x - b.x) < 0.000001 and absf(a.y - b.y) < 0.000001


## Posisi gambar (piksel game) titik dunia (lateral, maju) di tanah: proyeksi iso 2:1 ditulis ulang, dibulatkan.
func _layar(lateral: float, maju: float) -> Vector2:
	return Vector2(roundf((lateral + maju) * 32.0), roundf((lateral - maju) * 16.0))


## Varian dari tabel Python (id -> indeks) untuk id rute nyata: dihitung ulang tes dengan FNV-1a yang ditulis lagi di sini (oracle independen dari `VarianTembok`).
func _varian_oracle(id: String) -> String:
	var nilai: int = 2166136261
	for b: int in id.to_utf8_buffer():
		nilai = nilai ^ b
		nilai = (nilai * 16777619) & 4294967295
	return ["polos", "bata", "besi", "pot"][nilai % 4]


func _varian_rute(benih: int, pustaka: Array[SegmenRute]) -> Array[String]:
	var hasil: Array[String] = []
	for r: RouteBuilder.RumahRute in RouteBuilder.bangun(benih, pustaka).rute.rumah:
		if r.sisi == LoperAnim.Sisi.DEKAT:
			hasil.append(VarianTembok.pilih(r.id))
	return hasil


func _indeks_dekat_pertama(rute: RouteBuilder.Rute) -> int:
	for i: int in range(rute.rumah.size()):
		if rute.rumah[i].sisi == LoperAnim.Sisi.DEKAT:
			return i
	return 0


func _jumlah_huruf(teks: String) -> int:
	var j: int = 0
	for i: int in range(teks.length()):
		j += teks.unicode_at(i) * (i + 1)
	return j % 1000


func _tanpa_komentar(sumber: String) -> String:
	var hasil: Array[String] = []
	for baris: String in sumber.split("\n"):
		var potong: int = baris.find("#")
		hasil.append(baris if potong < 0 else baris.substr(0, potong))
	return "\n".join(hasil)


func _kumpulkan(folder: String, hasil: Array[String]) -> void:
	for berkas: String in DirAccess.get_files_at(folder):
		if berkas.ends_with(".gd") or berkas.ends_with(".tscn") or berkas.ends_with(".json") or berkas.ends_with(".csv"):
			hasil.append("%s/%s" % [folder, berkas])
	for sub: String in DirAccess.get_directories_at(folder):
		_kumpulkan("%s/%s" % [folder, sub], hasil)


func _siapkan() -> RuteMain:
	_tree.root.size = Vector2i(2340, 1080)
	var akar: RuteMain = (load(BERKAS_RUTE) as PackedScene).instantiate() as RuteMain
	_tree.root.add_child(akar)
	await _tree.process_frame
	await _tree.process_frame
	akar.set_process(false)
	(akar.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = false
	var sprite: LoperSprite = akar.find_child("LoperAgen", true, false) as LoperSprite
	sprite.set_process(false)
	return akar


func _bersihkan(akar: RuteMain) -> void:
	(akar.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = OS.has_feature("editor")
	_tree.root.remove_child(akar)
	akar.free()


func _taruh_sepeda(akar: RuteMain, maju: float, lateral: float = 0.0) -> void:
	var sepeda: SepedaUji = akar.find_child("Sepeda", true, false) as SepedaUji
	var k: BikeMotion.Keadaan = sepeda.keadaan.salin()
	k.kecepatan_ud = 3.0
	k.lateral_ubin = lateral
	sepeda.keadaan = k
	sepeda.jarak_ubin = maju
	akar.perbarui(0.0)
