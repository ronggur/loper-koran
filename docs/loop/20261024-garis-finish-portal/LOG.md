# Loop Log — 20261024-garis-finish-portal
Scope: Run garis finish dengan portal satpam (sepeda melaju keluar viewport)  ·  Branch: feat/garis-finish-portal (dari main 92255fa, rilis 0.7.0 + PR #66)  ·  Mulai: 2026-10-24  ·  Godot: 4.7.2

## Status: IN_PROGRESS   (iterasi 1/2; Dev bagian A selesai, B/C/D belum)

## Lingkungan (orchestrator, awal run)
- Basis: `main` = `origin/main` = `92255fa` (memuat PR #66 UI-2, di-merge 2026-10-24).
- sha256 save asli: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e`.
- `.claude/` untracked: bukan bagian run, tidak di-commit.

## Baseline (Dev bagian A mengisi, di main sebelum mengubah apa pun)
Diukur Dev bagian A, 2026-10-24, di `99b0d29` (= main `92255fa` + dua commit docs), sebelum satu pun perubahan. Godot 4.7.2 (`/opt/homebrew/bin/godot`), satu proses sekaligus.
- `godot --headless --import`: exit 0.
- `godot --headless --path . --quit-after 2`: exit 0, 0 baris ERROR/WARNING.
- `godot --headless --script res://tests/run_tests.gd`: exit 0; `tools/cek_keluaran_tes.py`: **28489 lolos, 0 gagal, 0 peringatan** (lolos).
- 17 `tools/tests_cek/uji_*.py`, semua exit 0: uji_aset_fase3 148, uji_aset_gelombang1 352, uji_aset_kucing 13, uji_aset_lampu_pohon 183, uji_aset_pasang_5b 595, uji_aset_pasang_gelombang1 565, uji_aset_simpang 214, uji_bangun_frames 62, uji_pemeriksa 16 kasus 0 menyimpang, uji_sintesis_kondisi 55, uji_sintesis_lempar 111, uji_sintesis_milestone 18, uji_sintesis_misi 47, uji_sintesis_rute 90, uji_sintesis_sepeda 32, uji_ui_lencana 25, uji_ui_redesain LOLOS.
- `godot --headless --path . --export-pack "Android" build/kring-uji.pck`: exit 0 (2.018.972 byte).
- sha256 save asli (`~/Library/Application Support/Godot/app_userdata/Kring Kring!/save.json`, tidak dibuka lewat game): `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e` (sama dengan awal run).

## Butir terbuka pemilik
- Lisensi latar bengkel (UI-1) belum dicatat; di luar scope run ini.

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 1 | | | | | |

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|
| A-1 | 1 | rendah | `prop_portal_satpam.png` frame 1 (terbuka) | Palang terangkat 75 derajat terpotong rata di tepi ATAS sel: baris y=0 masih berisi warna palang (x 23..28), bbox terbuka y 0..50. Sel 80x64 dengan pijak y=48 hanya menyisakan 48 px di atas tanah, sedangkan ujung palang terangkat berada sekitar z = 16 + 48 x sin 75 = 62 px (kira-kira 14 px, sekitar 28 persen panjang palang, terpotong). Tidak diperbaiki: memperbaikinya berarti mengubah sel atau pijak yang dikunci SPEC AC-1. | FIXED (G-1a, amandemen orchestrator) | `properti.py` (`PORTAL_SEL` 80x92, `PORTAL_PIJAK` (14, 60)), `render.py`, `komposisi.py`; aset `prop_portal_satpam.{png,json}` | `uji_aset_pasang_gelombang1.py` (bbox, tepi transparan, margin >= 1), `tes_export.gd` (tepi sel transparan) |
| A-2 | 1 | rendah | `prop_portal_satpam.png` frame 0 (tertutup) | Penyangga ujung palang (x = 52 unit, tinggi 12) terpotong di tepi BAWAH sel: kaki penyangga ada di layar y = 48 + 26 = 74 (> 63); baris 62 dan 63 identik (x 63..68, abu logam), tersisa nub abu 6x2 px di bawah ujung palang tanpa garis luar bawah. Alasan tidak diperbaiki sama dengan A-1. Pengaruh visual kecil. | FIXED (G-1a) | sama dengan A-1 | sama dengan A-1 |

## Tes lama yang diubah (G-1..G-6), per baris
(Dev mengisi: file, asersi, nilai lama -> baru, alasan)

Bagian A (portal dipasang, G-1; tidak ada perilaku game yang berubah, hanya daftar aset "yang dipasang"):
- `tools/tests_cek/uji_aset_pasang_gelombang1.py`: `TIDAK_DIPASANG` tidak lagi memuat `'prop_portal'` (portal sekarang dipasang; `prop_pos` tetap); `ekspektasi_skrip()` props + `prop_portal_satpam.{png,json}` (set tepat keluaran `render.py --salin`); `daftar_json` + portal (JSON konsisten, impor Lossless); asersi baru: dari keluarga `prop_portal*`/`prop_pos*` di `assets/` hanya `prop_portal_satpam.{json,png}`, JSON portal sel `[80, 64]` frames 2 pijak `[14, 48]` literal, PNG 160x64, total sprite `--salin` = 15. 565 -> 581 lolos.
- `tools/tests_cek/uji_aset_pasang_5b.py`: regex `TIDAK_DIPASANG_REGEX` `r'^prop_portal'` -> `r'^prop_portal(?!_satpam\.)'`; `ekspektasi_repo()` dan `harap_keluaran['props']` + `PROPS_GARIS_FINISH`. 595 -> 599 lolos.
- `tests/tes_ubin.gd`: `TERLARANG` (pemindai rujukan sumber, AC-17 ubin) tidak lagi memuat `"prop_" + "portal"` (9 -> 8 kata); `prop_pos_` tetap terlarang. Alasan: bagian C akan merujuk `prop_portal_satpam` dari kode.
- `tests/tes_koran_sprite.gd`: `SUFIKS_5B_PROPS` + `"portal_satpam"` (6 -> 7). Memengaruhi asersi "tidak ada rujukan nama prop_/vfx_/mission_ di luar aset terpasang" (kini mengenal portal) dan "folder props: PNG dan JSON hanya untuk aset terpasang" (14 -> 15 nama; sempat GAGAL dua asersi ini sebelum diubah, sebagai bukti asersinya hidup).
- `tests/tes_export.gd`: fungsi baru `_test_aset_garis_finish_ikut_paket` (portal PNG/.import/JSON ikut paket dan tidak dikecualikan preset, impor Lossless tanpa mipmap, JSON sel 80x64 dua frame pijak (14, 48), PNG = dua sel, isi `assets/sprites/props` tepat 15 PNG, 9 berkas gelombang 1 yang tidak dipasang tidak ada); `JALUR_WAJIB_IKUT_GARIS_FINISH` masuk loop `exclude_filter` di `_test_preset_asli`. Tidak ada nilai lama yang diubah. Total run_tests 28489 -> 28516 lolos (+27 asersi), 0 gagal.

## NEEDS-MANUAL (uji di HP)
- [ ] SETUP_ANDROID 8.20 (ditulis bagian D)

## Keputusan & catatan
- Putusan orchestrator G-1..G-6 di SPEC.

### Bagian A (Dev, iterasi 1): catatan
- Mekanisme "daftar tunggal": `render.py` punya satu kamus pasang per run (`PASANG`, `PASANG_5B`, kini `PASANG_GARIS_FINISH = {'props': ['prop_portal_satpam']}`) yang digabung di blok `--salin`; uji menulis daftar yang SAMA secara eksplisit sendiri (bukan membaca skrip), jadi menambah/menghapus portal di salah satu sisi saja menggagalkan uji. `--salin` kini mencetak "hanya 15 sprite" (6 koran + 7 VFX/kilau + tong sampah logam + portal; brief menyebut 14 sprite, hitungan skrip 15 karena tong sampah logam 5B ikut). 13 sprite lama dan tong sampah: `git status` bersih setelah `--salin` (byte-identik), uji golden 5B hijau.
- Impor: `prop_portal_satpam.png.import` identik dengan `prop_tong_sampah_logam.png.import` selain uid/path: `compress/mode=0` (Lossless), `mipmaps/generate=false`, bukan VRAM; filter Nearest dari `project.godot` (`default_texture_filter=0`).
- JSON: `cell` [80, 64], `frames` 2, `ground_anchor` [14, 48], PNG 160x64.
- Paket (`--export-pack`): memuat `assets/sprites/props/prop_portal_satpam.{png,json,png.import}` dan ctex terimpornya; tidak ada `pos_satpam`, jejak, mangkuk, percikan, polisi tidur, zebra, genangan, tong biru (0 kecocokan di pck, diperiksa dengan `strings`).

### Pengukuran sprite portal untuk bagian C (hanya angka, tidak memutuskan)
Sprite DILIHAT (PNG x6 dan lembar `docs/design/environment/gelombang1/lembar_properti_x5.png`).
- Ukuran: sel 80x64, dua frame (0 tertutup, 1 terbuka), pijak (14, 48) = kaki tiang. Bounding box opak frame 0: x 4..69, y 24..63 (66x40 px); frame 1: x 4..28, y 0..50 (25x51 px). Bayangan penanda (alpha 71) ada di bawah tiang.
- Orientasi: tiang abu gelap dengan pemberat di KIRI (sisi seberang), palang belang bata/krem (6 unit per belang) membentang dari tiang ke KANAN-BAWAH di layar dengan kemiringan tepat 1:2 (dari kira-kira (15, 31) ke (69, 58)). Itu sumbu +x dunia = `Iso.ARAH_DEKAT` (satu ubin = (+32, +16) px), jadi palang MELINTANG jalan dengan benar di proyeksi rute (jalan naik ke kanan atas = sumbu -y). Ujung palang bertumpu pada penyangga pendek di kanan bawah. Terbuka: palang diputar 75 derajat ke atas dari sendi di tiang.
- Tinggi: puncak tiang (pemberat) di y=24 pada frame tertutup, pijak y=48, jadi sekitar 24 px dari tanah (tiang 18 unit + pemberat); palang berada 16 px di atas tanah di tiang dan turun mengikuti kemiringan layar ke ujung. Pemain+sepeda: sel 46x58, badan 47 px.
- Panjang palang: 52 unit = 1,625 ubin = 52 px mendatar (26 px vertikal). Jangkauan seluruhnya dari pemberat (x = -4) sampai penyangga (x = 54): 58 unit = 1,81 ubin.
- Lebar jalan (Config): aspal `JALAN_LEBAR_UBIN` = 2,0 ubin (dua lajur: x -1,0 .. +1,0; 64 px mendatar), trotoar `JALAN_TROTOAR_UBIN` = 1,0 tiap sisi, rumput tepi `JALAN_RUMPUT_TEPI_UBIN` = 1,0 tiap sisi. Aspal + trotoar = 4,0 ubin (128 px mendatar) = jalur yang boleh dijelajahi sepeda (`BikeMotion` menjepit lateral di +-2,0). Aspal + trotoar + rumput tepi = 6,0 ubin.
- Perbandingan: palang 1,625 ubin = 81 persen lebar aspal (kurang 0,375 ubin = 12 px dari aspal penuh), 41 persen lebar aspal + trotoar (kurang 2,375 ubin = 76 px dari 4,0). SATU sprite tidak menutup lebar jalan yang dilalui sepeda; tiang di lateral L membuat palang berujung di L + 1,6875 (untuk menutup aspal -1..+1 dibutuhkan palang >= 2,0 ubin; untuk jalur sepeda -2..+2 dibutuhkan >= 4,0). Tidak ada varian cermin: `flip_h` memutar palang ke arah sumbu jalan (-y), bukan melintang, jadi tidak bisa dipakai untuk sisi lain. Sprite hanya satu per sel dan bukan sambungan; menyusun lebih dari satu salinan berarti banyak tiang di tengah jalan.
- Y-sort untuk C: pijak ada di tiang (sisi seberang), palang menjulur ke sisi dekat pada y dunia (maju) yang sama dengan tiang, jadi seluruh palang diurutkan pada nilai y tiang.

### Gerbang bagian A (hasil akhir, sesudah semua perubahan A)
- `godot --headless --import`: exit 0. `godot --headless --path . --quit-after 2`: exit 0, 0 baris ERROR/WARNING.
- `run_tests.gd` + `cek_keluaran_tes.py`: **28516 lolos, 0 gagal, 0 peringatan** (baseline 28489; +27 asersi bagian A).
- 17 `uji_*.py` exit 0 (uji_aset_pasang_gelombang1 565 -> 581, uji_aset_pasang_5b 595 -> 599, sisanya sama dengan baseline).
- `--export-pack "Android" build/kring-uji.pck`: exit 0 (2.020.528 byte), memuat portal (PNG, JSON, .import, ctex), tanpa aset gelombang 1 lain yang tak dipasang.
- sha256 save asli sesudah semua perintah: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e` (tidak berubah).
- Commit bagian A: `art:` portal + render.py, `test:` uji aset/tes_export/pemindai, `docs:` baseline dan log, `docs:`/`chore:` README env_art.

### G-1a: perbaikan A-1 dan A-2 lewat renderer (Dev bagian A, tambahan atas permintaan orchestrator)
- Pengukuran dengan sel besar sementara (relatif pijak, kedua frame): kiri -10, kanan +55, atas -57 (palang terbuka), bawah +27 (kaki penyangga tertutup; kaki penyangga ternyata menggantung dari ujung palang sampai tanah, jadi frame tertutup tersisa 2 baris saja yang terlihat di sel lama).
- Sel baru **80x92, pijak (14, 60)** (konstanta `PORTAL_SEL`, `PORTAL_PIJAK` di `properti.py`, dipakai `render.py` dan `komposisi.py`; angka pada docstring lama "80x56" ikut dibetulkan). Lebar 80 dipertahankan. PNG 160x92. Bentuk 3D tidak diubah: frame tertutup baris 0..61 sel lama identik piksel dengan baris 12..73 sel baru (0 piksel beda); frame terbuka identik di seluruh wilayah lama, hanya ujung palang yang tadinya terpotong kini utuh.
- bbox terukur sel baru: frame 0 (tertutup) x 4..69, y 36..87 (66x52 px), margin kiri 4, kanan 10, atas 36, bawah 4; frame 1 (terbuka) x 4..31, y 3..62 (28x60 px), margin kiri 4, kanan 48, atas 3, bawah 29. Margin transparan minimum 3 px (>= 1 px di semua sisi kedua frame). PNG dilihat (x6): palang terbuka utuh dengan ujung bulat berbelang, penyangga tertutup utuh dengan garis luar bawah.
- Efek ke angka pengukuran bagian A di atas ("Pengukuran sprite portal"): ukuran bbox, tinggi di atas tanah (palang terbuka kini 57 px di atas pijak) dan sel/pijak berubah seperti di atas; panjang palang 52 unit = 1,625 ubin, perbandingan dengan lebar jalan, orientasi, dan Y-sort TIDAK berubah. Pijak kini y=60 (bukan 48) untuk Y-sort dan penempatan di scene.
- Mock `docs/design/environment/gelombang1/{komposisi_siang_x3,komposisi_sore_x3,lembar_properti_x5}.png` dibangkitkan ulang `render.py --mock` (enam mock lain beda byte tetapi piksel sama, tidak di-commit).
- Tes diperbarui: `uji_aset_pasang_gelombang1.py` (JSON literal `[80, 92]`/`[14, 60]`, PNG 160x92, bbox kedua frame, tepi sel transparan, margin >= 1; 581 -> 587 lolos), `tes_export.gd` (sel 80x92, pijak (14, 60), tepi sel tiap frame transparan penuh dibaca dari tekstur nyata; +2 asersi), ART_DIRECTION 6.x, ROADMAP baris 88, README env_art, SPEC AC-1 dan G-1 (+ G-1a).
- Gerbang ulang sesudah G-1a: import exit 0; `--quit-after 2` 0 ERROR/WARNING; run_tests + pemeriksa **28518 lolos, 0 gagal, 0 peringatan** (28516 + 2 asersi tepi sel portal); 17 `uji_*.py` exit 0 (uji_aset_pasang_gelombang1 587, uji_aset_gelombang1 352 dengan mock baru, sisanya tidak berubah); `--export-pack` exit 0 dan memuat portal (tanpa `pos_satpam`); sha256 save asli tidak berubah (`37d6d6cb...549e`).
