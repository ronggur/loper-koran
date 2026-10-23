extends SceneTree
## Mencetak laporan `SimEkonomi` (reputasi per hari, tiga profil) untuk BALANCING 7.2: godot --headless --script res://tests/sim_ekonomi_laporan.gd -- [jumlah_hari] [rinci]

func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var hari: int = int(args[0]) if args.size() > 0 else 40
	for profil: String in SimEkonomi.PROFIL:
		var h: SimEkonomi.Hasil = SimEkonomi.jalankan(profil, hari)
		var teks: String = SimEkonomi.laporan(h)
		print(teks if args.size() > 1 else teks.split("\n")[0])
	quit()
