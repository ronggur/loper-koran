class_name SpriteKoran
extends RefCounted
## Sprite koran yang digambar di rute (run fase5a bagian B, D-3a sampai D-3c): bayangan menurut tinggi, koran berputar di udara, dan koran tergeletak, logika murni.
##
## Menyusun daftar `DefSprite.Item` untuk `KoranGambar` mode sprite. Lintasan, tinggi, dan waktu semuanya dari `KoranLempar` (tidak ada rumus lintasan atau bayangan kedua di sini);
## yang berubah dari placeholder hanya apa yang digambar. Lapisan `TANAH` (di bawah objek dunia): bayangan koran terbang dan koran tergeletak di teras atau rumput. Lapisan `UDARA`
## (di atas objek dunia): koran berputar dan koran yang bertumpu di kotak surat (kotak surat ada di lapisan objek, jadi koran di atasnya harus lebih tinggi).

const SPRITE_PUTAR: String = "prop_koran_putar"
const SPRITE_BAYANGAN: String = "prop_koran_bayangan"
const SPRITE_TERLIPAT: String = "prop_koran_terlipat"


## Indeks frame bayangan (0 sampai 2) untuk koran setinggi `tinggi_ubin`: frame yang lebarnya (`Config.KORAN_BAYANGAN_FRAME_LEBAR_PX`) terdekat dengan
## `KoranLempar.lebar_bayangan_px`; selisih sama = frame yang lebih lebar. Tinggi 0 = frame 0 (10 px), semakin tinggi semakin kecil (tidak pernah ke frame yang lebih lebar).
static func frame_bayangan(tinggi_ubin: float) -> int:
	var lebar: int = KoranLempar.lebar_bayangan_px(tinggi_ubin)
	var terbaik: int = 0
	var selisih_terbaik: int = absi(lebar - Config.KORAN_BAYANGAN_FRAME_LEBAR_PX[0])
	for i: int in range(1, Config.KORAN_BAYANGAN_FRAME_LEBAR_PX.size()):
		var selisih: int = absi(lebar - Config.KORAN_BAYANGAN_FRAME_LEBAR_PX[i])
		if selisih < selisih_terbaik:
			terbaik = i
			selisih_terbaik = selisih
	return terbaik


## Item gambar lapisan `TANAH` untuk satu koran: bayangan di titik tanah koran selama terbang, koran tergeletak (teras atau rumput) di titik mendarat sesudah mendarat. Kosong bila
## belum lepas, atau koran sudah mendarat di atas kotak surat (digambar lapisan `UDARA`).
static func item_tanah(koran: KoranLempar.Koran) -> Array[DefSprite.Item]:
	var hasil: Array[DefSprite.Item] = []
	if KoranLempar.di_udara(koran):
		var p: Vector3 = KoranLempar.posisi(koran)
		var titik: Vector2 = Iso.posisi_gambar(Vector2(p.x, p.y))
		hasil.append(DefSprite.Item.buat(SPRITE_BAYANGAN, frame_bayangan(p.z), DefSprite.pojok(SPRITE_BAYANGAN, titik)))
	elif koran.mendarat and koran.permukaan != PermukaanKoran.Permukaan.KOTAK_SURAT:
		hasil.append(_item_diam(koran))
	return hasil


## Item gambar lapisan `UDARA` untuk satu koran: koran berputar (`KoranLempar.frame_putar`) di posisi udaranya selama terbang, koran di atas kotak surat sesudah mendarat di sana.
static func item_udara(koran: KoranLempar.Koran) -> Array[DefSprite.Item]:
	var hasil: Array[DefSprite.Item] = []
	if KoranLempar.di_udara(koran):
		var p: Vector3 = KoranLempar.posisi(koran)
		var pusat: Vector2 = Iso.posisi_gambar_tinggi(Vector2(p.x, p.y), p.z) - Vector2(0, Config.KORAN_PUTAR_PUSAT_ATAS_PX)
		var frame: int = KoranLempar.frame_putar(koran, DefSprite.jumlah_frame(SPRITE_PUTAR))
		hasil.append(DefSprite.Item.buat(SPRITE_PUTAR, frame, DefSprite.pojok(SPRITE_PUTAR, pusat)))
	elif koran.mendarat and koran.permukaan == PermukaanKoran.Permukaan.KOTAK_SURAT:
		hasil.append(_item_diam(koran))
	return hasil


## Item koran tergeletak untuk koran yang sudah mendarat: sprite menurut permukaan, pijak di `titik_diam`.
static func _item_diam(koran: KoranLempar.Koran) -> DefSprite.Item:
	var nama: String = PermukaanKoran.nama_sprite(koran.permukaan)
	return DefSprite.Item.buat(nama, 0, DefSprite.pojok(nama, Iso.posisi_gambar(koran.titik_diam)))
