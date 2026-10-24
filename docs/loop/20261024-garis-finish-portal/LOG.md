# Loop Log — 20261024-garis-finish-portal
Scope: Run garis finish dengan portal satpam (sepeda melaju keluar viewport)  ·  Branch: feat/garis-finish-portal (dari main 92255fa, rilis 0.7.0 + PR #66)  ·  Mulai: 2026-10-24  ·  Godot: 4.7.2

## Status: IN_PROGRESS   (iterasi 1/2; Dev bagian A sedang dikerjakan)

## Lingkungan (orchestrator, awal run)
- Basis: `main` = `origin/main` = `92255fa` (memuat PR #66 UI-2, di-merge 2026-10-24).
- sha256 save asli: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e`.
- `.claude/` untracked: bukan bagian run, tidak di-commit.

## Baseline (Dev bagian A mengisi, di main sebelum mengubah apa pun)
Diukur Dev bagian A, 2026-10-24, di `99b0d29` (= main `92255fa` + dua commit docs), sebelum satu pun perubahan. Godot 4.7.2 (`/opt/homebrew/bin/godot`), satu proses sekaligus.
- `godot --headless --import`: exit 0.
- `godot --headless --path . --quit-after 2`: exit 0, 0 baris ERROR/WARNING.
- `godot --headless --script res://tests/run_tests.gd`: exit 0; `tools/cek_keluaran_tes.py`: **28489 lolos, 0 gagal, 0 peringatan** (lolos).
- 17 `tools/tests_cek/uji_*.py`, semua exit 0: uji_aset_fase3 148, uji_aset_gelombang1 352, uji_aset_kucing 13, uji_aset_lampu_pohon 183, uji_aset_pasang_5b 595, uji_aset_pasang_gelombang1 565, uji_aset_simpang 214, uji_bangun_frames 62, uji_pemeriksa 16 kasus 0 menyimpang, uji_sintesis_kondisi 55, uji_sintesis_lempar 111, uji_sintesis_milestone 18, uji_sintesis_misi 47, uji_sintesis_rute 90, uji_sintesis_sepeda 32, uji_ui_lencana 25, uji_ui_redesain LOLOS.
- `godot --headless --path . --export-pack "Android" build/kring-uji.pck`: exit 0 (2.018.972 byte).
- sha256 save asli (`~/Library/Application Support/Godot/app_userdata/Kring Kring!/save.json`, tidak dibuka lewat game): `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e` (sama dengan awal run).

## Butir terbuka pemilik
- Lisensi latar bengkel (UI-1) belum dicatat; di luar scope run ini.

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 1 | | | | | |

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## Tes lama yang diubah (G-1..G-6), per baris
(Dev mengisi: file, asersi, nilai lama -> baru, alasan)

## NEEDS-MANUAL (uji di HP)
- [ ] SETUP_ANDROID 8.20 (ditulis bagian D)

## Keputusan & catatan
- Putusan orchestrator G-1..G-6 di SPEC.
