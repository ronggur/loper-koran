# Panduan Menyusun Rute — Loper Koran

Pasangan dari GDD bagian 4, 7, dan 9. GDD menjawab "rute itu apa"; dokumen ini menjawab "bagaimana membuat rute yang seru dan adil". Seluruh dokumen ini **usulan** dan diuji di Fase 3 (`DEV_PHASES.md`). Angka jarak dan kecepatan diambil dari `BALANCING.md`; format filenya di `DATA_SCHEMA.md` bagian 3.

## 1. Rute dari segmen

> **KEPUTUSAN (GDD 9.4):** potongan rute dibuat tangan, urutannya diacak, jadi rute tidak bisa dihafal.

- Satu **rute** = segmen pembuka + beberapa segmen tengah + segmen penutup, disusun dengan seed per hari supaya bisa diuji ulang.
- Satu **segmen** = potongan jalan lurus 24–40 ubin buatan tangan, berisi petak rumah, properti, dan rintangan. Segmen pendek lebih gampang diacak tanpa terasa berulang.
- **Tepi segmen netral**: setiap segmen diawali dan diakhiri 2 ubin jalan kosong tanpa rintangan, supaya dua segmen apa pun bisa disambung.
- Segmen diberi **tag**: distrik, tingkat (`tenang`, `sedang`, `padat`), sisi pelanggan (`seberang`, `dekat`, `dua_sisi`), dan rintangan yang dipakai. Penyusun rute memilih segmen dari tag, bukan dari nama.

Rute perumahan pertama (prototype 3): sekitar 250 ubin, 25 pelanggan, 6–8 segmen. Hari 1 dan 2 semua pelanggan di sisi seberang; mulai hari 3, 8 atau 9 dari 25 di sisi dekat (bagian 3, Run 5D).

## 2. Tata letak jalan

```
 sisi seberang (kiri pelempar, kiri atas layar)
 ─────────────── petak rumah: fasad, teras ───────────────────────────
 ··············· halaman 1 ubin (kotak surat di sini) ·····················
 ··············· trotoar 1 ubin (bisa dilalui sepeda) ····················
 [ jalur seberang ]   ← lempar ke seberang paling dekat
 [ jalur tengah   ]   ← bisa menjangkau dua sisi, lemparan lebih jauh
 [ jalur dekat    ]   ← lempar ke sisi dekat paling dekat
 ··············· trotoar 1 ubin (bisa dilalui sepeda) ····················
 ─────────────── petak rumah: belakang rumah ──────────────────────────
 sisi dekat (kanan pelempar, kanan bawah layar)
```

- Jalan perumahan 2 ubin aspal, trotoar 1 ubin tiap sisi. Posisi lateral sepeda bebas (stick analog) sampai tepi trotoar (±2 ubin; sepeda boleh naik trotoar, halaman tidak), tapi untuk merancang dipakai **tiga jalur bantu**: seberang, tengah, dekat.
- **Petak rumah** 4 ubin (rumah 3 ubin + celah 1). Kotak surat di halaman rumah (bagian halaman terluas, sesudah teras), bukan di trotoar; teras di depan pintu.
- Jarak lempar 1,5–5 ubin ke samping (BALANCING 4): dari jalur seberang, kotak surat terjangkau swipe pendek; teras butuh swipe sedang.

## 3. Menempatkan rumah pelanggan

- Distrik pertama: **hari 1 dan 2** pelanggan hanya di sisi seberang; **mulai hari 3** tepat 8 atau 9 dari 25 pelanggan di sisi dekat (GDD 4.2 dan 9.1; keputusan pemilik 2026-10-22, Run 5D). `RouteBuilder.bangun` menerima nomor hari (bawaan hari 1) dan memilih pelanggan dari rumah yang `pelanggan_boleh`: dekat dulu (kuota 8 atau 9, diundi dari RNG rute sesudah susunan segmen), lalu sisanya di seberang. Hari 1 dan 2 mengonsumsi RNG persis seperti sebelum Run 5D, jadi rute kedua hari itu tidak berubah. Celah antar pelanggan berturut-turut (dua sisi digabung, urut maju) tidak lebih dari `RUTE_PELANGGAN_JARAK_MAKS_UBIN` (20 ubin); terukur di 100 hari: 2 sampai 20, median 10. Hampir semua rumah dekat di sembilan segmen `pelanggan_boleh` (34 dari 36); dua rumah bukan kandidat karena zona kotak surat dekatnya beririsan dengan anjing dekat (`per_tengah_02@12`, `per_tengah_03@28`; `DATA_SCHEMA.md` 3). Titik kucing misi P1 tetap di rumah seberang.
- **Sisi dekat terbuka.** Tembok sisi dekat Run 5B dihapus: kavling dekat adalah halaman rumput terbuka seperti sisi jauh, rumah dekat mundur 0,5 ubin dan punya teras yang menjorok ke arah jalan. Kotak surat dekat (di tepi trotoar dekat, cermin seberang) ada di semua rumah dekat: oranye bila pelanggan, abu-abu bila bukan. Rumah dekat tidak boleh menutupi kotak surat sasaran atau sepeda (`BALANCING.md` 5, diukur oracle piksel).
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
5. **Jalur utama tidak tertutup objek tinggi.** Pohon, mobil, dan atap boleh menutupi pemandangan, tapi rintangan di jalur selalu terlihat. Objek yang menutupi pemain dibuat semi-transparan; yang dilarang adalah pemain **tertutup opak**. Dekor (pohon, lampu jalan, tong sampah; di bawah) mengikuti aturan ini dan dibuktikan dengan **piksel**, bukan dengan model kotak: untuk tiap dekor, tiap lateral pemain di -2,0 sampai 2,0 dan tiap maju di sekitarnya tidak ada piksel opak dekor di atas piksel pemain pada alfa 1,0 kecuali kotak penutupnya menutupi pemain (alfa `RUTE_PENUTUP_ALFA`, pemain tetap terlihat), dan tidak ada piksel opak dekor di atas anjing atau mobil garasi di posisi mana pun yang bisa dicapainya (run 5B iterasi 2, putusan P-6; `tests/tes_dekor_piksel.gd`). Berlaku juga untuk tong sampah sisi dekat (P-7). Batas yang diketahui: sprite jatuh tidak dihitung; sejak run 5C sel jatuh/terjerembab/bangkit 140 x 88, dan di 5 dari 44 kombinasi dekor x rintangan sesegmen ada 89 sampai 284 piksel opak dekor di atas pose jatuh di lateral 0 yang tidak ditutup kotak penutup (I2-F3, DEFERRED; pose berkendara 0 piksel; `docs/loop/20261022-fase5c-animasi-simpang/LOG.md` AC-7).
6. **Rintangan tidak menutup satu-satunya kesempatan melempar.** Kalau mobil tamu menutupi kotak surat, teras tetap bisa dicapai.
7. **Rintangan tidak menembus rumah (usulan, keputusan pemilik 2026-10-17).** Mobil garasi parkir di **celah samping rumah**, bukan di depan rumah: `pos` mobil = `pos` rumah sesisi − 1 (petak 4 ubin = rumah 3 ubin + celah 1 ubin, jadi celah antar rumah maju `pos − 1,5` sampai `pos − 0,5`). Seluruh lintasan mobil, dari parkir (bagasi 2,5 ubin dari garis tengah, moncong 4,0) sampai berhenti di garis tengah, tidak boleh beririsan dengan tapak rumah mana pun (seberang lateral −6 sampai −3, dekat 3 sampai 6, maju `pos − 0,5` sampai `pos + 2,5`); tepi yang hanya bersentuhan boleh. Anjing penjaga yang diam di halaman (lateral ±2,5 sampai ±3,0) hanya menyentuh kaki fasad.

Rintangan prototype 3: **anjing penjaga** (mengejar sesuai kecepatan, berhenti di batas halaman) dan **mobil keluar garasi** (lampu mundur dulu, baru bergerak).

**Pola yang diterapkan (run 3B `20261017-fase3b-rintangan-skor`, usulan, dinilai lewat uji HP; angka di `BALANCING.md` 6c dan 6d):**

- **Separuh jalan (K-1, aturan 1).** Anjing dan mobil hanya memakai separuh jalan di sisinya (`jalur` di data segmen): sisi `seberang` dari tepi trotoar −2,0 sampai garis tengah 0, sisi `dekat` dari 0 sampai +2,0. Tepi bentuk rintangan tidak pernah melewati garis tengah, jadi separuh lain selalu bebas. Sepeda selebar 0,5 ubin, jadi sepeda yang tepat di garis tengah masih bisa menyentuh mobil yang sudah berhenti; jalan aman = tetap di separuh jalan lawan.
- **Anjing penjaga (D-2 run 3B).** Duduk di halaman; **waspada** (berdiri, menggeram) saat sepeda masuk `tanda_ubin` (9 ubin) di belakang titik rumahnya; **mengejar** (menggonggong, lari) baru saat sepeda sampai di titik rumahnya, dengan laju 1,25 × kecepatan sepeda (2,0 sampai 4,5 u/d) dan menyamping di separuh jalannya; berhenti di batas halaman (3 ubin maju dari rumahnya) atau sesudah menabrak, lalu pulang dan tidak mengejar lagi. Pemain ngebut di separuh jalan lawan lolos; pemain santai di sisi anjing tersusul.
- **Mobil keluar garasi (D-1 run 3B).** Lampu mundur berkedip dan bip selama 1,5 detik (waktu, bukan jarak) sesudah sepeda masuk `tanda_ubin`, lalu mundur 1,0 u/d sampai bagasi tepat di garis tengah dan berhenti di sana sampai rute disusun ulang (menutup separuh jalan sisinya). Tidak bereaksi pada bel.
- **Bel (K-3, D-5).** Anjing yang waspada atau mengejar dalam jangkauan bel (1 ubin di belakang sampai 4 ubin di depan sepeda) menampilkan "!" lalu mundur ke halamannya; reaksi per jenis rintangan diatur di satu tabel (`Bel.REAKSI_JENIS`), jadi pejalan kaki nanti cukup ditambah di sana.
- **Tabrakan = jatuh (keputusan pemilik 2026-10-17, BALANCING 6c; menggantikan oleng K-1).** Pemain jatuh 1,2 detik (kecepatan 0, stick dan lemparan diabaikan), combo putus, lalu bangun dan dikayuh lagi dari 0 dengan kebal 1,0 detik sejak bangun; rute tidak berhenti. Di scene: animasi jatuh lalu terjerembab, ikon kilatan di atas kepala, berkedip selama kebal, bunyi tabrakan lembut, label PUTUS di HUD dev. Rintangan yang tersentuh selama jatuh atau kebal tidak menabrak lagi sampai sepeda terpisah darinya, jadi mobil yang berhenti di garis tengah tidak bisa mengurung pemain.
- **Data.** Tidak ada field baru: rintangan dibangun dari `objek` segmen yang sudah ada (`jenis`, `pos`, `jalur`, `tanda_ubin`; `DATA_SCHEMA.md` 3). Data perumahan saat ini hanya punya mobil di sisi `seberang` (sprite mobil hanya untuk sisi itu); anjing di kedua sisi.
- **Celah samping rumah (aturan 7, 2026-10-17).** Mobil dipindah dari depan rumah ke celah sebelum rumah sesisi: `per_tengah_02` 26 → 25, `per_tengah_03` 10 → 9, `per_tengah_04` 18 → 17, `per_tengah_05` 10 → 9 dan 28 → 29 (28 ada di ujung rumah 26; celah 25 terlalu dekat anjing 20, jadi celah sebelum rumah 30). Aturan tanda, tepi segmen, dan jendela 6 ubin tetap terpenuhi. Divalidasi `SegmenRute.parse` (`SegmenRute.rintangan_memotong_rumah`, `MobilGarasi.lintasan`); posisi lama ditolak.
- **Diperiksa mesin (tes headless):** tanda ≥ 1,5 detik sebelum bahaya di santai, cepat, dan ngebut untuk semua posisi lateral (aturan 2); di 20 rute uji selalu ada sisi bebas dan bot di sisi bebas tidak pernah tertabrak (aturan 1); tabrakan tidak menghentikan rute.

## 4b. Dekor pinggir jalan (run `20261021-fase5b-tembok-dekor` bagian B2, usulan, dinilai lewat uji HP)

Dekor = tong sampah, pohon, dan lampu jalan di halaman dan tepi trotoar, ditulis tangan di bidang `dekor` tiap segmen (`DATA_SCHEMA.md` 3). Hanya hiasan: bukan rintangan, bukan sasaran, tidak masuk zona atau penilaian lemparan, dan tidak mengubah rute (rumah, pelanggan, rintangan, tenggat, dan skor untuk seed yang sama identik dengan sebelum ada dekor; tanpa RNG baru).

- **Letak.** Sisi dekat: pohon dan tong sampah di halaman (lateral 2,5, tapak kaki 0,5 × 0,5), lampu jalan di luar tepi trotoar (lateral 2,25, tapak kaki 0,25 × 0,25). Sisi seberang: tong 2,5, pohon 2,75, lampu 2,625 (lebih jauh dari jalan supaya tajuk dan lengan tidak menimpa pemain di tepi seberang, lateral -2,0; terukur 272 dan 240 piksel pada 2,5 dan 2,25, 0 piksel pada angka ini). Lateral tidak ditulis di data. `pos` bilangan bulat dari awal segmen (1 sampai `panjang - 1`); set perumahan memakai `pos` 2 sampai `panjang` - 2. Dekor di depan anjing atau mobil garasi dihindari: tiga butir digeser di iterasi 2 (tong `per_tengah_03` 31 ke 27, lampu dekat `per_tengah_04` 27 ke 23, lampu seberang `per_buka_01` 23 ke 25).
- **Celah satu ubin.** Dekor tidak boleh menimpa zona teras atau kotak surat rumah mana pun, tapak rumah, atau tapak rintangan (lintasan mobil garasi, anjing di posisi diamnya), dan tidak boleh menyentuh lajur sepeda (`|lateral|` kurang dari 2,0). Karena petak rumah 4 ubin dan rumah di tiap petak, dekor di halaman muat di celah satu ubin di antara tapak rumah (`pos` rumah + 3: rumah di 6 dan 10 memberi celah di 9) atau di kavling yang kosong. Tong sampah dipilih di celah sesudah rumah sisinya (dekat kotak surat dan gerbang), pohon dan lampu di celah lain.
- **Seperlunya.** Tiap berkas 2 sampai 8 butir, paling banyak satu butir per 4 ubin per sisi; seluruh set sedikitnya 3 tong sampah, 6 pohon (rindang, glodokan, ketapang di kedua sisi), 6 lampu jalan (kedua sisi). Set sekarang: 9 tong, 18 pohon, 11 lampu di sembilan segmen.
- **Sasaran tidak tertutup.** Diukur dari gambar piksel tata letak nyata (`tests/ukur_dekor.gd`): sprite dekor tidak menimpa badan kotak surat dan zona kotak surat dan teras rumah seberang yang `pelanggan_boleh` (0%). Pohon seberang di celah tepat sebelum rumah pelanggan menimpa zona teras (terukur 8,6% pada percobaan, dibuang dari data); letak diperiksa lagi bila geometri atau aset berubah.
- **Menutupi pemain.** Pohon, lampu, dan tong sampah **sisi dekat** menjadi semi-transparan (`RUTE_PENUTUP_ALFA`) bila pemain, di lajur sepeda atau trotoar, berada di baliknya menurut kamera isometrik. Kotak penutup = sprite nyata: tinggi dari piksel opak di atas pijak dibagi 32 (tong 0,75, pohon rindang 1,375, glodokan 1,96875, ketapang 1,65625, lampu dekat 2,0 ubin) dan tapak lebih lebar dari tapak kaki karena tajuk, lengan lampu, dan tubuh tong melebar (setengah sisi 0,625, 0,875, 0,625, 0,75, 0,75; ukuran terkecil yang membuat tidak ada piksel opak menimpa pemain tanpa kotak menutupinya, `Config.RUTE_DEKOR_*_PENUTUP_*`). Pohon dan lampu **seberang** tidak pernah menutupi (kamera melihat dari sisi dekat; dibuktikan 0 piksel menimpa pemain), begitu pula tong sampah seberang. Batasan lama "tinggi kotak <= lateral - setengah tapak - 1,0" dicabut: ia membuat tajuk menimpa pemain di lajur sepeda dengan piksel opak (QA-001).
- **Arah bayangan (keraguan, belum diputuskan).** Sprite pohon dan lampu membawa bayangan tanah yang selalu jatuh ke kanan bawah layar, di kedua sisi; dinilai di HP apakah wajar untuk dekor sisi dekat dan seberang.

## 4c. Simpang T hiasan (run `20261022-fase5c-animasi-simpang`, usulan, dinilai lewat uji HP)

Simpang = jalan samping (simpang T) ke sisi `seberang` atau `dekat`, ditulis tangan di bidang `simpang` `{pos, sisi}` tiap segmen (`DATA_SCHEMA.md` 3). **Hanya hiasan** (keputusan pemilik 2026-10-22, bagian 8): tanpa lalu lintas, rintangan, atau sasaran; pemain tidak bisa berbelok; gerak, zona, penilaian lemparan, skor, dan tenggat tidak berubah, dan rute untuk seed yang sama identik (tanpa RNG baru). Data disiapkan supaya kelak mobil atau motor bisa berbelok (M3) tanpa mengubah format: satu fungsi baca `RouteBuilder.simpang_di(rute)`.

- **Pita.** Mulut 2 ubin, ubin yang diganti renderer (mulut dan sudut kerb) 5 baris: maju `pos` − 1,5 sampai `pos` + 3,5. Di sisi simpang pita membentang dari garis tengah ke luar (lengan jalan samping sampai tepi layar); sisi lain jalan tetap lurus.
- **Aturan.** Pita di dalam segmen; tidak memotong (di sisi simpang) kavling rumah (tembok dekat sudah dihapus di Run 5D), zona sasaran, dekor, rintangan (anjing diam, lintasan mobil), jalan masuk garasi dan ujung kerbnya, atau pita simpang lain, juga di sambungan antar segmen. Tepi bersentuhan boleh. Divalidasi `SegmenRute.galat_tempat_simpang` dan `RouteBuilder.periksa_rute`.
- **Tempat.** Rumah sesisi berjarak 4 ubin dengan kavling 3 ubin, jadi celah paling lebar 1 ubin; simpang hanya muat di rentang tanpa rumah di sisinya. Sisi dekat punya rentang kosong di awal beberapa segmen; sisi seberang tidak punya sama sekali, sehingga satu rumah seberang bukan pelanggan (`per_buka_02@18`) dihapus untuk memberi tempat simpang seberang (putusan P-6 run 5C; kandidat pelanggan tidak berubah).
- **Isi sekarang.** Simpang dekat `per_buka_01@3`, `per_tengah_05@3`, `per_tutup_01@2`; simpang seberang `per_buka_02@18`.
- **Frekuensi (diukur, 100 rute hari `SeedHari.rute(1..100)`):** 100% rute memuat paling sedikit satu simpang, **100% simpang dekat**, **56% simpang seberang**; 1 sampai 3 simpang per rute. Simpang dekat ada di setiap rute karena `per_tengah_05` selalu terpakai (lima segmen tengah = lima yang dibutuhkan), selalu di posisi segmen yang sama; bisa terasa berulang (D-F3 run 5C), dinilai di HP dan saat segmen bertambah. Mobil garasi seberang `per_tengah_05@9` mundur ke jalan sekitar 1,5 ubin sesudah pita simpang dekat dan bisa terbaca seperti keluar dari simpang (D-F2), dinilai di HP.

## 4d. Akhir rute dengan portal satpam (run `20261024-garis-finish-portal`, usulan, dinilai lewat uji HP)

Garis akhir = `RouteBuilder.Rute.panjang_ubin` (tidak berubah) dan **tidak ada segmen yang ditambah atau diubah**: tidak ada rumah, rintangan, simpang, atau dekor milik rute di depan garis akhir (rumah terakhir ada sebelum `panjang_ubin`; jarak terdekat rintangan mana pun ke garis akhir 31,0 ubin, terukur di 400 rute), jadi rute untuk seed yang sama identik dengan sebelum run ini. Yang ada di depan garis hanya hiasan lanjutan Bagian F (di bawah), terpisah dari `Rute`. Yang berubah adalah apa yang terjadi sesudah garis (angka: BALANCING 6h):

- **Portal satpam** `prop_portal_satpam` berdiri melintang di garis akhir. Tiangnya di lateral −2,0 ubin (batas luar jalur sepeda sisi seberang, antara trotoar dan rumput) dan palangnya 1,625 ubin membentang ke arah jalan, jadi menutup trotoar seberang dan separuh aspal; sisi dekat tetap lapang. Tertutup saat jauh, membuka saat sepeda 6,0 ubin dari garis (`RUTE_PORTAL_BUKA_JARAK_UBIN`), dan tetap terbuka sesudahnya. Portal bukan penghalang: tidak masuk tabrakan, zona, atau penilaian. Sepeda yang lewat di lateral berapa pun tidak ditimpa palang (kotak penutup pemain setinggi palang terangkat, ART_DIRECTION 6.4). Pos satpam tidak dipasang (M3).
- **Sepeda tidak direm dan keluar dengan cepat (Bagian F, F-3).** Sesudah garis sepeda melaju lurus dengan laju minimal level ngebut (6,0 u/d, `RUTE_KELUAR_LAJU_MIN_UD`; efek kondisi dan lelah tidak berlaku, stamina dibekukan) sampai seluruh badan keluar viewport lewat **tepi kanan** (arah jalan naik ke kanan atas; tepi kanan lebih cepat dari tepi atas di keempat lebar viewport). Stick sungguhan dikunci, lemparan, mode bantu, dan bel mati, rintangan membeku dan tidak bisa menabrak.
- **Kamera dan dunia dibekukan di garis akhir.** Kamera berhenti mengikuti sepeda, dan tanah serta jendela daur rumah, dekor, dan rintangan dipakukan di jarak garis, jadi tidak ada lubang tanah di belakang portal walau sepeda menempuh jarak tambahan 12,8 sampai 17,9 ubin (640 sampai 800 lebar, tergantung geseran kecepatan saat garis tercapai; tabel di BALANCING 6h). Tanah di belakang portal tidak butuh segmen tambahan: kamera beku hanya melihat sampai 17,4 ubin di depan pijak sepeda saat beku.
- **Hiasan perumahan di depan portal (Bagian F, F-1, usulan, dinilai di HP).** Di depan portal bukan lagi jalan dan rumput kosong: `HiasanRute` menyusun rute hiasan TERPISAH dari `Rute` (aliran acak sendiri, seed rute + `RUTE_HIASAN_SEED_SELISIH`): satu sampai empat segmen pembuka/tengah dari pustaka (bukan penutup, bukan segmen sebelumnya, tidak dua padat berurutan) yang dimulai tepat di `panjang_ubin` dan menutupi sedikitnya `RUTE_HIASAN_PANJANG_UBIN` 32 ubin. Hanya rumah dan dekor yang disalin: semua rumah BUKAN pelanggan (sprite `_bukan`, kotak surat abu-abu, tanpa zona, radar, progres, skor), tanpa rintangan, titik misi, atau simpang; posisi dekor sudah di luar lajur sepeda. Digambar jendela daur yang sama (beku bersama dunia di garis) dan didaftarkan ke penerap penutup yang sama, anak induk Y-sort yang sama dengan sepeda dan portal. Data segmen dan keluaran `RouteBuilder.bangun` tidak berubah (golden G-5 tetap). Pola yang sama bisa dipakai ulang untuk mengisi area kosong di belakang rumah (backlog ROADMAP): rute atau lapisan hiasan terpisah dari `Rute`, dibangun murni dari benih.
- **Banner dan hasil.** Banner "Rute selesai" muncul saat sisa jalan sepeda sampai keluar paling banyak 6,0 ubin; layar hasil tampil sesudah sepeda keluar dan semua koran terbang mendarat. Skor, koin, tenggat, kondisi sepeda, progres, radar, dan misi dibekukan di garis seperti sebelumnya, jadi jarak tambahan tidak memengaruhi satu angka pun.

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
- ~~Cara menampilkan rumah di sisi dekat~~: diputuskan 2026-10-17 (tembok/pagar belakang rendah, kavling lebih dalam sekitar 1,25 ubin), **diganti pemilik 2026-10-22**: halaman terbuka tanpa tembok, rumah dekat mundur 0,5 ubin dan didesain ulang dengan teras menjorok (`ROADMAP.md` 4b, Run 5D); angka dan bentuk usulan sampai dinilai di HP (`SETUP_ANDROID.md` 8.16).
- ~~Persimpangan: hanya dekorasi, atau ada lalu lintas yang memotong~~: **untuk sekarang hiasan** (keputusan pemilik 2026-10-22, run 5C, bagian 4c): simpang T tanpa lalu lintas, rintangan, atau sasaran. Lalu lintas yang berbelok atau memotong di simpang (mobil, motor) dijadwalkan M3 dan memakai data simpang yang sama (`RouteBuilder.simpang_di`). Simpang empat dan pemain berbelok masuk jalan samping tetap terbuka bersama rute bercabang.
