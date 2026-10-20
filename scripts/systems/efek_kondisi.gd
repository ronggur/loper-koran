class_name EfekKondisi
extends RefCounted
## Pengali efek kondisi sepeda terhadap gerak, satu objek yang dibaca `BikeMotion.langkah` (run fase6a1-bengkel-kondisi, M-6, AC-9; usulan).
## Bawaan = identitas: semua pengali 1,0 dan batas puncak = kecepatan ngebut, jadi langkah dengan `EfekKondisi.new()` (atau tanpa efek) menghasilkan
## keluaran identik bit-demi-bit dengan gerak lama. `BikeMotion` tidak memuat angka pengali sendiri; semua nilai datang dari sini (dibuat
## `BikeCondition.efek` dari kondisi komponen dan upgrade, angka di `Config`). Kerusakan hanya menghambat (pengali <= 1,0); upgrade boleh menaikkan perlambatan rem
## dan kecepatan lateral di atas 1,0 tetapi tidak pernah kecepatan puncak (tanpa power creep, M-10).

## Pengali akselerasi (rantai rusak < 1,0).
var pengali_akselerasi: float = 1.0
## Pengali kecepatan tujuan dari stick (ban bocor < 1,0).
var pengali_kecepatan: float = 1.0
## Batas atas kecepatan tujuan, u/d (rantai putus menurunkannya, tidak di bawah kecepatan santai).
var batas_puncak_ud: float = Config.KECEPATAN_NGEBUT_UD
## Pengali perlambatan rem (rem blong < 1,0: jarak berhenti makin panjang; upgrade rem pakem > 1,0).
var pengali_rem: float = 1.0
## Pengali kecepatan lateral (ban bocor < 1,0; upgrade anti-selip > 1,0).
var pengali_lateral: float = 1.0
## Pengali laju stamina yang menguras (upgrade rantai hemat < 1,0). Laju pulih tidak berubah.
var pengali_kuras_stamina: float = 1.0


## True bila semua pengali identitas (gerak tidak berubah).
func identitas() -> bool:
	return pengali_akselerasi == 1.0 and pengali_kecepatan == 1.0 and batas_puncak_ud == Config.KECEPATAN_NGEBUT_UD and pengali_rem == 1.0 and pengali_lateral == 1.0 and pengali_kuras_stamina == 1.0
