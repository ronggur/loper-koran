class_name LayarHasil
extends CanvasLayer
## Layar hasil rute versi sketsa (DESIGN_SPEC 4 "Hasil harian" 🟡, rule `ui-scenes`; O-11, O-12, AC-12 run fase3c-hud-hasil, usulan).
##
## Layar penuh `UI_BG` dengan panel `UI_PANEL` di tengah, judul `HASIL_JUDUL` (Lilita One, `JudulLayar`), lalu angka dari `HasilRute.Angka`
## (satu sumber; layar ini tidak menghitung apa pun) urut dari yang berhasil: terkirim (n/25), tip, koin, skor, tepat; lalu meleset dan
## status tenggat dengan nada netral (`TEXT_2`, tanpa panel merah, tanpa kata "gagal", tanpa layar kalah; prinsip 2). Tombol `RUTE_MAIN_LAGI`
## (`TombolSentuh`, >= 42 px game) memancarkan `main_lagi_diminta`. Teks lewat kunci terjemahan; kolom nilai melar (autowrap) supaya teks
## Indonesia yang panjang tetap muat di 640, 780, dan 800.
## Run fase6a1-bengkel-kondisi bagian B (AC-24, M-11, usulan): bila ada komponen sepeda PERLU_BENGKEL, satu baris per komponen (sampai tiga, `KONDISI_HASIL_PERLU` "Rantai perlu servis", `WARN`) tampil di
## bawah daftar yang ada dan di atas tombol; tanpa komponen rusak tidak ada baris. Tidak menyentuh `HasilRute.Angka`, hadiah misi, atau rekap misi. Di alur hari tombolnya "Ke bengkel"
## (`BENGKEL_BUKA`, memancarkan `bengkel_diminta`; hari berakhir di bengkel, bukan di sini); "Main lagi" hanya di rute yang dijalankan sendiri dan banner galat muat.
## Run fase6a2-reputasi-pelanggan bagian B (AC-11, K-1, O-1, O-2, usulan): bila ada koran yang dilempar lalu terbuang, dua baris netral (`TEXT_2`, tanpa kata "gagal") tampil di daftar netral, terpisah dari ongkos dan tip:
## "Koran terbuang n koran (-potongan)" dan "Koin bersih" (boleh minus, tanda minus eksplisit); tanpa koran terbuang kedua baris tersembunyi. Baris "Saldo mulai lagi dari 0" tampil hanya bila saldo save benar-benar
## dijepit 0 (`isi` diberi `saldo_lama`, -1 = tidak diketahui). Baris "Koin" tetap koin kotor (`HasilRute.Angka.koin`); semua angka dari `HasilRute.Angka`.
## Run fase6a2-reputasi-pelanggan bagian C (AC-13 dan AC-14, O-8 sampai O-10, usulan): kolom kanan di panel yang sama (`PanelKanan`, lebar `HASIL_KANAN_LEBAR_PX`), di samping kolom kiri yang sudah padat, sehingga tinggi panel
## tidak bertambah: (1) reputasi saat ini dan perubahan hari itu ("12 (+2)", ikon `ui_icon_reputasi`; naik `OK`, selain itu `TEXT_2`, tanda plus atau minus eksplisit), (2) jumlah pelanggan baru, jadi tetap, berhenti
## berlangganan, dan berlangganan lagi (hanya yang bukan nol, nada netral, tanpa nama pelanggan), (3) SATU milestone paling dekat tercapai (nama dan tingkat berikutnya dengan lencana, bilah `BilahMilestone` dan angka
## "n/target": bukan warna saja), (4) tingkat yang baru tercapai hari itu ("Baru: Koin terkumpul · Perak", lencana, `OK`, paling banyak `MILESTONE_BARU_MAKS_TAMPIL`). Semua dari `ReputationManager.Hasil` dan
## `MilestoneTracker.Ringkasan` (layar ini tidak menghitung apa pun). Tanpa keduanya (rute yang dijalankan sendiri) kolom kanan tersembunyi dan layar sama dengan sebelumnya.
## Latar menangkap sentuhan GUI (`MOUSE_FILTER_STOP`); HUD dan kontrol sentuh di bawahnya dimatikan adegan (`RuteMain`) selama layar ini
## tampil, karena keduanya membaca sentuhan lewat `_input`.

## Tombol "Main lagi" ditekan (mode rute sendiri, bawaan).
signal main_lagi_diminta
## Tombol "Ke bengkel" ditekan (mode hari, `atur_mode_hari(true)`; run fase4a-koran-hari AC-17, run fase6a1-bengkel-kondisi AC-24: dulu "Hari berikutnya").
signal bengkel_diminta

## Lencana tiga tingkat (indeks 0 = perunggu), dimuat saat kompilasi (bukan di `_draw`).
const LENCANA: Array[Texture2D] = [
	preload("res://assets/sprites/ui/ui_lencana_perunggu.png"),
	preload("res://assets/sprites/ui/ui_lencana_perak.png"),
	preload("res://assets/sprites/ui/ui_lencana_emas.png"),
]

## True bila tombol layar ini "Ke bengkel" (di dalam alur hari), false bila "Main lagi" (rute dijalankan sendiri: probe, tes lama, dev).
var _mode_hari: bool = false

@onready var _latar: ColorRect = %LatarHasil
@onready var _panel: PanelContainer = %PanelHasil
@onready var _judul: Label = %JudulHasil
@onready var _isi: VBoxContainer = %IsiHasil
@onready var _daftar_berhasil: GridContainer = %DaftarBerhasil
@onready var _daftar_netral: GridContainer = %DaftarNetral
@onready var _nilai_terkirim: Label = %NilaiTerkirim
@onready var _nilai_tip: Label = %NilaiTip
@onready var _nilai_koin: Label = %NilaiKoin
@onready var _nilai_skor: Label = %NilaiSkor
@onready var _nilai_tepat: Label = %NilaiTepat
@onready var _nilai_meleset: Label = %NilaiMeleset
@onready var _nilai_terbuang: Label = %NilaiTerbuang
@onready var _nilai_bersih: Label = %NilaiBersih
@onready var _teks_saldo_nol: Label = %TeksSaldoNol
@onready var _teks_tenggat: Label = %TeksTenggat
@onready var _rekap_misi: Label = %RekapMisi
@onready var _tombol: TombolSentuh = %TombolMainLagi
@onready var _kondisi: VBoxContainer = %KondisiHasil
@onready var _kolom: VBoxContainer = %KolomHasil
@onready var _badan: HBoxContainer = %BadanHasil
@onready var _panel_kanan: PanelContainer = %PanelKanan
@onready var _kanan: VBoxContainer = %KananHasil
@onready var _ikon_reputasi: TextureRect = %IkonReputasiHasil
@onready var _label_reputasi: Label = %LabelReputasi
@onready var _nilai_reputasi: Label = %NilaiReputasi
@onready var _bagian_pelanggan: VBoxContainer = %BagianPelanggan
@onready var _judul_pelanggan: Label = %JudulPelanggan
@onready var _daftar_pelanggan: GridContainer = %DaftarPelanggan
@onready var _bagian_target: VBoxContainer = %BagianTarget
@onready var _judul_target: Label = %JudulTarget
@onready var _ikon_target: TextureRect = %IkonTarget
@onready var _nama_target: Label = %NamaTarget
@onready var _bilah_target: BilahMilestone = %BilahTarget
@onready var _angka_target: Label = %AngkaTarget
@onready var _teks_tamat: Label = %TeksTamat
@onready var _bagian_baru: VBoxContainer = %BagianBaru
## Baris tingkat baru tercapai (dibuat di `_ready`): ikon lencana dan teks.
var _baris_baru: Array[HBoxContainer] = []
var _ikon_baru: Array[TextureRect] = []
var _teks_baru: Array[Label] = []


func _ready() -> void:
	_latar.color = Palette.UI_BG
	_latar.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_theme_stylebox_override(&"panel", GayaHud.kotak(Palette.UI_PANEL, Palette.OUTLINE))
	_panel.custom_minimum_size = Vector2(Config.HASIL_PANEL_LEBAR_PX, 0)
	_isi.add_theme_constant_override(&"separation", Config.HUD_PANEL_PAD_Y_PX)
	_isi.custom_minimum_size = Vector2(Config.HASIL_PANEL_LEBAR_PX - 2 * Config.HUD_PANEL_PAD_X_PX, 0)
	_kolom.add_theme_constant_override(&"separation", Config.HUD_PANEL_PAD_Y_PX)
	_badan.add_theme_constant_override(&"separation", Config.HASIL_KOLOM_JARAK_PX)
	_terapkan_gaya_kanan()
	for daftar: GridContainer in [_daftar_berhasil, _daftar_netral]:
		daftar.add_theme_constant_override(&"v_separation", Config.HASIL_JARAK_BARIS_PX)
		daftar.add_theme_constant_override(&"h_separation", Config.HUD_PANEL_PAD_X_PX)
	_judul.add_theme_color_override(&"font_color", Palette.TEXT)
	for label: Node in _daftar_berhasil.get_children():
		(label as Label).add_theme_color_override(&"font_color", Palette.TEXT)
	for label: Node in _daftar_netral.get_children():
		(label as Label).add_theme_color_override(&"font_color", Palette.TEXT_2)
	_teks_tenggat.add_theme_color_override(&"font_color", Palette.TEXT_2)
	_teks_saldo_nol.add_theme_color_override(&"font_color", Palette.TEXT_2)
	_nilai_bersih.add_theme_color_override(&"font_color", Palette.TEXT)
	_nilai_terbuang.add_theme_color_override(&"font_color", Palette.TEXT_2)
	_rekap_misi.custom_minimum_size = Vector2(Config.HASIL_PANEL_LEBAR_PX - 2 * Config.HUD_PANEL_PAD_X_PX, 0)
	for label: Node in _kondisi.get_children():
		(label as Label).add_theme_color_override(&"font_color", Palette.WARN)
	_kondisi.add_theme_constant_override(&"separation", Config.HASIL_JARAK_BARIS_PX)
	for nilai: Label in [_nilai_terkirim, _nilai_tip, _nilai_koin, _nilai_skor, _nilai_tepat]:
		nilai.add_theme_color_override(&"font_color", Palette.ACCENT)
	_tombol.custom_minimum_size = Vector2(Config.HUD_TOMBOL_LEBAR_PX, Config.HUD_TOMBOL_TINGGI_PX)
	GayaHud.terapkan_tombol(_tombol)
	_tombol.add_theme_stylebox_override(&"normal", GayaHud.kotak(Palette.UI_PANEL_RAISED, Palette.TEXT))
	_tombol.add_theme_stylebox_override(&"hover", GayaHud.kotak(Palette.UI_PANEL_RAISED, Palette.TEXT))
	_tombol.ditekan.connect(_saat_tombol)
	tampilkan(false)


## Gaya dan simpul kolom kanan (panel terangkat `UI_PANEL_RAISED`, label `HudLabel`, ikon 14 px, baris tingkat baru tercapai).
func _terapkan_gaya_kanan() -> void:
	_panel_kanan.add_theme_stylebox_override(&"panel", GayaHud.kotak(Palette.UI_PANEL_RAISED, Palette.OUTLINE))
	_kanan.custom_minimum_size = Vector2(Config.HASIL_KANAN_LEBAR_PX, 0)
	_kanan.add_theme_constant_override(&"separation", Config.HUD_PANEL_PAD_Y_PX)
	_daftar_pelanggan.add_theme_constant_override(&"v_separation", Config.HASIL_JARAK_BARIS_PX)
	_daftar_pelanggan.add_theme_constant_override(&"h_separation", Config.HUD_PANEL_PAD_X_PX)
	_bagian_pelanggan.add_theme_constant_override(&"separation", Config.HASIL_JARAK_BARIS_PX)
	_bagian_target.add_theme_constant_override(&"separation", Config.HASIL_JARAK_BARIS_PX)
	_bagian_baru.add_theme_constant_override(&"separation", Config.HASIL_JARAK_BARIS_PX)
	for label: Label in [_label_reputasi, _judul_pelanggan, _judul_target]:
		label.add_theme_color_override(&"font_color", Palette.ACCENT)
	for node: Node in _daftar_pelanggan.get_children():
		(node as Label).add_theme_color_override(&"font_color", Palette.TEXT_2)
	_nama_target.add_theme_color_override(&"font_color", Palette.TEXT)
	_angka_target.add_theme_color_override(&"font_color", Palette.TEXT)
	_teks_tamat.add_theme_color_override(&"font_color", Palette.TEXT_2)
	_nilai_reputasi.add_theme_color_override(&"font_color", Palette.TEXT)
	_ikon_reputasi.custom_minimum_size = Vector2(Config.HASIL_IKON_PX, Config.HASIL_IKON_PX)
	_ikon_target.custom_minimum_size = Vector2(Config.HASIL_IKON_PX, Config.HASIL_IKON_PX)
	for i: int in range(Config.MILESTONE_BARU_MAKS_TAMPIL):
		var baris: HBoxContainer = HBoxContainer.new()
		baris.mouse_filter = Control.MOUSE_FILTER_IGNORE
		baris.visible = false
		var ikon: TextureRect = TextureRect.new()
		ikon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ikon.stretch_mode = TextureRect.STRETCH_KEEP
		ikon.custom_minimum_size = Vector2(Config.HASIL_IKON_PX, Config.HASIL_IKON_PX)
		ikon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ikon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		var teks: Label = Label.new()
		teks.theme_type_variation = &"HudLabel"
		teks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		teks.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		teks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		teks.mouse_filter = Control.MOUSE_FILTER_IGNORE
		teks.add_theme_color_override(&"font_color", Palette.OK)
		baris.add_child(ikon)
		baris.add_child(teks)
		_bagian_baru.add_child(baris)
		_baris_baru.append(baris)
		_ikon_baru.append(ikon)
		_teks_baru.append(teks)


## Mengganti tombol layar ini: true = "Ke bengkel" (alur hari), false = "Main lagi" (bawaan).
func atur_mode_hari(nilai: bool) -> void:
	_mode_hari = nilai
	_tombol.text = "BENGKEL_BUKA" if nilai else "RUTE_MAIN_LAGI"


## True bila tombol layar ini "Hari berikutnya".
func mode_hari() -> bool:
	return _mode_hari


func _saat_tombol() -> void:
	if _mode_hari:
		bengkel_diminta.emit()
	else:
		main_lagi_diminta.emit()


## Mengisi angka dari `angka` (`HasilRute.dari`). Tidak menghitung ulang apa pun. `misi` (data misi hari ini, null = tanpa misi) memberi teks banner untuk
## baris rekap misi (run fase4b-misi-kucing, AC-16): satu baris bila `angka.misi_hasil` selesai atau gagal, tidak ada baris tanpa misi. `perlu_bengkel` = id komponen sepeda PERLU_BENGKEL
## (`BikeCondition.perlu_bengkel`): satu baris kondisi per komponen, tanpa komponen rusak tidak ada baris (AC-24). `saldo_lama` = saldo save sebelum hari ini (-1 = tidak diketahui, mis. rute yang
## dijalankan sendiri): baris "Saldo mulai lagi dari 0" hanya bila `HasilRute.koin_dijepit` > 0. `reputasi` (`ReputationManager.Hasil` hari ini) dan `milestone` (`MilestoneTracker.Ringkasan`) mengisi kolom kanan (run 6A2 bagian C);
## null = bagian itu tidak tampil, keduanya null = kolom kanan tersembunyi.
func isi(angka: HasilRute.Angka, misi: DataMisi = null, perlu_bengkel: Array[String] = [], saldo_lama: int = -1, reputasi: ReputationManager.Hasil = null, milestone: MilestoneTracker.Ringkasan = null) -> void:
	var pemisah: String = tr("HUD_PEMISAH_RIBUAN")
	_nilai_terkirim.text = tr("HASIL_TERKIRIM_ANGKA").format({"n": angka.terkirim, "total": angka.pelanggan})
	_nilai_tip.text = tr("HASIL_TIP_ANGKA").format({"koin": HasilRute.ribuan(angka.koin_tip, pemisah), "n": angka.jumlah_tip})
	_nilai_koin.text = tr("HASIL_KOIN_ANGKA").format({"n": HasilRute.ribuan(angka.koin, pemisah)})
	_nilai_skor.text = tr("HASIL_SKOR_ANGKA").format({"n": HasilRute.ribuan(angka.skor, pemisah)})
	_nilai_tepat.text = tr("HASIL_TEPAT_ANGKA").format({"n": angka.jumlah_tepat})
	_nilai_meleset.text = tr("HASIL_MELESET_ANGKA").format({"n": angka.meleset})
	_isi_potongan(angka, saldo_lama, pemisah)
	_isi_rekap_misi(angka, misi)
	_isi_kondisi(perlu_bengkel)
	_isi_kanan(reputasi, milestone)
	if angka.tenggat_lewat:
		var md: Vector2i = TenggatRute.menit_detik(angka.detik_lewat)
		_teks_tenggat.text = tr("HASIL_TENGGAT_LEWAT").format({"m": md.x, "s": "%02d" % md.y})
	else:
		_teks_tenggat.text = tr("HASIL_TENGGAT_SEMPAT")


## Kolom kanan (AC-13): reputasi + perubahan, jumlah pelanggan (hanya yang bukan nol), milestone paling dekat, tingkat yang baru tercapai. Bagian tanpa data tersembunyi; tanpa keduanya seluruh kolom tersembunyi.
func _isi_kanan(reputasi: ReputationManager.Hasil, milestone: MilestoneTracker.Ringkasan) -> void:
	_panel_kanan.visible = reputasi != null or milestone != null
	var pemisah: String = tr("HUD_PEMISAH_RIBUAN")
	var baris_reputasi: Node = _nilai_reputasi.get_parent()
	(baris_reputasi as HBoxContainer).visible = reputasi != null
	_bagian_pelanggan.visible = false
	if reputasi != null:
		_nilai_reputasi.text = tr("HASIL_REPUTASI_ANGKA").format({"n": reputasi.reputasi_sesudah, "d": "%+d" % reputasi.perubahan})
		_nilai_reputasi.add_theme_color_override(&"font_color", Palette.OK if reputasi.perubahan > 0 else Palette.TEXT_2)
		var jenis: Array = [ReputationManager.Jenis.BARU, ReputationManager.Jenis.SETIA, ReputationManager.Jenis.BERHENTI, ReputationManager.Jenis.KEMBALI]
		var ada: bool = false
		var anak: Array[Node] = _daftar_pelanggan.get_children()
		for i: int in range(jenis.size()):
			var n: int = reputasi.jumlah(jenis[i])
			(anak[i * 2] as Label).visible = n > 0
			(anak[i * 2 + 1] as Label).visible = n > 0
			(anak[i * 2 + 1] as Label).text = tr("HASIL_PELANGGAN_ANGKA").format({"n": n})
			ada = ada or n > 0
		_bagian_pelanggan.visible = ada
	_bagian_target.visible = milestone != null
	_bagian_baru.visible = false
	if milestone == null:
		return
	var s: MilestoneTracker.Status = milestone.terdekat
	_teks_tamat.visible = s == null
	_bilah_target.get_parent().visible = s != null
	_nama_target.get_parent().visible = s != null
	if s != null:
		_ikon_target.texture = LENCANA[s.tingkat]
		_nama_target.text = tr("HASIL_TARGET_NAMA").format({"nama": tr(kunci_nama_milestone(s.id)), "tingkat": tr(kunci_tingkat(s.tingkat + 1))})
		_bilah_target.atur(s.pecahan())
		_angka_target.text = tr("HASIL_TARGET_ANGKA").format({"n": HasilRute.ribuan(s.nilai, pemisah), "target": HasilRute.ribuan(s.target, pemisah)})
	var tampil: int = mini(milestone.baru.size(), _baris_baru.size())
	_bagian_baru.visible = tampil > 0
	for i: int in range(_baris_baru.size()):
		_baris_baru[i].visible = i < tampil
		if i < tampil:
			var c: MilestoneTracker.Capaian = milestone.baru[i]
			_ikon_baru[i].texture = LENCANA[c.tingkat - 1]
			_teks_baru[i].text = tr("HASIL_TARGET_BARU").format({"nama": tr(kunci_nama_milestone(c.id)), "tingkat": tr(kunci_tingkat(c.tingkat))})


## Kunci terjemahan nama milestone `id` ("HASIL_MILESTONE_NAMA_<ID>").
static func kunci_nama_milestone(id: String) -> String:
	return "HASIL_MILESTONE_NAMA_" + id.to_upper()


## Kunci terjemahan nama tingkat 1..3 ("HASIL_MILESTONE_TINGKAT_<NAMA>").
static func kunci_tingkat(tingkat_ke: int) -> String:
	return "HASIL_MILESTONE_TINGKAT_" + MilestoneTracker.nama_tingkat(tingkat_ke).to_upper()


## Baris koran terbuang dan koin bersih (AC-11): tersembunyi bila tidak ada koran terbuang; baris saldo dijepit hanya bila saldo benar-benar dijepit 0 (O-2).
func _isi_potongan(angka: HasilRute.Angka, saldo_lama: int, pemisah: String) -> void:
	var ada: bool = angka.lempar_terbuang > 0
	for node: Node in [_nilai_terbuang, _nilai_bersih, _nilai_terbuang.get_parent().get_child(_nilai_terbuang.get_index() - 1), _nilai_bersih.get_parent().get_child(_nilai_bersih.get_index() - 1)]:
		(node as Label).visible = ada
	_nilai_terbuang.text = tr("HASIL_TERBUANG_ANGKA").format({"n": angka.lempar_terbuang, "koin": HasilRute.ribuan(angka.potongan, pemisah)})
	_nilai_bersih.text = tr("HASIL_KOIN_BERSIH_ANGKA").format({"n": HasilRute.ribuan(angka.koin_bersih, pemisah)})
	_teks_saldo_nol.visible = saldo_lama >= 0 and HasilRute.koin_dijepit(saldo_lama, angka.koin_bersih) > 0
	_teks_saldo_nol.text = tr("HASIL_SALDO_NOL")


## Baris rekap misi (AC-16): "Misi: Kucing ketemu! +75 koin" (selesai, `OK`, di bawah daftar yang berhasil) atau "Misi: Kucingnya lolos hari ini" (gagal, netral
## `TEXT_2`, di bawah daftar netral); tanpa misi (atau misi tanpa hasil) baris tersembunyi. Teks dari kunci banner misi dan `angka.koin_misi`, tanpa hitung ulang.
func _isi_rekap_misi(angka: HasilRute.Angka, misi: DataMisi) -> void:
	var selesai: bool = angka.misi_hasil == "selesai"
	var gagal: bool = angka.misi_hasil == "gagal"
	_rekap_misi.visible = (selesai or gagal) and misi != null
	if not _rekap_misi.visible:
		return
	if selesai:
		_rekap_misi.text = tr("HASIL_MISI_SELESAI").format({"teks": tr(misi.banner_selesai), "koin": HasilRute.ribuan(angka.koin_misi, tr("HUD_PEMISAH_RIBUAN"))})
		_rekap_misi.add_theme_color_override(&"font_color", Palette.OK)
		_isi.move_child(_rekap_misi, _daftar_berhasil.get_index() + 1)
	else:
		_rekap_misi.text = tr("HASIL_MISI_GAGAL").format({"teks": tr(misi.banner_gagal)})
		_rekap_misi.add_theme_color_override(&"font_color", Palette.TEXT_2)
		_isi.move_child(_rekap_misi, _daftar_netral.get_index() + 1)


## Baris kondisi sepeda: "Rantai perlu servis" per komponen PERLU_BENGKEL (sampai tiga), `WARN`; tanpa komponen rusak seluruh blok tersembunyi.
func _isi_kondisi(perlu_bengkel: Array[String]) -> void:
	var baris: Array[Node] = _kondisi.get_children()
	for i: int in range(baris.size()):
		var label: Label = baris[i] as Label
		label.visible = i < perlu_bengkel.size()
		if label.visible:
			label.text = tr("KONDISI_HASIL_PERLU").format({"komponen": tr(TampilKondisi.kunci_nama(perlu_bengkel[i]))})
	_kondisi.visible = not perlu_bengkel.is_empty()


## True bila blok baris kondisi tampil (false bila tidak ada komponen PERLU_BENGKEL: blok kosong yang terlihat tetap menambah jarak di panel).
func kondisi_tampil() -> bool:
	return _kondisi.visible


## Teks baris kondisi yang tampil, urut (kosong bila tidak ada komponen rusak).
func teks_kondisi() -> Array[String]:
	var hasil: Array[String] = []
	if not _kondisi.visible:
		return hasil
	for label: Node in _kondisi.get_children():
		if (label as Label).visible:
			hasil.append((label as Label).text)
	return hasil


## Persegi tiap baris kondisi yang tampil dalam koordinat viewport game (tes tata letak).
func rect_kondisi() -> Array[Rect2]:
	var hasil: Array[Rect2] = []
	if not _kondisi.visible:
		return hasil
	for label: Node in _kondisi.get_children():
		if (label as Label).visible:
			hasil.append((label as Label).get_global_rect())
	return hasil


## Teks baris rekap misi ("" bila tersembunyi).
func teks_rekap_misi() -> String:
	return _rekap_misi.text if _rekap_misi.visible else ""


## Persegi baris rekap misi dalam koordinat viewport game (tes tata letak).
func rect_rekap_misi() -> Rect2:
	return _rekap_misi.get_global_rect()


## Menampilkan atau menyembunyikan layar hasil.
func tampilkan(nilai: bool) -> void:
	visible = nilai


## True bila layar hasil sedang tampil.
func tampil() -> bool:
	return visible


## Teks koran terbuang, koin bersih, dan saldo dijepit yang tampil, urut ("" bila tersembunyi); untuk tes.
func teks_potongan() -> Array[String]:
	var hasil: Array[String] = []
	if _nilai_terbuang.visible:
		hasil.append(_nilai_terbuang.text)
		hasil.append(_nilai_bersih.text)
	if _teks_saldo_nol.visible:
		hasil.append(_teks_saldo_nol.text)
	return hasil


## True bila kolom kanan (reputasi, pelanggan, milestone) tampil.
func kanan_tampil() -> bool:
	return _panel_kanan.visible


## Teks reputasi "12 (+2)" ("" bila tersembunyi).
func teks_reputasi() -> String:
	return _nilai_reputasi.text if _panel_kanan.visible and (_nilai_reputasi.get_parent() as Control).visible else ""


## Baris pelanggan yang tampil, "Label: n" urut baru, jadi tetap, berhenti, kembali (kosong bila tidak ada).
func teks_pelanggan() -> Array[String]:
	var hasil: Array[String] = []
	if not _panel_kanan.visible or not _bagian_pelanggan.visible:
		return hasil
	var anak: Array[Node] = _daftar_pelanggan.get_children()
	for i: int in range(0, anak.size(), 2):
		if (anak[i] as Label).visible:
			hasil.append("%s: %s" % [tr((anak[i] as Label).text), (anak[i + 1] as Label).text])
	return hasil


## Milestone paling dekat: "Nama · Tingkat 2/10" ("" bila tersembunyi); semua emas = teks tamat.
func teks_target() -> String:
	if not _panel_kanan.visible or not _bagian_target.visible:
		return ""
	if _teks_tamat.visible:
		return tr(_teks_tamat.text)
	return "%s %s" % [_nama_target.text, _angka_target.text]


## Baris tingkat baru tercapai yang tampil, urut.
func teks_baru() -> Array[String]:
	var hasil: Array[String] = []
	if not _panel_kanan.visible or not _bagian_baru.visible:
		return hasil
	for i: int in range(_baris_baru.size()):
		if _baris_baru[i].visible:
			hasil.append(_teks_baru[i].text)
	return hasil


## Pecahan bilah milestone yang tampil (-1 bila bilah tersembunyi; untuk tes).
func pecahan_bilah() -> float:
	if _panel_kanan.visible and _bagian_target.visible and _bilah_target.get_parent().visible:
		return _bilah_target.pecahan()
	return -1


## Tekstur lencana target dan baris baru (untuk tes): indeks 0 = perunggu.
func tekstur_target() -> Texture2D:
	return _ikon_target.texture


func tekstur_baru() -> Array[Texture2D]:
	var hasil: Array[Texture2D] = []
	for i: int in range(_baris_baru.size()):
		if _baris_baru[i].visible:
			hasil.append(_ikon_baru[i].texture)
	return hasil


## Persegi panel kanan dan semua simpul kontennya yang tampil (tes tata letak): panel, label, ikon, bilah.
func rect_panel_kanan() -> Rect2:
	return _panel_kanan.get_global_rect()


func rect_isi_kanan() -> Array[Rect2]:
	var hasil: Array[Rect2] = []
	if not _panel_kanan.visible:
		return hasil
	var simpul: Array[Control] = [_label_reputasi, _nilai_reputasi, _ikon_reputasi]
	if _bagian_pelanggan.visible:
		simpul.append(_judul_pelanggan)
		for node: Node in _daftar_pelanggan.get_children():
			if (node as Label).visible:
				simpul.append(node as Label)
	if _bagian_target.visible:
		simpul.append(_judul_target)
		if _teks_tamat.visible:
			simpul.append(_teks_tamat)
		else:
			simpul.append_array([_ikon_target, _nama_target, _bilah_target, _angka_target])
	for i: int in range(_baris_baru.size()):
		if _baris_baru[i].visible:
			simpul.append_array([_ikon_baru[i], _teks_baru[i]])
	for c: Control in simpul:
		hasil.append(c.get_global_rect())
	return hasil


## Teks yang tampil (sesudah terjemahan), urut dari atas (untuk tes): judul, lalu pasangan label dan nilai (yang tersembunyi dilewati), lalu teks tenggat.
func teks_tampil() -> Array[String]:
	var hasil: Array[String] = [tr(_judul.text)]
	for daftar: GridContainer in [_daftar_berhasil, _daftar_netral]:
		for label: Node in daftar.get_children():
			if (label as Label).visible:
				hasil.append(tr((label as Label).text))
	if _teks_saldo_nol.visible:
		hasil.append(_teks_saldo_nol.text)
	hasil.append(tr(_teks_tenggat.text))
	if _rekap_misi.visible:
		hasil.append(_rekap_misi.text)
	hasil.append_array(teks_kondisi())
	if _panel_kanan.visible:
		if teks_reputasi() != "":
			hasil.append("%s %s" % [tr(_label_reputasi.text), teks_reputasi()])
		hasil.append_array(teks_pelanggan())
		if teks_target() != "":
			hasil.append(teks_target())
		hasil.append_array(teks_baru())
	return hasil


## Teks tombol "Main lagi" yang tampil (untuk tes).
func teks_tombol() -> String:
	return tr(_tombol.text)


## Tombol "Main lagi" (untuk tes: `ditekan.emit()`).
func tombol_main_lagi() -> TombolSentuh:
	return _tombol


## Persegi tombol "Main lagi" dan panel dalam koordinat viewport game.
func rect_tombol() -> Rect2:
	return _tombol.get_global_rect()


func rect_panel() -> Rect2:
	return _panel.get_global_rect()


## Persegi tiap label di panel (untuk tes tata letak: semuanya di dalam panel dan layar).
func rect_label() -> Array[Rect2]:
	var hasil: Array[Rect2] = [_judul.get_global_rect(), _teks_tenggat.get_global_rect()]
	if _teks_saldo_nol.visible:
		hasil.append(_teks_saldo_nol.get_global_rect())
	if _rekap_misi.visible:
		hasil.append(_rekap_misi.get_global_rect())
	hasil.append_array(rect_kondisi())
	for daftar: GridContainer in [_daftar_berhasil, _daftar_netral]:
		for label: Node in daftar.get_children():
			if (label as Label).visible:
				hasil.append((label as Label).get_global_rect())
	return hasil
