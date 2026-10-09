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

Project Godot 4.7.2 sudah ada (Fase 0, run 0A). Dari root repo:

```bash
godot --headless --import                              # sekali setelah clone, dan setiap ada class_name atau aset baru
mkdir -p build                                         # folder log, tidak di-commit
godot --headless --script res://tests/run_tests.gd 2>&1 | tee build/tests.log   # tes logika inti
python3 tools/cek_keluaran_tes.py build/tests.log      # pemeriksa keluaran: WAJIB, exit code Godot saja tidak cukup
python3 tools/tests_cek/uji_pemeriksa.py               # bukti pemeriksa menolak log buruk
godot --headless --path . --quit-after 2               # buka project dua frame, tidak boleh ada ERROR/WARNING
godot --headless --path . --script res://tests/probe_layar.gd   # skala bulat dan lebar viewport per rasio layar
python3 tools/env_art/graybox.py                       # render ulang ubin dan kotak graybox (hanya stdlib)
python3 tools/loper_art/produce.py --out build/loper_art   # render ulang sprite pemain (butuh numpy, pillow)
```

`godot --headless` mengabaikan `--resolution`; untuk jendela asli sebentar: `godot --path . --resolution 1560x720 --script res://tests/probe_layar_jendela.gd -- <jalur.png>`.
macOS tanpa `godot` di PATH: `/Applications/Godot.app/Contents/MacOS/Godot`.

## Peta repo

```
project.godot        Godot 4.7.2, Compatibility, landscape, 640x360 canvas_items + integer + expand
scenes/              dev/graybox.tscn (scene utama sementara), entities/loper_agen.tscn (pemain)
scripts/             config.gd (semua angka tuning), systems/ (logika murni), entities/, ui/ (palette.gd)
assets/              sprites/ (loper/, _placeholder/), palette/, fonts/ (usulan), LICENSES.md
tests/               run_tests.gd (runner), probe_layar*.gd (ukur skala layar)
docs/                Dokumen desain (GDD, STORY, TECH_PLAN, ART_DIRECTION, BALANCING, DATA_SCHEMA, dst.) + design/ + loop/
docs/design/         Token desain, mock HUD, sprite produksi pemain (character/loper_agen/)
tools/loper_art/     Renderer sprite pemain (Python), lihat tools/loper_art/README.md
tools/env_art/       Renderer aset lingkungan (usulan) + graybox.py (ubin graybox)
tools/               cek_keluaran_tes.py (pemeriksa keluaran tes), tests_cek/ (contoh log baik dan buruk)
.github/workflows/   tes.yml (CI: import, tes, pemeriksa keluaran)
.cursor/rules/       Aturan agent (sumber tunggal)
```

Belum ada: `export_presets.cfg`, `android/` (run 0C), input touch (run 0B), `scripts/autoload/`, `assets/data/`, file terjemahan, `assets/ui/theme.tres`. Struktur lengkap yang direncanakan ada di `docs/README.md`.
