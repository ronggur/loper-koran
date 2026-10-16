class_name BunyiLempar
extends RefCounted
## Keputusan bunyi lempar dan mendarat (SOUND_DESIGN 3.1 dan 4.2, D-10 run fase2b-bantu-audio), logika murni. Dipakai autoload `Audio`.
##
## - **Permukaan dari hasil** (`permukaan`): `KOTAK_SURAT` -> kotak surat ("tunk"), `TERAS` -> teras ("plak"), `HALAMAN` -> rumput ("puk"),
##   `MELESET` dan `BUKAN_PELANGGAN` -> meleset ("plek"; "meleset: jalan, rumah salah", SOUND_DESIGN 3.1). `JENDELA` mengikuti status
##   antaran dengan sakelar jendela (`Config.JENDELA_KENA_BONUS`): bonus (sah) -> teras, penalti (tidak sah) -> meleset, sampai bunyi
##   jendela ada (SOUND_DESIGN 4.2). Jadi bunyi selalu sejalan dengan penanda kena/meleset yang tampil.
## - **Variasi bergiliran** (`berkas_mendarat`, `giliran_berikut`): tiap permukaan punya tiga berkas, dipilih 01, 02, 03, 01, ... per
##   permukaan, tanpa RNG. Pencacah giliran disimpan pemanggil (`Audio`, satu per permukaan); fungsi ini hanya memetakan giliran ke berkas.
## - **Nada combo** (AC-18 run fase3b-rintangan-skor, SOUND_DESIGN 3.1): bunyi mendarat antaran sah ke-n dalam rangkaian combo
##   (`SkorRute.Hasil.urutan_beruntun`) diputar `tingkat_nada` = n - 1 setengah nada lebih tinggi, dijepit `AUDIO_COMBO_NADA_MAKS` (5),
##   lalu bertahan; pitch = rasio oktaf pangkat (tingkat / 12) (`pitch_nada`). Bukan antaran (meleset, rumah sudah terantar) = nada dasar;
##   combo putus mengembalikan antaran berikutnya ke nada dasar tanpa bunyi tambahan. Acak nada ±5% (SOUND_DESIGN 2) belum dipakai.

## Permukaan tempat koran mendarat, untuk memilih bunyi.
enum Permukaan { KOTAK_SURAT, TERAS, RUMPUT, MELESET }

## "Wus" saat lemparan diterima (berkas hasil `tools/audio_art/sintesis_lempar.py`).
const BERKAS_WUS: String = "res://assets/audio/sfx/throw/sfx_throw_whoosh_01.wav"
## Berkas bunyi mendarat per permukaan, urut variasi 01, 02, 03 (SOUND_DESIGN 6).
const BERKAS_MENDARAT: Dictionary = {
	Permukaan.KOTAK_SURAT: ["res://assets/audio/sfx/throw/sfx_land_mailbox_01.wav", "res://assets/audio/sfx/throw/sfx_land_mailbox_02.wav", "res://assets/audio/sfx/throw/sfx_land_mailbox_03.wav"],
	Permukaan.TERAS: ["res://assets/audio/sfx/throw/sfx_land_porch_01.wav", "res://assets/audio/sfx/throw/sfx_land_porch_02.wav", "res://assets/audio/sfx/throw/sfx_land_porch_03.wav"],
	Permukaan.RUMPUT: ["res://assets/audio/sfx/throw/sfx_land_grass_01.wav", "res://assets/audio/sfx/throw/sfx_land_grass_02.wav", "res://assets/audio/sfx/throw/sfx_land_grass_03.wav"],
	Permukaan.MELESET: ["res://assets/audio/sfx/throw/sfx_land_miss_01.wav", "res://assets/audio/sfx/throw/sfx_land_miss_02.wav", "res://assets/audio/sfx/throw/sfx_land_miss_03.wav"],
}


## Permukaan bunyi untuk hasil sasaran `hasil` (`ZonaSasaran.Hasil`) dengan sakelar jendela `jendela_bonus`.
static func permukaan(hasil: ZonaSasaran.Hasil, jendela_bonus: bool) -> Permukaan:
	match hasil:
		ZonaSasaran.Hasil.KOTAK_SURAT:
			return Permukaan.KOTAK_SURAT
		ZonaSasaran.Hasil.TERAS:
			return Permukaan.TERAS
		ZonaSasaran.Hasil.HALAMAN:
			return Permukaan.RUMPUT
		ZonaSasaran.Hasil.JENDELA:
			return Permukaan.TERAS if ZonaSasaran.sah(ZonaSasaran.status_antaran(hasil, jendela_bonus)) else Permukaan.MELESET
	return Permukaan.MELESET


## Jumlah variasi berkas untuk permukaan `p`.
static func jumlah_variasi(p: Permukaan) -> int:
	return (BERKAS_MENDARAT[p] as Array).size()


## Berkas bunyi mendarat untuk permukaan `p` pada giliran ke-`giliran` (0 = variasi 01). Giliran di luar rentang dibungkus.
static func berkas_mendarat(p: Permukaan, giliran: int) -> String:
	var daftar: Array = BERKAS_MENDARAT[p]
	return daftar[posmod(giliran, daftar.size())]


## Giliran sesudah `giliran` untuk permukaan `p` (01 -> 02 -> 03 -> 01).
static func giliran_berikut(p: Permukaan, giliran: int) -> int:
	return posmod(giliran + 1, jumlah_variasi(p))


## Semua berkas bunyi lempar dan mendarat ("wus" lalu tiap permukaan urut variasi).
static func semua_berkas() -> Array[String]:
	var hasil: Array[String] = [BERKAS_WUS]
	for p: Permukaan in [Permukaan.KOTAK_SURAT, Permukaan.TERAS, Permukaan.RUMPUT, Permukaan.MELESET]:
		for berkas: String in BERKAS_MENDARAT[p]:
			hasil.append(berkas)
	return hasil


## Tingkat nada combo (0 = nada dasar) untuk antaran ke-`urutan_beruntun` dalam rangkaian (1 = pertama); 0 atau kurang (bukan antaran) = 0.
static func tingkat_nada(urutan_beruntun: int) -> int:
	return clampi(urutan_beruntun - 1, 0, Config.AUDIO_COMBO_NADA_MAKS)


## Pitch untuk tingkat nada `tingkat` (dijepit 0..`AUDIO_COMBO_NADA_MAKS`): rasio oktaf pangkat (tingkat / setengah nada per oktaf).
static func pitch_nada(tingkat: int) -> float:
	var n: int = clampi(tingkat, 0, Config.AUDIO_COMBO_NADA_MAKS)
	return pow(Config.AUDIO_RASIO_OKTAF, float(n) / Config.AUDIO_SETENGAH_NADA_PER_OKTAF)


## Pitch bunyi mendarat untuk antaran ke-`urutan_beruntun` (0 = bukan antaran: nada dasar).
static func pitch_mendarat(urutan_beruntun: int) -> float:
	return pitch_nada(tingkat_nada(urutan_beruntun))
