extends SceneTree
## QA iterasi 1 run 4B (bukan bagian run_tests.gd): rencana kucing untuk 600 hari (bukan hanya 60) dan 200 benih "Main lagi" berurutan dari hari 1:
## harus sah, tidak berubah rute, titik terakhir <= batas rumah, titik berurutan, kucing tidak menimpa zona kotak surat pelanggan, dan jarak maju antar titik
## cukup supaya kucing berikut tidak muncul seketika (info: jarak antar titik minimum).
func _init() -> void:
	var misi: DataMisi = null
	for d: DataMisi in PemuatMisi.muat_folder().misi:
		if d.id == "p1_kucing":
			misi = d
	var segmen: Array[SegmenRute] = PemuatRute.muat_folder("res://assets/data/routes/perumahan").segmen
	var galat: int = 0
	var min_gap: float = 1000.0
	var tidak_sah: int = 0
	for hari: int in range(1, 601):
		var seed_rute: int = SeedHari.rute(hari)
		var rute: RouteBuilder.Rute = RouteBuilder.bangun(seed_rute, segmen).rute
		var r: RencanaMisi.Rencana = RencanaMisi.buat(misi, rute, SeedHari.misi(hari))
		if not r.sah():
			tidak_sah += 1
			continue
		for i: int in range(r.titik.size()):
			var t: RencanaMisi.Titik = r.titik[i]
			if t.indeks_rumah > r.batas_rumah:
				galat += 1
			if i > 0:
				min_gap = minf(min_gap, t.maju_ubin - r.titik[i - 1].maju_ubin)
	print("600 hari: tidak sah %d, galat batas %d, jarak maju antar titik minimum %.2f ubin" % [tidak_sah, galat, min_gap])
	quit(1 if (tidak_sah > 0 or galat > 0) else 0)
