# Kring Kring! (Loper Koran)

> **Judul game: Kring Kring!** (diputuskan 2026-10-09; dari bunyi bel sepeda). "Loper Koran" tetap dipakai sebagai nama kerja, nama repo, dan nama folder. Usulan subjudul berbahasa Inggris untuk pemain luar negeri (misalnya *Paper Route Stories*) belum diputuskan.

Judul game: **Kring Kring!** (diputuskan 2026-10-09, GDD 5.4). "Loper Koran" adalah nama kerja repo dan dokumen.

Game 2D mobile (Android) bergaya Paperboy modern: pemain mengayuh sepeda menyusuri jalan isometrik sambil melempar koran ke rumah pelanggan, dengan latar Indonesia, kecepatan yang diatur sendiri, dan isi koran yang ikut mengubah dunia.

Status: **Pra-produksi, Fase 0 berjalan** (per 2026-10-09). Desain inti, kamera, kontrol, dan karakter pemain sudah dikunci. Project Godot 4.7.2 dibuat di run 0A (Fase 0): layar 640×360 dengan skala bulat, `scripts/config.gd`, `scripts/ui/palette.gd`, sprite pemain Kemeja Agen dengan pemilih animasinya, ubin graybox, tes headless, dan CI. Input touch (run 0B) serta export Android dan APK di HP (run 0C) belum dikerjakan; Fase 0 baru selesai setelah APK diuji di HP ([`DEV_PHASES.md`](./DEV_PHASES.md)). Posisi lengkap ada di [`ROADMAP.md`](./ROADMAP.md).

## Dokumen

| File | Isi |
|---|---|
| [`ROADMAP.md`](./ROADMAP.md) | Status kesiapan, milestone M0–M4, keputusan yang masih terbuka |
| [`DEV_PHASES.md`](./DEV_PHASES.md) | Fase development dengan checklist, mengikuti urutan prototype 1–4 |
| [`GDD.md`](./GDD.md) | Game design document: core loop, kontrol, distrik, misi, sepeda, ekonomi, milestone |
| [`STORY.md`](./STORY.md) | Cerita utama: premis, tokoh, timeline bab per distrik, syarat membuka distrik, tiga akhir, Fase Bebas, status pelacakan |
| [`ART_DIRECTION.md`](./ART_DIRECTION.md) | Art bible: aturan pixel art isometrik, palet, kamera, karakter, daftar aset, spesifikasi teknis |
| [`BALANCING.md`](./BALANCING.md) | Angka tuning awal (kecepatan, stamina, lemparan, skor, ekonomi) dan cara mengubahnya |
| [`ROUTE_DESIGN.md`](./ROUTE_DESIGN.md) | Panduan menyusun rute dari segmen: ukuran, jalur, penempatan rumah dan rintangan, aturan adil |
| [`CONTENT_GUIDE.md`](./CONTENT_GUIDE.md) | Panduan menulis headline koran, misi sampingan, dan nama tokoh |
| [`DATA_SCHEMA.md`](./DATA_SCHEMA.md) | Format data misi, headline, segmen rute, dan file save (usulan) |
| [`SOUND_DESIGN.md`](./SOUND_DESIGN.md) | Prinsip audio, daftar efek suara, ambience per distrik, spesifikasi teknis (draf) |
| [`LOOP-DEV-QA.md`](./LOOP-DEV-QA.md) | Brief loop dua agent (Dev dan QA) untuk mengerjakan fase development, dengan Fase 0 dipecah jadi run 0A–0C |
| [`loop/`](./loop/) | Satu folder per run loop (`<RUN_ID>/`): `SPEC.md` (kontrak run), `LOG.md` (temuan dan keputusan), `shots/` (tangkapan layar bukti) |
| [`design/`](./design/) | [`DESIGN_SPEC.md`](./design/DESIGN_SPEC.md): token warna, font, dan spesifikasi HUD; `screens/` dan `source/`: render dan source mock HUD dan kontrol; [`character/`](./design/character/): indeks semua karakter; [`character/loper_agen/`](./design/character/loper_agen/): sprite produksi pemain; [`character/varian/`](./design/character/varian/): varian baju |

Sumber visual:

- Kanvas **"Loper Koran — Kamera dan Kontrol"**: isometrik 2:1, kontrol landscape, HUD, banding arah jalan.
- Kanvas **"Karakter Loper Koran"**: eksplorasi karakter, base model Kemeja Agen 5 arah, pose kecepatan, sprite produksi.
- Acuan gaya: proyek Brainy Dungeon (hanya acuan gaya, bukan aset bersama).

## Struktur project

Mengikuti pola Brainy Dungeon: root repo git `loper-koran` sekaligus root project Godot. Dokumen desain ada di `docs/`, yang diabaikan Godot lewat `docs/.gdignore`. Struktur dibangun bertahap di Fase 0: bagian bertanda **(ada)** sudah dibuat di run 0A, sisanya masih rencana.

```
AGENTS.md, CLAUDE.md   Pintu masuk agent coding (ada)
docs/                  Dokumen desain (folder ini) + design/ + loop/ (ada)
project.godot          Godot 4.7.2, landscape, renderer Compatibility, 640x360 canvas_items integer expand (ada)
export_presets.cfg     Preset export Android (run 0C)
scenes/                dev/graybox.tscn dan entities/loper_agen.tscn (ada); Boot, Rute, Koran, Hasil, Bengkel menyusul
assets/sprites/        loper/ dan _placeholder/ (ada); tiles/, houses/, props/, obstacles/, vfx/, ui/ menyusul
assets/palette/        loper_master.gpl (ada)
assets/fonts/          Lexend dan Lilita One, usulan (ada)
assets/LICENSES.md     Lisensi aset pihak ketiga (ada)
assets/data/           Segmen rute, misi, headline (DATA_SCHEMA.md), menyusul
scripts/config.gd      SEMUA angka tuning (BALANCING.md) (ada)
scripts/autoload/      SaveManager, DayManager, Analytics (nanti)
scripts/systems/       Logika murni: config_parser, loper_anim (ada); gerak sepeda, lemparan, skor, misi, reputasi, kerusakan menyusul
scripts/entities/      loper_sprite.gd (ada)
scripts/ui/            palette.gd (ada); HUD dan layar menyusul
tests/                 run_tests.gd, probe_layar.gd, probe_layar_jendela.gd (ada)
tools/loper_art/       Renderer sprite pemain (Python), lihat ART_DIRECTION bagian 4
tools/env_art/         Renderer aset lingkungan, termasuk graybox.py (ada)
tools/                 cek_keluaran_tes.py dan tests_cek/ (ada)
.github/workflows/     tes.yml, CI import dan tes headless (ada)
builds/                APK hasil export (tidak di-commit)
```

Path seperti `scripts/config.gd` atau `tools/loper_art/produce.py` di dokumen lain selalu relatif terhadap root repo.

## Keputusan yang sudah dikunci

- **Platform**: mobile Android, layar **landscape** dipegang dua tangan (GDD 5).
- **Engine**: **Godot 4** dengan GDScript (GDD 16).
- **Teknis Fase 0** (2026-10-09): Godot **4.7.2**, skala piksel **×3**, base 640×360 dengan stretch `canvas_items` + integer scale + `expand`, package Android **`com.rmh.kring`** (alasan di `ROADMAP.md` 4b).
- **Kamera**: **isometrik 2:1**, jalan naik ke **kanan atas**, sepeda di sepertiga kiri layar, cahaya dari kiri atas (ART_DIRECTION 2.2).
- **Dua sisi jalan**: kiri pelempar = **sisi seberang** (fasad rumah, kiri atas layar), kanan pelempar = **sisi dekat** (kanan bawah). Kiri dan kanan selalu mengikuti arah pelempar, bukan arah layar (GDD 4.2).
- **Kontrol**: stick melayang di kiri bawah (atas kayuh keras, netral santai, bawah melambat, tarik penuh dan tahan = rem, kiri/kanan = ke sisi seberang/dekat), swipe di kanan untuk melempar. Tanpa tombol rem terpisah. Mode bantu dan opsi kidal (GDD 5).
- **Tujuan**: gabungan pelanggan, uang, dan cerita. Distrik terbuka bertahap lewat reputasi. Co-op dibuang (GDD 3).
- **Mode**: tanpa endless run dan daily challenge; gantinya milestone tiga tingkat (GDD 13).
- **Sepeda**: komponen bisa aus atau rusak dan hanya diperbaiki di bengkel setelah mengantar (GDD 12).
- **Ekonomi**: satu mata uang (koin), tanpa gems. Pemasukan dari iklan hadiah opsional, tanpa iklan paksa (GDD 14).
- **Gaya visual**: pixel art isometrik dengan acuan gaya Brainy Dungeon, dimodernkan lewat lighting, partikel, dan color grading (ART_DIRECTION 2).
- **Karakter pemain**: **Kemeja Agen**, anak muda bercelana panjang jogger, tanpa tas selempang dan tanpa keranjang depan, 5 arah × 3 kecepatan; varian baju lain disimpan untuk item (ART_DIRECTION 3).
- **Sumber utama desain**: `docs/GDD.md` di repo ini; dokumen Claude Docs jadi arsip (2026-10-07).

Keputusan yang masih terbuka ada di `ROADMAP.md` bagian 5.

## Hubungan dengan dokumen lain

- **`GDD.md` di repo adalah sumber utama desain** (diputuskan 2026-10-07). Dokumen Claude Docs **"Loper Koran — Ide Pengembangan Game"** adalah asalnya dan sekarang menjadi arsip: perubahan desain ditulis di `GDD.md` dan dokumen lain di folder ini, tidak di Claude Docs.
- Aturan main untuk Claude di project claude.ai "Game - Loper koran" (`instruksi-project.md`) tetap berlaku: ide baru masuk `GDD.md` setelah disetujui, dan hal yang belum diuji ditandai **usulan**.
