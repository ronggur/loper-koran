# Dokumen Teknis Development — Loper Koran

Status per **7 Oktober 2026**. Seluruh isi dokumen ini adalah **usulan** sampai Ronggur menyetujui ("masukkan"). Setelah disetujui, ringkasannya dipindah ke `DEV_PHASES.md` dan `ROADMAP.md`, dan angka-angkanya ke `BALANCING.md` dan `DATA_SCHEMA.md`.

Dokumen ini menjawab satu pertanyaan: **untuk membangun game ini dari nol sampai tamat dan rilis, apa yang harus dibuat di setiap fase, termasuk kode, aset, data, dan konten cerita, dan bagaimana semuanya menyambung ke jalan cerita di `STORY.md`.**

## 0. Cara membaca dokumen ini

| Dokumen | Menjawab |
|---|---|
| `DEV_PHASES.md` | Checklist harian: apa yang dikerjakan berikutnya (Fase 0–8, belum memuat cerita bab 2–6) |
| **Dokumen ini** | Detail teknis dan kebutuhan aset per fase, dengan fase cerita dirinci sampai Fase 14 |
| `ART_DIRECTION.md` | Aturan gaya dan daftar aset gambar (dirujuk, tidak diulang) |
| `STORY.md` | Jalan cerita, bab, tenggat, setoran, akhir |
| `GDD.md` | Aturan main |

**Hubungan dengan `DEV_PHASES.md`.** Nomor Fase 0–7 dipertahankan sama supaya tidak membingungkan. Perubahannya:

1. **Fase 6 dipecah jadi 6A (sistem hari) dan 6B (mesin cerita)**, karena kalender 120 hari, setoran tiga pos, dan syarat buka distrik di `STORY.md` belum punya tempat di `DEV_PHASES.md`.
2. **Fase 7** sekarang berisi Prolog dan Bab 1 yang bisa dimainkan utuh (cerita sudah masuk, bukan hanya gameplay).
3. **Fase 8 ("Distrik berikutnya, iklan, rilis") dipecah jadi Fase 8–14**: satu fase per bab 2–6, lalu Fase Bebas, lalu rilis. Urutannya mengikuti tabel bab di `STORY.md` bagian 6.
4. Milestone **M4** dibelah dua (usulan): **M4 = Cerita tamat** (Fase 8–12) dan **M5 = Fase Bebas dan rilis** (Fase 13–14).

Label: ✅ dikunci di dokumen lain · 🟡 usulan di dokumen ini · ❓ keputusan terbuka (daftar di bagian 9).

## 1. Ringkasan fase

| Fase | Nama | Bab cerita | Hari cerita | Distrik | Milestone | Hasil utama |
|---|---|---|---|---|---|---|
| 0 | Fondasi teknis | — | — | — | M0 | APK jalan di HP |
| 1 | Gerak sepeda dan kecepatan | — | — | graybox | M1 | Kayuh, rem, pindah sisi terasa enak |
| 2 | Lemparan koran | — | — | graybox | M1 | Lemparan mewarisi kecepatan |
| 3 | Satu rute perumahan | — | — | Perumahan | M2 | Satu rute 25 pelanggan sampai layar hasil |
| 4 | Halaman depan koran dan misi kucing | Prolog (tutorial) | — | Perumahan | M2 | Satu hari utuh, save sederhana |
| 5 | Aset gelombang 1 *(paralel)* | — | — | Perumahan | M2–M3 | Rute tanpa placeholder |
| 6A | Hari demi hari | — | — | Perumahan | M3 | Reputasi, bengkel, kerusakan, ekonomi |
| 6B | Mesin cerita | Prolog, 1 | 1–20 | Perumahan | M3 | Kalender, setoran, tabungan, adegan, peta distrik |
| 7 | Vertical slice: Prolog dan Bab 1 | Prolog, 1 | 1–20 | Perumahan | M3 | Cerita 20 hari pertama bisa dimainkan |
| 8 | Bab 2: Perkampungan | 2 | 21–40 | Perkampungan | M4 | Dua sisi jalan pertama kali |
| 9 | Bab 3: Ruko | 3 | 41–60 | Ruko | M4 | Lalu lintas, kios buka-tutup |
| 10 | Bab 4: Pasar tradisional | 4 | 61–80 | Pasar | M4 | Lapak dinamis, dunia berubah oleh cerita |
| 11 | Bab 5: Jalan desa dan persawahan | 5 | 81–100 | Desa | M4 | Medan, cuaca di tengah rute |
| 12 | Bab 6 dan akhir: Pinggir sungai | 6, epilog | 101–120 | Sungai | M4 | Tiga akhir, cerita tamat |
| 13 | Fase Bebas dan milestone penuh | Fase Bebas | — | Semua | M5 | Game tetap main setelah tamat |
| 14 | Rilis | — | — | — | M5 | Iklan, kebijakan, Play Console, uji tertutup |

Urutan di atas bersifat kode dulu, konten kemudian. **Satu fase aktif di jalur kode**, dan Fase 5 (produksi aset) boleh berjalan paralel seperti di `DEV_PHASES.md`.

## 2. Jalan cerita sebagai kontrak teknis

Setiap keputusan di `STORY.md` punya konsekuensi teknis. Tabel ini menjadi daftar periksa: kalau ada fase yang melanggar baris di sini, fasenya yang salah.

| Dari `STORY.md` | Konsekuensi teknis | Fase |
|---|---|---|
| Satu save, dua fase (Cerita lalu Bebas), bukan dua mode (bagian 5) | Satu `user://save.json` dengan field `fase` (`cerita`, `bebas`); tamat tidak menghapus apa pun | 6B, 12, 13 |
| Tokoh utama Fajar Sidik, laki-laki, 17–18 tahun (keputusan 6) | Nama tetap di teks dan potret; pemain tidak memilih nama (menutup pertanyaan di `CONTENT_GUIDE.md` 8) | 7 |
| Cerita 120 hari, 20 April sampai 18 Agustus, 1 hari rute = 1 hari cerita (4.1) | `kalender_cerita.gd` memetakan hari 1–120 ke tanggal; `HARI_CERITA_PER_HARI_RUTE` di `config.gd` (nilai awal 1) | 6B |
| Setoran harian terbagi tiga: Keluarga, Bengkel, Tabungan Kuliah (4) | Tiga saldo di save, layar setoran di hasil harian, rasio awal 35/15/50 | 6B |
| Tenggat pendaftaran terlihat di HUD hasil (4) | Widget kalender dan sisa hari di layar hasil | 6B |
| Pilihan kecil di akhir bab (4, 10) | Sistem adegan dengan percabangan dua opsi dan efek ke setoran, reputasi, akhir | 6B |
| Tanpa game over; tenggat lewat berakhir "tunda setahun" (4) | Tidak ada state gagal di mesin hari; evaluator akhir dijalankan pada hari ke-120 | 6B, 12 |
| Satu bab per distrik, urutan Perumahan → Sungai (6) | `chapters.json` dengan distrik per bab; adegan awal dan akhir bab | 7–12 |
| Syarat buka distrik: reputasi + peristiwa cerita + syarat pendukung, tiap syarat punya jalur pengganti (7) | `district_unlock.gd` dengan tujuh jenis trigger dan `hari_paksa` agar tidak macet | 6B |
| Tiga akhir menurut tabungan dan reputasi (8) | `ending_evaluator.gd`; tiga adegan akhir; tahun kedua | 6B (logika), 12 (konten) |
| Setelah tamat game tetap main, Fajar jadi loper akhir pekan (9) | Mode `bebas` di `DayManager`: tanpa tenggat, tanpa setoran, semua distrik terbuka | 13 |
| Adegan 3–5 kotak dialog di awal dan akhir bab, bukan cutscene (10) | Sistem dialog sederhana berbasis data; latar adegan berupa gambar diam | 6B, 7 |
| Pesan masuk dari Dimas dan Pak Darto di layar hasil (10) | Kartu pesan di layar hasil dari `messages.json` | 6B |
| Berita ringan memuat kabar bab (10) | Headline `ringan` dengan syarat `bab` atau `flag` | 7–12 |
| Tokoh rute muncul lagi di epilog (3, 10) | Epilog membaca flag pelanggan setia: Bu Ratmi, Pak RT, Pak Sarmin, Pak Ujang | 12 |
| Koran memuat iklan baris untuk lapak ibu, pasar ramai kembali (Bab 4) | Flag `pasar_ramai` mengubah kepadatan lapak dan warga di distrik pasar | 10 |
| Tujuh Belasan menutup tenggat (4.1) | Hari ke-120 = 17 Agustus (hari rute terakhir); 18 Agustus = hari daftar ulang (adegan akhir); overlay dekorasi musiman terjadwal berdasarkan tanggal | 12 |

## 3. Arsitektur teknis

Mengikuti struktur di `README.md`. Bagian ini hanya menambahkan yang dibutuhkan cerita.

### 3.1 Autoload dan modul

| Modul | Tanggung jawab | Fase |
|---|---|---|
| `Config` (`scripts/config.gd`) | Semua angka tuning, termasuk parameter cerita | 0 |
| `SaveManager` | Baca, tulis, dan migrasi `user://save.json` | 4 |
| `DayManager` | Mesin hari: koran → adegan → rute → hasil → bengkel → simpan | 4 |
| `RouteBuilder` | Menyusun rute dari segmen dengan seed hari | 3 |
| `MissionManager` | Pemilihan misi harian, template misi, flag lanjutan | 4 |
| `HeadlineManager` | Memilih tiga headline per hari dari pool dan flag | 4 |
| `ReputationManager` | Reputasi per distrik, pelanggan baru dan berhenti | 6A |
| `BikeCondition` | Aus dan rusak per komponen, tanda peringatan | 6A |
| `Economy` | Ongkos, tip, hadiah, harga bengkel, tiga saldo | 6A, 6B |
| `StoryManager` | Fase cerita, hari, tanggal, bab, pilihan, tabungan | 6B |
| `DistrictUnlock` | Mengevaluasi syarat buka distrik tiap pagi | 6B |
| `EndingEvaluator` | Menghitung akhir pada hari ke-120 | 6B |
| `DialogPlayer` | Memutar adegan dari `scenes/*.json` | 6B |
| `MilestoneTracker` | Progres milestone tiga tingkat | 6A (dasar), 13 (penuh) |
| `AdService` | Pembungkus plugin iklan hadiah | 14 |
| `Audio` | Bus, pitch kayuhan, variasi acak | 1 |

Aturan: **logika murni ada di `scripts/systems/` tanpa node**, supaya bisa dites headless (`tests/run_tests.gd`). Node hanya menampilkan.

### 3.2 Mesin satu hari

```
PAGI_KORAN ──► (ADEGAN_AWAL_BAB bila hari pertama bab) ──► RUTE ──► HASIL ──► SETORAN ──► BENGKEL
     ▲                                                                                      │
     │                                   (ADEGAN_AKHIR_BAB + PILIHAN bila hari terakhir bab)│
     └────────────────────────── SIMPAN ◄───────────────────────────────────────────────────┘
```

- Simpan hanya di akhir hari (sesuai `DATA_SCHEMA.md` 4), tidak di tengah rute.
- Mode `bebas` memakai mesin yang sama tanpa SETORAN dan ADEGAN.
- Tidak ada keadaan "kalah". Hari buruk hanya mengurangi pelanggan, reputasi, dan tabungan.

### 3.3 Tambahan format save (versi 2, usulan)

Menambah blok baru ke format di `DATA_SCHEMA.md` 4. Save versi 1 dimigrasi dengan mengisi nilai awal.

```json
{
  "versi": 2,
  "fase": "cerita",
  "cerita": {
    "hari_cerita": 23,
    "bab": 2,
    "siklus": 1,
    "saldo": { "keluarga": 0, "bengkel": 85, "tabungan": 4310 },
    "porsi": { "keluarga": 35, "bengkel": 15, "tabungan": 50 },
    "darurat_keluarga": { "aktif": false, "sisa_hari": 0, "porsi_tambahan": 0 },
    "pilihan": { "bab_2": "pakai_tabungan" },
    "adegan_dilihat": ["prolog_1", "prolog_2", "bab_1_awal", "bab_1_akhir", "bab_2_awal"],
    "akhir": null
  },
  "distrik_terbuka": ["perumahan"],
  "dunia": { "pasar_ramai": false }
}
```

`akhir` terisi `mandiri`, `dibantu_warga`, atau `tunda` pada hari ke-120. `siklus` naik menjadi 2 pada "tahun kedua" (❓ bagian 9).

### 3.4 Data cerita baru (usulan, ditambahkan ke `DATA_SCHEMA.md` setelah disetujui)

| File | Isi |
|---|---|
| `assets/data/story/chapters.json` | Bab: `id`, `hari_mulai`, `hari_selesai`, `distrik`, `adegan_awal`, `adegan_akhir`, `pilihan` |
| `assets/data/story/scenes/<id>.json` | Satu adegan: latar, daftar kotak dialog (pembicara, ekspresi, teks) |
| `assets/data/story/choices.json` | Pilihan akhir bab: dua opsi dengan efek (`porsi`, `reputasi`, `flag`, `skor_akhir`) |
| `assets/data/story/messages.json` | Pesan di layar hasil: pengirim, teks, syarat (hari, bab, flag) |
| `assets/data/story/events.json` | Kejadian keluarga: `darurat_keluarga`, `porsi_tambahan`, `lama_hari` |
| `assets/data/story/endings.json` | Tiga akhir: syarat dan adegan |
| `assets/data/districts.json` | Syarat buka distrik (tujuh jenis trigger) dan `hari_paksa` |
| `assets/data/shop/upgrades.json` | Komponen, level, harga, efek (Fase 6A) |

Teks cerita memakai kunci (`prolog_1.k1`) yang bisa diterjemahkan, bukan string tertanam di kode. Ini murah dilakukan sejak awal dan menjaga pilihan bahasa Inggris tetap terbuka (❓ bagian 9).

### 3.5 Parameter baru di `scripts/config.gd` (semua usulan, disetel di prototype)

| Parameter | Nilai awal | Sumber |
|---|---|---|
| `TARGET_TABUNGAN` | 25.000 | STORY 4.1 |
| `HARI_CERITA_TOTAL` | 120 | STORY 4.1 |
| `HARI_CERITA_PER_HARI_RUTE` | 1 | STORY 4.1 |
| `TANGGAL_MULAI_CERITA` | 20 April | STORY 4.1 |
| `PORSI_AWAL` | 35 / 15 / 50 | STORY 4.1 |
| `PORSI_KELUARGA_MIN` | belum ada angka di STORY ("wajib kecil") | ❓ |
| `AMBANG_MANDIRI` / `AMBANG_DIBANTU` | 100% / 70% | STORY 8 |
| `REP_RATA_MIN_DIBANTU` | 60 | STORY 8 |
| `REP_PER_ANTARAN_TEPAT`, `REP_PER_MELESET`, `REP_PER_HARI_RAPI` | belum ada angka | ❓ BALANCING |
| `HARI_PAKSA_SETELAH_BAB` | 5 | usulan, jalur pengganti STORY 7 |

### 3.6 Strategi tes

- **Tes logika** (`tests/run_tests.gd`, headless): gerak, lemparan, skor, misi, reputasi, kerusakan, setoran, evaluator akhir, migrasi save, validasi semua file data (field wajib, id unik, rujukan, panjang teks sesuai `CONTENT_GUIDE.md`).
- **Simulasi ekonomi cerita** (`tests/sim_ekonomi.gd`, usulan, dari Fase 6B): menjalankan 120 hari dengan tiga profil bot (rapi, rata-rata, ceroboh) dan melaporkan tabungan per bab serta akhir yang dicapai. Ini alat utama untuk menyetel angka STORY 4.1, karena rata-rata 400 koin per hari menuntut misi dan tip hampir tiap hari, sedangkan rute dasar hanya 300–375 koin (GDD 14.1).
- **Uji di HP asli** di akhir tiap fase gameplay, dengan daftar perangkat uji (❓ bagian 9).
- **Playtest orang lain** di akhir Fase 2, 4, 7, dan tiap fase bab, dengan target dari `GDD.md` 10.8 (60–70% pemain baru menyelesaikan misi yang diambil).

### 3.7 Anggaran teknis (usulan)

| Hal | Target |
|---|---|
| Frame rate | 60 fps di HP kelas menengah, minimal 30 fps di kelas bawah |
| Ukuran APK/AAB | di bawah 100 MB (ART_DIRECTION 7) |
| Audio | di bawah 10 MB untuk M3 (SOUND_DESIGN 6); anggaran penuh ditetapkan di Fase 13 |
| Tekstur | maksimal 2048×2048, atlas per konteks |
| Detail hidup bergerak | maksimal sekitar 4 per layar (ART_DIRECTION 6.10) |
| Memuat rute | di bawah 1 detik di HP target |

### 3.8 Konvensi aset tambahan untuk cerita

Menambah `ART_DIRECTION.md` 7 (penamaan dan folder). Semua usulan sampai Fase 6B.

| Jenis | Awalan | Ukuran dasar (usulan) | Gaya | Folder |
|---|---|---|---|---|
| Potret dialog | `portrait_<tokoh>_<ekspresi>.png` | 96×96 px, setengah badan | Gaya skala besar (ART_DIRECTION 3.5), lima nada | `assets/sprites/portraits/` |
| Latar adegan | `scene_<id>.png` | 800×360 px, gambar diam | Sama dengan skala besar, palet distrik | `assets/sprites/scenes/` |
| Ilustrasi koran | `news_<id>.png` | 64×40 px | Sprite, krem monokrom (usulan) | `assets/sprites/news/` |
| UI cerita | `ui_<nama>.png` | mengikuti `DESIGN_SPEC.md` 1.3 | Panel 9-slice | `assets/sprites/ui/` |
| Overlay musiman | `overlay_<nama>_<distrik>.png` | per distrik | Sprite biasa, di atas dunia | `assets/sprites/overlay/` |

Ekspresi potret: netral, senang, cemas atau sedih, kaget. Tokoh yang hanya muncul sebentar cukup dua ekspresi. Potret Fajar memakai desain Kemeja Agen dan kepala terpisah dari gambar full body (ART_DIRECTION 3.5), jadi ekspresinya bisa dirender dari `fullbody.py --layers`.

---

## 4. Fase 0–7: dari fondasi sampai Prolog dan Bab 1

Setiap fase berisi: tujuan, kaitan cerita, sistem dan kode, aset, konten, uji, dan kriteria selesai. Checklist tugas harian tetap di `DEV_PHASES.md`; di sini hanya hal teknis dan kebutuhan aset.

### Fase 0 — Fondasi teknis (M0)

**Tujuan.** Project bisa jadi APK dan jalan di HP sebelum ada gameplay.

**Kaitan cerita.** Belum ada. Hanya memastikan struktur data dan save bisa memuat cerita nanti.

**Sistem dan kode**

| Hal | Keputusan teknis |
|---|---|
| Versi Godot | Usulan: kunci ke satu versi 4.7.x (rilis pemeliharaan terbaru yang terlihat per Agustus 2026 adalah 4.7.2). Sprite pemain baru dicek di 4.3, jadi muat ulang `loper_agen_frames.tres` di versi terpilih |
| Renderer | Compatibility (usulan, ART_DIRECTION 7). Uji light 2D, glow, partikel, dan shader warna bayangan di HP target |
| Stretch | Bandingkan dua cara di ART_DIRECTION 7 (`canvas_items` + integer scale vs `viewport` 640×360 + expand) di rasio 16:9, 19.5:9, 20:9, lalu kunci |
| Import sprite | Nearest, tanpa mipmap, Lossless; `snap_2d_transforms_to_pixel` aktif |
| Input | Stick melayang (zona kiri bawah), swipe (zona kanan), opsi kidal, keyboard untuk editor |
| Target Android | Google Play mewajibkan app baru dan update menargetkan Android 16 (API 36) mulai 31 Agustus 2026. Pastikan template export Godot terpilih mendukung target itu sebelum membuat preset export |
| Nama package | ❓ Putuskan sekarang; tidak bisa diganti setelah upload pertama |
| Repo | Root repo = root project Godot, `docs/.gdignore`, `AGENTS.md` dan `CLAUDE.md` berisi Definition of Done |
| Tes | `tests/run_tests.gd` headless dan CI sederhana |

**Aset**

| Aset | Jumlah | Catatan |
|---|---|---|
| Palet induk `assets/palette/loper_master.gpl` dan `scripts/ui/palette.gd` | 2 file | Dari ART_DIRECTION 2.4 dan DESIGN_SPEC 1.1 |
| Sprite pemain Kemeja Agen | ✅ ada | Salin dari `docs/design/character/loper_agen/` ke `assets/sprites/loper/` |
| Ubin graybox | 3 | Aspal, trotoar, rumput polos 64×32, folder `_placeholder/` |
| Kotak graybox rumah dan kotak surat | 2 | Untuk mengunci skala |
| Font | 2 | Lexend dan Lilita One (belum dikunci, ART_DIRECTION 11); catat lisensi di `assets/LICENSES.md` |
| Ikon aplikasi sementara | 1 | Ganti di Fase 14 |

**Uji.** APK debug terpasang di HP; sepeda placeholder bergerak dengan stick di layar sentuh.

**Selesai kalau.** Sama dengan `DEV_PHASES.md` Fase 0, ditambah: versi Godot, nama package, dan stretch mode sudah tercatat sebagai keputusan di `ROADMAP.md`.

---

### Fase 1 — Gerak sepeda dan kecepatan (M1)

**Tujuan.** Mengayuh, mengatur kecepatan, mengerem, dan pindah sisi terasa enak.

**Kaitan cerita.** Tidak langsung. Tetapi kontrol inilah yang dipakai pemain 120 hari; kalau tidak nyaman di sini, seluruh cerita ikut terganggu.

**Sistem dan kode**

- `Iso` (`scripts/systems/iso.gd`): konversi dunia ↔ layar sesuai ART_DIRECTION 2.2 (x → (+1, +½), y → (−1, +½), z → (0, −1) per unit). Jalan naik ke kanan atas. Tes: bolak-balik dunia → layar → dunia harus kembali ke titik awal.
- `BikeMotion` (`scripts/systems/bike_motion.gd`): logika murni. Masukan stick, keluaran kecepatan, posisi lateral, stamina, status rem. Angka dari `config.gd` (BALANCING 2–3).
- Kamera: sepeda di sepertiga kiri, melebar ke depan saat ngebut.
- `loper_sprite.gd` memilih animasi `kecepatan_arah` dari arah gerak sebenarnya (BALANCING 2).
- Umpan balik: debu roda dan garis kecepatan sebagai placeholder.
- Pause: game benar-benar berhenti.

**Aset**

| Aset | Jumlah | Catatan |
|---|---|---|
| Animasi meluncur | 1 sheet (arah normal dulu) | ART_DIRECTION 3.4 |
| Animasi rem | 1 sheet | Badan sedikit mundur |
| Ubin graybox jalan lurus | pakai Fase 0 | Menilai skala terhadap sprite |
| Garis kecepatan, debu roda | 2 VFX sederhana | Boleh dari partikel kode |
| Ikon jeda dan bar HUD sementara | 3 | Kotak polos |
| Audio placeholder: kayuhan loop, freewheel, rem | 3 file | Pitch kayuhan 1,0 / 1,15 / 1,3 (SOUND_DESIGN 3.2) |

**Uji.** 3–5 orang di HP: ambang rem (≥90% ditahan 0,25 detik), rasa stick, keterbacaan sprite di ×3. Keputusan skala piksel (×3 atau ×4) dan ubin 64×32 dikunci di akhir fase.

**Selesai kalau.** Sama dengan `DEV_PHASES.md` Fase 1.

---

### Fase 2 — Lemparan koran (M1)

**Tujuan.** Lemparan yang mewarisi kecepatan terasa memuaskan dan bisa dikuasai.

**Kaitan cerita.** Koran adalah pekerjaan Fajar. Lemparan yang pas menjadi sumber tip dan ongkos yang kelak menjadi tabungan kuliah.

**Sistem dan kode**

- `ThrowSolver` (`scripts/systems/throw_solver.gd`): dari panjang swipe, sisi, dan kecepatan sepeda menghitung titik mendarat, lama terbang, dan puncak lengkung (BALANCING 4). **Garis bidik memakai fungsi yang sama dengan lemparan sebenarnya**, supaya prediksi dan hasil tidak pernah berbeda.
- Zona sasaran: kotak surat, teras, halaman, jendela, bukan pelanggan (BALANCING 5). Bentuk zona ditulis di data rumah.
- Mode bantu: tap di sisi layar melempar ke kotak surat terdekat di sisi itu, kecepatan otomatis.
- Sisa koran dan jeda 0,35 detik.
- Jendela: bonus atau penalti masih ❓ (ROADMAP 5); sediakan sakelar di `config.gd`.

**Aset**

| Aset | Jumlah | Catatan |
|---|---|---|
| Animasi lempar ke sisi seberang dan sisi dekat | 2 sheet (arah normal dulu) | 3–4 frame, lengan kiri dan kanan |
| Koran gulung berputar | 1 sheet, 4 frame, sekitar 8×6 px | |
| Bayangan koran di tanah | dari kode | Mengikuti tinggi lengkung |
| Penanda garis bidik dan elips pendaratan | dari kode | DESIGN_SPEC 3.7 |
| Audio: lempar, mendarat (kotak surat, teras, rumput, meleset) | 1 + 4 (×3 variasi) | SOUND_DESIGN 3.1 |

**Uji.** Ketelitian swipe pendek di layar kecil; mengenai kotak surat di ketiga kecepatan.

**Selesai kalau.** Sama dengan `DEV_PHASES.md` Fase 2. **M1 selesai.**

---

### Fase 3 — Satu rute perumahan (M2)

**Tujuan.** Satu rute lengkap dari awal sampai layar hasil.

**Kaitan cerita.** Rute ini adalah hari kerja pertama Fajar. Rute 25 rumah dengan ongkos 15 koin menghasilkan 300–375 koin, penghasilan yang sama dengan loper sungguhan (GDD 14.1) dan angka dasar seluruh ekonomi cerita.

**Sistem dan kode**

- `RouteBuilder` dan pemuat segmen (`DATA_SCHEMA.md` 3), 8–10 segmen perumahan, 6–8 per rute, urutan acak dengan seed.
- Rumah dan pelanggan: distrik pertama hanya pelanggan di sisi seberang (GDD 9.1).
- Rintangan dengan mesin keadaan sederhana (GDD 9.3):
  - Anjing penjaga: diam → waspada (menggeram, berdiri) → mengejar sesuai kecepatan pemain → berhenti di batas halaman.
  - Mobil keluar garasi: lampu mundur dulu (minimal 1,5 detik tanda pada kecepatan ngebut, ROUTE_DESIGN 4) → bergerak.
- Tabrakan menghambat, tidak menghentikan rute (BALANCING 6). Skor, combo, pengali kecepatan.
- Radar tepi kiri dan kanan, HUD rute (DESIGN_SPEC 3), tenggat rute.
- **Objek yang menutupi pemain jadi semi-transparan** (prinsip GDD 2.3): aturan satu tempat di renderer, bukan per objek.
- Layar hasil sederhana: terkirim, meleset, koin, tip.

**Spike teknis yang harus selesai di fase ini: rumah di sisi dekat.** Perumahan hanya memakai sisi seberang, tapi keputusan tampilan sisi dekat memengaruhi desain aset rumah, dan Bab 2 (Perkampungan) adalah bab pertama yang memakai dua sisi. Bandingkan di graybox tiga pendekatan (usulan): (1) punggung rumah apa adanya, rendah dan kontras rendah; (2) tembok atau pagar belakang rendah dengan rumah di belakangnya; (3) punggung rumah semi-transparan di dekat pemain. Keputusan paling lambat sebelum aset Fase 8 dibuat. Pinggir sungai (Bab 6) tidak punya masalah ini karena sisi dekat adalah air (GDD 9.2).

**Aset (M2, dari ART_DIRECTION 6)**

| Kelompok | Aset | Jumlah |
|---|---|---|
| Ubin | Aspal + marka putus-putus, trotoar + kerb, rumput halaman, jalan masuk garasi | 4 |
| Rumah | 2 model perumahan: fasad (sisi seberang), belakang (sisi dekat), atap; teras sebagai zona sasaran | sekitar 7 |
| Properti | Kotak surat (penuh/kosong), tong sampah, pohon atau tanaman pot | 3 |
| Rintangan | Anjing (diam, lari, berhenti), mobil keluar garasi + lampu mundur | 2 sheet |
| Data | 8–10 segmen JSON | 10 file |
| UI | Radar (4 penanda), stick melayang, HUD rute (ikon, panel 9-slice), layar hasil sederhana | sekitar 10 |
| Audio | Anjing menggeram dan menggonggong, mobil bip dan mesin, tabrakan, tip | 5 |

**Uji.** 20 rute acak dibuat, 3 dimainkan (ROUTE_DESIGN 7); rute tidak terasa dihafal setelah tiga kali; tiap tabrakan bisa dijelaskan pemain.

**Selesai kalau.** Sama dengan `DEV_PHASES.md` Fase 3, ditambah: keputusan rumah sisi dekat sudah diambil atau punya tanggal.

---

### Fase 4 — Halaman depan koran dan misi kucing (M2)

**Tujuan.** Satu hari utuh: baca koran, ambil misi, antar, lihat hasil.

**Kaitan cerita.** Ini **tutorial Prolog** di `STORY.md` bagian 6: misi kucing Bu Ratmi mengajarkan kontrol dasar dan misi. Di fase ini teksnya masih placeholder; adegan Pak Darto dan keluarga datang di Fase 6B dan 7.

**Sistem dan kode**

- `HeadlineManager`: tiga headline per hari dari pool dan flag (`DATA_SCHEMA.md` 2).
- `MissionManager` dengan template **Cari** (misi P1 Kucing Bu Ratmi): tiga titik, petunjuk dari lemparan tepat, menepi dalam 2 ubin selama 1,5 detik, batas 12 rumah.
- HUD misi, banner selesai dan gagal (`CONTENT_GUIDE.md` 3), flag lanjutan, headline hari berikutnya membaca flag.
- `SaveManager` sederhana (`user://save.json`, versi 1; langsung dengan migrasi supaya versi 2 di Fase 6B tidak merusak).
- Tutorial terpandu (usulan): `tutorial_controller.gd` menampilkan satu petunjuk kontekstual per langkah (kayuh, melambat, lempar, menepi), bisa dilewati, tidak muncul lagi setelah selesai.
- Semua teks melalui kunci terjemahan (lihat 3.4).

**Aset**

| Aset | Jumlah | Catatan |
|---|---|---|
| Layar halaman depan koran | 1 layar | Satu-satunya layar terang, krem `#F2E7C9` (DESIGN_SPEC 4). Nama koran ❓ |
| Ikon efek berita utama | 8 | Hajatan, hujan, pasang, tujuh belasan, pasar kaget, jalan diperbaiki, panen raya, mati lampu (GDD 10.7); 2 dulu cukup |
| Kucing: diam, kabur, ditangkap; jejak kaki; mangkuk; kilau petunjuk (2 frame) | 4 sheet | ART_DIRECTION 6.7 |
| Banner selesai dan gagal | 2 | |
| Audio: petunjuk muncul, meong makin keras, misi selesai, misi gagal, buka koran, tap, Ambil/Lewati | 7 | Setiap suara punya pasangan visual (SOUND_DESIGN 1) |
| Data | `p1_kucing.json`, headline hari 1–3 | `CONTENT_GUIDE.md` 8 |

**Uji.** Pemain baru menyelesaikan P1 tanpa penjelasan lisan (target 60–70%); hari berikutnya menampilkan headline lanjutan sesuai hasil.

**Selesai kalau.** Sama dengan `DEV_PHASES.md` Fase 4. **M2 selesai.**

---

### Fase 5 — Aset gelombang 1 (paralel, M2–M3)

**Tujuan.** Mengganti semua placeholder rute perumahan dengan aset final.

**Kaitan cerita.** Distrik Perumahan adalah rumah pertama pemain di Prolog dan Bab 1. Karakter pelanggan (Bu Ratmi, satpam) harus terbaca sebagai tokoh yang akan muncul lagi di epilog.

Daftar rinci dan ukuran: `ART_DIRECTION.md` 6.1–6.9. Ringkasan kebutuhan dan urutan produksi:

| Urutan | Kelompok | Isi | Perkiraan file |
|---|---|---|---|
| 1 | Pemain | Lempar, meluncur, rem, berhenti, tabrakan (arah normal dulu, lalu arah lain) | 6–8 sheet |
| 2 | Koran | Proyektil, mendarat, terlipat | 3 |
| 3 | Ubin | Aspal, marka, trotoar, kerb, rumput, polisi tidur | 6 |
| 4 | Rumah | 3 model modular, palette swap untuk dinding dan atap, jendela menyala (malam) | sekitar 12 |
| 5 | Properti | Kotak surat, tong sampah, pohon, mobil tamu, lampu jalan, portal satpam, selang | 8 |
| 6 | Rintangan dan warga | Anjing, mobil garasi, penghuni menyiram, tukang sayur, pelanggan di teras (senang, kesal) | 6 |
| 7 | Misi | Kucing, jejak, mangkuk, kilau, pencuri sandal, paket | 6 |
| 8 | VFX | Debu, garis kecepatan, bintang kena sasaran, koin tip, percikan genangan, hujan | 6 |
| 9 | UI | Ikon HUD, penanda radar, stick | sekitar 14 |

Jumlah total mendekati kolom M3 di `ART_DIRECTION.md` 10 (sekitar 122 aset untuk perumahan).

**Aturan produksi.** Rumah dirender dari renderer yang sama dengan pemain (`tools/loper_art`) lalu dipoles manual (ART_DIRECTION 4.2); aset yang dipoles manual dicatat di changelog supaya render ulang tidak menimpanya. Setiap aset pihak ketiga masuk `assets/LICENSES.md` pada hari yang sama.

**Selesai kalau.** Rute perumahan bisa dimainkan tanpa placeholder; palet induk dikunci.

---

### Fase 6A — Hari demi hari: reputasi, bengkel, ekonomi (M3)

**Tujuan.** Sistem jangka panjang yang membuat satu hari berpengaruh ke hari berikutnya.

**Kaitan cerita.** Bengkel adalah pos kedua setoran harian, dan kondisi sepeda adalah alasan pemain tidak boleh menabung seluruh penghasilan ("Menabung banyak membuat sepeda cepat rusak", STORY 4).

**Sistem dan kode**

- `ReputationManager`: reputasi 0–100 per distrik; pelanggan punya status `aktif`, `setia`, `berhenti`; kepribadian pelanggan (cerewet, pemberi tip, sensitif terhadap meleset) dari GDD 8. **Laju reputasi per hari harus bisa dikejar sesuai syarat buka distrik**: syarat Perkampungan adalah reputasi Perumahan 40 dalam sekitar 20 hari, jadi sekitar 2 poin per hari. Parameter dihitung di `sim_ekonomi.gd` (❓ BALANCING).
- `BikeCondition`: ban, rem, rantai (serta setang dan lampu bila dipakai) dengan kondisi 0–1; aus dari ngebut dan sering mengerem, kerusakan langsung dari paku, kaca, genangan; tanda peringatan lebih dulu (rantai berisik, rem berdecit); efek hanya menghambat (GDD 12).
- Layar bengkel: servis dan upgrade; harga dari `upgrades.json`; tombol iklan hadiah opsional (disiapkan, belum aktif sampai Fase 14).
- `Economy`: ongkos 15 koin, tip 5 koin, hadiah misi 45/75/120 (BALANCING 7).
- `MilestoneTracker` dasar (pelanggan, uang, sepeda) dengan tiga tingkat.
- Upgrade yang **diperlukan syarat distrik**: servis pertama dan satu upgrade (syarat Ruko), ban anti-selip (syarat Desa). Daftar upgrade harus memuatnya sejak fase ini.

**Aset**

| Aset | Jumlah |
|---|---|
| Layar bengkel (judul, kartu komponen, kotak kondisi, harga, tombol Servis) | 1 layar + sekitar 8 elemen |
| Ikon komponen: ban, rem, rantai, setang, lampu (normal, aus, perlu bengkel) | 5 ikon × 3 status |
| Ikon upgrade (ban anti-selip, rem pakem, rantai, bel, radar, dll.) | sekitar 8 |
| Ikon milestone dan lencana (perunggu, perak, emas) | sekitar 6 |
| Penanda reputasi (bintang atau angka, ❓ DESIGN_SPEC 6) | 2 |
| VFX: percikan genangan, tanda "!" oranye | 2 |
| Audio kerusakan: rantai berisik, rem berdecit, ban bocor; servis bengkel; milestone | 5 |
| Data | `upgrades.json`, pool kepribadian pelanggan |

**Uji.** Seminggu bermain tanpa kebuntuan; kerusakan terasa menghambat, bukan memblokir.

**Selesai kalau.** Pemain bisa mengantar, melihat reputasi berubah, memperbaiki sepeda di bengkel, dan menabung koin dari ongkos.

---

### Fase 6B — Mesin cerita (M3)

**Tujuan.** Menjadikan rangkaian hari sebagai cerita 120 hari dengan tenggat, setoran, dan akhir.

**Kaitan cerita.** Seluruh `STORY.md` bagian 4, 5, 7, dan 8 diwujudkan di fase ini sebagai sistem. Konten bab belum diisi; yang dibuat adalah mesinnya.

**Sistem dan kode**

| Sistem | Isi |
|---|---|
| `StoryManager` | Fase, hari, tanggal, bab, tabungan, pilihan; maju satu hari setiap SIMPAN |
| `kalender_cerita.gd` | Hari 1 = 20 April, hari 120 = 17 Agustus, lalu 18 Agustus = hari daftar ulang (tenggat); sisa hari ke tenggat |
| Setoran harian | Layar tiga pos (Keluarga, Bengkel, Tabungan) dengan rasio awal 35/15/50; pemain mengatur porsi; ada batas minimum Keluarga dan kejadian darurat yang menaikkannya sementara (`events.json`) |
| Tiga saldo | `keluarga` (terpakai untuk dapur dan sekolah adik), `bengkel` (dibelanjakan di bengkel), `tabungan` (hanya naik). ❓ Apakah saldo bengkel bisa ditambah dari tabungan? Usulan: tidak |
| `DistrictUnlock` | Evaluasi tiap pagi; tujuh jenis trigger (STORY 7): reputasi distrik sebelumnya, peristiwa cerita, misi kunci, syarat sepeda, jumlah pelanggan tetap, ambang tabungan, headline berita utama. **Jalur pengganti**: bila bab berakhir dan syarat belum terpenuhi, setelah `HARI_PAKSA_SETELAH_BAB` distrik dibuka dengan reputasi awal rendah, supaya cerita tidak macet. Distrik yang sudah terbuka tidak terkunci ulang |
| `DialogPlayer` | Adegan 3–5 kotak: latar, potret, nama, teks, opsi; lewati dan lanjut; log dialog opsional |
| Pilihan akhir bab | Dua opsi dari `choices.json` dengan efek terstruktur |
| Pesan masuk | Kartu di layar hasil dari `messages.json` |
| `EndingEvaluator` | Hari ke-120: tabungan terhadap target dan reputasi rata-rata distrik terbuka → `mandiri`, `dibantu_warga`, `tunda` (STORY 8) |
| Peta distrik | Daftar distrik dengan syarat bercentang (STORY 7); menutup keputusan "peta distrik" di DESIGN_SPEC 4 |
| Efek pasar, panen, dan lainnya | `dunia` di save menampung flag dunia (misalnya `pasar_ramai`) yang dibaca `RouteBuilder` |

**Tombol penyesuaian.** Bila 120 hari terasa terlalu panjang di prototype, kecilkan lewat `HARI_CERITA_PER_HARI_RUTE` tanpa mengubah rasio setoran dan target (STORY 4.1).

**Aset**

| Aset | Jumlah | Catatan |
|---|---|---|
| Kotak dialog (panel 9-slice, nama pembicara, indikator lanjut) | 3 | DESIGN_SPEC 1.3 |
| Layar setoran (tiga pos, penggeser porsi, ikon keluarga, bengkel, tabungan) | 1 layar + 6 elemen | |
| Widget kalender tenggat (tanggal, sisa hari, bar tabungan) | 1 | Tampil di layar hasil |
| Kartu pesan masuk | 1 | |
| Layar pilihan akhir bab | 1 | Dua tombol besar |
| Layar peta distrik (6 simpul, status terkunci/terbuka, daftar syarat) | 1 layar + 6 ikon | |
| Layar judul dan menu utama | 1 layar | Memakai gambar full body Fajar (ART_DIRECTION 3.5) |
| Layar pengaturan dan jeda | 2 layar | Kidal, mode bantu, volume, getar |
| Audio UI: dialog maju, setoran tik-tik, kalender | 4 | |
| Data | `chapters.json` (kerangka 6 bab), `districts.json`, `events.json`, `endings.json` | Tanpa naskah penuh |

**Uji.** `sim_ekonomi.gd` menghasilkan tabungan per bab; tes unit untuk setiap trigger dan jalur pengganti, evaluator akhir (ketiga hasil), dan migrasi save v1→v2.

**Selesai kalau.** Hari 1 sampai 120 bisa dijalankan dengan bot dari awal sampai evaluator akhir tanpa kebuntuan, dan distrik dibuka lewat jalur normal maupun jalur pengganti.

---

### Fase 7 — Vertical slice: Prolog dan Bab 1 (M3)

**Tujuan.** Dua puluh hari pertama cerita bisa dimainkan utuh di Perumahan, dengan aset final dan audio dasar.

**Kaitan cerita.** Bab yang dicakup (STORY 6):

| Bab | Peristiwa | Wujud di fase ini |
|---|---|---|
| Prolog | Ayah di-PHK, hasil kelulusan keluar, Pak Darto menerima Fajar sebagai loper titipan, tutorial lewat misi kucing | 2 adegan, tutorial P1, bengkel dan tabungan terbuka |
| Bab 1 | Belajar rute, pelanggan pertama, ongkos pertama masuk tabungan | Adegan awal dan akhir bab, pilihan kecil, target tabungan 4.000 koin (16%) di hari 20 |

**Sistem dan kode**

- Lighting dinamis dan waktu pagi/siang/sore/malam dengan warna bayangan masing-masing (ART_DIRECTION 2.5); satu cuaca (hujan). **Shader warna bayangan** (mengganti penanda `#000000` alpha 71) harus lolos di renderer Compatibility; kalau tidak, ganti pendekatan sebelum aset distrik berikutnya dibuat.
- Berita utama dengan efek dunia: minimal dua (hujan deras, pasar kaget) dari GDD 10.7.
- Misi P2 (Antar khusus) dan P3 (Kejar) beserta template-nya.
- **Sistem overlay musiman generik** dibuat sekarang (dipakai Tujuh Belasan di Fase 12 dan kejadian musiman di Fase 13).
- Playtest seminggu dalam game, lalu 20 hari penuh.

**Aset**

| Kelompok | Aset | Jumlah |
|---|---|---|
| Aset M3 yang tersisa | Detail hidup (jemuran, ayam, kucing tidur, asap warung, layangan), mobil tamu, lampu jalan, selang, pos satpam, persimpangan, genangan, lampu sepeda menyala, pencuri sandal, paket | sekitar 25–30 (ART_DIRECTION 6.10) |
| **Potret** | Fajar (4 ekspresi), Ayah (3), Pak Darto (3), Bu Ratmi (2) | 12 |
| **Latar adegan** | `scene_rumah_fajar` (ruang tamu atau teras, Prolog dan akhir Bab 1), `scene_agen_koran` (Pak Darto, rak koran) | 2 |
| Ilustrasi koran | Kucing, hujan | 2 |
| Audio | Ambience perumahan (pagi, siang, sore, malam), hujan (lapisan), tukang sayur, ayam, motor jauh, bel | 8–10 |
| Keputusan musik | Tanpa musik, atau musik ringan hanya di koran, hasil, bengkel (SOUND_DESIGN 5) | ❓ |
| Konten tulisan | Naskah Prolog (2 adegan), Bab 1 (2 adegan), 1 pilihan, 6–8 pesan Pak Darto, headline hari 1–20 (utama, ringan, lanjutan) | sekitar 40 headline |

**Uji.** Sepuluh jam bermain tidak diperlukan di fase ini; yang diuji adalah 20 hari pertama dengan tiga profil bot dan dua pemain nyata. Tabungan pemain rata-rata mendekati 4.000 koin pada hari 20 (STORY 4.1).

**Selesai kalau.** Prolog dan Bab 1 dimainkan dari layar judul sampai adegan akhir Bab 1 tanpa kebuntuan, dengan aset final dan audio dasar. **M3 selesai.**

---

## 5. Fase 8–12: satu fase per bab

Setiap fase bab punya urutan kerja yang sama:

1. Prototipe mekanik baru di graybox (sebelum aset).
2. Palet dan modul aset distrik (urutan ART_DIRECTION 8 tahap 4).
3. Segmen rute 8–10 (`ROUTE_DESIGN.md`) dan rintangan khas.
4. Tiga misi distrik beserta headline lanjutannya.
5. Adegan awal dan akhir bab, pilihan, pesan, headline kabar bab.
6. Ambience dan suara khas.
7. Simulasi ekonomi bab, lalu uji HP dan playtest.

Distrik **tidak boleh dibuat sebelum perumahan terbukti seru** (ART_DIRECTION 10). Jadi Fase 8 baru dimulai setelah playtest Fase 7.

Perkiraan aset per distrik di bawah mengikuti tabel `ART_DIRECTION.md` 10 (sekitar 70 per distrik tambahan) ditambah aset cerita yang belum dihitung di sana.

### Fase 8 — Bab 2: Perkampungan (hari 21–40)

**Kaitan cerita (STORY 6).** Rumah Fajar ada di sini. Motor ayah dijual, adik butuh biaya sekolah. Pilihan akhir bab: pakai tabungan atau cari tambahan lewat misi. Membuka **setoran Keluarga** sebagai beban nyata. Target tabungan kumulatif 8.000 koin (32%).

**Syarat buka (STORY 7).** Reputasi Perumahan 40, peristiwa "ayah menjual motor, adik butuh biaya", 15 pelanggan tetap, satu misi sampingan selesai.

**Mekanik baru (graybox dulu)**

| Mekanik | Sumber | Catatan teknis |
|---|---|---|
| **Pelanggan di dua sisi** | GDD 4.2, 9.1 | Pertama kali sisi dekat jadi sasaran; radar kedua strip aktif; bonus zigzag (BALANCING 5); aset rumah sisi dekat sesuai keputusan Fase 3 |
| Lemparan jarak dekat | GDD 9.2 | Jalan sempit, swipe pendek dominan |
| **Gang berkelok** | GDD 6, 9.2 | Segmen rute lurus (ROUTE_DESIGN 1) tidak mengenal tikungan. Usulan: tikungan diimplementasi sebagai pergeseran lateral (zigzag) dengan arah kamera tetap kanan atas; uji di graybox sebelum membuat aset. ❓ |
| Lompat selokan | GDD 6 | Tanpa tombol baru: otomatis melompat bila kecepatan ≥ ambang, kalau tidak sepeda terhambat. Ambang di `config.gd` |
| Jemuran melintang | GDD 9.3 | Menutupi sebagian lemparan jarak dekat (bukan menutup jalur); beda dengan jemuran dekorasi |
| Kejadian darurat keluarga | STORY 4, 6 | `events.json`: adik butuh biaya menaikkan porsi Keluarga untuk beberapa hari |
| Pelanggan dua sisi di save | DATA_SCHEMA 4 | Kunci pelanggan memakai rumah tetap per distrik |

**Aset**

| Kelompok | Aset | Jumlah |
|---|---|---|
| Ubin | Gang semen atau paving, selokan terbuka (+ tepi), tembok gang, jalan pintas | sekitar 10 |
| Bangunan | Rumah gang rapat 3 model (bata, semen, seng; fasad dan belakang), warung, pos ronda | sekitar 14 |
| Properti | Jemuran melintang, pot, motor parkir, antena, kabel | sekitar 8 |
| Rintangan dan warga | Ayam menyeberang, anak main, gerobak bakso, warga di pos ronda | 4 sheet |
| Misi | K1 dompet (dompet, inisial di dompet), K2 petisi (kertas petisi, penanda rumah ×4), K3 ayam jago (ayam jago kabur) | 5 |
| Potret | Ibu (3), Adik (3), Pak RT (2) | 8 |
| Latar adegan | `scene_rumah_gang` (teras Fajar tanpa motor), `scene_warung_malam` (opsional) | 1–2 |
| Palet dan grading | Hangat dan padat: semen, bata, seng berkarat (ART_DIRECTION 2.5) | 1 set |
| Audio | Ambience: radio, anak main, ayam, sendok di gelas; lompat selokan, ayam, jemuran, pesan | 8–10 |
| Konten | 3 misi (K1–K3), headline lanjutan, kabar bab, adegan awal dan akhir, pilihan "pakai tabungan atau cari tambahan lewat misi", pesan | sekitar 25 teks |

**Template misi baru.** **Kumpul** (K2), melengkapi Cari dan Antar khusus; Kejar (K3) sudah ada dari P3.

**Uji.** Pemain bisa menjelaskan kenapa dua sisi berbeda; rute berkelok tidak membuat kamera atau radar membingungkan; simulasi ekonomi di akhir bab ≥ 32% target untuk profil rata-rata.

**Selesai kalau.** Bab 2 dimainkan dari adegan awal sampai akhir, dengan pilihan memengaruhi setoran dan flag akhir.

---

### Fase 9 — Bab 3: Ruko (hari 41–60)

**Kaitan cerita.** Dimas berangkat kuliah dan mengirim kabar. Tawaran jadi **kurir online** dengan bayaran lebih tinggi; pilihan akhir bab: setia pada koran atau tidak. Membuka **misi antar khusus** sebagai kebiasaan. Target kumulatif 12.000 koin (48%).

**Syarat buka.** Reputasi Perkampungan 50, peristiwa "Dimas berangkat, tawaran kurir online", satu upgrade sepeda dan servis pertama.

**Mekanik baru**

| Mekanik | Catatan teknis |
|---|---|
| Lalu lintas motor dan angkot | Jalur kendaraan dengan pola bisa dipelajari (angkot berhenti mendadak dengan tanda dulu) |
| **Kios dengan jam buka-tutup** | Status per kios (rolling door); pelanggan adalah kios; jadwal dari data segmen. Dipakai misi R2 |
| Pejalan menyeberang sembarangan | Muncul di jam ramai, dengan tanda |
| Truk bongkar muat | Menutup satu sisi sementara; syarat rute adil tetap berlaku (ROUTE_DESIGN 4) |
| Jalan lebih lebar | Usulan 3 ubin (GDD hanya menulis "lebih lebar"); perbarui penyusunan jalur bantu |
| Ritme paling cepat dan padat | Segmen `padat` lebih banyak; tenggat disetel ulang |

**Aset**

| Kelompok | Aset | Jumlah |
|---|---|---|
| Ubin | Jalan lebar, zebra cross, trotoar ruko, selokan tertutup | sekitar 8 |
| Bangunan | Ruko 3 model, rolling door (buka, tutup, animasi), papan nama rekaan (tanpa merek nyata) | sekitar 18 |
| Properti | Gerobak kaki lima, motor parkir berjajar, rambu, tiang listrik, kardus kue | sekitar 10 |
| Kendaraan | Angkot biru (berhenti, jalan), motor lewat, truk bongkar muat | 3 sheet |
| Warga | Pedagang kaki lima, pejalan menyeberang, sopir angkot | 3 sheet |
| Misi | R1 kardus kue (dengan 3 batang guncangan), R2 tanda tutup berkedip, R3 helm dan jendela angkot | 5 |
| Potret | Dimas (4 ekspresi), pemilik toko kue (2) | 6 |
| Ilustrasi UI | Kartu tawaran kurir online (pesan khusus di hasil) | 1 |
| Latar adegan | `scene_keberangkatan_dimas` (opsional, bisa cukup lewat pesan) | 0–1 |
| Audio | Ambience lalu lintas, klakson pendek, rolling door; angkot, motor, truk; rolling door turun | 8–10 |
| Konten | Misi R1–R3, headline, pesan Dimas, adegan, pilihan | sekitar 25 teks |

**Template misi baru.** **Jaga** (R1) dan **Lempar khusus** (R3). Jaga membutuhkan detektor guncangan dari `BikeMotion`: lubang, rem mendadak, ngebut di tikungan masing-masing mengurangi satu batang.

**❓ Efek pilihan.** STORY 6 menulis "pilih setia pada koran atau tidak" tetapi belum menetapkan akibat. Teknisnya sudah ada slot di `choices.json`; keputusan isinya (misalnya efek ke setoran, reputasi, atau akhir) dibutuhkan sebelum fase ini.

**Selesai kalau.** Bab 3 dimainkan penuh; kios buka-tutup dan lalu lintas tidak membuat rute tidak adil di tiga kecepatan.

---

### Fase 10 — Bab 4: Pasar tradisional (hari 61–80)

**Kaitan cerita.** Ibu berjualan di pasar yang sepi. **Koran memuat iklan baris untuk lapak Ibu dan pedagang lain, pasar ramai kembali.** Target kumulatif 16.000 koin (64%).

**Syarat buka.** Reputasi Ruko 55, peristiwa "Ibu berjualan di pasar sepi", lulus satu misi antar khusus.

**Mekanik baru**

| Mekanik | Catatan teknis |
|---|---|
| Pelanggan adalah pedagang, target meja lapak | Zona sasaran = meja; zona "barang dagangan" memberi penalti (GDD 9.2): perlu dua jenis zona di satu objek |
| Lapak dadakan membuka dan menutup jalur | Segmen punya variasi jalur dengan seed; jalan aman berubah tiap lewat, tetapi **selalu ada satu jalur bersih** (ROUTE_DESIGN 4.1) |
| Becak, gerobak, kuli panggul, keranjang jatuh | Perilaku lambat dan lebar; tanda dulu |
| Tenda terpal rendah | Menutup pandangan: aturan semi-transparan Fase 3 harus menanganinya |
| **Dunia berubah oleh cerita** | Flag `pasar_ramai` (di `dunia`) menaikkan kepadatan pedagang dan warga, diatur oleh iklan baris di koran; memakai varian segmen "sepi" dan "ramai" |
| Iklan baris di koran | Kolom iklan baris di layar koran: tampil mulai Bab 4 |

**Aset**

| Kelompok | Aset | Jumlah |
|---|---|---|
| Ubin | Lantai pasar basah, lorong, genangan pasar | sekitar 8 |
| Bangunan | Los pasar, lapak (meja, tenda terpal biru dan oranye; varian sepi dan ramai), gapura pasar | sekitar 16 |
| Barang dagangan | Sayur, ikan, buah, ayam (perlu terbaca sebagai "jangan kena") | sekitar 8 |
| Kendaraan dan warga | Becak, gerobak, kuli panggul, pedagang, pembeli | 5 sheet |
| Properti | Keranjang, timbangan, kardus, bendera meja (misi M1) | sekitar 8 |
| Misi | M1 bendera meja, M2 es balok (laju lelehnya naik saat berhenti), M3 anak ayam (4 anak ayam, keranjang) | 6 |
| Potret | Ibu (tambahan: berjualan), pedagang unggas (2), pedagang ikan (2) | 5 |
| Latar adegan | `scene_lapak_ibu` | 1 |
| Ilustrasi koran | Kolom iklan baris dan 3–4 ikon lapak | 4 |
| Audio | Ambience pasar, timbangan, plastik; becak, keranjang jatuh, genangan; ciap anak ayam | 8–10 |
| Konten | Misi M1–M3, iklan baris (teks), kabar "pasar ramai", adegan, pilihan | sekitar 25 teks |

**Selesai kalau.** Bab 4 dimainkan penuh dan pasar benar-benar terlihat lebih ramai setelah iklan baris; tidak ada rute pasar tanpa jalur bersih.

---

### Fase 11 — Bab 5: Jalan desa dan persawahan (hari 81–100)

**Kaitan cerita.** Ayah ikut kerja panen, keluarga mulai stabil, **setoran Keluarga turun**. Fajar sempat ragu apakah ingin kuliah. Target kumulatif 20.000 koin (80%).

**Syarat buka.** Reputasi Pasar 60, peristiwa "Ayah ikut panen", ban anti-selip.

**Mekanik baru**

| Mekanik | Catatan teknis |
|---|---|
| **Tanjakan dan turunan** | Pertama kali dibutuhkan penuh: sumbu z di proyeksi 2:1 (ART_DIRECTION 2.2), stamina pulih saat turunan (BALANCING 3) |
| Jalan tanah licin saat hujan | Pengali gesekan per permukaan; ban anti-selip mengurangi efek |
| Rumah berjauhan | Pagar halaman jauh dari jalan (usulan 4–5 ubin dari sepeda), lemparan butuh swipe panjang |
| **Cuaca berubah di tengah rute** | Hujan turun pada paruh kedua rute (misi D2) dan awan mendekat dengan penanda HUD (D3); cuaca runtime, bukan hanya dari headline |
| Kerbau yang tidak bisa dipaksa minggir | Rintangan lambat; D1: kerbau mengikuti sepeda selama kecepatan di bawah santai |
| Parit irigasi dengan jembatan bambu | Satu jalur sempit |
| Setoran Keluarga turun | Peristiwa cerita menurunkan `PORSI_KELUARGA_MIN`; tabungan lebih mudah naik |
| Keraguan Fajar | Adegan dan pilihan; pengaruh ke akhir ❓ |

**Aset**

| Kelompok | Aset | Jumlah |
|---|---|---|
| Ubin | Jalan tanah, tanah basah, sawah (padi bergoyang, 2–3 frame), parit, jembatan bambu, tanjakan dan turunan | sekitar 14 |
| Bangunan | Rumah desa berjauhan 3 model, lumbung atau saung, kandang kerbau | sekitar 12 |
| Properti | Gabah dijemur, terpal, jerami, pagar bambu | sekitar 8 |
| Rintangan dan warga | Kerbau, traktor, kubangan lumpur, rombongan bebek, petani | 5 sheet |
| Misi | D1 kerbau tersesat (jejak lumpur, lonceng), D2 surat dari perantauan, D3 terpal (awan gelap, terpal) | 6 |
| Cuaca | Awan mendekat, hujan desa, langit luas (latar yang lebih besar dari perkampungan) | 4 |
| Potret | Pak Sarmin (3), Ayah (tambahan: kerja panen) | 4 |
| Latar adegan | `scene_sawah_panen` | 1 |
| Audio | Angin di sawah, jangkrik, katak; lonceng kerbau, traktor, bebek; hujan di tanah | 8–10 |
| Konten | Misi D1–D3, headline, adegan, pilihan keraguan | sekitar 25 teks |

**Selesai kalau.** Bab 5 dimainkan penuh; medan dan cuaca tengah rute tidak membuat rute mustahil; setoran Keluarga turun benar-benar terasa di tabungan.

---

### Fase 12 — Bab 6 dan akhir: Pinggir sungai (hari 101–120)

**Kaitan cerita.** Klimaks. Tenggat pendaftaran dekat, **air pasang mengganggu rute**, warga yang sudah akrab ikut membantu. Hari ke-120 = 17 Agustus (hari rute terakhir, Tujuh Belasan), dan 18 Agustus = hari daftar ulang (tenggat). Cerita tamat saat Fajar membayar biaya daftar pada adegan hari itu. Target kumulatif 24.000–25.000 koin.

**Syarat buka.** Reputasi Desa 65, peristiwa "tenggat pendaftaran mendekat", tabungan minimal 60% target.

**Mekanik baru**

| Mekanik | Catatan teknis |
|---|---|
| **Sungai di sisi dekat** | Tidak ada rumah di sisi dekat; menyelesaikan keputusan tampilan sisi dekat untuk distrik ini saja |
| Tepi licin | Merapat ke tepi sungai memperlambat dan menggeser sepeda |
| Air pasang | Peristiwa headline: air menggenang di sisi dekat jalan; jalur aman menyempit; ubin genangan menggantikan ubin jalan dinamis |
| Rumah panggung | Teras tinggi: sasaran punya sumbu z; lemparan sedang |
| Perahu, dermaga, tali tambat, jembatan sempit | Perahu bergerak sandar; tali melintang di jalan; jembatan satu jalur |
| Target bergerak (misi S1) | Lempar tali ke tiang dermaga di depan perahu hanyut, 2 kesempatan |
| **Tujuh Belasan di semua distrik** | Overlay musiman terjadwal tanggal (hari 110–120, puncaknya hari 120 = 17 Agustus) yang dibuat generik di Fase 7 dipasang di keenam distrik |
| Warga membantu (usulan) | Pada hari-hari terakhir, pelanggan setia dari distrik sebelumnya tampil sebagai dekorasi pendukung di tepi rute, memakai sprite yang sudah ada |
| Hitung mundur | Widget tenggat menjadi menonjol di HUD |

**Akhir dan epilog**

| Hasil | Kondisi (STORY 8) | Konten |
|---|---|---|
| Mandiri | Tabungan ≥ 100% | Adegan loket pendaftaran, Fajar membayar sendiri |
| Dibantu warga | Tabungan 70–99% dan reputasi rata-rata ≥ 60 | Warga patungan; besar bantuan mengikuti reputasi; adegan warga di tepi sungai |
| Tunda setahun | Tabungan < 70% atau reputasi < 60 | Fajar menunda; tabungan dibawa ke "tahun kedua" (❓ bagian 9) |

Epilog memutar kembali tokoh rute yang pernah ditolong dan menjadi pelanggan setia: Bu Ratmi, Pak RT, Pak Sarmin, Pak Ujang (CONTENT_GUIDE 7). Kredit, lalu layar "Lanjut Bermain" yang membuka Fase Bebas di save yang sama.

**Aset**

| Kelompok | Aset | Jumlah |
|---|---|---|
| Ubin | Jalan sungai, tepi licin, dermaga kayu, air (animasi 4 frame, tepi), genangan pasang, jembatan sempit | sekitar 16 |
| Bangunan | Rumah padat sisi seberang 3 model, rumah panggung 2 model, tiang dermaga | sekitar 14 |
| Properti | Perahu (sandar, hanyut, berlalu), tali tambat, jemuran melintang antar rumah, ember dan pakaian di tepian | sekitar 10 |
| Warga | Warga mencuci di tepian, nelayan | 2 sheet |
| Misi | S1 tali dan perahu, S2 obat dan rumah panggung, S3 lima bendera tersembunyi | 6 |
| Overlay Tujuh Belasan | Bendera, umbul-umbul, gapura kecil, dekorasi lomba, per distrik (palette swap) | sekitar 12 |
| Potret | Pak Ujang (3), Fajar (ekspresi akhir), semua tokoh epilog | sekitar 8 |
| Latar adegan | `scene_sungai_pasang`, `scene_loket_pendaftaran` (3 varian: mandiri, dibantu, tunda), `scene_epilog_warga` | sekitar 5 |
| Layar | Akhir, kredit, "Lanjut Bermain", transisi tahun kedua | 4 |
| Audio | Air mengalir, mesin perahu jauh; air pasang, perahu, jembatan; motif akhir (jika musik dipakai) | 8–10 |
| Konten | Misi S1–S3, headline Tujuh Belasan dan air pasang, 3 adegan akhir, epilog per tokoh, pilihan terakhir | sekitar 35 teks |

**Uji.** `sim_ekonomi.gd` memastikan ketiga akhir bisa dicapai oleh profil bot yang berbeda, dan profil rata-rata mendekati "dibantu warga" atau "mandiri" (target STORY 4.1). Playtest penuh 120 hari oleh satu atau dua pemain nyata, sekitar 10 jam (usulan STORY 4.1); bila terlalu panjang, setel `HARI_CERITA_PER_HARI_RUTE`.

**Selesai kalau.** Cerita bisa dimainkan dari Prolog sampai salah satu dari tiga akhir, lalu masuk Fase Bebas di save yang sama. **M4 selesai.**

---

## 6. Fase 13–14: sesudah cerita

### Fase 13 — Fase Bebas dan milestone penuh (M5)

**Kaitan cerita (STORY 9).** Fajar berangkat kuliah dan menjadi **loper akhir pekan**. Semua distrik terbuka, hari berurutan tanpa tenggat cerita, uang untuk sepeda dan kosmetik.

**Sistem dan kode**

- `DayManager` mode `bebas`: tanpa setoran, tanpa adegan, tanpa tenggat; semua distrik terbuka otomatis (❓ STORY 11).
- **Rute acak lintas distrik**: pemain memilih distrik dari peta atau diacak (❓ GDD 9.5).
- Misi acak dari katalog 18 misi dengan masa jeda dan seed (GDD 10.3); misi lintas hari (❓ GDD 10.9).
- **Kejadian musiman** dijadwalkan oleh game, bukan tanggal nyata (jawaban usulan untuk GDD 9.5): Tujuh Belasan, hajatan, pasar kaget, mati lampu.
- Milestone penuh tiga tingkat (GDD 13): pelanggan, cerita, uang, keahlian, sepeda; target aktif di bengkel.
- Kosmetik: varian baju (Merah Klasik, Garis Biru, Jaket Hijau, Kaus Bola, Polo Kuning, Batik, Hoodie Abu), stiker, bel, warna sepeda.
- Tipe sepeda (lipat, balap, keranjang besar) dan "tahun kedua" bila dipilih.
- Mode roguelite (GDD 11) tetap opsional dan **ditunda** (ROADMAP 3).

**Aset**

| Aset | Jumlah | Catatan |
|---|---|---|
| Render ulang pemain untuk 7 varian baju | 7 × 15 animasi | Murah: `tools/loper_art` sudah punya varian (ART_DIRECTION 3.3) |
| Tipe sepeda (3 model) dirender dari kode | 3 × 15 animasi | Memerlukan model baru di `loper.py` |
| Kosmetik sepeda (stiker, bel, warna) | sekitar 12 | Palette swap |
| Ikon milestone tingkat tiga, julukan | sekitar 20 | |
| Layar lemari baju dan toko kosmetik | 2 layar | Memakai gambar full body |
| Layar hasil mode bebas | 1 | Tanpa setoran |
| Overlay musiman tambahan (hajatan, pasar kaget) | sekitar 8 | |
| Audio | Musik akhir pekan bila diputuskan; suara kosmetik | 5–8 |

**Selesai kalau.** Pemain bisa bermain tanpa batas di save yang sama dengan tujuan jelas (milestone, kosmetik, sepeda).

---

### Fase 14 — Rilis (M5)

| Bidang | Pekerjaan | Catatan |
|---|---|---|
| **Iklan hadiah** | `AdService` membungkus plugin; tombol di hasil dan bengkel, tanpa iklan paksa | Kandidat plugin untuk Godot 4: *Poing Studios godot-admob-android* (mendukung rewarded, dipelihara untuk Godot 4). Cek kompatibilitas dengan versi Godot terpilih dan target API 36 **sebelum** Fase 6A mengandalkannya |
| Consent | Formulir persetujuan iklan sesuai wilayah | Bergantung ❓ target usia |
| **Hapus iklan** | Pembelian sekali bayar | ❓ GDD 14.3; bila dipakai, perlu plugin penagihan Google Play untuk Godot |
| Kebijakan | Kebijakan privasi, Data Safety, rating konten | Bergantung ❓ target usia dan pasar (ROADMAP 2 no. 13) |
| Play Console | Target API 36, AAB, tanda tangan rilis, ikon, feature graphic, tangkapan layar landscape, deskripsi | Aset toko jangan ditinggal sampai minggu terakhir (ART_DIRECTION 8 tahap 5) |
| Uji tertutup | Syarat jumlah penguji dan lama uji untuk akun baru **dicek di Play Console** saat itu | Jadwalkan paling lambat sebelum Fase 12 selesai |
| Performa | Profil di HP kelas bawah; fill rate, draw call, ukuran APK, suhu | 3.7 |
| Aksesibilitas | Mode bantu, opsi kidal, ukuran teks, kontras, tanpa ketergantungan warna atau suara | DESIGN_SPEC 1.1, SOUND_DESIGN 1 |
| Lokalisasi | Bahasa Indonesia; Bahasa Inggris bila diputuskan | Teks sudah berbasis kunci sejak Fase 4 |
| Analitik dan crash | Opsional; dicatat di kebijakan privasi | |

**Aset materi rilis**

| Aset | Jumlah |
|---|---|
| Ikon aplikasi final (adaptif) | 1 set |
| Feature graphic | 1 |
| Tangkapan layar landscape (rute, koran, bengkel, adegan) | 6–8 |
| Video pratinjau pendek (opsional) | 1 |
| Teks deskripsi Indonesia (dan Inggris) | 2 |

**Selesai kalau.** Lolos review Play Console dan uji tertutup tanpa masalah besar.

---

## 7. Peta cerita ke fase dan aset

| Bab | Hari | Fase | Distrik | Misi baru | Template baru | Potret baru | Latar adegan | Dunia berubah |
|---|---|---|---|---|---|---|---|---|
| Prolog | 1 | 4, 7 | Perumahan | P1 kucing | Cari | Fajar, Ayah, Pak Darto, Bu Ratmi | rumah Fajar, agen koran | — |
| 1 | 1–20 | 7 | Perumahan | P2, P3 | Antar khusus, Kejar | — | (pakai ulang) | Bengkel terbuka |
| 2 | 21–40 | 8 | Perkampungan | K1, K2, K3 | Kumpul | Ibu, Adik, Pak RT | rumah gang | Setoran Keluarga naik (darurat) |
| 3 | 41–60 | 9 | Ruko | R1, R2, R3 | Jaga, Lempar khusus | Dimas, pemilik toko kue | keberangkatan Dimas (opsional) | Tawaran kurir online |
| 4 | 61–80 | 10 | Pasar | M1, M2, M3 | — | pedagang unggas, pedagang ikan | lapak Ibu | `pasar_ramai` |
| 5 | 81–100 | 11 | Desa | D1, D2, D3 | — | Pak Sarmin | sawah panen | Setoran Keluarga turun |
| 6 | 101–120 | 12 | Sungai | S1, S2, S3 | — | Pak Ujang | sungai pasang, loket (3), epilog | Tujuh Belasan, air pasang |

Ketiga hasil akhir dan epilog memakai potret dan latar yang sama; tidak ada aset tambahan di luar tabel.

## 8. Rekap jumlah aset (kasar)

Mengikuti pola `ART_DIRECTION.md` 10; angka adalah perkiraan untuk perencanaan, bukan target.

| Fase | Aset gambar baru (perkiraan) | Aset cerita (potret, latar, UI) | Audio baru |
|---|---|---|---|
| 0–2 | sekitar 15 | 0 | sekitar 10 |
| 3–5 | sekitar 60 (kolom M2) | UI HUD dan layar dasar sekitar 15 | sekitar 15 |
| 6A–7 | sisa M3 sekitar 60 | UI cerita sekitar 25, potret 12, latar 2 | sekitar 25 |
| 8 | sekitar 55 | potret 8, latar 1–2 | sekitar 10 |
| 9 | sekitar 55 | potret 6, latar 0–1 | sekitar 10 |
| 10 | sekitar 55 | potret 5, latar 1, ilustrasi koran 4 | sekitar 10 |
| 11 | sekitar 55 | potret 4, latar 1 | sekitar 10 |
| 12 | sekitar 60 (+ overlay 12) | potret 8, latar 5, layar 4 | sekitar 10 |
| 13 | render ulang pemain dan sepeda (otomatis) + sekitar 40 | layar 3 | sekitar 8 |
| 14 | materi toko sekitar 10 | — | — |

Perkiraan total: **sekitar 480 aset game** (ART_DIRECTION 10) **ditambah sekitar 80 aset cerita** (sekitar 43 potret, 11 latar adegan, 25 elemen UI cerita) yang belum dihitung di sana, jadi sekitar 560. Audio kira-kira 110 file, dengan anggaran ukuran yang perlu ditetapkan ulang di Fase 13 (anggaran 10 MB di SOUND_DESIGN hanya untuk M3).

## 9. Risiko dan keputusan terbuka

### 9.1 Risiko utama

| Risiko | Dampak | Penangkal |
|---|---|---|
| **Jumlah aset** (sekitar 560) untuk proyek solo | Penyebab paling umum game mangkrak (ART_DIRECTION 10) | Pemain dirender dari kode, rumah modular, variasi lewat palette swap, distrik baru hanya setelah perumahan terbukti seru; pertimbangkan rilis bertahap (❓) |
| **Ekonomi cerita**: rata-rata 400 koin per hari menuntut misi dan tip hampir tiap hari, sedangkan rute dasar 300–375 | Akhir "Mandiri" terlalu sulit, atau tabungan tidak mencapai target di hari 120 | `sim_ekonomi.gd` di Fase 6B; tombol `HARI_CERITA_PER_HARI_RUTE`; angka disetel di prototype |
| **Saldo bengkel kecil**: 15% dari 400 koin sekitar 60 per hari, sedangkan upgrade 500–800 koin dan syarat distrik menuntut upgrade | Syarat Ruko dan Desa tidak terkejar | Cek di simulasi; usulan alternatif: upgrade pertama lebih murah atau subsidi dari Pak Darto |
| **Panjang cerita** sekitar 10 jam | Pemain berhenti di tengah | Playtest penuh di Fase 12, kompres lewat `HARI_CERITA_PER_HARI_RUTE` |
| **Shader warna bayangan di renderer Compatibility** | Bayangan berwarna tidak jalan di HP murah | Uji di Fase 0 dan Fase 7, sebelum aset distrik dibuat |
| **Gang berkelok vs segmen lurus** | Perkampungan terasa sama dengan perumahan, atau kamera bermasalah | Spike graybox di awal Fase 8 |
| **Plugin iklan dan target API 36** | Iklan sebagai satu-satunya pemasukan tidak bisa dipasang | Cek plugin di Fase 0 pada versi Godot terpilih, bukan di Fase 14 |
| **Kontrol di HP asli** | Seluruh game bergantung pada stick dan swipe | Uji Fase 1 dan 2 dengan 3–5 orang |
| **Volume penulisan** (sekitar 200 teks cerita, 120 headline, 18 misi) | Konten tertinggal dari kode | Jadwalkan penulisan per fase bab, bukan di akhir; cek panjang otomatis lewat tes |
| **Target usia belum diputuskan** | Memengaruhi iklan, humor, dan tema (PHK, keuangan keluarga) | Putuskan sebelum naskah Prolog final |

### 9.2 Daftar keputusan terbuka dan batas waktunya

| Keputusan | Dibutuhkan sebelum | Usulan awal |
|---|---|---|
| Nama package Android | Fase 0 | — |
| Versi Godot dan stretch mode | Fase 0 | Godot 4.7.x; bandingkan dua cara (ART_DIRECTION 7) |
| HP uji (merek dan kelas) | Fase 0 | Tanya Ronggur HP yang dipakai |
| Skala piksel (×3/×4) dan ubin 64×32 | Akhir Fase 1 | ×3, 64×32 |
| Jendela: bonus atau penalti | Fase 2 | Netral dulu |
| Tampilan rumah sisi dekat | Akhir Fase 3 (paling lambat sebelum Fase 8) | Uji tiga pendekatan di graybox |
| Nama koran dan nama agen Pak Darto | Fase 4 | — |
| Misi lintas hari | Fase 4 | Tidak (satu hari satu misi) |
| Penanda reputasi: bintang atau angka | Fase 6A | Angka bulat 0–100 |
| `PORSI_KELUARGA_MIN`, laju reputasi | Fase 6B | Hitung lewat simulasi |
| Apakah saldo bengkel bisa ditambah dari tabungan | Fase 6B | Tidak |
| Pemain memilih distrik tiap hari atau urutan tetap | Fase 6B | Pilih dari peta distrik; bab maju oleh kalender |
| Musik atau hanya ambience | Fase 7 | Ambience saja; musik ringan di koran, hasil, bengkel |
| Nama kota atau lingkungan (menggantikan "Melati" di mock) | Fase 7 | — |
| Target usia dan pasar | Fase 7 | Perlu keputusan, bukan usulan |
| Hari cerita 120 terasa pas atau dikompres | Fase 7 (playtest 20 hari) | Tetap 120 |
| Isi pilihan akhir bab untuk bab 2–6, terutama efek pilihan Bab 3 (kurir online) | Sebelum naskah tiap bab | Selaras dengan STORY 4 |
| Gang berkelok sebagai zigzag lateral | Awal Fase 8 | Zigzag |
| Mekanik "tahun kedua" (target, kalender, tabungan terbawa) | Fase 12 | Siklus baru dengan target dikurangi tabungan terbawa |
| Distrik otomatis terbuka setelah tamat | Fase 13 | Ya |
| Hapus iklan sekali bayar | Fase 13, rencana plugin sebelum Fase 14 | — |
| Bahasa Inggris | Fase 6B (kunci teks), Fase 14 | Teks berbasis kunci, terjemahan menyusul |
| Sprite pemain dipoles manual | Fase 5 | Tidak, kecuali wajah depan |
| Font HUD final | Fase 5 | Lexend + Lilita One |
| Rilis bertahap (misalnya setelah Bab 3) | Setelah Fase 9 | Pertimbangkan |

## 10. Ketidakcocokan antar dokumen yang ditemukan

Ini bukan keputusan baru; hanya hal yang perlu disamakan setelah dokumen ini disetujui.

| # | Temuan | Perlu diperbarui |
|---|---|---|
| 1 | `ART_DIRECTION.md` 3.1 menyebut pemain sekitar **18–20 tahun**, sedangkan `STORY.md` mengunci **17–18 tahun** | Samakan teks; sprite tidak perlu dirender ulang |
| 2 | `CONTENT_GUIDE.md` 8 masih menanyakan nama pemain; `STORY.md` sudah mengunci **Fajar Sidik** | Tutup pertanyaan; tambah Fajar, Ayah, Ibu, Adik, Pak Darto, Dimas ke tabel tokoh (bagian 7) |
| 3 | `GDD.md` 3.2 dan `ROADMAP.md` 5 menyebut "game over atau tidak" masih terbuka, sedangkan `STORY.md` 4 mengusulkan **tanpa game over** | Perbarui setelah usulan disetujui |
| 4 | `BALANCING.md` 7 menyebut pemasukan 300–375 koin per hari rapi; `STORY.md` 4.1 memakai rata-rata sekitar 400 koin termasuk tip dan misi | Cek lewat simulasi, tulis hasilnya di `BALANCING.md` 7.1 |
| 5 | `BALANCING.md` 7.1 menetapkan porsi setoran tetap 35/15/50; `STORY.md` Bab 2 dan Bab 5 membuat porsi Keluarga naik (darurat) dan turun (panen) | Tambah parameter di `config.gd` dan `events.json` |
| 6 | `DATA_SCHEMA.md` 4 (save v1) belum punya blok cerita; schema headline belum punya syarat `bab` | Tambahkan setelah disetujui |
| 7 | `DEV_PHASES.md` Fase 8 ("distrik berikutnya, iklan, rilis") satu kalimat | Ganti dengan Fase 8–14 dokumen ini |
| 8 | `ROADMAP.md` M4 satu milestone untuk seluruh konten dan rilis | Pecah jadi M4 dan M5 |
| 9 | `GDD.md` 9.5 menanyakan kejadian musiman mengikuti tanggal nyata atau diatur game | Fase Cerita memakai kalender cerita (sudah pasti); Fase Bebas diatur game (usulan) |
| 10 | `DESIGN_SPEC.md` 4 menandai "Peta distrik" bergantung keputusan distrik bebas dipilih; `STORY.md` 7 sudah menyebut peta dengan syarat bercentang | Naikkan jadi layar wajib di Fase 6B |
| 11 | `DESIGN_SPEC.md` 6 memuat placeholder "HARI 3 · MELATI" | Ganti setelah nama lingkungan ditetapkan |
| 12 | `STORY.md` 4.1 menyebut 120 hari dari 20 April sampai 18 Agustus. Kalau hari 1 = 20 April, hari 120 jatuh pada 17 Agustus, bukan 18 Agustus | Dokumen ini memakai: hari rute 1–120 = 20 April–17 Agustus (hari ke-120 = Tujuh Belasan), 18 Agustus = hari daftar ulang untuk adegan akhir. Konfirmasi atau sesuaikan `STORY.md` |

## 11. Langkah berikutnya

1. **Baca dan koreksi dokumen ini.** Terutama pemecahan Fase 6A/6B, pemetaan bab ke fase, dan daftar keputusan terbuka.
2. **Bila disetujui ("masukkan")**: perbarui `DEV_PHASES.md`, `ROADMAP.md`, `README.md` (daftar dokumen), `DATA_SCHEMA.md`, dan tabel tokoh di `CONTENT_GUIDE.md`, serta ketidakcocokan di bagian 10.
3. **Mulai Fase 0.** Dibutuhkan dari Ronggur: nama package Android, HP yang dipakai untuk uji, dan versi Godot yang dipasang.

## Sumber

Hal di luar dokumen project (dicek 7 Oktober 2026; dicek ulang saat Fase 0 dan Fase 14 karena cepat berubah):

- [Godot Engine: daftar rilis](https://godotengine.org/blog/release) (rilis pemeliharaan seri 4.6 dan 4.7)
- [Google Play: persyaratan target API level](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en-419) (app baru dan update harus menargetkan Android 16, API 36)
- [Poing Studios: godot-admob-android](https://github.com/poingstudios/godot-admob-android) (plugin AdMob untuk Godot, mendukung iklan hadiah)
