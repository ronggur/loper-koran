class_name Iso
extends RefCounted
## Proyeksi isometrik 2:1 antara dunia dan layar, SATU-SATUNYA tempat konversi (ART_DIRECTION 2.2, rule `gdscript`).
##
## Posisi dunia dalam satuan ubin pada bidang datar (D-6 di SPEC run 0B+0C):
## - sumbu x dunia = melintang jalan, positif ke sisi `dekat` (turun ke kanan di layar);
## - sumbu y dunia = sepanjang jalan, MAJU adalah arah -y (naik ke kanan atas di layar).
## Satu ubin di sumbu x menggeser layar (+32, +16) px, di sumbu y (-32, +16) px, jadi maju satu
## ubin = (+32, -16) px: kemiringan tepat 1:2. Ukuran ubin dibaca dari `Config.UBIN_*`.
## Konversi ke piksel hanya dilakukan di sini; logika gerak tidak memakai koordinat layar.

## Arah maju sepanjang jalan di koordinat dunia (naik ke kanan atas di layar).
const ARAH_MAJU: Vector2 = Vector2(0, -1)
## Arah melintang jalan menuju sisi `dekat` (turun ke kanan di layar).
const ARAH_DEKAT: Vector2 = Vector2(1, 0)
## Arah melintang jalan menuju sisi `seberang` (naik ke kiri di layar).
const ARAH_SEBERANG: Vector2 = Vector2(-1, 0)


## Posisi dunia (ubin) ke posisi layar (piksel game, float).
static func dunia_ke_layar(dunia: Vector2) -> Vector2:
	var setengah_lebar: float = float(Config.UBIN_LEBAR_PX) / 2
	var setengah_tinggi: float = float(Config.UBIN_TINGGI_PX) / 2
	return Vector2((dunia.x - dunia.y) * setengah_lebar, (dunia.x + dunia.y) * setengah_tinggi)


## Posisi layar (piksel game) ke posisi dunia (ubin, float). Kebalikan persis `dunia_ke_layar`.
static func layar_ke_dunia(layar: Vector2) -> Vector2:
	var setengah_lebar: float = float(Config.UBIN_LEBAR_PX) / 2
	var setengah_tinggi: float = float(Config.UBIN_TINGGI_PX) / 2
	var selisih: float = layar.x / setengah_lebar
	var jumlah: float = layar.y / setengah_tinggi
	return Vector2((jumlah + selisih) / 2, (jumlah - selisih) / 2)


## Posisi layar untuk menggambar sprite: dibulatkan ke piksel (rule `gdscript`, pixel-perfect).
## Gerak halus tetap disimpan sebagai float di logika, hanya posisi gambar yang dibulatkan.
static func posisi_gambar(dunia: Vector2) -> Vector2:
	return dunia_ke_layar(dunia).round()
