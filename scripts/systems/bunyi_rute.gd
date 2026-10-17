class_name BunyiRute
extends RefCounted
## Keputusan bunyi rute run 3B: rintangan, tabrakan, bel, tip, dan tepat (SOUND_DESIGN 3.1, 3.3, 4.1-4.3; AC-19 run fase3b-rintangan-skor),
## logika murni. Dipakai autoload `Audio`; berkas dari `tools/audio_art/sintesis_rute.py`.
##
## - Peristiwa rintangan (`RintanganRute.Peristiwa`) ke bunyi (`dari_peristiwa`): anjing waspada = geram, mengejar = gonggong, mobil tanda =
##   bip lampu mundur (tiga bip sepanjang tanda 1,5 detik), mobil mundur = mesin. Anjing mundur karena bel tidak punya bunyi sendiri (bel
##   itu sendiri yang berbunyi; pasangan visualnya ikon "!").
## - Bel (`berkas_bel`, `pitch_bel`): tiga variasi "kring" bergiliran 01, 02, 03, 01 (tanpa acak); "kring kring!" memutar variasi berikutnya
##   `AUDIO_BEL_KEDUA_SETENGAH_NADA` setengah nada lebih tinggi. Ketukan yang ditolak tidak berbunyi.
## - Tip dan tepat (`TIP`, `TEPAT`): satu berkas masing-masing, diawali senyap di berkasnya supaya terdengar sesudah bunyi mendarat.
## Setiap bunyi punya pasangan visual (SOUND_DESIGN 4.3): geram = anjing berdiri, gonggong = anjing lari, bip = lampu mundur berkedip,
## mesin = mobil bergerak, tabrakan = pemain jatuh + kilatan, bel = teks "KRING!" + garis getar, tip = "+tip" melayang, tepat = penanda tepat.

## Bunyi rute.
enum Bunyi { ANJING_GERAM, ANJING_GONGGONG, MOBIL_BIP, MOBIL_MESIN, TABRAKAN, BEL, TIP, TEPAT }

## Berkas per bunyi (bel: tiga variasi urut 01, 02, 03).
const BERKAS: Dictionary = {
	Bunyi.ANJING_GERAM: ["res://assets/audio/sfx/obstacle/sfx_obs_dog_growl.wav"],
	Bunyi.ANJING_GONGGONG: ["res://assets/audio/sfx/obstacle/sfx_obs_dog_bark_01.wav"],
	Bunyi.MOBIL_BIP: ["res://assets/audio/sfx/obstacle/sfx_obs_car_beep.wav"],
	Bunyi.MOBIL_MESIN: ["res://assets/audio/sfx/obstacle/sfx_obs_car_engine.wav"],
	Bunyi.TABRAKAN: ["res://assets/audio/sfx/obstacle/sfx_obs_crash_01.wav"],
	Bunyi.BEL: ["res://assets/audio/sfx/bell/sfx_bike_bell_01.wav", "res://assets/audio/sfx/bell/sfx_bike_bell_02.wav", "res://assets/audio/sfx/bell/sfx_bike_bell_03.wav"],
	Bunyi.TIP: ["res://assets/audio/sfx/ui/sfx_ui_tip_01.wav"],
	Bunyi.TEPAT: ["res://assets/audio/sfx/ui/sfx_ui_tepat_01.wav"],
}
## Peristiwa rintangan -> bunyi. Peristiwa yang tidak ada di sini tidak berbunyi.
const BUNYI_PERISTIWA: Dictionary = {
	RintanganRute.Peristiwa.ANJING_WASPADA: Bunyi.ANJING_GERAM,
	RintanganRute.Peristiwa.ANJING_MENGEJAR: Bunyi.ANJING_GONGGONG,
	RintanganRute.Peristiwa.MOBIL_TANDA: Bunyi.MOBIL_BIP,
	RintanganRute.Peristiwa.MOBIL_MUNDUR: Bunyi.MOBIL_MESIN,
}


## True bila peristiwa rintangan `peristiwa` berbunyi.
static func berbunyi(peristiwa: RintanganRute.Peristiwa) -> bool:
	return BUNYI_PERISTIWA.has(peristiwa)


## Bunyi untuk peristiwa rintangan (panggil hanya bila `berbunyi`).
static func dari_peristiwa(peristiwa: RintanganRute.Peristiwa) -> Bunyi:
	return BUNYI_PERISTIWA[peristiwa]


## Volume bunyi `b`, dB (`Config.AUDIO_*_VOLUME_DB`).
static func volume_db(b: Bunyi) -> float:
	match b:
		Bunyi.BEL:
			return Config.AUDIO_BEL_VOLUME_DB
		Bunyi.TABRAKAN:
			return Config.AUDIO_TABRAKAN_VOLUME_DB
		Bunyi.TIP, Bunyi.TEPAT:
			return Config.AUDIO_TIP_VOLUME_DB
	return Config.AUDIO_RINTANGAN_VOLUME_DB


## Berkas bunyi `b` pada giliran ke-`giliran` (dibungkus; bunyi satu berkas selalu berkas itu).
static func berkas(b: Bunyi, giliran: int) -> String:
	var daftar: Array = BERKAS[b]
	return daftar[posmod(giliran, daftar.size())]


## Giliran sesudah `giliran` untuk bunyi `b`.
static func giliran_berikut(b: Bunyi, giliran: int) -> int:
	return posmod(giliran + 1, (BERKAS[b] as Array).size())


## Pitch bel untuk ketukan `bunyi_bel`: "kring" nada dasar, "kring kring!" lebih tinggi; ditolak = 0 (tidak diputar).
static func pitch_bel(bunyi_bel: Bel.Bunyi) -> float:
	match bunyi_bel:
		Bel.Bunyi.KRING:
			return 1.0
		Bel.Bunyi.KRING_KRING:
			return pow(Config.AUDIO_RASIO_OKTAF, Config.AUDIO_BEL_KEDUA_SETENGAH_NADA / Config.AUDIO_SETENGAH_NADA_PER_OKTAF)
	return 0.0


## Semua berkas bunyi rute, urut enum lalu variasi.
static func semua_berkas() -> Array[String]:
	var hasil: Array[String] = []
	for b: Bunyi in BERKAS:
		for jalur: String in BERKAS[b]:
			hasil.append(jalur)
	return hasil
