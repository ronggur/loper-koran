# Loop Log — 20261023-fase6a2-reputasi-pelanggan
Scope: Run 6A2, Fase 6A bagian kedua: reputasi per distrik, pelanggan tetap (aktif/setia/berhenti, kepribadian), pemetaan pelanggan tetap ke rute yang diacak, potongan koran terbuang (K-1 pemilik), milestone dasar  ·  Branch: feat/fase6a2-reputasi-pelanggan  ·  Mulai: 2026-10-23  ·  Godot: 4.7.2

## Status: IN_PROGRESS   (iterasi saat ini: 1/2; Dev iterasi 1 bagian A dan bagian B selesai, bagian C belum dimulai)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 0 | Persiapan orchestrator: SPEC, baseline | ✅ | - | - | - |
| 1A | Logika murni reputasi, pelanggan tetap, save v4, RouteBuilder dengan keadaan, sim_ekonomi | ✅ (19668 lolos, 0 gagal) | - | - | - |
| 1B | Potongan koran terbuang: SkorRute/HasilRute/catat_hari, umpan "-5", HUD koin bersih, layar hasil | ✅ (19872 lolos, 0 gagal) | - | - | - |

## Baseline (orchestrator, `main` = 726b59c, branch dari main terbaru, 2026-10-23)
- `godot --headless --import`: 0 baris ERROR/WARNING. `godot --headless --path . --quit-after 2`: 0 baris ERROR/WARNING.
- `run_tests.gd`: **19281 lolos, 0 gagal**; `tools/cek_keluaran_tes.py`: lolos (0 peringatan).
- Semua `tools/tests_cek/uji_*.py` (14 berkas) exit 0.
- sha256 `user://save.json` asli (`~/Library/Application Support/Godot/app_userdata/Kring Kring!/save.json`): `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e`.
- HP: `adb devices` kosong (tidak ada perangkat tersambung saat persiapan).
- Hasil uji HP Run 5D: **tidak diisi pemilik** (baris ISI kosong). QA-001/002/003 5D tidak ditutup; 8.16 NEEDS-MANUAL; butir aset Fase 5 tidak dicentang.
- Fakta data: 9 segmen perumahan, 71 rumah `pelanggan_boleh` (37 seberang, 34 dekat); satu rute memakai 7 dari 9 segmen (sekitar 55 kandidat), jadi pelanggan tetap yang segmennya tidak terpilih hari itu memang tidak muncul hari itu.

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## NEEDS-MANUAL (uji di HP)
Lihat SPEC bagian NEEDS-MANUAL dan SETUP_ANDROID 8.17 (dibuat Dev di bagian C).

## Keputusan & catatan
- Keputusan pemilik K-1..K-4 dan keputusan orchestrator O-1..O-10: SPEC. K-4 (tiga keputusan terbuka) dipakai sebagai rekomendasi tunggal yang ditulis pemilik di perintah run, tidak ditanyakan ulang; dilaporkan di laporan akhir untuk ditolak di review PR bila perlu.
- Izin pemilik (perintah run): sesudah QA PASS orchestrator boleh memasang APK ke vivo V2108 (`adb install -r`), push dan buka PR; merge menunggu konfirmasi pemilik.


## Iterasi 1, bagian A (Dev)

Cakupan: AC-1 sampai AC-7 (logika murni, save, RouteBuilder, simulasi), tanpa UI. Branch `feat/fase6a2-reputasi-pelanggan`, commit kecil, tidak push.

### Gerbang (dijalankan sendiri, satu proses Godot sekaligus)
- `godot --headless --import`: 0 baris ERROR/WARNING.
- `run_tests.gd` + `tools/cek_keluaran_tes.py`: **19668 lolos, 0 gagal, 0 peringatan** (baseline `main` 19281; +387 pemeriksaan: `tes_reputasi` 185, `tes_rute_pelanggan` 43, `tes_save_v4` 66, sisanya perbaikan tes lama yang mengunci SAVE_VERSI 3 dan contoh DATA_SCHEMA).
- `godot --headless --path . --quit-after 2`: 0 ERROR/WARNING.
- 14 `tools/tests_cek/uji_*.py`: semua exit 0.
- sha256 `user://save.json` asli: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e` (tidak berubah; tes memakai `user://tes_save_v4/` dan `TesSaveV4` membandingkan jejak sebelum/sesudah).
- `--export-pack "Android"`: `assets/data/customers/kepribadian.json` ikut paket (dicek dengan `strings`); `tes_export` menambah 5 jalur wajib.

### Yang dibuat (ringkas)
- `scripts/systems/`: `reputation_manager.gd` (`ReputationManager`: `terapkan`, `catat`, `catatan_misi`, struktur `Catatan`/`CatatanRumah`/`CatatanMisi`/`Peristiwa`/`Hasil`), `pelanggan_rute.gd` (`PelangganRute`), `kepribadian_pelanggan.gd` (`KepribadianPelanggan`: validasi, FNV-1a, `dari_id`), `pemuat_pelanggan.gd` (`PemuatPelanggan`, satu-satunya pembaca berkas). `route_builder.gd` (+ `bangun(..., pelanggan)`, `_pilih_pelanggan_keadaan`, `_pilih_pemberi_tip_keadaan`, `_cocokkan_bonus`, diagnosa `Rute.pelepasan`/`dikenal_kurang`), `skor_rute.gd` (+ `Kualitas`, `Keadaan.kualitas`, `kualitas_rumah`; pencatat saja), `data_save.gd` (v4), `data_misi.gd` (+ validasi dan `gagal_reputasi()`), `config.gd` (`REPUTASI_*`, `PELANGGAN_*`, `SAVE_VERSI` 4).
- `scripts/entities/`: `rute_main.gd` (`atur_pelanggan`, `catatan_pelanggan()`, `hasil_reputasi()`, `pelanggan_rute()`), `hari_main.gd` (kirim state + pustaka kepribadian, isi `CatatanHari.pelanggan`/`kepribadian`). Tidak ada perubahan tampilan.
- Data: `assets/data/customers/kepribadian.json`. Docs: DATA_SCHEMA 4 (tabel field, contoh nyata, aturan, migrasi v3 -> v4) dan bagian baru 4b (kepribadian), BALANCING 7.2 + catatan perubahan.
- Tes: `tes_reputasi.gd`, `tes_rute_pelanggan.gd`, `tes_save_v4.gd`, `sim_ekonomi.gd` (+ `sim_ekonomi_laporan.gd`), `ukur_golden_rute.gd` + `tests/data/golden_rute_main.json`; terdaftar di `run_tests.gd`.

### Keputusan teknis dan alasannya
1. **Golden dari `main`, bukan angka tangan.** `tests/ukur_golden_rute.gd` dijalankan sekali pada commit yang `route_builder.gd`-nya identik dengan `main` (blob `ef5a6e183eb2...` dicatat di berkas JSON; baris pertama hari 1 sama dengan `GOLDEN_HARI1` lama di `tes_sisi_dekat_b`). `TesRutePelanggan` membandingkan sidik FNV-1a identitas rute untuk 60 seed x hari 1..5 tanpa keadaan (300 kombinasi) dan dengan keadaan kaya di hari 1-2 (120 kombinasi): selisih 0.
2. **Desain pemilihan pelanggan (`_pilih_pelanggan_keadaan`).** Segmen dan undian kuota dekat persis seperti rute tanpa keadaan; setelah itu: (a) rumah `berhenti` keluar dari kolam kecuali satu "calon kembali" (sudah 3 hari; diundi bila lebih dari satu); (b) setia dan calon kembali menjadi **prioritas** lewat bonus biaya besar di DP pencocokan (`_cocokkan_bonus`, `PELANGGAN_BONUS_PRIORITAS_UBIN`), jadi pasti terpilih selama ada susunan sah; prioritas setia per sisi dibatasi lantai 60% kuota sisi; (c) rumah baru dibatasi 6 per rute di sisi yang pelanggan dikenalnya >= kuota + 4 (sisi yang kurang dikenal, mis. sisi dekat di hari 3, dilonggarkan); (d) pemberi tip: 7 tetap, kepribadian `pemberi_tip` didahulukan. Sifat yang dijaga: keadaan KOSONG memberi pelanggan yang SAMA dengan rute tanpa keadaan (konsumsi RNG tidak berubah bila tidak ada yang diundi), dites.
3. **Penyimpangan kecil dari O-7 (b): setia di luar prioritas tidak dikeluarkan.** Versi pertama mengeluarkan setia kelebihan (di atas 60%) dari kolam; ternyata kolam terlalu sempit dan pelepasan prioritas terjadi di ~45% rute. Sekarang kelebihan setia tetap kandidat biasa: yang dijamin adalah >= min(tersedia, 60% kuota) setia per sisi, bukan batas atas keras. Urutan prioritas setia memakai "titik tersebar" (farthest-point sampling, satu undian RNG untuk titik pertama) supaya melepas ekor daftar melepas setia yang paling berdekatan; ini tafsir saya atas "setia terjauh dulu".
4. **Pelepasan bertahap, tidak pernah gagal bangun.** Urutan: tingkat 0 semua aturan; tingkat 1 batas pelanggan baru dicabut; lalu prioritas dilepas seperempat demi seperempat (calon kembali terakhir); lalu larangan `berhenti` dicabut (prioritas penuh dulu, dilepas lagi bertahap). Tiap tingkat 60 percobaan jitter. `Rute.pelepasan` (tingkat) dan `Rute.dikenal_kurang` jadi diagnosa yang dites. Di 1200 kombinasi acak: 0 rute gagal; >= 800 tanpa pelepasan. Di simulasi 45 hari x 12 benih x 3 profil: pelepasan di 3% sampai 6% hari.
5. **Struktur save v4.** `reputasi` {distrik: int} (distrik awal selalu ada) dan `pelanggan` {id: {status, antar, meleset, hari_berhenti}}; kepribadian tidak disimpan. `catat_hari` menerima **masukan** (`CatatanHari.pelanggan` + `kepribadian`) dan memanggil `ReputationManager.terapkan` sekali: fungsi murni, hasilnya identik dengan yang dihitung `RuteMain` untuk layar hasil (bagian C tidak perlu menyalin hasil). `RuteMain.hasil_reputasi()` tersedia sesudah layar hasil terbuka. Migrasi v3 -> v4 menimpa field v4 liar di berkas berversi 3 dengan awal. Saya TIDAK menyentuh baris koin `catat_hari` supaya bagian B bebas menambah potongan; blok reputasi ada di antara `_catat_sepeda` dan tutorial.
6. **Rumus kredit.** Kredit per antaran: tepat 4, teras 3, kotak surat 2, halaman 1 (jendela bonus = halaman); poin harian = kredit / 30 bulat ke bawah (tanpa sisa dibawa, karena SPEC tidak mengizinkan field save tambahan) + poin misi (1/2/3), dipagari +6; turun -1 per pelanggan berhenti dan `gagal.reputasi`. Dipilih supaya hari rapi pemain teliti (sekitar 70 kredit) jatuh di tengah dataran +2 (60..89), sehingga laju mendekati 2 poin per hari tanpa tebing pembulatan.
7. **Urutan tiga tahap di `ReputationManager`** (pelanggan baru dibuat -> misi -> antaran/meleset) supaya misi bisa menjadikan pelanggan baru hari itu `setia` dan rumah `berhenti` yang kebetulan titik kucing kembali lewat misi; rumah yang kembali lewat misi tidak dihitung lagi di tahap 3 (satu KEMBALI, penghitung 0). Rumah titik tangkap yang BUKAN pelanggan dan tanpa entri: tidak ada efek (sesuai O-6).
8. **`DataMisi.gagal_reputasi()`** + validasi `gagal.reputasi` 0..1 (bilangan bulat); field `gagal` lain tetap longgar seperti sebelumnya. `REPUTASI_BAWAAN` (4A, dipakai `HeadlineManager`) tidak diubah; `REPUTASI_AWAL` baru untuk save. `rep_min` misi/headline belum membaca reputasi save (di luar scope A; catatan untuk C/6B).

### Hasil `sim_ekonomi` (AC-7) — ringkas; tabel lengkap dan asumsi di BALANCING 7.2
Asumsi diumumkan (akurasi lemparan tetap per profil, ulang saat meleset, misi P1 tiap 8 hari; fisika tidak disimulasikan). 12 benih x 45 hari: **santai mencapai reputasi 40 pada hari 17 sampai 20** (sasaran 16 sampai 24), rata-rata 2,0 sampai 2,3 poin per hari; campuran hari 25 sampai 33; ngebut 40 sampai 45 atau belum dalam 45 hari (8 dari 12 benih; akurasi 60% dan 40% sering meleset). Perubahan harian -2 sampai +4 (tidak ada yang melonjak > 6; kenaikan mentah sebelum pagar juga <= 6), reputasi tidak pernah < 0. Ini memenuhi AC-7, tetapi catatan untuk pemilik: pemain yang sering meleset (asumsi ngebut) bisa memerlukan > 45 hari untuk reputasi 40; dinilai di HP (SETUP_ANDROID 8.17 oleh bagian C).

### Mutan (AC-18, bagian A): 34 mutan nyata, semuanya tertangkap
Harness: `mutan.py` (di scratchpad, bukan di repo) memasang satu penggantian teks pada kode produksi, menjalankan `tes_reputasi` + `tes_rute_pelanggan` + `tes_save_v4`, memulihkan berkas. Hasil (tes penangkap pertama dalam kurung):
M01 berhenti `>` bukan `>=` (transisi aktif -> berhenti); M02 setia `>` bukan `>=` (transisi aktif -> setia); M03 meleset tidak direset antaran; M04 kembali tidak mereset antar; M05 non-sensitif bisa berhenti; M06 setia tidak lebih sabar; M07 cerewet tetap dapat kredit halaman; M08 reputasi tidak dijepit; M09 pagar harian dibuang; M10 penalti berhenti 0; M11 misi tidak mengembalikan berhenti; M12 kredit tepat = kotak surat; M13 poin dibulatkan ke atas; M14 `terapkan` mengubah state masukan; M15 hadiah `pelanggan_setia` tidak menjadikan setia; M16 pengali FNV salah; M17 `dari_id` mengabaikan hash (semua di `tes_reputasi`); M18 rumah berhenti ikut terpilih; M19 setia tanpa bonus prioritas; M20 calon kembali tidak pernah; M22 pemberi tip acak tanpa kepribadian; M23 golden tanpa keadaan bergeser (goyangan target 1%, 6 dari 300 sidik berubah); M24 keadaan dipakai juga hari 1-2; M25 larangan berhenti tidak pernah dicabut (rute gagal bangun di 12 dari 1200); M33 batas baru dicabut di semua sisi; M34 kuota seberang kurang satu (semua di `tes_rute_pelanggan`/sim); M26 migrasi v3 tidak mengganti field v4 liar; M27 `catat_hari` menerapkan dua kali; M28 normalisasi reputasi tanpa jepit; M29 `hari_berhenti` non-berhenti tidak dinolkan; M30 `salin` tidak menyalin kualitas (itu `tes_reputasi`); M31 `catat_hari` melewati penerapan; M32 tipe kunci `reputasi`/`pelanggan` dilepas (di `tes_save_v4`/sim).
- **M21 (batas pelanggan baru diabaikan) AWALNYA LOLOS**: tes (c) hanya menegaskan `baru <= 6 kecuali dikenal_kurang`, dan mutan membuat `dikenal_kurang` selalu true. Diperbaiki dengan `_test_batas_baru` (batas harus benar-benar mengikat di >= 60 rute, 0 pelanggaran, dan hari 3 sisi dekat dilonggarkan); M21 dan M33 kini tertangkap. Itu satu-satunya mutan lolos.

### Menyimpang dari SPEC / catatan untuk bagian B dan C
- BLOCKED: tidak ada.
- Menyimpang dari O-7 (b): lihat keputusan 3 (kelebihan setia tidak ditunda). Menyimpang dari O-7 teks "setia terjauh dulu": lihat keputusan 3 (ekor daftar tersebar).
- `Angka.meleset` dan potongan koran tidak disentuh; `SkorRute.Keadaan.terbuang` belum ada (bagian B). `Keadaan.salin` sudah menyalin `kualitas`, B perlu menambah `terbuang` ke `salin` juga.
- Untuk C: `RuteMain.hasil_reputasi()` (`ReputationManager.Hasil`: `reputasi_sebelum/sesudah`, `perubahan`, `jumlah(Jenis.BARU/SETIA/BERHENTI/KEMBALI)`) siap dibaca setelah `hasil_dibuka`; HUD rute dapat membaca `ReputationManager.reputasi_di(state, "perumahan")` dari state save yang diberikan ke `atur_pelanggan`. `tes_alur_hari` kini membandingkan contoh DATA_SCHEMA 4 secara semantik (25 pelanggan nyata, 3 ditampilkan di dokumen).
- `tests/sim_ekonomi.gd` adalah pembantu `class_name SimEkonomi` (dipanggil `TesReputasi`); `tests/sim_ekonomi_laporan.gd` mencetak laporan (`-- 45 rinci`).
- Belum dikerjakan (bukan scope A): AC-8 sampai AC-16, AC-19 (dokumen selain DATA_SCHEMA/BALANCING), AGENTS.md, README docs, ROADMAP, GDD.


## Iterasi 1, bagian B (Dev)

Cakupan: AC-8 sampai AC-11 (potongan koran terbuang, K-1/K-2/O-1/O-2/O-3). Bagian C (milestone, penanda reputasi, ikon dan bunyi baru, probe jendela, dokumen penutup) tidak dikerjakan. Branch `feat/fase6a2-reputasi-pelanggan`, commit kecil, tidak push.

### Gerbang (dijalankan sendiri, satu proses Godot sekaligus)
- `godot --headless --import`: 0 baris ERROR/WARNING.
- `run_tests.gd` + `tools/cek_keluaran_tes.py`: **19872 lolos, 0 gagal, 0 peringatan** (bagian A 19668; +204 pemeriksaan: `tes_potongan` murni, `tes_potongan_scene`, sisanya penyesuaian oracle lama).
- `godot --headless --path . --quit-after 2`: 0 ERROR/WARNING.
- 14 `tools/tests_cek/uji_*.py`: semua exit 0.
- sha256 `user://save.json` asli: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e` (tidak berubah; alur hari memakai `user://tes_potongan_scene/`, `TesPotonganScene` membandingkan jejak sebelum/sesudah, dan runner memeriksa lagi di akhir).
- Paket ekspor: tidak ada berkas data atau aset baru di bagian B (hanya skrip, scene, terjemahan); `tes_export` hijau. Tidak menjalankan ulang `--export-pack`.

### Yang dibuat (ringkas)
- `scripts/config.gd`: `KOIN_POTONGAN_KORAN_MELESET` = 5 (satu baris literal).
- `scripts/systems/skor_rute.gd`: `Keadaan.terbuang` (disalin di `salin`), naik untuk `TIDAK_SAH` dan `ULANG`, tidak untuk `ANTAR`; `SkorRute.potongan(k)` dan `SkorRute.hasil_terbuang(h)`. Skor, koin kotor, combo tidak disentuh.
- `scripts/systems/hasil_rute.gd`: `Angka.lempar_terbuang`, `potongan`, `koin_bersih` (properti `koin - potongan`, jadi Angka rakitan tes ikut konsisten), `HasilRute.saldo_sesudah(saldo_lama, koin_bersih)` dan `koin_dijepit`. `Angka.koin` tetap bruto (ongkos + tip + hadiah misi).
- `scripts/systems/data_save.gd`: saldo = `max(0, lama + (koin_kotor - potongan)) - belanja`; `koin_total` += koin kotor; `terakhir.potongan` (field angka baru di `_TERAKHIR_ANGKA`, bawaan 0 untuk save lama). Blok reputasi bagian A tidak diubah. `scripts/entities/hari_main.gd`: saldo awal bengkel lewat `HasilRute.saldo_sesudah` (satu rumus dengan save).
- Tampilan: `UmpanMelayang.Entri.potongan` + `dari_potongan`; `VfxAntaran.item_entri` tidak memutar bintang/koin untuk entri potongan; `UmpanMelayangGambar` teks `-{n}` (kunci `RUTE_UMPAN_POTONGAN`) berwarna `TEXT_2`; `AdeganJalan._saat_koran_mendarat` menambah entri "-5" di titik mendarat bila terbuang, `_koin_tampil()` (koin bersih) ke panel koin HUD. Layar hasil: baris `LabelTerbuang`/`NilaiTerbuang` dan `LabelBersih`/`NilaiBersih` di daftar netral (hanya bila ada koran terbuang), `TeksSaldoNol` (hanya bila saldo benar-benar dijepit), `isi(..., saldo_lama)`; `RuteMain._buka_hasil` meneruskan `koin` dari state save. Kunci baru di `translations/ui.csv`: `RUTE_UMPAN_POTONGAN`, `HASIL_TERBUANG(_ANGKA)`, `HASIL_KOIN_BERSIH(_ANGKA)`, `HASIL_SALDO_NOL`.
- Tes: `tests/tes_potongan.gd` (Config, status, 25/30/semua kena/tanpa lemparan, campuran, `catat_hari`, fuzz 10.000 hari vs oracle bilangan bulat, umpan, golden skor, 1000 urutan acak), `tests/tes_potongan_scene.gd` (lemparan nyata: meleset/ulang/antaran, "-5", HUD, mode bantu, jeda, Main lagi, HUD koin negatif di empat ukuran kanan dan kidal, layar hasil di empat ukuran termasuk kasus terpadat, hasil dari rute, dua alur `hari.tscn`), `tests/pembantu_golden_skor.gd`, `tests/ukur_golden_skor.gd`, `tests/data/golden_skor_main.json` (dibuat dari checkout `main` di worktree sementara, blob `skor_rute.gd` `0329ad5b...` dicatat; worktree sudah dihapus). Terdaftar di `run_tests.gd`.
- Dokumen (hanya sejauh perlu): GDD 2 (pengecualian prinsip 2), 8, 14.1; BALANCING 5 (baris jendela), 7, bagian baru 7.3, 10; DATA_SCHEMA 4 (`koin`, `koin_total`, `terakhir.potongan`); rule `00-project-core` prinsip 2 dan `balancing`.

### Keputusan teknis dan alasannya
1. **`Angka.koin_bersih` properti, bukan field.** Banyak tes lama merakit `HasilRute.Angka` dengan `.koin = X`; sebagai properti turunan (`koin - potongan`) mereka tetap benar tanpa diubah, dan tidak ada dua sumber yang bisa melenceng.
2. **Potongan di `Angka.potongan`, bukan di `Keadaan.koin`.** `SkorRute.Keadaan.koin` tetap koin kotor sehingga semua golden skor/koin lama utuh (dibuktikan golden dari `main`: 1000 urutan acak, sidik field lama sama persis).
3. **`catat_hari` memakai `koin_hari - max(potongan, 0)`** (bukan `koin_bersih` mentah) supaya jaminan lama "angka koin negatif tidak pernah mengurangi saldo" (`tes_hari`) tetap berlaku untuk koin kotor negatif; `koin_total` tetap koin kotor.
4. **`terakhir.potongan` tanpa kenaikan `SAVE_VERSI`.** `terakhir` dinormalisasi dari daftar field dengan bawaan 0, jadi save v4 lama terbaca tanpa migrasi. Oracle tes lama yang membandingkan dict `terakhir` persis (`tes_hari`, `tes_misi_save`, `tes_save_v3`, `tes_alur_hari`) dan contoh DATA_SCHEMA diberi `"potongan": 0`; tidak ada angka emas skor/combo/tenggat yang diubah.
5. **Umpan "-5" memakai antrean `UmpanMelayang` yang sama** (maks 2 sekaligus, `UMPAN_MELAYANG_MAKS` tidak diubah). Dua tes lama yang menegaskan "meleset/ulang: tanpa label" (`tes_vfx_sprite` 546/547) dan HUD koin "30" (`tes_rintangan_scene` 618, sekarang "25" karena satu koran ulang terbuang) diperbarui ke perilaku baru; yang ditegaskan tetap tanpa bintang dan koin.
6. **Baris layar hasil tersembunyi bila tidak ada koran terbuang**, jadi layar hari bersih identik dengan sebelumnya (tes lama tidak berubah). `teks_tampil`/`rect_label` kini melewati label tersembunyi. Baris "Saldo mulai lagi dari 0" memerlukan saldo lama; rute yang dijalankan sendiri (tanpa state save) tidak menampilkannya.
7. **Satu rumus saldo** `HasilRute.saldo_sesudah` dipakai `DataSave.catat_hari` dan saldo awal bengkel di `HariMain`, jadi saldo bengkel (belanja) dan save tidak bisa berbeda.
8. **Tes tahan error skrip.** Penjagaan `get_child(0)`/`back()` pada daftar kosong ditambahkan karena error skrip di dalam coroutine tes membuat runner menggantung bila umpan hilang (ditemukan saat mutan M14).

### Mutan (AC-18, bagian B): 30 mutan nyata, semuanya tertangkap
Harness: `mutan_b.py` + `runner_b.gd` (di scratchpad, bukan di repo) memasang satu penggantian teks pada kode produksi, menjalankan runner cepat (`TesPotongan`, `TesPotonganScene`, `TesSkor`, `TesHasil`, `TesHari`, `TesMisiSave`, `TesSaveV3/V4`, `TesVfxSprite`, `TesRintanganScene`; 1002 pemeriksaan, nol gagal pada kode asli), lalu memulihkan berkas (`git status` bersih sesudah tiap mutan). Penangkap pertama dalam kurung:
M01 ULANG tidak dihitung terbuang; M02 TIDAK_SAH tidak dihitung; M03 ANTAR dihitung terbuang; M04 `salin` lupa `terbuang`; M05 potongan dari `Angka.meleset`; M06 `lempar_terbuang` dari `Angka.meleset`; M07 `koin_bersih` abaikan potongan; M08 `saldo_sesudah` tidak dijepit 0; M09 `koin_total` memakai bersih; M10 `catat_hari` abaikan potongan; M11 `terakhir.potongan` selalu 0; M12 potongan tidak ikut mode bantu (`tes_potongan_scene`); M13 HUD koin tanpa potongan; M14 umpan "-5" tidak ditambahkan; M15 saldo awal bengkel pakai koin kotor (alur hari minus); M16 konstanta 6 (literal Config); M17 potongan memutar bintang; M18 baris "saldo dijepit" mengabaikan saldo; M19 baris potongan selalu tampil; M20 potongan x3; M21 label potongan berwarna OK; M22 saldo lama tidak diteruskan ke layar hasil; M23 `hasil_terbuang` abaikan ULANG; M24 `koin_dijepit` salah; M25 belanja tidak dikurangi dari saldo; M26 potongan negatif tidak dijepit; M27 `dari_potongan` jumlah tetap 1; M28 `putus_combo` menghapus terbuang; M29 `terakhir.potongan` tidak dinormalisasi; M30 Main lagi tidak mereset terbuang. Semua di `tes_potongan` atau `tes_potongan_scene` kecuali M29 (`tes_hari`). Satu percobaan awal (M14 dengan baris dihapus) adalah mutan tidak sah (parse error: badan `if` kosong), diganti `pass`; tidak ada mutan yang lolos. Catatan: M08 dan M24 hanya tertangkap di tingkat fungsi pembantu karena `catat_hari` menjepit ulang; saldo bengkel tetap dijaga M15 dan alur hari minus.

### Menyimpang dari SPEC / catatan untuk bagian C
- BLOCKED: tidak ada. Penyimpangan dari SPEC: tidak ada pada isi AC-8 sampai AC-11.
- Kekurangan yang perlu diketahui: **tangkapan layar belum dilihat** (probe jendela adalah bagian C, AC-16). Tata letak dites lewat geometri di empat ukuran (panel koin HUD negatif tidak menimpa panel skor/progres/kondisi/radar, kanan dan kidal; layar hasil kasus terpadat termasuk potongan + rekap misi + tiga baris kondisi + saldo dijepit muat di 360 px dan tombol >= 42 px), tetapi bagian C/QA sebaiknya melihat tangkapan hari minus dan kasus terpadat. `tes_potongan_scene` membangun kasus terpadat dengan angka tenggat lewat tetapi tanpa baris pelanggan/milestone bagian C: ruang vertikal baris baru bagian C (reputasi, pelanggan, milestone) perlu dicek ulang karena panel sudah sepadat itu.
- Untuk C: `LayarHasil.isi(angka, misi, perlu_bengkel, saldo_lama)`; urutan node di `IsiHasil`: judul, daftar berhasil, daftar netral (meleset, terbuang, bersih), `TeksTenggat`... `TeksSaldoNol` berada tepat di bawah `TeksTenggat`. `HasilRute.Angka` kini punya `lempar_terbuang`, `potongan`, `koin_bersih`. Kunci terjemahan baru sudah ada; bunyi/ikon untuk potongan tidak ditambahkan (umpan "-5" tanpa bunyi, pilihan: potongan tidak menghukum dengan bunyi negatif; bisa dinilai di HP).
- NEEDS-MANUAL untuk SETUP_ANDROID 8.17 (bagian C menulisnya): potongan 5 terasa adil, "-5" terbaca dan tidak mengganggu, hari minus terbaca netral, tidak membuat pemain takut melempar.
- Belum disentuh (bagian C/penutup): DEV_PHASES, ROADMAP 5, LOOP-DEV-QA 6f/6g, docs/README, AGENTS.md peta, SETUP_ANDROID 8.17, DESIGN_SPEC layar hasil/HUD.
