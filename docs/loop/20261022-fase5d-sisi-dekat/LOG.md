# Loop Log — 20261022-fase5d-sisi-dekat
Scope: Run 5D, Fase 5 (dimajukan dari Fase 8): pelanggan sisi dekat mulai hari 3 (8-9 dari 25), tembok dekat dihapus jadi halaman terbuka, rumah dekat mundur 0,5 ubin dan didesain ulang dengan teras menjorok  ·  Branch: feat/fase5d-sisi-dekat  ·  Mulai: 2026-10-22  ·  Godot: 4.7.2

## Status: IN_PROGRESS   (iterasi saat ini: 1/2, bagian A)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 1 (A) | AC-1..AC-6: baseline, fase3 dapat dihasilkan ulang + uji, rumah dekat baru (teras menjorok, tanpa kotak surat), tembok dilepas, mundur 0,5, kotak penutup sprite nyata; AC-6 tercapai TANPA pudar (P-3 tidak dipakai); 14 mutan | import 0 / 18933 lolos 0 gagal / pemeriksa lolos; 14 uji_*.py exit 0; save tetap | menunggu orchestrator (titik henti D-1) | - | - |

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## Baseline (orchestrator, `main` 53408cf, 2026-10-22; `main` lalu maju ke f42e22e = PR #55, hanya dokumen)
- `godot --headless --import`: 0 baris ERROR/WARNING. `godot --headless --path . --quit-after 2`: 0 baris ERROR/WARNING.
- `run_tests.gd`: **19022 lolos, 0 gagal**; `tools/cek_keluaran_tes.py`: lolos (0 peringatan).
- 13 `tools/tests_cek/uji_*.py` exit 0: uji_aset_gelombang1, uji_aset_kucing, uji_aset_lampu_pohon, uji_aset_pasang_5b, uji_aset_pasang_gelombang1, uji_aset_simpang, uji_bangun_frames, uji_pemeriksa, uji_sintesis_{kondisi,lempar,misi,rute,sepeda}.
- sha256 `user://save.json` asli (`~/Library/Application Support/Godot/app_userdata/Kring Kring!/save.json`): `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e`.
- HP: `adb devices` kosong.

## NEEDS-MANUAL (uji di HP)
Lihat SPEC bagian NEEDS-MANUAL dan SETUP_ANDROID 8.16.

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
