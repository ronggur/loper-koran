extends SceneTree
## AC-17 run 5C: galat muat segmen dan persen rute (100 seed SeedHari.rute(1..100) dan 100 seed 20261016 + 7 i) yang memuat >= 1 simpang, per sisi.
func _initialize() -> void:
	var k: PemuatRute.Kumpulan = PemuatRute.muat_folder()
	print("galat muat: ", k.galat)
	for nama: String in ["hari", "dev"]:
		var ada: int = 0
		var dekat: int = 0
		var seberang: int = 0
		var gagal: int = 0
		for i: int in range(100):
			var benih: int = SeedHari.rute(i + 1) if nama == "hari" else 20261016 + 7 * i
			var h: RouteBuilder.Hasil = RouteBuilder.bangun(benih, k.segmen)
			if not h.sah():
				gagal += 1
				print(h.galat)
				continue
			var s: Array[RouteBuilder.SimpangItem] = RouteBuilder.simpang_di(h.rute)
			var d: bool = false
			var b: bool = false
			for it: RouteBuilder.SimpangItem in s:
				d = d or it.sisi == LoperAnim.Sisi.DEKAT
				b = b or it.sisi == LoperAnim.Sisi.SEBERANG
			ada += 1 if not s.is_empty() else 0
			dekat += 1 if d else 0
			seberang += 1 if b else 0
		print("%s: >=1 simpang %d/100, dekat %d, seberang %d, gagal %d" % [nama, ada, dekat, seberang, gagal])
	quit(0)
