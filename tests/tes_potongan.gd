class_name TesPotongan
extends RefCounted
## Tes potongan koran terbuang run fase6a2-reputasi-pelanggan bagian B, logika murni (AC-8 sampai AC-10, K-1, K-2, O-1, O-2): `SkorRute.Keadaan.terbuang`, `HasilRute.Angka` (`lempar_terbuang`,
## `potongan`, `koin_bersih`), `DataSave.catat_hari` (saldo dijepit 0, `koin_total` koin kotor, `terakhir.potongan`), `UmpanMelayang`/`VfxAntaran` untuk "-5", dan golden `SkorRute` dari `main`.
##
## Harapan ditulis literal atau dihitung dengan cara lain (hitung status sendiri, saldo dengan bilangan bulat biasa), bukan memanggil fungsi yang dites. Golden skor datang dari `main`
## (`tests/data/golden_skor_main.json`, dibuat `tests/ukur_golden_skor.gd` pada checkout `main`).

const GOLDEN: String = "res://tests/data/golden_skor_main.json"

var _cek: Callable
var _judul: Callable


func _init(cek: Callable, judul: Callable) -> void:
	_cek = cek
	_judul = judul


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_test_config()
	_test_status_terbuang()
	_test_angka_hasil()
	_test_saldo_helper()
	_test_catat_hari()
	_test_hari_minus_tidak_menjebak()
	_test_fuzz_catat_hari()
	_test_umpan_potongan()
	_test_golden_skor()
	_test_urutan_acak_terbuang()


# --- Pembantu ---

## Rute buatan dengan `n` pelanggan berid "h@<i>".
func _rute(n: int) -> RouteBuilder.Rute:
	var rute: RouteBuilder.Rute = RouteBuilder.Rute.new()
	for i: int in range(n):
		var r: RouteBuilder.RumahRute = RouteBuilder.RumahRute.new()
		r.id = "h@%d" % i
		r.sisi = LoperAnim.Sisi.SEBERANG
		r.pelanggan = true
		r.maju_ubin = float(i * 9)
		rute.rumah.append(r)
		rute.pelanggan.append(r)
	rute.panjang_ubin = 240.0
	return rute


func _angka(k: SkorRute.Keadaan, n_pelanggan: int) -> HasilRute.Angka:
	return HasilRute.dari(k, _rute(n_pelanggan), TenggatRute.awal(240.0))


## Menilai satu koran ke zona `hasil` rumah `id` (santai, sakelar jendela penalti, sebelum tenggat).
func _nilai(k: SkorRute.Keadaan, hasil: ZonaSasaran.Hasil, id: String, jendela_bonus: bool = false) -> SkorRute.Hasil:
	return SkorRute.nilai(k, hasil, id, false, 3.0, false, jendela_bonus, false)


func _catatan(hari: int, koin: int, potongan: int, belanja: int = 0) -> DataSave.CatatanHari:
	var c: DataSave.CatatanHari = DataSave.CatatanHari.new()
	c.hari = hari
	c.angka = HasilRute.Angka.new()
	c.angka.koin = koin
	c.angka.potongan = potongan
	c.belanja_koin = belanja
	return c


# --- AC-8 ---

func _test_config() -> void:
	_judul.call("Potongan (AC-8): KOIN_POTONGAN_KORAN_MELESET = 5, satu baris literal di config.gd")
	var teks: String = FileAccess.get_file_as_string("res://scripts/config.gd")
	check(teks.contains("\nconst KOIN_POTONGAN_KORAN_MELESET: int = 5\n"), "config.gd: 'const KOIN_POTONGAN_KORAN_MELESET: int = 5' satu baris literal")
	check(Config.KOIN_POTONGAN_KORAN_MELESET == 5 and Config.KOIN_POTONGAN_KORAN_MELESET * 3 == Config.KOIN_ONGKOS_ANTAR, "potongan 5 = sepertiga ongkos antar 15 (K-1)")


func _test_status_terbuang() -> void:
	_judul.call("Potongan (AC-8, O-1): TIDAK_SAH dan ULANG yang mendarat menaikkan terbuang; ANTAR (termasuk halaman dan jendela bonus) tidak")
	var awal: SkorRute.Keadaan = SkorRute.awal()
	check(awal.terbuang == 0 and SkorRute.potongan(awal) == 0, "keadaan awal: terbuang 0, potongan 0")
	# Tidak sah: meleset, bukan pelanggan, jendela dengan sakelar penalti.
	for kasus: Array in [[ZonaSasaran.Hasil.MELESET, ""], [ZonaSasaran.Hasil.BUKAN_PELANGGAN, "b@1"], [ZonaSasaran.Hasil.JENDELA, "h@0"]]:
		var h: SkorRute.Hasil = _nilai(awal, kasus[0], kasus[1], false)
		check(h.status == SkorRute.Status.TIDAK_SAH and h.keadaan.terbuang == 1 and SkorRute.potongan(h.keadaan) == 5 and SkorRute.hasil_terbuang(h), "hasil zona %d tidak sah: terbuang 1, potongan 5" % kasus[0])
		check(awal.terbuang == 0, "masukan tidak diubah (hasil zona %d)" % kasus[0])
	# Sah: kotak surat, teras, halaman, jendela bonus.
	for kasus: Array in [[ZonaSasaran.Hasil.KOTAK_SURAT, false], [ZonaSasaran.Hasil.TERAS, false], [ZonaSasaran.Hasil.HALAMAN, false], [ZonaSasaran.Hasil.JENDELA, true]]:
		var h2: SkorRute.Hasil = _nilai(awal, kasus[0], "h@1", kasus[1])
		check(h2.status == SkorRute.Status.ANTAR and h2.keadaan.terbuang == 0 and not SkorRute.hasil_terbuang(h2), "hasil zona %d sah (jendela bonus %s): ANTAR, tidak terbuang" % [kasus[0], kasus[1]])
	# Ulang: rumah sudah terantar, termasuk zona halaman rumah yang sama.
	var satu: SkorRute.Keadaan = _nilai(awal, ZonaSasaran.Hasil.KOTAK_SURAT, "h@1").keadaan
	for hasil: ZonaSasaran.Hasil in [ZonaSasaran.Hasil.KOTAK_SURAT, ZonaSasaran.Hasil.TERAS, ZonaSasaran.Hasil.HALAMAN]:
		var hu: SkorRute.Hasil = _nilai(satu, hasil, "h@1")
		check(hu.status == SkorRute.Status.ULANG and hu.keadaan.terbuang == 1 and SkorRute.hasil_terbuang(hu) and hu.skor_tambah == 0 and hu.koin_tambah == 0, "koran ulang ke rumah terantar (zona %d): terbuang 1, 0 skor, 0 koin" % hasil)
	# Menumpuk, putus combo dan salin mempertahankan.
	var k: SkorRute.Keadaan = satu
	for i: int in range(7):
		k = _nilai(k, ZonaSasaran.Hasil.MELESET, "").keadaan
	check(k.terbuang == 7 and SkorRute.potongan(k) == 35, "tujuh meleset: terbuang 7, potongan 35")
	check(SkorRute.putus_combo(k).terbuang == 7 and k.salin().terbuang == 7, "putus combo (tabrakan) dan salin mempertahankan terbuang")
	check(k.jumlah_antar == 1 and k.skor == satu.skor and k.koin == satu.koin and k.koin == 15, "terbuang tidak mengubah skor, koin kotor, dan jumlah antar")


# --- AC-8 sampai AC-9: angka hasil ---

func _test_angka_hasil() -> void:
	_judul.call("Potongan (AC-8): Angka lempar_terbuang, potongan, koin_bersih = koin - potongan; 25 = 125, 30 = 150, semua kena = 0, tanpa lemparan = 0")
	# 25 terbuang tanpa antaran: -125.
	var k: SkorRute.Keadaan = SkorRute.awal()
	for i: int in range(25):
		k = _nilai(k, ZonaSasaran.Hasil.MELESET, "").keadaan
	var a: HasilRute.Angka = _angka(k, 25)
	check(a.lempar_terbuang == 25 and a.potongan == 125 and a.koin == 0 and a.koin_bersih == -125, "25 lemparan terbuang, 0 antaran: potongan 125, koin_bersih -125")
	check(a.terkirim == 0 and a.meleset == 25, "kontrol: meleset (pelanggan tidak menerima) 25 tetap besaran terpisah")
	# 30 terbuang.
	for i: int in range(5):
		k = _nilai(k, ZonaSasaran.Hasil.BUKAN_PELANGGAN, "x@1").keadaan
	check(_angka(k, 25).lempar_terbuang == 30 and _angka(k, 25).potongan == 150 and _angka(k, 25).koin_bersih == -150, "30 lemparan terbuang: potongan 150")
	# Semua kena: 25 antaran, nol terbuang.
	var bagus: SkorRute.Keadaan = SkorRute.awal()
	for i: int in range(25):
		bagus = _nilai(bagus, ZonaSasaran.Hasil.KOTAK_SURAT, "h@%d" % i).keadaan
	var ab: HasilRute.Angka = _angka(bagus, 25)
	check(ab.lempar_terbuang == 0 and ab.potongan == 0 and ab.koin == 375 and ab.koin_bersih == 375 and ab.meleset == 0, "semua kena (25 x 15 = 375): tanpa potongan, koin_bersih = koin")
	# Koran cadangan 0 lemparan dan pelanggan terlewat tanpa lemparan: tidak dikenai (K-2).
	var kosong: HasilRute.Angka = _angka(SkorRute.awal(), 25)
	check(kosong.lempar_terbuang == 0 and kosong.potongan == 0 and kosong.koin_bersih == 0 and kosong.meleset == 25 and kosong.terkirim == 0, "tanpa satu pun lemparan: 25 pelanggan terlewat (meleset 25) tetapi potongan 0 (K-2)")
	# Campuran: 3 antaran, 4 terbuang -> koin 45, potongan 20, bersih 25; meleset (pelanggan) 22 terpisah dari 4 terbuang.
	var m: SkorRute.Keadaan = SkorRute.awal()
	for i: int in range(3):
		m = _nilai(m, ZonaSasaran.Hasil.KOTAK_SURAT, "h@%d" % i).keadaan
	m = _nilai(m, ZonaSasaran.Hasil.KOTAK_SURAT, "h@0").keadaan
	m = _nilai(m, ZonaSasaran.Hasil.MELESET, "").keadaan
	m = _nilai(m, ZonaSasaran.Hasil.HALAMAN, "h@1").keadaan
	m = _nilai(m, ZonaSasaran.Hasil.JENDELA, "h@2", false).keadaan
	var am: HasilRute.Angka = _angka(m, 25)
	check(am.terkirim == 3 and am.meleset == 22 and am.lempar_terbuang == 4 and am.koin == 45 and am.potongan == 20 and am.koin_bersih == 25, "campuran: terkirim 3, meleset 22, terbuang 4, koin 45, potongan 20, bersih 25 (dua besaran tidak dicampur)")
	# Properti koin_bersih untuk Angka rakitan (koin sudah termasuk hadiah misi).
	var r: HasilRute.Angka = HasilRute.Angka.new()
	r.koin = 195
	r.koin_misi = 75
	r.potongan = 35
	check(r.koin_bersih == 160, "Angka rakitan: koin 195 (termasuk misi 75) - potongan 35 = 160")


func _test_saldo_helper() -> void:
	_judul.call("Potongan (AC-10, O-2): HasilRute.saldo_sesudah dan koin_dijepit")
	for baris: Array in [[100, 30, 130, 0], [100, -125, 0, 25], [100, -100, 0, 0], [0, -5, 0, 5], [0, 0, 0, 0], [800, -25, 775, 0], [5, 375, 380, 0]]:
		check(HasilRute.saldo_sesudah(baris[0], baris[1]) == baris[2] and HasilRute.koin_dijepit(baris[0], baris[1]) == baris[3], "saldo %d + bersih %d -> saldo %d, dijepit %d" % [baris[0], baris[1], baris[2], baris[3]])


# --- AC-10: catat_hari ---

func _test_catat_hari() -> void:
	_judul.call("catat_hari (AC-10, O-2): saldo = max(0, lama + bersih) - belanja, koin_total = lama + kotor, terakhir.potongan")
	var s0: Dictionary = DataSave.templat()
	s0["koin"] = 800
	s0["koin_total"] = 1000
	# Hari baik dengan sedikit potongan: 800 + 100 - 25 = 875.
	var s1: Dictionary = DataSave.catat_hari(s0, _catatan(1, 100, 25))
	check(s1["koin"] == 875 and s1["koin_total"] == 1100 and s1["terakhir"]["koin"] == 100 and s1["terakhir"]["potongan"] == 25, "800 + 100 - 25 = 875; koin_total 1000 + 100 (kotor) = 1100; terakhir.koin 100 dan potongan 25")
	check(s0["koin"] == 800 and s0["koin_total"] == 1000, "masukan tidak diubah")
	# Hari minus: saldo 800 - 125 = 675, koin_total tidak berubah (pendapatan kotor 0).
	var s2: Dictionary = DataSave.catat_hari(s0, _catatan(1, 0, 125))
	check(s2["koin"] == 675 and s2["koin_total"] == 1000 and s2["terakhir"]["koin"] == 0 and s2["terakhir"]["potongan"] == 125, "hari minus -125 dari saldo 800: saldo 675, koin_total tetap 1000 (hanya naik)")
	# Dijepit 0.
	var kecil: Dictionary = DataSave.templat()
	kecil["koin"] = 40
	kecil["koin_total"] = 40
	var s3: Dictionary = DataSave.catat_hari(kecil, _catatan(1, 15, 125))
	check(s3["koin"] == 0 and s3["koin_total"] == 55, "saldo 40 + 15 - 125 -> 0 (dijepit, bukan negatif); koin_total 55")
	# Belanja tidak membuat saldo negatif dan memakai saldo sesudah potongan.
	var s4: Dictionary = DataSave.catat_hari(kecil, _catatan(1, 100, 25, 50))
	check(s4["koin"] == 65 and s4["koin_total"] == 140, "40 + 100 - 25 = 115, belanja 50 -> 65; koin_total 140")
	var s5: Dictionary = DataSave.catat_hari(kecil, _catatan(1, 0, 125, 30))
	check(s5["koin"] == 0, "dijepit 0 dulu, belanja berlebih tetap 0 (tidak negatif)")
	# Tip total tidak terpengaruh potongan.
	var c_tip: DataSave.CatatanHari = _catatan(1, 60, 25)
	c_tip.angka.koin_tip = 10
	check(DataSave.catat_hari(DataSave.templat(), c_tip)["tip_total"] == 10, "tip_total memakai tip kotor (10), bukan terpotong")
	# Save lama tanpa terakhir.potongan dibaca sebagai 0 dan ke_teks stabil.
	var tua: Dictionary = DataSave.templat()
	tua["terakhir"] = {"hari": 1, "terkirim": 1, "meleset": 24, "koin": 15, "tip": 0, "skor": 100, "koin_misi": 0, "misi_diambil": "", "misi_hasil": ""}
	var muat: Dictionary = DataSave.dari_teks(DataSave.ke_teks(tua)).state
	check(muat["terakhir"]["potongan"] == 0, "terakhir tanpa potongan (save lama) dibaca 0")
	var bulak: String = DataSave.ke_teks(DataSave.dari_teks(DataSave.ke_teks(s2)).state)
	check(bulak == DataSave.ke_teks(s2), "ke_teks stabil byte demi byte sesudah hari minus (bulak-balik)")
	# Potongan negatif atau tidak sah dijepit 0 pada catatan; potongan besar tidak meluap.
	var s6: Dictionary = DataSave.catat_hari(s0, _catatan(1, 50, -20))
	check(s6["koin"] == 850 and s6["terakhir"]["potongan"] == 0, "potongan negatif (tidak seharusnya ada) diperlakukan 0")


func _test_hari_minus_tidak_menjebak() -> void:
	_judul.call("Hari minus tidak menjebak (AC-10): saldo 0 -> servis ditolak 'koin kurang', tetapi tidak ada keadaan buntu; hari berikutnya tetap bisa dimainkan")
	var s: Dictionary = DataSave.templat()
	s["koin"] = 20
	s["koin_total"] = 20
	var sepeda: Dictionary = s["sepeda"]
	(sepeda["rantai"] as Dictionary)["kondisi"] = 0.3
	var minus: Dictionary = DataSave.catat_hari(s, _catatan(1, 0, 150))
	check(minus["koin"] == 0 and minus["hari"] == 2, "hari minus: saldo 0, hari maju ke 2")
	var servis: Economy.Hasil = Economy.servis(minus, "rantai")
	check(not servis.diterima and servis.alasan == Economy.Alasan.KOIN_KURANG and servis.state == minus, "saldo 0: servis ditolak KOIN_KURANG tanpa efek")
	var lagi: Dictionary = DataSave.catat_hari(minus, _catatan(2, 150, 0))
	check(lagi["koin"] == 150 and lagi["hari"] == 3 and lagi["koin_total"] == 170, "hari berikutnya dari saldo 0 berjalan normal: 0 + 150 = 150")
	check(MesinHari.terapkan(MesinHari.awal(1), MesinHari.Peristiwa.BERANGKAT).diterima, "mesin hari: Berangkat tetap diterima (tidak ada gerbang saldo)")


func _test_fuzz_catat_hari() -> void:
	_judul.call("catat_hari fuzz 10.000 hari (AC-10): invarian koin >= 0, koin <= koin_total, koin_total dan hari hanya naik, saldo = oracle bilangan bulat")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20261023
	var state: Dictionary = DataSave.templat()
	var saldo: int = 0
	var total: int = 0
	var hari: int = 1
	var pelanggaran: Array[String] = []
	var jepit: int = 0
	for i: int in range(10000):
		var koin: int = rng.randi_range(0, 450)
		var potongan: int = 5 * rng.randi_range(0, 40)
		var tersedia: int = maxi(saldo + koin - potongan, 0)
		var belanja: int = rng.randi_range(0, tersedia) if rng.randf() < 0.5 and tersedia > 0 else 0
		var sebelum_total: int = int(state["koin_total"])
		var sebelum_hari: int = int(state["hari"])
		state = DataSave.catat_hari(state, _catatan(hari, koin, potongan, belanja))
		if saldo + koin - potongan < 0:
			jepit += 1
		saldo = maxi(saldo + koin - potongan, 0) - belanja
		total += koin
		hari += 1
		if int(state["koin"]) != saldo or int(state["koin_total"]) != total:
			pelanggaran.append("hari %d: saldo %d (oracle %d) total %d (oracle %d)" % [i, int(state["koin"]), saldo, int(state["koin_total"]), total])
		if int(state["koin"]) < 0 or int(state["koin"]) > int(state["koin_total"]) or int(state["koin_total"]) < sebelum_total or int(state["hari"]) < sebelum_hari:
			pelanggaran.append("hari %d: invarian" % i)
		if pelanggaran.size() > 3:
			break
	check(pelanggaran.is_empty(), "10.000 hari acak: saldo dan koin_total sama dengan oracle, invarian utuh: %s" % [pelanggaran])
	check(jepit > 200, "kontrol: penjepitan 0 benar-benar terjadi di fuzz (%d kali)" % jepit)


# --- O-3: umpan "-5" ---

func _test_umpan_potongan() -> void:
	_judul.call("Umpan potongan (O-3): entri '-5' di titik mendarat, tanpa bintang dan koin; hanya koran terbuang")
	var e: UmpanMelayang.Entri = UmpanMelayang.dari_potongan(5, Vector2(-2.0, -10.0))
	check(e != null and e.potongan == 5 and e.ongkos == 0 and e.tip == 0 and not e.tepat and e.titik_dunia == Vector2(-2.0, -10.0) and is_equal_approx(e.sisa_detik, Config.UMPAN_MELAYANG_DETIK), "entri potongan: 5, tanpa ongkos, tip, tepat; di titik mendarat; 0,8 detik")
	check(UmpanMelayang.dari_potongan(0, Vector2.ZERO) == null and UmpanMelayang.dari_potongan(-5, Vector2.ZERO) == null, "potongan 0 atau negatif: tanpa entri")
	check(e.salin().potongan == 5, "salin entri mempertahankan potongan")
	check(VfxAntaran.item_entri(e).is_empty() and VfxAntaran.frame_koin(e) == -1, "entri potongan tidak memutar bintang kena atau koin tip")
	var daftar: Array[UmpanMelayang.Entri] = UmpanMelayang.tambah([] as Array[UmpanMelayang.Entri], e)
	check(UmpanMelayang.langkah(daftar, 0.4)[0].potongan == 5 and UmpanMelayang.langkah(daftar, 0.81).is_empty(), "entri potongan naik dan memudar seperti entri lain, hilang sesudah 0,8 detik")
	# Dari penilaian: hanya hasil terbuang yang membuat entri potongan; dari_hasil tetap null untuk bukan ANTAR.
	var awal: SkorRute.Keadaan = SkorRute.awal()
	var antar: SkorRute.Hasil = _nilai(awal, ZonaSasaran.Hasil.KOTAK_SURAT, "h@1")
	var meleset: SkorRute.Hasil = _nilai(awal, ZonaSasaran.Hasil.MELESET, "")
	var ulang: SkorRute.Hasil = _nilai(antar.keadaan, ZonaSasaran.Hasil.KOTAK_SURAT, "h@1")
	check(not SkorRute.hasil_terbuang(antar) and SkorRute.hasil_terbuang(meleset) and SkorRute.hasil_terbuang(ulang) and not SkorRute.hasil_terbuang(null), "hasil_terbuang: antar tidak, meleset ya, ulang ya, null tidak")
	check(UmpanMelayang.dari_hasil(meleset, Vector2.ZERO) == null and UmpanMelayang.dari_hasil(ulang, Vector2.ZERO) == null, "dari_hasil tetap null untuk koran bukan antaran (umpan antaran tidak berubah)")


# --- AC-9: golden dan diff perilaku ---

func _test_golden_skor() -> void:
	_judul.call("Golden skor dari main (AC-9): 1000 urutan lemparan acak, field lama SkorRute persis sama dengan main (sidik FNV-1a)")
	var teks: String = FileAccess.get_file_as_string(GOLDEN)
	var data: Variant = JSON.parse_string(teks)
	check(typeof(data) == TYPE_DICTIONARY, "berkas golden skor main terbaca")
	if typeof(data) != TYPE_DICTIONARY:
		return
	var d: Dictionary = data
	check(int(d["jumlah_urutan"]) == PembantuGoldenSkor.JUMLAH_URUTAN and int(d["seed_awal"]) == PembantuGoldenSkor.SEED_AWAL and int(d["seed_langkah"]) == PembantuGoldenSkor.SEED_LANGKAH, "parameter golden sama dengan pembantu")
	check(str(d["blob_skor_rute_main"]) == "0329ad5b29b1f7558f5482ce0a8fd1311ad85982", "golden dibuat dari skor_rute.gd main (blob 0329ad5b...)")
	var sidik: Array = d["sidik"]
	var beda: Array[int] = []
	for i: int in range(PembantuGoldenSkor.JUMLAH_URUTAN):
		if PembantuGoldenSkor.sidik_urutan(i) != int(sidik[i]):
			beda.append(i)
	check(sidik.size() == PembantuGoldenSkor.JUMLAH_URUTAN and beda.is_empty(), "1000 urutan acak: sidik skor, koin, combo, terantar, status, penanda sama dengan main (selisih: %s)" % [beda.slice(0, 5)])


func _test_urutan_acak_terbuang() -> void:
	_judul.call("Terbuang pada 1000 urutan acak (AC-8): terbuang = jumlah penilaian TIDAK_SAH + ULANG yang dihitung terpisah; koin tidak berubah karenanya")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 424242
	var salah: Array[String] = []
	for i: int in range(1000):
		var s: SkorRute.Keadaan = SkorRute.awal()
		var hitung: int = 0
		var koin: int = 0
		for _l: int in range(rng.randi_range(5, 40)):
			if rng.randf() < 0.1:
				s = SkorRute.putus_combo(s)
				continue
			var h: SkorRute.Hasil = SkorRute.nilai(s, rng.randi_range(0, 5) as ZonaSasaran.Hasil, "r@%d" % rng.randi_range(1, 6), rng.randf() < 0.3, rng.randf_range(0.0, 7.0), rng.randf() < 0.3, rng.randf() < 0.5, rng.randf() < 0.2)
			if h.status != SkorRute.Status.ANTAR:
				hitung += 1
			koin += h.koin_tambah
			s = h.keadaan
		if s.terbuang != hitung or s.koin != koin or SkorRute.potongan(s) != hitung * 5:
			salah.append("urutan %d: terbuang %d (harapan %d) koin %d (harapan %d)" % [i, s.terbuang, hitung, s.koin, koin])
	check(salah.is_empty(), "1000 urutan acak: terbuang = penilaian bukan ANTAR, koin kotor tidak terpengaruh: %s" % [salah.slice(0, 3)])
