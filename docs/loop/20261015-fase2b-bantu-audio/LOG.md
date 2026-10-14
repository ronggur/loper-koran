# Loop Log — 20261015-fase2b-bantu-audio
Scope: Run 2B Fase 2 — mode bantu, bunyi lempar dan mendarat, QA-008/QA-005/QA-006, checklist uji HP penutup Fase 2  ·  Branch: `feat/mode-bantu-bunyi-lempar`  ·  Mulai: 2026-10-15  ·  Godot: 4.7.2

## Status: IN_PROGRESS   (iterasi saat ini: 1/2)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## NEEDS-MANUAL (uji di HP)
- [ ] (diisi QA)

## Keputusan & catatan
- Keputusan pemilik 2026-10-15 (awal sesi): K-1 santai otomatis + stick opsional; K-2 sisi tap dari garis jalan di zona swipe; K-3 kotak surat pelanggan terdekat di depan, selalu kena, tanpa sasaran = tidak melempar; K-4 jeda 0,35/0,17 tetap. Rincian di SPEC.md.
- Hasil uji HP sebelumnya (run arah bebas, vivo V2108, 2026-10-15): "this is much better". Catatan rinci (kotak surat tiga kecepatan, swipe pendek, garis bidik saat melaju, responsif) belum diisi pemilik; dijadikan butir checklist AC-16.
- Perangkat: vivo V2108 (12d8c9da) tersambung di awal run; A54 tidak tersambung.
