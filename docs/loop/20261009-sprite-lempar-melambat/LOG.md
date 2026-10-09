# Loop Log — 20261009-sprite-lempar-melambat
Scope: pasang sprite melambat dan lempar koran (usulan, PR #15) ke game untuk dilihat di A54  ·  Branch: feat/sprite-lempar-melambat  ·  Mulai: 2026-10-09  ·  Godot: 4.7.2.stable.official.ed1daf0bf

## Status: IN_PROGRESS   (iterasi saat ini: 1/2)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 1 | AC-1..AC-9 semua dikerjakan (8 commit di `feat/sprite-lempar-melambat`, tanpa push, tanpa `BLOCKED`): pembangun `.tres` stdlib + 38 animasi, `LoperAnim` (melambat, nama lempar, sisi dari swipe), `LemparWaktu`, `LoperSprite` (melambat, `lempar`, sinyal, Q-001), kabel swipe di `JalanUji`, Config + BALANCING 2, bukti visual 2340x1080, dokumen AC-7. Tes 2102 -> 3315, 65 mutan nyata (62 tertangkap, 3 hidup dan dijelaskan). | import bersih (juga di clone bersih, `git status --porcelain` kosong), `3315 lolos, 0 gagal` + pemeriksa `--ketat` exit 0, `uji_pemeriksa.py` 16 kasus 0 menyimpang, `uji_bangun_frames.py` 28 lolos, `--quit-after 2` 0 ERROR/WARNING, probe layar bersih | | | |

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## NEEDS-MANUAL (uji di HP)
Daftar awal ada di SPEC bagian "Butuh uji perangkat nyata". Dev dan QA menambah langkah di sini.

Tambahan Dev (iterasi 1), selain daftar SPEC (versi lengkap juga ada di `docs/SETUP_ANDROID.md` bagian 8):
- Melambat: tarik stick sedikit ke bawah (sekitar 15 sampai 25%) sambil belok. Sprite melambat dipicu begitu komponen bawah melewati zona mati 15% (D-1, tanpa ambang tambahan) padahal kecepatan target baru turun sedikit (15,1% bawah = 2,998 u/d). Catat bila animasi berkedip antara santai (8 fps) dan melambat (4 fps) atau terasa terlalu cepat berubah.
- Lempar: titik kaki di frame 0 lempar adalah fase kayuh 0, jadi kaki bisa melompat satu fase saat swipe dilepas (kayuh frame 1 sampai 3 menjadi lempar frame 0); catat bila terasa.
- Lempar: koran putih dan topi putih berdekatan di frame 1 dan 2 sisi seberang; nilai keterbacaan titik lepas di A54.
- Kembali dari background saat lempar berjalan: animasi lempar ditutup tanpa melepas koran (tidak ada koran terbang di run ini).

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

## Keputusan & catatan
- Keputusan pemilik (2026-10-09): pasang sprite melambat dan lempar dulu untuk dilihat sebelum Fase 1; skala tetap x3; izin pasang APK ke A54 berlaku (hanya orchestrator yang menyentuh HP). Lihat SPEC.
- Keputusan struktur D-1..D-6 ada di SPEC; diambil orchestrator dan bisa ditolak di review PR.
