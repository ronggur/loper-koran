# Loop Log — 20261016-fase3a-rute
Scope: Run 3A Fase 3, fondasi rute (segmen JSON, RouteBuilder berseed, scene rute, zona dari data, penutup semi-transparan)  ·  Branch: `feat/fase3a-rute`  ·  Mulai: 2026-10-16  ·  Godot: 4.7.2

## Status: IN_PROGRESS   (iterasi saat ini: 1/2)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 1a | Bagian A (logika murni): 9 segmen JSON, `SegmenRute`/`PemuatRute`/`RouteBuilder`/`PenutupPemain`, zona dari rute, `tes_rute.gd`; scene belum | ✅ import bersih; 7853 lolos, 0 gagal (`--ketat` 0 peringatan); `--quit-after 2` bersih; 4 `uji_*.py` lolos; `--export-pack` memuat 9 JSON | menunggu bagian B | 0 | 0 |

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## NEEDS-MANUAL (uji di HP)
- [ ] Rute dari awal sampai garis akhir tanpa patah, 60 fps, memuat < 1 detik; tiga seed berbeda tidak terasa dihafal.
- [ ] Kotak surat kena dengan sengaja di santai/cepat/ngebut; mode bantu mengenai kotak surat pelanggan terdekat.
- [ ] Objek penutup semi-transparan terbaca; rumah dan kotak surat tajam di ×3.
- [ ] Banner "Rute selesai" dan tombol "Main lagi" terbaca dan tidak tersentuh tak sengaja.
- [ ] Hasil uji HP Fase 2 (SETUP_ANDROID 8.5) belum diisi pemilik; Fase 2 dan M1 tetap tidak dicentang.

## Keputusan & catatan
- Keputusan pemilik 2026-10-16 ("ok semua"): K-1 segmen JSON; K-2 9 segmen, 7 per rute, 25 pelanggan, koran awal 30; K-3 id rumah `<id_segmen>@<pos>`, pemetaan ke save ditunda ke Fase 6; K-4 scene baru `scenes/rute/rute.tscn`, jalan uji tetap dev; K-5 akhir rute berhenti + banner sementara + "Main lagi" dev. Rincian di `SPEC.md`.
- Pemilik belum menjalankan uji HP Fase 2; 3A dimulai tanpa hasilnya.
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

