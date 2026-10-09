extends SceneTree
## Probe layar di jendela asli, non-headless (AC-13): memuat scene utama, menunggu beberapa frame,
## mencetak ukuran jendela, ukuran viewport yang tampak, dan skala dari Godot, lalu menyimpan
## tangkapan layar dan keluar sendiri. Tidak interaktif; jendela terbuka sekitar satu detik.
##
## Pakai (jendela harus muat di layar monitor, kalau tidak sistem operasi mengecilkannya dan
## ukuran yang tercetak adalah ukuran sebenarnya):
##   godot --path . --resolution 1560x720 --script res://tests/probe_layar_jendela.gd -- docs/loop/<RUN_ID>/shots/iter1/jendela_1560x720.png
## Argumen setelah `--` = jalur PNG tangkapan layar (boleh dikosongkan). Tangkapan layar berukuran
## sama dengan jendela: tiap piksel game adalah blok skala x skala piksel yang tajam.
## Untuk pengukuran tanpa jendela dan semua rasio sekaligus pakai `tests/probe_layar.gd`.

const JUMLAH_FRAME_TUNGGU: int = 4


func _initialize() -> void:
	var utama: String = str(ProjectSettings.get_setting("application/run/main_scene"))
	var paket: PackedScene = load(utama) as PackedScene
	if paket == null:
		push_error("scene utama '%s' tidak bisa dimuat" % utama)
		quit(1)
		return
	root.add_child(paket.instantiate())
	for i: int in range(JUMLAH_FRAME_TUNGGU):
		await process_frame
	var terlihat: Vector2 = root.get_visible_rect().size
	var transform_akhir: Transform2D = root.get_final_transform()
	var skala: Vector2 = transform_akhir.get_scale()
	print("jendela asli %s (driver %s): viewport terlihat %dx%d, skala %sx%s (%s), tepi kosong %s px" % [
		root.size,
		DisplayServer.get_name(),
		int(terlihat.x),
		int(terlihat.y),
		skala.x,
		skala.y,
		"bulat" if skala.x == roundf(skala.x) and skala.y == roundf(skala.y) else "PECAHAN",
		transform_akhir.origin,
	])
	var argumen: PackedStringArray = OS.get_cmdline_user_args()
	if argumen.size() > 0:
		var gambar: Image = root.get_texture().get_image()
		var galat: int = gambar.save_png(argumen[0])
		print("tangkapan layar %dx%d ke %s (kode %d)" % [gambar.get_width(), gambar.get_height(), argumen[0], galat])
	quit()
