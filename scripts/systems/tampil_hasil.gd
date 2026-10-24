class_name TampilHasil
extends RefCounted
## Pemilihan keadaan dan tata letak layar hasil sebagai struk antaran, data murni (run ui2-semua-layar bagian A, AC-2; kanvas Hasil.dc.html dan Hasil_*.dc.html, README redesain 3 butir 6 dan 4; usulan):
## margin menurut inset aman, lebar struk dan kolom samping (reputasi, pelanggan, milestone) di 640 sampai 800, persegi tombol aksi kanan bawah, batas bawah kolom samping, chip perubahan reputasi, glif
## "Terkirim", dan nama tekstur lencana. `LayarHasil` hanya mewujudkan hasilnya jadi node. Tanpa node, `Time`, atau RNG. Semua angka dari `Config`. Setiap keadaan terbaca TANPA warna:
## glif naik/turun/centang berpasangan dengan teks, "Terkirim" semua terantar bercentang hijau dan sebagian bercentang abu-abu dengan angka n/total.

## Tata letak layar hasil untuk satu viewport dan inset aman.
class Tata extends RefCounted:
	## Margin tiap tepi = max(`HASIL_MARGIN_PX`, inset aman tepi itu).
	var margin_awal: int = 0
	var margin_akhir: int = 0
	var margin_atas: int = 0
	var margin_bawah: int = 0
	## True bila kolom samping (reputasi, pelanggan, milestone) ada.
	var ada_samping: bool = false
	## Lebar struk dan kolom samping (0 bila tidak ada), piksel game.
	var lebar_struk: int = 0
	var lebar_kolom: int = 0
	## Persegi tombol aksi utama (kanan bawah, di dalam margin).
	var tombol: Rect2i = Rect2i()
	## Batas bawah kolom samping (koordinat y viewport): kolom harus berakhir di atas ini supaya tidak menutupi tombol.
	var batas_bawah_kolom: int = 0
	## Letak x kiri struk (koordinat viewport): dengan samping = margin awal; tanpa samping = tengah, atau digeser ke kiri bila struk setinggi itu sampai ke baris tombol aksi dan akan menutupinya.
	var x_struk: int = 0
	## Jarak kartu pertama kolom samping di bawah margin atas: `HASIL_KOLOM_ATAS_PX` (sejajar struk) bila kolom muat di atas tombol, selain itu 0 (sejajar judul).
	var kolom_atas: int = 0


## Perubahan reputasi pada chip: naik = gaya OK dengan glif naik; turun = netral dengan glif turun; nol = netral tanpa glif (bukan kenaikan, bukan penurunan). `teks` dengan tanda eksplisit.
class InfoDelta extends RefCounted:
	var gaya: KomponenUi.GayaChip = KomponenUi.GayaChip.NETRAL
	## Nama dasar tekstur glif (`GayaHud.tekstur`), "" = tanpa glif.
	var glif: String = ""
	var teks: String = ""


## Lebar kolom samping untuk lebar viewport `lebar`: `HASIL_KOLOM_LEBAR_LEBAR_PX` (300) di lebar >= `HASIL_LEBAR_LEBAR_MIN_PX` (800), selain itu `HASIL_KOLOM_LEBAR_PX` (236).
static func lebar_kolom(lebar: int) -> int:
	return Config.HASIL_KOLOM_LEBAR_LEBAR_PX if lebar >= Config.HASIL_LEBAR_LEBAR_MIN_PX else Config.HASIL_KOLOM_LEBAR_PX


## True bila kolom samping tampil: ada hasil reputasi atau ringkasan milestone (rute yang dijalankan sendiri tidak punya keduanya, struk ke tengah).
static func ada_samping(punya_reputasi: bool, punya_milestone: bool) -> bool:
	return punya_reputasi or punya_milestone


## Tata letak untuk `viewport` (piksel game), `inset` aman (null = nol), dan `samping` (ada kolom samping). Dengan samping: struk mengisi lebar sisa (isi - kolom - jarak); tanpa samping: struk 360 dibatasi lebar isi dan
## berada di tengah. `tinggi_struk` dan `tinggi_kolom` (tinggi isi kolom TANPA jarak atas; 0 = belum diketahui) menentukan dua keputusan yang bergantung tinggi: struk tanpa samping yang cukup tinggi sampai baris tombol digeser ke kiri
## supaya tidak menutupi tombol, dan kolom samping dimulai sejajar struk (`HASIL_KOLOM_ATAS_PX`) hanya bila muat di atas tombol (selain itu sejajar judul).
static func tata(viewport: Vector2i, inset: ZonaAman.Inset, samping: bool, tinggi_struk: int = 0, tinggi_kolom: int = 0) -> Tata:
	var ins: ZonaAman.Inset = inset if inset != null else ZonaAman.Inset.new()
	var hasil: Tata = Tata.new()
	hasil.margin_awal = ZonaAman.margin(Config.HASIL_MARGIN_PX, ins.awal_x)
	hasil.margin_akhir = ZonaAman.margin(Config.HASIL_MARGIN_PX, ins.akhir_x)
	hasil.margin_atas = ZonaAman.margin(Config.HASIL_MARGIN_PX, ins.atas)
	hasil.margin_bawah = ZonaAman.margin(Config.HASIL_MARGIN_PX, ins.bawah)
	hasil.ada_samping = samping
	var isi: int = maxi(viewport.x - hasil.margin_awal - hasil.margin_akhir, 0)
	if samping:
		hasil.lebar_kolom = lebar_kolom(viewport.x)
		hasil.lebar_struk = maxi(isi - hasil.lebar_kolom - Config.HASIL_STRUK_KOLOM_JARAK_PX, 0)
	else:
		hasil.lebar_struk = mini(Config.HASIL_STRUK_TANPA_SAMPING_PX, isi)
	var lebar_tombol: int = Config.UI_TOMBOL_LEBAR_UTAMA_PX
	hasil.tombol = Rect2i(viewport.x - hasil.margin_akhir - lebar_tombol, viewport.y - hasil.margin_bawah - Config.UI_TOMBOL_TINGGI_PX, lebar_tombol, Config.UI_TOMBOL_TINGGI_PX)
	hasil.batas_bawah_kolom = hasil.tombol.position.y - Config.HASIL_KOLOM_TOMBOL_JARAK_PX
	hasil.x_struk = hasil.margin_awal
	if not samping:
		hasil.x_struk = hasil.margin_awal + (isi - hasil.lebar_struk) / 2
		var bawah_struk: int = hasil.margin_atas + Config.HASIL_BARIS_ATAS_PX + tinggi_struk
		if bawah_struk > hasil.batas_bawah_kolom:
			hasil.x_struk = maxi(hasil.margin_awal, mini(hasil.x_struk, hasil.tombol.position.x - Config.HASIL_KOLOM_TOMBOL_JARAK_PX - hasil.lebar_struk))
	var tersedia: int = hasil.batas_bawah_kolom - hasil.margin_atas
	hasil.kolom_atas = Config.HASIL_KOLOM_ATAS_PX if tinggi_kolom + Config.HASIL_KOLOM_ATAS_PX <= tersedia else 0
	return hasil


## Chip perubahan reputasi untuk `perubahan` (selisih reputasi hari ini).
static func delta_reputasi(perubahan: int) -> InfoDelta:
	var hasil: InfoDelta = InfoDelta.new()
	hasil.teks = "%+d" % perubahan
	if perubahan > 0:
		hasil.gaya = KomponenUi.GayaChip.OK
		hasil.glif = "glif_naik_ok"
	elif perubahan < 0:
		hasil.gaya = KomponenUi.GayaChip.NETRAL
		hasil.glif = "glif_turun_teks2"
	return hasil


## Glif di samping angka "Terkirim": centang hijau bila SEMUA pelanggan terantar (dan ada pelanggan), selain itu centang abu-abu; angka n/total tetap menyatakan jumlahnya, jadi bukan warna saja.
static func glif_terkirim(terkirim: int, pelanggan: int) -> String:
	return "glif_centang_ok" if pelanggan > 0 and terkirim >= pelanggan else "glif_centang_teks2"


## Nama dasar tekstur lencana 32 untuk target menuju tingkat berindeks `tingkat` (0 = perunggu, 1 = perak, 2 = emas); dijepit ke 0..2.
static func tekstur_lencana32(tingkat: int) -> String:
	return "lencana32_" + Config.MILESTONE_TINGKAT[clampi(tingkat, 0, Config.MILESTONE_TINGKAT.size() - 1)]


## Nama dasar tekstur lencana 24 untuk tingkat baru tercapai `tingkat` (1 = perunggu, 2 = perak, 3 = emas); dijepit ke 1..3.
static func tekstur_lencana24(tingkat: int) -> String:
	return "icon24_lencana_" + Config.MILESTONE_TINGKAT[clampi(tingkat - 1, 0, Config.MILESTONE_TINGKAT.size() - 1)]


## Jumlah baris kondisi (komponen PERLU_BENGKEL) yang tampil: paling banyak `Config.KONDISI_KOMPONEN.size()` (tiga).
static func jumlah_baris_kondisi(perlu_bengkel: int) -> int:
	return clampi(perlu_bengkel, 0, Config.KONDISI_KOMPONEN.size())


## Kunci terjemahan nama milestone `id` dan nama tingkat 1..3 (satu sumber untuk layar dan tes).
static func kunci_nama_milestone(id: String) -> String:
	return "HASIL_MILESTONE_NAMA_" + id.to_upper()


static func kunci_tingkat(tingkat_ke: int) -> String:
	return "HASIL_MILESTONE_TINGKAT_" + MilestoneTracker.nama_tingkat(tingkat_ke).to_upper()


## Warna lapisan latar layar hasil (V-10): `UI_BG` dengan alpha `HASIL_LATAR_ALPHA` di atas dunia rute yang baru dilalui, atau alpha `HASIL_ALPHA_TANPA_DUNIA` (gelap polos) bila dunia tidak ada. Token `UI_BG` sendiri tidak berubah.
static func warna_latar(ada_dunia: bool) -> Color:
	return Color(Palette.UI_BG, Config.HASIL_LATAR_ALPHA if ada_dunia else Config.HASIL_ALPHA_TANPA_DUNIA)


## Alpha tekstur struk dan kartu kolom samping (V-10): `HASIL_PANEL_ALPHA` di atas dunia, `HASIL_ALPHA_TANPA_DUNIA` bila dunia tidak ada.
static func alpha_panel(ada_dunia: bool) -> float:
	return Config.HASIL_PANEL_ALPHA if ada_dunia else Config.HASIL_ALPHA_TANPA_DUNIA


## Faktor gelap RGB struk dan kartu (V-10): `HASIL_PANEL_GELAP` di atas dunia (menjaga kontras teks hijau walau panel transparan), `HASIL_PANEL_GELAP_TANPA_DUNIA` (1,0 = tanpa penggelapan) bila dunia tidak ada.
static func gelap_panel(ada_dunia: bool) -> float:
	return Config.HASIL_PANEL_GELAP if ada_dunia else Config.HASIL_PANEL_GELAP_TANPA_DUNIA


## Warna pengali (`modulate_color` StyleBoxTexture) struk dan kartu: abu-abu `gelap_panel` dengan alpha `alpha_panel`. Tanpa dunia = putih buram = tekstur apa adanya.
static func modulasi_panel(ada_dunia: bool) -> Color:
	var g: float = gelap_panel(ada_dunia)
	return Color(g, g, g, alpha_panel(ada_dunia))


## Perataan baseline dua teks yang berdiri sejajar dalam satu baris (revisi UI pemilik R-2, usulan): kedua teks berada di atas baris (rata atas) dengan tinggi font berbeda, jadi baseline-nya terpisah selisih ascent. Yang
## ascent-nya lebih kecil diturunkan sebesar selisih (dibulatkan, tidak pernah negatif) lewat margin atas. Hasil `Vector2i(turun_a, turun_b)`: salah satunya selalu 0.
static func turun_baseline(ascent_a: float, ascent_b: float) -> Vector2i:
	var selisih: int = roundi(absf(ascent_a - ascent_b))
	return Vector2i(selisih, 0) if ascent_a < ascent_b else Vector2i(0, selisih)


## Pusat vertikal tinta teks (jarak dari tepi atas baris, piksel game) untuk teks yang rata atas dengan `ascent` dan tinggi tinta kapital atau angka `tinggi_tinta`: garis dasar (`ascent`) dikurangi setengah tinggi tinta (R-5).
static func pusat_tinta(ascent: float, tinggi_tinta: float) -> float:
	return ascent - tinggi_tinta / 2


## Margin atas (piksel game, bulat, tidak pernah negatif) untuk tiap benda yang rata atas dalam satu baris supaya pusat vertikalnya sama (revisi UI pemilik R-5): `pusat` = pusat tiap benda dari tepi atasnya;
## semuanya diturunkan sampai pusat yang paling rendah (dibulatkan; pusat dari tinta bisa setengah piksel, jadi selisih sisa paling besar 0,5 px). Hasil sejajar dengan `pusat`; kosong untuk masukan kosong atau tidak hingga.
static func turun_pusat(pusat: Array[float]) -> Array[int]:
	var hasil: Array[int] = []
	var tertinggi: float = -INF
	for p: float in pusat:
		if not is_finite(p):
			return hasil
		tertinggi = maxf(tertinggi, p)
	for p: float in pusat:
		hasil.append(roundi(tertinggi - p))
	return hasil


## Baseline (jarak dari tepi atas chip ke garis dasar teks chip) untuk chip setinggi `tinggi_chip` dengan isi berjarak `pad_y` atas dan bawah, teks berbaris setinggi `tinggi_baris` dan `ascent`, teks di tengah tinggi isi
## (`ChipUi`: label berrata tengah di dalam kotak isi). Dipakai menurunkan chip reputasi sampai garis dasar teksnya sama dengan garis dasar angka reputasi.
static func baseline_chip(tinggi_chip: int, pad_y: int, tinggi_baris: float, ascent: float) -> float:
	var isi: float = float(maxi(tinggi_chip - pad_y * 2, 0))
	return float(pad_y) + (isi - tinggi_baris) / 2 + ascent
