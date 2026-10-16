# SPEC — 20261016-fase3a-rute

Run 3A Fase 3 (M2, prototype 3): fondasi rute. Branch `feat/fase3a-rute`, dari `main` `51aaedf` (sudah memuat PR #26 dan #27).

## Tujuan

Mengganti jalan uji tanpa ujung sebagai scene utama dengan **satu rute perumahan sungguhan** yang disusun dari segmen JSON buatan tangan lewat urutan acak berseed: rumah pelanggan dan bukan pelanggan dari data, zona sasaran dan mode bantu dari data rute, akhir rute yang jelas, dan objek penutup semi-transparan. Rintangan (perilaku), tabrakan, skor, radar, HUD rute, tenggat, dan layar hasil bukan bagian run ini (3B dan 3C).

## Keputusan dari pemilik (2026-10-16, "ok semua" atas rekomendasi orchestrator)

- **K-1 Format segmen**: JSON tulisan tangan di `assets/data/routes/perumahan/<id>.json`, bukan scene Godot yang diekspor.
- **K-2 Ukuran**: 9 segmen, panjang 24 sampai 40 ubin; satu rute memakai **7** segmen dari seed (pembuka `tenang` dan penutup `tenang`), sekitar 250 ubin; pelanggan **tepat 25** (konstanta `Config`); koran awal = pelanggan + 20% (25 → 30, sama dengan `Config.KORAN_AWAL` jalan uji, BALANCING 4).
- **K-3 Pelanggan tetap**: di 3A id rumah = `<id_segmen>@<pos>`, pelanggan dipilih dari rumah `pelanggan_boleh` lewat RNG berseed rute. Pemetaan ke id rumah tetap di save (`per_r014`, DATA_SCHEMA 4) **ditunda ke Fase 6**; 3A tidak menulis save.
- **K-4 Scene**: scene baru `scenes/rute/rute.tscn` menjadi `run/main_scene`; `scenes/dev/jalan_uji.tscn` tetap sebagai scene dev dan tes lamanya tidak diubah kecuali dengan alasan tertulis. Komponen yang ada (sepeda, kontrol touch, HUD, layar jeda, koran, garis bidik) dipakai ulang.
- **K-5 Akhir rute**: sepeda berhenti di garis akhir dengan laju rem, input stick dikunci, banner sementara "Rute selesai" lewat kunci terjemahan, dan tombol dev "Main lagi" dengan seed berikutnya. Struktur sesi dan game over tidak disentuh (ROADMAP 5, M2).
- **Uji HP Fase 2**: belum dilakukan pemilik; 3A jalan tanpa hasilnya. `DEV_PHASES` Fase 2 dan M1 **tetap tidak dicentang**.
- Sudah dikunci (ROADMAP 4b, tidak ditanyakan lagi): Godot 4.7.2, skala ×3, 640×360 `canvas_items` + integer + expand, ubin 64×32, arah lempar bebas, package `com.rmh.kring`.

## Di luar scope

- Perilaku rintangan (anjing, mobil garasi), tabrakan, skor, combo, pengali kecepatan, nada combo dan denting tip (Run 3B). Tempat rintangan **boleh ditandai di data** (`objek`), tapi tidak berperilaku dan tidak digambar sebagai rintangan hidup.
- Radar, HUD rute (progres pelanggan, koin), tenggat, layar hasil, rumah abu-abu di mode bantu, spike rumah sisi dekat (Run 3C).
- Save, `SaveManager`, hari, misi, headline, bel.
- Keputusan terbuka ROADMAP 5 yang **tidak boleh diputuskan diam-diam**: struktur sesi, game over, jendela bonus atau penalti (sakelar `Config.JENDELA_KENA_BONUS` tetap, bawaan penalti ringan), cara menampilkan rumah sisi dekat.
- Menggambar atau mengedit PNG sendiri (`art-assets.mdc`). Aset rumah, kotak surat, dan jalan dari PR #27 (`assets/sprites/houses/perumahan/`, `tools/env_art/fase3.py`) dan graybox yang ada dipakai apa adanya.

## Kriteria penerimaan (bisa diuji)

### Data dan pemuat

- **AC-1** Ada 9 berkas segmen `assets/data/routes/perumahan/per_*.json` dengan field DATA_SCHEMA 3 (`id`, `distrik`, `panjang`, `tag{tingkat, sisi_pelanggan, posisi}`, `rumah[]`, `objek[]`, `titik_misi[]`). Panjang 24 sampai 40 ubin; `id` huruf kecil dan garis bawah, unik dan sama dengan nama berkas; sisi hanya `seberang` atau `dekat`; jarak dalam ubin. Minimal 2 segmen `posisi: pembuka`, 2 `penutup`, dan sisanya `tengah`; segmen pembuka dan penutup `tingkat: tenang`; tiap segmen punya 2 ubin tepi kosong (tidak ada rumah, objek, atau titik misi dengan `pos` < 2 atau > `panjang` − 2).
- **AC-2** Pemuat murni di `scripts/systems/` (parse `Dictionary` menjadi objek bertipe, mengembalikan daftar galat dan **menolak** data tidak sah: field wajib hilang, id ganda, sisi `kiri`/`kanan`, panjang di luar 24–40, `pos` di luar segmen atau di tepi). Pembacaan berkas lewat satu fungsi terpisah; UI dan entitas tidak membaca JSON langsung (`gdscript.mdc`).
- **AC-3** Validasi data di tes headless memuat **semua** berkas nyata: field wajib, id unik, rujukan, dan aturan adil yang bisa diperiksa mesin: pelanggan hanya di sisi `seberang` (GDD 9.1); tidak ada rintangan di jalur `tengah` (jalur utama bersih); tidak ada rintangan di 2 ubin tepi; dalam jendela 6 ubin maksimal satu rintangan yang memaksa pindah jalur (ROUTE_DESIGN 4).
- **AC-4** `DATA_SCHEMA.md` bagian 3 diperbarui dengan contoh dari berkas nyata, daftar `jenis` rumah dan objek yang dikenal, dan format id rumah `<id_segmen>@<pos>`; tetap berlabel **usulan yang diterapkan di run 3A** (tidak ditulis "dikunci"). Bagian 5 dan `ROADMAP.md` 5 mencatat: segmen JSON (diputuskan), pemetaan ke id save tetap terbuka sampai Fase 6.

### RouteBuilder

- **AC-5** `RouteBuilder` murni di `scripts/systems/` (`class_name RouteBuilder`): `RandomNumberGenerator` diberi seed, tanpa `randi()` global, `Time`, atau scene tree. **Seed sama = rute sama** (urutan segmen dan pelanggan identik); **seed beda = rute beda** (dites atas 20 seed: tidak semua rute sama, dan paling sedikit 10 urutan segmen berbeda).
- **AC-6** Tiap rute: tepat 7 segmen berbeda (tanpa ulang dalam satu rute); segmen pertama `posisi: pembuka`, terakhir `penutup`, sisanya `tengah`; tidak ada dua segmen `padat` berurutan; panjang total terukur dan terdaftar (diharapkan sekitar 250 ubin, 200 sampai 300).
- **AC-7** Tiap rute: tepat **25 pelanggan** (`Config.RUTE_PELANGGAN`), semuanya rumah di sisi `seberang` dengan `pelanggan_boleh: true`, id rumah unik `<id_segmen>@<pos>`; jarak rata-rata antar pelanggan sekitar 9 ubin (BALANCING 6) dan tidak ada celah antar pelanggan berturut-turut lebih dari 20 ubin (dites, batas bisa dijelaskan di LOG bila disetel). Koran awal rute = pelanggan + 20% (dibulatkan ke atas, rumus ditulis di `BALANCING.md` 4 dan 6): 25 pelanggan → 30.
- **AC-8** Membangun satu rute (muat berkas + susun) selesai < 1 detik di mesin pengembang (TECH_PLAN 3.7; diukur di tes di luar `systems/`).

### Zona sasaran dan mode bantu dari data rute

- **AC-9** `ZonaSasaran` mendapat pembangun zona dari data rute (rumah → zona kotak surat, halaman, teras, jendela seberang; rumah `dekat` tanpa pelanggan → zona `BUKAN_PELANGGAN`), memakai geometri yang sama dengan zona jalan uji (konstanta `Config`, tanpa angka ajaib baru di kode). Penilaian tetap dari titik mendarat saja dan prioritas sama (kotak surat > jendela > teras > halaman). Tes dengan **oracle literal**: koordinat zona rumah di posisi `pos` tertentu ditulis eksplisit, bukan dihitung dengan fungsi yang dites.
- **AC-10** Scene rute memakai zona data rute untuk penilaian koran dan untuk `BantuLempar.pilih`; pelanggan di luar jangkauan lemparan tidak diproses (jendela zona sejauh jangkauan, bukan seluruh rute). Mode bantu tidak pernah memilih rumah bukan pelanggan atau rumah sisi `dekat`; bila tidak ada sasaran, perilaku D-6 run 2B (tanda kecil, koran dan jeda tetap) berlaku. Semua tes mode bantu, lemparan, dan bunyi tetap hijau, atau diperbarui dengan alasan tertulis di LOG.
- **AC-11** Tes scene: untuk beberapa posisi sepeda dan tiga kecepatan, jika `BantuLempar.pilih` mengembalikan pilihan, koran mendarat di zona kotak surat pelanggan itu dan dinilai `SAH_PENUH` lewat jalur penilaian yang sama dengan swipe (prediksi sama dengan hasil, prinsip run 2A).

### Scene rute

- **AC-12** `scenes/rute/rute.tscn` (root tipis, logika di `systems/`) menjadi `run/main_scene`. Rumah digambar dari data: sisi `seberang` dengan variasi pelanggan dan bukan pelanggan dari aset `house_perumahan_*`, kotak surat di rumah pelanggan, sisi `dekat` bukan pelanggan dengan aset `house_perumahan_dekat_*_bukan` (placeholder tanpa memutuskan cara tampil sisi dekat; spike di 3C). Hanya objek di sekitar kamera yang diinstansiasi (jendela daur, bukan seluruh rute sekaligus); urutan gambar Y-sort sama dengan jalan uji.
- **AC-13** Seed bawaan rute dev berasal dari konstanta `Config` dan deterministik; tombol dev "Main lagi" memakai seed berikutnya dan menyusun ulang rute. Koran awal rute dari data (30), tanpa isi ulang jalan uji (`SisaKoran.isi_ulang_jalan_uji` tidak dipakai di rute).
- **AC-14** Akhir rute (K-5): saat sepeda mencapai garis akhir (`panjang` rute), kecepatan ditekan ke 0 dengan laju rem yang sudah ada, stick dikunci, sinyal `rute_selesai` dipancarkan **tepat sekali**, banner sementara tampil lewat kunci terjemahan (`RUTE_SELESAI`), koran yang masih terbang tetap mendarat dan dinilai, jeda dan back tetap bekerja. Tidak ada layar hasil, tenggat, atau skor.
- **AC-15** Objek penutup semi-transparan: aturan **di satu tempat** (fungsi murni di `systems/` yang menentukan objek mana menutupi pemain dari kamera iso 2:1, ditambah satu simpul penerap di scene rute), bukan per objek rumah. Tes dengan oracle literal untuk objek yang menutupi, tidak menutupi, dan tepat di tepi (pola `tertutup_kotak` QA-004). Angka alfa masuk `Config`.
- **AC-16** Jeda, back Android, dan background bekerja di scene rute seperti di jalan uji (layar jeda, tanpa lanjut otomatis, `dt` 0 sesudah lanjut); koran terbang membeku selama jeda.

### Umum

- **AC-17** Semua angka baru ke `scripts/config.gd` satu baris literal per konstanta (`balancing.mdc`), `BALANCING.md` 6 diperbarui (angka rute, rumus koran awal). Semua teks pemain lewat `translations/ui.csv` dan `.translation` hasil impor ikut di-commit.
- **AC-18** Gerbang: `godot --headless --import` bersih; `run_tests.gd` + `tools/cek_keluaran_tes.py` (`--ketat` juga) lolos; `godot --headless --path . --quit-after 2` tanpa ERROR/WARNING pada scene utama baru; semua `uji_*.py` di `tools/tests_cek/` lolos; `godot --headless --path . --export-pack "Android" build/kring-uji.pck` memuat `assets/data/routes/perumahan/*.json` dan tidak memuat `tests/` atau `docs/` (`tests/tes_export.gd` diperbarui bila perlu).
- **AC-19** Dokumen diperbarui di commit yang sama dengan perubahannya: `DATA_SCHEMA.md` 3 dan 5, `BALANCING.md` 6, `AGENTS.md` (peta repo, perintah bila ada alat baru), `.cursor/rules/00-project-core.mdc` (perintah), `docs/README.md` (baris status), `ROADMAP.md` 5. `DEV_PHASES.md` **tidak dicentang oleh Dev** (orchestrator mencentang butir yang terbukti sesudah PR dibuka).

## Perubahan file/struktur yang diharapkan

Nama kelas boleh disesuaikan Dev asal tercatat di LOG.

| Jalur | Isi |
|---|---|
| `assets/data/routes/perumahan/per_*.json` | 9 segmen |
| `scripts/systems/segmen_rute.gd`, `pemuat_rute.gd`, `route_builder.gd`, `penutup_pemain.gd` | Data bertipe dan validasi, pembacaan berkas, penyusun rute berseed, aturan penutup |
| `scripts/systems/zona_sasaran.gd` | Pembangun zona dari data rute |
| `scripts/entities/rute_main.gd`, `rumah_rute.gd` (atau serupa) | Scene rute, jendela daur rumah dari data |
| `scenes/rute/rute.tscn` | Scene utama |
| `project.godot` | `run/main_scene` |
| `scripts/config.gd`, `translations/ui.csv` (+ `.translation`) | Angka dan teks baru |
| `tests/tes_rute.gd`, `tests/tes_rute_scene.gd`, `tests/run_tests.gd` | Tes baru |
| `docs/*` | Daftar di AC-19 |

## Tes yang harus ada

Tes headless dengan **mutan nyata** dan **oracle independen** (pelajaran QA-008 run 2A dan QA-001 run 2B: harapan ditulis eksplisit sebagai literal, bukan memanggil fungsi yang dites):

- Pemuat: berkas nyata lolos, setiap jenis data rusak ditolak (AC-2, AC-3).
- `RouteBuilder`: seed sama/beda, 7 segmen, urutan posisi, tanpa ulang, tanpa dua `padat` berurutan, 25 pelanggan seberang, id unik, koran awal 30 (AC-5 sampai AC-7); 20 rute acak berseed dibangun tanpa galat (ROUTE_DESIGN 7).
- Zona dari data rute dan penilaian titik mendarat (AC-9); mode bantu di scene rute (AC-10, AC-11).
- Akhir rute: `rute_selesai` tepat sekali, input terkunci, koran terbang tetap dinilai (AC-14).
- Penutup semi-transparan (AC-15).
- Invarian prinsip desain yang relevan: jalur utama bersih, pelanggan hanya `seberang` (distrik pertama).
- Tes lama (6445 assertion di run 2B) tetap lolos; tes yang diubah dicatat beserta alasannya.

## Butuh uji perangkat nyata (NEEDS-MANUAL)

Di HP (vivo V2108; A54 bila tersambung), dinilai pemilik, bukan QA:

- Rute berjalan dari awal sampai garis akhir tanpa patah atau lonjakan (60 fps, memuat < 1 detik), 25 pelanggan terasa dan tidak terlihat dihafal setelah tiga seed.
- Mengenai kotak surat dengan sengaja di tiga kecepatan, mode bantu mengenai kotak surat pelanggan terdekat.
- Objek penutup semi-transparan terbaca (rumah tidak menyembunyikan sepeda), tampilan rumah dan kotak surat tajam di ×3.
- Banner "Rute selesai" dan tombol "Main lagi" terbaca dan tidak tersentuh tak sengaja.

## Dokumen yang ikut diperbarui (README docs, ROADMAP 5, DEV_PHASES)

Lihat AC-19. `DEV_PHASES.md` Fase 3 dicentang oleh orchestrator hanya untuk butir yang terbukti: format segmen dan pemuat, rute dari urutan acak berseed, rumah pelanggan dan bukan pelanggan (seberang saja), pemuatan zona dari data rute (bagian butir mode bantu), dan objek semi-transparan. Butir rintangan, tabrakan, skor, nada combo, radar, HUD, tenggat, dan hasil tetap kosong; butir mode bantu "rumah abu-abu" tetap kosong.
