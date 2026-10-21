class_name UmpanBalikSepeda
extends Node2D
## Umpan balik kecepatan di sepeda (GDD 15, D-2 run fase1b-umpan-balik): debu roda dan garis kecepatan, placeholder dari kode; di scene rute dari sprite gelombang 1 (`atur_sprite`).
##
## Anak `SepedaUji` (ruang lokal = titik pijak sepeda, digambar di belakang sprite pemain). Tipis: tiap langkah `SepedaUji` memanggil
## `perbarui(kecepatan sebenarnya, rem aktif)`, node ini mengisi laju dua `PancaranPiksel` dari `UmpanBalikKecepatan` (logika murni).
## Debu: kotak 1-2 px `Palette.TEXT_2` dari roda belakang, menjauh ke belakang sepanjang jalan (2:1), di **ruang dunia** (QA-006,
## D-5 run fase1c-perapian): sesudah dipancarkan debu diam di jalan, jadi tertinggal di belakang saat sepeda maju dan tertinggal di
## sisi lama saat pindah sisi. Garis kecepatan: garis bertangga 2:1 `Palette.TEXT` di sekitar pengendara, melaju ke belakang, tetap
## di ruang lokal sepeda (efek kamera, bukan benda di jalan). Semua angka dari `Config` bagian "Umpan balik kecepatan";
## batas jumlah `UMPAN_DEBU_BATAS` dan `UMPAN_GARIS_BATAS`. `kurangi_efek` bawaan dari `Config.UMPAN_KURANGI_EFEK` (belum ada UI).

## Run fase5a bagian B (D-4, usulan): `atur_sprite(true)` (dipanggil scene rute) mengganti partikel kode dengan sprite `vfx_debu_roda` dan `vfx_garis_kecepatan_a/b/c` (`VfxSepedaGambar`, logika
## `VfxSepeda`): kapan tampil tetap dari `UmpanBalikKecepatan` (tidak berubah), kedua `PancaranPiksel` dimatikan (tersembunyi, tanpa proses, laju 0), dan sprite ikut sepeda (debu tidak
## tertinggal di dunia saat pindah sisi; gerak mundurnya dipanggang di sprite). Bawaan false: jalan uji dan probe lama tetap memakai partikel kode (D-7: `scenes/dev/*` tidak disentuh).

## Saklar kurangi efek (rule `ui-scenes`): garis mati, debu dikurangi.
var kurangi_efek: bool = Config.UMPAN_KURANGI_EFEK

var _sprite: VfxSepedaGambar = null

@onready var _debu: PancaranPiksel = %Debu
@onready var _garis: PancaranPiksel = %Garis


func _ready() -> void:
	# Arah jalan di layar (naik ke kanan atas, 2:1) dari `Iso`; partikel melaju ke arah sebaliknya.
	var mundur: Vector2 = -Iso.dunia_ke_layar(Iso.ARAH_MAJU).normalized()
	_debu.ruang_dunia = true
	_debu.siapkan(Config.UMPAN_DEBU_BATAS, 1)
	_debu.arah = mundur
	_debu.asal = Vector2(Config.UMPAN_DEBU_ASAL_X_PX, Config.UMPAN_DEBU_ASAL_Y_PX)
	_debu.umur_detik = Config.UMPAN_DEBU_UMUR_DETIK
	_debu.kecepatan_px = Config.UMPAN_DEBU_KECEPATAN_PX
	_debu.sebaran_px = Config.UMPAN_DEBU_SEBARAN_PX
	_debu.ukuran_maks_px = Config.UMPAN_DEBU_UKURAN_MAKS_PX
	_debu.warna = Color(Palette.TEXT_2, Config.UMPAN_DEBU_ALPHA)
	_garis.siapkan(Config.UMPAN_GARIS_BATAS, 2)
	_garis.arah = mundur
	_garis.asal = Vector2(Config.UMPAN_GARIS_ASAL_X_PX, Config.UMPAN_GARIS_ASAL_Y_PX)
	_garis.umur_detik = Config.UMPAN_GARIS_UMUR_DETIK
	_garis.kecepatan_px = Config.UMPAN_GARIS_KECEPATAN_PX
	_garis.sebaran_px = Config.UMPAN_GARIS_SEBARAN_PX
	_garis.panjang_px = Config.UMPAN_GARIS_PANJANG_PX
	_garis.warna = Color(Palette.TEXT, Config.UMPAN_GARIS_ALPHA)


## Mengisi laju debu dan garis dari kecepatan sebenarnya `kecepatan_ud` (u/d) dan status `rem_aktif`.
func perbarui(kecepatan_ud: float, rem_aktif: bool) -> void:
	if not is_node_ready():
		return
	if _sprite != null:
		_sprite.atur(kecepatan_ud, rem_aktif, kurangi_efek)
		return
	_debu.laju = UmpanBalikKecepatan.laju_debu(kecepatan_ud, rem_aktif, kurangi_efek)
	_garis.laju = UmpanBalikKecepatan.laju_garis(kecepatan_ud, kurangi_efek)


## Mengganti partikel kode dengan sprite gelombang 1 (`pakai` true; sekali, tidak dibatalkan) di scene rute. Pemancar kode dimatikan (laju 0, tersembunyi, tanpa proses).
func atur_sprite(pakai: bool) -> void:
	if not pakai or _sprite != null or not is_node_ready():
		return
	_debu.laju = 0.0
	_garis.laju = 0.0
	for pemancar: PancaranPiksel in [_debu, _garis]:
		pemancar.kosongkan()
		pemancar.visible = false
		pemancar.process_mode = Node.PROCESS_MODE_DISABLED
	_sprite = VfxSepedaGambar.new()
	_sprite.name = "VfxSprite"
	add_child(_sprite)


## True bila debu dan garis digambar dari sprite (scene rute).
func pakai_sprite() -> bool:
	return _sprite != null


## Node sprite debu dan garis (null bila belum `atur_sprite`; untuk tes dan probe).
func sprite() -> VfxSepedaGambar:
	return _sprite


## Pemancar debu roda (untuk tes dan probe).
func debu() -> PancaranPiksel:
	return _debu


## Pemancar garis kecepatan (untuk tes dan probe).
func garis() -> PancaranPiksel:
	return _garis
