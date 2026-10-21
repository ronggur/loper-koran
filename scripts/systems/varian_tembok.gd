class_name VarianTembok
extends RefCounted
## Pilihan varian tembok sisi dekat dari id rumah, logika murni (run fase5b-tembok-dekor bagian B1, D-3, AC-5; usulan).
##
## Satu varian untuk seluruh tembok satu rumah. Hash buatan sendiri (FNV-1a 32 bit atas byte UTF-8 id, konstanta di `Config.HASH_FNV1A_*`),
## bukan `String.hash()` (nilainya boleh berubah antar versi Godot) dan bukan RNG: id rumah sama = varian sama, di tiap jalan dan tiap mesin.
## Urutan nama varian tetap di `Config.RUTE_TEMBOK_VARIAN` (`polos`, `bata`, `besi`, `pot`).


## FNV-1a 32 bit atas byte UTF-8 `teks` (0 sampai 2^32 - 1). Teks kosong = nilai awal.
static func fnv1a_32(teks: String) -> int:
	var nilai: int = Config.HASH_FNV1A_AWAL
	for b: int in teks.to_utf8_buffer():
		nilai = ((nilai ^ b) * Config.HASH_FNV1A_KALI) & Config.HASH_FNV1A_MASKER
	return nilai


## Indeks varian (0 sampai jumlah varian - 1) untuk rumah berid `id_rumah`.
static func indeks(id_rumah: String) -> int:
	return fnv1a_32(id_rumah) % Config.RUTE_TEMBOK_VARIAN.size()


## Nama varian (`polos`, `bata`, `besi`, `pot`) untuk rumah berid `id_rumah` (`<id_segmen>@<pos>`).
static func pilih(id_rumah: String) -> String:
	return Config.RUTE_TEMBOK_VARIAN[indeks(id_rumah)]
