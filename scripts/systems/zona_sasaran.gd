class_name ZonaSasaran
extends RefCounted
## Zona sasaran koran, status antaran, dan bentuk penanda, logika murni (BALANCING 5, DESIGN_SPEC 3.6; D-6, D-7, D-10 run
## fase2a-lemparan, D-4 run fase2-arah-bebas). Semua usulan placeholder untuk jalan uji; skor, combo, dan koin ada di `SkorRute`.
## Inti "tepat" (K-4 run fase3b-rintangan-skor): zona kotak surat membawa `inti`, persegi 0,5 x 0,5 di pusat areanya
## (`Config.JALAN_UJI_*_KOTAK_SURAT_INTI_UBIN`, seberang dan dekat); titik di inti = antaran tepat (`tepat`), tepi seperti zona lain.
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
## bentuk berbeda dari sah biasa), setengah (halaman), silang kecil (tidak sah, `FAIL`; bukan panel merah besar). Run fase3b-rintangan-skor
## menambah `TEPAT` (antaran tepat di inti kotak surat, K-4, bentuk berbeda dari centang dan bintang) dan `NETRAL` (koran ke rumah yang sudah
## terantar, O-1); keduanya dipilih `SkorRute.penanda`, bukan `penanda` di bawah (yang tidak tahu status rumah).
enum Penanda { SILANG, CENTANG, SETENGAH, BINTANG, TEPAT, NETRAL }

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
	## Id rumah di rute (`<id_segmen>@<pos>`, DATA_SCHEMA 3); kosong untuk zona jalan uji.
	var id_rumah: String = ""
	## Inti "tepat" (K-4), koordinat jalan, ubin; hanya zona kotak surat (ukuran nol = tidak ada inti).
	var inti: Rect2 = Rect2()


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


## True bila titik dunia ada di inti "tepat" zona kotak surat `zona` (K-4): tepi min inklusif, maks eksklusif, seperti `memuat`. Zona lain,
## zona tanpa inti, null, atau titik tidak hingga = false. Status pelanggan dan mode bantu diperiksa pemanggil (`KoranLempar`, O-4).
static func tepat(zona: Zona, titik_dunia: Vector2) -> bool:
	if zona == null or zona.jenis != Jenis.KOTAK_SURAT or not zona.inti.has_area() or not titik_dunia.is_finite():
		return false
	var p: Vector2 = ke_jalan(titik_dunia)
	return p.x >= zona.inti.position.x and p.x < zona.inti.end.x and p.y >= zona.inti.position.y and p.y < zona.inti.end.y


## Bentuk penanda langsung dari hasil dan sakelar jendela.
static func penanda_hasil(hasil: Hasil, jendela_bonus: bool) -> Penanda:
	return penanda(status_antaran(hasil, jendela_bonus))


# --- Data jalan uji (Config.JALAN_UJI_*, placeholder usulan) ---

## True bila rumah seberang bernomor `indeks` pelanggan; bukan pelanggan bila indeks mod `JALAN_UJI_BUKAN_PELANGGAN_SETIAP` sama
## dengan `JALAN_UJI_BUKAN_PELANGGAN_SISA` (nomor negatif juga, `posmod`). Kavling sisi dekat selalu pelanggan.
static func pelanggan_jalan_uji(indeks: int) -> bool:
	return posmod(indeks, Config.JALAN_UJI_BUKAN_PELANGGAN_SETIAP) != Config.JALAN_UJI_BUKAN_PELANGGAN_SISA


## Zona kavling bernomor `indeks` di jalan uji: empat zona seberang (kotak surat, halaman, teras, jendela) dan tiga zona dekat
## (kotak surat, halaman, teras), digeser maju `indeks x JALAN_UJI_RUMAH_PERIODE_UBIN`. Geometri sama dengan zona rumah rute.
static func zona_jalan_uji(indeks: int) -> Array[Zona]:
	var maju: float = float(indeks * Config.JALAN_UJI_RUMAH_PERIODE_UBIN)
	var hasil: Array[Zona] = zona_rumah_seberang(maju, pelanggan_jalan_uji(indeks), indeks)
	hasil.append_array(zona_rumah_dekat(maju, true, indeks))
	return hasil


# --- Zona dari data rute (AC-9 run fase3a-rute; usulan) ---
# Geometri sama dengan zona jalan uji (`Config.JALAN_UJI_*`), diparametrisasi oleh awal kavling `maju_awal_ubin` (jarak maju dari awal
# rute sampai `pos` rumah). Rumah yang bukan pelanggan memberi zona `BUKAN_PELANGGAN` (rumah dekat pelanggan hanya sejak hari `RUTE_DEKAT_HARI_MULAI`, run fase5d-sisi-dekat bagian B).

## Empat zona rumah sisi `seberang` (kotak surat, halaman, teras, jendela) dengan awal kavling `maju_awal_ubin`.
static func zona_rumah_seberang(maju_awal_ubin: float, pelanggan: bool, nomor: int = 0, id_rumah: String = "") -> Array[Zona]:
	var hasil: Array[Zona] = []
	hasil.append(buat(_persegi(Config.JALAN_UJI_SEBERANG_KOTAK_SURAT_UBIN, maju_awal_ubin), LoperAnim.Sisi.SEBERANG, Jenis.KOTAK_SURAT, pelanggan, nomor))
	hasil.append(buat(_persegi(Config.JALAN_UJI_SEBERANG_HALAMAN_UBIN, maju_awal_ubin), LoperAnim.Sisi.SEBERANG, Jenis.HALAMAN, pelanggan, nomor))
	hasil.append(buat(_persegi(Config.JALAN_UJI_SEBERANG_TERAS_UBIN, maju_awal_ubin), LoperAnim.Sisi.SEBERANG, Jenis.TERAS, pelanggan, nomor))
	hasil.append(buat(_persegi(Config.JALAN_UJI_SEBERANG_JENDELA_UBIN, maju_awal_ubin), LoperAnim.Sisi.SEBERANG, Jenis.JENDELA, pelanggan, nomor))
	hasil[0].inti = _persegi(Config.JALAN_UJI_SEBERANG_KOTAK_SURAT_INTI_UBIN, maju_awal_ubin)
	for zona: Zona in hasil:
		zona.id_rumah = id_rumah
	return hasil


## Tiga zona rumah sisi `dekat` JALAN UJI (kotak surat, halaman, teras; tanpa jendela, placeholder datar `Config.JALAN_UJI_DEKAT_*`) dengan awal kavling `maju_awal_ubin`. Rumah dekat di rute memakai `zona_rumah_dekat_rute`.
static func zona_rumah_dekat(maju_awal_ubin: float, pelanggan: bool, nomor: int = 0, id_rumah: String = "") -> Array[Zona]:
	var hasil: Array[Zona] = []
	hasil.append(buat(_persegi(Config.JALAN_UJI_DEKAT_KOTAK_SURAT_UBIN, maju_awal_ubin), LoperAnim.Sisi.DEKAT, Jenis.KOTAK_SURAT, pelanggan, nomor))
	hasil.append(buat(_persegi(Config.JALAN_UJI_DEKAT_HALAMAN_UBIN, maju_awal_ubin), LoperAnim.Sisi.DEKAT, Jenis.HALAMAN, pelanggan, nomor))
	hasil.append(buat(_persegi(Config.JALAN_UJI_DEKAT_TERAS_UBIN, maju_awal_ubin), LoperAnim.Sisi.DEKAT, Jenis.TERAS, pelanggan, nomor))
	hasil[0].inti = _persegi(Config.JALAN_UJI_DEKAT_KOTAK_SURAT_INTI_UBIN, maju_awal_ubin)
	for zona: Zona in hasil:
		zona.id_rumah = id_rumah
	return hasil


## Lantai teras menjorok rumah dekat di rute, koordinat jalan (x = lateral, y = maju), ubin, awal kavling `maju_awal_ubin` (run fase5d-sisi-dekat bagian B, AC-10): `teras_ubin` dari JSON aset
## (`Config.RUTE_RUMAH_DEKAT_TERAS_UBIN`, relatif titik pijak gambar) digeser ke pijak gambar rumah dekat = pusat tapak logika (kaki fasad `RUTE_RUMAH_DEKAT_X_UBIN` + setengah `RUTE_RUMAH_DALAM_UBIN`,
## `JALAN_UJI_RUMAH_MAJU_UBIN` + setengah `RUTE_RUMAH_PANJANG_UBIN`) + mundur `RUTE_RUMAH_DEKAT_MUNDUR_UBIN` (SpriteRumah.pusat_gambar_dunia). Sama untuk semua jenis rumah dekat.
static func teras_dekat(maju_awal_ubin: float) -> Rect2:
	var teras: Array[float] = Config.RUTE_RUMAH_DEKAT_TERAS_UBIN
	var pusat_lateral: float = Config.RUTE_RUMAH_DEKAT_X_UBIN + Config.RUTE_RUMAH_DALAM_UBIN / 2 + Config.RUTE_RUMAH_DEKAT_MUNDUR_UBIN
	var pusat_maju: float = maju_awal_ubin + Config.JALAN_UJI_RUMAH_MAJU_UBIN + Config.RUTE_RUMAH_PANJANG_UBIN / 2
	var ukuran: Array[float] = teras.slice(2)
	return Rect2(pusat_lateral + teras[0], pusat_maju + teras[1], ukuran[0], ukuran[1])


## Tiga zona rumah sisi `dekat` di RUTE (kotak surat, halaman, teras; tanpa jendela), cermin sasaran seberang (run fase5d-sisi-dekat bagian B, P-5, AC-10): kotak surat `RUTE_DEKAT_KOTAK_SURAT_UBIN`
## (dengan inti tepat), halaman `RUTE_DEKAT_HALAMAN_UBIN`, dan teras dari geometri teras menjorok rumah dekat baru (`teras_dekat`). Prioritas dan angka skor sama dengan seberang. Zona dekat jalan uji
## (placeholder datar, `zona_rumah_dekat`) tidak berubah.
static func zona_rumah_dekat_rute(maju_awal_ubin: float, pelanggan: bool, nomor: int = 0, id_rumah: String = "") -> Array[Zona]:
	var hasil: Array[Zona] = []
	hasil.append(buat(_persegi(Config.RUTE_DEKAT_KOTAK_SURAT_UBIN, maju_awal_ubin), LoperAnim.Sisi.DEKAT, Jenis.KOTAK_SURAT, pelanggan, nomor))
	hasil.append(buat(_persegi(Config.RUTE_DEKAT_HALAMAN_UBIN, maju_awal_ubin), LoperAnim.Sisi.DEKAT, Jenis.HALAMAN, pelanggan, nomor))
	hasil.append(buat(teras_dekat(maju_awal_ubin), LoperAnim.Sisi.DEKAT, Jenis.TERAS, pelanggan, nomor))
	hasil[0].inti = _persegi(Config.RUTE_DEKAT_KOTAK_SURAT_INTI_UBIN, maju_awal_ubin)
	for zona: Zona in hasil:
		zona.id_rumah = id_rumah
	return hasil


## Zona satu rumah rute menurut sisinya (kosong bila sisi `TIDAK_ADA`).
static func zona_rumah(rumah: RouteBuilder.RumahRute) -> Array[Zona]:
	if rumah.sisi == LoperAnim.Sisi.SEBERANG:
		return zona_rumah_seberang(rumah.maju_ubin, rumah.pelanggan, 0, rumah.id)
	if rumah.sisi == LoperAnim.Sisi.DEKAT:
		return zona_rumah_dekat_rute(rumah.maju_ubin, rumah.pelanggan, 0, rumah.id)
	return []


## Jarak maju dari awal rute ke pusat zona kotak surat rumah `rumah` (geometri sama dengan `zona_rumah`, tanpa membuat zona; dipakai radar
## dan progres per langkah, run fase3c-hud-hasil). Sisi `TIDAK_ADA` = awal kavling.
static func maju_kotak_surat(rumah: RouteBuilder.RumahRute) -> float:
	var data: Array[float] = []
	if rumah.sisi == LoperAnim.Sisi.SEBERANG:
		data = Config.JALAN_UJI_SEBERANG_KOTAK_SURAT_UBIN
	elif rumah.sisi == LoperAnim.Sisi.DEKAT:
		data = Config.RUTE_DEKAT_KOTAK_SURAT_UBIN
	if data.is_empty():
		return rumah.maju_ubin
	return _persegi(data, rumah.maju_ubin).get_center().y


## Zona semua rumah di `daftar` (rumah rute, urut maju atau tidak).
static func zona_rute(daftar: Array[RouteBuilder.RumahRute]) -> Array[Zona]:
	var hasil: Array[Zona] = []
	for rumah: RouteBuilder.RumahRute in daftar:
		hasil.append_array(zona_rumah(rumah))
	return hasil


## Zona rumah rute yang bisa memuat titik dengan jarak maju dari `maju_awal_ubin` sampai `maju_akhir_ubin`: kavling yang mulainya dalam
## rentang itu dan satu petak (`RUTE_PETAK_UBIN`) cadangan di tiap ujung (zona menjorok ke kavling tetangga). Dipakai penilaian koran dan
## mode bantu sejauh jangkauan lemparan, bukan seluruh rute. Masukan tidak hingga = kosong.
static func zona_rute_rentang(daftar: Array[RouteBuilder.RumahRute], maju_awal_ubin: float, maju_akhir_ubin: float) -> Array[Zona]:
	var hasil: Array[Zona] = []
	if not is_finite(maju_awal_ubin) or not is_finite(maju_akhir_ubin):
		return hasil
	var dari: float = minf(maju_awal_ubin, maju_akhir_ubin) - float(Config.RUTE_PETAK_UBIN)
	var sampai: float = maxf(maju_awal_ubin, maju_akhir_ubin) + float(Config.RUTE_PETAK_UBIN)
	for rumah: RouteBuilder.RumahRute in daftar:
		if rumah.maju_ubin >= dari and rumah.maju_ubin <= sampai:
			hasil.append_array(zona_rumah(rumah))
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


## Zona semua kavling jalan uji yang bisa memuat titik dengan jarak maju dari `maju_awal_ubin` sampai `maju_akhir_ubin` (satu kavling
## cadangan di tiap ujung, seperti `zona_jalan_uji_sekitar`). Dipakai mode bantu untuk sasaran sejauh jangkauan lemparan
## (`BantuLempar.jangkauan_maju_ubin`). Masukan tidak hingga = kosong.
static func zona_jalan_uji_rentang(maju_awal_ubin: float, maju_akhir_ubin: float) -> Array[Zona]:
	var hasil: Array[Zona] = []
	if not is_finite(maju_awal_ubin) or not is_finite(maju_akhir_ubin):
		return hasil
	var periode: float = float(Config.JALAN_UJI_RUMAH_PERIODE_UBIN)
	var awal: int = floori(minf(maju_awal_ubin, maju_akhir_ubin) / periode)
	var akhir: int = floori(maxf(maju_awal_ubin, maju_akhir_ubin) / periode)
	for indeks: int in range(awal - 1, akhir + 2):
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
