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

## --- Ubin (dikunci 2026-10-14 setelah graybox Fase 1, ROADMAP 4b) ---

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
## Kecepatan pindah sisi (lateral), ubin per detik. Posisi lateral analog bebas, tanpa kunci jalur (keputusan pemilik 2026-10-13).
const KECEPATAN_LATERAL_UD: float = 3.0
## Lebar aspal, ubin (BALANCING 2). Batas tepi jalan resmi = setengahnya ke tiap sisi dari garis tengah (`BikeMotion`).
const JALAN_LEBAR_UBIN: float = 2.0
## Toleransi presisi tunggal saat membandingkan komponen bawah stick dengan `REM_AMBANG_STICK` (Vector2 berpresisi tunggal: 0,90 tersimpan 0,8999999762).
const REM_AMBANG_TOLERANSI: float = 0.000001
## Toleransi derau float saat membandingkan lama tahan rem dengan `REM_TAHAN_DETIK`, detik (jumlah 15 x 1/60 tidak tepat 0,25).
const REM_TAHAN_TOLERANSI_DETIK: float = 0.000001

## --- Stamina (BALANCING 3, GDD 6; usulan) ---
## Laju per detik dari kecepatan SEBENARNYA, linear per potong di antara tiga titik (santai, cepat, ngebut); di bawah santai
## sama dengan santai, di atas ngebut sama dengan ngebut. Stick ke bawah atau rem aktif memakai laju meluncur.

## Stamina maksimum (dan stamina awal).
const STAMINA_MAKS: float = 100.0
## Laju pulih saat stick ke bawah (meluncur atau melambat) atau rem aktif, per detik.
const STAMINA_LAJU_MELUNCUR: float = 15.0
## Laju di kecepatan santai (3,0 u/d) dan di bawahnya, per detik (pulih pelan).
const STAMINA_LAJU_SANTAI: float = 2.0
## Laju di kecepatan cepat (4,5 u/d), per detik (negatif = terkuras).
const STAMINA_LAJU_CEPAT: float = -4.0
## Laju di kecepatan ngebut (6,0 u/d), per detik.
const STAMINA_LAJU_NGEBUT: float = -12.0
## Stamina habis menyalakan lelah (kecepatan tujuan dijepit ke cepat); lelah padam saat stamina kembali sebesar ini atau lebih.
const STAMINA_PULIH_AMBANG: float = 30.0

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
## Pose meluncur (kaki diam) dipakai selama stick ke bawah dan kecepatan sebenarnya masih di atas kecepatan tujuan lebih dari ini, u/d.
## Selisih sekecil ini dianggap sudah sampai (melambat, kayuh 4 fps), supaya stick yang hanya bergetar tidak membuat pose berkedip.
const POSE_MELUNCUR_TOLERANSI_UD: float = 0.05
## Batas atas pengali laju kayuh (`pedal_rate` = kecepatan sebenarnya / kecepatan nominal tingkat animasi).
const PEDAL_RATE_MAKS: float = 1.5

## --- Lempar koran dan melambat (animasi pemain, usulan, run sprite-lempar-melambat) ---
## fps animasi (kayuh 8/10/12, melambat 4, lempar 12) dibaca dari `loper_agen_frames.tres`, bukan dari sini.
## Ambang swipe 12 px (run sprite-lempar-melambat) diganti `LEMPAR_SWIPE_MIN_PECAHAN` di bawah (run fase2a-lemparan, D-2).

## Indeks frame saat koran lepas dari tangan (`release_frame` di loper_agen_lempar.json, README lempar).
const LEMPAR_FRAME_LEPAS: int = 2
## Toleransi derau float saat menentukan frame animasi dari waktu, detik (mencegah frame bergeser satu langkah di batas).
const LEMPAR_TOLERANSI_DETIK: float = 0.000001

## --- Lemparan koran (BALANCING 4, GDD 5.1-5.2; usulan run fase2a-lemparan, dinilai lewat uji HP, jangan dikunci) ---
## `ThrowSolver` satu-satunya pemakai angka lintasan. Panjang swipe = komponen MENDATAR |dx| (piksel game) terhadap lebar viewport
## game saat itu; u = jepit((|dx| - min) / (maks - min), 0, 1). Jarak ke samping, lama terbang, dan tinggi puncak linear dari u.
## Koran mewarisi kecepatan maju sepeda; tidak ada warisan lateral selama terbang. Tinggi dalam ubin (1 ubin = 32 px tegak, `Iso`).

## Swipe terpendek yang masih melempar, pecahan lebar viewport game, inklusif (6%). Di bawahnya tidak melempar: tanpa garis bidik, koran tidak terpakai.
const LEMPAR_SWIPE_MIN_PECAHAN: float = 0.06
## Swipe terpanjang yang masih dihitung, pecahan lebar viewport game (35%). Lebih panjang dijepit ke lemparan terjauh.
const LEMPAR_SWIPE_MAKS_PECAHAN: float = 0.35
## Toleransi saat membandingkan |dx| dengan swipe minimum, piksel game (posisi sentuh berpresisi tunggal: 46,8 tersimpan 46,7999992).
const LEMPAR_SWIPE_TOLERANSI_PX: float = 0.001
## Jarak mendarat ke samping dari titik lepas pada swipe minimum (u = 0), ubin.
const LEMPAR_JARAK_MIN_UBIN: float = 1.5
## Jarak mendarat ke samping dari titik lepas pada swipe maksimum (u = 1), ubin.
const LEMPAR_JARAK_MAKS_UBIN: float = 5.0
## Lama terbang pada swipe minimum, detik.
const LEMPAR_TERBANG_MIN_DETIK: float = 0.45
## Lama terbang pada swipe maksimum, detik.
const LEMPAR_TERBANG_MAKS_DETIK: float = 0.75
## Tinggi puncak lengkung pada swipe minimum, ubin di atas tanah.
const LEMPAR_PUNCAK_MIN_UBIN: float = 1.0
## Tinggi puncak lengkung pada swipe maksimum, ubin di atas tanah.
const LEMPAR_PUNCAK_MAKS_UBIN: float = 1.6
## Bagian kecepatan maju sepeda yang diwarisi koran selama terbang (1,0 = 100%, GDD 5.1): ngebut = mendarat lebih jauh ke depan.
const LEMPAR_WARISAN_MAJU: float = 1.0
## Tinggi tangan saat koran lepas, ubin di atas tanah (0,7 = sekitar 22 px, setinggi setang pada sel 46x58). Lengkung mulai di sini.
const LEMPAR_TINGGI_TANGAN_UBIN: float = 0.7
## Jeda antar lemparan, detik: dari lemparan diterima (jari dilepas) sampai lemparan berikutnya boleh diterima, inklusif (toleransi `LEMPAR_TOLERANSI_DETIK`).
const LEMPAR_JEDA_DETIK: float = 0.35
## Koran di awal jalan uji (25 pelanggan + 20%, BALANCING 4). Tiap lemparan yang diterima mengurangi tepat 1.
const KORAN_AWAL: int = 30
## Lama penanda kena/meleset di titik mendarat, detik (DESIGN_SPEC 3.6).
const PENANDA_LAMA_DETIK: float = 0.8
## Sakelar jendela kena koran (BALANCING 5, ROADMAP 5, KEPUTUSAN TERBUKA sampai skor Fase 3): false = penalti ringan (bawaan pemilik
## 2026-10-14: antaran tidak sah seperti meleset, tanpa potong koin), true = bonus (antaran sah, ditandai bonus).
const JENDELA_KENA_BONUS: bool = false

## --- Koran terbang, garis bidik, penanda, dan zona (placeholder dari kode, usulan run fase2a-lemparan bagian 1b) ---
## Digambar per piksel game (persegi bulat) supaya tajam di skala bulat; warna hanya dari `Palette` (DESIGN_SPEC 3.6, 3.7,
## ART_DIRECTION 6.2). Bukan angka lintasan: lintasan tetap hanya dari `ThrowSolver`.

## Koran gulung berputar 4 langkah (4 frame pola) selama terbang, frame per detik (sama dengan animasi lempar 12 fps).
const KORAN_PUTAR_FPS: float = 12.0
## Bayangan koran: lebar elips saat koran di tanah, piksel game (tinggi elips setengahnya).
const KORAN_BAYANGAN_LEBAR_MAKS_PX: int = 8
## Bayangan koran: lebar elips terkecil (koran paling tinggi), piksel game.
const KORAN_BAYANGAN_LEBAR_MIN_PX: int = 4
## Bayangan koran mengecil sekian piksel game per ubin tinggi koran.
const KORAN_BAYANGAN_SUSUT_PX_PER_UBIN: float = 2.0
## Alpha bayangan koran (warna `OUTLINE`).
const KORAN_BAYANGAN_ALPHA: float = 0.5
## Penanda kena/meleset digambar sekian piksel game di atas titik mendarat (kaki penanda), di atas koran yang tergeletak (tinggi 6).
const PENANDA_ATAS_PX: int = 7
## Jumlah sampel `posisi_pada` sepanjang lintasan untuk menaruh titik garis bidik (titik dipilih dari sampel ini tiap `SWIPE_TITIK_JARAK_PX`).
const GARIS_BIDIK_SAMPEL: int = 96
## Alpha garis tepi halaman dan isi zona placeholder di jalan uji.
const ZONA_GARIS_ALPHA: float = 0.7

## --- Umpan balik kecepatan (GDD 15; usulan run fase1b-umpan-balik, dinilai di HP) ---
## Dihitung dari kecepatan SEBENARNYA (`UmpanBalikKecepatan`). Partikel digambar sendiri (`PancaranPiksel`), kotak 1-2 px game.

## Debu roda: mulai berdebu di kecepatan ini, u/d (inklusif). Di bawahnya tanpa debu kecuali rem.
const UMPAN_DEBU_AMBANG_UD: float = 3.0
## Debu roda: kecepatan saat laju debu maksimum, u/d. Di atasnya dijepit.
const UMPAN_DEBU_PENUH_UD: float = 6.0
## Debu roda: laju pancar tepat di ambang, partikel per detik.
const UMPAN_DEBU_LAJU_MIN: float = 4.0
## Debu roda: laju pancar maksimum, partikel per detik.
const UMPAN_DEBU_LAJU_MAKS: float = 24.0
## Debu rem: laju pancar selama rem aktif dan kecepatan di atas 0, partikel per detik.
const UMPAN_DEBU_REM_LAJU: float = 40.0
## Garis kecepatan: mulai tampil di kecepatan ini, u/d (inklusif). Di bawahnya tanpa garis.
const UMPAN_GARIS_AMBANG_UD: float = 4.5
## Garis kecepatan: kekuatan penuh (1) di kecepatan ini, u/d. Di atasnya dijepit.
const UMPAN_GARIS_PENUH_UD: float = 6.0
## Garis kecepatan: kekuatan tepat di ambang (0 sampai 1); naik linear ke 1 di kecepatan penuh.
const UMPAN_GARIS_KEKUATAN_MIN: float = 0.25
## Garis kecepatan: laju pancar di kekuatan 1, garis per detik.
const UMPAN_GARIS_LAJU_MAKS: float = 14.0
## Kurangi efek (rule `ui-scenes`): mematikan garis kecepatan dan mengurangi debu. Bawaan mati; belum ada UI (Pengaturan, Fase 3).
const UMPAN_KURANGI_EFEK: bool = false
## Kurangi efek: pengali laju debu (0 sampai 1).
const UMPAN_KURANGI_DEBU_PENGALI: float = 0.5
## Batas jumlah partikel debu hidup sekaligus (anggaran TECH_PLAN 3.7).
const UMPAN_DEBU_BATAS: int = 24
## Batas jumlah garis kecepatan hidup sekaligus (anggaran TECH_PLAN 3.7).
const UMPAN_GARIS_BATAS: int = 6
## Debu: umur satu partikel, detik.
const UMPAN_DEBU_UMUR_DETIK: float = 0.4
## Debu: kecepatan partikel menjauh ke belakang sepanjang jalan, piksel game per detik.
const UMPAN_DEBU_KECEPATAN_PX: float = 40.0
## Debu: sebaran titik muncul tegak lurus jalan, plus-minus piksel game.
const UMPAN_DEBU_SEBARAN_PX: float = 2.0
## Debu: titik muncul (roda belakang) dari titik pijak sepeda, datar, piksel game (negatif = ke kiri).
const UMPAN_DEBU_ASAL_X_PX: float = -12.0
## Debu: titik muncul dari titik pijak sepeda, tegak, piksel game (positif = ke bawah).
const UMPAN_DEBU_ASAL_Y_PX: float = 2.0
## Debu: sisi kotak partikel terbesar, piksel game (acak 1 sampai nilai ini).
const UMPAN_DEBU_UKURAN_MAKS_PX: int = 2
## Debu: alpha warna `TEXT_2`.
const UMPAN_DEBU_ALPHA: float = 0.85
## Garis kecepatan: umur satu garis, detik.
const UMPAN_GARIS_UMUR_DETIK: float = 0.3
## Garis kecepatan: kecepatan garis melaju ke belakang sepanjang jalan, piksel game per detik.
const UMPAN_GARIS_KECEPATAN_PX: float = 200.0
## Garis kecepatan: titik muncul dari titik pijak sepeda, datar, piksel game (di depan pengendara).
const UMPAN_GARIS_ASAL_X_PX: float = 30.0
## Garis kecepatan: titik muncul dari titik pijak sepeda, tegak, piksel game (negatif = ke atas, setinggi badan).
const UMPAN_GARIS_ASAL_Y_PX: float = -24.0
## Garis kecepatan: sebaran titik muncul tegak lurus jalan, plus-minus piksel game.
const UMPAN_GARIS_SEBARAN_PX: float = 26.0
## Garis kecepatan: panjang garis (lebar datar), piksel game; digambar bertangga 2:1.
const UMPAN_GARIS_PANJANG_PX: int = 14
## Garis kecepatan: alpha warna `TEXT`.
const UMPAN_GARIS_ALPHA: float = 0.7

## --- Audio sepeda placeholder (SOUND_DESIGN 3.2; usulan run fase1b-umpan-balik, dinilai di HP) ---
## Pitch loop kayuhan dari kecepatan SEBENARNYA (`BunyiSepeda`), linear per potong di titik `KECEPATAN_SANTAI_UD`, `KECEPATAN_CEPAT_UD`,
## dan `KECEPATAN_NGEBUT_UD`, dijepit di luar. Bunyi dibuat `tools/audio_art/sintesis_sepeda.py` dengan puncak sama; keras-pelan di sini.

## Pitch loop kayuhan di kecepatan santai (3,0 u/d) dan di bawahnya.
const AUDIO_KAYUH_PITCH_SANTAI: float = 1.0
## Pitch loop kayuhan di kecepatan cepat (4,5 u/d).
const AUDIO_KAYUH_PITCH_CEPAT: float = 1.15
## Pitch loop kayuhan di kecepatan ngebut (6,0 u/d) dan di atasnya.
const AUDIO_KAYUH_PITCH_NGEBUT: float = 1.3
## Volume loop kayuhan, dB (kayuhan duduk di bawah suara sasaran, SOUND_DESIGN 6).
const AUDIO_KAYUH_VOLUME_DB: float = -6.0
## Volume loop freewheel saat meluncur, dB ("tik-tik-tik" pelan, SOUND_DESIGN 3.2).
const AUDIO_FREEWHEEL_VOLUME_DB: float = -10.0
## Volume decit rem sekali putar, dB.
const AUDIO_REM_VOLUME_DB: float = -3.0

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
## Lebar trotoar di tiap sisi aspal, ubin. Selebihnya rumput.
const JALAN_TROTOAR_UBIN: float = 1.0
## Letak sepeda pada sumbu datar layar sebagai pecahan lebar viewport (sepertiga kiri, ART_DIRECTION 2.2).
const KAMERA_SEPEDA_X_PECAHAN: float = 0.3333
## Letak sepeda pada sumbu tegak layar sebagai pecahan tinggi viewport. 0,75 (dulu 0,6; paket pemilik 2026-10-14): jalan di depan terlihat lebih jauh; sprite di geseran dorongan terbesar tidak menabrak panel kecepatan di 640/780/800 (tes tata letak).
const KAMERA_SEPEDA_Y_PECAHAN: float = 0.75
## Dorongan kecepatan (GDD 15, usulan, disetel di HP): sepeda bergeser di bingkai layar sejajar arah jalan (naik ke
## kanan atas, 2:1) sesuai kecepatan SEBENARNYA. Nol di `KECEPATAN_SANTAI_UD`, naik linear sampai nilai di bawah di
## `KECEPATAN_NGEBUT_UD`, turun linear ke arah sebaliknya di `KECEPATAN_MELAMBAT_UD`. Nilai = komponen datar geseran.
## Geseran maju saat ngebut, komponen datar, piksel game (komponen tegak = setengahnya ke atas). 36 (dulu 28; paket pemilik 2026-10-14, dibarengi sepeda turun ke 0,75).
const DORONGAN_MAJU_PX: float = 36.0
## Geseran mundur saat melambat, komponen datar, piksel game (komponen tegak = setengahnya ke bawah).
const DORONGAN_MUNDUR_PX: float = 20.0
## Konstanta waktu penghalusan geseran (eksponensial, bebas framerate), detik. Setelah satu konstanta sisa jarak 37%.
const DORONGAN_RESPON_DETIK: float = 0.35
## Jarak antar rumah graybox di sisi seberang, ubin (3 ubin rumah + 1 ubin celah).
const JALAN_UJI_RUMAH_PERIODE_UBIN: int = 4
## Letak titik pijak rumah graybox (kaki fasad) melintang jalan, ubin dari garis tengah jalan (negatif = sisi seberang). -3,0 (dulu -2,0;
## run fase2a-lemparan): satu ubin rumput di antara trotoar dan fasad menjadi halaman dan teras sasaran (BALANCING 5).
const JALAN_UJI_RUMAH_X_UBIN: float = -3.0
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
## Tinggi bar kecepatan dan stamina termasuk garis luar 1 px, piksel game (DESIGN_SPEC 1.3).
const HUD_BAR_TINGGI_PX: int = 7
## Bar stamina berganti warna dari `ACCENT` ke `FAIL` di bawah nilai ini (DESIGN_SPEC 3.5, usulan).
const HUD_STAMINA_AMBANG_RENDAH: float = 30.0
## Panel sisa koran: jarak dari tepi layar sisi stick, piksel game (DESIGN_SPEC 3.5: x 400). Celah ke panel kecepatan = sisa sesudah panel kecepatan.
const HUD_PANEL_KORAN_GESER_PX: int = 400
## Panel sisa koran: jumlah ikon koran paling banyak (DESIGN_SPEC 3.5).
const HUD_KORAN_IKON_MAKS: int = 8
## Panel sisa koran: sisi ikon koran, piksel game (DESIGN_SPEC 3.5).
const HUD_KORAN_IKON_PX: int = 12
## Panel sisa koran: jarak antar ikon, piksel game.
const HUD_KORAN_IKON_JARAK_PX: int = 1
## Panel sisa koran: alpha ikon koran yang sudah terpakai (DESIGN_SPEC 3.5: redup 28%).
const HUD_KORAN_REDUP_ALPHA: float = 0.28
## Tinggi tombol di strip atas dan tombol layar jeda, piksel game. Di A54 (450 dpi, skala x3) 44 dp sekitar 41,7 px game, jadi 42 (paket pemilik 2026-10-14); muat di strip atas: margin 4 + 42 = 46 < 48.
const HUD_TOMBOL_TINGGI_PX: int = 42
## Lebar minimum tombol di strip atas, piksel game.
const HUD_TOMBOL_LEBAR_PX: int = 96
## Jarak tombol strip atas dari tepi atas layar, piksel game. Tombol berakhir di bawah `HUD_STRIP_ATAS_TINGGI_PX`.
const HUD_TOMBOL_MARGIN_ATAS_PX: int = 4
## Tombol jeda (DESIGN_SPEC 3.1): sisi area sentuh persegi, piksel game (≥ 44 dp di A54, paket pemilik 2026-10-14). Lebih besar dari gambarnya.
const HUD_JEDA_SENTUH_PX: int = 42
## Tombol jeda: sisi gambar persegi (kotak bergaris `TEXT`), piksel game.
const HUD_JEDA_GAMBAR_PX: int = 24
## Tombol jeda: letak pojok kiri atas gambar dari tepi kiri layar, piksel game. Tidak dicerminkan saat kidal.
const HUD_JEDA_GAMBAR_X_PX: int = 26
## Tombol jeda: letak pojok kiri atas gambar dari tepi atas layar, piksel game.
const HUD_JEDA_GAMBAR_Y_PX: int = 8
## Tombol jeda: lebar satu batang ikon, piksel game.
const HUD_JEDA_BATANG_LEBAR_PX: int = 3
## Tombol jeda: tinggi batang ikon, piksel game.
const HUD_JEDA_BATANG_TINGGI_PX: int = 10
## Tombol jeda: celah di antara dua batang ikon, piksel game.
const HUD_JEDA_BATANG_CELAH_PX: int = 4
## Layar jeda: lebar minimum tombol "Lanjut", piksel game (tingginya `HUD_TOMBOL_TINGGI_PX`).
const JEDA_TOMBOL_LEBAR_PX: int = 96
## Objek berkala di sisi seberang: berapa ubin di belakang sepeda yang masih disiapkan.
const JALAN_UJI_DAUR_MUNDUR_UBIN: int = 12
## Objek berkala di sisi seberang: berapa ubin di depan sepeda yang sudah disiapkan.
const JALAN_UJI_DAUR_MAJU_UBIN: int = 16

## --- Zona sasaran jalan uji (BALANCING 5, D-6 run fase2a-lemparan; placeholder usulan, bukan data rute) ---
## Tiap zona = [lateral_min, maju_min, lebar_lateral, panjang_maju], ubin, persegi di bidang tanah. Lateral dari garis tengah jalan
## (negatif = seberang, positif = dekat); maju relatif terhadap awal kavling `indeks x JALAN_UJI_RUMAH_PERIODE_UBIN` (sama dengan
## `JALAN_UJI_KOTAK_SURAT_MAJU_UBIN`). Tepi min inklusif, tepi maks eksklusif (`ZonaSasaran`). Prioritas bila tumpang tindih:
## kotak surat > jendela > teras > halaman. Sisi dekat datar tanpa fasad dan tanpa jendela, hanya supaya lempar ke sisi dekat bisa
## diuji (tidak memutuskan cara menampilkan rumah di sisi dekat, ROADMAP 5).

## Seberang: kotak surat, 0,5 x 0,5 di sekitar kotak surat graybox (pijak -1,5, 1,0, kotak 0,25 ubin) di trotoar.
const JALAN_UJI_SEBERANG_KOTAK_SURAT_UBIN: Array[float] = [-1.875, 0.875, 0.5, 0.5]
## Seberang: halaman, rumput di antara trotoar (-2,0) dan fasad (-3,0) sepanjang rumah (maju -0,5 sampai 2,5).
const JALAN_UJI_SEBERANG_HALAMAN_UBIN: Array[float] = [-3.0, -0.5, 1.0, 3.0]
## Seberang: teras, di kaki fasad bagian pintu.
const JALAN_UJI_SEBERANG_TERAS_UBIN: Array[float] = [-3.0, 0.0, 0.5, 1.25]
## Seberang: jendela, strip tanah 0,25 ubin di kaki fasad (model placeholder 2D).
const JALAN_UJI_SEBERANG_JENDELA_UBIN: Array[float] = [-3.0, 1.5, 0.25, 0.75]
## Dekat: kotak surat di trotoar dekat (datar, tanpa graybox).
const JALAN_UJI_DEKAT_KOTAK_SURAT_UBIN: Array[float] = [1.375, 0.875, 0.5, 0.5]
## Dekat: halaman, rumput sesudah trotoar dekat.
const JALAN_UJI_DEKAT_HALAMAN_UBIN: Array[float] = [2.0, -0.5, 1.0, 3.0]
## Dekat: teras, sisi jauh halaman.
const JALAN_UJI_DEKAT_TERAS_UBIN: Array[float] = [2.5, 0.25, 0.5, 1.5]
## Rumah seberang bernomor n bukan pelanggan bila n mod `SETIAP` = `SISA` (minimal satu per putaran daur 9 slot).
const JALAN_UJI_BUKAN_PELANGGAN_SETIAP: int = 4
## Lihat `JALAN_UJI_BUKAN_PELANGGAN_SETIAP`.
const JALAN_UJI_BUKAN_PELANGGAN_SISA: int = 2
## Isi ulang koran khusus jalan uji (alat uji, bukan aturan game; jalan uji tidak punya akhir rute): sesudah koran habis dan sepeda
## menempuh sekian ubin, sisa koran kembali penuh.
const JALAN_UJI_ISI_ULANG_UBIN: float = 16.0
