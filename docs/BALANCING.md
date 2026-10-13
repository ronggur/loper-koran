# Balancing — Loper Koran

Cara angka-angka game ini ditentukan, diuji, dan diubah. **Semua angka di dokumen ini adalah usulan awal** untuk prototype; tujuannya memberi titik mulai yang masuk akal, bukan jawaban akhir. Angka berubah lewat uji di HP, lalu dokumen ini diperbarui dari `scripts/config.gd`, bukan sebaliknya.

## 1. Satu sumber kebenaran

| File | Isi |
|---|---|
| `scripts/config.gd` | **Semua angka global**: kecepatan, stamina, lemparan, skor, tenggat, ekonomi, keausan. Satu-satunya tempat angka ini ditulis di kode. |
| `assets/data/missions/*.json` | Parameter tiap misi (batas, hadiah), format di `DATA_SCHEMA.md`. |
| `assets/data/routes/<distrik>/*.json` | Segmen rute: jarak rumah, posisi rintangan (`ROUTE_DESIGN.md`). |

Alur mengubah angka:

1. Ubah `scripts/config.gd`.
2. Jalankan tes logika (`tests/run_tests.gd`) yang mengecek target di bagian 9.
3. Coba di HP asli. Angka gerak dan lemparan tidak bisa dinilai dari editor.
4. Perbarui tabel di dokumen ini dan tulis alasannya di bagian 10.

**Satuan.** Jarak memakai **ubin** (1 ubin = 32 unit dunia = satu ubin 64×32 px di layar, ART_DIRECTION 2.2). Kecepatan dalam ubin per detik (u/d). Di skala ×3, 1 u/d kira-kira 107 piksel layar per detik di sepanjang jalan.

---

## 2. Kecepatan dan kontrol

| Angka | Usulan | Catatan |
|---|---|---|
| Kecepatan santai (stick netral) | 3,0 u/d | Tempo dasar. Satu layar 20:9 dilewati kira-kira dalam 7 detik |
| Kecepatan cepat | 4,5 u/d | |
| Kecepatan ngebut (stick penuh ke atas) | 6,0 u/d | |
| Melambat (stick bawah) | turun ke 1,5 u/d | Meluncur: stamina pulih |
| Akselerasi | 3,0 u/d² | |
| Perlambatan melambat | 2,0 u/d² | |
| Rem | 5,0 u/d² sampai berhenti | Aktif setelah stick di ujung bawah (≥ 90%) ditahan 0,25 detik |
| Zona mati stick | 15% | |
| Kecepatan pindah sisi (lateral) | 3,0 u/d | Lebar jalan perumahan 2 ubin |

Stick analog dipetakan halus: sumbu atas memetakan santai → ngebut, sumbu bawah memetakan santai → melambat. **Sprite** memilih tingkat dari posisi stick: di bawah 33% santai, 33–80% cepat, di atas 80% ngebut. Stick ditarik ke bawah (komponen maju di bawah nol sesudah zona mati 15%) memakai tingkat **melambat**: gambar sama persis dengan santai, kayuh 4 fps (santai 8 fps). Usulan awal (run sprite-lempar-melambat): 14,9% ke bawah masih santai, 15,1% ke bawah sudah melambat, tanpa ambang tambahan; kalau di HP animasi berkedip antara santai dan melambat saat stick hanya melenceng sedikit ke bawah sambil belok, tambahkan ambang (belum ada angkanya).

**Arah sprite** dipilih dari arah gerak sebenarnya (gabungan maju dan lateral), bukan dari stick langsung: sudut di bawah 22,5° = normal, 22,5–67,5° = serong, di atas 67,5° = 90°. Akibatnya, belok 90° hanya muncul saat sepeda pelan atau hampir berhenti, sesuai fisika.

**Rumus gerak `BikeMotion`** (`scripts/systems/bike_motion.gd`, run fase1a-gerak 2026-10-13, menggantikan `BikeDrive` run 0B; semua angka usulan sampai uji HP). Satu langkah `langkah(keadaan, stick, dt)` murni: keadaan = kecepatan, lateral, stamina, lama tahan rem, rem aktif, lelah; masukan tidak diubah.
- **Kecepatan tujuan** linear terhadap komponen maju stick (sesudah zona mati): atas penuh 6,0, atas 0,5 = 4,5, netral 3,0, bawah penuh 1,5 u/d. Naik 3,0 u/d², turun 2,0 u/d², tidak melewati tujuan. Selama **lelah** tujuan dijepit ke 4,5. Jarak per langkah dihitung tepat (rampa linear lalu tetap), jadi tidak bergantung pada `dt` (`BikeDrive` dulu memakai trapesium ujung-ujung yang hanya tepat di dalam rampa).
- **Rem tanpa tombol** (GDD 5.2): syarat = komponen **bawah** stick ≥ 0,90 (`REM_AMBANG_STICK`, inklusif; toleransi 1e-6 untuk presisi tunggal Vector2). Diagonal penuh 45° (0,707) tidak pernah memenuhi; bawah penuh dengan geser datar kecil (bawah ≥ 0,90) tetap memenuhi. Lama tahan bertambah selama syarat terpenuhi dan kembali 0 begitu tidak (stick naik, ke samping, atau dilepas). Rem **aktif** saat lama tahan ≥ 0,25 detik (`REM_TAHAN_DETIK`); selama aktif kecepatan turun 5,0 u/d² sampai **0** dan tetap 0. Sebelum aktif, stick bawah berperilaku meluncur biasa. Langkah yang melewati batas 0,25 detik dibagi: sisa sebelum batas gerak biasa, sesudahnya pengereman. Lepas rem: naik 3,0 u/d² ke tujuan stick. Jangkauan kecepatan 0 sampai 6,0; hanya rem yang membawa di bawah 1,5. Akibatnya stick bawah tanpa rem paling dalam sekitar 0,899 (tujuan sekitar 1,65 u/d); 1,5 hanya tujuan selama 0,25 detik pertama tarikan penuh.
- **Lateral** analog bebas (keputusan pemilik 2026-10-13, tanpa kunci atau snap jalur): komponen datar × 3,0 u/d, dijepit ke tepi aspal ±1,0 ubin (`JALAN_LEBAR_UBIN` / 2) sebagai **batas tepi jalan resmi**. Positif = sisi `dekat`, negatif = sisi `seberang`; kidal tidak mengubah arti sumbu. Kecepatan lateral efektif 0 bila terhalang tepi. Lateral tetap bekerja saat berhenti dengan rem (arah sprite 90°).
- **Pose sprite** (`LoperAnim.pose_dari_gerak`, keputusan pemilik "ikuti fisika"): (1) rem aktif = `rem_<arah>`, juga di kecepatan 0; (2) stick ke bawah dan kecepatan sebenarnya masih di atas tujuan lebih dari `POSE_MELUNCUR_TOLERANSI_UD` (0,05 u/d) = `meluncur_<arah>` (kaki diam); (3) stick ke bawah dan sudah sampai tujuan = `melambat_<arah>` (kayuh 4 fps); (4) selain itu kayuh dengan tingkat dari stick, **dijepit ke cepat selama lelah**. Toleransi 0,05 mencegah stick yang hanya bergetar membuat pose berkedip; akibatnya stick bawah 15,1% (tujuan 2,998) langsung melambat. Lempar dari meluncur atau rem memakai lempar santai.
- **Laju kayuh** (`LoperAnim.pedal_rate`): untuk kayuh dan melambat = kecepatan sebenarnya / kecepatan nominal tingkat (santai 3,0, cepat 4,5, ngebut 6,0, melambat 1,5), dijepit 0 sampai `PEDAL_RATE_MAKS` (1,5). Meluncur dan rem = 1 (animasinya napas dan getar dari `.tres`). Lempar tidak terpengaruh.
- **Jeda** (`JedaSim`, GDD rule `gdscript`): app di-background atau kehilangan fokus menghentikan simulasi (dt 0), melepas stick dan swipe, menutup lempar, dan mengembalikan lama tahan rem ke 0; lanjut otomatis dan langkah pertama sesudahnya ber-dt 0.

| Angka baru (run fase1a-gerak) | Usulan | Catatan |
|---|---|---|
| Batas tepi jalan resmi | ±1,0 ubin (setengah `JALAN_LEBAR_UBIN` 2,0) | Dipindah ke bagian "Kecepatan dan kontrol" di `config.gd` |
| Toleransi ambang rem | 0,000001 | `REM_AMBANG_TOLERANSI`; hanya presisi tunggal, tidak mengubah rasa |
| Toleransi lama tahan rem | 0,000001 detik | `REM_TAHAN_TOLERANSI_DETIK`; jumlah 15 × 1/60 tidak tepat 0,25 |
| Toleransi pose meluncur | 0,05 u/d | `POSE_MELUNCUR_TOLERANSI_UD`; usulan, dinilai di HP |
| Batas laju kayuh | 1,5 | `PEDAL_RATE_MAKS`; usulan |
| Bar stamina merah | di bawah 30 | `HUD_STAMINA_AMBANG_RENDAH` (DESIGN_SPEC 3.5); usulan |

**Kontrol sentuh (usulan, run 0B, belum diuji di HP).** Angka ada di `scripts/config.gd` bagian "Kontrol sentuh" dan "Jalan uji"; ukuran visual dari `design/DESIGN_SPEC.md` 3.7.

| Angka | Usulan | Catatan |
|---|---|---|
| Jangkauan penuh stick | 35 px game (sekitar 105 px layar di ×3) | `STICK_RADIUS_PX`; di atas jangkauan dijepit ke 1,0, arah dipertahankan |
| Zona mati stick | 15% radial (inklusif) | 15,0% = nol, 15,1% = kekuatan kecil; di atasnya dipetakan ulang linear 0 sampai 1 tanpa lompatan |
| Zona stick (tangan kanan) | x 8–192, y 186–352 | Stick melayang muncul di titik sentuh; opsi kidal mencerminkan |
| Zona swipe | x 210 sampai lebar − 20, y 48–352 | Strip atas (y < 48) bebas dari kontrol untuk tombol HUD; kidal mencerminkan |
| Lebar jalan scene uji | 2 ubin aspal, geser lateral ±1 ubin | `JALAN_LEBAR_UBIN`; sejak run fase1a-gerak batas tepi jalan resmi (lateral analog bebas, tanpa kunci jalur, keputusan pemilik 2026-10-13) |
| Letak dasar sepeda di layar | 33,33% lebar, 60% tinggi | `KAMERA_SEPEDA_*_PECAHAN`; sepertiga kiri (ART_DIRECTION 2.2), ±8 px di 640, 780, 800 saat geseran dorongan = 0 (santai) |
| Dorongan maju (ngebut) | 28 px game datar, naik ke kanan atas 2:1 (28, −14) | `DORONGAN_MAJU_PX`; GDD 15, usulan (permintaan Ronggur 2026-10-09), disetel di HP |
| Dorongan mundur (melambat) | 20 px game datar, turun ke kiri bawah 2:1 (−20, +10) | `DORONGAN_MUNDUR_PX`; usulan |
| Respon dorongan | 0,35 detik | `DORONGAN_RESPON_DETIK`; konstanta waktu penghalusan eksponensial, bebas framerate |
| Ambang swipe lempar | 12 px game, inklusif | `LEMPAR_SWIPE_AMBANG_PX`; usulan (run sprite-lempar-melambat), diukur dari panjang swipe awal ke akhir; belum diuji di HP, jangan dikunci sebelum uji |
| Frame koran lepas | indeks 2 | `LEMPAR_FRAME_LEPAS`; fakta sprite (`release_frame` di `loper_agen_lempar.json`), bukan angka tuning; dijaga tes terhadap JSON |
| Toleransi waktu frame | 0,000001 detik | `LEMPAR_TOLERANSI_DETIK`; hanya meredam derau float di batas frame, tidak mengubah rasa |

**Animasi melambat dan lempar** (usulan, run sprite-lempar-melambat; `scripts/systems/loper_anim.gd`, `lempar_waktu.gd`, `scripts/entities/loper_sprite.gd`; belum ada proyektil, skor, atau sasaran, itu Fase 2). fps tidak ada di `config.gd`: dibaca dari `loper_agen_frames.tres` (kayuh 8/10/12, melambat 4, lempar 12).
- **Sisi dari arah swipe** (GDD 5.2): ke kiri layar = sisi `seberang`, ke kanan layar = sisi `dekat`; opsi kidal hanya menukar zona, bukan arti sisi. Tidak melempar bila swipe lebih pendek dari 12 px, bila gerak tegak sama besar atau lebih besar dari gerak datar (tepat 45° dianggap ambigu), atau bila titiknya tidak sah.
- **Animasi** `lempar_<sisi>_<kecepatan>_<arah>` dengan kecepatan = tingkat sprite saat swipe dilepas (melambat memakai santai, tidak ada lempar melambat) dan arah = arah sprite saat itu (arah 90° belum ada gambarnya, jadi memakai serong di sisi yang sama). Sekali putar, 4 frame, 12 fps, sekitar 0,33 detik; koran lepas di frame 2 (sekitar 0,17 detik).
- Swipe berikutnya diabaikan selama animasi lempar berjalan (usulan sederhana). Setelah selesai sprite kembali ke animasi kayuh sesuai tingkat dan arah saat itu.

**Dorongan kecepatan** (`scripts/systems/dorongan_kecepatan.gd`, GDD 15): geseran sepeda di bingkai layar dihitung dari kecepatan SEBENARNYA, bukan dari stick. Nol di 3,0 u/d (santai), naik linear ke 28 px di 6,0 u/d (ngebut), turun linear ke −20 px di 1,5 u/d (melambat), dijepit di luar rentang itu; arah sejajar jalan (kemiringan persis 2:1). Hanya kamera yang bergeser (sepeda tampil di letak dasar + geseran); posisi dunia, posisi sprite, dan HUD tidak berubah. Geseran total ngebut ke melambat = 48 px game datar (sekitar 144 px layar di ×3). Konsekuensi yang sengaja disetel di HP: sepeda yang maju di layar memperpendek jalan yang terlihat di depan saat waktu bereaksi paling sempit, jadi nilainya sengaja kecil.

---

## 3. Stamina

| Angka | Usulan |
|---|---|
| Stamina maksimum | 100 |
| Santai | +2 / detik (pulih pelan) |
| Cepat | −4 / detik |
| Ngebut | −12 / detik |
| Meluncur atau melambat | +15 / detik |
| Turunan | +10 / detik tambahan (distrik dengan medan) |
| Stamina habis | Kecepatan maksimum turun ke cepat sampai stamina kembali 30 |

Dari penuh, ngebut terus bertahan sekitar 8 detik, dan cepat terus sekitar 25 detik. Meluncur mengisi penuh dalam sekitar 7 detik. Tujuannya: ngebut dipakai untuk menyusul tenggat atau melewati rintangan, bukan sepanjang rute (GDD 2, prinsip 1).

**Rumus stamina** (`BikeMotion`, run fase1a-gerak; angka di `config.gd` bagian "Stamina", semua usulan). Maksimum dan awal 100, dijepit 0..100. Laju per detik:
- stick ke bawah (meluncur atau melambat) atau rem aktif: **+15** (`STAMINA_LAJU_MELUNCUR`);
- selain itu dari **kecepatan sebenarnya**, linear per potong: ≤ 3,0 u/d → +2, 4,5 → −4, ≥ 6,0 → −12, di antaranya interpolasi linear (mis. 3,75 → −1, 5,25 → −8). Tidak ada lompatan di ambang tingkat, dan percepatan dari santai ke ngebut ikut menguras bertahap. Per langkah dihitung tepat: rampa kecepatan dipotong di titik patah 3,0 dan 4,5, dan di tiap potongan laju linear terhadap waktu, jadi hasilnya tidak bergantung pada pembagian `dt` (dites 1/30 lawan 1/240; satu-satunya selisih datang dari jepit 100 yang diterapkan di akhir langkah, di bawah 0,01 poin).
- **Habis:** stamina mencapai 0 menyalakan `lelah`; selama lelah kecepatan tujuan dijepit ke 4,5 (turun dengan 2,0 u/d² bila di atasnya) dan sprite dijepit ke cepat. Lelah padam saat stamina **≥ 30** (`STAMINA_PULIH_AMBANG`). Di 4,5 lajunya −4, jadi stamina tetap 0 sampai pemain melonggarkan stick: disengaja (ngebut punya harga, prinsip 1).
- Durasi hasil rumus (dites): dari penuh, ngebut terus mulai santai habis sekitar 9,0 detik (8,0-9,5); cepat terus sekitar 25,4 detik (24-27); dari 0 meluncur penuh 6,7 detik; lelah padam sesudah sekitar 2 detik meluncur. Turunan (+10) belum dipakai (distrik bermedan, di luar run ini).

---

## 4. Lemparan

| Angka | Usulan | Catatan |
|---|---|---|
| Swipe minimum | 6% lebar layar | Lebih pendek dari ini diabaikan |
| Swipe maksimum dihitung | 35% lebar layar | |
| Jarak lempar ke samping | 1,5 ubin (swipe pendek) sampai 5 ubin (swipe panjang) | Linear terhadap panjang swipe |
| Lama terbang | 0,45–0,75 detik | Naik dengan jarak |
| Tinggi puncak | 1,0–1,6 ubin | Bayangan koran di tanah wajib tampil |
| Warisan kecepatan sepeda | 100% ke arah maju | Ngebut membuat koran mendarat lebih jauh ke depan (GDD 5.1) |
| Jeda antar lemparan | 0,35 detik | |
| Jumlah koran di awal rute | pelanggan + 20% | 25 pelanggan → 30 koran |

Garis bidik menunjukkan titik mendarat **sudah termasuk** warisan kecepatan, supaya pemain belajar melempar lebih awal saat ngebut lewat apa yang dilihat, bukan coba-coba.

---

## 5. Sasaran dan skor

| Mendarat di | Antaran | Skor | Catatan |
|---|---|---|---|
| Kotak surat | ✅ | 100% | |
| Teras | ✅ | 100% | Pelanggan pemberi tip memberi tip |
| Halaman / rumput | ✅ | 50% | Pelanggan cerewet kesal (GDD 8) |
| Jendela | belum diputuskan | | Bonus atau penalti (ROADMAP 5) |
| Rumah bukan pelanggan, jalan, sisi salah | ❌ meleset | 0 | Memutus combo |

| Angka | Usulan |
|---|---|
| Combo | +0,1 pengali tiap antaran beruntun, maksimum ×2,0 |
| Combo putus | Meleset atau tabrakan |
| Bonus zigzag (seberang ↔ dekat bergantian) | +0,05 pengali tambahan, mulai distrik dua sisi |
| Pengali kecepatan saat melempar | santai ×1,0 · cepat ×1,2 · ngebut ×1,5 |

**Skor dan koin dipisah (usulan):** skor dipakai untuk milestone keahlian dan rasa main, sedangkan koin hanya dari ongkos antar, tip, dan hadiah misi (bagian 7), supaya ekonomi tetap dekat dengan patokan dunia nyata. Hubungan keduanya perlu diputuskan setelah prototype 3.

---

## 6. Rute, tenggat, dan tabrakan

| Angka | Usulan | Catatan |
|---|---|---|
| Lebar petak rumah | 4 ubin | Rumah 3 ubin + celah 1 ubin |
| Rute awal perumahan | 25 pelanggan di sisi seberang, panjang sekitar 250 ubin | Distrik pertama hanya satu sisi. Sela antar pelanggan diisi rumah bukan pelanggan, persimpangan, dan taman |
| Jarak rata-rata antar pelanggan | sekitar 9 ubin | Sekitar 2 detik pada kecepatan cepat, 3 detik pada santai |
| Lama rute | sekitar 55 detik (cepat) sampai 85 detik (santai) | |
| Tenggat | waktu tempuh rute pada kecepatan santai × 1,15 (sekitar 95 detik) | Santai terus masih sempat, tapi berhenti lama untuk misi butuh ngebut di bagian lain |
| Tabrakan | kecepatan turun ke 1,0 u/d, oleng 0,6 detik, combo putus | Tidak menghentikan rute |

Apakah ada game over atau batas tabrakan per hari masih terbuka (GDD 3.2).

---

## 7. Ekonomi

Patokan dari GDD 14.1 (diputuskan sebagai acuan). Angka bengkel di bawah adalah usulan.

| Angka | Nilai |
|---|---|
| 1 koin | Rp100 |
| Ongkos satu pengantaran | 15 koin (rentang 6–20 tergantung jenis koran) |
| Pemasukan satu hari rapi (25 rumah) | 300–375 koin |
| Tip pelanggan pemberi tip (teras tepat) | 5 koin (usulan) |
| Hadiah misi kecil / sedang / besar | 45 / 75 / 120 koin |
| Tambal ban | 100–150 koin (sekitar 1–2 jam kerja loper, usulan) |
| Servis rem | 80 koin (usulan) |
| Sambung / ganti rantai | 150 koin (usulan) |
| Upgrade komponen tingkat 1 | 500–800 koin, sekitar 2 hari kerja (usulan) |

Gagal misi tidak pernah mengurangi koin (GDD 10.5).

### 7.1 Ekonomi cerita (usulan, direvisi 2026-10-08)

Detail dan alasan ada di `STORY.md` bagian 4.1. Semua angka masuk `scripts/config.gd`.

| Parameter | Nilai awal |
|---|---|
| Target Tabungan Kuliah | 25.000 koin (Rp2.500.000) |
| Total kebutuhan awal kuliah / sumbangan keluarga | 50.000 / 25.000 koin |
| `HARI_CERITA` (kalender cerita) | 120 hari (20 April sampai 18 Agustus) |
| `HARI_CERITA_PER_RUTE` | 2 (satu rute dimainkan = hari utama + hari ringkas), jadi 60 rute, sekitar 5 jam |
| `PERSEN_HARI_RINGKAS` | 90 (pendapatan hari ringkas = 90% hari utama) |
| Pendapatan kotor hari utama (rata-rata) / per rute | sekitar 400 / 760 koin |
| Setoran Keluarga / Bengkel / Tabungan | 35% / 15% / 50% (tabungan sekitar 380 koin per rute) |
| Tabungan pemain rata-rata di akhir | sekitar 22.800 koin (91%) |
| Ambang akhir (hari ke-120) | Mandiri 100%; Dibantu warga 70 sampai 99% dan reputasi rata-rata minimal 60; di bawah itu Tunda setahun |

## 8. Keausan sepeda

Belum diisi. Diputuskan di Fase 6 bersama layar bengkel (GDD 12.5). Arah yang sudah disepakati: ngebut dan sering mengerem mempercepat aus, kejadian di rute (paku, kaca, genangan) bisa langsung merusak, setiap kerusakan punya tanda peringatan, dan kerusakan hanya menghambat.

---

## 9. Target yang dicek

| Target | Cara cek |
|---|---|
| Pemain yang santai terus dan tidak berhenti masih menyelesaikan rute sebelum tenggat | Tes logika: waktu tempuh rute ≤ tenggat |
| Ngebut tidak bisa dipakai sepanjang rute | Tes logika: stamina habis sebelum 25% rute |
| Satu hari rapi menghasilkan 300–375 koin | Tes logika dari jumlah pelanggan × ongkos |
| Lemparan bisa mengenai kotak surat di ketiga kecepatan | Uji HP (Fase 2) |
| 60–70% pemain baru menyelesaikan misi yang diambil | Playtest (GDD 10.8) |

---

## 10. Catatan perubahan

- **2026-10-13** — Run fase1a-gerak: `BikeMotion` menggantikan `BikeDrive` (bagian 2): rem tanpa tombol sampai berhenti, meluncur, stamina dengan laju linear per potong dan lelah (bagian 3), lateral analog dengan batas tepi jalan resmi ±1 ubin, jeda, pose meluncur/rem dari fisika, dan laju kayuh dari kecepatan. Angka lama BALANCING 2-3 tidak berubah (uji HP Fase 0 lolos tanpa permintaan ubah); angka baru: toleransi rem, toleransi pose 0,05 u/d, `PEDAL_RATE_MAKS` 1,5, bar stamina merah di bawah 30. Semua usulan sampai uji HP Run 1A.
- **2026-10-07** — Angka awal ditulis sebagai usulan untuk Fase 0–3. Belum ada yang diuji.
