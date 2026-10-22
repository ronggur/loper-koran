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
## Skenario bagian B2 (dekor pinggir jalan dari data segmen, rute nyata seed dev; kotak penutup rumah dekat digeser seperti gambarnya, P-4):
## - `dekor_pohon_menutupi` dan `dekor_lampu_menutupi`: sepeda di trotoar dekat (lateral 2,0) tepat di balik pohon atau lampu sisi dekat: sprite semi-transparan (alfa 0,45).
## - `dekor_pohon_seberang`, `dekor_lampu_seberang`, `dekor_tong`: sepeda di jalur tengah di dekat pohon, lampu, dan tong sampah sisi seberang dan dekat (tidak menutupi kotak surat, alfa 1,0).
## - `dekor_jalur_utama`: sepeda di tengah jalan melewati dekor kedua sisi (tidak ada dekor yang menutupinya, alfa 1,0).
## Skenario iterasi 2 (QA-001, P-6, P-7): `lajur_<pohon|lampu|tong>_<varian>_lat<lateral>`: sepeda di lajur atau trotoar dekat (lateral 1,0 untuk pohon, 0,5 untuk lampu, 2,0 untuk tong sampah) pada maju yang menurut oracle piksel (`UkurPenutupPiksel`) paling
##   banyak tertimpa piksel opak dekor; dekor harus semi-transparan (alfa 0,45), pemain tetap terlihat.
## Keadaan tidak sesuai dicetak bila alfa dekor tidak sesuai harapan di keadaan itu.
## Skenario bagian C (ubin khusus, rute nyata; `TanahDaur` mode khusus, baris mutlak dari awal rute):
## - `ubin_garasi_parkir` dan `ubin_garasi_tanda`: sepeda di jalur tengah di depan mobil garasi seberang pertama (mobil parkir, lalu dengan lampu mundur menyala); ubin masuk (trotoar dan rumput pertama) tepat di baris mobil.
## - `ubin_simbol_sepeda`: simbol sepeda di lajur sepeda kedua trotoar (seberang dan dekat) di baris simbol terdekat di depan sepeda.
## - `ubin_rumput_luar`: rumput luar bervariasi (rumput_1/2/3) di awal rute, sebelum rumah pertama.
## - `ubin_jalur_utama`: sepeda di tengah jalan di baris simbol dan baris jalan masuk: kolom aspal tidak berubah (tidak ada ubin khusus di aspal).
## - `ubin_kidal`: garasi parkir dengan tata letak kidal.
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

	# --- Dekor pinggir jalan (bagian B2) di rute nyata, rumah dekat tidak pudar lagi di trotoar dekat ---
	await _foto_dekor_semua()

	# --- Ubin khusus (bagian C): jalan masuk garasi di bawah mobil parkir, simbol sepeda, rumput luar bervariasi, jalur utama bersih ---
	await _foto_ubin()

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

	# --- Ubin khusus, sepasang kidal (rute nyata lagi) ---
	await _foto_ubin_kidal()

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


## Rute buatan spike (pelanggan sisi dekat) menggantikan rute nyata di scene yang sama: medan dan daur rumah ikut diganti; kotak surat sasaran dekat
## digambar probe di pusat zona (rumah dekat nyata memang tanpa kotak surat).
func _pasang_rute_buatan() -> void:
	var rute: RouteBuilder.Rute = SpikeSisiDekat.susun_rute()
	_akar.set("_rute", rute)
	_akar.set("_medan", MedanKoran.dari_rute(rute))
	_akar.daur().atur_rute(rute)
	(_akar.find_child("Tanah", true, false) as TanahDaur).atur_baris_masuk(UbinKhusus.himpunan_baris_masuk(rute.objek))
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


## Dekor pinggir jalan di rute nyata (bagian B2): pohon dan lampu menutupi pemain di trotoar dekat, dekor seberang dan tong di jalur tengah, jalur utama bersih.
func _foto_dekor_semua() -> void:
	await _tunggu(3)
	var rute: RouteBuilder.Rute = _akar.rute()
	var dekor: DekorDaur = _akar.dekor_daur()
	var pohon_dekat: int = _indeks_dekor("pohon", LoperAnim.Sisi.DEKAT, 40.0)
	var lampu_dekat: int = _indeks_dekor("lampu_jalan", LoperAnim.Sisi.DEKAT, 40.0)
	var pohon_seberang: int = _indeks_dekor("pohon", LoperAnim.Sisi.SEBERANG, 40.0)
	var lampu_seberang: int = _indeks_dekor("lampu_jalan", LoperAnim.Sisi.SEBERANG, 40.0)
	var tong: int = _indeks_dekor("tong_sampah", LoperAnim.Sisi.SEBERANG, 40.0)
	_cek(pohon_dekat >= 0 and lampu_dekat >= 0 and pohon_seberang >= 0 and lampu_seberang >= 0 and tong >= 0, "rute nyata memuat pohon dan lampu di kedua sisi dan tong sampah")
	if pohon_dekat < 0 or lampu_dekat < 0 or pohon_seberang < 0 or lampu_seberang < 0 or tong < 0:
		return
	# Menutupi: pemain di lateral 2,0, 0,3 ubin di depan dekor (garis pandang masuk tapak).
	_taruh(3.0, 2.0, rute.dekor[pohon_dekat].maju_ubin + 0.3)
	await _tunggu(3)
	await _foto_dekor("dekor_pohon_menutupi", pohon_dekat, 0.45)
	_taruh(3.0, 2.0, rute.dekor[lampu_dekat].maju_ubin + 0.3)
	await _tunggu(3)
	await _foto_dekor("dekor_lampu_menutupi", lampu_dekat, 0.45)
	# Tidak menutupi: jalur tengah, dekor seberang dan tong sampah di depan pemain.
	_taruh(3.0, 0.0, rute.dekor[pohon_seberang].maju_ubin - 3.0)
	await _tunggu(3)
	await _foto_dekor("dekor_pohon_seberang", pohon_seberang, 1.0)
	_taruh(3.0, 0.0, rute.dekor[lampu_seberang].maju_ubin - 3.0)
	await _tunggu(3)
	await _foto_dekor("dekor_lampu_seberang", lampu_seberang, 1.0)
	_taruh(3.0, 0.0, rute.dekor[tong].maju_ubin - 3.0)
	await _tunggu(3)
	await _foto_dekor("dekor_tong", tong, 1.0)
	# Jalur utama: tengah jalan melewati dekor dekat dan seberang, tidak ada yang menutupi.
	_taruh(3.0, 0.0, rute.dekor[pohon_dekat].maju_ubin - 3.0)
	await _tunggu(3)
	await _foto_dekor("dekor_jalur_utama", pohon_dekat, 1.0)
	var menutupi: int = _akar.penerap_penutup().jumlah_menutupi()
	_cek(menutupi == 0, "jalur utama: tidak ada gambar yang menutupi pemain di lateral 0,0 (%d)" % menutupi)
	# Lajur dekat (iterasi 2): pohon dan lampu sisi dekat semi-transparan di lajur bila piksel opaknya menimpa pemain (posisi dipilih oleh oracle piksel).
	var kasus_lajur: Array = [["pohon", "glodokan", 1.0], ["pohon", "ketapang", 1.0], ["pohon", "rindang", 1.0], ["lampu_jalan", "lengan", 0.5], ["tong_sampah", "logam", 2.0]]
	for kasus: Array in kasus_lajur:
		var indeks: int = -1
		for i: int in range(rute.dekor.size()):
			if rute.dekor[i].jenis == kasus[0] and rute.dekor[i].varian == kasus[1] and rute.dekor[i].sisi == LoperAnim.Sisi.DEKAT and rute.dekor[i].maju_ubin >= 20.0:
				indeks = i
				break
		_cek(indeks >= 0, "rute nyata memuat %s %s sisi dekat" % [kasus[0], kasus[1]])
		if indeks < 0:
			continue
		var sapuan: Dictionary = UkurPenutupPiksel.sapu_pemain(rute.dekor[indeks], 0.25, 1.0 / 16.0, 3.0)
		var terbaik: Vector3 = Vector3(0.0, 0.0, 0.0)
		for v: Vector3 in sapuan["posisi_tumpang"]:
			if is_equal_approx(v.x, float(kasus[2])) and v.z > terbaik.z:
				terbaik = v
		_cek(terbaik.z > 0.0, "oracle: ada posisi di lateral %s dengan piksel opak %s di atas pemain" % [kasus[2], kasus[1]])
		_taruh(3.0, float(kasus[2]), terbaik.y)
		await _tunggu(3)
		var nama_lajur: String = "lajur_%s_%s_lat%d" % [{"pohon": "pohon", "lampu_jalan": "lampu", "tong_sampah": "tong"}[kasus[0]], kasus[1], roundi(float(kasus[2]) * 100.0)]
		print("%s: oracle %d piksel opak dekor di atas pemain pada maju %.4f" % [nama_lajur, int(terbaik.z), terbaik.y])
		await _foto_dekor(nama_lajur, indeks, 0.45)
	# Rumah dekat tidak pudar di trotoar dekat (P-4): lateral 1,75 di samping rumah dekat pertama di jendela.
	for i: int in _akar.daur().indeks_tampil():
		if rute.rumah[i].sisi == LoperAnim.Sisi.DEKAT:
			_taruh(3.0, LATERAL_TROTOAR, rute.rumah[i].maju_ubin + 1.5)
			await _tunggu(3)
			var sprite: Sprite2D = _akar.daur().sprite_rumah(i)
			_cek(sprite != null and sprite.modulate.a == 1.0, "P-4: rumah dekat %s tidak pudar saat pemain di trotoar dekat" % rute.rumah[i].id)
			await _foto_dekor("dekor_rumah_dekat_trotoar", pohon_dekat, -1.0)
			break
	if dekor.jumlah_tampil() < 1:
		_cek(false, "dekor digambar di jendela daur")


## Indeks dekor pertama berjenis `jenis` di `sisi` dengan `maju_ubin` paling sedikit `dari_maju`; -1 bila tidak ada.
func _indeks_dekor(jenis: String, sisi: LoperAnim.Sisi, dari_maju: float) -> int:
	var rute: RouteBuilder.Rute = _akar.rute()
	for i: int in range(rute.dekor.size()):
		if rute.dekor[i].jenis == jenis and rute.dekor[i].sisi == sisi and rute.dekor[i].maju_ubin >= dari_maju:
			return i
	return -1


## Tangkapan keadaan dekor `indeks`: mencetak alfa spritenya dan menandai keadaan tidak sesuai bila berbeda dari `alfa_harapan` (negatif = tidak diperiksa).
func _foto_dekor(keadaan: String, indeks: int, alfa_harapan: float) -> void:
	await _tunggu(3)
	var sprite: Sprite2D = _akar.dekor_daur().sprite_dekor(indeks)
	var item: RouteBuilder.DekorItem = _akar.rute().dekor[indeks]
	var alfa: float = sprite.modulate.a if sprite != null else -1.0
	print("%s: dekor %s (%s %s) alfa %.2f, dekor tampil %d, menutupi pemain %d" % [keadaan, item.id, item.jenis, item.varian, alfa, _akar.dekor_daur().jumlah_tampil(), _akar.penerap_penutup().jumlah_menutupi()])
	if alfa_harapan >= 0.0:
		_cek(sprite != null and is_equal_approx(sprite.modulate.a, alfa_harapan), "%s: alfa dekor %.2f, harap %.2f" % [keadaan, alfa, alfa_harapan])
	_simpan(keadaan)


func _foto(keadaan: String, rumah: RouteBuilder.RumahRute) -> void:
	await _tunggu(3)
	var indeks: int = _akar.rute().rumah.find(rumah)
	var alfa: String = ""
	if indeks >= 0 and _akar.daur().sprite_rumah(indeks) != null:
		alfa = ", alfa rumah foto %.2f, tembok %d" % [_akar.daur().sprite_rumah(indeks).modulate.a, _akar.daur().sprite_tembok(indeks).size()]
	print("%s: kecepatan %.2f u/d, lateral %.2f, jarak %.2f ubin, kidal %s, koran terbang %d, rumah tampil %d, tembok tampil %d, menutupi pemain %d%s" % [keadaan, _sepeda.kecepatan_ud, _sepeda.lateral_ubin, _sepeda.jarak_ubin, _kontrol.router.kidal(), _akar.koran_terbang().size(), _akar.daur().jumlah_rumah(), _akar.daur().jumlah_tembok(), _akar.penerap_penutup().jumlah_menutupi(), alfa])
	_simpan(keadaan)


func _simpan(keadaan: String) -> void:
	if _folder.is_empty():
		return
	var gambar: Image = root.get_texture().get_image()
	var berkas: String = "%s/%s_dekat_%s.png" % [_folder, _awalan, keadaan]
	var galat: int = gambar.save_png(berkas)
	print("tangkapan layar %dx%d (%s) ke %s (kode %d)" % [gambar.get_width(), gambar.get_height(), keadaan, berkas, galat])


# --- Ubin khusus (bagian C) ---

## Sepeda 9,8 ubin di belakang titik mobil: mobil masih parkir (tanda baru menyala di 9,0). Jarak lain dari konstanta `Config.RUTE_*`/`MOBIL_*` tidak dipakai: ini hanya letak foto.
const JARAK_FOTO_PARKIR: float = 9.8
const JARAK_FOTO_TANDA: float = 5.0
const JARAK_FOTO_SIMBOL: float = 3.0
const MAJU_FOTO_RUMPUT: float = -9.0


func _tanah() -> TanahDaur:
	return _akar.find_child("Tanah", true, false) as TanahDaur


## Menyusun ulang rute nyata (seed dev dan sesudahnya) sampai ada mobil garasi seberang; kembali objek itu (null bila tidak ada di 60 seed). Rute disusun ulang = rintangan kembali ke keadaan awal.
func _siapkan_rute_dengan_mobil() -> RouteBuilder.ObjekRute:
	for i: int in range(60):
		_akar.call("_susun", Config.RUTE_SEED_DEV + i)
		for o: RouteBuilder.ObjekRute in _akar.rute().objek:
			if o.jenis == "mobil_garasi" and o.jalur == "seberang":
				return o
	return null


## Sprite ubin di wadah `wadah` yang barisnya (mutlak, dari letak sprite dan lantai jarak sepeda) = `baris`; kembali daftar pusat melintang (ubin).
func _x_ubin_di_baris(wadah: String, baris: int) -> Array[float]:
	var hasil: Array[float] = []
	var tanah: TanahDaur = _tanah()
	var blok: int = floori(_sepeda.jarak_ubin)
	for anak: Node in tanah.get_node(wadah).get_children():
		var pos: Vector2 = (anak as Sprite2D).position
		var gx: float = (pos.y / 16.0 + pos.x / 32.0) / 2.0
		var gy: float = (pos.y / 16.0 - pos.x / 32.0) / 2.0
		if roundi(-gy) + blok == baris:
			hasil.append(gx)
	return hasil


func _foto_ubin() -> void:
	var tanah: TanahDaur = _tanah()
	_cek(tanah != null and tanah.mode_khusus(), "tanah rute memakai ubin khusus")
	var mobil: RouteBuilder.ObjekRute = _siapkan_rute_dengan_mobil()
	_cek(mobil != null, "rute nyata (seed dev dan sesudahnya) memuat mobil garasi seberang")
	if mobil == null or tanah == null:
		return
	var baris: int = UbinKhusus.baris_masuk(mobil.maju_ubin)
	print("ubin: mobil garasi seberang %s di maju %.1f, baris masuk %d, baris masuk rute %s" % [mobil.id_segmen, mobil.maju_ubin, baris, UbinKhusus.himpunan_baris_masuk(_akar.rute().objek).keys()])
	# Mobil parkir di atas ubin masuk.
	_taruh(3.0, 0.0, mobil.maju_ubin - JARAK_FOTO_PARKIR)
	await _maju(0.25)
	_periksa_masuk(baris, mobil)
	await _foto("ubin_garasi_parkir", null)
	# Lampu mundur menyala (mobil masih di tempat parkir) lebih dekat.
	_taruh(3.0, 0.0, mobil.maju_ubin - JARAK_FOTO_TANDA)
	await _maju(0.25)
	_periksa_masuk(baris, mobil)
	await _foto("ubin_garasi_tanda", null)
	# Simbol sepeda di dua lajur: baris simbol terdekat di depan sepeda yang bukan baris masuk, di rute yang sama sesudah disusun ulang.
	_akar.call("_susun", _akar.benih())
	var baris_simbol: int = 18
	while not UbinKhusus.simbol_di_baris(baris_simbol) or UbinKhusus.himpunan_baris_masuk(_akar.rute().objek).has(baris_simbol):
		baris_simbol += 1
	_taruh(3.0, 0.0, float(baris_simbol) - JARAK_FOTO_SIMBOL)
	await _maju(0.25)
	var x_seberang: Array[float] = _x_ubin_di_baris("SimbolTrotoarSeberang", baris_simbol)
	var x_dekat: Array[float] = _x_ubin_di_baris("SimbolTrotoarDekat", baris_simbol)
	print("ubin_simbol_sepeda: baris %d, simbol seberang di x %s, simbol dekat di x %s" % [baris_simbol, x_seberang, x_dekat])
	_cek(x_seberang == ([-1.5] as Array[float]) and x_dekat == ([1.5] as Array[float]), "simbol sepeda di baris %d di kedua kolom trotoar (-1,5 dan 1,5)" % baris_simbol)
	await _foto("ubin_simbol_sepeda", null)
	# Jalur utama bersih: sepeda di tengah jalan di baris simbol; kolom aspal tidak pernah berganti tekstur.
	var aspal_asing: int = 0
	var aspal_total: int = 0
	var nama_aspal: Dictionary = {"AspalSeberang": "tile_perumahan_aspal_seberang.png", "AspalDekat": "tile_perumahan_aspal_dekat.png"}
	for wadah: String in nama_aspal:
		for anak: Node in tanah.get_node(wadah).get_children():
			aspal_total += 1
			if (anak as Sprite2D).texture.resource_path.get_file() != nama_aspal[wadah]:
				aspal_asing += 1
	print("ubin_jalur_utama: %d ubin aspal, %d bukan tekstur kolom aspal" % [aspal_total, aspal_asing])
	_cek(aspal_total > 30 and aspal_asing == 0, "kolom aspal tidak pernah berganti tekstur (jalur utama bersih dari ubin khusus)")
	await _foto("ubin_jalur_utama", null)
	# Rumput luar bervariasi di awal rute (sebelum rumah pertama): rumput_1, rumput_2, dan rumput_3 muncul.
	_taruh(3.0, 0.0, MAJU_FOTO_RUMPUT)
	await _maju(0.25)
	_cek(tanah.get_node("RumputLuar").get_child_count() > 20 and tanah.get_node("RumputLuar2").get_child_count() > 3 and tanah.get_node("RumputLuar3").get_child_count() > 2, "rumput luar: ketiga varian punya ubin di layar (%d, %d, %d)" % [tanah.get_node("RumputLuar").get_child_count(), tanah.get_node("RumputLuar2").get_child_count(), tanah.get_node("RumputLuar3").get_child_count()])
	await _foto("ubin_rumput_luar", null)


## Memeriksa bahwa ubin masuk trotoar dan rumput pertama seberang tepat di baris `baris` (satu ubin tiap kolom), kolom lain tidak, dan mencetak jarak ke mobil.
func _periksa_masuk(baris: int, mobil: RouteBuilder.ObjekRute) -> void:
	var trotoar: Array[float] = _x_ubin_di_baris("MasukTrotoarSeberang", baris)
	var rumput: Array[float] = _x_ubin_di_baris("MasukRumputSeberang", baris)
	print("ubin masuk di baris %d: trotoar x %s, rumput x %s (mobil maju %.1f, selisih %.1f ubin)" % [baris, trotoar, rumput, mobil.maju_ubin, mobil.maju_ubin - float(baris)])
	_cek(trotoar == ([-1.5] as Array[float]) and rumput == ([-2.5] as Array[float]), "ubin masuk di baris mobil %d: trotoar seberang (-1,5) dan rumput pertama seberang (-2,5)" % baris)
	_cek(absf(mobil.maju_ubin - float(baris)) <= 0.5, "mobil di dalam baris ubin masuknya")


func _foto_ubin_kidal() -> void:
	var mobil: RouteBuilder.ObjekRute = _siapkan_rute_dengan_mobil()
	if mobil == null:
		return
	_akar.atur_kidal(true)
	await _tunggu(3)
	_taruh(3.0, 0.0, mobil.maju_ubin - JARAK_FOTO_PARKIR)
	await _maju(0.25)
	_periksa_masuk(UbinKhusus.baris_masuk(mobil.maju_ubin), mobil)
	await _foto("ubin_kidal", null)
	_akar.atur_kidal(false)
