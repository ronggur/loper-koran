class_name DefSprite
extends RefCounted
## Definisi sprite gelombang 1 yang dipasang di rute dan pemetaan frame ke gambar, logika murni (run fase5a bagian B, D-3 sampai D-6, ART_DIRECTION 6.2, 6.3, 6.7, 6.9).
##
## Ukuran sel, jumlah frame, dan titik pijak tiap sprite dari `Config.SPRITE_*` (sama dengan JSON aset, dijaga tes). Sprite = sheet satu baris, frame berjajar kiri ke kanan. Node
## tidak menghitung letak gambar sendiri: `region`, `pojok`, dan `Item` dari sini, lalu `GambarSprite` menggambarnya sebagai tekstur Nearest di piksel game bulat. Tanpa node, tanpa waktu.

## Folder sprite properti (koran, kotak surat).
const FOLDER_PROPS: String = "res://assets/sprites/props"
## Folder sprite efek dan hiasan misi.
const FOLDER_VFX: String = "res://assets/sprites/vfx"

## Nama sprite yang dipasang (urutan = daftar D-1 run fase5a).
const NAMA: Array[String] = [
	"prop_koran_putar", "prop_koran_bayangan", "prop_koran_teras", "prop_koran_rumput", "prop_koran_kotak_surat", "prop_koran_terlipat",
	"vfx_debu_roda", "vfx_garis_kecepatan_a", "vfx_garis_kecepatan_b", "vfx_garis_kecepatan_c", "vfx_bintang_kena", "vfx_koin_tip", "mission_kilau",
]


## Satu sprite yang akan digambar: nama, frame, pojok kiri atas di ruang gambar node (piksel game, bulat), dan alpha.
class Item extends RefCounted:
	var nama: String = ""
	var frame: int = 0
	var pojok: Vector2 = Vector2.ZERO
	var alfa: float = 1.0

	## Item dari nama, frame, pojok, dan alpha.
	static func buat(nama_sprite: String, frame_sprite: int, pojok_sprite: Vector2, alfa_sprite: float = 1.0) -> Item:
		var item: Item = Item.new()
		item.nama = nama_sprite
		item.frame = frame_sprite
		item.pojok = pojok_sprite
		item.alfa = alfa_sprite
		return item


## Larik definisi `[lebar sel, tinggi sel, jumlah frame, pijak x, pijak y]` sprite bernama `nama_sprite`; kosong bila tidak dikenal.
static func data(nama_sprite: String) -> Array[int]:
	match nama_sprite:
		"prop_koran_putar":
			return Config.SPRITE_KORAN_PUTAR
		"prop_koran_bayangan":
			return Config.SPRITE_KORAN_BAYANGAN
		"prop_koran_teras":
			return Config.SPRITE_KORAN_TERAS
		"prop_koran_rumput":
			return Config.SPRITE_KORAN_RUMPUT
		"prop_koran_kotak_surat":
			return Config.SPRITE_KORAN_KOTAK_SURAT
		"prop_koran_terlipat":
			return Config.SPRITE_KORAN_TERLIPAT
		"vfx_debu_roda":
			return Config.SPRITE_DEBU_RODA
		"vfx_garis_kecepatan_a":
			return Config.SPRITE_GARIS_KECEPATAN_A
		"vfx_garis_kecepatan_b":
			return Config.SPRITE_GARIS_KECEPATAN_B
		"vfx_garis_kecepatan_c":
			return Config.SPRITE_GARIS_KECEPATAN_C
		"vfx_bintang_kena":
			return Config.SPRITE_BINTANG_KENA
		"vfx_koin_tip":
			return Config.SPRITE_KOIN_TIP
		"mission_kilau":
			return Config.SPRITE_MISI_KILAU
	var kosong: Array[int] = []
	return kosong


## Jalur PNG sprite bernama `nama_sprite` (properti di `props/`, efek dan kilau di `vfx/`).
static func jalur_png(nama_sprite: String) -> String:
	var folder: String = FOLDER_PROPS if nama_sprite.begins_with("prop_") else FOLDER_VFX
	return "%s/%s.png" % [folder, nama_sprite]


## Ukuran satu sel sprite, piksel; nol bila nama tidak dikenal.
static func sel(nama_sprite: String) -> Vector2i:
	var d: Array[int] = data(nama_sprite)
	return Vector2i(d[0], d[1]) if d.size() == Config.SPRITE_PANJANG else Vector2i.ZERO


## Jumlah frame sprite; 0 bila nama tidak dikenal.
static func jumlah_frame(nama_sprite: String) -> int:
	var d: Array[int] = data(nama_sprite)
	return d[2] if d.size() == Config.SPRITE_PANJANG else 0


## Titik pijak di dalam sel, piksel; nol bila nama tidak dikenal.
static func pijak(nama_sprite: String) -> Vector2i:
	var d: Array[int] = data(nama_sprite)
	return Vector2i(d[Config.SPRITE_INDEKS_PIJAK_X], d[Config.SPRITE_INDEKS_PIJAK_Y]) if d.size() == Config.SPRITE_PANJANG else Vector2i.ZERO


## Daerah frame `frame` di dalam PNG (frame di luar rentang diputar `posmod`); kosong bila nama tidak dikenal.
static func region(nama_sprite: String, frame: int) -> Rect2i:
	var d: Array[int] = data(nama_sprite)
	if d.size() != Config.SPRITE_PANJANG or d[2] < 1:
		return Rect2i()
	return Rect2i(posmod(frame, d[2]) * d[0], 0, d[0], d[1])


## Pojok kiri atas gambar bila titik pijak sprite diletakkan di `titik` (piksel game; hasil dibulatkan).
static func pojok(nama_sprite: String, titik: Vector2) -> Vector2:
	return titik.round() - Vector2(pijak(nama_sprite))


## Indeks frame animasi yang berputar (loop) pada waktu `detik` dengan `fps`, dari `jumlah` frame. Waktu negatif atau tidak hingga = frame 0.
static func frame_loop(detik: float, fps: float, jumlah: int) -> int:
	if jumlah < 1 or not is_finite(detik) or not is_finite(fps) or detik < 0.0 or fps <= 0.0:
		return 0
	return posmod(floori(detik * fps), jumlah)


## Indeks frame animasi sekali main pada waktu `detik` sejak mulai dengan `fps`, dari `jumlah` frame; -1 bila sudah selesai (atau belum mulai, atau masukan tidak sah).
static func frame_sekali(detik: float, fps: float, jumlah: int) -> int:
	if jumlah < 1 or not is_finite(detik) or not is_finite(fps) or detik < 0.0 or fps <= 0.0:
		return -1
	var frame: int = floori(detik * fps)
	return frame if frame < jumlah else -1
