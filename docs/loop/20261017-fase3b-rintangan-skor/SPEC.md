# SPEC — 20261017-fase3b-rintangan-skor

Run 3B Fase 3 (M2, prototype 3): rintangan, tabrakan, skor dan koin, bel. Branch `feat/fase3b-rintangan-skor`, dari `main` `4a3be86` (sudah memuat PR #28 run 3A, #29 kotak surat oranye, #30 trotoar dan kotak surat di halaman, #31 bel dimajukan ke Fase 3).

## Tujuan

Rute perumahan dari run 3A menjadi **bisa dimainkan dengan risiko dan hadiah**: dua rintangan perumahan berperilaku dengan pola yang bisa dipelajari (anjing penjaga, mobil keluar garasi), tabrakan yang menghambat tanpa menghentikan rute, skor (nilai sasaran × combo × pengali kecepatan) dan koin (ongkos antar + tip) yang dihitung terpisah, bonus presisi "tepat", bunyi combo, tip, rintangan, tabrakan, dan bel "Kring Kring!" yang membuat anjing mundur. Radar, HUD rute final, tenggat, layar hasil tetap di Run 3C.

## Keputusan dari pemilik (2026-10-16, jawaban atas pertanyaan orchestrator)

- **K-1 Tabrakan = BALANCING 6 apa adanya.** Kecepatan turun ke 1,0 u/d, oleng 0,6 detik, combo putus, lalu kebal sekitar 1 detik (tidak kena dua kali beruntun). Tanpa batas tabrakan per rute dan tanpa game over (game over tetap keputusan terbuka ROADMAP 5, M2; 3B tidak menguncinya). **Anjing dan mobil hanya memakai separuh jalan di sisinya** (jalur `seberang`: lateral dari tepi trotoar −2,0 sampai garis tengah 0; jalur `dekat`: 0 sampai +2,0), jadi separuh lain selalu bebas (ROUTE_DESIGN 4 aturan 1).
- **K-2 Skor dan koin sekarang.** Skor dan koin **dua besaran terpisah** (skor tidak dikonversi ke koin dan sebaliknya; usulan BALANCING 5 dipertahankan). Skor = nilai sasaran × pengali combo × pengali kecepatan saat melempar (× bonus tepat bila ada). Koin = ongkos antar 15 koin per antaran sah (BALANCING 7, GDD 14.1) + tip 5 koin dari pelanggan pemberi tip yang korannya mendarat di teras. Keduanya dihitung di 3B dan tampil di HUD dev sementara (HUD rute final di 3C).
- **K-3 Bel membuat anjing mundur (menyimpang dari GDD 5.4 dengan persetujuan pemilik).** Anjing yang sedang **waspada atau mengejar** dan berada di jangkauan bel (sekitar 4 ubin di depan sepeda, GDD 5.4) menampilkan ikon "!" lalu mundur ke halamannya. Mobil keluar garasi **tidak** terpengaruh. GDD 5.4 dan 9.3 diperbarui (anjing kini termasuk yang bereaksi pada bel; kendaraan tetap tidak).
- **K-4 Bonus presisi "tepat" aktif sekarang.** Antaran yang mendarat di **inti** 0,5 × 0,5 ubin di pusat area kotak surat (zona lama sebelum PR #30) = antaran "tepat": skor × `SKOR_TEPAT_PENGALI` (usulan 1,25) dan penanda berbeda dari centang biasa (bentuk, bukan hanya warna). Koin sama dengan antaran kotak surat biasa. Angka usulan, dinilai di HP.
- **Tidak diubah (dicatat agar tidak diputuskan diam-diam):** jendela tetap sakelar `Config.JENDELA_KENA_BONUS` dengan bawaan penalti ringan (ROADMAP 5, tetap terbuka). Sesudah garis akhir swipe dan tap bantu tetap ditolak (QA-004/D-17 run 3A) sampai 3C. Id rumah `<id_segmen>@<pos>`, tanpa save. Sisi dekat hanya placeholder `bukan`.
- **Uji HP 3A (SETUP_ANDROID 8.6) dan Fase 2 (8.5): belum dilakukan pemilik** (baris `HASIL UJI HP` kosong). Run jalan tanpa hasilnya; `DEV_PHASES` Fase 2, M1, dan butir 3A yang bergantung uji HP tidak dicentang.
- Sudah dikunci (ROADMAP 4b, tidak ditanyakan lagi): Godot 4.7.2, skala ×3, 640×360 `canvas_items` + integer + expand, ubin 64×32, arah lempar bebas, package `com.rmh.kring`. Bel di Fase 3 (pemilik 2026-10-16).

## Keputusan orchestrator (usulan, bisa ditolak di review PR)

- **O-1 Satu antaran per pelanggan.** Antaran sah pertama ke rumah pelanggan mengubah status rumah itu menjadi `TERANTAR` (memberi skor, koin, tip, dan menaikkan combo). Koran berikutnya yang mendarat di zona rumah yang sudah terantar: 0 skor, 0 koin, **tidak memutus combo** dan tidak menaikkan combo, penanda netral (bentuk tersendiri). Alasan: tanpa ini koin bisa digandakan dengan melempar berkali-kali ke satu rumah. Antaran halaman (sah setengah) juga mengunci rumah (tidak bisa "diperbaiki" dengan lemparan kedua).
- **O-2 Halaman = koin penuh, skor setengah.** Antaran halaman sah (BALANCING 5: skor 50%), jadi ongkos antar tetap 15 koin; tip hanya dari teras. Jendela dengan sakelar penalti = meleset (0 skor, 0 koin, combo putus); dengan sakelar bonus = sah penuh + bintang.
- **O-3 Pemberi tip ditentukan berseed oleh `RouteBuilder`.** Sebagian pelanggan rute ditandai pemberi tip (`Config.RUTE_PEMBERI_TIP_PERSEN`, usulan 30) lewat RNG rute yang sama (seed sama = pemberi tip sama). Pemberi tip tidak ditandai visual di 3B (pelanggan "punya kebiasaan", GDD 8); dinilai di uji HP apakah perlu penanda.
- **O-4 Mode bantu tidak mendapat bonus tepat.** `BantuLempar.pilih` selalu membidik pusat kotak surat, jadi lemparan bantu akan selalu "tepat". Lemparan bantu dinilai lewat jalur penilaian yang sama (prediksi = hasil) dan mendapat skor, combo, koin, dan tip seperti biasa, tetapi `tepat` diturunkan menjadi kotak surat biasa (penanda centang). Mode bantu tetap bisa ditabrak dan tetap bisa membunyikan bel.
- **O-5 Pengali kecepatan dari kecepatan sebenarnya saat koran dilepas**, dengan batas pita yang sama dengan pita sprite/umpan balik yang sudah ada (santai < cepat < ngebut; Dev menunjuk konstanta yang dipakai dan mencatatnya di BALANCING 5). Bukan dari posisi stick.

## Di luar scope

- Radar, HUD rute final (progres pelanggan, panel koin final, sisa koran final), tenggat, layar hasil, rumah abu-abu di mode bantu, spike rumah sisi dekat, uji 20 rute dimainkan, penanda garis akhir (Run 3C).
- Rintangan lain (penyiram, tong sampah, mobil tamu), pejalan kaki, bonus zigzag (distrik dua sisi), reputasi, pelanggan cerewet, kerusakan sepeda dari tabrakan (GDD 12, ROADMAP 5 M3), save, hari, misi, headline, upgrade bel.
- Keputusan terbuka ROADMAP 5 yang **tidak boleh diputuskan diam-diam**: game over / batas tabrakan, struktur sesi, jendela bonus atau penalti, cara tampil sisi dekat.
- Menggambar atau mengedit PNG dengan tangan (`art-assets.mdc`). Sprite rintangan dari `assets/sprites/obstacles/obs_anjing_sheet.*` dan `obs_mobil_garasi_sheet.*` dipakai apa adanya (titik pijak dari JSON). Aset bel dari `tools/ui_art/bel.py` (`docs/design/bel/`) disalin ke `assets/sprites/ui/` lewat skripnya (`--salin` atau setara), bukan disalin tangan. Bila perlu aset baru, lewat renderer yang ada dan render ulang di-commit bersama skripnya; kembalikan berkas yang drift piksel tanpa sengaja (catatan 3A).
- Mengunduh aset audio. Semua bunyi baru = sintesis stdlib di `tools/audio_art/`.

## Kriteria penerimaan (bisa diuji)

### A. Rintangan (logika murni di `scripts/systems/`)

- **AC-1 Anjing penjaga** = mesin keadaan murni (`static func`, tanpa node, tanpa RNG global): `DIAM` → `WASPADA` (sepeda masuk `tanda_ubin` di depan: berdiri, menggeram) → `MENGEJAR` (menggonggong, lari searah jalan dengan laju yang mengikuti kecepatan pemain sampai batas lajunya sendiri) → `BERHENTI` di batas halamannya (batas maju kavling + batas lateral separuh jalan sisinya, K-1), lalu `PULANG`/kembali `DIAM`. Juga `MUNDUR` karena bel (AC-14). Semua angka (laju, batas, jarak waspada/mengejar) di `Config`. Perilaku sama untuk anjing yang sama di posisi sama (ROUTE_DESIGN 4 aturan 3): tes dengan masukan identik memberi lintasan identik.
- **AC-2 Mobil keluar garasi** = mesin keadaan murni: `DIAM` → `TANDA` (lampu mundur + bip) → `MUNDUR` ke jalan sampai paling jauh garis tengah (separuh jalan sisinya, K-1) → `BERHENTI` (dan pola sesudahnya ditulis di BALANCING; Dev memilih satu pola sederhana yang bisa dipelajari dan mencatatnya). Tidak pernah melewati garis tengah. Angka di `Config`.
- **AC-3 Tanda sebelum bahaya (ROUTE_DESIGN 4 aturan 2), dites sebagai invarian:** untuk kedua rintangan, di **santai, cepat, dan ngebut**, dan untuk posisi lateral sepeda di seluruh rentang ±2,0 (termasuk trotoar), selang antara tanda pertama (waspada/lampu mundur) dan saat rintangan **pertama kali bisa menyentuh** jalur sepeda ≥ 1,5 detik pada ngebut (dan tidak lebih pendek pada kecepatan lebih rendah). Oracle literal: waktu dan jarak ditulis eksplisit di tes untuk paling sedikit satu kasus per rintangan, bukan dihitung dengan fungsi yang dites.
- **AC-4 Jalan keluar selalu ada (ROUTE_DESIGN 4 aturan 1):** di setiap rute dari seed 20 rute uji, pada setiap posisi maju, ada posisi lateral di [−2,0; 2,0] yang tidak pernah dimasuki rintangan mana pun (sisi seberangnya), dan pemain di santai yang tetap di sisi bebas tidak pernah bertabrakan (simulasi headless rute penuh).
- **AC-5 Data dan pembangun:** rintangan dibangun dari `objek` segmen yang sudah ada (jenis `anjing_penjaga`, `mobil_garasi`; `jalur`; `tanda_ubin`) lewat `Rute`/`RouteBuilder`; validasi data yang ada tetap berlaku. Bila `DATA_SCHEMA` 3 perlu field baru, diperbarui bersama data (satu commit) dan tetap berlabel usulan.

### B. Tabrakan

- **AC-6 Aturan tabrakan murni (K-1):** tabrakan sepeda–rintangan dideteksi dari bentuk sederhana di bidang tanah (ukuran di `Config`), lalu: kecepatan langsung turun ke `TABRAKAN_KECEPATAN_UD` 1,0 (bila lebih tinggi), oleng `TABRAKAN_OLENG_DETIK` 0,6 (selama oleng sepeda tidak bisa menambah kecepatan; arah lateral tetap bisa dikendalikan; lemparan tetap boleh), combo putus, lalu kebal `TABRAKAN_KEBAL_DETIK` (usulan 1,0, dihitung dari saat tabrakan) sehingga satu rintangan atau rintangan lain tidak memicu tabrakan kedua selama kebal. Stamina tidak dihukum tambahan.
- **AC-7 Tabrakan tidak menghentikan rute (prinsip 2), dites:** simulasi headless pemain yang sengaja menabrak **setiap** rintangan di satu rute tetap mencapai garis akhir; `rute_selesai` terpancar tepat sekali; tidak ada keadaan terkunci (kecepatan 0 permanen, input mati, jeda tak berujung).
- **AC-8 Tiap tabrakan bisa dijelaskan:** tabrakan selalu didahului tanda rintangan itu (AC-3) dan diikuti umpan balik visual (sepeda oleng di sprite/kamera kecil, ikon atau kilatan tabrakan, combo terlihat putus di HUD dev) **dan** bunyi tabrakan. Tes scene: sinyal/kejadian tabrakan membawa jenis rintangan penyebabnya.

### C. Skor, combo, koin, tip, tepat

- **AC-9 Skor murni** (`scripts/systems/`, satu sumber): nilai dasar `SKOR_SASARAN_DASAR` (usulan 100) × persen sasaran (kotak surat dan teras 100%, halaman 50%, jendela menurut sakelar, meleset/bukan pelanggan 0; BALANCING 5) × pengali combo × pengali kecepatan saat lepas (santai ×1,0, cepat ×1,2, ngebut ×1,5; O-5) × `SKOR_TEPAT_PENGALI` bila tepat (K-4, bukan untuk mode bantu O-4). Pembulatan ditulis eksplisit di BALANCING 5. Oracle literal untuk paling sedikit 6 kombinasi.
- **AC-10 Combo:** pengali combo mulai ×1,0, +0,1 tiap antaran sah beruntun, maksimum ×2,0 (BALANCING 5). Putus (kembali ×1,0) karena meleset, bukan pelanggan, jendela penalti, atau tabrakan. Koran ke rumah yang sudah terantar tidak memutus dan tidak menaikkan (O-1). Kapan pengali naik (sebelum atau sesudah antaran yang sedang dinilai) ditulis eksplisit dan dites.
- **AC-11 Koin dan tip (K-2, O-1 sampai O-3):** antaran sah pertama tiap pelanggan +`KOIN_ONGKOS_ANTAR` 15; teras ke pemberi tip + `KOIN_TIP` 5; selain itu 0. Koin tidak pernah berkurang (prinsip 2). Rute dengan 25 pelanggan terantar semua memberi 375 koin + tip; dites dengan simulasi. Pemberi tip berseed (seed sama = sama; dites atas sapuan seed bahwa himpunannya bergantung seed — pelajaran QA-001 run 3A).
- **AC-12 Tepat (K-4):** zona inti 0,5 × 0,5 di pusat area kotak surat seberang **dan** dekat (konstanta `Config`, bukan angka di kode), tepi min inklusif / maks eksklusif seperti zona lain. Titik di inti = `TEPAT`; di area tapi di luar inti = kotak surat biasa. Oracle literal: paling sedikit satu titik di dalam inti, satu tepat di tepi, satu di area luar inti, untuk kedua sisi. Penanda "tepat" berbeda bentuk dari centang dan bintang.
- **AC-13 Umpan balik dan HUD dev sementara:** HUD dev menampilkan skor, pengali combo, dan koin lewat kunci terjemahan (label baru di `translations/ui.csv`), tanpa hex di scene, anchor + Container, kidal dicerminkan, tidak menutupi sepeda atau zona stick (`tes_tata_letak.gd` diperbarui). Umpan balik melayang sederhana di titik mendarat (DESIGN_SPEC 3.6: "+15", tip, "TEPAT") boleh berupa versi minimal; maksimal dua sekaligus. Tata letak final menunggu 3C.

### D. Bel "Kring Kring!" (GDD 5.4, DESIGN_SPEC 3.8, K-3)

- **AC-14 Logika bel murni:** ketukan pertama = `KRING`; ketukan kedua selama teks masih tampil = `KRING_KRING`; sesudah dua bunyi, jeda `BEL_JEDA_DETIK` (usulan 1,0) dengan sisa jeda yang bisa dibaca (untuk cincin); ketukan selama jeda ditolak tanpa bunyi. Jangkauan `BEL_JANGKAUAN_UBIN` (usulan 4,0) di depan sepeda. Anjing di `WASPADA` atau `MENGEJAR` dalam jangkauan → ikon "!" lalu `MUNDUR` ke halamannya dan tidak mengejar lagi untuk lintasan sepeda itu; anjing `DIAM` tidak bereaksi; mobil tidak pernah bereaksi. Reaksi per jenis rintangan diatur di satu tabel (bukan `if` per entitas), supaya pejalan kaki nanti tinggal ditambahkan.
- **AC-15 Input bel:** tombol bel 40×40 di pojok kanan bawah, pusat (lebar −28, 332); kidal (28, 332); zona tap lingkaran radius 28. Sentuhan yang **dimulai** di zona bel membunyikan bel dan **tidak** memulai swipe, garis bidik, atau tap mode bantu; swipe yang dimulai di luar lalu melewati tombol tetap swipe. Dua jari (stick + bel, swipe + bel) tidak saling mengganggu (pelacakan `index`). Tombol tidak menutupi panel bawah, tombol mode bantu, atau tombol jeda (`tes_tata_letak.gd`, termasuk rasio 16:9, 19,5:9, 20:9).
- **AC-16 Visual bel:** tombol (normal, ditekan, jeda dengan cincin berkurang), efek di atas setang (garis getar + teks "KRING!" / "KRING KRING!"), ikon "!" di atas anjing yang bereaksi. Aset dari `tools/ui_art/bel.py`. Teks "KRING!" lewat kunci terjemahan bila berupa teks, atau sprite dari renderer bila berupa gambar (catat pilihannya). Selalu tampil juga saat suara mati.
- **AC-17 Bel dan jeda/background:** bel tidak bisa dibunyikan saat jeda game; jeda bel membeku selama jeda game (`dt` 0 sesudah lanjut, seperti sistem lain).

### E. Bunyi (SOUND_DESIGN 3.1, 3.3, 4.3; placeholder sintesis stdlib)

- **AC-18 Nada combo:** bunyi mendarat antaran ke-1 di nada dasar, naik setengah nada tiap antaran sah beruntun sampai 5 tingkat, lalu bertahan; combo putus mengembalikan ke dasar tanpa bunyi tambahan. Pemetaan tingkat → pitch murni di `systems/` (rasio 2^(n/12), oracle literal untuk tingkat 0 sampai 6). Meleset tidak ikut dinaikkan.
- **AC-19 Bunyi baru:** denting tip (sesudah bunyi mendarat), anjing menggeram (waspada) dan menggonggong (mengejar), mobil bip lampu mundur dan mesin, tabrakan, bel "kring" (3 variasi, bunyi kedua sedikit lebih tinggi untuk "kring kring!"), dan bunyi tepat bila berbeda. Semua dibuat skrip di `tools/audio_art/` (stdlib, deterministik), WAV di `assets/audio/sfx/<kelompok>/`, `assets/audio/LICENSES.md` diperbarui, dan ada `tools/tests_cek/uji_sintesis_<...>.py` yang membuktikan berkas = hasil skrip, durasi sesuai, tanpa klik. Diputar autoload `Audio` di bus yang sesuai, berhenti saat jeda/background. **Setiap bunyi punya pasangan visual** (tabel SOUND_DESIGN 4.3 diperbarui).

### F. Scene dan integrasi

- **AC-20 Scene rute:** anjing dan mobil digambar hidup dari sprite sheet (titik pijak dari JSON), ikut jendela daur (tidak semua rintangan diinstansiasi sekaligus), Y-sort benar terhadap sepeda dan rumah, dan objek penutup tetap lewat **satu** `PenerapPenutup` (rintangan yang menutupi pemain jadi semi-transparan tanpa kode per objek). Jalan uji (scene dev) tetap jalan; tes lamanya hijau atau diubah dengan alasan tertulis.
- **AC-21 Jeda/back/background:** rintangan, oleng, kebal, combo, dan bel membeku selama jeda game; tidak ada lanjut otomatis; perilaku sama dengan 3A.
- **AC-22 Main lagi:** tombol dev "Main lagi" mengatur ulang rintangan, skor, combo, koin, status rumah terantar, oleng/kebal, dan jeda bel (tes scene).
- **AC-23 Invarian prinsip desain dites (headless):** (a) tabrakan tidak menghentikan rute (AC-7); (b) **ngebut punya harga dan santai punya harga**: di skenario yang sama, ngebut memberi skor per antaran lebih tinggi tetapi waktu reaksi dari tanda ke bahaya lebih pendek (dalam detik), sedangkan santai memberi skor lebih rendah dan anjing bisa menyusul pemain santai di sisinya sementara pemain ngebut lolos; (c) tanda bahaya datang sebelum bahaya (AC-3).

### G. Umum

- **AC-24** Semua angka baru di `scripts/config.gd` satu baris literal per konstanta (`balancing.mdc`), tanpa angka ajaib di kode (termasuk angka kecil seperti 2); `BALANCING.md` 5 dan 6 diperbarui (skor, combo, pengali, tepat, koin, tip, tabrakan, rintangan, bel) dan bagian 10 (catatan perubahan). Teks pemain lewat `translations/ui.csv` (+ `.translation` hasil impor di-commit).
- **AC-25 Tes dengan mutan nyata dan oracle independen:** Dev mencatat di LOG daftar mutan yang ia jalankan (paling sedikit satu per sistem baru: anjing, mobil, tabrakan, skor, combo, koin/tip, tepat, bel, nada combo) dan tes yang membunuhnya. Harapan tes ditulis eksplisit (angka literal), bukan memanggil fungsi yang dites (pelajaran QA-008 run 2B, QA-001/002 run 3A).
- **AC-26 Gerbang:** `godot --headless --import` bersih; `run_tests.gd` + `tools/cek_keluaran_tes.py` (`--ketat` juga) lolos; `godot --headless --path . --quit-after 2` tanpa ERROR/WARNING; semua `tools/tests_cek/uji_*.py` lolos; `--export-pack "Android"` memuat WAV dan sprite baru dan tidak memuat `tests/` atau `docs/`; probe jendela rute (`probe_rute_jendela.gd` diperluas atau probe baru) menghasilkan tangkapan layar: anjing waspada, anjing mengejar, mobil tanda lampu mundur, mobil di jalan, tabrakan (oleng), bel + KRING KRING! + ikon "!" + anjing mundur, penanda tepat, HUD dev skor/combo/koin, kidal; keluar tanpa ERROR/WARNING (`ProbeKeluar`).

## Perubahan file/struktur yang diharapkan

- `scripts/systems/`: sistem baru, mis. `anjing_penjaga.gd`, `mobil_garasi.gd`, `tabrakan.gd`, `skor_rute.gd` (skor, combo, koin, tip, status terantar), `bel.gd`, `nada_combo.gd` (atau di `bunyi_lempar.gd`); `zona_sasaran.gd` (inti tepat); `route_builder.gd` (pemberi tip berseed, rintangan dari objek). Nama boleh lain, satu tanggung jawab per berkas.
- `scripts/entities/`: penampil rintangan (anjing, mobil), efek bel, penerapan tabrakan/oleng di `adegan_jalan.gd`/`rute_main.gd`; `scripts/ui/`: tombol bel, HUD dev skor/combo/koin, umpan balik melayang minimal; `scripts/autoload/audio.gd`: bunyi baru.
- `tools/audio_art/`: skrip sintesis baru (mis. `sintesis_rute.py`, `sintesis_bel.py`) + `tools/tests_cek/uji_sintesis_*.py`; `assets/audio/sfx/{obstacle,bell,ui}/` (nama menurut SOUND_DESIGN 6 penamaan).
- `assets/sprites/ui/`: aset bel hasil `tools/ui_art/bel.py`.
- `tests/`: `tes_rintangan.gd`, `tes_skor.gd`, `tes_bel.gd`, `tes_rintangan_scene.gd` (atau setara), dan pembaruan `tes_tata_letak.gd`, `tes_bunyi_lempar.gd`, `tes_rute_scene.gd`, `tes_export.gd` bila perlu.
- `translations/ui.csv` (+ `.translation`), `scripts/config.gd`.

## Tes yang harus ada

- Mesin keadaan anjing dan mobil: transisi, batas halaman/garis tengah, determinisme, laju mengikuti pemain, mundur karena bel.
- Invarian tanda ≥ 1,5 detik pada ngebut dari semua posisi lateral (AC-3), jalan keluar selalu ada (AC-4), tabrakan tidak menghentikan rute (AC-7), ngebut/santai punya harga (AC-23).
- Tabrakan: kecepatan, oleng, kebal, combo putus, tidak dobel.
- Skor/combo/koin/tip/tepat/terantar: oracle literal; tip bergantung seed.
- Bel: kring/kring kring/jeda/tolak, jangkauan, tabel reaksi, input tidak memulai swipe, dua jari, kidal.
- Nada combo: rasio pitch literal, reset saat putus.
- Scene: rintangan digambar dan daur, tabrakan dari scene, HUD dev, Main lagi, jeda, penutup tunggal.
- Sintesis audio baru: `uji_sintesis_*.py`.

## Butuh uji perangkat nyata (NEEDS-MANUAL)

- Tanda rintangan terasa cukup (tidak "tidak sempat") di santai, cepat, ngebut; tiap tabrakan bisa dijelaskan (ROUTE_DESIGN 7).
- Rasa tabrakan (1,0 u/d, oleng 0,6, kebal 1,0): menghambat tapi tidak menyebalkan.
- Combo, nada naik, denting tip, bonus tepat: terasa memuaskan; bonus tepat tidak terlalu sulit/mudah.
- Bel: tombol terjangkau jempol, tidak bentrok dengan swipe; anjing mundur terasa adil (tidak membuat anjing tak berarti).
- HUD dev skor/koin terbaca; tidak menutupi apa pun di vivo V2108 (2400×1080).
- Bunyi placeholder (anjing, mobil, tabrakan, bel) tidak mengganggu dan terbaca juga tanpa suara.

## Dokumen yang ikut diperbarui

- `GDD.md` 5.4 dan 9.3 (bel membuat anjing mundur, K-3; kendaraan tetap tidak), `BALANCING.md` 5, 6, 7 (skor, combo, pengali, tepat, koin, tip, tabrakan, rintangan, bel) dan 10, `SOUND_DESIGN.md` 3.1, 3.3, 4.2, 4.3 (placeholder baru), `DESIGN_SPEC.md` 3.6 dan 3.8 (penanda tepat, HUD dev sementara, bel diterapkan), `ROUTE_DESIGN.md` 4 (pola rintangan yang diterapkan, separuh jalan), `DATA_SCHEMA.md` 3 bila field berubah, `ROADMAP.md` 5 (hubungan skor dan koin: dipisah, keduanya dihitung — K-2; jendela tetap terbuka), `docs/README.md`, `AGENTS.md` (peta repo, perintah baru), `SETUP_ANDROID.md` (butir uji HP 3B), `DEV_PHASES.md` (dicentang hanya sesudah PR, oleh orchestrator, untuk yang terbukti dan bukan NEEDS-MANUAL).
