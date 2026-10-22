class_name KucingMisi
extends Node2D
## Kucing misi P1 di rute (AC-12 run fase4b-misi-kucing, usulan): sprite `mission_kucing_sheet` (belang tiga berkalung, hasil `tools/env_art/kendaraan.py --salin`,
## baris "masuk" menghadap rumah seberang, pose duduk dan ditangkap (run 5C); pose intip khusus ada di Fase 5, M-10) dan hiasan dari kode (`KucingHiasan`: kilau, ekor,
## bar progres tangkap). Node tipis: keputusan tampil dan posisi dari `MissionManager` dan `RencanaMisi`; di sini hanya memasang. Anak induk Y-sort rumah
## (`RumahDaurRute`, `y_sort_enabled`), jadi urutan gambar mengikuti titik pijak seperti rumah dan sepeda. Hanya tampil selama titiknya aktif di
## `MissionManager` dan dalam jendela daur rumah (`RUTE_DAUR_MUNDUR_UBIN`/`RUTE_DAUR_MAJU_UBIN`), jadi tidak bocor di luar jendela. Alfa penutup pemain diurus
## SATU `PenerapPenutup` (kotak kecil `RencanaMisi.persegi_kucing` setinggi `MISI_KUCING_TINGGI_UBIN`). Tidak menambah rintangan dan tidak menghalangi
## tabrakan, skor, atau sasaran: tanpa zona, tanpa tabrakan.
## Pose (run 20261022-fase5c-animasi-simpang, AC-9, usulan): frame badan dari `PoseKucing.frame` tiap `tampilkan`: duduk, atau ditangkap (kolom 7/8, dua frame dari
## waktu animasi misi) selama langkah `tangkap` dengan progres > 0. Titik pijak, offset, kotak penutup, dan hiasan tidak bergantung pada pose.

## Penerap penutup pemain (diisi scene rute).
var penerap: PenerapPenutup = null

var _titik: RencanaMisi.Titik = null
var _detik: float = 0.0

@onready var _badan: Sprite2D = %Badan
@onready var _hiasan: KucingHiasan = %Hiasan


func _ready() -> void:
	_badan.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_badan.centered = false
	_badan.offset = Vector2(-Config.MISI_KUCING_PIJAK_PX[0], -Config.MISI_KUCING_PIJAK_PX[1])
	_badan.hframes = Config.MISI_KUCING_KOLOM
	_badan.vframes = Config.MISI_KUCING_BARIS
	_badan.frame = frame_duduk()
	sembunyikan()


## Indeks frame duduk menghadap rumah seberang.
static func frame_duduk() -> int:
	return Config.MISI_KUCING_BARIS_HADAP * Config.MISI_KUCING_KOLOM + Config.MISI_KUCING_KOLOM_DUDUK


## Posisi gambar kucing di titik `t` (piksel game, dibulatkan): titik pijak dari lateral dan maju (dunia: y = -maju).
static func posisi_gambar(t: RencanaMisi.Titik) -> Vector2:
	return Iso.posisi_gambar(Vector2(t.lateral_ubin, -t.maju_ubin))


## Menampilkan kucing di titik `titik` (null = sembunyi) untuk sepeda yang sudah menempuh `jarak_ubin`. `detik` = waktu animasi (waktu efektif, membeku saat
## jeda), `progres` 0..1 bar tangkap, `kilau` dan `ekor` dari petunjuk visual data misi.
func tampilkan(titik: RencanaMisi.Titik, jarak_ubin: float, detik: float, progres: float, kilau: bool, ekor: bool) -> void:
	var dalam_jendela: bool = titik != null and titik.maju_ubin >= jarak_ubin - float(Config.RUTE_DAUR_MUNDUR_UBIN) and titik.maju_ubin <= jarak_ubin + float(Config.RUTE_DAUR_MAJU_UBIN)
	if not dalam_jendela:
		sembunyikan()
		return
	_titik = titik
	_detik = detik
	position = posisi_gambar(titik)
	_badan.frame = PoseKucing.frame(titik.jenis, progres, detik)
	visible = true
	_hiasan.atur(kilau, ekor, progres, detik)
	if penerap != null:
		penerap.daftarkan(_badan, PenutupPemain.buat(RencanaMisi.persegi_kucing(titik), Config.MISI_KUCING_TINGGI_UBIN, "kucing_misi"))


## Menyembunyikan kucing dan melepasnya dari penerap penutup.
func sembunyikan() -> void:
	_titik = null
	visible = false
	if penerap != null:
		penerap.lepas(_badan)


## True bila kucing sedang digambar.
func tampil() -> bool:
	return visible and _titik != null


## Titik yang sedang digambar, atau null.
func titik() -> RencanaMisi.Titik:
	return _titik


## Sprite badan (untuk tes dan probe).
func badan() -> Sprite2D:
	return _badan


## Hiasan kilau, ekor, dan progres (untuk tes dan probe).
func hiasan() -> KucingHiasan:
	return _hiasan


## Persegi gambar badan kucing (satu sel sheet) dalam koordinat viewport game (untuk tes dan probe).
func rect_badan() -> Rect2:
	var ukuran: Vector2 = Vector2(Config.MISI_KUCING_SEL_PX[0], Config.MISI_KUCING_SEL_PX[1])
	var lokal: Rect2 = Rect2(_badan.offset, ukuran)
	return _badan.get_global_transform_with_canvas() * lokal
