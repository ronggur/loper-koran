# Loop Log — 20261014-fase2a-lemparan
Scope: Run 2A Fase 2, inti lemparan koran (`ThrowSolver`, garis bidik = hasil, koran terbang, zona sasaran placeholder, sisa koran, jeda 0,35 detik) + perapian Run 1C (QA-001, QA-002, QA-005)  ·  Branch: `feat/fase2a-lemparan`  ·  Mulai: 2026-10-14  ·  Godot: 4.7.2

## Status: IN_PROGRESS   (iterasi saat ini: 1/2)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## NEEDS-MANUAL (uji di HP)
- [ ] (diisi QA dari SPEC bagian NEEDS-MANUAL dan temuan)

## Keputusan & catatan
- Keputusan pemilik 2026-10-14: jendela kena koran lewat sakelar `Config`, bawaan penalti ringan (antaran tidak sah, tanpa potong koin); keputusan akhir tetap terbuka (ROADMAP 5). Ukuran ubin 64×32 dikunci (ROADMAP 4b), dicatat orchestrator di `9405c45`.
- Uji HP oleh pemilik sendiri (bukan 3–5 orang). Izin pasang APK: vivo V2108 (`12d8c9da`) setelah QA PASS; A54 bila tersambung.
