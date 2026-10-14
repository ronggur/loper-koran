class_name TesKoranScene
extends RefCounted
## Tes terpadu lemparan koran run fase2a-lemparan bagian 1b (AC-4, AC-6, AC-7, AC-8, AC-9 bagian scene): scene jalan uji sungguhan, event
## sentuh sintetis lewat `Input.parse_input_event` di viewport 780x360 (pola `tests/tes_input_scene.gd`), langkah `JalanUji.perbarui(dt)`
## dengan `dt` tetap, waktu animasi lempar lewat `LoperSprite.maju(dt)`.
## - AC-4: titik akhir garis bidik pada frame jari dilepas = titik mendarat koran (<= 1e-4 ubin) sesudah koran disimulasikan frame demi
##   frame dengan dt 1/30 dan 1/240, sementara sepeda mempercepat, mengerem, dan pindah sisi selama jeda lepas dan terbang; titik garis
##   bidik adalah sampel `posisi_pada`; kontrol: keadaan sepeda memang berubah (jadi tes membedakan garis bidik dari frame sebelumnya
##   dan lintasan yang dihitung ulang saat frame lepas).
## - AC-6: 30 koran, tiap lemparan -1 tepat sekali, jeda 0,349 ditolak dan 0,35 diterima, swipe dalam jeda tidak mengurangi, habis =
##   tanpa garis bidik dan tanpa lempar, isi ulang uji 16 ubin, dua lempar cepat (animasi utuh, `koran_lepas` tepat sekali per lemparan).
## - AC-7: jeda game membekukan koran terbang, jeda antar lempar, dan penanda; lanjut tanpa lompatan; jeda di antara jari dilepas dan
##   frame lepas tidak menghilangkan atau menggandakan lemparan; swipe yang ditahan saat jeda tidak melempar.
## - AC-8: arah swipe ke sisi, garis bidik tampil saat ditahan dan hilang saat dilepas/batal, dua jari, kidal, sentuhan di panel HUD koran
##   tetap swipe, swipe tegak/pendek tidak melempar; elips sah berubah bentuk; jendela penalti tidak sah (sakelar bawaan).
## - HUD koran: angka, ikon terang/redup, penanda habis; zona placeholder digambar (bukan pelanggan bertanda bentuk).

const BERKAS_JALAN_UJI: String = "res://scenes/dev/jalan_uji.tscn"
const SKALA: int = 3
const DT: float = 1.0 / 60.0
const LEBAR: float = 780.0
const TITIK_STICK: Vector2 = Vector2(100, 260)
const SWIPE_Y: float = 200.0
const SWIPE_AWAL_DEKAT_X: float = 230.0
const SWIPE_AWAL_SEBERANG_X: float = 720.0
const TOL_PREDIKSI: float = 0.0001

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
	await _test_scene_tersambung()
	for dt: float in [1.0 / 30.0, 1.0 / 240.0]:
		for skenario: String in ["A", "B"]:
			await _test_prediksi_sama_hasil(dt, skenario)
	await _test_sisa_koran_dan_jeda()
	await _test_dua_lempar_cepat()
	await _test_habis_dan_isi_ulang()
	for pemicu: String in ["TOMBOL", "PAUSED", "FOCUS_OUT"]:
		await _test_jeda_game_saat_terbang(pemicu)
	await _test_jeda_sebelum_lepas()
	await _test_swipe_ditahan_saat_jeda()
	await _test_input_dan_kidal()
	await _test_elips_dan_jendela()
	await _test_hud_dan_zona()


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
	(_anak(akar, "KontrolTouch") as KontrolTouch).keyboard_aktif = OS.has_feature("editor")
	_tree.root.remove_child(akar)
	akar.free()


func _anak(akar: Node, nama: String) -> Node:
	return akar.find_child(nama, true, false)


## Sprite pemain dengan `_process` dimatikan (waktu lempar dimajukan tes).
func _sprite(akar: JalanUji) -> LoperSprite:
	var sprite: LoperSprite = _anak(akar, "LoperAgen") as LoperSprite
	sprite.set_process(false)
	return sprite


func _sepeda(akar: JalanUji) -> SepedaUji:
	return _anak(akar, "Sepeda") as SepedaUji


func _router(akar: JalanUji) -> TouchRouter:
	return (_anak(akar, "KontrolTouch") as KontrolTouch).router


func _sentuh(index: int, posisi_viewport: Vector2, tekan: bool, batal: bool = false) -> void:
	var peristiwa: InputEventScreenTouch = InputEventScreenTouch.new()
	peristiwa.index = index
	peristiwa.position = posisi_viewport * float(SKALA)
	peristiwa.pressed = tekan
	peristiwa.canceled = batal
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


## Langkah scene dan sprite `jumlah` kali dengan `dt`.
func _langkah(akar: JalanUji, jumlah: int, dt: float = DT) -> void:
	var sprite: LoperSprite = _sprite(akar)
	for i: int in range(jumlah):
		akar.perbarui(dt)
		sprite.maju(dt)


func _awal(sisi: LoperAnim.Sisi) -> Vector2:
	return Vector2(SWIPE_AWAL_SEBERANG_X if sisi == LoperAnim.Sisi.SEBERANG else SWIPE_AWAL_DEKAT_X, SWIPE_Y)


func _akhir(sisi: LoperAnim.Sisi, dx: float) -> Vector2:
	return _awal(sisi) + Vector2(-dx if sisi == LoperAnim.Sisi.SEBERANG else dx, 0)


## |dx| untuk kekuatan u di viewport 780.
func _dx(u: float) -> float:
	return ThrowSolver.swipe_min_px(LEBAR) + u * (ThrowSolver.swipe_maks_px(LEBAR) - ThrowSolver.swipe_min_px(LEBAR))


## Swipe penuh (turun, geser, angkat) jari 1 ke `sisi` sepanjang `dx`.
func _swipe(sisi: LoperAnim.Sisi, dx: float, index: int = 1) -> void:
	_sentuh(index, _awal(sisi), true)
	_geser(index, _akhir(sisi, dx))
	_sentuh(index, _akhir(sisi, dx), false)


## Mencatat sinyal `koran_dilempar` (lintasan) dan `koran_mendarat` (koran) akar.
func _catat(akar: JalanUji) -> Dictionary:
	var catatan: Dictionary = {"lempar": [], "mendarat": []}
	akar.koran_dilempar.connect(func(l: ThrowSolver.Lintasan) -> void: (catatan["lempar"] as Array).append(l))
	akar.koran_mendarat.connect(func(k: KoranLempar.Koran) -> void: (catatan["mendarat"] as Array).append(k))
	return catatan


func _catat_sprite(akar: JalanUji) -> Array:
	var sprite: LoperSprite = _sprite(akar)
	var catatan: Array = []
	sprite.koran_lepas.connect(func(sisi: LoperAnim.Sisi) -> void: catatan.append(["lepas", int(sisi)]))
	sprite.lempar_selesai.connect(func() -> void: catatan.append(["selesai", -1]))
	return catatan


func _jumlah(catatan: Array, jenis: String) -> int:
	var hasil: int = 0
	for entri: Array in catatan:
		if entri[0] == jenis:
			hasil += 1
	return hasil


func _dekat_v(a: Vector2, b: Vector2, tol: float = TOL_PREDIKSI) -> bool:
	return absf(a.x - b.x) <= tol and absf(a.y - b.y) <= tol


func _sama(a: ThrowSolver.Lintasan, b: ThrowSolver.Lintasan) -> bool:
	return a != null and b != null and a.sisi == b.sisi and a.titik_lepas == b.titik_lepas and a.titik_mendarat == b.titik_mendarat and a.lama_terbang == b.lama_terbang and a.tinggi_puncak == b.tinggi_puncak and a.jeda_lepas == b.jeda_lepas


## Menahan jari 1 di panjang yang membuat garis bidik mengarah ke `sasaran` (dicari dari keadaan saat ini, sepeda maju tiap langkah).
## True bila garis bidik yang tampil sesudah langkah terakhir mengarah ke sasaran (jari masih ditahan).
func _bidik_ke(akar: JalanUji, sisi: LoperAnim.Sisi, sasaran: ZonaSasaran.Hasil) -> bool:
	var garis: GarisBidik = akar.garis_bidik()
	var router: TouchRouter = _router(akar)
	for i: int in range(360):
		var dx: float = -1.0
		var coba: float = ceilf(ThrowSolver.swipe_min_px(LEBAR))
		while coba <= ThrowSolver.swipe_maks_px(LEBAR):
			var l: ThrowSolver.Lintasan = akar.lintasan_swipe(_awal(sisi), _akhir(sisi, coba))
			if l != null and KoranLempar.hasil_mendarat(l) == sasaran:
				dx = coba
				break
			coba += 1.0
		if dx > 0.0 and SisaKoran.boleh_lempar(akar.koran):
			if not router.swipe_aktif():
				_sentuh(1, _awal(sisi), true)
			_geser(1, _akhir(sisi, dx))
		elif router.swipe_aktif():
			_geser(1, _awal(sisi))
			_sentuh(1, _awal(sisi), false)
		_langkah(akar, 1)
		if garis.tampil() and KoranLempar.hasil_mendarat(garis.lintasan()) == sasaran:
			return true
	return false


## Melangkah sampai koran terakhir mendarat (paling lama 2 detik). Koran yang mendarat, atau null.
func _sampai_mendarat(akar: JalanUji, catatan: Dictionary, dt: float = DT) -> KoranLempar.Koran:
	var sebelum: int = (catatan["mendarat"] as Array).size()
	for i: int in range(roundi(2.0 / dt)):
		_langkah(akar, 1, dt)
		if (catatan["mendarat"] as Array).size() > sebelum:
			return (catatan["mendarat"] as Array)[sebelum]
	return null


# --- Scene tersambung ---

func _test_scene_tersambung() -> void:
	_judul.call("Lemparan di scene: node garis bidik, koran, zona (D-5, D-10)")
	var akar: JalanUji = await _siapkan()
	var garis: GarisBidik = akar.garis_bidik()
	var tanah: KoranGambar = _anak(akar, "KoranTanah") as KoranGambar
	var udara: KoranGambar = _anak(akar, "KoranUdara") as KoranGambar
	var zona: ZonaGambar = _anak(akar, "Zona") as ZonaGambar
	var objek: Node = _anak(akar, "Objek")
	var lapis_tanah: Node = _anak(akar, "Tanah")
	check(garis != null and tanah != null and udara != null and zona != null, "scene memuat GarisBidik, KoranTanah, KoranUdara, Zona")
	check(garis.get_parent() == akar and garis.get_canvas_layer_node() == null, "garis bidik di ruang dunia (anak akar Node2D, bukan CanvasLayer): ikut kamera")
	check(tanah.lapisan == KoranGambar.Lapisan.TANAH and udara.lapisan == KoranGambar.Lapisan.UDARA, "lapisan koran: TANAH (bayangan) dan UDARA (koran, penanda)")
	var i_tanah: int = lapis_tanah.get_index()
	check(i_tanah < zona.get_index() and zona.get_index() < objek.get_index() and tanah.get_index() < objek.get_index(), "zona dan bayangan koran digambar sesudah ubin tanah dan sebelum objek dunia (rumah, sepeda)")
	check(udara.get_index() > objek.get_index() and garis.get_index() > objek.get_index(), "koran di udara dan garis bidik digambar di atas objek dunia")
	check(akar.koran.sisa == Config.KORAN_AWAL and Config.KORAN_AWAL == 30, "jalan uji mulai dengan 30 koran (BALANCING 4)")
	check(not garis.tampil() and akar.koran_terbang().is_empty(), "awal: tanpa garis bidik dan tanpa koran terbang")
	_bersihkan(akar)


# --- AC-4: prediksi = hasil ---

## Skenario A: santai lalu stick ke atas (mempercepat) selama bidik, serong dekat sambil mempercepat selama jeda lepas, rem selama terbang.
## Skenario B: ngebut lalu stick ke bawah (meluncur) selama bidik, pindah ke sisi seberang selama jeda lepas, ngebut lagi selama terbang.
func _test_prediksi_sama_hasil(dt: float, skenario: String) -> void:
	var tag: String = "skenario %s dt 1/%d" % [skenario, roundi(1.0 / dt)]
	_judul.call("Prediksi = hasil di scene, %s (AC-4, D-4)" % tag)
	var akar: JalanUji = await _siapkan()
	var sepeda: SepedaUji = _sepeda(akar)
	var garis: GarisBidik = akar.garis_bidik()
	var catatan: Dictionary = _catat(akar)
	var r: float = Config.STICK_RADIUS_PX
	var atas: Vector2 = TITIK_STICK - Vector2(0, r)
	var bawah: Vector2 = TITIK_STICK + Vector2(0, r)
	var stick_bidik: Vector2 = atas if skenario == "A" else TITIK_STICK + Vector2(0, r * 0.85)
	var stick_lepas: Vector2 = TITIK_STICK + Vector2(r * 0.6, -r * 0.6) if skenario == "A" else TITIK_STICK - Vector2(r, 0)
	var stick_terbang: Vector2 = bawah if skenario == "A" else atas
	var sisi: LoperAnim.Sisi = LoperAnim.Sisi.SEBERANG if skenario == "A" else LoperAnim.Sisi.DEKAT
	var dx: float = _dx(1.0) if skenario == "A" else _dx(0.5)
	_sentuh(0, TITIK_STICK, true)
	if skenario == "B":
		_geser(0, atas)
		_langkah(akar, roundi(2.5 / dt), dt)
	_geser(0, stick_bidik)
	_sentuh(1, _awal(sisi), true)
	_geser(1, _akhir(sisi, dx))
	var langkah_bidik: int = roundi(0.3 / dt)
	_langkah(akar, langkah_bidik - 1, dt)
	var sebelum: ThrowSolver.Lintasan = garis.lintasan()
	var v_sebelum: float = sepeda.kecepatan_ud
	_langkah(akar, 1, dt)
	var tampil: ThrowSolver.Lintasan = garis.lintasan()
	var titik_akhir: Vector3 = garis.titik_akhir()
	check(garis.tampil() and tampil != null, "%s: garis bidik tampil selama jari ditahan" % tag)
	if tampil == null:
		_bersihkan(akar)
		return
	check(sepeda.kecepatan_ud != v_sebelum and not _dekat_v(sebelum.titik_mendarat, tampil.titik_mendarat, 0.001), "%s: kontrol: keadaan sepeda berubah di frame terakhir bidik (%s -> %s u/d), jadi garis bidik dari frame sebelumnya akan meleset" % [tag, v_sebelum, sepeda.kecepatan_ud])
	check(titik_akhir.z == 0.0 and _dekat_v(Vector2(titik_akhir.x, titik_akhir.y), tampil.titik_mendarat, 0.0), "%s: titik akhir garis bidik = titik mendarat lintasan yang ditampilkan, tinggi 0" % tag)
	# Titik garis bidik = sampel posisi_pada (bukan rumus kedua).
	var waktu: PackedFloat32Array = KoranLempar.waktu_titik_bidik(tampil, float(Config.SWIPE_TITIK_JARAK_PX), Config.GARIS_BIDIK_SAMPEL)
	var titik: PackedVector2Array = garis.titik_gambar()
	var sampel_benar: bool = titik.size() == waktu.size() and titik.size() >= 8
	for i: int in range(mini(titik.size(), waktu.size())):
		var p: Vector3 = ThrowSolver.posisi_pada(tampil, waktu[i])
		if titik[i] != Iso.dunia_tinggi_ke_layar(Vector2(p.x, p.y), p.z).round():
			sampel_benar = false
	check(sampel_benar, "%s: %d titik garis bidik = proyeksi ThrowSolver.posisi_pada pada waktu sampel" % [tag, titik.size()])
	check(garis.pojok_elips() == Iso.posisi_gambar(tampil.titik_mendarat) - Vector2(5, 2), "%s: elips 10x5 berpusat di titik mendarat (ruang dunia, bulat)" % tag)
	# Jari dilepas di titik yang sama: lintasan lemparan = garis bidik yang tampil.
	var sisa: int = akar.koran.sisa
	_sentuh(1, _akhir(sisi, dx), false)
	check(not garis.tampil(), "%s: garis bidik hilang saat jari dilepas" % tag)
	var dilempar: Array = catatan["lempar"]
	check(dilempar.size() == 1 and akar.koran.sisa == sisa - 1, "%s: satu lemparan diterima, koran -1" % tag)
	if dilempar.size() != 1:
		_bersihkan(akar)
		return
	var lintasan: ThrowSolver.Lintasan = dilempar[0]
	check(_sama(lintasan, tampil), "%s: lintasan lemparan = lintasan garis bidik frame jari dilepas (sisi, titik lepas, titik mendarat, lama, puncak, jeda lepas)" % tag)
	check(lintasan.jeda_lepas > 0.16 and lintasan.jeda_lepas < 0.17, "%s: jeda lepas = frame lepas animasi (2/12 detik), dapat %s" % [tag, lintasan.jeda_lepas])
	# Jeda lepas: sepeda berubah gerak; koran belum tampil di udara.
	_geser(0, stick_lepas)
	var koran: KoranLempar.Koran = akar.koran_terbang()[0]
	var v_lepas: float = sepeda.kecepatan_ud
	var lateral_lepas: float = sepeda.lateral_ubin
	var hitung_ulang: ThrowSolver.Lintasan = null
	for i: int in range(roundi(1.0 / dt)):
		_langkah(akar, 1, dt)
		koran = akar.koran_terbang()[0]
		if KoranLempar.di_udara(koran):
			hitung_ulang = akar.lintasan_swipe(_awal(sisi), _akhir(sisi, dx))
			break
		if i == 0:
			check(KoranLempar.posisi(koran) == Vector3(lintasan.titik_lepas.x, lintasan.titik_lepas.y, lintasan.tinggi_tangan), "%s: sebelum lepas koran di titik lepas setinggi tangan" % tag)
	check(hitung_ulang != null and koran.detik + 0.00001 >= lintasan.jeda_lepas and koran.detik - dt < lintasan.jeda_lepas + 0.00001, "%s: koran tampil di udara pada langkah yang melewati jeda lepas (detik %s)" % [tag, koran.detik])
	check(hitung_ulang != null and not _dekat_v(hitung_ulang.titik_mendarat, lintasan.titik_mendarat, 0.001), "%s: kontrol: lintasan yang dihitung ulang saat frame lepas dari keadaan baru berbeda (%s lawan %s), jadi menghitung ulang akan ketahuan" % [tag, hitung_ulang.titik_mendarat if hitung_ulang != null else Vector2.ZERO, lintasan.titik_mendarat])
	check(sepeda.kecepatan_ud != v_lepas or sepeda.lateral_ubin != lateral_lepas, "%s: kontrol: sepeda berubah gerak selama jeda lepas (%s u/d, lateral %s -> %s)" % [tag, sepeda.kecepatan_ud, lateral_lepas, sepeda.lateral_ubin])
	# Terbang: sepeda berubah gerak lagi; koran mengikuti posisi_sejak_jari lintasan beku dan mendarat tepat di prediksi.
	_geser(0, stick_terbang)
	var v_terbang: float = sepeda.kecepatan_ud
	var mengikuti: bool = true
	var mendarat: KoranLempar.Koran = null
	for i: int in range(roundi(2.0 / dt)):
		_langkah(akar, 1, dt)
		if not (catatan["mendarat"] as Array).is_empty():
			mendarat = (catatan["mendarat"] as Array)[0]
			break
		koran = akar.koran_terbang()[0]
		if KoranLempar.posisi(koran) != ThrowSolver.posisi_sejak_jari(lintasan, koran.detik):
			mengikuti = false
	check(mengikuti, "%s: tiap frame posisi koran = ThrowSolver.posisi_sejak_jari(lintasan beku)" % tag)
	check(mendarat != null, "%s: koran mendarat" % tag)
	if mendarat != null:
		var p: Vector3 = KoranLempar.posisi(mendarat)
		check(_dekat_v(Vector2(p.x, p.y), Vector2(titik_akhir.x, titik_akhir.y)) and p.z == 0.0, "%s: titik mendarat koran %s = titik akhir garis bidik frame jari dilepas %s (<= 1e-4 ubin)" % [tag, p, titik_akhir])
		check(mendarat.detik + 0.00001 >= ThrowSolver.lama_total(lintasan) and mendarat.detik - dt < ThrowSolver.lama_total(lintasan) + 0.00001, "%s: mendarat pada langkah yang melewati jeda lepas + lama terbang" % tag)
		check(mendarat.hasil == KoranLempar.hasil_mendarat(lintasan), "%s: hasil sasaran dinilai di titik prediksi" % tag)
	check(sepeda.kecepatan_ud != v_terbang, "%s: kontrol: kecepatan sepeda berubah selama terbang (%s -> %s u/d)" % [tag, v_terbang, sepeda.kecepatan_ud])
	_bersihkan(akar)


# --- AC-6: sisa koran, jeda antar lempar, dua lempar cepat ---

func _test_sisa_koran_dan_jeda() -> void:
	_judul.call("Sisa koran dan jeda antar lempar 0,35 di scene (AC-6, D-8, D-9)")
	var akar: JalanUji = await _siapkan()
	var hud: HudDev = _anak(akar, "Hud") as HudDev
	var catatan: Dictionary = _catat(akar)
	var garis: GarisBidik = akar.garis_bidik()
	check(hud.teks_koran() == "30" and hud.ikon_koran() == Vector2i(8, 8) and not hud.penanda_habis_tampil(), "HUD awal: angka 30, 8 ikon terang, tanpa penanda habis")
	_swipe(LoperAnim.Sisi.SEBERANG, _dx(0.5))
	check(akar.koran.sisa == 29 and (catatan["lempar"] as Array).size() == 1 and hud.teks_koran() == "29", "lemparan pertama: 30 -> 29 (tepat sekali), HUD 29")
	# Jeda: 0,349 ditolak, swipe dalam jeda tidak mengurangi dan tidak memulai ulang jeda; 0,35 diterima.
	akar.perbarui(0.349)
	_sentuh(1, _awal(LoperAnim.Sisi.DEKAT), true)
	_geser(1, _akhir(LoperAnim.Sisi.DEKAT, _dx(0.5)))
	akar.perbarui(0.0)
	check(not garis.tampil(), "dalam jeda antar lempar (0,349): garis bidik tidak tampil walau swipe ditahan")
	_sentuh(1, _akhir(LoperAnim.Sisi.DEKAT, _dx(0.5)), false)
	check(akar.koran.sisa == 29 and (catatan["lempar"] as Array).size() == 1, "swipe dilepas di 0,349 detik: ditolak, koran tetap 29")
	check(is_equal_approx(akar.koran.sejak_lempar_detik, 0.349), "swipe yang ditolak tidak memulai ulang jeda (%s)" % akar.koran.sejak_lempar_detik)
	akar.perbarui(0.001)
	_swipe(LoperAnim.Sisi.DEKAT, _dx(0.5))
	check(akar.koran.sisa == 28 and (catatan["lempar"] as Array).size() == 2, "0,35 detik (inklusif): diterima, koran 28")
	# Swipe tidak sah (tegak, pendek) tidak mengurangi.
	akar.perbarui(Config.LEMPAR_JEDA_DETIK)
	_sentuh(1, Vector2(450, 250), true)
	_geser(1, Vector2(450, 150))
	_sentuh(1, Vector2(450, 150), false)
	_swipe(LoperAnim.Sisi.SEBERANG, ThrowSolver.swipe_min_px(LEBAR) - 1.0)
	check(akar.koran.sisa == 28 and (catatan["lempar"] as Array).size() == 2, "swipe tegak dan swipe di bawah 6% tidak melempar dan tidak mengurangi koran")
	_bersihkan(akar)


## Dua lempar cepat: lemparan kedua tepat sesudah jeda 0,35 (animasi 0,333 sudah selesai), dan lemparan kedua saat waktu sprite tertinggal
## (lempar menyela). Animasi tidak rusak dan `koran_lepas` tepat sekali per lemparan.
func _test_dua_lempar_cepat() -> void:
	_judul.call("Dua lempar cepat: animasi utuh, koran_lepas sekali per lemparan (AC-6, D-9)")
	var akar: JalanUji = await _siapkan()
	var sepeda: SepedaUji = _sepeda(akar)
	var catatan: Dictionary = _catat(akar)
	var sinyal: Array = _catat_sprite(akar)
	_swipe(LoperAnim.Sisi.SEBERANG, _dx(0.3))
	_langkah(akar, 20)
	_swipe(LoperAnim.Sisi.DEKAT, _dx(0.3))
	check((catatan["lempar"] as Array).size() == 1 and _jumlah(sinyal, "lepas") == 1 and _jumlah(sinyal, "selesai") == 1, "20 langkah (0,333 detik): lemparan kedua ditolak jeda; lempar pertama selesai dengan koran_lepas dan lempar_selesai sekali")
	_langkah(akar, 1)
	_swipe(LoperAnim.Sisi.DEKAT, _dx(0.3))
	check((catatan["lempar"] as Array).size() == 2 and sepeda.nama_animasi() == &"lempar_kanan_santai_normal" and _sprite(akar).frame == 0, "21 langkah (0,35): lemparan kedua diterima, animasi lempar dekat dari frame 0")
	_langkah(akar, 25)
	check(_jumlah(sinyal, "lepas") == 2 and _jumlah(sinyal, "selesai") == 2 and not sepeda.sedang_melempar() and sepeda.nama_animasi() == &"santai_normal", "dua lemparan: 2 koran_lepas, 2 lempar_selesai, kembali ke santai_normal")
	# Waktu sprite tertinggal dari waktu scene: lemparan kedua menyela animasi pertama yang belum sampai frame lepas.
	sinyal.clear()
	akar.perbarui(Config.LEMPAR_JEDA_DETIK)
	_swipe(LoperAnim.Sisi.SEBERANG, _dx(0.3))
	_sprite(akar).maju(DT)
	akar.perbarui(Config.LEMPAR_JEDA_DETIK)
	_swipe(LoperAnim.Sisi.DEKAT, _dx(0.3))
	check((catatan["lempar"] as Array).size() == 4 and akar.koran.sisa == 26, "lemparan saat animasi sebelumnya masih berjalan tetap diterima bila jeda lewat (koran 26)")
	check(_jumlah(sinyal, "lepas") == 1 and sinyal[0][1] == int(LoperAnim.Sisi.SEBERANG) and _jumlah(sinyal, "selesai") == 1, "lempar pertama yang disela: koran_lepas (seberang) dan lempar_selesai sekali")
	check(sepeda.nama_animasi() == &"lempar_kanan_santai_normal" and _sprite(akar).frame == 0, "lempar kedua mulai utuh dari frame 0")
	_langkah(akar, 25)
	check(_jumlah(sinyal, "lepas") == 2 and _jumlah(sinyal, "selesai") == 2, "total 2 koran_lepas dan 2 lempar_selesai untuk 2 lemparan")
	check(akar.koran_terbang().size() <= 4 and (catatan["mendarat"] as Array).size() >= 2, "koran lemparan cepat terbang dan mendarat sendiri-sendiri")
	_bersihkan(akar)


func _test_habis_dan_isi_ulang() -> void:
	_judul.call("Koran habis dan isi ulang jalan uji (AC-6, D-8)")
	var akar: JalanUji = await _siapkan()
	var sepeda: SepedaUji = _sepeda(akar)
	var hud: HudDev = _anak(akar, "Hud") as HudDev
	var catatan: Dictionary = _catat(akar)
	var garis: GarisBidik = akar.garis_bidik()
	for i: int in range(30):
		akar.perbarui(Config.LEMPAR_JEDA_DETIK)
		_swipe(LoperAnim.Sisi.DEKAT if i % 2 == 0 else LoperAnim.Sisi.SEBERANG, _dx(0.4))
		if i == 25:
			check(hud.teks_koran() == "4" and hud.ikon_koran() == Vector2i(8, 4), "sisa 4: angka 4, 4 dari 8 ikon terang (sisanya redup)")
	check((catatan["lempar"] as Array).size() == 30 and akar.koran.sisa == 0, "30 lemparan diterima, sisa 0")
	akar.perbarui(Config.LEMPAR_JEDA_DETIK)
	check(hud.teks_koran() == "0" and hud.ikon_koran() == Vector2i(8, 0) and hud.penanda_habis_tampil(), "habis: angka 0, semua ikon redup, penanda HABIS tampil (bukan hanya warna)")
	_sentuh(1, _awal(LoperAnim.Sisi.DEKAT), true)
	_geser(1, _akhir(LoperAnim.Sisi.DEKAT, _dx(0.4)))
	akar.perbarui(DT)
	check(not garis.tampil(), "habis: garis bidik tidak tampil walau swipe ditahan")
	_sentuh(1, _akhir(LoperAnim.Sisi.DEKAT, _dx(0.4)), false)
	check((catatan["lempar"] as Array).size() == 30 and akar.koran.sisa == 0, "habis: swipe tidak melempar, sisa tetap 0")
	var habis_di: float = akar.koran.habis_di_ubin
	sepeda.jarak_ubin = habis_di + Config.JALAN_UJI_ISI_ULANG_UBIN - 0.01
	akar.perbarui(0.0)
	check(akar.koran.sisa == 0, "15,99 ubin sesudah habis: belum diisi ulang")
	# 16,001 (bukan tepat 16): (a + 16) - a pada float tidak selalu tepat 16; tepi tepat 16 dites murni di tes_lempar.gd.
	sepeda.jarak_ubin = habis_di + Config.JALAN_UJI_ISI_ULANG_UBIN + 0.001
	akar.perbarui(0.0)
	check(akar.koran.sisa == 30 and hud.teks_koran() == "30" and not hud.penanda_habis_tampil(), "16,001 ubin sesudah habis: terisi ulang 30, HUD kembali, penanda habis hilang")
	_swipe(LoperAnim.Sisi.SEBERANG, _dx(0.4))
	check(akar.koran.sisa == 29, "sesudah isi ulang lemparan diterima lagi")
	_bersihkan(akar)


# --- AC-7: jeda game ---

func _jeda(akar: JalanUji, pemicu: String) -> void:
	match pemicu:
		"TOMBOL":
			akar.minta_jeda()
		"PAUSED":
			_tree.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
		"FOCUS_OUT":
			_tree.root.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)


func _test_jeda_game_saat_terbang(pemicu: String) -> void:
	_judul.call("Jeda game (%s) saat koran terbang: beku, lanjut tanpa lompatan (AC-7, D-11)" % pemicu)
	var akar: JalanUji = await _siapkan()
	var catatan: Dictionary = _catat(akar)
	_swipe(LoperAnim.Sisi.SEBERANG, _dx(0.8))
	var lintasan: ThrowSolver.Lintasan = (catatan["lempar"] as Array)[0]
	_langkah(akar, 18)
	var koran: KoranLempar.Koran = akar.koran_terbang()[0]
	check(KoranLempar.di_udara(koran), "%s: koran di udara sebelum jeda" % pemicu)
	var detik: float = koran.detik
	var posisi: Vector3 = KoranLempar.posisi(koran)
	var sejak: float = akar.koran.sejak_lempar_detik
	_jeda(akar, pemicu)
	check(akar.sedang_jeda(), "%s: jeda" % pemicu)
	for dt: float in [DT, 0.1, 5.0, 100.0]:
		akar.perbarui(dt)
		akar._process(dt)
	koran = akar.koran_terbang()[0]
	check(koran.detik == detik and KoranLempar.posisi(koran) == posisi and akar.koran.sejak_lempar_detik == sejak and (catatan["mendarat"] as Array).is_empty(), "%s: perbarui dan _process dengan dt besar tidak memajukan koran (waktu %s, posisi %s), jeda antar lempar, atau pendaratan" % [pemicu, koran.detik, KoranLempar.posisi(koran)])
	check(akar.koran.sisa == 29 and akar.koran_terbang().size() == 1, "%s: koran yang sudah diterima tidak hilang dan tidak dihitung dua kali" % pemicu)
	akar.minta_lanjut()
	akar.perbarui(0.1)
	check(akar.koran_terbang()[0].detik == detik, "%s: langkah pertama sesudah lanjut ber-dt 0 (tanpa lompatan)" % pemicu)
	var mendarat: KoranLempar.Koran = _sampai_mendarat(akar, catatan)
	check(mendarat != null and _dekat_v(Vector2(KoranLempar.posisi(mendarat).x, KoranLempar.posisi(mendarat).y), lintasan.titik_mendarat), "%s: sesudah lanjut koran mendarat di titik prediksi" % pemicu)
	# Penanda ikut beku saat jeda.
	var sisa_penanda: float = KoranLempar.sisa_penanda(akar.koran_terbang()[0]) if not akar.koran_terbang().is_empty() else -1.0
	_jeda(akar, pemicu)
	akar.perbarui(5.0)
	check(not akar.koran_terbang().is_empty() and KoranLempar.sisa_penanda(akar.koran_terbang()[0]) == sisa_penanda, "%s: penanda kena/meleset tidak berkurang selama jeda" % pemicu)
	akar.minta_lanjut()
	_langkah(akar, roundi(Config.PENANDA_LAMA_DETIK / DT) + 2)
	check(akar.koran_terbang().is_empty(), "%s: sesudah lanjut penanda habis dan koran dibuang" % pemicu)
	_bersihkan(akar)


## Jeda datang di antara jari dilepas dan frame lepas: animasi ditutup, tetapi lemparan yang sudah diterima tetap terbang sesudah lanjut;
## koran berkurang tepat 1.
func _test_jeda_sebelum_lepas() -> void:
	_judul.call("Jeda di antara jari dilepas dan frame lepas: koran tetap terlempar (AC-7, D-11)")
	var akar: JalanUji = await _siapkan()
	var sepeda: SepedaUji = _sepeda(akar)
	var catatan: Dictionary = _catat(akar)
	var sinyal: Array = _catat_sprite(akar)
	_swipe(LoperAnim.Sisi.DEKAT, _dx(0.5))
	var lintasan: ThrowSolver.Lintasan = (catatan["lempar"] as Array)[0]
	_langkah(akar, 3)
	check(sepeda.sedang_melempar() and _jumlah(sinyal, "lepas") == 0 and not KoranLempar.di_udara(akar.koran_terbang()[0]), "3 langkah sesudah jari dilepas: belum frame lepas, koran belum di udara")
	_tree.root.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(akar.sedang_jeda() and not sepeda.sedang_melempar(), "FOCUS_OUT: animasi lempar ditutup")
	check(akar.koran.sisa == 29 and akar.koran_terbang().size() == 1, "lemparan tetap tercatat: koran 29, satu koran menunggu lepas")
	akar.perbarui(1.0)
	akar.minta_lanjut()
	var mendarat: KoranLempar.Koran = _sampai_mendarat(akar, catatan)
	check(mendarat != null and _dekat_v(Vector2(KoranLempar.posisi(mendarat).x, KoranLempar.posisi(mendarat).y), lintasan.titik_mendarat), "sesudah lanjut koran lepas, terbang, dan mendarat di titik prediksi")
	check(akar.koran.sisa == 29 and (catatan["lempar"] as Array).size() == 1, "koran berkurang tepat 1 (tidak dua kali, tidak dikembalikan)")
	check(_jumlah(sinyal, "lepas") == 0, "animasi yang ditutup jeda tidak memancarkan koran_lepas (batalkan_lempar hanya menutup animasi)")
	_bersihkan(akar)


func _test_swipe_ditahan_saat_jeda() -> void:
	_judul.call("Swipe yang ditahan saat jeda dibatalkan tanpa melempar (AC-7, D-11)")
	var akar: JalanUji = await _siapkan()
	var catatan: Dictionary = _catat(akar)
	var garis: GarisBidik = akar.garis_bidik()
	_sentuh(1, _awal(LoperAnim.Sisi.SEBERANG), true)
	_geser(1, _akhir(LoperAnim.Sisi.SEBERANG, _dx(0.5)))
	akar.perbarui(DT)
	check(garis.tampil(), "garis bidik tampil saat swipe ditahan")
	akar.minta_jeda()
	check(not garis.tampil(), "jeda: garis bidik hilang")
	akar.minta_lanjut()
	_sentuh(1, _akhir(LoperAnim.Sisi.SEBERANG, _dx(0.5)), false)
	akar.perbarui(DT)
	check((catatan["lempar"] as Array).is_empty() and akar.koran.sisa == 30 and not garis.tampil(), "jari diangkat sesudah lanjut: tidak melempar, koran tetap 30")
	_bersihkan(akar)


# --- AC-8: input, dua jari, kidal, panel HUD ---

func _test_input_dan_kidal() -> void:
	_judul.call("Input lempar: sisi, garis bidik, dua jari, kidal, panel HUD koran (AC-8)")
	var akar: JalanUji = await _siapkan()
	var sepeda: SepedaUji = _sepeda(akar)
	var hud: HudDev = _anak(akar, "Hud") as HudDev
	var catatan: Dictionary = _catat(akar)
	var garis: GarisBidik = akar.garis_bidik()
	var router: TouchRouter = _router(akar)
	# Kiri layar = seberang, kanan layar = dekat.
	_swipe(LoperAnim.Sisi.SEBERANG, _dx(0.5))
	akar.perbarui(Config.LEMPAR_JEDA_DETIK)
	_swipe(LoperAnim.Sisi.DEKAT, _dx(0.5))
	var dilempar: Array = catatan["lempar"]
	check(dilempar.size() == 2 and (dilempar[0] as ThrowSolver.Lintasan).sisi == LoperAnim.Sisi.SEBERANG and (dilempar[0] as ThrowSolver.Lintasan).titik_mendarat.x < sepeda.lateral_ubin, "swipe ke kiri layar: koran ke seberang (lateral negatif)")
	check(dilempar.size() == 2 and (dilempar[1] as ThrowSolver.Lintasan).sisi == LoperAnim.Sisi.DEKAT and (dilempar[1] as ThrowSolver.Lintasan).titik_mendarat.x > sepeda.lateral_ubin, "swipe ke kanan layar: koran ke dekat (lateral positif)")
	# Garis bidik: tampil saat ditahan, hilang saat batal.
	akar.perbarui(Config.LEMPAR_JEDA_DETIK)
	_sentuh(1, _awal(LoperAnim.Sisi.DEKAT), true)
	_geser(1, _akhir(LoperAnim.Sisi.DEKAT, ThrowSolver.swipe_min_px(LEBAR) - 1.0))
	akar.perbarui(DT)
	check(not garis.tampil(), "swipe ditahan di bawah 6%: tanpa garis bidik")
	_geser(1, _akhir(LoperAnim.Sisi.DEKAT, _dx(0.2)))
	akar.perbarui(DT)
	check(garis.tampil() and garis.lintasan().sisi == LoperAnim.Sisi.DEKAT, "swipe ditahan cukup panjang: garis bidik ke sisi dekat")
	_geser(1, _awal(LoperAnim.Sisi.DEKAT) + Vector2(10, -_dx(0.5)))
	akar.perbarui(DT)
	check(not garis.tampil(), "swipe ditahan dominan tegak: garis bidik hilang")
	_sentuh(1, _awal(LoperAnim.Sisi.DEKAT) + Vector2(10, -_dx(0.5)), false, true)
	akar.perbarui(DT)
	check(not garis.tampil() and dilempar.size() == 2, "sentuhan dibatalkan sistem: tanpa garis bidik, tanpa lemparan")
	# Dua jari: stick ngebut + swipe.
	_sentuh(0, TITIK_STICK, true)
	_geser(0, TITIK_STICK - Vector2(0, Config.STICK_RADIUS_PX))
	_langkah(akar, 60)
	_sentuh(1, _awal(LoperAnim.Sisi.SEBERANG), true)
	_geser(1, _akhir(LoperAnim.Sisi.SEBERANG, _dx(0.6)))
	_langkah(akar, 5)
	check(router.jumlah_jari_aktif() == 2 and garis.tampil() and sepeda.kecepatan_ud > 3.0, "dua jari: stick menggerakkan sepeda dan garis bidik tampil bersamaan")
	_sentuh(1, _akhir(LoperAnim.Sisi.SEBERANG, _dx(0.6)), false)
	check(dilempar.size() == 3 and router.stick_aktif() and is_equal_approx(dilempar[2].kecepatan_maju_ud, sepeda.kecepatan_ud), "dua jari: jari swipe diangkat melempar dengan kecepatan sepeda sebenarnya, stick tetap aktif")
	_sentuh(0, TITIK_STICK, false)
	# Sentuhan yang mulai di panel HUD koran (di dalam zona swipe) tetap swipe.
	akar.perbarui(Config.LEMPAR_JEDA_DETIK)
	var panel: Rect2 = hud.rect_panel_koran()
	check(TouchZones.rect_swipe(int(LEBAR), false).encloses(panel), "panel HUD koran %s ada di dalam zona swipe" % panel)
	var mulai: Vector2 = panel.get_center()
	_sentuh(1, mulai, true)
	_geser(1, mulai - Vector2(_dx(0.3), 0))
	_sentuh(1, mulai - Vector2(_dx(0.3), 0), false)
	check(dilempar.size() == 4 and (dilempar[3] as ThrowSolver.Lintasan).sisi == LoperAnim.Sisi.SEBERANG, "swipe yang mulai di panel HUD koran melempar ke seberang (HUD tidak menangkap sentuhan)")
	# Kidal: zona swipe di kiri layar, arti arah tetap.
	(_anak(hud, "TombolKidal") as Button).button_pressed = true
	await _tree.process_frame
	await _tree.process_frame
	check(router.kidal(), "kidal menyala")
	akar.perbarui(Config.LEMPAR_JEDA_DETIK)
	var awal_kidal: Vector2 = Vector2(400, SWIPE_Y)
	_sentuh(1, awal_kidal, true)
	_geser(1, awal_kidal - Vector2(_dx(0.4), 0))
	akar.perbarui(DT)
	check(garis.tampil() and garis.lintasan().sisi == LoperAnim.Sisi.SEBERANG, "kidal: swipe ke kiri layar menampilkan garis bidik ke seberang")
	_sentuh(1, awal_kidal - Vector2(_dx(0.4), 0), false)
	akar.perbarui(Config.LEMPAR_JEDA_DETIK)
	_sentuh(1, awal_kidal, true)
	_geser(1, awal_kidal + Vector2(_dx(0.4), 0))
	_sentuh(1, awal_kidal + Vector2(_dx(0.4), 0), false)
	check(dilempar.size() == 6 and (dilempar[4] as ThrowSolver.Lintasan).sisi == LoperAnim.Sisi.SEBERANG and (dilempar[5] as ThrowSolver.Lintasan).sisi == LoperAnim.Sisi.DEKAT, "kidal: kiri layar tetap seberang, kanan layar tetap dekat")
	var panel_kidal: Rect2 = hud.rect_panel_koran()
	check(TouchZones.rect_swipe(int(LEBAR), true).encloses(panel_kidal), "kidal: panel HUD koran %s pindah ke dalam zona swipe kidal" % panel_kidal)
	akar.perbarui(Config.LEMPAR_JEDA_DETIK)
	mulai = panel_kidal.get_center()
	_sentuh(1, mulai, true)
	_geser(1, mulai + Vector2(_dx(0.3), 0))
	_sentuh(1, mulai + Vector2(_dx(0.3), 0), false)
	check(dilempar.size() == 7 and (dilempar[6] as ThrowSolver.Lintasan).sisi == LoperAnim.Sisi.DEKAT, "kidal: swipe yang mulai di panel HUD koran tetap swipe (ke dekat)")
	(_anak(hud, "TombolKidal") as Button).button_pressed = false
	await _tree.process_frame
	_bersihkan(akar)


## Elips garis bidik berubah warna DAN bentuk saat mengarah ke sasaran sah; jendela dengan sakelar bawaan (penalti ringan) tidak sah:
## elips biasa, penanda silang. Hasil pendaratan sama dengan prediksi elips.
func _test_elips_dan_jendela() -> void:
	_judul.call("Elips sasaran sah, jendela penalti, bukan pelanggan, meleset (AC-5, AC-8, D-5, D-7, D-10)")
	check(Config.JENDELA_KENA_BONUS == false, "sakelar jendela bawaan = penalti ringan")
	var akar: JalanUji = await _siapkan()
	var catatan: Dictionary = _catat(akar)
	var garis: GarisBidik = akar.garis_bidik()
	var kasus: Array = [
		[LoperAnim.Sisi.SEBERANG, ZonaSasaran.Hasil.TERAS, true, ZonaSasaran.Penanda.CENTANG],
		[LoperAnim.Sisi.SEBERANG, ZonaSasaran.Hasil.KOTAK_SURAT, true, ZonaSasaran.Penanda.CENTANG],
		[LoperAnim.Sisi.SEBERANG, ZonaSasaran.Hasil.HALAMAN, true, ZonaSasaran.Penanda.SETENGAH],
		[LoperAnim.Sisi.SEBERANG, ZonaSasaran.Hasil.JENDELA, false, ZonaSasaran.Penanda.SILANG],
		[LoperAnim.Sisi.SEBERANG, ZonaSasaran.Hasil.BUKAN_PELANGGAN, false, ZonaSasaran.Penanda.SILANG],
		[LoperAnim.Sisi.SEBERANG, ZonaSasaran.Hasil.MELESET, false, ZonaSasaran.Penanda.SILANG],
		[LoperAnim.Sisi.DEKAT, ZonaSasaran.Hasil.KOTAK_SURAT, true, ZonaSasaran.Penanda.CENTANG],
		[LoperAnim.Sisi.DEKAT, ZonaSasaran.Hasil.TERAS, true, ZonaSasaran.Penanda.CENTANG],
	]
	for k: Array in kasus:
		var sisi: LoperAnim.Sisi = k[0]
		var sasaran: ZonaSasaran.Hasil = k[1]
		var nama: String = "%s %s" % [LoperAnim.Sisi.keys()[sisi], ZonaSasaran.Hasil.keys()[sasaran]]
		var ketemu: bool = _bidik_ke(akar, sisi, sasaran)
		check(ketemu, "%s: garis bidik bisa diarahkan ke sasaran" % nama)
		if not ketemu:
			continue
		check(garis.elips_sah() == k[2], "%s: elips %s" % [nama, "sah (OK, terisi)" if k[2] else "biasa (cincin TEXT)"])
		var l: ThrowSolver.Lintasan = garis.lintasan()
		_sentuh(1, _router(akar).posisi_swipe(), false)
		var mendarat: KoranLempar.Koran = _sampai_mendarat(akar, catatan)
		check(mendarat != null and mendarat.hasil == sasaran and mendarat.penanda == k[3] and ZonaSasaran.sah(mendarat.antaran) == k[2], "%s: mendarat dengan hasil sama dengan prediksi elips, penanda %s" % [nama, ZonaSasaran.Penanda.keys()[k[3]]])
		check(mendarat != null and _dekat_v(Vector2(KoranLempar.posisi(mendarat).x, KoranLempar.posisi(mendarat).y), l.titik_mendarat), "%s: titik mendarat = titik akhir garis bidik" % nama)
		check(KoranGambar.warna_penanda(mendarat.antaran if mendarat != null else ZonaSasaran.Antaran.TIDAK_SAH) == (Palette.OK if k[2] else Palette.FAIL), "%s: warna penanda %s" % [nama, "OK" if k[2] else "FAIL"])
		_langkah(akar, roundi(Config.PENANDA_LAMA_DETIK / DT) + 2)
	check(akar.koran_terbang().is_empty(), "semua penanda habis sesudah 0,8 detik")
	_bersihkan(akar)


# --- HUD koran dan zona ---

func _test_hud_dan_zona() -> void:
	_judul.call("HUD koran dan zona placeholder (AC-9, D-6)")
	var akar: JalanUji = await _siapkan()
	var hud: HudDev = _anak(akar, "Hud") as HudDev
	var zona: ZonaGambar = _anak(akar, "Zona") as ZonaGambar
	var deret: DeretKoran = _anak(hud, "DeretKoran") as DeretKoran
	var label: Label = _anak(hud, "LabelKoran") as Label
	var habis: Label = _anak(hud, "LabelHabis") as Label
	check(label.text == "HUD_KORAN" and habis.text == "HUD_KORAN_HABIS" and tr("HUD_KORAN") == "KORAN" and tr("HUD_KORAN_HABIS") == "HABIS", "label HUD koran memakai kunci terjemahan (KORAN, HABIS)")
	check(deret.custom_minimum_size == Vector2(8 * 12 + 7, 12) and deret.mouse_filter == Control.MOUSE_FILTER_IGNORE, "deret ikon: 8 ikon 12 px berjarak 1 px, tidak menerima sentuhan")
	check(SisaKoran.ikon_hud(30, 30, 8) == Vector2i(8, 8) and SisaKoran.ikon_hud(5, 30, 8) == Vector2i(8, 5) and SisaKoran.ikon_hud(0, 30, 8) == Vector2i(8, 0), "ikon HUD: penuh 8 terang, sisa 5 = 5 terang 3 redup, habis 0 terang")
	# Zona: kavling yang digambar sama dengan slot rumah, bukan pelanggan punya warna dan tanda bentuk sendiri.
	var kavling: Array[int] = zona.kavling_tampil()
	var objek: ObjekDaur = _anak(akar, "Objek") as ObjekDaur
	check(kavling.size() == objek.jumlah_slot(), "zona digambar untuk kavling sebanyak slot rumah (%d)" % kavling.size())
	var ada_bukan: bool = false
	for indeks: int in kavling:
		if not ZonaSasaran.pelanggan_jalan_uji(indeks):
			ada_bukan = true
	check(ada_bukan, "kavling yang tampil memuat rumah bukan pelanggan")
	var pelanggan: Array = ZonaGambar.perintah_kavling(true)
	var bukan: Array = ZonaGambar.perintah_kavling(false)
	var warna_pelanggan: Array[Color] = []
	var warna_bukan: Array[Color] = []
	for p: Array in pelanggan:
		warna_pelanggan.append(p[1])
	for p: Array in bukan:
		warna_bukan.append(p[1])
	check(not warna_pelanggan.has(Palette.RADAR_BUKAN) and warna_bukan.has(Palette.RADAR_BUKAN), "rumah bukan pelanggan memakai RADAR_BUKAN, pelanggan tidak")
	check(bukan.size() > pelanggan.size(), "rumah bukan pelanggan punya tanda bentuk tambahan (%d lawan %d perintah gambar)" % [bukan.size(), pelanggan.size()])
	check(warna_pelanggan.has(Palette.ACCENT) and warna_bukan.has(Palette.ACCENT), "kotak surat datar sisi dekat (ACCENT) di kedua jenis kavling (sisi dekat selalu pelanggan)")
	var jumlah_teras_bukan: int = 0
	for p: Array in bukan:
		if p[1] == Palette.UI_PANEL_RAISED:
			jumlah_teras_bukan += 1
	check(jumlah_teras_bukan == 1, "kavling bukan pelanggan: hanya teras sisi dekat yang tetap warna teras pelanggan")
	_bersihkan(akar)
