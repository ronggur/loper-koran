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
## Lemparan koran (run fase2a-lemparan bagian 1b): SATU fungsi `lintasan_swipe` (`ThrowSolver.dari_swipe` dari posisi sepeda, kecepatan
## maju sebenarnya, kecepatan lateral efektif langkah terakhir, dan jeda lepas animasi) dipakai garis bidik tiap langkah (sesudah sepeda
## digerakkan). Saat jari dilepas, lemparan memakai OBJEK lintasan garis bidik yang sedang tampil untuk swipe itu (dibekukan pada langkah
## terakhir), bukan menghitung ulang dari posisi lepas: jari yang masih bergerak saat diangkat (flick) sesudah langkah terakhir tidak
## mengubah lemparan, jadi koran mendarat tepat di elips terakhir yang terlihat (D-4, QA-001 iterasi 2). Bila tidak ada garis bidik
## yang tampil untuk swipe itu (swipe turun dan naik di antara dua langkah, atau langkah terakhir menolak swipe karena masih pendek atau
## tegak), lemparan dihitung dari posisi lepas dengan `lintasan_swipe` yang sama dan keadaan sepeda yang sama (keadaan langkah terakhir):
## tidak ada prediksi tampil yang bisa berbeda. Lemparan diterima bila `SisaKoran` mengizinkan (koran ada, jeda antar lempar 0,35 detik
## lewat; D-8, D-9): koran berkurang tepat 1, animasi lempar dimulai, dan `KoranLempar` membekukan lintasannya. Koran terbang, mendarat, dinilai zona (`ZonaSasaran`), dan penandanya tampil
## sesuai waktu langkah (`dt` efektif), digambar `KoranGambar` (bayangan di tanah, koran dan penanda di atas objek). Garis bidik
## (`GarisBidik`, D-5) hanya tampil selama swipe ditahan, |dx| cukup, dan lempar diizinkan. Isi ulang koran khusus jalan uji
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
## Bunyi sepeda (D-3, D-5): tiap langkah keadaan sebenarnya (pose, kecepatan, rem, jeda) diberikan ke autoload `Audio` (`/root/Audio`,
## dicari lewat jalur node, bukan nama global, supaya scene tetap jalan tanpa autoload); `jeda_berubah` disambungkan ke
## `Audio.atur_jeda` (semua bunyi sepeda berhenti saat jeda, tanpa decit rem tertunda), dan keluar dari pohon menghentikannya.

## Status jeda berubah: true = layar jeda dibuka (simulasi, sprite, partikel, dan input berhenti), false = lanjut.
signal jeda_berubah(jeda: bool)
## Lemparan diterima (jari dilepas, koran berkurang 1): lintasan beku koran itu.
signal koran_dilempar(lintasan: ThrowSolver.Lintasan)
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
	_layar_jeda.lanjut_diminta.connect(minta_lanjut)
	_kontrol.router.swipe_selesai.connect(_saat_swipe_selesai)
	_layar_jeda.tampilkan(false)
	_audio = get_node_or_null(^"/root/Audio") as SKRIP_AUDIO
	if _audio != null:
		jeda_berubah.connect(_audio.atur_jeda)
	perbarui(0.0)


func _notification(what: int) -> void:
	_terapkan_jeda(JedaSim.peristiwa_dari_notifikasi(what))


func _exit_tree() -> void:
	# Scene keluar saat dijeda (mis. ganti scene atau tes selesai): pause pohon dilepas supaya tidak menahan scene lain.
	if _jeda:
		get_tree().paused = false
	if _audio != null:
		_audio.hentikan_sepeda()


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


## Satu swipe selesai (jari dilepas): lempar bila diizinkan (D-8, D-9). Lintasan = garis bidik yang sedang tampil untuk swipe ini
## (`lintasan_bidik_tampil`, D-4); tanpa garis bidik tampil, dihitung dari posisi lepas bila swipe cukup panjang dan datar (D-2).
## Ditolak = koran tidak berkurang dan jeda tidak mulai ulang. Garis bidik selalu hilang saat jari dilepas.
func _saat_swipe_selesai(awal: Vector2, akhir: Vector2, _durasi_detik: float) -> void:
	var bidik: ThrowSolver.Lintasan = lintasan_bidik_tampil(_kontrol.router.nomor_swipe)
	_garis_bidik.sembunyikan()
	if _jeda or not SisaKoran.boleh_lempar(koran):
		return
	var lintasan: ThrowSolver.Lintasan = bidik if bidik != null else lintasan_swipe(awal, akhir)
	if lintasan == null:
		return
	var hasil: SisaKoran.Hasil = SisaKoran.terima(koran, _sepeda.jarak_ubin)
	koran = hasil.keadaan
	if not hasil.diterima:
		return
	_terbang.append(KoranLempar.baru(lintasan))
	_sepeda.lempar(lintasan.sisi)
	_hud.tampilkan_koran(koran.sisa, koran.penuh)
	koran_dilempar.emit(lintasan)


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
			_garis_bidik.tampilkan(lintasan, ZonaSasaran.sah(KoranLempar.prediksi_antaran(lintasan, Config.JENDELA_KENA_BONUS)))
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
