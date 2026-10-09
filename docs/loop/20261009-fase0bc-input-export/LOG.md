# Loop Log — 20261009-fase0bc-input-export
Scope: Run 0B + 0C digabung (input touch, sepeda placeholder, export Android, APK debug)  ·  Branch: feat/fase0bc-input-export  ·  Mulai: 2026-10-09  ·  Godot: 4.7.2.stable.official.ed1daf0bf

## Status: IN_PROGRESS   (iterasi saat ini: 1/2)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 1 | **Dev-0B selesai** (AC-1..AC-18 bagian 0B; AC-18 perintah ekspor menyusul di Dev-0C): logika murni input dan gerak, node input, jalan uji tanpa ujung, HUD sementara, terjemahan, tes (950 -> 1840 pemeriksaan), penjaga Q-002/Q-003. Tidak ada `BLOCKED`. **Dev-0C selesai sebagian** (AC-18 sisa, AC-19, AC-20, AC-23, AC-24 selesai; **AC-21 dan AC-22 `BLOCKED`**: `export/android/java_sdk_path` kosong di Editor Settings, tidak ada APK): `export_presets.cfg`, `tests/tes_export.gd`, `docs/SETUP_ANDROID.md`, perintah ekspor di dokumen, `.gitignore` +keystore, Import ETC2 ASTC di `project.godot`. | Dev-0B: import bersih di clone bersih (0 ERROR, `git status` kosong), `1840 lolos, 0 gagal` + pemeriksa (juga `--ketat`) exit 0, buka project 2 frame tanpa ERROR/WARNING. Dev-0C: import bersih di repo kerja dan clone bersih (0 ERROR/WARNING, `git status` kosong), `1948 lolos, 0 gagal` + pemeriksa (juga `--ketat`) exit 0, `uji_pemeriksa.py` 16 kasus 0 menyimpang, buka project 2 frame tanpa ERROR/WARNING, diff `main...HEAD` tanpa keystore/APK/`.godot`/`build`; **export APK tidak bisa dijalankan (BLOCKED)** | | | |

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|
| 0A-Q002 | 1 | Minor | tests/run_tests.gd (tes `pedal_rate` negatif) | Dari run 0A (Q-002, DEFERRED, AC-17): tes `speed_scale >= 0.0` terlalu longgar, mutan `absf` lolos. | FIXED (Dev-0B) | `tests/run_tests.gd`: `speed_scale == 0.0` dan `LoperAnim.skala_kayuh(-2.0) == 0.0`; mutan `absf` ditangkap (2 GAGAL) | `_test_scene_pemain` |
| 0A-Q003 | 1 | Minor | tests/run_tests.gd (penjaga AC-8/AC-9 run 0A) | Dari run 0A (Q-003, DEFERRED, AC-17): empat celah penjaga. Ditutup: `Camera2D.zoom` bulat (scene, skrip, dan node hidup), `Color.<KONSTAN>` di luar `palette.gd`, string `"kiri"`/`"kanan"` di skrip di luar `NAMA_ARAH`, teks pemain tertanam di skrip dan scene. Tiap penjaga punya contoh buruk sintetis yang ditolak dan mutan nyata yang ditangkap. | FIXED (Dev-0B) | `tests/run_tests.gd` (`_test_penjaga_berkas`, `_test_terjemahan`) | `_zoom_tak_bulat`, `_warna_konstan`, `_string_kiri_kanan`, `_teks_literal_di_skrip`, `_teks_di_scene` |
| 0C-B001 | 1 | Major | Editor Settings `export/android/java_sdk_path` (di luar repo) | AC-21 dan AC-22 tidak bisa dibuktikan: `godot --headless --path . --export-debug "Android" builds/kring-kring-debug.apk` berhenti dengan `A valid Java SDK path is required in Editor Settings.` walau `JAVA_HOME` diset. Tidak ada APK. Detail dan usulan tunggal di bagian Dev-0C. | BLOCKED | usulan di bagian Dev-0C: isi Java SDK Path di Editor Settings (butuh izin pemilik) | tes preset tidak bergantung pada APK (`tests/tes_export.gd`) |

## NEEDS-MANUAL (uji di HP)
Daftar awal ada di SPEC bagian "Butuh uji perangkat nyata". Dev dan QA menambah langkah di sini.

- [ ] (dari run 0A, Q-012/Q-013) Tangkapan layar A54 dan `cek_blok_piksel.py 3`, tinggi jendela 1080 (imersif).
- [ ] (dari run 0A, Q-014) Light 2D / glow / partikel / shader di Compatibility pada HP: bukan bagian run ini.
- [ ] (Dev-0B) Tepi layar Android: zona stick mulai di x = 8 px game (sekitar 24 px layar dari tepi kiri). Gestur "kembali" sistem di tepi kiri/kanan bisa mencuri atau membatalkan sentuhan di sana. Kode sudah menangani `InputEventScreenTouch.canceled` (jari dilepas tanpa mencatat swipe), tapi apakah zona perlu digeser ke dalam hanya bisa dinilai di A54. Catat bila stick sering "putus" saat jempol dekat tepi.
- [ ] (Dev-0B) Cutout kamera A54 di landscape (kamera di tepi kiri atau kanan tengah): periksa tidak menutupi zona stick (x mulai 8, y 186..352) atau panel kecepatan. Inset aman (`DisplayServer.get_display_safe_area()`) belum dipakai di run ini.
- [ ] (Dev-0B) Tombol kidal (strip atas, tinggi 36 px game = sekitar 108 px layar) mudah ditekan sengaja dan tidak ikut tersentuh saat bermain; panel kecepatan tidak tertutup jempol kanan saat swipe.
- [ ] (Dev-0B) Garis bidik swipe 2 px tiap 4 px (sekitar 6 px layar) terbaca di bawah jempol; knob (radius 15) yang menonjol 15 px di luar cincin saat tarikan penuh terlihat wajar.
- [ ] (Dev-0B) Tangkapan layar HUD: teks Lexend adalah font vektor yang dirasterisasi di resolusi layar dengan anti-alias, jadi tepi hurufnya BUKAN blok 3x3 (dikecualikan di `cek_blok_piksel.py --kecualikan`). Nilai keterbacaan ukuran 6 px game (18 px layar) dinilai mata di HP.
- [ ] (Dev-0C, orchestrator, setelah Java SDK Path terisi dan sebelum QA iterasi 1 bila memungkinkan) Jalankan ulang AC-21 dan AC-22 sesuai `docs/SETUP_ANDROID.md` bagian 4 dan 5, lalu salin hasilnya ke bagian Dev-0C (durasi, ukuran, `minSdkVersion`, `targetSdkVersion`, izin akhir, tanda tangan). Bila ada `ERROR:`/`WARNING:` baru (mis. ikon, build-tools, ETC2/ASTC), catat.
- [ ] (Dev-0C) Orientasi terkunci (putar HP 180 derajat: tampilan tidak terbalik dan tidak jadi portrait) dan ikon di launcher (kemungkinan ikon bawaan template; belum ada ikon project).
- [ ] (Dev-0C, opsional) Keyboard fisik/Bluetooth: panah dan WASD tidak boleh menggerakkan sepeda di APK (`OS.has_feature("editor")` salah di build ekspor). Sisa AC-13 dari Dev-0B yang tidak bisa dibuktikan headless.
- [ ] (Dev-0C) Layar penuh imersif di A54 dengan `screen/edge_to_edge=false` (bawaan Godot, belum diuji): viewport 780x360 skala x3; bila x2, coba `screen/edge_to_edge=true` di preset (usulan di `docs/SETUP_ANDROID.md` bagian 6).

## Catatan Dev (per pemanggilan)
Dev menulis gerbang yang dijalankan, perintah persis, dan keluaran ringkas di sini: satu bagian per pemanggilan (Dev-0B, Dev-0C, dan iterasi 2 bila ada). Termasuk: nama kelas bila berbeda dari SPEC D-1, perintah ekspor APK, durasi dan ukuran APK, hasil `aapt2`/`apksigner`/`apkanalyzer`, nilai min SDK/target SDK/`allowBackup`, daftar izin dan penjelasannya.

### Dev-0B (iterasi 1)

Lingkungan: macOS (Apple M1), `godot --version` = `4.7.2.stable.official.ed1daf0bf`, Python 3 (stdlib). 11 commit Dev-0B di `feat/fase0bc-input-export` (`git log --oneline main..HEAD`, di luar 3 commit dokumen orchestrator), tidak ada commit di `main`, tidak ada push. Hook `rtk` mengganti keluaran `git status --porcelain`; hitungan di bawah memakai `/usr/bin/git`. Tidak menyentuh HP, tidak mengunduh apa pun, tidak memasang apa pun di luar repo. Tidak ada `BLOCKED`. Bagian 0C (AC-19..AC-23) tidak dikerjakan.

#### Kelas dan file nyata (dibanding SPEC D-1)

Semua lima kelas D-1 ada dengan nama persis SPEC; tambahan yang tidak disebut SPEC ditandai (+).

| Tanggung jawab | File | Catatan |
|---|---|---|
| `Iso` | `scripts/systems/iso.gd` | `dunia_ke_layar`, `layar_ke_dunia`, `posisi_gambar` (dibulatkan), konstanta arah. Hanya yang dibutuhkan 0B (D-2); item Fase 1 tidak dicentang |
| `TouchZones` | `scripts/systems/touch_zones.gd` | `rect_stick`, `rect_swipe`, `zona_di`; semua tepi inklusif |
| `StickMap` | `scripts/systems/stick_map.gd` | `petakan`, `jepit_geser`, `dari_tombol` (keyboard editor, AC-13); satu fungsi `_layar_ke_kontrol` membalik sumbu Y |
| `TouchRouter` | `scripts/systems/touch_router.gd` | `RefCounted`, signal `swipe_selesai`, `tekan`/`geser`/`lepas`/`batal`/`batal_semua`/`atur_kidal` |
| `BikeDrive` | `scripts/systems/bike_drive.gd` | `langkah()` mengembalikan `BikeDrive.Hasil` (kecepatan, lateral, jarak maju, lateral efektif, tingkat dan arah sprite) |
| (+) `JalanDaur` | `scripts/systems/jalan_daur.gd` | Logika murni jalan tanpa ujung: sel tanah yang menutup layar, jenis ubin, slot objek berkala |
| (+) `PikselLingkaran` | `scripts/systems/piksel_lingkaran.gd` | Cakram dan cincin per piksel untuk tampilan stick |
| Node input + tampilan | `scripts/ui/kontrol_touch.gd` (`KontrolTouch`) | `_input`, notifikasi app, gambar stick/garis swipe, keyboard editor |
| HUD sementara | `scripts/ui/hud_dev.gd`, `bar_kecepatan.gd`, `scenes/ui/hud_dev.tscn` | |
| Pengendali sepeda uji | `scripts/entities/sepeda_uji.gd`, `scenes/entities/sepeda_uji.tscn` | |
| Scene uji | `scenes/dev/jalan_uji.tscn`, `scripts/entities/jalan_uji.gd`, `tanah_daur.gd`, `objek_daur.gd`, `scenes/dev/rumah_graybox.tscn`, `kotak_surat_graybox.tscn` | `run/main_scene` kini `jalan_uji.tscn` |
| Terjemahan dan tema | `translations/ui.csv` (+ `.import`, `ui.id.translation`), `assets/ui/theme.tres` | 3 kunci: `HUD_KECEPATAN`, `HUD_KECEPATAN_ANGKA` (`{v} u/d`), `HUD_KIDAL` |
| Tes | `tests/tes_input_murni.gd`, `tests/tes_input_scene.gd` (pembantu, dipanggil `run_tests.gd`), `tests/probe_input_jendela.gd` | `run_tests.gd` tetap runner tunggal; hitungan `check` satu |
| Alat | `tools/cek_blok_piksel.py` + opsi `--kecualikan` | Untuk melewati kotak teks HUD |

Aksi InputMap: `stick_atas`, `stick_bawah`, `stick_ke_seberang`, `stick_ke_dekat` (panah dan WASD, `physical_keycode`). Dipilih nama tanpa `kiri`/`kanan` (kata itu ditolak penjaga gaya kode).

#### Bukti per AC (file dan tes)

| AC | Bukti |
|---|---|
| AC-1 | Clone bersih di scratchpad (`git clone --branch feat/fase0bc-input-export`): `godot --headless --import` exit 0, `grep -cE "ERROR\|SCRIPT ERROR\|WARNING"` = 0, `/usr/bin/git status --porcelain -uall \| wc -l` = 0. Lihat "Temuan teknis" nomor 5 (satu masalah impor yang ditemukan dan diperbaiki) |
| AC-2 | `1840 lolos, 0 gagal` (sebelumnya 950), pemeriksa exit 0 termasuk `--ketat`, `uji_pemeriksa.py` 16 kasus 0 menyimpang. Tidak ada tes dihapus atau di-skip; yang diubah: tes `run/main_scene` (lihat AC-11) dan `speed_scale` (AC-17) |
| AC-3 | `godot --headless --path . --quit-after 2` hanya mencetak banner; 0 `ERROR`/`WARNING` (di repo kerja dan clone bersih) |
| AC-4 | Penjaga lama otomatis memindai semua `.gd` baru (tab, tipe return, tipe variabel, `for x: T in`, tanpa `kiri`/`kanan` di kode, tanpa hex/`Color("...")`, tanpa angka literal selain 0/1/2/-1/-2 di `systems/entities/ui`); semuanya lolos tanpa melonggarkan penjaga. Semua angka baru ke `Config` (+39 konstanta, satu baris, `ConfigParser` lolos) |
| AC-5 | `TesInputMurni._test_touch_zones`: 640/780/800 x bawaan/kidal, zona persis angka DESIGN_SPEC 3.7, cermin persis, tepi tiap zona di dalam dan 1 px di luar (kiri, kanan, atas, bawah, pojok), celah, strip atas bebas |
| AC-6 | `_test_stick_map`: 14,9 / 15,0 / 15,1 / 100 / 150% pada 6 arah; linear (57,5% = 0,5); tanpa lompatan (maks 0,00118 per 0,1% radius); monoton; sumbu Y dibalik (jari ke atas = (0, 1)); NaN/INF = nol |
| AC-7 | `_test_touch_router`: skenario a..i (a stick melayang, b dua jari kedua urutan, c jari kedua diabaikan, d jari diangkat + swipe tercatat sekali dengan durasi dari parameter, e index tak dikenal/ganda/negatif/NaN, f mulai di luar zona, g zona hanya saat turun, h kidal + batalkan semua + lebar 640/800, i `batal_semua`); ditambah `batal(index)` dan durasi tak negatif |
| AC-8 | `_test_bike_drive`: target 3,0 / 4,5 / 6,0 / 1,5 (+ -0,5 = 2,25), akselerasi dan perlambatan, dt besar tidak melewati target, dt nol/negatif/NaN/INF tanpa perubahan, batas 1,5..6,0, lateral dijepit +-1 ubin, diagonal, jarak = integral (4,5 ubin), 2000 rangkaian acak seed tetap (deterministik dan aman) |
| AC-9 | `_test_iso`: (1,0) -> (32,16), (0,1) -> (-32,16), maju (32,-16) kemiringan 1:2, 100 langkah tepat, bolak-balik 300 titik (toleransi karena `Vector2` float32), linear, `posisi_gambar` bulat |
| AC-10 | `_test_stick_ke_animasi`: a netral `santai_normal`; b atas penuh `ngebut_normal` (+ ambang 0,32/0,34 dan 0,79/0,81); c bawah penuh `santai_normal` dan turun ke 1,5; d kiri penuh maju 3,0 lateral -3,0 = `santai_serong_kiri`, lalu normal setelah membentur tepi jalan; e kanan penuh `santai_serong_kanan`; f lihat di bawah |
| AC-11 | `TesInputScene._test_scene_jalan_uji` dan `_test_jalan_tanpa_ujung`: tanah dan rumah didaur, 60 detik ngebut (358 ubin) di 3 lebar dengan cakupan layar dicek tiap detik pada scene sungguhan, sepeda di sepertiga kiri (simpangan terbesar tercatat di tes, batas 8 px) di lateral -1..1 dan jarak 0..250, tanpa zoom, posisi dan skala bulat, Nearest, Y-sort (`Objek` induk, titik pijak) |
| AC-12 | `_test_input_terpadu`: event sintetis lewat `Input.parse_input_event` pada jendela 2340x1080 (viewport 780x360): koordinat, dua jari (dua urutan), background (`propagate_notification(FOCUS_OUT)` dan `SceneTree.notification(PAUSED)`), `canceled`, strip atas, klik mouse tidak jadi stick. Kecepatan, posisi, dan animasi sepeda diperiksa. Kidal di `_test_kidal_dan_hud` (3 lebar) |
| AC-13 | `_test_tombol_keyboard` (16 kombinasi, panjang <= 1), `_test_proyek_dan_keyboard` (aksi, `keyboard_aktif == OS.has_feature("editor")`, dimatikan = nol, sentuhan didahulukan, tidak ada emulasi sentuhan dari mouse). Nonaktif di build ekspor TIDAK bisa dibuktikan tanpa export (dokumentasi Godot: tag `editor` hanya ada di build editor); dibuktikan di 0C bila perlu |
| AC-14 | Piksel stick/garis swipe: tekstur dicek dari `Palette` (isi TEXT 14%, garis TEXT 70% setebal 2 px, knob ACCENT radius 15); tangkapan layar 15 berkas: 0 blok 3x3 tidak seragam di luar teks HUD |
| AC-15 | `_test_scene_jalan_uji` + `_test_kidal_dan_hud`: `CanvasLayer` terpisah, anchor + Container, hanya tombol yang menerima sentuhan, tombol di y 4..40 (< 48) di luar kedua zona (pojok dan pusat, 3 lebar, kedua mode), sentuhan di tombol tidak diklaim, panel x 210 lebar 170 dan pindah ke lebar-210 saat kidal, bar 75% untuk 4,5 u/d, angka lewat `HUD_KECEPATAN_ANGKA`, ukuran font dari tema (10/6) |
| AC-16 | `_test_terjemahan`: header `keys,id`, kunci `HUD_*`, tanpa duplikat/kosong, placeholder bernama, `.import` + `.translation` + pendaftaran + fallback, `tr()` tiap kunci = kolom CSV, semua `tr("...")` di `scripts/` dan `text` di `scenes/` merujuk kunci yang ada, 7 contoh buruk sintetis ditolak |
| AC-17 | Q-002 dan Q-003 ditutup (lihat tabel Temuan); 36 mutan nyata dijalankan, semuanya ditangkap (bagian "Uji mutasi") |
| AC-18 | `AGENTS.md`, `.cursor/rules/00-project-core.mdc`, `docs/README.md`, `docs/ROADMAP.md` bagian 6 dan `docs/BALANCING.md` diperbarui. **Bagian "perintah ekspor" menunggu Dev-0C** (belum ada perintahnya). `ROADMAP.md` 4b dan `DEV_PHASES.md` tidak disentuh |

AC-10(f), diagonal atas-seberang tepat di batas 22,5 derajat: keyboard diagonal = (-0,7071, 0,7071). Kecepatan tujuan = 3,0 + 3,0 x 0,7071 = 5,1213 dan lateral = 0,7071 x 3,0 = 2,1213 u/d, sehingga tan(sudut) = 0,41421 = tan 22,5 derajat tepat (rasio itu = akar 2 - 1, kebetulan aljabar). Hasilnya `cepat_serong_kiri`: batas bawah serong inklusif dan toleransi 1e-6 derajat di `LoperAnim.besar_arah_dari_sudut` mencegah derau desimal membalikkannya. Dijelaskan di `##` tes dan di BALANCING 2. Di permainan nyata keadaan ini tidak bertahan: lateral membentur tepi jalan (+-1 ubin) dalam 0,47 detik, sebelum kecepatan sempat mencapai 5,12 (0,71 detik), jadi sudutnya turun melewati 22,5 derajat dari atas (35 derajat di awal) lalu sprite kembali normal. Kasus di sekitar batas (lateral 1% lebih kecil = normal, 1% lebih besar = serong) dites. Di HP kedutan di sekitar 22,5 derajat tetap mungkin karena jari bergetar: NEEDS-MANUAL (SPEC).

#### Temuan teknis (untuk orchestrator dan QA)

1. **Koordinat event sentuh (diminta SPEC).** Dengan stretch `canvas_items` + integer + `expand`, `InputEventScreenTouch.position` dan `InputEventScreenDrag.position` yang tiba di `_input` sudah berada di ruang koordinat viewport game (0..780 x 0..360 pada jendela 2340x1080), BUKAN piksel jendela, dan transformasi kamera TIDAK ikut. Buktinya (`tes_input_scene.gd`, `_test_input_terpadu`): event sintetis dengan posisi piksel jendela (300, 780) tiba di `TouchRouter` sebagai (100, 260) pada skala x3; hasilnya sama setelah sepeda dipindah 300 ubin dan kamera di (9732, -4837). Penyebabnya: `Viewport::_make_input_local` memakai `get_final_transform()` (stretch x global canvas transform); `Camera2D` mengubah `canvas_transform`, bukan transform global itu. Jalur yang dipakai tes (`Input.parse_input_event` lalu `flush_buffered_events`) melewati jalur dispatch yang sama dengan event perangkat dari `SceneTree`, kecuali tahap dari driver tampilan; jadi yang tidak terbukti hanya sisi Android (NEEDS-MANUAL). Node input memakai `_input` (bukan `_unhandled_input`) dan tidak menandai event tertangani: tombol HUD di strip atas tetap menerimanya lewat emulasi mouse-dari-sentuh bawaan (`emulate_mouse_from_touch` dibiarkan default true; yang dilarang SPEC hanya emulasi sentuhan dari mouse, dan itu tidak diaktifkan, dites).
2. **Notifikasi app.** `NOTIFICATION_APPLICATION_PAUSED` dan `FOCUS_OUT` sampai ke node lewat `SceneTree.notification()` dan `propagate_notification()`; dites kedua jalurnya, dan `batal_semua()` memang melepas stick tanpa menimbulkan gerak sendiri.
3. **`Vector2` berpresisi tunggal (float32).** Batas 0,80 tidak bisa dites lewat `Vector2(0, 0.80)` (menjadi 0,800000012 > 0,80 sehingga ngebut). Batas tepat dites langsung di `LoperAnim` (float64) dan di tes terpadu dipakai 0,79/0,81 dan 0,32/0,34. Toleransi tes proyeksi `Iso` di koordinat ribuan piksel memakai jarak eksplisit, bukan `is_equal_approx`.
4. **Jendela headless awal 64x64** (`root.size` = (64, 64), viewport terlihat 640x640). Tes scene selalu mengatur `root.size` dulu dan mengembalikannya di akhir.
5. **`gui/theme/custom` menghasilkan ERROR di impor pertama clone bersih.** Dengan tema proyek terisi, Godot mencoba memuat `theme.tres` (dan fontnya) saat startup sebelum font diimpor: 10 baris `ERROR:` pada `--import` pertama (exit 0, tapi AC-1 dan CI mensyaratkan 0 ERROR). Diperbaiki: tema dipasang di dua kontainer HUD (`theme = ExtResource(...)`), `gui/theme/custom` dikosongkan, dites (`tes_input_scene.gd`). Konsekuensi untuk Fase 1: scene UI baru harus memasang tema sendiri sampai ada cara memuatnya tanpa ERROR di impor pertama.
6. **Teks HUD bukan blok piksel.** Lexend adalah font vektor; hasil render beranti-alias di resolusi layar, jadi `cek_blok_piksel.py` melaporkan sekitar 424 blok tidak seragam di dua kotak HUD (tombol dan panel). Dunia, sprite, stick, dan garis swipe 0 blok. Alat diberi `--kecualikan X0,Y0,X1,Y1`; `tests/probe_input_jendela.gd` mencetak kotak yang perlu dikecualikan. Font piksel (atau teks yang dirender di 1x lalu diskalakan Nearest) tetap pilihan desain Fase 1, bukan keputusan Dev.

#### Keputusan dan deviasi kecil (bisa ditolak di review PR)

- **Koordinat jalan uji.** Garis tengah jalan = x 0; aspal x di -1..1 (ubin berpusat di +-0,5), trotoar +-1..2, rumput di luar. Ini bergeser 0,5 ubin dari penamaan sel graybox lama (pusat sel bulat) tetapi tata letak layarnya sama. Rumah di x -2,0 dan kotak surat di x -1,5, tiap 4 ubin, hanya sisi `seberang` (sisi `dekat` belum diputuskan, ROADMAP 5).
- **Kamera mengikuti sepeda penuh** (x dan y, dibulatkan), sepeda tetap di sekitar 33,3% lebar dan 60% tinggi, bukan hanya mengikuti sumbu jalan. Akibatnya geser lateral terlihat sebagai dunia yang bergeser dan sprite yang berputar, bukan sepeda yang berpindah di layar. Ini memenuhi "+-8 px di semua lebar" dari SPEC; apakah kamera nanti hanya mengikuti sumbu jalan adalah keputusan Fase 1.
- **Tingkat sprite dari komponen ATAS stick**, bukan panjang vektor (D-4 menyebut "kekuatan stick"; `LoperAnim.tingkat_dari_stick` didokumentasikan "kekuatan stick ke atas"). Stick penuh ke samping tanpa atas = santai. BALANCING 2 menulis "posisi stick"; kalimat klarifikasi ditambahkan di sana.
- **Pedal rate tidak dikaitkan ke kecepatan** (tetap 1,0): SPEC hanya meminta `speed_level` dan `steer`. Saat melambat ke 1,5 u/d animasi kayuh tetap pada laju bawaan tingkat santai.
- **Swipe di 0B**: hanya terdeteksi dan digambar; hasilnya (awal, akhir, durasi) tersedia lewat signal `swipe_selesai`, tanpa ambang minimum (butuh uji HP). Waktu swipe dari `Time.get_ticks_msec()` di node (sistem murni hanya menerima parameter).
- **Zona mati** inklusif dengan toleransi desimal `is_equal_approx` (15,0% harus nol walau pembulatan float).
- **Tidak digambar** (di luar AC dan butuh keputusan atau aset): empat panah kecil di dalam cincin dan cincin bawah menyala saat rem (DESIGN_SPEC 3.7, rem = Fase 1); garis tegak WARN di 80% bar kecepatan (DESIGN_SPEC 3.5), karena tingkat sprite berasal dari stick, bukan dari kecepatan, sehingga penanda itu menyesatkan; garis dalam panel `UI_PANEL_RAISED` (DESIGN_SPEC 1.3) karena `StyleBoxFlat` hanya punya satu garis tepi (menunggu panel 9-slice). Panel memakai garis luar 1 px `OUTLINE` dan sudut tegas.
- **`LANGKAH_WAKTU_MAKS_DETIK` = 0,1** membatasi `delta` per frame di `JalanUji` supaya app yang kembali dari background tidak melompat jauh. Angka usulan.
- **Blok tanah**: satu blok tetap (maks 450 `Sprite2D` pada lebar 800, 377 pada 640) dibangun sekali untuk lebar terbesar dan digeser kelipatan satu ubin; tidak dibangun ulang per lebar. Margin satu ubin dipakai supaya aman terhadap geser lateral dan pembulatan kamera. Bila profil di HP menunjukkan beban, kurangi margin atau pakai `TileMapLayer`.
- **Posisi dunia float tanpa rebasing**: pada 6 u/d, 1 jam menempuh 21.600 ubin = sekitar 690.000 px; presisi float32 `Vector2` turun ke 0,06 px. Bukan masalah di sesi pendek; rute sungguhan (Fase 3) memakai segmen dan posisi kecil.

#### Selisih dokumen yang ditemukan (docs.mdc: sebut ke pemilik, jangan ditambal diam-diam)

- BALANCING 2 ("sprite memilih tingkat dari posisi stick") vs implementasi (komponen atas): sudah diperjelas di BALANCING 2, sumber kebenaran tetap `LoperAnim`.
- DESIGN_SPEC 3.7 menyebut knob di dalam cincin; di jangkauan penuh pusat knob tepat di tepi cincin (radius jangkauan 35 = radius cincin) sehingga knob menonjol 15 px. Mock `design/screens/kontrol.png` hanya menunjukkan knob di tengah. Belum ada angka "knob dibatasi ke radius cincin dikurangi radius knob"; saya biarkan jangkauan 35 apa adanya.
- DESIGN_SPEC 3.5 "x 210, lebar 170" tumpang tindih dengan zona swipe (x >= 210). Panel tidak menerima sentuhan (IGNORE) sehingga swipe di atasnya tetap bekerja; tolong nilai di HP apakah panel di bawah jempol kanan mengganggu.

#### Uji mutasi (bukti tes menangkap bug; skrip sementara di scratchpad, tidak di-commit)

36 mutan satu baris diterapkan satu per satu pada kode asli lalu dijalankan `run_tests.gd` + `cek_keluaran_tes.py`, dikembalikan setelahnya (`git status` bersih). Semuanya ditangkap (exit Godot 1, pemeriksa 1, 1 sampai 48 `GAGAL`): `skala_kayuh` absf (Q-002); zona mati bergeser; sumbu Y tidak dibalik; zona swipe tepi +1; turun dobel diterima; swipe dicatat dua kali; kidal tidak membatalkan; `batal_semua` hanya stick; stick digeser ke zona lain berubah peran; perlambatan = akselerasi; lateral tidak dijepit; arah dari stick bukan gerak nyata; tingkat dari panjang stick; tanda `Iso` salah; koordinat event dibagi 3; `FOCUS_OUT` dan `PAUSED` tidak membatalkan; `canceled` diabaikan; keyboard nonaktif tak berlaku; zoom kamera 1,5; sepeda di tengah layar; zona mati 20%; tombol menembus strip atas; slot daur kurang; tanah tidak ikut maju; rumah tidak didaur; `Color.RED` di skrip; string `"kiri"` di skrip; teks pemain tertanam; kunci `tr()` tidak ada; kalimat di scene; kidal tidak memindah panel; bar tidak ikut kecepatan; `steer` tidak diterapkan; posisi tidak dibulatkan; kunci hilang dari CSV.

#### Gerbang yang dijalankan (perintah dan hasil)

```
godot --headless --import                                   # repo kerja: 0 baris ERROR/WARNING
mkdir -p build && godot --headless --script res://tests/run_tests.gd 2>&1 | tee build/tests.log
                                                            # ... 1840 lolos, 0 gagal (sekitar 1,6 detik)
python3 tools/cek_keluaran_tes.py build/tests.log           # pemeriksa: lolos (1840 lolos, 0 gagal, 0 peringatan), exit 0
python3 tools/cek_keluaran_tes.py --ketat build/tests.log   # exit 0
python3 tools/tests_cek/uji_pemeriksa.py                    # uji pemeriksa: 16 kasus, 0 menyimpang
godot --headless --path . --quit-after 2                    # hanya banner; 0 ERROR/WARNING
godot --headless --path . --script res://tests/probe_layar.gd   # 8 ukuran, semua skala bulat (640/780/800 pada x3 dan x2)
# clone bersih:
git clone --branch feat/fase0bc-input-export <repo> <scratchpad>/klon
cd <scratchpad>/klon && godot --headless --import           # exit 0, 0 ERROR/WARNING
/usr/bin/git status --porcelain -uall | wc -l               # 0
godot --headless --script res://tests/run_tests.gd ...      # 1835 lolos, 0 gagal (sebelum 5 tes tekstur ditambahkan); pemeriksa --ketat exit 0
godot --headless --path . --quit-after 2                    # 0 ERROR/WARNING
```

#### Tangkapan layar (non-headless, OpenGL 4.1 Metal, Apple M1)

Perintah (tiap ukuran; jendela terbuka sekitar 5 detik lalu menutup sendiri):

```
godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_input_jendela.gd -- docs/loop/20261009-fase0bc-input-export/shots/iter1
```

Jendela asli 1920x1080 / 2340x1080 / 2400x1080 -> viewport 640 / 780 / 800 x 360, skala x3 bulat (dicetak probe). 15 berkas `shots/iter1/<ukuran>_<tahap>.png`, tahap: `awal`, `dua_jari` (stick atas penuh + swipe), `serong_seberang`, `serong_dekat`, `kidal`. Ketajaman (kotak teks HUD dikecualikan dengan `--kecualikan` dari keluaran probe):

```
python3 tools/cek_blok_piksel.py 3 --kecualikan 1026,12,1315,121 --kecualikan 630,954,1141,1057 shots/iter1/2340x1080_awal.png
  -> 269864 blok, 0 tidak seragam, 10936 blok dikecualikan, sisa tepi (0, 0)
```

Hasil sama (0 tidak seragam) untuk ke-15 berkas (kotak panel mengikuti sisi pada tahap `kidal`). Kontrol negatif: tanpa `--kecualikan` file `2340x1080_awal.png` melaporkan 424 blok tidak seragam, exit 1 (teks HUD). Yang terlihat di gambar: jalan naik ke kanan atas dengan kemiringan 1:2, sepeda di sepertiga kiri dan sekitar 60% tinggi, rumah dan kotak surat graybox bergeser, stick melayang (cincin pucat, knob oranye) di titik sentuh, garis putus swipe, panel kecepatan di x 210 (pindah ke sisi kanan saat kidal, tombol "Kidal" beraksen), sprite serong di `serong_*`. Penilaian rasa dan keterbacaan di HP tetap NEEDS-MANUAL.

#### Hal yang tidak bisa saya verifikasi

Rasa kontrol (ukuran stick 35 px, zona mati 15%, ambang 33%/80%, geser lateral bebas 3,0 u/d), 60 fps, perilaku sentuhan multi-jari dan gestur tepi di Android sungguhan, cutout kamera A54, nonaktifnya keyboard di build ekspor, dan dua hal yang hanya sampai di 0C (imersif, orientasi di manifes). Catatan untuk Dev-0C: `display/window/handheld/orientation=0` sudah ada di `project.godot`; `.gitignore` sudah menutup `builds/`, `*.apk`, `*.aab`, `.godot/` (tes lama memeriksa); AC-19 butuh tes baru di `run_tests.gd` (tambahkan sebagai berkas pembantu atau fungsi baru); `export_credentials.cfg` tidak boleh masuk diff; dan "perintah ekspor" di `AGENTS.md`/`00-project-core.mdc` (AC-18) ditambahkan di sana.

### Dev-0C (iterasi 1)

Lingkungan: macOS (Apple M1), `godot --version` = `4.7.2.stable.official.ed1daf0bf`, JDK 17 (Zulu 17.0.14), Android SDK `~/Library/Android/sdk` (build-tools 35.0.0, 36.0.0, 37.0.0), export templates 4.7.2 terpasang orchestrator. 4 commit kode/dokumen Dev-0C di atas Dev-0B (`946effb`, `abb313d`, `9ea914a`, `818ef40`) ditambah 1 commit LOG ini, tidak ada commit di `main`, tidak ada push. Hook `rtk` mengganti keluaran `git`; hitungan memakai `/usr/bin/git`. **Tidak menyentuh HP** (tidak menjalankan `adb` apa pun; lihat temuan 4 tentang `adb` yang dipanggil Godot sendiri), tidak mengunduh apa pun, tidak mengubah Editor Settings, tidak membuat `android/`. Logika dan scene 0B tidak diubah; satu perubahan `project.godot` dituntut ekspor (temuan 3).

**Status: AC-18, AC-19, AC-20, AC-23, AC-24 selesai. AC-21 dan AC-22 `BLOCKED` (tidak ada APK).**

#### BLOCKED: ekspor APK (AC-21, AC-22)

Perintah persis (dari root repo, `JAVA_HOME` diset seperti diminta orchestrator, `builds/` sudah dibuat):

```
export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home
godot --headless --path . --export-debug "Android" builds/kring-kring-debug.apk
```

Keluaran lengkap (tanpa baris kemajuan `first_scan_filesystem`), exit code **1**, durasi 2 detik, tiga kali dicoba (sebelum dan sesudah `export_presets.cfg` final, dan sesudah perubahan `project.godot`) dengan hasil identik:

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

ERROR: Cannot export project with preset "Android" due to configuration errors:
A valid Java SDK path is required in Editor Settings.

   at: _fs_changed (editor/editor_node.cpp:1401)
ERROR: Project export for preset "Android" failed.
   at: _fs_changed (editor/editor_node.cpp:1417)
cannot connect to daemon at tcp:5037: Connection refused
```

Penyebab: `~/Library/Application Support/Godot/editor_settings-4.7.tres` berisi `export/android/java_sdk_path = ""`. Godot 4.7.2 **tidak** memakai `JAVA_HOME` sebagai pengganti. Sesuai instruksi, Editor Settings tidak ditulis dan tidak ada jalan memutar (mis. `HOME` sementara, yang juga akan membuat kunci adb baru dan berisiko memunculkan dialog di HP). Tidak ada APK di `builds/` (kosong), debug keystore belum dibuat (butuh `keytool`).

**Usulan tunggal:** isi **Java SDK Path** dengan `/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home` (Editor → Editor Settings → Export → Android, atau ubah baris `export/android/java_sdk_path` di `editor_settings-4.7.tres` saat Godot tertutup; `docs/SETUP_ANDROID.md` bagian 2). Ini pengaturan mesin di luar repo dan butuh izin pemilik. Setelah itu orchestrator menjalankan `docs/SETUP_ANDROID.md` bagian 4 (ekspor) dan bagian 5 (isi APK) dan menyalin hasilnya ke sini. Urutan perintah AC-22 sudah siap di bagian 5 dokumen itu (`aapt2 dump badging`, `aapt2 dump xmltree --file AndroidManifest.xml`, `aapt2 dump permissions`, `apksigner verify --verbose --print-certs`, `unzip -l`, opsional `apkanalyzer manifest print`).

Risiko tersisa yang baru terlihat setelah Java terisi: nama opsi preset diverifikasi terhadap string biner Godot 4.7.2 dan perilaku filter diverifikasi lewat `--export-pack`, tetapi ekspor APK penuh belum pernah jalan. Hal yang paling mungkin muncul pertama: `WARNING`/`ERROR` soal ikon (tidak ada `application/config/icon`), versi build-tools, atau opsi yang namanya salah (Godot mengabaikan kunci tak dikenal tanpa pesan, jadi nilai di APK harus dicek lewat `aapt2`: package, versionCode/Name, allowBackup, orientasi, izin).

#### Bukti per AC

| AC | Bukti |
|---|---|
| AC-18 (sisa 0C) | Perintah ekspor (`--export-pack`, `--export-debug`) dan peta repo (`export_presets.cfg`, `builds/`, `tests/tes_export.gd`, `docs/SETUP_ANDROID.md`) di `AGENTS.md`, `.cursor/rules/00-project-core.mdc`, `docs/README.md` (tabel dokumen, struktur, status), `docs/ROADMAP.md` bagian 6. Baris "belum ada" tidak lagi menyebut `export_presets.cfg`; `android/` tetap belum ada (build tanpa Gradle). `ROADMAP.md` 4b dan 5 dan `DEV_PHASES.md` tidak disentuh. Commit `abb313d` |
| AC-19 | `export_presets.cfg` (satu preset `Android`, `runnable=true`, `package/unique_name="com.rmh.kring"`, landscape dari `display/window/handheld/orientation=0`, `screen/immersive_mode=true`, `architectures/arm64-v8a=true` dan tiga lainnya `false`, `gradle_build/use_gradle_build=false`, `version/code=1`, `version/name="0.1.0"`, 152 izin Godot ditulis eksplisit `false`, `custom_permissions` kosong, enam kolom `keystore/*` kosong, `user_data_backup/allow=false`, `exclude_filter="docs/*, tests/*, tools/*, build/*, builds/*"`). `tests/tes_export.gd` (dipanggil dari `run_tests.gd`): `_test_preset_asli`, `_test_preset_contoh_buruk` (**24 mutan sintetis** ditolak, pesan commit `946effb` salah menulis 23: package salah/kosong, arsitektur ekstra/arm64 mati, Gradle, izin internet/camera/kustom, kata sandi dan jalur keystore terisi, nama preset, runnable, versi, imersif, backup, exclude_filter, export_path/template lokal, kunci enkripsi skrip; ditambah nol preset, dua preset, tanpa bagian opsi, dan kontrol positif), `_test_gitignore` (baris wajib + **`git check-ignore`** untuk 10 jalur contoh dan kontrol negatif 5 jalur sumber), `_test_berkas_dilacak` (`git ls-files` tanpa keystore/kredensial/APK/AAB/`.godot/`/`build/`/`builds/`, 11 contoh buruk ditolak). `.gitignore` ditambah `*.keystore`, `*.jks`, `*.p12`, `export_credentials.cfg` (pengaman tambahan di luar daftar AC-19, alasan: AC-23). Tes tidak butuh APK, templates, atau Java (hanya `git`). Commit `946effb` |
| AC-20 | `docs/SETUP_ANDROID.md` (8 bagian: prasyarat dengan status nyata mesin ini, cara pasang templates dengan SHA-512, Java SDK Path, tabel preset dengan alasan dan label usulan, pengaturan project yang dituntut ekspor, nilai template terverifikasi, ekspor CLI, pemeriksaan isi APK, target API 36 dan syarat rilis, pasang/log/`pm list packages`/larangan `pm clear`/tangkapan layar + `cek_blok_piksel.py`, tabel masalah umum, checklist HP) dan baris di tabel `docs/README.md`. `grep -n -i -E "brainydungeon\|startlights\|quicksplit\|firebase\|admob\|release-please\|godot-share\|SharePlugin" docs/SETUP_ANDROID.md` kosong (exit 1), dan dijaga tes (`_test_panduan_setup`: istilah terlarang ditolak, istilah wajib dicek, README mendaftarkannya). Commit `946effb`, `9ea914a`, `818ef40` |
| AC-21 | **BLOCKED** (lihat atas). Tidak ada APK, durasi, atau ukuran APK |
| AC-22 | **BLOCKED** pada APK hasil ekspor. Sebagai bukti sebagian, perintah yang sama dijalankan pada `android_debug.apk` bawaan template (tabel "Nilai yang diminta SPEC" di bawah) supaya sintaks perintah terbukti jalan dan batas bawah nilai (minSdk, targetSdk) diketahui |
| AC-23 | `git diff main...HEAD --name-only \| grep -E '(\.keystore\|\.jks\|\.p12\|\.apk\|\.aab)$\|export_credentials\.cfg\|(^\|/)\.godot/\|(^\|/)builds?/'` kosong (exit 1); `git diff main...HEAD` tanpa kata sandi/token (grep pola `password="..."`, `BEGIN ... PRIVATE`, `ghp_`, `AKIA` kosong); `git ls-files` tanpa berkas terlarang; `builds/` kosong dan ter-ignore; tidak ada commit di `main` (`main` = `origin/main` = `6df6fc9`); tidak ada push; tidak ada nama berkas atau string Brainy Dungeon di diff |
| AC-24 | 4 commit Dev-0C bertipe `feat`/`docs`/`fix`/`docs`, bahasa Indonesia, perubahan yang saling bergantung bersama (preset + tes + `.gitignore` + panduan + README; `project.godot` + tes + panduan). Branch `feat/fase0bc-input-export`, tidak ada push |

#### Nilai yang diminta SPEC (AC-19, AC-22, D-8)

| Nilai | Hasil | Sumber / status |
|---|---|---|
| `minSdkVersion` | **24** (Android 7.0) | **Template 4.7.2** (`aapt2 dump badging android_debug.apk`). Tanpa Gradle tidak bisa diubah dari preset (Godot: `"Min SDK" can only be overridden when "Use Gradle Build" is enabled`). APK hasil ekspor: belum diverifikasi |
| `targetSdkVersion` | **36** (`compileSdkVersion` 36) | Template. Memenuhi syarat Google Play API 36 (TECH_PLAN Fase 0) untuk APK debug tanpa Gradle; APK hasil ekspor belum diverifikasi. Syarat rilis (AAB butuh Gradle, keystore rilis, izin, Data Safety) dicatat di `SETUP_ANDROID.md` bagian 5 |
| `allowBackup` | **`false`** lewat `user_data_backup/allow=false`. Template juga `false` | **Usulan**: belum ada save yang layak dicadangkan; tinjau di Fase 6 (`save-system`, `privacy-ads`). APK hasil ekspor: belum diverifikasi (cek `aapt2 dump xmltree`) |
| Izin | Preset: **tidak ada izin menyala** (152 `permissions/*=false`, `custom_permissions` kosong). Template: `aapt2 dump permissions` hanya mencetak `package: com.godot.game`, tanpa izin | `INTERNET` tidak diminta preset. Godot dapat menambahkannya otomatis pada build debug untuk debugger jarak jauh (string `android.permission.INTERNET` ada di eksportirnya, kemungkinan hanya untuk Remote Deploy dari editor); belum diverifikasi pada APK CLI. Bila muncul: wajar untuk debug, wajib ditinjau di build rilis. Izin pelacakan (`AD_ID`, lokasi) tidak mungkin muncul karena tidak ada plugin dan semua izin mati; dikonfirmasi pada APK nyata saat ekspor jalan |
| Orientasi | Template: `screenOrientation=0` (landscape terkunci, bukan sensor), `resizeableActivity=false`; Godot menulis ulang dari `display/window/handheld/orientation=0` (sudah dites di `run_tests.gd` dan `tes_export.gd`) | APK hasil ekspor: belum diverifikasi |
| Activity peluncur | Template: alias `com.godot.game.GodotAppLauncher` → `com.godot.game.GodotApp` | Dipakai perintah `am start -n com.rmh.kring/com.godot.game.GodotAppLauncher` di panduan; cocokkan dengan `launchable-activity` pada APK nyata |
| `native-code` | Template: `arm64-v8a armeabi-v7a x86 x86_64`; preset hanya `arm64-v8a` | Template di disk 121,4 MB (empat arsitektur); ukuran APK arm64 saja: belum diketahui |
| `apksigner verify` | Template: `DOES NOT VERIFY` / `Missing META-INF/MANIFEST.MF` (template tidak bertanda tangan, wajar) | Tanda tangan debug baru ada setelah ekspor |
| Durasi dan ukuran APK | Tidak ada (BLOCKED) | |
| Paket game (`--export-pack`, tanpa Java) | **78 entri, 212,4 KB**; tidak ada `tests/`, `tools/`, `docs/`, `build/`. Tanpa `exclude_filter`: 90 entri, 310,6 KB, dengan 12 entri `tests/*.gd`. `strings` pada paket: `res://tests` 0 kemunculan (dengan filter) vs 14 (tanpa), `TesInput` 0 vs 2 | Bukti bahwa filter bekerja dan cache kelas global ikut tersaring |

#### Temuan teknis (untuk orchestrator dan QA)

1. **`JAVA_HOME` tidak cukup di Godot 4.7.2.** Pesan sama dengan dan tanpa variabel itu; hanya `export/android/java_sdk_path` yang dibaca. Dicatat di `SETUP_ANDROID.md` bagian 1, 2, dan 7.
2. **`--export-pack` jalan tanpa Java** dan memakai preset dan filter yang sama (tampaknya jalur `pack_only` Godot melewati pemeriksaan konfigurasi ekspor; disimpulkan dari perilakunya, bukan dari kode sumber). Dipakai sebagai satu-satunya bukti filter ekspor sampai APK bisa dibangun. Perintahnya ada di `AGENTS.md`, `00-project-core.mdc`, ROADMAP 6, dan `SETUP_ANDROID.md` bagian 4.
3. **`rendering/textures/vram_compression/import_etc2_astc=true` ditambahkan ke `project.godot`** (commit `9ea914a`). Temuan ini tidak ada di SPEC. Godot menolak ekspor mobile tanpanya (string pesan Android: `ETC2/ASTC texture compression is required for Android export`), tetapi pesan itu tersembunyi di balik kesalahan Java. Dibuktikan dengan ekspor uji platform lain di salinan klon sementara di scratchpad (preset iOS sementara, bukan di repo): gagal dengan `configuration errors:` kosong, lolos (mulai mengemas) setelah pengaturan itu menyala. Efek di repo ini nol: semua tekstur Lossless; `--import` tidak mengubah berkas apa pun (`git status` bersih) dan paket tetap 78 entri 212,4 KB. **Belum dicoba pada ekspor Android sebenarnya.** Dijaga `tes_export.gd` (mutan `false` ditangkap). Ini satu-satunya perubahan `project.godot` dan satu-satunya sentuhan di luar tugas 0C; bisa ditolak di review PR (konsekuensinya ekspor Android gagal).
4. **Godot memanggil `adb` sendiri** karena preset `runnable` (`cannot connect to daemon at tcp:5037` di akhir tiap ekspor, juga `--export-pack`; kemungkinan `adb kill-server` saat keluar tanpa server). Bukan perintah dari Dev, dan tampaknya tidak ada server adb yang hidup pada semua percobaan (pesan `Connection refused`); tidak ada yang dipasang atau dikirim ke HP. Bila HP tercolok saat ekspor APK penuh, Godot dapat mencacah perangkat (daftar saja). Dicatat di `SETUP_ANDROID.md` bagian 4.
5. **Tidak ada ikon project** (`application/config/icon` kosong; string Godot: `No project icon specified`). Ikon sementara bukan scope SPEC (Fase 14 untuk final; TECH_PLAN Fase 0 menyebut "Ikon aplikasi sementara" tanpa menetapkan alatnya dan `art-assets.mdc` melarang PNG buatan tangan). Dugaan: Godot memakai ikon bawaan template; belum terbukti. Keputusan perlu dari orchestrator bila ekspor menghasilkan WARNING.
6. **`.json` ikut paket** pada `export_filter=all_resources` (terbukti: `assets/sprites/loper/loper_agen.json`), jadi `assets/data/*.json` nanti tidak butuh `include_filter`. File non-resource lain (`.md`, `.py`, `.gpl`, `.csv` mentah) tidak ikut; `translations/ui.csv` hanya lewat `.import` dan `.translation`.
7. **Template tidak bertanda tangan dan tanpa izin; `resizeableActivity=false`, `profileable` aktif.** Untuk app yang menargetkan API 36, Android 16 mengabaikan batasan orientasi dan resizability di layar besar (sw ≥ 600dp). A54 aman; tablet dan foldable terbuka tidak (catatan di `SETUP_ANDROID.md` bagian 5, belum diuji).
8. **Opsi preset 4.7 yang tidak ada di panduan lama:** `screen/edge_to_edge` (bawaan `false`, dicatat sebagai opsi pertama bila skala turun ke x2), `screen/background_color`, `shader_baker/enabled`, `gradle_build/custom_theme_attributes`. Daftar nama opsi dan 152 nama izin diambil dari string biner Godot 4.7.2 (`strings`), karena `godot --headless` tidak punya perintah membuat preset. Preset ditulis tangan dengan format `[preset.0]` + `[preset.0.options]` dan diurai ulang oleh `ConfigFile` di tes.
9. **Sisa AC-13 dari Dev-0B** (keyboard nonaktif di build ekspor) tetap tidak terbukti headless; ditambahkan sebagai langkah opsional di NEEDS-MANUAL.
10. **Pesan `ERROR:` dari `ConfigFile` pada berkas rusak** ditolak pemeriksa keluaran, jadi kasus "preset tidak bisa diurai" sengaja tidak dites (cabang pertahanan di `_pelanggaran_preset` tetap ada).

#### Uji mutasi Dev-0C (skrip sementara di scratchpad, tidak di-commit)

19 mutan satu baris pada berkas asli, masing-masing dijalankan `run_tests.gd` + `cek_keluaran_tes.py`, dipulihkan setelahnya (`git status` bersih): package `com.rmh.loperkoran`; kata sandi keystore rilis terisi; jalur keystore debug terisi; izin `internet` menyala; `x86_64` menyala; Gradle menyala; imersif mati; `tests/*` tidak dikecualikan; `version/code=2`; `runnable=false`; `.gitignore` tanpa `builds/`, `*.aab`, `*.keystore`, `.godot/`; panduan memuat `AdMob`; panduan memuat package project lain; panduan tanpa `pm clear`; README tanpa `SETUP_ANDROID.md`; orientasi proyek bukan landscape. Semuanya ditangkap (exit Godot 1 dan pemeriksa 1, 1 sampai 4 `GAGAL`). Tambahan: mutan `import_etc2_astc=false` ditangkap; `git add -f builds/x.apk kunci_uji.keystore` ditolak tes berkas dilacak (lalu dibatalkan).

#### Gerbang yang dijalankan (perintah dan hasil)

```
godot --headless --import                                   # repo kerja: exit 0, 0 baris ERROR/WARNING, git status kosong
godot --headless --script res://tests/run_tests.gd 2>&1 | tee build/tests.log
                                                            # ... 1948 lolos, 0 gagal (sebelumnya 1840: +108 pemeriksaan)
python3 tools/cek_keluaran_tes.py build/tests.log           # pemeriksa: lolos (1948 lolos, 0 gagal, 0 peringatan), exit 0
python3 tools/cek_keluaran_tes.py --ketat build/tests.log   # exit 0
python3 tools/tests_cek/uji_pemeriksa.py                    # uji pemeriksa: 16 kasus, 0 menyimpang
godot --headless --path . --quit-after 2                    # hanya banner; 0 ERROR/WARNING
godot --headless --path . --script res://tests/probe_layar.gd   # tanpa ERROR atau PECAHAN
# clone bersih (git clone --branch feat/fase0bc-input-export <repo> <scratchpad>/klon0c, diulang setelah commit terakhir kode):
godot --headless --import                                   # exit 0, 0 ERROR/WARNING
/usr/bin/git status --porcelain -uall | wc -l               # 0 (sebelum dan sesudah tes)
godot --headless --script res://tests/run_tests.gd ...      # 1948 lolos, 0 gagal; pemeriksa --ketat exit 0
godot --headless --path . --quit-after 2                    # 0 ERROR/WARNING
git diff main...HEAD --stat                                 # 77 berkas, 4020 penambahan (Dev-0B + 0C, sebelum commit LOG ini)
git diff main...HEAD --name-only | grep -E '(\.keystore|\.jks|\.p12|\.apk|\.aab)$|export_credentials\.cfg|(^|/)\.godot/|(^|/)builds?/'
                                                            # kosong (exit 1)
godot --headless --path . --export-pack "Android" build/kring-uji.pck   # exit 0, 78 entri, 212,4 KB
export JAVA_HOME=...zulu-17.jdk/Contents/Home; godot --headless --path . --export-debug "Android" builds/kring-kring-debug.apk
                                                            # exit 1: Java SDK Path kosong (BLOCKED)
```

#### Hal yang tidak bisa saya verifikasi

APK hasil ekspor sama sekali (isi manifes, izin akhir, tanda tangan, ukuran, `unzip -l`), perilaku di HP (imersif, skala x3, orientasi, ikon), `OS.has_feature("editor")` di build ekspor, dan apakah ETC2/ASTC adalah satu-satunya pemeriksaan proyek Android yang tersembunyi di balik kesalahan Java (iOS menunjukkan pola yang sama, Android belum dicoba).

## Keputusan & catatan
- Keputusan pemilik (2026-10-09): run 0B dan 0C digabung; izin pasang APK ke A54 (hanya orchestrator yang menyentuh HP); format terjemahan CSV `translations/ui.csv`; izin unduh export templates 4.7.2. Lihat SPEC.
- Orchestrator: export templates 4.7.2 diunduh dari `godotengine/godot-builds` (`Godot_v4.7.2-stable_export_templates.tpz`, 1,2 GB) ke folder scratchpad, SHA-512 dicocokkan dengan `SHA512-SUMS.txt` rilis, lalu diekstrak ke `~/Library/Application Support/Godot/export_templates/4.7.2.stable/` (status di bagian bawah setelah selesai).
- Keputusan struktur D-1..D-8 ada di SPEC; yang diambil orchestrator tanpa tanya pemilik dan bisa ditolak di review PR.
