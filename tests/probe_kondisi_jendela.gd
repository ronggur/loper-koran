extends SceneTree
## Probe kondisi sepeda di jendela asli, non-headless (AC-30 run fase6a1-bengkel-kondisi bagian B): memuat `scenes/rute/rute.tscn` dengan sepeda dari `atur_sepeda`, memajukan simulasi
## dengan langkah tetap `perbarui(1/60)`, lalu memotret: HUD kondisi baru, AUS, PERLU_BENGKEL (satu kotak dan kosong dengan tanda "!"), campuran, peringatan (ikon bergetar, kotak WARN, dua fase
## getar), kotak berkurang sesudah tabrakan nyata, kidal, inset aman, dan layar hasil dengan baris kondisi (dari rute dan kasus terpadat: tiga baris + rekap misi + tenggat lewat).
## Mencetak data tiap keadaan dan jumlah keadaan yang tidak sesuai (kotak/tanda tidak sama dengan harapan, panel kondisi menumpuk elemen HUD lain, di luar layar, teks hasil terpotong).
## Tidak interaktif: keluar lewat `ProbeKeluar`.
##
## Pakai (jendela harus muat di layar monitor):
##   godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_kondisi_jendela.gd -- docs/loop/<RUN_ID>/shots/iter<N>
##   (juga 1920x1080, 2400x1080, 1600x720)
## Berkas: `<lebar>x<tinggi>_kondisi_<keadaan>.png`.

const BERKAS_RUTE: String = "res://scenes/rute/rute.tscn"
const BERKAS_HASIL: String = "res://scenes/ui/layar_hasil.tscn"
const FRAME_TUNGGU_LAYOUT: int = 5
const DT: float = 1.0 / 60.0

var _folder: String = ""
var _awalan: String = ""
var _akar: RuteMain
var _sepeda: SepedaUji
var _hud: HudRute
var _sprite: LoperSprite
var _debu: PancaranPiksel
var _garis: PancaranPiksel
var _toko: PemuatToko.Kumpulan = PemuatToko.muat()
var _gagal: int = 0


func _initialize() -> void:
	var argumen: PackedStringArray = OS.get_cmdline_user_args()
	_folder = argumen[0] if argumen.size() > 0 else ""
	await _tingkat()
	await _peringatan()
	await _tabrakan()
	await _hasil_dari_rute()
	await _hasil_terpadat()
	await _kidal_dan_inset()
	print("probe selesai, %d keadaan tidak sesuai" % _gagal)
	await ProbeKeluar.keluar(self, 0 if _gagal == 0 else 1)


# --- Skenario ---

func _state(ban: float, rem: float, rantai: float, level: Array = [0, 0, 0]) -> Dictionary:
	var s: Dictionary = DataSave.templat()
	var sepeda: Dictionary = s["sepeda"]
	var daftar: Array = [ban, rem, rantai]
	for i: int in range(3):
		var entri: Dictionary = sepeda[Config.KONDISI_KOMPONEN[i]]
		entri["kondisi"] = daftar[i]
		entri["level"] = level[i]
	return s


## Tiga tingkat di HUD: baru (BAIK), AUS, PERLU_BENGKEL (satu kotak dan kosong, dengan "!"), campuran.
func _tingkat() -> void:
	var kasus: Array = [
		["baru", _state(1.0, 1.0, 1.0), [3, 3, 3], [false, false, false]],
		["aus", _state(0.6, 0.5, 0.65), [2, 2, 2], [false, false, false]],
		["perlu_bengkel", _state(0.30, 0.20, 0.0), [1, 1, 0], [true, true, true]],
		["campuran", _state(1.0, 0.5, 0.2), [3, 2, 1], [false, false, true]],
	]
	for k: Array in kasus:
		await _pasang(k[1], 1)
		await _maju(1.4)
		await _foto(k[0])
		_cek_kotak(k[0], k[2], k[3])
		_cek_tumpang_tindih(k[0])
		_akar.queue_free()
		await _tunggu(2)


## Peringatan: ikon bergetar dan kotak WARN, difoto pada dua fase getar; rem tidak dipakai jadi tidak bergetar.
func _peringatan() -> void:
	await _pasang(_state(0.5, 0.5, 0.5), 1)
	await _maju(DT)
	await _foto("peringatan_fase1")
	var g1: int = _hud.kotak_kondisi("ban").getar_tampil()
	_harap("ban dan rantai bergetar, rem diam", g1 != 0 and _hud.kotak_kondisi("rantai").getar_tampil() != 0 and _hud.kotak_kondisi("rem").getar_tampil() == 0, "ban %d" % g1)
	_harap("kotak WARN pada ban", _hud.kotak_kondisi("ban").kotak_tampil()[0] == TampilKondisi.Kotak.PENUH_WARN, str(_hud.kotak_kondisi("ban").kotak_tampil()))
	await _maju(0.06)
	await _foto("peringatan_fase2")
	_harap("fase getar berikutnya berlawanan arah", _hud.kotak_kondisi("ban").getar_tampil() == -g1, "ban %d lalu %d" % [g1, _hud.kotak_kondisi("ban").getar_tampil()])
	await _maju(1.3)
	await _foto("peringatan_selesai")
	_harap("setelah 1,2 detik ikon diam dan kotak kembali TEXT", _hud.kotak_kondisi("ban").getar_tampil() == 0 and _hud.kotak_kondisi("ban").kotak_tampil()[0] == TampilKondisi.Kotak.PENUH, "")
	_cek_tumpang_tindih("peringatan")
	_akar.queue_free()
	await _tunggu(2)


## Tabrakan nyata dengan anjing: satu komponen berkurang 0,30 dan kotaknya berkurang segera.
func _tabrakan() -> void:
	await _pasang(_state(0.9, 0.9, 0.9), 5, false)
	var tabrak: Array[int] = [0]
	_akar.tabrakan.connect(func(_j: String) -> void: tabrak[0] += 1)
	_letakkan(30.0, -0.6)
	_set_kecepatan(3.0)
	var batas: int = 0
	while tabrak[0] == 0 and batas < 600:
		await _maju(DT, false)
		batas += 1
	await _maju(0.1)
	await _foto("tabrakan_aus")
	var rusak: String = BikeCondition.komponen_tabrakan(5, 0)
	var kotak: Array[TampilKondisi.Kotak] = _hud.kotak_kondisi(rusak).kotak_tampil()
	_harap("tabrakan: komponen %s berkurang menjadi dua kotak terisi" % rusak, tabrak[0] == 1 and kotak.count(TampilKondisi.Kotak.KOSONG) == 1, str(kotak))
	_cek_tumpang_tindih("tabrakan_aus")
	_akar.queue_free()
	await _tunggu(2)


## Layar hasil dari rute nyata dengan dua komponen PERLU_BENGKEL.
func _hasil_dari_rute() -> void:
	await _pasang(_state(1.0, 0.2, 0.3), 1)
	_akar.atur_mode_hari(true)
	await _selesaikan()
	await _foto("hasil_dua_baris")
	_harap("dua baris kondisi di layar hasil", _akar.layar_hasil().teks_kondisi() == ["Rem perlu servis", "Rantai perlu servis"], str(_akar.layar_hasil().teks_kondisi()))
	_cek_hasil("hasil_dua_baris", _akar.layar_hasil())
	_akar.queue_free()
	await _tunggu(2)


## Kasus terpadat: tiga baris kondisi + rekap misi selesai + tenggat lewat (layar hasil berdiri sendiri).
func _hasil_terpadat() -> void:
	var layar: LayarHasil = (load(BERKAS_HASIL) as PackedScene).instantiate() as LayarHasil
	root.add_child(layar)
	await _tunggu(2)
	var angka: HasilRute.Angka = HasilRute.Angka.new()
	angka.pelanggan = 25
	angka.terkirim = 3
	angka.meleset = 22
	angka.koin = 1250
	angka.koin_tip = 25
	angka.jumlah_tip = 1
	angka.skor = 14780
	angka.jumlah_tepat = 2
	angka.tenggat_lewat = true
	angka.detik_lewat = 72
	angka.misi_hasil = "selesai"
	angka.koin_misi = 75
	var misi: DataMisi = PemuatMisi.muat_folder().cari("p1_kucing")
	layar.isi(angka, misi, ["ban", "rem", "rantai"] as Array[String])
	layar.tampilkan(true)
	await _tunggu(5)
	_awalan = "%dx%d" % [root.size.x, root.size.y]
	await _simpan("hasil_terpadat")
	_cek_hasil("hasil_terpadat", layar)
	layar.queue_free()
	await _tunggu(2)


## Kidal (panel kondisi tidak dicerminkan) dan inset aman tiruan (kanan 24, atas 16).
func _kidal_dan_inset() -> void:
	await _pasang(_state(1.0, 0.5, 0.2), 1)
	_akar.atur_kidal(true)
	await _maju(0.2)
	await _foto("kidal")
	_cek_tumpang_tindih("kidal")
	_akar.atur_kidal(false)
	var inset: ZonaAman.Inset = ZonaAman.Inset.new()
	inset.awal_x = 20
	inset.akhir_x = 24
	inset.atas = 16
	inset.bawah = 18
	_hud.atur_inset(inset)
	await _maju(0.2)
	await _foto("inset_aman")
	var layar: Rect2 = Rect2(Vector2.ZERO, root.get_visible_rect().size)
	var panel: Rect2 = _hud.rect_panel_kondisi()
	_harap("inset: panel kondisi di dalam zona aman", panel.end.x <= layar.end.x - 24.0 and panel.position.y >= 16.0, str(panel))
	_cek_tumpang_tindih("inset_aman")
	_akar.queue_free()
	await _tunggu(2)


# --- Pemasangan ---

func _pasang(state: Dictionary, hari: int, tanpa_rintangan: bool = true) -> void:
	_akar = (load(BERKAS_RUTE) as PackedScene).instantiate() as RuteMain
	_akar.atur_sepeda(state, hari, _toko.upgrade)
	root.add_child(_akar)
	await _tunggu(FRAME_TUNGGU_LAYOUT)
	_akar.set_process(false)
	_awalan = "%dx%d" % [root.size.x, root.size.y]
	_sepeda = _akar.find_child("Sepeda", true, false) as SepedaUji
	_hud = _akar.hud_rute()
	(_akar.find_child("KontrolTouch", true, false) as KontrolTouch).keyboard_aktif = false
	_sprite = _akar.find_child("LoperAgen", true, false) as LoperSprite
	_sprite.set_process(false)
	_debu = _sepeda.umpan_balik().debu()
	_garis = _sepeda.umpan_balik().garis()
	_debu.set_process(false)
	_garis.set_process(false)
	if tanpa_rintangan:
		_akar.set(&"_rintangan", RintanganRute.Keadaan.new())
	_letakkan(0.0, 0.0)
	_set_kecepatan(Config.KECEPATAN_SANTAI_UD)
	_akar.atur_kondisi(KondisiRute.awal(Economy.kondisi_dari(state), Economy.level_dari(state), hari, _toko.upgrade))
	_akar.perbarui(0.0)


# --- Pemeriksaan ---

func _harap(nama: String, kondisi: bool, rincian: String) -> void:
	if not kondisi:
		print("TIDAK SESUAI: %s (%s)" % [nama, rincian])
		_gagal += 1


## Jumlah kotak terisi dan tanda "!" tiap komponen (urut ban, rem, rantai) sama dengan harapan keadaan.
func _cek_kotak(keadaan: String, terisi: Array, seru: Array) -> void:
	for i: int in range(3):
		var id: String = Config.KONDISI_KOMPONEN[i]
		var kotak: KotakKondisi = _hud.kotak_kondisi(id)
		var n: int = kotak.kotak_tampil().count(TampilKondisi.Kotak.PENUH) + kotak.kotak_tampil().count(TampilKondisi.Kotak.PENUH_WARN)
		_harap("%s: %s %d kotak terisi" % [keadaan, id, terisi[i]], n == terisi[i] and kotak.seru_tampil() == seru[i], "terisi %d, seru %s" % [n, kotak.seru_tampil()])
	print("kondisi [%s]: panel %s, kotak %s" % [keadaan, _hud.rect_panel_kondisi(), [_hud.kotak_kondisi("ban").kotak_tampil(), _hud.kotak_kondisi("rem").kotak_tampil(), _hud.kotak_kondisi("rantai").kotak_tampil()]])


## Panel kondisi di dalam layar, tidak menumpuk radar, panel progres, koin, skor, tombol jeda, tombol bel, panel bawah, dan zona stick.
func _cek_tumpang_tindih(keadaan: String) -> void:
	var layar: Rect2 = Rect2(Vector2.ZERO, root.get_visible_rect().size)
	var panel: Rect2 = _hud.rect_panel_kondisi()
	var lebar: int = roundi(layar.size.x)
	var pusat_bel: Vector2 = TouchZones.pusat_bel(lebar, _akar.kidal(), _akar.kontrol_router().geser_bel)
	var lain: Dictionary = {
		"radar_seberang": _hud.rect_radar_seberang(), "radar_dekat": _hud.rect_radar_dekat(), "panel_progres": _hud.rect_panel_progres(), "panel_koin": _hud.rect_panel_koin(),
		"panel_skor": _hud.rect_panel_skor(), "tombol_jeda": _hud.rect_tombol_jeda(), "zona_bel": Rect2(pusat_bel - Vector2(28, 28), Vector2(56, 56)),
		"panel_kecepatan": _hud.rect_panel_kecepatan(), "panel_koran": _hud.rect_panel_koran(), "zona_stick": TouchZones.rect_stick(lebar, _akar.kidal()),
	}
	var salah: int = 0
	if not layar.encloses(panel):
		print("TIDAK SESUAI [%s]: panel kondisi %s di luar layar %s" % [keadaan, panel, layar])
		salah += 1
	for nama: String in lain:
		if panel.intersects(lain[nama]):
			print("TIDAK SESUAI [%s]: panel kondisi %s menumpuk %s %s" % [keadaan, panel, nama, lain[nama]])
			salah += 1
	print("tata letak [%s]: panel kondisi %s, %d tidak sesuai" % [keadaan, panel, salah])
	_gagal += salah


func _cek_hasil(keadaan: String, hasil: LayarHasil) -> void:
	var layar: Rect2 = Rect2(Vector2.ZERO, root.get_visible_rect().size)
	var salah: int = 0
	if not layar.encloses(hasil.rect_panel()) or not layar.encloses(hasil.rect_tombol()):
		print("TIDAK SESUAI [%s]: panel hasil %s atau tombol %s di luar layar" % [keadaan, hasil.rect_panel(), hasil.rect_tombol()])
		salah += 1
	for r: Rect2 in hasil.rect_label():
		if not hasil.rect_panel().encloses(r):
			print("TIDAK SESUAI [%s]: label %s keluar dari panel %s" % [keadaan, r, hasil.rect_panel()])
			salah += 1
		if r.intersects(hasil.rect_tombol()):
			print("TIDAK SESUAI [%s]: label %s menumpuk tombol %s" % [keadaan, r, hasil.rect_tombol()])
			salah += 1
	print("hasil [%s]: panel %s, tombol %s (%s), baris kondisi %s, %d tidak sesuai" % [keadaan, hasil.rect_panel(), hasil.rect_tombol(), hasil.teks_tombol(), hasil.teks_kondisi(), salah])
	print("teks layar hasil: %s" % [" | ".join(hasil.teks_tampil())])
	_gagal += salah


# --- Gerak ---

func _selesaikan() -> void:
	_letakkan(_akar.rute().panjang_ubin - 1.0, 0.5)
	var batas: int = 0
	while not _akar.hasil_tampil() and batas < 600:
		await _maju(DT, false)
		batas += 1
	await _maju(DT)


func _set_kecepatan(kecepatan: float) -> void:
	var k: BikeMotion.Keadaan = _sepeda.keadaan.salin()
	k.kecepatan_ud = kecepatan
	_sepeda.keadaan = k


func _letakkan(maju: float, lateral: float = 0.5) -> void:
	_sepeda.jarak_ubin = maxf(maju, 0.0)
	var k: BikeMotion.Keadaan = _sepeda.keadaan.salin()
	k.lateral_ubin = lateral
	_sepeda.keadaan = k


func _tunggu(jumlah: int) -> void:
	for i: int in range(jumlah):
		await process_frame


func _maju(detik: float, gambar: bool = true) -> void:
	for i: int in range(maxi(roundi(detik / DT), 1)):
		if _akar.sedang_jeda():
			_akar.minta_lanjut()
		_akar.perbarui(DT)
		_sprite.maju(DT)
		_debu.maju(DT)
		_garis.maju(DT)
	if gambar:
		await _tunggu(2)


func _foto(keadaan: String) -> void:
	await _tunggu(3)
	print("%s: jarak %.2f, kecepatan %.2f, kondisi %s, kedip ban %.2f, kidal %s" % [keadaan, _sepeda.jarak_ubin, _sepeda.kecepatan_ud, _akar.kondisi().kondisi, float(_akar.kondisi().kedip["ban"]), _akar.kidal()])
	await _simpan(keadaan)


func _simpan(keadaan: String) -> void:
	if _folder.is_empty():
		return
	var gambar: Image = root.get_texture().get_image()
	var berkas: String = "%s/%s_kondisi_%s.png" % [_folder, _awalan, keadaan]
	var galat: int = gambar.save_png(berkas)
	print("tangkapan layar %dx%d (%s) ke %s (kode %d)" % [gambar.get_width(), gambar.get_height(), keadaan, berkas, galat])
