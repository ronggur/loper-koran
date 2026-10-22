class_name SpriteRumah
extends RefCounted
## Sprite rumah rute: nama berkas, titik pijak, dan letak gambar dari data rute, logika murni (AC-12 run fase3a-rute, usulan).
##
## Aset dari PR #27 (`tools/env_art/fase3.py`, `assets/sprites/houses/perumahan/`), dipakai apa adanya: `house_perumahan_<jenis>_<pelanggan|bukan>`.
## Aturan varian (K-3, D-4 run 3A): rumah `seberang` yang dipilih jadi pelanggan memakai `_pelanggan`; rumah `seberang` yang tidak
## dipilih (juga yang `pelanggan_boleh`) memakai `_bukan`; rumah `dekat` selalu `_bukan` (cara menampilkan sisi dekat belum diputuskan,
## ROADMAP 5). Titik pijak (`ground_anchor` di JSON aset) = tengah tapak rumah; ditulis sebagai tabel di `Config` (`RUTE_RUMAH_SPRITE`, `RUTE_RUMAH_PIJAK_PX`) supaya entitas tidak
## membaca JSON saat jalan, dan tes membandingkan tabel dengan JSON dan ukuran PNG-nya. Rumah digambar dengan titik pijak itu di tengah
## tapak yang SAMA dengan aturan penutup (`PenutupPemain.tapak_rumah`), bukan dari `maju_ubin` langsung.

## Folder sprite rumah perumahan.
const FOLDER: String = "res://assets/sprites/houses/perumahan"
## Awalan nama sprite rumah perumahan.
const AWALAN: String = "house_perumahan_"


## Nama sprite untuk `jenis` (`limasan`, `dekat_limasan`, ...) dan status pelanggan.
static func nama(jenis: String, pelanggan: bool) -> String:
	return "%s%s_%s" % [AWALAN, jenis, "pelanggan" if pelanggan else "bukan"]


## Nama sprite untuk rumah rute: pelanggan hanya di sisi `seberang` dan hanya bila dipilih (rumah `dekat` selalu `_bukan`).
static func nama_rumah(rumah: RouteBuilder.RumahRute) -> String:
	var pelanggan: bool = rumah.pelanggan and rumah.sisi == LoperAnim.Sisi.SEBERANG
	return nama(rumah.jenis, pelanggan)


## Jalur PNG sprite bernama `nama_sprite`.
static func jalur_png(nama_sprite: String) -> String:
	return "%s/%s.png" % [FOLDER, nama_sprite]


## Titik pijak sprite bernama `nama_sprite`; `(-1, -1)` bila tidak dikenal.
static func titik_pijak(nama_sprite: String) -> Vector2i:
	var indeks: int = Config.RUTE_RUMAH_SPRITE.find(nama_sprite)
	if indeks < 0:
		return Vector2i(-1, -1)
	return Vector2i(Config.RUTE_RUMAH_PIJAK_PX[indeks * 2], Config.RUTE_RUMAH_PIJAK_PX[indeks * 2 + 1])


## Titik tengah tapak rumah di dunia (ubin; y dunia = -maju): tapak `PenutupPemain.tapak_rumah`.
static func pusat_tapak_dunia(rumah: RouteBuilder.RumahRute) -> Vector2:
	var pusat: Vector2 = PenutupPemain.tapak_rumah(rumah.sisi, rumah.maju_ubin).get_center()
	return Vector2(pusat.x, -pusat.y)


## Titik pijak GAMBAR sprite rumah di dunia (ubin; y dunia = -maju): `pusat_tapak_dunia`, kecuali rumah sisi `dekat` digeser `RUTE_RUMAH_DEKAT_MUNDUR_UBIN`
## (0,5; run fase5d-sisi-dekat, keputusan pemilik 2026-10-22, halaman terbuka tanpa tembok) menjauh dari jalan. Tapak logika (zona, validasi) tidak ikut bergeser.
static func pusat_gambar_dunia(rumah: RouteBuilder.RumahRute) -> Vector2:
	var pusat: Vector2 = pusat_tapak_dunia(rumah)
	if rumah.sisi == LoperAnim.Sisi.DEKAT:
		pusat.x += Config.RUTE_RUMAH_DEKAT_MUNDUR_UBIN
	return pusat


## Titik pijak gambar kotak surat sasaran rumah pelanggan di dunia (ubin; y dunia = -maju): sama dengan kotak surat jalan uji
## (`JALAN_UJI_KOTAK_SURAT_*`, di tengah zona kotak surat), digeser ke awal kavling rumah.
static func titik_kotak_surat_dunia(rumah: RouteBuilder.RumahRute) -> Vector2:
	return Vector2(Config.JALAN_UJI_KOTAK_SURAT_X_UBIN, -(rumah.maju_ubin + Config.JALAN_UJI_KOTAK_SURAT_MAJU_UBIN))


## Titik tengah zona teras rumah di dunia (ubin; y dunia = -maju): tempat koran terlipat rumah yang sudah terantar (run fase5a bagian B, D-3d). Tanpa zona teras (sisi `TIDAK_ADA`) = pusat tapak.
static func titik_teras_dunia(rumah: RouteBuilder.RumahRute) -> Vector2:
	for zona: ZonaSasaran.Zona in ZonaSasaran.zona_rumah(rumah):
		if zona.jenis == ZonaSasaran.Jenis.TERAS:
			var pusat: Vector2 = zona.persegi.get_center()
			return Vector2(pusat.x, -pusat.y)
	return pusat_tapak_dunia(rumah)
