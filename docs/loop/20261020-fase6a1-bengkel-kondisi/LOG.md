# Loop Log — 20261020-fase6a1-bengkel-kondisi
Scope: Run 6A1 — save v3 (koin = saldo, `koin_total`, `sepeda`), `BikeCondition`, kotak kondisi di HUD rute, layar bengkel (servis + upgrade dari `upgrades.json`), `Economy`, alur Hasil → Bengkel → Hari berikutnya  ·  Branch: feat/bengkel-kondisi-6a1  ·  Mulai: 2026-10-20  ·  Godot: 4.7.2.stable

## Status: IN_PROGRESS   (iterasi saat ini: 1/2)

Baseline (main 337fae3, sebelum perubahan; dijalankan orchestrator 2026-10-20): `godot --headless --import` bersih; `run_tests.gd` **15133 lolos, 0 gagal**; `tools/cek_keluaran_tes.py` lolos (0 peringatan). HP: `adb devices` kosong saat run dimulai (vivo V2108 tidak tersambung); HP belum disentuh.

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 1 | Bagian A (kondisi, efek, save v3, ekonomi, toko, MesinHari, tes, mutan); bagian B belum (lihat Catatan Dev iterasi 1) | import bersih; `run_tests.gd` 15783 lolos, 0 gagal; pemeriksa keluaran lolos (0 peringatan); `--quit-after 2` bersih; semua `uji_*.py` lolos | | | |

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## Mutan (AC-31, diisi Dev; QA mengulang sedikitnya 10 yang berbeda)
Bagian A: 83 mutan, semuanya digagalkan sedikitnya satu tes. Cara: satu perubahan pada kode asli di salinan sekali pakai repo (lima salinan paralel dengan folder `user://` sendiri, supaya tes yang menulis `user://tes_*` tidak saling mengganggu), `run_tests.gd` penuh, berkas dikembalikan; **repo kerja tidak pernah diubah** (`git status` bersih sebelum dan sesudah). QA mengulang dengan `git checkout -- <file>`. Mutan UI dari daftar AC-31 (tombol nonaktif tetap bisa membeli, tata letak HUD bertumpuk) belum berlaku sampai bagian B.

| # | File | Perubahan | Tes yang gagal (pertama) |
|---|---|---|---|
| 1 | `scripts/config.gd` | ambang AUS 0,7 -> 0,3 (di bawah ambang efek) | ambang AUS 0,70 dan PERLU_BENGKEL 0,35 (BALANCING 8) (+26 tes lain) |
| 2 | `scripts/config.gd` | ambang PERLU_BENGKEL 0,35 -> 0,75 (di atas ambang AUS) | ambang AUS 0,70 dan PERLU_BENGKEL 0,35 (BALANCING 8) (+34 tes lain) |
| 3 | `scripts/systems/bike_condition.gd` | tingkat BAIK: >= menjadi > (batas inklusif) | tingkat tiap kondisi 0,00..1,00 sama dengan oracle (BAIK >= 0,70; AUS >= 0,35; selebihnya PERLU_BENGKEL) (+3 tes lain) |
| 4 | `scripts/systems/bike_condition.gd` | pecahan efek tidak dibagi ambang (lompatan efek di ambang) | kondisi 0,175: kecepatan x0,96, lateral x0,80, rem x0,70, akselerasi x0,675, puncak 4,8 u/d (setengah jalan, linear) (+1 tes lain) |
| 5 | `scripts/systems/bike_condition.gd` | pengali efek bisa > 1,0 (lerp ke 1,2, batas 1,5) | res://scripts/systems/bike_condition.gd: tanpa angka literal di luar config.gd (hanya 0, 1, 2, -1, -2 boleh): baris 257: (+21 tes lain) |
| 6 | `scripts/config.gd` | pengali rem terburuk 0,4 -> 0,1 (di bawah lantai) | pengali terburuk 0.1 di antara lantai dan 1,0 (hanya menghambat) (+9 tes lain) |
| 7 | `scripts/systems/bike_motion.gd` | literal 0,9 menggantikan pengali lateral di bike_motion.gd | res://scripts/systems/bike_motion.gd: tanpa angka literal di luar config.gd (hanya 0, 1, 2, -1, -2 boleh): baris 215: 0. (+29 tes lain) |
| 8 | `scripts/systems/bike_motion.gd` | batas puncak memakai maxf (puncak tidak membatasi) | 10a: stick netral -> 3,0 u/d dan santai_normal, dapat 5.99999999999999 santai_normal (+155 tes lain) |
| 9 | `scripts/systems/bike_motion.gd` | akselerasi mengabaikan efek rantai | bike_motion.gd memakai keenam bidang EfekKondisi (+1 tes lain) |
| 10 | `scripts/systems/bike_motion.gd` | rem mengabaikan efek rem blong | bike_motion.gd memakai keenam bidang EfekKondisi (+2 tes lain) |
| 11 | `scripts/systems/bike_motion.gd` | lateral mengabaikan efek ban | bike_motion.gd memakai keenam bidang EfekKondisi (+2 tes lain) |
| 12 | `scripts/systems/bike_motion.gd` | pengali kuras stamina mengenai laju pulih, bukan laju kuras | pengali_kuras_stamina = 0.5 mengubah hasil gerak ke arah yang dijanjikan: 40.0 vs 40.0 |
| 13 | `scripts/config.gd` | aus ban ngebut 0,0006 -> 0,0002 (rasio < 2, di bawah cepat) | aus per ubin: 0 < santai < cepat < ngebut dan ngebut >= 2x santai: [0.00015, 0.0003, 0.0002] (+5 tes lain) |
| 14 | `scripts/config.gd` | aus ban santai nol (servis abadi) | aus per ubin: 0 < santai < cepat < ngebut dan ngebut >= 2x santai: [0.0, 0.0003, 0.0006] (+9 tes lain) |
| 15 | `scripts/systems/bike_condition.gd` | aus di bawah santai tidak sebanding kecepatan | ban 1.5 u/d: 0.000075 per ubin, dapat 0.00015 (+1 tes lain) |
| 16 | `scripts/systems/bike_condition.gd` | rem aus tiap bergerak walau tanpa mengerem | tiga ubin pada santai: ban 1 - 3 x 0,00015, rantai 1 - 3 x 0,00011, rem utuh; dapat { "ban": 0.99955, "rem": 0.99, "rant (+11 tes lain) |
| 17 | `scripts/systems/bike_condition.gd` | aus per pengereman dihitung tiap langkah rem aktif, bukan tepi naik | rem aktif saat sepeda sudah diam (kecepatan awal 0) tidak aus (+1 tes lain) |
| 18 | `scripts/systems/bike_condition.gd` | kerusakan tabrakan tanpa memeriksa tepi naik (tiap langkah) | dua tabrakan mengurangi tepat 2 x 0,30 kondisi seluruhnya, dapat 2.0 dari { "ban": 0.0, "rem": 1.0, "rantai": 0.0 } (+1 tes lain) |
| 19 | `scripts/systems/tabrakan.gd` | Tabrakan: rintangan baru saat kebal tidak menempel (tabrakan ganda) | rintangan yang menyentuh sejak masa jatuh menempel: tidak menabrak selama jatuh, kebal, maupun sesudahnya (3,0 detik) (+3 tes lain) |
| 20 | `scripts/config.gd` | kerusakan tabrakan 0,3 -> 0,4 (melompati AUS) | kerusakan satu tabrakan 0,30 (+5 tes lain) |
| 21 | `scripts/systems/bike_condition.gd` | jepit tidak menjepit | rapikan: dijepit 0..1, bukan angka = 1,0, id asing dibuang; dapat { "ban": -3.0, "rem": 7.0, "rantai": 1.0 } (+7 tes lain) |
| 22 | `scripts/systems/bike_condition.gd` | aus ban dan rantai tanpa jepit (bisa di bawah 0) | kondisi tidak pernah di bawah 0 |
| 23 | `scripts/config.gd` | ban bocor terlalu lambat 0,92 -> 0,85 (melewati tenggat) | kondisi 0: kecepatan x0,92, lateral x0,60, rem x0,40, akselerasi x0,35, puncak 3,6 u/d (+17 tes lain) |
| 24 | `scripts/config.gd` | cadangan tenggat 2,0 -> 8,0 detik | cadangan tenggat 2,0 detik dan jarak berhenti rem blong paling jauh 9,0 ubin (2,5 kali 3,6) (+2 tes lain) |
| 25 | `scripts/config.gd` | batas puncak rantai putus di bawah santai | batas puncak rantai putus tidak di bawah santai dan di bawah ngebut (M-6) (+3 tes lain) |
| 26 | `scripts/config.gd` | akselerasi rantai putus 0,35 -> 0,30 (nilai berubah) | kondisi 0: kecepatan x0,92, lateral x0,60, rem x0,40, akselerasi x0,35, puncak 3,6 u/d (+14 tes lain) |
| 27 | `scripts/systems/data_save.gd` | migrasi: koin_total awal salah (koin v2 + 1) | hasil migrasi 4B = oracle tangan: semua field v2 sama, koin_total = 195, sepeda baru (+8 tes lain) |
| 28 | `scripts/systems/data_save.gd` | migrasi: sepeda tidak diisi (field hilang) | v2 dengan sepeda liar: sepeda baru (tanpa upgrade atau kerusakan gratis), koin_total = koin |
| 29 | `scripts/systems/data_save.gd` | sepeda baru berkondisi 0,9 (kerusakan gratis) | res://scripts/systems/data_save.gd: tanpa angka literal di luar config.gd (hanya 0, 1, 2, -1, -2 boleh): baris 116: 0.9 (+12 tes lain) |
| 30 | `scripts/systems/data_save.gd` | migrasi: versi tidak dinaikkan ke 3 | versi menjadi 3 (SAVE_VERSI) (+9 tes lain) |
| 31 | `scripts/systems/data_save.gd` | save versi 4 dianggap sah (ditimpa) | versi 4 (lebih baru dari 3): TERLALU_BARU, perlu disalin, state bawaan (+5 tes lain) |
| 32 | `scripts/systems/data_save.gd` | koin_total turun karena belanja | koin_total = 195 + 330 (belanja tidak mengurangi) (+3 tes lain) |
| 33 | `scripts/systems/data_save.gd` | koin hari dihitung dua kali | koin = 1000 + angka.koin (koin sudah termasuk tip) (+27 tes lain) |
| 34 | `scripts/systems/data_save.gd` | level upgrade bisa turun di catat_hari | level dan servis_total tidak turun; kondisi boleh turun (aus); komponen yang tidak disebut tetap |
| 35 | `scripts/systems/data_save.gd` | normalisasi sepeda tidak menjepit kondisi | ban 7 -> 1,0 level -3 -> 0; rem 'abc' -> 1,0 level 2; rantai -0,4 -> 0,0; dapat { "ban": { "kondisi": 7.0, "level": 0 }, (+2 tes lain) |
| 36 | `scripts/systems/data_save.gd` | servis_total bukan angka tidak dianggap rusak | {"versi": 3, "sepeda": {"servis_total": "banyak"}}: RUSAK, disalin, state bawaan |
| 37 | `scripts/systems/economy.gd` | servis: saldo tepat sama dengan harga ditolak (< -> <=) | saldo tepat sama dengan harga (96): diterima, saldo 0 |
| 38 | `scripts/systems/economy.gd` | upgrade: saldo kurang 1 koin diterima | saldo 599: ditolak KOIN_KURANG, state identik (+12 tes lain) |
| 39 | `scripts/systems/economy.gd` | servis diterima tanpa mengurangi saldo (transaksi parsial) | saldo 500 -> 380; koin_total dan tip_total tetap (+5 tes lain) |
| 40 | `scripts/systems/economy.gd` | upgrade membayar tetapi level tidak naik | saldo tepat 600: ban_anti_selip diterima, saldo 0, level ban 1 (+7 tes lain) |
| 41 | `scripts/systems/economy.gd` | upgrade level lompat diterima | level 2 tanpa level 1: ditolak LEVEL_TIDAK_BERURUTAN, state identik (+13 tes lain) |
| 42 | `scripts/systems/economy.gd` | upgrade sudah dimiliki bisa dibeli lagi | sudah dimiliki: tidak bisa dibeli dua kali walau saldo cukup |
| 43 | `scripts/systems/economy.gd` | ongkos naik dihapus (banyak rusak tanpa kenaikan) | pengali ongkos 1,0 / 1,0 / 1,25 / 1,5 untuk 0-3 komponen rusak (+7 tes lain) |
| 44 | `scripts/systems/economy.gd` | harga servis minimum 1 koin dihapus | rantai kondisi 0.999, satu rusak: 1 koin (dapat 0) (+3 tes lain) |
| 45 | `scripts/systems/data_toko.gd` | validasi: field asing tidak ditolak | field asing di upgrade: ditolak dan galat menyebut 'tidak dikenal'; dapat [] |
| 46 | `scripts/systems/pemuat_toko.gd` | validasi: id ganda lolos | id ganda: ditolak dan galat menyebut 'ganda'; dapat ["upgrade wajib \'ban_anti_selip\' harus level 1 untuk komponen \'ba |
| 47 | `scripts/systems/data_toko.gd` | validasi: komponen asing lolos | komponen asing (setang dicadangkan, belum dibuat): ditolak dan galat menyebut 'komponen 'setang' tidak dikenal'; dapat [ (+13 tes lain) |
| 48 | `scripts/systems/data_toko.gd` | validasi: level 0 lolos | level 0: ditolak dan galat menyebut 'level harus bilangan bulat >= 1'; dapat ["level upgrade komponen \'ban\' harus beru |
| 49 | `scripts/systems/data_toko.gd` | validasi: harga 0 lolos | harga 0: ditolak dan galat menyebut 'harga'; dapat [] (+1 tes lain) |
| 50 | `scripts/systems/data_toko.gd` | validasi: jenis efek asing lolos | jenis efek asing: pengali_kecepatan (menaikkan kecepatan puncak, power creep): ditolak dan galat menyebut 'tidak dikenal (+1 tes lain) |
| 51 | `scripts/systems/data_toko.gd` | validasi: nilai efek di atas rentang lolos | nilai di atas rentang aman (lateral 1,3 > 1,25): ditolak dan galat menyebut 'di luar rentang'; dapat [] (+2 tes lain) |
| 52 | `scripts/systems/data_toko.gd` | validasi: efek untuk komponen salah lolos | jenis efek rem pada komponen ban: ditolak dan galat menyebut 'hanya untuk komponen'; dapat [] |
| 53 | `scripts/systems/pemuat_toko.gd` | validasi: level komponen melompat lolos | level 2 tanpa level 1 untuk ban: ditolak dan galat menyebut 'berurutan'; dapat ["upgrade wajib \'ban_anti_selip\' harus  (+13 tes lain) |
| 54 | `scripts/systems/pemuat_toko.gd` | validasi: id wajib di komponen salah lolos | id wajib pada komponen yang salah: ditolak dan galat menyebut 'rem_pakem'; dapat ["level upgrade komponen \'ban\' harus  |
| 55 | `scripts/systems/data_toko.gd` | validasi: efek kosong lolos | efek kosong: ditolak dan galat menyebut 'efek'; dapat [] |
| 56 | `scripts/systems/data_toko.gd` | validasi: kunci nama hilang/terlalu panjang lolos | kunci nama tidak ada: ditolak dan galat menyebut 'kunci terjemahan'; dapat [] (+2 tes lain) |
| 57 | `scripts/systems/pemuat_toko.gd` | validasi: JSON rusak tidak dilaporkan sebagai JSON rusak | tiga upgrade nyata dimuat (+60 tes lain) |
| 58 | `scripts/systems/pemuat_toko.gd` | berkas tidak ada tidak dilaporkan | berkas tidak ada: galat jujur, daftar kosong: ["res://assets/data/shop/tidak_ada.json: berkas kosong atau tidak terbaca" |
| 59 | `scripts/systems/mesin_hari.gd` | MesinHari: HARI_BERIKUTNYA dari HASIL diterima | hasil/berikut ditolak tanpa efek (keadaan dan hari sama) (+13 tes lain) |
| 60 | `scripts/systems/mesin_hari.gd` | MesinHari: back di bengkel diabaikan | back di bengkel = lewati bengkel (sama dengan Hari berikutnya, M-8) |
| 61 | `scripts/systems/mesin_hari.gd` | MesinHari: BUKA_BENGKEL ikut menaikkan hari | satu hari utuh berakhir di KORAN hari 4 (hari naik sekali walau 'Hari berikutnya' diketuk tiga kali) (+15 tes lain) |
| 62 | `scripts/systems/mesin_hari.gd` | MesinHari: BUKA_BENGKEL ganda diterima | bengkel/bengkel ditolak tanpa efek (keadaan dan hari sama) (+2 tes lain) |
| 63 | `scripts/entities/hari_main.gd` | simpan saat layar hasil terbuka (sebelum waktunya) | sampai layar hasil terbuka belum ada simpan sama sekali (+13 tes lain) |
| 64 | `scripts/entities/hari_main.gd` | simpan dua kali di akhir hari | 'Hari berikutnya': tepat satu simpan, sinyal hari_selesai(1) (+9 tes lain) |
| 65 | `scripts/systems/bike_condition.gd` | kode kondisi menyebut mode bantu | bike_condition.gd: kode tidak menyebut mode bantu (satu ekonomi untuk semua pemain) |
| 66 | `scripts/systems/bike_condition.gd` | peringatan juga di tingkat BAIK | kondisi 1.0 (BAIK) dipakai 10000 langkah: nol peringatan (+3 tes lain) |
| 67 | `scripts/systems/bike_condition.gd` | peringatan tanpa jeda minimum (spam) | kondisi 0.69 dipakai 10000 langkah (167 detik): tiap komponen memperingatkan di langkah pertama lalu tiap >= 6 detik (se (+4 tes lain) |
| 68 | `scripts/systems/bike_condition.gd` | peringatan palsu untuk komponen yang tidak dipakai | komponen aus yang tidak dipakai (diam, tanpa rem): nol peringatan palsu (+2 tes lain) |
| 69 | `scripts/systems/bike_condition.gd` | peringatan berbunyi saat dt 0 (jeda game) | dt 0.0: tidak ada peringatan dan waktu beku (+13 tes lain) |
| 70 | `scripts/config.gd` | ban/rantai hanya memperingatkan di atas 5,5 u/d (pemain santai tak diperingatkan sebelum efek) | jeda peringatan 6,0 detik; ban dan rantai memperingatkan mulai santai 3,0 u/d (+6 tes lain) |
| 71 | `scripts/systems/seed_hari.gd` | SeedHari.kondisi memakai seed rute | seed kondisi hari 1, 2, 60 = 28182821, 29182824, 87182998 (27182818 + hari x 1000003) (+1 tes lain) |
| 72 | `scripts/systems/bike_condition.gd` | komponen tabrakan tidak bergantung nomor tabrakan | nomor tabrakan berbeda dan hari berbeda memberi pilihan berbeda (bukan satu nilai tetap) |
| 73 | `scripts/config.gd` | bobot tabrakan ban/rem tertukar | bobot tabrakan sejajar komponen: ban 50, rem 20, rantai 30 (M-4) (+13 tes lain) |
| 74 | `scripts/systems/bike_condition.gd` | efek lateral membaca kondisi rem, bukan ban | hanya ban rusak: kecepatan tujuan dan lateral turun, rem dan rantai utuh (+1 tes lain) |
| 75 | `scripts/systems/data_toko.gd` | validasi: nilai efek di bawah rentang lolos | nilai di bawah rentang aman (lateral 0,9 < 1,0): ditolak dan galat menyebut 'di luar rentang'; dapat [] (+3 tes lain) |
| 76 | `scripts/systems/economy.gd` | servis komponen 1,0 tetap dibayar | ban 1,0 ditolak KOMPONEN_PENUH, state identik (+3 tes lain) |
| 77 | `scripts/systems/bike_condition.gd` | batas puncak rantai membaca kondisi ban | hanya ban rusak: kecepatan tujuan dan lateral turun, rem dan rantai utuh (+2 tes lain) |
| 78 | `scripts/systems/economy.gd` | harga servis naik bila kondisi membaik | ban kondisi 0.0, satu rusak: 120 koin (dapat 1) (+22 tes lain) |
| 79 | `scripts/systems/bike_motion.gd` | rem_mulai bukan tepi naik (tiap langkah rem aktif) | tarik ke bawah 0.3 detik: tepi naik rem tepat 1 kali, dapat 4 (+4 tes lain) |
| 80 | `scripts/systems/data_save.gd` | catat_hari tidak menuliskan sepeda akhir | sepeda akhir ditulis (kondisi dibulatkan 4 desimal); dapat { "ban": { "kondisi": 1.0, "level": 0 }, "rem": { "kondisi":  (+3 tes lain) |
| 81 | `scripts/systems/data_save.gd` | catat_hari tidak menuliskan kondisi akhir | sepeda akhir ditulis (kondisi dibulatkan 4 desimal); dapat { "ban": { "kondisi": 1.0, "level": 0 }, "rem": { "kondisi":  (+3 tes lain) |
| 82 | `scripts/entities/hari_main.gd` | HariMain melewati BUKA_BENGKEL (peristiwa salah) | 'Hari berikutnya': tepat satu simpan, sinyal hari_selesai(1) (+60 tes lain) |
| 83 | `scripts/systems/bike_condition.gd` | pengali aus upgrade diabaikan | pengali aus ban 0,5 menghemat separuh aus ban saja (+2 tes lain) |

Catatan mutan: (1) mutan "koin_total awal nol" pada langkah migrasi `versi < 3` **selamat** karena setara: `_normalisasi` menaikkan `koin_total` ke `koin` (invarian `koin_total >= koin`), jadi diganti mutan "koin v2 + 1" yang digagalkan. (2) Mutan "komponen asing lolos" dan "level 0 lolos" di `DataToko` **awalnya selamat** karena kata cari tes (`komponen`, `level`) juga ada di galat pemeriksaan antar upgrade; tes `tes_toko.gd` diperketat (tiap kasus mencari kalimat galatnya sendiri) dan kedua mutan kini gagal. (3) Dua mutan setara (pengali efek tanpa lantai; batas puncak rantai tanpa jepit ke santai) dibuang dari tabel: selama Config sah mereka tidak mengubah keluaran. (4) Tidak terdeteksi: pergeseran satu poin persen pada sebaran bobot tabrakan (toleransi sebaran 3 poin persen dari 10.000 sampel, simpangan baku ~0,5 poin).
## Catatan Dev iterasi 1 (bagian A)

**Commit (branch `feat/bengkel-kondisi-6a1`, tanpa push):** `d3b9ee9` kondisi sepeda + efek + Config + BALANCING 7 dan 8; `c85cd18` save v3 + migrasi + DATA_SCHEMA; `e4852ad` Economy + PemuatToko + `upgrades.json`; `4997447` MesinHari BENGKEL + HariMain sementara + daftar tes; `6b6071f` tes kontinuitas efek; `2c810aa` perketat tes_toko + paket wajib; `13910d9` docs rule dan AGENTS; ditambah commit LOG ini.

**Gerbang (dijalankan Dev, 2026-10-20):** `godot --headless --import` bersih; `run_tests.gd` **15783 lolos, 0 gagal** (baseline 15133, +650) dan `tools/cek_keluaran_tes.py` lolos (0 peringatan); `godot --headless --path . --quit-after 2` tanpa ERROR/WARNING; `tools/tests_cek/uji_*.py` (aset_kucing 12, bangun_frames 51, pemeriksa 16 kasus, sintesis_lempar 111, sintesis_misi 47, sintesis_rute 90, sintesis_sepeda 32) semuanya lolos. `--export-pack "Android"` menghasilkan `build/kring-uji.pck` (1,4 MB) yang memuat `assets/data/shop/upgrades.json`, `bike_condition.gd`, `economy.gd`, `pemuat_toko.gd`, `efek_kondisi.gd`, `data_toko.gd` dan tanpa `tests/`, `docs/`, `tools/`; `PemuatToko.muat()` dijalankan dari folder di luar repo dengan `--main-pack` memuat 3 upgrade, `sah()` true, tanpa galat.

**Save asli pemilik tidak tersentuh:** sha256 `~/Library/Application Support/Godot/app_userdata/Kring Kring!/save.json` sebelum pekerjaan `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e` (219 byte, 17 Okt), sesudah: lihat baris "sha256 sesudah" di bawah. Tes memakai jalur uji `user://tes_*` dan `run_tests.gd` membandingkan jejak `user://save.json` sebelum dan sesudah (lolos).

sha256 sesudah seluruh pekerjaan: 37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e (identik: save asli tidak berubah, 219 byte)

**Yang selesai (bagian A, M-13):** `Config` (SAVE_VERSI 3, `KONDISI_*`, `SERVIS_*`, `TOKO_*`, `SEED_KONDISI_*`, satu baris literal); save v3 + migrasi (`DataSave`, fixture nyata 4B/4A/v0); `BikeCondition` + `EfekKondisi` + parameter `efek` opsional di `BikeMotion.langkah` (+ `Hasil.kecepatan_awal_ud` dan `rem_mulai`) + `SeedHari.kondisi`; `Economy`; `DataToko`/`PemuatToko` + `upgrades.json` + kunci `TOKO_` di `konten.csv`; `MesinHari` BENGKEL/BUKA_BENGKEL/back; tes `tes_kondisi`, `tes_kondisi_gerak` (+ `sim_profil_kondisi`), `tes_economy`, `tes_toko`, `tes_save_v3`; 83 mutan; BALANCING 7 dan 8 (angka dipilih dari ukuran simulasi, usulan); DATA_SCHEMA 4 dan bagian baru 6; rule `save-system` dan `content-data`; AGENTS.md (peta repo).

**Target aus yang terukur (BALANCING 8.2, bot di `BikeMotion` + `RouteBuilder` nyata, 60 seed, tanpa tabrakan dan tanpa servis):** santai terus = komponen pertama PERLU_BENGKEL di rute ke-19 (>= 12); campuran = rute ke-12; ngebut sebisa stamina + rem sering = rute ke-5 (<= 6). Semua rusak total, santai terus: tiba 87 detik pada rute 240 ubin (tenggat 92), sisa waktu terkecil 4,9 detik di 60 seed (cadangan 2,0). Rem blong dari 6,0 u/d berhenti 9,0 ubin (normal 3,6). Identitas efek: sidik 500 masukan acak = sidik kode gerak sebelum perubahan (`885da896...4404`, dihitung dari `git HEAD` `bike_motion.gd`).

**Penyimpangan dan keputusan kecil (bisa ditolak di review):**
1. **M-5**: rantai berisik dan ban mendesis memperingatkan mulai santai 3,0 u/d (`KONDISI_PERINGATAN_KECEPATAN_MIN_UD`), bukan rantai di >= 4,5 u/d. Alasan: dengan 4,5 u/d, pemain santai terus (aus rantai nyata, PERLU_BENGKEL di ~rute 19+) tidak pernah mendengar tanda rantai sebelum efeknya muncul; AC-8 meminta peringatan mendahului efek untuk kedua profil. Dites dengan lintasan aus nyata.
2. **AC-10a "dominasi"**: dites per langkah dari keadaan yang sama (kecepatan, jarak, lateral, kecepatan tujuan dengan efek <= tanpa efek; semua pengali <= 1,0; monoton terhadap kondisi), bukan lintasan panjang: pada lintasan panjang stamina berbeda menggeser `lelah` (baseline terjepit ke cepat sementara sepeda dengan ban bocor belum lelah), jadi kecepatan berurutan tidak dominan walau tiap langkah dominan. Untuk rem, "dominasi" berarti rem blong tidak pernah berhenti lebih cepat dari normal (kecepatan akhir dan jarak >= normal); kecepatan <= tanpa efek tidak berlaku saat mengerem.
3. **Save**: `koin_total` dinaikkan ke `koin` bila lebih kecil (invarian saldo <= total, di `_normalisasi`); `sepeda` bertipe salah, komponen bukan objek, atau `servis_total` bukan angka = save rusak; kondisi tidak sah (di luar 0..1, bukan angka, NaN) dijepit/1,0 (bukan rusak); save v2 yang kebetulan memuat `sepeda` liar digantikan sepeda baru (v2 tidak pernah menulisnya, jadi tidak ada upgrade gratis); `terakhir` tidak diberi field kondisi (tidak wajib).
4. **API untuk bagian B**: `DataSave.CatatanHari` kini punya `sepeda` (bentuk `state["sepeda"]`, kosong = tidak berubah; `level` dan `servis_total` hanya naik) dan `belanja_koin`; `catat_hari` menambah `koin` dan `koin_total` dengan koin hari sekali, mengurangi `koin` dengan belanja (jepit 0). `Economy` bekerja pada state save dan mengembalikan `Economy.Hasil` (state baru, `diterima`, `alasan` enum, `harga`). `BikeCondition.telemetri(hasil, dt)` mengubah keluaran `BikeMotion.langkah` jadi telemetri aus; `BikeCondition.tabrakan(kondisi, hari, tabrakan_hasil)` memakai `Tabrakan.Hasil` apa adanya; `BikeCondition.efek(kondisi, DataToko.pengali_efek(daftar, level))` untuk gerak dan `DataToko.pengali_aus` untuk `aus`; `BikeCondition.langkah_peringatan` menghasilkan daftar komponen yang memperingatkan (bunyi dan visual disambungkan UI).
5. **Upgrade (M-10)**: `ban_anti_selip` 600 (kecepatan lateral x1,15), `rem_pakem` 500 (perlambatan rem x1,2), `rantai_hemat` 700 (kuras stamina x0,85 dan aus rantai x0,8). Jenis efek tertutup: `pengali_aus` (0,5-1,0), `pengali_rem` (1,0-1,5, hanya rem), `pengali_lateral` (1,0-1,25, hanya ban), `pengali_kuras_stamina` (0,5-1,0, hanya rantai); `efek` di JSON berupa daftar (rantai hemat dua efek). Tidak ada jenis yang menaikkan kecepatan puncak.
6. **`HariMain` (minimum, sementara)**: tombol "Hari berikutnya" di layar hasil sekarang menerapkan `BUKA_BENGKEL` lalu `HARI_BERIKUTNYA` (bengkel dilewati tanpa layar) supaya `MesinHari` baru tidak mematahkan tes alur hari; satu simpan per hari tetap. Bagian B menggantikannya dengan layar bengkel.
7. **Tes lama yang diubah (alasan di commit)**: `tes_hari.gd` (SAVE_VERSI 3, templat bertambah `koin_total` dan `sepeda`, versi 3 kini sah dan TERLALU_BARU mulai versi 4, tabel transisi MesinHari 4 x 4 dan HARI_BERIKUTNYA hanya dari BENGKEL, back di bengkel, daftar field v3, `koin_total` mengikuti `koin` pada state uji); `tes_misi_save.gd` (versi 3 dan v4 TERLALU_BARU); `run_tests.gd` (regex awalan kunci menambah `BENGKEL_`, `KONDISI_`, `TOKO_`; pemindai angka literal mengecualikan nomor versi pada baris `if versi < N:` / `versi = N`); `tes_export.gd` (jalur wajib ikut paket). Angka tuning lama tidak diubah.
8. **Satu run penuh yang tidak bisa diulang**: sekali selama pekerjaan `run_tests.gd` menampilkan `SCRIPT ERROR: Invalid call. Nonexistent function 'rencana_misi' in base 'previously freed'` di `tes_misi_alur.gd:162` dan beberapa kegagalan "persegi sprite di dalam layar" di `tes_tata_letak.gd` (posisi sprite di luar layar). Run berikutnya bersih (sedikitnya sepuluh run penuh sesudahnya di repo dan lima salinan dasar, ditambah 83 run mutan yang gagalnya hanya pada tes yang dituju). Penyebab tidak terbukti (dugaan: lonjakan waktu frame di mesin saat itu); perlu diwaspadai QA bila muncul lagi.

**Belum dikerjakan (bagian B atau orchestrator) dan TIDAK terbukti sama sekali oleh bagian A:** aus, tabrakan, dan efek belum tersambung ke `SepedaUji`/`AdeganJalan`/`RuteMain` (belum ada kondisi yang berubah saat bermain; tes bagian A memakai `BikeMotion` dan `Tabrakan` murni); HUD kondisi, tanda peringatan bunyi dan visual berpasangan, layar hasil (baris kondisi, tombol "Ke bengkel"), layar bengkel, audio `condition/`, probe, tata letak, kunci `BENGKEL_`/`KONDISI_` UI; AC-4 (contoh save dengan satu belanja dari alur hari), AC-20, AC-21, AC-22 sampai AC-27, AC-29 sebagian (DESIGN_SPEC, SETUP_ANDROID 8.11, `docs/README.md`, perintah di `00-project-core.mdc`); mutan UI AC-31. Semua angka tuning adalah usulan yang BELUM dinilai di HP (target aus, harga, efek, jeda peringatan).

## NEEDS-MANUAL (uji di HP)
- [ ] Lihat SPEC bagian NEEDS-MANUAL; rincian dan lembar hasil di `docs/SETUP_ANDROID.md` 8.11.

## Keputusan & catatan
- Keputusan pemilik 2026-10-20: K-1 koin = saldo (bengkel dibayar langsung, `koin_total` untuk milestone); K-2 mode bantu tidak mengubah aus/kerusakan; K-3 kejadian rute hanya aus + tabrakan (paku/kaca/genangan = usulan 6A2); K-4 bengkel boleh dilewati.
- Keputusan orchestrator M-1 sampai M-13 di SPEC (usulan, bisa ditolak di review).
- Hasil uji HP 4A dan 4B: kosong (belum ada catatan). Fase 2, 3, 4, dan M2 tidak dicentang.
- Commit `docs:` terpisah (DEV_PHASES: teks "Fase aktif" dan baris Fase 4/6) sudah dibuat orchestrator di branch ini sebelum iterasi 1 (771402f).
