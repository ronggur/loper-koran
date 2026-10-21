class_name VfxAntaran
extends RefCounted
## Bintang kena dan koin tip dari sprite gelombang 1, logika murni (run fase5a bagian B, D-5, ART_DIRECTION 6.7; DESIGN_SPEC 3.6).
##
## Sumbernya entri `UmpanMelayang` (hanya antaran sah `SkorRute.Status.ANTAR` yang membuat entri, jadi koran netral, tidak sah, dan meleset tidak menyalakan keduanya). Waktu animasi = lama entri
## sudah tampil (`UMPAN_MELAYANG_DETIK` dikurangi sisa), yang ikut dt efektif, jadi jeda membekukannya. Keduanya sekali main: sesudah frame terakhir tidak digambar lagi.
## Tulisan "+5" dipanggang di sprite koin, jadi sprite dipakai hanya bila tip sama dengan `UMPAN_KOIN_TIP_SPRITE_NILAI`; selain itu baris tip label (`RUTE_UMPAN_TIP`) tetap tampil.

const SPRITE_BINTANG: String = "vfx_bintang_kena"
const SPRITE_KOIN: String = "vfx_koin_tip"


## True bila tip `tip` ditampilkan lewat sprite koin (bukan baris tip label): ada tip dan nilainya sama dengan nilai yang dipanggang di sprite.
static func koin_sprite(tip: int) -> bool:
	return tip > 0 and tip == Config.UMPAN_KOIN_TIP_SPRITE_NILAI


## Lama entri sudah tampil, detik (0 saat muncul).
static func detik_tampil(e: UmpanMelayang.Entri) -> float:
	return maxf(Config.UMPAN_MELAYANG_DETIK - e.sisa_detik, 0.0)


## Indeks frame bintang kena entri `e` (sekali main, 15 fps); -1 bila sudah selesai.
static func frame_bintang(e: UmpanMelayang.Entri) -> int:
	return DefSprite.frame_sekali(detik_tampil(e), Config.UMPAN_BINTANG_FPS, DefSprite.jumlah_frame(SPRITE_BINTANG))


## Indeks frame koin tip entri `e` (sekali main, 10 fps); -1 bila entri tanpa tip sprite atau sudah selesai.
static func frame_koin(e: UmpanMelayang.Entri) -> int:
	if not koin_sprite(e.tip):
		return -1
	return DefSprite.frame_sekali(detik_tampil(e), Config.UMPAN_KOIN_TIP_FPS, DefSprite.jumlah_frame(SPRITE_KOIN))


## Item gambar entri `e` di ruang gambar dunia: bintang (pijak = pusat di titik mendarat) lalu koin (pijak di titik mendarat, naik di dalam sel), yang sudah selesai dilewati.
static func item_entri(e: UmpanMelayang.Entri) -> Array[DefSprite.Item]:
	var hasil: Array[DefSprite.Item] = []
	var titik: Vector2 = Iso.posisi_gambar(e.titik_dunia)
	var bintang: int = frame_bintang(e)
	if bintang >= 0:
		hasil.append(DefSprite.Item.buat(SPRITE_BINTANG, bintang, DefSprite.pojok(SPRITE_BINTANG, titik)))
	var koin: int = frame_koin(e)
	if koin >= 0:
		hasil.append(DefSprite.Item.buat(SPRITE_KOIN, koin, DefSprite.pojok(SPRITE_KOIN, titik)))
	return hasil


## Item gambar semua entri `daftar` (urut).
static func item_semua(daftar: Array[UmpanMelayang.Entri]) -> Array[DefSprite.Item]:
	var hasil: Array[DefSprite.Item] = []
	for e: UmpanMelayang.Entri in daftar:
		hasil.append_array(item_entri(e))
	return hasil
