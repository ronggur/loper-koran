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
## `BAWAAN` = tekstur kolom biasa (termasuk `rumput_1` di kolom luar). Semua baris adalah baris MUTLAK dari awal rute (maju bulat; ubin berpusat di maju bulat, menutup baris maju - 0,5 sampai
## maju + 0,5). Tidak ada keadaan, node, atau Godot lain di sini: `TanahDaur` hanya menerapkan hasilnya.

enum Ubin { BAWAAN, MASUK, SIMBOL, RUMPUT_2, RUMPUT_3 }


## Baris ubin yang ditimpa jalan masuk garasi untuk mobil di maju `maju_ubin`: pembulatan maju ke baris terdekat, titik tepat di batas dua baris ke baris di belakang (maju lebih kecil).
## Mobil selebar 0,75 ubin di celah satu ubin antar rumah, jadi tepat satu baris.
static func baris_masuk(maju_ubin: float) -> int:
	return ceili(maju_ubin - 1.0 / 2)


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
static func jenis(x: float, baris: int, baris_masuk_rute: Dictionary) -> Ubin:
	var masuk: bool = baris_masuk_rute.has(baris)
	match JalanDaur.kolom_di(x):
		JalanDaur.Kolom.TROTOAR_SEBERANG:
			if masuk:
				return Ubin.MASUK
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
		JalanDaur.Kolom.RUMPUT_DEKAT:
			if JalanDaur.rumput_luar(x):
				return varian_rumput(floori(x), baris)
	return Ubin.BAWAAN
