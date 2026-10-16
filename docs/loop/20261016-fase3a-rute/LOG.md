# Loop Log — 20261016-fase3a-rute
Scope: Run 3A Fase 3, fondasi rute (segmen JSON, RouteBuilder berseed, scene rute, zona dari data, penutup semi-transparan)  ·  Branch: `feat/fase3a-rute`  ·  Mulai: 2026-10-16  ·  Godot: 4.7.2

## Status: IN_PROGRESS   (iterasi saat ini: 1/2, bagian A dan B selesai, menunggu QA)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 1a | Bagian A (logika murni): 9 segmen JSON, `SegmenRute`/`PemuatRute`/`RouteBuilder`/`PenutupPemain`, zona dari rute, `tes_rute.gd`; scene belum | ✅ import bersih; 7853 lolos, 0 gagal (`--ketat` 0 peringatan); `--quit-after 2` bersih; 4 `uji_*.py` lolos; `--export-pack` memuat 9 JSON | menunggu bagian B | 0 | 0 |
| 1b | Bagian B: `rute.tscn` jadi scene utama (rumah dan kotak surat dari data, jendela daur, zona dan mode bantu dari data rute, akhir rute + banner + Main lagi, penerap penutup tunggal), `AdeganJalan` dasar bersama, `tes_rute_scene.gd`, `probe_rute_jendela.gd`, dokumen | ✅ import bersih; 8117 lolos, 0 gagal (`--ketat` 0 peringatan); `--quit-after 2` bersih; 4 `uji_*.py` lolos; `--export-pack` memuat 9 JSON + `rute.tscn`, tanpa `tests/` dan `docs/`, rute dimuat dari paket; probe 2340x1080 dan 1600x720 bersih | menunggu | 0 | 0 |

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
