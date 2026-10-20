class_name TesKondisiScene
extends RefCounted
## Tes kondisi sepeda di rute run fase6a1-bengkel-kondisi bagian B (AC-6, AC-8, AC-11, AC-22, AC-23, AC-24): `TampilKondisi` (isi kotak, tanda "!", getar), `KondisiRute` (aus, kerusakan
## tabrakan, peringatan, efek) murni, lalu di `scenes/rute/rute.tscn` sungguhan: aus dari gerak nyata, mode bantu tidak mengubah aus (K-2), tabrakan nyata, efek dari level upgrade
## tersimpan, peringatan berpasangan (bunyi `Audio` dan visual HUD), jeda dan background, jeda pengulangan, garis akhir membekukan aus, dan baris kondisi di layar hasil (lima ukuran
## bersama rekap misi). Harapan literal ditulis tes (ambang BALANCING 8: AUS 0,70, PERLU_BENGKEL 0,35; kerusakan tabrakan 0,30; jeda peringatan 6,0 detik).

const BERKAS_RUTE: String = "res://scenes/rute/rute.tscn"
const BERKAS_HASIL: String = "res://scenes/ui/layar_hasil.tscn"
const DT: float = 1.0 / 60.0
const KASUS_HASIL: Array = [[1920, 1080, 640], [2340, 1080, 780], [2400, 1080, 800], [1600, 720, 800], [2000, 1080, 667]]

var _cek: Callable
var _judul: Callable
var _tree: SceneTree
var _toko: PemuatToko.Kumpulan = PemuatToko.muat()


func _init(cek: Callable, judul: Callable, tree: SceneTree) -> void:
	_cek = cek
	_judul = judul
	_tree = tree


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_test_tampil_kondisi_sapuan()
	_test_tampil_kondisi_getar_dan_kunci()
	_test_kondisi_rute_murni()
	await _test_aus_di_scene()
	await _test_tabrakan_di_scene()
	await _test_efek_dari_level()
	await _test_peringatan_berpasangan()
	await _test_peringatan_jeda_dan_background()
	await _test_garis_akhir_membekukan()
	await _test_hasil_baris_kondisi()
	for kasus: Array in KASUS_HASIL:
		await _test_hasil_lima_ukuran(kasus)
	_test_sumber_tanpa_mode_bantu_dan_iklan()


# --- Pembantu ---

func _state(ban: float = 1.0, rem: float = 1.0, rantai: float = 1.0, level_ban: int = 0, level_rem: int = 0, level_rantai: int = 0) -> Dictionary:
	var s: Dictionary = DataSave.templat()
	var sepeda: Dictionary = s["sepeda"]
	for pasang: Array in [["ban", ban, level_ban], ["rem", rem, level_rem], ["rantai", rantai, level_rantai]]:
		var entri: Dictionary = sepeda[pasang[0]]
		entri["kondisi"] = pasang[1]
		entri["level"] = pasang[2]
	return s


## Rute dengan sepeda dari `state`, hari `hari`, rintangan DIKOSONGKAN (tes aus tidak boleh bertabrakan dengan anjing), stick netral (santai 3,0 u/d), tanpa proses frame nyata.
func _siapkan(state: Dictionary, hari: int = 1, tanpa_rintangan: bool = true) -> RuteMain:
	_tree.root.size = Vector2i(2340, 1080)
	var akar: RuteMain = (load(BERKAS_RUTE) as PackedScene).instantiate() as RuteMain
	akar.atur_sepeda(state, hari, _toko.upgrade)
	_tree.root.add_child(akar)
	await _tree.process_frame
	await _tree.process_frame
	akar.set_process(false)
	(akar.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = false
	(akar.find_child("LoperAgen", true, false) as LoperSprite).set_process(false)
	if tanpa_rintangan:
		akar.set(&"_rintangan", RintanganRute.Keadaan.new())
	_taruh(akar, Config.KECEPATAN_SANTAI_UD, 0.0, 0.0)
	# Frame nyata sebelum `set_process(false)` sudah memajukan sepeda sedikit: kondisi dikembalikan ke awal supaya harapan literal.
	akar.atur_kondisi(KondisiRute.awal(Economy.kondisi_dari(state), Economy.level_dari(state), hari, _toko.upgrade))
	akar.perbarui(0.0)
	return akar


func _bersihkan(akar: RuteMain) -> void:
	if akar.sedang_jeda():
		akar.minta_lanjut()
	(akar.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = OS.has_feature("editor")
	_tree.root.remove_child(akar)
	akar.free()


func _sepeda(akar: Node) -> SepedaUji:
	return akar.find_child("Sepeda", true, false) as SepedaUji


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


func _audio() -> Node:
	return _tree.root.get_node_or_null(^"Audio")


func _jumlah_bunyi(b: BunyiKondisi.Bunyi) -> int:
	var audio: Node = _audio()
	return int(audio.call(&"jumlah_bunyi_kondisi", b)) if audio != null else 0


## Oracle tingkat kotak yang ditulis tes: kondisi c (dibulatkan 2 desimal) -> [terisi, warn, seru] dari ambang literal.
func _harapan_kotak(c: float) -> Array:
	if c >= 0.70:
		return [3, false, false]
	if c >= 0.35:
		return [2, false, false]
	return [1, true, true] if c > 0.0 else [0, false, true]


# --- Murni: TampilKondisi ---

func _test_tampil_kondisi_sapuan() -> void:
	_judul.call("TampilKondisi: kotak, warna, dan tanda '!' untuk kondisi 0,00..1,00 (AC-22, DESIGN_SPEC 3.3)")
	var salah: Array[String] = []
	for i: int in range(101):
		var c: float = float(i) / 100.0
		var h: Array = _harapan_kotak(c)
		var kotak: Array[TampilKondisi.Kotak] = TampilKondisi.kotak(c, false)
		var terisi: int = kotak.count(TampilKondisi.Kotak.PENUH) + kotak.count(TampilKondisi.Kotak.PENUH_WARN)
		var warn: int = kotak.count(TampilKondisi.Kotak.PENUH_WARN)
		var urut: bool = true
		for j: int in range(3):
			urut = urut and ((kotak[j] != TampilKondisi.Kotak.KOSONG) == (j < terisi))
		if kotak.size() != 3 or terisi != h[0] or (warn == terisi and terisi > 0) != h[1] or not urut or TampilKondisi.tanda_seru(c) != h[2]:
			salah.append("%.2f" % c)
	check(salah.is_empty(), "kotak terisi (3 / 2 / 1 / 0), warna WARN hanya PERLU_BENGKEL, terisi dari kiri, dan '!' hanya PERLU_BENGKEL untuk 101 kondisi: salah di %s" % [salah])
	check(TampilKondisi.kotak(0.5, false) == [TampilKondisi.Kotak.PENUH, TampilKondisi.Kotak.PENUH, TampilKondisi.Kotak.KOSONG], "AUS 0,50: dua kotak TEXT, satu hilang")
	check(TampilKondisi.kotak(0.5, true) == [TampilKondisi.Kotak.PENUH_WARN, TampilKondisi.Kotak.PENUH_WARN, TampilKondisi.Kotak.KOSONG], "AUS 0,50 saat peringatan: dua kotak WARN, satu hilang (bentuk tetap, warna berubah)")
	check(TampilKondisi.kotak(0.1, false) == [TampilKondisi.Kotak.PENUH_WARN, TampilKondisi.Kotak.KOSONG, TampilKondisi.Kotak.KOSONG] and TampilKondisi.tanda_seru(0.1), "PERLU_BENGKEL 0,10: satu kotak WARN, dua hilang, dan '!'")
	check(TampilKondisi.kotak(0.0, false) == [TampilKondisi.Kotak.KOSONG, TampilKondisi.Kotak.KOSONG, TampilKondisi.Kotak.KOSONG] and TampilKondisi.tanda_seru(0.0), "kondisi 0: semua kotak hilang tetapi '!' tampil")
	check(KotakKondisi.warna(TampilKondisi.Kotak.PENUH) == Palette.TEXT and KotakKondisi.warna(TampilKondisi.Kotak.PENUH_WARN) == Palette.WARN and KotakKondisi.warna(TampilKondisi.Kotak.KOSONG) == Palette.UI_PANEL_RAISED, "warna kotak dari Palette: TEXT / WARN / UI_PANEL_RAISED")
	check(PolaPiksel.KOTAK_KONDISI_PENUH != PolaPiksel.KOTAK_KONDISI_KOSONG and PolaPiksel.KOTAK_KONDISI_PENUH.size() == 5 and PolaPiksel.KOTAK_KONDISI_PENUH[0].length() == 5 and PolaPiksel.KOTAK_KONDISI_KOSONG.size() == 5, "kotak penuh dan hilang berbeda bentuk (bukan warna saja), 5x5 (DESIGN_SPEC 3.3)")
	check(PolaPiksel.TANDA_SERU_KONDISI.size() == 9 and PolaPiksel.TANDA_SERU_KONDISI[0].length() == Config.KONDISI_HUD_SERU_LEBAR_PX, "tanda '!' 3x9 sesuai KONDISI_HUD_SERU_LEBAR_PX")
	var ukuran: Vector2 = KotakKondisi.ukuran()
	check(ukuran == Vector2(14 + 2 + 17 + 2 + 3, 14), "ukuran satu komponen 38x14 (ikon 14 + jarak 2 + tiga kotak 5 dan jarak 1 + jarak 2 + '!' 3), dapat %s" % ukuran)


func _test_tampil_kondisi_getar_dan_kunci() -> void:
	_judul.call("TampilKondisi: getar ikon hanya saat peringatan, bergantian, murni dari sisa waktu; kunci teks (AC-23)")
	check(TampilKondisi.getar(0.0) == 0 and TampilKondisi.getar(-1.0) == 0 and TampilKondisi.getar(NAN) == 0 and TampilKondisi.getar(INF) == 0, "tanpa peringatan (0, negatif, NaN, tak hingga): ikon diam")
	check(TampilKondisi.getar(0.04) == 1 and TampilKondisi.getar(0.06) == -1 and TampilKondisi.getar(0.09) == -1 and TampilKondisi.getar(0.11) == 1 and TampilKondisi.getar(0.16) == -1, "getar bergantian +1 / -1 tiap setengah periode 0,1 detik (0,05)")
	var geser: Dictionary = {}
	var t: float = Config.KONDISI_KEDIP_DETIK
	while t > 0.0:
		geser[TampilKondisi.getar(t)] = true
		t -= 0.01
	check(geser.has(1) and geser.has(-1) and not geser.has(0), "selama 1,2 detik peringatan ikon bergeser ke dua arah dan tidak diam")
	check(TampilKondisi.kunci_nama("ban") == "KONDISI_NAMA_BAN" and TampilKondisi.kunci_nama("rem") == "KONDISI_NAMA_REM" and TampilKondisi.kunci_nama("rantai") == "KONDISI_NAMA_RANTAI" and TampilKondisi.kunci_nama("setang") == "", "kunci nama komponen; setang tidak dikenal (dicadangkan)")
	check(TampilKondisi.kunci_tingkat(1.0) == "KONDISI_TINGKAT_BAIK" and TampilKondisi.kunci_tingkat(0.7) == "KONDISI_TINGKAT_BAIK" and TampilKondisi.kunci_tingkat(0.69) == "KONDISI_TINGKAT_AUS" and TampilKondisi.kunci_tingkat(0.35) == "KONDISI_TINGKAT_AUS" and TampilKondisi.kunci_tingkat(0.34) == "KONDISI_TINGKAT_PERLU", "kunci tingkat: BAIK >= 0,70, AUS >= 0,35, selebihnya perlu servis (batas inklusif)")
	check(tr("KONDISI_TINGKAT_PERLU") == "Perlu servis" and tr("KONDISI_HASIL_PERLU").format({"komponen": tr("KONDISI_NAMA_RANTAI")}) == "Rantai perlu servis", "teks terjemahan: 'Perlu servis' dan 'Rantai perlu servis' (placeholder bernama)")


# --- Murni: KondisiRute ---

func _gerak(maju: float, v: float, rem: bool = false, rem_mulai: bool = false) -> BikeMotion.Hasil:
	var h: BikeMotion.Hasil = BikeMotion.Hasil.new()
	h.keadaan = BikeMotion.Keadaan.new()
	h.keadaan.kecepatan_ud = v
	h.keadaan.rem_aktif = rem
	h.maju_ubin = maju
	h.kecepatan_awal_ud = v
	h.rem_mulai = rem_mulai
	return h


func _tabrak(nomor: int) -> Tabrakan.Hasil:
	var h: Tabrakan.Hasil = Tabrakan.Hasil.new()
	h.tabrak = true
	h.keadaan = Tabrakan.awal()
	h.keadaan.jumlah = nomor
	return h


func _test_kondisi_rute_murni() -> void:
	_judul.call("KondisiRute: aus dari telemetri apa adanya, kerusakan tabrakan, peringatan berjeda, efek dari level, garis akhir dan jeda membekukan (AC-6, AC-8, AC-11)")
	var awal: KondisiRute.Keadaan = KondisiRute.awal({"ban": 1.0, "rem": 1.0, "rantai": 1.0}, {}, 4, _toko.upgrade)
	# Aus sama dengan BikeCondition.aus pada telemetri yang sama; santai 1 ubin: ban 0,00015, rantai 0,00011, rem utuh (literal Config BALANCING 8.2).
	var satu: KondisiRute.Hasil = KondisiRute.langkah(awal, _gerak(1.0, 3.0), 1.0 / 3.0, null, false)
	check(absf(float(satu.keadaan.kondisi["ban"]) - (1.0 - 0.00015)) < 1e-12 and absf(float(satu.keadaan.kondisi["rantai"]) - (1.0 - 0.00011)) < 1e-12 and satu.keadaan.kondisi["rem"] == 1.0, "santai 1 ubin: ban -0,00015, rantai -0,00011, rem utuh")
	check(awal.kondisi["ban"] == 1.0 and satu.keadaan != awal, "masukan tidak diubah (keadaan baru tiap langkah)")
	# dt nol / negatif / tak hingga membekukan aus, peringatan, dan waktu kedip.
	var peringatan_awal: KondisiRute.Keadaan = KondisiRute.awal({"ban": 0.5, "rem": 0.5, "rantai": 0.5}, {}, 4, [] as Array[DataToko])
	for dt: float in [0.0, -1.0, INF, NAN]:
		var beku: KondisiRute.Hasil = KondisiRute.langkah(peringatan_awal, _gerak(1.0, 4.0), dt, null, false)
		check(beku.peringatan.is_empty() and beku.keadaan.kondisi == peringatan_awal.kondisi and beku.keadaan.kedip == peringatan_awal.kedip, "dt %s: tidak ada aus, peringatan, atau waktu maju (beku)" % dt)
	# Peringatan: langkah pertama (jeda sudah penuh), lalu menunggu 6 detik.
	var p1: KondisiRute.Hasil = KondisiRute.langkah(peringatan_awal, _gerak(0.05, 3.0), DT, null, false)
	check(p1.peringatan == ["ban", "rantai"], "ban dan rantai AUS saat melaju santai 3,0 u/d: peringatan pada langkah pertama (urut ban, rantai; rem tidak dipakai), dapat %s" % [p1.peringatan])
	check(float(p1.keadaan.kedip["ban"]) == Config.KONDISI_KEDIP_DETIK and float(p1.keadaan.kedip["rantai"]) == Config.KONDISI_KEDIP_DETIK and float(p1.keadaan.kedip["rem"]) == 0.0, "visual peringatan (kedip) 1,2 detik untuk komponen yang memperingatkan")
	var k: KondisiRute.Keadaan = p1.keadaan
	var tambahan: int = 0
	for i: int in range(int(5.9 / DT)):
		var h: KondisiRute.Hasil = KondisiRute.langkah(k, _gerak(0.05, 3.0), DT, null, false)
		tambahan += h.peringatan.size()
		k = h.keadaan
	check(tambahan == 0, "5,9 detik kemudian: belum ada peringatan kedua (jeda 6,0 detik)")
	for i: int in range(int(0.2 / DT)):
		var h2: KondisiRute.Hasil = KondisiRute.langkah(k, _gerak(0.05, 3.0), DT, null, false)
		tambahan += h2.peringatan.size()
		k = h2.keadaan
	check(tambahan == 2, "lewat 6,0 detik: peringatan kedua untuk ban dan rantai, dapat %d" % tambahan)
	check(float(k.kedip["ban"]) > 0.0 and float(k.kedip["ban"]) <= Config.KONDISI_KEDIP_DETIK, "kedip dimulai lagi sesudah peringatan kedua")
	# Kedip habis dengan waktu.
	var sisa: KondisiRute.Keadaan = p1.keadaan
	for i: int in range(int(1.3 / DT)):
		sisa = KondisiRute.langkah(sisa, _gerak(0.0, 0.0), DT, null, false).keadaan
	check(float(sisa.kedip["ban"]) == 0.0 and not KondisiRute.sedang_kedip(sisa, "ban"), "diam 1,3 detik: kedip berhenti (tidak ada peringatan palsu untuk sepeda yang tidak dipakai)")
	# BAIK tidak pernah memperingatkan.
	var baik: KondisiRute.Keadaan = KondisiRute.awal({"ban": 0.9, "rem": 0.9, "rantai": 0.9}, {}, 4, [] as Array[DataToko])
	var jumlah_baik: int = 0
	for i: int in range(3000):
		var hb: KondisiRute.Hasil = KondisiRute.langkah(baik, _gerak(0.1, 5.0, i % 100 > 50), DT, null, false)
		jumlah_baik += hb.peringatan.size()
	check(jumlah_baik == 0, "kondisi BAIK dipakai 50 detik: nol peringatan")
	# Tabrakan: satu pengurangan 0,30 pada komponen dari seed hari 4 nomor 0; tanpa tabrakan tidak berubah.
	var kom: String = BikeCondition.komponen_tabrakan(4, 0)
	var rusak: KondisiRute.Hasil = KondisiRute.langkah(awal, _gerak(0.0, 0.0), DT, _tabrak(1), false)
	var turun: int = 0
	for id: String in Config.KONDISI_KOMPONEN:
		if float(rusak.keadaan.kondisi[id]) < 1.0:
			turun += 1
			check(id == kom and absf(float(rusak.keadaan.kondisi[id]) - 0.7) < 1e-12, "tabrakan 1 hari 4: tepat komponen %s dikurangi 0,30 (dapat %s)" % [kom, id])
	check(turun == 1, "satu tabrakan = satu komponen berkurang, dapat %d" % turun)
	# Garis akhir: tidak ada aus, kerusakan, atau peringatan; kedip tetap berjalan sampai habis.
	var akhir: KondisiRute.Hasil = KondisiRute.langkah(p1.keadaan, _gerak(5.0, 6.0, true, true), 1.0, _tabrak(2), true)
	check(akhir.keadaan.kondisi == p1.keadaan.kondisi and akhir.peringatan.is_empty() and float(akhir.keadaan.kedip["ban"]) == maxf(Config.KONDISI_KEDIP_DETIK - 1.0, 0.0), "selesai: kondisi tetap walau ada gerak dan tabrakan, tanpa peringatan, kedip tetap berkurang")
	# Efek dari level tersimpan dan data upgrade nyata (nilai literal upgrades.json).
	var upg: KondisiRute.Keadaan = KondisiRute.awal({"ban": 1.0, "rem": 1.0, "rantai": 1.0}, {"ban": 1, "rem": 1, "rantai": 1}, 1, _toko.upgrade)
	check(upg.efek.pengali_lateral == 1.15 and upg.efek.pengali_rem == 1.2 and upg.efek.pengali_kuras_stamina == 0.85 and upg.efek.pengali_kecepatan == 1.0 and upg.efek.pengali_akselerasi == 1.0, "level upgrade tersimpan 1/1/1: lateral x1,15, rem x1,2, stamina x0,85, tanpa efek kerusakan")
	var aus_hemat: KondisiRute.Hasil = KondisiRute.langkah(upg, _gerak(10.0, 3.0), 10.0 / 3.0, null, false)
	check(absf((1.0 - float(aus_hemat.keadaan.kondisi["rantai"])) - 10.0 * 0.00011 * 0.8) < 1e-12 and absf((1.0 - float(aus_hemat.keadaan.kondisi["ban"])) - 10.0 * 0.00015) < 1e-12, "rantai hemat: aus rantai x0,8 (0,00088 per 10 ubin), ban tanpa pengali")
	var tanpa_daftar: KondisiRute.Keadaan = KondisiRute.awal({}, {"ban": 1}, 1, [] as Array[DataToko])
	check(tanpa_daftar.efek.identitas() and tanpa_daftar.kondisi == BikeCondition.baru(), "kondisi kosong = sepeda baru; level tanpa data upgrade = tidak ada efek")
	var rusak_total: KondisiRute.Keadaan = KondisiRute.awal({"ban": 0.0, "rem": 0.0, "rantai": 0.0}, {}, 1, [] as Array[DataToko])
	check(rusak_total.efek.pengali_kecepatan == 0.92 and rusak_total.efek.pengali_lateral == 0.6 and rusak_total.efek.pengali_rem == 0.4 and rusak_total.efek.pengali_akselerasi == 0.35 and rusak_total.efek.batas_puncak_ud == 3.6, "kondisi 0: efek terburuk (literal BALANCING 8.4) 0,92 / 0,6 / 0,4 / 0,35 / puncak 3,6")


# --- Scene: aus, mode bantu, tabrakan, efek ---

func _test_aus_di_scene() -> void:
	_judul.call("Scene rute: aus dari gerak nyata sama dengan oracle; mode bantu tidak mengubah aus (K-2, AC-6, AC-11)")
	var akar: RuteMain = await _siapkan(_state())
	_langkah(akar, 1200)
	var sepeda: SepedaUji = _sepeda(akar)
	var kondisi: Dictionary = akar.kondisi().kondisi
	# Oracle independen: simulasi BikeMotion + BikeCondition murni dengan masukan yang sama.
	var s: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
	var k: Dictionary = BikeCondition.baru()
	var jarak: float = 0.0
	for i: int in range(1200):
		var h: BikeMotion.Hasil = BikeMotion.langkah(s, Vector2.ZERO, DT)
		k = BikeCondition.aus(k, BikeCondition.telemetri(h, DT))
		s = h.keadaan
		jarak += h.maju_ubin
	check(absf(sepeda.jarak_ubin - jarak) < 1e-9, "kontrol: jarak scene = simulasi (%.4f ubin)" % jarak)
	for id: String in Config.KONDISI_KOMPONEN:
		check(absf(float(kondisi[id]) - float(k[id])) < 1e-9, "20 detik santai: kondisi %s di scene (%.6f) = simulasi (%.6f)" % [id, float(kondisi[id]), float(k[id])])
	check(float(kondisi["ban"]) < 0.9915 and float(kondisi["ban"]) > 0.9885 and kondisi["rem"] == 1.0, "literal: 60 ubin santai -> ban sekitar 0,991 (60 x 0,00015), rem utuh (tanpa pengereman); dapat ban %.5f" % float(kondisi["ban"]))
	check(akar.hud_rute().kondisi_tampil() and akar.hud_rute().kotak_kondisi("ban").kotak_tampil() == [TampilKondisi.Kotak.PENUH, TampilKondisi.Kotak.PENUH, TampilKondisi.Kotak.PENUH], "HUD: panel kondisi tampil, tiga kotak penuh (BAIK)")
	var aus_tanpa_bantu: Dictionary = kondisi.duplicate()
	_bersihkan(akar)
	var bantu: RuteMain = await _siapkan(_state())
	bantu.atur_mode_bantu(true)
	_langkah(bantu, 1200)
	check(bantu.kondisi().kondisi == aus_tanpa_bantu, "mode bantu menyala: aus identik bit demi bit dengan tanpa mode bantu pada gerak yang sama (K-2: satu ekonomi)")
	_bersihkan(bantu)
	# Pengereman: rem mulai (tepi naik) dan lama aktif aus rem; lepas stick sebelum 0,25 detik tidak.
	var rem: RuteMain = await _siapkan(_state())
	_taruh(rem, 5.0, 0.0, 10.0)
	rem.perbarui(0.0)
	var stick_bawah: Vector2 = Vector2(0.0, -1.0)
	var kontrol: KontrolTouch = rem.find_child("KontrolTouch", true, false) as KontrolTouch
	kontrol.keyboard_aktif = true
	Input.action_press(&"stick_bawah")
	_langkah(rem, 30)
	Input.action_release(&"stick_bawah")
	kontrol.keyboard_aktif = false
	check(stick_bawah.y < 0.0 and float(rem.kondisi().kondisi["rem"]) < 1.0 and float(rem.kondisi().kondisi["rem"]) > 0.97, "rem ditarik 0,5 detik dari 5 u/d: rem aus satu pengereman + lama aktif (< 3%%), dapat %.4f" % float(rem.kondisi().kondisi["rem"]))
	_bersihkan(rem)


func _test_tabrakan_di_scene() -> void:
	_judul.call("Scene rute: tabrakan nyata mengurangi satu komponen 0,30 dari seed hari; HUD berkurang segera (AC-6, AC-22, AC-23)")
	var hari: int = 5
	var akar: RuteMain = await _siapkan(_state(0.9, 0.9, 0.9), hari, false)
	var tabrak: Array[String] = []
	akar.tabrakan.connect(func(jenis: String) -> void: tabrak.append(jenis))
	_taruh(akar, 3.0, -0.6, 30.0)
	var langkah: int = 0
	var sebelum: Dictionary = {}
	while tabrak.is_empty() and langkah < 600:
		sebelum = akar.kondisi().kondisi.duplicate()
		akar.perbarui(DT)
		langkah += 1
	check(tabrak == ["anjing_penjaga"], "kontrol: tabrakan nyata dengan anjing (rute seed dev), dapat %s" % [tabrak])
	var kom: String = BikeCondition.komponen_tabrakan(hari, 0)
	var sesudah: Dictionary = akar.kondisi().kondisi
	var turun: Array[String] = []
	for id: String in Config.KONDISI_KOMPONEN:
		if float(sesudah[id]) < float(sebelum[id]) - 0.2:
			turun.append(id)
			check(absf(float(sebelum[id]) - float(sesudah[id]) - 0.3) < 0.002, "komponen %s berkurang 0,30 (ditambah aus langkah itu)" % id)
	check(turun == [kom], "tepat satu komponen berkurang pada tabrakan: %s (oracle seed hari %d nomor 0 = %s)" % [turun, hari, kom])
	var kotak: KotakKondisi = akar.hud_rute().kotak_kondisi(kom)
	var isi_kotak: Array[TampilKondisi.Kotak] = kotak.kotak_tampil()
	check(float(sesudah[kom]) < 0.7 and float(sesudah[kom]) >= 0.35 and isi_kotak[2] == TampilKondisi.Kotak.KOSONG and isi_kotak[0] != TampilKondisi.Kotak.KOSONG and isi_kotak[1] != TampilKondisi.Kotak.KOSONG and not kotak.seru_tampil(), "0,90 - 0,30 = 0,60 (AUS): HUD segera menampilkan dua kotak terisi dan satu hilang, tanpa '!' (kotak berkurang segera): %s" % [isi_kotak])
	if kom != "rem":
		check(kotak.getar_tampil() != 0 and isi_kotak[0] == TampilKondisi.Kotak.PENUH_WARN, "komponen yang baru menjadi AUS dan sedang dipakai langsung memperingatkan pada langkah tabrakan (ikon bergetar, kotak WARN)")
	# Tabrakan kedua pada komponen lain/sama memakai nomor 1; jatuh dan kebal tidak menggandakan.
	_langkah(akar, 200)
	check(tabrak.size() == 1, "tidak ada tabrakan kedua selama jatuh dan kebal; kondisi komponen tidak berkurang lagi oleh jatuh yang berlanjut")
	check(float(akar.kondisi().kondisi[kom]) > float(sesudah[kom]) - 0.01, "jatuh yang berlanjut tidak mengurangi lagi (kondisi %.4f)" % float(akar.kondisi().kondisi[kom]))
	_bersihkan(akar)


func _test_efek_dari_level() -> void:
	_judul.call("Scene rute: efek memakai kondisi dan level upgrade tersimpan (AC-9, AC-18, AC-21)")
	var state: Dictionary = _state(1.0, 1.0, 0.0, 1, 1, 0)
	var akar: RuteMain = await _siapkan(state, 2)
	var e: EfekKondisi = akar.kondisi().efek
	check(e.pengali_lateral == 1.15 and e.pengali_rem == 1.2 and e.pengali_akselerasi == 0.35 and e.batas_puncak_ud == 3.6 and e.pengali_kuras_stamina == 1.0, "level ban 1 dan rem 1, rantai 0 rusak total: lateral x1,15, rem x1,2, akselerasi x0,35, puncak 3,6 u/d")
	var k: KotakKondisi = akar.hud_rute().kotak_kondisi("rantai")
	check(k.kotak_tampil() == [TampilKondisi.Kotak.KOSONG, TampilKondisi.Kotak.KOSONG, TampilKondisi.Kotak.KOSONG] and k.seru_tampil(), "HUD rantai 0: semua kotak hilang dan '!' tampil; ban dan rem tiga kotak penuh")
	# Gerak nyata: stick penuh ke atas 2 detik. Rantai rusak total membatasi puncak 3,6 u/d; sepeda baru melaju lebih cepat.
	var kontrol: KontrolTouch = akar.find_child("KontrolTouch", true, false) as KontrolTouch
	kontrol.keyboard_aktif = true
	Input.action_press(&"stick_atas")
	_langkah(akar, 180)
	Input.action_release(&"stick_atas")
	kontrol.keyboard_aktif = false
	var rusak_v: float = _sepeda(akar).kecepatan_ud
	_bersihkan(akar)
	var baru: RuteMain = await _siapkan(_state(), 2)
	var kontrol2: KontrolTouch = baru.find_child("KontrolTouch", true, false) as KontrolTouch
	kontrol2.keyboard_aktif = true
	Input.action_press(&"stick_atas")
	_langkah(baru, 180)
	Input.action_release(&"stick_atas")
	kontrol2.keyboard_aktif = false
	var baru_v: float = _sepeda(baru).kecepatan_ud
	check(rusak_v <= 3.6 + 1e-9 and baru_v > 5.5 and rusak_v < baru_v, "rantai rusak total: kecepatan puncak %.2f <= 3,6 u/d; sepeda baru %.2f u/d (efek hanya menghambat, sepeda tetap melaju)" % [rusak_v, baru_v])
	_bersihkan(baru)


# --- Scene: peringatan berpasangan ---

func _test_peringatan_berpasangan() -> void:
	_judul.call("Scene rute: peringatan = bunyi (Audio) + ikon bergetar + kotak WARN pada langkah yang sama; BAIK diam; tanpa audio visual tetap ada (AC-23)")
	var akar: RuteMain = await _siapkan(_state(0.5, 0.5, 0.5))
	var sinyal: Array[String] = []
	akar.peringatan_kondisi.connect(func(k: String) -> void: sinyal.append(k))
	var ban0: int = _jumlah_bunyi(BunyiKondisi.Bunyi.BAN_MENDESIS)
	var rantai0: int = _jumlah_bunyi(BunyiKondisi.Bunyi.RANTAI_BERISIK)
	var rem0: int = _jumlah_bunyi(BunyiKondisi.Bunyi.REM_BERDECIT)
	akar.perbarui(DT)
	check(sinyal == ["ban", "rantai"], "langkah pertama santai 3,0 u/d: sinyal peringatan ban lalu rantai (rem tidak dipakai), dapat %s" % [sinyal])
	if _audio() != null:
		check(_jumlah_bunyi(BunyiKondisi.Bunyi.BAN_MENDESIS) == ban0 + 1 and _jumlah_bunyi(BunyiKondisi.Bunyi.RANTAI_BERISIK) == rantai0 + 1 and _jumlah_bunyi(BunyiKondisi.Bunyi.REM_BERDECIT) == rem0, "bunyi pada langkah yang sama: ban mendesis +1, rantai berisik +1, rem berdecit tetap")
		var pemutar: AudioStreamPlayer = _audio().call(&"pemutar_kondisi", BunyiKondisi.berkas(BunyiKondisi.Bunyi.BAN_MENDESIS)) as AudioStreamPlayer
		check(pemutar != null and pemutar.playing and pemutar.bus == &"SFX" and pemutar.volume_db < Config.AUDIO_BEL_VOLUME_DB and pemutar.volume_db < Config.AUDIO_TABRAKAN_VOLUME_DB, "pemutar ban mendesis berbunyi di bus SFX, lebih pelan dari bel dan tabrakan (tidak menutupinya)")
	var hud: HudRute = akar.hud_rute()
	for id: String in ["ban", "rantai"]:
		var kotak: KotakKondisi = hud.kotak_kondisi(id)
		check(kotak.getar_tampil() != 0 and kotak.kotak_tampil() == [TampilKondisi.Kotak.PENUH_WARN, TampilKondisi.Kotak.PENUH_WARN, TampilKondisi.Kotak.KOSONG], "visual %s: ikon bergetar (%d px) dan kotak terisi WARN" % [id, kotak.getar_tampil()])
	var rem_kotak: KotakKondisi = hud.kotak_kondisi("rem")
	check(rem_kotak.getar_tampil() == 0 and rem_kotak.kotak_tampil() == [TampilKondisi.Kotak.PENUH, TampilKondisi.Kotak.PENUH, TampilKondisi.Kotak.KOSONG], "rem tidak dipakai: tidak bergetar, kotak tetap TEXT")
	# Jeda pengulangan di scene: 5,8 detik tidak ada peringatan kedua, 6,2 detik ada.
	_langkah(akar, 348)
	check(sinyal.size() == 2, "5,8 detik kemudian: belum ada peringatan kedua (jeda 6,0 detik), sinyal %d" % sinyal.size())
	_langkah(akar, 30)
	check(sinyal.size() == 4, "6,3 detik: peringatan kedua untuk ban dan rantai, sinyal %d" % sinyal.size())
	# Kedip berhenti dengan waktu: sesudah 1,2 detik ikon diam dan kotak kembali TEXT.
	_langkah(akar, 80)
	check(hud.kotak_kondisi("ban").getar_tampil() == 0 and hud.kotak_kondisi("ban").kotak_tampil()[0] == TampilKondisi.Kotak.PENUH, "sesudah kedip selesai: ikon diam dan kotak kembali TEXT")
	_bersihkan(akar)
	# Tanpa audio: visual tetap muncul (bunyi bukan satu-satunya pembawa informasi).
	var sunyi: RuteMain = await _siapkan(_state(0.5, 0.5, 0.5))
	sunyi.set(&"_audio", null)
	var hitung: Array[int] = [0]
	sunyi.peringatan_kondisi.connect(func(_k: String) -> void: hitung[0] += 1)
	sunyi.perbarui(DT)
	check(hitung[0] == 2 and sunyi.hud_rute().kotak_kondisi("ban").getar_tampil() != 0, "tanpa autoload Audio: peringatan dan visual (ikon bergetar) tetap terjadi")
	_bersihkan(sunyi)
	# BAIK: nol peringatan, ikon diam.
	var baik: RuteMain = await _siapkan(_state())
	var diam: Array[int] = [0]
	baik.peringatan_kondisi.connect(func(_k: String) -> void: diam[0] += 1)
	_langkah(baik, 1200)
	check(diam[0] == 0 and baik.hud_rute().kotak_kondisi("ban").getar_tampil() == 0, "kondisi BAIK dipakai 20 detik: nol peringatan dan ikon diam")
	_bersihkan(baik)
	# Rem berdecit: rem aus dan sedang mengerem.
	var rem: RuteMain = await _siapkan(_state(1.0, 0.5, 1.0))
	var rem_sinyal: Array[String] = []
	rem.peringatan_kondisi.connect(func(k: String) -> void: rem_sinyal.append(k))
	_taruh(rem, 5.0, 0.0, 10.0)
	var kontrol: KontrolTouch = rem.find_child("KontrolTouch", true, false) as KontrolTouch
	kontrol.keyboard_aktif = true
	Input.action_press(&"stick_bawah")
	_langkah(rem, 40)
	Input.action_release(&"stick_bawah")
	kontrol.keyboard_aktif = false
	check(rem_sinyal.has("rem") and rem_sinyal.count("rem") == 1, "rem AUS saat mengerem: satu peringatan rem berdecit (jeda 6 detik mencegah ulang), dapat %s" % [rem_sinyal])
	_bersihkan(rem)


func _test_peringatan_jeda_dan_background() -> void:
	_judul.call("Scene rute: jeda dan background menghentikan bunyi dan membekukan peringatan, kedip, dan aus (AC-23)")
	var akar: RuteMain = await _siapkan(_state(0.5, 0.5, 0.5))
	akar.perbarui(DT)
	var audio: Node = _audio()
	var kedip_awal: float = float(akar.kondisi().kedip["ban"])
	var kondisi_awal: Dictionary = akar.kondisi().kondisi.duplicate()
	var jumlah_awal: int = akar.kondisi().jumlah_peringatan["ban"]
	akar.minta_jeda()
	if audio != null:
		check(not bool(audio.call(&"ada_bunyi_kondisi")), "jeda: bunyi kondisi yang sedang berbunyi dihentikan seketika")
	_langkah(akar, 600, 1.0)
	check(float(akar.kondisi().kedip["ban"]) == kedip_awal and akar.kondisi().kondisi == kondisi_awal and akar.kondisi().jumlah_peringatan["ban"] == jumlah_awal, "10 menit waktu nyata selama jeda: kedip, kondisi, dan jumlah peringatan tidak berubah (beku)")
	check(akar.hud_rute().kotak_kondisi("ban").getar_tampil() == TampilKondisi.getar(kedip_awal), "ikon tidak bergetar lebih jauh selama jeda (fase getar beku)")
	akar.minta_lanjut()
	akar.perbarui(DT)
	check(akar.kondisi().jumlah_peringatan["ban"] == jumlah_awal, "langkah pertama sesudah lanjut ber-dt 0: tidak ada peringatan baru")
	# Background: app dijeda seperti tombol jeda.
	akar.propagate_notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(akar.sedang_jeda(), "app ke background: rute dijeda")
	_langkah(akar, 600, 1.0)
	check(akar.kondisi().jumlah_peringatan["ban"] == jumlah_awal and akar.kondisi().kondisi == kondisi_awal, "background: nol peringatan dan nol aus")
	if audio != null:
		check(not bool(audio.call(&"ada_bunyi_kondisi")), "background: tidak ada bunyi kondisi")
	_bersihkan(akar)


func _test_garis_akhir_membekukan() -> void:
	_judul.call("Scene rute: sesudah garis akhir tidak ada aus, kerusakan, atau peringatan; 'Main lagi' mengembalikan kondisi awal rute (AC-6)")
	var akar: RuteMain = await _siapkan(_state(0.5, 0.9, 0.5), 3)
	_taruh(akar, 3.0, 0.0, akar.rute().panjang_ubin - 0.5)
	_langkah(akar, 30)
	check(akar.rute_sudah_selesai(), "kontrol: garis akhir terlewati")
	var kondisi: Dictionary = akar.kondisi().kondisi.duplicate()
	var jumlah: Dictionary = akar.kondisi().jumlah_peringatan.duplicate()
	_langkah(akar, 600)
	check(akar.kondisi().kondisi == kondisi and akar.kondisi().jumlah_peringatan == jumlah, "10 detik sesudah garis akhir (pengereman otomatis): kondisi dan jumlah peringatan tidak berubah")
	check(akar.kondisi_akhir()["ban"] == BikeCondition.bulatkan(float(kondisi["ban"])), "kondisi_akhir() = kondisi dibulatkan 4 desimal (bentuk save)")
	akar.main_lagi()
	check(akar.kondisi().kondisi == {"ban": 0.5, "rem": 0.9, "rantai": 0.5} and akar.kondisi().hari == 3, "Main lagi: kondisi kembali ke kondisi awal rute (0,5 / 0,9 / 0,5), hari tetap")
	_bersihkan(akar)


# --- Layar hasil ---

func _angka(koin: int = 120) -> HasilRute.Angka:
	var a: HasilRute.Angka = HasilRute.Angka.new()
	a.pelanggan = 25
	a.terkirim = 3
	a.meleset = 22
	a.koin = koin
	a.koin_tip = 25
	a.jumlah_tip = 1
	a.skor = 1500
	a.jumlah_tepat = 2
	return a


func _test_hasil_baris_kondisi() -> void:
	_judul.call("Layar hasil: baris kondisi hanya bila ada PERLU_BENGKEL, Angka tidak berubah, tombol 'Ke bengkel' (AC-24)")
	var akar: RuteMain = await _siapkan(_state(1.0, 0.2, 0.3), 1)
	akar.atur_mode_hari(true)
	var dibuka: Array[HasilRute.Angka] = []
	akar.hasil_dibuka.connect(func(a: HasilRute.Angka) -> void: dibuka.append(a))
	_taruh(akar, 3.0, 0.0, akar.rute().panjang_ubin - 0.5)
	for i: int in range(900):
		if akar.hasil_tampil():
			break
		akar.perbarui(DT)
	check(akar.hasil_tampil() and dibuka.size() == 1, "kontrol: layar hasil terbuka")
	var hasil: LayarHasil = akar.layar_hasil()
	check(hasil.teks_kondisi() == ["Rem perlu servis", "Rantai perlu servis"], "dua komponen PERLU_BENGKEL (rem 0,2 dan rantai 0,3): baris 'Rem perlu servis' dan 'Rantai perlu servis' urut ban, rem, rantai; dapat %s" % [hasil.teks_kondisi()])
	check(hasil.teks_tombol() == "Ke bengkel" and hasil.mode_hari(), "tombol layar hasil di alur hari: 'Ke bengkel'")
	var angka_rusak: HasilRute.Angka = akar.angka_hasil()
	var bersih: RuteMain = await _siapkan(_state(), 1)
	bersih.atur_mode_hari(true)
	_taruh(bersih, 3.0, 0.0, bersih.rute().panjang_ubin - 0.5)
	for i: int in range(900):
		if bersih.hasil_tampil():
			break
		bersih.perbarui(DT)
	check(bersih.hasil_tampil() and bersih.layar_hasil().teks_kondisi().is_empty() and bersih.layar_hasil().rect_kondisi().is_empty() and not bersih.layar_hasil().kondisi_tampil() and akar.layar_hasil().kondisi_tampil(), "sepeda baik: tidak ada baris kondisi sama sekali dan blok kondisi tersembunyi (rusak: tampil)")
	var angka_bersih: HasilRute.Angka = bersih.angka_hasil()
	var sama: bool = true
	for nama: StringName in [&"pelanggan", &"terkirim", &"meleset", &"koin", &"koin_tip", &"jumlah_tip", &"skor", &"jumlah_tepat", &"tenggat_lewat", &"detik_lewat", &"koin_misi", &"misi_hasil", &"misi_id"]:
		sama = sama and angka_rusak.get(nama) == angka_bersih.get(nama)
	check(sama, "HasilRute.Angka dari rute yang sama identik dengan dan tanpa kondisi rusak (angka tidak tersentuh kondisi)")
	_bersihkan(bersih)
	_bersihkan(akar)
	# Tiga komponen rusak: tiga baris.
	var tiga: RuteMain = await _siapkan(_state(0.1, 0.1, 0.1), 1)
	_taruh(tiga, 3.0, 0.0, tiga.rute().panjang_ubin - 0.5)
	for i: int in range(900):
		if tiga.hasil_tampil():
			break
		tiga.perbarui(DT)
	check(tiga.layar_hasil().teks_kondisi() == ["Ban perlu servis", "Rem perlu servis", "Rantai perlu servis"], "tiga komponen PERLU_BENGKEL: tiga baris, dapat %s" % [tiga.layar_hasil().teks_kondisi()])
	_bersihkan(tiga)


func _test_hasil_lima_ukuran(kasus: Array) -> void:
	var lebar: int = kasus[2]
	var tag: String = "hasil %dx%d (viewport %d)" % [kasus[0], kasus[1], lebar]
	_judul.call("Layar hasil %s: tiga baris kondisi bersama rekap misi, tenggat lewat panjang: tidak terpotong, tidak bertumpuk (AC-24)" % tag)
	_tree.root.size = Vector2i(kasus[0], kasus[1])
	var layar: LayarHasil = (load(BERKAS_HASIL) as PackedScene).instantiate() as LayarHasil
	_tree.root.add_child(layar)
	await _tree.process_frame
	var misi: DataMisi = null
	for m: DataMisi in PemuatMisi.muat_folder().misi:
		if m.id == "p1_kucing":
			misi = m
	var angka: HasilRute.Angka = _angka(195)
	angka.tenggat_lewat = true
	angka.detik_lewat = 72
	angka.misi_hasil = "selesai"
	angka.koin_misi = 75
	layar.isi(angka, misi, ["ban", "rem", "rantai"] as Array[String])
	layar.tampilkan(true)
	await _tree.process_frame
	await _tree.process_frame
	var kotak_layar: Rect2 = Rect2(Vector2.ZERO, Vector2(lebar, 360))
	var panel: Rect2 = layar.rect_panel()
	check(kotak_layar.encloses(panel) and layar.rect_kondisi().size() == 3 and layar.teks_rekap_misi() != "", "%s: panel di dalam layar, tiga baris kondisi dan rekap misi tampil" % tag)
	var dalam: bool = true
	for r: Rect2 in layar.rect_label():
		dalam = dalam and panel.encloses(r) and r.size.x > 0.0
	check(dalam, "%s: semua label (termasuk tiga baris kondisi) di dalam panel" % tag)
	var tombol: Rect2 = layar.rect_tombol()
	check(tombol.size.y >= 42.0 and tombol.size.x >= 42.0 and panel.encloses(tombol), "%s: tombol >= 42 px di dalam panel" % tag)
	var tumpuk: bool = false
	var semua: Array[Rect2] = layar.rect_label()
	for i: int in range(semua.size()):
		for j: int in range(i + 1, semua.size()):
			tumpuk = tumpuk or semua[i].intersects(semua[j])
		tumpuk = tumpuk or semua[i].intersects(tombol)
	check(not tumpuk, "%s: tidak ada label atau tombol yang bertumpuk" % tag)
	var tidak_terpotong: bool = true
	for nama: String in ["KondisiSatu", "KondisiDua", "KondisiTiga", "RekapMisi", "TeksTenggat"]:
		var label: Label = layar.find_child(nama, true, false) as Label
		var font: Font = label.get_theme_font(&"font")
		var tinggi: float = font.get_height(label.get_theme_font_size(&"font_size")) * float(maxi(label.get_line_count(), 1))
		tidak_terpotong = tidak_terpotong and label.get_visible_line_count() == label.get_line_count() and label.size.y + 0.5 >= tinggi
	check(tidak_terpotong, "%s: tidak ada baris yang terpotong" % tag)
	check(layar.teks_kondisi() == ["Ban perlu servis", "Rem perlu servis", "Rantai perlu servis"], "%s: teks baris kondisi dari kunci terjemahan" % tag)
	_tree.root.remove_child(layar)
	layar.free()


# --- Pemindai sumber ---

## Isi berkas tanpa baris komentar penuh (`#` atau `##`): yang dipindai adalah kode, bukan penjelasannya.
func _teks(jalur: String) -> String:
	var baris: PackedStringArray = PackedStringArray()
	for satu: String in FileAccess.get_file_as_string(jalur).split("\n"):
		if not satu.strip_edges().begins_with("#"):
			baris.append(satu)
	return "\n".join(baris)


func _test_sumber_tanpa_mode_bantu_dan_iklan() -> void:
	_judul.call("Sumber: kondisi, ekonomi, dan bengkel tanpa cabang mode bantu (K-2, AC-11) dan tanpa iklan (AC-16)")
	var berkas: Array[String] = [
		"res://scripts/systems/bike_condition.gd", "res://scripts/systems/economy.gd", "res://scripts/systems/kondisi_rute.gd", "res://scripts/systems/tampil_kondisi.gd",
		"res://scripts/systems/bunyi_kondisi.gd", "res://scripts/ui/layar_bengkel.gd", "res://scripts/ui/kotak_kondisi.gd",
	]
	for jalur: String in berkas:
		var teks: String = _teks(jalur).to_lower()
		check(not teks.contains("mode_bantu") and not teks.contains("modebantu") and not teks.contains("bantu_lempar"), "%s: tidak menyebut mode bantu (satu ekonomi untuk semua pemain)" % jalur)
	for jalur: String in ["res://scripts/ui/layar_bengkel.gd", "res://scenes/bengkel/bengkel.tscn", "res://scripts/entities/hari_main.gd"]:
		var teks2: String = _teks(jalur).to_lower()
		check(not teks2.contains("adservice") and not teks2.contains("ad_service") and not teks2.contains("iklan") and not teks2.contains("admob"), "%s: tidak merujuk layanan iklan (tempat iklan hadiah tidak ada, rule privacy-ads)" % jalur)
	var adegan: String = _teks("res://scripts/entities/adegan_jalan.gd")
	var awal: int = adegan.find("func _langkah_kondisi")
	var akhir: int = adegan.find("\n\n\n", awal)
	check(awal > 0 and akhir > awal and not adegan.substr(awal, akhir - awal).to_lower().contains("bantu"), "AdeganJalan._langkah_kondisi tidak bercabang pada mode bantu")
