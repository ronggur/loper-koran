class_name JedaSim
extends RefCounted
## Jeda simulasi saat app di-background atau kehilangan fokus (D-6 run fase1a-gerak, rule `gdscript`), logika murni.
##
## Pemanggil (`JalanUji`) menyimpan dua nilai: `jeda` (simulasi berhenti) dan `baru_lanjut` (langkah berikutnya adalah langkah
## pertama sesudah lanjut). Notifikasi `NOTIFICATION_APPLICATION_PAUSED` atau `NOTIFICATION_APPLICATION_FOCUS_OUT` menjeda;
## `NOTIFICATION_APPLICATION_RESUMED` atau `NOTIFICATION_APPLICATION_FOCUS_IN` melanjutkan otomatis (tombol dan layar jeda ada
## di Run 1B). Satu peristiwa lanjut mana pun cukup, supaya simulasi tidak tertahan bila platform hanya mengirim salah satunya.
## Selama jeda, dan pada langkah pertama sesudah lanjut, `dt` efektif = 0: tidak ada lompatan, juga tidak sebesar
## `Config.LANGKAH_WAKTU_MAKS_DETIK`. Notifikasi lain tidak mengubah apa pun. Tanpa node: hanya konstanta notifikasi `Node` dibaca.


## True bila `what` adalah notifikasi yang menjeda simulasi.
static func notifikasi_jeda(what: int) -> bool:
	return what == Node.NOTIFICATION_APPLICATION_PAUSED or what == Node.NOTIFICATION_APPLICATION_FOCUS_OUT


## True bila `what` adalah notifikasi yang melanjutkan simulasi.
static func notifikasi_lanjut(what: int) -> bool:
	return what == Node.NOTIFICATION_APPLICATION_RESUMED or what == Node.NOTIFICATION_APPLICATION_FOCUS_IN


## Status jeda sesudah notifikasi `what`, dari status `jeda` sebelumnya.
static func jeda_sesudah(jeda: bool, what: int) -> bool:
	if notifikasi_jeda(what):
		return true
	if notifikasi_lanjut(what):
		return false
	return jeda


## Status `baru_lanjut` sesudah notifikasi `what`: menyala hanya saat jeda berganti menjadi lanjut, tetap bila lain.
static func baru_lanjut_sesudah(jeda: bool, baru_lanjut: bool, what: int) -> bool:
	if notifikasi_jeda(what):
		return false
	if notifikasi_lanjut(what) and jeda:
		return true
	return baru_lanjut


## `dt` yang dipakai simulasi untuk satu langkah: 0 selama jeda dan pada langkah pertama sesudah lanjut; selain itu `dt`
## apa adanya (NaN, tak hingga, atau negatif = 0). Jepit ke `Config.LANGKAH_WAKTU_MAKS_DETIK` tetap tugas `JalanUji._process`.
static func dt_efektif(jeda: bool, baru_lanjut: bool, dt: float) -> float:
	if jeda or baru_lanjut or not is_finite(dt) or dt <= 0.0:
		return 0.0
	return dt
