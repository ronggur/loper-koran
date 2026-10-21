extends SceneTree
## Probe layar bengkel di jendela asli, non-headless (AC-30 run fase6a1-bengkel-kondisi bagian B): memuat `scenes/bengkel/bengkel.tscn` dengan state tulisan probe dan data upgrade nyata, lalu
## memotret: sepeda baru, ada yang rusak (ongkos naik), saldo kurang (tombol nonaktif bertulis "Koin kurang"), sesudah servis, sesudah upgrade, kasus terpadat (tiga rusak, saldo besar),
## galat data upgrade, dan inset aman. Servis dan Beli ditekan lewat `pressed.emit()` (kode asli). Mencetak data tiap keadaan dan jumlah keadaan yang tidak sesuai (elemen di luar layar atau
## zona aman, bertumpuk, tombol < 42 px, teks terpotong). Tidak interaktif: keluar lewat `ProbeKeluar`.
##
## Pakai (jendela harus muat di layar monitor):
##   godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_bengkel_jendela.gd -- docs/loop/<RUN_ID>/shots/iter<N>
##   (juga 1920x1080, 2400x1080, 1600x720)
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
	await _kasus("baru", _state(480, 1.0, 1.0, 1.0))
	await _kasus("ada_rusak", _state(1000, 0.30, 0.20, 0.75))
	await _kasus("saldo_kurang", _state(50, 0.30, 0.55, 1.0))
	var layar: LayarBengkel = await _kasus("sesudah_servis", _state(1000, 0.30, 0.20, 0.75), ["servis:ban"])
	layar.queue_free()
	var layar2: LayarBengkel = await _kasus("sesudah_upgrade", _state(1100, 1.0, 0.6, 1.0), ["beli:ban_anti_selip"])
	layar2.queue_free()
	await _kasus("terpadat", _state(12345, 0.1, 0.2, 0.3))
	await _kasus("galat_data", _state(500, 0.5, 1.0, 1.0), [], PemuatToko.parse_teks("{bukan json", "upgrades.json"))
	_inset.awal_x = 20
	_inset.akhir_x = 24
	_inset.atas = 16
	_inset.bawah = 18
	await _kasus("inset_aman", _state(12345, 0.1, 0.2, 0.3))
	print("probe selesai, %d keadaan tidak sesuai" % _gagal)
	await ProbeKeluar.keluar(self, 0 if _gagal == 0 else 1)


func _state(koin: int, ban: float, rem: float, rantai: float) -> Dictionary:
	var s: Dictionary = DataSave.templat()
	s["koin"] = koin
	s["koin_total"] = koin
	var sepeda: Dictionary = s["sepeda"]
	var daftar: Array = [ban, rem, rantai]
	for i: int in range(3):
		var entri: Dictionary = sepeda[Config.KONDISI_KOMPONEN[i]]
		entri["kondisi"] = daftar[i]
	return s


## Satu keadaan: bengkel dengan `state`, aksi (servis:<komponen>, beli:<id>) ditekan, difoto, diperiksa. Mengembalikan layarnya (dibebaskan pemanggil bila diminta; bila tidak, dibebaskan di sini).
func _kasus(nama: String, state: Dictionary, aksi: Array = [], toko: PemuatToko.Kumpulan = null) -> LayarBengkel:
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
	if nama != "sesudah_servis" and nama != "sesudah_upgrade":
		layar.queue_free()
		await _tunggu(2)
	return layar


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
		if tombol.is_visible_in_tree() and (tombol.get_global_rect().size.y < 42.0 or tombol.get_global_rect().size.x < 42.0):
			print("TIDAK SESUAI [%s]: tombol %s < 42 px" % [nama, tombol.get_global_rect()])
			salah += 1
	for simpul: Node in layar.find_children("*", "Label", true, false):
		var label: Label = simpul as Label
		if label.is_visible_in_tree() and label.get_visible_line_count() != label.get_line_count():
			print("TIDAK SESUAI [%s]: teks terpotong '%s'" % [nama, label.text])
			salah += 1
	print("bengkel [%s]: saldo %s, belanja %d, isi %s, tombol hari %s, ongkos '%s', %d tidak sesuai" % [nama, layar.teks_saldo(), layar.belanja_koin(), layar.rect_isi(), layar.rect_tombol_hari(), layar.teks_ongkos(), salah])
	print("teks: %s" % [" | ".join(layar.teks_tampil())])
	_gagal += salah


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
