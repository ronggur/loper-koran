class_name TesSimpang
extends RefCounted
## Tes simpang T hiasan run 20261022-fase5c-animasi-simpang bagian D (AC-15 sampai AC-20; P-1, D-2, D-3, D-4).
##
## Harapan ditulis sebagai literal atau dihitung dengan cara lain dari kode produksi:
## - Config = JSON ubin terpasang (`tile_perumahan.json`, keluaran renderer), tabel sel ditulis ulang literal di sini (`SEL_DEKAT`).
## - Validasi: segmen sintetis dengan satu unsur tiap kasus, batas dihitung tangan di komentar (pita = pos - 1,5 sampai pos + 3,5; kavling rumah dekat = pos - 0,5 sampai pos + 3).
## - Rute identik: sidik FNV-1a uraian 60 seed (rumah, rintangan, pelanggan, titik misi, dekor, tenggat, skor) dihitung di commit 7f30557 SEBELUM simpang
##   (`dev_ukur/golden_rute_cd.gd`), ditulis literal di `GOLDEN_RUTE`.
## - Simpang rute: dibaca ulang dari berkas JSON segmen (FileAccess + JSON), bukan dari `SegmenRute`.
## - Ubin: nama harapan per sel dari tabel literal dan aturan kolom yang ditulis ulang (tanpa `UbinKhusus`); referensi piksel `tests/data/ubin_potongan_simpang.png`
##   dibuat `tools/tests_cek/uji_aset_simpang.py` dari berkas assets/ dan dicocokkan dengan adegan renderer di sana.

const BERKAS_RUTE: String = "res://scenes/rute/rute.tscn"
const FOLDER_RUTE: String = "res://assets/data/routes/perumahan"
const FOLDER_UBIN: String = "res://assets/sprites/tiles/perumahan/"
const JSON_UBIN: String = "res://assets/sprites/tiles/perumahan/tile_perumahan.json"
const REFERENSI: String = "res://tests/data/ubin_potongan_simpang.png"
const SEED_DEV: int = 20261016
const DT: float = 1.0 / 60.0
const TINGGI: int = 360
## Sidik uraian rute untuk seed 20261016 + 7 i (i = 0 sampai 59), dihitung di commit 7f30557 sebelum simpang ada, lalu dihitung ulang oleh `dev_ukur/banding_p6.gd` sesudah
## putusan P-6 (rumah seberang per_buka_02@18 dihapus: 31 seed berubah, satu-satunya beda baris rumah itu).
## Run 5D bagian B (AC-8, D-5): sidik DIHITUNG ULANG oleh skrip dari kode sesudah rumah dekat diberi pelanggan_boleh (34 dari 36 rumah dekat; baris R memuat bidang itu). Bukti per golden: dengan bidang pelanggan_boleh rumah DEKAT
## ditopeng false, sidik 60 seed sama persis dengan nilai sebelumnya (kontrol skrip), jadi satu-satunya beda adalah bidang itu; segmen, rumah, pelanggan, pemberi tip, rintangan, titik misi, dekor, tenggat, dan skor tidak berubah (LOG bagian B).
const GOLDEN_RUTE: Array[int] = [
	2614467885, 3241797744, 2434425869, 3878201912, 3217942099, 391584822, 820247053, 3438045503, 3163392706, 1134662680, 800917477, 4258250417, 360345169, 1460738201, 3343387745,
	3811976869, 453007822, 1445334839, 3457038886, 2925418863, 60454254, 535801372, 3889666564, 418649014, 2085920083, 2906281888, 3845165657, 2515259187, 4151768372, 804381226,
	3712372092, 3178186789, 2740143045, 3909798694, 2337926557, 1983168024, 2576523640, 387028903, 2833756705, 3022333875, 3001077485, 3169906017, 953943311, 741922815, 765758355,
	797797083, 3704170539, 1780195771, 3384794713, 196601923, 188766368, 467158931, 3461823506, 1935675447, 4025655775, 3898731002, 266873755, 280737375, 1005748027, 3392308696,
]
## Tabel sel simpang sisi dekat (baris relatif maju dari pos, kolom 0 aspal 1 trotoar 2 rumput pertama 3 lengan), ditulis literal dari ekspor renderer.
const SEL_DEKAT: Array = [[3, 1], [3, 2], [3, 3], [2, 0], [2, 1], [2, 2], [2, 3], [1, 0], [1, 1], [1, 2], [1, 3], [0, 0], [0, 1], [0, 2], [0, 3], [-1, 1], [-1, 2], [-1, 3]]
const SEL_SEBERANG: Array = [[3, 2], [3, 3], [2, 1], [2, 2], [2, 3], [1, 0], [1, 1], [1, 2], [1, 3], [0, 0], [0, 1], [0, 2], [0, 3], [-1, 1], [-1, 2], [-1, 3]]
const NAMA_BARIS: Dictionary = {3: "depan_2", 2: "depan_1", 1: "mulut_1", 0: "mulut_2", -1: "belakang_1"}
const NAMA_KOLOM_DEKAT: Array[String] = ["aspal_dekat", "trotoar_dekat", "rumput_dekat", "lengan"]
const NAMA_KOLOM_SEBERANG: Array[String] = ["aspal_seberang", "trotoar_seberang", "rumput_seberang", "lengan"]
## Simpang di data segmen (dihitung dari berkas dengan skrip lain, ditulis literal): [berkas, pos, sisi].
## Putusan P-6 run 5C: simpang seberang di per_buka_02 pos 18 (rumah seberang di pos itu dihapus).
const SIMPANG_DATA: Array = [["per_buka_01", 3, "dekat"], ["per_buka_02", 18, "seberang"], ["per_tengah_05", 3, "dekat"], ["per_tutup_01", 2, "dekat"]]
const REFERENSI_SEBERANG: String = "res://tests/data/ubin_potongan_simpang_seberang.png"

var _cek: Callable
var _judul: Callable
var _tree: SceneTree
var _gambar: Dictionary = {}


func _init(cek: Callable, judul: Callable, tree: SceneTree) -> void:
	_cek = cek
	_judul = judul
	_tree = tree


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_test_ujung_kerb_literal()
	_test_config_json()
	_test_parse_sah_dan_lama()
	_test_parse_negatif()
	_test_pita_batas()
	_test_zona_di_dalam_kavling()
	_test_rute_simpang_dan_fungsi_baca()
	_test_rute_identik_golden()
	_test_tanpa_rng()
	_test_periksa_rute_sambungan()
	_test_konten_dan_persen()
	_test_kucing_600_hari()
	_test_sel_simpang_literal()
	_test_tanah_pasang()
	_test_susunan_referensi()
	_test_susunan_referensi_seberang()
	_test_tanpa_celah()
	_test_medan_identik()
	await _test_scene()
	await _test_scene_gerak_identik()


# --- Pembantu ---

func _nama_sel(rel: int, kolom: int, sisi: LoperAnim.Sisi = LoperAnim.Sisi.DEKAT) -> String:
	if sisi == LoperAnim.Sisi.SEBERANG:
		return "simpang_seberang_%s_%s" % [NAMA_KOLOM_SEBERANG[kolom], NAMA_BARIS[rel]]
	return "simpang_dekat_%s_%s" % [NAMA_KOLOM_DEKAT[kolom], NAMA_BARIS[rel]]


func _indeks_sel(tabel: Array, rel: int, kolom: int) -> int:
	for i: int in range(tabel.size()):
		var p: Array = tabel[i]
		if p[0] == rel and p[1] == kolom:
			return i
	return -1


func _baca_json(jalur: String) -> Dictionary:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(jalur))
	return data as Dictionary if typeof(data) == TYPE_DICTIONARY else {}


## Segmen sintetis kosong panjang 30 (perumahan, tengah, tenang); `tambah` digabungkan.
func _segmen(tambah: Dictionary) -> Dictionary:
	var d: Dictionary = {
		"id": "uji_simpang", "distrik": "perumahan", "panjang": 30,
		"tag": {"tingkat": "tenang", "sisi_pelanggan": "seberang", "posisi": "tengah"},
		"rumah": [], "objek": [], "titik_misi": [],
	}
	for k: String in tambah:
		d[k] = tambah[k]
	return d


func _galat(tambah: Dictionary) -> Array[String]:
	return SegmenRute.parse(_segmen(tambah)).galat


func _ada_galat(tambah: Dictionary, kata: String) -> bool:
	for g: String in _galat(tambah):
		if g.contains(kata):
			return true
	return false


func _tekstur(nama: String) -> Texture2D:
	return load(FOLDER_UBIN + "tile_perumahan_%s.png" % nama) as Texture2D


## TanahDaur lengkap seperti rute.tscn: enam kolom, rumput polos, enam khusus 5B, dua ujung kerb, 18 ubin simpang dekat dan 16 seberang (urut tabel literal).
func _buat_tanah(simpang: bool = true) -> TanahDaur:
	var tanah: TanahDaur = TanahDaur.new()
	tanah.tekstur_kolom_rumput_seberang = _tekstur("rumput_seberang")
	tanah.tekstur_kolom_trotoar_seberang = _tekstur("trotoar_seberang")
	tanah.tekstur_kolom_aspal_seberang = _tekstur("aspal_seberang")
	tanah.tekstur_kolom_aspal_dekat = _tekstur("aspal_dekat")
	tanah.tekstur_kolom_trotoar_dekat = _tekstur("trotoar_dekat")
	tanah.tekstur_kolom_rumput_dekat = _tekstur("rumput_dekat")
	tanah.tekstur_rumput_luar = _tekstur("rumput_1")
	tanah.tekstur_rumput_luar_2 = _tekstur("rumput_2")
	tanah.tekstur_rumput_luar_3 = _tekstur("rumput_3")
	tanah.tekstur_masuk_trotoar_seberang = _tekstur("trotoar_seberang_masuk")
	tanah.tekstur_masuk_rumput_seberang = _tekstur("rumput_seberang_masuk")
	tanah.tekstur_simbol_trotoar_seberang = _tekstur("trotoar_seberang_simbol")
	tanah.tekstur_simbol_trotoar_dekat = _tekstur("trotoar_dekat_simbol")
	tanah.tekstur_ujung_trotoar_seberang = _tekstur("trotoar_seberang_masuk_ujung")
	tanah.tekstur_ujung_rumput_seberang = _tekstur("rumput_seberang_masuk_ujung")
	if simpang:
		var daftar: Array[Texture2D] = []
		for p: Array in SEL_DEKAT:
			daftar.append(_tekstur(_nama_sel(p[0] as int, p[1] as int)))
		tanah.tekstur_simpang_dekat = daftar
		var seb: Array[Texture2D] = []
		for p: Array in SEL_SEBERANG:
			seb.append(_tekstur(_nama_sel(p[0] as int, p[1] as int, LoperAnim.Sisi.SEBERANG)))
		tanah.tekstur_simpang_seberang = seb
	return tanah


func _sprite_ubin(tanah: TanahDaur) -> Array[Sprite2D]:
	var hasil: Array[Sprite2D] = []
	for wadah: Node in tanah.get_children():
		for anak: Node in wadah.get_children():
			hasil.append(anak as Sprite2D)
	return hasil


## Posisi dunia (ubin) pusat ubin dari posisi layar relatif blok (rumus proyeksi 2:1 ditulis ulang, bukan `Iso`).
func _dunia_dari_layar(layar: Vector2) -> Vector2:
	return Vector2((layar.y / 16.0 + layar.x / 32.0) / 2.0, (layar.y / 16.0 - layar.x / 32.0) / 2.0)


func _nama_tekstur(u: Sprite2D) -> String:
	return u.texture.resource_path.get_file().trim_prefix("tile_perumahan_").trim_suffix(".png")


func _gambar_tekstur(tekstur: Texture2D) -> Image:
	var kunci: String = tekstur.resource_path
	if not _gambar.has(kunci):
		var g: Image = tekstur.get_image()
		g.convert(Image.FORMAT_RGBA8)
		_gambar[kunci] = g
	return _gambar[kunci] as Image


func _simpang_item(maju: float, sisi: LoperAnim.Sisi) -> RouteBuilder.SimpangItem:
	var s: RouteBuilder.SimpangItem = RouteBuilder.SimpangItem.new()
	s.maju_ubin = maju
	s.sisi = sisi
	s.id = "uji:%s" % maju
	return s


func _pustaka() -> Array[SegmenRute]:
	return PemuatRute.muat_folder(FOLDER_RUTE).segmen


# --- AC-13: ujung kerb jalan masuk (bagian C) ---

func _test_ujung_kerb_literal() -> void:
	_judul.call("UbinKhusus: ujung kerb hanya di baris maju + 1 jalan masuk sisi seberang, dua kolom (AC-13, C-F1, oracle tabel)")
	var U: UbinKhusus.Ubin = UbinKhusus.Ubin.UJUNG
	var B: UbinKhusus.Ubin = UbinKhusus.Ubin.BAWAAN
	var masuk: Dictionary = {17: true}
	# [x, baris, himpunan masuk, dengan_ujung, harapan]; baris 18 juga baris simbol (6 + 12).
	var tabel: Array = [
		[-1.5, 18, masuk, true, U], [-2.5, 18, masuk, true, U], [-0.5, 18, masuk, true, B], [1.5, 18, masuk, true, UbinKhusus.Ubin.SIMBOL], [2.5, 18, masuk, true, B],
		[-1.5, 17, masuk, true, UbinKhusus.Ubin.MASUK], [-1.5, 16, masuk, true, B], [-2.5, 16, masuk, true, B], [-1.5, 19, masuk, true, B],
		[-1.5, 18, {17: true, 18: true}, true, UbinKhusus.Ubin.MASUK], [-1.5, 19, {17: true, 18: true}, true, U],
		[-1.5, 18, masuk, false, UbinKhusus.Ubin.SIMBOL], [-2.5, 18, masuk, false, B], [-1.5, 54, {53: true}, true, U], [-1.5, 54, {53: true}, false, UbinKhusus.Ubin.SIMBOL],
	]
	for t: Array in tabel:
		var dapat: UbinKhusus.Ubin = UbinKhusus.jenis(t[0] as float, t[1] as int, t[2] as Dictionary, t[3] as bool)
		check(dapat == t[4], "jenis(x %s, baris %s, masuk %s, ujung %s) = %s (dapat %s)" % [t[0], t[1], (t[2] as Dictionary).keys(), t[3], UbinKhusus.Ubin.keys()[t[4] as int], UbinKhusus.Ubin.keys()[dapat as int]])
	var kolom_luar: bool = UbinKhusus.jenis(-3.5, 18, masuk) == UbinKhusus.varian_rumput(-4, 18)
	check(kolom_luar, "kolom rumput luar di baris ujung tetap variasi rumput (bukan ujung)")
	var dekat: Array[RouteBuilder.ObjekRute] = []
	var o: RouteBuilder.ObjekRute = RouteBuilder.ObjekRute.new()
	o.jenis = "mobil_garasi"
	o.jalur = "dekat"
	o.maju_ubin = 17.0
	dekat.append(o)
	check(UbinKhusus.jenis(-1.5, 18, UbinKhusus.himpunan_baris_masuk(dekat)) == UbinKhusus.Ubin.SIMBOL, "mobil sisi dekat tidak membuat ujung kerb")
	var tanah: TanahDaur = _buat_tanah(false)
	tanah.bangun(Config.LAYAR_LEBAR_MAKS_PX, TINGGI)
	tanah.atur_baris_masuk({5: true})
	tanah.perbarui(0.0)
	var ujung: Dictionary = {}
	for u: Sprite2D in _sprite_ubin(tanah):
		if _nama_tekstur(u).ends_with("_ujung"):
			var d: Vector2 = _dunia_dari_layar(u.position)
			ujung["%s@%d" % [d.x, int(round(-d.y))]] = _nama_tekstur(u)
	check(ujung == {"-1.5@6": "trotoar_seberang_masuk_ujung", "-2.5@6": "rumput_seberang_masuk_ujung"}, "TanahDaur: jalan masuk baris 5 = tepat dua ubin ujung di baris 6 kolom -1,5 dan -2,5: %s" % [ujung])
	tanah.free()


# --- D-3: config = JSON renderer ---

func _test_config_json() -> void:
	_judul.call("Simpang: konstanta config = JSON ubin terpasang dan tabel literal (D-3, AC-18)")
	var meta: Dictionary = _baca_json(JSON_UBIN)
	var sp: Dictionary = meta.get("simpang", {})
	check(not sp.is_empty(), "tile_perumahan.json memuat bagian simpang")
	if sp.is_empty():
		return
	check(Config.RUTE_SIMPANG_LEBAR_MULUT_UBIN == float(sp["lebar_mulut_ubin"]) and Config.RUTE_SIMPANG_LEBAR_MULUT_UBIN == 2.0, "lebar mulut 2 ubin = JSON")
	var y_mulut: Array = sp["y_mulut_unit"]
	check(Config.RUTE_SIMPANG_MULUT_AWAL_UBIN == -float(y_mulut[1]) / 32.0 and Config.RUTE_SIMPANG_MULUT_AWAL_UBIN == -0.5, "tepi mulut = -y_mulut[1] / 32 = -0,5")
	check(Config.RUTE_SIMPANG_LEBAR_MULUT_UBIN == (float(y_mulut[1]) - float(y_mulut[0])) / 32.0, "lebar mulut = selisih y mulut renderer / 32")
	var pita: Array = sp["pita_baris_relatif"]
	check(Config.RUTE_SIMPANG_PITA_BARIS == [-1, 3] and int(pita[0]) == -1 and int(pita[1]) == 3, "pita baris [-1, 3] = JSON")
	check(Config.RUTE_UJUNG_KERB_BARIS_RELATIF == int(meta["ujung_kerb_baris_relatif"]) and Config.RUTE_UJUNG_KERB_BARIS_RELATIF == 1, "baris ujung kerb relatif 1 = JSON")
	var kolom: Dictionary = {"aspal": 0, "trotoar": 1, "rumput": 2, "lengan": 3}
	var dari_json: Array = []
	var nama_json: Array[String] = []
	for d: Dictionary in sp["sisi"]["dekat"]:
		dari_json.append([int(d["baris_relatif"]), int(kolom[d["kolom"]])])
		nama_json.append(String(d["nama"]))
	var dari_config: Array = []
	for i: int in range(Config.RUTE_SIMPANG_SEL_DEKAT.size() / 2):
		dari_config.append([Config.RUTE_SIMPANG_SEL_DEKAT[2 * i], Config.RUTE_SIMPANG_SEL_DEKAT[2 * i + 1]])
	check(dari_json == SEL_DEKAT and dari_config == SEL_DEKAT, "tabel sel dekat: config = JSON = literal (18 sel)")
	var nama_harap: Array[String] = []
	for p: Array in SEL_DEKAT:
		nama_harap.append(_nama_sel(p[0] as int, p[1] as int))
	check(nama_json == nama_harap, "nama ubin simpang dekat di JSON sejajar tabel")
	var seb: Array = []
	for i: int in range(Config.RUTE_SIMPANG_SEL_SEBERANG.size() / 2):
		seb.append([Config.RUTE_SIMPANG_SEL_SEBERANG[2 * i], Config.RUTE_SIMPANG_SEL_SEBERANG[2 * i + 1]])
	var seb_json: Array = []
	var seb_nama: Array[String] = []
	for d: Dictionary in sp["sisi"].get("seberang", []):
		seb_json.append([int(d["baris_relatif"]), int(kolom[d["kolom"]])])
		seb_nama.append(String(d["nama"]))
	var seb_harap: Array[String] = []
	for p: Array in SEL_SEBERANG:
		seb_harap.append(_nama_sel(p[0] as int, p[1] as int, LoperAnim.Sisi.SEBERANG))
	check(seb == SEL_SEBERANG and seb_json == SEL_SEBERANG and seb_nama == seb_harap, "tabel sel seberang: config = JSON terpasang (P-6) = literal (16 sel), nama sejajar")


# --- AC-15: data dan validasi ---

func _test_parse_sah_dan_lama() -> void:
	_judul.call("Simpang: berkas nyata sah, berkas tanpa simpang tetap sah (AC-15)")
	var k: PemuatRute.Kumpulan = PemuatRute.muat_folder(FOLDER_RUTE)
	check(k.galat.is_empty() and k.segmen.size() == 9, "sembilan segmen termasuk tiga bersimpang lolos validasi: %s" % [k.galat])
	var tanpa: int = 0
	for s: SegmenRute in k.segmen:
		if s.simpang.is_empty():
			tanpa += 1
	check(tanpa == 5, "lima berkas tanpa bidang simpang tetap sah (P-6: per_buka_02 kini bersimpang)")
	check(SegmenRute.parse(_segmen({})).sah(), "segmen sintetis tanpa simpang sah")
	var h: SegmenRute.Hasil = SegmenRute.parse(_segmen({"simpang": [{"pos": 5, "sisi": "dekat"}, {"pos": 15, "sisi": "seberang"}]}))
	check(h.sah() and h.segmen.simpang.size() == 2 and h.segmen.simpang[0].pos == 5 and h.segmen.simpang[0].sisi == LoperAnim.Sisi.DEKAT and h.segmen.simpang[1].sisi == LoperAnim.Sisi.SEBERANG, "dua simpang sah di segmen kosong: pos dan sisi terbaca")
	check(SegmenRute.parse(_segmen({"simpang": []})).sah(), "daftar simpang kosong sah")
	check(SegmenRute.parse(_segmen({"simpang": [{"pos": 5.0, "sisi": "dekat"}]})).sah(), "pos 5,0 (angka JSON) dihitung bilangan bulat")


func _test_parse_negatif() -> void:
	_judul.call("Simpang: tiap penolakan validasi, satu per satu (AC-15)")
	var dekat: Dictionary = {"pos": 10, "sisi": "dekat"}
	check(_ada_galat({"simpang": "x"}, "'simpang' harus daftar"), "simpang bukan daftar ditolak")
	check(_ada_galat({"simpang": [3]}, "harus objek"), "butir bukan objek ditolak")
	check(_ada_galat({"simpang": [{"pos": 10, "sisi": "kiri"}]}, "bukan seberang atau dekat"), "sisi 'kiri' ditolak")
	check(_ada_galat({"simpang": [{"pos": 10, "sisi": "tengah"}]}, "bukan seberang atau dekat"), "sisi 'tengah' ditolak")
	check(_ada_galat({"simpang": [{"pos": 10, "sisi": "dekat", "lebar": 2}]}, "field 'lebar' tidak dikenal"), "field asing ditolak")
	check(_ada_galat({"simpang": [{"sisi": "dekat"}]}, "field wajib 'pos'"), "pos hilang ditolak")
	check(_ada_galat({"simpang": [{"pos": 10}]}, "field wajib 'sisi'"), "sisi hilang ditolak")
	check(_ada_galat({"simpang": [{"pos": 10.5, "sisi": "dekat"}]}, "bilangan bulat"), "pos 10,5 ditolak")
	check(_ada_galat({"simpang": [{"pos": "10", "sisi": "dekat"}]}, "bilangan bulat"), "pos teks ditolak")
	check(_galat({"simpang": [dekat]}).is_empty(), "kontrol: simpang dekat di pos 10 segmen kosong sah")
	# Rumah dekat di pos 14: kavling 13,5 .. 16,5 (tapak; tembok dilepas run 5D, P-1); pita pos 10 = 8,5 .. 13,5 menyentuh saja.
	var rumah_dekat_14: Dictionary = {"pos": 14, "sisi": "dekat", "jenis": "dekat_limasan", "pelanggan_boleh": false}
	check(_galat({"rumah": [rumah_dekat_14], "simpang": [dekat]}).is_empty(), "rumah dekat pos 14, simpang dekat pos 10 (pita berakhir 13,5 = awal kavling): sah, tepi bersentuhan")
	check(_ada_galat({"rumah": [rumah_dekat_14], "simpang": [{"pos": 11, "sisi": "dekat"}]}, "kavling rumah dekat"), "simpang dekat pos 11 (pita 9,5 .. 14,5) memotong kavling rumah dekat pos 14")
	# Run 5D (P-1, tembok dilepas): rumah dekat pos 4 = kavling 3,5 .. 6,5 (tapak logika; kotak gambar 3,59 .. 6,41 di dalamnya). Dulu tembok 4 .. 7 membuat pos 8 ditolak.
	var rumah_dekat_4: Dictionary = {"pos": 4, "sisi": "dekat", "jenis": "dekat_limasan", "pelanggan_boleh": false}
	check(_galat({"rumah": [rumah_dekat_4], "simpang": [{"pos": 8, "sisi": "dekat"}]}).is_empty(), "simpang dekat pos 8 (pita 6,5 ..) hanya bersentuhan dengan kavling rumah dekat pos 4 (berakhir 6,5): sah sesudah tembok dilepas")
	check(_ada_galat({"rumah": [rumah_dekat_4], "simpang": [{"pos": 7, "sisi": "dekat"}]}, "kavling rumah dekat"), "simpang dekat pos 7 (pita 5,5 ..) memotong kavling rumah dekat pos 4")
	var rumah_seb_10: Dictionary = {"pos": 10, "sisi": "seberang", "jenis": "limasan", "pelanggan_boleh": true}
	check(_galat({"rumah": [rumah_seb_10], "simpang": [dekat]}).is_empty(), "rumah seberang di maju yang sama dengan simpang DEKAT: sah (sisi lain)")
	check(_ada_galat({"rumah": [rumah_seb_10], "simpang": [{"pos": 10, "sisi": "seberang"}]}, "kavling rumah seberang"), "rumah seberang di pita simpang seberang ditolak")
	# Dekor dekat pohon pos 14: tapak 13,75 .. 14,25; pita pos 10 sampai 13,5 aman; pohon pos 13 (12,75 ..) ditolak.
	check(_galat({"dekor": [{"jenis": "pohon", "pos": 14, "sisi": "dekat", "varian": "rindang"}], "simpang": [dekat]}).is_empty(), "pohon dekat pos 14 di luar pita: sah")
	check(_ada_galat({"dekor": [{"jenis": "pohon", "pos": 13, "sisi": "dekat", "varian": "rindang"}], "simpang": [dekat]}, "memotong dekor pohon"), "pohon dekat pos 13 di pita ditolak")
	check(_galat({"dekor": [{"jenis": "pohon", "pos": 12, "sisi": "seberang", "varian": "rindang"}], "simpang": [dekat]}).is_empty(), "pohon seberang di pita simpang dekat: sah (sisi lain)")
	# Rintangan: anjing dekat pos 12 (kotak 11,75 .. 12,25) di pita; anjing seberang di maju yang sama tidak.
	check(_ada_galat({"objek": [{"jenis": "anjing_penjaga", "pos": 12, "jalur": "dekat", "tanda_ubin": 9}], "simpang": [dekat]}, "memotong anjing_penjaga"), "anjing dekat di pita ditolak")
	check(_galat({"objek": [{"jenis": "anjing_penjaga", "pos": 12, "jalur": "seberang", "tanda_ubin": 9}], "simpang": [dekat]}).is_empty(), "anjing seberang di pita simpang dekat: sah")
	check(_ada_galat({"objek": [{"jenis": "mobil_garasi", "pos": 12, "jalur": "seberang", "tanda_ubin": 9}], "simpang": [{"pos": 10, "sisi": "seberang"}]}, "memotong mobil_garasi"), "lintasan mobil seberang di pita simpang seberang ditolak")
	# Jalan masuk: mobil seberang pos 10 (lintasan 9,625 .. 10,375), baris masuk 10 dan ujung 11 = 9,5 .. 11,5; simpang seberang pos 12 = pita 10,5 .. 15,5 hanya memotong baris ujung.
	var hasil_masuk: Array[String] = _galat({"objek": [{"jenis": "mobil_garasi", "pos": 10, "jalur": "seberang", "tanda_ubin": 9}], "simpang": [{"pos": 12, "sisi": "seberang"}]})
	var masuk_saja: bool = hasil_masuk.size() == 1 and hasil_masuk[0].contains("jalan masuk garasi")
	check(masuk_saja, "simpang seberang pos 12 hanya memotong baris jalan masuk + ujung kerb mobil pos 10 (bukan lintasannya): %s" % [hasil_masuk])
	check(_galat({"objek": [{"jenis": "mobil_garasi", "pos": 10, "jalur": "seberang", "tanda_ubin": 9}], "simpang": [{"pos": 13, "sisi": "seberang"}]}).is_empty(), "simpang seberang pos 13 (pita 11,5 ..) sesudah baris ujung kerb: sah")
	# Dua simpang: pos 5 (3,5 .. 8,5) dan 10 (8,5 .. 13,5) bersentuhan = sah; 5 dan 9 bertumpuk, juga beda sisi.
	check(_galat({"simpang": [{"pos": 5, "sisi": "dekat"}, {"pos": 10, "sisi": "dekat"}]}).is_empty(), "dua simpang berpita bersentuhan (pos 5 dan 10): sah")
	check(_ada_galat({"simpang": [{"pos": 5, "sisi": "dekat"}, {"pos": 9, "sisi": "seberang"}]}, "bertumpuk dengan pita simpang"), "dua simpang berpita bertumpuk (pos 5 dekat, 9 seberang) ditolak")


func _test_pita_batas() -> void:
	_judul.call("Simpang: pita di dalam segmen, rumus pita literal (AC-15, D-3)")
	check(SegmenRute.pita_maju(10.0) == Vector2(8.5, 13.5) and SegmenRute.pita_maju(0.0) == Vector2(-1.5, 3.5), "pita pos 10 = 8,5 .. 13,5; pos 0 = -1,5 .. 3,5")
	check(_ada_galat({"simpang": [{"pos": 1, "sisi": "dekat"}]}, "di luar segmen"), "pos 1 (pita mulai -0,5) ditolak")
	check(_galat({"simpang": [{"pos": 2, "sisi": "dekat"}]}).is_empty(), "pos 2 (pita mulai 0,5) sah")
	check(_galat({"simpang": [{"pos": 26, "sisi": "dekat"}]}).is_empty(), "pos 26 di panjang 30 (pita sampai 29,5) sah")
	check(_ada_galat({"simpang": [{"pos": 27, "sisi": "dekat"}]}, "di luar segmen"), "pos 27 di panjang 30 (pita sampai 30,5) ditolak")
	check(SegmenRute.memotong_pita(Vector2(8.5, 13.5), LoperAnim.Sisi.DEKAT, Rect2(2.0, 13.5, 1.0, 1.0)) == false and SegmenRute.memotong_pita(Vector2(8.5, 13.5), LoperAnim.Sisi.DEKAT, Rect2(2.0, 13.4, 1.0, 1.0)), "tepi bersentuhan tidak memotong, masuk 0,1 memotong")
	check(not SegmenRute.memotong_pita(Vector2(8.5, 13.5), LoperAnim.Sisi.DEKAT, Rect2(-3.0, 10.0, 3.0, 1.0)) and SegmenRute.memotong_pita(Vector2(8.5, 13.5), LoperAnim.Sisi.SEBERANG, Rect2(-3.0, 10.0, 3.0, 1.0)), "bentuk di lateral -3 .. 0 hanya memotong pita seberang")
	check(not SegmenRute.pita_bertumpuk(Vector2(3.5, 8.5), Vector2(8.5, 13.5)) and SegmenRute.pita_bertumpuk(Vector2(3.5, 8.5), Vector2(8.4, 13.4)), "pita bersentuhan tidak bertumpuk")


## Zona rumah selalu di dalam rentang maju kavling (jadi cabang validasi zona hanya pengaman; dicatat di LOG sebagai mutan ekuivalen).
func _test_zona_di_dalam_kavling() -> void:
	_judul.call("Simpang: zona rumah di dalam rentang maju kavling kedua sisi (AC-15)")
	for sisi: LoperAnim.Sisi in [LoperAnim.Sisi.SEBERANG, LoperAnim.Sisi.DEKAT]:
		var r: RouteBuilder.RumahRute = RouteBuilder.RumahRute.new()
		r.sisi = sisi
		r.maju_ubin = 10.0
		var kav: Rect2 = SegmenRute.kavling_rumah(sisi, 10.0)
		var di_dalam: bool = true
		for z: ZonaSasaran.Zona in ZonaSasaran.zona_rumah(r):
			if z.persegi.position.y < kav.position.y or z.persegi.end.y > kav.end.y:
				di_dalam = false
		check(di_dalam, "zona rumah %s di dalam rentang maju kavling %s" % [sisi, kav])
	check(SegmenRute.kavling_rumah(LoperAnim.Sisi.DEKAT, 10.0).position.y == 9.5 and SegmenRute.kavling_rumah(LoperAnim.Sisi.DEKAT, 10.0).end.y == 12.5, "kavling dekat pos 10 = maju 9,5 .. 12,5 (tembok dilepas run 5D; dulu sampai 13)")
	check(SegmenRute.kavling_rumah(LoperAnim.Sisi.SEBERANG, 10.0).position.y == 9.5 and SegmenRute.kavling_rumah(LoperAnim.Sisi.SEBERANG, 10.0).end.y == 12.5, "kavling seberang pos 10 = maju 9,5 .. 12,5")


# --- AC-16: rute ---

func _test_rute_simpang_dan_fungsi_baca() -> void:
	_judul.call("RouteBuilder: simpang diteruskan dari data (maju mutlak, sisi, lebar mulut, id) lewat simpang_di (AC-16)")
	var data: Dictionary = {}
	for nama: String in DirAccess.get_files_at(FOLDER_RUTE):
		if nama.ends_with(".json"):
			var d: Dictionary = _baca_json(FOLDER_RUTE + "/" + nama)
			data[String(d["id"])] = d.get("simpang", [])
	var salah: int = 0
	var jumlah: int = 0
	for i: int in range(20):
		var rute: RouteBuilder.Rute = RouteBuilder.bangun(SEED_DEV + 7 * i, _pustaka()).rute
		var harap: Array[String] = []
		for j: int in range(rute.segmen.size()):
			for s: Dictionary in data[rute.segmen[j].id]:
				var maju: float = rute.awal_segmen[j] + float(s["pos"])
				harap.append("%s:simpang:%s@%d|%s|%s|%s|%s" % [rute.segmen[j].id, s["sisi"], int(s["pos"]), maju, s["sisi"], 2.0, maju - 0.5])
		var dapat: Array[String] = []
		for it: RouteBuilder.SimpangItem in RouteBuilder.simpang_di(rute):
			dapat.append("%s|%s|%s|%s|%s" % [it.id, it.maju_ubin, SegmenRute.NAMA_SISI[0] if it.sisi == LoperAnim.Sisi.SEBERANG else SegmenRute.NAMA_SISI[1], it.lebar_mulut_ubin, it.mulut_awal_ubin])
		jumlah += dapat.size()
		if dapat != harap:
			salah += 1
	check(salah == 0 and jumlah >= 40, "20 rute: simpang = data segmen dibaca ulang dari berkas (%d simpang, %d rute salah)" % [jumlah, salah])
	check(RouteBuilder.simpang_di(null).is_empty(), "simpang_di(null) = kosong")
	var rute_dev: RouteBuilder.Rute = RouteBuilder.bangun(SEED_DEV, _pustaka()).rute
	check(RouteBuilder.simpang_di(rute_dev) == rute_dev.simpang, "simpang_di mengembalikan daftar rute")
	var urut: bool = true
	for i: int in range(1, rute_dev.simpang.size()):
		if rute_dev.simpang[i].maju_ubin < rute_dev.simpang[i - 1].maju_ubin:
			urut = false
	check(urut, "simpang rute urut maju")


func _test_rute_identik_golden() -> void:
	_judul.call("RouteBuilder: rute identik dengan sebelum simpang, 60 seed (rumah, rintangan, pelanggan, titik misi, dekor, tenggat, skor; AC-16)")
	var pustaka: Array[SegmenRute] = _pustaka()
	var cocok: int = 0
	var salah: Array[int] = []
	var pelanggan_25: int = 0
	for i: int in range(60):
		var hasil: RouteBuilder.Hasil = RouteBuilder.bangun(SEED_DEV + 7 * i, pustaka)
		if hasil.sah() and _fnv(_uraian(hasil.rute)) == GOLDEN_RUTE[i]:
			cocok += 1
		else:
			salah.append(i)
		if hasil.sah() and hasil.rute.pelanggan.size() == 25:
			pelanggan_25 += 1
	check(GOLDEN_RUTE.size() == 60 and cocok == 60, "60 rute: sidik uraian = golden 7f30557 dihitung ulang sesudah P-6 (%d cocok, salah di %s)" % [cocok, salah])
	check(pelanggan_25 == 60, "25 pelanggan di tiap rute (%d dari 60)" % pelanggan_25)


func _test_tanpa_rng() -> void:
	_judul.call("RouteBuilder: simpang tanpa RNG, rute tanpa simpang di data = rute dengan simpang (AC-16)")
	var tanpa: Array[SegmenRute] = []
	for nama: String in DirAccess.get_files_at(FOLDER_RUTE):
		if nama.ends_with(".json"):
			var d: Dictionary = _baca_json(FOLDER_RUTE + "/" + nama)
			d.erase("simpang")
			tanpa.append(SegmenRute.parse(d).segmen)
	var sama: int = 0
	for i: int in range(30):
		var a: RouteBuilder.Rute = RouteBuilder.bangun(SEED_DEV + 13 * i, _pustaka()).rute
		var b: RouteBuilder.Rute = RouteBuilder.bangun(SEED_DEV + 13 * i, tanpa).rute
		if _uraian(a) == _uraian(b) and b.simpang.is_empty() and not a.simpang.is_empty():
			sama += 1
	check(sama == 30, "30 seed: uraian rute dengan dan tanpa bidang simpang identik (%d)" % sama)


func _test_periksa_rute_sambungan() -> void:
	_judul.call("RouteBuilder.periksa_rute: simpang di rute utuh tidak memotong isi segmen mana pun dan tidak bertumpuk (AC-15)")
	var rute: RouteBuilder.Rute = RouteBuilder.bangun(SEED_DEV, _pustaka()).rute
	check(RouteBuilder.periksa_rute(rute).is_empty(), "rute nyata sah")
	var dekat: RouteBuilder.RumahRute = null
	for r: RouteBuilder.RumahRute in rute.rumah:
		if r.sisi == LoperAnim.Sisi.DEKAT:
			dekat = r
			break
	var sisip: RouteBuilder.SimpangItem = _simpang_item(dekat.maju_ubin, LoperAnim.Sisi.DEKAT)
	rute.simpang.append(sisip)
	var g: Array[String] = RouteBuilder.periksa_rute(rute)
	var ada: bool = false
	for s: String in g:
		if s.contains("kavling rumah dekat"):
			ada = true
	check(ada, "simpang disisipkan di rumah dekat rute ditolak di tingkat rute: %s" % [g])
	rute.simpang.erase(sisip)
	var pertama: RouteBuilder.SimpangItem = rute.simpang[0]
	var tumpang: RouteBuilder.SimpangItem = _simpang_item(pertama.maju_ubin + 1.0, LoperAnim.Sisi.DEKAT)
	rute.simpang.insert(1, tumpang)
	var g2: Array[String] = RouteBuilder.periksa_rute(rute)
	var ada2: bool = false
	for s: String in g2:
		if s.contains("bertumpuk"):
			ada2 = true
	check(ada2, "dua simpang bertumpuk di rute ditolak: %s" % [g2])
	var gagal: int = 0
	for i: int in range(100):
		if not RouteBuilder.bangun(SeedHari.rute(i + 1), _pustaka()).sah():
			gagal += 1
	check(gagal == 0, "100 rute hari tersusun sah dengan simpang (termasuk pemeriksaan sambungan segmen)")


# --- AC-17: konten ---

func _test_konten_dan_persen() -> void:
	_judul.call("Simpang: konten data dan persen rute bersimpang 100 seed (AC-17, D-4)")
	var data: Array = []
	for nama: String in DirAccess.get_files_at(FOLDER_RUTE):
		if nama.ends_with(".json"):
			var d: Dictionary = _baca_json(FOLDER_RUTE + "/" + nama)
			for s: Dictionary in d.get("simpang", []):
				data.append([String(d["id"]), int(s["pos"]), String(s["sisi"])])
	data.sort()
	check(data == SIMPANG_DATA, "simpang di data = %s (literal)" % [data])
	var ada: int = 0
	var dekat: int = 0
	var seberang: int = 0
	var total: int = 0
	for i: int in range(100):
		var rute: RouteBuilder.Rute = RouteBuilder.bangun(SeedHari.rute(i + 1), _pustaka()).rute
		var d2: bool = false
		var b2: bool = false
		for it: RouteBuilder.SimpangItem in RouteBuilder.simpang_di(rute):
			d2 = d2 or it.sisi == LoperAnim.Sisi.DEKAT
			b2 = b2 or it.sisi == LoperAnim.Sisi.SEBERANG
			total += 1
		ada += 1 if not rute.simpang.is_empty() else 0
		dekat += 1 if d2 else 0
		seberang += 1 if b2 else 0
	check(ada == 100 and dekat == 100 and seberang == 56, "100 rute hari: bersimpang %d, dekat %d, seberang %d (literal 100/100/56, dihitung dev_ukur/ukur_simpang.gd; per_tengah_05 selalu terpakai)" % [ada, dekat, seberang])
	check(total >= 100 and total <= 400, "1 sampai 3 simpang per rute (total %d di 100 rute)" % total)


func _test_kucing_600_hari() -> void:
	_judul.call("Simpang: titik kucing misi tidak pernah di pita simpang (600 hari, AC-15)")
	var misi: DataMisi = PemuatMisi.muat_folder().cari("p1_kucing")
	var pustaka: Array[SegmenRute] = _pustaka()
	var di_pita: int = 0
	var titik: int = 0
	for hari: int in range(1, 601):
		var rute: RouteBuilder.Rute = RouteBuilder.bangun(SeedHari.rute(hari), pustaka).rute
		var rencana: RencanaMisi.Rencana = RencanaMisi.buat(misi, rute, SeedHari.misi(hari))
		for t: RencanaMisi.Titik in rencana.titik:
			titik += 1
			for it: RouteBuilder.SimpangItem in rute.simpang:
				if SegmenRute.memotong_pita(SegmenRute.pita_maju(it.maju_ubin), it.sisi, RencanaMisi.persegi_kucing(t)):
					di_pita += 1
	check(titik > 1000 and di_pita == 0, "600 hari: %d titik kucing, %d di pita simpang" % [titik, di_pita])


# --- AC-18: pemilihan dan pemasangan ---

func _test_sel_simpang_literal() -> void:
	_judul.call("UbinKhusus.sel_simpang: tabel literal (AC-18)")
	var baris: Dictionary = UbinKhusus.himpunan_baris_simpang([_simpang_item(10.0, LoperAnim.Sisi.DEKAT), _simpang_item(20.0, LoperAnim.Sisi.SEBERANG)] as Array[RouteBuilder.SimpangItem])
	var D: int = LoperAnim.Sisi.DEKAT
	var S: int = LoperAnim.Sisi.SEBERANG
	check(baris == {9: Vector2i(D, -1), 10: Vector2i(D, 0), 11: Vector2i(D, 1), 12: Vector2i(D, 2), 13: Vector2i(D, 3), 19: Vector2i(S, -1), 20: Vector2i(S, 0), 21: Vector2i(S, 1), 22: Vector2i(S, 2), 23: Vector2i(S, 3)}, "himpunan baris: pos 10 dekat = 9 .. 13, pos 20 seberang = 19 .. 23: %s" % [baris])
	var T: Vector2i = UbinKhusus.TANPA_SIMPANG
	# [x, baris, harapan]
	var tabel: Array = [
		[0.5, 10, Vector2i(D, 11)], [1.5, 13, Vector2i(D, 0)], [2.5, 13, Vector2i(D, 1)], [3.5, 13, Vector2i(D, 2)], [7.5, 13, Vector2i(D, 2)], [40.5, 11, Vector2i(D, 10)],
		[0.5, 13, T], [0.5, 12, Vector2i(D, 3)], [0.5, 9, T], [2.5, 9, Vector2i(D, 16)], [1.5, 8, T], [1.5, 14, T], [-0.5, 10, T], [-1.5, 11, T], [-3.5, 12, T],
		[-0.5, 21, Vector2i(S, 5)], [-3.5, 23, Vector2i(S, 1)], [-9.5, 23, Vector2i(S, 1)], [-1.5, 23, T], [-2.5, 23, Vector2i(S, 0)], [1.5, 21, T], [-1.5, 18, T], [-0.5, 19, T],
	]
	for t: Array in tabel:
		var dapat: Vector2i = UbinKhusus.sel_simpang(t[0] as float, t[1] as int, baris)
		check(dapat == t[2], "sel_simpang(x %s, baris %s) = %s (dapat %s)" % [t[0], t[1], t[2], dapat])
	check(UbinKhusus.sel_simpang(1.5, 10, {}) == T, "tanpa simpang = TANPA_SIMPANG")
	# Indeks sel dari tabel literal: (rel 0, aspal) = 11, (3, trotoar) = 0, (-1, rumput) = 16.
	check(_indeks_sel(SEL_DEKAT, 0, 0) == 11 and _indeks_sel(SEL_DEKAT, 3, 1) == 0 and _indeks_sel(SEL_DEKAT, -1, 2) == 16 and _indeks_sel(SEL_SEBERANG, 1, 0) == 5, "indeks tabel literal")


## Nama tekstur harapan sel (x, baris) dengan simpang sisi `sisi` di baris `pos`: tabel literal bila di pita dan di sisi simpang, selain itu `bawaan` (tekstur sel sama di tanah tanpa simpang).
func _harapan_sel(x: float, baris: int, pos: int, bawaan: String, sisi: LoperAnim.Sisi = LoperAnim.Sisi.DEKAT) -> String:
	var rel: int = baris - pos
	var jarak: float = x if sisi == LoperAnim.Sisi.DEKAT else -x
	if jarak > 0.0 and rel >= -1 and rel <= 3:
		var kolom: int = 3
		if jarak < 1.0:
			kolom = 0
		elif jarak < 2.0:
			kolom = 1
		elif jarak < 3.0:
			kolom = 2
		if _indeks_sel(SEL_DEKAT if sisi == LoperAnim.Sisi.DEKAT else SEL_SEBERANG, rel, kolom) >= 0:
			return _nama_sel(rel, kolom, sisi)
	return bawaan


func _test_tanah_pasang() -> void:
	_judul.call("TanahDaur: ubin simpang di baris dan kolom yang benar, lengan berulang sampai kolom terjauh, sisi lain lurus (AC-18)")
	var tanah: TanahDaur = _buat_tanah(true)
	var polos: TanahDaur = _buat_tanah(false)
	check(tanah.mode_simpang(LoperAnim.Sisi.DEKAT) and tanah.mode_simpang(LoperAnim.Sisi.SEBERANG) and not polos.mode_simpang(LoperAnim.Sisi.DEKAT) and not polos.mode_simpang(LoperAnim.Sisi.SEBERANG), "mode simpang aktif dengan 18 tekstur dekat dan 16 seberang; tanpa tekstur tidak aktif")
	var pos: int = 12
	var masuk: Dictionary = {30: true}
	var total_salah: int = 0
	var contoh: String = ""
	for kasus: int in range(10):
		var lebar: int = ([640, 667, 780, 800, Config.LAYAR_LEBAR_MAKS_PX] as Array[int])[kasus % 5]
		var sisi: LoperAnim.Sisi = LoperAnim.Sisi.DEKAT if kasus < 5 else LoperAnim.Sisi.SEBERANG
		var arah: float = 1.0 if sisi == LoperAnim.Sisi.DEKAT else -1.0
		tanah.bangun(lebar, TINGGI)
		polos.bangun(lebar, TINGGI)
		tanah.atur_baris_masuk(masuk)
		polos.atur_baris_masuk(masuk)
		tanah.atur_simpang(UbinKhusus.himpunan_baris_simpang([_simpang_item(float(pos), sisi)] as Array[RouteBuilder.SimpangItem]))
		var lengan_maks: float = 0.0
		var x_maks_pita: float = 0.0
		for jarak: float in [0.0, 5.5, 9.99, 12.0, 14.3, 20.0]:
			tanah.perbarui(jarak)
			polos.perbarui(jarak)
			var blok: int = int(floor(jarak))
			var bawaan: Dictionary = {}
			for u: Sprite2D in _sprite_ubin(polos):
				bawaan[u.position] = _nama_tekstur(u)
			for u: Sprite2D in _sprite_ubin(tanah):
				var d: Vector2 = _dunia_dari_layar(u.position)
				var b: int = int(round(-d.y)) + blok
				var harap: String = _harapan_sel(d.x, b, pos, String(bawaan[u.position]), sisi)
				if _nama_tekstur(u) != harap:
					total_salah += 1
					if contoh.is_empty():
						contoh = "lebar %d jarak %s x %s baris %d: %s harapan %s" % [lebar, jarak, d.x, b, _nama_tekstur(u), harap]
				if b >= pos - 1 and b <= pos + 3 and arah * d.x > 3.0:
					x_maks_pita = maxf(x_maks_pita, arah * d.x)
					if _nama_tekstur(u).begins_with("simpang_%s_lengan" % ("dekat" if sisi == LoperAnim.Sisi.DEKAT else "seberang")):
						lengan_maks = maxf(lengan_maks, arah * d.x)
		check(lengan_maks > 3.0 and lengan_maks == x_maks_pita, "lebar %d sisi %s: lengan sampai kolom terjauh yang ada di blok (|x| %s = %s)" % [lebar, sisi, lengan_maks, x_maks_pita])
	check(total_salah == 0, "tiap sprite di 5 lebar x 6 jarak x 2 sisi = harapan (tabel literal di pita sisi simpang, sama dengan tanah tanpa simpang di luar): %s" % contoh)
	var wadah: Array[String] = []
	for w: Node in tanah.get_children():
		wadah.append(String(w.name))
		var tekstur: Dictionary = {}
		for a: Node in w.get_children():
			tekstur[(a as Sprite2D).texture.resource_path] = true
		if tekstur.size() > 1:
			check(false, "wadah %s lebih dari satu tekstur" % w.name)
	check(wadah.size() == 49 and wadah[15] == "SimpangSeberang0" and wadah[30] == "SimpangSeberang15" and wadah[31] == "SimpangDekat0" and wadah[48] == "SimpangDekat17", "49 wadah (15 + 16 simpang seberang + 18 dekat, naik tepat sebanyak tekstur baru), satu tekstur per wadah")
	check(_sprite_ubin(tanah).size() == _sprite_ubin(polos).size(), "jumlah sprite ubin sama dengan tanpa simpang")
	tanah.atur_simpang({})
	tanah.perbarui(12.0)
	polos.perbarui(12.0)
	var sisa: int = 0
	for u: Sprite2D in _sprite_ubin(tanah):
		if _nama_tekstur(u).begins_with("simpang_"):
			sisa += 1
	check(sisa == 0, "atur_simpang({}) menghapus semua ubin simpang")
	# Simpang seberang dengan tekstur dekat saja (tanah tanpa tekstur seberang): tanah tetap lurus, tidak ada ubin dekat yang salah sisi.
	var dekat_saja: TanahDaur = _buat_tanah(true)
	dekat_saja.tekstur_simpang_seberang = []
	dekat_saja.bangun(Config.LAYAR_LEBAR_MAKS_PX, TINGGI)
	dekat_saja.atur_simpang(UbinKhusus.himpunan_baris_simpang([_simpang_item(13.0, LoperAnim.Sisi.SEBERANG)] as Array[RouteBuilder.SimpangItem]))
	dekat_saja.perbarui(12.0)
	var salah_sisi: int = 0
	for u: Sprite2D in _sprite_ubin(dekat_saja):
		if _nama_tekstur(u).begins_with("simpang_"):
			salah_sisi += 1
	check(salah_sisi == 0 and dekat_saja.get_child_count() == 33, "simpang seberang tanpa tekstur seberang: tidak ada ubin simpang terpasang, 33 wadah")
	dekat_saja.free()
	tanah.free()
	polos.free()


# --- AC-19: piksel ---

func _test_susunan_referensi() -> void:
	_judul.call("TanahDaur: susunan simpang dekat piksel-identik dengan referensi Python (AC-19)")
	var tanah: TanahDaur = _buat_tanah(true)
	tanah.bangun(Config.LAYAR_LEBAR_MAKS_PX, Config.LAYAR_TINGGI_DASAR_PX)
	tanah.atur_simpang(UbinKhusus.himpunan_baris_simpang([_simpang_item(3.0, LoperAnim.Sisi.DEKAT)] as Array[RouteBuilder.SimpangItem]))
	tanah.perbarui(0.0)
	var ref: Image = Image.load_from_file(ProjectSettings.globalize_path(REFERENSI))
	check(ref != null and not ref.is_empty(), "referensi tests/data/ubin_potongan_simpang.png terbaca")
	if ref == null or ref.is_empty():
		tanah.free()
		return
	ref.convert(Image.FORMAT_RGBA8)
	var terpilih: Array[Sprite2D] = []
	var x_min: int = 1 << 30
	var y_min: int = 1 << 30
	var simpang: int = 0
	for u: Sprite2D in _sprite_ubin(tanah):
		var d: Vector2 = _dunia_dari_layar(u.position)
		if d.x > -5.0 and d.x < 6.0 and d.y <= 0.001 and d.y >= -8.001:
			terpilih.append(u)
			x_min = mini(x_min, int(u.position.x) - 32)
			y_min = mini(y_min, int(u.position.y) - 16)
			if _nama_tekstur(u).begins_with("simpang_"):
				simpang += 1
	check(terpilih.size() == 99 and simpang == 28, "potongan 11 kolom x 9 baris = 99 ubin, 28 ubin simpang (dapat %d, %d)" % [terpilih.size(), simpang])
	var kanvas: Image = Image.create(ref.get_width(), ref.get_height(), false, Image.FORMAT_RGBA8)
	kanvas.fill(Color(0, 0, 0, 0))
	for u: Sprite2D in terpilih:
		var g: Image = _gambar_tekstur(u.texture)
		kanvas.blend_rect(g, Rect2i(Vector2i.ZERO, g.get_size()), Vector2i(int(u.position.x) - 32 - x_min, int(u.position.y) - 16 - y_min))
	check(kanvas.get_size() == ref.get_size() and kanvas.get_data() == ref.get_data(), "susunan TanahDaur simpang dekat di baris 3 piksel-identik dengan referensi (mulut, sudut, lengan, variasi rumput)")
	tanah.free()


func _test_susunan_referensi_seberang() -> void:
	_judul.call("TanahDaur: susunan simpang seberang piksel-identik dengan referensi Python dari assets/ (AC-19, P-6)")
	var tanah: TanahDaur = _buat_tanah(true)
	tanah.bangun(Config.LAYAR_LEBAR_MAKS_PX, Config.LAYAR_TINGGI_DASAR_PX)
	tanah.atur_simpang(UbinKhusus.himpunan_baris_simpang([_simpang_item(3.0, LoperAnim.Sisi.SEBERANG)] as Array[RouteBuilder.SimpangItem]))
	tanah.perbarui(0.0)
	var ref: Image = Image.load_from_file(ProjectSettings.globalize_path(REFERENSI_SEBERANG))
	check(ref != null and not ref.is_empty(), "referensi tests/data/ubin_potongan_simpang_seberang.png terbaca")
	if ref == null or ref.is_empty():
		tanah.free()
		return
	ref.convert(Image.FORMAT_RGBA8)
	var terpilih: Array[Sprite2D] = []
	var x_min: int = 1 << 30
	var y_min: int = 1 << 30
	var simpang: int = 0
	for u: Sprite2D in _sprite_ubin(tanah):
		var d: Vector2 = _dunia_dari_layar(u.position)
		if d.x > -6.0 and d.x < 5.0 and d.y <= 0.001 and d.y >= -8.001:
			terpilih.append(u)
			x_min = mini(x_min, int(u.position.x) - 32)
			y_min = mini(y_min, int(u.position.y) - 16)
			if _nama_tekstur(u).begins_with("simpang_seberang_"):
				simpang += 1
	check(terpilih.size() == 99 and simpang == 26, "potongan 11 kolom x 9 baris = 99 ubin, 26 ubin simpang seberang (16 sel + lengan kolom -4,5 dan -5,5 di 5 baris; dapat %d, %d)" % [terpilih.size(), simpang])
	var kanvas: Image = Image.create(ref.get_width(), ref.get_height(), false, Image.FORMAT_RGBA8)
	kanvas.fill(Color(0, 0, 0, 0))
	for u: Sprite2D in terpilih:
		var g: Image = _gambar_tekstur(u.texture)
		kanvas.blend_rect(g, Rect2i(Vector2i.ZERO, g.get_size()), Vector2i(int(u.position.x) - 32 - x_min, int(u.position.y) - 16 - y_min))
	check(kanvas.get_size() == ref.get_size() and kanvas.get_data() == ref.get_data(), "susunan TanahDaur simpang seberang di baris 3 piksel-identik dengan referensi (mulut, sudut, lengan, simbol, variasi rumput)")
	tanah.free()


func _test_tanpa_celah() -> void:
	_judul.call("TanahDaur: tanpa piksel transparan di seluruh viewport di sekitar simpang (AC-19)")
	var tanah: TanahDaur = _buat_tanah(true)
	var total: int = 0
	var celah: int = 0
	var simpang_terlihat: int = 0
	for lebar: int in [640, 667, 780, 800, Config.LAYAR_LEBAR_MAKS_PX]:
		tanah.bangun(lebar, TINGGI)
		tanah.atur_simpang(UbinKhusus.himpunan_baris_simpang([_simpang_item(10.0, LoperAnim.Sisi.DEKAT), _simpang_item(16.0, LoperAnim.Sisi.SEBERANG)] as Array[RouteBuilder.SimpangItem]))
		for jarak_ubin: float in [6.0, 9.5, 11.25, 13.0]:
			tanah.perbarui(jarak_ubin)
			for u: Sprite2D in _sprite_ubin(tanah):
				if _nama_tekstur(u).begins_with("simpang_"):
					simpang_terlihat += 1
			for lat: float in [-2.0, 0.0, 2.0]:
				var layar_sepeda: Vector2 = Vector2((lat + jarak_ubin) * 32.0, (lat - jarak_ubin) * 16.0)
				var asal: Vector2i = Vector2i((layar_sepeda - Vector2(lebar * Config.KAMERA_SEPEDA_X_PECAHAN, TINGGI * Config.KAMERA_SEPEDA_Y_PECAHAN)).round())
				var kanvas: Image = Image.create(lebar, TINGGI, false, Image.FORMAT_RGBA8)
				kanvas.fill(Color(0, 0, 0, 0))
				for u: Sprite2D in _sprite_ubin(tanah):
					var g: Image = _gambar_tekstur(u.texture)
					kanvas.blend_rect(g, Rect2i(Vector2i.ZERO, g.get_size()), Vector2i(u.position + tanah.position) - Vector2i(32, 16) - asal)
				var data: PackedByteArray = kanvas.get_data()
				for i: int in range(3, data.size(), 4):
					if data[i] != 255:
						celah += 1
				total += 1
	check(total == 60 and celah == 0, "nol piksel transparan di %d viewport (5 lebar, 4 jarak, 3 lateral) di sekitar simpang (%d)" % [total, celah])
	check(simpang_terlihat > 1000, "ubin simpang tampil di viewport yang diuji (%d sprite)" % simpang_terlihat)
	tanah.free()


# --- AC-20: zona dan gerak ---

func _test_medan_identik() -> void:
	_judul.call("MedanKoran: zona dan penilaian identik dengan dan tanpa simpang (AC-20)")
	var rute: RouteBuilder.Rute = RouteBuilder.bangun(SEED_DEV, _pustaka()).rute
	var a: MedanKoran = MedanKoran.dari_rute(rute)
	var simpan: Array[RouteBuilder.SimpangItem] = rute.simpang.duplicate()
	rute.simpang.clear()
	var b: MedanKoran = MedanKoran.dari_rute(rute)
	rute.simpang = simpan
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 5317
	var beda: int = 0
	for i: int in range(2000):
		var titik: Vector2 = Vector2(rng.randf_range(-6.0, 6.0), -rng.randf_range(0.0, rute.panjang_ubin))
		var za: Array[ZonaSasaran.Zona] = a.zona_sekitar(titik)
		var zb: Array[ZonaSasaran.Zona] = b.zona_sekitar(titik)
		var tinggi: float = rng.randf_range(0.0, 1.5)
		if za.size() != zb.size() or ZonaSasaran.klasifikasi(titik, za) != ZonaSasaran.klasifikasi(titik, zb) or a.tertutup_titik(titik, tinggi) != b.tertutup_titik(titik, tinggi):
			beda += 1
	check(beda == 0, "2000 titik acak berseed: zona, penilaian, dan penutup sama dengan dan tanpa simpang (%d beda)" % beda)


func _siapkan() -> RuteMain:
	_tree.root.size = Vector2i(2340, 1080)
	var akar: RuteMain = (load(BERKAS_RUTE) as PackedScene).instantiate() as RuteMain
	_tree.root.add_child(akar)
	await _tree.process_frame
	await _tree.process_frame
	akar.set_process(false)
	(akar.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = false
	(akar.find_child("LoperAgen", true, false) as LoperSprite).set_process(false)
	return akar


func _bersihkan(akar: RuteMain) -> void:
	(akar.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = OS.has_feature("editor")
	_tree.root.remove_child(akar)
	akar.free()


func _taruh(akar: RuteMain, lateral: float, maju: float) -> void:
	var sepeda: SepedaUji = akar.find_child("Sepeda", true, false) as SepedaUji
	var k: BikeMotion.Keadaan = sepeda.keadaan.salin()
	k.kecepatan_ud = Config.KECEPATAN_SANTAI_UD
	k.lateral_ubin = lateral
	sepeda.keadaan = k
	sepeda.jarak_ubin = maju
	akar.perbarui(0.0)


func _test_scene() -> void:
	_judul.call("Scene rute: ubin simpang dari rute nyata kedua sisi, rute.tscn memuat 18 tekstur dekat dan 16 seberang, tembok dan rumah tidak di pita (AC-18)")
	var akar: RuteMain = await _siapkan()
	var tanah: TanahDaur = akar.find_child("Tanah", true, false) as TanahDaur
	check(tanah.mode_simpang(LoperAnim.Sisi.DEKAT) and tanah.mode_simpang(LoperAnim.Sisi.SEBERANG) and tanah.get_child_count() == 49, "rute.tscn: mode simpang kedua sisi, 49 wadah")
	var urut_seb: bool = tanah.tekstur_simpang_seberang.size() == 16
	for i: int in range(mini(16, tanah.tekstur_simpang_seberang.size())):
		var q: Array = SEL_SEBERANG[i]
		if tanah.tekstur_simpang_seberang[i].resource_path != FOLDER_UBIN + "tile_perumahan_%s.png" % _nama_sel(q[0] as int, q[1] as int, LoperAnim.Sisi.SEBERANG):
			urut_seb = false
	check(urut_seb, "tekstur_simpang_seberang di rute.tscn sejajar tabel sel")
	var urut: bool = tanah.tekstur_simpang_dekat.size() == 18
	for i: int in range(mini(18, tanah.tekstur_simpang_dekat.size())):
		var p: Array = SEL_DEKAT[i]
		if tanah.tekstur_simpang_dekat[i].resource_path != FOLDER_UBIN + "tile_perumahan_%s.png" % _nama_sel(p[0] as int, p[1] as int):
			urut = false
	check(urut, "tekstur_simpang_dekat di rute.tscn sejajar tabel sel")
	var salah: int = 0
	var simpang_sprite: int = 0
	var sisi_terlihat: Dictionary = {}
	for benih: int in [SEED_DEV, _benih_seberang()]:
		akar.call("_susun", benih)
		var rute: RouteBuilder.Rute = akar.get("_rute") as RouteBuilder.Rute
		check(not rute.simpang.is_empty(), "rute seed %d memuat simpang (%d)" % [benih, rute.simpang.size()])
		for it: RouteBuilder.SimpangItem in rute.simpang:
			sisi_terlihat[it.sisi] = true
			salah += _periksa_scene_simpang(akar, tanah, it, rute.simpang)
			simpang_sprite += 1
	check(salah == 0 and simpang_sprite >= 3 and sisi_terlihat.size() == 2, "simpang rute dev dan rute bersimpang seberang (kedua sisi): sel pita = tabel literal (%d simpang, %d salah)" % [simpang_sprite, salah])
	_cek_tembok_rumah_100()
	_bersihkan(akar)


## Seed pertama (20261016 + i) yang rutenya memuat simpang seberang (per_buka_02, putusan P-6).
func _benih_seberang() -> int:
	for i: int in range(60):
		for it: RouteBuilder.SimpangItem in RouteBuilder.bangun(SEED_DEV + i, _pustaka()).rute.simpang:
			if it.sisi == LoperAnim.Sisi.SEBERANG:
				return SEED_DEV + i
	return -1


## Jumlah sel salah di blok tanah dengan sepeda di baris `pos` simpang `it`: tiap sel = tabel literal simpang rute mana pun yang pitanya memuat sel itu (sisi simpang),
## dan tidak ada ubin simpang di luar pita simpang rute (`semua`).
func _periksa_scene_simpang(akar: RuteMain, tanah: TanahDaur, it: RouteBuilder.SimpangItem, semua: Array[RouteBuilder.SimpangItem]) -> int:
	var salah: int = 0
	var diperiksa: int = 0
	_taruh(akar, 0.0, it.maju_ubin)
	var blok: int = int(floor(it.maju_ubin))
	for u: Sprite2D in _sprite_ubin(tanah):
		var d: Vector2 = _dunia_dari_layar(u.position)
		var b: int = int(round(-d.y)) + blok
		var harap: String = ""
		for lain: RouteBuilder.SimpangItem in semua:
			if harap.is_empty():
				harap = _harapan_sel(d.x, b, roundi(lain.maju_ubin), "", lain.sisi)
		var nama: String = _nama_tekstur(u)
		if not harap.is_empty():
			diperiksa += 1
			if nama != harap:
				salah += 1
		elif nama.begins_with("simpang_"):
			salah += 1
	return salah if diperiksa > 50 else salah + 1


## Rumah (tapak gambar sprite nyata) sisi simpang tidak ada di pita simpang (100 rute hari, kedua sisi). Tembok dilepas run 5D (P-1).
func _cek_tembok_rumah_100() -> void:
	var di_pita: int = 0
	for i: int in range(100):
		var r: RouteBuilder.Rute = RouteBuilder.bangun(SeedHari.rute(i + 1), _pustaka()).rute
		for it: RouteBuilder.SimpangItem in r.simpang:
			var pita: Vector2 = Vector2(it.maju_ubin - 1.5, it.maju_ubin + 3.5)
			for rumah: RouteBuilder.RumahRute in r.rumah:
				if rumah.sisi != it.sisi:
					continue
				var tapak: Rect2 = PenutupPemain.tapak_rumah_gambar(rumah.sisi, rumah.maju_ubin, rumah.jenis)
				if tapak.position.y < pita.y and tapak.end.y > pita.x:
					di_pita += 1
	check(di_pita == 0, "100 rute: tidak ada tapak gambar rumah sisi simpang di pita simpang (%d)" % di_pita)


func _test_scene_gerak_identik() -> void:
	_judul.call("Scene rute: sepeda melintasi mulut simpang tanpa tabrakan, jejak gerak identik dengan simpang tidak digambar (AC-20)")
	var jejak: Array = []
	var tabrak_total: int = 0
	for mode: int in range(4):
		var akar: RuteMain = await _siapkan()
		var tanah: TanahDaur = akar.find_child("Tanah", true, false) as TanahDaur
		var segmen_uji: String = "per_tengah_05"
		if mode >= 2:
			akar.call("_susun", _benih_seberang())
			segmen_uji = "per_buka_02"
		var rute: RouteBuilder.Rute = akar.get("_rute") as RouteBuilder.Rute
		var it: RouteBuilder.SimpangItem = null
		for s: RouteBuilder.SimpangItem in rute.simpang:
			if s.id_segmen == segmen_uji:
				it = s
		if mode % 2 == 1:
			tanah.atur_simpang({})
		var tabrak: Array[String] = []
		akar.tabrakan.connect(func(j: String) -> void: tabrak.append(j))
		var teks: PackedStringArray = PackedStringArray()
		var sepeda: SepedaUji = akar.find_child("Sepeda", true, false) as SepedaUji
		for lat: float in [-2.0, -1.0, 0.0, 1.0, 2.0]:
			_taruh(akar, lat, it.maju_ubin - 2.5)
			for i: int in range(150):
				akar.perbarui(DT)
				var k: BikeMotion.Keadaan = sepeda.keadaan
				teks.append("%s|%s|%s|%s|%s|%s" % [var_to_str(sepeda.jarak_ubin), var_to_str(k.lateral_ubin), var_to_str(k.kecepatan_ud), var_to_str(k.stamina), sepeda.sedang_jatuh(), sepeda.pose()])
			if sepeda.jarak_ubin < it.maju_ubin + 3.5:
				check(false, "lateral %s: sepeda melewati ujung pita (%s)" % [lat, sepeda.jarak_ubin])
		tabrak_total += tabrak.size()
		jejak.append("\n".join(teks))
		_bersihkan(akar)
	check(jejak.size() == 4 and jejak[0] == jejak[1] and jejak[2] == jejak[3] and (jejak[0] as String).length() > 1000 and jejak[0] != jejak[2], "simpang dekat dan seberang, 5 lateral x 150 langkah: jejak gerak (jarak, lateral, kecepatan, stamina, jatuh, pose) identik bit demi bit dengan dan tanpa simpang tergambar")
	check(tabrak_total == 0, "tanpa tabrakan saat melintasi mulut simpang di lateral -2 .. 2 (%d)" % tabrak_total)


# --- Uraian rute (sama dengan dev_ukur/golden_rute_cd.gd) ---

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
	for d: RouteBuilder.DekorItem in rute.dekor:
		bagian.append("D|%s|%s|%s|%s|%d|%s|%s" % [d.id, d.id_segmen, str(d.maju_ubin), str(d.lateral_ubin), d.sisi, d.jenis, d.varian])
	var k: SkorRute.Keadaan = SkorRute.awal()
	var i: int = 0
	for p: RouteBuilder.RumahRute in rute.pelanggan:
		var hasil: ZonaSasaran.Hasil = ZonaSasaran.Hasil.KOTAK_SURAT if i % 2 == 0 else ZonaSasaran.Hasil.TERAS
		var kecepatan: float = 3.0 if i % 3 != 0 else 5.0
		k = SkorRute.nilai(k, hasil, p.id, i % 3 == 0, kecepatan, RouteBuilder.pemberi_tip(rute, p.id), false).keadaan
		i += 1
	bagian.append("skor=%d;koin=%d;tip=%d;tepat=%d;antar=%d" % [k.skor, k.koin, k.jumlah_tip, k.jumlah_tepat, k.jumlah_antar])
	return "\n".join(bagian)


## FNV-1a 32 bit atas byte UTF-8 (ditulis ulang di sini).
func _fnv(teks: String) -> int:
	var nilai: int = 2166136261
	for b: int in teks.to_utf8_buffer():
		nilai = nilai ^ b
		nilai = (nilai * 16777619) & 4294967295
	return nilai
