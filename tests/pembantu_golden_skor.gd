class_name PembantuGoldenSkor
extends RefCounted
## Pembantu golden skor `main` (run fase6a2-reputasi-pelanggan bagian B, AC-9): urutan lemparan acak berseed dan sidik FNV-1a field LAMA `SkorRute` (tanpa `terbuang`). Dipakai pembangkit
## (`ukur_golden_skor.gd`, dijalankan pada checkout `main`) dan `TesPotongan` (kode cabang ini), jadi keduanya menghitung dengan fungsi yang sama dan hanya `SkorRute` yang berbeda.

const SEED_AWAL: int = 20261023
const SEED_LANGKAH: int = 13
const JUMLAH_URUTAN: int = 1000
const PANJANG_MIN: int = 8
const PANJANG_MAKS: int = 40


static func fnv(teks: String) -> int:
	var nilai: int = 2166136261
	for b: int in teks.to_utf8_buffer():
		nilai = nilai ^ b
		nilai = (nilai * 16777619) & 4294967295
	return nilai


## Sidik urutan lemparan acak ke-`i`: tiap langkah ada koran acak (hasil zona, rumah dari kolam kecil supaya sering ulang, tepat, kecepatan, pemberi tip, sakelar jendela, tenggat) atau putus combo;
## yang disidik hanya field yang sudah ada sebelum run ini.
static func sidik_urutan(i: int) -> int:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = SEED_AWAL + i * SEED_LANGKAH
	var s: SkorRute.Keadaan = SkorRute.awal()
	var catatan: Array[String] = []
	var panjang: int = rng.randi_range(PANJANG_MIN, PANJANG_MAKS)
	for _langkah: int in range(panjang):
		if rng.randf() < 0.1:
			s = SkorRute.putus_combo(s)
			catatan.append("P|" + _keadaan(s))
			continue
		var hasil: ZonaSasaran.Hasil = rng.randi_range(0, 5) as ZonaSasaran.Hasil
		var id_rumah: String = "" if rng.randf() < 0.1 else "r@%d" % rng.randi_range(1, 7)
		var tepat: bool = rng.randf() < 0.4
		var kecepatan: float = rng.randf_range(0.0, 7.0)
		var pemberi_tip: bool = rng.randf() < 0.3
		var jendela: bool = rng.randf() < 0.5
		var lewat: bool = rng.randf() < 0.2
		var h: SkorRute.Hasil = SkorRute.nilai(s, hasil, id_rumah, tepat, kecepatan, pemberi_tip, jendela, lewat)
		s = h.keadaan
		catatan.append("%d|%d|%d|%d|%s|%d|%.4f|%.4f|%d|%s" % [h.status, h.skor_tambah, h.koin_tambah, h.tip, h.tepat, h.urutan_beruntun, h.pengali_combo, h.pengali_kecepatan, h.penanda, _keadaan(s)])
	return fnv("\n".join(catatan))


static func _keadaan(s: SkorRute.Keadaan) -> String:
	var ids: Array = s.terantar.keys()
	ids.sort()
	return "%d,%d,%d,%d,%d,%d,%d,%s" % [s.skor, s.koin, s.beruntun, s.jumlah_antar, s.jumlah_tepat, s.jumlah_tip, s.koin_tip, ",".join(PackedStringArray(ids))]
