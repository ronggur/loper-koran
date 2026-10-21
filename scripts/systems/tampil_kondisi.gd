class_name TampilKondisi
extends RefCounted
## Tampilan kondisi sepeda sebagai data murni (DESIGN_SPEC 3.3; AC-22 dan AC-23 run fase6a1-bengkel-kondisi bagian B; usulan): kunci teks komponen dan tingkat, isi tiga kotak,
## tanda "!", dan geseran getar ikon. Node (`KotakKondisi`, `LayarBengkel`, `HudRute`, `LayarHasil`) hanya menggambar hasilnya. Semua dari `BikeCondition`/`Config`, tanpa node, `Time`, atau RNG.
## Status terbaca tanpa warna: jumlah kotak terisi (3/2/1/0), kotak kosong berongga, tanda "!" untuk PERLU_BENGKEL, dan ikon bergetar saat peringatan.

## Isi satu kotak kondisi. PENUH = terisi `TEXT`; PENUH_WARN = terisi `WARN` (PERLU_BENGKEL, atau sedang peringatan); KOSONG = berongga `UI_PANEL_RAISED`.
enum Kotak { PENUH, PENUH_WARN, KOSONG }

## Kunci terjemahan nama komponen (`translations/ui.csv`).
const KUNCI_NAMA: Dictionary = {"ban": "KONDISI_NAMA_BAN", "rem": "KONDISI_NAMA_REM", "rantai": "KONDISI_NAMA_RANTAI"}
## Kunci terjemahan tingkat: BAIK, AUS, PERLU_BENGKEL (urut `BikeCondition.Tingkat`).
const KUNCI_TINGKAT: Array[String] = ["KONDISI_TINGKAT_BAIK", "KONDISI_TINGKAT_AUS", "KONDISI_TINGKAT_PERLU"]


## Kunci nama komponen `komponen` ("" bila bukan komponen yang dikenal).
static func kunci_nama(komponen: String) -> String:
	return KUNCI_NAMA.get(komponen, "")


## Kunci teks tingkat kondisi `kondisi`.
static func kunci_tingkat(kondisi: float) -> String:
	return KUNCI_TINGKAT[int(BikeCondition.tingkat(kondisi))]


## Tiga kotak kondisi `kondisi` urut dari kiri: terisi sebanyak `BikeCondition.kotak_terisi`, sisanya KOSONG. Terisi berwarna WARN bila PERLU_BENGKEL atau `kedip` (peringatan).
static func kotak(kondisi: float, kedip: bool) -> Array[Kotak]:
	var hasil: Array[Kotak] = []
	var terisi: int = BikeCondition.kotak_terisi(kondisi)
	var warn: bool = kedip or BikeCondition.tingkat(kondisi) == BikeCondition.Tingkat.PERLU_BENGKEL
	for i: int in range(Config.KONDISI_KOTAK_BAIK):
		if i >= terisi:
			hasil.append(Kotak.KOSONG)
		else:
			hasil.append(Kotak.PENUH_WARN if warn else Kotak.PENUH)
	return hasil


## True bila tanda "!" tampil: komponen PERLU_BENGKEL (perlu diperbaiki di bengkel setelah mengantar; efeknya hanya menghambat).
static func tanda_seru(kondisi: float) -> bool:
	return BikeCondition.tingkat(kondisi) == BikeCondition.Tingkat.PERLU_BENGKEL


## Geseran mendatar ikon (piksel game) saat peringatan tersisa `kedip_sisa` detik: 0 bila tidak ada peringatan, selain itu bergantian +/- `KONDISI_GETAR_PX` tiap setengah
## `KONDISI_GETAR_PERIODE_DETIK`. Murni dari sisa waktu, jadi membeku saat jeda game bersama waktunya.
static func getar(kedip_sisa: float) -> int:
	if not is_finite(kedip_sisa) or kedip_sisa <= 0.0:
		return 0
	var fase: int = int(kedip_sisa / (Config.KONDISI_GETAR_PERIODE_DETIK / 2))
	return Config.KONDISI_GETAR_PX if fase % 2 == 0 else -Config.KONDISI_GETAR_PX
