# Loop Log — 20261021-fase5b-tembok-dekor
Scope: Run 5B, Fase 5, tembok sisi dekat, dekor di data segmen (tong sampah, pohon, lampu jalan), ubin masuk garasi/simbol sepeda/rumput bervariasi, hanya tampilan dan data dekor  ·  Branch: feat/fase5b-tembok-dekor  ·  Mulai: 2026-10-21  ·  Godot: 4.7.2.stable.official.ed1daf0bf

## Status: IN_PROGRESS   (iterasi saat ini: 1/2, Dev bagian A dan B1 selesai; B2 dan C belum; satu temuan BLOCKED: AC-8 zona sasaran dekat)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|
| B1-F1 | 1 | Tinggi | AC-8, tembok sisi dekat vs zona sasaran dekat | **BLOCKED.** Badan sprite kotak surat sasaran dekat 0% tertimpa tembok/tiang (semua varian, jenis atap, posisi), tetapi ZONA di tanah tertimpa: kotak surat polos/bata/besi 1,7%, pot 13,1%; teras polos/bata 89,5%, besi 82,3%, pot 97,5% (diukur `UkurTembok`, piksel opak, urutan gambar dihitung; tanpa urutan gambar sama). Sebab: tembok di lateral 3,125 lebih dekat ke kamera dari zona teras dekat (lateral 2,5 sampai 3,0) dan setinggi 14 unit (tiang 17), jadi sinar kamera ke teras dan sebagian kotak surat melewati tembok. Keputusan pemilik: `RUTE_TEMBOK_X_UBIN` dan mundur 1,25 TIDAK digeser. Rute perumahan nyata tidak punya pelanggan dekat, jadi tidak ada dampak di game sekarang; berdampak bila rute dengan pelanggan dekat dibuat. Tangkapan: `shots/iter1/*_dekat_tembok_sasaran_bidik.png` (zona kuning di tanah tidak terlihat di balik tembok, kotak surat sendiri terlihat). Orchestrator/pemilik memutuskan (mis. tembok lebih rendah/bolong di teras, teras dekat digeser, atau terima). | BLOCKED | - | `tes_tembok.gd` `_test_sasaran_tidak_tertutup`: badan = 0 dijaga nol; zona dikunci pada nilai terukur berlabel BLOCKED (berubah jika geometri/aset berubah) |
| B1-F2 | 1 | Sedang | D-2: tapak logika rumah dekat tidak ikut mundur | Rumah dekat digambar 1,25 ubin lebih jauh tetapi `PenutupPemain.tapak_rumah` tetap di lateral 3,0 (keputusan D-2). Akibat terlihat: pemain di trotoar dekat (lateral 1,75) membuat sprite rumah dekat jadi alfa 0,45 padahal rumah yang digambar tidak menimpa pemain (tangkapan `shots/iter1/*_dekat_tembok_trotoar_dekat.png`: rumah transparan terlepas dari pemain, menimpa HUD bawah). Spike 3C mencatat "Tidak pernah" untuk pendekatan tembok karena spike ikut menggeser kotak penutup; D-2 melarang menggeser tapak, jadi perilaku ini nyata. Bukan BLOCKED (sesuai SPEC), tetapi perlu keputusan: tetap, atau kotak penutup digambar ikut mundur (mengubah `PenutupPemain.tapak_rumah`, dilarang AC-6). | OPEN (keputusan orchestrator) | - | - |

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

## Iterasi 1, bagian B1 (Dev): tembok sisi dekat (AC-4 sampai AC-8, AC-18 bagian tembok, AC-19, AC-20, sebagian AC-22 dan AC-23)

Commit (branch `feat/fase5b-tembok-dekor`, belum push): `9e2c664` feat (modul, scene, tes), probe + tangkapan iterasi 1, dan `test:` penghitung pemuatan PNG tembok (mutan B1-20 hidup lalu diperkuat). Satu proses Godot dalam satu waktu; ada proses `godot --headless --script res://tests/run_tests.gd` lama (hidup sekitar 7,7 jam, bukan milik sesi ini, tergantung dari sesi sebelumnya) yang TIDAK saya matikan; tidak mengganggu hasil.

**Yang dikerjakan**
- `scripts/config.gd` (satu baris, literal, komentar satuan): `RUTE_TEMBOK_X_UBIN` 3,125, `RUTE_RUMAH_DEKAT_MUNDUR_UBIN` 1,25, `RUTE_TEMBOK_MODUL_UBIN` 1,0, `RUTE_TEMBOK_VARIAN` (polos, bata, besi, pot), `SPRITE_TEMBOK` [46, 46, 1, 41, 25] (sama dengan lima JSON + PNG, dites), `SPRITE_TEMBOK_GESER_PX` [-32, 16] (dites = `Iso`), konstanta FNV-1a (`HASH_FNV1A_AWAL/KALI/MASKER`). `RUTE_RUMAH_DEKAT_X_UBIN` dan `PenutupPemain.tapak_rumah` tidak disentuh (`git diff 41cc11b` kosong untuk ThrowSolver, SkorRute, ZonaSasaran, TenggatRute, BikeMotion, Tabrakan, RintanganRute, PenutupPemain, JalanDaur, MedanKoran).
- `scripts/systems/varian_tembok.gd` (`VarianTembok`: `fnv1a_32`, `indeks`, `pilih`; FNV-1a 32 bit atas byte UTF-8, tanpa `hash()` dan RNG) dan `scripts/systems/tembok_dekat.gd` (`TembokDekat`: `potongan(rumah)`, `titik_dunia`, `sel/pijak/jalur_png/semua_nama`). `SpriteRumah.pusat_gambar_dunia` (pusat tapak + mundur untuk sisi dekat; `pusat_tapak_dunia` tetap).
- `RumahDaurRute`: kolam sprite tembok (`_tembok`, `_tembok_bebas`), PNG dimuat sekali di `atur_rute`, tidak didaftarkan ke `PenerapPenutup`, sprite rumah dekat digeser; aksesor `jumlah_tembok`, `sprite_tembok`, `jumlah_node_tembok`, `jumlah_tekstur_tembok`, `jumlah_muat_tembok`.
- Tes: `tests/tes_tembok.gd` (+ `tests/ukur_tembok.gd` pengukur piksel AC-8, dipakai juga probe), terdaftar di `run_tests.gd`; `tes_rute_scene.gd` disesuaikan hanya untuk letak gambar rumah dekat (oracle literal 5,75 bukan 4,5) dan hitungan anak `Objek` (+ tembok); `tes_ubin.gd`: `house_tembok_` dikeluarkan dari `TERLARANG` (kini sah dirujuk; pemindai khusus di `tes_tembok.gd` hanya mengizinkan lima nama sprite, nama lain gagal; pemindai lain TIDAK dilonggarkan). `tes_koran_sprite.gd` tidak perlu diubah (pemindainya hanya `prop_|vfx_|mission_`).
- Probe: `tests/probe_sisi_dekat_jendela.gd` (skenario B1: `tembok_polos/bata/besi/pot`, `tembok_jalur_dekat`, `tembok_trotoar_dekat`, `tembok_sasaran_bidik/terbang/kena`, `kidal`), 4 ukuran, 40 tangkapan di `shots/iter1/`.

**Keputusan dan penyimpangan dari SPEC (dicatat, usulan)**
1. **Arah rantai tembok.** SPEC D-3/AC-4 menulis modul di m, m+1, m+2 dan tiang di m+3. Sprite modul digambar dari pijaknya ke arah MUNDUR (maju mengecil; "modul berikut digeser (-32, +16)" = maju turun) dan tiang awalnya ada di pijak, sehingga rantai tumbuh ke belakang dari modul pertama dan tiang penutup ada di ujung belakang. Implementasi: `maju_ubin` potongan = ujung belakang modul, modul di m, m+1, m+2 (sesuai SPEC), pijak di ujung depan (maju + 1), tiang di maju m (bukan m+3, yang meninggalkan celah 1 ubin dan tiang terlepas). Mutan B1-24 dan B1-26 membuktikan tes menolak tiang di m+3.
2. **Y-sort wajar, bukan "tembok di depan rumah".** Instruksi minta tembok di depan rumah dan di belakang sepeda. Dengan Y-sort posisi pijak (satu-satunya urutan yang dipakai rumah, kotak surat, sepeda), pijak tembok (lateral 3,125) selalu lebih kecil dari pijak rumah (pusat lateral 5,75), jadi rumah digambar SESUDAH tembok: atap rumah menimpa bagian depan rantai di tangkapan (fisik benar: rumah lebih dekat ke kamera; sama dengan spike 3C yang dipilih pemilik). Terhadap sepeda: tembok digambar sesudah sepeda tetapi tidak menimpanya, karena piksel tembok jatuh 22 sampai 36 px di bawah kaki sepeda (lateral <= 2,0); dilihat di tangkapan jalur/trotoar dekat. Tes mengunci: tembok anak langsung `Objek`, `z_index` 0, Y tembok < Y rumah, alfa 1,0.
3. **Teras dan zona kotak surat ikut diukur (AC-8)**, bukan hanya badan kotak surat; lihat B1-F1 BLOCKED.

**Penilaian dari tangkapan** (dilihat sendiri, 2340x1080 dan 1600x720)
- Tembok terbaca sebagai pagar/pembatas halaman krem rendah dengan tiang, bukan pita gelap; keempat varian dapat dibedakan (polos krem, bata merah, besi hitam bersekat, pot dengan semak); tiang ujung tidak berisik (satu tiang per ubin, ritmis). Rumah di belakang tembok tampil wajar, tanpa celah ke tanah. Bagian depan rantai tertimpa atap rumah (Y-sort), terbaca sebagai tembok di belakang rumah.
- Sasaran: kotak surat dekat terlihat penuh di depan/atas tembok, garis bidik, koran terbang, dan penanda CENTANG/+15 benar (lemparan dinilai KOTAK_SURAT); zona kuning di tanah tertutup tembok (B1-F1).
- Trotoar dekat: rumah dekat menjadi alfa 0,45 di tempat yang tidak menutupi pemain (B1-F2).

**Gerbang** (sesudah commit terakhir, satu proses Godot dalam satu waktu)
- `godot --headless --import`: 0 ERROR/WARNING.
- `run_tests.gd` + `cek_keluaran_tes.py`: **17524 lolos, 0 gagal, 0 peringatan** (baseline bagian A 17409; +115 pemeriksaan baru dari `tes_tembok.gd`). `godot --headless --path . --quit-after 2`: tanpa ERROR/WARNING.
- Semua `tools/tests_cek/uji_*.py` lolos (gelombang1 352, kucing 12, lampu_pohon 183, pasang_5b 355, pasang_gelombang1 373, bangun_frames 51, pemeriksa 16 kasus, sintesis kondisi 55, lempar 111, misi 47, rute 90, sepeda 32).
- Probe jendela baru di 2340x1080, 1920x1080, 2400x1080, 1600x720: masing-masing "probe selesai, 0 keadaan tidak sesuai", tanpa ERROR/WARNING.
- sha256 `~/Library/Application Support/Godot/app_userdata/Kring Kring!/save.json` sesudah semua tes, probe, dan mutan: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e` (sama dengan sebelum).
- AC-6: `git diff 41cc11b` kosong untuk ThrowSolver, SkorRute, ZonaSasaran, TenggatRute, BikeMotion, Tabrakan, RintanganRute, PenutupPemain, JalanDaur, MedanKoran; 1000 lemparan berseed (checksum dihitung di 41cc11b sebelum kode berubah: 1000 / 11137 zona / 339 tertutup / 992255826) identik, dan identik dengan penilaian ulang dari `ZonaSasaran`.

**Mutan B1** (satu perubahan, `run_tests.gd` penuh, `git checkout`; `git status` bersih sesudahnya; "gagal" = jumlah GAGAL/SCRIPT ERROR)

| ID | File | Perubahan | Gagal | Tes pertama yang gagal |
|---|---|---|---|---|
| B1-1 | tembok_dekat.gd | jumlah modul 3 jadi 2 | 11 | tiga modul dan satu tiang |
| B1-2 | tembok_dekat.gd | geser antar modul 0,5 (literal) | 5 | pemindai angka literal di luar config |
| B1-3 | tembok_dekat.gd | tiang ujung hilang | 13 | tiga modul dan satu tiang |
| B1-4 | tembok_dekat.gd | varian per modul bukan per rumah | 3 | satu varian untuk ketiga modul |
| B1-5 | varian_tembok.gd | `hash()` dipakai | 5 | indeks varian = oracle |
| B1-6 | varian_tembok.gd | hash mod 3 | 10 | pemindai literal, oracle |
| B1-7 | varian_tembok.gd | hash mod 5 | banyak (indeks di luar rentang) | pemindai literal, SCRIPT ERROR |
| B1-8 | varian_tembok.gd | FNV-1 (kali lalu xor) bukan FNV-1a | 7 | hash = oracle Python |
| B1-9 | config.gd | `RUTE_TEMBOK_X_UBIN` 3,25 | 6 | letak modul/lateral 3,125 |
| B1-10 | config.gd | mundur -1,25 (terbalik) | 7 | posisi rumah dekat |
| B1-11 | config.gd | mundur 1,0 | 7 | posisi rumah dekat |
| B1-12 | rumah_daur_rute.gd | tembok didaftarkan ke penerap penutup | 4 | penerap terdaftar = rumah + rintangan |
| B1-13 | penutup_pemain.gd | tapak rumah dekat ikut mundur | 17 | tes rintangan/geometri tapak |
| B1-14 | sprite_rumah.gd | rumah seberang ikut digeser | 6 | posisi rumah seberang |
| B1-15 | tembok_dekat.gd | tembok juga untuk rumah seberang | 9 | rumah seberang tidak bertembok |
| B1-16 | rumah_daur_rute.gd | `_lepas_tembok` tidak melepas (node bocor di luar jendela) | 6 | sprite tembok = 4 x rumah dekat di jendela |
| B1-17 | config.gd | pijak tembok y 25 jadi 26 | 9 | Config = JSON = literal |
| B1-18 | rumah_daur_rute.gd | `z_index = 1` (tembok di depan rumah) | 1 | Y-sort/z_index tembok |
| B1-19 | tembok_dekat.gd | pijak modul di ujung belakang | 4 | titik pijak dunia |
| B1-20 | rumah_daur_rute.gd | tekstur tembok dimuat ulang tiap dipakai | **HIDUP** pada percobaan pertama (`load` ber-cache, hitungan kamus tidak berubah); tes diperkuat dengan `jumlah_muat_tembok()` = 5, ulang: **1** | PNG tembok dimuat tepat lima kali (240 tanpa guard) |
| B1-21 | rumah_daur_rute.gd | tekstur tidak dimuat di atur_rute | 1 | tekstur dimuat di atur_rute |
| B1-22 | rumah_daur_rute.gd | offset sprite tembok nol (titik pijak salah) | 1 | letak piksel tembok |
| B1-23 | tembok_dekat.gd | tiang memakai gambar modul | 6 | nama tiang |
| B1-24 | tembok_dekat.gd | tiang di m+3 (literal) | 4 | pemindai literal |
| B1-25 | config.gd | `RUTE_TEMBOK_MODUL_UBIN` 0,5 | 13 | tiga modul dan satu tiang |
| B1-26 | tembok_dekat.gd | tiang di m + `RUTE_RUMAH_PANJANG_UBIN` (arah SPEC) | 3 | titik pijak tembok/tiang |

26 mutan, 25 terdeteksi pada percobaan pertama atau sesudah penguatan (B1-20), 0 hidup sekarang. Catatan: B1-2/6/7/24 pertama kali tertangkap pemindai angka literal; B1-25 dan B1-26 (lewat Config) membuktikan tes geometri juga menangkapnya. AC-23 meminta mutan dekor/ubin/aset di bagian B2 dan C.

## NEEDS-MANUAL (uji di HP)
Lihat SPEC bagian NEEDS-MANUAL dan `docs/SETUP_ANDROID.md` 8.13 (ditulis Dev).

## Keputusan & catatan
- Persiapan orchestrator (2026-10-21): `main` = `origin/main` = `6edf5ba` (memuat PR #45 run 5A, #46 CI APK, #47 rilis 0.2.0). Branch kerja `feat/fase5b-tembok-dekor` dari situ. PR #48 (docs perintah 5B, Bagian 6h) masih terbuka dan belum di-merge; run ini TIDAK menyentuh Bagian 6h supaya tidak bentrok. Godot 4.7.2 (`/opt/homebrew/bin/godot`), `adb devices` kosong (tidak ada HP tersambung saat persiapan).
- Hasil uji HP 4A, 4B, 6A1, 5A: kosong (baris `ISI: ...` pada perintah tidak diisi pemilik, diperlakukan kosong).
- Keputusan pemilik: K-1 sampai K-5 di SPEC. Keputusan desain orchestrator D-1 sampai D-8 di SPEC (usulan, bisa ditolak di review PR). Dua penyesuaian atas perintah yang dilaporkan ke pemilik: (1) `aspal_N` polos TIDAK dipasang (D-4: tanpa garis tepi, memutus garis kerb; butuh varian kolom dari renderer); (2) tapak logika rumah dekat tidak digeser, hanya gambar (D-2: `RUTE_RUMAH_DEKAT_X_UBIN` 3,0 tetap; tembok pusat 3,125 = sisi jalan di 3,0 + setengah tebal 0,125; mundur gambar 1,25 sebagai konstanta baru).
- Baseline tes sebelum run (main 6edf5ba, Godot 4.7.2): **17324 lolos, 0 gagal**, pemeriksa keluaran lolos (catatan: log run 5A mencatat 17325 pada akhir iterasi 2; selisih 1 `check` belum dijelaskan, bukan kegagalan).
- sha256 `user://save.json` asli (`~/Library/Application Support/Godot/app_userdata/Kring Kring!/save.json`, mtime 17 Okt) sebelum run: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e`; sama sesudah baseline.
- Pelajaran dari 5A yang berlaku: jangan menjalankan dua proses Godot tes bersamaan (tes simpan `user://` bentrok); galat parse di berkas tes membuat `run_tests.gd` menggantung (beri batas waktu); tekstur dimuat di `_init`/`_ready`, bukan di `_draw`.
