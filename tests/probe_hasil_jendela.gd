extends SceneTree
## Probe layar hasil struk di jendela asli, non-headless (AC-2, AC-9 run ui2-semua-layar bagian A; kanvas Hasil*.dc.html): memotret semua keadaan papan dari data nyata (`HasilRute.Angka`, `ReputationManager.Hasil`,
## `MilestoneTracker.Ringkasan`): hari biasa, minus (koran terbuang + saldo dijepit + kondisi), semua terkirim (misi selesai), lewat tenggat (misi gagal), pelanggan berhenti/kembali/setia, milestone baru,
## semua emas, kasus terpadat (potongan + misi + tiga kondisi + saldo dijepit + reputasi turun + empat pelanggan + milestone + tiga baru + tenggat), tanpa data reputasi (struk ke tengah, tanpa dan dengan misi),
## inset aman, hasil dari rute nyata, dan mode "Main lagi" (rute sendiri). Mencetak data tiap keadaan dan jumlah keadaan yang tidak sesuai: elemen di luar layar atau zona aman, struk dan kolom samping dan tombol
## bertumpuk, label di luar struk atau kolom, label bertumpuk, teks terpotong (baris dan lebar), tombol < 42 tinggi atau < 84 lebar, chip di luar kartu, lebar struk dan kolom tidak sama dengan `TampilHasil.tata`.
## Menulis juga `<awalan>_hasil_<keadaan>.json` (persegi dan warna token tiap teks, persegi kartu dan tombol) yang dibaca `tools/ukur_kontras_tangkapan.py --jenis hasil`. Tidak interaktif: keluar lewat `ProbeKeluar`.
## Tidak menulis save apa pun.
##
## Run ui2-semua-layar bagian E (V-10): semua keadaan dipotret DI ATAS DUNIA RUTE nyata (`RuteMain` dibekukan di satu posisi, `_buka_hasil` dipanggil supaya HUD dan lapisan dunia tersembunyi seperti di permainan, lalu isi layar
## diganti data buatan keadaan itu). Keadaan `p_tanpa_dunia` memotret layar hasil sendiri tanpa dunia (latar gelap polos, panel buram). Tiap tangkapan disertai `<awalan>_hasil_<keadaan>_latar.png`: sama persis tetapi semua teks
## dibuat transparan, sehingga `tools/ukur_kontras_tangkapan.py --jenis hasil` mengukur kontras teks terhadap piksel latar TERBURUK di bawahnya (bukan hanya warna terbanyak). Argumen kedua (opsional) = folder untuk SAPUAN latar
## terburuk: keadaan terpadat di 12 kombinasi hari dan posisi rute (rumput, jalan, rumah, trotoar) berawalan `sapu_`; bawaan = folder pertama.
##
## Pakai (jendela harus muat di layar monitor):
##   godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_hasil_jendela.gd -- docs/loop/<RUN_ID>/shots/iter<N>
##   (juga 1920x1080 = lebar 640, 2400x1080 = lebar 800, 1600x720 = lebar 800)
## Berkas: `<lebar>x<tinggi>_hasil_<keadaan>.png`.

const BERKAS_RUTE: String = "res://scenes/rute/rute.tscn"
const BERKAS_HASIL: String = "res://scenes/ui/layar_hasil.tscn"
const DT: float = 1.0 / 60.0
## Hari dan posisi rute (pecahan panjang rute) untuk sapuan latar terburuk, dan posisi dunia keadaan biasa.
const SAPU_HARI: Array[int] = [3, 9]
## 1,0 = tepat di garis akhir: dunia beku dengan portal di latar (run garis-finish-portal, kamera beku seperti saat layar hasil nyata terbuka).
const SAPU_POSISI: Array[float] = [0.08, 0.25, 0.42, 0.58, 0.75, 0.92, 1.0]
const POSISI_BIASA: float = 0.5
const HARI_BIASA: int = 3

var _folder: String = ""
var _folder_sapu: String = ""
var _awalan: String = ""
var _gagal: int = 0
var _toko: PemuatToko.Kumpulan = PemuatToko.muat()
var _kepribadian: Array[KepribadianPelanggan.Entri] = PemuatPelanggan.muat().entri


func _initialize() -> void:
	var argumen: PackedStringArray = OS.get_cmdline_user_args()
	_folder = argumen[0] if argumen.size() > 0 else ""
	_folder_sapu = argumen[1] if argumen.size() > 1 else _folder
	var misi: DataMisi = PemuatMisi.muat_folder().cari("p1_kucing")
	var kosong: Array[String] = []
	var tiga: Array[String] = ["ban", "rem", "rantai"]
	var satu: Array[String] = ["ban"]
	# nama, angka, misi (null = tanpa), perlu bengkel, saldo lama, reputasi, state sebelum, state sesudah
	await _kasus("a_biasa", _angka(22, 355, 0, 25, 1, 14780, 9), null, kosong, 120, _rep(10, 12, [1, 0, 0, 0]), _ms(7, 700, 0, 0, 0), _ms(7, 1080, 0, 0, 0))
	await _kasus("b_minus", _angka(2, 30, 8, 0, 0, 1150, 0, true, 125), null, satu, 12, _rep(10, 9, [0, 0, 1, 0]), _ms(6, 700, 0, 0, 0), _ms(6, 730, 0, 0, 0))
	await _kasus("c_semua_terkirim", _angka(25, 510, 0, 60, 3, 21340, 18, false, 0, "selesai", 75), misi, kosong, 300, _rep(12, 15, [0, 2, 0, 0]), _ms(9, 700, 0, 0, 0), _ms(9, 1210, 1, 0, 0))
	await _kasus("d_lewat_tenggat", _angka(24, 370, 0, 10, 1, 15210, 7, true, 72, "gagal", 0), misi, kosong, 80, _rep(12, 13, [0, 0, 0, 0]), _ms(7, 700, 0, 0, 0), _ms(7, 1070, 0, 0, 0))
	await _kasus("e_pelanggan", _angka(18, 270, 0, 0, 0, 9000, 4), null, kosong, 80, _rep(30, 29, [1, 2, 1, 1]), _ms(7, 700, 0, 0, 0), _ms(7, 970, 0, 0, 0))
	await _kasus("f_milestone_baru", _angka(24, 420, 0, 0, 0, 14000, 6), null, kosong, 200, _rep(12, 14, [0, 0, 0, 0]), _ms(9, 700, 2, 3, 0), _ms(10, 1240, 2, 3, 0))
	await _kasus("g_semua_emas", _angka(25, 500, 0, 0, 0, 20000, 10), null, kosong, 300, _rep(47, 48, [0, 0, 0, 0]), _ms(25, 20000, 5, 10, 0), _ms(25, 20500, 5, 10, 0))
	var padat: HasilRute.Angka = _angka(2, 150, 25, 15, 2, 12480, 6, true, 72, "selesai", 75)
	await _kasus("h_terpadat", padat, misi, tiga, 10, _rep(55, 53, [4, 3, 2, 1]), _ms(2, 990, 0, 0, 0), _ms(10, 5100, 1, 4, 0))
	await _kasus("i_tanpa_reputasi", _angka(22, 355, 0, 25, 1, 14780, 9), null, kosong, -1, null, null, null)
	await _kasus("j_tanpa_reputasi_terpadat", padat, misi, tiga, 10, null, null, null)
	await _kasus("k_main_lagi", _angka(20, 300, 0, 0, 0, 10000, 3), null, kosong, -1, null, null, null, false)
	await _kasus("l_angka_besar", _angka(25, 1234567, 99999, 120, 5, 987654321, 25, false, 0), null, kosong, 10, _rep(88, 100, [12, 0, 0, 0]), _ms(25, 14000, 5, 10, 0), _ms(25, 15500, 5, 10, 0))
	await _kasus_dari_rute()
	var inset: ZonaAman.Inset = ZonaAman.Inset.new()
	inset.awal_x = 36
	inset.akhir_x = 24
	inset.atas = 16
	inset.bawah = 20
	await _kasus("m_inset_terpadat", padat, misi, tiga, 10, _rep(55, 53, [4, 3, 2, 1]), _ms(2, 990, 0, 0, 0), _ms(10, 5100, 1, 4, 0), true, inset)
	await _kasus("n_inset_biasa", _angka(22, 355, 0, 25, 1, 14780, 9), null, kosong, 120, _rep(10, 12, [1, 0, 0, 0]), _ms(7, 700, 0, 0, 0), _ms(7, 1080, 0, 0, 0), true, inset)
	# Run garis-finish-portal bagian C: layar hasil di atas dunia beku di garis akhir (portal terlihat di latar, sepeda sudah di luar layar), diukur kontrasnya seperti keadaan lain.
	await _kasus("q_dunia_portal", padat, misi, tiga, 10, _rep(55, 53, [4, 3, 2, 1]), _ms(2, 990, 0, 0, 0), _ms(10, 5100, 1, 4, 0), true, null, 1.0)
	await _kasus_tanpa_dunia("p_tanpa_dunia", padat, misi, tiga, 10, _rep(55, 53, [4, 3, 2, 1]), _ms(2, 990, 0, 0, 0), _ms(10, 5100, 1, 4, 0))
	await _sapu(padat, misi, tiga)
	print("probe selesai, %d keadaan tidak sesuai" % _gagal)
	await ProbeKeluar.keluar(self, 0 if _gagal == 0 else 1)


# --- Data buatan ---

func _angka(terkirim: int, koin: int, terbuang: int, koin_tip: int = 0, jumlah_tip: int = 0, skor: int = 1000, tepat: int = 0, lewat: bool = false, detik_lewat: int = 0, misi_hasil: String = "", koin_misi: int = 0) -> HasilRute.Angka:
	var a: HasilRute.Angka = HasilRute.Angka.new()
	a.pelanggan = 25
	a.terkirim = terkirim
	a.meleset = 25 - terkirim
	a.koin = koin
	a.koin_tip = koin_tip
	a.jumlah_tip = jumlah_tip
	a.skor = skor
	a.jumlah_tepat = tepat
	a.lempar_terbuang = terbuang
	a.potongan = terbuang * Config.KOIN_POTONGAN_KORAN_MELESET
	a.tenggat_lewat = lewat
	a.detik_lewat = detik_lewat
	a.misi_hasil = misi_hasil
	a.koin_misi = koin_misi
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
func _ms(setia: int, koin_total: int, misi: int, servis: int, level: int) -> Dictionary:
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


# --- Skenario ---

func _kasus(nama: String, angka: HasilRute.Angka, misi: DataMisi, perlu: Array[String], saldo_lama: int, rep: ReputationManager.Hasil, sebelum: Variant, sesudah: Variant, mode_hari: bool = true, inset: ZonaAman.Inset = null, posisi: float = POSISI_BIASA, hari: int = HARI_BIASA, folder: String = "", awalan_nama: String = "") -> void:
	var akar: RuteMain = await _dunia_beku(hari, posisi)
	var layar: LayarHasil = akar.layar_hasil()
	layar.atur_inset(inset)
	layar.atur_mode_hari(mode_hari)
	var ringkas: MilestoneTracker.Ringkasan = null
	if sebelum != null:
		ringkas = MilestoneTracker.ringkas(sebelum, sesudah)
	layar.isi(angka, misi if angka.misi_hasil != "" else null, perlu, saldo_lama, rep, ringkas)
	await _tunggu(5)
	_awalan = "%dx%d" % [root.size.x, root.size.y]
	_periksa_dunia(nama, akar)
	await _simpan(nama, folder)
	_cek(nama, layar, inset)
	_tulis_ukuran(nama, layar, folder)
	await _simpan_latar(nama, layar, folder)
	akar.queue_free()
	await _tunggu(2)


## Layar hasil sendiri tanpa dunia (`RuteMain` tidak ada): latar gelap polos buram dan panel buram, tanpa galat.
func _kasus_tanpa_dunia(nama: String, angka: HasilRute.Angka, misi: DataMisi, perlu: Array[String], saldo_lama: int, rep: ReputationManager.Hasil, sebelum: Variant, sesudah: Variant) -> void:
	var layar: LayarHasil = (load(BERKAS_HASIL) as PackedScene).instantiate() as LayarHasil
	root.add_child(layar)
	await _tunggu(2)
	layar.atur_mode_hari(true)
	layar.isi(angka, misi if angka.misi_hasil != "" else null, perlu, saldo_lama, rep, MilestoneTracker.ringkas(sebelum, sesudah))
	layar.tampilkan(true)
	await _tunggu(5)
	_awalan = "%dx%d" % [root.size.x, root.size.y]
	_harap("%s: tanpa dunia, latar gelap polos buram dan panel buram" % nama, not layar.ada_dunia() and layar.warna_latar() == TampilHasil.warna_latar(false) and layar.warna_latar().a == 1.0 and layar.alpha_panel() == 1.0, "")
	await _simpan(nama, "")
	_cek(nama, layar, null)
	_tulis_ukuran(nama, layar, "")
	await _simpan_latar(nama, layar, "")
	layar.queue_free()
	await _tunggu(2)


## Sapuan latar terburuk: keadaan terpadat di atas dunia pada 12 kombinasi hari dan posisi rute (tangkapan ke folder sapuan bila diberikan).
func _sapu(padat: HasilRute.Angka, misi: DataMisi, tiga: Array[String]) -> void:
	for hari: int in SAPU_HARI:
		for pos: float in SAPU_POSISI:
			var nama: String = "sapu_h%d_p%02d" % [hari, roundi(pos * 100.0)]
			await _kasus(nama, padat, misi, tiga, 10, _rep(55, 53, [4, 3, 2, 1]), _ms(2, 990, 0, 0, 0), _ms(10, 5100, 1, 4, 0), true, null, pos, hari, _folder_sapu)


## `RuteMain` nyata di hari `hari` dibekukan di `posisi` x panjang rute, lalu `_buka_hasil` dipanggil (HUD, tutorial, umpan melayang, dan lapisan kontrol tersembunyi seperti di permainan). Dunia tetap tergambar di belakang layar hasil.
func _dunia_beku(hari: int, posisi: float) -> RuteMain:
	var s: Dictionary = DataSave.templat()
	s["reputasi"] = {"perumahan": 20}
	s["koin"] = 150
	var akar: RuteMain = (load(BERKAS_RUTE) as PackedScene).instantiate() as RuteMain
	akar.atur_hari(hari)
	akar.atur_sepeda(s, hari, _toko.upgrade)
	akar.atur_pelanggan(s, _kepribadian)
	root.add_child(akar)
	await _tunggu(3)
	akar.set_process(false)
	(akar.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = false
	(akar.find_child("LoperAgen", true, false) as LoperSprite).set_process(false)
	var sepeda: SepedaUji = akar.find_child("Sepeda", true, false) as SepedaUji
	sepeda.jarak_ubin = akar.rute().panjang_ubin * posisi
	var k: BikeMotion.Keadaan = sepeda.keadaan.salin()
	k.lateral_ubin = 0.5
	k.kecepatan_ud = 0.0
	sepeda.keadaan = k
	akar.perbarui(0.0)
	await _tunggu(2)
	akar.call(&"_buka_hasil")
	await _tunggu(2)
	return akar


## Dunia ada di belakang layar hasil dan lapisan yang tidak boleh tembus tersembunyi (HUD, tutorial, umpan melayang, lapisan kontrol, banner), lapisan gelap tembus pandang dan panel transparan sebagian dari `Config`.
func _periksa_dunia(nama: String, akar: RuteMain) -> void:
	var layar: LayarHasil = akar.layar_hasil()
	var kontrol: CanvasLayer = akar.find_child("KontrolTouch", true, false).get_parent() as CanvasLayer
	var umpan: CanvasItem = akar.find_child("UmpanMelayang", true, false) as CanvasItem
	_harap("%s: dunia di belakang, lapisan gelap tembus pandang, panel transparan" % nama, layar.ada_dunia() and absf(layar.warna_latar().a - Config.HASIL_LATAR_ALPHA) < 0.0001 and absf(layar.alpha_panel() - Config.HASIL_PANEL_ALPHA) < 0.0001, "")
	_harap("%s: HUD, tutorial, kontrol, umpan, banner akhir tersembunyi" % nama, not akar.hud_rute().visible and not akar.find_child("Tutorial", true, false).visible and not kontrol.visible and not umpan.visible and not (akar.find_child("PanelAkhir", true, false) as PanelAkhirRute).tampil(), "")


## Hasil dari rute nyata (`RuteMain`): reputasi, pelanggan, dan milestone dihitung dari state save tiruan (tanpa menulis save).
func _kasus_dari_rute() -> void:
	var s: Dictionary = DataSave.templat()
	s["reputasi"] = {"perumahan": 20}
	s["koin"] = 150
	s["koin_total"] = 940
	var akar: RuteMain = (load(BERKAS_RUTE) as PackedScene).instantiate() as RuteMain
	akar.atur_hari(3)
	akar.atur_sepeda(s, 3, _toko.upgrade)
	akar.atur_pelanggan(s, _kepribadian)
	root.add_child(akar)
	await _tunggu(5)
	akar.set_process(false)
	_awalan = "%dx%d" % [root.size.x, root.size.y]
	var sepeda: SepedaUji = akar.find_child("Sepeda", true, false) as SepedaUji
	(akar.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = false
	var sprite: LoperSprite = akar.find_child("LoperAgen", true, false) as LoperSprite
	sprite.set_process(false)
	akar.set(&"_rintangan", RintanganRute.Keadaan.new())
	akar.atur_kondisi(KondisiRute.awal(Economy.kondisi_dari(s), Economy.level_dari(s), 3, _toko.upgrade))
	akar.atur_mode_hari(true)
	sepeda.jarak_ubin = akar.rute().panjang_ubin - 1.0
	var k: BikeMotion.Keadaan = sepeda.keadaan.salin()
	k.lateral_ubin = 0.5
	k.kecepatan_ud = Config.KECEPATAN_SANTAI_UD
	sepeda.keadaan = k
	var batas: int = 0
	while not akar.hasil_tampil() and batas < 600:
		akar.perbarui(DT)
		sprite.maju(DT)
		await process_frame
		batas += 1
	await _tunggu(5)
	var layar: LayarHasil = akar.layar_hasil()
	_harap("rute nyata: hasil reputasi dan milestone terisi dan kolom samping tampil", akar.hasil_reputasi() != null and akar.hasil_milestone() != null and layar.kanan_tampil(), "")
	_periksa_dunia("o_dari_rute", akar)
	await _simpan("o_dari_rute", "")
	_cek("o_dari_rute", layar, null)
	_tulis_ukuran("o_dari_rute", layar, "")
	await _simpan_latar("o_dari_rute", layar, "")
	akar.queue_free()
	await _tunggu(2)


# --- Pemeriksaan ---

func _harap(nama: String, kondisi: bool, rincian: String) -> void:
	if not kondisi:
		print("TIDAK SESUAI: %s (%s)" % [nama, rincian])
		_gagal += 1


## Struk, kolom samping, dan tombol di dalam zona aman dan tidak bertumpuk; label di dalam wadahnya dan tidak bertumpuk; teks tidak terpotong; tombol >= 42 x 84 (utama 140); lebar sesuai `TampilHasil.tata`.
func _cek(nama: String, layar: LayarHasil, inset: ZonaAman.Inset) -> void:
	var ins: ZonaAman.Inset = inset if inset != null else ZonaAman.Inset.new()
	var ukuran: Vector2 = root.get_visible_rect().size
	var aman: Rect2 = Rect2(Vector2(maxi(12, ins.awal_x), maxi(12, ins.atas)), ukuran - Vector2(maxi(12, ins.awal_x) + maxi(12, ins.akhir_x), maxi(12, ins.atas) + maxi(12, ins.bawah)))
	var salah: int = 0
	var struk: Rect2 = layar.rect_panel()
	var tombol: Rect2 = layar.rect_tombol()
	var kolom: Rect2 = layar.rect_panel_kanan() if layar.kanan_tampil() else Rect2()
	var judul: Rect2 = layar.rect_judul()
	var wadah: Dictionary = {"struk": struk, "tombol": tombol, "judul": judul}
	if layar.kanan_tampil():
		wadah["kolom"] = kolom
	for kunci: String in wadah:
		if not aman.grow(0.5).encloses(wadah[kunci]):
			print("TIDAK SESUAI [%s]: %s %s di luar zona aman %s" % [nama, kunci, wadah[kunci], aman])
			salah += 1
	var nama_wadah: Array = wadah.keys()
	for i: int in range(nama_wadah.size()):
		for j: int in range(i + 1, nama_wadah.size()):
			if (wadah[nama_wadah[i]] as Rect2).intersects(wadah[nama_wadah[j]]):
				print("TIDAK SESUAI [%s]: %s %s menumpuk %s %s" % [nama, nama_wadah[i], wadah[nama_wadah[i]], nama_wadah[j], wadah[nama_wadah[j]]])
				salah += 1
	if tombol.size.y < 42.0 or tombol.size.x < 84.0 or absf(tombol.size.x - 140.0) > 0.5 or absf(tombol.size.y - 42.0) > 0.5:
		print("TIDAK SESUAI [%s]: tombol %s bukan 140x42 (minimum 84x42)" % [nama, tombol.size])
		salah += 1
	if tombol.size.x + 0.5 < layar.tombol_main_lagi().get_minimum_size().x:
		print("TIDAK SESUAI [%s]: teks tombol terpotong" % nama)
		salah += 1
	var tata: TampilHasil.Tata = layar.tata()
	if absf(struk.size.x - float(tata.lebar_struk)) > 0.5 or (layar.kanan_tampil() and absf(kolom.size.x - float(tata.lebar_kolom)) > 0.5):
		print("TIDAK SESUAI [%s]: lebar struk %.1f dan kolom %.1f, seharusnya %d dan %d" % [nama, struk.size.x, kolom.size.x, tata.lebar_struk, tata.lebar_kolom])
		salah += 1
	if layar.kanan_tampil() and kolom.end.y > float(tata.batas_bawah_kolom) + 0.5:
		print("TIDAK SESUAI [%s]: kolom samping berakhir y %.1f di bawah batas %d (tombol %s)" % [nama, kolom.end.y, tata.batas_bawah_kolom, tombol])
		salah += 1
	var isi: Array[Rect2] = layar.rect_label()
	for r: Rect2 in isi:
		if not struk.grow(0.5).encloses(r) or r.size.x <= 0.0:
			print("TIDAK SESUAI [%s]: label %s di luar struk %s" % [nama, r, struk])
			salah += 1
	for r: Rect2 in layar.rect_isi_kanan():
		if not kolom.grow(0.5).encloses(r):
			print("TIDAK SESUAI [%s]: isi kolom samping %s di luar kolom %s" % [nama, r, kolom])
			salah += 1
	for r: Rect2 in layar.rect_kartu():
		if not kolom.grow(0.5).encloses(r):
			print("TIDAK SESUAI [%s]: kartu %s di luar kolom %s" % [nama, r, kolom])
			salah += 1
	salah += _periksa_label(nama, layar)
	var ada_chip: bool = layar.kanan_tampil() and layar.chip_reputasi().is_visible_in_tree()
	if ada_chip:
		var kartu_rep: Rect2 = layar.rect_kartu()[0]
		if not kartu_rep.grow(0.5).encloses(layar.chip_reputasi().get_global_rect()):
			print("TIDAK SESUAI [%s]: chip reputasi %s di luar kartunya %s" % [nama, layar.chip_reputasi().get_global_rect(), kartu_rep])
			salah += 1
	print("hasil [%s]: struk %s, kolom %s, tombol %s '%s', %d tidak sesuai" % [nama, struk, kolom, tombol, layar.teks_tombol(), salah])
	print("teks: %s" % [" | ".join(layar.teks_tampil())])
	_gagal += salah


## Label tampil yang teksnya terpotong (baris terlihat != baris, tinggi kurang, atau lebar kurang dari lebar teks pada label satu baris) dan label yang saling bertumpuk.
func _periksa_label(nama: String, layar: LayarHasil) -> int:
	var salah: int = 0
	var rects: Array[Rect2] = []
	var teks_rect: Array[String] = []
	for simpul: Node in layar.find_children("*", "Label", true, false):
		var label: Label = simpul as Label
		if not label.is_visible_in_tree() or label.text == "":
			continue
		var perlu: float = float(label.get_line_count()) * float(label.get_line_height())
		var font: Font = label.get_theme_font(&"font")
		var ukuran_font: int = label.get_theme_font_size(&"font_size")
		var lebar_teks: float = font.get_string_size(tr(label.text), HORIZONTAL_ALIGNMENT_LEFT, -1, ukuran_font).x
		if label.get_visible_line_count() != label.get_line_count() or label.size.y + 0.5 < perlu or (label.autowrap_mode == TextServer.AUTOWRAP_OFF and label.size.x + 0.5 < lebar_teks):
			print("TIDAK SESUAI [%s]: teks terpotong '%s' (label %s, perlu tinggi %.1f, lebar %.1f)" % [nama, label.text, label.size, perlu, lebar_teks])
			salah += 1
		rects.append(label.get_global_rect())
		teks_rect.append(label.text)
	for i: int in range(rects.size()):
		for j: int in range(i + 1, rects.size()):
			if rects[i].intersects(rects[j]):
				print("TIDAK SESUAI [%s]: label '%s' %s menumpuk '%s' %s" % [nama, teks_rect[i], rects[i], teks_rect[j], rects[j]])
				salah += 1
	return salah


## Persegi dan warna token tiap teks, kartu, struk, dan tombol ke `<awalan>_hasil_<keadaan>.json` untuk `tools/ukur_kontras_tangkapan.py --jenis hasil` (hanya bila folder keluaran diberikan).
func _tulis_ukuran(nama: String, layar: LayarHasil, folder: String = "") -> void:
	var tujuan: String = folder if folder != "" else _folder
	if tujuan.is_empty():
		return
	var teks: Array = []
	for simpul: Node in layar.find_children("*", "Label", true, false):
		var label: Label = simpul as Label
		if label.is_visible_in_tree() and label.text != "":
			var r: Rect2 = label.get_global_rect()
			teks.append({"teks": tr(label.text), "rect": [r.position.x, r.position.y, r.size.x, r.size.y], "warna": "#" + label.get_theme_color(&"font_color").to_html(false)})
	for simpul: Node in layar.find_children("*", "Button", true, false):
		var tombol: Button = simpul as Button
		if tombol.is_visible_in_tree() and tombol.text != "":
			var r2: Rect2 = tombol.get_global_rect()
			var kunci: StringName = &"font_disabled_color" if tombol.disabled else &"font_color"
			teks.append({"tombol": true, "teks": tr(tombol.text), "rect": [r2.position.x, r2.position.y, r2.size.x, r2.size.y], "warna": "#" + tombol.get_theme_color(kunci).to_html(false)})
	var komponen: Array = []
	var rt: Rect2 = layar.rect_tombol()
	komponen.append({"jenis": "tombol", "rect": [rt.position.x, rt.position.y, rt.size.x, rt.size.y]})
	for r3: Rect2 in layar.rect_kartu():
		komponen.append({"jenis": "kartu", "rect": [r3.position.x, r3.position.y, r3.size.x, r3.size.y]})
	var rs: Rect2 = layar.rect_panel()
	komponen.append({"jenis": "struk", "rect": [rs.position.x, rs.position.y, rs.size.x, rs.size.y]})
	var berkas: FileAccess = FileAccess.open("%s/%s_hasil_%s.json" % [tujuan, _awalan, nama], FileAccess.WRITE)
	if berkas != null:
		berkas.store_string(JSON.stringify({"viewport": [root.get_visible_rect().size.x, root.get_visible_rect().size.y], "teks": teks, "komponen": komponen}))


func _tunggu(jumlah: int) -> void:
	for i: int in range(jumlah):
		await process_frame


func _simpan(keadaan: String, folder: String = "") -> void:
	var tujuan: String = folder if folder != "" else _folder
	if tujuan.is_empty():
		return
	var gambar: Image = root.get_texture().get_image()
	var berkas: String = "%s/%s_hasil_%s.png" % [tujuan, _awalan, keadaan]
	var galat: int = gambar.save_png(berkas)
	print("tangkapan layar %dx%d (%s) ke %s (kode %d)" % [gambar.get_width(), gambar.get_height(), keadaan, berkas, galat])


## Tangkapan kedua dengan semua teks transparan (`<awalan>_hasil_<keadaan>_latar.png`): latar nyata di bawah tiap teks untuk kontras terburuk. Dipanggil sesudah `_tulis_ukuran` (warna teks sudah terbaca); layar dibuang sesudahnya.
func _simpan_latar(keadaan: String, layar: LayarHasil, folder: String) -> void:
	var tujuan: String = folder if folder != "" else _folder
	if tujuan.is_empty():
		return
	var bening: Color = Color(0, 0, 0, 0)
	for simpul: Node in layar.find_children("*", "Label", true, false):
		(simpul as Label).add_theme_color_override(&"font_color", bening)
	for simpul: Node in layar.find_children("*", "Button", true, false):
		for kunci: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color", &"font_disabled_color", &"font_hover_pressed_color"]:
			(simpul as Button).add_theme_color_override(kunci, bening)
	await _tunggu(3)
	var gambar: Image = root.get_texture().get_image()
	gambar.save_png("%s/%s_hasil_%s_latar.png" % [tujuan, _awalan, keadaan])
