# Loop Log — 20261021-fase5a-pasang-aset-gelombang1
Scope: Run 5A, Fase 5, pasang aset gelombang 1 (ubin enam kolom, koran, VFX sepeda, bintang dan koin, kilau misi), hanya tampilan  ·  Branch: feat/fase5a-pasang-aset-gelombang1  ·  Mulai: 2026-10-21  ·  Godot: 4.7.2.stable.official.ed1daf0bf

## Status: IN_PROGRESS   (iterasi saat ini: 1/2, bagian A dan B selesai, menunggu QA)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 1 (bagian A) | Renderer K-1, `--salin`, uji aset, 13 sprite + 7 ubin terpasang, ubin enam kolom di rute (bagian B belum) | import bersih; `run_tests.gd` 16949 lolos 0 gagal (baseline 16735), pemeriksa keluaran lolos; `--quit-after 2` bersih; semua `uji_*.py` lolos | (belum) | 0 | 0 |
| 1 (bagian B) | Koran (putar, bayangan menurut tinggi, permukaan, terlipat), debu dan garis dari sprite, bintang dan koin tip, kilau, probe jendela `probe_aset_jendela.gd` (4 ukuran), tes (`tes_koran_sprite.gd`, `tes_vfx_sprite.gd`, `tes_export.gd` diperluas), dokumen AC-20 | import bersih; `run_tests.gd` **17313 lolos, 0 gagal** (akhir bagian A 16949, baseline 16735) dan `cek_keluaran_tes.py` lolos (0 peringatan); `--quit-after 2` bersih; semua `uji_*.py` lolos (aset_gelombang1 352, aset_pasang_gelombang1 236, kucing 12, bangun_frames 51, pemeriksa 16, sintesis 32/111/90/47/55); `--export-pack` 1,6 MB dimuat dari folder luar repo (13 sprite + 7 ubin + `rute.tscn` + 9 segmen); probe baru 4 ukuran 0 keadaan tidak sesuai, probe lama jalan tanpa error; 30 mutan bagian B | (belum) | 0 | 0 |

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## NEEDS-MANUAL (uji di HP)
Lihat SPEC bagian NEEDS-MANUAL dan `docs/SETUP_ANDROID.md` 8.12 (ditulis Dev).

## Keputusan & catatan
- Persiapan orchestrator (2026-10-21): `main` = `origin/main` = `f2e5b64` (memuat PR #42, #43, #44). Branch kerja `feat/fase5a-pasang-aset-gelombang1` dari situ. Godot terpasang (`/opt/homebrew/bin/godot` 4.7.2), numpy 2.5.3 dan pillow 12.3.0 ada, `adb devices` kosong (tidak ada HP tersambung saat persiapan). Hasil uji HP 4A, 4B, 6A1: kosong (belum ada catatan pemilik).
- Keputusan pemilik yang didelegasikan: K-1 sampai K-5 di SPEC. Keputusan desain orchestrator D-1 sampai D-8 di SPEC (usulan, bisa ditolak di review PR).
- Baseline tes sebelum run (main f2e5b64, Godot 4.7.2): **16735 lolos, 0 gagal**, pemeriksa keluaran lolos.
- sha256 `user://save.json` asli (`~/Library/Application Support/Godot/app_userdata/Kring Kring!/save.json`, mtime 17 Okt) sebelum run: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e`; sama sesudah baseline. Dev dan QA mencatat lagi sesudah semua tes dan probe.
- Pelajaran persiapan: jangan menjalankan dua proses Godot tes bersamaan, tes simpan (`SaveManager` jalur uji, `user://`) bentrok dan menghasilkan dua GAGAL palsu.

### Iterasi 1, bagian A (Dev): renderer, aset terpasang, ubin enam kolom
Commit: `2b0399c` art (K-1, `--salin`, aset), `c48b342` test (uji aset), `e76aee1` feat (ubin enam kolom), `6f56152` + berikutnya test (`tes_ubin.gd`).
- **K-1 (1) kilau**: `mission_kilau` dua warna, krem terang `#FBF6E8` dominan (100% piksel non-garis-luar kecuali satu), kuning aksen `#FFC94A` satu piksel di titik tengah per frame. Diuji (>= 60%, <= 5 piksel kuning, di titik tengah, tidak ada warna ketiga).
- **K-1 (2) tong sampah**: hijau dibuang; `prop_tong_sampah_logam` (abu-abu logam: terang `logam[0]`, dasar `logamg[0]` #5F5B66, gelap `logamg[1]`; warna dasar sengaja bukan `logam[1]` = #969AA0 = RADAR_BUKAN) dan `prop_tong_sampah_biru` (dasar #5F96C8). **Hasil pemeriksaan token DESIGN_SPEC 1.1** (dibaca dari `scripts/ui/palette.gd`: ACCENT, OK, FAIL, WARN, RADAR_PELANGGAN/TIP/MISI/BUKAN): biru #5F96C8 jarak RGB terkecil ke token semantik >= 40 (uji), tidak bentrok, jadi **biru dipertahankan**; logam #5F5B66 tidak bentrok. Manifest tetap 29 sprite (hijau diganti logam; nama berubah, tidak dipasang di rute sampai 5B).
- **K-1 (3) polisi tidur**: `prop_polisi_tidur` kuning-hitam dan kodenya (`polisi_tidur`, `ekspor_polisi_tidur`, `KUNING`, `HITAM_PT`, impor `fase3` yang jadi tidak terpakai) dibuang dari `ubin_perumahan.py`; diuji ekspor di folder sementara, tidak ada berkas polisi di `assets/` dan `docs/design/environment/`; satu-satunya = `tile_perumahan_polisi_tidur` gelombang 1.
- **`--salin`**: `render.py --salin` (13 sprite ke `props/` dan `vfx/`), `ubin_perumahan.py --salin` (enam ubin + `rumput_1` + `tile_perumahan.json` terpangkas). Env `ENV_ART_SALIN_KE` dan `ENV_ART_MOCK_KE` (hanya untuk uji; default repo). Mock docs dirender ulang lewat `--mock`; hanya 3 PNG yang piksel-nya berubah (`komposisi_siang/sore_x3`, `lembar_properti_x5`) yang disimpan, sisanya dikembalikan (byte PNG beda antar run, piksel sama). `uji_aset_gelombang1.py` kini membandingkan semua mock termasuk lembar kontak ke hasil `--mock` di folder sementara.
- **Keputusan D-2, rumput luar** (diukur): `rumput_dekat` identik piksel dengan rumput polos (0 beda), tetapi `rumput_seberang` berbeda 80 piksel dari rumput polos (tepi kerb luar menjorok ke kolomnya, bayangan/silhouet 2,6 unit). Mengulang `rumput_seberang` di kolom luar memberi pita tepi di tiap ubin, jadi **dipasang SATU ubin polos tambahan `tile_perumahan_rumput_1`** (pengecualian atas daftar D-1, dicatat di JSON ubin, README, dan tes) dan dipakai untuk kolom rumput di luar kolom pertama di kedua sisi (`JalanDaur.rumput_luar`, `Config.JALAN_RUMPUT_TEPI_UBIN` = 1,0). `tests/tes_ubin.gd`: ubin kolom luar piksel-identik dengan `rumput_1`, `rumput_seberang` beda dari rumput polos, dan komposisi periodik tanpa pita; Python: susunan dari berkas = adegan renderer pada semua piksel tertutup (0 beda, 0 celah).
- **Tafsir D-2 (batas kolom), mohon QA/pemilik tinjau**: SPEC menulis interval setengah terbuka (`-2 <= x < -1` trotoar_seberang) sekaligus "batas luar inklusif ke jenis luar seperti jenis_di". Keduanya bertentangan di sisi seberang (`jenis_di(-1)` = TROTOAR, `jenis_di(-2)` = RUMPUT). Dipilih konsisten dengan `jenis_di` dan simetri (AC-4 "simetri nama seberang/dekat"): batas |x| = 1 dan 2 ke kolom luar di kedua sisi; hanya x = 0 jatuh ke `dekat`. Tanpa pengaruh pada game (pusat ubin selalu setengah ganjil). Dites dengan tabel literal dan 300 nilai acak.
- **Ubin di `TanahDaur`**: satu wadah per kolom ditambah `RumputLuar` (7 wadah, tiap wadah satu tekstur supaya gambar tergabung per tekstur; dengan tiga wadah per jenis batch akan putus tiap ubin). Jumlah SPRITE ubin dan posisinya tidak berubah (diuji 434/450/496/511 ubin untuk lebar 640/667/780/800 dan = jumlah graybox); node wadah +4 (3 menjadi 7) di scene rute saja. Mode tiga tekstur graybox tetap untuk `jalan_uji.tscn`, spike, dan `cek_render` (tidak disentuh).
- **Pengamatan sebelum run (tidak diubah)**: `JalanDaur.sel_tanah` tidak memuat dorongan kecepatan MUNDUR terbesar; di lebar 640, lateral +2, jarak pecahan tinggi ada celah sudut (sekitar 1.000 piksel transparan) yang sama pada ubin graybox lama. `sel_tanah` dikunci "tidak berubah" (AC-4), jadi `tes_ubin.gd` memeriksa tanpa celah untuk tanpa dorongan dan dorongan maju terbesar saja (360 viewport), dan ini dicatat sebagai temuan yang sudah ada, bukan akibat run ini (DEFERRED ke 5B/6 bila pemilik melihatnya di HP).
- **Tes baru**: `tools/tests_cek/uji_aset_pasang_gelombang1.py` (236 pemeriksaan; langkah di `tes.yml`), `uji_aset_gelombang1.py` (352), `tests/tes_ubin.gd` (sekitar 210 `check`; pemetaan, simetri, `sel_tanah` literal, scene rute, tanpa celah/pita, referensi `tests/data/ubin_potongan_8_maju.png` dengan `.gdignore`, pemindai aset belum dipasang). Referensi dibuat skrip (`--perbarui-referensi`), bukan tangan.
- **Kejadian**: dua kali pernah satu GAGAL palsu (`ban: 'Baik'`) saat dua proses Godot berjalan bersamaan (proses lama tertinggal); tidak terulang sesudah proses tunggal. Galat parse di berkas tes membuat `run_tests.gd` menggantung (pemeriksa keluaran perlu batas waktu bila otomatisasi).
- sha256 `user://save.json` asli sesudah semua tes bagian A: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e` (sama dengan awal).
- **Belum dikerjakan (bagian B)**: koran, permukaan, bayangan, terlipat, VFX, bintang, koin, kilau di game, probe, `tes_export`/paket (AC-16, AC-17 penuh; bagian ubin AC-17 sudah di `tes_ubin.gd`), dokumen AC-20.

### Mutan nyata bagian A (AC-22; tiap mutan satu perubahan, tes penuh atau uji Python, lalu `git checkout`; `git status` bersih sesudah tiap mutan)
| # | File | Perubahan satu baris | Tes yang gagal (pertama) |
|---|---|---|---|
| A1 | `jalan_daur.gd` | `x >= 0.0` jadi `x > 0.0` (batas nol) | `kolom_di(0.0) = ASPAL_DEKAT` |
| A2 | `jalan_daur.gd` | aspal seberang/dekat tertukar | `kolom_di(-0.5)`, `kolom_di(0.5)` (10 gagal) |
| A3 | `jalan_daur.gd` | trotoar seberang/dekat tertukar | `kolom_di(-1.5)`, `kolom_di(1.5)` (11 gagal) |
| A4 | `jalan_daur.gd` | `rumput_luar` `>=` jadi `>` | `rumput_luar(3.0)`, `rumput_luar(-3.0)` |
| A5 | `jalan_daur.gd` | `jenis_di` aspal `<` jadi `<=` | batas aspal-trotoar (x +-1,0) di `tes_input_murni` dan `tes_ubin` |
| A6 | `jalan_daur.gd` | `jenis_di` trotoar `<` jadi `<=` | batas trotoar-rumput (5 gagal) |
| A7 | `jalan_daur.gd` | baris atas `sel_tanah` dipangkas 40 px | `sel_tanah` literal 434/450/496/511, jendela pandang tertutup ubin (9 gagal) |
| A8 | `tanah_daur.gd` | aspal seberang memakai tekstur aspal dekat | tekstur kolom 480 dari 511 |
| A9 | `tanah_daur.gd` | kolom luar tanpa `rumput_1` (tepi kerb berulang) | tekstur kolom 173 dari 511, 7 tekstur (6 gagal) |
| A10 | `tanah_daur.gd` | ubin digeser 1 px | tanah menutup layar 60 detik ngebut (celah), posisi vs graybox (5 gagal) |
| A11 | `tanah_daur.gd` | tiap ubin digandakan (node naik) | jumlah sprite ubin 868 vs `sel_tanah` 434 (6 gagal) |
| A12 | `rute.tscn` | tekstur aspal dekat salah | scene rute: tekstur kolom 481 dari 511 (lolos dulu; tes diperkuat) |
| A13 | `rute.tscn` | tanpa `rumput_1` | scene rute: tekstur kolom 173 dari 511 (lolos dulu; tes diperkuat) |
| A14 | `config.gd` | `JALAN_TROTOAR_UBIN` 1,0 jadi 1,5 | 35 gagal (gerak, lateral, kolom) |
| A15 | `config.gd` | `JALAN_RUMPUT_TEPI_UBIN` 1,0 jadi 2,0 | `rumput_luar(3.0)` dan konstanta (11 gagal) |
| A16 | `rute.tscn` | merujuk `tile_graybox` lagi | rute.tscn tidak merujuk `tile_graybox_*` |
| A17 | `render.py` | aset tak dipasang ikut tersalin (`prop_tong_sampah_biru` ke props/) | uji pasang: daftar D-1 di props |
| A18 | `ubin_perumahan.py` | ubin tak dirujuk ikut disalin (`aspal_1`) | uji pasang: daftar D-1 dan JSON ubin byte-identik |
| A19 | `vfx_debu_roda.png.import` | `compress/mode=0` jadi 2 | uji pasang: impor Lossless |
| A20 | `tile_perumahan_rumput_1.png.import` | mipmap true | uji pasang: tanpa mipmap |
| A21 | `ubin_perumahan.py` | polisi tidur lama diekspor lagi | uji gelombang 1: tidak lagi menghasilkan polisi tidur |
| A22 | `properti.py` | kilau kuning dominan, krem hanya tengah | kilau: krem >= 60% dan kuning 1..5 (9 gagal) |
| A23 | `properti.py` | tong biru jadi hijau | tong: warna dasar hijau |
| A24 | `properti.py` | tong logam berdasar #969AA0 | tong: warna dasar bukan RADAR_BUKAN, jarak token 0 |
| A25 | `properti.py` | tong biru berwarna OK #56C46E | warna di luar palet induk, dasar hijau, dekat token |
| A26 | `tile_perumahan.json` | memuat ubin yang tidak dipasang | uji pasang: JSON byte-identik dan `tiles` |
| A27 | `lembar_vfx_x5.png` | satu piksel mock docs diubah | uji gelombang 1: mock docs beda dengan render |
| A28 | `tests/data/ubin_potongan_8_maju.png` | satu piksel referensi diubah | `tes_ubin`: susunan = referensi; Python: referensi = susunan assets |
| A29 | `prop_koran_putar.png` | satu piksel PNG terpasang diubah | uji pasang: piksel-identik dengan keluaran skrip |
Catatan: mutan awal A7 (`* 2 + 0` pada jangkauan) setara secara perilaku (hanya batas loop; cakupan ubin sama) dan diganti A7 di atas. Mutan bagian B (koran, bayangan, terlipat, VFX, bintang, koin, kilau game) menyusul di iterasi 1 bagian B.

### Iterasi 1, bagian B (Dev): koran, efek, kilau, probe, dokumen
Commit: `928a83a` feat (kode D-3 sampai D-6), `2e16de0` test (tes baru), `8160265` feat (probe + perbaikan tekstur + tangkapan), `4b33654` test (terlipat tidak bocor), dan commit docs bagian B.
- **Rancangan (D-7): mode sprite per node, bukan penggantian kode.** `jalan_uji.tscn` (dev scene, tidak disentuh) memakai skrip yang sama (`KoranGambar`, `UmpanBalikSepeda`/`PancaranPiksel`), jadi pola koran dan partikel kode TIDAK dibuang (masih dipakai jalan uji dan tes lamanya, yang tidak diubah). `rute.tscn` menyalakan sprite: `KoranGambar.pakai_sprite = true` (dua node, `rute.tscn`), `UmpanBalikSepeda.atur_sprite(true)` (dipanggil `RuteMain._siapkan_dunia`; dua `PancaranPiksel` dimatikan: tersembunyi, `PROCESS_MODE_DISABLED`, laju 0). Yang dibuang karena tidak ada pemakai lain: `PolaPiksel.KILAU_KUCING_1/2`, `KucingHiasan.perintah` dan `perintah_kilau` (kilau kini `item_kilau`, ekor `perintah_ekor`, bar progres tetap); `TampilMisi.rect_badan` memakai `Config.MISI_KILAU_KOTAK_PX` [11, 11] (angka sama, tes tidak berubah). `PolaPiksel.KORAN_PUTAR`/`pola_koran` dan `tile_graybox_*` TETAP (jalan uji, graybox, tes lama).
- **Tes lama yang diganti (alasan, D-7):** hanya `tes_misi_scene.gd` (pola kilau 9x9 dan 11x11, `perintah_kilau`, `perintah(...)` dengan kilau): diganti padanan untuk sprite (item `mission_kilau` frame 0/1, sel 9x9 dua frame, kotak 11x11 pojok (-5, -33), pojok sprite (-4, -32)), `perintah_ekor`, `perintah_progres`; jumlah `check` di blok itu tidak turun. Catatan: frame kilau ke-2 dulu 11x11, kini kedua frame 9x9 (aset gelombang 1). `probe_misi_jendela.gd` menyesuaikan satu baris cetak. Semua tes lain lulus tanpa diubah (tes koran, umpan balik, rintangan, hud, misi).
- **Modul baru (satu tanggung jawab per berkas):** `DefSprite` (sel, frame, pijak 13 sprite dari `Config.SPRITE_*`, dites = JSON + ukuran PNG; region, pojok, `frame_loop`, `frame_sekali`), `PermukaanKoran` (pemetaan permukaan + titik diam kotak surat), `SpriteKoran` (frame bayangan = frame yang lebarnya terdekat dengan `KoranLempar.lebar_bayangan_px`, item tanah dan udara), `VfxSepeda` (debu dan garis; kapan tampil tetap dari `UmpanBalikKecepatan` yang TIDAK diubah), `VfxAntaran` (koin sprite hanya bila tip = `UMPAN_KOIN_TIP_SPRITE_NILAI` 5, bintang 15 fps, koin 10 fps), `GambarSprite` (ui), `VfxSepedaGambar`. Field turunan `KoranLempar.Koran.permukaan` dan `titik_diam` (hasil, antaran, penanda, id_rumah, tepat tidak berubah; dites 1000 lemparan acak berseed terhadap penilaian ulang dari `ZonaSasaran`). `SkorRute`, `UmpanBalikKecepatan`, `UmpanMelayang`, `ThrowSolver` tidak diubah (`git diff` kosong; tes skor 60 rute 1500/300480/23110/122).
- **Konstanta baru di `config.gd`** (satu baris, literal, komentar satuan): `SPRITE_*` (13 larik [lebar sel, tinggi sel, frame, pijak x, pijak y] + 3 indeks), `KORAN_PUTAR_PUSAT_ATAS_PX` 3, `KORAN_BAYANGAN_FRAME_LEBAR_PX` [10, 8, 6], `UMPAN_DEBU_SPRITE_FPS` 12, `UMPAN_GARIS_GANTI_MIN/MAKS_FRAME` 2 dan 3, `UMPAN_GARIS_SPRITE_BENIH` 3, `UMPAN_BINTANG_FPS` 15, `UMPAN_KOIN_TIP_FPS` 10, `UMPAN_KOIN_TIP_SPRITE_NILAI` 5, `MISI_KILAU_KOTAK_PX` [11, 11]. Angka tuning gameplay tidak ada yang berubah.
- **Temuan teknis penting (hanya terlihat di jendela asli):** semua sprite pertama kali tergambar sebagai persegi putih polos karena tekstur yang BARU dimuat (`load`) di dalam `_draw` tidak tergambar pada frame itu (Godot 4.7.2 Compatibility; direproduksi dengan skrip kecil, tekstur lain yang dimuat di dalam `_draw` juga putih). Tes headless tidak bisa melihatnya. Perbaikan: tekstur dimuat sekali di `_init`/`_ready` node pemilik dan dipegang node (`GambarSprite.muat`, kamus per node); tes menjaga jumlah tekstur yang dipegang (mutan B25).
- **Tambahan penerapan:** koran yang bertumpu di kotak surat digambar di lapisan UDARA (kotak surat ada di lapisan objek di atas lapisan TANAH, jadi koran di lapisan TANAH tertutup kotak). `RumahDaurRute.atur_terantar` dipanggil tiap langkah dari `RuteMain._perbarui_dunia` dengan `_skor.terantar` (hanya dibaca); terlipat memakai kolam sprite, anak induk Y-sort rumah, posisi tengah zona teras (`SpriteRumah.titik_teras_dunia`).
- **Probe `tests/probe_aset_jendela.gd`** (AC-21): 22 tangkapan per ukuran (`awal`, `tengah`, `terbang_rendah`, `mendarat_kotak_surat`, `terbang_tinggi`, `mendarat_teras`, `mendarat_rumput`, `mendarat_aspal`, `bintang`, `bintang_tip`, `bintang_tip_koin_naik`, `terlipat`, `terlipat_banyak`, `ngebut_aspal`, `ngebut_trotoar`, `rem`, `kidal_terbang`, `kidal_bintang`, `kilau_rumput`, `kilau_trotoar` + `_frame2`) di 2340x1080, 1920x1080, 2400x1080, 1600x720 ke `shots/iter1/` (88 PNG); keadaan tidak sesuai 0 di keempat ukuran; keluar lewat `ProbeKeluar`. Catatan lingkungan: jendela kadang kehilangan fokus dan menjeda (`PERINGATAN: layar jeda terbuka`, probe melanjutkan sendiri); `probe_koran_jendela.gd` sekali melaporkan 1 sasaran tidak ditemukan karena itu dan lulus di percobaan ulang (jalan uji tidak berubah oleh run ini).
- **Keraguan visual (jujur, dari tangkapan; tidak diedit tangan, dinilai di HP):** (1) bayangan koran 28% di aspal sangat samar (hampir tak terlihat di jalan gelap); di rumput dan trotoar lebih terbaca. (2) Debu roda dan garis kecepatan jauh lebih tipis dan jarang dari partikel lama: debu hanya beberapa kotak krem 1-2 px, garis satu varian 1-3 garis tipis alpha 70% x kekuatan; di ngebut 6,0 u/d garis nyaris hilang di aspal terang dan di atas trotoar. (3) Lajur hijau trotoar (kolom `trotoar_*`) berwarna sama keluarga dengan penanda centang dan kotak progres "terkirim" hijau di HUD; tidak ada tabrakan peran di tangkapan, tetapi perlu dinilai. (4) Koran terlipat jatuh di tengah zona teras (x -2,75), yang di beberapa sprite rumah jatuh di halaman di depan teras sprite (tangkapan `terlipat_banyak`, rumah kiri), di sprite lain di lantai teras; terbaca sebagai koran tergeletak, belum tentu "terantar". (5) Koin tip: tulisan "+5" di sprite dan label "+15" bisa bertumpang selama sekitar 0,2 detik (label naik 12 px selama 0,8 detik; sprite koin diam di 14-24 px di atas titik), tidak mengganggu di tangkapan. (6) Kilau di atas atap atau teras putih (kucing di teras) berkontras rendah; kecil (5x5 piksel terlihat) dibanding kilau lama 9x9/11x11. (7) Penanda TEPAT (sasaran 9x9) menutupi kepala kotak surat tempat koran bertumpu (sudah begitu sebelum run).
- **Tidak berubah / pengamatan lama:** `DEFERRED sel_tanah` (celah sudut di lebar 640 saat dorongan mundur terbesar) tetap, bukan akibat run ini. sha256 `user://save.json` asli sesudah semua tes, probe (semua probe lama dan baru), mutan, dan `--export-pack`: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e` (sama dengan awal).
- **Dokumen AC-20:** `ART_DIRECTION` (2.6 lebar jalan, 6.2, 6.3, 6.7, 6.9 status terpasang vs usulan, 11, Changelog), `tools/env_art/README.md` (sudah di bagian A), `AGENTS.md` (peta repo + perintah), `00-project-core.mdc` (perintah), `docs/README.md`, `docs/design/PROMPT_FASE5.md` (hasil), `docs/SETUP_ANDROID.md` 8.12 baru, `assets/LICENSES.md`. `DEV_PHASES`, `GDD`, `ROADMAP` tidak diubah.

### Mutan nyata bagian B (AC-22; satu perubahan, `run_tests.gd` penuh, `git checkout`; `git status` bersih sesudah tiap mutan dan sesudah semua)
| # | File | Perubahan satu baris | Tes yang gagal (pertama) |
|---|---|---|---|
| B1 | `permukaan_koran.gd` | kotak surat selalu `KOTAK_SURAT` (abaikan pelanggan seberang) | zona KOTAK_SURAT pelanggan_seberang false kolom 0: harapan T (9 gagal) |
| B2 | `permukaan_koran.gd` | halaman = teras | zona HALAMAN pelanggan_seberang true kolom 0: harapan R (19 gagal) |
| B3 | `permukaan_koran.gd` | tanpa zona: hanya rumput seberang yang rumput | tanpa zona di kolom RUMPUT_DEKAT: R |
| B4 | `permukaan_koran.gd` | `dari_zona` mengabaikan sisi seberang | kotak surat bukan pelanggan dan di sisi dekat: teras |
| B5 | `permukaan_koran.gd` | titik diam memakai indeks salah (`[2]`) | titik diam kotak surat = kaki kotak surat: 0 dari 3539 (4 gagal) |
| B6 | `sprite_koran.gd` | seri frame bayangan `<` jadi `<=` (tie ke frame sempit) | tinggi 0.5: lebar 9, frame 0 (6 gagal) |
| B7 | `sprite_koran.gd` | bayangan memakai rumus kedua (susut x0,5) | tinggi 0.76: lebar 8, frame 1 (10 gagal); (percobaan pertama dengan literal angka tertangkap pemindai angka ajaib, diganti rumus dari Config) |
| B8 | `sprite_koran.gd` | frame bayangan terbalik (`2 - frame`) | bayangan di lapisan tanah di titik tanah koran, frame dari tinggi |
| B9 | `koran_lempar.gd` | penanda berubah untuk halaman di `langkah` (field baru mengubah hasil) | 1008 lintasan x 2 sakelar: penanda = prediksi elips (4 gagal) |
| B10 | `rumah_daur_rute.gd` | terlipat untuk semua rumah pelanggan (belum terantar) | node lain di Objek: 16 (13 gagal) |
| B11 | `rumah_daur_rute.gd` | terlipat untuk rumah bukan pelanggan yang id-nya terantar | id bukan pelanggan dalam daftar terantar: tanpa terlipat |
| B12 | `rumah_daur_rute.gd` | terlipat dibuat ulang tiap langkah (`if perlu:`) | **HIDUP** pada tes awal (hitungan node dari kamus+kolam menyembunyikan kebocoran); tes diperkuat (`_hitung_node_terlipat` dari anak induk), kini: tepat satu node terlipat (11) |
| B13 | `vfx_sepeda.gd` | debu tampil `> 0` jadi `>= 0` | debu: 17 kasus ambang cocok tabel (4 gagal) |
| B14 | `vfx_sepeda.gd` | garis tampil saat kurangi efek | garis: mati saat kurangi efek |
| B15 | `vfx_sepeda_gambar.gd` | node efek `PROCESS_MODE_ALWAYS` (tidak membeku saat jeda) | JEDA: pohon dijeda, node efek tidak berproses (6 gagal) |
| B16 | `umpan_melayang.gd` | entri juga untuk antaran tidak sah | koran ulang (netral): tanpa umpan balik melayang |
| B17 | `vfx_antaran.gd` | koin sprite juga tanpa tip | koin_sprite: hanya tip 5 (5 gagal) |
| B18 | `umpan_melayang_gambar.gd` | baris tip label ganda (tetap tampil walau ada sprite koin) | label tanpa baris tip: `["+15\ntip +5"]` |
| B19 | `config.gd` | `UMPAN_KOIN_TIP_SPRITE_NILAI` 5 jadi 6 | KOIN_TIP = 5 = nilai yang dipanggang di sprite (11 gagal) |
| B20 | `config.gd` | `KOIN_TIP` 5 jadi 6 (sprite tetap dianggap 5) | `Config.KOIN_TIP = 5` (22 gagal) |
| B21 | `kucing_hiasan.gd` | kilau tampil tanpa petunjuk `kilau` | tanpa petunjuk kilau: tidak ada item |
| B22 | `kucing_hiasan.gd` | posisi kilau bergeser (geser tengah dua kali) | pojok sprite (-4, -32) = pojok kotak + geser tengah |
| B23 | `koran_gambar.gd` | `pakai_sprite` bawaan true (jalan uji ikut sprite) | tes koran jalan uji: node TANAH menggambar koran tergeletak (11 gagal) |
| B24 | `sprite_koran.gd` | pusat putar tidak diangkat 3 px | pusat koran putar berselisih <= 1 px dari pola lama |
| B25 | `vfx_sepeda_gambar.gd` | tekstur tidak dimuat di `_init` (kamus kosong; bug putih di `_draw`) | node efek sepeda memegang empat tekstur |
| B26 | `rumah_daur_rute.gd` | terlipat di titik kotak surat, bukan teras | terlipat di tengah teras seberang: posisi |
| B27 | `rute_main.gd` | `atur_terantar` tidak dipanggil | rumah @6 terantar: tepat satu koran terlipat (4 gagal) |
| B28 | `umpan_balik_sepeda.gd` | kurangi efek tidak diteruskan ke sprite | kurangi efek saat ngebut: garis mati, debu alpha x pengali |
| B29 | `vfx_sepeda.gd` | alpha debu kurangi efek terbalik | kurangi efek: debu tetap tampil dengan alpha 0,5 (3 gagal) |
| B30 | `vfx_sepeda.gd` | garis diacak ulang satu frame terlambat (`< 0`) | diacak ulang tiap 2 atau 3 frame: interval benar false |
Catatan: total run = 29 (bagian A) + 30 (bagian B) = 59 mutan, target >= 24 terpenuhi; mutan yang awalnya hidup (B12) diperkuat tesnya dan diulang (mati). Hasil mentah dijalankan skrip pembantu di folder sementara (bukan bagian repo). Yang belum tercakup mutan: tidak ada bagian AC-22 yang tersisa selain sebagian "ubin tidak dirujuk tapi disalin" yang ada di bagian A.

