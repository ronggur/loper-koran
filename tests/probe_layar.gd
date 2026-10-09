extends SceneTree
## Probe layar (AC-13, ART_DIRECTION 7): mengukur skala dan ukuran viewport yang dipilih Godot
## untuk ukuran jendela tertentu dengan pengaturan stretch proyek ini. Bukan tes lulus/gagal:
## angka yang diharapkan dijaga oleh `_test_layar_integer` di `tests/run_tests.gd`.
##
## `--resolution` diabaikan oleh Godot headless (jendela root selalu 100x100), jadi probe ini
## mengubah `root.size` lalu membaca hasil hitungan stretch yang sama dengan yang dipakai jendela asli.
##
## Pakai:
##   godot --headless --path . --script res://tests/probe_layar.gd
##   godot --headless --path . --script res://tests/probe_layar.gd -- 2340x1080 1170x540
## Tanpa argumen setelah `--`, dipakai daftar bawaan di bawah. Lebar viewport yang tampak harus
## 640 (16:9), 780 (19,5:9), 800 (20:9) dan skala selalu bilangan bulat.

const UKURAN_BAWAAN: Array[String] = [
	"1920x1080",
	"2340x1080",
	"2400x1080",
	"1280x720",
	"1560x720",
	"1600x720",
	"2560x1440",
	"1170x540",
]
const NAMA_MODE: Dictionary = {
	Window.CONTENT_SCALE_MODE_DISABLED: "disabled",
	Window.CONTENT_SCALE_MODE_CANVAS_ITEMS: "canvas_items",
	Window.CONTENT_SCALE_MODE_VIEWPORT: "viewport",
}
const NAMA_ASPEK: Dictionary = {
	Window.CONTENT_SCALE_ASPECT_IGNORE: "ignore",
	Window.CONTENT_SCALE_ASPECT_KEEP: "keep",
	Window.CONTENT_SCALE_ASPECT_KEEP_WIDTH: "keep_width",
	Window.CONTENT_SCALE_ASPECT_KEEP_HEIGHT: "keep_height",
	Window.CONTENT_SCALE_ASPECT_EXPAND: "expand",
}
const NAMA_SKALA: Dictionary = {
	Window.CONTENT_SCALE_STRETCH_FRACTIONAL: "fractional",
	Window.CONTENT_SCALE_STRETCH_INTEGER: "integer",
}


func _initialize() -> void:
	print("pengaturan: mode=%s aspect=%s scale_mode=%s base=%s" % [
		NAMA_MODE[root.content_scale_mode],
		NAMA_ASPEK[root.content_scale_aspect],
		NAMA_SKALA[root.content_scale_stretch],
		root.content_scale_size,
	])
	var daftar: Array[String] = []
	for argumen: String in OS.get_cmdline_user_args():
		daftar.append(argumen)
	if daftar.is_empty():
		daftar = UKURAN_BAWAAN
	var ukuran_awal: Vector2i = root.size
	for teks: String in daftar:
		var bagian: PackedStringArray = teks.split("x")
		if bagian.size() != 2 or not bagian[0].is_valid_int() or not bagian[1].is_valid_int():
			push_error("ukuran '%s' harus berbentuk LEBARxTINGGI, mis. 2340x1080" % teks)
			continue
		var ukuran: Vector2i = Vector2i(bagian[0].to_int(), bagian[1].to_int())
		root.size = ukuran
		var terlihat: Vector2 = root.get_visible_rect().size
		var transform_akhir: Transform2D = root.get_final_transform()
		var skala: Vector2 = transform_akhir.get_scale()
		var bulat: bool = skala.x == roundf(skala.x) and skala.y == roundf(skala.y)
		print("jendela %s (rasio %.3f): viewport terlihat %dx%d, skala %sx%s (%s), tepi kosong %s px" % [
			teks,
			float(ukuran.x) / float(ukuran.y),
			int(terlihat.x),
			int(terlihat.y),
			skala.x,
			skala.y,
			"bulat" if bulat else "PECAHAN",
			transform_akhir.origin,
		])
	root.size = ukuran_awal
	quit()
