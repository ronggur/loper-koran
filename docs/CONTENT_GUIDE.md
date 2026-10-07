# Panduan Konten — Loper Koran

Cara menulis headline, teks misi, dialog pelanggan, dan nama tokoh supaya semua teks di game punya suara yang sama. Pasangan dari GDD bagian 10. Aturan panjang teks di dokumen ini **usulan** sampai layar koran diuji di HP (Fase 4). Format datanya di `DATA_SCHEMA.md` bagian 1–2.

## 1. Suara game

- **Hangat dan lucu, bukan sinis.** Dunia ini lingkungan yang kita kenal: tetangga, Pak RT, satpam kompleks, tukang sayur. Humor datang dari kejadian sehari-hari, bukan dari mengejek orang.
- **Gaya koran lokal.** Headline meniru gaya koran daerah: kalimat aktif, sedikit dramatis untuk hal kecil ("Ayam Tetangga Juara Lomba Berkokok").
- **Bahasa Indonesia sehari-hari yang rapi.** Kata baku untuk headline dan UI. Dialog pelanggan boleh santai ("tadi ada kucing lewat ke arah warung"), tanpa bahasa gaul yang cepat basi.
- **Aman untuk semua umur** sampai target usia diputuskan (ROADMAP 5). Tidak ada kekerasan, politik, SARA, merek nyata, atau nama orang terkenal.

## 2. Headline

Halaman depan selalu berisi tiga headline (GDD 10.1):

| Jenis | Fungsi | Contoh |
|---|---|---|
| Berita utama | Mengubah dunia hari itu (GDD 10.7) | "Hujan Deras Diperkirakan Seharian" |
| Misi sampingan | Pemicu misi, bisa diambil atau dilewati | "Kucing Bu Ratmi Hilang Sejak Semalam" |
| Berita ringan | Humor saja, tanpa efek | "Ayam Tetangga Juara Lomba Berkokok" |

Aturan menulis (usulan):

- **Maksimal 40 karakter**, ditulis dengan Huruf Kapital di Awal Kata. Kalau lebih, headline terpotong di layar 800×360.
- **Satu kejadian, satu kalimat.** Tanpa titik di akhir, tanpa tanda seru beruntun.
- **Headline misi harus menyebut apa yang dicari atau diantar** dan, bila perlu, nama atau tempatnya ("Paket Salah Alamat di Blok C"). Pemain harus bisa menebak misinya dari headline saja.
- **Berita utama harus bisa ditebak efeknya** ("Jalan Sedang Diperbaiki" → jalur menyempit). Jangan menulis berita utama yang efeknya mengejutkan tanpa tanda.
- **Headline lanjutan** dari flag kemarin memakai pola yang sama dengan headline asal supaya mudah dikenali: "Kucing Bu Ratmi Belum Ditemukan", "Sandal Hilang Lagi".
- Berita ringan boleh menyebut tokoh dan kejadian kemarin, supaya dunia terasa ingat.

Ringkasan satu baris di bawah headline misi (GDD 10.3): maksimal 60 karakter, berisi tindakan dan batas, misalnya "Cari kucing di sisi seberang sebelum 12 rumah".

## 3. Teks misi di rute

| Teks | Panjang | Contoh |
|---|---|---|
| Label HUD misi | ≤ 14 karakter + angka | "Kucing 0/1", "Petisi 2/4" |
| Banner selesai | ≤ 24 karakter | "Kucing ketemu!" |
| Banner gagal | ≤ 24 karakter, tidak menyalahkan | "Kucingnya lolos hari ini" |
| Petunjuk dari pelanggan | ≤ 50 karakter, satu kalimat | "Tadi ada kucing lewat ke arah warung" |

- **Arah dan sisi** selalu ditulis dengan istilah kontrol: **sisi seberang** (kiri pelempar) dan **sisi dekat** (kanan pelempar), atau patokan yang terlihat di rute ("ke arah warung", "dekat pos satpam"). Jangan memakai "kiri/kanan" tanpa keterangan, karena kiri layar dan kiri pelempar bisa berbeda.
- **Petunjuk tidak boleh berbohong.** Petunjuk boleh samar, tapi selalu mengarah ke yang benar.
- **Gagal ditulis ringan.** Gagal misi tidak pernah terasa sebagai hukuman (GDD 10.5): pakai "hari ini", "besok dicoba lagi".

## 4. Tokoh dan nama

- Tokoh punya **sapaan + nama** khas Indonesia dan dipakai konsisten di semua teks: Bu Ratmi (perumahan), Pak RT (perkampungan), Pak Sarmin (desa), Pak Ujang (sungai). Tokoh baru ditambahkan ke tabel di bagian 7.
- Nama terdengar umum dan beragam daerah, tidak mengacu orang nyata atau tokoh terkenal.
- Satu tokoh, satu sifat yang mudah diingat (Bu Ratmi sayang kucing, Pak RT bangga ayam jagonya). Sifat ini dipakai juga di berita ringan.
- Pelanggan umum tanpa nama disebut dari rumahnya: "rumah pagar hijau", "rumah nomor 12".
- Toko dan tempat memakai nama rekaan: "Warung Bu Inah", "Toko Kue Manis". Tidak ada merek nyata.

## 5. Latar

- Kota kecil Indonesia: kompleks perumahan, gang perkampungan, ruko, pasar, desa, pinggir sungai (GDD 9.2).
- Detail yang dikenal pemain Indonesia memperkuat suasana: pos ronda, portal satpam, jemuran, gerobak sayur, angkot, tujuh belasan, hajatan.
- Kejadian musiman (17 Agustus, Ramadan, hajatan) ditulis dengan hormat dan tanpa menyinggung ibadah secara langsung.

## 6. Proses menulis dan memeriksa

1. Tulis teks langsung di file data (`assets/data/headlines/*.json`, `assets/data/missions/*.json`), bukan di kode.
2. Cek panjang otomatis lewat tes (`tests/run_tests.gd`) dengan batas di bagian 2 dan 3.
3. Baca di HP pada layar koran asli. Teks yang terasa panjang di HP dipotong, walaupun lolos batas karakter.
4. Satu orang selain penulis membaca semua headline sebelum dimasukkan, untuk memastikan humor tidak menyinggung.

Bahasa Inggris atau bahasa lain belum direncanakan. Kalau nanti ada, semua teks sudah terkumpul di file data sehingga mudah diterjemahkan.

## 7. Daftar tokoh

| Tokoh | Distrik | Sifat | Muncul di |
|---|---|---|---|
| Bu Ratmi | Perumahan | Sayang kucing, pelanggan setia kalau ditolong | P1 |
| Satpam kompleks | Perumahan | Menjaga portal, memberi tip | P3 |
| Pak RT | Perkampungan | Bangga dengan ayam jagonya | K3 |
| Pak Sarmin | Desa | Petani, punya kerbau | D1 |
| Pak Ujang | Pinggir sungai | Pemilik perahu di dermaga | S1 |

## 8. Yang perlu diputuskan

- Target usia, yang menentukan batas humor dan aturan iklan.
- Nama pemain: punya nama tetap, bisa diganti, atau hanya "Loper".
- Nama kota atau lingkungan tempat game berlangsung.
- Contoh headline hari 1–3 untuk prototype 4.
