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
| `exclude_filter` | `docs/*, tests/*, tools/*, build/*, builds/*, scenes/dev/cek_render.tscn, scripts/dev/cek_render.gd, assets/shaders/warna_bayangan.gdshader` | Skrip tes (`tests/*.gd`) ikut ke APK kalau tidak dikecualikan; `docs/` sudah diabaikan lewat `docs/.gdignore`. Tiga berkas terakhir = probe render (bagian 6.1): **usulan** run fase1c-perapian (QA-004), APK normal tanpa probe; build probe melepasnya sementara lewat `tools/ekspor_cek_render.py`. `tests/tes_export.gd` menjaga pola ini, kecocokannya dengan `POLA_PROBE` di skrip itu, dan bahwa tidak ada berkas game yang memuat berkas probe |
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

### 6.1 Probe render Compatibility di HP (run fase1b-umpan-balik)

Membuktikan apakah **light 2D, glow, partikel CPU dan GPU, dan shader warna bayangan** jalan di renderer Compatibility pada HP (butir Q-014, ART_DIRECTION 2.3 dan 7). Probe adalah scene dev `scenes/dev/cek_render.tscn` (`scripts/dev/cek_render.gd`): empat panel berdampingan, dan sesudah 5 detik ia mencetak satu baris `[cek_render]` per fitur (hasil dari **piksel hasil render**, renderer, GPU, fps rata-rata) lalu satu baris ringkasan. Arti hasil:

| Baris | `ya` / `cocok` berarti |
|---|---|
| `perangkat:` | Nama renderer (`gl_compatibility`), driver, GPU, versi API, ukuran jendela dan viewport, skala, fps rata-rata selama 5 detik |
| `light2d:` | Titik dekat `PointLight2D` jauh lebih terang dari tepi yang hanya kena `CanvasModulate` gelap, **dan** titik di belakang `LightOccluder2D` lebih gelap dari titik sejarak di sisi lain (bayangan lembut PCF5). `cahaya_tanpa_bayangan` = cahaya jalan, bayangan tidak |
| `glow:` | Piksel 4 px di luar kotak terang lebih terang dari latar jauh (halo dari `WorldEnvironment` latar Canvas, glow menyala) |
| `cpu_partikel:` / `gpu_partikel:` | Ada piksel berwarna partikel (`ACCENT` / `OK`) di separuh panel masing-masing; jumlah piksel ditulis |
| `shader_bayangan:` | Piksel penanda bayangan (hitam alpha 71) di sprite ber-shader sama dengan campuran latar dan `#2E3550` alpha 71/255, piksel lain sama dengan sprite kontrol tanpa shader, dan latar terbaca benar (kalibrasi) |

Di `--headless` piksel tidak bisa dibaca: baris fitur menulis "tidak bisa dibaca headless" dan ringkasan `tidak_terbaca`, **bukan** lolos.

**Build normal tidak memuat probe; build probe hanya lewat skrip.** Scene utama yang di-commit tetap `jalan_uji.tscn`, tidak ada skrip atau scene game yang merujuk probe (dijaga `tests/tes_cek_render.gd` dan `tests/tes_export.gd`), dan `exclude_filter` preset `Android` mengecualikan `scenes/dev/cek_render.tscn`, `scripts/dev/cek_render.gd`, dan `assets/shaders/warna_bayangan.gdshader` (bagian 3; usulan run fase1c-perapian, QA-004), jadi APK dan paket normal tidak memuatnya sama sekali. Build probe dibuat terpisah oleh `tools/ekspor_cek_render.py`, yang hanya selama satu perintah ekspor (preset `Android` yang sama) mengganti baris `run/main_scene` di `project.godot` ke probe dan melepas ketiga pola itu dari `exclude_filter`, lalu memulihkan **kedua** berkas byte demi byte di `finally` (juga bila Godot gagal, tidak ditemukan, atau Ctrl+C), dan memeriksa bahwa hasil ekspor memuat berkas probe dan `project.binary`-nya menunjuk ke probe. Exit 1 bila salah satu berkas tidak pulih. `override.cfg` sementara **tidak** bisa dipakai: dicoba 2026-10-14, berkas itu tidak ikut ke paket dan tidak digabung ke `project.binary`, jadi paket tetap membuka `jalan_uji.tscn` (`override.cfg` kini di `.gitignore`).

```bash
python3 tools/ekspor_cek_render.py --pck build/kring-cek-render.pck          # paket probe tanpa Java (cek cepat)
python3 tools/ekspor_cek_render.py --apk builds/kring-cek-render-debug.apk   # APK debug probe (bagian 1 dan 2 harus beres)
git status --short project.godot export_presets.cfg                          # harus kosong (sudah dipulihkan)
```

Hasil di mesin pengembang 2026-10-14 (Apple M4): kedua perintah exit 0, "project.godot pulih byte demi byte: ya", `scene utama di project.binary = res://scenes/dev/cek_render.tscn`; APK probe 28.631.804 byte. APK normal (`--export-debug "Android"` biasa) tetap `res://scenes/dev/jalan_uji.tscn` di `assets/project.binary`. Sampai run fase1c-perapian berkas probe (`cek_render.scn`, `cek_render.gdc`, shader) ikut ke APK normal karena `export_filter` `all_resources`; sejak `exclude_filter` di atas, paket normal tidak memuatnya (cek: `godot --headless --path . --export-pack "Android" build/kring-uji.pck` lalu `grep -a -c cek_render build/kring-uji.pck` = 0; hasil run fase1c-perapian dicatat di `docs/loop/20261014-fase1c-perapian/LOG.md`), sedangkan paket probe memuatnya ("berkas probe di hasil ekspor: semua ada", "export_presets.cfg pulih byte demi byte: ya").

**Desktop** (bukti tanpa HP):

```bash
godot --path . --resolution 2340x1080 --position 0,0 scenes/dev/cek_render.tscn -- --tangkap=build/cek_render.png   # jendela asli: ukur, simpan tangkapan, keluar
godot --headless --path . scenes/dev/cek_render.tscn                       # headless: baris [cek_render], piksel "tidak bisa dibaca headless", keluar sendiri
godot --main-pack build/kring-cek-render.pck --resolution 2340x1080 --position 0,0 -- --keluar   # paket probe hasil ekspor (jalankan dari folder lain)
```

**Di A54 (orchestrator, sesudah QA PASS; aturan HP bagian 6 berlaku).** APK probe memakai package yang sama (`com.rmh.kring`), jadi memasangnya **menimpa** build uji di HP (data app tetap dengan `-r`); pasang ulang APK normal sesudahnya. Jangan `pm clear`, uninstall, atau `logcat -c` (log HP dipakai project lain).

```bash
adb devices                                                         # A54 "device"
adb shell dumpsys power | grep -E "mWakefulness|mHoldingDisplay"    # layar menyala dan tidak sedang dipakai pemilik
mkdir -p docs/loop/20261014-fase1b-umpan-balik/render_a54
adb install -r builds/kring-cek-render-debug.apk
adb shell am start -n com.rmh.kring/com.godot.game.GodotAppLauncher
# tunggu sekitar 10 detik (pengukuran 5 detik), jangan sentuh layar
adb exec-out screencap -p > docs/loop/20261014-fase1b-umpan-balik/render_a54/cek_render_a54.png
adb logcat -d -s godot | grep "\[cek_render\]" | tail -8 > docs/loop/20261014-fase1b-umpan-balik/render_a54/cek_render_a54.log
cat docs/loop/20261014-fase1b-umpan-balik/render_a54/cek_render_a54.log   # harus ada 7 baris: perangkat, 5 fitur, ringkasan
adb install -r builds/kring-kring-debug.apk                          # kembalikan build normal (jalan_uji)
```

Probe tetap terbuka di HP (tidak keluar sendiri); tombol back tidak berbuat apa-apa di sini (`quit_on_go_back` false), jadi tinggalkan lewat tombol home. Hasilnya dicatat orchestrator di `ART_DIRECTION.md` 2.3/7. Bila `logcat` kosong, buka ulang app (pengukuran diulang tiap kali dibuka). Sebagian ROM (mis. vivo V2108, 2026-10-14) memasang `log.tag=E`, jadi log info Godot dibuang: buka sementara dengan `adb shell setprop log.tag.godot V`, buka ulang app (`am force-stop com.rmh.kring` lalu `am start`), ambil log, lalu kembalikan dengan `adb shell setprop log.tag.godot "''"` (tidak persisten, hilang saat reboot).

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

**Hasil:** semua butir di bawah lolos di A54, dikonfirmasi pemilik 2026-10-13 (Fase 0 dan M0 selesai). Uji light 2D/glow/partikel/shader pindah ke Fase 1 (Run 1B).

**Inti M0**

- [x] APK terpasang dan app terbuka dalam landscape; tidak ada crash di `adb logcat -s godot`.
- [x] Stick muncul di bawah jempol kiri, sepeda bergerak naik ke kanan atas. Atas: ngebut (sprite berdiri). Netral: santai. Bawah: melambat. Kiri/kanan: sprite serong (sekitar 45° sampai 63°) dan sepeda bergeser. Sprite 90° belum bisa muncul di run ini (butuh rem Fase 1), jadi jangan dicatat sebagai cacat. Tidak ada animasi yang berkedip di sekitar batas sudut 22,5°.
- [x] Dua jempol bersamaan: stick dan garis swipe jalan tanpa saling mengganggu; mengangkat satu jari tidak mematikan yang lain.
- [x] Tombol kidal menukar zona dan panel kecepatan; tombol di strip atas tidak tersentuh tak sengaja saat bermain.
- [x] Kembali dari background (tombol home lalu buka lagi): stick tidak macet dan tidak ada gerak sendiri.
- [x] Ukuran stick (radius 35 px game, sekitar 105 px layar), zona mati 15%, ambang tingkat 33% dan 80% terasa wajar. Catat angka yang ingin diubah.
- [x] Ketajaman dan skala: tangkapan layar `adb exec-out screencap -p`, lalu `python3 tools/cek_blok_piksel.py 3 <png>` memberi 0 blok tidak seragam di luar teks HUD; layar 2340×1080 menampilkan viewport 780×360 skala ×3 tanpa bilah sistem.
- [x] Kinerja terasa 60 fps (belum ada pengukur resmi).

**Tambahan dari Dev-0B dan Dev-0C**

- [x] Tepi layar: zona stick mulai x = 8 px game (sekitar 24 px layar). Gestur kembali sistem di tepi kiri atau kanan bisa mencuri sentuhan; catat bila stick sering putus saat jempol dekat tepi.
- [x] Cutout kamera A54 di landscape tidak menutupi zona stick (x mulai 8, y 186..352) atau panel kecepatan.
- [x] Tombol kidal (strip atas, tinggi 36 px game, sekitar 108 px layar) mudah ditekan sengaja; panel kecepatan tidak tertutup jempol kanan saat swipe.
- [x] Garis bidik swipe (2 px tiap 4 px) terbaca di bawah jempol; knob (radius 15) yang menonjol saat tarikan penuh terlihat wajar.
- [x] Keterbacaan teks HUD (6 px game = 18 px layar) dinilai dengan mata.
- [x] Dorongan kecepatan (GDD 15, `DORONGAN_*` di `scripts/config.gd`, usulan awal 28 px maju, 20 px mundur, respon 0,35 detik): saat ngebut sepeda maju sedikit di layar (naik ke kanan atas); saat melambat mundur sedikit; stick dilepas: kembali halus ke posisi dasar tanpa goyang atau tersentak. Catat apakah geser terasa terlalu kecil atau terlalu besar (dan apakah jalan di depan jadi terasa terlalu pendek saat ngebut) beserta angka yang diinginkan; jangan diubah di run ini.
- [x] **Melambat (run sprite-lempar-melambat, usulan):** stick ditarik ke bawah penuh: kayuh jelas lebih pelan dari santai (4 fps lawan 8 fps), tidak terasa patah, kecepatan turun ke 1,5 u/d dan dorongan kecepatan menarik sepeda mundur sedikit. Tarik sedikit ke bawah sambil belok kiri atau kanan: apakah animasi berkedip antara santai dan melambat (kalau ya, catat; belum ada ambang selain zona mati 15%).
- [x] **Lempar kiri dan kanan (usulan):** swipe di zona kanan ke kiri dan ke kanan di santai, cepat, dan ngebut: lengan dan titik lepas koran terbaca, sprite tidak melompat saat berganti dari dan ke kayuh. Ke kiri = sisi seberang, ke kanan = sisi dekat. Sambil serong (stick kiri atau kanan) memakai varian serong yang benar; arah 90° belum ada gambarnya (pakai serong, jangan dicatat sebagai cacat). Belum ada koran terbang, skor, atau sasaran (Fase 2).
- [x] **Ambang swipe 12 px dan abaikan swipe saat melempar (usulan; ambang kini 6% lebar viewport dan arah bebas, lihat 8.3 dan 8.4):** swipe pendek tetap melempar, tap tanpa geser dan gerak vertikal tidak; swipe kedua saat masih melempar (sekitar 0,33 detik) diabaikan dan terasa wajar. Catat angka ambang yang diinginkan; jangan diubah di run ini.
- [x] **Dua jempol saat melempar:** stick tetap menggerakkan sepeda dan tidak putus selama animasi lempar berjalan; kembali dari background saat melempar tidak meninggalkan animasi lempar yang menggantung.
- [x] Orientasi terkunci: memutar HP 180° tidak membalik tampilan atau menjadikannya portrait (`screenOrientation=0`, bukan sensor).
- [x] Ikon di launcher: bel oranye di latar gelap (`icon.svg` sementara, tidak terpotong oleh bentuk ikon adaptif); nilai dengan mata, ikon final di Fase 14.
- [x] Opsional: sambungkan keyboard fisik; panah dan WASD **tidak** boleh menggerakkan sepeda di APK (keyboard hanya untuk editor, `OS.has_feature("editor")`).
- Bukan bagian checklist ini: uji light 2D, glow, partikel, dan shader di Compatibility (dipindah ke DEV_PHASES Fase 1, Run 1B).

### 8.1 Uji Run 1A Fase 1: gerak inti (run `20261013-fase1a-gerak`, belum diuji)

**Digabung ke bagian 8.2** (keputusan pemilik 2026-10-14): butir di bawah tetap sebagai rincian, tetapi dicentang di 8.2.

Semua angka usulan (`scripts/config.gd`, BALANCING 2-3). Catat angka yang ingin diubah beserta alasannya; jangan diubah di run uji. Ambang rem masih keputusan terbuka (ROADMAP 5), diputuskan dari uji ini.

- [ ] **Ambang rem:** tarik stick penuh ke bawah dan tahan: sesudah sekitar 0,25 detik sepeda mengerem (sprite `rem`, badan mundur 1 px dan bergetar) sampai berhenti; busur bawah cincin stick menyala oranye (`WARN`) selama rem aktif. Apakah 90% dan 0,25 detik terasa pas? Apakah sepeda pernah berhenti tak sengaja saat belok sambil menarik ke bawah, atau saat meluncur?
- [ ] **Rem lalu lepas:** dari berhenti, angkat jempol: rem padam, busur hilang, sepeda jalan lagi ke santai (3,0 u/d2) dengan kayuh yang mulai pelan dan makin cepat. Getar rem 1 px terbaca di x3 atau terlalu halus?
- [ ] **Meluncur lalu melambat:** dari ngebut tarik stick ke bawah sebagian (belum penuh): kaki diam (`meluncur`) selama kecepatan turun, lalu kayuh 4 fps (`melambat`) saat kecepatan sudah rendah. Pergantiannya terbaca atau mengganggu? Tidak ada lompatan posisi sprite.
- [ ] **Stamina:** ngebut terus dari penuh habis sekitar 8-9 detik; bar stamina (oranye) berubah merah di bawah 30 dan muncul tulisan LELAH; selama lelah kecepatan tertahan di 4,5 u/d dan sprite kayuh cepat walau stick penuh ke atas. Meluncur sekitar 2 detik memadamkan LELAH. Bar dan tulisannya terbaca?
- [ ] **Laju kayuh:** mempercepat dari berhenti ke ngebut: kayuh mulai pelan dan menyusul kecepatan, tidak terasa "kaki berputar di tempat".
- [ ] **Lateral sampai tepi trotoar:** geser kiri dan kanan penuh: sepeda naik trotoar dan berhenti di tepi trotoar (+-2 ubin, sebelum 2026-10-16 tepi aspal +-1) tanpa tersentak; geser saat berhenti dengan rem (sprite menghadap 90°) terlihat wajar atau aneh?
- [ ] **Kembali dari background** (home, notifikasi ditarik, panggilan): tidak ada lompatan posisi, kecepatan, atau stamina; rem yang sedang ditahan tidak tersisa (harus ditahan ulang 0,25 detik); stick dan lempar dilepas bersih.
- [ ] Dua jempol: swipe tetap melempar saat rem dan meluncur (lempar memakai gambar santai), stick tidak putus.

### 8.2 Uji Fase 1 di HP (run 1A + 1B, menutup Fase 1)

> **Keputusan pemilik 2026-10-14:** uji HP cukup dilakukan pemilik sendiri (tidak ada penguji lain), bukan 3-5 orang. Pemilik menyatakan uji Fase 1 oke pada 2026-10-14. Langkah dan lembar di bawah tetap dipakai sebagai daftar periksa; kode P1 sampai P5 cukup P1.

Menggabungkan 8.1 (gerak inti, run `20261013-fase1a-gerak`) dan run `20261014-fase1b-umpan-balik` (umpan balik, audio, jeda, penyetelan). **Fase 1 baru selesai** (`DEV_PHASES.md`) kalau pemilik mencoba di HP dan **bisa mengatur kecepatan, mengerem, dan pindah sisi tanpa penjelasan panjang**, dan **ambang rem tidak membuat sepeda berhenti tak sengaja**. Semua angka usulan; catat angka yang ingin diubah, jangan diubah di sesi uji.

**Persiapan (pemilik).** APK normal terbaru (`builds/kring-kring-debug.apk`, bagian 4) terpasang di A54; volume media sekitar setengah, uji suara di speaker HP (bukan headphone). Tiap penguji dicatat dengan kode (P1 sampai P5), **tanpa nama atau data pribadi**. Penjelasan ke penguji cukup satu kalimat: "Jempol kiri mengayuh dan mengarahkan, jempol kanan melempar." Amati dulu tanpa membantu; catat kapan penguji harus diberi tahu.

**Langkah per penguji (sekitar 5 menit, tulis di lembar catatan di bawah):**

1. Main bebas 1 menit tanpa petunjuk lain. Catat apakah ia menemukan sendiri cara ngebut, melambat, mengerem, dan pindah sisi.
2. Minta "berhenti total" lalu "jalan lagi". Rem = stick ditarik penuh ke bawah dan ditahan sekitar 0,25 detik.
3. Minta "pelan-pelan saja tanpa berhenti" selama 10 detik dan belok ke kiri dan kanan. Catat bila sepeda berhenti sendiri (rem tak sengaja).
4. Minta jeda lewat tombol jeda (kiri atas), lalu lanjut. Lalu tekan home, buka lagi app, dan lanjut.

**Butir yang dinilai (gabungan, centang bila sebagian besar penguji lancar):**

- [ ] **Kecepatan:** ngebut, santai, dan melambat bisa diatur tanpa penjelasan; sprite berdiri saat ngebut, kayuh pelan saat melambat (8.1 laju kayuh).
- [ ] **Rem:** berhenti dengan tarik penuh dan tahan; ambang 90% dan tahan 0,25 detik tidak membuat berhenti tak sengaja saat belok atau meluncur (8.1 ambang rem, rem lalu lepas). Busur rem oranye `WARN` terbaca di atas knob oranye `ACCENT` di luar ruangan (**QA-006**).
- [ ] **Melambat paling pelan (QA-005):** tarik ke bawah sampai tepat sebelum rem dan tahan: kecepatan menetap sekitar 1,6-1,7 u/d. Cukup pelan untuk membidik, atau rem terlalu mudah menyala saat ingin pelan?
- [ ] **Pindah sisi:** geser ke sisi seberang dan dekat sampai tepi trotoar tanpa tersentak (8.1 lateral).
- [ ] **Meluncur dan stamina:** meluncur (kaki diam) lalu melambat terbaca; stamina habis sekitar 8-9 detik ngebut, LELAH dan bar merah terbaca, meluncur sekitar 2 detik memulihkan (8.1 stamina).
- [ ] **Debu dan garis kecepatan:** debu krem di roda belakang sejak santai, lebih tebal saat ngebut dan saat rem; garis putih bertangga hanya saat cepat/ngebut. Sejak run fase1c-perapian debu tertinggal di jalan sebagai jejak titik (saat pindah sisi jejaknya tetap di sisi lama, QA-006 Run 1B): jejak terbaca dan tidak mengganggu? Terbaca sebagai kecepatan dan tidak menutupi jalan di depan; tidak tersendat (60 fps terasa).
- [ ] **Bunyi:** kayuhan terdengar dan nadanya naik saat ngebut (pitch 1,0 / 1,15 / 1,3); "tik-tik" freewheel saat meluncur; decit rem **sekali** saat rem menyala (tidak berulang selama ditahan); tidak ada klik di sambungan loop; volume relatif wajar di speaker HP. Catat bila tempo ketukan terasa tidak cocok dengan kayuhan saat ngebut (bunyi 10,4 ketuk/detik lawan animasi 12 fps).
- [ ] **Jeda:** tombol jeda (gambar 24×24, area sentuh 42×42 px game sekitar 44 dp) mudah ditekan sengaja dan tidak tertekan saat bermain; jari kedua bisa mengetuknya saat jempol di stick; layar jeda gelap dengan "JEDA" dan "Lanjut"; semua diam dan bunyi berhenti selama jeda; back Android menjeda dan (di layar jeda) melanjutkan.
- [ ] **Background:** home, notifikasi ditarik, atau panggilan masuk membuka layar jeda dan **tidak jalan sendiri** saat kembali; tidak ada decit rem yang menyusul sesudah Lanjut; rem harus ditahan ulang (8.1 kembali dari background).
- [ ] **Posisi sepeda dan dorongan:** sepeda di sekitar 75% tinggi layar; saat ngebut maju sedikit (36 px) dan jalan di depan terasa cukup jauh (sekitar 2,5 detik di A54); sepeda tidak tertutup jempol atau panel kecepatan.
- [ ] **Ukuran dan teks:** tombol kidal dan jeda (42 px game, 44 dp) nyaman; teks HUD 8 px (24 px layar) terbaca.
- [ ] **Dua jempol:** swipe tetap melempar saat rem dan meluncur; stick tidak putus (8.1 dua jempol).

**Lembar catatan per penguji (salin satu per orang; tanpa nama, umur pasti, kontak, atau foto):**

```
Penguji: P_   Tanggal: ____   HP: A54 / lainnya: ____   Build (commit): ____
Tangan dominan: kanan / kiri (pakai opsi kidal: ya / tidak)   Biasa main game HP: sering / kadang / jarang
1. Main bebas 1 menit, ditemukan sendiri tanpa diberi tahu:  ngebut [ ]  melambat [ ]  rem [ ]  pindah sisi [ ]  lempar [ ]
   Yang harus diberi tahu (dan kapan): ________________________________
2. Berhenti total lalu jalan lagi: lancar / perlu dicoba ulang ___ kali / tidak bisa
3. Pelan 10 detik sambil belok: rem tak sengaja ___ kali   kecepatan paling pelan terasa: terlalu cepat / pas / terlalu pelan
4. Jeda dan Lanjut: lancar / bingung   Home lalu kembali: layar jeda muncul ya / tidak   jalan sendiri ya / tidak
Bunyi: kayuh naik saat ngebut terasa ya / tidak   decit rem sekali ya / berulang   klik di loop ya / tidak   volume: pelan / pas / keras
Debu dan garis kecepatan: membantu / mengganggu / tidak terlihat
Tombol jeda tertekan tak sengaja: ___ kali   Teks HUD terbaca: ya / sulit
Angka yang ingin diubah dan alasannya: _______________________________
Catatan lain (kutip kata-kata penguji, bukan nama): ___________________
```

**Hasil:** tulis ringkasan (berapa dari berapa penguji lolos tiap butir, angka yang diminta berubah) di PR uji atau `docs/loop/`, lalu pemilik memutuskan centang Fase 1 di `DEV_PHASES.md`.


### 8.3 Uji Run 2A Fase 2: lemparan koran (run `20261014-fase2a-lemparan`, belum diuji)

Penguji: pemilik sendiri (keputusan 2026-10-14). APK normal terbaru (bagian 4) di vivo V2108 (`12d8c9da`), atau A54 bila tersambung. Semua angka usulan (`scripts/config.gd`, BALANCING 4-5): catat angka yang ingin diubah beserta alasannya, jangan diubah di sesi uji. Jalan uji mulai dengan 30 koran; sesudah habis, bersepeda sekitar 16 ubin (sekitar 5 detik santai) mengisi ulang (alat uji, bukan aturan game). Rumah bukan pelanggan diberi tanda lingkaran bergaris miring abu-abu di halaman; sisi dekat hanya kavling datar placeholder. Bukti desktop: tangkapan `docs/loop/20261014-fase2a-lemparan/shots/` (`tests/probe_koran_jendela.gd`).

- [ ] **Swipe pendek:** swipe sekitar 6% lebar layar (sekitar 1,5 cm di HP 6,5 inci) terbaca sebagai lempar dekat; sentuhan tak sengaja dan ketukan tidak melempar. (Sejak run fase2-arah-bebas swipe tegak juga melempar, lihat 8.4.) Swipe panjang sekitar 35% lebar layar nyaman dijangkau jempol kanan.
- [ ] **Garis bidik:** selama jari ditahan titik-titik putih melengkung dari tangan ke elips di tanah dan ikut berubah saat sepeda mempercepat atau melambat; tidak tertutup jempol. Elips ke sasaran sah (kotak surat, teras, halaman) berubah jadi elips hijau **terisi**; terbaca tanpa mengandalkan warna. Garis hilang saat jari dilepas.
- [ ] **Kena dengan sengaja:** kenai kotak surat di santai, cepat, dan ngebut. Saat ngebut garis bidik membantu melempar lebih awal (koran mewarisi kecepatan maju). Koran mendarat tepat di elips terakhir sebelum jari dilepas, walau sesudah itu sepeda direm atau pindah sisi.
- [ ] **Koran dan penanda:** koran gulung berputar dengan lengkung dan bayangan yang mengecil saat tinggi, terbaca di ×3; penanda centang (kotak surat, teras), setengah (halaman), dan silang kecil (meleset, bukan pelanggan, jendela) terbaca dan meleset tidak terasa menghukum.
- [ ] **Sisi dekat:** lempar ke sisi dekat (swipe ke kanan atau kanan bawah) terasa wajar walau zonanya placeholder datar.
- [ ] **HUD koran:** panel KORAN (angka dan 8 ikon) terbaca dan tidak tertutup jempol kanan saat swipe; swipe yang mulai di atas panel tetap melempar. Lempar sampai habis: HABIS tampil, garis bidik tidak muncul, swipe tidak melempar; lalu terisi ulang. Kidal: panel ikut pindah.
- [ ] **Jeda 0,35 detik:** dua swipe cepat berturut-turut: swipe kedua yang terlalu cepat diabaikan; apakah 0,35 detik terasa menelan swipe yang disengaja?
- [ ] **Background saat koran terbang:** tekan home atau tarik notifikasi saat koran di udara (dan tepat sesudah jari dilepas): layar jeda muncul, koran diam; sesudah Lanjut koran melanjutkan dan mendarat tanpa lompatan, koran berkurang satu saja.
- [ ] **Jendela penalti ringan:** lempar ke strip jendela di kaki fasad: silang kecil (tidak sah, tanpa hukuman lain). Apakah terasa adil? Catat sebagai bahan keputusan jendela (ROADMAP 5).

### 8.4 Uji arah lempar bebas (run `20261015-fase2-arah-bebas`, belum diuji)

Penguji: pemilik sendiri. APK normal terbaru (bagian 4) di vivo V2108 (`12d8c9da`), atau A54 bila tersambung. Laporan yang diperbaiki: "lemparan koran rasanya gak responsif, suka gagal, terutama ke arah kiri" (Run 2A menolak swipe yang lebih tegak dari 45°). Kini koran terbang ke arah swipe seperti terlihat di layar; rinciannya usulan (BALANCING 4, DESIGN_SPEC 3.7). Bukti desktop: tangkapan `docs/loop/20261015-fase2-arah-bebas/shots/` (`tests/probe_koran_jendela.gd`).

- [ ] **Arah terasa wajar:** swipe ke arah rumah yang terlihat mengenai rumah itu. Ke atas = rumah seberang di depan, ke kanan = sisi dekat, kanan atas = jauh ke depan. Garis bidik mengikuti arah jari.
- [ ] **Kotak surat seberang di depan** bisa dikenai dengan sengaja di santai, cepat, dan ngebut (swipe ke atas atau kiri atas).
- [ ] **Kiri murni:** swipe datar ke kiri mendarat di seberang sedikit ke belakang. Apakah membingungkan?
- [ ] **Swipe ke atas cukup panjang** untuk lemparan jauh: zona swipe setinggi 304 px game, lemparan terjauh butuh 35% lebar (224 sampai 280 px).
- [ ] **Flick dan tarik kembali:** jari yang masih bergerak atau berbelok saat diangkat tetap melempar ke elips terakhir; jari yang ditarik kembali ke dekat titik awal membatalkan tanpa memakai koran.
- [ ] **Masih terasa tidak responsif?** Catat apakah jeda antar lempar 0,35 detik atau jeda lepas sekitar 0,17 detik masih terasa menelan swipe (bahan Run 2B, jangan diubah di sesi uji).

### 8.5 Uji penutup Fase 2 dan M1 (run `20261015-fase2b-bantu-audio`, belum diuji)

Penguji: pemilik sendiri (keputusan 2026-10-14, rule `testing`). APK normal terbaru (bagian 4) di vivo V2108 (`12d8c9da`), atau A54 bila tersambung; volume media sekitar setengah, suara dinilai di speaker HP (bukan headphone). Semua angka usulan (`scripts/config.gd`, BALANCING 2, 4, 4b, 5): catat angka yang ingin diubah beserta alasannya, jangan diubah di sesi uji. Bukti desktop: tangkapan `docs/loop/20261015-fase2b-bantu-audio/shots/` (`tests/probe_bantu_jendela.gd`).

**Fase 2 dan M1 baru selesai** (`DEV_PHASES.md`, ROADMAP 4) kalau kotak surat bisa dikenai **dengan sengaja** di ketiga kecepatan, mode bantu bisa dimainkan, dan dua pertanyaan kontrol GDD 17 terjawab. Isi kolom hasil di tiap butir lalu ringkasannya di lembar di bawah; pemilik yang memutuskan centang.

1. [ ] **Kotak surat dengan sengaja, tiga kecepatan (mode bantu mati).** Langkah: di tiap kecepatan lempar 10 koran ke kotak surat (seberang dan dekat boleh campur): santai = stick netral, cepat = stick ke atas sekitar separuh, ngebut = stick penuh ke atas (sprite berdiri). Hitung berapa yang memberi penanda centang di kotak surat. Diharapkan: sebagian besar kena di santai dan cepat, dan ngebut masih bisa dikenai dengan sengaja memakai garis bidik (lempar lebih awal). Hasil: santai ___/10, cepat ___/10, ngebut ___/10. Catatan: ___
2. [ ] **Swipe pendek di layar kecil (GDD 17).** Langkah: lempar dengan swipe sependek mungkin (sekitar 6% lebar layar, kira-kira 1,5 cm) ke kotak surat terdekat, 10 kali. Diharapkan: swipe pendek terbaca sebagai lemparan dekat, ketukan tidak melempar (mode bantu mati), dan elips mendarat di tempat yang dimaksud. Hasil: terbaca ___/10, ketukan tak sengaja melempar ya / tidak. Cukup teliti? ya / tidak. Catatan: ___
3. [ ] **Empat arah swipe.** Langkah: swipe ke atas, kiri, kanan, dan bawah, masing-masing beberapa kali. Diharapkan: ke atas = rumah seberang di depan, ke kiri = seberang sedikit ke belakang, ke kanan = sisi dekat ke depan, ke bawah = sisi dekat ke belakang; garis tanah sejajar jari. Hasil: atas ___, kiri ___, kanan ___, bawah ___ (wajar / membingungkan). Catatan: ___
4. [ ] **Garis bidik saat melaju.** Langkah: tahan swipe sambil ngebut dan sambil melambat. Diharapkan: elips bergeser maju searah jalan saat ngebut dan koran mendarat tepat di elips terakhir sebelum jari dilepas. Hasil: sesuai / tidak. Catatan: ___
5. [ ] **Rasa responsif (K-4).** Langkah: lempar beruntun secepat mungkin, lalu satu-satu dengan cermat. Diharapkan: jeda antar lempar 0,35 detik tidak menelan swipe yang disengaja, dan jeda lepas sekitar 0,17 detik (koran keluar di frame 2 animasi) tidak terasa terlambat. Hasil: 0,35 terasa pas / terlalu lama / terlalu cepat; 0,17 terasa pas / terlambat. Angka yang diinginkan: ___
6. [ ] **Mode bantu: tap di atas dan di bawah garis jalan.** Langkah: ketuk tombol "Bantu: mati" di tengah strip atas sampai tertulis "Bantu: nyala". Ketuk zona lempar (kanan) di atas garis jalan yang melewati sepeda, lalu di bawahnya. Diharapkan: di atas = koran otomatis ke kotak surat pelanggan seberang terdekat di depan, di bawah = ke kotak surat dekat; tanpa garis bidik; selalu kena (centang di kotak surat); jeda 0,35 dan sisa koran sama dengan swipe; swipe manual tetap jalan. Hasil: sisi terasa jelas ya / tidak, garis jalan masuk akal ya / tidak. Catatan: ___
7. [ ] **Mode bantu: tanpa sasaran.** Langkah: ketuk sisi yang tidak punya kotak surat pelanggan terjangkau di depan (mis. sesaat sesudah melewati kotak surat, atau di depan rumah bukan pelanggan bertanda lingkaran bergaris). Diharapkan: tidak ada koran terpakai, cincin kecil pucat (krem bergaris gelap) muncul di titik ketukan sekitar 0,6 detik lalu hilang. Hasil: tanda terbaca ya / tidak, terasa adil ya / tidak. Catatan: ___
8. [ ] **Mode bantu + kidal.** Langkah: nyalakan "Kidal" dan "Bantu", lalu ketuk zona lempar kiri di atas dan di bawah garis jalan. Diharapkan: sama dengan butir 6 di zona kiri; stick pindah ke kanan. Hasil: ___
9. [ ] **Mode bantu satu jempol.** Langkah: dengan mode bantu nyala, mainkan satu menit hanya dengan mengetuk (tanpa menyentuh stick). Diharapkan: sepeda melaju santai sendiri (3,0 u/d, stamina tidak turun) dan kotak surat bisa diantar hanya dengan ketukan; stick tetap bisa dipakai untuk pindah sisi, melambat, rem, dan ngebut. Tombol Bantu mudah dijangkau tapi tidak terpencet tak sengaja. Hasil: bisa dimainkan satu jempol ya / tidak, tombol tertekan tak sengaja ___ kali. Catatan: ___
10. [ ] **Bunyi lempar dan mendarat.** Langkah: lempar ke kotak surat, teras, halaman (rumput), dan jalan (meleset), beberapa kali tiap permukaan, sambil mendengar tanpa melihat layar sesekali. Diharapkan: "wus" pendek tiap koran benar-benar terlempar (tidak ada saat lemparan ditolak: koran habis, jeda antar lempar, ketukan tanpa sasaran); "tunk" logam di kotak surat, "plak" kertas di teras, "puk" lembut di rumput, "plek" datar lebih pelan saat meleset; tiga variasi bergiliran tidak terasa monoton; terdengar di atas kayuhan. Hasil: empat permukaan bisa dibedakan tanpa melihat ya / tidak (yang tertukar: ___), volume wus pelan / pas / keras, mendarat pelan / pas / keras. Catatan: ___
11. [ ] **Bunyi berhenti saat jeda dan background.** Langkah: tekan tombol jeda tepat sesudah melempar (saat "wus" atau bunyi mendarat berbunyi); lalu tekan home saat koran di udara dan buka lagi. Diharapkan: bunyi berhenti seketika, layar jeda muncul, tidak ada bunyi lama yang menyusul sesudah "Lanjut"; koran yang beku mendarat sesudah lanjut dengan satu bunyi baru. Hasil: ya / tidak. Catatan: ___
12. [ ] **Dua pertanyaan kontrol GDD 17.** (a) Ambang rem di ujung bawah stick nyaman tanpa berhenti tak sengaja: sudah lolos uji HP pemilik 2026-10-14; cukup konfirmasi masih benar sesudah lemparan dan mode bantu ada. Hasil: masih nyaman ya / tidak. (b) Swipe pendek cukup teliti di layar kecil: jawaban dari butir 2. Hasil: ya / tidak.

**Lembar hasil (salin ke PR uji atau `docs/loop/`):**

```
Penguji: pemilik   Tanggal: ____   HP: vivo V2108 / A54 / lainnya: ____   Build (commit): ____
1. Kotak surat sengaja: santai __/10  cepat __/10  ngebut __/10
2. Swipe pendek: terbaca __/10  cukup teliti: ya / tidak
3. Empat arah: atas __  kiri __  kanan __  bawah __
4. Garis bidik saat melaju: sesuai / tidak
5. Responsif: jeda 0,35 pas / lama / cepat   jeda lepas 0,17 pas / terlambat   angka diinginkan: ____
6-9. Mode bantu: sisi jelas ya / tidak   tanpa sasaran terbaca ya / tidak   kidal ya / tidak   satu jempol ya / tidak   tombol tak sengaja __ kali
10. Bunyi: empat permukaan dibedakan ya / tidak (tertukar: ____)   volume wus ____   mendarat ____
11. Bunyi berhenti saat jeda/background: ya / tidak
12. GDD 17: rem masih nyaman ya / tidak   swipe pendek teliti ya / tidak
Angka yang ingin diubah dan alasannya: ____
Keputusan pemilik: Fase 2 selesai ya / belum   M1 selesai ya / belum
```

### 8.6 Uji penutup 3A: rute perumahan dari segmen (run `20261016-fase3a-rute`, terpasang di vivo V2108 2026-10-16, belum diuji)

Penguji: pemilik sendiri (rule `testing`). APK normal terbaru (bagian 4; scene utama sejak run 4A `scenes/hari/hari.tscn`; rute dimulai lewat Berangkat) di vivo V2108 (`12d8c9da`), atau A54 bila tersambung. Semua angka dan aset usulan: catat yang ingin diubah beserta alasannya, jangan diubah di sesi uji. Bukti desktop: tangkapan `docs/loop/20261016-fase3a-rute/shots/` (`tests/probe_rute_jendela.gd`, 2340x1080 dan 1600x720). Uji 8.5 (Fase 2 dan M1) tetap terpisah dan belum diisi.

1. [ ] **Rute dari awal sampai garis akhir tanpa patah.** Langkah: mainkan satu rute penuh (sekitar 236 ubin: sekitar 79 detik santai, sekitar 40 detik ngebut; BALANCING 6) santai, lalu satu kali ngebut. Diharapkan: 60 fps tanpa lonjakan atau patah saat rumah muncul, memuat di bawah 1 detik sejak game dibuka, rumah muncul tepat di tepi layar tanpa terlihat "muncul tiba-tiba" dekat sepeda. Hasil: mulus ya / tidak, memuat terasa cepat ya / tidak, di mana patah: ___
2. [ ] **25 pelanggan terasa dan tidak dihafal.** Langkah: tekan "Main lagi" di akhir rute dan mainkan tiga rute berturut-turut (seed berbeda). Diharapkan: tiga susunan terasa berbeda (urutan segmen dan letak rumah pelanggan), jarak antar pelanggan terasa kira-kira 2 sampai 3 detik, ada kelompok rumah berurutan lalu sela panjang. Hasil: terasa berbeda ya / tidak, sudah mulai hafal setelah tiga ya / tidak, jarak antar pelanggan pas / terlalu rapat / terlalu jarang. Catatan: ___
3. [ ] **Kotak surat dengan sengaja di tiga kecepatan.** Langkah: di rute, lempar ke kotak surat pelanggan (area oranye tipis di rumput halaman, menempel trotoar, dengan kotak surat oranye di tengah area, 1,0 x 1,25 ubin; sprite rumah pelanggan tidak lagi punya kotak merah di teras; lihat butir 9) di santai, cepat, dan ngebut, mode bantu mati. Diharapkan: sebagian besar kena di santai dan cepat, ngebut masih bisa dikenai dengan garis bidik. Hasil: santai ___/10, cepat ___/10, ngebut ___/10. Catatan: ___
4. [ ] **Satu kotak surat per rumah pelanggan.** Kotak surat merah di teras sprite rumah pelanggan sudah dihapus (render ulang `tools/env_art/fase3.py`, QA-005); sasarannya hanya area oranye tipis dengan satu kotak surat oranye di tengah area (bentuk kotak surat dari `lib.kotak_surat`, warna oranye placeholder sasaran, usulan; gambar final di Fase 5). Hasil: area oranye dan kotak surat jelas sebagai sasaran, dan kotak surat terbaca sebagai kotak surat, ya / tidak. Catatan: ___
5. [ ] **Mode bantu mengenai kotak surat pelanggan terdekat.** Langkah: nyalakan "Bantu: nyala", ketuk di atas garis jalan di depan beberapa rumah. Diharapkan: koran otomatis ke kotak surat pelanggan seberang terdekat di depan (centang), tidak pernah ke rumah bukan pelanggan atau sisi dekat; tanpa sasaran = tanda kecil pucat, koran tidak terpakai. Hasil: ___
6. [ ] **Objek penutup semi-transparan terbaca.** Di rute nyata rumah di tepi jalan praktis tidak pernah menutupi sepeda (aturan 3D `PenutupPemain`, BALANCING 6b); jadi periksa dua hal: (a) apakah ada rumah atau atap yang terlihat menimpa sepeda di layar padahal tidak semi-transparan (catat di mana: jarak rute, sisi), (b) apakah sprite rumah dan kotak surat tajam di ×3 dan tidak menyembunyikan sepeda. Hasil: ada tumpang tindih yang mengganggu ya / tidak (___), tajam ya / tidak.
7. [ ] **Banner "Rute selesai" dan tombol "Main lagi".** Langkah: sampai garis akhir. Diharapkan: sepeda mengerem sampai berhenti, banner di tengah atas terbaca, tombol "Main lagi" di pojok kanan atas terbaca dan tidak tersentuh tak sengaja saat bermain (tersembunyi sampai akhir rute); stick tidak lagi menggerakkan sepeda; koran yang sudah terbang tetap mendarat. Tekan "Main lagi": rute baru dari awal, koran 30. Hasil: banner terbaca ya / tidak, tombol tertekan tak sengaja ___ kali, jarak berhenti pas / terlalu jauh. Catatan: ___
8. [ ] **Jeda dan back di rute.** Langkah: tekan jeda di tengah rute (juga tombol back dan home). Diharapkan: sama dengan 8.5 butir 11: sepeda dan koran terbang membeku, tanpa lanjut otomatis, lanjut tanpa lompatan. Hasil: ya / tidak.

9. [ ] **Area kotak surat terbaca dan terasa lebih mudah** (tindak lanjut review pemilik, 2026-10-16). Zona kotak surat diperbesar dari 0,5 x 0,5 ke area sekitar 1,0 x 1,5 dan digambar di tanah rute (isi oranye tipis, garis tepi gelap) di sekitar kotak surat oranye, hanya untuk rumah pelanggan seberang. Sejak PR #30 (2026-10-16) area itu ada di rumput halaman: seberang 1,0 x 1,25 ubin, dekat 0,75 x 1,25 (lihat butir 10). Langkah: lempar ke kotak surat pelanggan di santai, cepat, dan ngebut, mode bantu mati; bandingkan dengan butir 3 (zona kecil). Diharapkan: area terbaca jelas tanpa menutupi sepeda atau penanda centang, dan kena terasa lebih mudah. Hasil: area terbaca ya / tidak, tidak mengganggu pandangan ya / tidak, kena santai ___/10, cepat ___/10, ngebut ___/10, terlalu mudah / pas / masih sulit. Catatan: ___ (angka usulan; "inti" 0,5 x 0,5 sebagai bonus presisi belum diputuskan, Run 3B).

10. [ ] **Sepeda boleh naik trotoar dan kotak surat di halaman** (permintaan pemilik, 2026-10-16, PR #30; merevisi batas tepi jalan D-4). Batas lateral sepeda kini tepi trotoar (+-2,0 ubin), rumput halaman tetap tidak bisa dimasuki. Langkah: geser sepeda sampai mentok ke kiri dan kanan di santai, cepat, dan ngebut; lempar ke kotak surat pelanggan dari aspal dan dari tepi trotoar seberang. Diharapkan: sepeda berhenti di tepi trotoar, tepi peta tidak terlihat, sepeda tidak tertutup rumah secara janggal; kotak surat oranye berdiri di rumput halaman dan areanya menempel trotoar; dari tepi trotoar seberang kotak surat hanya sekitar 0,25 ubin ke samping, jadi kena butuh lemparan serong ke depan. Hasil: trotoar terasa bisa dilalui ya / tidak, tepi peta terlihat ya / tidak, kotak surat di halaman terbaca ya / tidak, kena dari trotoar terasa wajar / terlalu sulit. Catatan: ___

**Lembar hasil 3A:**

```
Penguji: pemilik   Tanggal: ____   HP: vivo V2108 / A54 / lainnya: ____   Build (commit): ____
1. Rute mulus: ya / tidak   memuat < 1 detik: ya / tidak   patah di: ____
2. Tiga seed beda: ya / tidak   dihafal: ya / tidak   jarak pelanggan: pas / rapat / jarang
3. Kotak surat sengaja: santai __/10  cepat __/10  ngebut __/10
4. Dua kotak surat membingungkan: ya / tidak   sasaran: oranye / merah / keduanya
5. Mode bantu ke pelanggan terdekat: ya / tidak
6. Penutup: tumpang tindih mengganggu ya / tidak (____)   tajam di x3 ya / tidak
7. Banner terbaca: ya / tidak   tombol tak sengaja __ kali   jarak berhenti pas / jauh
8. Jeda dan back: ya / tidak
9. Area kotak surat: terbaca ya / tidak   tidak mengganggu ya / tidak   santai __/10  cepat __/10  ngebut __/10   terlalu mudah / pas / sulit
10. Trotoar bisa dilalui: ya / tidak   tepi peta terlihat: ya / tidak   kotak surat di halaman terbaca: ya / tidak   kena dari trotoar: wajar / terlalu sulit
Angka dan aset yang ingin diubah dan alasannya: ____
```

### 8.7 Uji penutup 3B: rintangan, tabrakan, skor, dan bel (run `20261017-fase3b-rintangan-skor`, belum diuji)

Penguji: pemilik sendiri (rule `testing`). APK normal terbaru (bagian 4) di vivo V2108 (`12d8c9da`), atau A54 bila tersambung. Semua angka, aset, dan bunyi usulan (`BALANCING.md` 5b, 6c, 6d, 6e; `DESIGN_SPEC.md` 3.6 dan 3.8). Tangkapan desktop pembanding: `docs/loop/20261017-fase3b-rintangan-skor/shots/iter1/` (`probe_rintangan_jendela.gd`).

1. [ ] **Tanda rintangan cukup.** Langkah: lewati anjing dan mobil di santai, cepat, dan ngebut. Diharapkan: anjing berdiri dan menggeram, mobil berkedip lampu mundur dan berbunyi bip, cukup lama sebelum bahaya (tidak "tidak sempat"); tiap tabrakan bisa dijelaskan dari tanda yang terlihat.
2. [ ] **Pola anjing adil (D-2).** Anjing baru mengejar sesudah sepeda melewati rumahnya. Diharapkan: ngebut di separuh jalan lawan lolos, santai di sisi anjing tersusul, di tepi trotoar sisi anjing bisa tertabrak. Terasa adil?
3. [ ] **Pola mobil (D-1).** Mobil yang sudah keluar berhenti di separuh jalannya sampai rute habis. Diharapkan: separuh jalan lain selalu bebas. Wajar, atau perlu kembali ke garasi?
4. [ ] **Rasa tabrakan = jatuh (keputusan pemilik 2026-10-17).** Langkah: tabrak anjing dan mobil di santai dan ngebut, juga sengaja di mobil yang sudah berhenti di garis tengah. Yang terjadi: pemain jatuh (animasi jatuh lalu terjerembab) 1,2 detik dengan kecepatan 0, stick dan lemparan tidak berpengaruh, kilatan di atas kepala, bunyi tabrakan lembut, label PUTUS; lalu bangun, dikayuh lagi dari 0, dan berkedip 1,0 detik (kebal). Diharapkan: jatuh terasa **adil** (selalu bisa dijelaskan dari tanda rintangan), **tidak menyebalkan** (1,2 detik tidak terasa lama, tidak terasa dihukum dua kali), dan **bisa dijelaskan** (jelas kapan bisa bergerak lagi); tidak ada tabrakan dobel beruntun; tidak pernah terjebak di dalam mobil. Catat juga apakah tubuh yang terjerembab terlihat wajar di depan mobil dan apakah semua arah memakai gambar lurus terasa janggal.
5. [ ] **Dua rintangan berseberangan rapat** (mis. anjing `dekat` lalu mobil `seberang` sekitar 6 ubin). Diharapkan: pindah sisi masih sempat di santai, cepat, ngebut.
6. [ ] **Skor, combo, koin terbaca.** Panel SKOR / COMBO / KOIN di kanan atas (kidal: kiri atas) tidak menutupi apa pun di 2400×1080. Combo naik x0,1 tiap antaran beruntun, kembali x1.0 dengan label PUTUS saat meleset atau tabrakan.
7. [ ] **Nada combo, denting tip, bonus tepat.** Antaran beruntun terdengar naik nadanya (sampai 5 tingkat); teras ke pelanggan pemberi tip berdenting; kena tepat di tengah kotak surat memberi penanda sasaran (bukan centang), "+15 / TEPAT" melayang, dan kilau. Diharapkan: memuaskan; tepat tidak terlalu sulit atau terlalu mudah.
8. [ ] **Koran kedua ke rumah yang sama.** Diharapkan: penanda garis abu-abu (netral), skor dan koin tidak bertambah, combo tidak putus.
9. [ ] **Tombol bel terjangkau.** Ketuk tombol bel di kanan bawah (kidal: kiri bawah; sejak 2026-10-17 pusatnya 64 px game dari tepi samping dan bawah, bukan di pojok, lihat 8.8 butir 17). Diharapkan: "KRING!" di atas setang dan bunyi bel; ketuk lagi cepat = "KRING KRING!" lalu cincin jeda berkurang; tombol tidak bentrok dengan swipe (swipe yang melewati tombol tetap melempar) dan tidak terpencet tak sengaja.
10. [ ] **Bel membuat anjing mundur (K-3, D-5).** Bunyikan bel saat anjing waspada atau mengejar di dekat sepeda (sampai 1 ubin di belakang). Diharapkan: "!" di atas anjing, anjing diam sebentar lalu lari pulang; mobil tidak bereaksi. Terasa adil (anjing tidak jadi tak berarti)? Jangkauan 1 ubin ke belakang perlu ditinjau.
11. [ ] **Tanpa suara.** Matikan suara. Diharapkan: semua isyarat (tanda rintangan, tabrakan, bel, tepat, tip) tetap terbaca dari visual.
12. [ ] **Jeda dan Main lagi.** Jeda di tengah anjing mengejar, sesudah tabrakan, dan sesudah bel: semua membeku, tanpa lanjut otomatis. "Main lagi" di akhir rute: skor, koin, combo, rintangan, bel kembali ke awal.
13. [ ] **Mobil di celah dan kotak surat abu-abu (keputusan pemilik 2026-10-17).** Mobil garasi parkir di celah samping rumah dan tidak menembus dinding saat parkir maupun mundur. Rumah bukan pelanggan seberang punya kotak surat abu-abu yang lebih rendah. Diharapkan: saat ngebut, kotak surat abu-abu tidak terbaca sebagai sasaran (yang menarik mata tetap kotak surat oranye dan areanya). Tangkapan desktop: `docs/loop/20261017-fase3b-rintangan-skor/shots/fix_mobil_kotak_surat/`.

**Lembar hasil 3B:**

```
Penguji: pemilik   Tanggal: ____   HP: vivo V2108 / A54 / lainnya: ____   Build (commit): ____
1. Tanda cukup: santai ya/tidak  cepat ya/tidak  ngebut ya/tidak   tabrakan tak terjelaskan: ____
2. Pola anjing adil: ya / tidak (____)
3. Mobil berhenti di jalan: wajar / perlu kembali ke garasi
4. Tabrakan: pas / terlalu menghukum / terlalu ringan   dobel: ya / tidak
5. Berseberangan rapat sempat: santai ya/tidak  cepat ya/tidak  ngebut ya/tidak
6. HUD skor terbaca: ya / tidak   menutupi: ____
7. Nada combo: ya / tidak   tip: ya / tidak   tepat: terlalu sulit / pas / terlalu mudah
8. Netral jelas: ya / tidak
9. Bel terjangkau: ya / tidak   bentrok swipe __ kali   terpencet tak sengaja __ kali
10. Anjing mundur adil: ya / tidak   jangkauan belakang 1 ubin: perlu / tidak
11. Tanpa suara terbaca: ya / tidak
12. Jeda dan Main lagi: ya / tidak
13. Mobil di celah wajar: ya / tidak   kotak surat abu-abu terbaca sebagai sasaran saat ngebut: ya / tidak
Angka, bunyi, dan aset yang ingin diubah dan alasannya: ____
```

### 8.8 Uji penutup Fase 3: radar, HUD rute final, tenggat, layar hasil (run `20261018-fase3c-hud-hasil`, belum diuji)

Penguji: pemilik sendiri (rule `testing`; tidak ada penguji lain). APK normal terbaru (bagian 4) di vivo V2108 (`12d8c9da`, 2400×1080, ada lubang kamera), atau A54 bila tersambung. Uji 8.5 (Fase 2 dan M1), 8.6 (3A), dan 8.7 (3B) tetap terpisah dan diisi di lembarnya sendiri. Semua angka, aset, dan tata letak usulan (`BALANCING.md` 6 dan 6f, `DESIGN_SPEC.md` 3, 3.2 sampai 3.4, dan 4; usulan O-6 sampai O-12 di `docs/loop/20261018-fase3c-hud-hasil/SPEC.md`): catat yang ingin diubah beserta alasannya, jangan diubah di sesi uji. Tangkapan desktop pembanding: `docs/loop/20261018-fase3c-hud-hasil/shots/*_hud_*.png` (`tests/probe_hud_rute_jendela.gd`, 1920×1080, 2340×1080, 2400×1080, 1600×720). Fase 3 baru selesai sesudah lembar ini diisi (`DEV_PHASES.md`).

1. [ ] **20 rute dibangun tanpa galat (bukti mesin, tidak perlu dimainkan).** Tes headless `tests/tes_rute.gd` (20 seed: urutan segmen dan pelanggan bervariasi, panjang 200 sampai 300 ubin) dan `tests/tes_rintangan.gd` (20 seed: sisi bebas selalu ada, bot santai dan ngebut di sisi bebas tanpa tabrakan, garis akhir tepat sekali, bot santai sampai sebelum tenggat) lolos di `run_tests.gd`. Hasil: lolos ya / tidak, commit: ___
2. [ ] **3 rute dimainkan (ROUTE_DESIGN 7).** Langkah: mainkan tiga rute berturut-turut lewat "Main lagi" di layar hasil (seed + 1 tiap kali), campur santai, cepat, dan ngebut. Diharapkan: ketiganya bisa dilewati tanpa tabrakan oleh pemain yang memperhatikan; tiap rute selesai dengan layar hasil. Hasil: ___
3. [ ] **Tidak terasa dihafal setelah tiga kali.** Diharapkan: urutan segmen, letak pelanggan, rintangan terasa berbeda; tidak menebak rumah berikutnya dari ingatan. Hasil: ya / tidak. Catatan: ___
4. [ ] **Tiap tabrakan bisa dijelaskan.** Catat tiap tabrakan selama tiga rute: penyebab (anjing/mobil), tanda terlihat atau tidak, dan apakah pemain bisa menjelaskan kenapa menabrak (ROUTE_DESIGN 7). Hasil: ___ tabrakan, tak terjelaskan: ___
5. [ ] **Radar terbaca saat ngebut.** Strip kiri (seberang) dan kanan (dekat), penanda 8×6 px game bergerak turun saat rumah mendekat; jangkauan 30 ubin (sekitar 5 detik ngebut). Langkah: ngebut sambil melirik radar. Diharapkan: penanda pelanggan (kuning), pemberi tip (hijau bertitik), dan "masuk jangkauan lempar" (membesar, garis terang) terbedakan tanpa berhenti; ancang-ancang terasa cukup; radar tidak tertutup jempol. Hasil: terbaca ya / tidak, jangkauan 30 ubin pas / pendek / panjang, tip terbaca ya / tidak, jangkau terbaca ya / tidak.
6. [ ] **HUD final terbaca dan tidak menutupi apa pun di vivo V2108.** Panel progres tengah atas (WAKTU / LEWAT, "n/25 TERKIRIM", 25 kotak 8×8 dengan simbol ✓ × ▶ kosong), panel koin dan skor/combo kanan atas, radar, tombol jeda, panel bawah, bel. Diharapkan: teks 8 px terbaca; simbol kotak terbedakan di ×3; tidak ada yang tertutup lubang kamera atau keluar zona aman (game terkunci landscape satu arah, `window/handheld/orientation=0` di `project.godot`; landscape terbalik belum didukung, jadi lubang kamera selalu di tepi yang sama); HUD tidak menutupi sepeda, jalan di depan, atau tanda rintangan (mobil seberang saat tanda lampu mundur bisa sebagian di bawah panel koin/skor, lihat butir 13). Hasil: terbaca ya / tidak, tertutup lubang kamera: ___, menutupi: ___
7. [ ] **Tenggat terasa adil.** Tenggat = waktu tempuh santai × 1,15 (sekitar 89 sampai 92 detik). Langkah: satu rute santai tanpa berhenti; satu rute dengan berhenti lama (rem) beberapa kali. Diharapkan: santai sampai sebelum tenggat dengan sisa sedikit; berhenti lama terasa ada harganya; ngebut terasa tidak perlu memburu jam. Hasil: santai sempat ya / tidak (sisa ___ detik), berhenti lama terasa ya / tidak, 1,15 pas / ketat / longgar.
8. [ ] **Tip hilang sesudah tenggat terbaca.** Sesudah "LEWAT +m:ss" (oranye, teks berubah), antaran tetap memberi ongkos 15, skor, dan combo, tetapi teras pemberi tip tidak memberi "tip +5" dan tidak berdenting; radar menampilkan pemberi tip sebagai pelanggan biasa. Diharapkan: pemain paham kenapa tip tidak ada; tidak terasa menghukum (tanpa potong koin, rute jalan terus). Hasil: paham ya / tidak, terasa wajar / menghukum.
9. [ ] **Layar hasil hangat.** Muncul sekitar 0,6 detik (santai) sampai 1,2 detik (ngebut) sesudah garis akhir, saat sepeda berhenti dan koran sudah mendarat. Urutan: Terkirim, Tip, Koin, Skor, Tepat, lalu Meleset dan status tenggat abu-abu netral. Diharapkan: terasa menghargai yang berhasil, bukan layar kalah; terbaca di 2400×1080; "Main lagi" tidak tertekan tak sengaja (jari masih di layar saat hasil muncul); back Android di layar hasil tidak melakukan apa-apa. Hasil: hangat ya / tidak, terbaca ya / tidak, tak sengaja ___ kali, back wajar ya / tidak.
10. [ ] **Sakelar Kidal dan Bantu di layar jeda mudah.** Langkah: jeda, ketuk "Kidal: mati" dan "Bantu: mati" (96×42 px game), lanjut, lalu jeda lagi dan matikan. Diharapkan: satu ketukan membalik, status terbaca dari teks dan bingkai oranye; kidal menukar zona stick/swipe, panel bawah, dan bel, tetapi radar tetap (kiri = seberang); bantu langsung memakai tap dan menampilkan rumah bukan pelanggan abu-abu (berlubang) di radar. Hasil: mudah ya / tidak, radar tetap saat kidal terasa benar ya / tidak.
11. [ ] **Mode bantu menyelesaikan rute sebelum tenggat.** Langkah: satu rute penuh mode bantu, hanya tap. Diharapkan: sampai sebelum tenggat tanpa tabrakan bila memilih sisi bebas; abu-abu di radar membantu memilih sisi tap. Hasil: ya / tidak.
12. [ ] **Zona aman nyata (NEEDS-MANUAL D-7 run 3C).** Apakah `DisplayServer.get_display_safe_area()` melaporkan inset di vivo V2108? Bila ya, radar, tombol jeda, panel koin/skor, panel bawah, dan bel bergeser ke dalam sama besar dan tidak ada yang tertutup lubang kamera; bila tidak (inset 0), catat apakah lubang kamera menutupi radar kiri/kanan atau tombol jeda. Hasil: inset terbaca ya / tidak, yang tertutup: ___
13. [ ] **Mobil seberang dan panel kanan atas (NEEDS-MANUAL run 3C).** Saat tanda lampu mundur mobil garasi seberang mulai terlihat, mobil bisa tampil sebagian di bawah panel koin/skor kanan atas (lebih kecil dari QA-007 run 3B karena strip atas tengah kini hanya panel progres). Diharapkan: lampu mundur tetap tertangkap mata. Hasil: tertangkap ya / tidak.
14. [ ] **Panel progres terbaca (NEEDS-MANUAL run 3C).** "WAKTU 1:31" / "LEWAT +0:12" dan "n/25 TERKIRIM" dengan font 8 px; kotak terlewat muncul sekitar 3 ubin sesudah rumah pelanggan yang tidak terantar dilewati (masih bisa dikenai lemparan ke belakang sebelum itu). Hasil: terbaca ya / tidak, terlewat muncul pada saat yang wajar ya / tidak.
15. [ ] **Tanpa suara.** Semua isyarat baru (tenggat lewat, tip hilang, layar hasil) terbaca dari visual. Hasil: ya / tidak.
16. [ ] **Keputusan rumah sisi dekat (bukan uji HP wajib).** Lihat `docs/loop/20261018-fase3c-hud-hasil/shots/spike_sisi_dekat/` (tiga pendekatan × jalur, trotoar, lempar) dan catatan perbandingan di LOG run itu, lalu pilih pendekatan atau tetapkan tanggal keputusan (paling lambat sebelum aset Fase 8, TECH_PLAN Fase 3). Spike bisa dicoba di desktop: `godot --path . scenes/dev/spike_sisi_dekat.tscn` (tombol 1/2/3). Hasil: pendekatan ___ / tanggal keputusan ___
17. [ ] **Bel terjangkau jempol kanan dan kiri tanpa menekuk (masukan review pemilik 2026-10-17, PR #33).** Tombol bel kini berpusat 64 px game dari tepi samping dan 64 dari tepi bawah (sekitar 1,2 cm dari tepi di vivo V2108; dulu 28 dan 28, di pojok), kidal dicerminkan ke kiri. Langkah: pegang HP dua tangan seperti bermain; ketuk bel berkali-kali dengan jempol kanan sambil jempol kiri di stick, lalu nyalakan Kidal di layar jeda dan ulangi dengan jempol kiri. Lalu swipe lempar dari sekitar tombol ke arah rumah (mulai di dekat tombol, di luar lingkarannya) dan di pojok bawah lama. Diharapkan: bel terjangkau tanpa menekuk jempol atau menggeser genggaman, tangan kanan dan kidal; bel tidak menghalangi swipe (swipe yang dimulai di luar tombol, termasuk di pojok lama, tetap melempar; sentuhan yang dimulai di tombol selalu "KRING", tidak pernah melempar); tombol tidak menutupi panel koran atau sepeda. Hasil: terjangkau kanan ya / tidak, kidal ya / tidak, menghalangi swipe __ kali, terpencet tak sengaja __ kali, posisi pas / terlalu ke dalam / terlalu ke tepi / terlalu tinggi / terlalu rendah.

**Lembar hasil 8.8 (penutup Fase 3):**

```
Penguji: pemilik   Tanggal: ____   HP: vivo V2108 / A54 / lainnya: ____   Build (commit): ____
1. 20 rute tanpa galat (tes): lolos ya / tidak   commit: ____
2. 3 rute dimainkan: ya / tidak   bisa dilewati tanpa tabrakan: ya / tidak
3. Dihafal setelah tiga kali: ya / tidak
4. Tabrakan: __ kali   tak terjelaskan: ____
5. Radar saat ngebut: terbaca ya / tidak   30 ubin pas / pendek / panjang   tip ya / tidak   jangkau ya / tidak
6. HUD final: terbaca ya / tidak   tertutup lubang kamera: ____   menutupi: ____
7. Tenggat: santai sempat ya / tidak (sisa __ detik)   berhenti lama terasa ya / tidak   1,15 pas / ketat / longgar
8. Tip hilang sesudah tenggat: paham ya / tidak   wajar / menghukum
9. Layar hasil: hangat ya / tidak   terbaca ya / tidak   Main lagi tak sengaja __ kali   back wajar ya / tidak
10. Sakelar layar jeda: mudah ya / tidak   radar tetap saat kidal benar ya / tidak
11. Mode bantu sebelum tenggat: ya / tidak
12. Zona aman: inset terbaca ya / tidak   tertutup: ____
13. Lampu mundur mobil di bawah panel kanan atas tertangkap: ya / tidak
14. Panel progres terbaca: ya / tidak   terlewat wajar: ya / tidak
15. Tanpa suara terbaca: ya / tidak
16. Rumah sisi dekat: pendekatan 1 / 2 / 3 / tanggal keputusan ____
17. Bel terjangkau: kanan ya / tidak   kidal ya / tidak   menghalangi swipe __ kali   tak sengaja __ kali   posisi pas / ke dalam / ke tepi / tinggi / rendah
Angka, tata letak, dan aset yang ingin diubah dan alasannya: ____
```

### 8.9 Uji alur satu hari: koran, rute, hasil, hari berikutnya (run `20261018-fase4a-koran-hari`, belum diuji)

Penguji: pemilik sendiri (rule `testing`). **Pasang tanpa menghapus apa pun:** `adb install -r builds/kring-kring-debug.apk` (ekspor APK debug: bagian 4; hanya setelah izin pemilik, HP dipakai bersama project lain). **Jangan `pm clear` dan jangan uninstall** (save di `user://save.json` ikut terhapus); mulai dari awal cukup dengan save yang sudah ada atau save baru. Menutup app = force stop (`adb shell am force-stop com.rmh.kring` atau geser dari recent), bukan hapus data. Fase 4 dan M2 baru boleh dicentang sesudah run 4B dan uji ini diisi. Nama koran "Warta Kring" dan "Perumahan Melati" adalah placeholder usulan. **Efek berita utama belum diterapkan** (S-5): headline "Pasar Kaget" atau "Jalan Sedang Diperbaiki" tidak mengubah rute.

Urutan uji:

1. [ ] **Layar koran terbaca dalam 10 detik di A54 dan vivo V2108.** Buka app. Diharapkan: halaman krem dengan "Warta Kring", "Hari 1 · Perumahan Melati", satu berita utama besar, berita ringan, panel misi "Kucing Bu Ratmi Hilang Sejak Semalam" dengan ringkasan satu baris, tombol Ambil, Lewati, Berangkat. Tidak ada paragraf; tidak ada teks terpotong; tidak tertutup lubang kamera. Hasil: terbaca dalam ___ detik, terpotong: ___
2. [ ] **Krem terang tidak menyilaukan setelah layar gelap.** Buka koran dari layar gelap (hasil rute, atau app baru dibuka di ruang redup). Hasil: nyaman ya / silau.
3. [ ] **Ambil, Lewati, Berangkat terasa pas.** Ketuk Ambil lalu Lewati lalu Ambil: tombol terpilih terisi gelap dengan bingkai tebal dan teks status berubah ("Misi diambil", "Misi dilewati", awal "Belum dipilih; berangkat = dilewati"). Berangkat di bawah jempol kanan. Hasil: target pas ya / tidak, salah ketuk ___ kali, status terbaca tanpa warna ya / tidak.
4. [ ] **Rute hari 1 berjalan seperti 3A sampai 3C.** Berangkat tanpa misi atau dengan Ambil (di 4A misi tidak berefek di rute; sejak run 4B Ambil mengaktifkan kucing, lihat 8.10). Hasil: rute normal ya / tidak (tombol jeda, radar, tenggat, layar hasil).
5. [ ] **Layar hasil menawarkan "Hari berikutnya".** Sesudah garis akhir. Diharapkan: tombol "Hari berikutnya" (tidak ada "Main lagi"); angka sama dengan yang tampil; satu ketukan membuka koran hari 2. Ketuk cepat dua kali tidak melompati hari 3. Hasil: ya / tidak.
6. [ ] **Koran hari 2 dan rute hari 2 berbeda.** Diharapkan: berita utama dan ringan berbeda dari hari 1; bila P1 diambil di hari 1 baris misi menampilkan "Tidak ada misi sampingan hari ini" tanpa tombol Ambil/Lewati (jeda 7 hari), bila dilewati P1 muncul lagi; rute (urutan rumah) terasa berbeda. Hasil: berbeda ya / tidak, misi: ___
7. [ ] **Force stop di tengah rute lalu buka lagi.** Berangkat hari 2, kayuh sebentar, force stop. Diharapkan: app terbuka di koran hari 2 (BUKAN hari 3) dengan headline dan misi yang sama, koin dan hari kemarin utuh, Ambil/Lewati diulang dari awal. Hasil: koran sama ya / tidak, progres utuh ya / tidak.
8. [ ] **Back Android.** Di koran: keluar app. Di rute: menjeda (back lagi melanjutkan). Di layar hasil: tidak terjadi apa pun. App ke background di koran lalu kembali: aman. Hasil: ya / tidak per layar.
9. [ ] **Kidal dan Bantu bertahan.** Di jeda nyalakan Kidal atau Bantu, selesaikan hari, "Hari berikutnya", Berangkat: masih menyala; force stop lalu buka lagi: masih menyala. Hasil: ya / tidak.
10. [ ] **Tanpa suara.** Layar koran tidak punya isyarat suara; semua status terbaca dari teks dan bentuk. Hasil: ya / tidak.
11. [ ] **Jeda dan hasil tidak menyimpan.** Bukti mesin (tes alur hari): tepat satu simpan per hari. Di HP cukup: setelah force stop di hasil (sebelum "Hari berikutnya") app membuka hari yang sama. Hasil: ya / tidak.

**Lembar hasil 8.9 (alur satu hari, run 4A):**

```
Penguji: pemilik   Tanggal: ____   HP: vivo V2108 / A54 / lainnya: ____   Build (commit): ____
1. Koran terbaca dalam 10 detik: ya / tidak (__ detik)   terpotong: ____   tertutup lubang kamera: ____
2. Krem menyilaukan: ya / tidak
3. Ambil/Lewati/Berangkat: pas ya / tidak   salah ketuk __ kali   status terbaca tanpa warna ya / tidak
4. Rute hari 1 normal: ya / tidak
5. Hari berikutnya: ya / tidak   lompat hari karena ketuk ganda: ya / tidak
6. Hari 2 berbeda: ya / tidak   misi hari 2: ____
7. Force stop di rute: koran sama ya / tidak   progres utuh ya / tidak
8. Back: koran ya / tidak   rute ya / tidak   hasil ya / tidak   background ya / tidak
9. Kidal dan Bantu bertahan: ya / tidak
10. Tanpa suara terbaca: ya / tidak
11. Force stop di hasil: hari sama ya / tidak
Catatan (teks, tata letak, angka yang ingin diubah dan alasannya): ____
```


### 8.10 Uji misi kucing P1 dan tutorial (run `20261018-fase4b-misi-kucing`, belum diuji)

Penguji: pemilik sendiri (rule `testing`). Semua angka dan perilaku usulan (BALANCING 6g, GDD 10.3): catat angka yang ingin diubah beserta alasannya, jangan diubah di sesi uji. **Pasang tanpa menghapus apa pun** (`adb install -r builds/kring-kring-debug.apk`, hanya setelah izin pemilik; HP dipakai bersama project lain). **Jangan `pm clear` dan jangan uninstall.** Catatan penting: save dari run 4A di vivo V2108 sudah melewati hari 1 dan menahan P1 selama jeda 7 hari (P1 diambil hari 1 boleh muncul lagi mulai hari 8), jadi P1 dan tutorial TIDAK muncul di save itu. Pilihan (tanya pemilik dulu, jangan dilakukan sendiri): (a) uji di HP lain atau pasang sebagai app terpisah dengan nama paket lain; (b) pemilik sendiri menghapus data app hanya bila rela kehilangan save; (c) bermain sampai P1 muncul lagi (hari 8 atau hari lain tanpa P1 diambil); (d) bukti desktop di `docs/loop/20261018-fase4b-misi-kucing/shots/` (`tests/probe_misi_jendela.gd`). Save v1 dari 4A dimigrasi otomatis ke v2 tanpa kehilangan koin dan hari (dites dengan fixture save 4A asli).

Urutan uji (dengan save yang memunculkan P1 dan tutorial hari 1):

1. [ ] **Tutorial hari 1.** Berangkat dengan Ambil. Diharapkan: petunjuk "PETUNJUK 1/4" di kiri atas bawah kartu misi, berganti per langkah (ngebut, melambat, lempar, menepi), tombol "Lewati" di strip atas (bukan di zona lempar), tidak menghalangi stick atau swipe. Lewati: petunjuk hilang dan tidak muncul lagi. Hari 2 tidak ada tutorial. Hasil: terbaca ya / tidak, mengganggu ya / tidak.
2. [ ] **Kartu misi dan kucing terlihat.** Diharapkan: kartu "Kucing 0/1 · N rumah" di kiri atas (di bawah tombol jeda), N turun tiap rumah seberang dilewati; kucing kecil dengan kilau kuning (9x9 lalu 11x11) terlihat sejak 14 ubin sebelum titiknya (22 ubin setelah petunjuk dari lemparan tepat): bila badannya belum masuk layar, sebuah panah oranye kecil di bawah strip HUD atas menunjukkan arahnya. Hasil: kucing terbaca di skala x3 ya / tidak, kilau terlihat cukup lama (>= 2 detik pada ngebut) ya / tidak, kartu menutupi radar atau tombol ya / tidak.
3. [ ] **Petunjuk dari lemparan tepat.** Lempar koran TEPAT (inti kotak surat) ke pelanggan sesudah kucing sebelumnya. Diharapkan: gelembung "Tadi ada kucing lewat ke arah warung" 2,5 detik, "meong", kucing berikutnya tampil lebih awal. Lemparan mode bantu tidak memberi petunjuk. Hasil: terasa berguna dan tidak wajib ya / tidak.
4. [ ] **Menepi dan menangkap.** Dekati kucing ketiga, tarik stick bawah penuh sampai berhenti (rem) dalam 2 ubin dari kucing; tahan 1,5 detik. Diharapkan: bar hijau di atas kucing terisi, banner "Kucing ketemu! +75", koin HUD +75. Hasil: radius 2 ubin dan ambang 1,5 u/d adil ya / tidak (perlu lebih longgar?), perlu berapa percobaan: ___
5. [ ] **Mode bantu.** Nyalakan Bantu di layar jeda: stick tetap bisa menepi dan menangkap; kecepatan otomatis tidak menangkap sendiri. Hasil: ya / tidak.
6. [ ] **Gagal.** Lewati rumah seberang ke-12 tanpa menangkap. Diharapkan: banner "Kucingnya lolos hari ini" tanpa kata gagal, koin tidak berkurang, hari berjalan terus. Hasil: batas 12 rumah adil ya / tidak.
7. [ ] **Layar hasil dan hari berikutnya.** Selesai: baris "Misi: Kucing ketemu! +75 koin" (hijau) dan koin sudah termasuk hadiah; gagal: "Misi: Kucingnya lolos hari ini" (netral). "Hari berikutnya": koran hari 2 menampilkan "Kucing Bu Ratmi Sudah Pulang ke Rumah" (selesai) atau "Kucing Bu Ratmi Belum Ditemukan" (gagal, tanpa tombol) sekali; hari 3 tidak lagi. Hasil: ya / tidak.
8. [ ] **Lewati misi.** Lewati P1 di koran: rute tanpa kucing, tanpa kartu, tanpa baris rekap.
9. [ ] **Force stop di tengah rute dengan misi aktif** (bukan hapus data): buka lagi = hari sama, misi dari awal, save kemarin utuh.
10. [ ] **Bunyi.** Meong (petunjuk), mrik (kucing terlihat), nada selesai, dua nada turun lembut (gagal); semua ada pasangan visual. Hasil: terdengar jelas ya / tidak, mengganggu ya / tidak.

**Lembar hasil 8.10 (misi kucing dan tutorial, run 4B):**

```
Penguji: pemilik   Tanggal: ____   HP: vivo V2108 / A54 / lainnya: ____   Build (commit): ____   Save: baru / migrasi dari 4A
1. Tutorial: terbaca ya / tidak   mengganggu ya / tidak   Lewati pas ya / tidak
2. Kucing terbaca x3 ya / tidak   kilau cukup lama ya / tidak   kartu menutupi sesuatu ya / tidak
3. Petunjuk berguna dan tidak wajib: ya / tidak
4. Tangkap: radius 2 / 1,5 u/d / 1,5 detik adil ya / tidak   percobaan: ____   usul angka: ____
5. Mode bantu: stick menangkap ya / tidak   auto-tangkap tidak terjadi ya / tidak
6. Gagal: batas 12 rumah adil ya / tidak   banner tidak menyalahkan ya / tidak
7. Hasil dan lanjutan besok benar: ya / tidak
8. Lewati misi: ya / tidak
9. Force stop: misi dari awal, save utuh ya / tidak
10. Bunyi: ya / tidak
Catatan (teks, tata letak, angka yang ingin diubah dan alasannya): ____
```

### 8.11 Uji kondisi sepeda, bengkel, dan koin sebagai saldo (run `20261020-fase6a1-bengkel-kondisi`, belum diuji)

Penguji: pemilik sendiri (rule `testing`). Semua angka, tata letak, dan bunyi usulan (BALANCING 7 dan 8, DESIGN_SPEC 3.3 dan 4, SPEC run): catat angka yang ingin diubah beserta alasannya, jangan diubah di sesi uji. **Pasang tanpa menghapus apa pun** (`adb install -r builds/kring-kring-debug.apk`, hanya setelah izin pemilik; HP dipakai bersama project lain; izin pasang ke vivo V2108 sesudah QA PASS sudah tercatat). **Jangan uninstall.** Edit save lewat `run-as com.rmh.kring` lebih disukai daripada `pm clear` (izin pemilik 2026-10-18 untuk `pm clear` bila perlu): catat save mana yang dipakai. Save v2 dari 4B di vivo harus termigrasi otomatis ke v3 (butir 7). Bukti desktop: tangkapan `docs/loop/20261020-fase6a1-bengkel-kondisi/shots/iter1/` (`tests/probe_kondisi_jendela.gd`, `tests/probe_bengkel_jendela.gd`). Dari mesin: kondisi, aus, efek, harga, dan simpan sudah dites; yang dinilai di sini hanya rasa, keterbacaan, dan keadilan.

1. [ ] **Kerusakan terasa menghambat, bukan memblokir.** Mainkan beberapa rute dengan sepeda yang sengaja dibiarkan rusak (edit save: ban 0,2, rem 0,2, rantai 0,2 lewat `run-as`, atau ngebut dan menabrak sampai rusak). Diharapkan: rantai rusak membuat akselerasi lambat dan puncak tertahan (sekitar 3,6 u/d), ban rusak membuat belok kurang lincah, rem blong membuat berhenti lebih jauh (sampai sekitar 2,5 kali jarak normal); rute tetap bisa diselesaikan sebelum tenggat dengan santai terus, tanpa kebuntuan. Hasil: terasa menghambat tetapi tidak menyebalkan ya / tidak; rem blong berbahaya tetapi tidak membuat rute mustahil ya / tidak.
2. [ ] **Tanda peringatan terbaca.** Dengan komponen AUS (kondisi 0,35 sampai 0,69): rantai berisik dan ban mendesis saat melaju santai atau lebih cepat, rem berdecit saat mengerem; bersamaan ikon komponen di HUD bergetar dan kotak berwarna oranye (sekitar 1,2 detik). Diharapkan: peringatan muncul sebelum efek terasa, tidak lebih sering dari satu kali per 6 detik per komponen, dan bunyi lebih pelan dari bel dan tabrakan. Hasil: terbaca di HP ya / tidak; bunyi dan ikon berpasangan ya / tidak; terlalu sering atau mengganggu ya / tidak (perlu jeda lebih panjang? usul: ___); tanpa suara tetap terbaca dari ikon ya / tidak. Catatan QA-004: dengan ban dan rantai sama-sama AUS dan santai terus, dua bunyi berbunyi tiap sekitar 6 detik selama belasan rute; tombol penyetel pertama bila mengganggu = `KONDISI_PERINGATAN_JEDA_DETIK` di `scripts/config.gd` (usul 12 sampai 15 detik), lalu peringatan berhenti sesudah N kali per komponen per rute. Ban PERLU_BENGKEL menurunkan kecepatan santai di bawah 3,0 u/d sehingga tanda ban berhenti ("!" tetap tampil; QA-008).
3. [ ] **Kotak kondisi 5x5 dan ikon 14 px terbaca di x3.** Panel baris 2 kanan atas (di bawah koin dan skor): tiga komponen, tiga kotak masing-masing, "!" oranye bila perlu servis. Diharapkan: terbaca sekilas tanpa menutupi radar kanan, tombol bel, tombol jeda, atau kartu misi; kotak yang hilang berongga. Catatan QA-007: kotak berongga (`UI_PANEL_RAISED` di atas `UI_PANEL`) berkontras sekitar 1,14:1 sehingga hampir hilang; status terbaca dari jumlah kotak terisi dan "!", jadi nilai apakah "2 dari 3" dan "3 dari 3" masih terbedakan. Catatan QA-003: panel ini memotong bagian paling atas zona swipe tetapi tidak menangkap sentuhan (AC-22 dilonggarkan untuk zona swipe, usulan); nilai apakah jempol yang swipe menutupi panel atau swipe dari pojok atas terasa terganggu (bila ya: naikkan `ZONA_SWIPE_Y_MIN_PX` ke 68 atau pindahkan baris 2). Hasil di vivo V2108 / A54: kotak terbaca ya / tidak; "!" terbaca ya / tidak; panel mengganggu lempar (swipe dari area itu tetap melempar) ya / tidak.
4. [ ] **Layar hasil menyebut komponen yang perlu servis.** Baris oranye "Rantai perlu servis" (satu per komponen, hanya yang PERLU_BENGKEL), tanpa baris bila semua baik; angka koin tidak berubah karenanya; tombol "Ke bengkel" (bukan "Hari berikutnya"). Hasil: ya / tidak.
5. [ ] **Bengkel mudah dipakai dan mudah dilewati.** Saldo (koin hari itu ikut), tiga kartu servis (ikon, kotak, tingkat, harga, tombol "Servis" atau "Baik"), tiga upgrade (nama, deskripsi, harga, "Beli" atau "Dimiliki"), "Hari berikutnya" di kanan bawah selalu aktif; tombol yang tidak terjangkau berubah menjadi "Koin kurang" dan redup. Ketuk ganda cepat tidak membeli dua kali. Back Android di bengkel = "Hari berikutnya". Hasil: target sentuh nyaman ya / tidak; layar tidak membingungkan ya / tidak; "Hari berikutnya" mudah dijangkau jempol kanan ya / tidak; tidak ada iklan atau tempat iklan ya / tidak.
6. [ ] **Harga terasa adil.** Servis kira-kira setengah hari kerja untuk komponen yang parah (hari rapi 300 sampai 375 koin), upgrade sekitar 1,5 sampai 2 hari; ongkos naik bila dua atau tiga komponen rusak (x1,25 dan x1,5, tertulis di bengkel) terasa wajar, bukan hukuman. Hasil: harga servis adil ya / tidak (usul: ___); harga upgrade adil ya / tidak (usul: ___); ongkos naik wajar ya / tidak; laju aus (santai terus tahan belasan rute, ngebut dan sering mengerem rusak dalam sekitar 5 rute) terasa pas ya / tidak.
7. [ ] **Save v3: migrasi dari save 4B.** Buka app dengan save 4B di vivo (hari, koin, flag, `misi_hasil`, `tutorial` utuh). Diharapkan: koran hari yang sama, tanpa notifikasi save rusak; sesudah satu hari selesai, save v3 berisi `koin_total` = koin lama + pendapatan hari itu, `sepeda` dengan kondisi aus dari hari itu. Catat save yang dipakai (edit `run-as` atau save asli). Hasil: hari, koin, flag utuh ya / tidak; tidak ada kondisi atau upgrade gratis ya / tidak.
8. [ ] **Seminggu hari berturut-turut tanpa kebuntuan.** Mainkan tujuh hari (boleh ngebut sebisa mungkin, boleh membiarkan semua komponen rusak, boleh saldo kecil): setiap hari tetap bisa diselesaikan dan "Hari berikutnya" selalu bisa ditekan. Hasil: ya / tidak; hari yang terasa buntu atau tidak adil: ___.
9. [ ] **Bengkel dilewati.** Selesaikan beberapa hari hanya dengan "Ke bengkel" lalu "Hari berikutnya" tanpa membeli: sepeda tetap jalan dengan kondisi menurun, kondisi tersimpan ke hari berikutnya (HUD hari 2 melanjutkan dari kondisi kemarin). Hasil: ya / tidak.
10. [ ] **Force stop di layar hasil atau bengkel (bukan hapus data).** Tutup app di layar hasil atau di bengkel (sebelum "Hari berikutnya"): buka lagi = hari yang sama dari koran dengan save lama (pendapatan dan belanja hari itu tidak tersimpan, sesuai aturan simpan akhir hari); tidak ada korupsi save. Hasil: ya / tidak. (Konsekuensi ini dicatat jujur: pemain yang menutup app di bengkel kehilangan belanja hari itu.)
11. [ ] **Tidak ada penurunan performa.** HUD kondisi dan peringatan tidak membuat game tersendat di HP menengah (60 fps tetap). Hasil: ya / tidak.
12. [ ] **Background di bengkel tidak mematikan bengkel (QA-001).** Buka bengkel, tarik bayangan notifikasi atau ganti app lalu kembali. Diharapkan: tidak ada dialog JEDA di atas bengkel, tombol Servis, Beli, dan "Hari berikutnya" tetap bisa disentuh, tidak ada simpan sampai "Hari berikutnya". Di rute dan layar hasil background tetap membuka layar JEDA (tanpa lanjut otomatis). Hasil: ya / tidak.

**Lembar hasil 8.11 (kondisi sepeda, bengkel, koin saldo, run 6A1):**

```
Penguji: pemilik   Tanggal: ____   HP: vivo V2108 / A54 / lainnya: ____   Build (commit): ____   Save: baru / migrasi dari 4B / hasil edit run-as
1. Kerusakan menghambat bukan memblokir ya / tidak   rem blong berbahaya tapi bisa ya / tidak
2. Peringatan terbaca ya / tidak   bunyi + ikon berpasangan ya / tidak   terlalu sering ya / tidak   usul jeda: ____
3. Kotak 5x5 dan ikon 14 px terbaca ya / tidak   "!" terbaca ya / tidak   menutupi sesuatu ya / tidak
4. Baris kondisi di layar hasil benar: ya / tidak   "Ke bengkel" jelas ya / tidak
5. Bengkel: sentuh nyaman ya / tidak   tidak membingungkan ya / tidak   tombol hari berikutnya terjangkau ya / tidak   ketuk ganda aman ya / tidak
6. Harga servis adil ya / tidak (usul ____)   upgrade adil ya / tidak (usul ____)   ongkos naik wajar ya / tidak   laju aus pas ya / tidak
7. Migrasi 4B -> v3: hari/koin/flag utuh ya / tidak   tanpa upgrade atau kondisi gratis ya / tidak
8. Seminggu tanpa kebuntuan ya / tidak   hari bermasalah: ____
9. Bengkel dilewati, kondisi berlanjut ya / tidak
10. Force stop di hasil atau bengkel: hari diulang, save utuh ya / tidak
11. 60 fps tetap ya / tidak
12. Background di bengkel: tanpa dialog JEDA, bengkel tetap bisa disentuh ya / tidak
Catatan (teks, tata letak, angka yang ingin diubah dan alasannya): ____
```
