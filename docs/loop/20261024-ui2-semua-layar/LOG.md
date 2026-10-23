# Loop Log — 20261024-ui2-semua-layar
Scope: Run UI-2 — redesain UI langkah 3-6 (hasil, koran, jeda, tutorial, banner, tombol jeda HUD) dalam satu PR  ·  Branch: feat/ui2-semua-layar (dari main d16b3bb, 0.7.0)  ·  Mulai: 2026-10-24  ·  Godot: 4.7.2.stable.official.ed1daf0bf

## Status: IN_PROGRESS   (iterasi 1/2)

## Lingkungan (orchestrator, awal run)
- Basis: `main` = `origin/main` = `d16b3bb` (rilis 0.7.0; memuat PR #64 UI-1). Branch dibuat dari sana.
- `adb devices`: tidak ada perangkat tersambung pada 2026-10-24 awal run.
- sha256 save asli: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e`.
- `.claude/` untracked: bukan bagian run, tidak di-commit.

## Amandemen scope (orchestrator, 2026-10-24, sebelum Dev A)
Pemilik menambah dua permintaan setelah SPEC ditulis: font bengkel dan hasil terlalu kecil, dan HUD diatur ulang (kecepatan dan stamina menumpuk). Menjadi V-8 (skala font +2, semua layar penuh, bengkel ikut) dan V-9 (H-1 panel bawah berdampingan, H-2 kolom kanan atas dipadatkan, H-3 tombol jeda) di SPEC; menggantikan V-6, AC-6, AC-8 versi awal. Catatan Dev per tes yang diubah wajib di bagian masing-masing.

## Butir terbuka pemilik
- Lisensi latar bengkel (UI-1) belum dicatat; belum boleh masuk rilis (ART_DIRECTION 9).
- Keputusan QA-003/D-1/D-2 UI-1 (kontras garis kartu, margin inset).
- Lapisan jeda 72 % (V-2) dinilai di HP.

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## Baseline (AC-1; diisi Dev bagian A, 2026-10-24, pohon kerja bersih di `b637062`, `main` + UI-1)
- `godot --headless --import`: tanpa ERROR/WARNING (0 baris).
- `run_tests.gd`: **23406 lolos, 0 gagal**; `tools/cek_keluaran_tes.py`: "lolos (23406 lolos, 0 gagal, 0 peringatan)".
- Semua `tools/tests_cek/uji_*.py` (17 berkas): exit 0 semua (aset_fase3, aset_gelombang1, aset_kucing, aset_lampu_pohon, aset_pasang_5b, aset_pasang_gelombang1, aset_simpang, bangun_frames, pemeriksa, sintesis_{kondisi,lempar,milestone,misi,rute,sepeda}, ui_lencana, ui_redesain).
- sha256 save asli sebelum dan sesudah baseline: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e` (tidak berubah).
- Tangkapan "sebelum" (jendela asli, 1920x1080 dan 2340x1080) di `shots/baseline/`: `bengkel_*` (probe_bengkel, 0 keadaan tidak sesuai), `hud_*` (probe_hud_rute: HUD, layar jeda `hud_jeda_sakelar`, layar hasil `hud_hasil_*`), `reputasi_*` (probe_reputasi: HUD reputasi dan layar hasil tujuh keadaan + inset + dari rute nyata), `koran_*` (probe_halaman_koran), `misi_*` (probe_misi: banner `misi_banner_*`, tutorial `misi_tutorial_lempar`, hasil `misi_hasil_*`). Semua probe: "probe selesai, 0 keadaan tidak sesuai".

## Bagian A — komponen tambahan + Hasil

### A1 — Skala font V-8 (selesai)
**Hasil: kenaikan PENUH (+2) terpasang untuk SEMUA elemen target; tidak ada elemen yang turun ke +1.**
- `assets/ui/theme.tres`: `LayarTeksUtama` 10 -> 12, `LayarTeksKecil` 9 -> 11, `LayarTeksMini` 8 -> 10, `LayarLabel` 8 -> 10, `TombolPeran` dan `TombolTipis` 10 -> 12, `ChipTeks` 10 -> 12, `ChipTeksBesar` 12 -> 14, `ChipTeksKecil` 8 -> 10. `LayarJudul` 24 tidak berubah. Variation HUD lama (`HudLabel`, `HudAngka`, `HudTeks`, `TeksKecil`, `JudulLayar`, `JudulBesar`) tidak diubah.
- Tinggi baris Lexend terukur (`Font.get_height`): 10 px = 13, 11 px = 14, 12 px = 15, 14 px = 18. Lebar terukur: "Ban Anti-Selip" 87 px (12 px SemiBold), "Rantai Hemat" 84 px, "Rem Pakem Racing Edition" (24 huruf) 163 px.
- `scripts/config.gd` (angka layout bengkel menyesuaikan, ukuran slice aset TIDAK berubah): chip kecil/normal/besar 14/18/24 -> **16/20/26** (`UI_CHIP_TINGGI_*`, pad vertikal kecil 2 -> 1); `BENGKEL_BAGIAN_TINGGI_PX` 12 -> 14; `BENGKEL_CATATAN_TINGGI_PX` 12 -> 14; `BENGKEL_PANEL_PAD_PX` 8 -> 6; kartu upgrade 62 -> **70** (tingkat tunggal) dan 72 tetap (bertingkat); kartu servis tetap 50 (jarak teks servis 3 -> 2, jarak baris status 2 -> 1); `BENGKEL_KARTU_JARAK_PX` 6 -> 4 -> 3 dan `BENGKEL_KARTU_PAD_AWAL_PX` 8 -> 6 (supaya nama upgrade nyata muat penuh di kolom upgrade sampai isi 580 px, inset aman 36 + 24); baru `BENGKEL_DESKRIPSI_BARIS_JEJAK_MAKS` 2 (kartu bertingkat), `BENGKEL_DESKRIPSI_BARIS_MAKS` 2 -> 3 (kartu tunggal; deskripsi nyata "Stamina awet dan rantai lebih tahan" butuh 3 baris di kolom 296 + inset), `BENGKEL_DESKRIPSI_JARAK_BARIS_PX` 1 (bawaan Label 3).
- `scripts/ui/layar_bengkel.gd`: jatah baris deskripsi per kartu (`max_lines_visible` 3 atau 2 bila ada jejak) dan jarak baris deskripsi dari Config. Struktur, sinyal, API, perilaku tidak berubah.
- Anggaran tinggi di 360: panggung sepeda tetap >= 82 (sepeda 78 + 4) di semua keadaan termasuk inset bawah 20; tiga kartu upgrade + judul bagian + jarak berakhir sebelum tombol "Hari berikutnya" (diperiksa probe: kartu tidak menutupi tombol, termasuk dengan inset).
- Probe `probe_bengkel_jendela.gd` (diperluas: cek kartu tidak menutupi "Hari berikutnya"): **0 keadaan tidak sesuai** di 1920x1080 (640), 2340x1080 (780), 2400x1080 (800), 1600x720 (800). Tangkapan di `shots/iter1/`. Kontras (`tools/ukur_kontras_tangkapan.py`, 1920x1080): semua teks >= 7,79:1 (terburuk "! Ban" 7,79; "Baik" 8,28), tombol >= 8,53:1; garis kartu 1,14..1,65:1 dan tombol nonaktif 1,14:1 (D-1 UI-1, tidak berubah, bukan kontrol aktif).
- Perubahan terukur: tinggi tinta "Rem Pakem" 7 -> 9 px game (+2), baris kecil "Perlu servis" 6,3 -> 7,7, "Banyak yang rusak..." 9 -> 11 (ukur kasar dari tangkapan 1920x1080 keadaan b, sebelum vs sesudah).
- Perbedaan tangkapan bengkel vs baseline UI-1: hanya ukuran huruf, tinggi chip, tinggi kartu upgrade, jarak baris, dan letak elemen yang bergeser karenanya (struktur sama).

Tes lama yang diubah (V-8; semua karena angka ukuran, bukan perilaku):
| Tes | Perubahan | Alasan |
|---|---|---|
| `tests/tes_komponen_ui.gd` `_test_tema` | ukuran font yang dijaga 10/9/8/10/8/12/10/10 -> 12/11/10 (Mini, ditambah)/10/10/14/12/12 | V-8 |
| `tests/tes_komponen_ui.gd` (dua `check`) | tinggi chip 14/18/24 -> 16/20/26 (`Config` dan `KomponenUi.tinggi_chip`) | V-8: tinggi baris Lexend 13/15/18 tidak muat di 14/18/24 |
| `tests/tes_tampil_bengkel.gd` | tinggi kartu upgrade tunggal 62 -> 70, bertingkat 72 (tetap) | V-8 |
| `tests/tes_bengkel_tata_c.gd` | chip Baik 18 -> 20, chip penanda 14 -> 16, chip saldo/harga 24/18 -> 26/20, kartu upgrade tunggal 62 -> 70, kartu servis tetap 50, jejak 72 tetap, komentar jatah baris deskripsi | V-8 |

## Bagian B — Koran

## Bagian C — Jeda, tutorial, banner, HUD

## Bagian D — dokumen

## NEEDS-MANUAL
Lihat SPEC (SETUP_ANDROID 8.19).
