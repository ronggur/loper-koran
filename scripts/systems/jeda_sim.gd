class_name JedaSim
extends RefCounted
## Status jeda permainan (D-6 run fase1b-umpan-balik, menggantikan lanjut otomatis run fase1a-gerak; rule `gdscript`), logika murni.
##
## Pemanggil (`JalanUji`) menyimpan dua nilai: `jeda` (layar jeda terbuka, simulasi berhenti) dan `baru_lanjut` (langkah berikutnya
## adalah langkah pertama sesudah lanjut). Masukan berupa `Peristiwa`:
## - `JEDA`: tombol jeda, `NOTIFICATION_APPLICATION_PAUSED`, atau `NOTIFICATION_APPLICATION_FOCUS_OUT`. Selalu menjeda (juga bila
##   sudah jeda).
## - `LANJUT`: tombol "Lanjut" di layar jeda. Satu-satunya cara lanjut selain back.
## - `BACK`: tombol back Android (`NOTIFICATION_WM_GO_BACK_REQUEST`). Menjeda saat berjalan, melanjutkan saat jeda.
## - `TIDAK_ADA`: notifikasi lain, termasuk `RESUMED` dan `FOCUS_IN`. **Tidak ada lanjut otomatis** saat app kembali (keputusan
##   pemilik 2026-10-14): pemain melihat layar jeda dan mengetuk "Lanjut".
## Selama jeda, dan pada langkah pertama sesudah lanjut, `dt` efektif = 0: tidak ada lompatan, juga tidak sebesar
## `Config.LANGKAH_WAKTU_MAKS_DETIK`. Tanpa node: hanya konstanta notifikasi `Node` dibaca.

## Peristiwa yang bisa mengubah status jeda.
enum Peristiwa { TIDAK_ADA, JEDA, LANJUT, BACK }


## Peristiwa dari notifikasi `what`: PAUSED dan FOCUS_OUT = `JEDA`, WM_GO_BACK_REQUEST = `BACK`, lainnya (termasuk RESUMED dan
## FOCUS_IN) = `TIDAK_ADA`.
static func peristiwa_dari_notifikasi(what: int) -> Peristiwa:
	if what == Node.NOTIFICATION_APPLICATION_PAUSED or what == Node.NOTIFICATION_APPLICATION_FOCUS_OUT:
		return Peristiwa.JEDA
	if what == Node.NOTIFICATION_WM_GO_BACK_REQUEST:
		return Peristiwa.BACK
	return Peristiwa.TIDAK_ADA


## Status jeda sesudah `peristiwa`, dari status `jeda` sebelumnya.
static func jeda_sesudah(jeda: bool, peristiwa: Peristiwa) -> bool:
	match peristiwa:
		Peristiwa.JEDA:
			return true
		Peristiwa.LANJUT:
			return false
		Peristiwa.BACK:
			return not jeda
	return jeda


## Status `baru_lanjut` sesudah `peristiwa`: menyala hanya saat jeda berganti menjadi lanjut, mati saat menjeda, tetap bila lain.
static func baru_lanjut_sesudah(jeda: bool, baru_lanjut: bool, peristiwa: Peristiwa) -> bool:
	var sesudah: bool = jeda_sesudah(jeda, peristiwa)
	if sesudah:
		return false
	if jeda:
		return true
	return baru_lanjut


## `dt` yang dipakai simulasi untuk satu langkah: 0 selama jeda dan pada langkah pertama sesudah lanjut; selain itu `dt`
## apa adanya (NaN, tak hingga, atau negatif = 0). Jepit ke `Config.LANGKAH_WAKTU_MAKS_DETIK` tetap tugas `JalanUji._process`.
static func dt_efektif(jeda: bool, baru_lanjut: bool, dt: float) -> float:
	if jeda or baru_lanjut or not is_finite(dt) or dt <= 0.0:
		return 0.0
	return dt
