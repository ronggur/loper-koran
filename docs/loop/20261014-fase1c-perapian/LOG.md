# Loop Log — 20261014-fase1c-perapian
Scope: Run 1C Fase 1, perapian temuan Run 1B (QA-001 tes cabang pertahanan, QA-002 gambar tombol jeda, QA-003 probe keluar bersih, QA-004 probe render tidak ikut APK normal, QA-006 debu ruang dunia); tanpa penyetelan (uji HP 8.2 belum ada)  ·  Branch: `fix/fase1c-perapian`  ·  Mulai: 2026-10-14  ·  Godot: 4.7.2

## Status: IN_PROGRESS   (iterasi saat ini: 1/2)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## NEEDS-MANUAL (uji di HP)
- [ ] (orchestrator) APK debug normal di vivo V2108: terpasang, jalan, isi APK tanpa berkas probe render.
- [ ] (QA-002) Tahan jempol di tombol jeda, tekan home, kembali, ketuk "Lanjut": ikon jeda tampil normal.
- [ ] (QA-006) Jejak debu tertinggal di jalan saat pindah sisi, terbaca dan tidak mengganggu.
- [ ] (QA-001 Q04) Swipe gesture navigasi sistem di atas tombol jeda tidak memicu jeda/lanjut.
- [ ] Checklist uji 3-5 orang Fase 1 (`SETUP_ANDROID.md` 8.2), termasuk QA-005 Run 1A dan Run 1B.

## Keputusan & catatan
- Keputusan pemilik 2026-10-14 (lihat SPEC): hasil uji HP 8.2 belum ada (kolom perintah masih template), jadi tidak ada angka penyetelan yang diubah; QA-005 Run 1A/1B tetap NEEDS-MANUAL. QA-004 dikerjakan (masuk scope).
- Lingkungan (orchestrator, 2026-10-14): Godot 4.7.2 `/opt/homebrew/bin/godot`; `adb` hanya vivo V2108 (12d8c9da), A54 tidak tersambung. `main` = `origin/main` = 7acbef7 (PR #21). PR #22 (docs perintah Run 1C) masih terbuka dan tidak dibutuhkan run ini.
