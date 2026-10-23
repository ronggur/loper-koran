class_name HariMain
extends Node
## Scene hari (`scenes/hari/hari.tscn`, scene utama sejak run fase4a-koran-hari; S-1, AC-17 sampai AC-19): alur satu hari Koran -> Rute -> Hasil ->
## "Hari berikutnya" -> Koran hari berikutnya. Akar tipis: keputusan ada di `MesinHari` (urutan peristiwa, back), `HeadlineManager` (halaman),
## `SeedHari` (seed rute), dan `DataSave` lewat autoload `SaveManager` (simpan); node ini hanya menyambungkan.
## - Saat siap: memuat data misi dan headline (`PemuatMisi`, `PemuatHeadline`), membaca save dari `SaveManager` SEBELUM layar koran dibuat
##   (hari, flag, jeda, pengaturan), lalu menampilkan koran hari itu.
## - Berangkat: `RuteMain` dibuat tepat sekali per hari (peristiwa ganda ditolak `MesinHari`), seed rute = `SeedHari.rute(hari)` disuntik SEBELUM
##   rute masuk pohon (tanpa `main_lagi`), nomor hari diteruskan lewat `RuteMain.atur_hari` (run fase5d-sisi-dekat bagian B: pelanggan sisi dekat sejak hari 3, tip hari 3), mode hari (tombol layar hasil = "Hari berikutnya"), lalu kidal dan mode bantu dari save diterapkan.
##   Misi yang diambil di koran (S-7) diaktifkan di rute (`RuteMain.atur_misi`, run fase4b-misi-kucing AC-11); dilewati atau Berangkat tanpa memilih
##   = rute tanpa kucing dan tanpa HUD misi.
## - "Hari berikutnya": angka `HasilRute.Angka` yang sama dengan layar hasil + misi diambil + jeda + sakelar jeda dicatat dan DISIMPAN tepat satu
##   kali (`SaveManager.akhiri_hari`), rute dibuang, koran hari + 1 tampil. Run 4B: angka itu membawa hasil misi dan koin misi (satu sumber); flag baru
##   dari hasil misi (`MissionManager.flag_hasil`) dan flag yang lanjutannya tampil hari ini (`HeadlineManager.flag_terpakai`, dikonsumsi) ikut dicatat;
##   `tutorial.selesai` ditulis bila tutorial hari ini selesai atau dilewati. Tidak ada simpan di tempat lain (layar koran, Ambil/Lewati, Berangkat,
##   jeda, background, hasil terbuka, rute ditutup di tengah jalan): save terakhir tetap utuh dan hari yang sama diulang dari layar koran (AC-19).
## - Back Android (S-6): di layar koran keluar app (`keluar_diminta`, lalu `SceneTree.quit` kecuali `panggil_quit` dimatikan tes); di rute `AdeganJalan`
##   menjeda sendiri; di layar hasil diabaikan. App ke background di layar koran tidak melakukan apa pun.
## - Simpan gagal (QA-004): `akhiri_hari` dicoba sekali lagi; bila tetap gagal (atau ditahan karena save lama tidak aman ditimpa, QA-003) hari tetap
##   maju di memori, alur TIDAK diblokir, dan layar koran berikutnya menampilkan satu baris netral (`KORAN_SAVE_GAGAL`, atau
##   `KORAN_SAVE_TIDAK_TERBACA` bila simpan ditahan) sampai satu simpan berhasil. Kemajuan menumpuk di memori, jadi simpan berikutnya
##   yang berhasil menuliskan semuanya.
## Run fase6a1-bengkel-kondisi bagian B (M-8, K-1, K-4, AC-19 sampai AC-21, AC-26): Koran -> Rute -> Hasil -> Bengkel -> Koran hari + 1. Tombol layar hasil = "Ke bengkel" (`BUKA_BENGKEL`): bengkel
##   (`scenes/bengkel/bengkel.tscn`, `LayarBengkel`) bekerja pada state kerja di memori (saldo = `koin` save + koin hari ini, kondisi sepeda = akhir rute, level dan `servis_total` dari save) dan
##   menukar saldo lewat `Economy`. Save ditulis tepat SEKALI per hari, saat "Hari berikutnya" dari bengkel (juga lewat back Android di bengkel, `MesinHari.aksi_back`): kondisi akhir, servis,
##   dan upgrade ikut tertulis (`CatatanHari.sepeda`) dan belanja mengurangi saldo (`CatatanHari.belanja_koin`). Tidak ada simpan di layar hasil, di bengkel, atau saat app di-background di sana:
##   menutup app di layar hasil atau bengkel mengulang hari dari koran dengan save lama (juga pendapatan dan belanja hari itu), sama seperti aturan 4A.
## Rute menerima sepeda dari save (`RuteMain.atur_sepeda`): aus melanjutkan dari kondisi tersimpan dan efek memakai level upgrade tersimpan.
## Run fase6a2-reputasi-pelanggan bagian A: state save dan pustaka kepribadian dikirim ke rute (`RuteMain.atur_pelanggan`, sebelum scene masuk pohon) dan catatan pelanggan hari itu masuk `CatatanHari` saat "Hari berikutnya"
## (reputasi dan status pelanggan ditulis `DataSave.catat_hari` tepat sekali, bersama simpan akhir hari lainnya).
## Alur hari berurutan ini prototype yang tidak mengunci struktur sesi (ROADMAP 5): tanpa hari terakhir, game over, atau target harian.

## Skrip autoload `SaveManager`, hanya untuk tipe (autoload tidak diberi `class_name`, rule `gdscript`).
const SKRIP_SIMPAN := preload("res://scripts/autoload/save_manager.gd")
const ADEGAN_RUTE: PackedScene = preload("res://scenes/rute/rute.tscn")
const ADEGAN_BENGKEL: PackedScene = preload("res://scenes/bengkel/bengkel.tscn")

## Back di layar koran: aplikasi diminta keluar.
signal keluar_diminta
## Rute hari ini dibuat (sesudah Berangkat).
signal rute_dimulai(rute: RuteMain)
## Hari selesai dan disimpan: nomor hari yang baru dimainkan.
signal hari_selesai(hari: int)

## Penyimpan (autoload `SaveManager`, atau objek lain yang disuntik tes sebelum scene masuk pohon).
var simpanan: SKRIP_SIMPAN = null
## False di tes: back di layar koran hanya memancarkan `keluar_diminta`, tidak mengakhiri proses.
var panggil_quit: bool = true
## False di tes yang sengaja memicu galat data.
var lapor_ke_log: bool = true
## Berapa rute dibuat sejak scene siap (pengintai tes: Berangkat ganda tidak boleh membuat dua rute).
var jumlah_rute_dibuat: int = 0

var _mesin: MesinHari.Status = MesinHari.awal(Config.HARI_AWAL)
var _halaman: HeadlineManager.Halaman = HeadlineManager.Halaman.new()
var _pustaka_misi: Array[DataMisi] = []
var _pustaka_headline: PemuatHeadline.Pustaka = PemuatHeadline.Pustaka.new()
var _galat_data: Array[String] = []
## Data upgrade bengkel (`PemuatToko`, satu-satunya pembaca berkas upgrade); dimuat sekali.
var _toko: PemuatToko.Kumpulan = PemuatToko.Kumpulan.new()
## Pustaka kepribadian pelanggan (`PemuatPelanggan`, satu-satunya pembaca berkasnya); dimuat sekali (run fase6a2-reputasi-pelanggan).
var _kepribadian: PemuatPelanggan.Kumpulan = PemuatPelanggan.Kumpulan.new()
## Layar bengkel yang sedang terbuka (null di luar keadaan BENGKEL) dan saldo awalnya (koin save + koin hari ini), untuk menghitung belanja.
var _bengkel: LayarBengkel = null
var _saldo_awal_bengkel: int = 0
var _rute: RuteMain = null
## Id misi yang diambil hari ini ("" bila dilewati atau tidak ada).
var _misi_diambil: String = ""
## True bila simpan terakhir (akhir hari) gagal; layar koran berikutnya memberi tahu sampai satu simpan berhasil.
var _simpan_gagal: bool = false

@onready var _koran: HalamanKoran = %Koran


func _ready() -> void:
	if simpanan == null:
		simpanan = get_node_or_null(^"/root/SaveManager") as SKRIP_SIMPAN
	if simpanan == null:
		simpanan = SKRIP_SIMPAN.new()
		add_child(simpanan)
	_muat_data()
	_koran.berangkat_diminta.connect(_saat_berangkat)
	_mesin = MesinHari.awal(simpanan.hari())
	_tampilkan_koran()


func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_GO_BACK_REQUEST or not is_node_ready():
		return
	var aksi: MesinHari.AksiBack = MesinHari.aksi_back(_mesin.keadaan)
	if aksi == MesinHari.AksiBack.KELUAR_APP:
		keluar_diminta.emit()
		if panggil_quit:
			get_tree().quit()
	elif aksi == MesinHari.AksiBack.LEWATI_BENGKEL:
		_saat_hari_berikutnya()


## Memuat data misi dan headline dan memeriksa aturan antar data; galat dicatat (bukan crash).
func _muat_data() -> void:
	var misi: PemuatMisi.Kumpulan = PemuatMisi.muat_folder()
	_pustaka_misi = misi.misi
	_pustaka_headline = PemuatHeadline.muat_folder()
	_toko = PemuatToko.muat()
	_kepribadian = PemuatPelanggan.muat()
	_galat_data = []
	_galat_data.append_array(_toko.galat)
	_galat_data.append_array(_kepribadian.galat)
	_galat_data.append_array(misi.galat)
	_galat_data.append_array(_pustaka_headline.galat)
	_galat_data.append_array(PemuatHeadline.periksa_silang(_pustaka_headline, _pustaka_misi))
	if not _galat_data.is_empty() and lapor_ke_log:
		push_error("Data koran tidak sah: %s" % "; ".join(_galat_data))


## Menyusun dan menampilkan koran hari `_mesin.hari` dari save (hari yang sama = koran yang sama).
func _tampilkan_koran() -> void:
	var masukan: HeadlineManager.Masukan = HeadlineManager.Masukan.new()
	masukan.hari = _mesin.hari
	masukan.flag = DataSave.daftar_flag(simpanan.state)
	masukan.headline_jeda = DataSave.daftar_jeda(simpanan.state, "headline_jeda")
	masukan.misi_jeda = DataSave.daftar_jeda(simpanan.state, "misi_jeda")
	masukan.pustaka = _pustaka_headline
	masukan.misi = _pustaka_misi
	_halaman = HeadlineManager.susun(masukan)
	_misi_diambil = ""
	_koran.isi(_halaman, _mesin.hari, Config.DISTRIK_AWAL)
	_koran.tampilkan_notifikasi(_kunci_notifikasi())
	_koran.tampilkan(true)


## Kunci satu baris notifikasi layar koran: masalah save saat muat (sekali), atau simpan akhir hari yang gagal ("" bila tidak ada).
func _kunci_notifikasi() -> String:
	var kunci: String = simpanan.ambil_notifikasi()
	if kunci.is_empty() and _simpan_gagal:
		kunci = SKRIP_SIMPAN.KUNCI_TIDAK_TERBACA if simpanan.simpan_ditahan() else "KORAN_SAVE_GAGAL"
	return kunci


## Berangkat: rute hari ini dibuat tepat sekali.
func _saat_berangkat() -> void:
	var baru: MesinHari.Status = MesinHari.terapkan(_mesin, MesinHari.Peristiwa.BERANGKAT)
	if not baru.diterima:
		return
	_mesin = baru
	_misi_diambil = ""
	if _koran.pilihan() == HalamanKoran.Pilihan.AMBIL and _halaman.misi != null:
		_misi_diambil = _halaman.misi.misi_id
	var pengaturan: Dictionary = simpanan.pengaturan()
	_rute = ADEGAN_RUTE.instantiate() as RuteMain
	_rute.atur_hari(_mesin.hari)
	_rute.atur_benih_awal(SeedHari.rute(_mesin.hari))
	_rute.atur_sepeda(simpanan.state, _mesin.hari, _toko.upgrade)
	_rute.atur_pelanggan(simpanan.state, _kepribadian.entri)
	_rute.atur_misi(_data_misi(_misi_diambil))
	_rute.atur_tutorial(TutorialLangkah.boleh_aktif(_mesin.hari, DataSave.tutorial_selesai(simpanan.state)))
	_rute.hasil_dibuka.connect(_saat_hasil_dibuka)
	_rute.bengkel_diminta.connect(_saat_bengkel_diminta)
	add_child(_rute)
	_rute.atur_mode_hari(true)
	_rute.atur_kidal(bool(pengaturan["kidal"]))
	_rute.atur_mode_bantu(bool(pengaturan["mode_bantu"]))
	_koran.tampilkan(false)
	jumlah_rute_dibuat += 1
	rute_dimulai.emit(_rute)


func _saat_hasil_dibuka(_angka: HasilRute.Angka) -> void:
	_mesin = MesinHari.terapkan(_mesin, MesinHari.Peristiwa.HASIL_TERBUKA)


## "Ke bengkel" (layar hasil): `BUKA_BENGKEL` diterima sekali. Layar bengkel dibuka di atas rute yang dibekukan; state kerja = save + koin hari ini + kondisi akhir rute. Tidak ada simpan.
func _saat_bengkel_diminta() -> void:
	var baru: MesinHari.Status = MesinHari.terapkan(_mesin, MesinHari.Peristiwa.BUKA_BENGKEL)
	if not baru.diterima or _rute == null or _rute.angka_hasil() == null:
		return
	_mesin = baru
	var angka: HasilRute.Angka = _rute.angka_hasil()
	var kerja: Dictionary = simpanan.state.duplicate(true)
	_saldo_awal_bengkel = HasilRute.saldo_sesudah(int(kerja["koin"]), angka.koin_bersih)
	kerja["koin"] = _saldo_awal_bengkel
	var sepeda: Dictionary = kerja["sepeda"]
	var akhir: Dictionary = _rute.kondisi_akhir()
	for id: String in Config.KONDISI_KOMPONEN:
		var entri: Dictionary = sepeda[id]
		entri["kondisi"] = akhir[id]
	# Rute dibekukan di bawah bengkel: tidak diproses dan tidak menerima sentuhan, layar hasilnya disembunyikan (tombol "Ke bengkel" tidak boleh tertekan lagi dari bawah).
	_rute.layar_hasil().tampilkan(false)
	_rute.process_mode = Node.PROCESS_MODE_DISABLED
	_bengkel = ADEGAN_BENGKEL.instantiate() as LayarBengkel
	add_child(_bengkel)
	_bengkel.isi(kerja, _toko)
	_bengkel.hari_berikutnya_diminta.connect(_saat_hari_berikutnya)


## "Hari berikutnya" dari bengkel (tombol atau back Android): catat dan simpan hari ini (satu kali) dengan kondisi sepeda, servis, upgrade, dan belanja dari bengkel, buang rute dan bengkel,
## tampilkan koran hari berikutnya. Dari keadaan lain (mis. layar hasil) ditolak tanpa efek.
func _saat_hari_berikutnya() -> void:
	var baru: MesinHari.Status = MesinHari.terapkan(_mesin, MesinHari.Peristiwa.HARI_BERIKUTNYA)
	if not baru.diterima or _rute == null or _bengkel == null:
		return
	var kerja: Dictionary = _bengkel.state()
	var jeda: HeadlineManager.JedaBaru = HeadlineManager.catat_jeda(_halaman, _misi_diambil)
	var catatan: DataSave.CatatanHari = DataSave.CatatanHari.new()
	catatan.hari = _mesin.hari
	catatan.angka = _rute.angka_hasil()
	catatan.misi_diambil = _misi_diambil
	var flag_baru: String = MissionManager.flag_hasil(_data_misi(_misi_diambil), catatan.angka.misi_hasil)
	if not flag_baru.is_empty():
		catatan.flag_baru = [flag_baru]
	catatan.flag_dikonsumsi = HeadlineManager.flag_terpakai(_halaman, _pustaka_headline)
	catatan.tutorial_selesai = _rute.tutorial_dimulai()
	catatan.headline_jeda = jeda.headline
	catatan.misi_jeda = jeda.misi
	catatan.kidal = _rute.kidal()
	catatan.mode_bantu = _rute.mode_bantu()
	catatan.sepeda = kerja["sepeda"]
	catatan.belanja_koin = maxi(_saldo_awal_bengkel - Economy.saldo(kerja), 0)
	catatan.pelanggan = _rute.catatan_pelanggan()
	catatan.kepribadian = _kepribadian.entri
	var hari_dimainkan: int = _mesin.hari
	var tersimpan: bool = simpanan.akhiri_hari(catatan)
	if not tersimpan and not simpanan.simpan_ditahan():
		tersimpan = simpanan.simpan()
	_simpan_gagal = not tersimpan
	var rute_lama: RuteMain = _rute
	_rute = null
	remove_child(rute_lama)
	rute_lama.queue_free()
	var bengkel_lama: LayarBengkel = _bengkel
	_bengkel = null
	remove_child(bengkel_lama)
	bengkel_lama.queue_free()
	_mesin = baru
	_tampilkan_koran()
	hari_selesai.emit(hari_dimainkan)


## Data misi dengan id `id` dari pustaka, atau null ("" atau tidak ada).
func _data_misi(id: String) -> DataMisi:
	if id.is_empty():
		return null
	for misi: DataMisi in _pustaka_misi:
		if misi.id == id:
			return misi
	return null


# --- Untuk tes dan probe ---

## Layar koran.
func koran() -> HalamanKoran:
	return _koran


## Rute hari ini (null di layar koran).
func rute() -> RuteMain:
	return _rute


## Layar bengkel yang sedang terbuka (null di luar bengkel).
func bengkel() -> LayarBengkel:
	return _bengkel


## Data upgrade bengkel yang dimuat.
func toko() -> PemuatToko.Kumpulan:
	return _toko


## Halaman koran hari ini.
func halaman() -> HeadlineManager.Halaman:
	return _halaman


## Status mesin hari saat ini.
func status() -> MesinHari.Status:
	return _mesin


## Id misi yang diambil hari ini ("" bila dilewati).
func misi_diambil() -> String:
	return _misi_diambil


## Galat memuat data koran (kosong bila baik).
func galat_data() -> Array[String]:
	return _galat_data
