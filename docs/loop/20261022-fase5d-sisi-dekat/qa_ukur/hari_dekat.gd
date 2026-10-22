extends SceneTree
func _init() -> void:
	var kum: PemuatRute.Kumpulan = PemuatRute.muat_folder()
	var sebar: Dictionary = {}
	var gagal: int = 0
	var celah_maks: float = 0.0
	var celah_min: float = 999.0
	var tidak25: int = 0
	var tak_boleh: int = 0
	var duplikat: int = 0
	var periksa_galat: int = 0
	var dekat_hari12: int = 0
	var tenggat_min: float = 1e9
	var tenggat_maks: float = 0.0
	var celah_semua: Array[float] = []
	var kota_dekat_salah: int = 0
	for hari: int in range(1, 1003):
		var s: int = SeedHari.rute(hari)
		var hasil: RouteBuilder.Hasil = RouteBuilder.bangun(s, kum.segmen, hari)
		if not hasil.sah():
			gagal += 1
			continue
		var r: RouteBuilder.Rute = hasil.rute
		var dekat: int = 0
		var ids: Dictionary = {}
		for p: RouteBuilder.RumahRute in r.pelanggan:
			if p.sisi == LoperAnim.Sisi.DEKAT:
				dekat += 1
			if not p.pelanggan_boleh:
				tak_boleh += 1
			if ids.has(p.id):
				duplikat += 1
			ids[p.id] = true
		if r.pelanggan.size() != 25:
			tidak25 += 1
		if hari <= 2:
			dekat_hari12 += dekat
			continue
		sebar[dekat] = int(sebar.get(dekat, 0)) + 1
		var urut: Array[float] = []
		for p: RouteBuilder.RumahRute in r.pelanggan:
			urut.append(p.maju_ubin)
		urut.sort()
		for i: int in range(1, urut.size()):
			var c: float = urut[i] - urut[i - 1]
			celah_maks = maxf(celah_maks, c)
			celah_min = minf(celah_min, c)
			celah_semua.append(c)
		if not RouteBuilder.periksa_rute(r).is_empty():
			periksa_galat += 1
		var tg: int = TenggatRute.detik_tenggat(r.panjang_ubin)
		tenggat_min = minf(tenggat_min, float(tg))
		tenggat_maks = maxf(tenggat_maks, float(tg))
	celah_semua.sort()
	print("HARI_DEKAT sebar=", sebar, " gagal=", gagal, " tidak25=", tidak25, " tak_boleh=", tak_boleh, " dup=", duplikat, " periksa_galat=", periksa_galat, " dekat_hari12=", dekat_hari12)
	print("HARI_DEKAT tenggat ", tenggat_min, " ", tenggat_maks)
	print("HARI_DEKAT celah min=", celah_min, " median=", celah_semua[celah_semua.size() / 2], " maks=", celah_maks, " batas=", Config.RUTE_PELANGGAN_JARAK_MAKS_UBIN)
	quit()
