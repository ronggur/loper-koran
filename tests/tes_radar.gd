class_name TesRadar
extends RefCounted
## Tes logika murni radar (AC-4, AC-6; K-2, O-9, O-10) dan status kotak progres (AC-7, O-12) run fase3c-hud-hasil.
##
## Oracle independen (AC-17): rute buatan tangan dengan pusat kotak surat di jarak bulat (awal kavling = pusat - 1,875, karena zona kotak
## surat seberang dan dekat sama-sama maju 1,25 + 1,25 / 2), lalu posisi vertikal, jenis, jangkau, dan status kotak ditulis literal.

const FOLDER: String = "res://assets/data/routes/perumahan"
## Pusat kotak surat dari awal kavling, ubin (BALANCING 5: maju 1,25, panjang 1,25), dihitung tangan.
const PUSAT_KOTAK: float = 1.875

var _cek: Callable
var _judul: Callable


func _init(cek: Callable, judul: Callable) -> void:
	_cek = cek
	_judul = judul


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_test_config()
	_test_geometri_kotak_surat()
	_test_vertikal_literal()
	_test_tepi_jangkauan()
	_test_jangkau()
	_test_jenis_dan_tenggat()
	_test_terantar_dan_bantu()
	_test_strip_ikut_sisi_dunia()
	_test_y_penanda_px()
	_test_rute_nyata()
	_test_progres_literal()
	_test_progres_selesai_dan_terkirim()


## Rumah buatan dengan pusat kotak surat di `pusat` (ubin dari awal rute).
func _rumah(id: String, pusat: float, sisi: LoperAnim.Sisi, pelanggan: bool, tip: bool = false) -> RouteBuilder.RumahRute:
	var r: RouteBuilder.RumahRute = RouteBuilder.RumahRute.new()
	r.id = id
	r.maju_ubin = pusat - PUSAT_KOTAK
	r.sisi = sisi
	r.pelanggan = pelanggan
	r.pelanggan_boleh = pelanggan
	r.pemberi_tip = tip
	return r


func _rute(rumah: Array[RouteBuilder.RumahRute]) -> RouteBuilder.Rute:
	var rute: RouteBuilder.Rute = RouteBuilder.Rute.new()
	rute.rumah = rumah
	for r: RouteBuilder.RumahRute in rumah:
		if r.pelanggan:
			rute.pelanggan.append(r)
		if r.pemberi_tip:
			rute.id_pemberi_tip[r.id] = true
	rute.panjang_ubin = 240.0
	return rute


## True bila isi `a` dan `b` sama (tipe array boleh berbeda).
func _sama(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i: int in range(a.size()):
		if int(a[i]) != int(b[i]):
			return false
	return true


func _cari(daftar: Array[RadarRute.Penanda], id: String) -> RadarRute.Penanda:
	for p: RadarRute.Penanda in daftar:
		if p.id_rumah == id:
			return p
	return null


func _test_config() -> void:
	_judul.call("Radar: angka Config literal (K-2, DESIGN_SPEC 3.4)")
	check(Config.RADAR_JANGKAUAN_UBIN == 30.0, "jangkauan radar 30 ubin (K-2)")
	check(Config.RADAR_TEPI_PX == 4 and Config.RADAR_LEBAR_PX == 12 and Config.RADAR_Y_ATAS_PX == 10 and Config.RADAR_Y_BAWAH_PX == 182, "strip x 4 dari tepi, lebar 12, y 10 sampai 182")
	check(Config.RADAR_PENANDA_LEBAR_PX == 8 and Config.RADAR_PENANDA_TINGGI_PX == 6 and Config.RADAR_JANGKAU_TAMBAH_PX == 2 and Config.RADAR_JALUR_PAD_PX == 2, "penanda 8x6, jangkau +2 (10x8), jalur penanda 2 px dari ujung strip (R-3: tanpa bingkai)")
	check(Config.LEMPAR_JARAK_MAKS_UBIN == 5.0 and Config.HUD_PROGRES_TERLEWAT_UBIN == 3.0, "jangkau = jarak lempar maksimum 5,0; terlewat 3,0 ubin di belakang")
	for jenis: String in ["pelanggan", "tip", "bukan"]:
		for akhiran: String in ["", "_jangkau"]:
			var jalur: String = "res://assets/sprites/ui/ui_radar_%s%s.png" % [jenis, akhiran]
			var t: Texture2D = load(jalur) as Texture2D
			var ukuran: Vector2 = Vector2(10, 8) if akhiran != "" else Vector2(8, 6)
			check(t != null and t.get_size() == ukuran, "%s ada, %s" % [jalur, ukuran])
	check(not ResourceLoader.exists("res://assets/sprites/ui/ui_radar_strip_9slice.png"), "R-3: bingkai strip radar 9-slice tidak dipasang lagi (strip tanpa latar gelap)")


func _test_geometri_kotak_surat() -> void:
	_judul.call("Radar: jarak rumah = pusat zona kotak surat (sama dengan zona penilaian)")
	for sisi: LoperAnim.Sisi in [LoperAnim.Sisi.SEBERANG, LoperAnim.Sisi.DEKAT]:
		var r: RouteBuilder.RumahRute = _rumah("g@1", 20.0, sisi, true)
		check(is_equal_approx(ZonaSasaran.maju_kotak_surat(r), 20.0), "sisi %s: kavling 18,125 -> pusat kotak surat 20,0" % LoperAnim.Sisi.keys()[sisi])
		var zona: Array[ZonaSasaran.Zona] = ZonaSasaran.zona_rumah(r)
		check(zona[0].jenis == ZonaSasaran.Jenis.KOTAK_SURAT and is_equal_approx(zona[0].persegi.get_center().y, 20.0), "sisi %s: sama dengan pusat zona KOTAK_SURAT penilaian" % LoperAnim.Sisi.keys()[sisi])
		check(is_equal_approx(RadarRute.jarak(r, 12.5), 7.5) and is_equal_approx(RadarRute.jarak(r, 25.0), -5.0), "jarak dari sepeda 12,5 = 7,5; dari 25 = -5 (di belakang)")


func _test_vertikal_literal() -> void:
	_judul.call("Radar posisi vertikal (AC-4): 0 = atas (30 ubin), 1 = bawah (di samping sepeda); oracle literal")
	var tabel: Array = [[30.0, 0.0], [24.0, 0.2], [15.0, 0.5], [6.0, 0.8], [3.0, 0.9], [0.0, 1.0]]
	for baris: Array in tabel:
		check(is_equal_approx(RadarRute.vertikal(baris[0]), baris[1]), "jarak %s -> vertikal %s (dapat %s)" % [baris[0], baris[1], RadarRute.vertikal(baris[0])])
	var rute: RouteBuilder.Rute = _rute([_rumah("v@1", 110.0, LoperAnim.Sisi.SEBERANG, true), _rumah("v@2", 124.0, LoperAnim.Sisi.SEBERANG, true), _rumah("v@3", 130.0, LoperAnim.Sisi.SEBERANG, true)] as Array[RouteBuilder.RumahRute])
	var p: Array[RadarRute.Penanda] = RadarRute.penanda(rute, 100.0, {}, false, false)
	check(p.size() == 3, "sepeda di 100: tiga pelanggan di 10, 24, 30 ubin tampil")
	if p.size() == 3:
		check(is_equal_approx(p[0].vertikal, 2.0 / 3.0) and is_equal_approx(p[1].vertikal, 0.2) and is_equal_approx(p[2].vertikal, 0.0), "vertikal 0,6667 / 0,2 / 0,0")
	# Rumah mendekat -> penanda turun (vertikal naik).
	var naik: bool = true
	var lama: float = -1.0
	for maju: float in [100.0, 105.0, 108.0, 109.5, 110.0]:
		var v: float = _cari(RadarRute.penanda(rute, maju, {}, false, false), "v@1").vertikal
		naik = naik and v > lama
		lama = v
	check(naik and lama == 1.0, "sepeda maju 100 -> 110: penanda v@1 turun terus sampai bawah strip (1,0)")


func _test_tepi_jangkauan() -> void:
	_judul.call("Radar tepi jangkauan (AC-4): 0 dan 30 INKLUSIF; sedikit di belakang atau di atas 30 tidak tampil")
	var rute: RouteBuilder.Rute = _rute([_rumah("t@0", 50.0, LoperAnim.Sisi.SEBERANG, true), _rumah("t@30", 80.0, LoperAnim.Sisi.SEBERANG, true), _rumah("t@luar", 80.01, LoperAnim.Sisi.SEBERANG, true), _rumah("t@blk", 49.99, LoperAnim.Sisi.SEBERANG, true)] as Array[RouteBuilder.RumahRute])
	var p: Array[RadarRute.Penanda] = RadarRute.penanda(rute, 50.0, {}, false, false)
	check(_cari(p, "t@0") != null and _cari(p, "t@0").vertikal == 1.0, "jarak 0 (tepat di samping sepeda): tampil di bawah strip")
	check(_cari(p, "t@30") != null and _cari(p, "t@30").vertikal == 0.0, "jarak 30,0: tampil di atas strip")
	check(_cari(p, "t@luar") == null, "jarak 30,01: tidak tampil")
	check(_cari(p, "t@blk") == null, "jarak -0,01 (sudah di belakang): tidak tampil")
	check(RadarRute.dalam_radar(0.0) and RadarRute.dalam_radar(30.0) and not RadarRute.dalam_radar(30.000001) and not RadarRute.dalam_radar(-0.000001) and not RadarRute.dalam_radar(NAN), "dalam_radar: [0; 30] inklusif, NaN tidak")


func _test_jangkau() -> void:
	_judul.call("Radar jangkau (O-10): pelanggan dengan 0 <= jarak <= 5,0 (inklusif); bukan pelanggan tidak pernah jangkau")
	var rute: RouteBuilder.Rute = _rute([_rumah("j@5", 15.0, LoperAnim.Sisi.SEBERANG, true), _rumah("j@luar", 15.001, LoperAnim.Sisi.SEBERANG, true, true), _rumah("j@0", 10.0, LoperAnim.Sisi.SEBERANG, true, true), _rumah("j@bukan", 12.0, LoperAnim.Sisi.SEBERANG, false), _rumah("j@dekat", 13.0, LoperAnim.Sisi.DEKAT, false)] as Array[RouteBuilder.RumahRute])
	var p: Array[RadarRute.Penanda] = RadarRute.penanda(rute, 10.0, {}, true, false)
	check(_cari(p, "j@5").jangkau, "jarak tepat 5,0: jangkau")
	check(not _cari(p, "j@luar").jangkau and _cari(p, "j@luar").jenis == RadarRute.Jenis.TIP, "jarak 5,001: tidak jangkau (tetap tip)")
	check(_cari(p, "j@0").jangkau and _cari(p, "j@0").jenis == RadarRute.Jenis.TIP, "jarak 0, pemberi tip: jangkau, jenis tip tetap (warna jenis tetap)")
	check(not _cari(p, "j@bukan").jangkau and _cari(p, "j@bukan").jenis == RadarRute.Jenis.BUKAN, "bukan pelanggan di 2 ubin (mode bantu): tampil BUKAN, tidak jangkau")
	check(not _cari(p, "j@dekat").jangkau, "rumah dekat bukan pelanggan di 3 ubin: tidak jangkau")
	check(RadarRute.dalam_jangkauan_lempar(5.0) and not RadarRute.dalam_jangkauan_lempar(5.000001) and RadarRute.dalam_jangkauan_lempar(0.0) and not RadarRute.dalam_jangkauan_lempar(-0.000001), "jangkauan lempar [0; 5] inklusif")


func _test_jenis_dan_tenggat() -> void:
	_judul.call("Radar jenis (O-9): pelanggan, tip, bukan; tip menjadi pelanggan biasa sesudah tenggat lewat")
	var rute: RouteBuilder.Rute = _rute([_rumah("k@p", 20.0, LoperAnim.Sisi.SEBERANG, true), _rumah("k@t", 22.0, LoperAnim.Sisi.SEBERANG, true, true), _rumah("k@b", 24.0, LoperAnim.Sisi.SEBERANG, false)] as Array[RouteBuilder.RumahRute])
	var sebelum: Array[RadarRute.Penanda] = RadarRute.penanda(rute, 10.0, {}, true, false)
	check(_cari(sebelum, "k@p").jenis == RadarRute.Jenis.PELANGGAN and _cari(sebelum, "k@t").jenis == RadarRute.Jenis.TIP and _cari(sebelum, "k@b").jenis == RadarRute.Jenis.BUKAN, "sebelum tenggat: pelanggan, tip, bukan")
	var sesudah: Array[RadarRute.Penanda] = RadarRute.penanda(rute, 10.0, {}, true, true)
	check(_cari(sesudah, "k@t").jenis == RadarRute.Jenis.PELANGGAN and _cari(sesudah, "k@p").jenis == RadarRute.Jenis.PELANGGAN and _cari(sesudah, "k@b").jenis == RadarRute.Jenis.BUKAN, "sesudah tenggat: pemberi tip tampil PELANGGAN; bukan tetap BUKAN")


func _test_terantar_dan_bantu() -> void:
	_judul.call("Radar: terantar keluar dari radar; bukan pelanggan hanya di mode bantu (AC-4, AC-6), sakelar langsung berlaku")
	var rute: RouteBuilder.Rute = _rute([_rumah("b@1", 20.0, LoperAnim.Sisi.SEBERANG, true), _rumah("b@2", 22.0, LoperAnim.Sisi.SEBERANG, false), _rumah("b@3", 23.0, LoperAnim.Sisi.DEKAT, false), _rumah("b@4", 25.0, LoperAnim.Sisi.SEBERANG, true)] as Array[RouteBuilder.RumahRute])
	var mati: Array[RadarRute.Penanda] = RadarRute.penanda(rute, 10.0, {}, false, false)
	check(mati.size() == 2 and _cari(mati, "b@1") != null and _cari(mati, "b@4") != null, "mode bantu mati: hanya dua pelanggan, tanpa rumah bukan pelanggan")
	var nyala: Array[RadarRute.Penanda] = RadarRute.penanda(rute, 10.0, {}, true, false)
	check(nyala.size() == 4 and _cari(nyala, "b@2").jenis == RadarRute.Jenis.BUKAN and _cari(nyala, "b@3").jenis == RadarRute.Jenis.BUKAN, "mode bantu nyala: rumah bukan pelanggan seberang dan dekat tampil BUKAN")
	var terantar: Array[RadarRute.Penanda] = RadarRute.penanda(rute, 10.0, {"b@1": true}, false, false)
	check(terantar.size() == 1 and _cari(terantar, "b@1") == null and _cari(terantar, "b@4") != null, "b@1 terantar: keluar dari radar, b@4 tetap")
	check(RadarRute.penanda(null, 10.0, {}, true, false).is_empty() and RadarRute.penanda(rute, NAN, {}, true, false).is_empty(), "rute null atau sepeda NaN: kosong")


func _test_strip_ikut_sisi_dunia() -> void:
	_judul.call("Radar: strip = sisi dunia (seberang kiri, dekat kanan); kidal tidak menukar (tidak ada masukan kidal)")
	var rute: RouteBuilder.Rute = _rute([_rumah("s@seb", 20.0, LoperAnim.Sisi.SEBERANG, true), _rumah("s@dek", 20.0, LoperAnim.Sisi.DEKAT, true)] as Array[RouteBuilder.RumahRute])
	var p: Array[RadarRute.Penanda] = RadarRute.penanda(rute, 10.0, {}, false, false)
	check(_cari(p, "s@seb").sisi == LoperAnim.Sisi.SEBERANG and _cari(p, "s@dek").sisi == LoperAnim.Sisi.DEKAT, "penanda membawa sisi dunia rumahnya")


func _test_y_penanda_px() -> void:
	_judul.call("Radar: tepi atas penanda di jalur strip (piksel), oracle literal")
	# Jalur = 172 - 2 x 2 = 168 px; penanda 6 -> ruang 162.
	var tabel: Array = [[0.0, 0], [0.5, 81], [1.0, 162], [0.25, 41], [-1.0, 0], [2.0, 162]]
	for baris: Array in tabel:
		check(RadarRute.y_penanda_px(baris[0], 168, 6) == baris[1], "vertikal %s -> y %d (dapat %d)" % [baris[0], baris[1], RadarRute.y_penanda_px(baris[0], 168, 6)])
	check(RadarRute.y_penanda_px(1.0, 168, 8) == 160, "penanda jangkau 8 tinggi: bawah = 160")


func _test_rute_nyata() -> void:
	_judul.call("Radar di rute nyata: awal rute, pelanggan dalam 30 ubin, tip dan bukan sesuai data")
	var rute: RouteBuilder.Rute = RouteBuilder.bangun(Config.RUTE_SEED_DEV, PemuatRute.muat_folder(FOLDER).segmen).rute
	if rute == null:
		check(false, "rute seed dev dibangun")
		return
	var p: Array[RadarRute.Penanda] = RadarRute.penanda(rute, 0.0, {}, false, false)
	var harap: int = 0
	for r: RouteBuilder.RumahRute in rute.pelanggan:
		var pusat: float = r.maju_ubin + PUSAT_KOTAK
		if pusat >= 0.0 and pusat <= 30.0:
			harap += 1
	check(p.size() == harap and harap > 0, "awal rute: %d pelanggan dalam 30 ubin tampil (dapat %d)" % [harap, p.size()])
	var semua_seberang: bool = true
	for q: RadarRute.Penanda in p:
		semua_seberang = semua_seberang and q.sisi == LoperAnim.Sisi.SEBERANG
	check(semua_seberang, "perumahan: semua pelanggan di strip seberang (distrik satu sisi)")
	var bantu: Array[RadarRute.Penanda] = RadarRute.penanda(rute, 0.0, {}, true, false)
	var ada_dekat: bool = false
	for q: RadarRute.Penanda in bantu:
		ada_dekat = ada_dekat or (q.sisi == LoperAnim.Sisi.DEKAT and q.jenis == RadarRute.Jenis.BUKAN)
	check(bantu.size() > p.size() and ada_dekat, "mode bantu: rumah bukan pelanggan (termasuk sisi dekat) ikut tampil")


func _test_progres_literal() -> void:
	_judul.call("Progres kotak (AC-7, O-12): terkirim, terlewat (> 3,0 di belakang), berikutnya (terdekat di depan), belum; oracle literal")
	var rute: RouteBuilder.Rute = _rute([_rumah("p@5", 5.0, LoperAnim.Sisi.SEBERANG, true), _rumah("p@10", 10.0, LoperAnim.Sisi.SEBERANG, true), _rumah("p@20", 20.0, LoperAnim.Sisi.SEBERANG, true), _rumah("p@40", 40.0, LoperAnim.Sisi.SEBERANG, true), _rumah("x@15", 15.0, LoperAnim.Sisi.SEBERANG, false)] as Array[RouteBuilder.RumahRute])
	var belum: ProgresRute.Status = ProgresRute.Status.BELUM
	var kirim: ProgresRute.Status = ProgresRute.Status.TERKIRIM
	var lewat: ProgresRute.Status = ProgresRute.Status.TERLEWAT
	var lanjut: ProgresRute.Status = ProgresRute.Status.BERIKUTNYA
	var kasus: Array = [
		["awal, sepeda 0", 0.0, {}, [lanjut, belum, belum, belum]],
		["p@5 terantar", 0.0, {"p@5": true}, [kirim, lanjut, belum, belum]],
		["sepeda 6 (p@5 1 ubin di belakang, belum terantar)", 6.0, {}, [belum, lanjut, belum, belum]],
		["sepeda 8 (p@5 tepat 3,0 di belakang)", 8.0, {}, [belum, lanjut, belum, belum]],
		["sepeda 8,01 (p@5 lebih dari 3,0 di belakang)", 8.01, {}, [lewat, lanjut, belum, belum]],
		["sepeda tepat di p@10 (jarak 0 = di depan)", 10.0, {"p@5": true}, [kirim, lanjut, belum, belum]],
		["sepeda 10,5: berikutnya pindah ke p@20", 10.5, {"p@5": true}, [kirim, belum, lanjut, belum]],
		["sepeda 30, p@20 terantar", 30.0, {"p@5": true, "p@20": true}, [kirim, lewat, kirim, lanjut]],
		["sepeda 50, semua lewat", 50.0, {"p@20": true}, [lewat, lewat, kirim, lewat]],
	]
	for c: Array in kasus:
		var dapat: Array[ProgresRute.Status] = ProgresRute.status(rute, c[1], c[2], false)
		check(_sama(dapat, c[3]), "%s: %s (dapat %s)" % [c[0], c[3], dapat])
	check(ProgresRute.status(rute, 0.0, {}, false).size() == 4, "satu kotak per pelanggan (rumah bukan pelanggan tidak dihitung)")
	var hitung_n: int = 0
	for s: ProgresRute.Status in ProgresRute.status(rute, 0.0, {}, false):
		if s == lanjut:
			hitung_n += 1
	check(hitung_n == 1, "tepat satu kotak berikutnya")


func _test_progres_selesai_dan_terkirim() -> void:
	_judul.call("Progres sesudah rute selesai: sisa terlewat, tanpa berikutnya; jumlah terkirim")
	var rute: RouteBuilder.Rute = _rute([_rumah("q@5", 5.0, LoperAnim.Sisi.SEBERANG, true), _rumah("q@10", 10.0, LoperAnim.Sisi.SEBERANG, true), _rumah("q@20", 20.0, LoperAnim.Sisi.SEBERANG, true)] as Array[RouteBuilder.RumahRute])
	var lewat: ProgresRute.Status = ProgresRute.Status.TERLEWAT
	var kirim: ProgresRute.Status = ProgresRute.Status.TERKIRIM
	check(_sama(ProgresRute.status(rute, 0.0, {"q@10": true}, true), [lewat, kirim, lewat]), "selesai: belum terantar = terlewat, tanpa berikutnya")
	check(ProgresRute.jumlah_terkirim(rute, {"q@10": true, "q@20": true, "lain@1": true}) == 2, "terkirim = pelanggan rute yang terantar (id lain tidak dihitung): 2")
	check(ProgresRute.jumlah_terkirim(null, {"q@10": true}) == 0 and ProgresRute.status(null, 0.0, {}, false).is_empty(), "rute null: 0 dan kosong")
