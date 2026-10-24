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
## `ThrowSolver` satu-satunya pemakai angka lintasan. Arah bebas (run fase2-arah-bebas): arah tanah = arah swipe di layar lewat `Iso`,
## panjang swipe = |v| penuh (piksel game) terhadap lebar viewport game saat itu; u = jepit((|v| - min) / (maks - min), 0, 1). Jarak
## tanah searah arah itu, lama terbang, dan tinggi puncak linear dari u.
## Koran mewarisi kecepatan maju sepeda; tidak ada warisan lateral selama terbang. Tinggi dalam ubin (1 ubin = 32 px tegak, `Iso`).

## Swipe terpendek yang masih melempar, pecahan lebar viewport game, inklusif (6%). Di bawahnya tidak melempar: tanpa garis bidik, koran tidak terpakai.
const LEMPAR_SWIPE_MIN_PECAHAN: float = 0.06
## Swipe terpanjang yang masih dihitung, pecahan lebar viewport game (35%). Lebih panjang dijepit ke lemparan terjauh.
const LEMPAR_SWIPE_MAKS_PECAHAN: float = 0.35
## Toleransi saat membandingkan |v| dengan swipe minimum, piksel game (posisi sentuh berpresisi tunggal: 46,8 tersimpan 46,7999992).
const LEMPAR_SWIPE_TOLERANSI_PX: float = 0.001
## Jarak tanah dari titik lepas searah arah swipe pada swipe minimum (u = 0), ubin.
const LEMPAR_JARAK_MIN_UBIN: float = 1.5
## Jarak tanah dari titik lepas searah arah swipe pada swipe maksimum (u = 1), ubin.
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

## --- Mode bantu (GDD 5.3, BALANCING 4b; usulan run fase2b-bantu-audio, dinilai lewat uji HP) ---
## Tap di zona swipe melempar otomatis ke kotak surat pelanggan terdekat di depan pada sisi tap (`BantuLempar`). Lintasan tetap dari
## `ThrowSolver.hitung`, jadi angka lintasan, jeda lepas, dan jeda antar lempar tidak berubah (K-4). Tap = |v| maksimum < swipe minimum,
## tanpa batas durasi (D-1), jadi tidak ada angka tap di sini.

## Toleransi pencarian kekuatan u ke pusat kotak surat (f(u) = |R(u)| - jarak tanah), ubin. Jauh di bawah setengah lebar zona (0,25).
const BANTU_TOLERANSI_UBIN: float = 0.000001
## Jumlah langkah bisection pencarian u; 48 langkah = ketelitian u sekitar 3,6e-15 (jarak tanah sekitar 1e-14 ubin).
const BANTU_CARI_ULANGAN: int = 48
## Lama tanda "tidak ada sasaran" di titik tap (cincin kecil `TEXT_2`, DESIGN_SPEC 3.7), detik.
const BANTU_TANDA_LAMA_DETIK: float = 0.6

## --- Koran terbang, garis bidik, penanda, dan zona (placeholder dari kode, usulan run fase2a-lemparan bagian 1b) ---
## Digambar per piksel game (persegi bulat) supaya tajam di skala bulat; warna hanya dari `Palette` (DESIGN_SPEC 3.6, 3.7,
## ART_DIRECTION 6.2). Bukan angka lintasan: lintasan tetap hanya dari `ThrowSolver`.

## Koran gulung berputar 4 langkah (4 frame pola) selama terbang, frame per detik (sama dengan animasi lempar 12 fps).
const KORAN_PUTAR_FPS: float = 12.0
## Bayangan koran: lebar elips saat koran di tanah, piksel game (tinggi elips setengahnya). 10 (dulu 8; QA-007 iterasi 2: lebih lebar dari
## koran 8 px supaya terbaca di ×3).
const KORAN_BAYANGAN_LEBAR_MAKS_PX: int = 10
## Bayangan koran: lebar elips terkecil (koran paling tinggi), piksel game. 6 (dulu 4; QA-007 iterasi 2).
const KORAN_BAYANGAN_LEBAR_MIN_PX: int = 6
## Bayangan koran mengecil sekian piksel game per ubin tinggi koran.
const KORAN_BAYANGAN_SUSUT_PX_PER_UBIN: float = 2.0
## Alpha bayangan koran (warna `OUTLINE`). 0,85 (dulu 0,5; QA-007 iterasi 2): kontras bayangan di atas aspal graybox naik dari sekitar
## 2,1:1 ke sekitar 3,2:1 (dites >= 3:1 di aspal, trotoar, dan rumput); masih sedikit tembus supaya terbaca sebagai bayangan.
const KORAN_BAYANGAN_ALPHA: float = 0.85
## Penanda kena/meleset digambar sekian piksel game di atas titik mendarat (kaki penanda), di atas koran yang tergeletak (tinggi 6).
const PENANDA_ATAS_PX: int = 7
## Jumlah sampel `posisi_pada` sepanjang lintasan untuk menaruh titik garis bidik (titik dipilih dari sampel ini tiap `SWIPE_TITIK_JARAK_PX`).
const GARIS_BIDIK_SAMPEL: int = 96
## Alpha titik garis bidik dan elips pendaratan yang tertutup rumah dari sudut kamera (di dalam atau di belakang kotak rumah; elips juga
## berganti bentuk putus-putus, QA-004 iterasi 2).
const GARIS_BIDIK_TERTUTUP_ALPHA: float = 0.5
## Alpha garis tepi halaman dan isi zona placeholder di jalan uji.
const ZONA_GARIS_ALPHA: float = 0.7
## Alpha isi persegi zona kotak surat di scene dev spike sisi dekat (tidak ikut paket): tipis supaya tanah tetap terbaca.
## Scene rute TIDAK lagi menggambar area kotak surat (keputusan pemilik 2026-10-22: persegi membuat pemain mengira hanya area itu yang
## dinilai); konstanta ini tinggal hanya untuk spike.
const AREA_KOTAK_ISI_ALPHA: float = 0.28
## Alpha garis tepi persegi zona kotak surat di scene dev spike sisi dekat: tegas (bentuk terbaca tanpa bergantung warna isi).
const AREA_KOTAK_TEPI_ALPHA: float = 0.9

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

## --- Audio lempar dan mendarat placeholder (SOUND_DESIGN 3.1, 4.2; usulan run fase2b-bantu-audio, dinilai di HP) ---
## Bunyi dibuat `tools/audio_art/sintesis_lempar.py`: puncak "wus" dan tiga permukaan sama dengan bunyi sepeda (-1 dBFS), meleset
## sekitar 5 dB lebih pelan di berkasnya sendiri. Diputar autoload `Audio` di bus `SFX`; pemetaan hasil ke permukaan di `BunyiLempar`.

## Volume "wus" saat lemparan diterima, dB (di bawah bunyi mendarat, sedikit di atas kayuhan).
const AUDIO_WUS_VOLUME_DB: float = -4.0
## Volume bunyi mendarat keempat permukaan, dB. Di atas kayuhan (-6 dB) supaya hasil lemparan selalu terdengar (SOUND_DESIGN 6).
const AUDIO_MENDARAT_VOLUME_DB: float = -1.0

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
## Zona swipe: batas atas, diukur dari atas layar, piksel game. Di atasnya strip HUD (`HUD_STRIP_ATAS_TINGGI_PX`) yang bebas dari kontrol. Sejak run 6A1 strip atas rute memuat juga panel kondisi (baris 2, y 43 sampai 67) yang
## memotong bagian paling atas zona swipe; panel itu tidak menangkap sentuhan, jadi swipe yang dimulai di atasnya tetap melempar (QA-003, usulan yang dinilai di HP: apakah jempol menutupi panel saat swipe).
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
## Lebar kolom rumput pertama di luar trotoar, ubin (tampilan, run fase5a D-2). Kolom pertama memakai ubin tepi kerb luar (`rumput_seberang`/`rumput_dekat`); kolom di luarnya memakai ubin rumput polos supaya tepi kerb tidak berulang jadi pita.
const JALAN_RUMPUT_TEPI_UBIN: float = 1.0
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
## Kotak rumah graybox: panjang sepanjang jalan dari titik pijak, dalam ke arah seberang dari kaki fasad, dan tinggi, ubin. Fakta aset
## `tools/env_art/graybox.py` (3 x 2 ubin, 48 px), dijaga tes terhadap ukuran `house_graybox_kotak.png`; dipakai aturan elips "tertutup
## rumah" garis bidik (QA-004 run fase2a-lemparan iterasi 2).
const JALAN_UJI_RUMAH_PANJANG_UBIN: float = 3.0
## Lihat `JALAN_UJI_RUMAH_PANJANG_UBIN`.
const JALAN_UJI_RUMAH_DALAM_UBIN: float = 2.0
## Lihat `JALAN_UJI_RUMAH_PANJANG_UBIN`.
const JALAN_UJI_RUMAH_TINGGI_UBIN: float = 1.5
## Letak kotak surat melintang jalan, ubin dari garis tengah jalan: di halaman (rumput antara trotoar -2,0 dan fasad -3,0), bukan di
## trotoar (permintaan pemilik 2026-10-16; dulu -1,5). Tetap 0,125 ubin ke arah jalan dari pusat zona (-2,25), seperti sebelumnya.
const JALAN_UJI_KOTAK_SURAT_X_UBIN: float = -2.125
## Geseran kotak surat sepanjang jalan, ubin: bagian halaman terluas, sesudah teras (maju 0 sampai 1,25) dan sebelum ujung kavling
## (dulu 1,0). Tetap 0,125 ubin di belakang pusat zona (1,875).
const JALAN_UJI_KOTAK_SURAT_MAJU_UBIN: float = 1.75
## Batas atas langkah waktu per frame, detik. Mencegah lompatan jauh setelah app kembali dari background.
const LANGKAH_WAKTU_MAKS_DETIK: float = 0.1
## Pembagi konversi milidetik ke detik.
const WAKTU_MS_PER_DETIK: float = 1000.0

## --- HUD sementara (DESIGN_SPEC 1.3, 3.5, 3.7) ---

## Tinggi strip atas HUD yang bebas dari zona kontrol, piksel game. Sama dengan `ZONA_SWIPE_Y_MIN_PX`. Pengecualian run 6A1: panel kondisi rute melewati garis ini (berakhir y 67) tanpa menangkap sentuhan; zona swipe tetap mulai di sini.
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
## Jarak antar tombol di strip atas (tombol kidal dan tombol mode bantu), piksel game.
const HUD_TOMBOL_JARAK_PX: int = 8
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

## Seberang: kotak surat sebagai AREA 1,0 x 1,25 (lateral x maju) di halaman, bagian terluas: sesudah teras (maju 0 sampai 1,25) sampai
## ujung halaman (2,5), berpusat di (-2,25; 1,875). Permintaan pemilik 2026-10-16: kotak surat di halaman rumah, bukan di trotoar (dulu
## [-2,125; 0,375; 1,0; 1,5] di trotoar). Lateral -2,75 sampai -1,75: menempel tepi trotoar (-2,0) dengan 0,25 ubin di atasnya supaya
## bisa dikenai dari trotoar, tidak menimpa teras (maju mulai 1,25, eksklusif) maupun jendela (lateral berakhir -2,75, eksklusif).
## Area turun dari 1,5 ke 1,25 ubin persegi karena teras harus tetap utuh (BALANCING 5).
const JALAN_UJI_SEBERANG_KOTAK_SURAT_UBIN: Array[float] = [-2.75, 1.25, 1.0, 1.25]
## Seberang: halaman, rumput di antara trotoar (-2,0) dan fasad (-3,0) sepanjang rumah (maju -0,5 sampai 2,5).
const JALAN_UJI_SEBERANG_HALAMAN_UBIN: Array[float] = [-3.0, -0.5, 1.0, 3.0]
## Seberang: teras, di kaki fasad bagian pintu.
const JALAN_UJI_SEBERANG_TERAS_UBIN: Array[float] = [-3.0, 0.0, 0.5, 1.25]
## Seberang: jendela, strip tanah 0,25 ubin di kaki fasad (model placeholder 2D).
const JALAN_UJI_SEBERANG_JENDELA_UBIN: Array[float] = [-3.0, 1.5, 0.25, 0.75]
## Dekat: kotak surat di halaman dekat (datar, tanpa graybox), area 0,75 x 1,25 di lateral 1,75 sampai 2,5, maju 1,25 sampai 2,5,
## berpusat di (2,125; 1,875). Lebih sempit dari seberang supaya tidak menimpa teras dekat (lateral mulai 2,5, eksklusif); tidak
## bertumpuk dengan zona seberang (celah lateral -1,75 sampai 1,75).
const JALAN_UJI_DEKAT_KOTAK_SURAT_UBIN: Array[float] = [1.75, 1.25, 0.75, 1.25]
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

## --- Rute perumahan dari segmen (BALANCING 6, DATA_SCHEMA 3, ROUTE_DESIGN; usulan run fase3a-rute, dinilai lewat uji HP) ---
## Segmen JSON buatan tangan di `assets/data/routes/perumahan/` disusun `RouteBuilder` dari seed; tidak ada angka tuning di data.

## Jumlah pelanggan tiap rute perumahan (GDD 14.1, K-2 run fase3a-rute): tepat sekian, semuanya di sisi `seberang`.
const RUTE_PELANGGAN: int = 25
## Jumlah segmen berbeda tiap rute: satu pembuka, sisanya tengah, satu penutup (K-2).
const RUTE_SEGMEN_PER_RUTE: int = 7
## Segmen pengapit tiap rute (satu pembuka dan satu penutup): sisa `RUTE_SEGMEN_PER_RUTE` adalah segmen tengah berbeda (K-2).
const RUTE_SEGMEN_PENGAPIT: int = 2
## Jumlah minimum segmen `pembuka` di pustaka supaya rute bervariasi antar seed (AC-1).
const RUTE_PEMBUKA_MIN: int = 2
## Jumlah minimum segmen `penutup` di pustaka supaya rute bervariasi antar seed (AC-1).
const RUTE_PENUTUP_MIN: int = 2
## Seed bawaan rute dev (deterministik); "Main lagi" memakai seed berikutnya (seed + 1).
const RUTE_SEED_DEV: int = 20261016
## Koran awal rute = pelanggan + sekian persen dibulatkan ke atas (BALANCING 4): 25 pelanggan = 30 koran.
const RUTE_KORAN_CADANGAN_PERSEN: int = 20
## Pembagi persen ke pecahan untuk persen rute (`RUTE_KORAN_CADANGAN_PERSEN`, `RUTE_PEMBERI_TIP_PERSEN`; 100 persen = satu bagian penuh).
const RUTE_KORAN_PERSEN_PENUH: int = 100
## Panjang segmen terpendek yang sah, ubin (ROUTE_DESIGN 1).
const RUTE_SEGMEN_PANJANG_MIN_UBIN: int = 24
## Panjang segmen terpanjang yang sah, ubin (ROUTE_DESIGN 1).
const RUTE_SEGMEN_PANJANG_MAKS_UBIN: int = 40
## Tepi netral tiap ujung segmen: tidak ada rumah, objek, atau titik misi di dalamnya, ubin (ROUTE_DESIGN 1).
const RUTE_TEPI_UBIN: int = 2
## Lebar satu petak rumah, ubin: rumah 3 ubin + celah 1 (ROUTE_DESIGN 2); dua rumah sesisi berjarak paling sedikit sekian.
const RUTE_PETAK_UBIN: int = 4
## Jendela belakang `MedanKoran.tertutup_titik`, petak: sinar ke kamera bergeser maju mundur selama naik, jadi rumah yang bisa menutupi titik tanah ada sampai sekian petak di belakangnya (satu petak di depan tetap).
const RUTE_PENUTUP_JENDELA_BELAKANG_PETAK: int = 2
## Jendela keputusan, ubin: dua rintangan yang memaksa pindah jalur berjarak paling sedikit sekian (ROUTE_DESIGN 4 aturan 4).
const RUTE_RINTANGAN_JENDELA_UBIN: int = 6
## Rintangan paling dekat ke tepi segmen, ubin: setengah jendela, supaya dua segmen yang disambung tidak menumpuk keputusan.
const RUTE_RINTANGAN_TEPI_UBIN: int = 3
## Tanda rintangan bergerak terlihat paling sedikit sekian ubin sebelum rintangan: 1,5 detik pada ngebut 6,0 u/d (ROUTE_DESIGN 4 aturan 2).
const RUTE_TANDA_MIN_UBIN: float = 9.0
## Celah terpanjang antara dua pelanggan berturut-turut, ubin (usulan; rata-rata sekitar 9 ubin, BALANCING 6).
const RUTE_PELANGGAN_JARAK_MAKS_UBIN: float = 20.0
## Goyangan acak (plus minus) target posisi pelanggan terhadap sebaran rata, ubin: memberi rumah berurutan lalu sela panjang (ROUTE_DESIGN 3).
const RUTE_PELANGGAN_GOYANG_UBIN: float = 3.0
## Percobaan paling banyak menyusun urutan segmen dan memilih pelanggan sebelum rute dinyatakan gagal dibangun.
const RUTE_SUSUN_PERCOBAAN_MAKS: int = 200
## Tapak kotak rumah rute untuk aturan penutup pemain (`PenutupPemain`), ubin. Dari aset `tools/env_art/perumahan.py`: badan 88 unit
## sepanjang jalan ditambah cucuran atap = sekitar 3 ubin; dalam 94 unit = sekitar 3 ubin; puncak atap 58 sampai 62 unit = sekitar 2 ubin.
const RUTE_RUMAH_PANJANG_UBIN: float = 3.0
## Lihat `RUTE_RUMAH_PANJANG_UBIN`.
const RUTE_RUMAH_DALAM_UBIN: float = 3.0
## Lihat `RUTE_RUMAH_PANJANG_UBIN`.
const RUTE_RUMAH_TINGGI_UBIN: float = 2.0
## Kaki fasad rumah sisi dekat melintang jalan, ubin dari garis tengah (positif = dekat): sesudah halaman dekat (2,0 sampai 3,0).
const RUTE_RUMAH_DEKAT_X_UBIN: float = 3.0
## Alpha objek yang menutupi pemain (GDD 2.3, ART_DIRECTION 2.2: semi-transparan); 1,0 saat tidak menutupi (`PenutupPemain`).
const RUTE_PENUTUP_ALFA: float = 0.45

## --- Scene rute (run fase3a-rute bagian B, usulan, dinilai lewat uji HP) ---

## Rumah yang masih ada (digambar) di belakang sepeda, ubin sepanjang jalan. Rumah di luar jendela daur tidak diinstansiasi (AC-12).
## 20 (bukan seluruh rute sekitar 250 ubin): layar terlebar 800 piksel game memuat sekitar 25 ubin sepanjang jalan, dan sprite rumah
## paling lebar 270 piksel menjorok sekitar 8 ubin ke kiri titik pijak.
const RUTE_DAUR_MUNDUR_UBIN: int = 20
## Rumah yang sudah ada di depan sepeda, ubin sepanjang jalan (sisi `dekat` paling jauh terlihat sekitar 25 ubin di depan sepeda).
const RUTE_DAUR_MAJU_UBIN: int = 30
## Stick buatan yang diberikan ke sepeda sesudah garis akhir: komponen tegak -1 = tarik penuh ke bawah = rem (stick sungguhan dikunci).
const RUTE_AKHIR_STICK_Y: float = -1.0
## Jarak banner "Rute selesai" dari tepi atas layar, piksel game: di bawah strip atas HUD dan di luar zona stick dan swipe.
const RUTE_BANNER_MARGIN_ATAS_PX: int = 64
## Nama 12 sprite rumah perumahan (`assets/sprites/houses/perumahan/<nama>.png`), sejajar dengan `RUTE_RUMAH_PIJAK_PX`.
const RUTE_RUMAH_SPRITE: Array[String] = ["house_perumahan_dekat_limasan_bukan", "house_perumahan_dekat_limasan_pelanggan", "house_perumahan_dekat_pelana_lintang_bukan", "house_perumahan_dekat_pelana_lintang_pelanggan", "house_perumahan_dekat_pelana_sejajar_bukan", "house_perumahan_dekat_pelana_sejajar_pelanggan", "house_perumahan_limasan_bukan", "house_perumahan_limasan_pelanggan", "house_perumahan_pelana_bukan", "house_perumahan_pelana_pelanggan", "house_perumahan_sayap_bukan", "house_perumahan_sayap_pelanggan"]
## Titik pijak tiap sprite rumah (`ground_anchor` di JSON aset, tengah tapak), piksel dari pojok kiri atas gambar: x lalu y, sejajar dengan `RUTE_RUMAH_SPRITE`. Tes membandingkannya dengan JSON aset.
const RUTE_RUMAH_PIJAK_PX: Array[int] = [110, 127, 110, 127, 110, 126, 110, 126, 110, 122, 110, 122, 105, 127, 105, 127, 96, 148, 96, 148, 105, 119, 105, 119]

## --- Rintangan perumahan (GDD 9.3, ROUTE_DESIGN 4, BALANCING 6c; usulan run fase3b-rintangan-skor, dinilai lewat uji HP) ---
## Posisi dalam koordinat jalan: lateral dari garis tengah (negatif = `seberang`), maju dari awal rute, ubin. Bentuk tabrakan = persegi di
## bidang tanah (setengah ukuran di bawah). Anjing dan mobil hanya memakai separuh jalan di sisinya (K-1): tepi bentuknya tidak pernah
## melewati garis tengah, jadi separuh lain selalu bebas (ROUTE_DESIGN 4 aturan 1). Jarak tanda dari data segmen (`tanda_ubin`).

## Setengah lebar bentuk tabrakan sepeda melintang jalan, ubin (lebar 0,5).
const TABRAKAN_SEPEDA_SETENGAH_LATERAL_UBIN: float = 0.25
## Setengah panjang bentuk tabrakan sepeda sepanjang jalan, ubin (panjang 0,8).
const TABRAKAN_SEPEDA_SETENGAH_MAJU_UBIN: float = 0.4
## Anjing penjaga: setengah sisi bentuk persegi, ubin (sisi 0,5).
const ANJING_SETENGAH_UBIN: float = 0.25
## Anjing: jarak pusat dari garis tengah saat di halamannya (duduk), ubin. Tepi bentuknya (2,5) di luar jangkauan sepeda di tepi trotoar.
const ANJING_RUMAH_LATERAL_UBIN: float = 2.75
## Anjing mulai mengejar saat sepeda sudah sejauh ini di belakang titik rumahnya atau lebih maju, ubin (0 = sepeda melewati anjing).
const ANJING_KEJAR_JARAK_UBIN: float = 0.0
## Anjing: laju maju saat mengejar = kecepatan sepeda x pengali ini, dijepit `ANJING_LAJU_MIN_UD` sampai `ANJING_LAJU_MAKS_UD`.
const ANJING_KEJAR_PENGALI: float = 1.25
## Anjing: laju maju terkecil saat mengejar, u/d (sepeda yang berhenti tetap dikejar).
const ANJING_LAJU_MIN_UD: float = 2.0
## Anjing: batas laju maju, u/d. Di bawah ngebut (6,0) supaya pemain ngebut lolos; di atas santai x pengali supaya santai tersusul.
const ANJING_LAJU_MAKS_UD: float = 4.5
## Anjing: laju menyamping ke arah sepeda (di dalam separuh jalan sisinya), u/d.
const ANJING_LATERAL_UD: float = 2.0
## Anjing: batas halaman, paling jauh sekian ubin maju dari titik rumahnya; sampai di sini anjing berhenti mengejar.
const ANJING_BATAS_MAJU_UBIN: float = 3.0
## Anjing: lama berdiri di batas halaman (atau sesudah menabrak sepeda) sebelum pulang, detik.
const ANJING_BERHENTI_DETIK: float = 0.8
## Anjing: laju pulang ke titik rumahnya (per sumbu), u/d.
const ANJING_PULANG_UD: float = 2.0
## Anjing yang mendengar bel: lama diam menampilkan ikon "!" sebelum mundur, detik (DESIGN_SPEC 3.8: sekitar 0,5).
const ANJING_KAGET_DETIK: float = 0.5
## Anjing yang mendengar bel: laju mundur ke titik rumahnya (per sumbu), u/d.
const ANJING_MUNDUR_UD: float = 3.0
## Mobil keluar garasi: panjang mobil melintang jalan (mobil mundur tegak lurus jalan), ubin.
const MOBIL_PANJANG_UBIN: float = 1.5
## Mobil: setengah lebar mobil sepanjang jalan, ubin (lebar 0,75).
const MOBIL_SETENGAH_LEBAR_UBIN: float = 0.375
## Mobil: jarak bagasi (ujung belakang) dari garis tengah saat parkir di garasi, ubin. Di luar jangkauan sepeda di tepi trotoar.
const MOBIL_BELAKANG_AWAL_UBIN: float = 2.5
## Mobil: bagasi berhenti sejauh ini dari garis tengah, ubin (0 = tepat di garis tengah; tidak pernah melewatinya, K-1).
const MOBIL_BELAKANG_AKHIR_UBIN: float = 0.0
## Mobil: lama lampu mundur dan bip menyala sebelum mobil bergerak, detik (ROUTE_DESIGN 4 aturan 2: tanda minimal 1,5 detik).
const MOBIL_TANDA_DETIK: float = 1.5
## Mobil: laju mundur ke jalan, u/d.
const MOBIL_MUNDUR_UD: float = 1.0

## --- Tabrakan = jatuh (BALANCING 6, keputusan pemilik 2026-10-17 menggantikan oleng K-1 run fase3b-rintangan-skor; usulan, dinilai lewat uji HP) ---

## Lama jatuh sejak tabrakan, detik: kecepatan 0, stick dan lemparan diabaikan, animasi jatuh lalu terjerembab; sesudahnya sepeda dikayuh lagi dari 0.
const TABRAKAN_JATUH_DETIK: float = 1.2
## Lama kebal dihitung dari saat BANGUN (akhir jatuh), detik: tidak ada tabrakan kedua dari rintangan mana pun.
const TABRAKAN_KEBAL_DETIK: float = 1.0
## Toleransi derau float untuk waktu rintangan, tabrakan, dan bel (sisa jatuh, kebal, jeda bel, lama berhenti anjing, lama tanda mobil), detik.
const TABRAKAN_TOLERANSI_DETIK: float = 0.000001

## --- Bel "Kring Kring!" (GDD 5.4, DESIGN_SPEC 3.8, K-3 run fase3b-rintangan-skor; usulan, dinilai lewat uji HP) ---

## Lama teks "KRING!" tampil sesudah ketukan, detik. Ketukan kedua selama teks tampil = "KRING KRING!" (GDD 5.4).
const BEL_TEKS_DETIK: float = 0.5
## Jeda bel sesudah "kring kring!" (dua bunyi), detik; ketukan selama jeda ditolak tanpa bunyi.
const BEL_JEDA_DETIK: float = 1.0
## Jangkauan bel di depan sepeda, ubin (GDD 5.4: sekitar 4 ubin).
const BEL_JANGKAUAN_UBIN: float = 4.0
## Jangkauan bel di belakang sepeda, ubin: anjing yang mengejar berlari tepat di samping atau sedikit di belakang sepeda (D-5 run ini).
const BEL_JANGKAUAN_BELAKANG_UBIN: float = 1.0

## --- Skor, combo, koin, tip, tepat (BALANCING 5 dan 7, GDD 14.1; K-2, K-4, O-1 sampai O-5 run fase3b-rintangan-skor; usulan) ---
## Skor dan koin dua besaran terpisah (K-2). Skor = dasar x persen sasaran x pengali combo x pengali kecepatan saat lepas (x tepat),
## dihitung dengan bilangan bulat (persen dan persepuluh) lalu dibulatkan ke bilangan bulat terdekat, setengah ke atas (`SkorRute`).

## Skor dasar satu antaran sah penuh, poin.
const SKOR_SASARAN_DASAR: int = 100
## Persen skor sasaran sah penuh (kotak surat, teras, jendela dengan sakelar bonus).
const SKOR_PERSEN_PENUH: int = 100
## Persen skor antaran halaman (sah setengah, BALANCING 5).
const SKOR_PERSEN_HALAMAN: int = 50
## Pengali combo antaran pertama dalam rangkaian.
const SKOR_COMBO_AWAL: float = 1.0
## Pengali combo naik sekian tiap antaran sah beruntun.
const SKOR_COMBO_LANGKAH: float = 0.1
## Pengali combo paling besar.
const SKOR_COMBO_MAKS: float = 2.0
## Pengali skor saat koran dilepas di pita santai (dan melambat), dari kecepatan SEBENARNYA (O-5).
const SKOR_PENGALI_SANTAI: float = 1.0
## Pengali skor di pita cepat.
const SKOR_PENGALI_CEPAT: float = 1.2
## Pengali skor di pita ngebut.
const SKOR_PENGALI_NGEBUT: float = 1.5
## Pengali skor antaran "tepat" (inti kotak surat, K-4; bukan mode bantu, O-4).
const SKOR_TEPAT_PENGALI: float = 1.25
## Ongkos antar tiap antaran sah pertama ke rumah pelanggan, koin (GDD 14.1, BALANCING 7).
const KOIN_ONGKOS_ANTAR: int = 15
## Tip dari pelanggan pemberi tip yang korannya mendarat di teras, koin (BALANCING 7).
const KOIN_TIP: int = 5
## Potongan tiap koran yang DILEMPAR lalu terbuang (meleset, rumah bukan pelanggan, rumah sudah terantar, jendela penalti), koin (K-1 pemilik 2026-10-22, 1/3 ongkos antar, usulan; BALANCING 7). Sisa koran yang tidak dilempar tidak dipotong.
const KOIN_POTONGAN_KORAN_MELESET: int = 5
## Persen pelanggan rute yang memberi tip, dipilih berseed oleh `RouteBuilder` (O-3); dibulatkan ke bawah: 25 x 30% = 7.
const RUTE_PEMBERI_TIP_PERSEN: int = 30
## Inti "tepat" kotak surat seberang [lateral_min, maju_min, lebar, panjang], ubin relatif awal kavling: 0,5 x 0,5 di pusat area
## `JALAN_UJI_SEBERANG_KOTAK_SURAT_UBIN` (pusat -2,25; 1,875). Tepi min inklusif, maks eksklusif (K-4).
const JALAN_UJI_SEBERANG_KOTAK_SURAT_INTI_UBIN: Array[float] = [-2.5, 1.625, 0.5, 0.5]
## Inti "tepat" kotak surat dekat: 0,5 x 0,5 di pusat area `JALAN_UJI_DEKAT_KOTAK_SURAT_UBIN` (pusat 2,125; 1,875).
const JALAN_UJI_DEKAT_KOTAK_SURAT_INTI_UBIN: Array[float] = [1.875, 1.625, 0.5, 0.5]

## --- Audio rute placeholder (SOUND_DESIGN 3.1, 3.3, 4.1-4.3; AC-18, AC-19 run fase3b-rintangan-skor; usulan, dinilai di HP) ---
## Bunyi dibuat `tools/audio_art/sintesis_rute.py` (puncak sama dengan bunyi lain, tabrakan lebih pelan di berkasnya). Diputar autoload
## `Audio` di bus `SFX`; pemetaan peristiwa ke bunyi di `BunyiRute`, nada combo di `BunyiLempar`.

## Nada combo: bunyi mendarat antaran sah naik setengah nada tiap antaran beruntun sampai sekian tingkat, lalu bertahan (SOUND_DESIGN 3.1).
const AUDIO_COMBO_NADA_MAKS: int = 5
## Jumlah setengah nada dalam satu oktaf (rasio pitch satu setengah nada = rasio oktaf pangkat 1/12).
const AUDIO_SETENGAH_NADA_PER_OKTAF: float = 12.0
## Rasio frekuensi satu oktaf.
const AUDIO_RASIO_OKTAF: float = 2.0
## Bunyi kedua "kring kring!" diputar sekian setengah nada lebih tinggi supaya dua bunyi terdengar satu frasa (SOUND_DESIGN 3.3).
const AUDIO_BEL_KEDUA_SETENGAH_NADA: float = 1.0
## Volume bel, dB (bel terdengar jelas di atas kayuhan, SOUND_DESIGN 3.3).
const AUDIO_BEL_VOLUME_DB: float = -2.0
## Volume geram, gonggong, bip, dan mesin rintangan, dB (peringatan di atas kayuhan, SOUND_DESIGN 6).
const AUDIO_RINTANGAN_VOLUME_DB: float = -3.0
## Volume tabrakan, dB (berkasnya sudah sekitar 3 dB lebih pelan: lembut, SOUND_DESIGN 2).
const AUDIO_TABRAKAN_VOLUME_DB: float = -2.0
## Volume denting tip dan kilau tepat, dB.
const AUDIO_TIP_VOLUME_DB: float = -3.0

## --- Scene rute run fase3b-rintangan-skor bagian B: rintangan digambar, tabrakan, bel, HUD skor (usulan, dinilai lewat uji HP) ---

## Tinggi kotak penutup anjing untuk aturan objek yang menutupi pemain (`PenutupPemain`), ubin: badan anjing sekitar 26 piksel = 0,8 ubin.
const RINTANGAN_ANJING_TINGGI_UBIN: float = 0.8
## Tinggi kotak penutup mobil, ubin: sedan sekitar 32 piksel dari tanah sampai atap = 1,0 ubin.
const RINTANGAN_MOBIL_TINGGI_UBIN: float = 1.0
## Titik jangkar ikon "!" di atas anjing yang bereaksi pada bel, piksel game di atas titik pijak anjing (kepala sekitar 26 piksel + 2).
const RINTANGAN_SERU_ATAS_PX: int = 28
## Kebal sesudah bangun dari jatuh: sprite pemain berkedip, lama satu fase kedip, detik.
const TABRAKAN_KEDIP_PERIODE_DETIK: float = 0.1
## Alpha sprite pemain pada fase redup kedip kebal.
const TABRAKAN_KEDIP_ALFA: float = 0.5
## Kaki ikon kilatan tabrakan di atas titik pijak pemain selama jatuh, piksel game (di atas kepala sprite 46x58, titik pijak y 46).
const TABRAKAN_IKON_ATAS_PX: int = 50
## Tombol bel: sisi persegi gambar, piksel game (DESIGN_SPEC 3.8: 40x40).
const BEL_TOMBOL_UKURAN_PX: int = 40
## Pusat tombol dan zona tap bel dari tepi layar sisi tombol, piksel game: x lebar - 64, kidal x 64 (usulan; masukan uji pemilik 2026-10-17: pojok susah dijangkau jempol).
const BEL_TOMBOL_PUSAT_SAMPING_PX: int = 64
## Pusat tombol dan zona tap bel dari tepi bawah, piksel game: y 360 - 64 = 296, kanan dan kidal (usulan, sekitar 1,2 cm dari tepi di vivo V2108).
const BEL_TOMBOL_PUSAT_BAWAH_PX: int = 64
## Jari-jari zona tap bel dari pusat tombol, piksel game (inklusif); sentuhan yang DIMULAI di sini membunyikan bel, bukan swipe.
const BEL_ZONA_RADIUS_PX: float = 28.0
## Jumlah frame jeda tombol bel di `assets/sprites/ui/ui_bel_tombol.png` (cincin n/8 sampai 1/8, sesudah frame diam dan ditekan).
const BEL_TOMBOL_JEDA_LANGKAH: int = 8
## Efek "kring": laju frame garis getar dan naik teks, frame per detik (DESIGN_SPEC 3.8: 12 fps).
const BEL_EFEK_FPS: float = 12.0
## Efek "kring": jumlah frame garis getar (`ui_bel_getar.png`).
const BEL_GETAR_FRAME: int = 4
## Titik jangkar garis getar di sel 16x16 `ui_bel_getar.png` (titik bel), piksel: x lalu y (`ui_bel.json`).
const BEL_GETAR_JANGKAR_PX: Array[int] = [3, 12]
## Titik bel relatif titik pijak sprite pemain, piksel game: x lalu y (dari `santai_normal` (31, 17) di `docs/design/bel/bell_anchors.json` dikurangi titik pijak (23, 46)); satu titik untuk semua animasi (usulan).
const BEL_TITIK_PX: Array[int] = [8, -29]
## Teks "KRING!": pojok kiri bawah teks relatif titik bel, piksel game: x lalu y (README bel: 11 ke kanan, 12 ke atas).
const BEL_TEKS_GESER_PX: Array[int] = [11, -12]
## Teks "KRING!" naik 1 piksel per frame efek, paling banyak sekian piksel.
const BEL_TEKS_NAIK_MAKS_PX: int = 4
## Alpha teks "KRING!" pada frame terakhirnya (versi redup sebelum hilang).
const BEL_TEKS_REDUP_ALFA: float = 0.6
## Panel skor HUD dev: jarak tepi luar panel dari tepi layar sisi swipe, piksel game (strip atas; tombol "Main lagi" 96 + margin 8 + jarak 8 di sisi itu).
const HUD_SKOR_GESER_PX: int = 112
## Label "PUTUS" tampil sekian detik sesudah combo putus (tabrakan atau antaran tidak sah), dt efektif.
const HUD_COMBO_PUTUS_DETIK: float = 0.8
## Umpan balik melayang (DESIGN_SPEC 3.6): lama tampil, detik.
const UMPAN_MELAYANG_DETIK: float = 0.8
## Umpan balik melayang: naik sekian piksel game selama tampil.
const UMPAN_MELAYANG_NAIK_PX: int = 12
## Umpan balik melayang: paling banyak sekian sekaligus; yang lama hilang lebih dulu.
const UMPAN_MELAYANG_MAKS: int = 2
## Umpan balik melayang: kaki teks di atas titik mendarat saat muncul, piksel game (di atas penanda 7 + 9 px).
const UMPAN_MELAYANG_ATAS_PX: int = 18
## Tebal garis luar teks di dunia (teks "KRING!", umpan balik melayang), piksel game: terbaca di atas aspal dan rumput.
const HUD_TEKS_GARIS_PX: int = 2
## Panel skor HUD dev: lebar minimum, piksel game (angka skor dan koin berubah tanpa membuat panel melompat).
const HUD_SKOR_LEBAR_PX: int = 72

## --- Tenggat rute (BALANCING 6, GDD 5.1; K-1 run fase3c-hud-hasil; usulan, dinilai lewat uji HP) ---
## Tenggat (detik) = ceil(panjang rute / `KECEPATAN_SANTAI_UD` x `TENGGAT_PENGALI`), dihitung dari rute (`TenggatRute`), bukan angka tetap.
## Jam berjalan dengan dt efektif (beku saat jeda) dan berhenti di garis akhir. Sesudah tenggat lewat rute tetap berjalan; hanya tip hilang.

## Pengali waktu tempuh santai untuk tenggat (BALANCING 6: santai terus masih sempat, berhenti lama terasa).
const TENGGAT_PENGALI: float = 1.15
## Toleransi derau float tenggat, detik: pembulatan ke atas (240 / 3,0 x 1,15 tetap 92) dan batas "lewat" (tepat di tenggat belum lewat).
const TENGGAT_TOLERANSI_DETIK: float = 0.000001
## Detik per menit untuk tampilan waktu "m:ss".
const WAKTU_DETIK_PER_MENIT: int = 60
## Jumlah angka per kelompok pemisah ribuan ("1.250", DESIGN_SPEC 3.3).
const ANGKA_KELOMPOK_RIBUAN: int = 3

## --- Radar (GDD 4.3, DESIGN_SPEC 3.4; K-2, O-9, O-10 run fase3c-hud-hasil; usulan, dinilai lewat uji HP) ---
## Strip kiri = sisi `seberang`, strip kanan = sisi `dekat` (sisi dunia, kidal tidak menukar). Jarak rumah = jarak maju dari sepeda ke pusat
## zona kotak suratnya. Atas strip = jauh (`RADAR_JANGKAUAN_UBIN` di depan), bawah = dekat sepeda.

## Jangkauan radar ke depan, ubin (K-2; sama dengan jendela daur rumah, sekitar 5 detik ngebut dan 10 detik santai). Kelak bisa upgrade.
const RADAR_JANGKAUAN_UBIN: float = 30.0
## Strip radar: jarak tepi luar strip dari tepi layar kiri atau kanan, piksel game (DESIGN_SPEC 3.4: x 4).
const RADAR_TEPI_PX: int = 4
## Strip radar: lebar termasuk garis luar, piksel game (DESIGN_SPEC 3.4).
const RADAR_LEBAR_PX: int = 12
## Strip radar: tepi atas dari atas layar, piksel game (DESIGN_SPEC 3.4: y 10).
const RADAR_Y_ATAS_PX: int = 10
## Strip radar: tepi bawah dari atas layar, piksel game (DESIGN_SPEC 3.4: y 182; zona stick mulai y 186).
const RADAR_Y_BAWAH_PX: int = 182
## Strip radar: tebal bingkai 9-slice `ui_radar_strip_9slice.png` (fakta aset `tools/ui_art/hud_ikon.py`), piksel game.
const RADAR_BINGKAI_PX: int = 2
## Penanda radar biasa: lebar dan tinggi, piksel game (`ui_radar_<jenis>.png` 8x6).
const RADAR_PENANDA_LEBAR_PX: int = 8
## Lihat `RADAR_PENANDA_LEBAR_PX`.
const RADAR_PENANDA_TINGGI_PX: int = 6
## Penanda "masuk jangkauan lempar" membesar sekian piksel game (`ui_radar_<jenis>_jangkau.png` 10x8, garis luar `TEXT`, O-10).
const RADAR_JANGKAU_TAMBAH_PX: int = 2

## --- HUD rute final (DESIGN_SPEC 1.3, 3.2, 3.3; O-6 sampai O-8, O-12 run fase3c-hud-hasil; usulan, dinilai lewat uji HP) ---

## Panel progres tengah atas: lebar, piksel game (DESIGN_SPEC 3.2).
const HUD_PROGRES_LEBAR_PX: int = 260
## Panel progres: sisi satu kotak pelanggan, piksel game (DESIGN_SPEC 3.2: 8x8 untuk 25 pelanggan).
const HUD_PROGRES_KOTAK_PX: int = 8
## Panel progres: jarak antar kotak, piksel game (25 kotak = 248 px).
const HUD_PROGRES_JARAK_PX: int = 2
## Panel progres: isi ke tepi kiri dan kanan, piksel game (6, bukan 7: 248 px kotak harus muat di panel 260).
const HUD_PROGRES_PAD_X_PX: int = 6
## Kotak pelanggan menjadi "terlewat" bila kotak suratnya LEBIH dari sekian ubin di belakang sepeda tanpa terantar (O-12; tepat 3,0 = belum).
const HUD_PROGRES_TERLEWAT_UBIN: float = 3.0
## Panel koin dan skor kanan atas: tepi kanan dari tepi layar, piksel game (DESIGN_SPEC 3.3: kanan 28, di luar strip radar).
const HUD_KANAN_MARGIN_PX: int = 28
## Jarak antar panel HUD, piksel game (DESIGN_SPEC 1.3).
const HUD_PANEL_JARAK_PX: int = 5
## Ikon HUD (koin), sisi persegi, piksel game (DESIGN_SPEC 1.3: 14x14).
const HUD_IKON_PX: int = 14
## Panel HUD 9-slice `ui_panel_hud_9slice.png`: tebal tepi 9-slice (fakta aset `tools/ui_art/hud_ikon.py`), piksel game.
const HUD_PANEL_9SLICE_PX: int = 4
## Zona aman (`ZonaAman`): toleransi derau float saat membulatkan inset layar ke piksel game ke atas, piksel game.
const ZONA_AMAN_TOLERANSI_PX: float = 0.000001

## --- Layar hasil (DESIGN_SPEC 4, rule ui-scenes; O-11, O-12 run fase3c-hud-hasil; usulan, sketsa) ---

## Layar hasil terbuka sesudah garis akhir bila kecepatan sepeda paling tinggi sekian u/d (sudah berhenti) dan tidak ada koran terbang.
const HASIL_BERHENTI_TOLERANSI_UD: float = 0.000001
## Tinggi dan lebar minimum bilah milestone, tebal garis luarnya (piksel game di tiap sisi). Bilah di kartu target layar hasil.
const HASIL_BILAH_TINGGI_PX: int = 7
const HASIL_BILAH_LEBAR_MIN_PX: int = 60
const HASIL_BILAH_TEPI_PX: int = 1

## --- Layar hasil sebagai struk antaran (run ui2-semua-layar bagian A; kanvas Hasil.dc.html dan Hasil_*.dc.html, README redesain 3 butir 6 dan 4; usulan, dinilai di HP) ---
## Margin layar minimum (dipakai max dengan inset aman), tinggi baris judul (struk dan kolom samping berada di margin atas + ini; kanvas y 44 = 12 + 32), dan jarak struk ke kolom samping, piksel game.
const HASIL_MARGIN_PX: int = 12
const HASIL_BARIS_ATAS_PX: int = 32
const HASIL_STRUK_KOLOM_JARAK_PX: int = 10
## Kolom samping dimulai sekian piksel di bawah margin atas (32 = sejajar dengan struk di kanvas; 0 = sejajar dengan judul bila kolom terpadat tidak muat di atas tombol aksi).
const HASIL_KOLOM_ATAS_PX: int = 32
## Lebar struk tanpa kolom samping (rute yang dijalankan sendiri; struk ke tengah), lebar kolom samping (reputasi, pelanggan, milestone) di lebar 640 dan di lebar >= `HASIL_LEBAR_LEBAR_MIN_PX`.
const HASIL_STRUK_TANPA_SAMPING_PX: int = 360
const HASIL_KOLOM_LEBAR_PX: int = 236
const HASIL_KOLOM_LEBAR_LEBAR_PX: int = 300
const HASIL_LEBAR_LEBAR_MIN_PX: int = 800
## Struk: jarak isi ke tepi luar (sudah termasuk tepi 9-slice 4: kanvas padding 8 samping, 6 atas, 8 bawah; bawah 10 supaya kasus terpadat muat dengan inset aman bawah 20), jarak antar baris, jarak antar kelompok angka Terkirim dan Koin, tinggi baris garis sobek, tinggi minimum baris label-nilai, piksel game.
const HASIL_STRUK_PAD_X_PX: int = 12
const HASIL_STRUK_PAD_ATAS_PX: int = 10
const HASIL_STRUK_PAD_BAWAH_PX: int = 10
const HASIL_STRUK_JARAK_PX: int = 2
const HASIL_ANGKA_JARAK_PX: int = 16
const HASIL_SOBEK_TINGGI_PX: int = 14
const HASIL_BARIS_TINGGI_PX: int = 15
## Garis sobek: lebar dan tinggi takik tiket (`ui_struk_takik.png`), jarak garis putus-putus dari tepi struk, panjang goresan dan celahnya; garis titik-titik penuntun baris: jarak dari dasar baris dan jarak antar titik, piksel game.
const HASIL_TAKIK_LEBAR_PX: int = 6
const HASIL_TAKIK_TINGGI_PX: int = 10
const HASIL_SOBEK_TEPI_PX: int = 6
const HASIL_SOBEK_GORES_PX: int = 3
const HASIL_TITIK_DASAR_PX: int = 5
const HASIL_TITIK_JARAK_PX: int = 2
## Ikon: koin di samping angka Koin, glif centang di samping Terkirim dan misi, bintang reputasi, lencana tingkat baru (24) dan lencana target (32), piksel game.
const HASIL_IKON_BESAR_PX: int = 24
const HASIL_GLIF_PX: int = 12
const HASIL_LENCANA_TARGET_PX: int = 32
## Kartu di kolom samping: jarak antar kartu, jarak antar baris di dalam kartu, tinggi kartu reputasi, jarak isi kartu ke garis (di luar tepi 4), jarak antar baris tingkat baru, piksel game.
const HASIL_KARTU_JARAK_PX: int = 3
const HASIL_KARTU_BARIS_JARAK_PX: int = 2
const HASIL_KARTU_REPUTASI_PX: int = 40
const HASIL_KARTU_PAD_PX: int = 2
const HASIL_BARU_JARAK_PX: int = 2
## Paling banyak sekian kali tata letak layar hasil ditata ulang per frame karena ukuran struk atau kolom samping berubah (bungkus kata menentukan tinggi sesudah Container selesai; mencegah berputar).
const HASIL_SUSUN_ULANG_MAKS: int = 8
## Jarak minimum kolom samping ke tombol aksi di bawahnya, piksel game.
const HASIL_KOLOM_TOMBOL_JARAK_PX: int = 6

## --- Hari, seed, dan save (Fase 4 run 4A, DATA_SCHEMA 4, rule save-system; usulan, alur hari berurutan ini prototype yang tidak mengunci struktur sesi ROADMAP 5) ---

## Hari pertama yang dimainkan (`hari` di save = hari yang akan dimainkan berikutnya, S-3).
const HARI_AWAL: int = 1
## Langkah seed antar hari: seed hari N = dasar + N x langkah (bilangan prima besar supaya seed hari berdekatan tidak mirip).
const SEED_HARI_LANGKAH: int = 1000003
## Seed dasar rute harian (`SeedHari.rute`); rute dev tetap `RUTE_SEED_DEV`.
const SEED_RUTE_DASAR: int = 20261100
## Selisih seed misi dari seed rute hari itu (`SeedHari.misi`, `RencanaMisi`): rencana kucing punya aliran acak sendiri dan tidak mengubah rute.
const SEED_MISI_SELISIH: int = 4093
## Seed dasar headline harian (`SeedHari.headline`, `HeadlineManager`).
const SEED_HEADLINE_DASAR: int = 31415926
## Seed dasar kerusakan tabrakan harian (`SeedHari.kondisi`, `BikeCondition.komponen_tabrakan`, run 6A1): aliran acak sendiri, tidak mengubah rute atau headline.
const SEED_KONDISI_DASAR: int = 27182818
## Langkah seed antar tabrakan dalam satu rute (seed tabrakan ke-n = seed kondisi hari itu + n x langkah), bilangan prima.
const SEED_KONDISI_NOMOR_LANGKAH: int = 7907
## Selisih seed antar slot halaman koran (utama, misi, ringan) supaya tiap slot punya aliran acak sendiri.
const SEED_HEADLINE_SLOT_LANGKAH: int = 7919
## Versi format save (DATA_SCHEMA 4); naik bersama langkah migrasi di `DataSave.migrasi`. v2 (run 4B): arti `flag` berubah (menunggu tampil, dikonsumsi), `misi_hasil`, `tutorial`. v3 (run 6A1): `koin` menjadi saldo, `koin_total`, `sepeda`. v4 (run 6A2): `reputasi` per distrik dan `pelanggan` (status pelanggan tetap).
const SAVE_VERSI: int = 4
## Berkas save (satu slot, rule save-system); ditulis atomik lewat berkas sementara di folder yang sama.
const SAVE_BERKAS: String = "user://save.json"
## Ekstensi berkas sementara penulisan atomik (`user://save.tmp`).
const SAVE_SEMENTARA_EKSTENSI: String = "tmp"
## Penanda nama salinan save rusak: `user://save.corrupt.<detik unix>.json`.
const SAVE_RUSAK_PENANDA: String = ".corrupt."
## Batas atas bilangan di save (hari, koin, skor, jeda): nilai lebih besar dijepit, bukan crash.
const SAVE_ANGKA_MAKS: int = 2000000000
## Volume suara dan musik bawaan dan batasnya (0 sampai 1); belum dipakai di 4A.
const SAVE_VOLUME_BAWAAN: float = 1.0
## Batas bawah volume di save.
const SAVE_VOLUME_MIN: float = 0.0
## Batas atas volume di save.
const SAVE_VOLUME_MAKS: float = 1.0

## --- Headline dan misi (DATA_SCHEMA 1 dan 2, CONTENT_GUIDE 2 dan 3; run 4A, usulan) ---

## Panjang maksimal headline (berita utama, ringan, lanjutan, dan judul misi), karakter teks terjemahan.
const HEADLINE_PANJANG_MAKS: int = 40
## Panjang maksimal ringkasan misi satu baris di layar koran, karakter.
const MISI_RINGKASAN_PANJANG_MAKS: int = 60
## Panjang maksimal label HUD misi, karakter.
const MISI_HUD_PANJANG_MAKS: int = 14
## Panjang maksimal petunjuk dari pelanggan, karakter.
const MISI_PETUNJUK_PANJANG_MAKS: int = 50
## Panjang maksimal banner selesai dan banner gagal di rute, karakter teks terjemahan (CONTENT_GUIDE 3).
const MISI_BANNER_PANJANG_MAKS: int = 24
## Kata penghubung yang boleh huruf kecil di tengah headline (CONTENT_GUIDE 2).
const HEADLINE_KATA_PENGHUBUNG: Array[String] = ["di", "ke", "dari", "dan", "yang", "untuk", "pada"]
## Bobot headline paling kecil (peluang relatif, bilangan bulat).
const HEADLINE_BOBOT_MIN: int = 1
## Dua tanda seru berturut-turut ditolak di headline (CONTENT_GUIDE 2).
const HEADLINE_TANDA_SERU_BERUNTUN: String = "!!"
## Kunci efek dunia berita utama (GDD 10.7); arti efek di kode (Fase 7), di 4A hanya dicatat (S-5).
const EFEK_DUNIA_DIKENAL: Array[String] = ["hajatan", "hujan_deras", "air_pasang", "tujuh_belasan", "pasar_kaget", "jalan_diperbaiki", "panen_raya", "mati_lampu"]
## Template misi (GDD 10.4).
const MISI_TEMPLATE_DIKENAL: Array[String] = ["cari", "antar_khusus", "lempar_khusus", "kumpul", "kejar", "jaga"]
## Tingkat hadiah misi (GDD 10.5).
const MISI_TINGKAT_HADIAH: Array[String] = ["kecil", "sedang", "besar"]
## Distrik yang dikenal data (GDD 9.2).
const DISTRIK_DIKENAL: Array[String] = ["perumahan", "perkampungan", "ruko", "pasar", "desa", "sungai"]
## Distrik yang dimainkan di 4A.
const DISTRIK_AWAL: String = "perumahan"
## Hari tutorial (STORY 6): slot misi hari ini selalu misi tutorial.
const MISI_HARI_TUTORIAL: int = 1
## Id misi tutorial (P1 Kucing Bu Ratmi, GDD 10.6).
const MISI_ID_TUTORIAL: String = "p1_kucing"
## Reputasi pemain di 4A (reputasi belum ada, Fase 6A): dipakai syarat `rep_min` misi.
const REPUTASI_BAWAAN: int = 0

## --- Pelanggan tetap, kepribadian, dan reputasi (run 6A2 bagian A, GDD 8 dan 10.5, BALANCING 7.2; semua usulan, dinilai lewat uji HP) ---

## Reputasi per distrik, bilangan bulat: batas bawah, batas atas, dan nilai awal save baru.
const REPUTASI_MIN: int = 0
const REPUTASI_MAKS: int = 100
const REPUTASI_AWAL: int = 0
## Kredit reputasi satu antaran sah menurut kualitasnya (poin kredit, bukan poin reputasi): tepat di inti kotak surat, teras, kotak surat, halaman (rumput). Pelanggan `cerewet` tidak memberi kredit untuk halaman.
const REPUTASI_KREDIT_TEPAT: int = 4
const REPUTASI_KREDIT_TERAS: int = 3
const REPUTASI_KREDIT_KOTAK_SURAT: int = 2
const REPUTASI_KREDIT_HALAMAN: int = 1
## Poin kredit satu hari per 1 poin reputasi (pembagian bulat ke bawah, tanpa sisa yang dibawa ke hari lain).
const REPUTASI_KREDIT_PER_POIN: int = 30
## Poin reputasi misi selesai menurut tingkat hadiah, sejajar dengan `MISI_TINGKAT_HADIAH` (kecil, sedang, besar; GDD 10.5).
const REPUTASI_MISI_POIN: Array[int] = [1, 2, 3]
## Poin reputasi yang hilang per pelanggan yang berhenti hari itu.
const REPUTASI_BERHENTI_POIN: int = 1
## Batas atas `gagal.reputasi` di data misi (GDD 10.5: paling berat satu poin).
const REPUTASI_MISI_GAGAL_MAKS: int = 1
## Kenaikan reputasi paling banyak dalam satu hari (kredit antaran + misi); pagar, bukan pembentuk kurva.
const REPUTASI_NAIK_MAKS_PER_HARI: int = 6
## Status pelanggan tetap yang sah di save dan penghitung paling besar (antar, meleset).
const PELANGGAN_STATUS: Array[String] = ["aktif", "setia", "berhenti"]
const PELANGGAN_HITUNG_MAKS: int = 999
## `aktif` menjadi `setia` sesudah sekian antaran sah (sejak masuk atau sejak kembali).
const PELANGGAN_SETIA_ANTAR: int = 5
## Pelanggan `sensitif` berhenti sesudah sekian hari berturut-turut tidak terantar saat masuk rute; pelanggan `setia` lebih sabar satu hari.
const PELANGGAN_BERHENTI_MELESET: int = 2
const PELANGGAN_SETIA_BERHENTI_MELESET: int = 3
## Pelanggan `berhenti` boleh dipilih lagi ("calon kembali") sesudah sekian hari sejak berhenti, paling banyak sekian per rute (ikut dihitung dalam 25).
const PELANGGAN_KEMBALI_JEDA_HARI: int = 3
const PELANGGAN_KEMBALI_MAKS_PER_RUTE: int = 1
## Pelanggan `setia` diprioritaskan sampai sekian persen kuota tiap sisi; pelanggan baru (belum pernah masuk rute) paling banyak sekian per rute bila pelanggan dikenal cukup.
const PELANGGAN_SETIA_MAKS_PERSEN: int = 60
const PELANGGAN_BARU_MAKS_PER_RUTE: int = 6
## Kandidat dikenal (bukan berhenti, sudah pernah masuk rute) per sisi harus paling sedikit kuota sisi + sekian supaya batas pelanggan baru berlaku di sisi itu.
const PELANGGAN_KANDIDAT_CADANGAN: int = 4
## Percobaan pencocokan per tingkat pelepasan prioritas di `RouteBuilder` dengan keadaan pelanggan.
const PELANGGAN_PERCOBAAN_PER_TINGKAT: int = 60
## Prioritas pelanggan dilepas bertahap: tiap tingkat melepas 1/sekian dari daftar prioritas (paling sedikit satu).
const PELANGGAN_LEPAS_PEMBAGI: int = 4
## Bonus biaya (ubin) bagi pelanggan prioritas (setia, calon kembali) dalam pencocokan: jauh di atas selisih terbesar mana pun, jadi mereka selalu terpilih selama ada susunan sah.
const PELANGGAN_BONUS_PRIORITAS_UBIN: float = 1000000.0
## Id kepribadian pelanggan (permanen) dan berkas datanya (`assets/data/customers/kepribadian.json`, DATA_SCHEMA 4b).
const PELANGGAN_KEPRIBADIAN_ID: Array[String] = ["biasa", "cerewet", "pemberi_tip", "sensitif"]
const PELANGGAN_KEPRIBADIAN_BERKAS: String = "res://assets/data/customers/kepribadian.json"

## --- Milestone dasar (run 6A2 bagian C, O-9, GDD 8 dan 13, BALANCING 7.4; semua usulan, tanpa hadiah kosmetik; progres diturunkan dari save, tanpa field save baru) ---

## Id milestone (permanen; urutan juga menjadi pemutus seri terakhir "paling dekat tercapai") dan nama tiga tingkatnya (perunggu, perak, emas).
const MILESTONE_ID: Array[String] = ["pelanggan_tetap", "koin_total", "misi_selesai", "sepeda"]
const MILESTONE_TINGKAT: Array[String] = ["perunggu", "perak", "emas"]
## Target tiap tingkat (menaik): jumlah pelanggan `setia`; `koin_total` seumur hidup; misi dengan hasil `selesai` di `misi_hasil`; `servis_total` + jumlah level upgrade sepeda.
const MILESTONE_TARGET_PELANGGAN_TETAP: Array[int] = [3, 10, 25]
const MILESTONE_TARGET_KOIN_TOTAL: Array[int] = [1000, 5000, 15000]
const MILESTONE_TARGET_MISI_SELESAI: Array[int] = [1, 3, 5]
const MILESTONE_TARGET_SEPEDA: Array[int] = [1, 4, 10]
## Layar hasil menampilkan paling banyak sekian tingkat yang baru tercapai hari itu (tertinggi dulu, lalu urutan `MILESTONE_ID`); sisanya tetap tercatat di progres.
const MILESTONE_BARU_MAKS_TAMPIL: int = 3
## Volume bunyi milestone tercapai, dB (lembut: sekitar 4 dB di bawah bunyi misi selesai yang sudah -3, tidak menutupi bunyi lain).
const AUDIO_MILESTONE_VOLUME_DB: float = -4.0

## --- Layar halaman depan koran (DESIGN_SPEC 4, 1.2; rule ui-scenes; run 4A, usulan; dinilai lewat uji HP; tata ulang run ui2-semua-layar bagian B dari kanvas Koran*.dc.html) ---

## Tepi layar koran ke isi, piksel game (sebelum zona aman).
const KORAN_MARGIN_PX: int = 12
## Jarak antar blok di kolom misi, piksel game (kanvas: gap 5).
const KORAN_MISI_JARAK_PX: int = 5
## Jarak antar blok di kolom berita, piksel game (kanvas: gap 6).
const KORAN_BERITA_JARAK_PX: int = 6
## Lebar kolom misi di lebar viewport < `KORAN_LEBAR_LEBAR_MIN_PX` dan di lebar >= itu (kanvas: 236 dan 280).
const KORAN_MISI_LEBAR_PX: int = 236
const KORAN_MISI_LEBAR_LEBAR_PX: int = 280
const KORAN_LEBAR_LEBAR_MIN_PX: int = 800
## Jarak kolom berita ke garis tegak dan garis tegak ke kolom misi (kanvas: 6 + garis 1 + 6), dan tebal garis tegak.
const KORAN_KOLOM_JARAK_PX: int = 6
const KORAN_GARIS_TEGAK_PX: int = 1
## Garis ganda di bawah kepala (kanvas `.k-ganda`): garis atas 2, celah 1, garis bawah 1 (tinggi total 4), dan jarak kepala ke garis dan garis ke isi.
const KORAN_GANDA_ATAS_PX: int = 2
const KORAN_GANDA_CELAH_PX: int = 1
const KORAN_GANDA_BAWAH_PX: int = 1
const KORAN_GANDA_JARAK_PX: int = 6
## Kepala: nama koran Lilita One 32 (tinggi baris 38) dinaikkan sekian px ke atas margin (seperti kanvas: kotak baris 33,6 px berpusat di glif) dan jarak ke garis ganda; sehingga garis ganda jatuh di y 46 (margin 12 + 34) seperti kanvas.
const KORAN_KEPALA_NAIK_PX: int = 5
const KORAN_KEPALA_BAWAH_PX: int = 1
## "Hari N · Perumahan Melati" diturunkan sekian px dari tepi atas kepala supaya garis dasarnya sejajar nama koran (kanvas: top 26 di margin 12 + 13).
const KORAN_HARI_TURUN_PX: int = 13
## Jarak antar baris label bungkus kata (tambahan di atas tinggi huruf; bawaan Godot 3): headline Lilita One 24 dan 16 dirapatkan seperti kanvas (tinggi baris 1,05 em), teks Lexend 11 sedikit rapat.
const KORAN_JARAK_BARIS_UTAMA_PX: int = -3
const KORAN_JARAK_BARIS_JUDUL_PX: int = -2
const KORAN_JARAK_BARIS_TEKS_PX: int = 1
## Foto berita utama 100x62 dan jarak foto ke headline (kanvas: gap 8).
const KORAN_FOTO_LEBAR_PX: int = 100
const KORAN_FOTO_TINGGI_PX: int = 62
const KORAN_FOTO_JARAK_PX: int = 8
## Efek berita utama yang punya foto dan ikon 24 (urutan sejajar; efek lain tanpa foto dan tanpa ikon: "jalan dan lampu dulu", Spesifikasi.dc.html).
const KORAN_EFEK_FOTO: Array[String] = ["jalan_diperbaiki", "mati_lampu"]
const KORAN_NAMA_FOTO: Array[String] = ["foto_jalan", "foto_lampu"]
const KORAN_NAMA_IKON: Array[String] = ["icon24_kerucut", "icon24_bohlam"]
## Ikon 24 di judul bagian (berita utama, misi) dan jarak ikon ke label.
const KORAN_IKON_PX: int = 24
const KORAN_IKON_JARAK_PX: int = 6
## Isi kotak misi 9-slice (tepi `UI_PANEL_SLICE_PX` sudah termasuk): samping, atas, bawah (kanvas: padding 4 6 6 di dalam bingkai 4).
const KORAN_PANEL_PAD_X_PX: int = 10
const KORAN_PANEL_PAD_ATAS_PX: int = 8
const KORAN_PANEL_PAD_BAWAH_PX: int = 10
## Jarak antar tombol Ambil dan Lewati.
const KORAN_TOMBOL_JARAK_PX: int = 6
## Kotak hiasan "Iklan baris" di bawah kolom berita: lebar paling besar, tinggi tetap, tinggi paling kecil supaya label dan satu baris hiasan muat (selain itu kotak tidak tampil), isi samping dan atas bawah, panjang goresan garis putus.
const KORAN_IKLAN_LEBAR_MAKS_PX: int = 220
const KORAN_IKLAN_TINGGI_PX: int = 54
const KORAN_IKLAN_TINGGI_MIN_PX: int = 28
const KORAN_IKLAN_PAD_X_PX: int = 6
const KORAN_IKLAN_PAD_Y_PX: int = 4
const KORAN_IKLAN_GORES_PX: int = 3
## Garis hiasan pengganti teks (kanvas: batang 2 px KORAN_KERTAS_2): tinggi, jarak antar baris, jarak antar kolom, dan lebar tiap batang (pecahan dari lebar kolomnya, kiri ke kanan lalu ke bawah, dua kolom).
const KORAN_HIASAN_TINGGI_PX: int = 2
const KORAN_HIASAN_JARAK_BARIS_PX: int = 3
const KORAN_HIASAN_JARAK_KOLOM_PX: int = 10
const KORAN_HIASAN_POLA: Array[float] = [1.0, 1.0, 1.0, 0.8, 0.6, 1.0]
## Kotak notifikasi save: tinggi paling kecil, isi samping dan atas bawah, jarak glif ke teks (kanvas: 42, padding 5 6, gap 4).
const KORAN_NOTIF_TINGGI_MIN_PX: int = 42
const KORAN_NOTIF_PAD_X_PX: int = 6
const KORAN_NOTIF_PAD_Y_PX: int = 5
const KORAN_NOTIF_JARAK_PX: int = 4
## Kontras minimum teks terhadap latar di layar koran (rumus WCAG, rasio).
const KORAN_KONTRAS_TEKS_MIN: float = 7.0
## Kontras minimum garis tombol dan panel terhadap latar (komponen UI, WCAG 1.4.11).
const KORAN_KONTRAS_GARIS_MIN: float = 3.0

## --- Misi P1 kucing, template Cari (GDD 10.2 sampai 10.6, DATA_SCHEMA 1; run 4B, usulan, dinilai lewat uji HP) ---

## Nama titik tempat kucing berada di data langkah misi Cari (tampilan placeholder sama untuk semuanya, M-10).
const MISI_TITIK_DIKENAL: Array[String] = ["atap", "bawah_mobil_tamu", "balik_pot"]
## Jenis langkah misi Cari: `lihat` selalu bisa diselesaikan, `tangkap` butuh menepi dan berhenti.
const MISI_LANGKAH_JENIS_DIKENAL: Array[String] = ["lihat", "tangkap"]
## Objek target misi Cari yang dikenal.
const MISI_TARGET_OBJEK_DIKENAL: Array[String] = ["kucing"]
## Sisi target misi yang didukung `RencanaMisi`: hanya `seberang` (kucing selalu di rumah sisi seberang). `dekat` ditolak validasi sampai didukung (QA-006).
const MISI_SISI_DIKENAL: Array[String] = ["seberang"]
## Penanda visual petunjuk misi yang dikenal.
const MISI_PETUNJUK_VISUAL_DIKENAL: Array[String] = ["kilau", "ekor"]
## Isyarat suara petunjuk misi yang dikenal.
const MISI_PETUNJUK_SUARA_DIKENAL: Array[String] = ["meong"]
## Koin hadiah per tingkat, sejajar dengan `MISI_TINGKAT_HADIAH` (kecil, sedang, besar; GDD 10.5 dan 14.1, 45 / 75 / 120). Dibayar saat misi selesai (K-1).
const MISI_HADIAH_KOIN: Array[int] = [45, 75, 120]
## Jarak maju kucing mulai tampil (penanda tepi layar dan badan) di depan pemain tanpa petunjuk, ubin (M-2'): 14 ubin / `KECEPATAN_NGEBUT_UD` 6,0 = 2,33 detik, sedikitnya
## `MISI_TAMPIL_DETIK_MIN` + `MISI_TAMPIL_CADANGAN_DETIK`. Iterasi 1 memakai 12 (tepat 2,0 detik di koordinat dunia, kurang dari itu di layar: QA-001).
const MISI_TAMPIL_JARAK_UBIN: float = 14.0
## Jarak maju kucing mulai tampil bila pemain mendapat petunjuk dari lemparan tepat, ubin (M-3'): 22 ubin, sedikitnya `MISI_PETUNJUK_TAMBAH_DETIK_MIN` +
## `MISI_TAMPIL_CADANGAN_DETIK` lebih awal dari `MISI_TAMPIL_JARAK_UBIN` pada ngebut. Iterasi 1 memakai 18 (tambahan nyata di layar nyaris nol: QA-002).
const MISI_TAMPIL_PETUNJUK_JARAK_UBIN: float = 22.0
## Waktu terlihat minimum kucing (penanda tepi layar atau badan) pada kecepatan ngebut, detik (prinsip 3: petunjuk misi punya penanda visual minimal 2 detik).
const MISI_TAMPIL_DETIK_MIN: float = 2.0
## Tambahan waktu terlihat minimum karena petunjuk dari lemparan tepat pada kecepatan ngebut, detik (M-3', usulan).
const MISI_PETUNJUK_TAMBAH_DETIK_MIN: float = 1.0
## Cadangan di atas kedua minimum itu, detik: selisih satu langkah waktu lambat (bingkai turun ke 30 fps), kecepatan sesaat, dan bulat piksel (usulan).
const MISI_TAMPIL_CADANGAN_DETIK: float = 0.25
## Kecepatan maju paling tinggi saat menangkap, u/d (M-4; sama dengan `KECEPATAN_MELAMBAT_UD`: tingkat meluncur, tanpa tombol baru).
const MISI_TANGKAP_KECEPATAN_MAKS_UD: float = 1.5
## Toleransi presisi tunggal saat membandingkan kecepatan dan lama berhenti dengan ambangnya.
const MISI_TANGKAP_TOLERANSI: float = 0.000001
## Lama banner selesai atau gagal tampil, detik (DESIGN_SPEC 3.1, CONTENT_GUIDE 3).
const MISI_BANNER_DETIK: float = 1.5
## Lama gelembung teks petunjuk dari pelanggan tampil, detik (prinsip 3: sedikitnya 2 detik).
const MISI_PETUNJUK_DETIK: float = 2.5
## Letak kucing di rumah titik: lateral dari garis tengah jalan (negatif = seberang), ubin (di trotoar, di depan pagar rumah).
const MISI_KUCING_LATERAL_UBIN: float = -2.0
## Letak kucing di rumah titik: jarak maju dari awal kavling rumah, ubin (sebelum zona kotak surat yang mulai di 1,25).
const MISI_KUCING_MAJU_UBIN: float = 0.5
## Goyangan acak berseed letak kucing: lateral +- sekian ubin (satu langkah ke tiap arah atau tidak sama sekali).
const MISI_KUCING_GOYANG_LATERAL_UBIN: float = 0.25
## Goyangan acak berseed letak kucing: maju +- sekian ubin. Tetap di kiri zona kotak surat (maju + 0,75 + setengah sisi < 1,25).
const MISI_KUCING_GOYANG_MAJU_UBIN: float = 0.25
## Sisi persegi kucing di tanah (untuk memeriksa tidak menimpa zona kotak surat), ubin.
const MISI_KUCING_PERSEGI_UBIN: float = 0.75
## Kilau di sekitar kucing berkedip tiap sekian detik (dua frame dari kode).
const MISI_KILAU_DETIK: float = 0.4
## Ekor kucing bergoyang tiap sekian detik (dua frame dari kode).
const MISI_EKOR_DETIK: float = 0.5
## Kucing tidak boleh ditaruh di rumah seberang yang jarak majunya dari mobil garasi seberang kurang dari ini, ubin (mobil mundur menutup separuh jalan).
const MISI_KUCING_JAUH_MOBIL_UBIN: float = 6.0

## --- Kucing misi di rute (run 4B, M-10; sheet `assets/sprites/npc/mission_kucing_sheet.png` dari `tools/env_art/kendaraan.py --salin`, usulan) ---

## Ukuran satu sel sheet kucing misi, piksel (lebar, tinggi); sama dengan `cell` di `mission_kucing_sheet.json` (dijaga tes).
const MISI_KUCING_SEL_PX: Array[int] = [46, 38]
## Titik pijak kucing di dalam sel, piksel (sama dengan `ground_anchor` di JSON).
const MISI_KUCING_PIJAK_PX: Array[int] = [18, 21]
## Kolom dan baris sheet (9 pose x 4 arah moncong; kolom 7-8 = ditangkap_1/_2 sejak Fase 5C, usulan).
const MISI_KUCING_KOLOM: int = 9
const MISI_KUCING_BARIS: int = 4
## Kolom pose ditangkap (duduk tenang dielus, dua frame bergantian; `frames` 7 dan 8 = `anim.ditangkap` di JSON sheet, dijaga tes). Tampil selama langkah `tangkap` dengan progres > 0 (P-3 run 5C, usulan).
const MISI_KUCING_KOLOM_DITANGKAP: Array[int] = [7, 8]
## Laju pose ditangkap, frame per detik dari waktu animasi misi (membeku saat jeda); sama dengan `fps.ditangkap` di JSON sheet (dijaga tes).
const MISI_KUCING_DITANGKAP_FPS: float = 3.0
## Baris "masuk" (moncong kiri atas, menghadap rumah sisi seberang) dan kolom pose duduk: placeholder untuk semua titik (M-10: pose intip khusus ada di Fase 5).
const MISI_KUCING_BARIS_HADAP: int = 1
const MISI_KUCING_KOLOM_DUDUK: int = 0
## Tinggi kotak penutup kucing, ubin (kucing kecil: hampir tidak pernah menutupi pemain; tetap lewat penerap penutup yang sama dengan rumah).
const MISI_KUCING_TINGGI_UBIN: float = 0.5
## Pojok kiri atas kotak kilau 11x11 (frame 9x9 di tengahnya; tengah di atas titik pijak) relatif titik pijak kucing, piksel (di atas kepala).
const MISI_KILAU_POSISI_PX: Array[int] = [-5, -33]
## Pojok kiri atas pola ekor 5x4 relatif titik pijak kucing, piksel (di belakang badan).
const MISI_EKOR_POSISI_PX: Array[int] = [9, -10]
## Bar progres tangkap di atas kucing: lebar dan tinggi piksel, jarak di atas titik pijak.
const MISI_PROGRES_LEBAR_PX: int = 18
const MISI_PROGRES_TINGGI_PX: int = 4
const MISI_PROGRES_ATAS_PX: int = 20

## --- HUD misi di rute (DESIGN_SPEC 3.1, run 4B, usulan; dinilai lewat uji HP) ---

## Kartu misi: pojok kiri atas, piksel game dari tepi layar (sebelum zona aman). Di bawah area sentuh jeda (y 4 sampai 46), bukan di y 40 seperti sketsa.
const MISI_KARTU_X_PX: int = 26
const MISI_KARTU_Y_PX: int = 50
## Lebar minimum kartu misi, piksel game (sketsa DESIGN_SPEC: 145).
const MISI_KARTU_LEBAR_PX: int = 145
## Banner dan gelembung petunjuk: jarak dari tepi atas layar (di bawah panel progres yang berakhir sekitar y 41), tengah mendatar.
const MISI_BANNER_Y_PX: int = 50
## Lebar minimum teks gelembung petunjuk dari pelanggan, piksel game (teks panjang membungkus).
const MISI_PETUNJUK_LEBAR_PX: int = 170

## --- Penanda tepi layar kucing misi (run 4B iterasi 2, M-2' dan M-3', QA-001 dan QA-002, usulan; dinilai lewat uji HP) ---

## Sisi persegi penanda tepi layar (panah), piksel game. Non-interaktif, tanpa teks.
const MISI_PENANDA_UKURAN_PX: int = 11
## Jarak penanda dan badan kucing "terlihat" dari tepi layar kiri dan kanan, piksel game (strip radar berakhir 16 px dari tepi, sebelum zona aman).
const MISI_PENANDA_TEPI_PX: int = 22
## Batas atas penanda dan badan kucing "terlihat" dari tepi atas layar, piksel game (panel progres, koin, skor, dan kartu/banner/gelembung misi berakhir sebelum y 82).
const MISI_PENANDA_ATAS_PX: int = 84
## Batas bawah penanda dari tepi bawah layar, piksel game (di atas tombol bel dan panel bawah, yang mulai sekitar 84 px dari bawah).
const MISI_PENANDA_BAWAH_PX: int = 100
## Bila kaki kucing sendiri berada di dalam persegi pusat penanda, penanda ditaruh sekian piksel di bawah kaki (menunjuk ke atas ke kucing, tidak menutupi badan).
const MISI_PENANDA_TURUN_PX: int = 14
## Penanda berganti warna tiap sekian detik (dua keadaan dari kode; bentuk panah tetap, jadi tidak hanya warna).
const MISI_PENANDA_KEDIP_DETIK: float = 0.4

## --- Bunyi misi (SOUND_DESIGN 3.1 dan 4, run 4B; WAV dari `tools/audio_art/sintesis_misi.py`, usulan) ---

## Volume bunyi misi (meong, terlihat, selesai), dB di bus SFX.
const AUDIO_MISI_VOLUME_DB: float = -3.0
## Volume bunyi misi gagal, dB (lebih pelan: gagal berbunyi lembut, SOUND_DESIGN 2).
const AUDIO_MISI_GAGAL_VOLUME_DB: float = -5.0

## --- Tutorial terpandu hari 1 (M-9 run 4B, TECH_PLAN Fase 4, STORY 6; usulan, dinilai lewat uji HP) ---

## Langkah kayuh selesai bila kecepatan maju paling sedikit ini, u/d (kecepatan cepat: pemain mendorong stick ke atas).
const TUTORIAL_KAYUH_KECEPATAN_UD: float = 4.5
## Langkah melambat selesai bila kecepatan maju paling banyak ini, u/d (pemain menarik stick ke bawah dari santai 3,0).
const TUTORIAL_MELAMBAT_KECEPATAN_UD: float = 2.0
## Jumlah petunjuk dengan menepi (empat bila ada misi) dan tanpa misi (tiga).
const TUTORIAL_JUMLAH_LANGKAH_MISI: int = 4
const TUTORIAL_JUMLAH_LANGKAH_TANPA_MISI: int = 3
## Tombol Lewati: pojok kiri atas strip atas (di luar zona swipe, y < 48: tap di sini tidak pernah melempar di mode bantu), x dari tepi layar sebelum zona aman,
## lebar piksel game (tinggi `HUD_TOMBOL_TINGGI_PX` 42, >= 44 dp di A54). Di kanan area sentuh jeda (berakhir x 59) dan di kiri panel progres (mulai sekitar x 190 di 640).
const TUTORIAL_LEWATI_X_PX: int = 66
const TUTORIAL_LEWATI_LEBAR_PX: int = 64
## Panel petunjuk tutorial: pojok kiri atas dari tepi layar sebelum zona aman, di bawah kartu misi; lebar minimum teks piksel game.
const TUTORIAL_PANEL_X_PX: int = 26
const TUTORIAL_PANEL_Y_PX: int = 88
const TUTORIAL_PANEL_LEBAR_PX: int = 150

## --- Kondisi sepeda: ban, rem, rantai (GDD 12, BALANCING 8; run 6A1, usulan; dinilai lewat uji HP) ---
## Kondisi 0,0 (rusak total) sampai 1,0 (baru) per komponen. Tiga tingkat dari ambang: BAIK (>= `KONDISI_AMBANG_AUS`), AUS (tanda peringatan, efek masih nol),
## PERLU_BENGKEL (< `KONDISI_AMBANG_PERLU_BENGKEL`: efek menghambat naik pelan-pelan sampai nilai terburuk di kondisi 0). `BikeCondition` satu-satunya pemakai.
## Setang dan lampu dicadangkan sebagai id (belum dibuat, M-1); mode bantu tidak mengubah aus atau kerusakan (K-2).

## Id komponen permanen (M-1), urutan = urutan HUD dan bengkel. Larik angka di bawah (`SERVIS_HARGA_PENUH`, `KONDISI_TABRAKAN_BOBOT`) sejajar dengan larik ini.
const KONDISI_KOMPONEN: Array[String] = ["ban", "rem", "rantai"]
## Kondisi di bawah ini = AUS (tanda peringatan muncul). Harus lebih besar dari `KONDISI_AMBANG_PERLU_BENGKEL` (peringatan mendahului efek, prinsip 3).
const KONDISI_AMBANG_AUS: float = 0.7
## Kondisi di bawah ini = PERLU_BENGKEL ("!" di HUD) dan efek mulai menghambat. Di atas atau sama dengan ini efek tepat 1,0.
const KONDISI_AMBANG_PERLU_BENGKEL: float = 0.35
## Kotak kondisi di HUD (DESIGN_SPEC 3.3): BAIK tiga, AUS dua, PERLU_BENGKEL satu (nol bila kondisi 0).
const KONDISI_KOTAK_BAIK: int = 3
## Lihat `KONDISI_KOTAK_BAIK`.
const KONDISI_KOTAK_AUS: int = 2
## Lihat `KONDISI_KOTAK_BAIK`.
const KONDISI_KOTAK_PERLU_BENGKEL: int = 1
## Kondisi di save dibulatkan ke sekian bagian (10000 = 4 desimal) supaya teks save stabil byte demi byte.
const KONDISI_PEMBULATAN_PEMBAGI: float = 10000.0

## Aus ban per ubin menurut kecepatan rata-rata langkah (u/d): di bawah santai sebanding kecepatan, antar titik linear, di atas ngebut tetap. Ngebut jauh lebih aus dari santai
## (prinsip 1: ngebut ada harganya), santai kecil tetapi bukan nol (servis tidak abadi). Kondisi hilang per ubin ditempuh.
const KONDISI_AUS_BAN_SANTAI_PER_UBIN: float = 0.00015
## Aus ban per ubin pada kecepatan cepat (4,5 u/d).
const KONDISI_AUS_BAN_CEPAT_PER_UBIN: float = 0.0003
## Aus ban per ubin pada kecepatan ngebut (6,0 u/d).
const KONDISI_AUS_BAN_NGEBUT_PER_UBIN: float = 0.0006
## Aus rantai per ubin pada kecepatan santai.
const KONDISI_AUS_RANTAI_SANTAI_PER_UBIN: float = 0.00011
## Aus rantai per ubin pada kecepatan cepat.
const KONDISI_AUS_RANTAI_CEPAT_PER_UBIN: float = 0.0003
## Aus rantai per ubin pada kecepatan ngebut.
const KONDISI_AUS_RANTAI_NGEBUT_PER_UBIN: float = 0.0007
## Aus rem setiap pengereman aktif dimulai (tepi naik rem aktif). Rem yang tidak dipakai tidak aus; lepas stick sebelum `REM_TAHAN_DETIK` tidak dihitung.
const KONDISI_AUS_REM_PER_PENGEREMAN: float = 0.006
## Aus rem per detik rem aktif selama sepeda masih bergerak.
const KONDISI_AUS_REM_PER_DETIK: float = 0.01

## Tabrakan (setiap tabrakan baru dari `Tabrakan`) mengurangi SATU komponen terpilih dari seed hari dan nomor tabrakan, dengan peluang relatif ini (bilangan bulat, sejajar `KONDISI_KOMPONEN`: ban 50, rem 20, rantai 30).
const KONDISI_TABRAKAN_BOBOT: Array[int] = [50, 20, 30]
## Besar kerusakan satu tabrakan. Harus lebih kecil dari `KONDISI_AMBANG_AUS` dikurangi `KONDISI_AMBANG_PERLU_BENGKEL` supaya satu tabrakan tidak melompati AUS (dijaga tes).
const KONDISI_TABRAKAN_KERUSAKAN: float = 0.3

## Efek kerusakan hanya menghambat (GDD 12): pengali nilai terburuk di kondisi 0, linear ke 1,0 di `KONDISI_AMBANG_PERLU_BENGKEL`. Ban: pengali kecepatan tujuan dan kecepatan lateral.
const KONDISI_EFEK_BAN_KECEPATAN_MIN: float = 0.92
## Ban bocor: pengali kecepatan lateral (sulit belok) di kondisi 0.
const KONDISI_EFEK_BAN_LATERAL_MIN: float = 0.6
## Rem blong: pengali perlambatan rem di kondisi 0 (jarak berhenti naik 1 / nilai ini kali).
const KONDISI_EFEK_REM_MIN: float = 0.4
## Rantai putus: pengali akselerasi di kondisi 0 ("turun drastis").
const KONDISI_EFEK_RANTAI_AKSELERASI_MIN: float = 0.35
## Rantai putus: batas kecepatan puncak di kondisi 0, u/d. Tidak boleh di bawah santai (rute tetap bisa diselesaikan).
const KONDISI_EFEK_RANTAI_PUNCAK_MIN_UD: float = 3.6
## Lantai semua pengali efek (tidak ada komponen yang melumpuhkan sepeda, prinsip 2).
const KONDISI_EFEK_LANTAI: float = 0.3
## Jarak berhenti terjauh dari rem aktif dengan rem blong (kondisi 0) dari ngebut, ubin (2,5 kali jarak normal 3,6 ubin).
const KONDISI_REM_JARAK_MAKS_UBIN: float = 9.0
## Cadangan waktu terhadap tenggat bila semua komponen rusak total dan pemain santai terus, detik: waktu tempuh <= tenggat - cadangan (dites untuk 60 seed).
const KONDISI_CADANGAN_TENGGAT_DETIK: float = 2.0
## Toleransi derau float membandingkan kondisi dengan ambangnya.
const KONDISI_TOLERANSI: float = 0.000001

## Tanda peringatan (M-5): jeda minimum antar peringatan komponen yang sama, detik (waktu game, beku saat jeda).
const KONDISI_PERINGATAN_JEDA_DETIK: float = 6.0
## Rantai berisik dan ban mendesis hanya saat sepeda melaju paling sedikit sekian u/d (santai; lebih rendah dari M-5 supaya pemain santai pun diperingatkan sebelum efek).
const KONDISI_PERINGATAN_KECEPATAN_MIN_UD: float = 3.0

## --- Bengkel: servis dan upgrade (GDD 12.3 dan 12.4, BALANCING 7 dan 8; run 6A1, M-9 dan M-10; usulan; dinilai lewat uji HP) ---
## Koin bilangan bulat, 1 koin kira-kira Rp100. Belanja dibayar dari saldo `koin` di save (K-1) dan hanya karena pilihan pemain (K-4: bengkel boleh dilewati).

## Harga servis komponen berkondisi 0 (rusak total), sejajar `KONDISI_KOMPONEN` (ban 120, rem 80, rantai 150; BALANCING 7). Harga turun linear dengan kondisi yang tersisa.
const SERVIS_HARGA_PENUH: Array[int] = [120, 80, 150]
## Harga servis termurah untuk komponen berkondisi di bawah 1,0 (koin). Komponen berkondisi 1,0 tidak bisa diservis.
const SERVIS_HARGA_MIN: int = 1
## Ongkos naik (GDD 12.3): bila `n` komponen PERLU_BENGKEL dan n >= 2, harga tiap servis dikali (1 + nilai ini x (n - 1)). Satu komponen rusak = tanpa kenaikan.
const SERVIS_KENAIKAN_PER_RUSAK: float = 0.25
## Id upgrade wajib ada di data upgrade bengkel (TECH_PLAN 6A: ban anti-selip syarat distrik Desa, upgrade pertama syarat Ruko). Id permanen.
const TOKO_ID_WAJIB: Array[String] = ["ban_anti_selip", "rem_pakem", "rantai_hemat"]
## Panjang maksimal nama upgrade, karakter teks terjemahan (satu baris kartu bengkel).
const TOKO_NAMA_PANJANG_MAKS: int = 24
## Panjang maksimal deskripsi efek upgrade, karakter teks terjemahan (satu baris).
const TOKO_DESKRIPSI_PANJANG_MAKS: int = 48
## Jenis efek upgrade yang dikenal (daftar tertutup; semuanya dibaca kode): aus komponen itu, perlambatan rem, kecepatan lateral, dan laju stamina yang menguras.
## Tidak ada jenis yang menaikkan kecepatan puncak (tanpa power creep). Tiga larik di bawah sejajar dengan daftar ini.
const TOKO_EFEK_JENIS: Array[String] = ["pengali_aus", "pengali_rem", "pengali_lateral", "pengali_kuras_stamina"]
## Nilai terkecil yang sah per jenis efek (aus tidak boleh ditiadakan: paling rendah 0,5).
const TOKO_EFEK_MIN: Array[float] = [0.5, 1.0, 1.0, 0.5]
## Nilai terbesar yang sah per jenis efek (perlambatan rem paling tinggi 1,5; lateral 1,25).
const TOKO_EFEK_MAKS: Array[float] = [1.0, 1.5, 1.25, 1.0]
## Komponen yang boleh membawa jenis efek itu ("" = komponen mana pun).
const TOKO_EFEK_KOMPONEN: Array[String] = ["", "rem", "ban", "rantai"]

## --- HUD kondisi sepeda di rute, bunyi kondisi, dan layar bengkel (run 6A1 bagian B; DESIGN_SPEC 3.3 dan 4, AC-22 sampai AC-27; usulan; dinilai lewat uji HP) ---

## Kotak kondisi di HUD (DESIGN_SPEC 3.3): sisi kotak, piksel game.
const KONDISI_HUD_KOTAK_PX: int = 5
## Jarak antar kotak kondisi, piksel game.
const KONDISI_HUD_KOTAK_JARAK_PX: int = 1
## Jarak ikon komponen ke kotak pertama, piksel game.
const KONDISI_HUD_IKON_JARAK_PX: int = 2
## Lebar tanda "!" (PERLU_BENGKEL) setelah kotak, piksel game. Ruangnya selalu disediakan supaya panel tidak melompat saat tanda muncul.
const KONDISI_HUD_SERU_LEBAR_PX: int = 3
## Jarak kotak terakhir ke tanda "!", piksel game.
const KONDISI_HUD_SERU_JARAK_PX: int = 2
## Jarak antar tiga komponen di panel kondisi, piksel game.
const KONDISI_HUD_ANTAR_KOMPONEN_PX: int = 6
## Lama visual peringatan (ikon bergetar, kotak terisi berwarna WARN) sesudah satu peristiwa peringatan, detik waktu game (beku saat jeda).
const KONDISI_KEDIP_DETIK: float = 1.2
## Periode getar ikon saat peringatan: ikon bergeser tiap setengah periode, detik.
const KONDISI_GETAR_PERIODE_DETIK: float = 0.1
## Besar geseran ikon saat bergetar, piksel game.
const KONDISI_GETAR_PX: int = 1
## Volume bunyi peringatan kondisi (rantai berisik, rem berdecit, ban mendesis), dB: lebih pelan dari bel dan tabrakan supaya tidak menutupinya.
const AUDIO_KONDISI_PERINGATAN_VOLUME_DB: float = -8.0
## Volume bunyi servis dan upgrade di bengkel, dB.
const AUDIO_KONDISI_TRANSAKSI_VOLUME_DB: float = -3.0

## Layar bengkel (DESIGN_SPEC 4): margin minimum dari tepi layar, piksel game (dipakai max dengan inset aman perangkat).
const BENGKEL_MARGIN_PX: int = 12
## Lebar tombol "Hari berikutnya" di bengkel, piksel game (aksi utama kanan bawah; sama dengan `UI_TOMBOL_LEBAR_UTAMA_PX`).
const BENGKEL_HARI_LEBAR_PX: int = 140

## --- Bengkel tata C (run ui1-komponen-bengkel bagian B; kanvas Bengkel.dc.html, ui.css, README redesain 4; usulan, dinilai lewat uji HP) ---
## Tinggi baris judul dan saldo: isi mulai di y = margin atas + ini (12 + 34 = 46 di kanvas, tanpa inset).
const BENGKEL_BARIS_ATAS_PX: int = 34
## Lebar kolom servis sebagai pecahan lebar isi (kanvas 48 %), jarak antar kolom servis dan upgrade, piksel game.
const BENGKEL_KOLOM_SERVIS_FRAKSI: float = 0.48
const BENGKEL_KOLOM_JARAK_PX: int = 8
## Isi panel servis berjarak sekian piksel dari tepi (garis 4 + padding 4), jarak antar anak panel servis, tinggi baris judul bagian dan baris catatan ongkos, piksel game.
const BENGKEL_PANEL_PAD_PX: int = 6
const BENGKEL_PANEL_JARAK_PX: int = 4
const BENGKEL_BAGIAN_TINGGI_PX: int = 14
## Judul bagian Upgrade berada di atas latar (bukan di dalam panel): diberi pelat `HUD_PANEL` dengan jarak samping sekian piksel supaya kontras teksnya tidak bergantung pada lampu di latar.
const BENGKEL_BAGIAN_PELAT_PAD_PX: int = 3
const BENGKEL_CATATAN_TINGGI_PX: int = 14
## Jarak antar kartu upgrade dan geseran ke bawah judul bagian Upgrade, piksel game.
const BENGKEL_UPGRADE_JARAK_PX: int = 6
const BENGKEL_UPGRADE_ATAS_PX: int = 4
## Tinggi kartu servis, kartu upgrade tingkat tunggal, dan kartu upgrade dengan jejak tingkat I, II, III (komponen bertingkat), piksel game.
const BENGKEL_KARTU_SERVIS_PX: int = 50
const BENGKEL_KARTU_UPGRADE_PX: int = 70
const BENGKEL_KARTU_UPGRADE_JEJAK_PX: int = 72
## Isi kartu: jarak antar kolom, jarak tepi kiri (garis 4 + padding 4) dan kanan (garis 4), jarak antar baris teks servis dan upgrade, jarak kotak kondisi ke teks status, jarak antar chip, piksel game.
const BENGKEL_KARTU_JARAK_PX: int = 3
const BENGKEL_KARTU_PAD_AWAL_PX: int = 6
const BENGKEL_KARTU_PAD_AKHIR_PX: int = 4
const BENGKEL_KARTU_TEKS_JARAK_SERVIS_PX: int = 2
const BENGKEL_KARTU_TEKS_JARAK_UPGRADE_PX: int = 2
const BENGKEL_KARTU_STATUS_JARAK_PX: int = 5
## Jarak antar baris bila teks status turun ke bawah kotak kondisi (kolom teks sempit), piksel game.
const BENGKEL_KARTU_STATUS_BARIS_PX: int = 1
const BENGKEL_JEJAK_JARAK_PX: int = 2
## Tampilan: ikon komponen (`ui_icon24_*`), glif (`ui_glif_*`), dan ikon koin di chip, sisi persegi piksel game.
const BENGKEL_IKON_PX: int = 24
const BENGKEL_GLIF_PX: int = 12
const BENGKEL_KOIN_PX: int = 14
## Panel galat data upgrade: jarak isi ke tepi di luar garis kartu (kanvas padding 8), jarak glif ke teks.
const BENGKEL_GALAT_PAD_PX: int = 8
## Deskripsi kartu upgrade tingkat tunggal paling banyak sekian baris; sisanya dipotong dengan elipsis supaya kartu tetap 70 tinggi dan tiga upgrade muat tanpa scroll (QA-001; V-8: font 11 membuat data nyata 2 sampai 3 baris di kolom 640).
const BENGKEL_DESKRIPSI_BARIS_MAKS: int = 3
## Deskripsi kartu upgrade BERTINGKAT (ada baris jejak I, II, III di bawahnya) paling banyak sekian baris.
const BENGKEL_DESKRIPSI_BARIS_JEJAK_MAKS: int = 2
## Jarak antar baris deskripsi kartu upgrade, piksel game (bawaan Label 3; 1 supaya tiga baris huruf 11 muat di kartu 70 dan tiga kartu muat di atas "Hari berikutnya" juga dengan inset aman bawah).
const BENGKEL_DESKRIPSI_JARAK_BARIS_PX: int = 1
## Panggung sepeda: tinggi minimum bila ruang sempit, ukuran sepeda kecil (`ui_bengkel_sepeda_kecil.png`) dan papan alat (`ui_bengkel_papan_alat.png`), jarak sepeda dari bawah panggung, lebar latar.
const BENGKEL_PANGGUNG_MIN_PX: int = 40
const BENGKEL_SEPEDA_LEBAR_PX: int = 116
const BENGKEL_SEPEDA_TINGGI_PX: int = 78
const BENGKEL_PAPAN_LEBAR_PX: int = 360
const BENGKEL_PAPAN_TINGGI_PX: int = 104
const BENGKEL_SEPEDA_BAWAH_PX: int = 4
const BENGKEL_LATAR_LEBAR_PX: int = 800
## Titik penanda kondisi di sepeda kecil (`titik_kecil` di `assets/sprites/ui/ui_bengkel_sepeda.json`; tes membandingkan): x lalu y per komponen urut `KONDISI_KOMPONEN` (ban, rem, rantai).
const BENGKEL_SEPEDA_TITIK: Array[int] = [5, 68, 74, 4, 33, 54]
## Penanda kondisi di sepeda (sisi chip per komponen ada di `TampilBengkel.SISI_PENANDA`): sisi titik 3x3, jarak chip dari titik (di depan dan sesudah titik), geseran chip bawah (mendatar dan tegak), geseran atas, dan tepi minimum ke tepi panggung, piksel game.
const BENGKEL_PENANDA_TITIK_PX: int = 3
const BENGKEL_PENANDA_JARAK_AWAL_PX: int = 4
const BENGKEL_PENANDA_JARAK_AKHIR_PX: int = 5
const BENGKEL_PENANDA_BAWAH_X_PX: int = 10
const BENGKEL_PENANDA_BAWAH_Y_PX: int = 6
const BENGKEL_PENANDA_ATAS_Y_PX: int = 7
const BENGKEL_PENANDA_TEPI_PX: int = 2
## Tingkat upgrade tertinggi yang punya angka romawi sendiri (I, II, III); di atasnya angka biasa.
const BENGKEL_TINGKAT_ROMAWI_MAKS: int = 3

## --- Aset gelombang 1 terpasang di rute (run fase5a bagian B, D-3 sampai D-6; usulan, dinilai di HP) ---
## Tiap sprite = [lebar sel, tinggi sel, jumlah frame, titik pijak x, titik pijak y], piksel; frame berjajar kiri ke kanan. Sama dengan `cell`, `frames`, dan `ground_anchor` di JSON
## aset (`assets/sprites/props/`, `assets/sprites/vfx/`); tes membandingkannya dengan JSON dan ukuran PNG. Pemilihan frame dan letak gambar ada di `DefSprite` dan turunannya.
## Indeks isi larik `SPRITE_*`: lebar sel 0, tinggi sel 1, jumlah frame 2, pijak x, pijak y; panjang larik.
const SPRITE_INDEKS_LEBAR: int = 0
const SPRITE_INDEKS_TINGGI: int = 1
const SPRITE_INDEKS_PIJAK_X: int = 3
const SPRITE_INDEKS_PIJAK_Y: int = 4
const SPRITE_PANJANG: int = 5
## Koran gulung berputar di udara (pijak = pusat putar).
const SPRITE_KORAN_PUTAR: Array[int] = [10, 10, 4, 5, 5]
## Bayangan koran: tiga frame (lebar 10, 8, 6 px) dalam sel 12 px; pijak = pusat bayangan di tanah.
const SPRITE_KORAN_BAYANGAN: Array[int] = [12, 6, 3, 6, 3]
## Koran tergeletak di lantai keras (teras, trotoar, aspal).
const SPRITE_KORAN_TERAS: Array[int] = [12, 10, 1, 6, 6]
## Koran tergeletak di rumput.
const SPRITE_KORAN_RUMPUT: Array[int] = [12, 10, 1, 6, 6]
## Koran bertumpu di kotak surat sasaran; pijak (-3, 19) = kaki kotak surat sasaran (`prop_kotak_surat`), bukan titik jatuh.
const SPRITE_KORAN_KOTAK_SURAT: Array[int] = [8, 7, 1, -3, 19]
## Koran terlipat di teras rumah yang sudah terantar.
const SPRITE_KORAN_TERLIPAT: Array[int] = [14, 10, 1, 7, 5]
## Debu roda: enam frame putar, pijak = titik roda belakang di tanah.
const SPRITE_DEBU_RODA: Array[int] = [18, 10, 6, 14, 7]
## Garis kecepatan varian a, b, dan c (satu frame; pijak = ujung kepala garis di kanan atas).
const SPRITE_GARIS_KECEPATAN_A: Array[int] = [28, 14, 1, 27, 7]
const SPRITE_GARIS_KECEPATAN_B: Array[int] = [28, 14, 1, 27, 7]
const SPRITE_GARIS_KECEPATAN_C: Array[int] = [28, 14, 1, 27, 7]
## Bintang kena: enam frame sekali main, pijak = pusat.
const SPRITE_BINTANG_KENA: Array[int] = [15, 15, 6, 7, 7]
## Koin tip: enam frame sekali main (koin naik, lalu tulisan "+5"), pijak = titik mendarat di dasar sel.
const SPRITE_KOIN_TIP: Array[int] = [16, 26, 6, 8, 24]
## Kilau kucing misi: dua frame, pijak = pusat.
const SPRITE_MISI_KILAU: Array[int] = [9, 9, 2, 4, 4]
## Pusat putar sprite koran di udara berada sekian piksel game di atas titik udara koran (setengah tinggi pola koran 8x6 lama, jadi pusat gambar tidak bergeser).
const KORAN_PUTAR_PUSAT_ATAS_PX: int = 3
## Lebar bayangan koran tiap frame `SPRITE_KORAN_BAYANGAN`, piksel game, dari yang terlebar (rendah) ke tersempit (tinggi). Frame dipilih yang lebarnya terdekat dengan `KoranLempar.lebar_bayangan_px`.
const KORAN_BAYANGAN_FRAME_LEBAR_PX: Array[int] = [10, 8, 6]
## Debu roda sprite berputar (loop) sekian frame per detik.
const UMPAN_DEBU_SPRITE_FPS: float = 12.0
## Garis kecepatan sprite diacak (varian dan geseran tegak lurus jalan) tiap sekian sampai sekian frame game.
const UMPAN_GARIS_GANTI_MIN_FRAME: int = 2
const UMPAN_GARIS_GANTI_MAKS_FRAME: int = 3
## Benih RNG garis kecepatan sprite (acak berseed, tetap).
const UMPAN_GARIS_SPRITE_BENIH: int = 3
## Garis kecepatan sprite: titik kepala (pijak sprite) dari titik pijak sepeda, sebelum geseran tegak lurus jalan, piksel game (datar, positif = ke kanan). Dipilih supaya pusat piksel garis
## (rata-rata tiga varian) jatuh di pusat rata-rata garis partikel run 1B seperti tergambar di 60 fps (11,7; -13,8): muncul di (30, -24), mundur 200 px/d, umur 0 sampai 17 frame. Run 5A memakai
## `UMPAN_GARIS_ASAL_*` (titik muncul) sebagai kepala, jadi garis diam sekitar 13,5 px lebih ke depan sepanjang jalan (umpan balik HP pemilik 2026-10-22; usulan, dinilai di HP).
const UMPAN_GARIS_SPRITE_KEPALA_X_PX: float = 20.0
## Garis kecepatan sprite: titik kepala dari titik pijak sepeda, tegak, piksel game (negatif = ke atas). Lihat `UMPAN_GARIS_SPRITE_KEPALA_X_PX`.
const UMPAN_GARIS_SPRITE_KEPALA_Y_PX: float = -14.0
## Bintang kena sekali main sekian frame per detik.
const UMPAN_BINTANG_FPS: float = 15.0
## Koin tip sekali main sekian frame per detik.
const UMPAN_KOIN_TIP_FPS: float = 10.0
## Nilai tip yang dipanggang di tulisan sprite `vfx_koin_tip` ("+5"). Sprite dipakai hanya bila tip sama dengan ini; bila `KOIN_TIP` berubah baris tip label dipakai lagi.
const UMPAN_KOIN_TIP_SPRITE_NILAI: int = 5
## Kotak kilau kucing misi (lebar, tinggi) piksel game: sprite 9x9 di tengahnya, pojok kiri atas kotak = `MISI_KILAU_POSISI_PX`. Juga kotak terburuk untuk "terlihat di layar" (`TampilMisi`).
const MISI_KILAU_KOTAK_PX: Array[int] = [11, 11]

## --- Rumah sisi dekat, halaman terbuka (run fase5d-sisi-dekat bagian A, P-1 dan P-2, keputusan pemilik 2026-10-22 K-1; usulan, dinilai di HP) ---
## Tembok belakang run 5B dilepas (P-1): kavling dekat = halaman rumput terbuka. Rumah sisi dekat DIGAMBAR sejauh ini lebih jauh dari jalan (ubin, arah lateral positif; pilihan pemilik 2026-10-22, dulu 1,25 dengan tembok); tapak logika (`RUTE_RUMAH_DEKAT_X_UBIN`, zona, validasi) tidak berubah.
const RUTE_RUMAH_DEKAT_MUNDUR_UBIN: float = 0.5
## Jenis rumah sisi dekat, urut tetap; tabel `RUTE_RUMAH_DEKAT_PENUTUP_*` sejajar dengan daftar ini.
const RUTE_RUMAH_DEKAT_JENIS: Array[String] = ["dekat_limasan", "dekat_pelana_lintang", "dekat_pelana_sejajar"]
## Kotak penutup rumah dekat = sprite nyata (`penutup_ubin` + `penutup_tinggi_ubin` di JSON aset `house_perumahan_dekat_*`, dari primitif renderer `tools/env_art/fase3.py`; badan dan atap tanpa teras dan antena, dijaga tes):
## lima tabel sejajar `RUTE_RUMAH_DEKAT_JENIS`, ubin relatif titik pijak GAMBAR (lateral positif menjauh dari jalan). Pelanggan dan bukan sama.
const RUTE_RUMAH_DEKAT_PENUTUP_LATERAL_UBIN: Array[float] = [-1.09375, -1.09375, -1.09375]
const RUTE_RUMAH_DEKAT_PENUTUP_MAJU_UBIN: Array[float] = [-1.40625, -1.40625, -1.375]
const RUTE_RUMAH_DEKAT_PENUTUP_LEBAR_UBIN: Array[float] = [3.06875, 3.1125, 3.1125]
const RUTE_RUMAH_DEKAT_PENUTUP_PANJANG_UBIN: Array[float] = [2.8125, 2.8125, 2.75]
const RUTE_RUMAH_DEKAT_PENUTUP_TINGGI_UBIN: Array[float] = [1.625, 1.6875, 1.5625]
## Lantai teras menjorok rumah dekat (`teras_ubin` di JSON aset, sama untuk semua jenis): [lateral_min, maju_min, lebar_lateral, panjang_maju], ubin relatif titik pijak gambar. Untuk zona teras dekat (run 5D bagian B, AC-10).
const RUTE_RUMAH_DEKAT_TERAS_UBIN: Array[float] = [-1.8125, -1.375, 0.875, 0.9375]
## Penghitung hash FNV-1a 32 bit (bukan angka tuning): nilai awal, pengali, dan masker 32 bit. Dipakai `UbinKhusus` (variasi rumput) tanpa `hash()` dan tanpa RNG.
const HASH_FNV1A_AWAL: int = 2166136261
const HASH_FNV1A_KALI: int = 16777619
const HASH_FNV1A_MASKER: int = 4294967295
## Tambahan penghitung hash FNV-1a atas bilangan bulat (`UbinKhusus`): jumlah byte per bilangan (32 bit), geser bit antar byte, dan masker satu byte.
const HASH_FNV1A_BYTE_PER_INT: int = 4
const HASH_FNV1A_GESER_BIT: int = 8
const HASH_FNV1A_MASKER_BYTE: int = 255

## --- Ubin khusus di tanah rute (run fase5b-tembok-dekor bagian C, D-7; usulan, dinilai di HP) ---
## Baris ubin jalan masuk garasi = pembulatan (maju - ini) ke atas, ubin: ubin berpusat di maju bulat dan menutup maju - 0,5 sampai maju + 0,5, jadi titik tepat di batas dua baris jatuh ke baris di belakang.
const RUTE_BARIS_MASUK_GESER_UBIN: float = 0.5
## Simbol sepeda di kedua kolom trotoar: satu baris tiap sekian baris ubin maju (baris mutlak dari awal rute), bergeser `RUTE_SIMBOL_SEPEDA_OFFSET_UBIN` (baris mutlak b: simbol bila b - offset kelipatan selang). Tidak di baris jalan masuk garasi.
const RUTE_SIMBOL_SEPEDA_SELANG_UBIN: int = 12
const RUTE_SIMBOL_SEPEDA_OFFSET_UBIN: int = 6
## Variasi rumput polos di kolom rumput luar (di luar kolom rumput pertama): (kolom, baris mutlak) di-hash FNV-1a, sisa bagi `RUTE_RUMPUT_VARIAN_MOD`; nilai di bawah `RUTE_RUMPUT_VARIAN_2_PERSEN` = rumput_2, lalu `RUTE_RUMPUT_VARIAN_3_PERSEN` berikutnya = rumput_3, sisanya rumput_1 (terbanyak).
const RUTE_RUMPUT_VARIAN_MOD: int = 100
const RUTE_RUMPUT_VARIAN_2_PERSEN: int = 12
const RUTE_RUMPUT_VARIAN_3_PERSEN: int = 8
## Ujung kerb jalan masuk sisi seberang (run fase5c-animasi-simpang, C-F1 run 5B): baris maju relatif ke baris jalan masuk yang memakai ubin `*_masuk_ujung` di kolom trotoar dan rumput pertama seberang (= `ujung_kerb_baris_relatif` di `tile_perumahan.json`, dijaga tes).
const RUTE_UJUNG_KERB_BARIS_RELATIF: int = 1

## --- Simpang T hiasan (run fase5c-animasi-simpang, keputusan pemilik 2026-10-22 K-1/P-1, D-3; usulan, dinilai di HP) ---
## Lebar mulut jalan samping sepanjang jalan utama, ubin (= `simpang.lebar_mulut_ubin` di `tile_perumahan.json` = selisih `SIMPANG_Y` renderer / 32, dijaga tes). Data segmen hanya `{pos, sisi}`.
const RUTE_SIMPANG_LEBAR_MULUT_UBIN: float = 2.0
## Tepi mulut paling dekat ke awal rute relatif ke `pos` simpang, ubin maju (= -`simpang.y_mulut_unit[1]` / 32 renderer): `pos` = baris `mulut_2` (berpusat di maju bulat), mulut menutup `pos - 0,5` sampai `pos + 1,5`.
const RUTE_SIMPANG_MULUT_AWAL_UBIN: float = -0.5
## Pita larangan simpang: baris relatif maju (dari baris `pos`) pertama dan terakhir yang ubinnya diganti renderer di kolom trotoar, rumput, atau lengan, kedua sisi (= `simpang.pita_baris_relatif`). Tiap baris menutup baris - 0,5 sampai baris + 0,5, jadi pita = maju `pos - 1,5` sampai `pos + 3,5`.
const RUTE_SIMPANG_PITA_BARIS: Array[int] = [-1, 3]
## Setengah tinggi satu baris ubin sepanjang jalan, ubin: baris berpusat di maju bulat b menutup b - ini sampai b + ini (dipakai tepi pita simpang dan baris jalan masuk di validasi simpang).
const RUTE_SETENGAH_BARIS_UBIN: float = 0.5
## Sel ubin simpang sisi `dekat`, pasangan (baris relatif maju, kolom: 0 aspal, 1 trotoar, 2 rumput pertama, 3 lengan = semua kolom rumput luar), urut sama dengan `simpang.sisi.dekat` di `tile_perumahan.json` dan `TanahDaur.tekstur_simpang_dekat`.
const RUTE_SIMPANG_SEL_DEKAT: Array[int] = [3, 1, 3, 2, 3, 3, 2, 0, 2, 1, 2, 2, 2, 3, 1, 0, 1, 1, 1, 2, 1, 3, 0, 0, 0, 1, 0, 2, 0, 3, -1, 1, -1, 2, -1, 3]
## Sel ubin simpang sisi `seberang` (pola sama; dari JSON renderer `build/env_art/ubin/simpang/`, dijaga `tools/tests_cek/uji_aset_simpang.py`). Ubinnya dipasang sejak putusan P-6 run 5C (simpang seberang `per_buka_02` pos 18).
const RUTE_SIMPANG_SEL_SEBERANG: Array[int] = [3, 2, 3, 3, 2, 1, 2, 2, 2, 3, 1, 0, 1, 1, 1, 2, 1, 3, 0, 0, 0, 1, 0, 2, 0, 3, -1, 1, -1, 2, -1, 3]

## --- Dekor pinggir jalan di data segmen (run fase5b-tembok-dekor bagian B2, D-5 dan D-6; usulan, dinilai di HP) ---
## Jenis dekor yang sah di data segmen (urut tetap; tabel `RUTE_DEKOR_*` di bawah sejajar dengan daftar ini).
const RUTE_DEKOR_JENIS: Array[String] = ["tong_sampah", "pohon", "lampu_jalan"]
## Varian sah per jenis (D-5): tong sampah logam abu-abu; pohon rindang, glodokan, ketapang; lampu jalan jenis lengan (PJU perumahan).
const RUTE_DEKOR_VARIAN_TONG_SAMPAH: Array[String] = ["logam"]
const RUTE_DEKOR_VARIAN_POHON: Array[String] = ["rindang", "glodokan", "ketapang"]
const RUTE_DEKOR_VARIAN_LAMPU_JALAN: Array[String] = ["lengan"]
## Lateral pusat dekor sisi `dekat` per jenis, ubin dari garis tengah jalan (besaran saja; tanda positif). Pohon dan tong sampah di halaman (2,5), lampu di luar tepi trotoar (2,25).
const RUTE_DEKOR_LATERAL_UBIN: Array[float] = [2.5, 2.5, 2.25]
## Lateral pusat dekor sisi `seberang` per jenis, ubin (besaran saja; tanda negatif). Pohon 2,75 dan lampu 2,625 lebih jauh dari jalan daripada sisi dekat (iterasi 2 run fase5b, D-6): kamera melihat dari sisi dekat, jadi tajuk dan lengan lampu seberang yang digambar sesudah pemain (Y-sort) menimpa pemain di lateral -2,0 sampai -1,75 dengan piksel opak (terukur 272 dan 240 piksel di lateral 2,5 dan 2,25); pada angka ini terukur 0 piksel (tes). Tong sampah 2,5 tetap.
const RUTE_DEKOR_LATERAL_SEBERANG_UBIN: Array[float] = [2.5, 2.75, 2.625]
## Setengah sisi tapak kaki dekor per jenis, ubin (persegi di bidang tanah): tong sampah dan pohon 0,5 x 0,5, tiang lampu 0,25 x 0,25. Tapak tidak boleh menyentuh lajur sepeda (|lateral| kurang dari `RUTE_DEKOR_LAJUR_UBIN`). Dipakai validasi tempat dekor, BUKAN kotak penutup.
const RUTE_DEKOR_SETENGAH_UBIN: Array[float] = [0.25, 0.25, 0.125]
## Kotak penutup pemain, sejajar `RUTE_DEKOR_SPRITE` (tong, pohon rindang, glodokan, ketapang, lampu seberang, lampu dekat). Tinggi = piksel opak sprite di atas titik pijaknya dibagi 32 piksel per ubin (tong 24, rindang 44, glodokan 63, ketapang 53, lampu seberang 58, lampu dekat 64 piksel). Hanya dekor sisi `dekat` memakai kotak ini (termasuk tong sampah, P-7); sisi `seberang` selalu tinggi 0 (run fase5b iterasi 2, P-6 dan P-7).
const RUTE_DEKOR_TINGGI_PENUTUP_UBIN: Array[float] = [0.75, 1.375, 1.96875, 1.65625, 1.8125, 2.0]
## Setengah sisi tapak kotak penutup, ubin (persegi di sekitar titik pijak, sejajar `RUTE_DEKOR_SPRITE`). Lebih besar dari tapak kaki karena tajuk dan lengan lampu melebar jauh dari batang; ukuran terkecil (kelipatan 0,125) yang membuat tidak ada piksel opak dekor di atas piksel pemain tanpa kotak menutupinya, lateral -2,0 sampai 2,0, semua pose berkendara (diukur tes dari PNG): tong 0,625, rindang 0,875, glodokan 0,625, ketapang 0,75, lampu dekat 0,75 (lampu seberang tidak dipakai).
const RUTE_DEKOR_SETENGAH_PENUTUP_UBIN: Array[float] = [0.625, 0.875, 0.625, 0.75, 0.75, 0.75]
## Batas lajur sepeda, ubin dari garis tengah: sepeda tidak pernah melewati lateral 2,0 (trotoar sampai tepi), dekor dan tapak kakinya harus di luar.
const RUTE_DEKOR_LAJUR_UBIN: float = 2.0
## Jarak paling dekat antara dua dekor sesisi sepanjang jalan, ubin (`pos` bilangan bulat, jadi dua dekor tidak di ubin yang sama).
const RUTE_DEKOR_JARAK_MIN_UBIN: int = 1
## `pos` dekor paling kecil, ubin dari awal segmen (paling besar = panjang segmen - sekian): dekor boleh di dekat tepi, jarak antar segmen terjaga oleh batas ini.
const RUTE_DEKOR_TEPI_UBIN: int = 1
## Sprite dekor terpasang (PNG di `assets/sprites/props/`), sejajar dengan `RUTE_DEKOR_SPRITE_DATA` (lima angka tiap sprite: lebar sel, tinggi sel, frame, pijak x, pijak y, piksel; sama dengan JSON aset dan ukuran PNG, dijaga tes).
const RUTE_DEKOR_SPRITE: Array[String] = ["prop_tong_sampah_logam", "prop_pohon_rindang", "prop_pohon_glodokan", "prop_pohon_ketapang", "prop_lampu_lengan_seberang", "prop_lampu_lengan_dekat"]
const RUTE_DEKOR_SPRITE_DATA: Array[int] = [20, 30, 1, 10, 25, 151, 119, 1, 41, 63, 121, 126, 1, 25, 77, 141, 124, 1, 35, 70, 85, 104, 1, 9, 63, 85, 104, 1, 22, 69]

## --- Pelanggan sisi dekat, sasaran dekat, dan tip hari 3 (run fase5d-sisi-dekat bagian B, P-4, P-5, P-6, D-2, D-3, D-4; usulan, dinilai di HP) ---
## Hari pertama yang punya pelanggan sisi dekat (P-4): hari 1 dan 2 hanya seberang, rute identik run sebelumnya (RNG sama). Juga hari tip singkat (P-6).
const RUTE_DEKAT_HARI_MULAI: int = 3
## Jumlah pelanggan sisi dekat per rute sejak `RUTE_DEKAT_HARI_MULAI`: paling sedikit dan paling banyak (8 atau 9 dari `RUTE_PELANGGAN` = sekitar 35%); total tetap `RUTE_PELANGGAN`.
const RUTE_DEKAT_KUOTA_MIN: int = 8
const RUTE_DEKAT_KUOTA_MAKS: int = 9
## Zona kotak surat rumah dekat di rute = cermin zona seberang (`JALAN_UJI_SEBERANG_KOTAK_SURAT_UBIN` -> lateral positif): [lateral_min, maju_min, lebar_lateral, panjang_maju], ubin, maju relatif awal kavling. Lebih lebar dari zona dekat jalan uji (0,75) karena teras dekat kini di lateral >= 3,19 (tidak lagi di lateral 2,5).
const RUTE_DEKAT_KOTAK_SURAT_UBIN: Array[float] = [1.75, 1.25, 1.0, 1.25]
## Inti "tepat" zona kotak surat dekat rute: 0,5 x 0,5 di pusat zona (cermin `JALAN_UJI_SEBERANG_KOTAK_SURAT_INTI_UBIN`).
const RUTE_DEKAT_KOTAK_SURAT_INTI_UBIN: Array[float] = [2.0, 1.625, 0.5, 0.5]
## Zona halaman rumah dekat di rute: rumput dari tepi trotoar dekat (lateral 2,0) sampai tepi badan rumah (pusat gambar 5,0 + `RUTE_RUMAH_DEKAT_PENUTUP_LATERAL_UBIN` -1,09375 = 3,90625), maju -0,5 sampai 2,5 relatif awal kavling. Dijaga tes terhadap JSON aset.
const RUTE_DEKAT_HALAMAN_UBIN: Array[float] = [2.0, -0.5, 1.90625, 3.0]
## Letak sprite kotak surat rumah dekat: lateral (cermin `JALAN_UJI_KOTAK_SURAT_X_UBIN` -2,125); maju relatif awal kavling sama dengan seberang (`JALAN_UJI_KOTAK_SURAT_MAJU_UBIN`).
const RUTE_DEKAT_KOTAK_SURAT_X_UBIN: float = 2.125
## Tip hari 3 (P-6): lama tampil sejak rute dimulai (detik waktu game, beku saat jeda), letak panel (kolom kiri di bawah kartu misi, sama dengan petunjuk tutorial) dan lebarnya, piksel game.
const TIP_SISI_DEKAT_DETIK: float = 6.0
const TIP_SISI_DEKAT_X_PX: int = 26
const TIP_SISI_DEKAT_Y_PX: int = 88
const TIP_SISI_DEKAT_LEBAR_PX: int = 150
## Koran terlipat di teras rumah dekat (AC-9): teras dekat ada di belakang titik pijak sprite rumahnya menurut Y-sort, jadi pembungkus Y-sort sprite terlipat diletakkan sekian piksel game di DEPAN titik pijak rumah supaya digambar sesudah sprite rumah.
const RUTE_RUMAH_DEKAT_URUT_TERLIPAT_PX: int = 1

## --- Komponen UI redesain bersama (run ui1-komponen-bengkel bagian A; docs/design/redesain/README.md 4, kanvas ui.css; usulan, dinilai lewat uji HP) ---
## Tepi 9-slice bingkai tombol 12x16 (`ui_btn_*.png`): atas, bawah, dan samping, piksel game. Sama dengan `slice` di `docs/design/redesain/aset/meta.json` (urutan CSS atas/kanan/bawah/kiri = 6/4/6/4), dijaga `tools/tests_cek/uji_ui_redesain.py`.
const UI_TOMBOL_SLICE_ATAS_PX: int = 6
const UI_TOMBOL_SLICE_BAWAH_PX: int = 6
const UI_TOMBOL_SLICE_SAMPING_PX: int = 4
## Tepi 9-slice panel layar dan kartu 12x12 (`ui_panel_layar.png`, `ui_kartu_*.png`), piksel game.
const UI_PANEL_SLICE_PX: int = 4
## Tepi 9-slice chip 8x8 (`ui_chip_*.png`), piksel game.
const UI_CHIP_SLICE_PX: int = 3
## Wajah tombol utama dan biasa turun sekian piksel saat ditekan (teks ikut turun lewat margin isi; gambarnya `*_tekan`).
const UI_TOMBOL_TEKAN_GESER_PX: int = 2
## Tinggi tombol standar, lebar minimum (target sentuh, rule ui-scenes), dan lebar tombol aksi utama kanan bawah, piksel game.
const UI_TOMBOL_TINGGI_PX: int = 42
const UI_TOMBOL_LEBAR_MIN_PX: int = 84
const UI_TOMBOL_LEBAR_UTAMA_PX: int = 140
## Garis fokus tombol berada sekian piksel di luar tepi tombol (1 px jarak + 1 px garis; kanvas `outline-offset: 1px`).
const UI_TOMBOL_FOKUS_JARAK_PX: int = 2
## Tebal garis 1 piksel game: garis kotak `GayaHud`, garis fokus, cincin gelap titik penanda sepeda dan ring luar panggung bengkel (QA-006: tanpa angka ajaib).
const UI_GARIS_PX: int = 1
## Isi sakelar: jarak tambahan kiri dan kanan di luar tepi 9-slice (CSS `padding: 0 4px 2px`).
const UI_TOMBOL_SAKELAR_PAD_X_PX: int = 4
## Tinggi chip kecil, normal, dan besar (V-8: 16, 20, 26 untuk huruf 10, 12, 14), serta jarak isi ke samping di luar tepi 9-slice, piksel game.
const UI_CHIP_TINGGI_KECIL_PX: int = 16
const UI_CHIP_TINGGI_PX: int = 20
const UI_CHIP_TINGGI_BESAR_PX: int = 26
const UI_CHIP_PAD_X_KECIL_PX: int = 1
const UI_CHIP_PAD_X_PX: int = 2
const UI_CHIP_PAD_X_BESAR_PX: int = 4
## Chip: jarak isi ke atas dan bawah di luar tepi 9-slice per ukuran (lebih kecil dari tepi: tinggi chip tetap 16, 20, 26 walau tinggi baris teks Lexend 13, 15, 18), dan jarak antar isi (glif, ikon, teks), piksel game.
const UI_CHIP_PAD_Y_KECIL_PX: int = 1
const UI_CHIP_PAD_Y_PX: int = 2
const UI_CHIP_PAD_Y_BESAR_PX: int = 3
const UI_CHIP_JARAK_PX: int = 3
const UI_CHIP_JARAK_BESAR_PX: int = 4
## Kotak kondisi besar (kartu servis bengkel, `KotakKondisiBesar`): sisi kotak, jarak antar kotak, jarak kotak ketiga ke tanda "!", piksel game. HUD rute tetap memakai `KONDISI_HUD_KOTAK_PX`.
const KONDISI_BESAR_KOTAK_PX: int = 8
const KONDISI_BESAR_KOTAK_JARAK_PX: int = 2
const KONDISI_BESAR_SERU_JARAK_PX: int = 2
