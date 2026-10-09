class_name LoperSprite
extends AnimatedSprite2D
## Sprite pemain (Kemeja Agen) yang memilih animasi dari tingkat kecepatan dan arah (ART_DIRECTION 3.2).
##
## Node hanya menampilkan: pemilihan nama animasi ada di `LoperAnim` (logika murni).
## - `speed_level`: 0 = santai, 1 = cepat, 2 = ngebut (dijepit ke 0 sampai 2);
## - `steer`: -2 = 90 derajat ke sisi seberang, -1 = serong seberang, 0 = lurus, 1 = serong dekat,
##   2 = 90 derajat ke sisi dekat (dijepit ke -2 sampai 2). Nama animasi memakai `kiri` / `kanan`
##   karena berasal dari sprite aset yang dikunci; kiri = sisi seberang, kanan = sisi dekat
##   (mengikuti arah pelempar, GDD 4.2);
## - `pedal_rate`: pengali laju kayuh, 1.0 = laju bawaan animasi. Nilai negatif dianggap 0.
## Asal nilai (stick, gerak sebenarnya) diurus pemanggil, bukan node ini.

@export_range(0, 2) var speed_level: int = 0:
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


func _ready() -> void:
	_terapkan_animasi()
	if not is_playing():
		play(animation)


## Memasang animasi sesuai `speed_level` dan `steer`, menjaga fase kayuh saat berganti.
func _terapkan_animasi() -> void:
	if sprite_frames == null:
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
