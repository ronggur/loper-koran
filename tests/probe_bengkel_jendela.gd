extends SceneTree
## Probe layar bengkel tata C di jendela asli, non-headless (AC-10 run ui1-komponen-bengkel bagian B; sebelumnya AC-30 run fase6a1-bengkel-kondisi bagian B): memuat `scenes/bengkel/bengkel.tscn` dengan state
## tulisan probe dan data upgrade nyata, lalu memotret keadaan kanvas a sampai g (a hari pertama, b ban dan rem perlu servis, c saldo kurang, d sesudah beli upgrade, e terpadat, f galat data upgrade,
## g inset aman), sesudah servis, dan upgrade bertingkat I, II, III (data uji dari upgrades.json + dua tingkat ban; `upgrades.json` tidak berubah). Servis dan Beli ditekan lewat `pressed.emit()` (kode asli).
## Mencetak data tiap keadaan dan jumlah keadaan yang tidak sesuai: elemen di luar layar atau zona aman, bertumpuk, tombol < 42 tinggi atau < 84 lebar ("Hari berikutnya" < 140), teks terpotong
## (baris, tinggi, lebar), kartu yang menutupi "Hari berikutnya" (V-8, juga dengan inset aman), chip di luar kartunya, chip kondisi di luar panggung sepeda atau titik di luar gambar sepeda, dan kolom tidak sama dengan `TampilBengkel.lebar_kolom`. Menulis juga
## `<awalan>_bengkel_<keadaan>.json` (persegi dan warna token tiap teks, persegi kartu, tombol, chip) yang dibaca `tools/ukur_kontras_tangkapan.py` untuk mengukur kontras dari tangkapan nyata.
## Tidak interaktif: keluar lewat `ProbeKeluar`.
##
## Pakai (jendela harus muat di layar monitor):
##   godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_bengkel_jendela.gd -- docs/loop/<RUN_ID>/shots/iter<N>
##   (juga 1920x1080 = lebar 640, 2400x1080 = lebar 800 dan 1600x720 = lebar 800; lebar 667 dan 700 hanya di tes: 2001x1080 dan 2100x1080)
## Berkas: `<lebar>x<tinggi>_bengkel_<keadaan>.png`.

const BERKAS_BENGKEL: String = "res://scenes/bengkel/bengkel.tscn"

var _folder: String = ""
var _awalan: String = ""
var _gagal: int = 0
var _toko: PemuatToko.Kumpulan = PemuatToko.muat()
var _inset: ZonaAman.Inset = ZonaAman.Inset.new()


func _initialize() -> void:
	var argumen: PackedStringArray = OS.get_cmdline_user_args()
	_folder = argumen[0] if argumen.size() > 0 else ""
	await _kasus("a_baru", _state(375, 1.0, 1.0, 1.0))
	await _kasus("b_ada_rusak", _state(1000, 0.30, 0.20, 0.60))
	await _kasus("c_saldo_kurang", _state(60, 0.30, 0.60, 1.0))
	await _kasus("d_sesudah_beli", _state(1100, 0.60, 1.0, 1.0), ["beli:ban_anti_selip"])
	await _kasus("e_terpadat", _state(125480, 0.1, 0.2, 0.3))
	await _kasus("f_galat_data", _state(1000, 0.30, 0.20, 0.60), [], PemuatToko.parse_teks("{bukan json", "upgrades.json"))
	await _kasus("sesudah_servis", _state(1000, 0.30, 0.20, 0.75), ["servis:ban"])
	var bertingkat: PemuatToko.Kumpulan = _toko_bertingkat()
	await _kasus("tingkat_1", _state(5000, 0.6, 1.0, 1.0), [], bertingkat)
	await _kasus("tingkat_2", _state(5000, 0.6, 1.0, 1.0, 1), [], bertingkat)
	await _kasus("tingkat_3_dimiliki", _state(100, 0.1, 0.2, 0.3, 3), [], bertingkat)
	_inset.awal_x = 36
	_inset.akhir_x = 24
	_inset.atas = 16
	_inset.bawah = 20
	await _kasus("g_inset_aman", _state(1000, 0.30, 0.20, 0.60))
	print("probe selesai, %d keadaan tidak sesuai" % _gagal)
	await ProbeKeluar.keluar(self, 0 if _gagal == 0 else 1)


func _state(koin: int, ban: float, rem: float, rantai: float, level_ban: int = 0) -> Dictionary:
	var s: Dictionary = DataSave.templat()
	s["koin"] = koin
	s["koin_total"] = koin
	var sepeda: Dictionary = s["sepeda"]
	var daftar: Array = [ban, rem, rantai]
	for i: int in range(3):
		var entri: Dictionary = sepeda[Config.KONDISI_KOMPONEN[i]]
		entri["kondisi"] = daftar[i]
	(sepeda["ban"] as Dictionary)["level"] = level_ban
	return s


## Data uji: upgrade nyata + dua tingkat tambahan untuk ban (hanya di memori probe).
func _toko_bertingkat() -> PemuatToko.Kumpulan:
	var k: PemuatToko.Kumpulan = PemuatToko.muat()
	for tingkat: int in [2, 3]:
		var d: DataToko.Hasil = DataToko.parse({
			"id": "ban_anti_selip_%d" % tingkat, "komponen": "ban", "level": tingkat, "harga": 600 + 300 * (tingkat - 1),
			"nama": "TOKO_BAN_ANTI_SELIP_NAMA", "deskripsi": "TOKO_BAN_ANTI_SELIP_DESKRIPSI", "efek": [{"jenis": "pengali_lateral", "nilai": 1.15}],
		})
		if d.upgrade != null:
			k.upgrade.append(d.upgrade)
	return k


## Satu keadaan: bengkel dengan `state`, aksi (servis:<komponen>, beli:<id>) ditekan, difoto, diperiksa.
func _kasus(nama: String, state: Dictionary, aksi: Array = [], toko: PemuatToko.Kumpulan = null) -> void:
	var layar: LayarBengkel = (load(BERKAS_BENGKEL) as PackedScene).instantiate() as LayarBengkel
	root.add_child(layar)
	await _tunggu(3)
	layar.atur_inset(_inset)
	layar.isi(state, toko if toko != null else _toko)
	await _tunggu(5)
	_awalan = "%dx%d" % [root.size.x, root.size.y]
	for a: String in aksi:
		var bagian: PackedStringArray = a.split(":")
		if bagian[0] == "servis":
			layar.tombol_servis(bagian[1]).pressed.emit()
		else:
			layar.tombol_beli(bagian[1]).pressed.emit()
	await _tunggu(5)
	await _simpan(nama)
	_periksa(nama, layar)
	_tulis_ukuran(nama, layar)
	layar.queue_free()
	await _tunggu(2)


func _periksa(nama: String, layar: LayarBengkel) -> void:
	var visible_rect: Rect2 = root.get_visible_rect()
	var lebar: float = visible_rect.size.x
	var awal: float = float(maxi(Config.BENGKEL_MARGIN_PX, _inset.awal_x))
	var akhir: float = lebar - float(maxi(Config.BENGKEL_MARGIN_PX, _inset.akhir_x))
	var atas: float = float(maxi(Config.BENGKEL_MARGIN_PX, _inset.atas))
	var bawah: float = visible_rect.size.y - float(maxi(Config.BENGKEL_MARGIN_PX, _inset.bawah))
	var aman: Rect2 = Rect2(awal, atas, akhir - awal, bawah - atas)
	var semua: Array[Rect2] = layar.rect_tampil()
	var salah: int = 0
	for r: Rect2 in semua:
		if not aman.grow(0.5).encloses(r):
			print("TIDAK SESUAI [%s]: elemen %s di luar zona aman %s" % [nama, r, aman])
			salah += 1
	for i: int in range(semua.size()):
		for j: int in range(i + 1, semua.size()):
			if semua[i].intersects(semua[j]):
				print("TIDAK SESUAI [%s]: %s menumpuk %s" % [nama, semua[i], semua[j]])
				salah += 1
	for tombol: TombolSentuh in layar.semua_tombol():
		if not tombol.is_visible_in_tree():
			continue
		var r: Rect2 = tombol.get_global_rect()
		var lebar_min: float = float(Config.BENGKEL_HARI_LEBAR_PX) if tombol == layar.tombol_hari_berikutnya() else 84.0
		if r.size.y < 42.0 or r.size.x < lebar_min:
			print("TIDAK SESUAI [%s]: tombol %s < 42 tinggi atau < %d lebar" % [nama, r, int(lebar_min)])
			salah += 1
		if tombol.size.x + 0.5 < tombol.get_minimum_size().x:
			print("TIDAK SESUAI [%s]: teks tombol '%s' terpotong (%.1f < %.1f)" % [nama, tombol.text, tombol.size.x, tombol.get_minimum_size().x])
			salah += 1
	var hari: Button = layar.tombol_hari_berikutnya()
	var margin_hari: int = GayaHud.margin_glif_tombol(hari)
	if margin_hari != roundi((hari.get_theme_stylebox(&"normal") as StyleBox).content_margin_right) or margin_hari < Config.UI_TOMBOL_GLIF_MARGIN_MIN_PX or float(GayaHud.lebar_teks_tombol(hari) + hari.get_theme_constant(&"h_separation") + hari.icon.get_width() + margin_hari * 2) > hari.size.x + 0.01:
		print("TIDAK SESUAI [%s]: panah 'Hari berikutnya' margin %d tidak sama kiri-kanan, di bawah minimum, atau teks terpotong (R-1)" % [nama, margin_hari])
		salah += 1
	for simpul: Node in layar.find_children("*", "Label", true, false):
		var label: Label = simpul as Label
		if not label.is_visible_in_tree() or label.text == "":
			continue
		var perlu: float = float(label.get_line_count()) * float(label.get_line_height())
		if label.get_visible_line_count() != label.get_line_count() or label.size.y + 0.5 < perlu or (label.autowrap_mode == TextServer.AUTOWRAP_OFF and label.size.x + 0.5 < label.get_minimum_size().x):
			print("TIDAK SESUAI [%s]: teks terpotong '%s' (label %s, perlu tinggi %.1f)" % [nama, label.text, label.size, perlu])
			salah += 1
	for r_kartu: Rect2 in layar.rect_kartu():
		if r_kartu.intersects(layar.rect_tombol_hari()):
			print("TIDAK SESUAI [%s]: kartu %s menutupi 'Hari berikutnya' %s" % [nama, r_kartu, layar.rect_tombol_hari()])
			salah += 1
	salah += _periksa_chip(nama, layar)
	var kolom: Vector2i = TampilBengkel.lebar_kolom(int(akhir - awal))
	if absf(layar.rect_panel_servis().size.x - float(kolom.x)) > 0.5 or absf(layar.rect_kolom_upgrade().size.x - float(kolom.y)) > 0.5:
		print("TIDAK SESUAI [%s]: kolom %.1f dan %.1f, seharusnya %d dan %d" % [nama, layar.rect_panel_servis().size.x, layar.rect_kolom_upgrade().size.x, kolom.x, kolom.y])
		salah += 1
	print("bengkel [%s]: saldo %s, belanja %d, isi %s, panel servis %s, kolom upgrade %s, tombol hari %s, ongkos '%s', %d tidak sesuai" % [nama, layar.teks_saldo(), layar.belanja_koin(), layar.rect_isi(), layar.rect_panel_servis(), layar.rect_kolom_upgrade(), layar.rect_tombol_hari(), layar.teks_ongkos(), salah])
	print("teks: %s" % [" | ".join(layar.teks_tampil())])
	_gagal += salah


## Chip di dalam kartunya dan chip kondisi di dalam panggung sepeda (titik di dalam gambar sepeda).
func _periksa_chip(nama: String, layar: LayarBengkel) -> int:
	var salah: int = 0
	for panel: Control in _semua_kartu(layar):
		for r: Rect2 in layar.rect_chip_di(panel):
			if not panel.get_global_rect().grow(0.5).encloses(r):
				print("TIDAK SESUAI [%s]: chip %s di luar kartu %s" % [nama, r, panel.get_global_rect()])
				salah += 1
	var p: PanggungSepeda = layar.panggung()
	for id: String in Config.KONDISI_KOMPONEN:
		if not p.chip_tampil(id):
			continue
		if not p.rect_panggung().grow(0.5).encloses(p.rect_chip(id)):
			print("TIDAK SESUAI [%s]: chip kondisi %s %s di luar panggung sepeda %s" % [nama, id, p.rect_chip(id), p.rect_panggung()])
			salah += 1
		if not p.rect_sepeda().grow(0.5).encloses(p.rect_titik_global(id).grow(-1)):
			print("TIDAK SESUAI [%s]: titik penanda %s di luar gambar sepeda" % [nama, id])
			salah += 1
	return salah


func _semua_kartu(layar: LayarBengkel) -> Array[Control]:
	var hasil: Array[Control] = []
	for id: String in Config.KONDISI_KOMPONEN:
		hasil.append(layar.kartu_servis(id).panel)
		var kartu_u: LayarBengkel.KartuUpgrade = layar.kartu_upgrade_komponen(id)
		if kartu_u != null:
			hasil.append(kartu_u.panel)
	return hasil


## Persegi dan warna token tiap teks dan komponen ke `<awalan>_bengkel_<keadaan>.json` untuk `tools/ukur_kontras_tangkapan.py` (hanya bila folder keluaran diberikan).
func _tulis_ukuran(nama: String, layar: LayarBengkel) -> void:
	if _folder.is_empty():
		return
	var teks: Array = []
	for simpul: Node in layar.find_children("*", "Label", true, false):
		var label: Label = simpul as Label
		if label.is_visible_in_tree() and label.text != "":
			var r: Rect2 = label.get_global_rect()
			teks.append({"teks": label.text, "rect": [r.position.x, r.position.y, r.size.x, r.size.y], "warna": "#" + label.get_theme_color(&"font_color").to_html(false)})
	for simpul: Node in layar.find_children("*", "Button", true, false):
		var tombol: Button = simpul as Button
		if tombol.is_visible_in_tree() and tombol.text != "":
			var r2: Rect2 = tombol.get_global_rect()
			var kunci: StringName = &"font_disabled_color" if tombol.disabled else &"font_color"
			teks.append({"teks": tombol.text, "rect": [r2.position.x, r2.position.y, r2.size.x, r2.size.y], "warna": "#" + tombol.get_theme_color(kunci).to_html(false)})
	var komponen: Array = []
	for tombol2: TombolSentuh in layar.semua_tombol():
		if tombol2.is_visible_in_tree():
			var r3: Rect2 = tombol2.get_global_rect()
			komponen.append({"jenis": "tombol_nonaktif" if tombol2.disabled else "tombol", "rect": [r3.position.x, r3.position.y, r3.size.x, r3.size.y]})
	for panel: Control in _semua_kartu(layar):
		if panel.is_visible_in_tree():
			var r4: Rect2 = panel.get_global_rect()
			komponen.append({"jenis": "kartu", "rect": [r4.position.x, r4.position.y, r4.size.x, r4.size.y]})
	var berkas: FileAccess = FileAccess.open("%s/%s_bengkel_%s.json" % [_folder, _awalan, nama], FileAccess.WRITE)
	if berkas != null:
		berkas.store_string(JSON.stringify({"viewport": [root.get_visible_rect().size.x, root.get_visible_rect().size.y], "teks": teks, "komponen": komponen}))


func _tunggu(jumlah: int) -> void:
	for i: int in range(jumlah):
		await process_frame


func _simpan(keadaan: String) -> void:
	if _folder.is_empty():
		return
	var gambar: Image = root.get_texture().get_image()
	var berkas: String = "%s/%s_bengkel_%s.png" % [_folder, _awalan, keadaan]
	var galat: int = gambar.save_png(berkas)
	print("tangkapan layar %dx%d (%s) ke %s (kode %d)" % [gambar.get_width(), gambar.get_height(), keadaan, berkas, galat])
