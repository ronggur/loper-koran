class_name JalanUji
extends Node2D
## Scene uji (Fase 0 AC-11, Fase 1 run 1A): jalan lurus tanpa ujung, sepeda digerakkan stick, HUD sementara.
##
## Akar tipis: tiap `_process` memberi vektor stick (sentuhan, atau keyboard di editor) ke `SepedaUji`, lalu
## menggeser tanah dan objek berkala, kamera, dan HUD. Kamera mengikuti sepeda penuh (posisi dibulatkan ke piksel)
## dengan sepeda di sepertiga kiri layar (ART_DIRECTION 2.2) dan tanpa zoom, ditambah dorongan kecepatan (GDD 15):
## saat ngebut sepeda bergeser maju sedikit di bingkai, saat melambat mundur sedikit, dihaluskan eksponensial. Geseran
## hanya menggeser kamera (`DoronganKecepatan`); posisi dunia dan posisi sprite sepeda serta HUD tidak berubah. Gerak
## halus tetap float di `SepedaUji`; hanya posisi gambar yang dibulatkan. Swipe di zona swipe memainkan animasi lempar
## (`_saat_swipe_selesai`, tanpa proyektil; Fase 2). Stamina dan rem tampil di HUD dan cincin stick.
##
## Jeda (D-6 run fase1b-umpan-balik, `JedaSim`): tombol jeda di HUD, app di-background atau kehilangan fokus (PAUSED, FOCUS_OUT), dan
## tombol back Android saat berjalan membuka **layar jeda** (`LayarJeda`). Tidak ada lanjut otomatis: RESUMED dan FOCUS_IN tidak
## mengubah apa pun; pemain melanjutkan lewat tombol "Lanjut" atau back saat layar jeda terbuka. Selama jeda `SceneTree.paused`
## menyala, jadi sprite pemain, partikel umpan balik, dan input stick dan swipe berhenti; bunyi sepeda dihentikan `Audio` lewat
## `jeda_berubah` (lihat bawah); hanya layar jeda (`PROCESS_MODE_WHEN_PAUSED`) yang menerima sentuhan. `perbarui` tetap boleh dipanggil tetapi
## memakai `dt` 0, jadi kecepatan, jarak, stamina, lama tahan rem, dan geseran dorongan tidak berubah; saat menjeda stick dan swipe
## dilepas, lempar ditutup, dan lama tahan rem kembali 0 (`SepedaUji.jeda`). Langkah pertama sesudah lanjut ber-`dt` 0.
## Titik kait untuk node lain: sinyal `jeda_berubah` dan `sedang_jeda()`.
##
## Bunyi sepeda (D-3, D-5): tiap langkah keadaan sebenarnya (pose, kecepatan, rem, jeda) diberikan ke autoload `Audio` (`/root/Audio`,
## dicari lewat jalur node, bukan nama global, supaya scene tetap jalan tanpa autoload); `jeda_berubah` disambungkan ke
## `Audio.atur_jeda` (semua bunyi sepeda berhenti saat jeda, tanpa decit rem tertunda), dan keluar dari pohon menghentikannya.

## Status jeda berubah: true = layar jeda dibuka (simulasi, sprite, partikel, dan input berhenti), false = lanjut.
signal jeda_berubah(jeda: bool)

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

@onready var _kamera: Camera2D = %Kamera
@onready var _tanah: TanahDaur = %Tanah
@onready var _objek: ObjekDaur = %Objek
@onready var _sepeda: SepedaUji = %Sepeda
@onready var _kontrol: KontrolTouch = %KontrolTouch
@onready var _hud: HudDev = %Hud
@onready var _layar_jeda: LayarJeda = %LayarJeda


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
	if not berubah:
		return
	_layar_jeda.tampilkan(_jeda)
	if is_inside_tree():
		get_tree().paused = _jeda
	jeda_berubah.emit(_jeda)


func _process(delta: float) -> void:
	perbarui(minf(delta, Config.LANGKAH_WAKTU_MAKS_DETIK))


## Satu swipe selesai: sisi lempar dari arah swipe (kiri layar = seberang, kanan layar = dekat, GDD 5.2), lalu animasi lempar
## pemain. Swipe dominan tegak atau dengan |dx| di bawah 6% lebar viewport tidak melempar (`ThrowSolver.sisi_dari_swipe`, D-2 run
## fase2a-lemparan). Proyektil, garis bidik, dan sisa koran menyusul (run fase2a-lemparan bagian 1b).
func _saat_swipe_selesai(awal: Vector2, akhir: Vector2, _durasi_detik: float) -> void:
	_sepeda.lempar(ThrowSolver.sisi_dari_swipe(awal, akhir, get_viewport_rect().size.x))


## Satu langkah permainan selama `dt` detik. Publik supaya tes terpadu bisa menjalankannya tanpa menunggu frame. Selama jeda
## dan pada langkah pertama sesudah lanjut `dt` diganti 0 (`JedaSim.dt_efektif`).
func perbarui(dt: float) -> void:
	var langkah_dt: float = JedaSim.dt_efektif(_jeda, _baru_lanjut, dt)
	if not _jeda:
		_baru_lanjut = false
	_sepeda.gerak(_kontrol.vektor_stick(), langkah_dt)
	_tanah.perbarui(_sepeda.jarak_ubin)
	_objek.perbarui(_sepeda.jarak_ubin)
	_hud.tampilkan_kecepatan(_sepeda.kecepatan_ud)
	_hud.tampilkan_stamina(_sepeda.stamina(), _sepeda.lelah())
	_kontrol.atur_rem(_sepeda.rem_aktif())
	if _audio != null:
		_audio.perbarui_sepeda(_sepeda.pose(), _sepeda.kecepatan_ud, _sepeda.rem_aktif(), _jeda)
	_geser_dorongan = DoronganKecepatan.haluskan(_geser_dorongan, DoronganKecepatan.geser_target(_sepeda.kecepatan_ud), langkah_dt)
	_kamera.position = posisi_kamera()


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
