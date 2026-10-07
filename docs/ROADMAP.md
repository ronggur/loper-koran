# Roadmap — Loper Koran

Status per **7 Oktober 2026**. Dokumen ini mencatat kesiapan sebelum produksi, milestone sampai rilis, dan keputusan yang masih terbuka. Rincian kerja per fase ada di [`DEV_PHASES.md`](./DEV_PHASES.md).

Status: ⬜ belum mulai · 🟡 sedang dikerjakan · ✅ selesai

## 1. Sebelum mulai coding

| # | Kebutuhan | Status | Di mana |
|---|---|---|---|
| 1 | Desain inti: core loop, kontrol, kamera, distrik, misi, sepeda, ekonomi | ✅ Dikunci 2026-10-05/06. Kontrol masih harus diuji di HP. `GDD.md` jadi sumber utama sejak 2026-10-07. | `GDD.md` |
| 2 | Arah visual dan karakter pemain | ✅ Pixel art isometrik (2026-10-06), Kemeja Agen dikunci untuk produksi (2026-10-07). | `ART_DIRECTION.md` 2–3 |
| 3 | Sprite produksi pemain | ✅ 15 animasi kayuh (3 kecepatan × 5 arah), SpriteFrames Godot dicek memuat di Godot 4.3 (2026-10-07). | `design/character/loper_agen/` |
| 4 | Art bible: aturan pixel art, palet, ukuran, penamaan | 🟡 Ditulis 2026-10-07. Palet induk dan ukuran ubin masih usulan sampai aset gelombang 1. | `ART_DIRECTION.md` |
| 5 | Angka tuning awal | 🟡 Usulan awal ditulis 2026-10-07, disetel lewat prototype. | `BALANCING.md` |
| 6 | Format data (misi, headline, segmen rute, save) | 🟡 Usulan ditulis 2026-10-07, dikunci saat Fase 3–4. | `DATA_SCHEMA.md` |
| 7 | Project Godot, export Android, panduan setup HP | ⬜ Fase 0. Panduan setup diadaptasi dari `SETUP_ANDROID.md` Brainy Dungeon. | `DEV_PHASES.md` Fase 0 |

## 2. Sebelum game penuh

| # | Kebutuhan | Status |
|---|---|---|
| 8 | Panduan menyusun rute dan segmen | 🟡 Usulan ditulis 2026-10-07 (`ROUTE_DESIGN.md`), diuji di Fase 3. |
| 9 | Panduan menulis headline dan misi | 🟡 Ditulis 2026-10-07 (`CONTENT_GUIDE.md`). Contoh headline hari 1–3 belum dibuat. |
| 10 | Desain layar di luar rute: halaman depan koran, hasil harian, bengkel | ⬜ HUD rute sudah ada di mock; tiga layar ini belum didesain (`design/DESIGN_SPEC.md` 4). |
| 11 | Cerita besar dan kondisi gagal | ⬜ Belum dirancang (GDD 3.2). |
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

## 5. Keputusan yang masih terbuka

| Keputusan | Menghambat |
|---|---|
| Skala piksel (×3 atau ×4) dan ukuran ubin (usulan 64×32) | Semua aset dunia (Fase 0–1). Sprite pemain dibuat untuk ×3 di kanvas 800×360. |
| Resolusi dasar dan cara menangani rasio layar 16:9 sampai 20:9 (usulan di ART_DIRECTION 7) | Fase 0 |
| Nama package Android (tidak bisa diganti setelah upload pertama) | Fase 0 (export) |
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

Belum ada project Godot. Setelah Fase 0, bagian ini diisi dengan perintah import, tes headless, dan export, mengikuti pola Brainy Dungeon:

```
cd loper-koran                                      # root repo = root project Godot
godot --headless --import                           # sekali, setelah clone
godot --headless --script res://tests/run_tests.gd  # uji logika inti
python3 tools/loper_art/produce.py                  # render ulang sprite pemain
```
