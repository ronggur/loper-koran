# Cerita Utama — Loper Koran

Alur cerita utama, tokoh, bab, akhir, dan cara cerita masuk ke gameplay. Dokumen ini dipisah dari `GDD.md` supaya mudah dilacak. Status per **7 Oktober 2026**. Hal yang belum diuji ditandai **usulan**. Pasangan dari GDD bagian 3 (tujuan utama), 8 (reputasi), dan 9 (distrik).

## 1. Keputusan

| # | Keputusan | Tanggal |
|---|---|---|
| 1 | Premis: gabungan **Tabungan Kuliah** dan **Menyambung Hidup Keluarga**. | 2026-10-07 |
| 2 | Tokoh utama muda, **baru lulus SMA** (sekitar 18 tahun). | 2026-10-07 |
| 3 | Cerita **tamat** saat uang tabungan dipakai menambah biaya daftar kuliah. | 2026-10-07 |
| 4 | Setelah tamat, game **tetap bisa dimainkan terus** (Fase Bebas). | 2026-10-07 |
| 5 | **Satu save, dua fase** (Cerita lalu Bebas), bukan dua mode terpisah. Tidak ada endless run dan daily challenge (GDD 13). | 2026-10-07 |
| 6 | Tokoh utama **laki-laki**, usia 17 sampai 18 tahun, bernama **Fajar Sidik**. Nama dipilih juga supaya mudah dibaca pemain luar negeri. | 2026-10-07 |

Semua bagian lain di dokumen ini adalah **usulan** sampai disetujui.

## 2. Premis

Tokoh utama baru lulus SMA. Ayahnya baru kena PHK dan tabungan keluarga terkuras untuk kebutuhan sehari-hari. Ia diterima kuliah, tapi biaya daftar ulang belum cukup. Ia menjadi loper koran selama dua bulan menjelang tenggat daftar ulang dan menabung dari tiap rute. Cerita tamat saat ia membayar biaya daftar: uang yang ia kumpulkan menutup kekurangan yang tidak sanggup ditutup keluarganya.

Latar ekonomi yang dirujuk: PHK yang berlanjut, daya beli yang turun, dan kelas menengah yang menyusut (lihat sumber di bagian 12).

## 3. Tokoh (usulan)

| Tokoh | Peran |
|---|---|
| **Fajar Sidik** (tokoh utama) | Laki-laki, lulusan SMA, 17 sampai 18 tahun. Dipanggil "Jar" oleh Pak Darto (usulan). |
| **Ayah** | Korban PHK pabrik. Awalnya murung, lalu mencari kerja serabutan. |
| **Ibu** | Berjualan kecil di pasar. Penghasilan turun karena pasar sepi. |
| **Adik** | Siswa SMP. Biaya sekolahnya jadi alasan tabungan terpotong. |
| **Pak Darto** | Pemilik agen koran, mentor, pemberi rute pertama. |
| **Dimas** | Teman sekolah yang berangkat kuliah lebih dulu dan mengirim kabar. |

Tokoh rute yang sudah ada (Bu Ratmi, Pak RT, Pak Sarmin, Pak Ujang, lihat CONTENT_GUIDE 7) muncul lagi di epilog.

## 4. Mekanik cerita (usulan)

- **Setoran harian.** Di layar hasil, penghasilan hari itu dibagi tiga: **Keluarga** (wajib kecil untuk dapur dan sekolah adik, naik saat ada kejadian darurat), **Bengkel** (servis dan upgrade sepeda), dan **Tabungan Kuliah** (menuju target biaya daftar). Pemain mengatur porsinya. Menabung banyak membuat sepeda cepat rusak, menyetor banyak ke keluarga membuat tabungan lambat.
- **Tenggat pendaftaran.** Kalender di HUD hasil menunjukkan sisa waktu menuju batas pendaftaran ulang.
- **Pilihan kecil.** Dua opsi di akhir tiap bab memengaruhi setoran, reputasi, dan akhir.
- **Tanpa game over.** Kalau tenggat terlewat, cerita lanjut ke akhir "tunda setahun", bukan kalah.

### 4.1 Biaya kuliah dan tenggat (usulan, direvisi 2026-10-07: cerita dipendekkan)

Angka disusun dari biaya kuliah PTN 2026 (lihat sumber di bawah) dan penghasilan loper sungguhan (GDD 14.1), lalu disetel di prototype. Cerita utama dibuat **60 hari rute (sekitar 5 jam)**, bukan 120 hari, karena versi 120 hari terasa terlalu panjang.

**Jalur dan biaya.** Fajar diterima di PTN lewat jalur SNBP atau SNBT, jadi **tanpa uang pangkal (IPI)**. Karena ayahnya di-PHK, ia mengajukan penyesuaian UKT dan ditetapkan di **golongan 2 (sekitar Rp1.000.000 per semester)**.

| Komponen biaya awal | Rupiah | Koin (1 koin = Rp100) |
|---|---|---|
| UKT semester 1 (golongan 2) | 1.000.000 | 10.000 |
| Kos dan deposit awal | 1.000.000 | 10.000 |
| Almamater, buku, perlengkapan, transport awal | 700.000 | 7.000 |
| Cadangan darurat bulan pertama | 1.000.000 | 10.000 |
| **Total kebutuhan** | **3.700.000** | **37.000** |
| Sumbangan keluarga (tabungan ibu) | 2.500.000 | 25.000 |
| **Target Tabungan Kuliah Fajar** | **1.200.000** | **12.000** |

Tabungan Fajar menambah biaya daftar, sesuai keputusan cerita: keluarga menutup sebagian besar, Fajar menutup kekurangannya.

**Tenggat.** Cerita mulai **19 Juni** (pengumuman diterima kuliah dan kabar PHK ayah) dan tenggat daftar ulang jatuh pada **18 Agustus**, tepat **60 hari** kemudian. Tenggat ini menutup bulan 17 Agustus, jadi bab terakhir bisa memakai suasana Tujuh Belasan (GDD 10.7). Satu hari rute di game sama dengan satu hari di kalender cerita.

**Mengapa masuk akal.**
- Penghasilan satu hari rapi 300 sampai 375 koin, ditambah tip dan hadiah misi, kira-kira **400 koin kotor per hari** (Rp40.000, dekat penghasilan nyata Rp30.000 sampai Rp40.000).
- Setoran harian yang realistis: **Keluarga 35 persen** (sekitar 140 koin), **Bengkel 15 persen** (sekitar 60 koin), **Tabungan 50 persen** (sekitar 200 koin).
- 60 hari dikali 200 koin kira-kira **12.000 koin**, tepat target. Pemain rata-rata pas-pasan, pemain yang rapi dan menjaga sepeda tetap sehat bisa mandiri, dan sisanya dibantu warga.
- Satu hari rute sekitar 5 menit, jadi cerita utama sekitar 5 jam bermain (usulan).

**Target tabungan per bab (rata-rata, usulan).** Satu bab sekitar 10 hari cerita.

| Bab | Hari cerita | Tabungan kumulatif | Persen target |
|---|---|---|---|
| Prolog dan 1 | 1 sampai 10 | 2.000 | 17 persen |
| 2 | 11 sampai 20 | 4.000 | 33 persen |
| 3 | 21 sampai 30 | 6.000 | 50 persen |
| 4 | 31 sampai 40 | 8.000 | 67 persen |
| 5 | 41 sampai 50 | 10.000 | 83 persen |
| 6 | 51 sampai 60 | 12.000 | 100 persen |

**Akhir menurut tabungan dan reputasi pada hari ke-60.**
- **Mandiri:** tabungan 100 persen atau lebih.
- **Dibantu warga:** tabungan 70 sampai 99 persen **dan** reputasi rata-rata di distrik yang sudah dibuka minimal 60. Kekurangan ditutup patungan warga.
- **Tunda setahun:** tabungan di bawah 70 persen, atau reputasi di bawah 60. Tabungan tetap dibawa ke tahun kedua.

**Tombol penyesuaian.** Panjang cerita diatur lewat `HARI_CERITA` (nilai awal 60) di `scripts/config.gd`. Target tabungan, tenggat, dan jumlah hari per bab mengikuti nilai itu. Kalau 5 jam masih terasa panjang, kurangi hari dan target secara proporsional (misalnya 45 hari dan 9.000 koin), tanpa mengubah rasio setoran.

## 5. Struktur: satu save, dua fase

| Fase | Isi |
|---|---|
| **Cerita** | Prolog sampai Bab 6, tenggat pendaftaran, setoran tabungan, bab per distrik. Berakhir di salah satu dari tiga akhir (bagian 8). |
| **Bebas** | Terbuka otomatis setelah tamat, di save yang sama. Bagian 9. |

Opsi yang bisa ditambah nanti: tombol "Main Bebas dari Awal" setelah tamat pertama, untuk save baru tanpa cerita.

## 6. Timeline bab (usulan)

Satu bab per distrik, mengikuti urutan distrik di GDD 9.

| Bab | Distrik | Peristiwa cerita | Yang terbuka |
|---|---|---|---|
| Prolog | Perumahan | Ayah di-PHK, hasil kelulusan keluar, Pak Darto menerima tokoh sebagai loper titipan. Tutorial lewat misi kucing Bu Ratmi. | Kontrol dasar, tabungan |
| 1 | Perumahan | Belajar rute, pelanggan pertama, ongkos pertama masuk tabungan. | Bengkel |
| 2 | Perkampungan | Rumah tokoh ada di sini. Motor ayah dijual, adik butuh biaya. Pilihan: pakai tabungan atau cari tambahan lewat misi. | Setoran keluarga |
| 3 | Ruko | Dimas berangkat kuliah. Tawaran jadi kurir online dengan bayaran lebih tinggi. Pilih setia pada koran atau tidak. | Misi antar khusus |
| 4 | Pasar tradisional | Ibu berjualan di pasar sepi. Koran memuat iklan baris untuk lapak ibu dan pedagang lain, pasar ramai kembali. | Pelanggan pedagang |
| 5 | Jalan desa dan persawahan | Ayah ikut kerja panen, keluarga mulai stabil, setoran keluarga turun. Tokoh sempat ragu apakah ingin kuliah. | Distrik jauh, misi jarak jauh |
| 6 | Pinggir sungai besar | Klimaks. Tenggat pendaftaran dekat, air pasang mengganggu rute, warga yang sudah akrab ikut membantu. | Akhir |

## 7. Syarat membuka distrik (usulan)

Satu distrik terbuka kalau **reputasi**, **peristiwa cerita**, dan **syarat pendukung** terpenuhi bersamaan. Reputasi memberi izin, cerita memberi alasan. Tidak ada syarat yang boleh membuat game macet: tiap syarat punya jalur pengganti.

| Distrik | Reputasi | Peristiwa cerita | Syarat pendukung |
|---|---|---|---|
| Perumahan | Terbuka sejak awal | Prolog | Selesai tutorial (kucing Bu Ratmi) |
| Perkampungan | Perumahan 40 | Ayah menjual motor, adik butuh biaya | 15 pelanggan tetap, satu misi sampingan selesai |
| Ruko | Perkampungan 50 | Dimas berangkat, tawaran kurir online | Satu upgrade sepeda, servis pertama |
| Pasar tradisional | Ruko 55 | Ibu berjualan di pasar sepi | Lulus satu misi antar khusus |
| Jalan desa dan persawahan | Pasar 60 | Ayah ikut panen | Ban anti-selip |
| Pinggir sungai besar | Desa 65 | Tenggat pendaftaran mendekat | Tabungan minimal 60 persen target (pemain rata-rata sekitar 83 persen di hari 50) |

Angka reputasi (skala 0 sampai 100) hanya contoh dan disetel di prototype.

Jenis trigger yang tersedia: reputasi distrik sebelumnya, peristiwa cerita, misi kunci (dengan jalur pengganti), syarat sepeda, jumlah pelanggan tetap, ambang tabungan, dan headline berita utama yang mengundang ke distrik baru.

Cara pemain tahu: headline di layar koran, pesan dari Pak Darto atau Dimas di layar hasil, dan peta dengan daftar syarat bercentang. Distrik yang sudah terbuka tidak terkunci ulang.

## 8. Akhir (usulan)

Cerita tamat saat pemain membayar biaya daftar. Ada tiga hasil menurut tabungan dan reputasi:

| Hasil | Kondisi | Cerita |
|---|---|---|
| **Mandiri** | Tabungan 100 persen atau lebih | Tokoh berangkat dengan tabungannya sendiri. |
| **Dibantu warga** | Tabungan 70 sampai 99 persen dan reputasi rata-rata minimal 60 | Warga di rute patungan secukupnya sebagai balas budi. Besar bantuan mengikuti reputasi. |
| **Tunda setahun** | Tabungan di bawah 70 persen atau reputasi di bawah 60 | Tokoh menunda kuliah setahun. Game lanjut ke "tahun kedua" dengan tabungan tersisa. |

## 9. Fase Bebas (usulan)

Tokoh berangkat kuliah dan menjadi **loper akhir pekan**. Semua distrik terbuka, hari berurutan tanpa tenggat cerita, dengan misi acak, milestone, kosmetik sepeda, dan kejadian musiman. Uang dipakai untuk sepeda dan kosmetik, bukan lagi untuk kuliah.

## 10. Cara narasi masuk ke gameplay (usulan)

- **Layar koran:** berita ringan memuat kabar bab (adik juara lomba, pasar ramai kembali).
- **Adegan singkat:** tiga sampai lima kotak dialog di awal dan akhir bab, bukan cutscene panjang.
- **Pesan masuk:** Dimas mengirim pesan di layar hasil.
- **Pilihan kecil:** dua opsi di akhir bab.
- **Tokoh rute:** tokoh yang pernah ditolong muncul lagi di epilog.

## 11. Yang perlu diputuskan

- Apakah 60 hari cerita (sekitar 5 jam) terasa pas, atau perlu dipendekkan lagi lewat `HARI_CERITA` (bagian 4.1).
- Apakah reputasi bisa dikejar dengan farming satu distrik atau dibatasi per hari.
- Apakah setelah tamat semua distrik otomatis terbuka.
- Pilihan kecil di akhir bab: apa saja, dan seberapa jauh memengaruhi akhir.
- Angka reputasi per distrik (bagian 7).

## 12. Pelacakan

| Item | Status | Catatan |
|---|---|---|
| Premis dan tokoh utama | ✅ Diputuskan 2026-10-07 | Bagian 1 |
| Satu save, dua fase | ✅ Diputuskan 2026-10-07 | Bagian 5 |
| Timeline bab per distrik | 🟡 Usulan | Bagian 6 |
| Syarat membuka distrik | 🟡 Usulan | Bagian 7 |
| Tiga akhir | 🟡 Usulan | Bagian 8 |
| Naskah dialog dan adegan bab | ⬜ Belum | Ikuti CONTENT_GUIDE |
| Nama tokoh utama | ✅ Fajar Sidik, diputuskan 2026-10-07 | Bagian 1 |
| Angka biaya daftar, konversi koin, dan tenggat | 🟡 Ditetapkan sebagai angka awal 2026-10-07, disetel di prototype | Bagian 4.1, `BALANCING.md` 7.1 |

## 13. Riwayat

- **2026-10-07** — Opsi premis dibahas dan dikerucutkan ke Tabungan Kuliah ditambah Menyambung Hidup Keluarga. Diputuskan: tokoh baru lulus SMA, uang tabungan menambah biaya daftar kuliah, game lanjut setelah tamat, satu save dua fase. Cerita dipisah ke `STORY.md`.
- **2026-10-07** — Tokoh utama dikunci laki-laki, 17 sampai 18 tahun, bernama **Fajar** (dipilih dari enam opsi, salah satu pertimbangan: mudah dibaca pemain luar negeri). Nama belakang dipilih Ronggur: **Sidik** (dari "siddiq", yang jujur), sehingga nama lengkap **Fajar Sidik**.
- **2026-10-07** — Biaya kuliah dan tenggat ditetapkan (usulan, disetel di prototype). Versi pertama 120 hari (sekitar 10 jam) dianggap terlalu panjang, jadi diperpendek: tenggat 60 hari (19 Juni sampai 18 Agustus, sekitar 5 jam), total kebutuhan Rp3.700.000 dengan sumbangan keluarga Rp2.500.000, target Tabungan Kuliah 12.000 koin (Rp1.200.000), setoran 35/15/50 persen.

## Sumber (konteks ekonomi dan biaya)

- [Masoem University: UKT PTN 2026 dan IPI](https://masoemuniversity.ac.id/?p=59485) (UKT golongan 1 sekitar Rp500.000, golongan 2 sekitar Rp1.000.000, jalur SNBP dan SNBT tanpa uang pangkal)
- [Dealls: UKT dan IPI UNNES 2026](https://dealls.com/pengembangan-karir/ukt-unnes)
- [Bisnis.com: Badai PHK Diramal Berlanjut saat Pasar Lesu Serap Tenaga Kerja Baru](https://ekonomi.bisnis.com/read/20260120/12/1945355/badai-phk-diramal-berlanjut-saat-pasar-lesu-serap-tenaga-kerja-baru)
- [Investortrust: Ancaman Ekonomi 2026, Daya Beli Turun, Kelas Menengah Menyusut](https://www.investortrust.id/macro/86628/ancaman-ekonomi-2026-daya-beli-turun-kelas-menengah-menyusut)
