class_name PoseKucing
extends RefCounted
## Pemilih frame sheet kucing misi (`mission_kucing_sheet`, 9 kolom pose x 4 baris arah moncong), logika murni tanpa node (run 20261022-fase5c-animasi-simpang
## AC-9, P-3, usulan; ART_DIRECTION 6.3).
##
## Kucing selalu menghadap rumah sisi seberang (baris `MISI_KUCING_BARIS_HADAP`, "masuk"). Kolom:
## - duduk (`MISI_KUCING_KOLOM_DUDUK`) bawaan, termasuk langkah `lihat` dan langkah `tangkap` sebelum ada progres;
## - ditangkap (`MISI_KUCING_KOLOM_DITANGKAP`, dua frame bergantian `MISI_KUCING_DITANGKAP_FPS` kali per detik) hanya selama langkah `tangkap` dengan progres
##   tangkap > 0 (pemain sedang menahan kucing). Frame = `floor(detik x fps) mod 2` dari waktu animasi misi pemanggil (`RuteMain._detik_misi`, hanya maju dengan
##   dt efektif), jadi jeda membekukannya. Batas inklusif dengan toleransi `MISI_TANGKAP_TOLERANSI`: tepat 1/3 detik = frame kedua.
## Selesai, gagal, dan langkah lain tidak pernah memakai kolom ditangkap (kucing langkah itu tidak digambar atau progresnya 0). Progres NaN atau tidak positif = duduk;
## waktu NaN atau negatif = 0.

## Jenis langkah misi yang memakai pose ditangkap (`RencanaMisi.Titik.jenis`).
const JENIS_TANGKAP: String = "tangkap"


## True bila kucing sedang ditahan pemain: langkah `tangkap` dengan progres > 0.
static func ditangkap(jenis: String, progres: float) -> bool:
	return jenis == JENIS_TANGKAP and is_finite(progres) and progres > 0.0


## Kolom sheet untuk langkah `jenis`, progres tangkap `progres` (0..1), dan waktu animasi misi `detik`.
static func kolom(jenis: String, progres: float, detik: float) -> int:
	if not ditangkap(jenis, progres):
		return Config.MISI_KUCING_KOLOM_DUDUK
	var t: float = detik if is_finite(detik) and detik > 0.0 else 0.0
	var indeks: int = posmod(floori(t * Config.MISI_KUCING_DITANGKAP_FPS + Config.MISI_TANGKAP_TOLERANSI), Config.MISI_KUCING_KOLOM_DITANGKAP.size())
	return Config.MISI_KUCING_KOLOM_DITANGKAP[indeks]


## Indeks frame `Sprite2D` (baris hadap x jumlah kolom + kolom) untuk dipasang ke `frame`.
static func frame(jenis: String, progres: float, detik: float) -> int:
	return Config.MISI_KUCING_BARIS_HADAP * Config.MISI_KUCING_KOLOM + kolom(jenis, progres, detik)
