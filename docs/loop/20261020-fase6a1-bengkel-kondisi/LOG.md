# Loop Log — 20261020-fase6a1-bengkel-kondisi
Scope: Run 6A1 — save v3 (koin = saldo, `koin_total`, `sepeda`), `BikeCondition`, kotak kondisi di HUD rute, layar bengkel (servis + upgrade dari `upgrades.json`), `Economy`, alur Hasil → Bengkel → Hari berikutnya  ·  Branch: feat/bengkel-kondisi-6a1  ·  Mulai: 2026-10-20  ·  Godot: 4.7.2.stable

## Status: IN_PROGRESS   (iterasi saat ini: 1/2)

Baseline (main 337fae3, sebelum perubahan; dijalankan orchestrator 2026-10-20): `godot --headless --import` bersih; `run_tests.gd` **15133 lolos, 0 gagal**; `tools/cek_keluaran_tes.py` lolos (0 peringatan). HP: `adb devices` kosong saat run dimulai (vivo V2108 tidak tersambung); HP belum disentuh.

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 1 | | | | | |

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## Mutan (AC-31, diisi Dev; QA mengulang sedikitnya 10 yang berbeda)
| # | File | Perubahan | Tes yang gagal |
|---|---|---|---|

## NEEDS-MANUAL (uji di HP)
- [ ] Lihat SPEC bagian NEEDS-MANUAL; rincian dan lembar hasil di `docs/SETUP_ANDROID.md` 8.11.

## Keputusan & catatan
- Keputusan pemilik 2026-10-20: K-1 koin = saldo (bengkel dibayar langsung, `koin_total` untuk milestone); K-2 mode bantu tidak mengubah aus/kerusakan; K-3 kejadian rute hanya aus + tabrakan (paku/kaca/genangan = usulan 6A2); K-4 bengkel boleh dilewati.
- Keputusan orchestrator M-1 sampai M-13 di SPEC (usulan, bisa ditolak di review).
- Hasil uji HP 4A dan 4B: kosong (belum ada catatan). Fase 2, 3, 4, dan M2 tidak dicentang.
- Commit `docs:` terpisah (DEV_PHASES: teks "Fase aktif" dan baris Fase 4/6) sudah dibuat orchestrator di branch ini sebelum iterasi 1 (771402f).
