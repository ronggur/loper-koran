extends SceneTree
## QA UI-2 iterasi 1 (bukan bagian run_tests.gd): lebar piksel banner misi untuk teks 24 huruf. Jalankan: godot --headless --path . --script res://tests/qa_banner_lebar.gd

func _init() -> void:
	var tema: Theme = load("res://assets/ui/theme.tres") as Theme
	var font: Font = tema.get_font(&"font", &"JudulLayar")
	var ukuran: int = tema.get_font_size(&"font_size", &"JudulLayar")
	for teks: String in ["Kucingnya lolos hari ini", "WWWWWWWWWWWWWWWWWWWWWWWW", "MMMMMMMMMMMMMMMMMMMMMMMM", "Kucing ketemu! +75 koin"]:
		print("banner %s (%d huruf): %s px pada Lilita %d" % [teks, teks.length(), font.get_string_size(teks, HORIZONTAL_ALIGNMENT_LEFT, -1, ukuran).x, ukuran])
	print("MISI_BANNER_PANJANG_MAKS %d, panel baris 2 mulai x 431 di 640 bila reputasi 100 (LOG C2)" % Config.MISI_BANNER_PANJANG_MAKS)
	quit(0)
