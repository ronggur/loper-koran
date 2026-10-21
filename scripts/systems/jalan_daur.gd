class_name JalanDaur
extends RefCounted
## Jalan lurus tanpa ujung dari bagian yang didaur di sekitar kamera, logika murni (AC-11 run 0B+0C).
##
## Dua hal yang didaur: (1) ubin tanah, yang sama sepanjang jalan sehingga cukup satu blok tetap yang
## digeser kelipatan satu ubin; (2) objek berkala (rumah dan kotak surat graybox) yang dipakai ulang
## lewat slot bernomor. Semua posisi dalam ubin dunia (`Iso`): x melintang jalan (positif = sisi
## `dekat`, nol = garis tengah jalan), maju = jarak sepanjang jalan, dan y dunia = -maju.

enum Jenis { ASPAL, TROTOAR, RUMPUT }

## Enam kolom ubin tanah melintang jalan, dari sisi `seberang` ke sisi `dekat` (run fase5a, D-2): rumput, trotoar, aspal di tiap sisi.
## Urutannya = urutan kolom `tools/env_art/ubin_perumahan.py` (`KOLOM`).
enum Kolom { RUMPUT_SEBERANG, TROTOAR_SEBERANG, ASPAL_SEBERANG, ASPAL_DEKAT, TROTOAR_DEKAT, RUMPUT_DEKAT }


## Jenis ubin tanah di posisi melintang `x` (ubin dari garis tengah jalan), simetris di kedua sisi.
static func jenis_di(x: float) -> Jenis:
	var jarak: float = absf(x)
	var setengah_aspal: float = Config.JALAN_LEBAR_UBIN / 2
	if jarak < setengah_aspal:
		return Jenis.ASPAL
	if jarak < setengah_aspal + Config.JALAN_TROTOAR_UBIN:
		return Jenis.TROTOAR
	return Jenis.RUMPUT


## Kolom ubin tanah di posisi melintang `x` (ubin dari garis tengah jalan): jenisnya sama dengan `jenis_di` (batas aspal-trotoar dan
## trotoar-rumput di |x| = 1 dan 2 dihitung ke kolom luar, di kedua sisi), sisinya dari tanda `x` (negatif = `seberang`, nol dan positif =
## `dekat`). Simetris: kolom di `-x` adalah cermin kolom di `x` kecuali tepat di `x` = 0.
static func kolom_di(x: float) -> Kolom:
	var dekat: bool = x >= 0.0
	match jenis_di(x):
		Jenis.ASPAL:
			return Kolom.ASPAL_DEKAT if dekat else Kolom.ASPAL_SEBERANG
		Jenis.TROTOAR:
			return Kolom.TROTOAR_DEKAT if dekat else Kolom.TROTOAR_SEBERANG
	return Kolom.RUMPUT_DEKAT if dekat else Kolom.RUMPUT_SEBERANG


## Benar bila ubin rumput di `x` ada di luar kolom rumput pertama (|x| >= setengah aspal + trotoar + `JALAN_RUMPUT_TEPI_UBIN`, batas
## inklusif ke luar). Kolom itu memakai ubin rumput polos, bukan ubin tepi kerb (D-2). Salah untuk aspal, trotoar, dan kolom rumput pertama.
static func rumput_luar(x: float) -> bool:
	return absf(x) >= Config.JALAN_LEBAR_UBIN / 2 + Config.JALAN_TROTOAR_UBIN + Config.JALAN_RUMPUT_TEPI_UBIN


## Pusat ubin tanah (x dunia, y dunia) yang perlu ada supaya seluruh layar tertutup, relatif terhadap
## titik awal blok (garis tengah jalan di jarak maju bulat). Pusat ubin: x di tengah ubin (kelipatan
## setengah ganjil), y bilangan bulat. Cakupan dihitung untuk lebar viewport terbesar dan sepeda di
## posisi mana pun di dalam batas tepi jalan resmi (`BikeMotion.batas_lateral_ubin`, termasuk trotoar), dengan batas ekstra
## sebesar geseran lateral terjauh ditambah satu ubin maju (blok digeser kelipatan satu ubin) supaya tepi tidak pernah terlihat.
static func sel_tanah(lebar_viewport: int, tinggi_viewport: int) -> PackedVector2Array:
	var hasil: PackedVector2Array = PackedVector2Array()
	var ubin: Vector2 = Vector2(Config.UBIN_LEBAR_PX, Config.UBIN_TINGGI_PX)
	var lebar: float = float(lebar_viewport)
	var tinggi: float = float(tinggi_viewport)
	var geser_lateral: Vector2 = Iso.dunia_ke_layar(Vector2(BikeMotion.batas_lateral_ubin(), 0.0)).abs()
	var geser_maju: Vector2 = Iso.dunia_ke_layar(-Iso.ARAH_MAJU).abs()
	var batas: Vector2 = geser_lateral + geser_maju
	var kiri_atas: Vector2 = Vector2(-lebar * Config.KAMERA_SEPEDA_X_PECAHAN, -tinggi * Config.KAMERA_SEPEDA_Y_PECAHAN) - batas
	var kanan_bawah: Vector2 = Vector2(lebar * (1.0 - Config.KAMERA_SEPEDA_X_PECAHAN), tinggi * (1.0 - Config.KAMERA_SEPEDA_Y_PECAHAN)) + batas
	var jangkauan: int = int(ceilf(lebar / float(Config.UBIN_LEBAR_PX))) * 2 + 2
	var setengah: Vector2 = ubin / 2
	for maju: int in range(-jangkauan, jangkauan + 1):
		for geser: int in range(-jangkauan, jangkauan + 1):
			var pusat: Vector2 = Vector2(float(geser) + 1.0 / 2, float(-maju))
			var layar: Vector2 = Iso.dunia_ke_layar(pusat)
			if layar.x + setengah.x < kiri_atas.x or layar.x - setengah.x > kanan_bawah.x:
				continue
			if layar.y + setengah.y < kiri_atas.y or layar.y - setengah.y > kanan_bawah.y:
				continue
			hasil.append(pusat)
	return hasil


## Jumlah slot yang cukup untuk menutup `mundur_ubin` di belakang sampai `maju_ubin` di depan sepeda.
## Nomor pertama membulat ke bawah (sampai satu periode di belakang batas), jadi ditambah dua slot cadangan.
static func jumlah_slot(mundur_ubin: int, maju_ubin: int, periode_ubin: int) -> int:
	return ceili(float(mundur_ubin + maju_ubin) / float(periode_ubin)) + 2


## Nomor objek berkala pertama yang masih perlu ada pada jarak maju sepeda `jarak_ubin`.
static func indeks_pertama(jarak_ubin: float, periode_ubin: int, mundur_ubin: int) -> int:
	return floori((jarak_ubin - float(mundur_ubin)) / float(periode_ubin))


## Nomor objek berkala yang dipegang slot `slot` (0 sampai jumlah-1) bila nomor pertama `pertama`.
## Tiap slot selalu memegang nomor yang sama modulo `jumlah`, jadi objek yang terlewat pindah ke depan
## tanpa menggeser slot lain.
static func indeks_slot(pertama: int, slot: int, jumlah: int) -> int:
	return pertama + posmod(slot - pertama, jumlah)


## Jarak maju titik pijak objek bernomor `indeks` dengan geseran `geser_ubin`, ubin.
static func maju_objek_ubin(indeks: int, periode_ubin: int, geser_ubin: float) -> float:
	return float(indeks * periode_ubin) + geser_ubin
