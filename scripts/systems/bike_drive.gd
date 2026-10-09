class_name BikeDrive
extends RefCounted
## Satu langkah gerak sepeda dari vektor stick, logika murni dan deterministik (BALANCING 2, GDD 5.2).
##
## Tanpa node, `Time`, atau RNG: kecepatan, posisi lateral, vektor stick, dan `dt` semuanya parameter.
## Satuan: kecepatan u/d (ubin per detik), jarak dan posisi lateral dalam ubin, `dt` detik.
## Lingkup run 0B: kecepatan maju mengikuti sumbu atas/bawah stick, lateral = geser bebas dibatasi
## lebar jalan (D-3). Stamina, rem, penguncian sisi, dan tabrakan adalah Fase 1.
## Tanda lateral: positif = sisi `dekat`, negatif = sisi `seberang` (sama dengan `LoperAnim.arah_dari_gerak`).


## Hasil satu langkah gerak.
class Hasil extends RefCounted:
	## Kecepatan maju sesudah langkah, u/d.
	var kecepatan_ud: float = 0.0
	## Posisi lateral sesudah langkah, ubin dari garis tengah jalan (positif = sisi dekat).
	var lateral_ubin: float = 0.0
	## Jarak maju yang ditempuh selama langkah ini, ubin.
	var maju_ubin: float = 0.0
	## Kecepatan lateral efektif selama langkah (perpindahan nyata per detik), u/d. Nol bila terhalang tepi jalan.
	var lateral_ud: float = 0.0
	## Tingkat sprite 0..2 dari kekuatan stick ke atas (`LoperAnim.tingkat_dari_stick`, D-4).
	var tingkat_sprite: int = 0
	## Arah sprite -2..2 dari gerak sebenarnya (`LoperAnim.arah_dari_gerak`, D-4).
	var arah_sprite: int = 0


## Kecepatan tujuan (u/d) untuk komponen atas stick (-1 sampai 1, dijepit). Netral = santai,
## atas penuh = ngebut, bawah penuh = melambat; di antaranya linear (BALANCING 2).
static func kecepatan_target_ud(atas: float) -> float:
	var a: float = 0.0 if is_nan(atas) else clampf(atas, -1, 1)
	if a >= 0.0:
		return lerpf(Config.KECEPATAN_SANTAI_UD, Config.KECEPATAN_NGEBUT_UD, a)
	return lerpf(Config.KECEPATAN_SANTAI_UD, Config.KECEPATAN_MELAMBAT_UD, -a)


## Batas geser lateral ke tiap sisi dari garis tengah jalan, ubin (setengah lebar jalan).
static func batas_lateral_ubin() -> float:
	return Config.JALAN_LEBAR_UBIN / 2


## Satu langkah: kecepatan mendekati target dengan akselerasi (naik) atau perlambatan (turun) tanpa
## melewati target, lateral bergeser sesuai sumbu datar stick dan dijepit ke lebar jalan.
## `dt` yang nol, negatif, atau bukan bilangan hingga dianggap 0 (keadaan tidak berubah, kecuali
## kecepatan dijepit ke jangkauan sah). Kecepatan hasil selalu antara melambat dan ngebut.
## Batas keabsahan `maju_ubin`: jarak dihitung dengan trapesium, `(kecepatan awal + akhir) / 2 * dt`,
## yang TEPAT hanya selama `dt` tidak melebihi waktu rampa kecepatan ke target (rampa linear sepanjang
## langkah). Untuk `dt` lebih besar hasilnya hanya pendekatan: misalnya `langkah(3.0, 0.0, Vector2(0, 1), 100.0)`
## memberi 450 ubin, nilai benar 598,5 (rampa 1 detik rata-rata 4,5 u/d, lalu 6,0 u/d selama 99 detik). Fungsi ini
## dirancang untuk langkah frame: pemanggil di scene menjepit `dt` ke `Config.LANGKAH_WAKTU_MAKS_DETIK` (`JalanUji`,
## dijaga tes), dan pada batas itu galat jarak per langkah paling banyak sekitar 0,004 ubin (kurang dari 0,2 px).
static func langkah(kecepatan_ud: float, lateral_ubin: float, stick: Vector2, dt: float) -> Hasil:
	var hasil: Hasil = Hasil.new()
	var waktu: float = dt if is_finite(dt) and dt > 0.0 else 0.0
	var atas: float = _sumbu_bersih(stick.y)
	var datar: float = _sumbu_bersih(stick.x)
	var target: float = kecepatan_target_ud(atas)
	var awal: float = clampf(kecepatan_ud, Config.KECEPATAN_MELAMBAT_UD, Config.KECEPATAN_NGEBUT_UD)
	var baru: float = awal
	if awal < target:
		baru = minf(target, awal + Config.AKSELERASI_UD2 * waktu)
	elif awal > target:
		baru = maxf(target, awal - Config.PERLAMBATAN_MELAMBAT_UD2 * waktu)
	hasil.kecepatan_ud = clampf(baru, Config.KECEPATAN_MELAMBAT_UD, Config.KECEPATAN_NGEBUT_UD)
	hasil.maju_ubin = (awal + hasil.kecepatan_ud) / 2 * waktu

	var batas: float = batas_lateral_ubin()
	var lateral_awal: float = clampf(lateral_ubin, -batas, batas)
	hasil.lateral_ubin = clampf(lateral_awal + datar * Config.KECEPATAN_LATERAL_UD * waktu, -batas, batas)
	if waktu > 0.0:
		hasil.lateral_ud = (hasil.lateral_ubin - lateral_awal) / waktu

	hasil.tingkat_sprite = LoperAnim.tingkat_dari_stick(atas)
	hasil.arah_sprite = LoperAnim.arah_dari_gerak(hasil.kecepatan_ud, hasil.lateral_ud)
	return hasil


static func _sumbu_bersih(nilai: float) -> float:
	if is_nan(nilai):
		return 0.0
	return clampf(nilai, -1, 1)
