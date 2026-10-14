# AGENTS.md — Loper Koran

Panduan untuk semua coding agent (Codex, Cursor, Claude Code, dan lainnya) yang bekerja di repo ini.

**Loper Koran**: game 2D mobile Android (landscape) bergaya Paperboy modern, pixel art isometrik 2:1, latar Indonesia.
Stack rencana: **Godot 4.7.2 (GDScript)**, renderer Compatibility. Tooling aset: Python 3 (`tools/loper_art/`, `tools/env_art/`).
Status dan fase aktif: lihat `docs/README.md`, `docs/ROADMAP.md`, dan `docs/DEV_PHASES.md`. Sumber utama desain: `docs/GDD.md`.

## Aturan ada di `.cursor/rules/`

Folder `.cursor/rules/` adalah **satu-satunya sumber aturan** untuk repo ini. File ini dan `CLAUDE.md` hanya menunjuk ke sana, jadi aturan tidak ditulis dua kali. Kalau ada aturan baru, tambahkan ke file `.mdc` yang relevan, bukan ke sini.

Wajib:

1. **Selalu baca `.cursor/rules/00-project-core.mdc` dan `.cursor/rules/git-workflow.mdc` sebelum mengerjakan apa pun.** Isinya stack, prinsip desain, sumber kebenaran, keputusan terkunci, alur kerja, Definition of Done, dan aturan git (branch + PR, tidak pernah push langsung ke `main`).
2. **Sebelum mengedit file, baca rule yang `globs`-nya cocok dengan file itu** (lihat tabel). Cursor memuatnya otomatis; agent lain harus membukanya sendiri.
3. Kalau aturan di rule bertabrakan dengan permintaan user, sebutkan konfliknya dulu sebelum mengerjakan.

| Rule | Berlaku untuk | Isi |
|---|---|---|
| [`00-project-core.mdc`](.cursor/rules/00-project-core.mdc) | **Selalu** | Stack, lima prinsip desain, sumber kebenaran, keputusan terkunci, kerja mandiri lewat CLI, perintah, Definition of Done |
| [`git-workflow.mdc`](.cursor/rules/git-workflow.mdc) | **Selalu** | Tarik `main` terbaru sebelum bikin branch, branch + PR, tidak pernah push ke `main`, format commit, isi PR, squash merge oleh user |
| [`gdscript.mdc`](.cursor/rules/gdscript.mdc) | `**/*.gd` | Gaya GDScript, letak kode (systems murni / autoload / ui), input touch, koordinat isometrik, aturan wajib |
| [`balancing.mdc`](.cursor/rules/balancing.mdc) | `scripts/config.gd`, `scripts/systems/**`, `assets/data/missions/**`, `assets/data/shop/**`, `docs/BALANCING.md` | Format config satu baris, satuan, alur mengubah angka, batasan desain tuning |
| [`save-system.mdc`](.cursor/rules/save-system.mdc) | `scripts/autoload/save_manager.gd`, `scripts/**/*save*.gd` | Simpan hanya di akhir hari, migrasi versi, save rusak tidak ditimpa, id permanen |
| [`content-data.mdc`](.cursor/rules/content-data.mdc) | `assets/data/**`, `translations/**`, `docs/CONTENT_GUIDE.md`, `docs/DATA_SCHEMA.md`, `docs/ROUTE_DESIGN.md` | Format data, segmen rute, headline dan misi, standar konten, kunci terjemahan |
| [`ui-scenes.mdc`](.cursor/rules/ui-scenes.mdc) | `scenes/**`, `scripts/ui/**`, `docs/design/**` | Layout landscape, zona aman, kontrol touch (stick + swipe), aksesibilitas, umpan balik |
| [`art-assets.mdc`](.cursor/rules/art-assets.mdc) | `tools/loper_art/**`, `tools/env_art/**`, `assets/sprites/**`, `assets/audio/**`, `docs/ART_DIRECTION.md`, `docs/SOUND_DESIGN.md`, `docs/design/character/**`, `docs/design/environment/**` | Gaya pixel art isometrik, aset dibuat lewat renderer, penamaan, impor Godot, audio |
| [`privacy-ads.mdc`](.cursor/rules/privacy-ads.mdc) | `analytics.gd`, `ad_service.gd`, `ad_rules.gd`, `export_presets.cfg`, `android/**`, `addons/**` | Privasi, iklan hadiah opsional, tanpa pembelian uang asli, export Android, keystore |
| [`testing.mdc`](.cursor/rules/testing.mdc) | `tests/**` | Tes headless, seed deterministik, verifikasi sebelum menyatakan selesai, uji di HP |
| [`docs.mdc`](.cursor/rules/docs.mdc) | `docs/**` | Bahasa, usulan vs dikunci, kapan dokumen diperbarui, apa yang tidak diedit manual |

## Perintah cepat

Project Godot 4.7.2 sudah ada (Fase 0, run 0A, 0B, dan 0C; Fase 1 run 1A dan 1B). Dari root repo:

```bash
godot --headless --import                              # sekali setelah clone, dan setiap ada class_name atau aset baru
mkdir -p build                                         # folder log, tidak di-commit
godot --headless --script res://tests/run_tests.gd 2>&1 | tee build/tests.log   # tes logika inti
python3 tools/cek_keluaran_tes.py build/tests.log      # pemeriksa keluaran: WAJIB, exit code Godot saja tidak cukup
python3 tools/tests_cek/uji_pemeriksa.py               # bukti pemeriksa menolak log buruk
python3 tools/tests_cek/uji_bangun_frames.py           # bukti SpriteFrames di assets/ = hasil skrip pembangun
python3 tools/tests_cek/uji_sintesis_sepeda.py         # bukti WAV di assets/audio/ = hasil skrip sintesis, deterministik, loop tanpa klik
godot --headless --path . --quit-after 2               # buka project dua frame, tidak boleh ada ERROR/WARNING
godot --headless --path . --script res://tests/probe_layar.gd   # skala bulat dan lebar viewport per rasio layar
godot --path .                                         # jalankan scene utama sementara (jalan_uji.tscn): stick di layar sentuh, panah atau WASD di editor
godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_umpan_balik_jendela.gd -- docs/loop/<RUN_ID>/shots   # tangkapan layar debu, garis, rem, jeda, kidal
godot --headless --path . scenes/dev/cek_render.tscn   # probe render Compatibility (light 2D, glow, partikel, shader); jendela asli: tambah --resolution 2340x1080 dan -- --tangkap=<png>
python3 tools/ekspor_cek_render.py --apk builds/kring-cek-render-debug.apk   # APK probe render terpisah (scene utama diganti dan pengecualian probe di preset dilepas hanya selama ekspor; APK normal tanpa probe); --pck <berkas> tanpa Java
mkdir -p builds                                        # folder APK hasil ekspor, tidak di-commit
godot --headless --path . --export-pack "Android" build/kring-uji.pck   # paket game dengan filter preset (tanpa Java); periksa tidak ada tests/ atau docs/
godot --headless --path . --export-debug "Android" builds/kring-kring-debug.apk   # APK debug; butuh export templates 4.7.2 dan Java SDK Path di Editor Settings
python3 tools/env_art/graybox.py                       # render ulang ubin dan kotak graybox (hanya stdlib)
python3 tools/audio_art/sintesis_sepeda.py             # buat ulang tiga WAV placeholder sepeda di assets/audio/sfx/bike/ (hanya stdlib); lalu godot --headless --import
python3 tools/loper_art/produce.py --out build/loper_art   # render ulang sprite pemain (butuh numpy, pillow)
python3 tools/loper_art/bangun_frames.py                   # bangun ulang loper_agen_frames.tres (48 animasi) dan salin PNG/JSON sprite ke assets/ (hanya stdlib)
```

`godot --headless` mengabaikan `--resolution`; untuk jendela asli sebentar: `godot --path . --resolution 1560x720 --script res://tests/probe_layar_jendela.gd -- <jalur.png>`.
macOS tanpa `godot` di PATH: `/Applications/Godot.app/Contents/MacOS/Godot`.
Export Android (preset `Android` di `export_presets.cfg`, tanpa Gradle, arm64-v8a, package `com.rmh.kring`): prasyarat mesin, isi dan alasan preset, pemeriksaan isi APK (`aapt2`, `apksigner`), pasang ke HP, dan checklist uji ada di [`docs/SETUP_ANDROID.md`](docs/SETUP_ANDROID.md). `JAVA_HOME` saja tidak cukup: `export/android/java_sdk_path` di Editor Settings harus terisi. Memasang ke HP hanya setelah izin pemilik; HP dipakai bersama project lain, jangan `pm clear` atau uninstall tanpa izin.

## Peta repo

```
project.godot        Godot 4.7.2, Compatibility, landscape, 640x360 canvas_items + integer + expand, scene utama jalan_uji.tscn, autoload Audio, quit_on_go_back false (back = jeda), aksi InputMap stick_* (keyboard hanya editor), terjemahan dan tema terdaftar
default_bus_layout.tres  Bus audio Master -> SFX -> Sepeda
scenes/              dev/jalan_uji.tscn (scene utama sementara, jalan tanpa ujung yang bisa digerakkan), dev/graybox.tscn (statis, untuk probe layar), dev/cek_render.tscn (probe render Compatibility, hanya lewat build probe), entities/loper_agen.tscn (pemain), sepeda_uji.tscn, umpan_balik_sepeda.tscn (debu, garis kecepatan), ui/hud_dev.tscn (HUD sementara + tombol jeda), ui/layar_jeda.tscn
scripts/             config.gd (semua angka tuning), systems/ (logika murni: iso, touch_zones, stick_map, touch_router, bike_motion (gerak, rem, stamina, lateral), jeda_sim (jeda tanpa lanjut otomatis), dorongan_kecepatan, jalan_daur, loper_anim (animasi, pose, laju kayuh), lempar_waktu, umpan_balik_kecepatan (debu, garis), bunyi_sepeda (loop, pitch, tepi naik rem)), autoload/ (audio.gd: autoload Audio, bunyi sepeda, tidak merujuk autoload lain), entities/ (sepeda_uji, jalan_uji, tanah_daur, objek_daur, loper_sprite, pancaran_piksel, umpan_balik_sepeda), ui/ (palette, kontrol_touch, hud_dev, bar_kecepatan, gaya_hud, tombol_jeda, tombol_sentuh, layar_jeda), dev/ (cek_render.gd)
assets/              sprites/ (loper/: sheet kayuh, melambat, lempar, meluncur, dan rem + loper_agen_frames.tres gabungan 48 animasi, _placeholder/), audio/ (sfx/bike/ tiga WAV placeholder hasil tools/audio_art/ + LICENSES.md), shaders/ (warna_bayangan.gdshader, usulan), palette/, fonts/ (usulan), ui/theme.tres (font dan ukuran saja), LICENSES.md
icon.svg             Ikon aplikasi sementara (bel, hanya warna Palette; pengganti final di Fase 14), dipakai ekspor Android
export_presets.cfg   Preset export Android (satu preset, tanpa rahasia, dijaga tests/tes_export.gd); keystore dan kredensial tidak pernah di-commit
builds/              APK hasil ekspor (di .gitignore, tidak di-commit)
translations/        ui.csv (kolom keys,id) beserta ui.csv.import dan ui.id.translation hasil impor; semua teks pemain lewat kunci di sini
tests/               run_tests.gd (runner), tes_input_murni.gd, tes_input_scene.gd, tes_sprite.gd, tes_gerak.gd, tes_gerak_scene.gd, tes_jeda_scene.gd, tes_tata_letak.gd, tes_umpan_balik.gd, tes_bunyi.gd, tes_cek_render.gd, dan tes_export.gd (pembantu runner), probe_layar*.gd (ukur skala layar), probe_input_jendela.gd, probe_dorongan_jendela.gd, probe_lempar_jendela.gd, probe_gerak_jendela.gd, dan probe_umpan_balik_jendela.gd (tangkapan layar skenario sentuh, melambat, lempar, meluncur, rem, stamina, debu, garis, jeda), probe_keluar.gd (`ProbeKeluar`: semua probe jendela keluar lewat sini, bunyi dihentikan dulu supaya keluar tanpa ERROR/WARNING)
docs/                Dokumen desain (GDD, STORY, TECH_PLAN, ART_DIRECTION, BALANCING, DATA_SCHEMA, dst.), SETUP_ANDROID.md (export dan uji HP) + design/ + loop/
docs/design/         Token desain, mock HUD, sprite produksi pemain (character/loper_agen/)
tools/loper_art/     Renderer sprite pemain (Python) + bangun_frames.py (SpriteFrames gabungan, stdlib), lihat tools/loper_art/README.md
tools/env_art/       Renderer aset lingkungan (usulan) + graybox.py (ubin graybox)
tools/audio_art/     sintesis_sepeda.py: bunyi placeholder sepeda dari rumus (stdlib, deterministik), lihat tools/audio_art/README.md
tools/               cek_keluaran_tes.py (pemeriksa keluaran tes), tests_cek/ (contoh log baik dan buruk, uji_bangun_frames.py, uji_sintesis_sepeda.py), cek_blok_piksel.py (ketajaman tangkapan layar), ekspor_cek_render.py (build probe render terpisah; probe dikecualikan dari build normal oleh exclude_filter preset)
.github/workflows/   tes.yml (CI: uji alat Python, import, tes, pemeriksa keluaran)
.cursor/rules/       Aturan agent (sumber tunggal)
```

Belum ada: `android/` (template Gradle; baru dipasang saat plugin Android masuk, Fase 8 dan 14), autoload selain `Audio`, `assets/data/`, file terjemahan bahasa Inggris, panel 9-slice di `assets/ui/theme.tres`. Struktur lengkap yang direncanakan ada di `docs/README.md`.
