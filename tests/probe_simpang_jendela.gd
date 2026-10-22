extends SceneTree
## Probe simpang T hiasan dan ujung kerb jalan masuk di jendela asli, non-headless (AC-21 dan AC-12 run 20261022-fase5c-animasi-simpang): memuat `scenes/rute/rute.tscn`, memajukan
## simulasi dengan langkah tetap `perbarui(1/60)` (bukan waktu dinding), lalu menyimpan tangkapan layar.
##
## Skenario (rute nyata seed dev untuk simpang `dekat`; seed pertama yang memakai `per_buka_02` untuk simpang `seberang`, putusan P-6):
## - `dekat_<id segmen>`: sepeda di jalur tengah 3 ubin sebelum mulut tiap simpang: mulut, sudut, lengan ke luar; tembok rumah dekat tetangga berhenti sebelum pita.
## - `mulut_lat<lateral>`: sepeda melintas mulut simpang per_tengah_05 di lateral -2, 0, 1, dan 2 (trotoar dekat): tanpa tabrakan, pose bukan jatuh.
## - `lengan_tepi`: sepeda di lateral -2 (layar bergeser ke kiri): lengan berulang sampai kolom terjauh blok di semua baris pita.
## - `ujung_kerb`: jalan masuk garasi mobil seberang pertama dan ujung kerb di baris depannya.
## - `kidal`: simpang per_tengah_05 dengan tata letak kidal.
## - `seberang_per_buka_02`, `seberang_mulut_lat<lateral>`, `seberang_lengan_tepi`, `seberang_kidal`: simpang seberang (per_buka_02 pos 18): mulut, sudut, lengan ke kiri atas,
##   melintas mulut di lateral -2 (trotoar seberang), -1, 0, 2, lengan sampai kolom terjauh dengan sepeda di lateral 2, kidal.
## Mencetak data tiap keadaan dan keadaan yang tidak sesuai (nol bila baik): ubin pita tidak sesuai tabel `Config.RUTE_SIMPANG_SEL_DEKAT`, lengan berhenti sebelum kolom terjauh,
## tembok atau tapak rumah dekat di pita, tabrakan atau jatuh saat melintas, ujung kerb tidak di baris maju + 1. Keluar lewat `ProbeKeluar`; tidak menulis `user://save.json`.
##
## Pakai (empat ukuran):
##   godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_simpang_jendela.gd -- docs/loop/<RUN_ID>/shots/iter<N>
##   (juga 1920x1080, 2400x1080, 1600x720). Berkas: `<lebar>x<tinggi>_simpang_<keadaan>.png`.

const BERKAS_RUTE: String = "res://scenes/rute/rute.tscn"
const FRAME_TUNGGU_LAYOUT: int = 5
const DT: float = 1.0 / 60.0
## Letak foto relatif `maju_ubin` simpang (baris `pos`), ubin; hanya letak kamera.
const MAJU_FOTO: float = -3.0
const MAJU_LINTAS: float = -2.5
const LANGKAH_LINTAS: int = 90
const LATERAL_LINTAS: Array[float] = [-2.0, 0.0, 1.0, 2.0]
const LATERAL_TEPI: float = -2.0
const JARAK_FOTO_UJUNG: float = 6.0

var _skala: float = 1.0
var _folder: String = ""
var _awalan: String = ""
var _akar: RuteMain
var _sepeda: SepedaUji
var _kontrol: KontrolTouch
var _sprite: LoperSprite
var _vfx: VfxSepedaGambar
var _gagal: int = 0


func _initialize() -> void:
	var argumen: PackedStringArray = OS.get_cmdline_user_args()
	_folder = argumen[0] if argumen.size() > 0 else ""
	if not _folder.is_empty():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + _folder) if not _folder.is_absolute_path() else _folder)
	if not await _muat():
		await ProbeKeluar.keluar(self, 1)
		return
	_skala = float(root.size.x) / root.get_visible_rect().size.x
	_awalan = "%dx%d" % [root.size.x, root.size.y]
	var rute: RouteBuilder.Rute = _akar.rute()
	print("jendela %s skala x%s; rute seed %d, %d simpang: %s" % [root.size, _skala, _akar.benih(), rute.simpang.size(), _uraian_simpang(rute)])
	_cek(not rute.simpang.is_empty(), "rute dev memuat simpang")
	var utama: RouteBuilder.SimpangItem = null
	for it: RouteBuilder.SimpangItem in RouteBuilder.simpang_di(rute):
		if it.id_segmen == "per_tengah_05":
			utama = it
		_taruh(3.0, 0.0, it.maju_ubin + MAJU_FOTO)
		await _maju(0.25)
		_periksa_pita(it)
		_periksa_tembok(it)
		await _foto("dekat_%s" % it.id_segmen)
	_cek(utama != null, "simpang per_tengah_05 ada di rute dev")
	if utama != null:
		for lat: float in LATERAL_LINTAS:
			await _lintas(utama, lat)
		_taruh(3.0, LATERAL_TEPI, utama.maju_ubin)
		await _maju(0.1)
		_periksa_pita(utama)
		await _foto("lengan_tepi")
		_akar.atur_kidal(true)
		await _tunggu(3)
		_taruh(3.0, 0.0, utama.maju_ubin + MAJU_FOTO)
		await _maju(0.25)
		_periksa_pita(utama)
		await _foto("kidal")
		_akar.atur_kidal(false)
	await _foto_seberang()
	await _foto_ujung()
	print("probe selesai, %d keadaan tidak sesuai" % _gagal)
	await ProbeKeluar.keluar(self, 0 if _gagal == 0 else 1)


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
	_kontrol = _akar.find_child("KontrolTouch", true, false) as KontrolTouch
	_sprite = _akar.find_child("LoperAgen", true, false) as LoperSprite
	_sprite.set_process(false)
	_vfx = _sepeda.umpan_balik().sprite()
	_vfx.set_process(false)
	_kontrol.keyboard_aktif = false
	return true


func _uraian_simpang(rute: RouteBuilder.Rute) -> String:
	var bagian: PackedStringArray = PackedStringArray()
	for it: RouteBuilder.SimpangItem in rute.simpang:
		bagian.append("%s maju %.0f mulut %.1f..%.1f" % [it.id, it.maju_ubin, it.mulut_awal_ubin, it.mulut_awal_ubin + it.lebar_mulut_ubin])
	return ", ".join(bagian)


func _tanah() -> TanahDaur:
	return _akar.find_child("Tanah", true, false) as TanahDaur


## Ubin pita simpang `it` (sisi mana pun) di blok sekarang: sel tabel = tekstur tabel sisi itu; lengan sampai kolom terjauh di tiap baris pita.
func _periksa_pita(it: RouteBuilder.SimpangItem) -> void:
	var tanah: TanahDaur = _tanah()
	var blok: int = floori(_sepeda.jarak_ubin)
	var dasar: int = roundi(it.maju_ubin)
	var sel_cocok: int = 0
	var sel_salah: int = 0
	var x_maks: Dictionary = {}
	var lengan_maks: Dictionary = {}
	for wadah: Node in tanah.get_children():
		for anak: Node in wadah.get_children():
			var u: Sprite2D = anak as Sprite2D
			var gx: float = (u.position.y / 16.0 + u.position.x / 32.0) / 2.0
			var gy: float = (u.position.y / 16.0 - u.position.x / 32.0) / 2.0
			var rel: int = roundi(-gy) + blok - dasar
			var arah: float = 1.0 if it.sisi == LoperAnim.Sisi.DEKAT else -1.0
			if rel < Config.RUTE_SIMPANG_PITA_BARIS[0] or rel > Config.RUTE_SIMPANG_PITA_BARIS[1] or arah * gx < 0.0:
				continue
			var nama: String = u.texture.resource_path.get_file()
			var sel: Vector2i = UbinKhusus.sel_simpang(gx, dasar + rel, UbinKhusus.himpunan_baris_simpang([it] as Array[RouteBuilder.SimpangItem]))
			if sel != UbinKhusus.TANPA_SIMPANG:
				if u.texture == tanah.tekstur_simpang(it.sisi)[sel.y]:
					sel_cocok += 1
				else:
					sel_salah += 1
			if arah * gx > 3.0:
				x_maks[rel] = maxf(float(x_maks.get(rel, 0.0)), arah * gx)
				if nama.begins_with("tile_perumahan_simpang_%s_lengan" % ("dekat" if arah > 0.0 else "seberang")):
					lengan_maks[rel] = maxf(float(lengan_maks.get(rel, 0.0)), arah * gx)
	print("pita %s (sepeda maju %.2f lateral %.2f): %d sel simpang cocok, %d salah, kolom terjauh %s, lengan terjauh %s" % [it.id, _sepeda.jarak_ubin, _sepeda.lateral_ubin, sel_cocok, sel_salah, x_maks, lengan_maks])
	_cek(sel_cocok > 20 and sel_salah == 0, "ubin pita %s = tabel sel (%d cocok, %d salah)" % [it.id, sel_cocok, sel_salah])
	_cek(x_maks == lengan_maks and not x_maks.is_empty(), "lengan %s sampai kolom terjauh di tiap baris pita" % it.id)


## Tembok (modul dan tiang) dan tapak gambar rumah dekat tidak di pita simpang `it` (data rute; sprite tembok diambil dari data yang sama oleh RumahDaurRute).
func _periksa_tembok(it: RouteBuilder.SimpangItem) -> void:
	var pita: Vector2 = SegmenRute.pita_maju(it.maju_ubin)
	var di_pita: int = 0
	var tetangga: PackedStringArray = PackedStringArray()
	for r: RouteBuilder.RumahRute in _akar.rute().rumah:
		if r.sisi != LoperAnim.Sisi.DEKAT:
			continue
		var kav: Rect2 = SegmenRute.kavling_rumah(r.sisi, r.maju_ubin)
		if absf(kav.get_center().y - (pita.x + pita.y) / 2) < 8.0:
			tetangga.append("%s %.1f..%.1f" % [r.id, kav.position.y, kav.end.y])
		for pot: TembokDekat.Potongan in TembokDekat.potongan(r):
			var akhir: float = pot.maju_ubin + (0.0 if pot.tiang else Config.RUTE_TEMBOK_MODUL_UBIN)
			if pot.maju_ubin < pita.y and akhir > pita.x:
				di_pita += 1
	print("tembok sekitar %s (pita %.1f..%.1f): rumah dekat tetangga %s; tembok di pita %d; tembok tampil %d" % [it.id, pita.x, pita.y, tetangga, di_pita, _akar.daur().jumlah_tembok()])
	_cek(di_pita == 0, "tembok terputus di pita %s" % it.id)


func _lintas(it: RouteBuilder.SimpangItem, lateral: float, awalan: String = "") -> void:
	var tabrak: Array[String] = []
	var sambung: Callable = func(j: String) -> void: tabrak.append(j)
	_akar.tabrakan.connect(sambung)
	_taruh(Config.KECEPATAN_SANTAI_UD, lateral, it.maju_ubin + MAJU_LINTAS)
	var jatuh: int = 0
	var foto: bool = false
	for i: int in range(LANGKAH_LINTAS):
		await _maju(DT, false)
		if _sepeda.sedang_jatuh():
			jatuh += 1
		if not foto and _sepeda.jarak_ubin >= it.mulut_awal_ubin + it.lebar_mulut_ubin / 2:
			foto = true
			await _tunggu(2)
			await _foto("%smulut_lat%s" % [awalan, str(lateral).replace(".", "_").replace("-", "m")])
	_akar.tabrakan.disconnect(sambung)
	print("lintas %s lateral %.1f: sampai maju %.2f, tabrakan %d, langkah jatuh %d, pose %s" % [it.id, lateral, _sepeda.jarak_ubin, tabrak.size(), jatuh, LoperAnim.Pose.keys()[_sepeda.pose()]])
	_cek(tabrak.is_empty() and jatuh == 0 and foto, "melintas mulut di lateral %.1f tanpa tabrakan atau jatuh" % lateral)


## Simpang seberang (putusan P-6): rute seed pertama yang memakai per_buka_02.
func _foto_seberang() -> void:
	var it: RouteBuilder.SimpangItem = null
	for i: int in range(60):
		_akar.call("_susun", Config.RUTE_SEED_DEV + i)
		for s: RouteBuilder.SimpangItem in RouteBuilder.simpang_di(_akar.rute()):
			if s.sisi == LoperAnim.Sisi.SEBERANG:
				it = s
		if it != null:
			break
	_cek(it != null, "ada rute dengan simpang seberang (60 seed)")
	if it == null:
		return
	print("simpang seberang: seed %d, %s" % [_akar.benih(), _uraian_simpang(_akar.rute())])
	_taruh(3.0, 0.0, it.maju_ubin + MAJU_FOTO)
	await _maju(0.25)
	_periksa_pita(it)
	_periksa_rumah_seberang(it)
	await _foto("seberang_%s" % it.id_segmen)
	for lat: float in [-2.0, -1.0, 0.0, 2.0]:
		await _lintas(it, lat, "seberang_")
	_taruh(3.0, -LATERAL_TEPI, it.maju_ubin)
	await _maju(0.1)
	_periksa_pita(it)
	await _foto("seberang_lengan_tepi")
	_akar.atur_kidal(true)
	await _tunggu(3)
	_taruh(3.0, 0.0, it.maju_ubin + MAJU_FOTO)
	await _maju(0.25)
	_periksa_pita(it)
	await _foto("seberang_kidal")
	_akar.atur_kidal(false)


## Tapak rumah seberang tidak di pita simpang seberang `it` (kavling tetangga per_buka_02@14 dan @22 berhenti di tepi pita).
func _periksa_rumah_seberang(it: RouteBuilder.SimpangItem) -> void:
	var pita: Vector2 = SegmenRute.pita_maju(it.maju_ubin)
	var di_pita: int = 0
	var tetangga: PackedStringArray = PackedStringArray()
	for r: RouteBuilder.RumahRute in _akar.rute().rumah:
		if r.sisi != LoperAnim.Sisi.SEBERANG:
			continue
		var kav: Rect2 = SegmenRute.kavling_rumah(r.sisi, r.maju_ubin)
		if absf(kav.get_center().y - (pita.x + pita.y) / 2) < 6.0:
			tetangga.append("%s %.1f..%.1f" % [r.id, kav.position.y, kav.end.y])
		if kav.position.y < pita.y and kav.end.y > pita.x:
			di_pita += 1
	print("rumah seberang sekitar %s (pita %.1f..%.1f): %s; di pita %d" % [it.id, pita.x, pita.y, tetangga, di_pita])
	_cek(di_pita == 0, "tidak ada rumah seberang di pita %s" % it.id)


func _foto_ujung() -> void:
	var mobil: RouteBuilder.ObjekRute = null
	for i: int in range(60):
		_akar.call("_susun", Config.RUTE_SEED_DEV + i)
		for o: RouteBuilder.ObjekRute in _akar.rute().objek:
			if o.jenis == "mobil_garasi" and o.jalur == "seberang" and mobil == null:
				mobil = o
		if mobil != null:
			break
	_cek(mobil != null, "ada mobil garasi seberang untuk foto ujung kerb")
	if mobil == null:
		return
	var baris: int = UbinKhusus.baris_masuk(mobil.maju_ubin)
	_taruh(3.0, 0.0, mobil.maju_ubin - JARAK_FOTO_UJUNG)
	await _maju(0.1)
	var tanah: TanahDaur = _tanah()
	var blok: int = floori(_sepeda.jarak_ubin)
	var ujung: Dictionary = {}
	for nama: String in ["UjungTrotoarSeberang", "UjungRumputSeberang"]:
		for anak: Node in tanah.get_node(nama).get_children():
			var p: Vector2 = (anak as Sprite2D).position
			var gx: float = (p.y / 16.0 + p.x / 32.0) / 2.0
			var gy: float = (p.y / 16.0 - p.x / 32.0) / 2.0
			ujung["%s@%d" % [gx, roundi(-gy) + blok]] = nama
	var harap: Dictionary = {"-1.5@%d" % (baris + 1): "UjungTrotoarSeberang", "-2.5@%d" % (baris + 1): "UjungRumputSeberang"}
	print("ujung kerb: mobil %s maju %.1f baris masuk %d, ubin ujung %s" % [mobil.id_segmen, mobil.maju_ubin, baris, ujung])
	var ada: bool = true
	for k: String in harap:
		if ujung.get(k, "") != harap[k]:
			ada = false
	_cek(ada, "ujung kerb trotoar dan rumput seberang di baris %d (maju + 1 jalan masuk)" % (baris + 1))
	await _foto("ujung_kerb")


func _cek(kondisi: bool, label: String) -> void:
	if not kondisi:
		_gagal += 1
		print("TIDAK SESUAI: %s" % label)


func _taruh(v: float, lateral: float, maju: float) -> void:
	var k: BikeMotion.Keadaan = _sepeda.keadaan.salin()
	k.kecepatan_ud = v
	k.lateral_ubin = lateral
	_sepeda.keadaan = k
	_sepeda.jarak_ubin = maju
	_akar.perbarui(0.0)


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


func _foto(keadaan: String) -> void:
	await _tunggu(3)
	print("%s: kecepatan %.2f u/d, lateral %.2f, jarak %.2f ubin, kidal %s, tembok tampil %d" % [keadaan, _sepeda.kecepatan_ud, _sepeda.lateral_ubin, _sepeda.jarak_ubin, _kontrol.router.kidal(), _akar.daur().jumlah_tembok()])
	if _folder.is_empty():
		return
	var gambar: Image = root.get_texture().get_image()
	var berkas: String = "%s/%s_simpang_%s.png" % [_folder, _awalan, keadaan]
	print("tangkapan layar %dx%d (%s) ke %s (kode %d)" % [gambar.get_width(), gambar.get_height(), keadaan, berkas, gambar.save_png(berkas)])
