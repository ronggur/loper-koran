extends SceneTree
## Pembangkit golden skor `main` (run fase6a2-reputasi-pelanggan bagian B, AC-9): menulis sidik 1000 urutan lemparan acak berseed (`PembantuGoldenSkor`) ke `tests/data/golden_skor_main.json`.
## Dijalankan SEKALI pada checkout `main` (blob `scripts/systems/skor_rute.gd` dicatat), bukan angka tulisan tangan:
##   godot --headless --script res://tests/ukur_golden_skor.gd -- <jalur keluaran> <blob skor_rute main>
## `TesPotongan` membandingkan hasil `SkorRute` cabang ini dengan berkas itu: field lama tidak boleh berubah.


func _initialize() -> void:
	var argumen: PackedStringArray = OS.get_cmdline_user_args()
	var sidik: Array = []
	for i: int in range(PembantuGoldenSkor.JUMLAH_URUTAN):
		sidik.append(PembantuGoldenSkor.sidik_urutan(i))
	var isi: Dictionary = {
		"blob_skor_rute_main": argumen[1] if argumen.size() > 1 else "",
		"jumlah_urutan": PembantuGoldenSkor.JUMLAH_URUTAN,
		"seed_awal": PembantuGoldenSkor.SEED_AWAL,
		"seed_langkah": PembantuGoldenSkor.SEED_LANGKAH,
		"sidik": sidik,
	}
	var berkas: FileAccess = FileAccess.open(argumen[0], FileAccess.WRITE)
	berkas.store_string(JSON.stringify(isi, "\t", true))
	berkas.close()
	print("golden skor main: %d urutan ditulis ke %s" % [sidik.size(), argumen[0]])
	quit(0)
