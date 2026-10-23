extends SceneTree
func _initialize() -> void:
	var f := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	var rng := RandomNumberGenerator.new(); rng.seed = 5150
	var hs := [ZonaSasaran.Hasil.MELESET, ZonaSasaran.Hasil.KOTAK_SURAT, ZonaSasaran.Hasil.TERAS, ZonaSasaran.Hasil.HALAMAN, ZonaSasaran.Hasil.JENDELA]
	for t in range(1000):
		var k := SkorRute.awal()
		for i in range(rng.randi_range(5, 40)):
			var hz = hs[rng.randi_range(0, hs.size()-1)]
			var id := "" if rng.randf() < 0.2 else "r%d" % rng.randi_range(0, 12)
			var res := SkorRute.nilai(k, hz, id, rng.randf() < 0.4, rng.randf_range(0.0, 7.0), rng.randf() < 0.3, rng.randf() < 0.3, rng.randf() < 0.2)
			k = res.keadaan
			if rng.randf() < 0.1: k = SkorRute.putus_combo(k)
			var keys: Array = k.terantar.keys(); keys.sort()
			f.store_line("%d %d %d %d %d %d %d %d %s %d %d %s" % [t, i, k.skor, k.beruntun, k.koin, k.jumlah_tepat, k.jumlah_tip, k.koin_tip, ",".join(PackedStringArray(keys)), res.status, res.penanda, str(res.tepat)])
	quit()
