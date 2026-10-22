class_name UbinKhusus
extends RefCounted
## Pemilihan ubin tanah khusus rute, logika murni (run fase5b-tembok-dekor bagian C, D-7, AC-14; usulan, hanya tampilan).
##
## Tiga jenis ubin menggantikan tekstur bawaan satu sel kolomnya, tanpa mengubah posisi atau jumlah sel (`JalanDaur.sel_tanah`, `kolom_di`, `jenis_di` tidak disentuh):
## - `MASUK`: jalan masuk garasi di bawah mobil garasi sisi `seberang`. Hanya kolom `TROTOAR_SEBERANG` dan kolom rumput PERTAMA sisi seberang (`RUMPUT_SEBERANG`, bukan rumput
##   luar), di baris ubin yang menutup titik rumah mobil (`baris_masuk`). Mobil sisi `dekat` tidak punya ubin masuk (aset `*_dekat_masuk` tidak dipasang, D-1).
## - `SIMBOL`: simbol sepeda di kedua kolom trotoar tiap `RUTE_SIMBOL_SEPEDA_SELANG_UBIN` baris (`simbol_di_baris`), tidak di baris `MASUK`.
## - `RUMPUT_2` dan `RUMPUT_3`: variasi rumput polos di kolom rumput luar (`JalanDaur.rumput_luar`), dipilih dari (kolom, baris) lewat hash FNV-1a, tanpa RNG dan tanpa hash bawaan Godot.
##   Kolom rumput pertama (ubin tepi kerb) tidak pernah diganti.
## - `UJUNG` (run fase5c-animasi-simpang, C-F1 run 5B): ujung kerb di kolom `TROTOAR_SEBERANG` dan rumput pertama seberang pada baris `RUTE_UJUNG_KERB_BARIS_RELATIF` di depan baris
##   `MASUK` (kerb yang putus di jalan masuk tidak lagi menjorok ke sel tetangga). `MASUK` menang atas `UJUNG`, `UJUNG` menang atas `SIMBOL` (ubin ujung tidak membawa simbol).
## `BAWAAN` = tekstur kolom biasa (termasuk `rumput_1` di kolom luar). Semua baris adalah baris MUTLAK dari awal rute (maju bulat; ubin berpusat di maju bulat, menutup baris maju - 0,5 sampai
## maju + 0,5). Tidak ada keadaan, node, atau Godot lain di sini: `TanahDaur` hanya menerapkan hasilnya.
##
## Simpang T hiasan (run fase5c-animasi-simpang, P-1, D-3; `sel_simpang`): di baris pita simpang (`RUTE_SIMPANG_PITA_BARIS` relatif ke `pos`) dan HANYA di sisi simpang, sel kolom aspal,
## trotoar, rumput pertama, dan semua kolom rumput luar (lengan jalan samping yang berulang ke luar) memakai ubin simpang menurut tabel `RUTE_SIMPANG_SEL_<SISI>`; sel yang tidak ada di tabel
## (sama dengan jalan lurus di adegan renderer) tetap ubin biasa. Ubin simpang menang atas semua jenis lain di sel itu (validasi segmen menjamin tidak ada jalan masuk di pita).

enum Ubin { BAWAAN, MASUK, SIMBOL, RUMPUT_2, RUMPUT_3, UJUNG }
## Kolom sel simpang (nilai kedua tiap pasangan `RUTE_SIMPANG_SEL_*`): aspal, trotoar, rumput pertama, lengan (kolom rumput luar).
enum KolomSimpang { ASPAL, TROTOAR, RUMPUT, LENGAN }
## Hasil `sel_simpang` bila sel bukan ubin simpang.
const TANPA_SIMPANG: Vector2i = Vector2i(-1, -1)


## Baris ubin yang ditimpa jalan masuk garasi untuk mobil di maju `maju_ubin`: pembulatan maju ke baris terdekat, titik tepat di batas dua baris ke baris di belakang (maju lebih kecil).
## Mobil selebar 0,75 ubin di celah satu ubin antar rumah, jadi tepat satu baris.
static func baris_masuk(maju_ubin: float) -> int:
	return ceili(maju_ubin - Config.RUTE_BARIS_MASUK_GESER_UBIN)


## Himpunan baris `MASUK` (kunci = baris mutlak, nilai true) dari objek rute: hanya `mobil_garasi` dengan jalur `seberang`.
static func himpunan_baris_masuk(objek: Array[RouteBuilder.ObjekRute]) -> Dictionary:
	var hasil: Dictionary = {}
	for o: RouteBuilder.ObjekRute in objek:
		if o.jenis == "mobil_garasi" and o.jalur == SegmenRute.NAMA_SISI[0]:
			hasil[baris_masuk(o.maju_ubin)] = true
	return hasil


## Benar bila baris mutlak `baris` membawa simbol sepeda (tiap `RUTE_SIMBOL_SEPEDA_SELANG_UBIN` baris, bergeser `RUTE_SIMBOL_SEPEDA_OFFSET_UBIN`, juga di baris negatif).
static func simbol_di_baris(baris: int) -> bool:
	return posmod(baris - Config.RUTE_SIMBOL_SEPEDA_OFFSET_UBIN, Config.RUTE_SIMBOL_SEPEDA_SELANG_UBIN) == 0


## FNV-1a 32 bit atas dua bilangan bulat: tiap bilangan sebagai 4 byte (urut byte paling rendah dulu, dua komplemen 32 bit), pertama `a` lalu `b`. 0 sampai 2^32 - 1.
static func fnv1a_dua_int(a: int, b: int) -> int:
	return _lipat(_lipat(Config.HASH_FNV1A_AWAL, a), b)


## Satu langkah FNV-1a untuk keempat byte `bilangan` (dua komplemen 32 bit, byte paling rendah dulu) di atas `nilai`.
static func _lipat(nilai: int, bilangan: int) -> int:
	var hasil: int = nilai
	var sisa: int = bilangan & Config.HASH_FNV1A_MASKER
	for _i: int in range(Config.HASH_FNV1A_BYTE_PER_INT):
		hasil = ((hasil ^ (sisa & Config.HASH_FNV1A_MASKER_BYTE)) * Config.HASH_FNV1A_KALI) & Config.HASH_FNV1A_MASKER
		sisa = sisa >> Config.HASH_FNV1A_GESER_BIT
	return hasil


## Varian rumput polos di ubin kolom `indeks_kolom` (indeks bulat kolom: lantai pusat x) dan baris mutlak `baris`: `RUMPUT_2`, `RUMPUT_3`, atau `BAWAAN` (rumput_1, dominan).
static func varian_rumput(indeks_kolom: int, baris: int) -> Ubin:
	var v: int = fnv1a_dua_int(indeks_kolom, baris) % Config.RUTE_RUMPUT_VARIAN_MOD
	if v < Config.RUTE_RUMPUT_VARIAN_2_PERSEN:
		return Ubin.RUMPUT_2
	if v < Config.RUTE_RUMPUT_VARIAN_2_PERSEN + Config.RUTE_RUMPUT_VARIAN_3_PERSEN:
		return Ubin.RUMPUT_3
	return Ubin.BAWAAN


## Jenis ubin di sel berpusat melintang `x` (ubin dari garis tengah, pusat setengah ganjil) dan baris mutlak `baris`; `baris_masuk_rute` dari `himpunan_baris_masuk` (kosong = tanpa jalan masuk).
## `dengan_ujung` false = tanpa ujung kerb (perilaku run 5B; dipakai `TanahDaur` tanpa tekstur ujung).
static func jenis(x: float, baris: int, baris_masuk_rute: Dictionary, dengan_ujung: bool = true) -> Ubin:
	var masuk: bool = baris_masuk_rute.has(baris)
	var ujung: bool = dengan_ujung and ujung_di_baris(baris, baris_masuk_rute)
	match JalanDaur.kolom_di(x):
		JalanDaur.Kolom.TROTOAR_SEBERANG:
			if masuk:
				return Ubin.MASUK
			if ujung:
				return Ubin.UJUNG
			if simbol_di_baris(baris):
				return Ubin.SIMBOL
		JalanDaur.Kolom.TROTOAR_DEKAT:
			if not masuk and simbol_di_baris(baris):
				return Ubin.SIMBOL
		JalanDaur.Kolom.RUMPUT_SEBERANG:
			if JalanDaur.rumput_luar(x):
				return varian_rumput(floori(x), baris)
			if masuk:
				return Ubin.MASUK
			if ujung:
				return Ubin.UJUNG
		JalanDaur.Kolom.RUMPUT_DEKAT:
			if JalanDaur.rumput_luar(x):
				return varian_rumput(floori(x), baris)
	return Ubin.BAWAAN


## Benar bila baris mutlak `baris` adalah baris ujung kerb: baris `RUTE_UJUNG_KERB_BARIS_RELATIF` di depan sebuah baris jalan masuk (`baris_masuk_rute`) dan bukan baris jalan masuk sendiri.
static func ujung_di_baris(baris: int, baris_masuk_rute: Dictionary) -> bool:
	return baris_masuk_rute.has(baris - Config.RUTE_UJUNG_KERB_BARIS_RELATIF) and not baris_masuk_rute.has(baris)


## Himpunan baris pita simpang (kunci = baris mutlak, nilai = Vector2i(sisi `LoperAnim.Sisi`, baris relatif ke `pos` simpang)) dari simpang rute (`RouteBuilder.simpang_di`).
## Pita dua simpang tidak bertumpuk (validasi segmen dan `RouteBuilder.periksa_rute`), jadi satu baris paling banyak satu simpang; bila tetap bertumpuk, simpang yang lebih awal di daftar menang.
static func himpunan_baris_simpang(simpang: Array[RouteBuilder.SimpangItem]) -> Dictionary:
	var hasil: Dictionary = {}
	for item: RouteBuilder.SimpangItem in simpang:
		var dasar: int = roundi(item.maju_ubin)
		for relatif: int in range(Config.RUTE_SIMPANG_PITA_BARIS[0], Config.RUTE_SIMPANG_PITA_BARIS[1] + 1):
			if not hasil.has(dasar + relatif):
				hasil[dasar + relatif] = Vector2i(item.sisi, relatif)
	return hasil


## Tabel sel simpang sisi `sisi` (`RUTE_SIMPANG_SEL_DEKAT` atau `RUTE_SIMPANG_SEL_SEBERANG`; kosong untuk sisi lain).
static func tabel_simpang(sisi: LoperAnim.Sisi) -> Array[int]:
	if sisi == LoperAnim.Sisi.DEKAT:
		return Config.RUTE_SIMPANG_SEL_DEKAT
	if sisi == LoperAnim.Sisi.SEBERANG:
		return Config.RUTE_SIMPANG_SEL_SEBERANG
	return []


## Kolom sel simpang di posisi melintang `x` (aspal, trotoar, rumput pertama, atau lengan untuk semua kolom rumput luar).
static func kolom_simpang(x: float) -> KolomSimpang:
	match JalanDaur.jenis_di(x):
		JalanDaur.Jenis.ASPAL:
			return KolomSimpang.ASPAL
		JalanDaur.Jenis.TROTOAR:
			return KolomSimpang.TROTOAR
	return KolomSimpang.LENGAN if JalanDaur.rumput_luar(x) else KolomSimpang.RUMPUT


## Ubin simpang sel berpusat melintang `x` di baris mutlak `baris`: Vector2i(sisi simpang, indeks pasangan di `tabel_simpang(sisi)`), atau `TANPA_SIMPANG` bila baris di luar pita,
## sel di sisi lain jalan (x negatif = seberang, nol dan positif = dekat, sama dengan `JalanDaur.kolom_di`), atau sel tidak ada di tabel (sama dengan jalan lurus).
static func sel_simpang(x: float, baris: int, baris_simpang: Dictionary) -> Vector2i:
	if not baris_simpang.has(baris):
		return TANPA_SIMPANG
	var entri: Vector2i = baris_simpang[baris]
	var sisi_sel: LoperAnim.Sisi = LoperAnim.Sisi.DEKAT if x >= 0.0 else LoperAnim.Sisi.SEBERANG
	if sisi_sel != entri.x:
		return TANPA_SIMPANG
	var tabel: Array[int] = tabel_simpang(sisi_sel)
	var kolom: int = kolom_simpang(x)
	for i: int in range(tabel.size() / 2):
		if tabel[2 * i] == entri.y and tabel[2 * i + 1] == kolom:
			return Vector2i(sisi_sel, i)
	return TANPA_SIMPANG
