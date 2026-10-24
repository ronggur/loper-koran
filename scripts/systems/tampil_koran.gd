class_name TampilKoran
extends RefCounted
## Pemilihan keadaan dan tata letak halaman depan koran sebagai data murni (run ui2-semua-layar bagian B, AC-3; kanvas Koran.dc.html dan Koran_*.dc.html, README redesain 3 butir 7 dan 4; usulan):
## tombol tinta koran tiga peran (Berangkat = TINTA, Ambil/Lewati tidak terpilih = TIPIS, terpilih = TERPILIH berongga) dengan tekstur, warna teks, dan geseran isi menurut keadaan tekan; glif centang pada
## tombol terpilih; foto dan ikon berita utama menurut efek dunia; margin menurut inset aman, lebar kolom misi dan berita di 640 sampai 800, letak garis tegak dan tombol Berangkat; persegi kotak hiasan
## "Iklan baris" di sisa ruang bawah kolom berita; batang hiasan pengganti teks; goresan garis ganda. `HalamanKoran` hanya mewujudkan hasilnya jadi node. Tanpa node, `Time`, atau RNG.
## Semua angka dari `Config`. Pilihan terbaca TANPA warna: terpilih = bingkai tinta tebal berongga + glif centang + teks status; tidak terpilih = garis tipis rata.

## Peran tombol koran: TINTA = aksi utama terisi tinta (Berangkat), TIPIS = pilihan belum dipilih (garis 1 px), TERPILIH = pilihan terpilih (berongga, bingkai tinta tebal).
enum PeranTombol { TINTA, TIPIS, TERPILIH }


## Tata letak halaman koran untuk satu viewport dan inset aman.
class Tata extends RefCounted:
	## Margin tiap tepi = max(`KORAN_MARGIN_PX`, inset aman tepi itu).
	var margin_awal: int = 0
	var margin_akhir: int = 0
	var margin_atas: int = 0
	var margin_bawah: int = 0
	## Lebar isi (viewport dikurangi margin kiri dan kanan), lebar kolom misi, dan lebar kolom berita (isi - misi - 13).
	var lebar_isi: int = 0
	var lebar_misi: int = 0
	var lebar_berita: int = 0
	## Letak x kiri kolom misi dan x garis tegak (koordinat viewport).
	var x_misi: int = 0
	var x_garis: int = 0
	## Persegi tombol Berangkat: kanan bawah di dalam margin (140x42).
	var berangkat: Rect2i = Rect2i()


## Lebar kolom misi untuk lebar viewport `lebar`: `KORAN_MISI_LEBAR_LEBAR_PX` (280) di lebar >= `KORAN_LEBAR_LEBAR_MIN_PX` (800), selain itu `KORAN_MISI_LEBAR_PX` (236).
static func lebar_misi(lebar: int) -> int:
	return Config.KORAN_MISI_LEBAR_LEBAR_PX if lebar >= Config.KORAN_LEBAR_LEBAR_MIN_PX else Config.KORAN_MISI_LEBAR_PX


## Tata letak untuk `viewport` (piksel game) dan `inset` aman (null = nol): kolom berita | 6 + garis 1 + 6 | misi.
static func tata(viewport: Vector2i, inset: ZonaAman.Inset) -> Tata:
	var ins: ZonaAman.Inset = inset if inset != null else ZonaAman.Inset.new()
	var hasil: Tata = Tata.new()
	hasil.margin_awal = ZonaAman.margin(Config.KORAN_MARGIN_PX, ins.awal_x)
	hasil.margin_akhir = ZonaAman.margin(Config.KORAN_MARGIN_PX, ins.akhir_x)
	hasil.margin_atas = ZonaAman.margin(Config.KORAN_MARGIN_PX, ins.atas)
	hasil.margin_bawah = ZonaAman.margin(Config.KORAN_MARGIN_PX, ins.bawah)
	hasil.lebar_isi = maxi(viewport.x - hasil.margin_awal - hasil.margin_akhir, 0)
	hasil.lebar_misi = lebar_misi(viewport.x)
	var pemisah: int = Config.KORAN_KOLOM_JARAK_PX + Config.KORAN_GARIS_TEGAK_PX + Config.KORAN_KOLOM_JARAK_PX
	hasil.lebar_berita = maxi(hasil.lebar_isi - hasil.lebar_misi - pemisah, 0)
	hasil.x_garis = hasil.margin_awal + hasil.lebar_berita + Config.KORAN_KOLOM_JARAK_PX
	hasil.x_misi = hasil.x_garis + Config.KORAN_GARIS_TEGAK_PX + Config.KORAN_KOLOM_JARAK_PX
	hasil.berangkat = Rect2i(viewport.x - hasil.margin_akhir - Config.UI_TOMBOL_LEBAR_UTAMA_PX, viewport.y - hasil.margin_bawah - Config.UI_TOMBOL_TINGGI_PX, Config.UI_TOMBOL_LEBAR_UTAMA_PX, Config.UI_TOMBOL_TINGGI_PX)
	return hasil


## Peran tombol pilihan (Ambil atau Lewati): terpilih = TERPILIH, selain itu TIPIS.
static func peran_pilih(terpilih: bool) -> PeranTombol:
	return PeranTombol.TERPILIH if terpilih else PeranTombol.TIPIS


## Nama dasar tekstur bingkai tombol (tanpa `ui_` dan `.png`). Kanvas tidak punya bingkai tekan untuk pilihan: ditekan = bingkai terpilih (menekan memang memilih).
static func nama_tekstur_tombol(peran: PeranTombol, ditekan: bool) -> String:
	match peran:
		PeranTombol.TINTA:
			return "koran_btn_tinta_tekan" if ditekan else "koran_btn_tinta"
		PeranTombol.TERPILIH:
			return "koran_btn_terpilih"
	return "koran_btn_terpilih" if ditekan else "koran_btn_tipis"


## Warna teks tombol dari `Palette`: TINTA = kertas di atas tinta (kanvas `.k-tinta`), TIPIS = TINTA_2 (tekan: TINTA, karena berganti bingkai terpilih), TERPILIH = TINTA.
static func warna_teks_tombol(peran: PeranTombol, ditekan: bool) -> Color:
	match peran:
		PeranTombol.TINTA:
			return Palette.KORAN_KERTAS
		PeranTombol.TERPILIH:
			return Palette.KORAN_TINTA
	return Palette.KORAN_TINTA if ditekan else Palette.KORAN_TINTA_2


## Tambahan margin isi di luar tepi 9-slice: `Vector2i(atas, bawah)`. Hanya TINTA punya bibir 2 px (normal teks naik, ditekan teks turun 2 px seperti wajahnya); pilihan rata tanpa bibir.
static func margin_isi_tombol(peran: PeranTombol, ditekan: bool) -> Vector2i:
	if peran != PeranTombol.TINTA:
		return Vector2i.ZERO
	if ditekan:
		return Vector2i(Config.UI_TOMBOL_TEKAN_GESER_PX, 0)
	return Vector2i(0, Config.UI_TOMBOL_TEKAN_GESER_PX)


## Nama dasar tekstur glif di tombol: pilihan terpilih bercentang gelap (bentuk dan glif, bukan warna saja); selain itu "" (tanpa glif).
static func glif_pilih(terpilih: bool) -> String:
	return "glif_centang_gelap" if terpilih else ""


## Nama dasar tekstur glif tombol Berangkat (panah terang di atas tinta).
static func glif_berangkat() -> String:
	return "glif_panah_terang"


## Nama dasar tekstur foto berita utama untuk `efek`; "" bila efek itu belum punya foto (hanya jalan diperbaiki dan mati lampu).
static func foto_untuk_efek(efek: String) -> String:
	var i: int = Config.KORAN_EFEK_FOTO.find(efek)
	return Config.KORAN_NAMA_FOTO[i] if i >= 0 else ""


## Nama dasar tekstur ikon 24 di judul berita utama untuk `efek`; "" bila efek itu belum punya ikon.
static func ikon_untuk_efek(efek: String) -> String:
	var i: int = Config.KORAN_EFEK_FOTO.find(efek)
	return Config.KORAN_NAMA_IKON[i] if i >= 0 else ""


## Persegi kotak hiasan "Iklan baris" di dalam area `area` (piksel game, sisa kolom berita): menempel di kiri bawah, lebar paling besar `KORAN_IKLAN_LEBAR_MAKS_PX`, tinggi `KORAN_IKLAN_TINGGI_PX` bila muat,
## selain itu seluruh tinggi area; kosong (`Rect2i()`) bila area lebih rendah dari `KORAN_IKLAN_TINGGI_MIN_PX` (kotak tidak tampil, tidak pernah menumpuk berita).
static func iklan(area: Vector2i) -> Rect2i:
	if area.y < Config.KORAN_IKLAN_TINGGI_MIN_PX or area.x <= 0:
		return Rect2i()
	var tinggi: int = mini(area.y, Config.KORAN_IKLAN_TINGGI_PX)
	var lebar: int = mini(area.x, Config.KORAN_IKLAN_LEBAR_MAKS_PX)
	return Rect2i(0, area.y - tinggi, lebar, tinggi)


## Pembagian ruang sisa kolom berita (ruang di bawah berita ringan sampai dasar kolom) antara batang hiasan di atas dan kotak "Iklan baris" di bawah.
class Ruang extends RefCounted:
	## Jumlah baris batang hiasan (0 sampai `KORAN_HIASAN_POLA.size() / 2`) dan persegi hiasan relatif sudut kiri atas ruang (kosong bila 0 baris).
	var hiasan_baris: int = 0
	var hiasan: Rect2i = Rect2i()
	## Persegi kotak iklan relatif sudut kiri atas ruang; kosong bila sisa ruang di bawah hiasan terlalu rendah.
	var iklan: Rect2i = Rect2i()


## Membagi `ruang` (piksel game): batang hiasan didahulukan (paling banyak semua barisnya, sebanyak yang muat), kotak iklan mengisi sisanya di dasar bila muat (`iklan`); ruang sempit mengorbankan iklan lebih dulu, lalu baris hiasan.
## Kedua elemen hanya hiasan: ruang boleh nol tanpa membuat kolom meluap.
static func ruang(ruang_tersedia: Vector2i) -> Ruang:
	var hasil: Ruang = Ruang.new()
	hasil.hiasan_baris = mini(Config.KORAN_HIASAN_POLA.size() / 2, baris_hiasan_muat(ruang_tersedia.y))
	var terpakai: int = 0
	if hasil.hiasan_baris > 0:
		var tinggi: int = tinggi_hiasan(hasil.hiasan_baris)
		hasil.hiasan = Rect2i(0, 0, ruang_tersedia.x, tinggi)
		terpakai = tinggi + Config.KORAN_BERITA_JARAK_PX
	var sisa: Rect2i = iklan(Vector2i(ruang_tersedia.x, ruang_tersedia.y - terpakai))
	if sisa.size.y > 0:
		hasil.iklan = Rect2i(sisa.position.x, sisa.position.y + terpakai, sisa.size.x, sisa.size.y)
	return hasil


## Tinggi `n` baris batang hiasan berikut jarak antar baris; 0 untuk `n` <= 0.
static func tinggi_hiasan(n: int) -> int:
	if n <= 0:
		return 0
	return n * Config.KORAN_HIASAN_TINGGI_PX + (n - 1) * Config.KORAN_HIASAN_JARAK_BARIS_PX


## Batang hiasan pengganti teks di dalam lebar `lebar` dan paling banyak `baris_maks` baris (dua kolom, `KORAN_HIASAN_POLA` kiri ke kanan lalu ke bawah, tiap batang pecahan dari lebar kolomnya).
## Persegi relatif sudut kiri atas; kosong bila lebar tidak cukup untuk dua kolom.
static func batang_hiasan(lebar: int, baris_maks: int) -> Array[Rect2i]:
	var hasil: Array[Rect2i] = []
	var kolom: int = (lebar - Config.KORAN_HIASAN_JARAK_KOLOM_PX) / 2
	if kolom <= 0 or baris_maks <= 0:
		return hasil
	var jumlah: int = mini(Config.KORAN_HIASAN_POLA.size(), baris_maks * 2)
	for i: int in range(jumlah):
		var baris: int = i / 2
		var x: int = (i % 2) * (kolom + Config.KORAN_HIASAN_JARAK_KOLOM_PX)
		var y: int = baris * (Config.KORAN_HIASAN_TINGGI_PX + Config.KORAN_HIASAN_JARAK_BARIS_PX)
		hasil.append(Rect2i(x, y, roundi(float(kolom) * Config.KORAN_HIASAN_POLA[i]), Config.KORAN_HIASAN_TINGGI_PX))
	return hasil


## Jumlah baris batang hiasan yang muat dalam tinggi `tinggi` (tiap baris setinggi batang, dipisah jarak baris); 0 bila tidak ada yang muat.
static func baris_hiasan_muat(tinggi: int) -> int:
	if tinggi < Config.KORAN_HIASAN_TINGGI_PX:
		return 0
	return 1 + (tinggi - Config.KORAN_HIASAN_TINGGI_PX) / (Config.KORAN_HIASAN_TINGGI_PX + Config.KORAN_HIASAN_JARAK_BARIS_PX)


## Dua goresan garis ganda (kanvas `.k-ganda`) sebagai persegi relatif sudut kiri atas untuk lebar `lebar`: garis atas `KORAN_GANDA_ATAS_PX`, celah, garis bawah `KORAN_GANDA_BAWAH_PX`.
static func garis_ganda(lebar: int) -> Array[Rect2i]:
	return [
		Rect2i(0, 0, lebar, Config.KORAN_GANDA_ATAS_PX),
		Rect2i(0, Config.KORAN_GANDA_ATAS_PX + Config.KORAN_GANDA_CELAH_PX, lebar, Config.KORAN_GANDA_BAWAH_PX),
	]


## Tinggi total garis ganda.
static func tinggi_garis_ganda() -> int:
	return Config.KORAN_GANDA_ATAS_PX + Config.KORAN_GANDA_CELAH_PX + Config.KORAN_GANDA_BAWAH_PX
