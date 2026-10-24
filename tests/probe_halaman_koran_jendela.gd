extends SceneTree
## Probe halaman depan koran di jendela asli, non-headless (AC-28 run fase4a-koran-hari; ditulis ulang run ui2-semua-layar bagian B, AC-3 dan AC-9; kanvas Koran*.dc.html): memuat `scenes/koran/halaman_koran.tscn` dan memotret
## semua keadaan papan: hari 1 belum dipilih, Ambil, Lewati, hari 2, teks terpanjang (headline 40, ringkasan 60 karakter huruf lebar, dengan foto jalan), terpanjang tanpa foto, foto lampu, tanpa misi (S-8), headline
## lanjutan tanpa misi, notifikasi save (rusak, tidak terbaca, simpan gagal), dan inset aman (cutout). Mencetak ukuran teks yang dibutuhkan dan tersedia tiap label dan jumlah keadaan yang tidak sesuai: teks terpotong,
## kontrol atau teks di luar zona aman, tumpang tindih (label, tombol, foto, ikon, kotak iklan, notifikasi, kolom), tombol < 42 tinggi atau < 84 lebar, kolom misi, garis tegak, dan Berangkat tidak sama dengan
## `TampilKoran.tata`, foto bukan 100x62, kolom meluap ke bawah. Menulis juga `<awalan>_koran_<keadaan>.json` (persegi teks, tombol, kotak) yang dibaca `tools/ukur_kontras_tangkapan.py --jenis koran`.
## Tidak interaktif: keluar lewat `ProbeKeluar`. Tidak menulis save apa pun.
##
## Pakai (jendela harus muat di layar monitor):
##   godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_halaman_koran_jendela.gd -- docs/loop/<RUN_ID>/shots/iter<N>
##   (juga 1920x1080 = lebar 640, 2400x1080 = lebar 800, 1600x720 = lebar 800)
## Berkas: `<lebar>x<tinggi>_koran_<keadaan>.png`.

const BERKAS_KORAN: String = "res://scenes/koran/halaman_koran.tscn"
const FRAME_TUNGGU: int = 6
const TOMBOL_TINGGI_MIN: float = 42.0
const TOMBOL_LEBAR_MIN: float = 84.0
const TOLERANSI: float = 0.5

var _folder: String = ""
var _awalan: String = ""
var _gagal: int = 0
var _koran: HalamanKoran
var _inset: ZonaAman.Inset = ZonaAman.Inset.new()


func _initialize() -> void:
	var argumen: PackedStringArray = OS.get_cmdline_user_args()
	_folder = argumen[0] if argumen.size() > 0 else ""
	var paket: PackedScene = load(BERKAS_KORAN) as PackedScene
	if paket == null:
		push_error("scene koran tidak bisa dimuat")
		await ProbeKeluar.keluar(self, 1)
		return
	var terjemahan: Translation = HalamanUji.pasang_terjemahan()
	_koran = paket.instantiate() as HalamanKoran
	root.add_child(_koran)
	await _tunggu(FRAME_TUNGGU)
	_awalan = "%dx%d" % [root.size.x, root.size.y]
	var terlihat: Vector2 = root.get_visible_rect().size
	print("jendela %s: viewport terlihat %dx%d" % [root.size, int(terlihat.x), int(terlihat.y)])

	_koran.isi(HalamanUji.nyata(1), 1, "perumahan")
	await _foto("hari1")
	_koran.atur_pilihan(HalamanKoran.Pilihan.AMBIL)
	await _foto("ambil")
	_koran.atur_pilihan(HalamanKoran.Pilihan.LEWATI)
	await _foto("lewati")
	_koran.isi(HalamanUji.nyata(2), 2, "perumahan")
	await _foto("hari2")
	_koran.isi(HalamanUji.terpanjang(), 12, "perumahan")
	await _foto("terpanjang")
	_koran.atur_pilihan(HalamanKoran.Pilihan.AMBIL)
	await _foto("terpanjang_ambil")
	_koran.isi(HalamanUji.dengan_efek(HalamanUji.terpanjang(), "hajatan"), 12, "perumahan")
	await _foto("terpanjang_tanpa_foto")
	_koran.isi(HalamanUji.dengan_efek(HalamanUji.nyata(2), "mati_lampu"), 2, "perumahan")
	await _foto("foto_lampu")
	_koran.isi(HalamanUji.tanpa_misi(), 3, "perumahan")
	await _foto("tanpa_misi")
	_koran.isi(HalamanUji.lanjutan_tanpa_misi(), 4, "perumahan")
	await _foto("lanjutan")
	_koran.isi(HalamanUji.nyata(1), 1, "perumahan")
	_koran.tampilkan_notifikasi("KORAN_SAVE_RUSAK")
	await _foto("save_rusak")
	_koran.tampilkan_notifikasi("KORAN_SAVE_TIDAK_TERBACA")
	await _foto("save_tidak_terbaca")
	_koran.tampilkan_notifikasi("KORAN_SAVE_GAGAL")
	await _foto("save_gagal")
	_koran.isi(HalamanUji.terpanjang(), 12, "perumahan")
	_koran.tampilkan_notifikasi("KORAN_SAVE_TIDAK_TERBACA")
	await _foto("terpanjang_save")
	_koran.tampilkan_notifikasi("")
	_inset.awal_x = 24
	_inset.akhir_x = 24
	_inset.atas = 12
	_inset.bawah = 16
	_koran.atur_inset(_inset)
	_koran.isi(HalamanUji.terpanjang(), 12, "perumahan")
	await _foto("inset_aman")
	_koran.isi(HalamanUji.nyata(1), 1, "perumahan")
	await _foto("inset_aman_hari1")
	HalamanUji.lepas_terjemahan(terjemahan)
	print("probe selesai, %d keadaan tidak sesuai" % _gagal)
	await ProbeKeluar.keluar(self, 0 if _gagal == 0 else 1)


func _tunggu(frame: int) -> void:
	for i: int in range(frame):
		await process_frame


func _luas_tumpang(a: Rect2, b: Rect2) -> float:
	var i: Rect2 = a.intersection(b)
	return maxf(i.size.x, 0.0) * maxf(i.size.y, 0.0)


## Label yang tampil: nama simpul dan persegi.
func _label_tampil() -> Array[Dictionary]:
	var hasil: Array[Dictionary] = []
	for simpul: Node in _koran.find_children("*", "Label", true, false):
		var label: Label = simpul as Label
		if label.is_visible_in_tree() and label.text != "":
			hasil.append({"nama": String(label.name), "rect": label.get_global_rect()})
	return hasil


## Memeriksa tata letak lalu memotret; menambah jumlah keadaan tidak sesuai ke `_gagal`.
func _foto(keadaan: String) -> void:
	await _tunggu(FRAME_TUNGGU)
	var viewport: Rect2 = Rect2(Vector2.ZERO, root.get_visible_rect().size)
	var tata: TampilKoran.Tata = _koran.tata()
	var aman: Rect2 = Rect2(float(tata.margin_awal), float(tata.margin_atas), float(tata.lebar_isi), viewport.size.y - float(tata.margin_atas) - float(tata.margin_bawah))
	var salah: Array[String] = []
	for ukuran: Dictionary in _koran.ukur_label():
		if float(ukuran["dibutuhkan"]) > float(ukuran["tersedia"]) + 1.0 or int(ukuran["garis"]) > int(ukuran["terlihat"]):
			salah.append("teks terpotong: %s (%s)" % [ukuran["nama"], ukuran])
	var tombol: Dictionary = {"Berangkat": _koran.rect_tombol_berangkat()}
	if _koran.ada_misi():
		tombol["Ambil"] = _koran.rect_tombol_ambil()
		tombol["Lewati"] = _koran.rect_tombol_lewati()
	var nama_tombol: Array = tombol.keys()
	for i: int in range(nama_tombol.size()):
		var r: Rect2 = tombol[nama_tombol[i]]
		if not aman.grow(TOLERANSI).encloses(r):
			salah.append("tombol %s di luar zona aman: %s" % [nama_tombol[i], r])
		if r.size.y < TOMBOL_TINGGI_MIN - TOLERANSI or r.size.x < TOMBOL_LEBAR_MIN - TOLERANSI:
			salah.append("tombol %s terlalu kecil: %s" % [nama_tombol[i], r.size])
		for j: int in range(i + 1, nama_tombol.size()):
			if _luas_tumpang(r, tombol[nama_tombol[j]]) > 0.0:
				salah.append("tombol %s dan %s bertumpuk" % [nama_tombol[i], nama_tombol[j]])
	# Semua label dan elemen berada di zona aman, dan tidak ada yang bertumpuk.
	var elemen: Dictionary = {}
	for l: Dictionary in _label_tampil():
		elemen["label " + String(l["nama"])] = l["rect"]
	for nama: String in nama_tombol:
		elemen["tombol " + nama] = tombol[nama]
	if _koran.foto_tampil():
		elemen["foto"] = _koran.rect_foto()
	if _koran.nama_ikon_utama() != "":
		elemen["ikon utama"] = _koran.rect_ikon_utama()
	elemen["ikon misi"] = _koran.rect_ikon_misi()
	if _koran.iklan_tampil():
		elemen["kotak iklan"] = _koran.rect_iklan()
	if _koran.notifikasi_tampil():
		elemen["kotak notifikasi"] = _koran.rect_notifikasi()
	elemen["garis ganda"] = _koran.rect_garis_ganda()
	var nama_elemen: Array = elemen.keys()
	for i: int in range(nama_elemen.size()):
		var a: String = nama_elemen[i]
		var batas_aman: Rect2 = aman
		if a == "label NamaKoran":
			# Kotak baris nama koran dinaikkan `KORAN_KEPALA_NAIK_PX` di atas margin (tinggi baris Lilita 32 lebih besar dari tinta huruf, seperti kanvas); tinta huruf tetap di dalam zona aman.
			batas_aman = Rect2(aman.position.x, aman.position.y - float(Config.KORAN_KEPALA_NAIK_PX), aman.size.x, aman.size.y + float(Config.KORAN_KEPALA_NAIK_PX))
		if not batas_aman.grow(TOLERANSI).encloses(elemen[a]):
			salah.append("%s di luar zona aman: %s" % [a, elemen[a]])
		for j: int in range(i + 1, nama_elemen.size()):
			var b: String = nama_elemen[j]
			# Label iklan dan label notifikasi berada di dalam kotaknya sendiri.
			if (a == "kotak iklan" and b == "label LabelIklan") or (b == "kotak iklan" and a == "label LabelIklan"):
				continue
			if (a == "kotak notifikasi" and b == "label Notifikasi") or (b == "kotak notifikasi" and a == "label Notifikasi"):
				continue
			if _luas_tumpang(elemen[a], elemen[b]) > 0.5:
				salah.append("%s dan %s bertumpuk: %s vs %s" % [a, b, elemen[a], elemen[b]])
	# Kotak misi tidak menutupi Berangkat; kolom tidak meluap ke bawah dan tidak bertumpuk.
	if _luas_tumpang(_koran.rect_panel_misi(), _koran.rect_tombol_berangkat()) > 0.0:
		salah.append("kotak misi menutupi Berangkat")
	if _koran.rect_kolom_berita().end.y > aman.end.y + TOLERANSI or _koran.rect_kolom_misi().end.y > aman.end.y + TOLERANSI:
		salah.append("kolom meluap ke bawah: berita %s misi %s batas %s" % [_koran.rect_kolom_berita().end.y, _koran.rect_kolom_misi().end.y, aman.end.y])
	if _luas_tumpang(_koran.rect_kolom_berita(), _koran.rect_kolom_misi()) > 0.0:
		salah.append("kolom berita dan misi bertumpuk")
	# Sama dengan tata letak murni.
	if not is_equal_approx(_koran.rect_kolom_misi().size.x, float(tata.lebar_misi)):
		salah.append("lebar kolom misi %s != tata %d" % [_koran.rect_kolom_misi().size.x, tata.lebar_misi])
	if not is_equal_approx(_koran.rect_kolom_berita().size.x, float(tata.lebar_berita)):
		salah.append("lebar kolom berita %s != tata %d" % [_koran.rect_kolom_berita().size.x, tata.lebar_berita])
	if not is_equal_approx(_koran.rect_garis_tegak().position.x, float(tata.x_garis)):
		salah.append("x garis tegak %s != tata %d" % [_koran.rect_garis_tegak().position.x, tata.x_garis])
	if _koran.rect_tombol_berangkat() != Rect2(tata.berangkat):
		salah.append("Berangkat %s != tata %s" % [_koran.rect_tombol_berangkat(), tata.berangkat])
	if _koran.foto_tampil() and _koran.rect_foto().size != Vector2(float(Config.KORAN_FOTO_LEBAR_PX), float(Config.KORAN_FOTO_TINGGI_PX)):
		salah.append("foto bukan 100x62: %s" % _koran.rect_foto().size)
	var tb: Button = _koran.tombol_berangkat()
	var mb: int = GayaHud.margin_glif_tombol(tb)
	if mb != roundi((tb.get_theme_stylebox(&"normal") as StyleBox).content_margin_right) + GayaHud.pad_kanan_glif(tb) or mb < Config.UI_TOMBOL_GLIF_MARGIN_MIN_PX or float(GayaHud.lebar_teks_tombol(tb) + tb.get_theme_constant(&"h_separation") + tb.icon.get_width() + mb * 2 - GayaHud.pad_kanan_glif(tb)) > tb.size.x + 0.01:
		salah.append("panah Berangkat: margin %d tidak sama kiri-kanan, di bawah minimum, atau teks terpotong (R-1)" % mb)
	print("%s: %d label, %d kontrol, foto '%s', ikon '%s', iklan %s, notif %s, %s" % [keadaan, _label_tampil().size(), tombol.size(), _koran.nama_foto(), _koran.nama_ikon_utama(), _koran.iklan_tampil(), _koran.notifikasi_tampil(), "OK" if salah.is_empty() else "; ".join(salah)])
	_gagal += salah.size()
	if _folder.is_empty():
		return
	var gambar: Image = root.get_texture().get_image()
	var berkas: String = "%s/%s_koran_%s.png" % [_folder, _awalan, keadaan]
	var galat: int = gambar.save_png(berkas)
	print("tangkapan layar %dx%d (%s) ke %s (kode %d)" % [gambar.get_width(), gambar.get_height(), keadaan, berkas, galat])
	_tulis_ukuran(keadaan, tombol)


## Persegi dan warna token tiap teks dan komponen ke `<awalan>_koran_<keadaan>.json` untuk `tools/ukur_kontras_tangkapan.py --jenis koran`.
func _tulis_ukuran(keadaan: String, tombol: Dictionary) -> void:
	var teks: Array = []
	for simpul: Node in _koran.find_children("*", "Label", true, false):
		var label: Label = simpul as Label
		if label.is_visible_in_tree() and label.text != "":
			var r: Rect2 = label.get_global_rect()
			teks.append({"teks": tr(label.text), "rect": [r.position.x, r.position.y, r.size.x, r.size.y], "warna": "#" + label.get_theme_color(&"font_color").to_html(false)})
	for simpul: Node in _koran.find_children("*", "Button", true, false):
		var tb: Button = simpul as Button
		if tb.is_visible_in_tree() and tb.text != "":
			var r2: Rect2 = tb.get_global_rect()
			teks.append({"teks": tr(tb.text), "rect": [r2.position.x, r2.position.y, r2.size.x, r2.size.y], "warna": "#" + tb.get_theme_color(&"font_color").to_html(false)})
	var komponen: Array = []
	for nama: String in tombol:
		var rt: Rect2 = tombol[nama]
		komponen.append({"jenis": "tombol" if nama == "Berangkat" else "pilih", "rect": [rt.position.x, rt.position.y, rt.size.x, rt.size.y]})
	var rp: Rect2 = _koran.rect_panel_misi()
	komponen.append({"jenis": "kotak_misi", "rect": [rp.position.x, rp.position.y, rp.size.x, rp.size.y]})
	var berkas: FileAccess = FileAccess.open("%s/%s_koran_%s.json" % [_folder, _awalan, keadaan], FileAccess.WRITE)
	if berkas != null:
		berkas.store_string(JSON.stringify({"viewport": [root.get_visible_rect().size.x, root.get_visible_rect().size.y], "teks": teks, "komponen": komponen}))
