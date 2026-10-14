class_name ProbeKeluar
extends RefCounted
## Jalan keluar bersama probe jendela `tests/probe_*_jendela.gd` (QA-003 run fase1b-umpan-balik, D-3 run fase1c-perapian).
##
## Probe memuat scene utama (`jalan_uji.tscn`), dan di jendela asli driver audio sungguhan memutar loop kayuhan lewat autoload
## `Audio`. Bila probe langsung `quit()` saat bunyi masih berjalan, AudioServer tidak sempat melepas playback dan Godot mencetak
## `WARNING: 2 ObjectDB instances were leaked at exit` dan `ERROR: 1 resources still in use at exit` (dibuktikan 2026-10-14
## dengan `probe_umpan_balik_jendela.gd` di 2340x1080). Pembantu ini melakukan hal yang sama dengan runner tes (`run_tests.gd`):
## semua bunyi sepeda dihentikan (`Audio.hentikan_sepeda`, dicari lewat jalur node supaya tidak bergantung pada nama global
## autoload), lalu menunggu `TUNGGU_DETIK` sampai driver mencampur lagi dan playback dilepas, baru keluar. Dipakai di SEMUA
## jalur keluar probe, termasuk jalur gagal: `await ProbeKeluar.keluar(self, kode)`.

## Lama menunggu sesudah bunyi dihentikan, detik (sama dengan runner tes: dua frame terlalu cepat, 0,25 detik bersih).
const TUNGGU_DETIK: float = 0.25


## Menghentikan bunyi sepeda, menunggu `TUNGGU_DETIK`, lalu `tree.quit(kode)`.
static func keluar(tree: SceneTree, kode: int = 0) -> void:
	var audio: Node = tree.root.get_node_or_null(^"Audio")
	if audio != null and audio.has_method(&"hentikan_sepeda"):
		audio.call(&"hentikan_sepeda")
	await tree.create_timer(TUNGGU_DETIK, true).timeout
	tree.quit(kode)
