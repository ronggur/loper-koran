extends SceneTree
## Probe reputasi, pelanggan, dan milestone di jendela asli, non-headless (AC-14 dan AC-16 run fase6a2-reputasi-pelanggan bagian C): memotret HUD rute dengan penanda reputasi (kanan, kidal, inset aman,
## koin bersih negatif dan umpan "-5" dari lemparan nyata) dan layar hasil (hari biasa, hari minus karena potongan, pelanggan berhenti/kembali/setia, milestone baru tercapai, semua emas, kasus terpadat:
## potongan + rekap misi + tiga baris kondisi + saldo dijepit + reputasi + empat baris pelanggan + milestone + tiga tingkat baru + tenggat lewat, dan hasil dari rute nyata dengan state save).
## Mencetak data tiap keadaan dan jumlah keadaan yang tidak sesuai (penanda reputasi di luar layar atau menumpuk elemen HUD lain, panel hasil atau isinya keluar layar atau zona aman, tombol < 42 px,
## label menumpuk tombol). Tidak interaktif: keluar lewat `ProbeKeluar`. Tidak menulis save apa pun.
##
## Pakai (jendela harus muat di layar monitor):
##   godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_reputasi_jendela.gd -- docs/loop/<RUN_ID>/shots/iter<N>
##   (juga 1920x1080, 2400x1080, 1600x720)
## Berkas: `<lebar>x<tinggi>_reputasi_<keadaan>.png`.

const BERKAS_RUTE: String = "res://scenes/rute/rute.tscn"
const BERKAS_HASIL: String = "res://scenes/ui/layar_hasil.tscn"
const FRAME_TUNGGU_LAYOUT: int = 5
const DT: float = 1.0 / 60.0
const LEBAR_LEMPAR: float = 780.0
const TITIK_MELESET: Vector2 = Vector2(-0.5, 10.5)

var _folder: String = ""
var _awalan: String = ""
var _akar: RuteMain
var _sepeda: SepedaUji
var _hud: HudRute
var _sprite: LoperSprite
var _debu: PancaranPiksel
var _garis: PancaranPiksel
var _toko: PemuatToko.Kumpulan = PemuatToko.muat()
var _kepribadian: Array[KepribadianPelanggan.Entri] = PemuatPelanggan.muat().entri
var _gagal: int = 0


func _initialize() -> void:
	var argumen: PackedStringArray = OS.get_cmdline_user_args()
	_folder = argumen[0] if argumen.size() > 0 else ""
	await _hud_reputasi()
	await _hud_potongan()
	await _hud_kidal_dan_inset()
	await _hasil_kasus()
	await _hasil_dari_rute()
	await _hasil_inset()
	print("probe selesai, %d keadaan tidak sesuai" % _gagal)
	await ProbeKeluar.keluar(self, 0 if _gagal == 0 else 1)


# --- Data buatan ---

func _state(reputasi: int, koin: int = 0) -> Dictionary:
	var s: Dictionary = DataSave.templat()
	s["reputasi"] = {"perumahan": reputasi}
	s["koin"] = koin
	return s


func _angka(terkirim: int, koin: int, terbuang: int, lewat: bool = false) -> HasilRute.Angka:
	var a: HasilRute.Angka = HasilRute.Angka.new()
	a.pelanggan = 25
	a.terkirim = terkirim
	a.meleset = 25 - terkirim
	a.koin = koin
	a.koin_tip = 25 if terkirim > 10 else 0
	a.jumlah_tip = 1 if terkirim > 10 else 0
	a.skor = 1000 + terkirim * 600
	a.jumlah_tepat = terkirim / 4
	a.lempar_terbuang = terbuang
	a.potongan = terbuang * Config.KOIN_POTONGAN_KORAN_MELESET
	a.tenggat_lewat = lewat
	a.detik_lewat = 72 if lewat else 0
	return a


## `ReputationManager.Hasil` buatan: reputasi `sebelum` -> `sesudah` dan jumlah peristiwa per jenis [baru, setia, berhenti, kembali].
func _rep(sebelum: int, sesudah: int, jumlah: Array) -> ReputationManager.Hasil:
	var h: ReputationManager.Hasil = ReputationManager.Hasil.new()
	h.reputasi_sebelum = sebelum
	h.reputasi_sesudah = sesudah
	h.perubahan = sesudah - sebelum
	var jenis: Array = [ReputationManager.Jenis.BARU, ReputationManager.Jenis.SETIA, ReputationManager.Jenis.BERHENTI, ReputationManager.Jenis.KEMBALI]
	for i: int in range(4):
		for n: int in range(int(jumlah[i])):
			var p: ReputationManager.Peristiwa = ReputationManager.Peristiwa.new()
			p.jenis = jenis[i]
			p.id_rumah = "x@%d" % n
			h.peristiwa.append(p)
	return h


## State save dengan nilai milestone: setia, koin_total, misi selesai, servis, level ban.
func _ms_state(setia: int, koin_total: int, misi: int, servis: int, level: int) -> Dictionary:
	var s: Dictionary = DataSave.templat()
	var pelanggan: Dictionary = {}
	for i: int in range(setia):
		pelanggan["s@%d" % i] = {"status": "setia", "antar": 5, "meleset": 0, "hari_berhenti": 0}
	s["pelanggan"] = pelanggan
	s["koin_total"] = koin_total
	var riwayat: Dictionary = {}
	for i: int in range(misi):
		riwayat["m%d" % i] = {"hasil": "selesai", "hari": i + 1}
	s["misi_hasil"] = riwayat
	s["sepeda"]["servis_total"] = servis
	s["sepeda"]["ban"]["level"] = level
	return s


# --- Skenario HUD ---

func _hud_reputasi() -> void:
	await _pasang(_state(37), 1)
	await _maju(0.3)
	await _foto("hud_reputasi")
	_harap("penanda reputasi tampil dengan angka 37", _hud.reputasi_tampil() and _hud.teks_reputasi() == "37", _hud.teks_reputasi())
	_cek_hud("hud_reputasi")
	_akar.queue_free()
	await _tunggu(2)
	await _pasang(_state(100), 1)
	await _foto("hud_reputasi_seratus")
	_harap("reputasi 100 tampil penuh", _hud.teks_reputasi() == "100", _hud.teks_reputasi())
	_cek_hud("hud_reputasi_seratus")
	_akar.queue_free()
	await _tunggu(2)


## Hari dengan koran terbuang: HUD koin bersih negatif (tanda minus eksplisit) dan umpan "-5" di titik mendarat, penanda reputasi tetap terbaca.
func _hud_potongan() -> void:
	await _pasang(_state(12), 1)
	var mendarat: Array[KoranLempar.Koran] = []
	_akar.koran_mendarat.connect(func(k: KoranLempar.Koran) -> void: mendarat.append(k))
	for i: int in range(3):
		await _lempar_ke_titik(4.0, TITIK_MELESET, mendarat)
		await _maju(1.1)
	await _lempar_ke_titik(4.0, TITIK_MELESET, mendarat)
	await _maju(0.15)
	await _foto("hud_koin_negatif_umpan")
	_harap("HUD koin bersih -20 sesudah empat koran terbuang", _hud.teks_koin() == "-20", _hud.teks_koin())
	_cek_hud("hud_koin_negatif_umpan")
	_akar.queue_free()
	await _tunggu(2)


func _hud_kidal_dan_inset() -> void:
	await _pasang(_state(58), 1)
	_akar.atur_kidal(true)
	await _maju(0.2)
	await _foto("hud_kidal")
	_cek_hud("hud_kidal")
	_akar.atur_kidal(false)
	var inset: ZonaAman.Inset = ZonaAman.Inset.new()
	inset.awal_x = 20
	inset.akhir_x = 24
	inset.atas = 16
	inset.bawah = 18
	_hud.atur_inset(inset)
	await _maju(0.2)
	await _foto("hud_inset_aman")
	var layar: Rect2 = Rect2(Vector2.ZERO, root.get_visible_rect().size)
	var panel: Rect2 = _hud.rect_panel_reputasi()
	_harap("inset: penanda reputasi di dalam zona aman", panel.end.x <= layar.end.x - 24.0 and panel.position.y >= 16.0, str(panel))
	_cek_hud("hud_inset_aman")
	_akar.queue_free()
	await _tunggu(2)


# --- Skenario layar hasil ---

func _hasil_kasus() -> void:
	var misi: DataMisi = PemuatMisi.muat_folder().cari("p1_kucing")
	var kasus: Array = [
		# nama, angka, misi, perlu bengkel, saldo lama, reputasi, state sebelum, state sesudah
		["hasil_hari_biasa", _angka(22, 380, 1), null, [], 120, _rep(10, 12, [3, 0, 0, 0]), _ms_state(1, 700, 0, 0, 0), _ms_state(1, 1080, 0, 0, 0)],
		["hasil_hari_minus", _angka(2, 30, 25), null, [], 12, _rep(12, 12, [0, 0, 0, 0]), _ms_state(1, 700, 0, 0, 0), _ms_state(1, 730, 0, 0, 0)],
		["hasil_berhenti_kembali_setia", _angka(18, 270, 2), null, [], 80, _rep(30, 29, [2, 1, 1, 1]), _ms_state(2, 1500, 1, 0, 0), _ms_state(2, 1770, 1, 0, 0)],
		["hasil_milestone_baru", _angka(24, 420, 0), misi, [], 200, _rep(40, 43, [1, 2, 0, 0]), _ms_state(2, 4800, 2, 3, 0), _ms_state(3, 5220, 3, 4, 0)],
		["hasil_semua_emas", _angka(25, 500, 0), null, [], 300, _rep(90, 92, [0, 0, 0, 0]), _ms_state(25, 20000, 5, 10, 0), _ms_state(25, 20500, 5, 10, 0)],
		["hasil_terpadat", _angka(2, 150, 25, true), misi, ["ban", "rem", "rantai"], 10, _rep(55, 53, [4, 3, 2, 1]), _ms_state(2, 990, 0, 0, 0), _ms_state(10, 5100, 1, 4, 0)],
	]
	for k: Array in kasus:
		var layar: LayarHasil = (load(BERKAS_HASIL) as PackedScene).instantiate() as LayarHasil
		root.add_child(layar)
		await _tunggu(2)
		var angka: HasilRute.Angka = k[1]
		if k[0] == "hasil_terpadat":
			angka.misi_hasil = "selesai"
			angka.koin_misi = 75
		var daftar_perlu: Array[String] = []
		for id: Variant in k[3]:
			daftar_perlu.append(str(id))
		layar.atur_mode_hari(true)
		layar.isi(angka, k[2], daftar_perlu, int(k[4]), k[5], MilestoneTracker.ringkas(k[6], k[7]))
		layar.tampilkan(true)
		await _tunggu(5)
		_awalan = "%dx%d" % [root.size.x, root.size.y]
		await _simpan(k[0])
		_cek_hasil(k[0], layar, Vector4.ZERO)
		layar.queue_free()
		await _tunggu(2)


## Layar hasil dari rute nyata dengan state save (reputasi, pelanggan, milestone dihitung `RuteMain`).
func _hasil_dari_rute() -> void:
	var s: Dictionary = _state(20, 150)
	s["koin_total"] = 940
	await _pasang(s, 3)
	_akar.atur_mode_hari(true)
	await _selesaikan()
	await _foto("hasil_dari_rute")
	var rep: ReputationManager.Hasil = _akar.hasil_reputasi()
	var ms: MilestoneTracker.Ringkasan = _akar.hasil_milestone()
	_harap("rute nyata: hasil reputasi dan milestone terisi, kolom kanan tampil", rep != null and ms != null and _akar.layar_hasil().kanan_tampil(), "")
	print("hasil dari rute: reputasi %s, pelanggan %s, target %s, baru %s" % [_akar.layar_hasil().teks_reputasi(), _akar.layar_hasil().teks_pelanggan(), _akar.layar_hasil().teks_target(), _akar.layar_hasil().teks_baru()])
	_cek_hasil("hasil_dari_rute", _akar.layar_hasil(), Vector4.ZERO)
	_akar.queue_free()
	await _tunggu(2)


## Layar hasil kasus terpadat dengan inset aman tiruan: panel dan tombol tetap di dalam zona aman (layar hasil dipusatkan, jadi harus muat di layar dikurangi inset).
func _hasil_inset() -> void:
	var misi: DataMisi = PemuatMisi.muat_folder().cari("p1_kucing")
	var layar: LayarHasil = (load(BERKAS_HASIL) as PackedScene).instantiate() as LayarHasil
	root.add_child(layar)
	await _tunggu(2)
	var angka: HasilRute.Angka = _angka(2, 150, 25, true)
	angka.misi_hasil = "selesai"
	angka.koin_misi = 75
	layar.atur_mode_hari(true)
	layar.isi(angka, misi, ["ban", "rem", "rantai"] as Array[String], 10, _rep(55, 53, [4, 3, 2, 1]), MilestoneTracker.ringkas(_ms_state(2, 990, 0, 0, 0), _ms_state(10, 5100, 1, 4, 0)))
	layar.tampilkan(true)
	await _tunggu(5)
	_awalan = "%dx%d" % [root.size.x, root.size.y]
	await _simpan("hasil_terpadat_inset")
	_cek_hasil("hasil_terpadat_inset", layar, Vector4(20, 16, 24, 18))
	layar.queue_free()
	await _tunggu(2)


# --- Pemasangan ---

func _pasang(state: Dictionary, hari: int) -> void:
	_akar = (load(BERKAS_RUTE) as PackedScene).instantiate() as RuteMain
	_akar.atur_hari(hari)
	_akar.atur_sepeda(state, hari, _toko.upgrade)
	_akar.atur_pelanggan(state, _kepribadian)
	root.add_child(_akar)
	await _tunggu(FRAME_TUNGGU_LAYOUT)
	_akar.set_process(false)
	_awalan = "%dx%d" % [root.size.x, root.size.y]
	_sepeda = _akar.find_child("Sepeda", true, false) as SepedaUji
	_hud = _akar.hud_rute()
	(_akar.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = false
	_sprite = _akar.find_child("LoperAgen", true, false) as LoperSprite
	_sprite.set_process(false)
	_debu = _sepeda.umpan_balik().debu()
	_garis = _sepeda.umpan_balik().garis()
	_debu.set_process(false)
	_garis.set_process(false)
	_akar.set(&"_rintangan", RintanganRute.Keadaan.new())
	_letakkan(0.0, 0.0)
	_set_kecepatan(Config.KECEPATAN_SANTAI_UD)
	_akar.atur_kondisi(KondisiRute.awal(Economy.kondisi_dari(state), Economy.level_dari(state), hari, _toko.upgrade))
	_akar.perbarui(0.0)


# --- Pemeriksaan ---

func _harap(nama: String, kondisi: bool, rincian: String) -> void:
	if not kondisi:
		print("TIDAK SESUAI: %s (%s)" % [nama, rincian])
		_gagal += 1


## Penanda reputasi di dalam layar dan tidak menumpuk elemen HUD lain: radar, panel progres, koin, skor, kondisi, tombol jeda, zona bel, panel kecepatan, panel koran, zona stick, kartu misi, banner, petunjuk.
func _cek_hud(keadaan: String) -> void:
	var layar: Rect2 = Rect2(Vector2.ZERO, root.get_visible_rect().size)
	var panel: Rect2 = _hud.rect_panel_reputasi()
	var lebar: int = roundi(layar.size.x)
	var pusat_bel: Vector2 = TouchZones.pusat_bel(lebar, _akar.kidal(), _akar.kontrol_router().geser_bel)
	var lain: Dictionary = {
		"radar_seberang": _hud.rect_radar_seberang(), "radar_dekat": _hud.rect_radar_dekat(), "panel_progres": _hud.rect_panel_progres(), "panel_koin": _hud.rect_panel_koin(),
		"panel_skor": _hud.rect_panel_skor(), "panel_kondisi": _hud.rect_panel_kondisi(), "tombol_jeda": _hud.rect_tombol_jeda(), "zona_bel": Rect2(pusat_bel - Vector2(28, 28), Vector2(56, 56)),
		"panel_kecepatan": _hud.rect_panel_kecepatan(), "panel_koran": _hud.rect_panel_koran(), "zona_stick": TouchZones.rect_stick(lebar, _akar.kidal()),
		"kartu_misi": Rect2(Vector2(Config.MISI_KARTU_X_PX, Config.MISI_KARTU_Y_PX), Vector2(Config.MISI_KARTU_LEBAR_PX, 28)),
		"banner_misi": Rect2(Vector2(layar.size.x * 0.5 - 120.0, Config.MISI_BANNER_Y_PX), Vector2(240, 26)),
	}
	var salah: int = 0
	if not layar.encloses(panel):
		print("TIDAK SESUAI [%s]: penanda reputasi %s di luar layar %s" % [keadaan, panel, layar])
		salah += 1
	for nama: String in lain:
		if panel.intersects(lain[nama]):
			print("TIDAK SESUAI [%s]: penanda reputasi %s menumpuk %s %s" % [keadaan, panel, nama, lain[nama]])
			salah += 1
	print("tata letak [%s]: penanda reputasi %s, panel kondisi %s, %d tidak sesuai" % [keadaan, panel, _hud.rect_panel_kondisi(), salah])
	_gagal += salah


## Panel hasil dan isinya di dalam layar dikurangi `inset` (kiri, atas, kanan, bawah), tombol >= 42 px dan terlihat penuh, label dan isi kolom kanan di dalam panel dan tidak menumpuk tombol atau satu sama lain.
func _cek_hasil(keadaan: String, hasil: LayarHasil, inset: Vector4) -> void:
	var layar: Rect2 = Rect2(Vector2(inset.x, inset.y), root.get_visible_rect().size - Vector2(inset.x + inset.z, inset.y + inset.w))
	var salah: int = 0
	var panel: Rect2 = hasil.rect_panel()
	var tombol: Rect2 = hasil.rect_tombol()
	if not layar.encloses(panel) or not layar.encloses(tombol):
		print("TIDAK SESUAI [%s]: panel hasil %s atau tombol %s di luar zona aman %s" % [keadaan, panel, tombol, layar])
		salah += 1
	if tombol.size.y < float(Config.HUD_TOMBOL_TINGGI_PX) or not panel.encloses(tombol):
		print("TIDAK SESUAI [%s]: tombol %s kurang dari 42 px atau keluar panel" % [keadaan, tombol])
		salah += 1
	var semua: Array[Rect2] = hasil.rect_label()
	semua.append_array(hasil.rect_isi_kanan())
	for r: Rect2 in semua:
		if not panel.encloses(r):
			print("TIDAK SESUAI [%s]: isi %s keluar dari panel %s" % [keadaan, r, panel])
			salah += 1
		if r.intersects(tombol):
			print("TIDAK SESUAI [%s]: isi %s menumpuk tombol %s" % [keadaan, r, tombol])
			salah += 1
	if hasil.kanan_tampil():
		var kanan: Rect2 = hasil.rect_panel_kanan()
		for r: Rect2 in hasil.rect_isi_kanan():
			if not kanan.encloses(r):
				print("TIDAK SESUAI [%s]: isi kolom kanan %s keluar dari panel kanan %s" % [keadaan, r, kanan])
				salah += 1
	print("hasil [%s]: panel %s, tombol %s (%s), reputasi %s, pelanggan %s, target %s, baru %s, %d tidak sesuai" % [keadaan, panel, tombol, hasil.teks_tombol(), hasil.teks_reputasi(), hasil.teks_pelanggan(), hasil.teks_target(), hasil.teks_baru(), salah])
	print("teks layar hasil: %s" % [" | ".join(hasil.teks_tampil())])
	_gagal += salah


# --- Gerak ---

func _selesaikan() -> void:
	_letakkan(_akar.rute().panjang_ubin - 1.0, 0.5)
	var batas: int = 0
	while not _akar.hasil_tampil() and batas < 600:
		await _maju(DT, false)
		batas += 1
	await _maju(DT)


func _set_kecepatan(kecepatan: float) -> void:
	var k: BikeMotion.Keadaan = _sepeda.keadaan.salin()
	k.kecepatan_ud = kecepatan
	_sepeda.keadaan = k


func _letakkan(maju: float, lateral: float = 0.5) -> void:
	_sepeda.jarak_ubin = maxf(maju, 0.0)
	var k: BikeMotion.Keadaan = _sepeda.keadaan.salin()
	k.lateral_ubin = lateral
	_sepeda.keadaan = k


## Lemparan ke titik jalan `titik_jalan` dari maju `maju` (lintasan sama dengan swipe nyata, `ThrowSolver`); menunggu koran mendarat.
func _lempar_ke_titik(maju: float, titik_jalan: Vector2, mendarat: Array[KoranLempar.Koran]) -> void:
	_letakkan(maju, 0.5)
	_set_kecepatan(3.0)
	_akar.perbarui(0.0)
	_akar.koran = SisaKoran.awal(30)
	var posisi: Vector2 = _sepeda.posisi_dunia()
	var jeda: float = _sepeda.jeda_lepas(LoperAnim.Sisi.SEBERANG)
	var lepas: Vector2 = ThrowSolver.titik_lepas(posisi, _sepeda.kecepatan_ud, _sepeda.lateral_ud, jeda)
	var sasaran: Vector2 = Vector2(titik_jalan.x, -titik_jalan.y)
	var u: float = BantuLempar.cari_kekuatan(sasaran, lepas, _sepeda.kecepatan_ud)
	if u < 0.0:
		_harap("titik lempar terjangkau dari maju %.1f" % maju, false, str(titik_jalan))
		return
	var lintasan: ThrowSolver.Lintasan = ThrowSolver.hitung(ThrowSolver.panjang_untuk_kekuatan(u, LEBAR_LEMPAR), LEBAR_LEMPAR, BantuLempar.arah_ke(sasaran, lepas, _sepeda.kecepatan_ud, u), posisi, _sepeda.kecepatan_ud, _sepeda.lateral_ud, jeda)
	var sebelum: int = mendarat.size()
	_akar.call(&"_lempar", lintasan, false)
	var batas: int = 0
	while mendarat.size() == sebelum and batas < 200:
		await _maju(DT, false)
		batas += 1


func _tunggu(jumlah: int) -> void:
	for i: int in range(jumlah):
		await process_frame


func _maju(detik: float, gambar: bool = true) -> void:
	for i: int in range(maxi(roundi(detik / DT), 1)):
		if _akar.sedang_jeda():
			_akar.minta_lanjut()
		_akar.perbarui(DT)
		_sprite.maju(DT)
		_debu.maju(DT)
		_garis.maju(DT)
	if gambar:
		await _tunggu(2)


func _foto(keadaan: String) -> void:
	await _tunggu(3)
	print("%s: jarak %.2f, reputasi HUD '%s', koin HUD '%s', kidal %s" % [keadaan, _sepeda.jarak_ubin, _hud.teks_reputasi(), _hud.teks_koin(), _akar.kidal()])
	await _simpan(keadaan)


func _simpan(keadaan: String) -> void:
	if _folder.is_empty():
		return
	var gambar: Image = root.get_texture().get_image()
	var berkas: String = "%s/%s_reputasi_%s.png" % [_folder, _awalan, keadaan]
	var galat: int = gambar.save_png(berkas)
	print("tangkapan layar %dx%d (%s) ke %s (kode %d)" % [gambar.get_width(), gambar.get_height(), keadaan, berkas, galat])
