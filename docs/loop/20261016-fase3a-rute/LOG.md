# Loop Log — 20261016-fase3a-rute
Scope: Run 3A Fase 3, fondasi rute (segmen JSON, RouteBuilder berseed, scene rute, zona dari data, penutup semi-transparan)  ·  Branch: `feat/fase3a-rute`  ·  Mulai: 2026-10-16  ·  Godot: 4.7.2

## Status: PASSED   (iterasi saat ini: 2/2; QA iterasi 2: QA-001, QA-002, QA-003, QA-006 a/b/c VERIFIED; QA-007 dan QA-008 (Minor/Nit baru) ditutup dengan tes QA; QA-004, QA-005, QA-009 DEFERRED; 0 Blocker/Major OPEN; NEEDS-MANUAL tetap, Fase 3 dan DEV_PHASES tidak dicentang)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 1a | Bagian A (logika murni): 9 segmen JSON, `SegmenRute`/`PemuatRute`/`RouteBuilder`/`PenutupPemain`, zona dari rute, `tes_rute.gd`; scene belum | ✅ import bersih; 7853 lolos, 0 gagal (`--ketat` 0 peringatan); `--quit-after 2` bersih; 4 `uji_*.py` lolos; `--export-pack` memuat 9 JSON | menunggu bagian B | 0 | 0 |
| 1b | Bagian B: `rute.tscn` jadi scene utama (rumah dan kotak surat dari data, jendela daur, zona dan mode bantu dari data rute, akhir rute + banner + Main lagi, penerap penutup tunggal), `AdeganJalan` dasar bersama, `tes_rute_scene.gd`, `probe_rute_jendela.gd`, dokumen | ✅ import bersih; 8117 lolos, 0 gagal (`--ketat` 0 peringatan); `--quit-after 2` bersih; 4 `uji_*.py` lolos; `--export-pack` memuat 9 JSON + `rute.tscn`, tanpa `tests/` dan `docs/`, rute dimuat dari paket; probe 2340x1080 dan 1600x720 bersih | menunggu | 0 | 0 |
| 1 (QA) | audit independen Agent 2: gerbang dijalankan ulang di repo dan klon bersih, 40 mutan QA, probe jendela 2340x1080 dan 1600x720, muat dari `.pck` | ✅ import bersih; 8117 lolos, 0 gagal (`--ketat` 0 peringatan; klon bersih sama); `--quit-after 2` bersih; 4 `uji_*.py` lolos; `--export-pack` 9 JSON, 0 `tests/` `docs/`; rute dimuat dari `.pck` | **FAIL** (1 Major) | 6 (1 Major, 4 Minor, 1 Nit) | 0 |
| 2 (Dev) | QA-001 (tes pilihan pelanggan bergantung seed, ketukan Main lagi dipindah ke tes permanen, `qa_repro_rute.gd` dihapus), QA-002 (tes titik tertutup literal, garis bidik redup di rute, `tertutup_pada` memakai medan), QA-003 (4 konstanta `Config`), QA-006 a, b, c; QA-004 dan QA-005 DEFERRED; QA-006 d dan e dicatat | ✅ import bersih; 8179 lolos, 0 gagal (`--ketat` 0 peringatan); `--quit-after 2` bersih; 4 `uji_*.py` lolos; `--export-pack` 9 JSON, 0 `tests/` `docs/` | **PASS** (QA iterasi 2) | 3 (1 Minor, 2 Nit; QA-007 dan QA-008 ditutup dengan tes QA) | 4 (QA-001, QA-002, QA-003, QA-006 a/b/c) |

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|
| QA-001 | 1 | Major | `scripts/systems/route_builder.gd:_cocokkan` (goyangan pilihan pelanggan), tes `tests/tes_rute.gd` | Pilihan pelanggan tidak dijaga bergantung pada seed. Mutan QA Q04 (`target.append(dasar + rng.randf_range(-G, G))` diganti `target.append(dasar)`, goyangan nol) **selamat**: `run_tests.gd` tetap 8117 lolos, 0 gagal. Akibatnya K-3 (pelanggan dipilih lewat RNG berseed rute) dan AC-5 (seed beda = rute beda) hanya terjaga lewat urutan segmen; dengan mutan itu, dua seed berurutan segmen sama memilih 25 pelanggan identik, dan konstanta `RUTE_PELANGGAN_GOYANG_UBIN` tidak dirujuk tes mana pun (`grep RUTE_PELANGGAN_GOYANG tests/` kosong). Reproduksi: terapkan mutan, `godot --headless --path . --script res://tests/qa_repro_rute.gd` -> `GAGAL: R1 ... (0 dari 210 urutan punya variasi)`; pada kode asli R1 lolos (122 dari 210 urutan segmen punya lebih dari satu himpunan pelanggan di 400 seed). Perbaikan yang diharapkan: tes di `tes_rute.gd` (atau pindahkan R1) yang menegaskan bahwa urutan segmen yang sama menghasilkan lebih dari satu himpunan pelanggan di sapuan seed, dan bahwa jarak antar pelanggan tidak seragam (ROUTE_DESIGN 3: rumah berurutan lalu sela panjang). | VERIFIED (QA iterasi 2) | `f03cecc`: `tests/tes_rute.gd:_test_pelanggan_bergantung_seed` (sapuan seed 1000..1399), `tests/tes_rute_scene.gd:_test_main_lagi_ketuk`; `qa_repro_rute.gd` (+ `.uid`) dihapus | `_test_pelanggan_bergantung_seed` (mutan Q04: 3 GAGAL), `_test_main_lagi_ketuk` |
| QA-002 | 1 | Minor | `scripts/systems/medan_koran.gd:51` (`tertutup_titik`), `scripts/entities/adegan_jalan.gd` (`_garis_bidik.tampilkan(..., _medan)`), `scripts/systems/koran_lempar.gd:tertutup_pada` | Tiga mutan QA selamat (0 tes gagal): Q11 jendela belakang `tertutup_titik` dari dua petak (8 ubin) jadi satu petak; Q22 `_medan` tidak diteruskan ke `GarisBidik.tampilkan` (titik redup garis bidik memakai rumah graybox jalan uji di rute); Q23 `KoranLempar.tertutup_pada` memakai medan null. Q11 bukan mutan setara: titik tanah (tinggi 0) di maju 10,3, lateral -5,5 tertutup rumah seberang berawal maju 6 (tapak maju 5,5 sampai 8,5, lateral -6 sampai -3; sinar ke kamera masuk tapak di maju 8,3 pada tinggi 1,8 < 2), padahal jendela satu petak [6,3; 14,3] terhadap `maju_ubin` rumah (6) melewatkannya. Akibat: elips TERTUTUP atau titik redup bisa salah di rute tanpa tes yang gagal. Perbaikan: tes literal untuk titik 4 sampai 4,5 ubin di depan awal kavling rumah, dan tes scene bahwa `GarisBidik` di rute menandai titik redup menurut rumah rute. | VERIFIED (QA iterasi 2) | `b6f3895` (hanya tes; kode produksi benar) | `tes_rute.gd:_test_medan_tertutup_titik` (Q11: 3 GAGAL, Q23: 2 GAGAL), `tes_rute_scene.gd:_test_garis_bidik_titik_redup` (Q22: 1 GAGAL, 30 titik salah) |
| QA-003 | 1 | Minor | `scripts/systems/pemuat_rute.gd:85,87,89`, `scripts/systems/route_builder.gd:198`, `scripts/systems/medan_koran.gd:51` | Angka ajaib baru di kode, melanggar `gdscript.mdc` ("tidak ada angka ajaib") dan `balancing.mdc`: minimal 2 pembuka dan 2 penutup (`< 2`, AC-1) tertanam di `periksa_kumpulan`; `RUTE_SEGMEN_PER_RUTE - 2` (pembuka + penutup) di dua tempat; `RUTE_PETAK_UBIN * 2` (jendela belakang penutup) di `medan_koran.gd`. Pemindai literal di `run_tests.gd` meloloskan angka 2. Perbaikan: konstanta `Config` (mis. `RUTE_PEMBUKA_MIN`, `RUTE_PENUTUP_MIN`, `RUTE_SEGMEN_PENGAPIT`, `RUTE_PENUTUP_JENDELA_BELAKANG_PETAK`). | VERIFIED (QA iterasi 2) | `cc5ee6b` (konstanta di `config.gd`, `BALANCING.md` 6b) dan `b6f3895` (tes) | `tes_rute.gd:_test_konstanta_pengapit`, `_test_kumpulan`, `_test_medan_tertutup_titik` (mutan nilai 1: 3, 2, 546, 4 GAGAL) |
| QA-004 | 1 | Minor | `scripts/entities/rute_main.gd:_lempar_diizinkan` (D-17) | Perilaku di luar SPEC: sesudah garis akhir, swipe dan tap bantu baru ditolak dan garis bidik disembunyikan. K-5 dan AC-14 hanya meminta stick dikunci dan koran yang sudah terbang tetap dinilai. Dev mencatatnya sebagai D-17 (bukan diam-diam), tetapi ini keputusan perilaku yang menyentuh area "struktur sesi" (ROADMAP 5, M2) tanpa persetujuan pemilik. Tes menjaga perilakunya (M29), jadi bukan bug; perlu konfirmasi pemilik (ganti `_lempar_diizinkan` bila tidak diinginkan). | DEFERRED (menunggu keputusan pemilik) | tidak diubah, rekomendasi di Keputusan & catatan | M29 tetap menjaga perilaku sekarang |
| QA-005 | 1 | Minor | `scripts/entities/rumah_daur_rute.gd:_pasang`, aset `house_perumahan_*_pelanggan` | Dua kotak surat per rumah pelanggan (D-16): kotak merah di teras sprite dan kubus oranye graybox di pusat zona; lihat `shots/qa/2340x1080_rute_tengah.png` dan `..._bantu_centang.png`. Sasaran sebenarnya (zona, penanda centang) hanya kubus oranye yang berdiri di trotoar, jadi kotak merah yang tampak seperti kotak surat bukan sasaran. Dev sudah melaporkan dan SPEC melarang menyentuh aset; keputusan akhir ada di pemilik/art (`tools/env_art/fase3.py`). | DEFERRED (menunggu keputusan pemilik) | tidak diubah, rekomendasi di Keputusan & catatan | (tidak ada; aset) |
| QA-006 | 1 | Nit | beberapa | (a) `SegmenRute._nama_sah`: `id` dengan akhiran baris baru (`"per_x\n"`) lolos `parse` karena `$` PCRE mencocokkan sebelum `\n` akhir (diverifikasi, `galat=[]`); pakai `\z`. (b) `PemuatRute`/`RuteMain._susun`: bila memuat gagal hanya `push_error`, pemain melihat jalan kosong tanpa pesan di layar. (c) `RumahDaurRute._tekstur_untuk`: `load()` PNG pertama kali jenis rumah muncul terjadi di tengah frame (12 PNG saja, risiko patah kecil); bisa dimuat di `atur_rute`. (d) Tidak ada penanda garis akhir di dunia (hanya banner sesudah lewat); sepeda berhenti 1,4 sampai 4,5 ubin lewat garis di tanah kosong. (e) Branch 15 commit, 90 berkas (`git-workflow.mdc`: satu branch satu topik yang bisa di-review sekali duduk); diterima sebagai run 3A. | VERIFIED (a, b, c, QA iterasi 2); (d) DEFERRED ke Run 3C; (e) diterima | a, b, c: `b2663d9`. d dan e tidak dikerjakan (perintah orchestrator) | a: `tes_rute.gd:_test_segmen_sah_dan_mutan` (`id_baris_baru`, `titik_nama_baris_baru`; mutan `$`: 2 GAGAL); b: `tes_rute_scene.gd:_test_galat_muat_terlihat` (mutan tanpa banner: 2 GAGAL); c: `_test_tekstur_dimuat_di_atur_rute` (mutan tanpa muat awal: 2 GAGAL) |
| QA-007 | 2 | Minor | `scripts/systems/medan_koran.gd:51` (`tertutup_titik`, jendela depan `+ RUTE_PETAK_UBIN`), tes `tes_rute.gd:_test_medan_tertutup_titik` | Mutan QA N16 (jendela depan `maju + float(PETAK)` jadi `maju`) **selamat** (8179 lolos, 0 gagal). Bukan setara: tapak rumah seberang mulai 0,5 ubin sebelum awal kavling (`maju_ubin`), jadi titik di lateral -5,5, maju 5,7 untuk rumah di awal 6 ada DI DALAM tapak (tertutup), tetapi rumah itu berada di depan titik dan terlewat bila jendela depan nol. Semua titik uji Dev berada di maju >= awal kavling. Kode produksi benar; hanya celah tes (sejenis QA-002). | VERIFIED (kode benar; tes ditambah QA) | tidak ada perubahan kode produksi | `tes_rute.gd:_test_medan_tertutup_titik` dua baris `kasus` baru (5,7 tertutup; 5,4 tidak); mutan N16: 1 GAGAL |
| QA-008 | 2 | Nit | `scripts/entities/rute_main.gd:lapor_galat_ke_log` (D-25) | Mutan QA N14 (bawaan `lapor_galat_ke_log` true jadi false) **selamat**: tidak ada tes yang menjaga bahwa galat rute dicatat ke log developer secara bawaan; hanya tes yang boleh mematikannya. Kode benar. | VERIFIED (kode benar; tes ditambah QA) | tidak ada perubahan kode produksi | `tes_rute_scene.gd:_test_galat_muat_terlihat` satu `check` baru; mutan N14: 1 GAGAL |
| QA-009 | 2 | Nit | `scripts/systems/route_builder.gd:_cocokkan` | Mutan QA N01 (goyangan target satu arah `randf_range(0, G)` bukan `(-G, G)`) selamat: tes menjaga goyangan bukan nol (QA-001) tetapi tidak simetri. Efek: pelanggan sedikit bergeser maju secara sistematik, rata-rata jarak tetap 8,5 sampai 9,8 dan celah <= 20 (tidak melanggar AC). Dicatat, tidak ada perubahan. | DEFERRED (Nit, dicatat saja) | tidak ada | (tidak ada) |

## NEEDS-MANUAL (uji di HP)
- [ ] Rute dari awal sampai garis akhir tanpa patah, 60 fps, memuat < 1 detik; tiga seed berbeda tidak terasa dihafal.
- [ ] Kotak surat kena dengan sengaja di santai/cepat/ngebut; mode bantu mengenai kotak surat pelanggan terdekat.
- [ ] Objek penutup semi-transparan terbaca; rumah dan kotak surat tajam di ×3.
- [ ] Banner "Rute selesai" dan tombol "Main lagi" terbaca dan tidak tersentuh tak sengaja.
- [ ] Hasil uji HP Fase 2 (SETUP_ANDROID 8.5) belum diisi pemilik; Fase 2 dan M1 tetap tidak dicentang.
- [ ] (QA) Urutan gambar rumah `dekat` vs sepeda di lateral +1 sepanjang satu rumah dekat: di probe jendela 2340x1080 tidak ada tumpang tindih salah (QA melihat d = -3 sampai +3 ubin), tetapi perlu dilihat sambil berjalan di HP.
- [x] (QA) Bedakan kotak surat merah (sprite) dan kubus oranye (sasaran) (QA-005): kotak merah dihapus dari 3 sprite rumah pelanggan seberang pasca-PASS (D-25); tinggal dinilai pemilik di HP bahwa satu kubus oranye per rumah jelas sebagai sasaran.
- [ ] (QA) Rute yang sama dimainkan tiga seed berturut-turut: semua 5 segmen tengah selalu dipakai (hanya urutan, pembuka, penutup, dan pelanggan yang berubah); nilai apakah terasa dihafal.

## Keputusan & catatan
- Keputusan pemilik 2026-10-16 ("ok semua"): K-1 segmen JSON; K-2 9 segmen, 7 per rute, 25 pelanggan, koran awal 30; K-3 id rumah `<id_segmen>@<pos>`, pemetaan ke save ditunda ke Fase 6; K-4 scene baru `scenes/rute/rute.tscn`, jalan uji tetap dev; K-5 akhir rute berhenti + banner sementara + "Main lagi" dev. Rincian di `SPEC.md`.
- Pemilik belum menjalankan uji HP Fase 2; 3A dimulai tanpa hasilnya.
- **Menunggu keputusan pemilik (dari iterasi 2, tidak diubah Dev, muncul di laporan akhir):**
  - **QA-004 (D-17, lemparan ditolak sesudah garis akhir).** Dev memilih menolak swipe dan tap bantu sesudah akhir rute (SPEC K-5/AC-14 hanya meminta stick dikunci dan koran terbang tetap dinilai); ini menyentuh struktur sesi (ROADMAP 5). **Rekomendasi: pertahankan perilaku sekarang** sampai 3C (layar hasil) menggantikan akhir rute; pemain yang berhenti 1,4 sampai 4,5 ubin lewat garis tidak punya sasaran dan koran baru tidak berarti. Bila pemilik ingin boleh melempar terus: ganti `RuteMain._lempar_diizinkan` menjadi `return true` dan sesuaikan tes M29 (dua pemeriksaan di `tes_rute_scene.gd:_test_akhir_rute`).
  - **QA-005 (D-16, dua kotak surat per rumah pelanggan).** Kotak merah di teras sprite bukan sasaran; kubus oranye graybox di pusat zona adalah sasaran, jadi pemain bisa mengincar kotak yang salah. **Rekomendasi: render ulang aset rumah pelanggan tanpa kotak surat di teras** (`tools/env_art/fase3.py`, `kotak=False` pada `house_far_v`, lalu `--salin`) supaya hanya satu kotak surat terlihat, dan kubus graybox diganti sprite kotak surat final di run seni; bukan edit PNG. Putuskan sebelum uji HP SETUP_ANDROID 8.6 butir 4.
- Lingkungan (2026-10-16): Godot 4.7.2, Java 17, `main` = `origin/main` = `51aaedf`, vivo V2108 (`12d8c9da`) tersambung, A54 tidak.

## Catatan Dev iterasi 1a

Bagian A (logika murni, dites headless). Scene, `project.godot`, `translations/`, `AGENTS.md`, `docs/README.md`, dan `00-project-core.mdc` tidak disentuh (bagian B). Tidak ada temuan QA yang dikerjakan (belum ada).

### Commit (branch `feat/fase3a-rute`, tidak di-push)

| Commit | Isi |
|---|---|
| `41e7277` feat: segmen rute perumahan JSON dan validasinya | 9 `per_*.json`, `SegmenRute`, `PemuatRute`, konstanta `RUTE_*` di `config.gd`, `DATA_SCHEMA.md` 3 dan 5 |
| `82ce78a` feat: RouteBuilder | `RouteBuilder`, `BALANCING.md` 4, 6 (bagian 6b baru), 10, `ROADMAP.md` 5 |
| `893349d` feat: zona sasaran dari data rute dan aturan penutup pemain | `ZonaSasaran.zona_rumah_*`/`zona_rute*`, `PenutupPemain` |
| `302b8d6` test: tes rute | `tests/tes_rute.gd` (+ `.uid`), didaftarkan di `run_tests.gd` |
| (commit berikutnya) test: exclude_filter | `_test_data_ikut_paket` di `tes_rute.gd` |

### Nama kelas dan berkas final

| Kelas | Berkas | Tugas |
|---|---|---|
| `SegmenRute` (+ `Rumah`, `Objek`, `TitikMisi`, `Hasil`) | `scripts/systems/segmen_rute.gd` | Data bertipe dan validasi: `SegmenRute.parse(Dictionary) -> Hasil{segmen, galat}`; segmen null bila ada galat |
| `PemuatRute` (+ `Kumpulan`) | `scripts/systems/pemuat_rute.gd` | `muat_folder(folder) -> Kumpulan{segmen, galat}`; `baca_teks` satu-satunya pembaca berkas; `parse_teks`, `periksa_kumpulan` murni |
| `RouteBuilder` (+ `Rute`, `RumahRute`, `ObjekRute`, `TitikMisiRute`, `Hasil`) | `scripts/systems/route_builder.gd` | `bangun(benih, pustaka) -> Hasil{rute, galat}`, `koran_awal(n)`, `periksa_rute`, `jarak_pelanggan` |
| `PenutupPemain` (+ `Objek`) | `scripts/systems/penutup_pemain.gd` | `menutupi`, `indeks_menutupi`, `alfa`, `tapak_rumah`, `dari_rumah` |
| `ZonaSasaran` (tambahan) | `scripts/systems/zona_sasaran.gd` | `zona_rumah_seberang`, `zona_rumah_dekat`, `zona_rumah(RumahRute)`, `zona_rute`, `zona_rute_rentang`; `Zona.id_rumah` baru |
| `TesRute` | `tests/tes_rute.gd` | 1.171 pemeriksaan |
| Data | `assets/data/routes/perumahan/per_buka_01..02`, `per_tengah_01..05`, `per_tutup_01..02` | 9 segmen |

### Keputusan Dev

- **D-1 (struktur variasi, konsekuensi K-2 + AC-1).** 9 segmen = 2 pembuka + 5 tengah + 2 penutup, dan satu rute memakai 7 segmen (1 pembuka, 5 tengah, 1 penutup), jadi **semua 5 segmen tengah dipakai di setiap rute**. Variasi antar seed = urutan tengah (72 dari 120 permutasi tanpa dua padat berurutan) x 2 pembuka x 2 penutup = 288 susunan, ditambah pilihan 25 pelanggan dari 31 sampai 32 kandidat. Terukur: 400 seed memberi puluhan sampai ratusan urutan berbeda (tes: paling sedikit 100). Bila uji HP tiga seed terasa dihafal, tambah segmen tengah (DEV_PHASES: 8 sampai 10 segmen); kode tidak perlu berubah.
- **D-2 (geometri).** `pos` = awal kavling (sama dengan `indeks x 4` di jalan uji), zona dihitung relatif `pos` dengan `Config.JALAN_UJI_*` yang sama (satu geometri, tanpa angka baru). Rumah seberang di `pos` 2, 6, 10, ... sampai `panjang - 2` (rumah sesisi berjarak 4 ubin), rumah dekat di `pos` 4, 8, ...; tiap segmen kelipatan 4 supaya grid petak tidak bergeser di sambungan.
- **D-3 (validasi tambahan di luar daftar AC-2/AC-3).** Field tidak dikenal ditolak; satu `pos` hanya satu rumah per segmen (kedua sisi) supaya id `<id_segmen>@<pos>` unik tanpa sisi; rumah sesisi berjarak paling sedikit 4; rintangan paling dekat 3 ubin ke tepi (setengah jendela 6, supaya sambungan dua segmen tidak menumpuk keputusan; diuji juga di seluruh rute lewat `periksa_rute`); `tanda_ubin` wajib dan paling sedikit 9 (1,5 detik pada ngebut, ROUTE_DESIGN 4 aturan 2); titik misi harus di rumah (pos dan sisi sama) dan di luar jendela 6 ubin dari rintangan (ROUTE_DESIGN 6); `tag.sisi_pelanggan` dari `seberang`/`dekat`/`dua_sisi`; distrik `perumahan` menolak `sisi_pelanggan` bukan `seberang`.
- **D-4 (jenis).** `rumah.jenis` memakai nama bentuk aset: seberang `limasan`/`pelana`/`sayap`, dekat `dekat_limasan`/`dekat_pelana_lintang`/`dekat_pelana_sejajar`; sprite = `house_perumahan_<jenis>_<pelanggan|bukan>`. `objek.jenis` hanya `anjing_penjaga` dan `mobil_garasi` (props seperti tong sampah belum punya aset). Tempat rintangan tidak diikat ke rumah (tidak ada aturan "rintangan harus di depan rumah").
- **D-5 (pemilihan pelanggan).** Tepat 25 dari kandidat (rumah seberang `pelanggan_boleh`), target posisi disebar rata dari kandidat pertama ke terakhir + goyangan acak plus minus 3,0 ubin, lalu pencocokan berurutan terbaik (DP, jumlah selisih mutlak terkecil). Dipilih ketimbang undian acak murni karena rata-rata jarak dan celah terjaga tanpa penolakan berulang. Bila celah > 20 ubin, goyangan diundi ulang (maks 200). Hasil 1000 seed: jarak rata-rata 8,83 sampai 9,33 (rata-rata 9,17), celah 4 sampai 20, tidak ada seed gagal. Celah terpanjang tepat 20 muncul (batas AC-7 tidak dilonggarkan).
- **D-6 (tidak ada rata-rata "tepat 9").** Jarak rata-rata ditentukan data: pelanggan pertama di maju 6 dan terakhir sekitar 10 ubin sebelum garis akhir, jadi (panjang - 16) / 24. Tes memakai batas 7,5 sampai 10,5 per rute dan 8,5 sampai 9,8 untuk rata-rata 20 rute.
- **D-7 (koran awal).** `pelanggan + ceil(pelanggan x 20 / 100)` dengan bilangan bulat (hindari `x 1,2` float); `Config.RUTE_KORAN_PERSEN_PENUH` 100 ditambah karena pemindai "tanpa angka literal" menolak `/ 100.0` di kode. Tabel tes: 25 -> 30, 10 -> 12, 11 -> 14, 1 -> 2, 0 -> 0.
- **D-8 (`PenutupPemain`).** Pola `ZonaSasaran.tertutup_kotak` dengan titik kaki pemain (tinggi 0, titik paling mudah tertutup; titik lebih tinggi hanya tertutup bila kaki tertutup). Tapak rumah 3 x 3 ubin, tinggi 2,0, kaki fasad dekat di lateral 3,0: turunan dari aset `tools/env_art/perumahan.py` (88 sampai 94 unit, puncak atap 58 sampai 62 unit), konstanta `RUTE_RUMAH_*`. **Catatan geometri penting untuk B dan QA:** rumah di tepi jalan praktis tidak pernah menutupi pemain di lebar jalan resmi (sinar ke kamera dari lateral di bawah 1 butuh d >= 2 untuk sampai ke tapak, atap rumah 2,0), dites eksplisit (0 pemicu sepanjang rute). Aturannya umum untuk objek yang lebih dekat jalan (mobil, pohon, tenda; rintangan 3B). Bila di layar atap rumah dekat terlihat menimpa sepeda karena urutan Y-sort, itu soal urutan gambar, bukan aturan 3D ini; catat sebagai temuan/keputusan, jangan memperlebar aturan diam-diam.
- **D-9 (mode bantu).** `BantuLempar` tidak diubah: ia sudah menerima `daftar` zona. Di rute, daftar = `ZonaSasaran.zona_rute_rentang(rute.rumah, maju, maju + BantuLempar.jangkauan_maju_ubin(...))`. Tes murni: sepanjang 2 rute, tiga kecepatan, tiga posisi lateral, pilihan selalu kotak surat pelanggan seberang dari rute dan mendarat `SAH_PENUH`; sisi dekat tidak pernah memilih; 3 ubin sebelum tiap kotak surat pada santai sasarannya pelanggan itu (25 dari 25).
- **D-10 (data titik misi).** 4 titik contoh (`atap` x3, `balik_pot` x1) di segmen yang ada, hanya untuk membuktikan format; Fase 4 yang menentukan titik misi sebenarnya.
- **D-11 (jalan uji).** `zona_jalan_uji` kini memanggil `zona_rumah_seberang`/`zona_rumah_dekat` (satu geometri). Perilakunya identik (tes lama 6.682 pemeriksaan tetap lolos, ditambah tes kesamaan kavling 3 = rumah di awal 12). Scene dan tes lama jalan uji tidak diubah.
- **D-12 (isi paket).** `--export-pack` memuat 9 JSON dan tidak memuat `tests/` atau `docs/`. `tes_rute` memeriksa pola `exclude_filter` tidak mencocokkan berkas segmen. Belum terbukti: `DirAccess.get_files` terhadap folder segmen di APK/pck terpasang (hanya diuji di editor/headless dari resource); `PemuatRute.daftar_berkas` memakainya. Bagian B atau QA sebaiknya memuat rute dari pck (`godot --main-pack`) atau APK; bila daftar kosong di sana, ganti dengan daftar id tetap di `PemuatRute` (satu tempat).

### Tabel mutan

Mutan dibuat dengan mengubah kode produksi satu baris, menjalankan `run_tests.gd`, lalu memulihkan. "Mati" = jumlah `GAGAL:` baru.

| # | Apa dimutasi | Hasil | Tes yang mematikan |
|---|---|---|---|
| M1 | `_tanpa_padat_berurutan` selalu true | mati (198) | struktur: dua padat berurutan; sapuan 400 seed; periksa_rute |
| M2 | `_kocok` memakai `Array.shuffle()` (RNG global) | mati (10) | seed sama = rute sama; penjaga sumber tanpa shuffle/randi |
| M3 | `RUTE_PELANGGAN` 24 | mati (127) | tepat 25 pelanggan, id unik, Config literal |
| M4 | koran awal dibulatkan ke bawah | mati (4) | tabel `koran_awal` (11 -> 14, 1 -> 2, 4 -> 5, 26 -> 32) |
| M5 | `pelanggan_boleh` diabaikan | mati (487) | pelanggan = pos `pelanggan_boleh` literal; sapuan |
| M6 | offset segmen salah 1 ubin | mati (69) | panjang rute dan awal segmen = jumlah literal |
| M7 | rintangan di jalur `tengah` diterima | mati (2) | mutan `objek_jalur_tengah`, tiga pelanggaran sekaligus |
| M8 | jendela rintangan `<` jadi `<=` | mati (1) | batas `ok_objek_rentang_6` (selisih tepat 6 harus diterima) |
| M9 | `pos` tepi 2 ditolak | mati (504) | segmen dasar, batas panjang 24/40, mutan objek_pos_2, seluruh berkas nyata |
| M10 | halaman seberang memakai geometri dekat | mati (16) | koordinat zona literal; tes lempar lama |
| M11 | rentang zona tanpa petak cadangan | mati (1) | `zona_rute_rentang` literal (a@2) |
| M12 | titik pemain setinggi 1,0 (bukan kaki) | mati (6) | literal menutupi / tidak / tepi |
| M13 | `alfa` selalu 1,0 | mati (1) | alfa 0,45 / 1,0 |
| M14 | pilih 25 kandidat pertama saja | mati (21) | jarak rata-rata 6,7 sampai 7,0 di luar 7,5 sampai 10,5 |
| M15 | pelanggan di sisi dekat diterima | mati (1) | mutan `rumah_pelanggan_dekat` |
| M16 | id ganda tidak diperiksa | mati (1) | `periksa_kumpulan` id ganda |
| M17 | tanda < 9 diterima | mati (1) | mutan `objek_tanda_pendek` |
| M18 | `periksa_rute` tanpa cek celah | mati (1) | mutan celah 20,5 ubin |
| M19 | pemilih pelanggan tanpa batas celah | **awalnya selamat**, tes ditambah, kini mati (3) | seed 9004 dibangun (DP murni kadang > 20, retry diperlukan); pustaka dengan segmen 40 tanpa kandidat harus ditolak dengan "tidak ada pilihan pelanggan" |
| M20 | sisi rumah apa saja diterima | mati (2) | mutan `rumah_sisi_kiri`/`kanan` |

Mutan pertama yang membuat tes null-deref (M1, M5, M9) dipakai untuk menambah penjaga null di tes; tidak ada `SCRIPT ERROR` tersisa.

### Gerbang (dijalankan Dev)

- `godot --headless --import`: bersih (tanpa error).
- `godot --headless --script res://tests/run_tests.gd 2>&1 | tee build/tests.log`: **7853 lolos, 0 gagal** (dasar 6682 sebelum run; +1171).
- `python3 tools/cek_keluaran_tes.py build/tests.log` dan `--ketat`: lolos, 0 peringatan.
- `godot --headless --path . --quit-after 2`: 0 baris ERROR/WARNING.
- `python3 tools/tests_cek/uji_pemeriksa.py`, `uji_bangun_frames.py`, `uji_sintesis_sepeda.py`, `uji_sintesis_lempar.py`: lolos (alat tidak disentuh).
- `godot --headless --path . --export-pack "Android" build/kring-uji.pck`: 9 `assets/data/routes/perumahan/per_*.json` masuk, 0 berkas `tests/` atau `docs/`.
- Waktu `muat_folder` + `bangun`: 1,6 ms di mesin dev (batas 1000 ms, AC-8); 100 seed tanpa muat rata-rata < 50 ms (dites).

### BLOCKED

Tidak ada. Hal terbuka ROADMAP 5 tidak diputuskan: rumah dekat tetap placeholder `bukan` (data hanya menyatakan jenisnya), jendela tetap sakelar `JENDELA_KENA_BONUS` (tidak disentuh), struktur sesi dan game over tidak disentuh.

### Catatan untuk bagian B

- **Memuat dan menyusun:** `var k: PemuatRute.Kumpulan = PemuatRute.muat_folder()` lalu `RouteBuilder.bangun(Config.RUTE_SEED_DEV, k.segmen)`; "Main lagi" = seed + 1. Galat dikembalikan, bukan `push_error` (scene yang menampilkan atau menghentikan).
- **`Rute`:** `panjang_ubin` = garis akhir, `koran_awal` (30), `rumah` (kedua sisi, urut maju, `maju_ubin` = awal kavling, `pelanggan` true bila dipilih, `jenis`, `id`), `pelanggan` (25, urut), `objek` (rintangan ditandai, jangan digambar hidup di 3A), `titik_misi`, `awal_segmen`.
- **Gambar rumah:** sprite = `house_perumahan_<jenis>_<pelanggan|bukan>`; rumah seberang `pelanggan_boleh` yang tidak terpilih memakai `_bukan` (sama dengan rumah tidak boleh); rumah dekat selalu `_bukan`. `ground_anchor` sprite = tengah tapak (JSON aset); tapak graybox seberang mulai di maju `maju_ubin - 0,5` sepanjang 3,0 ubin dan kaki fasad lateral -3,0 (`JALAN_UJI_RUMAH_*`); kotak surat berada di lateral -1,625 (pusat zona), maju `maju_ubin + 1,125`. Posisi pijak sprite perlu dihitung dari tapak, bukan dari `maju_ubin` langsung.
- **Zona dan penilaian:** `ZonaSasaran.zona_rute_rentang(rute.rumah, maju_awal, maju_akhir)` (cache per langkah, bukan per frame penuh bila alokasi terasa); penilaian = `ZonaSasaran.klasifikasi(titik_mendarat, zona)`; mode bantu = `BantuLempar.pilih(sisi, posisi, v, v_lateral, jeda_lepas, lebar_viewport, zona)` dengan zona yang sama; jangkauan = `BantuLempar.jangkauan_maju_ubin(v, jeda_lepas)`. Koran habis tetap lewat `SisaKoran`, tanpa `isi_ulang_jalan_uji`.
- **Koordinat:** x jalan = lateral (negatif = seberang), y jalan = maju, dunia y = -maju (`ZonaSasaran.ke_jalan`).
- **Penutup:** satu simpul penerap: untuk tiap rumah di jendela daur, `PenutupPemain.dari_rumah(rumah)` -> `PenutupPemain.menutupi(posisi_pemain_dunia, objek)` -> `modulate.a = PenutupPemain.alfa(...)`. Lihat D-8 (praktis tidak pernah memicu untuk rumah; tes scene perlu objek uji yang dekat jalan untuk membuktikan penerapnya, mis. objek sintetis `PenutupPemain.buat(Rect2(...))`).
- **Teks dan scene:** `RUTE_SELESAI`, "Main lagi", banner: lewat `translations/ui.csv`; `run/main_scene`, `AGENTS.md` (peta repo), `docs/README.md` (status), `00-project-core.mdc` (perintah) belum diperbarui.
- **Tes lama:** tidak ada yang diubah selain `run_tests.gd` (satu pendaftaran `TesRute`). `tes_export.gd` tidak perlu diubah untuk data; pemeriksaan pola `exclude_filter` ada di `tes_rute.gd`.



## Catatan Dev iterasi 1b

Bagian B (scene rute, penerap penutup, akhir rute, teks, probe, dokumen). Tidak ada temuan QA yang dikerjakan (belum ada). Branch `feat/fase3a-rute`, tidak di-push.

### Commit (setelah `6180220`)

| Commit | Isi |
|---|---|
| `7f972b0` feat: logika murni scene rute | `JendelaRute`, `AkhirRute`, `SpriteRumah`, `MedanKoran`; parameter `medan` di `KoranLempar` dan `GarisBidik`; konstanta `RUTE_DAUR_*`, `RUTE_AKHIR_*`, `RUTE_BANNER_*`, `RUTE_RUMAH_SPRITE`, `RUTE_RUMAH_PIJAK_PX` |
| `177b439` refactor: AdeganJalan | gerak, jeda, lemparan, mode bantu, bunyi, HUD dipindah dari `JalanUji` ke `AdeganJalan` lewat kait; `SepedaUji.atur_ulang` |
| `6704238` feat: scene rute | `rute.tscn` (+ `panel_akhir_rute.tscn`), `RuteMain`, `RumahDaurRute`, `PenerapPenutup`, `PanelAkhirRute`, `project.godot` main scene, `RUTE_SELESAI` dan `RUTE_MAIN_LAGI` di `ui.csv` (+ `.translation`), tes lama yang menyatakan scene utama diperbarui |
| `020a28b` test: probe | `probe_rute_jendela.gd`; 6 probe lama memuat `jalan_uji.tscn` langsung |
| `1ae4c27` test | elips tertutup medan rute (mutan M39) |
| `0952311` docs | `AGENTS.md`, `00-project-core.mdc`, `content-data.mdc` (awalan `RUTE_`), `docs/README.md`, `ROADMAP.md`, `BALANCING.md` 6b dan 10, `SETUP_ANDROID.md` 8.6 |
| `62acbb9` docs | tangkapan layar `docs/loop/20261016-fase3a-rute/shots/` |

### Kelas dan berkas final

| Kelas | Berkas | Tugas |
|---|---|---|
| `AdeganJalan` | `scripts/entities/adegan_jalan.gd` | Dasar bersama (dipindah dari `JalanUji`, isinya sama): gerak, kamera, jeda, lemparan, mode bantu, bunyi, HUD. Kait: `_siapkan_dunia`, `_perbarui_dunia`, `_zona_bantu`, `_langkah_koran`, `_vektor_stick`, `_lempar_diizinkan`, var `_medan`; `_kembalikan_awal` |
| `JalanUji` | `scripts/entities/jalan_uji.gd` | Tinggal 3 kait (objek graybox berkala, zona jalan uji, isi ulang uji); API publik tidak berubah |
| `RuteMain` | `scripts/entities/rute_main.gd` | Scene rute: seed, `_susun`, `main_lagi`, akhir rute, sinyal `rute_selesai` dan `rute_disusun` |
| `RumahDaurRute` | `scripts/entities/rumah_daur_rute.gd` | Induk Y-sort: kolam sprite rumah dan kotak surat, jendela daur |
| `PenerapPenutup` | `scripts/entities/penerap_penutup.gd` | SATU penerap alfa objek penutup (`daftarkan`, `lepas`, `terapkan`) |
| `PanelAkhirRute` | `scripts/ui/panel_akhir_rute.gd`, `scenes/ui/panel_akhir_rute.tscn` | Banner dan tombol "Main lagi" |
| `JendelaRute`, `AkhirRute`, `SpriteRumah`, `MedanKoran` | `scripts/systems/*.gd` | Logika murni (lihat commit pertama) |
| `TesRuteScene` | `tests/tes_rute_scene.gd` | 264 pemeriksaan baru (7853 -> 8117) |
| Probe | `tests/probe_rute_jendela.gd` | Tangkapan layar rute |

### Keputusan Dev (lanjutan D-12)

- **D-13 (jangan menyalin `JalanUji`).** Logika `JalanUji` (340 baris) dipindah ke `AdeganJalan` dan dua scene mengisi kaitnya. Semua tes lama (jalan_uji.tscn) tetap hijau tanpa diubah. Alasan: perilaku lemparan, jeda, mode bantu, dan bunyi tidak boleh bercabang antar scene (prinsip "prediksi = hasil", D-6 mode bantu).
- **D-14 (`MedanKoran`, bukan pewarisan).** `KoranLempar.hasil_mendarat/prediksi_antaran/bentuk_elips/tertutup_pada/langkah` dan `GarisBidik.tampilkan` menerima `medan: MedanKoran = null`; null = jalan uji (perilaku lama persis). Medan rute = `MedanKoran.dari_rute(rute)`. Dicoba dulu `MedanRute extends MedanKoran`; ditinggalkan karena GDScript 4.7.2 membuat skrip `segmen_rute.gd` tertahan di akhir proses (`ERROR: 1 resources still in use at exit`) begitu sebuah skrip menugaskan `MedanRute.new()` ke variabel bertipe `MedanKoran` (direproduksi dengan skrip 3 baris). Satu kelas konkret menghindarinya. Catatan untuk QA: jangan memperkenalkan lagi pola ini.
- **D-15 (letak sprite rumah).** Sprite = `Sprite2D` tanpa `centered`, offset = -`ground_anchor`, posisi = tengah tapak `PenutupPemain.tapak_rumah` (seberang x -4,5, dekat +4,5; maju awal kavling + 1,0), jadi fasad jatuh di -3,03 (JSON aset: titik pijak = tengah tapak, fasad 47 unit dari tengah). Y-sort memakai titik itu (tidak ada `y_sort_origin`): di tiap tumpang tindih layar sepeda tergambar di depan rumah seberang dan rumah dekat di depan sepeda (dihitung di LOG; tidak ada tumpang tindih sprite-sepeda yang salah urutan terlihat di tangkapan). Titik pijak 12 sprite disimpan di `Config` (`RUTE_RUMAH_SPRITE`, `RUTE_RUMAH_PIJAK_PX`) karena pemindai "tanpa angka literal di luar config.gd" menolak tabel di `SpriteRumah`; tes membandingkannya dengan JSON dan ukuran PNG.
- **D-16 (dua kotak surat, TERBUKA untuk pemilik/art).** Sprite `house_perumahan_*_pelanggan` sudah memuat kotak surat merah di teras (di x -2,34, maju kavling + 0,25), sedangkan zona kotak surat (BALANCING 5, geometri jalan uji) di x -1,625, maju kavling + 1,125, selisih sekitar 51 px di layar. Agar sasaran yang terlihat = zona, rumah pelanggan juga memakai kotak surat graybox oranye (`kotak_surat_graybox.tscn`) di pusat zona, seperti jalan uji. Hasilnya dua kotak surat per rumah pelanggan (lihat `shots/*_rute_tengah.png`). Bukan keputusan desain final: perbaikannya lewat `tools/env_art/fase3.py` (`kotak=False` pada `house_far_v` atau kotak di zona) lalu render ulang, bukan edit PNG; tidak dikerjakan karena SPEC melarang menyentuh aset. Masuk checklist 8.6 butir 4.
- **D-17 (akhir rute).** `rute_selesai` dipancarkan pada langkah ketika jarak >= panjang (tepat sekali per rute). Sesudahnya `_vektor_stick` = stick buatan (0, -1) (`AkhirRute.stick_akhir`), jadi sepeda berhenti lewat `BikeMotion` biasa (tahan 0,25 detik lalu rem 5,0 u/d²; berhenti sampai sekitar 4,5 ubin lewat garis dari ngebut, 1,4 dari santai; di sana hanya tanah, tanpa rumah). Lemparan baru (swipe dan tap bantu) juga ditolak sesudah akhir, dan garis bidik tidak tampil: SPEC hanya menyebut stick dikunci, tetapi rute yang sudah selesai tanpa layar hasil sebaiknya tidak menerima koran baru; koran yang sudah terbang tetap mendarat dan dinilai (dites). Jari dilepas saat selesai (`KontrolTouch.lepas_semua`). Kalau pemilik menginginkan boleh melempar terus, ganti `_lempar_diizinkan`.
- **D-18 (banner dan tombol).** Tombol "Main lagi" hanya tampil sesudah akhir rute (tombol dev, tersembunyi supaya tidak tersentuh saat bermain), pojok kanan atas strip HUD (x dari kanan 8 px, y 4 px, ukuran tombol HUD 96 x 42), tidak bertumpuk dengan kidal, bantu, dan jeda, di luar zona stick dan swipe (`ZONA_SWIPE_Y_MIN_PX` = tinggi strip), kidal maupun tidak, di 640, 780, 800. Banner di tengah atas (y 64) di dalam area zona swipe tetapi mengabaikan sentuhan (`mouse_filter` ignore, dites): swipe yang mulai di atasnya tetap swipe; sesudah akhir rute swipe memang tidak melempar. Teks lewat `tr("RUTE_SELESAI")` dan `tr("RUTE_MAIN_LAGI")` di skrip (bukan `text` scene), kunci di `ui.csv`.
- **D-19 (penutup).** `PenerapPenutup` dipasang satu di `rute.tscn` (dites: satu simpul di seluruh scene), `RumahDaurRute` mendaftarkan tiap rumah yang muncul (kotak = `PenutupPemain.dari_rumah`) dan melepasnya saat dibuang; `RuteMain._perbarui_dunia` memanggil `terapkan(posisi sepeda)` tiap langkah. **Di rute nyata tidak ada kejadian menutupi**: 0 dari 357 posisi (lateral -1, 0, 1 x maju 0..236 tiap 2 ubin), sesuai D-8; aturan tidak diubah. Penerap dibuktikan dengan objek uji yang memang menutupi (alfa 0,45 lewat langkah scene, tepat di tepi lateral -1,0 = 1,0, -0,9 = 0,45) dan di probe (`*_rute_menutupi.png`: rumah uji 2 ubin lebih dekat ke jalan, sepeda terlihat tembus). Elips garis bidik TERTUTUP dan titik redup memakai kotak rumah rute kedua sisi (`MedanKoran.tertutup_titik`).
- **D-20 (zona tidak digambar).** `ZonaGambar` (zona placeholder berkala) tidak dipakai di rute: sprite rumah sudah punya teras dan halaman, dan zona data tidak berkala. Konsekuensi: halaman, teras, dan jendela tidak bertanda di tanah; hanya kotak surat oranye yang terlihat sebagai sasaran. Penanda kena/meleset dan elips garis bidik tetap. Jika pemilik ingin zona terlihat untuk uji HP, perlu penggambar zona dari data rute (belum ada).
- **D-21 (tes dan probe lama yang diubah, alasan: scene utama pindah ke `rute.tscn`).** `run_tests.gd` (`scene utama = rute.tscn`, `jalan_uji.tscn` tetap ada, awalan kunci terjemahan `RUTE_` diterima, pemindai probe menerima probe yang memuat `jalan_uji.tscn`), `tes_input_scene.gd` (butir "main_scene" kini rute.tscn + jalan uji tetap ada), `tes_cek_render.gd` dan `tools/ekspor_cek_render.py` (konstanta `SCENE_UTAMA` = rute.tscn), 6 probe jendela lama (memuat `jalan_uji.tscn` langsung karena mentransmisikan ke `JalanUji`). Tidak ada tes yang dihapus atau di-skip.
- **D-22 (D-12 terjawab).** `--export-pack` lalu `godot --headless --main-pack build/kring-uji.pck --script <skrip>` dari folder di luar repo: `res://tests` dan `res://docs` tidak ada, `PemuatRute.daftar_berkas` mengembalikan 9 berkas (`per_buka_01.json` ... `per_tutup_02.json`, nama asli, tanpa `.remap`/`.import`), `muat_folder` 9 segmen tanpa galat, `RouteBuilder.bangun(20261016)` = rute sah (236 ubin, 89 rumah, 25 pelanggan, koran 30), PNG sprite rumah termuat; `--main-pack ... --quit-after 5` membuka `rute.tscn` tanpa ERROR. `PemuatRute.daftar_berkas` tidak perlu diganti. Pemasangan di APK/HP tetap bagian uji HP pemilik (APK memakai format paket yang sama).
- **D-23 (jendela daur).** 20 ubin di belakang dan 30 di depan sepeda (`RUTE_DAUR_*`): 11 sampai 20 rumah sekaligus dari 89, node dipakai ulang dari kolam (paling banyak 30 node rumah dibuat, dites sepanjang rute). Jendela yang terlalu sempit akan terlihat sebagai rumah muncul di dalam layar; di 800 px terlebar belum terlihat di tangkapan 1600x720.

### Gerbang (dijalankan Dev, sesudah commit terakhir kode)

- `godot --headless --import`: bersih.
- `godot --headless --script res://tests/run_tests.gd 2>&1 | tee build/tests.log`: **8117 lolos, 0 gagal** (dasar 7853 sesudah bagian A; +264).
- `python3 tools/cek_keluaran_tes.py build/tests.log` dan `--ketat`: lolos, 0 peringatan.
- `godot --headless --path . --quit-after 2`: 0 baris ERROR/WARNING (scene utama `rute.tscn`).
- `python3 tools/tests_cek/uji_pemeriksa.py`, `uji_bangun_frames.py`, `uji_sintesis_sepeda.py`, `uji_sintesis_lempar.py`: lolos.
- `godot --headless --path . --export-pack "Android" build/kring-uji.pck`: 9 `per_*.json`, `scenes/rute/rute.tscn`, `scenes/ui/panel_akhir_rute.tscn`, 12 PNG rumah; 0 berkas `tests/` atau `docs/`; dimuat dari paket (D-22).
- Jendela asli: `probe_rute_jendela.gd` di 2340x1080 dan 1600x720: 0 keadaan tidak sesuai, tanpa ERROR/WARNING (keluar lewat `ProbeKeluar`); `tools/cek_blok_piksel.py` (skala 3 dan 2, teks HUD dikecualikan): 0 blok tidak seragam pada awal, tengah, dan akhir rute. Probe lama bantu dan koran dijalankan ulang: bersih.
- `godot --path . --quit-after 120` (tanpa jendela probe): `WARNING: 2 ObjectDB instances were leaked` dan `ERROR: 1 resources still in use` sama persis dengan `jalan_uji.tscn` (bunyi kayuhan masih berjalan saat proses dibunuh `--quit-after`, ProbeKeluar dibuat untuk ini); bukan regresi.
- Waktu memuat: `muat_folder` + `bangun` 1,6 ms (bagian A); scene rute siap dalam 5 frame di jendela probe.

### Tabel mutan (bagian B)

Cara sama dengan 1a (`build/mutan.py`, ubah satu baris, jalankan `run_tests.gd`, pulihkan). 20 mutan, 19 mati pada percobaan pertama.

| # | Apa dimutasi | Hasil | Tes yang mematikan |
|---|---|---|---|
| M21 | batas atas jendela daur eksklusif | mati (10) | tabel jendela literal (kedua ujung inklusif); jendela scene lawan pindai linear |
| M22 | sprite pelanggan dari `pelanggan_boleh` | mati (3) | nama sprite rumah seberang tidak terpilih; tekstur tiap rumah |
| M23 | sprite dipijak di `maju_ubin` bukan tengah tapak | mati (4) | posisi layar tiap rumah (rumus iso ditulis ulang) |
| M24 | zona bantu = zona jalan uji | mati (8) | mode bantu hanya pelanggan seberang dari rute; kisi |
| M25 | `_medan = null` (penilaian jalan uji) | mati (22, 1 SCRIPT ERROR) | zona dari data; kisi mode bantu; swipe |
| M26 | isi ulang koran jalan uji di rute | mati (2) | koran tidak diisi ulang 96 ubin sesudah habis |
| M27 | `baru_selesai` tiap pemeriksaan | mati (7) | tabel `AkhirRute`; sinyal tepat sekali |
| M28 | stick tidak dikunci sesudah akhir | mati (3) | berhenti walau stick ke atas ditahan |
| M29 | lemparan tetap diterima sesudah akhir | mati (2) | tap bantu dan swipe ditolak, garis bidik tidak tampil |
| M30 | Main lagi memakai seed yang sama | mati (2) | seed + 1 dan urutan segmen literal |
| M31 | penutup tidak diterapkan di langkah scene | mati (2) | objek penutup alfa 0,45 lewat `perbarui` |
| M32 | rumah tidak didaftarkan ke penerap | mati (3) | jumlah terdaftar = rumah digambar |
| M33 | Main lagi tidak mengembalikan koran | mati (1) | koran kembali 30 |
| M34 | kotak surat di semua rumah `pelanggan_boleh` | mati (4) | kotak surat hanya di rumah pelanggan |
| M35 | jendela daur terlalu lebar (maju 300) | mati (10) | jendela = oracle; bukan seluruh rute |
| M36 | `hasil_mendarat` mengabaikan medan | mati (9) | `KoranLempar.hasil_mendarat` medan rute lawan jalan uji; kisi |
| M37 | alfa penutup selalu 1 | mati (2) | alfa 0,45 |
| M38 | koran terbang dibuang saat selesai | mati (3) | koran masih terbang dan dinilai sesudah akhir |
| M39 | medan tertutup mengabaikan rumah dekat | **awalnya selamat**; tes ditambah, kini mati (2) | elips TERTUTUP di balik rumah dekat (titik literal), titik di dalam tapak seberang |
| M40 | tombol Main lagi tampil dari awal | mati (3) | banner dan tombol tersembunyi di awal rute |

### Cakupan SPEC bagian B (AC-10 sampai AC-19)

| AC | Bukti |
|---|---|
| AC-10, AC-11 | `_test_zona_dari_data`, `_test_bantu_kisi` (3 kecepatan x 7 pelanggan x 5 jarak x 3 lateral = 105 keadaan per kecepatan, lawan `BantuLempar.pilih` dengan zona SELURUH rute), `_test_swipe_dinilai_zona_rute` (36 swipe) |
| AC-12, AC-13 | `_test_rute_dari_data`, `_test_rumah_digambar`, `_test_jendela_daur_bergerak`, `_test_koran_tanpa_isi_ulang`; seed bawaan dari `Config.RUTE_SEED_DEV` |
| AC-14 | `_test_akhir_rute`, `_test_akhir_koran_terbang_dinilai`, `_test_main_lagi`, `_test_tata_letak_akhir` |
| AC-15 | `_test_penutup` + M31, M32, M37, M39 |
| AC-16 | `_test_jeda`, jeda dan back sesudah akhir di `_test_akhir_rute`; tes jeda lama tetap hijau lewat `AdeganJalan` |
| AC-17 | `Config` satu baris literal (pemeriksa format hijau); `BALANCING.md` 6b dan 10; `ui.csv` + `ui.id.translation` di-commit |
| AC-18 | gerbang di atas |
| AC-19 | `AGENTS.md`, `00-project-core.mdc`, `docs/README.md`, `ROADMAP.md`, `BALANCING.md`, `SETUP_ANDROID.md` 8.6. `DATA_SCHEMA.md` tidak berubah di bagian B. `DEV_PHASES.md` tidak dicentang; tidak ada yang ditandai "dikunci" |

### BLOCKED

Tidak ada. Hal terbuka ROADMAP 5 tidak diputuskan: rumah dekat tetap `_bukan` (placeholder), `JENDELA_KENA_BONUS` tidak disentuh, struktur sesi dan game over tidak disentuh (akhir rute hanya berhenti + banner dev).

### Catatan untuk QA dan uji HP

- Hal yang paling mungkin dinilai berbeda oleh QA: D-16 (dua kotak surat), D-17 (lemparan ditolak sesudah akhir), D-20 (zona tidak digambar), dan "tidak ada kejadian menutupi di rute nyata" (D-19).
- Perilaku yang perlu dilihat di jendela asli (bukan headless): urutan gambar rumah dekat vs sepeda saat sepeda di lateral +1 (tangkapan 1600x720 dan 2340x1080 tidak menunjukkan tumpang tindih yang salah), kotak surat oranye vs merah, banner di rasio 640 (hanya diuji lewat tes tata letak, bukan tangkapan).
- `AdeganJalan` besar (diperkaya komentar dari `JalanUji`); bila QA menemukan perilaku jalan uji berbeda dari sebelum 1b, itu regresi refactor (tes lama 6.682 pemeriksaan tetap hijau).
- `JendelaRute` mengandaikan `Rute.rumah` urut maju menaik (dijaga `RouteBuilder`: id `<id_segmen>@<pos>` dan pos unik per segmen, segmen berurutan); bila segmen berikutnya mengizinkan dua rumah di maju yang sama, pencarian biner tetap benar (inklusif) tetapi indeks yang sama maju bisa tertukar urutan Y-sort.
- Seed 20261016 dan 20261017 sama-sama 236 ubin dan 89 rumah (semua 5 segmen tengah dipakai tiap rute, D-1 1a): variasi antar seed hanya urutan dan pelanggan.
- Uji HP: lihat `SETUP_ANDROID.md` 8.6 (8 butir) dan daftar NEEDS-MANUAL di atas.


## Catatan QA iterasi 1

Auditor: Agent 2 (QA). Semua perintah dijalankan sendiri di `feat/fase3a-rute` (HEAD `7151f28`, basis `main` `51aaedf`), macOS, Godot 4.7.2. Klaim Dev tidak dipakai sebagai bukti.

### Verdict: FAIL (1 Major OPEN: QA-001; 4 Minor; 1 Nit)

Semua gerbang objektif hijau. Alasan FAIL hanya satu: logika kritis pemilihan pelanggan (K-3, AC-5) tidak dijaga tes terhadap mutan yang menghapus ketergantungan pada seed (QA-001). Kode produksi sendiri tidak ditemukan salah.

### Gerbang objektif (dijalankan QA)

| Perintah | Hasil |
|---|---|
| `godot --headless --import` | bersih, tanpa ERROR/WARNING |
| `godot --headless --script res://tests/run_tests.gd 2>&1 \| tee build/qa_tests.log` | **8117 lolos, 0 gagal**, 0 baris `SCRIPT ERROR`/`ERROR:`/`WARNING:` di log |
| `python3 tools/cek_keluaran_tes.py build/qa_tests.log` dan `--ketat` | lolos (8117 lolos, 0 gagal, 0 peringatan), kode keluar 0 |
| `godot --headless --path . --quit-after 2` | bersih (scene utama `rute.tscn`) |
| `uji_pemeriksa.py` / `uji_bangun_frames.py` / `uji_sintesis_sepeda.py` / `uji_sintesis_lempar.py` | 16 kasus 0 menyimpang / 41 lolos / 32 lolos / 111 lolos |
| `godot --headless --path . --export-pack "Android" build/qa-uji.pck` | 734.604 byte; isi diperiksa dengan pemindai `DirAccess` dari paket: 297 berkas, **9 `per_*.json`**, 0 `tests/`, 0 `docs/`, 0 keystore/apk, `rute.tscn` ada |
| Muat dari paket: `godot --headless --main-pack build/qa-uji.pck --script <skrip scratchpad>` dari folder di luar repo | `PemuatRute.muat_folder()` = 9 segmen, 0 galat; `RouteBuilder.bangun(20261016)` = 236 ubin, 25 pelanggan, koran 30, 0 galat; `rute.tscn` termuat |
| Klon bersih (`git clone -b feat/fase3a-rute`, import, `run_tests.gd`, `--ketat`) | 8117 lolos, 0 gagal; `git status` bersih |
| `godot --path . --quit-after 600` (jendela asli) | hanya `WARNING: 2 ObjectDB instances were leaked` dan `ERROR: 1 resources still in use at exit`; **identik di `main`** (klon `main` dijalankan sendiri) dan di `jalan_uji.tscn`: bukan regresi (sisa penutupan audio saat proses dibunuh `--quit-after`) |
| Kebersihan repo | tidak ada secret, keystore, `.godot/`, `build/`, APK di diff; tidak ada commit di `main` (`main` = `51aaedf` = merge-base); 15 commit berformat `feat/test/docs/refactor:` berbahasa Indonesia; semua `.gd` baru punya `.uid`; `ui.id.translation` ikut commit; `DEV_PHASES.md` tidak disentuh |

### Kepatuhan SPEC (AC-1 sampai AC-19)

| AC | Verdict | Bukti QA |
|---|---|---|
| AC-1 | OK | Sepuluh pemeriksaan independen dengan skrip Python sendiri atas 9 berkas: id = nama berkas, panjang 24 sampai 40, 2 pembuka, 5 tengah, 2 penutup, pembuka/penutup tenang, tidak ada pos di tepi, tidak ada rumah dekat `pelanggan_boleh`, tidak ada rintangan di jalur `tengah`, jarak rintangan >= 6 |
| AC-2 | OK | `SegmenRute.parse` + `PemuatRute` murni; `baca_teks` satu-satunya pembaca berkas; mutan Q26 sampai Q33 semua mati |
| AC-3 | OK | `_test_berkas_nyata`, `_test_berkas_nyata_oracle_mentah`; mutan Q28 sampai Q33 mati |
| AC-4 | OK | contoh `DATA_SCHEMA.md` 3 identik dengan `per_tengah_02.json` (dibandingkan sebagai JSON); label usulan; bagian 5 dan ROADMAP 5 diperbarui |
| AC-5 | **Sebagian (QA-001)** | determinisme dan 288 susunan dites; ketergantungan pilihan pelanggan pada seed tidak dijaga (Q04 selamat) |
| AC-6, AC-7 | OK | struktur, padat berurutan, 25 pelanggan seberang, id unik, celah <= 20, koran 30; QA sendiri: 400 seed sah, 0 pelanggan dekat, panjang 200 sampai 300 (`qa_repro_rute.gd` R3) |
| AC-8 | OK | 1,6 ms (Dev); tes `_test_waktu_bangun` di luar `systems/` |
| AC-9 | OK | zona literal (`_test_zona_rumah_literal`); mutan Q07, Q08, Q10 mati |
| AC-10, AC-11 | OK | `_test_bantu_di_zona_rute`, `_test_bantu_kisi`, `_test_swipe_dinilai_zona_rute`; Q21 mati |
| AC-12 | OK | `_test_rumah_digambar`, `_test_jendela_daur_bergerak`; Q13, Q16, Q39, Q40 mati; tangkapan layar dilihat |
| AC-13 | OK | seed dari `Config`; Q36, Q37 mati; tanpa isi ulang jalan uji |
| AC-14 | OK | sinyal tepat sekali, stick dikunci, banner, tombol, koran terbang dinilai (Q12, Q18, Q20 mati). Ketukan sentuh sungguhan pada tombol "Main lagi" menyusun ulang dengan seed + 1 (`qa_repro_rute.gd` R2). Tambahan di luar SPEC: QA-004 |
| AC-15 | OK | `PenutupPemain` + satu `PenerapPenutup`; Q14, Q15, Q24, Q25, Q35, Q38 mati; probe menampilkan objek uji semi-transparan. Q11 selamat (QA-002) |
| AC-16 | OK | `_test_jeda`, jeda dan back sesudah akhir; jeda/background ada di `AdeganJalan` yang dipakai bersama |
| AC-17 | Sebagian (QA-003) | semua angka baru di `Config` satu baris literal, `BALANCING.md` 6b dan 4 diperbarui, kunci `RUTE_SELESAI`/`RUTE_MAIN_LAGI` di `ui.csv`; tetapi tiga literal `2` bermakna tuning masih di kode |
| AC-18 | OK | tabel gerbang di atas |
| AC-19 | OK | `AGENTS.md`, `00-project-core.mdc`, `content-data.mdc`, `docs/README.md`, `ROADMAP.md`, `BALANCING.md`, `DATA_SCHEMA.md`, `SETUP_ANDROID.md` 8.6 diperbarui; `DEV_PHASES.md` tidak dicentang |

Pemeriksaan khusus yang diminta: tidak ada `randi()`/`randf()`/`Time`/`shuffle`/`randomize` di `scripts/systems/` (grep); tidak ada `kiri`/`kanan` untuk sisi jalan di berkas baru; teks pemain hanya lewat `tr()` (dua kunci, ada di `ui.csv` dan lolos `tr(...)` di tes); tidak ada hex/`Color(` di scene baru; keputusan terbuka ROADMAP 5 tidak diputuskan diam-diam (struktur sesi, game over, jendela bonus/penalti tidak disentuh; rumah dekat tetap placeholder `_bukan`), kecuali catatan QA-004; harapan tes Dev pada umumnya literal independen (koordinat zona, urutan segmen seed 20261016, tabel koran awal), kecuali tes scene memakai `RouteBuilder` sebagai rute oracle (dapat diterima karena `RouteBuilder` punya oracle literal sendiri).

### Review kode (ringkas)

- Pemuatan segmen dari paket game terbukti (tabel di atas); `DirAccess.get_files` bekerja pada `.pck`.
- Performa per frame: `RumahDaurRute.perbarui` hanya bekerja bila rentang indeks berubah (pencarian biner), node rumah dan kotak surat dipakai ulang dari kolam (paling banyak 30 node rumah, dites); `PenerapPenutup.terapkan` melingkar atas 11 sampai 20 rumah per frame tanpa alokasi. Alokasi kecil hanya saat swipe ditahan (`MedanKoran.zona_sekitar` membuat `Zona` dan `PenutupPemain.Objek` per sampel garis bidik); tidak dikategorikan temuan. Angka 60 fps di HP tetap NEEDS-MANUAL.
- Jeda/background/back: `AdeganJalan` dipakai bersama, tes scene rute menjaga jeda, lanjut dengan `dt` 0, back dua kali, dan sesudah akhir rute.
- Input: tombol "Main lagi" di strip HUD kanan atas, di luar zona stick dan swipe baik kidal maupun tidak (dites di 640, 780, 800); banner `mouse_filter` ignore.
- Visual (dilihat sendiri, 2340x1080 dan 1600x720, `shots/qa/`): rumah dan kotak surat tajam; rumah pelanggan (atap berwarna, kotak merah) terbedakan dari bukan pelanggan (atap abu-abu); objek uji menutupi tampil semi-transparan dan sepeda terlihat; banner "Rute selesai" terbaca; tombol "Main lagi" di pojok kanan atas, tidak menutupi tombol Kidal/Bantu; kidal di 1600x720 benar. Urutan gambar rumah dekat vs sepeda di lateral +1, jarak -3 sampai +3 ubin dari rumah dekat pertama: tidak ada tumpang tindih salah (skrip QA di scratchpad). Probe Dev `probe_rute_jendela.gd` dijalankan ulang di kedua rasio: 0 keadaan tidak sesuai, tanpa ERROR/WARNING.

### Mutan QA (40, satu penggantian teks, di klon bersih, `run_tests.gd` dijalankan per mutan)

Mati = jumlah `GAGAL:` baru. 36 mati, 4 selamat (dua di antaranya dianalisis sebagai setara).

| # | Mutasi | Hasil |
|---|---|---|
| Q01 | pembuka selalu indeks 0 | mati (8) |
| Q02 | penutup selalu indeks 0 | mati (8) |
| Q03 | Fisher-Yates melewatkan elemen terakhir | mati (8) |
| **Q04** | goyangan pelanggan = 0 | **SELAMAT (0)** -> QA-001 |
| Q05 | `periksa_rute` tanpa cek padat berurutan | mati (1) |
| Q06 | id rumah memakai `pos + 1` | mati (12, 1 SCRIPT ERROR akibat id tak ditemukan) |
| Q07 | zona rumah dekat dianggap pelanggan | mati (8) |
| Q08 | `id_rumah` zona dekat kosong | mati (1) |
| Q09 | `zona_rute_rentang` tanpa cadangan ujung depan | selamat (0): setara untuk mode bantu (zona dengan awal sebelum kavling hanya halaman dan teras, sasaran bantu hanya kotak surat); dicatat, bukan temuan |
| Q10 | `MedanKoran.zona_sekitar` tanpa cadangan belakang | mati (15) |
| **Q11** | `tertutup_titik` jendela belakang 2 petak -> 1 petak | **SELAMAT (0)**, tidak setara -> QA-002 |
| Q12 | akhir rute `>` bukan `>=` | mati (2) |
| Q13 | jendela daur depan 10 ubin lebih pendek | mati (10) |
| Q14 | tapak rumah dekat memakai x seberang | mati (11) |
| Q15 | tinggi rumah penutup x2 | mati (4) |
| Q16 | kotak surat di semua rumah seberang | mati (8) |
| Q17 | `main_lagi` tanpa `perbarui(0.0)` | selamat (0): setara (`_daur.atur_rute` sudah memanggil `perbarui(0.0)`; kamera dan HUD terlambat satu frame); bukan temuan |
| Q18 | sinyal tombol Main lagi tidak tersambung | mati (9) |
| Q19 | akhir rute tanpa `lepas_semua` dan `sembunyikan` garis bidik | selamat (0): setara dalam perilaku terlihat (`_lempar_diizinkan` sudah menyembunyikan garis bidik dan menolak lemparan pada langkah berikutnya); bukan temuan |
| Q20 | banner tidak tampil di akhir | mati (2) |
| Q21 | jangkauan bantu nol di scene rute | mati (7) |
| **Q22** | garis bidik tidak diberi `_medan` | **SELAMAT (0)** -> QA-002 |
| **Q23** | `KoranLempar.tertutup_pada` medan null | **SELAMAT (0)** -> QA-002 |
| Q24 | penerap tidak menghitung penutup | mati (1) |
| Q25 | `lepas` tidak mereset alfa | mati (1) |
| Q26 | id segmen tidak dicek sama nama berkas | mati (1) |
| Q27 | minimal penutup 2 -> 0 | mati (1) |
| Q28 | `pos` tepi atas tidak ditolak | mati (1) |
| Q29 | rumah dekat `pelanggan_boleh` diterima | mati (1) |
| Q30 | field asing diterima | mati (2) |
| Q31 | pembuka/penutup bebas tingkat | mati (2) |
| Q32 | titik misi tidak harus di rumah | mati (1) |
| Q33 | rumah sesisi boleh menumpuk | mati (1) |
| Q34 | `RUTE_PELANGGAN_JARAK_MAKS_UBIN` 20 -> 30 | mati (2) |
| Q35 | `RUTE_PENUTUP_ALFA` 0,45 -> 0,6 | mati (4) |
| Q36 | `RUTE_SEED_DEV` berubah | mati (21) |
| Q37 | koran awal 25 pelanggan -> 29 | mati (25) |
| Q38 | rumah dekat tidak menutupi elips | mati (2) |
| Q39 | node rumah tidak dilepas | mati (10) |
| Q40 | sprite dekat memakai `pelanggan_boleh` | mati (3) |

Mutan hanya diterapkan di klon di folder scratchpad; repo kerja tidak dimutasi. Skrip mutan: `scratchpad/skrip/mutan.py` (tidak di-commit).

### Tes reproduksi

`tests/qa_repro_rute.gd` (+ `.uid`), dijalankan `godot --headless --path . --script res://tests/qa_repro_rute.gd`: R1 (pilihan pelanggan bergantung seed; **gagal pada mutan Q04**, lolos pada kode asli), R2 (ketukan sentuh sungguhan pada tombol "Main lagi"), R3 (9 segmen, 400 seed sah, pelanggan seberang, panjang 200 sampai 300). Kode asli: semua LOLOS. Setelah berkas ini ditambahkan, `run_tests.gd` memberi 8118 lolos, 0 gagal (satu pemeriksaan pemindai berkas tes bertambah). Bukan bagian `run_tests.gd`; Dev boleh memindahkan R1 ke `tes_rute.gd` sebagai tes regresi QA-001.

### NEEDS-MANUAL (tidak bisa diuji QA di sini)

Lihat daftar NEEDS-MANUAL di atas (rasa kontrol, 60 fps dan memuat < 1 detik di vivo V2108, rasio layar asli, ketajaman di x3, keterbacaan banner di HP, kotak surat ganda, variasi antar seed). Fase 3 dan DEV_PHASES tidak boleh dicentang untuk butir yang bergantung pada uji HP.


## Catatan Dev iterasi 2

Hanya temuan OPEN QA iterasi 1 yang dikerjakan. Branch `feat/fase3a-rute`, tidak di-push; tidak menyentuh HP/adb, PNG, `DEV_PHASES.md`, atau hal terbuka ROADMAP 5. Kode produksi hanya berubah untuk QA-003 (konstanta, perilaku sama) dan QA-006 (a, b, c).

### Commit

| Commit | Isi |
|---|---|
| `f03cecc` test: jaga pilihan pelanggan bergantung seed dan ketukan Main lagi | QA-001; `qa_repro_rute.gd` dihapus |
| `cc5ee6b` refactor: konstanta Config untuk pengapit, minimum pembuka dan penutup, jendela belakang penutup | QA-003 (kode + `BALANCING.md` 6b) |
| `b6f3895` test: titik tertutup medan rute, garis bidik redup di rute, konstanta pengapit | QA-002 dan tes QA-003 |
| `b2663d9` fix: id berakhiran baris baru ditolak, galat muat rute terlihat, PNG rumah dimuat di awal | QA-006 a, b, c |

### Per temuan

- **QA-001 (Major) FIXED.** `tests/tes_rute.gd:_test_pelanggan_bergantung_seed`: sapuan 400 seed (1000..1399) memeriksa (1) paling sedikit 50 urutan segmen sama punya lebih dari satu himpunan pelanggan (kode asli 122 dari 210), (2) satu urutan punya paling sedikit 3 himpunan, (3) tiap rute memuat jarak antar pelanggan <= 6 dan >= 12 (rumah berurutan lalu sela panjang, ROUTE_DESIGN 3), (4) sapuan: jarak terpendek <= 4 dan terpanjang >= 18, (5) `Config.RUTE_PELANGGAN_GOYANG_UBIN` = 3,0 dan > 0 (dirujuk tes), (6) tidak ada pelanggan sisi dekat dan panjang rute 200..300 (isi R3). R2 (ketukan sentuh sungguhan tombol "Main lagi") jadi `tes_rute_scene.gd:_test_main_lagi_ketuk`. `tests/qa_repro_rute.gd` dan `.uid` dihapus karena R1, R2, R3 tercakup.
  - Mutan Q04 (`target.append(dasar)`): **3 GAGAL** (urutan bervariasi 0 dari 210, himpunan terbanyak 1, celah terpanjang 16 < 18); dipulihkan (8161 lolos akhir).
  - Catatan jujur: goyangan nol TIDAK membuat rute lebih seragam per rute (rentang jarak terkecil per rute 12,0 pada mutan maupun kode asli, rata-rata 12,0 lawan 12,5, karena kandidat rumah diskrit di kelipatan 2 dan 4); yang membedakan mutan ialah variasi antar seed dan celah terpanjang. Karena itu pemeriksaan (3) dan (4) menjaga ritme ROUTE_DESIGN 3 tetapi bukan penentu mutan; penentunya (1), (2), dan celah terpanjang.
- **QA-002 (Minor) FIXED** (hanya tes; kode produksi benar).
  - `tes_rute.gd:_test_medan_tertutup_titik`: rumah seberang di awal 6 (tapak lateral -6..-3, maju 5,5..8,5); titik tanah lateral -5,5 di maju 10,0, 10,2, 10,3, 10,45 tertutup, 10,6 tidak, setinggi 1,9 tidak, di belakang tidak, tengah jalan tidak; `RUTE_PENUTUP_JENDELA_BELAKANG_PETAK` = 2. `KoranLempar.tertutup_pada`: lintasan literal (swipe 160, seberang, dari maju 50, santai) punya titik tertutup di graybox jalan uji, tidak di medan rute tanpa rumah, dan tertutup di medan rumah awal 50 (oracle literal tapak -6..-3, maju 49,5..52,5, tinggi < 2).
  - `tes_rute_scene.gd:_test_garis_bidik_titik_redup`: 120 swipe di scene rute (6 jarak x 5 sudut x 4 panjang), tiap titik garis bidik redup tepat bila `medan.tertutup_titik` (rumah rute), dengan kontrol ada titik yang berbeda dari rumah graybox jalan uji.
  - Mutan: Q11 (jendela satu petak) **3 GAGAL**; Q22 (`_medan` tidak diteruskan ke `GarisBidik.tampilkan`) **1 GAGAL** (30 titik salah); Q23 (`tertutup_pada` memakai medan null) **2 GAGAL**; semua dipulihkan.
- **QA-003 (Minor) FIXED.** `RUTE_SEGMEN_PENGAPIT` (2), `RUTE_PEMBUKA_MIN` (2), `RUTE_PENUTUP_MIN` (2), `RUTE_PENUTUP_JENDELA_BELAKANG_PETAK` (2) di `config.gd` satu baris literal; dipakai `pemuat_rute.gd` (85, 87, 89, galat bernomor dari Config), `route_builder.gd` (198 dan komentar), `medan_koran.gd` (51). Nilai sama, perilaku tidak berubah (8117 tes lama tetap lolos). `BALANCING.md` 6b diperbarui di commit yang sama. Tes: `tes_rute.gd:_test_konstanta_pengapit` (literal, pustaka tanpa satu pembuka/tengah ditolak, `RouteBuilder.bangun` menolak empat tengah) ditambah `_test_kumpulan` yang sudah ada. Mutan nilai konstanta 1: `RUTE_PEMBUKA_MIN` 3 GAGAL, `RUTE_PENUTUP_MIN` 2 GAGAL, `RUTE_SEGMEN_PENGAPIT` 546 GAGAL, `RUTE_PENUTUP_JENDELA_BELAKANG_PETAK` 4 GAGAL.
- **QA-004, QA-005 DEFERRED** (keputusan pemilik; tidak diubah). Rekomendasi tertulis di Keputusan & catatan.
- **QA-006 (Nit).**
  - (a) FIXED: `SegmenRute._nama_sah` memakai `\z`. Tes: `id_baris_baru` (`"per_uji_01\n"`) dan `titik_nama_baris_baru` (`"atap\n"`) ditolak dengan galat "harus huruf kecil, angka, dan garis bawah". Mutan kembali ke `$`: **2 GAGAL**.
  - (b) FIXED: kunci `RUTE_GAGAL_MUAT` ("Rute gagal dimuat") di `translations/ui.csv` dan `ui.id.translation` (impor ulang); `PanelAkhirRute.tampilkan_galat()` memakai banner yang sama dengan "Rute selesai" dan tombol "Main lagi" (mencoba seed berikutnya); `RuteMain._susun` memanggilnya saat galat. Perilaku rute normal tidak berubah (`tampilkan(false/true)` mengembalikan teks "Rute selesai"). Rute kosong tidak dinyatakan selesai (`AkhirRute.tercapai` menolak panjang <= 0), jadi banner galat bertahan. Tes: `tes_rute_scene.gd:_test_galat_muat_terlihat` (pustaka satu segmen, banner galat, bertahan 10 langkah, pulih lewat Main lagi lalu selesai normal). Mutan tanpa `tampilkan_galat`: **2 GAGAL**.
  - (c) FIXED: `RumahDaurRute.atur_rute` memuat semua PNG jenis rumah rute (`_tekstur_untuk`), akses `jumlah_tekstur_dimuat()`. Tes: `_test_tekstur_dimuat_di_atur_rute` (jumlah = jenis sprite di rute sebelum sepeda bergerak, tidak bertambah sepanjang rute). Mutan tanpa muat awal: **2 GAGAL** (7 dari 9).
  - (d) Tidak dikerjakan: **ditunda ke Run 3C** (penanda garis akhir di dunia; akhir rute dirombak bersama layar hasil).
  - (e) Tidak dikerjakan: **diterima** (branch 15+ commit, 90 berkas sebagai run 3A; empat commit iterasi 2 kecil).

### Keputusan Dev (lanjutan D-23)

- **D-24 (tes pilihan pelanggan, ambang).** Sapuan seed 1000..1399 (sama dengan sapuan QA), ambang diambil dari pengukuran: asli 122 dari 210 urutan bervariasi dan celah terpanjang 20; mutan 0 dan 16. Ambang 50 dan 18 memberi jarak aman pada kedua sisi.
- **D-25 (`RuteMain.lapor_galat_ke_log`).** `push_error` rute gagal tetap, tetapi tes yang sengaja memicu galat mematikannya lewat satu bendera publik (`lapor_galat_ke_log = false`), karena pemeriksa keluaran tes menolak baris `ERROR:`. Bukan perubahan perilaku game.
- **D-26 (tes memakai medan sintetis).** Tes QA-002 membuat `RouteBuilder.Rute` dengan satu rumah (`_rumah_uji`) dan oracle literal tapak, bukan `RouteBuilder` penuh, supaya geometri titik terbaca di tes.
- **D-27 (`_test_garis_bidik_titik_redup` memakai `medan.tertutup_titik` sebagai oracle).** Itu fungsi produksi, tetapi yang diuji ialah kabel (GarisBidik harus menerima medan rute), dan fungsinya sendiri dijaga literal di `_test_medan_tertutup_titik` (Q11).

### Gerbang (dijalankan Dev, sesudah commit terakhir kode)

- `godot --headless --import`: bersih (0 ERROR).
- `godot --headless --script res://tests/run_tests.gd 2>&1 | tee build/tests.log`: **8179 lolos, 0 gagal** (8117 sebelum iterasi 2; +62).
- `python3 tools/cek_keluaran_tes.py build/tests.log` dan `--ketat`: lolos, 0 peringatan.
- `godot --headless --path . --quit-after 2`: 0 baris ERROR/WARNING.
- `uji_pemeriksa.py` (16 kasus, 0 menyimpang), `uji_bangun_frames.py` (41), `uji_sintesis_sepeda.py` (32), `uji_sintesis_lempar.py` (111): lolos.
- `godot --headless --path . --export-pack "Android" build/kring-uji.pck`: 9 `assets/data/routes/perumahan/per_*.json`, `rute.tscn` dan `panel_akhir_rute.tscn`; 0 berkas `tests/` atau `docs/`.
- Tidak dijalankan ulang: probe jendela 2340x1080 dan 1600x720 (perubahan visual hanya teks banner galat yang tidak muncul di rute normal).

### BLOCKED

Tidak ada.


## Catatan QA iterasi 2

Auditor: Agent 2 (QA, agen baru, konteks segar). Semua perintah dijalankan sendiri di `feat/fase3a-rute` (HEAD `1392bae`, basis `main` `51aaedf`; diff iterasi 2 = `0d9ad18..HEAD`), macOS, Godot 4.7.2.

### Verdict: PASS (0 Blocker, 0 Major; 1 Minor dan 1 Nit baru ditutup dengan tes QA; 1 Nit DEFERRED; QA-004 dan QA-005 menunggu pemilik)

### Gerbang objektif (dijalankan QA)

| Perintah | Hasil |
|---|---|
| `godot --headless --import` (repo dan klon bersih di scratchpad, `git clone -b feat/fase3a-rute`) | bersih |
| `godot --headless --script res://tests/run_tests.gd 2>&1 \| tee build/qa2_tests.log` | **8179 lolos, 0 gagal**, 0 baris `SCRIPT ERROR`/`ERROR:`/`WARNING:`; klon bersih sama (8179 lolos, 0 gagal, `git status` bersih sesudah import dan tes) |
| `tools/cek_keluaran_tes.py` dan `--ketat` | lolos (8179 lolos, 0 gagal, 0 peringatan), kode keluar 0 |
| `godot --headless --path . --quit-after 2` | 0 baris ERROR/WARNING (repo dan klon) |
| `uji_pemeriksa.py` / `uji_bangun_frames.py` / `uji_sintesis_sepeda.py` / `uji_sintesis_lempar.py` | 16 kasus 0 menyimpang / 41 lolos / 32 lolos / 111 lolos |
| `godot --headless --path . --export-pack "Android" build/qa2-uji.pck` | 735.212 byte; 9 `per_*.json`; 0 `tests/`, `docs/`, keystore, apk |
| Muat dari paket: `godot --headless --main-pack build/qa2-uji.pck --script <skrip scratchpad>` dari folder di luar repo | `res://tests` dan `res://docs` tidak ada; `daftar_berkas` 9 nama asli; `muat_folder` 9 segmen 0 galat; `bangun(20261016)` = 236 ubin, 25 pelanggan, koran 30, 0 galat; `rute.tscn` termuat |
| Perilaku QA-003 tak berubah | skrip hash: 800 seed rute (id, pelanggan, maju, panjang) dan 60.000 titik `MedanKoran.tertutup_titik` identik antara `0d9ad18` dan `HEAD` (hash sama, 38.361 titik tertutup) |
| Kebersihan repo | tidak ada secret, keystore, `.godot/`, `build/`, APK di diff; tidak ada commit di `main`; 6 commit iterasi 2 berformat `test/refactor/fix/docs:` berbahasa Indonesia; `qa_repro_rute.gd.uid` ikut dihapus; `.uid` berkas baru: tidak ada berkas `.gd` baru; `ui.id.translation` ikut commit dan reproduksibel (impor ulang di klon tidak mengubah apa pun); `DEV_PHASES.md`, ROADMAP, aset, `project.godot` tidak disentuh |

Setelah tes QA ditambahkan (lihat di bawah): `run_tests.gd` **8182 lolos, 0 gagal**, `--ketat` lolos.

### Verifikasi temuan FIXED

| ID | Cara | Hasil |
|---|---|---|
| QA-001 | mutan Q04 (`target.append(dasar)`) | 3 GAGAL (urutan bervariasi 0 dari 210; himpunan terbanyak 1; celah terpanjang 16 < 18) -> **VERIFIED**. Mutan tambahan N02 (celah 20 ditolak) 1 GAGAL, N03 (percobaan ulang jadi `break`) 2 GAGAL. R1, R2, R3 `qa_repro_rute.gd` tercakup: R1 = `_test_pelanggan_bergantung_seed`, R2 = `_test_main_lagi_ketuk`, R3 = sapuan 400 seed (25 pelanggan, seberang, panjang 200..300) + `_test_berkas_nyata`; penghapusan sah |
| QA-002 | Q11 (jendela belakang satu petak) / Q22 (`_medan` tidak diteruskan) / Q23 (`tertutup_pada` medan null) | 3 / 1 (30 titik salah) / 3 GAGAL -> **VERIFIED**. Q11 dengan nilai konstanta 1 dan 3: 4 dan 1 GAGAL |
| QA-003 | `grep` literal `2` di `pemuat_rute.gd`, `route_builder.gd`, `medan_koran.gd`: tidak ada (sisa hanya `/ 2` rata-rata di `_cocokkan`, bukan tuning); 4 konstanta satu baris literal di `config.gd` (pemeriksa format hijau); `BALANCING.md` 6b memuat keempatnya; mutan nilai: PEMBUKA_MIN 3 -> 65 GAGAL, PENUTUP_MIN 3 -> 64, PENGAPIT 1 -> 553, JENDELA_BELAKANG 3 -> 1; perilaku identik (hash) | **VERIFIED** |
| QA-006 a | mutan `\\z` -> `$` | 2 GAGAL -> VERIFIED |
| QA-006 b | mutan tanpa `tampilkan_galat()` (dan mutan teks banner tetap "Rute selesai") | 2 GAGAL (masing-masing); kunci `RUTE_GAGAL_MUAT` ada di `ui.csv` dan `.translation` -> VERIFIED. Mutan N12 (`tampilkan` tidak mengembalikan teks "Rute selesai") 1 GAGAL, N13 (`_galat` tidak direset) 2 GAGAL |
| QA-006 c | mutan tanpa muat awal PNG | 2 GAGAL (7 dari 9) -> VERIFIED |
| QA-004, QA-005 | `git diff 0d9ad18..HEAD`: `_lempar_diizinkan`, aset, `tools/env_art` tidak berubah; rekomendasi tertulis di "Keputusan & catatan"; N18 (lemparan diterima sesudah akhir) 2 GAGAL, jadi perilaku D-17 tetap dijaga | tetap **DEFERRED** (keputusan pemilik) |

### Review diff iterasi 2

Static typing lengkap pada kode baru (`gagal: bool`, `jumlah_tekstur_dimuat() -> int`, `tampilkan_galat() -> void`); komentar `##` berbahasa Indonesia; tidak ada angka ajaib baru (pemindai literal hijau); tidak ada `kiri`/`kanan` pada baris tambahan; teks pemain lewat `tr("RUTE_GAGAL_MUAT")` dengan kunci baru di `ui.csv` dan `ui.id.translation`; tidak ada keputusan terbuka ROADMAP 5 yang diputuskan (struktur sesi, game over, jendela bonus, rumah dekat tidak disentuh); `DEV_PHASES.md` tidak dicentang; tidak ada perubahan di luar temuan (16 berkas, semuanya terkait QA-001..003, QA-006 atau LOG/BALANCING). Catatan kecil: `tes_rute_scene.gd` mengakses `akar._pustaka` (anggota privat) untuk menyuntikkan pustaka rusak; dapat diterima di tes.

### Mutan QA iterasi 2 (33, di empat klon bersih terpisah, `run_tests.gd` per mutan)

Mati = jumlah `GAGAL:` baru. Selamat: N01, N04, N14, N16, N17.

| # | Mutasi | Hasil |
|---|---|---|
| Q04, Q11, Q22, Q23 | lihat Verifikasi QA-001/002 | mati (3, 3, 1, 3) |
| Q03a-e | nilai 4 konstanta QA-003 | mati (65, 64, 553, 1, 4) |
| Q06a-c | `\z`->`$`, tanpa `tampilkan_galat`, tanpa muat awal PNG | mati (2, 2, 2) |
| N01 | goyangan target satu arah `(0, G)` | **SELAMAT** -> QA-009 (Nit) |
| N02 | celah pelanggan `>` -> `>=` (celah tepat 20 ditolak) | mati (1) |
| N03 | celah tidak sah: `continue` -> `break` | mati (2) |
| N04 | DP seri `<` -> `<=` | SELAMAT: setara praktis (target float acak, seri hampir mustahil); bukan temuan |
| N05 | tengah per rute dikurangi satu | mati (547) |
| N06 | `randi()` global ditambahkan di pemilih pembuka | mati (12) |
| N07 | `AkhirRute.periksa` lapor `baru_selesai` lagi | mati (7) |
| N08 | stick akhir (0, 0) | mati (4) |
| N09 | penerap tidak menghitung penutup | mati (1) |
| N10 | `lepas` tidak mengembalikan alfa | mati (1) |
| N11 | alfa penutup 0,8 di penerap | mati (3) |
| N12 | `tampilkan` tidak mengatur teks "Rute selesai" | mati (1) |
| N13 | `_galat` tidak direset di `_susun` | mati (2) |
| N14 | bawaan `lapor_galat_ke_log` false | **SELAMAT** -> QA-008 (Nit), kini mati (1) dengan tes QA |
| N15 | kotak surat di semua rumah `pelanggan_boleh` | mati (4) |
| N16 | jendela depan `tertutup_titik` nol | **SELAMAT** -> QA-007 (Minor), kini mati (1) dengan tes QA |
| N17 | akhir rute tanpa `_garis_bidik.sembunyikan()` | SELAMAT: setara (Q19 iterasi 1: `_lempar_diizinkan` sudah menyembunyikan garis bidik pada langkah berikutnya); bukan temuan |
| N18 | `_lempar_diizinkan` selalu true | mati (2) |
| N19 | pustaka butuh tengah `<=` | mati (62) |
| N20 | posisi maju rumah + 0,5 | mati (14) |
| N21 | banner galat memakai teks "Rute selesai" | mati (2) |

Skrip mutan dan klon ada di scratchpad (`qa2/mutan2.py`, tidak di-commit); repo kerja tidak dimutasi (`git status` hanya menampilkan dua tes QA dan LOG).

### Tes yang ditambahkan QA

- `tests/tes_rute.gd:_test_medan_tertutup_titik`: dua baris `kasus` (titik di dalam tapak 0,3 ubin sebelum awal kavling: tertutup; 0,1 ubin sebelum tapak: tidak). Membunuh N16.
- `tests/tes_rute_scene.gd:_test_galat_muat_terlihat`: satu `check` bahwa `lapor_galat_ke_log` bawaan true. Membunuh N14.
- Total 8179 -> 8182 lolos, 0 gagal.

### Validasi visual

`godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_rute_jendela.gd -- docs/loop/20261016-fase3a-rute/shots/qa2` dijalankan: "probe selesai, 0 keadaan tidak sesuai", tanpa ERROR/WARNING. Dua tangkapan dilihat sendiri (`shots/qa2/2340x1080_rute_tengah.png` dan `..._rute_akhir_berhenti.png`): rumah pelanggan dan bukan pelanggan terbedakan, kotak surat merah (sprite) dan kubus oranye (sasaran) tampil ganda (QA-005 tetap DEFERRED), HUD terbaca, banner "Rute selesai" dan tombol "Main lagi" di tempat yang benar, sepeda berhenti di tanah kosong (QA-006 d ditunda ke 3C). Tidak ada regresi visual dibanding iterasi 1. Tangkapan lain dihapus dari `qa2` untuk menghemat repo.

### Regresi

Jumlah tes naik (8117 -> 8179 -> 8182); tidak ada tes dihapus kecuali `qa_repro_rute.gd` (tercakup, lihat QA-001); tidak ada tes di-skip; `jalan_uji.tscn` dan tes jalan uji lama tidak diubah (diff iterasi 2 tidak menyentuhnya).

### NEEDS-MANUAL

Daftar di atas tetap berlaku (60 fps dan memuat < 1 detik di vivo V2108, rasa kontrol, keterbacaan banner di HP, kotak surat ganda QA-005, variasi antar tiga seed, urutan gambar rumah dekat vs sepeda). Fase 3 dan DEV_PHASES tidak boleh dicentang untuk butir yang bergantung pada uji HP, dan QA-004 serta QA-005 perlu keputusan pemilik sebelum uji HP SETUP_ANDROID 8.6.

## Keputusan pemilik dan perubahan sesudah QA PASS (2026-10-16)

- **QA-004 (D-17, lemparan ditolak sesudah garis akhir): pemilik setuju rekomendasi, perilaku dipertahankan** sampai Run 3C mengganti akhir rute dengan layar hasil. Tidak ada perubahan kode. Status: DEFERRED, keputusan pemilik tercatat.
- **QA-005 (D-16, dua kotak surat): dikerjakan orchestrator sesudah QA PASS atas permintaan pemilik.** `tools/env_art/fase3.py`: `house_far_v(..., kotak=False)` pada ekspor sprite rumah seberang, lalu `--salin`. Hanya 3 sprite `house_perumahan_{limasan,pelana,sayap}_pelanggan.png` yang berubah (kotak merah di teras hilang; ukuran sel 270x212 -> 262x208, 253x229 -> 245x225, 270x204 -> 254x196; `ground_anchor` tidak berubah, jadi posisi rumah di scene sama) dan catatan di 6 JSON seberang. Render ulang di mesin ini juga mengubah beberapa piksel berkas lain (mis. `house_perumahan_dekat_pelana_lintang_*` 40 piksel, `obs_mobil_garasi_sheet` 9 piksel, mock `docs/design/environment/`): itu drift renderer terhadap aset yang sudah di-commit, tidak terkait perubahan ini, jadi **dikembalikan** (tidak masuk commit). Bukti: 8182 lolos, 0 gagal (`--ketat` 0 peringatan), `--quit-after 2` bersih, tangkapan `shots/art/2340x1080_rute_tengah.png` memperlihatkan satu kubus oranye per rumah pelanggan tanpa kotak merah. **Perubahan ini TIDAK diaudit QA** (di luar iterasi 2); status QA-005 = FIXED (belum VERIFIED).
- **D-25 (aset).** Karena kotak surat sasaran kini hanya kubus graybox oranye di pusat zona, penggantian ke aset kotak surat final menjadi pekerjaan Fase 5 (bukan 3A). Sprite rumah dekat tidak diubah (selalu `bukan` di 3A).

## Tindak lanjut review pemilik: zona kotak surat jadi area (2026-10-16)

Pemilik mencoba di HP dan menilai zona kotak surat (100%) terlalu kecil: zona 0,5 x 0,5 ubin memberi toleransi sekitar +-3 mm gerak jari, dan di scene rute hanya kubus oranye yang tergambar, jadi pemain tidak melihat area yang sebenarnya. Keputusan pemilik: jadikan area. Di luar iterasi QA 1 dan 2 (dikerjakan sesudah PASS, di branch dan PR yang sama): **perubahan ini TIDAK diaudit QA**. Bukan keputusan terkunci; semuanya usulan yang dinilai lewat uji HP.

### Commit (branch `feat/fase3a-rute`, tidak di-push)

- `tune: kotak surat jadi area 1,0 x 1,5 dengan pusat tetap`: `Config.JALAN_UJI_SEBERANG_KOTAK_SURAT_UBIN` `[-1.875, 0.875, 0.5, 0.5]` menjadi `[-2.125, 0.375, 1.0, 1.5]`, `JALAN_UJI_DEKAT_KOTAK_SURAT_UBIN` `[1.375, 0.875, 0.5, 0.5]` menjadi `[1.125, 0.375, 1.0, 1.5]`; tes literal; BALANCING 5; DATA_SCHEMA 3.
- `feat: gambar area kotak surat di tanah scene rute`: `AreaKotakGambar`, simpul `AreaKotak` di `rute.tscn`, `AREA_KOTAK_ISI_ALPHA` dan `AREA_KOTAK_TEPI_ALPHA`, tes, tangkapan `shots/area/`.
- `docs:` SETUP_ANDROID 8.6 butir 9, LOG ini, LOOP-DEV-QA 6d Run 3B.

### Keputusan Dev (lanjutan D-27; D-26 dan D-27 sudah dipakai iterasi 2, jadi nomor berikutnya D-28)

- **D-28 (ukuran, pusat tetap).** Area 1,0 x 1,5 (lateral x maju), pusat tidak berubah: seberang (-1,625; 1,125), dekat (1,625; 1,125). Sasaran mode bantu (`BantuLempar.pilih` membidik pusat zona) dan `KASUS_KABEL` tidak bergeser; `BantuLempar` dan `ThrowSolver` tidak disentuh. Toleransi lateral sekitar +-6 mm (dua kali), maju sekitar +-9 mm (tiga kali), area sekitar 6 kali. Seberang dan dekat tidak bertumpuk (celah lateral -1,125 sampai 1,125 di jalan, dites). Semua zona tetap terjangkau (tes keterjangkauan lama lolos tanpa perubahan).
- **D-29 (tumpang tindih halaman, disengaja).** Zona yang membesar menimpa 0,125 ubin halaman di sisi trotoar (seberang lateral -2,125 sampai -2,0; dekat 2,0 sampai 2,125). Prioritas kotak surat > jendela > teras > halaman tidak berubah, jadi kotak surat menang; titik di sana yang dulu HALAMAN (50%) atau MELESET (lateral tepat -2,0, tepi maks halaman eksklusif) kini KOTAK_SURAT (100%). Dites literal, juga dengan daftar zona dibalik (prioritas, bukan urutan daftar).
- **D-30 (penggambar area).** `AreaKotakGambar` (`scripts/entities/area_kotak_gambar.gd`, pola `ZonaGambar`: perintah `GambarPiksel` dari `PolaPiksel.rentang_poligon(sudut_zona(persegi))` dan `rentang_tepi`). Persegi diambil dari `ZonaSasaran.zona_rumah` (jenis kotak surat), SATU sumber dengan penilaian, jadi yang terlihat = yang dinilai. Hanya rumah pelanggan sisi seberang di jendela daur yang sama dengan `RumahDaurRute` (`JendelaRute.rentang_sekitar`); gambar ulang hanya saat rentang jendela berganti. Rumah bukan pelanggan dan sisi dekat tidak digambar (jawaban atas D-20 untuk kotak surat; zona halaman, teras, dan jendela tetap tidak digambar di rute). Node `AreaKotak` di antara `Tanah` dan `KoranTanah`, jadi di bawah bayangan koran, rumah, dan sepeda. Isi `ACCENT` alfa 0,28, garis tepi `OUTLINE` alfa 0,9 (token `Palette`, tanpa hex); bentuk terbaca dari garis tepi bertangga 2x1, tidak hanya warna isi (rule `ui-scenes`).
- **D-31 (jalan uji).** `ZonaGambar` jalan uji menggambar kotak surat sisi dekat dari data yang sama, jadi sisi dekat jalan uji otomatis membesar; sisi seberang jalan uji tetap hanya kotak graybox (tidak diubah, `JalanUji` bukan scene rute).
- **D-32 (calon bonus presisi, TIDAK diputuskan).** "Inti" 0,5 x 0,5 di pusat area (zona lama) bisa menjadi antaran "tepat" dengan bonus skor atau combo di Run 3B. Hanya dicatat (BALANCING 5, LOOP-DEV-QA 6d); seluruh area sah penuh 100% sampai pemilik memutuskan.

### Tes

Gerbang: `--import`; `run_tests.gd` 8296 lolos, 0 gagal (sebelumnya 8182); `cek_keluaran_tes.py` dan `--ketat` lolos (0 peringatan); `--quit-after 2` bersih; empat `tools/tests_cek/uji_*.py` lolos; probe jendela rute 2340x1080, 0 keadaan tidak sesuai.

- `tests/tes_rute.gd:_test_kotak_surat_area`: persegi seberang dan dekat tepat 1,0 x 1,5 di awal 0 dan 50, pusat tetap, tidak bertumpuk, sisi tidak menyeberang; titik literal (pusat, pojok zona lama, dulu meleset lateral -2,0 maju +0,5, halaman tertimpa -2,05 dan 2,1, tepi min inklusif dan maks eksklusif kedua sumbu, 0,001 di dalam dan di luar tepi, aspal); prioritas dengan daftar dibalik; mode bantu v 3,0, 4,5, 6,0 mendarat di pusat (-1,625; -1,125) dan dinilai KOTAK_SURAT. Literal lama di `tes_rute.gd`, `tes_lempar.gd`, komentar `tes_bantu_scene.gd` dan `tes_rute_scene.gd` diganti; tetap literal, tidak dihitung dari `Config`.
- `tests/tes_rute.gd:_test_area_kotak_gambar`: dua perintah untuk pelanggan seberang, nol untuk bukan pelanggan, dekat, dan tanpa sisi; letak layar (x 1544..1624, y -864..-824 di awal 50, ditulis ulang dari proyeksi iso), isi sekitar 1536 piksel, tepi lebih sedikit dari isi, warna token `Palette`, alfa isi > 0 dan lebih pudar dari tepi; rentang indeks dan geseran 16 ubin.
- `tests/tes_rute_scene.gd:_test_area_kotak_digambar`: scene nyata di enam jarak: area = rumah pelanggan seberang di jendela daur (oracle dipindai linear), dua perintah per area, letak layar per rumah, urutan simpul (tanah, area, koran tanah, objek), tanpa `z_index`, tidak dihitung ulang selama jendela sama, berganti saat jendela berganti, mengikuti rute baru sesudah "Main lagi".

### Mutan (16 nyata, satu penggantian teks, di pohon kerja lalu dipulihkan dengan `git checkout`; semua mati)

| # | Mutan | Gagal |
|---|---|---|
| M1 | area digambar untuk rumah seberang bukan pelanggan | 29 |
| M2 | area juga untuk rumah dekat | 4 |
| M3 | ukuran seberang kembali 0,5 x 0,5 | 23 |
| M4 | pusat bergeser maju 0,25 | 44 |
| M5 | prioritas dibalik (halaman menang atas kotak surat) | 41 |
| M6 | zona dekat tidak ikut membesar | 5 |
| M7 | alfa isi 0 | 1 |
| M8 | area tidak mengikuti jendela daur (`perbarui` dihapus dari `_perbarui_dunia`) | 15 |
| M9 | area di atas objek (`z_index = 1`) | 1 |
| M10 | semua jenis zona digambar, bukan hanya kotak surat | 16 |
| M11 | tepi maks lateral zona inklusif | 4 |
| M12 | tanpa cache jendela (gambar ulang tiap langkah) | 1 |
| M13 | garis tepi lebih pudar dari isi | 1 |
| M14 | lebar 1,2 (pusat lateral bergeser) | 26 |
| M15 | isi memakai `TEXT`, bukan `ACCENT` | 1 |
| M16 | area tidak diganti sesudah "Main lagi" | 15 |

### Validasi visual

`shots/area/2340x1080_rute_tengah.png` dan `shots/area/2340x1080_rute_bantu_centang.png` (`tests/probe_rute_jendela.gd`): tiap rumah pelanggan seberang punya belah ketupat oranye tipis dengan garis tepi gelap bertangga di trotoar dan sedikit rumput, kubus oranye di tengahnya; sepeda tidak tertutup dan penanda centang di kubus tetap terbaca. Rumah bukan pelanggan dan rumah dekat tanpa area.

### NEEDS-MANUAL

- [ ] Uji HP (SETUP_ANDROID 8.6 butir 9): area terbaca, tidak mengganggu pandangan, kena terasa lebih mudah di tiga kecepatan; apakah 1,0 x 1,5 terlalu mudah atau pas (angka usulan). Bonus "inti" belum diputuskan.

## Catatan QA tindak lanjut zona kotak surat

Auditor: Agent 2 (QA, agen baru, konteks segar). Yang diaudit hanya `git diff 3f64bc8..HEAD` (commit `5e79ef0`, `d760503`, `f958bae`; HEAD `f958bae`) di `feat/fase3a-rute`, macOS, Godot 4.7.2. Semua perintah dijalankan sendiri. Kode produksi hanya dimutasi di klon bersih di scratchpad (`git status` repo kerja bersih sesudahnya selain tes QA dan tangkapan `shots/qa3`).

### Verdict: PASS (0 Blocker, 0 Major, 2 Minor, 1 Nit; QA-010 ditutup dengan tes QA, QA-011 dan QA-012 DEFERRED)

### Gerbang objektif (dijalankan QA)

| Perintah | Hasil |
|---|---|
| `godot --headless --import` (repo kerja dan klon bersih `git clone -b feat/fase3a-rute` di scratchpad) | bersih |
| `godot --headless --script res://tests/run_tests.gd 2>&1 \| tee build/qa_tests.log` | **8296 lolos, 0 gagal** (repo kerja dan klon bersih sama), 0 baris `SCRIPT ERROR`/`ERROR:`/`WARNING:` |
| `tools/cek_keluaran_tes.py` dan `--ketat` | lolos (8296 lolos, 0 gagal, 0 peringatan), kode keluar 0, repo kerja dan klon |
| `godot --headless --path . --quit-after 2` | 0 baris ERROR/WARNING (repo dan klon). Catatan: impor mencetak `cannot connect to daemon at tcp:5037` (plugin ekspor Android mencari adb); tidak ada HP atau adb yang disentuh |
| `uji_pemeriksa.py` / `uji_bangun_frames.py` / `uji_sintesis_sepeda.py` / `uji_sintesis_lempar.py` | 16 kasus 0 menyimpang / 41 lolos / 32 lolos / 111 lolos |
| `godot --headless --path . --export-pack "Android" build/qa3-uji.pck` | 738.016 byte; 9 `per_*.json` di `assets/data/routes/perumahan/`; 0 `res://tests`, `res://docs`, keystore, apk; `area_kotak_gambar.gd` ikut |
| Kebersihan diff | `scripts/systems/*` (ThrowSolver, BantuLempar, ZonaSasaran), aset PNG, `DEV_PHASES.md`, ROADMAP, `project.godot` tidak berubah; tidak ada kata "dikunci" baru (hanya penyangkalan "bukan keputusan terkunci"); tidak ada keputusan ROADMAP 5 yang diputuskan; `.uid` berkas baru hadir; 3 commit berformat `tune/feat/docs:` berbahasa Indonesia, tidak ada commit di `main`, tidak ada secret, `.godot/`, `build/`, APK |

Setelah tes QA ditambahkan (lihat di bawah): `run_tests.gd` **8298 lolos, 0 gagal**, `cek_keluaran_tes.py` dan `--ketat` lolos.

### Regresi dan independensi tes

- Jumlah tes naik 8182 -> 8296 (+114 check); `git diff` tidak menghapus atau melewati satu pun `check`; yang diganti hanya literal lama (`tes_rute.gd`, `tes_lempar.gd`) menjadi literal baru, komentar `tes_bantu_scene.gd` dan `tes_rute_scene.gd`.
- Tes baru (`_test_kotak_surat_area`, `_test_area_kotak_gambar`, `_test_area_kotak_digambar`) menulis angka eksplisit (-2,125; 0,375; 1,0; 1,5; pusat -1,625 dan 1,625; proyeksi iso 32 dan 16 ditulis ulang). Tidak ada pemanggilan `Config.JALAN_UJI_*_KOTAK_SURAT_UBIN` di tes baru; fungsi yang dites dipanggil hanya sebagai SUT, oracle ditulis terpisah. Satu celah: nilai mutlak `AREA_KOTAK_ISI_ALPHA` dan `AREA_KOTAK_TEPI_ALPHA` tidak dipatok (QA-010).

### Dampak desain (diperiksa, bukan diasumsikan)

| Butir | Cara | Hasil |
|---|---|---|
| (a) zona tidak bertumpuk dan terjangkau | `_test_keterjangkauan` (lama, tidak diubah) dibaca dan dijalankan: tiap zona kavling 0 dan bukan-pelanggan, tiga kecepatan; tes baru `not kotak_s.intersects(kotak_d)`; skrip QA `scan.gd` (scratchpad) pada 200 seed rute (5000 rumah pelanggan seberang): 0 tumpang tindih kotak surat dengan kotak/teras/jendela/halaman rumah LAIN, 0 zona menyeberang sisi | Hijau. Catatan: pusat zona tidak berubah, jadi keterjangkauan tes lama tidak menguji tepi baru; pusat tetap terjangkau, tepi tidak perlu terjangkau (area boleh lebih besar dari himpunan yang bisa dicapai) |
| (b) 0,125 ubin halaman tertimpa | tes literal Dev di kedua sisi (-2,05, -2,124, -2,126, 2,1, 2,125, daftar dibalik) dibaca; mutan Q05/Q06 (prioritas dibalik penuh dan sebagian) | Titik di strip dinilai KOTAK_SURAT, di luar strip HALAMAN; mutan mati (41 dan 39) |
| (c) tidak jadi bisa dicapai dari titik tertutup | `scan.gd`: 4.532.352 titik sampel (grid 0,0625 ubin, tinggi 0) di dalam area kotak surat seberang pelanggan pada 200 seed lewat `MedanKoran.tertutup_titik` | 0 titik tertutup. Sisi dekat: 66% area baru tertutup rumah dekat (84% pada inti 0,5 x 0,5 lama), tidak ada rumah dekat pelanggan di perumahan (0 dari seed 1..50), jadi tidak ada dampak skor; hasilnya BUKAN_PELANGGAN sama dengan MELESET untuk bunyi dan penanda |
| (d) `jalan_uji.tscn` | `probe_koran_jendela.gd` dijalankan ke scratchpad (bukan repo) dan dua tangkapan dilihat: `kena_kanan_kotak_surat_dekat` dan `kena_atas_kotak_surat_seberang`. Kubus graybox seberang (pijak -1,5; 1,0) berada di dalam zona [-2,125..-1,125] x [0,375..1,875] | Benar. Kotak dekat ACCENT lebih besar, penanda centang tampil. Garis tepi halaman dekat menyilang isi kotak (QA-012) |

### Mutan QA (30 penggantian teks, di empat klon bersih, `run_tests.gd` penuh per mutan; semua klon dikembalikan)

Mati = jumlah `GAGAL:` baru. Daftar berbeda dari 16 mutan Dev.

| # | Mutasi | Hasil |
|---|---|---|
| Q01 | seberang saja kembali 0,5 x 0,5 | mati (23) |
| Q02 | dekat saja kembali 0,5 x 0,5 | mati (5) |
| Q03 | seberang pusat maju +0,125 | mati (43) |
| Q04 | dekat pusat lateral +0,125 | mati (7) |
| Q05 | prioritas dibalik penuh | mati (41) |
| Q06 | halaman menang atas kotak surat saja | mati (39) |
| Q07 | area untuk rumah seberang bukan pelanggan | mati (29) |
| Q08 | area untuk rumah dekat pelanggan | mati (4) |
| Q09 | area dihitung untuk seluruh rute (luar jendela daur) | mati (11) |
| Q10 | area dobel (isi dua kali) | mati (16) |
| Q11 | alfa tepi 0 | mati (1) |
| Q12 | alfa isi 1,0 | mati (1) |
| Q13 | `memuat`: tepi maks inklusif | mati (9) |
| Q14 | `memuat`: tepi min eksklusif | mati (6) |
| Q15 | halaman seberang membesar | mati (1) |
| Q16 | teras seberang membesar | mati (8) |
| Q17 | jendela seberang membesar | mati (2) |
| Q18 | mode bantu membidik titik 0,25 dari sudut (juga kena pemindai literal) | mati (15) |
| Q18b | mode bantu membidik pojok maks zona | mati (76) |
| Q19 | kandidat bantu memakai tepi maks maju | mati (19) |
| Q20 | penggambar memakai geometri dekat (cermin) | mati (8) |
| Q21 | tanpa garis tepi | mati (17) |
| Q22 | garis tepi memakai `TEXT`, bukan `OUTLINE` | mati (1) |
| Q23 | area untuk jenis zona selain kotak surat | mati (16) |
| Q24a | `AreaKotak` di `rute.tscn` sesudah `Objek` | mati (1) |
| Q24b | `AreaKotak` di bawah `Tanah` | mati (1) |
| Q25 | dekat 1,0 x 1,0 | mati (7) |
| Q26 | seberang melebar ke aspal (lateral 1,2) | mati (26) |
| Q27 | `RuteMain` tidak memanggil `perbarui` area | mati (15) |
| Q28 | `AREA_KOTAK_ISI_ALPHA` 0,85 (menutup tanah) | **SELAMAT** -> QA-010, kini mati (1) dengan tes QA |
| Q29 | `AREA_KOTAK_TEPI_ALPHA` 0,3 (tidak tegas) | **SELAMAT** -> QA-010, kini mati (1) |
| Q30 | `AREA_KOTAK_ISI_ALPHA` 0,01 (area nyaris tak terlihat) | **SELAMAT** -> QA-010, kini mati (1) |

Skrip: `qa3/mutan.py`, `qa3/mutan2.py`, `qa3/scan.gd`, `qa3/scan2.gd` di scratchpad (tidak di-commit).

### Temuan

| ID | Severity | Lokasi | Deskripsi | Status |
|---|---|---|---|---|
| QA-010 | Minor | `tests/tes_rute.gd:_test_area_kotak_gambar`, `scripts/config.gd` `AREA_KOTAK_*_ALPHA` | Tes hanya memeriksa urutan alfa (isi > 0 dan < tepi), bukan nilai. Mutan Q28 (isi 0,85 menutup trotoar), Q29 (tepi 0,3), Q30 (isi 0,01, area hampir tak terlihat) selamat dengan 8296 lolos. Keterbacaan area adalah inti permintaan pemilik. | **FIXED oleh QA**: dua `check` pita (isi 0,15 sampai 0,5, tepi 0,7 sampai 1,0); Q28 sampai Q30 kini mati (1 gagal masing-masing); 8298 lolos |
| QA-011 | Minor | `docs/SETUP_ANDROID.md` 8.6 butir 3 dan 4 | Dua butir masih menyebut sasaran hanya "kubus oranye" dan butir 4 berbunyi "sasarannya hanya kubus oranye placeholder", padahal APK yang sama kini menggambar area. Butir 9 meminta "bandingkan dengan butir 3 (zona kecil)", tetapi butir 3 akan dijalankan pada build dengan zona besar, jadi pembanding "zona kecil" hanya ingatan pemilik. Tidak menghalangi uji; pemilik bisa tersesat memberi nilai. | DEFERRED (sunting butir 3 dan 4: sebut area; butir 9: "dibanding kesan sebelum perubahan") |
| QA-012 | Nit | `scripts/entities/zona_gambar.gd` (jalan uji dev) | Garis tepi halaman dekat (lateral 2,0) digambar sesudah isi kotak surat dekat yang kini 1,0 x 1,5, jadi menyilang isi ACCENT (terlihat di tangkapan jalan uji). Hanya scene dev, tidak memengaruhi penilaian. | DEFERRED |

Catatan non-temuan: klaim "toleransi jari sekitar +-3 mm" di BALANCING 5 dan `config.gd` adalah estimasi Dev; dihitung ulang QA dari `LEMPAR_SWIPE_*` (6% sampai 35% dari 780 px game untuk 3,5 ubin, sekitar 65 px game per ubin, sekitar 4,9 px game per mm pada layar 2340 px selebar ±158 mm) memberi ±3 mm untuk 0,25 ubin, jadi masuk akal, tetapi tetap perlu dinilai di HP (SETUP_ANDROID 8.6 butir 9).

### Validasi visual

`godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_rute_jendela.gd -- docs/loop/20261016-fase3a-rute/shots/qa3` dijalankan: "probe selesai, 0 keadaan tidak sesuai", tanpa ERROR/WARNING. Tangkapan lain dihapus; yang disimpan dan DILIHAT sendiri: `shots/qa3/2340x1080_rute_tengah.png` dan `shots/qa3/2340x1080_rute_bantu_centang.png` (plus potongan diperbesar area di scratchpad).

- Area terlihat sebagai belah ketupat oranye tipis di trotoar dengan sedikit rumput, kubus oranye di tengah; tidak menutupi sepeda, HUD, atau penanda centang (centang di kubus tetap terbaca di `bantu_centang`).
- Tidak bergantung pada warna isi: ada garis tepi gelap (`OUTLINE`) bertangga 1 piksel game, terbaca sebagai garis putus-putus rapat; masih terbaca di x3, tetapi tipis. Bukan temuan, disarankan dinilai di HP.
- Rumah bukan pelanggan (abu-abu) dan semua rumah dekat (kanan bawah) tanpa area. Sprite rumah tidak punya kotak merah ganda.

### Kepatuhan

- Static typing lengkap di `area_kotak_gambar.gd` (sama pola `ZonaGambar`; `_perintah: Array` tak bertipe elemen, selaras kode lama); komentar `##` berbahasa Indonesia; tidak ada angka ajaib baru (pemindai literal runner hijau, dua konstanta di `config.gd` satu baris literal); warna dari token `Palette` (`ACCENT`, `OUTLINE`), tanpa hex di skrip atau scene; tidak ada `kiri`/`kanan` pada baris tambahan; teks pemain tidak berubah.
- Dokumen sinkron dengan `config.gd`: BALANCING 5 (tabel dan catatan), DATA_SCHEMA 3 (p + 0,375 sampai p + 1,875, pusat p + 1,125), SETUP_ANDROID 8.6 butir 9 dan lembar hasil, LOOP-DEV-QA 6d (catatan Run 3B), LOG D-28 sampai D-32. Sisa: QA-011.
- Mutan Dev (16) terverifikasi mati lewat 27 mutan QA yang berbeda; tidak ada klaim Dev yang bertentangan dengan hasil jalankan QA.

### NEEDS-MANUAL

Tidak berubah dari catatan Dev: SETUP_ANDROID 8.6 butir 9 (area terbaca, tidak mengganggu, kena santai/cepat/ngebut, terlalu mudah atau pas) di HP; ukuran 1,0 x 1,5 tetap usulan. QA tidak menyentuh HP atau adb. Fase 3 dan `DEV_PHASES.md` tidak boleh dicentang untuk butir yang bergantung pada uji HP.

- **QA-011 (Minor) ditutup oleh orchestrator:** `SETUP_ANDROID.md` 8.6 butir 3 dan 4 disamakan dengan butir 9 (sasaran = area oranye tipis dengan kubus di tengahnya). QA-012 (Nit, garis halaman menyilang kotak surat dekat di jalan uji dev) tetap DEFERRED.
