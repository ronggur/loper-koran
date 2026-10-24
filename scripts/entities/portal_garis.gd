class_name PortalGaris
extends Sprite2D
## Portal satpam di garis akhir rute (run garis-finish-portal bagian C, G-1, AC-6, usulan): `prop_portal_satpam` melintang jalan di `RouteBuilder.Rute.panjang_ubin`.
##
## Node tipis: bingkai (0 tertutup, 1 terbuka) dari `AkhirRute.portal_bingkai` (jarak sepeda ke garis, fungsi murni), posisi dari `Iso` dan `Config.RUTE_PORTAL_LATERAL_UBIN`. Tekstur diisi scene
## (`rute.tscn`), jadi tidak ada pemuatan di `_draw` atau di tengah permainan; dua frame berjajar kiri ke kanan (`hframes`), titik pijak (kaki tiang) = `Config.RUTE_PORTAL_PIJAK_PX`.
## Anak induk Y-sort rumah dan sepeda (`RumahDaurRute`), jadi urutan gambar menurut posisi tegak titik pijak seperti rumah dan pohon: sepeda sebelum garis tergambar di depan palang, sepeda
## sesudah garis (lateral di dekat tiang) di belakang tiang. Alfa penutup pemain diurus SATU `PenerapPenutup` (kotak setinggi palang terangkat di sekitar tiang). Portal bukan penghalang:
## tidak masuk `Tabrakan`, `RintanganRute`, zona, atau penilaian lemparan. Tidak pernah didaur: satu node per scene, dipindah tiap rute disusun.

## Penerap penutup pemain (diisi scene rute).
var penerap: PenerapPenutup = null

var _panjang: float = 0.0


func _ready() -> void:
	centered = false
	hframes = Config.RUTE_PORTAL_FRAME
	offset = -Vector2(Config.RUTE_PORTAL_PIJAK_PX[0], Config.RUTE_PORTAL_PIJAK_PX[1])
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visible = false


## Titik pijak portal di dunia (ubin; y dunia = -maju) untuk rute sepanjang `panjang_ubin`.
static func titik_dunia(panjang_ubin: float) -> Vector2:
	return Vector2(Config.RUTE_PORTAL_LATERAL_UBIN, -panjang_ubin)


## Kotak penutup pemain portal (koordinat jalan: lateral, maju) untuk rute sepanjang `panjang_ubin`.
static func kotak_penutup(panjang_ubin: float) -> PenutupPemain.Objek:
	var s: float = Config.RUTE_PORTAL_TAPAK_SETENGAH_UBIN
	return PenutupPemain.buat(Rect2(Config.RUTE_PORTAL_LATERAL_UBIN - s, panjang_ubin - s, s + s, s + s), Config.RUTE_PORTAL_TINGGI_UBIN, "portal")


## Memasang portal di garis akhir rute sepanjang `panjang_ubin` dan menutupnya. Panjang tidak positif (rute gagal disusun) = portal tidak digambar.
func atur_rute(panjang_ubin: float) -> void:
	_panjang = panjang_ubin
	if penerap != null:
		penerap.lepas(self)
	visible = is_finite(panjang_ubin) and panjang_ubin > 0.0
	if not visible:
		return
	position = Iso.posisi_gambar(titik_dunia(panjang_ubin))
	if penerap != null:
		penerap.daftarkan(self, kotak_penutup(panjang_ubin))
	perbarui(0.0)


## Bingkai portal untuk sepeda yang sudah menempuh `jarak_ubin` (nyata, bukan jarak dunia yang dibekukan).
func perbarui(jarak_ubin: float) -> void:
	frame = AkhirRute.portal_bingkai(jarak_ubin, _panjang)


## Bingkai yang sedang tampil (0 tertutup, 1 terbuka; untuk tes dan probe).
func bingkai() -> int:
	return frame


## Panjang rute yang dipasang (untuk tes).
func panjang_dipasang() -> float:
	return _panjang
