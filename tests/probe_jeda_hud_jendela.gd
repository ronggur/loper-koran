extends SceneTree
## Probe layar jeda, tutorial, banner, dan HUD rute tata ulang di jendela asli, non-headless (run ui2-semua-layar bagian C3, AC-9; V-9). Memuat `scenes/rute/rute.tscn`, memajukan simulasi dengan langkah tetap
## `perbarui(1/60)` (bukan waktu dinding), lalu memotret:
## - `jeda_*`: layar jeda sakelar mati, kidal nyala, bantu nyala, keduanya nyala (panel 232 di tengah, lapisan 72 %);
## - `tutorial_*`: petunjuk langkah 1 sampai 4 (dengan misi) dan langkah 1 tanpa misi (tiga titik), tombol Lewati peran tenang;
## - `banner_*`: Rute selesai, galat muat (dengan tombol Main lagi), misi selesai, misi gagal, gelembung petunjuk "PELANGGAN:";
## - `hud_*` (awalan `hud_c_`): awal, kecepatan penuh, stamina < 30 (FAIL) dan lelah, koran sedikit dan habis, kondisi AUS, PERLU_BENGKEL dengan "!", peringatan, misi aktif, skor dan combo besar, reputasi 37 dan 100 (satu panel
##   dengan kondisi), terpadat, kidal, inset aman, kidal + inset.
## Mencetak data tiap keadaan dan jumlah keadaan yang tidak sesuai: teks terpotong (label keluar dari panel), elemen di luar layar atau di luar inset, tumpang tindih antar elemen HUD, kolom bawah di dalam zona stick,
## tombol jeda HUD dan sakelar < 42 tinggi atau < 84 lebar (kecuali pengecualian tertulis: area sentuh jeda 42x42 DESIGN_SPEC 3.1, Lewati 64x42 DESIGN_SPEC 3.1), bar kecepatan dan stamina tidak berdampingan, tinggi panel bawah > 40.
## Menulis juga `<awalan>_<jenis>_<keadaan>.json` (persegi teks dan komponen) untuk `tools/ukur_kontras_tangkapan.py --jenis jeda|hud`. Tidak interaktif: keluar lewat `ProbeKeluar`.
##
## Pakai (jendela harus muat di layar monitor):
##   godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_jeda_hud_jendela.gd -- docs/loop/<RUN_ID>/shots/iter<N>
##   (juga 1920x1080, 2400x1080, 1600x720)
## Berkas: `<lebar>x<tinggi>_<jeda|tutorial|banner|hud_c>_<keadaan>.png`.

const BERKAS_RUTE: String = "res://scenes/rute/rute.tscn"
const FRAME_TUNGGU_LAYOUT: int = 5
const DT: float = 1.0 / 60.0
## Inset aman tiruan (piksel game): kiri, atas, kanan, bawah.
const INSET: Array[int] = [10, 14, 11, 20]
## Tinggi panel bawah terbesar yang diizinkan V-9 H-1 (sekitar 34 sampai 40).
const PANEL_BAWAH_TINGGI_MAKS: float = 40.0

var _folder: String = ""
var _awalan: String = ""
var _skala: float = 1.0
var _akar: RuteMain
var _sepeda: SepedaUji
var _hud: HudRute
var _sprite: LoperSprite
var _debu: PancaranPiksel
var _garis: PancaranPiksel
var _misi: DataMisi
var _gagal: int = 0
var _inset_terpasang: bool = false


func _initialize() -> void:
	var argumen: PackedStringArray = OS.get_cmdline_user_args()
	_folder = argumen[0] if argumen.size() > 0 else ""
	_misi = PemuatMisi.muat_folder().cari("p1_kucing")
	await _skenario_jeda()
	await _skenario_tutorial()
	await _skenario_banner()
	await _skenario_hud()
	print("probe selesai, %d keadaan tidak sesuai" % _gagal)
	await ProbeKeluar.keluar(self, 0 if _gagal == 0 else 1)


# --- Jeda ---

func _skenario_jeda() -> void:
	await _pasang(1, false, false)
	await _maju(0.3)
	var layar: LayarJeda = _akar.find_child("LayarJeda", true, false) as LayarJeda
	_akar.minta_jeda()
	await _tunggu(4)
	await _foto("jeda", "mati")
	_cek_jeda(layar, "mati")
	layar.sakelar_kidal().ditekan.emit()
	await _tunggu(3)
	await _foto("jeda", "kidal_nyala")
	_cek_jeda(layar, "kidal_nyala")
	layar.sakelar_bantu().ditekan.emit()
	await _tunggu(3)
	await _foto("jeda", "nyala")
	_cek_jeda(layar, "nyala")
	layar.sakelar_kidal().ditekan.emit()
	await _tunggu(3)
	await _foto("jeda", "bantu_nyala")
	_cek_jeda(layar, "bantu_nyala")
	layar.sakelar_bantu().ditekan.emit()
	await _tunggu(2)
	_akar.minta_lanjut()
	await _bongkar()


func _cek_jeda(layar: LayarJeda, keadaan: String) -> void:
	var salah: int = 0
	var viewport: Rect2 = Rect2(Vector2.ZERO, root.get_visible_rect().size)
	var panel: Rect2 = layar.rect_panel()
	if panel.size.x != float(Config.JEDA_PANEL_LEBAR_PX) or absf(panel.get_center().x - viewport.get_center().x) > 0.5 or not viewport.encloses(panel):
		print("TIDAK SESUAI [jeda %s]: panel %s bukan lebar %d di tengah dalam layar" % [keadaan, panel, Config.JEDA_PANEL_LEBAR_PX])
		salah += 1
	if layar.rect_judul().size.x <= 0.0 or not panel.encloses(layar.rect_judul()):
		print("TIDAK SESUAI [jeda %s]: judul %s di luar panel" % [keadaan, layar.rect_judul()])
		salah += 1
	var tombol: Dictionary = {"lanjut": layar.rect_tombol_lanjut(), "kidal": layar.rect_sakelar_kidal(), "bantu": layar.rect_sakelar_bantu()}
	var nama_urut: Array = tombol.keys()
	for i: int in range(nama_urut.size()):
		var r: Rect2 = tombol[nama_urut[i]]
		if r.size.y < float(Config.UI_TOMBOL_TINGGI_PX) or r.size.x < float(Config.UI_TOMBOL_LEBAR_MIN_PX):
			print("TIDAK SESUAI [jeda %s]: tombol %s %s < 42 tinggi atau < 84 lebar" % [keadaan, nama_urut[i], r.size])
			salah += 1
		if not panel.encloses(r):
			print("TIDAK SESUAI [jeda %s]: tombol %s %s keluar dari panel %s" % [keadaan, nama_urut[i], r, panel])
			salah += 1
		for j: int in range(i + 1, nama_urut.size()):
			if r.intersects(tombol[nama_urut[j]]):
				print("TIDAK SESUAI [jeda %s]: tombol %s dan %s bertumpuk" % [keadaan, nama_urut[i], nama_urut[j]])
				salah += 1
	for pasangan: Array in [[layar.sakelar_kidal(), layar.rect_kenop_kidal(), layar.rect_sakelar_kidal()], [layar.sakelar_bantu(), layar.rect_kenop_bantu(), layar.rect_sakelar_bantu()]]:
		var teks_lebar: float = _lebar_teks(pasangan[0] as Button)
		var r_tombol: Rect2 = pasangan[2]
		var r_kenop: Rect2 = pasangan[1]
		var ruang_teks: float = r_kenop.position.x - r_tombol.position.x - float(Config.UI_TOMBOL_SLICE_SAMPING_PX + Config.UI_TOMBOL_SAKELAR_PAD_X_PX + Config.JEDA_SAKELAR_PAD_TAMBAH_PX)
		if teks_lebar > ruang_teks or not r_tombol.encloses(r_kenop):
			print("TIDAK SESUAI [jeda %s]: teks sakelar %.0f px lebih lebar dari ruang %.0f atau kenop %s di luar tombol" % [keadaan, teks_lebar, ruang_teks, r_kenop])
			salah += 1
	var lanjut: Button = layar.tombol_lanjut()
	var ruang_lanjut: float = layar.rect_tombol_lanjut().size.x - float(2 * Config.UI_TOMBOL_SLICE_SAMPING_PX)
	if _lebar_teks(lanjut) + float(Config.JEDA_LANJUT_JARAK_PX + Config.HUD_JEDA_GLIF_PX) > ruang_lanjut:
		print("TIDAK SESUAI [jeda %s]: teks Lanjut terpotong" % keadaan)
		salah += 1
	var margin_lanjut: int = GayaHud.margin_glif_tombol(lanjut)
	if margin_lanjut != roundi((lanjut.get_theme_stylebox(&"normal") as StyleBox).content_margin_right) + GayaHud.pad_kanan_glif(lanjut) or margin_lanjut < Config.UI_TOMBOL_GLIF_MARGIN_MIN_PX or float(GayaHud.lebar_teks_tombol(lanjut) + lanjut.get_theme_constant(&"h_separation") + lanjut.icon.get_width() + margin_lanjut * 2 - GayaHud.pad_kanan_glif(lanjut)) > lanjut.size.x + 0.01:
		print("TIDAK SESUAI [jeda %s]: panah Lanjut margin %d tidak sama kiri-kanan, di bawah minimum, atau teks terpotong (R-1)" % [keadaan, margin_lanjut])
		salah += 1
	print("jeda [%s]: panel %s, lanjut %s, kidal %s (%s), bantu %s (%s), %d tidak sesuai" % [keadaan, panel, layar.rect_tombol_lanjut(), layar.rect_sakelar_kidal(), tr(layar.sakelar_kidal().text), layar.rect_sakelar_bantu(), tr(layar.sakelar_bantu().text), salah])
	_gagal += salah
	var teks: Array = [
		{"rect": _rect_arr(layar.rect_judul()), "teks": "JEDA"},
		{"rect": _rect_arr(_ruang_teks_tombol(layar.rect_tombol_lanjut(), 0.0, float(Config.HUD_JEDA_GLIF_PX + Config.JEDA_LANJUT_JARAK_PX))), "teks": "Lanjut"},
		{"rect": _rect_arr(_ruang_teks_tombol(layar.rect_sakelar_kidal(), layar.rect_kenop_kidal().size.x, 0.0)), "teks": tr(layar.sakelar_kidal().text)},
		{"rect": _rect_arr(_ruang_teks_tombol(layar.rect_sakelar_bantu(), layar.rect_kenop_bantu().size.x, 0.0)), "teks": tr(layar.sakelar_bantu().text)},
	]
	var komponen: Array = [{"rect": _rect_arr(layar.rect_tombol_lanjut()), "jenis": "tombol_utama"}, {"rect": _rect_arr(layar.rect_sakelar_kidal()), "jenis": "sakelar"}, {"rect": _rect_arr(layar.rect_sakelar_bantu()), "jenis": "sakelar"}]
	_tulis_json("jeda", keadaan, teks, komponen)


# --- Tutorial ---

func _skenario_tutorial() -> void:
	await _pasang(1, true, true)
	await _maju(0.5)
	await _foto("tutorial", "langkah1")
	_cek_tutorial("langkah1", 1)
	var rencana: RencanaMisi.Rencana = _akar.rencana_misi()
	_set_kecepatan(Config.TUTORIAL_KAYUH_KECEPATAN_UD + 0.5)
	await _maju(DT)
	_set_kecepatan(Config.KECEPATAN_SANTAI_UD)
	await _maju(DT)
	await _foto("tutorial", "langkah2")
	_cek_tutorial("langkah2", 2)
	_set_kecepatan(Config.TUTORIAL_MELAMBAT_KECEPATAN_UD - 0.5)
	await _maju(DT)
	await _foto("tutorial", "langkah3")
	_cek_tutorial("langkah3", 3)
	_akar.set(&"_jumlah_lempar", 1)
	_letakkan(rencana.titik[2].maju_ubin - 6.0)
	await _maju(DT)
	await _foto("tutorial", "langkah4")
	_cek_tutorial("langkah4", 4)
	await _bongkar()
	await _pasang(1, false, true)
	await _maju(0.5)
	await _foto("tutorial", "tanpa_misi_langkah1")
	_cek_tutorial("tanpa_misi_langkah1", 1)
	await _bongkar()


func _cek_tutorial(keadaan: String, nomor: int) -> void:
	var tut: TutorialController = _akar.tutorial_node()
	var layar: Rect2 = Rect2(Vector2.ZERO, root.get_visible_rect().size)
	var salah: int = 0
	if not tut.tampil():
		print("TIDAK SESUAI [tutorial %s]: petunjuk tidak tampil" % keadaan)
		_gagal += 1
		return
	if tut.teks_langkah().find("%d/" % nomor) < 0:
		print("TIDAK SESUAI [tutorial %s]: label langkah '%s' bukan langkah %d" % [keadaan, tut.teks_langkah(), nomor])
		salah += 1
	var panel: Rect2 = tut.rect_panel()
	var lewati: Rect2 = tut.rect_lewati()
	if not layar.encloses(panel) or not layar.encloses(lewati):
		print("TIDAK SESUAI [tutorial %s]: panel %s atau Lewati %s di luar layar" % [keadaan, panel, lewati])
		salah += 1
	if lewati.size.y < float(Config.UI_TOMBOL_TINGGI_PX) or lewati.size.x < float(Config.TUTORIAL_LEWATI_LEBAR_PX):
		print("TIDAK SESUAI [tutorial %s]: Lewati %s kurang dari 64x42 (pengecualian tertulis DESIGN_SPEC 3.1)" % [keadaan, lewati.size])
		salah += 1
	for label: Label in _label_di(tut):
		if label.text.is_empty():
			continue
		if not panel.encloses(label.get_global_rect()):
			print("TIDAK SESUAI [tutorial %s]: label '%s' %s keluar dari panel %s" % [keadaan, label.text, label.get_global_rect(), panel])
			salah += 1
	salah += _cek_tumpang(keadaan, {"tutorial": panel, "lewati": lewati}, false)
	print("tutorial [%s]: label '%s', teks '%s', panel %s, lewati %s, %d tidak sesuai" % [keadaan, tut.teks_langkah(), tut.teks(), panel, lewati, salah])
	_gagal += salah
	var teks: Array = []
	for label: Label in _label_di(tut):
		if not label.text.is_empty():
			teks.append({"rect": _rect_arr(label.get_global_rect()), "teks": label.text})
	var teks_lewati: Rect2 = lewati.grow_individual(-float(Config.UI_TOMBOL_SLICE_SAMPING_PX), -float(Config.UI_TOMBOL_SLICE_ATAS_PX), -float(Config.UI_TOMBOL_SLICE_SAMPING_PX), -float(Config.UI_TOMBOL_SLICE_BAWAH_PX))
	teks.append({"rect": _rect_arr(teks_lewati), "teks": "Lewati"})
	_tulis_json("tutorial", keadaan, teks, [{"rect": _rect_arr(lewati), "jenis": "tombol"}])


# --- Banner ---

func _skenario_banner() -> void:
	await _pasang(1, false, false)
	await _maju(0.3)
	# Rute selesai: sepeda melewati garis akhir dan mulai keluar viewport (run garis finish: banner muncul saat HAMPIR KELUAR, sekitar 60 sampai 160 langkah sesudah garis, jadi batas 600 langkah); banner tampil sebelum layar hasil.
	_letakkan(_akar.rute().panjang_ubin - 0.3)
	var batas: int = 0
	while not _akar.panel_akhir().tampil() and batas < 600:
		await _maju(DT, false)
		batas += 1
	await _tunggu(3)
	await _foto("banner", "rute_selesai")
	_cek_banner_akhir("rute_selesai", false)
	_akar.panel_akhir().tampilkan_galat()
	await _tunggu(3)
	await _foto("banner", "galat_muat")
	_cek_banner_akhir("galat_muat", true)
	await _bongkar()
	await _pasang(1, true, false)
	await _maju(0.3)
	var rencana: RencanaMisi.Rencana = _akar.rencana_misi()
	# Misi selesai, gagal, dan petunjuk dari keadaan misi nyata yang disetel langsung (HUD hanya menampilkan `MissionManager.Keadaan`).
	for kasus: Array in [["misi_selesai", MissionManager.Status.SELESAI, 0.0, 1.5], ["misi_gagal", MissionManager.Status.GAGAL, 0.0, 1.5], ["petunjuk", MissionManager.Status.AKTIF, 2.5, 0.0]]:
		var k: MissionManager.Keadaan = MissionManager.awal(rencana)
		k.status = kasus[1]
		k.petunjuk_sisa = kasus[2]
		k.banner_sisa = kasus[3]
		_hud.tampilkan_misi(k, _misi)
		await _tunggu(3)
		await _foto("banner", String(kasus[0]))
		var salah: int = 0
		var elemen: Dictionary = {}
		if _hud.banner_tampil():
			elemen["banner"] = _hud.rect_banner()
		if _hud.petunjuk_tampil():
			elemen["petunjuk"] = _hud.rect_petunjuk()
		if elemen.is_empty():
			print("TIDAK SESUAI [banner %s]: banner/petunjuk tidak tampil" % kasus[0])
			salah += 1
		salah += _cek_tumpang(String(kasus[0]), elemen, false)
		print("banner [%s]: banner '%s', petunjuk '%s', %s, %d tidak sesuai" % [kasus[0], _hud.teks_banner(), _hud.teks_petunjuk(), elemen, salah])
		_gagal += salah
		var teks: Array = []
		for label: Label in _label_di(_hud):
			if label.is_visible_in_tree() and not label.text.is_empty() and (label.name == &"TeksBanner" or label.name == &"TeksPetunjuk" or label.name == &"LabelPelanggan"):
				teks.append({"rect": _rect_arr(label.get_global_rect()), "teks": label.text})
		_tulis_json("banner", String(kasus[0]), teks, [])
	await _bongkar()


func _cek_banner_akhir(keadaan: String, galat: bool) -> void:
	var panel: PanelAkhirRute = _akar.panel_akhir()
	var layar: Rect2 = Rect2(Vector2.ZERO, root.get_visible_rect().size)
	var salah: int = 0
	var banner: Rect2 = panel.rect_banner()
	if not panel.tampil() or not layar.encloses(banner):
		print("TIDAK SESUAI [banner %s]: banner tidak tampil atau di luar layar %s" % [keadaan, banner])
		salah += 1
	if galat != panel.tombol_tampil():
		print("TIDAK SESUAI [banner %s]: tombol Main lagi %s" % [keadaan, panel.tombol_tampil()])
		salah += 1
	if galat:
		var tombol: Rect2 = panel.rect_tombol()
		if tombol.size.y < float(Config.UI_TOMBOL_TINGGI_PX) or tombol.size.x < float(Config.UI_TOMBOL_LEBAR_MIN_PX) or not banner.encloses(tombol):
			print("TIDAK SESUAI [banner %s]: tombol Main lagi %s kurang dari 84x42 atau keluar banner" % [keadaan, tombol])
			salah += 1
	# Banner di tengah atas di bawah panel progres, tidak menumpuk radar, panel kanan atas, kartu misi, tombol jeda, bel.
	salah += _cek_tumpang(keadaan, {"banner_akhir": banner}, false)
	print("banner [%s]: teks '%s', banner %s, %d tidak sesuai" % [keadaan, panel.teks_banner(), banner, salah])
	_gagal += salah
	var teks: Array = [{"rect": _rect_arr(_akar.panel_akhir().find_child("JudulAkhir", true, false).get_global_rect()), "teks": panel.teks_banner()}]
	var komponen: Array = []
	if galat:
		komponen.append({"rect": _rect_arr(panel.rect_tombol()), "jenis": "tombol_utama"})
	_tulis_json("banner", keadaan, teks, komponen)


# --- HUD ---

func _skenario_hud() -> void:
	await _pasang(1, true, false)
	await _maju(0.5)
	await _hud_foto("awal")
	_hud.tampilkan_kecepatan(Config.KECEPATAN_NGEBUT_UD)
	await _hud_foto("kecepatan_penuh")
	_cek_tanda("kecepatan_penuh")
	_hud.tampilkan_kecepatan(Config.KECEPATAN_SANTAI_UD)
	_hud.tampilkan_stamina(Config.HUD_STAMINA_AMBANG_RENDAH + 0.5, false)
	await _hud_foto("stamina_batas_atas")
	_hud.tampilkan_stamina(Config.HUD_STAMINA_AMBANG_RENDAH - 0.5, false)
	await _hud_foto("stamina_rendah")
	_harap("stamina < 30 FAIL", _hud.warna_stamina() == Palette.FAIL, str(_hud.warna_stamina()))
	_hud.tampilkan_stamina(5.0, true)
	await _hud_foto("stamina_lelah")
	_harap("lelah tampil", _hud.penanda_lelah_tampil(), "")
	_hud.tampilkan_stamina(Config.STAMINA_MAKS, false)
	_hud.tampilkan_koran(3, Config.KORAN_AWAL)
	await _hud_foto("koran_sedikit")
	_hud.tampilkan_koran(0, Config.KORAN_AWAL)
	await _hud_foto("koran_habis")
	_harap("habis tampil", _hud.penanda_habis_tampil(), "")
	_hud.tampilkan_koran(Config.KORAN_AWAL, Config.KORAN_AWAL)
	_hud.tampilkan_kondisi(_kondisi(0.6, 0.5, 0.65, {}))
	await _hud_foto("kondisi_aus")
	_hud.tampilkan_kondisi(_kondisi(0.2, 0.3, 0.0, {}))
	await _hud_foto("kondisi_perlu_bengkel")
	_hud.tampilkan_kondisi(_kondisi(0.6, 0.5, 0.2, {"ban": 1.0}))
	await _hud_foto("kondisi_peringatan")
	_hud.tampilkan_kondisi(_kondisi(1.0, 1.0, 1.0, {}))
	_hud.tampilkan_reputasi(37)
	await _hud_foto("reputasi_37")
	_harap("reputasi di dalam panel baris 2", _hud.rect_panel_kondisi().encloses(_hud.rect_panel_reputasi()), str(_hud.rect_panel_reputasi()))
	_hud.tampilkan_reputasi(100)
	await _hud_foto("reputasi_100")
	_hud.tampilkan_skor(1234567, 12, 987654, false)
	await _hud_foto("skor_besar")
	_hud.tampilkan_skor(1234567, 0, 987654, true)
	await _hud_foto("combo_putus")
	_hud.tampilkan_skor(120, 2, 45, false)
	_hud.tampilkan_reputasi(37)
	_hud.tampilkan_kondisi(_kondisi(0.2, 0.3, 0.0, {"rem": 1.0}))
	_hud.tampilkan_kecepatan(5.4)
	_hud.tampilkan_stamina(12.0, true)
	_hud.tampilkan_koran(0, Config.KORAN_AWAL)
	await _hud_foto("terpadat_awal")
	# Misi aktif nyata (kartu), lalu petunjuk di slot banner, di atas keadaan terpadat.
	await _maju(0.1)
	var rencana: RencanaMisi.Rencana = _akar.rencana_misi()
	var k: MissionManager.Keadaan = MissionManager.awal(rencana)
	k.petunjuk_sisa = 2.5
	_hud.tampilkan_misi(k, _misi)
	_hud.tampilkan_skor(1234567, 12, 987654, false)
	_hud.tampilkan_reputasi(100)
	_hud.tampilkan_kondisi(_kondisi(0.2, 0.3, 0.0, {"rem": 1.0}))
	_hud.tampilkan_kecepatan(5.4)
	_hud.tampilkan_stamina(12.0, true)
	_hud.tampilkan_koran(0, Config.KORAN_AWAL)
	await _hud_foto("terpadat_misi_petunjuk")
	_akar.atur_kidal(true)
	await _maju(DT, false)
	_pulihkan_terpadat(rencana)
	await _hud_foto("terpadat_kidal")
	_pasang_inset(true)
	await _maju(DT, false)
	_pulihkan_terpadat(rencana)
	await _hud_foto("terpadat_kidal_inset")
	_akar.atur_kidal(false)
	await _maju(DT, false)
	_pulihkan_terpadat(rencana)
	await _hud_foto("terpadat_inset")
	_pasang_inset(false)
	await _bongkar()


## Mengatur ulang HUD terpadat sesudah `_maju` (perbarui menulis ulang nilai dari simulasi).
func _pulihkan_terpadat(rencana: RencanaMisi.Rencana) -> void:
	var k: MissionManager.Keadaan = MissionManager.awal(rencana)
	k.petunjuk_sisa = 2.5
	_hud.tampilkan_misi(k, _misi)
	_hud.tampilkan_skor(1234567, 12, 987654, false)
	_hud.tampilkan_reputasi(100)
	_hud.tampilkan_kondisi(_kondisi(0.2, 0.3, 0.0, {"rem": 1.0}))
	_hud.tampilkan_kecepatan(5.4)
	_hud.tampilkan_stamina(12.0, true)
	_hud.tampilkan_koran(0, Config.KORAN_AWAL)


func _pasang_inset(nyala: bool) -> void:
	_inset_terpasang = nyala
	var inset: ZonaAman.Inset = null
	if nyala:
		inset = ZonaAman.Inset.new()
		inset.awal_x = INSET[0]
		inset.atas = INSET[1]
		inset.akhir_x = INSET[2]
		inset.bawah = INSET[3]
	_hud.atur_inset(inset)


func _kondisi(ban: float, rem: float, rantai: float, kedip: Dictionary) -> KondisiRute.Keadaan:
	var k: KondisiRute.Keadaan = KondisiRute.Keadaan.new()
	k.kondisi = {"ban": ban, "rem": rem, "rantai": rantai}
	k.kedip = kedip
	return k


func _hud_foto(keadaan: String) -> void:
	await _tunggu(3)
	await _foto("hud_c", keadaan)
	_cek_hud(keadaan)
	var teks: Array = []
	for label: Label in _label_di(_hud):
		if label.is_visible_in_tree() and not label.text.is_empty():
			teks.append({"rect": _rect_arr(label.get_global_rect()), "teks": label.text})
	_tulis_json("hud_c", keadaan, teks, [])


func _cek_tanda(keadaan: String) -> void:
	var bar: BarKecepatan = _hud.bar_kecepatan()
	var tanda: Rect2 = bar.rect_tanda()
	var dalam: float = bar.size.x - 2.0
	var harapan: float = 1.0 + floorf(dalam * Config.HUD_BAR_TANDA_PECAHAN)
	_harap("tanda 90 %% di x %.0f (dapat %.0f) setinggi bar" % [harapan, tanda.position.x], tanda.position.x == harapan and tanda.size.y == bar.size.y and tanda.size.x == 1.0, str(tanda))
	_harap("bar stamina tanpa tanda", _hud.bar_stamina().tanda <= 0.0, "")
	print("tanda bar kecepatan [%s]: %s di bar %s (90 %% dari %.0f px isi)" % [keadaan, tanda, bar.size, dalam])


## Semua kontrol HUD: di dalam layar (dan di luar inset), tidak bertumpuk, kolom bawah di luar zona stick, panel bawah <= 40 tinggi, bar berdampingan, label tidak keluar panel, tombol jeda >= 42.
func _cek_hud(keadaan: String) -> void:
	var layar: Rect2 = Rect2(Vector2.ZERO, root.get_visible_rect().size)
	var lebar: int = int(layar.size.x)
	var kidal: bool = _akar.kidal()
	var salah: int = 0
	var aman: Rect2 = layar
	if _inset_terpasang:
		aman = Rect2(float(INSET[0]), float(INSET[1]), layar.size.x - float(INSET[0] + INSET[2]), layar.size.y - float(INSET[1] + INSET[3]))
	var elemen: Dictionary = {
		"radar_seberang": _hud.rect_radar_seberang(), "radar_dekat": _hud.rect_radar_dekat(), "panel_progres": _hud.rect_panel_progres(), "panel_koin": _hud.rect_panel_koin(), "panel_skor": _hud.rect_panel_skor(),
		"panel_baris2": _hud.rect_panel_kondisi(), "tombol_jeda": _hud.rect_tombol_jeda(), "panel_kecepatan": _hud.rect_panel_kecepatan(), "panel_koran": _hud.rect_panel_koran(),
		"zona_bel": Rect2(TouchZones.pusat_bel(lebar, kidal, _akar.kontrol_router().geser_bel) - Vector2.ONE * Config.BEL_ZONA_RADIUS_PX, Vector2.ONE * Config.BEL_ZONA_RADIUS_PX * 2),
	}
	if _hud.kartu_tampil():
		elemen["kartu_misi"] = _hud.rect_kartu()
	if _hud.banner_tampil():
		elemen["banner"] = _hud.rect_banner()
	if _hud.petunjuk_tampil():
		elemen["petunjuk"] = _hud.rect_petunjuk()
	for nama: String in elemen:
		var r: Rect2 = elemen[nama]
		if not layar.encloses(r):
			print("TIDAK SESUAI [hud %s]: %s %s di luar layar" % [keadaan, nama, r])
			salah += 1
		if _inset_terpasang and nama in ["panel_progres", "panel_koin", "panel_skor", "panel_baris2", "panel_kecepatan", "panel_koran", "zona_bel", "radar_seberang", "radar_dekat"] and not aman.encloses(r):
			print("TIDAK SESUAI [hud %s]: %s %s di luar zona aman %s" % [keadaan, nama, r, aman])
			salah += 1
	salah += _cek_tumpang(keadaan, elemen, true)
	var stick: Rect2 = TouchZones.rect_stick(lebar, kidal)
	for nama: String in ["panel_kecepatan", "panel_koran"]:
		if (elemen[nama] as Rect2).intersects(stick, true):
			print("TIDAK SESUAI [hud %s]: %s masuk zona stick %s" % [keadaan, nama, stick])
			salah += 1
		if (elemen[nama] as Rect2).size.y > PANEL_BAWAH_TINGGI_MAKS:
			print("TIDAK SESUAI [hud %s]: %s tinggi %.0f > 40" % [keadaan, nama, (elemen[nama] as Rect2).size.y])
			salah += 1
	var bar_k: Rect2 = _hud.rect_bar_kecepatan()
	var bar_s: Rect2 = _hud.rect_bar_stamina()
	if bar_s.position.x < bar_k.end.x or absf(bar_s.position.y - bar_k.position.y) > 0.5 or bar_s.size.y != float(Config.HUD_BAR_TINGGI_PX) or bar_k.size.y != float(Config.HUD_BAR_TINGGI_PX):
		print("TIDAK SESUAI [hud %s]: bar kecepatan %s dan stamina %s tidak berdampingan setinggi %d" % [keadaan, bar_k, bar_s, Config.HUD_BAR_TINGGI_PX])
		salah += 1
	for label: Label in _hud.label_bawah():
		if not label.is_visible_in_tree():
			continue
		var wadah: Rect2 = _hud.rect_panel_koran() if label.name in [&"LabelKoran", &"LabelHabis", &"AngkaKoran"] else _hud.rect_panel_kecepatan()
		if not wadah.encloses(label.get_global_rect()) or label.get_global_rect().size.x + 0.5 < label.get_minimum_size().x:
			print("TIDAK SESUAI [hud %s]: label '%s' %s terpotong atau keluar panel %s" % [keadaan, label.text, label.get_global_rect(), wadah])
			salah += 1
	if _hud.reputasi_tampil() and not _hud.rect_panel_kondisi().encloses(_hud.rect_panel_reputasi()):
		print("TIDAK SESUAI [hud %s]: reputasi %s keluar dari panel baris 2 %s" % [keadaan, _hud.rect_panel_reputasi(), _hud.rect_panel_kondisi()])
		salah += 1
	var jeda: Rect2 = _hud.rect_tombol_jeda()
	if jeda.size.x < 42.0 or jeda.size.y < 42.0:
		print("TIDAK SESUAI [hud %s]: area sentuh tombol jeda %s < 42x42" % [keadaan, jeda.size])
		salah += 1
	print("hud [%s]: kidal %s, inset %s, panel kecepatan %s, koran %s, baris2 %s, bar %s | %s, reputasi %s, jeda %s, %d tidak sesuai" % [keadaan, kidal, _inset_terpasang, _hud.rect_panel_kecepatan(), _hud.rect_panel_koran(), _hud.rect_panel_kondisi(), bar_k, bar_s, _hud.teks_reputasi(), jeda, salah])
	_gagal += salah


## Tumpang tindih antar `elemen` (dan terhadap elemen HUD tetap bila `hanya_antar` false): jumlah pelanggaran.
func _cek_tumpang(keadaan: String, elemen: Dictionary, hanya_antar: bool) -> int:
	var salah: int = 0
	var lain: Dictionary = {}
	if not hanya_antar:
		lain = {"radar_seberang": _hud.rect_radar_seberang(), "radar_dekat": _hud.rect_radar_dekat(), "panel_progres": _hud.rect_panel_progres(), "panel_koin": _hud.rect_panel_koin(), "panel_skor": _hud.rect_panel_skor(),
			"panel_baris2": _hud.rect_panel_kondisi(), "tombol_jeda": _hud.rect_tombol_jeda(), "tombol_bel": _hud.rect_tombol_bel(), "panel_kecepatan": _hud.rect_panel_kecepatan(), "panel_koran": _hud.rect_panel_koran()}
		if _hud.kartu_tampil():
			lain["kartu_misi"] = _hud.rect_kartu()
	var nama_urut: Array = elemen.keys()
	for i: int in range(nama_urut.size()):
		var r: Rect2 = elemen[nama_urut[i]]
		for nama_lain: String in lain:
			if r.intersects(lain[nama_lain]) and nama_lain != String(nama_urut[i]):
				print("TIDAK SESUAI [%s]: %s %s menumpuk %s %s" % [keadaan, nama_urut[i], r, nama_lain, lain[nama_lain]])
				salah += 1
		for j: int in range(i + 1, nama_urut.size()):
			if r.intersects(elemen[nama_urut[j]]):
				print("TIDAK SESUAI [%s]: %s %s menumpuk %s %s" % [keadaan, nama_urut[i], r, nama_urut[j], elemen[nama_urut[j]]])
				salah += 1
	return salah


# --- Pembantu ---

func _pasang(hari: int, dengan_misi: bool, tutorial: bool) -> void:
	_akar = (load(BERKAS_RUTE) as PackedScene).instantiate() as RuteMain
	_akar.atur_benih_awal(SeedHari.rute(hari))
	if dengan_misi:
		_akar.atur_misi(_misi)
	_akar.atur_tutorial(tutorial)
	root.add_child(_akar)
	await _tunggu(FRAME_TUNGGU_LAYOUT)
	_akar.set_process(false)
	var terlihat: Vector2 = root.get_visible_rect().size
	_skala = float(root.size.x) / terlihat.x
	_awalan = "%dx%d" % [root.size.x, root.size.y]
	_sepeda = _akar.find_child("Sepeda", true, false) as SepedaUji
	_hud = _akar.hud_rute()
	_sprite = _akar.find_child("LoperAgen", true, false) as LoperSprite
	_sprite.set_process(false)
	_debu = _sepeda.umpan_balik().debu()
	_garis = _sepeda.umpan_balik().garis()
	_debu.set_process(false)
	_garis.set_process(false)
	(_akar.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = false
	_inset_terpasang = false


func _bongkar() -> void:
	if _akar.sedang_jeda():
		_akar.minta_lanjut()
	root.remove_child(_akar)
	_akar.free()
	_akar = null
	await _tunggu(2)


func _harap(nama: String, kondisi: bool, rincian: String) -> void:
	if not kondisi:
		print("TIDAK SESUAI: %s (%s)" % [nama, rincian])
		_gagal += 1


## Lebar teks tombol (terjemahan) dengan font tema tombol.
func _lebar_teks(tombol: Button) -> float:
	var font: Font = tombol.get_theme_font(&"font")
	return font.get_string_size(tr(tombol.text), HORIZONTAL_ALIGNMENT_LEFT, -1, tombol.get_theme_font_size(&"font_size")).x


## Persegi tempat teks tombol (untuk ukur kontras): wajah tombol dikurangi tepi 9-slice, kenop di ujung akhir, dan glif.
func _ruang_teks_tombol(r: Rect2, kenop_lebar: float, glif_lebar: float) -> Rect2:
	var tepi: float = float(Config.UI_TOMBOL_SLICE_SAMPING_PX + Config.UI_TOMBOL_SAKELAR_PAD_X_PX + (Config.JEDA_SAKELAR_PAD_TAMBAH_PX if kenop_lebar > 0.0 else 0))
	var ujung: float = tepi + (kenop_lebar + float(Config.UI_TOMBOL_SAKELAR_PAD_X_PX) if kenop_lebar > 0.0 else glif_lebar)
	var atas: float = float(Config.UI_TOMBOL_SLICE_ATAS_PX)
	return Rect2(r.position + Vector2(tepi, atas), Vector2(maxf(r.size.x - tepi - ujung, 1.0), r.size.y - atas - float(Config.UI_TOMBOL_SLICE_BAWAH_PX)))


## Semua `Label` di bawah `akar` (termasuk yang tersembunyi).
func _label_di(akar: Node) -> Array[Label]:
	var hasil: Array[Label] = []
	for node: Node in akar.find_children("*", "Label", true, false):
		hasil.append(node as Label)
	return hasil


func _rect_arr(r: Rect2) -> Array:
	return [r.position.x, r.position.y, r.size.x, r.size.y]


func _tulis_json(jenis: String, keadaan: String, teks: Array, komponen: Array) -> void:
	if _folder.is_empty():
		return
	var berkas: FileAccess = FileAccess.open("%s/%s_%s_%s.json" % [_folder, _awalan, jenis, keadaan], FileAccess.WRITE)
	if berkas != null:
		berkas.store_string(JSON.stringify({"viewport": [root.get_visible_rect().size.x, root.get_visible_rect().size.y], "teks": teks, "komponen": komponen}))


func _set_kecepatan(kecepatan: float) -> void:
	var k: BikeMotion.Keadaan = _sepeda.keadaan.salin()
	k.kecepatan_ud = kecepatan
	_sepeda.keadaan = k


func _letakkan(maju: float) -> void:
	_sepeda.jarak_ubin = maxf(maju, 0.0)
	var k: BikeMotion.Keadaan = _sepeda.keadaan.salin()
	k.lateral_ubin = 0.5
	_sepeda.keadaan = k


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


func _foto(jenis: String, keadaan: String) -> void:
	await _tunggu(3)
	if _folder.is_empty():
		return
	var gambar: Image = root.get_texture().get_image()
	var berkas: String = "%s/%s_%s_%s.png" % [_folder, _awalan, jenis, keadaan]
	var galat: int = gambar.save_png(berkas)
	print("tangkapan layar %dx%d (%s_%s) ke %s (kode %d)" % [gambar.get_width(), gambar.get_height(), jenis, keadaan, berkas, galat])
