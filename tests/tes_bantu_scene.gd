class_name TesBantuScene
extends RefCounted
## Tes terpadu mode bantu run fase2b-bantu-audio (AC-5, AC-6, AC-7, D-5 sampai D-7): scene jalan uji sungguhan, event sentuh sintetis
## lewat `Input.parse_input_event` (pola `tests/tes_koran_scene.gd`), langkah `JalanUji.perbarui(dt)` dengan dt tetap.
## - AC-5: tap di mode bantu melempar satu koran ke kotak surat (seberang dan dekat), gerbang jeda antar lempar 0,35, koran habis, jeda game,
##   mode bantu mati, swipe manual tetap jalan, kidal, tanpa sasaran (tanda tampil lalu hilang, koran dan jeda tetap).
## - AC-6: kecepatan otomatis = santai 3,0 u/d tanpa stick, stamina tidak turun; stick tetap mengubah kecepatan dan sisi.
## - AC-7: sakelar di HUD dev: mengubah mode di scene, teks kunci terjemahan dengan status bukan warna saja, ukuran >= tombol kidal, di luar
##   zona stick dan swipe (kidal maupun tidak) di 640, 780, 800, tidak bertumpuk dengan tombol kidal, tombol jeda, dan panel.
## Sisi tap yang diharapkan dihitung dari garis layar 1:2 lewat titik pijak sepeda (oracle independen, bukan `BantuLempar.sisi_tap`).

const BERKAS_JALAN_UJI: String = "res://scenes/dev/jalan_uji.tscn"
const SKALA: int = 3
const DT: float = 1.0 / 60.0
const LEBAR: float = 780.0
const TITIK_STICK: Vector2 = Vector2(100, 260)
## Ukuran jendela uji: [lebar jendela, tinggi jendela, lebar viewport game].
const KASUS_JENDELA: Array = [[1920, 1080, 640], [2340, 1080, 780], [2400, 1080, 800]]

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
	await _test_tap_melempar()
	await _test_jeda_antar_lempar_dan_habis()
	await _test_jeda_game()
	await _test_mode_mati_dan_swipe()
	await _test_kidal()
	await _test_tanpa_sasaran()
	await _test_kecepatan_otomatis()
	for kasus: Array in KASUS_JENDELA:
		await _test_sakelar(kasus)


# --- Pembantu ---

func _siapkan(jendela: Vector2i = Vector2i(2340, 1080)) -> JalanUji:
	_tree.root.size = jendela
	var akar: JalanUji = (load(BERKAS_JALAN_UJI) as PackedScene).instantiate() as JalanUji
	_tree.root.add_child(akar)
	await _tree.process_frame
	await _tree.process_frame
	akar.set_process(false)
	(_anak(akar, "KontrolTouch") as KontrolTouch).keyboard_aktif = false
	_sprite(akar)
	return akar


func _bersihkan(akar: JalanUji) -> void:
	_lepas_semua_jari()
	if akar.sedang_jeda():
		akar.minta_lanjut()
	(_anak(akar, "KontrolTouch") as KontrolTouch).keyboard_aktif = OS.has_feature("editor")
	_tree.root.remove_child(akar)
	akar.free()


func _anak(akar: Node, nama: String) -> Node:
	return akar.find_child(nama, true, false)


func _sprite(akar: JalanUji) -> LoperSprite:
	var sprite: LoperSprite = _anak(akar, "LoperAgen") as LoperSprite
	sprite.set_process(false)
	return sprite


func _sepeda(akar: JalanUji) -> SepedaUji:
	return _anak(akar, "Sepeda") as SepedaUji


func _kontrol(akar: JalanUji) -> KontrolTouch:
	return _anak(akar, "KontrolTouch") as KontrolTouch


func _hud(akar: JalanUji) -> HudDev:
	return _anak(akar, "Hud") as HudDev


func _tombol_bantu(akar: JalanUji) -> Button:
	return _anak(akar, "TombolBantu") as Button


func _sentuh(index: int, posisi_viewport: Vector2, tekan: bool) -> void:
	var peristiwa: InputEventScreenTouch = InputEventScreenTouch.new()
	peristiwa.index = index
	peristiwa.position = posisi_viewport * float(SKALA)
	peristiwa.pressed = tekan
	Input.parse_input_event(peristiwa)
	Input.flush_buffered_events()


func _geser(index: int, posisi_viewport: Vector2) -> void:
	var peristiwa: InputEventScreenDrag = InputEventScreenDrag.new()
	peristiwa.index = index
	peristiwa.position = posisi_viewport * float(SKALA)
	Input.parse_input_event(peristiwa)
	Input.flush_buffered_events()


func _lepas_semua_jari() -> void:
	for i: int in range(8):
		_sentuh(i, Vector2(-50, -50), false)


## Tap jari `index` (turun dan naik di titik yang sama).
func _tap(posisi: Vector2, index: int = 1) -> void:
	_sentuh(index, posisi, true)
	_sentuh(index, posisi, false)


func _langkah(akar: JalanUji, jumlah: int, dt: float = DT) -> void:
	var sprite: LoperSprite = _sprite(akar)
	for i: int in range(jumlah):
		akar.perbarui(dt)
		sprite.maju(dt)


func _catat(akar: JalanUji) -> Dictionary:
	var catatan: Dictionary = {"lempar": [], "mendarat": [], "tanpa": []}
	akar.koran_dilempar.connect(func(l: ThrowSolver.Lintasan) -> void: (catatan["lempar"] as Array).append(l))
	akar.koran_mendarat.connect(func(k: KoranLempar.Koran) -> void: (catatan["mendarat"] as Array).append(k))
	akar.bantu_tanpa_sasaran.connect(func(p: Vector2) -> void: (catatan["tanpa"] as Array).append(p))
	return catatan


func _nyalakan_bantu(akar: JalanUji) -> void:
	_tombol_bantu(akar).button_pressed = true


## Sisi yang DIHARAPKAN dari garis layar 1:2 lewat titik pijak sepeda (oracle independen D-3).
func _sisi_harapan(tap: Vector2, sepeda: Vector2) -> LoperAnim.Sisi:
	var d: float = (tap.y - sepeda.y) + (tap.x - sepeda.x) / 2.0
	return LoperAnim.Sisi.SEBERANG if d < 0.0 else LoperAnim.Sisi.DEKAT


## Titik tap di atas garis jalan (seberang) dan di bawahnya (dekat) relatif titik pijak sepeda, di dalam zona swipe tangan kanan.
func _tap_seberang(akar: JalanUji) -> Vector2:
	return akar.posisi_layar_sepeda() + Vector2(200, -150)


func _tap_dekat(akar: JalanUji) -> Vector2:
	return akar.posisi_layar_sepeda() + Vector2(200, 30)


## Melangkah sampai ada sasaran bantu untuk `sisi` (paling lama 4 detik). True bila ada.
func _tunggu_sasaran(akar: JalanUji, sisi: LoperAnim.Sisi) -> bool:
	for i: int in range(240):
		if akar.pilihan_bantu(sisi) != null:
			return true
		_langkah(akar, 1)
	return akar.pilihan_bantu(sisi) != null


func _sampai_mendarat(akar: JalanUji, catatan: Dictionary) -> KoranLempar.Koran:
	var sebelum: int = (catatan["mendarat"] as Array).size()
	for i: int in range(roundi(2.0 / DT)):
		_langkah(akar, 1)
		if (catatan["mendarat"] as Array).size() > sebelum:
			return (catatan["mendarat"] as Array)[sebelum]
	return null


# --- AC-5 ---

func _test_tap_melempar() -> void:
	_judul.call("Mode bantu: tap melempar ke kotak surat seberang dan dekat (AC-5, D-3, D-5)")
	var akar: JalanUji = await _siapkan()
	var catatan: Dictionary = _catat(akar)
	var garis: GarisBidik = akar.garis_bidik()
	check(not akar.mode_bantu() and not _tombol_bantu(akar).button_pressed, "mode bantu bawaan mati")
	_nyalakan_bantu(akar)
	check(akar.mode_bantu(), "tombol bantu menyalakan mode bantu di scene")
	# Titik pijak sepeda di layar = transform kanvas sepeda sesudah kamera diterapkan.
	await _tree.process_frame
	check(_sepeda(akar).get_global_transform_with_canvas().origin.distance_to(akar.posisi_layar_sepeda()) < 0.001, "posisi layar sepeda = transform kanvas sepeda (%s)" % akar.posisi_layar_sepeda())
	for sisi: LoperAnim.Sisi in [LoperAnim.Sisi.SEBERANG, LoperAnim.Sisi.DEKAT]:
		var nama: String = LoperAnim.Sisi.keys()[sisi]
		akar.perbarui(Config.LEMPAR_JEDA_DETIK)
		check(_tunggu_sasaran(akar, sisi), "%s: ada kotak surat terjangkau" % nama)
		var tap: Vector2 = _tap_seberang(akar) if sisi == LoperAnim.Sisi.SEBERANG else _tap_dekat(akar)
		check(_sisi_harapan(tap, akar.posisi_layar_sepeda()) == sisi and TouchZones.zona_di(tap, int(LEBAR), false) == TouchZones.Zona.SWIPE, "%s: titik tap %s di zona swipe, di %s garis jalan (oracle)" % [nama, tap, "atas" if sisi == LoperAnim.Sisi.SEBERANG else "bawah"])
		var harapan: BantuLempar.Pilihan = akar.pilihan_bantu(sisi)
		var sisa: int = akar.koran.sisa
		var jumlah: int = (catatan["lempar"] as Array).size()
		_tap(tap)
		check((catatan["lempar"] as Array).size() == jumlah + 1 and akar.koran.sisa == sisa - 1, "%s: tap = tepat satu koran dilempar (koran_dilempar sekali), sisa %d -> %d" % [nama, sisa, akar.koran.sisa])
		check(not garis.tampil(), "%s: tap tanpa garis bidik" % nama)
		if (catatan["lempar"] as Array).size() != jumlah + 1:
			continue
		var l: ThrowSolver.Lintasan = (catatan["lempar"] as Array)[jumlah]
		check(harapan != null and l.titik_mendarat == harapan.lintasan.titik_mendarat and l.titik_lepas == harapan.lintasan.titik_lepas, "%s: lintasan = pilihan bantu dari keadaan sepeda langkah terakhir (rumah %d)" % [nama, harapan.zona.rumah if harapan != null else -1])
		check(_sepeda(akar).sedang_melempar() and l.sisi == sisi, "%s: animasi lempar ke sisi %s dimulai" % [nama, nama])
		check(akar.koran_terbang().size() >= 1 and akar.koran_terbang()[akar.koran_terbang().size() - 1].lintasan == l, "%s: koran terbang dengan lintasan beku itu" % nama)
		var mendarat: KoranLempar.Koran = _sampai_mendarat(akar, catatan)
		check(mendarat != null and mendarat.hasil == ZonaSasaran.Hasil.KOTAK_SURAT and mendarat.penanda == ZonaSasaran.Penanda.CENTANG, "%s: mendarat dan dinilai KOTAK_SURAT, penanda centang" % nama)
		check(mendarat != null and Vector2(KoranLempar.posisi(mendarat).x, KoranLempar.posisi(mendarat).y) == l.titik_mendarat, "%s: titik mendarat = lintasan beku" % nama)
	_bersihkan(akar)


func _test_jeda_antar_lempar_dan_habis() -> void:
	_judul.call("Mode bantu: jeda antar lempar 0,35 dan koran habis (AC-5, K-4, D-5)")
	var akar: JalanUji = await _siapkan()
	var catatan: Dictionary = _catat(akar)
	var kontrol: KontrolTouch = _kontrol(akar)
	_nyalakan_bantu(akar)
	check(_tunggu_sasaran(akar, LoperAnim.Sisi.DEKAT), "ada sasaran dekat")
	_tap(_tap_dekat(akar))
	check((catatan["lempar"] as Array).size() == 1 and akar.koran.sisa == 29, "tap pertama diterima")
	akar.perbarui(0.2)
	_tap(_tap_dekat(akar))
	check((catatan["lempar"] as Array).size() == 1 and akar.koran.sisa == 29 and is_equal_approx(akar.koran.sejak_lempar_detik, 0.2), "tap kedua 0,2 detik sesudahnya ditolak: koran tetap 29, jeda tidak mulai ulang")
	check(not kontrol.tanda_tampil() and (catatan["tanpa"] as Array).is_empty(), "ditolak karena jeda antar lempar: tidak ada tanda tanpa sasaran")
	akar.perbarui(0.149)
	_tap(_tap_dekat(akar))
	check((catatan["lempar"] as Array).size() == 1, "0,349 detik: masih ditolak")
	akar.perbarui(0.001)
	check(akar.pilihan_bantu(LoperAnim.Sisi.DEKAT) != null or _tunggu_sasaran(akar, LoperAnim.Sisi.DEKAT), "ada sasaran dekat lagi")
	_tap(_tap_dekat(akar))
	check((catatan["lempar"] as Array).size() == 2 and akar.koran.sisa == 28, "0,35 detik: tap diterima, sisa 28")
	# Koran habis: tap tidak melempar dan tidak memberi tanda.
	var tinggal_satu: SisaKoran.Keadaan = akar.koran.salin()
	tinggal_satu.sisa = 1
	tinggal_satu.sejak_lempar_detik = INF
	akar.koran = tinggal_satu
	check(_tunggu_sasaran(akar, LoperAnim.Sisi.SEBERANG), "ada sasaran seberang")
	_tap(_tap_seberang(akar))
	check((catatan["lempar"] as Array).size() == 3 and akar.koran.sisa == 0, "koran terakhir dilempar lewat tap")
	akar.perbarui(Config.LEMPAR_JEDA_DETIK)
	_tunggu_sasaran(akar, LoperAnim.Sisi.SEBERANG)
	_tap(_tap_seberang(akar))
	check((catatan["lempar"] as Array).size() == 3 and akar.koran.sisa == 0, "koran habis: tap tidak melempar (lempar %d, sisa %d)" % [(catatan["lempar"] as Array).size(), akar.koran.sisa])
	check(not kontrol.tanda_tampil() and (catatan["tanpa"] as Array).is_empty() and _hud(akar).penanda_habis_tampil(), "koran habis: tanpa tanda tanpa sasaran, HUD menunjukkan HABIS")
	_bersihkan(akar)


func _test_jeda_game() -> void:
	_judul.call("Mode bantu: jeda game, tap tidak melempar, koran terbang beku (AC-5, D-5)")
	var akar: JalanUji = await _siapkan()
	var catatan: Dictionary = _catat(akar)
	_nyalakan_bantu(akar)
	check(_tunggu_sasaran(akar, LoperAnim.Sisi.SEBERANG), "ada sasaran seberang")
	_tap(_tap_seberang(akar))
	# 0,4 detik: jeda antar lempar 0,35 sudah lewat (gerbang yang tersisa hanya jeda game), koran masih di udara (jeda lepas + terbang >= 0,62).
	_langkah(akar, 24)
	check(akar.koran_terbang().size() == 1 and KoranLempar.di_udara(akar.koran_terbang()[0]) and SisaKoran.boleh_lempar(akar.koran), "koran bantu masih di udara dan jeda antar lempar sudah lewat")
	var koran: KoranLempar.Koran = akar.koran_terbang()[0]
	var detik: float = koran.detik
	var posisi: Vector3 = KoranLempar.posisi(koran)
	akar.minta_jeda()
	check(akar.sedang_jeda(), "jeda")
	var tap: Vector2 = _tap_seberang(akar)
	_tap(tap)
	# Jalur gerbang di scene sendiri: router dipanggil langsung (input normal tidak sampai saat SceneTree.paused).
	var router: TouchRouter = _kontrol(akar).router
	router.tekan(3, tap, 0.0)
	router.lepas(3, tap, 0.1)
	check(router.jumlah_tap_selesai >= 1, "kontrol: tap langsung ke router tercatat saat jeda")
	for dt: float in [DT, 0.5, 5.0]:
		akar.perbarui(dt)
	check((catatan["lempar"] as Array).size() == 1 and akar.koran.sisa == 29 and not _kontrol(akar).tanda_tampil(), "jeda game: tap tidak melempar, tidak mengurangi koran, tanpa tanda")
	check(akar.koran_terbang().size() == 1 and akar.koran_terbang()[0].detik == detik and KoranLempar.posisi(akar.koran_terbang()[0]) == posisi, "jeda game: koran bantu yang terbang beku")
	akar.minta_lanjut()
	akar.perbarui(DT)
	var mendarat: KoranLempar.Koran = _sampai_mendarat(akar, catatan)
	check(mendarat != null and mendarat.hasil == ZonaSasaran.Hasil.KOTAK_SURAT, "sesudah lanjut koran bantu mendarat di kotak surat")
	_bersihkan(akar)


func _test_mode_mati_dan_swipe() -> void:
	_judul.call("Mode bantu mati: tap tidak melempar; swipe manual tetap melempar di mode bantu (AC-5, D-2)")
	var akar: JalanUji = await _siapkan()
	var catatan: Dictionary = _catat(akar)
	check(_tunggu_sasaran(akar, LoperAnim.Sisi.SEBERANG), "ada sasaran seberang (mode mati)")
	_tap(_tap_seberang(akar))
	check((catatan["lempar"] as Array).is_empty() and akar.koran.sisa == 30 and not _kontrol(akar).tanda_tampil(), "mode bantu mati: tap tidak melempar dan tanpa tanda")
	_nyalakan_bantu(akar)
	_tombol_bantu(akar).button_pressed = false
	check(not akar.mode_bantu(), "tombol bantu dimatikan lagi")
	_tap(_tap_seberang(akar))
	check((catatan["lempar"] as Array).is_empty(), "sesudah dimatikan: tap tidak melempar")
	_nyalakan_bantu(akar)
	# Swipe manual ke kiri (seberang) di mode bantu: garis bidik tampil, satu koran, bukan dua.
	var awal: Vector2 = Vector2(720, 200)
	var akhir: Vector2 = awal - Vector2(ThrowSolver.swipe_min_px(LEBAR) + 40.0, 0)
	_sentuh(1, awal, true)
	_geser(1, akhir)
	akar.perbarui(DT)
	check(akar.garis_bidik().tampil(), "mode bantu: swipe manual menampilkan garis bidik")
	_sentuh(1, akhir, false)
	check((catatan["lempar"] as Array).size() == 1 and akar.koran.sisa == 29 and ((catatan["lempar"] as Array)[0] as ThrowSolver.Lintasan).sisi == LoperAnim.Sisi.SEBERANG, "mode bantu: swipe manual melempar tepat satu koran ke arah swipe")
	# Tarik-lalu-kembali di mode bantu tetap batal (bukan tap otomatis).
	akar.perbarui(Config.LEMPAR_JEDA_DETIK)
	_sentuh(1, awal, true)
	_geser(1, akhir)
	_geser(1, awal + Vector2(1, 0))
	_sentuh(1, awal + Vector2(1, 0), false)
	check((catatan["lempar"] as Array).size() == 1 and akar.koran.sisa == 29 and not _kontrol(akar).tanda_tampil(), "mode bantu: swipe yang ditarik kembali tetap batal, bukan lemparan otomatis")
	_bersihkan(akar)


func _test_kidal() -> void:
	_judul.call("Mode bantu + kidal: tap di zona swipe kiri (AC-5, D-3)")
	var akar: JalanUji = await _siapkan()
	var catatan: Dictionary = _catat(akar)
	_nyalakan_bantu(akar)
	(_anak(akar, "TombolKidal") as Button).button_pressed = true
	await _tree.process_frame
	check(_kontrol(akar).router.kidal() and akar.mode_bantu(), "kidal dan mode bantu menyala")
	var sepeda_layar: Vector2 = akar.posisi_layar_sepeda()
	# Titik yang hanya zona swipe bila kidal: x 150 (< 210). Di atas garis = seberang; di bawah garis (y > garis di x 150) = dekat.
	var atas: Vector2 = Vector2(150, 120)
	var bawah: Vector2 = Vector2(150, 345)
	check(TouchZones.zona_di(atas, int(LEBAR), true) == TouchZones.Zona.SWIPE and TouchZones.zona_di(atas, int(LEBAR), false) == TouchZones.Zona.TIDAK_ADA, "kontrol: (150, 120) zona swipe hanya bila kidal")
	check(TouchZones.zona_di(bawah, int(LEBAR), true) == TouchZones.Zona.SWIPE and TouchZones.zona_di(bawah, int(LEBAR), false) == TouchZones.Zona.STICK, "kontrol: (150, 345) zona swipe bila kidal, zona stick bila tidak")
	check(_sisi_harapan(atas, sepeda_layar) == LoperAnim.Sisi.SEBERANG and _sisi_harapan(bawah, sepeda_layar) == LoperAnim.Sisi.DEKAT, "kontrol: (150, 120) di atas garis jalan, (150, 345) di bawahnya (sepeda di %s)" % sepeda_layar)
	check(_tunggu_sasaran(akar, LoperAnim.Sisi.SEBERANG), "ada sasaran seberang")
	_tap(atas)
	check((catatan["lempar"] as Array).size() == 1 and ((catatan["lempar"] as Array)[0] as ThrowSolver.Lintasan).sisi == LoperAnim.Sisi.SEBERANG, "kidal: tap di atas garis (zona kiri) melempar ke seberang")
	akar.perbarui(Config.LEMPAR_JEDA_DETIK)
	check(_tunggu_sasaran(akar, LoperAnim.Sisi.DEKAT), "ada sasaran dekat")
	if not _sisi_harapan(bawah, akar.posisi_layar_sepeda()) == LoperAnim.Sisi.DEKAT:
		bawah = Vector2(150, 351)
	_tap(bawah)
	check((catatan["lempar"] as Array).size() == 2 and ((catatan["lempar"] as Array)[1] as ThrowSolver.Lintasan).sisi == LoperAnim.Sisi.DEKAT, "kidal: tap di bawah garis (zona kiri) melempar ke dekat")
	akar.perbarui(Config.LEMPAR_JEDA_DETIK)
	_tunggu_sasaran(akar, LoperAnim.Sisi.SEBERANG)
	_tap(Vector2(700, 260))
	check((catatan["lempar"] as Array).size() == 2, "kidal: sentuhan di kanan bawah = stick, bukan tap")
	(_anak(akar, "TombolKidal") as Button).button_pressed = false
	await _tree.process_frame
	_bersihkan(akar)


func _test_tanpa_sasaran() -> void:
	_judul.call("Mode bantu: tap tanpa sasaran = tanda, koran dan jeda tetap (AC-5, K-3, D-6)")
	var akar: JalanUji = await _siapkan()
	var catatan: Dictionary = _catat(akar)
	var kontrol: KontrolTouch = _kontrol(akar)
	_nyalakan_bantu(akar)
	# Maju 5,2: kotak surat seberang rumah 1 (5,125) di belakang, rumah 2 bukan pelanggan, rumah 3 (13,125) di luar jangkauan santai.
	_sepeda(akar).jarak_ubin = 5.2
	akar.perbarui(0.0)
	check(akar.pilihan_bantu(LoperAnim.Sisi.SEBERANG) == null and akar.pilihan_bantu(LoperAnim.Sisi.DEKAT) != null, "kontrol: maju 5,2 santai tidak ada sasaran seberang, ada sasaran dekat (rumah 2 dekat)")
	var tap: Vector2 = _tap_seberang(akar)
	_tap(tap)
	check((catatan["lempar"] as Array).is_empty() and akar.koran.sisa == 30 and akar.koran_terbang().is_empty(), "tanpa sasaran: tidak ada koran, sisa tetap 30")
	check(akar.koran.sejak_lempar_detik == INF, "tanpa sasaran: jeda antar lempar tidak mulai")
	check(kontrol.tanda_tampil() and kontrol.posisi_tanda() == tap and (catatan["tanpa"] as Array).size() == 1, "tanpa sasaran: tanda tampil di titik tap %s" % tap)
	# Perintah gambar tanda: cincin 9x9 berpusat di titik tap, w = TEXT_2, o = OUTLINE (oracle eksplisit, bukan GambarPiksel).
	var pojok: Vector2i = Vector2i(tap.round()) - Vector2i(4, 4)
	var peta: Dictionary = {}
	for p: Array in kontrol.perintah_tanda():
		for r: Vector3i in p[0] as Array:
			for x: int in range(r.y, r.z):
				peta[Vector2i((p[1] as Vector2).round()) + Vector2i(x, r.x)] = p[2]
	var pola: Array[String] = ["...ooo...", ".oowwwoo.", ".owooowo.", "owo...owo", "owo...owo", "owo...owo", ".owooowo.", ".oowwwoo.", "...ooo..."]
	var gambar_benar: bool = true
	var jumlah_piksel: int = 0
	for y: int in range(9):
		for x: int in range(9):
			var huruf: String = pola[y][x]
			var titik: Vector2i = pojok + Vector2i(x, y)
			if huruf == ".":
				if peta.has(titik):
					gambar_benar = false
				continue
			jumlah_piksel += 1
			var harapan: Color = Palette.TEXT_2 if huruf == "w" else Palette.OUTLINE
			if not peta.has(titik) or not (peta[titik] as Color).is_equal_approx(harapan):
				gambar_benar = false
	check(gambar_benar and peta.size() == jumlah_piksel, "tanda: cincin 9x9 berpusat di titik tap, isi TEXT_2 bergaris OUTLINE (%d piksel)" % peta.size())
	# Tap dekat yang punya sasaran langsung diterima (tanda tadi tidak memulai jeda).
	_tap(_tap_dekat(akar))
	check((catatan["lempar"] as Array).size() == 1 and akar.koran.sisa == 29, "sesudah tap tanpa sasaran, tap dekat yang bersasaran langsung diterima")
	# Tanda hilang sesudah 0,6 detik (ikut dt efektif).
	_langkah(akar, 30)
	check(kontrol.tanda_tampil(), "tanda masih tampil sesudah 0,5 detik")
	akar.minta_jeda()
	akar.perbarui(5.0)
	check(kontrol.tanda_tampil(), "tanda beku selama jeda game")
	akar.minta_lanjut()
	akar.perbarui(DT)
	_langkah(akar, 7)
	check(not kontrol.tanda_tampil() and kontrol.perintah_tanda().is_empty(), "tanda hilang sesudah 0,6 detik, tidak digambar lagi")
	_bersihkan(akar)


# --- AC-6 ---

func _test_kecepatan_otomatis() -> void:
	_judul.call("Mode bantu: kecepatan otomatis santai, stick tetap aktif (AC-6, K-1)")
	var akar: JalanUji = await _siapkan()
	var sepeda: SepedaUji = _sepeda(akar)
	_nyalakan_bantu(akar)
	var awal: BikeMotion.Keadaan = sepeda.keadaan.salin()
	awal.kecepatan_ud = 1.5
	awal.stamina = 50.0
	sepeda.keadaan = awal
	var stamina_turun: bool = false
	var sebelum: float = sepeda.stamina()
	for i: int in range(180):
		_langkah(akar, 1)
		if sepeda.stamina() < sebelum - 0.000001:
			stamina_turun = true
		sebelum = sepeda.stamina()
	check(is_equal_approx(sepeda.kecepatan_ud, 3.0) and not stamina_turun and sepeda.stamina() > 50.0, "tanpa stick 3 detik: kecepatan menuju 3,0 u/d (dapat %.3f), stamina tidak turun (50 -> %.2f)" % [sepeda.kecepatan_ud, sepeda.stamina()])
	_sentuh(0, TITIK_STICK, true)
	_geser(0, TITIK_STICK + Vector2(0, -35))
	_langkah(akar, 60)
	check(sepeda.kecepatan_ud > 4.5, "mode bantu: stick ke atas tetap mempercepat (%.2f u/d)" % sepeda.kecepatan_ud)
	var lateral: float = sepeda.lateral_ubin
	_geser(0, TITIK_STICK + Vector2(35, 0))
	_langkah(akar, 20)
	check(absf(sepeda.lateral_ubin - lateral) > 0.3, "mode bantu: stick ke samping tetap pindah sisi (%.2f -> %.2f)" % [lateral, sepeda.lateral_ubin])
	_sentuh(0, TITIK_STICK + Vector2(35, 0), false)
	_bersihkan(akar)


# --- AC-7 ---

func _test_sakelar(kasus: Array) -> void:
	var lebar: int = kasus[2]
	var tag: String = "lebar %d" % lebar
	_judul.call("Sakelar mode bantu di HUD dev %s (AC-7, D-7)" % tag)
	var akar: JalanUji = await _siapkan(Vector2i(kasus[0], kasus[1]))
	var hud: HudDev = _hud(akar)
	var tombol: Button = _tombol_bantu(akar)
	var router: TouchRouter = _kontrol(akar).router
	check(tombol != null and tombol.toggle_mode and tombol.text == "HUD_BANTU_MATI" and not tombol.button_pressed, "%s: tombol bantu sakelar, bawaan mati, teks kunci HUD_BANTU_MATI" % tag)
	check(tr("HUD_BANTU_MATI") == "Bantu: mati" and tr("HUD_BANTU_NYALA") == "Bantu: nyala", "%s: kunci terjemahan bantu ada (Bantu: mati / Bantu: nyala)" % tag)
	tombol.button_pressed = true
	check(akar.mode_bantu() and tombol.text == "HUD_BANTU_NYALA", "%s: ditekan = mode bantu nyala, teks status berubah (bukan hanya warna)" % tag)
	tombol.button_pressed = false
	check(not akar.mode_bantu() and tombol.text == "HUD_BANTU_MATI", "%s: dilepas = mati, teks kembali" % tag)
	akar.atur_mode_bantu(true)
	check(tombol.button_pressed and tombol.text == "HUD_BANTU_NYALA", "%s: atur_mode_bantu menyamakan tombol" % tag)
	akar.atur_mode_bantu(false)
	await _tree.process_frame
	for kidal: bool in [false, true]:
		(_anak(akar, "TombolKidal") as Button).button_pressed = kidal
		await _tree.process_frame
		await _tree.process_frame
		var mode: String = "%s %s" % [tag, "kidal" if kidal else "kanan"]
		var r: Rect2 = hud.rect_tombol_bantu()
		var kidal_r: Rect2 = hud.rect_tombol_kidal()
		check(r.size.x >= kidal_r.size.x - 0.5 and r.size.y >= kidal_r.size.y - 0.5 and r.size.x >= 96.0 and r.size.y >= 42.0, "%s: tombol bantu %s >= tombol kidal %s dan >= 96x42" % [mode, r.size, kidal_r.size])
		check(r.position.y >= 0.0 and r.end.y <= float(Config.HUD_STRIP_ATAS_TINGGI_PX) and r.position.x >= 0.0 and r.end.x <= float(lebar), "%s: tombol bantu di strip atas (%s)" % [mode, r])
		var bebas: bool = true
		for m: bool in [false, true]:
			if r.intersects(TouchZones.rect_stick(lebar, m), true) or r.intersects(TouchZones.rect_swipe(lebar, m), true):
				bebas = false
		check(bebas, "%s: tombol bantu di luar zona stick dan swipe (tangan kanan dan kidal)" % mode)
		check(not r.intersects(kidal_r, true) and not r.intersects(hud.rect_tombol_jeda(), true) and not r.intersects(hud.rect_panel_kecepatan(), true) and not r.intersects(hud.rect_panel_koran(), true), "%s: tombol bantu tidak bertumpuk dengan tombol kidal, tombol jeda, panel kecepatan, panel koran" % mode)
		# Sentuhan di tombol bantu tidak menjadi stick, swipe, atau tap.
		var tap_sebelum: int = router.jumlah_tap_selesai
		_sentuh(0, r.get_center(), true)
		check(router.jumlah_jari_aktif() == 0, "%s: sentuhan di tombol bantu bukan stick atau swipe" % mode)
		_sentuh(0, r.get_center(), false)
		check(router.jumlah_tap_selesai == tap_sebelum, "%s: sentuhan di tombol bantu bukan tap" % mode)
	var r_kidal: Rect2 = hud.rect_tombol_bantu()
	(_anak(akar, "TombolKidal") as Button).button_pressed = false
	await _tree.process_frame
	await _tree.process_frame
	check(hud.rect_tombol_bantu() == r_kidal, "%s: tombol bantu tidak berpindah saat kidal berganti" % tag)
	_bersihkan(akar)
