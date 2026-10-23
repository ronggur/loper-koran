# Loop Log — 20261023-fase6a2-reputasi-pelanggan
Scope: Run 6A2, Fase 6A bagian kedua: reputasi per distrik, pelanggan tetap (aktif/setia/berhenti, kepribadian), pemetaan pelanggan tetap ke rute yang diacak, potongan koran terbuang (K-1 pemilik), milestone dasar  ·  Branch: feat/fase6a2-reputasi-pelanggan  ·  Mulai: 2026-10-23  ·  Godot: 4.7.2

## Status: IN_PROGRESS   (iterasi saat ini: 0/2, persiapan selesai; Dev iterasi 1 bagian A, B, C belum dimulai)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 0 | Persiapan orchestrator: SPEC, baseline | ✅ | - | - | - |

## Baseline (orchestrator, `main` = 726b59c, branch dari main terbaru, 2026-10-23)
- `godot --headless --import`: 0 baris ERROR/WARNING. `godot --headless --path . --quit-after 2`: 0 baris ERROR/WARNING.
- `run_tests.gd`: **19281 lolos, 0 gagal**; `tools/cek_keluaran_tes.py`: lolos (0 peringatan).
- Semua `tools/tests_cek/uji_*.py` (14 berkas) exit 0.
- sha256 `user://save.json` asli (`~/Library/Application Support/Godot/app_userdata/Kring Kring!/save.json`): `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e`.
- HP: `adb devices` kosong (tidak ada perangkat tersambung saat persiapan).
- Hasil uji HP Run 5D: **tidak diisi pemilik** (baris ISI kosong). QA-001/002/003 5D tidak ditutup; 8.16 NEEDS-MANUAL; butir aset Fase 5 tidak dicentang.
- Fakta data: 9 segmen perumahan, 71 rumah `pelanggan_boleh` (37 seberang, 34 dekat); satu rute memakai 7 dari 9 segmen (sekitar 55 kandidat), jadi pelanggan tetap yang segmennya tidak terpilih hari itu memang tidak muncul hari itu.

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## NEEDS-MANUAL (uji di HP)
Lihat SPEC bagian NEEDS-MANUAL dan SETUP_ANDROID 8.17 (dibuat Dev di bagian C).

## Keputusan & catatan
- Keputusan pemilik K-1..K-4 dan keputusan orchestrator O-1..O-10: SPEC. K-4 (tiga keputusan terbuka) dipakai sebagai rekomendasi tunggal yang ditulis pemilik di perintah run, tidak ditanyakan ulang; dilaporkan di laporan akhir untuk ditolak di review PR bila perlu.
- Izin pemilik (perintah run): sesudah QA PASS orchestrator boleh memasang APK ke vivo V2108 (`adb install -r`), push dan buka PR; merge menunggu konfirmasi pemilik.
