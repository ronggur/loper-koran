class_name TesGarisFinishScene
extends RefCounted
## Tes scene garis finish dengan portal, bagian C (run garis-finish-portal; G-1 sampai G-6, AC-5 sampai AC-8, AC-11): `scenes/rute/rute.tscn` sungguhan, langkah `perbarui(dt)` nyata.
##
## - G-5 (AC-7): bot `PembantuGoldenGaris` menjalankan delapan kasus sampai layar hasil di scene INI dan angkanya dibandingkan dengan golden dari perilaku LAMA (`tests/data/golden_garis_main.json`,
##   dibangkitkan `ukur_golden_garis.gd` pada checkout `main`: sepeda direm di garis, hasil terbuka saat berhenti). Skor, koin, tip, tenggat, kondisi, progres, radar, misi, dan angka hasil harus identik.
## - Keluar viewport di empat ukuran jendela dan kidal, dua laju: sinyal berurutan (garis, banner, hasil), kamera tidak bergeser sama sekali, stick dan jari diabaikan, tanpa rem, laju >= laju minimum,
##   sepeda sungguh di luar viewport saat hasil (kotak badan literal dari PNG), tanpa lubang tanah (oracle independen dari posisi sprite ubin), jeda dan back, Main lagi dan alur hari memulihkan awal.
## - Portal: bingkai menurut jarak, letak, penerap penutup, dan oracle piksel (tidak ada piksel opak portal di atas piksel pemain tanpa kotak penutup menutupi).

const BERKAS_RUTE: String = "res://scenes/rute/rute.tscn"
const BERKAS_GOLDEN: String = "res://tests/data/golden_garis_main.json"
const BERKAS_PORTAL_JSON: String = "res://assets/sprites/props/prop_portal_satpam.json"
const BERKAS_PORTAL_PNG: String = "res://assets/sprites/props/prop_portal_satpam.png"
const DT: float = 1.0 / 60.0
const PANJANG_RUTE: float = 236.0
## [lebar jendela, tinggi jendela, lebar viewport game].
const JENDELA: Array = [[1920, 1080, 640], [2340, 1080, 780], [2400, 1080, 800], [1600, 720, 800]]
## Kotak badan sepeda relatif titik pijak (literal dari PNG, dihitung di `tes_garis_finish`): kiri 18, kanan 16, atas 43, bawah 8.
const BADAN: Rect2 = Rect2(-18.0, -43.0, 34.0, 51.0)

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
	await _test_golden_g5()
	await _test_portal_scene()
	_test_portal_penutup_piksel()
	await _test_keluar_empat_ukuran()
	await _test_tanpa_lubang_tanah()
	await _test_masukan_dikunci()
	await _test_laju_minimum_dan_tutorial()
	await _test_keluar_cepat_walau_rusak_dan_lelah()
	await _test_rintangan_nonaktif_sesudah_garis()
	await _test_jeda_saat_keluar()
	await _test_koran_terbang_menunda_hasil()
	await _test_main_lagi_memulihkan()
	await _test_alur_hari_memulihkan()
	await _test_jendela_daur_beku()


# --- Pembantu ---

func _siapkan(jendela: Vector2i = Vector2i(2340, 1080)) -> RuteMain:
	_tree.root.size = jendela
	var akar: RuteMain = (load(BERKAS_RUTE) as PackedScene).instantiate() as RuteMain
	_tree.root.add_child(akar)
	await _tree.process_frame
	await _tree.process_frame
	akar.set_process(false)
	(akar.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = false
	(akar.find_child("LoperAgen", true, false) as LoperSprite).set_process(false)
	akar.atur_benih_awal(akar.benih())
	PembantuGoldenGaris.skala_jendela = _skala(akar)
	return akar


func _bersihkan(akar: RuteMain) -> void:
	for i: int in range(8):
		PembantuGoldenGaris.sentuh(i, Vector2(-50, -50), false)
	if akar.sedang_jeda():
		akar.minta_lanjut()
	(akar.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = OS.has_feature("editor")
	_tree.root.remove_child(akar)
	akar.free()


func _sepeda(akar: RuteMain) -> SepedaUji:
	return akar.find_child("Sepeda", true, false) as SepedaUji


func _kamera(akar: RuteMain) -> Camera2D:
	return akar.find_child("Kamera", true, false) as Camera2D


func _taruh(akar: RuteMain, v: float, lateral: float, maju: float) -> void:
	var sepeda: SepedaUji = _sepeda(akar)
	var k: BikeMotion.Keadaan = sepeda.keadaan.salin()
	k.kecepatan_ud = v
	k.lateral_ubin = lateral
	sepeda.keadaan = k
	sepeda.jarak_ubin = maju


func _langkah(akar: RuteMain, jumlah: int, dt: float = DT) -> void:
	for i: int in range(jumlah):
		akar.perbarui(dt)


## Titik tengah zona stick (koordinat viewport game) untuk lebar `lebar` dan tangan `kidal`.
func _titik_stick(lebar: int, kidal: bool) -> Vector2:
	return TouchZones.rect_stick(lebar, kidal).get_center()


func _skala(akar: RuteMain) -> int:
	return roundi(float(_tree.root.size.x) / akar.get_viewport_rect().size.x)


## Selisih rekursif dua nilai hasil JSON (jalur tiap perbedaan).
func _beda(a: Variant, b: Variant, jalur: String = "") -> Array[String]:
	var hasil: Array[String] = []
	if typeof(a) == TYPE_DICTIONARY and typeof(b) == TYPE_DICTIONARY:
		var da: Dictionary = a
		var db: Dictionary = b
		for k: Variant in da.keys():
			if not db.has(k):
				hasil.append("%s/%s hilang" % [jalur, k])
			else:
				hasil.append_array(_beda(da[k], db[k], "%s/%s" % [jalur, k]))
		for k: Variant in db.keys():
			if not da.has(k):
				hasil.append("%s/%s tambahan" % [jalur, k])
	elif typeof(a) == TYPE_ARRAY and typeof(b) == TYPE_ARRAY:
		var xa: Array = a
		var xb: Array = b
		if xa.size() != xb.size():
			hasil.append("%s ukuran %d != %d" % [jalur, xa.size(), xb.size()])
		else:
			for i: int in range(xa.size()):
				hasil.append_array(_beda(xa[i], xb[i], "%s[%d]" % [jalur, i]))
	elif a != b:
		hasil.append("%s: %s != %s" % [jalur, str(a), str(b)])
	return hasil


# --- G-5: identik dengan perilaku lama ---

func _test_golden_g5() -> void:
	_judul.call("G-5 (AC-7): delapan kasus bot sampai layar hasil di scene baru = golden perilaku LAMA dari main (skor, koin, tip, tenggat, kondisi, progres, radar, misi, angka hasil)")
	var golden: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BERKAS_GOLDEN)) as Dictionary
	var kasus_golden: Array = golden["kasus"]
	check(String(golden["commit_main"]).length() == 40 and kasus_golden.size() == PembantuGoldenGaris.KASUS.size() and kasus_golden.size() == 8, "golden berasal dari satu commit main (40 heksa) dan memuat delapan kasus bot yang sama dengan pembantu")
	var tabrak_sebelum: int = 0
	var tenggat_lewat: int = 0
	var tepat: int = 0
	var terbuang_berubah: int = 0
	var misi_gagal: int = 0
	var kondisi_aus: int = 0
	for i: int in range(kasus_golden.size()):
		var g: Dictionary = kasus_golden[i]
		var satu: Dictionary = await PembantuGoldenGaris.jalankan(_tree, PembantuGoldenGaris.KASUS[i])
		var baru: Dictionary = JSON.parse_string(JSON.stringify(satu)) as Dictionary
		var selisih: Array[String] = _beda(g, baru)
		check(selisih.is_empty(), "kasus %s: semua angka (garis akhir dan layar hasil) identik dengan golden main; selisih: %s" % [g["nama"], selisih.slice(0, 5)])
		check(bool(baru["hasil_terbuka"]) and int(baru["tabrakan_sesudah_garis"]) == 0, "kasus %s: layar hasil terbuka dan tidak ada tabrakan sesudah garis akhir" % g["nama"])
		var angka: Dictionary = g["angka"]
		tabrak_sebelum += 1 if int(g["tabrakan_sebelum_garis"]) > 0 else 0
		tenggat_lewat += 1 if bool(angka["tenggat_lewat"]) else 0
		tepat += 1 if int(angka["jumlah_tepat"]) > 0 else 0
		misi_gagal += 1 if String(angka["misi_hasil"]) == "gagal" else 0
		terbuang_berubah += 1 if int((g["garis"] as Dictionary)["terbuang"]) != int((g["hasil"] as Dictionary)["terbuang"]) else 0
		kondisi_aus += 1 if float(((g["hasil"] as Dictionary)["kondisi"] as Dictionary)["ban"]) < 0.95 else 0
	check(tabrak_sebelum >= 3 and tenggat_lewat >= 1 and tepat >= 6 and misi_gagal >= 2 and terbuang_berubah >= 5 and kondisi_aus >= 3, "kasus golden tidak sepele: tabrakan %d, tenggat lewat %d, antaran tepat %d, misi gagal %d, koran mendarat sesudah garis %d, ban aus %d" % [tabrak_sebelum, tenggat_lewat, tepat, misi_gagal, terbuang_berubah, kondisi_aus])


# --- Portal ---

func _test_portal_scene() -> void:
	_judul.call("Portal di scene rute: anak Objek (Y-sort), tekstur dan sel = JSON, letak di garis akhir, bingkai menurut jarak, terdaftar di penerap penutup (AC-6)")
	var akar: RuteMain = await _siapkan()
	var portal: PortalGaris = akar.portal()
	var objek: Node2D = akar.find_child("Objek", true, false) as Node2D
	var json: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BERKAS_PORTAL_JSON)) as Dictionary
	check(portal != null and portal.get_parent() == objek and objek.y_sort_enabled and portal.visible and portal.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "node Portal anak Objek (induk Y-sort bersama rumah dan sepeda), terlihat, filter Nearest")
	var sel: Array = json["cell"]
	var pijak: Array = json["ground_anchor"]
	check(portal.texture.resource_path == BERKAS_PORTAL_PNG and portal.texture.get_size() == Vector2(float(sel[0]) * float(json["frames"]), float(sel[1])) and portal.hframes == int(json["frames"]) and portal.hframes == 2, "tekstur prop_portal_satpam.png (dimuat scene, bukan saat jalan), dua frame berjajar, ukuran = sel x frame JSON")
	check(Config.RUTE_PORTAL_SEL_PX == ([int(sel[0]), int(sel[1])] as Array[int]) and Config.RUTE_PORTAL_PIJAK_PX == ([int(pijak[0]), int(pijak[1])] as Array[int]) and Config.RUTE_PORTAL_FRAME == int(json["frames"]), "Config sel, pijak, dan jumlah frame portal = JSON aset (80x92, pijak (14, 60), 2 frame)")
	check(portal.offset == -Vector2(float(pijak[0]), float(pijak[1])) and not portal.centered, "titik pijak (kaki tiang) di origin node: offset = -pijak, tidak di-center")
	check(PANJANG_RUTE == akar.rute().panjang_ubin and portal.position == Iso.posisi_gambar(Vector2(Config.RUTE_PORTAL_LATERAL_UBIN, -PANJANG_RUTE)) and Config.RUTE_PORTAL_LATERAL_UBIN == -2.0, "portal di garis akhir (maju 236) pada lateral -2,0 (tepi seberang jalur sepeda, palang membentang ke jalan)")
	check(portal.position == Vector2(round((-2.0 - -236.0) * 32.0), round((-2.0 + -236.0) * 16.0)), "posisi gambar = proyeksi iso 2:1 titik (-2, -236), dihitung sendiri: x = (lateral - y) x 32, y = (lateral + y) x 16")
	var kotak: PenutupPemain.Objek = akar.penerap_penutup().objek_untuk(portal)
	check(kotak != null and kotak.tapak == Rect2(-2.75, 235.25, 1.5, 1.5) and kotak.tinggi_ubin == 1.78125, "portal terdaftar di SATU penerap penutup dengan kotak tapak (-2,75; 235,25; 1,5x1,5) setinggi 1,78125 ubin (57 piksel palang terangkat / 32)")
	# Bingkai menurut jarak (naik, sebelum melewati garis): tertutup jauh, terbuka tepat 6,0 ubin sebelum garis (inklusif).
	var kasus: Array = [[0.0, 0], [100.0, 0], [200.0, 0], [229.9, 0], [230.0, 1], [233.0, 1], [235.9, 1]]
	var salah: Array[String] = []
	for k: Array in kasus:
		_taruh(akar, 3.0, 0.0, float(k[0]))
		akar.perbarui(0.0)
		if portal.bingkai() != int(k[1]):
			salah.append("jarak %.1f: bingkai %d, harap %d" % [k[0], portal.bingkai(), k[1]])
	check(salah.is_empty(), "bingkai portal: tertutup sampai 6,0 ubin dari garis (230 = terbuka), terbuka sesudahnya: %s" % [salah])
	_taruh(akar, 3.0, 0.0, 237.0)
	akar.perbarui(0.0)
	check(portal.bingkai() == 1, "sesudah garis portal tetap terbuka")
	var jumlah_penerap: int = akar.penerap_penutup().jumlah()
	portal.atur_rute(0.0)
	check(not portal.visible and akar.penerap_penutup().jumlah() == jumlah_penerap - 1 and akar.penerap_penutup().objek_untuk(portal) == null, "panjang rute 0 (rute gagal disusun): portal tidak digambar dan keluar dari penerap")
	_bersihkan(akar)


## Topeng piksel opak satu frame portal (frame `f`, kanvas bersama dengan pijak dari JSON).
func _topeng_portal(f: int) -> UkurPenutupPiksel.Topeng:
	var gambar: Image = (load(BERKAS_PORTAL_PNG) as Texture2D).get_image()
	var t: UkurPenutupPiksel.Topeng = UkurPenutupPiksel.Topeng.new()
	t.lebar = 80
	t.tinggi = 92
	t.pijak = Vector2i(14, 60)
	t.data.resize(80 * 92)
	for y: int in range(92):
		for x: int in range(80):
			t.data[y * 80 + x] = 1 if gambar.get_pixel(f * 80 + x, y).a >= UkurPenutupPiksel.ALFA_OPAK else 0
	t.selesai()
	return t


func _test_portal_penutup_piksel() -> void:
	_judul.call("Portal dan pemain (AC-6, oracle piksel): tidak ada posisi (lateral -2,0 sampai 2,0, maju 6 ubin di sekitar garis) dengan piksel opak portal di atas piksel pemain tanpa kotak penutup menutupi")
	var panjang: float = 100.0
	var kotak: PenutupPemain.Objek = PortalGaris.kotak_penutup(panjang)
	var pemain: UkurPenutupPiksel.Topeng = UkurPenutupPiksel.topeng_pemain()
	var pos_portal: Vector2i = UkurPenutupPiksel.layar(Config.RUTE_PORTAL_LATERAL_UBIN, panjang)
	var y_portal: float = UkurPenutupPiksel.y_urut(Config.RUTE_PORTAL_LATERAL_UBIN, panjang)
	var kasus: Array = [[1, -6.0, 6.0, kotak], [0, -9.0, -6.0, kotak]]
	var tumpang_total: int = 0
	for k: Array in kasus:
		var topeng: UkurPenutupPiksel.Topeng = _topeng_portal(int(k[0]))
		var tak_tertutup: int = 0
		var tumpang: int = 0
		var diperiksa: int = 0
		for i: int in range(-16, 17):
			var lateral: float = float(i) * 0.125
			for j: int in range(roundi(float(k[1]) * 16.0), roundi(float(k[2]) * 16.0) + 1):
				var maju: float = panjang + float(j) / 16.0
				diperiksa += 1
				if y_portal < UkurPenutupPiksel.y_urut(lateral, maju):
					continue
				var piksel: int = UkurPenutupPiksel.hitung_tumpang(topeng, pos_portal, pemain, UkurPenutupPiksel.layar(lateral, maju))
				if piksel <= 0:
					continue
				tumpang += 1
				if not PenutupPemain.menutupi(Vector2(lateral, -maju), kotak):
					tak_tertutup += 1
		tumpang_total += tumpang
		check(diperiksa > 1000 and tak_tertutup == 0, "frame %d: %d posisi diperiksa, %d dengan piksel portal di atas piksel pemain, %d di antaranya tanpa kotak penutup menutupi (harus 0)" % [k[0], diperiksa, tumpang, tak_tertutup])
	# Kontrol: kotak yang terlalu kecil (tapak 0,1 dan tinggi 0,5) memang meninggalkan piksel tertutup, jadi sapuan mampu mendeteksi.
	var kecil: PenutupPemain.Objek = PenutupPemain.buat(Rect2(Config.RUTE_PORTAL_LATERAL_UBIN - 0.05, panjang - 0.05, 0.1, 0.1), 0.5, "kecil")
	var topeng_buka: UkurPenutupPiksel.Topeng = _topeng_portal(1)
	var buruk: int = 0
	for i: int in range(-16, 17):
		for j: int in range(-96, 97):
			var lateral: float = float(i) * 0.125
			var maju: float = panjang + float(j) / 16.0
			if y_portal < UkurPenutupPiksel.y_urut(lateral, maju):
				continue
			if UkurPenutupPiksel.hitung_tumpang(topeng_buka, pos_portal, pemain, UkurPenutupPiksel.layar(lateral, maju)) > 0 and not PenutupPemain.menutupi(Vector2(lateral, -maju), kecil):
				buruk += 1
	check(tumpang_total > 20 and buruk > 20, "kontrol: %d posisi bertumpuk di sapuan, kotak yang terlalu kecil menyisakan %d posisi tertimpa (oracle mampu mendeteksi)" % [tumpang_total, buruk])


# --- Keluar viewport di empat ukuran ---

func _test_keluar_empat_ukuran() -> void:
	_judul.call("Sepeda keluar viewport sesudah garis (AC-5, AC-8): empat ukuran jendela x kanan/kidal x laju santai dan ngebut; sinyal berurutan, kamera tidak bergeser, stick diabaikan, tanpa rem")
	for j: Array in JENDELA:
		for kidal: bool in [false, true]:
			for laju: float in [Config.KECEPATAN_SANTAI_UD, Config.KECEPATAN_NGEBUT_UD]:
				await _satu_keluar(j, kidal, laju)


func _satu_keluar(jendela: Array, kidal: bool, laju: float) -> void:
	var tag: String = "%dx%d %s v %.1f" % [jendela[0], jendela[1], "kidal" if kidal else "kanan", laju]
	var akar: RuteMain = await _siapkan(Vector2i(jendela[0], jendela[1]))
	var lebar: int = int(jendela[2])
	akar.atur_kidal(kidal)
	var ukuran: Vector2 = akar.get_viewport_rect().size
	var skala: int = _skala(akar)
	var sepeda: SepedaUji = _sepeda(akar)
	var kamera: Camera2D = _kamera(akar)
	var urutan: Array[String] = []
	akar.rute_selesai.connect(func() -> void: urutan.append("selesai"))
	akar.hasil_dibuka.connect(func(_a: HasilRute.Angka) -> void: urutan.append("hasil"))
	_taruh(akar, laju, 0.0, PANJANG_RUTE - 1.0)
	# Jempol menahan stick ke depan sebelum garis (kecepatan ngebut), lalu menarik ke kiri-bawah (rem + belok) sesudahnya.
	var titik: Vector2 = _titik_stick(lebar, kidal)
	PembantuGoldenGaris.sentuh(0, titik, true)
	PembantuGoldenGaris.geser(0, titik + Vector2(0, -30))
	var langkah: int = 0
	var langkah_selesai: int = -1
	var langkah_banner: int = -1
	var langkah_hasil: int = -1
	var kamera_garis: Vector2 = Vector2.ZERO
	var geser_garis: Vector2 = Vector2.ZERO
	var lateral_garis: float = 0.0
	var kamera_bergeser: int = 0
	var rem_terlihat: int = 0
	var laju_min: float = INF
	var animasi_salah: int = 0
	var sisa_sebelum_hasil: float = INF
	var koran_awal: int = akar.koran.sisa
	var audio: Node = _tree.root.get_node_or_null(^"Audio")
	var laju_garis: float = 0.0
	var daftar_rintangan: int = akar.rintangan().daftar.size()
	while langkah < 900 and not akar.hasil_tampil():
		akar.perbarui(DT)
		langkah += 1
		if akar.rute_sudah_selesai() and langkah_selesai < 0:
			langkah_selesai = langkah
			kamera_garis = kamera.position
			geser_garis = akar.geser_dorongan()
			lateral_garis = sepeda.lateral_ubin
			laju_garis = sepeda.kecepatan_ud
			check(not akar.kontrol_router().stick_aktif() and akar.kontrol_router().jumlah_jari_aktif() == 0, "%s: di garis semua jari dilepas dari router (stick tidak aktif, tidak ada jari)" % tag)
			check(kamera.position == AkhirRute.posisi_kamera(sepeda.position, ukuran, akar.geser_dorongan()) and akar.kamera_beku(), "%s: kamera dibekukan di garis = AkhirRute.posisi_kamera (posisi gambar sepeda, geseran dorongan saat itu)" % tag)
			PembantuGoldenGaris.geser(0, titik + Vector2(-35 if not kidal else 35, 40))
			check(not akar.panel_akhir().tampil(), "%s: banner BELUM tampil di garis akhir" % tag)
		if langkah_selesai > 0:
			if kamera.position != kamera_garis or akar.geser_dorongan() != geser_garis:
				kamera_bergeser += 1
			if sepeda.rem_aktif():
				rem_terlihat += 1
			if langkah > langkah_selesai:
				laju_min = minf(laju_min, sepeda.kecepatan_ud)
			var nama: String = String(sepeda.nama_animasi())
			if nama.contains("rem") or nama.contains("berhenti"):
				animasi_salah += 1
			if akar.panel_akhir().tampil() and langkah_banner < 0:
				langkah_banner = langkah
			if not akar.hasil_tampil():
				sisa_sebelum_hasil = AkhirRute.sisa_ubin_keluar(akar.posisi_layar_sepeda(), ukuran)
	langkah_hasil = langkah
	check(urutan == ["selesai", "hasil"] and akar.hasil_tampil(), "%s: sinyal rute_selesai tepat sekali lalu hasil_dibuka tepat sekali (%s)" % [tag, urutan])
	check(langkah_selesai > 0 and langkah_banner > langkah_selesai and langkah_banner < langkah_hasil, "%s: banner muncul sesudah garis dan SEBELUM layar hasil (langkah garis %d, banner %d, hasil %d)" % [tag, langkah_selesai, langkah_banner, langkah_hasil])
	check(kamera_bergeser == 0 and kamera.position == kamera_garis, "%s: kamera dan geseran dorongan tidak bergeser sama sekali sesudah garis (%d langkah beda)" % [tag, kamera_bergeser])
	check(sepeda.lateral_ubin == lateral_garis and rem_terlihat == 0 and animasi_salah == 0, "%s: jempol menarik kiri-bawah diabaikan: lateral tetap, rem tidak pernah aktif (%d), animasi bukan rem atau berhenti (%d)" % [tag, rem_terlihat, animasi_salah])
	check(laju_min >= minf(laju_garis, Config.RUTE_KELUAR_LAJU_MIN_UD) - 0.0001 and (laju < Config.KECEPATAN_NGEBUT_UD or laju_min >= laju_garis - 0.0001), "%s: stick buatan lurus ke depan menjaga laju (ngebut tidak melambat: terendah %.3f dari %.3f di garis)" % [tag, laju_min, laju_garis])
	check(laju_min >= Config.RUTE_KELUAR_LAJU_MIN_UD - 0.0001 and laju_min >= 6.0 - 0.0001, "%s: sejak langkah pertama sesudah garis laju tidak turun di bawah 6,0 u/d (level ngebut, F-3; terendah %.3f)" % [tag, laju_min])
	check(sisa_sebelum_hasil > 0.0 and AkhirRute.sisa_ubin_keluar(akar.posisi_layar_sepeda(), ukuran) == 0.0, "%s: satu langkah sebelum hasil sepeda masih sebagian di layar (sisa %.2f ubin), saat hasil seluruhnya di luar" % [tag, sisa_sebelum_hasil])
	var pijak: Vector2 = akar.posisi_layar_sepeda()
	var badan: Rect2 = Rect2(pijak + BADAN.position, BADAN.size)
	check(not Rect2(Vector2.ZERO, ukuran).intersects(badan) and (badan.position.x >= ukuran.x or badan.end.y <= 0.0), "%s: kotak badan sepeda %s tidak beririsan dengan viewport %s saat hasil terbuka (keluar lewat tepi kanan/atas)" % [tag, badan, ukuran])
	check(float(langkah_hasil - langkah_selesai) * DT <= 3.0 and not akar.panel_akhir().tampil() and akar.koran.sisa == koran_awal, "%s: dari garis ke hasil %.2f detik (<= 3,0, F-3; sebelumnya 6,0), banner disembunyikan saat hasil, koran tidak terpakai" % [tag, float(langkah_hasil - langkah_selesai) * DT])
	check(skala >= 2 and Vector2(lebar, 360) == ukuran, "%s: viewport game %dx360, skala bulat %d" % [tag, lebar, skala])
	_langkah(akar, 30)
	check(kamera.position == kamera_garis and akar.hasil_tampil() and akar.rintangan().daftar.size() == daftar_rintangan, "%s: layar hasil tetap terbuka dan dunia tetap beku 30 langkah sesudahnya (rintangan %d tetap)" % [tag, daftar_rintangan])
	if audio != null:
		check(int(audio.call(&"loop_aktif")) == int(BunyiSepeda.Loop.DIAM), "%s: bunyi sepeda senyap sesudah layar hasil terbuka (sepeda sudah di luar layar)" % tag)
	_bersihkan(akar)


# --- Tanah tanpa lubang ---

## Kumpulan sel tanah (kolom, baris) yang digambar sprite ubin `TanahDaur`: pusat dunia dari posisi gambar global tiap sprite.
func _sel_tanah(akar: RuteMain) -> Dictionary:
	var tanah: TanahDaur = akar.find_child("Tanah", true, false) as TanahDaur
	var sel: Dictionary = {}
	for wadah: Node in tanah.get_children():
		for anak: Node in wadah.get_children():
			var s: Sprite2D = anak as Sprite2D
			if s == null or not s.visible:
				continue
			var pusat: Vector2 = Iso.layar_ke_dunia(s.global_position)
			sel[Vector2i(floori(pusat.x), roundi(pusat.y))] = true
	return sel


## Jumlah titik sampel viewport (kamera `kamera`, ukuran `ukuran`) yang tidak tertutup sel tanah mana pun.
func _titik_bolong(sel: Dictionary, kamera: Vector2, ukuran: Vector2) -> int:
	var bolong: int = 0
	var y: float = 0.0
	while y <= ukuran.y:
		var x: float = 0.0
		while x <= ukuran.x:
			var dunia: Vector2 = Iso.layar_ke_dunia(kamera - ukuran / 2 + Vector2(x, y))
			if not sel.has(Vector2i(floori(dunia.x), roundi(dunia.y))):
				bolong += 1
			x += 12.0
		y += 12.0
	return bolong


func _test_tanpa_lubang_tanah() -> void:
	_judul.call("Tanah di belakang portal (G-5, AC-6): sepanjang sepeda keluar tidak ada lubang di area terlihat, di empat ukuran; kontrol: blok yang ikut sepeda ke depan memang menimbulkan lubang")
	for j: Array in JENDELA:
		var akar: RuteMain = await _siapkan(Vector2i(j[0], j[1]))
		var ukuran: Vector2 = akar.get_viewport_rect().size
		var kamera: Camera2D = _kamera(akar)
		_taruh(akar, Config.KECEPATAN_NGEBUT_UD, 0.0, PANJANG_RUTE - 3.0)
		# Kontrol sebelum garis: kamera mengikuti, tanah tanpa lubang.
		akar.perbarui(DT)
		var sebelum: int = _titik_bolong(_sel_tanah(akar), kamera.position, ukuran)
		var bolong: int = 0
		var diperiksa: int = 0
		var blok_pertama: Dictionary = {}
		var blok_beda: int = 0
		for i: int in range(500):
			akar.perbarui(DT)
			if akar.rute_sudah_selesai():
				var sel: Dictionary = _sel_tanah(akar)
				if blok_pertama.is_empty():
					blok_pertama = sel
				elif sel != blok_pertama:
					blok_beda += 1
				if i % 7 == 0 or akar.hasil_tampil():
					bolong += _titik_bolong(sel, kamera.position, ukuran)
					diperiksa += 1
			if akar.hasil_tampil():
				break
		check(sebelum == 0 and diperiksa > 15 and bolong == 0 and blok_beda == 0, "%dx%d: titik sampel tanpa ubin: %d sebelum garis, %d di %d pemeriksaan sesudah garis; blok ubin berubah %d kali (harus 0)" % [j[0], j[1], sebelum, bolong, diperiksa, blok_beda])
		# Kontrol: tanah yang ikut sepeda ke depan 18 ubin (perilaku tanpa pembekuan) meninggalkan lubang di kamera yang beku.
		var tanah: TanahDaur = akar.find_child("Tanah", true, false) as TanahDaur
		tanah.perbarui(akar.jarak_beku() + 18.0)
		var kontrol: int = _titik_bolong(_sel_tanah(akar), kamera.position, ukuran)
		check(kontrol > 20, "%dx%d: kontrol, blok tanah digeser 18 ubin ke depan meninggalkan %d titik tanpa ubin (oracle mampu mendeteksi lubang)" % [j[0], j[1], kontrol])
		_bersihkan(akar)


# --- Masukan dikunci ---

func _test_masukan_dikunci() -> void:
	_judul.call("Sesudah garis akhir (AC-5): stick sungguhan, swipe, tap mode bantu, dan bel tidak berpengaruh; kontrol sentuh tidak membaca sentuhan")
	var akar: RuteMain = await _siapkan()
	var catatan: Array = [0, 0, 0]
	akar.koran_dilempar.connect(func(_l: ThrowSolver.Lintasan) -> void: catatan[0] += 1)
	akar.bantu_tanpa_sasaran.connect(func(_p: Vector2) -> void: catatan[1] += 1)
	akar.bel_berbunyi.connect(func(_b: Bel.Bunyi, _r: Array[int]) -> void: catatan[2] += 1)
	akar.atur_mode_bantu(true)
	var kontrol: KontrolTouch = akar.find_child("KontrolTouch", true, false) as KontrolTouch
	var sepeda: SepedaUji = _sepeda(akar)
	_taruh(akar, 4.5, 0.5, 222.0)
	akar.koran = SisaKoran.awal(30)
	akar.perbarui(0.0)
	# Kontrol sebelum garis: tap mode bantu dan swipe memang melempar (rute di dekat pelanggan terakhir).
	check(bool(akar.call(&"_lempar_terbuka")) and kontrol.is_processing_input(), "kontrol sebelum garis: lemparan terbuka dan kontrol sentuh membaca sentuhan")
	_taruh(akar, 4.5, 0.5, PANJANG_RUTE - 0.2)
	_langkah(akar, 20)
	check(akar.rute_sudah_selesai() and not kontrol.is_processing_input(), "garis tercapai: kontrol sentuh tidak membaca sentuhan lagi")
	var lateral: float = sepeda.lateral_ubin
	var sisa: int = akar.koran.sisa
	var bel_awal: int = akar.bel().jumlah
	var skala: int = _skala(akar)
	# Jari nyata: stick penuh kiri, atas, bawah; swipe; tap bantu; tap bel.
	for arah: Vector2 in [Vector2(-60, 0), Vector2(0, -60), Vector2(0, 60), Vector2(60, 60)]:
		PembantuGoldenGaris.sentuh(0, Vector2(100, 260), true)
		PembantuGoldenGaris.geser(0, Vector2(100, 260) + arah)
		_langkah(akar, 10)
		check(not akar.kontrol_router().stick_aktif() and sepeda.lateral_ubin == lateral and not sepeda.rem_aktif() and sepeda.kecepatan_ud >= Config.RUTE_KELUAR_LAJU_MIN_UD, "stick penuh ke %s sesudah garis: router tidak aktif, lateral tetap, tanpa rem, laju %.2f" % [arah, sepeda.kecepatan_ud])
		PembantuGoldenGaris.sentuh(0, Vector2(100, 260) + arah, false)
	PembantuGoldenGaris.sentuh(3, Vector2(560, 200), true)
	PembantuGoldenGaris.geser(3, Vector2(640, 150))
	_langkah(akar, 2)
	PembantuGoldenGaris.sentuh(3, Vector2(640, 150), false)
	PembantuGoldenGaris.sentuh(2, akar.posisi_layar_sepeda() + Vector2(200, -150), true)
	PembantuGoldenGaris.sentuh(2, akar.posisi_layar_sepeda() + Vector2(200, -150), false)
	PembantuGoldenGaris.sentuh(1, Vector2(float(akar.get_viewport_rect().size.x) - 64.0, 296.0), true)
	PembantuGoldenGaris.sentuh(1, Vector2(float(akar.get_viewport_rect().size.x) - 64.0, 296.0), false)
	_langkah(akar, 2)
	check(catatan[0] == 0 and akar.koran.sisa == sisa and catatan[1] == 0 and catatan[2] == 0 and akar.bel().jumlah == bel_awal and not akar.garis_bidik().tampil(), "swipe, tap bantu, dan tap bel (jari nyata): tidak ada lemparan (%d), koran tetap %d, tanda tanpa sasaran %d, bel %d" % [catatan[0], akar.koran.sisa, catatan[1], catatan[2]])
	# Panggilan langsung ke penangan (jalur kode, bukan jari): ditolak oleh penjaga di scene.
	akar.call(&"_saat_swipe_selesai", Vector2(560, 200), Vector2(640, 150), 0.1)
	akar.call(&"_saat_tap_selesai", akar.posisi_layar_sepeda() + Vector2(200, -150), 0.05)
	check(catatan[0] == 0 and akar.koran.sisa == sisa and catatan[1] == 0 and not bool(akar.call(&"_lempar_terbuka")), "penangan swipe dan tap dipanggil langsung sesudah garis: ditolak (lemparan tidak terbuka)")
	check(akar.ketuk_bel() == Bel.Bunyi.TOLAK and akar.bel().jumlah == bel_awal and catatan[2] == 0, "ketuk_bel sesudah garis: TOLAK, tanpa bunyi dan tanpa reaksi rintangan")
	check(skala >= 2 and not akar.sedang_jeda(), "tidak ada jeda tak sengaja dari semua sentuhan itu")
	_bersihkan(akar)


# --- Laju minimum dan tutorial ---

func _test_laju_minimum_dan_tutorial() -> void:
	_judul.call("Laju minimum sesudah garis (G-2) dari laju 0, dan tutorial hari 1 tidak lagi berjalan sesudah garis")
	var akar: RuteMain = await _siapkan()
	_taruh(akar, 0.0, 0.0, PANJANG_RUTE + 0.3)
	akar.perbarui(DT)
	check(akar.rute_sudah_selesai() and _sepeda(akar).kecepatan_ud < Config.RUTE_KELUAR_LAJU_MIN_UD, "kondisi uji: garis terlewati dengan sepeda hampir diam (%.2f u/d)" % _sepeda(akar).kecepatan_ud)
	akar.perbarui(DT)
	check(_sepeda(akar).kecepatan_ud >= Config.RUTE_KELUAR_LAJU_MIN_UD - 0.0001, "langkah pertama sesudah garis menaikkan laju ke laju minimum (%.3f)" % _sepeda(akar).kecepatan_ud)
	_bersihkan(akar)
	var akar2: RuteMain = (load(BERKAS_RUTE) as PackedScene).instantiate() as RuteMain
	akar2.atur_tutorial(true)
	_tree.root.add_child(akar2)
	await _tree.process_frame
	akar2.set_process(false)
	(akar2.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = false
	(akar2.find_child("LoperAgen", true, false) as LoperSprite).set_process(false)
	akar2.atur_benih_awal(akar2.benih())
	_taruh(akar2, 6.0, 0.0, PANJANG_RUTE - 0.3)
	_langkah(akar2, 12)
	check(akar2.rute_sudah_selesai() and akar2.keadaan_tutorial() != null, "kondisi uji: tutorial hari 1 aktif dan garis terlewati")
	var keadaan: TutorialLangkah.Keadaan = akar2.keadaan_tutorial()
	_langkah(akar2, 60)
	check(akar2.keadaan_tutorial() == keadaan, "tutorial membeku sesudah garis akhir (keadaan tidak diganti lagi)")
	_bersihkan(akar2)


## F-3: sepeda rusak (kondisi 0,05 semua komponen: efek terburuk) dan lelah (stamina 0) tetap keluar dengan 6,0 u/d, stamina dan kondisi tidak berubah sesudah garis, efek kondisi hanya dilepas sesudah garis.
func _test_keluar_cepat_walau_rusak_dan_lelah() -> void:
	_judul.call("F-3: sepeda rusak dan lelah tetap keluar dengan laju ngebut; efek kondisi dilepas hanya sesudah garis; stamina dan kondisi dibekukan di garis")
	for rusak: bool in [false, true]:
		var akar: RuteMain = await _siapkan()
		if rusak:
			var daftar: Array[DataToko] = []
			akar.atur_sepeda(PembantuGoldenGaris.state_sepeda(0.05), 1, daftar)
		var sepeda: SepedaUji = _sepeda(akar)
		_taruh(akar, 3.0, 0.0, PANJANG_RUTE - 4.0)
		var k: BikeMotion.Keadaan = sepeda.keadaan.salin()
		k.stamina = 0.0
		k.lelah = true
		sepeda.keadaan = k
		var efek_sebelum: Variant = akar.call(&"_efek_gerak")
		check(efek_sebelum != null, "kondisi uji: sebelum garis efek kondisi dipakai (rusak %s)" % rusak)
		var langkah: int = 0
		while langkah < 400 and not akar.rute_sudah_selesai():
			akar.perbarui(DT)
			langkah += 1
		check(akar.rute_sudah_selesai(), "rusak %s: garis tercapai" % rusak)
		check(akar.call(&"_efek_gerak") == null, "rusak %s: efek kondisi dilepas sesudah garis (null)" % rusak)
		var kondisi_garis: Dictionary = akar.kondisi_akhir()
		var stamina_garis: float = sepeda.stamina()
		var laju_min: float = INF
		var stamina_maks_turun: float = 0.0
		var lelah_menyala: int = 0
		var hasil_langkah: int = 0
		while hasil_langkah < 900 and not akar.hasil_tampil():
			akar.perbarui(DT)
			hasil_langkah += 1
			laju_min = minf(laju_min, sepeda.kecepatan_ud)
			stamina_maks_turun = maxf(stamina_maks_turun, stamina_garis - sepeda.stamina())
			lelah_menyala += 1 if (sepeda.lelah() and stamina_garis > 0.0) else 0
		check(akar.hasil_tampil() and float(hasil_langkah) * DT <= 3.0, "rusak %s lelah stamina 0: hasil terbuka %.2f detik sesudah garis (<= 3,0)" % [rusak, float(hasil_langkah) * DT])
		check(laju_min >= 6.0 - 0.0001, "rusak %s lelah: laju tidak pernah di bawah 6,0 sesudah garis (terendah %.3f)" % [rusak, laju_min])
		check(akar.kondisi_akhir() == kondisi_garis, "rusak %s: kondisi sepeda tidak berubah sesudah garis (G-5)" % rusak)
		check(stamina_maks_turun <= 12.0 * DT + 0.0001 and lelah_menyala == 0, "rusak %s: stamina tidak terkuras sesudah garis (turun paling banyak %.4f, lelah menyala %d)" % [rusak, stamina_maks_turun, lelah_menyala])
		_bersihkan(akar)


# --- Rintangan sesudah garis ---

func _test_rintangan_nonaktif_sesudah_garis() -> void:
	_judul.call("Rintangan sesudah garis akhir (G-5): tidak ada tabrakan baru dan kondisi sepeda tidak berubah; kontrol sebelum garis menabrak; jam jatuh yang sedang berjalan tetap maju")
	var hasil: Array = []
	for sesudah: bool in [false, true]:
		var akar: RuteMain = await _siapkan()
		var objek: Array[RouteBuilder.ObjekRute] = []
		var o: RouteBuilder.ObjekRute = RouteBuilder.ObjekRute.new()
		o.jenis = "anjing_penjaga"
		o.jalur = "seberang"
		o.maju_ubin = (PANJANG_RUTE + 2.0) if sesudah else 60.0
		o.tanda_ubin = 8.0
		objek.append(o)
		akar.set(&"_rintangan", RintanganRute.dari_objek(objek))
		var tabrak: Array[int] = [0]
		akar.tabrakan.connect(func(_j: String) -> void: tabrak[0] += 1)
		var awal: float = (PANJANG_RUTE + 0.5) if sesudah else 56.0
		_taruh(akar, Config.KECEPATAN_SANTAI_UD, -2.4, awal)
		if sesudah:
			akar.perbarui(DT)
			check(akar.rute_sudah_selesai(), "sesudah garis: rute dinyatakan selesai di awal skenario")
		var kondisi_awal: Dictionary = akar.kondisi_akhir()
		_langkah(akar, 240)
		hasil.append([tabrak[0], akar.kondisi_akhir() == kondisi_awal, Tabrakan.jatuh(akar.rintangan().tabrakan), akar.skor().beruntun])
		_bersihkan(akar)
	check(int(hasil[0][0]) >= 1, "kontrol (sebelum garis): anjing di jalur menabrak sepeda (%d tabrakan)" % hasil[0][0])
	check(int(hasil[1][0]) == 0 and bool(hasil[1][1]) and not bool(hasil[1][2]), "sesudah garis: anjing di jalur yang sama tidak menabrak (%d), kondisi sepeda tidak berubah, tidak jatuh" % hasil[1][0])
	# Jatuh yang sedang berjalan saat garis dilewati: sepeda bangun lalu melaju keluar (tidak terkunci diam selamanya).
	var akar2: RuteMain = await _siapkan()
	_taruh(akar2, Config.KECEPATAN_SANTAI_UD, 0.0, PANJANG_RUTE + 0.3)
	akar2.perbarui(DT)
	var t: RintanganRute.Keadaan = akar2.rintangan()
	t.tabrakan = Tabrakan.awal()
	var kandidat: Array[Tabrakan.Kandidat] = []
	var k: Tabrakan.Kandidat = Tabrakan.Kandidat.new()
	k.id = 0
	k.jenis = "anjing_penjaga"
	k.kotak = Tabrakan.kotak_sepeda(_sepeda(akar2).jarak_ubin, 0.0)
	kandidat.append(k)
	t.tabrakan = Tabrakan.langkah(t.tabrakan, Tabrakan.kotak_sepeda(_sepeda(akar2).jarak_ubin, 0.0), kandidat, DT).keadaan
	_sepeda(akar2).tabrak()
	check(Tabrakan.jatuh(akar2.rintangan().tabrakan) and _sepeda(akar2).kecepatan_ud == 0.0, "kondisi uji: sepeda sedang jatuh tepat di garis akhir")
	_langkah(akar2, 20)
	check(akar2.rute_sudah_selesai() and _sepeda(akar2).kecepatan_ud == 0.0, "selama jatuh sepeda diam walau sudah lewat garis")
	for i: int in range(600):
		if akar2.hasil_tampil():
			break
		akar2.perbarui(DT)
	check(akar2.hasil_tampil() and not Tabrakan.jatuh(akar2.rintangan().tabrakan), "jam jatuh tetap berjalan sesudah garis: sepeda bangun, melaju keluar, dan layar hasil terbuka")
	_bersihkan(akar2)


# --- Jeda sepanjang fase keluar ---

func _test_jeda_saat_keluar() -> void:
	_judul.call("Jeda dan back Android sepanjang fase keluar (AC-8): jeda membekukan semuanya, lanjut meneruskan, banner tetap, hasil tetap tepat sekali")
	var akar: RuteMain = await _siapkan()
	var sepeda: SepedaUji = _sepeda(akar)
	var kamera: Camera2D = _kamera(akar)
	var dibuka: Array[int] = [0]
	akar.hasil_dibuka.connect(func(_a: HasilRute.Angka) -> void: dibuka[0] += 1)
	_taruh(akar, 6.0, 0.0, PANJANG_RUTE - 0.3)
	for i: int in range(200):
		akar.perbarui(DT)
		if akar.hampir_keluar():
			break
	check(akar.hampir_keluar() and akar.panel_akhir().tampil() and not akar.hasil_tampil(), "kondisi uji: sepeda hampir keluar, banner tampil, hasil belum")
	akar.minta_jeda()
	var jarak: float = sepeda.jarak_ubin
	var layar: Vector2 = akar.posisi_layar_sepeda()
	var kam: Vector2 = kamera.position
	_langkah(akar, 120)
	check(akar.sedang_jeda() and sepeda.jarak_ubin == jarak and akar.posisi_layar_sepeda() == layar and kamera.position == kam and not akar.hasil_tampil() and akar.panel_akhir().tampil(), "jeda 2 detik di fase keluar: sepeda, kamera, dan fase tidak berubah, banner tetap, hasil belum terbuka")
	akar.minta_lanjut()
	akar.perbarui(DT)
	check(not akar.sedang_jeda() and sepeda.jarak_ubin == jarak, "langkah pertama sesudah lanjut ber-dt 0 (tanpa lompatan)")
	akar._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(akar.sedang_jeda() and _tree.paused, "tombol back Android di fase keluar membuka layar jeda")
	akar._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(not akar.sedang_jeda() and not _tree.paused, "back lagi: lanjut")
	akar._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(akar.sedang_jeda(), "app ke background di fase keluar: menjeda")
	akar.minta_lanjut()
	for i: int in range(600):
		if akar.hasil_tampil():
			break
		akar.perbarui(DT)
	check(akar.hasil_tampil() and dibuka[0] == 1 and kamera.position == kam, "sesudah lanjut: sepeda keluar, hasil terbuka tepat sekali, kamera tetap beku")
	# Jeda saat layar hasil terbuka: back diabaikan seperti sebelumnya (tidak jeda), fokus hilang menjeda.
	akar._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(not akar.sedang_jeda() and akar.hasil_tampil(), "back di layar hasil diabaikan")
	_bersihkan(akar)


# --- Koran terbang menunda hasil ---

func _test_koran_terbang_menunda_hasil() -> void:
	_judul.call("Koran yang masih terbang saat sepeda sudah keluar menunda layar hasil sampai mendarat dan dinilai (G-4, AC-4 di scene)")
	var akar: RuteMain = await _siapkan()
	_taruh(akar, 6.0, 0.0, PANJANG_RUTE - 6.0)
	akar.koran = SisaKoran.awal(30)
	akar.perbarui(0.0)
	# Lemparan jauh yang lama terbang tepat sebelum garis: lintasan dari swipe terpanjang ke depan.
	var lintasan: ThrowSolver.Lintasan = akar.lintasan_swipe(Vector2(560, 250), Vector2(700, 100))
	# Waktu terbang diperpanjang (5 detik) supaya koran masih di udara ketika sepeda sudah keluar (keluar dari 6 ubin sebelum garis butuh sekitar 3 detik di ngebut).
	lintasan.jeda_lepas = 0.0
	lintasan.lama_terbang = 5.0
	check(lintasan != null and bool(akar.call(&"_lempar", lintasan, false)), "koran dilempar tepat sebelum garis akhir (terbang 5 detik)")
	var terlambat: int = 0
	var hasil_langkah: int = -1
	var keluar_langkah: int = -1
	var mendarat_langkah: int = -1
	for i: int in range(900):
		akar.perbarui(DT)
		if akar.fase_keluar() == AkhirRute.Fase.SUDAH_KELUAR and keluar_langkah < 0:
			keluar_langkah = i
		if not akar.koran_terbang().is_empty() and akar.koran_terbang()[0].mendarat and mendarat_langkah < 0:
			mendarat_langkah = i
		if akar.hasil_tampil():
			hasil_langkah = i
			break
	check(keluar_langkah >= 0 and hasil_langkah > keluar_langkah and mendarat_langkah >= hasil_langkah - 1 and mendarat_langkah > keluar_langkah, "hasil terbuka sesudah sepeda keluar (langkah %d) DAN koran mendarat (langkah %d): hasil di langkah %d" % [keluar_langkah, mendarat_langkah, hasil_langkah])
	terlambat = 1 if akar.angka_hasil() != null else 0
	check(terlambat == 1 and akar.skor().jumlah_antar + akar.skor().terbuang >= 1, "koran yang mendarat sesudah garis tetap dinilai (antaran %d, terbuang %d)" % [akar.skor().jumlah_antar, akar.skor().terbuang])
	_bersihkan(akar)


# --- Pemulihan ---

func _test_main_lagi_memulihkan() -> void:
	_judul.call("Main lagi (dari layar hasil, dari fase keluar, dan dari banner galat) memulihkan keadaan awal: kamera mengikuti, portal tertutup, kontrol dan lempar aktif, banner hilang, fase SEBELUM (AC-8)")
	for dari: String in ["hasil", "keluar", "galat"]:
		var akar: RuteMain = await _siapkan()
		var sepeda: SepedaUji = _sepeda(akar)
		var kamera: Camera2D = _kamera(akar)
		_taruh(akar, 6.0, 0.0, PANJANG_RUTE - 0.3)
		for i: int in range(900):
			akar.perbarui(DT)
			if (dari == "hasil" and akar.hasil_tampil()) or (dari != "hasil" and akar.hampir_keluar()):
				break
		var benih: int = akar.benih()
		if dari == "galat":
			akar.panel_akhir().main_lagi_diminta.emit()
		elif dari == "hasil":
			akar.layar_hasil().tombol_main_lagi().ditekan.emit()
		else:
			akar.main_lagi()
		var tag: String = "dari %s" % dari
		check(akar.benih() == benih + 1 and not akar.kamera_beku() and akar.fase_keluar() == AkhirRute.Fase.SEBELUM and not akar.hampir_keluar() and akar.jarak_beku() == 0.0 and not akar.rute_sudah_selesai(), "%s: seed + 1, kamera tidak beku, fase SEBELUM, bendera hampir keluar, jarak beku, dan selesai kembali nol" % tag)
		check(akar.portal().bingkai() == 0 and akar.portal().visible and akar.portal().panjang_dipasang() == akar.rute().panjang_ubin, "%s: portal tertutup dan terpasang di garis akhir rute baru" % tag)
		check(not akar.panel_akhir().tampil() and not akar.hasil_tampil() and not akar.layar_hasil().tampil(), "%s: banner dan layar hasil hilang" % tag)
		check((akar.find_child("KontrolTouch", true, false) as KontrolTouch).is_processing_input() and bool(akar.call(&"_lempar_terbuka")) and akar.geser_dorongan() == Vector2.ZERO, "%s: kontrol sentuh membaca lagi, lemparan terbuka, geseran dorongan nol" % tag)
		akar.perbarui(DT)
		check(kamera.position == akar.posisi_kamera() and sepeda.jarak_ubin < 1.0 and akar.rute().panjang_ubin > 0.0, "%s: kamera mengikuti sepeda lagi (posisi kamera = posisi_kamera())" % tag)
		# Lemparan memang bisa dilakukan lagi.
		var sisa: int = akar.koran.sisa
		var lintasan: ThrowSolver.Lintasan = akar.lintasan_swipe(Vector2(560, 250), Vector2(620, 160))
		check(lintasan != null and bool(akar.call(&"_lempar", lintasan, false)) and akar.koran.sisa == sisa - 1, "%s: lemparan diterima lagi (koran %d -> %d)" % [tag, sisa, akar.koran.sisa])
		# Rute kedua bisa diselesaikan sampai hasil lagi.
		_taruh(akar, 6.0, 0.0, akar.rute().panjang_ubin - 0.3)
		for i: int in range(900):
			if akar.hasil_tampil():
				break
			akar.perbarui(DT)
		check(akar.hasil_tampil() and akar.fase_keluar() == AkhirRute.Fase.SUDAH_KELUAR and akar.kamera_beku(), "%s: rute berikutnya selesai lagi sampai layar hasil (fase keluar berulang)" % tag)
		_bersihkan(akar)


func _test_alur_hari_memulihkan() -> void:
	_judul.call("Alur hari (hari.tscn dengan simpanan sementara): Hari berikutnya memberi rute baru yang pulih penuh (kamera mengikuti, portal tertutup, kontrol aktif); save asli tidak tersentuh")
	var a: TesAlurHari = TesAlurHari.new(_cek, _judul, _tree)
	var sebelum: Dictionary = a._jejak_save_asli()
	a._bersihkan_folder()
	var m: Node = a._manajer()
	var hari: HariMain = await a._siapkan(m)
	var rute: RuteMain = await a._berangkat(hari)
	var lama: RuteMain = rute
	await a._selesaikan_rute(rute)
	check(rute.hasil_tampil() and rute.kamera_beku() and rute.fase_keluar() == AkhirRute.Fase.SUDAH_KELUAR and m.get(&"jumlah_simpan") == 0, "hari 1 selesai: hasil terbuka sesudah sepeda keluar, kamera beku, nol simpan")
	rute.layar_hasil().tombol_main_lagi().ditekan.emit()
	hari.bengkel().tombol_hari_berikutnya().ditekan.emit()
	await _tree.process_frame
	var rute2: RuteMain = await a._berangkat(hari)
	check(rute2 != lama and not rute2.kamera_beku() and rute2.fase_keluar() == AkhirRute.Fase.SEBELUM and rute2.portal().bingkai() == 0 and not rute2.hasil_tampil() and not rute2.hampir_keluar(), "hari 2: rute baru, kamera mengikuti, portal tertutup, fase SEBELUM")
	check((rute2.find_child("KontrolTouch", true, false) as KontrolTouch).is_processing_input() and bool(rute2.call(&"_lempar_terbuka")) and not rute2.panel_akhir().tampil(), "hari 2: kontrol sentuh dan lemparan aktif, banner tersembunyi")
	check(rute2.hari() == 2 and rute2.rute().panjang_ubin > 0.0 and rute2.portal().panjang_dipasang() == rute2.rute().panjang_ubin, "hari 2: portal di garis akhir rute hari 2")
	a._bersihkan(hari)
	a._tutup_manajer(m)
	a._bersihkan_folder()
	var sesudah: Dictionary = a._jejak_save_asli()
	check(sebelum == sesudah, "user://save.json asli tidak tersentuh (%s -> %s)" % [sebelum, sesudah])


# --- Jendela daur beku ---

func _test_jendela_daur_beku() -> void:
	_judul.call("Jendela daur sesudah garis (G-5): rumah, dekor, rintangan, dan tanah dibekukan di jarak garis; tidak bertambah dan tidak berpindah selama sepeda keluar")
	var akar: RuteMain = await _siapkan()
	_taruh(akar, 6.0, 0.0, PANJANG_RUTE - 0.2)
	akar.perbarui(DT)
	_langkah(akar, 10)
	check(akar.rute_sudah_selesai() and akar.jarak_beku() >= PANJANG_RUTE and akar.jarak_beku() < PANJANG_RUTE + 1.5, "jarak beku = jarak sepeda saat garis tercapai (%.3f)" % akar.jarak_beku())
	var rumah: Array[int] = akar.daur().indeks_tampil()
	var dekor: Array[int] = akar.dekor_daur().indeks_tampil()
	var rintangan: Array[int] = akar.rintangan_daur().id_tampil()
	var beku: float = akar.jarak_beku()
	_langkah(akar, 120)
	check(akar.jarak_beku() == beku and akar.daur().indeks_tampil() == rumah and akar.dekor_daur().indeks_tampil() == dekor and akar.rintangan_daur().id_tampil() == rintangan and _sepeda(akar).jarak_ubin > beku + 3.0, "120 langkah sepeda melaju: jendela rumah, dekor, dan rintangan tidak berubah walau sepeda menempuh %.1f ubin lagi" % (_sepeda(akar).jarak_ubin - beku))
	# Rute tanpa kontrol beku (jarak 240 lewat `_taruh`): jendela sesuai jarak garis, bukan 240.
	_bersihkan(akar)
