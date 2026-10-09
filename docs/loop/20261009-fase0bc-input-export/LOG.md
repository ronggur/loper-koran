# Loop Log — 20261009-fase0bc-input-export
Scope: Run 0B + 0C digabung (input touch, sepeda placeholder, export Android, APK debug)  ·  Branch: feat/fase0bc-input-export  ·  Mulai: 2026-10-09  ·  Godot: 4.7.2.stable.official.ed1daf0bf

## Status: IN_PROGRESS   (iterasi saat ini: 1/2)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 1 | (Dev-0B, lalu Dev-0C) | | | | |

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## NEEDS-MANUAL (uji di HP)
Daftar awal ada di SPEC bagian "Butuh uji perangkat nyata". Dev dan QA menambah langkah di sini.

- [ ] (dari run 0A, Q-012/Q-013) Tangkapan layar A54 dan `cek_blok_piksel.py 3`, tinggi jendela 1080 (imersif).
- [ ] (dari run 0A, Q-014) Light 2D / glow / partikel / shader di Compatibility pada HP: bukan bagian run ini.

## Catatan Dev (per pemanggilan)
Dev menulis gerbang yang dijalankan, perintah persis, dan keluaran ringkas di sini: satu bagian per pemanggilan (Dev-0B, Dev-0C, dan iterasi 2 bila ada). Termasuk: nama kelas bila berbeda dari SPEC D-1, perintah ekspor APK, durasi dan ukuran APK, hasil `aapt2`/`apksigner`/`apkanalyzer`, nilai min SDK/target SDK/`allowBackup`, daftar izin dan penjelasannya.

## Keputusan & catatan
- Keputusan pemilik (2026-10-09): run 0B dan 0C digabung; izin pasang APK ke A54 (hanya orchestrator yang menyentuh HP); format terjemahan CSV `translations/ui.csv`; izin unduh export templates 4.7.2. Lihat SPEC.
- Orchestrator: export templates 4.7.2 diunduh dari `godotengine/godot-builds` (`Godot_v4.7.2-stable_export_templates.tpz`, 1,2 GB) ke folder scratchpad, SHA-512 dicocokkan dengan `SHA512-SUMS.txt` rilis, lalu diekstrak ke `~/Library/Application Support/Godot/export_templates/4.7.2.stable/` (status di bagian bawah setelah selesai).
- Keputusan struktur D-1..D-8 ada di SPEC; yang diambil orchestrator tanpa tanya pemilik dan bisa ditolak di review PR.
