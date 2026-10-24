class_name TesHiasan
extends RefCounted
## Tes hiasan lanjutan di depan garis akhir (run garis-finish-portal Bagian F, F-1, F-2, AC-13; usulan).
##
## Murni (`HiasanRute`): deterministik dari benih rute, rute utama tidak berubah, semua rumah bukan pelanggan, tempat dan lateral sah (jalur sepeda bebas), sambungan tepat di garis akhir, panjang
## menutupi jendela daur dan tepi viewport terjauh (tabel `TesGarisFinish.TABEL_VIEWPORT`), irama segmen (tanpa penutup, tanpa ulang, tanpa dua padat), masukan tidak sah, kode tanpa waktu/RNG global.
## Scene (`scenes/rute/rute.tscn` sungguhan, `perbarui(dt)` nyata): hiasan tergambar di depan portal di empat ukuran dan kidal, bukan pelanggan, tidak masuk radar, progres, zona, `Rute`, atau penerap
## selain sebagai penutup, Y-sort bersama sepeda, tanpa kotak surat oranye, dibekukan bersama jendela daur, dipulihkan oleh Main lagi, tanpa kebocoran node dalam 20 putaran.

const BERKAS_RUTE: String = "res://scenes/rute/rute.tscn"
const BERKAS_HIASAN: String = "res://scripts/systems/hiasan_rute.gd"
const FOLDER: String = "res://assets/data/routes/perumahan"
const DT: float = 1.0 / 60.0
const PANJANG_RUTE: float = 236.0
## [lebar jendela, tinggi jendela, lebar viewport game].
const JENDELA: Array = [[1920, 1080, 640], [2079, 1080, 693], [2340, 1080, 780], [2400, 1080, 800]]

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
	_test_murni_dasar()
	_test_murni_irama_dan_tempat()
	_test_murni_cakupan()
	_test_murni_masukan_dan_kode()
	await _test_scene_tergambar()
	await _test_scene_bukan_permainan()
	await _test_scene_beku_dan_pulih()
	await _test_scene_daur_20x()


# --- Pembantu ---

func _pustaka() -> Array[SegmenRute]:
	return PemuatRute.muat_folder(FOLDER).segmen


func _rute(benih: int, hari: int = 1) -> RouteBuilder.Rute:
	return RouteBuilder.bangun(benih, _pustaka(), hari).rute


func _sidik_rute(rute: RouteBuilder.Rute) -> String:
	var bagian: PackedStringArray = PackedStringArray()
	for r: RouteBuilder.RumahRute in rute.rumah:
		bagian.append("%s|%s|%s|%s" % [r.id, r.maju_ubin, r.jenis, r.pelanggan])
	for d: RouteBuilder.DekorItem in rute.dekor:
		bagian.append("%s|%s|%s" % [d.id, d.maju_ubin, d.varian])
	bagian.append("%s|%d|%d" % [rute.panjang_ubin, rute.pelanggan.size(), rute.segmen.size()])
	return "\n".join(bagian)


func _sidik_hiasan(h: RouteBuilder.Rute) -> String:
	var bagian: PackedStringArray = PackedStringArray()
	for r: RouteBuilder.RumahRute in h.rumah:
		bagian.append("%s|%s|%s|%d" % [r.id, r.maju_ubin, r.jenis, r.sisi])
	for d: RouteBuilder.DekorItem in h.dekor:
		bagian.append("%s|%s|%s|%s" % [d.id, d.maju_ubin, d.jenis, d.varian])
	return "\n".join(bagian)


# --- Murni ---

func _test_murni_dasar() -> void:
	_judul.call("HiasanRute (murni): deterministik, rute utama tidak berubah, semua rumah bukan pelanggan, bersambung tepat di garis akhir")
	var pustaka: Array[SegmenRute] = _pustaka()
	check(pustaka.size() == 9, "pustaka nyata punya 9 segmen (%d)" % pustaka.size())
	var semua_ok: bool = true
	var catatan: String = ""
	var beda_benih: bool = false
	var sidik_pertama: String = ""
	for benih: int in range(1, 121):
		var rute: RouteBuilder.Rute = _rute(benih, 1 + benih % 6)
		var sebelum: String = _sidik_rute(rute)
		var a: RouteBuilder.Rute = HiasanRute.bangun(rute, pustaka)
		var b: RouteBuilder.Rute = HiasanRute.bangun(rute, pustaka)
		if _sidik_rute(rute) != sebelum:
			semua_ok = false
			catatan += " [benih %d: rute utama berubah]" % benih
		if _sidik_hiasan(a) != _sidik_hiasan(b):
			semua_ok = false
			catatan += " [benih %d: tidak deterministik]" % benih
		if a.rumah.is_empty() or a.dekor.is_empty():
			semua_ok = false
			catatan += " [benih %d: hiasan kosong]" % benih
		var ids: Dictionary = {}
		var urut: bool = true
		var sebelumnya: float = -INF
		for r: RouteBuilder.RumahRute in a.rumah:
			if r.pelanggan or r.pelanggan_boleh or r.pemberi_tip or r.maju_ubin < rute.panjang_ubin or ids.has(r.id) or r.maju_ubin < sebelumnya:
				urut = false
			ids[r.id] = true
			sebelumnya = r.maju_ubin
		for d: RouteBuilder.DekorItem in a.dekor:
			if d.maju_ubin < rute.panjang_ubin or ids.has(d.id):
				urut = false
			ids[d.id] = true
		if not urut:
			semua_ok = false
			catatan += " [benih %d: rumah/dekor tidak sah (pelanggan, di belakang garis, id ganda, atau tidak urut)]" % benih
		if not a.pelanggan.is_empty() or not a.objek.is_empty() or not a.titik_misi.is_empty() or not a.simpang.is_empty() or a.koran_awal != 0 or not a.id_pemberi_tip.is_empty():
			semua_ok = false
			catatan += " [benih %d: hiasan membawa pelanggan, rintangan, misi, simpang, atau tip]" % benih
		if a.awal_segmen.is_empty() or a.awal_segmen[0] != rute.panjang_ubin:
			semua_ok = false
			catatan += " [benih %d: segmen pertama tidak mulai di garis akhir]" % benih
		if benih == 1:
			sidik_pertama = _sidik_hiasan(a)
		elif _sidik_hiasan(a) != sidik_pertama:
			beda_benih = true
	check(semua_ok, "120 benih x hari 1..6: rute utama tidak berubah, deterministik, rumah bukan pelanggan, di depan garis, id unik, tanpa pelanggan/rintangan/misi/simpang/tip.%s" % catatan)
	check(beda_benih, "benih berbeda menghasilkan hiasan berbeda (bukan satu susunan tetap)")
	# Rute utama identik dengan golden rute (tidak ada yang memanggil RNG rute): sidik bangun sama sebelum dan sesudah hiasan disusun.
	var r1: RouteBuilder.Rute = _rute(20261016)
	var s1: String = _sidik_rute(r1)
	HiasanRute.bangun(r1, pustaka)
	check(_sidik_rute(_rute(20261016)) == s1, "RouteBuilder.bangun seed 20261016 tidak terpengaruh penyusunan hiasan")
	# Literal: pembuka seed 20261016: hiasan mulai di maju = panjang rute.
	var h: RouteBuilder.Rute = HiasanRute.bangun(r1, pustaka)
	check(h.panjang_ubin >= r1.panjang_ubin + float(Config.RUTE_HIASAN_PANJANG_UBIN) and h.panjang_ubin < r1.panjang_ubin + float(Config.RUTE_HIASAN_PANJANG_UBIN) + 40.0, "panjang hiasan seed 20261016: %.0f ubin sesudah garis (>= 32, < 72)" % (h.panjang_ubin - r1.panjang_ubin))


func _test_murni_irama_dan_tempat() -> void:
	_judul.call("HiasanRute (murni): segmen bukan penutup, tidak sama dengan segmen sebelumnya, tidak dua padat; dekor di luar lajur sepeda, rumah di luar jalur")
	var pustaka: Array[SegmenRute] = _pustaka()
	var pelanggaran: int = 0
	var padat_hiasan: int = 0
	var catatan: String = ""
	var lateral_min: float = INF
	var kavling_masuk_jalur: int = 0
	for benih: int in range(1, 201):
		var rute: RouteBuilder.Rute = _rute(benih)
		var urutan: Array[SegmenRute] = HiasanRute.pilih_segmen(rute, pustaka)
		var sebelumnya: SegmenRute = rute.segmen[rute.segmen.size() - 1]
		for segmen: SegmenRute in urutan:
			if segmen.posisi == SegmenRute.Posisi.PENUTUP or segmen.id == sebelumnya.id:
				pelanggaran += 1
				catatan += " [benih %d: segmen %s tidak boleh sesudah %s]" % [benih, segmen.id, sebelumnya.id]
			if segmen.tingkat == SegmenRute.Tingkat.PADAT and sebelumnya.tingkat == SegmenRute.Tingkat.PADAT:
				padat_hiasan += 1
			sebelumnya = segmen
		var h: RouteBuilder.Rute = HiasanRute.bangun(rute, pustaka)
		for d: RouteBuilder.DekorItem in h.dekor:
			lateral_min = minf(lateral_min, absf(d.lateral_ubin))
		for r: RouteBuilder.RumahRute in h.rumah:
			var tapak: Rect2 = SegmenRute.kavling_rumah(r.sisi, 0.0)
			var jalur: Rect2 = Rect2(-Config.RUTE_DEKOR_LAJUR_UBIN, -1000.0, Config.RUTE_DEKOR_LAJUR_UBIN * 2.0, 2000.0)
			if tapak.intersects(jalur):
				kavling_masuk_jalur += 1
	check(pelanggaran == 0, "200 benih: segmen hiasan bukan penutup dan tidak sama dengan segmen sebelumnya.%s" % catatan)
	check(padat_hiasan == 0, "200 benih: tidak ada dua segmen padat berurutan (garis akhir ke hiasan, dan di dalam hiasan): %d" % padat_hiasan)
	check(lateral_min >= Config.RUTE_DEKOR_LAJUR_UBIN, "semua dekor hiasan di luar lajur sepeda (lateral terdekat %.3f >= %.1f)" % [lateral_min, Config.RUTE_DEKOR_LAJUR_UBIN])
	check(kavling_masuk_jalur == 0, "tapak semua rumah hiasan di luar lajur sepeda (|lateral| >= %.1f)" % Config.RUTE_DEKOR_LAJUR_UBIN)
	var ada_dekat: bool = false
	var ada_seberang: bool = false
	var h2: RouteBuilder.Rute = HiasanRute.bangun(_rute(20261016), pustaka)
	for r: RouteBuilder.RumahRute in h2.rumah:
		ada_dekat = ada_dekat or r.sisi == LoperAnim.Sisi.DEKAT
		ada_seberang = ada_seberang or r.sisi == LoperAnim.Sisi.SEBERANG
	check(ada_dekat and ada_seberang, "hiasan seed 20261016 punya rumah di kedua sisi jalan")


func _test_murni_cakupan() -> void:
	_judul.call("HiasanRute (murni): panjang hiasan menutupi jendela daur ke depan dan tepi viewport terjauh dari kamera yang beku di garis (empat lebar x tiga geseran)")
	check(Config.RUTE_HIASAN_PANJANG_UBIN >= Config.RUTE_DAUR_MAJU_UBIN, "RUTE_HIASAN_PANJANG_UBIN %d >= jendela daur ke depan %d" % [Config.RUTE_HIASAN_PANJANG_UBIN, Config.RUTE_DAUR_MAJU_UBIN])
	var terjauh: float = 0.0
	for baris: Array in TesGarisFinish.TABEL_VIEWPORT:
		terjauh = maxf(terjauh, float(baris[6]))
	check(terjauh > 17.3 and terjauh < 17.4, "tepi terjauh dari tabel viewport: %.4f ubin di depan sepeda di garis" % terjauh)
	var pustaka: Array[SegmenRute] = _pustaka()
	var kurang: int = 0
	var celah_maks: float = 0.0
	for benih: int in range(1, 201):
		var rute: RouteBuilder.Rute = _rute(benih)
		var h: RouteBuilder.Rute = HiasanRute.bangun(rute, pustaka)
		if h.panjang_ubin - rute.panjang_ubin < terjauh + 3.0:
			kurang += 1
		# Celah terpanjang tanpa rumah (kedua sisi) antara garis akhir dan tepi terjauh: hiasan tidak boleh meninggalkan lubang besar tanpa rumah.
		var batas: float = rute.panjang_ubin + terjauh + 3.0
		var sebelumnya: float = rute.panjang_ubin
		for r: RouteBuilder.RumahRute in h.rumah:
			if r.maju_ubin > batas:
				break
			celah_maks = maxf(celah_maks, r.maju_ubin - sebelumnya)
			sebelumnya = r.maju_ubin
	check(kurang == 0, "200 benih: hiasan sedikitnya terjauh + 3 ubin (%.1f) di depan garis" % (terjauh + 3.0))
	check(celah_maks <= 12.0, "200 benih: celah terpanjang tanpa rumah di antara garis akhir dan tepi terjauh <= 12 ubin (dapat %.1f)" % celah_maks)


func _test_murni_masukan_dan_kode() -> void:
	_judul.call("HiasanRute (murni): masukan tidak sah, dan kode tanpa waktu, RNG global, atau kelas skor/tenggat/radar/progres/save")
	var pustaka: Array[SegmenRute] = _pustaka()
	var kosong: Array[SegmenRute] = []
	var rute: RouteBuilder.Rute = _rute(7)
	check(HiasanRute.bangun(null, pustaka).rumah.is_empty(), "rute null: hiasan kosong")
	check(HiasanRute.bangun(rute, kosong).rumah.is_empty() and HiasanRute.bangun(rute, kosong).panjang_ubin == rute.panjang_ubin, "pustaka kosong: hiasan kosong, panjang = panjang rute")
	var nol: RouteBuilder.Rute = RouteBuilder.Rute.new()
	check(HiasanRute.bangun(nol, pustaka).rumah.is_empty(), "rute tanpa panjang (gagal disusun): hiasan kosong")
	var nan: RouteBuilder.Rute = RouteBuilder.Rute.new()
	nan.panjang_ubin = NAN
	check(HiasanRute.bangun(nan, pustaka).rumah.is_empty(), "panjang rute NaN: hiasan kosong")
	# Pustaka hanya penutup: tetap menyusun (cadangan semua segmen), tidak crash.
	var hanya_penutup: Array[SegmenRute] = []
	for s: SegmenRute in pustaka:
		if s.posisi == SegmenRute.Posisi.PENUTUP:
			hanya_penutup.append(s)
	check(not HiasanRute.bangun(rute, hanya_penutup).rumah.is_empty(), "pustaka hanya penutup: cadangan memakai semua segmen, hiasan tersusun")
	var teks: String = FileAccess.get_file_as_string(BERKAS_HIASAN)
	var kode: String = ""
	for baris: String in teks.split("\n"):
		var potong: String = baris.strip_edges()
		if potong.begins_with("##") or potong.begins_with("#"):
			continue
		kode += baris + "\n"
	var terlarang: Array[String] = []
	for nama: String in ["SkorRute", "TenggatRute", "ProgresRute", "RadarRute", "KondisiRute", "BikeCondition", "MissionManager", "SaveManager", "DataSave", "HasilRute", "ZonaSasaran", "MedanKoran", "RintanganRute", "Time.", "randi()", "randf()", "randomize"]:
		if kode.contains(nama):
			terlarang.append(nama)
	check(terlarang.is_empty(), "kode hiasan_rute.gd tanpa kelas permainan, Time, atau RNG global: %s" % [terlarang])
	check(Config.RUTE_HIASAN_SEED_SELISIH == 104729 and Config.RUTE_HIASAN_SEGMEN_MAKS == 4 and Config.RUTE_HIASAN_COBA_MAKS == 24 and Config.RUTE_HIASAN_PANJANG_UBIN == 32, "konstanta hiasan literal: panjang 32, seed +104729, maks 4 segmen, 24 undian")


# --- Scene ---

func _siapkan(jendela: Vector2i) -> RuteMain:
	_tree.root.size = jendela
	var akar: RuteMain = (load(BERKAS_RUTE) as PackedScene).instantiate() as RuteMain
	_tree.root.add_child(akar)
	await _tree.process_frame
	await _tree.process_frame
	akar.set_process(false)
	(akar.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = false
	(akar.find_child("LoperAgen", true, false) as LoperSprite).set_process(false)
	akar.atur_benih_awal(akar.benih())
	return akar


func _bersihkan(akar: RuteMain) -> void:
	(akar.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = OS.has_feature("editor")
	_tree.root.remove_child(akar)
	akar.free()


func _sepeda(akar: RuteMain) -> SepedaUji:
	return akar.find_child("Sepeda", true, false) as SepedaUji


func _taruh(akar: RuteMain, v: float, maju: float) -> void:
	var sepeda: SepedaUji = _sepeda(akar)
	var k: BikeMotion.Keadaan = sepeda.keadaan.salin()
	k.kecepatan_ud = v
	sepeda.keadaan = k
	sepeda.jarak_ubin = maju


## Sprite hiasan yang sedang tampil (rumah dan dekor), titik pijak GLOBAL (koordinat layar tanpa kamera = piksel dunia) -> posisi di viewport lewat kamera.
func _sprite_hiasan(akar: RuteMain) -> Array[Sprite2D]:
	var hasil: Array[Sprite2D] = []
	for i: int in akar.rumah_hiasan().indeks_tampil():
		hasil.append(akar.rumah_hiasan().sprite_rumah(i))
	for i: int in akar.dekor_hiasan().indeks_tampil():
		hasil.append(akar.dekor_hiasan().sprite_dekor(i))
	return hasil


func _test_scene_tergambar() -> void:
	_judul.call("Scene: hiasan tergambar di depan portal sesudah garis di empat ukuran x kanan/kidal, bukan pelanggan, Y-sort bersama sepeda, penerap yang sama")
	for j: Array in JENDELA:
		for kidal: bool in [false, true]:
			var tag: String = "%dx%d %s" % [j[0], j[1], "kidal" if kidal else "kanan"]
			var akar: RuteMain = await _siapkan(Vector2i(j[0], j[1]))
			akar.atur_kidal(kidal)
			var ukuran: Vector2 = akar.get_viewport_rect().size
			var kamera: Camera2D = akar.find_child("Kamera", true, false) as Camera2D
			check(int(ukuran.x) == int(j[2]), "%s: viewport selebar %d" % [tag, int(j[2])])
			var rute: RouteBuilder.Rute = akar.rute()
			var hiasan: RouteBuilder.Rute = akar.hiasan()
			check(not hiasan.rumah.is_empty() and hiasan.awal_segmen[0] == rute.panjang_ubin, "%s: rute hiasan ada dan mulai di garis akhir" % tag)
			check(akar.rumah_hiasan().get_parent() == akar.daur() and akar.dekor_hiasan().get_parent() == akar.daur() and akar.rumah_hiasan().y_sort_enabled and akar.dekor_hiasan().y_sort_enabled and akar.daur().y_sort_enabled, "%s: hiasan anak induk Y-sort yang sama dengan sepeda, portal, dan rumah" % tag)
			_taruh(akar, 6.0, PANJANG_RUTE - 0.2)
			for i: int in range(40):
				akar.perbarui(DT)
			check(akar.rute_sudah_selesai() and akar.kamera_beku(), "%s: garis tercapai dan kamera beku" % tag)
			# Hiasan tampil di depan portal: sprite di jendela daur beku, sebagian jatuh dalam viewport yang dilihat kamera beku.
			var rect: Rect2 = Rect2(Vector2.ZERO, ukuran)
			var terlihat_rumah: int = 0
			var terlihat_dekor: int = 0
			var maju_terjauh: float = 0.0
			for i: int in akar.rumah_hiasan().indeks_tampil():
				var s: Sprite2D = akar.rumah_hiasan().sprite_rumah(i)
				var layar: Vector2 = s.global_position - kamera.position + ukuran / 2.0
				var kotak: Rect2 = Rect2(layar + s.offset, s.texture.get_size())
				if rect.intersects(kotak):
					terlihat_rumah += 1
					maju_terjauh = maxf(maju_terjauh, hiasan.rumah[i].maju_ubin - rute.panjang_ubin)
			for i: int in akar.dekor_hiasan().indeks_tampil():
				var s2: Sprite2D = akar.dekor_hiasan().sprite_dekor(i)
				var layar2: Vector2 = s2.global_position - kamera.position + ukuran / 2.0
				var kotak2: Rect2 = Rect2(layar2 + s2.offset, s2.texture.get_size())
				if rect.intersects(kotak2):
					terlihat_dekor += 1
			check(terlihat_rumah >= 3 and terlihat_dekor >= 1, "%s: sesudah garis sedikitnya 3 rumah dan 1 dekor hiasan terlihat di viewport kamera beku (rumah %d, dekor %d)" % [tag, terlihat_rumah, terlihat_dekor])
			check(maju_terjauh >= 8.0, "%s: rumah hiasan terlihat sampai %.1f ubin di depan garis (>= 8)" % [tag, maju_terjauh])
			# Tidak ada sprite hiasan yang hilang di dalam viewport sebelum tepi terjauh: semua rumah/dekor hiasan dalam jarak <= terjauh + 3 punya node (jendela daur menutupi).
			var kurang: int = 0
			var terjauh: float = AkhirRute.rentang_maju_terlihat(AkhirRute.posisi_layar(_sepeda(akar).position, kamera.position, ukuran), ukuran).y
			for idx: int in range(hiasan.rumah.size()):
				if hiasan.rumah[idx].maju_ubin <= akar.jarak_beku() + minf(terjauh + 3.0, float(Config.RUTE_DAUR_MAJU_UBIN)) and akar.rumah_hiasan().sprite_rumah(idx) == null:
					kurang += 1
			check(kurang == 0, "%s: setiap rumah hiasan sampai %.1f ubin di depan sepeda punya sprite (hilang %d)" % [tag, terjauh + 3.0, kurang])
			var semua_bukan: bool = true
			for idx: int in akar.rumah_hiasan().indeks_tampil():
				var s3: Sprite2D = akar.rumah_hiasan().sprite_rumah(idx)
				if not String(s3.texture.resource_path).ends_with("_bukan.png"):
					semua_bukan = false
			check(semua_bukan, "%s: semua sprite rumah hiasan = varian _bukan (bukan pelanggan)" % tag)
			check(akar.rumah_hiasan().jumlah_kotak_surat() == 0 and akar.rumah_hiasan().jumlah_kotak_surat_bukan() > 0, "%s: hiasan tanpa kotak surat sasaran (oranye 0), kotak abu-abu %d" % [tag, akar.rumah_hiasan().jumlah_kotak_surat_bukan()])
			# Penerap yang sama: rumah dan dekor dekat hiasan terdaftar (penutup pemain), seberang tidak (dekor).
			var penerap: PenerapPenutup = akar.penerap_penutup()
			var rumah_terdaftar: bool = true
			for idx: int in akar.rumah_hiasan().indeks_tampil():
				if penerap.objek_untuk(akar.rumah_hiasan().sprite_rumah(idx)) == null:
					rumah_terdaftar = false
			check(rumah_terdaftar, "%s: tiap rumah hiasan terdaftar di penerap penutup yang sama" % tag)
			var dekat_terdaftar: bool = true
			for idx: int in akar.dekor_hiasan().indeks_tampil():
				var butir: RouteBuilder.DekorItem = hiasan.dekor[idx]
				var harus: bool = DekorRute.menutupi(butir.jenis, butir.varian, butir.sisi)
				if (penerap.objek_untuk(akar.dekor_hiasan().sprite_dekor(idx)) != null) != harus:
					dekat_terdaftar = false
			check(dekat_terdaftar, "%s: dekor hiasan terdaftar di penerap tepat bila menutupi (sisi dekat)" % tag)
			_bersihkan(akar)


func _test_scene_bukan_permainan() -> void:
	_judul.call("Scene: hiasan tidak masuk Rute, radar, progres, zona sasaran, skor, atau pelanggan; rute utama sama dengan RouteBuilder.bangun mandiri")
	var akar: RuteMain = await _siapkan(Vector2i(2340, 1080))
	var rute: RouteBuilder.Rute = akar.rute()
	var mandiri: RouteBuilder.Rute = RouteBuilder.bangun(akar.benih(), _pustaka(), akar.hari()).rute
	check(_sidik_rute(rute) == _sidik_rute(mandiri), "rute scene = RouteBuilder.bangun mandiri (rumah, dekor, panjang, pelanggan, segmen identik)")
	var id_hiasan: Dictionary = {}
	for r: RouteBuilder.RumahRute in akar.hiasan().rumah:
		id_hiasan[r.id] = true
	var bocor: int = 0
	for r: RouteBuilder.RumahRute in rute.rumah:
		if id_hiasan.has(r.id):
			bocor += 1
	for r: RouteBuilder.RumahRute in rute.pelanggan:
		if id_hiasan.has(r.id):
			bocor += 1
	check(bocor == 0 and rute.pelanggan.size() == Config.RUTE_PELANGGAN, "tidak ada rumah hiasan di Rute.rumah atau Rute.pelanggan; pelanggan tetap %d" % rute.pelanggan.size())
	_taruh(akar, 6.0, PANJANG_RUTE - 0.2)
	for i: int in range(120):
		akar.perbarui(DT)
	# Radar dan progres dihitung dari rute utama: sama di garis dan di depan garis, kosong; progres 25 kotak.
	var terantar: Dictionary = akar.skor().terantar
	var progres: Array[ProgresRute.Status] = ProgresRute.status(rute, akar.jarak_beku(), terantar, true)
	check(progres.size() == Config.RUTE_PELANGGAN, "progres tetap %d kotak walau hiasan tergambar (%d)" % [Config.RUTE_PELANGGAN, progres.size()])
	var radar: Array[RadarRute.Penanda] = RadarRute.penanda(rute, _sepeda(akar).jarak_ubin, terantar, true, false)
	check(radar.is_empty(), "radar kosong di depan garis walau hiasan tergambar (hiasan bukan pelanggan)")
	# Zona sasaran: tidak ada zona di depan garis (hiasan bukan sasaran); koran yang dilempar ke rumah hiasan tidak terantar.
	var zona: Array[ZonaSasaran.Zona] = ZonaSasaran.zona_rute_rentang(rute.rumah, PANJANG_RUTE, PANJANG_RUTE + 40.0)
	var zona_hiasan: int = 0
	for z: ZonaSasaran.Zona in zona:
		if id_hiasan.has(z.id_rumah):
			zona_hiasan += 1
	check(zona_hiasan == 0, "zona sasaran dari Rute.rumah tidak memuat rumah hiasan (%d)" % zona_hiasan)
	check(akar.skor().terantar.is_empty() and akar.skor().skor == 0, "skor dan antaran tidak berubah oleh hiasan (skor %d, terantar %d)" % [akar.skor().skor, akar.skor().terantar.size()])
	_bersihkan(akar)


func _test_scene_beku_dan_pulih() -> void:
	_judul.call("Scene: jendela hiasan beku bersama jendela daur sesudah garis; Main lagi memulihkan (hiasan seed baru, jendela kembali ke awal, kosong di awal rute)")
	var akar: RuteMain = await _siapkan(Vector2i(2340, 1080))
	check(akar.rumah_hiasan().jumlah_rumah() == 0 and akar.dekor_hiasan().jumlah_tampil() == 0, "di awal rute (jarak 0) belum ada sprite hiasan tergambar")
	_taruh(akar, 6.0, PANJANG_RUTE - 0.2)
	for i: int in range(10):
		akar.perbarui(DT)
	var rumah: Array[int] = akar.rumah_hiasan().indeks_tampil()
	var dekor: Array[int] = akar.dekor_hiasan().indeks_tampil()
	check(not rumah.is_empty() and not dekor.is_empty(), "sesudah garis: %d rumah dan %d dekor hiasan tergambar" % [rumah.size(), dekor.size()])
	for i: int in range(120):
		akar.perbarui(DT)
	check(akar.rumah_hiasan().indeks_tampil() == rumah and akar.dekor_hiasan().indeks_tampil() == dekor and _sepeda(akar).jarak_ubin > akar.jarak_beku() + 3.0, "120 langkah keluar: jendela hiasan tidak berubah (dunia beku) walau sepeda menempuh %.1f ubin lagi" % (_sepeda(akar).jarak_ubin - akar.jarak_beku()))
	var sidik_lama: String = _sidik_hiasan(akar.hiasan())
	var benih_lama: int = akar.benih()
	akar.main_lagi()
	check(akar.benih() == benih_lama + 1 and _sidik_hiasan(akar.hiasan()) != sidik_lama, "Main lagi: seed + 1 dan hiasan baru disusun untuk rute baru")
	check(akar.rumah_hiasan().jumlah_rumah() == 0 and akar.dekor_hiasan().jumlah_tampil() == 0 and not akar.kamera_beku(), "Main lagi: jendela hiasan kembali kosong di awal rute, kamera mengikuti lagi")
	var hiasan_baru: RouteBuilder.Rute = HiasanRute.bangun(akar.rute(), _pustaka())
	check(_sidik_hiasan(akar.hiasan()) == _sidik_hiasan(hiasan_baru), "hiasan sesudah Main lagi = HiasanRute.bangun mandiri untuk rute baru")
	_bersihkan(akar)


func _test_scene_daur_20x() -> void:
	_judul.call("Scene: 20 putaran garis -> hasil -> Main lagi tanpa kebocoran node hiasan, penerap tidak menumpuk")
	var akar: RuteMain = await _siapkan(Vector2i(2340, 1080))
	var penerap: PenerapPenutup = akar.penerap_penutup()
	var rumah_node: Array[int] = []
	var dekor_node: Array[int] = []
	var penerap_sesudah: Array[int] = []
	var anak: Array[int] = []
	for putaran: int in range(20):
		_taruh(akar, 6.0, akar.rute().panjang_ubin - 0.2)
		var langkah: int = 0
		while langkah < 600 and not akar.hasil_tampil():
			akar.perbarui(DT)
			langkah += 1
		check(akar.hasil_tampil(), "putaran %d: hasil terbuka" % putaran)
		if putaran >= 2:
			rumah_node.append(akar.rumah_hiasan().jumlah_node_rumah())
			dekor_node.append(akar.dekor_hiasan().jumlah_node())
		akar.main_lagi()
		penerap_sesudah.append(penerap.jumlah())
		anak.append(akar.daur().get_child_count() + akar.rumah_hiasan().get_child_count() + akar.dekor_hiasan().get_child_count())
	var rumah_maks: int = rumah_node.max()
	var dekor_maks: int = dekor_node.max()
	check(rumah_maks <= 40 and dekor_maks <= 24, "node rumah hiasan paling banyak %d (<= 40) dan dekor hiasan %d (<= 24) dalam 20 putaran (kolam dipakai ulang)" % [rumah_maks, dekor_maks])
	check(anak.max() - anak.min() <= 40, "jumlah anak Objek + hiasan stabil dalam 20 putaran (selisih %d)" % (anak.max() - anak.min()))
	check(penerap_sesudah.max() - penerap_sesudah.min() <= 12, "penerap tidak menumpuk sesudah Main lagi (min %d, maks %d)" % [penerap_sesudah.min(), penerap_sesudah.max()])
	_bersihkan(akar)
