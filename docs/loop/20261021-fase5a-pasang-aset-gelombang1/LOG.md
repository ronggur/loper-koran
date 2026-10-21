# Loop Log — 20261021-fase5a-pasang-aset-gelombang1
Scope: Run 5A, Fase 5, pasang aset gelombang 1 (ubin enam kolom, koran, VFX sepeda, bintang dan koin, kilau misi), hanya tampilan  ·  Branch: feat/fase5a-pasang-aset-gelombang1  ·  Mulai: 2026-10-21  ·  Godot: 4.7.2.stable.official.ed1daf0bf

## Status: IN_PROGRESS   (iterasi saat ini: 1/2)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 1 (bagian A) | Renderer K-1, `--salin`, uji aset, 13 sprite + 7 ubin terpasang, ubin enam kolom di rute (bagian B belum) | import bersih; `run_tests.gd` 16949 lolos 0 gagal (baseline 16735), pemeriksa keluaran lolos; `--quit-after 2` bersih; semua `uji_*.py` lolos | (belum) | 0 | 0 |

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## NEEDS-MANUAL (uji di HP)
Lihat SPEC bagian NEEDS-MANUAL dan `docs/SETUP_ANDROID.md` 8.12 (ditulis Dev).

## Keputusan & catatan
- Persiapan orchestrator (2026-10-21): `main` = `origin/main` = `f2e5b64` (memuat PR #42, #43, #44). Branch kerja `feat/fase5a-pasang-aset-gelombang1` dari situ. Godot terpasang (`/opt/homebrew/bin/godot` 4.7.2), numpy 2.5.3 dan pillow 12.3.0 ada, `adb devices` kosong (tidak ada HP tersambung saat persiapan). Hasil uji HP 4A, 4B, 6A1: kosong (belum ada catatan pemilik).
- Keputusan pemilik yang didelegasikan: K-1 sampai K-5 di SPEC. Keputusan desain orchestrator D-1 sampai D-8 di SPEC (usulan, bisa ditolak di review PR).
- Baseline tes sebelum run (main f2e5b64, Godot 4.7.2): **16735 lolos, 0 gagal**, pemeriksa keluaran lolos.
- sha256 `user://save.json` asli (`~/Library/Application Support/Godot/app_userdata/Kring Kring!/save.json`, mtime 17 Okt) sebelum run: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e`; sama sesudah baseline. Dev dan QA mencatat lagi sesudah semua tes dan probe.
- Pelajaran persiapan: jangan menjalankan dua proses Godot tes bersamaan, tes simpan (`SaveManager` jalur uji, `user://`) bentrok dan menghasilkan dua GAGAL palsu.

### Iterasi 1, bagian A (Dev): renderer, aset terpasang, ubin enam kolom
Commit: `2b0399c` art (K-1, `--salin`, aset), `c48b342` test (uji aset), `e76aee1` feat (ubin enam kolom), `6f56152` + berikutnya test (`tes_ubin.gd`).
- **K-1 (1) kilau**: `mission_kilau` dua warna, krem terang `#FBF6E8` dominan (100% piksel non-garis-luar kecuali satu), kuning aksen `#FFC94A` satu piksel di titik tengah per frame. Diuji (>= 60%, <= 5 piksel kuning, di titik tengah, tidak ada warna ketiga).
- **K-1 (2) tong sampah**: hijau dibuang; `prop_tong_sampah_logam` (abu-abu logam: terang `logam[0]`, dasar `logamg[0]` #5F5B66, gelap `logamg[1]`; warna dasar sengaja bukan `logam[1]` = #969AA0 = RADAR_BUKAN) dan `prop_tong_sampah_biru` (dasar #5F96C8). **Hasil pemeriksaan token DESIGN_SPEC 1.1** (dibaca dari `scripts/ui/palette.gd`: ACCENT, OK, FAIL, WARN, RADAR_PELANGGAN/TIP/MISI/BUKAN): biru #5F96C8 jarak RGB terkecil ke token semantik >= 40 (uji), tidak bentrok, jadi **biru dipertahankan**; logam #5F5B66 tidak bentrok. Manifest tetap 29 sprite (hijau diganti logam; nama berubah, tidak dipasang di rute sampai 5B).
- **K-1 (3) polisi tidur**: `prop_polisi_tidur` kuning-hitam dan kodenya (`polisi_tidur`, `ekspor_polisi_tidur`, `KUNING`, `HITAM_PT`, impor `fase3` yang jadi tidak terpakai) dibuang dari `ubin_perumahan.py`; diuji ekspor di folder sementara, tidak ada berkas polisi di `assets/` dan `docs/design/environment/`; satu-satunya = `tile_perumahan_polisi_tidur` gelombang 1.
- **`--salin`**: `render.py --salin` (13 sprite ke `props/` dan `vfx/`), `ubin_perumahan.py --salin` (enam ubin + `rumput_1` + `tile_perumahan.json` terpangkas). Env `ENV_ART_SALIN_KE` dan `ENV_ART_MOCK_KE` (hanya untuk uji; default repo). Mock docs dirender ulang lewat `--mock`; hanya 3 PNG yang piksel-nya berubah (`komposisi_siang/sore_x3`, `lembar_properti_x5`) yang disimpan, sisanya dikembalikan (byte PNG beda antar run, piksel sama). `uji_aset_gelombang1.py` kini membandingkan semua mock termasuk lembar kontak ke hasil `--mock` di folder sementara.
- **Keputusan D-2, rumput luar** (diukur): `rumput_dekat` identik piksel dengan rumput polos (0 beda), tetapi `rumput_seberang` berbeda 80 piksel dari rumput polos (tepi kerb luar menjorok ke kolomnya, bayangan/silhouet 2,6 unit). Mengulang `rumput_seberang` di kolom luar memberi pita tepi di tiap ubin, jadi **dipasang SATU ubin polos tambahan `tile_perumahan_rumput_1`** (pengecualian atas daftar D-1, dicatat di JSON ubin, README, dan tes) dan dipakai untuk kolom rumput di luar kolom pertama di kedua sisi (`JalanDaur.rumput_luar`, `Config.JALAN_RUMPUT_TEPI_UBIN` = 1,0). `tests/tes_ubin.gd`: ubin kolom luar piksel-identik dengan `rumput_1`, `rumput_seberang` beda dari rumput polos, dan komposisi periodik tanpa pita; Python: susunan dari berkas = adegan renderer pada semua piksel tertutup (0 beda, 0 celah).
- **Tafsir D-2 (batas kolom), mohon QA/pemilik tinjau**: SPEC menulis interval setengah terbuka (`-2 <= x < -1` trotoar_seberang) sekaligus "batas luar inklusif ke jenis luar seperti jenis_di". Keduanya bertentangan di sisi seberang (`jenis_di(-1)` = TROTOAR, `jenis_di(-2)` = RUMPUT). Dipilih konsisten dengan `jenis_di` dan simetri (AC-4 "simetri nama seberang/dekat"): batas |x| = 1 dan 2 ke kolom luar di kedua sisi; hanya x = 0 jatuh ke `dekat`. Tanpa pengaruh pada game (pusat ubin selalu setengah ganjil). Dites dengan tabel literal dan 300 nilai acak.
- **Ubin di `TanahDaur`**: satu wadah per kolom ditambah `RumputLuar` (7 wadah, tiap wadah satu tekstur supaya gambar tergabung per tekstur; dengan tiga wadah per jenis batch akan putus tiap ubin). Jumlah SPRITE ubin dan posisinya tidak berubah (diuji 434/450/496/511 ubin untuk lebar 640/667/780/800 dan = jumlah graybox); node wadah +4 (3 menjadi 7) di scene rute saja. Mode tiga tekstur graybox tetap untuk `jalan_uji.tscn`, spike, dan `cek_render` (tidak disentuh).
- **Pengamatan sebelum run (tidak diubah)**: `JalanDaur.sel_tanah` tidak memuat dorongan kecepatan MUNDUR terbesar; di lebar 640, lateral +2, jarak pecahan tinggi ada celah sudut (sekitar 1.000 piksel transparan) yang sama pada ubin graybox lama. `sel_tanah` dikunci "tidak berubah" (AC-4), jadi `tes_ubin.gd` memeriksa tanpa celah untuk tanpa dorongan dan dorongan maju terbesar saja (360 viewport), dan ini dicatat sebagai temuan yang sudah ada, bukan akibat run ini (DEFERRED ke 5B/6 bila pemilik melihatnya di HP).
- **Tes baru**: `tools/tests_cek/uji_aset_pasang_gelombang1.py` (236 pemeriksaan; langkah di `tes.yml`), `uji_aset_gelombang1.py` (352), `tests/tes_ubin.gd` (sekitar 210 `check`; pemetaan, simetri, `sel_tanah` literal, scene rute, tanpa celah/pita, referensi `tests/data/ubin_potongan_8_maju.png` dengan `.gdignore`, pemindai aset belum dipasang). Referensi dibuat skrip (`--perbarui-referensi`), bukan tangan.
- **Kejadian**: dua kali pernah satu GAGAL palsu (`ban: 'Baik'`) saat dua proses Godot berjalan bersamaan (proses lama tertinggal); tidak terulang sesudah proses tunggal. Galat parse di berkas tes membuat `run_tests.gd` menggantung (pemeriksa keluaran perlu batas waktu bila otomatisasi).
- sha256 `user://save.json` asli sesudah semua tes bagian A: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e` (sama dengan awal).
- **Belum dikerjakan (bagian B)**: koran, permukaan, bayangan, terlipat, VFX, bintang, koin, kilau di game, probe, `tes_export`/paket (AC-16, AC-17 penuh; bagian ubin AC-17 sudah di `tes_ubin.gd`), dokumen AC-20.

### Mutan nyata bagian A (AC-22; tiap mutan satu perubahan, tes penuh atau uji Python, lalu `git checkout`; `git status` bersih sesudah tiap mutan)
| # | File | Perubahan satu baris | Tes yang gagal (pertama) |
|---|---|---|---|
| A1 | `jalan_daur.gd` | `x >= 0.0` jadi `x > 0.0` (batas nol) | `kolom_di(0.0) = ASPAL_DEKAT` |
| A2 | `jalan_daur.gd` | aspal seberang/dekat tertukar | `kolom_di(-0.5)`, `kolom_di(0.5)` (10 gagal) |
| A3 | `jalan_daur.gd` | trotoar seberang/dekat tertukar | `kolom_di(-1.5)`, `kolom_di(1.5)` (11 gagal) |
| A4 | `jalan_daur.gd` | `rumput_luar` `>=` jadi `>` | `rumput_luar(3.0)`, `rumput_luar(-3.0)` |
| A5 | `jalan_daur.gd` | `jenis_di` aspal `<` jadi `<=` | batas aspal-trotoar (x +-1,0) di `tes_input_murni` dan `tes_ubin` |
| A6 | `jalan_daur.gd` | `jenis_di` trotoar `<` jadi `<=` | batas trotoar-rumput (5 gagal) |
| A7 | `jalan_daur.gd` | baris atas `sel_tanah` dipangkas 40 px | `sel_tanah` literal 434/450/496/511, jendela pandang tertutup ubin (9 gagal) |
| A8 | `tanah_daur.gd` | aspal seberang memakai tekstur aspal dekat | tekstur kolom 480 dari 511 |
| A9 | `tanah_daur.gd` | kolom luar tanpa `rumput_1` (tepi kerb berulang) | tekstur kolom 173 dari 511, 7 tekstur (6 gagal) |
| A10 | `tanah_daur.gd` | ubin digeser 1 px | tanah menutup layar 60 detik ngebut (celah), posisi vs graybox (5 gagal) |
| A11 | `tanah_daur.gd` | tiap ubin digandakan (node naik) | jumlah sprite ubin 868 vs `sel_tanah` 434 (6 gagal) |
| A12 | `rute.tscn` | tekstur aspal dekat salah | scene rute: tekstur kolom 481 dari 511 (lolos dulu; tes diperkuat) |
| A13 | `rute.tscn` | tanpa `rumput_1` | scene rute: tekstur kolom 173 dari 511 (lolos dulu; tes diperkuat) |
| A14 | `config.gd` | `JALAN_TROTOAR_UBIN` 1,0 jadi 1,5 | 35 gagal (gerak, lateral, kolom) |
| A15 | `config.gd` | `JALAN_RUMPUT_TEPI_UBIN` 1,0 jadi 2,0 | `rumput_luar(3.0)` dan konstanta (11 gagal) |
| A16 | `rute.tscn` | merujuk `tile_graybox` lagi | rute.tscn tidak merujuk `tile_graybox_*` |
| A17 | `render.py` | aset tak dipasang ikut tersalin (`prop_tong_sampah_biru` ke props/) | uji pasang: daftar D-1 di props |
| A18 | `ubin_perumahan.py` | ubin tak dirujuk ikut disalin (`aspal_1`) | uji pasang: daftar D-1 dan JSON ubin byte-identik |
| A19 | `vfx_debu_roda.png.import` | `compress/mode=0` jadi 2 | uji pasang: impor Lossless |
| A20 | `tile_perumahan_rumput_1.png.import` | mipmap true | uji pasang: tanpa mipmap |
| A21 | `ubin_perumahan.py` | polisi tidur lama diekspor lagi | uji gelombang 1: tidak lagi menghasilkan polisi tidur |
| A22 | `properti.py` | kilau kuning dominan, krem hanya tengah | kilau: krem >= 60% dan kuning 1..5 (9 gagal) |
| A23 | `properti.py` | tong biru jadi hijau | tong: warna dasar hijau |
| A24 | `properti.py` | tong logam berdasar #969AA0 | tong: warna dasar bukan RADAR_BUKAN, jarak token 0 |
| A25 | `properti.py` | tong biru berwarna OK #56C46E | warna di luar palet induk, dasar hijau, dekat token |
| A26 | `tile_perumahan.json` | memuat ubin yang tidak dipasang | uji pasang: JSON byte-identik dan `tiles` |
| A27 | `lembar_vfx_x5.png` | satu piksel mock docs diubah | uji gelombang 1: mock docs beda dengan render |
| A28 | `tests/data/ubin_potongan_8_maju.png` | satu piksel referensi diubah | `tes_ubin`: susunan = referensi; Python: referensi = susunan assets |
| A29 | `prop_koran_putar.png` | satu piksel PNG terpasang diubah | uji pasang: piksel-identik dengan keluaran skrip |
Catatan: mutan awal A7 (`* 2 + 0` pada jangkauan) setara secara perilaku (hanya batas loop; cakupan ubin sama) dan diganti A7 di atas. Mutan bagian B (koran, bayangan, terlipat, VFX, bintang, koin, kilau game) menyusul di iterasi 1 bagian B.
