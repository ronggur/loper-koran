# SPEC — 20261014-fase1c-perapian

Run 1C Fase 1 (`DEV_PHASES.md` Fase 1, `LOOP-DEV-QA.md` 6b): **perapian temuan Minor/Nit Run 1B** yang ditunda di `docs/loop/20261014-fase1b-umpan-balik/LOG.md` (tabel Temuan dan Catatan QA iterasi 1): QA-001, QA-002, QA-003, QA-004, QA-006. Dokumen ini kontrak untuk Dev **dan** QA. Prosedur penuh di `docs/LOOP-DEV-QA.md` (maksimal 2 iterasi). Branch `fix/fase1c-perapian` dari `main` 7acbef7 (memuat PR #21).

## Tujuan

Menutup utang kecil Run 1B tanpa mengubah rasa permainan: empat cabang pertahanan diberi tes dengan mutan nyata (QA-001), gambar tombol jeda tidak tertahan "ditekan" sesudah lanjut (QA-002), probe jendela keluar tanpa `ERROR`/`WARNING` (QA-003), berkas probe render tidak ikut APK normal (QA-004), dan debu roda tertinggal di jalan (ruang dunia) saat sepeda pindah sisi (QA-006). Fase 1 tetap **tidak** dicentang selesai.

## Keputusan dari pemilik (dengan tanggal)

- **2026-10-14, hasil uji HP 8.2: belum ada.** Kolom hasil uji di perintah run masih berisi template, jadi dianggap belum diuji. Akibatnya **tidak ada angka penyetelan yang diubah**: `KAMERA_SEPEDA_Y_PECAHAN`, `DORONGAN_*`, ukuran tombol, `HudLabel`, radius stick, ambang rem, angka `BikeMotion`/stamina tetap. QA-005 Run 1B (jarak 1 px sepeda ke panel saat mundur penuh; sprite masuk zona stick di 16:9) dan QA-005 Run 1A (melambat paling pelan 1,65 lawan 1,5 u/d) **tetap NEEDS-MANUAL**, tidak diputuskan di run ini.
- **2026-10-14, QA-004 dikerjakan** (pemilik memasukkannya ke scope; dulu "keputusan pemilik di PR"): berkas probe render dikecualikan dari APK normal lewat `exclude_filter` preset, dan `tools/ekspor_cek_render.py` melepas pengecualian itu sementara untuk build probe.
- Dikunci dari run sebelumnya (jangan ditanyakan ulang): Godot 4.7.2, base 640×360 ×3, stretch `canvas_items` + integer + `expand`, `com.rmh.kring`, export tanpa Gradle, jeda tanpa lanjut otomatis (2026-10-14), partikel `PancaranPiksel` digambar sendiri (D-2 Run 1B).
- Izin HP: orchestrator boleh memasang APK ke vivo V2108 (`adb` 12d8c9da) sesudah QA PASS; A54 (`RRCWA05E2NN`) hanya bila tersambung. **Dev dan QA tidak menyentuh HP.** Tidak ada `pm clear`/uninstall/`logcat -c`.

Status **usulan** (jangan ditulis "dikunci"): D-1 sampai D-5 di bawah, dan tampilan debu baru.

### Keputusan orchestrator (bisa ditolak di review PR)

- **D-1. QA-001: satu cek scene per cabang, dengan mutan nyata.** Empat cabang yang hidup di mutan QA Run 1B (Q01-Q04, LOG Run 1B baris QA-001 dan bagian "Mutan QA") diberi tes yang **gagal** pada mutannya:
  - **Q01** `JalanUji._terapkan_jeda`: `_kontrol.atur_rem(false)` saat menjeda. Tes: rem aktif (cincin rem menyala), lalu jeda (tombol, `FOCUS_OUT`, atau back) → cincin rem padam selama jeda dan tetap padam sesudah lanjut sampai rem ditahan ulang.
  - **Q02** `Audio._notification`: pemutar berhenti pada `NOTIFICATION_APPLICATION_PAUSED` dan `NOTIFICATION_APPLICATION_FOCUS_OUT` **lewat jalurnya sendiri**, tanpa `JalanUji`/sinyal `jeda_berubah`. Tes: instans `Audio` (dari `load(...).new()`, ditambahkan sementara ke pohon tes bila perlu agar pemutar bisa `playing`; atau autoload yang ada dengan `putar_di_driver_dummy`) sedang memutar loop, lalu `propagate_notification(PAUSED)` → tidak ada pemutar yang `playing`; ulangi untuk `FOCUS_OUT`. Masing-masing notifikasi dites terpisah (mutan yang menghapus salah satu harus mati).
  - **Q03** `TombolSentuh._notification`: jari yang turun di tombol lalu `NOTIFICATION_PAUSED` (dan, terpisah, `NOTIFICATION_VISIBILITY_CHANGED` karena disembunyikan) lalu naik di dalam tombol → **tidak** memicu `ditekan`.
  - **Q04** `TombolSentuh._input`: jari turun di dalam tombol, naik dengan `canceled = true` di dalam tombol → **tidak** memicu `ditekan`.
  Tes ditaruh di berkas tes scene yang sudah ada (`tests/tes_jeda_scene.gd`, `tests/tes_bunyi.gd`) atau berkas baru yang didaftarkan di `run_tests.gd`. Tidak ada perubahan perilaku produksi untuk QA-001 kecuali dibutuhkan agar bisa dites (catat alasannya).
- **D-2. QA-002: status tekan tombol jeda dilepas saat jeda/lanjut.** Saat `NOTIFICATION_PAUSED` atau `NOTIFICATION_UNPAUSED` (atau saat tombol disembunyikan), `TombolJeda` (atau `TombolSentuh`, Dev memilih letak yang paling umum) melepas status tekan bawaan `Button` dan menggambar ulang, supaya sesudah lanjut gambarnya `HUD_PANEL`, bukan `UI_PANEL_RAISED`. Mekanisme dipilih Dev (mis. status tekan sendiri untuk gambar, atau melepas `button_pressed`/emulasi mouse dengan aman) asal ketukan normal tetap memicu tepat sekali dan klik mouse editor tetap jalan. Tes regresi = skenario reproduksi QA Run 1B: jari 1 turun di pusat tombol jeda (`Input.parse_input_event`, jendela/viewport sesuai tes yang ada), `propagate_notification(FOCUS_OUT)`, jari 1 naik `canceled`, `FOCUS_IN`, `minta_lanjut()` → gambar tidak dalam keadaan ditekan (`is_pressed()` false, atau penanda status gambar yang dipakai `_draw` = normal). Plus: ketukan biasa sesudahnya tetap menjeda tepat sekali.
- **D-3. QA-003: probe keluar bersih.** Setiap `tests/probe_*.gd` yang memuat `jalan_uji.tscn` (atau apa pun yang memutar `Audio`) memanggil penghentian audio yang sama dengan runner tes (`Audio.hentikan_sepeda()` lewat `get_root().get_node_or_null("Audio")` atau setara, lalu beberapa frame jeda singkat) sebelum `quit()`, **di semua jalur keluar** (sukses dan gagal). Lebih disukai satu pembantu bersama (mis. fungsi statis di berkas pembantu `tests/`) daripada salinan di tiap probe. Bila penyebab baris `ERROR`/`WARNING` ternyata bukan (hanya) audio, Dev mencari penyebabnya (`--verbose`) dan mencatatnya.
- **D-4. QA-004: probe render tidak ikut APK normal.**
  - `export_presets.cfg` preset `Android`: `exclude_filter` ditambah berkas probe saja: `scenes/dev/cek_render.tscn`, `scripts/dev/cek_render.gd` (atau `scripts/dev/*`), `assets/shaders/warna_bayangan.gdshader` — **hanya bila** berkas itu tidak dipakai oleh scene game normal (Dev membuktikan dengan grep + isi paket). Token warna di `palette.gd` tidak dihapus. Tidak ada opsi preset lain yang berubah.
  - `tools/ekspor_cek_render.py`: selain mengganti `run/main_scene` sementara, melepas pola probe dari `exclude_filter` sementara, lalu **memulihkan `project.godot` dan `export_presets.cfg` byte demi byte** (juga bila Godot gagal atau diinterupsi: `try/finally`). Memeriksa bahwa hasilnya memuat berkas probe dan menunjuk ke probe; mencetak status pulih kedua berkas; exit 1 bila salah satu tidak pulih. Tetap hanya stdlib.
  - `tests/tes_export.gd`: menjaga bahwa `exclude_filter` preset memuat pola probe, dan bahwa pola itu cocok dengan nama di `tools/ekspor_cek_render.py` (cek teks, supaya keduanya tidak berpisah diam-diam).
  - Bukti perintah (ditulis di LOG): `--export-pack "Android"` normal **tidak** memuat `cek_render` maupun shader probe dan scene utamanya `jalan_uji.tscn`; `python3 tools/ekspor_cek_render.py --pck <berkas>` lolos, paketnya **memuat** probe, dan sesudahnya `git status --porcelain` kosong.
  - `docs/SETUP_ANDROID.md` (bagian probe render, 6/6.1) diperbarui: build normal tidak memuat probe; build probe hanya lewat skrip.
- **D-5. QA-006: debu roda di ruang dunia.** Partikel debu, sesudah dipancarkan, **tidak lagi ikut bergeser bersama sepeda** (lateral, maju, atau geseran dorongan kamera): ia diam di jalan pada posisi dunia saat dipancarkan (bergerak hanya karena gerak partikel itu sendiri bila ada), sehingga tertinggal di belakang saat sepeda maju dan tertinggal di sisi lama saat pindah sisi. Cara dipilih Dev (mis. `PancaranPiksel` dengan opsi ruang dunia yang menyimpan posisi global dan menggambar dengan `top_level`/transform terbalik, atau node debu dipindah ke lapisan dunia di bawah `JalanUji`), asal:
  - Titik muncul tetap di roda belakang (asal `Config.UMPAN_DEBU_ASAL_*` relatif sepeda saat muncul), warna `Palette.TEXT_2` + `Config.UMPAN_DEBU_ALPHA`, posisi gambar tetap dibulatkan ke piksel game, batas `Config.UMPAN_DEBU_BATAS`, tanpa alokasi per frame, deterministik (`RandomNumberGenerator` bernih tetap), berhenti saat jeda.
  - Urutan gambar: debu tetap di belakang sprite pemain (tidak menutupi pengendara).
  - Laju dan kecepatan gerak debu sendiri boleh disetel ulang agar jejaknya terbaca (angka baru/berubah lewat `Config` + `BALANCING.md` 2/10 sebagai usulan, alasan "QA-006, debu di ruang dunia"); bila tidak perlu diubah, jangan diubah.
  - **Garis kecepatan tetap di ruang lokal sepeda** (efek kamera; bagian kedua QA-006, garis di belakang sprite, dicatat saja, tidak diubah).
  - Placeholder tetap; pengganti final `vfx_debu_roda.png` di fase aset.

## Di luar scope

- Semua angka penyetelan uji HP (lihat keputusan pemilik), QA-005 Run 1A dan 1B.
- Fitur baru, HUD baru, pengaturan, mode bantu, audio baru, aset unduhan.
- Menjalankan apa pun di HP (orchestrator saja). Mengedit `DEV_PHASES.md` dan `ROADMAP.md` (orchestrator).
- Mengubah perilaku jeda (D-6 Run 1B) selain QA-002.

## Kriteria penerimaan (bisa diuji)

Perintah dari root repo, `godot` = 4.7.2. Semua tes lama tetap hijau; tes lama yang memang harus berubah (mis. tes scene debu yang mengandaikan ruang lokal) dicatat di LOG beserta alasannya.

- **AC-1 (gerbang):** `godot --headless --import` bersih (0 `ERROR`/`SCRIPT ERROR`/`WARNING`); di klon bersih `git status --porcelain` kosong sesudahnya. `run_tests.gd` lalu `tools/cek_keluaran_tes.py --ketat` exit 0. `tools/tests_cek/uji_pemeriksa.py`, `uji_bangun_frames.py`, `uji_sintesis_sepeda.py` lolos. `godot --headless --path . --quit-after 2` tanpa `ERROR`/`WARNING`. Tidak ada keystore/APK/`.godot/`/`build/`/`builds/`/`override.cfg` di diff.
- **AC-2 (QA-001, D-1):** ada tes untuk Q01-Q04 (Q02 dua tes: PAUSED dan FOCUS_OUT). Dev menjalankan keempat mutan QA Run 1B (dan mutan Q02 per notifikasi) dan menunjukkan masing-masing kini **mati** (tes mana yang gagal), lalu memulihkan kode. Dicatat di LOG.
- **AC-3 (QA-002, D-2):** tes regresi skenario reproduksi QA Run 1B lolos; mutan "pelepasan status tekan dihapus" mati. Ketukan sentuhan biasa dan `pressed.emit()` tetap menjeda tepat sekali (tes lama tetap hijau).
- **AC-4 (QA-003, D-3):** di jendela asli, `godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_umpan_balik_jendela.gd -- <folder sementara di luar repo atau build/>` keluar exit 0 tanpa baris `ERROR`/`WARNING` (termasuk `ObjectDB instances were leaked` dan `resources still in use`); sama untuk setiap probe lain yang memuat `jalan_uji.tscn` (Dev mendaftar probe mana saja dan menjalankan masing-masing sekali; keluaran ringkas di LOG). Jalur gagal probe juga menghentikan audio (cek kode).
- **AC-5 (QA-004, D-4):** `tes_export.gd` menjaga pola probe di `exclude_filter` dan kecocokannya dengan `ekspor_cek_render.py`. `--export-pack "Android" build/<x>.pck` normal tidak memuat `cek_render` (scene, skrip, `.remap`) maupun `warna_bayangan.gdshader`, dan memuat `jalan_uji`. `python3 tools/ekspor_cek_render.py --pck build/<y>.pck` exit 0, paketnya memuat probe dan menunjuk ke probe, `project.godot` dan `export_presets.cfg` pulih byte demi byte, `git status --porcelain` kosong sesudahnya. Pemulihan juga terjadi saat Godot gagal (dibuktikan dengan kode `try/finally` dan, bila mudah, satu percobaan dengan jalur Godot salah). Mutan: hapus pola dari preset → `tes_export` gagal.
- **AC-6 (QA-006, D-5):** tes scene pada `jalan_uji.tscn` (atau scene uji yang setara): setelah debu dipancarkan, (a) mengubah lateral sepeda (pindah sisi) dan (b) memajukan sepeda/kamera **tidak** menggeser posisi global partikel yang sudah ada sebesar gerak sepeda (hanya gerak partikel sendiri, bila ada); (c) partikel baru muncul di dekat roda belakang posisi sepeda saat itu; (d) jumlah ≤ `UMPAN_DEBU_BATAS`, debu tetap 0 di bawah ambang, debu rem tetap muncul saat rem, partikel berhenti saat jeda; (e) debu digambar di belakang sprite pemain. Mutan: kembalikan ke ruang lokal → tes (a) atau (b) gagal. Garis kecepatan tetap lolos tes lamanya.
- **AC-7 (bukti visual):** dengan `tests/probe_umpan_balik_jendela.gd` (diperluas bila perlu dengan skenario pindah sisi sambil ngebut) di jendela asli 2340×1080, tangkapan layar ke `docs/loop/20261014-fase1c-perapian/shots/`: ngebut (debu + garis) dan pindah sisi (jejak debu tertinggal di sisi lama). `tools/cek_blok_piksel.py 3` lolos untuk tangkapan itu (di luar teks HUD).
- **AC-8 (aturan kode):** tab, static typing, `##` bahasa Indonesia, tidak ada angka tuning di luar `Config` (satu baris, literal; `ConfigParser`/tes config menerima konstanta baru bila ada), tidak ada hex di luar `palette.gd`, logika murni tetap di `scripts/systems/`, node tipis, tidak ada `kiri`/`kanan` untuk sisi jalan, tidak ada alokasi per frame di `_process`.
- **AC-9 (dokumen, di commit yang sama dengan perubahannya):** `SETUP_ANDROID.md` 6/6.1 (probe tidak ikut APK normal); `BALANCING.md` 2/10 hanya bila angka debu berubah; `ART_DIRECTION.md` atau dokumen umpan balik terkait bila menyebut debu di ruang lokal; `AGENTS.md` dan `.cursor/rules/00-project-core.mdc` bila perintah atau peta repo berubah (mis. berkas pembantu probe baru). `DEV_PHASES.md` dan `ROADMAP.md` **tidak** diedit Dev.
- **AC-10 (git):** commit kecil `<tipe>: <ringkasan>` bahasa Indonesia di `fix/fase1c-perapian`, tidak ada commit di `main`, **tidak ada push**. Tiap commit hijau sendiri (import + `run_tests` + pemeriksa).

## Perubahan file/struktur yang diharapkan

```
tests/tes_jeda_scene.gd, tests/tes_bunyi.gd, tests/tes_umpan_balik.gd (atau berkas baru + run_tests.gd)   QA-001, QA-002, QA-006
scripts/ui/tombol_jeda.gd dan/atau scripts/ui/tombol_sentuh.gd                                          QA-002
tests/probe_*_jendela.gd (+ pembantu bersama bila dibuat)                                                QA-003
export_presets.cfg, tools/ekspor_cek_render.py, tests/tes_export.gd, docs/SETUP_ANDROID.md               QA-004
scripts/entities/pancaran_piksel.gd, umpan_balik_sepeda.gd, sepeda_uji.gd/jalan_uji.gd, scenes terkait   QA-006
scripts/config.gd + docs/BALANCING.md (hanya bila angka debu berubah)
docs/loop/20261014-fase1c-perapian/LOG.md, shots/
```

## Tes yang harus ada

Q01-Q04 (Q02 per notifikasi) dengan mutan mati; regresi QA-002; penjaga pola probe di preset dan kecocokannya dengan skrip; debu ruang dunia (pindah sisi, maju, muncul di roda, batas, jeda, urutan gambar).

## Butuh uji perangkat nyata (NEEDS-MANUAL)

Orchestrator sesudah QA PASS: pasang APK debug normal ke vivo V2108 (cek layar menyala dan tidak dipakai), periksa isi APK tidak memuat probe (`unzip -l`/`aapt2`), tangkapan layar. Pemilik dan 3-5 penguji (`SETUP_ANDROID.md` 8.2), tetap terbuka dari Run 1B:
- QA-002: tahan jempol di tombol jeda, tekan home, kembali, ketuk "Lanjut": ikon jeda tampil normal.
- QA-006: jejak debu tertinggal di jalan saat pindah sisi dan terbaca, tidak mengganggu.
- QA-001 Q04: swipe gesture navigasi sistem di atas tombol jeda tidak memicu jeda/lanjut.
- Semua butir 8.2 lain (ambang rem, posisi sepeda/dorongan, tombol, teks HUD, bunyi, QA-005 Run 1A/1B) dan kriteria "Selesai kalau" Fase 1.

## Dokumen yang ikut diperbarui

Dev: AC-9. Orchestrator: sesudah PR, `DEV_PHASES.md` hanya bila ada butir yang terbukti selesai (butir Fase 1 yang tersisa semuanya menunggu uji HP, jadi kemungkinan tidak ada yang dicentang).
