class_name TesBantuScene
extends RefCounted
## Tes terpadu mode bantu run fase2b-bantu-audio (AC-5, AC-6, AC-7, D-5 sampai D-7): scene jalan uji sungguhan, event sentuh sintetis
## lewat `Input.parse_input_event` (pola `tests/tes_koran_scene.gd`), langkah `JalanUji.perbarui(dt)` dengan dt tetap.
## - AC-5: tap di mode bantu melempar satu koran ke kotak surat (seberang dan dekat), gerbang jeda antar lempar 0,35, koran habis, jeda game,
##   mode bantu mati, swipe manual tetap jalan, kidal, tanpa sasaran (tanda tampil lalu hilang, koran dan jeda tetap).
## - AC-6: kecepatan otomatis = santai 3,0 u/d tanpa stick, stamina tidak turun; stick tetap mengubah kecepatan dan sisi.
## - AC-7: sakelar di HUD dev: mengubah mode di scene, teks kunci terjemahan dengan status bukan warna saja, ukuran >= tombol kidal, di luar
##   zona stick dan swipe (kidal maupun tidak) di 640, 780, 800, tidak bertumpuk dengan tombol kidal, tombol jeda, dan panel.
## - Kabel scene ke `BantuLempar.pilih` (QA-001 run fase2b-bantu-audio): daftar zona sejauh jangkauan penuh, kecepatan maju sebenarnya,
##   kecepatan lateral efektif, dan jeda lepas animasi. Harapan TIDAK diambil dari `JalanUji.pilihan_bantu`: kasus literal (rumah dan
##   pusat kotak surat ditulis di sini, titik lepas dari rumus BALANCING 4 dengan jeda lepas 2/12 literal), kisi keadaan yang dibandingkan
##   dengan `BantuLempar.pilih` yang dipanggil tes dengan masukan yang disusun tes sendiri, dan tap saat stick sungguhan melaju dan berbelok
##   dengan kecepatan lateral diukur dari perpindahan lateral sepeda.
## - Gerbang koran habis dan jeda antar lempar untuk tap tanpa sasaran (QA-002): tidak ada tanda, tidak ada `bantu_tanpa_sasaran`.
## Sisi tap yang diharapkan dihitung dari garis layar 1:2 lewat titik pijak sepeda (oracle independen, bukan `BantuLempar.sisi_tap`).

const BERKAS_JALAN_UJI: String = "res://scenes/dev/jalan_uji.tscn"
const SKALA: int = 3
const DT: float = 1.0 / 60.0
const LEBAR: float = 780.0
const TITIK_STICK: Vector2 = Vector2(100, 260)
## Ukuran jendela uji: [lebar jendela, tinggi jendela, lebar viewport game].
const KASUS_JENDELA: Array = [[1920, 1080, 640], [2340, 1080, 780], [2400, 1080, 800]]
## Jeda lepas yang diharapkan: frame lepas 2 pada 12 fps (semua animasi lempar `loper_agen_frames.tres`), ditulis literal.
const JEDA_LEPAS_HARAPAN: float = 2.0 / 12.0
## Toleransi perbandingan titik (ubin).
const TOL_UBIN: float = 0.000001
## Kasus literal kabel scene (QA-001): [kecepatan maju u/d, lateral ubin, kecepatan lateral efektif u/d (+ = ke dekat), maju ubin, sisi,
## rumah sasaran, pusat kotak surat sasaran (x lateral, y maju)]. Kotak surat seberang kavling k: x -2,125..-1,125, maju 4k + 0,375..1,875
## (area 1,0 x 1,5, pusat -1,625; 4k + 1,125); dekat: x 1,125..2,125, pusat 1,625 (BALANCING 5 / config `JALAN_UJI_*_KOTAK_SURAT_UBIN`). Seberang rumah 2 bukan pelanggan (2 mod 4 = 2), rumah 1
## (5,125) sudah di belakang, jadi sasaran seberang dari maju 5,75 sampai 7,5 adalah rumah 3 (13,125): di luar daftar +-1 kavling di
## sekitar sepeda (`zona_jalan_uji_sekitar`), di dalam jangkauan santai 7,75 dan ngebut 10,5.
const KASUS_KABEL: Array = [
	[3.0, 0.0, 0.0, 5.75, LoperAnim.Sisi.SEBERANG, 3, Vector2(-1.625, 13.125)],
	[3.0, 0.0, 0.0, 6.5, LoperAnim.Sisi.SEBERANG, 3, Vector2(-1.625, 13.125)],
	[3.0, 0.0, 0.0, 7.5, LoperAnim.Sisi.SEBERANG, 3, Vector2(-1.625, 13.125)],
	[4.5, 0.0, -2.0, 6.5, LoperAnim.Sisi.SEBERANG, 3, Vector2(-1.625, 13.125)],
	[6.0, 0.0, 2.0, 6.0, LoperAnim.Sisi.SEBERANG, 3, Vector2(-1.625, 13.125)],
	[6.0, 0.5, -2.4, 2.0, LoperAnim.Sisi.DEKAT, 1, Vector2(1.625, 5.125)],
	[4.5, -0.5, 2.4, 9.5, LoperAnim.Sisi.DEKAT, 3, Vector2(1.625, 13.125)],
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
	await _test_tap_melempar()
	await _test_jeda_antar_lempar_dan_habis()
	await _test_jeda_game()
	await _test_mode_mati_dan_swipe()
	await _test_kidal()
	await _test_tanpa_sasaran()
	await _test_tanpa_sasaran_gerbang()
	await _test_kabel_literal()
	for v: float in [Config.KECEPATAN_SANTAI_UD, Config.KECEPATAN_CEPAT_UD, Config.KECEPATAN_NGEBUT_UD]:
		await _test_kabel_kisi(v)
	await _test_kabel_stick()
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


func _test_tanpa_sasaran_gerbang() -> void:
	_judul.call("Mode bantu: tap tanpa sasaran saat koran habis atau jeda antar lempar = tanpa tanda, tanpa sinyal (QA-002, D-6)")
	var akar: JalanUji = await _siapkan()
	var catatan: Dictionary = _catat(akar)
	var kontrol: KontrolTouch = _kontrol(akar)
	_nyalakan_bantu(akar)
	# Maju 5,2 santai: tidak ada kotak surat seberang terjangkau (rumah 1 di belakang, rumah 2 bukan pelanggan, rumah 3 13,125 > 5,2 + 7,75).
	_sepeda(akar).jarak_ubin = 5.2
	akar.perbarui(0.0)
	check(akar.pilihan_bantu(LoperAnim.Sisi.SEBERANG) == null, "kontrol: maju 5,2 santai tanpa sasaran seberang")
	var tap: Vector2 = _tap_seberang(akar)
	# Koran habis (jeda antar lempar sudah lewat): tap tanpa sasaran ditolak gerbang koran dulu.
	var habis: SisaKoran.Keadaan = akar.koran.salin()
	habis.sisa = 0
	habis.sejak_lempar_detik = INF
	akar.koran = habis
	_tap(tap)
	check(not kontrol.tanda_tampil() and (catatan["tanpa"] as Array).is_empty() and (catatan["lempar"] as Array).is_empty() and akar.koran.sisa == 0, "koran habis + tanpa sasaran: tidak ada tanda, tidak ada bantu_tanpa_sasaran, tidak ada lemparan")
	# Jeda antar lempar belum lewat (0,1 < 0,35 detik), koran masih ada.
	var jeda: SisaKoran.Keadaan = akar.koran.salin()
	jeda.sisa = 30
	jeda.sejak_lempar_detik = 0.1
	akar.koran = jeda
	_tap(tap)
	check(not kontrol.tanda_tampil() and (catatan["tanpa"] as Array).is_empty() and (catatan["lempar"] as Array).is_empty() and akar.koran.sisa == 30 and is_equal_approx(akar.koran.sejak_lempar_detik, 0.1), "jeda antar lempar + tanpa sasaran: tidak ada tanda, tidak ada bantu_tanpa_sasaran, jeda tidak mulai ulang")
	# Kontrol: tap yang sama sesudah jeda antar lempar lewat memberi tanda (jadi tap tadi memang sampai ke scene).
	var bebas: SisaKoran.Keadaan = akar.koran.salin()
	bebas.sejak_lempar_detik = INF
	akar.koran = bebas
	_tap(tap)
	check(kontrol.tanda_tampil() and (catatan["tanpa"] as Array).size() == 1 and (catatan["lempar"] as Array).is_empty(), "kontrol: tap yang sama dengan koran ada dan jeda lewat = tanda dan satu bantu_tanpa_sasaran")
	_bersihkan(akar)


# --- Kabel scene ke BantuLempar.pilih (QA-001) ---

## Menaruh sepeda pada keadaan langkah terakhir tertentu tanpa memajukan waktu: kecepatan maju `v`, lateral, maju, lalu kecepatan lateral
## efektif `lateral_ud` (diisi sesudah `perbarui(0)`, karena langkah ber-dt 0 menolkannya). Koran penuh, jeda antar lempar lewat.
func _taruh_sepeda(akar: JalanUji, v: float, lateral: float, lateral_ud: float, maju: float) -> void:
	var sepeda: SepedaUji = _sepeda(akar)
	var k: BikeMotion.Keadaan = sepeda.keadaan.salin()
	k.kecepatan_ud = v
	k.lateral_ubin = lateral
	sepeda.keadaan = k
	sepeda.jarak_ubin = maju
	akar.perbarui(0.0)
	sepeda.lateral_ud = lateral_ud
	akar.koran = SisaKoran.awal(Config.KORAN_AWAL)


## Oracle sasaran: `BantuLempar.pilih` dengan masukan yang disusun tes (posisi dari lateral dan maju, kecepatan dan kecepatan lateral yang
## diberikan, jeda lepas 2/12 literal, lebar 780, zona jalan uji dari 4 ubin di belakang sampai 16 ubin di depan: lebih jauh dari jangkauan
## ngebut 10,5, jadi tidak bergantung pada `jangkauan_maju_ubin` scene).
func _pilihan_oracle(sisi: LoperAnim.Sisi, lateral: float, maju: float, v: float, lateral_ud: float) -> BantuLempar.Pilihan:
	return BantuLempar.pilih(sisi, Vector2(lateral, -maju), v, lateral_ud, JEDA_LEPAS_HARAPAN, LEBAR, ZonaSasaran.zona_jalan_uji_rentang(maju - 4.0, maju + 16.0))


## Titik lepas yang diharapkan (dunia), rumus BALANCING 4 ditulis di sini: posisi + geser selama jeda lepas 2/12 (maju = kecepatan x
## jeda; lateral = kecepatan lateral x jeda, ke dekat = +x, dijepit tepi jalan +-1).
func _lepas_harapan(lateral: float, maju: float, v: float, lateral_ud: float) -> Vector2:
	return Vector2(clampf(lateral + lateral_ud * JEDA_LEPAS_HARAPAN, -1.0, 1.0), -(maju + v * JEDA_LEPAS_HARAPAN))


func _dekat(a: Vector2, b: Vector2, tol: float = TOL_UBIN) -> bool:
	return absf(a.x - b.x) <= tol and absf(a.y - b.y) <= tol


## Tap ke `sisi` lewat sentuhan jari `index`; [lintasan yang dilempar atau null, true bila titik tap di zona swipe dan di sisi oracle].
func _tap_ke(akar: JalanUji, catatan: Dictionary, sisi: LoperAnim.Sisi, index: int = 1) -> Array:
	var tap: Vector2 = _tap_seberang(akar) if sisi == LoperAnim.Sisi.SEBERANG else _tap_dekat(akar)
	var sah: bool = _sisi_harapan(tap, akar.posisi_layar_sepeda()) == sisi and TouchZones.zona_di(tap, int(LEBAR), false) == TouchZones.Zona.SWIPE
	var jumlah: int = (catatan["lempar"] as Array).size()
	_tap(tap, index)
	var lempar: Array = catatan["lempar"] as Array
	return [lempar[jumlah] if lempar.size() == jumlah + 1 else null, sah]


func _test_kabel_literal() -> void:
	_judul.call("Mode bantu: kabel scene, sasaran dan titik lepas literal di santai, cepat, ngebut, lateral != 0 (QA-001, D-4, D-5)")
	var akar: JalanUji = await _siapkan()
	var catatan: Dictionary = _catat(akar)
	_nyalakan_bantu(akar)
	for kasus: Array in KASUS_KABEL:
		var v: float = kasus[0]
		var lateral: float = kasus[1]
		var lateral_ud: float = kasus[2]
		var maju: float = kasus[3]
		var sisi: LoperAnim.Sisi = kasus[4]
		var rumah: int = kasus[5]
		var pusat: Vector2 = kasus[6]
		var tag: String = "v %.1f lateral %.1f vl %.1f maju %.2f %s" % [v, lateral, lateral_ud, maju, LoperAnim.Sisi.keys()[sisi]]
		_taruh_sepeda(akar, v, lateral, lateral_ud, maju)
		var hasil: Array = _tap_ke(akar, catatan, sisi)
		var l: ThrowSolver.Lintasan = hasil[0]
		check(hasil[1], "%s: kontrol titik tap di zona swipe dan sisi oracle" % tag)
		check(l != null and not _kontrol(akar).tanda_tampil(), "%s: tap melempar (ada kotak surat rumah %d terjangkau), tanpa tanda" % [tag, rumah])
		if l == null:
			continue
		var mendarat_jalan: Vector2 = Vector2(l.titik_mendarat.x, -l.titik_mendarat.y)
		var kotak: Rect2 = Rect2(pusat - Vector2(0.25, 0.25), Vector2(0.5, 0.5))
		check(kotak.has_point(mendarat_jalan) and _dekat(mendarat_jalan, pusat, 0.001), "%s: mendarat di pusat kotak surat rumah %d %s (dapat %s)" % [tag, rumah, pusat, mendarat_jalan])
		var lepas: Vector2 = _lepas_harapan(lateral, maju, v, lateral_ud)
		check(_dekat(l.titik_lepas, lepas), "%s: titik lepas = posisi sepeda saat tap + geser selama jeda lepas 2/12 dengan kecepatan maju dan lateral sebenarnya %s (dapat %s)" % [tag, lepas, l.titik_lepas])
		check(is_equal_approx(l.kecepatan_maju_ud, v) and is_equal_approx(l.jeda_lepas, JEDA_LEPAS_HARAPAN) and l.sisi == sisi, "%s: lintasan mewarisi kecepatan %.1f dan jeda lepas 2/12 (dapat %.3f, %.4f)" % [tag, v, l.kecepatan_maju_ud, l.jeda_lepas])
	# Satu kasus dibiarkan terbang sampai mendarat: dinilai KOTAK_SURAT centang di rumah 3 seberang.
	_taruh_sepeda(akar, 3.0, 0.0, 0.0, 6.0)
	var akhir: Array = _tap_ke(akar, catatan, LoperAnim.Sisi.SEBERANG)
	var mendarat: KoranLempar.Koran = null
	if akhir[0] != null:
		var target: ThrowSolver.Lintasan = akhir[0]
		for i: int in range(roundi(2.0 / DT)):
			_langkah(akar, 1)
			for k: KoranLempar.Koran in catatan["mendarat"]:
				if k.lintasan == target:
					mendarat = k
			if mendarat != null:
				break
	check(mendarat != null and mendarat.hasil == ZonaSasaran.Hasil.KOTAK_SURAT and mendarat.penanda == ZonaSasaran.Penanda.CENTANG and ZonaSasaran.zona_kena(mendarat.lintasan.titik_mendarat, ZonaSasaran.zona_jalan_uji(3)) != null, "santai maju 6 seberang: koran mendarat dan dinilai KOTAK_SURAT centang di kavling rumah 3")
	_bersihkan(akar)


func _test_kabel_kisi(v: float) -> void:
	_judul.call("Mode bantu: kabel scene, kisi keadaan v %.1f lawan oracle BantuLempar.pilih dari masukan tes (QA-001, D-4)" % v)
	var akar: JalanUji = await _siapkan()
	var catatan: Dictionary = _catat(akar)
	var kontrol: KontrolTouch = _kontrol(akar)
	_nyalakan_bantu(akar)
	var keadaan: int = 0
	var bersasaran: int = 0
	var tanpa: int = 0
	var beda_sekitar: int = 0
	var salah: Array[String] = []
	var tap_tidak_sah: int = 0
	for lateral_ud: float in [0.0, 2.0, -2.0]:
		for i: int in range(64):
			var maju: float = i * 0.25
			for sisi: LoperAnim.Sisi in [LoperAnim.Sisi.SEBERANG, LoperAnim.Sisi.DEKAT]:
				keadaan += 1
				var harapan: BantuLempar.Pilihan = _pilihan_oracle(sisi, 0.0, maju, v, lateral_ud)
				var sekitar: BantuLempar.Pilihan = BantuLempar.pilih(sisi, Vector2(0.0, -maju), v, lateral_ud, JEDA_LEPAS_HARAPAN, LEBAR, ZonaSasaran.zona_jalan_uji_sekitar(maju))
				if (sekitar == null) != (harapan == null) or (sekitar != null and harapan != null and sekitar.zona.rumah != harapan.zona.rumah):
					beda_sekitar += 1
				_taruh_sepeda(akar, v, 0.0, lateral_ud, maju)
				var tanpa_sebelum: int = (catatan["tanpa"] as Array).size()
				var hasil: Array = _tap_ke(akar, catatan, sisi)
				if not hasil[1]:
					tap_tidak_sah += 1
				var l: ThrowSolver.Lintasan = hasil[0]
				var tag: String = "vl %.1f maju %.2f %s" % [lateral_ud, maju, LoperAnim.Sisi.keys()[sisi]]
				if harapan == null:
					tanpa += 1
					if l != null or (catatan["tanpa"] as Array).size() != tanpa_sebelum + 1 or not kontrol.tanda_tampil():
						salah.append("%s: harap tanpa sasaran" % tag)
					continue
				bersasaran += 1
				if l == null or not _dekat(l.titik_mendarat, harapan.lintasan.titik_mendarat) or not _dekat(l.titik_lepas, harapan.lintasan.titik_lepas) or not _dekat(l.titik_lepas, _lepas_harapan(0.0, maju, v, lateral_ud)):
					salah.append("%s: harap rumah %d" % [tag, harapan.zona.rumah])
	check(tap_tidak_sah == 0, "v %.1f: kontrol semua titik tap di zona swipe dan sisi oracle (%d tidak sah)" % [v, tap_tidak_sah])
	check(salah.is_empty(), "v %.1f: %d keadaan (3 kecepatan lateral x 64 maju x 2 sisi), tap di scene = oracle (lintasan, titik lepas, atau tanda tanpa sasaran); salah %d: %s" % [v, keadaan, salah.size(), salah.slice(0, 6)])
	check(bersasaran > 0 and tanpa > 0, "v %.1f: kontrol kisi mencakup keadaan bersasaran (%d) dan tanpa sasaran (%d)" % [v, bersasaran, tanpa])
	if is_equal_approx(v, Config.KECEPATAN_SANTAI_UD):
		check(beda_sekitar > 0, "v %.1f: kontrol kisi mencakup keadaan di mana daftar +-1 kavling (zona_jalan_uji_sekitar) memberi sasaran lain (%d)" % [v, beda_sekitar])
	_bersihkan(akar)


func _test_kabel_stick() -> void:
	_judul.call("Mode bantu: tap saat stick sungguhan melaju dan berbelok, lintasan = oracle dari besaran sepeda terukur (QA-001, D-4)")
	var akar: JalanUji = await _siapkan()
	var catatan: Dictionary = _catat(akar)
	var sepeda: SepedaUji = _sepeda(akar)
	_nyalakan_bantu(akar)
	# [kecepatan awal u/d, geser stick dari titik stick (piksel game), sisi tap, batas bawah kecepatan saat tap].
	var kasus_stick: Array = [
		[4.5, Vector2(25, -25), LoperAnim.Sisi.SEBERANG, 4.4],
		[4.5, Vector2(25, -25), LoperAnim.Sisi.DEKAT, 4.4],
		[6.0, Vector2(-15, -35), LoperAnim.Sisi.SEBERANG, 5.6],
		[6.0, Vector2(-15, -35), LoperAnim.Sisi.DEKAT, 5.6],
	]
	for kasus: Array in kasus_stick:
		var v_awal: float = kasus[0]
		var geser: Vector2 = kasus[1]
		var sisi: LoperAnim.Sisi = kasus[2]
		var v_min: float = kasus[3]
		var tag: String = "v awal %.1f stick %s %s" % [v_awal, geser, LoperAnim.Sisi.keys()[sisi]]
		_taruh_sepeda(akar, v_awal, 0.0, 0.0, 0.0)
		_sentuh(0, TITIK_STICK, true)
		_geser(0, TITIK_STICK + geser)
		var dilempar: bool = false
		for langkah_ke: int in range(360):
			# Sepeda dikembalikan ke tengah sebelum langkah bila mendekati tepi, supaya langkah berikutnya masih berbelok sungguhan.
			if absf(sepeda.lateral_ubin) > 0.6:
				var k: BikeMotion.Keadaan = sepeda.keadaan.salin()
				k.lateral_ubin = 0.0
				sepeda.keadaan = k
			var lateral_sebelum: float = sepeda.lateral_ubin
			_langkah(akar, 1)
			# Besaran sepeda dibaca langsung; kecepatan lateral efektif diukur dari perpindahan lateral selama langkah itu.
			var lateral_terukur: float = (sepeda.lateral_ubin - lateral_sebelum) / DT
			var v: float = sepeda.kecepatan_ud
			var lateral: float = sepeda.lateral_ubin
			var maju: float = sepeda.jarak_ubin
			if absf(lateral_terukur) < 0.5 or v < v_min:
				continue
			var harapan: BantuLempar.Pilihan = _pilihan_oracle(sisi, lateral, maju, v, lateral_terukur)
			if harapan == null:
				continue
			akar.koran = SisaKoran.awal(Config.KORAN_AWAL)
			var hasil: Array = _tap_ke(akar, catatan, sisi)
			var l: ThrowSolver.Lintasan = hasil[0]
			check(hasil[1], "%s: kontrol titik tap di zona swipe dan sisi oracle" % tag)
			check(l != null and _dekat(l.titik_mendarat, harapan.lintasan.titik_mendarat) and _dekat(l.titik_lepas, harapan.lintasan.titik_lepas), "%s: tap saat v %.3f, vl terukur %.2f, maju %.3f: lintasan = oracle (rumah %d, mendarat %s; dapat %s)" % [tag, v, lateral_terukur, maju, harapan.zona.rumah, harapan.lintasan.titik_mendarat, str(l.titik_mendarat) if l != null else "null"])
			var lepas: Vector2 = _lepas_harapan(lateral, maju, v, lateral_terukur)
			check(l != null and _dekat(l.titik_lepas, lepas), "%s: titik lepas = posisi saat tap + geser selama jeda lepas 2/12 dengan kecepatan dan kecepatan lateral terukur %s (dapat %s)" % [tag, lepas, str(l.titik_lepas) if l != null else "null"])
			dilempar = true
			break
		check(dilempar, "%s: ada saat melaju dan berbelok dengan sasaran terjangkau (tap dilakukan)" % tag)
		_sentuh(0, TITIK_STICK + geser, false)
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
