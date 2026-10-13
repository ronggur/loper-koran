class_name UmpanBalikSepeda
extends Node2D
## Umpan balik kecepatan di sepeda (GDD 15, D-2 run fase1b-umpan-balik): debu roda dan garis kecepatan, placeholder dari kode.
##
## Anak `SepedaUji` (ruang lokal = titik pijak sepeda, digambar di belakang sprite pemain). Tipis: tiap langkah `SepedaUji` memanggil
## `perbarui(kecepatan sebenarnya, rem aktif)`, node ini mengisi laju dua `PancaranPiksel` dari `UmpanBalikKecepatan` (logika murni).
## Debu: kotak 1-2 px `Palette.TEXT_2` dari roda belakang, menjauh ke belakang sepanjang jalan (2:1). Garis kecepatan: garis
## bertangga 2:1 `Palette.TEXT` di sekitar pengendara, melaju ke belakang. Semua angka dari `Config` bagian "Umpan balik kecepatan";
## batas jumlah `UMPAN_DEBU_BATAS` dan `UMPAN_GARIS_BATAS`. `kurangi_efek` bawaan dari `Config.UMPAN_KURANGI_EFEK` (belum ada UI).

## Saklar kurangi efek (rule `ui-scenes`): garis mati, debu dikurangi.
var kurangi_efek: bool = Config.UMPAN_KURANGI_EFEK

@onready var _debu: PancaranPiksel = %Debu
@onready var _garis: PancaranPiksel = %Garis


func _ready() -> void:
	# Arah jalan di layar (naik ke kanan atas, 2:1) dari `Iso`; partikel melaju ke arah sebaliknya.
	var mundur: Vector2 = -Iso.dunia_ke_layar(Iso.ARAH_MAJU).normalized()
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
	_debu.laju = UmpanBalikKecepatan.laju_debu(kecepatan_ud, rem_aktif, kurangi_efek)
	_garis.laju = UmpanBalikKecepatan.laju_garis(kecepatan_ud, kurangi_efek)


## Pemancar debu roda (untuk tes dan probe).
func debu() -> PancaranPiksel:
	return _debu


## Pemancar garis kecepatan (untuk tes dan probe).
func garis() -> PancaranPiksel:
	return _garis
