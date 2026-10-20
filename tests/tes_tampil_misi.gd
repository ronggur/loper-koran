class_name TesTampilMisi
extends RefCounted
## Tes run fase4b-misi-kucing iterasi 2 (QA-001, QA-002; M-2' dan M-3'): kucing misi "terlihat" di LAYAR >= `MISI_TAMPIL_DETIK_MIN` (+ cadangan) pada
## `KECEPATAN_NGEBUT_UD` di semua kombinasi lebar viewport (640, 667, 780, 800), posisi lateral sepeda (-2 sampai +2), goyangan letak kucing, dan dorongan
## kecepatan; dengan petunjuk dari lemparan tepat waktu terlihat bertambah >= `MISI_PETUNJUK_TAMBAH_DETIK_MIN` (+ cadangan).
##
## Oracle independen (AC-19): posisi kaki kucing di layar, persegi badan + kilau, area layar, dan HUD ditulis ulang tes dari konstanta mentah (`UBIN_*`, `KAMERA_*`,
## `MISI_KUCING_*`, `RADAR_*`), bukan memanggil `TampilMisi`. "Terlihat" = badan utuh di area (di bawah strip HUD atas, di luar strip radar) ATAU penanda tepi layar
## yang dihitung `TampilMisi` berada utuh di dalam layar, di luar radar, strip HUD atas, dan zona bel/panel bawah. Nilai iterasi 1 (12 dan 18 ubin)
## ditolak oleh syarat yang sama (mutan nyata).

const LEBAR_KASUS: Array[float] = [640.0, 667.0, 780.0, 800.0]
const TINGGI: float = 360.0
const LANGKAH_JARAK: float = 0.05

var _cek: Callable
var _judul: Callable


func _init(cek: Callable, judul: Callable) -> void:
	_cek = cek
	_judul = judul


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_test_syarat_waktu_dan_mutan()
	_test_semua_kombinasi_terlihat()
	_test_penanda_murni()
	_test_pola_panah()
	_test_indeks_terlihat()


# --- Oracle tes (konstanta mentah, bukan TampilMisi) ---

## Kaki kucing di layar: sepeda di (lebar/3, 0,75 tinggi) + geseran dorongan, kucing `d` ubin di depan dan `selisih_lateral` ubin ke samping (iso 2:1).
func _kaki(lebar: float, geser: Vector2, selisih_lateral: float, d: float) -> Vector2:
	var sepeda: Vector2 = Vector2(lebar * 0.3333, TINGGI * 0.75) + geser
	return sepeda + Vector2((selisih_lateral + d) * 32.0, (selisih_lateral - d) * 16.0)


func _sepeda(lebar: float, geser: Vector2) -> Vector2:
	return Vector2(lebar * 0.3333, TINGGI * 0.75) + geser


## Badan kucing (sel 46x38 dengan titik pijak (18, 21)) disatukan dengan kotak kilau 11x11 yang pojok kirinya (-5, -33) dari titik pijak.
func _badan(kaki: Vector2) -> Rect2:
	var sel: Rect2 = Rect2(kaki.x - 18.0, kaki.y - 21.0, 46.0, 38.0)
	var kilau: Rect2 = Rect2(kaki.x - 5.0, kaki.y - 33.0, 11.0, 11.0)
	return sel.merge(kilau)


## Area badan: x dari 22 sampai lebar - 22, y dari 84 sampai bawah layar (strip HUD atas berakhir sebelum y 82, strip radar sebelum x 16).
func _area(lebar: float) -> Rect2:
	return Rect2(22.0, 84.0, lebar - 44.0, TINGGI - 84.0)


## Persegi penanda utuh dan sah: di layar, di dalam x 22..lebar-22, y 84..260 (di atas bel dan panel bawah), di luar strip radar (x < 16 dan x > lebar - 16, y 10..182).
func _penanda_sah(r: Rect2, lebar: float) -> bool:
	var layar: Rect2 = Rect2(0.0, 0.0, lebar, TINGGI)
	var boleh: Rect2 = Rect2(22.0, 84.0, lebar - 44.0, 260.0 - 84.0)
	var radar_a: Rect2 = Rect2(4.0, 10.0, 12.0, 172.0)
	var radar_b: Rect2 = Rect2(lebar - 16.0, 10.0, 12.0, 172.0)
	return layar.encloses(r) and boleh.encloses(r) and not r.intersects(radar_a) and not r.intersects(radar_b)


## Syarat M-2' dan M-3' untuk sepasang jarak: waktu terlihat tanpa petunjuk dan tambahan karena petunjuk pada ngebut, dengan cadangan.
func _memenuhi(jarak: float, jarak_petunjuk: float) -> bool:
	var ngebut: float = 6.0
	return jarak / ngebut >= 2.0 + 0.25 and (jarak_petunjuk - jarak) / ngebut >= 1.0 + 0.25


# --- Tes ---

func _test_syarat_waktu_dan_mutan() -> void:
	_judul.call("Kucing misi: syarat waktu terlihat (M-2') dan tambahan petunjuk (M-3'); nilai iterasi 1 ditolak (QA-001, QA-002)")
	check(Config.KECEPATAN_NGEBUT_UD == 6.0 and Config.MISI_TAMPIL_DETIK_MIN == 2.0 and Config.MISI_PETUNJUK_TAMBAH_DETIK_MIN == 1.0 and Config.MISI_TAMPIL_CADANGAN_DETIK == 0.25, "oracle tes: ngebut 6,0 u/d, minimum 2,0 detik, tambahan petunjuk 1,0 detik, cadangan 0,25 detik")
	check(not _memenuhi(12.0, 18.0), "nilai iterasi 1 (12 dan 18 ubin) tidak memenuhi syarat: 2,0 detik tanpa cadangan, tambahan 1,0 detik tanpa cadangan")
	check(not _memenuhi(12.0, 22.0) and not _memenuhi(14.0, 18.0), "12 ubin saja, atau 18 ubin saja, tidak memenuhi")
	check(_memenuhi(Config.MISI_TAMPIL_JARAK_UBIN, Config.MISI_TAMPIL_PETUNJUK_JARAK_UBIN), "nilai Config sekarang (%.1f dan %.1f ubin) memenuhi kedua syarat" % [Config.MISI_TAMPIL_JARAK_UBIN, Config.MISI_TAMPIL_PETUNJUK_JARAK_UBIN])
	check(Config.MISI_TAMPIL_JARAK_UBIN / Config.KECEPATAN_NGEBUT_UD >= Config.MISI_TAMPIL_DETIK_MIN + Config.MISI_TAMPIL_CADANGAN_DETIK, "tanpa petunjuk: %.2f detik >= %.2f + %.2f" % [Config.MISI_TAMPIL_JARAK_UBIN / Config.KECEPATAN_NGEBUT_UD, Config.MISI_TAMPIL_DETIK_MIN, Config.MISI_TAMPIL_CADANGAN_DETIK])
	check((Config.MISI_TAMPIL_PETUNJUK_JARAK_UBIN - Config.MISI_TAMPIL_JARAK_UBIN) / Config.KECEPATAN_NGEBUT_UD >= Config.MISI_PETUNJUK_TAMBAH_DETIK_MIN + Config.MISI_TAMPIL_CADANGAN_DETIK, "dengan petunjuk: tambahan %.2f detik >= %.2f + %.2f" % [(Config.MISI_TAMPIL_PETUNJUK_JARAK_UBIN - Config.MISI_TAMPIL_JARAK_UBIN) / Config.KECEPATAN_NGEBUT_UD, Config.MISI_PETUNJUK_TAMBAH_DETIK_MIN, Config.MISI_TAMPIL_CADANGAN_DETIK])


## Setiap jarak dari `MISI_TAMPIL_PETUNJUK_JARAK_UBIN` sampai sejajar: badan utuh di area ATAU penanda tepi layar sah. Dijalankan pada empat lebar, lateral sepeda
## -2 sampai +2, goyangan lateral kucing, dan tiga dorongan kecepatan.
func _test_semua_kombinasi_terlihat() -> void:
	_judul.call("Kucing misi terlihat di layar (badan utuh atau penanda tepi) pada SEMUA lebar, lateral sepeda, goyangan, dan dorongan, sampai jarak petunjuk (M-2', M-3')")
	var geser_set: Array[Vector2] = [DoronganKecepatan.geser_target(6.0), DoronganKecepatan.geser_target(3.0), DoronganKecepatan.geser_target(1.5)]
	var kombinasi: int = 0
	var celah: int = 0
	var penanda_salah: int = 0
	var badan_tanpa_penanda: int = 0
	var arah_salah: int = 0
	var badan_hilang_lagi: int = 0
	var contoh: String = ""
	for lebar: float in LEBAR_KASUS:
		var area_tes: Rect2 = _area(lebar)
		for geser: Vector2 in geser_set:
			var sepeda: Vector2 = _sepeda(lebar, geser)
			for lateral_sepeda: float in [-2.0, -1.5, -1.0, -0.5, 0.0, 0.5, 1.0, 1.5, 2.0]:
				for goyang: float in [-0.25, 0.0, 0.25]:
					kombinasi += 1
					var selisih_lateral: float = (Config.MISI_KUCING_LATERAL_UBIN + goyang) - lateral_sepeda
					var badan_pernah: bool = false
					var d: float = Config.MISI_TAMPIL_PETUNJUK_JARAK_UBIN
					while d > 0.0:
						var kaki: Vector2 = _kaki(lebar, geser, selisih_lateral, d)
						var utuh: bool = area_tes.encloses(_badan(kaki))
						var p: TampilMisi.Penanda = TampilMisi.penanda(0, sepeda, kaki, TampilMisi.area(lebar, TINGGI), TINGGI)
						var sah: bool = _penanda_sah(TampilMisi.rect_penanda(p), lebar)
						if not sah:
							penanda_salah += 1
						if not utuh and not sah:
							celah += 1
							contoh = "lebar %.0f lateral %.1f goyang %.2f geser %s d %.2f penanda %s" % [lebar, lateral_sepeda, goyang, geser, d, TampilMisi.rect_penanda(p)]
						# TampilMisi harus sepakat dengan oracle tes tentang kapan badan utuh.
						if TampilMisi.badan_terlihat(TampilMisi.kaki_kucing(sepeda, lateral_sepeda, 0.0, Config.MISI_KUCING_LATERAL_UBIN + goyang, d), TampilMisi.area(lebar, TINGGI)) != utuh:
							badan_tanpa_penanda += 1
						# Arah panah: menyentuh tepi atas -> atas; kalau tidak di tepi kanan -> kanan.
						if p.arah == TampilMisi.Arah.KANAN and TampilMisi.rect_penanda(p).end.x < lebar - 22.0 - 0.5:
							arah_salah += 1
						if utuh:
							badan_pernah = true
						elif badan_pernah and d > 0.5:
							badan_hilang_lagi += 1
						d -= LANGKAH_JARAK
	print("  [tampil_misi] %d kombinasi, jarak sampai sejajar sampel %.2f ubin; contoh celah: %s" % [kombinasi, LANGKAH_JARAK, contoh])
	check(kombinasi == 4 * 3 * 9 * 3, "%d kombinasi (4 lebar x 3 dorongan x 9 lateral sepeda x 3 goyangan)" % kombinasi)
	check(celah == 0, "tidak ada jarak (sampai petunjuk 22 ubin) yang kucingnya tidak terlihat sama sekali: %d celah, contoh: %s" % [celah, contoh])
	check(penanda_salah == 0, "penanda tepi layar selalu utuh di layar, di luar radar, strip HUD atas, dan zona bel/panel bawah: %d pelanggaran" % penanda_salah)
	check(badan_tanpa_penanda == 0, "TampilMisi.badan_terlihat sama dengan oracle tes pada semua sampel: %d selisih" % badan_tanpa_penanda)
	check(arah_salah == 0, "panah menunjuk ke kanan hanya bila di tepi kanan area: %d salah" % arah_salah)
	check(badan_hilang_lagi == 0, "sekali badan utuh di area (d > 0,5 ubin), badan tidak hilang lagi saat mendekat: %d kejadian" % badan_hilang_lagi)


func _test_penanda_murni() -> void:
	_judul.call("TampilMisi: kaki kucing, area, penanda tepi (jepit ke persegi pusat), penanda_aktif (aktif utuh tanpa penanda, belakang tanpa penanda)")
	var sepeda: Vector2 = Vector2(213.0, 270.0)
	var kaki: Vector2 = TampilMisi.kaki_kucing(sepeda, 0.0, 10.0, -2.0, 20.0)
	check(kaki == sepeda + Vector2((-2.0 + 10.0) * 32.0, (-2.0 - 10.0) * 16.0), "kaki kucing: sepeda + proyeksi iso selisih (lateral -2, maju 10) = %s" % [kaki])
	var area_a: Rect2 = TampilMisi.area(640.0, 360.0)
	check(area_a == Rect2(22.0, 84.0, 596.0, 276.0), "area tanpa inset di 640: %s" % [area_a])
	var area_inset: Rect2 = TampilMisi.area(640.0, 360.0, 30, 6, 10)
	check(area_inset == Rect2(52.0, 90.0, 556.0, 270.0), "area dengan inset zona aman (30, 6, 10): %s" % [area_inset])
	var kotak: Rect2 = TampilMisi.area_penanda(area_a, 360.0)
	check(kotak == Rect2(27.0, 89.0, 585.0, 165.0), "persegi pusat penanda: area dipersempit setengah ukuran dan dipotong 100 px dari bawah: %s" % [kotak])
	# Kaki jauh di atas kanan: penanda di tepi atas persegi pusat, panah ke atas.
	var p_atas: TampilMisi.Penanda = TampilMisi.penanda(2, sepeda, Vector2(500.0, -300.0), area_a, 360.0)
	check(p_atas.titik == 2 and p_atas.pusat.y == 89.0 and p_atas.arah == TampilMisi.Arah.ATAS and kotak.grow(0.5).has_point(p_atas.pusat), "kaki jauh di atas: penanda di tepi atas persegi pusat (y 89), panah atas: %s" % [p_atas.pusat])
	var p_tepi: TampilMisi.Penanda = TampilMisi.penanda(0, sepeda, Vector2(2000.0, 250.0), area_a, 360.0)
	check(p_tepi.arah == TampilMisi.Arah.KANAN and p_tepi.pusat.x == 612.0 and kotak.grow(0.5).has_point(p_tepi.pusat), "kaki jauh di kanan: penanda di tepi kanan (x 612), panah kanan: %s" % [p_tepi.pusat])
	var p_dalam: TampilMisi.Penanda = TampilMisi.penanda(0, sepeda, Vector2(300.0, 200.0), area_a, 360.0)
	check(p_dalam.pusat == Vector2(300.0, 214.0) and p_dalam.arah == TampilMisi.Arah.ATAS, "kaki di dalam persegi pusat: penanda 14 px di bawah kaki (tidak menutupi badan), panah atas")
	var p_bawah: TampilMisi.Penanda = TampilMisi.penanda(0, Vector2(213.0, 330.0), Vector2(250.0, 345.0), area_a, 360.0)
	check(kotak.grow(0.5).has_point(p_bawah.pusat), "sepeda di bawah persegi pusat: awal garis dijepit ke persegi, penanda tetap di dalamnya: %s" % [p_bawah.pusat])
	# Persegi badan: sel penuh disatukan dengan kilau.
	var badan: Rect2 = TampilMisi.rect_badan(Vector2(100.0, 100.0))
	check(badan == Rect2(82.0, 67.0, 46.0, 50.0), "persegi badan + kilau berkaki di (100, 100): %s" % [badan])
	check(TampilMisi.badan_terlihat(Vector2(300.0, 200.0), area_a) and not TampilMisi.badan_terlihat(Vector2(300.0, 100.0), area_a) and not TampilMisi.badan_terlihat(Vector2(610.0, 200.0), area_a), "badan utuh di area: ya di (300, 200); tidak bila kilau menyentuh strip HUD atas (kaki y 100); tidak bila sel melewati tepi kanan area")
	# penanda_aktif: dari keadaan MissionManager.
	var r: RencanaMisi.Rencana = _rencana_uji()
	var k: MissionManager.Keadaan = MissionManager.awal(r)
	var m: MissionManager.Masukan = MissionManager.Masukan.new()
	m.maju_ubin = 8.0
	m.dt = 1.0 / 60.0
	k = MissionManager.langkah(k, m).keadaan
	var sepeda_n: Vector2 = TampilMisi.sepeda_layar_nominal(640.0, 360.0, 6.0)
	var daftar: Array[TampilMisi.Penanda] = TampilMisi.penanda_aktif(k, sepeda_n, 0.0, 8.0, area_a, 360.0)
	check(daftar.size() == 1 and daftar[0].titik == 0, "kucing 1 terlihat (12 ubin di depan, di luar layar): satu penanda untuk titik 0")
	k = MissionManager.langkah(k, _masukan_uji(31.0)).keadaan
	check(MissionManager.indeks_terlihat(k) == [1, 2] or MissionManager.indeks_terlihat(k) == [1], "setelah kucing 1 dilewati, hanya titik yang belum selesai di indeks terlihat: %s" % [MissionManager.indeks_terlihat(k)])
	var belakang: Array[TampilMisi.Penanda] = TampilMisi.penanda_aktif(k, sepeda_n, 0.0, 41.0, area_a, 360.0)
	var punya_belakang: bool = false
	for p: TampilMisi.Penanda in belakang:
		if r.titik[p.titik].maju_ubin <= 41.0:
			punya_belakang = true
	check(not punya_belakang, "kucing yang sudah di belakang sepeda tidak diberi penanda")
	# Kucing aktif yang badannya utuh di layar tidak diberi penanda; kucing berikutnya yang sudah terlihat tetap diberi penanda (badannya tidak digambar).
	var k2: MissionManager.Keadaan = MissionManager.langkah(MissionManager.awal(r), _masukan_uji(15.0)).keadaan
	var dekat: Array[TampilMisi.Penanda] = TampilMisi.penanda_aktif(k2, sepeda_n, -2.0, 15.0, area_a, 360.0)
	check(MissionManager.indeks_terlihat(k2) == [0] and dekat.is_empty(), "kucing aktif 5 ubin di depan, badan utuh di layar: tanpa penanda (%d penanda)" % dekat.size())
	var k3: MissionManager.Keadaan = MissionManager.langkah(k2, _masukan_uji(18.0)).keadaan
	var dua: Array[TampilMisi.Penanda] = TampilMisi.penanda_aktif(k3, sepeda_n, -2.0, 18.0, area_a, 360.0)
	check(MissionManager.indeks_terlihat(k3) == [0, 1] and dua.size() == 1 and dua[0].titik == 1, "kucing 2 sudah terlihat tetapi bukan langkah aktif: penanda untuk titik 1, kucing 1 (badan utuh) tanpa penanda")
	check(TampilMisi.penanda_aktif(null, sepeda_n, 0.0, 0.0, area_a, 360.0).is_empty(), "tanpa keadaan misi: tidak ada penanda")


func _rencana_uji() -> RencanaMisi.Rencana:
	var r: RencanaMisi.Rencana = RencanaMisi.Rencana.new()
	r.id_misi = "p1_kucing"
	r.batas_rumah = 12
	r.jumlah_seberang = 14
	r.maju_batas_ubin = 96.0
	r.panjang_ubin = 200.0
	r.hadiah_koin = 75
	r.target = 1
	for i: int in range(12):
		r.akhir_kavling_ubin.append(float(8 * (i + 1)))
	for maju: float in [20.0, 31.5, 43.0]:
		var t: RencanaMisi.Titik = RencanaMisi.Titik.new()
		t.jenis = "lihat"
		t.nama = "atap"
		t.lateral_ubin = -2.0
		t.maju_ubin = maju
		t.maju_rumah_ubin = maju - 0.5
		t.petunjuk_awal_ubin = 0.0
		t.petunjuk_akhir_ubin = maju - 0.5
		r.titik.append(t)
	return r


func _masukan_uji(maju: float) -> MissionManager.Masukan:
	var m: MissionManager.Masukan = MissionManager.Masukan.new()
	m.maju_ubin = maju
	m.dt = 1.0 / 60.0
	return m


func _test_pola_panah() -> void:
	_judul.call("Penanda: pola panah 11 lebar, diputar ke kanan jadi 10 lebar x 11 tinggi, perintah gambar dua warna bergantian, tanpa teks")
	var atas: Array[String] = PolaPiksel.PANAH_KUCING_ATAS
	var rata: bool = true
	for baris: String in atas:
		rata = rata and baris.length() == 11
	check(rata and atas.size() == 10, "panah atas 11x10, semua baris sama panjang")
	var pola_tepi: Array[String] = PolaPiksel.putar_kanan(atas)
	check(pola_tepi.size() == 11 and pola_tepi[0].length() == 10, "panah kanan hasil putar: 11 baris x 10 kolom")
	check(PolaPiksel.putar_kanan(pola_tepi).size() == 10 and PolaPiksel.putar_kanan(PolaPiksel.putar_kanan(PolaPiksel.putar_kanan(pola_tepi))) == atas, "empat kali putar kembali ke panah atas")
	check(PolaPiksel.putar_kanan([] as Array[String]).is_empty() and PolaPiksel.putar_kanan(["ab", "c"] as Array[String]).is_empty(), "pola kosong atau tidak persegi panjang: hasil kosong")
	var p: TampilMisi.Penanda = TampilMisi.Penanda.new()
	p.pusat = Vector2(300.0, 100.0)
	check(PenandaKucing.kedip(0.0) == 0 and PenandaKucing.kedip(0.41) == 1 and PenandaKucing.kedip(0.81) == 0, "kedip berganti tiap 0,4 detik")
	check(PenandaKucing.perintah(p, 0.0) != PenandaKucing.perintah(p, 0.41) and not PenandaKucing.perintah(p, 0.0).is_empty(), "perintah gambar berganti warna antar keadaan kedip")
	p.arah = TampilMisi.Arah.KANAN
	check(TampilMisi.pola(TampilMisi.Arah.KANAN) == pola_tepi and TampilMisi.pola(TampilMisi.Arah.ATAS) == atas, "TampilMisi.pola memilih panah sesuai arah")
	var rect_p: Rect2 = TampilMisi.rect_penanda(p)
	check(rect_p.size == Vector2(11.0, 11.0) and rect_p.position == p.pusat - Vector2(5.0, 5.0), "persegi penanda 11x11, piksel tengah di titik penanda")


func _test_indeks_terlihat() -> void:
	_judul.call("MissionManager.indeks_terlihat: semua langkah belum selesai yang sudah masuk jarak (tidak menunggu langkah sebelumnya selesai)")
	var r: RencanaMisi.Rencana = _rencana_uji()
	var k: MissionManager.Keadaan = MissionManager.awal(r)
	check(MissionManager.indeks_terlihat(k).is_empty() and MissionManager.indeks_terlihat(null).is_empty(), "awal: tidak ada yang terlihat; keadaan null: kosong")
	var h: MissionManager.Hasil = MissionManager.langkah(k, _masukan_uji(6.0))
	check(MissionManager.indeks_terlihat(h.keadaan) == [0] and h.jumlah(MissionManager.Peristiwa.TERLIHAT) == 1, "maju 6,0 (kucing 1 di 20, jarak 14): hanya kucing 1")
	h = MissionManager.langkah(h.keadaan, _masukan_uji(17.5))
	check(MissionManager.indeks_terlihat(h.keadaan) == [0, 1] and h.keadaan.langkah == 0 and h.jumlah(MissionManager.Peristiwa.TERLIHAT) == 1, "maju 17,5 (kucing 2 di 31,5): kucing 2 terlihat padahal langkah 1 masih aktif (jarak antar kucing 11,5 < 14)")
	h = MissionManager.langkah(h.keadaan, _masukan_uji(20.0))
	check(MissionManager.indeks_terlihat(h.keadaan) == [1] and h.keadaan.langkah == 1, "kucing 1 dilewati: hanya kucing 2 yang tersisa")
	var selesai: MissionManager.Hasil = MissionManager.langkah(h.keadaan, _masukan_uji(100.0))
	check(MissionManager.indeks_terlihat(selesai.keadaan).is_empty(), "misi selesai atau gagal: tidak ada yang terlihat")
