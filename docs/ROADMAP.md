# Roadmap — Loper Koran

Status per **9 Oktober 2026**. Dokumen ini mencatat kesiapan sebelum produksi, milestone sampai rilis, dan keputusan yang masih terbuka. Rincian kerja per fase ada di [`DEV_PHASES.md`](./DEV_PHASES.md).

Status: ⬜ belum mulai · 🟡 sedang dikerjakan · ✅ selesai

## 1. Sebelum mulai coding

| # | Kebutuhan | Status | Di mana |
|---|---|---|---|
| 1 | Desain inti: core loop, kontrol, kamera, distrik, misi, sepeda, ekonomi | ✅ Dikunci 2026-10-05/06. Kontrol masih harus diuji di HP. `GDD.md` jadi sumber utama sejak 2026-10-07. | `GDD.md` |
| 2 | Arah visual dan karakter pemain | ✅ Pixel art isometrik (2026-10-06), Kemeja Agen dikunci untuk produksi (2026-10-07). | `ART_DIRECTION.md` 2–3 |
| 3 | Sprite produksi pemain | ✅ 15 animasi kayuh (3 kecepatan × 5 arah), SpriteFrames Godot dicek memuat di Godot 4.3 (2026-10-07) dan di 4.7.2 tanpa perubahan (2026-10-09, run 0A). | `design/character/loper_agen/` |
| 4 | Art bible: aturan pixel art, palet, ukuran, penamaan | 🟡 Ditulis 2026-10-07. Palet induk dan ukuran ubin masih usulan sampai aset gelombang 1. | `ART_DIRECTION.md` |
| 5 | Angka tuning awal | 🟡 Usulan awal ditulis 2026-10-07, disetel lewat prototype. | `BALANCING.md` |
| 6 | Format data (misi, headline, segmen rute, save) | 🟡 Usulan ditulis 2026-10-07, dikunci saat Fase 3–4. | `DATA_SCHEMA.md` |
| 7 | Project Godot, export Android, panduan setup HP | 🟡 Project Godot (run 0A), input touch dan sepeda placeholder (run 0B), preset export + APK debug + panduan `SETUP_ANDROID.md` (run 0C) ada dan lolos QA 2026-10-09; APK terpasang di A54. Menunggu uji di HP dan cek light 2D/glow/partikel (Fase 0). | `DEV_PHASES.md` Fase 0, `SETUP_ANDROID.md` |

## 2. Sebelum game penuh

| # | Kebutuhan | Status |
|---|---|---|
| 8 | Panduan menyusun rute dan segmen | 🟡 Usulan ditulis 2026-10-07 (`ROUTE_DESIGN.md`), diuji di Fase 3. |
| 9 | Panduan menulis headline dan misi | 🟡 Ditulis 2026-10-07 (`CONTENT_GUIDE.md`). Contoh headline hari 1–3 belum dibuat. |
| 10 | Desain layar di luar rute: halaman depan koran, hasil harian, bengkel | ⬜ HUD rute sudah ada di mock; tiga layar ini belum didesain (`design/DESIGN_SPEC.md` 4). |
| 11 | Cerita besar dan kondisi gagal | 🟡 Premis dan alur diputuskan 2026-10-07, bab dan akhir masih usulan (`STORY.md`). Usulan: tanpa game over, tenggat terlewat berakhir di "tunda setahun". |
| 12 | Audio | ⬜ Draf prinsip dan daftar suara (`SOUND_DESIGN.md`); musik belum diputuskan. |
| 13 | Target usia dan pasar, kebijakan privasi, Data Safety | ⬜ Belum diputuskan. Menentukan aturan iklan dan konten. |
| 14 | Integrasi iklan hadiah (AdMob atau sejenisnya) | ⬜ Plugin perlu dicek lebih awal (GDD 16). |

## 3. Bisa menyusul

- Mode roguelite (GDD 11).
- Distrik pasar, desa, dan pinggir sungai (masih usulan awal, GDD 9.2).
- Tipe sepeda lain dan kosmetik dari varian baju pemain (GDD 11).
- Kejadian musiman (17 Agustus, Ramadan, hajatan).

## 4. Milestone (usulan)

Milestone mengikuti urutan prototype di GDD 17. Rinciannya jadi fase dengan checklist di `DEV_PHASES.md`.

| Milestone | Isi | Selesai kalau |
|---|---|---|
| **M0 — Fondasi teknis** | Repo, project Godot landscape, skala piksel bulat, input touch (stick + swipe), sprite pemain terpasang, export APK. | APK terpasang di HP, sepeda placeholder bisa digerakkan dengan stick di HP. |
| **M1 — Terasa enak di HP** | Prototype 1 dan 2: gerak sepeda dengan 3 kecepatan, stamina, rem, pindah sisi; lemparan yang mewarisi kecepatan dengan garis bidik. | Mengayuh dan melempar terasa enak di HP asli menurut 3–5 orang yang mencoba, dan dua pertanyaan kontrol di GDD 17 terjawab. |
| **M2 — Satu hari penuh** | Prototype 3 dan 4: satu rute perumahan dari segmen, 25 pelanggan, dua rintangan, radar, HUD, tenggat, layar hasil; halaman depan koran dengan misi P1 kucing hilang. | Satu hari bisa dimainkan dari koran sampai hasil, dengan placeholder atau aset gelombang 1. |
| **M3 — Vertical slice perumahan** | Aset final distrik perumahan, reputasi, bengkel dan kerusakan, ekonomi, milestone dasar, audio dasar, beberapa hari berturut-turut dengan flag lanjutan. | Seminggu dalam game di distrik perumahan bisa dimainkan tanpa kebuntuan. |
| **M4 — Konten & rilis** | Distrik berikutnya, misi per distrik, iklan hadiah, kebijakan privasi, store listing, uji tertutup. | Lolos review Play Console. |

## 4b. Keputusan teknis Fase 0 (dikunci 2026-10-09, kecuali baris bertanda usulan)

Skala dipilih Ronggur; sisanya didelegasikan ke agent dengan alasan tertulis. Bisa dibatalkan lewat PR selama belum ada upload ke Play Console.

| Keputusan | Pilihan | Alasan |
|---|---|---|
| Skala piksel | **×3**, tinggi dasar 360 piksel game | Sprite pemain sudah dibuat untuk ×3 (kanvas 800×360). Pandangan ke depan lebih luas untuk bereaksi saat ngebut (6 u/d). |
| Versi Godot | **4.7.2** | Versi pemeliharaan terbaru yang tercatat (TECH_PLAN); sama dengan Brainy Dungeon, jadi panduan export Android dan template bisa dipakai ulang. Sprite pemain dicek di 4.3 dan sudah dimuat di 4.7.2 tanpa perubahan (run 0A, 2026-10-09). |
| Resolusi dasar dan stretch | **640×360**, stretch `canvas_items`, `scale_mode = integer`, aspect `expand`; lebar tampil 640 (16:9) sampai 800 (20:9) | HUD dan teks dirender di resolusi layar sehingga tajam, sprite tetap pixel-perfect lewat skala bulat dan `snap_2d_transforms_to_pixel`. Cara `viewport` (piksel paling konsisten tapi teks beresolusi rendah) dipakai sebagai cadangan. **Hasil verifikasi run 0A (2026-10-09, desktop macOS, bukan HP): dipertahankan.** Jendela 1920×1080, 2340×1080, 2400×1080 memberi viewport 640×360, 780×360, 800×360 dengan skala ×3; 1280×720, 1560×720, 1600×720 memberi viewport yang sama dengan skala ×2. Skala selalu bulat, tidak pernah pecahan, dan tangkapan layar jendela asli lolos pemeriksa blok piksel (tiap piksel game jadi blok seragam). Pada ukuran yang bukan kelipatan (mis. 1170×540) Godot memilih skala bulat di bawahnya dan menyisakan tepi kosong. **Risiko untuk run 0C:** di Android, bila tinggi jendela yang dipakai game kurang dari 1080 (bilah sistem tidak tersembunyi), skala turun ke ×2 dengan tepi kosong; layar penuh imersif harus diatur di preset export dan dicek di A54. Ketajaman di HP belum diuji. Bukti dan perintah: `docs/loop/20261009-fase0a-fondasi/LOG.md`. |
| HP uji | **Samsung Galaxy A54 (SM-A546E)**, Android 16 (API 36), layar 2340×1080 landscape (19,5:9, tepat ×3 → kanvas 780×360), GL ES 3.2, kelas menengah | Terhubung lewat `adb` (2026-10-09). Mewakili HP menengah target; uji HP kelas bawah dan layar 16:9 menyusul (emulator atau perangkat lain). Perangkat dipakai bersama project lain: pasang dan hapus app hanya setelah izin pemilik. |
| Nama package Android | **`com.rmh.kring`** | Pilihan Ronggur (2026-10-09, menggantikan usulan awal `com.rmh.loperkoran`). Pola sama dengan `com.rmh.brainydungeon`. Tidak bisa diganti setelah upload pertama ke Play Console. |
| Format file terjemahan | **CSV `translations/ui.csv`** (kolom `keys,id`, kolom bahasa ditambah di kanan) | Pilihan Ronggur (2026-10-09). Satu file, diimpor Godot otomatis, mudah diedit; rule `content-data` dan `DESIGN_SPEC` 5 mengikuti. Teks panjang (cerita) boleh di CSV lain dengan format yang sama. |
| Export Android (usulan, run 0C) | Tanpa Gradle build, `arm64-v8a` saja, min SDK 24 (bawaan template), target SDK 36 (bawaan template 4.7.2, memenuhi syarat Google Play API 36), mode imersif, orientasi `landscape` satu arah, `allowBackup` false, nol izin di build debug | Usulan, belum dikunci: detail dan alasan di `SETUP_ANDROID.md`. Gradle build baru dibutuhkan Fase 8 (plugin iklan/analytics) atau bila target SDK perlu dikendalikan. Template export 4.7.2 dipasang di mesin pengembang; APK debug 27 MB. Risiko: ikon `icon.svg` sementara (ganti di Fase 14), peringatan provider ganda di manifes hasil ekspor Godot (tidak menggagalkan pemasangan, terbukti di A54). |

## 5. Keputusan yang masih terbuka

| Keputusan | Menghambat |
|---|---|
| Ukuran ubin (usulan 64×32) | Semua aset dunia. Dikunci setelah graybox Fase 1 (skala piksel sudah ×3). |
| Subjudul Inggris dan cek ketersediaan nama "Kring Kring!" (Play Store, App Store, Steam, PDKI/DJKI) | Fase 0 (export). Nama package sudah `com.rmh.kring` (4b), jadi cek ini sebaiknya selesai sebelum upload pertama ke Play Console |
| Ambang rem di stick dan ketelitian swipe pendek | M1 (diputuskan lewat uji HP) |
| Jendela kena koran: bonus atau penalti (GDD 4.1) | Fase 2–3 (skor) |
| Cara menampilkan rumah di sisi dekat | Fase 3 (rute), aset rumah |
| Struktur sesi: hari berurutan atau run roguelite | M2 |
| Game over atau tidak, target harian atau tidak (GDD 3.2) | M2 |
| Cerita besar dan akhirnya | M3 |
| Distrik bebas dipilih atau berurutan, syarat reputasi tiap distrik (GDD 9.5) | M3 |
| Misi lintas hari, efek gagal ke pelanggan tertentu (GDD 10.9) | Fase 4 |
| Efek kerusakan, ongkos servis, laju aus, kerusakan di mode bantu (GDD 12.5) | M3 (bengkel) |
| Iklan satu-satunya pemasukan atau ada "hapus iklan", besar bonus iklan (GDD 14.3) | M4 |
| Target usia dan pasar | M4 (kebijakan privasi, aturan iklan) |
| Musik atau hanya ambience | M3 (audio) |

## 6. Cara menjalankan project

Project Godot 4.7.2 ada sejak run 0A (Fase 0); run 0B menambah input touch dan scene utama sementara yang bisa digerakkan; run 0C menambah preset export Android (`export_presets.cfg`) dan `docs/SETUP_ANDROID.md`. Root repo = root project Godot. Dari root repo (macOS tanpa `godot` di PATH: `/Applications/Godot.app/Contents/MacOS/Godot`):

```
godot --headless --import                           # sekali, setelah clone
mkdir -p build                                      # folder log, tidak di-commit
godot --headless --script res://tests/run_tests.gd 2>&1 | tee build/tests.log   # uji logika inti
python3 tools/cek_keluaran_tes.py build/tests.log   # pemeriksa keluaran: wajib, exit code Godot saja tidak cukup
godot --headless --path . --quit-after 2            # buka project dua frame, tanpa ERROR dan WARNING
godot --headless --path . --script res://tests/probe_layar.gd   # skala bulat dan viewport per rasio layar
godot --path .                                      # jalankan scene utama sementara (jalan_uji.tscn): stick di layar sentuh, panah atau WASD di editor
python3 tools/env_art/graybox.py                    # render ulang ubin graybox (hanya stdlib)
python3 tools/loper_art/produce.py                  # render ulang sprite pemain (butuh numpy, pillow)
mkdir -p builds                                     # folder APK hasil export, tidak di-commit
godot --headless --path . --export-pack "Android" build/kring-uji.pck   # paket game dengan filter preset (tanpa Java)
godot --headless --path . --export-debug "Android" builds/kring-kring-debug.apk   # APK debug (export templates 4.7.2 dan Java SDK Path di Editor Settings)
```

Export Android dan APK debug (`builds/`): prasyarat mesin, isi preset, pemeriksaan isi APK, pasang ke HP, dan checklist uji ada di [`SETUP_ANDROID.md`](./SETUP_ANDROID.md). CI (`.github/workflows/tes.yml`) menjalankan import, tes, dan pemeriksa keluaran di setiap PR; CI tidak membangun APK.
