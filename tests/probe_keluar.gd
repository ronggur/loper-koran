class_name ProbeKeluar
extends RefCounted
## Jalan keluar bersama probe jendela `tests/probe_*_jendela.gd` (QA-003 run fase1b-umpan-balik, D-3 run fase1c-perapian).
##
## Probe memuat scene utama (`jalan_uji.tscn`), dan di jendela asli driver audio sungguhan memutar loop kayuhan lewat autoload
## `Audio`. Bila probe langsung `quit()` saat bunyi masih berjalan, AudioServer tidak sempat melepas playback dan Godot mencetak
## `WARNING: 2 ObjectDB instances were leaked at exit` dan `ERROR: 1 resources still in use at exit` (dibuktikan 2026-10-14
## dengan `probe_umpan_balik_jendela.gd` di 2340x1080). Pembantu ini melakukan hal yang sama dengan runner tes (`run_tests.gd`):
## semua bunyi sepeda dan bunyi lempar/mendarat dihentikan (`Audio.hentikan_sepeda`, `Audio.hentikan_lempar`, dicari lewat jalur
## node supaya tidak bergantung pada nama global autoload), lalu menunggu `TUNGGU_DETIK` sampai driver mencampur lagi dan playback dilepas, baru keluar. Sebelumnya pohon dijeda
## (`SceneTree.paused`): probe yang membiarkan scene berjalan sendiri (`probe_dorongan_jendela.gd`, `probe_input_jendela.gd`)
## kalau tidak akan menyalakan loop kayuhan lagi lewat `JalanUji._process` selama masa tunggu (terjadi 2026-10-14). Timer tetap
## jalan saat pohon dijeda. Dipakai di SEMUA jalur keluar probe, termasuk jalur gagal: `await ProbeKeluar.keluar(self, kode)`.

## Lama menunggu sesudah bunyi dihentikan, detik (sama dengan runner tes: dua frame terlalu cepat, 0,25 detik bersih).
const TUNGGU_DETIK: float = 0.25


## Menjeda pohon, menghentikan bunyi sepeda dan lempar/mendarat, menunggu `TUNGGU_DETIK`, lalu `tree.quit(kode)`.
static func keluar(tree: SceneTree, kode: int = 0) -> void:
	tree.paused = true
	var audio: Node = tree.root.get_node_or_null(^"Audio")
	if audio != null and audio.has_method(&"hentikan_sepeda"):
		audio.call(&"hentikan_sepeda")
	if audio != null and audio.has_method(&"hentikan_lempar"):
		audio.call(&"hentikan_lempar")
	await tree.create_timer(TUNGGU_DETIK, true).timeout
	tree.quit(kode)
