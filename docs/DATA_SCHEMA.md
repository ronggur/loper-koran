# Skema Data — Loper Koran

Format file data yang dibaca game: misi, headline, segmen rute, save, dan upgrade bengkel. Kolom misi di bagian 1 berasal dari dokumen ide (GDD 10). Bentuk JSON, nama field, dan bagian 1, 2, dan 4 adalah **usulan** yang diterapkan di run `20261018-fase4a-koran-hari` (dibaca `DataMisi`/`PemuatMisi`, `DataHeadline`/`PemuatHeadline`, dan `DataSave`/`SaveManager`), belum dikunci sampai diuji di HP. **Alur hari berurutan yang memakai format ini adalah prototype yang tidak mengunci struktur sesi** (ROADMAP 5: hari terakhir, game over, dan target harian tetap terbuka).

Aturan umum:

- Semua data konten berada di `assets/data/` sebagai JSON, satu file per kelompok (per distrik atau per jenis). Angka global tidak ditaruh di sini, tetapi di `scripts/config.gd` (`BALANCING.md` bagian 1).
- `id` memakai huruf kecil dan garis bawah, unik di seluruh game, dan **tidak pernah diganti** setelah dipakai di save.
- Sisi selalu ditulis `seberang` atau `dekat` (GDD 4.2), tidak pernah `kiri`/`kanan`.
- Jarak dalam ubin, batas misi dalam rumah (GDD 10.3), waktu dalam detik.
- Tes logika (`tests/run_tests.gd`) memuat semua file data dan memeriksa field wajib, id unik, rujukan id yang ada, dan panjang teks (`CONTENT_GUIDE.md` bagian 2–3).
- **Teks pemain di data adalah kunci terjemahan** (run 4A, S-2): `headline`, `ringkasan`, `hud`, `teks`, dan `petunjuk.dari_pelanggan` berisi kunci `UPPER_SNAKE_CASE` (awalan `KORAN_` untuk headline, `MISI_` untuk misi) yang teksnya ada di `translations/konten.csv`, bukan kalimat jadi (rule `content-data`). Batas panjang (40, 60, 14, 50) dan gaya diperiksa terhadap teks hasil terjemahan. Ini menyimpang dari contoh `teks` literal di versi lama dokumen ini.

---

## 1. Misi

File: `assets/data/missions/<distrik>.json`, berisi array misi.

| Kolom | Isi | Contoh |
|---|---|---|
| `id` | Kode unik | `p1_kucing` |
| `template` | Salah satu dari enam template (GDD 10.4): `cari`, `antar_khusus`, `lempar_khusus`, `kumpul`, `kejar`, `jaga` | `cari` |
| `headline` | Kunci terjemahan judul di koran; teksnya maksimal 40 karakter | `MISI_P1_KUCING_HEADLINE` ("Kucing Bu Ratmi Hilang Sejak Semalam") |
| `ringkasan` | Kunci terjemahan satu baris di bawah headline, teksnya maksimal 60 karakter (usulan) | `MISI_P1_KUCING_RINGKASAN` |
| `hud` | Kunci terjemahan label di HUD, teksnya maksimal 14 karakter (usulan) | `MISI_P1_KUCING_HUD` |
| `distrik` | Distrik yang boleh memunculkannya | `perumahan` |
| `rep_min` | Reputasi minimum distrik | `0` |
| `syarat` | Objek dengan kunci boleh `flag` (id), `hari_min`, `hari_maks` (hari >= 1), dan `berita_utama` (kunci efek GDD 10.7; hanya di misi); kosong = tanpa syarat | `{"berita_utama": "air_pasang"}` |
| `target` | Objek, rumah, atau sosok yang muncul, lengkap dengan sisinya | `{"objek": "kucing", "jumlah": 3, "sisi": "seberang"}` |
| `langkah` | Urutan kondisi sampai selesai | petunjuk 1, petunjuk 2, tangkap |
| `petunjuk` | Penanda visual dan suara; `dari_pelanggan` (kunci terjemahan, teks maksimal 50 karakter) | `{"visual": ["kilau", "ekor"], "suara": "meong", "dari_pelanggan": "MISI_P1_KUCING_PETUNJUK"}` |
| `batas` | Jumlah rumah atau bagian rute | `{"rumah": 12}` |
| `hadiah` | Tingkat hadiah dan tambahan (GDD 10.5) | `{"tingkat": "sedang", "tambahan": "pelanggan_setia"}` |
| `gagal` | Efek langsung saat gagal | `{"reputasi": 0}` |
| `flag_lanjut` | Flag yang ditulis saat selesai dan saat gagal, dibaca headline besok (flag dikonsumsi sesudah lanjutannya tampil, bagian 4) | `{"selesai": "kucing_ketemu", "gagal": "kucing_belum"}` |
| `banner` | Kunci terjemahan banner di rute (run 4B): `selesai` dan `gagal`, masing-masing teks hasil terjemahan paling banyak 24 karakter (CONTENT_GUIDE 3; gagal tidak menyalahkan). Wajib untuk semua template | `{"selesai": "MISI_P1_KUCING_SELESAI", "gagal": "MISI_P1_KUCING_GAGAL"}` |
| `jeda` | Hari sebelum boleh muncul lagi, dihitung dari hari misi DIAMBIL (S-4); misi yang dilewati tidak memicu jeda | `7` |
| `aktif` | Opsional, bawaan `true`. Menonaktifkan misi = `false`, id tidak pernah dihapus atau dipakai ulang | `true` |
| `lanjutan_dari` | Opsional: id misi asal bila ini misi lanjutan; misi lanjutan tidak ikut undian biasa, hanya lewat headline lanjutan | `p1_kucing` |

**Validasi** (`DataMisi.parse`, `PemuatMisi`; dijalankan tes pada berkas nyata, dan satu data buruk per aturan Cari oleh `tests/tes_misi.gd`): field wajib ada dan bertipe benar, field tidak dikenal ditolak, `id` huruf kecil, angka, dan garis bawah (dimulai huruf) dan unik, `template` salah satu dari enam, `distrik` dikenal, `rep_min` dan `jeda` tidak negatif, `hadiah.tingkat` kecil/sedang/besar, `flag_lanjut.selesai` dan `.gagal` berupa id, kunci terjemahan harus ada, dan teks hasil terjemahan <= 40 (headline, juga Huruf Kapital di Awal Kata), 60, 14, 50 karakter. `banner.selesai` dan `banner.gagal` kunci yang ada dengan teks <= 24 karakter. `target`, `langkah`, `petunjuk`, `batas` diperiksa tipenya untuk semua template; **template `cari` diperiksa penuh (run 4B)**, lihat "Template Cari" di bawah.

Contoh lengkap dari berkas nyata (`assets/data/missions/perumahan.json`, P1 dari GDD 10.6):

```json
[
  {
    "id": "p1_kucing",
    "aktif": true,
    "template": "cari",
    "headline": "MISI_P1_KUCING_HEADLINE",
    "ringkasan": "MISI_P1_KUCING_RINGKASAN",
    "hud": "MISI_P1_KUCING_HUD",
    "distrik": "perumahan",
    "rep_min": 0,
    "syarat": {},
    "target": { "objek": "kucing", "jumlah": 1, "sisi": "seberang" },
    "langkah": [
      { "jenis": "lihat", "titik": "atap", "rumah_dari_mulai": [3, 4] },
      { "jenis": "lihat", "titik": "bawah_mobil_tamu", "rumah_dari_sebelumnya": [3, 4] },
      { "jenis": "tangkap", "titik": "balik_pot", "rumah_dari_sebelumnya": [3, 4], "radius_ubin": 2.0, "lama_berhenti_detik": 1.5 }
    ],
    "petunjuk": {
      "visual": ["kilau", "ekor"],
      "suara": "meong",
      "dari_pelanggan": "MISI_P1_KUCING_PETUNJUK"
    },
    "batas": { "rumah": 12 },
    "hadiah": { "tingkat": "sedang", "tambahan": "pelanggan_setia", "tokoh": "bu_ratmi" },
    "gagal": { "reputasi": 0 },
    "flag_lanjut": { "selesai": "kucing_ketemu", "gagal": "kucing_belum" },
    "banner": { "selesai": "MISI_P1_KUCING_SELESAI", "gagal": "MISI_P1_KUCING_GAGAL" },
    "jeda": 7
  }
]
```

Misi lanjutan memakai field yang sama dengan `lanjutan_dari` (id misi asal) dan `syarat` berisi flag, misalnya `{"flag": "kucing_belum"}`. Batasnya lebih longgar (GDD 10.7). Misi lanjutan P1 belum ada di data (4B); headline lanjutannya memakai `misi_ditunda` (bagian 2).

`langkah` berbeda per template. Field yang dipakai tiap template ditulis di sini setelah template itu dibuat (Cari di Fase 4, Antar khusus dan Kejar untuk P2–P3 di Fase 7, sisanya di Fase 8).

**Template Cari (run 4B, usulan; GDD 10.2 sampai 10.6, M-1 sampai M-5; `DataMisi._periksa_cari`, rencana di `RencanaMisi`, perilaku di `MissionManager`):**

- `target`: `objek` salah satu dari `kucing`, `jumlah` bilangan bulat >= 1, `sisi` `seberang` atau `dekat`. Jumlah langkah `tangkap` harus sama dengan `jumlah`.
- `target.sisi`: hanya `seberang` yang didukung `RencanaMisi`; `dekat` ditolak validasi sampai didukung (QA-006, run 4B iterasi 2).
- `langkah`: daftar >= 2 langkah. Tiap langkah punya `jenis` (`lihat` atau `tangkap`) dan `titik` (`atap`, `bawah_mobil_tamu`, `balik_pot`; placeholder tampilan sama semua, M-10). Langkah pertama memakai `rumah_dari_mulai`, sisanya `rumah_dari_sebelumnya`, berupa rentang `[min, maks]` bilangan bulat dengan 1 <= min <= maks (jumlah rumah seberang dari rumah pertama rute atau dari titik sebelumnya). Langkah terakhir `tangkap`; langkah `tangkap` wajib punya `radius_ubin` > 0 dan `lama_berhenti_detik` > 0 (field itu ditolak di langkah `lihat`). Jumlah semua `maks` tidak boleh melebihi `batas.rumah`, jadi batas 12 rumah terpenuhi secara konstruksi.
- `petunjuk`: `visual` (daftar tidak kosong dari `kilau`, `ekor`), `suara` (`meong`), `dari_pelanggan` (kunci terjemahan, teks <= 50 karakter). `batas`: hanya `rumah` (>= 1). `hadiah`: `tingkat` (`kecil` 45, `sedang` 75, `besar` 120 koin; `Config.MISI_HADIAH_KOIN`) dan boleh `tambahan`, `tokoh` (teks; tidak berefek di 4B, K-2).
- "Rumah" = rumah sisi seberang (pelanggan atau bukan), urut maju. Rencana kucing dari benih hari: `SeedHari.misi(hari)` = seed rute + `SEED_MISI_SELISIH`.

---

## 2. Headline

File: `assets/data/headlines/<jenis>.json` dengan jenis `utama`, `ringan`, dan `lanjutan` (nama berkas = jenis), tiap berkas berisi array. Headline misi tidak ditulis di sini, karena sudah ada di data misi.

| Field | Isi | Contoh |
|---|---|---|
| `id` | Kode unik di seluruh headline DAN misi | `utama_hajatan` |
| `jenis` | `utama`, `ringan`, `lanjutan`; sama dengan jenis berkas | `utama` |
| `teks` | Kunci terjemahan; teksnya maksimal 40 karakter, Huruf Kapital di Awal Kata (kata penghubung `di`, `ke`, `dari`, `dan`, `yang`, `untuk`, `pada` boleh huruf kecil), tanpa titik di akhir, tanpa tanda seru beruntun (`CONTENT_GUIDE.md` 2) | `KORAN_UTAMA_HAJATAN` |
| `distrik` | Daftar distrik, kosong berarti semua | `["perumahan", "perkampungan"]` |
| `efek` | Hanya berita utama, wajib: kunci efek dunia (GDD 10.7, delapan nilai) | `hajatan` |
| `syarat` | Objek: `flag`, `hari_min`, `hari_maks` | `{"flag": "kucing_belum"}` |
| `bobot` | Peluang relatif terpilih, bilangan bulat >= 1 | `2` |
| `jeda` | Hari sebelum boleh muncul lagi, dihitung dari hari headline DITAMPILKAN (S-4) | `4` |
| `aktif` | Opsional, bawaan `true`; menonaktifkan tanpa menghapus | `false` |
| `slot` | Hanya `lanjutan`, wajib: `misi` atau `ringan` (baris halaman yang ditempati) | `misi` |
| `misi` | Hanya `lanjutan` slot `misi`: id misi lanjutan yang ada di data misi | `p1_kucing_lanjut` |
| `misi_ditunda` | Hanya `lanjutan` slot `misi`: `true` bila misi lanjutannya belum dibuat (4B); headline tetap tampil di baris misi tanpa tombol Ambil/Lewati. Slot `misi` wajib punya tepat satu dari `misi` atau `misi_ditunda` | `true` |

Kunci `efek` dan artinya didefinisikan di kode (satu `match` per efek, Fase 7), bukan di data, supaya efek dunia tetap diuji. **Di 4A efek hanya dicatat** dan tidak diterapkan (S-5): berita utama "Hujan" tidak membuat hujan turun.

**Validasi** (`DataHeadline.parse`, `PemuatHeadline`, `PemuatHeadline.periksa_silang`): field wajib dan tipe, field tidak dikenal ditolak (mis. `efek` di berita ringan), `jenis` = jenis berkas, `efek` salah satu dari delapan kunci, `bobot` >= 1, `jeda` >= 0, `distrik` dikenal, lanjutan wajib `syarat.flag` dan `slot`, kunci terjemahan harus ada dan teksnya lolos panjang dan gaya. Antar berkas: id unik di seluruh headline dan misi, setiap `syarat.flag` ditulis sedikitnya satu misi lewat `flag_lanjut` (rujukan flag tidak yatim), dan `misi` headline lanjutan menunjuk misi yang ada.

**Pemilihan halaman** (`HeadlineManager`, seed per hari dari `SeedHari`): satu berita utama, satu baris misi, satu berita ringan. Kandidat harus aktif, cocok distrik, memenuhi syarat, dan tidak dalam jeda (`headline_jeda` / `misi_jeda` di save menyimpan hari pertama boleh muncul lagi). Headline lanjutan yang flag-nya aktif menempati slotnya sebelum undian biasa. Bila semua kandidat headline dalam jeda, dipilih yang jedanya paling cepat berakhir. Hari 1 slot misi selalu `p1_kucing` (tutorial). Tanpa misi yang memenuhi syarat, baris misi kosong (keadaan sah).

Contoh dari berkas nyata (`assets/data/headlines/utama.json`, `lanjutan.json`):

```json
{"id": "utama_hajatan", "jenis": "utama", "aktif": true, "teks": "KORAN_UTAMA_HAJATAN", "distrik": ["perumahan", "perkampungan"], "efek": "hajatan", "syarat": {}, "bobot": 2, "jeda": 4}
{"id": "lanjutan_kucing_belum", "jenis": "lanjutan", "aktif": true, "teks": "KORAN_LANJUT_KUCING_BELUM", "distrik": ["perumahan"], "syarat": {"flag": "kucing_belum"}, "slot": "misi", "misi_ditunda": true, "bobot": 1, "jeda": 30}
```

Catatan 4A: flag belum pernah ditulis oleh permainan (hasil misi ada di 4B), jadi headline lanjutan belum muncul di permainan. Flag juga belum dihapus sesudah headline lanjutannya tampil; `jeda` 30 mencegah headline lanjutan muncul tiap hari selama flag tetap ada, dan aturan konsumsi flag diputuskan di 4B.

---

## 3. Segmen rute

File: `assets/data/routes/<distrik>/<id>.json`, satu file per segmen, **JSON buatan tangan** (keputusan pemilik 2026-10-16, K-1 run `20261016-fase3a-rute`; bukan scene Godot yang diekspor). Aturan menyusun segmen ada di `ROUTE_DESIGN.md`. Bentuk di bawah adalah **usulan yang diterapkan di run 3A** (dibaca `SegmenRute`, `PemuatRute`, `RouteBuilder`), belum dikunci: nilai `jenis`, parameter objek, dan aturan validasi masih bisa berubah setelah uji HP.

| Field | Isi |
|---|---|
| `id` | Kode unik huruf kecil dan garis bawah, **sama dengan nama berkas** (`per_tengah_02` di `per_tengah_02.json`) |
| `distrik` | Distrik segmen (`perumahan`) |
| `panjang` | Panjang dalam ubin, bilangan bulat 24 sampai 40 |
| `tag` | `tingkat` (`tenang`/`sedang`/`padat`), `sisi_pelanggan` (`seberang`/`dekat`/`dua_sisi`), `posisi` (`pembuka`/`tengah`/`penutup`). Pembuka dan penutup selalu `tenang` |
| `rumah` | Daftar petak rumah: `pos` (ubin dari awal segmen, bilangan bulat), `sisi` (`seberang`/`dekat`), `jenis` (bentuk rumah, daftar di bawah), `pelanggan_boleh` (true/false) |
| `objek` | Rintangan yang ditandai: `jenis`, `pos`, `jalur` (`seberang`/`dekat`; **tidak pernah `tengah`**), `tanda_ubin` (jarak tanda terlihat sebelum rintangan, paling sedikit 9) |
| `titik_misi` | Tempat yang boleh dipakai misi: `nama` (mis. `atap`, `balik_pot`), `pos`, `sisi`; harus berdiri di rumah (pos dan sisi sama dengan sebuah rumah) |

Contoh dari berkas nyata (`assets/data/routes/perumahan/per_tengah_02.json`):

```json
{
  "id": "per_tengah_02",
  "distrik": "perumahan",
  "panjang": 32,
  "tag": { "tingkat": "sedang", "sisi_pelanggan": "seberang", "posisi": "tengah" },
  "rumah": [
    { "pos": 2, "sisi": "seberang", "jenis": "pelana", "pelanggan_boleh": false },
    { "pos": 4, "sisi": "dekat", "jenis": "dekat_limasan", "pelanggan_boleh": false },
    { "pos": 6, "sisi": "seberang", "jenis": "limasan", "pelanggan_boleh": true },
    { "pos": 10, "sisi": "seberang", "jenis": "sayap", "pelanggan_boleh": true },
    { "pos": 12, "sisi": "dekat", "jenis": "dekat_pelana_sejajar", "pelanggan_boleh": false },
    { "pos": 14, "sisi": "seberang", "jenis": "limasan", "pelanggan_boleh": false },
    { "pos": 18, "sisi": "seberang", "jenis": "pelana", "pelanggan_boleh": true },
    { "pos": 20, "sisi": "dekat", "jenis": "dekat_pelana_lintang", "pelanggan_boleh": false },
    { "pos": 22, "sisi": "seberang", "jenis": "sayap", "pelanggan_boleh": true },
    { "pos": 26, "sisi": "seberang", "jenis": "pelana", "pelanggan_boleh": true },
    { "pos": 28, "sisi": "dekat", "jenis": "dekat_limasan", "pelanggan_boleh": false },
    { "pos": 30, "sisi": "seberang", "jenis": "limasan", "pelanggan_boleh": false }
  ],
  "objek": [
    { "jenis": "anjing_penjaga", "pos": 14, "jalur": "dekat", "tanda_ubin": 9 },
    { "jenis": "mobil_garasi", "pos": 25, "jalur": "seberang", "tanda_ubin": 9 }
  ],
  "titik_misi": [
    { "nama": "atap", "pos": 6, "sisi": "seberang" }
  ]
}
```

**Jenis yang dikenal** (jenis lain ditolak pemuat):

| Bidang | Nilai | Aset |
|---|---|---|
| `rumah.jenis` sisi `seberang` | `limasan`, `pelana`, `sayap` | `assets/sprites/houses/perumahan/house_perumahan_<jenis>_<pelanggan\|bukan>.png` |
| `rumah.jenis` sisi `dekat` | `dekat_limasan`, `dekat_pelana_lintang`, `dekat_pelana_sejajar` | `house_perumahan_<jenis>_<pelanggan\|bukan>.png` (di distrik perumahan hanya varian `bukan` dipakai; tampilan sisi dekat diputuskan 2026-10-17: tembok/pagar belakang rendah, ROADMAP 4b; field data untuk tembok belum ada) |
| `objek.jenis` | `anjing_penjaga`, `mobil_garasi` | `assets/sprites/obstacles/obs_anjing_sheet`, `obs_mobil_garasi_sheet` (perilaku di Run 3B; di 3A hanya tempatnya yang ditandai) |

**Id rumah** di rute = `<id_segmen>@<pos>` (mis. `per_tengah_02@18`). Satu `pos` hanya boleh dipakai satu rumah per segmen (kedua sisi), supaya id unik tanpa sisi. Ini id sementara untuk rute dan penilaian zona; pemetaan ke id rumah tetap di save (`per_r014`, bagian 4) ditunda ke Fase 6 (bagian 5).

**Geometri.** `pos` adalah awal kavling: zona kotak surat, halaman, teras, dan jendela dihitung relatif terhadap `pos` dengan angka `Config.JALAN_UJI_*` yang sama dengan jalan uji (BALANCING 5), jadi rumah di `pos` p memakai kotak surat sebagai area di halaman, maju p + 1,25 sampai p + 2,5 (seberang 1,0 × 1,25 di lateral −2,75 sampai −1,75, dekat 0,75 × 1,25 di lateral 1,75 sampai 2,5; pusat maju p + 1,875; sebagian halaman tertimpa, kotak surat menang; teras dan jendela tidak tertimpa). Rumah sesisi berjarak paling sedikit satu petak (4 ubin). Dua ubin di tiap ujung segmen kosong (tidak ada rumah, objek, atau titik misi dengan `pos` kurang dari 2 atau lebih dari `panjang` - 2); rintangan paling dekat 3 ubin ke tepi supaya dua segmen yang disambung tidak menumpuk keputusan.

**Rumah mana yang jadi pelanggan** ditentukan saat rute disusun (seed rute, `RouteBuilder`), bukan di segmen. Segmen hanya menyatakan rumah mana yang **boleh** jadi pelanggan. Distrik pertama: `pelanggan_boleh: true` hanya di sisi `seberang` (GDD 9.1).

**Validasi** (`SegmenRute.parse`, `PemuatRute.periksa_kumpulan`; dijalankan tes pada semua berkas nyata): field wajib ada dan bertipe benar, field tidak dikenal ditolak, sisi hanya `seberang` atau `dekat`, id unik dan sama dengan nama berkas, panjang 24 sampai 40, tepi 2 ubin kosong, pelanggan hanya di seberang, rintangan tidak di jalur `tengah` (jalur utama bersih), tanda rintangan paling sedikit 9 ubin (1,5 detik pada ngebut), dalam jendela 6 ubin maksimal satu rintangan, rintangan tidak memotong tapak rumah mana pun di segmen (mobil garasi seluruh lintasannya, jadi parkir di celah samping rumah: `pos` rumah sesisi − 1; anjing di posisi diamnya; tepi bersentuhan boleh; ROUTE_DESIGN 4 aturan 7, usulan), titik misi di rumah dan di luar jendela rintangan, sekurangnya 2 segmen `pembuka`, 2 `penutup`, dan 5 `tengah` per distrik (satu rute memakai 7 segmen).

## 4. Save

File: `user://save.json`. Satu slot dulu. Format v3 (run 6A1: `koin` menjadi saldo, `koin_total`, `sepeda`; v2 dari run 4B dan v1 dari run 4A dimigrasi, tidak dihapus) di bawah dibaca dan ditulis `SaveManager` (autoload) lewat `DataSave`; **alur hari berurutan yang memakai save ini adalah prototype yang tidak mengunci struktur sesi** (ROADMAP 5: hari terakhir, kalender 120 hari, game over, target harian belum diputuskan). Field DATA_SCHEMA lain yang belum dipakai (`distrik_terbuka`, `reputasi`, `pelanggan`, `kosmetik`, `milestone`) belum ditulis; bila ada di berkas (save masa depan) dibiarkan.

Contoh save nyata setelah hari 1 selesai (isi dari tes alur hari `tests/tes_alur_hari.gd`: P1 diambil dan selesai, 3 dari 25 terantar, koin 195 = rute 120 termasuk tip 25 + hadiah misi 75, skor 1500; flag `kucing_ketemu` menunggu tampil besok; tanpa belanja bengkel dan tanpa kerusakan, jadi `sepeda` masih baru):

```json
{
	"flag": [
		"kucing_ketemu"
	],
	"hari": 2,
	"headline_jeda": {
		"ringan_mangga": 4,
		"utama_jalan_diperbaiki": 5
	},
	"koin": 195,
	"koin_total": 195,
	"misi_hasil": {
		"p1_kucing": {
			"hari": 1,
			"hasil": "selesai"
		}
	},
	"misi_jeda": {
		"p1_kucing": 8
	},
	"pengaturan": {
		"kidal": false,
		"mode_bantu": false,
		"musik": 1.0,
		"suara": 1.0
	},
	"sepeda": {
		"ban": {
			"kondisi": 1.0,
			"level": 0
		},
		"rantai": {
			"kondisi": 1.0,
			"level": 0
		},
		"rem": {
			"kondisi": 1.0,
			"level": 0
		},
		"servis_total": 0
	},
	"terakhir": {
		"hari": 1,
		"koin": 195,
		"koin_misi": 75,
		"meleset": 22,
		"misi_diambil": "p1_kucing",
		"misi_hasil": "selesai",
		"skor": 1500,
		"terkirim": 3,
		"tip": 25
	},
	"tip_total": 25,
	"tutorial": {
		"selesai": true
	},
	"versi": 3
}
```

(Kunci diurutkan abjad oleh `DataSave.ke_teks`, jadi isi sama = teks sama byte demi byte.)

| Field | Arti |
|---|---|
| `versi` | Naik setiap format berubah (`Config.SAVE_VERSI`); game memigrasi save lama lewat `if versi < N: ...; versi = N`, tidak menghapusnya. Save tanpa `versi` dianggap v0 dan digabung dengan templat |
| `hari` | Hari yang AKAN dimainkan berikutnya, mulai 1 (S-3); naik 1 saat "Hari berikutnya" |
| `koin` | **Saldo** koin (v3, K-1 run 6A1): bertambah sebesar koin hari itu (sudah termasuk tip dan hadiah misi) dan berkurang HANYA oleh belanja bengkel yang disengaja (servis, upgrade); tidak pernah berkurang oleh hukuman dan tidak pernah negatif |
| `koin_total` | Koin yang pernah didapat seumur hidup (v3): bertambah sebesar koin hari itu, tidak pernah berkurang (belanja tidak mengubahnya), tidak pernah di bawah saldo `koin`. Untuk milestone nanti. Awal (migrasi) = `koin` v2 |
| `tip_total` | Total koin dari tip (bagian dari `koin_total`; belanja tidak mengubahnya) |
| `sepeda` | Kondisi dan upgrade sepeda (v3, M-7): `ban`, `rem`, `rantai`, masing-masing `{"kondisi": 0.0 sampai 1.0, "level": n}`, ditambah `servis_total` (jumlah servis seumur hidup, bukti "servis pertama" untuk syarat distrik Ruko, TECH_PLAN 6A). `kondisi` 1.0 = baru, dibulatkan 4 desimal (teks save stabil byte demi byte), nilai di luar 0 sampai 1 atau bukan angka dijepit (bukan save rusak); `level` = tingkat upgrade yang dimiliki (0 = belum; jumlah upgrade dibaca dari sini); `level` dan `servis_total` hanya naik. Id komponen asing dibiarkan; `sepeda` atau komponen bukan objek, atau `servis_total` bukan angka = save rusak. `setang` dan `lampu` dicadangkan sebagai id (belum dipakai, tidak ditulis). `statistik_aus` tidak dibuat (tidak ada konsumen di 6A1) |
| `flag` | Daftar flag "lanjutan menunggu tampil" (id). **Arti berubah di v2 (M-6):** bukan riwayat. Hasil misi menulis flag (`flag_lanjut`) di akhir hari; headline lanjutan yang `syarat.flag`-nya flag itu tampil besok tepat sekali, lalu flag dikonsumsi (dihapus) di akhir hari tampilnya. Urutan di `catat_hari`: konsumsi dulu, tambah flag baru sesudahnya (flag baru hari ini tidak ikut terhapus). Id yang tidak ada di data dibiarkan |
| `misi_hasil` | Riwayat permanen hasil misi (M-7): id misi -> `{"hasil": "selesai" atau "gagal", "hari": n}`. `selesai` tidak pernah ditimpa `gagal` dan hari selesainya tidak bergeser; `gagal` boleh diganti `selesai` atau `gagal` yang lebih baru. Id yang tidak ada di data dibiarkan |
| `tutorial` | `{"selesai": bool}`: tutorial terpandu hari 1 selesai atau dilewati (M-9), ditulis di akhir hari dan tidak pernah kembali false |
| `misi_jeda` | Id misi -> hari pertama boleh muncul lagi (hari diambil + `jeda`). Hanya untuk misi yang DIAMBIL (S-4); misi yang dilewati tidak memicu jeda. Ini bukan penalti: koin, hari, `tip_total`, dan flag sama untuk Ambil dan Lewati, hanya baris misi hari-hari berikutnya yang kosong sementara (diputuskan orchestrator 2026-10-17, bisa ditolak di review PR) |
| `headline_jeda` | Id headline -> hari pertama boleh muncul lagi (hari tampil + `jeda`) |
| `terakhir` | Hasil hari terakhir dari `HasilRute.Angka` yang sama dengan layar hasil: `hari`, `terkirim`, `meleset`, `koin`, `tip` (bagian tip), `skor`, `misi_diambil` ("" bila dilewati), `misi_hasil` ("", `selesai`, `gagal`), `koin_misi` (hadiah yang dibayar, hanya `selesai`; sudah termasuk di `koin`) |
| `pengaturan` | `kidal`, `mode_bantu` (sakelar layar jeda, disimpan di akhir hari dan dibaca sebelum layar koran), `suara`, `musik` (0 sampai 1, bawaan 1.0, belum dipakai) |

Aturan:

- Save ditulis di akhir hari (tombol "Hari berikutnya" di bengkel, v3; sebelumnya di layar hasil), tepat satu kali per hari, bukan di tengah rute. Selama layar hasil dan bengkel, saldo, kondisi, dan belanja ada di memori; menutup app di sana mengulang hari dari koran dengan save lama (juga pendapatan hari itu dan belanja). Tutup app di tengah rute: save terakhir utuh, hari yang sama dimulai lagi dari layar koran dengan headline dan seed rute yang sama.
- Penulisan atomik: ke `user://save.tmp`, diperiksa terbaca, lalu rename. Save rusak (bukan JSON, bukan objek, field kunci bertipe salah) atau `versi` lebih baru tidak ditimpa diam-diam: disalin dulu ke `user://save.corrupt.<detik unix>.json` (isi yang sama dengan salinan yang sudah ada tidak disalin lagi, jadi peluncuran berulang tidak menumpuk salinan), permainan mulai dari state bawaan, dan layar koran memberi tahu satu baris (`KORAN_SAVE_RUSAK`). Berkas yang ADA tetapi tidak bisa dibuka (izin, galat I/O), atau berkas rusak yang salinannya gagal dibuat, TIDAK PERNAH ditimpa: `simpan` ditahan sepanjang sesi (mengembalikan false, berkas lama utuh), permainan tetap jalan dari state bawaan di memori, dan layar koran memberi tahu satu baris jujur (`KORAN_SAVE_TIDAK_TERBACA`, tanpa mengaku menyimpan salinan). Simpan akhir hari yang gagal dicoba sekali lagi; bila tetap gagal alur tidak diblokir dan koran berikutnya menampilkan satu baris netral (`KORAN_SAVE_GAGAL`) sampai satu simpan berhasil (kemajuan menumpuk di memori, jadi simpan berikutnya menuliskan semuanya). Nilai tidak sah di dalam blok (negatif, tipe salah) dijepit atau diganti bawaan.
- Progres tidak turun: `hari`, `koin_total`, `tip_total`, `servis_total`, dan `level` upgrade hanya naik, jeda tidak mundur; `koin` (saldo) turun hanya karena belanja bengkel; hari dengan koin 0 atau misi gagal tidak mengurangi apa pun (prinsip 2). (Invarian "flag hanya bertambah" run 4A diganti aturan konsumsi flag di v2.) Hadiah misi = `Config.MISI_HADIAH_KOIN` menurut `hadiah.tingkat` (75 untuk `sedang`, K-1), dibayar saat misi selesai dan dihitung sekali di `HasilRute.Angka`, bukan di UI.
- Id pelanggan memakai rumah tetap di distrik (`per_r014`), supaya pelanggan yang sama tetap ada walau segmen diacak. Cara memetakan rumah tetap ke segmen yang diacak ditunda ke Fase 6 (bagian 5); di Fase 3 dan 4A rumah hanya punya id rute `<id_segmen>@<pos>` (bagian 3) dan tidak ada yang ditulis ke save.
- `kosmetik.baju` (nanti) memakai nama varian baju dari `ART_DIRECTION.md` 3.3.
- Misi aktif tidak disimpan: hidup hanya selama rute; app ditutup di tengah rute = hari yang sama diulang dari koran dan misi dari awal (konsisten dengan 4A). Misi lintas hari tidak dikerjakan di 4B dan masih terbuka (bagian 5, ROADMAP 5).
- Migrasi v1 -> v2 (`DataSave.migrasi`, `if versi < 2`): `misi_hasil` kosong, `tutorial.selesai` false, `terakhir.misi_hasil` "" dan `terakhir.koin_misi` 0; `flag`, `koin`, `hari`, `tip_total`, jeda, dan pengaturan dipertahankan. Dites dengan fixture bentuk save 4A asli dan v0.
- Migrasi v2 -> v3 (`if versi < 3`): `koin_total` = `koin` lama, `sepeda` baru (semua kondisi 1.0, level 0, `servis_total` 0: tidak ada kerusakan atau upgrade gratis); semua field v2 dipertahankan nilainya. Dites dengan fixture bentuk save 4B asli (hari 2, koin 195, flag `kucing_ketemu`), save 4A (v1), dan v0. Versi > 3 tidak ditimpa (disalin dulu).
- `catat_hari` (v3) menerima sepeda akhir rute dan belanja bengkel: `koin` = saldo lama + koin hari - belanja, `koin_total` = lama + koin hari (persis sekali), kondisi sepeda akhir (sesudah aus rute, servis, dan upgrade).

---

## 5. Yang perlu diputuskan

- ~~Segmen ditulis sebagai JSON atau scene Godot yang diekspor.~~ **Diputuskan 2026-10-16 (pemilik, K-1 run 3A): JSON buatan tangan** di `assets/data/routes/<distrik>/<id>.json` (bagian 3). Nilai `jenis`, parameter objek, dan aturan validasi tetap usulan sampai uji HP.
- Cara memetakan pelanggan tetap ke rute yang diacak. **Masih terbuka, ditunda ke Fase 6** (K-3): run 3A memakai id rute `<id_segmen>@<pos>` dan tidak menulis save; id rumah tetap di save (`per_r014`) belum ada.
- Misi lintas hari (GDD 10.9) memengaruhi save: misi aktif perlu disimpan atau tidak. **Masih terbuka** (run 4A dan 4B tidak menyimpan misi aktif; 4B tidak mengerjakan misi lintas hari).
- Format data milestone (Fase 6B). ~~Format data bengkel~~ **Diterapkan run 6A1 (usulan, bagian 6)**: `upgrades.json` dan kondisi sepeda di save v3 (bagian 4).
- Bentuk struktur sesi (setoran tiga pos, kalender, tenggat bab) yang menentukan di mana koin saldo dibelanjakan: **masih terbuka** (ROADMAP 5, Fase 6B). Alur Koran -> Rute -> Hasil -> Bengkel -> hari berikutnya di 6A1 adalah prototype.
- Setang dan lampu (komponen kelima dan keempat GDD 12.4): id `setang` dan `lampu` dicadangkan, belum dibuat.

---

## 6. Upgrade bengkel

File: `assets/data/shop/upgrades.json` (run 6A1, usulan). Array objek, dibaca satu-satunya oleh `PemuatToko` (validasi `DataToko`); layar bengkel, `Economy`, dan `BikeCondition` hanya menerima `DataToko`. Tingkat 1 saja di 6A1; `level` > 1 untuk komponen yang sama boleh ditambah nanti (level harus berurutan 1, 2, 3, ...).

Contoh nyata (isi `upgrades.json`, upgrade pertama; dua lainnya `rem_pakem` dan `rantai_hemat`):

```json
{
	"id": "ban_anti_selip",
	"komponen": "ban",
	"level": 1,
	"harga": 600,
	"nama": "TOKO_BAN_ANTI_SELIP_NAMA",
	"deskripsi": "TOKO_BAN_ANTI_SELIP_DESKRIPSI",
	"efek": [
		{"jenis": "pengali_lateral", "nilai": 1.15}
	]
}
```

| Field | Arti |
|---|---|
| `id` | Huruf kecil dan garis bawah, unik, **permanen**. Tiga id wajib (`Config.TOKO_ID_WAJIB`): `ban_anti_selip` (komponen `ban`; syarat distrik Desa), `rem_pakem` (`rem`), `rantai_hemat` (`rantai`). Ketiganya memenuhi "satu upgrade" untuk syarat distrik Ruko; tidak ada jenis ke-4 |
| `komponen` | `ban`, `rem`, atau `rantai` (`Config.KONDISI_KOMPONEN`) |
| `level` | Bilangan bulat >= 1. Level N hanya bisa dibeli bila level N - 1 komponen itu dimiliki; level tiap komponen berurutan tanpa lompatan atau kembar |
| `harga` | Koin bulat >= 1, dibayar dari saldo `koin` (rentang tingkat 1: 500 sampai 800, BALANCING 7) |
| `nama`, `deskripsi` | Kunci terjemahan di `translations/konten.csv` (awalan `TOKO_`); nama paling banyak 24 karakter, deskripsi paling banyak 48 (`Config.TOKO_NAMA_PANJANG_MAKS`, `TOKO_DESKRIPSI_PANJANG_MAKS`) |
| `efek` | Daftar tidak kosong `{"jenis", "nilai"}` dari daftar tertutup `Config.TOKO_EFEK_JENIS`, nilai dalam rentang aman (`TOKO_EFEK_MIN`/`TOKO_EFEK_MAKS`) dan komponen yang sesuai (`TOKO_EFEK_KOMPONEN`): `pengali_aus` (0,5 sampai 1,0, semua komponen: aus komponen itu lebih lambat, tidak pernah ditiadakan), `pengali_rem` (1,0 sampai 1,5, `rem`: perlambatan rem), `pengali_lateral` (1,0 sampai 1,25, `ban`: kecepatan pindah sisi), `pengali_kuras_stamina` (0,5 sampai 1,0, `rantai`: laju stamina yang menguras). Semuanya dibaca kode; **tidak ada jenis yang menaikkan kecepatan puncak** (tanpa power creep) |

Efek upgrade yang dimiliki (level komponen di save >= level upgrade) dikalikan; `DataToko.pengali_efek` dan `DataToko.pengali_aus` menghasilkan pengali untuk `BikeCondition.efek` dan `BikeCondition.aus`. Upgrade tidak mengubah kondisi, hanya laju aus dan gerak. Validasi menolak, tiap kasus dites: id ganda, komponen asing, level 0 atau negatif atau pecahan, urutan level tidak berurutan, harga <= 0 atau pecahan, jenis efek asing, nilai efek di luar rentang, efek untuk komponen yang salah, efek kosong, kunci teks hilang atau terlalu panjang, field asing, JSON rusak, dan berkas tidak ada (galat tanpa crash).
