extends SceneTree
## Probe tampilan sisi dekat di jendela asli, non-headless (AC-22 run fase5b-tembok-dekor; bagian B1: tembok; bagian lain menambah skenario dekor dan ubin ke probe yang sama): memuat
## `scenes/rute/rute.tscn`, memajukan simulasi dengan langkah tetap `perbarui(1/60)` (bukan waktu dinding), lalu menyimpan tangkapan layar.
##
## Skenario bagian B1 (tembok belakang rendah, rumah penuh di belakangnya digeser 1,25 ubin):
## - `tembok_polos`, `tembok_bata`, `tembok_besi`, `tembok_pot`: rute nyata, sepeda di jalur dekat di samping rumah dekat pertama berbarengan varian itu (id rumah -> FNV-1a); tiang ujung terlihat.
## - `tembok_sasaran_*`: rute buatan (`SpikeSisiDekat.susun_rute`, pelanggan di sisi dekat, geometri `JALAN_UJI_DEKAT_*`, rute nyata tidak punya pelanggan dekat) dengan kotak surat sasaran di zona
##   dekat: garis bidik (`_bidik`), koran terbang (`_terbang`), dan penanda sesudah mendarat (`_kena`).
## - `tembok_jalur_dekat` dan `tembok_trotoar_dekat`: sepeda di jalur dekat (lateral 0,5) dan trotoar dekat (lateral 1,75) di samping rumah pelanggan dekat bertembok.
## - `kidal`: tata letak kidal dengan tembok di layar.
## Mencetak data tiap keadaan, kotak teks HUD, pecahan piksel sasaran yang tertimpa tembok (`UkurTembok`), dan keadaan yang tidak sesuai harapan (nol bila baik). Tidak interaktif: keluar sendiri lewat
## `ProbeKeluar`. Tidak menulis `user://save.json`.
##
## Pakai (jendela harus muat di layar monitor), empat ukuran:
##   godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_sisi_dekat_jendela.gd -- docs/loop/<RUN_ID>/shots/iter<N>
##   godot --path . --resolution 1920x1080 --position 0,0 --script res://tests/probe_sisi_dekat_jendela.gd -- docs/loop/<RUN_ID>/shots/iter<N>
##   godot --path . --resolution 2400x1080 --position 0,0 --script res://tests/probe_sisi_dekat_jendela.gd -- docs/loop/<RUN_ID>/shots/iter<N>
##   godot --path . --resolution 1600x720 --position 0,0 --script res://tests/probe_sisi_dekat_jendela.gd -- docs/loop/<RUN_ID>/shots/iter<N>
## Berkas: `<lebar>x<tinggi>_dekat_<keadaan>.png`.

const BERKAS_RUTE: String = "res://scenes/rute/rute.tscn"
const ADEGAN_KOTAK_SURAT: PackedScene = preload("res://scenes/entities/kotak_surat.tscn")
const FRAME_TUNGGU_LAYOUT: int = 5
const DT: float = 1.0 / 60.0
## Sepeda di belakang awal kavling rumah foto varian (ubin), supaya rumah dan tembok masuk layar di kanan atas pemain.
const MAJU_FOTO_VARIAN: float = -2.0
const LATERAL_JALUR: float = 0.5
const LATERAL_TROTOAR: float = 1.75
## Kavling rumah pelanggan dekat rute buatan yang difoto (pola spike: kavling 3, indeks rumah = kavling * 2 + 1).
const KAVLING: int = 3
const MAJU_JALUR: float = -1.5
const MAJU_TROTOAR: float = 0.5
## Sepeda saat swipe lempar, relatif awal kavling foto.
const MAJU_LEMPAR: float = -2.0
const SWIPE_X_PECAHAN: float = 0.72
const SWIPE_Y: float = 250.0
const FOTO_TERBANG_PECAHAN: float = 0.5
const VARIAN: Array[String] = ["polos", "bata", "besi", "pot"]

var _skala: float = 1.0
var _folder: String = ""
var _awalan: String = ""
var _akar: RuteMain
var _sepeda: SepedaUji
var _hud: HudRute
var _kontrol: KontrolTouch
var _sprite: LoperSprite
var _vfx: VfxSepedaGambar
var _gagal: int = 0
var _lapis: CanvasLayer


func _initialize() -> void:
	var argumen: PackedStringArray = OS.get_cmdline_user_args()
	_folder = argumen[0] if argumen.size() > 0 else ""
	if not _folder.is_empty():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + _folder) if not _folder.is_absolute_path() else _folder)
	if not await _muat():
		await ProbeKeluar.keluar(self, 1)
		return
	_lapis = CanvasLayer.new()
	_lapis.layer = 50
	root.add_child(_lapis)
	var terlihat: Vector2 = root.get_visible_rect().size
	_skala = float(root.size.x) / terlihat.x
	_awalan = "%dx%d" % [root.size.x, root.size.y]
	print("jendela %s: viewport terlihat %dx%d, skala x%s (driver %s, renderer %s)" % [root.size, int(terlihat.x), int(terlihat.y), _skala, DisplayServer.get_name(), RenderingServer.get_current_rendering_method()])
	var rute: RouteBuilder.Rute = _akar.rute()
	print("rute: seed %d, panjang %.0f ubin, %d rumah, galat %s" % [_akar.benih(), rute.panjang_ubin, rute.rumah.size(), _akar.galat_rute()])
	_cetak_kecualikan("HUD", [_hud.rect_tombol_jeda(), _hud.rect_panel_progres(), _hud.rect_panel_kecepatan(), _hud.rect_panel_koran()])

	# --- Empat varian tembok di rute nyata (rumah dekat, tiang ujung, rumah penuh di belakang) ---
	for varian: String in VARIAN:
		var rumah: RouteBuilder.RumahRute = _rumah_dekat_varian(varian)
		_cek(rumah != null, "rute nyata memuat rumah dekat bertembok %s" % varian)
		if rumah == null:
			continue
		_taruh(3.0, LATERAL_JALUR, rumah.maju_ubin + MAJU_FOTO_VARIAN)
		await _maju(0.25)
		await _foto("tembok_%s" % varian, rumah)
		_periksa_tembok(rumah, varian)

	# --- Rute buatan dengan pelanggan di sisi dekat: ukur sasaran, jalur dekat, trotoar dekat, garis bidik, koran terbang, kena ---
	_pasang_rute_buatan()
	var indeks: int = KAVLING * 2 + 1
	var foto: RouteBuilder.RumahRute = _akar.rute().rumah[indeks]
	print("rumah foto: %s sisi %s pelanggan %s maju %.1f varian tembok %s" % [foto.id, LoperAnim.Sisi.keys()[foto.sisi], foto.pelanggan, foto.maju_ubin, VarianTembok.pilih(foto.id)])
	_cek(foto.sisi == LoperAnim.Sisi.DEKAT and foto.pelanggan, "rumah foto rute buatan: pelanggan di sisi dekat")
	_cetak_ukur()
	_taruh(3.0, LATERAL_JALUR, foto.maju_ubin + MAJU_JALUR)
	await _maju(0.25)
	await _foto("tembok_jalur_dekat", foto)
	_taruh(3.0, LATERAL_TROTOAR, foto.maju_ubin + MAJU_TROTOAR)
	await _maju(0.25)
	await _foto("tembok_trotoar_dekat", foto)
	_taruh(3.0, LATERAL_JALUR, foto.maju_ubin + MAJU_LEMPAR)
	await _maju(Config.LEMPAR_JEDA_DETIK)
	await _lempar_dekat("tembok_sasaran", foto)

	# --- Kidal ---
	_akar.atur_kidal(true)
	await _tunggu(3)
	_cetak_kecualikan("kidal", [_hud.rect_tombol_jeda(), _hud.rect_panel_progres(), _hud.rect_panel_kecepatan(), _hud.rect_panel_koran()])
	_taruh(3.0, LATERAL_JALUR, foto.maju_ubin + MAJU_JALUR)
	await _maju(0.25)
	await _foto("kidal", foto)
	_akar.atur_kidal(false)

	print("probe selesai, %d keadaan tidak sesuai" % _gagal)
	await ProbeKeluar.keluar(self, 0 if _gagal == 0 else 1)


## Memuat scene rute ke pohon dan menyiapkan rujukan. True bila berhasil.
func _muat() -> bool:
	var paket: PackedScene = load(BERKAS_RUTE) as PackedScene
	if paket == null:
		push_error("scene rute tidak bisa dimuat")
		return false
	_akar = paket.instantiate() as RuteMain
	root.add_child(_akar)
	await _tunggu(FRAME_TUNGGU_LAYOUT)
	_akar.set_process(false)
	_sepeda = _akar.find_child("Sepeda", true, false) as SepedaUji
	_hud = _akar.hud_rute()
	_kontrol = _akar.find_child("KontrolTouch", true, false) as KontrolTouch
	_sprite = _akar.find_child("LoperAgen", true, false) as LoperSprite
	_sprite.set_process(false)
	_vfx = _sepeda.umpan_balik().sprite()
	_vfx.set_process(false)
	_kontrol.keyboard_aktif = false
	return true


## Rumah dekat pertama di rute nyata yang id-nya memilih varian `varian` dan kavlingnya cukup jauh dari awal.
func _rumah_dekat_varian(varian: String) -> RouteBuilder.RumahRute:
	for r: RouteBuilder.RumahRute in _akar.rute().rumah:
		if r.sisi == LoperAnim.Sisi.DEKAT and r.maju_ubin >= 8.0 and VarianTembok.pilih(r.id) == varian:
			return r
	return null


## Rute buatan spike (pelanggan sisi dekat) menggantikan rute nyata di scene yang sama: medan, daur rumah, dan area kotak ikut diganti; kotak surat sasaran dekat
## digambar probe di pusat zona (rumah dekat nyata memang tanpa kotak surat).
func _pasang_rute_buatan() -> void:
	var rute: RouteBuilder.Rute = SpikeSisiDekat.susun_rute()
	_akar.set("_rute", rute)
	_akar.set("_medan", MedanKoran.dari_rute(rute))
	_akar.daur().atur_rute(rute)
	(_akar.find_child("AreaKotak", true, false) as AreaKotakGambar).atur_rute(rute)
	var objek: Node2D = _akar.find_child("Objek", true, false) as Node2D
	for r: RouteBuilder.RumahRute in rute.rumah:
		if r.sisi != LoperAnim.Sisi.DEKAT or not r.pelanggan:
			continue
		for z: ZonaSasaran.Zona in ZonaSasaran.zona_rumah(r):
			if z.jenis == ZonaSasaran.Jenis.KOTAK_SURAT:
				var kotak: Node2D = ADEGAN_KOTAK_SURAT.instantiate() as Node2D
				kotak.name = "KotakDekat_%s" % r.id.replace("@", "_")
				kotak.position = Iso.posisi_gambar(Vector2(z.persegi.get_center().x, -z.persegi.get_center().y))
				objek.add_child(kotak)
	_akar.koran = SisaKoran.awal(30)
	_taruh(3.0, LATERAL_JALUR, 0.0)


## Pecahan piksel sasaran sisi dekat yang tertimpa tembok untuk 4 varian x 3 jenis atap (kavling foto dan satu kavling lain), dari `UkurTembok`.
func _cetak_ukur() -> void:
	var terburuk_badan: float = 0.0
	var teras: Array[String] = []
	var kotak: Array[String] = []
	for varian: String in VARIAN:
		var maks_kotak: float = 0.0
		var maks_teras: float = 0.0
		for jenis: String in ["dekat_limasan", "dekat_pelana_lintang", "dekat_pelana_sejajar"]:
			for maju: float in [8.0, 20.0, 20.5]:
				var h: Dictionary = UkurTembok.ukur(maju, jenis, varian)
				terburuk_badan = maxf(terburuk_badan, float(h["kotak_badan"]))
				maks_kotak = maxf(maks_kotak, float(h["zona_kotak"]))
				maks_teras = maxf(maks_teras, float(h["zona_teras"]))
		kotak.append("%s %.1f%%" % [varian, maks_kotak * 100.0])
		teras.append("%s %.1f%%" % [varian, maks_teras * 100.0])
	print("ukur AC-8 (terburuk dari 3 jenis atap x 3 kavling): badan kotak surat %.1f%%; zona kotak surat %s; zona teras %s" % [terburuk_badan * 100.0, ", ".join(kotak), ", ".join(teras)])
	_cek(terburuk_badan == 0.0, "badan kotak surat sasaran dekat tidak tertimpa tembok (AC-8)")


## Memeriksa tembok rumah `rumah` di scene: empat sprite (tiga modul varian `varian` dan tiang), tekstur benar, alfa 1,0, dan tidak ada sprite tembok untuk rumah seberang.
func _periksa_tembok(rumah: RouteBuilder.RumahRute, varian: String) -> void:
	var indeks: int = _akar.rute().rumah.find(rumah)
	var tembok: Array[Sprite2D] = _akar.daur().sprite_tembok(indeks)
	var nama: Array[String] = []
	for s: Sprite2D in tembok:
		nama.append(s.texture.resource_path.get_file().get_basename() if s.texture != null else "null")
	print("tembok %s (%s): %s, alfa rumah %.2f" % [rumah.id, varian, nama, _akar.daur().sprite_rumah(indeks).modulate.a])
	_cek(tembok.size() == 4 and nama == (["house_tembok_" + varian, "house_tembok_" + varian, "house_tembok_" + varian, "house_tembok_tiang"] as Array[String]), "tembok %s: tiga modul %s dan satu tiang" % [rumah.id, varian])
	for s: Sprite2D in tembok:
		_cek(s.modulate.a == 1.0 and s.visible, "sprite tembok %s opak dan terlihat" % s.name)
	var dekat_di_jendela: int = 0
	for i: int in _akar.daur().indeks_tampil():
		if _akar.rute().rumah[i].sisi == LoperAnim.Sisi.DEKAT:
			dekat_di_jendela += 1
	_cek(_akar.daur().jumlah_tembok() == 4 * dekat_di_jendela, "jumlah sprite tembok = 4 x rumah dekat di jendela daur (%d, %d)" % [_akar.daur().jumlah_tembok(), dekat_di_jendela])


## Swipe ke kotak surat sisi dekat rumah `rumah`: sudut dan panjang dicari lewat `lintasan_swipe` (fungsi yang sama dengan garis bidik) sampai titik mendarat di zona kotak surat rumah itu; jari ditekan,
## digeser (garis bidik), lalu diangkat. Memotret garis bidik, koran terbang, dan penanda sesudah mendarat.
func _lempar_dekat(nama: String, rumah: RouteBuilder.RumahRute) -> void:
	var zona: ZonaSasaran.Zona = null
	for z: ZonaSasaran.Zona in ZonaSasaran.zona_rumah(rumah):
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
	await _foto(nama + "_bidik", rumah)
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
	await _foto(nama + "_terbang", rumah)
	var batas: int = 0
	while not _koran_ini(koran).mendarat and batas < 120:
		await _maju(DT, false)
		batas += 1
	var mendarat: KoranLempar.Koran = _koran_ini(koran)
	await _maju(DT)
	print("%s: mendarat %s, hasil %s, penanda %s" % [nama, mendarat.mendarat, ZonaSasaran.Hasil.keys()[mendarat.hasil], ZonaSasaran.Penanda.keys()[mendarat.penanda]])
	_cek(mendarat.mendarat and mendarat.hasil == ZonaSasaran.Hasil.KOTAK_SURAT, "koran mendarat di kotak surat sasaran sisi dekat (penilaian tidak berubah)")
	await _foto(nama + "_kena", rumah)


func _gambar_jari(awal: Vector2, akhir: Vector2) -> void:
	_hapus_titik()
	var jumlah: int = floori(awal.distance_to(akhir) / 6.0)
	for i: int in range(jumlah + 1):
		var titik: ColorRect = ColorRect.new()
		titik.color = Palette.ACCENT
		titik.size = Vector2(4, 4) if i == 0 else Vector2(2, 2)
		titik.position = awal.lerp(akhir, float(i) / float(maxi(jumlah, 1))).round()
		_lapis.add_child(titik)


func _hapus_titik() -> void:
	for anak: Node in _lapis.get_children():
		anak.queue_free()


func _koran_ini(koran: KoranLempar.Koran) -> KoranLempar.Koran:
	for k: KoranLempar.Koran in _akar.koran_terbang():
		if k.lintasan == koran.lintasan:
			return k
	return koran


func _cek(kondisi: bool, label: String) -> void:
	if not kondisi:
		print("PERINGATAN: %s" % label)
		_gagal += 1


func _taruh(v: float, lateral: float, maju: float) -> void:
	var k: BikeMotion.Keadaan = _sepeda.keadaan.salin()
	k.kecepatan_ud = v
	k.lateral_ubin = lateral
	_sepeda.keadaan = k
	_sepeda.jarak_ubin = maju
	_akar.perbarui(0.0)


func _cetak_kecualikan(nama: String, kotak: Array) -> void:
	var bagian: PackedStringArray = PackedStringArray()
	for k: Rect2 in kotak:
		bagian.append("--kecualikan %d,%d,%d,%d" % [int(k.position.x * _skala), int(k.position.y * _skala), int(k.end.x * _skala) + 1, int(k.end.y * _skala) + 1])
	print("kecualikan teks %s: %s" % [nama, " ".join(bagian)])


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
		_vfx.maju(DT)
	if gambar:
		await _tunggu(2)


func _sentuh(index: int, posisi_viewport: Vector2, tekan: bool) -> void:
	var peristiwa: InputEventScreenTouch = InputEventScreenTouch.new()
	peristiwa.index = index
	peristiwa.position = posisi_viewport * _skala
	peristiwa.pressed = tekan
	Input.parse_input_event(peristiwa)
	Input.flush_buffered_events()


func _geser(index: int, posisi_viewport: Vector2) -> void:
	var peristiwa: InputEventScreenDrag = InputEventScreenDrag.new()
	peristiwa.index = index
	peristiwa.position = posisi_viewport * _skala
	Input.parse_input_event(peristiwa)
	Input.flush_buffered_events()


func _foto(keadaan: String, rumah: RouteBuilder.RumahRute) -> void:
	await _tunggu(3)
	var indeks: int = _akar.rute().rumah.find(rumah)
	var alfa: String = ""
	if indeks >= 0 and _akar.daur().sprite_rumah(indeks) != null:
		alfa = ", alfa rumah foto %.2f, tembok %d" % [_akar.daur().sprite_rumah(indeks).modulate.a, _akar.daur().sprite_tembok(indeks).size()]
	print("%s: kecepatan %.2f u/d, lateral %.2f, jarak %.2f ubin, kidal %s, koran terbang %d, rumah tampil %d, tembok tampil %d, menutupi pemain %d%s" % [keadaan, _sepeda.kecepatan_ud, _sepeda.lateral_ubin, _sepeda.jarak_ubin, _kontrol.router.kidal(), _akar.koran_terbang().size(), _akar.daur().jumlah_rumah(), _akar.daur().jumlah_tembok(), _akar.penerap_penutup().jumlah_menutupi(), alfa])
	if _folder.is_empty():
		return
	var gambar: Image = root.get_texture().get_image()
	var berkas: String = "%s/%s_dekat_%s.png" % [_folder, _awalan, keadaan]
	var galat: int = gambar.save_png(berkas)
	print("tangkapan layar %dx%d (%s) ke %s (kode %d)" % [gambar.get_width(), gambar.get_height(), keadaan, berkas, galat])
