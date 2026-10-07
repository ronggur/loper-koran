## Memilih animasi loper dari input stick.
## speed_level: 0 = santai, 1 = cepat, 2 = ngebut
## steer: -2 = 90° kiri, -1 = serong kiri, 0 = lurus, 1 = serong kanan, 2 = 90° kanan
## (kiri/kanan mengikuti arah pelempar: kanan = sisi dekat, kiri = sisi seberang)
extends AnimatedSprite2D

const SPEEDS := ["santai", "cepat", "ngebut"]
const HEADINGS := {-2: "kiri", -1: "serong_kiri", 0: "normal", 1: "serong_kanan", 2: "kanan"}

@export_range(0, 2) var speed_level := 0:
	set(v):
		speed_level = clampi(v, 0, 2)
		_refresh()
@export_range(-2, 2) var steer := 0:
	set(v):
		steer = clampi(v, -2, 2)
		_refresh()
## Kalikan laju kayuh dengan kecepatan sepeda sebenarnya (1.0 = laju bawaan animasi).
@export var pedal_rate := 1.0:
	set(v):
		pedal_rate = v
		speed_scale = maxf(v, 0.0)


func _ready() -> void:
	_refresh()


func _refresh() -> void:
	if sprite_frames == null:
		return
	var anim := StringName("%s_%s" % [SPEEDS[speed_level], HEADINGS[steer]])
	if animation != anim:
		var f := frame
		play(anim)
		frame = f  # jaga fase kayuh saat berganti arah/kecepatan
