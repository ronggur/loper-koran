class_name MedanKoran
extends RefCounted
## Medan sasaran koran: zona yang menilai titik mendarat dan kotak yang menutupinya dari kamera, logika murni (run fase3a-rute).
##
## `KoranLempar` menilai dan membentuk elips garis bidik dari medan ini. `null` berarti jalan uji (zona kavling berkala dan rumah graybox,
## perilaku run 2A dan 2B tidak berubah). `dari_rute` membuat medan rumah satu rute (AC-10): zona kotak surat, halaman, teras, dan jendela
## tiap rumah (`ZonaSasaran.zona_rumah`) dan kotak rumah penutup (`PenutupPemain.dari_rumah`); hanya rumah di sekitar titik yang dilihat
## (pencarian biner `JendelaRute`), bukan seluruh rute, dan penilaian tetap dari titik mendarat saja. Satu kelas konkret (bukan turunan):
## pewarisan `MedanKoran` -> medan rute membuat skrip data rute tertahan di akhir proses (GDScript, dites di LOG run 3A bagian B).

## Rumah rute (urut maju, milik `RouteBuilder.Rute`, tidak diubah); kosong = medan jalan uji.
var _rumah: Array[RouteBuilder.RumahRute] = []
## True bila medan ini medan rute.
var _rute: bool = false


## Medan untuk `rute` (rumah kedua sisi).
static func dari_rute(rute: RouteBuilder.Rute) -> MedanKoran:
	var medan: MedanKoran = MedanKoran.new()
	medan._rumah = rute.rumah
	medan._rute = true
	return medan


## True bila ini medan rute (false = jalan uji).
func adalah_rute() -> bool:
	return _rute


## Zona kandidat di sekitar `titik_dunia` (ubin; y dunia = -maju). Jalan uji: kavling di sekitar titik (`ZonaSasaran.zona_jalan_uji_sekitar`).
## Rute: zona rumah dengan kavling di sekitar maju titik, satu petak cadangan tiap ujung (`ZonaSasaran.zona_rute`).
func zona_sekitar(titik_dunia: Vector2) -> Array[ZonaSasaran.Zona]:
	var maju: float = ZonaSasaran.ke_jalan(titik_dunia).y
	if not _rute:
		return ZonaSasaran.zona_jalan_uji_sekitar(maju)
	if not is_finite(maju):
		return []
	var rentang: Vector2i = JendelaRute.rentang(_rumah, maju - float(Config.RUTE_PETAK_UBIN), maju + float(Config.RUTE_PETAK_UBIN))
	return ZonaSasaran.zona_rute(_rumah.slice(rentang.x, rentang.y))


## True bila titik di dunia setinggi `tinggi_ubin` tertutup rumah dari kamera iso 2:1. Jalan uji: rumah graybox seberang. Rute: sinar
## ke kamera bergeser maju mundur selama naik, jadi rumah yang bisa menutupi titik ada di belakangnya (maju lebih kecil): jendela dari dua
## petak di belakang sampai satu petak di depan.
func tertutup_titik(titik_dunia: Vector2, tinggi_ubin: float) -> bool:
	if not _rute:
		return ZonaSasaran.tertutup_rumah_jalan_uji(titik_dunia, tinggi_ubin)
	var maju: float = ZonaSasaran.ke_jalan(titik_dunia).y
	if not is_finite(maju) or not is_finite(tinggi_ubin):
		return false
	var rentang: Vector2i = JendelaRute.rentang(_rumah, maju - float(Config.RUTE_PETAK_UBIN * 2), maju + float(Config.RUTE_PETAK_UBIN))
	for i: int in range(rentang.x, rentang.y):
		var objek: PenutupPemain.Objek = PenutupPemain.dari_rumah(_rumah[i])
		if ZonaSasaran.tertutup_kotak(titik_dunia, tinggi_ubin, objek.tapak, objek.tinggi_ubin):
			return true
	return false


## Zona di sekitar `titik_dunia` menurut `medan` (null = jalan uji).
static func zona(medan: MedanKoran, titik_dunia: Vector2) -> Array[ZonaSasaran.Zona]:
	if medan == null:
		return ZonaSasaran.zona_jalan_uji_sekitar(ZonaSasaran.ke_jalan(titik_dunia).y)
	return medan.zona_sekitar(titik_dunia)


## True bila titik tertutup menurut `medan` (null = jalan uji).
static func tertutup(medan: MedanKoran, titik_dunia: Vector2, tinggi_ubin: float) -> bool:
	if medan == null:
		return ZonaSasaran.tertutup_rumah_jalan_uji(titik_dunia, tinggi_ubin)
	return medan.tertutup_titik(titik_dunia, tinggi_ubin)
