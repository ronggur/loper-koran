# Loop Log — 20261009-sprite-lempar-melambat
Scope: pasang sprite melambat dan lempar koran (usulan, PR #15) ke game untuk dilihat di A54  ·  Branch: feat/sprite-lempar-melambat  ·  Mulai: 2026-10-09  ·  Godot: 4.7.2.stable.official.ed1daf0bf

## Status: PASSED   (selesai di iterasi 1/2: QA PASS, 0 Blocker, 0 Major; 2 Minor dan 3 Nit, tidak ada yang menuntut iterasi 2)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 1 | AC-1..AC-9 semua dikerjakan (8 commit di `feat/sprite-lempar-melambat`, tanpa push, tanpa `BLOCKED`): pembangun `.tres` stdlib + 38 animasi, `LoperAnim` (melambat, nama lempar, sisi dari swipe), `LemparWaktu`, `LoperSprite` (melambat, `lempar`, sinyal, Q-001), kabel swipe di `JalanUji`, Config + BALANCING 2, bukti visual 2340x1080, dokumen AC-7. Tes 2102 -> 3315, 65 mutan nyata (62 tertangkap, 3 hidup dan dijelaskan). | import bersih (juga di clone bersih, `git status --porcelain` kosong), `3315 lolos, 0 gagal` + pemeriksa `--ketat` exit 0, `uji_pemeriksa.py` 16 kasus 0 menyimpang, `uji_bangun_frames.py` 28 lolos, `--quit-after 2` 0 ERROR/WARNING, probe layar bersih | **PASS** (gerbang hijau di klon bersih, 0 Blocker, 0 Major; 2 Minor, 3 Nit, 6 NEEDS-MANUAL) | 5 (QS-001..QS-005) | 0 (tidak ada temuan sebelumnya) |

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|
| QS-001 | 1 | Minor | `scripts/systems/loper_anim.gd` `tingkat_dari_stick`, `scripts/systems/bike_drive.gd:73` | Melambat dipicu oleh TANDA komponen y stick saja (D-1, AC-3 literal), jadi berlaku juga untuk belok mendatar dengan jempol sedikit di bawah titik asal, bukan hanya "di sekitar zona mati" seperti catatan Dev. Bukti (simulasi `StickMap.petakan` -> `BikeDrive.langkah`, 600 langkah 1/60 detik, stick ke kanan 20 px, y bergetar sigma 1,5 px): 291 pergantian tingkat sprite (santai 8 fps <-> melambat 4 fps) dalam 10 detik, 4,7 detik di `melambat`, padahal kecepatan terendah 2,91 u/d (santai 3,0). Stick ke kanan 20 px dengan y tetap +2 px di bawah titik asal: `melambat` terus selama 10 detik pada 2,93 u/d. Gambar melambat = santai, jadi yang berubah hanya kecepatan putar (rata-rata kayuh jadi sekitar 6 fps dan tidak stabil), bukan kedipan gambar. Perilaku sesuai SPEC (D-1/AC-3: 15,1% bawah = melambat), jadi bukan cacat kode; risikonya ada di aturan. Rekomendasi (keputusan pemilik, mengubah angka AC-3, jangan diubah Dev tanpa keputusan): ambang atau histeresis (mis. melambat baru bila komponen y < -X dan keluar bila > -Y), atau dasarkan pada kecepatan target yang benar-benar turun; angka dari uji HP. Repro: lihat potongan di bagian QA. | DEFERRED (keputusan desain; uji HP, lihat NEEDS-MANUAL) | | |
| QS-002 | 1 | Minor | git: `refs/remotes/origin/feat/sprite-lempar-melambat` | Branch kerja sudah ter-push ke `origin`: reflog `update by push` pada 2026-10-09 20:26:20 +0700 (commit terakhir Dev 20:22:45; QA mulai sesudahnya). SPEC AC-9 dan LOOP-DEV-QA bagian 0 menyatakan tidak ada push selama loop (push menunggu konfirmasi pemilik). Catatan Dev "tanpa push" benar saat ditulis (sebelum 20:26); pelaku push tidak bisa ditentukan dari repo (bukan QA: QA tidak push). Dampak: tidak ada (bukan `main`, belum ada PR), tetapi orchestrator perlu tahu bahwa isi branch sudah ada di GitHub. Bukti: `git reflog show --date=iso origin/feat/sprite-lempar-melambat`. | CLOSED (bukan cacat) | orchestrator: branch di-push atas pertanyaan pemilik ("sprite-lempar-melambat gak dipush?") sebagai draft PR #18 setelah Dev selesai dan sebelum QA berakhir; isi branch tidak berubah oleh push; pemilik kemudian mengizinkan merge setelah QA PASS | - |
| QS-003 | 1 | Nit | `docs/ART_DIRECTION.md`, `docs/design/character/README.md`, `tools/loper_art/README.md` | `origin/main` sudah maju dua commit (#16 sprite meluncur dan rem, #17 perintah Fase 1) sejak branch dibuat. Uji merge di klon (`git merge --no-commit q/main`): konflik isi di tiga berkas dokumen itu (bukan di kode). Bukan kesalahan Dev, tetapi branch perlu `git rebase origin/main` (atau merge) sebelum PR; gerbang harus diulang sesudahnya. | FIXED (rebase) | orchestrator: `git rebase origin/main`, konflik dokumen diselesaikan dengan menggabungkan kedua sisi; gerbang diulang sesudahnya (lihat catatan penutup) | - |
| QS-004 | 1 | Nit | `scripts/ui/kontrol_touch.gd` (run 0B) + zona swipe kidal | Dengan kidal, zona swipe pindah ke sisi kiri layar dan melewati sprite (x sekitar 260 piksel game); garis putus swipe digambar di `CanvasLayer` di atas sprite selama jari ditahan, jadi menutupi badan sprite sebentar (`shots/qa_2340x1080_kidal_swipe_ditahan.png`, `qa_1920x1080_kidal_swipe_ditahan.png`). Bukan regresi run ini (zona dan garis dari 0B); tidak menutupi sprite lempar sesudah jari diangkat (`qa_*_kidal_lempar_f2.png`). Tangan kanan (bawaan): stick, HUD, dan garis swipe tidak menyentuh sprite. | DEFERRED (nilai di HP) | | |
| QS-005 | 1 | Nit | `tests/tes_input_scene.gd` | Semua tes scene mematikan `_process` sprite dan `JalanUji` (`set_process(false)`) dan memajukan waktu dengan `maju(dt)`/`perbarui(dt)`; jalur nyata `_process` -> `maju` hanya dites langsung lewat `_process(5.0)` di `_test_loper_sprite_di_tree`. Mutan QA N19 (`JalanUji._ready` memanggil `set_process(false)`) tidak tertangkap. Celah ini sudah ada sejak 0B; QA menutupinya dengan uji waktu nyata sementara (skrip scratchpad, tidak di-commit): koran_lepas di 0,165 detik dan lempar_selesai di 0,340 detik (harapan 0,167 dan 0,333), lima swipe 50 ms beruntun menghasilkan satu lempar, FOCUS_OUT/PAUSED di tengah lempar menutup lempar, 200 swipe acak tanpa ERROR dan tanpa lempar menggantung. Tidak ada bug; hanya catatan cakupan. | DEFERRED | | |

## NEEDS-MANUAL (uji di HP)
Daftar awal ada di SPEC bagian "Butuh uji perangkat nyata". Dev dan QA menambah langkah di sini.

Tambahan Dev (iterasi 1), selain daftar SPEC (versi lengkap juga ada di `docs/SETUP_ANDROID.md` bagian 8):
- Melambat: tarik stick sedikit ke bawah (sekitar 15 sampai 25%) sambil belok. Sprite melambat dipicu begitu komponen bawah melewati zona mati 15% (D-1, tanpa ambang tambahan) padahal kecepatan target baru turun sedikit (15,1% bawah = 2,998 u/d). Catat bila animasi berkedip antara santai (8 fps) dan melambat (4 fps) atau terasa terlalu cepat berubah.
- Lempar: titik kaki di frame 0 lempar adalah fase kayuh 0, jadi kaki bisa melompat satu fase saat swipe dilepas (kayuh frame 1 sampai 3 menjadi lempar frame 0); catat bila terasa.
- Lempar: koran putih dan topi putih berdekatan di frame 1 dan 2 sisi seberang; nilai keterbacaan titik lepas di A54.
- Kembali dari background saat lempar berjalan: animasi lempar ditutup tanpa melepas koran (tidak ada koran terbang di run ini).

Tambahan QA (iterasi 1), langkah uji di A54:
- [ ] **QS-001, melambat saat belok mendatar:** pada kecepatan santai tarik stick ke kanan (atau kiri) penuh sambil jempol dibiarkan wajar, 10 detik. Apakah kecepatan kayuh terlihat naik turun (4 fps lawan 8 fps) padahal kecepatan hampir tetap 3 u/d? Kalau ya, putuskan ambang atau histeresis (angka dari uji ini); lalu AC-3 (15,1% bawah) perlu diubah oleh pemilik.
- [ ] **Kaki saat lempar dimulai:** swipe dilepas pada fase kayuh 0, 1, 2, dan 3 (urutan acak). Hanya fase 3 yang menyambung mulus ke lempar frame 0; fase lain memberi lompatan kecil pada kaki (terukur QA di render: frame kayuh -> lempar frame 0 -> kayuh frame 0). Catat apakah mengganggu.
- [ ] **Keterbacaan titik lepas:** koran putih berdekatan dengan topi putih di frame 1 sisi seberang (`qa_*_lembar_lempar_kiri_*.png`, panel ke-3). Terbaca di layar desktop ×3; nilai di A54 (450 dpi, di luar ruangan).
- [ ] **Garis swipe di atas sprite pada kidal (QS-004):** pada mode kidal, apakah garis putus yang melewati badan pemain mengganggu.
- [ ] **CI GitHub:** langkah baru `Uji pembangun SpriteFrames` di `.github/workflows/tes.yml` hanya bisa dibuktikan di runner; PR baru boleh dianggap siap bila CI hijau (QA hanya membaca YAML: valid, tidak melonggarkan langkah lama, tanpa jaringan atau langkah berbahaya).
- [ ] **Sebelum PR:** rebase atau merge `origin/main` (QS-003) lalu ulangi gerbang di klon bersih.

## Catatan Dev

### Dev (iterasi 1)

Lingkungan: macOS (Apple M1), `godot --version` = `4.7.2.stable.official.ed1daf0bf`, Python 3.14 (stdlib). 8 commit Dev (7 kode/tes/dokumen + commit LOG ini) di `feat/sprite-lempar-melambat` sesudah commit SPEC/LOG orchestrator (`git log --oneline main..HEAD`), tidak ada commit di `main`, tidak ada push. Tidak ada `BLOCKED`. Tidak menyentuh HP (tidak ada perintah `adb` dari saya; baris `cannot connect to daemon at tcp:5037` di keluaran `godot --headless --import` berasal dari plugin export Android Godot sendiri, bukan dari saya), tidak mengunduh, tidak mengubah Editor Settings, tidak membangun APK. Hook `rtk` mengubah keluaran `git status`/`grep`; semua hitungan memakai `/usr/bin/git` dan `/usr/bin/grep`.

Commit (urut): `ba2e32a` art: SpriteFrames gabungan; `544951f` feat: LoperAnim + LemparWaktu + Config + BALANCING; `c69e3e9` feat: LoperSprite; `b8d95b5` feat: kabel swipe/stick di jalan uji; `234ac3b` test: titik pijak + probe + bukti visual; `3648684` docs: AC-7; `5de9021` test: batas inklusif; dan commit LOG ini (`docs: LOG Dev iterasi 1`).

#### Bukti per AC

| AC | Bukti (file, tes, perintah) |
|---|---|
| AC-1 | Lihat "Gerbang". Clone bersih (`git clone --branch feat/sprite-lempar-melambat`): `godot --headless --import` exit 0, 0 baris `ERROR`/`SCRIPT ERROR`/`WARNING`, `git status --porcelain -uall` 0 baris (semua `.import` dan `.uid` ter-commit, termasuk `.import` dua PNG baru, `lempar_waktu.gd.uid`, `tes_sprite.gd.uid`, `probe_lempar_jendela.gd.uid`). Diff terhadap `main` tidak memuat keystore, APK, `.godot/`, `build/`, `builds/` (grep nama berkas: 0). |
| AC-2 | `tools/loper_art/bangun_frames.py` (stdlib; membaca tiga JSON di `docs/design/character/loper_agen/`, memeriksa nama ganda dan region di dalam PNG lewat header IHDR, menyalin PNG+JSON byte demi byte, menulis `.tres` dengan template `produce.py`). `assets/sprites/loper/` kini memuat `loper_agen_{lempar,melambat}.{png,json}` + `.png.import` (Lossless, tanpa mipmap, tanpa VRAM; sama dengan `loper_agen.png.import` kecuali uid). `tests/tes_sprite.gd` `_test_aset_dan_frames` (sekitar 800 pemeriksaan): byte-identik 6 berkas, `.import`, urutan nama di teks `.tres` = urutan JSON (38), tiap animasi: 4 frame, region, atlas, fps (8/10/12, 4, 12), `loop` (true, true, false), baris sheet, durasi 1,0, nama = kolom JSON, `release_frame` 2 untuk ke-18 animasi lempar. `tools/tests_cek/uji_bangun_frames.py` (28 pemeriksaan, dipasang di CI): berkas di repo = hasil skrip (`--cek`), dua kali jalan = byte sama, 38 animasi, loop false hanya 18, 7 jenis sumber rusak ditolak (exit 2), `--cek` menolak `.tres`/PNG yang diubah (exit 1). |
| AC-3 | `scripts/systems/loper_anim.gd`: `TINGKAT_MELAMBAT` (-1), `tingkat_dari_stick` (negatif = melambat), `nama_animasi`, `tingkat_untuk_lempar`, `arah_untuk_lempar`, `nama_lempar`, `sisi_dari_swipe`, enum `Sisi {TIDAK_ADA, SEBERANG, DEKAT}`. Tes di `tests/tes_sprite.gd`: `_test_melambat_dari_stick` (14,9% / 15,0% bawah = santai, 15,1% = melambat lewat rantai `StickMap.petakan` -> `tingkat_dari_stick` dan `BikeDrive`; atas dan samping tidak pernah melambat; nol, -0,0, 1e-6 negatif, NaN), `_test_nama_lempar` (40 kombinasi = 18 nama berbeda semuanya ada di SpriteFrames; melambat -> santai; +-2 -> +-1 sisi sama; sisi kosong/7/-1 = nama kosong), `_test_sisi_dari_swipe` (kiri, kanan, miring, vertikal, 45 derajat, 11,99 / 12,0 / 12,08, nol, NaN, INF, 1e30). `LemparWaktu` (garis waktu murni): `_test_lempar_waktu`. |
| AC-4 | `scripts/entities/loper_sprite.gd`, tes `_test_loper_sprite_*` di `tests/tes_sprite.gd`: tingkat -1..2 dan jepit; `lempar(sisi)` sekali (tidak loop), `koran_lepas` tepat sekali di langkah 10 (frame 2, `dt` 1/60) dan `lempar_selesai` sekali di langkah 20; 40 kombinasi; kembali ke kayuh sesuai tingkat/arah TERKINI; lempar kedua ditolak; `maju` dengan dt 0/negatif/NaN/INF/besar/1e300; `batalkan_lempar` sebelum dan sesudah lepas; re-entrancy pendengar; `pedal_rate` 0 tidak membekukan lempar; di dalam tree (`_process` hanya saat melempar, delta dijepit 0,1 detik); Q-001 (a) tanpa frames masuk tree tanpa ERROR, (b) repro 0A: frames dicopot lalu dipasang dengan `speed_level` berubah -> `cepat_kiri` berputar, (c) frames dicopot di tengah lempar -> ditutup tanpa sinyal. Waktu: semua lewat `maju(DT)` (`dt` tetap), tidak ada tunggu waktu nyata. Di luar scene tree: node tidak pernah masuk tree di sebagian besar tes; 0 ERROR/WARNING (pemeriksa `--ketat`). |
| AC-5 | `scripts/entities/jalan_uji.gd` (`_saat_swipe_selesai`, `_notification`) + `sepeda_uji.gd` (`lempar`, `sedang_melempar`, `batalkan_lempar`). Tes `tests/tes_input_scene.gd`: `_test_melambat_stick` (event sentuh sintetis di viewport 780x360: 14,9 / 15,0 / 15,1% bawah, bawah penuh = `melambat_normal` 4 fps, kecepatan 1,5 u/d dan dorongan kecepatan -20 px tetap bekerja, bawah-dekat = `melambat_serong_kanan`, lepas = santai), `_test_lempar_swipe` (kiri dan kanan di santai, cepat, ngebut; sinyal; kembali ke kayuh), `_test_lempar_serong_dan_tepi` (serong seberang/dekat, 90 derajat -> serong, vertikal, miring, 11 px, ketukan nol, tepat 12 px kiri dan kanan, swipe mulai di strip atas atau zona stick, swipe kedua saat melempar), `_test_lempar_dua_jari` (ngebut 6,0 u/d dan sepeda maju 0,95+ ubin selama 10 langkah lempar, stick dilepas di tengah lempar), `_test_lempar_kidal` (3 lebar: kidal tidak mengubah arti sisi), `_test_lempar_batal` (FOCUS_OUT, PAUSED, kidal berganti saat swipe ditahan, lempar berjalan ditutup tanpa sinyal, swipe baru normal sesudahnya). |
| AC-6 | `scripts/config.gd` bagian baru "Lempar koran dan melambat": `LEMPAR_SWIPE_AMBANG_PX = 12.0`, `LEMPAR_FRAME_LEPAS = 2`, `LEMPAR_TOLERANSI_DETIK = 0.000001`, masing-masing satu baris literal (lolos `ConfigParser`). `LEMPAR_FPS`/`MELAMBAT_FPS` tidak dibuat: fps dibaca dari `SpriteFrames` (`get_animation_speed`). `docs/BALANCING.md` bagian 2: tiga baris tabel dan paragraf aturan, ditandai usulan. |
| AC-7 | Commit `3648684` (dokumen terakhir, lihat "Deviasi"): README lempar dan melambat, `docs/design/character/README.md`, `docs/ART_DIRECTION.md` 3.2, 3.4, dan changelog, `AGENTS.md` (peta + perintah), `.cursor/rules/00-project-core.mdc` (perintah), `docs/README.md` (status, pohon), `docs/SETUP_ANDROID.md` bagian 8 (empat butir baru), `tools/loper_art/README.md`. `DEV_PHASES.md` dan `ROADMAP.md` tidak disentuh. |
| AC-8 | `tests/probe_lempar_jendela.gd`, 25 tangkapan layar + 4 lembar potongan di `docs/loop/20261009-sprite-lempar-melambat/shots/`; titik pijak diukur di bawah; tes permanen `_test_titik_pijak_sama`. |
| AC-9 | 8 commit kecil `<tipe>: <ringkasan>` berbahasa Indonesia, branch `feat/sprite-lempar-melambat`, `main` tetap `f6594cd`, tidak ada push. |

#### Pembangun `.tres` (perintah dan hash)

```
python3 tools/loper_art/bangun_frames.py                  # 38 animasi, 6 berkas sumber disalin -> assets/sprites/loper
python3 tools/loper_art/bangun_frames.py --cek            # sama: 7 berkas di assets/sprites/loper
python3 tools/loper_art/bangun_frames.py --out build/ul1  # dan build/ul2: sha256 .tres keduanya sama
sha256 loper_agen_frames.tres = 4b697a16cba979ad0098d43b4b3ea4b942ba1180df7e235ad9d2d37a853260e9 (31.567 byte, load_steps 156)
sha256 loper_agen_lempar.png  = d07b76ce9dd1e4ef2772b681e1f3da6eb7d37118f47832f31ee9a62f8222b843
sha256 loper_agen_melambat.png = 29fa67a87ce074dce6a6158fcce4c8cc7786fe4d260ff1c8558fd61e3588ccf4
```
15 animasi kayuh dan 60 `AtlasTexture` pertama identik byte demi byte dengan `.tres` lama (dibandingkan sebelum menulis); animasi baru ditambahkan di belakang. Id ext_resource: `1_sheet` (kayuh, sama dengan `produce.py`), `2_melambat`, `3_lempar`. `produce.py`, `lempar.py`, `melambat.py`, dan semua PNG/JSON sumber tidak diubah.

#### Tes lama yang berubah (alasan)

| Tes | Perubahan | Alasan |
|---|---|---|
| `run_tests.gd` `_test_tingkat_sprite` | stick bawah (-0,1, -1,0, -INF) kini `TINGKAT_MELAMBAT` (-1), bukan 0; monoton diperiksa -1..1 | D-1: komponen maju negatif = melambat |
| `_test_nama_animasi_dan_frames` | "tepat 15 animasi" -> 38; `nama_animasi(-1, 9)` `santai_kanan` -> `melambat_kanan`; pemeriksaan yatim memakai semua nama `LoperAnim` (kayuh + melambat + lempar) dan sebaliknya (tiap nama `LoperAnim` ada di SpriteFrames) | SpriteFrames gabungan; tingkat -1 sekarang melambat. Pemeriksaan JSON kayuh lama tetap utuh |
| `_test_scene_pemain` | loop tingkat 0..2 -> -1..2; `speed_level = -4` dijepit ke 0 -> dijepit ke -1 | `speed_level` mendukung melambat |
| `_string_kiri_kanan` (penjaga Q-003) | daftar putih satu blok (`const NAMA_ARAH`) -> dua (`NAMA_ARAH`, `NAMA_SISI_LEMPAR`) lewat `BLOK_NAMA_SISI_SAH`; 4 kasus negatif baru (blok lain berisi "kiri" ditolak, "kiri" sesudah blok ditutup ditolak, nama lempar di fungsi ditolak, blok sah diterima) | Nama animasi lempar memuat sisi `kiri`/`kanan`; daftar putih tidak boleh longgar. Alasan tertulis di komentar konstanta |
| `tes_input_murni.gd` `_test_stick_ke_animasi` (10c) | bawah penuh `santai_normal` -> `melambat_normal` (dua pemeriksaan) | D-1 |
| `tes_input_scene.gd` `_test_input_terpadu` | swipe 70 px ke kanan sekarang melempar: ditambah pemeriksaan `lempar_kanan_ngebut_normal`, lalu lempar diselesaikan dengan waktu terkontrol sebelum pemeriksaan kayuh yang lama (`santai_normal` dst. tetap ada) | Swipe horizontal kini melempar (AC-5); tes lama mengamati kayuh sesudahnya |

Tidak ada tes yang dihapus, di-skip, atau dilemahkan. Jumlah pemeriksaan: 2102 (baseline `main`) -> 3315.

#### Uji mutasi (65 mutan nyata; skrip sementara di scratchpad, tidak di-commit)

Tiap mutan: satu suntingan pada kode asli, `run_tests.gd` + `cek_keluaran_tes.py --ketat`, dipulihkan sesudahnya (`git status` bersih tiap akhir). Tertangkap = exit Godot atau pemeriksa 1.
- **AC-2 (10, semua tertangkap):** lempar jadi loop; fps satu lempar 10; region digeser 1 px; nama `melambat_kirii`; PNG lempar beda 1 byte; `release_frame` 3 (aset dan sumber); atlas menunjuk sheet kayuh; dua nama kayuh tertukar; `.import` lempar hilang; satu melambat tanpa loop.
- **AC-3 (23; 22 tertangkap, 1 hidup):** nol dianggap melambat; melambat butuh -0,2; melambat tidak jatuh ke santai; 90 derajat tidak jatuh ke serong; sisi swipe tertukar; ambang eksklusif; tanpa pemeriksaan vertikal; 45 derajat melempar; ambang dari komponen datar; ambang Config 13; toleransi 0 (derau float menggeser frame); lepas berulang; selesai terlambat satu langkah (`>` bukan `>=`, awalnya HIDUP, dibunuh dengan tes batas inklusif tepat commit `5de9021`); `frame_lepas` 0 tidak dijepit; nama sisi lempar tertukar; `jepit_tingkat` bawah 0; NaN bukan santai; dt tak hingga memajukan; fps tak sah menggantung; daftar putih guard terlalu sempit dan terlalu longgar; nama melambat salah. **Hidup: `_indeks` memakai `int()` sebelum menjepit** (waktu 1e300): di Apple M1 konversi float ke int saturasi sehingga hasilnya tetap benar; di x86 (runner CI) hasil `int()` di luar jangkauan = INT64_MIN dan mutan itu akan tertangkap oleh tes `dt 1e300`. Jepit-sebelum-int tetap dipertahankan sebagai pertahanan lintas platform.
- **AC-4 (20; 19 tertangkap, 1 hidup):** lempar tanpa penjaga "sedang melempar"; `koran_lepas` tiap langkah; tanpa kembali ke kayuh; gambar berganti saat `speed_level` berubah; tidak pernah selesai; `lempar_selesai` sebelum kayuh kembali; `batalkan_lempar` memancarkan `lempar_selesai`; `sprite_frames_changed` tidak disambung (Q-001b); `_mainkan_bila_siap` tanpa penjaga frames kosong (Q-001a, tertangkap sebagai `ERROR:` oleh pemeriksa); `_process` tanpa jepit delta; `_process` tidak dinyalakan; `_ready` tidak mematikan `_process`; pemutar bawaan tidak dihentikan; `koran_lepas` selalu sisi dekat; tanpa penjaga nama kosong; frames hilang tidak membatalkan; fps lempar 10 (juga ditolak penjaga angka literal); `LEMPAR_FRAME_LEPAS` 3; `speed_level` tanpa jepit. **Hidup (setara): `set_frame_and_progress(0, 0.0)` di awal `lempar` dihapus**: setter `animation` mesin sudah mengembalikan frame 0; baris itu tetap dipertahankan sebagai pertahanan eksplisit dan perilakunya dites (mulai di frame 0 walau kayuh di frame 2).
- **AC-5 (12, semua tertangkap):** arah swipe dibalik; swipe tidak disambung; pause tidak menutup lempar (FOCUS_OUT dan PAUSED terpisah); sepeda selalu melempar ke dekat; kidal menukar arti sisi; stick bawah tidak melambat; sepeda berhenti saat melempar; awal = akhir; `SepedaUji` tidak meneruskan tingkat atau arah; paksa batal sebelum lempar baru.

Di luar mutasi ada contoh buruk sintetis: 7 sumber `.tres` rusak (`uji_bangun_frames.py`), 4 kasus penjaga kiri/kanan, kontrol negatif pengukur alas (sel digeser 1 px), dan kontrol negatif `cek_blok_piksel.py` tanpa `--kecualikan` (413 blok tidak seragam dari teks HUD, exit 1).

#### Ukuran posisi alas sprite (AC-8)

Statis, dari PNG (tes permanen `_test_titik_pijak_sama`, 72 frame lempar vs frame kayuh sumber `source_row`): baris piksel terbawah (indeks dari atas sel 46x58, titik pijak y 46) sama persis untuk semua 72 frame: normal 54, serong_kanan 50, serong_kiri 56, dan himpunan piksel tidak transparan di tiga baris terbawah (tapak roda dan bayangan) juga sama persis. 20 frame melambat identik piksel demi piksel dengan baris santai. Sel, `ground_anchor` (23, 46), dan `godot_offset` (0, -17) sama untuk ketiga sheet (dites).

Dinamis, di jendela 2340x1080 (keluaran `ukur` dari `tests/probe_lempar_jendela.gd`, titik pijak = `get_global_transform_with_canvas().origin`, piksel game; `letak_alas_layar_y` = titik pijak y + baris terbawah - 46):

| Keadaan | Santai (kiri dan kanan) | Ngebut (kiri dan kanan) |
|---|---|---|
| sebelum (kayuh) | titik pijak (260, 216), baris terbawah 54, alas y 224,0 | (288, 202), 54, alas y 210,0 |
| lempar f0, f1, f2, f3 | (260, 216), 54, 224,0 (keempatnya) | (288, 202), 54, 210,0 (keempatnya) |
| sesudah (kayuh) | (260, 216), 54, 224,0 | (288, 202), 54, 210,0 |

Selisih alas sebelum/saat/sesudah = 0,0 px game (0,0 px layar) di keempat lemparan. Beda antara santai dan ngebut (28, -14) adalah dorongan kecepatan yang sudah ada (kamera), bukan lompatan sprite.

#### Tangkapan layar dan penilaian saya (non-headless, OpenGL 4.1 Metal, Apple M1)

Perintah: `godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_lempar_jendela.gd -- docs/loop/20261009-sprite-lempar-melambat/shots` (sekitar 70 detik; dijalankan ulang ke `build/shots_cek` sesudah merapikan nama variabel: 29 berkas, 0 error). Viewport 780x360, skala x3. Berkas: `2340x1080_melambat_{normal,serong_kanan,serong_kiri,kiri_90,kanan_90}.png`, `2340x1080_lempar_{kiri,kanan}_{santai,ngebut}_{f0,f1,f2,f3,sesudah}.png` (20), dan empat `lembar_lempar_<sisi>_<tingkat>.png` (sebelum, f0..f3, sesudah berdampingan, potongan 80x90 piksel game).
- **Ketajaman:** `python3 tools/cek_blok_piksel.py 3 --kecualikan 1026,12,1315,121 --kecualikan 630,954,1141,1057 <png>` pada ke-25 tangkapan layar: 271.226 blok, 0 tidak seragam, 9.574 dikecualikan (teks HUD), sisa tepi (0, 0). Empat lembar potongan (tanpa pengecualian): 43.200 blok, 0 tidak seragam. Kontrol negatif: tanpa `--kecualikan` 413 blok tidak seragam (teks HUD), exit 1.
- **Yang saya lihat (dengan alat Read pada PNG):** melambat_normal: sprite sepeda dari belakang-kanan, kecepatan HUD 1,5 u/d, stick bawah penuh (knob oranye di bawah cincin). melambat_serong_kiri: pengendara menghadap atas layar (arah `serong_kiri` per ART_DIRECTION 3.2), kecepatan masih turun (2,0 u/d). melambat_kanan_90: sprite arah `kanan` (menghadap sisi dekat, wajah terlihat); dua gambar 90 derajat hanya untuk melihat aset (sudut gerak maksimum saat melambat atan(3,0/1,5) = 63,4 derajat < 67,5, jadi 90 derajat tidak bisa muncul dari stick; SPEC menyebut "4 arah yang bisa muncul", yang bisa muncul dari stick adalah 3: normal, serong_kanan, serong_kiri). Lembar lempar: urutan terbaca jelas: f0 koran di tangan di sisi tas (Ambil), f1 koran diangkat (kiri: di atas bahu; kanan: ditarik ke samping badan), f2 koran di titik lepas (kiri: di samping kepala; kanan: di tangan yang terulur, saat lepas), f3 lengan terjulur tanpa koran, sesudah = kayuh biasa. Alas roda dan bayangan tidak bergeser di antara enam panel; tepi piksel tajam (tidak ada blur); tidak ada lompatan posisi. Lengan dan koran (persegi putih kecil dengan garis luar gelap) terbaca di x3.
- **Yang tidak bisa saya nilai:** rasa gerak (0,33 detik terasa cepat atau lambat, kayuh 4 fps terasa pelan atau patah), keterbacaan di A54 fisik (ukuran 450 dpi, cahaya luar), dan apakah koran putih di dekat topi putih cukup kontras saat bergerak. Itu NEEDS-MANUAL.

#### Keputusan, deviasi, dan keraguan (bisa ditolak di review PR)

1. **Indeks tingkat melambat = -1** (bukan 3): urut menurut kecepatan, jadi `jepit_tingkat` memetakan di bawah jangkauan ke melambat dan di atasnya ke ngebut. Konsekuensi: `BikeDrive.Hasil.tingkat_sprite` dan `LoperSprite.speed_level` kini -1..2 (`@export_range(-1, 2)`).
2. **Waktu lempar dimajukan `LoperSprite` sendiri** (`maju(dt)` + `LemparWaktu`), bukan pemutar bawaan `AnimatedSprite2D` (yang tidak punya langkah manual, jadi tes harus menunggu waktu nyata). Konsekuensi: `_process` sprite menyala hanya saat melempar, delta dijepit ke `LANGKAH_WAKTU_MAKS_DETIK`; animasi kayuh tetap pemutar bawaan. Tes scene mematikan `_process` sprite (`set_process(false)`) dan memanggil `maju`.
3. **`batalkan_lempar()` + `JalanUji._notification`** (tidak diminta eksplisit): app di-background atau kehilangan fokus (FOCUS_OUT, PAUSED) menutup lempar tanpa `koran_lepas`/`lempar_selesai`. Di desktop FOCUS_OUT juga terjadi saat jendela kehilangan fokus. Kidal berganti di tengah lempar TIDAK menutup lempar (hanya swipe yang ditahan yang dibatalkan router).
4. **Aturan swipe (D-2) yang saya pilih:** ambang diukur dari panjang swipe (bukan hanya komponen datar), inklusif pada 12,0 px; dominan vertikal DAN tepat 45 derajat (|dx| = |dy|) = tidak melempar (ambigu). Sisi dari tanda `akhir.x - awal.x`; durasi swipe tidak dipakai.
5. **Konstanta `LEMPAR_FRAME_LEPAS` dan `LEMPAR_TOLERANSI_DETIK`** ada di Config walau bukan angka tuning: aturan "tanpa angka literal di entities/systems" (penjaga otomatis) menolak literal selain 0, 1, 2, -1, -2. `LEMPAR_FRAME_LEPAS` dites sama dengan `release_frame` JSON.
6. **Lempar mulai dari frame 0 apa pun fase kayuhnya**: frame k lempar = frame k kayuh dengan lengan digambar, jadi saat swipe dilepas di kayuh frame 2 kaki melompat ke fase 0. Sesudah lempar kayuh melanjutkan dari frame 0 (sesudah lempar frame 3). Menyelaraskan fase mulai bukan lingkup (urutan frame lengan tetap 0..3); catat di HP.
7. **Melambat tanpa ambang selain zona mati** (SPEC: 14,9% tidak, 15,1% ya): di 15,1% sprite sudah berayun 4 fps sementara kecepatan target 2,998 u/d (hampir santai). Saat stick hanya melenceng sedikit ke bawah sambil belok, animasi bisa berkedip santai/melambat. Tidak ditambah ambang (butuh angka dari uji HP); dicatat di BALANCING 2 dan SETUP_ANDROID.
8. **Dokumen (AC-7) di commit terakhir, bukan di commit yang sama dengan tiap perubahan kode**: status "dipakai" baru benar setelah kabel dan bukti visual selesai. BALANCING 2 ikut di commit Config (sesuai `balancing.mdc`).
9. **CI:** satu langkah ditambahkan di `.github/workflows/tes.yml` (`python3 tools/tests_cek/uji_bangun_frames.py`); tidak bisa saya jalankan di GitHub dari sini (perintah yang sama berjalan lokal dan di klon bersih).
10. Q-001 (run 0A) ditutup di `loper_sprite.gd` (lihat AC-4); `Q-001` di LOG run 0A tetap tertulis DEFERRED, hanya orchestrator yang mengubah status.
11. `docs/design/character/loper_agen/loper_agen_frames.tres` (keluaran `produce.py`, 15 animasi) dan `loper_sprite.gd` salinan di folder docs tidak diubah; yang dipakai game adalah `assets/sprites/loper/loper_agen_frames.tres` gabungan.

#### Gerbang yang dijalankan (perintah dan hasil)

```
godot --headless --import                                           # repo kerja: 0 ERROR/WARNING
mkdir -p build && godot --headless --script res://tests/run_tests.gd 2>&1 | tee build/tests.log
                                                                    # 3315 lolos, 0 gagal (sebelum: 2102 di main)
python3 tools/cek_keluaran_tes.py --ketat build/tests.log           # lolos (3315 lolos, 0 gagal, 0 peringatan), exit 0
python3 tools/tests_cek/uji_pemeriksa.py                            # 16 kasus, 0 menyimpang
python3 tools/tests_cek/uji_bangun_frames.py                        # 28 lolos, 0 gagal
python3 tools/loper_art/bangun_frames.py --cek                      # sama: 7 berkas
godot --headless --path . --quit-after 2                            # hanya banner; 0 ERROR/WARNING/SCRIPT ERROR
godot --headless --path . --script res://tests/probe_layar.gd       # 0 ERROR, 0 PECAHAN
# klon bersih di scratchpad (git clone --branch feat/sprite-lempar-melambat):
godot --headless --import                                           # exit 0, 0 ERROR/WARNING
/usr/bin/git status --porcelain -uall | wc -l                       # 0
godot --headless --script res://tests/run_tests.gd ...              # 3313 lolos, 0 gagal (sebelum commit tes batas inklusif); pemeriksa --ketat exit 0
godot --headless --path . --quit-after 2                            # 0 ERROR/WARNING
git diff main --name-only | grep -E "keystore|\.apk|\.aab|\.godot/|^build/|^builds/|\.jks|\.p12|export_credentials"   # kosong
git branch --show-current                                           # feat/sprite-lempar-melambat; main tetap f6594cd
```

#### Hal yang tidak bisa saya verifikasi

Rasa kontrol dan animasi di A54 (kayuh 4 fps, lempar 0,33 detik, ambang 12 px, abaikan swipe saat melempar, melambat berkedip), 60 fps, keterbacaan koran kecil di layar 450 dpi, perilaku sentuhan multi-jari dan background di Android sungguhan, dan CI GitHub (langkah baru `uji_bangun_frames.py`). Tidak ada APK dibangun atau dipasang oleh saya.

### QA (iterasi 1)

Peran: auditor independen. Semua hasil di bawah dijalankan sendiri oleh QA (klaim Dev tidak dipercaya). Klon bersih `git clone --branch feat/sprite-lempar-melambat` di scratchpad (`.../scratchpad/qa_sprite/klon`, commit `5ef5062`); `godot` 4.7.2.stable.official.ed1daf0bf, macOS Apple M1. Tidak ada `adb`, tidak ada unduhan, tidak ada push/PR/merge, Editor Settings tidak disentuh, tidak ada APK. Python yang membaca berkas selalu `python3 -I`. Eksperimen dan mutasi hanya di klon; repo kerja hanya ketambahan LOG ini dan tangkapan layar `shots/qa_*.png`.

#### Gerbang objektif

```
godot --headless --import                                  # exit 0, 0 ERROR/WARNING/SCRIPT ERROR; git status --porcelain -uall = 0 baris
godot --headless --script res://tests/run_tests.gd | tee   # 3315 lolos, 0 gagal (baseline main di klon main sendiri: 2102 lolos, 0 gagal)
python3 -I tools/cek_keluaran_tes.py build/tests.log       # lolos, exit 0
python3 -I tools/cek_keluaran_tes.py --ketat build/tests.log   # lolos (0 peringatan), exit 0
python3 -I tools/tests_cek/uji_pemeriksa.py                # 16 kasus, 0 menyimpang
python3 -I tools/tests_cek/uji_bangun_frames.py            # 28 lolos, 0 gagal
godot --headless --path . --quit-after 2                   # hanya banner, 0 ERROR/WARNING
godot --headless --path . --script res://tests/probe_layar.gd   # 0 ERROR, 0 PECAHAN (langkah CI)
godot --headless --path . --export-pack "Android" <scratchpad>/qa-uji.pck   # exit 0; pck memuat PNG lempar+melambat dan .tres, tanpa tests/, docs/, atau .json
git diff main...HEAD --name-only | grep -E "keystore|\.apk|\.aab|\.godot/|^build/|^builds/|\.jks|\.p12|export_credentials"   # kosong
git diff --check main...HEAD                               # bersih
```

Tambahan yang diperiksa:
- Commit: 9 commit di atas `main` (`007fc07` SPEC/LOG orchestrator + 8 Dev), semua `<tipe>: <ringkasan>` bahasa Indonesia, tidak ada commit di `main` (tetap `f6594cd`). `.import` kedua PNG, `lempar_waktu.gd.uid`, `tes_sprite.gd.uid`, `probe_lempar_jendela.gd.uid` hadir; `.import` sama dengan `loper_agen.png.import` selain uid/path. Catatan push: QS-002.
- Aset: `cmp` 6 pasang PNG/JSON `assets/sprites/loper/` lawan `docs/design/character/loper_agen/{,melambat/,lempar/}` semuanya identik. `bangun_frames.py --out` dijalankan dua kali: `cmp` identik antar-run dan identik dengan `loper_agen_frames.tres` di repo.
- `.tres` diperiksa dengan skrip QA sendiri (regex, bukan kode Dev; `scratchpad/qa_sprite/cek_tres.py`): tepat 38 animasi; nama, urutan, `loop`, `speed` dan 4 region + atlas (ext_resource -> sheet yang benar) tiap frame sama dengan tiga JSON; loop `false` tepat 18 (semua lempar), `release_frame` = 2 untuk semua lempar; himpunan fps {4, 8, 10, 12}; id sub_resource unik; 60 `AtlasTexture` pertama dan teks 15 animasi kayuh identik dengan `.tres` di `main`.
- CI `tes.yml` (+3 baris): langkah `python3 tools/tests_cek/uji_bangun_frames.py` sebelum import. YAML valid (`ruby -ryaml YAML.load_file`), langkah lama tidak diubah atau dilonggarkan, langkah baru stdlib tanpa jaringan dan hanya menulis ke folder sementara. Tidak bisa dijalankan lokal di runner: NEEDS-MANUAL (CI hijau di PR).

#### Telusur AC dan keputusan

| Item | Verdict | Bukti QA |
|---|---|---|
| AC-1 | OK | Gerbang di atas; klon bersih tanpa berkas belum ter-commit sesudah import. |
| AC-2 | OK | `cmp` 6 berkas, dua kali bangun identik, skrip `.tres` QA (38 animasi, loop/fps/region/release_frame). Mutan M03, M23, M24, M25 tertangkap (JSON aset diubah, lempar loop, melambat 8 fps, satu lempar 10 fps). |
| AC-3 | OK | Tes `tes_sprite.gd` meliputi 14,9/15,0/15,1% lewat rantai `StickMap` -> `tingkat_dari_stick`, 40 kombinasi nama lempar (18 nama berbeda, semuanya ada di SpriteFrames), +-2 -> serong sisi sama, sisi swipe (kiri/kanan, vertikal, 45 derajat, 11,99/12,0, nol/NaN/INF). Mutan M01, M04, M05, M05b, M06, M08, M12, M13, M26, M30, M37 tertangkap. Semua pemakai tingkat -1 diperiksa (lihat di bawah): tidak ada indeks negatif ke `NAMA_TINGKAT`. |
| AC-4 | OK | `LoperSprite`: sekali putar, `koran_lepas` tepat sekali di frame 2 (langkah 10), `lempar_selesai` sekali (langkah 20), kembali ke kayuh TERKINI (N02 tertangkap), lempar kedua ditolak (M27), `sprite_frames` null aman (Q-001a/b/c, M31), re-entrancy pendengar, `pedal_rate` 0. Waktu nyata (`_process`, bukan `maju`): 0,165 detik dan 0,340 detik. |
| AC-5 | OK | Stick bawah -> `melambat_*` + dorongan kecepatan tetap (M19, N17); swipe sintetis (`Input.parse_input_event` + flush) di tiga tingkat kiri/kanan (M20, M21, M22); kidal tidak menukar sisi (N13); vertikal, pendek, tap tidak melempar; stick + swipe dua jari; FOCUS_OUT dan PAUSED menutup lempar (M10, M10b, M10c, M32). |
| AC-6 | OK | Tiga konstanta `LEMPAR_*` satu baris literal di `config.gd` (lolos `ConfigParser`), tercatat di BALANCING 2 sebagai usulan, nilai sama dengan kode. `LEMPAR_FPS`/`MELAMBAT_FPS` tidak dibuat dan tidak dibutuhkan (fps dari SpriteFrames, `get_animation_speed`; N08 menolak fps literal). |
| AC-7 | OK | README lempar dan melambat, `docs/design/character/README.md`, ART_DIRECTION 3.2/3.4/changelog, AGENTS.md, docs/README.md, SETUP_ANDROID bagian 8, `tools/loper_art/README.md`, perintah di `00-project-core.mdc` diperbarui; `DEV_PHASES.md` dan `ROADMAP.md` tidak disentuh. Tidak ada kata \"dikunci\" untuk hal usulan (semua ditulis \"usulan\", \"tetap usulan sampai dinilai di HP\"). |
| AC-8 | OK | Tangkapan layar Dev ada dan terbaca; QA mengulang dengan skrip sendiri dan waktu nyata (bagian visual di bawah). |
| AC-9 | OK dengan catatan | Commit kecil berformat benar, tidak ada commit di `main`; push: QS-002. |
| D-1 | OK (lihat QS-001) | Tingkat melambat dari tanda komponen y stick sesudah zona mati; kecepatan dari `BikeDrive`. |
| D-2 | OK | Kiri layar = seberang, kanan = dekat; ambang 12 px inklusif dari panjang swipe; vertikal/45 derajat tepat = tidak melempar (pilihan Dev, tercatat). |
| D-3 | OK | `lempar_<sisi>_<kecepatan>_<arah>`, melambat -> santai, +-2 -> serong; swipe saat melempar diabaikan. |
| D-4 | OK | Kembali ke kayuh tingkat/arah terkini; indeks frame dilanjutkan (frame lempar 3 -> kayuh 0, terlihat di render). |
| D-5 | OK | `koran_lepas(sisi)` sekali di frame 2, `lempar_selesai` sekali; tidak ada pendengar selain tes. |
| D-6 | OK | Satu `.tres` 38 animasi dibuat skrip stdlib dengan templat `produce.py`; 15 animasi kayuh tidak berubah. |

Pemakai tingkat -1 yang diperiksa: `LoperAnim` (`jepit_tingkat`, `nama_animasi`, `tingkat_untuk_lempar`, `nama_lempar`: semua akses `NAMA_TINGKAT[...]` terjadi sesudah cabang melambat atau memakai `maxi(.., 0)`), `BikeDrive.Hasil.tingkat_sprite`, `SepedaUji.gerak`, `LoperSprite.speed_level` (`@export_range(-1, 2)`), `scenes/dev/graybox.tscn` (`speed_level = 1`), `tests/probe_lempar_jendela.gd`; `HudDev` tidak memakai tingkat sprite. Tes lama yang berubah (15 -> 38, stick bawah santai -> melambat, `speed_level` -4 -> -1, daftar putih kiri/kanan, `_test_input_terpadu`) dibandingkan baris demi baris dengan `git diff main...HEAD -- tests/`: semuanya beralasan, tidak ada yang dihapus, di-skip, atau dilonggarkan; baseline 2102 pemeriksaan di `main` terkonfirmasi dan sekarang 3315. Daftar putih kedua penjaga kiri/kanan (`NAMA_SISI_LEMPAR`) hanya berlaku di dalam bloknya, dengan 4 tes negatif (nama blok lain, sesudah blok ditutup, di fungsi, blok sah).

#### Review kode terhadap rule

`gdscript`: static typing lengkap (return type di semua fungsi, lambda `-> void`), logika murni di `systems/` (`LoperAnim`, `LemparWaktu` tanpa node, waktu sebagai parameter), `kiri`/`kanan` hanya sebagai nama animasi lewat `NAMA_SISI_LEMPAR` dan komentar, input dipisah dari logika, pause/background ditangani (`_notification` di `JalanUji`), tidak ada alokasi per frame (`_process` sprite hanya menyala saat melempar). `balancing`: tiga konstanta satu baris literal dan tercatat di BALANCING 2 (angka sama); `LEMPAR_FRAME_LEPAS` dan `LEMPAR_TOLERANSI_DETIK` bukan angka tuning tetapi sah ditaruh di Config karena penjaga literal; ada preseden (`SPRITE_SUDUT_TOLERANSI_DERAJAT`). `art-assets`: `.tres` lewat skrip, PNG/JSON byte-identik, impor Lossless/Nearest/tanpa mipmap, penamaan sesuai. `testing`: tes deterministik (`dt` tetap), tidak ada tes dihapus. `docs`: bahasa Indonesia, \"usulan\" dipertahankan. `git-workflow`: format commit dan tanpa berkas terlarang OK. Tidak ada teks pemain baru (tidak ada `tr()` baru dibutuhkan). Tidak ada keputusan terbuka (ROADMAP 5) yang diputuskan diam-diam; keputusan swipe 45 derajat dan \"abaikan swipe saat melempar\" tercatat sebagai usulan.

#### Uji mutasi (QA, skrip scratchpad; tiap mutan satu suntingan di klon, `run_tests.gd` + pemeriksa `--ketat`, dipulihkan setelahnya)

54 mutan valid: **52 tertangkap, 2 hidup**. Daftar permintaan orchestrator, semuanya tertangkap:

| Mutan | Hasil |
|---|---|
| M01 balik sisi lempar di `sisi_dari_swipe` | tertangkap |
| M21 arah swipe dibalik di `JalanUji` | tertangkap |
| M02 `LEMPAR_FRAME_LEPAS` 3; M03 `release_frame` JSON 3 | tertangkap |
| M23 satu lempar `loop: true` | tertangkap |
| M04 lupa menjepit arah 90 derajat | tertangkap |
| M05 melambat ambang -0,2; M05b melambat ambang <= 0 | tertangkap |
| M06 fallback melambat -> santai dihapus | tertangkap |
| M07 `koran_lepas` ganda; M07b `lempar_selesai` ganda; M16 lepas berulang | tertangkap |
| M08 ambang swipe `>` bukan `>=`; M37 ambang 0; M12 45 derajat melempar; M13 tanpa penjaga vertikal | tertangkap |
| N02 kembali ke animasi kayuh lama bukan terkini | tertangkap |
| M10, M10b, M10c, M32 `batalkan_lempar`/FOCUS_OUT/PAUSED dihapus | tertangkap |
| M11 `jepit_tingkat` -1 -> 0 | tertangkap |

Lainnya tertangkap: M14 (`pause()` dihapus), M15 (kayuh tidak diputar lagi), M17 (delta tidak dijepit), M19/N17 (stick bawah tidak melambat), M20/M22 (swipe tidak diteruskan/disambung), M24/M25 (fps), M26 (lempar selalu santai), M27 (lempar saat melempar), M30 (NaN = melambat), M31 (frames diganti saat lempar), M34 (re-entrancy), M35 (dt negatif), M36 (nama arah), N03/N04 (tingkat/arah diabaikan), N05..N11, N13..N16, N18. Hidup: **M28** (reset `_waktu_lempar` di `lempar()` dihapus; setara karena `_akhiri_lempar` sudah menolkan waktu) dan **N19** (`JalanUji` mematikan `_process` sendiri; semua tes scene mematikannya sendiri, lihat QS-005). Tes bermakna, bukan tautologi: mutan yang menyentuh perilaku (sisi, frame lepas, sinyal, kembali ke kayuh terkini, batal) selalu gagal di pemeriksaan spesifiknya.

#### Uji tambahan QA (tidak di-commit)

- Waktu nyata headless (`qa_nyata.gd`, scene utama penuh, tanpa mematikan `_process`): 7 skenario, 0 gagal, 0 ERROR/WARNING: swipe kanan (lepas 0,165 s, selesai 0,340 s), lima swipe 50 ms beruntun (satu lempar), FOCUS_OUT dan PAUSED di tengah lempar (tidak ada sinyal sisa, swipe sesudahnya normal), stick bawah penuh + swipe (`lempar_kanan_santai_normal` lalu kembali `melambat_normal`, 4 fps), ngebut + stick dilepas di tengah lempar, 200 swipe acak dengan FOCUS_OUT berkala.
- Repro QS-001 (headless; potongan, dijalankan sebagai `--script`):
```gdscript
var rng := RandomNumberGenerator.new(); rng.seed = 42
var kec: float = Config.KECEPATAN_SANTAI_UD; var lat: float = 0.0; var lalu: int = 99; var ganti: int = 0
for i in 600:
	var h: BikeDrive.Hasil = BikeDrive.langkah(kec, lat, StickMap.petakan(Vector2(20.0, rng.randfn(0.0, 1.5))), 1.0 / 60.0)
	kec = h.kecepatan_ud; lat = h.lateral_ubin
	if lalu != 99 and h.tingkat_sprite != lalu: ganti += 1
	lalu = h.tingkat_sprite
# hasil: ganti = 291 dalam 10 detik, kecepatan terendah 2,91 u/d
```

#### Validasi visual (non-headless, jendela asli, waktu nyata)

Skrip QA `qa_visual.gd` (scratchpad) pada 2340x1080 (viewport 780x360, x3) dan 1920x1080 (640x360, x3), OpenGL 4.1 Metal; tanpa `set_process(false)`, jadi `_process` sprite berjalan nyata. Pengukuran memakai latar rata (ubin, objek, HUD disembunyikan) dan membandingkan piksel render, bukan nilai node.
- **Melambat berbeda dari santai hanya pada kecepatan putar:** 20/20 frame (5 arah x 4 frame) identik piksel demi piksel di render (kedua resolusi); kecepatan putar nyata (jumlah `frame_changed` selama 3 detik): santai 7,99 fps, melambat 4,00 fps, kecepatan sepeda 1,5 u/d (`qa_*_paritas_santai_atas_melambat_bawah.png`, `qa_*_melambat_normal_penuh.png`).
- **Titik pijak tidak melompat:** pada keempat kasus (santai dan ngebut, swipe kiri dan kanan), baris alas sprite relatif titik pijak = +8 konstan (kayuh sebelum, lempar f0..f3, kayuh sesudah; sekitar 13 render per frame animasi), puncak sprite konstan (-42 santai, -43 ngebut); hanya jangkauan lengan berubah (kiri f2 x0 -23, kanan f2 x1 +20 santai dan +22 ngebut). Urutan kayuh yang terlihat: kayuh f3 -> lempar f0, f1, f2, f3 -> kayuh f0.
- **Keempat frame lempar terbaca** kiri dan kanan (santai dan ngebut): f0 koran di sisi tas, f1 koran diangkat (kiri: di atas bahu dekat topi; kanan: ditarik ke badan), f2 lengan terjulur dengan koran di sisi yang benar (kiri: ke kiri atas = sisi seberang/fasad; kanan: ke kanan bawah = sisi dekat), f3 lengan tanpa koran. Kaki tetap mengayuh dan gambar tidak berpindah. Koran putih dan topi putih berdekatan di f1 kiri: terbaca di desktop, nilai di A54 (NEEDS-MANUAL).
- **Ketajaman:** `python3 -I tools/cek_blok_piksel.py 3 --kecualikan <kotak HUD>`: 0 blok tidak seragam pada 21 tangkapan layar penuh per resolusi (16 frame lempar, 2 dua-jari, 2 kidal, 1 melambat) dan pada lembar potongan/paritas 2340x1080 tanpa pengecualian. Mode kidal memindahkan panel kecepatan ke kanan, jadi kotak pengecualian HUD-nya berbeda (`1200,950,1712,1060` di 2340; `780,950,1295,1060` di 1920).
- **Tumpang tindih:** tangan kanan: cincin dan knob stick (kiri bawah), panel kecepatan, dan tombol Kidal tidak menyentuh sprite lempar (`qa_*_dua_jari_lempar_f2.png`: ngebut 5,1 u/d, lempar kiri, stick ditahan). Kidal: garis swipe melintasi sprite selama jari ditahan (QS-004), tidak sesudah jari diangkat.
- Tidak bisa dinilai agent: rasa gerak, apakah 0,33 detik terasa cepat/lambat, kenyamanan ambang 12 px, kejelasan di A54 fisik (NEEDS-MANUAL di atas).

#### Verdict QA iterasi 1: **PASS**
Semua gerbang hijau, 0 Blocker, 0 Major OPEN. Temuan: 2 Minor (QS-001 DEFERRED desain, QS-002 untuk orchestrator), 3 Nit (QS-003..QS-005), 6 butir NEEDS-MANUAL (QA) di samping butir Dev dan SPEC. Hal yang paling perlu perhatian pemilik sebelum merge: QS-001 (aturan melambat dari tanda sumbu y) dan rebase ke `origin/main` (QS-003).

## Keputusan & catatan
- Keputusan pemilik (2026-10-09): pasang sprite melambat dan lempar dulu untuk dilihat sebelum Fase 1; skala tetap x3; izin pasang APK ke A54 berlaku (hanya orchestrator yang menyentuh HP). Lihat SPEC.
- Keputusan struktur D-1..D-6 ada di SPEC; diambil orchestrator dan bisa ditolak di review PR.
- Penutupan run (orchestrator, 2026-10-09): QA iterasi 1 PASS. Pemilik memberi izin (2026-10-09) untuk langsung merge PR #18 dan membangun serta memasang APK ke A54 setelah QA selesai, dengan syarat QA PASS, rebase ke `main` terbaru, gerbang dan CI hijau. QS-001 (melambat dipicu tanda komponen y stick tanpa ambang/histeresis) tetap DEFERRED: keputusan desain pemilik, dan sprite `meluncur` yang baru masuk `main` (PR #16) mengubah pemetaan stick-bawah, jadi diputuskan di Run 1A (rekomendasi tertulis di SPEC). QS-004 (garis swipe kidal menutup sprite sebentar) dan QS-005 (cakupan jalur `_process`) DEFERRED.

