class_name SimProfilKondisi
extends RefCounted
## Pembantu tes run fase6a1-bengkel-kondisi: bot pemain yang menjalankan `BikeMotion` nyata di rute `RouteBuilder` nyata dan menumpuk aus lewat `BikeCondition` (AC-8, AC-10, AC-12).
## Tiga profil (BALANCING 8): `santai` (stick netral terus, tanpa rem), `campuran` (10 detik cepat lalu 10 detik santai, rem 0,8 detik tiap 20 detik) dan `ngebut` (stick
## penuh ke atas sebisa stamina; stamina habis = tarik penuh ke bawah (rem) sampai pulih; rem 0,8 detik tiap 12 detik untuk rintangan). Murni dan deterministik; TIDAK menyentuh berkas.
## Juga pembangkit masukan acak berseed dan sidik jari hasil gerak (`sidik`) untuk membuktikan keluaran identik bit-demi-bit dengan gerak sebelum ada efek.

## Langkah simulasi, detik (60 fps).
const DT: float = 1.0 / 60.0
## Batas waktu satu rute simulasi, detik (pengaman rute tidak selesai).
const WAKTU_MAKS: float = 600.0
const PROFIL: Array[String] = ["santai", "campuran", "ngebut"]

static var _pustaka_cache: Array[SegmenRute] = []


## Pustaka segmen rute nyata (dimuat sekali).
static func pustaka() -> Array[SegmenRute]:
	if _pustaka_cache.is_empty():
		_pustaka_cache = PemuatRute.muat_folder("res://assets/data/routes/perumahan").segmen
	return _pustaka_cache


## Rute hari 1 sampai `jumlah` dari `RouteBuilder` dengan `SeedHari.rute` (panjang dalam ubin).
static func panjang_rute(jumlah: int) -> Array[float]:
	var hasil: Array[float] = []
	for hari: int in range(1, jumlah + 1):
		var r: RouteBuilder.Hasil = RouteBuilder.bangun(SeedHari.rute(hari), pustaka())
		hasil.append(r.rute.panjang_ubin if r.sah() else 0.0)
	return hasil


## Stick bot `profil` pada keadaan `s` dan waktu rute `t` detik.
static func stick(profil: String, s: BikeMotion.Keadaan, t: float) -> Vector2:
	match profil:
		"campuran":
			var siklus: float = fmod(t, 20.0)
			if siklus >= 19.2:
				return Vector2(0.0, -1.0)
			return Vector2(0.0, 0.5) if siklus < 10.0 else Vector2.ZERO
		"ngebut":
			if s.lelah:
				return Vector2(0.0, -1.0)
			if fmod(t, 12.0) >= 11.2:
				return Vector2(0.0, -1.0)
			return Vector2(0.0, 1.0)
		_:
			return Vector2.ZERO


## Hasil satu rute simulasi.
class HasilSim extends RefCounted:
	var waktu: float = 0.0
	var selesai: bool = false
	var kondisi: Dictionary = {}
	var rem_mulai: int = 0
	var kecepatan_maks: float = 0.0
	var stamina_akhir: float = 0.0


## Jejak lintas rute: waktu global dan saat pertama tanda peringatan dan efek menghambat muncul per komponen.
class Jejak extends RefCounted:
	var waktu_global: float = 0.0
	var status_peringatan: BikeCondition.StatusPeringatan = BikeCondition.status_peringatan_awal()
	var peringatan_pertama: Dictionary = {}
	var efek_pertama: Dictionary = {}
	var jumlah_peringatan: Dictionary = {}


## Satu rute sepanjang `panjang` ubin dari `kondisi` awal. `pakai_efek` false = gerak tanpa efek (kondisi tetap aus). `pengali_upgrade` dan `pengali_aus` dari `DataToko`.
## `jejak` (opsional) mencatat saat pertama tanda peringatan dan efek. `awal` (opsional) = keadaan sepeda awal.
static func jalankan_rute(profil: String, panjang: float, kondisi: Dictionary, pakai_efek: bool = true, pengali_upgrade: Dictionary = {}, pengali_aus: Dictionary = {}, jejak: Jejak = null, awal: BikeMotion.Keadaan = null) -> HasilSim:
	var hasil: HasilSim = HasilSim.new()
	var s: BikeMotion.Keadaan = awal if awal != null else BikeMotion.Keadaan.new()
	var jarak: float = 0.0
	var t: float = 0.0
	var k: Dictionary = BikeCondition.rapikan(kondisi)
	while jarak < panjang and t < WAKTU_MAKS:
		var e: EfekKondisi = BikeCondition.efek(k, pengali_upgrade) if pakai_efek else null
		var h: BikeMotion.Hasil = BikeMotion.langkah(s, stick(profil, s, t), DT, 0.0, e)
		if h.rem_mulai:
			hasil.rem_mulai += 1
		k = BikeCondition.aus(k, BikeCondition.telemetri(h, DT), pengali_aus)
		s = h.keadaan
		hasil.kecepatan_maks = maxf(hasil.kecepatan_maks, s.kecepatan_ud)
		jarak += h.maju_ubin
		t += DT
		if jejak != null:
			jejak.waktu_global += DT
			var pakai: BikeCondition.Pemakaian = BikeCondition.Pemakaian.new()
			pakai.kecepatan_ud = s.kecepatan_ud
			pakai.rem_aktif = s.rem_aktif
			var p: BikeCondition.HasilPeringatan = BikeCondition.langkah_peringatan(jejak.status_peringatan, k, pakai, DT)
			jejak.status_peringatan = p.status
			for kom: String in p.komponen:
				jejak.jumlah_peringatan[kom] = int(jejak.jumlah_peringatan.get(kom, 0)) + 1
				if not jejak.peringatan_pertama.has(kom):
					jejak.peringatan_pertama[kom] = jejak.waktu_global
			var ef: EfekKondisi = BikeCondition.efek(k, pengali_upgrade)
			var menghambat: Dictionary = {
				"ban": ef.pengali_kecepatan < 1.0 or ef.pengali_lateral < 1.0,
				"rem": ef.pengali_rem < 1.0,
				"rantai": ef.pengali_akselerasi < 1.0 or ef.batas_puncak_ud < Config.KECEPATAN_NGEBUT_UD,
			}
			for kom: String in Config.KONDISI_KOMPONEN:
				if menghambat[kom] and not jejak.efek_pertama.has(kom):
					jejak.efek_pertama[kom] = jejak.waktu_global
	hasil.waktu = t
	hasil.selesai = jarak >= panjang
	hasil.kondisi = k
	hasil.stamina_akhir = s.stamina
	return hasil


## Nomor rute (mulai 1) saat salah satu komponen pertama kali PERLU_BENGKEL bila `profil` menjalankan rute `panjang` berturut-turut tanpa servis; 0 bila tidak pernah dalam rute tersedia.
## `komponen_pertama` diisi komponen yang PERLU_BENGKEL pada saat itu.
static func rute_pertama_perlu_bengkel(profil: String, panjang: Array[float], komponen_pertama: Array[String] = []) -> int:
	var k: Dictionary = BikeCondition.baru()
	for i: int in range(panjang.size()):
		var hasil: HasilSim = jalankan_rute(profil, panjang[i], k)
		k = hasil.kondisi
		var perlu: Array[String] = BikeCondition.perlu_bengkel(k)
		if not perlu.is_empty():
			komponen_pertama.append_array(perlu)
			return i + 1
	return 0


## Satu masukan gerak acak berseed.
class Masukan extends RefCounted:
	var keadaan: BikeMotion.Keadaan = null
	var stick: Vector2 = Vector2.ZERO
	var dt: float = 0.0
	var beku: float = 0.0


## `jumlah` masukan gerak acak dari `benih` (keadaan awal, stick termasuk di luar jangkauan, dt dari himpunan tetap, jatuh acak). Pembangkit sama dipakai untuk menghitung sidik emas
## dari kode gerak sebelum ada efek.
static func masukan_acak(jumlah: int, benih: int) -> Array[Masukan]:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = benih
	var daftar_dt: Array[float] = [0.0, 0.001, 1.0 / 240.0, 1.0 / 60.0, 0.05, 0.1, 0.25, 0.5, 1.0, 3.0]
	var hasil: Array[Masukan] = []
	for i: int in range(jumlah):
		var m: Masukan = Masukan.new()
		var s: BikeMotion.Keadaan = BikeMotion.Keadaan.new()
		s.kecepatan_ud = rng.randf_range(0.0, 6.0)
		s.lateral_ubin = rng.randf_range(-2.0, 2.0)
		s.stamina = rng.randf_range(0.0, 100.0)
		s.tahan_rem_detik = rng.randf_range(0.0, 0.5) if rng.randi() % 3 == 0 else 0.0
		s.rem_aktif = s.tahan_rem_detik >= 0.25 and rng.randi() % 2 == 0
		s.lelah = rng.randi() % 4 == 0
		m.keadaan = s
		m.stick = Vector2(rng.randf_range(-1.2, 1.2), rng.randf_range(-1.2, 1.2))
		if rng.randi() % 5 == 0:
			m.stick = Vector2(0.0, -1.0)
		m.dt = daftar_dt[rng.randi() % daftar_dt.size()]
		m.beku = rng.randf_range(0.0, 1.5) if rng.randi() % 6 == 0 else 0.0
		hasil.append(m)
	return hasil


## Nilai-nilai hasil gerak (objek `Hasil` dari `BikeMotion` apa pun versinya) sebagai larik 64-bit, untuk dibandingkan bit demi bit.
static func nilai_hasil(h: Object) -> PackedFloat64Array:
	var s: Object = h.get(&"keadaan")
	var larik: PackedFloat64Array = PackedFloat64Array()
	for nama: StringName in [&"kecepatan_ud", &"lateral_ubin", &"stamina", &"tahan_rem_detik"]:
		larik.append(float(s.get(nama)))
	larik.append(1.0 if s.get(&"rem_aktif") else 0.0)
	larik.append(1.0 if s.get(&"lelah") else 0.0)
	for nama: StringName in [&"maju_ubin", &"lateral_ud", &"tujuan_ud", &"stick_maju", &"pedal_rate"]:
		larik.append(float(h.get(nama)))
	for nama: StringName in [&"pose", &"tingkat_sprite", &"arah_sprite"]:
		larik.append(float(int(h.get(nama))))
	return larik


## Sidik sha256 dari urutan larik nilai (representasi bit 64-bit).
static func sidik(urutan: Array[PackedFloat64Array]) -> String:
	var semua: PackedFloat64Array = PackedFloat64Array()
	for larik: PackedFloat64Array in urutan:
		semua.append_array(larik)
	return semua.to_byte_array().hex_encode().sha256_text()
