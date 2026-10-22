# Loop Log — 20261022-fase5d-sisi-dekat
Scope: Run 5D, Fase 5 (dimajukan dari Fase 8): pelanggan sisi dekat mulai hari 3 (8-9 dari 25), tembok dekat dihapus jadi halaman terbuka, rumah dekat mundur 0,5 ubin dan didesain ulang dengan teras menjorok  ·  Branch: feat/fase5d-sisi-dekat  ·  Mulai: 2026-10-22  ·  Godot: 4.7.2

## Status: IN_PROGRESS   (iterasi saat ini: 1/2, bagian A, B, dan C selesai; QA iterasi 1: PASS dengan 5 Minor dan 4 Nit OPEN, menunggu keputusan orchestrator)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 1 (QA) | gerbang diulang QA sendiri; AC-1..AC-19 ditelusuri; banding RouteBuilder `main` vs HEAD, 1000 hari, grid zona, ukur piksel Python, 4 probe, 20 mutan | import 0 / 19281 lolos 0 gagal / pemeriksa lolos; `--quit-after 2` bersih; 14 uji_*.py exit 0; paket 1.773.380 byte bersih; save tetap | **PASS** (0 Blocker, 0 Major; 5 Minor, 4 Nit OPEN) | 9 | 0 (iterasi pertama) |
| 1 (C) | AC-14..AC-19: paket diperiksa dan dimuat dari luar repo (47 cek), `tes_export` diperluas (aset 5D, pemindai rujukan, dokumen), dokumen AC-17 (GDD, ROADMAP 4b, ROUTE_DESIGN, BALANCING, ART_DIRECTION, AGENTS, SETUP_ANDROID 8.16, dst.), gerbang akhir, 15 mutan C (total 59) | import 0 / 19281 lolos 0 gagal / pemeriksa lolos; `--quit-after 2` bersih; 14 uji_*.py exit 0; 4 probe lama 0 tidak sesuai; paket 47 cek; save tetap | menunggu orchestrator/QA | - | - |
| 1 (B) | AC-7..AC-13: data pelanggan dekat (34 dari 36 rumah), validasi segmen, `RouteBuilder` dari hari (8/9 dekat sejak hari 3), zona dekat cermin seberang, kotak surat dua sisi, terlipat teras dekat, bantu/radar/progres, tip hari 3, probe empat ukuran; 30 mutan | import 0 / 19180 lolos 0 gagal / pemeriksa lolos; 14 uji_*.py exit 0; save tetap | menunggu orchestrator | - | - |
| 1 (A) | AC-1..AC-6: baseline, fase3 dapat dihasilkan ulang + uji, rumah dekat baru (teras menjorok, tanpa kotak surat), tembok dilepas, mundur 0,5, kotak penutup sprite nyata; AC-6 tercapai TANPA pudar (P-3 tidak dipakai); 14 mutan | import 0 / 18933 lolos 0 gagal / pemeriksa lolos; 14 uji_*.py exit 0; save tetap | menunggu orchestrator (titik henti D-1) | - | - |

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|
| QA-001 | 1 | Minor | `scenes/ui/hud_rute.tscn` (panel bawah) x rumah dekat; SPEC AC-13 (hanya diukur) | Butir (ii) Dev: rumah dekat tertutup panel HUD bawah. Pengukuran Dev (sepeda tiap 2 ubin) melewatkan jendela sempit: dari tangkapan `shots/qa1/2340x1080_dekat_teras_bidik.png` dan `_teras_kena.png` lantai TERAS pelanggan dekat (sasaran sah penuh + tip) sebagian tertutup panel KECEPATAN/KORAN saat sepeda hampir sejajar rumah. Hitungan QA (sepeda lateral 0,5, panel 211..380 dan 401..517 px, y >= 293/313 px viewport 780x360): pusat teras tertutup panel kecepatan bila jarak maju sepeda-ke-teras D <= 0,66 ubin, kaki tiang kotak surat pelanggan bila D < ~0,4 (sekitar 0,1 detik pada 3 u/d), tidak tertutup untuk D 0,66..5 (jangkauan lempar). Bukan kegagalan AC (HUD di luar scope), tetapi lemparan terakhir sebelum rumah dekat lewat bisa membidik di bawah panel. | OPEN (usul DEFERRED; NEEDS-MANUAL 8.16 butir 8) | - | - |
| QA-002 | 1 | Minor | `scripts/entities/rute_main.gd:_koran_dinilai`, `scripts/systems/mission_manager.gd:_terapkan_petunjuk` (tidak diubah) | Butir (iii) Dev dinilai: `Lemparan.kotak_pelanggan`/`maju_rumah_ubin` tidak membawa sisi, jadi lemparan TEPAT ke pelanggan DEKAT di jendela petunjuk sebuah langkah juga memicu petunjuk kucing. Bukti QA (`qa_ukur/qa_petunjuk.gd`, 100 rute hari 3..102, langkah 1): 100 dari 100 pelanggan dekat di jendela memberi PETUNJUK, sama dengan seberang (92 dari 92). Teks petunjuk (`MISI_P1_KUCING_PETUNJUK`) adalah celoteh pelanggan ('Tadi ada kucing lewat ke arah warung') tanpa sisi, jadi tidak salah secara cerita; efeknya petunjuk lebih mudah didapat (kandidat jendela bertambah sekitar sepertiga) dan kucing tampil 22 bukan 14 ubin lebih awal. Titik kucing tetap di rumah seberang (tes 600 hari lulus). Bukan bug; keputusan desain pemilik (batasi ke seberang butuh mengubah `MissionManager`/`Lemparan`, dilarang run ini). | OPEN (usul DEFERRED, keputusan pemilik) | - | - |
| QA-003 | 1 | Nit | `per_tengah_02@14`, `per_tengah_03@30` (anjing dekat) | Butir (i) Dev: kotak surat abu-abu (bukan sasaran) rumah `per_tengah_02@12` dan `per_tengah_03@28` berdampingan dengan anjing di halaman. Tangkapan `2340x1080_dekat_bantu_dekat_kena.png` dilihat: anjing berdiri di rumput di samping tiang kotak surat abu-abu, sprite tidak saling menimpa, anjing tidak tertutup atap (di belakang tepi atap, terbaca). Hanya hiasan; preseden seberang (`per_tengah_04`). Rekomendasi Dev (geser anjing @16/@32) tidak perlu sebelum uji HP. | OPEN (usul DEFERRED) | - | - |
| QA-004 | 1 | Minor | `scripts/systems/route_builder.gd:periksa_rute` (kuota maks), tes `tes_sisi_dekat_b.gd` | Mutan QA Q13 (`dekat > KUOTA_MAKS` jadi `> KUOTA_MAKS + 1`): `run_tests.gd` penuh 19281/0 LOLOS. Batas atas kuota (10 pelanggan dekat ditolak) tidak dijaga; Dev hanya mengetes 7 (di bawah min) dan mematikan seluruh cek (M-B25). Saran: tambah kasus rute mutan dengan 10 pelanggan dekat ditolak dan 9 dan 8 sah. | OPEN | - | - |
| QA-005 | 1 | Minor | `scripts/entities/rumah_daur_rute.gd:_lepas_terlipat` | Mutan QA Q12 (`sprite.reparent(self, false)` dihapus saat terlipat dekat dilepas): `run_tests.gd` penuh LOLOS. Tanpa baris itu sprite terlipat dari kolam yang pernah dipakai rumah dekat tetap anak pembungkus yang tersembunyi, jadi terlipat rumah seberang yang memakainya ulang tidak tampil. Tidak ada tes daur ulang kolam terlipat dekat -> seberang. Kode produksi benar; hanya celah tes (pola 5A: kolam dipakai ulang). | OPEN | - | - |
| QA-006 | 1 | Nit | `tests/tes_sisi_dekat_b.gd` (determinisme hari >= 3) | Mutan QA Q2 (urutan dua `_cocokkan` dekat/seberang tertukar) LOLOS penuh: hari >= 3 hanya dites sah dan sebaran 8/9, tidak ada golden identitas rute hari 3 (hari 1-2 punya golden 60 seed). Perubahan konsumsi RNG diam-diam di masa depan menggeser semua rute hari >= 3 tanpa alarm. | OPEN | - | - |
| QA-007 | 1 | Nit | `scenes/ui/panel_tip_sisi_dekat.tscn`, `translations/ui.csv` | Mutan QA Q17 (teks tip 3x lebih panjang di CSV): hanya tertangkap oleh cek CSV = `.translation` terkompilasi, bukan oleh tata letak; panjang teks terpanjang tidak dites (SPEC AC-12 menyebut batas panjang bila ada). Tip 2 baris pada 150 px terbaca di tangkapan; terjemahan Inggris kelak bisa lebih panjang. | OPEN | - | - |
| QA-008 | 1 | Minor | `docs/BALANCING.md` bagian 5 (butir 'Kotak surat dipindah ke halaman': 'kotak surat dekat tetap tanpa sprite'; butir 'Zona dari data rute': 'semua rumah dekat di distrik perumahan' = `BUKAN_PELANGGAN`), `docs/ROUTE_DESIGN.md` baris 85 ('kavling rumah termasuk tembok belakang rumah dekat') | Teks usang sesudah Run 5D (rule `docs`: dokumen akurat; butir riwayat boleh, tetapi tidak diberi tanda 'diganti'): kotak surat dekat kini bersprite, rumah dekat bisa pelanggan sejak hari 3, tembok tidak ada. Tidak berpengaruh ke kode. | OPEN | - | - |
| QA-009 | 1 | Nit | `tests/ukur_sisi_dekat.gd` vs ukur QA | Informasi: halaman dekat tertimpa sprite rumah (SPEC hanya 'dicatat', tanpa target). Ukur QA (`qa_ukur/ukur6.py`: 100 rute nyata, kedua varian, semua rumah dalam 14 ubin, tanpa urutan Y-sort) menghasilkan maksimum 59,9% (Dev 26-33%, tetangga +-4 ubin); lantai teras tertimpa tetangga 24,4% (sama). Tidak ada tangkapan yang menunjukkan halaman tak terbaca. Tidak diselidiki lebih jauh. | OPEN (informasi) | - | - |

## Baseline (orchestrator, `main` 53408cf, 2026-10-22; `main` lalu maju ke f42e22e = PR #55, hanya dokumen)
- `godot --headless --import`: 0 baris ERROR/WARNING. `godot --headless --path . --quit-after 2`: 0 baris ERROR/WARNING.
- `run_tests.gd`: **19022 lolos, 0 gagal**; `tools/cek_keluaran_tes.py`: lolos (0 peringatan).
- 13 `tools/tests_cek/uji_*.py` exit 0: uji_aset_gelombang1, uji_aset_kucing, uji_aset_lampu_pohon, uji_aset_pasang_5b, uji_aset_pasang_gelombang1, uji_aset_simpang, uji_bangun_frames, uji_pemeriksa, uji_sintesis_{kondisi,lempar,misi,rute,sepeda}.
- sha256 `user://save.json` asli (`~/Library/Application Support/Godot/app_userdata/Kring Kring!/save.json`): `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e`.
- HP: `adb devices` kosong.

## NEEDS-MANUAL (uji di HP)
Lihat SPEC bagian NEEDS-MANUAL dan SETUP_ANDROID 8.16.
- [ ] (QA, iterasi 1) 8.16 butir 8: lemparan ke teras dan kotak surat pelanggan dekat saat sepeda hampir sejajar rumah (jarak maju < 1 ubin) dengan panel kecepatan/koran di bawahnya: apakah garis bidik dan teras terbaca (QA-001).
- [ ] (QA, iterasi 1) 8.16 butir 6 dan 7: hari 3 tip terbaca dan 8-9 pelanggan dekat adil; hari 4 dan 5 tanpa tip. Save lama di hari >= 3 tidak melihat tip (tidak ada bidang save, P-6): terima atau tidak.
- [ ] (QA, iterasi 1) petunjuk misi kucing dari lemparan tepat ke pelanggan dekat (QA-002): terasa aneh atau tidak.

## Keputusan & catatan
- Putusan K-1..K-5, P-1..P-6, D-1..D-7: SPEC.
- Bagian 6j LOOP-DEV-QA sudah di `main` (PR #55, f42e22e); run ini hanya menyentuh tabel 6g.
- Izin pemilik (perintah run): sesudah QA PASS orchestrator push dan membuka PR; merge oleh pemilik. HP: vivo V2108 boleh `adb install -r` sesudah QA PASS bila tersambung.

## Iterasi 1, bagian A (Dev)

### Baseline ulang (AC-1, Dev, branch `feat/fase5d-sisi-dekat` = d532b72 sebelum perubahan, 2026-10-22)
- sha256 `user://save.json` asli: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e` (sama dengan orchestrator).
- `godot --headless --import`: 0 baris ERROR/WARNING. `godot --headless --path . --quit-after 2`: 0 baris ERROR/WARNING.
- `run_tests.gd`: **19022 lolos, 0 gagal**; `tools/cek_keluaran_tes.py`: lolos (0 peringatan).
- 13 `tools/tests_cek/uji_*.py` exit 0 (daftar sama dengan baseline orchestrator).

### AC-2 Reproduksi fase3.py (commit ed9b504, sebelum desain ulang)
- `fase3.py` (tanpa argumen) dibandingkan per piksel dengan `assets/`: 22 dari 24 PNG fase3 identik; **beda**: `house_perumahan_dekat_pelana_lintang_{bukan,pelanggan}.png` 40 piksel masing-masing (satu garis diagonal atap: nada gelap lama vs nada dasar baru) dan `obs_mobil_garasi_sheet.png` 9 piksel (baris y 57, tepi bumper/lampu belakang tiga frame). JSON semua byte-identik. Mock `docs/design/environment/fase3_perumahan.png` 104, `fase3_dua_sisi.png` 108, `fase3_mobil_garasi.png` 36 piksel beda (x2 dari beda yang sama).
- Engine SEBELUM `mm()` (86864d1^, `git archive` ke folder sementara) menghasilkan beda yang SAMA di mesin ini, jadi `assets/` lama berasal dari pustaka numpy/pillow lain (PR #27/#34) dan tidak bisa dihasilkan ulang. **Keputusan (SPEC AC-2): versi skrip jadi sumber kebenaran**; tiga PNG aset dan tiga mock disalin ulang dari `--salin` (PNG yang pikselnya sama dikembalikan ke HEAD supaya diff hanya berkas yang benar-benar berubah).
- `fase3.py`: `ENV_ART_SALIN_KE` (akar tujuan `--salin`) untuk uji. Tidak ada `@`/`np.linalg.norm` vektor di fase3 (sudah `mm()`/`panjang()`).
- Uji baru `tools/tests_cek/uji_aset_fase3.py` (masuk `.github/workflows/tes.yml`): deterministik (dua jalan), isi `assets/sprites/{houses/perumahan,obstacles,props}` fase3 = keluaran (PNG piksel, JSON byte), `--salin` hanya daftar fase3 + mock, mock docs = keluaran x2, impor Lossless, kontrol satu byte/piksel.
- Tes lama terdampak: `run_tests.gd` tetap 19022. **Catatan jujur:** `uji_aset_pasang_5b.py` (golden byte 5B memuat dua PNG rumah dekat lintang) MERAH di commit ed9b504 karena tidak saya jalankan ulang di commit itu; diperbaiki di 2c799cb (rumah dekat diserahkan ke `uji_aset_fase3.py`, lihat bawah).

### AC-3 Desain ulang rumah dekat (commit 2c799cb)
- `fase3.py house_near_teras` (koordinat lokal = tengah tapak gambar): badan rumah mundur di belakang tapak (x -30..40 unit = lateral dunia 4,06..6,25), dinding 30, atap per jenis (limasan 52; **pelana lintang dibuat perisai di ujung jalan**, segitiga pelana hanya di belakang; pelana sejajar 50), **teras menjorok ke jalan** di ujung maju kecil (sisi +y yang terlihat kamera): lantai x -58..-30, y 14..44, tiga tiang, atap sandar rendah 27 -> 21, lampu, keset dan pot (pelanggan), pintu samping ke teras. Aturan bentuk: setiap titik rumah lateral L tinggi H memenuhi L - H >= ~2,8 ubin (sinar kamera dari zona kotak surat dan trotoar dekat tidak kena rumah).
- **Keputusan Dev:** tetap dua varian per jenis (pelanggan berwarna, bukan kusam abu-abu, seperti seberang), keduanya TANPA kotak surat; dipakai `_bukan` di bagian A (rute belum punya pelanggan dekat), `_pelanggan` untuk bagian B.
- JSON aset: `teras_ubin` [-1,8125; -1,375; 0,875; 0,9375] dan `penutup_ubin` + `penutup_tinggi_ubin` (AABB primitif nyata tanpa teras dan antena) relatif titik pijak gambar. Titik pijak baru: limasan (110,127), lintang (110,126), sejajar (110,122).
- Iterasi desain (dilihat sendiri): teras pertama x0 -62 -> oracle mencatat pemain di tepi trotoar (lateral 2,0) tertimpa 10 piksel (0,54%) atap teras; teras dipendekkan ke -58 -> 0%.
- Mock: `docs/design/environment/fase3_rumah_dekat_banding.png` (atas lama, bawah baru, 3 jenis x pelanggan/bukan, x2) dan `fase3_layar_dekat_5d.png` (tata letak game: aspal 2, trotoar 1, rumah dekat di lateral 5,0, kotak surat oranye/abu-abu cermin seberang di 2,125; x2). Layar lama `fase3_dua_sisi.png` tetap memakai `house_near_v` (mock lama, tidak dipakai game).
- `--salin` hanya yang dipakai (daftar sama: 6 rumah dekat, nama tetap). `uji_aset_fase3.py` diperbarui: tujuh mock, geometri JSON literal, catatan "TANPA kotak surat".
- `uji_aset_pasang_5b.py`: 12 berkas golden `house_perumahan_dekat_*` dilewati (dicek tepat 12) dan dijaga `uji_aset_fase3.py`; golden lain tetap byte-identik.

### AC-4 Lepas tembok, mundur 0,5, halaman terbuka (commit db8d9dd)
- `RUTE_RUMAH_DEKAT_MUNDUR_UBIN` 1,25 -> **0,5**. `RUTE_TEMBOK_X_UBIN`, `RUTE_TEMBOK_MODUL_UBIN`, `RUTE_TEMBOK_VARIAN`, `SPRITE_TEMBOK`, `SPRITE_TEMBOK_GESER_PX` dibuang (konstanta FNV-1a tetap: dipakai `UbinKhusus`).
- **Keputusan Dev:** `TembokDekat` dan `VarianTembok` (+ `.uid`) DIHAPUS (bukan dilepas), lima `house_tembok_*` (+ `.import`, JSON) dihapus dari `assets/`; `gelombang1/render.py --salin` tidak lagi menyalin tembok (tetap dirender ke build/ dan papan). `RumahDaurRute` tanpa kolam tembok.
- Halaman terbuka: kavling dekat = ubin rumput yang sudah ada (tidak ada aset baru). Jalan setapak tidak ditambah (tidak ada ubin/sprite jalan setapak dekat yang dipasang; usulan untuk dinilai di HP).
- Simpang: `SegmenRute.kavling_rumah` disederhanakan = tapak logika ∪ tapak gambar (rentang tembok sampai pos+3 dibuang). Data simpang sembilan segmen tetap sah; `tes_simpang` hijau.
- `tes_tembok.gd` dan `ukur_tembok.gd` DIHAPUS (alasan: semua yang dijaganya — varian FNV, modul, tiang, letak tembok, jendela daur tembok — tidak ada lagi); diganti `tests/tes_sisi_dekat.gd` (+ `ukur_sisi_dekat.gd`). Cek yang masih berlaku dipindah ke tes baru: 1000 lemparan acak = checksum sebelum run 5B (geometri logika tidak berubah), tapak logika literal, pemindai rujukan (kini: TIDAK boleh ada nama sprite tembok, kelas tembok, atau berkas).

### AC-5 Penutup dan Y-sort
- `PenutupPemain.tapak_rumah_gambar(sisi, maju, jenis = "")`: rumah dekat = kotak sprite nyata per jenis dari `Config.RUTE_RUMAH_DEKAT_PENUTUP_{LATERAL,MAJU,LEBAR,PANJANG,TINGGI}_UBIN` (= JSON, dijaga tes) relatif pusat gambar (tapak logika + 0,5); tanpa jenis = gabungan tiga jenis (kavling validasi). `tinggi_rumah_gambar` baru; `dari_rumah_gambar` memakai keduanya. Seberang tidak berubah.
- `PenerapPenutup.objek_untuk(gambar)` (getter untuk tes). Rumah dekat tetap anak `Objek` (Y-sort bersama sepeda, kotak surat, rintangan, dekor); `KoranUdara` digambar sesudah `Objek` (dites).

### AC-6 Ukur oracle piksel (`tests/ukur_sisi_dekat.gd`, dipakai `tes_sisi_dekat.gd` dan probe)
Oracle independen: proyeksi iso ditulis ulang, PNG + JSON nyata, rumah dekat di lateral 5,0 (literal), kotak surat dekat cermin seberang (2,125; kavling + 1,75), zona dirasterisasi sendiri, Y-sort (y sama = di atas). Enam sprite x (sendiri + 12 tetangga di +-4 ubin) x 2 kavling; pemain = gabungan semua frame berkendara, lateral langkah 0,125, maju kavling -3..+5.

| Ukuran | Sasaran SPEC | Sebelum (orchestrator, sprite lama, mundur 0,5) | Desain baru tanpa pudar | Sesudah pudar |
|---|---|---|---|---|
| Badan/sprite kotak surat dekat tertimpa | 0% | 44,3% | **0%** | P-3 tidak dipakai |
| Zona kotak surat dekat (cermin / lama) | <= 5% | 68,5% / 58,0% | **2,58% / <= 1,77%** | - |
| Pemain di lajur dekat | 0% | 0% | **0%** | - |
| Pemain di trotoar dekat | 0% sesudah pudar | 27,3% | **0%** (posisi tumpang tanpa tanda kotak: 0) | - |
| Koran terbang | - | - | 0% (KoranUdara di atas Objek) | - |
| Halaman dekat tertimpa rumah | (dicatat) | median terlihat 0,47 | 26,2% (probe, kavling 8) / <= 32,6% (tes, dua kavling) | - |
| Lantai teras tertimpa rumah tetangga | (dicatat) | - | <= 24,4% (tetangga di -4 ubin) | - |

- **P-3 (pudar) TIDAK dipakai**: semua sasaran tercapai oleh desain. Angka jadi tes regresi di `tes_sisi_dekat.gd` (batas atas = angka terukur; kontrol: rumah digambar 1,25 ubin lebih dekat ke jalan terukur menutupi kotak surat dan zona; pemain buatan di halaman terukur tertimpa).
- Catatan untuk bagian B (bukan temuan bagian A): (1) teras dekat ada di BELAKANG titik pijak rumah menurut Y-sort, jadi koran terlipat di teras dekat akan tertimpa sprite rumahnya sendiri bila digambar sebagai anak `Objek` biasa; zona teras dekat perlu bagian lantai yang terlihat (lantai di bawah atap teras dan 24% bisa tertimpa tetangga). (2) `MedanKoran.tertutup_titik` masih memakai tapak logika rumah dekat (3..6, tinggi 2) — tidak diubah di bagian A.

### Tes lama yang angkanya berubah (D-5)
- `tes_rute_scene.gd`: pusat gambar rumah dekat 5,75 -> **5,0** (mundur 0,5); anak `Objek` tanpa `jumlah_tembok()`.
- `tes_dekor.gd` P-4: tapak gambar rumah dekat maju 8 `(4,25; 7,5) 3x3` -> **gabungan sprite nyata (3,906; 7,594) 3,1125 x 2,8125**; kotak limasan (3,906; 7,594) 3,06875 x 2,8125 tinggi **1,625** (dulu 2,0); rute nyata: dekat = pusat logika + 0,5 + kotak per jenis (dulu logika + 1,25); "pusat gambar = pusat kotak" -> "pusat gambar di dalam kotak" (kotak tidak simetris karena toren/jemuran). Sapuan "tidak pernah menutupi pemain |lateral| <= 2" tetap 0.
- `tes_simpang.gd`: simpang dekat pos 8 vs rumah dekat pos 4: **ditolak -> sah** (tembok sampai 7 dilepas; pita 6,5 hanya bersentuhan dengan kavling 6,5); kasus pemotong baru pos 7 ditolak; kavling dekat pos 10 berakhir 13,0 -> **12,5**; `_cek_tembok_rumah_100` kini hanya tapak gambar (per jenis).
- `tes_export.gd`: lima PNG tembok + dua skrip keluar dari daftar wajib ikut paket dan masuk daftar tidak boleh ada; PNG 5B dicek 17 -> **12**.
- `tes_ubin.gd`, `tes_dekor.gd`: komentar saja (nama kelas tembok dihapus dari teks karena pemindai baru).
- Python: `uji_aset_pasang_5b.py` (TEMBOK kosong, 53 -> **48** PNG impor, kontrol piksel memakai tong sampah, 12 golden rumah dekat diserahkan), `uji_aset_pasang_gelombang1.py` (`houses/perumahan` dari render.py kosong).
- Total tes: 19022 -> **18933** lolos (tes tembok dihapus, tes sisi dekat ditambah).

### Mutan nyata bagian A (14; satu perubahan, tes penuh atau uji Python terkait, `git checkout`, `git status` bersih tiap kali; skrip `mutan.py` di scratchpad Dev)
| ID | Berkas | Perubahan satu baris | Hasil | Gagal yang menangkap (contoh) |
|---|---|---|---|---|
| M-A1 | `assets/sprites/obstacles/obs_mobil_garasi_sheet.png` | PNG dikembalikan ke versi lama (9 piksel beda) | TERTANGKAP (uji_aset_fase3 131/1) | piksel-identik dengan keluaran fase3.py |
| M-A2 | `tools/env_art/fase3.py` | `ANJING_SIZE` + acak (fase3 tidak deterministik) | TERTANGKAP (uji_aset_fase3, 8 gagal) | layar_fase3/dua_sisi: dua kali jalan = piksel sama |
| M-A3 | `scripts/config.gd` | `RUTE_RUMAH_DEKAT_MUNDUR_UBIN` 0,5 -> 1,25 (mundur lama kembali) | TERTANGKAP (14 gagal) | tes_rute_scene posisi rumah dekat; tes_sisi_dekat konstanta/geometri |
| M-A4 | `scripts/systems/penutup_pemain.gd` | tinggi kotak dekat = `RUTE_RUMAH_TINGGI_UBIN` (kotak penutup bukan sprite nyata) | TERTANGKAP (7 gagal) | kotak penutup gambar limasan tinggi 1,625 (dapat 2,0) |
| M-A5 | `scripts/systems/penutup_pemain.gd` | pusat kotak gambar dekat tanpa `+ MUNDUR` | TERTANGKAP (10 gagal) | kotak penutup gambar x 3,906 (dapat 3,406) |
| M-A6 | `scripts/entities/rumah_daur_rute.gd` | rumah dekat tidak didaftarkan ke penerap | TERTANGKAP (6 gagal) | rumah digambar = didaftarkan ke penerap |
| M-A7 | `tools/env_art/fase3.py` | teras x0 -58 -> -66 tanpa `--salin` | TERTANGKAP (uji_aset_fase3 134/14) | assets/ = keluaran fase3.py |
| M-A8 | `tools/env_art/fase3.py` | teras x0 -58 -> -66 + `--salin` | TERTANGKAP (11 gagal) | Config pijak = JSON; tes_sisi_dekat literal |
| M-A9 | `tools/env_art/fase3.py` | kotak surat terpanggang lagi di rumah dekat pelanggan + `--salin` | TERTANGKAP (7 gagal) | sprite kotak surat dekat 0% tertimpa (terburuk 0,1096); pijak/penutup JSON |
| M-A10 | `tools/env_art/gelombang1/render.py` | `house_tembok_polos` kembali ke `PASANG_5B` (aset tembok ikut tersalin) | TERTANGKAP (uji_aset_pasang_gelombang1 564/1) | --salin tepat daftar D-1 di houses/perumahan |
| M-A11 | `house_perumahan_dekat_limasan_bukan.png.import` | `compress/mode=0` -> 2 (bukan Lossless) | TERTANGKAP (uji_aset_fase3 147/1) | impor Lossless |
| M-A12 | `scripts/systems/segmen_rute.gd` | `kavling_rumah` dekat digabung rentang tembok lama (sampai pos+3) | TERTANGKAP (4 gagal) | kavling 7,5..10,5; simpang dekat pos 8 sah |
| M-A13 | `scripts/config.gd` | `RUTE_RUMAH_DEKAT_PENUTUP_TINGGI_UBIN` -> 2,0 | TERTANGKAP (8 gagal) | Config penutup = JSON |
| M-A14 | `scripts/config.gd` | pijak rumah dekat limasan 110 -> 114 | TERTANGKAP (7 gagal) | Config pijak = JSON aset |

Semua 14 tertangkap, `git status` bersih sesudah tiap mutan (12 lewat skrip + M-A1, M-A2 manual). Catatan lingkungan: ada proses `godot --headless --script res://tests/run_tests.gd` lain (PID 26665) yang menggantung sejak ~1 hari 5 jam dari sesi lama di folder repo ini; tidak dimatikan (bukan milik sesi ini), tidak mengganggu (tidak menulis apa pun selama run).

### Gerbang bagian A (Dev, HEAD bagian A)
- `godot --headless --import`: 0 ERROR/WARNING. `godot --headless --path . --quit-after 2`: 0 ERROR/WARNING.
- `run_tests.gd`: **18933 lolos, 0 gagal**; `tools/cek_keluaran_tes.py`: lolos (0 peringatan).
- 14 `tools/tests_cek/uji_*.py` exit 0 (13 lama + `uji_aset_fase3.py` baru, di CI).
- sha256 save asli sebelum dan sesudah semua tes, probe, dan mutan: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e` (tidak berubah).
- Probe `tests/probe_sisi_dekat_jendela.gd` 2340x1080 non-headless: exit 0, **0 keadaan tidak sesuai**, 0 baris ERROR/WARNING; mencetak "ukur AC-6: kotak surat dekat 0,00%, zona kotak surat 2,58%, halaman tertimpa 26,24%, teras tertimpa tetangga 24,40%, pemain lajur 0,00%, trotoar 0,00%"; lempar ke kotak surat dekat rute buatan: KOTAK_SURAT, CENTANG. Probe lain (`probe_simpang_jendela` diperbarui tanpa tembok) dijalankan di bagian C.

### Tangkapan bagian A (`docs/loop/20261022-fase5d-sisi-dekat/shots/iter1/`, 2340x1080, dilihat Dev)
- `2340x1080_dekat_halaman_{limasan,pelana_lintang,pelana_sejajar}.png`: rute nyata, sepeda di jalur dekat, tiga jenis rumah dekat baru, halaman terbuka tanpa tembok, teras menjorok terbaca dari samping.
- `2340x1080_dekat_halaman_trotoar_{limasan,pelana_lintang,pelana_sejajar}.png`: sepeda di tepi trotoar dekat (lateral 2,0) sejajar teras: rumah opak, pemain tidak tertimpa.
- `2340x1080_dekat_jalur_dekat.png`, `2340x1080_dekat_trotoar_dekat.png`: rute buatan dengan pelanggan dekat (kotak surat oranye placeholder di zona jalan uji).
- `2340x1080_dekat_sasaran_{bidik,terbang,kena}.png`: bidik, koran terbang, dan kena kotak surat dekat (sprite kotak surat utuh di depan rumah).
- `2340x1080_dekat_kidal.png`; tangkapan dekor dan ubin lama tetap dibuat probe (`dekor_*`, `lajur_*`, `ubin_*`). Pudar P-3 tidak dipakai, jadi tidak ada tangkapan pudar.
- Empat ukuran (1920x1080, 2400x1080, 1600x720) menyusul di bagian B/C (AC-13).

### Commit bagian A
ed9b504 (AC-2), 2c799cb (AC-3), db8d9dd (AC-4..AC-6), dan commit probe + tangkapan + LOG ini.

## Iterasi 1, bagian B (Dev)

Commit bagian B: 381fa18 (kode, data, tes), f97cbd4 (probe dan tangkapan), dan commit LOG + DATA_SCHEMA + mock gelombang1 ini. `ThrowSolver`, `BikeMotion`, `Tabrakan`, `TenggatRute`, angka skor, `MissionManager`, `RencanaMisi`, `BikeCondition`, `Economy`, `DataSave`, `SaveManager`: `git diff main` kosong.

### Keputusan Dev (dicatat, bukan putusan pemilik)
- **Kandidat pelanggan dekat = 34 dari 36 rumah dekat** (`pelanggan_boleh: true`). Dua rumah bukan kandidat: `per_tengah_02@12` dan `per_tengah_03@28`, karena zona kotak surat dekat (lateral 1,75..2,75, maju pos+1,25..2,5) beririsan dengan anjing dekat (lateral 2,5..3,0) di @14 dan @30 (oracle literal di `TesSisiDekatB`). Validasi rintangan-vs-zona berlaku untuk rumah dekat yang `pelanggan_boleh`; dekor dan pita simpang diperiksa untuk SEMUA rumah dekat. **Catatan untuk review (bukan BLOCKED, tidak mengubah rintangan atau rumah):** kotak surat abu-abu dua rumah itu tumpang visual dengan anjing yang duduk di halamannya. Preseden: seberang `per_tengah_04` anjing @8 beririsan dengan zona kotak surat pelanggan seberang @6 sejak run 3B. **Rekomendasi (satu):** bila terasa mengganggu di HP, geser anjing dekat `per_tengah_02` @14 -> @16 dan `per_tengah_03` @30 -> @32 (mengubah rintangan = keputusan pemilik, di luar D-5).
- **Zona dekat di rute** (`ZonaSasaran.zona_rumah_dekat_rute`, cermin seberang): kotak surat `[1,75; 1,25; 1,0; 1,25]` (+ inti `[2,0; 1,625; 0,5; 0,5]`), halaman `[2,0; -0,5; 1,90625; 3,0]` (dari tepi trotoar sampai badan rumah = pijak 5,0 + penutup JSON -1,09375), teras = `teras_ubin` JSON digeser ke pijak gambar (lateral 3,1875..4,0625, maju kavling -0,375..+0,5625). Konstanta `Config.RUTE_DEKAT_*` (satu baris, literal; tes membandingkan dengan JSON aset). Zona dekat JALAN UJI (`zona_rumah_dekat`, `JALAN_UJI_DEKAT_*`) tidak berubah (D-6).
- **Kotak surat dekat** di lateral +2,125, maju kavling + 1,75 (cermin sprite seberang -2,125). Oranye pelanggan, abu-abu bukan, semua rumah dekat (D-3), termasuk hari 1-2 (semua abu-abu). `SpriteRumah.nama_rumah` kini memakai varian `_pelanggan` untuk rumah dekat terpilih (sprite A).
- **Koran terlipat di teras dekat (catatan A):** teras dekat ada di BELAKANG pijak sprite rumah menurut Y-sort. Solusi tetap di induk Y-sort yang sama: `RumahDaurRute` membungkus sprite terlipat rumah DEKAT dalam `Node2D` pembungkus yang diletakkan `RUTE_RUMAH_DEKAT_URUT_TERLIPAT_PX` = 1 px di depan pijak rumah; sprite ada di titik tengah teras sebagai anak pembungkus; kolam dipakai ulang; seberang tidak berubah. Bukti piksel (`TesSisiDekatScene._test_terlipat_dekat`, oracle PNG + JSON + iso ditulis ulang): 0% piksel terlipat tertimpa sprite rumah dengan urutan game; kontrol (diletakkan langsung di titik teras) tertimpa >50%.
- **`MedanKoran.tertutup_titik`** kini memakai `PenutupPemain.dari_rumah_gambar` (seberang = tapak logika, tak berubah; dekat = kotak sprite nyata). Bukti: 143 dari 143 titik seberang identik, tertutup sisi dekat 196 -> 104 dari 506 lemparan acak (kotak logika lama 3..6 x tinggi 2 menandai halaman/teras dekat "tertutup" padahal tidak tertimpa sprite; banding per lemparan di bawah).
- **Tip hari 3:** `TipSisiDekat` (logika murni: hari = 3, 6 detik waktu game beku saat jeda, sekali per `RuteMain`, tidak diisi ulang "Main lagi") + `PanelTipSisiDekat` (scene `scenes/ui/panel_tip_sisi_dekat.tscn`, kolom kiri x 26 y 88 di bawah kartu misi, lebar 150, tanpa kontrol penerima sentuhan, inset aman dibaca seperti HUD). Kunci `RUTE_TIP_LABEL` ("TIP") dan `RUTE_TIP_SISI_DEKAT` ("Mulai hari ini pelanggan ada di kedua sisi jalan") di `ui.csv` (awalan `RUTE_` agar pemeriksa awalan tidak diubah). Tanpa bidang save; `DataSave` diff kosong.
- **Petunjuk misi dari lemparan tepat (catatan, tidak diubah):** `MissionManager` menghitung lemparan tepat ke kotak surat pelanggan di jendela rumah; lemparan tepat ke pelanggan dekat dalam jendela itu juga memberi petunjuk (hanya sisi seberang punya titik kucing). `MissionManager`/`RencanaMisi` tidak boleh berubah; dibiarkan sebagai bonus presisi, ditandai untuk keputusan pemilik.
- **Lingkungan tes headless:** headless mengembalikan ukuran jendela root sesudah tiap frame (viewport 640x640); tes scene baru mengatur `root.size` lagi sesudah `await` supaya langkah sinkron berjalan di 780x360. Tes lama tidak diubah.
- **Perbaikan bagian A yang tidak tertangkap:** `uji_aset_gelombang1.py` merah di HEAD bagian A (3 mock `komposisi_siang/sore_x3` dan `sisi_dekat_siang_x3` memakai sprite rumah dekat yang diganti A). Diperbaiki: `python3 tools/env_art/gelombang1/render.py --mock`, hanya tiga PNG yang berubah-dan-diuji yang dikomit (enam PNG lain ikut berubah byte oleh pustaka mesin ini dan dikembalikan).
- **P-3 pudar, tembok:** tidak dipakai / sudah dihapus di bagian A; mutan terkait ada di tabel A (M-A3, M-A12) dan tidak diulang.

### AC-7 data dan validasi
- 9 segmen nyata sah, 0 galat; `sisi_pelanggan` semuanya `dua_sisi`; `DISTRIK_SATU_SISI` dihapus. Validasi baru `SegmenRute`: tag sesuai isi (`_periksa_sisi_pelanggan`), `rintangan_menimpa_zona_dekat` (anjing diam dan lintasan mobil vs zona kotak surat dan teras rumah dekat kandidat). Aturan dekor (kotak surat + teras) dan pita simpang (zona rumah) yang lama otomatis memakai geometri zona baru; data nyata lolos tanpa memindah dekor (tidak ada dekor dipindah).
- Tes negatif satu per satu + positif di `TesSisiDekatB._test_validasi_segmen` (anjing @12 ditolak, @11 sah, rumah bukan kandidat sah, anjing seberang sah, mobil dekat, pohon, lampu, simpang @9 ditolak, pohon @8 dan simpang seberang sah, enam kasus tag). Jalan masuk garasi (lateral <= 0) tidak pernah menjangkau zona dekat: dites untuk pos 3..40, bukan cabang validasi.

### AC-8 RouteBuilder dari hari, ukur hari 3..102 (`tests/ukur_hari_dekat.gd`)
| Ukuran | Nilai |
|---|---|
| Rute sah | 100 dari 100 (gagal 0) |
| Jumlah dekat per rute | **8: 54 rute, 9: 46 rute** (100% di {8, 9}); 25 pelanggan tiap rute, semua rumah `pelanggan_boleh` |
| Persentase dekat | 8/25 = 32%, 9/25 = 36% (rata-rata 34,6%) |
| Celah gabungan (dua sisi, urut maju) | min 2,0 / median 10,0 / **maks 20,0** ubin (batas 20), tidak ada celah 0 |
| Celah per sisi | seberang 4,0 / 16,0 / 24,0; dekat 16,0 / 28,0 / 44,0 (maks seberang 24 > 20 wajar: batas berlaku pada celah gabungan) |
| Tenggat | 89 .. 92 detik (panjang rute 232 .. 240 ubin; rumus tidak berubah) |
- Hari 1-2: rute identik `main`. Golden 60 seed dihitung di `main` (53408cf) oleh Python dari dump pustaka `main` (identitas: panjang, koran, tenggat, segmen, pelanggan, pemberi tip, rintangan, titik misi, dekor, rumah id/maju/jenis) dan ditulis literal di `TesSisiDekatB.GOLDEN_HARI1`: 60 dari 60 cocok; `bangun` tanpa hari = hari 1 = hari 2. Banding pustaka `main` vs HEAD bagian B per bidang (60 seed): satu-satunya beda adalah bidang `pelanggan_boleh` rumah DEKAT (1678 entri); segmen, rumah (id, maju, sisi, jenis), pelanggan, pemberi tip, objek, titik misi, dekor, simpang, panjang, koran, tenggat, galat identik. Pustaka `main` dan HEAD bagian A identik.
- RNG hari >= 3: kuota (`randi_range(8, 9)`) diundi dari RNG rute SESUDAH susunan segmen; dua `_cocokkan` (dekat, lalu seberang) memakai RNG yang sama; tanpa RNG di luar seed. Hari tidak ikut seed (hari 3 dan hari 50 dengan seed sama = rute sama). `periksa_rute(rute)` memakai `Rute.hari`: pelanggan dekat hanya hari >= 3, hanya rumah `pelanggan_boleh`, kuota 8-9, celah gabungan <= 20.
- `HariMain` meneruskan hari lewat `RuteMain.atur_hari` SEBELUM scene masuk pohon (tes dengan save hari 2, 3, 4 di folder sementara: `rute.hari()`, seed `SeedHari.rute(hari)`, 0 / 8-9 pelanggan dekat, tip hanya hari 3). `rute.tscn` sendiri = hari 1. "Main lagi" mempertahankan hari.

### AC-9, AC-10, AC-11, AC-12 (tes scene `tes_sisi_dekat_scene.gd`, nilai harapan literal atau dari JSON/PNG)
- Kotak surat: tiap rumah di jendela punya tepat satu kotak (oranye pelanggan / abu-abu bukan) di lateral -2,125 (seberang) atau +2,125 (dekat), maju kavling + 1,75, sprite rumah varian sesuai; hari 1 semua dekat abu-abu; node kolam dipakai ulang.
- Prediksi = hasil: swipe NYATA (event sentuh -> `TouchRouter` -> garis bidik -> lepas -> koran terbang -> mendarat) ke kotak surat, teras, halaman, dan meleset di sisi dekat, tangan normal dan KIDAL (zona swipe kiri): titik mendarat diklasifikasikan oracle independen (literal + `teras_ubin`/`penutup_ubin` JSON) = hasil game = prediksi garis bidik = antaran (SAH_PENUH / SAH_PENUH / SAH_SETENGAH / TIDAK_SAH), elips SAH hanya bila sah. Selain itu grid 18.818 titik (1/16 ubin) pelanggan + bukan: 0 beda dari oracle (`_test_zona_oracle_grid`).
- Skor/koin sama aturan: ANTAR sisi dekat `skor 100` (= `SKOR_SASARAN_DASAR`, combo 1,0, santai) dan koin >= ongkos 15; pemberi tip dekat: teras +5 tip, kotak surat 0 tip (SkorRute tidak punya input sisi).
- Mode bantu: untuk tiap pelanggan dekat, sepeda mundur 0..8 ubin (langkah 0,5) dari kotak suratnya: SEMUA pilihan bantu dekat (>50) = pelanggan dekat terdekat di depan (oracle literal pos+1,875), mendarat di zona kotak surat (selalu kena); tiap pelanggan dekat terjangkau dari suatu titik; sesudah pelanggan dekat terakhir = tanpa sasaran; sisi seberang tidak pernah menyasar zona dekat; tap bantu nyata: koran bantu, KOTAK_SURAT, bukan tepat.
- Radar (strip DEKAT = kanan; kidal tidak menukar), `jangkau`, jenis TIP/PELANGGAN/BUKAN (abu-abu hanya mode bantu), terantar keluar: dibandingkan oracle literal (jarak = pos + 1,875 - sepeda, 0..30, jangkau <= 5) untuk 2 x 2 x 122 keadaan; progres 25 kotak dua sisi (BERIKUTNYA, TERLEWAT < -3, TERKIRIM) = oracle; `jumlah_terkirim` menghitung dekat.
- Tip: hanya hari 3 (tidak 1, 2, 4, 50), teks terjemahan tampil, panel tidak menelan sentuhan (tap bantu tetap melempar saat tip tampil), di dalam viewport dan tidak menimpa panel progres/tombol jeda, beku saat jeda (60 x 1 detik jeda: sisa tidak berubah), hilang sesudah 6 detik, "Main lagi" tidak memunculkan lagi, kidal dan inset aman.

### Bot bantu (scene nyata, AC-11): 25/25 terkirim, 0 lewat tenggat di 22 rute
Bot: mode bantu, tanpa stick (santai 3,0 u/d), satu tap per pelanggan yang belum dibidik (sisi dekat dulu), dt 1/30 (hari 1-2 = dua rute seed hari 1 dan 2; 20 seed hari 3..22).
| Hari | Dekat | Selesai (detik) | Tenggat | Sisa |
|---|---|---|---|---|
| 1 | 0 | 80,0 | 92 | 12,0 |
| 2 | 0 | 78,6 | 91 | 12,4 |
| 3 | 8 | 77,2 | 89 | 11,8 |
| 4 | 9 | 78,6 | 91 | 12,4 |
| 5 | 8 | 78,6 | 91 | 12,4 |
| 6 | 9 | 78,6 | 91 | 12,4 |
| 7 | 9 | 78,6 | 91 | 12,4 |
| 8 | 8 | 77,2 | 89 | 11,8 |
| 9 | 8 | 77,2 | 89 | 11,8 |
| 10 | 9 | 78,6 | 91 | 12,4 |
| 11 | 8 | 79,9 | 92 | 12,1 |
| 12 | 8 | 77,2 | 89 | 11,8 |
| 13 | 8 | 79,9 | 92 | 12,1 |
| 14 | 8 | 78,6 | 91 | 12,4 |
| 15 | 9 | 78,6 | 91 | 12,4 |
| 16 | 9 | 78,6 | 91 | 12,4 |
| 17 | 9 | 77,2 | 89 | 11,8 |
| 18 | 9 | 78,6 | 91 | 12,4 |
| 19 | 8 | 78,6 | 91 | 12,4 |
| 20 | 9 | 77,2 | 89 | 11,8 |
| 21 | 9 | 77,2 | 89 | 11,8 |
| 22 | 8 | 78,6 | 91 | 12,4 |
Sisa tenggat 11,8..12,4 detik di semua seed (dua sisi tidak memperlambat bot karena kecepatan santai tetap dan kecepatan bantu tidak bergantung jumlah pelanggan; bot mode bantu tidak melemparkan koran lebih dari 25 dari 30).

### Rumah dekat di bawah panel HUD bawah (diukur, HUD TIDAK diubah; probe 2340x1080, juga 1600x720: angka sama)
Sepeda tiap 2 ubin sepanjang rute (114 sampel), lateral 0,5, tangan normal dan kidal (angka sama):
- kotak pembatas sprite rumah dekat menyentuh panel kecepatan/stamina atau panel koran di **100%** sampel (rumah dekat memang selalu lewat di bawah panel bawah, bukan akibat run ini);
- titik kotak surat dekat (mana pun, termasuk yang sudah lewat) di dalam panel bawah di 52% sampel;
- **kotak surat PELANGGAN dekat dalam jangkauan lempar (0..5 ubin di depan) di dalam panel bawah di 0% sampel**: sasaran yang bisa dilempar tidak pernah tertutup panel. Rumah dekat tampak (di tangkapan 2340, 1920, 1600) tertutup sebagian panel di bawah sepeda; dinilai di HP (SETUP_ANDROID 8.16 butir 8).

### Tes lama yang angkanya berubah (D-5, satu per satu, alasan)
1. `tes_rute.gd`: `BOLEH` dipisah, `BOLEH_DEKAT` baru (literal), total `pelanggan_boleh` 37 -> 37 seberang + 34 dekat = 71, tag nyata `seberang` -> `dua_sisi`, mutan data `sisi_pelanggan_dekat` dan `rumah_pelanggan_dekat` kini ditolak dengan "tidak sesuai isi" (aturan satu sisi dihapus, P-4), mutan `periksa_rute` memakai pesan baru "bukan rumah yang boleh untuk hari".
2. `tes_rute_scene.gd`: `nama_rumah(dekat terpilih)` = `_pelanggan` (dulu selalu `_bukan`); titik "di balik rumah dekat" (2,5 -> 2,9) karena kotak tertutup rumah dekat = sprite nyata (teras dan atap tidak lagi menutup lateral 2,5).
3. `tes_kotak_surat.gd`: rumah dekat kini punya kotak surat (lateral +2,125); batas simpul kolam 20 -> maks rumah di jendela + 4 (kedua sisi).
4. `tes_sisi_dekat.gd`: golden 1000 lemparan dipecah per sisi. Seberang `[494, 5508, 143, 809075394]` = nilai sebelum run 5B (tidak berubah); dekat `[506, 5629, 104, 648143202]` baru (HEAD A: tertutup 196, checksum 1274964814). Banding per lemparan HEAD A vs HEAD B (1000 lemparan, skrip `dump_lempar.gd`): 45 beda hasil/zona, **semuanya di sisi dekat (0 di seberang)**; 92 beda tertutup, 0 di seberang. Total checksum 992255826 -> 1166943782.
5. `tes_dekor.gd`: (a) golden rute 60 seed dihitung ulang oleh skrip; bukti: dengan `pelanggan_boleh` rumah dekat ditopeng false, sidik 60 seed = nilai lama persis (kontrol skrip), jadi beda hanya bidang itu; (b) "tapak (2,25; 10,75) menimpa teras dekat" diganti: teras dekat baru di lateral 3,19..4,06 tidak terjangkau dekor (lateral <= 2,75), ditambah tes tapak hipotetis dan batas kotak surat 2,75; "pohon dekat @11 menimpa teras" -> sah (tapak maju berakhir 11,25 = awal kotak surat).
6. `tes_simpang.gd`: golden rute 60 seed (uraian dengan dekor) dihitung ulang, bukti kontrol topeng sama.
- `run_tests.gd`: dua tes baru didaftarkan. Total tes: 18933 -> **19180** lolos (+247), 0 gagal.

### Mutan nyata bagian B (30; satu perubahan, runner = tes bagian B (82 cek) / tes scene baru (122 cek) / `run_tests.gd` penuh, `git checkout`, `git status` bersih tiap kali; skrip `mutan_b.py` di scratchpad Dev)
| ID | Berkas | Perubahan satu baris | Hasil | Gagal yang menangkap (contoh) |
|---|---|---|---|---|
| M-B1 | `route_builder.gd` | hari mulai `>=` jadi `>` | TERTANGKAP (5) | hari mulai pelanggan dekat = 3 (2 tidak, 3 ya) |
| M-B2 | `config.gd` | kuota min 8 -> 7 | TERTANGKAP (2) | sebaran { 8: 39, 9: 37, 7: 24 } != golden |
| M-B3 | `config.gd` | kuota maks 9 -> 10 | TERTANGKAP (2) | sebaran dengan 10 |
| M-B4 | `config.gd` | `RUTE_DEKAT_HARI_MULAI` 3 -> 2 (pelanggan dekat di hari 2) | TERTANGKAP (6) | hari 1 = hari 2 untuk seed sama (0 dari 60) |
| M-B5 | `route_builder.gd` | RNG hari 1-2 bergeser (`+ rng.randi() * 0` di jalur lama) | TERTANGKAP (1) | 60 rute tanpa hari: identitas = golden main (0 cocok) |
| M-B6 | `route_builder.gd` | celah gabungan tidak diperiksa di pemilih (batas 1000) | TERTANGKAP (2) | 100 hari semuanya sah (gagal 6, ditolak `periksa_rute`) |
| M-B7 | `route_builder.gd` | kandidat dekat tanpa `pelanggan_boleh` | TERTANGKAP (6, galat skrip) | 100 hari semuanya sah (gagal 100) |
| M-B8 | `config.gd` | kotak surat dekat lateral +2,125 -> -2,125 (sisi salah) | TERTANGKAP (2) | tiap rumah punya kotak surat di lateral dekat +2,125 |
| M-B9 | `zona_sasaran.gd` | teras dekat dari geometri lama (`JALAN_UJI_DEKAT_TERAS_UBIN`) | TERTANGKAP (3) | teras dekat dari geometri teras menjorok |
| M-B10 | `zona_sasaran.gd` | prioritas halaman dan teras tertukar | TERTANGKAP (2) | klasifikasi grid: 180 beda dari oracle |
| M-B11 | `zona_sasaran.gd` | skor dekat beda (zona kotak surat dekat berjenis HALAMAN) | TERTANGKAP (8) | kotak surat dekat = cermin seberang |
| M-B12 | `bantu_lempar.gd` | bantu menyasar sisi seberang untuk tap dekat | TERTANGKAP (24) | sasaran bantu dekat = pelanggan dekat terdekat |
| M-B13 | `radar_rute.gd` | radar tanpa rumah dekat | TERTANGKAP (2) | radar = oracle literal |
| M-B14 | `progres_rute.gd` | `jumlah_terkirim` hanya seberang | TERTANGKAP (22) | jumlah terkirim menghitung pelanggan dekat |
| M-B15 | `tip_sisi_dekat.gd` | tip di hari >= 3 (hari lain) | TERTANGKAP (5) | hari tip hanya 3 |
| M-B16 | `tip_sisi_dekat.gd` | tip tidak tampil di hari 3 (kunci kosong) | TERTANGKAP (8) | kunci teks dan lama 6 detik hanya di hari 3 |
| M-B17 | `config.gd` | mundur 0,5 -> 1,25 (mundur lama kembali) | TERTANGKAP (2) | teras dekat dari geometri teras menjorok |
| M-B18 | `medan_koran.gd` | kotak penutup titik bukan sprite nyata (`dari_rumah`) | TERTANGKAP (1; run_tests penuh) | sisi dekat [506, 5629, 196, ...] != nilai baru |
| M-B19 | `segmen_rute.gd` | cabang teras validasi rintangan dilepas | TERTANGKAP (1) | lintasan mobil garasi dekat @10 menimpa teras |
| M-B20 | `segmen_rute.gd` | validasi rintangan berlaku untuk bukan kandidat juga | TERTANGKAP (9) | 9 segmen nyata sah (per_tengah_02 anjing menimpa) |
| M-B21 | `segmen_rute.gd` | cabang tag `seberang` dilepas | TERTANGKAP (1) | seberang padahal ada rumah dekat yang boleh |
| M-B22 | `config.gd` | urut Y-sort terlipat +1 -> -1 px | TERTANGKAP (3) | pembungkus di pijak rumah + (0; 1) px |
| M-B23 | `hari_main.gd` | `atur_hari` tidak dipanggil | TERTANGKAP (6) | save hari 2: rute.hari() = 2 |
| M-B24 | `rute_main.gd` | tip memakai dt waktu dinding (tidak beku saat jeda) | TERTANGKAP (1) | jeda 60 detik: tip beku (sisa 4,9 = 5,9) |
| M-B25 | `route_builder.gd` | cek kuota 8-9 di `periksa_rute` dimatikan | TERTANGKAP (2) | mutan: 7 pelanggan dekat ditolak |
| M-B26 | `sprite_rumah.gd` | rumah dekat selalu varian `_bukan` | TERTANGKAP (1) | sprite rumah bukan varian pelanggan |
| M-B27 | `rumah_daur_rute.gd` | kotak surat oranye hanya seberang | TERTANGKAP (2) | tiap rumah punya kotak surat sesuai status |
| M-B28 | `config.gd` | halaman dekat 1,90625 -> 1,0 lebar (geometri halaman lama) | TERTANGKAP (4) | halaman dekat sampai badan rumah |
| M-B29 | `segmen_rute.gd` | `_periksa_sisi_pelanggan` tidak dipanggil | TERTANGKAP (4) | dua_sisi tanpa rumah dekat yang boleh ditolak |
| M-B30 | `route_builder.gd` | kuota dekat tetap 8 (tidak diundi) | TERTANGKAP (1) | sebaran { 8: 100 } != golden |
Total mutan Dev: 14 (A) + 30 (B) = **44** (target >= 30 terpenuhi). Mutan "validasi tumpang tiap cabang dilepas": rintangan (M-B19, M-B20), tag (M-B21, M-B29); dekor dan pita simpang adalah aturan lama yang dijaga `tes_dekor`/`tes_simpang` (M-A12 untuk kavling simpang). Butir AC-19 yang tidak berlaku di bagian B: pudar P-3 (tidak dipakai), tembok masih dipasang (dihapus di A, M-A3), aset tembok tersalin (M-A10), `.import` bukan Lossless (M-A11), fase3 tidak deterministik (M-A2). 

### Gerbang bagian B (Dev, HEAD sesudah commit LOG)
- `godot --headless --import`: 0 ERROR/WARNING. `godot --headless --path . --quit-after 2`: 0 ERROR/WARNING.
- `run_tests.gd`: **19180 lolos, 0 gagal**; `tools/cek_keluaran_tes.py`: lolos (0 peringatan).
- 14 `tools/tests_cek/uji_*.py` exit 0 (setelah mock gelombang1 diperbarui).
- sha256 save asli sebelum dan sesudah tes, probe, dan mutan: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e` (tidak berubah).
- Probe `tests/probe_sisi_dekat_jendela.gd` 2340x1080, 1920x1080, 2400x1080, 1600x720: exit 0, **0 keadaan tidak sesuai** di keempat ukuran, 0 baris ERROR/WARNING.

### Tangkapan bagian B (`docs/loop/20261022-fase5d-sisi-dekat/shots/iter1/`, `<ukuran>_dekat_<keadaan>.png`, dilihat Dev)
Keadaan baru: `hari3_tip` (tip di kolom kiri di bawah kartu misi, tidak menutupi kontrol), `jalur_dekat`/`trotoar_dekat` (kotak surat oranye/abu-abu dekat di tepi trotoar), `sasaran_{bidik,terbang,kena}`, `teras_*`, `halaman_*`, `meleset_*` (swipe nyata; kena = centang + "+15" di kotak surat dekat), `terlipat_dekat` (koran terlipat di teras dekat, sepeda 5 ubin di belakang rumah), `bantu_dekat_{terbang,kena,tanpa_sasaran}`, `radar_dekat` (strip kanan, penanda pelanggan dekat), `hari2_tanpa_dekat` (kotak surat dekat semua abu-abu, tanpa tip), `kidal`. Catatan dari tangkapan: rumah dekat di bawah sepeda sebagian tertutup panel HUD bawah (diukur di atas); tip tetap tampil di tangkapan lempar karena belum 6 detik waktu game.

## Iterasi 1, bagian C (Dev)

Commit bagian C: e610f9f (tes paket, cek paket dari luar repo), a90ebf5 (dokumen AC-17), commit tes dokumen + LICENSES + skrip mutan C, dan commit LOG ini. `ThrowSolver`, `BikeMotion`, `Tabrakan`, `TenggatRute`, `MissionManager`, `RencanaMisi`, `BikeCondition`, `Economy`, `DataSave`, `SaveManager`: `git diff main` kosong (diperiksa lagi di bagian C); `scripts/config.gd` tidak mengubah angka skor, combo, koin, atau tenggat (baris tambahan hanya `RUTE_DEKAT_*`, `RUTE_RUMAH_DEKAT_*`, `TIP_SISI_DEKAT_*`, `RUTE_DEKAT_*`, dan penghapusan `RUTE_TEMBOK_*`/`SPRITE_TEMBOK*`).

### AC-14 Paket
- `godot --headless --path . --export-pack "Android" build/kring-uji.pck`: exit 0, 0 baris ERROR/WARNING, **1.773.380 byte (1,77 MB)**, 682 berkas (697 di 5C; 5 PNG tembok x tiga berkas dilepas dan berkas baru 5D ditambah).
- Dimuat dari folder di luar repo (`<scratchpad>/paket5d`) dengan `godot --headless --main-pack <repo>/build/kring-uji.pck --script cek_paket_5d.gd` (salinan di `docs/loop/20261022-fase5d-sisi-dekat/dev_ukur/cek_paket_5d.gd`): **47 cek lolos, 0 gagal**, 0 ERROR/WARNING. Isi diperiksa: tidak ada `res://tests/`, `docs/`, `tools/`, `build/`, spike, `cek_render`, `warna_bayangan`, dan **tidak ada berkas dengan nama tembok**; 6 rumah dekat + 6 seberang (PNG dimuat, ukuran = `size` JSON, `teras_ubin`/`penutup_ubin`/`penutup_tinggi_ubin` ada), kedua kotak surat dimuat, kunci `RUTE_TIP_LABEL` dan `RUTE_TIP_SISI_DEKAT` diterjemahkan dari paket, `PemuatRute.muat_folder()` 9 segmen tanpa galat, 34 rumah dekat `pelanggan_boleh`, semua segmen `dua_sisi`; `RouteBuilder.bangun` dari paket: hari 1 dan 2 = 0 dekat, hari 3 = 8, hari 4 = 9, hari 10 = 9 (25 pelanggan, sah); `rute.tscn` dan `panel_tip_sisi_dekat.tscn` dimuat dan dibuat.
- `tests/tes_export.gd` diperluas: `JALUR_WAJIB_IKUT_5D` (rumah dekat PNG/.import/JSON, kotak surat, panel tip, kunci terjemahan, skrip pelanggan dekat) ikut `_pelanggaran_preset` (ada di repo dan tidak dikecualikan filter); `_test_aset_5d_ikut_paket` (impor Lossless, JSON = PNG, folder rumah tepat 12 PNG, tidak ada nama berkas tembok di `assets/` selain graybox spike yang dikecualikan preset, kunci tip tepat satu di `ui.csv`, 9 segmen `dua_sisi` dan 34 rumah dekat `pelanggan_boleh` dihitung dari JSON); `_test_rujukan_5d_tak_dipasang` (pemindai rujukan ke `house_*`/`prop_kotak_surat_*` yang tidak dipasang atau bernama tembok, dengan lima contoh buruk sintetis dan kontrol nama yang dipasang); `_test_dokumen_5d` (SETUP_ANDROID 8.16 dengan 11 butir dan lembar hasil, catatan 8.13, README, AGENTS.md, GDD, ROADMAP). `tes_export` sekarang 625 cek (runner terpisah).

### AC-17 Dokumen (commit a90ebf5 dan sesudahnya)
GDD 4.2 dan 9.1 (pelanggan dekat mulai hari 3, 8 atau 9 dari 25) dan baris keputusan terbuka "Cara menampilkan rumah di sisi dekat" (ditandai diganti); ROADMAP 4b (baris tampilan rumah dekat: keputusan 2026-10-22 menggantikan tembok, riwayat 2026-10-17 tetap, status Run 5D); ROUTE_DESIGN 1, 3, 8; BALANCING 5 (zona dekat di rute), 6b (pelanggan per rute), 10 (catatan perubahan); DATA_SCHEMA 3 (catatan tembok di pita simpang; contoh dari bagian B); ART_DIRECTION 6.4 (paragraf "Rumah dekat Run 5D", tembok ditandai tidak terpasang), keputusan terbuka dan Changelog; TECH_PLAN (spike diganti); `tools/env_art/README.md`; AGENTS.md (peta repo, perintah, tanpa `TembokDekat`/`VarianTembok`); `.cursor/rules/00-project-core.mdc` dan `content-data.mdc`; `docs/README.md`; `assets/LICENSES.md`; LOOP-DEV-QA hanya tabel 6g (baris 5D = dikerjakan, menunggu QA dan uji HP; Bagian 6j tidak disentuh); SETUP_ANDROID 8.16 (11 butir + lembar hasil; 8.13 ditandai tembok tidak berlaku). `DEV_PHASES.md`, `CHANGELOG.md`, `.release-please-manifest.json`: tidak diubah.

### AC-15, AC-16, AC-18 Gerbang akhir bagian C (HEAD sebelum commit LOG)
- `godot --headless --import`: 0 ERROR/WARNING. `godot --headless --path . --quit-after 2`: 0 ERROR/WARNING.
- `run_tests.gd`: **19281 lolos, 0 gagal** (19180 sesudah bagian B + 86 cek paket/pemindai/dokumen 5D di `tes_export` + 15 cek dokumen); `tools/cek_keluaran_tes.py`: lolos (0 peringatan). Satu putaran sempat merah (tes pemindai tembok di `tes_sisi_dekat` menandai teks `TembokDekat` yang saya tulis polos di `tes_export`); diperbaiki dengan penyambungan string, putaran penuh diulang hijau.
- 14 `tools/tests_cek/uji_*.py` exit 0 (termasuk `uji_aset_fase3.py` dan `uji_aset_gelombang1.py`).
- Probe 2340x1080 (`probe_sisi_dekat_jendela`, `probe_simpang_jendela`, `probe_rute_jendela`, `probe_hud_rute_jendela`): exit 0, 0 ERROR/WARNING, 0 keadaan tidak sesuai.
- `git diff main` kosong untuk `ThrowSolver`, `BikeMotion`, `Tabrakan`, `TenggatRute`, `MissionManager`, `RencanaMisi`, `BikeCondition`, `Economy`, `DataSave`, `SaveManager`; angka skor `config.gd` tidak berubah.
- sha256 `user://save.json` asli sesudah semua tes, probe, mutan: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e` (tidak berubah).
- Paket (AC-14): 1.773.380 byte, 682 berkas, cek dari luar repo 47 lolos, 0 gagal.

### Pindai AC-16 (diff `main...HEAD`)
- Static typing: tidak ada `var`/`const` tanpa tipe di baris tambahan `scripts/` dan `tests/` (pindai regex 0 temuan; `:=` tidak dipakai di tambahan). `##` bahasa Indonesia; sisi hanya `seberang`/`dekat`.
- Hex di luar `palette.gd`: 0 di baris tambahan `scripts/` dan `scenes/`. Teks pemain tertanam: hanya `tr("RUTE_TIP_LABEL")` dan kunci `RUTE_TIP_SISI_DEKAT` (keduanya di `ui.csv`).
- Angka ajaib: literal baru di luar `config.gd` hanya nilai struktural (0.0, 1.0, 2 sebagai pembagi/indeks); semua angka tuning ada di `config.gd` satu baris literal (`RUTE_DEKAT_*`, `RUTE_RUMAH_DEKAT_*`, `TIP_SISI_DEKAT_*`).
- `.uid`/`.import`: semua `.gd` dan PNG baru di `scripts/`, `tests/`, `assets/` punya `.uid`/`.import` terkomit (`docs/` dikecualikan Godot oleh `docs/.gdignore`, jadi `dev_ukur/*.gd` dan PNG docs tanpa `.uid`/`.import`, sama dengan 5C). Tidak ada `build/`, `builds/`, `.godot/`, APK, AAB, keystore di diff.
- Tembok: `assets/` tidak punya berkas tembok (selain graybox spike, dikecualikan paket); kode tidak punya `TembokDekat`, `VarianTembok`, `RUTE_TEMBOK*`, `SPRITE_TEMBOK*` (dijaga `tes_sisi_dekat` dan `tes_export`); sisa kata "tembok" di kode hanya komentar sejarah ("dilepas run 5D") dan nama run `fase5b-tembok-dekor`.
- Impor Nearest/Lossless/tanpa mipmap: dijaga `tes_export` (rumah dekat, kotak surat) dan `uji_aset_fase3.py`. Tekstur dimuat di `_init`/`_ready` (tidak ada `load`/`preload` di `_draw` pada tambahan).

### Mutan nyata bagian C (15; satu perubahan, runner `tes_export` lewat `dev_ukur/mutan_c.py` atau paket nyata, `git checkout`/hapus berkas, `git status` bersih tiap kali)
| ID | Berkas | Perubahan satu baris | Hasil | Gagal yang menangkap |
|---|---|---|---|---|
| M-C1 | `assets/sprites/houses/perumahan/house_tembok_polos.png` | aset tembok ikut tersalin ke `assets/` | MATI (3 gagal) | aset tak dipasang tidak ada di repo; folder rumah tepat 12 PNG |
| M-C2 | `house_perumahan_dekat_pelana_sejajar_pelanggan.png.import` | `compress/mode=0` -> 2 (bukan Lossless) | MATI (1) | impor Lossless tanpa mipmap |
| M-C3 | `scripts/config.gd` | komentar merujuk `house_perumahan_dekat_pelana_gudang_bukan` | MATI (1) | pemindai: rujukan ke rumah yang belum dipasang |
| M-C4 | `scenes/rute/rute.tscn` | merujuk `prop_kotak_surat_dekat` | MATI (1) | pemindai: rujukan ke kotak surat yang belum dipasang |
| M-C5 | `export_presets.cfg` | satu rumah dekat dikecualikan dari paket | MATI (21) | `exclude_filter` mengecualikan berkas yang harus ikut paket |
| M-C6 | `translations/ui.csv` | baris `RUTE_TIP_SISI_DEKAT` dihapus | MATI (1) | kunci tepat satu di ui.csv |
| M-C7 | `per_buka_01.json` | satu rumah dekat `pelanggan_boleh` true -> false | MATI (1) | 34 rumah dekat `pelanggan_boleh` di JSON (dapat 33) |
| M-C8 | `house_perumahan_dekat_limasan_bukan.json` | kunci `teras_ubin` rusak | MATI (1) | titik pijak, teras, penutup di JSON |
| M-C9 | `per_tutup_02.json` | tag `dua_sisi` -> `seberang` | MATI (1) | tag sisi_pelanggan dua_sisi |
| M-C10 | `docs/SETUP_ANDROID.md` | judul 8.16 -> 8.17 | MATI (9) | bagian 8.16 ada; 11 butir |
| M-C11 | `docs/ROADMAP.md` | "Riwayat (diganti, tetap dicatat)" -> "Riwayat" | MATI (1) | ROADMAP 4b menandai tembok diganti dengan riwayat tetap |
| M-C12 | `docs/GDD.md` | "8 atau 9 dari 25" -> "7 atau 10 dari 25" (semua) | MATI (1) | GDD memuat 8 atau 9 dari 25 |
| M-C13 | `AGENTS.md` | `TembokDekat`/`VarianTembok` didaftar lagi | MATI (1) | AGENTS.md tidak lagi mendaftar kelas tembok |
| M-C14 | paket nyata | JSON `house_tembok_polos.json` di `assets/`, `--export-pack` | MATI (cek paket 46/1) | tidak ada berkas bernama tembok di paket |
| M-C15 | paket nyata, `export_presets.cfg` | `per_tutup_02.json` dikecualikan dari paket | MATI (cek paket 45/2) | 9 segmen dimuat dari paket tanpa galat; 34 rumah dekat dari paket |
Total mutan Dev: 14 (A) + 30 (B) + 15 (C) = **59** (target >= 30; butir wajib AC-19 tercakup di A, B, dan C: aset tembok tersalin M-A10/M-C1/M-C14, pemindai rujukan M-C3/M-C4, `.import` bukan Lossless M-A11/M-C2, fase3 tidak deterministik M-A2, dokumen-tes M-C10..M-C13).

### Tangkapan dan probe lama (2340x1080, non-headless, satu proses Godot sekaligus)
`probe_sisi_dekat_jendela`, `probe_simpang_jendela`, `probe_rute_jendela`, `probe_hud_rute_jendela`: exit 0, 0 baris ERROR/WARNING, "probe selesai, 0 keadaan tidak sesuai" di keempatnya (tangkapan ke folder sementara, tidak dikomit). Probe `sisi_dekat` sudah dijalankan di empat ukuran di bagian B.

### Hal yang menunggu keputusan pemilik (dari bagian B, diteruskan)
1. Anjing dekat `per_tengah_02@14` dan `per_tengah_03@30` beririsan dengan zona kotak surat dua rumah bukan pelanggan: geser ke @16 dan @32 bila mengganggu di HP (SETUP_ANDROID 8.16 butir 9).
2. Lemparan tepat ke pelanggan dekat dalam jendela rumah memberi petunjuk misi (bonus presisi; `MissionManager` tidak boleh berubah).
3. Rumah dekat sebagian tertutup panel HUD bawah (HUD tidak diubah; 8.16 butir 8).

## Iterasi 1, QA (Agent 2)

Verdict: **PASS** (0 Blocker, 0 Major; Minor QA-001, -002, -004, -005, -008; Nit QA-003, -006, -007, -009). Semua keadaan di bawah dijalankan sendiri oleh QA, bukan disalin dari klaim Dev. Skrip QA ada di `docs/loop/20261022-fase5d-sisi-dekat/qa_ukur/` (di luar jangkauan Godot oleh `docs/.gdignore`).

### Gerbang objektif (QA, HEAD be7a5c0)
- `godot --headless --import`: 0 ERROR/WARNING (satu baris `cannot connect to daemon at tcp:5037` dari plugin adb Godot, tidak ada dampak). `run_tests.gd`: **19281 lolos, 0 gagal**; `tools/cek_keluaran_tes.py`: lolos (0 peringatan). `godot --headless --path . --quit-after 2`: 0 ERROR/WARNING.
- 14 `tools/tests_cek/uji_*.py` (termasuk `uji_aset_fase3.py`, ada di `.github/workflows/tes.yml`): semua exit 0.
- sha256 save asli sebelum dan sesudah semua tes, probe, mutan: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e`.
- Kebersihan: 13 commit di atas `main` lokal, tidak ada commit di `main`, format `feat/test/art/docs: ...` bahasa Indonesia dengan `Claude-Session`; tidak ada keystore, APK, `.godot/`, `build/` di diff; `.uid`/`.import` hadir untuk semua `.gd`/PNG baru di `scripts/`, `tests/`, `assets/` (`dev_ukur/*.gd` di `docs/` dikecualikan Godot). Catatan: `main` lokal tertinggal dari `origin/main`; commit `f42e22e` (PR #55, hanya dokumen) ikut di riwayat branch.
- `git diff main` KOSONG untuk `throw_solver.gd`, `bike_motion.gd`, `tabrakan.gd`, `tenggat_rute.gd`, `mission_manager.gd`, `rencana_misi.gd`, `bike_condition.gd`, `economy.gd`, `data_save.gd`, `save_manager.gd`; `config.gd` tidak mengubah angka skor, combo, koin, tenggat (baris berubah hanya `RUTE_RUMAH_*`, `RUTE_DEKAT_*`, `TIP_SISI_DEKAT_*`, pijak sprite rumah dekat, tembok dibuang).
- Paket `--export-pack`: exit 0, 0 ERROR/WARNING, 1.773.380 byte (sama dengan Dev). Isi (strings): 36 rujukan `house_perumahan_dekat`, kedua kotak surat, `tip_sisi_dekat.gd`, `panel_tip_sisi_dekat`; tidak ada `tembok`, `res://tests`, `res://docs`, `res://tools`, spike, `cek_render`.
- Tembok: `assets/` hanya menyisakan graybox `_spike/sisi_dekat/spike_dekat_tembok_*` (D-6, dikecualikan paket); di `scripts/` (selain `scripts/dev/spike_sisi_dekat.gd`) dan `scenes/` kata 'tembok' hanya di komentar riwayat; tidak ada kelas/konstanta/aset tembok.

### Pengukuran QA dengan skrip sendiri
- **(a) RouteBuilder `main` vs HEAD** (`dump_rute.gd`, refleksi semua bidang `Rute`; `main` lewat `git archive` ke folder sementara dan diimpor sendiri; 200 seed: `SeedHari.rute(1..100)` + seed 1..100, panggilan tanpa hari dan hari 2): 0 beda galat, satu-satunya bidang yang berbeda `rumah[].pelanggan_boleh` (5600 entri per mode = 11.200 total), semuanya sisi DEKAT dan false -> true, tidak ada pada `per_tengah_02@12`/`per_tengah_03@28`; segmen, rumah (id, maju, sisi, jenis), pelanggan, pemberi tip, objek, titik misi, dekor, simpang, panjang, koran awal, tenggat identik; HEAD hari 1 = hari 2 untuk 200 dari 200. **Hari 3..1002 (1000 hari, `hari_dekat.gd`)**: sebaran dekat {8: 486, 9: 514} (100% di 8-9), 0 rute gagal, 25 pelanggan semua, tak ada pelanggan tak boleh atau ganda, `periksa_rute` kosong, hari 1-2: 0 dekat; celah gabungan min 2,0 / median 10,0 / maks 20,0 (batas 20,0); tenggat 89..92 detik.
- **(b) Prediksi = hasil, zona dekat** (`qa_grid.gd` + oracle Python independen dari config seberang, JSON aset, dan prioritas SPEC): klasifikasi `ZonaSasaran.klasifikasi` atas 425.663 titik (119 rumah dekat, hari 3..6, grid 1/16 ubin, pelanggan dan bukan) vs oracle: 496 beda, SEMUANYA di baris maju = kavling + 3,5 yang adalah zona rumah tetangga (artefak batas grid, bukan beda); 0 beda nyata. Lemparan swipe nyata (tiga sasaran + meleset, kidal) dijaga `tes_sisi_dekat_scene` yang saya jalankan terpisah (123 lolos, 0 gagal, termasuk bot bantu 22 rute 25/25); mutan Q15 dan Q19 menguji pemasangan sprite/inti.
- **(c) Bantu, radar, progres**: bot bantu 22 rute lulus; mutan QA Q5 (sasaran bantu terjauh) dan Q6 (strip radar dekat menyaring seberang) tertangkap (Q6 hanya oleh `tes_hud_rute_scene`).
- **(d) Tip**: hanya `hari == RUTE_DEKAT_HARI_MULAI`; `git diff main -- scripts/systems/data_save.gd scripts/autoload/save_manager.gd` kosong, `HariMain` hanya menambah `atur_hari`; tangkapan hari 3 (tip 2 baris di kolom kiri, tidak terpotong, tidak menutup kontrol) dan hari 2 (tanpa tip, kotak surat dekat abu-abu) dilihat.
- **(e) AC-6 diukur ulang** (`ukur6.py`: PNG dan JSON nyata, proyeksi iso ditulis ulang, 100 rute nyata hari 1, semua rumah dalam 14 ubin sebagai penutup, dua varian sprite, Y-sort untuk kotak surat dan pemain, pemain = gabungan semua frame berkendara, lateral -1..2 langkah 0,125, maju kavling -3..+5): badan kotak surat dekat **0%** tertimpa, zona kotak surat dekat maks **2,58%** (<= 5%), pemain di semua lateral -1..2: **0%** tertimpa di setiap posisi (tidak ada satu pun piksel pemain tertutup), lantai teras tertimpa tetangga 24,4%, halaman 59,9% (QA-009). Sasaran SPEC tercapai tanpa pudar.
- **(f)** tembok: lihat gerbang. **(g)** paket: lihat gerbang.
- **(iii) MissionManager**: lihat QA-002 (100/100).

### Telusur AC (bukti kode + tes yang QA baca atau jalankan)
AC-1 baseline di LOG (Dev + orchestrator, nilai sama dengan gerbang QA). AC-2 `uji_aset_fase3.py` exit 0 (147 lolos) + mutan P1 (satu byte biru satu piksel PNG rumah) tertangkap; di CI baris 89. AC-3 `fase3.py house_near_teras`, JSON `teras_ubin`/`penutup_*`, mock `fase3_rumah_dekat_banding.png`; tangkapan tiga jenis dilihat (teras menjorok terbaca dari samping). AC-4 tes sisi dekat + pemindai; paket tanpa tembok. AC-5 `PenutupPemain.dari_rumah_gambar` kotak sprite nyata; mutan Q8 dan Q16 tertangkap. AC-6 lihat (e). AC-7 data 34/36 + validasi (mutan Q9 tertangkap). AC-8 lihat (a); `HariMain` meneruskan hari (mutan Q10). AC-9 kotak surat dua sisi dan terlipat dekat: tangkapan `terlipat_dekat` dilihat, koran terlipat tampak di teras (dikrop dan dibesarkan). AC-10 lihat (b). AC-11 lihat (c). AC-12 tip (mutan Q14, Q18). AC-13 probe 4 ukuran dijalankan QA: semua exit 0, 0 ERROR/WARNING, 'probe selesai, 0 keadaan tidak sesuai'. AC-14 paket. AC-15 tidak ada regresi (tes lama berubah dinilai di bawah). AC-16 pindai QA atas 520 baris tambahan `scripts/` dan `scenes/`: tanpa `var` tak bertipe, tanpa `:=`, tanpa hex atau `Color(`, tanpa `kiri/kanan` di kode, tanpa `randi()`/`randf()`/`load()` di tambahan (RNG hanya `RandomNumberGenerator` berseed di RouteBuilder), angka literal baru hanya di `config.gd` satu baris. AC-17 dokumen ada; sisa teks usang: QA-008; Bagian 6j LOOP-DEV-QA tidak disentuh (hanya satu baris tabel 6g berubah sejak f42e22e); `DEV_PHASES.md`, `CHANGELOG.md`, manifest tidak diubah Dev. AC-18 gerbang. AC-19 59 mutan Dev tercatat; QA mengulang 20 sendiri (bawah).

### Tes lama yang berubah (D-5) dinilai QA
- `tes_tembok.gd`, `ukur_tembok.gd` dihapus: semua yang dijaga (varian FNV, modul, tiang) tidak ada lagi; yang masih berlaku dipindah ke `tes_sisi_dekat.gd` (1000 lemparan seberang tetap `[494, 5508, 143, 809075394]`): sah.
- `tes_rute.gd` (`pelanggan_boleh` 37 -> 37 + 34, tag `dua_sisi`, dua mutan data kini ditolak dengan pesan 'tidak sesuai isi'), `tes_kotak_surat.gd` (rumah dekat kini punya kotak surat), `tes_rute_scene.gd` (pusat gambar 5,75 -> 5,0; titik 'di balik rumah dekat' 2,5 -> 2,9): sah, akibat langsung P-1/P-4/P-5.
- `tes_dekor.gd` dan `tes_simpang.gd` golden 60 seed dihitung ulang: QA memverifikasi sendiri bahwa satu-satunya beda dari `main` adalah `pelanggan_boleh` rumah dekat (bagian (a)), jadi perubahan golden sah. `tes_simpang`: simpang dekat pos 8 vs rumah pos 4 ditolak -> sah karena tembok (rentang sampai pos+3) dilepas, kavling dekat pos 10 13,0 -> 12,5: sah. Tidak ada tes di-skip.
- `uji_aset_pasang_5b.py` (12 golden rumah dekat diserahkan ke `uji_aset_fase3.py`, dicek tepat 12) dan `uji_aset_pasang_gelombang1.py`: sah; kedua exit 0.

### Tangkapan yang QA lihat (`shots/qa1/`, probe `probe_sisi_dekat_jendela`, non-headless, satu proses Godot; hanya 2340x1080 dan 1600x720 dikomit demi ukuran repo, 1920x1080 dan 2400x1080 juga dijalankan: 0 tidak sesuai, 0 ERROR)
Dilihat langsung: `2340x1080_dekat_{halaman_limasan, halaman_pelana_sejajar, hari3_tip, hari2_tanpa_dekat, terlipat_dekat (+ krop 3x), teras_bidik, teras_kena, radar_dekat, bantu_dekat_kena (+ krop anjing), kidal}`, `1600x720_dekat_{hari3_tip, halaman_trotoar_pelana_lintang}`. Penilaian jujur: halaman dekat terbuka dan terbaca sebagai rumput; ketiga jenis rumah dekat dengan teras menjorok terbaca dari samping dan tidak menimpa sepeda; kotak surat dekat (oranye pelanggan, abu-abu bukan) di tepi trotoar terbaca; tip dua baris tidak terpotong di 2340x1080 dan 1600x720 dan tidak menutup kontrol (menimpa sebagian atap rumah di bawahnya, dasar gelap transparan); radar kanan menampilkan penanda dekat; koran terlipat tampak di teras dekat; hari 2 tanpa tip dan semua kotak surat dekat abu-abu. Tidak ada sprite aneh menumpuk atau terpotong, kecuali rumah dekat yang sebagian tertutup panel HUD bawah (QA-001, tercatat Dev). Tidak dilihat satu per satu: 1920x1080 dan 2400x1080 (hanya angka probe), tangkapan bidik meleset, `bantu_dekat_tanpa_sasaran`.

### Mutan QA (20; satu perubahan, runner = `qa_runner.gd` (tes sisi dekat A/B/scene, `tes_rute`, HUD rute + radar, kotak surat + rute scene) lalu `run_tests.gd` penuh untuk yang selamat, `git checkout`, `git status` bersih tiap kali; skrip `qa_ukur/qa_mutan.py`, `qa_mutan_full.py`)
| ID | Berkas | Perubahan satu baris | Hasil |
|---|---|---|---|
| Q1 | `route_builder.gd` | `periksa_rute`: celah `>` jadi `>=` (celah 20 tepat ditolak) | TERTANGKAP (4 gagal; 59 hari tak sah) |
| Q2 | `route_builder.gd` | urutan dua `_cocokkan` dekat/seberang tertukar | **LOLOS** penuh (QA-006) |
| Q3 | `zona_sasaran.gd` | zona teras dekat tanpa mundur 0,5 | TERTANGKAP (10) |
| Q4 | `config.gd` | inti tepat zona dekat +0,25 lateral | TERTANGKAP (1) |
| Q5 | `bantu_lempar.gd` | bantu memilih sasaran terjauh | TERTANGKAP (1, `tes_rute`) |
| Q6 | `hud_rute.gd` | strip radar dekat menyaring sisi seberang | TERTANGKAP (HUD rute scene: 6 gagal vs 1 dasar headless) |
| Q7 | `panel_tip_sisi_dekat.tscn` | semua `mouse_filter` 2 -> 0 (panel menelan sentuhan) | TERTANGKAP (1) |
| Q8 | `penutup_pemain.gd` | gabungan kotak jenis dekat hanya jenis terakhir | TERTANGKAP (1) |
| Q9 | `segmen_rute.gd` | tag `dua_sisi` cukup satu sisi (`and` -> `or`) | TERTANGKAP (2) |
| Q10 | `hari_main.gd` | hari diteruskan +1 | TERTANGKAP (6) |
| Q11 | `config.gd` | halaman dekat mulai maju -1,0 | TERTANGKAP (2) |
| Q12 | `rumah_daur_rute.gd` | `reparent` kembali dari pembungkus dihapus | **LOLOS** penuh (QA-005) |
| Q13 | `route_builder.gd` | kuota maks `periksa_rute` +1 | **LOLOS** penuh (QA-004) |
| Q14 | `tip_sisi_dekat.gd` | tip tampil walau sisa 0 | TERTANGKAP (3) |
| Q15 | `sprite_rumah.gd` | sprite kotak surat +0,25 maju dari zona | TERTANGKAP (2) |
| Q16 | `medan_koran.gd` | tertutup memakai tapak logika | TERTANGKAP (1) |
| Q17 | `ui.csv` | teks tip 3x lebih panjang | TERTANGKAP hanya oleh cek CSV = `.translation` (1), bukan tata letak (QA-007) |
| Q18 | `rute_main.gd` | 'Main lagi' mengisi ulang tip | TERTANGKAP (1) |
| Q19 | `zona_sasaran.gd` | zona kotak surat dekat tanpa inti | TERTANGKAP (1) |
| Q20 | `route_builder.gd` | kuota hari genap selalu 8 | TERTANGKAP (2) |
| P1 | `house_perumahan_dekat_limasan_bukan.png` | satu kanal satu piksel +1 | TERTANGKAP (`uji_aset_fase3` 147/1) |
| P2 | `house_perumahan_dekat_pelana_sejajar_pelanggan.json` | `penutup_tinggi_ubin` 1,5625 -> 1,625 | TERTANGKAP (`uji_aset_fase3` 146/2) |
16 dari 20 mutan Q tertangkap penuh (ditambah P1 dan P2 Python, 18 tertangkap total); Q17 sebagian; 3 selamat (Q2, Q12, Q13) = celah tes, bukan bug produksi. `git status` bersih (selain folder shots/skrip QA) sesudah tiap mutan.

### Catatan lingkungan
Proses `godot` PID 26665 milik sesi lama tidak disentuh. Hanya satu proses Godot milik QA berjalan pada satu waktu. HUD rute scene dijalankan terpisah di runner QA menghasilkan 1 kegagalan dasar (`lebar 640: panel di dalam layar...`) karena urutan ukuran viewport headless; `run_tests.gd` penuh hijau, jadi mutan dibandingkan dengan dasar 1.
