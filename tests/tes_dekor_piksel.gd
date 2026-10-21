class_name TesDekorPiksel
extends RefCounted
## Tes run fase5b-tembok-dekor iterasi 2 (QA-001, putusan P-6): tinggi dan tapak kotak penutup dekor sisi dekat = sprite nyata, dibuktikan dengan PIKSEL, bukan dengan model kotak.
##
## Oracle independen (`UkurPenutupPiksel`): piksel opak dihitung dari PNG nyata dengan matematika proyeksi isometrik 2:1 yang ditulis sendiri; satu-satunya fungsi produksi yang diuji untuk
## keputusan "menutupi" adalah `PenutupPemain.menutupi` atas `PenutupPemain.dari_dekor` (kotak penutup). Dua kasus:
## - pemain tidak pernah hilang: tidak ada posisi (lateral -2,0 sampai 2,0, maju sekitar dekor) di mana piksel opak dekor sisi dekat ada di atas piksel pemain pada alfa 1,0 kecuali kotak
##   penutupnya menutupi pemain (alfa objek jadi `RUTE_PENUTUP_ALFA`, pemain tetap terlihat);
## - rintangan di jalur selalu terlihat (ROUTE_DESIGN aturan 5): tidak ada piksel opak dekor di atas piksel anjing atau mobil garasi di posisi mana pun yang bisa dicapainya.
## Kontrol: model lama (tinggi pohon 1,25, lampu 1,0, tapak kaki) memang meninggalkan piksel tertutup, jadi sapuan mampu mendeteksi.

const FOLDER_RUTE: String = "res://assets/data/routes/perumahan"
const SEED_DEV: int = 20261016
## Sprite sisi dekat yang menutupi: [jenis, varian, tinggi piksel opak di atas pijak (dihitung dari PNG dengan skrip lain), tinggi ubin literal, setengah tapak penutup literal].
const DEKAT_ORACLE: Array = [
	["pohon", "rindang", 44, 1.375, 0.875], ["pohon", "glodokan", 63, 1.96875, 0.625], ["pohon", "ketapang", 53, 1.65625, 0.75], ["lampu_jalan", "lengan", 64, 2.0, 0.75],
]

## Sprite sisi seberang (tidak menutupi): [jenis, varian].
const SEBERANG_ORACLE: Array = [["pohon", "rindang"], ["pohon", "glodokan"], ["pohon", "ketapang"], ["lampu_jalan", "lengan"], ["tong_sampah", "logam"]]

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
	_test_tabel_penutup()
	_test_pemain_tidak_hilang_sprite()
	_test_pemain_tidak_hilang_data_nyata()
	_test_model_lama_gagal()
	_test_tong_dekat_batas_diketahui()
	_test_seberang_tidak_menutupi()
	_test_rintangan_terlihat()
	_test_rintangan_kontrol()


# --- Tabel ---

func _test_tabel_penutup() -> void:
	_judul.call("Kotak penutup dekor: tinggi = piksel opak sprite di atas pijak / 32, tapak penutup literal, hanya sisi dekat menutupi (P-6)")
	check(Config.RUTE_DEKOR_TINGGI_PENUTUP_UBIN == ([0.0, 1.375, 1.96875, 1.65625, 1.8125, 2.0] as Array[float]), "tinggi penutup per sprite (tong, rindang, glodokan, ketapang, lampu seberang, lampu dekat) = literal")
	check(Config.RUTE_DEKOR_SETENGAH_PENUTUP_UBIN == ([0.0, 0.875, 0.625, 0.75, 0.75, 0.75] as Array[float]), "setengah tapak penutup per sprite = literal")
	# Tinggi dari PNG: baris opak paling atas, dihitung di sini dengan cara sendiri.
	var nama: Array[String] = ["prop_tong_sampah_logam", "prop_pohon_rindang", "prop_pohon_glodokan", "prop_pohon_ketapang", "prop_lampu_lengan_seberang", "prop_lampu_lengan_dekat"]
	var salah: Array[String] = []
	for i: int in range(nama.size()):
		var t: UkurPenutupPiksel.Topeng = UkurPenutupPiksel.topeng_prop(nama[i])
		var tinggi_px: int = -t.batas.position.y
		var tinggi_ubin: float = float(tinggi_px) / 32.0
		if i == 0:
			if Config.RUTE_DEKOR_TINGGI_PENUTUP_UBIN[i] != 0.0:
				salah.append("tong tidak menutupi")
		elif tinggi_ubin != Config.RUTE_DEKOR_TINGGI_PENUTUP_UBIN[i]:
			salah.append("%s: piksel %d / 32 = %s, tabel %s" % [nama[i], tinggi_px, tinggi_ubin, Config.RUTE_DEKOR_TINGGI_PENUTUP_UBIN[i]])
	check(salah.is_empty(), "tinggi penutup tiap sprite = (baris opak teratas di atas pijak dari PNG) / 32: %s" % [salah])
	for baris: Array in DEKAT_ORACLE:
		var t: UkurPenutupPiksel.Topeng = UkurPenutupPiksel.topeng_prop("prop_pohon_" + str(baris[1]) if baris[0] == "pohon" else "prop_lampu_lengan_dekat")
		check(-t.batas.position.y == int(baris[2]) and float(baris[2]) / 32.0 == float(baris[3]), "%s: tinggi piksel opak %d = %s ubin (literal)" % [baris[1], int(baris[2]), baris[3]])
	# Hanya sisi dekat, hanya pohon dan lampu.
	for baris: Array in DEKAT_ORACLE:
		var jenis: String = baris[0]
		var varian: String = baris[1]
		check(DekorRute.tinggi_penutup(jenis, varian, LoperAnim.Sisi.DEKAT) == float(baris[3]) and DekorRute.setengah_penutup(jenis, varian, LoperAnim.Sisi.DEKAT) == float(baris[4]), "%s %s sisi dekat: tinggi %s, setengah tapak %s" % [jenis, varian, baris[3], baris[4]])
		check(DekorRute.tinggi_penutup(jenis, varian, LoperAnim.Sisi.SEBERANG) == 0.0 and not DekorRute.menutupi(jenis, varian, LoperAnim.Sisi.SEBERANG) and DekorRute.menutupi(jenis, varian, LoperAnim.Sisi.DEKAT), "%s %s: sisi seberang tidak pernah menutupi, sisi dekat menutupi" % [jenis, varian])
	check(DekorRute.tinggi_penutup("tong_sampah", "logam", LoperAnim.Sisi.DEKAT) == 0.0 and not DekorRute.menutupi("tong_sampah", "logam", LoperAnim.Sisi.DEKAT) and not DekorRute.menutupi("tong_sampah", "logam", LoperAnim.Sisi.SEBERANG), "tong sampah tidak menutupi di sisi mana pun")
	check(DekorRute.tinggi_penutup("kursi", "x", LoperAnim.Sisi.DEKAT) == 0.0 and DekorRute.tinggi_penutup("pohon", "beringin", LoperAnim.Sisi.DEKAT) == 0.0 and DekorRute.tinggi_penutup("pohon", "rindang", LoperAnim.Sisi.TIDAK_ADA) == 0.0, "jenis, varian, atau sisi tidak dikenal: tinggi 0")
	check(DekorRute.tapak_penutup("pohon", "rindang", LoperAnim.Sisi.DEKAT, 13.0) == Rect2(1.625, 12.125, 1.75, 1.75), "tapak penutup pohon rindang dekat maju 13: pusat (2,5; 13), setengah 0,875 -> (1,625; 12,125) 1,75 x 1,75")
	check(DekorRute.tapak_penutup("lampu_jalan", "lengan", LoperAnim.Sisi.DEKAT, 21.0) == Rect2(1.5, 20.25, 1.5, 1.5), "tapak penutup lampu dekat maju 21: pusat (2,25; 21), setengah 0,75 -> (1,5; 20,25) 1,5 x 1,5")
	check(DekorRute.tapak_penutup("pohon", "rindang", LoperAnim.Sisi.SEBERANG, 13.0) == Rect2() and DekorRute.tapak_penutup("tong_sampah", "logam", LoperAnim.Sisi.DEKAT, 13.0) == Rect2(), "seberang dan tong: tapak penutup kosong")
	# Tapak kaki (validasi tempat) tidak berubah oleh kotak penutup.
	check(DekorRute.tapak("pohon", LoperAnim.Sisi.DEKAT, 13.0) == Rect2(2.25, 12.75, 0.5, 0.5), "tapak kaki pohon dekat (validasi tempat) tetap 0,5 x 0,5")


# --- Pemain tidak pernah hilang ---

## Sapuan per sprite sisi dekat (letak dekor di maju 20): lateral -2,0 sampai 2,0 langkah 0,125 dan maju 4 ubin di kedua sisi dekor langkah 1/32. Posisi relatif sama untuk dekor di maju bulat mana
## pun (bergeser kelipatan satu ubin = (32, -16) piksel, bilangan bulat), jadi satu sapuan per sprite berlaku untuk setiap dekor sisi dekat di rute.
func _test_pemain_tidak_hilang_sprite() -> void:
	_judul.call("Pemain tidak pernah di bawah piksel opak dekor sisi dekat tanpa kotak penutup menutupinya: pohon rindang, glodokan, ketapang, lampu (lateral -2,0 sampai 2,0, P-6)")
	for baris: Array in DEKAT_ORACLE:
		var d: RouteBuilder.DekorItem = UkurPenutupPiksel.dekor_buatan(baris[0], baris[1], LoperAnim.Sisi.DEKAT, 20.0)
		var h: Dictionary = UkurPenutupPiksel.sapu_pemain(d, 0.125, 1.0 / 32.0, 4.0)
		var tak: Array = h["tak_tertutup"]
		check(int(h["diperiksa"]) > 8000 and int(h["tumpang"]) > 150 and int(h["tertutup_tumpang"]) > 100, "%s: kontrol sapuan %d posisi, %d tumpang piksel, %d di antaranya tertutup kotak (oracle mampu mendeteksi)" % [baris[1], int(h["diperiksa"]), int(h["tumpang"]), int(h["tertutup_tumpang"])])
		var contoh: Array = tak.slice(0, 3)
		check(tak.is_empty(), "%s: 0 posisi dengan piksel opak dekor di atas pemain tanpa kotak menutupi (dapat %d, terburuk %d piksel, contoh %s)" % [baris[1], tak.size(), int(h["piksel_maks"]), contoh])


## Sembilan segmen: tiap dekor (pohon, lampu, tong; kedua sisi) pada letak nyata (sapuan lebih kasar), dan setiap kombinasi jenis/varian/sisi di 60 rute tercakup sapuan per sprite.
func _test_pemain_tidak_hilang_data_nyata() -> void:
	_judul.call("Pemain tidak pernah hilang di sembilan segmen dan 60 rute nyata: tiap dekor pada letak sebenarnya, kedua sisi (P-6)")
	var pustaka: Array[SegmenRute] = PemuatRute.muat_folder(FOLDER_RUTE).segmen
	var diperiksa: int = 0
	var jumlah_dekor: int = 0
	var dekat: int = 0
	var buruk: Array[String] = []
	for segmen: SegmenRute in pustaka:
		for butir: SegmenRute.Dekor in segmen.dekor:
			jumlah_dekor += 1
			if butir.jenis == "tong_sampah" and butir.sisi == LoperAnim.Sisi.DEKAT:
				continue
			if butir.sisi == LoperAnim.Sisi.DEKAT:
				dekat += 1
			var d: RouteBuilder.DekorItem = UkurPenutupPiksel.dekor_buatan(butir.jenis, butir.varian, butir.sisi, float(butir.pos))
			var h: Dictionary = UkurPenutupPiksel.sapu_pemain(d, 0.25, 1.0 / 8.0, 4.0)
			diperiksa += int(h["diperiksa"])
			if not (h["tak_tertutup"] as Array).is_empty():
				buruk.append("%s %s@%d: %d" % [segmen.id, butir.jenis, butir.pos, (h["tak_tertutup"] as Array).size()])
	check(jumlah_dekor == 38 and dekat >= 8 and diperiksa > 10000 and buruk.is_empty(), "%d dekor di sembilan segmen (%d pohon/lampu sisi dekat; tong sampah dekat lihat batas yang diketahui), %d posisi pemain: 0 tertimpa opak tanpa kotak penutup: %s" % [jumlah_dekor, dekat, diperiksa, buruk.slice(0, 3)])
	# 60 rute: tiap kombinasi (jenis, varian, sisi) yang muncul ada di sapuan per sprite; rute hanya menggeser dekor kelipatan satu ubin (bilangan bulat, jadi posisi relatif tetap).
	var dikenal: Dictionary = {}
	for baris: Array in DEKAT_ORACLE:
		dikenal["%s/%s/%d" % [baris[0], baris[1], LoperAnim.Sisi.DEKAT]] = true
	for baris: Array in SEBERANG_ORACLE:
		dikenal["%s/%s/%d" % [baris[0], baris[1], LoperAnim.Sisi.SEBERANG]] = true
	dikenal["tong_sampah/logam/%d" % LoperAnim.Sisi.DEKAT] = true
	var tak_dikenal: int = 0
	var jumlah: int = 0
	var bulat: int = 0
	for i: int in range(60):
		var rute: RouteBuilder.Rute = RouteBuilder.bangun(SEED_DEV + i * 7, pustaka).rute
		for b: RouteBuilder.DekorItem in rute.dekor:
			jumlah += 1
			if not dikenal.has("%s/%s/%d" % [b.jenis, b.varian, b.sisi]):
				tak_dikenal += 1
			if b.maju_ubin == floorf(b.maju_ubin):
				bulat += 1
	check(jumlah > 1200 and tak_dikenal == 0 and bulat == jumlah, "60 rute: %d dekor, semua kombinasi jenis/varian/sisi tercakup sapuan per sprite (%d tidak dikenal) dan semua di maju bulat (%d)" % [jumlah, tak_dikenal, bulat])


## Model lama (tinggi pohon 1,25, lampu 1,0, tapak kaki 0,5 dan 0,25) meninggalkan piksel tertutup: sapuan menangkapnya, jadi mutan "tinggi kembali 1,25" tidak lolos.
func _test_model_lama_gagal() -> void:
	_judul.call("Kontrol: model kotak lama (pohon 1,25, lampu 1,0, tapak kaki) meninggalkan pemain di bawah piksel opak, sapuan piksel mendeteksinya (QA-001)")
	var lama: Array = [["pohon", "rindang", 0.25, 1.25], ["pohon", "glodokan", 0.25, 1.25], ["pohon", "ketapang", 0.25, 1.25], ["lampu_jalan", "lengan", 0.125, 1.0]]
	for baris: Array in lama:
		var d: RouteBuilder.DekorItem = UkurPenutupPiksel.dekor_buatan(baris[0], baris[1], LoperAnim.Sisi.DEKAT, 20.0)
		var pusat: Vector2 = Vector2(UkurPenutupPiksel.lateral_dekor(d), 20.0)
		var setengah: float = float(baris[2])
		var kotak: PenutupPemain.Objek = PenutupPemain.buat(Rect2(pusat.x - setengah, pusat.y - setengah, setengah + setengah, setengah + setengah), float(baris[3]), "lama")
		var h: Dictionary = UkurPenutupPiksel.sapu_pemain(d, 0.25, 1.0 / 16.0, 4.0, kotak)
		check((h["tak_tertutup"] as Array).size() >= 20 and int(h["piksel_maks"]) >= 40, "%s dengan kotak lama: %d posisi tertimpa opak tanpa tertutup, terburuk %d piksel" % [baris[1], (h["tak_tertutup"] as Array).size(), int(h["piksel_maks"])])
	# Hanya tinggi diperbaiki (tapak kaki dipertahankan) belum cukup: tajuk dan lengan lebih lebar dari tapak kaki.
	var d2: RouteBuilder.DekorItem = UkurPenutupPiksel.dekor_buatan("pohon", "glodokan", LoperAnim.Sisi.DEKAT, 20.0)
	var kotak2: PenutupPemain.Objek = PenutupPemain.buat(DekorRute.tapak("pohon", LoperAnim.Sisi.DEKAT, 20.0), 63.0 / 32.0, "tinggi_saja")
	var h2: Dictionary = UkurPenutupPiksel.sapu_pemain(d2, 0.25, 1.0 / 16.0, 4.0, kotak2)
	check((h2["tak_tertutup"] as Array).size() >= 20, "glodokan dengan tinggi sprite (1,97) tetapi tapak kaki: masih %d posisi tertimpa opak (tapak penutup harus selebar tajuk)" % (h2["tak_tertutup"] as Array).size())


# --- Tong sampah dekat: batas yang diketahui ---

## Tong sampah sisi dekat (tinggi 24 piksel = 0,75 ubin) tidak didaftarkan ke penerap penutup (putusan P-6), jadi ia boleh menimpa pemain dengan piksel opak. Batasnya dikunci di sini supaya tidak berubah diam-diam:
## hanya di trotoar dekat (lateral 1,375 sampai 2,0), tidak pernah di aspal (|lateral| <= 1,0), dan di bawah 300 piksel. Keputusan mendaftarkannya ke penerap ada di orchestrator (LOG iterasi 2).
func _test_tong_dekat_batas_diketahui() -> void:
	_judul.call("Tong sampah sisi dekat: menimpa pemain hanya di trotoar dekat (lateral >= 1,375), tidak pernah di aspal; batas yang diketahui (P-6, LOG iterasi 2)")
	var d: RouteBuilder.DekorItem = UkurPenutupPiksel.dekor_buatan("tong_sampah", "logam", LoperAnim.Sisi.DEKAT, 20.0)
	var h: Dictionary = UkurPenutupPiksel.sapu_pemain(d, 0.125, 1.0 / 32.0, 4.0)
	var lateral_min: float = 99.0
	for v: Vector3 in h["tak_tertutup"]:
		lateral_min = minf(lateral_min, v.x)
	check(int(h["tumpang"]) == (h["tak_tertutup"] as Array).size() and int(h["tumpang"]) > 0 and lateral_min >= 1.375 and int(h["piksel_maks"]) <= 300, "tong sampah dekat: %d posisi menimpa pemain, semuanya tak tertutup (tong tidak menutupi), lateral terkecil %s (>= 1,375: aspal bersih), terburuk %d piksel (<= 300)" % [int(h["tumpang"]), lateral_min, int(h["piksel_maks"])])


# --- Seberang ---

func _test_seberang_tidak_menutupi() -> void:
	_judul.call("Dekor sisi seberang tidak pernah menutupi (kotak penutup tinggi 0) dan tidak pernah menimpa pemain dengan piksel opak di lateral -2,0 sampai 2,0 (P-6, D-6 iterasi 2)")
	var tertutup: int = 0
	var diperiksa: int = 0
	for baris: Array in SEBERANG_ORACLE:
		var d: RouteBuilder.DekorItem = UkurPenutupPiksel.dekor_buatan(baris[0], baris[1], LoperAnim.Sisi.SEBERANG, 20.0)
		var kotak: PenutupPemain.Objek = PenutupPemain.dari_dekor(d)
		for i: int in range(-16, 17):
			for k: int in range(-80, 81):
				diperiksa += 1
				if PenutupPemain.menutupi(Vector2(float(i) * 0.125, -(20.0 + float(k) * 0.0625)), kotak):
					tertutup += 1
	check(diperiksa > 10000 and tertutup == 0, "dekor seberang: 0 dari %d posisi pemain tertutup" % diperiksa)
	# Karena tidak pernah menutupi, piksel opak dekor seberang tidak boleh berada di atas pemain di posisi mana pun (tajuk dan lengan lampu lebar; lateral seberang pohon 2,75 dan lampu 2,625).
	for baris: Array in SEBERANG_ORACLE:
		var d2: RouteBuilder.DekorItem = UkurPenutupPiksel.dekor_buatan(baris[0], baris[1], LoperAnim.Sisi.SEBERANG, 20.0)
		var h: Dictionary = UkurPenutupPiksel.sapu_pemain(d2, 0.125, 1.0 / 32.0, 4.0)
		check(int(h["diperiksa"]) > 8000 and int(h["tumpang"]) == 0, "%s %s seberang: 0 posisi dengan piksel opak di atas pemain dari %d posisi (dapat %d, terburuk %d piksel)" % [baris[0], baris[1], int(h["diperiksa"]), int(h["tumpang"]), int(h["piksel_maks"])])
	# Kontrol: pada lateral lama (pohon dan lampu 2,5 dan 2,25) piksel opak dekor seberang memang menimpa pemain di tepi seberang (oracle mampu mendeteksi).
	var lama: Array = [["pohon", "rindang", -2.5], ["pohon", "ketapang", -2.5], ["lampu_jalan", "lengan", -2.25]]
	for baris: Array in lama:
		var d3: RouteBuilder.DekorItem = UkurPenutupPiksel.dekor_buatan(baris[0], baris[1], LoperAnim.Sisi.SEBERANG, 20.0)
		var h3: Dictionary = UkurPenutupPiksel.sapu_pemain(d3, 0.125, 1.0 / 32.0, 4.0, null, float(baris[2]))
		check(int(h3["tumpang"]) >= 5 and int(h3["piksel_maks"]) >= 50, "%s %s seberang di lateral lama %s: %d posisi tertimpa opak, terburuk %d piksel" % [baris[0], baris[1], baris[2], int(h3["tumpang"]), int(h3["piksel_maks"])])


# --- Rintangan ---

## Sembilan segmen: tiap rintangan (anjing, mobil garasi) lawan tiap dekor segmen itu, di semua posisi yang bisa dicapai rintangan.
func _test_rintangan_terlihat() -> void:
	_judul.call("Rintangan di jalur selalu terlihat: 0 piksel opak dekor di atas anjing dan mobil garasi di semua posisinya, sembilan segmen dan 60 rute (ROUTE_DESIGN aturan 5, P-6)")
	var pustaka: Array[SegmenRute] = PemuatRute.muat_folder(FOLDER_RUTE).segmen
	var pasangan: int = 0
	var buruk: Array[String] = []
	for segmen: SegmenRute in pustaka:
		for o: SegmenRute.Objek in segmen.objek:
			if o.jenis != "anjing_penjaga" and o.jenis != "mobil_garasi":
				continue
			for butir: SegmenRute.Dekor in segmen.dekor:
				pasangan += 1
				var d: RouteBuilder.DekorItem = UkurPenutupPiksel.dekor_buatan(butir.jenis, butir.varian, butir.sisi, float(butir.pos))
				var jalur: String = o.jalur
				var h: Dictionary = UkurPenutupPiksel.sapu_rintangan(d, o.jenis, float(o.pos), jalur, 0.125)
				if int(h["tumpang"]) > 0:
					buruk.append("%s: %s@%d (%s) tertimpa %s %s@%d: %d posisi, terburuk %d piksel di %s" % [segmen.id, o.jenis, o.pos, jalur, butir.jenis, butir.varian, butir.pos, int(h["tumpang"]), int(h["piksel_maks"]), h["posisi_terburuk"]])
	check(pasangan >= 40 and buruk.is_empty(), "%d pasangan rintangan x dekor di sembilan segmen: 0 piksel opak dekor di atas rintangan: %s" % [pasangan, buruk.slice(0, 3)])
	# 60 rute: pasangan rintangan x dekor yang berdekatan (selisih maju <= 8), dengan cache menurut (jenis rintangan, jalur, dekor, selisih maju).
	var pasangan_rute: int = 0
	var cache: Dictionary = {}
	var buruk_rute: Array[String] = []
	for i: int in range(60):
		var rute: RouteBuilder.Rute = RouteBuilder.bangun(SEED_DEV + i * 7, pustaka).rute
		for o: RouteBuilder.ObjekRute in rute.objek:
			if o.jenis != "anjing_penjaga" and o.jenis != "mobil_garasi":
				continue
			for b: RouteBuilder.DekorItem in rute.dekor:
				if absf(b.maju_ubin - o.maju_ubin) > 8.0:
					continue
				pasangan_rute += 1
				var kunci: String = "%s/%s/%s/%s/%s/%s" % [o.jenis, o.jalur, b.jenis, b.varian, b.sisi, b.maju_ubin - o.maju_ubin]
				if not cache.has(kunci):
					var d: RouteBuilder.DekorItem = UkurPenutupPiksel.dekor_buatan(b.jenis, b.varian, b.sisi, b.maju_ubin - o.maju_ubin)
					cache[kunci] = int(UkurPenutupPiksel.sapu_rintangan(d, o.jenis, 0.0, o.jalur, 0.125)["tumpang"])
				if int(cache[kunci]) > 0:
					buruk_rute.append("seed %d: %s@%s lawan %s" % [SEED_DEV + i * 7, o.jenis, o.maju_ubin, b.id])
	check(pasangan_rute > 100 and buruk_rute.is_empty(), "60 rute: %d pasangan rintangan x dekor berdekatan (%d selisih berbeda): 0 tertimpa: %s" % [pasangan_rute, cache.size(), buruk_rute.slice(0, 3)])


## Kontrol: penempatan lama (tong sampah dekat 1 ubin di depan anjing dekat, lampu dekat 1 ubin di belakang anjing dekat) memang terukur menimpa anjing.
func _test_rintangan_kontrol() -> void:
	_judul.call("Kontrol rintangan: tong sampah dan lampu sisi dekat di dekat anjing sisi dekat memang terukur menimpa anjing (oracle mampu mendeteksi)")
	var tong: RouteBuilder.DekorItem = UkurPenutupPiksel.dekor_buatan("tong_sampah", "logam", LoperAnim.Sisi.DEKAT, 31.0)
	var h1: Dictionary = UkurPenutupPiksel.sapu_rintangan(tong, "anjing_penjaga", 30.0, "dekat", 0.125)
	check(int(h1["tumpang"]) > 20 and int(h1["piksel_maks"]) >= 100, "tong sampah dekat di maju 31 lawan anjing dekat di 30: %d posisi, terburuk %d piksel" % [int(h1["tumpang"]), int(h1["piksel_maks"])])
	var lampu: RouteBuilder.DekorItem = UkurPenutupPiksel.dekor_buatan("lampu_jalan", "lengan", LoperAnim.Sisi.DEKAT, 27.0)
	var h2: Dictionary = UkurPenutupPiksel.sapu_rintangan(lampu, "anjing_penjaga", 28.0, "dekat", 0.125)
	check(int(h2["tumpang"]) > 20 and int(h2["piksel_maks"]) >= 100, "lampu dekat di maju 27 lawan anjing dekat di 28: %d posisi, terburuk %d piksel" % [int(h2["tumpang"]), int(h2["piksel_maks"])])
