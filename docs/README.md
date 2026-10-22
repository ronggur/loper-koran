# Kring Kring! (Loper Koran)

> **Judul game: Kring Kring!** (diputuskan 2026-10-09; dari bunyi bel sepeda). "Loper Koran" tetap dipakai sebagai nama kerja, nama repo, dan nama folder. Usulan subjudul berbahasa Inggris untuk pemain luar negeri (misalnya *Paper Route Stories*) belum diputuskan.

Judul game: **Kring Kring!** (diputuskan 2026-10-09, GDD 5.4). "Loper Koran" adalah nama kerja repo dan dokumen.

Game 2D mobile (Android) bergaya Paperboy modern: pemain mengayuh sepeda menyusuri jalan isometrik sambil melempar koran ke rumah pelanggan, dengan latar Indonesia, kecepatan yang diatur sendiri, dan isi koran yang ikut mengubah dunia.

Status: **Fase 0 dan Fase 1 selesai, Fase 2 menunggu uji HP, Fase 3 (prototype 3) kode selesai (run 3A sampai 3C), Fase 4 (prototype 4) berjalan: run 4A (halaman depan koran, format misi dan headline, `HeadlineManager`, save v1, alur satu hari Koran -> Rute -> Hasil -> Hari berikutnya; satu hari tanpa misi kucing, prototype yang tidak mengunci struktur sesi) dikerjakan 2026-10-18, run 4B (`20261018-fase4b-misi-kucing`, branch `feat/misi-kucing-4b`, usulan, belum diuji di HP): misi P1 Kucing Bu Ratmi (template Cari) di rute dengan tiga kucing di rumah seberang, petunjuk dari lemparan tepat, menepi dan berhenti 1,5 detik, batas 12 rumah, hadiah 75 koin, HUD kartu dan banner, rekap di layar hasil, save v2 (flag yang dikonsumsi sesudah headline lanjutan tampil, `misi_hasil`, `tutorial`), tutorial terpandu hari 1 yang bisa dilewati, dan bunyi misi; checklist uji HP: [`SETUP_ANDROID.md`](./SETUP_ANDROID.md) 8.10; **Fase 3, Fase 4, dan M2 belum dicentang sebelum uji HP** (per 2026-10-18). Desain inti, kamera, kontrol, dan karakter pemain sudah dikunci. Project Godot 4.7.2 dibuat di run 0A (Fase 0): layar 640×360 dengan skala bulat, `scripts/config.gd`, `scripts/ui/palette.gd`, sprite pemain Kemeja Agen dengan pemilih animasinya, ubin graybox, tes headless, dan CI. Run 0B menambah input touch (stick melayang, swipe, opsi kidal, keyboard editor), sepeda placeholder yang bergerak di jalan uji tanpa ujung, HUD kecepatan sementara, dan terjemahan `translations/ui.csv`. Run 0C menambah preset export Android (`export_presets.cfg`, tanpa Gradle) dan panduan [`SETUP_ANDROID.md`](./SETUP_ANDROID.md) untuk membangun APK debug. Run kecil `sprite-lempar-melambat` (2026-10-09) memasang sprite melambat (stick bawah) dan lempar koran (swipe horizontal) ke jalan uji sebagai animasi saja, tanpa proyektil atau skor (Fase 2). Uji HP di A54 lolos 2026-10-13, jadi Fase 0 dan M0 selesai; fase aktif sekarang Fase 1. Run 1A (2026-10-13, PR #20, sudah di-merge) mengganti gerak placeholder dengan `BikeMotion`: rem tanpa tombol, meluncur, stamina dan lelah, batas tepi jalan resmi, jeda saat app di-background, laju kayuh mengikuti kecepatan, sprite meluncur dan rem terpasang, bar stamina dan cincin rem di HUD; rasa kontrolnya belum dinilai di HP (gerak sepeda dan kecepatan, [`DEV_PHASES.md`](./DEV_PHASES.md)). Run 1B (2026-10-14, PR #21, sudah di-merge) menambah tombol dan layar jeda tanpa lanjut otomatis (juga untuk back Android dan background), debu roda dan garis kecepatan dari kode, bunyi placeholder kayuhan/freewheel/rem lewat autoload `Audio` (dibuat skrip sintesis `tools/audio_art/`), penyetelan paket A54 (sepeda 75% tinggi layar, dorongan 36, tombol 42 px, teks HUD 8 px), probe render Compatibility `scenes/dev/cek_render.tscn` (light 2D, glow, partikel CPU/GPU, shader warna bayangan; lolos di desktop, A54 belum), dan checklist uji 3-5 orang Fase 1 ([`SETUP_ANDROID.md`](./SETUP_ANDROID.md) 8.2). Run 1C (PR #23) merapikan temuan Run 1B. Uji HP Fase 1 dilakukan pemilik sendiri (keputusan 2026-10-14, semula 3-5 orang) dan dinyatakan oke 2026-10-14, jadi Fase 1 selesai. Fase 2: run 2A (PR #24) memasang lemparan koran dengan garis bidik, zona sasaran placeholder, dan sisa koran; run arah bebas (PR #25) membuat koran terbang ke arah swipe di layar; run 2B (`20261015-fase2b-bantu-audio`, PR #26, belum di-merge) menambah mode bantu (tap melempar otomatis ke kotak surat pelanggan terdekat), bunyi placeholder "wus" dan mendarat empat permukaan dari `tools/audio_art/sintesis_lempar.py`, dan checklist uji HP penutup Fase 2 dan M1 ([`SETUP_ANDROID.md`](./SETUP_ANDROID.md) 8.5). Fase 2 dan M1 baru selesai sesudah uji HP pemilik. Fase 3, run 3A (`20261016-fase3a-rute`, branch `feat/fase3a-rute`, usulan, belum diuji di HP): satu rute perumahan sungguhan dari 7 segmen JSON buatan tangan (`assets/data/routes/perumahan/`, 9 segmen) yang disusun `RouteBuilder` dari seed, 25 pelanggan seberang, koran awal 30; scene utama sekarang `scenes/rute/rute.tscn` (rumah dan kotak surat dari data lewat jendela daur, zona sasaran dan mode bantu dari data rute, akhir rute dengan rem + banner "Rute selesai" + tombol dev "Main lagi", objek penutup semi-transparan lewat satu penerap), sedangkan `scenes/dev/jalan_uji.tscn` tetap scene dev; checklist uji HP: [`SETUP_ANDROID.md`](./SETUP_ANDROID.md) 8.6. Run 3B (`20261017-fase3b-rintangan-skor`, branch `feat/fase3b-rintangan-skor`, usulan, belum diuji di HP): anjing penjaga dan mobil keluar garasi dengan pola yang bisa dipelajari (separuh jalan sisinya, tanda ≥ 1,5 detik), tabrakan yang menghambat tanpa menghentikan rute (1,0 u/d, oleng, kebal), skor (sasaran × combo × kecepatan × tepat) dan koin (ongkos 15 + tip 5) dihitung terpisah dengan HUD dev sementara, penanda tepat dan netral, nada combo dan denting tip, dan bel "Kring Kring!" yang membuat anjing mundur; checklist uji HP: [`SETUP_ANDROID.md`](./SETUP_ANDROID.md) 8.7. Run 3C (`20261018-fase3c-hud-hasil`, branch `feat/fase3c-hud-hasil`, usulan, belum diuji di HP): HUD rute final (panel progres 25 kotak dengan tenggat, panel koin dan skor/combo, radar kiri dan kanan 30 ubin dengan penanda tip dan jangkau, rumah bukan pelanggan abu-abu di mode bantu, zona aman), tenggat rute = waktu santai × 1,15 tanpa game over (sesudah lewat hanya tip yang hilang), layar hasil sederhana yang dibuka dengan yang berhasil, sakelar Kidal dan Bantu pindah ke layar jeda, dan spike rumah sisi dekat (tiga pendekatan di `scenes/dev/spike_sisi_dekat.tscn`; pemilik memilih tembok/pagar belakang rendah 2026-10-17, ROADMAP 4b); checklist uji HP penutup Fase 3: [`SETUP_ANDROID.md`](./SETUP_ANDROID.md) 8.8. Fase 3 baru selesai sesudah uji HP pemilik. Fase 6A, run 6A1 (`20261020-fase6a1-bengkel-kondisi`, branch `feat/bengkel-kondisi-6a1`, usulan, belum diuji di HP): koin menjadi saldo (save v3: `koin_total`, `sepeda`), kondisi sepeda ban/rem/rantai (`BikeCondition`: aus dari telemetri gerak, kerusakan tabrakan, tanda peringatan dengan bunyi dan ikon bergetar, efek yang hanya menghambat), baris kondisi di HUD rute dan layar hasil, layar bengkel (`scenes/bengkel/bengkel.tscn`: servis dan tiga upgrade dari `assets/data/shop/upgrades.json`, `Economy`) dan alur Hasil -> Bengkel -> Hari berikutnya (bengkel boleh dilewati; simpan tepat sekali saat "Hari berikutnya"); checklist uji HP: [`SETUP_ANDROID.md`](./SETUP_ANDROID.md) 8.11. Fase 5, run 5A (`20261021-fase5a-pasang-aset-gelombang1`, branch `feat/fase5a-pasang-aset-gelombang1`, usulan, belum diuji di HP): aset gelombang 1 hasil renderer dipasang di rute perumahan menggantikan placeholder dari kode, hanya tampilan: enam kolom ubin jalan (`tools/env_art/ubin_perumahan.py --salin`), koran putar dengan bayangan menurut tinggi, koran tergeletak menurut permukaan (kotak surat, teras, rumput) dan koran terlipat di rumah terantar, debu roda dan garis kecepatan dari sprite, bintang kena dan koin tip, dan kilau kucing misi (`tools/env_art/gelombang1/render.py --salin`); jalan uji tetap memakai pola kode; checklist uji HP: [`SETUP_ANDROID.md`](./SETUP_ANDROID.md) 8.12; Fase 5 penuh belum dicentang. Run 5B (`20261021-fase5b-tembok-dekor`, branch `feat/fase5b-tembok-dekor`, usulan, belum diuji di HP): tembok sisi dekat empat varian dengan tiang ujung dan rumah dekat digambar mundur 1,25 ubin (tapak logika tidak berubah), dekor pinggir jalan (tong sampah logam, tiga pohon, lampu jalan mati) lewat bidang `dekor` di sembilan segmen ([`DATA_SCHEMA.md`](./DATA_SCHEMA.md) 3), dan tiga ubin tambahan di tanah rute (jalan masuk garasi di bawah mobil seberang, simbol sepeda tiap 12 baris, variasi rumput luar; `aspal_N` tidak dipasang); checklist uji HP: [`SETUP_ANDROID.md`](./SETUP_ANDROID.md) 8.13; Fase 5 penuh belum dicentang. Posisi lengkap ada di [`ROADMAP.md`](./ROADMAP.md).

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
| [`LOOP-DEV-QA.md`](./LOOP-DEV-QA.md) | Brief loop dua agent (Dev dan QA) untuk mengerjakan fase development, dengan Fase 0 dipecah jadi run 0A–0C dan perintah tempel untuk memulai run Fase 1 (Bagian 6b), Fase 6A (6f), dan pemasangan aset Fase 5 (6g, Run 5A) |
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
scenes/                hari/hari.tscn (scene utama sejak run 4A), koran/halaman_koran.tscn (run 4A), entities/kucing_misi.tscn dan ui/tutorial.tscn (run 4B), rute/rute.tscn, ui/panel_akhir_rute.tscn, dev/jalan_uji.tscn (scene dev), dev/graybox.tscn, dev/cek_render.tscn (probe render, hanya build probe), entities/loper_agen.tscn, sepeda_uji.tscn, umpan_balik_sepeda.tscn, ui/hud_dev.tscn, ui/layar_jeda.tscn (ada); Boot, Rute, Koran, Hasil, Bengkel menyusul
assets/sprites/        loper/, _placeholder/, houses/perumahan/ (rumah seberang dan dekat, dipakai scene rute), obstacles/ dan ui/ (usulan, belum dipakai scene) (ada); tiles/, props/, vfx/ menyusul
assets/palette/        loper_master.gpl (ada)
assets/fonts/          Lexend dan Lilita One, usulan (ada)
assets/audio/          sfx/bike/ tiga WAV placeholder hasil tools/audio_art/ + LICENSES.md (ada); ambience, SFX lain menyusul
assets/shaders/        warna_bayangan.gdshader, usulan (ada)
default_bus_layout.tres Bus audio Master -> SFX -> Sepeda (ada)
assets/ui/             theme.tres: font dan ukuran saja, warna dari Palette (ada); panel 9-slice menyusul
translations/          ui.csv dan konten.csv (keys,id; konten = headline dan misi, run 4A) + hasil impor .translation; semua teks pemain lewat kunci (ada)
assets/LICENSES.md     Lisensi aset pihak ketiga (ada)
assets/data/routes/perumahan/  9 segmen rute JSON, usulan (ada); assets/data/missions/ (misi P1) dan assets/data/headlines/ (utama, ringan, lanjutan), usulan, run 4A (ada)
scripts/config.gd      SEMUA angka tuning (BALANCING.md) (ada)
scripts/autoload/      audio.gd (autoload Audio, bunyi sepeda), save_manager.gd (autoload SaveManager, save v2 sejak run 4B) (ada); DayManager = MesinHari + scene hari (bukan autoload, S-1)
scripts/systems/       Logika murni: segmen_rute, pemuat_rute, route_builder, penutup_pemain, jendela_rute, akhir_rute, sprite_rumah, medan_koran, config_parser, loper_anim, iso, touch_zones, stick_map, touch_router, bike_motion (gerak, rem, stamina, lateral), jeda_sim, dorongan_kecepatan, jalan_daur, piksel_lingkaran, lempar_waktu, umpan_balik_kecepatan, bunyi_sepeda, throw_solver, zona_sasaran, sisa_koran, koran_lempar, pola_piksel (ada); skor, misi, reputasi, kerusakan menyusul
scripts/entities/      adegan_jalan (dasar bersama), rute_main, rumah_daur_rute, penerap_penutup, loper_sprite, sepeda_uji, jalan_uji, tanah_daur, objek_daur, zona_gambar, koran_gambar, pancaran_piksel, umpan_balik_sepeda (ada)
scripts/dev/           cek_render.gd (probe render Compatibility) (ada)
scripts/ui/            palette, panel_akhir_rute, kontrol_touch, hud_dev, bar_kecepatan, deret_koran, gambar_piksel, garis_bidik, gaya_hud, tombol_jeda, tombol_sentuh, layar_jeda (ada); HUD final dan layar menyusul
tests/                 run_tests.gd, tes_rute.gd, tes_rute_scene.gd, probe_rute_jendela.gd, tes_input_murni.gd, tes_input_scene.gd, tes_sprite.gd, tes_gerak.gd, tes_gerak_scene.gd, tes_jeda_scene.gd, tes_tata_letak.gd, tes_umpan_balik.gd, tes_bunyi.gd, tes_cek_render.gd, tes_lempar.gd, tes_koran_scene.gd, tes_export.gd, probe_layar.gd, probe_*_jendela.gd (ada)
tools/loper_art/       Renderer sprite pemain (Python), lihat ART_DIRECTION bagian 4; bangun_frames.py membangun SpriteFrames gabungan 68 animasi (stdlib); fase5c.py merender jatuh lima arah, bangkit, dan berhenti
tools/env_art/         Renderer aset lingkungan, termasuk graybox.py (ada)
tools/audio_art/       sintesis_sepeda.py, sintesis_lempar.py, sintesis_rute.py, sintesis_misi.py (run 4B): bunyi placeholder dari rumus (stdlib) (ada)
tools/                 cek_keluaran_tes.py, cek_blok_piksel.py, ekspor_cek_render.py (build probe render), tests_cek/ (uji_pemeriksa, uji_bangun_frames, uji_sintesis_*, uji_aset_kucing) (ada)
.github/workflows/     tes.yml (CI import dan tes headless), build-apk.yml (APK uji), release-please.yml (rilis)
builds/                APK hasil export, perintah di SETUP_ANDROID.md (di .gitignore, tidak di-commit)
```

Path seperti `scripts/config.gd` atau `tools/loper_art/produce.py` di dokumen lain selalu relatif terhadap root repo.

## Keputusan yang sudah dikunci

- **Platform**: mobile Android, layar **landscape** dipegang dua tangan (GDD 5).
- **Engine**: **Godot 4** dengan GDScript (GDD 16).
- **Teknis Fase 0** (2026-10-09): Godot **4.7.2**, skala piksel **×3**, base 640×360 dengan stretch `canvas_items` + integer scale + `expand`, package Android **`com.rmh.kring`** (alasan di `ROADMAP.md` 4b). Ukuran ubin **64×32 px** (2026-10-14).
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
