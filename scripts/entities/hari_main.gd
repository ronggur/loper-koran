class_name HariMain
extends Node
## Scene hari (`scenes/hari/hari.tscn`, scene utama sejak run fase4a-koran-hari; S-1, AC-17 sampai AC-19): alur satu hari Koran -> Rute -> Hasil ->
## "Hari berikutnya" -> Koran hari berikutnya. Akar tipis: keputusan ada di `MesinHari` (urutan peristiwa, back), `HeadlineManager` (halaman),
## `SeedHari` (seed rute), dan `DataSave` lewat autoload `SaveManager` (simpan); node ini hanya menyambungkan.
## - Saat siap: memuat data misi dan headline (`PemuatMisi`, `PemuatHeadline`), membaca save dari `SaveManager` SEBELUM layar koran dibuat
##   (hari, flag, jeda, pengaturan), lalu menampilkan koran hari itu.
## - Berangkat: `RuteMain` dibuat tepat sekali per hari (peristiwa ganda ditolak `MesinHari`), seed rute = `SeedHari.rute(hari)` disuntik SEBELUM
##   rute masuk pohon (tanpa `main_lagi`), mode hari (tombol layar hasil = "Hari berikutnya"), lalu kidal dan mode bantu dari save diterapkan.
##   Misi yang diambil hanya tercatat (S-7), tanpa efek di rute (misi 4B).
## - "Hari berikutnya": angka `HasilRute.Angka` yang sama dengan layar hasil + misi diambil + jeda + sakelar jeda dicatat dan DISIMPAN tepat satu
##   kali (`SaveManager.akhiri_hari`), rute dibuang, koran hari + 1 tampil. Tidak ada simpan di tempat lain (layar koran, Ambil/Lewati, Berangkat,
##   jeda, background, hasil terbuka, rute ditutup di tengah jalan): save terakhir tetap utuh dan hari yang sama diulang dari layar koran (AC-19).
## - Back Android (S-6): di layar koran keluar app (`keluar_diminta`, lalu `SceneTree.quit` kecuali `panggil_quit` dimatikan tes); di rute `AdeganJalan`
##   menjeda sendiri; di layar hasil diabaikan. App ke background di layar koran tidak melakukan apa pun.
## - Simpan gagal (QA-004): `akhiri_hari` dicoba sekali lagi; bila tetap gagal (atau ditahan karena save lama tidak aman ditimpa, QA-003) hari tetap
##   maju di memori, alur TIDAK diblokir, dan layar koran berikutnya menampilkan satu baris netral (`KORAN_SAVE_GAGAL`, atau
##   `KORAN_SAVE_TIDAK_TERBACA` bila simpan ditahan) sampai satu simpan berhasil. Kemajuan menumpuk di memori, jadi simpan berikutnya
##   yang berhasil menuliskan semuanya.
## Alur hari berurutan ini prototype yang tidak mengunci struktur sesi (ROADMAP 5): tanpa hari terakhir, game over, atau target harian.

## Skrip autoload `SaveManager`, hanya untuk tipe (autoload tidak diberi `class_name`, rule `gdscript`).
const SKRIP_SIMPAN := preload("res://scripts/autoload/save_manager.gd")
const ADEGAN_RUTE: PackedScene = preload("res://scenes/rute/rute.tscn")

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
	if MesinHari.aksi_back(_mesin.keadaan) == MesinHari.AksiBack.KELUAR_APP:
		keluar_diminta.emit()
		if panggil_quit:
			get_tree().quit()


## Memuat data misi dan headline dan memeriksa aturan antar data; galat dicatat (bukan crash).
func _muat_data() -> void:
	var misi: PemuatMisi.Kumpulan = PemuatMisi.muat_folder()
	_pustaka_misi = misi.misi
	_pustaka_headline = PemuatHeadline.muat_folder()
	_galat_data = []
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
	_rute.atur_benih_awal(SeedHari.rute(_mesin.hari))
	_rute.hasil_dibuka.connect(_saat_hasil_dibuka)
	_rute.hari_berikutnya_diminta.connect(_saat_hari_berikutnya)
	add_child(_rute)
	_rute.atur_mode_hari(true)
	_rute.atur_kidal(bool(pengaturan["kidal"]))
	_rute.atur_mode_bantu(bool(pengaturan["mode_bantu"]))
	_koran.tampilkan(false)
	jumlah_rute_dibuat += 1
	rute_dimulai.emit(_rute)


func _saat_hasil_dibuka(_angka: HasilRute.Angka) -> void:
	_mesin = MesinHari.terapkan(_mesin, MesinHari.Peristiwa.HASIL_TERBUKA)


## "Hari berikutnya": catat dan simpan hari ini (satu kali), buang rute, tampilkan koran hari berikutnya.
func _saat_hari_berikutnya() -> void:
	var baru: MesinHari.Status = MesinHari.terapkan(_mesin, MesinHari.Peristiwa.HARI_BERIKUTNYA)
	if not baru.diterima or _rute == null:
		return
	var jeda: HeadlineManager.JedaBaru = HeadlineManager.catat_jeda(_halaman, _misi_diambil)
	var catatan: DataSave.CatatanHari = DataSave.CatatanHari.new()
	catatan.hari = _mesin.hari
	catatan.angka = _rute.angka_hasil()
	catatan.misi_diambil = _misi_diambil
	catatan.headline_jeda = jeda.headline
	catatan.misi_jeda = jeda.misi
	catatan.kidal = _rute.kidal()
	catatan.mode_bantu = _rute.mode_bantu()
	var hari_dimainkan: int = _mesin.hari
	var tersimpan: bool = simpanan.akhiri_hari(catatan)
	if not tersimpan and not simpanan.simpan_ditahan():
		tersimpan = simpanan.simpan()
	_simpan_gagal = not tersimpan
	var rute_lama: RuteMain = _rute
	_rute = null
	remove_child(rute_lama)
	rute_lama.queue_free()
	_mesin = baru
	_tampilkan_koran()
	hari_selesai.emit(hari_dimainkan)


# --- Untuk tes dan probe ---

## Layar koran.
func koran() -> HalamanKoran:
	return _koran


## Rute hari ini (null di layar koran).
func rute() -> RuteMain:
	return _rute


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
