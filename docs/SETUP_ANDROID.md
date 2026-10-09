# Setup Android: APK debug dan uji di HP

Panduan membangun APK debug **Kring Kring!** (`com.rmh.kring`) dari CLI, memeriksa isinya, memasangnya ke HP Android, dan checklist uji M0. Diadaptasi dari panduan Brainy Dungeon (hanya polanya), lalu ditulis ulang untuk repo ini berdasarkan perintah yang benar-benar dijalankan di mesin pengembang pada 2026-10-09. Tanpa Gradle, tanpa plugin Android, tanpa keystore rilis (belum ada, Fase 14).

Label **usulan** berarti belum dikunci (rule `docs`). Nilai preset di bagian 3 adalah usulan SPEC run `20261009-fase0bc-input-export` (D-8), bukan keputusan pemilik. Semua hasil di bawah adalah keluaran perintah yang dijalankan pada 2026-10-09 (APK `builds/kring-kring-debug.apk`); yang belum dijalankan ditandai "belum".

## 1. Prasyarat dan status mesin ini

Status dicek 2026-10-09 (macOS, Apple M1). Perintah cek ada di kolom terakhir.

| Kebutuhan | Status | Nilai nyata | Cek |
|---|---|---|---|
| Godot 4.7.2 | ✅ | `/opt/homebrew/bin/godot` → `/Applications/Godot.app/Contents/MacOS/Godot`, `4.7.2.stable.official.ed1daf0bf` | `godot --version` |
| JDK 17 | ✅ | Zulu 17.0.14 di `/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home`. JDK 11 juga terpasang; `java -version` bawaan = 17 | `/usr/libexec/java_home -V` |
| Android SDK | ✅ | `~/Library/Android/sdk`: `build-tools` 35.0.0, 36.0.0, 37.0.0; `platforms` android-29 sampai 36 (tanpa 32); `platform-tools`; `cmdline-tools/latest` | `ls ~/Library/Android/sdk/build-tools` |
| `adb` | ✅ | `/opt/homebrew/bin/adb` (platform-tools 37.0.0, juga ada di SDK) | `command -v adb` |
| Export templates 4.7.2 | ✅ | `~/Library/Application Support/Godot/export_templates/4.7.2.stable/` (isi `android_debug.apk`, `android_release.apk`, `version.txt` = `4.7.2.stable`) | `cat "$HOME/Library/Application Support/Godot/export_templates/4.7.2.stable/version.txt"` |
| `export/android/android_sdk_path` | ✅ | Terisi di Editor Settings (`~/Library/Application Support/Godot/editor_settings-4.7.tres`) | lihat bagian 2 |
| **`export/android/java_sdk_path`** | ✅ Terisi 2026-10-09 | `/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home`, diisi orchestrator atas izin pemilik. **Wajib**: tanpanya ekspor berhenti dengan `A valid Java SDK path is required in Editor Settings.`, dan variabel lingkungan `JAVA_HOME` **tidak** menggantikannya di Godot 4.7.2 (dicoba, pesan sama) | `grep java_sdk_path "$HOME/Library/Application Support/Godot/editor_settings-4.7.tres"` |
| Debug keystore | ✅ | `~/Library/Application Support/Godot/keystores/debug.keystore` (2,7 KB) dibuat Godot sendiri (lewat `keytool` dari JDK di atas) pada ekspor debug pertama; perilaku standar, di luar repo | `ls "$HOME/Library/Application Support/Godot/keystores/"` |
| `aapt2`, `apksigner`, `apkanalyzer` | ✅ | `~/Library/Android/sdk/build-tools/<versi>/aapt2` dan `apksigner`; `~/Library/Android/sdk/cmdline-tools/latest/bin/apkanalyzer` | `~/Library/Android/sdk/build-tools/37.0.0/aapt2 version` |

### Export templates (kalau belum ada)

Dipakai orchestrator pada 2026-10-09 (unduhan sekitar 1,2 GB, sekali per versi Godot). Verifikasi checksum SHA-512 dari berkas `SHA512-SUMS.txt` rilis yang sama sebelum memasang. Ganti `4.7.2-stable` bila versi Godot berubah. Lakukan di folder sementara di luar repo.

```bash
RILIS=4.7.2-stable
BASIS=https://github.com/godotengine/godot-builds/releases/download/$RILIS
curl -sSfLO "$BASIS/Godot_v${RILIS}_export_templates.tpz"
curl -sSfLO "$BASIS/SHA512-SUMS.txt"
grep "Godot_v${RILIS}_export_templates.tpz" SHA512-SUMS.txt | shasum -a 512 -c -     # harus "OK"
unzip -q "Godot_v${RILIS}_export_templates.tpz"                                       # menghasilkan folder templates/
mkdir -p "$HOME/Library/Application Support/Godot/export_templates/4.7.2.stable"
cp -R templates/. "$HOME/Library/Application Support/Godot/export_templates/4.7.2.stable/"
```

Nama folder tujuan harus sama dengan isi `version.txt` di dalam templates (`4.7.2.stable`). Alternatif dari editor: **Editor → Manage Export Templates → Download and Install**.

## 2. Java SDK Path di Editor Settings (sekali per mesin)

Godot 4.7.2 tidak mau mengekspor Android selama `export/android/java_sdk_path` kosong. Pilih satu:

- **Editor**: buka project, **Editor → Editor Settings → Export → Android → Java SDK Path** diisi `/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home`.
- **Berkas**: tutup semua jendela Godot, lalu ubah baris `export/android/java_sdk_path = ""` di `~/Library/Application Support/Godot/editor_settings-4.7.tres` menjadi nilai yang sama. (Godot menimpa berkas ini saat editor ditutup, jadi jangan mengeditnya sambil editor terbuka.)

Ini pengaturan mesin, bukan bagian repo: jangan di-commit dan agent tidak mengubahnya tanpa izin pemilik. Di mesin ini baris itu diisi orchestrator pada 2026-10-09 atas izin pemilik (baris 313, hanya itu yang berubah). Setelah terisi, ekspor debug pertama membuat debug keystore otomatis.

## 3. Preset export (`export_presets.cfg`)

File di root repo, **di-commit**, tanpa rahasia. Tes `tests/tes_export.gd` membaca file ini dan menolak perubahan yang melanggar tabel di bawah (termasuk kata sandi atau jalur keystore terisi, package salah, arsitektur ekstra, izin menyala). Hanya satu preset: `Android`.

| Opsi | Nilai | Alasan |
|---|---|---|
| `package/unique_name` | `com.rmh.kring` | Pilihan pemilik 2026-10-09. **Jangan diganti**: terkunci setelah upload pertama ke Play Console |
| `runnable` | `true` | Supaya Remote Deploy dari editor tersedia dan `--export-debug` jalan dengan nama preset |
| `gradle_build/use_gradle_build` | `false` | **Usulan.** Belum ada plugin Android yang butuh Gradle; build tanpa Gradle memakai `android_debug.apk` dari export templates dan tidak mengunduh dependensi. Berubah saat plugin masuk (Fase 8 dan 14) |
| `architectures/arm64-v8a` | `true` | **Usulan.** HP target (A54) 64-bit; Google Play mewajibkan 64-bit. APK jadi lebih kecil |
| `architectures/armeabi-v7a`, `x86`, `x86_64` | `false` | **Usulan.** Emulator x86_64 tidak dipakai (uji di HP asli). Nyalakan `x86_64` hanya bila perlu emulator |
| `version/code`, `version/name` | `1`, `0.1.0` | **Usulan.** Versi awal pra-produksi. Jangan diubah tanpa diminta (rule `git-workflow`) |
| `screen/immersive_mode` | `true` | Menyembunyikan bilah sistem supaya tinggi jendela 1080 dan skala tetap ×3 (ROADMAP 4b, risiko ×2). Terbukti di APK: `assets/_cl_` memuat `--fullscreen` (efek di layar: uji HP) |
| `screen/edge_to_edge` | `false` (bawaan Godot) | **Belum diuji di HP.** Bila bilah sistem atau cutout memakan layar atau skala turun ke ×2, ini opsi pertama yang dicoba |
| `user_data_backup/allow` (`android:allowBackup`) | `false` | **Usulan.** Belum ada save yang layak dicadangkan (SaveManager belum ada). Tinjau ulang di Fase 6 bersama keputusan save dan privasi (`privacy-ads`, `save-system`) |
| `permissions/*` | semua `false`, `custom_permissions` kosong | Tanpa izin kustom. Daftar penuh izin Godot ditulis eksplisit supaya penyimpangan terlihat di diff |
| `keystore/debug*`, `keystore/release*` | kosong | Debug keystore diurus Godot lewat Editor Settings; keystore rilis di luar folder project dan tidak pernah di-commit |
| `package/signed` | `true` | APK ditandatangani dengan debug keystore |
| `exclude_filter` | `docs/*, tests/*, tools/*, build/*, builds/*` | Skrip tes (`tests/*.gd`) ikut ke APK kalau tidak dikecualikan; `docs/` sudah diabaikan lewat `docs/.gdignore` |
| `export_filter` | `all_resources` | Semua resource yang dikenal Godot; `.json` data konten juga ikut (terbukti: `assets/sprites/loper/loper_agen.json` masuk paket) |
| `script_export_mode` | `2` (terkompresi) | Hanya memadatkan skrip, **bukan** perlindungan: isi APK tetap bisa dibongkar |
| `package/name` | kosong | Label app = nama project, `Kring Kring!` |
| Ikon (`launcher_icons/*`) | kosong | Memakai ikon project (`application/config/icon` = `res://icon.svg`, lihat di bawah). Ikon final di Fase 14 |

### Pengaturan project yang dituntut ekspor

| Pengaturan (`project.godot`) | Nilai | Alasan |
|---|---|---|
| `rendering/textures/vram_compression/import_etc2_astc` (Project Settings → Rendering → Textures → VRAM Compression → Import ETC2 ASTC) | `true` | **Terbukti perlu** pada ekspor Android (2026-10-09): dengan `false` ekspor berhenti (exit 1) dengan `ETC2/ASTC texture compression is required for Android export`; dengan `true` lolos. Efek: hanya tekstur ber-mode "VRAM Compressed" mendapat varian ETC2/ASTC tambahan; semua sprite repo ini Lossless, jadi hasil impor tidak berubah (`git status` bersih sesudah `--import`) |
| `application/config/icon` | `res://icon.svg` | Tanpa ikon project, ekspor Android mencetak `ERROR: No project icon specified` (tetap exit 0, tetapi gerbang meminta nol ERROR). `icon.svg` adalah ikon **sementara** buatan sendiri (bel oranye di latar gelap, hanya warna `Palette`, isi di zona aman ikon adaptif), bukan logo Godot. Pengganti final: logo "Kring Kring!" di Fase 14 (ART_DIRECTION 8). Dijaga `tests/tes_export.gd` |
| `display/window/handheld/orientation` | `0` (landscape) | Dipakai Godot untuk `screenOrientation` di manifes; dijaga `tests/run_tests.gd` dan `tests/tes_export.gd` |

### Nilai yang ditentukan template (tanpa Gradle tidak bisa diubah dari preset)

`minSdkVersion` **24** (Android 7.0) dan `targetSdkVersion` **36** (Android 16) berasal dari `android_debug.apk` bawaan export templates 4.7.2 dan terbukti sama di APK hasil ekspor (bagian 5). Godot menolak `"Min SDK" can only be overridden when "Use Gradle Build" is enabled`. Template sendiri tidak bertanda tangan (`apksigner verify`: `Missing META-INF/MANIFEST.MF`); tanda tangan dibuat saat ekspor.

## 4. Ekspor APK debug dari CLI

Prasyarat: bagian 1 dan 2 selesai. Dari root repo:

```bash
mkdir -p builds                                  # builds/ ada di .gitignore, tidak di-commit
godot --headless --import                        # sekali setelah clone, supaya aset terimpor
time godot --headless --path . --export-debug "Android" builds/kring-kring-debug.apk
echo "exit=$?"
ls -la builds/kring-kring-debug.apk
```

- Nama preset (`"Android"`) harus persis sama dengan `name` di `export_presets.cfg`.
- Ekspor pertama membuat debug keystore di `~/Library/Application Support/Godot/keystores/` lewat `keytool`. Penandatanganan memakai `build-tools/36.0.0/apksigner` (Godot memilih sendiri).
- Selain `builds/kring-kring-debug.apk`, Godot menulis `builds/kring-kring-debug.apk.idsig` (tanda tangan v4). Keduanya ter-ignore git.
- **Godot memanggil `adb` sendiri.** Pengaturan editor `export/android/shutdown_adb_on_exit` (bawaan aktif) menjalankan `adb kill-server` saat Godot keluar: bila ada server adb hidup (mis. HP sedang tersambung), ekspor mematikannya, dan perintah `adb` berikutnya menyalakannya lagi. Bila tidak ada server, muncul `cannot connect to daemon at tcp:5037: Connection refused` di akhir keluaran; tidak berbahaya. Ekspor tidak memasang apa pun ke HP.
- Keluaran harus bebas `ERROR:` dan `WARNING:`. Catat sisanya.

**Hasil nyata 2026-10-09** (perintah persis di atas, `JAVA_HOME` tidak dipakai): exit **0**, **8 sampai 9 detik**, `builds/kring-kring-debug.apk` **28.483.189 byte** (27,2 MiB; di bawah anggaran 100 MB). Keluaran bebas `ERROR:` dan `WARNING:` sesudah `icon.svg` ditambahkan; sebelumnya ada satu `ERROR: No project icon specified. Please specify one in the Project Settings under Application -> Config -> Icon` (load_icon_refs), ekspor tetap selesai.

### Memeriksa isi paket game tanpa Java (terverifikasi 2026-10-09)

`--export-pack` memakai preset dan filter yang sama tetapi tidak butuh Java:

```bash
godot --headless --path . --export-pack "Android" build/kring-uji.pck 2>&1 | grep "Storing File"
```

Hasil saat ditulis (2026-10-09, dengan `icon.svg`): 81 entri, 220 KB; tidak ada `tests/`, `tools/`, `docs/`, atau `build/`. Tanpa `exclude_filter` paket sebelum ikon berisi 90 entri (310 KB) dengan 12 entri `tests/*.gd` tambahan; jadi filter itu bekerja. Di APK, isi game tersimpan sebagai berkas terpisah di bawah `assets/` (83 entri) dengan `assets/assets.sparsepck` (7 KB) sebagai indeks.

## 5. Memeriksa isi APK

Setelah ekspor berhasil. `AAPT2` dan `APKSIGNER` ada di folder `build-tools` yang sama.

```bash
BT=~/Library/Android/sdk/build-tools/36.0.0
APK=builds/kring-kring-debug.apk
stat -f "%z byte" $APK
$BT/aapt2 dump badging $APK | grep -E "^(package|sdkVersion|minSdkVersion|targetSdkVersion|application-label:|native-code|launchable-activity|supports-screens|uses-permission|uses-feature)"
$BT/aapt2 dump xmltree --file AndroidManifest.xml $APK | grep -E "screenOrientation|allowBackup|debuggable|resizeableActivity|minSdkVersion|targetSdkVersion|package="
$BT/aapt2 dump permissions $APK
$BT/apksigner verify --verbose --print-certs $APK
unzip -l $APK | tail -1
unzip -l $APK | grep -E " lib/|classes.dex|AndroidManifest"
unzip -l $APK | grep -c -E "assets/(docs|tests|tools|build|builds)/"          # harus 0
unzip -p $APK assets/_cl_ | strings                                           # argumen baris perintah (imersif)
~/Library/Android/sdk/cmdline-tools/latest/bin/apkanalyzer manifest print $APK | head -120   # alternatif aapt2 xmltree
```

Hasil pada APK hasil ekspor (2026-10-09):

| Hal | Hasil |
|---|---|
| `package` | `name='com.rmh.kring' versionCode='1' versionName='0.1.0'`, `compileSdkVersion='36'`, `application-label:'Kring Kring!'` |
| `minSdkVersion` | **24** (Android 7.0) |
| `targetSdkVersion` | **36** (Android 16): memenuhi syarat target API 36 Google Play untuk APK ini |
| `native-code` | **`'arm64-v8a'`** saja. `lib/` hanya `arm64-v8a/libgodot_android.so` (76 MB tak terkompresi, 25 MB di APK) dan `libc++_shared.so`; tidak ada armeabi-v7a, x86, x86_64 |
| Orientasi | `screenOrientation=0` (landscape, terkunci) pada `com.godot.game.GodotApp`; badging juga memuat `uses-feature android.hardware.screen.landscape` (tersirat) |
| Activity peluncur | `aapt2 dump badging` **tidak** mencetak `launchable-activity` (peluncur lewat alias). Manifes: `activity-alias` `com.godot.game.GodotAppLauncher` (MAIN, DEFAULT, LAUNCHER, `exported=true`) → `com.godot.game.GodotApp` (`exported=false`) |
| `allowBackup` | **`false`** (sesuai preset). Juga: `debuggable=true` (APK debug), `profileable shell=true`, `isGame=true`, `resizeableActivity=true` (template `false`; Godot menulis ulang) |
| `supports-screens` | `'small' 'normal' 'large' 'xlarge'`; `glEsVersion=0x00030000` (GLES 3.0) |
| Izin | `aapt2 dump permissions`: hanya `package: com.rmh.kring`, **tanpa `uses-permission`** (tidak ada `INTERNET` walau debug: ekspor CLI bukan Remote Deploy; tidak ada `AD_ID`, lokasi, atau izin pelacakan). `android.permission.DUMP` yang terlihat di manifes hanyalah izin yang dituntut receiver `androidx.profileinstaller.ProfileInstallReceiver` milik pustaka AndroidX, bukan izin yang diminta app |
| `apksigner verify` | `Verifies`; skema v2 dan v3 `true`, v1 dan v4 `false`; satu penanda tangan `CN=Godot, OU=Godot Engine, O=Stichting Godot, C=NL`, RSA 2048, SHA-256 sertifikat `838522b2…164483` (debug keystore mesin ini) |
| `unzip -l` | 181 berkas, 84.188.491 byte tak terkompresi; `AndroidManifest.xml`, `resources.arsc`, 13 `classes*.dex`, 83 entri `assets/` (skrip `.gdc` dan `.remap`, `.import`, `.ctex`, `assets.sparsepck`, `project.binary`, `_cl_`); **0** entri `assets/docs|tests|tools|build|builds`, **0** sumber `.gd` |
| `assets/_cl_` | `--xr_mode_regular --xr-mode off --fullscreen --background_color #000000`: mode imersif (`--fullscreen`) aktif, tanpa `--edge_to_edge` |

Pengamatan yang belum terbukti berefek (diuji saat pasang di HP):

- **Dua provider dengan authority yang sama.** `androidx.core.content.FileProvider` dan `androidx.startup.InitializationProvider` sama-sama `authorities="com.rmh.kring.fileprovider"` (di template yang kedua `com.godot.game.androidx-startup`; Godot menulis ulang semua `authorities` pada ekspor tanpa Gradle). Menurut perilaku Android yang saya ketahui, duplikat dalam satu paket hanya memberi peringatan `Skipping provider name` dan provider kedua dilewati saat dipasang, tetapi **belum terbukti di HP**. Bila `adb install` gagal dengan `INSTALL_FAILED_CONFLICTING_PROVIDER`, inilah penyebabnya; jalan keluarnya Gradle build (manifes bisa dikendalikan) atau patch Godot, bukan perubahan di repo ini.
- `aapt2` mencetak `warn: resource com.godot.game:mipmap/themed_icon for config 'anydpi-v26' is a file reference to 'res/mipmap-anydpi-v26/themed_icon.xml' but no such path exists` di setiap perintahnya pada APK ini (pada `android_debug.apk` template tidak muncul). Acuan ikon bertema tanpa berkas; ikon adaptif memuat `icon_monochrome.webp` sendiri. Tidak diketahui berefek.

### Target API 36 dan syarat rilis

Google Play mewajibkan app baru dan update menargetkan Android 16 (API 36) mulai 31 Agustus 2026 (TECH_PLAN Fase 0). Template 4.7.2 menargetkan **36** dan APK hasil ekspor terbukti `targetSdkVersion='36'`, jadi APK debug tanpa Gradle memenuhi syarat target. Syarat rilis yang belum dikerjakan (bukan penghalang APK debug):

- **AAB**: Play Console menerima AAB untuk app baru; ekspor AAB (`gradle_build/export_format=1`) hanya valid dengan **Use Gradle Build** menyala. Gradle build baru dipasang saat plugin Android masuk (Fase 8 dan 14), lalu folder `android/` perlu aturan `.gitignore` sendiri.
- Keystore rilis di luar folder project, kata sandi tidak di-commit.
- Layar besar: menurut dokumentasi Android 16, app yang menargetkan API 36 tidak lagi dipatuhi batasan orientasi dan `resizeableActivity` di layar lebar (sw ≥ 600dp: tablet, foldable terbuka). Landscape terkunci tetap berlaku di HP seperti A54, tetapi belum diuji di perangkat besar; tinjau sebelum rilis.
- Tinjau izin `INTERNET`, `allowBackup`, kebijakan privasi, dan Data Safety (`privacy-ads`, ROADMAP 5 #13).
- Ikon aplikasi, nama toko, dan `version/code` yang naik tiap upload.

## 6. Pasang dan jalankan di HP

**Aturan HP.** HP uji (Samsung A54, SM-A546E) **dipakai bersama project lain**. Hanya pasang `com.rmh.kring`; jangan menyentuh app lain. Periksa dulu apakah pemilik sedang memakai HP (layar menyala) sebelum meluncurkan app atau mengirim ketukan. Memasang APK ke HP hanya setelah izin pemilik. Pada run `20261009-fase0bc-input-export` hanya orchestrator yang menyentuh HP, setelah QA.

```bash
adb devices                                       # HP harus "device"; "unauthorized" = izinkan di layar HP
adb install -r builds/kring-kring-debug.apk       # -r: timpa versi lama, data app tetap
adb shell am start -n com.rmh.kring/com.godot.game.GodotAppLauncher   # buka app (alias peluncur dari manifes template)
adb logcat -s godot                               # log game (Ctrl+C berhenti); error skrip muncul di sini
```

Bila lebih dari satu perangkat: tambahkan `-s <serial>` dari `adb devices` ke setiap perintah `adb`. Alternatif membuka app: `adb shell monkey -p com.rmh.kring -c android.intent.category.LAUNCHER 1`.

**Sebelum menghapus apa pun**, cek dulu isi HP:

```bash
adb shell pm list packages | grep rmh                 # lihat app apa yang ada
adb uninstall com.rmh.kring                           # hanya app ini; data app ikut hilang
```

**Jangan pernah `pm clear` atau uninstall tanpa izin pemilik** (rule `00-project-core`), dan jangan sentuh package lain di daftar itu. Menghapus app ini menghapus save-nya.

Tangkapan layar untuk cek ketajaman piksel (butuh layar menyala, orientasi landscape):

```bash
mkdir -p build
adb exec-out screencap -p > build/hp_awal.png
python3 tools/cek_blok_piksel.py 3 build/hp_awal.png     # hasil yang diharapkan: 0 blok tidak seragam
```

Teks HUD (font vektor) tidak berupa blok piksel; kecualikan kotaknya dengan `--kecualikan X0,Y0,X1,Y1` (lihat komentar di `tools/cek_blok_piksel.py`). Layar 2340×1080 harus menampilkan viewport 780×360 pada skala ×3. Bila yang terlihat ×2 (tepi kosong), bilah sistem tidak tersembunyi: catat dan coba `screen/edge_to_edge=true` di preset. Bukti yang dipakai sebagai hasil run disimpan di `docs/loop/<RUN_ID>/shots/`.

## 7. Masalah umum

| Gejala | Penyebab dan solusi |
|---|---|
| `A valid Java SDK path is required in Editor Settings.` | `export/android/java_sdk_path` kosong (bagian 2). `JAVA_HOME` saja tidak cukup di 4.7.2 (terverifikasi) |
| `cannot connect to daemon at tcp:5037` di akhir ekspor | Godot menjalankan `adb kill-server` saat keluar dan tidak ada server; tidak berbahaya. Bila server adb hidup, ekspor mematikannya (bagian 4) |
| `ERROR: No project icon specified` | `application/config/icon` kosong; sekarang `res://icon.svg` (bagian 3) |
| `adb install` gagal `INSTALL_FAILED_CONFLICTING_PROVIDER` (belum terjadi) | Dua provider berauthority sama di manifes hasil ekspor tanpa Gradle (bagian 5, pengamatan) |
| `No export template found` | Export templates 4.7.2 belum terpasang atau nama folder tidak sama dengan `version.txt` (bagian 1) |
| Ekspor mengeluh soal keystore atau `keytool` | Java SDK Path salah atau bukan JDK (butuh `bin/keytool`); debug keystore dibuat otomatis (bagian 2) |
| `adb devices` menampilkan `unauthorized` (umum) | Izinkan USB debugging di layar HP; kalau dialog tidak muncul, cabut otorisasi di Opsi pengembang lalu colok ulang |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` (umum) | APK lama ditandatangani keystore lain. Cek `pm list packages` dulu, lalu `adb uninstall com.rmh.kring` hanya dengan izin pemilik (save ikut terhapus) |
| App langsung tertutup (umum) | Lihat penyebabnya dengan `adb logcat -s godot` |
| Dialog sistem "Viewing full screen" saat pertama dibuka (umum) | Dialog Android untuk mode imersif; tekan "Got it", muncul sekali |
| `ETC2/ASTC texture compression is required for Android export` | `rendering/textures/vram_compression/import_etc2_astc` mati di `project.godot` (bagian 3); dijaga `tests/tes_export.gd` |
| Skala turun ke ×2 atau ada tepi kosong di HP | Bilah sistem tidak tersembunyi; lihat bagian 6 dan ROADMAP 4b |
| Tes ekspor `tests/tes_export.gd` gagal | Ada perubahan di `export_presets.cfg` atau `.gitignore` yang melanggar bagian 3; baca pesan `GAGAL` |

## 8. Checklist uji HP (menutup Fase 0 dan M0)

Dikerjakan manusia di HP asli; agent tidak bisa menilai rasa kontrol. Fase 0 **tidak dicentang** sebelum butir inti selesai (`DEV_PHASES.md`). Catat angka yang ingin diubah, jangan mengubahnya di run ini.

**Inti M0**

- [ ] APK terpasang dan app terbuka dalam landscape; tidak ada crash di `adb logcat -s godot`.
- [ ] Stick muncul di bawah jempol kiri, sepeda bergerak naik ke kanan atas. Atas: ngebut (sprite berdiri). Netral: santai. Bawah: melambat. Kiri/kanan: sprite serong (sekitar 45° sampai 63°) dan sepeda bergeser. Sprite 90° belum bisa muncul di run ini (butuh rem Fase 1), jadi jangan dicatat sebagai cacat. Tidak ada animasi yang berkedip di sekitar batas sudut 22,5°.
- [ ] Dua jempol bersamaan: stick dan garis swipe jalan tanpa saling mengganggu; mengangkat satu jari tidak mematikan yang lain.
- [ ] Tombol kidal menukar zona dan panel kecepatan; tombol di strip atas tidak tersentuh tak sengaja saat bermain.
- [ ] Kembali dari background (tombol home lalu buka lagi): stick tidak macet dan tidak ada gerak sendiri.
- [ ] Ukuran stick (radius 35 px game, sekitar 105 px layar), zona mati 15%, ambang tingkat 33% dan 80% terasa wajar. Catat angka yang ingin diubah.
- [ ] Ketajaman dan skala: tangkapan layar `adb exec-out screencap -p`, lalu `python3 tools/cek_blok_piksel.py 3 <png>` memberi 0 blok tidak seragam di luar teks HUD; layar 2340×1080 menampilkan viewport 780×360 skala ×3 tanpa bilah sistem.
- [ ] Kinerja terasa 60 fps (belum ada pengukur resmi).

**Tambahan dari Dev-0B dan Dev-0C**

- [ ] Tepi layar: zona stick mulai x = 8 px game (sekitar 24 px layar). Gestur kembali sistem di tepi kiri atau kanan bisa mencuri sentuhan; catat bila stick sering putus saat jempol dekat tepi.
- [ ] Cutout kamera A54 di landscape tidak menutupi zona stick (x mulai 8, y 186..352) atau panel kecepatan.
- [ ] Tombol kidal (strip atas, tinggi 36 px game, sekitar 108 px layar) mudah ditekan sengaja; panel kecepatan tidak tertutup jempol kanan saat swipe.
- [ ] Garis bidik swipe (2 px tiap 4 px) terbaca di bawah jempol; knob (radius 15) yang menonjol saat tarikan penuh terlihat wajar.
- [ ] Keterbacaan teks HUD (6 px game = 18 px layar) dinilai dengan mata.
- [ ] Dorongan kecepatan (GDD 15, `DORONGAN_*` di `scripts/config.gd`, usulan awal 28 px maju, 20 px mundur, respon 0,35 detik): saat ngebut sepeda maju sedikit di layar (naik ke kanan atas); saat melambat mundur sedikit; stick dilepas: kembali halus ke posisi dasar tanpa goyang atau tersentak. Catat apakah geser terasa terlalu kecil atau terlalu besar (dan apakah jalan di depan jadi terasa terlalu pendek saat ngebut) beserta angka yang diinginkan; jangan diubah di run ini.
- [ ] **Melambat (run sprite-lempar-melambat, usulan):** stick ditarik ke bawah penuh: kayuh jelas lebih pelan dari santai (4 fps lawan 8 fps), tidak terasa patah, kecepatan turun ke 1,5 u/d dan dorongan kecepatan menarik sepeda mundur sedikit. Tarik sedikit ke bawah sambil belok kiri atau kanan: apakah animasi berkedip antara santai dan melambat (kalau ya, catat; belum ada ambang selain zona mati 15%).
- [ ] **Lempar kiri dan kanan (usulan):** swipe di zona kanan ke kiri dan ke kanan di santai, cepat, dan ngebut: lengan dan titik lepas koran terbaca, sprite tidak melompat saat berganti dari dan ke kayuh. Ke kiri = sisi seberang, ke kanan = sisi dekat. Sambil serong (stick kiri atau kanan) memakai varian serong yang benar; arah 90° belum ada gambarnya (pakai serong, jangan dicatat sebagai cacat). Belum ada koran terbang, skor, atau sasaran (Fase 2).
- [ ] **Ambang swipe 12 px dan abaikan swipe saat melempar (usulan):** swipe pendek tetap melempar, tap tanpa geser dan gerak vertikal tidak; swipe kedua saat masih melempar (sekitar 0,33 detik) diabaikan dan terasa wajar. Catat angka ambang yang diinginkan; jangan diubah di run ini.
- [ ] **Dua jempol saat melempar:** stick tetap menggerakkan sepeda dan tidak putus selama animasi lempar berjalan; kembali dari background saat melempar tidak meninggalkan animasi lempar yang menggantung.
- [ ] Orientasi terkunci: memutar HP 180° tidak membalik tampilan atau menjadikannya portrait (`screenOrientation=0`, bukan sensor).
- [ ] Ikon di launcher: bel oranye di latar gelap (`icon.svg` sementara, tidak terpotong oleh bentuk ikon adaptif); nilai dengan mata, ikon final di Fase 14.
- [ ] Opsional: sambungkan keyboard fisik; panah dan WASD **tidak** boleh menggerakkan sepeda di APK (keyboard hanya untuk editor, `OS.has_feature("editor")`).
- [ ] Tetap terbuka dan bukan bagian checklist ini: uji light 2D, glow, partikel, dan shader di Compatibility (DEV_PHASES Fase 0).
