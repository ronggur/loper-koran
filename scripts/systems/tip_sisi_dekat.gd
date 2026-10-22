class_name TipSisiDekat
extends RefCounted
## Tip singkat hari pertama ada pelanggan di sisi dekat, logika murni (P-6, D-4, AC-12 run fase5d-sisi-dekat bagian B; usulan, dinilai di HP).
##
## Ditentukan dari nomor hari saja, tanpa bidang save baru: tampil hanya bila hari = `Config.RUTE_DEKAT_HARI_MULAI` (hari 3), selama `Config.TIP_SISI_DEKAT_DETIK` detik waktu game sejak rute
## dimulai (beku saat jeda, seperti tenggat), lalu hilang. Tidak ada di hari 1, 2, 4, atau 50. Node (`PanelTipSisiDekat`) hanya menampilkan; tidak menerima sentuhan, jadi stick, swipe, dan
## bel tetap sampai ke `TouchRouter`. Tanpa node, `Time`, atau RNG; masukan tidak diubah.

## Kunci terjemahan isi tip (`translations/ui.csv`).
const KUNCI_TEKS: String = "RUTE_TIP_SISI_DEKAT"


## True bila hari `hari` adalah hari tip (hari pertama pelanggan dekat).
static func hari_tip(hari: int) -> bool:
	return hari == Config.RUTE_DEKAT_HARI_MULAI


## Kunci teks tip untuk hari `hari`; kosong bila bukan hari tip.
static func kunci_teks(hari: int) -> String:
	return KUNCI_TEKS if hari_tip(hari) else ""


## Sisa detik tip di awal rute hari `hari`: `Config.TIP_SISI_DEKAT_DETIK` di hari tip, selain itu 0.
static func detik_awal(hari: int) -> float:
	return Config.TIP_SISI_DEKAT_DETIK if hari_tip(hari) else 0.0


## Sisa detik sesudah `dt` detik (tidak kurang dari 0; dt NaN, tak hingga, atau negatif = 0, jadi jeda game membekukannya).
static func sisa(sisa_detik: float, dt: float) -> float:
	var langkah: float = dt if is_finite(dt) and dt > 0.0 else 0.0
	var sekarang: float = sisa_detik if is_finite(sisa_detik) else 0.0
	return maxf(sekarang - langkah, 0.0)


## True selama tip tampil: masih ada sisa detik (lebih dari toleransi `LEMPAR_TOLERANSI_DETIK`).
static func tampil(sisa_detik: float) -> bool:
	return is_finite(sisa_detik) and sisa_detik > Config.LEMPAR_TOLERANSI_DETIK
