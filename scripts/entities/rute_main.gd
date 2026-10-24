class_name RuteMain
extends AdeganJalan
## Scene rute (run fase3a-rute bagian B, AC-10 sampai AC-16, usulan): satu rute perumahan dari segmen JSON, scene utama game.
##
## Memakai seluruh perilaku `AdeganJalan` (gerak, kamera, jeda, lemparan, mode bantu, bunyi, HUD) dan hanya mengisi kaitnya untuk rute:
## - Dunia (D-13): rute disusun `RouteBuilder.bangun(benih, pustaka)` dari segmen `PemuatRute.muat_folder`; seed bawaan
##   `Config.RUTE_SEED_DEV`, "Main lagi" memakai seed + 1. Rumah dan kotak surat digambar `RumahDaurRute` (jendela daur), tanah `TanahDaur`.
## - Penilaian koran dan mode bantu (AC-10): `MedanKoran.dari_rute` untuk penilaian dan garis bidik, `ZonaSasaran.zona_rute_rentang` untuk sasaran
##   mode bantu sejauh jangkauan lemparan. Koran awal = `rute.koran_awal` (30), tanpa isi ulang jalan uji.
## - Akhir rute (AC-14, `AkhirRute`; diubah run garis-finish-portal bagian C, G-2 sampai G-5): sepeda mencapai garis akhir (`panjang_ubin`) -> `rute_selesai` tepat sekali, tenggat berhenti,
##   stick sungguhan dan jari tidak dibaca lagi (`KontrolTouch` berhenti menerima sentuhan; stick buatan `AkhirRute.stick_keluar` lurus), laju dijaga minimal (`AkhirRute.keadaan_dijaga`),
##   lemparan, mode bantu, bel, dan tabrakan baru mati, kamera dan geseran dorongan beku di posisi garis akhir (`_bekukan_kamera`), dan tanah serta jendela daur dibekukan di jarak garis akhir
##   (`_jarak_dunia`): sepeda melaju keluar viewport lewat tepi kanan (`AkhirRute.periksa_keluar`). Banner `RUTE_SELESAI` tampil saat sepeda hampir keluar, bukan di garis; layar hasil terbuka
##   sesudah sepeda KELUAR dan semua koran mendarat (`HasilRute.siap_tampil`). Koran yang sudah terbang tetap mendarat dan dinilai. Portal satpam (`PortalGaris`) berdiri di garis akhir.
##   Jeda dan back tetap bekerja sepanjang fase keluar.
## - Penutup pemain (AC-15): SATU penerap (`PenerapPenutup`) memanggil `PenutupPemain` tiap langkah untuk semua rumah di jendela daur.
## - "Main lagi" (tombol layar hasil sejak run fase3c-hud-hasil, O-11; tombol banner hanya untuk galat muat): seed + 1, rute baru, sepeda,
##   sisa koran, koran terbang, skor, tenggat, radar, progres, rintangan, bel, dan oleng dikembalikan ke awal (`_susun`, `_kembalikan_awal`).
## - Tanpa area kotak surat di tanah (keputusan pemilik 2026-10-22, mengganti tindak lanjut uji HP 2026-10-16): persegi zona kotak surat
##   tidak digambar lagi karena membuat pemain mengira hanya area itu yang dinilai. Penilaian (`ZonaSasaran`, `MedanKoran`) tidak berubah.
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
##   - Layar hasil (`LayarHasil`, O-11): terbuka tepat sekali sesudah garis akhir, saat sepeda sudah keluar viewport dan tidak ada koran terbang
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
## Run fase5d-sisi-dekat bagian B (P-4, P-5, P-6; usulan, dinilai di HP): nomor hari (`atur_hari`, `HariMain` meneruskan `_mesin.hari` SEBELUM scene masuk pohon; bawaan hari 1 untuk `rute.tscn` yang dijalankan
## sendiri, probe, dan tes lama) masuk ke `RouteBuilder.bangun`: hari 1 dan 2 hanya pelanggan seberang (rute identik run sebelumnya), sejak hari 3 sebanyak 8 atau 9 dari 25 pelanggan di sisi dekat. Sasaran dekat
## (zona, kotak surat oranye/abu-abu, teras, mode bantu, radar, progres, skor) lewat kode yang sama dengan seberang. Hari 3: tip singkat sekali (`TipSisiDekat`, `PanelTipSisiDekat`, beku saat jeda).
##
## Run fase6a2-reputasi-pelanggan bagian A (O-7, AC-4, AC-6; usulan, tanpa tampilan): keadaan pelanggan tetap dari save (`atur_pelanggan`, dipanggil `HariMain` SEBELUM scene masuk pohon) diteruskan ke `RouteBuilder.bangun`.
## Saat layar hasil terbuka catatan pelanggan hari itu dan hasil `ReputationManager` (dari state save yang sama) disimpan dan bisa diambil (`catatan_pelanggan`, `hasil_reputasi`); `HariMain` memasukkan catatan itu ke
## `CatatanHari` saat "Hari berikutnya", jadi `DataSave.catat_hari` menerapkannya tepat sekali. Rute yang dijalankan sendiri (tanpa `atur_pelanggan`) tidak punya keadaan, catatan, atau hasil reputasi.
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
## Nomor hari rute (bawaan hari 1; `atur_hari`).
var _hari: int = Config.HARI_AWAL
## Sisa detik tip hari 3 (`TipSisiDekat`); diisi sekali saat rute pertama disusun dan tidak diisi ulang oleh "Main lagi".
var _tip_sisa: float = 0.0
var _tip_sudah: bool = false
var _rute: RouteBuilder.Rute = RouteBuilder.Rute.new()
## Hiasan lanjutan di depan garis akhir (`HiasanRute`, F-1): rute terpisah, hanya rumah bukan pelanggan dan dekor; tidak masuk radar, progres, zona, skor, atau `_rute`.
var _hiasan: RouteBuilder.Rute = RouteBuilder.Rute.new()
var _pustaka: Array[SegmenRute] = []
## Galat memuat segmen atau menyusun rute (kosong bila baik).
var _galat: Array[String] = []
## False hanya di tes yang sengaja memicu galat: galat tidak dicetak sebagai `ERROR:` ke log (pemeriksa keluaran tes menolak baris itu).
var lapor_galat_ke_log: bool = true
var _selesai: bool = false
## Fase sepeda terhadap garis akhir dan bendera "hampir keluar" (`AkhirRute.periksa_keluar`), dan jarak sepeda saat garis tercapai (jarak dunia yang dibekukan).
var _fase: AkhirRute.Fase = AkhirRute.Fase.SEBELUM
var _hampir_keluar: bool = false
var _jarak_beku: float = 0.0
## Stamina sepeda saat garis akhir tercapai (dipulihkan tiap langkah sesudah garis supaya keluar tidak menguras atau membuat lelah).
var _stamina_garis: float = Config.STAMINA_MAKS
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
## Keadaan pelanggan tetap rute ini (`atur_pelanggan`; null = rute tanpa keadaan), state save asalnya, dan pustaka kepribadian.
var _pelanggan_rute: PelangganRute = null
var _state_pelanggan: Dictionary = {}
var _kepribadian: Array[KepribadianPelanggan.Entri] = []
## Catatan pelanggan hari ini dan hasil reputasinya; diisi saat layar hasil terbuka (null sebelum itu, dan bila rute tanpa keadaan).
var _catatan_pelanggan: ReputationManager.Catatan = null
var _hasil_reputasi: ReputationManager.Hasil = null
## Ringkasan milestone hari ini (`MilestoneTracker.ringkas`: state save sebelum hari dan hasil `DataSave.catat_hari` tanpa belanja bengkel); diisi saat layar hasil terbuka, null bila rute tanpa keadaan.
var _hasil_milestone: MilestoneTracker.Ringkasan = null

@onready var _daur: RumahDaurRute = %Objek
@onready var _penerap: PenerapPenutup = %PenerapPenutup
@onready var _panel_akhir: PanelAkhirRute = %PanelAkhir
@onready var _rintangan_daur: RintanganDaur = %Rintangan
@onready var _dekor_daur: DekorDaur = %Dekor
@onready var _rumah_hiasan: RumahDaurRute = %RumahHiasan
@onready var _dekor_hiasan: DekorDaur = %DekorHiasan
@onready var _portal: PortalGaris = %Portal
@onready var _umpan_gambar: UmpanMelayangGambar = %UmpanMelayang
@onready var _layar_hasil: LayarHasil = %LayarHasil
@onready var _kucing: KucingMisi = %Kucing
@onready var _tutorial_node: TutorialController = %Tutorial
@onready var _tip_node: PanelTipSisiDekat = %TipSisiDekat


func _siapkan_dunia() -> void:
	_sepeda.umpan_balik().atur_sprite(true)
	_daur.penerap = _penerap
	_rintangan_daur.penerap = _penerap
	_dekor_daur.penerap = _penerap
	_rumah_hiasan.penerap = _penerap
	_dekor_hiasan.penerap = _penerap
	_portal.penerap = _penerap
	_kucing.penerap = _penerap
	_tutorial_node.lewati_diminta.connect(_saat_tutorial_dilewati)
	koran_dilempar.connect(_saat_lempar_diterima)
	_panel_akhir.main_lagi_diminta.connect(main_lagi)
	_layar_hasil.main_lagi_diminta.connect(main_lagi)
	_layar_hasil.bengkel_diminta.connect(bengkel_diminta.emit)
	_layar_hasil.atur_dunia(true)
	_susun(_benih)


func _perbarui_dunia(jarak_ubin: float) -> void:
	_langkah_misi(jarak_ubin)
	_langkah_tutorial()
	_daur.perbarui(jarak_ubin)
	_daur.atur_terantar(_skor.terantar)
	_rintangan_daur.perbarui(_rintangan, jarak_ubin)
	_dekor_daur.perbarui(jarak_ubin)
	_rumah_hiasan.perbarui(jarak_ubin)
	_dekor_hiasan.perbarui(jarak_ubin)
	_tip_node.tampilkan(TipSisiDekat.kunci_teks(_hari) if TipSisiDekat.tampil(_tip_sisa) and not _hasil_tampil else "")
	_umpan_gambar.tampilkan(_umpan)
	_penerap.terapkan(_sepeda.posisi_dunia())
	_portal.perbarui(_sepeda.jarak_ubin)
	var status: AkhirRute.Status = AkhirRute.periksa(_selesai, jarak_ubin, _rute.panjang_ubin)
	_selesai = status.selesai
	if status.baru_selesai:
		_jarak_beku = jarak_ubin
		_stamina_garis = _sepeda.stamina()
		_tenggat = TenggatRute.hentikan(_tenggat)
		_kontrol.lepas_semua()
		# Sesudah garis akhir stick dan jari tidak dibaca lagi (jempol yang masih menahan tidak membelokkan atau mengerem), dan tidak ada lemparan atau ketukan baru.
		_kontrol.set_process_input(false)
		_garis_bidik.sembunyikan()
		_bekukan_kamera()
		rute_selesai.emit()
	var ukuran: Vector2 = get_viewport_rect().size
	var keluar: AkhirRute.Keluar = AkhirRute.periksa_keluar(_fase, _hampir_keluar, _selesai, AkhirRute.posisi_layar(_sepeda.position, _kamera.position, ukuran), ukuran)
	_fase = keluar.fase
	_hampir_keluar = keluar.hampir_keluar
	if keluar.baru_hampir_keluar:
		_panel_akhir.tampilkan(true)
	_perbarui_hud_rute(jarak_ubin)
	if _selesai and not _hasil_tampil and HasilRute.siap_tampil(_selesai, _fase == AkhirRute.Fase.SUDAH_KELUAR, koran_terbang()):
		_buka_hasil()


## HUD rute final dari keadaan murni (hanya menampilkan).
func _perbarui_hud_rute(jarak_ubin: float) -> void:
	var hud: HudRute = _hud as HudRute
	if hud == null:
		return
	var lewat: bool = TenggatRute.lewat(_tenggat)
	hud.tampilkan_reputasi(ReputationManager.reputasi_di(_state_pelanggan, Config.DISTRIK_AWAL) if _pelanggan_rute != null else -1)
	hud.tampilkan_tenggat(_tenggat)
	hud.tampilkan_radar(RadarRute.penanda(_rute, jarak_ubin, _skor.terantar, mode_bantu(), lewat))
	hud.tampilkan_progres(ProgresRute.status(_rute, jarak_ubin, _skor.terantar, _selesai), ProgresRute.jumlah_terkirim(_rute, _skor.terantar), _rute.pelanggan.size())


## Membuka layar hasil (tepat sekali per rute): angka dari `HasilRute`, banner dan HUD disembunyikan, kontrol sentuh berhenti membaca.
func _buka_hasil() -> void:
	_hasil_tampil = true
	_angka_hasil = HasilRute.dari(_skor, _rute, _tenggat, _keadaan_misi)
	var perlu: Array[String] = BikeCondition.perlu_bengkel(_kondisi.kondisi) if _kondisi != null else []
	if _pelanggan_rute != null:
		_catatan_pelanggan = ReputationManager.catat(_rute, _skor, _hari, _misi, _keadaan_misi)
		_hasil_reputasi = ReputationManager.terapkan(_state_pelanggan, _catatan_pelanggan, _kepribadian)
		_hasil_milestone = MilestoneTracker.ringkas(_state_pelanggan, _state_sesudah_hari())
	var saldo_lama: int = int(_state_pelanggan["koin"]) if _state_pelanggan.has("koin") else -1
	_layar_hasil.isi(_angka_hasil, _misi if _keadaan_misi != null else null, perlu, saldo_lama, _hasil_reputasi, _hasil_milestone)
	if _audio != null and _hasil_milestone != null and BunyiMilestone.berbunyi(_hasil_milestone.baru.size()):
		_audio.putar_milestone()
	_layar_hasil.tampilkan(true)
	_panel_akhir.tampilkan(false)
	_hud.visible = false
	_tutorial_node.visible = false
	_atur_lapisan_dunia_tampil(false)
	_kontrol.lepas_semua()
	_kontrol.set_process_input(false)
	hasil_dibuka.emit(_angka_hasil)


## Layar hasil kini di atas dunia yang tembus pandang (V-10): selain HUD dan tutorial (disembunyikan di `_buka_hasil`), lapisan kontrol sentuh (stick, tanda "tidak ada sasaran") dan umpan melayang ("+15", TEPAT) tidak boleh
## tembus di baliknya. `tampil` false saat layar hasil terbuka, true lagi sesudah "Main lagi". Hanya mengubah `visible`, tanpa pemrosesan per frame.
func _atur_lapisan_dunia_tampil(tampil: bool) -> void:
	_umpan_gambar.visible = tampil
	(_kontrol.get_parent() as CanvasLayer).visible = tampil
	if not tampil:
		_tip_node.tampilkan("")


## State save sesudah hari ini (pratinjau murni `DataSave.catat_hari` dari state awal dan catatan hari ini, tanpa belanja bengkel dan tanpa menulis apa pun): dasar progres milestone di layar hasil.
func _state_sesudah_hari() -> Dictionary:
	var catatan: DataSave.CatatanHari = DataSave.CatatanHari.new()
	catatan.hari = _hari
	catatan.angka = _angka_hasil
	catatan.pelanggan = _catatan_pelanggan
	catatan.kepribadian = _kepribadian
	return DataSave.catat_hari(_state_pelanggan, catatan)


func _langkah_waktu(langkah_dt: float) -> void:
	_dt_langkah = langkah_dt
	_tip_sisa = TipSisiDekat.sisa(_tip_sisa, langkah_dt)
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
		return AkhirRute.stick_keluar()
	return super()


## Sesudah garis akhir laju dinaikkan ke laju minimum (level ngebut), lelah dipadamkan, dan stamina dikembalikan ke nilai di garis sebelum langkah gerak (`AkhirRute.keadaan_dijaga`); sebelum garis tidak ada yang berubah.
func _siapkan_gerak() -> void:
	if _selesai:
		_sepeda.keadaan = AkhirRute.keadaan_dijaga(_sepeda.keadaan, _stamina_garis)


## Efek kondisi sepeda tidak berlaku sesudah garis akhir (Bagian F, F-3): sepeda keluar dengan cepat walau aus atau rusak; kondisi sudah dibekukan di garis (G-5).
func _efek_gerak() -> EfekKondisi:
	return null if _selesai else super()


## Tanah dan dunia di garis akhir dibekukan di jarak saat garis tercapai (G-5): kamera beku melihat persis yang sama dengan frame sebelum beku, tanpa lubang di belakang portal.
func _jarak_dunia() -> float:
	return _jarak_beku if _selesai else _sepeda.jarak_ubin


func _rintangan_aktif() -> bool:
	return not _selesai


func _bel_diizinkan() -> bool:
	return not _selesai


func _sepeda_senyap() -> bool:
	return _hasil_tampil


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
	var hasil: RouteBuilder.Hasil = RouteBuilder.bangun(benih, _pustaka, _hari, _pelanggan_rute)
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
	_fase = AkhirRute.Fase.SEBELUM
	_hampir_keluar = false
	_jarak_beku = 0.0
	_stamina_garis = Config.STAMINA_MAKS
	_tenggat = TenggatRute.awal(_rute.panjang_ubin)
	_hasil_tampil = false
	_angka_hasil = null
	_catatan_pelanggan = null
	_hasil_reputasi = null
	_hasil_milestone = null
	_layar_hasil.tampilkan(false)
	_hud.visible = true
	_tutorial_node.visible = true
	_atur_lapisan_dunia_tampil(true)
	if not _tip_sudah:
		_tip_sudah = true
		_tip_sisa = TipSisiDekat.detik_awal(_hari)
	_kontrol.set_process_input(true)
	_daur.atur_rute(_rute)
	_tanah.atur_baris_masuk(UbinKhusus.himpunan_baris_masuk(_rute.objek))
	_tanah.atur_simpang(UbinKhusus.himpunan_baris_simpang(RouteBuilder.simpang_di(_rute)))
	_rintangan_daur.lepas_semua()
	_dekor_daur.atur_rute(_rute)
	_hiasan = HiasanRute.bangun(_rute, _pustaka) if not gagal else RouteBuilder.Rute.new()
	_rumah_hiasan.atur_rute(_hiasan)
	_dekor_hiasan.atur_rute(_hiasan)
	_portal.atur_rute(_rute.panjang_ubin)
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
	if _tutorial == null or _selesai:
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
			penanda = TampilMisi.penanda_aktif(_keadaan_misi, TampilMisi.sepeda_layar(ukuran, geser_dorongan()), _sepeda.lateral_ubin, _jarak_dunia(), hud.area_misi(), ukuran.y)
		hud.tampilkan_penanda_kucing(penanda, _detik_misi)
	if _kucing == null:
		return
	var t: RencanaMisi.Titik = MissionManager.titik_tampil(_keadaan_misi) if _keadaan_misi != null else null
	if t == null:
		_kucing.sembunyikan()
		return
	var progres: float = _keadaan_misi.timer_detik / t.lama_berhenti_detik if t.jenis == "tangkap" and t.lama_berhenti_detik > 0.0 else 0.0
	var visual: Array = _misi.petunjuk.get("visual", [])
	_kucing.tampilkan(t, _jarak_dunia(), _detik_misi, progres, visual.has("kilau"), visual.has("ekor"))


## Tombol "Main lagi" layar hasil atau banner galat (juga dipanggil tes): seed berikutnya (seed + 1), rute baru dari awal.
func main_lagi() -> void:
	_susun(_benih + 1)
	perbarui(0.0)


## Mengatur nomor hari rute (run fase5d-sisi-dekat bagian B, AC-8): menentukan pelanggan sisi dekat (sejak `Config.RUTE_DEKAT_HARI_MULAI`) dan tip hari 3. Dipanggil SEBELUM scene masuk pohon (`HariMain`); bila sudah
## siap, rute disusun ulang dengan seed yang sedang dipakai. Bawaan hari 1.
func atur_hari(hari_baru: int) -> void:
	_hari = hari_baru
	if is_node_ready():
		_tip_sudah = false
		_susun(_benih)
		perbarui(0.0)


## Mengatur keadaan pelanggan tetap dari state save `state` (`pelanggan`) dan pustaka kepribadian `kepribadian` (kosong = dimuat `PemuatPelanggan`). Dipanggil SEBELUM scene masuk pohon (`HariMain`);
## bila sudah siap, rute disusun ulang dengan seed yang sedang dipakai. Tanpa panggilan ini rute disusun tanpa keadaan (perilaku sebelum run fase6a2).
func atur_pelanggan(state: Dictionary, kepribadian: Array[KepribadianPelanggan.Entri] = []) -> void:
	_state_pelanggan = state.duplicate(true)
	_kepribadian = kepribadian if not kepribadian.is_empty() else PemuatPelanggan.muat().entri
	_pelanggan_rute = PelangganRute.dari_state(_state_pelanggan, _kepribadian)
	if is_node_ready():
		_susun(_benih)
		perbarui(0.0)


## Keadaan pelanggan rute ini (null = tanpa keadaan).
func pelanggan_rute() -> PelangganRute:
	return _pelanggan_rute


## Catatan pelanggan hari ini (null sebelum layar hasil terbuka atau bila rute tanpa keadaan).
func catatan_pelanggan() -> ReputationManager.Catatan:
	return _catatan_pelanggan


## Hasil `ReputationManager` hari ini (null sebelum layar hasil terbuka atau bila rute tanpa keadaan); sama dengan yang diterapkan `DataSave.catat_hari`.
func hasil_reputasi() -> ReputationManager.Hasil:
	return _hasil_reputasi


## Ringkasan milestone hari ini (null sebelum layar hasil terbuka atau bila rute tanpa keadaan).
func hasil_milestone() -> MilestoneTracker.Ringkasan:
	return _hasil_milestone


## Nomor hari rute (bawaan hari 1).
func hari() -> int:
	return _hari


## Sisa detik tip hari 3 (untuk tes dan probe).
func sisa_tip() -> float:
	return _tip_sisa


## Panel tip hari 3 (untuk tes dan probe).
func tip_node() -> PanelTipSisiDekat:
	return _tip_node


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


## Fase sepeda terhadap garis akhir (`AkhirRute.Fase`; untuk tes dan probe).
func fase_keluar() -> AkhirRute.Fase:
	return _fase


## True sejak sepeda hampir keluar viewport (banner "Rute selesai" muncul) sampai "Main lagi".
func hampir_keluar() -> bool:
	return _hampir_keluar


## Jarak maju tempat tanah dan dunia dibekukan: jarak sepeda saat garis akhir tercapai (0 sebelum itu).
func jarak_beku() -> float:
	return _jarak_beku


## Portal satpam di garis akhir (untuk tes dan probe).
func portal() -> PortalGaris:
	return _portal


## Jendela daur rumah (untuk tes dan probe).
func daur() -> RumahDaurRute:
	return _daur


## Gambar rintangan (untuk tes dan probe).
func rintangan_daur() -> RintanganDaur:
	return _rintangan_daur


## Gambar dekor pinggir jalan (untuk tes dan probe).
func dekor_daur() -> DekorDaur:
	return _dekor_daur


## Rute hiasan di depan garis akhir (untuk tes dan probe).
func hiasan() -> RouteBuilder.Rute:
	return _hiasan


## Banyaknya gambar hiasan yang terdaftar di penerap penutup: semua rumah hiasan yang tergambar dan dekor hiasan yang menutupi (sisi dekat). Untuk tes.
func jumlah_hiasan_penerap() -> int:
	var jumlah: int = _rumah_hiasan.jumlah_rumah()
	for indeks: int in _dekor_hiasan.indeks_tampil():
		var butir: RouteBuilder.DekorItem = _hiasan.dekor[indeks]
		if DekorRute.menutupi(butir.jenis, butir.varian, butir.sisi):
			jumlah += 1
	return jumlah


## Gambar rumah hiasan (untuk tes dan probe).
func rumah_hiasan() -> RumahDaurRute:
	return _rumah_hiasan


## Gambar dekor hiasan (untuk tes dan probe).
func dekor_hiasan() -> DekorDaur:
	return _dekor_hiasan


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
