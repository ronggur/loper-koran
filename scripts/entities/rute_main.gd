class_name RuteMain
extends AdeganJalan
## Scene rute (run fase3a-rute bagian B, AC-10 sampai AC-16, usulan): satu rute perumahan dari segmen JSON, scene utama game.
##
## Memakai seluruh perilaku `AdeganJalan` (gerak, kamera, jeda, lemparan, mode bantu, bunyi, HUD) dan hanya mengisi kaitnya untuk rute:
## - Dunia (D-13): rute disusun `RouteBuilder.bangun(benih, pustaka)` dari segmen `PemuatRute.muat_folder`; seed bawaan
##   `Config.RUTE_SEED_DEV`, "Main lagi" memakai seed + 1. Rumah dan kotak surat digambar `RumahDaurRute` (jendela daur), tanah `TanahDaur`.
## - Penilaian koran dan mode bantu (AC-10): `MedanKoran.dari_rute` untuk penilaian dan garis bidik, `ZonaSasaran.zona_rute_rentang` untuk sasaran
##   mode bantu sejauh jangkauan lemparan. Koran awal = `rute.koran_awal` (30), tanpa isi ulang jalan uji.
## - Akhir rute (AC-14, `AkhirRute`): sepeda mencapai garis akhir (`panjang_ubin`) -> `rute_selesai` tepat sekali, stick sungguhan dikunci
##   dan diganti stick buatan ke bawah penuh (rem dengan laju rem biasa), lemparan baru tidak diterima (koran yang sudah terbang tetap
##   mendarat dan dinilai), banner `RUTE_SELESAI` tampil sesaat. Jeda dan back tetap bekerja.
## - Penutup pemain (AC-15): SATU penerap (`PenerapPenutup`) memanggil `PenutupPemain` tiap langkah untuk semua rumah di jendela daur.
## - "Main lagi" (tombol layar hasil sejak run fase3c-hud-hasil, O-11; tombol banner hanya untuk galat muat): seed + 1, rute baru, sepeda,
##   sisa koran, koran terbang, skor, tenggat, radar, progres, rintangan, bel, dan oleng dikembalikan ke awal (`_susun`, `_kembalikan_awal`).
## - Area kotak surat (tindak lanjut uji HP 2026-10-16): `AreaKotakGambar` menggambar persegi zona kotak surat rumah pelanggan seberang di
##   tanah (jendela daur yang sama dengan rumah), supaya area yang dinilai terlihat.
## - Rintangan (run fase3b-rintangan-skor bagian B, AC-20): `RintanganRute.dari_rute` (kait `_rintangan_awal`, juga tiap "Main lagi"),
##   perilaku dan tabrakan di `AdeganJalan`; digambar `RintanganDaur` (anak induk Y-sort rumah, jendela daur, penutup lewat penerap yang
##   SAMA dengan rumah).
## - Skor dan koin (AC-9 sampai AC-13): kait `_skor_aktif` true, `_rute_skor` = rute ini (pemberi tip); umpan balik melayang digambar
##   `UmpanMelayangGambar` di atas objek.
## - Run fase3c-hud-hasil (K-1, O-6 sampai O-12, AC-1 sampai AC-13, usulan):
##   - Tenggat (`TenggatRute`): jam dimulai saat rute disusun, maju dengan dt efektif lewat kait `_langkah_waktu` (beku saat jeda dan
##     background), berhenti di garis akhir. Sesudah lewat rute tetap berjalan; koran yang mendarat tidak memberi tip (`_tenggat_lewat`).
##   - HUD rute final (`HudRute`): tiap langkah radar (`RadarRute.penanda` dari jarak sepeda, rumah terantar, mode bantu, tenggat lewat),
##     kotak progres (`ProgresRute.status`), "n/25 TERKIRIM", dan tenggat. HUD hanya menampilkan.
##   - Layar hasil (`LayarHasil`, O-11): terbuka tepat sekali sesudah garis akhir, saat sepeda berhenti dan tidak ada koran terbang
##     (`HasilRute.siap_tampil`); angka dari `HasilRute.dari` (satu sumber). Saat terbuka banner disembunyikan, HUD disembunyikan (tombol
##     jeda tidak bisa disentuh) dan kontrol sentuh tidak membaca sentuhan (stick, swipe, tap, bel), jadi hanya tombol "Main lagi" yang
##     aktif. Back Android di layar hasil diabaikan (`_saring_jeda`; tidak memulai ulang diam-diam dan tidak membuka layar jeda di atasnya);
##     app ke background tetap menjeda seperti biasa.

##
## Run fase5a bagian B (usulan, hanya tampilan): scene rute memakai sprite gelombang 1 untuk koran (`KoranGambar.pakai_sprite` di `rute.tscn`), debu roda dan garis kecepatan (`atur_sprite` di
## `_siapkan_dunia`), bintang kena dan koin tip (`UmpanMelayangGambar`), kilau kucing (`KucingHiasan`), dan koran terlipat di rumah terantar (`RumahDaurRute.atur_terantar` tiap langkah dari
## `_skor.terantar`, hanya dibaca). Skor, zona, tenggat, gerak, tabrakan, misi, dan kondisi tidak berubah.
##
## Run fase4b-misi-kucing (AC-11 sampai AC-14, M-1 sampai M-5, K-1 sampai K-4, usulan): misi sampingan hari ini lewat `atur_misi` (kosong = tanpa misi,
## perilaku 3A sampai 4A tidak berubah; `rute.tscn` yang dijalankan sendiri tidak punya misi):
## - `RencanaMisi.buat` (benih = seed rute + `SEED_MISI_SELISIH`, disusun tiap rute) lalu `MissionManager.langkah` tiap langkah dengan posisi, kecepatan, jatuh,
##   jeda, dt efektif, dan lemparan yang baru dinilai (`_koran_dinilai`: `SkorRute.Hasil.tepat`, `Koran.bantu`, hasil kotak surat, rumah yang kena, apa adanya).
##   Peristiwa dipancarkan sebagai `misi_peristiwa` dan diteruskan ke bunyi (`Audio.putar_misi`).
## - Kucing digambar `KucingMisi` (anak `Objek`, Y-sort dengan rumah; lewat penerap penutup yang sama), HUD menampilkan kartu, banner, dan gelembung petunjuk.
## - Hadiah misi (K-1) ikut `koin` di HUD (`_koin_tambahan`) dan di `HasilRute.Angka` yang sama dengan layar hasil dan save; gagal tidak mengubah koin, tip, skor,
##   atau tenggat. Misi tidak pernah masih aktif saat layar hasil terbuka: `MissionManager` menggagalkan di garis akhir rute pada langkah yang sama dengan `AkhirRute`
##   (iterasi 2, QA-004: cabang `_akhiri_misi_aktif` iterasi 1 tidak terjangkau dan dihapus; dijaga tes `tes_misi_scene`).
##
## - Tutorial hari 1 (M-9, `atur_tutorial`): `TutorialLangkah` (logika murni) dari kecepatan, jumlah lemparan, dan keadaan kucing/misi; `TutorialController` hanya
##   menampilkan dan tidak memblokir input. Rute yang dijalankan sendiri tidak punya tutorial. Hari tutorial yang berakhir ditulis `tutorial.selesai` oleh `HariMain`.
##
## Run fase6a1-bengkel-kondisi bagian B (AC-6, AC-11, AC-20, AC-21, AC-24): kondisi sepeda rute (`KondisiRute`). `atur_sepeda` (dipanggil `HariMain` SEBELUM scene masuk pohon, seperti `atur_misi`) memberi
## kondisi dan level upgrade tersimpan, hari (seed kerusakan tabrakan), dan daftar upgrade (`PemuatToko`); tanpa itu rute yang dijalankan sendiri memakai sepeda baru. Aus dan kerusakan berhenti di
## garis akhir (`_kondisi_selesai`); "Main lagi" mengembalikan kondisi awal rute. Layar hasil mendapat daftar komponen PERLU_BENGKEL (`BikeCondition.perlu_bengkel`) tanpa mengubah `HasilRute.Angka`.
##
## Sepeda mencapai garis akhir rute (tepat sekali per rute; diulang hanya sesudah "Main lagi").
signal rute_selesai
## Rute baru disusun (saat scene siap dan tiap "Main lagi").
signal rute_disusun(rute: RouteBuilder.Rute)
## Layar hasil terbuka (tepat sekali per rute): angka yang ditampilkan.
signal hasil_dibuka(angka: HasilRute.Angka)
## Peristiwa misi (`MissionManager.Peristiwa`) pada langkah ke-`langkah` (indeks titik); sebelum bunyi dan HUD dipasang.
signal misi_peristiwa(jenis: MissionManager.Peristiwa, langkah: int)
## Tombol "Ke bengkel" layar hasil ditekan (hanya di mode hari, `atur_mode_hari`; run fase4a-koran-hari AC-17, run fase6a1-bengkel-kondisi AC-24: dulu "Hari berikutnya").
signal bengkel_diminta

## Seed rute yang sedang dimainkan.
var _benih: int = Config.RUTE_SEED_DEV
var _rute: RouteBuilder.Rute = RouteBuilder.Rute.new()
var _pustaka: Array[SegmenRute] = []
## Galat memuat segmen atau menyusun rute (kosong bila baik).
var _galat: Array[String] = []
## False hanya di tes yang sengaja memicu galat: galat tidak dicetak sebagai `ERROR:` ke log (pemeriksa keluaran tes menolak baris itu).
var lapor_galat_ke_log: bool = true
var _selesai: bool = false
## Jam tenggat rute (`TenggatRute`).
var _tenggat: TenggatRute.Keadaan = TenggatRute.Keadaan.new()
## True sejak layar hasil terbuka sampai "Main lagi".
var _hasil_tampil: bool = false
## Angka layar hasil terakhir (null sebelum layar hasil terbuka).
var _angka_hasil: HasilRute.Angka = null
## Misi sampingan hari ini (null = tanpa misi), rencana dan keadaannya, lemparan yang menunggu langkah misi berikutnya, dt langkah terakhir, dan waktu animasi kucing.
var _misi: DataMisi = null
var _rencana_misi: RencanaMisi.Rencana = null
var _keadaan_misi: MissionManager.Keadaan = null
var _lemparan_misi: Array[MissionManager.Lemparan] = []
var _dt_langkah: float = 0.0
var _detik_misi: float = 0.0
## Tutorial hari 1: diminta `atur_tutorial` (HariMain), keadaannya (null = tanpa tutorial), dan jumlah lemparan yang diterima sejak rute dimulai.
var _tutorial_diminta: bool = false
var _tutorial: TutorialLangkah.Keadaan = null
var _jumlah_lempar: int = 0
## Sepeda awal rute dari save (`atur_sepeda`): kondisi, level upgrade, hari, dan daftar upgrade yang sah.
var _sepeda_kondisi: Dictionary = BikeCondition.baru()
var _sepeda_level: Dictionary = {}
var _sepeda_hari: int = Config.HARI_AWAL
var _daftar_upgrade: Array[DataToko] = []

@onready var _daur: RumahDaurRute = %Objek
@onready var _area_kotak: AreaKotakGambar = %AreaKotak
@onready var _penerap: PenerapPenutup = %PenerapPenutup
@onready var _panel_akhir: PanelAkhirRute = %PanelAkhir
@onready var _rintangan_daur: RintanganDaur = %Rintangan
@onready var _dekor_daur: DekorDaur = %Dekor
@onready var _umpan_gambar: UmpanMelayangGambar = %UmpanMelayang
@onready var _layar_hasil: LayarHasil = %LayarHasil
@onready var _kucing: KucingMisi = %Kucing
@onready var _tutorial_node: TutorialController = %Tutorial


func _siapkan_dunia() -> void:
	_sepeda.umpan_balik().atur_sprite(true)
	_daur.penerap = _penerap
	_rintangan_daur.penerap = _penerap
	_dekor_daur.penerap = _penerap
	_kucing.penerap = _penerap
	_tutorial_node.lewati_diminta.connect(_saat_tutorial_dilewati)
	koran_dilempar.connect(_saat_lempar_diterima)
	_panel_akhir.main_lagi_diminta.connect(main_lagi)
	_layar_hasil.main_lagi_diminta.connect(main_lagi)
	_layar_hasil.bengkel_diminta.connect(bengkel_diminta.emit)
	_susun(_benih)


func _perbarui_dunia(jarak_ubin: float) -> void:
	_langkah_misi(jarak_ubin)
	_langkah_tutorial()
	_daur.perbarui(jarak_ubin)
	_daur.atur_terantar(_skor.terantar)
	_area_kotak.perbarui(jarak_ubin)
	_rintangan_daur.perbarui(_rintangan, jarak_ubin)
	_dekor_daur.perbarui(jarak_ubin)
	_umpan_gambar.tampilkan(_umpan)
	_penerap.terapkan(_sepeda.posisi_dunia())
	var status: AkhirRute.Status = AkhirRute.periksa(_selesai, jarak_ubin, _rute.panjang_ubin)
	_selesai = status.selesai
	if status.baru_selesai:
		_tenggat = TenggatRute.hentikan(_tenggat)
		_kontrol.lepas_semua()
		_garis_bidik.sembunyikan()
		_panel_akhir.tampilkan(true)
		rute_selesai.emit()
	_perbarui_hud_rute(jarak_ubin)
	if _selesai and not _hasil_tampil and HasilRute.siap_tampil(_selesai, _sepeda.kecepatan_ud, koran_terbang()):
		_buka_hasil()


## HUD rute final dari keadaan murni (hanya menampilkan).
func _perbarui_hud_rute(jarak_ubin: float) -> void:
	var hud: HudRute = _hud as HudRute
	if hud == null:
		return
	var lewat: bool = TenggatRute.lewat(_tenggat)
	hud.tampilkan_tenggat(_tenggat)
	hud.tampilkan_radar(RadarRute.penanda(_rute, jarak_ubin, _skor.terantar, mode_bantu(), lewat))
	hud.tampilkan_progres(ProgresRute.status(_rute, jarak_ubin, _skor.terantar, _selesai), ProgresRute.jumlah_terkirim(_rute, _skor.terantar), _rute.pelanggan.size())


## Membuka layar hasil (tepat sekali per rute): angka dari `HasilRute`, banner dan HUD disembunyikan, kontrol sentuh berhenti membaca.
func _buka_hasil() -> void:
	_hasil_tampil = true
	_angka_hasil = HasilRute.dari(_skor, _rute, _tenggat, _keadaan_misi)
	var perlu: Array[String] = BikeCondition.perlu_bengkel(_kondisi.kondisi) if _kondisi != null else []
	_layar_hasil.isi(_angka_hasil, _misi if _keadaan_misi != null else null, perlu)
	_layar_hasil.tampilkan(true)
	_panel_akhir.tampilkan(false)
	_hud.visible = false
	_tutorial_node.visible = false
	_kontrol.lepas_semua()
	_kontrol.set_process_input(false)
	hasil_dibuka.emit(_angka_hasil)


func _langkah_waktu(langkah_dt: float) -> void:
	_dt_langkah = langkah_dt
	if not _selesai:
		_tenggat = TenggatRute.langkah(_tenggat, langkah_dt)


func _tenggat_lewat() -> bool:
	return TenggatRute.lewat(_tenggat)


## Rute yang dibekukan `HariMain` di bawah layar bengkel (`process_mode` DISABLED) mengabaikan semua peristiwa jeda: notifikasi aplikasi (PAUSED, FOCUS_OUT, GO_BACK) tetap
## dikirim ke tiap node di pohon walau `process_mode` mati, dan menjeda rute tersembunyi memasang `SceneTree.paused` sehingga bengkel berhenti menerima sentuhan dan dialog JEDA muncul
## di atasnya (QA-001 run fase6a1). Di rute dan layar hasil `process_mode` tetap bawaan, jadi jeda di sana tidak berubah.
func _saring_jeda(peristiwa: JedaSim.Peristiwa) -> JedaSim.Peristiwa:
	if process_mode == Node.PROCESS_MODE_DISABLED:
		return JedaSim.Peristiwa.TIDAK_ADA
	if _hasil_tampil and peristiwa == JedaSim.Peristiwa.BACK and not sedang_jeda():
		return JedaSim.Peristiwa.TIDAK_ADA
	return peristiwa


func _zona_bantu(maju_awal_ubin: float, maju_akhir_ubin: float) -> Array[ZonaSasaran.Zona]:
	return ZonaSasaran.zona_rute_rentang(_rute.rumah, maju_awal_ubin, maju_akhir_ubin)


func _skor_aktif() -> bool:
	return true


func _koin_tambahan() -> int:
	return MissionManager.koin_misi(_keadaan_misi)


func _koran_dinilai(k: KoranLempar.Koran, hasil_skor: SkorRute.Hasil) -> void:
	if _keadaan_misi == null or hasil_skor == null:
		return
	var l: MissionManager.Lemparan = MissionManager.Lemparan.new()
	l.tepat = hasil_skor.tepat
	l.bantu = k.bantu
	l.kotak_pelanggan = k.hasil == ZonaSasaran.Hasil.KOTAK_SURAT
	for rumah: RouteBuilder.RumahRute in _rute.rumah:
		if rumah.id == k.id_rumah:
			l.maju_rumah_ubin = rumah.maju_ubin
			break
	_lemparan_misi.append(l)


func _rute_skor() -> RouteBuilder.Rute:
	return _rute


func _rintangan_awal() -> RintanganRute.Keadaan:
	return RintanganRute.dari_rute(_rute)


func _kondisi_awal() -> KondisiRute.Keadaan:
	return KondisiRute.awal(_sepeda_kondisi, _sepeda_level, _sepeda_hari, _daftar_upgrade)


func _kondisi_selesai() -> bool:
	return _selesai


func _vektor_stick() -> Vector2:
	if _selesai:
		return AkhirRute.stick_akhir()
	return super()


func _lempar_diizinkan() -> bool:
	return not _selesai


## Menyusun ulang rute dengan seed `benih`, dan mengembalikan adegan ke awal. Pustaka segmen dimuat sekali.
func _susun(benih: int) -> void:
	_benih = benih
	_galat = []
	if _pustaka.is_empty():
		var kumpulan: PemuatRute.Kumpulan = PemuatRute.muat_folder()
		_galat.append_array(kumpulan.galat)
		_pustaka = kumpulan.segmen
	var hasil: RouteBuilder.Hasil = RouteBuilder.bangun(benih, _pustaka)
	_galat.append_array(hasil.galat)
	var gagal: bool = false
	if hasil.rute != null and _galat.is_empty():
		_rute = hasil.rute
	else:
		if lapor_galat_ke_log:
			push_error("Rute tidak bisa disusun (seed %d): %s" % [benih, "; ".join(_galat)])
		_rute = RouteBuilder.Rute.new()
		gagal = true
	_medan = MedanKoran.dari_rute(_rute)
	_selesai = false
	_tenggat = TenggatRute.awal(_rute.panjang_ubin)
	_hasil_tampil = false
	_angka_hasil = null
	_layar_hasil.tampilkan(false)
	_hud.visible = true
	_tutorial_node.visible = true
	_kontrol.set_process_input(true)
	_daur.atur_rute(_rute)
	_tanah.atur_baris_masuk(UbinKhusus.himpunan_baris_masuk(_rute.objek))
	_area_kotak.atur_rute(_rute)
	_rintangan_daur.lepas_semua()
	_dekor_daur.atur_rute(_rute)
	_penerap.terapkan(_sepeda.posisi_dunia())
	_panel_akhir.tampilkan(false)
	if gagal:
		_panel_akhir.tampilkan_galat()
		# Tanpa rute tidak ada yang bisa disetir atau dilempar; tombol banner galat ada di zona swipe, jadi kontrol sentuh tidak membaca
		# sentuhan supaya ketukannya bukan tap atau swipe.
		_kontrol.set_process_input(false)
	_susun_misi()
	_susun_tutorial()
	_kembalikan_awal(_rute.koran_awal)
	rute_disusun.emit(_rute)


## Menyusun ulang rencana dan keadaan misi untuk rute yang sedang dimainkan (tiap rute disusun). Tanpa misi, atau rute gagal disusun, atau rencana tidak sah:
## tidak ada misi (kartu, banner, dan kucing tersembunyi).
func _susun_misi() -> void:
	_lemparan_misi = []
	_detik_misi = 0.0
	_rencana_misi = null
	_keadaan_misi = null
	if _misi != null and not _rute.pelanggan.is_empty():
		_rencana_misi = RencanaMisi.buat(_misi, _rute, _benih + Config.SEED_MISI_SELISIH)
		if _rencana_misi.sah():
			_keadaan_misi = MissionManager.awal(_rencana_misi)
	_tampilkan_misi()


## Satu langkah misi sesudah sepeda digerakkan dan lemparan dinilai (urutan `AdeganJalan.perbarui`): masukan dari keadaan sebenarnya, peristiwa ke sinyal dan bunyi.
func _langkah_misi(jarak_ubin: float) -> void:
	if _keadaan_misi == null:
		return
	var m: MissionManager.Masukan = MissionManager.Masukan.new()
	m.maju_ubin = jarak_ubin
	m.lateral_ubin = _sepeda.lateral_ubin
	m.kecepatan_ud = _sepeda.kecepatan_ud
	m.jatuh = Tabrakan.jatuh(_rintangan.tabrakan)
	m.jeda = sedang_jeda()
	m.dt = _dt_langkah
	m.lemparan = _lemparan_misi
	_lemparan_misi = []
	if is_finite(_dt_langkah) and _dt_langkah > 0.0 and not m.jeda:
		_detik_misi += _dt_langkah
	var hasil: MissionManager.Hasil = MissionManager.langkah(_keadaan_misi, m)
	_keadaan_misi = hasil.keadaan
	for k: MissionManager.Kejadian in hasil.kejadian:
		if _audio != null:
			_audio.putar_misi_peristiwa(k.jenis)
		misi_peristiwa.emit(k.jenis, k.langkah)
	_tampilkan_misi()


## Menyusun ulang tutorial untuk rute yang sedang dimainkan: berjalan bila diminta; petunjuk menepi hanya bila ada misi aktif.
func _susun_tutorial() -> void:
	_jumlah_lempar = 0
	_tutorial = TutorialLangkah.awal(_tutorial_diminta, _keadaan_misi != null) if _tutorial_diminta else null
	_tutorial_node.tampilkan_langkah(_tutorial)


## Satu langkah tutorial dari keadaan sebenarnya (kecepatan, lemparan, kucing tangkap, misi berakhir).
func _langkah_tutorial() -> void:
	if _tutorial == null:
		return
	var m: TutorialLangkah.Masukan = TutorialLangkah.Masukan.new()
	m.kecepatan_ud = _sepeda.kecepatan_ud
	m.jumlah_lempar = _jumlah_lempar
	var t: RencanaMisi.Titik = MissionManager.titik_tampil(_keadaan_misi) if _keadaan_misi != null else null
	m.kucing_tangkap_terlihat = t != null and t.jenis == "tangkap"
	m.misi_berakhir = _keadaan_misi != null and _keadaan_misi.status != MissionManager.Status.AKTIF
	_tutorial = TutorialLangkah.langkah(_tutorial, m)
	_tutorial_node.tampilkan_langkah(_tutorial)


func _saat_lempar_diterima(_lintasan: ThrowSolver.Lintasan) -> void:
	_jumlah_lempar += 1


func _saat_tutorial_dilewati() -> void:
	if _tutorial == null:
		return
	_tutorial = TutorialLangkah.lewati(_tutorial)
	_tutorial_node.tampilkan_langkah(_tutorial)


## HUD dan kucing dari keadaan misi.
func _tampilkan_misi() -> void:
	var hud: HudRute = _hud as HudRute
	if hud != null:
		hud.tampilkan_misi(_keadaan_misi, _misi)
		var ukuran: Vector2 = get_viewport_rect().size
		var penanda: Array[TampilMisi.Penanda] = []
		if _keadaan_misi != null:
			penanda = TampilMisi.penanda_aktif(_keadaan_misi, TampilMisi.sepeda_layar(ukuran, geser_dorongan()), _sepeda.lateral_ubin, _sepeda.jarak_ubin, hud.area_misi(), ukuran.y)
		hud.tampilkan_penanda_kucing(penanda, _detik_misi)
	if _kucing == null:
		return
	var t: RencanaMisi.Titik = MissionManager.titik_tampil(_keadaan_misi) if _keadaan_misi != null else null
	if t == null:
		_kucing.sembunyikan()
		return
	var progres: float = _keadaan_misi.timer_detik / t.lama_berhenti_detik if t.jenis == "tangkap" and t.lama_berhenti_detik > 0.0 else 0.0
	var visual: Array = _misi.petunjuk.get("visual", [])
	_kucing.tampilkan(t, _sepeda.jarak_ubin, _detik_misi, progres, visual.has("kilau"), visual.has("ekor"))


## Tombol "Main lagi" layar hasil atau banner galat (juga dipanggil tes): seed berikutnya (seed + 1), rute baru dari awal.
func main_lagi() -> void:
	_susun(_benih + 1)
	perbarui(0.0)


## Mengatur seed rute awal (run fase4a-koran-hari AC-17: seed hari dari `SeedHari`). Dipanggil SEBELUM scene masuk pohon, jadi rute pertama
## sudah disusun dari seed ini (tanpa `main_lagi`); sesudah siap, rute disusun ulang dengan seed itu.
func atur_benih_awal(benih_baru: int) -> void:
	_benih = benih_baru
	if is_node_ready():
		_susun(benih_baru)
		perbarui(0.0)


## Mode hari: tombol layar hasil menjadi "Ke bengkel" (memancarkan `bengkel_diminta`), bukan "Main lagi". Bawaan mati (rute sendiri).
func atur_mode_hari(nilai: bool) -> void:
	_layar_hasil.atur_mode_hari(nilai)


## Seed rute yang sedang dimainkan.
func benih() -> int:
	return _benih


## Rute yang sedang dimainkan (rute kosong bila gagal disusun).
func rute() -> RouteBuilder.Rute:
	return _rute


## Galat memuat segmen atau menyusun rute (kosong bila baik).
func galat_rute() -> Array[String]:
	return _galat


## True sejak sepeda mencapai garis akhir sampai "Main lagi".
func rute_sudah_selesai() -> bool:
	return _selesai


## Jendela daur rumah (untuk tes dan probe).
func daur() -> RumahDaurRute:
	return _daur


## Gambar rintangan (untuk tes dan probe).
func rintangan_daur() -> RintanganDaur:
	return _rintangan_daur


## Gambar dekor pinggir jalan (untuk tes dan probe).
func dekor_daur() -> DekorDaur:
	return _dekor_daur


## Gambar umpan balik melayang (untuk tes dan probe).
func umpan_gambar() -> UmpanMelayangGambar:
	return _umpan_gambar


## Penerap penutup pemain (untuk tes dan probe).
func penerap_penutup() -> PenerapPenutup:
	return _penerap


## Panel banner dan tombol akhir rute (untuk tes dan probe).
func panel_akhir() -> PanelAkhirRute:
	return _panel_akhir


## Layar hasil (untuk tes dan probe).
func layar_hasil() -> LayarHasil:
	return _layar_hasil


## True sejak layar hasil terbuka sampai "Main lagi".
func hasil_tampil() -> bool:
	return _hasil_tampil


## Angka layar hasil terakhir (null sebelum terbuka).
func angka_hasil() -> HasilRute.Angka:
	return _angka_hasil


## Jam tenggat rute saat ini (untuk tes dan probe).
func tenggat() -> TenggatRute.Keadaan:
	return _tenggat


## Mengganti jam tenggat (hanya untuk tes dan probe: mis. tenggat hampir habis tanpa menunggu 90 detik).
func atur_tenggat(k: TenggatRute.Keadaan) -> void:
	_tenggat = k


## HUD rute final (untuk tes dan probe).
func hud_rute() -> HudRute:
	return _hud as HudRute


## Medan sasaran koran rute yang sedang dimainkan (untuk tes).
func medan() -> MedanKoran:
	return _medan


## Mengatur misi sampingan hari ini (null = tanpa misi). Dipanggil SEBELUM scene masuk pohon (`HariMain`), jadi rencana disusun saat rute disusun; bila sudah
## siap, rencana disusun ulang untuk rute yang sedang dimainkan.
func atur_misi(misi: DataMisi) -> void:
	_misi = misi
	if is_node_ready():
		_susun_misi()
		perbarui(0.0)


## Misi sampingan hari ini (null = tanpa misi).
func misi() -> DataMisi:
	return _misi


## Rencana misi rute ini (null = tanpa misi).
func rencana_misi() -> RencanaMisi.Rencana:
	return _rencana_misi


## Keadaan misi (null = tanpa misi).
func keadaan_misi() -> MissionManager.Keadaan:
	return _keadaan_misi


## Kucing misi (untuk tes dan probe).
func kucing() -> KucingMisi:
	return _kucing


## Mengatur sepeda awal rute dari save `state` (`sepeda.<komponen>.kondisi` dan `.level`; hilang = baru), hari yang dimainkan (seed kerusakan tabrakan), dan daftar upgrade yang sah
## (`PemuatToko.Kumpulan.upgrade`, untuk efek dan aus). Dipanggil SEBELUM scene masuk pohon (`HariMain`); bila sudah siap, kondisi rute diatur ulang ke awal.
func atur_sepeda(state: Dictionary, hari: int, daftar: Array[DataToko]) -> void:
	_sepeda_kondisi = Economy.kondisi_dari(state)
	_sepeda_level = Economy.level_dari(state)
	_sepeda_hari = hari
	_daftar_upgrade = daftar
	if is_node_ready():
		_kondisi = _kondisi_awal()
		_hud.tampilkan_kondisi(_kondisi)


## Kondisi sepeda akhir rute (id -> 0..1, dibulatkan 4 desimal seperti di save): kondisi awal bila rute belum berjalan.
func kondisi_akhir() -> Dictionary:
	var hasil: Dictionary = {}
	var sumber: Dictionary = _kondisi.kondisi if _kondisi != null else _sepeda_kondisi
	for id: String in Config.KONDISI_KOMPONEN:
		hasil[id] = BikeCondition.bulatkan(float(sumber.get(id, 1.0)))
	return hasil


## Menyalakan atau mematikan tutorial hari 1 (`HariMain`: hari pertama dan `tutorial.selesai` belum true). Dipanggil SEBELUM scene masuk pohon; bila sudah siap, tutorial
## disusun ulang. Bawaan mati (`rute.tscn` sendiri tanpa tutorial).
func atur_tutorial(aktif: bool) -> void:
	_tutorial_diminta = aktif
	if is_node_ready():
		_susun_tutorial()


## Keadaan tutorial (null = tanpa tutorial; untuk tes dan probe).
func keadaan_tutorial() -> TutorialLangkah.Keadaan:
	return _tutorial


## True bila tutorial berjalan hari ini (diminta dan keadaan dibuat), selesai atau belum: hari tutorial yang berakhir menulis `tutorial.selesai` (M-9).
func tutorial_dimulai() -> bool:
	return _tutorial != null and _tutorial.aktif


## Node tutorial (untuk tes dan probe).
func tutorial_node() -> TutorialController:
	return _tutorial_node


## Jumlah lemparan yang diterima sejak rute dimulai (untuk tes).
func jumlah_lempar() -> int:
	return _jumlah_lempar
