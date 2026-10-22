# Loop Log — 20261022-fase5c-animasi-simpang
Scope: Run 5C, Fase 5, verifikasi animasi pemain PR #51 (jatuh/terjerembab lima arah, bangkit, berhenti), pose kucing ditangkap, ujung kerb jalan masuk (C-F1), simpang T hiasan; hanya tampilan dan data segmen  ·  Branch: feat/fase5c-animasi-simpang  ·  Mulai: 2026-10-22  ·  Godot: 4.7.2

## Status: IN_PROGRESS   (iterasi saat ini: 1/2)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 1 (AB) | Bagian A (AC-1..AC-8) dan B (AC-9..AC-11), bagian A/B dari AC-23/24/27; lihat "Iterasi 1, bagian AB (Dev)" | hijau: import 0 ERROR/WARNING, 18420 lolos 0 gagal, pemeriksa lolos, `--quit-after 2` bersih, 12 `uji_*.py` exit 0 | - | A-F1 Minor FIXED, A-F2 Major FIXED, A-F3 Nit, A-F4 Nit, B-F1 Nit, I2-F3 diukur ulang (DEFERRED) | - |

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|
| A-F1 | 1 (Dev) | Minor | `scripts/entities/loper_sprite.gd` `atur_jatuh(false)` -> `_terapkan_animasi` | Saat bangun, animasi kayuh (4 frame) mewarisi indeks frame `bangkit_<arah>` (frame 5) yang dijepit Godot ke frame 3: frame terakhir bangkit (= santai frame 0) disusul **santai frame 3**, lompatan piksel tiap tabrakan. Reproduksi di `main` b69fc1f: `steer = 1; atur_jatuh(true, 1.15); atur_jatuh(false, 0)` -> `santai_serong_kanan f3 p0.50`. | FIXED | `loper_sprite.gd`: animasi pose dimulai frame 0 progres 0 saat bangun; commit 18f7d15 | `tes_animasi_5c.gd` `_test_pijak_urutan_per_arah` (urutan berakhir `santai_<arah>:0`), `_test_bangkit_ke_kayuh_piksel` (0 piksel beda, kontrol frame 3 berbeda), scene `_test_scene_jatuh_arah_ditahan`; mutan A13 |
| A-F2 | 1 (Dev) | Major | `scripts/entities/sepeda_uji.gd` `gerak` | Jatuh lima arah PR #51 praktis tidak pernah tampil di game: `SepedaUji.gerak` mengganti `steer` tiap langkah dari `BikeMotion`, yang melapor arah 0 selama sepeda dibekukan (kecepatan 0, lateral 0), jadi `jatuh_<arah>` hanya tampil pada langkah tabrakan lalu berganti ke `jatuh_normal`/`terjerembab_normal`/`bangkit_normal`. Reproduksi di `main`: `steer = 2; atur_jatuh(true, 0); steer = 0; atur_jatuh(true, 0.1)` -> `jatuh_normal f1`; di scene (stick ke seberang, tabrakan anjing di lateral -1,46) langkah kedua jatuh sudah `jatuh_normal`. | FIXED | `sepeda_uji.gd`: `steer` tidak diganti selama `sprite.sedang_jatuh()` (langkah bangun juga, jadi frame bangun = `santai_<arah jatuh>` f0); commit 18f7d15 (baris tambahan di `atur_ulang` dibuang di a167770: ekuivalen, mutan A15) | `_test_scene_jatuh_arah_ditahan` (normal dan serong kiri: jatuh 0-3, terjerembab, bangkit 0-5, santai 0 semua ke arah tabrakan), `_test_scene_main_lagi_saat_jatuh`; mutan A14 |
| A-F3 | 1 (Dev) | Nit | AC-6, `MissionManager` syarat tangkap (tidak diubah) | Syarat tangkap (kecepatan <= `MISI_TANGKAP_KECEPATAN_MAKS_UD` 1,5 selama `lama_berhenti_detik` 1,5) bisa terpenuhi **tanpa pose BERHENTI**: rem diketuk berulang (lepas di <= 0,4 u/d, tekan lagi di >= 1,3) menjaga 0,333 <= v <= 1,5 selama 19,6 detik dengan pose REM/KAYUH saja. Satu siklus rem sampai 0 lalu dilepas: 0,833 detik di bawah ambang (REM 0,300, BERHENTI 0,033, KAYUH 0,500), belum cukup sendiri. Tanpa rem sama sekali tidak bisa (stick -0,89 = tujuan 1,665 u/d). Skrip: `dev_ukur/ukur_nit.gd`. Pose berhenti tampil bila pemain menahan rem sampai diam (dites, AC-6). | OPEN (Nit, dilaporkan; syarat dan gerak tidak diubah sesuai SPEC) | - | `_test_scene_berhenti_tangkap` (jalur rem sampai diam = BERHENTI, progres berjalan) |
| A-F4 | 1 (Dev) | Nit | `SepedaUji` sesudah bangun | Langkah bangun memakai arah jatuh (piksel-identik dengan frame terakhir bangkit); langkah berikutnya arah kembali dari gerak, jadi bila stick masih ditahan ke samping sprite berganti arah satu langkah sesudah bangun (contoh probe: `santai_serong_kiri` f0 lalu `santai_kiri`). Pijak tetap; ini perubahan arah biasa dari gerak, bukan lompatan pijak. Dicatat untuk penilaian di HP (SETUP_ANDROID 8.14 butir 2). | NEEDS-MANUAL | - | - |
| B-F1 | 1 (Dev) | Nit | `probe_misi_jendela.gd` titik tahan tangkap (sepeda 1,2 ubin sebelum kucing, lateral -1) | Di titik tahan probe lama kepala dan badan pemain menutup sebagian besar kucing (kucing lateral -2 digambar di belakang pemain menurut Y-sort), jadi pose ditangkap hanya terlihat telinganya (`shots/iter1/*_misi_tangkap_progres*.png`). Saat berhenti lebih jauh (rem dari 2,9 ubin, berhenti sekitar 1,6 ubin sebelum kucing) kucing duduk dielus terlihat utuh (`*_animasi_berhenti_tangkap_kucing.png`). Keterbacaan = NEEDS-MANUAL (SETUP_ANDROID 8.14 butir 5); geometri tangkap tidak diubah. | NEEDS-MANUAL | - | - |
| I2-F3 | 1 (Dev ukur ulang) | Nit | pose jatuh/terjerembab/bangkit (sel 140x88) lawan dekor | Lihat bagian "AC-7" di Iterasi 1 bagian AB: 5 dari 44 kombinasi dekor x rintangan sesegmen punya piksel opak dekor di atas pose jatuh yang tidak ditutup kotak penutup (maks 89 sampai 284 piksel per kombinasi), pose berkendara 0 di semua kombinasi. Perbaikan butuh kotak penutup lebih besar (mengubah kapan dekor memudar saat berkendara), jadi bukan "satu konstanta tanpa efek ke pose berkendara". | DEFERRED | - | `dev_ukur/ukur_i2f3.gd` |

## Baseline (orchestrator, `main` b69fc1f, 2026-10-22)
- `godot --headless --import`: 0 baris ERROR/WARNING.
- `run_tests.gd`: **18318 lolos, 0 gagal**; `tools/cek_keluaran_tes.py`: lolos (18318 lolos, 0 gagal, 0 peringatan).
- 12 `tools/tests_cek/uji_*.py` exit 0: uji_aset_gelombang1, uji_aset_kucing, uji_aset_lampu_pohon, uji_aset_pasang_5b, uji_aset_pasang_gelombang1, uji_bangun_frames, uji_pemeriksa, uji_sintesis_{kondisi,lempar,misi,rute,sepeda}.
- sha256 `user://save.json` asli: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e`.
- HP: `adb devices` kosong (tidak ada HP tersambung).

## NEEDS-MANUAL (uji di HP)
Lihat SPEC bagian NEEDS-MANUAL dan SETUP_ANDROID 8.14.

## Keputusan & catatan
- Putusan P-1..P-5 dan D-1..D-4: SPEC.
- Bagian 6i LOOP-DEV-QA ada di branch `docs/perintah-run-5c` (belum di-merge); run ini hanya menyentuh tabel 6g.

## Iterasi 1, bagian AB (Dev)

Dikerjakan: AC-1 sampai AC-11 dan bagian A/B dari AC-23, AC-24, AC-27 (SPEC D-1). Bagian C, D, E tidak disentuh. Tidak ada BLOCKED.

### AC-1 Baseline (Dev, sebelum perubahan apa pun, branch di 260f020 = `main` b69fc1f + SPEC/LOG)
- `godot --headless --import`: 0 baris ERROR/WARNING. `godot --headless --path . --quit-after 2`: 0 baris ERROR/WARNING (belum diukur orchestrator).
- `run_tests.gd`: **18318 lolos, 0 gagal**; pemeriksa lolos (0 peringatan). 12 `tools/tests_cek/uji_*.py` exit 0. sha256 save asli = `37d6d6cb...549e`.
- Catatan lingkungan: sejak awal sesi ada proses `godot --headless --script res://tests/run_tests.gd` (pid 26665, berjalan sekitar 22 jam, CPU hampir 0) yang bukan dari sesi Dev ini; tidak dimatikan. Semua proses Godot Dev dijalankan satu per satu.

**Perubahan tes lama yang dibawa PR #51 (`git show b69fc1f -- tests/ tools/tests_cek/`), satu per satu:**
1. `tests/run_tests.gd` `_test_nama_animasi_dan_frames`: 50 -> 68 nama dan animasi; pose `BERHENTI` ditambah ke putaran pose; `nama_bangkit` ditambah. Alasan: 18 animasi baru (10 jatuh/terjerembab lima arah menggantikan 2, 5 bangkit, 5 berhenti).
2. `tests/tes_gerak.gd` `_test_lateral`: `rem_kanan` -> `berhenti_kanan` dan `rem_normal` -> `berhenti_normal` (dua cek berhenti dengan rem di kecepatan 0). Alasan: pose BERHENTI baru.
3. `tests/tes_gerak.gd` `_test_pose`: `pose_dari_gerak(true, -1, 0, 1,5)` REM -> BERHENTI; cek baru batas toleransi (0,05 inklusif, di atasnya REM, NaN REM). Alasan sama.
4. `tests/tes_gerak.gd` `_test_pose_dari_langkah`: kasus "rem berhenti (3 detik)" `rem_normal` -> `berhenti_normal`.
5. `tests/tes_gerak_scene.gd` `_test_rem_di_scene`: `rem_normal` -> `berhenti_normal` (rem ditahan sampai 0 u/d).
6. `tests/tes_input_murni.gd` `_test_stick_ke_animasi` 10c: `rem_normal` -> `berhenti_normal`.
7. `tests/tes_kondisi_gerak.gd` `SIDIK_EMAS_GERAK` 885da896... -> 7c18cdf8.... **Diverifikasi Dev** (`dev_ukur/cek_sidik.gd`): 33 dari 500 hasil berpose BERHENTI; bila BERHENTI dipetakan ke REM sidiknya kembali tepat `885da896ef96fd6f01d014fd034076ce86a39707ae82ff491e9ee2a187ac4404`, jadi nilai gerak lain tidak berubah (`pedal_rate` BERHENTI = REM = 1).
8. `tests/tes_misi_scene.gd`: label dan `hframes` 7 -> 9 kolom sheet kucing. Alasan: sheet 9 kolom (ditangkap_1/_2).
9. `tests/tes_rintangan.gd` `_test_frame_jatuh`: nama harapan per arah (dulu semua `_normal`), NaN = `jatuh_serong_kanan` untuk arah 1, cek nama per arah dan jepit, kasus bangkit baru. Alasan: jatuh lima arah dan bangkit.
10. `tests/tes_rintangan_scene.gd` `_test_tabrakan_dari_scene`: pada 1,183 detik `terjerembab_normal` -> `bangkit_normal` frame 5. Alasan: bangkit di 0,6 detik terakhir jatuh.
11. `tests/tes_sprite.gd`: `JUMLAH_ANIMASI` 50 -> 68; `JATUH_*` (sel 114x68, pijak 57,51) diganti `SHEET_5C` (jatuh/bangkit sel 140x88 pijak 70,61; berhenti 46x58 pijak 23,46); `_test_aset_jatuh` -> `_test_aset_5c` (+ cek bangkit frame 5 = santai frame 0 piksel); `_test_loper_sprite_jatuh` 6 -> 8 saat per arah dengan bangkit, `jatuh_normal` -> `jatuh_kanan`.
12. `tools/tests_cek/uji_aset_kucing.py`: columns 7 -> 9, cek baru kolom 7-8 ditangkap 3 fps.
13. `tools/tests_cek/uji_bangun_frames.py`: 50 -> 68 animasi, jumlah berkas 13 -> 17, hitungan loop/fps/AtlasTexture, region sel 140x88, kasus sumber rusak bangkit/berhenti.

**Perubahan tes lama oleh Dev run ini:** tidak ada angka tes lama yang diubah. Yang disentuh: `tests/run_tests.gd` (hanya mendaftarkan `TesAnimasi5c` dan `TesKucingDitangkap`) dan `tests/probe_misi_jendela.gd` (diperluas AC-11: `_cek_pose_ditangkap` dan bagian 10 kidal; pemeriksaan lama tidak diubah; satu baris komentar header diperpanjang).

### Perubahan kode
- `scripts/entities/loper_sprite.gd` (A-F1): bangun memulai animasi pose dari frame 0 progres 0.
- `scripts/entities/sepeda_uji.gd` (A-F2): `steer` tidak diganti selama sprite jatuh.
- `scripts/systems/pose_kucing.gd` baru (`PoseKucing.ditangkap/kolom/frame`), `scripts/entities/kucing_misi.gd` memasang `_badan.frame = PoseKucing.frame(titik.jenis, progres, detik)` tiap `tampilkan`. `KucingHiasan` **tidak diubah** (kilau, ekor dari kode, bar progres tetap; ekor kode tetap tampil di atas pose ditangkap bila petunjuk visual `ekor` aktif, dinilai di HP).
- `scripts/config.gd`: `MISI_KUCING_KOLOM_DITANGKAP: Array[int] = [7, 8]`, `MISI_KUCING_DITANGKAP_FPS: float = 3.0` (satu baris literal, dijaga tes = JSON).
- `bangun_frames.py` dan PNG tidak diubah: AC-2 terpenuhi aset PR #51 (offset `(0, -17)` - sel/2 + pijak = 0 untuk sel 46x58 pijak 23,46 dan 140x88 pijak 70,61).

### Bukti per AC
- **AC-2** `tes_animasi_5c.gd`: `_test_pijak_semua_animasi` (262 frame dari 68 animasi: pijak dunia = titik asal node dan ukuran frame = `cell` JSON; oracle tabel awalan -> JSON ditulis ulang di tes), `_test_pijak_urutan_per_arah` (lima arah, 73 langkah 60 fps: santai f3 -> jatuh 0-3 -> terjerembab 0 -> bangkit 0-5 -> santai f0, pijak tetap; rem -> berhenti -> kayuh), `_test_scene_jatuh_arah_ditahan` (rute nyata, arah normal dan serong kiri: pijak = posisi sepeda tiap langkah, urutan semua ke arah tabrakan).
- **AC-3** `_test_bangkit_ke_kayuh_piksel` (lima arah: 0 piksel beda antara `bangkit_<arah>` f5 dan frame sesudah bangun di koordinat dunia; kontrol santai f3 berbeda) dan langkah bangun di scene (0 piksel beda). Uji aset lama di `tes_sprite.gd` tetap.
- **AC-4** `_test_celah_frame_jatuh`, `_test_celah_pose_berhenti`: batas 0,6 tepat dan `0,6 - toleransi` persis = bangkit f0, `0,6 - 2 x toleransi` = terjerembab; tabel bangkit (f5 ditahan progres 0 dari 1,2); 72 langkah = jatuh 24 / terjerembab 12 (0,2 detik) / bangkit 36; `maxf` (total 0,5); jepit arah -3/7 untuk jatuh, terjerembab, bangkit, berhenti; NaN/negatif/INF = jatuh f0; tanpa bangkit = perilaku lama; BERHENTI 0,05 inklusif, 0,0500001 REM, NaN REM, -0,001 BERHENTI, tanpa rem tidak pernah BERHENTI (196 kombinasi).
- **AC-5** `_test_scene_lama_jatuh_tanpa_bangkit` (SpriteFrames dengan vs tanpa animasi bangkit: 150 langkah jatuh_detik, kebal_detik, alfa kedip, sedang_jatuh, kecepatan, jarak identik; bangun langkah 72, kebal habis langkah 132), `_test_lempar_dari_berhenti` (10 kasus: `lempar_<sisi>_santai_<arah lempar>` walau tingkat ngebut), `_test_scene_jeda_bangkit` (120 langkah jeda: animasi, frame, progres, jatuh_detik tetap; lanjut tanpa lompatan; bangun tetap 72 langkah efektif), `_test_scene_main_lagi_saat_jatuh` (Main lagi di langkah 10/30/60 jatuh serong kiri: `santai_normal` f0 diputar, tanpa animasi jatuh langkah berikutnya). `Tabrakan` tidak berubah (`git diff main` kosong) dan tes lama tabrakan lulus tanpa diubah.
- **AC-6** `_test_scene_berhenti_tangkap` (misi P1 hari 1, menepi lateral -1, rem penuh sampai 0: pose BERHENTI `berhenti_*`, langkah tangkap aktif, timer > 0). Temuan Nit A-F3 dengan angka. Tangkapan `*_animasi_berhenti_tangkap_kucing.png`.
- **AC-7** I2-F3 diukur ulang (`dev_ukur/ukur_i2f3.gd`, memakai `UkurPenutupPiksel` run 5B dengan topeng gabungan semua frame `loper_agen_jatuh` + `loper_agen_bangkit` sel 140x88, pijak dari JSON; posisi tabrakan = sisi rintangan lateral 0..2 langkah 1/16, maju pos-1,5..pos+3,5 langkah 1/16; hanya posisi dengan dekor di atas pemain menurut Y-sort dan kotak penutup `PenutupPemain.dari_dekor` TIDAK menutupi). 44 kombinasi dekor x rintangan sesegmen di 9 segmen, 5 bertumpuk:

  | Segmen | Dekor | Rintangan | Posisi tak tertutup (pose jatuh) | Piksel maks | Pose berkendara |
  |---|---|---|---|---|---|
  | per_tengah_01 | pohon dekat@19 | anjing seberang@22 | 23 | 89 (lat 0, maju 20,5) | 0 |
  | per_tengah_02 | lampu dekat@24 | mobil seberang@25 | 433 | 231 (lat 0, maju 24,5) | 0 |
  | per_tengah_03 | pohon dekat@11 | mobil seberang@9 | 150 | 276 (lat 0, maju 12,375) | 0 |
  | per_tengah_04 | pohon dekat@9 | anjing seberang@8 | 181 | 220 (lat 0, maju 10,0) | 0 |
  | per_tengah_05 | pohon dekat@8 | mobil seberang@9 | 310 | 284 (lat 0, maju 9,25) | 0 |

  `per_tengah_04` lampu dekat@23 lawan mobil seberang@17 dan anjing dekat@28: 0. Semua terburuk di lateral 0 (pemain jatuh di garis tengah, sprite rebah melebar ke sisi dekat). Pose berkendara 0 di semua kombinasi (oracle P-6 tetap 0). Perbaikan perlu kotak penutup dekor lebih lebar/tinggi, yang mengubah kapan dekor memudar saat berkendara, jadi tidak memenuhi syarat "satu konstanta tanpa efek ke pose berkendara": **tetap DEFERRED**.
- **AC-8** `tests/probe_animasi_pemain_jendela.gd` di 2340x1080, 1920x1080, 2400x1080, 1600x720: masing-masing **0 keadaan tidak sesuai**, 0 baris ERROR/WARNING, 31 tangkapan per ukuran (`shots/iter1/<ukuran>_animasi_*.png`): tabrakan nyata normal dan serong kiri (jatuh, terjerembab, bangkit tengah/akhir, bangun), lima arah x (jatuh, terjerembab, bangkit), rem bergerak, berhenti, berhenti lalu kayuh, berhenti di titik tangkap kucing, kidal jatuh dan bangkit. Dev melihat sendiri: `2340x1080_animasi_tabrak_serong_kiri_jatuh`, `..._bangkit_akhir` vs `..._bangun` (sama kecuali ikon kilatan), `2340x1080_animasi_berhenti_tangkap_kucing` (kaki kanan turun, kucing duduk dengan bar progres dan kilau), `1600x720_animasi_arah_kanan_terjerembab` (pemain rebah ke kanan di jalan, tidak menumpuk panel HUD).
- **AC-9/AC-10** `tes_kucing_ditangkap.gd`: 22 kasus literal (`frame` 9/16/17: progres 0/1e-9/1, t 0,3333 / 1/3 / 0,5 / 2/3 / 1 / 10, NaN, -2, -0,2, langkah lihat/kosong/kabur/petunjuk/"Tangkap"), 100 langkah 1/60 dijumlahkan = frame kedua (toleransi), urutan 2 detik 16,17,16,17,16,17; JSON `columns` 9 = `MISI_KUCING_KOLOM`, `frames[7..8]` = `anim.ditangkap` = `MISI_KUCING_KOLOM_DITANGKAP` [7, 8], `fps.ditangkap` 3 = `MISI_KUCING_DITANGKAP_FPS`; baris "masuk" piksel opak terbawah duduk/ditangkap_1/ditangkap_2 sama; scene: langkah lihat selalu duduk (240 langkah), progres 0 duduk, 60 langkah diam = ditangkap iff timer > 0, berganti tiap 20 langkah, posisi/offset/kotak badan tetap, kilau sama, bar progres tetap; jeda 90 langkah + 0,34 detik waktu dinding = frame dan timer tetap. Tes misi lama tidak diubah dan lulus; `uji_aset_kucing.py` lulus.
- **AC-11** `probe_misi_jendela.gd` di empat ukuran: **0 keadaan tidak sesuai**; tangkapan baru `*_misi_tangkap_progres_frame2.png`, `*_misi_kidal_tangkap_progres.png`, `*_misi_kidal_tangkap_progres_frame2.png` (frame 17 -> 16 dan 16 -> 17, posisi dunia dan offset badan tetap). Lihat B-F1 tentang keterbacaan di titik tahan probe lama.

### Mutan nyata (AC-27 bagian A/B)
Tiap mutan: satu perubahan di kode/aset asli, `run_tests.gd` penuh + `cek_keluaran_tes.py`, lalu `git checkout -- <berkas>`; `git status` sesudahnya hanya LOG dan `dev_ukur/` (belum dikomit). Skrip: `dev_ukur/mutan.py` (`python3 .../mutan.py [kode...]`).

| Kode | Berkas | Perubahan | Hasil (lolos/gagal) | Tes yang gagal (contoh) |
|---|---|---|---|---|
| A1 | loper_anim.gd | batas mulai bangkit `>=` jadi `>` | 18419/1 MATI | "0,6 - toleransi persis ... = bangkit frame 0 (batas >=)" (kasus ditambah 59f06ed sesudah A1 hidup di percobaan pertama tanpa kasus itu) |
| A2 | loper_anim.gd | toleransi batas bangkit dibuang | 18418/2 MATI | "0,6 - 0,5 toleransi = bangkit frame 0" |
| A3 | loper_anim.gd | `maxf(..., lama_jatuh)` dibuang | 18417/3 MATI | "total 0,5: 0,39 masih jatuh"; tes lama `tes_rintangan` |
| A4 | loper_anim.gd | frame terakhir bangkit tidak ditahan (`posmod`) | 18408/12 MATI | tabel bangkit (1,2 dan 3,0 = f0), urutan per arah |
| A5 | loper_anim.gd | arah bangkit tidak dijepit (`NAMA_ARAH.get(arah, "normal")`) | 18418/2 MATI | "nama per arah ... dijepit"; jepit -3/7 |
| A6 | loper_anim.gd | bangkit selalu arah 0 | 18396/20 MATI | "LoperAnim menghasilkan tepat 68 nama ... dapat 64"; urutan per arah |
| A7 | loper_anim.gd | BERHENTI tanpa rem (`if rem_aktif or kecepatan_ud == 0.0`) | 18410/10 MATI | sidik emas gerak, "tanpa rem tidak pernah BERHENTI" |
| A8 | loper_anim.gd | BERHENTI `<=` jadi `<` | 18418/2 MATI | "rem, 0,05 = BERHENTI (inklusif)" |
| A9 | loper_anim.gd | NaN = BERHENTI | 18418/2 MATI | "rem, NaN = REM" |
| A10 | loper_anim.gd | lempar dari BERHENTI memakai tingkat kayuh | 18418/2 MATI | "BERHENTI: lempar tingkat santai"; 10 kasus lempar |
| A11 | loper_agen.tscn | offset pijak `(0, -17)` jadi `(0, -16)` | 18401/19 MATI | pijak 262 frame, urutan per arah, tes lama offset |
| A12 | loper_agen_frames.tres | region `bangkit_kiri` f5 bergeser 1 px | 18418/2 MATI | `tes_sprite` region; AC-3 piksel arah kiri |
| A13 | loper_sprite.gd | fix A-F1 dilepas (`set_frame_and_progress(0, 0)` jadi `pass`) | 18403/17 MATI | urutan per arah (`santai_kiri:3`), piksel bangkit -> kayuh |
| A14 | sepeda_uji.gd | fix A-F2 dilepas (`if not _sprite.sedang_jatuh()` jadi `if true`) | 18419/1 MATI | "serong_kiri: ... urutan animasi" |
| A15 | sepeda_uji.gd | baris `atur_jatuh(false)` di `atur_ulang` dibuang | 18420/0 HIDUP -> ekuivalen | Tes Main lagi lulus tanpanya (jalur Main lagi sudah keluar dari jatuh dengan arah awal); baris dibuang di a167770, mutan ditarik |
| B1 | pose_kucing.gd | ditangkap saat progres 0 (`>= 0`) | 18417/3 MATI | 22 kasus literal (p0 = 16/17) |
| B2 | pose_kucing.gd | ditangkap di langkah lain (syarat jenis dibuang) | 18419/1 MATI | kasus `lihat`, kosong, `kabur` |
| B3 | config.gd | `MISI_KUCING_DITANGKAP_FPS` 3,0 jadi 4,0 | 18416/4 MATI | literal t 0,3333/0,5, JSON fps = konstanta |
| B4 | config.gd | kolom ditangkap [7, 8] jadi [6, 7] (kolom 6 kaget) | 18414/6 MATI | literal 16/17, JSON frames 7-8 |
| B5 | pose_kucing.gd | toleransi batas 1/3 detik dibuang | 18419/1 MATI (ulang sesudah a167770; percobaan pertama HIDUP) | "100 langkah 1/60 dijumlahkan = frame kedua" |
| B6 | kucing_misi.gd | pose dari waktu dinding (`detik + Time.get_ticks_usec() x 1e-6`), tidak membeku saat jeda | 18418/2 MATI (ulang; percobaan pertama hanya mati oleh cek angka ajaib) | "berganti tiap 20 langkah (3 fps), jarak [19, 20]"; jeda + 0,34 detik waktu dinding |
| B7 | kucing_misi.gd | KucingMisi tidak memakai PoseKucing | 18418/2 MATI | "60 langkah diam: frame ditangkap iff progres > 0" |
| B8 | pose_kucing.gd | waktu negatif tidak dibersihkan | 18419/1 MATI (ulang; percobaan pertama HIDUP) | kasus t -0,2 |

22 mutan mati (A1-A14, B1-B8), 1 ditarik sebagai ekuivalen (A15). Tiga mutan hidup di percobaan pertama (A1 sebelum kasus batas persis ditulis, B5, B8) dan satu hanya mati oleh cek gaya (B6) menunjukkan tes yang lemah; tes diperketat (59f06ed, a167770) lalu mutannya diulang dan mati.

### Gerbang akhir bagian AB (HEAD a167770 + LOG)
- `godot --headless --import`: 0 baris ERROR/WARNING.
- `godot --headless --script res://tests/run_tests.gd 2>&1 | tee build/tests.log`: **18420 lolos, 0 gagal** (18318 + 102 cek baru); `python3 tools/cek_keluaran_tes.py build/tests.log`: lolos (0 peringatan).
- `godot --headless --path . --quit-after 2`: 0 baris ERROR/WARNING.
- 12 `tools/tests_cek/uji_*.py` exit 0 (termasuk `uji_bangun_frames.py` 62 lolos, `uji_aset_kucing.py` 13 lolos).
- Probe: `probe_animasi_pemain_jendela.gd` dan `probe_misi_jendela.gd` di empat ukuran, 0 keadaan tidak sesuai, 0 ERROR/WARNING.
- `git diff main` kosong untuk `throw_solver`, `skor_rute`, `zona_sasaran`, `tenggat_rute`, `bike_motion`, `tabrakan`, `rintangan_rute`, `mission_manager`, `rencana_misi`, `bike_condition`, `economy`, `data_save`, `jalan_daur`.
- sha256 `user://save.json` asli sebelum dan sesudah semua tes, probe, dan mutan: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e`.
- Rule (AC-24 bagian A/B): static typing, `##` bahasa Indonesia, angka baru hanya di `config.gd` (cek gaya kode runner lolos), tanpa hex, tanpa teks pemain baru, `.uid` dikomit, tanpa PNG renderer diedit, tidak ada tekstur baru dimuat (sheet kucing sudah dimuat scene).

### Commit bagian AB
105677c (feat B), 18f7d15 (fix A-F1/A-F2 + tes A), 425f28a (probe animasi + tangkapan), 2a2186e (probe misi AC-11), 59f06ed (tes batas), a167770 (tes kucing diperketat, baris ekuivalen dibuang), commit LOG ini. Tidak di-push.
