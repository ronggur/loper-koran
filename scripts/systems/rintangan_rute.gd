class_name RintanganRute
extends RefCounted
## Semua rintangan satu rute dan tabrakan sepeda dengannya, logika murni (AC-1 sampai AC-7, AC-14 run fase3b-rintangan-skor, usulan).
##
## Rintangan dibangun dari `objek` segmen yang sudah ada di rute (`RouteBuilder.Rute.objek`: jenis, maju, jalur, tanda), tanpa field data
## baru (AC-5). Jenis dipetakan lewat `JENIS_DATA`; tiap rintangan memegang keadaan mesinnya sendiri (`AnjingPenjaga`, `MobilGarasi`; tanpa
## pewarisan, catatan D-14 run 3A). Satu langkah (`langkah`) adalah SATU-SATUNYA urutan dunia per langkah, dipakai scene dan simulasi tes:
## 1. sepeda sudah digerakkan pemilik (`BikeMotion.langkah` dengan `tahan_naik = Tabrakan.oleng(keadaan.tabrakan)`);
## 2. tiap rintangan melangkah dengan posisi dan kecepatan sepeda baru (peristiwa tanda dicatat untuk bunyi dan visual);
## 3. `Tabrakan.langkah` atas bentuk rintangan yang berbahaya; tabrakan baru membuat anjing penyebab berhenti mengejar.
## Pemilik lalu menerapkan `hasil.tabrak`: `Tabrakan.terapkan_ke_sepeda`, `SkorRute.putus_combo`, bunyi dan visual tabrakan.
## Bel (`terapkan_bel`) memakai tabel reaksi `Bel.REAKSI_JENIS`. `dt` 0 (jeda) = tidak ada yang berubah.

enum Jenis { ANJING, MOBIL }
## Peristiwa rintangan untuk bunyi dan visual (SOUND_DESIGN 4.3): masuk status tanda, mulai bergerak, mundur karena bel.
enum Peristiwa { ANJING_WASPADA, ANJING_MENGEJAR, ANJING_MUNDUR, MOBIL_TANDA, MOBIL_MUNDUR }

## Nama jenis di data segmen (`SegmenRute.JENIS_OBJEK`) -> jenis.
const JENIS_DATA: Dictionary = {
	"anjing_penjaga": Jenis.ANJING,
	"mobil_garasi": Jenis.MOBIL,
}


## Satu rintangan di rute.
class Item extends RefCounted:
	## Indeks di `Keadaan.daftar` (tetap sepanjang rute).
	var id: int = 0
	var jenis: Jenis = Jenis.ANJING
	## Nama jenis di data (`anjing_penjaga`, `mobil_garasi`).
	var nama_jenis: String = ""
	## Keadaan mesin sesuai jenis (yang lain null).
	var anjing: AnjingPenjaga.Keadaan = null
	var mobil: MobilGarasi.Keadaan = null

	func salin() -> Item:
		var baru: Item = Item.new()
		baru.id = id
		baru.jenis = jenis
		baru.nama_jenis = nama_jenis
		baru.anjing = anjing
		baru.mobil = mobil
		return baru


## Keadaan rintangan satu rute dan tabrakan sepeda.
class Keadaan extends RefCounted:
	var daftar: Array[Item] = []
	var tabrakan: Tabrakan.Keadaan = Tabrakan.awal()


## Satu peristiwa rintangan.
class Kejadian extends RefCounted:
	var id: int = 0
	var nama_jenis: String = ""
	var peristiwa: Peristiwa = Peristiwa.ANJING_WASPADA


## Hasil satu langkah.
class Hasil extends RefCounted:
	var keadaan: Keadaan = null
	## Peristiwa langkah ini, urut id.
	var kejadian: Array[Kejadian] = []
	## True bila langkah ini terjadi tabrakan baru; `id_tabrak` dan `jenis_tabrak` (nama data) penyebabnya (AC-8).
	var tabrak: bool = false
	var id_tabrak: int = -1
	var jenis_tabrak: String = ""


## Hasil bel.
class HasilBel extends RefCounted:
	var keadaan: Keadaan = null
	## Id rintangan yang bereaksi.
	var bereaksi: Array[int] = []
	var kejadian: Array[Kejadian] = []


## Rintangan rute `rute` (urut maju, sama dengan `rute.objek`), semua di awal, tanpa tabrakan.
static func dari_rute(rute: RouteBuilder.Rute) -> Keadaan:
	return dari_objek(rute.objek)


## Rintangan dari daftar objek rute. Jenis yang tidak dikenal dilewati (pemuat sudah menolaknya).
static func dari_objek(objek: Array[RouteBuilder.ObjekRute]) -> Keadaan:
	var k: Keadaan = Keadaan.new()
	for o: RouteBuilder.ObjekRute in objek:
		if not JENIS_DATA.has(o.jenis):
			continue
		var item: Item = Item.new()
		item.id = k.daftar.size()
		item.jenis = JENIS_DATA[o.jenis]
		item.nama_jenis = o.jenis
		var sisi: LoperAnim.Sisi = SegmenRute.sisi_dari_nama(o.jalur)
		match item.jenis:
			Jenis.ANJING:
				item.anjing = AnjingPenjaga.baru(o.maju_ubin, sisi, o.tanda_ubin)
			Jenis.MOBIL:
				item.mobil = MobilGarasi.baru(o.maju_ubin, sisi, o.tanda_ubin)
		k.daftar.append(item)
	return k


## Satu langkah dunia sesudah sepeda digerakkan (urutan di atas). Masukan tidak diubah.
static func langkah(k: Keadaan, sepeda_maju: float, sepeda_lateral: float, sepeda_kecepatan_ud: float, dt: float) -> Hasil:
	var hasil: Hasil = Hasil.new()
	var baru: Keadaan = Keadaan.new()
	baru.tabrakan = k.tabrakan
	hasil.keadaan = baru
	for lama: Item in k.daftar:
		var item: Item = lama.salin()
		match item.jenis:
			Jenis.ANJING:
				item.anjing = AnjingPenjaga.langkah(lama.anjing, sepeda_maju, sepeda_lateral, sepeda_kecepatan_ud, dt)
				_catat_anjing(hasil.kejadian, item, lama.anjing.status)
			Jenis.MOBIL:
				item.mobil = MobilGarasi.langkah(lama.mobil, sepeda_maju, dt)
				_catat_mobil(hasil.kejadian, item, lama.mobil.status)
		baru.daftar.append(item)
	var t: Tabrakan.Hasil = Tabrakan.langkah(k.tabrakan, Tabrakan.kotak_sepeda(sepeda_maju, sepeda_lateral), kandidat_tabrakan(baru), dt)
	baru.tabrakan = t.keadaan
	if t.tabrak:
		hasil.tabrak = true
		hasil.id_tabrak = t.id
		hasil.jenis_tabrak = t.jenis
		var item: Item = baru.daftar[t.id]
		if item.jenis == Jenis.ANJING:
			item.anjing = AnjingPenjaga.kena_tabrak(item.anjing)
	return hasil


## Bentuk rintangan yang bisa menabrak sekarang (berbahaya), urut id.
static func kandidat_tabrakan(k: Keadaan) -> Array[Tabrakan.Kandidat]:
	var hasil: Array[Tabrakan.Kandidat] = []
	for item: Item in k.daftar:
		if berbahaya(item):
			hasil.append(Tabrakan.kandidat(item.id, item.nama_jenis, kotak(item)))
	return hasil


## Bel dibunyikan dengan sepeda di maju `sepeda_maju` (pemanggil hanya memanggilnya untuk ketukan yang berbunyi, `Bel.berbunyi`): tiap
## rintangan dalam jangkauan bereaksi menurut `Bel.REAKSI_JENIS`. Masukan tidak diubah.
static func terapkan_bel(k: Keadaan, sepeda_maju: float) -> HasilBel:
	var hasil: HasilBel = HasilBel.new()
	var baru: Keadaan = Keadaan.new()
	baru.tabrakan = k.tabrakan
	hasil.keadaan = baru
	for lama: Item in k.daftar:
		var item: Item = lama.salin()
		if Bel.dalam_jangkauan(sepeda_maju, posisi(item).y):
			match Bel.reaksi(item.nama_jenis):
				Bel.Reaksi.MUNDUR:
					if _mundur_karena_bel(item):
						hasil.bereaksi.append(item.id)
						hasil.kejadian.append(_kejadian(item, Peristiwa.ANJING_MUNDUR))
		baru.daftar.append(item)
	return hasil


## Bentuk tabrakan rintangan di bidang tanah, koordinat jalan (x = lateral, y = maju), ubin.
static func kotak(item: Item) -> Rect2:
	if item.jenis == Jenis.MOBIL:
		return MobilGarasi.kotak(item.mobil)
	return AnjingPenjaga.kotak(item.anjing)


## True bila rintangan bisa menabrak sekarang.
static func berbahaya(item: Item) -> bool:
	if item.jenis == Jenis.MOBIL:
		return MobilGarasi.berbahaya(item.mobil)
	return AnjingPenjaga.berbahaya(item.anjing)


## Titik gambar rintangan (x = lateral, y = maju), ubin: pusat anjing; mobil = pusat bentuknya.
static func posisi(item: Item) -> Vector2:
	if item.jenis == Jenis.MOBIL:
		return MobilGarasi.kotak(item.mobil).get_center()
	return Vector2(item.anjing.lateral_ubin, item.anjing.maju_ubin)


## Nama animasi sprite (kunci `anim` di JSON sheet rintangan).
static func animasi(item: Item) -> String:
	if item.jenis == Jenis.MOBIL:
		return MobilGarasi.animasi(item.mobil)
	return AnjingPenjaga.animasi(item.anjing)


## True bila sprite rintangan digambar dicerminkan mendatar (bagian B, usulan; sheet dari `tools/env_art/fase3.py` hanya punya satu arah):
## - anjing `PULANG` atau `MUNDUR` (sesudah kaget): sheet `lari` menghadap maju, anjing bergerak mundur ke rumahnya;
## - anjing `dekat` yang duduk atau waspada (`DIAM`, `WASPADA`): sheet `duduk`/`gonggong` menghadap jalan dari sisi seberang (kanan bawah
##   layar); dicerminkan anjing di sisi dekat menghadap ke belakang sepanjang jalan, ke arah sepeda yang datang;
## - mobil: tidak pernah (sheet = mobil sisi seberang, bagasi ke jalan; data perumahan hanya punya mobil `seberang`).
static func cermin_sprite(item: Item) -> bool:
	if item.jenis != Jenis.ANJING:
		return false
	match item.anjing.status:
		AnjingPenjaga.Status.PULANG:
			return true
		AnjingPenjaga.Status.MUNDUR:
			return not AnjingPenjaga.ikon_seru(item.anjing)
		AnjingPenjaga.Status.DIAM, AnjingPenjaga.Status.WASPADA:
			return item.anjing.sisi == LoperAnim.Sisi.DEKAT
	return false


## Tinggi kotak penutup rintangan untuk `PenutupPemain`, ubin (`RINTANGAN_*_TINGGI_UBIN`).
static func tinggi_penutup(item: Item) -> float:
	return Config.RINTANGAN_MOBIL_TINGGI_UBIN if item.jenis == Jenis.MOBIL else Config.RINTANGAN_ANJING_TINGGI_UBIN


## True selama ikon "!" tampil di atas rintangan (anjing yang kaget karena bel).
static func ikon_seru(item: Item) -> bool:
	return item.jenis == Jenis.ANJING and AnjingPenjaga.ikon_seru(item.anjing)


## Rintangan yang bisa terlihat di jendela daur dari `dari_maju` sampai `sampai_maju` (ubin; posisi gambar sekarang di dalam rentang).
static func di_rentang(k: Keadaan, dari_maju: float, sampai_maju: float) -> Array[Item]:
	var hasil: Array[Item] = []
	for item: Item in k.daftar:
		var maju: float = posisi(item).y
		if maju >= dari_maju and maju <= sampai_maju:
			hasil.append(item)
	return hasil


static func _mundur_karena_bel(item: Item) -> bool:
	if item.jenis != Jenis.ANJING or not AnjingPenjaga.bisa_dengar_bel(item.anjing):
		return false
	item.anjing = AnjingPenjaga.dengar_bel(item.anjing)
	return true


static func _catat_anjing(kejadian: Array[Kejadian], item: Item, status_lama: AnjingPenjaga.Status) -> void:
	var sekarang: AnjingPenjaga.Status = item.anjing.status
	if sekarang == status_lama:
		return
	if sekarang == AnjingPenjaga.Status.WASPADA:
		kejadian.append(_kejadian(item, Peristiwa.ANJING_WASPADA))
	elif sekarang == AnjingPenjaga.Status.MENGEJAR:
		if status_lama == AnjingPenjaga.Status.DIAM:
			kejadian.append(_kejadian(item, Peristiwa.ANJING_WASPADA))
		kejadian.append(_kejadian(item, Peristiwa.ANJING_MENGEJAR))


static func _catat_mobil(kejadian: Array[Kejadian], item: Item, status_lama: MobilGarasi.Status) -> void:
	var sekarang: MobilGarasi.Status = item.mobil.status
	if sekarang == status_lama:
		return
	if sekarang == MobilGarasi.Status.TANDA:
		kejadian.append(_kejadian(item, Peristiwa.MOBIL_TANDA))
	elif sekarang == MobilGarasi.Status.MUNDUR or sekarang == MobilGarasi.Status.BERHENTI:
		if status_lama == MobilGarasi.Status.DIAM:
			kejadian.append(_kejadian(item, Peristiwa.MOBIL_TANDA))
		if status_lama != MobilGarasi.Status.MUNDUR:
			kejadian.append(_kejadian(item, Peristiwa.MOBIL_MUNDUR))


static func _kejadian(item: Item, peristiwa: Peristiwa) -> Kejadian:
	var k: Kejadian = Kejadian.new()
	k.id = item.id
	k.nama_jenis = item.nama_jenis
	k.peristiwa = peristiwa
	return k
