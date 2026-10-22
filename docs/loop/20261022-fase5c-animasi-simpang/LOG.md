# Loop Log — 20261022-fase5c-animasi-simpang
Scope: Run 5C, Fase 5, verifikasi animasi pemain PR #51 (jatuh/terjerembab lima arah, bangkit, berhenti), pose kucing ditangkap, ujung kerb jalan masuk (C-F1), simpang T hiasan; hanya tampilan dan data segmen  ·  Branch: feat/fase5c-animasi-simpang  ·  Mulai: 2026-10-22  ·  Godot: 4.7.2

## Status: IN_PROGRESS   (iterasi saat ini: 1/2)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 1 (AB) | Bagian A (AC-1..AC-8) dan B (AC-9..AC-11), bagian A/B dari AC-23/24/27; lihat "Iterasi 1, bagian AB (Dev)" | hijau: import 0 ERROR/WARNING, 18420 lolos 0 gagal, pemeriksa lolos, `--quit-after 2` bersih, 12 `uji_*.py` exit 0 | PASS (QA iterasi 1, lihat baris 1 (E)) | A-F1 Minor FIXED, A-F2 Major FIXED, A-F3 Nit, A-F4 Nit, B-F1 Nit, I2-F3 diukur ulang (DEFERRED) | - |
| 1 (CD) | Bagian C (AC-12..AC-14) dan D (AC-15..AC-21), bagian C/D dari AC-23/24/27; simpang seberang sesudah putusan P-6; lihat "Iterasi 1, bagian CD (Dev)" dan "Lanjutan P-6" | hijau: import 0 ERROR/WARNING, 18835 lolos 0 gagal, pemeriksa lolos, `--quit-after 2` bersih, 13 `uji_*.py` exit 0 | PASS (QA iterasi 1, lihat baris 1 (E)) | C-F1 (5B) FIXED, D-F1 FIXED (P-6), D-F2 Nit, D-F3 Nit | - |
| 1 (E) | Bagian E (AC-22..AC-27): paket ekspor diperiksa dan dimuat dari luar repo, `tes_export`/pemindai diperluas, dokumen AC-25, gerbang akhir iterasi 1, 7 mutan E; lihat "Iterasi 1, bagian E (Dev)" | hijau: import 0 ERROR/WARNING, 19052 lolos 0 gagal, pemeriksa lolos, `--quit-after 2` bersih, 13 `uji_*.py` exit 0, paket 155 cek lolos | **PASS** (QA iterasi 1: gerbang sendiri hijau, 19052 lolos 0 gagal, 13 `uji_*.py` exit 0, paket diperiksa, 12 mutan QA mati, 0 Blocker, 0 Major) | tidak ada (Dev); QA: QA-001 Nit, QA-002 Minor, QA-003 Nit | A-F1, A-F2, C-F1, D-F1 VERIFIED |

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|
| A-F1 | 1 (Dev) | Minor | `scripts/entities/loper_sprite.gd` `atur_jatuh(false)` -> `_terapkan_animasi` | Saat bangun, animasi kayuh (4 frame) mewarisi indeks frame `bangkit_<arah>` (frame 5) yang dijepit Godot ke frame 3: frame terakhir bangkit (= santai frame 0) disusul **santai frame 3**, lompatan piksel tiap tabrakan. Reproduksi di `main` b69fc1f: `steer = 1; atur_jatuh(true, 1.15); atur_jatuh(false, 0)` -> `santai_serong_kanan f3 p0.50`. | VERIFIED (QA iterasi 1: mutan QA Q3 `set_frame_and_progress(0` -> `(1` mati 19034/18; tangkapan qa1 `*_tabrak_*_bangkit_akhir` vs `*_bangun` sama di sekitar pemain) | `loper_sprite.gd`: animasi pose dimulai frame 0 progres 0 saat bangun; commit 18f7d15 | `tes_animasi_5c.gd` `_test_pijak_urutan_per_arah` (urutan berakhir `santai_<arah>:0`), `_test_bangkit_ke_kayuh_piksel` (0 piksel beda, kontrol frame 3 berbeda), scene `_test_scene_jatuh_arah_ditahan`; mutan A13 |
| A-F2 | 1 (Dev) | Major | `scripts/entities/sepeda_uji.gd` `gerak` | Jatuh lima arah PR #51 praktis tidak pernah tampil di game: `SepedaUji.gerak` mengganti `steer` tiap langkah dari `BikeMotion`, yang melapor arah 0 selama sepeda dibekukan (kecepatan 0, lateral 0), jadi `jatuh_<arah>` hanya tampil pada langkah tabrakan lalu berganti ke `jatuh_normal`/`terjerembab_normal`/`bangkit_normal`. Reproduksi di `main`: `steer = 2; atur_jatuh(true, 0); steer = 0; atur_jatuh(true, 0.1)` -> `jatuh_normal f1`; di scene (stick ke seberang, tabrakan anjing di lateral -1,46) langkah kedua jatuh sudah `jatuh_normal`. | VERIFIED (QA iterasi 1: tangkapan qa1 `2340x1080_animasi_tabrak_serong_kiri_{jatuh,terjerembab,bangkit_tengah,bangkit_akhir,bangun}` semua serong kiri; mutan Dev A14 tercatat, diff `sepeda_uji.gd` dibaca) | `sepeda_uji.gd`: `steer` tidak diganti selama `sprite.sedang_jatuh()` (langkah bangun juga, jadi frame bangun = `santai_<arah jatuh>` f0); commit 18f7d15 (baris tambahan di `atur_ulang` dibuang di a167770: ekuivalen, mutan A15) | `_test_scene_jatuh_arah_ditahan` (normal dan serong kiri: jatuh 0-3, terjerembab, bangkit 0-5, santai 0 semua ke arah tabrakan), `_test_scene_main_lagi_saat_jatuh`; mutan A14 |
| A-F3 | 1 (Dev) | Nit | AC-6, `MissionManager` syarat tangkap (tidak diubah) | Syarat tangkap (kecepatan <= `MISI_TANGKAP_KECEPATAN_MAKS_UD` 1,5 selama `lama_berhenti_detik` 1,5) bisa terpenuhi **tanpa pose BERHENTI**: rem diketuk berulang (lepas di <= 0,4 u/d, tekan lagi di >= 1,3) menjaga 0,333 <= v <= 1,5 selama 19,6 detik dengan pose REM/KAYUH saja. Satu siklus rem sampai 0 lalu dilepas: 0,833 detik di bawah ambang (REM 0,300, BERHENTI 0,033, KAYUH 0,500), belum cukup sendiri. Tanpa rem sama sekali tidak bisa (stick -0,89 = tujuan 1,665 u/d). Skrip: `dev_ukur/ukur_nit.gd`. Pose berhenti tampil bila pemain menahan rem sampai diam (dites, AC-6). | NEEDS-MANUAL (QA iterasi 1: diterima sebagai Nit sesuai AC-6; syarat tangkap dan gerak tidak diubah, `git diff main` kosong untuk `mission_manager.gd`/`bike_motion.gd`; dinilai di SETUP_ANDROID 8.14 butir 4) | - | `_test_scene_berhenti_tangkap` (jalur rem sampai diam = BERHENTI, progres berjalan) |
| A-F4 | 1 (Dev) | Nit | `SepedaUji` sesudah bangun | Langkah bangun memakai arah jatuh (piksel-identik dengan frame terakhir bangkit); langkah berikutnya arah kembali dari gerak, jadi bila stick masih ditahan ke samping sprite berganti arah satu langkah sesudah bangun (contoh probe: `santai_serong_kiri` f0 lalu `santai_kiri`). Pijak tetap; ini perubahan arah biasa dari gerak, bukan lompatan pijak. Dicatat untuk penilaian di HP (SETUP_ANDROID 8.14 butir 2). | NEEDS-MANUAL | - | - |
| B-F1 | 1 (Dev) | Nit | `probe_misi_jendela.gd` titik tahan tangkap (sepeda 1,2 ubin sebelum kucing, lateral -1) | Di titik tahan probe lama kepala dan badan pemain menutup sebagian besar kucing (kucing lateral -2 digambar di belakang pemain menurut Y-sort), jadi pose ditangkap hanya terlihat telinganya (`shots/iter1/*_misi_tangkap_progres*.png`). Saat berhenti lebih jauh (rem dari 2,9 ubin, berhenti sekitar 1,6 ubin sebelum kucing) kucing duduk dielus terlihat utuh (`*_animasi_berhenti_tangkap_kucing.png`). Keterbacaan = NEEDS-MANUAL (SETUP_ANDROID 8.14 butir 5); geometri tangkap tidak diubah. | NEEDS-MANUAL | - | - |
| I2-F3 | 1 (Dev ukur ulang) | Nit | pose jatuh/terjerembab/bangkit (sel 140x88) lawan dekor | Lihat bagian "AC-7" di Iterasi 1 bagian AB: 5 dari 44 kombinasi dekor x rintangan sesegmen punya piksel opak dekor di atas pose jatuh yang tidak ditutup kotak penutup (maks 89 sampai 284 piksel per kombinasi), pose berkendara 0 di semua kombinasi. Perbaikan butuh kotak penutup lebih besar (mengubah kapan dekor memudar saat berkendara), jadi bukan "satu konstanta tanpa efek ke pose berkendara". | DEFERRED | - | `dev_ukur/ukur_i2f3.gd` |
| C-F1 (run 5B) | 1 (Dev CD) | Rendah | ubin tetangga jalan masuk sisi seberang | Celah ujung kerb 22 piksel di baris maju + 1 jalan masuk (DEFERRED dari run 5B). | VERIFIED (QA iterasi 1: `uji_aset_pasang_5b.py` 661 lolos dengan cek 0 piksel dan kontrol 22; mutan QA Q11 mati; tangkapan qa1 `2340x1080_simpang_ujung_kerb.png` kerb berhenti rapi di jalan masuk) | `ubin_perumahan.py` (`UJUNG_SEL`, `cek_masuk`), `UbinKhusus.Ubin.UJUNG`, `TanahDaur` ujung, rute.tscn; commit 414a4bd | `uji_aset_pasang_5b.py` (0 piksel, kontrol 22 tanpa ujung), `tes_simpang._test_ujung_kerb_literal`, oracle `tes_ubin_5b`; mutan C1-C5 |
| D-F1 | 1 (Dev CD) | Major (keputusan) | `assets/data/routes/perumahan/*.json`, AC-17, D-4 | **Simpang sisi seberang tidak muat tanpa mengubah susunan rute.** Rumah seberang di semua sembilan segmen berjarak 4 ubin dengan tapak 3 ubin (kavling `pos - 0,5` .. `pos + 2,5`), jadi celah sisi seberang paling lebar **1 ubin** (juga di sambungan segmen: ujung kavling terakhir `panjang + 0,5`, rumah pertama segmen berikut `1,5`), sedangkan pita simpang (renderer, D-3) **5 ubin** (mulut saja 2 ubin). D-4 (a) tidak mungkin, (b) geser dekor tidak membuka celah (yang menghalangi rumah). (c) butuh menghapus satu rumah seberang. **Rekomendasi:** hapus rumah seberang `per_buka_02@18` (`pelanggan_boleh` false, jadi kandidat pelanggan tidak berubah) dan pasang `{ "pos": 18, "sisi": "seberang" }` (pita 16,5 .. 21,5 tepat di antara kavling 14 dan 22; tanpa dekor, rintangan, atau titik misi di pita, tanpa memindah dekor), lalu `SIMPANG_SISI_DIPASANG += ['seberang']` (16 ubin seberang dari build/) dan 16 tekstur di rute.tscn. **Diukur (percobaan, sudah dikembalikan):** validasi lolos; 56/100 rute hari (48/100 seed dev) memuat simpang seberang; 6 cek gagal yang angkanya akan berubah: `tes_rute` "total rumah di 9 segmen = 109 (73 seberang ...)" -> 108 (72 seberang, per_buka_02 7), `tes_dekor` GOLDEN_RUTE 29/60 cocok (31 seed memakai per_buka_02: uraian rumah berubah, golden perlu dihitung ulang), `tes_simpang` GOLDEN_RUTE 29/60, `tes_simpang` "enam berkas tanpa simpang" -> lima, konten literal, persen literal (seberang 0 -> 56). Tes misi 600 hari, pelanggan, tip, tenggat, rintangan lulus. Diputus orchestrator P-6 (rekomendasi diterima) dan dikerjakan, lihat "Lanjutan P-6". | VERIFIED (QA iterasi 1: skrip banding QA sendiri, pustaka `main` vs HEAD per bidang: 60 seed dev 31 berubah, 600 hari 311 berubah, perbedaan selain hilangnya baris rumah `per_buka_02@18` = 0; lihat QA-003 untuk angka rencana kucing) | `per_buka_02.json` (rumah @18 dihapus, simpang seberang pos 18), `ubin_perumahan.py` `SIMPANG_SISI_DIPASANG`, 16 ubin seberang, rute.tscn; commit 35db641 | `tes_simpang` (golden ulang, scene dan gerak sisi seberang, referensi seberang), `uji_aset_simpang.py`, probe seberang; mutan S1-S5 |
| D-F2 | 1 (Dev CD) | Nit | `per_tengah_05` simpang dekat pos 3 dan mobil garasi seberang pos 9 | Mobil seberang segmen yang sama mundur melintang ke jalan sekitar 1,5 ubin sesudah ujung pita simpang (`*_simpang_lengan_tepi.png`, sepeda menunggu di mulut): mobil di jalan dekat mulut jalan samping bisa terbaca seperti keluar dari simpang. Bukan pelanggaran aturan (lintasan mobil di luar pita, dites), simpang tetap hiasan; dinilai di HP (SETUP_ANDROID 8.14 butir 7). | NEEDS-MANUAL | - | `_test_parse_negatif` (lintasan mobil di pita ditolak) |
| D-F3 | 1 (Dev CD) | Nit | AC-17 | 100 % rute memuat simpang dekat karena `per_tengah_05` selalu terpakai (lima segmen tengah = lima dibutuhkan), selalu di posisi segmen yang sama; ditambah 50 % rute dengan pembuka `per_buka_01` dan penutup `per_tutup_01`. Bisa terasa berulang; frekuensi dinilai di HP dan saat segmen bertambah (ROUTE_DESIGN, bagian E). | NEEDS-MANUAL | - | `_test_konten_dan_persen` (literal 100/100/0) |
| QA-001 | 1 (QA) | Nit | `scripts/config.gd:1218` komentar `RUTE_SIMPANG_SEL_SEBERANG` | Komentar masih berbunyi "Ubinnya belum dipasang selama data belum memakai simpang seberang (D-2)", padahal sesudah P-6 (35db641) 16 ubin seberang dipasang dan `per_buka_02` memakai simpang seberang. Komentar basi, menyesatkan pembaca config. Repro: `sed -n 1218p scripts/config.gd`. | OPEN | - | - (komentar) |
| QA-002 | 1 (QA) | Minor | pose `jatuh_kanan`/`terjerembab_kanan` (sel 140x88) lawan panel HUD bawah | Di 2340x1080 kepala pemain yang jatuh penuh ke sisi dekat terpotong beberapa piksel oleh panel KECEPATAN (tangkapan qa1 `2340x1080_animasi_arah_kanan_terjerembab.png` dan `_jatuh.png`, dagu dan topi di bawah tepi atas panel; probe menaruh sepeda di lateral 0). Di 1600x720 kepala tepat menyentuh tepi panel tanpa tertutup. Jatuh nyata ke kanan terjadi saat menyetir ke sisi dekat, jadi pemain bisa lebih ke kanan bawah dan lebih tertutup. Tidak melanggar AC (probe tidak memeriksa tumpang HUD) dan HUD tidak diubah run ini; klaim Dev AC-8 "tidak menumpuk panel HUD" hanya benar untuk 1600x720. Dinilai di HP (SETUP_ANDROID 8.14 butir 1); bila mengganggu, perbaikan tata letak HUD/kamera di run lain. | NEEDS-MANUAL | - | - (visual) |
| QA-003 | 1 (QA) | Nit | LOG "Lanjutan P-6" turunan (2) | LOG menulis rencana kucing misi P1 berubah "di 311 dari 600 hari (semua hari ber-`per_buka_02`)". Skrip QA (`RencanaMisi.buat` dengan benih `SeedHari.misi(hari)` = benih `RuteMain`, pustaka `main` vs HEAD, banding daftar `id_rumah`) mendapat **289 dari 600**: 311 adalah jumlah rute yang berubah, bukan rencana; sebagian hari ber-`per_buka_02` memilih titik sebelum pos 14 sehingga rencananya tetap. Hanya ketelitian catatan, tidak mengubah kesimpulan P-6 (tes misi 600 hari lulus tanpa diubah). | OPEN | - | - |

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
- **Putusan orchestrator P-6 (D-F1, 2026-10-22):** rekomendasi Dev diterima. Hapus rumah seberang `per_buka_02@18` (`pelanggan_boleh` false, kandidat pelanggan tidak berubah) dan pasang simpang `{ "pos": 18, "sisi": "seberang" }`; `SIMPANG_SISI_DIPASANG` = `['dekat', 'seberang']`, 16 ubin seberang lewat `--salin`. Alasan: AC-17 mewajibkan >= 1 simpang seberang; celah seberang maksimum 1 ubin di semua segmen sehingga D-4 (a)/(b) mustahil; rumah yang dihapus bukan pelanggan, jadi pemain kehilangan satu rumah hiasan saja. Syarat: (1) golden yang berubah (`tes_rute` hitungan rumah, GOLDEN_RUTE `tes_dekor` dan `tes_simpang`, hitungan berkas tanpa simpang, literal konten/persen) dihitung ulang oleh skrip dari kode, bukan tangan, dan LOG mencatat per golden bahwa SATU-SATUNYA perbedaan adalah rumah `per_buka_02@18` (31 seed) beserta turunannya yang dijelaskan; pelanggan, rintangan, titik misi, dekor, tenggat, skor lain identik atau dijelaskan satu per satu; (2) tes misi 600 hari, pelanggan, tip, tenggat, rintangan tetap lulus tanpa diubah; (3) tidak ada segmen baru, tidak ada dekor dipindah. D-F2 dan D-F3 diterima sebagai NEEDS-MANUAL.

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

## Iterasi 1, bagian CD (Dev)

Dikerjakan: AC-12 sampai AC-21 dan bagian C/D dari AC-23, AC-24, AC-27 (SPEC D-1). Bagian E (dokumen, paket ekspor, gerbang penuh) tidak disentuh, kecuali komentar kode. Simpang sisi `seberang` sempat BLOCKED (D-F1, D-4 c), lalu diputus orchestrator P-6 dan dikerjakan (bagian "Lanjutan P-6" di bawah); bagian AC di bawah sudah memuat hasil sesudah P-6.

### Baseline bagian CD (HEAD 7f30557, sebelum perubahan)
- `run_tests.gd`: 18420 lolos, 0 gagal; pemeriksa lolos. sha256 save asli `37d6d6cb...549e`.
- Golden rute AC-16 dihitung di 7f30557 SEBELUM simpang: `dev_ukur/golden_rute_cd.gd` (uraian rumah, rintangan, pelanggan, titik misi, DEKOR, tenggat, skor; 60 seed 20261016 + 7 i), ditulis literal di `tests/tes_simpang.gd` `GOLDEN_RUTE`.
- Proses lama pid 26665 (bukan milik Dev) tetap dibiarkan; semua proses Godot Dev dijalankan satu per satu.

### Perubahan kode
- `tools/env_art/ubin_perumahan.py`: (C) `ekspor_ubin` menghitung sel tetangga jalan masuk sisi seberang yang berbeda dari ubin lurus pada adegan jalan masuk (hasil: tepat `trotoar_seberang` dan `rumput_seberang` di baris maju + 1; dicocokkan `UJUNG_SEL`, assert), menyimpan `*_masuk_ujung`; `cek_masuk` menyusun ulang jalan masuk sisi seberang dari ubin = adegan (cetak `beda sambungan masuk seberang: 0`). (D) `--salin` menyalin ubin simpang hanya untuk `SIMPANG_SISI_DIPASANG = ['dekat']` (D-2) dan JSON terpangkas membawa `ubin_ujung_kerb`, `ujung_kerb_baris_relatif`, `simpang` (y mulut, lebar mulut, pita baris relatif, sel per sisi dengan baris relatif maju). PNG lama tidak berubah (git: tidak ada `M` pada PNG 5A/5B).
- `scripts/config.gd` (satu baris literal): `RUTE_UJUNG_KERB_BARIS_RELATIF = 1`, `RUTE_SIMPANG_LEBAR_MULUT_UBIN = 2.0`, `RUTE_SIMPANG_MULUT_AWAL_UBIN = -0.5`, `RUTE_SIMPANG_PITA_BARIS = [-1, 3]`, `RUTE_SETENGAH_BARIS_UBIN = 0.5`, `RUTE_SIMPANG_SEL_DEKAT` (18 pasangan), `RUTE_SIMPANG_SEL_SEBERANG` (16 pasangan); semuanya dites = JSON renderer (Godot: JSON terpasang; Python: JSON build lengkap, termasuk sisi seberang).
- `scripts/systems/ubin_khusus.gd`: `Ubin.UJUNG` (MASUK > UJUNG > SIMBOL; parameter `dengan_ujung` untuk tanah tanpa tekstur ujung = perilaku 5B), `ujung_di_baris`, `himpunan_baris_simpang`, `tabel_simpang`, `kolom_simpang` (lengan = semua kolom rumput luar), `sel_simpang` (murni).
- `scripts/systems/segmen_rute.gd`: bidang opsional `simpang` `{pos, sisi}` (`Simpang`), `_parse_simpang`, `pita_maju`, `memotong_pita` (tepi bersentuhan boleh; sisi simpang membentang dari garis tengah ke luar), `pita_bertumpuk`, `kavling_rumah` (tapak logika + tapak gambar + tembok dekat pos..pos+3), `bentuk_jalan_masuk` (baris jalan masuk + baris ujung kerb), `galat_tempat_simpang`.
- `scripts/systems/route_builder.gd`: `SimpangItem` (id `<segmen>:simpang:<sisi>@<pos>`, `maju_ubin` mutlak, `sisi`, `lebar_mulut_ubin`, `mulut_awal_ubin`), `Rute.simpang`, SATU fungsi baca `simpang_di(rute)` (titik pakai lalu lintas berbelok M3, didokumentasikan), diisi di `_isi_segmen` tanpa RNG; `periksa_rute` + `_periksa_simpang` memeriksa pita terhadap isi segmen MANA PUN di rute utuh (sambungan segmen) dan tumpang antar simpang.
- `scripts/entities/tanah_daur.gd`: `tekstur_ujung_*` (wadah `UjungTrotoarSeberang`, `UjungRumputSeberang`), `tekstur_simpang_dekat`/`_seberang` (Array, sejajar tabel; wadah `SimpangDekat<i>`), `mode_ujung`, `mode_simpang(sisi)`, `atur_simpang`; kolom aspal dan rumput pertama ikut dinamis bila sisi itu punya ubin simpang. Sel, posisi, jumlah sprite tidak berubah; tekstur tetap dari `@export` (tanpa `load` di `_draw`).
- `scripts/entities/rute_main.gd`: satu baris `_tanah.atur_simpang(UbinKhusus.himpunan_baris_simpang(RouteBuilder.simpang_di(_rute)))`.
- `scenes/rute/rute.tscn`: 2 tekstur ujung + 18 tekstur simpang dekat.
- Data (D-4 a, sela kosong, tanpa memindah apa pun): `per_buka_01` simpang dekat pos 3, `per_tengah_05` pos 3, `per_tutup_01` pos 2.
- Aset baru (lewat `--salin`, `.import` dan uid dikomit): `tile_perumahan_{trotoar,rumput}_seberang_masuk_ujung.png`, 18 `tile_perumahan_simpang_dekat_*.png`, `tile_perumahan.json`.
- Tes/uji baru: `tests/tes_simpang.gd` (139 cek), `tests/probe_simpang_jendela.gd`, `tools/tests_cek/uji_aset_simpang.py` (132 cek, masuk CI `.github/workflows/tes.yml`), `tests/data/ubin_potongan_simpang.png` (dibuat `--perbarui-referensi`).

### Tes lama yang diubah (satu per satu, alasan)
1. `tests/tes_ubin_5b.gd` `_buat_tanah`: ditambah dua tekstur ujung kerb (15 tekstur) supaya ujung ikut diuji. Alasan: C-F1.
2. `tests/tes_ubin_5b.gd` `_nama_harapan` (oracle): baris maju + 1 jalan masuk = ujung kerb di kolom -1,5 dan -2,5, menang atas simbol. Alasan: C-F1 (sebelumnya baris itu ubin biasa/simbol).
3. `tests/tes_ubin_5b.gd` `_periksa_tanah`: parameter `pita_dekat` (bawaan kosong); di baris pita simpang dekat rute nyata, ubin `simpang_dekat_*` di sisi dekat diterima (letak per sel diuji `tes_simpang.gd`). Alasan: rute nyata kini memuat simpang (scene rute dan Main lagi).
4. `tests/tes_ubin_5b.gd` `_test_tanah_khusus`: daftar wadah 13 -> 15 (`UjungTrotoarSeberang`, `UjungRumputSeberang`); `WADAH_BARU`/`TEKSTUR_WADAH_BARU` +2. Alasan: tekstur baru, satu wadah per tekstur (AC-18).
5. `tests/tes_ubin_5b.gd` `_test_scene_rute`: wadah scene 13 -> 33 (+2 ujung, +18 simpang dekat); cek mode khusus + `mode_ujung`. Alasan sama.
6. `tests/tes_ubin_5b.gd` `_test_kolom_pertama_dan_proporsi`: dengan masuk {17}, baris 18 harus `UJUNG` (dulu: semua baris selain 17 bawaan). Alasan: C-F1.
7. `tests/tes_ubin_5b.gd` `_test_susunan_referensi`: ubin khusus di potongan 9 -> 11 (2 ujung kerb baris 5); `_test_tanpa_celah` menghitung `_ujung.png` sebagai ubin khusus. Alasan: C-F1.
8. `tests/data/ubin_potongan_5b.png`: dibuat ulang oleh `uji_aset_pasang_5b.py --perbarui-referensi` (kini memuat ujung kerb). Bukan tangan.
9. `tests/tes_ubin.gd`: konstanta `UBIN_5C` (20 nama literal) ditambah ke tekstur sah di scene rute, pemindai rujukan, dan isi folder. Alasan: 20 ubin baru dipasang.
10. `tools/tests_cek/uji_aset_pasang_5b.py`: pengecualian C-F1 dihapus: "tepat 22 piksel beda" kini KONTROL tanpa ubin ujung (bukti angka lama), dan cek baru "dengan ubin ujung = 0 piksel" + tanpa celah; `nama_ubin_khusus` memilih ujung; daftar ubin folder/JSON +20; PNG baru 17 -> 37; cek `beda sambungan masuk seberang: 0`. Alasan: AC-14.
11. `tools/tests_cek/uji_aset_pasang_gelombang1.py`: daftar ubin folder dan JSON + `UBIN_5C`. Alasan: isi folder berubah.
12. `tests/run_tests.gd`: hanya mendaftarkan `TesSimpang`.
Sebelum P-6 tidak ada angka gerak, skor, zona, misi, tabrakan, atau golden rute lama yang diubah. Sesudah P-6 lihat daftar lanjutan di "Lanjutan P-6".

### Bukti per AC
- **AC-12** `uji_aset_simpang.py` dan `uji_aset_pasang_5b.py`: dua kali `--salin` piksel sama dan JSON byte sama; isi `assets/` = keluaran; hanya `*_masuk_ujung` sisi seberang (sel dihitung renderer, assert `UJUNG_SEL`); `*_dekat_masuk`, `aspal_N` tidak ada; `.import` Lossless, tanpa mipmap, bukan VRAM, uid ada.
- **AC-13** `tes_simpang._test_ujung_kerb_literal` (15 kasus literal: kolom -1,5/-2,5 baris 18 = UJUNG, aspal dan dekat tidak, baris 16/19 tidak, MASUK menang, tanpa ujung = SIMBOL, mobil dekat tanpa ujung; TanahDaur jalan masuk baris 5 = tepat dua ubin ujung di baris 6); `tes_ubin_5b` oracle per sel di 18 jarak dan scene rute nyata (5 mobil seberang) lulus; `jalan_daur.gd` tidak berubah (`git diff main` kosong), jumlah dan posisi sprite sama (`tes_ubin_5b` lima lebar).
- **AC-14** `cek_masuk` = 0, `uji_aset_pasang_5b.py`: jalan masuk sisi seberang = adegan **0 piksel** (kontrol tanpa ujung: tepat 22 di baris maju 5, x -2,1..-1,0); referensi `ubin_potongan_5b.png` dari skrip; `tes_ubin_5b._test_susunan_referensi` piksel-identik. Tangkapan `*_simpang_ujung_kerb.png` (Dev melihat 2340x1080: kerb berhenti rapi di tepi jalan masuk, tanpa potongan kerb di depan).
- **AC-15** `tes_simpang._test_parse_negatif` (tiap cabang: bukan daftar, bukan objek, sisi kiri/tengah, field asing, pos/sisi hilang, pos 10,5 dan teks, kavling dekat dan seberang dengan batas sentuh sah, tembok saja, dekor dekat vs seberang, anjing dekat vs seberang, lintasan mobil, jalan masuk + ujung kerb saja, dua pita bersentuhan sah vs bertumpuk beda sisi), `_test_pita_batas` (pos 1 ditolak, 2 sah, 26 sah, 27 ditolak di panjang 30), `_test_parse_sah_dan_lama` (6 berkas tanpa simpang sah), `_test_kucing_600_hari` (600 hari, >1000 titik kucing, 0 di pita), `_test_periksa_rute_sambungan` (sisipan di rumah dekat dan tumpang ditolak di tingkat rute; 100 rute hari sah). Catatan batas: dengan `pos` bulat, tepi pita selalu di x,5, jadi batas "pita di dalam segmen" `<` vs `<=` tidak bisa dibedakan (mutan ekuivalen, tidak dihitung).
- **AC-16** `_test_rute_identik_golden`: 60/60 sidik = golden 7f30557 (termasuk dekor), 25 pelanggan; `_test_tanpa_rng`: 30 seed rute dengan dan tanpa bidang simpang identik; `_test_rute_simpang_dan_fungsi_baca`: 20 rute, simpang (id, maju mutlak, sisi, lebar 2,0, mulut awal maju - 0,5) = berkas JSON dibaca ulang; `simpang_di(null)` kosong. `tes_dekor` golden lama lulus tanpa diubah.
- **AC-17** Konten: tiga simpang dekat di sela kosong tanpa memindah apa pun (D-4 a: `per_buka_01@3`, `per_tengah_05@3`, `per_tutup_01@2`) dan satu simpang seberang `per_buka_02@18` (P-6: rumah seberang `per_buka_02@18` dihapus, tanpa dekor dipindah dan tanpa segmen baru). 100 seed `SeedHari.rute(1..100)`: **100 % bersimpang, 100 % dekat, 56 % seberang**; 100 seed dev 20261016 + 7 i: 100 / 100 / 48 (`dev_ukur/ukur_simpang.gd`). `per_tengah_05` selalu terpakai (lima segmen tengah = lima dibutuhkan); 1 sampai 3 simpang per rute (satu pembuka, per_tengah_05, satu penutup). ROUTE_DESIGN belum diperbarui (bagian E).
- **AC-18** `_test_sel_simpang_literal` (23 kasus literal kedua sisi, di luar pita, sisi lain, kolom luar jauh x 40,5 dan -9,5); `_test_tanah_pasang` (5 lebar x 6 jarak: tiap sprite = tabel literal di pita sisi dekat dan sama dengan tanah tanpa simpang di luar; lengan sampai kolom terjauh blok di tiap lebar; 33 wadah = 15 + 18 tekstur baru, satu tekstur per wadah; jumlah sprite sama; `atur_simpang({})` bersih; simpang seberang tanpa tekstur tidak memasang apa pun); `_test_scene` (rute.tscn 18 tekstur sejajar tabel; sel pita rute dev = tabel; 100 rute: 0 modul tembok, tiang, atau tapak gambar rumah dekat di pita). Penutup pemain tidak disentuh (`penutup_pemain.gd` tanpa diff).
- **AC-19** `uji_aset_simpang.py` (214 cek): susunan 12 kolom x 9 baris dari assets/ kedua sisi = `build_simpang` **0 piksel beda**, tanpa celah; kontrol lengan berhenti kolom ke-4, geser satu baris, sisi salah terdeteksi; config = JSON terpasang kedua sisi; referensi `tests/data/ubin_potongan_simpang.png` (dekat) dan `ubin_potongan_simpang_seberang.png` (seberang) dibuat skrip. `tes_simpang._test_susunan_referensi` (99 ubin, 28 simpang dekat) dan `_test_susunan_referensi_seberang` (99 ubin, 26 simpang seberang) piksel-identik; `_test_tanpa_celah` 60 viewport dengan simpang dekat dan seberang sekaligus: 0 piksel transparan. `cek_simpang` = 0 di renderer.
- **AC-20** `_test_scene_gerak_identik`: rute dev, simpang `per_tengah_05`, lateral -2, -1, 0, 1, 2, 150 langkah 1/60 tiap lateral: jejak (jarak, lateral, kecepatan, stamina, jatuh, pose) **identik bit demi bit** dengan `atur_simpang({})`, 0 tabrakan; `_test_medan_identik`: 2000 titik berseed, zona/penilaian/penutup MedanKoran sama dengan dan tanpa simpang.
- **AC-21** `tests/probe_simpang_jendela.gd` di 2340x1080, 1920x1080, 2400x1080, 1600x720: **0 keadaan tidak sesuai**, 0 baris ERROR/WARNING, 16 tangkapan per ukuran (`shots/iter1/<ukuran>_simpang_*.png`): tiap simpang dekat rute dev, melintas mulut dekat di lateral -2/0/1/2, lengan sampai tepi, kidal, simpang seberang `per_buka_02` (rumah seberang tetangga berhenti di tepi pita), melintas mulut seberang di lateral -2/-1/0/2, lengan seberang sampai tepi kiri, kidal seberang, ujung kerb. `probe_sisi_dekat_jendela.gd` diulang di empat ukuran: 0 tidak sesuai, 0 ERROR/WARNING. Dev melihat sendiri: `2340x1080_simpang_dekat_per_tengah_05` (jalan samping ke kanan bawah, sudut kerb dan lajur hijau membelok siku, tembok berhenti sebelum mulut), `2340x1080_simpang_seberang_per_buka_02` (jalan samping ke kiri atas di antara dua rumah seberang, kotak surat tetangga utuh), `1600x720_simpang_seberang_lengan_tepi` (lengan sampai tepi kiri), `2340x1080_simpang_ujung_kerb`, `1600x720_simpang_lengan_tepi`.

### Mutan nyata (AC-27 bagian C/D)
Tiap mutan: satu perubahan di kode/data/aset asli, `run_tests.gd` penuh + `cek_keluaran_tes.py` (atau uji Python terkait untuk mutan aset), lalu `git checkout -- <berkas>`. Skrip: `dev_ukur/mutan_cd.py`.

| Kode | Berkas | Perubahan | Hasil (lolos/gagal) | Tes yang gagal (contoh) |
|---|---|---|---|---|
| C1 | ubin_khusus.gd | ujung kerb di baris salah (maju - 1) | 18701/16 MATI | kolom rumput pertama (-2,5 dan 2,5) tidak pernah rumput_2, rumput_3, atau simbol (1200 baris); masuk hanya di baris 17, ujung kerb hanya di  |
| C2 | ubin_khusus.gd | ujung kerb hanya di trotoar (kolom rumput pertama lupa) | 18704/12 MATI | kolom rumput pertama (-2,5 dan 2,5) tidak pernah rumput_2, rumput_3, atau simbol (1200 baris); masuk hanya di baris 17, ujung kerb hanya di  |
| C3 | ubin_khusus.gd | ujung kerb juga di sisi dekat | 18706/11 MATI | tiap sprite ubin memakai tekstur harapan oracle di 18 jarak (naik dan turun): 20 salah dari 9198 (jarak 0.0: x 1.5 baris -2: tekstur rumput_ |
| C4 | tanah_daur.gd | TanahDaur tidak pernah memasang ujung kerb | 18705/10 MATI | tiap sprite ubin memakai tekstur harapan oracle di 18 jarak (naik dan turun): 40 salah dari 9198 (jarak 0.0: x -2.5 baris -2: tekstur rumput |
| C5 | config.gd | konstanta ujung kerb salah | 18699/18 MATI | kolom rumput pertama (-2,5 dan 2,5) tidak pernah rumput_2, rumput_3, atau simbol (1200 baris); masuk hanya di baris 17, ujung kerb hanya di  |
| D1 | segmen_rute.gd | batas pita < jadi <= (sentuh ditolak) | 18714/3 MATI | rumah dekat pos 14, simpang dekat pos 10 (pita berakhir 13,5 = awal kavling): sah, tepi bersentuhan |
| D2 | segmen_rute.gd | penolakan kavling rumah dilepas | 18713/4 MATI | simpang dekat pos 11 (pita 9,5 .. 14,5) memotong kavling rumah dekat pos 14 |
| D3 | segmen_rute.gd | kavling tanpa tembok | 18715/2 MATI | simpang dekat pos 8 memotong tembok rumah dekat pos 4 (tembok sampai maju 7) |
| D4 | segmen_rute.gd | penolakan dekor dilepas | 18716/1 MATI | pohon dekat pos 13 di pita ditolak |
| D5 | segmen_rute.gd | penolakan rintangan dilepas | 18715/2 MATI | anjing dekat di pita ditolak |
| D6 | segmen_rute.gd | penolakan jalan masuk dilepas | 18716/1 MATI | simpang seberang pos 12 hanya memotong baris jalan masuk + ujung kerb mobil pos 10 (bukan lintasannya): [] |
| D7 | segmen_rute.gd | penolakan pita di luar segmen dilepas | 18715/2 MATI | pos 1 (pita mulai -0,5) ditolak |
| D8 | segmen_rute.gd | penolakan dua pita bertumpuk dilepas | 18716/1 MATI | dua simpang berpita bertumpuk (pos 5 dekat, 9 seberang) ditolak |
| D9 | segmen_rute.gd | sisi tidak dikenal tidak ditolak | 18715/2 MATI | sisi 'kiri' ditolak |
| D10 | segmen_rute.gd | field asing simpang tidak ditolak | 18716/1 MATI | field asing ditolak |
| D11 | segmen_rute.gd | pos bukan bilangan bulat diterima | 18715/2 MATI | pos 10,5 ditolak |
| D12 | route_builder.gd | simpang ikut memakai RNG rute (mengubah rute dari seed) | 18690/26 MATI | tap bantu ke kotak surat @10: centang, bukan tepat (O-4) |
| D13 | route_builder.gd | maju simpang tidak mutlak | 16239/924 MATI (juga 1542 SCRIPT ERROR: rute tanpa simpang mutlak memicu galat di tes lain) | seed 1 dibangun dua kali: urutan segmen dan pelanggan identik |
| D14 | ubin_khusus.gd | ubin simpang di sisi salah juga | 18712/5 MATI | sel_simpang(x -0.5, baris 10) = (-1, -1) (dapat (1, 9)) |
| D15 | ubin_khusus.gd | lengan tidak diulang sampai kolom terjauh | 18709/8 MATI | sel_simpang(x 40.5, baris 11) = (2, 10) (dapat (2, 9)) |
| D16 | ubin_khusus.gd | ubin simpang di baris salah (geser 1) | 18696/21 MATI | scene rute, mobil di maju 113.0: semua ubin sesuai oracle (x 1.5 baris 111: tekstur simpang_dekat_trotoar_dekat_depan_2 harapan trotoar_deka |
| D17 | tanah_daur.gd | kolom aspal dan rumput dekat tidak bisa berganti (mulut aspal hilang) | 18712/5 MATI | tiap sprite di 5 lebar x 6 jarak = harapan (tabel literal di pita sisi dekat, sama dengan tanah tanpa simpang di luar): lebar 640 jarak 0.0  |
| D18 | config.gd | pita terlalu pendek | 18698/19 MATI | pita baris [-1, 3] = JSON |
| D19 | ubin_perumahan.py | ubin simpang seberang yang tidak dipakai ikut tersalin | uji_aset_simpang 131 lolos, 1 gagal MATI | tile_perumahan.json byte-identik: dua kali jalan dan assets/ |
| D20 | tile_perumahan_simpang_dekat_lengan_mulut_1.png.import | .import ubin simpang bukan Lossless | uji_aset_simpang 131 lolos, 1 gagal MATI | simpang_dekat_lengan_mulut_1: impor Lossless, tanpa mipmap, bukan VRAM |
| D21 | segmen_rute.gd | penolakan zona dilepas (dugaan ekuivalen: zona di dalam kavling) | 18717/0 HIDUP -> ekuivalen | Zona rumah selalu di dalam rentang maju kavling (dibuktikan `_test_zona_di_dalam_kavling`), jadi cabang zona hanya pengaman; tidak dihitung |

25 mutan mati (C1-C5, D1-D20; ditambah S1-S5 sisi seberang di "Lanjutan P-6"), 1 hidup dan dinyatakan ekuivalen dengan bukti tes (D21). Tidak ada mutan hidup yang menuntut tes diperketat. `git status` sesudah tiap mutan hanya LOG dan `dev_ukur/` (belum dikomit). Mutan tidak dihitung: batas "pita di dalam segmen" `<` vs `<=` (ekuivalen untuk `pos` bulat, lihat AC-15).

### Gerbang bagian CD sebelum P-6 (HEAD 129666e + LOG; gerbang akhir sesudah P-6 di "Lanjutan P-6")
- `godot --headless --import`: 0 baris ERROR/WARNING.
- (Sebelum P-6, HEAD 129666e) `run_tests.gd`: **18717 lolos, 0 gagal** (18420 + 297 cek: 139 `tes_simpang`, sisanya perluasan `tes_ubin_5b`/`tes_ubin`); `python3 tools/cek_keluaran_tes.py build/tests.log`: lolos (0 peringatan).
- `godot --headless --path . --quit-after 2`: 0 baris ERROR/WARNING.
- 13 `tools/tests_cek/uji_*.py` exit 0 (12 lama + `uji_aset_simpang.py` baru, masuk CI).
- Probe: `probe_simpang_jendela.gd` dan `probe_sisi_dekat_jendela.gd` di 2340x1080, 1920x1080, 2400x1080, 1600x720: 0 keadaan tidak sesuai, 0 ERROR/WARNING.
- `git diff main` kosong untuk `throw_solver`, `skor_rute`, `zona_sasaran`, `tenggat_rute`, `bike_motion`, `tabrakan`, `rintangan_rute`, `mission_manager`, `rencana_misi`, `bike_condition`, `economy`, `data_save`, `jalan_daur`, `medan_koran`, `penutup_pemain`, `scripts/autoload/`.
- sha256 `user://save.json` asli sebelum dan sesudah semua tes, probe, mutan, dan percobaan D-F1: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e`.
- Rule (AC-24 bagian C/D): static typing dan `##` bahasa Indonesia (cek gaya runner lolos), sisi hanya `seberang`/`dekat` di kode dan data, angka baru hanya di `config.gd` satu baris literal (cek angka ajaib lolos), tanpa hex, tanpa teks pemain baru, RNG tidak dipakai simpang, `.uid`/`.import` dikomit, tanpa PNG renderer diedit tangan (semua lewat `--salin`, referensi lewat `--perbarui-referensi`), tekstur dari `@export` scene (tidak dimuat di `_draw`).

### Commit bagian CD
414a4bd (feat: ujung kerb + simpang inti + data + tes lama), 6930002 (test: tes_simpang, uji_aset_simpang, referensi, CI), 129666e (test: probe simpang, tes literal ujung kerb, tangkapan), commit LOG ini (+ `dev_ukur/golden_rute_cd.gd`, `ukur_simpang.gd`, `mutan_cd.py`). Tidak di-push.


### Lanjutan P-6 (simpang seberang, putusan orchestrator d3718d7)
**Perubahan.** `per_buka_02.json`: baris rumah `{ "pos": 18, "sisi": "seberang", "jenis": "limasan", "pelanggan_boleh": false }` dihapus dan `"simpang": [{ "pos": 18, "sisi": "seberang" }]` ditambah (diff data hanya itu; tidak ada dekor dipindah, tidak ada segmen baru). `ubin_perumahan.py`: `SIMPANG_SISI_DIPASANG = ['dekat', 'seberang']`; `--salin` memasang 16 `tile_perumahan_simpang_seberang_*.png` (PNG lama tidak berubah) + JSON; `rute.tscn` `tekstur_simpang_seberang` 16 tekstur sejajar `RUTE_SIMPANG_SEL_SEBERANG`; `godot --headless --import` bersih, `.import`/uid dikomit. Kode produksi tidak berubah (sisi seberang sudah didukung `UbinKhusus`/`TanahDaur`).

**Golden dihitung ulang oleh skrip** `dev_ukur/banding_p6.gd -- <per_buka_02 lama.json>` (membangun rute dengan pustaka lama dan baru, membandingkan uraian baris per baris):
- 60 seed dev 20261016 + 7 i: **31 berubah, 0 dengan perbedaan selain baris rumah `per_buka_02@18`**: tiap seed yang memakai pembuka `per_buka_02` kehilangan tepat satu baris `R|per_buka_02@18|...`; baris pelanggan (P), pemberi tip (kolom R), rintangan (O), titik misi data (T), dekor (D), panjang, koran awal, tenggat, dan skor/koin/tip/tepat/antar identik. 29 seed lain identik seluruhnya.
- 600 rute hari (`SeedHari.rute(1..600)`): 311 berubah, 0 dengan perbedaan selain baris rumah itu.
- **Turunan yang berubah (dijelaskan):** (1) sidik `GOLDEN_RUTE` `tes_dekor` (uraian tanpa dekor) dan `tes_simpang` (dengan dekor): 31 nilai berubah karena uraian memuat daftar rumah; nilai baru ditempel dari keluaran skrip (`build/banding_p6.txt`), bukan dihitung tangan. (2) Rencana kucing misi P1 (`RencanaMisi`, memilih rumah seberang ke-n dengan RNG misi): berubah di 311 dari 600 hari (semua hari ber-`per_buka_02`), karena urutan rumah seberang bergeser satu sesudah pos 14 (contoh hari 1: titik kedua `per_buka_02@22` -> `@26`, ketiga `per_tengah_02@6` -> `@10`). Ini bukan perubahan rute; tes misi 600 hari (`tes_misi_rantai`: sah, batas rumah, berurutan, tidak menimpa zona, rute tidak berubah, jarak) dan tes kucing 600 hari tidak di pita (`tes_simpang`) lulus TANPA diubah. (3) Jumlah rumah: 109 -> 108 (seberang 73 -> 72, `per_buka_02` 8 -> 7).
- Tes misi, pelanggan, tip, tenggat, rintangan, skor, hari tidak diubah dan lulus: `git diff main -- tests/tes_misi*.gd tests/tes_rintangan*.gd tests/tes_tenggat.gd tests/tes_skor.gd tests/tes_hari.gd` kosong.

**Tes lama yang angkanya berubah karena P-6 (lanjutan daftar, alasan sama: rumah per_buka_02@18 dihapus dan 16 ubin seberang dipasang):**
13. `tests/tes_rute.gd`: total rumah 109 -> 108 (72 seberang: 7+7+9+8+10+9+9+6+7; angka dari skrip).
14. `tests/tes_dekor.gd` `GOLDEN_RUTE`: 31 dari 60 nilai diganti keluaran skrip; komentar mencatat asal.
15. `tests/tes_simpang.gd` `GOLDEN_RUTE`: 31 dari 60 nilai diganti keluaran skrip; `SIMPANG_DATA` + `per_buka_02@18 seberang`; "enam berkas tanpa simpang" -> lima; persen 100/100/0 -> 100/100/56 (skrip `ukur_simpang.gd`); batas atas total simpang 100 rute 300 -> 400 (pemeriksaan longgar); config seberang kini dicek terhadap JSON terpasang; wadah 33 -> 49.
16. `tests/tes_ubin_5b.gd` `_test_scene_rute`: wadah scene 33 -> 49.
17. `tests/tes_ubin.gd` `UBIN_5C`: +16 nama seberang (tekstur sah dan isi folder).
18. `tools/tests_cek/uji_aset_pasang_5b.py`: daftar ubin +16, PNG baru 37 -> 53; `uji_aset_pasang_gelombang1.py`: daftar ubin +16; `uji_aset_simpang.py`: aset terpasang = 34 ubin kedua sisi (dulu "tidak ada seberang"), susunan dari assets/ kedua sisi, referensi seberang baru.

**Tes baru sisi seberang:** `tes_simpang`: pemasangan TanahDaur sisi seberang 5 lebar x 6 jarak dengan lengan sampai kolom terjauh, tanah tanpa tekstur seberang tidak memasang apa pun (33 wadah), scene rute nyata kedua sisi (dev dan seed 20261018 dengan `per_buka_02`), urutan 16 tekstur seberang rute.tscn, tembok/tapak rumah sisi simpang tidak di pita 100 rute, jejak gerak identik bit demi bit dan 0 tabrakan melintasi mulut seberang (lateral -2..2), referensi piksel seberang, tanpa celah dengan kedua simpang. Total `tes_simpang` 139 -> 257 cek.

**Mutan sisi seberang** (skrip `dev_ukur/mutan_cd.py S1..S5`):

| Kode | Berkas | Perubahan | Hasil (lolos/gagal) | Tes yang gagal (contoh) |
|---|---|---|---|---|
| S1 | ubin_khusus.gd | sisi seberang memakai tabel sel dekat | 18817/18 MATI | "scene rute: 49 wadah ubin ... dapat 33" (mode simpang seberang mati), pemasangan seberang |
| S2 | config.gd | sel seberang pertama di kolom trotoar, bukan rumput | 18829/6 MATI | "tabel sel seberang: config = JSON terpasang (P-6) = literal" |
| S3 | rute.tscn | dua tekstur seberang tertukar | 18833/2 MATI | "tekstur_simpang_seberang di rute.tscn sejajar tabel sel" |
| S4 | per_buka_02.json | simpang seberang pos 17 (pita memotong kavling rumah @14) | 16865/407 MATI (101 SCRIPT ERROR karena pustaka segmen tidak lengkap) | "semua berkas nyata lolos pemuat tanpa galat: ... pita 15.5 sampai 20.5 memotong kavling rumah seberang" |
| S5 | ubin_perumahan.py | ubin seberang tidak tersalin (`SIMPANG_SISI_DIPASANG = ['dekat']`) | uji_aset_simpang 165/17 MATI | "berkas ada di keluaran dan assets/: tile_perumahan_simpang_seberang_..." |

Total mutan bagian CD: 30 mati (C1-C5, D1-D20, S1-S5), 1 ekuivalen (D21).

### Gerbang akhir bagian CD (HEAD 35db641 + LOG)
- `godot --headless --import`: 0 baris ERROR/WARNING.
- `godot --headless --script res://tests/run_tests.gd 2>&1 | tee build/tests.log`: **18835 lolos, 0 gagal**; `python3 tools/cek_keluaran_tes.py build/tests.log`: lolos (0 peringatan).
- `godot --headless --path . --quit-after 2`: 0 baris ERROR/WARNING.
- 13 `tools/tests_cek/uji_*.py` exit 0 (`uji_aset_simpang` 214, `uji_aset_pasang_5b` 661, `uji_aset_pasang_gelombang1` 625 cek).
- Probe `probe_simpang_jendela.gd` dan `probe_sisi_dekat_jendela.gd` di empat ukuran: 0 keadaan tidak sesuai, 0 ERROR/WARNING (tangkapan iterasi 1 diperbarui).
- `git diff main` kosong untuk sistem gerak/skor/zona/tenggat/tabrakan/rintangan/misi/kondisi/ekonomi/save/`jalan_daur`/`medan_koran`/`penutup_pemain`/autoload.
- sha256 `user://save.json` asli sebelum dan sesudah semua tes, probe, mutan, dan perbandingan: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e`.
- Commit lanjutan: 35db641 (content: simpang seberang P-6, tes, uji, probe, tangkapan), commit LOG ini. Tidak di-push.


## Iterasi 1, bagian E (Dev)

Dikerjakan: AC-22 sampai AC-27 bagian E (SPEC D-1). Kode gameplay tidak diubah; hanya tes, dokumen, dan skrip ukur. Tidak ada BLOCKED.

### AC-22 Paket ekspor
- **Tes diperluas** (`tests/tes_export.gd`, commit 5011058): `JALUR_WAJIB_IKUT_5C` (SpriteFrames 68 animasi, PNG/JSON/.import jatuh, bangkit, berhenti, `.import`/JSON sheet kucing, `tile_perumahan.json`, `pose_kucing.gd`, `segmen_rute.gd`, `pemuat_rute.gd`, `route_builder.gd`, `kucing_misi.gd`, `loper_sprite.gd`) ikut diperiksa `_pelanggaran_preset` (ada di repo, tidak cocok exclude_filter); `_test_aset_5c_ikut_paket`: 40 PNG 5C (3 sheet pemain, sheet kucing, 2 ujung kerb, 18 simpang dekat, 16 simpang seberang dari `TesUbin.UBIN_5C`) punya `.import` Lossless tanpa mipmap dan tidak dikecualikan, `loper_agen_frames.tres` 68 animasi termasuk `jatuh_/terjerembab_/bangkit_/berhenti_<arah>` lima arah, JSON kucing `columns` 9 = lebar tekstur 414 / sel 46, `JALUR_TIDAK_ADA_5C` (ujung kerb sisi dekat, empat ubin simpang yang sama dengan jalan lurus) tidak ada, folder ubin memuat tepat 36 ubin simpang/ujung terdaftar. Dua contoh buruk preset baru (loper/* dan `pose_kucing.gd` dikecualikan) ditolak.
- **Pemindai rujukan** (`tests/tes_ubin.gd`): regex diperluas ke `simpang_*` dan `*_masuk_ujung` (alternatif ditulis lebih dulu supaya tidak terpotong `_masuk`), hanya nama `UBIN_5B`/`UBIN_5C` yang sah; dipindah ke `_rujukan_ubin_tak_dipasang` dengan tujuh contoh buruk sintetis (dua simpang tak dipasang, simpang `mulut_3`, dua `*_dekat_masuk_ujung`, `aspal_2`, `trotoar_dekat_masuk`) yang tertangkap dan 42 nama terpasang yang tidak tertangkap. Perubahan tes lama: hanya refactor pemindai ke fungsi pembantu (logika dan pengecualian lama sama); tidak ada angka lama diubah.
- **Paket nyata:** `godot --headless --path . --export-pack "Android" build/kring-uji.pck` exit 0, 0 baris ERROR/WARNING, **1.769.916 byte (1,77 MB)**, 697 berkas. Dimuat dari folder di luar repo (scratchpad) dengan `godot --headless --main-pack <repo>/build/kring-uji.pck --script <scratchpad>/cek_paket_5c.gd` (salinan skrip: `dev_ukur/cek_paket_5c.gd`): **155 cek lolos, 0 gagal**, 0 ERROR/WARNING. Isi: tidak ada `res://tests/`, `docs/`, `tools/`, `build/`, spike, `cek_render`, `warna_bayangan`; SpriteFrames 68 animasi, 20 animasi 5C dengan ukuran frame benar (jatuh/terjerembab/bangkit 140x88, berhenti 46x58; `bangkit_normal` 6 frame, `jatuh_kiri` 4); tiga PNG pemain dan sheet kucing 9 kolom dimuat; 36 ubin ujung/simpang (18 dekat, 16 seberang, 2 ujung) beserta remap `.import` dimuat; `aspal_1..3`, `*_dekat_masuk`, dua ubin simpang tak dipasang, polisi tidur, zebra tidak ada; `PemuatRute.muat_folder()` dari paket: 9 segmen tanpa galat, simpang `per_buka_01@3:dekat`, `per_buka_02@18:seberang`, `per_tengah_05@3:dekat`, `per_tutup_01@2:dekat`; rute hari 1 sah, 25 pelanggan, simpang `per_buka_02:simpang:seberang@18`, `per_tengah_05:simpang:dekat@3`; `rute.tscn` dari paket: 18 + 16 tekstur simpang dan dua tekstur ujung kerb terisi.

### AC-23 Regresi
- `run_tests.gd`: **19052 lolos, 0 gagal** (18835 sesudah CD + 217 cek baru bagian E dari `tes_export`/`tes_ubin`); pemeriksa lolos, 0 peringatan. Tidak ada angka tes lama yang diubah di bagian E.
- `git diff main` kosong untuk `throw_solver`, `skor_rute`, `zona_sasaran`, `tenggat_rute`, `bike_motion`, `tabrakan`, `rintangan_rute`, `mission_manager`, `rencana_misi`, `bike_condition`, `economy`, `data_save`, `jalan_daur`, `medan_koran`, `penutup_pemain`, `scripts/autoload/`.
- sha256 `user://save.json` asli sebelum bagian E, sesudah semua tes, ekspor, pemuatan paket, mutan, dan gerbang: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e`.

### AC-24 Rule (seluruh run, dicek ulang di bagian E)
- `git diff --name-only main` tanpa `.godot/`, `build/`, `builds/`, APK/AAB, keystore, `CHANGELOG.md`, `.release-please-manifest.json`; tidak ada tag dibuat.
- PNG yang berubah terhadap `main` selain berkas baru hanya `tests/data/ubin_potongan_5b.png` (dibuat ulang `uji_aset_pasang_5b.py --perbarui-referensi`, bagian CD); tidak ada PNG renderer diedit tangan.
- Gaya kode (static typing, `##` bahasa Indonesia, angka ajaib, hex di luar palet) dijaga cek gaya runner, lolos; sisi `seberang`/`dekat` di data dan kode; bagian E tidak menambah kode game.

### AC-25 Dokumen (commit 70ddc51, 05652a9, f0f4523)
- `docs/DATA_SCHEMA.md` 3: baris tabel `simpang`, contoh dari `per_tengah_05.json` dan `per_buka_02.json`, makna `pos`, mulut dan pita dari `config.gd` (D-3), `SimpangItem`/`simpang_di`, aturan penempatan, akibat geometri, isi set sekarang, butir validasi.
- `docs/ROUTE_DESIGN.md`: bagian baru 4c (simpang hiasan, pita, aturan, P-6 rumah `per_buka_02@18` dihapus, isi, frekuensi 100% bersimpang / 100% dekat / 56% seberang dari 100 rute hari, D-F2, D-F3); bagian 8 persimpangan dicoret: hiasan dulu (pemilik 2026-10-22), lalu lintas berbelok M3; aturan 5 batas sprite jatuh diperbarui ke 140x88 dan I2-F3.
- `docs/ART_DIRECTION.md`: 3.4 (berhenti: A-F3; jatuh/bangkit: verifikasi run 5C, A-F1/A-F2, I2-F3), 6.1 (baris tabrakan), 6.3 (paragraf terpasang run 5C: ujung kerb dan simpang; catatan 5A/5B "ditunda ke 5C" ditandai ditutup), 6.7 (pose kucing ditangkap, B-F1), 11 (butir Run 5C: P-1..P-6, D-2, keraguan HP), Changelog 2026-10-22 baru (menggantikan "belum dipakai/belum dipasang" di entri PR #51). Semua berstatus usulan, dinilai di HP.
- `tools/env_art/README.md` (`--salin` ujung kerb dan simpang, `uji_aset_simpang.py`), `tools/loper_art/README.md` (verifikasi offset pijak run 5C).
- `AGENTS.md`: paragraf perintah cepat (run 5C), perintah `probe_animasi_pemain_jendela.gd`, `probe_simpang_jendela.gd`, `uji_aset_simpang.py`, catatan `ubin_perumahan.py --salin`; peta repo baris Run 5C (`pose_kucing`, simpang di `segmen_rute`/`route_builder`/`ubin_khusus`/`tanah_daur`, entities, data, aset, tes baru).
- `.cursor/rules/00-project-core.mdc`: `bangun_frames.py` 50 -> 68 animasi, perintah `uji_aset_simpang.py` dan dua probe 5C.
- `docs/README.md`: status Run 5C, hasil uji HP 4A/4B/6A1/5A/5B belum ada per 2026-10-22, Fase 2/3/4/5/M2 belum dicentang; daftar tes dan alat.
- `docs/DEV_PHASES.md`: hanya catatan Run 5C di paragraf pembagian pemasangan; **tidak ada centang** (butir aset, Fase 2/3/4/5, M2).
- `docs/LOOP-DEV-QA.md`: **hanya tabel 6g** (baris 5B = di-merge PR #49; baris 5C = status run ini). Bagian 6i tidak disentuh.
- `docs/SETUP_ANDROID.md` **8.14** baru: 10 butir NEEDS-MANUAL SPEC + temuan A-F3 (butir 4), A-F4 (butir 2), B-F1 (butir 5), D-F2 dan D-F3 (butir 7), I2-F3 (butir 1), lembar hasil. Tidak mengklaim hasil uji HP apa pun.

### AC-26 Gerbang akhir iterasi 1 (HEAD f0f4523 + LOG)
- `godot --headless --import`: 0 baris ERROR/WARNING.
- `godot --headless --script res://tests/run_tests.gd`: exit 0, **19052 lolos, 0 gagal**; `python3 tools/cek_keluaran_tes.py build/tests.log`: lolos (0 peringatan).
- `godot --headless --path . --quit-after 2`: 0 baris ERROR/WARNING.
- 13 `tools/tests_cek/uji_*.py` exit 0: aset_gelombang1 352, aset_kucing 13, aset_lampu_pohon 183, aset_pasang_5b 661, aset_pasang_gelombang1 625, aset_simpang 214, bangun_frames 62, pemeriksa (lulus), sintesis_kondisi 55, lempar 111, misi 47, rute 90, sepeda 32. CI `.github/workflows/tes.yml` menjalankan ke-13-nya (termasuk `uji_aset_simpang.py`).
- Paket diperiksa (AC-22). Probe AC-8/AC-11/AC-21 dan `probe_sisi_dekat_jendela.gd` tidak diulang: tidak ada kode game atau aset berubah sejak gerbang CD (bagian E hanya tes dan dokumen).
- Satu proses Godot sekaligus; proses lama pid 26665 (bukan milik Dev) dibiarkan. HP/adb tidak disentuh. Tidak di-push.

### AC-27 Mutan bagian E
Skrip `dev_ukur/mutan_e.py` (satu perubahan, `run_tests.gd` penuh, dikembalikan `git checkout`/hapus berkas; `git status` sesudah tiap mutan hanya skrip ukur yang belum dikomit):

| Kode | Berkas | Perubahan | Hasil (lolos/gagal) | Tes yang gagal (contoh) |
|---|---|---|---|---|
| E1 | export_presets.cfg | `assets/sprites/loper/*` dikecualikan | 19020/32 MATI | "loper_agen_frames.tres harus ikut paket tetapi cocok dengan exclude_filter" |
| E2 | export_presets.cfg | `tile_perumahan_simpang_seberang_lengan_mulut_1.png` dikecualikan | 19032/20 MATI | "...simpang_seberang_lengan_mulut_1.png tidak dikecualikan filter preset" (`_test_aset_5c_ikut_paket`) |
| E3 | assets/sprites/tiles/perumahan/ | ubin simpang tak dipasang `simpang_dekat_aspal_dekat_depan_2` ikut ada | 19050/5 MATI | "ubin tak dipasang tidak ada di repo", "folder ... tepat 36 ubin simpang/ujung, dapat 37" |
| E4 | scripts/config.gd | komentar merujuk `tile_perumahan_simpang_dekat_aspal_dekat_depan_2` | 19051/1 MATI | "tidak ada rujukan ke aset yang belum dipasang" (hanya pemindai yang diperluas yang menangkapnya) |
| E5 | scenes/rute/rute.tscn | komentar merujuk `tile_perumahan_trotoar_dekat_masuk_ujung` | 19050/2 MATI | "rute.tscn memuat tile_perumahan_trotoar_dekat_masuk_ujung" |
| E6 | loper_agen_bangkit.png.import | `compress/mode=0` jadi `1` | 19049/3 MATI | "loper_agen_bangkit.png: impor Lossless" |
| E7 | mission_kucing_sheet.json | `columns` 9 jadi 8 | 19049/3 MATI | "sheet kucing 9 kolom: JSON columns 8, lebar tekstur 414 = 9 x sel 46" |

7 mutan E mati, 0 hidup. **Total mutan run (Dev iterasi 1): 59 mati** (A1-A14, B1-B8, C1-C5, D1-D20, S1-S5, E1-E7), 2 ekuivalen ditarik dengan bukti (A15, D21). Cakupan daftar AC-27 SPEC terpenuhi (bangkit/berhenti/lempar/pijak: A; kucing: B; ujung kerb: C; simpang, validasi, RNG, salin, `.import`: D, S; paket dan pemindai: E).

### Commit bagian E
5011058 (test: paket ekspor dan pemindai AC-22), 70ddc51 (docs: DATA_SCHEMA dan ROUTE_DESIGN), 05652a9 (docs: ART_DIRECTION dan README alat), f0f4523 (docs: status, SETUP_ANDROID 8.14, AGENTS, rule), commit LOG ini (+ `dev_ukur/mutan_e.py`, `dev_ukur/cek_paket_5c.gd`). Tidak di-push.


## Iterasi 1, QA

QA independen (konteks segar), HEAD ebc0723, diff `git diff main...HEAD` (20 commit, 517 berkas). Klaim Dev diperlakukan sebagai klaim; semua angka di bawah dari perintah yang QA jalankan sendiri. Satu proses Godot sekaligus; proses lama pid 26665 (bukan milik QA) dibiarkan. HP/adb tidak disentuh. Tidak di-push. Skrip QA sementara ada di scratchpad sesi (tidak dikomit).

### Gerbang (QA sendiri)
- `godot --headless --import`: exit 0, **0** baris ERROR/WARNING.
- `godot --headless --script res://tests/run_tests.gd 2>&1 | tee build/tests_qa.log`: **19052 lolos, 0 gagal** (93 detik); `python3 tools/cek_keluaran_tes.py build/tests_qa.log`: `pemeriksa: lolos (19052 lolos, 0 gagal, 0 peringatan)`.
- `godot --headless --path . --quit-after 2`: exit 0, 0 baris ERROR/WARNING.
- 13 `tools/tests_cek/uji_*.py` exit 0: aset_gelombang1 352, aset_kucing 13, aset_lampu_pohon 183, aset_pasang_5b 661, aset_pasang_gelombang1 625, aset_simpang 214, bangun_frames 62, pemeriksa 16 kasus 0 menyimpang, sintesis kondisi 55, lempar 111, misi 47, rute 90, sepeda 32. `.github/workflows/tes.yml` memuat ke-13-nya (termasuk `uji_aset_simpang.py`).
- Paket: `godot --headless --path . --export-pack "Android" build/kring-uji-qa.pck` exit 0, 0 ERROR/WARNING, 1.769.916 byte. Dimuat dari folder di luar repo dengan skrip QA sendiri (`--main-pack`): 697 berkas; 0 berkas `tests/`, `docs/`, `tools/`, `build/`, spike, `cek_render`; tidak ada `aspal_1..3` atau `*_dekat_masuk*`; 36 ubin ujung/simpang dimuat sebagai tekstur; `loper_agen_frames.tres` 68 animasi (`bangkit_kiri` 6 frame, `berhenti_kanan` ada); sheet kucing lebar 414 (9 x 46); `PemuatRute.muat_folder()` 9 segmen tanpa galat, simpang `per_buka_01@3 dekat`, `per_buka_02@18 seberang`, `per_tengah_05@3 dekat`, `per_tutup_01@2 dekat`; `rute.tscn` dimuat.
- Kebersihan repo: tidak ada `.godot/`, `build/`, `builds/`, APK/AAB, keystore, `CHANGELOG.md`, `.release-please-manifest.json` di diff; branch bukan `main`; commit berformat `<tipe>: <ringkasan>` bahasa Indonesia (tipe `feat/fix/test/docs/content`, sah menurut `git-workflow.mdc`), semua 20 commit membawa baris Claude-Session; `.uid` berkas skrip baru dikomit; `docs/.gdignore` membuat skrip `dev_ukur/*.gd` tidak diimpor Godot. Satu-satunya PNG lama yang berubah: `tests/data/ubin_potongan_5b.png` (referensi dari skrip, AC-14).
- sha256 save asli sebelum gerbang, sesudah tes, sesudah 12 mutan, dan sesudah semua probe: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e` (tetap).

### Pemeriksaan khusus
- **Golden P-6 (skrip banding QA sendiri, bukan `banding_p6.gd`):** sembilan berkas segmen `main` diekstrak ke folder sementara; rute dibangun dengan pustaka `main` dan HEAD lalu dibandingkan per bidang (rumah lengkap: id, segmen, pos, maju, sisi, jenis, pelanggan_boleh, pelanggan, pemberi_tip; objek; titik misi data; dekor; daftar pelanggan; urutan dan awal segmen; panjang; koran awal; pemberi tip; `TenggatRute.detik_tenggat`). 60 seed dev (20261016 + 7 i): **31 berubah, perbedaan lain 0**; 600 hari (`SeedHari.rute(1..600)`): **311 berubah, perbedaan lain 0**. Satu-satunya perbedaan di semua rute = hilangnya rumah `per_buka_02@18|seberang|limasan|pelanggan_boleh false|bukan pelanggan|bukan pemberi tip`. Simpang di rute hanya empat id yang diharapkan. Rencana kucing P1 berubah di 289/600 hari (QA-003). Persen 100 rute hari diulang QA: bersimpang 100, dekat 100, seberang 56 (sama dengan literal tes dan ROUTE_DESIGN).
- **Data:** diff empat berkas segmen hanya menambah `simpang` dan (P-6) menghapus satu baris rumah `per_buka_02@18`; tidak ada dekor, objek, atau rumah lain bergeser; tidak ada segmen baru.
- **Sistem terlarang:** `git diff main...HEAD` kosong untuk `throw_solver`, `skor_rute`, `zona_sasaran`, `tenggat_rute`, `bike_motion`, `tabrakan`, `rintangan_rute`, `mission_manager`, `rencana_misi`, `bike_condition`, `economy`, `data_save`, `jalan_daur`, `medan_koran`, `penutup_pemain`, `efek_kondisi`, `hasil_rute`, `loper_anim`, `scripts/autoload/`.
- **config.gd:** sembilan konstanta baru, semua satu baris literal (`const NAMA: Tipe = literal`), bertipe, berkomentar `##` dan satuan; konstanta tampilan, bukan angka tuning, jadi `BALANCING.md` tidak perlu berubah. Komentar `RUTE_SIMPANG_SEL_SEBERANG` basi (QA-001).
- **Tes lama yang diubah:** daftar Dev (AC-1 butir 1-13, CD butir 1-18) dicocokkan dengan diff. Semua berasal dari aset/fitur baru (68 animasi, BERHENTI, sheet 9 kolom, ujung kerb mengganti oracle baris maju + 1, wadah ubin bertambah, golden P-6 dari skrip). Tidak ada tes yang dihapus atau di-skip; `tes_ubin_5b._periksa_tanah` hanya menerima `simpang_dekat_*` di baris pita sisi dekat rute (sel diuji literal di `tes_simpang`), bukan pelonggaran umum. `SIDIK_EMAS_GERAK` berubah karena BERHENTI (PR #51, sudah di `main`), bukan run ini. Tes misi, rintangan, tenggat, skor, hari tidak berubah (`git diff` kosong). Tidak ditemukan pelemahan tes.
- **Dokumen:** `DEV_PHASES.md` hanya kalimat catatan di paragraf pembagian, tidak ada `[x]` baru; `LOOP-DEV-QA.md` hanya dua baris tabel 6g (5B, 5C), Bagian 6i tidak ada di diff; SETUP_ANDROID 8.14 semua butir `[ ]`, lembar hasil kosong, menyatakan "belum diuji"; README/ART_DIRECTION/ROUTE_DESIGN menyebut "usulan, belum diuji di HP". Tidak ada klaim hasil uji HP.

### Mutan QA (12, dipilih sendiri; 10 bukan dari daftar Dev)
Tiap mutan satu perubahan, `run_tests.gd` penuh (Q11 juga `uji_aset_simpang.py` dan `uji_aset_pasang_5b.py`), lalu `git checkout -- <berkas>`; `git status` bersih sesudah tiap mutan.

| Kode | Bagian | Berkas | Perubahan | Hasil | Tes yang gagal (contoh) |
|---|---|---|---|---|---|
| Q1 | B | pose_kucing.gd | `floori(t * fps + tol)` jadi `roundi(...)` | 19050/2 MATI | "22 kasus literal ... tangkap p0.5 t0.3333: 17 (harap 16)" |
| Q2 | B | kucing_misi.gd | `PoseKucing.frame(jenis, progres, detik)` jadi `(..., 0.0)` (pose tidak bergerak) | 19050/2 MATI | "berganti tiap 20 langkah (3 fps)" |
| Q3 | A | loper_sprite.gd | bangun mulai frame 1, bukan 0 | 19034/18 MATI | "arah kiri: pijak tetap ... urutan" |
| Q4 | D | rute_main.gd | baris `_tanah.atur_simpang(...)` dibuang (simpang tidak tergambar) | 19051/1 MATI | "simpang rute dev dan rute bersimpang seberang: sel pita = tabel literal (286 salah)" |
| Q5 | D | ubin_khusus.gd | `himpunan_baris_simpang` melewatkan baris pita terakhir | 19038/14 MATI | "himpunan baris: pos 10 dekat = 9 .. 13" |
| Q6 | D | segmen_rute.gd | `bentuk.end.y <= pita.x` jadi `<` (tepi awal bersentuhan ditolak) | 17082/407 MATI (101 SCRIPT ERROR) | "per_buka_02 ... pita 16.5 sampai 21.5 memotong kavling rumah seberang di pos 14" |
| Q7 | D | segmen_rute.gd | `pita_bertumpuk` `and` jadi `or` | 16570/928 MATI (1543 SCRIPT ERROR) | "seed 1 dibangun dua kali ..." |
| Q8 | D | config.gd | `RUTE_SIMPANG_MULUT_AWAL_UBIN` -0,5 jadi -1,0 | 19050/2 MATI | "tepi mulut = -y_mulut[1] / 32 = -0,5" |
| Q9 | D | route_builder.gd | `mulut_awal_ubin = maju + MULUT_AWAL` jadi `maju - MULUT_AWAL` | 19051/1 MATI | "20 rute: simpang = data segmen dibaca ulang dari berkas" |
| Q10 | D | ubin_khusus.gd | `kolom_simpang` LENGAN dan RUMPUT tertukar | 19031/21 MATI | "sel_simpang(x 2.5, baris 13) = (2, 1)" |
| Q11 | C | `tile_perumahan_rumput_seberang_masuk_ujung.png.import` | `mipmaps/generate=true` | MATI: uji_aset_simpang 213/1, uji_aset_pasang_5b 660/1, run_tests 19050/2 | "rumput_seberang_masuk_ujung: impor Lossless, tanpa mipmap" |
| Q12 | E | export_presets.cfg | `tile_perumahan.json` dikecualikan | 19048/4 MATI | "tile_perumahan.json harus ikut paket" |

12 mati, 0 hidup. Catatan: Q4 hanya dibunuh satu cek scene (cukup, tetapi satu-satunya penjaga sambungan `RuteMain` -> `TanahDaur`).

### Tangkapan yang dilihat (probe di jendela asli, `shots/qa1/`)
Empat probe di 2340x1080 dan 1600x720 (`probe_animasi_pemain_jendela`, `probe_misi_jendela`, `probe_simpang_jendela`, `probe_sisi_dekat_jendela`): masing-masing exit 0, 0 baris ERROR/WARNING, **"0 keadaan tidak sesuai"**; 190 PNG. Dilihat dengan Read (beberapa dipotong/diperbesar oleh QA):
- **Jatuh lima arah** (`2340x1080_animasi_arah_{kiri,serong_kiri,normal,serong_kanan,kanan}_{jatuh,terjerembab,bangkit}`, kisi 5x3): kelima arah jelas berbeda (rebah ke kiri atas, serong, ke depan, serong kanan, ke kanan bawah), sepeda terlempar sesuai arah, piksel tajam, pijak tampak di titik yang sama antar pose. Terbaca baik. Arah kanan: kepala terpotong panel KECEPATAN di 2340x1080 (QA-002).
- **Tabrakan nyata serong kiri** (jatuh, terjerembab, bangkit tengah, bangkit akhir, bangun): arah serong kiri tertahan sampai bangun (A-F2); bangkit akhir dan bangun sama di sekitar pemain (A-F1). Frame jatuh pertama banyak tertutup anjing (posisi tabrakan), terjerembab terbaca.
- **Berhenti dan kucing ditangkap** (`2340x1080_animasi_berhenti_tangkap_kucing`, `_misi_tangkap_progres`, `_frame2`): pemain diam kaki turun, kucing duduk dengan bar progres dan kilau; diperbesar, kucing tampak duduk tenang. Di titik tahan probe misi badan pemain menutup kucing (B-F1 benar). Kucing kecil di layar 2340: keterbacaan "dielus" = NEEDS-MANUAL.
- **Ujung kerb** (`2340x1080_simpang_ujung_kerb`): kerb dan lajur hijau berhenti rapi di jalan masuk beton di bawah mobil seberang, tanpa potongan kerb.
- **Simpang dekat** (`2340x1080_simpang_dekat_per_tengah_05`): jalan samping ke kanan bawah, sudut kerb siku, tembok dekat berhenti sebelum mulut dan rumah dekat berikutnya sesudahnya; tanpa celah transparan.
- **Simpang seberang** (`1600x720_simpang_seberang_lengan_tepi`, `2340x1080_animasi_arah_kanan_terjerembab` yang kebetulan di mulut seberang): jalan samping ke kiri atas di antara dua rumah, lengan sampai tepi kiri layar, rumah tetangga utuh.
- **Kidal** (`2340x1080_simpang_kidal`, `_animasi_kidal_jatuh`): HUD tercermin, simpang dan jatuh tampil benar.
Semua masih usulan; keterbacaan di layar HP = NEEDS-MANUAL (SETUP_ANDROID 8.14).

### Pemeriksaan AC
| AC | Status | Bukti QA |
|---|---|---|
| AC-1 | PASS | Baseline dan 13 butir perubahan tes PR #51 tercatat; dicocokkan dengan diff |
| AC-2 | PASS | `tes_animasi_5c` lulus di suite QA; Q3 mati; tangkapan lima arah pijak tetap |
| AC-3 | PASS | `_test_bangkit_ke_kayuh_piksel` lulus; Q3 mati; bangkit akhir = bangun di tangkapan |
| AC-4 | PASS | tes celah lulus; mutan Dev A1-A10 tercatat; kode `loper_anim.gd` tidak berubah di run ini (PR #51) |
| AC-5 | PASS | `tabrakan.gd` tanpa diff, tes lama tabrakan lulus tanpa diubah; tes jeda/Main lagi/lempar dari BERHENTI lulus |
| AC-6 | PASS (+ Nit A-F3 NEEDS-MANUAL) | tangkapan berhenti di titik tangkap |
| AC-7 | PASS (I2-F3 tetap DEFERRED) | angka tercatat; perbaikan bukan satu konstanta |
| AC-8 | PASS (+ QA-002 Minor NEEDS-MANUAL) | probe 2 ukuran 0 tidak sesuai, 0 ERROR/WARNING |
| AC-9 | PASS | `PoseKucing` murni; Q1, Q2 mati |
| AC-10 | PASS | `uji_aset_kucing.py` 13 lolos; tes misi lama tanpa diff |
| AC-11 | PASS | probe misi 2 ukuran 0 tidak sesuai; tangkapan frame 1/2 dan kidal |
| AC-12 | PASS | `uji_aset_simpang.py`, `uji_aset_pasang_5b.py` lulus; Q11 mati; paket tanpa `*_dekat_masuk`/`aspal_N` |
| AC-13 | PASS | `jalan_daur.gd` tanpa diff; tes literal ujung kerb lulus |
| AC-14 | PASS | 0 piksel, kontrol 22; referensi dari skrip |
| AC-15 | PASS | tes negatif lulus; Q6, Q7 mati |
| AC-16 | PASS | banding QA sendiri: hanya rumah `per_buka_02@18`; Q9 mati; `simpang_di` satu fungsi baca tanpa RNG |
| AC-17 | PASS | 3 dekat + 1 seberang; persen 100/100/56 diulang QA |
| AC-18 | PASS | Q4, Q5, Q10 mati; tangkapan lengan sampai tepi |
| AC-19 | PASS | `uji_aset_simpang.py` 214 lolos (0 piksel kedua sisi), tes referensi Godot lulus |
| AC-20 | PASS | `_test_scene_gerak_identik`, `_test_medan_identik` lulus; `bike_motion`/`medan_koran` tanpa diff |
| AC-21 | PASS | probe simpang dan sisi dekat 2 ukuran, 0 tidak sesuai |
| AC-22 | PASS | paket diperiksa QA dari luar repo; Q12 mati |
| AC-23 | PASS | 19052 >= 18318 + baru, 0 gagal; daftar sistem tanpa diff; sha256 save tetap |
| AC-24 | PASS (+ QA-001 Nit) | cek gaya runner lolos; config satu baris literal; tekstur dari `@export`; tanpa keystore/APK/`.godot/` |
| AC-25 | PASS | dokumen sesuai; tidak ada centang, tidak ada klaim HP; 6g saja |
| AC-26 | PASS | gerbang QA hijau |
| AC-27 | PASS | Dev 59 mati + 2 ekuivalen beralasan; QA 12 mati, 0 hidup |

### Putusan QA iterasi 1
**PASS.** Semua gerbang hijau; 0 Blocker, 0 Major. Temuan baru: QA-002 Minor (NEEDS-MANUAL), QA-001 Nit (OPEN, komentar), QA-003 Nit (OPEN, catatan LOG). Diverifikasi: A-F1, A-F2, C-F1, D-F1. A-F3 diterima sebagai NEEDS-MANUAL. NEEDS-MANUAL untuk laporan akhir: SETUP_ANDROID 8.14 butir 1-10, ditambah QA-002 (kepala pemain jatuh ke kanan tertutup panel bawah di layar 19,5:9). Fase 5, 2, 3, 4, dan M2 tidak boleh dicentang sebelum uji HP pemilik.
