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
5. **Bayangan di tanah**: elips hitam dengan opasitas 28% (`#000000`, alpha 71), digeser 1 px ke kanan bawah, dipanggang di sprite. Bayangan lembut dari lighting dinamis ditambahkan di atasnya oleh engine.
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
- Glow dan cahaya lampu memakai cincin piksel semi-transparan bertumpuk atau light 2D engine, bukan gradien di dalam sprite.
- Partikel (debu roda, percikan genangan, kertas koran) digambar sebagai sprite piksel kecil dengan palet yang sama.
- Depth of field dan bloom dipakai ringan dan tidak pernah membuat objek gameplay kabur. Apakah semuanya jalan di renderer Compatibility di HP kelas bawah harus dicek di Fase 0 (bagian 7).

### 2.4 Palet induk (usulan)

Diambil dari sprite pemain produksi dan mock jalan. Dikunci setelah aset gelombang 1 (Fase 5). Satu file referensi palet (`assets/palette/loper_master.gpl` untuk Aseprite/LibreSprite, dan `scripts/ui/palette.gd` untuk warna UI) dibuat di Fase 0.

| Peran | Warna (terang · dasar · gelap) |
|---|---|
| Garis luar | `#0E0A1C` |
| Bayangan tanah | `#000000` alpha 28% |
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

| Waktu | Color grading |
|---|---|
| Pagi | Hangat dan terang, bayangan panjang tipis |
| Siang | Netral terang, kontras tinggi |
| Sore | Jingga, bayangan panjang |
| Malam | Biru gelap; lampu jalan, lampu sepeda, dan jendela menyala |

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

**Kendaraan:** sedan, angkot (minibus tanpa rak atap), dan bus kecil kota dua warna dengan papan trayek; semuanya punya kaca miring, sudut bodi tumpul, lekuk roda, pelek, dan lampu.

**Palet distrik** tambahan dari palet induk ada di papan "Palet per distrik" (ramp terang · dasar · gelap), dengan color grading ringan per distrik (contoh: perkampungan R ×1,04 B ×0,94, sungai R ×0,97 B ×1,04).

**Detail hidup di pinggir jalan:** jemuran bergoyang (kaus, celana, handuk, sarung; 8 frame), ayam jalan dan mematuk (8 frame, tiga warna lewat palette swap), asap warung (12 frame, tanpa garis luar karena VFX), kucing di tembok, layangan di kabel, **antena TV di atap** rumah dan ruko, pohon kelapa, klotok di sungai. Gerakannya pelan dan kontrasnya di bawah objek gameplay.

---

## 3. Karakter Pemain: Kemeja Agen

> **KEPUTUSAN (2026-10-07): Kemeja Agen dikunci sebagai base model untuk produksi.** Dipilih dari delapan varian di kanvas "Karakter Loper Koran". Varian tanpa tas selempang dipilih karena siluetnya lebih jelas.

### 3.1 Desain

- Topi putih **dipakai terbalik** dengan pita dan pet dongker, sehingga pet terbaca di tengkuk dari semua arah.
- Kemeja biru, celana dongker, sepatu gelap, kulit terang.
- **Tanpa tas selempang.** Koran dibawa di **tas kiri dan kanan boncengan** (merah bata) dan **keranjang depan**.
- Sepeda hijau, rangka dua nada, tanpa spakbor.
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
| Meluncur | Fase 1 | Pedal datar, kaki diam |
| Rem | Fase 1 | Badan sedikit mundur |
| Berhenti | Fase 4 (menangkap kucing) | Satu kaki turun ke tanah |
| Tabrakan / oleng | Fase 3 | Tidak jatuh dramatis; kerusakan hanya menghambat |

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
| Kayuh 3 kecepatan × 5 arah | ✅ | ✅ | Selesai 2026-10-07 |
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

### 6.9 VFX

| Aset | M2 | M3 |
|---|---|---|
| Debu roda | ✅ | ✅ |
| Garis kecepatan | ✅ | ✅ |
| Koran kena sasaran (bintang kecil) | ✅ | ✅ |
| Tip / koin muncul | ✅ | ✅ |
| Percikan genangan | ⬜ | ✅ |
| Hujan | ⬜ | ✅ |

---

## 7. Spesifikasi Teknis

### Resolusi & scaling (usulan, dikunci di Fase 0)

- **Landscape**, orientasi dikunci.
- **Tinggi dasar 360 piksel game**, lebar mengikuti rasio layar: 640 (16:9), 780 (19,5:9), 800 (20:9). Di HP 1080p pembesarannya ×3, di 720p ×2, di 1440p ×4. Sprite pemain didesain untuk ×3.
- Dua cara di Godot yang perlu dibandingkan di Fase 0:
  - stretch mode `canvas_items` dengan `scale_mode = integer` dan snap piksel 2D: sprite tetap tajam, HUD dan teks dirender di resolusi layar (seperti Brainy Dungeon).
  - stretch mode `viewport` dengan base 640×360 dan aspect `expand`: piksel paling konsisten, tapi HUD dan teks ikut beresolusi rendah.
- **Zona aman**: elemen gameplay penting tetap di area 16:9 tengah; HP yang lebih lebar menampilkan jalan lebih jauh ke depan dan ke belakang.
- HUD digambar di ukuran final mengikuti `design/DESIGN_SPEC.md`.

### Tekstur & performa

- **Ukuran tekstur maksimal 2048×2048** untuk kompatibilitas GPU HP lama.
- **Gabungkan ke atlas per konteks** (pemain, distrik, UI) untuk menurunkan draw call.
- **Fill rate** adalah leher botol utama di HP murah: hindari menumpuk banyak sprite transparan besar dan efek layar penuh.
- Sprite piksel diimpor **Lossless**, filter **Nearest**, tanpa mipmap.
- Renderer **Compatibility** (usulan) untuk HP kelas bawah. Cek di Fase 0 apakah light 2D, glow, dan partikel yang dibutuhkan jalan di renderer ini.
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

**Tahap 3 — Hidup dan modern (Fase 6–7).** Lighting dan waktu, VFX, warga, properti tambahan, bengkel.

**Tahap 4 — Distrik berikutnya.** Palet dan modul baru per distrik.

**Tahap 5 — Aset toko dan materi rilis.** Jangan ditinggal sampai minggu terakhir.

---

## 9. Sumber Aset & Lisensi

- **Pemain, rumah, dan rintangan dibuat sendiri** (bagian 4), karena harus konsisten dengan proyeksi dan palet.
- **UI, ikon, dan efek suara** boleh memakai set CC0 (misalnya Kenney.nl) kalau cocok dengan gaya. Lisensi aset dari OpenGameArt dan itch.io bervariasi per aset, jadi selalu periksa.
- **AI image generation** lemah untuk sprite yang harus konsisten di banyak arah dan frame. Kalau dipakai, hanya untuk konsep atau latar statis, dan periksa ketentuan lisensi komersialnya.

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
| **Total** | **~117** | **~450** |

Jumlah aset adalah penyebab paling umum game solo mangkrak. Penawarnya sudah dibangun ke rencana: pemain dirender dari model, rumah modular, variasi lewat palette swap, dan distrik baru hanya dibuat setelah perumahan terbukti seru.

---

## 11. Keputusan yang Perlu Diambil

- **Skala piksel (×3 atau ×4) dan ukuran ubin (64×32)**: dikunci setelah graybox Fase 1.
- **Stretch mode dan resolusi dasar** (bagian 7): dikunci di Fase 0.
- **Palet induk** (bagian 2.4): dikunci setelah aset gelombang 1.
- **Cara menampilkan rumah di sisi dekat**, yang hanya terlihat belakangnya.
- **Font HUD**: mock memakai Lexend + Lilita One (sama dengan Brainy Dungeon). Kunci atau pilih identitas sendiri.
- **Apakah sprite pemain dipoles manual** sebelum rilis, terutama wajah dari arah depan.

---

## Changelog Keputusan

- **2026-10-07** — **Usulan lingkungan** (bagian 2.6): bayangan berwarna per waktu, pemain setengah color grading, penampang jalan per distrik (lajur sepeda di perumahan, ruko 2 lajur, gang 2 ubin, talud sungai miring), palet enam distrik, detail pinggir jalan dan antena TV, tiga bentuk rumah perumahan, model sedan/angkot/bus kecil. Mock di `design/environment/`, renderer `tools/env_art`. Belum dikunci.

- **2026-10-07** — **Sprite produksi Kemeja Agen** (bagian 3.2): 15 animasi kayuh (3 kecepatan × 5 arah, 4 frame maju), sel 46×58, titik pijak (23, 46), SpriteFrames dicek memuat di Godot 4.3. Saat ngebut hanya sepeda yang bergoyang ±5°; badan pengendara stabil supaya kepala tidak bergetar di 12 fps.
- **2026-10-07** — **Audit sprite sebelum produksi**: roda depan tidak lagi terpotong saat setang belok (seluruh rakitan depan berputar bersama), condong dan setang saat belok dikecilkan, wajah dari depan memakai dua mata dan mulut, topi diberi pita dan pet dongker supaya terbaca terbalik, bahu dilebarkan supaya lengan terlihat dari belakang, rangka sepeda dua nada dan lebih tipis, pose ngebut dibuat lebih tegak dengan sadel terlihat.
- **2026-10-07** — **Kemeja Agen jadi base model** (bagian 3), tanpa tas selempang. Lima arah sesuai stick dan tiga pose kecepatan disetujui. Varian baju lain disimpan untuk item (bagian 3.3).
- **2026-10-06** — **Gaya pixel art disamakan dengan Brainy Dungeon** setelah dibandingkan di papan Banding: garis luar `#0E0A1C`, bayangan hitam 28%, warna dasar dominan, kepala lebih besar. Arah kayuh dibetulkan jadi maju.
- **2026-10-06** — **Pixel art isometrik** untuk karakter dan dunia (bagian 2), menggantikan eksplorasi karakter bergaya flat. Kepala dan topi harus bulat utuh.
- **2026-10-05** — **Isometrik 2:1 terkunci, jalan ke kanan atas**, sepeda di sepertiga kiri layar, kamera melihat sisi kanan sepeda, cahaya dari kiri atas dengan pintu dan jendela kontras, layar landscape.
