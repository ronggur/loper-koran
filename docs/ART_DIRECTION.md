# Art Direction & Asset Guide — Loper Koran

Dokumen pendamping [`GDD.md`](./GDD.md). GDD menjawab "game ini bekerja bagaimana"; dokumen ini menjawab "game ini kelihatan seperti apa, dan aset apa saja yang harus dibuat". Setiap aset baru wajib mengikuti bagian 2. Kalau ada aset yang tidak cocok dengan aturan di sini, ubah asetnya, atau ubah aturannya lewat keputusan yang dicatat di changelog, jangan dibiarkan berbeda diam-diam.

Label **usulan** berarti belum dikunci dan masih bisa berubah setelah diuji di HP.

---

## 1. Prinsip Visual

> **Rangkuman, perlu dikonfirmasi (2026-10-07).** Diturunkan dari prinsip GDD bagian 2 dan dari keputusan visual yang sudah diambil.

1. **Gameplay terbaca lebih dulu, keindahan kedua.** Kotak surat, teras, rintangan, dan petunjuk misi harus langsung terlihat di layar HP yang dipegang dua tangan. Latar boleh kaya, tapi kontrasnya selalu di bawah objek gameplay.
2. **Satu sudut pandang, satu kepadatan piksel.** Semua yang ada di dunia game memakai isometrik 2:1 dan skala piksel yang sama dengan sprite pemain. Campuran sudut atau ukuran piksel langsung terlihat amatir.
3. **Indonesia sehari-hari, bukan kartu pos.** Rumah perumahan, gang, warung, motor, jemuran, dan pedagang keliling digambar akrab dan sedikit jenaka, bukan eksotis.
4. **Modern di cahaya, retro di piksel.** Lighting dinamis, partikel, dan color grading boleh dipakai, tapi piksel tetap tajam: tanpa anti-aliasing, tanpa skala pecahan, tanpa blur di sprite.
5. **Hemat sejak awal.** Rumah dibuat modular, distrik dan waktu dibedakan lewat palet, dan varian dibuat lewat palette swap. Aset paling murah adalah yang tidak jadi dibuat.

---

## 2. Gaya Visual

> **KEPUTUSAN (2026-10-06): pixel art isometrik**, dengan gaya pixel Brainy Dungeon sebagai acuan (garis 1 px, palet terbatas, bayangan kecil, skala bulat), dimodernkan lewat lighting dinamis, bayangan lembut, partikel, depth of field ringan, bloom, dan color grading per distrik. Referensi rasa: Eastward dan Octopath Traveler, tanpa pindah dari isometrik 2:1. Eksplorasi karakter bergaya flat (2026-10-06) ditinggalkan.

### 2.1 Aturan konsistensi

Yang membedakan pixel art profesional dari yang amatir hampir seluruhnya soal konsistensi. Aturan ini berlaku untuk semua sprite dunia game, tanpa kecuali.

1. **Satu kepadatan piksel.** Semua sprite digambar di ukuran piksel asli (1×) dengan kepadatan yang sama dengan sprite pemain (tinggi pemain dan sepeda 47 px), lalu diperbesar Godot dengan kelipatan bulat yang sama untuk semua. Sprite yang ukuran pikselnya berbeda (*mixel*) adalah penanda amatir nomor satu.
2. **Garis luar 1 px warna `#0E0A1C`**, termasuk garis dalam antarbagian yang saling menutup. Tanpa anti-aliasing. Mock jalan lama di kanvas kamera masih memakai `#2A1E17`; aset baru memakai `#0E0A1C` seperti sprite pemain dan Brainy Dungeon.
3. **Tiga nada per material:** terang, dasar, gelap. Warna dasar mendominasi; nada gelap hanya di sisi yang membelakangi cahaya, nada terang hanya di bidang yang menghadap cahaya. Tanpa gradien.
4. **Cahaya dari kiri atas** di semua sprite. Konsekuensinya, fasad sisi seberang (menghadap kanan bawah) cenderung gelap; pintu, jendela, dan kotak surat di fasad dibuat kontras supaya tetap terbaca (keputusan 2026-10-05).
5. **Bayangan di tanah berwarna** (usulan, 2026-10-07): elips 28% (alpha 71), digeser 1 px ke kanan bawah, dipanggang di sprite dengan `#000000` sebagai **warna penanda**. Di game, shader mengganti piksel penanda itu dengan **warna bayangan** distrik dan waktu yang aktif (bagian 2.5), jadi bayangan tidak pernah hitam pekat. Bayangan lembut dari lighting dinamis memakai warna yang sama.
6. **Detail di bawah 2 px dihilangkan.** Bentuk dibuat besar dan sederhana. Wajah pemain dari arah depan hanya sekitar 4 baris piksel, jadi ekspresi cukup dua mata dan mulut.
7. **Objek gameplay lebih kontras dari latar.** Kotak surat, teras sasaran, rintangan, dan petunjuk misi memakai nada terang dan garis luar penuh; dinding, atap, dan tanah latar memakai kontras rendah.

### 2.2 Kamera dan geometri isometrik

> **KEPUTUSAN (2026-10-05): isometrik 2:1 terkunci, jalan naik ke kanan atas.** Dibandingkan dengan arah kiri atas di papan "Banding arah jalan"; arah kiri atas ditinggalkan.

- **Proyeksi 2:1**: satu langkah dunia di sumbu x menggeser layar (+1, +½) piksel, di sumbu y (−1, +½), dan tinggi z (0, −1). Ubin belah ketupat **64×32 px (usulan)** = persegi dunia 32×32 unit.
- **Arah jalan** naik ke kanan atas. Sepeda di **sepertiga kiri layar**, jadi pandangan ke depan jatuh di area yang bebas dari jempol.
- **Kamera melihat sisi kanan sepeda** (rantai dan gir) dan punggung pengendara.
- **Sisi seberang** (kiri pelempar) ada di kiri atas jalan: fasad, pintu, dan kotak surat terlihat. **Sisi dekat** (kanan pelempar) ada di kanan bawah jalan: rumah hanya terlihat belakangnya. Cara menampilkan rumah di sisi dekat masih terbuka (bagian 11).
- **Arah pemain tidak bisa dicerminkan**: karena kamera selalu dari kanan belakang, arah kiri dan kanan digambar terpisah.
- **Objek tinggi** (rumah, pohon, mobil, jemuran) boleh menutupi rintangan di baliknya, tapi jalur utama tetap bersih dan objek yang menutupi pemain dibuat semi-transparan.
- **Urutan gambar** memakai Y-sort Godot dengan origin setiap sprite di titik pijaknya di tanah.

Ukuran relatif (usulan, dicek di graybox Fase 1):

| Objek | Ukuran dunia | Kira-kira di layar (1×) |
|---|---|---|
| Ubin | 32×32 unit | 64×32 px |
| Pemain + sepeda | panjang ~30 unit, tinggi ~38 unit | 46×58 px sel, tinggi badan 47 px |
| Lebar jalan perumahan | 2 ubin + trotoar ½ ubin tiap sisi | |
| Rumah perumahan | tapak 3×3 ubin, dinding ~40 px, atap ~30 px | lebar ~192 px |
| Kotak surat | tapak ¼ ubin, tinggi ~20 px | |
| Mobil | 2×1 ubin | |

### 2.3 Cahaya, bayangan, dan efek modern

- Cahaya utama dari kiri atas dipanggang di sprite (nada terang/dasar/gelap). Lighting dinamis engine hanya **menambah**: lampu jalan dan lampu sepeda di malam hari, jendela menyala, kilat, dan color grading per waktu.
- **Bayangan berwarna** (usulan): bayangan tanah, bayangan jatuh dari objek tinggi, dan bayangan lembut engine memakai warna bayangan dari bagian 2.5, bukan hitam. Nada gelap material tidak berubah; yang berwarna hanya bayangan yang jatuh ke permukaan lain. Cara kerjanya: satu shader mengganti piksel `#000000` alpha 71 dengan warna bayangan aktif, jadi sprite yang sudah ada (termasuk pemain) tidak perlu dirender ulang.
- Glow dan cahaya lampu memakai cincin piksel semi-transparan bertumpuk atau light 2D engine, bukan gradien di dalam sprite.
- Partikel (debu roda, percikan genangan, kertas koran) digambar sebagai sprite piksel kecil dengan palet yang sama.
- Depth of field dan bloom dipakai ringan dan tidak pernah membuat objek gameplay kabur. Apakah semuanya jalan di renderer Compatibility di HP kelas bawah harus dicek di Fase 0 (bagian 7).

### 2.4 Palet induk (usulan)

Diambil dari sprite pemain produksi dan mock jalan. Dikunci setelah aset gelombang 1 (Fase 5). Satu file referensi palet (`assets/palette/loper_master.gpl` untuk Aseprite/LibreSprite, dan `scripts/ui/palette.gd` untuk warna UI) dibuat di Fase 0.

| Peran | Warna (terang · dasar · gelap) |
|---|---|
| Garis luar | `#0E0A1C` |
| Bayangan tanah | penanda `#000000` alpha 28%, diganti warna bayangan aktif (bagian 2.5) |
| Kertas, krem | `#FBF6E8` · `#F2E7C9` · `#C2AF86`; putih `#FFFFFF` |
| Kulit terang | `#F2B98C` · `#E8A07A` · `#B47C5F` |
| Kulit sawo | `#D89A6C` · `#B47C5F` · `#8A5A40` |
| Rambut | `#8A5A40` · `#6D4334` · `#4A2319` |
| Biru kemeja, kaca | `#9BC4D8` · `#5F96C8` · `#466E8C` |
| Dongker | `#7480A3` · `#5C6A8C` · `#404A62` |
| Hijau rangka, daun | `#6FAE4F` · `#466E50` · `#314D38` |
| Rumput | `#7DBB5A` · `#6FAE4F` · `#62A046` |
| Merah bata, atap | `#B5523B` · `#994532` · `#673F31` (aksen `#7E3929`) |
| Cokelat kayu, pintu | `#B47C5F` · `#96643C` · `#553428` |
| Logam | `#C4C0C8` · `#969AA0` · `#67636D` |
| Logam gelap, ban | `#5F5B66` · `#3D4649` · `#221E26` |
| Aspal | `#6C6872` · `#67636D`, marka `#F2E7C9` |
| Trotoar, kerb | `#DCCBA6` · `#D5C4A1`, kerb `#A9A2AE` |
| Dinding pastel | pink `#F0C8CD`/`#BB9C9F`, krem `#F6D6A0`, hijau muda `#C9E0A5`/`#9CAE80`, biru muda `#AADCF0`/`#90BBCC` |
| Aksen hangat | `#FFE08A` · `#FFC94A` · `#E98E3F` |

### 2.5 Palet per distrik dan waktu (usulan)

Gaya piksel sama, palet berbeda, supaya pemain langsung tahu sedang di mana (GDD 9.4).

| Distrik | Rasa palet |
|---|---|
| Perumahan | Pastel cerah, rumput hijau segar, aspal abu-abu ungu |
| Perkampungan | Hangat dan padat: semen, bata, seng berkarat, cat tembok pudar |
| Ruko | Abu-abu beton dengan papan nama warna-warni dan rolling door |
| Pasar tradisional | Terpal biru dan oranye, kayu lapak, lantai basah gelap |
| Jalan desa | Hijau sawah, tanah cokelat, langit luas |
| Pinggir sungai | Biru-hijau air, kayu dermaga, rumah panggung |

| Waktu | Color grading | Warna bayangan (usulan) |
|---|---|---|
| Pagi | Hangat dan terang, bayangan panjang tipis | `#3E3A66` ungu kebiruan |
| Siang | Netral terang, kontras tinggi | `#2E3550` dongker tua |
| Sore | Jingga, bayangan panjang | `#5A2E3A` merah anggur |
| Malam | Biru gelap; lampu jalan, lampu sepeda, dan jendela menyala | `#141A3A` biru malam |

Warna bayangan sengaja lebih dingin dari cahaya hangat dari kiri atas, supaya bentuk tetap terbaca tanpa hitam pekat. Tiap distrik boleh menggesernya sedikit ke arah rasa paletnya (misalnya lebih hijau di jalan desa, lebih biru-hijau di pinggir sungai), selama tetap gelap. Dikunci bersama palet induk.

### 2.6 Lingkungan: cahaya, jalan, dan detail (usulan)

> **Usulan (2026-10-07)**, disetujui di kanvas "Lingkungan Loper Koran" tapi belum diuji di HP. Mock dan cara merender ulang: [`design/environment/`](./design/environment/), `tools/env_art`.

**Cahaya dan bayangan**

- Bayangan jatuh dan sisi yang membelakangi matahari **diwarnai sesuai waktu**, bukan hitam, supaya material di dalam bayangan tetap terbaca. Arah cahaya tetap dari kiri atas; yang berubah hanya tinggi matahari dan warna. Kalau dipakai, ini menggantikan bayangan hitam 28% di aturan 2.1 nomor 5 untuk lingkungan.

| Waktu | Sudut matahari | Pengali cahaya (R · G · B) | Pengali bayangan (R · G · B) |
|---|---|---|---|
| Pagi | 24° | 1,04 · 1,00 · 0,90 | 0,66 · 0,70 · 0,92 |
| Siang | 52° | 1,00 · 1,00 · 1,00 | 0,60 · 0,62 · 0,82 |
| Sore | 20° | 1,08 · 0,90 · 0,72 | 0,60 · 0,53 · 0,76 |
| Malam | 40° | 0,40 · 0,46 · 0,70 | 0,24 · 0,26 · 0,46 |

- Lampu malam (`#FFD27A`) menerangi dalam tiga cincin (1,00 · 0,62 · 0,30), hanya permukaan yang menghadap lampu. Jendela menyala memakai glow tiga cincin piksel.
- **Pemain hanya kena setengah color grading** supaya tidak tenggelam di bayangan sore dan malam.
- Di Godot (cek di Fase 0): CanvasModulate per waktu, lapisan bayangan multiply, PointLight2D bertekstur cincin.

**Penampang jalan per distrik**

| Distrik | Jalan |
|---|---|
| Perumahan | Aspal 3 ubin (dua lajur mobil), kerb pemisah, **lajur sepeda hijau ¾ ubin di tiap sisi** menggantikan trotoar, tepi putus-putus di depan jalan masuk garasi. Loper di lajur sepeda kiri, di samping deretan kotak surat. Halaman depan dipersempit supaya rumah di kedua sisi tetap terlihat. |
| Perkampungan | Gang 2 ubin, selokan di kedua sisi. Di sisi dekat, rumah dan halaman (kandang ayam, kebun, jemuran) diselang-seling. |
| Ruko | 2 lajur (aspal 3 ubin), garis tengah putus-putus, trotoar di kedua sisi |
| Pasar | Lorong hampir 4 ubin di antara lapak |
| Jalan desa | Jalan tanah 2 ubin, parit di sisi dekat |
| Pinggir sungai | Jalan semen hampir 2 ubin. Muka air jauh di bawah jalan dengan **talud batu kali miring**; lampu jalan di sisi sungai. |

Jalan yang lebih lebar membuat lemparan ke sisi dekat butuh swipe panjang; perlu diuji di prototype 2.

**Variasi rumah perumahan** (bentuk, bukan cuma warna), diselang-seling di sisi seberang: *limasan* (badan lebar, atap limas, teras di tengah), *pelana* (segitiga atap menghadap jalan dengan lubang angin, teras samping beratap dak), *sayap* (badan utama mundur, ruang depan menonjol beratap pelana kecil, teras di ceruk). Rumah sisi dekat bergantian atap limas, pelana melintang, dan pelana memanjang. Warna dinding dan atap tetap lewat palette swap.

**Pohon perumahan**, tiga jenis bergantian: *rindang* (mangga/kersen: batang bercabang, tajuk lebar dari banyak gumpalan), *glodokan tiang* (ramping, meruncing), *ketapang kencana* (tajuk datar bertingkat).

**Kendaraan:** sedan, angkot (minibus tanpa rak atap), dan bus kecil kota dua warna dengan papan trayek; semuanya punya kaca miring, sudut bodi tumpul, lekuk roda, pelek, dan lampu.

**Palet distrik** tambahan dari palet induk ada di papan "Palet per distrik" (ramp terang · dasar · gelap), dengan color grading ringan per distrik (contoh: perkampungan R ×1,04 B ×0,94, sungai R ×0,97 B ×1,04).

**Detail hidup di pinggir jalan:** jemuran bergoyang (kaus, celana, handuk, sarung; 8 frame), ayam jalan dan mematuk (8 frame, tiga warna lewat palette swap), asap warung (12 frame, tanpa garis luar karena VFX), kucing di tembok, layangan di kabel, **antena TV di atap** rumah dan ruko, pohon kelapa, klotok di sungai. Gerakannya pelan dan kontrasnya di bawah objek gameplay.

---

## 3. Karakter Pemain: Kemeja Agen

> **KEPUTUSAN (2026-10-07): Kemeja Agen dikunci sebagai base model untuk produksi.** Dipilih dari delapan varian di kanvas "Karakter Loper Koran". Varian tanpa tas selempang dipilih karena siluetnya lebih jelas.

### 3.1 Desain

> **KEPUTUSAN (2026-10-07): celana panjang jogger dan tanpa keranjang depan.** Menggantikan celana pendek dan keranjang depan di versi pertama. Pilihan celana 3/4 tidak dipakai.

- Pemain **anak muda** (sekitar 18–20 tahun), badan ramping.
- Topi putih **dipakai terbalik** dengan pita dan pet dongker, sehingga pet terbaca di tengkuk dari semua arah.
- Kemeja biru lengan pendek, dibiarkan di luar celana; kulit terang.
- **Celana panjang jogger** dongker dengan manset karet di pergelangan kaki; sneakers gelap bersol krem.
- **Tanpa tas selempang dan tanpa keranjang depan.** Koran dibawa di **tas kiri dan kanan boncengan** (merah bata).
- Sepeda hijau, rangka dua nada, tanpa spakbor, **lampu depan kecil** dan **bel kuning** di setang.
- Spesifikasi dan riwayat keputusan: project claude.ai, dokumen `claude/sprite-loper-kemeja-agen.md`.

### 3.2 Set animasi produksi

Sprite sheet ada di [`design/character/loper_agen/`](./design/character/loper_agen/), dibuat dengan `tools/loper_art` (bagian 4).

| Kecepatan | Stick | fps | Pose |
|---|---|---|---|
| santai | netral | 8 | duduk tegak |
| cepat | setengah ke atas | 10 | duduk, badan condong 50° |
| ngebut | penuh ke atas | 12 | berdiri dari sadel, condong 55°, hanya sepeda yang bergoyang ±5° |

| Arah | Menghadap di layar | Condong / setang |
|---|---|---|
| normal | kanan atas, mengikuti jalan | 0° / 0° |
| serong_kanan | kanan | 4° / 8° |
| kanan | kanan bawah, ke sisi dekat; wajah terlihat | 6° / 12° |
| serong_kiri | atas | 4° / 8° |
| kiri | kiri atas, ke sisi seberang | 6° / 12° |

- Nama animasi `kecepatan_arah`, 4 frame kayuh yang berputar **maju** (searah jarum jam dilihat dari kanan).
- Sel 46×58 px, titik pijak (tengah sepeda di tanah) di piksel (23, 46). Di Godot dengan `centered = true`: `offset = Vector2(0, -17)`.

### 3.3 Varian baju (disimpan untuk item)

Tujuh varian dari eksplorasi tetap ada di `tools/loper_art/loper.py` dan bisa dirender ulang dengan sepeda dan pose yang sama: Merah Klasik, Garis Biru, Jaket Hijau, dan Kaus Bola (dengan tas selempang), serta Polo Kuning, Batik, dan Hoodie Abu (tanpa tas selempang). Dipakai nanti sebagai aksesori atau kosmetik (GDD 11).

### 3.4 Animasi yang belum dibuat

| Animasi | Dibutuhkan di | Catatan |
|---|---|---|
| Lempar ke sisi seberang | Fase 2 | Lengan kiri, 3–4 frame, per arah |
| Lempar ke sisi dekat | Fase 2 | Lengan kanan |
| Meluncur | Fase 1 | Pedal datar, kaki diam. **Usulan sudah dibuat** (`design/character/loper_agen/rem_meluncur/`), 5 arah, belum dipasang |
| Rem | Fase 1 | Badan sedikit mundur. **Usulan sudah dibuat** (`design/character/loper_agen/rem_meluncur/`), 5 arah, belum dipasang |
| Berhenti | Fase 4 (menangkap kucing) | Satu kaki turun ke tanah |
| Tabrakan / oleng | Fase 3 | Tidak jatuh dramatis; kerusakan hanya menghambat |

### 3.5 Gambar skala besar (full body)

> **KEPUTUSAN (2026-10-08): gambar full body diganti dengan konversi gambar AI** (`konversi2`), menggantikan gambar 294×283 hasil `fullbody.py` (disimpan di `design/character/loper_agen/arsip/loper_agen_fullbody_v2.png`).

Dipakai di layar di luar rute: layar judul, halaman depan koran, lemari baju, hasil harian, gambar toko. Gambar skala besar seperti ini juga akan dijadikan **gambar adegan (cutscene)** saat jalan cerita maju dan di **adegan pembuka (start scene)** (keputusan Ronggur 2026-10-08); bentuk adegannya mengikuti `docs/STORY.md` bagian 10. File: `design/character/loper_agen/loper_agen_fullbody.png` (240×292 px, tampil ×3), dibuat dengan `tools/loper_art/fullbody/konversi2.py` dari ilustrasi AI `design/character/loper_agen/konversi2/sumber_ai.jpg`, lalu sebagian diubah dan digambar ulang (catatan lengkap di `konversi2/README.md`).

Gaya skala besar sengaja lebih kaya dari sprite rute, karena dilihat dari dekat dan tidak bergerak di atas jalan:

| | Sprite rute | Skala besar |
|---|---|---|
| Nada per warna | 3 | Palet hasil konversi (k-means 36 warna ditambah warna bagian yang digambar ulang, 70 warna) |
| Garis dalam | `#0E0A1C` | Warna gelap dari gambar sumber; garis luar siluet `#1B1226` |
| Bayangan tanah | Penanda hitam 28%, diwarnai shader | Dongker `#2E3550` 38% |
| Detail | Bentuk besar, wajah 2 mata + mulut | Lipatan kain, jahitan, wajah tiga perempat, tulisan "KORAN" di koran |

Pose: berdiri di depan sepeda, menghadap penonton. Tangan kanan mengangkat koran hari ini tinggi-tinggi dengan tulisan "KORAN" terbaca, tangan kiri di samping badan. Wajah tiga perempat, tersenyum.

**Kepala terpisah:** leher tidak digambar. Bagian belakang kerah dongker terlihat di bawah dagu, dan dagu sedikit menumpuk kerah itu. Garis dagu melengkung: tegak di bawah telinga, landai ke dagu. Ujung kerah menyambung ke bahu; kulit dada hanya terlihat di bukaan V kecil. Kepala ada di layer sendiri (`konversi2.py --layers` menyimpan `_head` dan `_body`) untuk ganti ekspresi atau animasi kecil.

**Sepeda di gambar ini:** tas boncengan terbuka berisi koran gulung, satu gir belakang tanpa derailleur, dua engkol segaris, dua kabel rem. Beda dengan 3.1: sepeda pakai spakbor dan tas boncengan hanya terlihat satu sisi. Sprite rute tidak berubah.

**Acuan untuk gambar skala besar berikutnya (2026-10-08):** gambar adegan cerita, adegan pembuka, potret ekspresi, dan baju lain di lemari mengikuti gambar full body ini supaya terlihat satu keluarga. Prinsipnya diputuskan Ronggur; rincian di bawah masih **usulan**:

- **Cara membuat:** ilustrasi (boleh dari AI) diubah jadi pixel art dengan cara yang sama (`konversi2.py` sebagai contoh: latar dibuang, warna dikelompokkan, tiap sel mengambil warna terbanyak, piksel lepas dirapikan), lalu bagian yang salah atau tidak cocok dengan brief digambar ulang dengan tangan. Kalau sumbernya gambar AI, periksa ketentuan lisensi komersial generatornya (bagian 9).
- **Palet:** warna kulit, kemeja, dongker, merah bata, hijau sepeda, dan krem koran diambil dari `loper_agen_fullbody.png`, bukan dari palet baru tiap gambar. Warna baru hanya untuk benda yang memang baru (latar, tokoh lain).
- **Garis dan bayangan:** garis luar siluet `#1B1226` 1 px, garis dalam dari warna gelap bahannya, bayangan tanah dongker `#2E3550` 38%.
- **Kepadatan piksel:** sama dengan gambar ini, tokoh setinggi sekitar 270 px dari topi sampai sol, tampil ×3. Gambar adegan yang lebih lebar memakai kepadatan yang sama, bukan diperkecil.
- **Kepala** digambar di layer sendiri seperti gambar ini, supaya ekspresi bisa diganti tanpa menggambar ulang badan.

---

## 4. Pipeline Aset

### 4.1 Pemain: `tools/loper_art`

Sprite pemain **tidak digambar per piksel**, tapi dirender dari model sederhana di kode, mirip pipeline rig → frame Brainy Dungeon:

1. Bentuk pengendara dan sepeda ditulis sebagai kapsul, bola, dan kotak di `loper.py` (koordinat lokal: maju, kanan, atas).
2. `iso.py` mengubahnya jadi titik permukaan, memproyeksikan ke isometrik 2:1, memilih nada terang/dasar/gelap dari arah cahaya, lalu menggambar garis luar `#0E0A1C` dan bayangan tanah.
3. `base.py` menyimpan pose yang dikunci (5 arah, 3 kecepatan).
4. `produce.py` merender 60 frame, menyusun sheet, menulis JSON dan SpriteFrames `.tres`, plus GIF pratinjau.

```
pip install numpy pillow
python3 tools/loper_art/produce.py --out build/loper_art
```

Keuntungannya: arah, pose, dan varian baju selalu konsisten, dan menambah animasi (misalnya lempar) cukup menambah pose. Batasannya: wajah dari depan sangat kecil dan piksel hasil render kadang perlu dirapikan. **Kalau frame dipoles manual**, simpan hasil polesan sebagai file terpisah dan catat di changelog, karena render ulang akan menimpa sheet.

### 4.2 Aset lain

- **Rumah dan kendaraan (usulan):** dirender dengan renderer yang sama (kotak, prisma atap) supaya proyeksi dan cahayanya persis sama dengan pemain, lalu dipoles manual. Mock lingkungan sudah memakai `tools/env_art` (ray cast pada primitif cembung, proyeksi dan cahaya sama dengan `iso.py`).
- **Properti kecil, NPC, hewan, VFX, ikon:** boleh digambar langsung per piksel di Aseprite atau LibreSprite dengan palet induk dan kepadatan yang sama.
- File kerja disimpan di luar `assets/` (`tools/`, `docs/design/`) supaya tidak ikut ke APK.

### 4.3 Ekspor ke Godot

- **PNG 1×** (ukuran piksel asli), satu sheet per objek atau animasi, latar transparan. Pembesaran dilakukan Godot.
- Filter tekstur **Nearest**, tanpa mipmap, mode **Lossless**.
- Sheet animasi didampingi JSON (ukuran sel, titik pijak, region frame) atau langsung SpriteFrames `.tres`.
- Bayangan tanah dipanggang dengan warna penanda `#000000` alpha 71 (bagian 2.1 no. 5). Jangan memakai warna itu untuk hal lain di sprite.

---

## 5. Mock dan Referensi

| Sumber | Isi |
|---|---|
| Kanvas "Loper Koran — Kamera dan Kontrol" | Isometrik 2:1 (mock jalan 800×360), kontrol landscape, HUD, banding arah jalan |
| Kanvas "Karakter Loper Koran" | Eksplorasi baju A–H, banding dengan Brainy Dungeon, base model 5 arah, pose kecepatan, sprite produksi |
| Kanvas "Lingkungan Loper Koran" ([`design/environment/`](./design/environment/)) | Gang perkampungan sore, perumahan empat waktu, bayangan hitam vs berwarna, palet enam distrik, detail pinggir jalan |
| Brainy Dungeon `docs/ART_DIRECTION.md` | Acuan aturan pixel art (garis, bayangan, skala bulat) |

---

## 6. Daftar Aset Detail

Kolom **M2** = dibutuhkan untuk satu hari penuh di perumahan (prototype 3–4). Kolom **M3** = vertical slice perumahan. Ukuran adalah usulan (bagian 2.2).

### 6.1 Pemain

| Aset | M2 | M3 | Catatan |
|---|---|---|---|
| Kayuh 3 kecepatan × 5 arah | ✅ | ✅ | Selesai 2026-10-07, diperbarui ke celana jogger tanpa keranjang |
| Gambar full body skala besar | ✅ | ✅ | Selesai; diganti 2026-10-08 dengan konversi gambar AI (bagian 3.5) |
| Lempar sisi seberang / dekat | ✅ | ✅ | Per arah normal dulu, arah lain menyusul |
| Meluncur, rem | ✅ | ✅ | |
| Berhenti (kaki turun) | ✅ | ✅ | Untuk menangkap kucing |
| Tabrakan / oleng | ⬜ | ✅ | |
| Lampu sepeda menyala | ⬜ | ✅ | Untuk malam |

### 6.2 Koran dan barang misi

| Aset | M2 | M3 | Catatan |
|---|---|---|---|
| Koran gulung berputar | ✅ | ✅ | ~8×6 px, 4 frame |
| Koran mendarat / terlipat | ✅ | ✅ | Di teras, rumput, kotak surat |
| Paket | ⬜ | ✅ | Misi P2 |

### 6.3 Ubin dan jalan (perumahan)

| Aset | M2 | M3 |
|---|---|---|
| Aspal + marka putus-putus | ✅ | ✅ |
| Trotoar, kerb | ✅ | ✅ |
| Rumput halaman | ✅ | ✅ |
| Jalan masuk garasi | ✅ | ✅ |
| Polisi tidur | ⬜ | ✅ |
| Persimpangan | ⬜ | ✅ |
| Genangan (hujan) | ⬜ | ✅ |

### 6.4 Rumah

| Aset | M2 | M3 | Catatan |
|---|---|---|---|
| Rumah perumahan modular: fasad (sisi seberang), belakang (sisi dekat), atap | 2 model | 3 model | Palette swap untuk variasi warna dinding dan atap |
| Teras sebagai zona sasaran | ✅ | ✅ | Harus terbaca jelas |
| Jendela menyala (malam) | ⬜ | ✅ | |
| Pos satpam + portal | ⬜ | ✅ | |

### 6.5 Properti

| Aset | M2 | M3 |
|---|---|---|
| Kotak surat (penuh/kosong) | ✅ | ✅ |
| Tong sampah | ✅ | ✅ |
| Pohon / tanaman pot | ✅ | ✅ |
| Mobil tamu parkir | ⬜ | ✅ |
| Lampu jalan | ⬜ | ✅ |
| Selang penyiram | ⬜ | ✅ |

### 6.6 Rintangan dan warga

| Aset | M2 | M3 | Catatan |
|---|---|---|---|
| Anjing penjaga: diam, lari, berhenti di batas halaman | ✅ | ✅ | Rintangan 1 di prototype 3 |
| Mobil keluar garasi + lampu mundur | ✅ | ✅ | Rintangan 2 di prototype 3 |
| Penghuni menyiram halaman | ⬜ | ✅ | |
| Tukang sayur keliling | ⬜ | ✅ | |
| Pelanggan di teras (reaksi senang / kesal) | ⬜ | ✅ | |
| Reaksi bel: ikon "!" lalu menepi | ⬜ | ✅ | Untuk warga dan hewan yang bisa minggir (GDD 5.4). Ikon di `design/bel/`; frame menepi per tokoh menyusul, awalnya cukup bergeser |

### 6.7 Misi

| Aset | M2 | M3 |
|---|---|---|
| Kucing: diam, kabur, ditangkap | ✅ | ✅ |
| Jejak kaki, mangkuk | ✅ | ✅ |
| Kilau petunjuk (2 frame) | ✅ | ✅ |
| Pencuri sandal | ⬜ | ✅ |

### 6.8 HUD dan UI

Spesifikasi di `design/DESIGN_SPEC.md`.

| Aset | M2 | M3 |
|---|---|---|
| Ikon: jeda, koin, reputasi, koran, ban, rem, rantai, misi kucing | ✅ | ✅ |
| Penanda radar (pelanggan, tip, misi, bukan pelanggan) | ✅ | ✅ |
| Stick melayang | ✅ | ✅ |
| Layar halaman depan koran | ✅ | ✅ |
| Layar hasil harian | ✅ | ✅ |
| Layar bengkel | ⬜ | ✅ |
| Tombol bel: diam, ditekan, jeda (usulan, `design/bel/`) | ⬜ | ✅ |
| Logo "Kring Kring!" untuk layar judul dan ikon aplikasi | ⬜ | ✅ |

### 6.9 VFX

| Aset | M2 | M3 |
|---|---|---|
| Debu roda | ✅ | ✅ |
| Garis kecepatan | ✅ | ✅ |
| Koran kena sasaran (bintang kecil) | ✅ | ✅ |
| Tip / koin muncul | ✅ | ✅ |
| Percikan genangan | ⬜ | ✅ |
| Efek bel: garis getar dan teks "KRING!" / "KRING KRING!" (usulan, `design/bel/`) | ⬜ | ✅ |
| Hujan | ⬜ | ✅ |

### 6.10 Detail hidup di pinggir jalan (usulan)

Gerakan kecil yang membuat lingkungan terasa ditinggali (GDD 9.4). Semuanya dekorasi: tidak masuk jalur, tidak bisa ditabrak, dan tidak memberi skor.

| Aset | M2 | M3 | Catatan |
|---|---|---|---|
| Jemuran bergoyang | ⬜ | ✅ | 2–3 frame, di samping rumah. Jemuran yang melintang jalan adalah rintangan perkampungan, bukan dekorasi |
| Ayam mematuk, lari kecil saat sepeda lewat | ⬜ | ✅ | Di halaman, selalu menjauh dari jalan |
| Kucing tidur di teras atau pagar | ⬜ | ✅ | Warna dan pose berbeda dari kucing misi |
| Asap warung atau gerobak | ⬜ | ✅ | Loop 4–6 frame dari piksel semi-transparan bertumpuk; warung di ujung blok |
| Layangan di langit | ⬜ | ✅ | Bergerak pelan, hanya di latar |
| Daun jatuh | ⬜ | ⬜ | Partikel, setelah M3 |

Aturan (usulan):

- Kontras di bawah objek gameplay (bagian 2.1 no. 7), jadi tidak pernah lebih menonjol dari kotak surat, rintangan, atau petunjuk.
- Tidak memakai kilau, gerakan ekor, atau warna penanda radar dan misi (kuning, hijau, oranye; DESIGN_SPEC 1.1), supaya tidak tertukar dengan petunjuk misi (GDD 10.3).
- Hewan latar tidak pernah bergerak ke jalur.
- Animasi 2–6 frame dengan jeda acak antar loop, supaya tidak berdenyut bersamaan.
- Maksimal sekitar 4 detail bergerak dalam satu layar, untuk menjaga fill rate di HP murah (bagian 7).

---

## 7. Spesifikasi Teknis

### Resolusi & scaling (dikunci 2026-10-09; lihat ROADMAP 4b)

- **Landscape**, orientasi dikunci.
- **Tinggi dasar 360 piksel game**, lebar mengikuti rasio layar: 640 (16:9), 780 (19,5:9), 800 (20:9). Di HP 1080p pembesarannya ×3, di 720p ×2, di 1440p ×4. Sprite pemain didesain untuk ×3.
- **Dipilih: `canvas_items` + integer scale + aspect `expand`** (alasan di ROADMAP 4b). Cara `viewport` jadi cadangan. Dua cara di Godot yang dibandingkan:
  - stretch mode `canvas_items` dengan `scale_mode = integer` dan snap piksel 2D: sprite tetap tajam, HUD dan teks dirender di resolusi layar (seperti Brainy Dungeon).
  - stretch mode `viewport` dengan base 640×360 dan aspect `expand`: piksel paling konsisten, tapi HUD dan teks ikut beresolusi rendah.
- **Zona aman**: elemen gameplay penting tetap di area 16:9 tengah; HP yang lebih lebar menampilkan jalan lebih jauh ke depan dan ke belakang.
- HUD digambar di ukuran final mengikuti `design/DESIGN_SPEC.md`.

### Tekstur & performa

- **Ukuran tekstur maksimal 2048×2048** untuk kompatibilitas GPU HP lama.
- **Gabungkan ke atlas per konteks** (pemain, distrik, UI) untuk menurunkan draw call.
- **Fill rate** adalah leher botol utama di HP murah: hindari menumpuk banyak sprite transparan besar dan efek layar penuh.
- Sprite piksel diimpor **Lossless**, filter **Nearest**, tanpa mipmap.
- Renderer **Compatibility** (usulan) untuk HP kelas bawah. Cek di Fase 0 apakah light 2D, glow, partikel, dan shader warna bayangan yang dibutuhkan jalan di renderer ini.
- **Anggaran ukuran APK: target di bawah 100 MB.**

### Penamaan file

`snake_case`, dengan awalan kategori supaya urut rapi:

```
loper_agen.png                       <- sheet pemain, satu baris per animasi
loper_agen.json / loper_agen_frames.tres
tile_perumahan_aspal.png
house_perumahan_a_fasad.png          <- model a, sisi seberang
house_perumahan_a_belakang.png       <- model a, sisi dekat
prop_kotak_surat.png
obs_anjing_sheet.png                 <- rintangan
npc_tukang_sayur_sheet.png
mission_kucing_sheet.png
vfx_debu_roda.png
ui_icon_koin.png
```

### Struktur folder

```
assets/
  sprites/
    loper/                 <- sprite pemain (dari docs/design/character/loper_agen/)
    tiles/perumahan/
    houses/perumahan/
    props/
    obstacles/
    npc/
    mission/
    vfx/
    ui/
    _placeholder/          <- aset sementara, gampang dicari saat mau diganti
  palette/
  fonts/
  LICENSES.md              <- WAJIB, lihat bagian 9
```

---

## 8. Urutan Produksi

Ikuti urutan kebutuhan, bukan urutan daftar:

**Tahap 0 — Graybox (Fase 0–1).** Kotak dan ubin polos untuk mengunci ukuran ubin, lebar jalan, dan skala. Sprite pemain final sudah ada, jadi graybox langsung dinilai terhadapnya.

**Tahap 1 — Rasa mengayuh dan melempar (Fase 1–2).** Animasi meluncur, rem, dan lempar; koran; jalan perumahan.

**Tahap 2 — Satu hari di perumahan (Fase 3–4).** Rumah modular, kotak surat, dua rintangan, kucing, HUD, layar koran dan hasil.

**Tahap 3 — Hidup dan modern (Fase 6–7).** Lighting dan waktu dengan bayangan berwarna, VFX, warga, detail hidup pinggir jalan (6.10), properti tambahan, bengkel.

**Tahap 4 — Distrik berikutnya.** Palet dan modul baru per distrik.

**Tahap 5 — Aset toko dan materi rilis.** Jangan ditinggal sampai minggu terakhir.

---

## 9. Sumber Aset & Lisensi

- **Pemain, rumah, dan rintangan dibuat sendiri** (bagian 4), karena harus konsisten dengan proyeksi dan palet.
- **UI, ikon, dan efek suara** boleh memakai set CC0 (misalnya Kenney.nl) kalau cocok dengan gaya. Lisensi aset dari OpenGameArt dan itch.io bervariasi per aset, jadi selalu periksa.
- **AI image generation** lemah untuk sprite yang harus konsisten di banyak arah dan frame. Kalau dipakai, hanya untuk konsep, latar statis, atau gambar skala besar yang diam (full body dan gambar adegan, bagian 3.5; diubah jadi pixel art dulu), dan periksa ketentuan lisensi komersialnya.

### Wajib: catat semua lisensi

Buat `assets/LICENSES.md` sejak aset pihak ketiga pertama masuk: nama file, sumber, jenis lisensi, tautan, dan kewajiban atribusi. Menambah satu baris tiap kali mengunduh aset jauh lebih murah daripada mencari asal-usul ratusan file setahun kemudian.

---

## 10. Perkiraan Jumlah Aset (kasar)

| Kelompok | M3 (perumahan) | Penuh (6 distrik) |
|---|---|---|
| Pemain (sheet animasi) | ~8 | ~10 + varian baju |
| Koran dan barang misi | ~6 | ~15 |
| Ubin | ~20 | ~110 |
| Rumah dan bangunan (modular) | ~12 | ~70 |
| Properti | ~15 | ~80 |
| Rintangan dan warga | ~10 | ~60 |
| Misi | ~6 | ~40 |
| HUD, ikon, layar | ~30 | ~45 |
| VFX | ~10 | ~20 |
| Detail hidup pinggir jalan | ~5 | ~30 |
| **Total** | **~122** | **~480** |

Jumlah aset adalah penyebab paling umum game solo mangkrak. Penawarnya sudah dibangun ke rencana: pemain dirender dari model, rumah modular, variasi lewat palette swap, dan distrik baru hanya dibuat setelah perumahan terbukti seru.

---

## 11. Keputusan yang Perlu Diambil

- **Ukuran ubin (64×32)**: dikunci setelah graybox Fase 1. Skala piksel sudah dikunci ×3 (2026-10-09).
- **Stretch mode dan resolusi dasar** (bagian 7): sudah dipilih 2026-10-09, diverifikasi di desktop pada run 0A (hasil di ROADMAP 4b); uji di HP menunggu.
- **Palet induk** (bagian 2.4): dikunci setelah aset gelombang 1.
- **Warna bayangan per waktu dan distrik** (bagian 2.5): dikunci bersama palet induk, setelah shader-nya dicek di Fase 0.
- **Cara menampilkan rumah di sisi dekat**, yang hanya terlihat belakangnya.
- **Font HUD**: mock memakai Lexend + Lilita One (sama dengan Brainy Dungeon). Kunci atau pilih identitas sendiri.
- **Apakah sprite pemain dipoles manual** sebelum rilis, terutama wajah dari arah depan.

---

## Changelog Keputusan

- **2026-10-09** — **Judul game "Kring Kring!" dan bel sebagai ciri khas** (GDD 5.4). Aset bel ditambahkan sebagai usulan: tombol bel HUD tiga keadaan, efek garis getar dan teks "KRING!" / "KRING KRING!" di atas setang, dan ikon "!" untuk warga atau hewan yang menepi (`design/bel/`, `tools/ui_art/bel.py`). Logo "Kring Kring!" masuk daftar aset. Animasi pemain tidak berubah: bel di sprite rute hanya 1–2 piksel, jadi efeknya cukup lewat VFX.
- **2026-10-08** — **Gambar full body diganti dengan konversi gambar AI** (bagian 3.5). `loper_agen_fullbody.png` sekarang 240×292 px dari `konversi2.py` (sumber di `design/character/loper_agen/konversi2/`), menggantikan gambar 294×283 lima nada dari `fullbody.py`. Kepala terpisah tanpa leher dengan dagu sedikit menumpuk kerah belakang, koran diangkat tinggi, tas boncengan terbuka berisi koran, satu gir belakang, dua engkol segaris, dua kabel rem. Spakbor dan tas satu sisi berbeda dari 3.1, hanya di gambar ini. Pertanyaan terbuka soal gaya lima nada untuk skala besar ditutup. Gambar ini jadi acuan gambar skala besar berikutnya, dan gambar skala besar seperti ini akan dipakai sebagai gambar adegan (cutscene) saat jalan cerita maju dan di adegan pembuka.
- **2026-10-07** — **Usulan lingkungan** (bagian 2.6): bayangan berwarna per waktu, pemain setengah color grading, penampang jalan per distrik (lajur sepeda di perumahan, ruko 2 lajur, gang 2 ubin, talud sungai miring), palet enam distrik, detail pinggir jalan dan antena TV, tiga bentuk rumah dan tiga jenis pohon perumahan, model sedan/angkot/bus kecil. Mock di `design/environment/`, renderer `tools/env_art`. Belum dikunci.
- **2026-10-07** — **Gambar full body: kepala terpisah tanpa leher, koran dijepit di samping wajah** (bagian 3.5). Kepala melayang 2 px di atas kerah; ukuran gambar menjadi 294×283 px. Sprite rute tidak berubah.
- **2026-10-07** — **Celana panjang jogger dan tanpa keranjang depan** (bagian 3.1). Sprite produksi dirender ulang dengan ukuran sel dan titik pijak yang sama (46×58, 23,46), jadi kode dan SpriteFrames tidak berubah. Ditambah lampu depan dan bel. Gambar full body skala besar dibuat dengan gaya lima nada (bagian 3.5); pilihan celana 3/4 tidak dipakai.
- **2026-10-07** — **Bayangan berwarna dan detail hidup pinggir jalan** dimasukkan sebagai usulan. Bayangan tanah tidak lagi hitam pekat: warnanya mengikuti distrik dan waktu lewat shader yang mengganti warna penanda (bagian 2.1 no. 5, 2.3, 2.5). Jemuran, ayam, kucing, asap warung, dan layangan masuk daftar aset sebagai dekorasi (bagian 6.10).
- **2026-10-07** — **Sprite produksi Kemeja Agen** (bagian 3.2): 15 animasi kayuh (3 kecepatan × 5 arah, 4 frame maju), sel 46×58, titik pijak (23, 46), SpriteFrames dicek memuat di Godot 4.3. Saat ngebut hanya sepeda yang bergoyang ±5°; badan pengendara stabil supaya kepala tidak bergetar di 12 fps.
- **2026-10-07** — **Audit sprite sebelum produksi**: roda depan tidak lagi terpotong saat setang belok (seluruh rakitan depan berputar bersama), condong dan setang saat belok dikecilkan, wajah dari depan memakai dua mata dan mulut, topi diberi pita dan pet dongker supaya terbaca terbalik, bahu dilebarkan supaya lengan terlihat dari belakang, rangka sepeda dua nada dan lebih tipis, pose ngebut dibuat lebih tegak dengan sadel terlihat.
- **2026-10-07** — **Kemeja Agen jadi base model** (bagian 3), tanpa tas selempang. Lima arah sesuai stick dan tiga pose kecepatan disetujui. Varian baju lain disimpan untuk item (bagian 3.3).
- **2026-10-06** — **Gaya pixel art disamakan dengan Brainy Dungeon** setelah dibandingkan di papan Banding: garis luar `#0E0A1C`, bayangan hitam 28%, warna dasar dominan, kepala lebih besar. Arah kayuh dibetulkan jadi maju.
- **2026-10-06** — **Pixel art isometrik** untuk karakter dan dunia (bagian 2), menggantikan eksplorasi karakter bergaya flat. Kepala dan topi harus bulat utuh.
- **2026-10-05** — **Isometrik 2:1 terkunci, jalan ke kanan atas**, sepeda di sepertiga kiri layar, kamera melihat sisi kanan sepeda, cahaya dari kiri atas dengan pintu dan jendela kontras, layar landscape.
