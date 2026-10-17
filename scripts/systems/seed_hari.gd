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
