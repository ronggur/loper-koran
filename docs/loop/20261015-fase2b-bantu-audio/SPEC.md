# SPEC — 20261015-fase2b-bantu-audio

Run 2B Fase 2, sesudah Run 2A (PR #24) dan run arah bebas (PR #25, di-merge 2026-10-15). Isinya butir Fase 2 yang tersisa: **mode bantu**, **bunyi lempar dan mendarat**, dua temuan DEFERRED, dan checklist uji HP untuk menutup Fase 2 dan M1. Kontrak bagi Dev **dan** QA. Prosedur penuh di `docs/LOOP-DEV-QA.md` (maksimal 2 iterasi).

## Tujuan

1. **Mode bantu** (GDD 5.3, rule `ui-scenes`: wajib ada dan sepenuhnya bisa dimainkan). Tap di zona lempar melempar otomatis ke kotak surat pelanggan terdekat di depan, di sisi jalan yang ditap. Lemparannya dihitung oleh `ThrowSolver` yang sama dengan swipe, jadi warisan kecepatan, jeda lepas, lengkung, penilaian zona, sisa koran, dan jeda antar lempar tidak berubah.
2. **Bunyi lempar dan mendarat placeholder** (SOUND_DESIGN 3.1, 4.2). Ada satu "wus" saat koran dilempar. Bunyi mendarat dibedakan untuk kotak surat, teras, rumput/halaman, dan meleset, dengan tiga variasi per permukaan. Semua WAV dibuat skrip sintesis stdlib yang deterministik dan diputar lewat autoload `Audio`.
3. **Perapian DEFERRED.**
   - QA-008 run 2A: oracle tes `GambarPiksel` harus independen.
   - QA-005 dan QA-006 run arah bebas: mock kontrol, DESIGN_SPEC 6, dan kata di GDD 4.2.
4. **Checklist uji HP penutup Fase 2 dan M1** di `docs/SETUP_ANDROID.md` bagian 8.

Semua sifat run sebelumnya tetap berlaku dan dijaga tes yang ada:
- arah bebas, ambang 6% dan 35%, warisan maju 100%, jeda lepas 0,17 detik;
- garis bidik sama dengan hasil, termasuk saat flick;
- zona menilai dari titik mendarat saja;
- sisa koran 30, jeda antar lempar 0,35 detik;
- jeda game membekukan koran, kidal menukar zona tanpa mengubah arti arah.

## Keputusan dari pemilik (2026-10-15, dijawab di awal sesi run ini)

Keempatnya adalah rekomendasi orchestrator yang dipilih pemilik. Statusnya **usulan** yang dinilai lewat uji HP, jadi jangan menulisnya "dikunci".

- **K-1 Kecepatan otomatis = santai, stick opsional.** Di mode bantu, tanpa sentuhan stick sepeda melaju santai 3,0 u/d (`KECEPATAN_SANTAI_UD`). Ini perilaku stick netral yang sudah ada, dan santai tidak menguras stamina. Stick tetap aktif penuh untuk pindah sisi, melambat, meluncur, rem, cepat, dan ngebut. Jadi mode bantu bisa dimainkan dengan satu jempol (tap saja).
- **K-2 Sisi tap = garis jalan, di zona swipe.** Tap dihitung hanya di zona lempar, yaitu zona swipe (kanan, atau kiri bila kidal). Sisi ditentukan dari posisi tap relatif terhadap garis searah jalan di layar yang melewati sepeda. Di atas garis itu `SEBERANG`, di bawahnya `DEKAT`. Stick tetap di zona stick, jadi tidak ada bentrok.
- **K-3 Sasaran = kotak surat pelanggan terdekat di depan, selalu kena.** Kandidatnya hanya kotak surat **pelanggan** di sisi yang ditap, dengan pusat berada di depan sepeda dan bisa dicapai lintasan (u 0 sampai 1, dengan warisan kecepatan dan jeda lepas). Lintasan diarahkan ke pusat kotak surat, jadi selalu mendarat di zona kotak surat. Kalau tidak ada sasaran, tidak ada lemparan: koran tidak berkurang, jeda antar lempar tidak mulai, dan muncul tanda kecil.
- **K-4 Jeda tetap.** Jeda antar lempar 0,35 detik (`LEMPAR_JEDA_DETIK`) dan jeda lepas 0,17 detik (frame 2 dari 4 di 12 fps) tidak diubah. Mode bantu memakai jeda yang sama. Rasa responsif ditanyakan khusus di checklist uji HP.
- Keputusan sebelumnya tetap berlaku:
  - ubin 64×32 dan skala ×3 dikunci;
  - arah lempar bebas (ROADMAP 4b);
  - `JENDELA_KENA_BONUS` bawaan false (penalti ringan) dan keputusan akhirnya masih terbuka;
  - uji HP dilakukan pemilik sendiri;
  - kerusakan di mode bantu tetap terbuka (ROADMAP 5). Fase 2 tidak menyentuhnya.

## Rincian usulan orchestrator (bisa ditolak di review PR)

- **D-1 Tap.** Tap adalah sentuhan yang mengklaim slot swipe dan, **selama seluruh hidupnya**, panjang swipe |v| (dari titik awal ke posisi mana pun yang pernah dicapai) tidak pernah mencapai min 6%.
  - Sentuhan yang pernah mencapai min lalu ditarik kembali ke dekat titik awal tetap **batal**, seperti sekarang. Itu bukan tap, supaya gerakan batal tidak berubah jadi lemparan otomatis.
  - Tap tidak dibatasi durasi, jadi tidak ada angka setel baru.
  - Posisi tap = titik awal sentuhan.
  - Pelacakan |v| maksimum ada di `TouchRouter` (logika murni). Bentuk sinyal atau API-nya bebas, asal dites.
  - Sentuhan yang mulai di luar zona swipe (termasuk tombol jeda, tombol kidal, dan tombol mode bantu) bukan tap.
- **D-2 Swipe manual tetap jalan di mode bantu.** Swipe ≥ min melempar persis seperti sekarang (garis bidik, flick, batal). Tap di luar mode bantu tidak melakukan apa-apa, sama seperti sekarang.
- **D-3 Sisi dari tap.** Sisi = `ThrowSolver.sisi_dari_arah(ThrowSolver.arah_tanah(tap − posisi_sepeda_di_layar))`. Pemisah sisinya sama dengan arah bebas, jadi tidak ada aturan sisi kedua.
  - `posisi_sepeda_di_layar` adalah titik pijak sepeda dalam koordinat viewport game. Scene yang menghitungnya (kamera ikut bergeser). Logika menerimanya sebagai parameter.
  - Tap tepat di garis (x tanah = 0) memberi `DEKAT`, sama dengan aturan sisi yang ada.
  - Kidal tidak mengubah aturan ini.
- **D-4 Pemilihan sasaran (logika murni baru di `scripts/systems/`, nama bebas, mis. `BantuLempar`).**
  - Masukan: sisi, posisi sepeda, kecepatan maju sebenarnya, kecepatan lateral efektif langkah terakhir, jeda lepas animasi untuk sisi itu, lebar viewport, dan daftar zona (`ZonaSasaran.zona_jalan_uji_sekitar` di scene; fungsinya menerima daftar zona apa pun supaya Fase 3 bisa memakai data rute).
  - Kandidat: zona `KOTAK_SURAT` dengan `pelanggan == true` dan sisi = sisi tap, yang maju pusatnya ≥ maju posisi sepeda saat tap ("di depan").
  - Untuk tiap kandidat, cari u dan arah tanah sehingga `ThrowSolver.hitung(panjang(u), lebar, arah, …)` mendarat di pusat zona. Lintasan yang dipakai **adalah hasil `ThrowSolver.hitung`**, bukan rumus kedua. Pencarian u (mis. bisection pada |R(u)| − jarak(u), dengan R(u) = pusat − titik_lepas − maju × v × T(u) × warisan) boleh di modul baru, tapi titik mendarat akhirnya dicek ulang lewat lintasan `hitung` dan harus dimuat zona kotak surat itu.
  - Pilih kandidat terjangkau dengan maju pusat terkecil, yaitu yang paling dekat di depan. Seri diputus dengan lateral terkecil, lalu urutan daftar.
  - Tidak ada kandidat terjangkau = null.
  - Toleransi numerik ditulis di `config.gd` bila perlu (satu baris, satuan di nama).
- **D-5 Lemparan bantu di scene.** Tap di mode bantu melewati gerbang yang sama dengan swipe: tidak jeda, `SisaKoran.boleh_lempar`, lalu `SisaKoran.terima`. Sesudah itu langkahnya juga sama dengan swipe: `KoranLempar.baru`, `_sepeda.lempar(sisi)`, HUD, dan sinyal `koran_dilempar`.
  - Lintasan dihitung sekali dari keadaan sepeda **langkah terakhir** saat tap diterima, lalu dibekukan, sama dengan lemparan swipe tanpa garis bidik.
  - Tidak ada garis bidik untuk tap (tap seketika). Elips pendaratan dan penanda tetap tampil.
  - Tap saat koran habis, saat jeda antar lempar, atau saat jeda game: tidak melempar dan tidak mengubah apa pun.
- **D-6 Tanda "tidak ada sasaran".** Bila tap di mode bantu ditolak karena tidak ada kotak surat terjangkau, tampilkan tanda kecil di titik tap selama waktu singkat dari `config.gd`.
  - Bentuknya silang kecil atau lingkaran kecil memakai token Palette yang ada (mis. `MUTED`), bukan teks dan bukan warna saja.
  - Tanda ini tidak memakai koran dan tidak memulai jeda.
  - Tap yang ditolak karena koran habis atau jeda antar lempar tidak perlu tanda baru. HUD koran sudah memberi tanda HABIS.
- **D-7 Sakelar mode bantu di HUD dev**, seperti tombol kidal (layar pengaturan belum ada).
  - Tombolnya sakelar dengan ikon atau teks lewat kunci terjemahan baru (mis. `HUD_BANTU`) di `translations/ui.csv`.
  - Target sentuh ≥ ukuran tombol kidal. Letaknya di strip atas HUD, di luar zona stick dan swipe, dan tidak bertumpuk dengan tombol kidal, tombol jeda, atau panel.
  - Bawaannya mati, dan tidak disimpan (belum ada save, sama seperti kidal).
  - Statusnya harus terlihat (ditekan/tidak), tidak hanya dari warna.
- **D-8 Rumah bukan pelanggan tampil abu-abu di mode bantu**: ditunda sampai radar ada (Fase 3). Cukup dicatat di GDD 5.3 dan DEV_PHASES Fase 3, tanpa kode.
- **D-9 Bunyi.** Skrip baru `tools/audio_art/sintesis_lempar.py` (stdlib saja, deterministik, gaya `sintesis_sepeda.py`) menulis 13 WAV ke `assets/audio/sfx/throw/`:
  - `sfx_throw_whoosh_01.wav` ("wus" pendek, desis pita sempit yang naik-turun, sekitar 150–250 ms);
  - `sfx_land_mailbox_0{1,2,3}.wav` ("tunk" logam pendek nada naik, 150–250 ms);
  - `sfx_land_porch_0{1,2,3}.wav` ("plak" kertas renyah, 150–250 ms);
  - `sfx_land_grass_0{1,2,3}.wav` ("puk" lembut redup, 150–200 ms);
  - `sfx_land_miss_0{1,2,3}.wav` ("plek" datar, sekitar 150 ms, lebih pelan dari tiga permukaan lain).

  Format WAV mono 16-bit, laju sampel sama dengan bunyi sepeda. Tiga variasi berbeda nyata (nada/warna/panjang), bukan salinan. Ukuran total jauh di bawah anggaran audio. Lisensi dicatat di `assets/audio/LICENSES.md` (buatan sendiri dari rumus, sama dengan bunyi sepeda). README alat diperbarui.
- **D-10 Pemetaan hasil → bunyi (logika murni, mis. `BunyiLempar` di `scripts/systems/`).**
  - `KOTAK_SURAT` → mailbox, `TERAS` → porch, `HALAMAN` → grass.
  - `MELESET` dan `BUKAN_PELANGGAN` → miss ("meleset: jalan, rumah salah", SOUND_DESIGN 3.1).
  - `JENDELA` mengikuti status antaran: penalti (tidak sah) → miss, bonus (sah) → porch, sampai bunyi jendela ada (SOUND_DESIGN 4.2 ⬜).
  - Variasi dipilih bergiliran per permukaan (01, 02, 03, 01, …), deterministik tanpa RNG. Pencacahnya ada di `Audio`, dan fungsi pemilihnya murni.
- **D-11 Kapan berbunyi.**
  - "Wus" berbunyi saat lemparan **diterima** (jari dilepas atau tap diterima, satu kali per koran yang benar-benar terpakai), supaya terasa responsif. Pasangan visualnya: garis bidik hilang dan koran muncul.
  - Bunyi mendarat berbunyi tepat sekali di langkah koran mendarat (sinyal `koran_mendarat`). Pasangan visualnya penanda di titik mendarat.
  - Lemparan yang ditolak tidak berbunyi.
  - Volume di `config.gd` (dB, satu baris per konstanta). Mendarat terdengar di atas kayuhan (SOUND_DESIGN 6 "Level"), dan meleset lebih pelan dari mendarat lain.
  - Bus `SFX` (bukan `Sepeda`). Bus baru tidak wajib. Kalau ditambah, `default_bus_layout.tres` dan SOUND_DESIGN 6 diperbarui.
  - Nada naik mengikuti combo **ditunda ke Fase 3** (skor dan combo belum ada). Dicatat di SOUND_DESIGN 3.1 dan DEV_PHASES Fase 3, tanpa kode.
- **D-12 Bunyi berhenti saat jeda dan background.** Jeda game (tombol jeda, back, `FOCUS_OUT`, `APPLICATION_PAUSED`) menghentikan bunyi lempar dan mendarat yang sedang berbunyi **seketika**, dengan jalur yang sama seperti decit rem. Selama jeda tidak ada bunyi baru (koran beku, jadi tidak mendarat). Sesudah "Lanjut" tidak ada sisa bunyi lama yang diputar ulang.
- **D-13 Alat uji bunyi.** Tambah `tools/tests_cek/uji_sintesis_lempar.py`, setara `uji_sintesis_sepeda.py`. Isinya:
  - skrip dua kali → byte sama (deterministik);
  - WAV di `assets/` = hasil skrip;
  - durasi tiap berkas di rentang D-9;
  - puncak miss < puncak permukaan lain;
  - tiga variasi tiap permukaan berbeda;
  - tidak ada klik di awal dan akhir (sampel tepi mendekati nol).

  Alat ini didaftarkan di `.github/workflows/tes.yml`, `AGENTS.md`, dan `00-project-core.mdc` (perintah).

## Di luar scope

- Animasi lempar pemain baru (aset Fase 5). Sprite `lempar` yang ada tetap dipakai.
- Radar, rumah abu-abu di mode bantu, skor, combo dan nada naik combo, tip, koin, status antaran per rumah (Fase 3).
- Layar pengaturan dan penyimpanan sakelar mode bantu/kidal (belum ada save).
- Mengubah angka lintasan, ambang swipe, jeda 0,35/0,17, atau zona sasaran (K-4).
- Bunyi jendela pecah, bel, musik, ambience.
- Mengunduh aset audio dari internet (dilarang).
- Kerusakan di mode bantu (ROADMAP 5).

## Kriteria penerimaan (bisa diuji)

**Mode bantu**
- **AC-1 Tap.** `TouchRouter` membedakan tap (|v| maksimum selama sentuhan < min 6% lebar viewport) dari swipe. Sentuhan yang pernah ≥ min lalu ditarik kembali bukan tap. Tes headless mencakup:
  - tap di tepat min − ε dan tepat min (inklusif = swipe);
  - tarik-lalu-kembali;
  - dua jari (stick + tap bersamaan);
  - jari kedua di zona swipe yang terisi;
  - `batal`/`batal_semua` di tengah sentuhan;
  - kidal (tap di zona swipe kiri).
- **AC-2 Sisi tap** mengikuti D-3. Tes mencakup tap di atas garis → `SEBERANG`, di bawah → `DEKAT`, tepat di garis → `DEKAT`, dengan posisi sepeda di layar yang berbeda-beda (garis ikut sepeda), dan kidal sama.
- **AC-3 Pemilihan sasaran** (D-4), dites murni. Tes mencakup:
  - memilih kotak surat pelanggan terdekat di depan pada sisi yang benar;
  - melewati rumah bukan pelanggan (n mod 4 = 2) ke pelanggan berikutnya bila terjangkau;
  - tidak memilih kotak surat di belakang sepeda;
  - tidak memilih sisi lain;
  - null bila tidak ada kandidat terjangkau (mis. kotak surat terlalu jauh di depan, atau satu-satunya kandidat bukan pelanggan);
  - daftar zona kosong → null.
- **AC-4 Selalu kena dan satu lintasan.** Untuk tiap sasaran yang dipilih, lintasan adalah keluaran `ThrowSolver.hitung` dan `ZonaSasaran.klasifikasi(lintasan.mendarat, zona)` = `KOTAK_SURAT`. Ini dites di santai 3,0, cepat 4,5, ngebut 6,0, dan kecepatan antara, dengan lateral sepeda di tepi seberang, tengah, dan tepi dekat, kecepatan lateral ≠ 0, kedua sisi, dan berbagai fase kavling. u selalu di [0, 1].
- **AC-5 Lemparan bantu di scene** (tes scene terpadu, seperti `tes_koran_scene.gd`). Tes mencakup:
  - mode bantu nyala + tap di zona swipe → satu koran terbang, sisa koran −1, mendarat dan dinilai `KOTAK_SURAT`;
  - tap kedua sebelum 0,35 detik ditolak tanpa mengurangi koran, sesudah 0,35 diterima;
  - koran habis → tap tidak melempar;
  - jeda game → tap tidak melempar dan koran yang terbang beku;
  - mode bantu mati → tap tidak melempar;
  - swipe manual tetap melempar di mode bantu;
  - kidal + mode bantu → tap di zona kiri melempar;
  - tap tanpa sasaran → tidak ada koran, sisa tetap, tanda D-6 tampil, lalu hilang sesudah waktunya.
- **AC-6 Kecepatan otomatis** (K-1). Mode bantu nyala tanpa stick selama beberapa detik → kecepatan menuju 3,0 u/d dan stamina tidak turun. Stick tetap mengubah kecepatan dan sisi di mode bantu. Tes scene.
- **AC-7 Sakelar mode bantu** di HUD dev (D-7). Tes mencakup:
  - `pressed`/`toggled` mengubah mode bantu di scene;
  - rect tombol ≥ tombol kidal dan di luar `rect_stick` dan `rect_swipe` (kidal maupun tidak) di 640, 780, 800;
  - tidak bertumpuk dengan tombol kidal, tombol jeda, dan panel;
  - teks lewat kunci terjemahan (tidak ada string tertanam).
- **AC-8 Tidak ada rumus lintasan kedua.** `git grep` tidak menemukan perhitungan titik mendarat di luar `ThrowSolver`, kecuali pencarian u di modul bantu, yang hasilnya selalu dicek ulang lewat `ThrowSolver.hitung` (AC-4). QA memeriksanya lewat review.

**Bunyi**
- **AC-9 Aset bunyi** (D-9, D-13). `python3 tools/tests_cek/uji_sintesis_lempar.py` lolos. 13 WAV ada beserta `.import` hasil Godot, dan `godot --headless --import` bersih.
- **AC-10 Pemetaan** (D-10). Tes murni mencakup setiap `ZonaSasaran.Hasil` × sakelar jendela → permukaan yang benar, giliran variasi 01→02→03→01 per permukaan dan independen antar permukaan, dan berkas yang dirujuk ada.
- **AC-11 Pemicu** (D-11, tes scene dengan `Audio` di driver Dummy dan `putar_di_driver_dummy` seperti tes bunyi yang ada). Tes mencakup:
  - lemparan swipe dan tap yang diterima → tepat satu "wus";
  - lemparan ditolak (jeda, habis, pendek, tanpa sasaran) → tidak ada "wus";
  - mendarat → tepat satu bunyi dengan permukaan sesuai hasil;
  - dua koran mendarat → dua bunyi, variasi bergiliran.
- **AC-12 Berhenti saat jeda dan background** (D-12). Tes mencakup jeda saat bunyi mendarat atau "wus" berbunyi → pemutar berhenti seketika, `NOTIFICATION_APPLICATION_PAUSED`/`FOCUS_OUT` sampai ke `Audio` → berhenti, dan sesudah lanjut tidak ada bunyi lama yang diputar ulang. Bunyi sepeda tetap seperti sebelumnya (tes lama hijau).

**Perapian DEFERRED**
- **AC-13 QA-008.** Tes kabel gambar (`tests/tes_koran_scene.gd` dan lainnya) tidak lagi memakai `GambarPiksel.perintah_pola`/`warna_huruf` sebagai oracle. Harapan ditulis eksplisit: warna dan alpha perintah ikon ke-i (termasuk redup 28% yang terpakai), isi `w` penanda = `OK`/`FAIL`, garis luar `o` = `OUTLINE`, elips tertutup redup. Empat mutan QA dari LOG run 2A harus **mati** di `scripts/ui/gambar_piksel.gd`:
  - N16 `warna.a *= alpha` dibuang;
  - N20 huruf `o` memakai warna utama;
  - N21 huruf `w` dilewati;
  - N22 alpha ditimpa 1.

  Dev mencatat bukti mutan (jumlah tes gagal per mutan) di LOG.
- **AC-14 QA-005.** `docs/design/source/kontrol.html` menulis aturan arah bebas, menggantikan "swipe kiri = seberang, kanan = dekat". Mode bantu boleh disebut sebagai catatan.
  - Render `docs/design/screens/kontrol.png` dan `kontrol-board.png` diperbarui **hanya** bila bisa dirender ulang dari HTML dengan alat yang ada di mesin (mis. Chrome headless `--screenshot` di ukuran asli 1600×720 dan ukuran board yang sama dengan berkas lama). Perintahnya dicatat di DESIGN_SPEC 0 atau README design.
  - Bila tidak bisa dirender sama ukurannya, PNG tidak disentuh dan tabel DESIGN_SPEC 6 diberi baris: di mock tertulis swipe kiri = seberang, kanan = dekat; digantikan arah bebas GDD 5.2; pakai DESIGN_SPEC 3.7 dan BALANCING 4.
  - Tabel DESIGN_SPEC 6 dan 3.7 tidak lagi memuat aturan dua arah sebagai aturan yang berlaku.
  - `git grep -n "Swipe kiri" docs/design` hanya menyisakan baris tabel 6 yang menandainya usang (bila PNG tidak dirender).
- **AC-15 QA-006.** GDD 4.2 memakai "mengarah ke" sisi seberang/dekat, bukan "jatuh di".

**Dokumen dan uji HP**
- **AC-16 Checklist uji HP** `docs/SETUP_ANDROID.md` bagian 8 untuk penutup Fase 2 dan M1. Langkah dan hasil yang diharapkan ditulis per butir:
  - kotak surat bisa dikenai **dengan sengaja** di santai, cepat, dan ngebut (mis. 10 lemparan per kecepatan, catat berapa kena);
  - ketelitian swipe pendek di layar kecil;
  - swipe ke atas, kiri, kanan, dan bawah;
  - garis bidik saat melaju;
  - rasa responsif jeda 0,35 dan 0,17 (K-4);
  - mode bantu: tap di atas dan di bawah garis jalan, tanpa sasaran, kidal, dan bisa dimainkan satu jempol;
  - bunyi "wus" dan empat bunyi mendarat terdengar dan bisa dibedakan tanpa melihat, di speaker HP;
  - bunyi berhenti saat jeda dan background;
  - **dua pertanyaan kontrol GDD 17**: ambang rem dan ketelitian swipe pendek. Ambang rem sudah lolos 2026-10-14, jadi ini cukup konfirmasi.

  Tempat isian hasil disediakan.
- **AC-17 Dokumen ikut diperbarui** (rule `docs`):
  - GDD 5.3: rincian mode bantu K-1 sampai K-3 dan D-1 sampai D-3, ditandai usulan dengan tanggal; rumah abu-abu menunggu radar;
  - BALANCING: bagian mode bantu (aturan tap, pemilihan sasaran, selalu kena, angka baru) dan volume bunyi bila ada di `config.gd`;
  - SOUND_DESIGN 3.1, 4.2, 6: yang sudah ada, pemetaan, dan combo ditunda;
  - TECH_PLAN Fase 2 bila nama modul berbeda;
  - DESIGN_SPEC 3.5 dan 3.7: tombol mode bantu dan tanda tanpa sasaran;
  - DEV_PHASES Fase 3: catatan rumah abu-abu di mode bantu dan nada naik combo;
  - `AGENTS.md` (peta repo dan perintah), `00-project-core.mdc` (perintah), dan `docs/README.md` (status) sesuai kenyataan.

  `DEV_PHASES` Fase 2 **tidak** dicentang oleh Dev. Orchestrator mencentang "Mode bantu" sesudah PR dibuka. "Uji di HP" tetap kosong sampai pemilik menguji.

**Gerbang umum**
- **AC-18** Semua gerbang hijau:
  - `godot --headless --import` tanpa ERROR/WARNING;
  - `run_tests.gd` + `tools/cek_keluaran_tes.py` (juga `--ketat`);
  - `godot --headless --path . --quit-after 2` bersih;
  - tiga alat Python lama + `uji_sintesis_lempar.py` lolos;
  - `--export-pack "Android"` tanpa `tests/`, `docs/`, dan probe;
  - tidak ada angka ajaib baru di luar `config.gd`, tidak ada hex di luar `palette.gd`, tidak ada teks pemain tertanam, tidak ada `kiri`/`kanan` untuk sisi jalan.
- **AC-19 Tangkapan layar jendela asli** 2340×1080 lewat probe yang ada atau probe baru yang keluar lewat `ProbeKeluar`, disimpan ke `docs/loop/20261015-fase2b-bantu-audio/shots/`. Isinya:
  - tombol mode bantu mati dan nyala;
  - koran bantu terbang ke kotak surat seberang dan dekat;
  - penanda centang di kotak surat;
  - tanda tanpa sasaran;
  - kidal + mode bantu.

  Lolos `tools/cek_blok_piksel.py`.

## Perubahan file/struktur yang diharapkan (perkiraan, Dev boleh menyesuaikan dengan alasan)

- Baru:
  - `scripts/systems/bantu_lempar.gd` (pemilihan sasaran dan sisi tap);
  - `scripts/systems/bunyi_lempar.gd` (pemetaan dan variasi);
  - `tools/audio_art/sintesis_lempar.py`;
  - `tools/tests_cek/uji_sintesis_lempar.py`;
  - `assets/audio/sfx/throw/*.wav` (+ `.import`);
  - tes baru atau tambahan di `tests/`;
  - probe tangkapan layar bila perlu.
- Diubah:
  - `scripts/systems/touch_router.gd` (tap);
  - `scripts/entities/jalan_uji.gd` (mode bantu, sinyal bunyi);
  - `scripts/ui/hud_dev.gd` dan `scenes/ui/hud_dev.tscn` (tombol);
  - `scripts/autoload/audio.gd` (pemutar lempar dan mendarat, berhenti saat jeda);
  - `scripts/config.gd`;
  - `translations/ui.csv` (+ hasil impor);
  - `assets/audio/LICENSES.md`, `tools/audio_art/README.md`;
  - `.github/workflows/tes.yml`;
  - tes QA-008;
  - `docs/design/source/kontrol.html` (dan PNG bila dirender);
  - dokumen di AC-17.

## Tes yang harus ada (mutan nyata)

Setiap logika murni baru dijaga tes yang **gagal** bila logikanya dirusak. Dev menjalankan mutan sendiri dan mencatat hasilnya di LOG (mutan, jumlah gagal). Minimal satu mutan per butir:
- tap: ambang `<` diganti `<=`, |v| maksimum diganti |v| akhir;
- sisi tap: tanda dibalik, posisi sepeda diabaikan;
- sasaran: filter pelanggan dibuang, filter "di depan" dibuang, filter sisi dibuang, pilih terjauh, tanpa cek ulang `hitung`, warisan kecepatan diabaikan di pencarian u;
- scene: gerbang jeda antar lempar dilewati untuk tap, sisa koran tidak dikurangi untuk tap, mode bantu diabaikan, kidal tidak dihormati;
- bunyi: permukaan tertukar, variasi tidak bergiliran, wus diputar untuk lemparan ditolak, bunyi mendarat dua kali, jeda tidak menghentikan pemutar lempar/mendarat;
- QA-008: N16, N20, N21, N22.

Tes oracle **independen**: angka harapan ditulis eksplisit atau dihitung dengan cara berbeda dari kode yang dites (pelajaran QA-008).

## Butuh uji perangkat nyata (NEEDS-MANUAL)

- Kotak surat bisa dikenai dengan sengaja di santai, cepat, dan ngebut (kriteria selesai Fase 2 dan M1).
- Ketelitian swipe pendek di layar kecil (GDD 17) dan rasa responsif jeda 0,35/0,17 (K-4).
- Mode bantu: tap sisi terasa jelas (garis jalan masuk akal?), satu jempol cukup, tanda tanpa sasaran terbaca, dan sakelar mudah dijangkau tapi tidak terpencet tak sengaja.
- Bunyi "wus" dan empat permukaan terdengar di speaker HP di atas kayuhan dan bisa dibedakan tanpa melihat. Bunyi berhenti saat jeda dan background.
- Fase 2 dan M1 **tidak dicentang selesai** sebelum pemilik menguji ini.

## Dokumen yang ikut diperbarui

Lihat AC-17. Orchestrator sesudah PR dibuka: centang `DEV_PHASES` Fase 2 "Mode bantu" (bukan "Uji di HP"), lalu catat baris status di `docs/README.md` dan `ROADMAP.md` bila berubah.
