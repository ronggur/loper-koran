extends SceneTree
## Pembangkit golden garis finish `main` (run garis-finish-portal bagian C, G-5, AC-7): menjalankan bot `PembantuGoldenGaris` di scene rute pada checkout `main` (perilaku LAMA: sepeda direm di
## garis akhir, layar hasil terbuka saat berhenti) dan menulis angka tiap kasus ke `tests/data/golden_garis_main.json`. Dijalankan SEKALI pada checkout `main` (bukan angka tulisan tangan):
##   godot --headless --path . --script res://tests/ukur_golden_garis.gd -- <jalur keluaran> <hash commit main>
## `TesGarisFinishScene` menjalankan bot yang sama di cabang ini (sepeda melaju keluar viewport) dan membandingkan dengan berkas itu.


func _initialize() -> void:
	var argumen: PackedStringArray = OS.get_cmdline_user_args()
	var hasil: Array = []
	for kasus: Dictionary in PembantuGoldenGaris.KASUS:
		var satu: Dictionary = await PembantuGoldenGaris.jalankan(self, kasus)
		hasil.append(satu)
		print("golden garis %s: langkah garis %d, hasil terbuka %s" % [kasus["nama"], int(satu["langkah_garis"]), str(satu["hasil_terbuka"])])
	var isi: Dictionary = {"commit_main": argumen[1] if argumen.size() > 1 else "", "kasus": hasil}
	var berkas: FileAccess = FileAccess.open(argumen[0], FileAccess.WRITE)
	berkas.store_string(JSON.stringify(isi, "\t", true))
	berkas.close()
	print("golden garis main: %d kasus ditulis ke %s" % [hasil.size(), argumen[0]])
	quit(0)
