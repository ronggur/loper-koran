extends SceneTree
## Probe aset gelombang 1 di jendela asli, non-headless (AC-21 run fase5a-pasang-aset-gelombang1): memuat `scenes/rute/rute.tscn`, memajukan simulasi, sprite, dan efek dengan langkah tetap
## `perbarui(1/60)` (bukan waktu dinding), lalu menyimpan tangkapan layar aset yang dipasang: ubin enam kolom (awal rute, tengah rute dengan rumah, kotak surat, trotoar, dan rumput kiri-kanan),
## koran terbang rendah dan tinggi dengan bayangan, koran mendarat di kotak surat, teras, rumput (halaman), dan aspal, rumah terantar dengan koran terlipat (satu dan beberapa), ngebut dengan
## debu roda dan garis kecepatan (aspal, trotoar, dan rem), bintang kena dan koin tip, kilau kucing misi di rumput dan di trotoar, dan kidal. Lemparan memakai lintasan pencari mode bantu
## (`BantuLempar`) yang sama dengan tes; titik sasaran literal dari geometri zona rumah rute. Kilau di rumput dan trotoar: kucing digambar ulang di titik yang lateralnya diganti (-2,75 rumput,
## -1,5 trotoar) hanya untuk tangkapan. Mencetak data tiap keadaan, kotak teks HUD untuk `tools/cek_blok_piksel.py --kecualikan`, dan keadaan yang tidak sesuai harapan (nol bila baik). Tidak
## interaktif: keluar sendiri lewat `ProbeKeluar`.
##
## Pakai (jendela harus muat di layar monitor), empat ukuran:
##   godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_aset_jendela.gd -- docs/loop/<RUN_ID>/shots/iter<N>
##   godot --path . --resolution 1920x1080 --position 0,0 --script res://tests/probe_aset_jendela.gd -- docs/loop/<RUN_ID>/shots/iter<N>
##   godot --path . --resolution 2400x1080 --position 0,0 --script res://tests/probe_aset_jendela.gd -- docs/loop/<RUN_ID>/shots/iter<N>
##   godot --path . --resolution 1600x720 --position 0,0 --script res://tests/probe_aset_jendela.gd -- docs/loop/<RUN_ID>/shots/iter<N>
## Berkas: `<lebar>x<tinggi>_aset_<keadaan>.png`.

const BERKAS_RUTE: String = "res://scenes/rute/rute.tscn"
const FRAME_TUNGGU_LAYOUT: int = 5
const DT: float = 1.0 / 60.0
const TITIK_STICK: Vector2 = Vector2(100, 260)
## Maju sepeda (ubin) untuk foto tengah rute.
const MAJU_TENGAH: float = 92.0
## Jarak sepeda di belakang kavling rumah sasaran saat melempar, ubin.
const JARAK_LEMPAR_UBIN: float = 4.0
## Pecahan lama terbang untuk foto koran rendah (dekat tangan) dan tinggi (puncak).
const FOTO_RENDAH_PECAHAN: float = 0.12
const FOTO_TINGGI_PECAHAN: float = 0.45
## Lateral titik sasaran literal di rumah seberang: teras, halaman, aspal (ubin); dan maju relatif awal kavling.
const TERAS_LATERAL: float = -2.75
const TERAS_MAJU: float = 0.625
const HALAMAN_LATERAL: float = -2.4
const HALAMAN_MAJU: float = 0.5
const ASPAL_LATERAL: float = -0.5
const ASPAL_MAJU: float = 0.5
## Lateral kucing untuk tangkapan kilau: rumput polos dan trotoar seberang. Rumput polos = kolom rumput luar sisi dekat (|x| >= 3, `JalanDaur.rumput_luar`) di celah antara dua rumah dekat
## (iterasi 2, QA-004: sebelumnya -2,75 di seberang jatuh di teras rumah, bukan rumput polos).
const KUCING_RUMPUT_LATERAL: float = 3.75
const KUCING_TROTOAR_LATERAL: float = -1.5
## Lama menunggu bintang tampil sebelum foto (frame 1 dari 6), detik.
const FOTO_BINTANG_DETIK: float = 0.1

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


func _initialize() -> void:
	var argumen: PackedStringArray = OS.get_cmdline_user_args()
	_folder = argumen[0] if argumen.size() > 0 else ""
	if not _folder.is_empty():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + _folder) if not _folder.is_absolute_path() else _folder)
	var terlihat: Vector2 = Vector2.ZERO
	if not await _muat(false):
		await ProbeKeluar.keluar(self, 1)
		return
	terlihat = root.get_visible_rect().size
	_skala = float(root.size.x) / terlihat.x
	_awalan = "%dx%d" % [root.size.x, root.size.y]
	print("jendela %s: viewport terlihat %dx%d, skala x%s (driver %s, renderer %s)" % [root.size, int(terlihat.x), int(terlihat.y), _skala, DisplayServer.get_name(), RenderingServer.get_current_rendering_method()])
	var rute: RouteBuilder.Rute = _akar.rute()
	print("rute: seed %d, panjang %.0f ubin, %d rumah, %d pelanggan, galat %s" % [_akar.benih(), rute.panjang_ubin, rute.rumah.size(), rute.pelanggan.size(), _akar.galat_rute()])
	_cetak_kecualikan("HUD", [_hud.rect_tombol_jeda(), _hud.rect_panel_progres(), _hud.rect_panel_kecepatan(), _hud.rect_panel_koran()])

	# --- Ubin: awal rute dan tengah rute (rumah, kotak surat, trotoar dan rumput kiri-kanan) ---
	await _maju(0.5)
	await _foto("awal")
	_sepeda.jarak_ubin = MAJU_TENGAH
	await _maju(0.5)
	await _foto("tengah")

	# --- Koran terbang rendah dan tinggi dengan bayangan, mendarat di kotak surat ---
	var rumah_a: RouteBuilder.RumahRute = _pelanggan_seberang(0)
	var rumah_b: RouteBuilder.RumahRute = _pelanggan_seberang(1)
	var rumah_c: RouteBuilder.RumahRute = _pelanggan_seberang(2)
	var rumah_h: RouteBuilder.RumahRute = _pelanggan_seberang(3)
	var rumah_e: RouteBuilder.RumahRute = _pelanggan_seberang(4)
	var rumah_as: RouteBuilder.RumahRute = _pelanggan_seberang(5)
	var rumah_tip: RouteBuilder.RumahRute = _pemberi_tip_seberang()
	_cek(rumah_a != null and rumah_b != null and rumah_c != null and rumah_h != null and rumah_e != null and rumah_as != null and rumah_tip != null, "rute memuat enam pelanggan seberang bukan pemberi tip dan satu pemberi tip")
	var koran: KoranLempar.Koran = await _lempar_kotak(rumah_a, "terbang_rendah", FOTO_RENDAH_PECAHAN)
	await _foto("terbang_rendah")
	await _selesaikan_terbang(koran)
	await _foto("mendarat_kotak_surat")
	_cek(koran != null and _koran_ini(koran).permukaan == PermukaanKoran.Permukaan.KOTAK_SURAT, "mendarat di kotak surat: permukaan KOTAK_SURAT")
	await _maju(1.0)
	var koran2: KoranLempar.Koran = await _lempar_kotak(rumah_b, "terbang_tinggi", FOTO_TINGGI_PECAHAN)
	await _foto("terbang_tinggi")
	await _selesaikan_terbang(koran2)
	await _maju(1.0)

	# --- Mendarat di teras, rumput (halaman), dan aspal ---
	var teras: KoranLempar.Koran = await _lempar_titik(rumah_c, TERAS_LATERAL, TERAS_MAJU, "teras")
	await _selesaikan_terbang(teras)
	await _foto("mendarat_teras")
	_cek(teras != null and _koran_ini(teras).permukaan == PermukaanKoran.Permukaan.TERAS and _koran_ini(teras).hasil == ZonaSasaran.Hasil.TERAS, "mendarat di teras: permukaan TERAS")
	await _maju(1.0)
	var halaman: KoranLempar.Koran = await _lempar_titik(rumah_h, HALAMAN_LATERAL, HALAMAN_MAJU, "halaman")
	await _selesaikan_terbang(halaman)
	await _foto("mendarat_rumput")
	_cek(halaman != null and _koran_ini(halaman).permukaan == PermukaanKoran.Permukaan.RUMPUT and _koran_ini(halaman).hasil == ZonaSasaran.Hasil.HALAMAN, "mendarat di halaman: permukaan RUMPUT")
	await _maju(1.0)
	var aspal: KoranLempar.Koran = await _lempar_titik(rumah_as, ASPAL_LATERAL, ASPAL_MAJU, "aspal")
	await _selesaikan_terbang(aspal)
	await _foto("mendarat_aspal")
	_cek(aspal != null and _koran_ini(aspal).permukaan == PermukaanKoran.Permukaan.TERAS and _koran_ini(aspal).hasil == ZonaSasaran.Hasil.MELESET, "mendarat di aspal: permukaan TERAS (lantai keras), meleset")
	await _maju(1.0)

	# --- Bintang kena dan koin tip ---
	var biasa: KoranLempar.Koran = await _lempar_titik(rumah_e, TERAS_LATERAL, TERAS_MAJU, "bintang")
	_cek(biasa != null, "teras rumah pelanggan biasa")
	await _maju(FOTO_BINTANG_DETIK)
	await _foto("bintang")
	print("bintang: item %s, label %s" % [_nama_item(_akar.umpan_gambar().item_sprite()), _akar.umpan_gambar().teks_tampil()])
	await _maju(1.0)
	var tip: KoranLempar.Koran = await _lempar_titik(rumah_tip, TERAS_LATERAL, TERAS_MAJU, "bintang_tip")
	_cek(tip != null and _akar.skor().koin_tip > 0, "teras pemberi tip: tip tercatat di skor")
	await _maju(FOTO_BINTANG_DETIK)
	await _foto("bintang_tip")
	print("bintang_tip: item %s, label %s" % [_nama_item(_akar.umpan_gambar().item_sprite()), _akar.umpan_gambar().teks_tampil()])
	_cek(_nama_item(_akar.umpan_gambar().item_sprite()) == ["vfx_bintang_kena", "vfx_koin_tip"] and _akar.umpan_gambar().teks_tampil() == ["+15"], "bintang dan koin tampil, label tanpa baris tip")
	await _maju(0.35)
	await _foto("bintang_tip_koin_naik")
	await _maju(1.0)

	# --- Koran terlipat di rumah terantar ---
	_sepeda.jarak_ubin = rumah_a.maju_ubin - 1.0
	await _maju(0.5)
	print("terlipat: %d dari %d rumah di jendela" % [_akar.daur().jumlah_terlipat(), _akar.daur().jumlah_rumah()])
	_cek(_akar.daur().jumlah_terlipat() >= 2, "dua rumah atau lebih terantar menampilkan koran terlipat")
	await _foto("terlipat")
	_sepeda.jarak_ubin = rumah_tip.maju_ubin - 6.0
	await _maju(0.5)
	await _foto("terlipat_banyak")

	# --- Ngebut: debu roda dan garis kecepatan (aspal, trotoar), rem ---
	_taruh(6.0, 0.0, rumah_a.maju_ubin - 10.0)
	_sentuh(0, TITIK_STICK, true)
	_geser(0, TITIK_STICK - Vector2(0, Config.STICK_RADIUS_PX))
	await _maju(2.0)
	print("ngebut: kecepatan %.2f, efek %s" % [_sepeda.kecepatan_ud, _nama_item(_vfx.item_sprite())])
	_cek(_sepeda.kecepatan_ud >= 5.9 and _vfx.item_sprite().size() == 2, "ngebut 6,0: debu dan garis tampil")
	await _foto("ngebut_aspal")
	var jarak_ngebut: float = _sepeda.jarak_ubin
	_taruh(6.0, -1.5, jarak_ngebut)
	_geser(0, TITIK_STICK - Vector2(0, Config.STICK_RADIUS_PX))
	await _maju(0.3)
	await _foto("ngebut_trotoar")
	_geser(0, TITIK_STICK + Vector2(0, Config.STICK_RADIUS_PX))
	await _maju(0.35)
	print("rem: kecepatan %.2f, rem aktif %s, efek %s" % [_sepeda.kecepatan_ud, _sepeda.rem_aktif(), _nama_item(_vfx.item_sprite())])
	_cek(_sepeda.rem_aktif() and _vfx.item_sprite().size() >= 1, "rem: debu tampil")
	await _foto("rem")
	await _maju(3.0)
	_sentuh(0, TITIK_STICK, false)

	# --- Kidal: koran terbang dan bintang ---
	_akar.atur_kidal(true)
	await _tunggu(3)
	_cetak_kecualikan("kidal", [_hud.rect_tombol_jeda(), _hud.rect_panel_progres(), _hud.rect_panel_kecepatan(), _hud.rect_panel_koran()])
	var rumah_d: RouteBuilder.RumahRute = _pelanggan_seberang(3)
	var koran_kidal: KoranLempar.Koran = await _lempar_kotak(rumah_d, "kidal_terbang", FOTO_TINGGI_PECAHAN)
	await _foto("kidal_terbang")
	await _selesaikan_terbang(koran_kidal)
	await _maju(FOTO_BINTANG_DETIK)
	await _foto("kidal_bintang")
	_akar.atur_kidal(false)

	# --- Kilau kucing misi di rumput dan trotoar ---
	if not await _muat(true):
		await ProbeKeluar.keluar(self, 1)
		return
	var t1: RencanaMisi.Titik = _akar.rencana_misi().titik[0]
	_taruh(3.0, 0.5, maxf(t1.maju_ubin - 8.0, 0.0))
	await _maju(0.6)
	_cek(_akar.kucing().tampil() and _akar.kucing().hiasan().item_sprite().size() == 1, "kucing tampil dengan satu sprite kilau")
	for kasus: Array in [["kilau_rumput", KUCING_RUMPUT_LATERAL], ["kilau_trotoar", KUCING_TROTOAR_LATERAL]]:
		var titik: RencanaMisi.Titik = RencanaMisi.Titik.new()
		titik.jenis = t1.jenis
		titik.maju_ubin = t1.maju_ubin if kasus[0] != "kilau_rumput" else _maju_celah_dekat(t1.maju_ubin)
		_taruh(3.0, 0.5, maxf(titik.maju_ubin - 8.0, 0.0))
		titik.lateral_ubin = kasus[1]
		titik.lama_berhenti_detik = t1.lama_berhenti_detik
		_akar.perbarui(DT)
		_akar.kucing().tampilkan(titik, _sepeda.jarak_ubin, 0.0, 0.0, true, true)
		await _tunggu(3)
		print("%s: kucing lateral %.2f, kolom %s, kilau %s" % [kasus[0], kasus[1], JalanDaur.Kolom.keys()[JalanDaur.kolom_di(kasus[1])], _nama_item(_akar.kucing().hiasan().item_sprite())])
		await _foto(kasus[0])
		# Frame kilau kedua (0,4 detik kemudian) untuk melihat kedua frame.
		_akar.kucing().tampilkan(titik, _sepeda.jarak_ubin, Config.MISI_KILAU_DETIK + 0.01, 0.0, true, true)
		await _tunggu(3)
		await _foto("%s_frame2" % kasus[0])
	_cek(JalanDaur.rumput_luar(KUCING_RUMPUT_LATERAL) and JalanDaur.kolom_di(KUCING_RUMPUT_LATERAL) == JalanDaur.Kolom.RUMPUT_DEKAT, "lateral kilau_rumput ada di kolom rumput luar sisi dekat (rumput polos)")
	print("probe selesai, %d keadaan tidak sesuai" % _gagal)
	await ProbeKeluar.keluar(self, 0 if _gagal == 0 else 1)


## Maju (ubin) di tengah celah antara dua rumah sisi dekat yang paling dekat ke `acuan`, supaya kucing di rumput luar sisi dekat berdiri di rumput polos (bukan di halaman atau teras rumah).
## Celah = dari ujung kavling rumah dekat (`RUTE_RUMAH_PANJANG_UBIN`) sampai awal rumah dekat berikutnya; tengahnya. Tanpa celah >= 3 ubin: `acuan`.
func _maju_celah_dekat(acuan: float) -> float:
	var awal: Array[float] = []
	for r: RouteBuilder.RumahRute in _akar.rute().rumah:
		if r.sisi == LoperAnim.Sisi.DEKAT:
			awal.append(r.maju_ubin)
	var terbaik: float = acuan
	var jarak_terbaik: float = INF
	for i: int in range(awal.size() - 1):
		var ujung: float = awal[i] + Config.RUTE_RUMAH_PANJANG_UBIN
		if awal[i + 1] - ujung < 3.0:
			continue
		var tengah: float = (ujung + awal[i + 1]) / 2.0
		if absf(tengah - acuan) < jarak_terbaik:
			jarak_terbaik = absf(tengah - acuan)
			terbaik = tengah
	return terbaik


## Memuat scene rute (dengan atau tanpa misi P1 dari seed hari 1) ke pohon dan menyiapkan rujukan; scene lama dilepas. True bila berhasil.
func _muat(dengan_misi: bool) -> bool:
	if _akar != null:
		root.remove_child(_akar)
		_akar.free()
	var paket: PackedScene = load(BERKAS_RUTE) as PackedScene
	if paket == null:
		push_error("scene rute tidak bisa dimuat")
		return false
	_akar = paket.instantiate() as RuteMain
	if dengan_misi:
		_akar.atur_benih_awal(SeedHari.rute(1))
		_akar.atur_misi(PemuatMisi.muat_folder().cari("p1_kucing"))
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


## Rumah pelanggan sisi seberang BUKAN pemberi tip ke-`urutan` (dari awal rute) yang kavlingnya cukup jauh dari awal untuk memuat sepeda di belakangnya; null bila tidak ada.
func _pelanggan_seberang(urutan: int) -> RouteBuilder.RumahRute:
	var ke: int = 0
	for r: RouteBuilder.RumahRute in _akar.rute().pelanggan:
		if r.sisi != LoperAnim.Sisi.SEBERANG or r.maju_ubin < JARAK_LEMPAR_UBIN + 2.0 or RouteBuilder.pemberi_tip(_akar.rute(), r.id):
			continue
		if ke == urutan:
			return r
		ke += 1
	return null


## Pelanggan seberang pemberi tip yang paling awal (setelah awal rute); null bila tidak ada.
func _pemberi_tip_seberang() -> RouteBuilder.RumahRute:
	for r: RouteBuilder.RumahRute in _akar.rute().pelanggan:
		if r.sisi == LoperAnim.Sisi.SEBERANG and r.maju_ubin >= JARAK_LEMPAR_UBIN + 2.0 and RouteBuilder.pemberi_tip(_akar.rute(), r.id):
			return r
	return null


func _cek(kondisi: bool, label: String) -> void:
	if not kondisi:
		print("PERINGATAN: %s" % label)
		_gagal += 1


func _nama_item(daftar: Array[DefSprite.Item]) -> Array[String]:
	var hasil: Array[String] = []
	for i: DefSprite.Item in daftar:
		hasil.append(i.nama)
	return hasil


func _taruh(v: float, lateral: float, maju: float) -> void:
	var k: BikeMotion.Keadaan = _sepeda.keadaan.salin()
	k.kecepatan_ud = v
	k.lateral_ubin = lateral
	_sepeda.keadaan = k
	_sepeda.jarak_ubin = maju
	_akar.perbarui(0.0)


## Melempar koran ke pusat kotak surat `rumah` (lintasan pencari mode bantu) dari sepeda di belakangnya, memotret di pecahan `pecahan` lama terbang. Mengembalikan koran yang dilempar.
func _lempar_kotak(rumah: RouteBuilder.RumahRute, nama: String, pecahan: float) -> KoranLempar.Koran:
	_taruh(3.0, 0.5, ZonaSasaran.maju_kotak_surat(rumah) - JARAK_LEMPAR_UBIN + 1.0)
	_akar.koran = SisaKoran.awal(30)
	var pilihan: BantuLempar.Pilihan = _akar.pilihan_bantu(LoperAnim.Sisi.SEBERANG)
	if pilihan == null or pilihan.zona.id_rumah != rumah.id:
		print("PERINGATAN %s: tidak ada lintasan ke %s (dapat %s)" % [nama, rumah.id, pilihan.zona.id_rumah if pilihan != null else "tidak ada"])
		_gagal += 1
		return null
	_akar.call(&"_lempar", pilihan.lintasan, false)
	var hasil: KoranLempar.Koran = _akar.koran_terbang()[_akar.koran_terbang().size() - 1]
	await _maju(hasil.lintasan.jeda_lepas + hasil.lintasan.lama_terbang * pecahan)
	return _koran_ini(hasil)


## Melempar koran dari sepeda di belakang `rumah` ke titik (`lateral`, maju kavling + `maju_relatif`) dengan pencari kekuatan dan arah yang sama dengan mode bantu. Berhenti tepat sesudah mendarat.
func _lempar_titik(rumah: RouteBuilder.RumahRute, lateral: float, maju_relatif: float, nama: String) -> KoranLempar.Koran:
	_taruh(3.0, 0.5, rumah.maju_ubin - JARAK_LEMPAR_UBIN)
	_akar.koran = SisaKoran.awal(30)
	var posisi: Vector2 = _sepeda.posisi_dunia()
	var jeda: float = _sepeda.jeda_lepas(LoperAnim.Sisi.SEBERANG)
	var lepas: Vector2 = ThrowSolver.titik_lepas(posisi, _sepeda.kecepatan_ud, _sepeda.lateral_ud, jeda)
	var sasaran: Vector2 = Vector2(lateral, -(rumah.maju_ubin + maju_relatif))
	var u: float = BantuLempar.cari_kekuatan(sasaran, lepas, _sepeda.kecepatan_ud)
	if u < 0.0:
		print("PERINGATAN %s: titik %s tak terjangkau dari maju %.1f" % [nama, sasaran, posisi.y])
		_gagal += 1
		return null
	var lebar: float = float(root.get_visible_rect().size.x)
	var lintasan: ThrowSolver.Lintasan = ThrowSolver.hitung(ThrowSolver.panjang_untuk_kekuatan(u, lebar), lebar, BantuLempar.arah_ke(sasaran, lepas, _sepeda.kecepatan_ud, u), posisi, _sepeda.kecepatan_ud, _sepeda.lateral_ud, jeda)
	_akar.call(&"_lempar", lintasan, false)
	var koran: KoranLempar.Koran = _akar.koran_terbang()[_akar.koran_terbang().size() - 1]
	var batas: int = 0
	while not _koran_ini(koran).mendarat and batas < 240:
		await _maju(DT, false)
		batas += 1
	await _maju(DT, false)
	return _koran_ini(koran)


## Menunggu koran `koran` mendarat (bila belum) lalu satu langkah, supaya penanda dan koran tergeletak tampil.
func _selesaikan_terbang(koran: KoranLempar.Koran) -> void:
	if koran == null:
		return
	var batas: int = 0
	while not _koran_ini(koran).mendarat and batas < 240:
		await _maju(DT, false)
		batas += 1
	await _maju(DT)


func _koran_ini(koran: KoranLempar.Koran) -> KoranLempar.Koran:
	for k: KoranLempar.Koran in _akar.koran_terbang():
		if k.lintasan == koran.lintasan:
			return k
	return koran


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


func _foto(keadaan: String) -> void:
	await _tunggu(3)
	print("%s: kecepatan %.2f u/d, lateral %.2f, jarak %.2f ubin, kidal %s, koran terbang %d, terlipat %d, rumah tampil %d, efek sepeda %s, bintang/koin %s" % [keadaan, _sepeda.kecepatan_ud, _sepeda.lateral_ubin, _sepeda.jarak_ubin, _kontrol.router.kidal(), _akar.koran_terbang().size(), _akar.daur().jumlah_terlipat(), _akar.daur().jumlah_rumah(), _nama_item(_vfx.item_sprite()), _nama_item(_akar.umpan_gambar().item_sprite())])
	if _folder.is_empty():
		return
	var gambar: Image = root.get_texture().get_image()
	var berkas: String = "%s/%s_aset_%s.png" % [_folder, _awalan, keadaan]
	var galat: int = gambar.save_png(berkas)
	print("tangkapan layar %dx%d (%s) ke %s (kode %d)" % [gambar.get_width(), gambar.get_height(), keadaan, berkas, galat])
