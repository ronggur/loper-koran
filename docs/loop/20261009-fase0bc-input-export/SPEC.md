# SPEC — 20261009-fase0bc-input-export

Run **0B + 0C digabung** dari `docs/LOOP-DEV-QA.md` Bagian 6. Kontrak bagi Dev **dan** QA.

## Tujuan

Menutup kode Fase 0 (M0): sepeda placeholder bergerak di jalan graybox isometrik 2:1 lewat stick melayang di layar sentuh, dan project bisa diekspor jadi APK debug yang terpasang di HP. Bagian **0B** = input touch, logika pemetaan input → gerak yang murni dan dites headless, sprite yang memilih animasi dari gerak, HUD kecepatan sementara. Bagian **0C** = `export_presets.cfg`, `docs/SETUP_ANDROID.md`, APK debug di `builds/`, pemeriksaan target API dan template. Stamina, rem, pindah sisi, lemparan, dan kamera final tetap Fase 1 dan 2.

## Keputusan dari pemilik (dengan tanggal)

Terkunci, jangan ditanyakan ulang:

- **2026-10-09, run digabung.** 0B dan 0C satu run, satu branch (`feat/fase0bc-input-export`), satu PR. Ini mengesampingkan "jangan menggabungkan" di `LOOP-DEV-QA.md` Bagian 7 (sudah dicatat di Bagian 6/7, commit `97542e1`). Batas 2 iterasi dan satu QA per iterasi tetap. Boleh dua pemanggilan Dev berurutan di iterasi 1 (0B lalu 0C) sebelum QA.
- **2026-10-09, izin pasang ke HP.** Pemilik mengizinkan memasang APK ke Samsung A54 (SM-A546E, serial `RRCWA05E2NN`). Cakupan: memasang `com.rmh.kring` saja. Tidak menghapus atau mengubah app lain, tidak `pm clear`, tidak uninstall. HP dipakai bersama project lain (ada `com.rmh.brainydungeon`, `com.rmh.startlights`, `com.rmh.quicksplit`). **Hanya orchestrator yang menyentuh HP**, setelah QA; Dev dan QA tidak memasang, tidak memanggil `adb shell`, tidak mengirim ketukan. Orchestrator memeriksa dulu apakah HP sedang dipakai (layar menyala) sebelum meluncurkan app atau mengambil tangkapan layar.
- **2026-10-09, format terjemahan = CSV `translations/ui.csv`** (kolom `keys,id`). Sudah ditulis di `content-data.mdc` dan `DESIGN_SPEC.md` 5 (commit `e8cd78e`).
- **2026-10-09, izin unduh export templates Godot 4.7.2** (sekitar 1,2 GB, rilis resmi `godotengine/godot-builds`, SHA-512 dicocokkan dengan `SHA512-SUMS.txt`). Diunduh dan dipasang oleh orchestrator ke `~/Library/Application Support/Godot/export_templates/4.7.2.stable/` sebelum Dev 0C mulai. Dev tidak mengunduh apa pun.
- Dari run sebelumnya (ROADMAP 4b): Godot 4.7.2, Compatibility, base 640×360, stretch `canvas_items` + `integer` + `expand`, skala ×3, package `com.rmh.kring`, HP uji A54. Cadangan stretch `viewport` tidak boleh dipakai tanpa persetujuan pemilik.

Status **usulan** (jangan ditulis "dikunci"): ukuran ubin 64×32, font Lexend/Lilita One, semua angka di `BALANCING.md` 2, ukuran stick dan zona di `DESIGN_SPEC.md` 3.7, pengaturan preset export di D-8.

### Keputusan struktur orchestrator (bisa ditolak di review PR; dicatat di laporan akhir)

- **D-1. Kelas murni di `scripts/systems/`** (nama boleh berbeda kalau Dev punya alasan, dicatat di LOG; lima tanggung jawabnya harus ada dan dites): `TouchZones` (zona dari lebar viewport + kidal), `StickMap` (vektor stick → zona mati → kekuatan), `TouchRouter` (pelacak jari per `index`; instance `RefCounted`, tanpa node), `BikeDrive` (satu langkah kecepatan dan lateral), `Iso` (proyeksi). Node input hanya menerjemahkan `InputEvent` ke panggilan `TouchRouter` dan menggambar.
- **D-2. `Iso` minimal masuk run ini**, hanya konversi dunia↔layar dan konstanta arah, karena sepeda harus bergerak persis 2:1. Item Fase 1 "Sistem koordinat dunia ↔ layar..." **tidak dicentang** (kamera, ubin placeholder penuh, dan batas jalan menyusul).
- **D-3. Lateral di 0B = geser bebas dibatasi lebar jalan (placeholder)**, supaya arah sprite dari gerak sebenarnya bisa dilihat di HP. Tidak ada penguncian ke sisi `seberang`/`dekat`, rem, stamina, atau tabrakan. Tanda lateral: positif = sisi `dekat` (kanan bawah layar), negatif = `seberang`, sama dengan `LoperAnim.arah_dari_gerak`. Stick kiri → lateral negatif.
- **D-4. Tingkat sprite dari kekuatan stick** (setelah zona mati) lewat `LoperAnim.tingkat_dari_stick`; **arah sprite dari gerak sebenarnya** (kecepatan maju dan lateral hasil `BikeDrive`) lewat `LoperAnim.arah_dari_gerak` (BALANCING 2). Tingkat tidak dihitung dari kecepatan.
- **D-5. Opsi kidal hanya runtime** (bawaan: tangan kanan). Penyimpanan pengaturan menyusul bersama `SaveManager`/layar pengaturan (rule `save-system`). Untuk uji ada tombol toggle di scene uji.
- **D-6. Sumbu dunia:** maju = arah −y dunia (layar naik ke kanan atas), lateral positif = +x dunia (layar turun ke kanan). Posisi dunia dalam satuan ubin (`gdscript.mdc`), konversi ke piksel hanya di `Iso`.
- **D-7. Tema:** `assets/ui/theme.tres` berisi font dan ukuran saja (DESIGN_SPEC 1.2, 2); warna diambil dari `Palette` lewat skrip. Tidak ada literal warna di `.tres`. Panel 9-slice belum dibuat (belum ada panel).
- **D-8. Preset export (usulan, dicatat di `SETUP_ANDROID.md`):** tanpa Gradle build (belum ada plugin; baru Fase 8), arsitektur `arm64-v8a` saja, min SDK bawaan template, `version/code=1`, `version/name="0.1.0"`, mode imersif nyala, `allowBackup` dicatat nilainya. Kalau `targetSdkVersion` template lebih rendah dari 36 (syarat Google Play, TECH_PLAN Fase 0), itu **bukan** penghalang APK debug: catat sebagai syarat rilis (Gradle build) di `SETUP_ANDROID.md` dan LOG.

## Di luar scope

- Stamina, rem (ambang 90% ditahan 0,25 detik), penguncian sisi, batas tepi jalan resmi, tabrakan, kamera yang melebar saat ngebut (Fase 1). Tombol bel dan efek "kring" (Fase 1/2). Lemparan, garis bidik, dan arti swipe (Fase 2). Swipe di 0B hanya **terdeteksi dan diberi umpan balik visual** (garis putus ke posisi jari), tanpa efek lain dan tanpa ambang minimum yang dikunci (butuh uji HP, `ui-scenes.mdc`).
- Mode bantu (GDD 5.3). Penyimpanan opsi kidal. File terjemahan bahasa Inggris. Layar Boot, menu, atau pengaturan.
- Uji light 2D, glow, partikel, shader di HP (butir Fase 0 lain; **tidak** ditutup run ini, tetap terbuka di `DEV_PHASES.md`).
- Gradle build, plugin Android, iklan, analytics, keystore rilis, AAB, upload Play Console, ikon aplikasi final (Fase 14), perubahan `tools/loper_art/*.py`.
- Mengganti sprite pemain. Menyalin aset Brainy Dungeon (hanya boleh membaca `SETUP_ANDROID.md`-nya sebagai bahan adaptasi; nilai spesifiknya tidak disalin).
- `Q-001` (LoperSprite dengan `sprite_frames` null) tetap `DEFERRED`; kerjakan hanya bila `loper_sprite.gd` memang diubah di run ini.

## Kriteria penerimaan (bisa diuji)

Perintah dari root repo. `GODOT` = `godot` (4.7.2). Tes mengikuti `testing.mdc`: label bahasa Indonesia, merujuk bagian dokumen; waktu dan RNG jadi parameter.

### Umum

- AC-1: Pada clone bersih branch ini, `$GODOT --headless --import` selesai tanpa `ERROR:` / `SCRIPT ERROR`, dan sesudahnya `git status --porcelain` kosong (semua `.uid`, `.import`, dan `.translation` hasil impor ter-commit; `.godot/` tidak).
- AC-2: `$GODOT --headless --script res://tests/run_tests.gd 2>&1 | tee <log>` lalu `python3 tools/cek_keluaran_tes.py <log>` keluar 0, dengan ringkasan `N lolos, 0 gagal`. Tes lama tidak dihapus atau di-skip tanpa alasan tertulis di LOG. `python3 tools/tests_cek/uji_pemeriksa.py` tetap lolos.
- AC-3: `$GODOT --headless --path . --quit-after 2` selesai tanpa `ERROR:`, `SCRIPT ERROR`, atau `WARNING:`.
- AC-4: Semua `.gd` baru: tab, static typing (return di setiap fungsi, tipe eksplisit variabel dan `@export`), `##` bahasa Indonesia, tidak ada angka tuning di luar `Config`, tidak ada hex di luar `palette.gd`, tidak ada `kiri`/`kanan` untuk sisi jalan (nama sumbu layar hanya untuk input), tidak ada teks pemain di skrip atau scene selain kunci terjemahan.

### 0B — Input touch dan gerak

- AC-5 (`TouchZones`): dengan lebar viewport 640, 780, dan 800 (tinggi 360), zona stick = x 8–192, y 186–352 dan zona swipe = x 210 sampai (lebar − 20), y 48–352 (DESIGN_SPEC 3.7). Dengan kidal zona dicerminkan persis: stick x (lebar − 192)–(lebar − 8), swipe x 20 sampai (lebar − 210). Titik di luar kedua zona tidak masuk zona mana pun. Angkanya konstanta di `Config` (satu baris, satuan PX). Tes menyentuh tepi tiap zona (di dalam dan di luar 1 px).
- AC-6 (`StickMap`): radius penuh = `Config` (usulan 35 px, DESIGN_SPEC 3.7). Zona mati radial 15% (`Config.ZONA_MATI_STICK`): 14,9% dan 15,0% dari radius → vektor nol; 15,1% → kekuatan > 0 dan kecil; di atasnya dipetakan ulang linear ke 0..1 (tanpa lompatan di batas), 100% → 1,0, di atas 100% dijepit ke 1,0, arah dipertahankan. Sumbu Y layar (bawah = positif) dibalik di **satu** fungsi sehingga stick ke atas layar = maju positif; dites. Tes menyentuh 14,9 / 15,0 / 15,1 / 100 / 150%.
- AC-7 (`TouchRouter`): tes untuk tiap skenario, termasuk urutan terbalik bila relevan:
  - a. satu jari turun di zona stick → stick aktif, titik asal = titik sentuh (stick melayang), vektor mengikuti geseran dan dijepit ke radius;
  - b. **dua jari bersamaan** (stick + swipe), masing-masing dengan `index` sendiri, saling tidak mengganggu, kedua urutan turun;
  - c. jari kedua turun di zona stick saat stick sudah aktif → diabaikan, stick pertama tidak terganggu;
  - d. **jari stick diangkat** → vektor nol dan slot bebas (jari baru bisa mengambil); jari swipe diangkat → hasil swipe (titik awal, titik akhir, durasi dari parameter waktu, bukan `Time`) tercatat sekali;
  - e. drag atau up dengan `index` yang tidak pernah turun, dan turun dobel dengan `index` sama → tanpa error dan tanpa slot ganda;
  - f. sentuhan yang mulai di luar kedua zona tidak diklaim, walau digeser masuk zona;
  - g. jari stick yang digeser ke zona swipe tetap stick (zona hanya menentukan klaim saat turun);
  - h. **kidal**: zona tertukar, sentuhan di zona lama tidak diklaim; mengganti kidal membatalkan semua jari aktif;
  - i. `batal_semua()` (dipanggil saat app di-background atau kehilangan fokus) melepas semua jari dan menolkan vektor.
- AC-8 (`BikeDrive`, `Config`: BALANCING 2): stick netral → kecepatan menuju 3,0 u/d; kekuatan atas 0,5 → target 4,5; atas penuh → 6,0; bawah penuh → 1,5 (target linear antara santai dan ngebut/melambat). Kecepatan naik dengan akselerasi 3,0 u/d², turun dengan perlambatan 2,0 u/d², tidak melampaui target walau `dt` besar, tidak berubah bila `dt` = 0, tidak pernah di bawah `KECEPATAN_MELAMBAT_UD` atau di atas `KECEPATAN_NGEBUT_UD`. Lateral = komponen X stick × `KECEPATAN_LATERAL_UD`, posisi lateral dijepit ke lebar jalan (konstanta `Config`, usulan 2 ubin, BALANCING 2). Diagonal bekerja bersamaan (maju dan lateral dalam satu langkah). Murni dan deterministik: tanpa `Time`, RNG, atau node.
- AC-9 (`Iso`, ART_DIRECTION 2.2): satu ubin di sumbu x dunia = (+32, +16) px layar, di sumbu y = (−32, +16) px. Bolak-balik dunia → layar → dunia mengembalikan titik awal (titik acak dengan seed tetap, toleransi float). Gerak maju (−y) naik ke kanan atas dengan kemiringan tepat 1:2; lateral positif (+x) turun ke kanan.
- AC-10 (tes terpadu stick → animasi): urutan perintah → `BikeDrive` → `LoperAnim.nama_animasi` dites tanpa node: (a) netral → `santai` + arah normal; (b) atas penuh, lurus → `ngebut` + normal; (c) bawah penuh → `santai` (stick negatif = santai) dan kecepatan turun ke 1,5; (d) kiri penuh tanpa maju: maju 3,0 dan lateral −3,0 (sudut 45°) → serong seberang; (e) kanan penuh → serong dekat; (f) satu kasus diagonal atas-kiri yang jatuh tepat di batas 22,5°, hasilnya dicatat dan dijelaskan di `##`.
- AC-11 (scene uji): scene yang menjadi `run/main_scene` memuat jalan lurus **tanpa ujung terlihat** (ubin aspal, trotoar, rumput didaur di sekitar kamera, atau cukup panjang untuk 60 detik ngebut), penanda gerak (rumah dan kotak surat graybox berulang secara berkala, supaya kecepatan terbaca), `loper_agen.tscn` bergerak, dan kamera mengikuti dengan sepeda di sekitar sepertiga kiri layar (±8 px pada lebar 640, 780, 800). Y-sort benar (origin sprite di titik pijak). Posisi sprite yang digambar dibulatkan; gerak halus tetap di float di logika. Tidak ada zoom atau skala pecahan. `graybox.tscn` lama boleh tetap ada (probe layar dan tes lamanya); bila `run/main_scene` berubah, tes pengaturan proyek diperbarui dan alasannya dicatat di LOG.
- AC-12 (node input): `InputEventScreenTouch` dan `InputEventScreenDrag` dengan `index` per jari, dibaca di ruang koordinat viewport game (bukan piksel jendela), diteruskan ke `TouchRouter`; `NOTIFICATION_APPLICATION_PAUSED` dan `NOTIFICATION_APPLICATION_FOCUS_OUT` memanggil `batal_semua()`. Tes terpadu memasukkan event sintetis lewat node (`Input.parse_input_event` atau memanggil handler) pada viewport 780×360 dan memeriksa bahwa kecepatan, posisi, dan animasi sepeda berubah, termasuk skenario dua jari dan kidal. Tidak ada emulasi sentuhan dari mouse di `project.godot`.
- AC-13 (keyboard editor): panah dan WASD menghasilkan vektor stick lewat fungsi murni yang dites (4 tombol → vektor, diagonal tidak melebihi 1), aktif hanya bila `OS.has_feature("editor")`, nonaktif di build ekspor. Aksi `InputMap` di `project.godot` berbahasa Indonesia, tanpa `kiri`/`kanan` untuk sisi jalan.
- AC-14 (umpan balik visual, tanpa teks): stick digambar saat aktif di titik sentuh (cincin radius 35 `TEXT` 14% isi dan garis `TEXT` 70%, knob radius 15 `ACCENT`, DESIGN_SPEC 3.7, warna dari `Palette`), hilang saat dilepas; saat swipe ditahan digambar garis putus dari titik awal ke posisi jari dan hilang saat dilepas. Piksel tajam, skala bulat.
- AC-15 (HUD sementara): `CanvasLayer` terpisah, anchor dan Container (bukan posisi piksel absolut), memuat bar kecepatan (isi `TEXT`, latar `UI_PANEL_RAISED`, garis `OUTLINE`, tinggi 7, DESIGN_SPEC 1.3 dan 3.5) dengan label `tr("HUD_KECEPATAN")` dan angka kecepatan u/d (format angka, bukan teks terjemahan), serta tombol toggle kidal berlabel kunci `HUD_KIDAL` di strip atas (y < 48, di luar kedua zona kontrol, DESIGN_SPEC 3.7 dan `ui-scenes.mdc`). Panel kecepatan ikut berpindah sisi saat kidal. Tidak ada panel stamina atau koran. Tombol tidak mengklaim sentuhan kontrol dan sentuhan di tombol tidak menjadi stick atau swipe.
- AC-16 (terjemahan): `translations/ui.csv` (header `keys,id`), `.csv.import` dan `.translation` hasil impor ter-commit, terdaftar di `project.godot` (`internationalization/locale/translations`, fallback `id`). Kunci `UPPER_SNAKE_CASE` berawalan `HUD_`, tidak duplikat, tiap baris punya nilai. Tes: CSV valid; `TranslationServer`/`tr()` untuk tiap kunci menghasilkan teks, bukan kuncinya; setiap kunci `tr("...")` di `scripts/` dan setiap `text`/`tooltip_text` di `scenes/` merujuk kunci yang ada; tidak ada kalimat jadi di properti teks scene.
- AC-17 (temuan DEFERRED run 0A, karena `run_tests.gd` disentuh): **Q-002** — tes `pedal_rate` negatif memeriksa `speed_scale == 0.0`, dan tes ini gagal bila `skala_kayuh` memakai `absf`. **Q-003** — penjaga ditambah untuk: `Camera2D.zoom` bulat (scene dan skrip), pola `Color\.[A-Z_]+` di luar `palette.gd` ditolak, string `"kiri"`/`"kanan"` di skrip hanya boleh di `NAMA_ARAH` (atau daftar putih tertulis untuk nama aksi input), dan teks pemain di skrip/scene hanya kunci terjemahan. Setiap penjaga baru dibuktikan dengan tes negatif (contoh buruk sintetis yang ditolak), bukan hanya file asli yang lolos.
- AC-18: Perintah dan peta repo di `AGENTS.md` dan `.cursor/rules/00-project-core.mdc` diperbarui sesuai kenyataan (scene utama, `translations/`, perintah ekspor), dan `docs/README.md` (struktur dan status) serta `docs/ROADMAP.md` bagian 6 di commit yang sama dengan perubahannya. `ROADMAP.md` 4b dan `DEV_PHASES.md` **tidak** diedit Dev.

### 0C — Export Android dan APK debug

- AC-19 (`export_presets.cfg` di root repo, di-commit): tepat satu preset bernama `Android`, `runnable=true`, `package/unique_name="com.rmh.kring"`, orientasi landscape (selaras `display/window/handheld/orientation=0`), `screen/immersive_mode=true`, `architectures/arm64-v8a=true` dan lainnya false, `gradle_build/use_gradle_build=false`, `version/code=1`, `version/name="0.1.0"`, tidak ada izin kustom yang dinyalakan, jalur dan kata sandi keystore (`keystore/release*`, `keystore/debug*`) kosong, `.godot/export_credentials.cfg` tidak ada di diff. Nilai min SDK dan `allowBackup` yang dipakai dicatat di `SETUP_ANDROID.md`. Tes headless membaca file ini dan memeriksa semua poin di atas, ditambah `.gitignore` menutup `builds/`, `*.apk`, `*.aab`, `.godot/` (cek dengan `git check-ignore`).
- AC-20 (`docs/SETUP_ANDROID.md`, bahasa Indonesia, terdaftar di tabel `docs/README.md`): diadaptasi dari panduan Brainy Dungeon, hanya untuk repo ini. Memuat: tabel prasyarat dengan status nyata mesin ini (Godot 4.7.2, JDK 17 beserta jalur, Android SDK dan versi `build-tools`, `adb`, template export 4.7.2 dan cara pasang dari CLI dengan verifikasi checksum, `export/android/java_sdk_path` di Editor Settings, debug keystore dibuat otomatis oleh Godot di luar repo), perintah ekspor CLI persis, perintah pasang dan log (`adb install -r`, `adb logcat -s godot`), cek `pm list packages` sebelum uninstall dan larangan `pm clear` tanpa izin, pengaturan preset beserta alasannya (D-8), hasil cek target API dan catatan syarat rilis, tabel masalah umum, dan **checklist uji HP** (NEEDS-MANUAL di bawah). Tidak boleh memuat nilai spesifik Brainy Dungeon (package `com.rmh.brainydungeon`, `startlights`, `quicksplit`, plugin share/Firebase, keystore, release-please); QA memeriksanya dengan `grep -i`.
- AC-21 (APK debug): dibangun dengan perintah di `SETUP_ANDROID.md` (mis. `godot --headless --path . --export-debug "Android" builds/kring-kring-debug.apk`), exit 0 dan berkas ada; Dev mencatat perintah persis, durasi, dan ukuran di LOG. `builds/` tidak di-commit. Bila ekspor gagal karena sesuatu di luar jangkauan (mis. JDK atau SDK), tandai `BLOCKED` dengan keluaran lengkapnya, jangan berpura-pura berhasil.
- AC-22 (bukti isi APK, dijalankan Dev dan diulang QA sendiri): `aapt2 dump badging` (dari `~/Library/Android/sdk/build-tools/<versi>/`) menunjukkan `package: name='com.rmh.kring'`, `versionCode`, `versionName`, `minSdkVersion`, `targetSdkVersion`, `native-code: 'arm64-v8a'`, activity peluncur; manifes (`aapt2 dump xmltree --file AndroidManifest.xml` atau `apkanalyzer manifest print`) menunjukkan orientasi layar landscape; `aapt2 dump permissions` dicatat lengkap dengan penjelasan tiap izin (izin `INTERNET` di build debug dijelaskan: untuk debugger jarak jauh; build rilis nanti wajib ditinjau, `privacy-ads.mdc`) dan tidak ada izin pelacakan (mis. `AD_ID`, lokasi); `apksigner verify` pada APK menunjukkan tanda tangan debug yang valid. `targetSdkVersion` dibandingkan dengan syarat API 36 dan hasilnya (lolos atau syarat rilis) dicatat sesuai D-8.
- AC-23 (kebersihan): `git diff main...HEAD` tidak memuat `*.keystore`, `*.jks`, `*.p12`, `export_credentials.cfg`, `*.apk`, `*.aab`, `.godot/`, `build/`, `builds/`, token, atau kata sandi; tidak ada commit di `main`; tidak ada push; tidak ada aset dari Brainy Dungeon.
- AC-24: Commit kecil, format `<tipe>: <ringkasan>` bahasa Indonesia, di branch `feat/fase0bc-input-export`. Perubahan yang saling bergantung dalam satu commit (mis. `Config` + dokumen angkanya, CSV + `.import` + `.translation` + pendaftaran di `project.godot`). Tidak ada push.

## Perubahan file/struktur yang diharapkan

```
project.godot                              (aksi InputMap, terjemahan, main_scene bila diganti)
export_presets.cfg                         (preset Android, tanpa rahasia)
translations/ui.csv                        (+ ui.csv.import, ui.id.translation)
assets/ui/theme.tres                       (font dan ukuran saja)
scenes/dev/jalan_uji.tscn                  (atau nama setara; scene utama sementara yang bisa digerakkan)
scenes/ui/hud_dev.tscn                     (HUD sementara; nama boleh berbeda)
scripts/config.gd                          (zona, radius stick, lebar jalan, dst., satu baris per konstanta)
scripts/systems/touch_zones.gd | stick_map.gd | touch_router.gd | bike_drive.gd | iso.gd
scripts/ui/                                (node input, tampilan stick/garis swipe, HUD)
scripts/entities/                          (pengendali sepeda uji yang menghubungkan system ke LoperSprite)
tests/run_tests.gd                         (+ tes AC-5..AC-17, AC-19; boleh dipecah ke berkas bantu di tests/)
docs/SETUP_ANDROID.md
docs/README.md, docs/ROADMAP.md (bagian 6), AGENTS.md, .cursor/rules/00-project-core.mdc
```

## Tes yang harus ada

AC-5 sampai AC-10 dan AC-12, AC-13, AC-16, AC-17, AC-19 punya tes di `run_tests.gd` (label bahasa Indonesia, rujuk bagian dokumen). Tiap bug yang ditemukan QA mendapat tes regresi, kecuali murni visual atau rasa kontrol.

## Butuh uji perangkat nyata (NEEDS-MANUAL)

Orchestrator memasang APK ke A54 setelah QA PASS. Yang di bawah **tidak bisa dinilai agent** dan menutup Fase 0:

- Stick muncul di bawah jempol kiri, sepeda bergerak naik ke kanan atas; atas → ngebut (sprite berdiri), netral → santai, bawah → melambat; kiri/kanan → sprite serong atau 90° dan sepeda bergeser; tidak ada animasi yang berkedip di batas sudut 22,5°.
- Dua jempol bersamaan: stick dan garis swipe jalan tanpa saling mengganggu; angkat satu jari tidak mematikan yang lain.
- Tombol kidal menukar zona dan panel; tombol di strip atas tidak tersentuh tak sengaja.
- Kembali dari background (tombol home lalu buka lagi): stick tidak macet, tidak ada gerak sendiri.
- Ukuran stick (radius 35 px game ≈ 105 px layar), zona mati 15%, ambang tingkat 33%/80%, terasa wajar; catat angka yang ingin diubah (jangan diubah di run ini).
- Ketajaman dan skala (Q-013 run 0A): tangkapan layar `adb exec-out screencap -p`, lalu `python3 tools/cek_blok_piksel.py 3 <png>` → 0 blok tidak seragam; layar 2340×1080 menampilkan viewport 780×360 skala ×3 tanpa bilah sistem. Bila skala turun ke ×2, catat dan perbaiki di preset (imersif).
- Kinerja: terasa 60 fps (tanpa pengukur resmi di run ini).
- Tetap terbuka dan bukan bagian run ini: light 2D/glow/partikel/shader di Compatibility (Q-014).

## Dokumen yang ikut diperbarui

Dev: `AGENTS.md`, `.cursor/rules/00-project-core.mdc`, `docs/README.md`, `docs/ROADMAP.md` bagian 6, `docs/SETUP_ANDROID.md` (baru), `docs/BALANCING.md` bila angka baru (zona, radius, lebar jalan) perlu dicatat. Orchestrator: `docs/ROADMAP.md` 4b dan 5, `docs/DEV_PHASES.md` (centang butir yang terbukti, di commit terpisah setelah PR dibuka), `docs/design/DESIGN_SPEC.md` bila ada selisih yang ditemukan. Tidak ada keputusan di ROADMAP bagian 5 yang ditutup oleh run ini.
