class_name JalanDaur
extends RefCounted
## Jalan lurus tanpa ujung dari bagian yang didaur di sekitar kamera, logika murni (AC-11 run 0B+0C).
##
## Dua hal yang didaur: (1) ubin tanah, yang sama sepanjang jalan sehingga cukup satu blok tetap yang
## digeser kelipatan satu ubin; (2) objek berkala (rumah dan kotak surat graybox) yang dipakai ulang
## lewat slot bernomor. Semua posisi dalam ubin dunia (`Iso`): x melintang jalan (positif = sisi
## `dekat`, nol = garis tengah jalan), maju = jarak sepanjang jalan, dan y dunia = -maju.

enum Jenis { ASPAL, TROTOAR, RUMPUT }


## Jenis ubin tanah di posisi melintang `x` (ubin dari garis tengah jalan), simetris di kedua sisi.
static func jenis_di(x: float) -> Jenis:
	var jarak: float = absf(x)
	var setengah_aspal: float = Config.JALAN_LEBAR_UBIN / 2
	if jarak < setengah_aspal:
		return Jenis.ASPAL
	if jarak < setengah_aspal + Config.JALAN_TROTOAR_UBIN:
		return Jenis.TROTOAR
	return Jenis.RUMPUT


## Pusat ubin tanah (x dunia, y dunia) yang perlu ada supaya seluruh layar tertutup, relatif terhadap
## titik awal blok (garis tengah jalan di jarak maju bulat). Pusat ubin: x di tengah ubin (kelipatan
## setengah ganjil), y bilangan bulat. Cakupan dihitung untuk lebar viewport terbesar dan sepeda di
## posisi mana pun pada lebar jalan, dengan batas satu ubin ekstra supaya tepi tidak pernah terlihat.
static func sel_tanah(lebar_viewport: int, tinggi_viewport: int) -> PackedVector2Array:
	var hasil: PackedVector2Array = PackedVector2Array()
	var ubin: Vector2 = Vector2(Config.UBIN_LEBAR_PX, Config.UBIN_TINGGI_PX)
	var lebar: float = float(lebar_viewport)
	var tinggi: float = float(tinggi_viewport)
	var kiri_atas: Vector2 = Vector2(-lebar * Config.KAMERA_SEPEDA_X_PECAHAN, -tinggi * Config.KAMERA_SEPEDA_Y_PECAHAN) - ubin
	var kanan_bawah: Vector2 = Vector2(lebar * (1.0 - Config.KAMERA_SEPEDA_X_PECAHAN), tinggi * (1.0 - Config.KAMERA_SEPEDA_Y_PECAHAN)) + ubin
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
