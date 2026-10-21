class_name TembokDekat
extends RefCounted
## Tembok belakang rendah rumah sisi dekat: potongan sprite, letak, dan berkasnya, logika murni (run fase5b-tembok-dekor bagian B1, D-2 dan D-3, AC-4, AC-7; usulan).
##
## Satu rumah `dekat` = `RUTE_RUMAH_PANJANG_UBIN` (3) modul satu ubin berurutan dari `maju_ubin` rumah, satu varian untuk semuanya (`VarianTembok.pilih`
## atas id rumah), ditambah satu `house_tembok_tiang` penutup. Letak potongan tidak mengubah tapak logika rumah (`PenutupPemain.tapak_rumah`): tembok
## hanya gambar, tidak penghalang, tidak masuk tabrakan, penutup, medan koran, atau zona.
##
## Arah sprite: modul digambar dari pijaknya ke arah mundur (maju mengecil; sambungan modul berikut = geser layar (-32, +16), `Config.SPRITE_TEMBOK_GESER_PX`)
## dan tiang awalnya ada di pijak. `maju_ubin` sebuah potongan = ujung BELAKANG modul (maju terkecil), jadi modul rumah di maju m ada di m, m+1, m+2 dan
## pijaknya di ujung depan (maju + `RUTE_TEMBOK_MODUL_UBIN`). Tiang penutup di maju m (ujung belakang rantai), karena rantai tumbuh ke belakang dari modul
## pertama. Spesifikasi D-3 menulis tiang di m+3 (arah rantai terbalik); arah sprite yang menentukan, dicatat di LOG run.

## Folder sprite tembok (satu folder dengan rumah perumahan).
const FOLDER: String = "res://assets/sprites/houses/perumahan"
## Awalan nama sprite tembok.
const AWALAN: String = "house_tembok_"
## Nama sprite tiang penutup.
const NAMA_TIANG: String = "house_tembok_tiang"


## Satu potongan tembok yang digambar.
class Potongan extends RefCounted:
	## Nama sprite (`house_tembok_<varian>` atau `house_tembok_tiang`).
	var nama: String = ""
	## Nama varian (`polos`, ..., `pot`); kosong untuk tiang.
	var varian: String = ""
	## True bila ini tiang penutup.
	var tiang: bool = false
	## Ujung belakang potongan, ubin dari awal rute (maju terkecil; modul membentang sampai `+ RUTE_TEMBOK_MODUL_UBIN`).
	var maju_ubin: float = 0.0
	## Lateral pusat tembok, ubin dari garis tengah jalan (positif = dekat).
	var lateral_ubin: float = 0.0


## Banyaknya modul satu rumah (`RUTE_RUMAH_PANJANG_UBIN` / `RUTE_TEMBOK_MODUL_UBIN`).
static func jumlah_modul() -> int:
	return int(round(Config.RUTE_RUMAH_PANJANG_UBIN / Config.RUTE_TEMBOK_MODUL_UBIN))


## Potongan tembok rumah: modul berurut dari maju terkecil lalu tiang penutup terakhir. Kosong bila rumah bukan sisi `dekat` (rumah seberang tidak bertembok).
static func potongan(rumah: RouteBuilder.RumahRute) -> Array[Potongan]:
	var hasil: Array[Potongan] = []
	if rumah == null or rumah.sisi != LoperAnim.Sisi.DEKAT:
		return hasil
	var varian: String = VarianTembok.pilih(rumah.id)
	for i: int in range(jumlah_modul()):
		var modul: Potongan = Potongan.new()
		modul.varian = varian
		modul.nama = nama_modul(varian)
		modul.maju_ubin = rumah.maju_ubin + float(i) * Config.RUTE_TEMBOK_MODUL_UBIN
		modul.lateral_ubin = Config.RUTE_TEMBOK_X_UBIN
		hasil.append(modul)
	var ujung: Potongan = Potongan.new()
	ujung.nama = NAMA_TIANG
	ujung.tiang = true
	ujung.maju_ubin = rumah.maju_ubin
	ujung.lateral_ubin = Config.RUTE_TEMBOK_X_UBIN
	hasil.append(ujung)
	return hasil


## Nama sprite modul varian `varian`.
static func nama_modul(varian: String) -> String:
	return AWALAN + varian


## Nama semua sprite tembok: empat modul (urut `Config.RUTE_TEMBOK_VARIAN`) lalu tiang.
static func semua_nama() -> Array[String]:
	var hasil: Array[String] = []
	for varian: String in Config.RUTE_TEMBOK_VARIAN:
		hasil.append(nama_modul(varian))
	hasil.append(NAMA_TIANG)
	return hasil


## Jalur PNG sprite tembok bernama `nama`.
static func jalur_png(nama: String) -> String:
	return "%s/%s.png" % [FOLDER, nama]


## Ukuran sel sprite tembok (modul dan tiang sama), piksel.
static func sel() -> Vector2i:
	return Vector2i(Config.SPRITE_TEMBOK[0], Config.SPRITE_TEMBOK[1])


## Titik pijak di dalam sel (garis tengah tembok di awal modul), piksel.
static func pijak() -> Vector2i:
	return Vector2i(Config.SPRITE_TEMBOK[Config.SPRITE_INDEKS_PIJAK_X], Config.SPRITE_TEMBOK[Config.SPRITE_INDEKS_PIJAK_Y])


## Titik pijak gambar potongan di dunia (ubin; y dunia = -maju): modul di ujung depannya, tiang di `maju_ubin` sendiri.
static func titik_dunia(potong: Potongan) -> Vector2:
	var maju: float = potong.maju_ubin if potong.tiang else potong.maju_ubin + Config.RUTE_TEMBOK_MODUL_UBIN
	return Vector2(potong.lateral_ubin, -maju)
