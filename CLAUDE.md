# CLAUDE.md — Loper Koran

Aturan project ini ada di `.cursor/rules/` dan dipakai bersama oleh Cursor, Claude Code, dan agent lain. File ini mengimpor aturan-aturan itu supaya Claude Code memakai aturan yang sama persis. **Jangan menulis aturan baru di sini.** Tambahkan ke file `.mdc` yang relevan.

## Indeks agent

@AGENTS.md

## Aturan (diimpor dari `.cursor/rules/`)

Frontmatter `globs` di setiap file menunjukkan file mana yang terkena aturan itu. Aturan `git-workflow` berlaku untuk semua pekerjaan. Rule baru ditambahkan ke daftar impor ini.

@.cursor/rules/git-workflow.mdc
