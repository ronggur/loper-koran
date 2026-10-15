class_name JalanUji
extends Node2D
## Scene uji (Fase 0 AC-11, Fase 1 run 1A): jalan lurus tanpa ujung, sepeda digerakkan stick, HUD sementara.
##
## Akar tipis: tiap `_process` memberi vektor stick (sentuhan, atau keyboard di editor) ke `SepedaUji`, lalu
## menggeser tanah dan objek berkala, kamera, dan HUD. Kamera mengikuti sepeda penuh (posisi dibulatkan ke piksel)
## dengan sepeda di sepertiga kiri layar (ART_DIRECTION 2.2) dan tanpa zoom, ditambah dorongan kecepatan (GDD 15):
## saat ngebut sepeda bergeser maju sedikit di bingkai, saat melambat mundur sedikit, dihaluskan eksponensial. Geseran
## hanya menggeser kamera (`DoronganKecepatan`); posisi dunia dan posisi sprite sepeda serta HUD tidak berubah. Gerak
## halus tetap float di `SepedaUji`; hanya posisi gambar yang dibulatkan. Stamina dan rem tampil di HUD dan cincin stick.
##
## Lemparan koran (run fase2a-lemparan bagian 1b, arah bebas run fase2-arah-bebas): SATU fungsi `lintasan_swipe` (`ThrowSolver.dari_swipe`
## dari posisi sepeda, kecepatan maju sebenarnya, kecepatan lateral efektif langkah terakhir, dan jeda lepas animasi) dipakai garis bidik
## tiap langkah (sesudah sepeda digerakkan). Koran terbang ke arah swipe seperti terlihat di layar (arah tanah dari `Iso`), panjang |v|
## menentukan kekuatan, dan tidak ada sudut yang ditolak. Saat jari dilepas (D-5 run fase2-arah-bebas), lemparan memakai OBJEK lintasan
## garis bidik yang sedang tampil untuk swipe itu (dibekukan pada langkah terakhir), bukan menghitung ulang dari posisi lepas: jari yang
## masih bergerak atau berbelok ke arah mana pun saat diangkat (flick) tidak membatalkan lemparan dan tidak mengubah titik mendarat, jadi
## koran mendarat tepat di elips terakhir yang terlihat (QA-001 Run 2A). Lemparan batal HANYA bila panjang swipe di posisi lepas |v_lepas|
## di bawah min (jari ditarik kembali ke dekat titik awal): tidak ada koran, jadi tidak ada hasil yang berbeda dari prediksi. Bila tidak
## ada garis bidik yang tampil untuk swipe itu (swipe turun dan naik di antara dua langkah, atau langkah terakhir menolak swipe karena
## masih pendek), lemparan dihitung dari posisi lepas dengan `lintasan_swipe` yang sama dan keadaan sepeda yang sama (keadaan langkah
## terakhir): tidak ada prediksi tampil yang bisa berbeda. Lemparan diterima bila `SisaKoran` mengizinkan (koran ada, jeda antar lempar
## 0,35 detik lewat; D-8, D-9): koran berkurang tepat 1, animasi lempar dimulai ke sisi lintasan (`ThrowSolver.sisi_dari_arah`), dan
## `KoranLempar` membekukan lintasannya. Koran terbang, mendarat, dinilai zona dari titik mendarat saja (`ZonaSasaran`), dan penandanya
## tampil sesuai waktu langkah (`dt` efektif), digambar `KoranGambar` (bayangan di tanah, koran dan penanda di atas objek). Garis bidik
## (`GarisBidik`, D-5 Run 2A) hanya tampil selama swipe ditahan, |v| cukup, dan lempar diizinkan. Isi ulang koran khusus jalan uji
## (`SisaKoran.isi_ulang_jalan_uji`, alat uji). Zona placeholder digambar `ZonaGambar` di bawah objek dunia.
##
## Jeda (D-6 run fase1b-umpan-balik, `JedaSim`): tombol jeda di HUD, app di-background atau kehilangan fokus (PAUSED, FOCUS_OUT), dan
## tombol back Android saat berjalan membuka **layar jeda** (`LayarJeda`). Tidak ada lanjut otomatis: RESUMED dan FOCUS_IN tidak
## mengubah apa pun; pemain melanjutkan lewat tombol "Lanjut" atau back saat layar jeda terbuka. Selama jeda `SceneTree.paused`
## menyala, jadi sprite pemain, partikel umpan balik, dan input stick dan swipe berhenti; bunyi sepeda dihentikan `Audio` lewat
## `jeda_berubah` (lihat bawah); hanya layar jeda (`PROCESS_MODE_WHEN_PAUSED`) yang menerima sentuhan. `perbarui` tetap boleh dipanggil tetapi
## memakai `dt` 0, jadi kecepatan, jarak, stamina, lama tahan rem, dan geseran dorongan tidak berubah; saat menjeda stick dan swipe
## dilepas, lempar ditutup, dan lama tahan rem kembali 0 (`SepedaUji.jeda`). Langkah pertama sesudah lanjut ber-`dt` 0.
## Koran yang sudah diterima tidak hilang karena jeda (D-11): waktunya ikut `dt` efektif, jadi koran terbang, jeda antar lempar, penanda,
## dan isi ulang membeku selama jeda dan lanjut tanpa lompatan; jeda di antara jari dilepas dan frame lepas hanya menutup animasi.
## Titik kait untuk node lain: sinyal `jeda_berubah` dan `sedang_jeda()`.
##
## Mode bantu (GDD 5.3; K-1 sampai K-4, D-1 sampai D-7 run fase2b-bantu-audio, usulan): sakelar di HUD (`HudDev.bantu_diubah`, bawaan
## mati, tidak disimpan). Saat menyala, TAP di zona swipe (`TouchRouter.tap_selesai`, posisi = titik awal sentuhan) melempar otomatis:
## sisi dari posisi tap terhadap garis jalan yang melewati sepeda di layar (`BantuLempar.sisi_tap`, `posisi_layar_sepeda`), sasaran =
## kotak surat pelanggan terdekat di depan pada sisi itu (`BantuLempar.pilih` atas zona jalan uji sejauh jangkauan lemparan), lintasan =
## keluaran `ThrowSolver.hitung` dari keadaan sepeda langkah terakhir, dibekukan saat tap diterima (tanpa garis bidik; elips pendaratan
## dan penanda tetap). Gerbangnya sama dengan swipe (tidak jeda, `SisaKoran.boleh_lempar`, `SisaKoran.terima`) dan langkah sesudahnya juga
## sama (`_lempar`: koran terbang, animasi, HUD, sinyal `koran_dilempar`). Tap yang ditolak karena tidak ada sasaran tidak memakai koran
## dan tidak memulai jeda; tanda kecil tampil di titik tap (`KontrolTouch.tampilkan_tanda`, D-6). Ditolak karena habis atau jeda antar
## lempar = tidak ada tanda (HUD koran sudah memberi tanda HABIS). Swipe manual tetap melempar seperti biasa di mode bantu. Kecepatan
## otomatis (K-1) = perilaku stick netral (santai 3,0 u/d, tidak menguras stamina); stick tetap aktif penuh.
##
## Bunyi lempar dan mendarat (D-10 sampai D-12 run fase2b-bantu-audio): `koran_dilempar` dipancarkan tepat sekali per lemparan yang
## DITERIMA, swipe maupun tap (lemparan ditolak tidak memancarkannya), dan disambungkan ke `Audio.putar_lempar` ("wus"; pasangan visualnya
## garis bidik hilang dan koran muncul). `koran_mendarat` tepat sekali per koran pada langkah ia mendarat, disambungkan ke
## `Audio.putar_mendarat` dengan hasil koran itu dan sakelar jendela yang sama dengan penilaiannya (pasangan visualnya penanda di titik
## mendarat). `jeda_berubah` menghentikan bunyi lempar/mendarat yang sedang berbunyi lewat `Audio.atur_jeda`.
##
## Bunyi sepeda (D-3, D-5): tiap langkah keadaan sebenarnya (pose, kecepatan, rem, jeda) diberikan ke autoload `Audio` (`/root/Audio`,
## dicari lewat jalur node, bukan nama global, supaya scene tetap jalan tanpa autoload); `jeda_berubah` disambungkan ke
## `Audio.atur_jeda` (semua bunyi sepeda berhenti saat jeda, tanpa decit rem tertunda), dan keluar dari pohon menghentikannya.

## Status jeda berubah: true = layar jeda dibuka (simulasi, sprite, partikel, dan input berhenti), false = lanjut.
signal jeda_berubah(jeda: bool)
## Lemparan diterima (jari swipe dilepas atau tap mode bantu diterima, koran berkurang 1): lintasan beku koran itu. Tepat sekali per
## koran yang benar-benar terpakai.
signal koran_dilempar(lintasan: ThrowSolver.Lintasan)
## Tap mode bantu ditolak karena tidak ada kotak surat terjangkau (D-6): titik tap, koordinat viewport game.
signal bantu_tanpa_sasaran(posisi: Vector2)
## Koran mendarat dan sudah dinilai (`KoranLempar.Koran`: hasil, antaran, penanda).
signal koran_mendarat(koran: KoranLempar.Koran)

## Skrip autoload `Audio`, hanya untuk tipe (`Audio` tidak merujuk autoload lain, rule `gdscript`).
const SKRIP_AUDIO := preload("res://scripts/autoload/audio.gd")

## Geseran sepeda di layar akibat dorongan kecepatan yang sudah dihaluskan, piksel game.
var _geser_dorongan: Vector2 = Vector2.ZERO
## True selama layar jeda terbuka (`JedaSim`).
var _jeda: bool = false
## True bila langkah berikutnya adalah langkah pertama sesudah lanjut (memakai dt 0).
var _baru_lanjut: bool = false
## Autoload `Audio` bila terdaftar (null bila scene dijalankan tanpa autoload).
var _audio: SKRIP_AUDIO = null
## Sisa koran dan jeda antar lempar (`SisaKoran`). Publik untuk tes; diganti objek baru tiap perubahan.
var koran: SisaKoran.Keadaan = SisaKoran.awal(Config.KORAN_AWAL)
## Koran yang sudah dilempar dan belum selesai (terbang, atau penandanya masih tampil).
var _terbang: Array[KoranLempar.Koran] = []
## Nomor swipe (`TouchRouter.nomor_swipe`) yang garis bidiknya sedang tampil; -1 bila belum ada.
var _bidik_nomor: int = -1
## True selama mode bantu menyala (D-7; bawaan mati, tidak disimpan).
var _mode_bantu: bool = false

@onready var _kamera: Camera2D = %Kamera
@onready var _tanah: TanahDaur = %Tanah
@onready var _objek: ObjekDaur = %Objek
@onready var _sepeda: SepedaUji = %Sepeda
@onready var _kontrol: KontrolTouch = %KontrolTouch
@onready var _hud: HudDev = %Hud
@onready var _layar_jeda: LayarJeda = %LayarJeda
@onready var _zona: ZonaGambar = %Zona
@onready var _koran_tanah: KoranGambar = %KoranTanah
@onready var _koran_udara: KoranGambar = %KoranUdara
@onready var _garis_bidik: GarisBidik = %GarisBidik


func _ready() -> void:
	_hud.kidal_diubah.connect(_kontrol.atur_kidal)
	_hud.jeda_diminta.connect(minta_jeda)
	_hud.bantu_diubah.connect(atur_mode_bantu)
	_layar_jeda.lanjut_diminta.connect(minta_lanjut)
	_kontrol.router.swipe_selesai.connect(_saat_swipe_selesai)
	_kontrol.router.tap_selesai.connect(_saat_tap_selesai)
	_layar_jeda.tampilkan(false)
	_audio = get_node_or_null(^"/root/Audio") as SKRIP_AUDIO
	if _audio != null:
		jeda_berubah.connect(_audio.atur_jeda)
		koran_dilempar.connect(_bunyi_lempar)
		koran_mendarat.connect(_bunyi_mendarat)
	perbarui(0.0)


func _notification(what: int) -> void:
	_terapkan_jeda(JedaSim.peristiwa_dari_notifikasi(what))


func _exit_tree() -> void:
	# Scene keluar saat dijeda (mis. ganti scene atau tes selesai): pause pohon dilepas supaya tidak menahan scene lain.
	if _jeda:
		get_tree().paused = false
	if _audio != null:
		_audio.hentikan_sepeda()
		_audio.hentikan_lempar()


## Lemparan diterima: satu "wus" lewat `Audio` (D-11).
func _bunyi_lempar(_lintasan: ThrowSolver.Lintasan) -> void:
	_audio.putar_lempar()


## Koran mendarat: satu bunyi permukaan lewat `Audio`, dengan sakelar jendela yang sama dengan penilaian koran (D-10, D-11).
func _bunyi_mendarat(koran_mendarat_ini: KoranLempar.Koran) -> void:
	_audio.putar_mendarat(koran_mendarat_ini.hasil, Config.JENDELA_KENA_BONUS)


## Tombol jeda di HUD: membuka layar jeda (tidak berpengaruh bila sudah jeda).
func minta_jeda() -> void:
	_terapkan_jeda(JedaSim.Peristiwa.JEDA)


## Tombol "Lanjut" di layar jeda: menutup layar jeda dan melanjutkan (langkah pertama ber-`dt` 0).
func minta_lanjut() -> void:
	_terapkan_jeda(JedaSim.Peristiwa.LANJUT)


## Menerapkan satu peristiwa jeda. Saat menjeda (juga bila sudah jeda): sepeda dijeda, jari dilepas, cincin rem padam. Saat status
## berubah: layar jeda tampil atau hilang, `SceneTree.paused` mengikuti, dan `jeda_berubah` dipancarkan.
func _terapkan_jeda(peristiwa: JedaSim.Peristiwa) -> void:
	if peristiwa == JedaSim.Peristiwa.TIDAK_ADA or not is_node_ready():
		return
	var jeda_baru: bool = JedaSim.jeda_sesudah(_jeda, peristiwa)
	_baru_lanjut = JedaSim.baru_lanjut_sesudah(_jeda, _baru_lanjut, peristiwa)
	var berubah: bool = jeda_baru != _jeda
	_jeda = jeda_baru
	if _jeda:
		_sepeda.jeda()
		_kontrol.lepas_semua()
		_kontrol.atur_rem(false)
		_garis_bidik.sembunyikan()
	if not berubah:
		return
	_layar_jeda.tampilkan(_jeda)
	if is_inside_tree():
		get_tree().paused = _jeda
	jeda_berubah.emit(_jeda)


func _process(delta: float) -> void:
	perbarui(minf(delta, Config.LANGKAH_WAKTU_MAKS_DETIK))


## Lintasan koran untuk swipe dari `awal` ke `akhir` (piksel game) dengan keadaan sepeda SAAT INI, atau null bila swipe tidak melempar.
## Satu-satunya panggilan lintasan di scene: garis bidik tiap langkah dan lemparan saat jari dilepas (D-4).
func lintasan_swipe(awal: Vector2, akhir: Vector2) -> ThrowSolver.Lintasan:
	var lebar: float = get_viewport_rect().size.x
	var sisi: LoperAnim.Sisi = ThrowSolver.sisi_dari_swipe(awal, akhir, lebar)
	if sisi == LoperAnim.Sisi.TIDAK_ADA:
		return null
	return ThrowSolver.dari_swipe(awal, akhir, lebar, _sepeda.posisi_dunia(), _sepeda.kecepatan_ud, _sepeda.lateral_ud, _sepeda.jeda_lepas(sisi))


## Satu swipe selesai (jari dilepas): lempar bila diizinkan (D-8, D-9) dan panjang swipe di posisi lepas |v_lepas| >= min (D-5 run
## fase2-arah-bebas; arah posisi lepas tidak menentukan apa pun). Lintasan = garis bidik yang sedang tampil untuk swipe ini
## (`lintasan_bidik_tampil`); tanpa garis bidik tampil, dihitung dari posisi lepas. Ditolak = koran tidak berkurang dan jeda tidak mulai
## ulang. Garis bidik selalu hilang saat jari dilepas.
func _saat_swipe_selesai(awal: Vector2, akhir: Vector2, _durasi_detik: float) -> void:
	var bidik: ThrowSolver.Lintasan = lintasan_bidik_tampil(_kontrol.router.nomor_swipe)
	_garis_bidik.sembunyikan()
	if _jeda or not SisaKoran.boleh_lempar(koran):
		return
	if not ThrowSolver.cukup_panjang(ThrowSolver.panjang_swipe(awal, akhir), get_viewport_rect().size.x):
		return
	var lintasan: ThrowSolver.Lintasan = bidik if bidik != null else lintasan_swipe(awal, akhir)
	if lintasan == null:
		return
	_lempar(lintasan)


## Satu tap di zona swipe selesai (D-1): di mode bantu, lempar otomatis ke kotak surat pelanggan terdekat di depan pada sisi tap (D-3 sampai
## D-6). Di luar mode bantu tidak melakukan apa pun. Gerbang sama dengan swipe; tanpa sasaran = tanda di titik tap, koran dan jeda tetap.
func _saat_tap_selesai(posisi: Vector2, _durasi_detik: float) -> void:
	if not _mode_bantu or _jeda or not SisaKoran.boleh_lempar(koran):
		return
	var pilihan: BantuLempar.Pilihan = pilihan_bantu(BantuLempar.sisi_tap(posisi, posisi_layar_sepeda()))
	if pilihan == null:
		_kontrol.tampilkan_tanda(posisi)
		bantu_tanpa_sasaran.emit(posisi)
		return
	_lempar(pilihan.lintasan)


## Gerbang terakhir dan langkah sesudahnya, sama untuk swipe dan tap (D-5): `SisaKoran.terima`; diterima = koran -1, koran terbang dengan
## lintasan beku, animasi lempar ke sisi lintasan, HUD, dan `koran_dilempar`. Ditolak = tidak ada yang berubah. True bila diterima.
func _lempar(lintasan: ThrowSolver.Lintasan) -> bool:
	var hasil: SisaKoran.Hasil = SisaKoran.terima(koran, _sepeda.jarak_ubin)
	koran = hasil.keadaan
	if not hasil.diterima:
		return false
	_terbang.append(KoranLempar.baru(lintasan))
	_sepeda.lempar(lintasan.sisi)
	_hud.tampilkan_koran(koran.sisa, koran.penuh)
	koran_dilempar.emit(lintasan)
	return true


## Sasaran lemparan mode bantu untuk tap ke `sisi` dari keadaan sepeda langkah terakhir (posisi dunia, kecepatan maju sebenarnya, kecepatan
## lateral efektif, jeda lepas animasi sisi itu), atas zona jalan uji dari posisi sepeda sampai jangkauan lemparan; null bila tidak ada.
func pilihan_bantu(sisi: LoperAnim.Sisi) -> BantuLempar.Pilihan:
	if sisi == LoperAnim.Sisi.TIDAK_ADA:
		return null
	var posisi: Vector2 = _sepeda.posisi_dunia()
	var jeda_lepas: float = _sepeda.jeda_lepas(sisi)
	var maju: float = -posisi.y
	var zona: Array[ZonaSasaran.Zona] = ZonaSasaran.zona_jalan_uji_rentang(maju, maju + BantuLempar.jangkauan_maju_ubin(_sepeda.kecepatan_ud, jeda_lepas))
	return BantuLempar.pilih(sisi, posisi, _sepeda.kecepatan_ud, _sepeda.lateral_ud, jeda_lepas, get_viewport_rect().size.x, zona)


## Titik pijak sepeda di layar, koordinat viewport game (sama dengan koordinat sentuhan): posisi gambar sepeda dikurangi pojok kiri atas
## kamera (kamera di tengah layar, tanpa zoom). Garis pemisah sisi tap mode bantu melewati titik ini (D-3).
func posisi_layar_sepeda() -> Vector2:
	return _sepeda.global_position - _kamera.position + get_viewport_rect().size / 2


## Menyalakan atau mematikan mode bantu (sakelar HUD, D-7). Tombol HUD ikut disamakan.
func atur_mode_bantu(nilai: bool) -> void:
	_mode_bantu = nilai
	_hud.atur_bantu(nilai)


## True selama mode bantu menyala.
func mode_bantu() -> bool:
	return _mode_bantu


## Lintasan garis bidik yang sedang tampil bila dihitung untuk swipe bernomor `nomor` (`TouchRouter.nomor_swipe`), atau null (tidak
## tampil, atau sisa garis bidik swipe lain yang dibatalkan sebelum langkah berikutnya menyembunyikannya).
func lintasan_bidik_tampil(nomor: int) -> ThrowSolver.Lintasan:
	if not _garis_bidik.tampil() or _bidik_nomor != nomor:
		return null
	return _garis_bidik.lintasan()


## Koran yang sedang dilempar (terbang atau penandanya masih tampil), urut dari yang pertama dilempar. Untuk tes dan probe.
func koran_terbang() -> Array[KoranLempar.Koran]:
	return _terbang


## Garis bidik di ruang dunia (untuk tes dan probe).
func garis_bidik() -> GarisBidik:
	return _garis_bidik


## Satu langkah permainan selama `dt` detik. Publik supaya tes terpadu bisa menjalankannya tanpa menunggu frame. Selama jeda
## dan pada langkah pertama sesudah lanjut `dt` diganti 0 (`JedaSim.dt_efektif`).
func perbarui(dt: float) -> void:
	var langkah_dt: float = JedaSim.dt_efektif(_jeda, _baru_lanjut, dt)
	if not _jeda:
		_baru_lanjut = false
	_sepeda.gerak(_kontrol.vektor_stick(), langkah_dt)
	_perbarui_lemparan(langkah_dt)
	_kontrol.langkah_tanda(langkah_dt)
	_tanah.perbarui(_sepeda.jarak_ubin)
	_zona.perbarui(_sepeda.jarak_ubin)
	_objek.perbarui(_sepeda.jarak_ubin)
	_hud.tampilkan_kecepatan(_sepeda.kecepatan_ud)
	_hud.tampilkan_stamina(_sepeda.stamina(), _sepeda.lelah())
	_kontrol.atur_rem(_sepeda.rem_aktif())
	if _audio != null:
		_audio.perbarui_sepeda(_sepeda.pose(), _sepeda.kecepatan_ud, _sepeda.rem_aktif(), _jeda)
	_geser_dorongan = DoronganKecepatan.haluskan(_geser_dorongan, DoronganKecepatan.geser_target(_sepeda.kecepatan_ud), langkah_dt)
	_kamera.position = posisi_kamera()


## Langkah lemparan sesudah sepeda digerakkan: jeda antar lempar, isi ulang uji, koran terbang dan mendarat, lalu garis bidik dari
## keadaan sepeda yang baru (bukan keadaan frame sebelumnya).
func _perbarui_lemparan(langkah_dt: float) -> void:
	koran = SisaKoran.isi_ulang_jalan_uji(SisaKoran.langkah(koran, langkah_dt), _sepeda.jarak_ubin)
	if not _terbang.is_empty():
		var sisa: Array[KoranLempar.Koran] = []
		for lama: KoranLempar.Koran in _terbang:
			var baru: KoranLempar.Koran = KoranLempar.langkah(lama, langkah_dt, Config.JENDELA_KENA_BONUS)
			if baru.mendarat and not lama.mendarat:
				koran_mendarat.emit(baru)
			if not KoranLempar.selesai(baru):
				sisa.append(baru)
		_terbang = sisa
	_koran_tanah.tampilkan(_terbang)
	_koran_udara.tampilkan(_terbang)
	_hud.tampilkan_koran(koran.sisa, koran.penuh)
	var router: TouchRouter = _kontrol.router
	if not _jeda and router.swipe_aktif() and SisaKoran.boleh_lempar(koran):
		var lintasan: ThrowSolver.Lintasan = lintasan_swipe(router.awal_swipe(), router.posisi_swipe())
		if lintasan != null:
			_garis_bidik.tampilkan(lintasan, KoranLempar.bentuk_elips(lintasan, Config.JENDELA_KENA_BONUS))
			_bidik_nomor = router.nomor_swipe
			return
	_garis_bidik.sembunyikan()


## True selama layar jeda terbuka (simulasi, sprite, partikel, dan input berhenti).
func sedang_jeda() -> bool:
	return _jeda


## Geseran sepeda di layar akibat dorongan kecepatan (sudah dihaluskan), piksel game; nol di kecepatan santai.
func geser_dorongan() -> Vector2:
	return _geser_dorongan


## Posisi kamera supaya sepeda jatuh di `KAMERA_SEPEDA_*_PECAHAN` viewport ditambah geseran dorongan kecepatan,
## dibulatkan ke piksel (tidak ada sub-piksel dan tidak ada zoom).
func posisi_kamera() -> Vector2:
	var ukuran: Vector2 = get_viewport_rect().size
	var sasaran: Vector2 = Vector2(ukuran.x * Config.KAMERA_SEPEDA_X_PECAHAN, ukuran.y * Config.KAMERA_SEPEDA_Y_PECAHAN)
	return (_sepeda.position + ukuran / 2 - (sasaran + _geser_dorongan)).round()
