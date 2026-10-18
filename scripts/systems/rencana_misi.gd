class_name RencanaMisi
extends RefCounted
## Rencana misi Cari (kucing P1) untuk satu rute, logika murni (M-1, M-11, AC-3 dan AC-4 run fase4b-misi-kucing, usulan; GDD 10.2 sampai 10.6).
##
## Dari `DataMisi` (template cari), `RouteBuilder.Rute`, dan benih -> daftar titik kucing di RUMAH SISI SEBERANG ("rumah" = semua rumah seberang
## urut maju, pelanggan atau bukan; satuan yang sama untuk batas 12 dan label "N rumah" di HUD). Rumah titik pertama dihitung dari rumah pertama
## rute (`rumah_dari_mulai`), tiap titik berikutnya dari titik sebelumnya (`rumah_dari_sebelumnya`); total tidak pernah melewati `batas.rumah`
## karena jumlah maks rentang sudah divalidasi `DataMisi`. Pilihan angka dalam rentang dari `RandomNumberGenerator` berseed (tanpa `randi()`):
## benih sama = rencana sama. Titik tidak boleh jatuh di rumah yang dekat mobil garasi seberang (`MISI_KUCING_JAUH_MOBIL_UBIN`; mobil mundur
## menutup separuh jalan): bila pilihan acak terkena, nilai lain dalam rentang dicoba (mulai dari pilihan acak, berputar), lalu titik sebelumnya
## dicoba ulang; tidak ada susunan sah = rencana tidak sah (`sah()` false, tanpa titik). Rencana TIDAK mengubah `Rute` dan tidak membaca berkas.
##
## Titik kucing = (lateral `MISI_KUCING_LATERAL_UBIN`, maju awal kavling + `MISI_KUCING_MAJU_UBIN`) digoyang satu langkah acak berseed ke kedua arah
## (`MISI_KUCING_GOYANG_*`, supaya letak kucing tidak persis sama di setiap hari): di trotoar depan pagar, sebelum zona kotak surat rumah (zona mulai
## di maju 1,25 dari awal kavling). Persegi kucing di tanah (`persegi_kucing`) diperiksa tes tidak menimpa zona kotak surat pelanggan mana pun.
##
## Jendela petunjuk titik ke-i (M-3): rumah-rumah dari rumah titik sebelumnya (atau awal rute untuk titik pertama) sampai SEBELUM rumah titik ini
## (`petunjuk_awal_ubin` inklusif, `petunjuk_akhir_ubin` eksklusif, keduanya jarak maju awal kavling): lemparan tepat ke kotak surat pelanggan di
## rumah itu memberi petunjuk untuk titik ke-i.


## Satu titik kucing.
class Titik extends RefCounted:
	## `lihat` atau `tangkap`.
	var jenis: String = ""
	## Nama titik di data (`atap`, `bawah_mobil_tamu`, `balik_pot`).
	var nama: String = ""
	## Rumah ke-N di antara rumah seberang (mulai 1 dari rumah pertama rute).
	var indeks_rumah: int = 0
	var id_rumah: String = ""
	## Awal kavling rumah titik, ubin dari awal rute.
	var maju_rumah_ubin: float = 0.0
	## Letak kucing: lateral (negatif = seberang) dan maju dari awal rute, ubin.
	var lateral_ubin: float = 0.0
	var maju_ubin: float = 0.0
	## Hanya `tangkap`.
	var radius_ubin: float = 0.0
	var lama_berhenti_detik: float = 0.0
	## Jendela petunjuk: jarak maju awal kavling rumah, `petunjuk_awal_ubin` <= maju rumah yang dilempar < `petunjuk_akhir_ubin`.
	var petunjuk_awal_ubin: float = 0.0
	var petunjuk_akhir_ubin: float = 0.0


## Rencana satu rute.
class Rencana extends RefCounted:
	var id_misi: String = ""
	var titik: Array[Titik] = []
	## Batas rumah misi (`batas.rumah`) dan berapa rumah seberang yang ada di rute.
	var batas_rumah: int = 0
	var jumlah_seberang: int = 0
	## Jarak maju akhir kavling tiap rumah seberang yang dihitung (paling banyak `batas_rumah` rumah pertama), ubin dari awal rute.
	var akhir_kavling_ubin: Array[float] = []
	## Pemain yang maju melewati ini sebelum menangkap = gagal: akhir kavling rumah ke-`batas_rumah`, atau akhir rute bila rumah seberang kurang.
	var maju_batas_ubin: float = 0.0
	var panjang_ubin: float = 0.0
	## Koin hadiah bila selesai (`DataMisi.hadiah_koin`).
	var hadiah_koin: int = 0
	## Jumlah target yang ditangkap (`target.jumlah`).
	var target: int = 0

	## True bila rencana punya titik dan batas yang sah.
	func sah() -> bool:
		return not titik.is_empty() and panjang_ubin > 0.0


## Rencana untuk `misi` pada `rute` dengan `benih`. Rencana kosong (tidak sah) bila misi bukan Cari, rute null, atau tidak ada susunan sah.
static func buat(misi: DataMisi, rute: RouteBuilder.Rute, benih: int) -> Rencana:
	var rencana: Rencana = Rencana.new()
	if misi == null or rute == null or misi.template != "cari":
		return rencana
	var langkah: Array[DataMisi.LangkahCari] = misi.langkah_cari()
	if langkah.is_empty():
		return rencana
	var seberang: Array[RouteBuilder.RumahRute] = rumah_seberang(rute)
	rencana.id_misi = misi.id
	rencana.batas_rumah = misi.batas_rumah()
	rencana.jumlah_seberang = seberang.size()
	rencana.panjang_ubin = rute.panjang_ubin
	rencana.hadiah_koin = misi.hadiah_koin()
	rencana.target = misi.target_jumlah()
	var dihitung: int = mini(rencana.batas_rumah, seberang.size())
	for i: int in range(dihitung):
		rencana.akhir_kavling_ubin.append(seberang[i].maju_ubin + float(Config.RUTE_PETAK_UBIN))
	rencana.maju_batas_ubin = rencana.akhir_kavling_ubin[dihitung - 1] if seberang.size() >= rencana.batas_rumah and dihitung > 0 else rute.panjang_ubin
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = benih
	var indeks: Array[int] = []
	if not _pilih(langkah, 0, 0, dihitung, seberang, rute, rng, indeks):
		return rencana
	for i: int in range(langkah.size()):
		var rumah: RouteBuilder.RumahRute = seberang[indeks[i] - 1]
		var t: Titik = Titik.new()
		t.jenis = langkah[i].jenis
		t.nama = langkah[i].titik
		t.indeks_rumah = indeks[i]
		t.id_rumah = rumah.id
		t.maju_rumah_ubin = rumah.maju_ubin
		t.lateral_ubin = Config.MISI_KUCING_LATERAL_UBIN + float(rng.randi_range(-1, 1)) * Config.MISI_KUCING_GOYANG_LATERAL_UBIN
		t.maju_ubin = rumah.maju_ubin + Config.MISI_KUCING_MAJU_UBIN + float(rng.randi_range(-1, 1)) * Config.MISI_KUCING_GOYANG_MAJU_UBIN
		t.radius_ubin = langkah[i].radius_ubin
		t.lama_berhenti_detik = langkah[i].lama_berhenti_detik
		t.petunjuk_awal_ubin = 0.0 if i == 0 else rencana.titik[i - 1].maju_rumah_ubin
		t.petunjuk_akhir_ubin = rumah.maju_ubin
		rencana.titik.append(t)
	return rencana


## Rumah sisi seberang rute, urut maju (satuan "rumah" misi).
static func rumah_seberang(rute: RouteBuilder.Rute) -> Array[RouteBuilder.RumahRute]:
	var hasil: Array[RouteBuilder.RumahRute] = []
	for rumah: RouteBuilder.RumahRute in rute.rumah:
		if rumah.sisi == LoperAnim.Sisi.SEBERANG:
			hasil.append(rumah)
	return hasil


## Persegi kucing `t` di tanah, koordinat jalan (x = lateral, y = maju), ubin: berpusat di titik kucing.
static func persegi_kucing(t: Titik) -> Rect2:
	var sisi: float = Config.MISI_KUCING_PERSEGI_UBIN
	return Rect2(t.lateral_ubin - sisi / 2, t.maju_ubin - sisi / 2, sisi, sisi)


## True bila rumah `rumah` terlalu dekat dengan mobil garasi seberang di `rute` (titik kucing tidak boleh di situ). Jaraknya `MISI_KUCING_JAUH_MOBIL_UBIN`
## ditambah goyangan maju terbesar, jadi posisi kucing mana pun sesudah digoyang tetap paling sedikit sejauh itu dari mobil.
static func dekat_mobil(rute: RouteBuilder.Rute, rumah: RouteBuilder.RumahRute) -> bool:
	var maju_kucing: float = rumah.maju_ubin + Config.MISI_KUCING_MAJU_UBIN
	for o: RouteBuilder.ObjekRute in rute.objek:
		if o.jenis == "mobil_garasi" and o.jalur == "seberang" and absf(o.maju_ubin - maju_kucing) < Config.MISI_KUCING_JAUH_MOBIL_UBIN + Config.MISI_KUCING_GOYANG_MAJU_UBIN:
			return true
	return false


## Mencari indeks rumah untuk langkah ke-`i` dan seterusnya (rekursi dengan mundur). `sebelum` = indeks rumah titik sebelumnya (0 untuk awal).
static func _pilih(langkah: Array[DataMisi.LangkahCari], i: int, sebelum: int, dihitung: int, seberang: Array[RouteBuilder.RumahRute], rute: RouteBuilder.Rute, rng: RandomNumberGenerator, indeks: Array[int]) -> bool:
	if i >= langkah.size():
		return true
	var l: DataMisi.LangkahCari = langkah[i]
	var lebar: int = l.rumah_maks - l.rumah_min + 1
	var awal: int = rng.randi_range(0, lebar - 1)
	for k: int in range(lebar):
		var selisih: int = l.rumah_min + (awal + k) % lebar
		var n: int = sebelum + selisih
		if n > dihitung or dekat_mobil(rute, seberang[n - 1]):
			continue
		indeks.append(n)
		if _pilih(langkah, i + 1, n, dihitung, seberang, rute, rng, indeks):
			return true
		indeks.pop_back()
	return false
