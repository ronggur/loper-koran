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
- **Lateral** analog bebas (keputusan pemilik 2026-10-13, tanpa kunci atau snap jalur): komponen datar × 3,0 u/d, dijepit ke tepi trotoar ±2,0 ubin (`JALAN_LEBAR_UBIN` / 2 + `JALAN_TROTOAR_UBIN`) sebagai **batas tepi jalan resmi**; sepeda boleh naik trotoar, rumput halaman tetap di luar (permintaan pemilik 2026-10-16; sebelumnya tepi aspal ±1,0). Positif = sisi `dekat`, negatif = sisi `seberang`; kidal tidak mengubah arti sumbu. Kecepatan lateral efektif 0 bila terhalang tepi. Lateral tetap bekerja saat berhenti dengan rem (arah sprite 90°).
- **Pose sprite** (`LoperAnim.pose_dari_gerak`, keputusan pemilik "ikuti fisika"): (1) rem aktif = `rem_<arah>`, juga di kecepatan 0; (2) stick ke bawah dan kecepatan sebenarnya masih di atas tujuan lebih dari `POSE_MELUNCUR_TOLERANSI_UD` (0,05 u/d) = `meluncur_<arah>` (kaki diam); (3) stick ke bawah dan sudah sampai tujuan = `melambat_<arah>` (kayuh 4 fps); (4) selain itu kayuh dengan tingkat dari stick, **dijepit ke cepat selama lelah**. Toleransi 0,05 mencegah stick yang hanya bergetar membuat pose berkedip; akibatnya stick bawah 15,1% (tujuan 2,998) langsung melambat. Lempar dari meluncur atau rem memakai lempar santai.
- **Laju kayuh** (`LoperAnim.pedal_rate`): untuk kayuh dan melambat = kecepatan sebenarnya / kecepatan nominal tingkat (santai 3,0, cepat 4,5, ngebut 6,0, melambat 1,5), dijepit 0 sampai `PEDAL_RATE_MAKS` (1,5). Meluncur dan rem = 1 (animasinya napas dan getar dari `.tres`). Lempar tidak terpengaruh.
- **Jeda** (`JedaSim`, rule `gdscript`; diubah run fase1b-umpan-balik 2026-10-14, keputusan pemilik): tombol jeda, app di-background atau kehilangan fokus, dan tombol back Android membuka **layar jeda**; simulasi berhenti (dt 0), `SceneTree.paused` menghentikan sprite, partikel, dan input, stick dan swipe dilepas, lempar ditutup, lama tahan rem kembali 0. **Tidak ada lanjut otomatis** (RESUMED dan FOCUS_IN tidak berpengaruh); lanjut hanya lewat tombol "Lanjut" atau back saat layar jeda terbuka. Langkah pertama sesudah lanjut ber-dt 0, stick harus disentuh ulang, rem harus ditahan ulang 0,25 detik.

| Angka baru (run fase1a-gerak) | Usulan | Catatan |
|---|---|---|
| Batas tepi jalan resmi | ±2,0 ubin (setengah `JALAN_LEBAR_UBIN` 2,0 + `JALAN_TROTOAR_UBIN` 1,0; sebelum 2026-10-16 ±1,0 = tepi aspal) | `BikeMotion.batas_lateral_ubin`; ThrowSolver dan cakupan ubin tanah memakai fungsi yang sama |
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
| Lebar jalan scene uji | 2 ubin aspal + 1 ubin trotoar tiap sisi, geser lateral ±2 ubin (sejak 2026-10-16; dulu ±1) | `JALAN_LEBAR_UBIN`; sejak run fase1a-gerak batas tepi jalan resmi (lateral analog bebas, tanpa kunci jalur, keputusan pemilik 2026-10-13) |
| Letak dasar sepeda di layar | 33,33% lebar, **75% tinggi** (dulu 60%) | `KAMERA_SEPEDA_*_PECAHAN`; sepertiga kiri dikunci (ART_DIRECTION 2.2), ±8 px di 640, 780, 800 saat geseran dorongan = 0 (santai). 75% dari paket pemilik 2026-10-14 (usulan): dengan dorongan mundur penuh, sel sprite 46×58 berakhir di y 292, satu piksel di atas panel kecepatan (y 293, tinggi 59 dengan teks 8 px) di 640, 780, dan 800, tangan kanan dan kidal (`tests/tes_tata_letak.gd`); 0,75 tidak menabrak, jadi dipakai apa adanya |
| Dorongan maju (ngebut) | **36** px game datar (dulu 28), naik ke kanan atas 2:1 (36, −18) | `DORONGAN_MAJU_PX`; GDD 15, usulan (permintaan Ronggur 2026-10-09; 36 dari paket pemilik 2026-10-14 bersama sepeda turun ke 75%), disetel di HP |
| Dorongan mundur (melambat) | 20 px game datar, turun ke kiri bawah 2:1 (−20, +10) | `DORONGAN_MUNDUR_PX`; usulan |
| Respon dorongan | 0,35 detik | `DORONGAN_RESPON_DETIK`; konstanta waktu penghalusan eksponensial, bebas framerate |
| Tinggi tombol strip atas dan tombol "Lanjut" | 42 px game (44 dp di A54 450 dpi ×3 = 41,7) | `HUD_TOMBOL_TINGGI_PX`; paket pemilik 2026-10-14 (dulu 36 = 38 dp); muat di strip atas: 4 + 42 = 46 < 48. Usulan, belum diuji di HP |
| Tombol kidal dan tombol mode bantu | masing-masing ≥ 96×42 px game, satu baris di tengah strip atas, jarak 8 px | `HUD_TOMBOL_LEBAR_PX`, `HUD_TOMBOL_TINGGI_PX`, `HUD_TOMBOL_JARAK_PX` (run fase2b-bantu-audio, D-7); tidak dicerminkan saat kidal; usulan |
| Tombol jeda | area sentuh 42×42 px game, gambar 24×24 di (26, 8) | `HUD_JEDA_*`; area sentuh x 17–59, y 4–46 di strip atas, tidak dicerminkan saat kidal (DESIGN_SPEC 3.1); usulan |
| Ambang swipe lempar | 6% lebar viewport game, inklusif (38,4 px di 640, 46,8 di 780, 48 di 800) | `LEMPAR_SWIPE_MIN_PECAHAN`, diukur dari panjang penuh \|v\| ke arah mana pun (bagian 4; run fase2a-lemparan memakai komponen mendatar \|dx\|, diganti run fase2-arah-bebas). Menggantikan 12 px panjang total (`LEMPAR_SWIPE_AMBANG_PX`, run sprite-lempar-melambat) sejak run fase2a-lemparan; usulan, belum diuji di HP, jangan dikunci sebelum uji |
| Frame koran lepas | indeks 2 | `LEMPAR_FRAME_LEPAS`; fakta sprite (`release_frame` di `loper_agen_lempar.json`), bukan angka tuning; dijaga tes terhadap JSON |
| Toleransi waktu frame | 0,000001 detik | `LEMPAR_TOLERANSI_DETIK`; hanya meredam derau float di batas frame, tidak mengubah rasa |

**Animasi melambat dan lempar** (usulan, run sprite-lempar-melambat; `scripts/systems/loper_anim.gd`, `lempar_waktu.gd`, `scripts/entities/loper_sprite.gd`; belum ada proyektil, skor, atau sasaran, itu Fase 2). fps tidak ada di `config.gd`: dibaca dari `loper_agen_frames.tres` (kayuh 8/10/12, melambat 4, lempar 12).
- **Sisi dari arah swipe** (GDD 5.2, `ThrowSolver.sisi_dari_swipe`; arah bebas sejak run fase2-arah-bebas): sisi dari komponen melintang arah tanah swipe (bagian 4), jadi ke kiri atau ke atas layar = sisi `seberang`, ke kanan atau ke bawah layar = sisi `dekat`, dan swipe tepat searah sumbu jalan di layar = `dekat`; opsi kidal hanya menukar zona, bukan arti sisi. Tidak melempar hanya bila panjang swipe \|v\| di bawah 6% lebar viewport game atau titiknya tidak sah; tidak ada sudut yang ditolak (Run 2A menolak swipe yang lebih tegak dari 45°).
- **Animasi** `lempar_<sisi>_<kecepatan>_<arah>` dengan kecepatan = tingkat sprite saat swipe dilepas (melambat memakai santai, tidak ada lempar melambat) dan arah = arah sprite saat itu (arah 90° belum ada gambarnya, jadi memakai serong di sisi yang sama). Sekali putar, 4 frame, 12 fps, sekitar 0,33 detik; koran lepas di frame 2 (sekitar 0,17 detik).
- Sejak run fase2a-lemparan (D-9) animasi lempar **tidak** menolak swipe sendiri: yang menolak hanya jeda antar lemparan 0,35 detik dan sisa koran (bagian 4). Lempar baru yang datang saat animasi lama masih berjalan menutup lempar lama dulu (`koran_lepas` bila belum, lalu `lempar_selesai`) lalu mulai dari frame 0. Setelah selesai sprite kembali ke animasi kayuh sesuai tingkat dan arah saat itu.

**Dorongan kecepatan** (`scripts/systems/dorongan_kecepatan.gd`, GDD 15): geseran sepeda di bingkai layar dihitung dari kecepatan SEBENARNYA, bukan dari stick. Nol di 3,0 u/d (santai), naik linear ke 36 px di 6,0 u/d (ngebut), turun linear ke −20 px di 1,5 u/d (melambat), dijepit di luar rentang itu; arah sejajar jalan (kemiringan persis 2:1). Hanya kamera yang bergeser (sepeda tampil di letak dasar + geseran); posisi dunia, posisi sprite, dan HUD tidak berubah. Geseran total ngebut ke melambat = 56 px game datar (sekitar 168 px layar di ×3). Konsekuensi yang sengaja disetel di HP: sepeda yang maju di layar memperpendek jalan yang terlihat di depan saat waktu bereaksi paling sempit, jadi nilainya sengaja kecil.

**Umpan balik kecepatan** (`scripts/systems/umpan_balik_kecepatan.gd`, GDD 15, run fase1b-umpan-balik 2026-10-14; semua usulan, dinilai di HP). Dihitung dari kecepatan SEBENARNYA, bukan stick; NaN, tak hingga, dan negatif = 0.

| Angka | Usulan | Catatan |
|---|---|---|
| Debu roda | 0 di bawah 3,0 u/d; dari 3,0 (inklusif) 4 naik linear ke 24 partikel/detik di 6,0, dijepit | `UMPAN_DEBU_*`; santai sudah berdebu tipis |
| Debu rem | 40 partikel/detik selama rem aktif dan kecepatan > 0; 0 saat berhenti | `UMPAN_DEBU_REM_LAJU`; laju tersendiri, juga di bawah 3,0 |
| Garis kecepatan | 0 di bawah 4,5 u/d; dari 4,5 (inklusif) kekuatan 0,25 naik linear ke 1 di 6,0, dijepit; laju = kekuatan × 14 garis/detik | `UMPAN_GARIS_*` |
| Kurangi efek | garis mati, debu × 0,5; bawaan mati | `UMPAN_KURANGI_EFEK`, `UMPAN_KURANGI_DEBU_PENGALI`; rule `ui-scenes`, belum ada UI (Pengaturan Fase 3) |
| Batas partikel hidup | 24 debu, 6 garis | `UMPAN_DEBU_BATAS`, `UMPAN_GARIS_BATAS` (TECH_PLAN 3.7) |
| Debu: umur, kecepatan, ukuran | 0,4 detik, 40 px/detik ke belakang, kotak 1–2 px, muncul di (−12, +2) dari titik pijak, sebaran ±2 px | tampilan |
| Garis: umur, kecepatan, panjang | 0,3 detik, 200 px/detik ke belakang, 14 px datar bertangga 2:1, muncul di (30, −24), sebaran ±26 px | tampilan |

Selama jeda partikel berhenti (tidak memancar, tidak bergerak) karena `SceneTree.paused`.

**Bunyi sepeda** (`scripts/systems/bunyi_sepeda.gd` + autoload `Audio`, SOUND_DESIGN 3.2, run fase1b-umpan-balik 2026-10-14; semua usulan, dinilai di HP). Dari keadaan SEBENARNYA: pose kayuh atau melambat = loop kayuhan, meluncur = loop freewheel, rem = decit sekali di tepi naik rem (tidak diulang selama ditahan, tidak di kecepatan 0) lalu diam, kecepatan 0 tanpa rem = diam, jeda = semua diam tanpa decit tertunda.

| Angka | Usulan | Catatan |
|---|---|---|
| Pitch loop kayuhan | 1,0 di santai 3,0 u/d, 1,15 di cepat 4,5, 1,3 di ngebut 6,0; linear per potong di antaranya, dijepit 1,0..1,3 (melambat tetap 1,0) | `AUDIO_KAYUH_PITCH_*` (SOUND_DESIGN 3.2); titik kecepatan dari `KECEPATAN_*_UD` |
| Volume kayuhan, freewheel, rem | −6, −10, −3 dB | `AUDIO_*_VOLUME_DB`; ketiga WAV dinormalkan ke puncak yang sama (−1 dBFS), jadi keras-pelan relatif hanya di sini. Kayuhan di bawah suara sasaran (SOUND_DESIGN 6), freewheel pelan |

**Bunyi lempar dan mendarat** (`scripts/systems/bunyi_lempar.gd` + autoload `Audio`, bus `SFX`, SOUND_DESIGN 3.1 dan 4.2, run fase2b-bantu-audio 2026-10-15; usulan, dinilai di HP). Satu "wus" per lemparan yang diterima (swipe dan tap mode bantu), satu bunyi mendarat per koran dengan permukaan dari hasil sasaran (bagian 5): kotak surat, teras, halaman = rumput, meleset dan bukan pelanggan = meleset, jendela = teras bila bonus (sah) atau meleset bila penalti. Tiga variasi per permukaan bergiliran 01, 02, 03, 01 (tanpa acak). Jeda dan background menghentikannya seketika.

| Angka | Usulan | Catatan |
|---|---|---|
| Volume "wus" | −4 dB | `AUDIO_WUS_VOLUME_DB`; sedikit di atas kayuhan (−6), di bawah bunyi mendarat |
| Volume bunyi mendarat | −1 dB (keempat permukaan) | `AUDIO_MENDARAT_VOLUME_DB`; di atas kayuhan supaya hasil lemparan selalu terdengar (SOUND_DESIGN 6). Meleset sudah sekitar 5 dB lebih pelan di berkasnya (puncak 0,5 lawan 0,89), jadi tidak perlu angka volume terpisah |

**Bunyi rute** (`scripts/systems/bunyi_rute.gd`, nada combo di `bunyi_lempar.gd`, autoload `Audio` bus `SFX`; SOUND_DESIGN 3.1, 3.3, 4.3; run fase3b-rintangan-skor 2026-10-16, usulan, dinilai di HP). Nada combo: antaran sah ke-n diputar n − 1 setengah nada lebih tinggi (pitch 2^(tingkat/12)), paling tinggi 5 tingkat lalu bertahan; meleset dan koran ke rumah terantar di nada dasar. "Kring kring!" +1 setengah nada.

| Angka | Usulan | Catatan |
|---|---|---|
| Nada combo | 5 tingkat setengah nada (pitch maks 1,3348) | `AUDIO_COMBO_NADA_MAKS`, `AUDIO_SETENGAH_NADA_PER_OKTAF` 12, `AUDIO_RASIO_OKTAF` 2 |
| Bel kedua | +1 setengah nada (1,0595) | `AUDIO_BEL_KEDUA_SETENGAH_NADA` |
| Volume bel, rintangan, tabrakan, tip/tepat | −2, −3, −2, −3 dB | `AUDIO_BEL_VOLUME_DB`, `AUDIO_RINTANGAN_VOLUME_DB`, `AUDIO_TABRAKAN_VOLUME_DB`, `AUDIO_TIP_VOLUME_DB`; peringatan di atas kayuhan (−6); tabrakan sudah sekitar 3 dB lebih pelan di berkasnya (lembut, SOUND_DESIGN 2) |

**Jalan terlihat di depan saat ngebut** (run fase1b-umpan-balik, dihitung dari garis tengah jalan: titik pijak sepeda + dorongan maju penuh sampai tepi layar, 1 ubin maju = 32 px datar, 6,0 u/d): 780 (A54) dari sekitar 2,10 detik (0,6 dan 28 px) menjadi sekitar **2,52 detik**; 800 dari 2,10 menjadi sekitar 2,59 detik. Di **640 (16:9)** jalan keluar layar lewat tepi kanan, bukan tepi atas, jadi menurunkan sepeda tidak menolong dan dorongan 36 sedikit memperpendek: dari sekitar 2,08 menjadi sekitar 2,03 detik (tanpa dorongan 2,22 detik di keduanya). Dinilai di HP (NEEDS-MANUAL).

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
| Swipe minimum | 6% lebar viewport game | Panjang penuh \|v\| ke arah mana pun; lebih pendek dari ini diabaikan (inklusif di 6%). `LEMPAR_SWIPE_MIN_PECAHAN` |
| Swipe maksimum dihitung | 35% lebar viewport game | Lebih panjang dijepit. `LEMPAR_SWIPE_MAKS_PECAHAN` |
| Jarak lempar | 1,5 ubin (swipe pendek) sampai 5 ubin (swipe panjang) | Linear terhadap panjang swipe, dari titik lepas searah arah swipe di tanah (arah bebas). `LEMPAR_JARAK_*_UBIN` |
| Lama terbang | 0,45–0,75 detik | Naik dengan jarak. `LEMPAR_TERBANG_*_DETIK` |
| Tinggi puncak | 1,0–1,6 ubin | Bayangan koran di tanah wajib tampil. `LEMPAR_PUNCAK_*_UBIN`; lengkung mulai dari tinggi tangan 0,7 ubin (`LEMPAR_TINGGI_TANGAN_UBIN`) |
| Warisan kecepatan sepeda | 100% ke arah maju | Ngebut membuat koran mendarat lebih jauh ke depan (GDD 5.1). `LEMPAR_WARISAN_MAJU`; tanpa warisan lateral |
| Jeda antar lemparan | 0,35 detik | Inklusif, dari lemparan diterima. `LEMPAR_JEDA_DETIK` |
| Jumlah koran di awal rute | pelanggan + 20% dibulatkan ke atas | 25 pelanggan → 30 koran. Rumus: pelanggan + ceil(pelanggan × `RUTE_KORAN_CADANGAN_PERSEN` / 100) (`RouteBuilder.koran_awal`, usulan run fase3a-rute); contoh 10 → 12, 11 → 14. Jalan uji: `KORAN_AWAL` 30 |

Garis bidik menunjukkan titik mendarat **sudah termasuk** warisan kecepatan, supaya pemain belajar melempar lebih awal saat ngebut lewat apa yang dilihat, bukan coba-coba.

**Rumus `ThrowSolver`** (`scripts/systems/throw_solver.gd`, run fase2a-lemparan 2026-10-14, arah bebas run fase2-arah-bebas 2026-10-15; semua usulan, dinilai di HP). Satu-satunya sumber lintasan: koran terbang, garis bidik, elips pendaratan, dan bayangan memanggil fungsi yang sama, jadi prediksi = hasil.

- **Arah bebas** (keputusan pemilik 2026-10-15, GDD 5.2; rinciannya usulan): v = titik akhir − titik awal swipe (piksel game). Arah tanah = `Iso.layar_ke_dunia(v)` dinormalkan, jadi garis tanah lemparan di layar sejajar jari. Tidak ada sudut yang ditolak, termasuk ke bawah dan ke belakang. Swipe ke atas = rumah seberang di depan, ke kanan = sisi dekat ke depan, ke kiri murni = seberang **sedikit ke belakang**, ke bawah = sisi dekat ke belakang.
- **Panjang swipe** = panjang penuh \|v\| (piksel game) terhadap **lebar viewport game saat itu** (640, 780, atau 800). min = 6%, maks = 35% (`LEMPAR_SWIPE_MIN_PECAHAN`, `LEMPAR_SWIPE_MAKS_PECAHAN`). \|v\| < min = tidak melempar (tanpa garis bidik, koran tidak terpakai); tepat min melempar (inklusif, toleransi `LEMPAR_SWIPE_TOLERANSI_PX` 0,001 px untuk derau presisi tunggal posisi sentuh). Run 2A memakai komponen mendatar saja dan menolak swipe yang lebih tegak dari 45°; aturan itu dihapus.
- **Kekuatan** u = jepit((\|v\| − min) / (maks − min), 0, 1), sama di semua arah. Jarak tanah = lerp(1,5, 5,0, u) ubin dari titik lepas searah arah tanah; lama terbang = lerp(0,45, 0,75, u) detik; tinggi puncak = lerp(1,0, 1,6, u) ubin (`LEMPAR_JARAK_*`, `LEMPAR_TERBANG_*`, `LEMPAR_PUNCAK_*`).
- **Sisi** (hanya untuk animasi lempar kiri/kanan) dari komponen melintang arah tanah: ke seberang = `SEBERANG`, ke dekat = `DEKAT`, tepat searah sumbu jalan di layar (x tanah = 0) = `DEKAT`. Kidal tidak mengubah arti arah. Zona sasaran menilai dari titik mendarat saja (bagian 5).
- **Warisan maju** 100% (`LEMPAR_WARISAN_MAJU` 1,0): geser maju selama terbang = kecepatan maju sebenarnya × lama terbang. Contoh swipe pendek (u 0): santai 3,0 u/d = 1,35 ubin ke depan, ngebut 6,0 u/d = 2,7 ubin. Tidak ada warisan lateral selama terbang.
- **Jeda lepas** (D-4): lintasan ditetapkan sekali saat jari dilepas lalu dibekukan di dunia. Koran lepas dari tangan di frame lepas animasi (frame 2 dari 4 di 12 fps = 2/12 ≈ 0,17 detik, `LemparWaktu.waktu_lepas`; fps dari `.tres`, bukan angka baru), jadi titik lepas = posisi sepeda saat jari dilepas + kecepatan sepeda (maju dan lateral) × jeda lepas, lateral dijepit ke tepi jalan resmi (±2 ubin = tepi trotoar). Garis bidik memakai panggilan yang sama, jadi jeda ini sudah ada di prediksi; sepeda yang mempercepat, mengerem, atau pindah sisi sesudah jari dilepas tidak mengubah titik mendarat.
- **Lengkung**: tinggi parabola dari tinggi tangan `LEMPAR_TINGGI_TANGAN_UBIN` 0,7 ubin (sekitar 22 px, setinggi setang) ke 0 dengan maksimum tepat tinggi puncak; posisi tanah linear dari titik lepas ke titik mendarat. Tinggi diproyeksikan hanya di `Iso` (1 ubin tinggi = 32 px ke atas), posisi gambar dibulatkan ke piksel.
- **Jeda antar lemparan** 0,35 detik (`LEMPAR_JEDA_DETIK`) dihitung dari lemparan diterima (jari dilepas) sampai lemparan berikutnya boleh diterima, inklusif (toleransi `LEMPAR_TOLERANSI_DETIK`): 0,349 ditolak, 0,35 diterima; swipe yang ditolak tidak mengurangi koran (`SisaKoran`).
- **Koran awal** jalan uji 30 (`KORAN_AWAL`, 25 pelanggan + 20%); tiap lemparan yang diterima mengurangi tepat 1; habis = swipe tidak melempar. Jalan uji tidak punya akhir rute, jadi sebagai **alat uji** (bukan aturan game) sisa koran kembali penuh sesudah habis dan sepeda menempuh 16 ubin (`JALAN_UJI_ISI_ULANG_UBIN`).
- **Di scene jalan uji** (bagian 1b): satu fungsi `JalanUji.lintasan_swipe` (posisi sepeda, kecepatan maju sebenarnya, kecepatan lateral efektif langkah terakhir, jeda lepas animasi) dipakai garis bidik tiap langkah (sesudah sepeda digerakkan). Saat jari dilepas, lemparan memakai **lintasan garis bidik yang terakhir tampil** untuk swipe itu (objek yang sama, dibekukan pada langkah terakhir), bukan menghitung ulang dari posisi lepas: jari yang masih bergerak atau berbelok ke arah mana pun saat diangkat (flick) tidak membatalkan lemparan dan tidak menggeser titik mendarat dari elips yang terlihat (yang terlihat = yang terjadi; QA-001 Run 2A, D-5 run fase2-arah-bebas). Lemparan batal **hanya** bila panjang swipe di posisi lepas \|v_lepas\| di bawah 6%, yaitu jari ditarik kembali ke dekat titik awal, walau garis bidik masih tampil (tidak ada koran, jadi tidak ada hasil yang berbeda dari prediksi). Tanpa garis bidik yang tampil untuk swipe itu (swipe turun dan naik di antara dua langkah, atau langkah terakhir menolak swipe karena masih pendek), lemparan dihitung dari posisi lepas dengan fungsi yang sama dan keadaan sepeda langkah terakhir; tidak ada prediksi tampil yang bisa berbeda. Garis bidik basi milik swipe yang dibatalkan tidak pernah dipakai swipe lain (`TouchRouter.nomor_swipe`). Koran (`KoranLempar`) tampil di udara mulai jeda lepas, mendarat dan dinilai di titik prediksi, lalu penandanya tampil 0,8 detik; waktunya ikut `dt` efektif, jadi jeda game membekukannya. Animasi lempar tidak lagi menolak swipe sendiri (D-9): yang menentukan hanya jeda 0,35 dan sisa koran. Angka tampilan (bukan angka lintasan) di `config.gd`: putaran koran 12 fps (4 langkah), bayangan 10 → 6 px (susut 2 px per ubin tinggi, alpha 0,85; dulu 8 → 4 px alpha 0,5, dinaikkan iterasi 2 QA-007 karena nyaris tak terlihat di aspal: kontras di aspal graybox sekitar 2,1:1 → 3,2:1, dites ≥ 3:1 di aspal, trotoar, rumput), penanda 7 px di atas titik mendarat, 96 sampel garis bidik, garis zona alpha 0,7, panel koran HUD (DESIGN_SPEC 3.5). Iterasi 2 (QA-004): titik garis bidik dan elips yang tertutup rumah dari sudut kamera digambar redup alpha 0,5 (`GARIS_BIDIK_TERTUTUP_ALPHA`), elipsnya putus-putus (DESIGN_SPEC 3.7); ukuran kotak rumah graybox 3 × 2 × 1,5 ubin (`JALAN_UJI_RUMAH_PANJANG/DALAM/TINGGI_UBIN`) adalah fakta aset `tools/env_art/graybox.py`, dijaga tes terhadap ukuran PNG, bukan angka setel.

### 4b. Mode bantu (usulan run fase2b-bantu-audio 2026-10-15, dinilai lewat uji HP)

Keputusan pemilik 2026-10-15 (K-1 sampai K-4, usulan) dan rinciannya (D-1 sampai D-6, usulan orchestrator). GDD 5.3. Logika di `scripts/systems/bantu_lempar.gd` (`BantuLempar`) dan `TouchRouter` (tap); scene di `JalanUji`.

- **Tap** (D-1): sentuhan yang mulai di zona swipe dan, selama seluruh hidupnya, panjang swipe \|v\| (dari titik awal ke posisi mana pun yang pernah dicapai, termasuk posisi lepas) tidak pernah mencapai swipe minimum 6% (`ThrowSolver.cukup_panjang`; tepat 6% = swipe). Sentuhan yang pernah ≥ 6% lalu ditarik kembali tetap **batal**, bukan tap. Tidak ada batas durasi, jadi tidak ada angka tap baru. Posisi tap = titik awal sentuhan. Di luar mode bantu tap tidak melakukan apa pun; swipe manual tetap melempar di mode bantu.
- **Sisi tap** (K-2, D-3): sisi = `ThrowSolver.sisi_dari_arah(ThrowSolver.arah_tanah(tap − titik pijak sepeda di layar))`, jadi pemisahnya garis searah jalan di layar (kemiringan 1:2) yang melewati sepeda: di atas garis = `seberang`, di bawah = `dekat`, tepat di garis = `dekat`. Garis ikut sepeda (kamera bergeser). Kidal tidak mengubahnya.
- **Sasaran** (K-3, D-4): kotak surat rumah **pelanggan** di sisi tap yang pusatnya di depan sepeda (maju pusat ≥ maju sepeda saat tap) dan bisa dicapai lintasan dengan u 0 sampai 1, warisan kecepatan maju 100%, dan jeda lepas yang sama dengan swipe. Dari yang terjangkau dipilih yang paling dekat di depan; seri = selisih lateral pusat ke sepeda terkecil, lalu urutan daftar zona.
- **Selalu kena, satu lintasan**: lintasan diarahkan ke pusat kotak surat. u dicari dengan bisection pada f(u) = \|R(u)\| − jarak tanah(u), R(u) = pusat − titik lepas − arah maju × geser maju(u); f turun tegas (jarak naik 3,5 ubin per u, \|R\| berubah paling banyak 1,8 ubin di ngebut), jadi akarnya tunggal dan terjangkau bila f(0) ≥ 0 ≥ f(1). Pencarian memakai bagian rumus `ThrowSolver` (`titik_lepas`, `jarak_ubin`, `geser_maju_ubin`); lintasan yang dipakai selalu keluaran `ThrowSolver.hitung` dengan panjang swipe setara u (`panjang_untuk_kekuatan`), dan titik mendaratnya dicek ulang: zona yang menang di titik itu harus kotak surat sasaran. Contoh: santai 3,0 u/d dari tengah jalan, kotak surat seberang terjangkau bila pusatnya sekitar 0 sampai 7,5 ubin di depan sepeda; ngebut 6,0 u/d sekitar 0 sampai 10 ubin.
- **Tanpa sasaran** = tidak melempar: koran tidak berkurang, jeda antar lempar tidak mulai, tanda kecil (cincin `TEXT_2`) tampil di titik tap selama 0,6 detik (D-6). Tap saat koran habis, saat jeda antar lempar, atau saat jeda game tidak melempar dan tidak memberi tanda.
- **Kecepatan otomatis** (K-1): tanpa sentuhan stick sepeda melaju santai 3,0 u/d (`KECEPATAN_SANTAI_UD`, perilaku stick netral yang sudah ada; santai tidak menguras stamina). Stick tetap aktif penuh. Mode bantu bisa dimainkan dengan satu jempol.
- **Jeda tetap** (K-4): jeda antar lempar 0,35 detik dan jeda lepas sekitar 0,17 detik sama dengan swipe; lintasan dihitung sekali dari keadaan sepeda langkah terakhir saat tap diterima lalu dibekukan.
- Rumah bukan pelanggan abu-abu di mode bantu menunggu radar (Fase 3, D-8). Efek kerusakan di mode bantu masih terbuka (ROADMAP 5).

| Angka | Usulan | Catatan |
|---|---|---|
| Lama tanda tanpa sasaran | 0,6 detik | `BANTU_TANDA_LAMA_DETIK`; ikut `dt` efektif (membeku saat jeda) |
| Toleransi pencarian u | 0,000001 ubin | `BANTU_TOLERANSI_UBIN`; hanya meredam derau float di ujung u 0 dan 1, jauh di bawah setengah lebar zona kotak surat (0,25) |
| Langkah bisection | 48 | `BANTU_CARI_ULANGAN`; ketelitian u sekitar 3,6e-15 |

---

## 5. Sasaran dan skor

| Mendarat di | Antaran | Skor | Catatan |
|---|---|---|---|
| Kotak surat | ✅ | 100% | |
| Teras | ✅ | 100% | Pelanggan pemberi tip memberi tip |
| Halaman / rumput | ✅ | 50% | Pelanggan cerewet kesal (GDD 8) |
| Jendela | sakelar, bawaan penalti ringan | | **Masih terbuka** (ROADMAP 5) sampai skor Fase 3. `JENDELA_KENA_BONUS` false (bawaan, keputusan pemilik 2026-10-14) = penalti ringan: antaran tidak sah seperti meleset, tanpa potong koin atau hukuman lain (prinsip 2); true = bonus: antaran sah, ditandai bonus |
| Rumah bukan pelanggan, jalan, di luar zona | ❌ meleset | 0 | Memutus combo |

**Zona sasaran placeholder jalan uji** (`scripts/systems/zona_sasaran.gd`, run fase2a-lemparan 2026-10-14; semua usulan, bukan data rute). Zona = persegi di bidang tanah, ubin: `[lateral_min, maju_min, lebar_lateral, panjang_maju]` (`Config.JALAN_UJI_SEBERANG_*_UBIN`, `JALAN_UJI_DEKAT_*_UBIN`), lateral dari garis tengah jalan (negatif = `seberang`), maju relatif terhadap awal kavling (kelipatan 4 ubin, `JALAN_UJI_RUMAH_PERIODE_UBIN`). Tepi min **inklusif**, tepi maks **eksklusif** di kedua sumbu, jadi dua zona bersebelahan tidak pernah sama-sama memuat satu titik.

| Zona | Seberang (lateral, maju, ukuran) | Dekat | Catatan |
|---|---|---|---|
| Kotak surat | −2,75, 1,25, 1,0 × 1,25 | 1,75, 1,25, 0,75 × 1,25 | AREA di **halaman**, bagian terluas sesudah teras (maju 1,25 sampai 2,5), pusat (−2,25; 1,875) dan (2,125; 1,875); menempel tepi trotoar dengan 0,25 ubin di atasnya. Dulu 1,0 × 1,5 di trotoar (−2,125, 0,375) dan sebelumnya 0,5 × 0,5 (usulan, lihat di bawah) |
| Halaman | −3,0, −0,5, 1,0 × 3,0 | 2,0, −0,5, 1,0 × 3,0 | Rumput sepanjang rumah. Rumah graybox seberang mundur dari −2,0 ke **−3,0** (`JALAN_UJI_RUMAH_X_UBIN`) supaya ada satu ubin halaman di depan fasad |
| Teras | −3,0, 0,0, 0,5 × 1,25 | 2,5, 0,25, 0,5 × 1,5 | Seberang di kaki fasad bagian pintu |
| Jendela | −3,0, 1,5, 0,25 × 0,75 | (tidak ada) | Strip tanah di kaki fasad (model placeholder 2D) |

- **Kotak surat dipindah ke halaman** (permintaan pemilik 2026-10-16, usulan, dinilai lewat uji HP): kotak surat sebelumnya di trotoar, padahal kotak surat nyata ada di halaman rumah (mock `ART_DIRECTION` 2.6) dan sepeda kini boleh naik trotoar. Halaman hanya 1 ubin lebar dan teras (maju 0 sampai 1,25) serta jendela (lateral −3,0 sampai −2,75) ada di kaki fasad, jadi area digeser ke **bagian halaman terluas**, sesudah teras: seberang `[−2,75; 1,25; 1,0 × 1,25]`, dekat `[1,75; 1,25; 0,75 × 1,25]` (lebih sempit supaya teras dekat tidak tertimpa). Tidak ada zona lain yang tertimpa selain halaman; teras dan jendela utuh (dites). Area turun dari 1,5 ke 1,25 ubin persegi seberang (sekitar −17%); toleransi jari lateral tetap sekitar ±6 mm, maju sekitar ±7,5 mm. 0,25 ubin area berada di atas trotoar supaya bisa dikenai dari sepeda di trotoar. Pusat berpindah ke (−2,25; maju + 1,875), jadi sasaran mode bantu bergeser; dari tepi trotoar (lateral −2,0) pusat hanya 0,25 ubin ke samping, di bawah jarak lempar terpendek 1,5, jadi harus dikenai dengan lemparan serong ke depan. Mode bantu dan keterjangkauan tetap lolos tes dari semua posisi lateral di jalan. Kotak surat bersprite di (−2,125; maju + 1,75), dan kotak surat dekat tetap tanpa sprite.
- **Kotak surat sebagai area** (tindak lanjut uji HP pemilik, 2026-10-16; usulan, dinilai lewat uji HP; letak lama di trotoar, kini lihat atas): pemilik mencoba di HP dan menilai zona kotak surat 0,5 × 0,5 terlalu kecil. Toleransi gerak jari sekitar ±3 mm (setengah sisi 0,25 ubin) dan di scene rute hanya kotak surat sasaran oranye (waktu itu kubus graybox) yang tergambar, jadi pemain tidak melihat area sebenarnya. Zona menjadi **1,0 × 1,5** (lateral × maju) dengan **pusat yang sama**, jadi sasaran mode bantu (`BantuLempar.pilih` membidik pusat) tidak bergeser. Toleransi lateral sekitar ±6 mm (dua kali), maju sekitar ±9 mm (tiga kali), area sekitar 6 kali. Zona yang membesar menimpa 0,125 ubin halaman di sisi trotoar (lateral −2,125 sampai −2,0 seberang, 2,0 sampai 2,125 dekat); kotak surat menang atas halaman (prioritas tidak berubah), disengaja. Zona seberang dan dekat tetap tidak bertumpuk (celah lateral −1,125 sampai 1,125 di jalan). Area ini digambar di tanah scene rute (`AreaKotakGambar`, isi tipis `AREA_KOTAK_ISI_ALPHA` dan garis tepi tegas) hanya untuk rumah pelanggan seberang. **Calon bonus presisi, belum diputuskan:** "inti" 0,5 × 0,5 di pusat area (zona lama) bisa menjadi antaran "tepat" dengan bonus skor atau combo di Run 3B; angka dan bentuk bonus menunggu keputusan pemilik dan uji HP. Sampai itu, seluruh area sah penuh (100%). **Diputuskan pemilik 2026-10-16 (K-4 run fase3b-rintangan-skor):** inti 0,5 × 0,5 di pusat area = antaran tepat, skor ×1,25 (usulan), bagian 5b.
- **Zona dari data rute** (run fase3a-rute, usulan): zona jalan uji dan zona rumah rute memakai SATU geometri (`Config.JALAN_UJI_*`), diparametrisasi awal kavling: `ZonaSasaran.zona_rumah_seberang` (kotak surat, halaman, teras, jendela) dan `zona_rumah_dekat` (kotak surat, halaman, teras) menerima jarak maju awal kavling (awal segmen + `pos` rumah). Rumah yang bukan pelanggan (termasuk semua rumah dekat di distrik perumahan) memberi zona `BUKAN_PELANGGAN`. `zona_rute_rentang` hanya menyiapkan kavling di sekitar jangkauan lemparan (rentang + satu petak di tiap ujung), bukan seluruh rute. Prioritas dan penilaian dari titik mendarat tidak berubah.
- **Prioritas** bila tumpang tindih: kotak surat > jendela > teras > halaman (teras dan jendela ada di dalam halaman). Zona yang menang dulu, baru status pelanggan: zona rumah bukan pelanggan = `BUKAN_PELANGGAN`. Penilaian dari **titik mendarat saja** (run fase2-arah-bebas, D-4): zona yang memuat titik itu menilai koran apa pun arah atau sisi lemparannya (Run 2A: zona hanya untuk lemparan ke sisinya). Zona seberang dan zona dekat tidak bertumpuk (dites). Di luar semua zona = meleset.
- **Bukan pelanggan**: rumah seberang bernomor n dengan n mod 4 = 2 (`JALAN_UJI_BUKAN_PELANGGAN_*`), minimal satu tiap putaran daur 9 slot. Kavling sisi dekat datar tanpa fasad dan tanpa jendela, selalu pelanggan, **hanya supaya lempar ke sisi dekat bisa diuji**; tidak memutuskan cara menampilkan rumah di sisi dekat (ROADMAP 5, Fase 3).
- **Status antaran**: kotak surat dan teras sah penuh, halaman sah setengah, bukan pelanggan dan meleset tidak sah, jendela menurut sakelar. Tiap pendaratan dinilai sendiri (status per rumah di luar scope Fase 2). Semua zona terjangkau dari posisi lateral di dalam jalan pada santai, cepat, dan ngebut dengan swipe min sampai maks (dites).
- **Penanda** di titik mendarat selama 0,8 detik (`PENANDA_LAMA_DETIK`, DESIGN_SPEC 3.6), bentuk tidak hanya warna: sah penuh = centang (`OK`), bonus jendela = bintang (beda dari sah biasa), halaman = setengah, tidak sah = silang kecil (`FAIL`, bukan panel merah besar).

| Angka | Usulan |
|---|---|
| Combo | +0,1 pengali tiap antaran beruntun, maksimum ×2,0 |
| Combo putus | Meleset, bukan pelanggan, jendela penalti, atau tabrakan |
| Bonus zigzag (seberang ↔ dekat bergantian) | +0,05 pengali tambahan, mulai distrik dua sisi (belum dipakai) |
| Pengali kecepatan saat melempar | santai ×1,0 · cepat ×1,2 · ngebut ×1,5 |
| Bonus presisi "tepat" | inti 0,5 × 0,5 di pusat area kotak surat: skor ×1,25 |

**Skor dan koin dipisah (keputusan pemilik 2026-10-16, K-2 run fase3b-rintangan-skor):** skor dipakai untuk milestone keahlian dan rasa main, sedangkan koin hanya dari ongkos antar, tip, dan hadiah misi (bagian 7), supaya ekonomi tetap dekat dengan patokan dunia nyata. Keduanya dihitung di rute sejak run 3B; skor tidak pernah menjadi koin dan sebaliknya.

### 5b. Skor, combo, tepat, dan rumah terantar (usulan run fase3b-rintangan-skor 2026-10-16, dinilai lewat uji HP)

Logika di `scripts/systems/skor_rute.gd` (`SkorRute`), satu sumber untuk HUD, umpan balik, dan bunyi; angka di `config.gd` (awalan `SKOR_`, `KOIN_`). Keputusan pemilik K-2 dan K-4, keputusan orchestrator O-1 sampai O-5 (SPEC run).

- **Rumus skor satu antaran:** `SKOR_SASARAN_DASAR` 100 × persen sasaran × pengali combo × pengali kecepatan × (`SKOR_TEPAT_PENGALI` 1,25 bila tepat). Persen sasaran: kotak surat, teras, dan jendela dengan sakelar bonus 100 (`SKOR_PERSEN_PENUH`); halaman 50 (`SKOR_PERSEN_HALAMAN`); meleset, bukan pelanggan, jendela dengan sakelar penalti 0.
- **Pembulatan:** semua pengali diubah ke bilangan bulat persen (×1,1 = 110, ×1,25 = 125) dan dikalikan sebagai bilangan bulat, lalu dibagi sekali dan **dibulatkan ke bilangan bulat terdekat, setengah ke atas**. Contoh: halaman, combo ×1,1, ngebut = 50 × 1,1 × 1,5 = 82,5 → 83; tepat, combo ×1,3, ngebut = 243,75 → 244; tepat, combo ×1,3, santai = 162,5 → 163.
- **Combo (kapan naik):** pengali = 1,0 + 0,1 × jumlah antaran sah beruntun **sebelum** antaran yang sedang dinilai, dijepit ×2,0. Antaran yang dinilai memakai pengali sebelum naik, lalu rangkaian bertambah satu. Jadi antaran ke-1 ×1,0, ke-2 ×1,1, ..., ke-11 dan seterusnya ×2,0 (santai: 100, 110, ..., 200, 200, ...). Halaman dan jendela bonus termasuk antaran sah (ikut menaikkan). Putus = kembali ke ×1,0.
- **Satu antaran per pelanggan (O-1):** antaran sah pertama ke rumah pelanggan menandainya terantar (juga halaman: tidak bisa "diperbaiki" dengan lemparan kedua). Koran berikutnya ke zona rumah itu (termasuk jendela penalti): 0 skor, 0 koin, combo **tidak putus dan tidak naik**, penanda netral (bentuk sendiri). Rumah bukan pelanggan tidak pernah terantar.
- **Pengali kecepatan (O-5):** dari kecepatan **sebenarnya** saat jari dilepas (`ThrowSolver.Lintasan.kecepatan_maju_ud`), bukan posisi stick. Pita sama dengan pita sprite: kecepatan dipetakan ke kekuatan setara (santai 3,0 = 0, ngebut 6,0 = 1) lalu ambang `SPRITE_AMBANG_CEPAT` 0,33 dan `SPRITE_AMBANG_NGEBUT` 0,80 (`LoperAnim.tingkat_dari_stick`). Hasil: santai di bawah sekitar 3,99 u/d (termasuk melambat dan berhenti), cepat sampai sekitar 5,4, ngebut di atasnya.
- **Tepat (K-4):** titik mendarat di inti 0,5 × 0,5 di pusat area kotak surat, seberang `[−2,5; 1,625; 0,5 × 0,5]` dan dekat `[1,875; 1,625; 0,5 × 0,5]` relatif awal kavling (`JALAN_UJI_*_KOTAK_SURAT_INTI_UBIN`), tepi min inklusif dan maks eksklusif seperti zona lain. Di area tapi di luar inti = kotak surat biasa. Tepat hanya untuk rumah pelanggan dan **tidak untuk mode bantu** (O-4: mode bantu membidik pusat, jadi akan selalu tepat); koin sama dengan kotak surat biasa. Penanda tepat berbeda bentuk dari centang dan bintang (DESIGN_SPEC 3.6).
- **Mode bantu (O-4):** dinilai lewat jalur yang sama (skor, combo, koin, tip seperti biasa), hanya tepat diturunkan ke kotak surat biasa.

| Angka | Usulan | Catatan |
|---|---|---|
| Skor dasar | 100 | `SKOR_SASARAN_DASAR` |
| Persen sasaran | penuh 100, halaman 50 | `SKOR_PERSEN_PENUH`, `SKOR_PERSEN_HALAMAN` |
| Combo | ×1,0 + 0,1 per antaran beruntun sebelumnya, maks ×2,0 | `SKOR_COMBO_AWAL`, `SKOR_COMBO_LANGKAH`, `SKOR_COMBO_MAKS` |
| Pengali kecepatan | ×1,0 / ×1,2 / ×1,5 | `SKOR_PENGALI_SANTAI`, `_CEPAT`, `_NGEBUT` |
| Tepat | ×1,25, inti 0,5 × 0,5 | `SKOR_TEPAT_PENGALI`, `JALAN_UJI_*_KOTAK_SURAT_INTI_UBIN`; seberapa sulit dinilai di HP |

---

## 6. Rute, tenggat, dan tabrakan

| Angka | Usulan | Catatan |
|---|---|---|
| Lebar petak rumah | 4 ubin | Rumah 3 ubin + celah 1 ubin. `RUTE_PETAK_UBIN` |
| Rute awal perumahan | 25 pelanggan di sisi seberang, panjang sekitar 250 ubin | Distrik pertama hanya satu sisi. Sela antar pelanggan diisi rumah bukan pelanggan, persimpangan, dan taman |
| Jarak rata-rata antar pelanggan | sekitar 9 ubin | Sekitar 2 detik pada kecepatan cepat, 3 detik pada santai |
| Lama rute | sekitar 55 detik (cepat) sampai 85 detik (santai) | |
| Tenggat | waktu tempuh rute pada kecepatan santai × 1,15, dibulatkan ke atas: `ceil(panjang / 3,0 × 1,15)` = 89 / 91 / 92 detik untuk rute 232 / 236 / 240 ubin | Santai terus masih sempat (cadangan sekitar 11 detik), tapi berhenti lama untuk misi butuh ngebut di bagian lain. Sesudah tenggat lewat hanya tip yang hilang (K-1 run fase3c-hud-hasil, bagian 6f) |
| Tabrakan | kecepatan turun ke 1,0 u/d, oleng 0,6 detik, combo putus, lalu kebal 1,0 detik | Tidak menghentikan rute (K-1 run fase3b-rintangan-skor, bagian 6c) |

Apakah ada game over atau batas tabrakan per hari masih terbuka (GDD 3.2, ROADMAP 5); run 3B tidak menguncinya (tanpa batas tabrakan per rute).

### 6b. Rute dari segmen (usulan run fase3a-rute 2026-10-16, dinilai lewat uji HP)

Keputusan pemilik K-1 sampai K-5 (SPEC run). Format segmen di `DATA_SCHEMA.md` 3; logika di `scripts/systems/` (`SegmenRute`, `PemuatRute`, `RouteBuilder`, `PenutupPemain`). Semua angka di bawah masuk `scripts/config.gd` (awalan `RUTE_`), kecuali yang tertulis "data".

| Angka | Usulan | Catatan |
|---|---|---|
| Segmen per distrik | 9 (data): 2 pembuka, 5 tengah, 2 penutup | `assets/data/routes/perumahan/per_*.json`; satu rute memakai semua 5 tengah, jadi variasi dari urutan dan pilihan pembuka, penutup, dan pelanggan |
| Segmen per rute | 7 | `RUTE_SEGMEN_PER_RUTE`: satu pembuka, 5 tengah berbeda, satu penutup, tanpa ulang. Pengapit (pembuka + penutup) = `RUTE_SEGMEN_PENGAPIT` 2; pustaka paling sedikit `RUTE_PEMBUKA_MIN` 2 pembuka dan `RUTE_PENUTUP_MIN` 2 penutup |
| Panjang segmen | 24 sampai 40 ubin | `RUTE_SEGMEN_PANJANG_MIN_UBIN`, `_MAKS_`. Data: 24, 28, 28, 32, 32, 36, 36, 36, 40 |
| Panjang rute | 232 sampai 240 ubin | Terukur dari data (jumlah 7 segmen); sekitar 250 di BALANCING awal. Garis akhir = panjang rute |
| Pelanggan per rute | tepat 25 | `RUTE_PELANGGAN`; semuanya rumah `seberang` dengan `pelanggan_boleh`. Data memuat 37 rumah boleh; satu rute punya 31 sampai 32 kandidat |
| Pilihan pelanggan | sebaran rata dengan goyangan | Target posisi disebar dari kandidat pertama ke terakhir dengan goyangan acak plus minus `RUTE_PELANGGAN_GOYANG_UBIN` (3,0), lalu pencocokan berurutan terbaik. Hasil terukur (1000 seed): jarak rata-rata 8,8 sampai 9,3 ubin (rata-rata 9,2), celah 4 sampai 20 ubin |
| Celah terpanjang antar pelanggan | 20 ubin | `RUTE_PELANGGAN_JARAK_MAKS_UBIN`; pilihan diundi ulang bila terlampaui (paling banyak `RUTE_SUSUN_PERCOBAAN_MAKS` 200 kali), lalu rute ditolak dengan galat |
| Koran awal | 30 | Pelanggan + 20% dibulatkan ke atas (bagian 4). Rute tidak memakai isi ulang jalan uji |
| Tepi segmen | 2 ubin kosong | `RUTE_TEPI_UBIN`; rintangan paling dekat 3 ubin ke tepi (`RUTE_RINTANGAN_TEPI_UBIN`) supaya sambungan tidak menumpuk keputusan |
| Jendela keputusan | maksimal satu rintangan dalam 6 ubin | `RUTE_RINTANGAN_JENDELA_UBIN`; berlaku di dalam segmen (data) dan di seluruh rute (`RouteBuilder.periksa_rute`) |
| Tanda rintangan | paling sedikit 9 ubin | `RUTE_TANDA_MIN_UBIN`: 1,5 detik pada ngebut 6,0 u/d (ROUTE_DESIGN 4 aturan 2); perilaku rintangan Run 3B |
| Urutan keramaian | tidak ada dua segmen `padat` berurutan | ROUTE_DESIGN 5; pembuka dan penutup selalu `tenang`. Data: 1 tenang, 2 sedang, 2 padat di tengah |
| Jendela daur rumah (scene rute) | 20 ubin di belakang, 30 di depan sepeda | `RUTE_DAUR_MUNDUR_UBIN`, `RUTE_DAUR_MAJU_UBIN`: rumah di luar jendela tidak diinstansiasi (sekitar 11 sampai 20 dari 89 rumah sekaligus). Bukan angka permainan; menyangkut performa dan lebar layar terlebar 800 px |
| Akhir rute | stick buatan ke bawah penuh (`RUTE_AKHIR_STICK_Y` −1,0) | Sesudah garis akhir sepeda direm dengan rem biasa (tahan 0,25 detik lalu 5,0 u/d²), jadi berhenti paling jauh sekitar 4,5 ubin dari garis (ngebut 6,0 u/d), 1,4 ubin dari santai. Stick sungguhan dan lemparan dikunci; tanpa tenggat, skor, atau layar hasil (3B dan 3C) |
| Penutup pemain | alfa 0,45 | `RUTE_PENUTUP_ALFA`; objek yang menutupi kaki pemain dari kamera iso 2:1 (`PenutupPemain`), 1,0 bila tidak menutupi. Tapak rumah 3 × 3 ubin dan tinggi 2,0 (`RUTE_RUMAH_*`, dari `tools/env_art/perumahan.py`). Rumah penguji elips dan titik redup: dua petak di belakang titik sampai satu petak di depan (`RUTE_PENUTUP_JENDELA_BELAKANG_PETAK` 2) |

Catatan: rumah di tepi jalan (lateral 3 ubin atau lebih) praktis tidak pernah menutupi pemain di lebar jalan resmi (aturan 3D `PenutupPemain`); aturan ini disiapkan untuk objek yang lebih dekat ke jalan (mobil, pohon, tenda) dan dinilai lewat uji HP.

### 6c. Rintangan perumahan dan tabrakan (usulan run fase3b-rintangan-skor 2026-10-16, dinilai lewat uji HP)

Logika murni di `scripts/systems/` (`AnjingPenjaga`, `MobilGarasi`, `RintanganRute`, `Tabrakan`); angka di `config.gd` (awalan `ANJING_`, `MOBIL_`, `TABRAKAN_`). Rintangan dibangun dari `objek` segmen (jenis, `pos`, `jalur`, `tanda_ubin`) tanpa field data baru. Posisi dalam koordinat jalan (lateral dari garis tengah, negatif = seberang; maju dari awal rute). Bentuk tabrakan = persegi di bidang tanah; tepi yang hanya bersentuhan bukan tabrakan.

- **Separuh jalan (K-1):** anjing dan mobil hanya memakai separuh jalan di sisi jalurnya; tepi bentuknya paling jauh tepat di garis tengah. Separuh lain selalu bebas (ROUTE_DESIGN 4 aturan 1), dites di 20 rute seed.
- **Anjing penjaga:** duduk di halaman (pusat lateral ±2,75, tepi 2,5 di luar jangkauan sepeda di tepi trotoar 2,25). **Waspada** (berdiri, menggeram) saat sepeda masuk `tanda_ubin` (data, paling sedikit 9) di belakang titik rumahnya. **Mengejar** (menggonggong, lari) saat sepeda sampai di titik rumahnya (`ANJING_KEJAR_JARAK_UBIN` 0 = sepeda melewati anjing): maju menuju maju sepeda tanpa mendahuluinya dengan laju kecepatan sepeda × 1,25, dijepit 2,0 sampai 4,5 u/d, dan menyamping ke arah sepeda 2,0 u/d di separuh jalannya. **Berhenti** di batas halaman (3,0 ubin maju dari titik rumah) atau sesudah menabrak, diam 0,8 detik, lalu **pulang** 2,0 u/d dan duduk lagi; sesudah itu tidak waspada lagi untuk lintasan itu. Berbahaya hanya saat mengejar dan berhenti.
- **Harga kecepatan (prinsip 1):** tanda ke anjing mengejar = 9 ubin / kecepatan = 3,0 detik di santai, 1,5 detik di ngebut. Anjing (3,75 u/d) menyusul pemain santai (3,0) di separuh jalannya; pemain ngebut (6,0) di tengah separuh itu (lateral ±1,0) lolos karena anjing butuh sekitar 0,6 detik menyamping, saat itu sepeda sudah sekitar 0,9 ubin di depan (jarak sentuh 0,65). Di tepi trotoar sisi anjing, ngebut pun bisa tertabrak.
- **Mobil keluar garasi (D-1, pola sederhana):** parkir dengan bagasi 2,5 ubin dari garis tengah. **Tanda** (lampu mundur berkedip + bip) saat sepeda masuk `tanda_ubin`; tanda menyala **1,5 detik** (waktu, sama di semua kecepatan), lalu **mundur** 1,0 u/d sampai bagasi di garis tengah, lalu **berhenti** di sana menutup separuh jalan sisinya sampai rute disusun ulang. Mobil 1,5 ubin melintang × 0,75 ubin sepanjang jalan. Selalu padat; tidak bereaksi pada bel.
- **Tanda sebelum bahaya (ROUTE_DESIGN 4 aturan 2):** selang dari tanda pertama sampai bentuk rintangan pertama kali beririsan dengan jalur sepeda (pita lateral bentuk sepeda) ≥ 1,5 detik di santai, cepat, dan ngebut untuk semua posisi lateral −2,0 sampai 2,0, dan di posisi yang kena di dua kecepatan, yang lebih pelan tidak lebih pendek (dites 204 kasus). Terpendek di tepi trotoar sisi rintangan pada ngebut: anjing sekitar 1,63 detik, mobil 1,75 detik (contoh literal dengan langkah 1/8 detik: anjing tanda di 1,875 detik dan menyentuh di 3,5 detik).
- **Tabrakan (K-1):** sepeda 0,5 × 0,8 ubin (`TABRAKAN_SEPEDA_SETENGAH_*`). Saat tabrakan kecepatan langsung turun ke 1,0 u/d bila lebih tinggi, **oleng** 0,6 detik (kecepatan tidak bisa naik; lateral, melambat, rem, dan lemparan tetap bisa; `BikeMotion.langkah(..., tahan_naik)`), combo putus, dan **kebal** 1,0 detik dihitung dari saat tabrakan (tidak ada tabrakan kedua dari rintangan mana pun). Stamina tidak dihukum. **Tanpa tabrakan ganda:** rintangan yang bersentuhan saat tabrakan atau selama kebal tidak memicu tabrakan lagi sampai sepeda terpisah darinya (sepeda yang terus melewati mobil yang ditabraknya tidak tertabrak berulang). Anjing penyebab berhenti mengejar. Tanpa batas tabrakan per rute dan tanpa game over (ROADMAP 5 tetap terbuka).
- **Urutan per langkah** (`RintanganRute.langkah`, dipakai scene dan simulasi tes): sepeda bergerak (oleng menahan naik), rintangan melangkah dengan posisi dan kecepatan sepeda baru, lalu tabrakan diperiksa. Jeda (dt 0) membekukan semuanya.
- **Dites (invarian prinsip):** 20 rute seed: pemain santai di sisi bebas tanpa tabrakan, dan di setiap posisi maju ada posisi lateral yang tidak pernah dimasuki rintangan. Pemain santai yang sengaja menabrak setiap rintangan (11 per rute) tetap sampai garis akhir, kecepatan kembali ke santai dalam 3 detik sesudah tiap tabrakan, `rute_selesai` tepat sekali.

| Angka | Usulan | Catatan |
|---|---|---|
| Bentuk sepeda | 0,5 lateral × 0,8 maju | `TABRAKAN_SEPEDA_SETENGAH_LATERAL_UBIN` 0,25, `_MAJU_UBIN` 0,4 |
| Anjing: bentuk, halaman | 0,5 × 0,5; pusat ±2,75 | `ANJING_SETENGAH_UBIN`, `ANJING_RUMAH_LATERAL_UBIN` |
| Anjing: mulai mengejar | sepeda di titik rumah (0 ubin di belakang) | `ANJING_KEJAR_JARAK_UBIN` |
| Anjing: laju | sepeda × 1,25, dijepit 2,0..4,5 u/d; menyamping 2,0 u/d | `ANJING_KEJAR_PENGALI`, `ANJING_LAJU_MIN_UD`, `ANJING_LAJU_MAKS_UD`, `ANJING_LATERAL_UD` |
| Anjing: batas halaman | 3,0 ubin maju | `ANJING_BATAS_MAJU_UBIN` |
| Anjing: berhenti, pulang | 0,8 detik; 2,0 u/d | `ANJING_BERHENTI_DETIK`, `ANJING_PULANG_UD` |
| Mobil: ukuran | 1,5 melintang × 0,75 sepanjang jalan | `MOBIL_PANJANG_UBIN`, `MOBIL_SETENGAH_LEBAR_UBIN` 0,375 |
| Mobil: bagasi | 2,5 ubin saat parkir, berhenti di 0 (garis tengah) | `MOBIL_BELAKANG_AWAL_UBIN`, `MOBIL_BELAKANG_AKHIR_UBIN` |
| Mobil: tanda, mundur | 1,5 detik; 1,0 u/d | `MOBIL_TANDA_DETIK`, `MOBIL_MUNDUR_UD` |
| Tabrakan | 1,0 u/d, oleng 0,6, kebal 1,0 detik | `TABRAKAN_KECEPATAN_UD`, `TABRAKAN_OLENG_DETIK`, `TABRAKAN_KEBAL_DETIK`; `TABRAKAN_TOLERANSI_DETIK` 0,000001 hanya derau float |

### 6d. Bel "Kring Kring!" (usulan run fase3b-rintangan-skor 2026-10-16, dinilai lewat uji HP)

Logika di `scripts/systems/bel.gd` (`Bel`), reaksi lewat `RintanganRute.terapkan_bel`; GDD 5.4, K-3. Ketukan pertama = "kring", teks "KRING!" tampil 0,5 detik; ketukan kedua selama teks tampil = "kring kring!", lalu bel jeda 1,0 detik (ketukan ditolak tanpa bunyi, sisa jeda dibaca sebagai cincin). "Kring" tunggal yang teksnya sudah habis tidak memulai jeda. Bel ditolak saat jeda game; teks dan jeda bel membeku selama jeda. Jangkauan: rintangan dari 1,0 ubin di belakang sampai 4,0 ubin di depan sepeda, seluruh lebar jalan. Reaksi per jenis dari SATU tabel (`Bel.REAKSI_JENIS`): anjing penjaga yang waspada atau mengejar kaget 0,5 detik (ikon "!") lalu mundur ke halamannya 3,0 u/d dan tidak mengejar lagi untuk lintasan itu; anjing yang duduk tidak bereaksi; mobil tidak pernah bereaksi.

| Angka | Usulan | Catatan |
|---|---|---|
| Teks bel | 0,5 detik | `BEL_TEKS_DETIK`; jendela ketukan kedua |
| Jeda bel | 1,0 detik sesudah "kring kring!" | `BEL_JEDA_DETIK` |
| Jangkauan | 4,0 ubin di depan, 1,0 di belakang | `BEL_JANGKAUAN_UBIN`, `BEL_JANGKAUAN_BELAKANG_UBIN` (D-5: anjing yang mengejar berlari di samping atau sedikit di belakang sepeda) |
| Anjing kaget, mundur | 0,5 detik; 3,0 u/d | `ANJING_KAGET_DETIK`, `ANJING_MUNDUR_UD` |

### 6e. Scene rute run 3B: tampilan rintangan, tabrakan, bel, HUD skor (usulan run fase3b-rintangan-skor bagian B 2026-10-16, dinilai lewat uji HP)

Angka tampilan dan input bagian B di `config.gd` (tidak mengubah aturan main di 5b, 6c, 6d). Tata letaknya di `DESIGN_SPEC.md` 3.6 dan 3.8.

| Angka | Usulan | Catatan |
|---|---|---|
| Tinggi kotak penutup rintangan | anjing 0,8 ubin, mobil 1,0 ubin | `RINTANGAN_ANJING_TINGGI_UBIN`, `RINTANGAN_MOBIL_TINGGI_UBIN`; aturan penutup `PenutupPemain` yang sama dengan rumah |
| Ikon "!" anjing | 28 px game di atas titik pijak | `RINTANGAN_SERU_ATAS_PX` (kepala sekitar 26 px + 2) |
| Oleng (visual) | sprite bergeser ±1 px tiap 0,05 detik | `TABRAKAN_OLENG_GESER_PX`, `TABRAKAN_OLENG_PERIODE_DETIK`; geser kecil supaya tidak berlebihan (rule `ui-scenes`) |
| Kedip kebal | alpha 0,5 tiap fase 0,1 detik | `TABRAKAN_KEDIP_PERIODE_DETIK`, `TABRAKAN_KEDIP_ALFA` |
| Ikon kilatan tabrakan | 50 px game di atas titik pijak | `TABRAKAN_IKON_ATAS_PX` |
| Tombol bel | 40×40, pusat 28 dari tepi samping dan bawah, zona tap radius 28 inklusif | `BEL_TOMBOL_UKURAN_PX`, `BEL_TOMBOL_PUSAT_TEPI_PX`, `BEL_ZONA_RADIUS_PX`; 8 frame cincin jeda `BEL_TOMBOL_JEDA_LANGKAH` |
| Efek bel | 12 fps, garis getar 4 frame (jangkar (3, 12)), titik bel (8, −29) dari titik pijak pemain, teks (11, −12) dari titik bel, naik paling banyak 4 px, redup 0,6 | `BEL_EFEK_FPS`, `BEL_GETAR_FRAME`, `BEL_GETAR_JANGKAR_PX`, `BEL_TITIK_PX`, `BEL_TEKS_GESER_PX`, `BEL_TEKS_NAIK_MAKS_PX`, `BEL_TEKS_REDUP_ALFA` |
| Panel skor HUD dev | 112 px dari tepi sisi swipe, lebar minimum 72 | `HUD_SKOR_GESER_PX`, `HUD_SKOR_LEBAR_PX` |
| Label PUTUS | 0,8 detik sesudah combo putus | `HUD_COMBO_PUTUS_DETIK` |
| Umpan balik melayang | 0,8 detik, naik 12 px, paling banyak 2, kaki 18 px di atas titik mendarat | `UMPAN_MELAYANG_DETIK`, `UMPAN_MELAYANG_NAIK_PX`, `UMPAN_MELAYANG_MAKS`, `UMPAN_MELAYANG_ATAS_PX` (DESIGN_SPEC 3.6) |
| Garis luar teks dunia | 2 px game | `HUD_TEKS_GARIS_PX` (teks KRING dan umpan balik melayang) |

### 6f. Tenggat, radar, HUD rute, dan layar hasil (usulan run fase3c-hud-hasil 2026-10-17, dinilai lewat uji HP)

Keputusan pemilik K-1 (tenggat, tip hilang sesudahnya) dan K-2 (radar 30 ubin), usulan orchestrator O-6 sampai O-12 (SPEC run). Logika murni di `scripts/systems/` (`TenggatRute`, `RadarRute`, `ProgresRute`, `HasilRute`, `ZonaAman`); tata letak di `docs/design/DESIGN_SPEC.md` 3 dan 4.

- **Tenggat (K-1):** `TenggatRute.detik_tenggat` = `ceil(panjang_ubin / KECEPATAN_SANTAI_UD × TENGGAT_PENGALI - TENGGAT_TOLERANSI_DETIK)`, dari rute, satu tempat. Jam maju dengan dt efektif (beku saat jeda dan background), berhenti di garis akhir. **Lewat** = waktu lebih dari tenggat; tepat di tenggat (sisa 0) belum lewat. Tampilan dibulatkan ke atas ke detik bulat: "WAKTU 1:32" sebelum lewat, "LEWAT +0:12" sesudahnya.
- **Tip sesudah tenggat (K-1):** antaran sah ke pemberi tip sesudah tenggat lewat tetap memberi ongkos 15 koin, skor, dan combo seperti biasa; tip 0, `jumlah_tip` tidak naik, tidak ada denting tip dan umpan "tip +5" (`SkorRute.nilai(..., tenggat_lewat)`). Status tenggat dibaca saat koran mendarat. Tanpa potong koin dan tanpa game over (prinsip 2); game over dan batas tabrakan tetap terbuka (ROADMAP 5).
- **Radar (K-2, O-9, O-10):** penanda rumah dengan 0 ≤ jarak ≤ 30 ubin (kedua tepi inklusif), jarak = jarak maju dari sepeda ke pusat zona kotak surat. Posisi vertikal = 1 - jarak / 30 (atas jauh, bawah di samping sepeda). Pemberi tip tampil `tip` sampai tenggat lewat, lalu pelanggan biasa. Rumah terantar keluar dari radar. Rumah bukan pelanggan hanya tampil di mode bantu (abu-abu berlubang). "Masuk jangkauan lempar" = rumah pelanggan dengan 0 ≤ jarak ≤ 5,0 ubin (jarak lemparan terjauh).
- **Kotak progres (O-12):** terkirim (✓), terlewat (×; kotak surat lebih dari 3,0 ubin di belakang sepeda tanpa terantar, atau rute selesai), berikutnya (▶; pelanggan belum terantar terdekat di depan, jarak ≥ 0), belum (kosong).
- **Layar hasil (O-11, O-12):** terbuka sesudah garis akhir saat sepeda berhenti dan tidak ada koran terbang. Terkirim = pelanggan rute yang terantar, meleset = 25 - terkirim, koin/tip/skor/tepat dari `SkorRute`, tenggat lewat dan detiknya dari `TenggatRute`.

| Angka | Usulan | Catatan |
|---|---|---|
| Pengali tenggat | ×1,15 waktu tempuh santai | `TENGGAT_PENGALI`; `TENGGAT_TOLERANSI_DETIK` 0,000001 hanya derau float; `WAKTU_DETIK_PER_MENIT` 60 |
| Jangkauan radar | 30 ubin ke depan (sekitar 5 detik ngebut, 10 detik santai) | `RADAR_JANGKAUAN_UBIN` (K-2); kelak bisa upgrade (GDD 4.3) |
| Strip radar | x 4 dari tepi, lebar 12, y 10 sampai 182, bingkai 9-slice 2; penanda 8×6, jangkau 10×8 | `RADAR_TEPI_PX`, `RADAR_LEBAR_PX`, `RADAR_Y_ATAS_PX`, `RADAR_Y_BAWAH_PX`, `RADAR_BINGKAI_PX`, `RADAR_PENANDA_*`, `RADAR_JANGKAU_TAMBAH_PX` (DESIGN_SPEC 3.4) |
| Kotak progres | 25 kotak 8×8 jarak 2 di panel 260 (isi samping 6, bukan 7, supaya 248 px muat); terlewat sesudah 3,0 ubin | `HUD_PROGRES_*` (DESIGN_SPEC 3.2) |
| Panel kanan atas | koin dan skor, tepi kanan 28 dari tepi layar, jarak antar panel 5, ikon 14, panel 9-slice 4 | `HUD_KANAN_MARGIN_PX`, `HUD_PANEL_JARAK_PX`, `HUD_IKON_PX`, `HUD_PANEL_9SLICE_PX`; pemisah ribuan tiap `ANGKA_KELOMPOK_RIBUAN` 3 angka |
| Zona aman | margin tepi = max(margin DESIGN_SPEC, inset aman); inset layar dibulatkan ke atas ke piksel game | `ZONA_AMAN_TOLERANSI_PX` 0,000001 hanya derau float |
| Layar hasil | panel lebar minimum 300, jarak baris 2; terbuka saat kecepatan ≤ 0,000001 u/d | `HASIL_PANEL_LEBAR_PX`, `HASIL_JARAK_BARIS_PX`, `HASIL_BERHENTI_TOLERANSI_UD` |

Dites (invarian prinsip): bot santai tanpa berhenti di sisi bebas sampai garis akhir sebelum tenggat tanpa tabrakan di 20 seed (cadangan paling sedikit 10 detik); bot yang berhenti 100 detik melewati tenggat tetapi tetap sampai garis akhir tepat sekali; koin tidak pernah berkurang, juga sesudah tenggat.

---

## 7. Ekonomi

Patokan dari GDD 14.1 (diputuskan sebagai acuan). Angka bengkel di bawah adalah usulan.

| Angka | Nilai |
|---|---|
| 1 koin | Rp100 |
| Ongkos satu pengantaran | 15 koin (rentang 6–20 tergantung jenis koran) |
| Pemasukan satu hari rapi (25 rumah) | 300–375 koin |
| Tip pelanggan pemberi tip (koran di teras) | 5 koin (usulan, `KOIN_TIP`) |
| Hadiah misi kecil / sedang / besar | 45 / 75 / 120 koin |
| Tambal ban | 100–150 koin (sekitar 1–2 jam kerja loper, usulan) |
| Servis rem | 80 koin (usulan) |
| Sambung / ganti rantai | 150 koin (usulan) |
| Upgrade komponen tingkat 1 | 500–800 koin, sekitar 2 hari kerja (usulan) |

Gagal misi tidak pernah mengurangi koin (GDD 10.5).

**Koin di rute (usulan run fase3b-rintangan-skor 2026-10-16, K-2, O-1 sampai O-3; `SkorRute`):** antaran sah **pertama** tiap pelanggan +15 koin ongkos (`KOIN_ONGKOS_ANTAR`), juga antaran halaman (sah setengah untuk skor, ongkos penuh, O-2) dan jendela dengan sakelar bonus. Koran ke teras pelanggan pemberi tip +5 koin tip (`KOIN_TIP`); tip hanya dari teras. Meleset, bukan pelanggan, jendela penalti, dan koran ke rumah yang sudah terantar 0 koin. Koin tidak pernah berkurang (prinsip 2). Tepat tidak menambah koin. **Pemberi tip** = 30% pelanggan rute dibulatkan ke bawah (`RUTE_PEMBERI_TIP_PERSEN`: 25 pelanggan = 7), dipilih `RouteBuilder` dengan RNG rute yang sama sesudah pelanggan (seed sama = sama), tanpa penanda visual di 3B (GDD 8). Rute 25 pelanggan terantar semua = 375 koin ongkos + tip (semua ke teras: 375 + 7 × 5 = 410), dites dengan simulasi; patokan hari rapi 300 sampai 375 koin (GDD 14.1) tetap untuk ongkos.

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

- **2026-10-17** — Run fase3c-hud-hasil iterasi 1a (keputusan pemilik K-1 dan K-2, usulan orchestrator O-6 sampai O-12; semua angka usulan, belum diuji di HP): tenggat dihitung dari rute `ceil(panjang / 3,0 × 1,15)` (89 sampai 92 detik; dulu tertulis "sekitar 95 detik" dari panjang 250 lama) dan tip hilang sesudah tenggat lewat (ongkos, skor, combo tetap); radar 30 ubin dengan jangkau = jarak lempar terjauh 5,0; kotak progres terlewat sesudah 3,0 ubin; angka tampilan HUD rute final dan layar hasil (bagian 6f). Angka gerak, lemparan, skor, ekonomi, rintangan, dan bel tidak berubah. Alasan: kontrak SPEC run 3C (AC-1 sampai AC-13, AC-16).

- **2026-10-16** — Run fase3b-rintangan-skor bagian B (scene; usulan, belum diuji di HP): angka tampilan dan input baru di bagian 6e (tinggi penutup rintangan, ikon "!", oleng ±1 px, kedip kebal, ikon kilatan, tombol dan zona bel, efek bel, panel skor HUD dev, label PUTUS, umpan balik melayang). Aturan main bagian 5b, 6c, 6d, 7 tidak berubah. Alasan: AC-8, AC-13, AC-15, AC-16, DESIGN_SPEC 3.6 dan 3.8; nilai dinilai lewat uji HP (`SETUP_ANDROID.md` 8.7). Anjing yang kaget karena bel kini memakai animasi `berhenti` (bukan `lari`) selama ikon "!" tampil, supaya terbaca kaget.

- **2026-10-16** — Run fase3b-rintangan-skor bagian A, bunyi (usulan, belum diuji di HP): nada combo (5 tingkat setengah nada), bel kedua +1 setengah nada, volume bel −2, rintangan −3, tabrakan −2, tip/tepat −3 dB (bagian 2). Alasan: SOUND_DESIGN 3.1 dan 3.3 (AC-18, AC-19).
- **2026-10-16** — Run fase3b-rintangan-skor bagian A (logika murni; keputusan pemilik K-1 sampai K-4 dan usulan orchestrator O-1 sampai O-5; semua angka usulan, belum diuji di HP): rintangan anjing penjaga dan mobil keluar garasi, tabrakan, bel (bagian 6c dan 6d), skor, combo, pengali kecepatan, tepat, rumah terantar (bagian 5b), koin dan tip (bagian 7). Angka BALANCING 5-7 yang sudah ada dipakai apa adanya (combo +0,1 maks ×2,0; pengali 1,0 / 1,2 / 1,5; ongkos 15; tip 5; tabrakan 1,0 u/d dan oleng 0,6). Angka baru: kebal 1,0 detik, tepat ×1,25 dengan inti 0,5 × 0,5, skor dasar 100 dan halaman 50%, pemberi tip 30%, semua angka rintangan (bagian 6c), bel (teks 0,5, jeda 1,0, jangkauan 4,0 depan dan 1,0 belakang). Alasan: kontrak SPEC run 3B (AC-1 sampai AC-14); angka rintangan dipilih supaya invarian prinsip desain lolos (tanda ≥ 1,5 detik pada ngebut, separuh jalan selalu bebas, santai tersusul anjing, ngebut lolos).

- **2026-10-16** — Sepeda boleh naik trotoar dan kotak surat pindah ke halaman (permintaan pemilik, usulan, belum diuji di HP): batas tepi jalan resmi ±1,0 → ±2,0 ubin (bagian 2), kotak surat seberang `[−2,125; 0,375; 1,0 × 1,5]` → `[−2,75; 1,25; 1,0 × 1,25]` dan dekat `[1,125; 0,375; 1,0 × 1,5]` → `[1,75; 1,25; 0,75 × 1,25]` (bagian 5), sprite kotak surat dari (−1,5; +1,0) ke (−2,125; +1,75). Angka lain tidak berubah.
- **2026-10-16** — Run fase3a-rute bagian B (scene rute; semua usulan, belum diuji di HP): scene utama `scenes/rute/rute.tscn` menggambar rumah dan kotak surat dari data lewat jendela daur (angka baru `RUTE_DAUR_MUNDUR_UBIN` 20 dan `RUTE_DAUR_MAJU_UBIN` 30), akhir rute dengan rem biasa (`RUTE_AKHIR_STICK_Y` −1,0) dan tombol dev "Main lagi" (seed + 1), dan penerap penutup tunggal (alfa 0,45 tidak berubah). Titik pijak sprite rumah disimpan di `RUTE_RUMAH_SPRITE` dan `RUTE_RUMAH_PIJAK_PX` (fakta aset, dicek tes terhadap JSON). Penilaian koran dan mode bantu memakai zona rute lewat `MedanKoran`; angka lintasan, zona, jeda, dan skor tidak berubah. Alasan: kontrak SPEC run 3A (AC-10 sampai AC-16).

- **2026-10-16** — Run fase3a-rute bagian A (logika murni; semua usulan, belum diuji di HP): rute perumahan dari segmen JSON (bagian 6b). Angka baru di `config.gd` (awalan `RUTE_`): 25 pelanggan, 7 segmen per rute, seed dev 20261016, koran cadangan 20%, panjang segmen 24 sampai 40, tepi 2 ubin, petak 4 ubin, jendela rintangan 6 ubin (tepi rintangan 3), tanda paling sedikit 9 ubin, celah pelanggan maks 20 ubin, goyangan target 3,0 ubin, percobaan 200, tapak rumah 3 × 3 × 2,0 ubin, alfa penutup 0,45. Angka lintasan, zona, dan skor tidak berubah (geometri zona rute sama dengan zona jalan uji). Alasan: kontrak SPEC run 3A (K-1 sampai K-5); jarak rata-rata terukur 9,2 ubin dari 1000 seed.

- **2026-10-15** — Run fase2b-bantu-audio bagian B (usulan, belum diuji di HP): bunyi lempar dan mendarat placeholder (bagian 2). Angka baru: volume "wus" −4 dB dan bunyi mendarat −1 dB. Alasan: SOUND_DESIGN 3.1 dan 6 (mendarat terdengar di atas kayuhan, meleset lebih pelan), dinilai di speaker HP.

- **2026-10-15** — Run fase2b-bantu-audio bagian A (keputusan pemilik K-1 sampai K-4, rinciannya usulan, belum diuji di HP): mode bantu (bagian 4b): tap di zona swipe melempar otomatis ke kotak surat pelanggan terdekat di depan pada sisi tap, lintasan dari `ThrowSolver.hitung`, selalu kena; tanpa sasaran tidak melempar dan memberi tanda. Angka lintasan, jeda 0,35, dan jeda lepas tidak berubah. Angka baru: lama tanda 0,6 detik, toleransi pencarian u, jumlah langkah bisection, jarak tombol strip atas 8 px. Alasan: mode bantu wajib ada dan sepenuhnya bisa dimainkan (GDD 5.3, rule `ui-scenes`).

- **2026-10-15** — Run fase2-arah-bebas (keputusan pemilik "arah bebas", GDD 5.2; rinciannya usulan, belum diuji di HP): arah lemparan mengikuti arah swipe di layar lewat `Iso` (bagian 4), panjang swipe = \|v\| penuh, tidak ada sudut yang ditolak, sisi animasi dari komponen melintang arah tanah (x = 0 = dekat), jari yang berbelok saat diangkat tidak membatalkan (batal hanya bila \|v_lepas\| di bawah 6%), dan zona menilai dari titik mendarat saja (bagian 5). Angka tidak berubah dan tidak ada angka `Config` baru; "jarak ke samping" kini "jarak tanah" searah swipe. Alasan: uji HP pemilik Run 2A di vivo V2108 ("suka gagal, terutama ke arah kiri"): swipe 45°–135° ditolak, padahal kotak surat seberang di depan sepeda ada di rentang itu (SPEC run, Latar belakang).

- **2026-10-14** — Run fase2a-lemparan iterasi 2 (perbaikan temuan QA; usulan, belum diuji di HP): lemparan memakai lintasan garis bidik yang terakhir tampil, bukan posisi lepas jari (QA-001, bagian 4). Bayangan koran 8 → 4 px alpha 0,5 menjadi 10 → 6 px alpha 0,85 (QA-007, bagian 4; keterbacaan di HP tetap diuji pemilik). Elips dan titik garis bidik yang tertutup rumah dari sudut kamera digambar putus-putus/redup (QA-004, angka tampilan `GARIS_BIDIK_TERTUTUP_ALPHA` 0,5 dan ukuran kotak rumah graybox di bagian 4). Kalimat lama bagian 2 "swipe diabaikan selama animasi lempar" diselaraskan dengan D-9 (QA-002). Angka lintasan tidak berubah. Alasan: AC-4 prediksi = hasil juga untuk flick; dokumen tidak boleh berbeda aturan.
- **2026-10-14** — Run fase2a-lemparan bagian 1b (scene; usulan, belum diuji di HP): lemparan tersambung ke jalan uji (garis bidik di ruang dunia, koran terbang dengan bayangan, penanda kena/meleset, zona placeholder tampil, HUD sisa koran, jeda game membekukan koran). Angka lintasan BALANCING 4-5 tidak berubah; angka tampilan baru di bagian 4 (putaran koran, bayangan, penanda, sampel garis bidik, panel koran). `LoperSprite` tidak lagi menolak lempar selama animasi (D-9). Alasan: kontrak SPEC run 2A.

- **2026-10-14** — Run fase2a-lemparan (bagian 1a, logika murni; semua usulan, belum diuji di HP): `ThrowSolver` (bagian 4) dengan angka BALANCING 4 yang sudah ada (swipe 6–35%, jarak 1,5–5,0, terbang 0,45–0,75, puncak 1,0–1,6, warisan maju 100%, jeda 0,35, koran 30) masuk `config.gd`. Ambang swipe 12 px panjang total (run sprite-lempar-melambat) **diganti** \|dx\| ≥ 6% lebar viewport game (38,4 / 46,8 / 48 px; D-2 SPEC). Angka baru: tinggi tangan 0,7 ubin, toleransi swipe 0,001 px, penanda 0,8 detik (DESIGN_SPEC 3.6), isi ulang jalan uji 16 ubin (alat uji). Zona sasaran placeholder dan sakelar jendela bawaan penalti ringan (bagian 5, keputusan pemilik 2026-10-14, masih terbuka); rumah graybox seberang mundur ke lateral −3,0 untuk memberi halaman. Alasan: kontrak SPEC run 2A; dinilai pemilik di HP sesudah run.

- **2026-10-14** — Run fase1b-umpan-balik (paket usulan pemilik, belum diuji di HP): jeda tanpa lanjut otomatis (tombol jeda, layar jeda, back Android); tinggi tombol strip atas dan "Lanjut" 36 → 42 px game (≥ 44 dp di A54), tombol jeda baru dengan area sentuh 42×42; sepeda turun dari 60% ke 75% tinggi layar (`KAMERA_SEPEDA_Y_PECAHAN` 0,75, tidak menabrak panel kecepatan di 640/780/800 kanan dan kidal); dorongan maju 28 → 36 px (mundur 20 dan respon 0,35 tetap); teks HUD terkecil (`HudLabel`) 6 → 8 px di `assets/ui/theme.tres` (DESIGN_SPEC 1.2). Radius stick tetap 35. Angka baru umpan balik kecepatan (debu roda, debu rem, garis kecepatan, kurangi efek, batas partikel) dan bunyi sepeda (pitch kayuhan 1,0 / 1,15 / 1,3 dari SOUND_DESIGN 3.2, volume tiga bunyi) di bagian 2. Alasan: paket usulan pemilik dari pengamatan A54, belum diuji di HP.

- **2026-10-13** — Run fase1a-gerak: `BikeMotion` menggantikan `BikeDrive` (bagian 2): rem tanpa tombol sampai berhenti, meluncur, stamina dengan laju linear per potong dan lelah (bagian 3), lateral analog dengan batas tepi jalan resmi ±1 ubin, jeda, pose meluncur/rem dari fisika, dan laju kayuh dari kecepatan. Angka lama BALANCING 2-3 tidak berubah (uji HP Fase 0 lolos tanpa permintaan ubah); angka baru: toleransi rem, toleransi pose 0,05 u/d, `PEDAL_RATE_MAKS` 1,5, bar stamina merah di bawah 30. Semua usulan sampai uji HP Run 1A.
- **2026-10-07** — Angka awal ditulis sebagai usulan untuk Fase 0–3. Belum ada yang diuji.
