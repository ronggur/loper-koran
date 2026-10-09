# Setup Android: APK debug dan uji di HP

Panduan membangun APK debug **Kring Kring!** (`com.rmh.kring`) dari CLI, memeriksa isinya, memasangnya ke HP Android, dan checklist uji M0. Diadaptasi dari panduan Brainy Dungeon (hanya polanya), lalu ditulis ulang untuk repo ini berdasarkan perintah yang benar-benar dijalankan di mesin pengembang pada 2026-10-09. Tanpa Gradle, tanpa plugin Android, tanpa keystore rilis (belum ada, Fase 14).

Label **usulan** berarti belum dikunci (rule `docs`). Nilai preset di bagian 3 adalah usulan SPEC run `20261009-fase0bc-input-export` (D-8), bukan keputusan pemilik. Kolom "Terverifikasi" membedakan yang sudah dijalankan dari yang belum.

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
| **`export/android/java_sdk_path`** | ⬜ **Kosong** | Ekspor ditolak: `A valid Java SDK path is required in Editor Settings.` Variabel lingkungan `JAVA_HOME` **tidak** menggantikannya di Godot 4.7.2 (dicoba 2026-10-09, pesan sama) | bagian 2 |
| Debug keystore | ⬜ | `~/Library/Application Support/Godot/keystores/debug.keystore` belum ada. Godot membuatnya sendiri (lewat `keytool` dari JDK di atas) pada ekspor debug pertama; ini perilaku standar dan berada di luar repo | `ls "$HOME/Library/Application Support/Godot/keystores/"` |
| `aapt2`, `apksigner`, `apkanalyzer` | ✅ | `~/Library/Android/sdk/build-tools/<versi>/aapt2` dan `apksigner`; `~/Library/Android/sdk/cmdline-tools/latest/bin/apkanalyzer` | `aapt2 version` |

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

Ini pengaturan mesin, bukan bagian repo: jangan di-commit dan agent tidak mengubahnya tanpa izin pemilik. Setelah terisi, ekspor debug pertama membuat debug keystore otomatis.

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
| `screen/immersive_mode` | `true` | Menyembunyikan bilah sistem supaya tinggi jendela 1080 dan skala tetap ×3 (ROADMAP 4b, risiko ×2) |
| `screen/edge_to_edge` | `false` (bawaan Godot) | **Belum diuji di HP.** Bila bilah sistem atau cutout memakan layar atau skala turun ke ×2, ini opsi pertama yang dicoba |
| `user_data_backup/allow` (`android:allowBackup`) | `false` | **Usulan.** Belum ada save yang layak dicadangkan (SaveManager belum ada). Tinjau ulang di Fase 6 bersama keputusan save dan privasi (`privacy-ads`, `save-system`) |
| `permissions/*` | semua `false`, `custom_permissions` kosong | Tanpa izin kustom. Daftar penuh izin Godot ditulis eksplisit supaya penyimpangan terlihat di diff |
| `keystore/debug*`, `keystore/release*` | kosong | Debug keystore diurus Godot lewat Editor Settings; keystore rilis di luar folder project dan tidak pernah di-commit |
| `package/signed` | `true` | APK ditandatangani dengan debug keystore |
| `exclude_filter` | `docs/*, tests/*, tools/*, build/*, builds/*` | Skrip tes (`tests/*.gd`) ikut ke APK kalau tidak dikecualikan; `docs/` sudah diabaikan lewat `docs/.gdignore` |
| `export_filter` | `all_resources` | Semua resource yang dikenal Godot; `.json` data konten juga ikut (terbukti: `assets/sprites/loper/loper_agen.json` masuk paket) |
| `script_export_mode` | `2` (terkompresi) | Hanya memadatkan skrip, **bukan** perlindungan: isi APK tetap bisa dibongkar |
| `package/name` | kosong | Label app = nama project, `Kring Kring!` |
| Ikon (`launcher_icons/*`) | kosong | Belum ada ikon project (`application/config/icon`); ikon sementara dan final bukan scope Fase 0 (Fase 14). Launcher menampilkan ikon bawaan template |

### Nilai dari template 4.7.2 (terverifikasi pada `android_debug.apk` bawaan, 2026-10-09)

Dengan build tanpa Gradle, nilai ini tidak bisa diubah dari preset:

| Hal | Nilai template | Perintah |
|---|---|---|
| `minSdkVersion` | **24** (Android 7.0) | `aapt2 dump badging` pada `android_debug.apk` |
| `targetSdkVersion` | **36** (Android 16), `compileSdkVersion` 36 | idem |
| `allowBackup` bawaan template | `false` (Godot menulis ulang sesuai `user_data_backup/allow`) | `aapt2 dump xmltree --file AndroidManifest.xml` |
| Orientasi activity | `screenOrientation=0` (landscape terkunci, bukan sensor); Godot menulis ulang dari `display/window/handheld/orientation` | idem |
| Activity peluncur | alias `com.godot.game.GodotAppLauncher` → `com.godot.game.GodotApp` (`exported=true` hanya untuk alias) | idem |
| Izin | tidak ada di template; Godot menambahkan sesuai preset (dan mungkin `INTERNET` untuk debugger jarak jauh) | `aapt2 dump permissions` |
| Template tidak bertanda tangan | `apksigner verify` pada template: `Missing META-INF/MANIFEST.MF` (wajar; tanda tangan dibuat saat ekspor) | `apksigner verify` |

Nilai **APK hasil ekspor** (package, versionCode, minSdk, izin akhir, tanda tangan) baru valid setelah ekspor pertama berhasil; lihat bagian 5.

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
- Ekspor pertama membuat debug keystore di `~/Library/Application Support/Godot/keystores/` lewat `keytool`.
- Karena preset `runnable`, Godot memanggil `adb` sendiri, juga pada mode headless dan `--export-pack` (terlihat dari pesan `cannot connect to daemon at tcp:5037: Connection refused` di akhir keluaran, kemungkinan `adb kill-server` saat keluar tanpa server berjalan). Itu bukan perintah dari kita, dan Godot dapat mencacah perangkat yang tersambung; ekspor tidak memasang apa pun ke HP.
- Keluaran harus bebas `ERROR:` dan `WARNING:`. Catat sisanya.

### Memeriksa isi paket game tanpa Java (terverifikasi 2026-10-09)

`--export-pack` memakai preset dan filter yang sama tetapi tidak butuh Java:

```bash
godot --headless --path . --export-pack "Android" build/kring-uji.pck 2>&1 | grep "Storing File"
```

Hasil saat ditulis (2026-10-09): 78 entri, 212 KB; tidak ada `tests/`, `tools/`, `docs/`, atau `build/`. Tanpa `exclude_filter` paketnya 90 entri (310 KB) dan memuat 12 entri `tests/*.gd`; jadi filter itu bekerja.

## 5. Memeriksa isi APK

Setelah ekspor berhasil. `AAPT2` dan `APKSIGNER` ada di folder `build-tools` yang sama.

```bash
BT=~/Library/Android/sdk/build-tools/36.0.0
APK=builds/kring-kring-debug.apk
$BT/aapt2 dump badging $APK | grep -E "^(package|sdkVersion|minSdkVersion|targetSdkVersion|native-code|launchable-activity|supports-screens|uses-permission)"
$BT/aapt2 dump xmltree --file AndroidManifest.xml $APK | grep -E "screenOrientation|allowBackup|debuggable|resizeableActivity|minSdkVersion|targetSdkVersion"
$BT/aapt2 dump permissions $APK
$BT/apksigner verify --verbose --print-certs $APK
unzip -l $APK | grep -E "assets/|lib/|classes|AndroidManifest" | head -20
~/Library/Android/sdk/cmdline-tools/latest/bin/apkanalyzer manifest print $APK | head -60   # alternatif aapt2 xmltree
```

Yang diharapkan (diverifikasi pada APK nyata, bukan hanya template):

| Hal | Diharapkan |
|---|---|
| `package: name=` | `com.rmh.kring`, `versionCode='1'`, `versionName='0.1.0'` |
| `minSdkVersion` | `24` (dari template; build tanpa Gradle) |
| `targetSdkVersion` | `36` (dari template) |
| `native-code` | `'arm64-v8a'` saja |
| Orientasi | `screenOrientation=0` (landscape) |
| `allowBackup` | `false` |
| Izin | tanpa izin pelacakan (`AD_ID`, lokasi, dst.). Godot menambahkan `INTERNET` hanya untuk debugger jarak jauh; catat apa adanya, dan **tinjau ulang di build rilis** (`privacy-ads`) |
| `apksigner verify` | `Verifies` dengan sertifikat debug Godot (`CN=Godot, OU=Godot Engine, O=Stichting Godot, C=NL`, dari argumen `keytool` di Godot) |
| `unzip -l` | `assets/` berisi paket game (di Godot 4.7: `assets/assets.sparsepck`), `lib/arm64-v8a/` saja, `AndroidManifest.xml`; ukuran APK jauh di bawah 100 MB (TECH_PLAN 3.7) |

### Target API 36 dan syarat rilis

Google Play mewajibkan app baru dan update menargetkan Android 16 (API 36) mulai 31 Agustus 2026 (TECH_PLAN Fase 0). Template 4.7.2 menargetkan **36**, jadi APK debug tanpa Gradle memenuhi syarat target. Syarat rilis yang belum dikerjakan (bukan penghalang APK debug):

- **AAB**: Play Console menerima AAB untuk app baru; ekspor AAB (`gradle_build/export_format=1`) hanya valid dengan **Use Gradle Build** menyala. Gradle build baru dipasang saat plugin Android masuk (Fase 8 dan 14), lalu folder `android/` perlu aturan `.gitignore` sendiri.
- Keystore rilis di luar folder project, kata sandi tidak di-commit.
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
| `cannot connect to daemon at tcp:5037` di akhir ekspor | Godot mematikan server adb saat keluar; tidak berbahaya (bagian 4) |
| `No export template found` | Export templates 4.7.2 belum terpasang atau nama folder tidak sama dengan `version.txt` (bagian 1) |
| Ekspor mengeluh soal keystore atau `keytool` | Java SDK Path salah atau bukan JDK (butuh `bin/keytool`); debug keystore dibuat otomatis (bagian 2) |
| `adb devices` menampilkan `unauthorized` (umum) | Izinkan USB debugging di layar HP; kalau dialog tidak muncul, cabut otorisasi di Opsi pengembang lalu colok ulang |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` (umum) | APK lama ditandatangani keystore lain. Cek `pm list packages` dulu, lalu `adb uninstall com.rmh.kring` hanya dengan izin pemilik (save ikut terhapus) |
| App langsung tertutup (umum) | Lihat penyebabnya dengan `adb logcat -s godot` |
| Dialog sistem "Viewing full screen" saat pertama dibuka (umum) | Dialog Android untuk mode imersif; tekan "Got it", muncul sekali |
| Skala turun ke ×2 atau ada tepi kosong di HP | Bilah sistem tidak tersembunyi; lihat bagian 6 dan ROADMAP 4b |
| Tes ekspor `tests/tes_export.gd` gagal | Ada perubahan di `export_presets.cfg` atau `.gitignore` yang melanggar bagian 3; baca pesan `GAGAL` |

## 8. Checklist uji HP (menutup Fase 0 dan M0)

Dikerjakan manusia di HP asli; agent tidak bisa menilai rasa kontrol. Fase 0 **tidak dicentang** sebelum butir inti selesai (`DEV_PHASES.md`). Catat angka yang ingin diubah, jangan mengubahnya di run ini.

**Inti M0**

- [ ] APK terpasang dan app terbuka dalam landscape; tidak ada crash di `adb logcat -s godot`.
- [ ] Stick muncul di bawah jempol kiri, sepeda bergerak naik ke kanan atas. Atas: ngebut (sprite berdiri). Netral: santai. Bawah: melambat. Kiri/kanan: sprite serong atau 90° dan sepeda bergeser. Tidak ada animasi yang berkedip di sekitar batas sudut 22,5°.
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
- [ ] Orientasi terkunci: memutar HP 180° tidak membalik tampilan atau menjadikannya portrait (`screenOrientation=0`, bukan sensor).
- [ ] Ikon di launcher: kemungkinan ikon bawaan Godot (belum ada ikon project); catat, tidak diperbaiki di run ini.
- [ ] Opsional: sambungkan keyboard fisik; panah dan WASD **tidak** boleh menggerakkan sepeda di APK (keyboard hanya untuk editor, `OS.has_feature("editor")`).
- [ ] Tetap terbuka dan bukan bagian checklist ini: uji light 2D, glow, partikel, dan shader di Compatibility (DEV_PHASES Fase 0).
