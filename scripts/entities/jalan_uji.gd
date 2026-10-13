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
## Jeda (D-6 run fase1a-gerak): app di-background atau kehilangan fokus menjeda simulasi (`JedaSim`): `perbarui` tetap boleh
## dipanggil tetapi memakai `dt` 0, jadi kecepatan, jarak, stamina, lama tahan rem, dan geseran dorongan tidak berubah; stick dan
## swipe dilepas (`KontrolTouch`), lempar ditutup, dan lama tahan rem kembali 0 (`SepedaUji.jeda`). Lanjut otomatis saat app
## kembali; langkah pertama sesudahnya juga ber-`dt` 0. `set_process` tidak disentuh. Garis kecepatan, debu, dan getar kamera Run 1B.

## Geseran sepeda di layar akibat dorongan kecepatan yang sudah dihaluskan, piksel game.
var _geser_dorongan: Vector2 = Vector2.ZERO
## True selama simulasi dijeda (`JedaSim`).
var _jeda: bool = false
## True bila langkah berikutnya adalah langkah pertama sesudah lanjut (memakai dt 0).
var _baru_lanjut: bool = false

@onready var _kamera: Camera2D = %Kamera
@onready var _tanah: TanahDaur = %Tanah
@onready var _objek: ObjekDaur = %Objek
@onready var _sepeda: SepedaUji = %Sepeda
@onready var _kontrol: KontrolTouch = %KontrolTouch
@onready var _hud: HudDev = %Hud


func _ready() -> void:
	_hud.kidal_diubah.connect(_kontrol.atur_kidal)
	_kontrol.router.swipe_selesai.connect(_saat_swipe_selesai)
	perbarui(0.0)


func _notification(what: int) -> void:
	var jeda_baru: bool = JedaSim.jeda_sesudah(_jeda, what)
	_baru_lanjut = JedaSim.baru_lanjut_sesudah(_jeda, _baru_lanjut, what)
	_jeda = jeda_baru
	if JedaSim.notifikasi_jeda(what) and _sepeda != null:
		_sepeda.jeda()
		_kontrol.atur_rem(false)


func _process(delta: float) -> void:
	perbarui(minf(delta, Config.LANGKAH_WAKTU_MAKS_DETIK))


## Satu swipe selesai: sisi lempar dari arah swipe (kiri layar = seberang, kanan layar = dekat, GDD 5.2), lalu animasi lempar
## pemain. Swipe vertikal atau lebih pendek dari ambang tidak melempar (`LoperAnim.sisi_dari_swipe`). Tanpa proyektil (Fase 2).
func _saat_swipe_selesai(awal: Vector2, akhir: Vector2, _durasi_detik: float) -> void:
	_sepeda.lempar(LoperAnim.sisi_dari_swipe(awal, akhir))


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
	_geser_dorongan = DoronganKecepatan.haluskan(_geser_dorongan, DoronganKecepatan.geser_target(_sepeda.kecepatan_ud), langkah_dt)
	_kamera.position = posisi_kamera()


## True selama simulasi dijeda (app di-background atau kehilangan fokus).
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
