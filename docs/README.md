# Kring Kring! (Loper Koran)

> **Judul game: Kring Kring!** (diputuskan 2026-10-09; dari bunyi bel sepeda). "Loper Koran" tetap dipakai sebagai nama kerja, nama repo, dan nama folder. Usulan subjudul berbahasa Inggris untuk pemain luar negeri (misalnya *Paper Route Stories*) belum diputuskan.

Judul game: **Kring Kring!** (diputuskan 2026-10-09, GDD 5.4). "Loper Koran" adalah nama kerja repo dan dokumen.

Game 2D mobile (Android) bergaya Paperboy modern: pemain mengayuh sepeda menyusuri jalan isometrik sambil melempar koran ke rumah pelanggan, dengan latar Indonesia, kecepatan yang diatur sendiri, dan isi koran yang ikut mengubah dunia.

Status: **Fase 0 dan Fase 1 selesai, Fase 2 berikutnya** (per 2026-10-14). Desain inti, kamera, kontrol, dan karakter pemain sudah dikunci. Project Godot 4.7.2 dibuat di run 0A (Fase 0): layar 640×360 dengan skala bulat, `scripts/config.gd`, `scripts/ui/palette.gd`, sprite pemain Kemeja Agen dengan pemilih animasinya, ubin graybox, tes headless, dan CI. Run 0B menambah input touch (stick melayang, swipe, opsi kidal, keyboard editor), sepeda placeholder yang bergerak di jalan uji tanpa ujung, HUD kecepatan sementara, dan terjemahan `translations/ui.csv`. Run 0C menambah preset export Android (`export_presets.cfg`, tanpa Gradle) dan panduan [`SETUP_ANDROID.md`](./SETUP_ANDROID.md) untuk membangun APK debug. Run kecil `sprite-lempar-melambat` (2026-10-09) memasang sprite melambat (stick bawah) dan lempar koran (swipe horizontal) ke jalan uji sebagai animasi saja, tanpa proyektil atau skor (Fase 2). Uji HP di A54 lolos 2026-10-13, jadi Fase 0 dan M0 selesai; fase aktif sekarang Fase 1. Run 1A (2026-10-13, PR #20, sudah di-merge) mengganti gerak placeholder dengan `BikeMotion`: rem tanpa tombol, meluncur, stamina dan lelah, batas tepi jalan resmi, jeda saat app di-background, laju kayuh mengikuti kecepatan, sprite meluncur dan rem terpasang, bar stamina dan cincin rem di HUD; rasa kontrolnya belum dinilai di HP (gerak sepeda dan kecepatan, [`DEV_PHASES.md`](./DEV_PHASES.md)). Run 1B (2026-10-14, PR #21, sudah di-merge) menambah tombol dan layar jeda tanpa lanjut otomatis (juga untuk back Android dan background), debu roda dan garis kecepatan dari kode, bunyi placeholder kayuhan/freewheel/rem lewat autoload `Audio` (dibuat skrip sintesis `tools/audio_art/`), penyetelan paket A54 (sepeda 75% tinggi layar, dorongan 36, tombol 42 px, teks HUD 8 px), probe render Compatibility `scenes/dev/cek_render.tscn` (light 2D, glow, partikel CPU/GPU, shader warna bayangan; lolos di desktop, A54 belum), dan checklist uji 3-5 orang Fase 1 ([`SETUP_ANDROID.md`](./SETUP_ANDROID.md) 8.2). Run 1C (PR #23) merapikan temuan Run 1B. Uji HP Fase 1 dilakukan pemilik sendiri (keputusan 2026-10-14, semula 3-5 orang) dan dinyatakan oke 2026-10-14, jadi Fase 1 selesai. Posisi lengkap ada di [`ROADMAP.md`](./ROADMAP.md).

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
| [`SETUP_ANDROID.md`](./SETUP_ANDROID.md) | Export Android tanpa Gradle: prasyarat mesin, preset `export_presets.cfg` beserta alasannya, ekspor APK debug dari CLI, pemeriksaan isi APK, pasang ke HP, probe render di HP (6.1), checklist uji M0 dan uji 3-5 orang Fase 1 (8.2) |
| [`LOOP-DEV-QA.md`](./LOOP-DEV-QA.md) | Brief loop dua agent (Dev dan QA) untuk mengerjakan fase development, dengan Fase 0 dipecah jadi run 0A–0C dan perintah tempel untuk memulai run Fase 1 (Bagian 6b) |
| [`loop/`](./loop/) | Satu folder per run loop (`<RUN_ID>/`): `SPEC.md` (kontrak run), `LOG.md` (temuan dan keputusan), `shots/` (tangkapan layar bukti) |
| [`design/`](./design/) | [`DESIGN_SPEC.md`](./design/DESIGN_SPEC.md): token warna, font, dan spesifikasi HUD; `screens/` dan `source/`: render dan source mock HUD dan kontrol; [`character/`](./design/character/): indeks semua karakter; [`character/loper_agen/`](./design/character/loper_agen/): sprite produksi pemain; [`character/varian/`](./design/character/varian/): varian baju |

Sumber visual:

- Kanvas **"Loper Koran — Kamera dan Kontrol"**: isometrik 2:1, kontrol landscape, HUD, banding arah jalan.
- Kanvas **"Karakter Loper Koran"**: eksplorasi karakter, base model Kemeja Agen 5 arah, pose kecepatan, sprite produksi.
- Acuan gaya: proyek Brainy Dungeon (hanya acuan gaya, bukan aset bersama).

## Struktur project

Mengikuti pola Brainy Dungeon: root repo git `loper-koran` sekaligus root project Godot. Dokumen desain ada di `docs/`, yang diabaikan Godot lewat `docs/.gdignore`. Struktur dibangun bertahap di Fase 0: bagian bertanda **(ada)** sudah dibuat di run 0A dan 0B, sisanya masih rencana.

```
AGENTS.md, CLAUDE.md   Pintu masuk agent coding (ada)
docs/                  Dokumen desain (folder ini) + design/ + loop/ (ada)
project.godot          Godot 4.7.2, landscape, renderer Compatibility, 640x360 canvas_items integer expand (ada)
icon.svg               Ikon aplikasi sementara, dipakai ekspor Android (ada)
export_presets.cfg     Preset export Android: satu preset, tanpa Gradle, arm64-v8a, tanpa rahasia (ada)
scenes/                dev/jalan_uji.tscn (scene utama sementara), dev/graybox.tscn, dev/cek_render.tscn (probe render, hanya build probe), entities/loper_agen.tscn, sepeda_uji.tscn, umpan_balik_sepeda.tscn, ui/hud_dev.tscn, ui/layar_jeda.tscn (ada); Boot, Rute, Koran, Hasil, Bengkel menyusul
assets/sprites/        loper/ dan _placeholder/ (ada); tiles/, houses/, props/, obstacles/, vfx/, ui/ menyusul
assets/palette/        loper_master.gpl (ada)
assets/fonts/          Lexend dan Lilita One, usulan (ada)
assets/audio/          sfx/bike/ tiga WAV placeholder hasil tools/audio_art/ + LICENSES.md (ada); ambience, SFX lain menyusul
assets/shaders/        warna_bayangan.gdshader, usulan (ada)
default_bus_layout.tres Bus audio Master -> SFX -> Sepeda (ada)
assets/ui/             theme.tres: font dan ukuran saja, warna dari Palette (ada); panel 9-slice menyusul
translations/          ui.csv (keys,id) + hasil impor .translation; semua teks pemain lewat kunci (ada)
assets/LICENSES.md     Lisensi aset pihak ketiga (ada)
assets/data/           Segmen rute, misi, headline (DATA_SCHEMA.md), menyusul
scripts/config.gd      SEMUA angka tuning (BALANCING.md) (ada)
scripts/autoload/      audio.gd (autoload Audio, bunyi sepeda) (ada); SaveManager, DayManager menyusul
scripts/systems/       Logika murni: config_parser, loper_anim, iso, touch_zones, stick_map, touch_router, bike_motion (gerak, rem, stamina, lateral), jeda_sim, dorongan_kecepatan, jalan_daur, piksel_lingkaran, lempar_waktu, umpan_balik_kecepatan, bunyi_sepeda (ada); lemparan, skor, misi, reputasi, kerusakan menyusul
scripts/entities/      loper_sprite, sepeda_uji, jalan_uji, tanah_daur, objek_daur, pancaran_piksel, umpan_balik_sepeda (ada)
scripts/dev/           cek_render.gd (probe render Compatibility) (ada)
scripts/ui/            palette, kontrol_touch, hud_dev, bar_kecepatan, gaya_hud, tombol_jeda, tombol_sentuh, layar_jeda (ada); HUD final dan layar menyusul
tests/                 run_tests.gd, tes_input_murni.gd, tes_input_scene.gd, tes_sprite.gd, tes_gerak.gd, tes_gerak_scene.gd, tes_jeda_scene.gd, tes_tata_letak.gd, tes_umpan_balik.gd, tes_bunyi.gd, tes_cek_render.gd, tes_export.gd, probe_layar.gd, probe_*_jendela.gd (ada)
tools/loper_art/       Renderer sprite pemain (Python), lihat ART_DIRECTION bagian 4; bangun_frames.py membangun SpriteFrames gabungan 48 animasi (stdlib)
tools/env_art/         Renderer aset lingkungan, termasuk graybox.py (ada)
tools/audio_art/       sintesis_sepeda.py: bunyi placeholder sepeda dari rumus (stdlib) (ada)
tools/                 cek_keluaran_tes.py, cek_blok_piksel.py, ekspor_cek_render.py (build probe render), tests_cek/ (uji_pemeriksa, uji_bangun_frames, uji_sintesis_sepeda) (ada)
.github/workflows/     tes.yml, CI import dan tes headless (ada)
builds/                APK hasil export, perintah di SETUP_ANDROID.md (di .gitignore, tidak di-commit)
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
