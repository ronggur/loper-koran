# Panduan Menyusun Rute — Loper Koran

Pasangan dari GDD bagian 4, 7, dan 9. GDD menjawab "rute itu apa"; dokumen ini menjawab "bagaimana membuat rute yang seru dan adil". Seluruh dokumen ini **usulan** dan diuji di Fase 3 (`DEV_PHASES.md`). Angka jarak dan kecepatan diambil dari `BALANCING.md`; format filenya di `DATA_SCHEMA.md` bagian 3.

## 1. Rute dari segmen

> **KEPUTUSAN (GDD 9.4):** potongan rute dibuat tangan, urutannya diacak, jadi rute tidak bisa dihafal.

- Satu **rute** = segmen pembuka + beberapa segmen tengah + segmen penutup, disusun dengan seed per hari supaya bisa diuji ulang.
- Satu **segmen** = potongan jalan lurus 24–40 ubin buatan tangan, berisi petak rumah, properti, dan rintangan. Segmen pendek lebih gampang diacak tanpa terasa berulang.
- **Tepi segmen netral**: setiap segmen diawali dan diakhiri 2 ubin jalan kosong tanpa rintangan, supaya dua segmen apa pun bisa disambung.
- Segmen diberi **tag**: distrik, tingkat (`tenang`, `sedang`, `padat`), sisi pelanggan (`seberang`, `dekat`, `dua_sisi`), dan rintangan yang dipakai. Penyusun rute memilih segmen dari tag, bukan dari nama.

Rute perumahan pertama (prototype 3): sekitar 250 ubin, 25 pelanggan di sisi seberang, 6–8 segmen.

## 2. Tata letak jalan

```
 sisi seberang (kiri pelempar, kiri atas layar)
 ─────────────── petak rumah: fasad, teras, kotak surat ───────────────
 ··············· trotoar ½ ubin ·······································
 [ jalur seberang ]   ← lempar ke seberang paling dekat
 [ jalur tengah   ]   ← bisa menjangkau dua sisi, lemparan lebih jauh
 [ jalur dekat    ]   ← lempar ke sisi dekat paling dekat
 ··············· trotoar ½ ubin ·······································
 ─────────────── petak rumah: belakang rumah ──────────────────────────
 sisi dekat (kanan pelempar, kanan bawah layar)
```

- Jalan perumahan 2 ubin. Posisi lateral sepeda bebas (stick analog), tapi untuk merancang dipakai **tiga jalur bantu**: seberang, tengah, dekat.
- **Petak rumah** 4 ubin (rumah 3 ubin + celah 1). Kotak surat di tepi jalan, teras di depan pintu.
- Jarak lempar 1,5–5 ubin ke samping (BALANCING 4): dari jalur seberang, kotak surat terjangkau swipe pendek; teras butuh swipe sedang.

## 3. Menempatkan rumah pelanggan

- Distrik pertama: pelanggan **hanya di sisi seberang** (GDD 9.1). Rumah sisi dekat ada, tapi bukan pelanggan.
- Jarak rata-rata antar pelanggan sekitar 9 ubin (BALANCING 6). Variasikan: beberapa rumah berurutan (ritme cepat), lalu sela panjang (napas).
- Sela antar pelanggan diisi rumah bukan pelanggan, persimpangan, taman, atau pos satpam, supaya radar dan mata pemain punya kerja.
- Jangan menaruh dua pelanggan berturut-turut yang hanya bisa dicapai dari jalur berlawanan dengan jarak kurang dari 4 ubin. Pemain butuh waktu untuk pindah jalur.
- Pelanggan pemberi tip dan target misi diletakkan di tempat yang menuntut lemparan tepat, tapi tetap bisa dicapai pada kecepatan santai.

## 4. Menempatkan rintangan

Aturan adil (GDD 2, prinsip 3):

1. **Selalu ada jalan keluar.** Di setiap titik, minimal satu jalur bisa dilewati tanpa tabrakan pada kecepatan santai.
2. **Tanda dulu, bahaya kemudian.** Setiap rintangan yang bergerak memberi tanda yang terlihat minimal **1,5 detik pada kecepatan ngebut** sebelum memotong jalur (sekitar 9 ubin di depan). Contoh: lampu mundur mobil, anjing menggonggong dan berdiri.
3. **Pola yang bisa dipelajari.** Rintangan yang sama selalu berperilaku sama (GDD 9.3). Variasi datang dari penempatan, bukan dari perilaku acak.
4. **Jangan menumpuk keputusan.** Dalam 6 ubin, maksimal satu rintangan yang memaksa pindah jalur. Rintangan kedua boleh ada kalau hanya memaksa melambat.
5. **Jalur utama tidak tertutup objek tinggi.** Pohon, mobil, dan atap boleh menutupi pemandangan, tapi rintangan di jalur selalu terlihat. Objek yang menutupi pemain dibuat semi-transparan.
6. **Rintangan tidak menutup satu-satunya kesempatan melempar.** Kalau mobil tamu menutupi kotak surat, teras tetap bisa dicapai.

Rintangan prototype 3: **anjing penjaga** (mengejar sesuai kecepatan, berhenti di batas halaman) dan **mobil keluar garasi** (lampu mundur dulu, baru bergerak).

## 5. Ritme dan kesulitan

- Segmen pembuka selalu `tenang`: tanpa rintangan bergerak, 2–3 pelanggan berdekatan untuk pemanasan.
- Selang-seling: setelah segmen `padat`, beri segmen `tenang` atau setengahnya.
- Segmen penutup pendek dan tenang supaya hari selesai dengan antaran yang berhasil, bukan tabrakan.
- Tiap distrik baru memperkenalkan satu atau dua rintangan baru di segmen `tenang` dulu, sendirian, sebelum digabung dengan rintangan lain (GDD 9.1).
- Ngebut harus menguntungkan di segmen tenang dan berisiko di segmen padat.

## 6. Misi di rute

- Target misi ditandai di segmen sebagai **titik misi** dengan sisi (seberang/dekat). Penyusun rute menaruh titik misi di segmen yang punya titik itu.
- Batas misi dihitung dalam rumah atau bagian rute (GDD 10.3), jadi segmen menghitung rumah, bukan detik.
- Petunjuk misi tidak ditaruh di belakang objek tinggi dan tidak berbarengan dengan rintangan yang memaksa pindah jalur.
- Tempat menepi untuk menangkap atau mengumpulkan butuh minimal 3 ubin jalur dekat tepi yang kosong.

## 7. Cara menguji segmen

- Mainkan segmen sendirian di tiga kecepatan: santai, cepat, ngebut. Ketiganya harus bisa dilewati tanpa tabrakan oleh pemain yang memperhatikan.
- Hitung keputusan per detik saat ngebut. Kalau terasa "tidak sempat", jarak tanda (aturan 4.2) terlalu pendek.
- Susun 20 rute acak dari segmen yang ada dan mainkan tiga di antaranya. Rute tidak boleh terasa dihafal (DEV_PHASES Fase 3).
- Catat tiap tabrakan saat playtest: kalau pemain tidak bisa menjelaskan kenapa menabrak, segmennya tidak adil.

## 8. Yang perlu diputuskan

- Panjang segmen dan rute final setelah graybox.
- Rute bercabang (gang pintas vs jalan utama, GDD 4.1): bagaimana cabang disusun dari segmen.
- Cara menampilkan rumah di sisi dekat.
- Persimpangan: hanya dekorasi, atau ada lalu lintas yang memotong.
