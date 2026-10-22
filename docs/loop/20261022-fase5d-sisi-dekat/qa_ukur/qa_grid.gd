extends SceneTree
func _init() -> void:
	var kum: PemuatRute.Kumpulan = PemuatRute.muat_folder()
	var keluar: Array = []
	for hari: int in [3, 4, 5, 6]:
		var h: RouteBuilder.Hasil = RouteBuilder.bangun(SeedHari.rute(hari), kum.segmen, hari)
		var medan: MedanKoran = MedanKoran.dari_rute(h.rute)
		for rumah: RouteBuilder.RumahRute in h.rute.rumah:
			if rumah.sisi != LoperAnim.Sisi.DEKAT:
				continue
			var grid: Array = []
			for i: int in range(48 + 1):
				var lat: float = 1.5 + float(i) / 16.0
				for j: int in range(72 + 1):
					var maju: float = rumah.maju_ubin - 1.0 + float(j) / 16.0
					var t: Vector2 = Vector2(lat, -maju)
					grid.append(int(ZonaSasaran.klasifikasi(t, medan.zona_sekitar(t))))
			keluar.append({"hari": hari, "id": rumah.id, "m0": rumah.maju_ubin, "jenis": rumah.jenis, "pel": rumah.pelanggan, "grid": grid})
	var f: FileAccess = FileAccess.open("/private/tmp/claude-501/-Users-ronggur-Works-Games-Loper-Koran-apps-loper-koran/ede651fa-6106-4ad1-a67e-c27dcc2dfc44/scratchpad/grid_qa.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(keluar))
	f.close()
	print("GRID rumah ", keluar.size())
	quit()
