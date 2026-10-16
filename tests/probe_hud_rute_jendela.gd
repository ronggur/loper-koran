extends SceneTree
## Probe HUD rute final dan layar hasil di jendela asli, non-headless (AC-20 run fase3c-hud-hasil): memuat `scenes/rute/rute.tscn` (scene
## utama), memajukan simulasi dengan langkah tetap `perbarui(1/60)` (bukan waktu dinding), lalu memotret: HUD final di awal rute, radar
## dengan pelanggan/tip/jangkau, mode bantu dengan penanda abu-abu, kotak progres campuran (terkirim, terlewat, berikutnya, belum), tenggat
## hampir habis dan LEWAT, layar hasil "ada meleset + tenggat lewat", layar hasil "semua terantar", layar jeda dengan sakelar Kidal/Bantu,
## dan kidal. Antaran dibuat dengan lemparan mode bantu sungguhan (tap di zona swipe lewat event sentuh); sepeda dipindah ke depan rumah
## sasaran (teleport jarak) supaya probe singkat. Jam tenggat untuk foto "hampir habis" dan "LEWAT" diatur lewat `RuteMain.atur_tenggat`.
## Mencetak data tiap keadaan (teks HUD, angka hasil) dan jumlah keadaan yang tidak sesuai. Tidak interaktif: keluar lewat `ProbeKeluar`.
##
## Pakai (jendela harus muat di layar monitor):
##   godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_hud_rute_jendela.gd -- docs/loop/<RUN_ID>/shots
##   (juga 1920x1080, 2400x1080, 1600x720)
## Berkas: `<lebar>x<tinggi>_hud_<keadaan>.png`.

const BERKAS_RUTE: String = "res://scenes/rute/rute.tscn"
const FRAME_TUNGGU_LAYOUT: int = 5
const DT: float = 1.0 / 60.0
## Titik ketukan seberang relatif titik pijak sepeda di layar (di atas garis jalan, zona swipe kanan), sama dengan probe rute.
const TAP_SEBERANG: Vector2 = Vector2(200, -150)
const TAP_KIDAL_SEBERANG: Vector2 = Vector2(150, 120)
## Sepeda diletakkan sekian ubin sebelum pusat kotak surat sasaran sebelum mengetuk.
const MUNDUR_SASARAN_UBIN: float = 3.0
## Pelanggan (urutan rute) yang diantar untuk foto progres campuran; nomor `PROGRES_LEWATI` sengaja dilewati (terlewat).
const PROGRES_ANTAR: Array[int] = [0, 1, 2, 4]
const PROGRES_LEWATI: int = 3
## Antaran sesudah foto progres untuk skenario "ada meleset + tenggat lewat" (sebelum tenggat lewat).
const MELESET_ANTAR_SEBELUM: Array[int] = [5, 6, 7, 9, 10, 12, 13, 15]
## Sisa detik tenggat untuk foto "hampir habis" dan detik lewat untuk foto "LEWAT".
const TENGGAT_SISA_DETIK: float = 3.5
const TENGGAT_LEWAT_DETIK: float = 11.5

var _skala: float = 1.0
var _folder: String = ""
var _awalan: String = ""
var _akar: RuteMain
var _sepeda: SepedaUji
var _hud: HudRute
var _kontrol: KontrolTouch
var _sprite: LoperSprite
var _debu: PancaranPiksel
var _garis: PancaranPiksel
var _gagal: int = 0
var _lapis: CanvasLayer


func _initialize() -> void:
	var argumen: PackedStringArray = OS.get_cmdline_user_args()
	_folder = argumen[0] if argumen.size() > 0 else ""
	var paket: PackedScene = load(BERKAS_RUTE) as PackedScene
	if paket == null:
		push_error("scene rute tidak bisa dimuat")
		await ProbeKeluar.keluar(self, 1)
		return
	_akar = paket.instantiate() as RuteMain
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
	_hud = _akar.hud_rute()
	_kontrol = _akar.find_child("KontrolTouch", true, false) as KontrolTouch
	_sprite = _akar.find_child("LoperAgen", true, false) as LoperSprite
	_sprite.set_process(false)
	_debu = _sepeda.umpan_balik().debu()
	_garis = _sepeda.umpan_balik().garis()
	_debu.set_process(false)
	_garis.set_process(false)
	_kontrol.keyboard_aktif = false
	var rute: RouteBuilder.Rute = _akar.rute()
	print("jendela %s: viewport terlihat %dx%d, skala x%s" % [root.size, int(terlihat.x), int(terlihat.y), _skala])
	print("rute: seed %d, panjang %.0f ubin, %d pelanggan, tenggat %d detik" % [_akar.benih(), rute.panjang_ubin, rute.pelanggan.size(), _akar.tenggat().tenggat_detik])

	# --- 1. HUD final awal rute ---
	await _maju(0.5)
	await _foto("awal")
	if not _hud.teks_tenggat().begins_with("WAKTU") or _hud.teks_terkirim() != "0/25 TERKIRIM":
		_gagal += 1

	# --- 2. Radar dengan pelanggan, pemberi tip, dan jangkau ---
	var maju_radar: float = _maju_radar_lengkap()
	print("radar lengkap (tip + jangkau) di maju %.1f" % maju_radar)
	if maju_radar < 0.0:
		_gagal += 1
		maju_radar = 20.0
	_letakkan(maju_radar)
	await _maju(DT)
	await _foto("radar")
	_cek_radar(false)

	# --- 3. Mode bantu: rumah bukan pelanggan abu-abu di radar ---
	_akar.atur_mode_bantu(true)
	await _maju(DT)
	await _foto("bantu_abu")
	_cek_radar(true)

	# --- 4. Kotak progres campuran ---
	for n: int in PROGRES_ANTAR:
		await _antar(n)
	_letakkan(ZonaSasaran.maju_kotak_surat(rute.pelanggan[PROGRES_LEWATI + 2]) - MUNDUR_SASARAN_UBIN)
	_akar.atur_mode_bantu(false)
	await _maju(DT)
	var status: Array[ProgresRute.Status] = ProgresRute.status(rute, _sepeda.jarak_ubin, _akar.skor().terantar, false)
	print("progres: %s, %s" % [_nama_status(status), _hud.teks_terkirim()])
	if status[PROGRES_LEWATI] != ProgresRute.Status.TERLEWAT or status[0] != ProgresRute.Status.TERKIRIM or not status.has(ProgresRute.Status.BERIKUTNYA) or not status.has(ProgresRute.Status.BELUM):
		_gagal += 1
	await _foto("progres_campuran")

	# --- 5. Tenggat hampir habis lalu LEWAT ---
	_akar.atur_mode_bantu(true)
	for n: int in MELESET_ANTAR_SEBELUM:
		await _antar(n)
	_akar.atur_mode_bantu(false)
	_atur_jam(_akar.tenggat().tenggat_detik - TENGGAT_SISA_DETIK)
	await _maju(DT)
	await _foto("tenggat_hampir")
	if not _hud.teks_tenggat().begins_with("WAKTU 0:0"):
		_gagal += 1
	_atur_jam(_akar.tenggat().tenggat_detik + TENGGAT_LEWAT_DETIK)
	await _maju(DT)
	await _foto("tenggat_lewat")
	if not _hud.teks_tenggat().begins_with("LEWAT +0:1") or _hud.warna_tenggat() != Palette.WARN:
		_gagal += 1

	# --- 6. Layar hasil: ada meleset + tenggat lewat (satu antaran pemberi tip sesudah lewat: tanpa tip) ---
	_akar.atur_mode_bantu(true)
	var tip_sesudah: int = _pemberi_tip_sesudah(MELESET_ANTAR_SEBELUM[MELESET_ANTAR_SEBELUM.size() - 1])
	var tip_sebelum: int = _akar.skor().jumlah_tip
	if tip_sesudah >= 0:
		await _antar(tip_sesudah)
	print("antaran pemberi tip sesudah tenggat lewat (pelanggan %d): jumlah tip %d -> %d" % [tip_sesudah, tip_sebelum, _akar.skor().jumlah_tip])
	if tip_sesudah < 0 or _akar.skor().jumlah_tip != tip_sebelum:
		_gagal += 1
	_akar.atur_mode_bantu(false)
	await _selesaikan()
	await _foto("hasil_meleset_lewat")
	_cek_hasil(false)

	# --- 7. Layar hasil: semua terantar sebelum tenggat (rute baru, seed + 1) ---
	_akar.main_lagi()
	_akar.atur_mode_bantu(true)
	for n: int in range(_akar.rute().pelanggan.size()):
		await _antar(n)
	_akar.atur_mode_bantu(false)
	await _selesaikan()
	await _foto("hasil_semua")
	_cek_hasil(true)

	# --- 8. Layar jeda dengan sakelar Kidal dan Bantu (Bantu nyala) ---
	_akar.main_lagi()
	await _maju(0.3)
	_akar.atur_mode_bantu(true)
	_akar.minta_jeda()
	await _tunggu(4)
	await _foto("jeda_sakelar")
	if not _akar.sedang_jeda():
		_gagal += 1
	_akar.minta_lanjut()
	_akar.atur_mode_bantu(false)

	# --- 9. Kidal: panel bawah dan bel dicerminkan, radar tidak ditukar ---
	_akar.atur_kidal(true)
	_letakkan(_maju_radar_lengkap())
	await _maju(DT)
	await _foto("kidal")
	_cek_radar(false)
	print("probe selesai, %d keadaan tidak sesuai" % _gagal)
	await ProbeKeluar.keluar(self, 0 if _gagal == 0 else 1)


## Maju sepeda pertama (kelipatan 0,5 ubin) dengan radar memuat penanda TIP dan penanda jangkau sekaligus; -1 bila tidak ada.
func _maju_radar_lengkap() -> float:
	var rute: RouteBuilder.Rute = _akar.rute()
	var maju: float = 0.0
	while maju < rute.panjang_ubin:
		var ada_tip: bool = false
		var ada_jangkau: bool = false
		for p: RadarRute.Penanda in RadarRute.penanda(rute, maju, {}, false, false):
			ada_tip = ada_tip or p.jenis == RadarRute.Jenis.TIP
			ada_jangkau = ada_jangkau or p.jangkau
		if ada_tip and ada_jangkau:
			return maju
		maju += 0.5
	return -1.0


func _cek_radar(bantu: bool) -> void:
	var daftar: Array[RadarRute.Penanda] = RadarRute.penanda(_akar.rute(), _sepeda.jarak_ubin, _akar.skor().terantar, bantu, TenggatRute.lewat(_akar.tenggat()))
	var jumlah: Dictionary = {"pelanggan": 0, "tip": 0, "bukan": 0, "jangkau": 0}
	for p: RadarRute.Penanda in daftar:
		jumlah[["pelanggan", "tip", "bukan"][p.jenis]] += 1
		if p.jangkau:
			jumlah["jangkau"] += 1
	var tampil: int = _hud.radar_seberang().penanda_tampil().size() + _hud.radar_dekat().penanda_tampil().size()
	print("radar (bantu %s): %s, digambar %d" % [bantu, jumlah, tampil])
	if tampil != daftar.size() or jumlah["tip"] == 0 or jumlah["jangkau"] == 0 or (jumlah["bukan"] > 0) != bantu:
		_gagal += 1


func _cek_hasil(semua: bool) -> void:
	var a: HasilRute.Angka = _akar.angka_hasil()
	if a == null or not _akar.hasil_tampil():
		print("PERINGATAN: layar hasil tidak terbuka")
		_gagal += 1
		return
	print("hasil: terkirim %d/%d, meleset %d, koin %d (tip %d dari %d), skor %d, tepat %d, tenggat lewat %s +%d detik" % [a.terkirim, a.pelanggan, a.meleset, a.koin, a.koin_tip, a.jumlah_tip, a.skor, a.jumlah_tepat, a.tenggat_lewat, a.detik_lewat])
	print("teks layar hasil: %s" % [" | ".join(_akar.layar_hasil().teks_tampil())])
	if semua and (a.terkirim != a.pelanggan or a.tenggat_lewat or a.jumlah_tip == 0):
		_gagal += 1
	if not semua and (a.meleset == 0 or not a.tenggat_lewat or a.jumlah_tip == 0):
		_gagal += 1


## Pelanggan pemberi tip pertama dengan nomor urut lebih dari `sesudah`; -1 bila tidak ada.
func _pemberi_tip_sesudah(sesudah: int) -> int:
	var rute: RouteBuilder.Rute = _akar.rute()
	for n: int in range(sesudah + 1, rute.pelanggan.size()):
		if RouteBuilder.pemberi_tip(rute, rute.pelanggan[n].id):
			return n
	return -1


## Antaran ke pelanggan bernomor `n` (urutan rute). Pemberi tip: swipe sungguhan ke teras (tip hanya dari teras, BALANCING 6). Lainnya:
## mode bantu (sakelar dinyalakan pemanggil): sepeda diletakkan `MUNDUR_SASARAN_UBIN` sebelum kotak suratnya, maju sampai sasaran bantu sisi
## seberang adalah rumah itu, tap, lalu menunggu koran mendarat.
func _antar(n: int) -> void:
	var rumah: RouteBuilder.RumahRute = _akar.rute().pelanggan[n]
	if RouteBuilder.pemberi_tip(_akar.rute(), rumah.id):
		await _antar_teras(rumah)
		return
	_letakkan(ZonaSasaran.maju_kotak_surat(rumah) - MUNDUR_SASARAN_UBIN)
	await _maju(Config.LEMPAR_JEDA_DETIK, false)
	var detik: float = 0.0
	var pilihan: BantuLempar.Pilihan = _akar.pilihan_bantu(LoperAnim.Sisi.SEBERANG)
	while (pilihan == null or pilihan.zona.id_rumah != rumah.id) and detik < 3.0:
		await _maju(DT, false)
		detik += DT
		pilihan = _akar.pilihan_bantu(LoperAnim.Sisi.SEBERANG)
	if pilihan == null or pilihan.zona.id_rumah != rumah.id:
		print("PERINGATAN: pelanggan %d (%s) bukan sasaran bantu" % [n, rumah.id])
		_gagal += 1
		return
	var tap: Vector2 = TAP_KIDAL_SEBERANG if _akar.kidal() else _akar.posisi_layar_sepeda() + TAP_SEBERANG
	_sentuh(1, tap, true)
	_sentuh(1, tap, false)
	var batas: int = 0
	while not _akar.skor().terantar.has(rumah.id) and batas < 180:
		await _maju(DT, false)
		batas += 1
	if not _akar.skor().terantar.has(rumah.id):
		print("PERINGATAN: pelanggan %d (%s) tidak terantar" % [n, rumah.id])
		_gagal += 1


## Swipe ke teras `rumah`: sudut dan panjang dicari dengan `lintasan_swipe` scene (fungsi garis bidik) supaya titik mendarat paling dekat
## pusat teras; jari ditekan, digeser, satu langkah (garis bidik), lalu diangkat; menunggu koran mendarat.
func _antar_teras(rumah: RouteBuilder.RumahRute) -> void:
	_letakkan(rumah.maju_ubin + Config.JALAN_UJI_SEBERANG_TERAS_UBIN[1] + Config.JALAN_UJI_SEBERANG_TERAS_UBIN[3] / 2.0 - MUNDUR_SASARAN_UBIN)
	await _maju(Config.LEMPAR_JEDA_DETIK, false)
	var teras: ZonaSasaran.Zona = null
	for z: ZonaSasaran.Zona in ZonaSasaran.zona_rumah(rumah):
		if z.jenis == ZonaSasaran.Jenis.TERAS:
			teras = z
	var pusat: Vector2 = teras.persegi.get_center()
	var lebar: float = root.get_visible_rect().size.x
	var awal: Vector2 = Vector2(roundf(lebar * 0.72), 250.0)
	if _akar.kidal():
		awal = Vector2(roundf(lebar * 0.28), 250.0)
	var akhir: Vector2 = Vector2.INF
	var terbaik: float = INF
	for derajat: int in range(40, 181, 2):
		var panjang: float = ceilf(ThrowSolver.swipe_min_px(lebar))
		while panjang <= ThrowSolver.swipe_maks_px(lebar):
			var coba: Vector2 = (awal + Vector2(cos(deg_to_rad(derajat)), -sin(deg_to_rad(derajat))) * panjang).round()
			var l: ThrowSolver.Lintasan = _akar.lintasan_swipe(awal, coba)
			if l != null:
				var z: ZonaSasaran.Zona = ZonaSasaran.zona_kena(l.titik_mendarat, ZonaSasaran.zona_rumah(rumah))
				var jarak: float = ZonaSasaran.ke_jalan(l.titik_mendarat).distance_to(pusat)
				if z != null and z.jenis == ZonaSasaran.Jenis.TERAS and jarak < terbaik:
					terbaik = jarak
					akhir = coba
			panjang += 2.0
	if akhir == Vector2.INF:
		print("PERINGATAN: tidak ada swipe ke teras %s" % rumah.id)
		_gagal += 1
		return
	_sentuh(2, awal, true)
	_geser(2, akhir)
	await _maju(DT, false)
	_sentuh(2, akhir, false)
	var batas: int = 0
	while not _akar.skor().terantar.has(rumah.id) and batas < 180:
		await _maju(DT, false)
		batas += 1
	if not _akar.skor().terantar.has(rumah.id):
		print("PERINGATAN: pemberi tip %s tidak terantar lewat teras" % rumah.id)
		_gagal += 1


func _geser(index: int, posisi_viewport: Vector2) -> void:
	var peristiwa: InputEventScreenDrag = InputEventScreenDrag.new()
	peristiwa.index = index
	peristiwa.position = posisi_viewport * _skala
	Input.parse_input_event(peristiwa)
	Input.flush_buffered_events()


## Sepeda ke garis akhir lalu menunggu layar hasil (sepeda berhenti, tidak ada koran terbang).
func _selesaikan() -> void:
	_letakkan(_akar.rute().panjang_ubin - 1.0)
	var batas: int = 0
	while not _akar.hasil_tampil() and batas < 600:
		await _maju(DT, false)
		batas += 1
	await _maju(DT)


func _atur_jam(waktu: float) -> void:
	var k: TenggatRute.Keadaan = _akar.tenggat().salin()
	k.waktu_detik = waktu
	_akar.atur_tenggat(k)


func _letakkan(maju: float) -> void:
	_sepeda.jarak_ubin = maxf(maju, 0.0)


func _nama_status(status: Array[ProgresRute.Status]) -> String:
	var huruf: PackedStringArray = PackedStringArray()
	for s: ProgresRute.Status in status:
		huruf.append([".", "v", "x", ">"][s])
	return "".join(huruf)


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


func _foto(keadaan: String) -> void:
	await _tunggu(3)
	print("%s: jarak %.2f, kecepatan %.2f, %s, %s, koin %s, skor %s, bantu %s, kidal %s, hasil %s" % [keadaan, _sepeda.jarak_ubin, _sepeda.kecepatan_ud, _hud.teks_tenggat(), _hud.teks_terkirim(), _hud.teks_koin(), _hud.teks_skor(), _akar.mode_bantu(), _akar.kidal(), _akar.hasil_tampil()])
	if _folder.is_empty():
		return
	var gambar: Image = root.get_texture().get_image()
	var berkas: String = "%s/%s_hud_%s.png" % [_folder, _awalan, keadaan]
	var galat: int = gambar.save_png(berkas)
	print("tangkapan layar %dx%d (%s) ke %s (kode %d)" % [gambar.get_width(), gambar.get_height(), keadaan, berkas, galat])
