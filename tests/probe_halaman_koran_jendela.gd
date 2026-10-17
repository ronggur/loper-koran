extends SceneTree
## Probe halaman depan koran di jendela asli, non-headless (AC-28 run fase4a-koran-hari): memuat `scenes/koran/halaman_koran.tscn` dan memotret
## keadaannya: hari 1 nyata (belum dipilih), Ambil, Lewati, teks terpanjang (headline 40, ringkasan 60 karakter huruf lebar), tanpa misi (S-8),
## headline lanjutan tanpa misi, notifikasi save (rusak, tidak terbaca, simpan gagal), dan inset aman (cutout). Mencetak ukuran teks yang dibutuhkan dan tersedia tiap label
## dan jumlah keadaan yang tidak sesuai (teks terpotong, kontrol tumpang tindih atau di luar layar). Tidak interaktif: keluar lewat `ProbeKeluar`.
##
## Pakai (jendela harus muat di layar monitor):
##   godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_halaman_koran_jendela.gd -- docs/loop/<RUN_ID>/shots/iter<N>
##   (juga 1920x1080, 2400x1080, 1600x720)
## Berkas: `<lebar>x<tinggi>_koran_<keadaan>.png`.

const BERKAS_KORAN: String = "res://scenes/koran/halaman_koran.tscn"
const FRAME_TUNGGU: int = 6

var _folder: String = ""
var _awalan: String = ""
var _gagal: int = 0
var _koran: HalamanKoran


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
	_koran.tampilkan_notifikasi("")
	var inset: ZonaAman.Inset = ZonaAman.Inset.new()
	inset.awal_x = 24
	inset.akhir_x = 24
	inset.atas = 12
	inset.bawah = 16
	_koran.atur_inset(inset)
	_koran.isi(HalamanUji.terpanjang(), 12, "perumahan")
	await _foto("inset_aman")
	HalamanUji.lepas_terjemahan(terjemahan)
	print("probe selesai, %d keadaan tidak sesuai" % _gagal)
	await ProbeKeluar.keluar(self, 0 if _gagal == 0 else 1)


func _tunggu(frame: int) -> void:
	for i: int in range(frame):
		await process_frame


## Memeriksa tata letak (teks tidak terpotong, kontrol dalam layar dan tidak bertumpuk) lalu memotret.
func _foto(keadaan: String) -> void:
	await _tunggu(FRAME_TUNGGU)
	var layar: Rect2 = Rect2(Vector2.ZERO, root.get_visible_rect().size)
	var salah: Array[String] = []
	for ukuran: Dictionary in _koran.ukur_label():
		if float(ukuran["dibutuhkan"]) > float(ukuran["tersedia"]) + 1.0 or int(ukuran["garis"]) > int(ukuran["terlihat"]):
			salah.append("teks terpotong: %s (%s)" % [ukuran["nama"], ukuran])
	var tombol: Array[Rect2] = [_koran.rect_tombol_berangkat()]
	if _koran.ada_misi():
		tombol.append(_koran.rect_tombol_ambil())
		tombol.append(_koran.rect_tombol_lewati())
	for i: int in range(tombol.size()):
		if not layar.encloses(tombol[i]):
			salah.append("tombol %d di luar layar: %s" % [i, tombol[i]])
		for j: int in range(i + 1, tombol.size()):
			if tombol[i].intersects(tombol[j]):
				salah.append("tombol %d dan %d bertumpuk" % [i, j])
	print("%s: %d label, %d kontrol, %s" % [keadaan, _koran.rect_label_tampil().size(), tombol.size(), "OK" if salah.is_empty() else "; ".join(salah)])
	_gagal += salah.size()
	if _folder.is_empty():
		return
	var gambar: Image = root.get_texture().get_image()
	var berkas: String = "%s/%s_koran_%s.png" % [_folder, _awalan, keadaan]
	var galat: int = gambar.save_png(berkas)
	print("tangkapan layar %dx%d (%s) ke %s (kode %d)" % [gambar.get_width(), gambar.get_height(), keadaan, berkas, galat])
