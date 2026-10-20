class_name TesBengkelScene
extends RefCounted
## Tes layar bengkel dan alur Hasil -> Bengkel -> Hari berikutnya run fase6a1-bengkel-kondisi bagian B (AC-16, AC-20, AC-21, AC-25, AC-26). `scenes/bengkel/bengkel.tscn` sendiri dengan state
## tulisan tes (saldo, kondisi, level) dan data upgrade nyata (`upgrades.json`: ban_anti_selip 600, rem_pakem 500, rantai_hemat 700): kartu servis, harga, ongkos naik, tombol nonaktif terbaca tanpa
## warna, transaksi atomik lewat `pressed.emit()` dan sentuhan sungguhan, ketukan ganda, target sentuh >= 42 px, dan tata letak di 640, 667, 780, 800 dengan dan tanpa inset aman. Lalu tiga
## skenario utuh dari `scenes/hari/hari.tscn` dengan `SaveManager` jalur sementara (`user://tes_save_4a_alur/`; TIDAK PERNAH menyentuh `user://save.json`, dicek sebelum dan sesudah): (a) bengkel
## dilewati, (b) tabrakan lalu servis dan beli satu upgrade, (c) saldo tidak cukup. Harga literal dihitung tangan dari BALANCING 7 dan 8.5: servis = harga penuh (ban 120, rem 80, rantai 150) x
## (1 - kondisi) x (1 + 0,25 x (rusak - 1) bila rusak >= 2), dibulatkan ke koin (setengah ke atas), paling murah 1.

const BERKAS_BENGKEL: String = "res://scenes/bengkel/bengkel.tscn"
const KASUS: Array = [[1920, 1080, 640], [2001, 1080, 667], [2340, 1080, 780], [2400, 1080, 800]]
const DT: float = 1.0 / 60.0

var _cek: Callable
var _judul: Callable
var _tree: SceneTree
var _a: TesAlurHari = null
var _toko: PemuatToko.Kumpulan = PemuatToko.muat()


func _init(cek: Callable, judul: Callable, tree: SceneTree) -> void:
	_cek = cek
	_judul = judul
	_tree = tree
	_a = TesAlurHari.new(cek, judul, tree)


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	var sebelum: Dictionary = _a._jejak_save_asli()
	check(_toko.sah() and _toko.upgrade.size() == 3, "kontrol: data upgrade nyata sah, tiga upgrade")
	await _test_kondisi_baru()
	await _test_ada_rusak_dan_ongkos()
	await _test_servis_dan_ketukan_ganda()
	await _test_saldo_kurang()
	await _test_upgrade()
	await _test_hari_berikutnya_selalu_aktif()
	await _test_sentuhan_sungguhan()
	await _test_galat_data_upgrade()
	for kasus: Array in KASUS:
		for inset_pakai: bool in [false, true]:
			await _test_tata_letak(kasus, inset_pakai)
	await _test_alur_a_dilewati()
	await _test_alur_b_servis_dan_upgrade()
	await _test_alur_c_saldo_kurang()
	await _test_back_background_dan_tutup_di_bengkel()
	var sesudah: Dictionary = _a._jejak_save_asli()
	check(sebelum == sesudah, "user://save.json tidak tersentuh oleh tes bengkel dan alur bengkel (%s -> %s)" % [sebelum, sesudah])


# --- Pembantu ---

func _state(koin: int, ban: float = 1.0, rem: float = 1.0, rantai: float = 1.0, level: Array = [0, 0, 0], servis_total: int = 0) -> Dictionary:
	var s: Dictionary = DataSave.templat()
	s["koin"] = koin
	s["koin_total"] = koin
	var sepeda: Dictionary = s["sepeda"]
	var daftar: Array = [ban, rem, rantai]
	for i: int in range(3):
		var entri: Dictionary = sepeda[Config.KONDISI_KOMPONEN[i]]
		entri["kondisi"] = daftar[i]
		entri["level"] = level[i]
	sepeda["servis_total"] = servis_total
	return s


func _bengkel(state: Dictionary, jendela: Vector2i = Vector2i(2340, 1080), toko: PemuatToko.Kumpulan = null) -> LayarBengkel:
	_tree.root.size = jendela
	var layar: LayarBengkel = (load(BERKAS_BENGKEL) as PackedScene).instantiate() as LayarBengkel
	_tree.root.add_child(layar)
	await _tree.process_frame
	layar.isi(state, toko if toko != null else _toko)
	await _tree.process_frame
	await _tree.process_frame
	return layar


func _buang(layar: LayarBengkel) -> void:
	_lepas_jari()
	_tree.root.remove_child(layar)
	layar.free()


func _lepas_jari() -> void:
	for i: int in range(8):
		var p: InputEventScreenTouch = InputEventScreenTouch.new()
		p.index = i
		p.position = Vector2(-50, -50)
		p.pressed = false
		Input.parse_input_event(p)
	Input.flush_buffered_events()


func _ketuk(titik_viewport: Vector2, index: int = 0) -> void:
	for tekan: bool in [true, false]:
		var p: InputEventScreenTouch = InputEventScreenTouch.new()
		p.index = index
		p.position = titik_viewport * 3.0
		p.pressed = tekan
		Input.parse_input_event(p)
		Input.flush_buffered_events()


func _audio() -> Node:
	return _tree.root.get_node_or_null(^"Audio")


# --- Layar bengkel sendiri ---

func _test_kondisi_baru() -> void:
	_judul.call("Bengkel: sepeda baru, saldo 500: tiga komponen 'Baik' tanpa tombol Servis; upgrade nyata dengan Beli aktif hanya bila saldo cukup (AC-25)")
	var layar: LayarBengkel = await _bengkel(_state(500))
	check(layar.teks_judul() == "Bengkel" and layar.teks_saldo() == "500", "judul 'Bengkel' dan saldo '500'")
	for id: String in Config.KONDISI_KOMPONEN:
		var kartu: LayarBengkel.KartuServis = layar.kartu_servis(id)
		check(not kartu.tombol.visible and kartu.label_baik.visible and kartu.label_baik.text == "Baik" and not kartu.harga.visible, "%s penuh: label 'Baik', tanpa tombol Servis dan tanpa harga" % id)
		check(kartu.tingkat.text == "Baik" and kartu.kotak.kotak_tampil() == [TampilKondisi.Kotak.PENUH, TampilKondisi.Kotak.PENUH, TampilKondisi.Kotak.PENUH] and not kartu.kotak.seru_tampil(), "%s: tingkat 'Baik', tiga kotak penuh, tanpa '!'" % id)
	check(layar.jumlah_upgrade_tampil() == 3 and not layar.ongkos_tampil() and not layar.galat_tampil(), "tiga upgrade tampil, tanpa catatan ongkos naik, tanpa galat data")
	var pakem: TombolSentuh = layar.tombol_beli("rem_pakem")
	var anti: TombolSentuh = layar.tombol_beli("ban_anti_selip")
	var hemat: TombolSentuh = layar.tombol_beli("rantai_hemat")
	check(not pakem.disabled and pakem.text == "Beli" and layar.kartu_upgrade("rem_pakem").harga.text == "500 koin", "saldo 500 = harga rem_pakem: Beli aktif (tepat di ambang sah), harga '500 koin'")
	check(anti.disabled and anti.text == "Koin kurang" and hemat.disabled and hemat.text == "Koin kurang", "ban_anti_selip 600 dan rantai_hemat 700 melebihi saldo: nonaktif dengan teks 'Koin kurang' (terbaca tanpa warna)")
	check(layar.kartu_upgrade("ban_anti_selip").nama.text == "Ban Anti-Selip" and layar.kartu_upgrade("ban_anti_selip").deskripsi.text == "Belok lebih lincah (+15%)" and layar.kartu_upgrade("rantai_hemat").harga.text == "700 koin", "nama, deskripsi, dan harga upgrade dari data (kunci terjemahan)")
	_buang(layar)


func _test_ada_rusak_dan_ongkos() -> void:
	_judul.call("Bengkel: dua komponen PERLU_BENGKEL memicu ongkos naik x1,25 dan harga servis sesuai rumus (GDD 12.3, M-9)")
	var layar: LayarBengkel = await _bengkel(_state(1000, 0.30, 0.20, 0.75))
	var ban: LayarBengkel.KartuServis = layar.kartu_servis("ban")
	var rem: LayarBengkel.KartuServis = layar.kartu_servis("rem")
	var rantai: LayarBengkel.KartuServis = layar.kartu_servis("rantai")
	# ban: 120 x 0,70 x 1,25 = 105; rem: 80 x 0,80 x 1,25 = 80; rantai 0,75 (BAIK tetapi belum penuh): 150 x 0,25 x 1,25 = 46,875 -> 47.
	check(ban.harga.text == "105 koin" and rem.harga.text == "80 koin" and rantai.harga.text == "47 koin", "harga: ban 105, rem 80, rantai 38 koin (ongkos naik x1,25 untuk dua komponen rusak), dapat %s / %s / %s" % [ban.harga.text, rem.harga.text, rantai.harga.text])
	check(ban.tingkat.text == "Perlu servis" and rem.tingkat.text == "Perlu servis" and rantai.tingkat.text == "Baik", "tingkat dalam teks: Perlu servis, Perlu servis, Baik")
	check(ban.kotak.seru_tampil() and rem.kotak.seru_tampil() and not rantai.kotak.seru_tampil(), "tanda '!' hanya pada komponen PERLU_BENGKEL")
	check(layar.ongkos_tampil() and layar.teks_ongkos() == "Banyak yang rusak: ongkos servis x1.25", "catatan ongkos naik tampil: '%s'" % layar.teks_ongkos())
	check(not ban.tombol.disabled and not rem.tombol.disabled and not rantai.tombol.disabled and ban.tombol.text == "Servis", "saldo 1.000 cukup: tiga tombol Servis aktif")
	check(layar.teks_saldo() == "1.000", "saldo berpemisah ribuan: '1.000'")
	_buang(layar)


func _test_servis_dan_ketukan_ganda() -> void:
	_judul.call("Bengkel: Servis menurunkan saldo tepat harga, kondisi 1,0, servis_total + 1, tombol menjadi 'Baik'; ketukan ganda tidak membeli dua kali (AC-26)")
	var layar: LayarBengkel = await _bengkel(_state(1000, 0.30, 0.20, 0.75))
	var diterima: Array[String] = []
	layar.servis_dilakukan.connect(func(k: String, h: int) -> void: diterima.append("%s:%d" % [k, h]))
	var audio: Node = _audio()
	var bunyi_awal: int = int(audio.call(&"jumlah_bunyi_kondisi", BunyiKondisi.Bunyi.SERVIS)) if audio != null else 0
	layar.tombol_servis("ban").pressed.emit()
	layar.tombol_servis("ban").pressed.emit()
	var s: Dictionary = layar.state()
	check(diterima == ["ban:105"] and s["koin"] == 895, "dua ketukan Servis ban dalam satu frame: dibayar sekali (105), saldo 895, dapat %s / %d" % [diterima, s["koin"]])
	check(Economy.kondisi_dari(s)["ban"] == 1.0 and Economy.servis_total(s) == 1 and s["koin_total"] == 1000, "ban kondisi 1,0, servis_total 1, koin_total tidak berubah (belanja tidak mengurangi total seumur hidup)")
	check(audio == null or int(audio.call(&"jumlah_bunyi_kondisi", BunyiKondisi.Bunyi.SERVIS)) == bunyi_awal + 1, "satu bunyi servis (pasangan visual: tombol berganti 'Baik' dan saldo turun)")
	await _tree.process_frame
	layar.tombol_servis("ban").pressed.emit()
	check(layar.state()["koin"] == 895 and diterima.size() == 1, "ketukan lagi di frame berikutnya (komponen sudah penuh): tidak ada transaksi kedua")
	var ban: LayarBengkel.KartuServis = layar.kartu_servis("ban")
	check(not ban.tombol.visible and ban.label_baik.visible and ban.kotak.kotak_tampil() == [TampilKondisi.Kotak.PENUH, TampilKondisi.Kotak.PENUH, TampilKondisi.Kotak.PENUH] and layar.teks_saldo() == "895", "tampilan: label 'Baik', tiga kotak penuh, saldo '895'")
	# Sekarang hanya rem yang PERLU_BENGKEL: ongkos naik hilang, harga rem 80 x 0,80 = 64.
	check(not layar.ongkos_tampil() and layar.kartu_servis("rem").harga.text == "64 koin" and layar.kartu_servis("rantai").harga.text == "38 koin", "satu komponen rusak tersisa: tanpa ongkos naik, rem 64 koin dan rantai 38 koin (37,5 dibulatkan ke atas)")
	layar.tombol_servis("rem").pressed.emit()
	layar.tombol_servis("rantai").pressed.emit()
	check(layar.state()["koin"] == 895 - 64 - 38 and Economy.servis_total(layar.state()) == 3 and layar.belanja_koin() == 105 + 64 + 38, "servis rem lalu rantai: saldo 793, servis_total 3, belanja 207")
	_buang(layar)


func _test_saldo_kurang() -> void:
	_judul.call("Bengkel: saldo kurang = tombol nonaktif bertulis 'Koin kurang'; menekannya lewat pressed.emit() tidak mengubah apa pun (AC-21c, AC-26)")
	var awal: Dictionary = _state(50, 0.30, 1.0, 1.0)
	var layar: LayarBengkel = await _bengkel(awal)
	var tombol: TombolSentuh = layar.tombol_servis("ban")
	check(tombol.visible and tombol.disabled and tombol.text == "Koin kurang" and layar.kartu_servis("ban").harga.text == "84 koin", "ban 0,30 harga 84 > saldo 50: tombol nonaktif 'Koin kurang', harga '84 koin'")
	var sebelum: Dictionary = layar.state()
	tombol.pressed.emit()
	for id: String in ["ban_anti_selip", "rem_pakem", "rantai_hemat"]:
		layar.tombol_beli(id).pressed.emit()
	check(layar.state() == sebelum and layar.belanja_koin() == 0, "menekan semua tombol nonaktif: state identik, belanja 0")
	check(not layar.tombol_hari_berikutnya().disabled, "'Hari berikutnya' tetap aktif (K-4)")
	_buang(layar)


func _test_upgrade() -> void:
	_judul.call("Bengkel: Beli upgrade menurunkan saldo tepat harga, level naik, tombol menjadi 'Dimiliki'; ketukan ganda tidak membeli dua kali (AC-14, AC-26)")
	var layar: LayarBengkel = await _bengkel(_state(1100))
	var dibeli: Array[String] = []
	layar.upgrade_dibeli.connect(func(id: String, h: int) -> void: dibeli.append("%s:%d" % [id, h]))
	layar.tombol_beli("ban_anti_selip").pressed.emit()
	layar.tombol_beli("ban_anti_selip").pressed.emit()
	var s: Dictionary = layar.state()
	check(dibeli == ["ban_anti_selip:600"] and s["koin"] == 500 and Economy.level_dari(s)["ban"] == 1, "ban_anti_selip dibeli sekali: saldo 500, level ban 1, dapat %s / %d" % [dibeli, s["koin"]])
	var kartu: LayarBengkel.KartuUpgrade = layar.kartu_upgrade("ban_anti_selip")
	check(not kartu.tombol.visible and kartu.label_dimiliki.visible and kartu.label_dimiliki.text == "Dimiliki" and not kartu.harga.visible, "kartu menjadi label 'Dimiliki' tanpa tombol dan tanpa harga")
	check(not layar.tombol_beli("rem_pakem").disabled and layar.tombol_beli("rantai_hemat").disabled and layar.tombol_beli("rantai_hemat").text == "Koin kurang", "saldo 500: rem_pakem masih terbeli (tepat), rantai_hemat nonaktif 'Koin kurang'")
	layar.tombol_beli("rem_pakem").pressed.emit()
	check(layar.state()["koin"] == 0 and Economy.level_dari(layar.state())["rem"] == 1 and layar.state()["koin_total"] == 1100 and layar.state()["tip_total"] == 0, "rem_pakem dibeli: saldo 0, level rem 1, koin_total dan tip_total tetap")
	check(layar.tombol_beli("rantai_hemat").disabled and layar.belanja_koin() == 1100, "saldo 0: semua tombol Beli yang tersisa nonaktif, belanja 1.100")
	_buang(layar)


func _test_hari_berikutnya_selalu_aktif() -> void:
	_judul.call("Bengkel: 'Hari berikutnya' selalu aktif dan memancarkan sinyal, juga saat saldo 0 dan semua rusak (K-4)")
	var layar: LayarBengkel = await _bengkel(_state(0, 0.0, 0.0, 0.0))
	var sinyal: Array[int] = [0]
	layar.hari_berikutnya_diminta.connect(func() -> void: sinyal[0] += 1)
	check(not layar.tombol_hari_berikutnya().disabled and tr(layar.tombol_hari_berikutnya().text) == "Hari berikutnya" and layar.tombol_hari_berikutnya().visible, "saldo 0 dan tiga komponen rusak total: 'Hari berikutnya' aktif")
	layar.tombol_hari_berikutnya().ditekan.emit()
	check(sinyal[0] == 1, "ditekan: sinyal hari_berikutnya_diminta")
	for id: String in Config.KONDISI_KOMPONEN:
		check(layar.tombol_servis(id).disabled and layar.tombol_servis(id).text == "Koin kurang", "%s kondisi 0 saldo 0: Servis nonaktif 'Koin kurang'" % id)
	_buang(layar)


func _test_sentuhan_sungguhan() -> void:
	_judul.call("Bengkel: jari sungguhan pada tombol Servis dan Beli bekerja (TombolSentuh), jari pada tombol nonaktif tidak (AC-26)")
	var layar: LayarBengkel = await _bengkel(_state(700, 0.5, 1.0, 1.0))
	var tombol: Rect2 = layar.tombol_servis("ban").get_global_rect()
	_ketuk(tombol.get_center())
	check(layar.state()["koin"] == 700 - 60 and Economy.kondisi_dari(layar.state())["ban"] == 1.0, "ketukan jari di tombol Servis ban: dibayar 60 (120 x 0,5), kondisi 1,0")
	var beli: Rect2 = layar.tombol_beli("rantai_hemat").get_global_rect()
	_ketuk(beli.get_center(), 1)
	check(layar.state()["koin"] == 640 and Economy.level_dari(layar.state())["rantai"] == 0, "ketukan jari di Beli rantai_hemat (700 > saldo 640, nonaktif): tidak membeli")
	var pakem: Rect2 = layar.tombol_beli("rem_pakem").get_global_rect()
	_ketuk(pakem.get_center(), 2)
	check(layar.state()["koin"] == 140 and Economy.level_dari(layar.state())["rem"] == 1, "ketukan jari di Beli rem_pakem (500): saldo 140, level rem 1")
	_buang(layar)


func _test_galat_data_upgrade() -> void:
	_judul.call("Bengkel: data upgrade rusak = pesan galat jujur, tanpa upgrade, servis dan 'Hari berikutnya' tetap berfungsi (AC-17, K-4)")
	var rusak: PemuatToko.Kumpulan = PemuatToko.parse_teks("{bukan json", "upgrades.json")
	check(not rusak.sah() and rusak.upgrade.is_empty(), "kontrol: JSON rusak ditolak")
	var layar: LayarBengkel = await _bengkel(_state(500, 0.5), Vector2i(2340, 1080), rusak)
	check(layar.galat_tampil() and layar.jumlah_upgrade_tampil() == 0, "pesan galat tampil dan daftar upgrade kosong")
	layar.tombol_servis("ban").pressed.emit()
	check(layar.state()["koin"] == 440 and not layar.tombol_hari_berikutnya().disabled, "servis tetap bisa dan 'Hari berikutnya' aktif")
	_buang(layar)


# --- Tata letak ---

func _test_tata_letak(kasus: Array, dengan_inset: bool) -> void:
	var lebar: int = kasus[2]
	var tag: String = "bengkel %d %s" % [lebar, "inset" if dengan_inset else "tanpa inset"]
	_judul.call("Tata letak %s: kasus terpadat (tiga rusak, ongkos naik, tiga upgrade), di dalam zona aman, tidak bertumpuk, tombol >= 42 px, tanpa scroll (AC-25)" % tag)
	var layar: LayarBengkel = await _bengkel(_state(12345, 0.1, 0.2, 0.3), Vector2i(kasus[0], kasus[1]))
	var inset: ZonaAman.Inset = ZonaAman.Inset.new()
	if dengan_inset:
		inset.awal_x = 20
		inset.akhir_x = 24
		inset.atas = 16
		inset.bawah = 18
	layar.atur_inset(inset)
	await _tree.process_frame
	await _tree.process_frame
	var batas_awal: float = float(maxi(Config.BENGKEL_MARGIN_PX, inset.awal_x))
	var batas_akhir: float = float(lebar - maxi(Config.BENGKEL_MARGIN_PX, inset.akhir_x))
	var atas: float = float(maxi(Config.BENGKEL_MARGIN_PX, inset.atas))
	var bawah: float = float(360 - maxi(Config.BENGKEL_MARGIN_PX, inset.bawah))
	var aman: Rect2 = Rect2(batas_awal, atas, batas_akhir - batas_awal, bawah - atas)
	var semua: Array[Rect2] = layar.rect_tampil()
	check(semua.size() >= 25, "%s: elemen tampil terdaftar (%d)" % [tag, semua.size()])
	var di_luar: Array[String] = []
	for r: Rect2 in semua:
		if r.size.x <= 0.0 or r.size.y <= 0.0 or not aman.grow(0.5).encloses(r):
			di_luar.append(str(r))
	check(di_luar.is_empty(), "%s: semua elemen di dalam zona aman %s: di luar %s" % [tag, aman, di_luar.slice(0, 3)])
	var tumpuk: Array[String] = []
	for i: int in range(semua.size()):
		for j: int in range(i + 1, semua.size()):
			if semua[i].intersects(semua[j]):
				tumpuk.append("%s x %s" % [semua[i], semua[j]])
	check(tumpuk.is_empty(), "%s: tidak ada elemen yang bertumpuk: %s" % [tag, tumpuk.slice(0, 3)])
	var kecil: Array[String] = []
	for tombol: TombolSentuh in layar.semua_tombol():
		if tombol.is_visible_in_tree() and (tombol.get_global_rect().size.y < 42.0 or tombol.get_global_rect().size.x < 42.0):
			kecil.append(str(tombol.get_global_rect()))
	check(kecil.is_empty(), "%s: semua tombol yang tampil >= 42x42 px game: %s" % [tag, kecil])
	check(layar.rect_tombol_hari().size.x >= float(Config.BENGKEL_HARI_LEBAR_PX) and layar.rect_tombol_hari().end.y <= bawah + 0.5 and layar.rect_tombol_hari().end.x <= batas_akhir + 0.5, "%s: 'Hari berikutnya' %s di sudut kanan bawah zona aman" % [tag, layar.rect_tombol_hari()])
	check(layar.find_children("*", "ScrollContainer", true, false).is_empty() and layar.rect_isi().end.y <= bawah + 0.5, "%s: tanpa scroll, isi berakhir y %.1f <= %.1f" % [tag, layar.rect_isi().end.y, bawah])
	var terpotong: Array[String] = []
	for simpul: Node in layar.find_children("*", "Label", true, false):
		var label: Label = simpul as Label
		if label.is_visible_in_tree() and label.get_visible_line_count() != label.get_line_count():
			terpotong.append(label.text)
	check(terpotong.is_empty(), "%s: tidak ada teks terpotong: %s" % [tag, terpotong])
	var mentah: Array[String] = []
	var kunci_mentah: RegEx = RegEx.create_from_string("^[A-Z]+(?:_[A-Z0-9]+)+$")
	for teks: String in layar.teks_tampil():
		if kunci_mentah.search(teks) != null:
			mentah.append(teks)
	check(mentah.is_empty() and layar.teks_tampil().size() >= 20, "%s: semua teks yang tampil sudah diterjemahkan (tanpa kunci mentah): %s" % [tag, mentah])
	_buang(layar)


# --- Alur utuh dari hari.tscn ---

## Tabrakan nyata dengan anjing seed dev: rute diatur ke seed dev (rintangan diketahui), sepeda disisipkan di sisi anjing; mengembalikan jumlah tabrakan.
func _tabrak_anjing(rute: RuteMain) -> int:
	rute.atur_benih_awal(Config.RUTE_SEED_DEV)
	rute.set_process(false)
	var sepeda: SepedaUji = rute.find_child("Sepeda", true, false) as SepedaUji
	var k: BikeMotion.Keadaan = sepeda.keadaan.salin()
	k.kecepatan_ud = 3.0
	k.lateral_ubin = -0.6
	sepeda.keadaan = k
	sepeda.jarak_ubin = 30.0
	var tabrak: Array[int] = [0]
	rute.tabrakan.connect(func(_j: String) -> void: tabrak[0] += 1)
	for i: int in range(600):
		if tabrak[0] > 0:
			break
		rute.perbarui(DT)
	return tabrak[0]


func _test_alur_a_dilewati() -> void:
	_judul.call("Alur (a): rute bersih, Ke bengkel, langsung 'Hari berikutnya': satu simpan, tanpa belanja, kondisi hanya aus (AC-20, AC-21a)")
	_a._bersihkan_folder()
	var m: Node = _a._manajer()
	var hari: HariMain = await _a._siapkan(m)
	hari.koran().tombol_lewati().ditekan.emit()
	var rute: RuteMain = await _a._berangkat(hari)
	await _a._selesaikan_rute(rute)
	check(rute.layar_hasil().teks_kondisi().is_empty(), "rute bersih: layar hasil tanpa baris kondisi")
	check(m.get(&"jumlah_simpan") == 0, "layar hasil terbuka: nol simpan")
	rute.layar_hasil().tombol_main_lagi().ditekan.emit()
	await _tree.process_frame
	var bengkel: LayarBengkel = hari.bengkel()
	check(hari.status().keadaan == MesinHari.Keadaan.BENGKEL and bengkel != null and bengkel.visible and not rute.layar_hasil().tampil() and m.get(&"jumlah_simpan") == 0, "'Ke bengkel': status BENGKEL, bengkel tampil, layar hasil tersembunyi, belum ada simpan")
	check(bengkel.teks_saldo() == "120" and bengkel.state()["koin"] == 120, "saldo bengkel = koin save (0) + koin hari ini (120)")
	for id: String in Config.KONDISI_KOMPONEN:
		check(not bengkel.tombol_servis(id).visible and bengkel.kartu_servis(id).label_baik.visible, "%s: 'Baik' (rute bersih)" % id)
	bengkel.tombol_hari_berikutnya().ditekan.emit()
	await _tree.process_frame
	var s: Dictionary = _a._baca_save()
	check(m.get(&"jumlah_simpan") == 1 and s["hari"] == 2 and s["koin"] == 120 and s["koin_total"] == 120, "tepat satu simpan sesudah 'Hari berikutnya': hari 2, koin 120, koin_total 120")
	var sepeda: Dictionary = s["sepeda"]
	var aus_kecil: bool = true
	for id: String in Config.KONDISI_KOMPONEN:
		var entri: Dictionary = sepeda[id]
		aus_kecil = aus_kecil and float(entri["kondisi"]) >= 0.999 and entri["level"] == 0
	check(aus_kecil and sepeda["servis_total"] == 0, "sepeda: hanya aus kecil (>= 0,999), level 0, servis_total 0 (tidak ada belanja)")
	check(hari.status().keadaan == MesinHari.Keadaan.KORAN and hari.bengkel() == null and hari.rute() == null and hari.koran().tampil(), "kembali ke koran hari 2: bengkel dan rute dibuang")
	_a._bersihkan(hari)
	_a._tutup_manajer(m)
	_a._bersihkan_folder()


func _test_alur_b_servis_dan_upgrade() -> void:
	_judul.call("Alur (b): save berkondisi 0,5, tabrakan nyata, servis komponen rusak dan beli rem_pakem, 'Hari berikutnya': saldo, kondisi, level benar; hari berikutnya memakai level tersimpan (AC-20, AC-21b)")
	_a._bersihkan_folder()
	_a._tulis_save(DataSave.ke_teks(_state(600, 0.5, 0.5, 0.5)))
	var m: Node = _a._manajer()
	var hari: HariMain = await _a._siapkan(m)
	hari.koran().tombol_lewati().ditekan.emit()
	var rute: RuteMain = await _a._berangkat(hari)
	var awal_sama: bool = true
	for id: String in Config.KONDISI_KOMPONEN:
		awal_sama = awal_sama and float(rute.kondisi().kondisi[id]) <= 0.5 and float(rute.kondisi().kondisi[id]) >= 0.49
	check(awal_sama, "rute hari 1 memakai kondisi tersimpan 0,5 / 0,5 / 0,5 (bukan 1,0): %s" % [rute.kondisi().kondisi])
	check(await _tabrak_anjing(rute) == 1, "kontrol: satu tabrakan nyata dengan anjing")
	var rusak: String = BikeCondition.komponen_tabrakan(1, 0)
	check(float(rute.kondisi().kondisi[rusak]) <= 0.2 and float(rute.kondisi().kondisi[rusak]) > 0.19, "komponen %s (seed hari 1 nomor 0) 0,5 - 0,3 = 0,2 (sedikit aus lagi), dapat %.4f" % [rusak, float(rute.kondisi().kondisi[rusak])])
	await _a._selesaikan_rute(rute)
	var nama_rusak: String = {"ban": "Ban", "rem": "Rem", "rantai": "Rantai"}[rusak]
	check(rute.layar_hasil().teks_kondisi() == ["%s perlu servis" % nama_rusak], "layar hasil: satu baris '%s perlu servis'" % nama_rusak)
	rute.layar_hasil().tombol_main_lagi().ditekan.emit()
	var bengkel: LayarBengkel = hari.bengkel()
	var harga: int = {"ban": 96, "rem": 64, "rantai": 120}[rusak]
	check(bengkel.teks_saldo() == "720" and bengkel.kartu_servis(rusak).harga.text == "%d koin" % harga and bengkel.kartu_servis(rusak).tingkat.text == "Perlu servis", "saldo 720 (600 + 120); servis %s %d koin (harga penuh x 0,8, satu rusak tanpa ongkos naik)" % [rusak, harga])
	bengkel.tombol_servis(rusak).pressed.emit()
	bengkel.tombol_beli("rem_pakem").pressed.emit()
	check(m.get(&"jumlah_simpan") == 0, "servis dan beli di bengkel: belum ada simpan")
	check(bengkel.state()["koin"] == 720 - harga - 500, "saldo kerja %d (720 - %d - 500)" % [720 - harga - 500, harga])
	bengkel.tombol_hari_berikutnya().ditekan.emit()
	await _tree.process_frame
	var s: Dictionary = _a._baca_save()
	var sepeda: Dictionary = s["sepeda"]
	var entri_rusak: Dictionary = sepeda[rusak]
	check(m.get(&"jumlah_simpan") == 1 and s["koin"] == 720 - harga - 500 and s["koin_total"] == 720 and s["tip_total"] == 25 and s["hari"] == 2, "save: koin %d, koin_total 720 (belanja tidak mengurangi), tip_total 25, hari 2; dapat koin %s" % [720 - harga - 500, s["koin"]])
	check(entri_rusak["kondisi"] == 1.0 and sepeda["servis_total"] == 1 and sepeda["rem"]["level"] == 1 and sepeda["ban"]["level"] == 0 and sepeda["rantai"]["level"] == 0, "save: %s kondisi 1,0, servis_total 1, level rem 1 (upgrade), level lain 0" % rusak)
	for id: String in Config.KONDISI_KOMPONEN:
		if id != rusak:
			check(float(sepeda[id]["kondisi"]) >= 0.49 and float(sepeda[id]["kondisi"]) <= 0.5, "komponen %s yang tidak diservis tetap sekitar 0,5 (aus kecil), dapat %s" % [id, sepeda[id]["kondisi"]])
	# Hari berikutnya memakai kondisi dan level tersimpan.
	var rute2: RuteMain = await _a._berangkat(hari)
	check(rute2.kondisi().efek.pengali_rem == 1.2 and float(rute2.kondisi().kondisi[rusak]) == 1.0, "hari 2: efek memakai level rem 1 (perlambatan x1,2) dan %s dimulai dari 1,0" % rusak)
	for id: String in Config.KONDISI_KOMPONEN:
		if id != rusak:
			check(float(rute2.kondisi().kondisi[id]) <= 0.5 and float(rute2.kondisi().kondisi[id]) >= 0.485, "hari 2: aus melanjutkan dari kondisi tersimpan %s (bukan dari 1,0)" % id)
	_a._bersihkan(hari)
	_a._tutup_manajer(m)
	_a._bersihkan_folder()


func _test_alur_c_saldo_kurang() -> void:
	_judul.call("Alur (c): saldo tidak cukup: Servis dan Beli nonaktif, ditekan tidak mengubah apa pun; kondisi buruk tersimpan dan hari berikutnya hanya menghambat (AC-21c, prinsip 2)")
	_a._bersihkan_folder()
	_a._tulis_save(DataSave.ke_teks(_state(0, 0.0, 1.0, 0.0)))
	var m: Node = _a._manajer()
	var hari: HariMain = await _a._siapkan(m)
	hari.koran().tombol_lewati().ditekan.emit()
	var rute: RuteMain = await _a._berangkat(hari)
	await _a._selesaikan_rute(rute)
	check(rute.layar_hasil().teks_kondisi() == ["Ban perlu servis", "Rantai perlu servis"], "layar hasil: 'Ban perlu servis' dan 'Rantai perlu servis'")
	rute.layar_hasil().tombol_main_lagi().ditekan.emit()
	var bengkel: LayarBengkel = hari.bengkel()
	# Saldo 120: ban 120 x 1,0 x 1,25 = 150 dan rantai 150 x 1,25 = 187,5 -> 188 melebihi saldo; semua upgrade (>= 500) juga.
	check(bengkel.kartu_servis("ban").harga.text == "150 koin" and bengkel.kartu_servis("rantai").harga.text == "188 koin" and bengkel.teks_saldo() == "120", "harga ban 150 dan rantai 188 koin (ongkos naik x1,25) melebihi saldo 120")
	check(bengkel.tombol_servis("ban").disabled and bengkel.tombol_servis("rantai").disabled, "Servis ban dan rantai nonaktif")
	for id: String in ["ban_anti_selip", "rem_pakem", "rantai_hemat"]:
		check(bengkel.tombol_beli(id).disabled and bengkel.tombol_beli(id).text == "Koin kurang", "Beli %s nonaktif 'Koin kurang'" % id)
	var sebelum: Dictionary = bengkel.state()
	bengkel.tombol_servis("ban").pressed.emit()
	bengkel.tombol_servis("rantai").pressed.emit()
	bengkel.tombol_beli("rem_pakem").pressed.emit()
	check(bengkel.state() == sebelum and bengkel.belanja_koin() == 0, "menekan tombol nonaktif lewat pressed.emit(): state identik")
	bengkel.tombol_hari_berikutnya().ditekan.emit()
	await _tree.process_frame
	var s: Dictionary = _a._baca_save()
	check(s["koin"] == 120 and s["koin_total"] == 120 and float(s["sepeda"]["ban"]["kondisi"]) == 0.0 and float(s["sepeda"]["rantai"]["kondisi"]) == 0.0 and s["sepeda"]["servis_total"] == 0, "save: koin 120 utuh, ban dan rantai tetap 0,0, servis_total 0 (tidak ada hukuman, tidak ada kebuntuan)")
	var rute2: RuteMain = await _a._berangkat(hari)
	check(rute2.kondisi().efek.pengali_kecepatan == 0.92 and rute2.kondisi().efek.pengali_akselerasi == 0.35 and rute2.hud_rute().kotak_kondisi("ban").seru_tampil() and rute2.hud_rute().kotak_kondisi("ban").kotak_tampil() == [TampilKondisi.Kotak.KOSONG, TampilKondisi.Kotak.KOSONG, TampilKondisi.Kotak.KOSONG], "hari 2: ban dan rantai 0 sejak awal: efek terburuk hanya menghambat, HUD ban tanpa kotak dan dengan '!'")
	await _a._selesaikan_rute(rute2)
	check(rute2.hasil_tampil() and rute2.angka_hasil().terkirim == 3, "hari 2 tetap bisa diselesaikan dengan ban dan rantai rusak total (tidak ada kebuntuan)")
	_a._bersihkan(hari)
	_a._tutup_manajer(m)
	_a._bersihkan_folder()


func _test_back_background_dan_tutup_di_bengkel() -> void:
	_judul.call("Bengkel: background tidak menyimpan; back Android = 'Hari berikutnya' (simpan sekali); di layar hasil back diabaikan; app ditutup di bengkel = hari diulang dari save lama (AC-20, M-8)")
	_a._bersihkan_folder()
	var m: Node = _a._manajer()
	var hari: HariMain = await _a._siapkan(m)
	hari.koran().tombol_lewati().ditekan.emit()
	var rute: RuteMain = await _a._berangkat(hari)
	await _a._selesaikan_rute(rute)
	hari.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(hari.status().keadaan == MesinHari.Keadaan.HASIL and m.get(&"jumlah_simpan") == 0 and hari.bengkel() == null, "back di layar hasil: diabaikan (tidak membuka bengkel, tidak menyimpan)")
	rute.layar_hasil().tombol_main_lagi().ditekan.emit()
	var bengkel: LayarBengkel = hari.bengkel()
	bengkel.tombol_servis("ban").pressed.emit()
	hari.propagate_notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	hari.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(hari.status().keadaan == MesinHari.Keadaan.BENGKEL and m.get(&"jumlah_simpan") == 0 and not FileAccess.file_exists(_a._jalur()), "app ke background di bengkel: nol simpan, bengkel tetap")
	# App ditutup di bengkel: scene dibuang tanpa simpan; buka lagi = hari 1 dari koran dengan save lama.
	_a._bersihkan(hari)
	var jumlah_simpan: int = int(m.get(&"jumlah_simpan"))
	_a._tutup_manajer(m)
	check(jumlah_simpan == 0 and not FileAccess.file_exists(_a._jalur()), "scene dibuang di bengkel: tidak ada simpan dan tidak ada berkas (pendapatan hari itu diulang)")
	var m2: Node = _a._manajer()
	var hari2: HariMain = await _a._siapkan(m2)
	check(hari2.status().hari == 1 and hari2.status().keadaan == MesinHari.Keadaan.KORAN, "dibuka lagi: hari 1 dari layar koran")
	hari2.koran().tombol_lewati().ditekan.emit()
	var rute2: RuteMain = await _a._berangkat(hari2)
	await _a._selesaikan_rute(rute2)
	rute2.layar_hasil().tombol_main_lagi().ditekan.emit()
	var dibuka_back: LayarBengkel = hari2.bengkel()
	check(dibuka_back != null and hari2.status().keadaan == MesinHari.Keadaan.BENGKEL, "hari 1 ulang: bengkel terbuka")
	hari2.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await _tree.process_frame
	check(m2.get(&"jumlah_simpan") == 1 and hari2.status().hari == 2 and hari2.status().keadaan == MesinHari.Keadaan.KORAN and _a._baca_save()["koin"] == 120, "back Android di bengkel = 'Hari berikutnya': satu simpan, hari 2, koin 120")
	hari2.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(m2.get(&"jumlah_simpan") == 1, "back di layar koran bukan lagi 'Hari berikutnya' (tidak menyimpan lagi)")
	_a._bersihkan(hari2)
	_a._tutup_manajer(m2)
	_a._bersihkan_folder()
