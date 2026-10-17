extends SceneTree
## Probe spike rumah sisi dekat di jendela asli (run fase3c-hud-hasil AC-15, usulan): memuat `scenes/dev/spike_sisi_dekat.tscn` dan, untuk
## tiap pendekatan (1 rendah dan kontras rendah, 2 tembok belakang rendah, 3 punggung penuh semi-transparan lewat aturan penutup),
## memotret: sepeda di jalur dekat di samping rumah pelanggan dekat, sepeda di trotoar dekat (posisi yang paling mungkin tertutup rumah
## dekat), lalu swipe ke kotak surat sisi dekat rumah itu: garis bidik, koran terbang, dan penanda sesudah mendarat.
## Simulasi maju dengan langkah tetap `perbarui(1/60)`. Mencetak fakta untuk catatan perbandingan di LOG: banyaknya gambar yang menutupi
## pemain dan alfanya, serta pecahan piksel kotak surat dan zonanya yang tertutup gambar di depannya (`SpikeSisiDekat.sasaran_tertutup`).
## TIDAK memilih pendekatan. Keluar lewat `ProbeKeluar`.
##
## Pakai (jendela harus muat di layar monitor):
##   godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_spike_sisi_dekat_jendela.gd -- docs/loop/<RUN_ID>/shots/spike_sisi_dekat
## Berkas: `<lebar>x<tinggi>_p<n>_<pendekatan>_<keadaan>.png`.

const BERKAS_SPIKE: String = "res://scenes/dev/spike_sisi_dekat.tscn"
const FRAME_TUNGGU_LAYOUT: int = 5
const DT: float = 1.0 / 60.0
## Kavling rumah pelanggan dekat yang difoto (pola spike: kavling 3 pelanggan, maju 20).
const KAVLING: int = 3
## Jarak sepeda untuk foto jalur dan trotoar, relatif awal kavling (ubin): rumah dan kotak surat sedikit di depan; trotoar = posisi
## kaki pemain di bawah atap rumah penuh (`PenutupPemain`).
const MAJU_JALUR: float = -1.5
const MAJU_TROTOAR: float = 2.0
const LATERAL_JALUR: float = 0.5
const LATERAL_TROTOAR: float = 1.75
## Sepeda saat swipe lempar, ubin relatif awal kavling foto: kotak surat sekitar 4 ubin di depan, jadi mendarat di atas panel bawah HUD.
const MAJU_LEMPAR: float = -2.0
## Titik awal swipe (piksel game): pecahan lebar viewport dan tinggi, di zona swipe kanan.
const SWIPE_X_PECAHAN: float = 0.72
const SWIPE_Y: float = 250.0
const FOTO_TERBANG_PECAHAN: float = 0.5
const NAMA: Dictionary = {1: "rendah", 2: "tembok", 3: "penuh"}

var _skala: float = 1.0
var _folder: String = ""
var _awalan: String = ""
var _akar: SpikeSisiDekat
var _sepeda: SepedaUji
var _sprite: LoperSprite
var _debu: PancaranPiksel
var _garis: PancaranPiksel
var _kontrol: KontrolTouch
var _gagal: int = 0
var _lapis: CanvasLayer


func _initialize() -> void:
	var argumen: PackedStringArray = OS.get_cmdline_user_args()
	_folder = argumen[0] if argumen.size() > 0 else ""
	var paket: PackedScene = load(BERKAS_SPIKE) as PackedScene
	if paket == null:
		push_error("scene spike tidak bisa dimuat")
		await ProbeKeluar.keluar(self, 1)
		return
	_akar = paket.instantiate() as SpikeSisiDekat
	root.add_child(_akar)
	_lapis = CanvasLayer.new()
	_lapis.layer = 50
	root.add_child(_lapis)
	await _tunggu(FRAME_TUNGGU_LAYOUT)
	_akar.set_process(false)
	var terlihat: Vector2 = root.get_visible_rect().size
	_skala = float(root.size.x) / terlihat.x
	_awalan = "%dx%d" % [root.size.x, root.size.y]
	_sepeda = _akar.find_child("Sepeda", true, false) as SepedaUji
	_kontrol = _akar.find_child("KontrolTouch", true, false) as KontrolTouch
	_sprite = _akar.find_child("LoperAgen", true, false) as LoperSprite
	_sprite.set_process(false)
	_debu = _sepeda.umpan_balik().debu()
	_garis = _sepeda.umpan_balik().garis()
	_debu.set_process(false)
	_garis.set_process(false)
	_kontrol.keyboard_aktif = false
	var indeks: int = KAVLING * 2 + 1
	var rumah: RouteBuilder.RumahRute = _akar.rute().rumah[indeks]
	print("jendela %s: viewport terlihat %dx%d, skala x%s" % [root.size, int(terlihat.x), int(terlihat.y), _skala])
	print("rumah foto: %s sisi %s pelanggan %s maju %.1f" % [rumah.id, LoperAnim.Sisi.keys()[rumah.sisi], rumah.pelanggan, rumah.maju_ubin])
	if rumah.sisi != LoperAnim.Sisi.DEKAT or not rumah.pelanggan:
		_gagal += 1
	for p: int in [1, 2, 3]:
		_akar.atur_pendekatan(p as SpikeSisiDekat.Pendekatan)
		var nama: String = "p%d_%s" % [p, NAMA[p]]
		var tutup: Vector2 = _akar.sasaran_tertutup(indeks)
		print("--- pendekatan %d (%s): piksel tertutup gambar di depannya: badan kotak surat %.0f%%, zona kotak surat di tanah %.0f%%" % [p, NAMA[p], tutup.x * 100.0, tutup.y * 100.0])
		_ringkas_sasaran(p)
		_letakkan(rumah.maju_ubin + MAJU_JALUR, LATERAL_JALUR)
		await _maju(0.25)
		await _foto(nama + "_jalur", indeks)
		_letakkan(rumah.maju_ubin + MAJU_TROTOAR, LATERAL_TROTOAR)
		await _maju(0.25)
		await _foto(nama + "_trotoar", indeks)
		_letakkan(rumah.maju_ubin + MAJU_LEMPAR, LATERAL_JALUR)
		await _maju(Config.LEMPAR_JEDA_DETIK)
		await _lempar_dekat(nama, indeks)
	print("probe selesai, %d keadaan tidak sesuai" % _gagal)
	await ProbeKeluar.keluar(self, 0 if _gagal == 0 else 1)


## Rata-rata dan maksimum piksel sasaran tertutup untuk SEMUA rumah pelanggan dekat (tiga jenis atap) pada pendekatan `p`.
func _ringkas_sasaran(p: int) -> void:
	var jumlah: int = 0
	var total: Vector2 = Vector2.ZERO
	var maks: Vector2 = Vector2.ZERO
	for i: int in range(_akar.rute().rumah.size()):
		var r: RouteBuilder.RumahRute = _akar.rute().rumah[i]
		if r.sisi != LoperAnim.Sisi.DEKAT or not r.pelanggan:
			continue
		var t: Vector2 = _akar.sasaran_tertutup(i)
		total += t
		maks = Vector2(maxf(maks.x, t.x), maxf(maks.y, t.y))
		jumlah += 1
	print("    semua %d pelanggan dekat (pendekatan %d): badan kotak surat rata-rata %.0f%% maks %.0f%%; zona rata-rata %.0f%% maks %.0f%%" % [jumlah, p, total.x / jumlah * 100.0, maks.x * 100.0, total.y / jumlah * 100.0, maks.y * 100.0])


func _letakkan(maju: float, lateral: float) -> void:
	_sepeda.jarak_ubin = maju
	_sepeda.lateral_ubin = lateral


## Swipe ke kotak surat sisi dekat rumah foto (`indeks`): sudut dan panjang dicari lewat `lintasan_swipe` scene (fungsi yang sama dengan
## garis bidik) sampai titik mendarat di zona kotak surat rumah itu; jari ditekan, digeser (garis bidik tampil satu langkah), lalu
## diangkat. Memotret garis bidik, koran terbang, lalu penanda sesudah mendarat.
func _lempar_dekat(nama: String, indeks: int) -> void:
	var zona: ZonaSasaran.Zona = null
	for z: ZonaSasaran.Zona in ZonaSasaran.zona_rumah(_akar.rute().rumah[indeks]):
		if z.jenis == ZonaSasaran.Jenis.KOTAK_SURAT:
			zona = z
	var lebar: float = root.get_visible_rect().size.x
	var awal: Vector2 = Vector2(roundf(lebar * SWIPE_X_PECAHAN), SWIPE_Y)
	var akhir: Vector2 = Vector2.INF
	for derajat: int in range(0, 91, 2):
		var panjang: float = ceilf(ThrowSolver.swipe_min_px(lebar))
		while panjang <= ThrowSolver.swipe_maks_px(lebar) and akhir == Vector2.INF:
			var coba: Vector2 = awal + Vector2(cos(deg_to_rad(derajat)), -sin(deg_to_rad(derajat))) * panjang
			var l: ThrowSolver.Lintasan = _akar.lintasan_swipe(awal, coba)
			if l != null and ZonaSasaran.memuat(zona, l.titik_mendarat):
				akhir = coba.round()
			panjang += 2.0
		if akhir != Vector2.INF:
			break
	if akhir == Vector2.INF:
		print("PERINGATAN %s: tidak ada swipe ke kotak surat dekat %s" % [nama, zona.id_rumah])
		_gagal += 1
		return
	_gambar_jari(awal, akhir)
	_sentuh(1, awal, true)
	_geser(1, akhir)
	await _maju(DT)
	await _foto(nama + "_lempar_bidik", -1)
	var sebelum: int = _akar.koran_terbang().size()
	_sentuh(1, akhir, false)
	_hapus_titik()
	if _akar.koran_terbang().size() != sebelum + 1:
		print("PERINGATAN %s: swipe tidak melempar" % nama)
		_gagal += 1
		return
	print("%s: swipe %s -> %s ke %s" % [nama, awal, akhir, zona.id_rumah])
	var koran: KoranLempar.Koran = _akar.koran_terbang()[_akar.koran_terbang().size() - 1]
	await _maju(koran.lintasan.jeda_lepas + koran.lintasan.lama_terbang * FOTO_TERBANG_PECAHAN)
	await _foto(nama + "_lempar_terbang", -1)
	var batas: int = 0
	while not _koran_ini(koran).mendarat and batas < 120:
		await _maju(DT, false)
		batas += 1
	var mendarat: KoranLempar.Koran = _koran_ini(koran)
	await _maju(DT)
	print("%s: mendarat %s, hasil %s, penanda %s" % [nama, mendarat.mendarat, ZonaSasaran.Hasil.keys()[mendarat.hasil], ZonaSasaran.Penanda.keys()[mendarat.penanda]])
	if mendarat.hasil != ZonaSasaran.Hasil.KOTAK_SURAT or mendarat.penanda != ZonaSasaran.Penanda.CENTANG:
		_gagal += 1
	await _foto(nama + "_lempar_kena", -1)


func _gambar_jari(awal: Vector2, akhir: Vector2) -> void:
	_hapus_titik()
	var jumlah: int = floori(awal.distance_to(akhir) / 6.0)
	for i: int in range(jumlah + 1):
		var titik: ColorRect = ColorRect.new()
		titik.color = Palette.ACCENT
		titik.size = Vector2(4, 4) if i == 0 else Vector2(2, 2)
		titik.position = awal.lerp(akhir, float(i) / float(maxi(jumlah, 1))).round()
		_lapis.add_child(titik)


func _geser(index: int, posisi_viewport: Vector2) -> void:
	var peristiwa: InputEventScreenDrag = InputEventScreenDrag.new()
	peristiwa.index = index
	peristiwa.position = posisi_viewport * _skala
	Input.parse_input_event(peristiwa)
	Input.flush_buffered_events()


func _koran_ini(koran: KoranLempar.Koran) -> KoranLempar.Koran:
	for k: KoranLempar.Koran in _akar.koran_terbang():
		if k.lintasan == koran.lintasan:
			return k
	return koran


func _hapus_titik() -> void:
	for anak: Node in _lapis.get_children():
		anak.queue_free()


func _tunggu(jumlah: int) -> void:
	for i: int in range(jumlah):
		await process_frame


func _maju(detik: float, gambar: bool = true) -> void:
	for i: int in range(maxi(roundi(detik / DT), 1)):
		if _akar.sedang_jeda():
			print("PERINGATAN: layar jeda terbuka (jendela kehilangan fokus); probe melanjutkan lewat minta_lanjut")
			_akar.minta_lanjut()
		_akar.perbarui(DT)
		_sprite.maju(DT)
		_debu.maju(DT)
		_garis.maju(DT)
	if gambar:
		await _tunggu(2)


func _sentuh(index: int, posisi_viewport: Vector2, tekan: bool) -> void:
	var peristiwa: InputEventScreenTouch = InputEventScreenTouch.new()
	peristiwa.index = index
	peristiwa.position = posisi_viewport * _skala
	peristiwa.pressed = tekan
	Input.parse_input_event(peristiwa)
	Input.flush_buffered_events()


func _foto(keadaan: String, indeks_rumah: int) -> void:
	await _tunggu(3)
	var penerap: PenerapPenutup = _akar.penerap_penutup()
	var alfa: String = ""
	if indeks_rumah >= 0:
		alfa = ", alfa rumah foto %.2f" % _akar.sprite_rumah(indeks_rumah).modulate.a
	print("%s: jarak %.2f, lateral %.2f, gambar terdaftar %d, menutupi pemain %d%s" % [keadaan, _sepeda.jarak_ubin, _sepeda.lateral_ubin, penerap.jumlah(), penerap.jumlah_menutupi(), alfa])
	if _folder.is_empty():
		return
	var gambar: Image = root.get_texture().get_image()
	var berkas: String = "%s/%s_%s.png" % [_folder, _awalan, keadaan]
	var galat: int = gambar.save_png(berkas)
	print("tangkapan layar %dx%d (%s) ke %s (kode %d)" % [gambar.get_width(), gambar.get_height(), keadaan, berkas, galat])
