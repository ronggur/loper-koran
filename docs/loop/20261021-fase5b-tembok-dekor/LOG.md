# Loop Log — 20261021-fase5b-tembok-dekor
Scope: Run 5B, Fase 5, tembok sisi dekat, dekor di data segmen (tong sampah, pohon, lampu jalan), ubin masuk garasi/simbol sepeda/rumput bervariasi, hanya tampilan dan data dekor  ·  Branch: feat/fase5b-tembok-dekor  ·  Mulai: 2026-10-21  ·  Godot: 4.7.2.stable.official.ed1daf0bf

## Status: IN_PROGRESS   (iterasi saat ini: 1/2, Dev bagian A selesai; bagian B dan C belum)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## Iterasi 1, bagian A (Dev): renderer, `--salin`, uji aset (AC-1, AC-2, AC-3, sebagian AC-23)

Commit (branch `feat/fase5b-tembok-dekor`, belum push): `b050b47` art (renderer + 23 sprite/ubin + `.import`), `6f6f6e3` test (dua uji Python baru, golden, CI), commit ketiga `test:` (daftar isi folder di `tes_koran_sprite.gd` dan `tes_ubin.gd`).

**Yang dikerjakan**
- `tools/env_art/gelombang1/render.py --salin`: `PASANG_5B` menambah `house_tembok_{polos,bata,besi,pot,tiang}` ke `assets/sprites/houses/perumahan/` dan `prop_tong_sampah_logam` ke `props/`. Tong biru TIDAK. `PASANG` (isi 5A) tidak disentuh; 61 berkas isi 5A + lama dibuktikan byte-identik (golden sha256).
- `tools/env_art/lampu_pohon.py --salin` (baru, `ENV_ART_SALIN_KE` = folder props langsung): `prop_pohon_{rindang,glodokan,ketapang}` (seed 3, sama dengan `ekspor_pohon`) dan lampu `lengan` bingkai MATI sebagai `prop_lampu_lengan_seberang` dan `prop_lampu_lengan_dekat` (satu bingkai). Jalan tanpa argumen: 38 berkas `build/env_art/lampu_pohon/` sama persis dengan skrip lama (diperiksa piksel lawan skrip dari commit d102d61; golden sha256 di `tools/tests_cek/golden_aset_5b.json`).
- `tools/env_art/ubin_perumahan.py --salin`: `PASANG_TAMBAHAN` = `rumput_1,2,3`; `PASANG_KHUSUS` = `trotoar_seberang_masuk`, `rumput_seberang_masuk`, `trotoar_seberang_simbol`, `trotoar_dekat_simbol`. `aspal_1..3` dan `*_dekat_masuk` TIDAK. `tile_perumahan.json` terpangkas diperbarui oleh skrip (kunci baru `ubin_khusus`; `ubin_polos_luar` kini 3 nama; `tiles` 13 PNG; `kolom_x_ubin` tetap).
- Ketiga `--salin` dijalankan (bukan salin tangan), `godot --headless --import` bersih, 17 `.png.import` baru dikomit: semuanya `compress/mode=0`, `mipmaps/generate=false`, `vram_texture` false, uid ada (tidak ada `.uid` terpisah untuk PNG). `tests/run_tests.gd` sudah memeriksa `.import` Lossless setiap PNG di `assets/sprites` (itulah sebab hitungan lolos naik 85 = 17 PNG x 5 pemeriksaan, bukan tes baru).
- Uji baru: `tools/tests_cek/uji_aset_lampu_pohon.py` (AC-2, 183 pemeriksaan) dan `tools/tests_cek/uji_aset_pasang_5b.py` (AC-1/AC-3, 355); `uji_aset_pasang_gelombang1.py` diperbarui (daftar folder `houses/perumahan`, props, ubin; `TIDAK_DIPASANG` dilonggarkan hanya untuk aset D-1; 373). Semua punya kontrol "satu byte/piksel diubah terdeteksi" dan exit 2 bila numpy/pillow tak ada. Tiga langkah di `.github/workflows/tes.yml` (langkah 5A diberi nama folder baru, dua langkah baru).
- Dua tes GDScript yang memeriksa ISI folder aset gagal karena berkas baru: `tests/tes_ubin.gd` (`UBIN_5B`, folder `tiles/perumahan`) dan `tests/tes_koran_sprite.gd` (`SUFIKS_5B_PROPS`, folder `props`; awalan `prop_` ditambahkan di kode supaya pemindai rujukan tidak mengira ada rujukan kode). Hanya daftar isi folder yang diperluas; pemindai "tidak ada rujukan ke aset belum dipasang" (`TERLARANG`, regex `rumput_[02-9]|_masuk|_simbol`, `dikenal`) TIDAK dilonggarkan. Bagian B/C yang mulai merujuk nama-nama itu harus memperluas pemindai itu (AC-18) bersama kodenya. Rujukan 5B di `tes_export.gd` (`JALUR_WAJIB_IKUT`, AC-17) belum ditambahkan (bagian C).

**Ukuran sel dan titik pijak (untuk bagian B; px sprite 1x, pijak = `ground_anchor` dari kiri atas sel)**

| Sprite | Berkas JSON | Sel (lebar x tinggi) | Pijak (x, y) | Catatan |
|---|---|---|---|---|
| `house_tembok_{polos,bata,besi,pot,tiang}` | `houses/perumahan/` | 46 x 46 | (41, 25) | satu bingkai, modul 1 ubin; sambung geser (-32, +16) px |
| `prop_tong_sampah_logam` | `props/` | 20 x 30 | (10, 25) | tapak r 7 unit |
| `prop_pohon_rindang` | `props/` | 151 x 119 | (41, 63) | pijak = pangkal batang; ada bayangan baked |
| `prop_pohon_glodokan` | `props/` | 121 x 126 | (25, 77) | idem |
| `prop_pohon_ketapang` | `props/` | 141 x 124 | (35, 70) | idem |
| `prop_lampu_lengan_seberang` | `props/` | 85 x 104 | (9, 63) | lengan ke kanan bawah, pijak = kaki tiang, tinggi tiang 56 unit |
| `prop_lampu_lengan_dekat` | `props/` | 85 x 104 | (22, 69) | lengan ke kiri atas, pijak = kaki tiang |
| ubin baru (6) | `tiles/perumahan/` | 64 x 32 | (32, 16) | |

Catatan: (1) JSON pohon/lampu memakai bentuk 5A (`cell`, `frames` 1, `fps` 0, `ground_anchor`, `board` "dekor"), bukan `size` seperti JSON lama pohon di `build/`; keputusan saya supaya `DefSprite`-semacam bisa dipakai bagian B sama untuk semua. (2) Sel pohon/lampu lebar karena bayangan semi-transparan (#000000 alfa 71) ikut dirender ke tanah (lampu: bayangan memanjang ke kanan; piksel tiang/kepala hanya ~20x60). Posisi bayangan jatuh ke arah kanan bawah dari pijak pada semua sisi: bagian B perlu menilai apakah ini wajar di sisi dekat (bayangan tidak mengikuti sisi). Bukan keputusan saya, dicatat saja. (3) Palet pohon dan lampu MELEBIHI palet induk 2.4: tiap sprite 8 sampai 10 warna opak, hanya 1 sampai 3 di palet induk, total 23 warna di luar palet induk (katalog `KATALOG_RENDERER` di `uji_aset_lampu_pohon.py`, ramp bahan daun/batang/tiang `lib.py` dan `lampu_pohon.py`). Palet tidak dikunci (K-3), dicatat sesuai AC-2.

**Gerbang** (semua dijalankan sesudah commit terakhir)
- `godot --headless --import`: tanpa ERROR. `godot --headless --path . --quit-after 2`: tanpa ERROR/WARNING.
- `run_tests.gd` + `tools/cek_keluaran_tes.py`: **17409 lolos, 0 gagal** ("pemeriksa: lolos (17409 lolos, 0 gagal, 0 peringatan)"). Baseline main d102d61 dijalankan ulang di worktree terpisah: 17324 lolos, 0 gagal (selisih +85 = pemeriksaan `.import` 17 PNG, lihat di atas). Sebelum pembaruan dua daftar folder: 17407 lolos, 2 gagal (hanya dua pemeriksaan isi folder di atas).
- Semua `python3 tools/tests_cek/uji_*.py` lolos: gelombang1 352, kucing 12, lampu_pohon 183, pasang_5b 355, pasang_gelombang1 373, bangun_frames 51, pemeriksa 16 kasus, sintesis (kondisi 55, lempar 111, misi 47, rute 90, sepeda 32).
- sha256 `user://save.json` asli sesudah tes dan mutan: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e` (sama dengan sebelum).
- Catatan: `godot --headless --import` ikut mengimpor PNG di `build/env_art/...` (folder `build/` tidak punya `.gdignore`; ter-ignore git, tidak berpengaruh ke repo). Tidak diubah.

**BLOCKED**: tidak ada.

**Mutan bagian A** (satu perubahan, uji terkait, `git checkout`/hapus berkas; `git status` bersih sesudah semuanya; "T5" = `uji_aset_pasang_5b.py`, "TL" = `uji_aset_lampu_pohon.py`, "T1" = `uji_aset_pasang_gelombang1.py`, "RT" = `run_tests.gd`)

| ID | File | Perubahan | Terdeteksi oleh |
|---|---|---|---|
| A1 | render.py | `prop_tong_sampah_biru` ikut di `PASANG_5B` (tong biru tersalin) | T5, T1: daftar `--salin` props beda |
| A2 | render.py | `house_tembok_tiang` dibuang dari `PASANG_5B` | T5, T1: daftar houses/perumahan (3 GAGAL) |
| A3 | ubin_perumahan.py | `aspal_1` ikut `PASANG_KHUSUS` | T5, T1: daftar ubin |
| A4 | ubin_perumahan.py | `trotoar_dekat_masuk` ikut `PASANG_KHUSUS` | T5, T1: daftar ubin |
| A5 | ubin_perumahan.py | JSON terpangkas memuat kunci `tiles_extra` dengan `aspal_1` | T5: JSON tidak byte-identik |
| A6 | ubin_perumahan.py | `tiles` JSON menyebut `aspal_1` | T5, T1: JSON tidak byte-identik |
| A7 | render.py | sprite `prop_tong_sampah_logam` digambar dengan `tong_sampah('biru')` | T5: piksel beda dari assets; `uji_aset_gelombang1.py`: mock docs beda |
| A8 | lampu_pohon.py | pijak lampu geser +5 px y | TL (4 GAGAL), T5 (JSON) |
| A9 | lampu_pohon.py | lampu dirender NYALA di `--salin` | TL (6 GAGAL: bukan bingkai mati), T5 |
| A10 | lampu_pohon.py | `beringin` ikut `PASANG_POHON` | TL, T5: daftar 5 sprite |
| A11 | lampu_pohon.py | `SEED_POHON` 3 jadi 4 | T5 (5 GAGAL, piksel beda dari assets) |
| A12 | lampu_pohon.py | seed `ekspor_pohon` 3 jadi 4 (keluaran tanpa argumen) | TL (40 GAGAL, golden keluaran lama) |
| A13 | lampu_pohon.py | urutan `PASANG_LAMPU` ditukar | LOLOS (mutan setara: nama dan isi tak berubah; kontrol, bukan celah) |
| A14 | lampu_pohon.py | nama lampu seberang dan dekat tertukar | TL, T5 |
| A15 | lampu_pohon.py | `--salin` tidak menyalin apa pun | TL (crash folder tak ada), T5 (11 GAGAL) |
| A16 | `.import` house_tembok_bata | `compress/mode=1` (bukan Lossless) | T5 |
| A17 | house_tembok_bata.png | satu piksel opak diubah | T5: piksel beda dari keluaran skrip |
| A18 | assets tile_perumahan.json | `aspal_1` ditambah ke `tiles` | T5 (2 GAGAL: JSON dan isi) |
| A19 | assets tiles/perumahan | berkas `tile_perumahan_aspal_1.png` liar | T5 (2 GAGAL); RT: tak ada `.import` dan folder tak sesuai |
| A20 | prop_koran_putar.png (isi 5A) | satu byte diubah | T5: golden sha256 5A |
| A21 | `.import` prop_pohon_rindang | `mipmaps/generate=true` | T5 |
| A22 | `.import` rumput_2 | `compress/mode=2` (VRAM) | T5 |
| A23 | prop_tong_sampah_logam.json | pijak y 25 jadi 26 | T5 (JSON byte) |
| A24 | assets props | `prop_pohon_beringin.png` liar | T5 (2 GAGAL); RT: tak ada `.import`, folder props tak sesuai |
| A25 | assets props | `prop_lampu_lengan_dekat_nyala.png` liar | T5 (3 GAGAL) |
| A26 | assets houses/perumahan | `house_tembok_besi_dekat_masuk.png` liar | T5 |

26 mutan, 25 terdeteksi, 1 mutan setara (A13). Mutan bagian lain (modul tembok, hash varian, dst. di AC-23) menyusul bersama kodenya di bagian B dan C.

## NEEDS-MANUAL (uji di HP)
Lihat SPEC bagian NEEDS-MANUAL dan `docs/SETUP_ANDROID.md` 8.13 (ditulis Dev).

## Keputusan & catatan
- Persiapan orchestrator (2026-10-21): `main` = `origin/main` = `6edf5ba` (memuat PR #45 run 5A, #46 CI APK, #47 rilis 0.2.0). Branch kerja `feat/fase5b-tembok-dekor` dari situ. PR #48 (docs perintah 5B, Bagian 6h) masih terbuka dan belum di-merge; run ini TIDAK menyentuh Bagian 6h supaya tidak bentrok. Godot 4.7.2 (`/opt/homebrew/bin/godot`), `adb devices` kosong (tidak ada HP tersambung saat persiapan).
- Hasil uji HP 4A, 4B, 6A1, 5A: kosong (baris `ISI: ...` pada perintah tidak diisi pemilik, diperlakukan kosong).
- Keputusan pemilik: K-1 sampai K-5 di SPEC. Keputusan desain orchestrator D-1 sampai D-8 di SPEC (usulan, bisa ditolak di review PR). Dua penyesuaian atas perintah yang dilaporkan ke pemilik: (1) `aspal_N` polos TIDAK dipasang (D-4: tanpa garis tepi, memutus garis kerb; butuh varian kolom dari renderer); (2) tapak logika rumah dekat tidak digeser, hanya gambar (D-2: `RUTE_RUMAH_DEKAT_X_UBIN` 3,0 tetap; tembok pusat 3,125 = sisi jalan di 3,0 + setengah tebal 0,125; mundur gambar 1,25 sebagai konstanta baru).
- Baseline tes sebelum run (main 6edf5ba, Godot 4.7.2): **17324 lolos, 0 gagal**, pemeriksa keluaran lolos (catatan: log run 5A mencatat 17325 pada akhir iterasi 2; selisih 1 `check` belum dijelaskan, bukan kegagalan).
- sha256 `user://save.json` asli (`~/Library/Application Support/Godot/app_userdata/Kring Kring!/save.json`, mtime 17 Okt) sebelum run: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e`; sama sesudah baseline.
- Pelajaran dari 5A yang berlaku: jangan menjalankan dua proses Godot tes bersamaan (tes simpan `user://` bentrok); galat parse di berkas tes membuat `run_tests.gd` menggantung (beri batas waktu); tekstur dimuat di `_init`/`_ready`, bukan di `_draw`.
