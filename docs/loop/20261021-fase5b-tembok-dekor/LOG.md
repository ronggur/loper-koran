# Loop Log — 20261021-fase5b-tembok-dekor
Scope: Run 5B, Fase 5, tembok sisi dekat, dekor di data segmen (tong sampah, pohon, lampu jalan), ubin masuk garasi/simbol sepeda/rumput bervariasi, hanya tampilan dan data dekor  ·  Branch: feat/fase5b-tembok-dekor  ·  Mulai: 2026-10-21  ·  Godot: 4.7.2.stable.official.ed1daf0bf

## Status: IN_PROGRESS   (iterasi saat ini: 1/2, Dev belum mulai)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## NEEDS-MANUAL (uji di HP)
Lihat SPEC bagian NEEDS-MANUAL dan `docs/SETUP_ANDROID.md` 8.13 (ditulis Dev).

## Keputusan & catatan
- Persiapan orchestrator (2026-10-21): `main` = `origin/main` = `6edf5ba` (memuat PR #45 run 5A, #46 CI APK, #47 rilis 0.2.0). Branch kerja `feat/fase5b-tembok-dekor` dari situ. PR #48 (docs perintah 5B, Bagian 6h) masih terbuka dan belum di-merge; run ini TIDAK menyentuh Bagian 6h supaya tidak bentrok. Godot 4.7.2 (`/opt/homebrew/bin/godot`), `adb devices` kosong (tidak ada HP tersambung saat persiapan).
- Hasil uji HP 4A, 4B, 6A1, 5A: kosong (baris `ISI: ...` pada perintah tidak diisi pemilik, diperlakukan kosong).
- Keputusan pemilik: K-1 sampai K-5 di SPEC. Keputusan desain orchestrator D-1 sampai D-8 di SPEC (usulan, bisa ditolak di review PR). Dua penyesuaian atas perintah yang dilaporkan ke pemilik: (1) `aspal_N` polos TIDAK dipasang (D-4: tanpa garis tepi, memutus garis kerb; butuh varian kolom dari renderer); (2) tapak logika rumah dekat tidak digeser, hanya gambar (D-2: `RUTE_RUMAH_DEKAT_X_UBIN` 3,0 tetap; tembok pusat 3,125 = sisi jalan di 3,0 + setengah tebal 0,125; mundur gambar 1,25 sebagai konstanta baru).
- Baseline tes sebelum run (main 6edf5ba, Godot 4.7.2): **17324 lolos, 0 gagal**, pemeriksa keluaran lolos (catatan: log run 5A mencatat 17325 pada akhir iterasi 2; selisih 1 `check` belum dijelaskan, bukan kegagalan).
- sha256 `user://save.json` asli (`~/Library/Application Support/Godot/app_userdata/Kring Kring!/save.json`, mtime 17 Okt) sebelum run: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e`; sama sesudah baseline.
- Pelajaran dari 5A yang berlaku: jangan menjalankan dua proses Godot tes bersamaan (tes simpan `user://` bentrok); galat parse di berkas tes membuat `run_tests.gd` menggantung (beri batas waktu); tekstur dimuat di `_init`/`_ready`, bukan di `_draw`.
