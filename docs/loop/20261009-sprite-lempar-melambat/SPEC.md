# SPEC — 20261009-sprite-lempar-melambat

Run kecil di antara Fase 0 dan Fase 1 (permintaan pemilik, 2026-10-09): memasang sprite **melambat** dan **lempar koran** yang sudah ada di `main` (PR #15, `docs/design/character/loper_agen/{melambat,lempar}/`) ke game supaya bisa dilihat di A54. Kontrak bagi Dev **dan** QA. Versi ringan dari `docs/LOOP-DEV-QA.md`: satu iterasi Dev, satu QA, iterasi 2 hanya bila ada Blocker/Major.

## Tujuan

Di jalan uji yang sudah ada: (1) saat stick ditarik ke bawah sepeda memakai animasi `melambat_<arah>` (kayuh 4 fps); (2) swipe horizontal di zona kanan memainkan animasi `lempar_<sisi>_<kecepatan>_<arah>` satu kali lalu kembali mengayuh. **Tanpa proyektil koran, tanpa skor, tanpa sasaran** (Fase 2): hanya animasi pemain, plus sinyal pada frame lepas supaya Fase 2 tinggal menyambung.

## Keputusan dari pemilik (dengan tanggal)

- 2026-10-09: sprite melambat dan lempar dipasang dulu untuk dilihat sebelum Fase 1. Skala tetap ×3. Izin pasang APK ke A54 (`RRCWA05E2NN`) berlaku (hanya orchestrator yang menyentuh HP; Dev dan QA tidak).
- Dari run sebelumnya: Godot 4.7.2, base 640×360 ×3, `com.rmh.kring`, format terjemahan CSV, export tanpa Gradle. Export templates dan Java SDK path sudah siap di mesin ini.

Status **usulan** (jangan ditulis "dikunci"): semua sprite lempar/melambat, fps 4 dan 12, ambang swipe, aturan pemilihan di bawah.

### Keputusan orchestrator (bisa ditolak di review PR)

- **D-1. Melambat dipicu stick**, sama seperti tingkat lain (D-4 run 0B): komponen maju stick di bawah nol setelah zona mati → tingkat `melambat`. Stick netral atau naik tidak memakainya. (README sprite: "saat stick ditarik ke bawah dan sepeda melambat".) Kecepatan sebenarnya tetap dari `BikeDrive`.
- **D-2. Sisi lempar dari arah swipe:** swipe ke kiri layar = sisi `seberang` (nama animasi `kiri`), ke kanan layar = sisi `dekat` (`kanan`) (GDD 5.2; `kiri`/`kanan` hanya di nama animasi aset). Swipe yang dominan vertikal atau lebih pendek dari ambang usulan (`Config`, usulan 12 px game; belum dikunci, ui-scenes: butuh uji HP) tidak melempar.
- **D-3. Pilihan animasi lempar:** `lempar_<sisi>_<kecepatan>_<arah>` dengan kecepatan = tingkat sprite saat itu (melambat memakai `santai`, tidak ada lempar melambat) dan arah = arah sprite saat itu; arah 90° (belum ada gambarnya) diganti serong di sisi yang sama (README lempar). Selama animasi lempar berjalan, swipe berikutnya diabaikan (usulan sederhana).
- **D-4. Setelah lempar selesai** kembali ke animasi kayuh yang sesuai tingkat dan arah **saat itu** (bukan saat mulai), dengan indeks frame dan progres kayuh dipertahankan seperti pergantian animasi biasa (`LoperSprite._terapkan_animasi`).
- **D-5. Sinyal:** `LoperSprite` memancarkan `koran_lepas(sisi)` tepat saat frame `release_frame` (indeks 2) ditampilkan dan `lempar_selesai` saat selesai. Tidak ada yang mendengarkan di run ini selain tes.
- **D-6. Satu `SpriteFrames` gabungan:** `assets/sprites/loper/loper_agen_frames.tres` diperluas jadi 15 kayuh + 5 melambat + 18 lempar = 38 animasi, dibuat oleh skrip di `tools/` dari tiga JSON sumber (bukan diedit tangan, `art-assets.mdc`), PNG dan JSON disalin ke `assets/sprites/loper/` dengan setelan impor yang sama (Lossless, tanpa mipmap, tanpa kompresi VRAM). Cara `.tres` lama dibuat ada di `tools/loper_art/produce.py`; ikuti, jangan menulis ulang gayanya.

## Di luar scope

- Proyektil koran, lintasan, skor, sasaran, jendela kena, garis bidik yang memperhitungkan kecepatan, efek mendarat (Fase 2). Arah lempar 90° (belum ada gambar). Bel dan efek kring (`bel/`, belum diminta). Varian baju. Rem, stamina, pindah sisi (Fase 1). Mengubah `tools/loper_art/lempar.py`/`melambat.py` atau PNG sumber.
- Mengubah angka tuning kecepatan, dorongan kecepatan, atau skala.

## Kriteria penerimaan (bisa diuji)

Perintah dari root repo, `godot` = 4.7.2. Tes mengikuti `testing.mdc`; semua tes lama tetap hijau kecuali yang memang harus berubah (daftar dan alasannya di LOG: mis. "SpriteFrames memuat tepat 15 animasi").

- AC-1: `godot --headless --import` bersih (0 `ERROR`/`SCRIPT ERROR`/`WARNING`); di clone bersih `git status --porcelain` kosong sesudahnya (semua `.import`, `.uid` ter-commit). `run_tests.gd` + `tools/cek_keluaran_tes.py --ketat` exit 0; `tools/tests_cek/uji_pemeriksa.py` lolos; `godot --headless --path . --quit-after 2` tanpa `ERROR`/`WARNING`; tidak ada keystore/APK/`.godot/`/`build/`/`builds/` di diff.
- AC-2 (aset): `assets/sprites/loper/` memuat PNG dan JSON lempar dan melambat byte-identik dengan sumber di `docs/design/character/loper_agen/`, dengan `.import` Lossless/tanpa mipmap. Skrip pembangun `.tres` di `tools/` (stdlib, deterministik: dijalankan dua kali menghasilkan byte sama) menghasilkan `loper_agen_frames.tres` dengan **tepat 38 animasi**: nama, urutan baris, 4 frame, region tiap frame sama dengan JSON sumber, fps 8/10/12 (kayuh), 4 (melambat), 12 (lempar), loop true untuk kayuh dan melambat, **false untuk lempar**. Tes memeriksa semuanya terhadap JSON, termasuk tidak ada animasi lempar dengan `release_frame` selain 2.
- AC-3 (`LoperAnim`, murni): fungsi nama animasi mencakup melambat dan lempar; `melambat` hanya untuk komponen stick maju negatif setelah zona mati (14,9% bawah tidak, 15,1% bawah ya, tepi dites); pilih lempar sesuai D-3 untuk semua kombinasi (sisi 2 × tingkat melambat+3 × arah -2..2 = semua nama ada di `SpriteFrames`); arah ±2 jatuh ke serong di sisi yang sama; tingkat melambat jatuh ke santai. Fungsi sisi dari swipe (D-2): kiri/kanan, vertikal dominan, di bawah ambang, tepat di ambang, vektor nol/NaN, dites.
- AC-4 (`LoperSprite`): `speed_level` mendukung tingkat melambat (nilai di luar jangkauan tetap dijepit); `lempar(sisi)` memainkan animasi yang benar sekali (tidak loop), memancarkan `koran_lepas` tepat sekali pada frame 2 dan `lempar_selesai` tepat sekali, kembali ke kayuh dengan tingkat/arah terkini (D-4), mengabaikan panggilan `lempar` saat sedang melempar (D-3), tetap aman bila `sprite_frames` null (Q-001 dari run 0A: perbaiki sekalian karena `loper_sprite.gd` disentuh, dengan tes), tidak ada `ERROR`/`WARNING` saat dipanggil di luar scene tree. Tes dengan node hidup memakai waktu terkontrol (memanggil langkah animasi dengan `dt` tetap) sehingga deterministik.
- AC-5 (kabel): stick bawah di scene uji → animasi `melambat_*` (bersama dorongan kecepatan yang sudah ada); swipe sintetis lewat `Input.parse_input_event` pada viewport 780×360 (jalur yang sama dengan tes AC-12 run 0B) → `lempar_*` yang benar untuk swipe kiri dan kanan di tiga tingkat, kidal tidak mengubah arti sisi (kidal menukar zona, bukan sisi lempar); swipe vertikal atau pendek tidak melempar; stick dan swipe dua jari bersamaan: sepeda tetap bergerak sambil melempar; `batal_semua()`/pause tidak meninggalkan animasi lempar menggantung.
- AC-6 (Config, satu baris per konstanta): ambang swipe lempar, `LEMPAR_FPS`/`MELAMBAT_FPS` hanya bila dipakai kode (fps boleh dibaca dari `SpriteFrames` tanpa konstanta); dicatat di `docs/BALANCING.md` bagian 2 sebagai usulan awal.
- AC-7 (dokumen, commit yang sama dengan perubahannya): `docs/design/character/loper_agen/lempar/README.md` dan `melambat/README.md` ("belum dipakai di game" → dipakai, tanggal), `docs/design/character/README.md`, `docs/ART_DIRECTION.md` bagian yang menyebut status sprite (bila ada), `AGENTS.md` peta repo, `docs/README.md`, `docs/SETUP_ANDROID.md` bagian checklist HP (butir uji baru, lihat di bawah). `DEV_PHASES.md` dan `ROADMAP.md` 4b **tidak** diedit Dev.
- AC-8 (bukti visual, di jendela asli 2340×1080 lewat pola `tests/probe_*_jendela.gd`, simpan di `docs/loop/20261009-sprite-lempar-melambat/shots/`): tangkapan layar melambat (4 arah yang bisa muncul), dan urutan 4 frame lempar kiri dan kanan di santai dan ngebut; sprite tajam (`tools/cek_blok_piksel.py 3`, `--kecualikan` untuk teks HUD); sprite lempar punya titik pijak yang sama dengan kayuh (tidak melompat saat berganti animasi: ukur posisi alas sprite sebelum, saat, dan sesudah lempar).
- AC-9: commit kecil `<tipe>: <ringkasan>` bahasa Indonesia di branch `feat/sprite-lempar-melambat`, tidak ada commit di `main`, tidak ada push.

## Perubahan file/struktur yang diharapkan

```
assets/sprites/loper/{loper_agen_lempar,loper_agen_melambat}.{png,json}(+.import), loper_agen_frames.tres (38 animasi)
tools/loper_art/ atau tools/env_art/ : skrip pembangun .tres dari tiga JSON (+ README singkat)
scripts/systems/loper_anim.gd (+ fungsi nama melambat/lempar, sisi dari swipe)
scripts/entities/loper_sprite.gd (tingkat melambat, lempar(), sinyal)
scripts/entities/sepeda_uji.gd, scripts/ui/kontrol_touch.gd atau penghubung swipe -> lempar
scripts/config.gd (+ ambang swipe lempar), tests/ (tes baru, tes lama diperbarui seperlunya)
docs: README sprite, BALANCING 2, SETUP_ANDROID (checklist), AGENTS.md, docs/README.md
```

## Butuh uji perangkat nyata (NEEDS-MANUAL)

Orchestrator memasang APK ke A54 setelah QA. Pemilik menilai dengan mata:
- Melambat: stick bawah penuh → kayuh jelas lebih pelan dari santai (4 fps vs 8 fps), tidak terasa patah.
- Lempar: swipe kiri dan kanan di santai, cepat, ngebut; lengan dan titik lepas terbaca; tidak ada lompatan posisi saat berganti; sambil serong (stick kiri atau kanan) memakai varian serong yang benar; 90° belum ada gambar (pakai serong).
- Ambang swipe 12 px dan "abaikan swipe saat masih melempar" terasa wajar; catat angka yang diinginkan.
- Dua jempol: stick tetap jalan saat melempar.

## Dokumen yang ikut diperbarui

Lihat AC-7. Orchestrator: `DEV_PHASES.md` (butir Fase 1 "Animasi pemain memilih ... laju kayuh" dan Fase 2 "Swipe ... menentukan sisi" tidak dicentang; bila perlu ditambah catatan bahwa animasinya sudah terpasang), `ROADMAP.md` 4b bila ada keputusan baru.
