# Loop Log — 20261013-fase1a-gerak
Scope: Run 1A Fase 1, logika gerak inti (BikeMotion, rem, meluncur, stamina, lateral analog dengan batas, pause, laju kayuh, sprite meluncur/rem)  ·  Branch: feat/fase1a-gerak  ·  Mulai: 2026-10-13  ·  Godot: 4.7.2.stable.official.ed1daf0bf

## Status: IN_PROGRESS   (iterasi saat ini: 1/2)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## NEEDS-MANUAL (uji di HP)
Daftar awal ada di SPEC bagian "Butuh uji perangkat nyata". Dev dan QA menambah langkah di sini.

## Keputusan & catatan
- Keputusan pemilik 2026-10-13: pindah sisi analog bebas (bukan kunci jalur); sprite stick bawah ikuti fisika (D-7); PR #19 di-merge sebelum run; uji HP Fase 0 lolos tanpa angka yang diubah.
- RUN_ID diganti dari 20261010 ke 20261013 (tanggal mulai, LOOP-DEV-QA 6b).
- A54 tidak tersambung saat persiapan (`adb devices` kosong, 2026-10-13); dicek ulang setelah QA.

## Catatan Dev

## Catatan QA
