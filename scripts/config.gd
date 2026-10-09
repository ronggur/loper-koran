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

## --- Kontrol sentuh (DESIGN_SPEC 3.7, GDD 5.2; usulan, dinilai lewat uji HP) ---
## Zona diukur dari tepi layar sisi stick (kiri bila tangan kanan, bawaan; opsi kidal mencerminkannya).

## Zona stick: jarak terdekat dari tepi layar sisi stick, piksel game.
const ZONA_STICK_X_MIN_PX: int = 8
## Zona stick: jarak terjauh dari tepi layar sisi stick, piksel game.
const ZONA_STICK_X_MAKS_PX: int = 192
## Zona stick: batas atas, diukur dari atas layar (tidak ikut dicerminkan), piksel game.
const ZONA_STICK_Y_MIN_PX: int = 186
## Zona stick: batas bawah, diukur dari atas layar, piksel game.
const ZONA_STICK_Y_MAKS_PX: int = 352
## Zona swipe: tepi dalam (dekat stick), diukur dari tepi layar sisi stick, piksel game.
const ZONA_SWIPE_X_MIN_PX: int = 210
## Zona swipe: jarak tepi luar dari tepi layar sisi swipe, piksel game.
const ZONA_SWIPE_TEPI_PX: int = 20
## Zona swipe: batas atas, diukur dari atas layar, piksel game. Di atasnya strip HUD yang bebas dari kontrol.
const ZONA_SWIPE_Y_MIN_PX: int = 48
## Zona swipe: batas bawah, diukur dari atas layar, piksel game.
const ZONA_SWIPE_Y_MAKS_PX: int = 352
## Jangkauan penuh stick (radius cincin), piksel game. Zona mati stick ada di `ZONA_MATI_STICK`.
const STICK_RADIUS_PX: float = 35.0
## Radius knob stick, piksel game.
const STICK_KNOB_RADIUS_PX: int = 15
## Tebal garis cincin stick, piksel game.
const STICK_CINCIN_TEBAL_PX: int = 2
## Alpha isi cincin stick (warna TEXT, 14%).
const STICK_ISI_ALPHA: float = 0.14
## Alpha garis cincin stick (warna TEXT, 70%).
const STICK_GARIS_ALPHA: float = 0.70
## Ukuran satu titik garis swipe, piksel game.
const SWIPE_TITIK_UKURAN_PX: int = 2
## Jarak antar titik garis swipe (dari titik ke titik), piksel game.
const SWIPE_TITIK_JARAK_PX: int = 4

## --- Jalan uji dan kamera (placeholder Fase 0, dikunci ulang di Fase 1) ---

## Lebar viewport terbesar yang didukung (20:9), piksel game. Menentukan luas ubin yang disiapkan.
const LAYAR_LEBAR_MAKS_PX: int = 800
## Lebar aspal jalan uji, ubin (BALANCING 2). Batas geser sepeda = setengahnya ke tiap sisi.
const JALAN_LEBAR_UBIN: float = 2.0
## Lebar trotoar di tiap sisi aspal, ubin. Selebihnya rumput.
const JALAN_TROTOAR_UBIN: float = 1.0
## Letak sepeda pada sumbu datar layar sebagai pecahan lebar viewport (sepertiga kiri, ART_DIRECTION 2.2).
const KAMERA_SEPEDA_X_PECAHAN: float = 0.3333
## Letak sepeda pada sumbu tegak layar sebagai pecahan tinggi viewport.
const KAMERA_SEPEDA_Y_PECAHAN: float = 0.6
## Jarak antar rumah graybox di sisi seberang, ubin (3 ubin rumah + 1 ubin celah).
const JALAN_UJI_RUMAH_PERIODE_UBIN: int = 4
## Letak titik pijak rumah graybox melintang jalan, ubin dari garis tengah jalan (negatif = sisi seberang).
const JALAN_UJI_RUMAH_X_UBIN: float = -2.0
## Geseran titik pijak rumah graybox sepanjang jalan, ubin.
const JALAN_UJI_RUMAH_MAJU_UBIN: float = -0.5
## Letak kotak surat graybox melintang jalan, ubin dari garis tengah jalan.
const JALAN_UJI_KOTAK_SURAT_X_UBIN: float = -1.5
## Geseran kotak surat graybox sepanjang jalan, ubin.
const JALAN_UJI_KOTAK_SURAT_MAJU_UBIN: float = 1.0
## Batas atas langkah waktu per frame, detik. Mencegah lompatan jauh setelah app kembali dari background.
const LANGKAH_WAKTU_MAKS_DETIK: float = 0.1
## Pembagi konversi milidetik ke detik.
const WAKTU_MS_PER_DETIK: float = 1000.0

## --- HUD sementara (DESIGN_SPEC 1.3, 3.5, 3.7) ---

## Tinggi strip atas HUD yang bebas dari zona kontrol, piksel game. Sama dengan `ZONA_SWIPE_Y_MIN_PX`.
const HUD_STRIP_ATAS_TINGGI_PX: int = 48
## Jarak panel HUD dari tepi layar, piksel game.
const HUD_MARGIN_TEPI_PX: int = 8
## Jarak panel kecepatan dari tepi layar sisi stick, piksel game (DESIGN_SPEC 3.5: x 210).
const HUD_PANEL_KECEPATAN_GESER_PX: int = 210
## Lebar panel kecepatan, piksel game (DESIGN_SPEC 3.5).
const HUD_PANEL_KECEPATAN_LEBAR_PX: int = 170
## Isi panel HUD: jarak ke tepi atas dan bawah, piksel game (DESIGN_SPEC 1.3).
const HUD_PANEL_PAD_Y_PX: int = 5
## Isi panel HUD: jarak ke tepi kiri dan kanan, piksel game (DESIGN_SPEC 1.3).
const HUD_PANEL_PAD_X_PX: int = 7
## Tinggi bar kecepatan termasuk garis luar 1 px, piksel game (DESIGN_SPEC 1.3).
const HUD_BAR_TINGGI_PX: int = 7
## Tinggi tombol di strip atas, piksel game (sekitar 44 dp di A54, rule `ui-scenes`).
const HUD_TOMBOL_TINGGI_PX: int = 36
## Lebar minimum tombol di strip atas, piksel game.
const HUD_TOMBOL_LEBAR_PX: int = 96
## Jarak tombol strip atas dari tepi atas layar, piksel game. Tombol berakhir di bawah `HUD_STRIP_ATAS_TINGGI_PX`.
const HUD_TOMBOL_MARGIN_ATAS_PX: int = 4
## Objek berkala di sisi seberang: berapa ubin di belakang sepeda yang masih disiapkan.
const JALAN_UJI_DAUR_MUNDUR_UBIN: int = 12
## Objek berkala di sisi seberang: berapa ubin di depan sepeda yang sudah disiapkan.
const JALAN_UJI_DAUR_MAJU_UBIN: int = 16
