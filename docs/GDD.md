# Game Design Document — "Kring Kring!" (nama kerja: Loper Koran)

> **Dokumen pendamping**: [`ART_DIRECTION.md`](./ART_DIRECTION.md) (gaya visual & daftar aset), [`BALANCING.md`](./BALANCING.md) (angka tuning), [`ROUTE_DESIGN.md`](./ROUTE_DESIGN.md) (menyusun rute), [`DATA_SCHEMA.md`](./DATA_SCHEMA.md) (format data), [`SOUND_DESIGN.md`](./SOUND_DESIGN.md) (audio).
>
> **KEPUTUSAN (2026-10-07): dokumen ini sumber utama desain Loper Koran.** Perubahan desain ditulis di sini. Dokumen Claude Docs "Loper Koran — Ide Pengembangan Game" (versi 2026-10-07) adalah asal dokumen ini dan sekarang menjadi arsip yang tidak diperbarui lagi.
>
> **KEPUTUSAN (2026-10-09): judul game "Kring Kring!"**, dari bunyi bel sepeda. Pemain bisa membunyikan bel selama mengayuh sebagai tanda minta jalan (bagian 5.4). "Loper Koran" tetap dipakai sebagai nama kerja di repo dan dokumen.
>
> Dibanding dokumen asal, isinya sama; yang berubah hanya penomoran bagian, pemisahan skema data ke `DATA_SCHEMA.md`, dan bagian 2 yang merangkum prinsip dari keputusan yang sudah ada. Label **usulan** berarti belum diuji dan masih bisa berubah lewat prototype.

## 1. Pitch

Game mobile bergaya pixel art isometrik yang memodernisasi Paperboy NES: pemain mengayuh sepeda menyusuri jalan sambil melempar koran, dengan kecepatan yang bisa diatur, pelanggan berkepribadian, dan isi koran yang ikut memengaruhi dunia.

- **Judul:** **Kring Kring!** Bel sepeda adalah ciri khas game: bisa dibunyikan kapan saja untuk minta jalan (bagian 5.4).
- **Platform:** mobile saja dulu. Orientasi layar landscape, dipegang dengan dua tangan (bagian 15).
- **Sudut pandang:** isometrik 2:1 (terkunci) di layar landscape, seperti Paperboy aslinya yang semi-isometrik. Lemparan dan manuver sepeda didesain ulang untuk sudut ini.
- **Setting:** lokal Indonesia, misalnya gang kampung, warung, ojek, dan tukang bubur lewat. Jarang dipakai di game sejenis.
- **Pembeda dari Paperboy:** kecepatan diatur pemain, isi koran memicu misi sampingan, dan reputasi lingkungan memengaruhi pendapatan.
- **Acuan visual:** gaya pixel art Brainy Dungeon (garis 1 px, bayangan kecil, palet terbatas).

---

## 2. Prinsip Desain

> **Rangkuman, perlu dikonfirmasi (2026-10-07).** Prinsip di bawah tidak ditulis terpisah di dokumen ide, tapi muncul berulang di keputusan-keputusannya. Ditulis di sini supaya keputusan baru bisa dicek terhadapnya. Kalau disetujui, bagian ini jadi pilar resmi.

1. **Kecepatan adalah pilihan dengan konsekuensi.** Ngebut menaikkan skor dan mengejar tenggat, tapi mempersempit waktu bereaksi, menguras stamina, dan mempercepat keausan sepeda. Santai lebih aman, tapi tenggat tidak menunggu (bagian 5, 6, 12).
2. **Gagal tidak menghukum berlapis.** Misi gagal tidak mengurangi koin dan tidak menggagalkan hari, misi lanjutan lebih longgar, dan kerusakan sepeda hanya menghambat, tidak menghentikan permainan (bagian 10, 12).
3. **Adil dan bisa dibaca.** Rintangan punya pola yang bisa dipelajari, kerusakan memberi tanda peringatan dulu, petunjuk misi punya penanda visual minimal 2 detik, jalur utama selalu bersih, dan objek yang menutupi pemain dibuat semi-transparan (bagian 7, 10, 12, 15).
4. **Tanpa pay-to-win.** Satu mata uang yang hanya didapat dari bermain. Iklan selalu pilihan pemain, tidak pernah di tengah rute, dan seluruh game bisa dimainkan tanpa iklan (bagian 14).
5. **Indonesia yang hidup.** Gang kampung, warung, pasar, sawah, sungai, hajatan, dan tujuh belasan adalah bahan utama dunia, rintangan, dan misi, bukan sekadar dekorasi (bagian 7, 9, 10).

---

## 3. Tujuan Utama dan Alur Permainan

> **KEPUTUSAN:** tujuan utama menggabungkan tiga lapisan. Pelanggan tetap dan reputasi menjadi ukuran kemajuan harian, penjualan (uang) menjadi alat untuk servis dan upgrade, dan cerita memberi tujuan besar jangka panjang. Co-op dibuang.

| Tujuan | Cara kerja | Kelebihan | Risiko |
| --- | --- | --- | --- |
| Pelanggan | Jumlah pelanggan tetap dan reputasi lingkungan menjadi ukuran kemajuan. Pelanggan berhenti kalau koran sering meleset | Dekat dengan Paperboy asli dan menyambung ke reputasi, misi, dan distrik | Terasa menghukum kalau satu hari buruk menghapus banyak pelanggan |
| Penjualan | Mengejar target uang harian atau mingguan | Jelas dan mudah diukur | Mudah jadi grind dan kurang menyambung ke misi serta isi koran |
| Cerita | Uang dan reputasi menuju satu tujuan besar, misalnya membuka agen koran sendiri | Memberi arah dan akhir | Butuh penulisan dan perlu perencanaan alur yang matang |

### 3.1 Putaran satu hari (usulan)

1. Baca halaman depan koran: berita utama, misi sampingan, berita ringan.
2. Antar rute dalam batas waktu, sambil memilih mengambil misi sampingan atau tidak.
3. Lihat hasil hari itu: tip, pelanggan baru atau berhenti, perubahan reputasi.
4. Ke bengkel untuk servis dan upgrade dengan uang hari itu.
5. Hari berikutnya: headline dan konsekuensi misi kemarin mengubah rute.

### 3.2 Yang perlu diputuskan

- Cerita besar dan akhirnya: premis diputuskan (Tabungan Kuliah ditambah Menyambung Hidup Keluarga), bab dan akhir masih usulan. Lihat [`STORY.md`](./STORY.md).
- Ada game over atau tidak, atau hari buruk hanya mengurangi pelanggan.
- Ada target harian atau tidak.

---

## 4. Core Loop

Inti Paperboy tetap dipertahankan: sepeda terus berjalan sementara pemain mengantar koran dengan presisi, lalu ditambah beberapa lapisan baru.

### 4.1 Lapisan baru

- **Lemparan dengan arah dan kekuatan:** jarak lemparan diatur pemain, bukan sekadar lurus. Kena kotak surat atau teras dapat nilai penuh, kena jendela bisa jadi bonus atau penalti (belum diputuskan).
- **Combo dan momentum:** antaran beruntun yang berhasil menaikkan pengali skor. Satu kesalahan memutus rantai.
- **Rute bercabang:** pemain memilih gang kecil yang lebih cepat tapi berbahaya, atau jalan utama yang aman tapi panjang.
- **Tenggat rute:** tiap rute punya batas waktu, jadi terlalu santai punya harga (bagian 5).

### 4.2 Dua sisi jalan

> **KEPUTUSAN:** kiri pelempar = **sisi seberang** (fasad rumah, kiri atas layar), kanan pelempar = **sisi dekat** (kanan bawah layar). Kiri dan kanan selalu mengikuti arah pelempar, bukan arah layar, di kontrol, radar, dokumen, maupun data misi.

Pelanggan ada di kiri dan kanan jalan, dan posisi jalur menentukan seberapa mudah melempar ke tiap sisi.

- Swipe ke kiri atau kanan menentukan sisi lemparan.
- Posisi jalur jadi strategi: di tengah bisa menjangkau dua sisi tapi lemparan lebih jauh, sedangkan merapat ke satu sisi membuat lemparan ke sana lebih dekat tapi sisi seberang sulit dijangkau.
- Dua sisi bisa berbeda isi, misalnya kiri pelanggan dan kanan bukan pelanggan, atau kiri rumah dan kanan toko. Rintangan juga datang dari dua arah.
- Antaran bergantian kiri-kanan secara berurutan bisa memberi bonus combo zigzag.

### 4.3 Radar rumah pelanggan

Radar menandai rumah pelanggan yang akan datang di kiri dan kanan, supaya pemain bisa ancang-ancang berpindah jalur.

- Berupa strip tipis di tepi kiri dan kanan layar, bukan mini-map di sudut, supaya hemat ruang layar. Strip kiri untuk sisi seberang, strip kanan untuk sisi dekat.
- Ikon rumah pelanggan bergeser mendekati pemain dan berubah warna saat sudah masuk jangkauan lempar.
- Ikon bisa dibedakan antara pelanggan biasa, pelanggan yang memberi tip, dan target misi sampingan.
- Jangkauan radar bisa jadi upgrade, dan mode bantu bisa menampilkan jangkauan penuh. Tanpa radar, pemain membaca lingkungan sendiri.

Tampilan radar dan HUD lainnya: `design/DESIGN_SPEC.md` bagian 3 (radar di 3.4).

---

## 5. Kecepatan Sepeda dan Kontrol Mobile

Di NES kecepatan sepeda praktis statis; di game ini pemain mengatur sendiri kecepatannya, dan pilihan itu memengaruhi lemparan, risiko, dan skor.

### 5.1 Efek kecepatan

- **Lemparan:** koran mewarisi kecepatan sepeda. Ngebut membuat koran melayang lebih jauh ke depan sehingga harus dilempar lebih awal. Pelan membuat bidikan lebih mudah tapi tempo melambat.
- **Risiko dan hadiah:** cepat menaikkan pengali skor dan mengejar tenggat, tapi waktu bereaksi terhadap rintangan lebih sempit. Pelan lebih aman, tapi tenggat rute tidak menunggu.
- **Anjing:** mengejar sesuai kecepatan pemain, jadi melambat di dekat pagar berbahaya.

Tiga tingkat kecepatan yang terlihat di sprite pemain: **santai** (stick netral), **cepat** (stick setengah ke atas), dan **ngebut** (stick penuh ke atas, pengendara berdiri dari sadel). Angka awalnya ada di `BALANCING.md` bagian 2.

### 5.2 Skema kontrol landscape

> **KEPUTUSAN (dikunci di instruksi project, 2026-10-06):** stick melayang di kiri, swipe di kanan, tanpa tombol rem terpisah. Rasa kontrol di HP asli masih harus diuji (bagian 17).

- **Jempol kiri** memegang stick analog melayang di zona kiri bawah. Stick muncul di tempat jempol menyentuh. Kiri-kanan memindah sisi (kiri sisi seberang, kanan sisi dekat, mengikuti arah pelempar, bukan arah layar). Atas untuk kayuh keras, netral kayuh santai, bawah untuk melambat dan meluncur. Diagonal bekerja bersamaan, misalnya atas-kiri untuk ngebut sambil belok.
- **Rem tanpa tombol terpisah:** stick ditarik penuh ke bawah dan ditahan, sepeda berhenti perlahan. Jempol tidak perlu pindah, jadi kemudi tetap terjaga. Ambang rem dibuat di ujung bawah supaya sepeda tidak berhenti tanpa sengaja saat belok.
- **Jempol kanan** melempar dengan swipe kiri atau kanan di mana saja di sisi kanan layar: kiri ke sisi seberang, kanan ke sisi dekat. Swipe panjang melempar kencang dan jauh, swipe pendek pelan dan dekat. Garis bidik putus-putus muncul selama jari ditahan, koran terlempar saat jari dilepas.
- **Bel (usulan, 2026-10-09):** tombol bel bulat di pojok kanan bawah, di dalam zona swipe. Sentuhan yang dimulai di tombol dibaca sebagai bel, bukan swipe (bagian 5.4).
- Alternatif yang tidak dipilih: 3 tingkat gigi lewat swipe naik-turun. Lebih sederhana, tapi kurang halus dibanding stick analog.

Mock tampilan dan zona kontrol: kanvas "Loper Koran — Kamera dan Kontrol", papan Kontrol landscape.

### 5.3 Mode bantu dan opsi kidal

- **Mode bantu:** opsi kecepatan otomatis untuk pemain santai, supaya kontrol tambahan tidak jadi penghalang. Lemparnya juga otomatis: tap di sisi layar yang ada rumahnya, ke kotak surat terdekat di sisi itu.
- **Opsi kidal:** zona kiri dan kanan bisa ditukar.

### 5.4 Bel: "Kring Kring!" (usulan, 2026-10-09)

Bel memberi nama pada game. Pemain membunyikannya sebagai tanda "permisi, mau lewat", seperti loper sungguhan di gang. Semua angka di bawah usulan dan disetel lewat prototype.

- **Kontrol:** tombol bel 40×40 piksel dasar di pojok kanan bawah (opsi kidal: kiri bawah). Zona tapnya lingkaran radius 28; sentuhan yang dimulai di zona ini membunyikan bel dan tidak memulai swipe. Ukuran dan posisi di `design/DESIGN_SPEC.md` 3.8.
- **Satu ketukan = "kring"** (sekitar 0,4 detik). **Ketuk lagi selama teks masih tampil = "kring kring!"**, bunyi dobel yang menjadi judul game. Setelah dua bunyi, bel jeda sekitar 1 detik; tombol menampilkan sisa jeda sebagai cincin. Jeda ini menjaga bel tidak dibunyikan terus-menerus, karena bunyinya akan didengar ribuan kali (`SOUND_DESIGN.md` 1).
- **Efek ke dunia:** warga dan hewan yang bisa minggir dan berada dalam jangkauan di depan sepeda (sekitar 4 ubin) menampilkan ikon "!", lalu menepi ke pinggir jalan. Contoh: pejalan kaki, jogger, anak main bola, ayam, kucing. Anjing penjaga dan kendaraan tidak terpengaruh, supaya rintangan utama tetap harus dihindari. Rintangan mana yang bereaksi diatur per jenis rintangan (bagian 9.3, `ROUTE_DESIGN.md`).
- **Tanpa suara tetap terbaca:** setiap bunyi bel selalu disertai efek visual di atas setang (garis getar dan teks "KRING!"), karena banyak pemain HP bermain tanpa suara.
- **Upgrade dan kosmetik:** upgrade bel menambah jangkauan (bagian 11). Bel kosmetik mengganti warna dan bunyi, tanpa mengubah fungsi (bagian 13, `SOUND_DESIGN.md` 3.3).
- **Aset:** `design/bel/` (tombol, efek, ikon "!"), dibuat dengan `tools/ui_art/bel.py`. Mock di kanvas "Loper Koran — Kamera dan Kontrol", papan Bel · Kring Kring!.

---

## 6. Stamina dan Medan

Mengayuh kencang menguras stamina dan meluncur mengisinya kembali, jadi pemain terus menimbang kapan ngebut dan kapan menyimpan tenaga.

- **Stamina:** mengayuh cepat menguras energi. Turunan dan meluncur tanpa mengayuh mengisinya lagi. Rute yang punya tanjakan dan turunan membuat pengaturan tenaga makin penting.
- **Tanjakan kecil dan lompatan:** butuh kecepatan cukup untuk melewati selokan atau tumpukan karung.
- **Genangan dan kerikil:** kalau terlalu cepat, sepeda selip.
- **Tikungan di gang:** melambat dulu supaya tidak menabrak pot atau tukang sayur.

---

## 7. Rintangan dan Dunia yang Hidup

Rintangan tidak sebatas anjing dan mobil: tiap rintangan punya pola perilaku sendiri yang bisa dipelajari pemain.

- **Pejalan dan aktivitas warga:** jogger, anak main bola, skateboarder, tukang sayur keliling.
- **Kondisi jalan:** genangan saat hujan, jalan ditutup karena perbaikan.
- **Siklus siang, sore, malam:** mengubah visibilitas dan jenis rintangan.
- **Cuaca:** hujan dan kondisi lain memengaruhi jalan dan rute yang aman.
- **Pengaruh headline:** berita hari itu bisa mengubah dunia, misalnya festival membuat jalanan ramai atau berita banjir membuat jalan tertentu tergenang (bagian 10.7).

Pola perilaku rintangan per distrik ada di bagian 9.3; aturan menempatkannya di rute ada di `ROUTE_DESIGN.md`.

---

## 8. Pelanggan dan Reputasi Lingkungan

Setiap rumah punya penghuni dengan kebiasaan sendiri, dan reputasi pemain di lingkungan menentukan pendapatan serta akses ke area baru.

- **Kepribadian pelanggan:** ada yang cerewet kalau koran jatuh di rumput, ada yang memberi tip kalau koran mendarat tepat di teras, ada yang berhenti langganan kalau koran meleset dua kali.
- **Reputasi:** akumulasi dari antaran yang tepat, misi sampingan yang berhasil, dan kejadian di rute. Reputasi tinggi menaikkan pendapatan dan membuka distrik baru.
- **Hubungan dengan misi:** hasil misi sampingan membawa konsekuensi ke hari berikutnya (bagian 10.7).

---

## 9. Distrik dan Variasi Lingkungan

Game punya beberapa distrik dengan aturan main berbeda yang dibuka bertahap lewat reputasi lingkungan, sehingga pemain terus menemui tantangan baru.

### 9.1 Pembukaan bertahap

- Pemain mulai di distrik pertama yang ritmenya tenang. Distrik berikutnya dibuka lewat reputasi lingkungan (bagian 8).
- Tiap distrik baru memperkenalkan satu atau dua rintangan atau aturan baru, lalu distrik lanjutan menggabungkannya.
- Distrik pertama hanya punya pelanggan di satu sisi jalan (sisi seberang, karena fasad dan pintunya terlihat di isometrik) sebagai tutorial alami, distrik lanjutan memakai dua sisi (bagian 4.2).
- Urutan usulan: perumahan, perkampungan, ruko, lalu distrik lain di tabel. Urutan ini belum final. Apartemen dan kampus sudah dibuang.

### 9.2 Daftar distrik

| Distrik | Suasana | Aturan pembeda | Rintangan khas | Ritme |
| --- | --- | --- | --- | --- |
| Perumahan | Jalan lurus dan teratur, rumah seragam, kotak surat di tepi jalan | Portal satpam buka-tutup dan polisi tidur, tanpa pagar sehingga lemparan terbuka | Anjing penjaga, mobil keluar garasi, penghuni menyiram halaman, tong sampah di tepi jalan, mobil tamu parkir di bahu jalan | Tenang, cocok untuk distrik awal |
| Perkampungan | Gang sempit dan berkelok, rumah rapat | Ngebut berbahaya, banyak jalan pintas, lemparan jarak dekat | Jemuran melintang, selokan terbuka, ayam menyeberang, anak main, gerobak bakso, pos ronda di tikungan | Sedang, banyak percabangan |
| Ruko | Jalan lebih lebar dengan lalu lintas motor dan angkot | Tujuan antar adalah kios dan toko yang punya jam buka-tutup | Pedagang kaki lima, motor parkir berjajar, angkot berhenti mendadak, truk bongkar muat, pejalan menyeberang sembarangan | Paling cepat dan padat |
| Pasar tradisional | Lorong ramai, los dan tenda terpal | Pelanggan adalah pedagang dan targetnya meja lapak, bukan kotak surat. Koran yang mengenai barang dagangan membuat pedagang marah dan reputasi turun, sedangkan yang mendarat di meja memberi bonus. Lapak dadakan membuka dan menutup jalur, jadi jalan yang aman berubah tiap kali lewat | Becak dan gerobak, pedagang menyeberang tiba-tiba, kuli panggul membawa karung, keranjang jatuh dari lapak, genangan air pasar, tenda terpal rendah | Padat dan kacau |
| Jalan desa dan persawahan | Jalan tanah, sawah terbuka, rumah berjauhan | Jalan tanah licin saat hujan, rumah berjauhan sehingga lemparan lebih jauh | Kerbau, traktor, kubangan lumpur, rombongan bebek, gabah dijemur di tepi jalan, parit irigasi dengan jembatan bambu | Lambat dan sepi, jarak antar rumah jauh |
| Pinggir sungai besar | Perumahan padat di sisi seberang, sungai besar di sisi dekat | Pelanggan terutama di sisi seberang, sesekali ada di dermaga atau perahu di sisi dekat. Terlalu merapat ke tepi sungai membuat sepeda tergelincir dan melambat | Jembatan sempit, perahu lewat dan sandar, tali tambat melintang jalan, jemuran melintang, air pasang naik ke jalan, warga mencuci di tepian | Sedang, jalur sempit di dekat tepi |

Baris pasar, desa, dan pinggir sungai masih usulan awal dan belum diuji. Di baris pinggir sungai, perumahan ada di sisi seberang dan sungai di sisi dekat, sehingga sisi dekat bebas dari punggung rumah.

### 9.3 Rintangan khas per distrik: pola perilaku (usulan)

- **Perumahan:** anjing penjaga mengejar sesuai kecepatan pemain dan berhenti di batas halaman. Mobil keluar garasi memberi tanda lampu mundur sebelum bergerak. Selang penghuni yang menyiram membuat jalan licin sesaat. Tong sampah di hari angkut mempersempit jalur, dan mobil tamu di bahu jalan menutupi kotak surat.
- **Perkampungan:** jemuran melintang menutupi sebagian lemparan jarak dekat. Selokan terbuka butuh kecepatan cukup untuk dilompati. Ayam menyeberang acak tapi pelan, anak main di tengah gang, dan gerobak bakso yang lewat memblokir gang sempit. Warga berkumpul di pos ronda sehingga tikungan menyempit.
- **Ruko:** pedagang kaki lima mempersempit tepi jalan dan motor parkir berjajar menutupi kotak surat. Angkot berhenti mendadak di depan pemain, truk bongkar muat menutup satu sisi sementara, dan pejalan menyeberang sembarangan di jam ramai.
- **Pasar tradisional:** becak dan gerobak bergerak lambat dan lebar. Kuli panggul sulit berhenti, keranjang jatuh dari lapak ke jalan, dan genangan air pasar membuat sepeda selip. Tenda terpal yang menggantung rendah menutup pandangan.
- **Jalan desa dan persawahan:** kerbau melintas pelan dan tidak bisa dipaksa minggir, traktor lambat memenuhi jalan sempit, dan kubangan lumpur membuat selip. Rombongan bebek menyeberang, gabah dijemur di tepi jalan, dan parit irigasi hanya bisa dilewati lewat jembatan bambu sempit.
- **Pinggir sungai besar:** jembatan sempit hanya muat satu jalur, perahu lewat dan sandar di sisi dekat, dan tali tambat melintang di jalan. Jemuran melintang di antara rumah padat di sisi seberang. Air pasang naik ke jalan dan menggenang di sisi dekat, sementara warga yang mencuci di tepian tidak melihat sepeda.

### 9.4 Mengurangi rasa bosan di dalam satu distrik

- **Rute dari segmen yang diacak:** potongan rute dibuat tangan, urutannya berubah, jadi rute tidak bisa dihafal (`ROUTE_DESIGN.md`).
- **Waktu dan cuaca:** pagi sepi dengan tukang sayur, siang terik, sore ramai anak main, malam gelap dan butuh lampu, plus hujan dan banjir.
- **Kejadian khas Indonesia:** lomba 17 Agustus, hajatan dengan tenda yang menutup jalan, pasar kaget, takjil saat Ramadan. Headline koran bisa jadi pemicunya.
- **Momen khas per distrik:** misalnya kejar-kejaran dengan anjing besar di kampung, atau menyeberang jalan raya yang ramai di ruko.
- **Detail latar yang hidup:** jemuran yang bergoyang, ayam mematuk di halaman, kucing tidur di teras, asap dari warung atau gerobak, dan layangan di langit. Semuanya dekorasi yang tidak menghalangi jalur, dijaga tetap terbaca dan tidak memakai penanda misi, supaya tidak mengganggu pandangan ke rintangan dan petunjuk (ART_DIRECTION 6.10).
- **Palet warna berbeda per distrik dan waktu,** dengan gaya pixel yang sama, supaya pemain langsung tahu sedang di mana. Warna bayangan ikut berubah (ART_DIRECTION 2.5).

### 9.5 Yang perlu diputuskan

- Apakah pemain bebas memilih distrik yang sudah terbuka tiap hari, atau urutannya tetap.
- Syarat reputasi untuk membuka tiap distrik.
- Apakah kejadian musiman mengikuti tanggal asli di dunia nyata atau diatur oleh game.

---

## 10. Isi Koran dan Misi Sampingan

Headline koran hari itu menjadi pemicu misi sampingan dan pengubah suasana dunia, sehingga tiap hari terasa berbeda tanpa harus membuat level baru.

### 10.1 Halaman depan (3 headline)

1. **Berita utama:** memengaruhi dunia game, misalnya festival membuat jalanan ramai atau banjir membuat jalan tertentu tergenang.
2. **Misi sampingan:** satu headline yang bisa dikerjakan sambil mengantar.
3. **Berita ringan:** humor saja, misalnya "Ayam Tetangga Juara Lomba Berkokok".

Teksnya dibuat singkat supaya cepat dibaca sebelum berangkat, mengingat ruang layar mobile terbatas. Cara menulisnya: `CONTENT_GUIDE.md`.

### 10.2 Contoh misi: kucing hilang

- Headline: "Kucing Bu Ratmi Hilang Sejak Semalam". Pengantaran tetap tugas utama, misi ini bonus yang boleh diambil atau dilewati.
- Kucing terlihat sekilas di pojok layar: di atas atap, di bawah mobil, atau di balik pot. Pemain harus memperhatikan, tidak hanya fokus melempar.
- Pelanggan memberi petunjuk saat koran dilempar tepat, misalnya "tadi ada kucing lewat ke arah warung". Ketepatan lemparan jadi berguna di luar skor.
- Jejak kecil: jejak kaki, suara meong yang makin keras saat mendekat, mangkuk makan di tempat tak terduga.
- Menangkap kucing dengan melambat dan menepi di dekatnya, sehingga pemain memilih antara menjaga tempo dan berhenti.
- Ngebut membuat petunjuk mudah terlewat. Terlalu santai melampaui tenggat rute.

Konsekuensi: kucing ketemu, Bu Ratmi jadi pelanggan setia dan memberi tip. Gagal, headline besoknya "Kucing Bu Ratmi Belum Ditemukan" dan ia mungkin berhenti langganan. Ini menyambung dengan sistem reputasi.

**Yang perlu dijaga:** petunjuk punya penanda visual halus (kilau kecil atau ekor yang bergerak) dan misi punya batas waktu yang adil, supaya pemain tidak frustrasi.

Variasi misi lain: antar paket untuk satu rumah tertentu karena alamatnya tertukar, cari pemilik dompet yang jatuh, kumpulkan tanda tangan untuk petisi lingkungan, tangkap pencuri sandal yang terus muncul di rute.

### 10.3 Aturan umum misi (usulan, belum diuji)

Semua angka di bagian 10.3–10.8 masih usulan dan disetel lewat prototype.

- Satu halaman depan per hari: satu berita utama (efek dunia), satu misi sampingan, satu berita ringan. Awalnya maksimal satu misi aktif per hari, naik jadi dua setelah distrik ketiga terbuka.
- Misi diambil di layar koran sebelum berangkat lewat tombol "Ambil" atau "Lewati". Melewati misi tidak ada penalti.
- Misi tidak pernah menggantikan rute utama, dan gagal misi tidak menggagalkan hari.
- Batas misi dihitung dalam jumlah rumah atau bagian rute, bukan detik nyata, supaya pemain yang santai tidak dihukum. Tenggat rute harian tetap berlaku.
- Petunjuk dan target selalu punya penanda visual halus (kilau dua frame, ekor bergerak, bayangan bergerak) dan tetap terlihat minimal 2 detik, ditambah satu isyarat suara.
- Tidak ada tombol baru. Misi memakai mekanik yang sudah ada: melambat dan menepi lewat stick, lemparan lewat swipe, dan memilih sisi seberang atau dekat. Aksi seperti mengambil atau menyerahkan terjadi otomatis saat sepeda berhenti di zona kecil di sekitar target.
- Posisi target selalu ditulis dengan sisi seberang (kiri pelempar) atau sisi dekat (kanan pelempar), konsisten dengan kontrol.
- Pemilihan misi harian: dari katalog sesuai distrik dan reputasi minimum, lanjutan kemarin diprioritaskan, dan misi yang sama tidak muncul lagi selama masa jeda kecuali sebagai lanjutan. Hasil pemilihan memakai seed per hari supaya mudah diuji ulang.

**Alur satu hari dengan misi**

1. Layar koran menampilkan tiga headline. Misi sampingan punya ringkasan satu baris dan tombol Ambil atau Lewati.
2. Di rute, ikon misi kecil dan progres tampil di HUD, misalnya "Kucing 0/1" dan sisa rumah.
3. Petunjuk dan target muncul sesuai definisi misi. Banner singkat muncul saat misi selesai atau gagal.
4. Layar hasil harian merekap misi, hadiah, dan efeknya ke pelanggan.
5. Konsekuensi disimpan sebagai flag. Headline hari berikutnya membaca flag itu.

### 10.4 Enam template misi

| Template | Intinya | Mekanik yang dipakai | Parameter utama |
| --- | --- | --- | --- |
| Cari | Menemukan hewan, benda, atau orang lewat petunjuk | Perhatian, melambat, menepi | Jumlah titik, radius tangkap, lama berhenti |
| Antar khusus | Mengantar barang selain koran ke satu rumah tertentu | Lemparan tepat, memilih sisi | Rumah tujuan, jenis barang, toleransi mendarat |
| Lempar khusus | Mengenai atau menghindari target tertentu dengan lemparan | Swipe, garis bidik | Target, jumlah kesempatan, target bergerak atau diam |
| Kumpul | Berhenti di beberapa titik untuk mendapat sesuatu | Melambat, menepi | Jumlah titik, rumah mana, lama berhenti |
| Kejar | Menghentikan atau menggiring sosok yang bergerak | Kecepatan, lemparan | Kecepatan sosok, jumlah kemunculan, titik buntu |
| Jaga | Membawa barang rapuh atau cepat rusak sepanjang rute | Stick halus, hindari lubang dan rem mendadak | Batas guncangan, durasi, laju kerusakan |

Skema data misi (kolom, contoh, format file): `DATA_SCHEMA.md` bagian 1.

### 10.5 Hadiah dan akibat gagal (standar)

| Tingkat | Koin | Reputasi distrik | Tambahan |
| --- | --- | --- | --- |
| Kecil | Sekitar 3 kali ongkos satu pengantaran (45) | +1 | Tip dari pihak yang ditolong |
| Sedang | Sekitar 5 kali ongkos satu pengantaran (75) | +2 | Pelanggan baru atau pelanggan jadi setia |
| Besar | Sekitar 8 kali ongkos satu pengantaran (120) | +3 | Kosmetik sepeda atau julukan, dan hitungan untuk milestone Cerita |

Gagal tidak pernah mengurangi koin. Paling berat hanya reputasi satu poin di distrik itu, dan hanya bila misinya melibatkan satu pelanggan tertentu.

### 10.6 Katalog misi (18 misi, tiga per distrik)

| Misi | Template | Cara main | Hadiah, gagal, dan lanjutan |
| --- | --- | --- | --- |
| P1 Perumahan: Kucing Bu Ratmi Hilang | Cari | Kucing terlihat di tiga titik berbeda di sisi seberang (atap, bawah mobil tamu, balik pot), tiap 3 sampai 4 rumah. Lemparan tepat ke rumah pelanggan memberi petunjuk arah. Melambat dan menepi dalam jarak 2 ubin selama 1,5 detik di titik terakhir menangkap kucing. Batas 12 rumah. | Sedang. Bu Ratmi jadi pelanggan setia dan memberi tip tetap. Gagal: besok headline "Kucing Bu Ratmi Belum Ditemukan", dan gagal dua hari berturut-turut membuatnya berhenti langganan. |
| P2 Perumahan: Paket Salah Alamat di Blok C | Antar khusus | Satu paket muncul di keranjang. Nomor tujuan ada di headline dan terbaca di kotak surat. Paket harus mendarat di kotak surat tepi jalan. Salah rumah mengembalikan paket dan memberi satu kesempatan lagi. | Kecil. Gagal: rumah yang salah kesal (reputasi -1), dan paket diantar besok sebagai lanjutan dengan batas lebih longgar. |
| P3 Perumahan: Pencuri Sandal Resahkan Warga | Kejar | Sosok kecil membawa sandal dan menyeberang jalan tiga kali, tiap sekitar 6 rumah. Kena lemparan koran membuatnya tersandung dan tertangkap. Kemunculan ketiga selalu dekat portal satpam yang menutup jalannya. | Sedang, dan satpam memberi tip. Gagal: besok headline "Sandal Hilang Lagi" dan satu pelanggan acak kehilangan sandal (reputasi -1). |
| K1 Perkampungan: Dompet Jatuh di Gang | Cari | Dompet tergeletak di balik jemuran dan diambil dengan menepi. Inisial di dompet cocok dengan satu dari tiga pelanggan di sisa rute. Pelanggan yang benar bereaksi saat koran mendarat. Batas 10 rumah. | Sedang dan pemilik menjadi pelanggan setia. Gagal: besok headline "Dompet Belum Kembali", pemilik tidak menurunkan reputasi. |
| K2 Perkampungan: Petisi Perbaikan Selokan | Kumpul | Empat rumah bertanda kertas petisi. Pemain menepi dan berhenti 1 detik di tiap rumah untuk tanda tangan. Selokan terbuka dan jemuran menyulitkan menepi. Batas satu ruas gang sampai pos ronda. | Sedang, dan setiap rumah yang tanda tangan lebih loyal (+1 reputasi tersembunyi). Gagal: tanpa penalti, petisi muncul lagi besok dengan target tiga rumah. |
| K3 Perkampungan: Ayam Jago Pak RT Kabur | Kejar | Ayam berlari menjauh dari koran yang jatuh di dekatnya. Pemain menggiring ayam ke arah pos ronda dengan menjatuhkan koran di belakangnya. Ayam tidak bisa dipaksa kalau pemain ngebut. | Kecil dan Pak RT memberi bonus tip. Gagal: besok ayam muncul lagi di jalur acak sebagai rintangan. |
| R1 Ruko: Kue Pesanan Jangan Penyok | Jaga | Antar kardus kue dari satu toko ke toko lain di ujung rute. Kardus punya 3 batang guncangan. Lubang, rem mendadak, dan ngebut di tikungan mengurangi satu batang. Habis berarti kue hancur. | Sedang. Gagal: toko komplain (reputasi -1), tanpa lanjutan. |
| R2 Ruko: Paket Harus Tiba Sebelum Toko Tutup | Antar khusus | Paket untuk satu toko yang akan menutup di tengah rute (memakai aturan jam buka-tutup distrik). Lemparan harus tepat ke kios sebelum rolling door turun. Tanda tutup berkedip dua rumah sebelumnya. | Sedang. Gagal: toko tutup dan paket diantar besok dengan tambahan hadiah kecil. |
| R3 Ruko: Helm Tertinggal di Angkot | Lempar khusus | Angkot biru muncul dari belakang dan melaju pelan di sisi dekat. Pemain menyamai kecepatannya lalu melempar helm ke jendela terbuka. Dua kesempatan, angkot berhenti mendadak di antara kesempatan. | Kecil dan sopir jadi pelanggan tetap di jam ramai. Gagal: helm hilang, tanpa penalti. |
| M1 Pasar: Lomba Meja Terbersih | Lempar khusus | Enam meja lapak diberi bendera. Koran yang mendarat di meja berbendera dihitung, empat dari enam berarti menang. Mengenai barang dagangan tetap menurunkan reputasi seperti aturan pasar. | Besar bila kena lima atau enam, sedang bila empat. Gagal: tanpa penalti tambahan selain barang yang terkena. |
| M2 Pasar: Es Balok untuk Lapak Ikan | Jaga | Es balok meleleh makin cepat saat sepeda berhenti dan makin lambat saat bergerak. Lorong padat memaksa pemain melambat, jadi harus memilih jalur terbuka. Antar ke lapak ikan di ujung lorong. | Sedang. Gagal: ikan basi, pedagang ikan reputasi -1 dan besok tidak memesan koran. |
| M3 Pasar: Anak Ayam Lepas dari Keranjang | Kumpul | Empat anak ayam tersebar di lorong dan bersuara ciap. Melewati mereka dengan pelan menggiring ke keranjang di sisi dekat. Terlalu cepat membuat mereka kabur. | Kecil dan pedagang unggas jadi pelanggan. Gagal: sisa anak ayam muncul sebagai rintangan kecil besok. |
| D1 Desa: Kerbau Pak Sarmin Tersesat | Cari | Kerbau berada di sawah sisi seberang dengan jejak lumpur dan bunyi lonceng sebagai petunjuk. Setelah ditemukan, kerbau mengikuti sepeda selama kecepatan di bawah santai sampai ke kandang di ujung rute. | Besar. Gagal: besok headline "Kerbau Pak Sarmin Masih Hilang" dan kerbau menjadi rintangan yang melintas. |
| D2 Desa: Surat dari Perantauan | Antar khusus | Surat untuk rumah terjauh di rute, hanya bisa dicapai dengan swipe panjang. Hujan turun di paruh kedua rute sehingga jalan licin dan lemparan lebih sulit. | Sedang dan penerima jadi pelanggan setia. Gagal: surat diantar besok sebagai lanjutan. |
| D3 Desa: Hujan Datang, Gabah Belum Ditutup | Lempar khusus | Awan gelap mendekat dengan penanda di HUD. Lempar terpal ke tiga halaman gabah di tepi jalan sebelum hujan turun. Batas 8 rumah. | Sedang. Gagal: gabah basah, satu pelanggan petani mengeluh (reputasi -1). |
| S1 Sungai: Perahu Pak Ujang Hanyut | Lempar khusus | Perahu kosong hanyut di sungai di sisi dekat. Lempar tali tambat ke tiang dermaga di depannya, dua kesempatan. Perahu bergerak sehingga perlu memperkirakan arah. | Sedang dan Pak Ujang jadi pelanggan di dermaga. Gagal: besok perahu muncul sebagai rintangan di jalur sungai. |
| S2 Sungai: Pasang Naik, Antar Obat ke Rumah Panggung | Antar khusus | Syarat berita utama air pasang. Air menggenang di sisi dekat sehingga pemain harus tetap di sisi seberang. Lempar obat ke teras rumah panggung yang tinggi dengan lemparan sedang. | Besar. Gagal: obat diantar besok dan penerima menunggu, reputasi sungai -1. |
| S3 Sungai: Bendera Tujuh Belasan Tersembunyi | Cari | Syarat berita utama 17 Agustus. Lima bendera tersembunyi di sepanjang rute dengan kilau kecil. Cukup melewatinya dalam jarak 2 ubin, tanpa harus berhenti. | Sedang dan dekorasi bendera tersisa di distrik sampai akhir pekan. Gagal: tanpa penalti. |

### 10.7 Berita utama dan konsekuensi lanjutan

**Berita utama: efek dunia (usulan)**

| Headline | Efek di game | Distrik paling terdampak |
| --- | --- | --- |
| Hajatan Warga | Tenda dan tamu memenuhi tepi jalan, pejalan lebih banyak, rumah hajatan memesan koran ganda sehari | Perkampungan, perumahan |
| Hujan Deras Seharian | Genangan dan jalan licin, selip lebih mudah, pandangan lebih redup | Desa, sungai, pasar |
| Air Pasang Naik | Air menggenang di sisi dekat jalan sungai, jalur aman menyempit | Pinggir sungai |
| Tujuh Belasan | Bendera dan dekorasi, lomba kecil, hadiah misi lebih besar | Semua distrik |
| Pasar Kaget Digelar | Lapak dadakan di jalan yang biasanya biasa, jalur berubah | Perumahan, ruko |
| Jalan Sedang Diperbaiki | Satu sisi tertutup, jalur menyempit dan pengalihan | Perumahan, ruko |
| Panen Raya | Banyak traktor dan gabah di tepi jalan | Desa |
| Mati Lampu Semalam | Pencahayaan redup dan jarak pandang pendek, lemparan lebih sulit dibidik | Perkampungan, perumahan |

**Konsekuensi dan flag lanjutan**

- Tiap misi menulis satu flag saat selesai atau gagal. Headline hari berikutnya memilih teks dan misi lanjutan berdasarkan flag itu, seperti contoh kucing hilang.
- Misi lanjutan memakai batas lebih longgar, jadi pemain yang gagal punya kesempatan kedua yang lebih mudah, bukan hukuman berlapis.
- Pelanggan setia dari misi menyumbang ke milestone Pelanggan dan Cerita.
- Misi yang gagal dua hari berturut-turut berhenti dan tidak muncul lagi selama masa jeda, supaya tidak terasa menekan.

### 10.8 Urutan pengerjaan dan cara menguji misi (usulan)

Urutan pengerjaan:

1. Layar koran dengan satu misi tertanam (P1 kucing hilang) dan HUD misi.
2. Template Cari dan Antar khusus (P1, P2) beserta flag dan headline lanjutan.
3. Template Lempar khusus dan Kumpul (R3, M1, K2).
4. Template Kejar dan Jaga (P3, K3, R1, M2).
5. Berita utama dengan efek dunia, lalu pemilihan misi harian dengan seed.
6. Misi tiap distrik dirilis bersamaan dengan distrik itu.

Cara menguji:

- Pemain santai dan pemain ngebut sama-sama bisa menuntaskan misi, hanya dengan strategi berbeda.
- Sasaran awal: sekitar 60 sampai 70 persen pemain baru menyelesaikan misi yang diambil. Di bawah itu, petunjuk dibuat lebih jelas atau batasnya dilonggarkan.
- Pemain harus bisa menjelaskan sendiri kenapa misi gagal (petunjuk terlewat, kehabisan batas, atau salah target).

### 10.9 Yang perlu diputuskan

- Apakah misi boleh dibawa lintas hari, atau harus selesai di hari yang sama.
- Setelah prototype, apakah ongkos 15 koin per pengantaran dan hadiah misi kelipatannya terasa pas.
- Apakah misi dengan efek ke satu pelanggan tertentu boleh membuat pelanggan itu berhenti langganan, atau cukup menurunkan reputasi.

---

## 11. Progres dan Upgrade

Progres datang dari upgrade sepeda, distrik baru, dan opsi mode roguelite yang membuat tiap run berbeda.

- **Upgrade sepeda:** kecepatan puncak, akselerasi, rem, radius belok, ukuran keranjang, ban anti-selip, dan bel untuk mengusir pejalan kaki.
- **Tipe sepeda:** sepeda lipat gesit tapi lambat, sepeda balap cepat tapi sulit belok, sepeda keranjang besar muat banyak koran tapi lebih berat.
- **Distrik baru:** dibuka bertahap lewat reputasi lingkungan (bagian 9).
- **Mode roguelite:** tiap run punya rute dan kejadian acak, dengan upgrade sementara yang hilang setelah run selesai.
- **Kosmetik:** varian baju pemain (Merah Klasik, Garis Biru, Jaket Hijau, Kaus Bola, Polo Kuning, Batik, Hoodie Abu) disimpan untuk aksesori atau item nanti (ART_DIRECTION 3.3).

---

## 12. Perawatan dan Komponen Sepeda

> **KEPUTUSAN:** komponen sepeda bisa aus atau rusak dan hanya diperbaiki di bengkel setelah mengantar.

Sepeda punya komponen yang bisa rusak dan di-upgrade, jadi kondisi sepeda ikut menentukan strategi pemain, bukan sekadar angka stat.

### 12.1 Kerusakan di rute

- **Ban bocor:** terkena paku, pecahan kaca, atau kerikil tajam. Sepeda melambat dan sulit belok sampai diperbaiki di bengkel.
- **Rem blong:** rem melemah karena sering dipakai atau terkena genangan, jarak berhenti makin panjang. Berbahaya di dekat anjing dan tikungan.
- **Rantai putus:** akselerasi turun drastis dan kecepatan maksimum terbatas sampai diperbaiki di bengkel.
- **Lain-lain (opsional):** setang oblak, lampu mati saat malam, bel macet.

Supaya adil, tiap kerusakan punya tanda peringatan lebih dulu, misalnya rantai berisik sebelum putus atau rem yang mulai berdecit. Kerusakan hanya menghambat dan tidak menghentikan permainan: pemain tetap bisa menyelesaikan rute dengan sepeda yang kondisinya lebih buruk.

### 12.2 Penyebab kerusakan

Kerusakan datang dari dua sumber: keausan (komponen aus lebih cepat kalau pemain sering ngebut dan sering mengerem) dan kejadian di rute (paku, kaca, genangan, kerikil, tabrakan). Dengan begitu pilihan kecepatan punya konsekuensi jangka panjang, bukan hanya di satu rute.

### 12.3 Perbaikan

- Perbaikan hanya dikerjakan di bengkel setelah pengantaran selesai, bukan di tengah rute, sehingga alur permainan tidak terputus.
- Pemain membayar servis untuk mengembalikan kondisi komponen. Ongkosnya naik kalau banyak komponen rusak, jadi ngebut dan menabrak punya harga.
- Bengkel kampung bisa jadi lokasi dengan pemilik yang punya kepribadian sendiri.
- Upgrade komponen juga dibeli di bengkel.

### 12.4 Komponen dan upgrade

| Komponen | Bisa rusak | Efek saat rusak | Upgrade |
| --- | --- | --- | --- |
| Ban | Bocor | Melambat, sulit belok | Tahan bocor, anti-selip |
| Rem | Blong | Jarak berhenti panjang | Rem lebih pakem |
| Rantai dan gir | Putus | Akselerasi turun drastis, kecepatan maksimum terbatas | Akselerasi lebih baik, stamina lebih hemat |
| Setang | Oblak | Setir kurang presisi | Radius belok lebih baik |
| Lampu | Mati | Visibilitas malam turun | Lebih terang dan jangkauan lebih jauh |

HUD menampilkan kondisi ban, rem, dan rantai sebagai tiga kotak per komponen, dengan tanda ! oranye saat perlu ke bengkel (DESIGN_SPEC 3.3).

### 12.5 Yang perlu diputuskan

- Seberapa besar efek tiap kerusakan, supaya terasa menghambat tapi tidak membuat rute mustahil diselesaikan.
- Ongkos servis dan seberapa cepat komponen aus.
- Apakah mode bantu mengurangi keausan atau mematikan kerusakan, untuk pemain yang ingin santai.

---

## 13. Milestone Permainan

> **KEPUTUSAN:** mode endless run dan daily challenge tidak dipakai. Gantinya milestone tiga tingkat.

Milestone adalah penanda pencapaian jangka panjang yang terbuka sepanjang perjalanan, supaya pemain selalu punya tujuan berikutnya tanpa perlu mode terpisah. Angka di bawah masih usulan dan belum diuji.

- **Pelanggan:** jumlah pelanggan tetap (misalnya 10, 50, 100, 250) dan "semua rumah di rute satu distrik berlangganan".
- **Cerita:** distrik baru terbuka, jumlah misi sampingan selesai (misalnya 5, 25, 50), dan rantai misi yang tamat.
- **Uang:** total koin yang pernah didapat dari ongkos antar dan tip.
- **Keahlian:** lemparan tepat beruntun, rute selesai tanpa menabrak, rute selesai tanpa pakai rem, kiriman jarak jauh yang kena.
- **Sepeda:** upgrade pertama, semua komponen mencapai level tertentu, dan jumlah perbaikan di bengkel.
- **Tingkatan:** tiap milestone punya tiga tingkat (misalnya perunggu, perak, emas) dengan target yang makin tinggi.
- **Hadiah:** koin, julukan (misalnya "Loper Andalan"), dan kosmetik sepeda seperti stiker, bel, dan warna. Tidak ada gems, dan hadiah tidak menutup akses ke kemampuan inti supaya tetap adil.
- **Tampilan:** layar hasil harian menunjukkan milestone yang hampir tercapai, dan satu milestone bisa dipilih sebagai target aktif yang kemajuannya tampil di bengkel.

---

## 14. Ekonomi dan Monetisasi

> **KEPUTUSAN:** tanpa gems atau mata uang premium. Hanya ada satu mata uang, koin, yang didapat dari bermain. Pemasukan dari iklan hadiah opsional.

### 14.1 Patokan ekonomi dari dunia nyata (diputuskan sebagai acuan)

Angka koin mengacu pada penghasilan loper koran sungguhan di Indonesia: komisi sekitar Rp600 sampai Rp2.000 per eksemplar (Mojok, 2023) dan penghasilan sekitar Rp30.000 sampai Rp40.000 per hari. Angka di bawah masih usulan awal untuk disetel lewat prototype; tempatnya di `scripts/config.gd` (BALANCING.md).

- 1 koin setara Rp100, supaya mudah dihubungkan dengan harga sungguhan.
- Ongkos satu pengantaran: 15 koin (Rp1.500), dengan rentang 6 sampai 20 koin tergantung jenis koran.
- Rute awal sekitar 25 rumah, jadi pemasukan satu hari yang rapi sekitar 300 sampai 375 koin (Rp30.000 sampai Rp37.500), mendekati penghasilan nyata.
- Hadiah misi mengikuti kelipatan ongkos: kecil 45 koin, sedang 75 koin, besar 120 koin.
- Harga di bengkel dan upgrade dibuat dalam skala yang sama, misalnya tambal ban sekitar 1 sampai 2 jam kerja harian, supaya terasa seperti uang loper sungguhan.
- Di awal, jumlah pelanggan sedikit dan makin banyak seiring reputasi, mirip loper nyata yang pelanggannya naik turun.

### 14.2 Monetisasi

- Iklan berhadiah yang opsional: pemain memilih menonton untuk bonus, misalnya menggandakan koin hari itu atau diskon servis. Tidak ada iklan paksa di tengah rute.
- Titik iklan yang pas: layar hasil hari dan bengkel, saat alur sudah berhenti.
- Koin tidak bisa dibeli dengan uang asli, jadi tidak ada pay-to-win.
- Seluruh game tetap bisa dimainkan penuh tanpa menonton iklan.

### 14.3 Yang perlu diputuskan

- Apakah iklan satu-satunya pemasukan, atau ada juga pembelian sekali bayar seperti hapus iklan.
- Seberapa besar bonus iklan supaya tidak merusak keseimbangan ekonomi.

---

## 15. Visual, Audio, dan Orientasi Layar

Ringkasan; aturan lengkapnya ada di `ART_DIRECTION.md` dan `SOUND_DESIGN.md`.

- **Gaya:** pixel art retro dengan palet terbatas, dimodernkan lewat lighting dinamis (cahaya utama dari kiri atas), bayangan lembut berwarna yang mengikuti distrik dan waktu, partikel, depth of field ringan, bloom, dan color grading per distrik. Referensi rasa: Eastward dan Octopath Traveler, tanpa pindah dari isometrik 2:1.
- **Ukuran:** ubin isometrik belah ketupat 2:1, usulan 64×32 px. Karakter pemain dan sepeda sekitar 47 px tinggi. Di layar landscape 2400×1080, skala ×3 memberi kanvas sekitar 800×360 px.
- **Umpan balik kecepatan:** garis kecepatan, debu pixel di roda, getaran kamera, dan nada suara kayuhan yang naik saat ngebut. Bel sepeda jadi efek suara sekaligus alat mengusir pejalan kaki, dan memberi nama pada game (bagian 5.4). Kamera melebar sedikit ke depan saat ngebut supaya rintangan masih sempat terlihat.
- **Orientasi landscape:** dipegang dengan dua tangan, jadi dua jempol terasa natural. Ruang ke samping luas dan pandangan ke depan lebih lega karena jalan isometrik berjalan diagonal. Portrait ditinggalkan karena jalan diagonal memendekkan pandangan dan membuang sisi layar.
- **Isometrik 2:1, jalan ke kanan atas (diputuskan):** sepeda di sepertiga kiri layar, kamera melihat sisi kanan sepeda (rantai dan gir terlihat), fasad sisi seberang menghadap kanan bawah dengan pintu dan jendela kontras. Detail dan konsekuensinya: ART_DIRECTION 2.2.

---

## 16. Game Engine

> **KEPUTUSAN:** **Godot 4**, dengan GDScript.

Alasannya:

- Mendukung TileMap isometrik bawaan, jadi ubin belah ketupat 2:1 bisa langsung dipakai, dan Y-sort mengurus urutan gambar rumah, sepeda, dan rintangan.
- Render pixel-perfect dengan skala bilangan bulat (×3 atau ×4).
- Ringan untuk HP Android kelas menengah ke bawah dan hasil ekspornya kecil.
- Gratis tanpa royalti, cocok untuk proyek solo dengan monetisasi iklan.
- Katalog misi bisa disimpan sebagai JSON atau resource, sesuai skema data misi (`DATA_SCHEMA.md`).

Yang perlu dicek lebih awal:

- Plugin iklan hadiah (AdMob atau sejenisnya) untuk Android, karena iklan adalah satu-satunya pemasukan dan plugin-nya dari komunitas.
- Rasa kontrol landscape (stick dan swipe) di HP asli, bukan hanya di editor.

Alternatif yang sempat dipertimbangkan dan tidak dipilih: Unity, Defold, GameMaker, Cocos Creator.

---

## 17. Pertanyaan Terbuka dan Urutan Prototype

Beberapa keputusan masih terbuka dan paling baik diputuskan lewat prototype kasar. Daftar lengkap dengan apa yang dihambatnya ada di `ROADMAP.md` bagian 5.

**Pertanyaan terbuka**

- Cerita besar dan kondisi gagal (bagian 3.2).
- Cara menampilkan rumah di sisi dekat, yang hanya terlihat belakangnya di isometrik (kanan bawah jalan).
- Kontrol landscape: apakah ambang rem di ujung bawah stick nyaman tanpa berhenti tak sengaja, dan apakah swipe pendek cukup teliti di layar kecil.
- Bel: apakah tombol di pojok kanan bawah mudah dijangkau tanpa terpencet saat swipe, dan apakah bel dimajukan ke prototype awal karena sekarang menjadi ciri judul game (saat ini dijadwalkan Fase 6–7, `SOUND_DESIGN.md` 8).
- Struktur sesi: rute harian berurutan, atau run roguelite dengan rute acak.
- Skala tampilan pixel (×3 atau ×4) dan ukuran ubin isometrik.

**Urutan prototype**

1. Gerak sepeda dengan kontrol kecepatan.
2. Lemparan koran yang mewarisi kecepatan.
3. Satu rute dengan beberapa rumah dan dua jenis rintangan.
4. Satu halaman depan koran dengan satu misi sampingan (kucing hilang).

Uji di HP asli. Rincian tiap langkah sebagai fase dengan checklist ada di `DEV_PHASES.md`.
