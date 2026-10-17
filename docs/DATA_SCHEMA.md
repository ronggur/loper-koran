# Skema Data — Loper Koran

Format file data yang dibaca game: misi, headline, segmen rute, dan save. Kolom misi di bagian 1 berasal dari dokumen ide (GDD 10). Bentuk JSON, nama field, dan bagian 2–4 adalah **usulan** dan dikunci saat Fase 3–4 (`DEV_PHASES.md`), setelah ada kode yang membacanya.

Aturan umum:

- Semua data konten berada di `assets/data/` sebagai JSON, satu file per kelompok (per distrik atau per jenis). Angka global tidak ditaruh di sini, tetapi di `scripts/config.gd` (`BALANCING.md` bagian 1).
- `id` memakai huruf kecil dan garis bawah, unik di seluruh game, dan **tidak pernah diganti** setelah dipakai di save.
- Sisi selalu ditulis `seberang` atau `dekat` (GDD 4.2), tidak pernah `kiri`/`kanan`.
- Jarak dalam ubin, batas misi dalam rumah (GDD 10.3), waktu dalam detik.
- Tes logika (`tests/run_tests.gd`) memuat semua file data dan memeriksa field wajib, id unik, rujukan id yang ada, dan panjang teks (`CONTENT_GUIDE.md` bagian 2–3).

---

## 1. Misi

File: `assets/data/missions/<distrik>.json`, berisi array misi.

| Kolom | Isi | Contoh |
|---|---|---|
| `id` | Kode unik | `p1_kucing` |
| `template` | Salah satu dari enam template (GDD 10.4): `cari`, `antar_khusus`, `lempar_khusus`, `kumpul`, `kejar`, `jaga` | `cari` |
| `headline` | Judul di koran, maksimal 40 karakter | `Kucing Bu Ratmi Hilang Sejak Semalam` |
| `ringkasan` | Satu baris di bawah headline, maksimal 60 karakter (usulan) | `Cari kucing di sisi seberang sebelum 12 rumah` |
| `hud` | Label di HUD, maksimal 14 karakter (usulan) | `Kucing` |
| `distrik` | Distrik yang boleh memunculkannya | `perumahan` |
| `rep_min` | Reputasi minimum distrik | `0` |
| `syarat` | Flag, hari, atau berita utama yang dibutuhkan | `{"berita_utama": "air_pasang"}` |
| `target` | Objek, rumah, atau sosok yang muncul, lengkap dengan sisinya | `{"objek": "kucing", "jumlah": 3, "sisi": "seberang"}` |
| `langkah` | Urutan kondisi sampai selesai | petunjuk 1, petunjuk 2, tangkap |
| `petunjuk` | Penanda visual dan suara | `["kilau", "ekor", "meong"]` |
| `batas` | Jumlah rumah atau bagian rute | `{"rumah": 12}` |
| `hadiah` | Tingkat hadiah dan tambahan (GDD 10.5) | `{"tingkat": "sedang", "tambahan": "pelanggan_setia"}` |
| `gagal` | Efek langsung saat gagal | `{"reputasi": 0}` |
| `flag_lanjut` | Flag yang ditulis saat selesai dan saat gagal, dibaca headline besok | `{"selesai": "kucing_ketemu", "gagal": "kucing_belum"}` |
| `jeda` | Hari sebelum boleh muncul lagi | `7` |

Contoh lengkap (P1 dari GDD 10.6):

```json
{
  "id": "p1_kucing",
  "template": "cari",
  "headline": "Kucing Bu Ratmi Hilang Sejak Semalam",
  "ringkasan": "Cari kucing di sisi seberang sebelum 12 rumah",
  "hud": "Kucing",
  "distrik": "perumahan",
  "rep_min": 0,
  "syarat": {},
  "target": { "objek": "kucing", "jumlah": 1, "sisi": "seberang" },
  "langkah": [
    { "jenis": "lihat", "titik": "atap", "rumah_dari_mulai": [3, 4] },
    { "jenis": "lihat", "titik": "bawah_mobil_tamu", "rumah_dari_sebelumnya": [3, 4] },
    { "jenis": "tangkap", "titik": "balik_pot", "rumah_dari_sebelumnya": [3, 4],
      "radius_ubin": 2.0, "lama_berhenti_detik": 1.5 }
  ],
  "petunjuk": {
    "visual": ["kilau", "ekor"],
    "suara": "meong",
    "dari_pelanggan": "Tadi ada kucing lewat ke arah warung"
  },
  "batas": { "rumah": 12 },
  "hadiah": { "tingkat": "sedang", "tambahan": "pelanggan_setia", "tokoh": "bu_ratmi" },
  "gagal": { "reputasi": 0 },
  "flag_lanjut": { "selesai": "kucing_ketemu", "gagal": "kucing_belum" },
  "jeda": 7
}
```

Misi lanjutan memakai field yang sama ditambah `lanjutan_dari` (id misi asal) dan `syarat` berisi flag, misalnya `{"flag": "kucing_belum"}`. Batasnya lebih longgar (GDD 10.7).

`langkah` berbeda per template. Field yang dipakai tiap template ditulis di sini setelah template itu dibuat (Cari di Fase 4, Antar khusus dan Kejar untuk P2–P3 di Fase 7, sisanya di Fase 8).

---

## 2. Headline

File: `assets/data/headlines/<jenis>.json` dengan jenis `utama`, `ringan`, dan `lanjutan`. Headline misi tidak ditulis di sini, karena sudah ada di data misi.

| Field | Isi | Contoh |
|---|---|---|
| `id` | Kode unik | `utama_hujan_deras` |
| `jenis` | `utama`, `ringan`, `lanjutan` | `utama` |
| `teks` | Maksimal 40 karakter (`CONTENT_GUIDE.md` 2) | `Hujan Deras Diperkirakan Seharian` |
| `distrik` | Daftar distrik, kosong berarti semua | `["desa", "sungai", "pasar"]` |
| `efek` | Hanya berita utama: kunci efek dunia (GDD 10.7) | `hujan_deras` |
| `syarat` | Flag, hari, atau tanggal | `{"flag": "kucing_belum"}` |
| `bobot` | Peluang relatif terpilih | `1` |
| `jeda` | Hari sebelum boleh muncul lagi | `5` |

Kunci `efek` dan artinya didefinisikan di kode (satu `match` per efek), bukan di data, supaya efek dunia tetap diuji.

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

File: `user://save.json`. Satu slot dulu.

```json
{
  "versi": 1,
  "hari": 4,
  "koin": 1240,
  "distrik_terbuka": ["perumahan"],
  "reputasi": { "perumahan": 7 },
  "pelanggan": {
    "per_r014": { "status": "setia", "meleset": 0, "tokoh": "bu_ratmi" },
    "per_r022": { "status": "aktif", "meleset": 1 }
  },
  "flag": ["kucing_ketemu"],
  "misi_jeda": { "p1_kucing": 11 },
  "sepeda": {
    "komponen": { "ban": 1, "rem": 1, "rantai": 1 },
    "kondisi": { "ban": 0.8, "rem": 0.6, "rantai": 1.0 }
  },
  "kosmetik": { "baju": "kemeja_agen", "dimiliki": ["kemeja_agen"] },
  "milestone": {},
  "pengaturan": { "kidal": false, "mode_bantu": false, "suara": 1.0, "musik": 1.0 }
}
```

- `versi` naik setiap format berubah. Game memigrasi save lama, tidak menghapusnya.
- Id pelanggan memakai rumah tetap di distrik (`per_r014`), supaya pelanggan yang sama tetap ada walau segmen diacak. Cara memetakan rumah tetap ke segmen yang diacak ditunda ke Fase 6 (bagian 5); di Fase 3 rumah hanya punya id rute `<id_segmen>@<pos>` (bagian 3) dan tidak ada yang ditulis ke save.
- Save ditulis di akhir hari (layar hasil), bukan di tengah rute.
- `kosmetik.baju` memakai nama varian baju dari `ART_DIRECTION.md` 3.3.

---

## 5. Yang perlu diputuskan

- ~~Segmen ditulis sebagai JSON atau scene Godot yang diekspor.~~ **Diputuskan 2026-10-16 (pemilik, K-1 run 3A): JSON buatan tangan** di `assets/data/routes/<distrik>/<id>.json` (bagian 3). Nilai `jenis`, parameter objek, dan aturan validasi tetap usulan sampai uji HP.
- Cara memetakan pelanggan tetap ke rute yang diacak. **Masih terbuka, ditunda ke Fase 6** (K-3): run 3A memakai id rute `<id_segmen>@<pos>` dan tidak menulis save; id rumah tetap di save (`per_r014`) belum ada.
- Misi lintas hari (GDD 10.9) memengaruhi save: misi aktif perlu disimpan atau tidak.
- Format data milestone dan bengkel (Fase 6).
