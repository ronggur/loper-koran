# Loop Log — 20261013-fase1a-gerak
Scope: Run 1A Fase 1, logika gerak inti (BikeMotion, rem, meluncur, stamina, lateral analog dengan batas, pause, laju kayuh, sprite meluncur/rem)  ·  Branch: feat/fase1a-gerak  ·  Mulai: 2026-10-13  ·  Godot: 4.7.2.stable.official.ed1daf0bf

## Status: IN_PROGRESS   (iterasi saat ini: 1/2)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 1 | AC-1 sampai AC-15: `BikeMotion` (rem, meluncur, stamina/lelah, lateral berbatas, jeda via `JedaSim`), pose dan `pedal_rate` di `LoperAnim`, SpriteFrames 48 animasi, bar stamina + LELAH, busur rem `WARN`, tes murni dan scene, 40 mutan nyata (semua tertangkap), bukti visual 2340x1080, dokumen AC-14. 7 commit, tidak push | ✅ import 0 ERROR/WARNING; 3886 lolos 0 gagal; `--ketat` lolos; uji_pemeriksa 16/0; uji_bangun_frames 41/0; quit-after 0; klon bersih sama | | | |

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## NEEDS-MANUAL (uji di HP)
Daftar awal ada di SPEC bagian "Butuh uji perangkat nyata". Dev dan QA menambah langkah di sini.

Tambahan Dev (iterasi 1; juga di `docs/SETUP_ANDROID.md` 8.1):
- [ ] Busur rem `WARN` di bawah cincin terbaca saat knob menutupi tengahnya (busur digambar di atas knob); bandingkan dengan cincin biasa.
- [ ] Stick bawah tanpa rem paling dalam sekitar 90% (tujuan sekitar 1,65 u/d); 1,5 u/d tidak lagi tercapai tanpa rem. Apakah jarak antara "melambat paling pelan" dan "rem" terasa wajar.
- [ ] Toleransi pose meluncur 0,05 u/d: saat stick hanya sedikit ke bawah (15-30%), sprite langsung melambat 4 fps tanpa sempat meluncur; apakah itu terasa benar atau perlu meluncur sesaat.
- [ ] Lelah: di 4,5 u/d stamina tetap 0 selama stick ditahan ke atas (disengaja, -4/d); pemain harus melonggarkan stick. Apakah tulisan LELAH cukup menjelaskan kenapa sepeda tidak bisa ngebut.
- [ ] Laju kayuh `pedal_rate` maksimum 1,5: saat lelah turun dari 6,0 ke 4,5 kayuh cepat sempat berputar 1,33x; saat santai di atas 4,5 (sesudah melepas ngebut) kayuh santai bisa sampai 1,5x. Terlihat wajar atau "kaki ngebut".
- [ ] Jeda di desktop/editor: kehilangan fokus jendela juga menjeda (FOCUS_OUT). Di HP: tarik bilah notifikasi saat ngebut lalu tutup: posisi, stamina, kecepatan tidak melompat; sprite tetap beranimasi selama jeda (pemutar bawaan tidak dihentikan, hanya simulasi).

## Keputusan & catatan
- Keputusan pemilik 2026-10-13: pindah sisi analog bebas (bukan kunci jalur); sprite stick bawah ikuti fisika (D-7); PR #19 di-merge sebelum run; uji HP Fase 0 lolos tanpa angka yang diubah.
- RUN_ID diganti dari 20261010 ke 20261013 (tanggal mulai, LOOP-DEV-QA 6b).
- A54 tidak tersambung saat persiapan (`adb devices` kosong, 2026-10-13); dicek ulang setelah QA.

## Catatan Dev

### Dev (iterasi 1)

Lingkungan: macOS (Apple M4, OpenGL 4.1 Metal), `godot --version` = `4.7.2.stable.official.ed1daf0bf`, Python 3 stdlib. Branch `feat/fase1a-gerak` (dicek `git branch --show-current`), 7 commit Dev sesudah commit SPEC/LOG orchestrator + commit LOG ini, tidak ada commit di `main`, **tidak push**. Tidak menyentuh HP (tidak ada perintah `adb`), tidak mengunduh, tidak mengubah Editor Settings, tidak membangun APK. Tidak ada `BLOCKED`. `DEV_PHASES.md` dan `ROADMAP.md` tidak diedit.

Commit (urut): `be27680` art: SpriteFrames 48 animasi; `cd7c74f` feat: `BikeMotion` + `LoperAnim` + `JedaSim` + Config + BALANCING + tes murni; `4e05da6` feat: kabel scene, HUD stamina, busur rem, jeda + tes scene; `d13a283` test: probe gerak + tangkapan layar; `3a628fc` docs: AGENTS, aturan inti, README, SETUP_ANDROID 8.1; `3fc1bbd` fix: stamina tepat di titik patah (hasil mutan M16 yang hidup); `f6af841` test: tangkapan layar ulang dari kode akhir; lalu commit LOG ini. Catatan jujur: commit `be27680` dan `cd7c74f` berdiri sendiri **tidak** lolos tes (perubahan aset, logika, dan scene saling bergantung; runner di `cd7c74f` sudah merujuk `TesGerakScene` yang baru masuk di `4e05da6`). Mulai `4e05da6` semua gerbang hijau; gerbang lengkap dijalankan di `HEAD` dan di klon bersih.

#### Bukti per AC

| AC | Bukti (file, tes, perintah) |
|---|---|
| AC-1 | Lihat "Gerbang". Klon bersih (`git clone --branch feat/fase1a-gerak`, scratchpad): import exit 0, 0 ERROR/WARNING, `git status --porcelain -uall` 0 baris (`.import` dua PNG baru, `.uid` `bike_motion`, `jeda_sim`, `tes_gerak`, `tes_gerak_scene`, `probe_gerak_jendela` ter-commit; `bike_drive.gd` + `.uid` dihapus). Diff terhadap `main`: 0 berkas keystore/APK/AAB/`.godot/`/`build/`/`builds/`. |
| AC-2 | `scripts/systems/bike_motion.gd` (`Keadaan`, `Hasil`, `langkah`, `kecepatan_tujuan_ud`, `syarat_rem`, `tahan_cukup`, `laju_stamina*`, `jeda`). `tests/tes_gerak.gd` `_test_kecepatan` (netral 3,0, atas 0,5 = 4,5, atas penuh 6,0, bawah penuh tujuan 1,5 sebelum rem, naik 3,0 dan turun 2,0 u/d2, sapuan tidak melewati tujuan untuk dt 0,016..100, jarak tepat termasuk dt 100 = 598,5 ubin), `_test_masukan_aneh_dan_murni` (dt 0/-1/NaN/INF/-INF tidak mengubah keadaan; stick NaN = netral, (5,5) = (1,1), (0,-7) = (0,-1); keadaan NaN/di luar jangkauan dibersihkan; masukan tidak berubah dan hasil objek baru; 2000 langkah acak seed tetap: deterministik dan aman). |
| AC-3 | `_test_rem_ambang` (0,899 tidak pernah, 0,90 ya, tepat di ambang efektif ya = inklusif, lewat Vector2 presisi tunggal, NaN), `_test_rem_tahan` (0,249 belum, 0,25 ya; 14 lawan 15 langkah 1/60; lepas, naik sesaat ke 0,85, samping, atas memutus hitungan), `_test_rem_berhenti_dan_lepas` (5,0 u/d2, jarak henti 0,9 ubin, tetap 0 selama ditahan, di bawah 1,5; lepas: rem padam, naik 3,0 u/d2), `_test_rem_diagonal` (bawah 0,85 + samping 0,5 dan 45 derajat penuh tidak rem; jari bawah penuh dengan geser datar 8 px lewat `StickMap` = bawah 0,975 rem), `_test_independen_dt` (skenario dt 1/30 lawan 1/240: kecepatan dan stamina galat < 1e-6, jarak < 1e-4; satu langkah 0,35 detik = 35 langkah 0,01). |
| AC-4 | `_test_stamina_laju` (3,0/4,5/6,0 = +2/-4/-12, 3,75 = -1, 5,25 = -8, monoton, +15 saat stick bawah dan saat rem, jepit 0..100, rampa naik dan turun tepat), `_test_stamina_durasi` (ngebut dari penuh mulai santai habis 8,97 detik; cepat 25,4; dari 0 meluncur penuh 6,67; invarian prinsip 1: santai tidak menguras, ngebut 20 detik lelah dan <= 4,5), `_test_lelah` (menyala tepat di 0 bukan di 0,3; tujuan 4,5 turun 2,0 u/d2; 29,99 masih lelah, 30 padam; 10 -> 12 masih lelah; sprite cepat_normal; padam sesudah sekitar 2 detik meluncur). |
| AC-5 | `_test_lateral` (datar x 3,0 u/d; jepit +-1; `lateral_ud` 0 terhalang dan 0,5 saat sebagian; bebas dari tepi seberang; diagonal maju + seberang satu langkah = `cepat_serong_kiri`; geser saat berhenti dengan rem = `rem_kanan`). Kidal: `tests/tes_gerak_scene.gd` `_test_kidal_rem` (geser ke kiri layar tetap lateral negatif). Penjaga kiri/kanan lama tetap lolos (tidak ada string sisi baru; `NAMA_POSE` hanya `meluncur`/`rem`). |
| AC-6 | `scripts/systems/loper_anim.gd`: `Pose {KAYUH, MELUNCUR, REM}`, `pose_dari_gerak`, `tingkat_sprite` (lelah), `nama_animasi_pose`, `tingkat_lempar`, `kecepatan_nominal_ud`, `pedal_rate`. Tes `_test_pose` (tabel: rem di kecepatan > 0 dan = 0, meluncur, batas toleransi 0,99/1,01, di tujuan, di bawah tujuan, stick netral/atas tidak meluncur, NaN, jepit lelah, lempar santai), `_test_pose_dari_langkah` (11 kasus lewat `BikeMotion` termasuk arah serong per pose; urutan meluncur -> melambat sekali ganti; 3000 langkah acak: semua nama ada di SpriteFrames), `_test_pedal_rate` (nominal = 1, setengah = 0,5, 0 = 0, jepit 1,5, meluncur/rem = 1, dari berhenti ke ngebut = v/6 monoton). `LoperSprite.pose` di `tests/tes_sprite.gd` `_test_loper_sprite_pose` (5 arah x 4 tingkat x 2 pose, fps 4/8, frame dijaga, lempar dari rem/meluncur = santai). |
| AC-7 | `tools/loper_art/bangun_frames.py` (+2 sumber setelah lempar, id `4_meluncur`, `5_rem`), `assets/sprites/loper/loper_agen_{meluncur,rem}.{png,json,png.import}`, `.tres` 48 animasi, 192 AtlasTexture, load_steps 198; 38 animasi dan 152 sub_resource lama identik byte demi byte (dibandingkan sebelum menulis). `uji_bangun_frames.py` 41 pemeriksaan (48 animasi, loop 18 false/30 true, fps 4 = 10, 8 = 10, urutan meluncur/rem sesudah lempar, 5 jenis sumber rusak meluncur/rem baru ditolak, 11 berkas deterministik). `tes_sprite.gd` `_test_aset_dan_frames` (5 sheet byte-identik, `.import` Lossless tanpa mipmap tanpa VRAM, region/fps/loop/baris, nama `meluncur_<arah>`/`rem_<arah>`). `run_tests.gd` 48 nama dari `LoperAnim` = 48 animasi (tidak ada yatim). |
| AC-8 | `scripts/systems/jeda_sim.gd` + `JalanUji._notification`/`perbarui` + `SepedaUji.jeda` (`BikeMotion.jeda`). Murni: `_test_jeda_sim` (PAUSED/FOCUS_OUT/RESUMED/FOCUS_IN, notifikasi lain, `dt_efektif`, urutan Android, `BikeMotion.jeda`). Scene: `_test_jeda` (dua pasangan FOCUS_OUT/FOCUS_IN dan PAUSED/RESUMED: stick dan swipe dilepas, lempar ditutup, `perbarui` dan `_process` dengan dt 1/60, 0,1, 5, 100 tidak mengubah kecepatan, jarak, stamina, lama tahan, dorongan; langkah pertama sesudah lanjut dt 0 walau diminta 0,1; langkah berikutnya normal), `_test_jeda_di_tengah_tahan_rem` (0,2 detik tahan, jeda, lanjut, jari baru 0,1 detik belum rem, 0,25 rem; jeda saat rem aktif memadamkan rem dan busur). |
| AC-9 | `scenes/ui/hud_dev.tscn` (+`BarisStamina`/`LabelStamina`/`LabelLelah`/`BarStamina` di panel bawah yang sama), `scripts/ui/hud_dev.gd` (`tampilkan_stamina`), `bar_kecepatan.gd` (+`warna_isi`), `kontrol_touch.gd` (`atur_rem`, busur `PikselLingkaran.di_busur_bawah`, `WARN`), `translations/ui.csv` (+`HUD_STAMINA`, `HUD_LELAH`; `.translation` hasil impor ter-commit). Tes `_test_hud_stamina_dan_bar` (posisi di bawah bar kecepatan, lebar sama, tinggi 7, kunci terjemahan, ACCENT penuh dan tepat 30, FAIL di 29,9, LELAH tampil hanya saat lelah, bar kecepatan 0), `_test_busur_rem` (busur = semua piksel cincin di seperempat bawah, simetris), `_test_kidal_rem` (panel kecepatan + stamina pindah sisi bersama). |
| AC-10 | `tests/tes_gerak_scene.gd` lewat `Input.parse_input_event` di viewport 780x360 skala x3: `_test_rem_di_scene` (14 langkah meluncur, 15 rem + busur, berhenti dan jarak tetap, lepas: busur hilang, santai lagi; bawah 0,2 detik tidak rem), `_test_meluncur_lalu_melambat` (dari ngebut, laju kayuh ikut kecepatan), `_test_dua_jari_rem_dan_meluncur` (swipe saat rem = `lempar_kanan_santai_normal`, rem dan stick tetap aktif, kembali ke `rem_normal`; saat meluncur = `lempar_kiri_santai_normal`, kembali ke `meluncur_normal`), `_test_stamina_di_scene` (bar turun, FAIL < 30, LELAH, 4,5 + `cepat_normal`, pulih), `_test_kidal_rem`. |
| AC-11 | Lihat "Mutan nyata": 40 mutan, 40 tertangkap, 0 hidup sesudah perbaikan `3fc1bbd`. |
| AC-12 | Penjaga lama lolos untuk semua berkas baru: tab, static typing, `##` bahasa Indonesia, tanpa angka literal di `systems/`/`entities/`/`ui/` selain 0, 1, 2, -1, -2 (semua angka baru di Config satu baris, `ConfigParser` membaca semuanya: "parser membaca semua konstanta Config"), tanpa hex di luar `palette.gd`, tanpa `Color.X`, teks pemain lewat kunci. Node tipis: `SepedaUji` hanya menyimpan `Keadaan` dan meneruskan hasil. |
| AC-13 | `tests/probe_gerak_jendela.gd`, 8 tangkapan layar + 5 lembar di `docs/loop/20261013-fase1a-gerak/shots/` (lihat "Bukti visual"). |
| AC-14 | BALANCING 2 (paragraf `BikeMotion` menggantikan "Rumus gerak di run 0B", tabel angka baru), 3 (rumus stamina, lelah, durasi), 10 (2026-10-13), ART_DIRECTION 3.4 + changelog, `rem_meluncur/README.md` (status dipakai, aturan pose), `docs/design/character/README.md`, `tools/loper_art/README.md` (48), `AGENTS.md`, `.cursor/rules/00-project-core.mdc` (48), `docs/README.md` (status run 1A, peta), `docs/SETUP_ANDROID.md` 8.1 (uji Run 1A). Dokumen aset di commit art, BALANCING di commit Config/logika, sisanya di commit docs (lihat "Pilihan di luar SPEC" 7). |
| AC-15 | Commit di atas, format `<tipe>: <ringkasan>` bahasa Indonesia dengan body alasan; `main` tidak berubah; tidak push. |

#### Pilihan yang saya ambil di luar SPEC (bisa ditolak di review)

1. **Toleransi presisi rem di Config** (`REM_AMBANG_TOLERANSI` 1e-6, `REM_TAHAN_TOLERANSI_DETIK` 1e-6): Vector2 berpresisi tunggal menyimpan 0,90 sebagai 0,8999999762 dan 15 x 1/60 tidak tepat 0,25, jadi tanpa toleransi "0,90 rem" dan "0,25 rem" gagal. Pola sama dengan `SPRITE_SUDUT_TOLERANSI_DERAJAT`. Mutan `>=` -> `>` tetap tertangkap lewat tes tepat di ambang efektif.
2. **Toleransi pose meluncur 0,05 u/d** (`POSE_MELUNCUR_TOLERANSI_UD`, usulan): SPEC meminta "toleransi kecil di Config" tanpa angka. Akibat: stick bawah 15,1% (tujuan 2,998) langsung melambat; perlambatan 2,0 u/d2 menempuh 0,05 dalam 0,025 detik, jadi meluncur berakhir sekitar 1,5 frame sebelum benar-benar sampai.
3. **Batas laju kayuh berlaku juga ke bawah 0** (`pedal_rate` 0 di kecepatan 0, kaki diam) dan **meluncur/rem = 1** sesuai D-8. `HUD_STAMINA_AMBANG_RENDAH` (30) dipisah dari `STAMINA_PULIH_AMBANG` (30) karena maknanya berbeda (warna lawan aturan lelah).
4. **Jarak dan stamina dihitung tepat**, bukan didekati: langkah dibagi di batas tahan rem, rampa kecepatan dipotong di titik patah laju stamina (3,0 dan 4,5). Satu-satunya ketergantungan pada `dt` tersisa adalah jepit stamina 100 dan pergantian `lelah`/tujuan lelah yang diterapkan di akhir langkah (paling lama satu langkah terlambat; selisih < 0,01 poin di dt 1/30, dites).
5. **Jeda: satu peristiwa lanjut mana pun cukup** (RESUMED atau FOCUS_IN), supaya simulasi tidak tertahan bila platform hanya mengirim salah satu. `JedaSim.dt_efektif` tidak menjepit dt (jepit `LANGKAH_WAKTU_MAKS_DETIK` tetap di `_process`, dijaga tes lama QB-003). `set_process` tidak disentuh (tes mematikan proses scene). Animasi sprite (pemutar bawaan) tidak dihentikan saat jeda; hanya simulasi. Saat jeda sprite dipasang ulang dari keadaan (pose kayuh, arah normal) lewat `gerak(Vector2.ZERO, 0.0)`.
6. **Busur rem digambar di atas knob**: pada tarikan penuh knob (radius 15) menutupi tengah busur bawah, sehingga di tangkapan layar pertama busur hanya terlihat di dua ujungnya. Busur = piksel cincin dengan |dx| <= dy (seperempat bawah), tebal sama dengan cincin, `Palette.WARN` penuh.
7. **Dokumen AC-14 sebagian di commit docs terpisah** (`3a628fc`): AGENTS/aturan inti/README/SETUP_ANDROID menyebut beberapa perubahan sekaligus (art, logika, scene); BALANCING ikut commit Config, dokumen aset ikut commit art.
8. **`SepedaUji.kecepatan_ud` dan `lateral_ubin` tetap ada** sebagai properti yang membaca/menulis `keadaan` (setter membuat salinan), supaya tes dan probe lama tidak perlu diubah. `BarKecepatan` dipakai ulang untuk stamina dengan `warna_isi` (tidak diganti nama, supaya scene dan tes lama tetap).
9. **Probe lama disesuaikan**: `probe_lempar_jendela.gd` urutan melambat kini memakai 85% jangkauan (bawah penuh sekarang rem); komentar `probe_dorongan_jendela.gd` mencatat bawah penuh = rem.
10. Stick bawah tanpa rem kini paling dalam sekitar 0,899 (tujuan sekitar 1,65 u/d); 1,5 u/d hanya tujuan selama 0,25 detik pertama tarikan penuh. Dicatat di BALANCING 2 dan NEEDS-MANUAL; angka tidak diubah.

#### Tes lama yang diubah, dipindah, atau dibuang (alasan)

| Tes | Perubahan | Alasan |
|---|---|---|
| `tes_input_murni.gd` `_test_bike_drive` (seluruhnya) | **Dipindah** ke `tes_gerak.gd` sebagai tes `BikeMotion`: tujuan kecepatan, akselerasi/perlambatan, tidak melewati tujuan (sapuan QB-002), dt tidak sah, lateral dan jepit, diagonal, deterministik 2000 langkah. **Diubah:** "bawah penuh dt 100 berhenti di 1,5" -> bawah penuh = tujuan 1,5 sebelum rem (dt 0,2 dari 1,6), karena sesudah 0,25 detik rem; "kecepatan selalu di antara 1,5 dan 6,0" -> 0..6, di bawah 1,5 hanya lewat rem; QB-011 "trapesium galat < 0,005 di dt 0,1" -> jarak **tepat** (galat < 1e-6) untuk dt 0,05..2. **Dibuang:** `batas_lateral_ubin` lewat `BikeDrive` (diganti `BikeMotion.batas_lateral_ubin`) | D-1, D-2 |
| `tes_input_murni.gd` `_test_stick_ke_animasi` (10c) | bawah penuh 1 langkah `melambat_normal` -> `meluncur_normal`; bawah penuh 2 detik "1,5 u/d melambat_normal" -> "0 u/d rem_normal"; ditambah bawah 0,8 2 detik = 1,8 u/d `melambat_normal`. Lainnya hanya ganti tipe `BikeDrive.Hasil` -> `BikeMotion.Hasil` | D-2, D-7 |
| `tes_sprite.gd` `_test_aset_dan_frames` | 38 -> 48; sheet meluncur dan rem ditambah ke daftar (byte, `.import`, region, fps 4/8, loop, nama) | D-9 |
| `tes_sprite.gd` `_test_melambat_dari_stick` (bagian terpadu) | `BikeDrive` -> `BikeMotion`; bawah-dekat dari 3,0 u/d kini `meluncur_serong_kanan`, ditambah kasus di tujuan = `melambat_serong_kanan` | D-7 |
| `run_tests.gd` `_test_nama_animasi_dan_frames` | 38 -> 48 nama dari `LoperAnim` termasuk pose meluncur/rem | D-9 |
| `tes_input_scene.gd` `_test_jalan_tanpa_ujung` | 60 detik stick atas: "358 ubin, 6,0, ngebut_normal" -> "280-285 ubin, lelah, 4,5, cepat_normal" | D-5 (stamina habis sekitar 9 detik) |
| `tes_input_scene.gd` `_test_dorongan_kecepatan_scene` | "melambat mantap 1,5 u/d, geseran -20" -> "berhenti dengan rem 0 u/d, geseran -20" (geseran dijepit di 1,5) | D-2 (keyboard bawah = bawah penuh) |
| `tes_input_scene.gd` `_test_melambat_stick` | bawah penuh -> bawah 85%: `meluncur_normal` (laju 1) lalu `melambat_normal` di tujuan 1,76, laju kayuh = v/1,5, dorongan parsial; zona mati 14,9/15,0/15,1% tetap | D-2, D-7, D-8 |
| `tes_input_scene.gd` `_test_input_terpadu` (FOCUS_OUT) | "setelah kehilangan fokus tidak ada gerak sendiri, kembali santai" -> simulasi dijeda (lateral dan jarak tetap), lalu FOCUS_IN: lanjut santai 3,0 | D-6 |

Tidak ada tes yang di-skip atau dilemahkan selain yang tercatat. Jumlah pemeriksaan: 3315 (`main`) -> 3886.

#### Mutan nyata (AC-11)

Skrip sementara di scratchpad (tidak di-commit): tiap mutan mengganti satu potongan kode asli, menjalankan `run_tests.gd` + `cek_keluaran_tes.py --ketat`, lalu memulihkan berkas (`git status` bersih sesudahnya). Tertangkap = exit Godot atau pemeriksa 1. Delapan mutan wajib SPEC = M01, M02, M03, M04, M05, M06, M07, M08.

| Mutan | Hasil (`run_tests`) | Tes yang menangkap (contoh) |
|---|---|---|
| M01 ambang rem `>=` -> `>` | 1 gagal | "tepat di ambang efektif (0,90 - toleransi) memenuhi" |
| M02 lama tahan tidak di-reset saat syarat putus | 9 gagal | "stick dilepas di tengah tahan: lama tahan kembali 0", "naik sesaat ke bawah 0,85" |
| M03 rem berhenti di 1,5 bukan 0 | 12 gagal | "rem 0,6 detik dari 3,0: berhenti tepat 0", 10c "rem, berhenti 0 u/d" |
| M04 stamina tanpa jepit | 6 gagal | "stamina dijepit di 100 / 0", 2000 langkah acak |
| M05 lelah padam di `> 0` | 4 gagal | "stamina 10 -> 12: lelah tetap", "29,99 lelah tetap" |
| M06 interpolasi stamina diganti tangga | 6 gagal | "3,75 = -1, 5,25 = -8", independen dt (juga penjaga angka literal 0,5) |
| M07 pose meluncur/melambat tertukar | 29 gagal | 10c `meluncur_normal`, tabel pose, scene `_test_meluncur_lalu_melambat` |
| M08 pause tidak menolkan dt pertama | 6 gagal | `dt_efektif` sesudah lanjut, scene "langkah pertama sesudah lanjut ber-dt 0" |
| M09 langkah tidak dibagi di batas 0,25 detik | 15 gagal | "satu langkah 0,35 = 35 x 0,01", "rem aktif 0,1 detik = 2,5" |
| M10 `tahan_cukup` tanpa toleransi (`>`) | 10 gagal | "15 x 1/60 = 0,25 rem aktif", "tepat 0,25 rem" |
| M11 lelah tidak menjepit tujuan | 11 gagal | "lelah: tujuan 4,5", invarian prinsip 1 |
| M12 sprite tidak dijepit saat lelah | 7 gagal | "sprite cepat_normal selama lelah" |
| M13 lelah menyala di `< 1` | 2 gagal | "0,5 -> 0,3 belum lelah" |
| M14 rem tidak memberi +15 | 2 gagal | "rem aktif 1 detik dari 50 = 65" |
| M15 stick bawah tidak memberi +15 | 7 gagal | "stick ke bawah 1 detik = 65", durasi pulih |
| M16 laju stamina dari kecepatan tujuan | 2 gagal | "rampa 3,0 -> 6,0: 50 -> 45,5 tepat". **Awalnya HIDUP** (trapesium ujung-ujung, rentang durasi lebar); dibunuh dengan stamina tepat per potongan + tes rampa (`3fc1bbd`) |
| M16b rampa tidak dipotong di titik patah | 3 gagal | rampa naik/turun tepat, independen dt |
| M17 lateral tidak dijepit | 8 gagal | 10d tepi jalan, 2000 langkah acak |
| M18 tanda lateral terbalik | 34 gagal | 10d `santai_serong_kiri`, lateral +0,3 sisi dekat |
| M19 / M19b syarat rem dari panjang stick | 1 / 2 gagal | "jari diagonal 45 derajat lewat StickMap", "diagonal 0,85 + 0,5 tidak rem" |
| M20 rem tidak mendahului pose | 15 gagal | "langkah ke-15: pose rem", `rem_kanan` |
| M21 `pedal_rate` tidak dijepit | 1 gagal | "dijepit di PEDAL_RATE_MAKS" |
| M22 `pedal_rate` meluncur/rem dari kecepatan | 3 gagal | "meluncur dan rem selalu 1" (murni dan scene) |
| M23 `SepedaUji` mengirim `pedal_rate` 1 | 2 gagal | scene "laju kayuh = v / 6,0 dan naik" |
| M24 nominal cepat = santai | 2 gagal | "nominal tiap tingkat = 1" |
| M25 `BikeMotion.jeda` tidak me-reset tahan | 4 gagal | "jeda di tengah tahan: rem tidak langsung aktif" |
| M26 notifikasi jeda tidak memanggil `SepedaUji.jeda` | 10 gagal | lempar ditutup saat FOCUS_OUT/PAUSED, lama tahan 0 |
| M27 FOCUS_OUT tidak menjeda | 13 gagal | `notifikasi_jeda`, scene jeda |
| M28 RESUMED tidak melanjutkan | 3 gagal | "PAUSED/RESUMED: lanjut otomatis" |
| M29 sprite tidak menerima pose | 12 gagal | scene `meluncur_normal`, `rem_normal` |
| M30 lempar dari rem memakai tingkat stick | 2 gagal | "lempar dari rem memakai santai" |
| M31 busur rem tidak diperbarui | 4 gagal | "busur bawah cincin WARN tampil" |
| M32 bar stamina FAIL di `<= 30` | 1 gagal | "stamina tepat 30: masih ACCENT" |
| M33 penanda lelah tidak tampil | 2 gagal | "penanda teks LELAH tampil" |
| M34 busur di atas, bukan bawah | 3 gagal | `_test_busur_rem` |
| M35 rem 2,0 u/d2 bukan 5,0 | 7 gagal | "rem 0,1 detik = 2,5", "dari ngebut berhenti" |
| M36 jarak trapesium BikeDrive lama | 3 gagal | "dt 100 = 598,5 ubin", jarak tepat |
| M37 toleransi pose 0 | 1 gagal | "di atas tujuan sedikit kurang dari toleransi = KAYUH" |
| M38 `perbarui` tanpa `JedaSim` | 7 gagal | scene "perbarui dan _process dengan dt besar tidak mengubah ..." |

Total 40 mutan, 40 tertangkap, 0 hidup (sesudah `3fc1bbd`; sebelum itu M16 hidup, lihat baris M16). Di luar mutan: contoh buruk sintetis di `uji_bangun_frames.py` (5 sumber rusak meluncur/rem baru) dan kontrol negatif pemeriksa blok piksel (tanpa `--kecualikan`, exit 1).

#### Bukti visual (AC-13)

Perintah: `godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_gerak_jendela.gd -- docs/loop/20261013-fase1a-gerak/shots` (non-headless, OpenGL 4.1 Metal, viewport 780x360 skala x3, 0 ERROR/WARNING; simulasi dimajukan `perbarui(1/60)`, bukan waktu dinding). Pada percobaan pertama jendela kehilangan fokus di awal dan simulasi terjeda (FOCUS_OUT, sesuai D-6); probe mencatatnya dan mengirim FOCUS_IN. Tangkapan akhir dari kode `3fc1bbd` tanpa jeda.

Berkas: `2340x1080_{stamina_penuh, stamina_rendah, stamina_lelah, meluncur, melambat, rem_bergerak, rem_berhenti, kayuh_lagi}.png` dan `lembar_{kayuh_ke_meluncur, meluncur_ke_melambat, kayuh_ke_meluncur_rem, meluncur_ke_rem, rem_ke_kayuh}.png` (langkah tepat sebelum ganti, sesudah ganti, dua langkah sesudahnya; potongan 80x90 piksel game).
- Keadaan saat foto (dari keluaran probe): penuh 100, santai; rendah 19,9 ngebut 6,0 (bar merah); lelah 0, `cepat_normal` 4,5 u/d, tulisan LELAH merah di kanan label STAMINA; meluncur 3,80 u/d `meluncur_normal`; melambat 1,76 u/d `melambat_normal`; rem bergerak 2,83 u/d `rem_normal`, busur bawah `WARN` tampil; rem berhenti 0,00 u/d, busur tampil, angka "0.0 u/d"; kayuh lagi 1,65 u/d `santai_normal`.
- Ketajaman: `python3 tools/cek_blok_piksel.py 3 --kecualikan 1026,12,1315,121 --kecualikan 630,885,1141,1057 <8 png>`: 2.138.344 blok, 0 tidak seragam (teks HUD dikecualikan; kotak dicetak probe, panel bawah kini lebih tinggi karena bar stamina). Lima lembar tanpa pengecualian: 108.000 blok, 0 tidak seragam. Kontrol negatif: `rem_berhenti.png` tanpa `--kecualikan` = 560 blok tidak seragam (teks HUD), exit 1.
- Alas sprite saat pose berganti (titik pijak layar dan `letak_alas_layar_y` = titik pijak y + baris terbawah - 46, piksel game):

| Pergantian | Sebelum | Sesudah | Selisih alas |
|---|---|---|---|
| `cepat_normal` -> `meluncur_normal` | (277, 208), baris 54, alas 216 | (277, 208), 54, 216 | 0 |
| `meluncur_normal` -> `melambat_normal` | (253, 220), 54, 228 | (253, 220), 54, 228 | 0 |
| `cepat_normal` -> `meluncur_normal` (sebelum rem) | (274, 209), 54, 217 | (274, 209), 54, 217 | 0 |
| `meluncur_normal` -> `rem_normal` | (273, 210), 54, 218 | (272, 210), 54, 218 | 0 (titik pijak geser 1 px datar = dorongan kamera satu langkah) |
| `rem_normal` -> `santai_normal` | (240, 226), 54, 234 | (240, 226), 54, 234 | 0 |

  Statis (tes permanen `_test_titik_pijak_sama`): 40 frame meluncur/rem: alas dan tapak tiga baris terbawah = santai frame 2 per arah, baris terbawah = keempat frame santai (normal 54, serong_kanan 50, kanan 54, serong_kiri 56, kiri 53).
- Yang saya lihat (Read pada PNG): rem bergerak/berhenti: busur oranye di seperempat bawah cincin, digambar di atas knob; badan pengendara condong mundur sedikit; bar kecepatan kosong saat berhenti. Stamina lelah: bar stamina kosong, "LELAH" merah rata kanan di baris STAMINA, kecepatan 4,5. Stamina rendah: bar merah pendek. Lembar meluncur -> rem: roda dan bayangan tidak bergeser, hanya badan atas 1 px.
- Yang tidak bisa saya nilai: apakah getar 1 px rem dan napas meluncur terbaca di A54 450 dpi, rasa ambang rem, dan kenyamanan stamina. NEEDS-MANUAL.

#### Gerbang (dijalankan di `HEAD` sesudah `3fc1bbd`)

```
godot --headless --import                                           # 0 baris ERROR/WARNING
mkdir -p build && godot --headless --script res://tests/run_tests.gd 2>&1 | tee build/tests.log
                                                                    # 3886 lolos, 0 gagal (main: 3315)
python3 tools/cek_keluaran_tes.py --ketat build/tests.log           # pemeriksa: lolos (3886 lolos, 0 gagal, 0 peringatan)
python3 tools/tests_cek/uji_pemeriksa.py                            # 16 kasus, 0 menyimpang
python3 tools/tests_cek/uji_bangun_frames.py                        # 41 lolos, 0 gagal
python3 tools/loper_art/bangun_frames.py --cek                      # sama: 11 berkas di assets/sprites/loper
godot --headless --path . --quit-after 2                            # 0 ERROR/WARNING
godot --headless --path . --script res://tests/probe_layar.gd       # 0 ERROR, 0 PECAHAN
git diff main --name-only | grep -E "keystore|\.apk|\.aab|\.godot/|^build/|^builds/|\.jks|\.p12|export_credentials"   # kosong
# klon bersih (git clone --branch feat/fase1a-gerak, scratchpad), commit 3fc1bbd:
godot --headless --import                                           # exit 0, 0 ERROR/WARNING
git status --porcelain -uall | wc -l                                # 0
run_tests + cek_keluaran_tes.py --ketat                             # 3886 lolos, 0 gagal; lolos
godot --headless --path . --quit-after 2                            # 0 ERROR/WARNING
```
(Commit `f6af841` dan commit LOG ini hanya menambah PNG dan Markdown di `docs/`, yang diabaikan Godot lewat `docs/.gdignore`.)

#### Hal yang tidak bisa saya verifikasi

Rasa ambang rem (90%, 0,25 detik), rasa meluncur/melambat, durasi stamina di tangan, keterbacaan bar stamina, LELAH, dan busur rem di A54, laju kayuh secara visual, perilaku notifikasi jeda di Android sungguhan (urutan FOCUS/PAUSED), 60 fps, dan CI GitHub. Tidak ada APK yang dibangun atau dipasang.

## Catatan QA
