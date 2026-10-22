class_name VfxSepeda
extends RefCounted
## Debu roda dan garis kecepatan dari sprite gelombang 1, logika murni (run fase5a bagian B, D-4, ART_DIRECTION 6.7; GDD 15).
##
## Kapan efek tampil TIDAK dihitung ulang di sini: selalu dari `UmpanBalikKecepatan` (debu tampil tepat bila `laju_debu` > 0, garis tepat bila `kekuatan_garis` > 0), jadi ambang, rem,
## kecepatan 0, dan kurangi efek sama dengan placeholder partikel. Di sini hanya: alpha, frame animasi debu (loop), dan acak varian garis (RNG berseed, diganti tiap 2 sampai 3 frame game).
## Posisi: debu dengan titik pijak (roda belakang) di `UMPAN_DEBU_ASAL_*`, garis dengan ujung kepala di `UMPAN_GARIS_SPRITE_KEPALA_*` digeser tegak lurus jalan (sebaran `UMPAN_GARIS_SEBARAN_PX`), semua di
## ruang lokal sepeda (sprite ikut sepeda; gerak mundur debu dipanggang di sprite). Kepala garis BUKAN `UMPAN_GARIS_ASAL_*`: itu titik muncul partikel yang lalu melaju mundur 60 px, jadi sprite diam di
## sana berada sekitar 13,5 px di depan posisi garis lama (umpan balik HP pemilik 2026-10-22); kepala sprite dipilih supaya pusat garis = pusat rata-rata waktu garis partikel.

const SPRITE_DEBU: String = "vfx_debu_roda"
const SPRITE_GARIS: Array[String] = ["vfx_garis_kecepatan_a", "vfx_garis_kecepatan_b", "vfx_garis_kecepatan_c"]


## Keadaan acak garis kecepatan: varian (0 sampai 2), sisa frame sampai diacak lagi, dan geseran tegak lurus jalan (piksel game).
class GarisKeadaan extends RefCounted:
	var varian: int = 0
	var sisa_frame: int = 0
	var geser_px: float = 0.0

	func salin() -> GarisKeadaan:
		var baru: GarisKeadaan = GarisKeadaan.new()
		baru.varian = varian
		baru.sisa_frame = sisa_frame
		baru.geser_px = geser_px
		return baru


## Arah ke belakang sepanjang jalan di layar (satuan, sama dengan arah partikel placeholder).
static func arah_mundur() -> Vector2:
	return -Iso.dunia_ke_layar(Iso.ARAH_MAJU).normalized()


## Arah tegak lurus jalan di layar (satuan).
static func arah_tegak() -> Vector2:
	var mundur: Vector2 = arah_mundur()
	return Vector2(-mundur.y, mundur.x)


## True bila debu roda tampil: tepat bila laju debu placeholder di atas 0 (`UmpanBalikKecepatan.laju_debu`; ambang, rem, kecepatan 0, dan kurangi efek ikut).
static func debu_tampil(kecepatan_ud: float, rem_aktif: bool, kurangi_efek: bool) -> bool:
	return UmpanBalikKecepatan.laju_debu(kecepatan_ud, rem_aktif, kurangi_efek) > 0.0


## Alpha debu: penuh, dikali `UMPAN_KURANGI_DEBU_PENGALI` bila kurangi efek.
static func debu_alfa(kurangi_efek: bool) -> float:
	return Config.UMPAN_KURANGI_DEBU_PENGALI if kurangi_efek else 1.0


## True bila garis kecepatan tampil: tepat bila `UmpanBalikKecepatan.kekuatan_garis` > 0 (mati saat kurangi efek).
static func garis_tampil(kecepatan_ud: float, kurangi_efek: bool) -> bool:
	return UmpanBalikKecepatan.kekuatan_garis(kecepatan_ud, kurangi_efek) > 0.0


## Alpha garis: mengikuti kekuatan garis (0 sampai 1).
static func garis_alfa(kecepatan_ud: float, kurangi_efek: bool) -> float:
	return UmpanBalikKecepatan.kekuatan_garis(kecepatan_ud, kurangi_efek)


## Keadaan acak garis yang pertama dari `rng` (varian, sisa frame, geseran).
static func garis_awal(rng: RandomNumberGenerator) -> GarisKeadaan:
	var k: GarisKeadaan = GarisKeadaan.new()
	_acak(k, rng)
	return k


## Keadaan acak garis sesudah satu frame game: sisa frame berkurang; bila habis, varian, sisa frame, dan geseran diacak lagi dari `rng`. Masukan tidak diubah.
static func garis_maju(k: GarisKeadaan, rng: RandomNumberGenerator) -> GarisKeadaan:
	var baru: GarisKeadaan = k.salin()
	baru.sisa_frame -= 1
	if baru.sisa_frame <= 0:
		_acak(baru, rng)
	return baru


## Item debu roda untuk kecepatan, rem, kurangi efek, dan waktu animasi `detik`: satu item (frame berputar 12 fps), atau kosong bila debu tidak tampil.
static func item_debu(kecepatan_ud: float, rem_aktif: bool, kurangi_efek: bool, detik: float) -> Array[DefSprite.Item]:
	var hasil: Array[DefSprite.Item] = []
	if not debu_tampil(kecepatan_ud, rem_aktif, kurangi_efek):
		return hasil
	var asal: Vector2 = Vector2(Config.UMPAN_DEBU_ASAL_X_PX, Config.UMPAN_DEBU_ASAL_Y_PX)
	var frame: int = DefSprite.frame_loop(detik, Config.UMPAN_DEBU_SPRITE_FPS, DefSprite.jumlah_frame(SPRITE_DEBU))
	hasil.append(DefSprite.Item.buat(SPRITE_DEBU, frame, DefSprite.pojok(SPRITE_DEBU, asal), debu_alfa(kurangi_efek)))
	return hasil


## Item garis kecepatan untuk kecepatan, kurangi efek, dan keadaan acak `k`: satu item (varian `k.varian`, alpha = kekuatan), atau kosong bila garis tidak tampil.
static func item_garis(kecepatan_ud: float, kurangi_efek: bool, k: GarisKeadaan) -> Array[DefSprite.Item]:
	var hasil: Array[DefSprite.Item] = []
	if not garis_tampil(kecepatan_ud, kurangi_efek):
		return hasil
	var kepala: Vector2 = Vector2(Config.UMPAN_GARIS_SPRITE_KEPALA_X_PX, Config.UMPAN_GARIS_SPRITE_KEPALA_Y_PX) + arah_tegak() * k.geser_px
	var nama: String = SPRITE_GARIS[posmod(k.varian, SPRITE_GARIS.size())]
	hasil.append(DefSprite.Item.buat(nama, 0, DefSprite.pojok(nama, kepala), garis_alfa(kecepatan_ud, kurangi_efek)))
	return hasil


static func _acak(k: GarisKeadaan, rng: RandomNumberGenerator) -> void:
	k.varian = rng.randi_range(0, SPRITE_GARIS.size() - 1)
	k.sisa_frame = rng.randi_range(Config.UMPAN_GARIS_GANTI_MIN_FRAME, Config.UMPAN_GARIS_GANTI_MAKS_FRAME)
	k.geser_px = rng.randf_range(-Config.UMPAN_GARIS_SEBARAN_PX, Config.UMPAN_GARIS_SEBARAN_PX)
