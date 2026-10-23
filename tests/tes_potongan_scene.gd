class_name TesPotonganScene
extends RefCounted
## Tes scene potongan koran terbuang run fase6a2-reputasi-pelanggan bagian B (AC-9 sampai AC-11, O-3): lemparan nyata di scene rute (umpan "-5" di titik mendarat, HUD koin bersih, mode bantu,
## Main lagi), layar hasil (baris koran terbuang, koin bersih, saldo dijepit; empat ukuran layar, kasus terpadat) dan alur `hari.tscn` (Hasil -> Bengkel -> Hari berikutnya menulis save tepat sekali,
## hari minus tidak menjebak). `SaveManager` disuntik jalur sementara `user://tes_potongan_scene/`; `user://save.json` TIDAK pernah disentuh (dicek sebelum dan sesudah).

const BERKAS_RUTE: String = "res://scenes/rute/rute.tscn"
const BERKAS_HASIL: String = "res://scenes/ui/layar_hasil.tscn"
const BERKAS_HARI: String = "res://scenes/hari/hari.tscn"
const FOLDER_TES: String = "user://tes_potongan_scene"
const SAVE_ASLI: String = "user://save.json"
const SKRIP_SIMPAN: String = "res://scripts/autoload/save_manager.gd"
const DT: float = 1.0 / 60.0
const SKALA: int = 3
const LEBAR: int = 780
## Titik aspal di luar zona mana pun, dari maju 4 (dipakai tes_vfx_sprite untuk koran meleset).
const TITIK_MELESET: Vector2 = Vector2(-0.5, 10.5)

var _cek: Callable
var _judul: Callable
var _tree: SceneTree
var _simpanan_aktif: Array[Node] = []


func _init(cek: Callable, judul: Callable, tree: SceneTree) -> void:
	_cek = cek
	_judul = judul
	_tree = tree


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	var sebelum: Dictionary = _jejak_save_asli()
	await _test_lemparan_nyata()
	await _test_mode_bantu_dan_main_lagi()
	await _test_hud_koin_negatif()
	for kasus: Array in [[1600, 720, 800], [1920, 1080, 640], [2340, 1080, 780], [2400, 1080, 800]]:
		await _test_layar_hasil(kasus)
	await _test_hasil_dari_rute()
	await _test_alur_hari_minus()
	await _test_alur_hari_baik()
	var sesudah: Dictionary = _jejak_save_asli()
	check(sebelum == sesudah, "user://save.json tidak tersentuh oleh tes potongan scene (%s -> %s)" % [sebelum, sesudah])


# --- Pembantu ---

func _jejak_save_asli() -> Dictionary:
	var ada: bool = FileAccess.file_exists(SAVE_ASLI)
	return {"ada": ada, "ukuran": FileAccess.get_file_as_bytes(SAVE_ASLI).size() if ada else 0, "sha": FileAccess.get_sha256(SAVE_ASLI) if ada else ""}


func _anak(akar: Node, nama: String) -> Node:
	return akar.find_child(nama, true, false)


func _sepeda(akar: Node) -> SepedaUji:
	return akar.find_child("Sepeda", true, false) as SepedaUji


func _siapkan(jendela: Vector2i = Vector2i(2340, 1080)) -> RuteMain:
	_tree.root.size = jendela
	var akar: RuteMain = (load(BERKAS_RUTE) as PackedScene).instantiate() as RuteMain
	_tree.root.add_child(akar)
	await _tree.process_frame
	await _tree.process_frame
	akar.set_process(false)
	(_anak(akar, "KontrolTouch") as KontrolTouch).keyboard_aktif = false
	(_anak(akar, "LoperAgen") as LoperSprite).set_process(false)
	return akar


func _bersihkan(akar: AdeganJalan) -> void:
	_lepas_jari()
	if akar.sedang_jeda():
		akar.minta_lanjut()
	(_anak(akar, "KontrolTouch") as KontrolTouch).keyboard_aktif = OS.has_feature("editor")
	_tree.root.remove_child(akar)
	akar.free()


func _lepas_jari() -> void:
	for i: int in range(8):
		var peristiwa: InputEventScreenTouch = InputEventScreenTouch.new()
		peristiwa.index = i
		peristiwa.position = Vector2(-50, -50)
		peristiwa.pressed = false
		Input.parse_input_event(peristiwa)
	Input.flush_buffered_events()


func _taruh(akar: AdeganJalan, v: float, lateral: float, maju: float) -> void:
	var sepeda: SepedaUji = _sepeda(akar)
	var k: BikeMotion.Keadaan = sepeda.keadaan.salin()
	k.kecepatan_ud = v
	k.lateral_ubin = lateral
	sepeda.keadaan = k
	sepeda.jarak_ubin = maju
	akar.perbarui(0.0)


func _langkah(akar: AdeganJalan, jumlah: int) -> void:
	for i: int in range(jumlah):
		akar.perbarui(DT)


## Melempar koran ke titik jalan `titik_jalan` dari maju `maju` (lintasan sama dengan swipe nyata: `ThrowSolver`), `bantu` = koran mode bantu; menunggu mendarat dan mengembalikannya.
func _lempar_ke_titik(akar: RuteMain, maju: float, titik_jalan: Vector2, mendarat: Array[KoranLempar.Koran], bantu: bool = false) -> KoranLempar.Koran:
	_taruh(akar, 3.0, 0.5, maju)
	akar.koran = SisaKoran.awal(30)
	var sepeda: SepedaUji = _sepeda(akar)
	var posisi: Vector2 = sepeda.posisi_dunia()
	var jeda: float = sepeda.jeda_lepas(LoperAnim.Sisi.SEBERANG)
	var lepas: Vector2 = ThrowSolver.titik_lepas(posisi, sepeda.kecepatan_ud, sepeda.lateral_ud, jeda)
	var sasaran: Vector2 = Vector2(titik_jalan.x, -titik_jalan.y)
	var u: float = BantuLempar.cari_kekuatan(sasaran, lepas, sepeda.kecepatan_ud)
	if u < 0.0:
		check(false, "pembantu tes: titik %s terjangkau dari maju %.1f" % [titik_jalan, maju])
		return null
	var lebar: float = float(LEBAR)
	var lintasan: ThrowSolver.Lintasan = ThrowSolver.hitung(ThrowSolver.panjang_untuk_kekuatan(u, lebar), lebar, BantuLempar.arah_ke(sasaran, lepas, sepeda.kecepatan_ud, u), posisi, sepeda.kecepatan_ud, sepeda.lateral_ud, jeda)
	var sebelum: int = mendarat.size()
	akar.call(&"_lempar", lintasan, bantu)
	for i: int in range(150):
		akar.perbarui(DT)
		if mendarat.size() > sebelum:
			return mendarat[sebelum]
	return null


func _lempar_ke_kotak(akar: RuteMain, maju: float, id_rumah: String, mendarat: Array[KoranLempar.Koran]) -> KoranLempar.Koran:
	_taruh(akar, 3.0, 0.5, maju)
	akar.koran = SisaKoran.awal(30)
	var pilihan: BantuLempar.Pilihan = akar.pilihan_bantu(LoperAnim.Sisi.SEBERANG)
	if pilihan == null or pilihan.zona.id_rumah != id_rumah:
		check(false, "pembantu tes: lintasan ke %s dari maju %.1f" % [id_rumah, maju])
		return null
	var sebelum: int = mendarat.size()
	akar.call(&"_lempar", pilihan.lintasan, false)
	for i: int in range(150):
		akar.perbarui(DT)
		if mendarat.size() > sebelum:
			return mendarat[sebelum]
	return null


## Angka hasil rakitan tes: `terbuang` koran terbuang (potongan = terbuang x 5), koin kotor `koin`.
func _angka(terkirim: int, koin: int, terbuang: int) -> HasilRute.Angka:
	var a: HasilRute.Angka = HasilRute.Angka.new()
	a.pelanggan = 25
	a.terkirim = terkirim
	a.meleset = 25 - terkirim
	a.koin = koin
	a.koin_tip = 0
	a.skor = 1000
	a.lempar_terbuang = terbuang
	a.potongan = terbuang * Config.KOIN_POTONGAN_KORAN_MELESET
	return a


# --- Lemparan nyata di scene rute (O-3) ---

func _test_lemparan_nyata() -> void:
	_judul.call("Scene rute: koran meleset/ulang menahan potongan; umpan '-5' di titik mendarat (netral, tanpa bintang), HUD koin bersih (O-3, AC-11)")
	var akar: RuteMain = await _siapkan()
	var hud: HudRute = akar.hud_rute()
	var gambar: UmpanMelayangGambar = akar.umpan_gambar()
	var mendarat: Array[KoranLempar.Koran] = []
	akar.koran_mendarat.connect(func(k: KoranLempar.Koran) -> void: mendarat.append(k))
	check(hud.teks_koin() == "0" and akar.skor().terbuang == 0, "awal: HUD koin 0, terbuang 0")
	# 1. Meleset ke aspal.
	var m: KoranLempar.Koran = _lempar_ke_titik(akar, 4.0, TITIK_MELESET, mendarat)
	check(m != null and m.hasil == ZonaSasaran.Hasil.MELESET and akar.skor().terbuang == 1 and akar.skor().koin == 0, "kontrol: koran meleset dinilai tidak sah: terbuang 1, koin kotor tetap 0")
	check(hud.teks_koin() == "-5", "HUD koin bersih '-5' (tanda minus eksplisit), dapat '%s'" % hud.teks_koin())
	check(gambar.teks_tampil() == ["-5"] and gambar.item_sprite().is_empty(), "umpan melayang '-5' tanpa bintang dan koin: %s" % [gambar.teks_tampil()])
	var entri: Array[UmpanMelayang.Entri] = akar.umpan_melayang()
	check(m != null and entri.size() == 1 and entri[0].potongan == 5 and entri[0].titik_dunia == m.lintasan.titik_mendarat, "entri potongan 5 di titik mendarat koran")
	var label: Label = gambar.get_child(0) as Label if gambar.get_child_count() > 0 else null
	check(label != null and label.get_theme_color(&"font_color") == Palette.TEXT_2, "label potongan nada netral TEXT_2 (bukan OK hijau, bukan merah)")
	# 2. Antaran sah ke kotak surat @6 sesudah umpan habis: koin 15, bersih 10.
	_langkah(akar, 60)
	check(gambar.teks_tampil().is_empty(), "sesudah 1 detik umpan habis")
	var k: KoranLempar.Koran = _lempar_ke_kotak(akar, 1.0, "per_buka_01@6", mendarat)
	check(k != null and akar.skor().koin == 15 and akar.skor().terbuang == 1 and hud.teks_koin() == "10", "antaran sah: koin kotor 15, koin bersih HUD 10 (15 - 5)")
	check(gambar.teks_tampil().size() == 1 and (gambar.teks_tampil()[0] as String).begins_with("+15"), "antaran sah: umpan '+15' (bukan potongan): %s" % [gambar.teks_tampil()])
	# 3. Koran ulang ke rumah yang sama: dipotong lagi.
	_langkah(akar, 60)
	var u: KoranLempar.Koran = _lempar_ke_kotak(akar, 1.0, "per_buka_01@6", mendarat)
	check(u != null and akar.skor().terbuang == 2 and akar.skor().koin == 15 and hud.teks_koin() == "5" and gambar.teks_tampil() == ["-5"], "koran ulang ke rumah terantar: terbuang 2, koin kotor tetap 15, HUD 5, umpan '-5'")
	# 4. Koran yang tidak dilempar tidak dipotong: sisa koran turun hanya karena lemparan.
	check(akar.skor().terbuang == 2 and mendarat.size() == 3, "hanya tiga koran dilempar dan dua terbuang; sisa koran lain tidak dipotong (K-2)")
	# 5. Jeda membekukan umpan potongan.
	_langkah(akar, 60)
	_lempar_ke_titik(akar, 4.0, TITIK_MELESET, mendarat)
	var sisa: float = akar.umpan_melayang().back().sisa_detik if not akar.umpan_melayang().is_empty() else -1.0
	akar.minta_jeda()
	_langkah(akar, 40)
	check(sisa > 0.0 and not akar.umpan_melayang().is_empty() and akar.umpan_melayang().back().sisa_detik == sisa and gambar.teks_tampil().has("-5"), "jeda game membekukan umpan '-5'")
	akar.minta_lanjut()
	_bersihkan(akar)


func _test_mode_bantu_dan_main_lagi() -> void:
	_judul.call("Mode bantu: potongan tetap berlaku; Main lagi mengatur ulang terbuang, HUD, dan umpan (AC-11)")
	var akar: RuteMain = await _siapkan()
	var hud: HudRute = akar.hud_rute()
	var mendarat: Array[KoranLempar.Koran] = []
	akar.koran_mendarat.connect(func(k: KoranLempar.Koran) -> void: mendarat.append(k))
	akar.atur_mode_bantu(true)
	var m: KoranLempar.Koran = _lempar_ke_titik(akar, 4.0, TITIK_MELESET, mendarat, true)
	check(m != null and m.bantu and akar.skor().terbuang == 1 and hud.teks_koin() == "-5" and akar.umpan_gambar().teks_tampil() == ["-5"], "koran bantu yang mendarat di aspal: terbuang 1, HUD '-5', umpan '-5' (aturan sama)")
	# Mode bantu yang mengenai sasaran tidak dipotong.
	_langkah(akar, 60)
	var sebelum: int = akar.skor().terbuang
	var k: KoranLempar.Koran = _lempar_ke_kotak(akar, 1.0, "per_buka_01@6", mendarat)
	check(k != null and akar.skor().terbuang == sebelum and akar.skor().koin == 15, "koran bantu yang kena rumah pelanggan: tidak terbuang")
	akar.main_lagi()
	check(akar.skor().terbuang == 0 and akar.skor().koin == 0 and hud.teks_koin() == "0" and akar.umpan_melayang().is_empty(), "Main lagi: terbuang 0, koin 0, HUD '0', umpan kosong")
	_bersihkan(akar)


func _test_hud_koin_negatif() -> void:
	_judul.call("HUD rute: koin bersih negatif tidak menutupi/bertumpuk (empat ukuran, kanan dan kidal): panel koin di layar, tidak menimpa panel skor dan progres")
	for kasus: Array in [[1600, 720, 800], [1920, 1080, 640], [2340, 1080, 780], [2400, 1080, 800]]:
		for kidal: bool in [false, true]:
			var akar: RuteMain = await _siapkan(Vector2i(kasus[0], kasus[1]))
			akar.atur_kidal(kidal)
			var hud: HudRute = akar.hud_rute()
			hud.tampilkan_skor(4478, 3, -1250, false)
			await _tree.process_frame
			await _tree.process_frame
			var layar: Rect2 = Rect2(Vector2.ZERO, Vector2(int(kasus[2]), 360))
			var koin: Rect2 = hud.rect_panel_koin()
			check(hud.teks_koin() == "-1.250" and layar.encloses(koin), "lebar %d kidal %s: '-1.250' tampil, panel koin %s di dalam layar" % [kasus[2], kidal, koin])
			check(not koin.intersects(hud.rect_panel_skor()) and not koin.intersects(hud.rect_panel_progres()) and not koin.intersects(hud.rect_panel_kondisi()), "lebar %d kidal %s: panel koin tidak menimpa panel skor, progres, atau kondisi" % [kasus[2], kidal])
			check(not koin.intersects(hud.rect_radar_seberang(), true) and not koin.intersects(hud.rect_radar_dekat(), true), "lebar %d kidal %s: panel koin tidak menimpa radar" % [kasus[2], kidal])
			_bersihkan(akar)


# --- Layar hasil (AC-11) ---

func _test_layar_hasil(kasus: Array) -> void:
	var lebar: int = kasus[2]
	_judul.call("Layar hasil %dx%d: baris koran terbuang, koin bersih (boleh minus), saldo dijepit; kasus terpadat muat (AC-11, AC-14)" % [kasus[0], kasus[1]])
	_tree.root.size = Vector2i(kasus[0], kasus[1])
	var layar: LayarHasil = (load(BERKAS_HASIL) as PackedScene).instantiate() as LayarHasil
	_tree.root.add_child(layar)
	await _tree.process_frame
	var kotak_layar: Rect2 = Rect2(Vector2.ZERO, Vector2(lebar, 360))
	# Tanpa koran terbuang: layar sama seperti sebelum run ini (tanpa baris potongan).
	layar.isi(_angka(25, 375, 0), null, [] as Array[String], 100)
	layar.tampilkan(true)
	await _tree.process_frame
	var harap: Array[String] = ["Hasil antaran", "Terkirim", "25/25", "Tip", "+0 dari 0 pelanggan", "Koin", "375", "Skor", "1.000", "Tepat", "0", "Meleset", "0", "Sampai sebelum tenggat"]
	check(layar.teks_tampil() == harap and layar.teks_potongan().is_empty(), "tanpa koran terbuang: tanpa baris potongan, daftar sama seperti dulu (dapat %s)" % [layar.teks_tampil()])
	# Hari minus: 25 terbuang, tidak ada antaran, saldo 40 -> dijepit.
	layar.isi(_angka(0, 0, 25), null, [] as Array[String], 40)
	await _tree.process_frame
	await _tree.process_frame
	check(layar.teks_potongan() == ["25 koran (-125)", "-125", "Saldo mulai lagi dari 0"], "hari minus: '25 koran (-125)', koin bersih '-125' (minus eksplisit), saldo dijepit (dapat %s)" % [layar.teks_potongan()])
	var teks_semua: String = " ".join(layar.teks_tampil()).to_lower()
	check(teks_semua.find("gagal") == -1 and teks_semua.find("kalah") == -1 and teks_semua.find("rugi") == -1, "nada netral: tanpa kata gagal, kalah, atau rugi (prinsip 2)")
	check(layar.teks_tampil().has("Koran terbuang") and layar.teks_tampil().has("Koin bersih") and layar.teks_tampil().has("Koin"), "baris 'Koran terbuang' dan 'Koin bersih' terpisah dari baris 'Koin' (ongkos/tip)")
	# Saldo cukup: tidak ada baris dijepit. Saldo tidak diketahui: tidak ada baris.
	layar.isi(_angka(20, 300, 5), null, [] as Array[String], 500)
	check(layar.teks_potongan() == ["5 koran (-25)", "275"], "bersih positif '275', saldo cukup: tanpa baris dijepit (dapat %s)" % [layar.teks_potongan()])
	layar.isi(_angka(0, 0, 25), null, [] as Array[String])
	check(layar.teks_potongan() == ["25 koran (-125)", "-125"], "saldo tidak diketahui (rute sendiri): tanpa baris dijepit")
	# Tepat di batas: saldo 125 - 125 = 0 -> tidak dijepit.
	layar.isi(_angka(0, 0, 25), null, [] as Array[String], 125)
	check(not layar.teks_potongan().has("Saldo mulai lagi dari 0"), "saldo 125 - 125 = 0 tepat: bukan penjepitan, tanpa baris")
	# Kasus terpadat: potongan + rekap misi selesai + tiga baris kondisi + saldo dijepit + tenggat lewat.
	var misi: DataMisi = PemuatMisi.muat_folder().cari("p1_kucing")
	var padat: HasilRute.Angka = _angka(3, 195, 30)
	padat.koin_misi = 75
	padat.misi_id = "p1_kucing"
	padat.misi_hasil = "selesai"
	padat.tenggat_lewat = true
	padat.detik_lewat = 125
	padat.koin_tip = 25
	padat.jumlah_tip = 5
	layar.isi(padat, misi, ["ban", "rem", "rantai"] as Array[String], 20)
	layar.atur_mode_hari(true)
	await _tree.process_frame
	await _tree.process_frame
	check(layar.teks_potongan() == ["30 koran (-150)", "45"], "kasus terpadat: koin 195 - 150 = 45 (positif, saldo 20 + 45 tidak dijepit): %s" % [layar.teks_potongan()])
	layar.isi(_angka(3, 0, 30), misi, ["ban", "rem", "rantai"] as Array[String], 20)
	await _tree.process_frame
	await _tree.process_frame
	check(layar.teks_potongan() == ["30 koran (-150)", "-150", "Saldo mulai lagi dari 0"], "kasus terpadat minus: tiga baris potongan tampil bersama rekap misi dan tiga baris kondisi: %s" % [layar.teks_potongan()])
	var tombol: Rect2 = layar.rect_tombol()
	var di_panel: bool = true
	for r: Rect2 in layar.rect_label():
		di_panel = di_panel and layar.rect_panel().encloses(r) and r.size.x > 0.0
	check(kotak_layar.encloses(layar.rect_panel()) and layar.rect_panel().encloses(tombol), "kasus terpadat lebar %d: panel %s di dalam layar 360 tinggi, tombol di dalam panel" % [lebar, layar.rect_panel()])
	check(tombol.size.x >= 42.0 and tombol.size.y >= 42.0 and kotak_layar.encloses(tombol), "kasus terpadat: tombol 'Ke bengkel' >= 42 px dan terlihat penuh (%s)" % [tombol])
	check(di_panel, "kasus terpadat: semua label (potongan, misi, kondisi, tenggat) di dalam panel")
	_tree.root.remove_child(layar)
	layar.free()


func _test_hasil_dari_rute() -> void:
	_judul.call("Scene rute: layar hasil terbuka membawa angka koran terbuang dari lemparan nyata (satu sumber HasilRute); tanpa save tidak ada baris dijepit")
	var akar: RuteMain = await _siapkan()
	var mendarat: Array[KoranLempar.Koran] = []
	akar.koran_mendarat.connect(func(k: KoranLempar.Koran) -> void: mendarat.append(k))
	_lempar_ke_titik(akar, 4.0, TITIK_MELESET, mendarat)
	_langkah(akar, 60)
	_lempar_ke_kotak(akar, 1.0, "per_buka_01@6", mendarat)
	_langkah(akar, 60)
	_lempar_ke_titik(akar, 4.0, TITIK_MELESET, mendarat)
	var sepeda: SepedaUji = _sepeda(akar)
	var kb: BikeMotion.Keadaan = sepeda.keadaan.salin()
	kb.kecepatan_ud = Config.KECEPATAN_SANTAI_UD
	sepeda.keadaan = kb
	sepeda.jarak_ubin = akar.rute().panjang_ubin - 0.01
	for i: int in range(900):
		if akar.hasil_tampil():
			break
		akar.perbarui(DT)
	var a: HasilRute.Angka = akar.angka_hasil()
	check(akar.hasil_tampil() and a != null and a.lempar_terbuang == 2 and a.potongan == 10 and a.koin == 15 and a.koin_bersih == 5, "hasil terbuka: 2 terbuang, potongan 10, koin 15, bersih 5 (dapat %s)" % [a.koin_bersih if a != null else -1])
	check(a.terkirim == 1 and a.meleset == 24, "terkirim 1, meleset (pelanggan) 24 terpisah dari 2 koran terbuang")
	check(akar.layar_hasil().teks_potongan() == ["2 koran (-10)", "5"], "layar hasil: '2 koran (-10)' dan bersih '5' (tanpa save: tanpa baris dijepit): %s" % [akar.layar_hasil().teks_potongan()])
	_bersihkan(akar)


# --- Alur hari (AC-10, AC-11) ---

func _jalur() -> String:
	return FOLDER_TES.path_join("save.json")


func _bersihkan_folder() -> void:
	var dir: DirAccess = DirAccess.open(FOLDER_TES)
	if dir == null:
		return
	for nama: String in dir.get_files():
		DirAccess.remove_absolute(FOLDER_TES.path_join(nama))
	DirAccess.remove_absolute(FOLDER_TES)


func _tulis_save(s: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(FOLDER_TES)
	var berkas: FileAccess = FileAccess.open(_jalur(), FileAccess.WRITE)
	berkas.store_string(DataSave.ke_teks(s))
	berkas.close()


func _baca_save() -> Dictionary:
	return DataSave.dari_teks(FileAccess.get_file_as_string(_jalur())).state


func _manajer() -> Node:
	var m: Node = (load(SKRIP_SIMPAN) as GDScript).new()
	m.set(&"jalur", _jalur())
	m.set(&"lapor_ke_log", false)
	m.call(&"muat", 1700000000)
	_simpanan_aktif.append(m)
	return m


func _siapkan_hari(m: Node) -> HariMain:
	_tree.root.size = Vector2i(2340, 1080)
	var hari: HariMain = (load(BERKAS_HARI) as PackedScene).instantiate() as HariMain
	hari.simpanan = m
	hari.panggil_quit = false
	_tree.root.add_child(hari)
	await _tree.process_frame
	await _tree.process_frame
	return hari


func _berangkat(hari: HariMain) -> RuteMain:
	hari.koran().tombol_berangkat().ditekan.emit()
	await _tree.process_frame
	await _tree.process_frame
	var rute: RuteMain = hari.rute()
	rute.set_process(false)
	(_anak(rute, "KontrolTouch") as KontrolTouch).keyboard_aktif = false
	(_anak(rute, "LoperAgen") as LoperSprite).set_process(false)
	return rute


## Mengisi skor hari ini dengan literal (`koin` kotor, `terbuang` koran terbuang, 3 pelanggan terantar) lalu menyelesaikan rute sampai layar hasil.
func _selesaikan(rute: RuteMain, koin: int, terbuang: int) -> void:
	var skor: SkorRute.Keadaan = rute.skor()
	skor.koin = koin
	skor.terbuang = terbuang
	skor.skor = 900
	for i: int in range(3):
		skor.terantar[rute.rute().pelanggan[i].id] = true
	var sepeda: SepedaUji = _sepeda(rute)
	var k: BikeMotion.Keadaan = sepeda.keadaan.salin()
	k.kecepatan_ud = Config.KECEPATAN_SANTAI_UD
	sepeda.keadaan = k
	sepeda.jarak_ubin = rute.rute().panjang_ubin - 0.01
	for i: int in range(900):
		if rute.hasil_tampil():
			return
		rute.perbarui(DT)


func _bersihkan_hari(hari: HariMain) -> void:
	_lepas_jari()
	var rute: RuteMain = hari.rute()
	if rute != null:
		if rute.sedang_jeda():
			rute.minta_lanjut()
		(_anak(rute, "KontrolTouch") as KontrolTouch).keyboard_aktif = OS.has_feature("editor")
	_tree.root.remove_child(hari)
	hari.free()


func _tutup_manajer(m: Node) -> void:
	_simpanan_aktif.erase(m)
	m.free()


func _test_alur_hari_minus() -> void:
	_judul.call("Alur hari minus (AC-10, AC-11): saldo 40, 30 koran terbuang (-150): hasil minus, saldo dijepit 0, bengkel 'Koin kurang' tetapi 'Hari berikutnya' aktif, save ditulis sekali")
	_bersihkan_folder()
	var s: Dictionary = DataSave.templat()
	s["koin"] = 40
	s["koin_total"] = 40
	_tulis_save(s)
	var sha_awal: String = FileAccess.get_sha256(_jalur())
	var m: Node = _manajer()
	var hari: HariMain = await _siapkan_hari(m)
	var rute: RuteMain = await _berangkat(hari)
	_selesaikan(rute, 0, 30)
	var a: HasilRute.Angka = rute.angka_hasil()
	check(rute.hasil_tampil() and a.koin == 0 and a.lempar_terbuang == 30 and a.potongan == 150 and a.koin_bersih == -150, "hasil: koin 0, 30 terbuang, potongan 150, bersih -150")
	check(rute.layar_hasil().teks_potongan() == ["30 koran (-150)", "-150", "Saldo mulai lagi dari 0"], "layar hasil memuat baris potongan, bersih -150, dan saldo mulai lagi dari 0: %s" % [rute.layar_hasil().teks_potongan()])
	check(FileAccess.get_sha256(_jalur()) == sha_awal, "layar hasil tidak menyimpan apa pun")
	rute.layar_hasil().tombol_main_lagi().ditekan.emit()
	var bengkel: LayarBengkel = hari.bengkel()
	check(bengkel != null and bengkel.teks_saldo() == "0", "bengkel terbuka dengan saldo 0 (dijepit), bukan negatif: '%s'" % [bengkel.teks_saldo() if bengkel != null else "-"])
	var semua_kurang: bool = true
	for id: String in ["ban_anti_selip", "rem_pakem", "rantai_hemat"]:
		var tombol: TombolSentuh = bengkel.tombol_beli(id)
		semua_kurang = semua_kurang and tombol != null and tombol.disabled and tombol.text == "Koin kurang"
	check(semua_kurang and not bengkel.tombol_hari_berikutnya().disabled, "upgrade nonaktif bertulis 'Koin kurang'; 'Hari berikutnya' tetap aktif (tidak ada keadaan buntu)")
	check(FileAccess.get_sha256(_jalur()) == sha_awal, "bengkel tidak menyimpan apa pun sebelum 'Hari berikutnya'")
	bengkel.tombol_hari_berikutnya().ditekan.emit()
	var baru: Dictionary = _baca_save()
	check(FileAccess.get_sha256(_jalur()) != sha_awal and int(baru["hari"]) == 2 and int(baru["koin"]) == 0 and int(baru["koin_total"]) == 40, "Hari berikutnya menulis save: hari 2, koin 0, koin_total 40 (hanya naik koin kotor 0)")
	check(int(baru["terakhir"]["potongan"]) == 150 and int(baru["terakhir"]["koin"]) == 0, "terakhir mencatat potongan 150 dan koin kotor 0")
	check(hari.status().keadaan == MesinHari.Keadaan.KORAN and hari.status().hari == 2 and hari.koran().tampil(), "layar koran hari 2 tampil; hari berikutnya tetap bisa dimainkan")
	_bersihkan_hari(hari)
	_tutup_manajer(m)
	_bersihkan_folder()


func _test_alur_hari_baik() -> void:
	_judul.call("Alur hari dengan potongan kecil (AC-10): saldo 800 + koin 120 - 25 = 895, koin_total + 120 (kotor), belanja memakai saldo bersih")
	_bersihkan_folder()
	var s: Dictionary = DataSave.templat()
	s["koin"] = 800
	s["koin_total"] = 1000
	_tulis_save(s)
	var m: Node = _manajer()
	var hari: HariMain = await _siapkan_hari(m)
	var rute: RuteMain = await _berangkat(hari)
	check(rute.hud_rute().teks_koin() == "0", "awal rute: HUD koin 0")
	_selesaikan(rute, 120, 5)
	check(rute.hud_rute().teks_koin() == "95" and rute.angka_hasil().koin_bersih == 95, "HUD koin bersih 95 (120 - 25) = angka hasil")
	check(rute.layar_hasil().teks_potongan() == ["5 koran (-25)", "95"], "layar hasil: '5 koran (-25)', bersih '95', tanpa baris dijepit: %s" % [rute.layar_hasil().teks_potongan()])
	rute.layar_hasil().tombol_main_lagi().ditekan.emit()
	var bengkel: LayarBengkel = hari.bengkel()
	check(bengkel.teks_saldo() == "895", "saldo awal bengkel 895 = 800 + 95, bukan 920: '%s'" % bengkel.teks_saldo())
	bengkel.tombol_hari_berikutnya().ditekan.emit()
	var baru: Dictionary = _baca_save()
	check(int(baru["koin"]) == 895 and int(baru["koin_total"]) == 1120 and int(baru["terakhir"]["potongan"]) == 25 and int(baru["terakhir"]["koin"]) == 120, "save: koin 895, koin_total 1120 (kotor), terakhir potongan 25 dan koin 120")
	_bersihkan_hari(hari)
	_tutup_manajer(m)
	_bersihkan_folder()
