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

File: `assets/data/routes/<distrik>/<id>.json`, satu file per segmen. Aturan menyusun segmen ada di `ROUTE_DESIGN.md`.

| Field | Isi |
|---|---|
| `id` | Kode unik, misalnya `per_lurus_01` |
| `distrik` | Distrik segmen |
| `panjang` | Panjang dalam ubin (24–40) |
| `tag` | `tingkat` (`tenang`/`sedang`/`padat`), `sisi_pelanggan`, `posisi` (`pembuka`/`tengah`/`penutup`) |
| `rumah` | Daftar petak rumah: `pos` (ubin dari awal segmen), `sisi`, `jenis` (aset rumah), `pelanggan_boleh` (true/false) |
| `objek` | Properti dan rintangan: `jenis`, `pos`, `jalur` (`seberang`/`tengah`/`dekat`), parameter perilaku |
| `titik_misi` | Tempat yang boleh dipakai misi: `nama` (misalnya `atap`, `balik_pot`), `pos`, `sisi` |

```json
{
  "id": "per_lurus_01",
  "distrik": "perumahan",
  "panjang": 32,
  "tag": { "tingkat": "tenang", "sisi_pelanggan": "seberang", "posisi": "pembuka" },
  "rumah": [
    { "pos": 2,  "sisi": "seberang", "jenis": "rumah_a", "pelanggan_boleh": true },
    { "pos": 6,  "sisi": "seberang", "jenis": "rumah_b", "pelanggan_boleh": true },
    { "pos": 10, "sisi": "seberang", "jenis": "rumah_a", "pelanggan_boleh": false }
  ],
  "objek": [
    { "jenis": "tong_sampah", "pos": 14, "jalur": "dekat" },
    { "jenis": "mobil_garasi", "pos": 22, "sisi": "seberang", "tanda_ubin": 9 }
  ],
  "titik_misi": [
    { "nama": "atap", "pos": 6, "sisi": "seberang" }
  ]
}
```

Rumah mana yang menjadi pelanggan ditentukan saat rute disusun (seed hari itu dan data pelanggan di save), bukan di segmen. Segmen hanya menyatakan rumah mana yang **boleh** jadi pelanggan.

Segmen awal mungkin lebih mudah dibuat di editor Godot sebagai scene `.tscn`, lalu diekspor ke JSON lewat skrip. Keputusan ini diambil di Fase 3.

---

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
- Id pelanggan memakai rumah tetap di distrik (`per_r014`), supaya pelanggan yang sama tetap ada walau segmen diacak. Cara memetakan rumah tetap ke segmen yang diacak perlu diputuskan di Fase 3.
- Save ditulis di akhir hari (layar hasil), bukan di tengah rute.
- `kosmetik.baju` memakai nama varian baju dari `ART_DIRECTION.md` 3.3.

---

## 5. Yang perlu diputuskan

- Segmen ditulis sebagai JSON atau scene Godot yang diekspor.
- Cara memetakan pelanggan tetap ke rute yang diacak.
- Misi lintas hari (GDD 10.9) memengaruhi save: misi aktif perlu disimpan atau tidak.
- Format data milestone dan bengkel (Fase 6).
