# Loop Log — 20261018-fase4b-misi-kucing
Scope: Run 4B — misi P1 Kucing Bu Ratmi (template Cari), HUD misi dan banner, flag → headline lanjutan, rekap hasil, tutorial hari 1, save v2  ·  Branch: feat/misi-kucing-4b  ·  Mulai: 2026-10-18  ·  Godot: 4.7.2.stable

## Status: IN_PROGRESS   (iterasi saat ini: 1/2)

Baseline (main df57f88, sebelum perubahan, dari LOG 4A): `run_tests.gd` 13050 lolos, 0 gagal; `tools/cek_keluaran_tes.py` lolos. Dijalankan ulang oleh Dev di awal iterasi 1.

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 1 | Seluruh AC-1..AC-23: validasi Cari + banner, `RencanaMisi`, `MissionManager`, save v2 (konsumsi flag, `misi_hasil`, `tutorial`), `HeadlineManager.flag_terpakai`, kucing di rute (`KucingMisi`, aset lewat `kendaraan.py --salin`), HUD kartu/banner/gelembung, rekap hasil, hadiah 75 koin, tutorial terpandu, bunyi misi (`sintesis_misi.py`), probe 4 resolusi, dokumen | import bersih; `run_tests.gd` **14901 lolos, 0 gagal** (baseline 13050) dan `cek_keluaran_tes.py` lolos (0 peringatan); `--quit-after 2` tanpa ERROR/WARNING; `uji_pemeriksa` 16, `uji_bangun_frames` 51, `uji_sintesis_{sepeda,lempar,rute,misi}` 32/111/90/47, `uji_aset_kucing` 12 lolos; `--export-pack` 1,35 MB memuat sheet kucing, scene kucing dan tutorial, 4 WAV misi, skrip misi, tanpa tests/docs/tools/spike, pemuat dan rencana jalan dari paket di folder luar repo; probe 4 resolusi 0 keadaan tidak sesuai (52 tangkapan); 37 mutan Dev; git bersih | (menunggu QA) | | |

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## Mutan (AC-20, diisi Dev; QA mengulang sedikitnya 8)
Cara: skrip pembantu di scratchpad (empat salinan repo di folder sementara, tiap salinan dengan folder `user://` sendiri; repo asli tidak dimutasi dan `user://save.json` asli tidak tersentuh, sha256 sebelum = sesudah) mengganti SATU potongan kode asli, menjalankan `run_tests.gd`, mencatat `GAGAL:` pertama, lalu mengembalikan berkas. Hasil: 37 mutan, 36 MERAH, 1 ekuivalen. Untuk mutan yang menyisipkan angka literal, penjaga "tanpa angka literal" merah lebih dulu; mutan itu diulang dengan konstanta Config (nomor 34-37) supaya perilakunya yang ditangkap.

| # | Mutan (file, perubahan) | Tes yang merah | Dikembalikan |
|---|---|---|---|
| 1 | `mission_manager.gd` tangkap tidak mereset timer saat keluar radius atau terlalu cepat | 6 gagal: `keluar radius: timer kembali 0`, `kecepatan di atas ambang: timer kembali 0` | ya |
| 2 | `mission_manager.gd` ambang kecepatan tangkap terbalik (`>=`) | 78 gagal: `1,0 detik berturut-turut`, kelayakan BikeMotion, mode bantu | ya |
| 3 | `mission_manager.gd` timer maju saat jatuh (hanya jeda yang menahan) | 4 gagal: `tiga langkah jatuh di dalam radius: timer tetap 1,0` | ya |
| 4 | `mission_manager.gd` petunjuk dari lemparan tidak tepat | 1 gagal: `lemparan tidak tepat: tidak memberi petunjuk` | ya |
| 5 | `mission_manager.gd` petunjuk dari lemparan bantu | 2 gagal: `lemparan mode bantu (tap), walau tepat (K-3)` | ya |
| 6 | `mission_manager.gd` petunjuk berulang pada langkah yang sama | 1 gagal: `petunjuk tidak berulang (sekali per langkah)` | ya |
| 7 | `hasil_rute.gd` gagal mengurangi koin (literal 10) | 7 gagal (penjaga angka literal; diulang sebagai 34) | ya |
| 8 | `mission_manager.gd` `koin_misi` dibayar saat gagal | 10 gagal: `gagal: koin misi 0 dan kartu hilang`, hasil dan rekap | ya |
| 9 | `layar_hasil.gd` hadiah dihitung ulang di UI (+1 di rekap) | 3 gagal: `layar hasil memuat baris rekap 'Misi: Kucing ketemu! +75 koin'` | ya |
| 10 | `rute_main.gd` koin tambahan HUD +1 (HUD beda dari hasil) | 12 gagal: koin HUD = Angka.koin, alur A | ya |
| 11 | `data_save.gd` flag tidak dikonsumsi | 17 gagal: `konsumsi dulu lalu tambah`, rantai headline, alur A hari 3 | ya |
| 12 | `data_save.gd` flag baru ikut terhapus (konsumsi sesudah tambah) | 3 gagal: `flag baru hari ini tidak ikut terhapus` | ya |
| 13 | `hari_main.gd` simpan di tengah rute (tiap peristiwa misi memanggil `simpan`) | 10 gagal: `sampai layar hasil terbuka belum ada simpan sama sekali`, jumlah simpan | ya |
| 14 | `data_save.gd` `selesai` ditimpa `gagal` | 3 gagal: `hasil 'selesai' tidak ditimpa 'gagal'` | ya |
| 15 | `data_save.gd` migrasi menjatuhkan `flag` | 3 gagal: `flag v1 ... tidak dijatuhkan migrasi` | ya |
| 16 | `rencana_misi.gd` pakai `randi()` | 2 gagal: `benih sama = rencana sama` | ya |
| 17 | `hari_main.gd` kucing muncul walau misi dilewati (selalu aktifkan P1) | 10 gagal: Ambil/Lewati, skenario C | ya |
| 18 | `hari_main.gd` Berangkat tanpa memilih mengaktifkan misi (`!= LEWATI`) | 6 gagal: `Berangkat langsung dari belum memilih: misi_diambil kosong` | ya |
| 19 | `mission_manager.gd` batas 12 rumah x2 (literal) | 10 gagal (penjaga literal; diulang sebagai 35) | ya |
| 20 | `tutorial_langkah.gd` tutorial muncul di hari 2 (`>=`) | 2 gagal: `hari 2 walau tutorial.selesai false: tidak ada tutorial` | ya |
| 21 | `tutorial.tscn` panel tutorial memblokir input (mouse_filter STOP) | 1 gagal: `satu-satunya kontrol tutorial yang menerima sentuhan GUI adalah tombol Lewati` | ya |
| 22 | `data_misi.gd` panjang banner tidak divalidasi (literal 999) | 2 gagal (penjaga literal; diulang sebagai 36) | ya |
| 23 | `headline_manager.gd` jeda lanjutan menahan lanjutan (M-8) | 3 gagal: `lanjutan dengan flag aktif tetap muncul walau jeda headline-nya belum lewat`, rantai 40 hari | ya |
| 24 | `headline_manager.gd` `flag_terpakai` selalu kosong | 17 gagal: rantai selesai/gagal, alur A | ya |
| 25 | `mission_manager.gd` tangkap terlalu cepat (literal 1,3) | 20 gagal (penjaga literal; diulang sebagai 37) | ya |
| 26 | `mission_manager.gd` radius eksklusif (`<`) | 2 gagal: `jarak tepat 2,0 ubin: di dalam radius (inklusif)` | ya |
| 27 | `mission_manager.gd` langkah lihat tidak lagi memeriksa kucing sudah tampil | **LOLOS (EKUIVALEN)**: tampil selalu sudah true saat titik dilewati (ambang tampil 12 ubin di depan titik), jadi pemeriksaan itu tidak terjangkau; tidak dijadikan syarat tambahan | ya |
| 28 | `mission_manager.gd` jendela petunjuk: awal eksklusif | 5 gagal: `rumah tepat di awal jendela (0,0, inklusif) memberi petunjuk` | ya |
| 29 | `mission_manager.gd` jarak tampil dengan petunjuk diabaikan | 2 gagal: `detik_tampil ... dengan petunjuk 18 / 6 = 3 detik`, tampil lebih awal | ya |
| 30 | `mission_manager.gd` banner tidak membeku saat jeda | 3 gagal: `saat jeda game gelembung membeku`, banner | ya |
| 31 | `config.gd` hadiah sedang 60 | 23 gagal: `Config.MISI_HADIAH_KOIN = [45, 75, 120]`, hadiah, koin hasil | ya |
| 32 | `rencana_misi.gd` mengabaikan mobil garasi | 3 gagal: `tidak ada titik dalam 6 ubin dari mobil garasi seberang (60 seed)` | ya |
| 33 | `hari_main.gd` `tutorial.selesai` tidak ditulis | 3 gagal: `hari tutorial berakhir: tutorial.selesai true`, simpan di akhir hari | ya |
| 34 | `hasil_rute.gd` gagal mengurangi koin (`Config.KOIN_TIP`) | 6 gagal: `misi gagal: koin tetap 120 (tidak berkurang, hadiah 0)` | ya |
| 35 | `mission_manager.gd` batas 12 rumah bergeser satu kavling (`+ RUTE_PETAK_UBIN`) | 8 gagal: `maju 96,0: rumah ke-12 terlewati, tepat satu GAGAL` | ya |
| 36 | `data_misi.gd` banner divalidasi dengan batas 60 | 1 gagal: `banner selesai 25 karakter ditolak (panjang banner divalidasi)` | ya |
| 37 | `mission_manager.gd` tangkap tanpa menunggu 1,5 detik | 60 gagal | ya |

Daftar wajib AC-20 (20 butir) tercakup: timer tidak direset (1), ambang terbalik (2), jatuh (3), petunjuk tidak tepat (4), bantu (5), berulang (6), gagal mengurangi koin (7/34), koin_misi saat gagal (8), hadiah dihitung ulang di UI (9/10), flag tidak dikonsumsi (11), flag baru ikut terhapus (12), flag ditulis di tengah rute (13), selesai ditimpa gagal (14), migrasi menjatuhkan flag (15), `randi()` (16), kucing walau dilewati (17), Berangkat tanpa memilih (18), batas rumah (19/35), tutorial hari 2 (20), tutorial memblokir input (21), panjang banner (22/36). `git status` bersih sesudah semua mutan (dicek; satu-satunya perubahan sesudahnya adalah perbaikan `hud_rute.gd` yang sah, lihat bawah).

## NEEDS-MANUAL (uji di HP)
- [ ] Lihat SPEC bagian NEEDS-MANUAL; rincian dan lembar hasil di `docs/SETUP_ANDROID.md` 8.10. Poin khusus Dev:
- [ ] Kucing (sekitar 15 px, skala x3 = 45 px) terbaca di vivo V2108 dan A54; kilau 7x7/9x9 dan ekor cukup terlihat; di layar 640 kucing 12 ubin di depan baru muncul tepat di tepi kanan (hitung iso), jadi "2 detik terlihat pada ngebut" hanya tercapai penuh di layar lebih lebar.
- [ ] Menepi: ambang 1,5 u/d praktis hanya tercapai dengan rem (stick bawah penuh, sekitar 1,3 ubin sampai berhenti dari 3,0 u/d); radius 2,0 mungkin ketat; angka dinilai di HP.
- [ ] Petunjuk dari lemparan tepat: jarak lempar 5 ubin dan waktu terbang membuat petunjuk hanya berguna bila dilempar cepat; apakah terasa berguna dan tidak wajib.
- [ ] Batas 12 rumah; HUD kartu/banner tidak mengganggu radar dan bel; tutorial terbaca dan Lewati pas; bunyi meong/mrik/selesai/gagal.
- [ ] P1 di save 4A vivo tidak muncul (jeda sampai hari 8); jangan `pm clear` (SETUP_ANDROID 8.10 memuat opsi yang meminta izin pemilik).

## Keputusan & catatan
- Keputusan pemilik 2026-10-18: K-1 hadiah P1 75 koin (tingkat sedang) masuk hasil hari saat misi selesai; K-2 hanya flag `kucing_ketemu`/`kucing_belum`; K-3 mode bantu: stick tetap menangkap, lemparan bantu tidak beri petunjuk; K-4 kucing gagal hanya lewat headline lanjutan.
- Keputusan orchestrator M-1 sampai M-12 di SPEC (usulan, bisa ditolak di review).
- Catatan konflik: prompt run menyebut hadiah 45 koin; data dan GDD 10.6 menyebut tingkat sedang = 75. Pemilik memilih 75.
- HP vivo V2108 tersambung (adb 12d8c9da) saat run dimulai; belum disentuh. Save 4A pemilik ada di vivo: jangan hapus data app.
- Hasil uji HP 4A dan Fase 3: belum ada catatan.

### Catatan Dev iterasi 1 (penyimpangan, keputusan kecil, dan hal untuk ditinjau pemilik)
- **Petunjuk (M-3) diubah dari SPEC, usulan Dev, bisa ditolak:** (1) petunjuk berlaku untuk langkah mana pun yang BELUM dilewati yang jendelanya memuat rumah yang dilempar (jendela tiap langkah [rumah titik sebelumnya, rumah titik ini) tidak bertumpuk), bukan hanya langkah aktif; (2) syarat "kucing belum tampil" dibuang. Alasan (dihitung dan dibuktikan di probe): bila langkah aktif dan kucing belum tampil dipersyaratkan, jarak lempar 5 ubin + waktu terbang membuat petunjuk hampir mustahil (kucing tampil 12 ubin di depan, jendela hanya 12-16 ubin). Akibat: petunjuk selalu memberi gelembung + meong, dan membuat kucing tampil 18 (bukan 12) ubin di depan hanya bila kucing itu belum tampil.
- **P1 muncul lagi di hari 8, bukan 9** (S-4 jeda 7 dari hari diambil: 1 + 7 = 8; rantai 40 hari dites: hari 1, 8, 15, 22, 29, 36, lanjutan hari 2, 9, 16, 23, 30, 37 tepat sekali). Teks SPEC M-8 "hari 9+" tidak diikuti; GDD 10.3 hanya menyebut 7 hari.
- **M-8 mekanisme:** `jeda` headline `lanjutan` diabaikan saat memilih (flag yang dikonsumsi adalah gerbangnya); data `jeda: 30` dibiarkan.
- **Letak kucing digoyang berseed** (+-0,25 lateral dan maju, `MISI_KUCING_GOYANG_*`) supaya 60 rencana benar-benar berbeda (tanpa goyangan hanya 29-36 dari 60 karena rencana bergantung pada dua segmen pertama); tidak menimpa zona kotak surat (diuji 60 seed).
- **Kartu misi di y 50, bukan 40** (area sentuh jeda berakhir di y 46); tombol Lewati tutorial di strip atas (y 4, x 66) di luar zona swipe supaya tap di sana tidak melempar di mode bantu; panel tutorial di kolom kiri y 88.
- **`tutorial.selesai` ditulis true di akhir hari 1 bila tutorial berjalan hari itu** (selesai, dilewati, atau belum tuntas): tutorial hanya hari 1 jadi tidak ada gunanya mengulang; app ditutup di tengah rute = tidak ditulis, tutorial ulang.
- **Data misi punya field baru `banner` (`selesai`, `gagal`)** untuk semua template (kunci terjemahan, <= 24 karakter): DATA_SCHEMA 1 diperbarui. `Audio.putar_misi_peristiwa` menerima int karena autoload tidak boleh merujuk `MissionManager` (penjaga tes).
- **Rekap hasil** ditaruh di bawah daftar berhasil (selesai, hijau) atau di bawah daftar netral (gagal, netral).
- **Aset kucing:** sheet hanya lewat `kendaraan.py --salin`; render deterministik di mesin ini; mock PR #35 berselisih sekitar 100 piksel (drift numpy/pillow), tidak relevan ke game. `.import` WAV misi disetel tangan (`loop_mode=1`, `compress/mode=0`) seperti WAV lain.
- **Tes lama yang diubah (alasan di commit):** `SAVE_VERSI` 1 -> 2 dan bentuk templat/migrasi/terakhir (`tes_hari`); fixture misi dasar kini Cari valid + `banner` (`tes_headline`); lanjutan dengan flag aktif muncul walau jeda headline (M-8); `tes_alur_hari` (hari 1 menyelesaikan misi lewat langkah nyata: koin 195, flag kucing_ketemu, tutorial true; Ambil+gagal vs Lewati). Tidak ada tes dihapus atau di-skip; kunci `TUTORIAL_`, `HASIL_MISI_` ditambah ke penjaga kunci.
- **Penyimpangan kecil:** "adb: cannot connect to daemon" tercetak oleh `--export-pack` (hanya percobaan memulai adb); HP tidak disentuh. `user://save.json` asli: sha256 `258848de...` sebelum dan sesudah semua tes, probe, dan mutan.
- **Tidak dikerjakan (sengaja):** centang DEV_PHASES, "dikunci", ROADMAP 5 (struktur sesi, game over, target harian, misi lintas hari tetap terbuka), `allowBackup` (tetap pertanyaan pemilik di PR), pose/jejak kaki/mobil tamu bergambar (Fase 5), tinjauan budaya konten (teks 4B netral: kucing, warung).
- **Untuk PR (jangan diputuskan Dev):** (1) hadiah P1 75 (prompt run menyebut 45 = kecil; pemilik memilih 75); (2) petunjuk diubah (lihat atas); (3) P1 muncul lagi hari 8; (4) save v1 -> v2 dimigrasi, save 4A di vivo utuh; (5) Fase 3, Fase 4, M2 tidak dicentang; (6) `allowBackup`.
