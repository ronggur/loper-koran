# AGENTS.md — Loper Koran

Panduan untuk semua coding agent (Codex, Cursor, Claude Code, dan lainnya) yang bekerja di repo ini.

**Loper Koran**: game 2D mobile Android (landscape) bergaya Paperboy modern, pixel art isometrik 2:1, latar Indonesia.
Stack rencana: **Godot 4 (GDScript)**, renderer Compatibility. Tooling aset: Python 3 (`tools/loper_art/`).
Status dan fase aktif: lihat `docs/README.md`, `docs/ROADMAP.md`, dan `docs/DEV_PHASES.md`. Sumber utama desain: `docs/GDD.md`.

## Aturan ada di `.cursor/rules/`

Folder `.cursor/rules/` adalah **satu-satunya sumber aturan** untuk repo ini. File ini dan `CLAUDE.md` hanya menunjuk ke sana, jadi aturan tidak ditulis dua kali. Kalau ada aturan baru, tambahkan ke file `.mdc` yang relevan, bukan ke sini.

Wajib:

1. **Selalu baca `.cursor/rules/git-workflow.mdc` sebelum mengerjakan apa pun yang membuat commit.** Isinya aturan git: tarik `main` terbaru, branch + PR, tidak pernah push langsung ke `main`, format commit dan PR.
2. **Sebelum mengedit file, baca rule yang `globs`-nya cocok dengan file itu** (lihat tabel). Cursor memuatnya otomatis; agent lain harus membukanya sendiri.
3. Kalau aturan di rule bertabrakan dengan permintaan user, sebutkan konfliknya dulu sebelum mengerjakan.

| Rule | Berlaku untuk | Isi |
|---|---|---|
| [`git-workflow.mdc`](.cursor/rules/git-workflow.mdc) | **Selalu** | Tarik `main` terbaru sebelum bikin branch, branch + PR, tidak pernah push ke `main`, format commit, isi PR, squash merge oleh user |

## Peta repo

```
docs/                Dokumen desain (GDD, ART_DIRECTION, BALANCING, DATA_SCHEMA, dst.) + design/
docs/design/         Token desain, mock HUD, sprite produksi pemain (character/loper_agen/)
tools/loper_art/     Renderer sprite pemain (Python), lihat tools/loper_art/README.md
.cursor/rules/       Aturan agent (sumber tunggal)
```

Struktur Godot (`scenes/`, `scripts/`, `assets/`, `tests/`) dibuat di Fase 0, lihat `docs/README.md`.
