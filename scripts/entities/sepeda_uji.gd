class_name SepedaUji
extends Node2D
## Pengendali sepeda uji (placeholder Fase 0): menghubungkan `BikeDrive` ke `LoperSprite` (AC-8, AC-10, AC-11).
##
## Node hanya menyimpan keadaan gerak dan menampilkannya: seluruh perhitungan ada di `BikeDrive` (logika
## murni). Keadaan: kecepatan maju (u/d), posisi lateral (ubin dari garis tengah jalan, positif = sisi
## `dekat`), dan jarak yang sudah ditempuh sepanjang jalan (ubin). Posisi dunia = (lateral, -jarak) lalu
## diproyeksikan oleh `Iso` dan dibulatkan ke piksel; origin node = titik pijak sprite (Y-sort benar).
## Tingkat sprite dari komponen atas stick (stick bawah = melambat), arah sprite dari gerak sebenarnya (D-4). Lempar koran hanya
## animasi (`lempar`). Stamina, rem, dan penguncian sisi bukan lingkup run ini (Fase 1).

## Kecepatan maju saat ini, u/d.
var kecepatan_ud: float = Config.KECEPATAN_SANTAI_UD
## Posisi lateral, ubin dari garis tengah jalan.
var lateral_ubin: float = 0.0
## Jarak yang sudah ditempuh sepanjang jalan, ubin.
var jarak_ubin: float = 0.0

@onready var _sprite: LoperSprite = %LoperAgen


func _ready() -> void:
	position = Iso.posisi_gambar(posisi_dunia())


## Posisi dunia sepeda dalam ubin (x = lateral, y = -jarak maju, D-6).
func posisi_dunia() -> Vector2:
	return Vector2(lateral_ubin, -jarak_ubin)


## Satu langkah gerak dari vektor stick (x: datar, y: atas) selama `dt` detik, lalu memperbarui sprite dan posisi.
func gerak(stick: Vector2, dt: float) -> void:
	var hasil: BikeDrive.Hasil = BikeDrive.langkah(kecepatan_ud, lateral_ubin, stick, dt)
	kecepatan_ud = hasil.kecepatan_ud
	lateral_ubin = hasil.lateral_ubin
	jarak_ubin += hasil.maju_ubin
	_sprite.speed_level = hasil.tingkat_sprite
	_sprite.steer = hasil.arah_sprite
	position = Iso.posisi_gambar(posisi_dunia())


## Animasi yang sedang dipilih sprite (untuk tes dan HUD uji).
func nama_animasi() -> StringName:
	return _sprite.animation


## Melempar koran ke `sisi`: hanya animasi pemain (D-3), tanpa proyektil, skor, atau sasaran (Fase 2). Gerak sepeda tidak terganggu.
## True bila animasi dimulai; false bila sisi kosong atau pemain masih melempar (swipe berikutnya diabaikan).
func lempar(sisi: LoperAnim.Sisi) -> bool:
	return _sprite.lempar(sisi)


## True selama animasi lempar berjalan.
func sedang_melempar() -> bool:
	return _sprite.sedang_melempar()


## Menutup lempar yang sedang berjalan tanpa sinyal (app di-background atau kehilangan fokus).
func batalkan_lempar() -> void:
	_sprite.batalkan_lempar()
