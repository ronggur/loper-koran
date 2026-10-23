# Loop Log — 20261023-ui1-komponen-bengkel
Scope: Run UI-1 — redesain UI langkah 1-2 (komponen + bengkel tata C)  ·  Branch: feat/ui1-komponen-bengkel  ·  Mulai: 2026-10-23  ·  Godot: 4.7.2.stable.official.ed1daf0bf

## Status: PASSED   (iterasi 2/2; QA iterasi 2 = PASS: QA-001, QA-002, QA-004, QA-005, QA-006 VERIFIED; tidak ada Blocker/Major terbuka; 1 Minor DEFERRED lama + 1 Minor baru DEFERRED; NEEDS-MANUAL: uji HP SETUP_ANDROID 8.18 dan keputusan pemilik QA-003 dan D-2; Fase UI belum boleh dicentang sebelum uji HP)

## Lingkungan (orchestrator, awal run)
- `main` = `origin/main` = `b99f5a9` (rilis 0.6.0; memuat PR #61, #62, #63). Branch dibuat dari sana.
- Godot 4.7.2 di `/opt/homebrew/bin/godot`; python3 dengan numpy 2.5.3 dan pillow 12.3.0; `cv2`/`sklearn` TIDAK terpasang (hanya dibutuhkan `latar_bengkel.py` membuat ulang latar; `--salin` hanya menyalin berkas jadi tidak perlu).
- `adb devices`: tidak ada perangkat tersambung (vivo/A54 belum dicolok). Pemasangan APK menunggu perangkat tersambung dan QA PASS.
- sha256 save asli `Kring Kring!/save.json` awal run: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e`.
- `.claude/` untracked di working tree: bukan bagian run, tidak di-commit.

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 1 | Dev: bagian A komponen (30 aset, `GayaHud`, `KomponenUi`, kotak kondisi besar), bagian B bengkel tata C (`TampilBengkel`, `PanggungSepeda`, `LayarBengkel`, probe, mutan 50/50), bagian C dokumen | import tanpa error, `--quit-after 2` tanpa ERROR/WARNING, `run_tests.gd` 23003 lolos 0 gagal + pemeriksa lolos, 17 `uji_*.py` exit 0, sha256 save asli tidak berubah | (menunggu QA) | **FAIL** (QA iterasi 1: gerbang objektif hijau; 2 Major OPEN) | 9 baru: 2 Major, 1 Minor, 6 Nit | 0 |
| 2 | Dev: QA-001 (nama dan deskripsi kartu bengkel berelipsis), QA-002 (tes chip harga tampil), QA-005, QA-006, amandemen SPEC AC-2 (QA-004) | import tanpa error, `--quit-after 2` tanpa ERROR/WARNING, `run_tests.gd` 23406 lolos 0 gagal + pemeriksa lolos, 17 `uji_*.py` exit 0, sha256 save asli tidak berubah, probe 2340x1080 0 keadaan tidak sesuai (QA mengulang semuanya: sama) | **PASS** (QA iterasi 2: gerbang hijau, 0 Blocker/Major terbuka) | 4 baru: 1 Minor, 3 Nit (QA-010..013; tidak ada Major) | 5 VERIFIED (QA-001, 002, 004, 005, 006); 4 tetap DEFERRED (QA-003, 007, 008, 009), pantas |

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|
| QA-001 | 1 | Major | scripts/ui/layar_bengkel.gd:377 (`kartu.nama = _label(&"LayarTeksUtama", ...)` di `_bangun_kartu_upgrade`; juga :304 kartu servis) | Label nama kartu upgrade TIDAK punya autowrap atau ellipsis (hanya `deskripsi` yang dibungkus). SPEC AC-6: "Teks panjang pakai autowrap/ellipsis". `DataToko` mengizinkan nama sampai `Config.TOKO_NAMA_PANJANG_MAKS` = 24 huruf. Lebar minimum kartu naik, `Batas`/`Isi` ikut melebar dan seluruh layar bergeser keluar viewport. Bukti (tes reproduksi QA, tidak terdaftar di runner): `godot --headless --path . --script res://tests/qa_repro_ui1_teks_panjang.gd` di lebar game 640 (1920x1080): nama "Rem Pakem Racing Edition" (24 huruf): `Isi` = (-4.5, 12) ukuran 649 x 336 (kiri dan kanan keluar layar 640); nama "Ban Anti-Selip Super" (20 huruf): `Isi` 618 lebar (melewati margin 12). Di lebar 800 nama 24 huruf "WWW..." menggeser `Isi` ke x=-14 (ukuran 828). Deskripsi 48 huruf biasa (kontrol) tidak merusak. Latent: data nyata saat ini <= 14 huruf ("Ban Anti-Selip"), tetapi pemuat data MENGIZINKAN nilai itu dan tidak ada tes terpanjang (Dev hanya menguji "Stamina awet dan rantai lebih tahan"). | VERIFIED (QA iter 2) | `scripts/ui/layar_bengkel.gd`: label nama kartu upgrade dan servis lewat `_label_potong` (satu baris, `OVERRUN_TRIM_ELLIPSIS`, `clip_text`, lebar minimum tidak mengikuti teks); deskripsi upgrade `max_lines_visible` = `Config.BENGKEL_DESKRIPSI_BARIS_MAKS` (2) berelipsis supaya kartu tetap 62; `scripts/config.gd`; commit b473ffd | `tests/tes_bengkel_tata_c.gd` `_test_teks_panjang`: 6 kasus teks (nama 24 huruf, 24 huruf "W" tanpa spasi, deskripsi 48 huruf biasa dan "W" tanpa spasi, gabungan) x saldo 125.480 dan dibatasi `Economy.saldo` (2.000.000.000, 10 digit) x lebar 640, 700, 800: `Isi` x 12 dan lebar tepat, kolom tetap, tanpa tumpang tindih/teks terpotong, tombol >= 42/84 ("Hari berikutnya" 140), kartu servis 50 dan upgrade 62, tanpa scroll, nama satu baris berelipsis, data nyata tidak berelipsis; nama komponen servis 28 huruf lebar. Tes reproduksi `tests/qa_repro_ui1_teks_panjang.gd` diserap lalu dihapus |
| QA-002 | 1 | Major | scripts/ui/layar_bengkel.gd:230 dan :259 (`_tampil_chip(kartu.chip_harga, ...)`) | Mutan QA M16 (chip harga disembunyikan bila `Aksi.KURANG`, hanya tampil bila AKTIF) LOLOS: 23004 lolos, 0 gagal. SPEC U-1: "Harga selalu chip di sebelah tombolnya" dan keadaan c (saldo kurang) memperlihatkan harga di sebelah tombol "Koin kurang" supaya pemain tahu berapa yang kurang. Tes memeriksa `kartu.harga.text` (teks label) tetapi tidak `chip_harga.visible` / `is_visible_in_tree()` pada kartu servis maupun upgrade berstatus KURANG (`tes_bengkel_tata_c._test_keadaan_c` dan `tes_bengkel_scene`). Perilaku sekarang benar (tangkapan c menunjukkan "84 koin" di sebelah "Koin kurang"); yang hilang adalah tes untuk logika kritis ini. | VERIFIED (QA iter 2) | hanya tes (perilaku sudah benar): commit b473ffd | `tests/tes_bengkel_tata_c.gd` `_test_chip_harga_terlihat` (lebar 640 dan 800): chip harga + labelnya `is_visible_in_tree()`, rect > 0, teks tidak kosong, di kiri tombol (jarak <= 8, sejajar tegak) untuk servis AKTIF, servis KURANG ("Koin kurang"), upgrade AKTIF, upgrade KURANG; tersembunyi untuk servis penuh dan upgrade Dimiliki (chip Baik/Dimiliki tampil). Mutan M16a/b/c dan M6 diulang, lihat "Dev iterasi 2" |
| QA-003 | 1 | Minor | assets/sprites/ui/ui_kartu_biasa.png, ui_kartu_redup.png, ui_btn_nonaktif.png (garis bingkai) | AC-9 menulis "garis komponen >= 3:1". Ukuran QA sendiri dari tangkapan 2340x1080 (tepi komponen vs 2 px di luarnya, pita kiri): kartu biasa/redup 1,14..1,29:1, tombol nonaktif 1,14:1 (kartu menonjol berbingkai WARN 6,91:1; tombol aktif 8,53..10,27:1; "Hari berikutnya" 10,27:1). Cocok dengan angka Dev (D-1). Putusan QA: BUKAN Major. Alasan: tombol AKTIF (satu-satunya yang menuntut pengenalan target) lolos jauh; tombol nonaktif dikecualikan dari 1.4.11 WCAG dan dibedakan tanpa warna (arsir, teks tipis, alasan "Koin kurang", teks >= 7,48:1 terhadap sisi terang arsir, diukur QA); kartu adalah wadah, bukan kontrol, dan isinya terbaca (teks >= 7,79:1). Tetap penyimpangan harfiah dari AC-9 dan dari kanvas yang diberi pemilik; keputusan pemilik setelah uji HP 8.18 (D-1). Disarankan SPEC AC-9 dipersempit ke "kontrol aktif". | DEFERRED (keputusan pemilik, D-1; QA iter 2 menilai ulang: tetap Minor, lihat "QA iterasi 2") | | |
| QA-004 | 1 | Nit | tools/ui_art/redesain/pasang.py:LATAR; SPEC AC-2 | SPEC AC-2 menyebut latar "640/800"; hanya 800 dipasang (P1). QA memverifikasi alasannya: `bengkel_latar_640.png` = potongan tengah (x 80..720) `bengkel_latar_800.png`, 0 piksel beda; `Config.LAYAR_LEBAR_MAKS_PX` = 800; `ui_bengkel_latar_800.png` di assets = salinan byte-identik docs. Di lebar 640 bengkel tampil benar (tangkapan 1920x1080 dilihat QA: lampu di tengah, tidak ada teks tertutup). Pembenaran SAH; yang tersisa hanya SPEC perlu diamendemen. | VERIFIED (QA iter 2; amandemen SPEC AC-2 diterima) | `SPEC.md` AC-2 diamendemen: hanya latar 800 dipasang, alasan dicatat (commit docs iter 2). Tidak ada perubahan kode atau aset | |
| QA-005 | 1 | Nit | scripts/systems/tampil_bengkel.gd:81 (`kunci_tombol`) | Mutan QA M6 (`status != Aksi.AKTIF` alih-alih `== Aksi.KURANG`) lolos: setara di praktik karena `_atur_tombol` hanya dipanggil bila aksi != TIDAK_ADA, tetapi kontrak fungsi murni untuk `Aksi.TIDAK_ADA` tidak diuji. | VERIFIED (QA iter 2) | hanya tes: commit aea0cd2 | `tests/tes_tampil_bengkel.gd`: `kunci_tombol(TIDAK_ADA, "BENGKEL_SERVIS"/"BENGKEL_BELI")` = kunci aksi; mutan M6 diulang, lihat "Dev iterasi 2" |
| QA-006 | 1 | Nit | scripts/systems/tampil_bengkel.gd:173 (`var cincin: int = 1`), scripts/ui/panggung_sepeda.gd:45 (`Vector2(-1, -1)`, `Vector2(2, 2)`), scripts/ui/gaya_hud.gd (`set_border_width_all(1)`, `_kotak_fokus`) | Angka ajaib kecil (garis 1 px) di luar `Config`; rule `gdscript` "tanpa angka ajaib". Murni gaya, tidak mengubah perilaku. | VERIFIED (QA iter 2; lokasi yang tercatat bersih, sisa serupa di QA-010) | `Config.UI_GARIS_PX` = 1 dipakai `tampil_bengkel.gd` (`cincin`), `panggung_sepeda.gd` (ring luar), `gaya_hud.gd` (`kotak` dan `_kotak_fokus`); nilai tetap 1, tampilan tidak berubah; commit 0fa1997 | tes lama (pemindai angka literal, titik penanda 5x5, ring panggung) |
| QA-007 | 1 | Nit | tools/tests_cek/uji_aset_pasang_5b.py:67 | Pola larangan `r'nyala'` diperlonggar jadi `r'^prop_lampu_.*nyala'` (dicatat Dev; alasan sah: `ui_btn_sakelar_nyala`). Efek samping: aset lain berkata "nyala" kini tidak ditandai. Lebih ketat bila hanya mengecualikan `ui_btn_sakelar_nyala` secara eksplisit. Juga `tes_bengkel_scene.gd` (satu `check` diubah dari teks "Baik" ke `not tingkat.visible`, dicatat Dev). | DEFERRED | | |
| QA-008 | 1 | Nit | scripts/ui/layar_bengkel.gd:`_saat_beli_komponen` | Latent (data sekarang hanya tingkat I): pada komponen bertingkat kartu berganti isi ke tingkat berikutnya sesudah beli, jadi ketukan kedua pada tempat yang sama (frame berbeda) membeli tingkat II tanpa konfirmasi. Bukan bug untuk data hari ini; patut dipertimbangkan sebelum tingkat 2-3 nyata dipakai (jeda 0,35 detik atau konfirmasi). | DEFERRED | | |
| QA-009 | 1 | Nit | scenes/bengkel/bengkel.tscn (`GambarLatar`) | Lebar game > 800 (mis. 21:9 = 853, QA uji 853/1000/1066 lewat skrip, tata letak benar, tanpa teks terpotong) membuat latar 800 tidak menutup tepi; sisi kiri dan kanan berwarna `UI_BG` polos. `LAYAR_LEBAR_MAKS_PX` memang 800 (20:9), jadi di luar jangkauan resmi. Visual saja. | DEFERRED | | |
| QA-010 | 2 | Nit | scripts/ui/panggung_sepeda.gd:141 (`_gaya_titik`: `hasil.set_border_width_all(1)`) | Sisa angka ajaib garis 1 px dengan pola yang sama dengan QA-006: Dev memperbaiki lokasi yang tercatat (`tampil_bengkel.gd`, `panggung_sepeda.gd:45`, `gaya_hud.gd` x2) tetapi `_gaya_titik` (garis luar titik penanda) masih memakai literal 1. Pemindai angka literal tidak menangkap `1`. Murni gaya, tidak mengubah perilaku. | OPEN (Nit, tidak menghalangi PASS) | ganti dengan `Config.UI_GARIS_PX` | |
| QA-011 | 2 | Nit | scripts/ui/layar_bengkel.gd:228 dan :250 (`_gaya_kartu(... PAD_AKHIR + (PAD_AKHIR if info.penuh / info.dimiliki else 0))`) | Mutan QA N5 (pad kanan kartu upgrade Dimiliki dihapus) dan N19 (pad kanan kartu servis penuh dihapus) LOLOS: 23406 lolos, 0 gagal (setiap kali 165 detik, pohon kerja dipulihkan). Bukan setara: chip "Dimiliki" dan "Baik" bergeser 4 px ke kanan. Tidak ada tes yang memeriksa margin kanan kartu bercip. Murni tata letak (kanvas padding 8 vs 4), bukan logika kritis. | OPEN (Nit, tidak menghalangi PASS) | tambah satu pemeriksaan `content_margin_right` kartu penuh/Dimiliki = 8 dan kartu bertombol = 4 | |
| QA-012 | 2 | Minor | scripts/ui/layar_bengkel.gd (`max_lines_visible` deskripsi = 2, nama berelipsis) + inset aman besar di lebar game 640 | Efek samping perbaikan QA-001 pada DATA NYATA: di lebar 640 (1920x1080) dengan inset aman >= 44 piksel game per sisi (setara 132 px fisik), lebar label nama turun ke 67 piksel: "Ban Anti-Selip" (72) dan "Rantai Hemat" (70) berelipsis, deskripsi "Stamina awet dan rantai lebih tahan" butuh 3 baris tetapi dijatah 2 (dipotong); pada inset 60 piksel deskripsi butuh 4 sampai 6 baris dan nama "Ban Anti-Selip" dan "Rem Pakem" berelipsis. Ukur QA (`qa2_inset.gd` di scratchpad, headless, 5 inset x 4 lebar 640/700/780/800): lebar >= 700 dan inset sampai 80: tanpa elipsis data nyata; lebar 640 dan inset <= 30: tanpa elipsis. Tata letak tidak pecah (Isi di dalam zona aman, tanpa tumpang tindih, tombol >= 42x84). Perangkat 16:9 (lebar 640) dengan inset >= 44 jarang. Sebelum perbaikan keadaan ini membuat layar melar keluar (lebih buruk), jadi bukan regresi; tetap penyimpangan harfiah AC-9 "tidak ada teks terpotong" untuk konfigurasi ekstrem. | DEFERRED (Minor; catatan untuk uji HP 8.18 di perangkat 16:9 berinset) | | |
| QA-013 | 2 | Nit | scripts/systems/data_toko.gd + `Config.TOKO_NAMA_PANJANG_MAKS` 24 dan `TOKO_DESKRIPSI_PANJANG_MAKS` 48 | Validator data lebih longgar daripada kapasitas layar: di lebar 640 dengan harga 3 digit nama dengan lebar teks > 103 piksel (kira-kira >= 20 huruf biasa; "Rem Pakem Racing Edition" 136 piksel tampil "Rem Pakem Racin...") dan deskripsi > 2 baris (kira-kira >= 44 huruf; "Stamina awet dan rantai lebih tahan lama" tampil "...tahan...") berelipsis tanpa cara membacanya penuh; harga 6 digit memperkecil nama lagi (82 piksel), harga 13 digit 28 piksel. Kasus ekstrem: harga 2.000.000.000 dengan tiga tingkat di lebar 640 melebarkan `Isi` 5 piksel (x 9,5, lebar 621; `Economy.saldo` dibatasi 2.000.000.000 jadi harga itu tidak terbeli); huruf non-Latin (CJK) tidak punya glif di font dan kasus deskripsi CJK ditandai terpotong oleh pemeriksa (di luar bahasa game). Data nyata hari ini (<= 14 huruf, <= 35 huruf) aman di 640..800 tanpa inset. Layar terbaca di semua kasus ekstrem ini (nama berelipsis tetap mengenali, tombol dan harga utuh). | DEFERRED (Nit; saran: turunkan batas panjang di DataToko ke yang muat di 640, atau bungkus nama dua baris, bila upgrade baru ditambah di 6B) | | |

## Dev iterasi 2 (Agent 1; hanya temuan OPEN; commit b473ffd, 0fa1997, aea0cd2, dan commit docs iterasi 2)
**QA-001 (Major) FIXED.** `LayarBengkel._label_potong`: label nama kartu upgrade dan servis satu baris, `OVERRUN_TRIM_ELLIPSIS` + `clip_text` (lebar minimum tidak lagi mengikuti teks, jadi nama 24 huruf tidak melebarkan kartu, kolom, `Isi`). Deskripsi upgrade tetap autowrap tetapi `max_lines_visible` = `Config.BENGKEL_DESKRIPSI_BARIS_MAKS` (2) berelipsis: deskripsi 48 huruf "W" tanpa spasi sempat membuat kartu 95 tinggi (di luar layar) saat tes diperluas, sekarang kartu tetap 62. Ukuran kartu 50/62 dan tiga upgrade tanpa scroll tidak berubah. Keputusan tata letak (usulan, bisa ditolak): nama yang melebihi kolom (hanya data di luar data nyata, mis. 24 huruf lebar di 640) DIPOTONG dengan elipsis, bukan dibungkus, supaya tinggi kartu tetap; data nyata ("Ban Anti-Selip" dst.) muat penuh di 640..800 (diuji: lebar teks <= lebar label; deskripsi nyata <= 2 baris). Tes: `TesBengkelTataC._test_teks_panjang` (+ `KASUS_TEKS` 6 kasus x saldo 125.480 dan 10 digit (dibatasi `Economy.saldo` 2.000.000.000; `2147483647` tertulis "2.000.000.000") x lebar 640, 700, 800, plus data nyata dan nama komponen servis 28 huruf). Pembantu `_teks_terpotong` mengenal `max_lines_visible` (hanya baris yang dijatah wajib tampil penuh; label tanpa batas tetap diperiksa seperti semula). `tests/qa_repro_ui1_teks_panjang.gd` diserap ke tes ini lalu DIHAPUS (juga `.uid`-nya yang tak terlacak).
**QA-002 (Major) FIXED.** `TesBengkelTataC._test_chip_harga_terlihat` (lebar 640 dan 800): chip harga + label `is_visible_in_tree()`, rect > 0, teks tidak kosong, jarak <= 8 di kiri tombol dan sejajar tegak, untuk servis AKTIF, servis KURANG ("Koin kurang"), upgrade AKTIF, upgrade KURANG; chip harga dan tombol tersembunyi untuk servis penuh (chip "Baik" tampil) dan upgrade Dimiliki (chip "Dimiliki" tampil).
**QA-005 (Nit) FIXED**: `tes_tampil_bengkel.gd` memeriksa `kunci_tombol(TIDAK_ADA, ...)` = kunci aksi. **QA-006 (Nit) FIXED**: `Config.UI_GARIS_PX` = 1 menggantikan literal 1 di `tampil_bengkel.gd` (`cincin`), `panggung_sepeda.gd` (ring luar), `gaya_hud.gd` (dua `set_border_width_all`); pemindai angka literal menolak `2.0` jadi ring ditulis `size + garis + garis`; nilai sama, tampilan sama. **QA-004 (Nit, DEFERRED diterima QA)**: SPEC AC-2 diamendemen (hanya latar 800; alasan: 640 = potongan tengah 800, lebar maksimum 800). **QA-003, QA-007, QA-008, QA-009: tidak disentuh** (DEFERRED; QA-003 keputusan pemilik, tanpa perubahan aset).

### Mutan iterasi 2 (satu perubahan, `run_tests.gd` penuh, `git checkout` sesudahnya; semuanya TERTANGKAP, pohon kerja bersih sesudahnya)
| Id | Perubahan | Hasil (lolos, gagal) | Pemeriksaan pertama yang gagal |
|---|---|---|---|
| M16a | (mutan M16 QA, yang tadinya LOLOS) chip harga kartu servis hanya tampil bila AKTIF | 23404, **2 gagal** | tes_bengkel_tata_c "servis KURANG: tombol 'Koin kurang' dan chip harga '84 koin' tampil" (lebar 640 dan 800) |
| M16b | sama untuk kartu upgrade | 23398, 8 gagal | "upgrade ban_anti_selip KURANG: chip harga '600 koin' di sebelah tombol 'Koin kurang'" |
| M16c | chip harga upgrade tetap tampil saat Dimiliki | 23402, 4 gagal | "kartu menjadi label 'Dimiliki' tanpa tombol dan tanpa harga" (tes lama) |
| M6 | (mutan QA-005) `kunci_tombol`: `status != Aksi.AKTIF` | 23405, **1 gagal** | tes_tampil_bengkel "teks tombol tanpa aksi (TIDAK_ADA)" |
| M51 | nama tanpa elipsis dan tanpa klip (kembali ke QA-001) | 23265, 141 gagal | "nama 24 huruf: Isi (-4.5, 12) 649 x 336 tidak melebar" |
| M52 | deskripsi tanpa batas baris | 23333, 73 gagal | "tanpa teks terpotong" / tinggi kartu |

### Gerbang iterasi 2
- `godot --headless --import` tanpa ERROR/WARNING; `--quit-after 2` tanpa ERROR/WARNING.
- `run_tests.gd` + `tools/cek_keluaran_tes.py`: **23406 lolos, 0 gagal, 0 peringatan** (iterasi 1: 23003; +403 pemeriksaan: `_test_teks_panjang`, `_test_chip_harga_terlihat`, satu pemeriksaan QA-005). Satu percobaan awal gagal oleh pemindai "tanpa angka literal" (`2.0` di `panggung_sepeda.gd`), diperbaiki sebelum commit.
- 17 `tools/tests_cek/uji_*.py` exit 0. sha256 save asli `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e` tidak berubah.
- Probe `probe_bengkel_jendela.gd` 2340x1080 (11 keadaan, data nyata): **0 keadaan tidak sesuai**; tangkapan di `shots/iter2/`, dibandingkan piksel dengan `shots/qa_iter1/`: 7 dari 11 identik; 4 (b, e, g, sesudah_servis) beda di 277 piksel layar (31 piksel game, kotak 41x332 di dalam teks "Servis" tombol, huruf "v") yang saya lihat berupa antialias huruf: persegi tombol, kartu, chip, dan nama IDENTIK (diukur lewat skrip di jendela 780 lebar, lama = baru), JSON probe identik, dua run iterasi 2 saling identik (deterministik). Bisect: hilang bila label nama TIDAK diberi elipsis (kembali identik dengan iterasi 1); `clip_text` dan deskripsi bukan penyebab. Penyebab mekanisme tidak diketahui (kemungkinan jalur render teks Godot untuk label berelipsis memengaruhi posisi subpiksel teks di tombol); dampak visual tidak terlihat dalam perbesaran 10x. Dilaporkan terbuka, bukan disembunyikan; QA silakan menilai.

## Baseline (AC-1; diisi Dev bagian A langkah 1)
Diambil di pohon kerja yang belum berubah selain `docs/loop/` (HEAD `0b34f64`, setara `main` `b99f5a9`), 2026-10-23, satu proses Godot sekaligus.
- `godot --headless --import`: selesai tanpa error; `git status` bersih (selain `.claude/` yang tidak di-commit).
- `run_tests.gd`: **20371 lolos, 0 gagal**; `tools/cek_keluaran_tes.py build/tests.log`: lolos (20371 lolos, 0 gagal, 0 peringatan), exit 0.
- `godot --headless --path . --quit-after 2`: tanpa ERROR/WARNING.
- Semua `tools/tests_cek/uji_*.py` exit 0 (17 skrip): aset_fase3 148, aset_gelombang1 352, aset_kucing 13, aset_lampu_pohon 183, aset_pasang_5b 595, aset_pasang_gelombang1 565, aset_simpang 214, bangun_frames 62, pemeriksa 16 kasus 0 menyimpang, sintesis_kondisi 55, sintesis_lempar 111, sintesis_milestone 18, sintesis_misi 47, sintesis_rute 90, sintesis_sepeda 32, ui_lencana 25, ui_redesain LOLOS.
- sha256 save asli (`~/Library/Application Support/Godot/app_userdata/Kring Kring!/save.json`): `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e` (sama dengan awal run; diperiksa lagi sesudah probe jendela).
- Tangkapan "sebelum" untuk bukti piksel-identik (AC-4): `probe_hud_rute_jendela.gd` di 1920x1080 (10 PNG: HUD awal, radar, jeda dengan sakelar, layar hasil, kidal, dst.) disimpan di scratchpad `sebelum/`; dibandingkan dengan keluaran sesudah perubahan.

## Bagian A — komponen (Dev, iterasi 1; commit 4204b25, dc2e4c5, f3655ef)
**Set aset terpasang** (daftar tunggal `tools/ui_art/redesain/pasang.py`; diputuskan dari papan `Bengkel.dc.html`, `Bengkel_Tingkat.dc.html`, `Spesifikasi.dc.html`) di `assets/sprites/ui/`, 30 berkas + `.import`:
- Tombol: 8 bingkai `ui_btn_{utama,utama_tekan,biasa,biasa_tekan,sakelar_nyala,tenang,tenang_tekan,nonaktif}` + `ui_arsir_nonaktif` (sakelar mati memakai `btn_biasa`; kanvas tidak punya `btn_sakelar_tekan`, `btn_biasa_tekan` dipakai).
- Panel dan kartu: `ui_panel_layar`, `ui_kartu_{biasa,menonjol,redup}`; chip: `ui_chip_{gelap,ok,warn,netral,aksen}` (kelimanya dipakai kanvas bengkel). `panel_hud` TIDAK dipasang ulang (sudah ada `ui_panel_hud_9slice.png`).
- `ui_bengkel_papan_alat`, `ui_bengkel_sepeda_kecil.png` + `ui_bengkel_sepeda.json` (salinan byte `sepeda.json`), `ui_bengkel_latar_800.png`.
- Ikon 24 (potongan sel dari sheet `ikon24`, piksel sama): `ui_icon24_{ban,rem,rantai}` (hanya tiga yang dipakai kartu servis dan upgrade). Glif 12 (potongan sel `glif12` per warna): `ui_glif_{seru_warn,centang_ok,centang_teks2,kunci_terang,panah_gelap}` (kombinasi nyata di kanvas).
- TIDAK dipasang (tidak dipakai bengkel): `sepeda_besar` (kanvas hanya `sepeda_kecil`), `bengkel_latar_640` (lihat keputusan 2), koran_*, struk*, foto_*, lencana32, ikon dan glif lain, `kertas_tile`, `panel_hud`, `lembar_*`.

**Keputusan kecil Dev (usulan; bisa ditolak di review)**
1. Ikon 24 dan glif 12 dipasang sebagai PNG per sel (bukan sheet utuh) supaya "tidak ada aset redesain yang tidak dipakai di `assets/`" terpenuhi; piksel sama dengan sheet, dijaga `uji_ui_redesain.py`. Run layar lain menambah sel ke `pasang.py`.
2. Latar: hanya `ui_bengkel_latar_800.png`. Kanvas selalu memakai latar 800 dengan `bgx = (lebar - 800) / 2` (di 640 terpotong 80 px tiap sisi); versi 640 = potongan tengah versi 800 (diuji), jadi tidak dipakai. SPEC AC-2 menyebut "640/800"; menambah 640 cukup satu baris di `pasang.py` bila bagian B memerlukannya.
3. Variabel lingkungan tujuan `--salin` bernama `UI_ART_SALIN_KE` (folder tujuan langsung, bukan akar repo) dan sama untuk ketiga skrip.
4. `latar_bengkel.py` memuat `cv2`/`sklearn` hanya di `main()` saat membuat ulang; `--salin` hanya menyalin berkas resmi docs/ (jalan tanpa kedua pustaka).
5. Nonaktif diarsir: `ui_btn_nonaktif.png` sel tengah 4x4 (tepat sebesar ubin) diganti `ui_arsir_nonaktif.png` saat dimuat pertama kali (`GayaHud._tekstur_nonaktif_arsir`, dibangun sekali, mode ubin). CSS kanvas menaruh arsir di balik `border-image ... fill` yang opak sehingga arsir di kanvas hampir tidak tampak; di sini arsir terlihat di tengah bingkai (tepi 4/6 px tetap rata). Tidak ada PNG yang diedit tangan.
6. Fokus tombol: garis ACCENT 1 px lurus berjarak 1 px (kanvas putus-putus; Godot tidak punya garis putus-putus).
7. `GayaHud.tombol_*` juga mengatur `disabled` (false untuk empat peran, true untuk `tombol_nonaktif`) dan `theme_type_variation` (`TombolPeran` SemiBold 10 untuk utama/biasa/sakelar, `TombolTipis` Regular 10 untuk tenang/nonaktif); memanggil fungsi peran lain pada tombol yang sama memulihkan. Teks alasan ("Koin kurang") dipilih pemanggil lewat `KomponenUi.teks_tombol`.
8. Type variation baru di `theme.tres` (U-3): `LayarTeksUtama` 10, `LayarTeksKecil` 9 Regular, `LayarLabel` 8 (KAPITAL dan spasi 0,1 em dibuat pemanggil: tema tidak punya `text-transform`/`letter-spacing`), `LayarJudul` Lilita One 24, `ChipTeks` 10, `ChipTeksKecil` 8, `ChipTeksBesar` 12, `TombolPeran`, `TombolTipis`. Tanpa token Palette baru (semua warna komponen sudah ada: `UI_BG`, `TEXT`, `TEXT_2`, `ACCENT`, `WARN`, `OUTLINE`; `#FFE08A` hanya muncul di bilah progres dan aset, belum dipakai kode).
9. Kotak kondisi besar: kelas BARU `KotakKondisiBesar` (+ `TampilKondisiBesar` murni); `KotakKondisi` 14 px untuk HUD tidak disentuh. Tanda "!" memakai pola 3x9 `PolaPiksel.TANDA_SERU_KONDISI` (bukan glif 12) dan selalu disediakan ruangnya (33x9 total). Berongga = lubang `UI_BG` bergaris `TEXT_2` (versi HUD memakai `UI_PANEL_RAISED`).
10. Chip tingkat upgrade (I, II, III) dan format teks penanda sepeda ("! Ban", "Ban aus") bagian B; di sini hanya status -> gaya + glif + kunci teks (`KomponenUi.chip`).

**Tes baru:** `tests/tes_komponen_ui.gd` (+550 pemeriksaan, terdaftar di `run_tests.gd`): Config = meta.json, ukuran 18 tekstur terpasang, 4 peran x 3 keadaan tombol (tekstur, margin, warna, bobot, teks alasan), kartu (sapuan kondisi 0..1 per 0,01 + batas + NaN), chip (7 status, tanpa tabrakan gaya/glif/teks, kunci ada di `ui.csv`), wujud `GayaHud` (StyleBoxTexture, tepi 4/6/4/6, margin isi, sakelar, ganti peran), arsir, fungsi lama tak berubah, kotak kondisi besar (geometri, sapuan warna dan luminans, node), tema. `tools/tests_cek/uji_ui_redesain.py` bagian 7 (+16 pemeriksaan); langkah sudah terdaftar di job `alat` `tes.yml` (nama langkah diperbarui; tidak ada yang butuh Godot).

**Gerbang bagian A (Dev):** `godot --headless --import` tanpa error; `--quit-after 2` tanpa ERROR/WARNING; `run_tests.gd` **20921 lolos, 0 gagal** + `cek_keluaran_tes.py` lolos (baseline 20371); semua `uji_*.py` exit 0 (termasuk `uji_ui_redesain.py` LOLOS); sha256 save asli tetap `37d6d6cb...549e`.
**Bukti layar lama tidak berubah:** `probe_hud_rute_jendela.gd` 1920x1080, tangkapan sebelum (pohon `0b34f64`, worktree terpisah, dua kali) lawan sesudah (pohon ini, dua kali): layar hasil (2), jeda sakelar, kidal, progres campuran, tenggat hampir, tenggat lewat piksel-identik di semua pasangan. Tiga tangkapan lain bervariasi menurut fase animasi dari jam dinding, bukan UI: `hud_awal` (sesudah run 1 beda seluruh layar, sesudah run 2 identik dengan sebelum), `hud_bantu_abu` (beda 24x12 px bahkan antara dua run SEBELUM) dan `hud_radar` (beda hanya di kotak 10x23 game px = fase kayuh sprite pemain; HUD identik). Kesimpulan: tampilan HUD, hasil, jeda tidak berubah.
**Pemeriksaan visual komponen:** skrip sementara di scratchpad (bukan di repo) merender tombol enam peran, tiga kartu, enam chip, kotak kondisi besar (baik/aus/perlu/nol), glif, ikon, panel layar di 1920x1080: semuanya tampil seperti kanvas (nonaktif diarsir, kartu menonjol bergaris WARN, kotak berongga dan "!" terbaca).

## Perubahan tes lama (AC-8; setiap tes lama yang diubah dan alasannya)
Bagian A: tidak ada tes lama yang diubah (hanya `tests/run_tests.gd` menambah satu panggilan `TesKomponenUi`).
Bagian B:
- `tests/tes_bengkel_scene.gd` `_test_kondisi_baru` (satu `check`): `kartu.tingkat.text == "Baik"` untuk komponen penuh diganti `not kartu.tingkat.visible`. Alasan: di tata C komponen penuh tidak punya teks status kecil (kanvas keadaan a: kartu redup hanya bertanda chip "Baik"); chip itu dites `label_baik.visible and text == "Baik"` (baris yang sama, tidak diubah). Hanya tiga pemeriksaan (ban, rem, rantai) yang berubah; sisa 59 `check` di berkas itu (servis, upgrade, ketukan ganda, saldo tepat, galat data, empat lebar x inset, tiga alur hari, back, background, kidal) lolos tanpa perubahan lewat API yang dipertahankan (`tombol_servis`, `tombol_beli`, `tombol_hari_berikutnya`, `semua_tombol`, `kartu_servis(id).{tombol,label_baik,harga,tingkat,kotak,nama}`, `kartu_upgrade(id).{harga,nama,deskripsi,tombol,label_dimiliki,panel}`, `teks_*`, `rect_*`, `galat_tampil`, `ongkos_tampil`, `jumlah_upgrade_tampil`).
- `tests/run_tests.gd`: tiga panggilan baru (`TesTampilBengkel`, `TesBengkelTataC`); tidak ada perubahan lain.
- `tests/probe_bengkel_jendela.gd`: ditulis ulang (AC-10).
- `tests/tes_export.gd`: fungsi baru `_test_aset_ui1_ikut_paket` (AC-12), fungsi lama tidak diubah.
- `tests/tes_kondisi_scene.gd` dan `tests/tes_tata_letak.gd`: TIDAK diubah (pemindai sumber di `tes_kondisi_scene` bahwa bengkel tanpa mode bantu dan tanpa iklan tetap lolos untuk `layar_bengkel.gd` dan `bengkel.tscn` baru; `tes_tata_letak` hanya menyebut bengkel di komentar).
- `tools/tests_cek/uji_aset_pasang_5b.py` (baris 67): pola aset 5B yang tak dipasang `r'nyala'` dipersempit jadi `r'^prop_lampu_.*nyala'`. Alasan: pola lama (bingkai lampu nyala) salah menandai `ui_btn_sakelar_nyala.png` yang dipasang bagian A (uji itu GAGAL di HEAD bagian A, `aebfde0`; tertangkap di gerbang bagian B). Kontrol "bingkai nyala terdeteksi" tetap memakai nama lampu.

## Butir terbuka pemilik
- **Lisensi latar bengkel** (`docs/design/redesain/latar_bengkel/sumber_ai.jpg`): generator dan ketentuan lisensi komersial belum dicatat. Latar dipasang untuk uji HP (U-4) tapi TIDAK boleh masuk rilis sebelum dicatat (ART_DIRECTION 9).
- **Garis bingkai kartu dan tombol nonaktif < 3:1** (D-1): diterima apa adanya atau garis disorot (mengubah aset komponen dan `uji_ui_redesain.py`); putuskan sesudah uji HP 8.18.
- **Margin dengan inset aman** `max(12, inset)` (D-2) atau `12 + inset` seperti papan kanvas g.
- Butir redesain yang tetap terbuka dan di luar run ini: lapisan jeda 72%, kunci teks koran "Iklan baris" dan hasil "Pelanggan:".

## Bagian C — dokumen dan penutup (Dev, iterasi 1)
Semua dokumen memakai label **usulan**; tidak ada yang ditandai dikunci atau terpasang final. Kode, aset, dan tes tidak disentuh (hanya dokumen, README alat, dan satu baris perintah di rule). Isi diambil dari berkas nyata (nama kelas, skrip, perintah, daftar aset di `pasang.py`); `--salin` ketiga skrip dijalankan dengan `UI_ART_SALIN_KE` ke folder sementara untuk memastikan sintaks dan jumlah (27 + 2 + 1 = 30 berkas, `assets/` tidak ditimpa).

| Dokumen | Perubahan |
|---|---|
| `docs/design/DESIGN_SPEC.md` | Baris Bengkel di bagian 4: "Sketsa run UI-1" (tata C, kolom, kartu servis dan upgrade, chip, tombol, latar, jejak tingkat, penyimpangan dari kanvas dengan angka kontras); 1.3: komponen layar penuh (tombol empat peran, kartu, chip, type variation, kelas); 3.3: catatan `KotakKondisiBesar` tanpa mengubah versi 14 px; paragraf "Redesain usulan" tidak lagi bertulis "belum dipasang". Keputusan lama tidak diubah |
| `docs/ART_DIRECTION.md` | 6.8: paragraf redesain diperbarui dan blok "Dipasang run UI-1" (30 berkas, yang tidak dipasang, kotak kondisi dari kode, kontras terukur); Changelog entri baru 2026-10-23 dan entri redesain lama diberi keterangan waktu; bagian 9: butir lisensi latar bengkel (belum boleh masuk rilis) |
| `docs/design/redesain/README.md` | Pembuka (status per 2026-10-23: sebagian terpasang), bagian 6 butir 1 dan 2 berstatus "terpasang (usulan, run UI-1, dinilai di HP)" beserta penyimpangan, catatan hanya latar 800 dan komponen bengkel yang dipasang, daftar "Butir terbuka (pemilik)" (lisensi latar, kontras garis kartu, lapisan jeda). Bagian 1 dan 7 tidak diubah (tidak ada fakta yang keliru; tabel bagian 1 menyebut `--mock`, tetap benar) |
| `tools/ui_art/README.md` | Perintah tiga `--salin`, `UI_ART_SALIN_KE`, `pasang.py`, `tools/ukur_kontras_tangkapan.py`, uji baru; tabel File (`pasang.py`, pengukur kontras; baris `komponen.py` tidak lagi bertulis "belum ada --salin") |
| `AGENTS.md` | Intro Fase 6A diperpanjang dengan run UI-1; perintah cepat (tiga `--salin`, `UI_ART_SALIN_KE`, `uji_ui_redesain.py` yang diperluas, `ukur_kontras_tangkapan.py`, probe bengkel diperbarui; baris `--mock` tidak lagi bertulis "belum ke assets/"); peta repo: paragraf "Run UI-1" (kelas baru, fungsi `GayaHud`, aset, tes, tools) dan baris `tools/ui_art/` |
| `.cursor/rules/00-project-core.mdc` | Hanya bagian Perintah: baris probe bengkel diperbarui, dua baris baru (`komponen.py --salin` dengan catatan dua skrip lain, `uji_ui_redesain.py`). Tidak ada aturan baru (pola run 6A2/5x: bagian Perintah ikut diperbarui) |
| `CLAUDE.md` | Tidak diedit (aturan hanya di `.cursor/rules/`) |
| `docs/README.md` | Baris status ditambah paragraf run UI-1; baris `design/` (redesain tidak lagi "belum dipasang"); baris `LOOP-DEV-QA.md` menyebut 6k |
| `docs/DEV_PHASES.md` | Fase 6: butir baru **belum dicentang** "Redesain UI layar penuh" (UI-1 dikerjakan Dev, menunggu QA dan uji HP 8.18); baris tabel Fase 6. Tidak ada butir aset UI yang dicentang |
| `docs/SETUP_ANDROID.md` | Bagian 8.18 baru (10 butir checklist HP + lembar hasil kosong bergaya 8.17): terbaca sekilas, sepeda dan chip, tombol dan tiga keadaan, kartu menonjol vs redup, harga dekat tombol, latar, tiga upgrade tanpa scroll di vivo dan A54, Hari berikutnya, zona aman, 60 fps |
| `docs/LOOP-DEV-QA.md` | Bagian 6k baru: tabel run (UI-1, UI-2 dst), putusan U-1..U-5, perintah run (scope A/B/C, di luar scope, tes, izin HP, RUN_ID) dan catatan pelajaran. **Catatan jujur:** teks perintah disusun dari SPEC (kontrak run); pesan asli pemilik tidak tersedia bagi Dev, jadi bukan salinan kata demi kata |
| `docs/ROADMAP.md` | Bagian 5: butir terbuka lisensi latar bengkel (pemilik) dan butir redesain UI (langkah 3 sampai 6, lapisan jeda, garis kartu); satu kalimat pembaruan di status |

**Dokumen yang diperiksa dan TIDAK diubah:** `docs/BALANCING.md`, `docs/DATA_SCHEMA.md`, `docs/GDD.md` (12.3/12.4 hanya menyebut bengkel dan HUD secara fungsional), `docs/ROUTE_DESIGN.md`, `docs/CONTENT_GUIDE.md`, `docs/TECH_PLAN.md`, `CHANGELOG.md`, `.release-please-manifest.json`, `version.txt`. Alasan: SPEC U-5, tidak ada angka ekonomi, aturan permainan, format data, atau format save yang berubah (`upgrades.json` tidak berubah; kunci terjemahan baru bukan data konten). `grep` untuk "redesain", "belum dipasang", dan "bengkel" di dokumen itu tidak menemukan klaim yang menjadi keliru.

**Pemeriksaan konsistensi:** semua tautan relatif dan jalur berkas dalam backtick yang ditambah menunjuk ke berkas yang ada (dicek skrip pada diff); tidak ada kata "dikunci" atau "terpasang final" pada baris yang ditambah (kecuali kalimat penolakan); jumlah berkas terpasang (30), kelas, dan nama skrip dicocokkan dengan `pasang.py` dan `scripts/`.

**Gerbang bagian C:** `godot --headless --import` tanpa error (satu baris "cannot connect to daemon at tcp:5037" dari editor yang mencari adb, bukan galat project); `--quit-after 2` tanpa ERROR/WARNING; `run_tests.gd` **23003 lolos, 0 gagal** (sama dengan akhir bagian B) + `cek_keluaran_tes.py` lolos (0 peringatan); 17 `tools/tests_cek/uji_*.py` exit 0 (termasuk `uji_ui_redesain.py` LOLOS dan `uji_aset_*` yang membandingkan mock docs); sha256 save asli `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e` tidak berubah; `git status` hanya berisi berkas dokumen/README/rule yang diubah (selain `.claude/` yang bukan bagian run).

## Keputusan Dev yang perlu diterima atau ditolak (review PR)
Semuanya usulan; ditolak = diubah di iterasi berikutnya atau run berikutnya, tanpa menahan sisanya.

| Id | Keputusan | Alasan singkat | Dampak bila ditolak |
|---|---|---|---|
| D-1 | Garis bingkai kartu (1,14..1,78:1) dan tombol nonaktif (1,14:1) tidak memenuhi AC-9 "garis komponen >= 3:1"; kartu dibedakan lewat isi dan garis WARN | Kanvas memakai garis luar `OUTLINE` gelap di atas latar gelap; teks semua >= 7,79:1, tombol aktif 8,53..13,48:1 | Sorot garis di aset komponen (`komponen.py`, mengubah `uji_ui_redesain.py` dan semua kartu) |
| D-2 | Margin dengan inset = `max(12, inset)` (`ZonaAman.margin`), bukan `12 + inset` papan kanvas g | Satu aturan zona aman proyek, dipakai layar lain dan tes lama | Ubah rumus margin bengkel saja; tes keadaan g memakai angka kanvas dan perlu disesuaikan |
| D-3 | Judul "Bengkel" di y 12 (margin), bukan y 11 | Mengikuti margin; isi tetap mulai y 46 | Satu konstanta |
| D-4 | Ring luar panggung 1 px digambar di luar panggung (seperti `box-shadow` kanvas) | Ukuran panggung 92 tepat | Visual kecil |
| D-5 | Panggung punya tinggi minimum 40; di bawah 78 sepeda terklip bawah (inset sangat besar) | Tidak ada perangkat nyata dengan inset sebesar itu | Perlu aturan skala sepeda bila ada |
| K1 | Rect sepeda untuk AC-9 = panggung (papan + sepeda), bukan sprite 116x78 | Chip ban dan rem di kanvas berada di luar sprite | Perketat jadi sprite saja: chip harus digeser ke dalam |
| K2 | Kartu servis BAIK-belum-penuh (kondisi 0,70..0,999) redup tetapi tetap membawa harga dan tombol Servis; penuh = chip "Baik" tanpa tombol | Aturan bagian A "BAIK = redup" dan servis tetap tersedia | Kartu menonjol untuk semua yang belum penuh |
| K3 | Teks status turun di bawah kotak kondisi bila kolom sempit (`HFlowContainer`), sebaris bila muat (lebar 800) | "Perlu servis" 45 px tidak muat sebaris di 640 | Teks lebih pendek atau kotak di atas teks selalu |
| K4 | Status "Perlu servis" dan pesan galat berwarna `TEXT`, bukan WARN | WARN di atas `UI_PANEL` 6,91:1 < 7:1 | Pakai WARN dan terima 6,91:1 (melanggar AC-9) |
| K5 | Chip jejak tingkat "menunggu" tidak diredupkan | Opacity .55 kanvas = 3,65:1 | Terima kontras rendah untuk tingkat belum dibuka |
| K6 | Pelat `HUD_PANEL` 3 px di belakang judul "UPGRADE" | Cahaya lampu menutupi judul di 640..800 | Judul tanpa pelat atau latar digeser |
| P1 | Latar 640 dibuang dari paket (latar 800 di tengah, dipotong 80 px per sisi di 640, seperti kanvas) — **penyimpangan SPEC AC-2 ("640/800")** | Kanvas memakai satu latar 800 dengan `bgx = (W - 800) / 2`; 640 = potongan tengah 800, diuji; tidak ada aset tak terpakai di `assets/` | Satu baris di `pasang.py` lalu `--salin` |
| P2 | Ikon 24 dan glif 12 dipasang per sel, bukan sheet utuh | SPEC: tidak ada aset redesain yang tak dipakai di `assets/`; piksel sama dengan sheet | Pasang sheet utuh dan potong di kode |
| P3 | `UI_ART_SALIN_KE` = folder tujuan langsung, sama untuk tiga skrip; `latar_bengkel.py` memuat `cv2`/`sklearn` hanya saat membuat ulang | `--salin` tidak butuh pustaka berat dan tes bisa tidak menyentuh `assets/` | Nama variabel atau aturan impor |
| P4 | Latar dipasang untuk uji HP walau lisensi generator belum dicatat (U-4) | Putusan orchestrator; tidak memblokir run | Ganti latar atau catat lisensi sebelum rilis (ART_DIRECTION 9) |

## NEEDS-MANUAL (uji di HP)
- [ ] SETUP_ANDROID 8.18 (lihat SPEC): bengkel terbaca sekilas; sepeda dan chip kondisi jelas; tombol enak ditekan, tiga keadaan jelas bedanya; kartu menonjol vs redup; harga dekat tombol; latar tidak mengganggu teks; tiga upgrade tanpa scroll; 60 fps.

## Keputusan & catatan
- Putusan U-1..U-5 dan semua keputusan lama: lihat SPEC. Tidak ada keputusan terbuka yang menghambat saat SPEC ditulis; kalau tata C tidak muat di 640 untuk teks terpanjang, berhenti dan tanyakan SEKALI dengan satu rekomendasi.


## Bagian B — bengkel tata C (Dev, iterasi 1; commit 47c7fbd, bdd3732, f45880d, c9370b7, 2ff7173, 98115b8, e754afd, dan commit penutup bagian B)

### Tabel kerja angka dari kanvas (langkah 1)
Sumber: `Bengkel.dc.html` (`renderVals`), `ui.css`, `Spesifikasi.dc.html`, README redesain 4, `sepeda.json`. Semuanya jadi `Config.BENGKEL_*` / `UI_*` (pemindai "tanpa angka literal" di `scripts/ui|systems`), dijaga tes dengan oracle literal.

| Butir | Kanvas | Di game |
|---|---|---|
| Margin layar | 12 + inset | `ZonaAman.margin(12, inset)` = max (aturan satu-satunya proyek, lihat deviasi D-2) |
| Judul / isi mulai | judul y 11, isi y 46 | judul y 12 (margin), baris atas 34 tinggi => isi y 46 (`BENGKEL_BARIS_ATAS_PX`) |
| Kolom | 48 % | 8 | upgrade; 616 -> 296 | 312 | `TampilBengkel.lebar_kolom` (tes: 616, 592, 756, 776) |
| Panel servis | padding 4 + garis 4 = 8, jarak 4, baris judul 12, catatan 12 | sama |
| Kartu servis / upgrade | 50 / 62 (72 bila bertingkat), jarak 4 / 6, isi kiri 8 kanan 4, jarak isi 6 | sama |
| Chip | harga/Baik/Dimiliki 18, tingkat 14, saldo 24, jarak isi 3 (4 besar) | sama (`ChipUi`) |
| Tombol | 84 x 42, "Hari berikutnya" 140 x 42 kanan bawah | sama; `GayaHud.tombol_*` |
| Sepeda / papan / latar | 116x78 (`bx = sw/2 - 58`, `by = sh - 4 - 78`), papan 360x104 (`sw/2 - 180`, dasar), latar 800 di tengah (`(W-800)/2`, KEEP_CENTERED + klip) | `TampilBengkel.tata_panggung`, `PanggungSepeda`, `GambarLatar` |
| Titik chip | `titik_kecil` ban (5,68), rem (74,4), rantai (33,54); chip ban di depan titik (`x - w - 4`, min 2), rem `x + 5`, rantai `x - 10`, `y + 6`; lainnya `y - 7` | `BENGKEL_SEPEDA_TITIK` (= JSON, dites), `TampilBengkel.rect_chip` + jepit ke panggung |
| Hasil ukur (640, tanpa inset) | stage `sh` = 92 | panggung 280x92, panel servis 296x302, kolom upgrade 312 (cocok) |

Muat di 640 untuk teks terpanjang: ya, tidak BLOCKED. Ukur Godot (Lexend): "Stamina awet dan rantai lebih tahan" 160 px (9 px) membungkus 2 baris di kolom teks ~103; "Perlu servis" 45 px (8 px) tidak muat sebaris dengan tiga kotak + "!" (33 + 5 + 45 = 83 > 72) sehingga turun di bawah kotak (lihat keputusan 3); "125.480" di chip besar 46 px; "Koin kurang" 62 px di tombol 76 px dalam; "Hari berikutnya" 80 + 12 + 4 di 132 px dalam. Tidak ada teks yang dipotong di 640 sampai 800 (tes dan probe).

### Yang dibangun
- Logika murni `scripts/systems/tampil_bengkel.gd` (`TampilBengkel`, tes `tests/tes_tampil_bengkel.gd`): keadaan kartu servis (`servis(kondisi, harga, saldo)`: kartu menonjol/redup/biasa lewat `KomponenUi.kartu_servis`, penuh lewat `Economy.penuh`, status, chip penanda AUS/PERLU), `aksi/kunci_tombol` (AKTIF, KURANG bertulis "Koin kurang", TIDAK_ADA), `upgrade(...)` satu kartu per komponen (tingkat dijual, jejak DIMILIKI/AKTIF/MENUNGGU, tinggi 62 atau 72, chip tingkat), `kunci_tingkat` (I, II, III), `lebar_kolom`, `tata_panggung`, `rect_chip`, `rect_titik`. Perluasan `KomponenUi`: `warna_teks_chip`, `pad_y_chip`, `jarak_chip`.
- Node: `ChipUi` (chip 9-slice, status -> gaya + glif + teks), `PanggungSepeda` (panggung, papan, sepeda, titik, chip penanda; semua dari `TampilBengkel`), `GayaHud.chip_gaya`, `LayarBengkel` ditulis ulang (anchor + Container; tanpa hex; tekstur const preload; kartu servis dan upgrade dari komponen bagian A), `bengkel.tscn` baru, tema: `LayarLabel` berspasi huruf 1 px (FontVariation) dan `LayarTeksMini` (8 Regular).
- Kunci baru `ui.csv`: `BENGKEL_LABEL_SALDO`, `BENGKEL_PENANDA_PERLU` ("! {nama}"), `BENGKEL_PENANDA_AUS` ("{nama} aus"), `BENGKEL_TINGKAT_1/2/3` (I, II, III), `BENGKEL_TINGKAT_LAIN`; kunci lama tidak diubah; `.translation` hasil impor ikut di-commit.
- Config: blok `BENGKEL_*` lama (jarak, rasio kolom, lebar harga) diganti blok tata C; `UI_CHIP_PAD_Y_*`, `UI_CHIP_JARAK_*`. Konstanta Vector2i ditolak parser Config, jadi ukuran dan titik berupa int dan `Array[int]`.
- Perilaku tak berubah: sinyal, API tes, Economy, `HariMain` (tidak disentuh). Tombol nonaktif tetap dilindungi penolakan atomik `Economy` (tes: `pressed.emit()` dan `ditekan.emit()` pada nonaktif -> state identik). Back Android, simpan sekali, dan alur Hasil -> Bengkel -> Hari berikutnya dijaga tes lama (lolos).
- `tools/ukur_kontras_tangkapan.py` (baru): ukur kontras dari tangkapan nyata + JSON persegi dari probe.

### Keputusan kecil Dev bagian B (usulan; bisa ditolak)
1. **"Rect sepeda" untuk AC-9 = panggung sepeda** (papan + sepeda, 280x92 di 640), bukan sprite 116x78 saja: di kanvas chip ban/rem berada di LUAR sprite (di depan titik ban dan sesudah titik rem). Tes memeriksa chip di dalam panggung, titik 5x5 di dalam gambar sepeda, dan chip tidak saling menumpuk.
2. **Kartu servis BAIK-belum-penuh** (kondisi 0,70..0,999): redup (aturan bagian A `KomponenUi.kartu_servis`, "BAIK = redup") tetapi tetap membawa chip harga + tombol Servis dan status "Baik"; penuh = chip "Baik" tanpa tombol. Sepeda bersih untuk tingkat BAIK.
3. **Teks status turun di bawah kotak kondisi** bila kolom teks sempit (`HFlowContainer`), bukan membungkus huruf demi huruf di sebelahnya seperti kanvas: di 640 "Perlu servis" (45 px) tidak muat sebaris dengan kotak (33) dan harga + tombol (160). Ditemukan lewat tes `inset 36` (status 22 px lebar dibungkus 3 baris, kartu 60 > 50). Sebaris bila muat (lebar 800).
4. **Status "Perlu servis" dan pesan galat berwarna TEXT, bukan WARN** (kanvas `c-warn`): WARN di atas `UI_PANEL` hanya 6,91:1 (< 7:1, AC-9). Pembeda tetap: kartu bergaris WARN, "!" WARN di kotak kondisi, chip penanda WARN (7,79:1), glif "!" WARN.
5. **Chip jejak tingkat "menunggu" tidak diredupkan (opacity .55 di kanvas ditolak)**: teksnya 3,65:1 di tangkapan nyata. Dibedakan dari "dimiliki" (centang) dan "aktif" (gaya aksen).
6. **Pelat `HUD_PANEL` di belakang judul "UPGRADE"**: judul ini di atas latar, tepat di bawah lampu (selalu tertutup cahaya lampu di 640..800, ACCENT di atas cahaya tidak terbaca). Satu pelat 3 px per sisi, tanpa token baru.
7. **Model tampilan tingkat 2-3**: satu kartu per komponen dari `PemuatToko` (dikelompokkan per `komponen`, urut `level`); `kartu.data` = tingkat yang sedang tampil; `tombol_beli(id)` hanya untuk id yang sedang tampil; `kartu_upgrade(id)` untuk id tingkat mana pun komponen itu. Jejak I, II, III dan tinggi 72 hanya bila data punya > 1 tingkat (`upgrades.json` tidak berubah: tiga kartu tunggal 62; diuji dengan data uji lima upgrade).
8. **Chip tingkat di bawah ikon**: aksen bila dimiliki atau komponen bertingkat, netral selain itu (menyatukan kanvas Bengkel a/d dan Bengkel_Tingkat yang tidak konsisten).
9. **Tinggi chip** dipaksa 14/18/24 lewat jarak isi atas-bawah 2/2/3 (`UI_CHIP_PAD_Y_*`) karena baris teks Lexend 8/10/12 setinggi 10/13/15 (kanvas line-height 8/12/-).
10. **Anti-bug tata letak**: label berbungkus kata yang baru tampil menghitung tinggi dengan lebar 0; `Batas` lalu membesar dan Control MENYIMPAN ukuran itu di offsetnya (isi bergeser ke atas layar, tertangkap probe keadaan galat). `LayarBengkel._pulihkan_batas` menegakkan persegi penuh sesudah `isi()` (deferred) dan tiap `_susun()`; `_susun` juga dijaga `is_inside_tree()` (sinyal `size_changed` ke layar yang sudah dicabut). Tes keadaan f memeriksa tinggi isi.

### Deviasi dari SPEC/kanvas (untuk ditolak atau diterima)
- **D-1** AC-9 "kontras garis komponen >= 3:1": TIDAK terpenuhi oleh desain untuk bingkai kartu (1,14..1,78:1; garis luar `OUTLINE` gelap di atas latar gelap) dan tombol nonaktif (1,14:1; sengaja redup, rata, diarsir). Tombol aktif 8,53..13,48:1. Teks semua >= 7,79:1. Kartu dibedakan dari latar lewat isi, bukan garis. QA/pemilik memutuskan apakah garis kartu perlu diberi sorot (itu mengubah aset bagian A).
- **D-2** Margin dengan inset = `max(12, inset)` (aturan `ZonaAman.margin`, dipakai layar lain dan tes lama), bukan `12 + inset` seperti papan kanvas g (README: "12 + inset aman (max)", ambigu). Tes keadaan g memakai margin 36 kiri dan 20 bawah supaya angka kanvas (kolom 284 | 300, sepeda by = 2) teruji.
- **D-3** Judul "Bengkel" y 12 (margin), bukan 11.
- **D-4** Ring luar panggung 1 px digambar di luar panggung (seperti `box-shadow` kanvas) sehingga ukuran panggung (92) sama persis.
- **D-5** `rem` panggung sangat sempit (inset besar): panggung punya tinggi minimum 40; di bawah 78 sepeda terklip bawah (tidak diuji di perangkat nyata mana pun; chip dijepit ke dalam panggung).

### Gerbang bagian B
- `godot --headless --import` tanpa error; `--quit-after 2` tanpa ERROR/WARNING.
- `run_tests.gd` + `tools/cek_keluaran_tes.py`: **23003 lolos, 0 gagal, 0 peringatan** (baseline A 20921; +2082 pemeriksaan: `TesTampilBengkel` murni, `TesBengkelTataC` scene (kontras token, keadaan a-g, gaya tombol, tingkat I-III, enam jendela x inset), `_test_aset_ui1_ikut_paket`, `TesKomponenUi` tak berubah). Dua tes baru terdaftar di `run_tests.gd` sesudah `TesBengkelScene`.
- Semua 17 `tools/tests_cek/uji_*.py` exit 0 (setelah perbaikan `uji_aset_pasang_5b.py`).
- Paket `godot --headless --path . --export-pack "Android" build/kring-uji.pck`: seluruh 29 PNG UI yang dipasang + `ui_bengkel_sepeda.json` ada; tidak ada `ui_koran_`, `ui_struk`, `sepeda_besar`, `ui_foto_`, `lencana32`, `latar_640`, `ui_kertas_tile`, `ui_lembar`, `glif12`, `ikon24`; skrip `tampil_bengkel`, `chip_ui`, `panggung_sepeda` di paket.
- Bukti layar lain tak berubah: `probe_hud_rute_jendela.gd` 1920x1080, sebelum (pohon `aebfde0` di worktree, dua kali) lawan sesudah (pohon ini): sembilan dari sepuluh tangkapan piksel-identik (hasil, jeda sakelar, kidal, radar, bantu abu, progres, tenggat); `hud_awal` beda 322.556 piksel di dua run SEBELUM sendiri (fase animasi jam dinding, sama seperti catatan bagian A), jadi bukan UI.
- sha256 save asli: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e` (tidak berubah, sebelum dan sesudah probe/tes).

### Probe dan tangkapan (AC-10)
`tests/probe_bengkel_jendela.gd`: keadaan a-g, sesudah servis, tingkat I, II, dan III dimiliki (data uji), di 1920x1080 (lebar 640), 2340x1080 (780), 2400x1080 (800), dan 1600x720 (800); lebar 667 dan 700 hanya di tes scene (`2001x1080`, `2100x1080`). Lebar 800 diperoleh dari rasio 20:9 (2400x1080 dan 1600x720): viewport `canvas_items` + `expand` melebarkan viewport game sesuai rasio jendela, jadi tidak perlu trik. Hasil: 0 keadaan tidak sesuai di keempat ukuran (teks terpotong, tumpang tindih, tombol < 42 tinggi / < 84 lebar, chip di luar kartu atau panggung, kolom != `lebar_kolom`). Tangkapan: `docs/loop/20261023-ui1-komponen-bengkel/shots/iter1/<ukuran>_bengkel_<keadaan>.png` (+ `.json` persegi teks untuk pengukur kontras). Dibandingkan dengan kanvas: kolom 296 | 312, panggung 92 tinggi, kartu 50 / 62, chip "! Ban", "! Rem", "Rantai aus" di titik sepeda, kartu menonjol bergaris WARN, kartu redup, "Koin kurang" diarsir, "Hari berikutnya" 140x42 kanan bawah, saldo enam digit, pesan galat: cocok. Beda disengaja: D-1..D-4, keputusan 3 dan 6.

### Kontras terukur dari tangkapan nyata (`python3 tools/ukur_kontras_tangkapan.py docs/loop/20261023-ui1-komponen-bengkel/shots/iter1 --awalan <ukuran>`)
Teks (latar = warna terbanyak di persegi teks, teks = persentil 98): terburuk 7,79:1 ("! Ban" WARN di chip warn), berikutnya 8,28:1 ("Baik" OK di chip ok); 0 teks < 7:1 di 44 tangkapan (11 keadaan x 4 ukuran), termasuk "UPGRADE" di atas pelat, status, deskripsi, harga, tombol. Garis komponen (pita luar 2 px game vs 2 px di luar): tombol aktif 8,53..13,48:1 (>= 3); kartu 1,14..1,78:1 dan tombol nonaktif 1,14:1 (< 3, lihat D-1). Dua temuan yang sudah diperbaiki sebelum angka akhir: chip jejak "menunggu" 3,65:1 (keputusan 5) dan WARN di atas `UI_PANEL` 6,91:1 (keputusan 4; tes `_test_kontras_token` menjaga kontras teks token terhadap isi tekstur terpasang secara deterministik).

### Mutan (AC-13; Dev, satu perubahan per mutan, `git checkout` sesudahnya)
Dijalankan dengan harness sementara (`build/mutan.py`, tidak di-commit) pada subset `TesTampilBengkel + TesKomponenUi + TesExport + TesBengkelTataC + TesBengkelScene`; subset ini adalah bagian dari `run_tests.gd` penuh. Putaran 1: 41 dari 50 tertangkap, 9 LOLOS (M28, M34, M42, M43, M44, M45, M46, M47, M50). Tes ditambah (jepit mendatar chip di panggung sempit, warna teks chip literal, warna nama upgrade dimiliki, warna teks status, titik penanda tidak tampil untuk komponen baik dan warnanya, tinggi chip penanda 14 dan chip harga/saldo/Baik 18/24, panah tombol hari di kanan); M40 hanya tertangkap lewat SCRIPT ERROR dan diperkuat dengan pemeriksaan eksplisit. Putaran 2 (pohon akhir): **50 dari 50 tertangkap**, pohon kerja bersih sesudahnya.

| Id | Perubahan | Tertangkap oleh (pemeriksaan pertama yang gagal) |
|---|---|---|
| M01 | aksi: saldo tepat harga jadi KURANG (`>=` -> `>`) | tes_tampil_bengkel: saldo 84 untuk harga 84 AKTIF |
| M02 | aksi: AKTIF dan KURANG tertukar | tes_tampil_bengkel kondisi 0,75 + 45 lain |
| M03 | aksi: tersedia=false tidak TIDAK_ADA | tes_tampil_bengkel kondisi 1,0 penuh |
| M04 | kunci_tombol: alasan "Koin kurang" hilang | tes_tampil_bengkel teks tombol |
| M05 | servis: kartu selalu biasa | tes_tampil_bengkel kondisi 1,0 |
| M06 | servis: penuh selalu false | tes_tampil_bengkel kondisi 1,0 |
| M07 | servis: status tampil saat penuh | tes_tampil_bengkel kondisi 1,0 |
| M08 | servis: AUS tanpa penanda di sepeda | tes_tampil_bengkel kondisi 0,50 |
| M09 | servis: kunci penanda PERLU dan AUS tertukar | tes_tampil_bengkel kondisi 0,50 |
| M10 | servis: harga tampil saat penuh | tes_tampil_bengkel kondisi 1,0 |
| M11 | upgrade: tingkat dimiliki dijual lagi (`>` -> `>=`) | tes_tampil_bengkel level 1 |
| M12 | upgrade: semua dimiliki menampilkan tingkat I | tes_tampil_bengkel level 3 |
| M13 | upgrade: dimiliki masih beraksi | tes_tampil_bengkel level 1 |
| M14 | upgrade: dimiliki tidak redup | tes_tampil_bengkel level 1 |
| M15 | upgrade: jejak tampil untuk satu tingkat | tes_tampil_bengkel level 0 |
| M16 | jejak: tingkat dimiliki bukan DIMILIKI (`<=` -> `<`) | tes_tampil_bengkel level 1 |
| M17 | upgrade: tinggi bertingkat tetap 62 | tes_tampil_bengkel bertingkat |
| M18 | chip tingkat: `or` -> `and` | tes_tampil_bengkel level 1 |
| M19 | jejak: gaya AKTIF dan MENUNGGU tertukar | tes_tampil_bengkel jejak gaya |
| M20 | kunci_tingkat: III jatuh ke angka biasa | tes_tampil_bengkel kunci I, II, III |
| M21 | lebar_kolom: floor alih-alih round | tes_tampil_bengkel lebar 640 |
| M22 | lebar_kolom: jarak 8 tidak dikurangi | tes_tampil_bengkel + tes_bengkel_tata_c |
| M23 | tata_panggung: sepeda menempel dasar | tes_tampil_bengkel panggung 280x92 |
| M24 | tata_panggung: papan memakai lebar sepeda | tes_tampil_bengkel panggung |
| M25 | rect_chip: chip ban di sisi salah | tes_tampil_bengkel ban + 30 lain |
| M26 | rect_chip: chip rantai di atas titik | tes_tampil_bengkel rantai |
| M27 | rect_chip: tanpa jepit tegak | tes_tampil_bengkel panggung 84 |
| M28 | rect_chip: tanpa jepit mendatar | LOLOS putaran 1; sekarang tes_tampil_bengkel panggung 160 lebar |
| M29 | SISI_PENANDA: ban sesudah titik | tes_tampil_bengkel sisi chip |
| M30 | titik_sepeda: y memakai x | tes_tampil_bengkel titik |
| M31 | Config titik ban y 67 | tes_tampil_bengkel titik (Config = JSON) |
| M32 | KomponenUi: kartu BAIK tidak redup | tes_tampil_bengkel kondisi 1,0 |
| M33 | KomponenUi: chip AUS bergaya WARN | tes_komponen_ui "AUS = netral + teks" |
| M34 | warna teks chip OK jadi TEXT | LOLOS putaran 1; sekarang tes_bengkel_tata_c warna teks chip |
| M35 | layar: gaya tombol aktif dan nonaktif tertukar | tes_bengkel_tata_c keadaan a |
| M36 | layar: catatan ongkos baru di 3 rusak | tes_bengkel_tata_c keadaan b |
| M37 | layar: label chip tidak ikut disembunyikan | tes_bengkel_scene penuh "Baik" |
| M38 | layar: kolom servis memakai lebar upgrade | tes_bengkel_tata_c keadaan g |
| M39 | layar: tombol hari memakai margin atas | tes_bengkel_tata_c keadaan g |
| M40 | layar: Beli selalu tingkat pertama | LOLOS-lemah putaran 1 (hanya crash); sekarang tes_bengkel_tata_c "kartu berganti ke III" |
| M41 | layar: tombol Beli tetap tampil saat dimiliki | tes_bengkel_tata_c keadaan d |
| M42 | layar: nama upgrade dimiliki tidak redup | LOLOS putaran 1; sekarang tes_bengkel_tata_c keadaan d |
| M43 | layar: warna status PERLU sama dengan AUS | LOLOS putaran 1; sekarang tes_bengkel_tata_c keadaan b |
| M44 | panggung: titik tampil walau baik | LOLOS putaran 1; sekarang tes_bengkel_tata_c keadaan a |
| M45 | panggung: titik PERLU bukan WARN | LOLOS putaran 1; sekarang tes_bengkel_tata_c keadaan b |
| M46 | panggung: chip penanda ukuran normal | LOLOS putaran 1; sekarang tes_bengkel_tata_c keadaan b (tinggi 14) |
| M47 | layar: panah Hari berikutnya di kiri teks | LOLOS putaran 1; sekarang tes_bengkel_tata_c gaya tombol |
| M48 | layar: galat data tidak ditampilkan | tes_bengkel_tata_c keadaan f |
| M49 | layar: kartu servis selalu biasa | tes_bengkel_tata_c keadaan a |
| M50 | ChipUi: tinggi chip tidak dipaksa | LOLOS putaran 1; sekarang tes_bengkel_tata_c chip Baik 18 |

Catatan: satu kejadian kerja, bukan mutan: `git checkout` milik harness sempat membuang suntingan `panggung_sepeda.gd` yang belum di-commit (menghapus `warna_titik`, membuat M44..M46 tampak "galat skrip"); suntingan dipasang ulang dan di-commit sebelum mutan itu diulang.

### Butir yang mengganjal / perlu keputusan
- D-1 (garis kartu 1,14..1,78:1 dan tombol nonaktif 1,14:1 < 3:1) dan D-2 (max vs 12 + inset).
- `uji_aset_pasang_5b.py` sudah gagal di HEAD bagian A (diperbaiki di sini).
- Lisensi latar bengkel tetap terbuka (bagian C mencatatnya di dokumen).

## QA iterasi 1 (Agent 2, independen; semua perintah dijalankan sendiri, satu proses Godot sekaligus)

**Verdict: FAIL** (gerbang objektif hijau; 2 Major OPEN: QA-001 layout rusak untuk nama upgrade 21-24 huruf, QA-002 mutan chip harga lolos). Temuan: Blocker 0, Major 2, Minor 1, Nit 6.

### Gerbang objektif
| Gerbang | Perintah | Hasil |
|---|---|---|
| Impor | `godot --headless --import` | selesai, tanpa ERROR |
| Buka proyek | `godot --headless --path . --quit-after 2` | tanpa ERROR/WARNING |
| Tes | `godot --headless --script res://tests/run_tests.gd` + `python3 tools/cek_keluaran_tes.py build/tests.log` | 23003 lolos, 0 gagal; pemeriksa: lolos (0 peringatan) |
| Alat Python | semua 17 `tools/tests_cek/uji_*.py` (termasuk `uji_pemeriksa.py`, `uji_ui_redesain.py`) | semua exit 0 |
| Save asli | sha256 `~/Library/Application Support/Godot/app_userdata/Kring Kring!/save.json` sebelum dan sesudah (juga sesudah semua probe dan 18 mutan) | `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e` tetap |
| Kebersihan repo | `git diff main...HEAD --name-only`, `git log main..HEAD` | tidak ada `.godot/`, `build/`, APK, keystore, secret; tidak ada commit di `main` (branch `feat/ui1-komponen-bengkel`, 17 commit, tanpa merge); semua commit berformat `tipe: ...` bahasa Indonesia + `Claude-Session`; `.uid` dan `.import` ada untuk skrip dan PNG baru; tidak ada file nyasar |
| Paket | `godot --headless --path . --export-pack "Android" build/kring-uji.pck` | ada: 29 PNG UI terpasang, `ui_bengkel_sepeda.json`, skrip/scene bengkel, `theme.tres`; tidak ada: `ui_koran_`, `ui_struk`, `ui_foto`, `lencana32`, `sepeda_besar`, `latar_640`, `res://tests`, `res://docs` |

### Kepatuhan AC dan putusan (BUKTI = kode + tes/ukuran yang QA jalankan; TANPA BUKTI = kurang)
| AC / putusan | Status | Catatan QA |
|---|---|---|
| AC-1 baseline | BUKTI | bagian Baseline di LOG ada; angka akhir cocok gerbang di atas |
| AC-2 set aset | BUKTI dengan penyimpangan sah | 29 PNG + `ui_bengkel_sepeda.json` tepat sama dengan `pasang.py` dan `tes_export` (himpunan tepat, impor Lossless Nearest tanpa mipmap, `.import` ada); `SALIN_KE` (`UI_ART_SALIN_KE`) ada. Latar 640 TIDAK dipasang: dibuktikan 640 = potongan tengah 800 (0 piksel beda), `LAYAR_LEBAR_MAKS_PX` 800 (QA-004, diterima) |
| AC-3 `uji_ui_redesain.py` | BUKTI | exit 0, langkah ada di job `alat` (tes.yml:94..154), bukan job `tes` |
| AC-4 fungsi lama utuh | BUKTI | `git diff` `gaya_hud.gd` dan `theme.tres`: hanya penambahan (tidak ada baris `-` di fungsi atau variation lama). Probe `probe_hud_rute_jendela.gd` 1920x1080 dijalankan di worktree `main` dan di branch: `hud_hasil_meleset_lewat`, `hud_hasil_semua`, `hud_jeda_sakelar`, `hud_kidal`, `hud_progres_campuran`, `hud_tenggat_hampir`, `hud_tenggat_lewat` = 0 piksel beda; `hud_awal` dan `hud_radar` beda antar jalan di branch yang sama (derau animasi, `main` jalan 2 = branch jalan 2: 0 piksel); `hud_bantu_abu` beda 45 piksel di kotak 24x12 (x 582..605, y 813..824) secara konsisten main vs branch (dua jalan tiap sisi): QA melihat potongannya, itu satu bingkai koran terbang di dunia (posisi bergantung waktu), bukan HUD/UI; bukan regresi tampilan layar yang dikerjakan. Layar koran/tutorial/banner tidak disentuh (tidak ada di diff) |
| AC-5 kotak kondisi besar | BUKTI | `KotakKondisiBesar` + `TampilKondisiBesar`; `kotak_kondisi.gd` tidak ada di diff; tes murni di `tes_komponen_ui.gd`; terlihat di tangkapan (tiga kotak, berongga, "!") |
| AC-6 bengkel mengikuti kanvas | BUKTI sebagian | angka kanvas (header, isi y 46, kolom 48%|8, kartu 50/62/72, chip 18, sepeda 116x78, titik `sepeda.json` = `Config.BENGKEL_SEPEDA_TITIK` urut ban, rem, rantai) cocok; anchor + Container, tanpa hex di scene. **Teks panjang: autowrap hanya di deskripsi; nama tidak (QA-001)** |
| AC-7 keadaan a-g, tingkat 2-3 | BUKTI | semua dilihat di tangkapan (daftar di bawah) dan diuji dari data nyata |
| AC-8 perilaku tak berubah | BUKTI | `hari_main.gd`, `economy.gd`, `data_save.gd` tidak ada di diff; QA skrip: saldo = harga sah, harga - 1 nonaktif "Koin kurang", `pressed.emit()` pada nonaktif tidak mengubah state/belanja, ketukan ganda servis dan beli membelanjakan sekali, "Hari berikutnya" selalu aktif (saldo 0). Tes lama berubah: hanya satu `check` di `tes_bengkel_scene.gd` (dicatat) dan regex `uji_aset_pasang_5b.py` (QA-007) |
| AC-9 ukuran dan kontras | BUKTI, dengan QA-003 | tombol >= 42 tinggi dan >= 84 lebar (probe 4 ukuran: 0 tidak sesuai; QA skrip saldo sampai 2.147.483.647, semua komponen 0 atau dimiliki, lebar 640..1066: tanpa teks terpotong, tanpa kartu menimpa "Hari berikutnya"). Kontras teks lihat tabel; garis komponen lihat QA-003 |
| AC-10 probe | BUKTI | dijalankan 4 ukuran, 0 keadaan tidak sesuai, tangkapan dilihat |
| AC-11 dokumen | BUKTI | DESIGN_SPEC, ART_DIRECTION, redesain README, tools README, AGENTS, README, DEV_PHASES (tanpa mencentang), SETUP_ANDROID 8.18, LOOP-DEV-QA 6k ada; semua berlabel usulan, tidak ada klaim "dikunci"; butir lisensi latar tercatat |
| AC-12 gerbang akhir | BUKTI | tabel gerbang |
| AC-13 mutan | BUKTI dengan QA-002/005 | Dev 50/50 (klaim); QA 18 mutan: 16 tertangkap, 2 lolos (tabel di bawah) |
| U-1 tata C | BUKTI | |
| U-2 satu bahasa tombol | BUKTI | empat peran, nonaktif rata diarsir "Koin kurang", 140x42 kanan bawah selalu aktif |
| U-3 fungsi baru | BUKTI | |
| U-4 latar dipasang untuk uji | BUKTI | lisensi tercatat sebagai butir terbuka pemilik |
| U-5 tanpa angka ekonomi/kunci lama berubah | BUKTI | `git diff` `translations/ui.csv`: hanya 7 kunci baru (`BENGKEL_LABEL_SALDO`, `BENGKEL_PENANDA_PERLU/AUS`, `BENGKEL_TINGKAT_1/2/3/LAIN`); `config.gd`: hanya konstanta tampilan `BENGKEL_*` (beberapa konstanta lama `BENGKEL_JARAK_PX`, `BENGKEL_TOMBOL_LEBAR_PX`, `BENGKEL_HARGA_LEBAR_PX`, `BENGKEL_KOLOM_*_RASIO` dihapus karena tidak lagi dipakai; tes hijau) dan `UI_*`/`KONDISI_BESAR_*`; tidak ada konstanta `SERVIS_*`/`TOKO_*` berubah |

### Tangkapan yang QA jalankan dan LIHAT (`docs/loop/20261023-ui1-komponen-bengkel/shots/qa_iter1/`, 4 ukuran x 11 keadaan = 44 PNG + JSON)
Dilihat satu per satu (Read PNG): 2340x1080 `a_baru`, `b_ada_rusak`, `c_saldo_kurang`, `d_sesudah_beli`, `e_terpadat`, `f_galat_data`, `g_inset_aman`, `tingkat_2`, `tingkat_3_dimiliki`; 1920x1080 (lebar 640) `e_terpadat`, `g_inset_aman`, `tingkat_3_dimiliki`, `f_galat_data`. Yang TIDAK saya lihat sebagai gambar (hanya dijalankan dan lolos pemeriksaan probe/JSON): 2400x1080 dan 1600x720 (lebar 800, diperiksa lewat angka probe), `sesudah_servis` dan `tingkat_1` semua ukuran, 1920x1080 `a`,`b`,`c`,`d`. Perbandingan dengan kanvas dilakukan lewat angka dan komposisi dari `Bengkel*.dc.html`/`ui.css`/`sepeda.json` (kanvas tidak bisa dirender di sini: bergantung `support.js` dan blob). Hasil: sepeda di tengah panggung dengan chip "! Ban" di depan titik ban, "! Rem" sesudah titik rem, "Rantai aus" di bawah titik rantai (sepeda baik tampil bersih, keadaan a); kartu PERLU SERVIS berbingkai WARN menonjol, BAIK/Dimiliki redup dengan chip "Baik"/"Dimiliki" bercentang; chip harga persis di sebelah tombol, juga di samping "Koin kurang"; tombol nonaktif rata, diarsir, teks alasan; jejak tingkat "I | II | III" dengan centang dan tingkat aktif beraksen; tiga kartu upgrade dan tiga kartu servis muat tanpa scroll di 640, 780, 800; "Hari berikutnya" 140x42 kanan bawah, panah di kanan; galat data menampilkan panel WARN, servis tetap jalan; inset aman menggeser margin dan tombol; tidak ada teks terpotong; lampu latar menimpa judul "UPGRADE" tetapi berpelat (terbaca). Pengamatan: potongan krem (kalender) dari latar mengintip di celah antar kartu upgrade (tidak mengganggu teks); bagian latar di bawah kartu upgrade terakhir kosong.

Tangkapan lama hasil/jeda: `probe_hud_rute_jendela.gd` 1920x1080 dijalankan di worktree `main` (`b99f5a9`, sudah di-prune) dan branch; layar hasil, jeda (sakelar), kidal, progres, tenggat, hasil semua: piksel identik (lihat AC-4). Tampilan sama dengan main.

### Kontras (ukuran QA sendiri dari tangkapan; skrip scratchpad `kontras_qa3.py`, `kontras_qa2.py`; metode berbeda dari `tools/ukur_kontras_tangkapan.py`)
- Teks: warna token dari JSON probe (bukan estimasi piksel) melawan warna latar modal di persegi teks, 44 tangkapan: terburuk 7,79:1 ("! Ban"/"! Rem"/"! Rantai" WARN di chip warn), lalu 8,28:1 ("Baik"), 8,32:1 ("UPGRADE" di pelat), 8,53:1 (TEXT_2 di `UI_PANEL`/status/deskripsi/"Koin kurang"), 8,99:1, 9,63:1 dst; tidak ada teks < 7:1. Cocok dengan angka Dev, tetapi dihitung ulang dengan warna token independen.
- "Koin kurang" di atas arsir: dua warna arsir `(42,30,23)` dan `(54,40,30)`; TEXT_2 `(205,185,163)` terhadap keduanya 8,53:1 dan 7,48:1 (>= 7).
- Judul "Bengkel" dan label "SALDO" langsung di atas latar (tanpa pelat): piksel latar di persegi itu (aset 800x360, p99 luminans 0,004..0,010) memberi 15,9..17,8:1 (judul) dan 9,2..10,3:1 (label TEXT_2). Percobaan awal QA dengan latar dari tangkapan memberi 1,5..1,9:1 karena menghitung piksel tepi huruf, itu artefak metode, bukan temuan.
- Garis komponen: lihat QA-003 (tombol aktif 8,53..10,27:1; kartu menonjol 6,91:1; kartu biasa/redup 1,14..1,29:1; tombol nonaktif 1,14:1).

### Mutan QA (18, pilihan sendiri; satu perubahan, `run_tests.gd` penuh, `git checkout`/pemulihan sesudahnya; pohon kerja bersih lagi)
Skrip `mutan.py` di scratchpad menulis balik berkas asli dari salinan memori; `git status` sesudah semua mutan: hanya `.claude/`, `shots/qa_iter1/`, dan tes reproduksi QA.
| # | Mutan | Hasil |
|---|---|---|
| M1 | `Aksi.AKTIF if saldo >= harga` -> `>` | TERTANGKAP (10 gagal) |
| M2 | penanda di sepeda hanya untuk PERLU (AUS tak bertanda) | TERTANGKAP (6) |
| M3 | kartu PERLU_BENGKEL tidak menonjol (BIASA) | TERTANGKAP (13) |
| M4 | titik rem x 33 -> 34 di `BENGKEL_SEPEDA_TITIK` | TERTANGKAP (3) |
| M5 | jejak tingkat tampil bila >= 1 (bukan > 1) | TERTANGKAP (3) |
| M6 | `kunci_tombol`: `status != Aksi.AKTIF` (alih-alih `== KURANG`) | **LOLOS** (setara di praktik; QA-005) |
| M7 | lebar minimum tombol 84 -> 80 | TERTANGKAP (14) |
| M8 | tombol nonaktif tetap `disabled = false` | TERTANGKAP (21) |
| M9 | chip tingkat aktif: `dimiliki or jumlah > 1` -> `and` | TERTANGKAP (4) |
| M10 | jarak chip sisi AKHIR 5 -> 0 | TERTANGKAP (2) |
| M11 | catatan ongkos naik bila rusak >= 3 (bukan 2) | TERTANGKAP (3) |
| M12 | kunci penanda PERLU dan AUS tertukar | TERTANGKAP (3) |
| M13 | upgrade yang dijual: `>` -> `>=` level dimiliki | TERTANGKAP (10, dengan SCRIPT ERROR) |
| M14 | kartu upgrade dimiliki tidak redup | TERTANGKAP (4) |
| M15 | fraksi kolom servis 0,48 -> 0,5 | TERTANGKAP (5) |
| M16 | chip harga kartu servis hanya tampil bila AKTIF (hilang saat "Koin kurang") | **LOLOS** (0 gagal; QA-002 Major) |
| M17 | warna teks tombol nonaktif TEXT_2 -> TEXT | TERTANGKAP (5) |
| M18 | status jejak AKTIF = indeks 0 | TERTANGKAP (3) |

### Edge case bengkel (skrip scratchpad `qa_edge*.gd`, `qa_first.gd`)
Saldo = harga (aktif, belanja 84, saldo 0), harga - 1 (nonaktif "Koin kurang"; `pressed.emit()` dua kali: state identik); saldo 0 semua baik (tiga "Koin kurang" + hanya "Hari berikutnya"); saldo 999.999, 12.345.678, 2.147.483.647 di lebar 640 dan 800 (tanpa terpotong, tanpa keluar viewport); semua komponen 0, tidak ada yang rusak, semua dimiliki (hanya satu tombol tampil); ketukan ganda servis dan beli (sekali); lebar game 853, 1000, 1066 (tata letak benar). Gagal: nama upgrade panjang (QA-001). Catatan: pada instansiasi PERTAMA di proses headless dengan `root.size` yang diatur skrip, tinggi `Isi` 616 (viewport awal belum sesuai): artefak skrip QA (diberi pemanasan di tes reproduksi), BUKAN temuan; QA tidak melaporkannya. Back Android = Hari berikutnya, jeda/background, kidal: tidak berubah (tidak ada di diff `hari_main.gd`/`layar_bengkel` tidak menyebut kidal; tes lama hijau).

### NEEDS-MANUAL
- [ ] SETUP_ANDROID 8.18 (10 butir) di vivo V2108 dan A54: terbaca sekilas, chip kondisi tepat, tombol enak ditekan (ditekan = turun 2 px), kartu menonjol vs redup, harga dekat tombol, latar tidak mengganggu (lisensi latar belum tercatat, belum boleh masuk rilis), tiga upgrade tanpa scroll, 60 fps, zona aman notch. Tambahan QA: nilai apakah garis kartu (QA-003) cukup jelas di bawah sinar matahari.
- [ ] Keputusan pemilik: QA-003 (garis kartu < 3:1), D-2 (`max(12, inset)` vs `12 + inset`).

### Tes reproduksi QA
`tests/qa_repro_ui1_teks_panjang.gd` (TIDAK terdaftar di `run_tests.gd`, exit 1 selama QA-001 terbuka): `godot --headless --path . --script res://tests/qa_repro_ui1_teks_panjang.gd`. Hapus atau jadikan tes resmi (`tes_bengkel_tata_c`) saat Dev memperbaiki.

## QA iterasi 2 (Agent 2, independen; agent baru; semua perintah dijalankan sendiri, satu proses Godot sekaligus)

**Verdict: PASS.** Gerbang objektif hijau; QA-001 dan QA-002 (Major) direproduksi sendiri dan VERIFIED; tidak ada Blocker/Major OPEN, FIXED, atau DISPUTED. Temuan: Blocker 0, Major 0; baru 1 Minor (QA-012, DEFERRED) dan 3 Nit (QA-010, 011, 013); lama tetap DEFERRED: 1 Minor (QA-003) dan 3 Nit (QA-007, 008, 009). OPEN turun dari 2 Major (iterasi 1) ke 0 Major; tidak ada temuan yang sama muncul lagi (QA-010 adalah lokasi baru pola QA-006, Nit). Tidak ada eskalasi.

### Gerbang objektif
| Gerbang | Perintah | Hasil |
|---|---|---|
| Impor | `godot --headless --import` | selesai, tanpa ERROR |
| Buka proyek | `godot --headless --path . --quit-after 2` | tanpa ERROR/WARNING |
| Tes | `run_tests.gd > build/tests.log` + `python3 tools/cek_keluaran_tes.py build/tests.log` | **23406 lolos, 0 gagal**; pemeriksa: lolos (0 peringatan) |
| Alat Python | semua 17 `tools/tests_cek/uji_*.py` (satu per satu) | semua exit 0 |
| Save asli | sha256 `~/Library/Application Support/Godot/app_userdata/Kring Kring!/save.json` sebelum, sesudah tes, sesudah 4 probe, sesudah 19 mutan, akhir | `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e` tetap |
| Kebersihan repo | `git status`, `git log main..HEAD`, `git diff main...HEAD --name-status` | branch `feat/ui1-komponen-bengkel`, 22 commit (bukan di `main`), semuanya berformat `tipe: ...` Indonesia + `Claude-Session`; tidak ada `.godot/`, `build/`, APK, keystore; tidak ada berkas dihapus dibandingkan `main`; berkas lama yang diubah hanya `assets/ui/theme.tres`, `scenes/bengkel/bengkel.tscn`, `scripts/config.gd`, `scripts/ui/gaya_hud.gd`, `scripts/ui/layar_bengkel.gd`, `translations/ui.csv` + `.translation`; pohon kerja bersih sesudah mutan (`.claude/` dan `shots/qa_iter2/` saja) |
| Paket | `godot --headless --path . --export-pack "Android" build/kring-uji.pck` | ada: `ui_bengkel_latar_800.png`, `ui_bengkel_papan_alat.png`, `ui_bengkel_sepeda_kecil.png`, `layar_bengkel.gd`, `tampil_bengkel.gd`, `bengkel.scn`; tidak ada: `res://tests`, `res://docs`, `ui_koran_`, `ui_struk`, `ui_foto`, `lencana32`, `sepeda_besar`, `latar_640`, `spike` |

### Verifikasi temuan FIXED
- **QA-001 (VERIFIED).** Reproduksi sendiri dengan skrip `qa2_ekstrem.gd` (scratchpad, headless, pemanasan satu layar dulu karena instansiasi pertama di proses headless punya viewport awal tidak benar: artefak skrip, bukan temuan) di lebar 640/700/800/1066 x saldo 125.480 dan 2.000.000.000 x 7 kasus data: nama 24 huruf biasa, "WWWWWWWWWWWWWWWWWWWWWWWW" (239 piksel), nama beraksen "ÀÉÎÕÜ..." (171), CJK (tanpa glif), deskripsi 48 "W", harga 6 digit, harga 13 digit, harga 2.000.000.000, tiga dan enam tingkat. Hasil: `Isi` tepat x 12 dan lebar penuh (616/676/776/1042), tanpa tumpang tindih, tanpa elemen keluar zona aman, semua tombol >= 42x84, kecuali dua kasus ekstrem (QA-013: harga 2e9 + tiga tingkat di 640 melebarkan Isi 5 piksel) dan CJK (QA-013). Dilihat sebagai tangkapan nyata (`lihat/`: nama 24 huruf + deskripsi 48 di 640 = "Rem Pakem Racin..." dan deskripsi dua baris utuh; "WWWWWWW..." dan deskripsi "W" 2 baris berelipsis, harga "150.000 koin" utuh; nama "Ban Anti-Selip S..." dengan jejak I II III dan harga "12.000 koin"): teks terpotong tetap dikenali dan bermakna (nama berelipsis di tempat yang wajar, harga dan tombol utuh), layar tidak pecah. Mutan QA N14 (jatah deskripsi 1 baris) dan N18 (elipsis diganti `OVERRUN_TRIM_CHAR`) tertangkap oleh tes baru (8 dan 108 gagal). Tes reproduksi QA lama dihapus Dev: penggantinya (`_test_teks_panjang`: 6 kasus x 2 saldo x 3 lebar, memeriksa `Isi` x 12 dan lebar tepat, kolom tetap, tanpa tumpang tindih, tombol, kartu 50/62, tanpa scroll, saldo terbaca, nama satu baris berelipsis, data nyata tanpa elipsis) mencakup kasus yang sama (nama 24, 20, deskripsi 48) dan lebih banyak, dengan kekuatan sama atau lebih. Tidak ada tes dihapus atau di-skip dibandingkan `main`.
- **QA-002 (VERIFIED).** Mutan M16 asli QA iterasi 1 (chip harga servis hanya bila AKTIF) diulang sebagai varian N11 (tombol servis hanya tampil bila AKTIF): tertangkap (3 gagal). Mutan chip harga upgrade dan Dimiliki ditangkap oleh `_test_chip_harga_terlihat` (Dev M16a/b/c; QA tidak mengulang ketiganya, tetapi N11, N15, N16 menyentuh jalur yang sama). Tes memeriksa `is_visible_in_tree()`, ukuran > 0, teks tidak kosong, jarak <= 8 di kiri tombol dan sejajar tegak untuk servis AKTIF/KURANG dan upgrade AKTIF/KURANG di lebar 640 dan 800.
- **QA-004 (VERIFIED).** `SPEC.md` AC-2 diamendemen (hanya latar 800; alasan 640 = potongan tengah 800, lebar maksimum 800; QA iterasi 1 sudah membuktikan 0 piksel beda). Paket memuat hanya `ui_bengkel_latar_800.png`.
- **QA-005 (VERIFIED).** `tes_tampil_bengkel.gd` memeriksa `kunci_tombol(TIDAK_ADA, ...)` = kunci aksi; mutan M6 asli (`status != Aksi.AKTIF`) kini tertangkap (Dev M6: 1 gagal; QA tidak mengulang M6 persis, tetapi memeriksa isi tes di diff).
- **QA-006 (VERIFIED dengan sisa).** `Config.UI_GARIS_PX` dipakai di `tampil_bengkel.gd`, `panggung_sepeda.gd:45`, `gaya_hud.gd` (dua tempat); nilai tetap 1. Sisa `set_border_width_all(1)` di `panggung_sepeda.gd:141` = QA-010. `gaya_hud.gd` `kotak` dan `_kotak_fokus` kini membaca konstanta (nilai sama); AC-4 menyebut diff kosong untuk fungsi lama, perubahan ini permintaan QA-006 dan tampilannya identik (lihat di bawah).
- **DEFERRED pantas:** QA-007 (regex uji, Nit), QA-008 (latent, data hari ini hanya tingkat I, Nit), QA-009 (21:9 di luar jangkauan resmi 800, Nit). Pantas dan tidak naik severity. **QA-003 dinilai ulang: tetap Minor** (alasan terukur di bawah).

### Keanehan yang dilaporkan Dev (31 piksel game, antialias huruf "v" di tombol "Servis")
Diukur sendiri: (a) probe 2340x1080 dijalankan dua kali pada kode yang sama: 11 keadaan, **0 piksel beda** antara dua jalan dan antara jalan QA dan `shots/iter2` Dev: render deterministik, derau dasar 0; (b) `qa_iter2` vs `qa_iter1`: 7 keadaan identik, 4 keadaan (b, e, g, sesudah_servis, tepat yang punya tombol "Servis") beda 281/213/292/199 piksel layar (maks selisih per piksel 203 dari 765), semuanya di kolom game x 330..335 dan 339..343 pada baris tombol "Servis" (y 188..191, 242..245, 296..298), yaitu tepi antialias dua huruf; persegi tombol, kartu, chip, nama identik (JSON probe sama); (c) potongan 3x diperbesar kedua versi dilihat berdampingan: tidak terbedakan. Kesimpulan: **tak berbahaya** (bukan ketidakdeterministikan, bukan regresi tampilan); penyebab mekanisme (label berelipsis memengaruhi posisi subpiksel teks lain) tidak dibuktikan QA dan tidak perlu. Tidak dicatat sebagai temuan.

### Validasi visual (4 ukuran x 11 keadaan = 44 PNG + JSON di `shots/qa_iter2/`)
Semua 44 tangkapan DILIHAT satu per satu (Read PNG): 2340x1080 (lebar 780), 1920x1080 (lebar 640), 2400x1080 (800), 1600x720 (800), keadaan a baru, b ada rusak, c saldo kurang, d sesudah beli, e terpadat, f galat data, g inset aman, sesudah servis, tingkat I, tingkat II, tingkat III dimiliki (iterasi 1 tidak sempat melihat 2400x1080, 1600x720, a-d di 1920x1080, sesudah_servis, tingkat_1; kini semua). Probe di empat ukuran: **0 keadaan tidak sesuai** (Dev klaim 2340 saja; QA mengulang empat). Temuan visual: sesuai kanvas dan angka (header y 11, isi y 46, margin 12, kolom 48% | 8 = 296 | 312 di 640, 363 | 385 di 780, 372 | 396 di 800, kartu servis 50 dan upgrade 62 (72 dengan jejak), chip harga di sebelah tombol, tombol 84x42 dan 140x42, tiga kartu upgrade tanpa scroll di semua lebar); di lebar 640 teks status "Perlu servis" turun di bawah kotak kondisi dan deskripsi upgrade dua baris, keduanya terbaca; di 800 semua sebaris; galat data menampilkan panel WARN dengan servis tetap jalan; inset aman menggeser margin kiri 36 dan kanan 24 (tombol hari mengikuti); chip kondisi "! Ban", "! Rem", "Rantai aus" tepat di titik sepeda tanpa menutupi kartu; sepeda baik bersih; kartu PERLU SERVIS berbingkai oranye menonjol, Baik/Dimiliki redup dengan chip bercentang; jejak I | II | III dengan centang pada yang dimiliki dan aksen pada yang dijual; tombol nonaktif rata, diarsir, "Koin kurang". Pengamatan kecil (Nit yang sudah tercatat QA-009 dan iterasi 1): potongan krem latar (kalender) mengintip di celah antar kartu upgrade dan latar di bawah kartu upgrade terakhir kosong; tidak mengganggu teks.
**Layar hasil, jeda, HUD tidak berubah vs `main`:** worktree `main` (`b99f5a9`, sudah dihapus) dan branch, `probe_hud_rute_jendela.gd` 1920x1080 dijalankan dua kali masing-masing. `hud_hasil_meleset_lewat`, `hud_hasil_semua`, `hud_jeda_sakelar`, `hud_kidal`, `hud_progres_campuran`, `hud_tenggat_hampir`, `hud_tenggat_lewat`: 0 piksel beda di semua pasangan. `hud_awal`, `hud_bantu_abu`, `hud_radar` beda antar jalan di sisi yang sama (derau animasi dunia, polanya sama dengan iterasi 1; `hud_awal`: main1 vs main2 beda penuh layar), dan masing-masing punya pasangan main-vs-branch yang identik (`hud_awal` main1=br1; `hud_bantu_abu` dan `hud_radar` main2=br2): bukan regresi. Koran, tutorial, banner tidak ada di diff.

### Kontras terukur QA iterasi 2 (dari tangkapan 2340x1080 dan JSON probe; skrip scratchpad)
- Teks: tidak ada yang < 7:1 (terburuk 7,48:1 "Koin kurang" pada sisi terang arsir, 7,79:1 chip WARN, lalu 8,28 sampai 15,9:1; sama dengan iterasi 1, QA tidak menemukan teks baru yang rendah).
- Garis komponen (tepi vs 3 px di luar, pita kiri, 12 keadaan): tombol aktif 8,53:1; "Hari berikutnya" 11,92:1; kartu menonjol (garis WARN) 6,91:1; **kartu Baik/Dimiliki/biasa 1,08..1,29:1; tombol nonaktif 1,14:1** (angka sama persis dengan iterasi 1 dan D-1 Dev).
- **QA-003 dinilai ulang: tetap Minor, DEFERRED**, bukan Major. Alasan terukur: (1) semua kontrol yang bisa DITEKAN lolos jauh (>= 8,53:1; satu-satunya kontrol yang dikenali dari bingkainya); (2) tombol nonaktif memang dikecualikan WCAG 1.4.11 dan dibedakan tanpa warna lewat tiga petunjuk bersama (rata tanpa tinggi, arsir diagonal, teks berganti "Koin kurang" 7,48..8,53:1); (3) kartu adalah wadah, bukan kontrol: informasi yang dibawanya (perlu servis, baik, dimiliki) dinyatakan berulang oleh teks status, chip "Baik"/"Dimiliki" bercentang, kotak kondisi, dan garis WARN 6,91:1 pada yang menonjol, jadi garis redup 1,14..1,29:1 tidak membawa informasi unik; (4) desain redup adalah keputusan pemilik lewat kanvas (README redesain bagian 3). Tetap penyimpangan harfiah AC-9 "garis komponen >= 3:1": rekomendasi QA agar orchestrator/pemilik memutuskan dengan SPEC AC-9 dipersempit ke "kontrol aktif" atau garis kartu disorot (mengubah aset) setelah uji HP di bawah sinar matahari. Tidak memblokir PASS.

### Mutan QA iterasi 2 (19 mutan nyata pilihan sendiri, BERBEDA dari 18 mutan iterasi 1 dan mutan Dev; satu perubahan, `run_tests.gd` penuh, berkas dipulihkan sesudahnya dari salinan memori; `git status` bersih sesudahnya)
| # | Mutan | Hasil |
|---|---|---|
| N1 | `_label_potong`: `clip_text = false` | LOLOS, **setara** (dengan `OVERRUN_TRIM_ELLIPSIS` lebar minimum label sudah tidak mengikuti teks, tes lebar tetap hijau; Dev juga mem-bisect dan menyatakan `clip_text` bukan penyebab); bukan lubang tes |
| N2 | catatan ongkos format `%.2f` -> `%.1f` | TERTANGKAP (3) |
| N3 | warna nama upgrade Dimiliki tertukar (TEXT/TEXT_2) | TERTANGKAP (1) |
| N4 | tombol "Hari berikutnya" naik 2 px dari margin bawah | TERTANGKAP (13) |
| N5 | pad kanan kartu upgrade Dimiliki dihapus | **LOLOS** (QA-011, Nit) |
| N6 | `rect_chip`: jepit y mulai 2 | TERTANGKAP (1) |
| N7 | angka romawi hanya sampai II (`<` bukan `<=`) | TERTANGKAP (3) |
| N8 | lebar kolom upgrade tanpa jarak 8 | TERTANGKAP (58) |
| N9 | belanja servis tidak dicatat | TERTANGKAP (2) |
| N10 | teks status servis selalu tampil | TERTANGKAP (3) |
| N11 | tombol Servis hanya tampil saat AKTIF (hilang saat "Koin kurang"; varian M16 iterasi 1) | TERTANGKAP (3) |
| N12 | tinggi tombol 42 -> 40 | TERTANGKAP (71) |
| N13 | chip jejak MENUNGGU bergaya aktif | TERTANGKAP (1) |
| N14 | jatah baris deskripsi 2 -> 1 | TERTANGKAP (8) |
| N15 | panel galat data selalu tersembunyi | TERTANGKAP (3) |
| N16 | belanja upgrade tidak dicatat | TERTANGKAP (1) |
| N17 | margin kanan memakai inset kiri | TERTANGKAP (28) |
| N18 | elipsis nama -> `OVERRUN_TRIM_CHAR` | TERTANGKAP (108) |
| N19 | pad kanan kartu servis penuh dihapus | **LOLOS** (QA-011, Nit) |
Ringkasan: 19 mutan, 16 tertangkap, 1 setara (N1), 2 lolos nyata (N5 dan N19, satu akar: margin kanan kartu bercip tidak diuji; Nit). Tidak ada mutan lolos yang menyangkut logika kritis (pemilihan keadaan, tombol nonaktif, harga, belanja, penjagaan elipsis). Syarat AC-13 (QA >= 10 pilihan sendiri) terpenuhi; yang lolos dicatat (QA-011) dan tidak memblokir.

### Kepatuhan AC (perubahan sejak iterasi 1)
AC-1, 3, 4, 5, 7, 8, 10, 11, 12: tetap BUKTI (tabel gerbang dan tangkapan di atas; AC-4: layar hasil/jeda/HUD identik vs `main`, tabel di atas). AC-2: BUKTI dengan amandemen QA-004 (SPEC diperbarui). AC-6: BUKTI penuh sekarang (teks panjang: nama berelipsis, deskripsi dibatasi, diuji; QA-001 VERIFIED). AC-9: BUKTI dengan dua catatan: kontras garis kartu (QA-003, Minor, keputusan pemilik) dan elipsis data nyata pada inset >= 44 di lebar 640 (QA-012, Minor); ukuran tombol dan tanpa tumpang tindih diperiksa di empat ukuran dan puluhan kombinasi ekstrem (56 kasus data, 28 sapuan harga, 20 kombinasi inset). AC-13: BUKTI (Dev >= 30, QA 19 baru; satu lolos nyata dicatat sebagai Nit). U-1 sampai U-5 tetap BUKTI.

### NEEDS-MANUAL
- [ ] SETUP_ANDROID 8.18 (10 butir) di vivo V2108 dan A54 (sekarang tidak ada perangkat tersambung): terbaca sekilas, chip kondisi tepat, tombol enak ditekan (ditekan = turun 2 px), kartu menonjol vs redup (QA-003: apakah garis kartu cukup jelas di bawah sinar matahari), harga dekat tombol, latar tidak mengganggu (lisensi latar belum tercatat, belum boleh masuk rilis), tiga upgrade tanpa scroll, 60 fps, zona aman notch (QA-012: bila ada perangkat 16:9 berinset >= 44 piksel game, periksa nama dan deskripsi upgrade tidak berelipsis).
- [ ] Keputusan pemilik: QA-003 / D-1 (garis kartu < 3:1), D-2 (`max(12, inset)` vs `12 + inset`), QA-013 (batas panjang nama dan deskripsi di `DataToko` bila upgrade baru ditambah).

### Tes reproduksi QA
Tidak ada yang tertunda: `tests/qa_repro_ui1_teks_panjang.gd` diserap `tes_bengkel_tata_c._test_teks_panjang` dan dihapus Dev (terverifikasi). Skrip ekstrem QA iterasi 2 (`qa2_ekstrem.gd`, `qa2_harga.gd`, `qa2_inset.gd`, `qa2_lihat.gd`) ada di scratchpad sesi QA, bukan di repo (data ekstrem di luar data nyata; hasilnya dicatat di QA-012 dan QA-013).
