class_name BunyiMilestone
extends RefCounted
## Keputusan bunyi milestone tercapai run 6A2 bagian C (SOUND_DESIGN 3.1 dan 4, AC-15; usulan), logika murni, gaya `BunyiKondisi`. Dipakai autoload `Audio`; berkas dari
## `tools/audio_art/sintesis_milestone.py`. Satu denting lembut saat layar hasil menampilkan tingkat yang baru tercapai (pasangan visual: lencana dan baris "Baru"); tidak ada bunyi selama jeda game (diatur `Audio`).

## Berkas bunyi milestone tercapai.
const BERKAS: String = "res://assets/audio/sfx/milestone/sfx_milestone_tercapai_01.wav"


## Volume bunyi milestone, dB (`Config.AUDIO_MILESTONE_VOLUME_DB`).
static func volume_db() -> float:
	return Config.AUDIO_MILESTONE_VOLUME_DB


## True bila layar hasil membunyikan milestone: hanya bila ada tingkat yang baru tercapai (`jumlah_baru` > 0).
static func berbunyi(jumlah_baru: int) -> bool:
	return jumlah_baru > 0
