# Skema Data — Loper Koran

Format file data yang dibaca game: misi, headline, segmen rute, dan save. Kolom misi di bagian 1 berasal dari dokumen ide (GDD 10). Bentuk JSON, nama field, dan bagian 1, 2, dan 4 adalah **usulan** yang diterapkan di run `20261018-fase4a-koran-hari` (dibaca `DataMisi`/`PemuatMisi`, `DataHeadline`/`PemuatHeadline`, dan `DataSave`/`SaveManager`), belum dikunci sampai diuji di HP. **Alur hari berurutan yang memakai format ini adalah prototype yang tidak mengunci struktur sesi** (ROADMAP 5: hari terakhir, game over, dan target harian tetap terbuka).

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
| `flag_lanjut` | Flag yang ditulis saat selesai dan saat gagal, dibaca headline besok | `{"selesai": "kucing_ketemu", "gagal": "kucing_belum"}` |
| `jeda` | Hari sebelum boleh muncul lagi, dihitung dari hari misi DIAMBIL (S-4); misi yang dilewati tidak memicu jeda | `7` |
| `aktif` | Opsional, bawaan `true`. Menonaktifkan misi = `false`, id tidak pernah dihapus atau dipakai ulang | `true` |
| `lanjutan_dari` | Opsional: id misi asal bila ini misi lanjutan; misi lanjutan tidak ikut undian biasa, hanya lewat headline lanjutan | `p1_kucing` |

**Validasi** (`DataMisi.parse`, `PemuatMisi`; dijalankan tes pada berkas nyata): field wajib ada dan bertipe benar, field tidak dikenal ditolak, `id` huruf kecil, angka, dan garis bawah (dimulai huruf) dan unik, `template` salah satu dari enam, `distrik` dikenal, `rep_min` dan `jeda` tidak negatif, `hadiah.tingkat` kecil/sedang/besar, `flag_lanjut.selesai` dan `.gagal` berupa id, kunci terjemahan harus ada, dan teks hasil terjemahan <= 40 (headline, juga Huruf Kapital di Awal Kata), 60, 14, 50 karakter. `target`, `langkah`, `petunjuk`, `batas` di 4A hanya diperiksa tipenya (aturan template Cari ditambah di 4B).

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
    "jeda": 7
  }
]
```

Misi lanjutan memakai field yang sama dengan `lanjutan_dari` (id misi asal) dan `syarat` berisi flag, misalnya `{"flag": "kucing_belum"}`. Batasnya lebih longgar (GDD 10.7). Misi lanjutan P1 belum ada di data (4B); headline lanjutannya memakai `misi_ditunda` (bagian 2).

`langkah` berbeda per template. Field yang dipakai tiap template ditulis di sini setelah template itu dibuat (Cari di Fase 4, Antar khusus dan Kejar untuk P2–P3 di Fase 7, sisanya di Fase 8).

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

File: `user://save.json`. Satu slot dulu. Format v1 di bawah dibaca dan ditulis `SaveManager` (autoload) lewat `DataSave`; **alur hari berurutan yang memakai save ini adalah prototype yang tidak mengunci struktur sesi** (ROADMAP 5: hari terakhir, kalender 120 hari, game over, target harian belum diputuskan). Field DATA_SCHEMA lain yang belum dipakai (`distrik_terbuka`, `reputasi`, `pelanggan`, `sepeda`, `kosmetik`, `milestone`) belum ditulis; bila ada di berkas (save masa depan) dibiarkan.

Contoh save nyata setelah hari 1 selesai (isi dari tes alur hari `tests/tes_alur_hari.gd`: P1 diambil, 3 dari 25 terantar, koin 120 termasuk tip 25, skor 1500):

```json
{
	"flag": [],
	"hari": 2,
	"headline_jeda": {
		"ringan_mangga": 4,
		"utama_jalan_diperbaiki": 5
	},
	"koin": 120,
	"misi_jeda": {
		"p1_kucing": 8
	},
	"pengaturan": {
		"kidal": false,
		"mode_bantu": false,
		"musik": 1.0,
		"suara": 1.0
	},
	"terakhir": {
		"hari": 1,
		"koin": 120,
		"meleset": 22,
		"misi_diambil": "p1_kucing",
		"skor": 1500,
		"terkirim": 3,
		"tip": 25
	},
	"tip_total": 25,
	"versi": 1
}
```

(Kunci diurutkan abjad oleh `DataSave.ke_teks`, jadi isi sama = teks sama byte demi byte.)

| Field | Arti |
|---|---|
| `versi` | Naik setiap format berubah (`Config.SAVE_VERSI`); game memigrasi save lama lewat `if versi < N: ...; versi = N`, tidak menghapusnya. Save tanpa `versi` dianggap v0 dan digabung dengan templat |
| `hari` | Hari yang AKAN dimainkan berikutnya, mulai 1 (S-3); naik 1 saat "Hari berikutnya" |
| `koin` | Total koin; bertambah sebesar koin hari itu (sudah termasuk tip), tidak pernah berkurang oleh hukuman |
| `tip_total` | Total koin dari tip (bagian dari `koin`) |
| `flag` | Daftar flag aktif (id); hanya bertambah. Id yang tidak ada di data dibiarkan |
| `misi_jeda` | Id misi -> hari pertama boleh muncul lagi (hari diambil + `jeda`) |
| `headline_jeda` | Id headline -> hari pertama boleh muncul lagi (hari tampil + `jeda`) |
| `terakhir` | Hasil hari terakhir dari `HasilRute.Angka` yang sama dengan layar hasil: `hari`, `terkirim`, `meleset`, `koin`, `tip` (bagian tip), `skor`, `misi_diambil` ("" bila dilewati) |
| `pengaturan` | `kidal`, `mode_bantu` (sakelar layar jeda, disimpan di akhir hari dan dibaca sebelum layar koran), `suara`, `musik` (0 sampai 1, bawaan 1.0, belum dipakai) |

Aturan:

- Save ditulis di akhir hari (tombol "Hari berikutnya" di layar hasil), tepat satu kali per hari, bukan di tengah rute. Tutup app di tengah rute: save terakhir utuh, hari yang sama dimulai lagi dari layar koran dengan headline dan seed rute yang sama.
- Penulisan atomik: ke `user://save.tmp`, diperiksa terbaca, lalu rename. Save rusak (bukan JSON, bukan objek, field kunci bertipe salah) atau `versi` lebih baru tidak ditimpa diam-diam: disalin dulu ke `user://save.corrupt.<detik unix>.json`, permainan mulai dari state bawaan, dan layar koran memberi tahu satu baris. Nilai tidak sah di dalam blok (negatif, tipe salah) dijepit atau diganti bawaan.
- Progres tidak turun: `hari`, `koin`, `tip_total` hanya naik, flag hanya bertambah, jeda tidak mundur; hari dengan koin 0 tidak mengurangi apa pun.
- Id pelanggan memakai rumah tetap di distrik (`per_r014`), supaya pelanggan yang sama tetap ada walau segmen diacak. Cara memetakan rumah tetap ke segmen yang diacak ditunda ke Fase 6 (bagian 5); di Fase 3 dan 4A rumah hanya punya id rute `<id_segmen>@<pos>` (bagian 3) dan tidak ada yang ditulis ke save.
- `kosmetik.baju` (nanti) memakai nama varian baju dari `ART_DIRECTION.md` 3.3.
- Misi aktif lintas hari tidak disimpan (misi lintas hari ditunda ke 4B dan masih terbuka, ROADMAP 5).

---

## 5. Yang perlu diputuskan

- ~~Segmen ditulis sebagai JSON atau scene Godot yang diekspor.~~ **Diputuskan 2026-10-16 (pemilik, K-1 run 3A): JSON buatan tangan** di `assets/data/routes/<distrik>/<id>.json` (bagian 3). Nilai `jenis`, parameter objek, dan aturan validasi tetap usulan sampai uji HP.
- Cara memetakan pelanggan tetap ke rute yang diacak. **Masih terbuka, ditunda ke Fase 6** (K-3): run 3A memakai id rute `<id_segmen>@<pos>` dan tidak menulis save; id rumah tetap di save (`per_r014`) belum ada.
- Misi lintas hari (GDD 10.9) memengaruhi save: misi aktif perlu disimpan atau tidak. **Masih terbuka, ditunda ke 4B** (run 4A tidak menyimpan misi aktif).
- Format data milestone dan bengkel (Fase 6).
