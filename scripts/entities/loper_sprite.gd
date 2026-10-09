class_name LoperSprite
extends AnimatedSprite2D
## Sprite pemain (Kemeja Agen) yang memilih animasi dari tingkat kecepatan dan arah, dan memainkan lempar koran (ART_DIRECTION 3.2).
##
## Node hanya menampilkan: pemilihan nama animasi ada di `LoperAnim` dan garis waktu lempar di `LemparWaktu` (logika murni).
## - `speed_level`: -1 = melambat (kayuh 4 fps), 0 = santai, 1 = cepat, 2 = ngebut (dijepit ke -1 sampai 2);
## - `steer`: -2 = 90 derajat ke sisi seberang, -1 = serong seberang, 0 = lurus, 1 = serong dekat,
##   2 = 90 derajat ke sisi dekat (dijepit ke -2 sampai 2). Nama animasi memakai `kiri` / `kanan`
##   karena berasal dari sprite aset yang dikunci; kiri = sisi seberang, kanan = sisi dekat
##   (mengikuti arah pelempar, GDD 4.2);
## - `pedal_rate`: pengali laju kayuh, 1.0 = laju bawaan animasi. Nilai negatif dianggap 0.
## Asal nilai (stick, gerak sebenarnya) diurus pemanggil, bukan node ini.
##
## Lempar (`lempar`): animasi `lempar_<sisi>_<kecepatan>_<arah>` dimainkan SEKALI dari frame 0 lalu sprite kembali ke animasi kayuh
## sesuai `speed_level` dan `steer` pada saat itu (bukan saat mulai), dengan indeks frame dan progres dilanjutkan seperti pergantian
## animasi biasa. Selama melempar `speed_level` dan `steer` tetap tersimpan tetapi tidak mengganti gambar, dan `lempar` berikutnya
## diabaikan. Waktu lempar dimajukan node sendiri lewat `maju(dt)` (dipanggil `_process`, `dt` dijepit ke
## `Config.LANGKAH_WAKTU_MAKS_DETIK`), bukan oleh pemutar bawaan, supaya tes bisa memajukannya dengan `dt` tetap.

## Koran lepas dari tangan: dipancarkan tepat sekali per lempar, saat frame `Config.LEMPAR_FRAME_LEPAS` (indeks 2) tampil.
## Proyektil koran (Fase 2) disambungkan ke sinyal ini.
signal koran_lepas(sisi: LoperAnim.Sisi)
## Animasi lempar habis dan sprite sudah kembali ke animasi kayuh: dipancarkan tepat sekali per lempar.
signal lempar_selesai

@export_range(-1, 2) var speed_level: int = 0:
	set(nilai):
		speed_level = LoperAnim.jepit_tingkat(nilai)
		_terapkan_animasi()
@export_range(-2, 2) var steer: int = 0:
	set(nilai):
		steer = LoperAnim.jepit_arah(nilai)
		_terapkan_animasi()
@export var pedal_rate: float = 1.0:
	set(nilai):
		pedal_rate = nilai
		speed_scale = LoperAnim.skala_kayuh(nilai)

var _sedang_melempar: bool = false
var _sisi_lempar: LoperAnim.Sisi = LoperAnim.Sisi.TIDAK_ADA
var _waktu_lempar: float = 0.0


func _init() -> void:
	sprite_frames_changed.connect(_saat_frames_berganti)


func _ready() -> void:
	set_process(_sedang_melempar)
	_terapkan_animasi()
	_mainkan_bila_siap()


func _process(delta: float) -> void:
	maju(minf(delta, Config.LANGKAH_WAKTU_MAKS_DETIK))


## True selama animasi lempar berjalan.
func sedang_melempar() -> bool:
	return _sedang_melempar


## Mulai animasi lempar ke `sisi`. Mengembalikan true bila dimulai. Tidak melakukan apa pun (false) bila sedang melempar
## (swipe berikutnya diabaikan), `sisi` adalah `TIDAK_ADA`, atau `sprite_frames` kosong. Animasi dipilih dari `speed_level` dan
## `steer` saat ini (`LoperAnim.nama_lempar`).
func lempar(sisi: LoperAnim.Sisi) -> bool:
	if _sedang_melempar or sprite_frames == null:
		return false
	var nama: StringName = LoperAnim.nama_lempar(sisi, speed_level, steer)
	if nama == &"":
		return false
	if not sprite_frames.has_animation(nama):
		push_warning("LoperSprite: animasi lempar '%s' tidak ada di SpriteFrames" % nama)
		return false
	_sedang_melempar = true
	_sisi_lempar = sisi
	_waktu_lempar = 0.0
	animation = nama
	set_frame_and_progress(0, 0.0)
	pause()
	set_process(true)
	return true


## Memajukan animasi lempar selama `dt` detik (tidak berpengaruh bila tidak sedang melempar). Memancarkan `koran_lepas` pada
## langkah yang pertama kali menampilkan frame lepas, lalu `lempar_selesai` saat frame habis dan sprite kembali ke kayuh.
func maju(dt: float) -> void:
	if not _sedang_melempar:
		return
	if sprite_frames == null or not sprite_frames.has_animation(animation):
		batalkan_lempar()
		return
	var langkah: LemparWaktu.Langkah = LemparWaktu.langkah(_waktu_lempar, dt, sprite_frames.get_animation_speed(animation), sprite_frames.get_frame_count(animation), Config.LEMPAR_FRAME_LEPAS)
	_waktu_lempar = langkah.waktu
	set_frame_and_progress(langkah.frame, langkah.progres)
	if langkah.lepas:
		koran_lepas.emit(_sisi_lempar)
	if langkah.selesai and _sedang_melempar:
		_akhiri_lempar()
		lempar_selesai.emit()


## Menghentikan lempar yang sedang berjalan dan kembali ke kayuh tanpa memancarkan `koran_lepas` atau `lempar_selesai`. Dipakai
## saat app di-background atau `sprite_frames` hilang, supaya tidak ada animasi lempar yang menggantung.
func batalkan_lempar() -> void:
	if _sedang_melempar:
		_akhiri_lempar()


func _akhiri_lempar() -> void:
	_sedang_melempar = false
	_sisi_lempar = LoperAnim.Sisi.TIDAK_ADA
	_waktu_lempar = 0.0
	set_process(false)
	_terapkan_animasi()
	_mainkan_bila_siap()


## Memasang animasi kayuh sesuai `speed_level` dan `steer`, menjaga fase kayuh saat berganti. Tidak menyentuh gambar selama melempar.
func _terapkan_animasi() -> void:
	if sprite_frames == null or _sedang_melempar:
		return
	var nama: StringName = LoperAnim.nama_animasi(speed_level, steer)
	if not sprite_frames.has_animation(nama):
		push_warning("LoperSprite: animasi '%s' tidak ada di SpriteFrames" % nama)
		return
	if animation == nama:
		return
	var frame_lama: int = frame
	var progres_lama: float = frame_progress
	animation = nama
	set_frame_and_progress(frame_lama, progres_lama)


## Menyalakan putaran animasi bila ada `sprite_frames` yang memuat animasi saat ini. Aman tanpa `sprite_frames` (Q-001).
func _mainkan_bila_siap() -> void:
	if _sedang_melempar or sprite_frames == null or not sprite_frames.has_animation(animation):
		return
	if not is_playing():
		play(animation)


## `sprite_frames` diganti (termasuk dari kosong ke berisi, Q-001): lempar yang berjalan dibatalkan, lalu animasi kayuh dipasang ulang.
func _saat_frames_berganti() -> void:
	if _sedang_melempar:
		_akhiri_lempar()
		return
	_terapkan_animasi()
	_mainkan_bila_siap()
