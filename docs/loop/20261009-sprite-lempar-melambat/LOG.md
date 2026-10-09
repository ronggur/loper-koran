# Loop Log — 20261009-sprite-lempar-melambat
Scope: pasang sprite melambat dan lempar koran (usulan, PR #15) ke game untuk dilihat di A54  ·  Branch: feat/sprite-lempar-melambat  ·  Mulai: 2026-10-09  ·  Godot: 4.7.2.stable.official.ed1daf0bf

## Status: IN_PROGRESS   (iterasi saat ini: 1/2)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 1 | | | | | |

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## NEEDS-MANUAL (uji di HP)
Daftar awal ada di SPEC bagian "Butuh uji perangkat nyata". Dev dan QA menambah langkah di sini.

## Catatan Dev
Dev menulis gerbang yang dijalankan (perintah persis dan keluaran ringkas), pembuatan `.tres` (perintah dan hash), daftar tes lama yang diubah beserta alasannya, ukuran terukur (posisi alas sprite sebelum, saat, sesudah lempar), dan keputusan kecil di sini.

## Keputusan & catatan
- Keputusan pemilik (2026-10-09): pasang sprite melambat dan lempar dulu untuk dilihat sebelum Fase 1; skala tetap x3; izin pasang APK ke A54 berlaku (hanya orchestrator yang menyentuh HP). Lihat SPEC.
- Keputusan struktur D-1..D-6 ada di SPEC; diambil orchestrator dan bisa ditolak di review PR.
