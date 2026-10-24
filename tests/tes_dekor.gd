class_name TesDekor
extends RefCounted
## Tes run fase5b-tembok-dekor bagian B2: dekor pinggir jalan di data segmen (AC-9 sampai AC-13, AC-18 bagian dekor) dan kotak penutup rumah dekat yang digeser seperti gambarnya (P-4).
##
## Harapan ditulis sebagai literal atau dihitung tes dengan cara lain dari kode produksi:
## - Rute identik: 60 seed (20261016 + 7 i) dibandingkan dengan sidik FNV-1a dari uraian rute (rumah, rintangan, pelanggan, titik misi, tenggat, skor dari 25 antaran) yang dihitung di commit
##   SEBELUM bagian B2 (fb9033d), ditulis literal di `GOLDEN_RUTE`; `_uraian` dan `_fnv` di sini sama dengan skrip penghitung golden itu.
## - Geometri: lateral, tapak, dan tinggi penutup ditulis literal; kena atau tidaknya penutup dihitung dengan penalaran garis pandang yang ditulis di komentar, bukan dengan memanggil aturan yang diuji.
## - Sasaran tidak tertutup: pecahan piksel opak dari `UkurDekor` (pola `UkurTembok`), dengan kontrol bahwa penempatan buruk memang terukur.
## - Isi sembilan segmen: jumlah per berkas dan per jenis ditulis literal, dihitung dari berkas data dengan skrip lain.
## - Kotak penutup pohon dan lampu sisi dekat = sprite nyata (iterasi 2, QA-001, P-6): bukti pemain tidak pernah hilang di balik piksel opak ada di `TesDekorPiksel` (oracle piksel dari PNG);
##   di sini hanya geometri kotak (murni) dan perilaku di scene.

const BERKAS_RUTE: String = "res://scenes/rute/rute.tscn"
const FOLDER_RUTE: String = "res://assets/data/routes/perumahan"
const FOLDER_PROPS: String = "res://assets/sprites/props"
const SEED_DEV: int = 20261016
const DAUR_MUNDUR: float = 20.0
const DAUR_MAJU: float = 30.0
## Sidik uraian rute untuk seed 20261016 + 7 i (i = 0 sampai 59), dihitung di commit fb9033d sebelum dekor ada; dihitung ulang oleh skrip `docs/loop/20261022-fase5c-animasi-simpang/dev_ukur/banding_p6.gd`
## sesudah putusan P-6 run 5C (rumah seberang per_buka_02@18 dihapus: 31 seed berubah, satu-satunya beda baris rumah itu; LOG run 5C).
## Run 5D bagian B (AC-8, D-5): sidik DIHITUNG ULANG oleh skrip dari kode sesudah rumah dekat diberi pelanggan_boleh (34 dari 36 rumah dekat; baris R memuat bidang itu). Bukti per golden: dengan bidang pelanggan_boleh rumah DEKAT
## ditopeng false, sidik 60 seed sama persis dengan nilai sebelumnya (kontrol skrip), jadi satu-satunya beda adalah bidang itu; segmen, rumah, pelanggan, pemberi tip, rintangan, titik misi, dekor, tenggat, dan skor tidak berubah (LOG bagian B).
const GOLDEN_RUTE: Array[int] = [
	299265929, 592171248, 1677403481, 32812021, 2913826288, 1046867607, 988649871, 1534843447, 330497132, 2754380451, 2522862173, 3442290866, 2427538121, 4120860591, 1824805011,
	3043426513, 21044601, 180660512, 3160363486, 1915645779, 2609557601, 759987888, 374147715, 3655786764, 1664289267, 3154014392, 1118545561, 3742039627, 471049183, 456681243,
	3514914666, 4182804130, 126450175, 3476316046, 2976101518, 1870146191, 1103024936, 1301129216, 955434053, 4062427992, 780297767, 2986942708, 426223188, 4294850231, 3331496612,
	1054790504, 4103035617, 524582720, 496311467, 4004418556, 2131610056, 1640273865, 4127787835, 2966526230, 1474512725, 251310509, 339062592, 2229810785, 1594329270, 3403948488,
]
## Banyaknya dekor per berkas (urut nama): dihitung dari berkas data dengan skrip lain (Python), ditulis literal.
const JUMLAH_PER_BERKAS: Array = [
	["per_buka_01", 5], ["per_buka_02", 5], ["per_tengah_01", 4], ["per_tengah_02", 4], ["per_tengah_03", 4], ["per_tengah_04", 4], ["per_tengah_05", 4], ["per_tutup_01", 4], ["per_tutup_02", 4],
]
## Sprite dekor: [nama, lebar sel, tinggi sel, pijak x, pijak y] (dari JSON aset dan PNG, ditulis literal).
const SPRITE_ORACLE: Array = [
	["prop_tong_sampah_logam", 20, 30, 10, 25], ["prop_pohon_rindang", 151, 119, 41, 63], ["prop_pohon_glodokan", 121, 126, 25, 77], ["prop_pohon_ketapang", 141, 124, 35, 70],
	["prop_lampu_lengan_seberang", 85, 104, 9, 63], ["prop_lampu_lengan_dekat", 85, 104, 22, 69],
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
	_test_tabel_dan_geometri()
	_test_sprite_sama_dengan_json()
	_test_aturan_tempat_murni()
	_test_validasi_parse()
	_test_rute_identik()
	_test_rute_dekor()
	_test_penutup_murni()
	_test_isi_sembilan_segmen()
	_test_sasaran_tidak_tertutup()
	_test_medan_dan_penilaian_identik()
	_test_rujukan_dan_pemisahan()
	_test_p4_tapak_gambar_murni()
	await _test_scene_dekor()
	await _test_jendela_daur_dan_tekstur()
	await _test_penutup_scene()
	await _test_p4_scene()


# --- Tabel dan geometri (D-5, D-6) ---

func _test_tabel_dan_geometri() -> void:
	_judul.call("Dekor: jenis, varian, lateral, tapak, tinggi penutup, nama sprite (tabel Config = literal; D-5, D-6)")
	check(Config.RUTE_DEKOR_JENIS == (["tong_sampah", "pohon", "lampu_jalan"] as Array[String]), "jenis dekor: tong_sampah, pohon, lampu_jalan")
	check(DekorRute.varian_sah("tong_sampah") == (["logam"] as Array[String]) and DekorRute.varian_sah("pohon") == (["rindang", "glodokan", "ketapang"] as Array[String]) and DekorRute.varian_sah("lampu_jalan") == (["lengan"] as Array[String]), "varian sah: tong logam; pohon rindang, glodokan, ketapang; lampu lengan (D-5)")
	check(DekorRute.varian_sah("kursi").is_empty(), "jenis tidak dikenal: tanpa varian")
	check(Config.RUTE_DEKOR_LATERAL_UBIN == ([2.5, 2.5, 2.25] as Array[float]) and Config.RUTE_DEKOR_SETENGAH_UBIN == ([0.25, 0.25, 0.125] as Array[float]), "tabel lateral 2,5/2,5/2,25 dan setengah tapak kaki 0,25/0,25/0,125 (literal; tinggi dan tapak kotak penutup per sprite ada di TesDekorPiksel)")
	check(Config.RUTE_DEKOR_LAJUR_UBIN == 2.0 and Config.RUTE_DEKOR_JARAK_MIN_UBIN == 1 and Config.RUTE_DEKOR_TEPI_UBIN == 1, "lajur sepeda sampai 2,0, jarak dekor sesisi >= 1 ubin, pos mulai 1")
	check(DekorRute.lateral("pohon", LoperAnim.Sisi.SEBERANG) == -2.75 and DekorRute.lateral("pohon", LoperAnim.Sisi.DEKAT) == 2.5, "pohon: lateral -2,75 di seberang (iterasi 2: tajuk tidak menimpa pemain di tepi seberang), +2,5 di dekat")
	check(DekorRute.lateral("tong_sampah", LoperAnim.Sisi.SEBERANG) == -2.5 and DekorRute.lateral("tong_sampah", LoperAnim.Sisi.DEKAT) == 2.5, "tong sampah: lateral -2,5 dan +2,5")
	check(DekorRute.lateral("lampu_jalan", LoperAnim.Sisi.SEBERANG) == -2.625 and DekorRute.lateral("lampu_jalan", LoperAnim.Sisi.DEKAT) == 2.25, "lampu jalan: lateral -2,625 di seberang (iterasi 2), +2,25 di dekat")
	check(Config.RUTE_DEKOR_LATERAL_SEBERANG_UBIN == ([2.5, 2.75, 2.625] as Array[float]), "tabel lateral sisi seberang 2,5/2,75/2,625 (literal)")
	check(DekorRute.lateral("kursi", LoperAnim.Sisi.DEKAT) == 0.0 and DekorRute.lateral("pohon", LoperAnim.Sisi.TIDAK_ADA) == 0.0, "jenis atau sisi tidak dikenal: lateral 0")
	check(DekorRute.tapak("pohon", LoperAnim.Sisi.SEBERANG, 13.0) == Rect2(-3.0, 12.75, 0.5, 0.5), "tapak pohon seberang di maju 13: (-3,0; 12,75) 0,5 x 0,5 (pusat -2,75; tepi luar tepat di kaki fasad)")
	check(DekorRute.tapak("lampu_jalan", LoperAnim.Sisi.DEKAT, 21.0) == Rect2(2.125, 20.875, 0.25, 0.25), "tapak lampu dekat di maju 21: (2,125; 20,875) 0,25 x 0,25")
	check(DekorRute.tapak("tong_sampah", LoperAnim.Sisi.DEKAT, 15.0) == Rect2(2.25, 14.75, 0.5, 0.5), "tapak tong sampah dekat di maju 15: (2,25; 14,75) 0,5 x 0,5")
	check(DekorRute.tapak("pohon", LoperAnim.Sisi.TIDAK_ADA, 5.0) == Rect2() and DekorRute.tapak("kursi", LoperAnim.Sisi.DEKAT, 5.0) == Rect2(), "jenis atau sisi tidak dikenal: persegi kosong")
	check(DekorRute.tinggi_penutup("tong_sampah", "logam", LoperAnim.Sisi.DEKAT) == 0.75 and DekorRute.tinggi_penutup("tong_sampah", "logam", LoperAnim.Sisi.SEBERANG) == 0.0 and DekorRute.tinggi_penutup("pohon", "glodokan", LoperAnim.Sisi.DEKAT) == 1.96875 and DekorRute.tinggi_penutup("lampu_jalan", "lengan", LoperAnim.Sisi.DEKAT) == 2.0 and DekorRute.tinggi_penutup("kursi", "x", LoperAnim.Sisi.DEKAT) == 0.0, "tinggi penutup sisi dekat: tong 0,75 (seberang 0), pohon glodokan 1,96875, lampu 2,0 (tinggi sprite nyata)")
	check(DekorRute.menutupi("tong_sampah", "logam", LoperAnim.Sisi.DEKAT) and not DekorRute.menutupi("tong_sampah", "logam", LoperAnim.Sisi.SEBERANG) and DekorRute.menutupi("pohon", "rindang", LoperAnim.Sisi.DEKAT) and DekorRute.menutupi("lampu_jalan", "lengan", LoperAnim.Sisi.DEKAT) and not DekorRute.menutupi("pohon", "rindang", LoperAnim.Sisi.SEBERANG), "semua dekor sisi dekat (pohon, lampu, tong sampah, P-7) menutupi dan didaftarkan penerap; sisi seberang tidak")
	check(DekorRute.titik_dunia("pohon", LoperAnim.Sisi.DEKAT, 13.0) == Vector2(2.5, -13.0), "titik dunia pohon dekat di maju 13 = (2,5; -13) (y dunia = -maju)")
	var nama: Dictionary = {
		["tong_sampah", "logam", 1]: "prop_tong_sampah_logam", ["tong_sampah", "logam", 2]: "prop_tong_sampah_logam",
		["pohon", "rindang", 1]: "prop_pohon_rindang", ["pohon", "glodokan", 2]: "prop_pohon_glodokan", ["pohon", "ketapang", 1]: "prop_pohon_ketapang",
		["lampu_jalan", "lengan", 1]: "prop_lampu_lengan_seberang", ["lampu_jalan", "lengan", 2]: "prop_lampu_lengan_dekat",
	}
	var salah: Array[String] = []
	for kunci: Array in nama.keys():
		var dapat: String = DekorRute.nama_sprite(kunci[0], kunci[1], kunci[2] as LoperAnim.Sisi)
		if dapat != nama[kunci]:
			salah.append("%s: %s, harap %s" % [kunci, dapat, nama[kunci]])
	check(salah.is_empty() and DekorRute.nama_sprite("kursi", "x", LoperAnim.Sisi.DEKAT) == "" and DekorRute.nama_sprite("lampu_jalan", "lengan", LoperAnim.Sisi.TIDAK_ADA) == "", "nama sprite per jenis, varian, sisi: lampu menghadap jalan (seberang dan dekat), lainnya sama di kedua sisi: %s" % [salah])
	check(DekorRute.jalur_png("prop_pohon_rindang") == "res://assets/sprites/props/prop_pohon_rindang.png", "jalur PNG di assets/sprites/props")


func _test_sprite_sama_dengan_json() -> void:
	_judul.call("Sprite dekor: tabel Config = JSON aset = ukuran PNG untuk enam sprite (AC-11; pola DefSprite)")
	check(Config.RUTE_DEKOR_SPRITE.size() == 6 and Config.RUTE_DEKOR_SPRITE_DATA.size() == 6 * Config.SPRITE_PANJANG, "enam sprite dekor, lima angka tiap sprite")
	var salah: Array[String] = []
	for baris: Array in SPRITE_ORACLE:
		var nama: String = baris[0]
		var json: Variant = JSON.parse_string(FileAccess.get_file_as_string("%s/%s.json" % [FOLDER_PROPS, nama]))
		var tekstur: Texture2D = load("%s/%s.png" % [FOLDER_PROPS, nama]) as Texture2D
		if typeof(json) != TYPE_DICTIONARY or tekstur == null:
			salah.append("%s: JSON atau PNG tidak terbaca" % nama)
			continue
		var j: Dictionary = json
		var sel_json: Array = j["cell"]
		var pijak_json: Array = j["ground_anchor"]
		var data: Array[int] = DekorRute.data_sprite(nama)
		if int(sel_json[0]) != baris[1] or int(sel_json[1]) != baris[2] or int(pijak_json[0]) != baris[3] or int(pijak_json[1]) != baris[4] or int(j["frames"]) != 1:
			salah.append("%s: JSON %s %s berbeda dari literal" % [nama, sel_json, pijak_json])
		if tekstur.get_width() != baris[1] or tekstur.get_height() != baris[2]:
			salah.append("%s: PNG %dx%d berbeda dari sel %dx%d" % [nama, tekstur.get_width(), tekstur.get_height(), baris[1], baris[2]])
		if data != ([baris[1], baris[2], 1, baris[3], baris[4]] as Array[int]):
			salah.append("%s: Config %s berbeda dari JSON" % [nama, data])
		if DekorRute.sel(nama) != Vector2i(baris[1], baris[2]) or DekorRute.pijak(nama) != Vector2i(baris[3], baris[4]):
			salah.append("%s: sel() atau pijak() salah" % nama)
	check(salah.is_empty(), "tabel Config = JSON = PNG = literal untuk enam sprite dekor: %s" % [salah])
	check(DekorRute.data_sprite("tidak_ada").is_empty() and DekorRute.sel("tidak_ada") == Vector2i.ZERO and DekorRute.pijak("tidak_ada") == Vector2i.ZERO, "nama tidak dikenal: kosong, tanpa error")


# --- Aturan tempat murni (AC-9) ---

func _test_aturan_tempat_murni() -> void:
	_judul.call("Aturan tempat dekor murni: lajur sepeda, zona teras dan kotak surat, tapak rumah, tapak rintangan (AC-9)")
	# Lajur sepeda: |lateral| < 2,0; tepi yang hanya menyentuh = bukan menimpa.
	check(DekorRute.menimpa_lajur(Rect2(1.5, 5.0, 0.5, 0.5)) and DekorRute.menimpa_lajur(Rect2(1.75, 5.0, 0.5, 0.5)), "tapak di lateral 1,5 sampai 2,0 dan 1,75 sampai 2,25 menimpa lajur (dekat)")
	check(not DekorRute.menimpa_lajur(Rect2(2.0, 5.0, 0.5, 0.5)) and not DekorRute.menimpa_lajur(Rect2(-2.5, 5.0, 0.5, 0.5)), "tapak yang hanya menyentuh lajur (2,0 sampai 2,5 dan -2,5 sampai -2,0) tidak menimpa")
	check(DekorRute.menimpa_lajur(Rect2(-2.25, 5.0, 0.5, 0.5)) and DekorRute.menimpa_lajur(Rect2(-0.25, 5.0, 0.5, 0.5)), "tapak di -2,25 sampai -1,75 (seberang) dan di tengah jalan menimpa lajur")
	check(not DekorRute.menimpa_lajur(DekorRute.tapak("tong_sampah", LoperAnim.Sisi.SEBERANG, 5.0)) and not DekorRute.menimpa_lajur(DekorRute.tapak("pohon", LoperAnim.Sisi.DEKAT, 5.0)) and not DekorRute.menimpa_lajur(DekorRute.tapak("lampu_jalan", LoperAnim.Sisi.SEBERANG, 5.0)) and not DekorRute.menimpa_lajur(DekorRute.tapak("lampu_jalan", LoperAnim.Sisi.DEKAT, 5.0)), "tapak kaki semua jenis di kedua sisi di luar lajur sepeda (tepi tapak paling dalam 2,125 sampai 2,25)")
	# Zona seberang rumah di pos 6: teras (lateral -3 sampai -2,5; maju 6 sampai 7,25), kotak surat (lateral -2,75 sampai -1,75; maju 7,25 sampai 8,5).
	var s: LoperAnim.Sisi = LoperAnim.Sisi.SEBERANG
	var d: LoperAnim.Sisi = LoperAnim.Sisi.DEKAT
	check(DekorRute.menimpa_zona_rumah(Rect2(-2.75, 6.75, 0.5, 0.5), s, 6.0), "tapak (-2,75; 6,75) menimpa teras seberang rumah pos 6 (lateral -2,75 sampai -2,5, maju 6,75 sampai 7,25)")
	check(DekorRute.menimpa_zona_rumah(Rect2(-2.0, 7.75, 0.25, 0.25), s, 6.0), "tapak (-2,0; 7,75) menimpa zona kotak surat seberang (maju 7,25 sampai 8,5)")
	check(not DekorRute.menimpa_zona_rumah(Rect2(-2.75, 8.5, 0.5, 0.5), s, 6.0), "tapak yang mulai tepat di ujung zona (maju 8,5, eksklusif) tidak menimpa")
	check(not DekorRute.menimpa_zona_rumah(Rect2(-2.75, 4.5, 0.5, 0.5), s, 6.0), "tapak di maju 4,5 sampai 5,0 (jauh di belakang teras) tidak menimpa")
	# Run 5D bagian B (AC-10): zona dekat di rute = cermin seberang. Kotak surat lateral 1,75 sampai 2,75 (dulu 2,5), maju 11,25 sampai 12,5; teras menjorok rumah baru di lateral 3,1875 sampai 4,0625, maju 9,625 sampai 10,5625
	# (rumah pos 10: pusat gambar (5,0; 11,0) + teras_ubin [-1,8125; -1,375; 0,875; 0,9375]), jadi dekor sisi dekat (lateral <= 2,75) tidak pernah menjangkau teras dekat.
	check(not DekorRute.menimpa_zona_rumah(Rect2(2.25, 10.75, 0.5, 0.5), d, 10.0), "tapak (2,25; 10,75) tidak lagi menimpa zona dekat: teras dekat baru di lateral 3,1875 .. 4,0625 (dulu teras placeholder di lateral 2,5)")
	check(DekorRute.menimpa_zona_rumah(Rect2(3.25, 9.75, 0.5, 0.5), d, 10.0), "tapak hipotetis (3,25; 9,75) menimpa teras dekat rumah pos 10 (lateral 3,1875 .. 4,0625; maju 9,625 .. 10,5625)")
	check(DekorRute.menimpa_zona_rumah(Rect2(2.25, 11.75, 0.5, 0.5), d, 10.0), "tapak (2,25; 11,75) menimpa kotak surat dekat (lateral 1,75 sampai 2,75; maju 11,25 sampai 12,5)")
	check(DekorRute.menimpa_zona_rumah(Rect2(2.625, 11.75, 0.25, 0.25), d, 10.0) and not DekorRute.menimpa_zona_rumah(Rect2(2.75, 11.75, 0.25, 0.25), d, 10.0), "kotak surat dekat berakhir di lateral 2,75 (eksklusif): tapak 2,625 .. 2,875 menimpa, tapak 2,75 .. 3,0 tidak")
	check(not DekorRute.menimpa_zona_rumah(Rect2(2.25, 12.5, 0.5, 0.5), d, 10.0), "tapak mulai tepat di ujung kotak surat dekat (maju 12,5) tidak menimpa")
	check(not DekorRute.menimpa_zona_rumah(Rect2(-2.75, 6.75, 0.5, 0.5), LoperAnim.Sisi.TIDAK_ADA, 6.0), "rumah tanpa sisi: tanpa zona")
	# Halaman dan jendela BUKAN zona yang dihitung: tapak di halaman seberang jauh dari teras dan kotak surat boleh.
	check(not DekorRute.menimpa_zona_rumah(Rect2(-3.0, 5.5, 0.25, 0.25), s, 6.0), "tapak (-3,0; 5,5) di halaman (zona halaman, bukan teras atau kotak surat) tidak menimpa")
	# Tapak rumah (logika): seberang lateral -6 sampai -3, dekat 3 sampai 6, maju pos - 0,5 sampai pos + 2,5.
	check(DekorRute.menimpa_tapak_rumah(Rect2(-3.25, 7.0, 0.5, 0.5), s, 6.0), "tapak (-3,25; 7,0) menimpa tapak rumah seberang pos 6 (lateral -6 sampai -3)")
	check(not DekorRute.menimpa_tapak_rumah(Rect2(-2.75, 7.0, 0.5, 0.5), s, 6.0), "tapak (-2,75; 7,0) di luar tapak rumah seberang (tepi -3 hanya menyentuh)")
	check(DekorRute.menimpa_tapak_rumah(Rect2(2.75, 11.0, 0.5, 0.5), d, 10.0), "tapak (2,75; 11,0) menimpa tapak rumah dekat pos 10 (lateral 3 sampai 6)")
	check(not DekorRute.menimpa_tapak_rumah(Rect2(2.25, 11.0, 0.5, 0.5), d, 10.0), "tapak (2,25; 11,0) tidak menimpa tapak rumah dekat (tepi 3 hanya disentuh)")
	# Rintangan: mobil garasi seluruh lintasan (lateral 0 sampai 4, maju pos +- 0,375); anjing di posisi diamnya (lateral 2,5 sampai 3,0; maju pos +- 0,25).
	check(DekorRute.menimpa_rintangan(Rect2(-2.75, 23.75, 0.5, 0.5), "mobil_garasi", 24.0, s), "tapak pohon seberang di maju 24 menimpa lintasan mobil garasi pos 24 seberang")
	check(not DekorRute.menimpa_rintangan(Rect2(-2.75, 22.5, 0.5, 0.5), "mobil_garasi", 24.0, s), "tapak di maju 22,5 sampai 23 (lebih dari 0,375 dari mobil) tidak menimpa")
	check(not DekorRute.menimpa_rintangan(Rect2(2.25, 23.75, 0.5, 0.5), "mobil_garasi", 24.0, s), "mobil di seberang tidak menimpa tapak di sisi dekat")
	check(DekorRute.menimpa_rintangan(Rect2(2.25, 17.75, 0.5, 0.5), "anjing_penjaga", 18.0, d), "tapak tong di maju 18 dekat menimpa anjing dekat pos 18 (lateral 2,5 sampai 3,0 bertumpuk dengan 2,25 sampai 2,75)")
	check(not DekorRute.menimpa_rintangan(Rect2(2.25, 18.5, 0.5, 0.5), "anjing_penjaga", 18.0, d), "tapak yang mulai di maju 18,5 (ujung anjing 18,25) tidak menimpa")
	check(not DekorRute.menimpa_rintangan(Rect2(2.25, 17.75, 0.5, 0.5), "kucing", 18.0, d) and not DekorRute.menimpa_rintangan(Rect2(2.25, 17.75, 0.5, 0.5), "anjing_penjaga", 18.0, LoperAnim.Sisi.TIDAK_ADA), "jenis rintangan atau sisi tidak dikenal: tidak menimpa")


# --- Validasi parse (AC-9) ---

## Segmen dasar sah tanpa dekor: rumah seberang pos 6 (pelanggan), rumah dekat pos 10, anjing dekat pos 18, mobil seberang pos 24.
func _dasar() -> Dictionary:
	return {
		"id": "uji_dekor", "distrik": "perumahan", "panjang": 28,
		"tag": {"tingkat": "tenang", "sisi_pelanggan": "seberang", "posisi": "tengah"},
		"rumah": [
			{"pos": 6, "sisi": "seberang", "jenis": "limasan", "pelanggan_boleh": true},
			{"pos": 10, "sisi": "dekat", "jenis": "dekat_limasan", "pelanggan_boleh": false},
		],
		"objek": [
			{"jenis": "anjing_penjaga", "pos": 18, "jalur": "dekat", "tanda_ubin": 9},
			{"jenis": "mobil_garasi", "pos": 24, "jalur": "seberang", "tanda_ubin": 9},
		],
		"titik_misi": [],
	}


func _dengan(dekor: Variant) -> Dictionary:
	var d: Dictionary = _dasar()
	d["dekor"] = dekor
	return d


func _butir(jenis: String, pos: Variant, sisi: String, varian: Variant) -> Dictionary:
	return {"jenis": jenis, "pos": pos, "sisi": sisi, "varian": varian}


func _galat_memuat(data: Dictionary, kata: String) -> bool:
	var hasil: SegmenRute.Hasil = SegmenRute.parse(data)
	if hasil.sah():
		return false
	for g: String in hasil.galat:
		if g.contains(kata):
			return true
	return false


func _sah(data: Dictionary) -> bool:
	return SegmenRute.parse(data).sah()


func _test_validasi_parse() -> void:
	_judul.call("Validasi dekor di SegmenRute.parse: positif dan negatif per cabang penolakan (AC-9)")
	check(_sah(_dasar()) and SegmenRute.parse(_dasar()).segmen.dekor.is_empty(), "berkas lama tanpa bidang dekor tetap sah, dekor kosong")
	check(_sah(_dengan([])) and SegmenRute.parse(_dengan([])).segmen.dekor.is_empty(), "dekor berupa daftar kosong sah")
	var tiga: SegmenRute.Hasil = SegmenRute.parse(_dengan([_butir("pohon", 3, "seberang", "rindang"), _butir("tong_sampah", 14, "dekat", "logam"), _butir("lampu_jalan", 20.0, "seberang", "lengan")]))
	check(tiga.sah() and tiga.segmen.dekor.size() == 3 and tiga.segmen.dekor[0].jenis == "pohon" and tiga.segmen.dekor[0].pos == 3 and tiga.segmen.dekor[0].sisi == LoperAnim.Sisi.SEBERANG and tiga.segmen.dekor[0].varian == "rindang", "tiga dekor sah terbaca: jenis, pos, sisi, varian")
	check(tiga.segmen.dekor[1].sisi == LoperAnim.Sisi.DEKAT and tiga.segmen.dekor[2].pos == 20, "sisi dekat terbaca; pos 20.0 (float bulat) diterima sebagai 20")
	# Semua jenis dan varian sah, di kedua sisi (posisi bebas dari rumah dan rintangan).
	var semua_sah: bool = true
	for jenis: String in Config.RUTE_DEKOR_JENIS:
		for varian: String in DekorRute.varian_sah(jenis):
			for sisi: String in ["seberang", "dekat"]:
				semua_sah = semua_sah and _sah(_dengan([_butir(jenis, 2, sisi, varian)]))
	check(semua_sah, "semua kombinasi jenis x varian sah x sisi (5 varian x 2 sisi) lolos di pos 2")
	# Batas pos: 1 sampai panjang - 1 (28 - 1 = 27).
	check(_sah(_dengan([_butir("tong_sampah", 1, "seberang", "logam")])) and _sah(_dengan([_butir("tong_sampah", 27, "seberang", "logam")])), "pos 1 dan pos 27 (panjang 28 - 1) sah (batas dalam)")
	check(_galat_memuat(_dengan([_butir("tong_sampah", 0, "seberang", "logam")]), "pos 0 di luar 1 sampai 27") and _galat_memuat(_dengan([_butir("tong_sampah", 28, "seberang", "logam")]), "pos 28 di luar 1 sampai 27"), "pos 0 dan pos 28 (= panjang) ditolak (batas luar)")
	check(_galat_memuat(_dengan([_butir("tong_sampah", -3, "seberang", "logam")]), "di luar") and _galat_memuat(_dengan([_butir("tong_sampah", 99, "seberang", "logam")]), "di luar"), "pos negatif dan jauh melewati panjang ditolak")
	check(_galat_memuat(_dengan([_butir("tong_sampah", 3.5, "seberang", "logam")]), "bilangan bulat") and _galat_memuat(_dengan([_butir("tong_sampah", "3", "seberang", "logam")]), "bilangan bulat") and _galat_memuat(_dengan([_butir("tong_sampah", null, "seberang", "logam")]), "bilangan bulat"), "pos 3,5, teks \"3\", dan null ditolak (bukan bilangan bulat)")
	# Jenis, sisi, varian.
	check(_galat_memuat(_dengan([_butir("kursi", 3, "seberang", "logam")]), "jenis 'kursi' tidak dikenal"), "jenis salah ditolak")
	check(_galat_memuat(_dengan([_butir("tong_sampah", 3, "kiri", "logam")]), "sisi 'kiri' bukan seberang atau dekat"), "sisi kiri ditolak (hanya seberang atau dekat)")
	check(_galat_memuat(_dengan([_butir("tong_sampah", 3, "tengah", "logam")]), "sisi 'tengah' bukan seberang atau dekat"), "sisi tengah ditolak untuk dekor (jalur utama bersih)")
	check(_galat_memuat(_dengan([_butir("pohon", 3, "seberang", "beringin")]), "varian 'beringin' tidak sah untuk jenis pohon"), "varian pohon salah ditolak")
	check(_galat_memuat(_dengan([_butir("tong_sampah", 3, "seberang", "biru")]), "varian 'biru' tidak sah untuk jenis tong_sampah"), "varian tong biru ditolak (K-2: biru tidak dipasang)")
	check(_galat_memuat(_dengan([_butir("lampu_jalan", 3, "seberang", "nyala")]), "varian 'nyala' tidak sah"), "varian lampu nyala ditolak")
	check(_galat_memuat(_dengan([_butir("pohon", 3, "seberang", "logam")]), "tidak sah untuk jenis pohon"), "varian jenis lain (logam untuk pohon) ditolak")
	# Field.
	var asing: Dictionary = _butir("pohon", 3, "seberang", "rindang")
	asing["tinggi"] = 2
	check(_galat_memuat(_dengan([asing]), "field 'tinggi' tidak dikenal"), "field asing ditolak")
	for field: String in ["jenis", "pos", "sisi", "varian"]:
		var kurang: Dictionary = _butir("pohon", 3, "seberang", "rindang")
		kurang.erase(field)
		check(_galat_memuat(_dengan([kurang]), "field wajib '%s' tidak ada" % field), "field %s hilang ditolak (semua field wajib)" % field)
	check(_galat_memuat(_dengan(["pohon"]), "dekor #1: harus objek") and _galat_memuat(_dengan("pohon"), "'dekor' harus daftar") and _galat_memuat(_dengan({"jenis": "pohon"}), "'dekor' harus daftar"), "butir bukan objek dan dekor bukan daftar ditolak")
	var kosong: Dictionary = _butir("", 3, "seberang", "rindang")
	check(_galat_memuat(_dengan([kosong]), "'jenis' tidak boleh kosong") and _galat_memuat(_dengan([_butir("pohon", 3, "seberang", 5)]), "'varian' harus teks"), "jenis kosong dan varian bukan teks ditolak")
	# Tempat: zona teras dan kotak surat rumah mana pun (seberang pos 6, dekat pos 10), tapak rintangan.
	check(_galat_memuat(_dengan([_butir("pohon", 7, "seberang", "rindang")]), "menimpa zona teras atau kotak surat rumah seberang di pos 6"), "pohon seberang di maju 7 menimpa teras rumah pos 6: ditolak")
	check(_galat_memuat(_dengan([_butir("tong_sampah", 8, "seberang", "logam")]), "menimpa zona teras atau kotak surat rumah seberang di pos 6"), "tong seberang di maju 8 menimpa kotak surat rumah pos 6: ditolak")
	check(_sah(_dengan([_butir("pohon", 11, "dekat", "rindang")])), "pohon dekat di maju 11 sah: tapak maju 10,75 .. 11,25 berakhir tepat di awal kotak surat dekat (11,25) dan teras dekat baru jauh di lateral 3,19 (run 5D bagian B)")
	check(_galat_memuat(_dengan([_butir("pohon", 12, "dekat", "rindang")]), "menimpa zona teras atau kotak surat rumah dekat di pos 10"), "pohon dekat di maju 12 menimpa kotak surat dekat: ditolak")
	check(_galat_memuat(_dengan([_butir("lampu_jalan", 7, "seberang", "lengan")]), "menimpa zona teras atau kotak surat rumah seberang di pos 6"), "lampu seberang di maju 7 menimpa teras (lateral -3 sampai -2,5, maju 6 sampai 7,25): tapak -2,75 sampai -2,5 (iterasi 2: lampu seberang 2,625) ditolak")
	check(_sah(_dengan([_butir("lampu_jalan", 9, "seberang", "lengan")])), "lampu seberang di maju 9 sah: celah sesudah rumah pos 6, tapak maju 8,875 sampai 9,125 di luar kotak surat (sampai 8,5)")
	check(_galat_memuat(_dengan([_butir("tong_sampah", 24, "seberang", "logam")]), "menimpa tapak mobil_garasi di pos 24"), "tong seberang di pos mobil garasi: ditolak (seluruh lintasan)")
	check(_galat_memuat(_dengan([_butir("pohon", 18, "dekat", "rindang")]), "menimpa tapak anjing_penjaga di pos 18"), "pohon dekat di pos anjing: ditolak (posisi diam)")
	check(_sah(_dengan([_butir("pohon", 18, "seberang", "rindang")])), "pohon di seberang pada pos anjing dekat sah (sisi lain)")
	check(_sah(_dengan([_butir("pohon", 5, "seberang", "rindang"), _butir("pohon", 9, "seberang", "glodokan"), _butir("pohon", 13, "seberang", "ketapang")])), "pohon di gap antar rumah (pos 5, 9, 13) sah: celah satu ubin di antara tapak")
	check(_galat_memuat(_dengan([_butir("pohon", 9, "seberang", "rindang"), _butir("pohon", 9, "seberang", "glodokan")]), "hanya 0 ubin dari dekor sesisi di pos 9"), "dua dekor sesisi di pos yang sama ditolak (duplikat, kurang dari 1 ubin)")
	check(_sah(_dengan([_butir("pohon", 9, "seberang", "rindang"), _butir("pohon", 9, "dekat", "glodokan")])), "dua dekor di pos sama tetapi beda sisi sah")
	check(_sah(_dengan([_butir("lampu_jalan", 13, "seberang", "lengan"), _butir("lampu_jalan", 14, "seberang", "lengan")])), "dua dekor sesisi berjarak tepat 1 ubin sah (batas: kurang dari 1 ditolak)")
	# Galat banyak sekaligus dan pesan bukan teks pemain.
	var banyak: SegmenRute.Hasil = SegmenRute.parse(_dengan([_butir("kursi", 0, "kiri", "x"), _butir("pohon", 7, "seberang", "rindang")]))
	check(not banyak.sah() and banyak.segmen == null and banyak.galat.size() >= 4, "banyak pelanggaran dikumpulkan semua, segmen null (%d galat)" % banyak.galat.size())
	var punya_kunci: bool = false
	for g: String in banyak.galat:
		if g.contains("TERJEMAHAN") or g.begins_with("DEKOR_"):
			punya_kunci = true
	check(not punya_kunci, "pesan galat validasi adalah teks developer (data), bukan kunci terjemahan")
	# Lewat PemuatRute.parse_teks (JSON).
	var teks: String = JSON.stringify(_dengan([_butir("pohon", 5, "seberang", "ketapang")]))
	var dari_teks: SegmenRute.Hasil = PemuatRute.parse_teks(teks, "uji.json")
	check(dari_teks.sah() and dari_teks.segmen.dekor.size() == 1 and dari_teks.segmen.dekor[0].pos == 5, "dekor terbaca lewat PemuatRute.parse_teks (JSON)")
	var teks_buruk: String = JSON.stringify(_dengan([_butir("pohon", 7, "seberang", "ketapang")]))
	var buruk: SegmenRute.Hasil = PemuatRute.parse_teks(teks_buruk, "uji.json")
	check(not buruk.sah() and buruk.galat[0].begins_with("uji.json: "), "galat dekor lewat PemuatRute diberi nama berkas")


# --- Rute identik dan turunan dekor (AC-10) ---

func _test_rute_identik() -> void:
	_judul.call("RouteBuilder: rute tidak berubah dengan dekor ada, 60 seed sama dengan sidik sebelum run (rumah, rintangan, pelanggan, titik misi, tenggat, skor; AC-10)")
	var pustaka: Array[SegmenRute] = PemuatRute.muat_folder(FOLDER_RUTE).segmen
	var cocok: int = 0
	var salah: Array[int] = []
	for i: int in range(60):
		var hasil: RouteBuilder.Hasil = RouteBuilder.bangun(SEED_DEV + i * 7, pustaka)
		if hasil.sah() and _fnv(_uraian(hasil.rute)) == GOLDEN_RUTE[i]:
			cocok += 1
		else:
			salah.append(i)
	check(GOLDEN_RUTE.size() == 60 and cocok == 60, "60 rute: sidik uraian = golden commit sebelum dekor (%d cocok, salah di seed ke-%s)" % [cocok, salah])
	# Dekor tidak memakai RNG: bangun ulang dengan dekor dikosongkan menghasilkan rute sama (rumah, pelanggan).
	var tanpa: Array[SegmenRute] = []
	for segmen: SegmenRute in pustaka:
		var salin: SegmenRute = SegmenRute.parse(_data_tanpa_dekor(segmen)).segmen
		tanpa.append(salin)
	var sama: int = 0
	for i: int in range(60):
		var a: RouteBuilder.Hasil = RouteBuilder.bangun(SEED_DEV + i * 7, pustaka)
		var b: RouteBuilder.Hasil = RouteBuilder.bangun(SEED_DEV + i * 7, tanpa)
		if a.sah() and b.sah() and _uraian(a.rute) == _uraian(b.rute) and b.rute.dekor.is_empty() and not a.rute.dekor.is_empty():
			sama += 1
	check(sama == 60, "uraian rute dengan dan tanpa dekor di data segmen identik untuk 60 seed (%d), dekor hanya tambahan" % sama)


func _data_tanpa_dekor(segmen: SegmenRute) -> Dictionary:
	var teks: String = FileAccess.get_file_as_string("%s/%s.json" % [FOLDER_RUTE, segmen.id])
	var data: Dictionary = JSON.parse_string(teks)
	data.erase("dekor")
	return data


func _test_rute_dekor() -> void:
	_judul.call("RouteBuilder.Rute.dekor: maju mutlak, lateral, jenis, varian, id stabil; jarak sesisi di rute utuh (AC-10)")
	var pustaka: Array[SegmenRute] = PemuatRute.muat_folder(FOLDER_RUTE).segmen
	var salah: Array[String] = []
	var total: int = 0
	var jarak_min: float = INF
	for i: int in range(60):
		var rute: RouteBuilder.Rute = RouteBuilder.bangun(SEED_DEV + i * 7, pustaka).rute
		var ulang: RouteBuilder.Rute = RouteBuilder.bangun(SEED_DEV + i * 7, pustaka).rute
		var harapan: int = 0
		for s: SegmenRute in rute.segmen:
			harapan += s.dekor.size()
		if rute.dekor.size() != harapan or harapan < 20:
			salah.append("seed %d: %d dekor, harap %d (>= 20)" % [i, rute.dekor.size(), harapan])
		var id_terlihat: Dictionary = {}
		var terakhir: Dictionary = {1: -INF, 2: -INF}
		var maju_lalu: float = -INF
		for k: int in range(rute.dekor.size()):
			var b: RouteBuilder.DekorItem = rute.dekor[k]
			var u: RouteBuilder.DekorItem = ulang.dekor[k]
			total += 1
			var awal: float = rute.awal_segmen[_indeks_segmen(rute, b.id_segmen)]
			var sisi_nama: String = "seberang" if b.sisi == LoperAnim.Sisi.SEBERANG else "dekat"
			var lateral: float = -2.5 if b.sisi == LoperAnim.Sisi.SEBERANG else 2.5
			if b.jenis == "pohon" and b.sisi == LoperAnim.Sisi.SEBERANG:
				lateral = -2.75
			if b.jenis == "lampu_jalan":
				lateral = -2.625 if b.sisi == LoperAnim.Sisi.SEBERANG else 2.25
			if b.maju_ubin != awal + float(b.pos) or b.lateral_ubin != lateral or b.id != "%s:%s@%d" % [b.id_segmen, sisi_nama, b.pos]:
				salah.append("seed %d %s: maju %s lateral %s id %s" % [i, b.id, b.maju_ubin, b.lateral_ubin, b.id])
			if id_terlihat.has(b.id):
				salah.append("seed %d: id %s ganda" % [i, b.id])
			id_terlihat[b.id] = true
			if u.id != b.id or u.maju_ubin != b.maju_ubin or u.jenis != b.jenis or u.varian != b.varian:
				salah.append("seed %d: dekor ke-%d tidak stabil antar bangun" % [i, k])
			if b.maju_ubin < maju_lalu:
				salah.append("seed %d: dekor tidak urut maju di %s" % [i, b.id])
			maju_lalu = b.maju_ubin
			var sebelum: float = terakhir[int(b.sisi)]
			if b.maju_ubin - sebelum < 1.0:
				salah.append("seed %d: %s hanya %.1f ubin dari dekor sesisi" % [i, b.id, b.maju_ubin - sebelum])
			if sebelum > -INF:
				jarak_min = minf(jarak_min, b.maju_ubin - sebelum)
			terakhir[int(b.sisi)] = b.maju_ubin
	check(salah.is_empty(), "60 rute: jumlah, maju mutlak, lateral, id, urutan, stabil antar bangun, jarak sesisi >= 1 ubin: %s" % [salah.slice(0, 3)])
	check(total > 1200 and jarak_min >= 4.0, "total %d dekor diperiksa; jarak sesisi terdekat di rute utuh %.1f ubin (>= 4: seperlunya, sambungan segmen terjaga)" % [total, jarak_min])
	# Periksa_rute menolak dua dekor sesisi < 1 ubin (rute buatan).
	var rute_buatan: RouteBuilder.Rute = RouteBuilder.bangun(SEED_DEV, pustaka).rute
	var a: RouteBuilder.DekorItem = rute_buatan.dekor[0]
	var b2: RouteBuilder.DekorItem = RouteBuilder.DekorItem.new()
	b2.id = "x:s@1"
	b2.sisi = a.sisi
	b2.maju_ubin = a.maju_ubin + 0.5
	b2.jenis = "tong_sampah"
	b2.varian = "logam"
	rute_buatan.dekor.append(b2)
	rute_buatan.dekor.sort_custom(func(p: RouteBuilder.DekorItem, q: RouteBuilder.DekorItem) -> bool: return p.maju_ubin < q.maju_ubin)
	var galat: Array[String] = RouteBuilder.periksa_rute(rute_buatan)
	var ada: bool = false
	for g: String in galat:
		if g.contains("dua dekor sesisi"):
			ada = true
	check(ada, "periksa_rute menolak dua dekor sesisi lebih dekat dari 1 ubin di rute utuh")


func _indeks_segmen(rute: RouteBuilder.Rute, id: String) -> int:
	for i: int in range(rute.segmen.size()):
		if rute.segmen[i].id == id:
			return i
	return 0


## Uraian rute tanpa dekor (sama dengan skrip penghitung golden, dijalankan di commit fb9033d).
func _uraian(rute: RouteBuilder.Rute) -> String:
	var bagian: Array[String] = []
	bagian.append("benih=%d;panjang=%s;koran=%d;tenggat=%s" % [rute.benih, str(rute.panjang_ubin), rute.koran_awal, str(TenggatRute.awal(rute.panjang_ubin).tenggat_detik)])
	var ids: Array[String] = []
	for s: SegmenRute in rute.segmen:
		ids.append(s.id)
	bagian.append("segmen=" + ",".join(ids))
	for r: RouteBuilder.RumahRute in rute.rumah:
		bagian.append("R|%s|%s|%d|%s|%s|%s|%s" % [r.id, str(r.maju_ubin), r.sisi, r.jenis, r.pelanggan, r.pelanggan_boleh, r.pemberi_tip])
	for o: RouteBuilder.ObjekRute in rute.objek:
		bagian.append("O|%s|%s|%s|%s|%s" % [o.jenis, o.id_segmen, str(o.maju_ubin), o.jalur, str(o.tanda_ubin)])
	for p: RouteBuilder.RumahRute in rute.pelanggan:
		bagian.append("P|" + p.id)
	for t: RouteBuilder.TitikMisiRute in rute.titik_misi:
		bagian.append("T|%s|%s|%s|%d" % [t.nama, t.id_segmen, str(t.maju_ubin), t.sisi])
	var k: SkorRute.Keadaan = SkorRute.awal()
	var i: int = 0
	for p: RouteBuilder.RumahRute in rute.pelanggan:
		var hasil: ZonaSasaran.Hasil = ZonaSasaran.Hasil.KOTAK_SURAT if i % 2 == 0 else ZonaSasaran.Hasil.TERAS
		var kecepatan: float = 3.0 if i % 3 != 0 else 5.0
		k = SkorRute.nilai(k, hasil, p.id, i % 3 == 0, kecepatan, RouteBuilder.pemberi_tip(rute, p.id), false).keadaan
		i += 1
	bagian.append("skor=%d;koin=%d;tip=%d;tepat=%d;antar=%d" % [k.skor, k.koin, k.jumlah_tip, k.jumlah_tepat, k.jumlah_antar])
	return "\n".join(bagian)


## FNV-1a 32 bit atas byte UTF-8 (ditulis ulang di sini, independen dari kode produksi).
func _fnv(teks: String) -> int:
	var nilai: int = 2166136261
	for b: int in teks.to_utf8_buffer():
		nilai = nilai ^ b
		nilai = (nilai * 16777619) & 4294967295
	return nilai


# --- Penutup dekor (AC-11) murni ---

func _test_penutup_murni() -> void:
	_judul.call("PenutupPemain.dari_dekor: kotak penutup pohon dan lampu sisi dekat (tinggi sprite nyata, tapak lebih lebar dari tapak kaki), seberang tidak pernah (AC-11, P-6)")
	var pohon: RouteBuilder.DekorItem = _item("pohon", LoperAnim.Sisi.DEKAT, 13.0)
	var kotak: PenutupPemain.Objek = PenutupPemain.dari_dekor(pohon)
	check(kotak.tapak == Rect2(1.625, 12.125, 1.75, 1.75) and kotak.tinggi_ubin == 1.375 and kotak.id == pohon.id, "kotak penutup pohon rindang dekat maju 13 = tapak (1,625; 12,125) 1,75 x 1,75 (pusat 2,5; 13), tinggi 1,375, id dekor")
	var lampu: RouteBuilder.DekorItem = _item("lampu_jalan", LoperAnim.Sisi.DEKAT, 21.0)
	check(PenutupPemain.dari_dekor(lampu).tapak == Rect2(1.5, 20.25, 1.5, 1.5) and PenutupPemain.dari_dekor(lampu).tinggi_ubin == 2.0, "kotak penutup lampu dekat maju 21 = tapak (1,5; 20,25) 1,5 x 1,5 (pusat 2,25; 21), tinggi 2,0")
	# Garis pandang: titik (x, y) dan (x + d, y - d) (maju - d) tertutup bila (x + d, y - d) di dalam tapak dan tinggi d <= tinggi kotak.
	# Pohon dekat (tapak lateral 1,625 sampai 3,375; maju 12,125 sampai 13,875; tinggi 1,375): pemain di lateral 2,0 dan maju 13,5: d = 0 sudah di dalam tapak (lateral 2,0; maju 13,5).
	check(PenutupPemain.menutupi(Vector2(2.0, -13.5), kotak), "pemain di trotoar dekat (lateral 2,0; maju 13,5) tertutup pohon dekat")
	check(PenutupPemain.menutupi(Vector2(2.0, -13.1), kotak) and PenutupPemain.menutupi(Vector2(2.0, -13.8), kotak), "pemain di lateral 2,0 di maju 13,1 dan 13,8 tertutup (di dalam tapak penutup)")
	check(PenutupPemain.menutupi(Vector2(1.0, -13.3), kotak) and PenutupPemain.menutupi(Vector2(0.75, -13.6), kotak), "pemain di lajur dekat (lateral 1,0; maju 13,3) dan (0,75; maju 13,6) tertutup: garis pandang d = 0,625 .. 0,875 masuk tapak, tinggi di bawah 1,375 (tajuk menimpa lajur)")
	check(not PenutupPemain.menutupi(Vector2(2.0, -12.125), kotak), "pemain di maju 12,125 tepat di tepi belakang tapak penutup tidak tertutup")
	check(not PenutupPemain.menutupi(Vector2(2.0, -11.0), kotak), "pemain di maju 11,0 (di belakang pohon, garis pandang mundur keluar tapak) tidak tertutup")
	check(not PenutupPemain.menutupi(Vector2(2.0, -16.0), kotak), "pemain di maju 16,0 (terlalu jauh di depan: garis pandang ke tapak lebih tinggi dari 1,375) tidak tertutup")
	check(not PenutupPemain.menutupi(Vector2(0.0, -13.5), kotak) and not PenutupPemain.menutupi(Vector2(0.0, -14.5), kotak), "pemain di tengah jalan tidak tertutup pohon rindang dekat (garis pandang butuh d >= 1,625 > 1,375)")
	# Lampu dekat (tapak 1,5 sampai 3,0; maju 20,25 sampai 21,75; tinggi 2,0).
	check(PenutupPemain.menutupi(Vector2(2.0, -21.3), PenutupPemain.dari_dekor(lampu)), "pemain di (2,0; 21,3) tertutup lampu dekat")
	check(PenutupPemain.menutupi(Vector2(0.5, -21.3), PenutupPemain.dari_dekor(lampu)) and not PenutupPemain.menutupi(Vector2(0.0, -21.3), PenutupPemain.dari_dekor(lampu)), "lengan lampu dekat menutupi lajur sampai lateral 0,5 (d = 1,0 .. 1,05) tetapi tidak tengah jalan (butuh d >= 1,5 pada maju 21,3 - d > 20,25)")
	# Seberang: kotak tinggi 0, kamera melihat dari sisi dekat; tidak pernah menutupi di lateral -2,0 sampai 2,0.
	var s_pohon: RouteBuilder.DekorItem = _item("pohon", LoperAnim.Sisi.SEBERANG, 13.0)
	var s_lampu: RouteBuilder.DekorItem = _item("lampu_jalan", LoperAnim.Sisi.SEBERANG, 13.0)
	check(PenutupPemain.dari_dekor(s_pohon).tinggi_ubin == 0.0 and PenutupPemain.dari_dekor(s_lampu).tinggi_ubin == 0.0, "kotak penutup dekor seberang bertinggi 0")
	var tertutup_seberang: int = 0
	for lateral: int in range(-8, 9):
		for maju: int in range(0, 41):
			var titik: Vector2 = Vector2(float(lateral) * 0.25, -(10.0 + float(maju) * 0.125))
			if PenutupPemain.menutupi(titik, PenutupPemain.dari_dekor(s_pohon)) or PenutupPemain.menutupi(titik, PenutupPemain.dari_dekor(s_lampu)):
				tertutup_seberang += 1
	check(tertutup_seberang == 0, "pohon dan lampu seberang tidak pernah menutupi pemain di lateral -2,0 sampai 2,0: %d titik" % tertutup_seberang)
	# Tong sampah: tinggi 0 di kedua sisi.
	var tong: PenutupPemain.Objek = PenutupPemain.dari_dekor(_item("tong_sampah", LoperAnim.Sisi.DEKAT, 13.0))
	check(tong.tapak == Rect2(1.875, 12.375, 1.25, 1.25) and tong.tinggi_ubin == 0.75, "kotak penutup tong sampah dekat maju 13 = tapak (1,875; 12,375) 1,25 x 1,25, tinggi 0,75 (P-7)")
	check(PenutupPemain.menutupi(Vector2(2.0, -13.0), tong) and PenutupPemain.menutupi(Vector2(1.5, -13.2), tong) and not PenutupPemain.menutupi(Vector2(0.5, -13.0), tong) and not PenutupPemain.menutupi(Vector2(2.0, -15.0), tong), "tong dekat menutupi pemain di trotoar (2,0; 13,0) dan (1,5; 13,2), tidak di (0,5; 13,0) dan tidak jauh di depan (2,0; 15,0)")
	check(PenutupPemain.dari_dekor(_item("tong_sampah", LoperAnim.Sisi.SEBERANG, 13.0)).tinggi_ubin == 0.0, "tong sampah seberang tidak punya kotak penutup bertinggi")


func _item(jenis: String, sisi: LoperAnim.Sisi, maju: float) -> RouteBuilder.DekorItem:
	var b: RouteBuilder.DekorItem = RouteBuilder.DekorItem.new()
	b.jenis = jenis
	b.varian = DekorRute.varian_sah(jenis)[0]
	b.sisi = sisi
	b.pos = int(maju)
	b.maju_ubin = maju
	b.lateral_ubin = DekorRute.lateral(jenis, sisi)
	b.id = "uji:%s@%d" % ["seberang" if sisi == LoperAnim.Sisi.SEBERANG else "dekat", int(maju)]
	return b


# `_test_jalur_utama_bersih` (sapuan kotak: dekor tidak menutupi |lateral| <= 1,0) dihapus di iterasi 2: ia menjaga model kotak lama (tinggi 1,25 / 1,0) yang dinilai QA-001 salah,
# karena sprite jauh lebih tinggi dari kotak sehingga tajuk menimpa pemain dengan piksel opak. Penggantinya adalah tes piksel di `TesDekorPiksel` (P-6).


# --- Isi sembilan segmen (AC-13) ---

func _test_isi_sembilan_segmen() -> void:
	_judul.call("Isi sembilan segmen perumahan: 2 sampai 8 dekor per berkas, jumlah dan sebaran per jenis, seperlunya, penempatan (AC-13, D-6)")
	var muat: PemuatRute.Kumpulan = PemuatRute.muat_folder(FOLDER_RUTE)
	check(muat.sah() and muat.segmen.size() == 9, "sembilan segmen sah dimuat dengan dekor (%d galat: %s)" % [muat.galat.size(), muat.galat.slice(0, 2)])
	var jumlah_berkas: Array = []
	var tong: int = 0
	var pohon: int = 0
	var lampu: int = 0
	var sisi_jenis: Dictionary = {}
	var rapat: Array[String] = []
	var tempat_salah: Array[String] = []
	for segmen: SegmenRute in muat.segmen:
		jumlah_berkas.append([segmen.id, segmen.dekor.size()])
		var per_sisi: Dictionary = {1: [], 2: []}
		for d: SegmenRute.Dekor in segmen.dekor:
			match d.jenis:
				"tong_sampah":
					tong += 1
				"pohon":
					pohon += 1
				"lampu_jalan":
					lampu += 1
			sisi_jenis["%s/%s/%d" % [d.jenis, d.varian, d.sisi]] = true
			(per_sisi[int(d.sisi)] as Array).append(d.pos)
			if d.pos < 2 or d.pos > segmen.panjang - 2:
				tempat_salah.append("%s: dekor di pos %d terlalu dekat tepi segmen" % [segmen.id, d.pos])
			if d.jenis == "tong_sampah":
				# Tong sampah di celah sesudah rumah sisinya (gerbang, dekat kotak surat): rumah sisi sama di pos - 3.
				var ada_rumah: bool = false
				for r: SegmenRute.Rumah in segmen.rumah:
					if r.sisi == d.sisi and r.pos == d.pos - 3:
						ada_rumah = true
				if not ada_rumah:
					tempat_salah.append("%s: tong sampah di pos %d bukan di celah sesudah rumah" % [segmen.id, d.pos])
		for sisi: int in [1, 2]:
			var posisi: Array = per_sisi[sisi]
			posisi.sort()
			for k: int in range(1, posisi.size()):
				if int(posisi[k]) - int(posisi[k - 1]) < 4:
					rapat.append("%s sisi %d: pos %d dan %d" % [segmen.id, sisi, posisi[k - 1], posisi[k]])
	check(jumlah_berkas == JUMLAH_PER_BERKAS, "jumlah dekor per berkas = literal (dihitung dari data dengan skrip lain): %s" % [jumlah_berkas])
	var dalam_rentang: bool = true
	for baris: Array in jumlah_berkas:
		dalam_rentang = dalam_rentang and int(baris[1]) >= 2 and int(baris[1]) <= 8
	check(dalam_rentang, "tiap berkas punya 2 sampai 8 dekor")
	check(tong == 9 and pohon == 18 and lampu == 11, "seluruh set: %d tong sampah (>= 3), %d pohon (>= 6), %d lampu (>= 6); literal 9, 18, 11" % [tong, pohon, lampu])
	var lengkap: bool = true
	for varian: String in ["rindang", "glodokan", "ketapang"]:
		for sisi: int in [1, 2]:
			lengkap = lengkap and sisi_jenis.has("pohon/%s/%d" % [varian, sisi])
	check(lengkap, "ketiga varian pohon (rindang, glodokan, ketapang) muncul di kedua sisi")
	check(sisi_jenis.has("lampu_jalan/lengan/1") and sisi_jenis.has("lampu_jalan/lengan/2") and sisi_jenis.has("tong_sampah/logam/1") and sisi_jenis.has("tong_sampah/logam/2"), "lampu jalan dan tong sampah muncul di kedua sisi")
	check(rapat.is_empty(), "paling banyak satu dekor per 4 ubin per sisi di tiap segmen: %s" % [rapat.slice(0, 3)])
	check(tempat_salah.is_empty(), "dekor tidak di tepi segmen (pos 2 sampai panjang - 2, jadi sambungan segmen >= 4 ubin) dan tong sampah di celah sesudah rumah: %s" % [tempat_salah.slice(0, 3)])
	# D-6: pohon dan tong di halaman (lateral 2,5), lampu di tepi trotoar (lebih dekat ke jalan dari pohon, di luar lajur).
	check(Config.RUTE_DEKOR_LATERAL_UBIN[2] > Config.RUTE_DEKOR_LAJUR_UBIN and Config.RUTE_DEKOR_LATERAL_UBIN[2] < Config.RUTE_DEKOR_LATERAL_UBIN[1] and Config.RUTE_DEKOR_LATERAL_UBIN[0] == Config.RUTE_DEKOR_LATERAL_UBIN[1], "lampu di tepi trotoar (2,25: di luar lajur, lebih dekat ke jalan dari pohon dan tong 2,5)")


# --- Sasaran tidak tertutup (AC-12) ---

func _test_sasaran_tidak_tertutup() -> void:
	_judul.call("Dekor tidak menutupi sasaran: pecahan piksel opak yang menimpa kotak surat dan zona kotak surat/teras rumah pelanggan_boleh seberang = 0% di sembilan segmen (AC-12)")
	var muat: PemuatRute.Kumpulan = PemuatRute.muat_folder(FOLDER_RUTE)
	var maks: Dictionary = {"kotak_badan": 0.0, "kotak_badan_geom": 0.0, "zona_kotak": 0.0, "zona_teras": 0.0}
	var rumah_diukur: int = 0
	var dekor_diukur: int = 0
	for segmen: SegmenRute in muat.segmen:
		var h: Dictionary = UkurDekor.ukur(segmen, true)
		rumah_diukur += int(h["jumlah_rumah"])
		dekor_diukur += int(h["jumlah_dekor"])
		for kunci: String in maks.keys():
			maks[kunci] = maxf(float(maks[kunci]), float(h[kunci]))
	check(muat.segmen.size() == 9 and rumah_diukur >= 30 and dekor_diukur == 38, "kontrol: %d rumah seberang pelanggan_boleh dan %d dekor diukur di sembilan segmen" % [rumah_diukur, dekor_diukur])
	check(maks["kotak_badan"] == 0.0 and maks["kotak_badan_geom"] == 0.0, "badan sprite kotak surat sasaran: 0%% tertimpa dekor (terburuk %.4f, tanpa urutan gambar %.4f)" % [maks["kotak_badan"], maks["kotak_badan_geom"]])
	check(maks["zona_kotak"] == 0.0 and maks["zona_teras"] == 0.0, "zona kotak surat dan zona teras rumah pelanggan_boleh seberang: 0%% tertimpa dekor (terburuk %.4f dan %.4f)" % [maks["zona_kotak"], maks["zona_teras"]])
	# Kontrol: penempatan buruk memang terukur (pohon rindang seberang yang sah menurut tapak kaki tetapi tajuknya menimpa teras rumah pelanggan pos 6: pos 1 sampai 27 dicoba, yang terburuk).
	var terburuk: float = 0.0
	var pos_terburuk: int = -1
	for pos_coba: int in range(1, 28):
		var data: Dictionary = _dasar()
		data["dekor"] = [_butir("pohon", pos_coba, "seberang", "rindang")]
		var coba: SegmenRute.Hasil = SegmenRute.parse(data)
		if not coba.sah():
			continue
		var nilai: float = float(UkurDekor.ukur(coba.segmen, true)["zona_teras"])
		if nilai > terburuk:
			terburuk = nilai
			pos_terburuk = pos_coba
	check(pos_terburuk > 0 and terburuk > 0.0, "kontrol: pohon seberang yang sah menurut tapak kaki bisa menimpa zona teras (terburuk %.1f%% di pos %d; pengukur mampu mendeteksi)" % [terburuk * 100.0, pos_terburuk])
	# Tong sampah seberang di semua posisi sah tidak pernah menimpa sasaran (sprite kecil).
	var tong_buruk: float = 0.0
	for pos: int in range(1, 28):
		var d2: Dictionary = _dasar()
		d2["dekor"] = [_butir("tong_sampah", pos, "seberang", "logam")]
		var h2: SegmenRute.Hasil = SegmenRute.parse(d2)
		if h2.sah():
			var u: Dictionary = UkurDekor.ukur(h2.segmen, true)
			tong_buruk = maxf(tong_buruk, maxf(float(u["kotak_badan"]), maxf(float(u["zona_kotak"]), float(u["zona_teras"]))))
	check(tong_buruk == 0.0, "tong sampah seberang di semua pos sah segmen uji: 0%% menimpa sasaran (terburuk %.4f)" % tong_buruk)


func _test_medan_dan_penilaian_identik() -> void:
	_judul.call("Dekor tidak masuk MedanKoran: 1000 lemparan acak berseed dinilai identik dengan dan tanpa dekor (AC-12, AC-6)")
	var pustaka: Array[SegmenRute] = PemuatRute.muat_folder(FOLDER_RUTE).segmen
	var tanpa: Array[SegmenRute] = []
	for segmen: SegmenRute in pustaka:
		tanpa.append(SegmenRute.parse(_data_tanpa_dekor(segmen)).segmen)
	var rute_a: RouteBuilder.Rute = RouteBuilder.bangun(SEED_DEV, pustaka).rute
	var rute_b: RouteBuilder.Rute = RouteBuilder.bangun(SEED_DEV, tanpa).rute
	var medan_a: MedanKoran = MedanKoran.dari_rute(rute_a)
	var medan_b: MedanKoran = MedanKoran.dari_rute(rute_b)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 90210
	var sama: int = 0
	var tertutup_sama: int = 0
	var zona_sama: int = 0
	for i: int in range(1000):
		var r: RouteBuilder.RumahRute = rute_a.rumah[rng.randi_range(0, rute_a.rumah.size() - 1)]
		var titik: Vector2 = Vector2(rng.randf_range(-4.5, 4.5), -(r.maju_ubin + rng.randf_range(-1.0, 3.5)))
		var tinggi: float = rng.randf_range(0.0, 1.0)
		var za: Array[ZonaSasaran.Zona] = medan_a.zona_sekitar(titik)
		var zb: Array[ZonaSasaran.Zona] = medan_b.zona_sekitar(titik)
		if za.size() == zb.size():
			zona_sama += 1
		if int(ZonaSasaran.klasifikasi(titik, za)) == int(ZonaSasaran.klasifikasi(titik, zb)):
			sama += 1
		if medan_a.tertutup_titik(titik, tinggi) == medan_b.tertutup_titik(titik, tinggi):
			tertutup_sama += 1
	check(sama == 1000 and tertutup_sama == 1000 and zona_sama == 1000, "1000 lemparan: klasifikasi (%d), tertutup (%d), dan jumlah zona (%d) sama dengan dan tanpa dekor" % [sama, tertutup_sama, zona_sama])
	check(rute_a.rumah.size() == rute_b.rumah.size() and rute_a.pelanggan.size() == rute_b.pelanggan.size() and not rute_a.dekor.is_empty() and rute_b.dekor.is_empty(), "rute dengan dekor punya rumah dan pelanggan sama; hanya daftar dekor yang beda")


# --- Rujukan dan pemisahan (AC-11, AC-12, AC-18) ---

func _test_rujukan_dan_pemisahan() -> void:
	_judul.call("Dekor hanya hiasan: logika tabrakan, rintangan, medan, zona, skor, lempar, gerak, tenggat tidak merujuk dekor; pengguna DekorRute terbatas (AC-11, AC-12)")
	var bersih: Array[String] = []
	for jalur: String in ["scripts/systems/tabrakan.gd", "scripts/systems/rintangan_rute.gd", "scripts/systems/medan_koran.gd", "scripts/systems/zona_sasaran.gd", "scripts/systems/skor_rute.gd", "scripts/systems/throw_solver.gd", "scripts/systems/bike_motion.gd", "scripts/systems/tenggat_rute.gd", "scripts/systems/mission_manager.gd", "scripts/systems/koran_lempar.gd", "scripts/systems/bantu_lempar.gd", "scripts/entities/penerap_penutup.gd", "scripts/entities/rintangan_daur.gd"]:
		if FileAccess.get_file_as_string("res://" + jalur).to_lower().contains("dekor"):
			bersih.append(jalur)
	check(bersih.is_empty(), "logika tabrakan, rintangan, medan, zona, skor, lempar, gerak, tenggat, misi, penerap tidak merujuk dekor: %s" % [bersih])
	var berkas: Array[String] = []
	_kumpulkan("res://scripts", berkas)
	var pengguna: Array[String] = []
	for jalur: String in berkas:
		if jalur.ends_with(".gd") and not jalur.ends_with("dekor_rute.gd") and FileAccess.get_file_as_string(jalur).contains("DekorRute."):
			pengguna.append(jalur)
	pengguna.sort()
	check(pengguna == (["res://scripts/entities/dekor_daur.gd", "res://scripts/entities/rute_main.gd", "res://scripts/systems/hiasan_rute.gd", "res://scripts/systems/penutup_pemain.gd", "res://scripts/systems/route_builder.gd", "res://scripts/systems/segmen_rute.gd"] as Array[String]), "pengguna DekorRute di scripts: DekorDaur, RuteMain (hitungan penerap hiasan), HiasanRute (lateral dekor hiasan), PenutupPemain, RouteBuilder, SegmenRute saja: %s" % [pengguna])
	var pengguna_daur: Array[String] = []
	for jalur: String in berkas:
		if jalur.ends_with(".gd") and not jalur.ends_with("dekor_daur.gd") and FileAccess.get_file_as_string(jalur).contains("DekorDaur"):
			pengguna_daur.append(jalur)
	check(pengguna_daur == (["res://scripts/entities/rute_main.gd"] as Array[String]), "satu-satunya pengguna DekorDaur adalah RuteMain: %s" % [pengguna_daur])
	# Rujukan nama aset: hanya enam sprite dekor sah; nama pohon/lampu/tong lain di sumber ditolak.
	var semua: Array[String] = berkas.duplicate()
	for sub: String in ["res://scenes", "res://assets/data"]:
		_kumpulkan(sub, semua)
	var tes: DirAccess = DirAccess.open("res://tests")
	for nama: String in tes.get_files():
		if nama.ends_with(".gd") and not nama.begins_with("probe_"):
			semua.append("res://tests/" + nama)
	var regex: RegEx = RegEx.create_from_string("prop_(pohon|lampu|tong_sampah)_[a-z_0-9]*")
	var sah: Array[String] = ["prop_tong_sampah_logam", "prop_pohon_rindang", "prop_pohon_glodokan", "prop_pohon_ketapang", "prop_lampu_lengan_seberang", "prop_lampu_lengan_dekat"]
	var asing: Array[String] = []
	var total: int = 0
	for jalur: String in semua:
		var teks: String = FileAccess.get_file_as_string(jalur)
		for cocok: RegExMatch in regex.search_all(teks):
			total += 1
			var nama: String = cocok.get_string()
			# Awalan yang disambung kode ("prop_pohon_" + varian, "prop_lampu_%s_seberang") diizinkan bila ada nama sah yang diawali sama.
			var awalan_sah: bool = false
			for s: String in sah:
				awalan_sah = awalan_sah or s.begins_with(nama)
			if not sah.has(nama) and not awalan_sah:
				asing.append("%s: %s" % [jalur, nama])
	check(total > 10, "pemindai menemukan rujukan nama dekor (%d)" % total)
	check(asing.is_empty(), "tidak ada rujukan prop_pohon_/prop_lampu_/prop_tong_sampah_ di luar enam sprite sah: %s" % [asing])
	var terlarang: Array[String] = []
	for jalur: String in semua:
		var teks: String = FileAccess.get_file_as_string(jalur)
		for kata: String in ["tong_sampah_" + "biru", "lampu_lengan_dekat_" + "nyala", "lampu_lengan_seberang_" + "nyala", "prop_pohon_" + "beringin", "prop_lampu_" + "tiang"]:
			if teks.contains(kata) and not jalur.ends_with("tes_dekor.gd") and not jalur.ends_with("tes_ubin.gd"):
				terlarang.append("%s: %s" % [jalur, kata])
	check(terlarang.is_empty(), "tidak ada rujukan tong biru, lampu nyala, beringin, lampu jenis lain: %s" % [terlarang])


# --- P-4: kotak penutup rumah dekat digeser seperti gambarnya (murni) ---

func _test_p4_tapak_gambar_murni() -> void:
	_judul.call("P-4 PenutupPemain.tapak_rumah_gambar: rumah dekat = kotak sprite nyata (run 5D: mundur 0,5, JSON aset), seberang tetap, tapak logika tidak berubah")
	# Run fase5d-sisi-dekat (AC-5): dulu (4,25; 7,5) 3 x 3 (logika + 1,25). Kini pusat gambar (5,0; 9,0) + kotak JSON; tanpa jenis = gabungan tiga jenis: lateral 5,0 - 1,09375 = 3,90625,
	# maju 9,0 - 1,40625 = 7,59375, lebar terbesar 3,1125, panjang terbesar 2,8125.
	check(PenutupPemain.tapak_rumah_gambar(LoperAnim.Sisi.DEKAT, 8.0).is_equal_approx(Rect2(3.90625, 7.59375, 3.1125, 2.8125)), "tapak gambar rumah dekat di maju 8 tanpa jenis = (3,906; 7,594) 3,1125 x 2,8125 (gabungan sprite nyata)")
	check(PenutupPemain.tapak_rumah_gambar(LoperAnim.Sisi.SEBERANG, 8.0) == Rect2(-6.0, 7.5, 3.0, 3.0), "tapak gambar rumah seberang di maju 8 = (-6,0; 7,5) tidak bergeser")
	check(PenutupPemain.tapak_rumah_gambar(LoperAnim.Sisi.TIDAK_ADA, 8.0) == Rect2(), "tapak gambar sisi kosong: persegi kosong")
	check(PenutupPemain.tapak_rumah(LoperAnim.Sisi.DEKAT, 8.0) == Rect2(3.0, 7.5, 3.0, 3.0) and PenutupPemain.tapak_rumah(LoperAnim.Sisi.SEBERANG, 8.0) == Rect2(-6.0, 7.5, 3.0, 3.0), "tapak logika tidak berubah: dekat (3,0; 7,5), seberang (-6,0; 7,5)")
	var dekat: RouteBuilder.RumahRute = _rumah(8, 8.0, LoperAnim.Sisi.DEKAT)
	var seberang: RouteBuilder.RumahRute = _rumah(8, 8.0, LoperAnim.Sisi.SEBERANG)
	check(PenutupPemain.dari_rumah_gambar(dekat).tapak.is_equal_approx(Rect2(3.90625, 7.59375, 3.06875, 2.8125)) and PenutupPemain.dari_rumah_gambar(dekat).tinggi_ubin == 1.625 and PenutupPemain.dari_rumah_gambar(dekat).id == dekat.id, "kotak penutup gambar rumah dekat limasan: sprite nyata (3,906; 7,594) 3,06875 x 2,8125, tinggi 1,625, id rumah (run 5D; dulu logika + 1,25 tinggi 2)")
	check(PenutupPemain.dari_rumah_gambar(seberang).tapak == PenutupPemain.dari_rumah(seberang).tapak, "kotak penutup gambar rumah seberang = kotak penutup logika")
	check(PenutupPemain.dari_rumah(dekat).tapak == Rect2(3.0, 7.5, 3.0, 3.0), "kotak penutup logika rumah dekat tetap (3,0; 7,5) (MedanKoran, dites lama)")
	# Sapuan murni: pemain di lateral -2,0 sampai 2,0 (langkah 0,25) dan maju 6 ubin di sekitar rumah (langkah 0,125) tidak pernah tertutup rumah dekat yang digeser.
	# Penalaran (run 5D): titik kaki harus mencapai tapak (lateral 3,906) lewat garis pandang (x + d), jadi d >= 1,906 > tinggi 1,625 tak pernah tercapai.
	var dekat_tertutup: int = 0
	var seberang_tertutup: int = 0
	var diperiksa: int = 0
	for l: int in range(-8, 9):
		for m: int in range(-48, 97):
			var p: Vector2 = Vector2(float(l) * 0.25, -(8.0 + float(m) * 0.125))
			diperiksa += 1
			if PenutupPemain.menutupi(p, PenutupPemain.dari_rumah_gambar(dekat)):
				dekat_tertutup += 1
			if PenutupPemain.menutupi(p, PenutupPemain.dari_rumah_gambar(seberang)):
				seberang_tertutup += 1
	check(diperiksa > 2000 and dekat_tertutup == 0 and seberang_tertutup == 0, "sapuan %d titik (|lateral| <= 2,0): rumah dekat digeser dan rumah seberang tidak pernah menutupi pemain (%d dan %d)" % [diperiksa, dekat_tertutup, seberang_tertutup])
	# Kontrol: kotak logika lama (tanpa geser) memang menutupi pemain di trotoar dekat (gejala B1-F2).
	var lama_tertutup: int = 0
	for m: int in range(-48, 97):
		if PenutupPemain.menutupi(Vector2(1.75, -(8.0 + float(m) * 0.125)), PenutupPemain.dari_rumah(dekat)):
			lama_tertutup += 1
	check(lama_tertutup > 20, "kontrol: kotak logika rumah dekat (tanpa geser) menutupi pemain di lateral 1,75 pada %d titik maju (gejala B1-F2), sapuan mampu mendeteksi" % lama_tertutup)
	# Semua rumah di sembilan segmen dan rute nyata: kotak gambar rumah seberang sama dengan logika.
	var rute: RouteBuilder.Rute = RouteBuilder.bangun(SEED_DEV, PemuatRute.muat_folder(FOLDER_RUTE).segmen).rute
	var salah: Array[String] = []
	for r: RouteBuilder.RumahRute in rute.rumah:
		var gambar: Rect2 = PenutupPemain.dari_rumah_gambar(r).tapak
		var logika: Rect2 = PenutupPemain.dari_rumah(r).tapak
		if r.sisi == LoperAnim.Sisi.SEBERANG and gambar != logika:
			salah.append("%s: seberang bergeser" % r.id)
		# Run 5D: kotak gambar dekat = pusat tapak logika + 0,5 lateral + kotak sprite nyata per jenis (literal dari JSON aset).
		var kotak_jenis: Dictionary = {"dekat_limasan": [-1.09375, -1.40625, 3.06875, 2.8125], "dekat_pelana_lintang": [-1.09375, -1.40625, 3.1125, 2.8125], "dekat_pelana_sejajar": [-1.09375, -1.375, 3.1125, 2.75]}
		if r.sisi == LoperAnim.Sisi.DEKAT:
			var k: Array = kotak_jenis[r.jenis]
			var harap: Rect2 = Rect2(logika.get_center().x + 0.5 + float(k[0]), logika.get_center().y + float(k[1]), float(k[2]), float(k[3]))
			if not gambar.is_equal_approx(harap):
				salah.append("%s: kotak gambar dekat %s, harap %s" % [r.id, gambar, harap])
	check(salah.is_empty(), "rute nyata (%d rumah): kotak gambar seberang = logika, dekat = pusat logika + 0,5 + kotak sprite nyata: %s" % [rute.rumah.size(), salah.slice(0, 3)])


func _rumah(pos: int, maju: float, sisi: LoperAnim.Sisi) -> RouteBuilder.RumahRute:
	var r: RouteBuilder.RumahRute = RouteBuilder.RumahRute.new()
	r.id_segmen = "x"
	r.pos = pos
	r.id = "x@%d" % pos
	r.maju_ubin = maju
	r.sisi = sisi
	r.jenis = "dekat_limasan" if sisi == LoperAnim.Sisi.DEKAT else "limasan"
	return r


# --- Scene (AC-11) ---

func _test_scene_dekor() -> void:
	_judul.call("Scene rute: dekor digambar per jenis di jendela daur, letak piksel, Y-sort, anak Dekor di Objek, tong sampah bukan penutup (AC-11)")
	var akar: RuteMain = await _siapkan()
	var rute: RouteBuilder.Rute = akar.rute()
	var objek: Node2D = akar.find_child("Objek", true, false) as Node2D
	var dekor: DekorDaur = akar.dekor_daur()
	var daur: RumahDaurRute = akar.daur()
	check(dekor.get_parent() == objek and dekor.y_sort_enabled and objek.y_sort_enabled and dekor.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "node Dekor anak langsung Objek (Y-sort bersama rumah dan sepeda), y_sort_enabled, filter Nearest")
	var salah: Array[String] = []
	var diperiksa: int = 0
	# 235,5 (bukan 236): tepat di garis akhir dunia dibekukan (run garis-finish-portal), jadi titik uji terakhir tetap di dalam rute.
	var jarak_uji: Array[float] = [0.0, 40.0, 90.0, 140.0, 190.0, 235.5]
	for jarak: float in jarak_uji:
		_taruh_sepeda(akar, jarak)
		var harapan: Array[int] = _indeks_jendela(rute, jarak)
		if dekor.indeks_tampil() != harapan:
			salah.append("jarak %.0f: tampil %s, harap %s" % [jarak, dekor.indeks_tampil(), harapan])
		for i: int in dekor.indeks_tampil():
			var b: RouteBuilder.DekorItem = rute.dekor[i]
			var s: Sprite2D = dekor.sprite_dekor(i)
			diperiksa += 1
			var nama: String = _nama_oracle(b)
			var pijak: Vector2 = _pijak_oracle(nama)
			var lateral: float = UkurPenutupPiksel.lateral_dekor(b)
			if s.texture == null or s.texture.resource_path != "%s/%s.png" % [FOLDER_PROPS, nama]:
				salah.append("%s: tekstur %s, harap %s" % [b.id, s.texture.resource_path if s.texture != null else "null", nama])
			if s.position != _layar(lateral, b.maju_ubin) or s.offset != -pijak or s.centered or not s.visible or s.get_parent() != dekor:
				salah.append("%s: posisi %s offset %s, harap %s dan %s" % [b.id, s.position, s.offset, _layar(lateral, b.maju_ubin), -pijak])
			if s.z_index != 0 or s.y_sort_enabled:
				salah.append("%s: z_index %d atau y_sort sendiri" % [b.id, s.z_index])
	check(diperiksa > 20 and salah.is_empty(), "%d sprite dekor di enam titik gulir: jendela = oracle, tekstur sesuai jenis/varian/sisi, letak piksel dari proyeksi iso, titik pijak = JSON: %s" % [diperiksa, salah.slice(0, 3)])
	# Y-sort: urutan gambar dekor dan rumah dari posisi tegak pijak (sama dengan rumah, kotak surat, sepeda).
	_taruh_sepeda(akar, 100.0)
	var tegak_dekor_ada: bool = false
	for i: int in dekor.indeks_tampil():
		tegak_dekor_ada = tegak_dekor_ada or dekor.sprite_dekor(i).position.y != 0.0
	check(tegak_dekor_ada and daur.jumlah_rumah() > 5, "dekor dan rumah anak induk Y-sort yang sama, urutan dari posisi tegak titik pijak")
	# Tong sampah sisi seberang tidak didaftarkan ke penerap (alfa selalu 1,0); tong sisi dekat didaftarkan (P-7, alfanya 0,45 hanya bila menutupi pemain, lihat `_test_penutup_scene`).
	var penerap: PenerapPenutup = akar.penerap_penutup()
	var tong_tampil: int = 0
	var alfa_tong_salah: int = 0
	for jarak: float in [20.0, 80.0, 150.0, 220.0]:
		for lateral: float in [-2.0, 0.0, 2.0]:
			_taruh_sepeda(akar, jarak, lateral)
			for i: int in dekor.indeks_tampil():
				if rute.dekor[i].jenis == "tong_sampah" and rute.dekor[i].sisi == LoperAnim.Sisi.SEBERANG:
					tong_tampil += 1
					if dekor.sprite_dekor(i).modulate.a != 1.0:
						alfa_tong_salah += 1
			if penerap.jumlah() != daur.jumlah_rumah() + akar.rintangan_daur().jumlah_tampil() + _jumlah_penutup(akar) + 1 + akar.jumlah_hiasan_penerap():
				alfa_tong_salah += 1000
	check(tong_tampil >= 4 and alfa_tong_salah == 0, "tong sampah seberang tidak didaftarkan ke penerap (jumlah terdaftar = rumah + rintangan + dekor sisi dekat + portal) dan alfanya 1,0 di semua sapuan (%d tong terlihat, salah %d)" % [tong_tampil, alfa_tong_salah])
	_bersihkan(akar)


func _test_penutup_scene() -> void:
	_judul.call("Scene rute: pemain di balik pohon dan lampu sisi dekat = alfa RUTE_PENUTUP_ALFA, di tempat lain 1,0, kembali 1,0, lepas bersama sprite (AC-11)")
	var akar: RuteMain = await _siapkan()
	var rute: RouteBuilder.Rute = akar.rute()
	var dekor: DekorDaur = akar.dekor_daur()
	var penerap: PenerapPenutup = akar.penerap_penutup()
	var jenis_diuji: Dictionary = {}
	var salah: Array[String] = []
	var dicoba: int = 0
	for k: int in range(rute.dekor.size()):
		var b: RouteBuilder.DekorItem = rute.dekor[k]
		if b.sisi != LoperAnim.Sisi.DEKAT or not DekorRute.menutupi(b.jenis, b.varian, b.sisi) or jenis_diuji.has(b.jenis + b.varian):
			continue
		jenis_diuji[b.jenis + b.varian] = true
		dicoba += 1
		# Pemain di lateral 2,0 dan maju 0,3 di depan dekor: titik itu ada di dalam tapak penutup (d = 0), tinggi kotak lebih dari 1,3.
		var maju_pemain: float = b.maju_ubin + 0.3
		_taruh_sepeda(akar, maju_pemain, 2.0)
		var sprite: Sprite2D = dekor.sprite_dekor(k)
		if sprite == null:
			salah.append("%s: tidak digambar di maju pemain %.1f" % [b.id, maju_pemain])
			continue
		if not is_equal_approx(sprite.modulate.a, 0.45):
			salah.append("%s: alfa %.2f saat pemain di baliknya, harap 0,45" % [b.id, sprite.modulate.a])
		if penerap.jumlah_menutupi() < 1:
			salah.append("%s: penerap tidak mencatat penutup" % b.id)
		_taruh_sepeda(akar, maju_pemain, 0.0)
		if sprite.modulate.a != 1.0:
			salah.append("%s: alfa %.2f saat pemain di tengah jalan, harap 1,0" % [b.id, sprite.modulate.a])
		_taruh_sepeda(akar, maju_pemain, 2.0)
		if not is_equal_approx(sprite.modulate.a, 0.45):
			salah.append("%s: alfa %.2f saat pemain kembali ke baliknya, harap 0,45" % [b.id, sprite.modulate.a])
		_taruh_sepeda(akar, maju_pemain + 6.0, 2.0)
		if sprite.modulate.a != 1.0:
			salah.append("%s: alfa %.2f saat pemain sudah 5,7 ubin di depannya, harap 1,0" % [b.id, sprite.modulate.a])
	check(dicoba >= 3 and salah.is_empty(), "%d pohon dan lampu dekat (tiga varian pohon, lampu): alfa 0,45 di baliknya, 1,0 di tengah jalan, kembali 0,45, 1,0 di depannya: %s" % [dicoba, salah.slice(0, 3)])
	# Lajur sepeda (iterasi 2, P-6): posisi pemain di lateral 0,25 sampai 1,0 yang oracle piksel (`UkurPenutupPiksel`) buktikan tertimpa piksel opak dekor => alfa objek 0,45, bukan 1,0; pindah ke tengah jalan atau jauh => 1,0.
	var lajur_salah: Array[String] = []
	var lajur_dicoba: int = 0
	var jenis_lajur: Dictionary = {}
	for k: int in range(rute.dekor.size()):
		var b: RouteBuilder.DekorItem = rute.dekor[k]
		if b.sisi != LoperAnim.Sisi.DEKAT or not DekorRute.menutupi(b.jenis, b.varian, b.sisi) or jenis_lajur.has(b.jenis + b.varian):
			continue
		jenis_lajur[b.jenis + b.varian] = true
		var sapuan: Dictionary = UkurPenutupPiksel.sapu_pemain(b, 0.25, 1.0 / 16.0, 3.0)
		for lateral_uji: float in [0.5, 0.75, 1.0]:
			var terbaik: Vector3 = Vector3(-99.0, 0.0, 0.0)
			for v: Vector3 in sapuan["posisi_tumpang"]:
				if is_equal_approx(v.x, lateral_uji) and v.z > terbaik.z:
					terbaik = v
			if terbaik.z <= 0.0:
				continue
			lajur_dicoba += 1
			_taruh_sepeda(akar, terbaik.y, terbaik.x)
			var sepeda: Node2D = akar.find_child("Sepeda", true, false) as Node2D
			var harapan: Vector2i = UkurPenutupPiksel.layar(terbaik.x, terbaik.y)
			if absf(sepeda.position.x - float(harapan.x)) > 1.0 or absf(sepeda.position.y - float(harapan.y)) > 1.0:
				lajur_salah.append("%s: posisi sepeda %s, oracle %s" % [b.id, sepeda.position, harapan])
			var sprite_lajur: Sprite2D = dekor.sprite_dekor(k)
			if sprite_lajur == null or not is_equal_approx(sprite_lajur.modulate.a, 0.45):
				lajur_salah.append("%s: lateral %.2f maju %.4f (%d piksel opak di atas pemain): alfa %s, harap 0,45" % [b.id, terbaik.x, terbaik.y, int(terbaik.z), sprite_lajur.modulate.a if sprite_lajur != null else -1.0])
				continue
			_taruh_sepeda(akar, terbaik.y, -2.0)
			if sprite_lajur.modulate.a != 1.0:
				lajur_salah.append("%s: alfa %.2f saat pemain pindah ke tepi seberang, harap 1,0" % [b.id, sprite_lajur.modulate.a])
			_taruh_sepeda(akar, terbaik.y + 6.0, terbaik.x)
			if sprite_lajur.modulate.a != 1.0:
				lajur_salah.append("%s: alfa %.2f saat pemain 6 ubin di depannya di lateral %.2f, harap 1,0" % [b.id, sprite_lajur.modulate.a, terbaik.x])
	check(lajur_dicoba >= 9 and lajur_salah.is_empty(), "%d posisi di lajur sepeda (lateral 0,5 / 0,75 / 1,0) dengan piksel opak dekor di atas pemain: alfa objek 0,45, posisi sepeda = oracle, 1,0 di tepi seberang dan 6 ubin di depan: %s" % [lajur_dicoba, lajur_salah.slice(0, 3)])
	# Tong sampah sisi dekat (P-7): pemain di trotoar dekat (lateral 1,5 / 1,75 / 2,0) pada maju yang oracle piksel buktikan tertimpa piksel tong => alfa 0,45; pergi (maju +6 atau tepi seberang) => 1,0; sprite dilepas bersama penerap saat keluar jendela.
	var tong_salah: Array[String] = []
	var tong_dicoba: int = 0
	var tong_idx: int = -1
	for k: int in range(rute.dekor.size()):
		if rute.dekor[k].jenis == "tong_sampah" and rute.dekor[k].sisi == LoperAnim.Sisi.DEKAT:
			tong_idx = k
			break
	check(tong_idx >= 0, "rute nyata memuat tong sampah sisi dekat")
	if tong_idx >= 0:
		var tong_b: RouteBuilder.DekorItem = rute.dekor[tong_idx]
		var sapuan_tong: Dictionary = UkurPenutupPiksel.sapu_pemain(tong_b, 0.25, 1.0 / 16.0, 3.0)
		for lateral_tong: float in [1.5, 1.75, 2.0]:
			var terbaik_tong: Vector3 = Vector3(0.0, 0.0, 0.0)
			for v: Vector3 in sapuan_tong["posisi_tumpang"]:
				if is_equal_approx(v.x, lateral_tong) and v.z > terbaik_tong.z:
					terbaik_tong = v
			if terbaik_tong.z <= 0.0:
				tong_salah.append("tidak ada posisi tumpang di lateral %s" % lateral_tong)
				continue
			tong_dicoba += 1
			_taruh_sepeda(akar, terbaik_tong.y, lateral_tong)
			var sprite_tong: Sprite2D = dekor.sprite_dekor(tong_idx)
			if sprite_tong == null or not is_equal_approx(sprite_tong.modulate.a, 0.45):
				tong_salah.append("lateral %s maju %.4f (%d piksel tong di atas pemain): alfa %s, harap 0,45" % [lateral_tong, terbaik_tong.y, int(terbaik_tong.z), sprite_tong.modulate.a if sprite_tong != null else -1.0])
				continue
			_taruh_sepeda(akar, terbaik_tong.y + 6.0, lateral_tong)
			if sprite_tong.modulate.a != 1.0:
				tong_salah.append("alfa %.2f saat pemain 6 ubin di depan tong, harap 1,0" % sprite_tong.modulate.a)
			_taruh_sepeda(akar, terbaik_tong.y, -2.0)
			if sprite_tong.modulate.a != 1.0:
				tong_salah.append("alfa %.2f saat pemain di tepi seberang, harap 1,0" % sprite_tong.modulate.a)
	check(tong_dicoba == 3 and tong_salah.is_empty(), "tong sampah sisi dekat: alfa objek 0,45 di trotoar dekat pada %d posisi oracle, 1,0 sesudah pemain pergi: %s" % [tong_dicoba, tong_salah.slice(0, 3)])
	# Pohon seberang tidak pernah semi-transparan (kamera dari sisi dekat), di semua lateral lajur.
	var seberang_salah: int = 0
	var seberang_dicek: int = 0
	for k: int in range(rute.dekor.size()):
		var b: RouteBuilder.DekorItem = rute.dekor[k]
		if b.sisi != LoperAnim.Sisi.SEBERANG or b.jenis == "tong_sampah" or seberang_dicek >= 8:
			continue
		seberang_dicek += 1
		for lateral: float in [-2.0, -1.0, 0.0, 1.0, 2.0]:
			for selisih: float in [-1.0, 0.0, 0.3, 1.0]:
				_taruh_sepeda(akar, b.maju_ubin + selisih, lateral)
				var sprite: Sprite2D = dekor.sprite_dekor(k)
				if sprite != null and sprite.modulate.a != 1.0:
					seberang_salah += 1
	check(seberang_dicek >= 6 and seberang_salah == 0, "%d pohon dan lampu seberang tidak pernah semi-transparan di lateral -2,0 sampai 2,0 (%d salah)" % [seberang_dicek, seberang_salah])
	# Lepas bersama sprite: setelah digulir jauh, tidak ada sprite dekor terlihat yang tak terdaftar, sprite di kolam beralfa 1,0, dan jumlah terdaftar sama dengan yang tampil.
	_taruh_sepeda(akar, 235.5, 2.0)
	var di_kolam_salah: int = 0
	for anak: Node in dekor.get_children():
		var s: Sprite2D = anak as Sprite2D
		if s != null and not s.visible and s.modulate.a != 1.0:
			di_kolam_salah += 1
	check(di_kolam_salah == 0 and penerap.jumlah() == akar.daur().jumlah_rumah() + akar.rintangan_daur().jumlah_tampil() + _jumlah_penutup(akar) + 1 + akar.jumlah_hiasan_penerap(), "sprite dekor yang keluar jendela dilepas dari penerap dan dikembalikan ke alfa 1,0 (kolam %d salah); terdaftar = rumah + rintangan + pohon dan lampu sisi dekat tampil + portal" % di_kolam_salah)
	_bersihkan(akar)


func _test_jendela_daur_dan_tekstur() -> void:
	_judul.call("Jendela daur dekor: node tidak tumbuh saat rute digulir, tidak ada node di luar jendela, tekstur dimuat sekali, kolam dipakai ulang (AC-11)")
	var akar: RuteMain = await _siapkan()
	var rute: RouteBuilder.Rute = akar.rute()
	var dekor: DekorDaur = akar.dekor_daur()
	var nama_pakai: Dictionary = {}
	for b: RouteBuilder.DekorItem in rute.dekor:
		nama_pakai[_nama_oracle(b)] = true
	check(dekor.jumlah_tekstur() == nama_pakai.size() and nama_pakai.size() == 6 and dekor.jumlah_muat() == 6, "tekstur dekor dimuat di atur_rute sebelum digulir: %d nama (tong, tiga pohon, dua lampu), %d pemuatan" % [dekor.jumlah_tekstur(), dekor.jumlah_muat()])
	var puncak: int = 0
	var puncak_oracle: int = 0
	var salah: Array[String] = []
	var node_naik: int = 0
	var sebelumnya: int = dekor.jumlah_node()
	for jarak: int in range(0, 237):
		_taruh_sepeda(akar, float(jarak))
		var harapan: int = _indeks_jendela(rute, float(jarak)).size()
		puncak_oracle = maxi(puncak_oracle, harapan)
		puncak = maxi(puncak, dekor.jumlah_tampil())
		if dekor.jumlah_tampil() != harapan:
			salah.append("jarak %d: %d sprite, harap %d" % [jarak, dekor.jumlah_tampil(), harapan])
		if dekor.jumlah_node() > sebelumnya:
			node_naik += 1
			sebelumnya = dekor.jumlah_node()
	check(salah.is_empty(), "237 titik gulir: sprite dekor = banyaknya dekor dalam jendela daur (sapuan linear): %s" % [salah.slice(0, 3)])
	check(puncak == puncak_oracle and puncak >= 5 and puncak < rute.dekor.size() and dekor.jumlah_node() == puncak, "puncak %d sprite = puncak oracle %d (< %d dekor seluruh rute); node pernah dibuat %d = puncak: kolam dipakai ulang" % [puncak, puncak_oracle, rute.dekor.size(), dekor.jumlah_node()])
	check(dekor.jumlah_muat() == 6 and dekor.jumlah_tekstur() == 6, "PNG dekor dimuat dari disk tepat enam kali selama seluruh gulir (%d), tekstur tetap enam" % dekor.jumlah_muat())
	var terlihat: int = 0
	for anak: Node in dekor.get_children():
		if anak is Sprite2D and (anak as Sprite2D).visible:
			terlihat += 1
	check(terlihat == dekor.jumlah_tampil() and dekor.get_child_count() == dekor.jumlah_node(), "node Dekor_* terlihat (%d) = sprite terpakai (%d); jumlah anak = jumlah node dibuat" % [terlihat, dekor.jumlah_tampil()])
	# Tidak ada dekor tergambar dua kali: nama anak yang terlihat unik.
	var nama_terlihat: Dictionary = {}
	var ganda: int = 0
	for anak: Node in dekor.get_children():
		if anak is Sprite2D and (anak as Sprite2D).visible:
			if nama_terlihat.has(anak.name):
				ganda += 1
			nama_terlihat[anak.name] = true
	check(ganda == 0, "tiap dekor digambar satu kali (tanpa nama ganda di antara sprite terlihat): %d ganda" % ganda)
	# Gulir mundur dan perbarui berulang pada jarak sama: tidak menambah node.
	var node_sebelum: int = dekor.jumlah_node()
	for jarak: int in range(235, -1, -3):
		_taruh_sepeda(akar, float(jarak))
	_taruh_sepeda(akar, 100.0)
	_taruh_sepeda(akar, 100.0)
	check(dekor.jumlah_node() == node_sebelum and node_naik >= 1, "gulir mundur dan pembaruan berulang tidak menambah node (%d)" % dekor.jumlah_node())
	# Ganti rute (Main lagi): semua kembali ke kolam lalu dipasang ulang; tekstur tidak dimuat ulang.
	var muat_sebelum: int = dekor.jumlah_muat()
	dekor.atur_rute(RouteBuilder.bangun(SEED_DEV + 1, PemuatRute.muat_folder(FOLDER_RUTE).segmen).rute)
	check(dekor.jumlah_node() <= node_sebelum + 8 and dekor.jumlah_muat() == muat_sebelum, "ganti rute: sprite dipakai ulang dari kolam (%d -> %d node), PNG tidak dimuat ulang (%d)" % [node_sebelum, dekor.jumlah_node(), dekor.jumlah_muat()])
	_bersihkan(akar)


func _test_p4_scene() -> void:
	_judul.call("P-4 scene rute: rumah dekat tidak lagi pudar saat pemain di trotoar atau jalur dekat; kotak penutup terdaftar = tapak gambar (B1-F2)")
	var akar: RuteMain = await _siapkan()
	var rute: RouteBuilder.Rute = akar.rute()
	var daur: RumahDaurRute = akar.daur()
	var salah: Array[String] = []
	var rumah_diperiksa: int = 0
	var pudar_dekat: int = 0
	for lateral: float in [-2.0, -1.0, 0.0, 1.0, 1.75, 2.0]:
		for jarak: int in range(0, 237, 3):
			_taruh_sepeda(akar, float(jarak), lateral)
			for i: int in daur.indeks_tampil():
				var s: Sprite2D = daur.sprite_rumah(i)
				rumah_diperiksa += 1
				if s.modulate.a != 1.0:
					pudar_dekat += 1
					if salah.size() < 3:
						salah.append("%s lateral %.2f jarak %d: alfa %.2f" % [rute.rumah[i].id, lateral, jarak, s.modulate.a])
	check(rumah_diperiksa > 5000 and pudar_dekat == 0, "%d pengamatan rumah (6 lateral x 80 jarak): tidak ada rumah dekat atau seberang yang pudar saat pemain tidak tertutup (%d pudar): %s" % [rumah_diperiksa, pudar_dekat, salah])
	# Pendaftaran: kotak penutup yang terdaftar untuk rumah dekat = tapak gambar. Diuji lewat perilaku, pemain di maju dan lateral yang
	# menutupi bila kotak tidak digeser (lateral 1,75, 1 ubin di depan awal kavling: garis pandang masuk tapak lama lateral 3,0 pada d = 1,25, tinggi 1,25 <= 2,0).
	var indeks_dekat: int = -1
	for i: int in range(rute.rumah.size()):
		if rute.rumah[i].sisi == LoperAnim.Sisi.DEKAT and rute.rumah[i].maju_ubin > 40.0:
			indeks_dekat = i
			break
	var dekat: RouteBuilder.RumahRute = rute.rumah[indeks_dekat]
	_taruh_sepeda(akar, dekat.maju_ubin + 3.0, 1.75)
	var sprite: Sprite2D = daur.sprite_rumah(indeks_dekat)
	check(sprite != null and sprite.modulate.a == 1.0, "pemain di trotoar dekat (lateral 1,75) satu kavling di depan rumah dekat: sprite rumah dekat alfa 1,0 (dulu 0,45, B1-F2)")
	# Letak gambar rumah dekat sesuai tapak: kotak penutup (tapak gambar) mencakup titik pijak gambar (pusat tapak + geser).
	var pusat: Vector2 = SpriteRumah.pusat_gambar_dunia(dekat)
	var tapak: Rect2 = PenutupPemain.dari_rumah_gambar(dekat).tapak
	# Run 5D: kotak sprite nyata tidak simetris (toren dan jemuran di belakang), jadi hanya dicek memuat titik pijak gambar.
	check(tapak.has_point(Vector2(pusat.x, -pusat.y)), "pusat gambar rumah dekat (%s) ada di dalam kotak penutup gambar (%s)" % [pusat, tapak])
	_bersihkan(akar)


# --- Pembantu ---

func _indeks_jendela(rute: RouteBuilder.Rute, jarak: float) -> Array[int]:
	var hasil: Array[int] = []
	for i: int in range(rute.dekor.size()):
		if rute.dekor[i].maju_ubin >= jarak - DAUR_MUNDUR and rute.dekor[i].maju_ubin <= jarak + DAUR_MAJU:
			hasil.append(i)
	return hasil


func _jumlah_penutup(akar: RuteMain) -> int:
	var jumlah: int = 0
	for i: int in akar.dekor_daur().indeks_tampil():
		var butir: RouteBuilder.DekorItem = akar.rute().dekor[i]
		if DekorRute.menutupi(butir.jenis, butir.varian, butir.sisi):
			jumlah += 1
	return jumlah


## Nama sprite oracle dari jenis, varian, sisi (ditulis ulang).
func _nama_oracle(b: RouteBuilder.DekorItem) -> String:
	if b.jenis == "tong_sampah":
		return "prop_tong_sampah_logam"
	if b.jenis == "pohon":
		return "prop_pohon_" + b.varian
	return "prop_lampu_lengan_seberang" if b.sisi == LoperAnim.Sisi.SEBERANG else "prop_lampu_lengan_dekat"


func _pijak_oracle(nama: String) -> Vector2:
	for baris: Array in SPRITE_ORACLE:
		if baris[0] == nama:
			return Vector2(baris[3], baris[4])
	return Vector2(-1, -1)


## Posisi gambar (piksel game) titik dunia (lateral, maju) di tanah: proyeksi iso 2:1 ditulis ulang, dibulatkan.
func _layar(lateral: float, maju: float) -> Vector2:
	return Vector2(roundf((lateral + maju) * 32.0), roundf((lateral - maju) * 16.0))


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
