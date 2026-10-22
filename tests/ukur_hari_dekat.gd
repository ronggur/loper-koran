class_name UkurHariDekat
extends RefCounted
## Pengukur rute per hari run fase5d-sisi-dekat bagian B (AC-8): menyusun rute `SeedHari.rute(hari)` untuk rentang hari dari pustaka nyata dan mengukur jumlah pelanggan sisi dekat, celah antar pelanggan
## (gabungan dan per sisi), dan tenggat. Dipakai `TesSisiDekatB` dan skrip pengukuran LOG; murni (tanpa berkas selain pustaka segmen), deterministik.


## Hasil ukur: `n` rute sah dari `gagal + n` hari, `sebaran` jumlah dekat -> banyak rute, `celah_*` = [min, median, maks] ubin, `tenggat` = [min, maks] detik.
class Hasil extends RefCounted:
	var n: int = 0
	var gagal: int = 0
	var sebaran: Dictionary = {}
	var celah_gabungan: Array[float] = []
	var celah_seberang: Array[float] = []
	var celah_dekat: Array[float] = []
	var tenggat: Array[float] = []
	var panjang: Array[float] = []
	var pelanggan_total_salah: int = 0
	var dekat_bukan_boleh: int = 0


static func ukur(hari_awal: int, hari_akhir: int, pustaka: Array[SegmenRute] = []) -> Hasil:
	var segmen: Array[SegmenRute] = pustaka if not pustaka.is_empty() else PemuatRute.muat_folder().segmen
	var hasil: Hasil = Hasil.new()
	var gabungan: Array[float] = []
	var seberang: Array[float] = []
	var dekat: Array[float] = []
	var tenggat: Array[float] = []
	var panjang: Array[float] = []
	for hari: int in range(hari_awal, hari_akhir + 1):
		var h: RouteBuilder.Hasil = RouteBuilder.bangun(SeedHari.rute(hari), segmen, hari)
		if not h.sah():
			hasil.gagal += 1
			continue
		hasil.n += 1
		var rute: RouteBuilder.Rute = h.rute
		var n_dekat: int = RouteBuilder.jumlah_dekat(rute)
		hasil.sebaran[n_dekat] = int(hasil.sebaran.get(n_dekat, 0)) + 1
		if rute.pelanggan.size() != Config.RUTE_PELANGGAN:
			hasil.pelanggan_total_salah += 1
		for p: RouteBuilder.RumahRute in rute.pelanggan:
			if not p.pelanggan_boleh:
				hasil.dekat_bukan_boleh += 1
		gabungan.append_array(RouteBuilder.jarak_pelanggan(rute))
		for sisi: LoperAnim.Sisi in [LoperAnim.Sisi.SEBERANG, LoperAnim.Sisi.DEKAT]:
			var sebelumnya: float = -1.0
			for p: RouteBuilder.RumahRute in rute.pelanggan:
				if p.sisi != sisi:
					continue
				if sebelumnya >= 0.0:
					(seberang if sisi == LoperAnim.Sisi.SEBERANG else dekat).append(p.maju_ubin - sebelumnya)
				sebelumnya = p.maju_ubin
		tenggat.append(TenggatRute.awal(rute.panjang_ubin).tenggat_detik)
		panjang.append(rute.panjang_ubin)
	hasil.celah_gabungan = _min_median_maks(gabungan)
	hasil.celah_seberang = _min_median_maks(seberang)
	hasil.celah_dekat = _min_median_maks(dekat)
	hasil.tenggat = [_min_median_maks(tenggat)[0], _min_median_maks(tenggat)[2]]
	hasil.panjang = [_min_median_maks(panjang)[0], _min_median_maks(panjang)[2]]
	return hasil


static func _min_median_maks(daftar: Array[float]) -> Array[float]:
	if daftar.is_empty():
		return [0.0, 0.0, 0.0]
	var urut: Array[float] = daftar.duplicate()
	urut.sort()
	return [urut[0], urut[urut.size() / 2], urut[urut.size() - 1]]
