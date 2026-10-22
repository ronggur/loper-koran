class_name TesSisiDekatScene
extends RefCounted
## Tes run fase5d-sisi-dekat bagian B, bagian scene (AC-9 sampai AC-12): `scenes/rute/rute.tscn` hari 3 dengan pelanggan di sisi dekat.
## - AC-9: kotak surat dekat (oranye pelanggan, abu-abu bukan) di lateral +2,125, koran terlipat di teras dekat tidak tertimpa sprite rumahnya (oracle piksel independen: PNG + JSON, Y-sort ditulis ulang).
## - AC-10: swipe NYATA (event sentuh) ke kotak surat, teras, halaman, dan meleset di sisi dekat: prediksi garis bidik = hasil mendarat = oracle independen (literal + JSON), juga kidal; skor dan koin sama aturan seberang.
## - AC-11: mode bantu ke sisi dekat (selalu kena), radar dua strip, progres 25 kotak dua sisi; bot bantu menyelesaikan 25 pelanggan di 20 seed hari >= 3 (dan hari 1 dan 2) tanpa lewat tenggat.
## - AC-12: tip hari 3 sekali, tidak di hari lain, beku saat jeda, tidak menelan sentuhan; `HariMain` meneruskan hari.
## Tes TIDAK menulis `user://save.json`: alur hari memakai folder sementara `user://tes_save_5d_hari/`.

const BERKAS_RUTE: String = "res://scenes/rute/rute.tscn"
const BERKAS_HARI: String = "res://scenes/hari/hari.tscn"
const FOLDER_TES: String = "user://tes_save_5d_hari"
const SKRIP_SIMPAN: String = "res://scripts/autoload/save_manager.gd"
const SKALA: int = 3
const DT: float = 1.0 / 60.0
const LEBAR: float = 780.0
const SWIPE_Y: float = 200.0
const SWIPE_X: float = 560.0
const SWIPE_X_KIDAL: float = 220.0
const FOLDER_RUMAH: String = "res://assets/sprites/houses/perumahan"
const FOLDER_PROPS: String = "res://assets/sprites/props"
const SEED_BOT: Array[int] = [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22]
const HARI_BOT_LAMA: Array[int] = [1, 2]

var _cek: Callable
var _judul: Callable
var _tree: SceneTree
var _simpanan_aktif: Array[Node] = []
var catatan_bot: Array[String] = []


func _init(cek: Callable, judul: Callable, tree: SceneTree) -> void:
	_cek = cek
	_judul = judul
	_tree = tree


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	await _test_kotak_surat_dua_sisi()
	await _test_terlipat_dekat()
	await _test_lempar_nyata(false)
	await _test_lempar_nyata(true)
	await _test_bantu_dan_hud()
	_test_radar_progres_murni()
	await _test_tip()
	await _test_hari_main()
	await _test_bot_bantu()


# --- Pembantu ---

func _siapkan(hari: int, benih: int = -1) -> RuteMain:
	_tree.root.size = Vector2i(2340, 1080)
	var akar: RuteMain = (load(BERKAS_RUTE) as PackedScene).instantiate() as RuteMain
	akar.atur_hari(hari)
	akar.atur_benih_awal(benih if benih >= 0 else SeedHari.rute(hari))
	_tree.root.add_child(akar)
	await _tree.process_frame
	await _tree.process_frame
	# Headless mengembalikan ukuran jendela sesudah tiap frame; ukuran diatur lagi supaya viewport 780x360 berlaku untuk langkah sinkron berikutnya.
	_tree.root.size = Vector2i(2340, 1080)
	akar.set_process(false)
	(akar.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = false
	var sprite: LoperSprite = akar.find_child("LoperAgen", true, false) as LoperSprite
	if sprite != null:
		sprite.set_process(false)
	return akar


func _bersihkan(akar: RuteMain) -> void:
	_lepas_jari()
	(akar.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = OS.has_feature("editor")
	if akar.sedang_jeda():
		akar.minta_lanjut()
	_tree.root.remove_child(akar)
	akar.free()


func _taruh(akar: RuteMain, maju: float, lateral: float, kecepatan: float = 3.0) -> void:
	var sepeda: SepedaUji = akar.find_child("Sepeda", true, false) as SepedaUji
	var k: BikeMotion.Keadaan = sepeda.keadaan.salin()
	k.kecepatan_ud = kecepatan
	k.lateral_ubin = lateral
	sepeda.keadaan = k
	sepeda.jarak_ubin = maju
	akar.perbarui(0.0)


func _sentuh(index: int, posisi: Vector2, tekan: bool) -> void:
	var p: InputEventScreenTouch = InputEventScreenTouch.new()
	p.index = index
	p.position = posisi * float(SKALA)
	p.pressed = tekan
	Input.parse_input_event(p)
	Input.flush_buffered_events()


func _geser(index: int, posisi: Vector2) -> void:
	var p: InputEventScreenDrag = InputEventScreenDrag.new()
	p.index = index
	p.position = posisi * float(SKALA)
	Input.parse_input_event(p)
	Input.flush_buffered_events()


func _lepas_jari() -> void:
	for i: int in range(8):
		_sentuh(i, Vector2(-50, -50), false)


func _langkah(akar: RuteMain, jumlah: int, dt: float = DT) -> void:
	for i: int in range(jumlah):
		akar.perbarui(dt)


func _rumah_dekat_pelanggan(rute: RouteBuilder.Rute, indeks_ke: int = 0) -> RouteBuilder.RumahRute:
	var n: int = 0
	for r: RouteBuilder.RumahRute in rute.pelanggan:
		if r.sisi == LoperAnim.Sisi.DEKAT:
			if n == indeks_ke:
				return r
			n += 1
	return null


func _jenis_pendek(r: RouteBuilder.RumahRute) -> String:
	return r.jenis.trim_prefix("dekat_")


func _layar(lateral: float, maju: float) -> Vector2i:
	return Vector2i(roundi((lateral + maju) * 32.0), roundi((lateral - maju) * 16.0))


func _topeng(folder: String, nama: String) -> UkurPenutupPiksel.Topeng:
	return UkurSisiDekat.topeng(folder, nama)


# --- AC-9: kotak surat dua sisi ---

func _test_kotak_surat_dua_sisi() -> void:
	_judul.call("Scene rute hari 3: kotak surat oranye di pelanggan dan abu-abu di bukan pelanggan, KEDUA sisi, dekat di lateral +2,125 (AC-9, D-3)")
	for hari: int in [1, 3]:
		var akar: RuteMain = await _siapkan(hari)
		var daur: RumahDaurRute = akar.daur()
		var rute: RouteBuilder.Rute = akar.rute()
		var salah: Array[String] = []
		var oranye_dekat: int = 0
		var abu_dekat: int = 0
		var oranye_seberang: int = 0
		for jarak: float in [0.0, 60.0, 120.0, 180.0, 225.0]:
			daur.perbarui(jarak)
			for indeks: int in daur.indeks_tampil():
				var r: RouteBuilder.RumahRute = rute.rumah[indeks]
				var oranye: Sprite2D = daur.kotak_surat(indeks) as Sprite2D
				var abu: Sprite2D = daur.kotak_surat_bukan(indeks) as Sprite2D
				var dipakai: Sprite2D = oranye if r.pelanggan else abu
				var lain: Sprite2D = abu if r.pelanggan else oranye
				if dipakai == null or lain != null or not dipakai.visible:
					salah.append("%s: kotak surat salah jenis atau tidak ada" % r.id)
					continue
				var lateral: float = (dipakai.position.x / 32.0 + dipakai.position.y / 16.0) / 2.0
				var maju: float = (dipakai.position.x / 32.0 - dipakai.position.y / 16.0) / 2.0
				var lateral_harap: float = 2.125 if r.sisi == LoperAnim.Sisi.DEKAT else -2.125
				if not is_equal_approx(lateral, lateral_harap) or not is_equal_approx(maju, r.maju_ubin + 1.75):
					salah.append("%s: pijak (%.3f; %.3f) bukan (%.3f; %.3f)" % [r.id, lateral, maju, lateral_harap, r.maju_ubin + 1.75])
				if r.sisi == LoperAnim.Sisi.DEKAT:
					if r.pelanggan:
						oranye_dekat += 1
					else:
						abu_dekat += 1
				elif r.pelanggan:
					oranye_seberang += 1
				# Sprite rumah memakai varian sesuai status pelanggan (kedua sisi).
				var sprite: Sprite2D = daur.sprite_rumah(indeks)
				var nama_harap: String = "house_perumahan_%s_%s" % [r.jenis, "pelanggan" if r.pelanggan else "bukan"]
				if sprite == null or sprite.texture == null or not sprite.texture.resource_path.ends_with(nama_harap + ".png"):
					salah.append("%s: sprite rumah bukan %s" % [r.id, nama_harap])
		check(salah.is_empty(), "hari %d: tiap rumah punya kotak surat sesuai status (oranye/abu-abu), lateral dekat +2,125 seberang -2,125, sprite rumah varian pelanggan: %s" % [hari, salah.slice(0, 3)])
		check(abu_dekat > 0 and oranye_seberang > 0, "hari %d: jendela memuat abu-abu dekat (%d) dan oranye seberang (%d)" % [hari, abu_dekat, oranye_seberang])
		if hari == 3:
			check(oranye_dekat > 0, "hari 3: ada kotak surat oranye di rumah dekat pelanggan (%d)" % oranye_dekat)
			check(RouteBuilder.jumlah_dekat(rute) in [8, 9], "hari 3: rute scene memuat 8 atau 9 pelanggan dekat (%d)" % RouteBuilder.jumlah_dekat(rute))
		else:
			check(oranye_dekat == 0 and RouteBuilder.jumlah_dekat(rute) == 0, "hari 1: tidak ada pelanggan dekat, semua kotak surat dekat abu-abu")
		_bersihkan(akar)


# --- AC-9: koran terlipat di teras dekat ---

func _test_terlipat_dekat() -> void:
	_judul.call("Koran terlipat di teras dekat: tidak tertimpa sprite rumahnya (oracle piksel PNG + JSON + Y-sort ditulis ulang), seberang tidak berubah (AC-9)")
	var akar: RuteMain = await _siapkan(3)
	var daur: RumahDaurRute = akar.daur()
	var rute: RouteBuilder.Rute = akar.rute()
	var r: RouteBuilder.RumahRute = _rumah_dekat_pelanggan(rute, 2)
	check(r != null, "kontrol: ada pelanggan dekat ke-3")
	if r == null:
		_bersihkan(akar)
		return
	var seb: RouteBuilder.RumahRute = null
	for p: RouteBuilder.RumahRute in rute.pelanggan:
		if p.sisi == LoperAnim.Sisi.SEBERANG and absf(p.maju_ubin - r.maju_ubin) < 12.0:
			seb = p
			break
	_taruh(akar, r.maju_ubin - 2.0, 0.5)
	akar.skor().terantar[r.id] = true
	if seb != null:
		akar.skor().terantar[seb.id] = true
	akar.perbarui(0.0)
	var indeks: int = rute.rumah.find(r)
	var sprite: Sprite2D = daur.sprite_terlipat(indeks)
	var pembungkus: Node2D = daur.pembungkus_terlipat(indeks)
	var sprite_rumah: Sprite2D = daur.sprite_rumah(indeks)
	check(sprite != null and pembungkus != null and sprite_rumah != null and sprite.get_parent() == pembungkus and pembungkus.get_parent() == daur, "terantar: satu sprite terlipat di pembungkus, anak induk Y-sort yang sama dengan sprite rumah")
	if sprite == null or pembungkus == null or sprite_rumah == null:
		_bersihkan(akar)
		return
	# Letak: pembungkus 1 piksel di depan pijak rumah; sprite di titik tengah teras (pijak gambar 5,0; maju + 1,0 + teras_ubin dari JSON).
	var json: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("%s/house_perumahan_%s_pelanggan.json" % [FOLDER_RUMAH, r.jenis])) as Dictionary
	var teras: Array = json["teras_ubin"]
	var pusat_lateral: float = 5.0 + float(teras[0]) + float(teras[2]) / 2.0
	var pusat_maju: float = r.maju_ubin + 1.0 + float(teras[1]) + float(teras[3]) / 2.0
	var titik_teras: Vector2i = _layar(pusat_lateral, pusat_maju)
	var pijak_rumah: Vector2i = _layar(5.0, r.maju_ubin + 1.0)
	check(pembungkus.position.is_equal_approx(Vector2(pijak_rumah) + Vector2(0.0, 1.0)), "pembungkus di pijak rumah + (0; 1) px: %s vs %s" % [pembungkus.position, pijak_rumah])
	check((pembungkus.position + sprite.position).is_equal_approx(Vector2(titik_teras)), "sprite terlipat tepat di titik tengah teras (literal iso): %s vs %s" % [pembungkus.position + sprite.position, titik_teras])
	check(pembungkus.position.y > sprite_rumah.position.y, "Y-sort: pembungkus digambar sesudah sprite rumah (y %s > %s)" % [pembungkus.position.y, sprite_rumah.position.y])
	# Oracle piksel: piksel opak sprite terlipat yang tertimpa piksel opak sprite rumah yang digambar sesudahnya.
	var topeng_rumah: UkurPenutupPiksel.Topeng = _topeng(FOLDER_RUMAH, "house_perumahan_%s_pelanggan" % r.jenis)
	var topeng_lipat: UkurPenutupPiksel.Topeng = _topeng(FOLDER_PROPS, "prop_koran_terlipat")
	var titik: Array[Vector2i] = []
	var i: int = 0
	while i < topeng_lipat.titik.size():
		titik.append(titik_teras + Vector2i(topeng_lipat.titik[i], topeng_lipat.titik[i + 1]))
		i += 2
	var sprite_oracle: Array = [[topeng_rumah, pijak_rumah, float(pijak_rumah.y)]]
	var y_game: float = pembungkus.position.y
	var tertimpa_game: float = UkurSisiDekat.pecahan(titik, sprite_oracle, y_game)
	var y_naif: float = float(titik_teras.y)
	var tertimpa_naif: float = UkurSisiDekat.pecahan(titik, sprite_oracle, y_naif)
	check(titik.size() > 20 and tertimpa_game == 0.0, "koran terlipat dekat (%d piksel opak): 0%% tertimpa sprite rumah sesuai urutan gambar game" % titik.size())
	check(tertimpa_naif > 0.5, "kontrol: diletakkan langsung di titik teras (urutan naif) %.0f%% tertimpa rumahnya sendiri" % (tertimpa_naif * 100.0))
	# Seberang: sprite terlipat tetap anak induk langsung, posisi = titik teras seberang.
	if seb != null:
		var i_seb: int = rute.rumah.find(seb)
		var s_seb: Sprite2D = daur.sprite_terlipat(i_seb)
		if s_seb != null:
			check(s_seb.get_parent() == daur and daur.pembungkus_terlipat(i_seb) == null, "seberang: terlipat tetap anak induk langsung, tanpa pembungkus")
	# Pool: jendela digeser jauh lalu kembali; node tidak bocor.
	var node_awal: int = daur.jumlah_node_terlipat() + daur.jumlah_node_pembungkus()
	for jarak: float in [10.0, 150.0, r.maju_ubin - 2.0, 10.0, r.maju_ubin - 2.0]:
		_taruh(akar, jarak, 0.5)
	check(daur.jumlah_node_terlipat() + daur.jumlah_node_pembungkus() <= node_awal + 4 and daur.sprite_terlipat(indeks) != null, "kolam sprite terlipat dan pembungkus dipakai ulang (%d -> %d)" % [node_awal, daur.jumlah_node_terlipat() + daur.jumlah_node_pembungkus()])
	akar.skor().terantar.erase(r.id)
	akar.perbarui(0.0)
	check(daur.sprite_terlipat(indeks) == null and daur.pembungkus_terlipat(indeks) == null, "tidak lagi terantar: sprite dan pembungkus dilepas")
	_bersihkan(akar)


# --- AC-10: lempar nyata ---

## Kelas oracle (0 meleset, 1 kotak surat, 2 teras, 3 halaman, 5 bukan pelanggan) untuk titik dunia di rumah dekat `r`, literal + JSON.
func _kelas_oracle(titik: Vector2, r: RouteBuilder.RumahRute) -> int:
	var json: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("%s/house_perumahan_%s_pelanggan.json" % [FOLDER_RUMAH, r.jenis])) as Dictionary
	var t: Array = json["teras_ubin"]
	var pen: float = float((json["penutup_ubin"] as Array)[0])
	var lat: float = titik.x
	var maju: float = -titik.y
	var awal: float = r.maju_ubin
	var kena: int = 0
	if lat >= 1.75 and lat < 2.75 and maju >= awal + 1.25 and maju < awal + 2.5:
		kena = 1
	elif lat >= 5.0 + float(t[0]) and lat < 5.0 + float(t[0]) + float(t[2]) and maju >= awal + 1.0 + float(t[1]) and maju < awal + 1.0 + float(t[1]) + float(t[3]):
		kena = 2
	elif lat >= 2.0 and lat < 5.0 + pen and maju >= awal - 0.5 and maju < awal + 2.5:
		kena = 3
	return kena


func _kelas_hasil(h: ZonaSasaran.Hasil) -> int:
	match h:
		ZonaSasaran.Hasil.KOTAK_SURAT:
			return 1
		ZonaSasaran.Hasil.TERAS:
			return 2
		ZonaSasaran.Hasil.HALAMAN:
			return 3
		ZonaSasaran.Hasil.BUKAN_PELANGGAN:
			return 5
	return 0


## Cari swipe (awal -> akhir) yang lintasannya memenuhi `syarat` dari keadaan sepeda sekarang. Vector2.INF bila tidak ada.
func _cari_swipe(akar: RuteMain, awal: Vector2, syarat: Callable) -> Vector2:
	for derajat: int in range(0, 360, 3):
		var panjang: float = ceilf(ThrowSolver.swipe_min_px(LEBAR))
		while panjang <= ThrowSolver.swipe_maks_px(LEBAR):
			var akhir: Vector2 = (awal + Vector2(cos(deg_to_rad(derajat)), -sin(deg_to_rad(derajat))) * panjang).round()
			var l: ThrowSolver.Lintasan = akar.lintasan_swipe(awal, akhir)
			if l != null and syarat.call(l):
				return akhir
			panjang += 2.0
	return Vector2.INF


## Satu lemparan nyata (event sentuh) ke sasaran `syarat` dari sepeda di (maju, lateral). Kembalikan {koran, prediksi, bentuk, lintasan} atau {} bila gagal.
func _lempar_nyata(akar: RuteMain, awal: Vector2, syarat: Callable) -> Dictionary:
	var garis: GarisBidik = akar.garis_bidik()
	var router: TouchRouter = akar.kontrol_router()
	var catatan: Array = []
	var pencatat: Callable = func(k: KoranLempar.Koran) -> void: catatan.append(k)
	akar.koran_mendarat.connect(pencatat)
	var hasil: Dictionary = {}
	for percobaan: int in range(40):
		var akhir: Vector2 = _cari_swipe(akar, awal, syarat)
		if akhir == Vector2.INF:
			break
		if not router.swipe_aktif():
			_sentuh(1, awal, true)
		_geser(1, akhir)
		akar.perbarui(DT)
		if garis.tampil() and syarat.call(garis.lintasan()):
			var lintasan: ThrowSolver.Lintasan = garis.lintasan()
			hasil["prediksi"] = KoranLempar.prediksi_antaran(lintasan, Config.JENDELA_KENA_BONUS, akar.medan())
			hasil["bentuk"] = KoranLempar.bentuk_elips(lintasan, Config.JENDELA_KENA_BONUS, akar.medan())
			hasil["lintasan"] = lintasan
			var sebelum: int = akar.koran_terbang().size()
			_sentuh(1, akhir, false)
			if akar.koran_terbang().size() != sebelum + 1:
				break
			for n: int in range(240):
				akar.perbarui(DT)
				if not catatan.is_empty():
					break
			if not catatan.is_empty():
				hasil["koran"] = catatan[0]
			break
	if router.swipe_aktif():
		_sentuh(1, awal, false)
	akar.koran_mendarat.disconnect(pencatat)
	return hasil


func _test_lempar_nyata(kidal: bool) -> void:
	_judul.call("Swipe nyata ke sisi dekat hari 3%s: prediksi garis bidik = hasil mendarat = oracle independen untuk kotak surat, teras, halaman, meleset (AC-10, QA-008)" % (", KIDAL" if kidal else ""))
	var akar: RuteMain = await _siapkan(3)
	if kidal:
		akar.atur_kidal(true)
	var rute: RouteBuilder.Rute = akar.rute()
	var awal: Vector2 = Vector2(SWIPE_X_KIDAL if kidal else SWIPE_X, SWIPE_Y)
	var medan: MedanKoran = akar.medan()
	var sasaran: Array = [
		["KOTAK_SURAT", 1, 0],
		["TERAS", 2, 1],
		["HALAMAN", 3, 2],
		["MELESET", 0, 3],
	]
	var jumlah_ok: int = 0
	for s: Array in sasaran:
		var r: RouteBuilder.RumahRute = _rumah_dekat_pelanggan(rute, int(s[2]) + 1)
		var kelas_target: int = int(s[1])
		var syarat: Callable = func(l: ThrowSolver.Lintasan) -> bool:
			if l.sisi != LoperAnim.Sisi.DEKAT:
				return false
			var z: ZonaSasaran.Zona = ZonaSasaran.zona_kena(l.titik_mendarat, medan.zona_sekitar(l.titik_mendarat))
			if kelas_target == 0:
				return z == null and l.titik_mendarat.x > 0.0
			return z != null and z.id_rumah == r.id and _kelas_hasil(ZonaSasaran.hasil_zona(z)) == kelas_target
		akar.koran = SisaKoran.awal(Config.KORAN_AWAL)
		_taruh(akar, r.maju_ubin - 2.5, 0.5)
		_langkah(akar, 30)
		_taruh(akar, r.maju_ubin - 2.5, 0.5)
		var h: Dictionary = _lempar_nyata(akar, awal, syarat)
		check(h.has("koran"), "%s%s: swipe nyata melempar dan koran mendarat" % [s[0], " (kidal)" if kidal else ""])
		if not h.has("koran"):
			continue
		var k: KoranLempar.Koran = h["koran"]
		var titik: Vector2 = k.lintasan.titik_mendarat
		var kelas_oracle: int = _kelas_oracle(titik, r)
		check(kelas_oracle == kelas_target, "%s: oracle independen mengklasifikasi titik mendarat %s = kelas %d (dapat %d)" % [s[0], titik, kelas_target, kelas_oracle])
		check(_kelas_hasil(k.hasil) == kelas_target and (kelas_target == 0 or k.id_rumah == r.id), "%s: hasil game %s = oracle, rumah %s" % [s[0], ZonaSasaran.Hasil.keys()[k.hasil], k.id_rumah])
		var antaran_harap: ZonaSasaran.Antaran = ZonaSasaran.Antaran.TIDAK_SAH
		if kelas_target == 1 or kelas_target == 2:
			antaran_harap = ZonaSasaran.Antaran.SAH_PENUH
		elif kelas_target == 3:
			antaran_harap = ZonaSasaran.Antaran.SAH_SETENGAH
		check(h["prediksi"] == antaran_harap and k.antaran == antaran_harap, "%s: prediksi garis bidik = antaran mendarat = %s (oracle)" % [s[0], ZonaSasaran.Antaran.keys()[antaran_harap]])
		check((h["bentuk"] == KoranLempar.Elips.SAH) == (kelas_target != 0), "%s: elips SAH hanya bila sah" % s[0])
		if kelas_target == 1:
			check(akar.skor().terantar.has(r.id) and akar.skor().jumlah_antar >= 1, "kotak surat dekat: rumah terantar")
		jumlah_ok += 1
	check(jumlah_ok == 4, "empat sasaran dekat diuji lewat swipe nyata (%d)" % jumlah_ok)
	_bersihkan(akar)


# --- AC-10/AC-11: skor, bantu, radar, progres ---

func _test_bantu_dan_hud() -> void:
	_judul.call("Mode bantu dua sisi: tap sisi dekat menyasar kotak surat pelanggan dekat terdekat di depan dan selalu kena; tanpa sasaran = tanda; skor/koin sama aturan (AC-10, AC-11)")
	var akar: RuteMain = await _siapkan(3)
	akar.atur_mode_bantu(true)
	var rute: RouteBuilder.Rute = akar.rute()
	var semua_kena: int = 0
	var dicoba: int = 0
	var terjangkau: Dictionary = {}
	var salah: Array[String] = []
	for r: RouteBuilder.RumahRute in rute.pelanggan:
		if r.sisi != LoperAnim.Sisi.DEKAT:
			continue
		var mundur: float = 0.0
		while mundur <= 8.0:
			_taruh(akar, r.maju_ubin + 1.875 - mundur, 0.5)
			var p: BantuLempar.Pilihan = akar.pilihan_bantu(LoperAnim.Sisi.DEKAT)
			if p != null:
				dicoba += 1
				# Oracle: sasaran = pelanggan dekat dengan pusat kotak surat paling dekat di depan sepeda (literal pos + 1,875).
				var maju_sepeda: float = r.maju_ubin + 1.875 - mundur
				var terdekat: RouteBuilder.RumahRute = null
				for q: RouteBuilder.RumahRute in rute.pelanggan:
					if q.sisi == LoperAnim.Sisi.DEKAT and q.maju_ubin + 1.875 >= maju_sepeda and (terdekat == null or q.maju_ubin < terdekat.maju_ubin):
						terdekat = q
				if p.zona.id_rumah != terdekat.id or p.zona.jenis != ZonaSasaran.Jenis.KOTAK_SURAT or p.zona.sisi != LoperAnim.Sisi.DEKAT:
					salah.append("mundur %.2f dari %s: sasaran %s, harapan %s" % [mundur, r.id, p.zona.id_rumah, terdekat.id])
				var kena: ZonaSasaran.Zona = ZonaSasaran.zona_kena(p.lintasan.titik_mendarat, akar.medan().zona_sekitar(p.lintasan.titik_mendarat))
				if kena != null and kena.id_rumah == p.zona.id_rumah and kena.jenis == ZonaSasaran.Jenis.KOTAK_SURAT:
					semua_kena += 1
				else:
					salah.append("lintasan bantu ke %s tidak mendarat di kotak surat" % p.zona.id_rumah)
				terjangkau[p.zona.id_rumah] = true
			mundur += 0.5
	check(salah.is_empty(), "sasaran bantu dekat = pelanggan dekat terdekat di depan (oracle literal), lintasan mendarat di kotak surat: %s" % [salah.slice(0, 3)])
	check(dicoba > 50 and semua_kena == dicoba, "semua %d pilihan bantu dekat mendarat di kotak surat pelanggan (selalu kena)" % dicoba)
	check(terjangkau.size() == RouteBuilder.jumlah_dekat(rute), "setiap pelanggan dekat (%d) terjangkau mode bantu dari suatu titik (%d)" % [RouteBuilder.jumlah_dekat(rute), terjangkau.size()])
	# Setelah pelanggan dekat terakhir lewat, tidak ada sasaran dekat; seberang tidak pernah memilih zona dekat.
	var terakhir: RouteBuilder.RumahRute = null
	for q: RouteBuilder.RumahRute in rute.pelanggan:
		if q.sisi == LoperAnim.Sisi.DEKAT:
			terakhir = q
	_taruh(akar, terakhir.maju_ubin + 3.0, 0.5)
	check(akar.pilihan_bantu(LoperAnim.Sisi.DEKAT) == null, "lewat pelanggan dekat terakhir: tidak ada sasaran dekat (tanda tanpa sasaran)")
	var seb_salah: int = 0
	for jarak: float in range(0, 230, 3):
		_taruh(akar, jarak, 0.5)
		var ps: BantuLempar.Pilihan = akar.pilihan_bantu(LoperAnim.Sisi.SEBERANG)
		if ps != null and ps.zona.sisi != LoperAnim.Sisi.SEBERANG:
			seb_salah += 1
	check(seb_salah == 0, "tap sisi seberang tidak pernah menyasar zona dekat")
	# Tap nyata: lempar bantu ke kotak surat dekat, tidak tepat (bantu), skor ANTAR.
	var r0: RouteBuilder.RumahRute = _rumah_dekat_pelanggan(rute, 1)
	akar.koran = SisaKoran.awal(Config.KORAN_AWAL)
	_taruh(akar, r0.maju_ubin + 1.875 - 3.0, 0.5, 3.0)
	_langkah(akar, 5)
	var posisi: Vector2 = akar.posisi_layar_sepeda() + Vector2(200, 30)
	var catatan: Array = []
	var dinilai: Array = []
	akar.koran_mendarat.connect(func(k: KoranLempar.Koran) -> void: catatan.append(k))
	akar.skor_dinilai.connect(func(h: SkorRute.Hasil) -> void: dinilai.append(h))
	var sebelum: int = akar.koran_terbang().size()
	_sentuh(1, posisi, true)
	_sentuh(1, posisi, false)
	check(akar.koran_terbang().size() == sebelum + 1 and akar.koran_terbang()[akar.koran_terbang().size() - 1].bantu, "tap bantu sisi dekat melempar satu koran bantu")
	for n: int in range(180):
		akar.perbarui(DT)
		if not catatan.is_empty():
			break
	check(not catatan.is_empty() and (catatan[0] as KoranLempar.Koran).hasil == ZonaSasaran.Hasil.KOTAK_SURAT and (catatan[0] as KoranLempar.Koran).id_rumah == _id_terdekat_di_depan(rute, r0.maju_ubin + 1.875 - 3.0) and not (catatan[0] as KoranLempar.Koran).tepat, "koran bantu mendarat di kotak surat pelanggan dekat terdekat, bukan tepat")
	if not dinilai.is_empty():
		var h: SkorRute.Hasil = dinilai[0]
		check(h.status == SkorRute.Status.ANTAR and h.skor_tambah == Config.SKOR_SASARAN_DASAR and h.koin_tambah >= Config.KOIN_ONGKOS_ANTAR, "ANTAR sisi dekat: skor %d (= dasar %d, combo 1,0, santai) dan koin %d (ongkos %d)" % [h.skor_tambah, Config.SKOR_SASARAN_DASAR, h.koin_tambah, Config.KOIN_ONGKOS_ANTAR])
	else:
		check(false, "skor dinilai untuk koran bantu dekat")
	# Aturan sama dua sisi: nilai murni tidak bergantung sisi; tip hanya teras ke pemberi tip.
	var tip_dekat: RouteBuilder.RumahRute = null
	for q: RouteBuilder.RumahRute in rute.pelanggan:
		if q.sisi == LoperAnim.Sisi.DEKAT and q.pemberi_tip:
			tip_dekat = q
	if tip_dekat != null:
		var teras: SkorRute.Hasil = SkorRute.nilai_koran(SkorRute.awal(), _koran_buatan(ZonaSasaran.Hasil.TERAS, tip_dekat.id), rute, false)
		var kotak: SkorRute.Hasil = SkorRute.nilai_koran(SkorRute.awal(), _koran_buatan(ZonaSasaran.Hasil.KOTAK_SURAT, tip_dekat.id), rute, false)
		check(teras.tip == Config.KOIN_TIP and kotak.tip == 0 and teras.koin_tambah == Config.KOIN_ONGKOS_ANTAR + Config.KOIN_TIP, "pemberi tip dekat: teras +%d tip, kotak surat tanpa tip" % Config.KOIN_TIP)
	else:
		check(true, "rute ini tanpa pemberi tip dekat (tidak dihitung)")
	_bersihkan(akar)


func _koran_buatan(hasil: ZonaSasaran.Hasil, id_rumah: String) -> KoranLempar.Koran:
	var k: KoranLempar.Koran = KoranLempar.Koran.new()
	k.hasil = hasil
	k.id_rumah = id_rumah
	k.lintasan = ThrowSolver.Lintasan.new()
	k.lintasan.kecepatan_maju_ud = 3.0
	return k


func _id_terdekat_di_depan(rute: RouteBuilder.Rute, maju_sepeda: float) -> String:
	var hasil: RouteBuilder.RumahRute = null
	for q: RouteBuilder.RumahRute in rute.pelanggan:
		if q.sisi == LoperAnim.Sisi.DEKAT and q.maju_ubin + 1.875 >= maju_sepeda and (hasil == null or q.maju_ubin < hasil.maju_ubin):
			hasil = q
	return hasil.id if hasil != null else ""


func _test_radar_progres_murni() -> void:
	_judul.call("Radar dan progres dua sisi: strip dekat memuat pelanggan dekat (jenis, jangkau, bantu abu-abu), 25 kotak progres menghitung dua sisi (oracle literal, AC-11)")
	var rute: RouteBuilder.Rute = RouteBuilder.bangun(SeedHari.rute(3), PemuatRute.muat_folder().segmen, 3).rute
	var salah: Array[String] = []
	var dekat_tampil: int = 0
	var jangkau_dekat: int = 0
	var bukan_dekat_bantu: int = 0
	for bantu: bool in [false, true]:
		for lewat: bool in [false, true]:
			for maju_sepeda: float in range(-2, 240, 2):
				var terantar: Dictionary = {}
				if int(maju_sepeda) % 3 == 0:
					for q: RouteBuilder.RumahRute in rute.pelanggan:
						if q.maju_ubin < maju_sepeda - 20.0:
							terantar[q.id] = true
				var harap: Dictionary = {}
				for r: RouteBuilder.RumahRute in rute.rumah:
					var j: float = r.maju_ubin + 1.875 - maju_sepeda
					if j < 0.0 or j > 30.0:
						continue
					if not r.pelanggan and not bantu:
						continue
					if r.pelanggan and terantar.has(r.id):
						continue
					var jenis: int = RadarRute.Jenis.BUKAN
					if r.pelanggan:
						jenis = RadarRute.Jenis.TIP if (r.pemberi_tip and not lewat) else RadarRute.Jenis.PELANGGAN
					harap[r.id] = [r.sisi, jenis, r.pelanggan and j <= 5.0]
				var dapat: Array[RadarRute.Penanda] = RadarRute.penanda(rute, maju_sepeda, terantar, bantu, lewat)
				if dapat.size() != harap.size():
					salah.append("maju %s bantu %s: %d penanda, harapan %d" % [maju_sepeda, bantu, dapat.size(), harap.size()])
					continue
				for p: RadarRute.Penanda in dapat:
					var h: Array = harap.get(p.id_rumah, [])
					if h.is_empty() or h[0] != p.sisi or h[1] != p.jenis or h[2] != p.jangkau:
						salah.append("%s di maju %s: sisi/jenis/jangkau salah" % [p.id_rumah, maju_sepeda])
					if p.sisi == LoperAnim.Sisi.DEKAT:
						dekat_tampil += 1
						if p.jangkau:
							jangkau_dekat += 1
						if p.jenis == RadarRute.Jenis.BUKAN:
							bukan_dekat_bantu += 1
	check(salah.is_empty(), "radar = oracle literal (jarak = pos + 1,875 - sepeda, 0..30, jangkau <= 5, tip, abu-abu hanya mode bantu): %s" % [salah.slice(0, 3)])
	check(dekat_tampil > 100 and jangkau_dekat > 10 and bukan_dekat_bantu > 10, "kontrol: strip dekat menampilkan penanda (%d), jangkau (%d), abu-abu mode bantu (%d)" % [dekat_tampil, jangkau_dekat, bukan_dekat_bantu])
	# Progres: 25 kotak, BERIKUTNYA = pelanggan belum terantar terdekat di depan di dua sisi, TERLEWAT < -3.
	var prog_salah: Array[String] = []
	for maju_sepeda: float in range(0, 240, 5):
		var terantar: Dictionary = {}
		for i: int in range(0, rute.pelanggan.size(), 3):
			terantar[rute.pelanggan[i].id] = true
		var status: Array[ProgresRute.Status] = ProgresRute.status(rute, maju_sepeda, terantar, false)
		if status.size() != 25:
			prog_salah.append("ukuran %d" % status.size())
			continue
		var berikut: int = -1
		var jarak_berikut: float = INF
		for i: int in range(25):
			var j: float = rute.pelanggan[i].maju_ubin + 1.875 - maju_sepeda
			var harap_status: ProgresRute.Status = ProgresRute.Status.BELUM
			if terantar.has(rute.pelanggan[i].id):
				harap_status = ProgresRute.Status.TERKIRIM
			elif j < -3.0:
				harap_status = ProgresRute.Status.TERLEWAT
			elif j >= 0.0 and j < jarak_berikut:
				berikut = i
				jarak_berikut = j
			if status[i] != harap_status and not (harap_status == ProgresRute.Status.BELUM and status[i] == ProgresRute.Status.BERIKUTNYA):
				prog_salah.append("maju %s kotak %d: %s harapan %s" % [maju_sepeda, i, ProgresRute.Status.keys()[status[i]], ProgresRute.Status.keys()[harap_status]])
		if berikut >= 0 and status[berikut] != ProgresRute.Status.BERIKUTNYA:
			prog_salah.append("maju %s: BERIKUTNYA bukan kotak %d" % [maju_sepeda, berikut])
	check(prog_salah.is_empty(), "progres 25 kotak dua sisi = oracle: %s" % [prog_salah.slice(0, 3)])
	var terkirim: Dictionary = {}
	var n_dekat: int = 0
	for q: RouteBuilder.RumahRute in rute.pelanggan:
		if q.sisi == LoperAnim.Sisi.DEKAT:
			terkirim[q.id] = true
			n_dekat += 1
	check(ProgresRute.jumlah_terkirim(rute, terkirim) == n_dekat and n_dekat in [8, 9], "jumlah terkirim menghitung pelanggan dekat (%d)" % n_dekat)


# --- AC-12: tip hari 3 ---

func _test_tip() -> void:
	_judul.call("Tip hari 3: tampil sekali di hari 3, tidak di hari 1, 2, 4, 50; beku saat jeda; tidak menelan sentuhan; zona aman (AC-12, P-6)")
	check(TipSisiDekat.hari_tip(3) and not TipSisiDekat.hari_tip(1) and not TipSisiDekat.hari_tip(2) and not TipSisiDekat.hari_tip(4) and not TipSisiDekat.hari_tip(50), "hari tip hanya 3")
	check(TipSisiDekat.kunci_teks(3) == "RUTE_TIP_SISI_DEKAT" and TipSisiDekat.kunci_teks(4).is_empty() and TipSisiDekat.detik_awal(3) == 6.0 and TipSisiDekat.detik_awal(2) == 0.0, "kunci teks dan lama 6 detik hanya di hari 3")
	check(TipSisiDekat.sisa(6.0, 1.0) == 5.0 and TipSisiDekat.sisa(0.5, 2.0) == 0.0 and TipSisiDekat.sisa(5.0, NAN) == 5.0 and TipSisiDekat.sisa(5.0, -1.0) == 5.0 and TipSisiDekat.tampil(0.5) and not TipSisiDekat.tampil(0.0), "sisa detik: turun, tidak negatif, NaN dan negatif = 0 langkah")
	for hari: int in [1, 2, 4, 50]:
		var a: RuteMain = await _siapkan(hari)
		_langkah(a, 3)
		check(not a.tip_node().tampil() and a.sisa_tip() == 0.0, "hari %d: tip tidak tampil" % hari)
		_bersihkan(a)
	var akar: RuteMain = await _siapkan(3)
	_langkah(akar, 3)
	var tip: PanelTipSisiDekat = akar.tip_node()
	check(tip.tampil() and tip.teks() == tip.tr("RUTE_TIP_SISI_DEKAT") and not tip.teks().is_empty() and tip.teks() != "RUTE_TIP_SISI_DEKAT", "hari 3: tip tampil dengan teks terjemahan: '%s'" % tip.teks())
	check(tip.kontrol_penerima_sentuhan().is_empty(), "panel tip tidak menelan sentuhan (semua kontrol MOUSE_FILTER_IGNORE)")
	var viewport: Rect2 = Rect2(Vector2.ZERO, akar.get_viewport_rect().size)
	check(viewport.encloses(tip.rect_panel()) and tip.rect_panel().position.x >= 26.0 and tip.rect_panel().size.x <= float(Config.TIP_SISI_DEKAT_LEBAR_PX) + 1.0, "panel tip di dalam viewport, lebar <= %d px: %s" % [Config.TIP_SISI_DEKAT_LEBAR_PX, tip.rect_panel()])
	var hud: HudRute = akar.hud_rute()
	check(not tip.rect_panel().intersects(hud.rect_panel_progres()) and not tip.rect_panel().intersects(hud.rect_tombol_jeda()), "panel tip tidak menimpa panel progres atau tombol jeda")
	# Beku saat jeda.
	var sisa_awal: float = akar.sisa_tip()
	akar.minta_jeda()
	_langkah(akar, 60, 1.0)
	check(is_equal_approx(akar.sisa_tip(), sisa_awal) and tip.tampil(), "jeda 60 detik: tip beku (sisa %.3f = %.3f)" % [akar.sisa_tip(), sisa_awal])
	akar.minta_lanjut()
	# Swipe dan tap masih sampai ke router saat tip tampil.
	akar.atur_mode_bantu(true)
	var rute: RouteBuilder.Rute = akar.rute()
	var r: RouteBuilder.RumahRute = _rumah_dekat_pelanggan(rute, 0)
	_taruh(akar, r.maju_ubin + 1.875 - 3.0, 0.5)
	var terbang: int = akar.koran_terbang().size()
	var pos: Vector2 = akar.posisi_layar_sepeda() + Vector2(200, 30)
	_sentuh(1, pos, true)
	_sentuh(1, pos, false)
	check(tip.tampil() and akar.koran_terbang().size() == terbang + 1, "tip tampil dan tap bantu tetap melempar (tidak menghalangi kontrol)")
	# Habis 6 detik.
	_langkah(akar, 400)
	check(not tip.tampil() and akar.sisa_tip() == 0.0, "sesudah 6 detik waktu game: tip hilang")
	akar.main_lagi()
	_langkah(akar, 3)
	check(not tip.tampil(), "Main lagi di hari 3: tip tidak muncul lagi")
	_bersihkan(akar)
	# Kidal dan inset: panel tidak dicerminkan, atur_inset menggeser.
	var k: RuteMain = await _siapkan(3)
	k.atur_kidal(true)
	_langkah(k, 2)
	var p_awal: Rect2 = k.tip_node().rect_panel()
	var inset: ZonaAman.Inset = ZonaAman.Inset.new()
	inset.awal_x = 20
	inset.atas = 10
	k.tip_node().atur_inset(inset)
	_langkah(k, 2)
	var p_geser: Rect2 = k.tip_node().rect_panel()
	check(k.tip_node().tampil() and p_geser.position.x >= p_awal.position.x and p_geser.position.y >= p_awal.position.y and viewport.encloses(p_geser), "kidal: tip tetap di kiri atas dan inset aman menggeser ke dalam (%s -> %s)" % [p_awal, p_geser])
	_bersihkan(k)


# --- HariMain meneruskan hari ---

func _jalur() -> String:
	return FOLDER_TES.path_join("save.json")


func _tulis_save(hari: int) -> void:
	DirAccess.make_dir_recursive_absolute(FOLDER_TES)
	var s: Dictionary = DataSave.templat()
	s["hari"] = hari
	var berkas: FileAccess = FileAccess.open(_jalur(), FileAccess.WRITE)
	berkas.store_string(DataSave.ke_teks(s))
	berkas.close()


func _bersihkan_folder() -> void:
	var dir: DirAccess = DirAccess.open(FOLDER_TES)
	if dir == null:
		return
	for nama: String in dir.get_files():
		DirAccess.remove_absolute(FOLDER_TES.path_join(nama))
	DirAccess.remove_absolute(FOLDER_TES)


func _test_hari_main() -> void:
	_judul.call("HariMain meneruskan nomor hari ke rute: hari 3 = pelanggan dekat + tip, hari 2 = tanpa, seed = SeedHari.rute (AC-8, AC-12)")
	for hari_save: int in [2, 3, 4]:
		_tulis_save(hari_save)
		_tree.root.size = Vector2i(2340, 1080)
		var m: Node = (load(SKRIP_SIMPAN) as GDScript).new()
		m.set(&"jalur", _jalur())
		m.set(&"lapor_ke_log", false)
		m.call(&"muat", 1700000000)
		_simpanan_aktif.append(m)
		var hari: HariMain = (load(BERKAS_HARI) as PackedScene).instantiate() as HariMain
		hari.simpanan = m
		hari.panggil_quit = false
		_tree.root.add_child(hari)
		await _tree.process_frame
		await _tree.process_frame
		hari.koran().tombol_berangkat().ditekan.emit()
		await _tree.process_frame
		var rute: RuteMain = hari.rute()
		check(rute != null and rute.hari() == hari_save and rute.benih() == SeedHari.rute(hari_save), "save hari %d: rute.hari() = %d, seed = SeedHari.rute(%d)" % [hari_save, hari_save, hari_save])
		if rute != null:
			var dekat: int = RouteBuilder.jumlah_dekat(rute.rute())
			check((hari_save >= 3 and dekat in [8, 9]) or (hari_save < 3 and dekat == 0), "hari %d: %d pelanggan dekat" % [hari_save, dekat])
			check(rute.tip_node().tampil() == (hari_save == 3), "hari %d: tip tampil = %s" % [hari_save, hari_save == 3])
			(rute.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = OS.has_feature("editor")
		_lepas_jari()
		_tree.root.remove_child(hari)
		hari.free()
		_simpanan_aktif.erase(m)
		m.free()
	_bersihkan_folder()
	check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(FOLDER_TES)), "folder save sementara dibersihkan (save asli tidak disentuh)")


# --- AC-11: bot bantu ---

## Satu rute penuh oleh bot mode bantu: tanpa stick (santai 3,0 u/d), tap sekali per pelanggan yang belum dibidik di sisi dekat atau seberang (koran yang masih terbang belum menandai rumah terantar). Kembalikan {terkirim, sisa, lewat, dekat, waktu}.
func _bot(hari: int, benih: int) -> Dictionary:
	var akar: RuteMain = await _siapkan(hari, benih)
	akar.atur_mode_bantu(true)
	var dt: float = 1.0 / 30.0
	var waktu: float = 0.0
	var tenggat: int = akar.tenggat().tenggat_detik
	var selesai_waktu: float = -1.0
	var lewat_saat_selesai: bool = false
	var jeda_tap: float = 0.0
	var sudah_dibidik: Dictionary = {}
	for n: int in range(int(300.0 / dt)):
		akar.perbarui(dt)
		waktu += dt
		jeda_tap -= dt
		if akar.rute_sudah_selesai():
			selesai_waktu = waktu
			lewat_saat_selesai = TenggatRute.lewat(akar.tenggat())
			break
		if jeda_tap <= 0.0 and SisaKoran.boleh_lempar(akar.koran):
			for sisi: LoperAnim.Sisi in [LoperAnim.Sisi.DEKAT, LoperAnim.Sisi.SEBERANG]:
				var p: BantuLempar.Pilihan = akar.pilihan_bantu(sisi)
				if p != null and not akar.skor().terantar.has(p.zona.id_rumah) and not sudah_dibidik.has(p.zona.id_rumah):
					sudah_dibidik[p.zona.id_rumah] = true
					var pos: Vector2 = akar.posisi_layar_sepeda() + (Vector2(200, 30) if sisi == LoperAnim.Sisi.DEKAT else Vector2(200, -150))
					_sentuh(1, pos, true)
					_sentuh(1, pos, false)
					jeda_tap = Config.LEMPAR_JEDA_DETIK
					break
	var rute: RouteBuilder.Rute = akar.rute()
	var hasil: Dictionary = {
		"terkirim": ProgresRute.jumlah_terkirim(rute, akar.skor().terantar),
		"sisa": float(tenggat) - selesai_waktu if selesai_waktu >= 0.0 else -999.0,
		"lewat": lewat_saat_selesai or selesai_waktu < 0.0,
		"dekat": RouteBuilder.jumlah_dekat(rute),
		"waktu": selesai_waktu,
		"tenggat": tenggat,
	}
	_bersihkan(akar)
	return hasil


func _test_bot_bantu() -> void:
	_judul.call("Bot mode bantu menyelesaikan 25 pelanggan di 20 seed hari >= 3 dan hari 1-2 tanpa lewat tenggat, scene nyata (AC-11)")
	var semua: Array[String] = []
	var ok: int = 0
	for hari: int in HARI_BOT_LAMA + SEED_BOT:
		var h: Dictionary = await _bot(hari, SeedHari.rute(hari))
		var baik: bool = int(h["terkirim"]) == 25 and not bool(h["lewat"])
		if baik:
			ok += 1
		semua.append("hari %d: terkirim %d, dekat %d, selesai %.1f dari tenggat %d (sisa %.1f)%s" % [hari, h["terkirim"], h["dekat"], h["waktu"], h["tenggat"], h["sisa"], "" if baik else " GAGAL"])
		check(baik, "bot bantu hari %d: 25 terkirim (%d), dekat %d, tidak lewat tenggat (sisa %.1f detik)" % [hari, h["terkirim"], h["dekat"], h["sisa"]])
	catatan_bot = semua
	for baris: String in semua:
		print("bot: ", baris)
	check(ok == HARI_BOT_LAMA.size() + SEED_BOT.size(), "semua %d rute bot selesai 25/25" % ok)
