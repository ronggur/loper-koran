# Loop Log — 20261023-ui1-komponen-bengkel
Scope: Run UI-1 — redesain UI langkah 1-2 (komponen + bengkel tata C)  ·  Branch: feat/ui1-komponen-bengkel  ·  Mulai: 2026-10-23  ·  Godot: 4.7.2.stable.official.ed1daf0bf

## Status: IN_PROGRESS   (iterasi saat ini: 1/2, Dev bagian A berikutnya)

## Lingkungan (orchestrator, awal run)
- `main` = `origin/main` = `b99f5a9` (rilis 0.6.0; memuat PR #61, #62, #63). Branch dibuat dari sana.
- Godot 4.7.2 di `/opt/homebrew/bin/godot`; python3 dengan numpy 2.5.3 dan pillow 12.3.0; `cv2`/`sklearn` TIDAK terpasang (hanya dibutuhkan `latar_bengkel.py` membuat ulang latar; `--salin` hanya menyalin berkas jadi tidak perlu).
- `adb devices`: tidak ada perangkat tersambung (vivo/A54 belum dicolok). Pemasangan APK menunggu perangkat tersambung dan QA PASS.
- sha256 save asli `Kring Kring!/save.json` awal run: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e`.
- `.claude/` untracked di working tree: bukan bagian run, tidak di-commit.

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 1 | (bagian A, B, C belum) | | | | |

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## Baseline (AC-1; diisi Dev bagian A langkah 1)

## Perubahan tes lama (AC-8; setiap tes lama yang diubah dan alasannya)

## Butir terbuka pemilik
- **Lisensi latar bengkel** (`docs/design/redesain/latar_bengkel/sumber_ai.jpg`): generator dan ketentuan lisensi komersial belum dicatat. Latar dipasang untuk uji HP (U-4) tapi TIDAK boleh masuk rilis sebelum dicatat (ART_DIRECTION 9).

## NEEDS-MANUAL (uji di HP)
- [ ] SETUP_ANDROID 8.18 (lihat SPEC): bengkel terbaca sekilas; sepeda dan chip kondisi jelas; tombol enak ditekan, tiga keadaan jelas bedanya; kartu menonjol vs redup; harga dekat tombol; latar tidak mengganggu teks; tiga upgrade tanpa scroll; 60 fps.

## Keputusan & catatan
- Putusan U-1..U-5 dan semua keputusan lama: lihat SPEC. Tidak ada keputusan terbuka yang menghambat saat SPEC ditulis; kalau tata C tidak muat di 640 untuk teks terpanjang, berhenti dan tanyakan SEKALI dengan satu rekomendasi.
