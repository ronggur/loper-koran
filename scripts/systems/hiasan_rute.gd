class_name HiasanRute
extends RefCounted
## Hiasan lanjutan di depan garis akhir (run garis-finish-portal, Bagian F, F-1, usulan): perumahan yang tetap tampak di depan portal sesudah kamera berhenti di garis akhir.
##
## Murni dan deterministik. Dari rute `rute` dan pustaka segmen disusun SATU rute hiasan terpisah (`RouteBuilder.Rute` lain): beberapa segmen berurutan yang dimulai tepat di
## `rute.panjang_ubin` dan menutupi sedikitnya `RUTE_HIASAN_PANJANG_UBIN` ubin (sama dengan jendela daur ke depan, jadi seluruh jendela terisi). Hanya rumah dan dekor yang
## disalin: semua rumah dijadikan BUKAN pelanggan (sprite `_bukan`, kotak surat abu-abu, tanpa zona, tanpa radar, tanpa progres, tanpa skor), tanpa rintangan, titik misi, atau simpang
## (tanah tidak berubah). `Rute` utama, data segmen, dan keluaran `RouteBuilder.bangun` tidak disentuh (golden G-5 tetap); acak memakai aliran sendiri (`benih` rute +
## `RUTE_HIASAN_SEED_SELISIH`), jadi seed rute sama = hiasan sama dan rute tidak ikut berubah. Segmen diambil dari yang pembuka atau tengah (penutup mengakhiri jalan), tidak sama dengan
## segmen terakhir rute atau segmen hiasan sebelumnya, dan tidak dua `padat` berurutan (irama sama dengan rute, ROUTE_DESIGN 5). Posisi rumah dan dekor tiap segmen sudah sah terhadap lajur
## sepeda (lajur dekor `RUTE_DEKOR_LAJUR_UBIN`), jadi jalur sepeda lateral tetap bebas. Digambar oleh satu `RumahDaurRute` dan satu daur dekor tambahan di scene rute (jendela daur yang sama dengan rute) dan didaftarkan ke penerap penutup yang sama.


## Rute hiasan untuk `rute` dari `pustaka` segmen. Rute kosong (tanpa rumah dan dekor, panjang = panjang rute) bila rute null atau tanpa panjang, atau pustaka kosong.
static func bangun(rute: RouteBuilder.Rute, pustaka: Array[SegmenRute]) -> RouteBuilder.Rute:
	var hiasan: RouteBuilder.Rute = RouteBuilder.Rute.new()
	if rute == null or not is_finite(rute.panjang_ubin) or rute.panjang_ubin <= 0.0 or pustaka.is_empty():
		hiasan.panjang_ubin = rute.panjang_ubin if rute != null else 0.0
		return hiasan
	hiasan.benih = rute.benih
	hiasan.hari = rute.hari
	var urutan: Array[SegmenRute] = pilih_segmen(rute, pustaka)
	var awal: float = rute.panjang_ubin
	for nomor: int in range(urutan.size()):
		var segmen: SegmenRute = urutan[nomor]
		hiasan.segmen.append(segmen)
		hiasan.awal_segmen.append(awal)
		for r: SegmenRute.Rumah in segmen.rumah:
			var rumah: RouteBuilder.RumahRute = RouteBuilder.RumahRute.new()
			rumah.id = "hiasan%d_%s@%d" % [nomor, segmen.id, r.pos]
			rumah.id_segmen = segmen.id
			rumah.pos = r.pos
			rumah.maju_ubin = awal + float(r.pos)
			rumah.sisi = r.sisi
			rumah.jenis = r.jenis
			hiasan.rumah.append(rumah)
		for d: SegmenRute.Dekor in segmen.dekor:
			var butir: RouteBuilder.DekorItem = RouteBuilder.DekorItem.new()
			butir.id_segmen = segmen.id
			butir.pos = d.pos
			butir.sisi = d.sisi
			butir.id = "hiasan%d_%s:%s@%d" % [nomor, segmen.id, SegmenRute.NAMA_SISI[0] if d.sisi == LoperAnim.Sisi.SEBERANG else SegmenRute.NAMA_SISI[1], d.pos]
			butir.maju_ubin = awal + float(d.pos)
			butir.lateral_ubin = DekorRute.lateral(d.jenis, d.sisi)
			butir.jenis = d.jenis
			butir.varian = d.varian
			hiasan.dekor.append(butir)
		awal += float(segmen.panjang)
	hiasan.panjang_ubin = awal
	hiasan.rumah.sort_custom(func(a: RouteBuilder.RumahRute, b: RouteBuilder.RumahRute) -> bool: return a.maju_ubin < b.maju_ubin if a.maju_ubin != b.maju_ubin else a.id < b.id)
	hiasan.dekor.sort_custom(func(a: RouteBuilder.DekorItem, b: RouteBuilder.DekorItem) -> bool: return a.maju_ubin < b.maju_ubin if a.maju_ubin != b.maju_ubin else a.id < b.id)
	return hiasan


## Segmen hiasan berurutan: dipilih dari pembuka dan tengah (semua segmen bila pustaka tidak punya satu pun), tidak sama dengan segmen sebelumnya, tidak dua `padat` berurutan
## (dilonggarkan bila tidak ada kandidat), sampai panjang total >= `Config.RUTE_HIASAN_PANJANG_UBIN`. Segmen tanpa panjang positif dilewati.
static func pilih_segmen(rute: RouteBuilder.Rute, pustaka: Array[SegmenRute]) -> Array[SegmenRute]:
	var hasil: Array[SegmenRute] = []
	var terurut: Array[SegmenRute] = []
	for segmen: SegmenRute in pustaka:
		if segmen.panjang > 0:
			terurut.append(segmen)
	terurut.sort_custom(func(a: SegmenRute, b: SegmenRute) -> bool: return a.id < b.id)
	var kandidat: Array[SegmenRute] = []
	for segmen: SegmenRute in terurut:
		if segmen.posisi != SegmenRute.Posisi.PENUTUP:
			kandidat.append(segmen)
	if kandidat.is_empty():
		kandidat = terurut
	if kandidat.is_empty():
		return hasil
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = rute.benih + Config.RUTE_HIASAN_SEED_SELISIH
	var sebelumnya: SegmenRute = rute.segmen[rute.segmen.size() - 1] if not rute.segmen.is_empty() else null
	var panjang: int = 0
	while float(panjang) < float(Config.RUTE_HIASAN_PANJANG_UBIN) and hasil.size() < Config.RUTE_HIASAN_SEGMEN_MAKS:
		var pilihan: SegmenRute = null
		for usaha: int in range(Config.RUTE_HIASAN_COBA_MAKS):
			var calon: SegmenRute = kandidat[rng.randi_range(0, kandidat.size() - 1)]
			var longgar: bool = usaha >= Config.RUTE_HIASAN_COBA_MAKS / 2
			if sebelumnya != null and calon.id == sebelumnya.id and kandidat.size() > 1:
				continue
			if not longgar and sebelumnya != null and calon.tingkat == SegmenRute.Tingkat.PADAT and sebelumnya.tingkat == SegmenRute.Tingkat.PADAT:
				continue
			pilihan = calon
			break
		if pilihan == null:
			pilihan = kandidat[0]
		hasil.append(pilihan)
		panjang += pilihan.panjang
		sebelumnya = pilihan
	return hasil
