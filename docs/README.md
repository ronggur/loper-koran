# Loper Koran

Game 2D mobile (Android) bergaya Paperboy modern: pemain mengayuh sepeda menyusuri jalan isometrik sambil melempar koran ke rumah pelanggan, dengan latar Indonesia, kecepatan yang diatur sendiri, dan isi koran yang ikut mengubah dunia.

Status: **Pra-produksi** (per 2026-10-07). Desain inti, kamera, kontrol, dan karakter pemain sudah dikunci. Sprite produksi pemain (Kemeja Agen, 15 animasi kayuh) sudah jadi dan sudah dicek di Godot 4.3. Project Godot belum dibuat; langkah berikutnya adalah Fase 0 di [`DEV_PHASES.md`](./DEV_PHASES.md). Posisi lengkap ada di [`ROADMAP.md`](./ROADMAP.md).

## Dokumen

| File | Isi |
|---|---|
| [`ROADMAP.md`](./ROADMAP.md) | Status kesiapan, milestone M0–M4, keputusan yang masih terbuka |
| [`DEV_PHASES.md`](./DEV_PHASES.md) | Fase development dengan checklist, mengikuti urutan prototype 1–4 |
| [`GDD.md`](./GDD.md) | Game design document: core loop, kontrol, distrik, misi, sepeda, ekonomi, milestone |
| [`ART_DIRECTION.md`](./ART_DIRECTION.md) | Art bible: aturan pixel art isometrik, palet, kamera, karakter, daftar aset, spesifikasi teknis |
| [`BALANCING.md`](./BALANCING.md) | Angka tuning awal (kecepatan, stamina, lemparan, skor, ekonomi) dan cara mengubahnya |
| [`ROUTE_DESIGN.md`](./ROUTE_DESIGN.md) | Panduan menyusun rute dari segmen: ukuran, jalur, penempatan rumah dan rintangan, aturan adil |
| [`CONTENT_GUIDE.md`](./CONTENT_GUIDE.md) | Panduan menulis headline koran, misi sampingan, dan nama tokoh |
| [`DATA_SCHEMA.md`](./DATA_SCHEMA.md) | Format data misi, headline, segmen rute, dan file save (usulan) |
| [`SOUND_DESIGN.md`](./SOUND_DESIGN.md) | Prinsip audio, daftar efek suara, ambience per distrik, spesifikasi teknis (draf) |
| [`design/`](./design/) | [`DESIGN_SPEC.md`](./design/DESIGN_SPEC.md): token warna, font, dan spesifikasi HUD; `screens/` dan `source/`: render dan source mock HUD dan kontrol; [`character/loper_agen/`](./design/character/loper_agen/): sprite produksi pemain |

Sumber visual:

- Kanvas **"Loper Koran — Kamera dan Kontrol"**: isometrik 2:1, kontrol landscape, HUD, banding arah jalan.
- Kanvas **"Karakter Loper Koran"**: eksplorasi karakter, base model Kemeja Agen 5 arah, pose kecepatan, sprite produksi.
- Acuan gaya: proyek Brainy Dungeon (hanya acuan gaya, bukan aset bersama).

## Struktur project (usulan)

Mengikuti pola Brainy Dungeon: root repo git `loper-koran` sekaligus root project Godot. Dokumen desain ada di `docs/`, yang diabaikan Godot lewat `docs/.gdignore`. Struktur di bawah adalah rencana; dibuat di Fase 0.

```
AGENTS.md, CLAUDE.md   Pintu masuk agent coding
docs/                  Dokumen desain (folder ini) + design/
project.godot          Godot 4 (minimal 4.3), landscape, renderer Compatibility (usulan, dicek di Fase 0)
export_presets.cfg     Preset export Android
scenes/                Boot, Rute (gameplay), Koran (halaman depan), Hasil, Bengkel, dev/
assets/sprites/        loper/ (pemain), tiles/, houses/, props/, obstacles/, vfx/, ui/
assets/data/           Segmen rute, misi, headline (DATA_SCHEMA.md)
scripts/config.gd      SEMUA angka tuning (BALANCING.md)
scripts/autoload/      SaveManager, DayManager, Analytics (nanti)
scripts/systems/       Logika murni: gerak sepeda, lemparan, skor, misi, reputasi, kerusakan
scripts/ui/            HUD, layar, palette.gd
tests/                 Tes logika headless
tools/loper_art/       Renderer sprite pemain (Python), lihat ART_DIRECTION bagian 4
builds/                APK hasil export (tidak di-commit)
```

Path seperti `scripts/config.gd` atau `tools/loper_art/produce.py` di dokumen lain selalu relatif terhadap root repo.

## Keputusan yang sudah dikunci

- **Platform**: mobile Android, layar **landscape** dipegang dua tangan (GDD 5).
- **Engine**: **Godot 4** dengan GDScript (GDD 16).
- **Kamera**: **isometrik 2:1**, jalan naik ke **kanan atas**, sepeda di sepertiga kiri layar, cahaya dari kiri atas (ART_DIRECTION 2.2).
- **Dua sisi jalan**: kiri pelempar = **sisi seberang** (fasad rumah, kiri atas layar), kanan pelempar = **sisi dekat** (kanan bawah). Kiri dan kanan selalu mengikuti arah pelempar, bukan arah layar (GDD 4.2).
- **Kontrol**: stick melayang di kiri bawah (atas kayuh keras, netral santai, bawah melambat, tarik penuh dan tahan = rem, kiri/kanan = ke sisi seberang/dekat), swipe di kanan untuk melempar. Tanpa tombol rem terpisah. Mode bantu dan opsi kidal (GDD 5).
- **Tujuan**: gabungan pelanggan, uang, dan cerita. Distrik terbuka bertahap lewat reputasi. Co-op dibuang (GDD 3).
- **Mode**: tanpa endless run dan daily challenge; gantinya milestone tiga tingkat (GDD 13).
- **Sepeda**: komponen bisa aus atau rusak dan hanya diperbaiki di bengkel setelah mengantar (GDD 12).
- **Ekonomi**: satu mata uang (koin), tanpa gems. Pemasukan dari iklan hadiah opsional, tanpa iklan paksa (GDD 14).
- **Gaya visual**: pixel art isometrik dengan acuan gaya Brainy Dungeon, dimodernkan lewat lighting, partikel, dan color grading (ART_DIRECTION 2).
- **Karakter pemain**: **Kemeja Agen** tanpa tas selempang, 5 arah × 3 kecepatan; varian baju lain disimpan untuk item (ART_DIRECTION 3).
- **Sumber utama desain**: `docs/GDD.md` di repo ini; dokumen Claude Docs jadi arsip (2026-10-07).

Keputusan yang masih terbuka ada di `ROADMAP.md` bagian 5.

## Hubungan dengan dokumen lain

- **`GDD.md` di repo adalah sumber utama desain** (diputuskan 2026-10-07). Dokumen Claude Docs **"Loper Koran — Ide Pengembangan Game"** adalah asalnya dan sekarang menjadi arsip: perubahan desain ditulis di `GDD.md` dan dokumen lain di folder ini, tidak di Claude Docs.
- Aturan main untuk Claude di project claude.ai "Game - Loper koran" (`instruksi-project.md`) tetap berlaku: ide baru masuk `GDD.md` setelah disetujui, dan hal yang belum diuji ditandai **usulan**.
