# Roadmap — Loper Koran

Status per **22 Oktober 2026**: pemilik menguji HP 2026-10-22 ("untuk uji hp sejauh ini oke semua"), jadi **M1 dan M2 tercapai** (Fase 2, 3, 4 selesai, `DEV_PHASES.md`). Fase 5 (aset) dan Fase 6 berjalan; Run 5D dikerjakan di branch `feat/fase5d-sisi-dekat` (menunggu QA dan uji HP `SETUP_ANDROID.md` 8.16): pelanggan sisi dekat mulai hari 3 dan tembok sisi dekat diganti halaman terbuka dengan rumah dekat mundur 0,5 ubin dan teras menjorok (keputusan pemilik 2026-10-22, mengganti keputusan tembok 2026-10-17 di 4b). Pembaruan 23 Oktober 2026: Run UI-1 (redesain UI langkah 1 dan 2: komponen bersama dan bengkel tata C, `LOOP-DEV-QA.md` 6k) dikerjakan Dev di branch `feat/ui1-komponen-bengkel`, usulan, menunggu QA dan uji HP `SETUP_ANDROID.md` 8.18; tidak ada angka atau aturan yang berubah, jadi tidak ada milestone yang bergeser. Status sebelumnya (17 Oktober 2026): Fase 3 run 3C: radar, HUD rute final, tenggat, layar hasil, dan spike sisi dekat, usulan, menunggu uji HP penutup Fase 3; tampilan rumah sisi dekat diputuskan pemilik 2026-10-17: tembok rendah; run 3A dan 3B juga menunggu uji HP; Fase 2 dan M1 masih menunggu uji HP. Dokumen ini mencatat kesiapan sebelum produksi, milestone sampai rilis, dan keputusan yang masih terbuka. Rincian kerja per fase ada di [`DEV_PHASES.md`](./DEV_PHASES.md).

Status: ⬜ belum mulai · 🟡 sedang dikerjakan · ✅ selesai

## 1. Sebelum mulai coding

| # | Kebutuhan | Status | Di mana |
|---|---|---|---|
| 1 | Desain inti: core loop, kontrol, kamera, distrik, misi, sepeda, ekonomi | ✅ Dikunci 2026-10-05/06. Kontrol masih harus diuji di HP. `GDD.md` jadi sumber utama sejak 2026-10-07. | `GDD.md` |
| 2 | Arah visual dan karakter pemain | ✅ Pixel art isometrik (2026-10-06), Kemeja Agen dikunci untuk produksi (2026-10-07). | `ART_DIRECTION.md` 2–3 |
| 3 | Sprite produksi pemain | ✅ 15 animasi kayuh (3 kecepatan × 5 arah), SpriteFrames Godot dicek memuat di Godot 4.3 (2026-10-07) dan di 4.7.2 tanpa perubahan (2026-10-09, run 0A). | `design/character/loper_agen/` |
| 4 | Art bible: aturan pixel art, palet, ukuran, penamaan | 🟡 Ditulis 2026-10-07. Palet induk masih usulan sampai aset gelombang 1; ukuran ubin 64×32 dikunci 2026-10-14 (4b). | `ART_DIRECTION.md` |
| 5 | Angka tuning awal | 🟡 Usulan awal ditulis 2026-10-07, disetel lewat prototype. | `BALANCING.md` |
| 6 | Format data (misi, headline, segmen rute, save) | 🟡 Usulan ditulis 2026-10-07, dikunci saat Fase 3–4. Segmen rute: JSON buatan tangan, diterapkan di run 3A (2026-10-16), masih usulan sampai uji HP. | `DATA_SCHEMA.md` |
| 7 | Project Godot, export Android, panduan setup HP | ✅ Project Godot (run 0A), input touch dan sepeda placeholder (run 0B), preset export + APK debug + panduan `SETUP_ANDROID.md` (run 0C) lolos QA 2026-10-09; uji HP di A54 lolos 2026-10-13 (Fase 0 dan M0 selesai). Cek light 2D/glow/partikel pindah ke Fase 1. | `DEV_PHASES.md` Fase 0, `SETUP_ANDROID.md` |

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
| **M0 — Fondasi teknis** ✅ 2026-10-13 | Repo, project Godot landscape, skala piksel bulat, input touch (stick + swipe), sprite pemain terpasang, export APK. | APK terpasang di HP, sepeda placeholder bisa digerakkan dengan stick di HP. |
| **M1 — Terasa enak di HP** | Prototype 1 dan 2: gerak sepeda dengan 3 kecepatan, stamina, rem, pindah sisi; lemparan yang mewarisi kecepatan dengan garis bidik. | Mengayuh dan melempar terasa enak di HP asli menurut pemilik yang mencoba (keputusan pemilik 2026-10-14: uji HP cukup oleh pemilik sendiri, semula 3–5 orang), dan dua pertanyaan kontrol di GDD 17 terjawab. |
| **M2 — Satu hari penuh** | Prototype 3 dan 4: satu rute perumahan dari segmen, 25 pelanggan, dua rintangan, radar, HUD, tenggat, layar hasil; halaman depan koran dengan misi P1 kucing hilang. | Satu hari bisa dimainkan dari koran sampai hasil, dengan placeholder atau aset gelombang 1. |
| **M3 — Vertical slice perumahan** | Aset final distrik perumahan, reputasi, bengkel dan kerusakan, ekonomi, milestone dasar, audio dasar, beberapa hari berturut-turut dengan flag lanjutan. | Seminggu dalam game di distrik perumahan bisa dimainkan tanpa kebuntuan. |
| **M4 — Konten & rilis** | Distrik berikutnya, misi per distrik, iklan hadiah, kebijakan privasi, store listing, uji tertutup. | Lolos review Play Console. |

## 4b. Keputusan teknis Fase 0 (dikunci 2026-10-09, kecuali baris bertanda usulan)

Skala dipilih Ronggur; sisanya didelegasikan ke agent dengan alasan tertulis. Bisa dibatalkan lewat PR selama belum ada upload ke Play Console.

| Keputusan | Pilihan | Alasan |
|---|---|---|
| Skala piksel | **×3**, tinggi dasar 360 piksel game | Sprite pemain sudah dibuat untuk ×3 (kanvas 800×360). Pandangan ke depan lebih luas untuk bereaksi saat ngebut (6 u/d). **Skala ×4 dipertimbangkan dan ditunda (Ronggur, 2026-10-09): tetap ×3.** Sprite pemain di A54 setinggi sekitar 8 mm dan terasa kecil, tapi ×4 tidak menuntut menggambar ulang sprite dunia (piksel 1× tetap, hanya dikalikan 4). Yang berubah bila ×4 dipilih nanti: kanvas dasar 480×270 (A54: 585×270, area lihat turun sekitar 44%, jalan terlihat saat ngebut dari sekitar 2,2 menjadi sekitar 1,5 detik), tata letak HUD dan zona kontrol (dirancang untuk tinggi 360), gambar skala besar (tokoh setinggi 270 px tampil ×3, `ART_DIRECTION` 3.x), dan tempo rute di `BALANCING`. Alternatif tanpa mengubah skala: posisi sepeda lebih rendah, kontrol dan HUD lebih besar (`DEV_PHASES` Fase 1). Tinjau ulang bila uji HP Fase 1 menilai sprite terlalu kecil, dan sebelum HUD final dan aset produksi dibuat. |
| Versi Godot | **4.7.2** | Versi pemeliharaan terbaru yang tercatat (TECH_PLAN); sama dengan Brainy Dungeon, jadi panduan export Android dan template bisa dipakai ulang. Sprite pemain dicek di 4.3 dan sudah dimuat di 4.7.2 tanpa perubahan (run 0A, 2026-10-09). |
| Resolusi dasar dan stretch | **640×360**, stretch `canvas_items`, `scale_mode = integer`, aspect `expand`; lebar tampil 640 (16:9) sampai 800 (20:9) | HUD dan teks dirender di resolusi layar sehingga tajam, sprite tetap pixel-perfect lewat skala bulat dan `snap_2d_transforms_to_pixel`. Cara `viewport` (piksel paling konsisten tapi teks beresolusi rendah) dipakai sebagai cadangan. **Hasil verifikasi run 0A (2026-10-09, desktop macOS, bukan HP): dipertahankan.** Jendela 1920×1080, 2340×1080, 2400×1080 memberi viewport 640×360, 780×360, 800×360 dengan skala ×3; 1280×720, 1560×720, 1600×720 memberi viewport yang sama dengan skala ×2. Skala selalu bulat, tidak pernah pecahan, dan tangkapan layar jendela asli lolos pemeriksa blok piksel (tiap piksel game jadi blok seragam). Pada ukuran yang bukan kelipatan (mis. 1170×540) Godot memilih skala bulat di bawahnya dan menyisakan tepi kosong. **Risiko untuk run 0C:** di Android, bila tinggi jendela yang dipakai game kurang dari 1080 (bilah sistem tidak tersembunyi), skala turun ke ×2 dengan tepi kosong; layar penuh imersif harus diatur di preset export dan dicek di A54. Ketajaman dan skala ×3 di A54 lolos uji HP (2026-10-13). Bukti dan perintah: `docs/loop/20261009-fase0a-fondasi/LOG.md`. |
| HP uji | **Samsung Galaxy A54 (SM-A546E)**, Android 16 (API 36), layar 2340×1080 landscape (19,5:9, tepat ×3 → kanvas 780×360), GL ES 3.2, kelas menengah | Terhubung lewat `adb` (2026-10-09). Mewakili HP menengah target; uji HP kelas bawah dan layar 16:9 menyusul (emulator atau perangkat lain). Perangkat dipakai bersama project lain: pasang dan hapus app hanya setelah izin pemilik. |
| Ukuran ubin | **64×32 px** (persegi dunia 32×32 unit; dikunci Ronggur 2026-10-14) | Dikunci setelah graybox Fase 1, seperti direncanakan. `scripts/config.gd` (`UBIN_*`), `Iso`, ubin graybox, sprite pemain, dan uji HP Fase 1 (A54 dan vivo V2108) sudah memakai ukuran ini tanpa keluhan. Jarak lemparan (BALANCING 4) dan semua aset dunia bergantung padanya. |
| Arah lempar koran | **Bebas** (Ronggur 2026-10-15): koran terbang ke arah swipe di layar, diproyeksikan ke tanah lewat `Iso`; menggantikan dua arah tetap (kiri = seberang, kanan = dekat) dari run 2A | Uji HP pemilik di vivo V2108 (2026-10-14): lemparan ke seberang sering gagal karena rumah seberang di depan terlihat di atas sepeda, sedangkan swipe dominan tegak ditolak. Rinciannya (panjang swipe penuh, sisi dari arah melintang, penilaian zona dari titik mendarat) usulan run `20261015-fase2-arah-bebas`, dinilai lewat uji HP. GDD 5.2. |
| Tampilan rumah sisi dekat | **Halaman rumput terbuka tanpa tembok**; rumah dekat mundur **0,5 ubin** dan didesain ulang dengan **teras menjorok ke arah jalan** sehingga terbaca dari samping; kotak surat dekat di tepi trotoar (pilihan pemilik 2026-10-22, **menggantikan** keputusan tembok 2026-10-17 di bawah; dikerjakan Run 5D, usulan sampai dinilai di HP, `SETUP_ANDROID.md` 8.16). Pelanggan sisi dekat dimajukan dari Fase 8 ke Fase 5: mulai hari 3, 8 atau 9 dari 25 | Pemilik melihat tangkapan mundur 0,25 sampai 1,5 ubin tanpa tembok dan memilih 0,5: kotak surat dekat 44% tertutup pada sprite lama, jadi rumah didesain ulang (teras menjorok, atap sisi jalan rendah, tanpa kotak surat terpanggang) sampai badan kotak surat 0% dan zona kotak surat 2,58% tertutup, pemain di lajur dan trotoar dekat 0% (oracle piksel, `docs/loop/20261022-fase5d-sisi-dekat/`). Pudar rumah (semi-transparan permanen) tidak dipakai. **Riwayat (diganti, tetap dicatat):** *2026-10-17, tembok atau pagar belakang rendah di kaki kavling, rumah penuh (belakang) di belakangnya, kavling dekat lebih dalam sekitar 1,25 ubin (pendekatan 2 spike run 3C; dipasang Run 5B, tinggi tembok 14 unit)*: di spike graybox sasaran dekat tidak pernah tertutup (badan kotak surat dan zona 0%, dibanding 3%/22% pendekatan rendah dan 40%/78% semi-transparan), tembok memberi batas halaman yang jelas dan cocok untuk gang kampung Bab 2. Pemilik menilai sisi dekat terlihat berbeda dari sisi jauh, jadi tembok dihapus (2026-10-22). Bukti spike: `docs/loop/20261018-fase3c-hud-hasil/` (LOG, `shots/spike_sisi_dekat/`). Gang kampung Bab 2 dinilai ulang saat aset M3. |
| Nama package Android | **`com.rmh.kring`** | Pilihan Ronggur (2026-10-09, menggantikan usulan awal `com.rmh.loperkoran`). Pola sama dengan `com.rmh.brainydungeon`. Tidak bisa diganti setelah upload pertama ke Play Console. |
| Format file terjemahan | **CSV `translations/ui.csv`** (kolom `keys,id`, kolom bahasa ditambah di kanan) | Pilihan Ronggur (2026-10-09). Satu file, diimpor Godot otomatis, mudah diedit; rule `content-data` dan `DESIGN_SPEC` 5 mengikuti. Teks panjang (cerita) boleh di CSV lain dengan format yang sama. |
| Export Android (usulan, run 0C) | Tanpa Gradle build, `arm64-v8a` saja, min SDK 24 (bawaan template), target SDK 36 (bawaan template 4.7.2, memenuhi syarat Google Play API 36), mode imersif, orientasi `landscape` satu arah, `allowBackup` false, nol izin di build debug | Usulan, belum dikunci: detail dan alasan di `SETUP_ANDROID.md`. Gradle build baru dibutuhkan Fase 8 (plugin iklan/analytics) atau bila target SDK perlu dikendalikan. Template export 4.7.2 dipasang di mesin pengembang; APK debug 27 MB. Risiko: ikon `icon.svg` sementara (ganti di Fase 14), peringatan provider ganda di manifes hasil ekspor Godot (tidak menggagalkan pemasangan, terbukti di A54). |

## 5. Keputusan yang masih terbuka

| Keputusan | Menghambat |
|---|---|
| Subjudul Inggris dan cek ketersediaan nama "Kring Kring!" (Play Store, App Store, Steam, PDKI/DJKI) | Fase 0 (export). Nama package sudah `com.rmh.kring` (4b), jadi cek ini sebaiknya selesai sebelum upload pertama ke Play Console |
| Ketelitian swipe pendek (ambang rem: lolos uji HP pemilik 2026-10-14, angka ≥90% ditahan 0,25 detik dipakai) | M1, Fase 2 (diputuskan lewat uji HP) |
| Jendela kena koran: bonus atau penalti (GDD 4.1). Bawaan prototype Run 2A: **penalti ringan** (antaran tidak sah, tanpa potong koin) lewat sakelar di `scripts/config.gd`, nilai bonus tetap tersedia (pemilik 2026-10-14); keputusan akhir tetap terbuka. Run 3B memakai sakelar yang sama untuk skor dan koin (penalti = meleset: 0 skor, 0 koin, combo putus; bonus = sah penuh + bintang) tanpa mengubahnya | Fase 2–3 (skor) |
| Pemetaan pelanggan tetap (id rumah di save, mis. `per_r014`) ke rute yang diacak. Format segmen **diputuskan JSON buatan tangan** (pemilik 2026-10-16, run 3A, `DATA_SCHEMA` 3 dan 5); run 3A memakai id rute `<id_segmen>@<pos>` dan tidak menulis save | Fase 6 (save dan hari) |
| Struktur sesi: hari berurutan atau run roguelite | M2 |
| Batas tabrakan per rute (run 3B: tanpa batas dan tanpa game over, tabrakan hanya menghambat, K-1); dicek ulang bersama game over | M2 |
| Game over atau tidak, target harian atau tidak (GDD 3.2) | M2 |
| Cerita besar dan akhirnya | M3 |
| Distrik bebas dipilih atau berurutan, syarat reputasi tiap distrik (GDD 9.5) | M3 |
| Misi lintas hari, efek gagal ke pelanggan tertentu (GDD 10.9) | Fase 4 |
| Efek kerusakan, ongkos servis, laju aus (GDD 12.5): angka usulan run 6A1 ada di BALANCING 8, menunggu uji HP. **Kerusakan di mode bantu diputuskan pemilik 2026-10-20: tidak mengubah keausan atau kerusakan.** | M3 (bengkel) |
| ~~**Usulan pemilik 2026-10-22:** koran yang dilempar lalu terbuang dipotong~~ **Dikerjakan run 6A2 bagian B (usulan, dinilai di HP):** `KOIN_POTONGAN_KORAN_MELESET` 5, hasil hari boleh minus, saldo dijepit 0, koran cadangan yang tidak dilempar tidak dipotong (BALANCING 7.3, GDD 2 dan 14.1). Hukuman tambahan untuk pelanggan terlewat belum diputuskan dan tidak dikerjakan | Fase 6A2 (selesai, menunggu uji HP) |
| **Run 6A2 (bagian A sampai C, usulan, menunggu uji HP):** reputasi per distrik 0 sampai 100 (naik sekitar 2 sampai 3 poin per hari bagi pemain teliti), pelanggan tetap (aktif, setia, berhenti, kembali) dengan kepribadian dan pemetaan ke rute diacak, penanda reputasi di HUD dan layar hasil, empat milestone x tiga tingkat di layar hasil (BALANCING 7.2 dan 7.4, GDD 8 dan 13). **Reputasi belum memengaruhi pendapatan atau membuka distrik** (GDD 8 "menaikkan pendapatan", syarat buka distrik): ditunda ke 6B dan Fase 8. Tiga usulan pemilik 2026-10-22 di bawah (anjing, mobil berbelok, garis finish) tetap usulan dan tidak dikerjakan di 6A2 | 6A2 selesai; efek reputasi 6B/Fase 8 |
| **Lisensi latar bengkel (butir pemilik, 2026-10-23, Run UI-1):** ilustrasi AI `docs/design/redesain/latar_bengkel/sumber_ai.jpg` kiriman pemilik; generator dan ketentuan lisensi komersialnya belum dicatat. Latar dipasang untuk uji HP (`assets/sprites/ui/ui_bengkel_latar_800.png`, keputusan orchestrator U-4, bisa ditolak) tetapi belum boleh masuk rilis; catat di `assets/LICENSES.md` atau ganti latar (ART_DIRECTION 9) | M4 (rilis); uji HP 8.18 tidak terhambat |
| **Redesain UI layar penuh (usulan 2026-10-23, `design/redesain/README.md` 6):** langkah 1 dan 2 (komponen, bengkel) dikerjakan Run UI-1 dan menunggu uji HP 8.18; langkah 3 sampai 6 (hasil, koran, jeda dengan tutorial dan banner, tombol jeda HUD) belum, termasuk lapisan jeda 72% (bukan alpha 84% token `HUD_PANEL`) dan kunci teks baru "Iklan baris" dan "Pelanggan:". Garis bingkai kartu dan tombol nonaktif bengkel berkontras 1,14 sampai 1,78:1 (di bawah 3:1, keputusan D-1 di LOG run UI-1): disorot atau diterima | setelah uji HP 8.18 |
| **Usulan pemilik 2026-10-22:** anjing berhenti mengejar terlalu cepat, terutama di rumah dekat (ukur jarak kejar dulu, run tuning kecil) | sesudah Run 5D |
| **Usulan pemilik 2026-10-22:** sebagian mobil keluar garasi lanjut berbelok dan melaju (data simpang run 5C sudah disiapkan) | M3 (lalu lintas) |
| **Usulan pemilik 2026-10-22:** garis finish: sepeda otomatis melaju keluar viewport menggantikan animasi berhenti, dengan penanda di dunia (mungkin portal); kontrol dikunci lurus, lempar nonaktif, banner saat hampir keluar; menyentuh `AkhirRute` dan kamera | run kecil bersama aset portal (M3) |
| Iklan satu-satunya pemasukan atau ada "hapus iklan", besar bonus iklan (GDD 14.3) | M4 |
| Target usia dan pasar | M4 (kebijakan privasi, aturan iklan) |
| Musik atau hanya ambience | M3 (audio) |

**Sudah diputuskan (tidak lagi terbuka):** hubungan skor dan koin, **dua besaran terpisah dan keduanya dihitung** (keputusan pemilik 2026-10-16, run 3B K-2): skor = nilai sasaran × combo × pengali kecepatan (× tepat), koin = ongkos antar 15 per antaran sah + tip 5 dari teras pemberi tip; skor tidak dikonversi ke koin dan sebaliknya (`BALANCING.md` 5, 5b, 7). Angka skor dan tip tetap usulan sampai uji HP.

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

Export Android dan APK debug (`builds/`): prasyarat mesin, isi preset, pemeriksaan isi APK, pasang ke HP, dan checklist uji ada di [`SETUP_ANDROID.md`](./SETUP_ANDROID.md). CI (`.github/workflows/tes.yml`) menjalankan import, tes, dan pemeriksa keluaran di setiap PR; `.github/workflows/build-apk.yml` membangun APK uji (debug) di setiap PR dan `release-please.yml` mengurus versi dan Release (SETUP_ANDROID bagian 4b).
