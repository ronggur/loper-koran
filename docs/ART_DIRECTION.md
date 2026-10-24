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

- **Proyeksi 2:1**: satu langkah dunia di sumbu x menggeser layar (+1, +½) piksel, di sumbu y (−1, +½), dan tinggi z (0, −1). Ubin belah ketupat **64×32 px (dikunci 2026-10-14)** = persegi dunia 32×32 unit.
- **Arah jalan** naik ke kanan atas. Sepeda di **sepertiga kiri layar**, jadi pandangan ke depan jatuh di area yang bebas dari jempol.
- **Kamera melihat sisi kanan sepeda** (rantai dan gir) dan punggung pengendara.
- **Sisi seberang** (kiri pelempar) ada di kiri atas jalan: fasad, pintu, dan kotak surat terlihat. **Sisi dekat** (kanan pelempar) ada di kanan bawah jalan: rumah hanya terlihat belakangnya. Rumah sisi dekat ditampilkan dengan tembok atau pagar belakang rendah di kaki kavling dengan rumah penuh di belakangnya (pendekatan 2 spike run 3C; keputusan pemilik 2026-10-17); rincian di bagian 11.
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
  - **Placeholder Fase 1 (usulan, run fase1b-umpan-balik 2026-10-14):** debu roda dan garis kecepatan digambar dari kode (`scripts/entities/pancaran_piksel.gd`, `umpan_balik_sepeda.gd`), bukan `GPUParticles2D`/`CPUParticles2D` (posisi partikel CPUParticles2D tidak dibulatkan ke piksel game sehingga jatuh di antara blok ×3). Debu: kotak 1–2 px `TEXT_2` (krem, alpha 85%) dari roda belakang, melaju ke belakang sejajar jalan 2:1, di **ruang dunia** (usulan run fase1c-perapian, QA-006): sesudah muncul debu diam di jalan, jadi membentuk jejak titik di belakang sepeda saat ngebut dan tertinggal di sisi lama saat pindah sisi; tetap digambar di belakang sprite pemain. Garis kecepatan tetap di ruang lokal sepeda (efek kamera). Garis kecepatan: garis bertangga 2:1 (anak tangga 2×1 px) `TEXT` alpha 70% di sekitar pengendara. Tidak ada token warna baru (memakai `TEXT_2` dan `TEXT` dari `palette.gd`). Laju dari kecepatan sebenarnya (`BALANCING.md` 2), batas 24 debu + 6 garis. `vfx_debu_roda.png` (bagian 7) menggantikannya nanti.
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
| Perumahan | **Di game (`config.gd`, K-3 run fase5a): aspal 2 ubin, trotoar 1 ubin per sisi, lalu rumput; mock 3 ubin di bawah tidak berlaku.** Aspal 3 ubin (dua lajur mobil), kerb pemisah, **lajur sepeda hijau ¾ ubin di tiap sisi** menggantikan trotoar, tepi putus-putus di depan jalan masuk garasi. Loper di lajur sepeda kiri, di samping deretan kotak surat. Halaman depan dipersempit supaya rumah di kedua sisi tetap terlihat. |
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
- **Melambat** (usulan, 2026-10-09): `melambat_<arah>`, 5 animasi, gambar sama persis dengan santai, 4 fps (santai 8 fps), dipakai saat stick ditarik ke bawah. **Lempar** (usulan, 2026-10-09): `lempar_<sisi>_<kecepatan>_<arah>`, 18 animasi (kiri = sisi seberang, kanan = sisi dekat; santai, cepat, ngebut; normal dan dua serong), 4 frame, 12 fps, sekali putar, koran lepas di frame 2; arah 90° belum ada gambarnya. Keduanya sudah dipasang di jalan uji (`assets/sprites/loper/loper_agen_frames.tres`, 38 animasi gabungan, dibangun `tools/loper_art/bangun_frames.py`) tetapi masih usulan sampai dinilai di HP.

### 3.3 Varian baju (disimpan untuk item)

Tujuh varian dari eksplorasi tetap ada di `tools/loper_art/loper.py` dan bisa dirender ulang dengan sepeda dan pose yang sama: Merah Klasik, Garis Biru, Jaket Hijau, dan Kaus Bola (dengan tas selempang), serta Polo Kuning, Batik, dan Hoodie Abu (tanpa tas selempang). Dipakai nanti sebagai aksesori atau kosmetik (GDD 11).

### 3.4 Animasi yang belum dibuat

| Animasi | Dibutuhkan di | Catatan |
|---|---|---|
| Lempar ke sisi seberang | Fase 2 | Lengan kiri, 4 frame, arah normal dan dua serong sudah ada sebagai usulan dan dipakai di jalan uji sejak 2026-10-09 (3.2); arah 90° belum |
| Lempar ke sisi dekat | Fase 2 | Lengan kanan, sama |
| Meluncur | Fase 1 | Pedal datar, kaki diam. **Usulan, dipasang di jalan uji sejak 2026-10-13** (`design/character/loper_agen/rem_meluncur/`, `meluncur_<arah>`, 5 arah, 4 fps): dipakai selama stick ke bawah dan kecepatan masih di atas tujuan (BALANCING 2). Pergeseran 1 px dan fps masih tebakan, dinilai di HP |
| Rem | Fase 1 | Badan sedikit mundur. **Usulan, dipasang di jalan uji sejak 2026-10-13** (`rem_<arah>`, 5 arah, 8 fps): dipakai selama rem aktif dan sepeda masih bergerak; sejak Fase 5C saat sudah berhenti diganti pose berhenti |
| Berhenti | Fase 4 (menangkap kucing) | **Usulan Fase 5C, dipasang 2026-10-22** (`design/character/loper_agen/berhenti/`, `berhenti_<arah>`, 5 arah, sel 46×58, 2 frame 3 fps berulang): kaki **kanan** turun (sisi kamera, supaya terlihat; keputusan pemilik 2026-10-22), sepeda condong 7° ke kanan, badan atas turun 1 px bergantian. Dipakai saat rem aktif dan kecepatan 0 (toleransi pose `POSE_MELUNCUR_TOLERANSI_UD`). **Run 5C (2026-10-22):** tampil di skenario tangkap kucing nyata bila pemain menahan rem sampai diam (dites); syarat tangkap (`MISI_TANGKAP_KECEPATAN_MAKS_UD`, tidak diubah) juga bisa terpenuhi dengan rem diketuk tanpa pose berhenti (temuan Nit A-F3, `docs/loop/20261022-fase5c-animasi-simpang/LOG.md`). Dinilai di HP |
| Tabrakan = jatuh | Fase 3 | **Dipakai sejak 2026-10-17** (keputusan pemilik: tabrakan membuat pemain jatuh lalu tetap bisa melanjutkan; menggantikan "oleng, tidak jatuh dramatis"). Sheet usulan `design/character/loper_agen/jatuh/` (`jatuh.py`, sel 114×68, titik pijak 57,51, offset sama dengan kayuh): `jatuh_normal` 4 frame 10 fps sekali lalu `terjerembab_normal` 2 frame 3 fps berulang, masuk `loper_agen_frames.tres` lewat `bangun_frames.py`. **Fase 5C (usulan, 2026-10-22):** lima arah dirender `fase5c.py` dari pose yang sama (yaw arah; serong_kiri tubuh diputar 30° di tanah supaya tengkurap terbaca), sel jadi **140×88, titik pijak (70, 61)** (114×68 tidak muat untuk serong_kanan, kanan, serong_kiri; arah normal piksel sama, dipotong ulang); `jatuh_<arah>` dan `terjerembab_<arah>` memakai arah saat menabrak; **bangkit** `bangkit_<arah>` (6 frame 10 fps: bertumpu tangan, berlutut memungut topi, berdiri kembali ke sepeda, meraih setang, menegakkan sepeda, kayuh santai frame 0) diputar di 0,6 detik terakhir jatuh 1,2 detik, jadi lama jatuh tidak berubah dan terjerembab tinggal 0,2 detik; koran berserakan hilang di frame terakhir. **Diverifikasi run 5C (2026-10-22, usulan):** titik pijak tidak melompat di seluruh urutan kayuh → jatuh → terjerembab → bangkit → kayuh lima arah (dites dari JSON sheet); dua cacat dipasang diperbaiki di kode tampilan tanpa menggambar ulang: kayuh sesudah bangun dimulai frame 0 (dulu mewarisi frame bangkit, lompat ke frame 3) dan arah jatuh ditahan selama jatuh (dulu kembali ke `normal` sesudah langkah pertama karena sepeda diam). Sel jatuh 140×88 lebih lebar dari kotak penutup dekor, jadi dekor bisa menutup sebagian pose jatuh tanpa memudar (I2-F3, DEFERRED; pose berkendara tidak terpengaruh). Dinilai di HP |

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
| Tabrakan = jatuh (jatuh, terjerembab, bangkit) | ✅ | ✅ | Arah `normal` dipakai sejak 2026-10-17 untuk semua arah; lima arah dan bangkit dipasang Fase 5C dan diverifikasi run 5C (2026-10-22, usulan, 3.4) |
| Lampu sepeda menyala | ⬜ | ✅ | Untuk malam |

### 6.2 Koran dan barang misi

| Aset | M2 | M3 | Catatan |
|---|---|---|---|
| Koran gulung berputar | ✅ | ✅ | ~8×6 px, 4 frame |
| Koran mendarat / terlipat | ✅ | ✅ | Di teras, rumput, kotak surat |
| Paket | ⬜ | ✅ | Misi P2 |

**Placeholder dari kode (usulan, run fase2a-lemparan 2026-10-14):** belum ada sheet koran di repo, jadi koran, bayangannya, penanda kena/meleset, elips garis bidik, ikon koran HUD, dan zona sasaran jalan uji digambar dari pola piksel di `scripts/systems/pola_piksel.gd` (baris teks berisi peran warna, bukan hex) oleh `scripts/entities/koran_gambar.gd`, `zona_gambar.gd`, dan `scripts/ui/garis_bidik.gd`, `deret_koran.gd`. Semua per piksel game (persegi bilangan bulat, tajam di ×3, lolos `tools/cek_blok_piksel.py 3`) dan hanya warna `Palette` (`OUTLINE`, `TEXT`, `TEXT_2`, `OK`, `FAIL`, `ACCENT`, `UI_PANEL_RAISED`, `RADAR_BUKAN`). Koran gulung 8×6, 4 langkah putar (mendatar, serong naik, tegak, serong turun) di 12 fps, di atas objek dunia; bayangan elips `OUTLINE` alpha 85% di lapisan tanah, 10 px di tanah mengecil 2 px per ubin tinggi sampai 6 px (dulu alpha 50%, 8 sampai 4 px; dinaikkan run fase2a-lemparan iterasi 2 karena nyaris tak terlihat di aspal, kontras di aspal graybox sekitar 3,2:1; usulan, dinilai di HP); koran yang mendarat tergeletak (frame mendatar) selama penandanya tampil. Zona jalan uji di bawah objek dunia: halaman bergaris tepi `TEXT` 70%, teras isi `UI_PANEL_RAISED`, strip jendela `TEXT_2` di kaki fasad, kotak surat datar sisi dekat `ACCENT`, rumah bukan pelanggan dengan garis dan teras `RADAR_BUKAN` plus tanda lingkaran bergaris miring di halaman. Sisi dekat hanya kavling datar (cara menampilkan rumah sisi dekat tetap terbuka, bagian 11). Sheet koran dari renderer menggantikannya nanti.

**Terpasang di rute (run fase5a-pasang-aset-gelombang1 bagian B, 2026-10-21; usulan sampai dinilai di HP, SETUP_ANDROID 8.12):** `prop_koran_{putar,bayangan,teras,rumput,kotak_surat,terlipat}` disalin `tools/env_art/gelombang1/render.py --salin` ke `assets/sprites/props/` dan digambar `KoranGambar` mode sprite (`pakai_sprite` di `rute.tscn`; jalan uji tetap pola kode). Koran putar di lapisan udara (pusat gambar sama dengan pola 8x6 lama, selisih <= 1 px); bayangan di lapisan tanah dengan frame menurut tinggi lewat `SpriteKoran.frame_bayangan` (frame yang lebarnya terdekat dengan `KoranLempar.lebar_bayangan_px`, 10/8/6 px), warna penanda alpha 28% bawaan sprite (keterbacaan di aspal dinilai di HP; keraguan dicatat di LOG); koran tergeletak menurut permukaan titik mendarat (`PermukaanKoran`: kotak surat pelanggan seberang = bertumpu di kotak surat dan digambar di lapisan udara karena kotak surat ada di lapisan objek, halaman = rumput, teras dan jendela dan kotak yang tidak digambar = teras, tanpa zona = rumput di kolom rumput selain itu teras); `prop_koran_terlipat` di tengah zona teras setiap rumah pelanggan yang terantar di `SkorRute` (hanya dibaca), anak induk Y-sort rumah sehingga digambar di atas sprite rumah. Penanda kena/meleset, garis bidik, elips, dan ikon HUD tetap dari kode. **Usulan gelombang 1 (2026-10-20, `tools/env_art/gelombang1/`):** `prop_koran_putar` (sel 10×10, 4 frame, 12 fps, pijak = pusat putar; gulungan krem kertas tiga nada dengan karet merah bata di tengah, sama dengan isi tas sepeda), `prop_koran_bayangan` (12×6, tiga ukuran 10/8/6 px dipilih dari tinggi, warna penanda), `prop_koran_teras` dan `prop_koran_rumput` (12×10, gulungan sejajar jalan; versi rumput ditutup dua jumput rumput), `prop_koran_kotak_surat` (8×7, tumpangan di atas kotak surat: pijak kotak surat = piksel (−3, 19) sel ini), `prop_koran_terlipat` (14×10, pose "terantar", lembar 6×9 unit setebal 1, kepala berita dongker). Mock `design/environment/gelombang1/lembar_koran_x5.png`.

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

**Terpasang di rute (run fase5a, bagian A, 2026-10-21; usulan sampai dinilai di HP):** enam ubin kolom `tile_perumahan_{rumput_seberang,trotoar_seberang,aspal_seberang,aspal_dekat,trotoar_dekat,rumput_dekat}` plus `tile_perumahan_rumput_1` (rumput polos untuk kolom rumput di luar kolom pertama, pengecualian D-2 karena `rumput_seberang` membawa tepi kerb luar yang akan berulang jadi pita) di `assets/sprites/tiles/perumahan/`, dipasang `TanahDaur` lewat `JalanDaur.kolom_di` (batas kolom di |x| = 1 dan 2 dihitung ke kolom luar, sama dengan `jenis_di`); `rute.tscn` tidak lagi memakai `tile_graybox_*` (jalan uji, graybox, spike, dan `cek_render` tetap graybox). Lebar jalan tetap 2 ubin aspal (K-3). **Usulan gelombang 1 (2026-10-20, `tools/env_art/gelombang1/`, belum dipasang):** `tile_perumahan_polisi_tidur`, `tile_perumahan_zebra` (persimpangan, dipakai di kedua lajur aspal; jalan samping memakai aspal polos), `tile_perumahan_genangan`, masing-masing 64×32 pijak (32, 16) dengan alas aspal polos dari `ubin_perumahan.py`, tanpa garis luar. Polisi tidur belang krem/logam gelap (bukan kuning-hitam seperti `prop_polisi_tidur` di `ubin_perumahan.py`, supaya kuning tetap berarti sasaran; salah satunya perlu dipilih). Ubin ujung kerb dan sudut trotoar mulut simpang belum ada (dipasang run 5C, lihat di bawah). Mock `design/environment/gelombang1/ubin_potongan_x3.png`.

**Terpasang di rute (run fase5b bagian C, 2026-10-21; usulan sampai dinilai di HP, SETUP_ANDROID 8.13):** enam ubin tambahan di `assets/sprites/tiles/perumahan/` (D-1, D-7), menukar tekstur satu sel kolomnya tanpa mengubah posisi atau jumlah sel (`JalanDaur.sel_tanah`, `kolom_di`, `jenis_di` tidak disentuh), dipilih `UbinKhusus` per baris maju mutlak dari awal rute dan dipasang `TanahDaur`: `trotoar_seberang_masuk` dan `rumput_seberang_masuk` (jalan masuk garasi beton di baris yang menutup titik rumah tiap mobil garasi sisi seberang, kolom trotoar dan rumput pertama saja; mobil sisi `dekat` tidak ada di data dan `*_dekat_masuk` tidak dipasang), `trotoar_seberang_simbol` dan `trotoar_dekat_simbol` (simbol sepeda tiap 12 baris di kedua trotoar, bergeser 6 baris, tidak di baris jalan masuk), dan `rumput_2` serta `rumput_3` (variasi rumput polos di kolom rumput luar, `rumput_1` tetap dominan, pilihan dari hash FNV-1a atas kolom dan baris, kolom rumput pertama tidak pernah diganti). **`aspal_1..3` TIDAK dipasang (D-4):** ketiganya polos tanpa garis tepi kerb sedangkan `aspal_seberang`/`aspal_dekat` membawa garis tepi, jadi menukarnya memutus garis; memasang variasi aspal butuh varian kolom dari renderer (usulan 5C atau M3). Keterbatasan yang diketahui: ubin `*_masuk` disambung ke tetangga biasa tanpa ubin ujung kerb, sehingga 22 piksel di baris tetangga (maju + 1, di sekitar kedua kerb) berbeda dari adegan renderer (diukur `tools/tests_cek/uji_aset_pasang_5b.py`); ubin ujung kerb ditunda ke 5C (ditutup run 5C, lihat di bawah). Polisi tidur, zebra, dan genangan tetap belum dipasang.

**Terpasang di rute (run fase5c-animasi-simpang, 2026-10-22; usulan sampai dinilai di HP, SETUP_ANDROID 8.14):** (1) **Ujung kerb jalan masuk** (C-F1 run 5B): `tile_perumahan_trotoar_seberang_masuk_ujung` dan `tile_perumahan_rumput_seberang_masuk_ujung`, dipasang `UbinKhusus.Ubin.UJUNG` di baris tetangga jalan masuk sisi seberang (maju + 1, `RUTE_UJUNG_KERB_BARIS_RELATIF`; dihitung renderer sebagai satu-satunya sel yang berbeda dari jalan lurus), jadi susunan jalan masuk di game = adegan renderer 0 piksel beda (dulu 22). (2) **Simpang T hiasan** (keputusan pemilik 2026-10-22, ROUTE_DESIGN 8): jalan samping ke sisi `dekat` atau `seberang` dari bidang `simpang` `{pos, sisi}` di data segmen (DATA_SCHEMA 3), tanpa lalu lintas, rintangan, atau sasaran. 18 ubin simpang sisi dekat dan 16 sisi seberang (`tile_perumahan_simpang_<sisi>_<kolom>_<baris>`, baris `depan_2`, `depan_1`, `mulut_1`, `mulut_2`, `belakang_1`) dari `ubin_perumahan.py` `ekspor_simpang`; hanya ubin yang berbeda dari jalan lurus yang disalin (`--salin`, `SIMPANG_SISI_DIPASANG`), ubin aspal jalan utama yang sama tidak. Mulut 2 ubin, pita baris yang diganti 5 ubin (`RUTE_SIMPANG_PITA_BARIS`), lengan jalan samping berulang ke semua kolom rumput luar sampai tepi layar (`UbinKhusus.sel_simpang`); sisi lain jalan tetap lurus, tembok dan rumah dekat tidak ada di pita. Susunan di game = adegan renderer piksel-identik (`tools/tests_cek/uji_aset_simpang.py`, `tests/tes_simpang.gd`). Gerak, zona, dan lemparan tidak berubah. Keraguan untuk HP: simpang terbaca sebagai jalan samping, bukan jalur yang harus dibelok; mobil garasi seberang yang mundur dekat mulut simpang dekat di `per_tengah_05` bisa terbaca seperti keluar dari simpang (D-F2); simpang dekat `per_tengah_05` ada di setiap rute (D-F3).

### 6.4 Rumah

| Aset | M2 | M3 | Catatan |
|---|---|---|---|
| Rumah perumahan modular: fasad (sisi seberang), belakang (sisi dekat), atap | 2 model | 3 model | Palette swap untuk variasi warna dinding dan atap |
| Teras sebagai zona sasaran | ✅ | ✅ | Harus terbaca jelas |
| Jendela menyala (malam) | ⬜ | ✅ | |
| Pos satpam + portal | ⬜ | ✅ | |

**Usulan dirender (2026-10-15, `tools/env_art/fase3.py`, belum dipasang di game):** rumah pelanggan dan bukan pelanggan untuk dua sisi jalan di `assets/sprites/houses/perumahan/` (PNG 1× + JSON, titik pijak tengah tapak), mock di `design/environment/fase3_*.png`.

- **Sisi seberang:** tiga bentuk dari `perumahan.py` (limasan, pelana, sayap). Pelanggan: dinding dan genteng berwarna (palette swap), teras krem dengan keset merah dan pot, jendela kaca; sprite rumah seberang tidak membawa kotak surat (sasaran digambar scene di zona kotak surat, run 3A QA-005). Bukan pelanggan: dinding abu-abu krem, genteng abu-abu, jendela bertirai, pintu kayu gelap, teras abu-abu tanpa keset, tanpa kotak surat. Pembedanya juga terang-gelap dan benda, bukan hanya hue.
- **Sisi dekat (terlihat belakang):** tiga atap dari `house_near` (limasan, pelana dengan bubungan tegak lurus jalan, pelana dengan bubungan sejajar jalan), kanopi seng di pintu belakang, halaman belakang berisi toren air dan jemuran. Rumah mundur 22 unit (sekitar ¾ ubin) dari posisi `perumahan.py` supaya kotak surat pelanggan di tepi lajur tidak tertutup atap. Teras sisi dekat tidak terlihat, jadi sasarannya kotak surat (bagian 11). **Diganti Run 5D (2026-10-22, lihat paragraf "Rumah dekat Run 5D" di bawah): rumah dekat didesain ulang dengan teras menjorok, tanpa kotak surat terpanggang, mundur 0,5 ubin dari tepi kavling; teras dekat kini terbaca dari samping dan menjadi sasaran.**
- Antena TV ikut dirender bersama rumah (6.5).
- **Kotak surat sasaran (usulan, run art-kotak-surat 2026-10-16):** `assets/sprites/props/prop_kotak_surat.png` + `.json` dari `tools/env_art/fase3.py`, sprite tunggal 30×39 px skala 1×, titik pijak = kaki tiang (10, 26). Bentuk `lib.kotak_surat` (tiang `metal_dk` dan badan dengan celah surat, bentuk yang disukai pemilik dari teras sprite rumah lama), berwarna **oranye placeholder sasaran** (tiga nada sama dengan kubus graybox: `#FFE08A` atas, `#FFC94A` samping, `#E98E3F` fasad). Dipasang di scene rute menggantikan kubus graybox, di pusat zona kotak surat; jalan uji tetap kubus graybox. Warna dan gambar final menunggu Fase 5. **Keputusan pemilik 2026-10-22:** persegi area kotak surat di tanah (isi oranye tipis dan garis tepi, `AreaKotakGambar`, tindak lanjut uji HP 2026-10-16) dihapus dari scene rute karena membuat pemain mengira hanya area itu yang dinilai; sprite kotak surat oranye sendiri yang menandai sasaran. Zona penilaian tidak berubah (BALANCING 5).
- **Kotak surat bukan pelanggan (usulan, keputusan pemilik 2026-10-17):** `assets/sprites/props/prop_kotak_surat_bukan.png` + `.json` dari `tools/env_art/fase3.py` (`kotak_surat_bukan`), sprite tunggal 28×33 px skala 1×, titik pijak = kaki tiang (9, 20). Rumah **bukan pelanggan sisi seberang** juga punya kotak surat supaya deretan rumah terasa hidup, tetapi jelas **bukan sasaran**: abu-abu logam palet induk (`#969AA0` atas = `RADAR_BUKAN`, `#67636D` samping), jauh lebih redup dari oranye, dan bentuknya juga beda (tiang 8 lawan 12, badan lebih kecil, tanpa celah surat; puncaknya 7 px lebih rendah: 16 lawan 23 px di atas titik pijak), jadi pembedanya bukan hanya warna. Digambar scene rute di titik yang sama dengan kotak surat pelanggan, **tanpa** area oranye di tanah (sejak 2026-10-22 kotak surat pelanggan juga tanpa area, lihat butir di atas); penilaian (`BUKAN_PELANGGAN`) dan mode bantu tidak berubah. Sisi dekat tetap tanpa kotak surat (K-5 tembok rendah untuk Bab 2, bukan perumahan).
- **Tembok belakang rendah sisi dekat (usulan gelombang 1, 2026-10-20, `tools/env_art/gelombang1/tembok_ubin.py`):** modul 1 ubin, tinggi 14 unit (badan 13 + tutup), tebal 4, diawali tiang 6×4 setinggi 17 yang menutup sambungan; empat varian `house_tembok_polos` (plester krem kertas), `house_tembok_bata` (bata ekspos merah bata), `house_tembok_besi` (tembok pendek 5 unit + jeruji logam gelap), `house_tembok_pot` (plester hijau muda dengan dua pot semak), plus `house_tembok_tiang` penutup ujung. Sel 46×46, pijak (41, 25) = garis tengah tembok di awal modul; modul berikut digeser (−32, +16) px. Sisi yang menghadap kamera memakai nada dasar, bukan gelap, supaya tidak jadi pita gelap di tepi bawah layar (sedikit melonggarkan 2.1). Komposisi repo memakai geometri spike run 3C: tembok berpusat x = 3,125 ubin, rumah dekat mundur 1,25 ubin. Mock `design/environment/gelombang1/sisi_dekat_siang_x3.png`, `tembok_rantai_x3.png`. **Tidak lagi terpasang sejak Run 5D (keputusan pemilik 2026-10-22: sisi dekat terlihat berbeda dari sisi jauh): lima PNG `house_tembok_*` dihapus dari `assets/`, renderer tetap di `gelombang1/` dan papan, tidak disalin.**
- **Rumah dekat Run 5D (usulan, dinilai di HP, `SETUP_ANDROID.md` 8.16; `tools/env_art/fase3.py`, `house_near_teras`):** tiga jenis dekat (`dekat_limasan`, `dekat_pelana_lintang`, `dekat_pelana_sejajar`), dua varian per jenis (pelanggan berwarna dan bukan pelanggan, keduanya **tanpa kotak surat terpanggang**; kotak surat dekat = sprite terpisah `prop_kotak_surat`/`prop_kotak_surat_bukan` di lateral +2,125). Badan rumah mundur di belakang tapak, atap sisi jalan lebih rendah (limasan 52, pelana lintang jadi perisai di ujung jalan, pelana sejajar 50), dan **teras menjorok ke arah jalan** di ujung maju kecil: lantai, tiga tiang, atap sandar rendah 27 ke 21, lampu, pintu samping; keset dan pot di pelanggan. Aturan bentuk: setiap titik rumah dengan lateral L dan tinggi H memenuhi L - H >= sekitar 2,8 ubin, jadi sinar kamera dari zona kotak surat dan trotoar dekat tidak kena rumah. JSON memuat `teras_ubin`, `penutup_ubin`, dan `penutup_tinggi_ubin` (kotak penutup = sprite nyata). Halaman dekat adalah rumput terbuka (ubin rumput yang ada), tanpa tembok dan tanpa jalan setapak. Palet induk tidak dikunci. Mock: `design/environment/fase3_rumah_dekat_banding.png` (lama atas, baru bawah, x2) dan `fase3_layar_dekat_5d.png`. Terukur (oracle piksel): kotak surat dekat 0% tertimpa, zona kotak surat 2,58%, pemain di lajur dan trotoar dekat 0%, jadi pudar tidak dipakai.
- **Tembok terpasang (run fase5b bagian B1, 2026-10-21; usulan sampai uji HP Bab 2):** `TembokDekat` memasang tiap rumah sisi `dekat` sebagai tiga modul `house_tembok_<varian>` di `maju` m, m+1, m+2 dan satu `house_tembok_tiang` di m (sprite modul membentang ke arah mundur dari pijaknya, jadi tiang di awal modul menutup sambungan tanpa celah; D-3 menulis m+3 sebelum arah sprite diukur, putusan P-2). Varian (`polos`, `bata`, `besi`, `pot`) dipilih dari id rumah (`<id_segmen>@<pos>`) lewat FNV-1a 32 bit mod 4, satu varian untuk seluruh rumah. Tembok berpusat di lateral 3,125 ubin dengan tebal 4 unit (0,125 ubin), jadi sisi jalannya tepat di 3,0 = `RUTE_RUMAH_DEKAT_X_UBIN` (selisih pusat 0,125 = setengah tebal); rumah dekat DIGAMBAR 1,25 ubin lebih jauh dari jalan (`RUTE_RUMAH_DEKAT_MUNDUR_UBIN`), sedangkan tapak logika, zona, dan validasi segmen tidak berubah. Tembok bukan penghalang gerak atau tabrakan dan tidak didaftarkan ke penerap penutup; kotak penutup rumah dekat yang didaftarkan memakai tapak yang digeser sama dengan gambarnya (P-4), sehingga rumah dekat tidak pudar saat pemain di trotoar dekat. Pengukuran sasaran (P-1): badan kotak surat dekat tertimpa tembok 0%, zona kotak surat paling banyak 13,1% (varian `pot`), zona teras dekat dikecualikan karena tidak terlihat; keraguan visual tercatat bagian 11.
- **Pos satpam + portal (usulan gelombang 1, M3):** `prop_pos_satpam` (sel 64×64, pijak (32, 50); pos 20×24 unit, dinding krem pastel, atap dongker menjorok, jendela biru muda menghadap jalan samping, pintu kayu) dan `prop_portal_satpam` (sel 80×64, 2 frame: tertutup, terbuka; pijak (14, 48) = kaki tiang; palang 52 unit belang merah bata/krem tiap 6 unit, tiang logam gelap dengan pemberat).

### 6.5 Properti

| Aset | M2 | M3 |
|---|---|---|
| Kotak surat (penuh/kosong) | ✅ | ✅ |
| Tong sampah | ✅ | ✅ |
| Pohon / tanaman pot | ✅ | ✅ |
| Mobil tamu parkir | ⬜ | ✅ |
| Lampu jalan | ⬜ | ✅ |
| Selang penyiram | ⬜ | ✅ |

**Antena TV (usulan, 2026-10-15):** enam jenis di `tools/env_art/fase3.py` (`antena_v`): yagi (`lib.antena`), yagi di tiang bambu tinggi, dua yagi bertumpuk, parabola putih, parabola jaring besar, dan panel digital DVB-T2 dengan booster. Yagi dan panel menghadap arah pemancar yang sama (`ANT_DIR`), parabola menghadap langit ke arah satelit. Jenis per rumah dipilih dari seed. Lembar contoh `design/environment/fase3_antena_tv.png`.

**Usulan gelombang 1 (2026-10-20, `tools/env_art/gelombang1/`, belum dipasang):** `prop_tong_sampah_hijau` dan `prop_tong_sampah_biru` (palette swap), tong plastik bulat bertutup, tapak r 7 unit (±¼ ubin), tinggi 18, sel 20×30 pijak (10, 25).

**Terpasang di rute (run fase5b bagian B2, 2026-10-21; usulan sampai dinilai di HP):** `prop_tong_sampah_logam` (abu-abu logam saja, tong biru TIDAK dipasang, K-2), `prop_pohon_{rindang,glodokan,ketapang}`, dan lampu jalan `lengan` (PJU perumahan) hanya bingkai MATI (siang) sebagai dua sprite tunggal `prop_lampu_lengan_seberang` dan `prop_lampu_lengan_dekat` (lengan menghadap jalan; bingkai nyala tidak disalin, M3), dikeluarkan `tools/env_art/lampu_pohon.py --salin` dan `gelombang1/render.py --salin`. Penempatan lewat bidang `dekor` data segmen (DATA_SCHEMA 3, ROUTE_DESIGN 4b), digambar `DekorDaur` dengan jendela daur dan Y-sort; pohon, lampu, dan tong sampah sisi dekat menutupi pemain (alfa `RUTE_PENUTUP_ALFA`) lewat penerap penutup yang sama dengan rumah, termasuk di lajur sepeda dan trotoar (iterasi 2, P-6 dan P-7: kotak = tinggi dan lebar sprite nyata, dibuktikan dengan piksel; pemain tidak pernah tertutup opak), dekor seberang tidak (lateral seberang pohon 2,75, lampu 2,625). Keraguan visual: tong sampah abu-abu mirip kotak surat abu-abu bukan pelanggan dari jauh; bayangan tanah pohon dan lampu dipanggang ke kanan bawah di kedua sisi, jadi arah bayangan antar sprite tidak konsisten dengan satu sumber cahaya (PNG tidak diedit); palet pohon dan lampu melebihi palet induk 2.4 (23 warna di luar palet induk, palet belum dikunci, K-3).

### 6.6 Rintangan dan warga

| Aset | M2 | M3 | Catatan |
|---|---|---|---|
| Anjing penjaga: diam, lari, berhenti di batas halaman | ✅ | ✅ | Rintangan 1 di prototype 3 |
| Mobil keluar garasi + lampu mundur | ✅ | ✅ | Rintangan 2 di prototype 3 |
| Penghuni menyiram halaman | ⬜ | ✅ | |
| Tukang sayur keliling | ⬜ | ✅ | |
| Pelanggan di teras (reaksi senang / kesal) | ⬜ | ✅ | |
| Reaksi bel: ikon "!" lalu menepi | ⬜ | ✅ | Untuk warga dan hewan yang bisa minggir (GDD 5.4). Ikon di `design/bel/`; frame menepi per tokoh menyusul, awalnya cukup bergeser |

**Usulan dirender (2026-10-15, `tools/env_art/fase3.py`, belum dipasang di game)** di `assets/sprites/obstacles/`:

- `obs_anjing_sheet.png` (sel 58×58, titik pijak (24, 38)): duduk dan gonggong menghadap jalan, lari_1/lari_2 (10 fps) dan berhenti menghadap maju. Tanda = berdiri dan menggonggong (ROUTE_DESIGN 2). Bulu krem kecokelatan, ukuran ×1,15 supaya terbaca saat ngebut.
- `obs_mobil_garasi_sheet.png` (sel 132×95, titik pijak (43, 46)): sedan `lib.car()` diputar 90°, moncong ke garasi, bagasi ke jalan. Parkir, lalu nyala dan redup bergantian 4 fps sebagai tanda lampu mundur, dengan asap knalpot dan cahaya di aspal (alpha di sel); frame nyala dipakai saat mundur. Hanya sisi seberang: mobil sisi dekat mundur ke arah kamera dan lampunya tidak terlihat.
- Bayangan jatuh dipanggang sebagai penanda #000000 alpha 28% (2.1), cahaya siang.

### 6.7 Misi

| Aset | M2 | M3 |
|---|---|---|
| Kucing: diam, kabur, ditangkap | ✅ | ✅ |
| Jejak kaki, mangkuk | ✅ | ✅ |
| Kilau petunjuk (2 frame) | ✅ | ✅ |
| Pencuri sandal | ⬜ | ✅ |

**Pose kucing ditangkap (run fase5c-animasi-simpang, 2026-10-22; usulan, dinilai di HP):** `KucingMisi` memakai kolom `ditangkap_1`/`ditangkap_2` (kolom 7 dan 8 sheet 9 kolom, baris hadap "masuk" seperti duduk) selama langkah tangkap dengan progres > 0, dua frame `MISI_KUCING_DITANGKAP_FPS` 3 fps dari waktu animasi misi (membeku saat jeda), lewat fungsi murni `PoseKucing`; progres 0 dan langkah lain tetap duduk. Titik pijak, kotak penutup, zona, bar progres, dan kilau tidak berubah. Keraguan: di titik tahan dekat kucing, badan pemain menutup sebagian besar kucing (B-F1).

**Terpasang (run fase5a bagian B): hanya `mission_kilau`** (`assets/sprites/vfx/`, `KucingHiasan.item_kilau`: sprite 9x9 dua frame di tengah kotak 11x11 yang pojoknya `MISI_KILAU_POSISI_PX`, ritme `MISI_KILAU_DETIK` 0,4 detik, di atas ekor dan di bawah bar progres); jejak dan mangkuk belum dipasang. Kilau dua warna (K-1): krem terang dominan, kuning aksen satu piksel di titik tengah. Keraguan visual: kilau kecil dan krem di atas atap atau teras putih berkontras rendah (dinilai di HP). **Usulan gelombang 1 (2026-10-20, `tools/env_art/gelombang1/`, belum dipasang):** `mission_jejak_kucing_1` (lurus naik ke kanan atas) dan `_2` (berbelok ke halaman), decal tanah 40×20 tanpa garis luar, lumpur kayu gelap, telapak 5×3 px (jari digabung supaya tidak ada detail 1 px); `mission_mangkuk_kucing` (14×12, mangkuk pink berisi pelet); `mission_kilau` (9×9, 2 frame, 4 fps, kuning aksen hangat bergaris luar supaya terbaca di trotoar krem; dipasang 12–16 px di atas benda petunjuk).

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

**Usulan (2026-10-15, `tools/ui_art/hud_ikon.py`):** ikon 14×14 koin, reputasi, ban, rem, rantai, dan misi kucing (`assets/sprites/ui/ui_icon_<nama>.png`, `ui_icon_hud_sheet.png`), penanda radar 8×6 dan versi masuk jangkauan 10×8 (`ui_radar_<jenis>.png`, `ui_radar_<jenis>_jangkau.png`, `ui_radar_penanda.png`), bingkai 9-slice strip radar dan panel HUD. Koran tetap `IKON_KORAN` di kode, tombol jeda dari kode. Pratinjau di `design/hud/`. Ikon rem paling lemah di ×1, cek di HP.
| Tombol bel: diam, ditekan, jeda (usulan, `design/bel/`) | ⬜ | ✅ |
| Logo "Kring Kring!" untuk layar judul dan ikon aplikasi | ⬜ | ✅ |

**Usulan redesain UI (2026-10-23, `tools/ui_art/redesain/`; komponen bersama dan bengkel dipasang di run UI-1, hasil, koran, jeda, tutorial, banner, dan tombol jeda HUD di run UI-2, semuanya sebagai usulan):** bingkai 9-slice tombol 12×16 empat peran dengan bibir bawah 2 px dan versi ditekan, panel dan kartu 12×12 (biasa, menonjol WARN, redup), chip 8×8, versi terang halaman koran, struk bergerigi, ikon 24×24 (koin, bintang, ban, rem, rantai, kucing, kerucut, bohlam), lencana 32×32 (tingkat juga ditandai 1/2/3 titik), glif 12×12 satu warna, sepeda panggung bengkel 116×78 (dan 232×155) yang diambil dari gambar full body tanpa tokoh, bagian yang tertutup tubuh digambar ulang (`sepeda_fullbody.py`, warna hanya dari palet gambar full body, garis luar `#1B1226`), papan alat bengkel, dan foto berita tinta dua nada. Semua warna dari palet induk dan token UI. Latar bengkel 640×360 dan 800×360 adalah konversi ilustrasi AI dengan cara gambar skala besar (3.5; tanpa garis luar `#0E0A1C`, cahaya lampu sebagai cincin bertingkat). Rincian dan urutan porting: `design/redesain/README.md`.

**Dipasang run UI-1 (usulan, 2026-10-23, `docs/loop/20261023-ui1-komponen-bengkel/`; dinilai di HP, SETUP_ANDROID 8.18):** `--salin` tiga skrip (`komponen.py`, `sepeda_fullbody.py`, `latar_bengkel.py`; daftar tunggal di `tools/ui_art/redesain/pasang.py`, tujuan `assets/sprites/ui/`, folder tujuan uji lewat `UI_ART_SALIN_KE`) memasang HANYA yang dipakai bengkel tata C dan komponen bersama, 29 PNG + `ui_bengkel_sepeda.json` (30 berkas), masing-masing dengan `.import` Lossless, Nearest, tanpa mipmap:
- Tombol (`ui_btn_{utama,utama_tekan,biasa,biasa_tekan,sakelar_nyala,tenang,tenang_tekan,nonaktif}`, 12×16, slice samping 4 dan atas-bawah 6) dan `ui_arsir_nonaktif` (4×4, ubin tengah tombol nonaktif; tidak ada PNG yang diedit tangan, arsir diganti saat dimuat).
- Panel dan kartu (`ui_panel_layar`, `ui_kartu_{biasa,menonjol,redup}`, 12×12, slice 4) dan chip (`ui_chip_{gelap,ok,warn,netral,aksen}`, 8×8, slice 3). `panel_hud` tidak dipasang ulang (sudah ada `ui_panel_hud_9slice.png`).
- `ui_bengkel_papan_alat` (360×104), `ui_bengkel_sepeda_kecil` (116×78) dan `ui_bengkel_sepeda.json` (titik penanda, salinan byte `sepeda.json`), `ui_bengkel_latar_800` (800×360).
- Ikon 24 (`ui_icon24_{ban,rem,rantai}`) dan glif 12 (`ui_glif_{seru_warn,centang_ok,centang_teks2,kunci_terang,panah_gelap}`) dipotong per sel dari sheet `ikon24` dan `glif12` (piksel sama dengan sheet, dijaga `uji_ui_redesain.py`).
- Tidak dipasang (belum dipakai layar mana pun): `sepeda_besar`, latar 640 (potongan tengah latar 800), koran, struk, foto berita, `lencana32`, `kertas_tile`, ikon dan glif lain, lembar pratinjau. Layar berikutnya menambah barisnya ke `pasang.py`.
- Kotak kondisi besar (8×8, jarak 2, "!" 3×9, berongga = AUS) dan chip tingkat I, II, III digambar dari kode (`PolaPiksel`, komponen `ChipUi`), bukan PNG. Tanpa token warna baru; font tetap Lexend dan Lilita One, hanya ukuran layar penuh yang baru (type variation di `assets/ui/theme.tres`, DESIGN_SPEC 1.3).
- Teknik latar: cahaya lampu menutupi judul "UPGRADE" di atas latar, jadi judul itu diberi pelat `HUD_PANEL` (3 px per sisi) di kode.
- Kontras terukur dari tangkapan nyata (`tools/ukur_kontras_tangkapan.py`): semua teks >= 7,79:1; garis bingkai kartu 1,14 sampai 1,78:1 dan tombol nonaktif 1,14:1 (di bawah 3:1, keputusan terbuka D-1 di LOG run); tombol aktif 8,53 sampai 13,48:1.

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

**Terpasang di rute (run fase5a bagian B; usulan sampai dinilai di HP):** `vfx_debu_roda` dan `vfx_garis_kecepatan_{a,b,c}` menggantikan partikel kode di scene rute lewat `UmpanBalikSepeda.atur_sprite` (`VfxSepedaGambar`, logika `VfxSepeda`): kapan tampil tetap dari `UmpanBalikKecepatan` (debu tepat bila `laju_debu` > 0, garis tepat bila `kekuatan_garis` > 0, kurangi efek = garis mati dan debu alpha x0,5), sprite ikut sepeda (debu tidak lagi tertinggal di dunia saat pindah sisi), varian garis diacak berseed tiap 2-3 frame dengan geseran tegak lurus jalan, membeku saat jeda; kepala garis di (20, −14) dari titik pijak sepeda (`UMPAN_GARIS_SPRITE_KEPALA_*`, perbaikan 2026-10-22 atas uji HP pemilik), sehingga pusat garis = pusat rata-rata garis partikel lama di sekitar badan pengendara, bukan di titik munculnya (30, −24) di depan roda depan; `vfx_bintang_kena` (sekali, 15 fps) di titik mendarat tiap antaran sah dan `vfx_koin_tip` (sekali, 10 fps, tulisan "+5" dipanggang) bila ada tip, dijaga `UMPAN_KOIN_TIP_SPRITE_NILAI` = 5 (bila `KOIN_TIP` berbeda baris tip label dipakai lagi). Keraguan visual: debu dan garis jauh lebih tipis dari partikel lama di x3 dan hampir hilang di trotoar; label "+15" bisa menimpa tulisan "+5" koin sekejap. Jalan uji tetap partikel kode. **Usulan gelombang 1 (2026-10-20, `tools/env_art/gelombang1/`, belum dipasang untuk percikan):** `vfx_debu_roda` (18×10, 6 frame, 12 fps loop, pijak = roda belakang; kotak 2×2 lalu 1×1 krem mundur 2 px kiri 1 px turun per frame), `vfx_garis_kecepatan_a/b/c` (28×14, putih alpha 70%, anak tangga 2×1, tanpa garis luar), `vfx_bintang_kena` (15×15, 6 frame, 15 fps sekali; empat sinar utama + empat sinar pendek berputar 90° lalu pecah), `vfx_koin_tip` (16×26, 6 frame, 10 fps sekali; koin naik 16 px sambil berputar, "+5" huruf 3×5), `vfx_percikan_genangan` (24×16, 5 frame, 12 fps sekali, biru muda tanpa garis luar). Mock `design/environment/gelombang1/lembar_vfx_x5.png`.

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
- Renderer **Compatibility** (usulan) untuk HP kelas bawah. Cek di Fase 0 apakah light 2D, glow, partikel, dan shader warna bayangan yang dibutuhkan jalan di renderer ini. **Hasil 2026-10-14 (probe `scenes/dev/cek_render.tscn`, run 1B) di vivo V2108, Android 12, Adreno 618, OpenGL ES 3.2, 2400×1080 ×3:** light 2D + bayangan occluder ya, glow 2D (`WorldEnvironment` latar Canvas) ya tetapi halonya tipis (0,101 lawan latar 0,050), partikel CPU dan GPU ya, shader warna bayangan cocok (13/13 piksel penanda, piksel lain tidak berubah), 60,6 fps rata-rata. HP uji dipilih pemilik ("pakai yang ada"); A54 (GPU Mali) belum dicek. Bukti: `docs/loop/20261014-fase1b-umpan-balik/render_vivo/`.
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

- **Latar bengkel (usulan, 2026-10-23, butir terbuka pemilik):** `docs/design/redesain/latar_bengkel/sumber_ai.jpg` adalah ilustrasi AI kiriman pemilik; **generator dan ketentuan lisensi komersialnya belum dicatat**. Konversinya (`ui_bengkel_latar_800.png`) dipasang di `assets/sprites/ui/` HANYA untuk uji HP run UI-1. **Aset itu belum boleh masuk rilis** (build rilis, Play Store, materi publik) sebelum pemilik mencatat nama generator, tanggal, dan ketentuan lisensi komersial di `assets/LICENSES.md`; bila ketentuannya tidak mengizinkan, latar diganti (tanpa mengubah tata letak bengkel, latar hanya `TextureRect` di belakang).

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

- ~~**Ukuran ubin (64×32)**~~: dikunci 2026-10-14 setelah graybox Fase 1 (ROADMAP 4b). Skala piksel sudah dikunci ×3 (2026-10-09).
- **Stretch mode dan resolusi dasar** (bagian 7): sudah dipilih 2026-10-09, diverifikasi di desktop pada run 0A (hasil di ROADMAP 4b); uji di HP menunggu.
- **Palet induk** (bagian 2.4): dikunci setelah aset gelombang 1.
- **Warna bayangan per waktu dan distrik** (bagian 2.5): dikunci bersama palet induk, setelah shader-nya dicek di Fase 0 (shader jalan di Compatibility, dicek 2026-10-14 di vivo V2108; bagian 7).
- **Cara menampilkan rumah di sisi dekat** (✅ diputuskan 2026-10-17: tembok/pagar belakang rendah, lihat akhir butir ini; **diganti pemilik 2026-10-22, Run 5D: halaman terbuka tanpa tembok, rumah dekat mundur 0,5 ubin dengan teras menjorok, 6.4**), yang hanya terlihat belakangnya. **Usulan lama (2026-10-15, digantikan keputusan 2026-10-17):** rumah sisi dekat dimundurkan ¾ ubin dan sasarannya kotak surat di tepi lajur (6.4). Ikut terbuka: kalau aturan warna pelanggan dipakai ketat, sisi tanpa pelanggan (seluruh sisi dekat di distrik pertama) jadi abu-abu; pilihan lain, sisi tanpa pelanggan tetap berwarna dan pembedanya hanya kotak surat. Mock `design/environment/fase3_perumahan.png` memakai pilihan kedua. **Spike run 3C (2026-10-17):** tiga pendekatan TECH_PLAN Fase 3 dibuat sebagai graybox dev oleh `tools/env_art/spike_sisi_dekat.py` (`assets/sprites/_spike/sisi_dekat/`, hanya untuk `scenes/dev/spike_sisi_dekat.tscn`, tidak ikut paket game): (1) punggung rumah rendah (dinding 18, atap 31 unit) dan kontras rendah (warna dicampur 40% ke rumput), (2) tembok belakang rendah 14 unit di kaki kavling dengan rumah penuh 1,25 ubin di belakangnya, (3) punggung rumah penuh yang semi-transparan lewat aturan penutup. Tangkapan dan catatan perbandingan: `docs/loop/20261018-fase3c-hud-hasil/`. **Diputuskan pemilik 2026-10-17: pendekatan (2), tembok/pagar belakang rendah** (`ROADMAP.md` 4b). Aset produksi sisi dekat (modul tembok/pagar per distrik + belakang rumah penuh) dibuat di Fase 5/8; tinggi tembok 14 unit dan mundur 1,25 ubin tetap usulan sampai uji HP Bab 2. Usulan warna sisi tanpa pelanggan di atas tetap terbuka.
- **Aset gelombang 1 (2026-10-20, keraguan yang perlu diputuskan pemilik sebelum palet induk dikunci):** (a) bintang kena, koin tip, dan kilau misi memakai kuning aksen hangat seperti yang diminta, padahal kuning berarti sasaran kotak surat; di satu layar ada tiga titik kuning dengan arti berbeda, paling berisiko kilau misi di atas rumput (pilihan: kilau dua warna krem terang + kuning, atau ritme kedip berbeda); (b) polisi tidur dan portal sengaja tidak kuning-hitam, jadi berbeda dari `prop_polisi_tidur` lama; (c) tong hijau memakai hijau dasar, padahal hijau berarti misi selesai (pilihan: abu-abu logam); (d) koran gulung 8×6 nyaris hilang saat terbang di ×3, bayangannya lebih mudah terbaca; (e) debu dan garis kecepatan hampir hilang di trotoar krem distrik lain; (f) versi sore baru grading satu layar termasuk pemain, belum setengah grading pemain (2.6) dan belum bayangan panjang. **Diputuskan 2026-10-21 (delegasi pemilik ke orchestrator, usulan, bisa ditolak di review PR; dikerjakan di Run 5A, `LOOP-DEV-QA.md` 6g):** (a) kilau misi dua warna, krem terang dominan dengan kuning hanya titik tengah; bintang kena dan koin tip tetap kuning karena muncul sekejap setelah lemparan, bukan zona diam; (b) hanya satu polisi tidur, versi gelombang 1 belang krem dan logam gelap, `prop_polisi_tidur` kuning-hitam lama dibuang dari ekspor; (c) tong sampah hijau diganti abu-abu logam; (d) koran 8×6 dipakai apa adanya dan diperbesar hanya bila uji HP menolak; (e) dan (f) ditunda ke penilaian HP dan Fase 7. Lebar jalan 2 ubin aspal mengikuti `config.gd` (mock 3 ubin lama di 2.6 tidak berlaku). Palet induk tetap belum dikunci sampai aset dinilai di HP.
- **Pemasangan gelombang 1 di rute (Run 5A, 2026-10-21, usulan, bisa ditolak di review PR):** D-2 enam kolom ubin (batas |x| = 1 dan 2 ke kolom luar, ubin polos `rumput_1` untuk rumput di luar kolom pertama); D-3 koran (putar, bayangan menurut tinggi tanpa alpha 85% placeholder, permukaan, terlipat); D-4 debu dan garis dari sprite dengan logika `UmpanBalikKecepatan` tidak berubah; D-5 bintang kena dan koin tip; D-6 kilau; D-7 kode placeholder dibuang hanya bila tidak ada pemakai (jalan uji tetap memakai pola kode dan partikel kode, jadi mode sprite adalah sakelar per node). Temuan teknis: tekstur yang baru dimuat di dalam `_draw` tergambar putih polos, jadi tekstur dimuat di luar `_draw` dan dipegang node (`GambarSprite`). Keraguan yang tetap terbuka untuk HP: bayangan 28% di aspal, lajur hijau trotoar lawan penanda misi selesai, debu dan garis yang tipis, kilau di atas atap putih, posisi koran terlipat terhadap teras sprite rumah.
- **Pemasangan tembok, dekor, dan ubin tambahan di rute (Run 5B, 2026-10-21, usulan, bisa ditolak di review PR; `docs/loop/20261021-fase5b-tembok-dekor/SPEC.md`):** D-1 hanya aset yang dipasang yang disalin lewat `--salin` tiga skrip renderer; D-2 tapak logika rumah dekat tidak digeser, hanya gambarnya (mundur 1,25 ubin; tembok berpusat 3,125, selisih 0,125 = setengah tebal); D-3 tembok tiga modul dan satu tiang per rumah dekat, varian dari FNV-1a id rumah; D-4 `aspal_1..3` tidak dipasang (memutus garis kerb); D-5 satu jenis lampu per sisi (`lengan`, mati), tiga jenis pohon, tong logam; D-6 dekor di `pos` bulat 1..panjang-1, lateral per jenis di `config.gd`; D-7 ubin masuk hanya sisi seberang, simbol tiap 12 baris, rumput polos luar dari hash; D-8 pembagian Dev A (renderer), B (tembok, dekor), C (ubin, probe, paket, dokumen). Putusan sesudah B1: P-1 kriteria sasaran dekat menjadi badan kotak surat 0% dan zona kotak surat paling banyak 15% (zona teras dekat dikecualikan); P-2 tiang di awal modul; P-3 Y-sort wajar (rumah digambar sesudah tembok); P-4 kotak penutup rumah dekat digeser seperti gambarnya. Keraguan yang tetap terbuka untuk HP: tembok rendah terbaca sebagai pagar bukan pita gelap, varian `pot` menutupi 13,1% zona kotak surat dekat, tong abu-abu lawan kotak surat abu-abu, bayangan baked yang tidak seragam arahnya, ubin garasi masuk membuat mobil parkir terbaca sebagai garasi, simbol sepeda tidak terbaca sebagai marka bahaya, dan variasi rumput tidak terlihat acak berisik. Palet induk tetap belum dikunci.
- **Animasi pemain, kucing ditangkap, ujung kerb, dan simpang T (Run 5C, 2026-10-22, usulan, bisa ditolak di review PR; `docs/loop/20261022-fase5c-animasi-simpang/SPEC.md`):** P-1 simpang = hiasan (keputusan pemilik); P-2 ujung kerb dikerjakan terpisah dari simpang; P-3 kucing ditangkap tampil selama progres tangkap > 0; P-4 lama jatuh tetap 1,2 detik, jadi terjerembab hanya 0,2 detik; P-5 lempar 90° di luar scope; P-6 rumah seberang `per_buka_02@18` (bukan pelanggan) dihapus untuk memberi tempat satu simpang seberang; D-2 hanya ubin yang berbeda dari jalan lurus yang disalin. Keraguan yang tetap terbuka untuk HP: jatuh lima arah terbaca dan pijak tidak melompat, bangkit mulus ke kayuh (sprite bisa berganti arah satu langkah sesudah bangun bila stick masih ditahan, A-F4), terjerembab 0,2 detik cukup atau terlalu singkat, kaki kanan berhenti terbaca saat menangkap kucing, kucing ditangkap terbaca sebagai dielus (bukan diam seperti mati), ujung kerb rapi, simpang terbaca sebagai jalan samping, tembok dekat terputus wajar di simpang dekat. Palet induk tetap belum dikunci.
- **Font HUD**: mock memakai Lexend + Lilita One (sama dengan Brainy Dungeon). Kunci atau pilih identitas sendiri.
- **Apakah sprite pemain dipoles manual** sebelum rilis, terutama wajah dari arah depan.

**Dipasang run UI-2 (usulan, 2026-10-24, `docs/loop/20261024-ui2-semua-layar/`; dinilai di HP, SETUP_ANDROID 8.19):** `komponen.py --salin` (daftar tunggal `pasang.py`) memasang 32 berkas tambahan ke `assets/sprites/ui/` (total redesain terpasang 62, masing-masing `.import` Lossless, Nearest, tanpa mipmap, bukan VRAM): untuk hasil `ui_struk` (9-slice 12×12, tepi atas dan bawah bergerigi), `ui_struk_takik` (6×10), `ui_icon24_{koin,bintang,lencana_perunggu,lencana_perak,lencana_emas}`, `ui_lencana32_{perunggu,perak,emas}` (sel dari sheet lencana 32; sel "belum" tidak dipasang), `ui_glif_{naik_ok,turun_teks2}`; untuk koran `ui_koran_{kotak,btn_tinta,btn_tinta_tekan,btn_tipis,btn_terpilih}`, `ui_kertas_tile`, `ui_foto_{jalan,lampu}`, `ui_icon24_{kucing,kerucut,bohlam}`, `ui_glif_{centang_gelap,panah_terang,seru_tinta2}`; untuk jeda, tutorial, banner `ui_glif_{jeda_terang,lanjut_gelap,naik_aksen,turun_aksen,panah_aksen,seru_aksen}`. Tidak dipasang: `sepeda_besar`, sheet lencana 32 utuh, `panel_hud` redesain (panel HUD tetap `ui_panel_hud_9slice.png`), latar 640, sheet ikon dan glif utuh, foto berita selain jalan dan lampu. Kenop sakelar jeda digambar kode (bukan PNG). Struk dan kartu hasil di atas dunia rute memakai `modulate_color` (alpha 0,72 dan gelap 0,5; V-10): PNG tidak diedit tangan dan tanpa palet baru. Aset lencana lama `ui_lencana_{perunggu,perak,emas}.png` (14×14, run 6A2) tidak dipakai skrip mana pun lagi dan dibiarkan (masih dijaga `uji_ui_lencana.py` dan `tes_export`); pembersihannya DEFERRED ke run lain. Tanpa font atau palet baru.

---

## Changelog Keputusan

- **2026-10-24** — **Hasil, koran, jeda, tutorial, banner, dan tombol jeda HUD dipasang sebagai usulan; skala font layar penuh naik +2; latar hasil memakai dunia yang baru dilalui** (Run UI-2, `docs/loop/20261024-ui2-semua-layar/`; bagian 6.8, 9; usulan sampai dinilai di HP, `SETUP_ANDROID.md` 8.19): 32 aset komponen tambahan lewat `--salin` (daftar `pasang.py`, hanya yang dipakai; total 62), struk antaran dengan kolom samping, halaman koran berkertas dengan foto berita dan kotak iklan hiasan, jeda dengan lapisan 72 persen dan sakelar berkenop, panel tutorial dan banner baru; HUD rute hanya tombol jeda, panel bawah kecepatan dan stamina berdampingan, dan kolom kanan atas dua baris (V-9, permintaan pemilik). Penyimpangan dari kanvas tertulis di LOG (kotak iklan tanpa teks, label kapital hasil jadi huruf biasa, banner misi HUD tanpa ikon, panel jeda di tengah tegak, struk dan kartu digelapkan di atas dunia). Butir lisensi latar bengkel tetap terbuka (bagian 9).
- **2026-10-23** — **Komponen UI redesain dan latar bengkel dipasang sebagai usulan** (Run UI-1, `docs/loop/20261023-ui1-komponen-bengkel/`; bagian 6.8, 9; usulan sampai dinilai di HP, `SETUP_ANDROID.md` 8.18): tombol empat peran, panel dan kartu, chip, papan alat, sepeda bengkel, ikon 24 dan glif 12 yang dipakai, serta latar bengkel 800 disalin lewat `--salin` ke `assets/sprites/ui/` (30 berkas, daftar di `tools/ui_art/redesain/pasang.py`, hanya yang dipakai). Latar bengkel dari ilustrasi AI **dipasang untuk uji HP walau generator dan lisensi komersialnya belum dicatat** (keputusan orchestrator U-4, bisa ditolak): berkas itu belum boleh masuk rilis sebelum pemilik mencatatnya (bagian 9). Palet induk, font, dan token warna tidak berubah. Tidak ada keputusan palet atau gaya yang dikunci.
- **2026-10-23** — **Redesain UI layar penuh sebagai usulan** (6.8): kanvas Claude Design "UI Loper Koran — Redesain" diporting jadi renderer `tools/ui_art/redesain/komponen.py`, sepeda bengkel dari gambar full body `tools/ui_art/redesain/sepeda_fullbody.py`, dan konversi latar bengkel `tools/ui_art/redesain/latar_bengkel.py` (latar dipilih pemilik dari dua kandidat, tanaman dihapus). Pada tanggal itu belum dipasang di game dan belum disalin ke `assets/`; belum dikunci.
- **2026-10-22** — **Animasi pemain 5C diverifikasi, kucing ditangkap, ujung kerb, dan simpang T hiasan dipasang di rute** (Run 5C, `docs/loop/20261022-fase5c-animasi-simpang/`; bagian 3.4, 6.1, 6.3, 6.7, 11; usulan sampai dinilai di HP, SETUP_ANDROID 8.14): pijak jatuh/bangkit/berhenti tidak melompat (dua perbaikan tampilan: kayuh sesudah bangun dari frame 0, arah jatuh ditahan), pose kucing `ditangkap_1/_2` dipakai selama progres tangkap, dua ubin ujung kerb jalan masuk seberang (C-F1 ditutup), 18 + 16 ubin simpang T dipasang dari bidang `simpang` di data segmen (tiga simpang dekat, satu seberang; rumah seberang bukan pelanggan `per_buka_02@18` dihapus, P-6). Entri 2026-10-22 di bawah yang menyebut kucing ditangkap "belum dipakai rute" dan ubin simpang "belum dipasang" digantikan entri ini. Hanya tampilan dan data segmen.
- **2026-10-22** — **Rumah sisi dekat didesain ulang, tembok sisi dekat dihapus** (Run 5D, `docs/loop/20261022-fase5d-sisi-dekat/`; bagian 6.4, 6.6; keputusan pemilik: sisi dekat harus terlihat seperti sisi jauh, rumah dekat mundur 0,5 ubin dengan teras menjorok; usulan sampai dinilai di HP, `SETUP_ANDROID.md` 8.16). `fase3.py` kini bisa dihasilkan ulang ke `assets/` (tiga PNG lama berbeda beberapa piksel dari skrip, versi skrip jadi sumber kebenaran; `uji_aset_fase3.py`). Lima `house_tembok_*` dihapus dari `assets/`; ART_DIRECTION 6.4 tembok ditandai tidak terpasang, riwayat tetap.
- **2026-10-22** — **Kotak penutup dekor sisi dekat = tinggi dan lebar sprite nyata, dekor seberang digeser keluar** (Run 5B iterasi 2, QA-001, P-6, usulan sampai dinilai di HP; bagian 6.5): pohon, lampu, dan tong sampah sisi dekat semi-transparan juga di lajur sepeda dan trotoar (tinggi 1,375 / 1,96875 / 1,65625 / 2,0 / 0,75 ubin, setengah tapak 0,875 / 0,625 / 0,75 / 0,75 / 0,625), dibuktikan dengan piksel (`tests/tes_dekor_piksel.gd`); lateral seberang pohon 2,75 dan lampu 2,625; tiga butir data digeser dari anjing dan teras.
- **2026-10-22** — **Animasi pemain Fase 5C dipasang sebagai usulan** (bagian 3.4; kanvas Claude Design "Animasi Pemain Fase 5C — Loper Koran"): jatuh/terjerembab lima arah (sel 140×88), bangkit lima arah, berhenti kaki kanan lima arah (`tools/loper_art/fase5c.py`, opsi `foot_down` di `loper.py`), pose kucing misi `ditangkap_1/_2` (kolom 7–8 sheet kucing, `kendaraan.py`, belum dipakai rute), dan ubin simpang T ke sisi dekat dan seberang (`ubin_perumahan.py ekspor_simpang`, 18 + 16 ubin di `build/`, belum dipasang karena rute belum punya simpang). `loper_agen_frames.tres` kini 68 animasi.
- **2026-10-21** — **Tembok sisi dekat, dekor pinggir jalan, dan ubin tambahan dipasang di rute perumahan** (Run 5B, `docs/loop/20261021-fase5b-tembok-dekor/`; bagian 6.3, 6.4, 6.5, 11; usulan sampai dinilai di HP, SETUP_ANDROID 8.13): tembok empat varian dengan tiang ujung dan rumah dekat digambar mundur 1,25 ubin, tong sampah logam, tiga pohon dan lampu mati lewat bidang `dekor` di sembilan segmen, jalan masuk garasi di bawah mobil seberang, simbol sepeda tiap 12 baris, dan variasi rumput luar. `aspal_N` tidak dipasang (D-4). Hanya tampilan dan data dekor.
- **2026-10-21** — **Aset gelombang 1 dipasang di rute perumahan** (Run 5A, `docs/loop/20261021-fase5a-pasang-aset-gelombang1/`; bagian 2.6, 6.2, 6.3, 6.7, 6.9, 11; usulan sampai dinilai di HP, SETUP_ANDROID 8.12): enam kolom ubin jalan, koran putar dengan bayangan menurut tinggi, koran tergeletak menurut permukaan dan koran terlipat di rumah terantar, debu roda dan garis kecepatan dari sprite, bintang kena dan koin tip, kilau misi. Hanya tampilan. Keraguan visual yang tercatat ada di bagian 11.

- **2026-10-21** — **Keraguan warna gelombang 1 diputuskan** (bagian 11; usulan, delegasi pemilik ke orchestrator): kilau misi dua warna, satu polisi tidur (versi gelombang 1), tong sampah abu-abu logam, koran 8×6 dipakai apa adanya, lebar jalan 2 ubin. Pemasangan aset ke rute dipecah menjadi Run 5A (ubin, koran, VFX, kilau), 5B (tembok sisi dekat, dekor di data segmen), dan 5C (animasi pemain); perintah 5A di `LOOP-DEV-QA.md` 6g. Palet induk belum dikunci.
- **2026-10-20** — **Aset gelombang 1 Fase 5 dirender sebagai usulan** (6.2–6.5, 6.7, 6.9; keraguan di 11). Kanvas Claude Design "Aset Gelombang 1 (Fase 5)" (`design/PROMPT_FASE5.md`) digambar dengan kode tanpa gambar generatif, lalu diporting ke `tools/env_art/gelombang1/`: 29 sprite 1× + JSON (koran, VFX, tong sampah, misi kucing, gerbang satpam, tembok belakang rendah sisi dekat, tiga ubin), semuanya hanya memakai palet induk 2.4 (dites `tools/tests_cek/uji_aset_gelombang1.py`). Belum disalin ke `assets/` dan belum dipasang; tidak ada yang dikunci.
- **2026-10-17** — **Tabrakan = jatuh** (keputusan pemilik; bagian 3.4, 6.1; BALANCING 6c). Animasi jatuh terjerembab yang sebelumnya usulan tak terpakai kini dipakai setiap tabrakan: `jatuh_normal` lalu `terjerembab_normal` selama 1,2 detik, lalu bangun langsung ke kayuh dengan kedip kebal. Baris lama "tidak jatuh dramatis" diganti: tabrakan kini terlihat jatuh, tetapi tetap hanya menghambat (pemain melanjutkan, tanpa game over). `loper_agen_frames.tres` kini 50 animasi, dibangun `tools/loper_art/bangun_frames.py` dari enam JSON sumber; PNG jatuh disalin byte demi byte, tidak diubah. Titik pijak (57, 51) di sel 114×68 berjarak sama dari tengah sel dengan kayuh, jadi offset (0, -17) sama (dites). Empat arah lain dan animasi bangkit tercatat sebagai pekerjaan aset Fase 5.

- **2026-10-15** — **Aset Fase 3 perumahan dirender sebagai usulan** (6.4–6.6, 6.8): anjing penjaga, mobil keluar garasi, rumah pelanggan dan bukan pelanggan di dua sisi, enam jenis antena TV (`tools/env_art/fase3.py`), ikon HUD dan penanda radar (`tools/ui_art/hud_ikon.py`). Mock lama dari `perumahan.py` tidak berubah. Belum dipasang di game dan belum dikunci.
- **2026-10-14** — **Ukuran ubin 64×32 px dikunci** (bagian 2.2, ROADMAP 4b), keputusan pemilik setelah graybox dan uji HP Fase 1. Persegi dunia tetap 32×32 unit; aset dunia gelombang 1 dibuat dengan ukuran ini.
- **2026-10-13** — **Meluncur dan rem dipasang di jalan uji** (bagian 3.4), tetap usulan sampai dinilai di HP. `loper_agen_frames.tres` kini 48 animasi (15 kayuh, 5 melambat, 18 lempar, 5 meluncur, 5 rem), dibangun `tools/loper_art/bangun_frames.py` dari lima JSON sumber; PNG tidak diubah. Alas dan tapak roda tiap frame sama dengan santai frame 2, jadi sprite tidak melompat saat berganti kayuh, meluncur, dan rem (dites). Pemilihan pose mengikuti fisika (keputusan pemilik 2026-10-13, BALANCING 2).
- **2026-10-09** — **Melambat dan lempar koran dipasang di jalan uji** (bagian 3.2, 3.4), tetap usulan sampai dinilai di HP. `loper_agen_frames.tres` kini gabungan 38 animasi (15 kayuh, 5 melambat, 18 lempar) yang dibangun `tools/loper_art/bangun_frames.py` dari tiga JSON sumber; sel, titik pijak, dan offset sama dengan sheet kayuh. Hanya animasi pemain: proyektil, skor, dan arah lempar 90° tetap Fase 2 dan aset berikutnya.
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
