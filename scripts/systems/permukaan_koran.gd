class_name PermukaanKoran
extends RefCounted
## Permukaan tempat koran mendarat (run fase5a D-3c, ART_DIRECTION 6.2): menentukan sprite koran yang tergeletak, logika murni.
##
## Hanya tampilan: penilaian tetap `ZonaSasaran` dan `SkorRute`. Aturan (urut):
## - zona kotak surat rumah pelanggan sisi `seberang` (kotak surat sasaran memang digambar) = `KOTAK_SURAT`: sprite bertumpu di atas kotak surat, pijak = kaki kotak surat, bukan titik jatuh;
## - zona halaman = `RUMPUT`;
## - zona teras, jendela, dan kotak surat yang kotaknya tidak digambar (rumah bukan pelanggan, sisi `dekat`, jalan uji) = `TERAS` di titik mendarat;
## - tanpa zona: `RUMPUT` bila kolom ubin di titik mendarat rumput, selain itu `TERAS` (lantai keras: aspal dan trotoar).

enum Permukaan { KOTAK_SURAT, TERAS, RUMPUT }


## Permukaan untuk koran yang mendarat. `ada_zona` false = tanpa zona (meleset); `jenis` diabaikan bila tanpa zona. `pelanggan_seberang` true bila zona itu rumah pelanggan sisi `seberang`
## (kotak surat sasaran digambar di sana). `kolom` = kolom ubin di titik mendarat (`JalanDaur.kolom_di`).
static func pilih(ada_zona: bool, jenis: ZonaSasaran.Jenis, pelanggan_seberang: bool, kolom: JalanDaur.Kolom) -> Permukaan:
	if not ada_zona:
		if kolom == JalanDaur.Kolom.RUMPUT_SEBERANG or kolom == JalanDaur.Kolom.RUMPUT_DEKAT:
			return Permukaan.RUMPUT
		return Permukaan.TERAS
	match jenis:
		ZonaSasaran.Jenis.KOTAK_SURAT:
			return Permukaan.KOTAK_SURAT if pelanggan_seberang else Permukaan.TERAS
		ZonaSasaran.Jenis.HALAMAN:
			return Permukaan.RUMPUT
	return Permukaan.TERAS


## Permukaan untuk zona `zona` (null = meleset) dan kolom ubin `kolom` di titik mendarat.
static func dari_zona(zona: ZonaSasaran.Zona, kolom: JalanDaur.Kolom) -> Permukaan:
	if zona == null:
		return pilih(false, ZonaSasaran.Jenis.HALAMAN, false, kolom)
	return pilih(true, zona.jenis, zona.pelanggan and zona.sisi == LoperAnim.Sisi.SEBERANG, kolom)


## Nama sprite koran tergeletak untuk `permukaan`.
static func nama_sprite(permukaan: Permukaan) -> String:
	match permukaan:
		Permukaan.KOTAK_SURAT:
			return "prop_koran_kotak_surat"
		Permukaan.RUMPUT:
			return "prop_koran_rumput"
	return "prop_koran_teras"


## Titik dunia (ubin) tempat titik pijak sprite koran tergeletak diletakkan: kaki kotak surat sasaran untuk `KOTAK_SURAT` (dari `zona`, zona kotak surat rumah itu; sama dengan
## `SpriteRumah.titik_kotak_surat_dunia`), selain itu `titik_mendarat`. `zona` null untuk `KOTAK_SURAT` = titik mendarat.
static func titik_diam(permukaan: Permukaan, zona: ZonaSasaran.Zona, titik_mendarat: Vector2) -> Vector2:
	if permukaan != Permukaan.KOTAK_SURAT or zona == null:
		return titik_mendarat
	var awal_kavling: float = zona.persegi.position.y - Config.JALAN_UJI_SEBERANG_KOTAK_SURAT_UBIN[1]
	return Vector2(Config.JALAN_UJI_KOTAK_SURAT_X_UBIN, -(awal_kavling + Config.JALAN_UJI_KOTAK_SURAT_MAJU_UBIN))
