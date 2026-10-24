# Loop Log — 20261024-garis-finish-portal
Scope: Run garis finish dengan portal satpam (sepeda melaju keluar viewport)  ·  Branch: feat/garis-finish-portal (dari main 92255fa, rilis 0.7.0 + PR #66)  ·  Mulai: 2026-10-24  ·  Godot: 4.7.2

## Status: IN_PROGRESS   (iterasi 1/2; Dev bagian A dan B selesai, C/D belum)

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

Bagian B (logika murni; perilaku game yang terlihat tidak berubah):
- `tests/tes_hasil.gd` `_test_siap_tampil` (G-4, AC-4): `HasilRute.siap_tampil(selesai, kecepatan_ud: float, koran)` -> `siap_tampil(selesai, sudah_keluar: bool, koran)`. Asersi lama -> baru: (1) `siap_tampil(true, 0.0, tanpa)` "selesai, berhenti, tanpa koran: siap" -> `siap_tampil(true, true, tanpa)` "selesai, sudah keluar, tanpa koran: siap"; (2) `(true, 0.0, [mendarat])` -> `(true, true, [mendarat])`; (3) `(true, 0.0, [mendarat, terbang])` -> `(true, true, [mendarat, terbang])` tetap false; (4) `(true, 0.01, tanpa)` "sepeda masih bergerak 0,01 u/d: belum" -> `(true, false, tanpa)` "sepeda belum keluar viewport: belum"; (5) `(false, 0.0, tanpa)` "rute belum selesai" -> `(false, true, tanpa)`; (6) `(true, NAN, tanpa)` "kecepatan NaN: belum" DIHAPUS (tidak ada lagi parameter kecepatan; NaN pada geometri diuji di `tes_garis_finish`: sisa tak hingga = tidak pernah keluar). Alasan: G-4 mengganti syarat "kecepatan 0" dengan "sudah keluar viewport". 6 asersi -> 5.
- `scripts/entities/rute_main.gd` (bukan tes; adaptor sementara agar proyek tetap terkompilasi dan perilaku game identik): `HasilRute.siap_tampil(_selesai, _sepeda.kecepatan_ud, ...)` -> `siap_tampil(_selesai, _sepeda.kecepatan_ud <= Config.HASIL_BERHENTI_TOLERANSI_UD, ...)`. Setara dengan perilaku lama (NaN dan di atas toleransi = belum; kecepatan tak mungkin -tak hingga). BAGIAN C: ganti dengan `AkhirRute.periksa_keluar`/fase `SUDAH_KELUAR` dan HAPUS `HASIL_BERHENTI_TOLERANSI_UD` (satu-satunya pemakai tinggal baris ini; sudah ditandai di komentar `config.gd`).
- Tes lain tidak berubah: `tes_rute_scene`, `tes_rintangan` (simulasi bot memakai `AkhirRute.stick_akhir`, kontrak lama dipertahankan), `tes_hud_rute_scene`, `tes_animasi_5c` tetap hijau tanpa suntingan. `BikeMotion` dan `EfekKondisi` tidak disentuh sama sekali (`git diff f4863c3 -- scripts/systems/bike_motion.gd scripts/systems/efek_kondisi.gd` kosong), jadi sidik gerak lama, `tes_gerak`, dan `tes_kondisi_gerak` identik bit demi bit tanpa perlu bukti tambahan.

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

### Bagian B (Dev, iterasi 1): logika murni garis finish

Commit: `feat:` AkhirRute + config + hasil_rute (4a9acf7), `test:` tes_garis_finish (fa034e1) dan penyusul. Tidak ada scene yang disentuh selain satu baris adaptor `rute_main.gd` (lihat "Tes lama yang diubah").

**API baru (`scripts/systems/akhir_rute.gd`; kontrak lama `periksa`, `Status`, `tercapai`, `stick_akhir` tidak berubah)**
- `enum Fase { SEBELUM, MELAJU_KELUAR, SUDAH_KELUAR }`, `class Keluar` (`fase`, `hampir_keluar` sticky, `baru_hampir_keluar`, `baru_keluar`, `sisa_ubin`), `periksa_keluar(fase_lama, hampir_lama, selesai, pijak_layar, ukuran) -> Keluar` (pola sama dengan `periksa`: pemanggil menyimpan fase dan bendera hampir; fase hanya maju; sinyal tepat sekali; langkah besar yang melompat ke SUDAH_KELUAR tetap memberi `baru_hampir_keluar` pada pemeriksaan yang sama).
- Gerak: `stick_keluar()` = `Vector2(0, RUTE_KELUAR_STICK_Y)` = (0, +1), `laju_dijaga(v)`, `keadaan_dijaga(keadaan)`, `langkah_keluar(keadaan, dt, beku_detik = 0, efek = null) -> BikeMotion.Hasil` (keadaan dijaga + stick lurus lewat `BikeMotion.langkah` apa adanya).
- Geometri: `posisi_layar_pijak(ukuran, geser_dorongan)`, `posisi_kamera(posisi_sepeda, ukuran, geser_dorongan)` (rumus sama dengan `AdeganJalan.posisi_kamera`, dibuktikan di scene), `posisi_layar(posisi_sepeda, kamera, ukuran)`, `sisa_ubin_keluar(pijak_layar, ukuran)`, `sudah_keluar(sisa)`, `hampir_keluar(sisa)`, `rentang_maju_terlihat(pijak_layar, ukuran) -> Vector2(belakang, depan)` ubin.
- Portal: `jarak_ke_garis(jarak, panjang)`, `portal_terbuka(jarak, panjang)`, `portal_bingkai(jarak, panjang)` (0 tertutup, 1 terbuka).
- `HasilRute.siap_tampil(selesai: bool, sudah_keluar: bool, koran)`.
- `config.gd` (blok baru sesudah `RUTE_AKHIR_STICK_Y`, satu baris literal): `RUTE_KELUAR_STICK_Y` 1,0; `RUTE_KELUAR_LAJU_MIN_UD` 3,0; `RUTE_KELUAR_BADAN_KIRI_PX` 18; `RUTE_KELUAR_BADAN_BAWAH_PX` 8; `RUTE_KELUAR_HAMPIR_UBIN` 6,0; `RUTE_PORTAL_BUKA_JARAK_UBIN` 6,0. `RUTE_AKHIR_STICK_Y` dipertahankan (dipakai `stick_akhir` yang masih dipakai simulasi `tes_rintangan`).

**Keputusan dan alasan**
1. Stick lurus = `(0, +1)` (bukan netral `(0, 0)`). Konvensi `BikeMotion`: x positif = sisi dekat, y positif = maju; tujuan dari `y` linear: netral 3,0, +1 = 6,0, -1 = 1,5; `x` menggeser lateral, jadi x = 0 berarti lateral tidak berubah (dibuktikan tes: `lateral_ubin` identik 600 langkah, `lateral_ud` 0, `arah_sprite` 0). Stick netral akan memperlambat pembalap ngebut ke 3,0 (pose melambat); `+1` membuatnya keluar dengan semangat, dan menjamin tujuan >= 3,0 untuk semua efek kondisi yang mungkin (lelah menjepit ke 4,5 x ban 0,92 = 4,14; batas puncak rantai tidak pernah di bawah santai 3,0).
2. Laju minimum diterapkan SEBELUM langkah lewat fungsi murni (`keadaan_dijaga`, mis. `_sepeda.kecepatan_ud = AkhirRute.laju_dijaga(_sepeda.kecepatan_ud)` atau `langkah_keluar`), TANPA hook di `BikeMotion`. Karena tujuan stick lurus tidak pernah di bawah 3,0, laju yang dimulai >= 3,0 tidak turun di bawahnya (dibuktikan: 96 kasus x 600 langkah, laju awal 0/1,5/2,9/3/4,5/6, dengan dan tanpa efek terburuk, lelah, lateral -2..1,9, rem aktif dari awal). Satu-satunya pengecualian: jatuh sesudah tabrakan (`beku_detik`), diam menurut aturan jatuh yang ada, lalu langkah berikutnya dijaga lagi (diuji). Laju awal 0 (mis. sempat berhenti persis di garis) melompat ke 3,0 pada langkah pertama sesudah garis; itu satu-satunya lonjakan, dicatat untuk uji HP.
3. Kotak badan dari piksel sprite nyata (bukan tebakan): gabungan piksel buram animasi arah lurus kayuh (santai/cepat/ngebut), melambat, meluncur, rem, berhenti relatif titik pijak (23, 46): kiri 18, kanan 16, atas 43, bawah 8. Hanya kiri dan bawah yang dipakai (maju = naik ke kanan atas, jadi sisi kiri badan terakhir meninggalkan tepi kanan dan sisi bawah terakhir meninggalkan tepi atas); `tes_garis_finish` mengukur ulang dari PNG/JSON nyata dan membandingkan dengan config. Animasi lempar dan jatuh tidak dihitung (lempar dimatikan sesudah garis; jatuh: sprite jatuh lebih lebar, kiri 27 kanan 55 atas 50 bawah 11; kalau rintangan masih bisa menjatuhkan sepeda sesudah garis, bagian C yang memutuskan).
4. Definisi "hampir keluar" (banner G-3): sisa jalan sepeda sampai SELURUH badan di luar viewport <= 6,0 ubin (jarak sepanjang jalan, dari geometri). Bukan "badan mulai melewati tepi": itu hanya sekitar 1,1 ubin (18 + 16 px / 32) sebelum hilang = 0,2 detik di ngebut, terlalu singkat untuk terbaca. 6 ubin = 1,0 detik (laju 6,0) sampai 2,0 detik (laju 3,0) banner terlihat sebelum layar hasil menggantikannya. Angka disetel di HP.
5. Portal membuka 6,0 ubin sebelum garis (1,0 detik di ngebut, 2,0 detik di santai); tetap terbuka sesudahnya (fungsi dari jarak; jarak sepeda tidak pernah turun).
6. Keluar viewport lewat geometri: titik pijak layar = (lebar x 0,3333, 270) + geseran dorongan kecepatan; sesudah garis kamera beku, jadi pijak bergeser (+32, -16) px per ubin. Arah dari `Iso.dunia_ke_layar(Iso.ARAH_MAJU)` (naik ke kanan atas): sepeda KELUAR LEWAT TEPI KANAN di semua viewport (kanan lebih cepat dari atas hanya 0,15 sampai 3,5 ubin; di 800 lebar hampir sudut kanan atas). Tepi atas hanya menang bila pijak sangat tinggi di layar (diuji dengan pijak sintetis).
7. Kamera beku = fungsi murni `posisi_kamera(posisi_sepeda_di_garis, ukuran, geser_dorongan)`; bagian C menghitungnya SEKALI pada langkah `baru_selesai` (posisi sepeda dan `geser_dorongan()` saat itu) dan memakai nilainya terus; `geser_dorongan` juga dibekukan di nilai itu.

**Jarak tambahan keluar dari garis akhir (ubin sepanjang jalan; dari `sisa_ubin_keluar`, bukan waktu tetap), per viewport**
Kolom = geseran dorongan saat garis tercapai (melambat = laju <= 1,5 geser (-20, +10); santai = (0, 0); ngebut = laju 6,0 geser (+36, -18)). Jarak = tambahan maksimum yang perlu tergambar di belakang portal.

| Lebar viewport | melambat (terjauh) | santai | ngebut (terdekat) | Waktu keluar dari santai (3,0 konstan = laju minimum terburuk) | Waktu dari ngebut 6,0 (terpendek) | Waktu santai lalu mempercepat ke 6,0 |
|---|---|---|---|---|---|---|
| 640 | 14,52 | 13,90 | 12,77 | 4,63 s | 2,13 s | 2,57 s |
| 693 | 15,63 | 15,00 | 13,88 | 5,00 s | 2,31 s | 2,75 s |
| 780 | 17,44 | 16,81 | 15,69 | 5,60 s | 2,61 s | 3,05 s |
| 800 | 17,86 | 17,23 | 16,11 | 5,74 s | 2,68 s | 3,12 s |

(Waktu terpanjang mungkin = 5,95 s pada 800 lebar, laju 3,0 konstan dengan efek kondisi terburuk dan geseran melambat; waktu normal dengan stick `+1` sekitar 2,6 sampai 3,1 s.) Keempat viewport keluar lewat tepi kanan.

**Kebutuhan tanah dan dunia di belakang portal (G-5), dari `rentang_maju_terlihat`**: dengan kamera beku di garis akhir, yang terlihat sepanjang jalan relatif pijak sepeda saat beku adalah paling jauh 13,98 sampai 17,40 ubin di DEPAN (640 ngebut 13,98; 800 melambat 17,40) dan 5,52 sampai 8,10 ubin di BELAKANG. Tidak ada rumah di depan garis akhir (rumah terakhir sebelum `panjang_ubin`; radar dan progres di garis dan 17,9 ubin sesudahnya sama persis, diuji dengan rute nyata). Kesimpulan untuk bagian C: G-5 BISA dipenuhi tanpa mengubah segmen rute atau menambah RNG/angka ekonomi. Yang perlu: jendela daur dan blok tanah JANGAN ikut sepeda ke depan, melainkan dibekukan di jarak sepeda saat garis tercapai (kamera beku melihat persis yang sama dengan frame sebelum beku); bila `_tanah.perbarui`, `_daur.perbarui`, `_dekor_daur.perbarui`, dan `_rintangan_daur.perbarui` tetap diberi jarak sepeda yang terus naik, blok tanah (diukur relatif sepeda) dan rumah di belakang (jendela mundur 20 ubin) bergeser dan menimbulkan lubang karena kamera sudah tertinggal 14 sampai 18 ubin di belakang sepeda. Portal digambar di `panjang_ubin` pada lateral pilihan C (palang 1,625 ubin; lihat pengukuran bagian A).

**Gerbang bagian B**
- `godot --headless --import` exit 0; `--quit-after 2` exit 0, 0 baris ERROR/WARNING.
- `run_tests.gd` + `cek_keluaran_tes.py`: **28729 lolos, 0 gagal, 0 peringatan** (bagian A 28518; +211 neto: `tes_garis_finish` +212 asersi termasuk bagian scene, `tes_hasil` 6 -> 5 asersi = -1).
- 17 `uji_*.py` exit 0 (angka sama dengan bagian A: aset_fase3 148, gelombang1 352, kucing 13, lampu_pohon 183, pasang_5b 599, pasang_gelombang1 587, simpang 214, bangun_frames 62, pemeriksa 16 kasus, sintesis_kondisi 55, lempar 111, milestone 18, misi 47, rute 90, sepeda 32, ui_lencana 25, ui_redesain LOLOS).
- `--export-pack "Android" build/kring-uji.pck` exit 0 (2.023.792 byte), memuat `prop_portal_satpam`.
- sha256 save asli: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e` (tidak berubah).

**Tes baru**: `tests/tes_garis_finish.gd` (`TesGarisFinish`, didaftarkan di `run_tests.gd` sesudah `TesRuteScene`): kontrak lama + baru_selesai tepat sekali; laju dijaga (0, 1,5, 2,9, 3,0, 3,001, 4,5, 6,0, NaN, negatif); `BikeMotion` nyata 96 kasus x 600 langkah (tanpa belok, tanpa rem, laju >= 3,0, lateral tetap) + jarak literal (4,5 / 4,5 / 6,0 / 3,0 ubin per detik) + `beku_detik`; kotak badan = piksel PNG nyata (7 animasi); geometri 4 viewport x 3 geseran dengan oracle skrip Python terpisah (pijak, sisa, rentang terlihat, tepi keluar = kanan) + kasus sintetis tepi atas, inklusif, tak hingga/NaN, tinggi nol; `periksa_keluar` tabel 17 baris + fuzz berseed 300 rangkaian x 80 langkah (fase tidak turun, sinyal paling banyak sekali); simulasi `BikeMotion` nyata 4 viewport x 5 laju x 2 efek (hampir sekali lalu keluar sekali, jarak saat keluar = sisa geometri dalam 1 langkah, sisa saat hampir 5,9..6,0) + waktu literal (langkah 153 dan 277); portal (ambang tepat inklusif, tak hingga/NaN, panjang tak sah, fuzz 200 rute: tidak pernah menutup lagi); kamera beku (literal); `siap_tampil` 16 kombinasi + sambungan ke fase; G-5 murni (pemindai kode: tidak ada rujukan SkorRute/TenggatRute/ProgresRute/RadarRute/KondisiRute/BikeCondition/MissionManager/SaveManager/DataSave/HasilRute/RouteBuilder; dinamis: 600 langkah gerak keluar tidak mengubah kondisi sepeda (dengan kontrol tanpa bendera selesai yang memang mengikis), jam tenggat, progres, radar dengan rute nyata); scene `jalan_uji` di 3 lebar x 3 laju: `AkhirRute.posisi_kamera` = kamera nyata persis dan `posisi_layar_pijak` = `posisi_layar_sepeda` dalam 0,5 piksel.

**Mutan (AC-10) bagian B**: commit dulu, lalu 55 mutan satu perubahan (skrip bantu di scratchpad, bukan di repo; subset cepat `tes_garis_finish` + `tes_hasil` + `tes_gerak` + `tes_rute`, yang lolos subset diulang dengan `run_tests.gd` penuh + pemeriksa): config (stick Y x3, laju min x2, badan kiri/bawah, hampir x2, portal x2), `laju_dijaga` x2, `keadaan_dijaga` x2, `langkah_keluar` x5, `posisi_layar_pijak` x2, `posisi_kamera` x2, `posisi_layar`, `sisa_ubin_keluar` x9, `sudah_keluar`, `hampir_keluar`, `periksa_keluar` x9, `rentang_maju_terlihat` x2, portal/`jarak_ke_garis`/`portal_bingkai` x6, `siap_tampil` x3, `stick_keluar` x, `tercapai`. Hasil putaran pertama: **50 tertangkap, 5 lolos di subset**:
  - `langkah_keluar` mengabaikan `beku_detik`: LOLOS asli -> ditutup tes baru ("beku_detik diteruskan: selama jatuh sepeda diam" dan "sisa langkah sesudah bangun") lalu ulang: tertangkap.
  - `sisa_ubin_keluar` dengan `ukuran.y <= 0` diubah `< 0`: LOLOS asli (tes hanya memakai -1) -> ditutup tes tinggi viewport 0, ulang: tertangkap.
  - `periksa_keluar` tanpa klausa `or k.fase == SUDAH_KELUAR` pada syarat hampir: LOLOS dan dibuktikan setara (sisa 0 selalu <= ambang hampir) -> klausa redundan dihapus dari kode; mutan pengganti (banner hanya saat sudah keluar) tertangkap.
  - `portal_terbuka` tanpa penjaga `not is_nan(sisa)`: LOLOS dan dibuktikan setara (perbandingan dengan NaN selalu false) -> penjaga dihapus dan didokumentasikan; mutan pengganti (NaN dianggap terbuka) tertangkap.
  - `AkhirRute.tercapai` `>=` -> `>` (kontrak lama): LOLOS di subset karena asersinya ada di `tes_rute_scene` (tidak di subset); run_tests penuh: tertangkap ("garis akhir tercapai di jarak >= panjang (inklusif)").
  Putaran kedua (empat mutan yang diperbaiki dan dua pengganti): semua tertangkap. Total akhir **55 mutan, 55 tertangkap, 0 lolos** (2 setara dihapus dari kode). Ambang Dev >= 40 terpenuhi.

Catatan untuk C dan D: (a) `RuteMain` harus memakai `stick_keluar`/`langkah_keluar` bukan `stick_akhir`, mematikan `_lempar_diizinkan` dan mode bantu, dan menyimpan `fase`, `hampir` dari `periksa_keluar`; (b) `HASIL_BERHENTI_TOLERANSI_UD` dihapus di C; `BALANCING.md` baris 290 (Akhir rute) dan 368 (Layar hasil) menyebut rem dan toleransi kecepatan lama dan perlu ditulis ulang di D; (c) angka baru perlu masuk `BALANCING.md` (6 konstanta).

