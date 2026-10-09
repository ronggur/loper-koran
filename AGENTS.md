# AGENTS.md — Loper Koran

Panduan untuk semua coding agent (Codex, Cursor, Claude Code, dan lainnya) yang bekerja di repo ini.

**Loper Koran**: game 2D mobile Android (landscape) bergaya Paperboy modern, pixel art isometrik 2:1, latar Indonesia.
Stack rencana: **Godot 4 (GDScript)**, renderer Compatibility. Tooling aset: Python 3 (`tools/loper_art/`, `tools/env_art/`).
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

Project Godot belum ada (dibuat di Fase 0). Setelah itu:

```bash
godot --headless --import                              # sekali setelah clone
godot --headless --script res://tests/run_tests.gd     # tes logika inti
python3 tools/loper_art/produce.py --out build/loper_art   # render ulang sprite pemain
```

macOS tanpa `godot` di PATH: `/Applications/Godot.app/Contents/MacOS/Godot`.

## Peta repo

```
docs/                Dokumen desain (GDD, STORY, TECH_PLAN, ART_DIRECTION, BALANCING, DATA_SCHEMA, dst.) + design/
docs/design/         Token desain, mock HUD, sprite produksi pemain (character/loper_agen/)
tools/loper_art/     Renderer sprite pemain (Python), lihat tools/loper_art/README.md
tools/env_art/       Renderer aset lingkungan (usulan)
.cursor/rules/       Aturan agent (sumber tunggal)
```

Struktur Godot (`scenes/`, `scripts/`, `assets/`, `tests/`) dibuat di Fase 0, lihat `docs/README.md`.
