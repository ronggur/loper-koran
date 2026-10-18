class_name BunyiMisi
extends RefCounted
## Keputusan bunyi misi kucing run 4B (SOUND_DESIGN 3.1 dan 4, AC-15 run fase4b-misi-kucing; usulan), logika murni, gaya `BunyiRute`. Dipakai autoload `Audio`; berkas dari
## `tools/audio_art/sintesis_misi.py`.
##
## Peristiwa misi (`MissionManager.Peristiwa`) ke bunyi (`dari_peristiwa`): `PETUNJUK` = meong (pasangan visual: gelembung teks petunjuk dan kilau), `TERLIHAT` = "mrik"
## kecil saat kucing mulai terlihat (pasangan visual: kilau di atas kepala), `TERTANGKAP` = nada selesai (banner "Kucing ketemu!"), `GAGAL` = dua nada turun lembut
## (banner "Kucingnya lolos hari ini"). `LANGKAH_SELESAI` tidak berbunyi sendiri (langkah lihat selesai diam-diam; tangkap membunyikan `TERTANGKAP`). Tidak ada bunyi
## selama jeda game (diatur `Audio`).

## Bunyi misi.
enum Bunyi { MEONG, TERLIHAT, SELESAI, GAGAL }

## Berkas per bunyi.
const BERKAS: Dictionary = {
	Bunyi.MEONG: "res://assets/audio/sfx/mission/sfx_mis_meong_01.wav",
	Bunyi.TERLIHAT: "res://assets/audio/sfx/mission/sfx_mis_terlihat_01.wav",
	Bunyi.SELESAI: "res://assets/audio/sfx/mission/sfx_mis_selesai_01.wav",
	Bunyi.GAGAL: "res://assets/audio/sfx/mission/sfx_mis_gagal_01.wav",
}
## Peristiwa misi (nilai enum `MissionManager.Peristiwa`) -> bunyi. Peristiwa yang tidak ada di sini tidak berbunyi.
const BUNYI_PERISTIWA: Dictionary = {
	MissionManager.Peristiwa.PETUNJUK: Bunyi.MEONG,
	MissionManager.Peristiwa.TERLIHAT: Bunyi.TERLIHAT,
	MissionManager.Peristiwa.TERTANGKAP: Bunyi.SELESAI,
	MissionManager.Peristiwa.GAGAL: Bunyi.GAGAL,
}


## True bila peristiwa misi `peristiwa` berbunyi.
static func berbunyi(peristiwa: int) -> bool:
	return BUNYI_PERISTIWA.has(peristiwa)


## Bunyi untuk peristiwa misi (panggil hanya bila `berbunyi`).
static func dari_peristiwa(peristiwa: int) -> Bunyi:
	return BUNYI_PERISTIWA[peristiwa]


## Volume bunyi `b`, dB (`Config.AUDIO_MISI_*_VOLUME_DB`): gagal lebih pelan.
static func volume_db(b: Bunyi) -> float:
	return Config.AUDIO_MISI_GAGAL_VOLUME_DB if b == Bunyi.GAGAL else Config.AUDIO_MISI_VOLUME_DB


## Berkas bunyi `b`.
static func berkas(b: Bunyi) -> String:
	return BERKAS[b]


## Semua berkas bunyi misi, urut enum.
static func semua_berkas() -> Array[String]:
	var hasil: Array[String] = []
	for b: Bunyi in BERKAS:
		hasil.append(BERKAS[b])
	return hasil
