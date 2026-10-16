# Loop Log — 20261017-fase3b-rintangan-skor
Scope: Run 3B Fase 3, rintangan (anjing penjaga, mobil keluar garasi), tabrakan, skor + combo + pengali kecepatan + tepat, koin + tip, nada combo, bel "Kring Kring!"  ·  Branch: `feat/fase3b-rintangan-skor`  ·  Mulai: 2026-10-16  ·  Godot: 4.7.2

## Status: IN_PROGRESS   (iterasi saat ini: 1/2)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 1a | Bagian A (Dev): logika murni anjing, mobil, rintangan rute, tabrakan + oleng di `BikeMotion`, skor/combo/koin/tip/tepat/terantar, pemberi tip berseed, bel, nada combo, pemetaan bunyi; 10 WAV placeholder (`sintesis_rute.py` + `uji_sintesis_rute.py` + CI) dan API `Audio`; Config + BALANCING 2/5b/6c/6d/7/10, SOUND_DESIGN; 4 tes baru; 30 mutan mati. Commit `5045dfa`, `28ca026`, `6649b24`, `9a8e209` + log | ✅ import bersih (0 ERROR); `run_tests` 8919 lolos 0 gagal; `cek_keluaran_tes.py` dan `--ketat` lolos (0 peringatan); `--quit-after 2` 0 ERROR/WARNING; 5 `uji_*.py` lolos; `--export-pack` memuat WAV dan skrip baru, tanpa `tests/`/`docs/` | (QA sesudah bagian B) | | |
| 1b | Bagian B (Dev): rintangan digambar hidup (scene `anjing_penjaga.tscn`/`mobil_garasi.tscn` dari sheet, `RintanganDaur` jendela daur + Y-sort + penerap tunggal), tabrakan diterapkan ke sepeda dengan oleng/kedip/kilatan + bunyi + sinyal `tabrakan(jenis)`, skor/koin di scene (penanda tepat dan netral, umpan melayang, nada combo, tip, tepat), HUD dev skor/combo/koin, bel (zona tap, tombol 40x40 dari `bel.py --salin`, efek KRING, anjing mundur), jeda dan Main lagi; `tes_rintangan_scene.gd` + `tes_tata_letak.gd`; probe `probe_rintangan_jendela.gd` (9 tangkapan); dokumen GDD/DESIGN_SPEC/ROUTE_DESIGN/ROADMAP/BALANCING/SETUP_ANDROID/README/AGENTS/00-project-core; 20 mutan mati. Commit `914ffd6`, `d2df29c`, `80f93ac`, `9ffaf99`, `78ec51d` + log | ✅ import 0 ERROR/WARNING; `run_tests` **9333 lolos, 0 gagal**; `cek_keluaran_tes.py` dan `--ketat` lolos (0 peringatan); `--quit-after 2` 0 ERROR/WARNING; 5 `uji_*.py` lolos (41/0, 16/0, 111/0, 90/0, 32/0); `--export-pack` 0 ERROR, memuat `ui_bel_*`, `ui_ikon_seru`, sheet rintangan, scene rintangan, WAV bel/tabrakan, skrip baru, tanpa `res://tests/` dan `res://docs/`; probe `probe_rintangan_jendela` dan `probe_rute_jendela` keluar 0, 0 ERROR/WARNING, 0 keadaan tidak sesuai | (QA) | | |

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## NEEDS-MANUAL (uji di HP)
- [ ] (diisi Dev/QA; daftar awal di SPEC "Butuh uji perangkat nyata")
- [ ] (Dev 1a) Dua rintangan berseberangan sejauh jendela minimum 6 ubin (mis. anjing `dekat` lalu mobil `seberang`): celah pindah sisi sekitar 1,5 ubin (anjing bisa sampai 3 ubin maju dari rumahnya). Simulasi bot lolos di santai, cepat, dan ngebut; apakah terasa "sempat" di HP?
- [ ] (Dev 1a) Mobil yang sudah keluar tetap berhenti di separuh jalannya sampai rute habis (D-1): wajar atau perlu kembali ke garasi?
- [ ] (Dev 1a) Anjing hanya mengejar SESUDAH sepeda melewati rumahnya (D-2): pemain ngebut di tengah separuh jalan anjing lolos, di tepi trotoar sisi anjing tetap bisa tertabrak. Terasa adil?
- [ ] (Dev 1a) Bunyi placeholder: geram, gonggong, bip tiga kali, mesin, tabrakan lembut, tiga "kring", denting tip (terlambat 0,12 detik), kilau tepat; volume relatif terhadap kayuhan di speaker HP.
- [ ] (Dev 1b) Checklist lengkap uji HP 3B: `docs/SETUP_ANDROID.md` 8.7 (12 butir + lembar hasil): tanda cukup, pola anjing/mobil adil, rasa tabrakan (oleng ±1 px, kedip, kilatan), HUD skor terbaca di 2400×1080, nada combo/tip/tepat, netral, tombol bel terjangkau dan tidak bentrok swipe, anjing mundur adil (jangkauan 1 ubin ke belakang, D-5), tanpa suara terbaca, jeda dan Main lagi.
- [ ] (Dev 1b) Titik bel satu titik tetap (8, −29) untuk semua animasi dan tidak dicerminkan pada arah 90° kiri (D-16): apakah "KRING!" tetap terlihat menempel di setang saat belok?
- [ ] (Dev 1b) Saat tabrakan dengan mobil, sprite mobil digambar menumpuk sepeda (bentuk bertumpuk; mobil jadi semi-transparan bila menutupi kaki pemain): terbaca sebagai "menabrak"?

## Keputusan & catatan
- Keputusan pemilik 2026-10-16 (K-1 sampai K-4) dan keputusan orchestrator O-1 sampai O-5: lihat `SPEC.md`.
- Lingkungan awal run (orchestrator, 2026-10-16): Godot 4.7.2.stable.official (`/opt/homebrew/bin/godot`); `adb devices`: vivo V2108 `12d8c9da` tersambung; A54 tidak tersambung. `main` = `origin/main` = `4a3be86`.
- RUN_ID memakai tanggal 20261017 dari perintah pemilik walaupun dimulai 2026-10-16 (nama folder tetap).

### Catatan Dev iterasi 1a (bagian A: logika murni, bunyi, angka)

Bagian A selesai; bagian B (scene, sprite, HUD, input bel, probe, GDD/DESIGN_SPEC/ROUTE_DESIGN/ROADMAP/README/AGENTS/SETUP_ANDROID) belum disentuh. Branch `feat/fase3b-rintangan-skor`, tidak di-push. Tidak ada temuan QA (belum ada).

**Commit**

| Commit | Isi |
|---|---|
| `5045dfa` feat: skor, combo, koin, tip, dan antaran tepat | `SkorRute`; `ZonaSasaran` (inti tepat, `Penanda.TEPAT`/`NETRAL`); `KoranLempar` (`bantu`, `id_rumah`, `tepat`, `zona_mendarat`); `RouteBuilder` (pemberi tip berseed); Config `SKOR_*`, `KOIN_*`, `RUTE_PEMBERI_TIP_PERSEN`, inti; BALANCING 5b, 7, 10; `tests/tes_skor.gd` |
| `28ca026` feat: anjing penjaga, mobil garasi, tabrakan, dan bel | `AnjingPenjaga`, `MobilGarasi`, `RintanganRute`, `Tabrakan`, `Bel`; `BikeMotion.langkah(..., tahan_naik)`; Config `ANJING_*`, `MOBIL_*`, `TABRAKAN_*`, `BEL_*`; BALANCING 6, 6c, 6d, 10; `tests/tes_rintangan.gd`, `tests/tes_bel.gd` |
| `6649b24` feat: bunyi placeholder rintangan, tabrakan, bel, tip, tepat dan nada combo | `tools/audio_art/sintesis_rute.py` + 10 WAV (`assets/audio/sfx/{obstacle,bell,ui}/`, `.import` PCM sekali putar), `tools/tests_cek/uji_sintesis_rute.py` (+ CI), `BunyiRute`, nada combo di `BunyiLempar`, API `Audio`; Config `AUDIO_*`; BALANCING 2, 10; SOUND_DESIGN 3.1, 3.3, 4.1-4.3, 6, 8; `assets/audio/LICENSES.md`, `tools/audio_art/README.md`; `tests/tes_bunyi_rute.gd` |
| `9a8e209` test: bot ngebut di sisi bebas | AC-4 diperkuat (ngebut juga tanpa tabrakan di 20 seed) |
| (commit log ini) docs | LOG |

**Kelas dan berkas baru** (`scripts/systems/`): `anjing_penjaga.gd` (`AnjingPenjaga`), `mobil_garasi.gd` (`MobilGarasi`), `rintangan_rute.gd` (`RintanganRute`), `tabrakan.gd` (`Tabrakan`), `skor_rute.gd` (`SkorRute`), `bel.gd` (`Bel`), `bunyi_rute.gd` (`BunyiRute`). Tes: `tests/tes_rintangan.gd` (`TesRintangan`), `tes_skor.gd` (`TesSkor`), `tes_bel.gd` (`TesBel`), `tes_bunyi_rute.gd` (`TesBunyiRute`); semuanya didaftarkan di `run_tests.gd` (tidak ada tes lama yang diubah atau dihapus).

**Keputusan Dev (usulan, bisa ditolak di review; angka di BALANCING 6c/6d/5b)**

- **D-1 (pola mobil, AC-2 meminta Dev memilih).** Tanda (lampu mundur + bip) menyala **1,5 detik berdasarkan waktu**, bukan jarak, jadi tanda selalu sama lama di semua kecepatan (aturan 2 terpenuhi juga di ngebut). Lalu mundur 1,0 u/d sampai bagasi tepat di garis tengah dan **berhenti di sana sampai rute disusun ulang** (menutup separuh jalan sisinya; separuh lain bebas). Paling sederhana dan mudah dipelajari; konsekuensi: pada ngebut sepeda sudah lewat sebelum mobil sampai jalur (mobil tidak berbahaya), pada santai mobil sudah menutup jalur sebelum sepeda tiba. Tercatat NEEDS-MANUAL.
- **D-2 (pola anjing).** Mulai mengejar saat sepeda **sampai di titik rumahnya** (`ANJING_KEJAR_JARAK_UBIN` 0), lari menuju maju sepeda tanpa mendahuluinya (laju sepeda × 1,25, dijepit 2,0..4,5 u/d; batas bawah supaya sepeda yang berhenti tetap dikejar) dan menyamping 2,0 u/d di separuh jalannya; berhenti di batas halaman 3 ubin atau sesudah menabrak; lalu pulang dan tidak waspada lagi untuk lintasan itu (`selesai`). Berbahaya hanya saat `MENGEJAR` dan `BERHENTI` (anjing di halaman di luar jangkauan sepeda; anjing pulang/mundur tidak menggigit). Alasan: "mengejar sesuai kecepatan pemain" (GDD 5.1) dan AC-23 b (santai tersusul, ngebut lolos) sambil menjaga tanda ≥ 1,5 detik. Bila anjing mulai lari sebelum sepeda lewat, tanda di ngebut < 1,5 detik (mutan M4 membuktikan invarian menangkapnya).
- **D-3 (tanpa tabrakan ganda, AC-6).** Selain kebal 1,0 detik, rintangan yang bersentuhan dengan sepeda saat tabrakan atau selama kebal "menempel" dan tidak memicu tabrakan lagi sampai sepeda terpisah darinya. Tanpa aturan ini sepeda yang terus melaju melewati mobil yang ditabraknya (1,0 u/d, panjang sentuh sekitar 1,55 ubin) tertabrak lagi tepat sesudah kebal habis. Anjing penyebab juga berhenti mengejar (`kena_tabrak`).
- **D-4 (tafsiran AC-3).** "Saat rintangan pertama kali bisa menyentuh jalur sepeda" = pertama kali bentuk rintangan beririsan dengan pita lateral bentuk sepeda (lebar 0,5 di sekitar posisi lateral sepeda) di mana pun sepanjang jalan, jadi tafsirannya konservatif (lebih awal dari tabrakan sebenarnya). "Tidak lebih pendek pada kecepatan lebih rendah" dites sebagai: di santai, cepat, dan ngebut selang ≥ 1,5 detik, dan bila bahaya terjadi di dua kecepatan, yang lebih pelan tidak lebih pendek. Di beberapa posisi dekat garis tengah anjing tidak pernah sampai ke jalur pada cepat/ngebut (sudah di batas halaman), jadi selangnya tak hingga; pasangan itu tidak dibandingkan.
- **D-5 (jangkauan bel ke belakang).** GDD 5.4/K-3 menyebut jangkauan "sekitar 4 ubin di depan sepeda", tetapi anjing yang **mengejar** (D-2) berlari di samping atau sedikit di belakang sepeda, jadi bel tidak akan pernah mengenainya bila hanya ke depan, padahal K-3 menyebut anjing "waspada atau mengejar". Dipilih jangkauan dari 1,0 ubin di belakang (`BEL_JANGKAUAN_BELAKANG_UBIN`) sampai 4,0 di depan, seluruh lebar jalan. Untuk ditinjau pemilik (bagian B mencatatnya di GDD 5.4).
- **D-6 (bel).** Teks 0,5 detik (jendela ketukan kedua; GDD "sekitar 0,4 detik" untuk bunyinya). "Kring" tunggal yang teksnya habis tidak memulai jeda (GDD: jeda sesudah dua bunyi), jadi "kring" tunggal bisa diulang tiap 0,5 detik; bila terasa terlalu sering di HP, jeda juga untuk kring tunggal (satu baris di `Bel.ketuk`).
- **D-7 (skor).** Dihitung bilangan bulat (persen dan persepuluh) lalu satu kali dibagi dan dibulatkan setengah ke atas, supaya 82,5 tidak jatuh ke 82 karena float (mutan M11). Jendela dengan sakelar bonus = 100% (BALANCING tidak menyebut persen; "bonus" ditandai bintang). Halaman dan jendela bonus ikut menaikkan combo. Koran ke rumah terantar termasuk jendela penalti = netral (O-1 "zona rumah yang sudah terantar").
- **D-8 (penanda tepat dan netral).** `ZonaSasaran.Penanda` mendapat `TEPAT` dan `NETRAL` (ditambah di akhir enum), tetapi dipilih `SkorRute` (hanya skor tahu rumah terantar), bukan `KoranLempar`; `KoranLempar.Koran.penanda` tetap dari zona, sehingga semua tes lama hijau tanpa diubah. Bagian B yang menimpa penanda koran dengan `hasil_skor.penanda` dan menambah pola di `PolaPiksel.pola_penanda` (sekarang keduanya jatuh ke silang).
- **D-9 (pemberi tip).** 30% dibulatkan ke bawah (25 → 7), dipilih Fisher-Yates sebagian dengan RNG rute **sesudah** pelanggan, jadi rute, pelanggan, dan koran awal run 3A tidak berubah untuk seed yang sama.
- **D-10 (pita pengali kecepatan, O-5).** Kecepatan sebenarnya saat jari dilepas (`Lintasan.kecepatan_maju_ud`) dipetakan ke kekuatan setara lalu ambang sprite 0,33/0,80: santai < sekitar 3,99 u/d, cepat sampai sekitar 5,4, ngebut di atasnya.
- **D-11 (bunyi).** Tip dan tepat "sesudah bunyi mendarat" dipanggang sebagai senyap 0,12 / 0,05 detik di awal berkas (tanpa pewaktu di `Audio`, jadi jeda tetap menghentikannya seketika). "Kring kring!" = variasi bel berikutnya dengan pitch +1 setengah nada, bukan berkas lain. Tabrakan sekitar 3 dB lebih pelan di berkasnya (SOUND_DESIGN 2). Anjing mundur karena bel tidak berbunyi sendiri (belnya yang berbunyi).
- **D-12 (`Audio.hentikan_lempar`).** Kini menghentikan semua bunyi bus SFX, termasuk bunyi rute, jadi `ProbeKeluar` dan runner tes tidak perlu diubah untuk keluar bersih.
- **D-13 (simulasi invarian).** AC-4: bot "sisi bebas" memilih sisi lawan dari rintangan dengan titik rumah paling awal di [maju − 3,7, maju + 12] dan berjalan di lateral ±0,5; okupansi dicatat per potongan maju 0,25 ubin secara konservatif (tepi terdalam tiap sisi) dan harus menyisakan pusat sepeda di [−2, 2]. Dijalankan untuk santai dan ngebut di 20 seed (0 tabrakan; cepat juga 0, diukur, tidak dites). AC-7: bot "penabrak" menuju pusat lateral rintangan terdekat yang belum ditabrak, di 3 seed (11 dari 11 rintangan tertabrak tiap seed).

**Mutan nyata (AC-25).** Satu penggantian teks di kode produksi, `run_tests.gd` penuh, lalu `git checkout` berkas itu (skrip di scratchpad, tidak di-commit). 30 dari 30 mati, 0 `SCRIPT ERROR`.

| # | Sistem | Mutasi | GAGAL | Tes yang membunuh (contoh) |
|---|---|---|---|---|
| M1 | anjing | batas waspada eksklusif (`>`) | 1 | "sepeda tepat 9 ubin di belakang: WASPADA (inklusif)" |
| M2 | anjing | pusat boleh sampai garis tengah | 2 | separuh jalan: tepi bentuk 0,2 > 0 |
| M3 | anjing | batas laju di atas ngebut | 4 | laju kejar literal, maju 20,825, langkah berhenti 6 |
| M4 | anjing | mengejar 3 ubin sebelum lewat | 8 | literal langkah 28; invarian AC-3 (terpendek 1,117 < 1,5); AC-23 b ngebut tidak lolos |
| M5 | mobil | tanda 1,0 detik | 10 | literal TANDA/MUNDUR; invarian AC-3 |
| M6 | mobil | bentuk seberang melewati garis tengah | 14 | persegi literal; separuh jalan; okupansi 20 seed |
| M7 | tabrakan | tanpa kebal | 3 | "0,9999 detik: masih kebal"; tanpa ganda |
| M8 | tabrakan | menempel diabaikan | 6 | "satu tabrakan saja"; bot penabrak tanpa tabrakan berulang |
| M9 | tabrakan | kecepatan tidak turun | 1 | "6,0 -> 1,0" |
| M10 | oleng (`BikeMotion`) | `tahan_naik` diabaikan | 2 | "kecepatan tetap 1,0 saat oleng" |
| M11 | skor | pembulatan ke bawah | 4 | 82,5 -> 83, 243,75 -> 244, 162,5 -> 163 |
| M12 | combo | naik sebelum antaran dinilai | 13 | urutan 12 koran literal |
| M13 | combo | tanpa maksimum x2,0 | 6 | 14 antaran: tetap 200 |
| M14 | terantar (O-1) | rumah terantar diantar lagi | 7 | koran kedua netral; halaman mengunci |
| M15 | tip | tip bukan hanya teras | 4 | kotak surat tanpa tip; simulasi 375 koin |
| M16 | koin (O-2) | halaman setengah ongkos | 5 | ongkos halaman 15; total 95 koin |
| M17 | tepat | tepi lateral maks inti inklusif | 2 | tepi -2,0 / 2,375 eksklusif (kedua sisi) |
| M18 | tepat (O-4) | mode bantu dapat tepat | 5 | bantu ke pusat = kotak surat biasa; 0 tepat di 25 antaran bantu |
| M19 | pemberi tip (O-3) | selalu 7 pelanggan pertama | 1 | 200 seed: 37 himpunan < 150 |
| M20 | bel | tidak pernah kring kring | 9 | urutan ketukan literal |
| M21 | bel | jeda bel tidak menolak | 2 | "ketukan selama jeda: TOLAK" |
| M22 | bel (tabel) | anjing tidak bereaksi | 5 | tabel; anjing 4 ubin di depan MUNDUR |
| M23 | bel (jangkauan) | hanya di depan | 2 | jangkauan 9,0; anjing mengejar 0,9 di belakang |
| M24 | nada combo | antaran ke-1 sudah naik | 6 | tingkat literal |
| M25 | nada combo | tanpa batas 5 tingkat | 1 | tingkat 6 -> 1,334840 |
| M26 | pemetaan bunyi | waspada menggonggong | 2 | tabel peristiwa; hitungan Audio |
| M27 | `Audio` | bunyi rute saat jeda | 2 | "selama jeda: tidak ada bunyi rute baru" |
| M28 | `Audio` | jeda tidak menghentikan bunyi rute | 7 | `atur_jeda`, `perbarui_sepeda`, notifikasi |
| M29 | rintangan dari rute (AC-5) | anjing bergeser 1 ubin | 8 | 4 seed: rintangan = objek JSON mentah |
| M30 | `RintanganRute` | anjing tetap mengejar sesudah menabrak | 4 | "anjing penyebab berhenti"; bot penabrak 16 tabrakan > 13 |

**Gerbang (dijalankan Dev sesudah commit kode terakhir)**

- `godot --headless --import`: 0 baris ERROR.
- `godot --headless --script res://tests/run_tests.gd 2>&1 | tee build/tests.log`: **8919 lolos, 0 gagal** (dasar sebelum run 8346; +573). Waktu sekitar 23 detik (dasar sekitar 19).
- `python3 tools/cek_keluaran_tes.py build/tests.log` dan `--ketat`: lolos, 0 peringatan.
- `godot --headless --path . --quit-after 2`: 0 baris ERROR/WARNING.
- `python3 tools/tests_cek/uji_pemeriksa.py` (16 kasus, 0 menyimpang), `uji_bangun_frames.py` (41/0), `uji_sintesis_sepeda.py` (32/0), `uji_sintesis_lempar.py` (111/0), `uji_sintesis_rute.py` (90/0).
- `godot --headless --path . --export-pack "Android" build/kring-uji.pck`: 0 ERROR; paket memuat 10 WAV baru dan skrip sistem baru, tanpa `tests/` dan `docs/` (dicek dengan mencari nama berkas di paket). Probe jendela dan pemuatan dari paket = bagian B.

**Cakupan SPEC oleh bagian A**: AC-1, AC-2, AC-3, AC-4, AC-5, AC-6 (logika), AC-7 (simulasi murni), AC-9, AC-10, AC-11, AC-12 (zona dan oracle; pola penanda di B), AC-14, AC-17 (logika), AC-18 (logika), AC-19 (berkas, uji, `Audio`; sambungan scene di B), AC-23 a/b/c, AC-24 (untuk angka bagian A; teks terjemahan di B), AC-25. Untuk bagian B: AC-8 (visual dan sinyal scene), AC-13, AC-15, AC-16, AC-20, AC-21 (scene), AC-22, AC-26 (probe), dan dokumen GDD 5.4/9.3, DESIGN_SPEC 3.6/3.8, ROUTE_DESIGN 4, ROADMAP 5, README, AGENTS, SETUP_ANDROID, `00-project-core.mdc` (perintah `sintesis_rute.py`, `uji_sintesis_rute.py`). `DATA_SCHEMA` 3 tidak perlu field baru (AC-5).

**BLOCKED**: tidak ada. Keputusan terbuka ROADMAP 5 tidak diputuskan: tanpa game over dan tanpa batas tabrakan per rute (K-1); sakelar jendela tetap `Config.JENDELA_KENA_BONUS` (dibaca, tidak diubah); struktur sesi tidak disentuh.

### Catatan Dev 1A untuk bagian B

Semua fungsi di bawah murni (`static func`, masukan tidak diubah, objek keadaan baru dikembalikan). Koordinat jalan: x = lateral (negatif = seberang), y = maju; dunia `Iso` = (x, −maju).

1. **Keadaan baru di `RuteMain`/`AdeganJalan`:** `_rintangan: RintanganRute.Keadaan` (`RintanganRute.dari_rute(_rute)`, sudah berisi `tabrakan`), `_skor: SkorRute.Keadaan` (`SkorRute.awal()`), `_bel: Bel.Keadaan` (`Bel.awal()`). "Main lagi" (AC-22): buat ulang ketiganya + `Audio.atur_ulang_rute()`. Jalan uji: `RintanganRute.Keadaan.new()` kosong.
2. **Urutan per langkah** (satu urutan, sama dengan simulasi tes `TesRintangan._sim_rute`): (a) sepeda: `BikeMotion.langkah(keadaan, stick, dt, Tabrakan.oleng(_rintangan.tabrakan))` (`SepedaUji.gerak` perlu meneruskan argumen ini); (b) `var hr := RintanganRute.langkah(_rintangan, jarak, lateral, kecepatan, dt)`, `_rintangan = hr.keadaan`; (c) tiap `hr.kejadian`: `Audio.putar_peristiwa(k.peristiwa)` + visual (animasi dari `RintanganRute.animasi(item)` sudah berubah); (d) bila `hr.tabrak`: keadaan sepeda = `Tabrakan.terapkan_ke_sepeda(...)` (perlu `SepedaUji.tabrak()`), `_skor = SkorRute.putus_combo(_skor)`, `Audio.putar_tabrakan()`, sinyal scene `tabrakan(jenis: String)` dengan `hr.jenis_tabrak` (AC-8), visual oleng selama `Tabrakan.oleng(_rintangan.tabrakan)`, kebal `Tabrakan.kebal(...)`; (e) bel dan skor di bawah. Jeda: `dt` efektif 0 membekukan semuanya (dites).
3. **Koran mendarat:** `var hs := SkorRute.nilai_koran(_skor, koran, _rute, Config.JENDELA_KENA_BONUS)`; `_skor = hs.keadaan`; **timpa** `koran.penanda = hs.penanda` (TEPAT/NETRAL/...) sebelum digambar; bunyi `Audio.putar_mendarat(koran.hasil, Config.JENDELA_KENA_BONUS, BunyiLempar.pitch_mendarat(hs.urutan_beruntun))`, lalu `Audio.putar_tip()` bila `hs.tip > 0` dan `Audio.putar_tepat()` bila `hs.tepat`. Sekarang `_bunyi_mendarat` tersambung langsung ke sinyal `koran_mendarat` tanpa skor, jadi urutannya perlu diubah (nilai dulu, lalu bunyi). HUD: `_skor.skor`, `_skor.koin`, pengali combo berikutnya `SkorRute.pengali_combo(_skor.beruntun)`; umpan balik melayang dari `hs.skor_tambah`, `hs.koin_tambah`, `hs.tip`, `hs.tepat`. Pola `ZonaSasaran.Penanda.TEPAT` dan `NETRAL` belum ada di `PolaPiksel.pola_penanda` (jatuh ke silang): tambahkan, bentuk beda dari centang dan bintang (AC-12, O-1). **Tes lama**: bila scene menimpa penanda, lemparan swipe ke pusat kotak surat menjadi `TEPAT`, bukan `CENTANG` (`tes_koran_scene.gd`, `probe_*`); lemparan mode bantu tetap centang.
4. **Mode bantu (O-4):** tap harus membuat koran dengan `KoranLempar.baru(lintasan, true)` (sekarang `_lempar` memanggil `baru(lintasan)` untuk swipe dan tap; perlu argumen `bantu`).
5. **Jalan uji dan skor:** zona jalan uji tidak punya `id_rumah` (kosong), jadi `SkorRute` tidak bisa mengunci rumah di sana (tiap pendaratan = antaran baru). Bila HUD skor tampil di jalan uji, beri id kavling (mis. `uji@<indeks>`) atau jangan menilai skor di jalan uji.
6. **Bel:** tombol (input, AC-15) -> `var hb := Bel.ketuk(_bel, _jeda)`, `_bel = hb.keadaan`; bila `Bel.berbunyi(hb.bunyi)`: `Audio.putar_bel(hb.bunyi)` dan `_rintangan = RintanganRute.terapkan_bel(_rintangan, jarak).keadaan` (hasil `.kejadian` berisi `ANJING_MUNDUR` untuk visual; `.bereaksi` = id). Tiap langkah `_bel = Bel.langkah(_bel, dt_efektif)`. Tampilan: `Bel.teks_tampil(_bel)` dan `_bel.dobel` (KRING! / KRING KRING!, kunci terjemahan baru), cincin jeda `Bel.sisa_jeda_pecahan(_bel)`, ikon "!" `RintanganRute.ikon_seru(item)`. Zona tap bel (lingkaran radius 28 di (lebar − 28, 332), kidal (28, 332)) belum ada di `Config`/`TouchRouter`.
7. **Gambar rintangan:** `RintanganRute.di_rentang(_rintangan, jarak − RUTE_DAUR_MUNDUR_UBIN, jarak + RUTE_DAUR_MAJU_UBIN)`; posisi `RintanganRute.posisi(item)` (anjing = pusat bentuk; mobil = pusat bentuk, maju = titik rumah), nama animasi `RintanganRute.animasi(item)` = kunci `anim` di JSON sheet (dites terhadap JSON). Arah hadap: sheet anjing `lari` menghadap maju; saat `PULANG`/`MUNDUR` anjing bergerak mundur (balik sprite, keputusan B). Mobil: `ground_anchor` (43, 46) dari JSON perlu dipetakan ke bentuk tabrakan (bagasi = `belakang_ubin` dari garis tengah); `kotak(item)` bisa dipakai untuk menggambar bentuk uji. Penutup: rintangan perlu didaftarkan ke `PenerapPenutup` dengan tinggi (angka tinggi mobil/anjing belum ada di `Config`).
8. **Angka yang belum ada untuk B:** tombol bel, efek bel, HUD skor/koin, umpan balik melayang (DESIGN_SPEC), tinggi rintangan untuk penutup. Teks pemain (KRING!, skor, koin, TEPAT, +tip) lewat `translations/ui.csv`.

### Catatan Dev iterasi 1b (bagian B: scene, HUD, bel, probe, dokumen)

Bagian B selesai di branch `feat/fase3b-rintangan-skor` (tidak di-push). Tidak ada temuan QA (QA belum jalan). Tidak ada bug bagian A yang ditemukan; satu perubahan kecil di bagian A tercatat di D-18 (animasi anjing kaget).

**Commit**

| Commit | Isi |
|---|---|
| `914ffd6` art | `tools/ui_art/bel.py --salin`: `assets/sprites/ui/ui_bel_tombol.png` (diam, ditekan, 8 frame jeda cincin 8/8..1/8), `ui_bel_getar.png`, `ui_ikon_seru.png`, `ui_bel.json` (+ `.import`); render dokumen `docs/design/bel/` tidak berubah (piksel 1x dibandingkan sama); README alat dan bel |
| `d2df29c` feat | Scene: `scenes/entities/anjing_penjaga.tscn`, `mobil_garasi.tscn` (SpriteFrames dari sheet, titik pijak dan animasi dari JSON); `RintanganDaur`, `EfekSepeda`, `UmpanMelayangGambar`, `TombolBel`, `UmpanMelayang` (murni); `AdeganJalan` (urutan langkah rintangan, tabrakan, skor di koran mendarat, bel, jeda, Main lagi), `RuteMain` (kait), `SepedaUji` (`tahan_naik`, `tabrak`, visual oleng/kedip, efek bel), `HudDev` (panel skor, tombol bel), `TouchZones`/`TouchRouter` (zona dan jari bel), `PolaPiksel` (TEPAT, NETRAL, IKON_TABRAKAN), `KoranGambar` (warna netral), `Tabrakan`/`Bel`/`RintanganRute` (fungsi tampilan murni); Config bagian B; `translations/ui.csv` (+ `.translation`) 11 kunci baru; tes lama yang disesuaikan (lihat bawah) |
| `80f93ac` test | `tests/tes_rintangan_scene.gd` (`TesRintanganScene`, didaftarkan di `run_tests.gd`), `tes_tata_letak.gd` (tombol bel dan panel skor, 3 rasio × kidal), `tests/probe_rintangan_jendela.gd` |
| `9ffaf99` docs | GDD 5.4 dan 9.3, ROUTE_DESIGN 4, ROADMAP 5, DESIGN_SPEC 3.6 dan 3.8, BALANCING 6e dan 10, SETUP_ANDROID 8.7, docs/README, AGENTS, `00-project-core.mdc` |
| `78ec51d` docs | 9 tangkapan layar `shots/iter1/2340x1080_rintangan_*.png` |

**Tes lama yang diubah (dengan alasan; tidak ada yang dihapus):**
- `tes_input_murni.gd` "pojok zona swipe inklusif": pojok bawah sisi luar zona swipe (lebar − 20, 352) / kidal (20, 352) kini di zona tap bel (jarak 21,5 ≤ 28) dan bel menang atas swipe (AC-15); tiga pojok lain tetap diperiksa, pojok itu diperiksa = BEL.
- `tes_input_scene.gd`: HUD punya dua kontainer anchor baru (`StripSkor`, `StripBel`), diperiksa anchor-nya; daftar kontainer yang dikecualikan dari "ditata Container" jadi lima.
- `tes_rute_scene.gd`: (a) anak Objek kini + node induk `Rintangan` (rintangan memang digambar sejak 3B; label lama "rintangan di data tidak digambar"); (b) jumlah di penerap = rumah + rintangan tampil; (c) kisi mode bantu: koran kedua ke rumah yang sama kini penanda NETRAL (O-1), oracle mencatat rumah terantar sendiri.

**Keputusan Dev bagian B (usulan, bisa ditolak di review)**

- **D-14 (skor hanya di scene rute).** `AdeganJalan` menilai skor lewat kait `_skor_aktif()` (bawaan false; `RuteMain` true). Jalan uji (scene dev) tidak menilai skor karena zonanya tanpa id rumah (catatan bagian A no. 5): penanda tetap Fase 2 dan panel skor HUD disembunyikan; semua tes jalan uji lama tetap hijau tanpa diubah. Bel, efek, dan kait tabrakan tetap ada di jalan uji (rintangan kosong).
- **D-15 (teks KRING = kunci terjemahan).** `RUTE_KRING` "KRING!" dan `RUTE_KRING_KRING` "KRING KRING!" dirender font HUD 8 px `ACCENT` bergaris `OUTLINE` (rule `content-data`: tidak ada teks pemain di gambar), jadi `teks_kring*.png` tidak disalin ke game. Aset game lewat `bel.py --salin` (opsi baru), termasuk 8 tingkat cincin jeda dari fungsi `button("jeda", p)` yang sama (desain hanya punya contoh 50%).
- **D-16 (titik bel tetap).** Satu titik bel (8, −29) dari titik pijak pemain (= `santai_normal` di `bell_anchors.json` dikurangi (23, 46)), bukan per animasi; tidak dicerminkan untuk arah 90° kiri. README bel sendiri menyebut acuan titik belum dipilih. NEEDS-MANUAL.
- **D-17 (zona bel).** `TouchZones.Zona.BEL` (ditambah di akhir enum), diperiksa sesudah stick dan sebelum swipe; `TouchRouter` memancarkan `bel_ditekan` saat jari turun di zona itu dan melacak jari bel (`bel_ditahan`) sampai diangkat/batal; jari bel tidak pernah jadi stick/swipe/tap. Tombol = `Control` gambar saja (`MOUSE_FILTER_IGNORE`) di kontainer `StripBel`, bukan `Button`, supaya semantik "dimulai di zona" dan pelacakan index tetap di router.
- **D-18 (arah sprite rintangan).** `RintanganRute.cermin_sprite`: anjing `PULANG` dan `MUNDUR` sesudah kaget dicermin (sheet `lari` menghadap maju); anjing sisi `dekat` yang duduk/waspada dicermin (menghadap sepeda yang datang dari belakang); mobil tidak (sheet = mobil seberang; data perumahan hanya punya mobil seberang). **Perubahan kecil bagian A:** `AnjingPenjaga.animasi` mengembalikan `berhenti` selama kaget (ikon "!") alih-alih `lari` (tangkapan probe pertama: anjing "berlari di tempat" tidak terbaca kaget); tes bagian A tetap hijau, mutan B13 membuktikan tes baru menjaganya.
- **D-19 (visual tabrakan).** Sprite pemain bergeser ±1 px tiap 0,05 detik selama oleng, berkedip alpha 0,5 tiap 0,1 detik selama kebal, ikon kilatan `PolaPiksel.IKON_TABRAKAN` `WARN` 50 px di atas titik pijak selama oleng; tanpa getar kamera (rule `ui-scenes`: efek tidak berlebihan). Angka di Config/BALANCING 6e.
- **D-20 (HUD dev skor).** Tiga baris (SKOR, COMBO, KOIN) di strip atas sisi swipe, 112 px dari tepi supaya tempat tombol dev "Main lagi" tetap bebas; kidal dicerminkan ke 112 px dari tepi kiri (AC-13). COMBO menampilkan pengali untuk antaran BERIKUTNYA (`SkorRute.pengali_combo(beruntun)`, catatan bagian A no. 3), format "x1.3" (titik desimal, sama dengan HUD kecepatan). Label PUTUS 0,8 detik saat rangkaian > 0 putus (tabrakan atau tidak sah).
- **D-21 (umpan balik melayang minimal).** Teks, bukan panel ikon koin: "+<ongkos>", "tip +<n>", "TEPAT", satu per baris, hanya untuk antaran sah pertama; maks 2, naik 12 px dan memudar 0,8 detik (DESIGN_SPEC 3.6).
- **D-22 (bentuk penanda).** TEPAT = sasaran berlapis 9×9 `OK` (cincin + titik pusat); NETRAL = garis datar 7×4 `TEXT_2` (`KoranGambar.warna_penanda_koran`).
- **D-23 (penutup rintangan).** Rintangan tampil didaftarkan ke `PenerapPenutup` yang sama dengan kotak tabrakannya dan tinggi 0,8 (anjing) / 1,0 ubin (mobil); kotak diperbarui tiap langkah.
- **D-24 (probe tepat).** Probe dan tes melempar "tepat" dengan lintasan `BantuLempar.pilih` (pusat kotak surat) yang dilempar sebagai lemparan biasa (`_lempar(lintasan, false)`), bukan swipe sintetis; swipe sungguhan ke kotak surat sudah dites `tes_koran_scene` (jalan uji).

**Bug yang ditemukan dan diperbaiki sendiri sebelum commit:** `RintanganDaur.perbarui` memasang node baru sebelum melepas yang keluar jendela, jadi kolam tidak terpakai (6 node dibuat, bukan 3); urutan dibalik (lepas dulu). Dijaga tes "node sprite rintangan dipakai ulang dari kolam" (mutan B2).

**Mutan nyata (AC-25, bagian B).** Satu penggantian teks di kode produksi, `run_tests.gd` penuh, lalu berkas dikembalikan (skrip di scratchpad, tidak di-commit). 20 dari 20 mati, 0 `SCRIPT ERROR`.

| # | Sistem | Mutasi | GAGAL | Tes yang membunuh (contoh) |
|---|---|---|---|---|
| B1 | zona bel | swipe diperiksa sebelum bel | 26 | pojok bawah luar zona swipe = BEL; input bel di scene |
| B2 | daur rintangan | pasang sebelum lepas | 1 | node dipakai ulang dari kolam (6 > 5) |
| B3 | tabrakan scene | `SepedaUji.tabrak` tidak dipanggil | 3 | "saat sinyal: kecepatan sudah turun ke 1,0" |
| B4 | skor scene | penanda tidak ditimpa skor | 9 | kisi bantu (netral), penanda TEPAT |
| B5 | mode bantu (O-4) | tap bantu = koran biasa | 9 | kisi bantu: centang, bukan tepat |
| B6 | bel + jeda | `Bel.ketuk` tanpa status jeda | 2 | "bel tidak bisa dibunyikan saat jeda game" |
| B7 | Main lagi | skor tidak diatur ulang | 2 | "skor, koin, combo, rumah terantar diatur ulang" |
| B8 | arah sprite | tidak pernah dicermin | 2 | anjing dekat dicermin; lari mundur dicermin |
| B9 | visual oleng | geser selalu 0 | 8 | tabel oleng literal; "+1 px" di scene |
| B10 | tombol bel | cincin jeda diabaikan | 10 | tabel frame tombol; frame 6 sesudah 0,52 detik |
| B11 | umpan melayang | tanpa batas 2 | 3 | "paling banyak dua sekaligus" |
| B12 | jeda | rintangan memakai dt mentah | 2 | "60 langkah selama jeda ... tidak berubah" |
| B13 | anjing kaget | animasi kaget = lari | 1 | "ikon ! ... anjing yang berdiri kaget" |
| B14 | HUD kidal | panel skor tidak dicermin | 3 | tata letak rute kidal: x 112 |
| B15 | nada combo scene | pitch selalu 1,0 | 1 | "nada combo antaran ke-2: pitch 1,059463" |
| B16 | oleng | `tahan_naik` tidak diteruskan | 2 | "kecepatan tetap 1,0 (oleng)" |
| B17 | jari bel | turun ganda index sama dihitung | 1 | "bel berbunyi sekali (turun ganda ... diabaikan)" (tes ditambah sesudah mutan ini lolos pertama kali) |
| B18 | penutup | rintangan tidak didaftarkan | 4 | penerap = rumah + rintangan; mobil alfa 0,45 |
| B19 | combo tabrakan | combo tidak putus saat tabrakan | 1 | "combo putus: x1.0 dan label PUTUS" |
| B20 | zona bel | radius eksklusif | 2 | "zona bel radius 28 inklusif (x 724 bel)" |

**Probe jendela (AC-26).** `godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_rintangan_jendela.gd -- docs/loop/20261017-fase3b-rintangan-skor/shots/iter1`: keluar 0, 0 ERROR/WARNING, 0 keadaan tidak sesuai. Dilihat sendiri: `anjing_waspada` (anjing berdiri di halaman dekat kotak surat), `anjing_mengejar` (anjing lari di samping sepeda di separuh seberang), `mobil_tanda` (lampu mundur dan cahaya di aspal), `mobil_di_jalan` (mobil mundur ke jalan, sepeda di sisi dekat lewat), `tabrakan_oleng` (sepeda menumpuk mobil, kecepatan 1,0, ikon kilatan di atas, sprite berkedip), `bel_kring_kring` ("KRING KRING!" di atas setang, "!" di atas anjing yang berdiri, tombol cincin jeda), `bel_anjing_mundur` (anjing lari pulang dicermin), `tepat_hud_skor` (penanda sasaran di kotak surat, "+15 / TEPAT", HUD SKOR 413, x1.3, KOIN 45), `kidal_bel_skor` (tombol bel kiri bawah, panel skor kiri atas, "KRING!"). Yang tampak salah di putaran pertama dan diperbaiki: panel skor sempat 3 px melewati strip atas (separasi VBox 0), anjing kaget memakai pose lari (D-18). `probe_rute_jendela.gd` (3A) juga dijalankan: keluar 0, tanpa ERROR/WARNING.

**Catatan untuk QA/orchestrator (di luar scope, bukan regresi 3B):** `tests/probe_bantu_jendela.gd` (jalan uji) keluar 1 dengan "1 keadaan tidak sesuai" (keadaan `tanpa_sasaran`: di `MAJU_TANPA_SASARAN` kini ada kotak surat seberang terjangkau, koran terlempar). Sama persis di `main` (dicek di worktree `main` `4a3be86`), kemungkinan sejak zona kotak surat diperbesar/dipindah ke halaman (PR #30). Tidak diubah di run ini.

**Cakupan SPEC bagian B:** AC-8 (sinyal jenis, visual, bunyi), AC-12 (bentuk penanda), AC-13, AC-15, AC-16, AC-17 (scene), AC-18/19 (sambungan scene), AC-20, AC-21, AC-22, AC-24 (angka dan teks bagian B), AC-25 (mutan B1–B20), AC-26. `DATA_SCHEMA` 3 tidak berubah (AC-5: tanpa field baru). `DEV_PHASES` tidak disentuh (orchestrator).

**BLOCKED:** tidak ada. Keputusan terbuka ROADMAP 5 tidak diputuskan: jendela tetap `Config.JENDELA_KENA_BONUS` (dibaca, tidak diubah), tanpa game over/batas tabrakan (baris baru di ROADMAP 5 hanya mencatatnya tetap terbuka), struktur sesi tidak disentuh. **Perlu ditinjau pemilik:** D-5 (jangkauan bel 1 ubin ke belakang, kini tertulis di GDD 5.4 sebagai usulan).

