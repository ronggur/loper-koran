class_name BunyiKondisi
extends RefCounted
## Keputusan bunyi kondisi sepeda run 6A1 bagian B (SOUND_DESIGN 3.1 dan 4, AC-23 dan AC-27; usulan), logika murni, gaya `BunyiMisi`. Dipakai autoload `Audio`; berkas dari
## `tools/audio_art/sintesis_kondisi.py`. Autoload `Audio` tidak merujuk `BikeCondition`: ia menerima indeks komponen (bilangan bulat, urutan `Config.KONDISI_KOMPONEN`: ban, rem, rantai).
##
## Tanda peringatan: ban = mendesis, rem = berdecit, rantai = berisik. Pasangan visualnya (ikon komponen bergetar dan kotak WARN di HUD) dipicu pada langkah yang sama oleh `AdeganJalan`;
## bunyi bukan satu-satunya pembawa informasi. Transaksi bengkel: servis dan upgrade. Tidak ada bunyi selama jeda game (diatur `Audio`).

## Bunyi kondisi.
enum Bunyi { RANTAI_BERISIK, REM_BERDECIT, BAN_MENDESIS, SERVIS, UPGRADE }

## Berkas per bunyi.
const BERKAS: Dictionary = {
	Bunyi.RANTAI_BERISIK: "res://assets/audio/sfx/condition/sfx_cond_rantai_berisik_01.wav",
	Bunyi.REM_BERDECIT: "res://assets/audio/sfx/condition/sfx_cond_rem_berdecit_01.wav",
	Bunyi.BAN_MENDESIS: "res://assets/audio/sfx/condition/sfx_cond_ban_mendesis_01.wav",
	Bunyi.SERVIS: "res://assets/audio/sfx/condition/sfx_cond_servis_01.wav",
	Bunyi.UPGRADE: "res://assets/audio/sfx/condition/sfx_cond_upgrade_01.wav",
}
## Bunyi peringatan menurut indeks komponen di `Config.KONDISI_KOMPONEN` (ban, rem, rantai).
const PERINGATAN_INDEKS: Array[Bunyi] = [Bunyi.BAN_MENDESIS, Bunyi.REM_BERDECIT, Bunyi.RANTAI_BERISIK]


## True bila `indeks` adalah indeks komponen yang punya bunyi peringatan.
static func ada_peringatan(indeks: int) -> bool:
	return indeks >= 0 and indeks < PERINGATAN_INDEKS.size()


## Bunyi peringatan komponen berindeks `indeks` (panggil hanya bila `ada_peringatan`).
static func peringatan(indeks: int) -> Bunyi:
	return PERINGATAN_INDEKS[indeks]


## Volume bunyi `b`, dB: peringatan lebih pelan dari bel dan tabrakan (tidak menutupinya), transaksi bengkel lebih jelas.
static func volume_db(b: Bunyi) -> float:
	if b == Bunyi.SERVIS or b == Bunyi.UPGRADE:
		return Config.AUDIO_KONDISI_TRANSAKSI_VOLUME_DB
	return Config.AUDIO_KONDISI_PERINGATAN_VOLUME_DB


## Berkas bunyi `b`.
static func berkas(b: Bunyi) -> String:
	return BERKAS[b]


## Semua berkas bunyi kondisi, urut enum.
static func semua_berkas() -> Array[String]:
	var hasil: Array[String] = []
	for b: Bunyi in BERKAS:
		hasil.append(BERKAS[b])
	return hasil
