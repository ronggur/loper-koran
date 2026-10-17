class_name TesTenggat
extends RefCounted
## Tes logika murni tenggat rute dan tip sesudah tenggat run fase3c-hud-hasil (AC-1, AC-2, AC-18; K-1).
##
## Oracle independen (AC-17): detik tenggat, sisa, detik lewat, menit:detik, skor, dan koin ditulis literal di sini (dihitung tangan dari
## BALANCING 6 dan 7: santai 3,0 u/d, pengali 1,15, ongkos 15, tip 5), bukan dengan memanggil fungsi yang dites.

const FOLDER: String = "res://assets/data/routes/perumahan"

var _cek: Callable
var _judul: Callable


func _init(cek: Callable, judul: Callable) -> void:
	_cek = cek
	_judul = judul


func check(kondisi: bool, label: String) -> void:
	_cek.call(kondisi, label)


func jalankan() -> void:
	_test_config()
	_test_rumus_literal()
	_test_rute_nyata()
	_test_jam_dan_beku()
	_test_tepi_lewat()
	_test_tampilan()
	_test_tip_sesudah_tenggat()
	_test_koin_tidak_berkurang_sesudah_tenggat()


func _test_config() -> void:
	_judul.call("Tenggat: angka Config literal (K-1, BALANCING 6)")
	check(Config.TENGGAT_PENGALI == 1.15, "TENGGAT_PENGALI 1,15")
	check(Config.TENGGAT_TOLERANSI_DETIK == 0.000001, "TENGGAT_TOLERANSI_DETIK 0,000001 (hanya derau float)")
	check(Config.WAKTU_DETIK_PER_MENIT == 60 and Config.KECEPATAN_SANTAI_UD == 3.0, "60 detik per menit; santai 3,0 u/d")


func _test_rumus_literal() -> void:
	_judul.call("Tenggat = ceil(panjang / 3,0 x 1,15) (AC-1): oracle literal, pembulatan tidak membuat 240 menjadi 93")
	# panjang -> detik tenggat, dihitung tangan: 232/3x1,15 = 88,93 -> 89; 236 -> 90,47 -> 91; 240 -> 92,0 tepat -> 92; 24 -> 9,2 -> 10;
	# 3 -> 1,15 -> 2; 30 -> 11,5 -> 12; 0,5 -> 0,19 -> 1.
	var tabel: Array = [[232.0, 89], [236.0, 91], [240.0, 92], [24.0, 10], [3.0, 2], [30.0, 12], [0.5, 1], [0.0, 0], [-10.0, 0], [NAN, 0], [INF, 0]]
	for baris: Array in tabel:
		check(TenggatRute.detik_tenggat(baris[0]) == baris[1], "panjang %s ubin -> tenggat %d detik (dapat %d)" % [baris[0], baris[1], TenggatRute.detik_tenggat(baris[0])])
	var k: TenggatRute.Keadaan = TenggatRute.awal(240.0)
	check(k.tenggat_detik == 92 and k.waktu_detik == 0.0 and not k.berhenti and not TenggatRute.lewat(k), "awal rute 240 ubin: tenggat 92, jam 0, belum lewat")


func _test_rute_nyata() -> void:
	_judul.call("Tenggat rute nyata 20 seed: 89 sampai 92 detik untuk rute 232 sampai 240 ubin (K-1)")
	var pustaka: Array[SegmenRute] = PemuatRute.muat_folder(FOLDER).segmen
	# Tabel literal panjang -> tenggat untuk semua panjang rute yang mungkin (kelipatan 4 dari 232 sampai 240).
	var harapan: Dictionary = {232.0: 89, 236.0: 91, 240.0: 92}
	var semua_ok: bool = true
	var dilihat: Dictionary = {}
	for i: int in range(20):
		var rute: RouteBuilder.Rute = RouteBuilder.bangun(Config.RUTE_SEED_DEV + i, pustaka).rute
		if rute == null or not harapan.has(rute.panjang_ubin):
			semua_ok = false
			continue
		dilihat[rute.panjang_ubin] = true
		if TenggatRute.detik_tenggat(rute.panjang_ubin) != harapan[rute.panjang_ubin]:
			semua_ok = false
	check(semua_ok and not dilihat.is_empty(), "20 rute: panjang 232/236/240 dan tenggat 89/91/92 (panjang terlihat: %s)" % [dilihat.keys()])


func _test_jam_dan_beku() -> void:
	_judul.call("Jam tenggat: maju dt efektif, beku saat jeda (dt 0), berhenti di garis akhir (AC-1)")
	var k: TenggatRute.Keadaan = TenggatRute.awal(240.0)
	k = TenggatRute.langkah(k, 0.5)
	k = TenggatRute.langkah(k, 0.25)
	check(k.waktu_detik == 0.75, "0,5 + 0,25 detik -> jam 0,75")
	var awal_jam: float = k.waktu_detik
	for dt: float in [0.0, -1.0, NAN, INF, -INF]:
		k = TenggatRute.langkah(k, dt)
	check(k.waktu_detik == awal_jam, "dt 0 (jeda), negatif, NaN, tak hingga: jam tidak berubah (beku)")
	var sebelum: TenggatRute.Keadaan = k
	var berhenti: TenggatRute.Keadaan = TenggatRute.hentikan(k)
	check(berhenti.berhenti and berhenti.waktu_detik == 0.75 and not sebelum.berhenti, "hentikan: jam berhenti tanpa mengubah waktu; masukan tidak diubah")
	berhenti = TenggatRute.langkah(berhenti, 10.0)
	check(berhenti.waktu_detik == 0.75, "sesudah garis akhir jam tidak maju lagi (10 detik -> tetap 0,75)")
	var lama: TenggatRute.Keadaan = TenggatRute.awal(240.0)
	var baru: TenggatRute.Keadaan = TenggatRute.langkah(lama, 1.0)
	check(lama.waktu_detik == 0.0 and baru.waktu_detik == 1.0, "langkah tidak mengubah masukan")


func _test_tepi_lewat() -> void:
	_judul.call("Tepi tenggat (AC-1): tepat di tenggat (sisa 0) BELUM lewat; sedikit sesudahnya lewat")
	var k: TenggatRute.Keadaan = TenggatRute.awal(240.0)
	k = TenggatRute.langkah(k, 91.5)
	check(not TenggatRute.lewat(k) and TenggatRute.sisa_detik(k) == 0.5 and TenggatRute.detik_lewat(k) == 0.0, "91,5 detik dari 92: belum lewat, sisa 0,5, lewat 0")
	k = TenggatRute.langkah(k, 0.5)
	check(k.waktu_detik == 92.0 and not TenggatRute.lewat(k) and TenggatRute.sisa_detik(k) == 0.0, "tepat 92,0 detik: sisa 0, BELUM lewat")
	k = TenggatRute.langkah(k, 0.25)
	check(TenggatRute.lewat(k) and TenggatRute.sisa_detik(k) == 0.0 and TenggatRute.detik_lewat(k) == 0.25, "92,25 detik: lewat, sisa 0, lewat 0,25")
	k = TenggatRute.langkah(k, 11.75)
	check(TenggatRute.lewat(k) and TenggatRute.detik_lewat(k) == 12.0, "104 detik: lewat 12")


func _test_tampilan() -> void:
	_judul.call("Tampilan tenggat: detik bulat ke atas, menit:detik (O-8)")
	var k: TenggatRute.Keadaan = TenggatRute.awal(240.0)
	check(TenggatRute.detik_tampil(k) == 92 and TenggatRute.menit_detik(92) == Vector2i(1, 32), "awal: 92 detik -> 1:32")
	k = TenggatRute.langkah(k, 0.01)
	check(TenggatRute.detik_tampil(k) == 92, "0,01 detik berjalan: tampil masih 92 (ke atas)")
	k = TenggatRute.langkah(k, 0.99)
	check(TenggatRute.detik_tampil(k) == 91, "1,0 detik berjalan: tampil 91")
	k = TenggatRute.langkah(k, 91.0)
	check(TenggatRute.detik_tampil(k) == 0 and not TenggatRute.lewat(k), "tepat 92: tampil 0:00, belum lewat")
	k = TenggatRute.langkah(k, 0.01)
	check(TenggatRute.lewat(k) and TenggatRute.detik_tampil(k) == 1, "0,01 detik sesudah tenggat: LEWAT +0:01")
	k = TenggatRute.langkah(k, 11.99)
	check(TenggatRute.detik_tampil(k) == 12 and TenggatRute.menit_detik(12) == Vector2i(0, 12), "12 detik sesudah tenggat: +0:12")
	var tabel: Array = [[0, Vector2i(0, 0)], [59, Vector2i(0, 59)], [60, Vector2i(1, 0)], [61, Vector2i(1, 1)], [125, Vector2i(2, 5)], [-5, Vector2i(0, 0)]]
	for baris: Array in tabel:
		check(TenggatRute.menit_detik(baris[0]) == baris[1], "%d detik -> %s" % [baris[0], baris[1]])


func _test_tip_sesudah_tenggat() -> void:
	_judul.call("Tip hilang sesudah tenggat (AC-2, K-1): ongkos, skor, combo tetap; tip 0, jumlah tip tidak naik")
	var k: SkorRute.Keadaan = SkorRute.awal()
	# Sebelum tenggat: teras ke pemberi tip, santai, antaran pertama: skor 100, koin 15 + 5.
	var h1: SkorRute.Hasil = SkorRute.nilai(k, ZonaSasaran.Hasil.TERAS, "a@1", false, 3.0, true, false, false)
	check(h1.status == SkorRute.Status.ANTAR and h1.skor_tambah == 100 and h1.koin_tambah == 20 and h1.tip == 5, "sebelum tenggat: +100 skor, +20 koin (15 + tip 5)")
	check(h1.keadaan.jumlah_tip == 1 and h1.keadaan.koin_tip == 5 and h1.keadaan.koin == 20 and h1.keadaan.beruntun == 1, "sebelum tenggat: jumlah tip 1, koin tip 5, koin 20, beruntun 1")
	# Sesudah tenggat: teras ke pemberi tip berikutnya, antaran kedua beruntun (x1,1): skor 110, koin 15, tip 0.
	var h2: SkorRute.Hasil = SkorRute.nilai(h1.keadaan, ZonaSasaran.Hasil.TERAS, "a@2", false, 3.0, true, false, true)
	check(h2.status == SkorRute.Status.ANTAR and h2.skor_tambah == 110 and h2.koin_tambah == 15 and h2.tip == 0, "sesudah tenggat: +110 skor (combo x1,1), +15 koin, tip 0")
	check(h2.keadaan.jumlah_tip == 1 and h2.keadaan.koin_tip == 5 and h2.keadaan.koin == 35 and h2.keadaan.skor == 210 and h2.keadaan.beruntun == 2 and h2.keadaan.terantar.has("a@2"), "sesudah tenggat: jumlah tip tetap 1, koin 35, skor 210, combo naik ke 2, rumah terantar")
	check(h2.pengali_combo == 1.1 and h2.urutan_beruntun == 2, "sesudah tenggat combo tetap berjalan (x1,1, urutan 2: nada combo tetap naik)")
	# Kotak surat dan halaman pemberi tip sesudah tenggat: sama seperti sebelum (tidak pernah ada tip di sana).
	var h3: SkorRute.Hasil = SkorRute.nilai(h2.keadaan, ZonaSasaran.Hasil.KOTAK_SURAT, "a@3", false, 3.0, true, false, true)
	check(h3.koin_tambah == 15 and h3.tip == 0 and h3.skor_tambah == 120, "kotak surat pemberi tip sesudah tenggat: +15, tip 0, skor 120 (x1,2)")
	# Umpan balik melayang: tanpa baris tip sesudah tenggat.
	var e: UmpanMelayang.Entri = UmpanMelayang.dari_hasil(h2, Vector2.ZERO)
	check(e != null and e.ongkos == 15 and e.tip == 0, "umpan balik melayang sesudah tenggat: +15 tanpa tip")
	# Lewat KoranLempar: nilai_koran meneruskan status tenggat.
	var rute: RouteBuilder.Rute = RouteBuilder.Rute.new()
	rute.id_pemberi_tip = {"r@1": true}
	var koran: KoranLempar.Koran = KoranLempar.Koran.new()
	koran.mendarat = true
	koran.hasil = ZonaSasaran.Hasil.TERAS
	koran.id_rumah = "r@1"
	var hk_sebelum: SkorRute.Hasil = SkorRute.nilai_koran(SkorRute.awal(), koran, rute, false, false)
	var hk_sesudah: SkorRute.Hasil = SkorRute.nilai_koran(SkorRute.awal(), koran, rute, false, true)
	check(hk_sebelum.tip == 5 and hk_sebelum.koin_tambah == 20 and hk_sesudah.tip == 0 and hk_sesudah.koin_tambah == 15, "nilai_koran: tip 5 sebelum tenggat, 0 sesudahnya (koin 20 lawan 15)")
	check(SkorRute.nilai_koran(SkorRute.awal(), koran, rute, false).tip == 5, "nilai_koran tanpa status tenggat = belum lewat (perilaku 3B)")


func _test_koin_tidak_berkurang_sesudah_tenggat() -> void:
	_judul.call("Koin tidak pernah berkurang, juga sesudah tenggat lewat (AC-2, AC-18, prinsip 2)")
	var k: SkorRute.Keadaan = SkorRute.awal()
	var hasil_semua: Array = [ZonaSasaran.Hasil.TERAS, ZonaSasaran.Hasil.MELESET, ZonaSasaran.Hasil.BUKAN_PELANGGAN, ZonaSasaran.Hasil.HALAMAN, ZonaSasaran.Hasil.JENDELA, ZonaSasaran.Hasil.KOTAK_SURAT]
	var turun: bool = false
	var n: int = 0
	for lewat: bool in [false, true]:
		for hasil: ZonaSasaran.Hasil in hasil_semua:
			for tip: bool in [false, true]:
				n += 1
				var koin_sebelum: int = k.koin
				var h: SkorRute.Hasil = SkorRute.nilai(k, hasil, "k@%d" % n, false, 6.0, tip, false, lewat)
				k = h.keadaan
				if k.koin < koin_sebelum or (lewat and h.tip != 0):
					turun = true
				k = SkorRute.putus_combo(k)
	check(not turun, "24 koran campuran sebelum dan sesudah tenggat: koin tidak pernah turun, tip 0 sesudah tenggat")
	check(k.koin_tip == 5 and k.jumlah_tip == 1, "hanya satu tip (teras pemberi tip sebelum tenggat): koin tip 5")
