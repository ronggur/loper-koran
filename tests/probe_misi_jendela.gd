extends SceneTree
## Probe misi kucing di jendela asli, non-headless (AC-22 run fase4b-misi-kucing): memuat `scenes/rute/rute.tscn` dengan misi P1 nyata (`atur_misi`) dan tutorial
## (`atur_tutorial`), memajukan simulasi dengan langkah tetap `perbarui(1/60)` (bukan waktu dinding), lalu memotret: HUD misi awal (kartu, tutorial langkah 1),
## HUD dengan 8 rumah tersisa, kucing tampil (kilau) di tiap titik, petunjuk dari lemparan tepat sungguhan (gelembung teks), menepi dan tangkap (bar progres),
## banner selesai, banner gagal, layar hasil dengan rekap (selesai dan gagal), tutorial tiap langkah, dan kidal. Mencetak data tiap keadaan dan jumlah keadaan
## yang tidak sesuai (teks terpotong, tumpang tindih dengan elemen HUD lain, di luar layar). Tidak interaktif: keluar lewat `ProbeKeluar`.
##
## Pakai (jendela harus muat di layar monitor):
##   godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_misi_jendela.gd -- docs/loop/<RUN_ID>/shots/iter<N>
##   (juga 1920x1080, 2400x1080, 1600x720)
## Berkas: `<lebar>x<tinggi>_misi_<keadaan>.png`.

const BERKAS_RUTE: String = "res://scenes/rute/rute.tscn"
const FRAME_TUNGGU_LAYOUT: int = 5
const DT: float = 1.0 / 60.0

var _skala: float = 1.0
var _folder: String = ""
var _awalan: String = ""
var _akar: RuteMain
var _sepeda: SepedaUji
var _hud: HudRute
var _kontrol: KontrolTouch
var _sprite: LoperSprite
var _debu: PancaranPiksel
var _garis: PancaranPiksel
var _misi: DataMisi
var _gagal: int = 0
## Bila >= 0: sepeda ditahan diam di jarak ini (lateral -1) tiap langkah (foto menepi dan menangkap).
var _tahan_jarak: float = -1.0


func _initialize() -> void:
	var argumen: PackedStringArray = OS.get_cmdline_user_args()
	_folder = argumen[0] if argumen.size() > 0 else ""
	_misi = PemuatMisi.muat_folder().cari("p1_kucing")
	await _jalankan_skenario("selesai")
	print("probe selesai, %d keadaan tidak sesuai" % _gagal)
	await ProbeKeluar.keluar(self, 0 if _gagal == 0 else 1)


## Satu putaran penuh skenario; `akhir` = "selesai" (kucing ditangkap) lalu rute baru untuk skenario gagal.
func _jalankan_skenario(_nama: String) -> void:
	await _pasang(1)
	var rute: RouteBuilder.Rute = _akar.rute()
	var rencana: RencanaMisi.Rencana = _akar.rencana_misi()
	print("jendela %s: skala x%s; rute seed %d, %d pelanggan; rencana titik rumah ke-%d, %d, %d (maju %.1f, %.1f, %.1f), batas maju %.1f" % [root.size, _skala, _akar.benih(), rute.pelanggan.size(), rencana.titik[0].indeks_rumah, rencana.titik[1].indeks_rumah, rencana.titik[2].indeks_rumah, rencana.titik[0].maju_ubin, rencana.titik[1].maju_ubin, rencana.titik[2].maju_ubin, rencana.maju_batas_ubin])

	# --- 1. HUD misi awal: kartu 12 rumah, tutorial langkah 1 (kayuh) ---
	await _maju(0.5)
	await _foto("awal")
	_harap("kartu awal", _hud.kartu_tampil() and _hud.teks_kartu() == "Kucing 0/1 · 12 rumah", _hud.teks_kartu())
	_harap("tutorial langkah 1", _akar.tutorial_node().tampil() and _akar.tutorial_node().teks() == "Dorong stick ke atas untuk ngebut", _akar.tutorial_node().teks())
	_cek_tumpang_tindih("awal")

	# --- 2. Kucing titik 1 tampil (kilau) dari jauh; tutorial langkah 2 (melambat) ---
	var t1: RencanaMisi.Titik = rencana.titik[0]
	_set_kecepatan(Config.TUTORIAL_KAYUH_KECEPATAN_UD + 0.5)
	await _maju(DT)
	_set_kecepatan(Config.KECEPATAN_SANTAI_UD)
	_letakkan(t1.maju_ubin - 9.0, 0.5)
	await _maju(DT)
	await _foto("kucing_titik1")
	_harap("tutorial langkah 2 tampil sebelum melambat", _akar.tutorial_node().teks() == "Tarik stick ke bawah untuk melambat", _akar.tutorial_node().teks())
	_harap("kucing titik 1 tampil", _akar.kucing().tampil() and _akar.kucing().titik() == t1, "")
	_cek_kucing("kucing_titik1")
	_set_kecepatan(Config.TUTORIAL_MELAMBAT_KECEPATAN_UD - 0.5)
	await _maju(DT)
	await _foto("tutorial_lempar")
	_harap("tutorial langkah 3 sesudah melambat", _akar.tutorial_node().teks() == "Lempar koran ke kotak surat", _akar.tutorial_node().teks())

	# --- 4. Petunjuk dari lemparan tepat sungguhan untuk titik 2 (jendela [rumah titik 1, rumah titik 2)); tutorial langkah 3 (lempar) ---
	var t2: RencanaMisi.Titik = rencana.titik[1]
	var rumah_petunjuk: RouteBuilder.RumahRute = _rumah_pelanggan_di_jendela(t2)
	if rumah_petunjuk != null:
		await _lempar_tepat(rumah_petunjuk, t2.maju_ubin - Config.MISI_TAMPIL_JARAK_UBIN - 0.3)
		await _foto("petunjuk")
		_harap("petunjuk tampil", _hud.petunjuk_tampil() and _hud.teks_petunjuk() == "Tadi ada kucing lewat ke arah warung", _hud.teks_petunjuk())
		_harap("tutorial langkah 4 menunggu kucing tangkap", _akar.keadaan_tutorial().langkah == TutorialLangkah.Langkah.MENEPI and not _akar.tutorial_node().tampil(), "")
		_cek_tumpang_tindih("petunjuk")
	else:
		print("PERINGATAN: tidak ada pelanggan di jendela petunjuk titik 2")
		_gagal += 1
	await _maju(Config.MISI_PETUNJUK_DETIK + 0.1)

	# --- 3. HUD dengan 8 rumah tersisa (empat rumah seberang dilewati), kucing titik 1 dilewati ---
	_letakkan(rencana.akhir_kavling_ubin[3] + 0.1, 0.5)
	await _maju(DT)
	await _foto("hud_8_rumah")
	_harap("kartu 8 rumah", _hud.teks_kartu() == "Kucing 0/1 · 8 rumah", _hud.teks_kartu())
	_cek_tumpang_tindih("hud_8_rumah")

	# --- 5. Kucing titik 2 dan 3 tampil (kilau) ---
	_letakkan(t2.maju_ubin - 7.0, 0.5)
	await _maju(DT)
	await _foto("kucing_titik2")
	_harap("kucing titik 2 tampil", _akar.kucing().tampil() and _akar.kucing().titik() == t2, "")
	_cek_kucing("kucing_titik2")
	var t3: RencanaMisi.Titik = rencana.titik[2]
	_letakkan(t3.maju_ubin - 6.0, 0.5)
	await _maju(DT)
	await _foto("kucing_titik3")
	_harap("kucing titik 3 tampil", _akar.kucing().tampil() and _akar.kucing().titik() == t3, "")
	_cek_kucing("kucing_titik3")
	_harap("tutorial langkah 4 (menepi) tampil sesudah kucing tangkap terlihat", _akar.tutorial_node().tampil() and _akar.tutorial_node().teks() == "Menepi dan berhenti dekat kucing", _akar.tutorial_node().teks())

	# --- 6. Menepi dan menangkap: sepeda diam di lateral -1 dekat kucing, separuh waktu lalu selesai ---
	_tahan_jarak = t3.maju_ubin - 1.2
	await _maju(t3.lama_berhenti_detik * 0.6)
	await _foto("tangkap_progres")
	var progres: float = _akar.keadaan_misi().timer_detik / t3.lama_berhenti_detik
	print("progres tangkap: %.2f (timer %.2f detik)" % [progres, _akar.keadaan_misi().timer_detik])
	_harap("progres tangkap berjalan", progres > 0.4 and progres < 0.9, str(progres))
	await _maju(t3.lama_berhenti_detik * 0.6, false)
	_tahan_jarak = -1.0
	await _maju(0.2)
	await _foto("banner_selesai")
	_harap("banner selesai", _hud.banner_tampil() and _hud.teks_banner() == "Kucing ketemu! +75", _hud.teks_banner())
	_harap("koin HUD = koin antaran + 75 hadiah misi", _hud.teks_koin() == str(_akar.skor().koin + 75), _hud.teks_koin())
	_cek_tumpang_tindih("banner_selesai")

	# --- 7. Layar hasil dengan rekap selesai ---
	await _selesaikan()
	await _foto("hasil_selesai")
	_harap("rekap selesai", _akar.layar_hasil().teks_rekap_misi() == "Misi: Kucing ketemu! +75 koin", _akar.layar_hasil().teks_rekap_misi())
	_cek_hasil("hasil_selesai")

	# --- 8. Rute baru (seed + 1) untuk skenario gagal: lewati semua, banner gagal, hasil gagal ---
	_akar.main_lagi()
	await _maju(0.3)
	var rencana2: RencanaMisi.Rencana = _akar.rencana_misi()
	_letakkan(rencana2.maju_batas_ubin + 0.2, 0.5)
	await _maju(DT)
	await _foto("banner_gagal")
	_harap("banner gagal", _hud.banner_tampil() and _hud.teks_banner() == "Kucingnya lolos hari ini", _hud.teks_banner())
	_harap("koin HUD tetap 0 saat gagal", _hud.teks_koin() == "0", _hud.teks_koin())
	_cek_tumpang_tindih("banner_gagal")
	await _selesaikan()
	await _foto("hasil_gagal")
	_harap("rekap gagal", _akar.layar_hasil().teks_rekap_misi() == "Misi: Kucingnya lolos hari ini", _akar.layar_hasil().teks_rekap_misi())
	_cek_hasil("hasil_gagal")

	# --- 8b. Penanda tepi layar (iterasi 2, M-2'): kucing terlihat ngebut tetapi badannya belum utuh di layar; lajur dekat, tengah, dan seberang ---
	_akar.main_lagi()
	await _maju(0.3)
	var rencana3: RencanaMisi.Rencana = _akar.rencana_misi()
	var t1_baru: RencanaMisi.Titik = rencana3.titik[0]
	for kasus: Array in [["dekat", 2.0], ["tengah", 0.0], ["seberang", -2.0]]:
		await _ngebut_di(maxf(t1_baru.maju_ubin - 13.0, 0.0), float(kasus[1]))
		await _foto("penanda_" + str(kasus[0]))
		_harap("penanda tepi layar tampil (%s)" % kasus[0], _hud.penanda_kucing().penanda_tampil().size() == 1 and _akar.keadaan_misi().tampil[0], "penanda %d" % _hud.penanda_kucing().penanda_tampil().size())
		_cek_tumpang_tindih("penanda_" + str(kasus[0]))
	_set_kecepatan(Config.KECEPATAN_SANTAI_UD)
	for i: int in range(40):
		_letakkan(maxf(t1_baru.maju_ubin - 6.0, 0.0), 0.0)
		await _maju(DT, false)
	await _maju(DT)
	await _foto("penanda_hilang_badan_utuh")
	_harap("kucing 6 ubin di depan: badan utuh di layar, penanda hilang", _hud.penanda_kucing().penanda_tampil().is_empty() and _akar.kucing().tampil(), "penanda %d" % _hud.penanda_kucing().penanda_tampil().size())

	# --- 9. Kidal: kartu misi tidak berpindah, panel bawah dan bel dicerminkan ---
	_akar.main_lagi()
	await _maju(0.3)
	_akar.atur_kidal(true)
	_letakkan(rencana2.akhir_kavling_ubin[3] + 0.1, 0.5)
	await _maju(DT)
	await _foto("kidal")
	_cek_tumpang_tindih("kidal")
	_cek_tutorial_lewati("kidal")


# --- Pemasangan ---

func _pasang(hari: int) -> void:
	_akar = (load(BERKAS_RUTE) as PackedScene).instantiate() as RuteMain
	_akar.atur_benih_awal(SeedHari.rute(hari))
	_akar.atur_misi(_misi)
	_akar.atur_tutorial(true)
	root.add_child(_akar)
	await _tunggu(FRAME_TUNGGU_LAYOUT)
	_akar.set_process(false)
	var terlihat: Vector2 = root.get_visible_rect().size
	_skala = float(root.size.x) / terlihat.x
	_awalan = "%dx%d" % [root.size.x, root.size.y]
	_sepeda = _akar.find_child("Sepeda", true, false) as SepedaUji
	_hud = _akar.hud_rute()
	_kontrol = _akar.find_child("KontrolTouch", true, false) as KontrolTouch
	_sprite = _akar.find_child("LoperAgen", true, false) as LoperSprite
	_sprite.set_process(false)
	_debu = _sepeda.umpan_balik().debu()
	_garis = _sepeda.umpan_balik().garis()
	_debu.set_process(false)
	_garis.set_process(false)
	_kontrol.keyboard_aktif = false


# --- Pemeriksaan ---

func _harap(nama: String, kondisi: bool, rincian: String) -> void:
	if not kondisi:
		print("TIDAK SESUAI: %s (%s)" % [nama, rincian])
		_gagal += 1


## Elemen misi (kartu, banner, petunjuk, tutorial) di dalam layar dan tidak menumpuk radar, panel progres, panel koin dan skor, tombol jeda, tombol bel, atau satu sama lain.
func _cek_tumpang_tindih(keadaan: String) -> void:
	var layar: Rect2 = Rect2(Vector2.ZERO, root.get_visible_rect().size)
	var elemen: Dictionary = {}
	if _hud.kartu_tampil():
		elemen["kartu"] = _hud.rect_kartu()
	if _hud.banner_tampil():
		elemen["banner"] = _hud.rect_banner()
	if _hud.petunjuk_tampil():
		elemen["petunjuk"] = _hud.rect_petunjuk()
	var nomor_penanda: int = 0
	for r_penanda: Rect2 in _hud.penanda_kucing().rect_penanda():
		elemen["penanda%d" % nomor_penanda] = r_penanda
		nomor_penanda += 1
	var tut: TutorialController = _akar.tutorial_node()
	if tut.tampil():
		elemen["tutorial"] = tut.rect_panel()
		elemen["lewati"] = tut.rect_lewati()
	var lain: Dictionary = {
		"radar_seberang": _hud.rect_radar_seberang(), "radar_dekat": _hud.rect_radar_dekat(), "panel_progres": _hud.rect_panel_progres(),
		"panel_koin": _hud.rect_panel_koin(), "panel_skor": _hud.rect_panel_skor(), "tombol_jeda": _hud.rect_tombol_jeda(), "tombol_bel": _hud.rect_tombol_bel(),
		"panel_kecepatan": _hud.rect_panel_kecepatan(), "panel_koran": _hud.rect_panel_koran(),
	}
	var salah: int = 0
	for nama: String in elemen:
		var r: Rect2 = elemen[nama]
		if not layar.encloses(r):
			print("TIDAK SESUAI [%s]: %s %s di luar layar %s" % [keadaan, nama, r, layar])
			salah += 1
		for nama_lain: String in lain:
			if r.intersects(lain[nama_lain]):
				print("TIDAK SESUAI [%s]: %s %s menumpuk %s %s" % [keadaan, nama, r, nama_lain, lain[nama_lain]])
				salah += 1
		for nama_kedua: String in elemen:
			if nama_kedua > nama and r.intersects(elemen[nama_kedua]):
				print("TIDAK SESUAI [%s]: %s %s menumpuk %s %s" % [keadaan, nama, r, nama_kedua, elemen[nama_kedua]])
				salah += 1
	print("tata letak [%s]: %d elemen misi/tutorial diperiksa, %d tidak sesuai" % [keadaan, elemen.size(), salah])
	_gagal += salah


func _cek_tutorial_lewati(keadaan: String) -> void:
	var tut: TutorialController = _akar.tutorial_node()
	if tut.tampil() and (tut.rect_lewati().size.x < 42.0 or tut.rect_lewati().size.y < 42.0):
		print("TIDAK SESUAI [%s]: tombol Lewati %s < 42 px" % [keadaan, tut.rect_lewati().size])
		_gagal += 1


## Kucing digambar dan sepenuhnya di dalam layar; hiasan kilau dan ekor menghasilkan perintah gambar.
func _cek_kucing(keadaan: String) -> void:
	var layar: Rect2 = Rect2(Vector2.ZERO, root.get_visible_rect().size)
	var r: Rect2 = _akar.kucing().rect_badan()
	var piksel: Rect2 = Rect2(r.position + Vector2(Config.MISI_KUCING_PIJAK_PX[0] - 6, Config.MISI_KUCING_PIJAK_PX[1] - 14), Vector2(16, 16))
	print("kucing [%s]: sel %s, badan sekitar %s, di layar %s, perintah hiasan %d" % [keadaan, r, piksel, layar.encloses(piksel), KucingHiasan.perintah_ekor(true, 0.0).size() + KucingHiasan.item_kilau(true, 0.0).size()])
	if not layar.encloses(piksel):
		print("TIDAK SESUAI [%s]: kucing di luar layar" % keadaan)
		_gagal += 1


func _cek_hasil(keadaan: String) -> void:
	var a: HasilRute.Angka = _akar.angka_hasil()
	var layar: Rect2 = Rect2(Vector2.ZERO, root.get_visible_rect().size)
	var salah: int = 0
	if a == null or not _akar.hasil_tampil():
		print("TIDAK SESUAI [%s]: layar hasil tidak terbuka" % keadaan)
		_gagal += 1
		return
	var hasil: LayarHasil = _akar.layar_hasil()
	if not layar.encloses(hasil.rect_panel()) or not layar.encloses(hasil.rect_tombol()):
		print("TIDAK SESUAI [%s]: panel hasil %s atau tombol %s di luar layar" % [keadaan, hasil.rect_panel(), hasil.rect_tombol()])
		salah += 1
	for r: Rect2 in hasil.rect_label():
		if not hasil.rect_panel().encloses(r):
			print("TIDAK SESUAI [%s]: label %s keluar dari panel %s" % [keadaan, r, hasil.rect_panel()])
			salah += 1
	if hasil.rect_tombol().intersects(hasil.rect_rekap_misi()):
		print("TIDAK SESUAI [%s]: tombol menumpuk rekap misi" % keadaan)
		salah += 1
	print("hasil [%s]: misi %s, koin %d (misi %d), tombol %s, panel %s, %d tidak sesuai" % [keadaan, a.misi_hasil, a.koin, a.koin_misi, hasil.rect_tombol(), hasil.rect_panel(), salah])
	print("teks layar hasil: %s" % [" | ".join(hasil.teks_tampil())])
	_gagal += salah


# --- Gerak ---

## Pelanggan pertama di jendela petunjuk `titik` (awal kavling di [awal, akhir)) yang kotak suratnya masih terjangkau lemparan sebelum kucing titik itu terlihat tanpa petunjuk; null bila tidak ada.
func _rumah_pelanggan_di_jendela(titik: RencanaMisi.Titik) -> RouteBuilder.RumahRute:
	for rumah: RouteBuilder.RumahRute in _akar.rute().pelanggan:
		var terjangkau_sebelum_tampil: bool = ZonaSasaran.maju_kotak_surat(rumah) - 4.5 < titik.maju_ubin - Config.MISI_TAMPIL_JARAK_UBIN - 0.3
		if rumah.maju_ubin >= titik.petunjuk_awal_ubin and rumah.maju_ubin < titik.petunjuk_akhir_ubin and terjangkau_sebelum_tampil:
			return rumah
	return null


## Lemparan biasa (bukan bantu) tepat ke pusat kotak surat `rumah` (lintasan dari pencari mode bantu, `_lempar` dengan `bantu` false), lalu menunggu koran mendarat.
func _lempar_tepat(rumah: RouteBuilder.RumahRute, maju_maks: float = INF) -> void:
	_letakkan(minf(ZonaSasaran.maju_kotak_surat(rumah) - 3.0, maju_maks), 0.5)
	await _maju(Config.LEMPAR_JEDA_DETIK, false)
	_akar.koran = SisaKoran.awal(30)
	var pilihan: BantuLempar.Pilihan = _akar.pilihan_bantu(LoperAnim.Sisi.SEBERANG)
	var detik: float = 0.0
	while (pilihan == null or pilihan.zona.id_rumah != rumah.id) and detik < 3.0:
		await _maju(DT, false)
		detik += DT
		pilihan = _akar.pilihan_bantu(LoperAnim.Sisi.SEBERANG)
	if pilihan == null or pilihan.zona.id_rumah != rumah.id:
		print("PERINGATAN: %s bukan sasaran dari sepeda" % rumah.id)
		_gagal += 1
		return
	_akar.call(&"_lempar", pilihan.lintasan, false)
	var batas: int = 0
	while not _akar.skor().terantar.has(rumah.id) and batas < 200:
		await _maju(DT, false)
		batas += 1
	await _maju(DT)


## Sepeda ngebut di `maju`/`lateral` sampai dorongan kamera mantap (sepeda ditaruh ulang tiap langkah), lalu satu bingkai digambar.
func _ngebut_di(maju: float, lateral: float) -> void:
	_set_kecepatan(Config.KECEPATAN_NGEBUT_UD)
	for i: int in range(45):
		_letakkan(maju, lateral)
		_set_kecepatan(Config.KECEPATAN_NGEBUT_UD)
		await _maju(DT, false)
	_letakkan(maju, lateral)
	await _maju(DT)


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


func _letakkan(maju: float, lateral: float = 0.5, lateral_tetap: float = INF) -> void:
	_sepeda.jarak_ubin = maxf(maju, 0.0)
	var k: BikeMotion.Keadaan = _sepeda.keadaan.salin()
	k.lateral_ubin = lateral if lateral_tetap == INF else lateral_tetap
	if lateral_tetap != INF:
		k.kecepatan_ud = 0.0
	_sepeda.keadaan = k


func _tunggu(jumlah: int) -> void:
	for i: int in range(jumlah):
		await process_frame


func _maju(detik: float, gambar: bool = true) -> void:
	for i: int in range(maxi(roundi(detik / DT), 1)):
		if _akar.sedang_jeda():
			_akar.minta_lanjut()
		if _tahan_jarak >= 0.0:
			_letakkan(_tahan_jarak, 0.0, -1.0)
		_akar.perbarui(DT)
		_sprite.maju(DT)
		_debu.maju(DT)
		_garis.maju(DT)
	if gambar:
		await _tunggu(2)


func _foto(keadaan: String) -> void:
	await _tunggu(3)
	var tut: TutorialController = _akar.tutorial_node()
	print("%s: jarak %.2f, kecepatan %.2f, kartu '%s', banner '%s', petunjuk '%s', tutorial '%s', koin %s, kucing %s, kidal %s" % [keadaan, _sepeda.jarak_ubin, _sepeda.kecepatan_ud, _hud.teks_kartu(), _hud.teks_banner(), _hud.teks_petunjuk(), tut.teks(), _hud.teks_koin(), _akar.kucing().tampil(), _akar.kidal()])
	if _folder.is_empty():
		return
	var gambar: Image = root.get_texture().get_image()
	var berkas: String = "%s/%s_misi_%s.png" % [_folder, _awalan, keadaan]
	var galat: int = gambar.save_png(berkas)
	print("tangkapan layar %dx%d (%s) ke %s (kode %d)" % [gambar.get_width(), gambar.get_height(), keadaan, berkas, galat])
