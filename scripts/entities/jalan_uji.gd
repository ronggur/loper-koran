class_name JalanUji
extends Node2D
## Scene uji Fase 0 (AC-11): jalan lurus tanpa ujung, sepeda placeholder digerakkan stick (AC-12), HUD sementara.
##
## Akar tipis: tiap `_process` memberi vektor stick (sentuhan, atau keyboard di editor) ke `SepedaUji`, lalu
## menggeser tanah dan objek berkala, kamera, dan HUD. Kamera mengikuti sepeda penuh (posisi dibulatkan ke piksel)
## dengan sepeda di sepertiga kiri layar (ART_DIRECTION 2.2) dan tanpa zoom, ditambah dorongan kecepatan (GDD 15):
## saat ngebut sepeda bergeser maju sedikit di bingkai, saat melambat mundur sedikit, dihaluskan eksponensial. Geseran
## hanya menggeser kamera (`DoronganKecepatan`); posisi dunia dan posisi sprite sepeda serta HUD tidak berubah. Gerak
## halus tetap float di `SepedaUji`; hanya posisi gambar yang dibulatkan. Stamina, rem, garis kecepatan, debu, getar
## kamera, dan batas jalan resmi adalah Fase 1.

## Geseran sepeda di layar akibat dorongan kecepatan yang sudah dihaluskan, piksel game.
var _geser_dorongan: Vector2 = Vector2.ZERO

@onready var _kamera: Camera2D = %Kamera
@onready var _tanah: TanahDaur = %Tanah
@onready var _objek: ObjekDaur = %Objek
@onready var _sepeda: SepedaUji = %Sepeda
@onready var _kontrol: KontrolTouch = %KontrolTouch
@onready var _hud: HudDev = %Hud


func _ready() -> void:
	_hud.kidal_diubah.connect(_kontrol.atur_kidal)
	perbarui(0.0)


func _process(delta: float) -> void:
	perbarui(minf(delta, Config.LANGKAH_WAKTU_MAKS_DETIK))


## Satu langkah permainan selama `dt` detik. Publik supaya tes terpadu bisa menjalankannya tanpa menunggu frame.
func perbarui(dt: float) -> void:
	_sepeda.gerak(_kontrol.vektor_stick(), dt)
	_tanah.perbarui(_sepeda.jarak_ubin)
	_objek.perbarui(_sepeda.jarak_ubin)
	_hud.tampilkan_kecepatan(_sepeda.kecepatan_ud)
	_geser_dorongan = DoronganKecepatan.haluskan(_geser_dorongan, DoronganKecepatan.geser_target(_sepeda.kecepatan_ud), dt)
	_kamera.position = posisi_kamera()


## Geseran sepeda di layar akibat dorongan kecepatan (sudah dihaluskan), piksel game; nol di kecepatan santai.
func geser_dorongan() -> Vector2:
	return _geser_dorongan


## Posisi kamera supaya sepeda jatuh di `KAMERA_SEPEDA_*_PECAHAN` viewport ditambah geseran dorongan kecepatan,
## dibulatkan ke piksel (tidak ada sub-piksel dan tidak ada zoom).
func posisi_kamera() -> Vector2:
	var ukuran: Vector2 = get_viewport_rect().size
	var sasaran: Vector2 = Vector2(ukuran.x * Config.KAMERA_SEPEDA_X_PECAHAN, ukuran.y * Config.KAMERA_SEPEDA_Y_PECAHAN)
	return (_sepeda.position + ukuran / 2 - (sasaran + _geser_dorongan)).round()
