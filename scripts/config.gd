class_name Config
extends RefCounted
## Satu-satunya tempat angka tuning global (BALANCING 1, rule `balancing`).
##
## Format wajib: SATU baris per konstanta, `const NAMA: Tipe = nilai`, nilai
## literal (angka, true/false, teks, array literal), tanpa ekspresi dan tanpa
## rujukan ke konstanta lain. `ConfigParser` memeriksa aturan ini dan dites di
## `tests/run_tests.gd`. Satuan ada di nama: PX = piksel game, UD = ubin per
## detik, UD2 = ubin per detik kuadrat, DETIK, DERAJAT. 1 ubin = 32 unit dunia.
## Semua angka di bawah adalah usulan awal untuk prototype (BALANCING 2) kecuali
## yang ditandai dikunci (layar, ROADMAP 4b). Ubah di sini, lalu perbarui BALANCING.md.

## --- Layar (dikunci 2026-10-09, ROADMAP 4b, ART_DIRECTION 7) ---

## Lebar dasar viewport dalam piksel game (16:9). HP lebih lebar menampilkan sampai 800.
const LAYAR_LEBAR_DASAR_PX: int = 640
## Tinggi dasar viewport dalam piksel game. Selalu 360, lebar mengikuti rasio layar.
const LAYAR_TINGGI_DASAR_PX: int = 360
## Skala piksel target di HP 1080p (sprite pemain didesain untuk x3).
const LAYAR_SKALA_PIKSEL: int = 3

## --- Ubin (usulan, dikunci setelah graybox Fase 1, ART_DIRECTION 11) ---

## Lebar belah ketupat satu ubin, piksel game.
const UBIN_LEBAR_PX: int = 64
## Tinggi belah ketupat satu ubin, piksel game (isometrik 2:1).
const UBIN_TINGGI_PX: int = 32
## Satu ubin sama dengan sekian unit dunia (BALANCING 1).
const UBIN_UNIT_DUNIA: int = 32

## --- Kecepatan dan kontrol (BALANCING 2) ---

## Kecepatan santai (stick netral), ubin per detik.
const KECEPATAN_SANTAI_UD: float = 3.0
## Kecepatan cepat, ubin per detik.
const KECEPATAN_CEPAT_UD: float = 4.5
## Kecepatan ngebut (stick penuh ke atas), ubin per detik.
const KECEPATAN_NGEBUT_UD: float = 6.0
## Kecepatan tujuan saat melambat (stick bawah), ubin per detik.
const KECEPATAN_MELAMBAT_UD: float = 1.5
## Akselerasi, ubin per detik kuadrat.
const AKSELERASI_UD2: float = 3.0
## Perlambatan saat melambat, ubin per detik kuadrat.
const PERLAMBATAN_MELAMBAT_UD2: float = 2.0
## Perlambatan rem sampai berhenti, ubin per detik kuadrat.
const REM_PERLAMBATAN_UD2: float = 5.0
## Rem aktif bila stick di ujung bawah melewati ambang ini (0 sampai 1, 0,90 = 90%).
const REM_AMBANG_STICK: float = 0.90
## Lama stick ditahan di ujung bawah sebelum rem aktif, detik.
const REM_TAHAN_DETIK: float = 0.25
## Zona mati stick sebagai pecahan jangkauan (0,15 = 15%).
const ZONA_MATI_STICK: float = 0.15
## Kecepatan pindah sisi (lateral), ubin per detik.
const KECEPATAN_LATERAL_UD: float = 3.0

## --- Pemilih animasi sprite pemain (BALANCING 2, ART_DIRECTION 3.2) ---

## Kekuatan stick (0 sampai 1) mulai tingkat cepat, inklusif. Di bawahnya santai.
const SPRITE_AMBANG_CEPAT: float = 0.33
## Kekuatan stick (0 sampai 1) paling tinggi untuk tingkat cepat, inklusif. Di atasnya ngebut.
const SPRITE_AMBANG_NGEBUT: float = 0.80
## Sudut gerak terhadap arah jalan mulai arah serong, inklusif, derajat. Di bawahnya normal.
const SPRITE_SUDUT_SERONG_DERAJAT: float = 22.5
## Sudut gerak terhadap arah jalan paling besar untuk arah serong, inklusif, derajat. Di atasnya 90 derajat.
const SPRITE_SUDUT_SIKU_DERAJAT: float = 67.5
## Toleransi pembulatan desimal saat membandingkan sudut dengan batasnya, derajat.
const SPRITE_SUDUT_TOLERANSI_DERAJAT: float = 0.000001
