class_name SeedHari
extends RefCounted
## Seed harian, logika murni (AC-15 run fase4a-koran-hari, rule `gdscript`: semua acak gameplay berseed dari hari). Hari yang sama selalu
## menghasilkan seed yang sama, hari berbeda seed berbeda: seed = dasar + hari x `SEED_HARI_LANGKAH`. Rute memakai `SEED_RUTE_DASAR`,
## halaman koran memakai `SEED_HEADLINE_DASAR`, jadi keduanya tidak berbagi aliran acak. Tanpa node, `Time`, atau `randi()`. Usulan.


## Seed dari seed dasar `dasar` dan hari `hari`.
static func campur(dasar: int, hari: int) -> int:
	return dasar + hari * Config.SEED_HARI_LANGKAH


## Seed rute hari `hari` (diberikan ke `RouteBuilder.bangun`).
static func rute(hari: int) -> int:
	return campur(Config.SEED_RUTE_DASAR, hari)


## Seed halaman koran hari `hari` (dasar bawaan `HeadlineManager`).
static func headline(hari: int) -> int:
	return campur(Config.SEED_HEADLINE_DASAR, hari)


## Seed misi hari `hari` (rencana kucing, `RencanaMisi`): seed rute hari itu ditambah `SEED_MISI_SELISIH`, jadi aliran acaknya sendiri dan tidak
## mengubah rute (run fase4b-misi-kucing, M-1). Rute yang dijalankan sendiri (tanpa hari) memakai `Rute.benih + SEED_MISI_SELISIH`, rumus yang sama.
static func misi(hari: int) -> int:
	return rute(hari) + Config.SEED_MISI_SELISIH
