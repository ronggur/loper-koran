class_name PenutupPemain
extends RefCounted
## Aturan objek yang menutupi pemain, SATU tempat (GDD 2 prinsip 3, ART_DIRECTION 2.2, TECH_PLAN Fase 3; AC-15 run fase3a-rute,
## usulan). Logika murni dari kamera isometrik 2:1; penerapnya (membuat objek semi-transparan) satu simpul di scene rute, bukan per
## objek rumah.
##
## Aturan: objek = kotak bertapak persegi di bidang tanah (koordinat jalan: x = lateral, y = maju) setinggi `tinggi_ubin`.
## Titik kaki pemain (tinggi 0) adalah titik pemain yang paling mudah tertutup: titik di (x, y, z) dan (x + d, y + d, z + d) jatuh di
## layar yang sama dan d > 0 lebih dekat kamera (`ZonaSasaran.tertutup_kotak`), jadi titik yang lebih tinggi hanya tertutup bila
## kakinya tertutup. Pemain "tertutup" bila kakinya tertutup kotak; sebagian badan yang tertutup juga dihitung. Titik tepat di tepi
## tapak atau tepat di puncak tidak tertutup (pola `tertutup_kotak`, QA-004 run fase2a-lemparan).
##
## Catatan geometri: rumah di tepi jalan (lateral 3 atau lebih) hampir tidak pernah menutupi pemain di lebar jalan resmi (kaki di
## lateral -1 sampai 1 butuh d >= 2 untuk sampai ke tapak, sedangkan atap rumah 2 ubin). Aturannya umum untuk objek yang lebih dekat
## ke jalan (mobil, pohon, tenda) di fase berikutnya.


## Satu objek penutup: tapak di bidang tanah (koordinat jalan) dan tinggi kotak.
class Objek extends RefCounted:
	## Persegi tapak, ubin (x = lateral dari garis tengah jalan, negatif = seberang; y = maju dari awal rute).
	var tapak: Rect2 = Rect2()
	## Tinggi kotak dari tanah, ubin.
	var tinggi_ubin: float = 0.0
	## Pengenal bebas (id rumah atau nama objek), untuk penerap di scene.
	var id: String = ""


## Objek baru.
static func buat(tapak: Rect2, tinggi_ubin: float, id: String = "") -> Objek:
	var objek: Objek = Objek.new()
	objek.tapak = tapak
	objek.tinggi_ubin = tinggi_ubin
	objek.id = id
	return objek


## True bila kotak `objek` menutupi pemain yang berdiri di `posisi_pemain` (dunia, ubin: y dunia = -maju).
static func menutupi(posisi_pemain: Vector2, objek: Objek) -> bool:
	if objek == null or not posisi_pemain.is_finite():
		return false
	return ZonaSasaran.tertutup_kotak(posisi_pemain, 0.0, objek.tapak, objek.tinggi_ubin)


## Indeks objek di `daftar` yang menutupi pemain (urut daftar). Kosong bila tidak ada.
static func indeks_menutupi(posisi_pemain: Vector2, daftar: Array[Objek]) -> PackedInt32Array:
	var hasil: PackedInt32Array = PackedInt32Array()
	for i: int in range(daftar.size()):
		if menutupi(posisi_pemain, daftar[i]):
			hasil.append(i)
	return hasil


## Alpha gambar objek: `RUTE_PENUTUP_ALFA` bila menutupi pemain, 1,0 bila tidak.
static func alfa(menutupi_pemain: bool) -> float:
	return Config.RUTE_PENUTUP_ALFA if menutupi_pemain else 1.0


## Tapak kotak rumah rute (koordinat jalan) untuk rumah bersisi `sisi` dengan awal kavling `maju_awal_ubin`: seberang dari kaki fasad
## (`JALAN_UJI_RUMAH_X_UBIN`) ke arah seberang sedalam `RUTE_RUMAH_DALAM_UBIN`, dekat dari kaki fasad (`RUTE_RUMAH_DEKAT_X_UBIN`) ke arah
## dekat; maju dari `maju_awal_ubin + JALAN_UJI_RUMAH_MAJU_UBIN` sepanjang `RUTE_RUMAH_PANJANG_UBIN` (sama dengan halaman zona).
## Sisi `TIDAK_ADA` = persegi kosong.
static func tapak_rumah(sisi: LoperAnim.Sisi, maju_awal_ubin: float) -> Rect2:
	var maju: float = maju_awal_ubin + Config.JALAN_UJI_RUMAH_MAJU_UBIN
	if sisi == LoperAnim.Sisi.SEBERANG:
		return Rect2(Config.JALAN_UJI_RUMAH_X_UBIN - Config.RUTE_RUMAH_DALAM_UBIN, maju, Config.RUTE_RUMAH_DALAM_UBIN, Config.RUTE_RUMAH_PANJANG_UBIN)
	if sisi == LoperAnim.Sisi.DEKAT:
		return Rect2(Config.RUTE_RUMAH_DEKAT_X_UBIN, maju, Config.RUTE_RUMAH_DALAM_UBIN, Config.RUTE_RUMAH_PANJANG_UBIN)
	return Rect2()


## Objek penutup dari rumah rute (tapak dan tinggi dari `Config.RUTE_RUMAH_*`).
static func dari_rumah(rumah: RouteBuilder.RumahRute) -> Objek:
	return buat(tapak_rumah(rumah.sisi, rumah.maju_ubin), Config.RUTE_RUMAH_TINGGI_UBIN, rumah.id)
