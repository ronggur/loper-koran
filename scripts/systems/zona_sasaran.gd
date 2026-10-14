class_name ZonaSasaran
extends RefCounted
## Zona sasaran koran, status antaran, dan bentuk penanda, logika murni (BALANCING 5, DESIGN_SPEC 3.6; D-6, D-7, D-10 run
## fase2a-lemparan, D-4 run fase2-arah-bebas). Semua usulan placeholder untuk jalan uji; skor, combo, dan koin belum ada (Fase 3).
##
## Zona = persegi di bidang tanah dalam koordinat JALAN: x = lateral (ubin dari garis tengah, negatif = `seberang`), y = maju (ubin
## sepanjang jalan; dunia y = -maju, `Iso`). Tepi min inklusif, tepi maks eksklusif, di kedua sumbu: dua zona yang bersebelahan tidak
## pernah sama-sama memuat satu titik. Penilaian dari TITIK MENDARAT saja (D-4 run fase2-arah-bebas): zona yang memuat titik itu menilai
## koran apa pun arah atau sisi lemparannya, jadi fungsi di sini tidak menerima sisi lempar (penyaring sisi Run 2A dihapus). `Zona.sisi`
## hanya untuk gambar. Zona seberang dan zona dekat jalan uji tidak bertumpuk (dites). Bila beberapa zona memuat titik mendarat,
## prioritas jenis: kotak surat > jendela > teras > halaman (`PRIORITAS`); jenis sama = yang pertama di daftar. Sesudah itu: zona rumah
## bukan pelanggan = `BUKAN_PELANGGAN`. Tidak ada zona = `MELESET`.
##
## Status antaran (BALANCING 5): kotak surat dan teras sah penuh, halaman sah setengah, bukan pelanggan dan meleset tidak sah, jendela
## menurut sakelar (`Config.JENDELA_KENA_BONUS`, KEPUTUSAN TERBUKA ROADMAP 5; bawaan penalti ringan = tidak sah tanpa hukuman lain),
## diberikan sebagai parameter supaya kedua nilai bisa dites. Tiap pendaratan dinilai sendiri (status per rumah di luar scope).

## Jenis zona di data.
enum Jenis { KOTAK_SURAT, TERAS, HALAMAN, JENDELA }
## Hasil klasifikasi satu titik mendarat.
enum Hasil { MELESET, KOTAK_SURAT, TERAS, HALAMAN, JENDELA, BUKAN_PELANGGAN }
## Status antaran dari hasil (BALANCING 5).
enum Antaran { TIDAK_SAH, SAH_PENUH, SAH_SETENGAH, SAH_BONUS }
## Bentuk penanda di titik mendarat (D-10, DESIGN_SPEC 3.6), tidak hanya warna: centang (sah penuh, `OK`), bintang (bonus jendela,
## bentuk berbeda dari sah biasa), setengah (halaman), silang kecil (tidak sah, `FAIL`; bukan panel merah besar).
enum Penanda { SILANG, CENTANG, SETENGAH, BINTANG }

## Urutan prioritas jenis bila zona tumpang tindih, dari yang paling diutamakan.
const PRIORITAS: Array[Jenis] = [Jenis.KOTAK_SURAT, Jenis.JENDELA, Jenis.TERAS, Jenis.HALAMAN]


## Satu zona sasaran.
class Zona extends RefCounted:
	## Persegi di bidang tanah, koordinat jalan (x = lateral, y = maju), ubin. Tepi min inklusif, maks eksklusif.
	var persegi: Rect2 = Rect2()
	## Sisi jalan zona ini (`SEBERANG` atau `DEKAT`), untuk gambar dan data; tidak dipakai penilaian (D-4 run fase2-arah-bebas).
	var sisi: LoperAnim.Sisi = LoperAnim.Sisi.TIDAK_ADA
	## Jenis zona.
	var jenis: Jenis = Jenis.HALAMAN
	## True bila rumah ini pelanggan.
	var pelanggan: bool = true
	## Nomor kavling di jalan uji (untuk penanda per rumah; bukan bagian aturan).
	var rumah: int = 0


## Zona baru (persegi dalam koordinat jalan, ubin).
static func buat(persegi: Rect2, sisi: LoperAnim.Sisi, jenis: Jenis, pelanggan: bool, rumah: int = 0) -> Zona:
	var zona: Zona = Zona.new()
	zona.persegi = persegi
	zona.sisi = sisi
	zona.jenis = jenis
	zona.pelanggan = pelanggan
	zona.rumah = rumah
	return zona


## Koordinat jalan (x = lateral, y = maju) dari posisi dunia (`Iso`: y dunia = -maju).
static func ke_jalan(dunia: Vector2) -> Vector2:
	return Vector2(dunia.x, -dunia.y)


## True bila titik dunia ada di dalam zona: tepi min inklusif, tepi maks eksklusif. Titik tidak hingga = false.
static func memuat(zona: Zona, titik_dunia: Vector2) -> bool:
	if zona == null or not titik_dunia.is_finite():
		return false
	var p: Vector2 = ke_jalan(titik_dunia)
	var awal: Vector2 = zona.persegi.position
	var akhir: Vector2 = zona.persegi.end
	return p.x >= awal.x and p.x < akhir.x and p.y >= awal.y and p.y < akhir.y


## Zona yang menang untuk titik mendarat (lihat aturan di atas, tanpa sisi lempar), atau null bila tidak ada.
static func zona_kena(titik_dunia: Vector2, daftar: Array[Zona]) -> Zona:
	var terbaik: Zona = null
	var peringkat_terbaik: int = PRIORITAS.size()
	for zona: Zona in daftar:
		if zona == null or not memuat(zona, titik_dunia):
			continue
		var peringkat: int = PRIORITAS.find(zona.jenis)
		if peringkat < 0:
			continue
		if peringkat < peringkat_terbaik:
			terbaik = zona
			peringkat_terbaik = peringkat
	return terbaik


## Hasil klasifikasi titik mendarat (dunia, ubin) terhadap `daftar` zona; tidak bergantung arah atau sisi lemparan.
static func klasifikasi(titik_dunia: Vector2, daftar: Array[Zona]) -> Hasil:
	return hasil_zona(zona_kena(titik_dunia, daftar))


## Hasil untuk zona yang kena (null = `MELESET`, rumah bukan pelanggan = `BUKAN_PELANGGAN`).
static func hasil_zona(zona: Zona) -> Hasil:
	if zona == null:
		return Hasil.MELESET
	if not zona.pelanggan:
		return Hasil.BUKAN_PELANGGAN
	match zona.jenis:
		Jenis.KOTAK_SURAT:
			return Hasil.KOTAK_SURAT
		Jenis.TERAS:
			return Hasil.TERAS
		Jenis.HALAMAN:
			return Hasil.HALAMAN
		Jenis.JENDELA:
			return Hasil.JENDELA
	return Hasil.MELESET


## Status antaran dari hasil (BALANCING 5). `jendela_bonus` = sakelar jendela (`Config.JENDELA_KENA_BONUS` di game): true = sah bonus,
## false = penalti ringan (tidak sah, tanpa hukuman lain).
static func status_antaran(hasil: Hasil, jendela_bonus: bool) -> Antaran:
	match hasil:
		Hasil.KOTAK_SURAT, Hasil.TERAS:
			return Antaran.SAH_PENUH
		Hasil.HALAMAN:
			return Antaran.SAH_SETENGAH
		Hasil.JENDELA:
			return Antaran.SAH_BONUS if jendela_bonus else Antaran.TIDAK_SAH
	return Antaran.TIDAK_SAH


## True bila antaran sah (dihitung terkirim; elips garis bidik berubah `OK` dan berubah bentuk, D-5).
static func sah(antaran: Antaran) -> bool:
	return antaran != Antaran.TIDAK_SAH


## Bentuk penanda untuk status antaran (D-10). Tiap antaran sah punya bentuk berbeda dari tidak sah.
static func penanda(antaran: Antaran) -> Penanda:
	match antaran:
		Antaran.SAH_PENUH:
			return Penanda.CENTANG
		Antaran.SAH_SETENGAH:
			return Penanda.SETENGAH
		Antaran.SAH_BONUS:
			return Penanda.BINTANG
	return Penanda.SILANG


## Bentuk penanda langsung dari hasil dan sakelar jendela.
static func penanda_hasil(hasil: Hasil, jendela_bonus: bool) -> Penanda:
	return penanda(status_antaran(hasil, jendela_bonus))


# --- Data jalan uji (Config.JALAN_UJI_*, placeholder usulan) ---

## True bila rumah seberang bernomor `indeks` pelanggan; bukan pelanggan bila indeks mod `JALAN_UJI_BUKAN_PELANGGAN_SETIAP` sama
## dengan `JALAN_UJI_BUKAN_PELANGGAN_SISA` (nomor negatif juga, `posmod`). Kavling sisi dekat selalu pelanggan.
static func pelanggan_jalan_uji(indeks: int) -> bool:
	return posmod(indeks, Config.JALAN_UJI_BUKAN_PELANGGAN_SETIAP) != Config.JALAN_UJI_BUKAN_PELANGGAN_SISA


## Zona kavling bernomor `indeks` di jalan uji: empat zona seberang (kotak surat, halaman, teras, jendela) dan tiga zona dekat
## (kotak surat, halaman, teras), digeser maju `indeks x JALAN_UJI_RUMAH_PERIODE_UBIN`.
static func zona_jalan_uji(indeks: int) -> Array[Zona]:
	var maju: float = float(indeks * Config.JALAN_UJI_RUMAH_PERIODE_UBIN)
	var pelanggan: bool = pelanggan_jalan_uji(indeks)
	var hasil: Array[Zona] = []
	hasil.append(buat(_persegi(Config.JALAN_UJI_SEBERANG_KOTAK_SURAT_UBIN, maju), LoperAnim.Sisi.SEBERANG, Jenis.KOTAK_SURAT, pelanggan, indeks))
	hasil.append(buat(_persegi(Config.JALAN_UJI_SEBERANG_HALAMAN_UBIN, maju), LoperAnim.Sisi.SEBERANG, Jenis.HALAMAN, pelanggan, indeks))
	hasil.append(buat(_persegi(Config.JALAN_UJI_SEBERANG_TERAS_UBIN, maju), LoperAnim.Sisi.SEBERANG, Jenis.TERAS, pelanggan, indeks))
	hasil.append(buat(_persegi(Config.JALAN_UJI_SEBERANG_JENDELA_UBIN, maju), LoperAnim.Sisi.SEBERANG, Jenis.JENDELA, pelanggan, indeks))
	hasil.append(buat(_persegi(Config.JALAN_UJI_DEKAT_KOTAK_SURAT_UBIN, maju), LoperAnim.Sisi.DEKAT, Jenis.KOTAK_SURAT, true, indeks))
	hasil.append(buat(_persegi(Config.JALAN_UJI_DEKAT_HALAMAN_UBIN, maju), LoperAnim.Sisi.DEKAT, Jenis.HALAMAN, true, indeks))
	hasil.append(buat(_persegi(Config.JALAN_UJI_DEKAT_TERAS_UBIN, maju), LoperAnim.Sisi.DEKAT, Jenis.TERAS, true, indeks))
	return hasil


## Zona semua kavling yang bisa memuat titik dengan jarak maju `maju_ubin` (kavling di sekitarnya, satu di tiap arah sebagai cadangan
## untuk zona yang menjorok ke kavling tetangga).
static func zona_jalan_uji_sekitar(maju_ubin: float) -> Array[Zona]:
	var hasil: Array[Zona] = []
	if not is_finite(maju_ubin):
		return hasil
	var tengah: int = floori(maju_ubin / float(Config.JALAN_UJI_RUMAH_PERIODE_UBIN))
	for indeks: int in range(tengah - 1, tengah + 2):
		hasil.append_array(zona_jalan_uji(indeks))
	return hasil


## Klasifikasi titik mendarat di jalan uji (zona kavling sekitar titik itu), dari titik saja.
static func klasifikasi_jalan_uji(titik_dunia: Vector2) -> Hasil:
	return klasifikasi(titik_dunia, zona_jalan_uji_sekitar(ke_jalan(titik_dunia).y))


## Tapak kotak rumah graybox seberang kavling `indeks` di bidang tanah, koordinat jalan (QA-004): lateral dari kaki fasad
## (`JALAN_UJI_RUMAH_X_UBIN`) ke arah seberang sedalam `JALAN_UJI_RUMAH_DALAM_UBIN`, maju dari titik pijak rumah (`JalanDaur.maju_objek_ubin`,
## sama dengan `ObjekDaur`) sepanjang `JALAN_UJI_RUMAH_PANJANG_UBIN`.
static func tapak_rumah_jalan_uji(indeks: int) -> Rect2:
	var maju: float = JalanDaur.maju_objek_ubin(indeks, Config.JALAN_UJI_RUMAH_PERIODE_UBIN, Config.JALAN_UJI_RUMAH_MAJU_UBIN)
	var dalam: float = Config.JALAN_UJI_RUMAH_DALAM_UBIN
	return Rect2(Config.JALAN_UJI_RUMAH_X_UBIN - dalam, maju, dalam, Config.JALAN_UJI_RUMAH_PANJANG_UBIN)


## True bila titik di dunia setinggi `tinggi_ubin` tertutup kotak setinggi `tinggi_kotak_ubin` di atas `tapak` (koordinat jalan) dilihat dari
## kamera iso 2:1 (QA-004). Titik (x, y, z) dan (x + d, y + d, z + d) jatuh di titik layar yang sama (`Iso`), dan d > 0 lebih dekat ke
## kamera; jadi titik tertutup bila ada d >= 0 dengan (x + d, y + d) di dalam tapak dan z + d <= tinggi kotak (d = 0: di dalam kotak). Di
## koordinat jalan: lateral + d dan maju - d. Titik tepat di tepi tidak tertutup (irisan selang d harus terbuka), jadi zona di kaki fasad
## (lateral >= kaki fasad) tidak pernah tertutup. Masukan tidak hingga = false.
static func tertutup_kotak(titik_dunia: Vector2, tinggi_ubin: float, tapak: Rect2, tinggi_kotak_ubin: float) -> bool:
	if not titik_dunia.is_finite() or not is_finite(tinggi_ubin) or not is_finite(tinggi_kotak_ubin):
		return false
	var p: Vector2 = ke_jalan(titik_dunia)
	var bawah: float = maxf(0.0, maxf(tapak.position.x - p.x, p.y - tapak.end.y))
	var atas: float = minf(tinggi_kotak_ubin - maxf(tinggi_ubin, 0.0), minf(tapak.end.x - p.x, p.y - tapak.position.y))
	return bawah < atas


## True bila titik di dunia setinggi `tinggi_ubin` tertutup salah satu rumah graybox seberang jalan uji (kavling di sekitarnya).
static func tertutup_rumah_jalan_uji(titik_dunia: Vector2, tinggi_ubin: float) -> bool:
	if not titik_dunia.is_finite():
		return false
	var tengah: int = floori(ke_jalan(titik_dunia).y / float(Config.JALAN_UJI_RUMAH_PERIODE_UBIN))
	for indeks: int in range(tengah - 1, tengah + 2):
		if tertutup_kotak(titik_dunia, tinggi_ubin, tapak_rumah_jalan_uji(indeks), Config.JALAN_UJI_RUMAH_TINGGI_UBIN):
			return true
	return false


## Persegi dari data `[lateral_min, maju_min, lebar_lateral, panjang_maju]`, maju digeser `geser_maju`.
static func _persegi(data: Array[float], geser_maju: float) -> Rect2:
	var ukuran: Array[float] = data.slice(2)
	return Rect2(data[0], data[1] + geser_maju, ukuran[0], ukuran[1])
