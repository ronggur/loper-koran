# Loop Log — 20261022-fase5d-sisi-dekat
Scope: Run 5D, Fase 5 (dimajukan dari Fase 8): pelanggan sisi dekat mulai hari 3 (8-9 dari 25), tembok dekat dihapus jadi halaman terbuka, rumah dekat mundur 0,5 ubin dan didesain ulang dengan teras menjorok  ·  Branch: feat/fase5d-sisi-dekat  ·  Mulai: 2026-10-22  ·  Godot: 4.7.2

## Status: IN_PROGRESS   (iterasi saat ini: 1/2, bagian A)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## Baseline (orchestrator, `main` 53408cf, 2026-10-22; `main` lalu maju ke f42e22e = PR #55, hanya dokumen)
- `godot --headless --import`: 0 baris ERROR/WARNING. `godot --headless --path . --quit-after 2`: 0 baris ERROR/WARNING.
- `run_tests.gd`: **19022 lolos, 0 gagal**; `tools/cek_keluaran_tes.py`: lolos (0 peringatan).
- 13 `tools/tests_cek/uji_*.py` exit 0: uji_aset_gelombang1, uji_aset_kucing, uji_aset_lampu_pohon, uji_aset_pasang_5b, uji_aset_pasang_gelombang1, uji_aset_simpang, uji_bangun_frames, uji_pemeriksa, uji_sintesis_{kondisi,lempar,misi,rute,sepeda}.
- sha256 `user://save.json` asli (`~/Library/Application Support/Godot/app_userdata/Kring Kring!/save.json`): `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e`.
- HP: `adb devices` kosong.

## NEEDS-MANUAL (uji di HP)
Lihat SPEC bagian NEEDS-MANUAL dan SETUP_ANDROID 8.16.

## Keputusan & catatan
- Putusan K-1..K-5, P-1..P-6, D-1..D-7: SPEC.
- Bagian 6j LOOP-DEV-QA sudah di `main` (PR #55, f42e22e); run ini hanya menyentuh tabel 6g.
- Izin pemilik (perintah run): sesudah QA PASS orchestrator push dan membuka PR; merge oleh pemilik. HP: vivo V2108 boleh `adb install -r` sesudah QA PASS bila tersambung.
