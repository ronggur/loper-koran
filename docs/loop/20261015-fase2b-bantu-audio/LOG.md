# Loop Log — 20261015-fase2b-bantu-audio
Scope: Run 2B Fase 2 — mode bantu, bunyi lempar dan mendarat, QA-008/QA-005/QA-006, checklist uji HP penutup Fase 2  ·  Branch: `feat/mode-bantu-bunyi-lempar`  ·  Mulai: 2026-10-15  ·  Godot: 4.7.2

## Status: PASSED   (selesai di iterasi 2/2: QA PASS, 0 Blocker, 0 Major terbuka; QA-001 sampai QA-004 VERIFIED)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 1a | Bagian A: mode bantu AC-1..AC-8 (tap di `TouchRouter`, `BantuLempar` sisi tap + pemilihan sasaran, lemparan bantu di scene, tanda tanpa sasaran, sakelar HUD, kecepatan otomatis), AC-13 QA-008 (oracle gambar independen, N16/N20/N21/N22 mati), dokumen mode bantu (GDD 5.3, BALANCING 4b, DESIGN_SPEC 3.7, TECH_PLAN Fase 2, DEV_PHASES Fase 3, AGENTS peta repo). Bunyi, kontrol.html, SETUP_ANDROID = bagian B. HEAD kode `00954cd` | ✅ import 0 ERROR/WARNING; `run_tests` 6283 lolos 0 gagal; `cek_keluaran_tes.py` dan `--ketat` lolos (0 peringatan); `--quit-after 2` 0 ERROR/WARNING; `uji_pemeriksa` 16 kasus 0 menyimpang, `uji_bangun_frames` 41 lolos, `uji_sintesis_sepeda` 32 lolos; `--export-pack "Android"` tanpa `tests/`, `docs/`, probe | (menunggu QA) | | |
| 1b | Bagian B: bunyi lempar dan mendarat AC-9..AC-12 (13 WAV dari `tools/audio_art/sintesis_lempar.py`, `uji_sintesis_lempar.py`, `BunyiLempar`, pemutar di `Audio` bus SFX, wus per lemparan diterima, mendarat sekali per koran, berhenti saat jeda/background), AC-14 (kontrol.html arah bebas, kedua PNG dirender ulang di ukuran lama), AC-15 (GDD 4.2), AC-16 (SETUP_ANDROID 8.5), AC-17 sisa (SOUND_DESIGN 3.1/4.2/6/8, BALANCING 2, TECH_PLAN, DEV_PHASES Fase 3, AGENTS, 00-project-core, docs/README), AC-19 (`probe_bantu_jendela.gd`, 11 tangkapan). HEAD kode `be6c945` | ✅ import 0 ERROR/WARNING; `run_tests` 6445 lolos 0 gagal; `cek_keluaran_tes.py` dan `--ketat` lolos (0 peringatan); `--quit-after 2` 0 ERROR/WARNING; `uji_pemeriksa` 16 kasus 0 menyimpang, `uji_bangun_frames` 41 lolos, `uji_sintesis_sepeda` 32 lolos, `uji_sintesis_lempar` 111 lolos; `--export-pack "Android"` tanpa `tests/`, `docs/`, probe (WAV throw dan `bunyi_lempar` ada) | (menunggu QA) | | |
| 1 (QA) | — (audit QA atas HEAD `3417c9c`, gabungan 1a + 1b) | ✅ semua gerbang hijau dijalankan QA sendiri (rinci di Catatan QA iterasi 1), juga dari klon bersih | **FAIL** (1 Major OPEN) | 4 (1 Major, 2 Minor, 1 Nit) | 0 |
| 2 | Perbaikan QA-001..QA-004, hanya tes (kode game tidak diubah): kabel scene mode bantu dengan oracle independen (literal, kisi 1152 tap lawan `BantuLempar.pilih` dari masukan tes, stick sungguhan dengan kecepatan lateral terukur), gerbang habis/jeda antar lempar untuk tap tanpa sasaran, bunyi pendaratan di jendela di scene, batas inklusif "di depan". Mutan QA hidup Q1, Q9-Q13, Q29 semuanya mati. HEAD kode `22b228c` | ✅ import 0 ERROR/WARNING; `run_tests` 6522 lolos 0 gagal; `cek_keluaran_tes.py` dan `--ketat` lolos (0 peringatan); `--quit-after 2` 0 ERROR/WARNING; `uji_pemeriksa` 16 kasus 0 menyimpang, `uji_bangun_frames` 41 lolos, `uji_sintesis_sepeda` 32 lolos, `uji_sintesis_lempar` 111 lolos | **PASS** (QA atas HEAD `62b3ee6`: semua gerbang hijau dijalankan QA sendiri, juga dari klon bersih; tidak ada Blocker/Major OPEN/FIXED/DISPUTED) | 0 | 4 (QA-001..QA-004 VERIFIED) |

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|
| QA-001 | 1 | Major | scripts/entities/jalan_uji.gd:235-243 (`pilihan_bantu`); tests/tes_bantu_scene.gd:178-210 (oracle `akar.pilihan_bantu`) | **Kabel scene mode bantu tidak dijaga tes yang independen.** Masukan `BantuLempar.pilih` dari scene (daftar zona sejauh jangkauan, kecepatan maju sebenarnya, kecepatan lateral efektif, jeda lepas sisi itu; D-4, D-5) bisa dirusak tanpa satu tes pun gagal. Empat mutan QA HIDUP (6445 lolos, 0 gagal): **Q9** daftar zona diganti `zona_jalan_uji_sekitar(maju)` (padahal Dev sendiri menulis `zona_jalan_uji_rentang` justru karena `sekitar` kurang jauh), **Q10** kecepatan diganti `KECEPATAN_SANTAI_UD` tetap, **Q11** kecepatan lateral = 0, **Q12** jeda lepas = 0. Penyebab: tes scene AC-5 hanya di santai dengan lateral 0, dan harapannya diambil dari `akar.pilihan_bantu(sisi)` (fungsi yang dites, pelajaran QA-008). Dampak nyata Q9 dibuktikan skrip repro QA (`BantuLempar.pilih` dengan daftar `rentang` vs `sekitar`, 3 kecepatan x 64 posisi maju x 2 sisi): **34 dari 384 keadaan berbeda**, mis. santai 3,0 u/d maju 5,75 sampai 7,5 sisi seberang: `rentang` = kotak surat rumah 3, `sekitar` = null, jadi regresi itu memunculkan tanda "tanpa sasaran" palsu di depan kotak surat pelanggan yang terjangkau tanpa tes merah. Q10-Q12 membuat lemparan bantu tidak mewarisi kecepatan/jeda lepas yang sama dengan swipe (Tujuan 1, K-4) tetapi tetap "kena" karena konsisten dengan dirinya sendiri, jadi juga tidak tertangkap. Repro: terapkan salah satu mutan di `pilihan_bantu`, `run_tests` tetap 0 gagal. Saran: tes scene yang (a) menap seberang di maju sekitar 6 saat santai dan mengharapkan kotak surat rumah 3 (angka literal), (b) menap di cepat dan ngebut dengan kecepatan lateral ≠ 0 lalu membandingkan lintasan dengan `BantuLempar.pilih` yang dipanggil tes dengan masukan yang disusun tes sendiri (posisi dunia, `kecepatan_ud`, `lateral_ud`, jeda lepas literal 0,17 dari frame 2 di 12 fps, daftar `rentang`), dan (c) memeriksa titik lepas koran = posisi sepeda saat tap + geser selama jeda lepas. Perilaku kode sekarang benar menurut review; yang kurang adalah penjaganya. | VERIFIED | Hanya tes (kode `pilihan_bantu` tidak diubah; perilakunya sudah benar menurut review QA). `tests/tes_bantu_scene.gd`, commit `430c47a`: tiga tes scene baru yang tidak memakai `pilihan_bantu` sebagai oracle (lihat Catatan Dev iterasi 2). | `_test_kabel_literal` (7 kasus literal santai/cepat/ngebut, kecepatan lateral 0/±2/±2,4, seberang dan dekat, termasuk santai maju 5,75 / 6,5 / 7,5 seberang = kotak surat rumah 3 pusat (-1,625; 13,125); mendarat di pusat kotak surat yang ditulis eksplisit, titik lepas = posisi + geser selama jeda lepas 2/12 literal, kecepatan dan jeda lepas lintasan; satu koran sampai dinilai KOTAK_SURAT centang), `_test_kabel_kisi` (v 3,0/4,5/6,0 x kecepatan lateral 0/2/-2 x 64 maju x 2 sisi = 1152 tap lawan `BantuLempar.pilih` dengan masukan tes dan daftar zona -4..+16 ubin; juga tanda tanpa sasaran; kontrol: kisi santai mencakup keadaan yang berbeda bila daftar ±1 kavling), `_test_kabel_stick` (stick sungguhan cepat dan ngebut sambil berbelok, kecepatan lateral diukur dari perpindahan lateral sepeda). Mutan Q9/Q10/Q11/Q12 mati: 11/18/16/32 gagal. **QA iter 2:** Q9/Q10/Q11/Q12 diterapkan ulang QA (pola sama dengan deskripsi iter 1): mati 11/18/16/32. Mutan tambahan di kabel yang sama juga mati: R1b daftar zona hanya sampai maju+2 (11), R2 daftar mulai maju+4 (1), R3 lateral posisi diabaikan (11), R4 tanda kecepatan lateral dibalik (16), R5 lebar 640 tetap (1), R11 maju dari sumbu lateral (16). Oracle independen: kasus literal (pusat kotak surat dan rumus titik lepas 2/12 ditulis di tes), kisi lawan `BantuLempar.pilih` (fungsi murni yang dijaga oracle literal di `tes_bantu.gd`) dengan masukan dari tes, bukan `pilihan_bantu`; `pilihan_bantu` hanya dipakai sebagai kontrol keadaan di `_test_tanpa_sasaran_gerbang`. |
| QA-002 | 1 | Minor | scripts/entities/jalan_uji.gd:209; tests/tes_bantu_scene.gd:213-246 | Gerbang `SisaKoran.boleh_lempar` di `_saat_tap_selesai` tidak dijaga untuk kasus tanpa sasaran. Mutan **Q13** (gerbang dibuang, sisa `not _mode_bantu or _jeda`) HIDUP: tap saat koran habis atau saat jeda antar lempar di tempat tanpa kotak surat terjangkau memunculkan tanda "tanpa sasaran" dan sinyal `bantu_tanpa_sasaran`, padahal D-6 dan BALANCING 4b menulis tap yang ditolak karena habis/jeda antar lempar tidak memberi tanda. Tes habis dan jeda antar lempar selalu menunggu ada sasaran dulu (`_tunggu_sasaran`), jadi `_lempar` yang menolak. Repro: terapkan Q13, `run_tests` 0 gagal. Saran: tes tap tanpa sasaran saat koran habis dan saat jeda antar lempar → tidak ada tanda, tidak ada sinyal. | VERIFIED | Hanya tes. `tests/tes_bantu_scene.gd`, commit `430c47a`: `_test_tanpa_sasaran_gerbang`. | Maju 5,2 santai (tanpa sasaran seberang): tap saat koran habis dan saat jeda antar lempar 0,1 detik = tidak ada tanda, tidak ada `bantu_tanpa_sasaran`, tidak ada lemparan, jeda tidak mulai ulang; kontrol: tap yang sama sesudah jeda lewat = tanda + satu sinyal. Mutan Q13 mati: 3 gagal. **QA iter 2:** Q13 mati (3); varian R7 (gerbang hanya `habis`, jeda antar lempar lolos ke tanda) mati (2); R8 sinyal `bantu_tanpa_sasaran` dibuang mati (5); R9 tanda di titik pijak sepeda mati (2). |
| QA-003 | 1 | Minor | scripts/entities/jalan_uji.gd:139-140 (`_bunyi_mendarat`); tests/tes_bunyi_lempar.gd:443-510 | Sakelar jendela yang diteruskan scene ke `Audio.putar_mendarat` tidak dijaga. Mutan **Q29** (`not Config.JENDELA_KENA_BONUS`) HIDUP: bunyi pendaratan di jendela menjadi teras ("sah") sementara penandanya silang (penalti bawaan), melanggar D-10 "bunyi selalu sejalan dengan penanda". Tes scene bunyi (16 swipe) tidak pernah mendarat di zona `JENDELA`. Repro: terapkan Q29, `run_tests` 0 gagal. Saran: satu lemparan scene yang mendarat di jendela dengan sakelar bawaan → berkas `sfx_land_miss_*`, dan cek berkas sejalan dengan `koran.antaran`/penanda koran itu. | VERIFIED | Hanya tes. `tests/tes_bunyi_lempar.gd`, commit `f801edf`: `_test_scene_jendela`. | Satu swipe di scene (kekuatan dan arah dari pembantu solver, diubah ke vektor layar lewat `Iso`; kontrol `lintasan_swipe` mendarat di zona jendela seberang rumah 1 x -3..-2,75 maju 5,5..6,25) -> koran dinilai JENDELA -> berkas bunyi = tabel oracle D-10 untuk (JENDELA, `Config.JENDELA_KENA_BONUS` yang dipakai game) (bawaan: `sfx_land_miss_01.wav`) dan sejalan dengan penanda koran itu (silang <-> meleset). Sakelar adalah `const`, jadi tes menjaga nilai yang sedang dipakai; oracle tabel mencakup kedua nilai. Mutan Q29 mati: 1 gagal. **QA iter 2:** Q29 mati (1); R10 sakelar dibalik di `Audio.putar_mendarat` mati (2). Oracle = `TABEL_PERMUKAAN` literal di tes; pembantu solver hanya menyusun swipe dan dikontrol dengan persegi jendela literal. |
| QA-004 | 1 | Nit | scripts/systems/bantu_lempar.gd:52; tests/tes_bantu.gd:312-352 | Batas "di depan" D-4 (maju pusat **≥** maju sepeda, inklusif) tidak dites: mutan **Q1** (`>=` jadi `>`) HIDUP. Kasus berukuran nol di jalan uji, jadi Nit; saran satu tes zona buatan dengan pusat tepat di maju sepeda → kandidat. Catatan visual (Nit, tanpa perubahan wajib): pada tangkapan `*_seberang_terbang` (Dev dan QA) koran hampir menempel di kotak surat karena sasaran terdekat di santai hanya sekitar 1 ubin di depan, jadi "koran bantu terbang" kurang terlihat; perilaku K-3, dinilai di HP (NEEDS-MANUAL). | VERIFIED | Hanya tes. `tests/tes_bantu.gd`, commit `22b228c`: tambahan di `_test_sasaran_tepi`. Catatan visual tetap NEEDS-MANUAL (butir checklist yang sudah ada). | Zona buatan dengan pusat tepat di maju sepeda 0,5 = kandidat dan dipilih saat sepeda berhenti (u 0,5/3,5, mendarat di pusat); pusat 0,4999 = bukan kandidat, `pilih` = null. Mutan Q1 mati: 2 gagal. **QA iter 2:** Q1 mati (2). |

## NEEDS-MANUAL (uji di HP)
- [ ] **Kotak surat dengan sengaja di santai, cepat, ngebut** (mode bantu mati): SETUP_ANDROID 8.5 butir 1, 10 lemparan per kecepatan, catat jumlah centang. Diharapkan sebagian besar kena di santai/cepat, ngebut masih bisa dikenai dengan garis bidik. Fase 2 dan M1 tidak dicentang sebelum ini.
- [ ] **Swipe pendek di layar kecil (GDD 17) dan responsif jeda 0,35 / 0,17 (K-4)**: butir 2 dan 5; ketukan tanpa mode bantu tidak boleh melempar.
- [ ] **Mode bantu, sisi tap**: nyalakan "Bantu: nyala", ketuk zona kanan jelas di atas garis jalan yang melewati sepeda lalu jelas di bawahnya, 5 kali per sisi di santai, lalu ulangi sambil ngebut (stick penuh ke atas). Diharapkan koran selalu ke kotak surat pelanggan terdekat di depan pada sisi itu dengan centang, termasuk saat ngebut (kebalikan QA-001 yang hanya dites di santai). Catat bila ada ketukan dekat garis yang terasa masuk sisi salah.
- [ ] **Mode bantu, lemparan sangat pendek di santai**: perhatikan apakah koran ke kotak surat yang hanya sekitar 1 ubin di depan masih terlihat terbang dan terasa wajar (QA-004 catatan visual).
- [ ] **Tanda tanpa sasaran**: ketuk sisi seberang tepat sesudah melewati kotak surat pelanggan dan di depan rumah bukan pelanggan (lingkaran bergaris). Diharapkan tidak ada koran terpakai, cincin pucat 9×9 px game sekitar 0,6 detik; nilai apakah terbaca di layar HP dan terasa adil bila ada kotak surat terlihat tetapi di luar jangkauan.
- [ ] **Mode bantu + kidal dan satu jempol**: butir 8 dan 9; satu menit hanya mengetuk, sepeda santai sendiri, stamina tidak turun; hitung berapa kali tombol "Bantu"/"Kidal" terpencet tak sengaja.
- [ ] **Bunyi di speaker HP**: butir 10; empat permukaan (tunk, plak, puk, plek) bisa dibedakan tanpa melihat dan terdengar di atas kayuhan; "wus" tidak berbunyi untuk lemparan ditolak.
- [ ] **Bunyi berhenti saat jeda dan background**: butir 11; tekan jeda tepat saat bunyi mendarat, lalu home saat koran di udara; tidak ada bunyi lama sesudah "Lanjut", koran beku mendarat sekali dengan satu bunyi baru.
- [ ] **GDD 17 (ambang rem)**: butir 12, konfirmasi masih nyaman sesudah lemparan dan mode bantu.

## Keputusan & catatan
- Keputusan pemilik 2026-10-15 (awal sesi): K-1 santai otomatis + stick opsional; K-2 sisi tap dari garis jalan di zona swipe; K-3 kotak surat pelanggan terdekat di depan, selalu kena, tanpa sasaran = tidak melempar; K-4 jeda 0,35/0,17 tetap. Rincian di SPEC.md.
- Hasil uji HP sebelumnya (run arah bebas, vivo V2108, 2026-10-15): "this is much better". Catatan rinci (kotak surat tiga kecepatan, swipe pendek, garis bidik saat melaju, responsif) belum diisi pemilik; dijadikan butir checklist AC-16.
- Perangkat: vivo V2108 (12d8c9da) tersambung di awal run; A54 tidak tersambung.

## Catatan Dev iterasi 1a

Bagian A dari dua pemanggilan Dev iterasi 1. Commit: `3cc2a77` (tes QA-008), `9192256` (logika murni mode bantu + config + BALANCING 4b), `c0fb888` (mode bantu di scene + HUD + terjemahan), `00954cd` (dokumen).

**Keputusan implementasi**
- **Tap (D-1)** di `TouchRouter`: `_maks_swipe_px` mencatat |v| terbesar dari titik awal (di `geser` dan di posisi `lepas`). Saat jari slot swipe diangkat, `swipe_selesai` tetap dipancarkan seperti dulu (jalan uji menolaknya karena pendek), lalu sinyal baru `tap_selesai(posisi = titik awal, durasi)` bila `not ThrowSolver.cukup_panjang(maks, lebar)` (ambang dan toleransi sama dengan swipe; tepat 6% = swipe). Tambahan: `jumlah_tap_selesai`, `panjang_swipe_maks()`. `batal`/`batal_semua` tidak pernah tap. Swipe dan tap saling eksklusif (tap ⇒ |v_lepas| < min ⇒ swipe ditolak), jadi tidak ada lemparan ganda.
- **Modul `BantuLempar`** (`scripts/systems/bantu_lempar.gd`): `sisi_tap(tap, posisi_sepeda_layar)` = `sisi_dari_arah(arah_tanah(tap − sepeda))`; tap tepat di titik pijak sepeda (vektor nol) = `DEKAT` (di garis), masukan tidak hingga = `TIDAK_ADA`. `pilih(sisi, posisi, v, v_lateral, jeda_lepas, lebar, daftar) -> Pilihan {zona, lintasan, kekuatan}`; `kandidat`, `cari_kekuatan` (bisection f(u) = |R(u)| − jarak(u), terjangkau bila f(0) ≥ 0 ≥ f(1); f turun tegas karena jarak naik 3,5/u sedangkan |R| berubah ≤ 1,8/u di ngebut), `arah_ke`, `jangkauan_maju_ubin`, `sisa_tanda`, `tanda_tampil`. Cek ulang: lintasan `ThrowSolver.hitung(panjang_untuk_kekuatan(u), …)` diterima hanya bila `ZonaSasaran.zona_kena(titik_mendarat, daftar) == zona` (lebih ketat dari "dinilai KOTAK_SURAT": zona yang menang harus kotak surat sasaran itu sendiri).
- **Tafsiran seri D-4** "lateral terkecil" = **selisih lateral pusat zona ke sepeda** terkecil (|x pusat − x sepeda|), lalu urutan daftar. Orchestrator/QA boleh menolak.
- **Satu sumber warisan kecepatan**: penjaga AC-4 Run 2A melarang `Config.LEMPAR_*` di luar `ThrowSolver`, jadi ditambahkan `ThrowSolver.geser_maju_ubin(v, u)` (dipakai juga oleh `hitung`, refaktor tanpa ubah angka) dan `ThrowSolver.panjang_untuk_kekuatan(u, lebar)` (kebalikan `kekuatan`). `BantuLempar` tidak memakai `Config.LEMPAR_*` (penjaga tetap hijau).
- **Daftar zona di scene**: `ZonaSasaran.zona_jalan_uji_rentang(maju, maju + jangkauan)` (baru) menggantikan `zona_jalan_uji_sekitar` yang SPEC sebut sebagai contoh, karena `sekitar` hanya mencakup ±1 kavling (4–8 ubin ke depan) sedangkan jangkauan lemparan sampai 10,5 ubin (ngebut); dengan `sekitar` kotak surat berikutnya sesudah rumah bukan pelanggan bisa tidak masuk daftar walau terjangkau.
- **Scene (`JalanUji`)**: `_saat_tap_selesai` → gerbang `mode bantu && !jeda && SisaKoran.boleh_lempar` → `pilihan_bantu(sisi_tap(posisi, posisi_layar_sepeda()))` → null = `KontrolTouch.tampilkan_tanda` + sinyal baru `bantu_tanpa_sasaran(posisi)`; ada = `_lempar(lintasan)`. `_lempar` dipakai bersama swipe dan tap (`SisaKoran.terima`, `KoranLempar.baru`, `_sepeda.lempar`, HUD, `koran_dilempar`). `posisi_layar_sepeda()` = posisi gambar sepeda − posisi kamera + setengah viewport (dites sama dengan transform kanvas sepeda). API publik baru: `atur_mode_bantu`, `mode_bantu`, `pilihan_bantu`, `posisi_layar_sepeda`.
- **Titik kait bagian B (bunyi)**: `koran_dilempar` tepat sekali per lemparan DITERIMA, swipe maupun tap (lemparan ditolak tidak memancarkannya); `koran_mendarat` tepat sekali per koran; `jeda_berubah` sudah ada. Didokumentasikan di kepala `jalan_uji.gd`.
- **Tanda D-6**: pola baru `PolaPiksel.TANDA_TANPA_SASARAN` (cincin 9×9, `w` = `TEXT_2`, garis luar `OUTLINE`; tidak ada token `MUTED` di Palette, jadi dipakai `TEXT_2`), digambar `KontrolTouch` (CanvasLayer, koordinat sentuhan) lewat `perintah_tanda()`; waktu `langkah_tanda(dt efektif)` dari `JalanUji.perbarui`, jadi membeku saat jeda.
- **Sakelar D-7**: `BarisTombol` (HBox) di `StripAtas` berisi `TombolKidal` lalu `TombolBantu` di tengah strip atas (tombol kidal bergeser 52 px ke kiri dari tengah; tes tata letak lama tetap hijau). Status terbaca dari teks `HUD_BANTU_MATI` "Bantu: mati" / `HUD_BANTU_NYALA` "Bantu: nyala" selain gaya ditekan. Sinyal `HudDev.bantu_diubah`, `atur_bantu`, `rect_tombol_bantu`.
- **K-1**: tidak ada kode baru; kecepatan otomatis = stick netral (santai 3,0, stamina +2/d), dites AC-6.
- **Angka baru di `config.gd`** (BALANCING 4b dan 2, commit yang sama): `BANTU_TOLERANSI_UBIN` 0,000001 (derau float di ujung u, jauh di bawah setengah lebar zona 0,25), `BANTU_CARI_ULANGAN` 48 (ketelitian u ~3,6e-15), `BANTU_TANDA_LAMA_DETIK` 0,6 (cukup terbaca, lebih pendek dari penanda 0,8 supaya tidak menumpuk saat tap berulang; usulan, dinilai di HP), `HUD_TOMBOL_JARAK_PX` 8.
- **QA-008 (AC-13)**: `tests/tes_koran_scene.gd` tidak lagi memanggil `GambarPiksel.perintah_pola`/`perintah_rentang`/`warna_huruf` sebagai oracle (`git grep` hanya menyisakan komentar). Oracle: tabel warna per huruf peran ditulis di tes (`_warna_peran`), pola dibaca per karakter, dibandingkan per piksel layar (`_peta_pola` vs `_peta_perintah`), plus titik uji eksplisit: ikon ke-3 alpha 1 dan ke-4 alpha 0,28 (`OUTLINE`/`TEXT`/`TEXT_2`), tiap piksel `w` penanda = `OK`/`FAIL` dan tiap `o` = `OUTLINE`, piksel `w` elips tertutup = `TEXT` alpha 0,5. Alpha 0,28 dan 0,5 ditulis literal dan `Config` dicek sama.

**Tes baru**: `tests/tes_bantu.gd` (murni: pembantu solver, tap ambang/tarik-kembali/dua jari/slot terisi/batal/kidal, sisi tap ~3300 titik × 5 posisi sepeda terhadap oracle garis layar 1:2, rentang zona, sasaran dasar/tepi, AC-4 grid 2880 keadaan: 5 kecepatan × 3 lateral × 3 kecepatan lateral × 2 sisi × 32 fase; 2846 bersasaran, 2870 dibandingkan dengan oracle keterjangkauan berangka BALANCING 4 literal, semua cocok; waktu tanda). `tests/tes_bantu_scene.gd` (AC-5 delapan skenario, AC-6, AC-7 di 640/780/800 kanan dan kidal). Jumlah tes 6082 → 6283.

**Tabel mutan** (dijalankan dengan skrip yang menerapkan satu mutan, menjalankan `run_tests`, menghitung `GAGAL:`, lalu mengembalikan isi berkas; `git diff` bersih dari mutan sesudahnya)

| Mutan | Berkas | Jumlah gagal |
|---|---|---|
| N16 `warna.a *= alpha` dibuang | `scripts/ui/gambar_piksel.gd` | 5 (mati) |
| N20 huruf `o` memakai warna utama | `scripts/ui/gambar_piksel.gd` | 33 (mati) |
| N21 huruf `w` dilewati | `scripts/ui/gambar_piksel.gd` | 26 (mati) |
| N22 alpha ditimpa 1 | `scripts/ui/gambar_piksel.gd` | 5 (mati) |
| M1 tap: ambang `<` jadi `<=` (`maks <= swipe_min_px`) | `touch_router.gd` | 7 |
| M2 tap: \|v\| maksimum jadi \|v\| akhir | `touch_router.gd` | 3 |
| M3 sisi tap: tanda dibalik | `bantu_lempar.gd` | 4 |
| M4 sisi tap: posisi sepeda diabaikan | `bantu_lempar.gd` | 4 |
| M5 sasaran: filter pelanggan dibuang | `bantu_lempar.gd` | 7 |
| M6 sasaran: filter "di depan" dibuang | `bantu_lempar.gd` | 3 |
| M7 sasaran: filter sisi dibuang | `bantu_lempar.gd` | 7 |
| M8 sasaran: pilih terjauh | `bantu_lempar.gd` | 4 |
| M9 sasaran: tanpa cek ulang `hitung`/`zona_kena` | `bantu_lempar.gd` | 2 |
| M10 sasaran: warisan kecepatan diabaikan di pencarian u | `bantu_lempar.gd` | 10 |
| S1 scene: gerbang jeda antar lempar dilewati untuk tap | `jalan_uji.gd` | 5 |
| S2 scene: sisa koran tidak dikurangi untuk tap (tanpa `terima`) | `jalan_uji.gd` | 11 |
| S3 scene: mode bantu diabaikan | `jalan_uji.gd` | 9 |
| S4 scene: kidal tidak dihormati (zona saat jari turun) | `touch_router.gd` | 19 |
| S5 scene: tanda tanpa sasaran tidak ditampilkan | `jalan_uji.gd` | 4 |
| S6 scene: tanda tidak pernah hilang | `jalan_uji.gd` | 1 |
| S7 scene: posisi layar sepeda tanpa kamera | `jalan_uji.gd` | 32 |
| S8 scene: gerbang jeda game dilewati untuk tap | `jalan_uji.gd` | 2 (awalnya 0: tes jeda game menap saat jeda antar lempar belum lewat; tes diperkuat menunggu 0,4 detik dulu, lalu mati) |

**Belum selesai / catatan**
- Bagian B (pemanggilan Dev berikutnya): bunyi lempar dan mendarat (D-9..D-13, AC-9..AC-12), `kontrol.html` dan DESIGN_SPEC 6 (AC-14), GDD 4.2 (AC-15), checklist `SETUP_ANDROID.md` 8 (AC-16), SOUND_DESIGN, `00-project-core.mdc`/`docs/README.md`, dan tangkapan layar AC-19 (tombol bantu mati/nyala, koran bantu, tanda tanpa sasaran, kidal + bantu). Pemeriksaan visual cepat lewat `probe_koran_jendela.gd` (di scratchpad, tidak di-commit): tombol "Kidal" dan "Bantu: mati" berdampingan di tengah strip atas, tidak menumpuk tombol jeda atau panel.
- Tidak ada BLOCKED.

## Catatan Dev iterasi 1b

Bagian B dari dua pemanggilan Dev iterasi 1. Commit: `a1ad445` (art: skrip sintesis + 13 WAV + `.import` + uji alat + CI), `b7ef274` (feat: `BunyiLempar`, `Audio`, `JalanUji`, config + BALANCING + SOUND_DESIGN + TECH_PLAN, tes), `1f2e286` (docs: kontrol.html + PNG + DESIGN_SPEC 0 + GDD 4.2), `5ec99ae` (docs: SETUP_ANDROID 8.5, DEV_PHASES Fase 3, AGENTS, 00-project-core, docs/README), `be6c945` (test: probe mode bantu + tangkapan).

**Keputusan implementasi**
- **Sintesis (D-9).** `tools/audio_art/sintesis_lempar.py`, stdlib, benih tetap `20261015`, laju 22050 Hz mono 16-bit (sama dengan sepeda). "Wus" = derau lewat lolos-pita dua kutub yang pusatnya 700 -> 2200 -> 700 Hz (setengah sinus), keras-pelan sin² (0,20 detik). Kotak surat = empat parsial tak harmonis (1 / 2,41 / 3,93 / 5,62) dari 520 / 600 / 690 Hz yang naik 12% dalam ~30 ms + ketukan resonator 3100 Hz. Teras = tamparan derau lolos-tinggi di pita 2600 / 3000 / 3500 Hz + 2 / 3 / 4 gemeresik + dentum badan 150–190 Hz. Rumput = derau lolos-bawah + dentum 105 / 122 / 140 Hz, serangan lunak 8 ms. Meleset = derau pita tengah 950 / 1150 / 1350 Hz + nada datar, puncak 0,5 (sekitar 5 dB di bawah 0,89 permukaan lain). Durasi: wus 0,20; kotak surat 0,17/0,20/0,23; teras 0,16/0,19/0,22; rumput 0,15/0,17/0,19; meleset 0,14/0,15/0,16. Serangan dan lepas setengah kosinus, jadi sampel pertama dan terakhir tepat nol. Total 13 WAV sekitar 105 KB.
- **`.import`**: Godot membuat `compress/mode=2` (QOA) dan `edit/loop_mode=0`; diubah ke `compress/mode=0` (PCM, sama persis dengan berkas) dan `edit/loop_mode=1` seperti decit rem, lalu diimpor ulang (hasil lama di `.godot/imported/` dihapus). Langkah ini dicatat di README alat.
- **Pemetaan (D-10)** di `scripts/systems/bunyi_lempar.gd` (`BunyiLempar.permukaan(hasil, jendela_bonus)`): jendela memakai `ZonaSasaran.status_antaran` dengan sakelar yang sama dengan penilaian koran, jadi bunyi selalu sejalan dengan penanda. Variasi: `berkas_mendarat(p, giliran)` + `giliran_berikut`, pencacah per permukaan disimpan `Audio` (`_giliran`), tanpa RNG. Acak nada ±5% (SOUND_DESIGN 2) tidak dipakai (D-10 meminta deterministik); dicatat di SOUND_DESIGN 3.1.
- **Pemutar (D-11)**: satu pemutar "wus" + satu pemutar per berkas mendarat (12), semuanya bus `SFX`, volume dari `Config` saat dibuat. Alasan satu pemutar per berkas: stream tidak pernah diganti saat berbunyi dan dua koran yang mendarat berdekatan di permukaan berbeda tidak saling memotong. Tidak ada bus baru (tes bus lama "hanya Master, SFX, Sepeda" tetap hijau).
- **Sambungan scene**: `JalanUji._ready` menyambungkan `koran_dilempar` -> `Audio.putar_lempar` dan `koran_mendarat` -> `Audio.putar_mendarat(koran.hasil, Config.JENDELA_KENA_BONUS)`; `_exit_tree` memanggil `hentikan_lempar`. Logika mode bantu bagian A tidak diubah; tidak ditemukan bug bagian A.
- **Jeda (D-12)**: `atur_jeda(true)`, `perbarui_sepeda(..., jeda = true)`, dan `_notification` (PAUSED, FOCUS_OUT, WM_CLOSE) menghentikan pemutar lempar/mendarat; selama `_jeda` `putar_*` tidak berbuat apa pun (giliran tidak maju). `stop()` (bukan pause), jadi sesudah lanjut tidak ada yang diputar ulang. `ProbeKeluar` dan runner tes juga memanggil `hentikan_lempar` sebelum keluar (mencegah playback bocor seperti kasus bunyi sepeda); penjaga teks ProbeKeluar di `run_tests.gd` ikut memeriksa `hentikan_lempar`.
- **API `Audio` baru**: `putar_lempar`, `putar_mendarat`, `hentikan_lempar`, `atur_ulang_lempar` (tes), `jumlah_wus`, `jumlah_mendarat`, `mendarat_terakhir`, `ada_bunyi_lempar`, `pemutar_wus`, `pemutar_mendarat(berkas)`. `ada_bunyi()` tetap hanya bunyi sepeda (tes lama). `Audio` tetap tidak merujuk autoload lain (tes teks lama hijau); ia merujuk `BunyiLempar` dan `ZonaSasaran` (class_name, bukan autoload).

**Angka baru** (`scripts/config.gd` + BALANCING 2 + SOUND_DESIGN 3.1, commit `b7ef274`): `AUDIO_WUS_VOLUME_DB` -4,0 (sedikit di atas kayuhan -6, di bawah mendarat); `AUDIO_MENDARAT_VOLUME_DB` -1,0 untuk keempat permukaan (di atas kayuhan, SOUND_DESIGN 6 "koran mendarat harus selalu terdengar di atas kayuhan"). Meleset lebih pelan lewat puncak berkasnya (D-9/D-13), jadi tidak ada konstanta volume meleset terpisah. Semua usulan, dinilai di speaker HP (SETUP_ANDROID 8.5 butir 10).

**Tes baru**: `tests/tes_bunyi_lempar.gd` (dipanggil runner sesudah `TesBunyi`): Config; tabel oracle 6 hasil x 2 sakelar; giliran tujuh langkah per permukaan dengan nama berkas literal; 13 berkas (format, `.import`, durasi D-9, puncak meleset < permukaan lain dari data stream); `Audio` tanpa tree (bus, volume, 12 pendaratan campuran dengan urutan berkas literal, jeda tanpa bunyi baru); pemutar sungguhan di driver Dummy (berbunyi, berhenti sendiri, jeda seketika, tidak diputar ulang, `perbarui_sepeda` jeda); notifikasi sendiri per instans; scene: wus untuk swipe dan tap diterima, tanpa wus untuk swipe pendek, jeda antar lempar, jeda game, mode bantu mati, tanpa sasaran, koran habis; mendarat tepat sekali (dua lemparan bantu = mailbox 01 lalu 02, 30 langkah sesudahnya tetap satu), 16 swipe ke 8 arah x 2 kekuatan dengan giliran dihitung oracle sendiri (mencakup meleset, rumput, kotak surat, bukan pelanggan); jeda saat wus dan saat bunyi mendarat, APPLICATION_PAUSED, scene dibuang. Jumlah tes 6283 -> 6445. `uji_sintesis_lempar.py`: 111 pemeriksaan termasuk kontrol contoh buruk (byte diubah, tepi berklik, variasi kembar, variasi berbeda panjang tetapi warna sama, impor numpy/scipy).

**Tabel mutan bunyi** (skrip di scratchpad menerapkan satu mutan, menjalankan `run_tests`, menghitung `GAGAL:`, mengembalikan berkas; `git diff` bersih sesudahnya)

| Mutan | Berkas | Jumlah gagal |
|---|---|---|
| B1 permukaan tertukar: teras -> rumput, halaman -> teras | `bunyi_lempar.gd` | 6 |
| B1b kotak surat -> teras | `bunyi_lempar.gd` | 10 |
| B1c jendela dibalik (bonus -> meleset) | `bunyi_lempar.gd` | 2 |
| B1d bukan pelanggan -> rumput | `bunyi_lempar.gd` | 4 |
| B2 variasi tidak bergiliran (`giliran_berikut` tidak maju) | `bunyi_lempar.gd` | 12 |
| B2b `Audio` tidak menyimpan giliran | `audio.gd` | 4 |
| B2c satu giliran bersama semua permukaan | `audio.gd` | 3 |
| B3a wus di awal `_saat_swipe_selesai` (juga untuk swipe ditolak) | `jalan_uji.gd` | 8 |
| B3b wus di awal `_saat_tap_selesai` (juga untuk tap ditolak) | `jalan_uji.gd` | 8 |
| B3c wus sebelum `SisaKoran.terima` (juga saat ditolak gerbang terakhir) | `jalan_uji.gd` | 7 |
| B4 bunyi mendarat dua kali per koran | `jalan_uji.gd` | 9 |
| B4b bunyi mendarat lagi tiap langkah sesudah mendarat | `jalan_uji.gd` | 5 |
| B5a `atur_jeda` tidak menghentikan pemutar lempar/mendarat | `audio.gd` | 5 |
| B5b `_notification` tidak menghentikan pemutar lempar/mendarat | `audio.gd` | 3 |
| B5c `perbarui_sepeda(jeda)` tidak menghentikan pemutar lempar/mendarat | `audio.gd` | 1 |
| B5d bunyi mendarat baru boleh selama jeda | `audio.gd` | 2 |
| B5e `_exit_tree` tidak menghentikan pemutar lempar/mendarat | `jalan_uji.gd` | 1 (awalnya 0: tap terakhir sebelum scene dibuang ditolak jeda antar lempar sehingga tidak ada bunyi; tes diperkuat menunggu jeda dan memastikan wus berbunyi dulu, lalu mati) |

**AC-14 (QA-005)**: render lama ternyata dibuat tanpa web font (font cadangan sans). Render HTML lama dengan Chrome headless + jaringan diblokir (`--host-resolver-rules="MAP * ~NOTFOUND"`) berukuran sama 1728x1560 dan berbeda 3,7% piksel papan / sekitar 1% piksel area gambar dari PNG lama (hanya antialias teks dan satu judul kartu yang tidak lagi terbungkus); dengan web font termuat tampilannya berubah (font Lexend/Lilita, tata letak bergeser), jadi tidak dipakai. `kontrol.png` lama = potongan papan di (64, 279) 1600x721 (selisih 0 piksel), jadi PNG baru dipotong dari tempat yang sama. Perintah lengkap di DESIGN_SPEC 0. Judul papan tetap dua baris supaya potongan tidak bergeser. `git grep -n "Swipe kiri" docs/design` kosong; DESIGN_SPEC 6 tidak perlu baris usang karena PNG dirender ulang. DESIGN_SPEC 3.4 "sama dengan arah stick dan swipe" diperjelas ke arah bebas.

**AC-19 tangkapan** (`docs/loop/20261015-fase2b-bantu-audio/shots/`, perintah `godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_bantu_jendela.gd -- docs/loop/20261015-fase2b-bantu-audio/shots`, keluaran tanpa ERROR/WARNING, "0 keadaan tidak sesuai"): `2340x1080_bantu_tombol_mati`, `_tombol_nyala`, `_seberang_terbang`, `_seberang_centang`, `_dekat_terbang`, `_dekat_centang`, `_tanpa_sasaran`, `_kidal_seberang_terbang`, `_kidal_seberang_centang`, `_kidal_dekat_terbang`, `_kidal_dekat_centang` (11 PNG, titik ketukan digambar probe dengan 4 titik `ACCENT`). Dilihat sendiri: tombol "Bantu: mati" lalu "Bantu: nyala" bergaris `ACCENT` di samping "Kidal"; koran bantu dan bayangannya terbang ke kotak surat dekat; centang hijau di atas kotak surat seberang dan dekat; cincin tanda tanpa sasaran di titik ketukan; kidal: panel pindah, ketukan di zona kiri melempar ke seberang dan dekat. **`tools/cek_blok_piksel.py 3`** dengan kotak teks HUD yang dicetak probe (`--kecualikan` tombol kidal, tombol bantu, panel kecepatan, panel koran; set kidal terpisah): 11/11 berkas **0 blok tidak seragam** (257478 blok, 23322 dikecualikan, sisa tepi 0).

**Catatan untuk QA / uji HP (bukan perubahan desain)**
- Pada sepeda santai di awal jalan uji, kotak surat pelanggan terdekat di depan sering hanya sekitar 1 ubin di depan sepeda, jadi koran bantu terbang pendek dan rendah (`_seberang_terbang` memperlihatkan koran sudah dekat kotak surat di pertengahan terbang). Ini perilaku K-3 (terdekat di depan).
- Di `_tanpa_sasaran` titik ketukan jatuh tepat di samping kotak surat seberang rumah 3 yang terlihat tetapi di luar jangkauan santai (maju 13,125 dari sepeda di 5,2). Tanda tanpa sasaran di sebelah kotak surat yang terlihat bisa membingungkan; dimasukkan ke butir 7 checklist 8.5 ("terasa adil?").
- Teks tombol yang dibaca probe adalah kunci (`HUD_BANTU_NYALA`); di layar tampil terjemahan "Bantu: nyala" (dilihat di tangkapan).

**Belum selesai / BLOCKED**: tidak ada BLOCKED. Uji HP (SETUP_ANDROID 8.5) menunggu pemilik; `DEV_PHASES` Fase 2 tidak dicentang Dev.

## Catatan QA iterasi 1

Auditor: Agent 2 (QA), 2026-10-15, HEAD `3417c9c` di `feat/mode-bantu-bunyi-lempar`, Godot 4.7.2.stable (`/opt/homebrew/bin/godot`). Semua klaim Dev di atas diperlakukan sebagai daftar yang diuji ulang, bukan bukti.

**Tahap 1: gerbang objektif (dijalankan QA sendiri)**

| Perintah | Hasil |
|---|---|
| `godot --headless --import` | 0 baris ERROR/WARNING (satu baris `cannot connect to daemon at tcp:5037` dari adb, bukan Godot) |
| `godot --headless --script res://tests/run_tests.gd > build/qa_tests.log 2>&1` | exit 0, `6445 lolos, 0 gagal` (sekitar 14 detik) |
| `python3 tools/cek_keluaran_tes.py build/qa_tests.log` dan `--ketat` | keduanya `pemeriksa: lolos (6445 lolos, 0 gagal, 0 peringatan)` |
| `godot --headless --path . --quit-after 2` | 0 ERROR/WARNING |
| `uji_pemeriksa.py`, `uji_bangun_frames.py`, `uji_sintesis_sepeda.py`, `uji_sintesis_lempar.py` | exit 0 semua: 16 kasus 0 menyimpang; 41 lolos; 32 lolos; 111 lolos |
| `godot --headless --path . --export-pack "Android" build/qa.pck` | paket 612 KB; daftar path dari `strings`: tidak ada `tests/`, `docs/`, `probe`, `cek_render`; 13 WAV throw + `.sample` impornya, `bantu_lempar.gdc`, `bunyi_lempar.gdc` ada |
| Klon bersih (`git clone -b feat/mode-bantu-bunyi-lempar` ke scratchpad, lalu import + tes + `--ketat` + `--quit-after 2`) | import bersih, `6445 lolos, 0 gagal`, pemeriksa lolos, 0 ERROR/WARNING |
| Kebersihan repo | diff tanpa `.godot/`, `build/`, APK, keystore, kredensial; `main` = `origin/main` (`08e3f62`), tidak ada commit di `main`; 12 commit `<tipe>: ...` bahasa Indonesia dengan baris `Claude-Session`; `.uid` untuk tiap `.gd` baru dan `.import` untuk tiap WAV baru ada |
| WAV (analisis QA sendiri dengan `wave`) | 13 berkas 22050 Hz mono 16-bit (sama dengan sepeda); durasi wus 0,20, kotak surat 0,17/0,20/0,23, teras 0,16/0,19/0,22, rumput 0,15/0,17/0,19, meleset 0,14/0,15/0,16 (dalam rentang D-9); puncak meleset 0,50 lawan 0,89, RMS meleset −24..−26 dBFS lawan −15..−21 permukaan lain; sampel pertama dan terakhir tepat 0 |

Gerbang: **hijau**.

**Tahap 2: kepatuhan SPEC (ringkas)**
- AC-1/AC-2/AC-3: dites murni di `tests/tes_bantu.gd` (ambang min−0,01/min, tarik-kembali, dua jari, slot terisi, batal, kidal; sisi tap lawan oracle garis 1:2; sasaran pelanggan, belakang, sisi, null). Mutan QA Q8, Q16-Q18 mati.
- AC-4/AC-8: grid 2880 keadaan memeriksa lintasan = `ThrowSolver.hitung` dan `KOTAK_SURAT`; `git grep` titik mendarat/`LEMPAR_*` di luar `throw_solver.gd` hanya menemukan `config.gd`. `BantuLempar` memakai `titik_lepas`, `jarak_ubin`, `geser_maju_ubin` lalu cek ulang `zona_kena`. Mutan Q2-Q7 mati. **Celah**: kabel scene ke `pilih` (QA-001).
- D-1 lemparan ganda: swipe dan tap saling eksklusif (tap ⇒ \|v_lepas\| < min ⇒ swipe ditolak di `_saat_swipe_selesai`); urutan sinyal ditukar (Q19) tidak mengubah apa pun, jadi memang tidak ada lemparan ganda.
- AC-5/AC-6/AC-7: ada; tombol bantu di luar zona stick/swipe di 640/780/800 kanan dan kidal, teks lewat kunci. Celah gerbang tanpa sasaran (QA-002).
- AC-9..AC-12: ada; Audio tetap tidak merujuk autoload lain; bus `SFX`; jeda/notifikasi menghentikan pemutar (Q22-Q26, Q28 mati). Celah sakelar jendela di scene (QA-003).
- AC-13: QA menerapkan sendiri N16, N20, N21, N22 di `scripts/ui/gambar_piksel.gd`: **semuanya mati** (5, 34, 27, 5 gagal). `tests/tes_koran_scene.gd` tidak lagi memanggil `perintah_pola`/`warna_huruf` sebagai oracle (hanya komentar).
- AC-14/AC-15: `git grep -i "swipe kiri\|kiri = seberang\|kanan = dekat" docs/design` kosong; GDD 4.2 "mengarah ke"; satu-satunya sisa di GDD 5.2 adalah kalimat sejarah ("Sebelumnya hanya swipe kiri...").
- AC-16/AC-17: SETUP_ANDROID 8.5 lengkap (12 butir + lembar hasil); GDD 5.3, BALANCING 2/4b/10, SOUND_DESIGN 3.1/4.2/6/8, TECH_PLAN, DESIGN_SPEC 0/3.4/3.7, DEV_PHASES Fase 3, AGENTS, 00-project-core, docs/README diperbarui dan konsisten satu sama lain (angka 0,6 detik, −4/−1 dB, 96×42/8 px sama di config dan dokumen); semua ditandai usulan; DEV_PHASES Fase 2 "Mode bantu" dan "Uji di HP" **tidak** dicentang. Keputusan terbuka ROADMAP 5 (kerusakan di mode bantu, jendela) tidak diputuskan.

**Tahap 3: review kode terhadap rule** — static typing lengkap di kode baru; angka baru di `config.gd` satu baris literal dan sama dengan BALANCING; logika murni di `scripts/systems/`; tidak ada `kiri`/`kanan` untuk sisi jalan di kode (hanya zona input di tes); tidak ada hex baru (warna dari `Palette`); teks pemain lewat `HUD_BANTU_*`; Audio berhenti saat PAUSED/FOCUS_OUT/WM_CLOSE. Tidak ada temuan rule selain celah tes di atas.

**Tahap 4: mutan QA** (`scratchpad/mutan.py`: satu penggantian teks, `run_tests`, hitung `GAGAL:`/SCRIPT ERROR, berkas dikembalikan; `git status` bersih sesudahnya). Berbeda dari tabel mutan Dev.

| Mutan | Berkas | Hasil |
|---|---|---|
| N16 / N20 / N21 / N22 (QA-008) | `scripts/ui/gambar_piksel.gd` | mati: 5 / 34 / 27 / 5 gagal |
| Q1 di depan `>=` jadi `>` | `bantu_lempar.gd` | **HIDUP** (QA-004) |
| Q2 syarat terjangkau atas dilonggarkan (f(1) > 0,5) | `bantu_lempar.gd` | mati (2) |
| Q3 arah bisection dibalik | `bantu_lempar.gd` | mati (65) |
| Q4 `arah_ke` memakai u = 0 | `bantu_lempar.gd` | mati (2) |
| Q5 seri lateral dibalik | `bantu_lempar.gd` | mati (1) |
| Q6 kecepatan lateral diabaikan di titik lepas pencarian | `bantu_lempar.gd` | mati (2) |
| Q7 jeda lepas diabaikan di titik lepas pencarian | `bantu_lempar.gd` | mati (64) |
| Q8 tap tepat di titik pijak = SEBERANG | `bantu_lempar.gd` | mati (1) |
| Q9 daftar zona scene = `zona_jalan_uji_sekitar` | `jalan_uji.gd` | **HIDUP** (QA-001) |
| Q10 kecepatan scene = santai tetap | `jalan_uji.gd` | **HIDUP** (QA-001) |
| Q11 kecepatan lateral scene = 0 | `jalan_uji.gd` | **HIDUP** (QA-001) |
| Q12 jeda lepas scene = 0 | `jalan_uji.gd` | **HIDUP** (QA-001) |
| Q13 gerbang `boleh_lempar` tap dibuang | `jalan_uji.gd` | **HIDUP** (QA-002) |
| Q14 tanda dimajukan `dt` mentah (tidak beku saat jeda) | `jalan_uji.gd` | mati (1) |
| Q15 `atur_mode_bantu` tidak menyamakan tombol | `jalan_uji.gd` | mati (3) |
| Q16 `batal` memancarkan tap | `touch_router.gd` | mati (3) |
| Q17 posisi tap = titik akhir | `touch_router.gd` | mati (1) |
| Q18 posisi lepas tidak dihitung ke \|v\| maksimum | `touch_router.gd` | mati (1) |
| Q19 tap dipancarkan sebelum `swipe_selesai` | `touch_router.gd` | hidup, setara (tidak ada perilaku berubah; bukan temuan) |
| Q20 jendela selalu teras | `bunyi_lempar.gd` | mati (2) |
| Q21 giliran 01, 03, 02 | `bunyi_lempar.gd` | mati (12) |
| Q22 `putar_lempar` tidak menolak saat jeda | `audio.gd` | mati (1) |
| Q23 FOCUS_OUT/WM_CLOSE tidak menghentikan pemutar lempar | `audio.gd` | mati (2) |
| Q24 jeda = `stream_paused`, lanjut memutar ulang bunyi lama | `audio.gd` | mati (3 + 1 error) |
| Q25 bus lempar = `Sepeda` | `audio.gd` | mati (2) |
| Q26 wus memakai volume mendarat | `audio.gd` | mati (1) |
| Q27 teks status tombol bantu tertukar | `hud_dev.gd` | mati (12) |
| Q28 giliran tidak di-reset `atur_ulang_lempar` | `audio.gd` | mati (3) |
| Q29 sakelar jendela dibalik di `_bunyi_mendarat` | `jalan_uji.gd` | **HIDUP** (QA-003) |
| Q30 `zona_jalan_uji_rentang` tanpa kavling cadangan akhir | `zona_sasaran.gd` | mati (2) |

Ringkas: 34 mutan, 27 mati, 1 setara (Q19), 6 hidup bermakna (Q1, Q9-Q13, Q29). Skrip repro dampak Q9 (`scratchpad/repro_q9.gd`, tidak di-commit): 34 dari 384 keadaan berbeda sasaran.

**Tahap 5: validasi visual (jendela asli, non-headless).** Tangkapan Dev di `shots/` dilihat (tombol mati/nyala, seberang/dekat terbang dan centang, tanpa sasaran, kidal). QA mengambil ulang lewat `godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_bantu_jendela.gd -- docs/loop/20261015-fase2b-bantu-audio/shots/iter1-qa`: exit 0, 0 ERROR/WARNING, "0 keadaan tidak sesuai", 11 PNG di `shots/iter1-qa/`. Pengambilan pertama kebetulan menangkap layar jeda di `dekat_terbang` karena jendela kehilangan fokus di mesin QA (perilaku benar: FOCUS_OUT = jeda; probe melanjutkan lewat `minta_lanjut`), jadi probe dijalankan ulang. `tools/cek_blok_piksel.py 3` dengan `--kecualikan` kotak teks HUD dari probe (set kidal terpisah): **11/11 berkas 0 blok tidak seragam** (257478 blok, 23322 dikecualikan, sisa tepi 0). Dilihat: "Kidal" dan "Bantu: mati/nyala" berdampingan di tengah strip atas, tidak menumpuk tombol jeda atau panel, status terbaca dari teks dan garis `ACCENT`; centang di atas kotak surat seberang dan dekat; cincin tanda tanpa sasaran di titik ketukan; kidal: panel pindah, ketukan zona kiri melempar ke seberang dan dekat. Catatan: di `*_seberang_terbang` koran sudah hampir di kotak surat yang hanya sekitar 1 ubin di depan (QA-004, NEEDS-MANUAL).

**Tahap 6: regresi** — `git diff main...HEAD -- tests/` tidak menghapus atau melewati tes lama; `tes_koran_scene.gd` hanya mengganti oracle (QA-008) dan menambah; jumlah tes 6082 (main) → 6445. Tes lama bunyi sepeda, tata letak, dan export tetap hijau.

**Verdict iterasi 1: FAIL** — gerbang hijau, tetapi QA-001 (Major) OPEN. Minor QA-002, QA-003 dan Nit QA-004 boleh dikerjakan bersama atau DEFERRED dengan catatan.
- Orchestrator 2026-10-15: QA iterasi 1 FAIL (Major 1: QA-001; Minor 2: QA-002, QA-003; Nit 1: QA-004; tidak ada Blocker di tabel, angka "1 Blocker" di laporan QA salah tulis). Lanjut iterasi 2: Dev memperbaiki QA-001 sampai QA-004.

## Catatan Dev iterasi 2

Hanya temuan OPEN QA-001..QA-004. Commit: `430c47a` (test: QA-001 + QA-002, `tests/tes_bantu_scene.gd`), `f801edf` (test: QA-003, `tests/tes_bunyi_lempar.gd`), `22b228c` (test: QA-004, `tests/tes_bantu.gd`). Tidak ada perubahan kode game, config, BALANCING, atau dokumen desain: keempat temuan adalah celah penjaga, dan perilaku kode sudah benar menurut review QA. Teks yang menjadi pola mutan QA di `jalan_uji.gd` dan `bantu_lempar.gd` tidak berubah, jadi mutan diterapkan persis seperti `mutan.json` QA.

**QA-001 (kabel scene ke `BantuLempar.pilih`).** Tiga tes scene baru; tidak satu pun memakai `JalanUji.pilihan_bantu` sebagai harapan. Keadaan sepeda ditaruh tanpa memajukan waktu (`_taruh_sepeda`: kecepatan, lateral, maju, lalu `perbarui(0)`, lalu kecepatan lateral efektif langkah terakhir diisi karena langkah ber-dt 0 menolkannya; koran penuh), lalu tap sungguhan lewat `Input.parse_input_event` sehingga jalurnya `TouchRouter.tap_selesai` -> `_saat_tap_selesai` -> `pilihan_bantu` -> `_lempar`.
- `_test_kabel_literal`: 7 kasus dengan rumah dan pusat kotak surat sasaran ditulis eksplisit (dari config `JALAN_UJI_*_KOTAK_SURAT_UBIN` dihitung tangan): santai maju 5,75 / 6,5 / 7,5 seberang -> rumah 3 (-1,625; 13,125) (keadaan yang gagal dengan `zona_jalan_uji_sekitar`); cepat 4,5 vl -2 maju 6,5 seberang -> rumah 3; ngebut 6,0 vl +2 maju 6 seberang -> rumah 3; ngebut lateral 0,5 vl -2,4 maju 2 dekat -> rumah 1 (1,625; 5,125); cepat lateral -0,5 vl +2,4 maju 9,5 dekat -> rumah 3 dekat. Diperiksa: tap melempar tanpa tanda, titik mendarat di pusat kotak surat itu (±0,001), titik lepas = (lateral + vl x 2/12, -(maju + v x 2/12)) ditulis di tes (±1e-6), lintasan mewarisi v dan jeda lepas 2/12. Satu koran (santai maju 6 seberang) diterbangkan sampai dinilai KOTAK_SURAT centang di kavling 3.
- `_test_kabel_kisi` (dipanggil untuk v 3,0, 4,5, 6,0): kecepatan lateral 0 / +2 / -2 x maju 0..15,75 tiap 0,25 x 2 sisi = 384 tap per kecepatan. Oracle = `BantuLempar.pilih` dipanggil tes dengan posisi (0, -maju), v, vl, jeda lepas 2/12 literal, lebar 780, dan zona `zona_jalan_uji_rentang(maju - 4, maju + 16)` (lebih jauh dari jangkauan ngebut 10,5, jadi tidak bergantung pada `jangkauan_maju_ubin` di scene). Bersasaran: titik mendarat dan titik lepas = oracle dan titik lepas = rumus literal; tanpa sasaran: tidak ada lemparan, tanda tampil, satu `bantu_tanpa_sasaran`. Kontrol: semua titik tap di zona swipe dan di sisi oracle garis 1:2; kisi mencakup keadaan bersasaran dan tanpa sasaran; kisi santai mencakup keadaan di mana daftar ±1 kavling memberi sasaran lain.
- `_test_kabel_stick`: stick sungguhan (jari 0 di zona stick) cepat (awal 4,5, stick (25, -25)) dan ngebut (awal 6,0, stick (-15, -35)) sambil berbelok, tap jari 1 ke seberang dan dekat. Besaran dibaca langsung dari sepeda sesudah langkah; kecepatan lateral diukur sendiri = (lateral sesudah - lateral sebelum) / dt langkah itu (bukan `SepedaUji.lateral_ud`). Lintasan = oracle `pilih` dari besaran itu, titik lepas = rumus literal. Tap terjadi pada v 4,55 vl 2,12 dan v 5,97 vl -1,18.

**QA-002.** `_test_tanpa_sasaran_gerbang`: maju 5,2 santai (kontrol: tanpa sasaran seberang); tap seberang saat koran 0 (jeda lewat) lalu saat koran 30 dengan jeda antar lempar 0,1 detik: tidak ada tanda, tidak ada `bantu_tanpa_sasaran`, tidak ada lemparan, `sejak_lempar_detik` tetap 0,1. Kontrol: tap yang sama sesudah jeda lewat = tanda + satu sinyal.

**QA-003.** `_test_scene_jendela` (di `TesBunyiLempar`, sesudah `_test_scene_mendarat`): sepeda santai maju 2 lateral 0; kekuatan dan arah ke pusat jendela seberang rumah 1 (-2,875; 5,875) dari `BantuLempar.cari_kekuatan`/`arah_ke`, diubah ke vektor swipe layar lewat `Iso.dunia_ke_layar` dan `ThrowSolver.panjang_untuk_kekuatan`; kontrol `JalanUji.lintasan_swipe` mendarat di persegi jendela literal. Swipe turun-naik tanpa langkah di antaranya, koran dinilai JENDELA, bunyi = `FOLDER + sfx_land_<nama>_01.wav` dengan nama dari tabel oracle D-10 (`TABEL_PERMUKAAN`) untuk (JENDELA, `Config.JENDELA_KENA_BONUS`), dan bunyi sejalan dengan penanda koran itu (silang <-> meleset); dengan sakelar bawaan: penanda silang, `sfx_land_miss_01.wav`. `JENDELA_KENA_BONUS` adalah `const`, jadi satu jalankan hanya bisa menjaga nilai yang dipakai game; oracle menangani kedua nilai, dan sakelar dibalik di scene (Q29) selalu gagal karena bunyinya lalu tidak sejalan dengan penilaian.

**QA-004.** Di `_test_sasaran_tepi`: zona buatan pusat (-2,0; 0,5) dengan sepeda di maju 0,5 = kandidat; pusat 0,4999 = bukan kandidat; sepeda berhenti (titik lepas = posisi) memilih zona sejajar dengan u 0,5/3,5 dan mendarat di pusatnya; zona sedikit di belakang -> `pilih` null. Catatan visual QA-004 (koran bantu sangat pendek di santai) tetap NEEDS-MANUAL lewat butir checklist yang sudah ada; tidak ada perubahan desain.

Jumlah tes 6445 -> 6522.

**Tabel mutan QA iterasi 2** (`scratchpad/mutan.py` + `mutan.json` milik QA, tanpa perubahan pola: satu penggantian teks, `run_tests`, hitung `GAGAL:`/SCRIPT ERROR, berkas dikembalikan; `git status` bersih sesudahnya, hanya berkas tes yang berubah sebelum commit)

| Mutan | Berkas | Iterasi 1 | Iterasi 2 (jumlah gagal) | Tes yang membunuh |
|---|---|---|---|---|
| Q1 di depan `>=` jadi `>` | `bantu_lempar.gd` | HIDUP | mati, 2 | `_test_sasaran_tepi` (kandidat sejajar, pilih saat berhenti) |
| Q9 daftar zona scene = `zona_jalan_uji_sekitar` | `jalan_uji.gd` | HIDUP | mati, 11 | literal santai/cepat/ngebut seberang rumah 3 (8), kisi v 3,0/4,5/6,0 (salah 56/69/79 keadaan) |
| Q10 kecepatan scene = santai tetap | `jalan_uji.gd` | HIDUP | mati, 18 | literal cepat/ngebut (titik lepas, kecepatan lintasan), kisi v 4,5/6,0 (salah 382/384), stick 4 kasus x 2 |
| Q11 kecepatan lateral scene = 0 | `jalan_uji.gd` | HIDUP | mati, 16 | literal vl != 0 (titik lepas, sasaran), kisi 3 kecepatan (salah 252-256), stick 4 kasus x 2 |
| Q12 jeda lepas scene = 0 | `jalan_uji.gd` | HIDUP | mati, 32 | literal semua kasus, kisi 3 kecepatan (salah 377-384), stick 4 kasus x 2 |
| Q13 gerbang `boleh_lempar` tap dibuang | `jalan_uji.gd` | HIDUP | mati, 3 | `_test_tanpa_sasaran_gerbang` (habis, jeda antar lempar, kontrol) |
| Q29 sakelar jendela dibalik di `_bunyi_mendarat` | `jalan_uji.gd` | HIDUP | mati, 1 | `_test_scene_jendela` (dapat `sfx_land_porch_01.wav`, harap `sfx_land_miss_01.wav`) |

**Gerbang (dijalankan sendiri, HEAD kode `22b228c`)**: `godot --headless --import` 0 ERROR/WARNING; `run_tests` 6522 lolos, 0 gagal; `cek_keluaran_tes.py` dan `--ketat`: lolos (6522 lolos, 0 gagal, 0 peringatan); `--quit-after 2` 0 ERROR/WARNING; `uji_pemeriksa` 16 kasus 0 menyimpang; `uji_bangun_frames` 41 lolos; `uji_sintesis_sepeda` 32 lolos; `uji_sintesis_lempar` 111 lolos.

**Tidak ada DISPUTED atau BLOCKED.**

## Catatan QA iterasi 2

Auditor: Agent 2 (QA), 2026-10-15, HEAD `62b3ee6` di `feat/mode-bantu-bunyi-lempar`, Godot 4.7.2.stable. Klaim Dev iterasi 2 diuji ulang, bukan diterima.

**Gerbang objektif (dijalankan QA sendiri)**

| Perintah | Hasil |
|---|---|
| `godot --headless --import` | 0 baris ERROR/WARNING |
| `godot --headless --script res://tests/run_tests.gd > build/qa2_tests.log 2>&1` | exit 0, `6522 lolos, 0 gagal` |
| `cek_keluaran_tes.py` dan `--ketat` | keduanya `pemeriksa: lolos (6522 lolos, 0 gagal, 0 peringatan)` |
| `godot --headless --path . --quit-after 2` | 0 ERROR/WARNING |
| `uji_pemeriksa.py`, `uji_bangun_frames.py`, `uji_sintesis_sepeda.py`, `uji_sintesis_lempar.py` | exit 0 semua: 16 kasus 0 menyimpang; 41 lolos; 32 lolos; 111 lolos |
| `--export-pack "Android" build/qa2.pck` | exit 0, 612 KB; `strings`: 0 path `tests/`, `docs/`, `probe`, `cek_render`; `bantu_lempar.gdc`, `bunyi_lempar.gdc`, 13 WAV throw/land ada |
| Klon bersih (`git clone -b feat/mode-bantu-bunyi-lempar` ke scratchpad, HEAD `62b3ee6`, lalu import + tes + `--ketat` + `--quit-after 2`) | import bersih, `6522 lolos, 0 gagal`, pemeriksa `--ketat` lolos, 0 ERROR/WARNING |
| Kebersihan repo | `git diff 5088d94..HEAD` hanya `tests/tes_bantu.gd`, `tests/tes_bantu_scene.gd`, `tests/tes_bunyi_lempar.gd` (hanya tambahan) dan LOG; `scripts/`, `scenes/`, `assets/` tidak berubah sejak iterasi 1; tanpa `.godot/`, `build/`, APK, keystore, kredensial; `main` = `origin/main` (`08e3f62`), tidak ada commit di `main`; 5 commit iterasi 2 berformat `<tipe>: ...` bahasa Indonesia dengan body "kenapa" dan baris `Claude-Session` |

Gerbang: **hijau**.

**Verifikasi temuan FIXED.** Ketujuh mutan iterasi 1 diterapkan ulang QA dengan penggantian teks persis seperti deskripsi di tabel QA iterasi 1 (harness QA `scratchpad/qa2/mutan.py`: satu penggantian, `run_tests`, hitung `GAGAL:`/SCRIPT ERROR, berkas dikembalikan; `git status` bersih sesudahnya). Semua kini mati. Oracle tes baru diperiksa satu per satu: `_test_kabel_literal` menulis rumah, pusat kotak surat, dan titik lepas (rumus BALANCING 4, jeda lepas 2/12 literal) di tes; `_test_kabel_kisi` dan `_test_kabel_stick` membandingkan dengan `BantuLempar.pilih` (fungsi murni yang sendiri dijaga oracle literal di `tes_bantu.gd`) yang dipanggil dengan masukan dari tes (posisi, kecepatan, kecepatan lateral terukur dari perpindahan, daftar -4..+16 ubin), bukan dengan `JalanUji.pilihan_bantu`; `pilihan_bantu` hanya muncul sebagai kontrol keadaan (maju 5,2 tanpa sasaran) di `_test_tanpa_sasaran_gerbang`. `_test_scene_jendela` memakai tabel `TABEL_PERMUKAAN` literal sebagai oracle bunyi; pembantu solver hanya menyusun vektor swipe, dan pendaratan di persegi jendela literal dicek sebagai kontrol. QA-001..QA-004 → **VERIFIED**.

**Tabel mutan QA iterasi 2** (Q = mutan iterasi 1 diulang, R = mutan baru di kode yang dijaga tes iterasi 2)

| Mutan | Berkas | Hasil |
|---|---|---|
| Q1 di depan `>=` jadi `>` | `bantu_lempar.gd` | mati (2) |
| Q9 daftar zona scene = `zona_jalan_uji_sekitar` | `jalan_uji.gd` | mati (11) |
| Q10 kecepatan scene = santai tetap | `jalan_uji.gd` | mati (18) |
| Q11 kecepatan lateral scene = 0 | `jalan_uji.gd` | mati (16) |
| Q12 jeda lepas scene = 0 | `jalan_uji.gd` | mati (32) |
| Q13 gerbang `boleh_lempar` tap dibuang | `jalan_uji.gd` | mati (3) |
| Q29 sakelar jendela dibalik di `_bunyi_mendarat` | `jalan_uji.gd` | mati (1) |
| R1 jangkauan daftar zona dari kecepatan santai tetap | `jalan_uji.gd` | hidup, **setara**: `zona_jalan_uji_rentang` selalu menambah satu kavling cadangan (4 ubin) sesudah kavling ujung, jadi daftar selalu mencapai lebih dari maju + 7,75 + 4 > maju + 10,5 (jangkauan ngebut); perilaku tidak berubah, bukan temuan |
| R1b daftar zona hanya sampai maju + 2 ubin | `jalan_uji.gd` | mati (11) |
| R2 daftar zona mulai maju + 4 | `jalan_uji.gd` | mati (1) |
| R3 posisi lateral sepeda diabaikan di `pilihan_bantu` | `jalan_uji.gd` | mati (11) |
| R4 tanda kecepatan lateral dibalik | `jalan_uji.gd` | mati (16) |
| R5 lebar viewport tetap 640 di `pilih` | `jalan_uji.gd` | mati (1) |
| R6 jeda lepas selalu sisi DEKAT | `jalan_uji.gd` | hidup, **setara**: semua animasi lempar lepas di frame 2 pada 12 fps, jadi jeda lepas kedua sisi sama 2/12 (dijaga `tes_sprite.gd`); bukan temuan |
| R7 gerbang tap hanya `habis` (jeda antar lempar tidak menahan tanda) | `jalan_uji.gd` | mati (2) |
| R8 sinyal `bantu_tanpa_sasaran` tidak dipancarkan | `jalan_uji.gd` | mati (5) |
| R9 tanda di titik pijak sepeda, bukan titik tap | `jalan_uji.gd` | mati (2) |
| R10 `Audio.putar_mendarat` membalik sakelar jendela | `audio.gd` | mati (2) |
| R11 maju daftar zona dari sumbu lateral | `jalan_uji.gd` | mati (16) |

Ringkas: 19 mutan, 17 mati, 2 setara (R1, R6), 0 hidup bermakna.

**Regresi dan review rule.** Tidak ada tes lama yang dihapus atau dilewati (diff tes hanya tambahan; 6445 → 6522). Kode tes baru bertipe statis, label bahasa Indonesia dengan rujukan D-x, angka harapan literal dengan alasan di komentar, tidak ada `kiri`/`kanan` untuk sisi jalan, waktu deterministik (langkah `DT` tetap, tanpa RNG). Tidak ada perubahan kode game, config, BALANCING, atau scene, jadi rule gdscript/balancing/ui-scenes tidak tersentuh. Tidak ada temuan baru.

**Validasi visual (jendela asli, non-headless).** Kode scene tidak berubah sejak iterasi 1; probe tetap dijalankan sebagai cek regresi: `godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_bantu_jendela.gd -- docs/loop/20261015-fase2b-bantu-audio/shots/iter2-qa`: exit 0, 0 ERROR/WARNING, "0 keadaan tidak sesuai", 11 PNG di `shots/iter2-qa/` (pengambilan pertama gagal menyimpan karena folder belum ada; probe tidak membuat folder sendiri, jadi dibuat lalu diulang). `tools/cek_blok_piksel.py 3` dengan `--kecualikan` kotak teks HUD dari probe (set kidal terpisah): **11/11 berkas 0 blok tidak seragam** (257478 blok, 23322 dikecualikan, sisa tepi 0). Dilihat lewat lembar kontak: tidak ada layar jeda tertangkap; tombol "Kidal" dan "Bantu: mati/nyala" berdampingan, centang di kotak surat seberang dan dekat, cincin tanda tanpa sasaran, kidal memindah panel. Sama dengan iterasi 1.

**NEEDS-MANUAL** tidak berubah (daftar di atas tetap berlaku; Fase 2 dan M1 tidak boleh dicentang sebelum uji HP SETUP_ANDROID 8.5).

**Verdict iterasi 2: PASS** — semua gerbang hijau; QA-001 (Major), QA-002 dan QA-003 (Minor), QA-004 (Nit) VERIFIED; tidak ada temuan baru; tidak ada Blocker/Major berstatus OPEN/FIXED/DISPUTED. Jumlah temuan per severity: Blocker 0, Major 1 (VERIFIED), Minor 2 (VERIFIED), Nit 1 (VERIFIED).
- Orchestrator 2026-10-15: QA iterasi 2 PASS → status PASSED. Orchestrator mengulang `run_tests` di HEAD `0512fbc`: 6522 lolos, 0 gagal, `--ketat` lolos; `uji_sintesis_lempar` 111 lolos. APK debug `builds/kring-kring-debug.apk` (28,8 MB) dibangun tanpa ERROR/WARNING; isi: 13 WAV `throw/`, tanpa `tests/`/`docs/`. Pemasangan ke vivo V2108 tertunda: `adb devices` kosong saat dicek (HP tidak tersambung); A54 juga tidak tersambung.
