class_name TombolSentuh
extends Button
## Tombol yang tetap bisa diketuk jari mana pun saat jari lain menempel di layar (tombol jeda, "Lanjut"; run fase1b-umpan-balik).
##
## Masalah yang ditutup: GUI Godot 4.7 memakai emulasi mouse dari jari PERTAMA; ketukan jari kedua (jempol lain masih di stick)
## bisa tidak sampai ke `Button` sesudah tombol pernah menjeda pohon (dibuktikan di LOG run ini). Node ini membaca
## `InputEventScreenTouch` sendiri di `_input` (koordinat viewport game, sama dengan `KontrolTouch`): jari yang turun DAN naik di
## dalam persegi tombol memicu `ditekan`. Klik mouse (editor desktop) tetap lewat `pressed` bawaan. Dua jalur dalam satu frame
## (sentuhan + emulasi mouse dari sentuhan yang sama) hanya memicu sekali. Tidak menandai event tertangani.

## Tombol diketuk (sentuhan jari mana pun atau klik mouse), paling banyak sekali per frame.
signal ditekan

## Indeks jari yang turun di dalam tombol dan belum naik; -1 = tidak ada.
var _jari: int = -1
## Frame proses terakhir saat `ditekan` dipancarkan (mencegah ganda dalam satu frame).
var _frame_terakhir: int = -1


func _ready() -> void:
	pressed.connect(_picu)


func _input(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch) or not is_visible_in_tree() or disabled:
		return
	var sentuh: InputEventScreenTouch = event
	var di_dalam: bool = get_global_rect().has_point(sentuh.position)
	if sentuh.pressed and not sentuh.canceled:
		if _jari == -1 and di_dalam:
			_jari = sentuh.index
		return
	if sentuh.index != _jari:
		return
	_jari = -1
	if di_dalam and not sentuh.canceled:
		_picu()


func _notification(what: int) -> void:
	# Jari yang tertahan saat tombol berhenti diproses (pohon dijeda) atau disembunyikan tidak boleh memicu sesudahnya.
	if what == NOTIFICATION_PAUSED or what == NOTIFICATION_VISIBILITY_CHANGED:
		_jari = -1


func _picu() -> void:
	var frame: int = Engine.get_process_frames()
	if frame == _frame_terakhir:
		return
	_frame_terakhir = frame
	ditekan.emit()
