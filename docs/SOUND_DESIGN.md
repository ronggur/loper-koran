# Sound Design Guide — Loper Koran

Dokumen pendamping [`GDD.md`](./GDD.md) (bagian 15) dan [`ART_DIRECTION.md`](./ART_DIRECTION.md). Formatnya mengikuti `SOUND_DESIGN.md` Brainy Dungeon. Seluruh dokumen ini **draf usulan**: yang sudah ada hanya bunyi placeholder dari rumus, yaitu tiga bunyi sepeda (bagian 3.2, run fase1b-umpan-balik 2026-10-14) serta "wus" lemparan dan bunyi mendarat empat permukaan (bagian 3.1, run fase2b-bantu-audio 2026-10-15). Apakah game memakai musik masih terbuka (ROADMAP 5).

---

## 1. Dua Kenyataan

**Pertama: banyak orang main tanpa suara.** Di angkutan umum, di samping orang tidur, atau karena memang tidak suka. Jadi **game harus sepenuhnya bisa dimainkan tanpa audio**. Setiap isyarat suara penting wajib punya pasangan visual: suara meong kucing punya ekor yang bergerak, rantai berisik punya kotak kondisi yang berkedip, anjing menggonggong punya pose berdiri (GDD 10.3, 12.1).

**Kedua: beberapa suara akan didengar ribuan kali.** Koran mendarat (25–30 kali per hari), kayuhan (sepanjang rute), dan bel. Ketiganya menanggung rasa main lebih besar dari semua suara lain, jadi diperlakukan sebagai aset audio terpenting (bagian 3).

---

## 2. Prinsip Audio

Diturunkan dari prinsip GDD bagian 2.

1. **Kecepatan terdengar.** Nada kayuhan, desir angin, dan ritme rantai naik saat ngebut dan turun saat meluncur (GDD 15). Pemain bisa merasakan kecepatannya tanpa melirik bar.
2. **Gagal tidak menghukum.** Koran meleset, tabrakan, dan misi gagal berbunyi lembut dan pendek. Tidak ada buzzer.
3. **Ramah untuk pengulangan.** Suara yang sering diputar punya 3 variasi dan sedikit acak nada (`pitch_scale` ±5%). Uji dengan mendengarnya 30 kali berturut-turut.
4. **Peringatan datang lebih dulu dari bahaya.** Lampu mundur mobil berbunyi bip, anjing menggeram sebelum mengejar, rantai berisik sebelum putus (GDD 12.1). Bunyinya muncul bersamaan dengan tanda visual, minimal 1,5 detik sebelum bahaya (`ROUTE_DESIGN.md` 4).
5. **Lingkungan Indonesia terdengar.** Ambience tiap distrik berisi suara yang dikenal pemain: tukang sayur, ayam, motor, angkot, pasar, sawah (bagian 5).

---

## 3. Suara Terpenting

### 3.1 Koran mendarat

Hadiah inti tiap antaran. Bunyinya membedakan permukaan, supaya pemain tahu hasil lemparan tanpa melihat.

| Mendarat di | Karakter | Durasi |
|---|---|---|
| Kotak surat | "tunk" logam pendek, nada naik | 150–250 ms |
| Teras | "plak" kertas di lantai, renyah | 150–250 ms |
| Rumput / halaman | "puk" lembut, redup | 150–200 ms |
| Meleset (jalan, rumah salah) | "plek" datar dan pelan | 150 ms, lebih pelan |

- Tiga variasi per permukaan.
- **Nada naik mengikuti combo**: antaran ke-1 di nada dasar, lalu naik setengah nada tiap antaran beruntun sampai 5 tingkat, lalu bertahan. Combo putus mengembalikan nada ke dasar tanpa bunyi tambahan.
- Tip pelanggan menambah denting koin kecil setelah bunyi mendarat.

**Placeholder Fase 2 (sudah ada, usulan, run fase2b-bantu-audio 2026-10-15; dinilai di HP).** 13 WAV dibuat dari rumus oleh `tools/audio_art/sintesis_lempar.py` (hanya pustaka standar, deterministik, tanpa rekaman atau unduhan; `assets/audio/LICENSES.md`), diputar autoload `Audio` di bus `SFX` dengan pemetaan dari `scripts/systems/bunyi_lempar.gd` (logika murni, dites headless):

| Berkas (`assets/audio/sfx/throw/`) | Bunyi | Kapan |
|---|---|---|
| `sfx_throw_whoosh_01.wav` | "Wus" 0,20 detik, desis pita sempit yang naik lalu turun | Sekali saat lemparan **diterima** (jari swipe dilepas atau tap mode bantu diterima, koran berkurang 1). Lemparan yang ditolak (pendek, jeda antar lempar, koran habis, jeda game, tanpa sasaran) tidak berbunyi |
| `sfx_land_mailbox_0{1,2,3}.wav` | "Tunk" logam bernada naik, 0,17 / 0,20 / 0,23 detik | Koran mendarat dengan hasil kotak surat |
| `sfx_land_porch_0{1,2,3}.wav` | "Plak" kertas renyah, 0,16 / 0,19 / 0,22 detik | Hasil teras, dan jendela bila sakelar jendela = bonus (sah) |
| `sfx_land_grass_0{1,2,3}.wav` | "Puk" lembut redup, 0,15 / 0,17 / 0,19 detik | Hasil halaman (rumput) |
| `sfx_land_miss_0{1,2,3}.wav` | "Plek" datar, 0,14 / 0,15 / 0,16 detik, sekitar 5 dB lebih pelan di berkasnya | Hasil meleset (jalan, di luar zona), bukan pelanggan (rumah salah), dan jendela bila penalti (bawaan, `Config.JENDELA_KENA_BONUS` false) |

- Bunyi mendarat berbunyi **tepat sekali** di langkah koran mendarat (`JalanUji.koran_mendarat`), dengan hasil dan sakelar jendela yang sama dengan penanda kena/meleset, jadi bunyi dan penanda selalu sejalan.
- Variasi dipilih **bergiliran** per permukaan (01, 02, 03, 01, ...), tanpa acak; pencacahnya di `Audio`, satu per permukaan. Satu pemutar per berkas, jadi bunyi permukaan lain tidak terpotong.
- Volume: "wus" −4 dB, mendarat −1 dB (`Config.AUDIO_WUS_VOLUME_DB`, `AUDIO_MENDARAT_VOLUME_DB`; BALANCING 2), di atas kayuhan −6 dB.
- Pasangan visual: garis bidik hilang dan koran muncul ("wus"); penanda centang/setengah/bintang/silang di titik mendarat (bunyi mendarat, DESIGN_SPEC 3.6).
- **Ditunda ke Fase 3:** nada naik mengikuti combo (skor dan combo belum ada), denting tip. Bunyi jendela pecah (bagian 4.2) belum ada. Acak nada ±5% (bagian 2 butir 3) belum dipakai; giliran tiga variasi dulu, dinilai di HP.

### 3.2 Kayuhan dan kecepatan

- **Loop kayuhan** (rantai + gir) dengan `pitch_scale` mengikuti kecepatan: santai 1,0, cepat 1,15, ngebut 1,3 (usulan). Tempo ketukan pedal disamakan dengan fps animasi (8/10/12, ART_DIRECTION 3.2).
- **Angin** di bus terpisah, keras-pelannya naik saat ngebut.
- **Meluncur**: kayuhan berhenti, diganti bunyi freewheel "tik-tik-tik" pelan. Ini juga tanda stamina sedang pulih.
- **Stamina hampir habis**: napas terengah pendek sekali saat stamina di bawah 30, tidak diulang terus.

**Placeholder Fase 1 (sudah ada, usulan, run fase1b-umpan-balik 2026-10-14; dinilai di HP).** Tiga WAV dibuat dari rumus oleh `tools/audio_art/sintesis_sepeda.py` (hanya pustaka standar, deterministik, tanpa rekaman atau unduhan; `assets/audio/LICENSES.md`), diputar autoload `Audio` di bus `Sepeda` dengan keputusan dari `scripts/systems/bunyi_sepeda.gd` (logika murni, dites headless):

| Berkas | Bunyi | Kapan |
|---|---|---|
| `assets/audio/sfx/bike/sfx_bike_pedal_loop.wav` | Ketukan rantai 8 per detik + hentakan pedal tiap 0,25 detik, loop 1,0 detik | Pose kayuh dan melambat, kecepatan > 0. `pitch_scale` dari kecepatan **sebenarnya**: 1,0 di santai 3,0 u/d, 1,15 di cepat 4,5, 1,3 di ngebut 6,0, linear di antaranya, dijepit (melambat tetap 1,0) |
| `assets/audio/sfx/bike/sfx_bike_freewheel_loop.wav` | "Tik-tik-tik" 10 per detik, pelan, loop 1,0 detik | Pose meluncur (kayuhan berhenti) |
| `assets/audio/sfx/bike/sfx_bike_brake_01.wav` | Decit 2400 Hz bergetar dengan gesekan di awal, 0,45 detik | Sekali saat rem baru aktif (tepi naik, kecepatan > 0); tidak diulang selama rem ditahan. Selama rem dan sesudah berhenti dengan rem: diam |

- Tempo ketukan ikut pitch: 8 / 9,2 / 10,4 per detik di santai / cepat / ngebut, sedangkan animasi kayuh 8 / 10 / 12 fps. Selisihnya dinilai di HP; menyamakan tempo penuh butuh loop terpisah per kecepatan.
- Pasangan visual: animasi kayuh dan bar kecepatan (kayuhan), kaki diam `meluncur` (freewheel), sprite `rem`, debu rem, dan cincin stick `WARN` (decit).
- Belum dibuat (fase lain): angin, napas stamina rendah, variasi acak nada, bel.

### 3.3 Bel sepeda

Bel adalah efek suara sekaligus alat mengusir pejalan kaki (GDD 5.4, 11, 15), dan sejak 2026-10-09 memberi nama pada game: **Kring Kring!** Satu "kring" yang jelas, 300–500 ms, dengan 3 variasi. Ketukan kedua selama teks masih tampil memutar bunyi kedua, jadi terdengar "kring kring!"; bunyi kedua sebaiknya sedikit lebih tinggi supaya dua bunyi terdengar sebagai satu frasa (usulan). Bel yang di-upgrade punya bunyi berbeda (kosmetik). Pasangan visualnya selalu tampil, juga saat suara mati (`design/bel/`).

---

## 4. Daftar Efek Suara

Kolom **M2** menandai yang dibutuhkan untuk satu hari penuh di perumahan (ROADMAP 4).

### 4.1 Sepeda

| Suara | M2 | Pasangan visual |
|---|---|---|
| Kayuhan (loop, 3 kecepatan lewat pitch) | ✅ | Animasi kayuh, bar kecepatan |
| Freewheel saat meluncur | ✅ | Pedal diam |
| Rem dan decit | ✅ | Animasi rem, cincin stick bawah menyala |
| Bel ("kring", dan "kring kring!" saat diketuk dua kali) | ⬜ | Garis getar dan teks "KRING!" di atas setang (`design/bel/`) |
| Tabrakan (lembut, "bruk" + kerincing) | ✅ | Oleng, bintang kecil |
| Selip di genangan / kerikil | ⬜ | Percikan, sepeda bergeser |

### 4.2 Lemparan dan sasaran

| Suara | M2 | Pasangan visual |
|---|---|---|
| Swipe / koran dilempar ("wus") — placeholder ada (bagian 3.1) | ✅ | Koran berputar, garis bidik hilang |
| Mendarat: kotak surat, teras, rumput, meleset — placeholder ada, 3 variasi bergiliran (bagian 3.1); jendela memakai teras (bonus) atau meleset (penalti) | ✅ | Bintang kecil, umpan balik melayang (DESIGN_SPEC 3.6) |
| Tip / koin | ✅ | Koin muncul |
| Pelanggan kesal (gumam pendek) | ⬜ | Pelanggan di teras bereaksi |
| Jendela pecah (kalau dipakai, GDD 4.1) | ⬜ | Kaca retak |

### 4.3 Rintangan dan warga

| Suara | M2 | Pasangan visual |
|---|---|---|
| Anjing menggeram (peringatan), menggonggong (mengejar) | ✅ | Anjing berdiri, lalu lari |
| Mobil: bip lampu mundur, mesin | ✅ | Lampu mundur menyala |
| Tukang sayur (teriakan pendek tanpa kata jelas) | ⬜ | Gerobak muncul |
| Angkot, motor lewat | ⬜ | Kendaraan |
| Ayam, bebek, kerbau (lonceng) | ⬜ | Hewan |

### 4.4 Misi

| Suara | M2 | Pasangan visual |
|---|---|---|
| Petunjuk muncul (denting lembut) | ✅ | Kilau 2 frame (GDD 10.3) |
| Meong kucing, makin keras saat mendekat | ✅ | Ekor bergerak, jejak kaki |
| Misi selesai (motif naik pendek) | ✅ | Banner selesai |
| Misi gagal (motif turun lembut) | ✅ | Banner gagal |
| Lonceng kerbau, ciap anak ayam, dan suara khas misi lain | ⬜ | Sesuai misi (GDD 10.6) |

### 4.5 Kerusakan sepeda

| Suara | M2 | Pasangan visual |
|---|---|---|
| Rantai berisik (peringatan sebelum putus) | ⬜ | Kotak rantai `WARN` dan "!" |
| Rem berdecit (peringatan rem melemah) | ⬜ | Kotak rem `WARN` |
| Ban bocor ("pss" lalu gedebuk pelan) | ⬜ | Kotak ban, sepeda goyang |

### 4.6 Antarmuka dan hasil

| Suara | M2 | Pasangan visual |
|---|---|---|
| Tap tombol | ✅ | Tombol ditekan |
| Buka koran (kertas dibalik) | ✅ | Layar koran muncul |
| Ambil / Lewati misi | ✅ | Tombol |
| Rekap hasil (koin dihitung, tik-tik) | ✅ | Angka berjalan |
| Pelanggan baru / berhenti langganan | ⬜ | Baris di layar hasil |
| Servis di bengkel (kunci pas, pompa) | ⬜ | Kotak kondisi terisi |
| Milestone tercapai | ⬜ | Lencana |

---

## 5. Ambience dan Musik

**Ambience per distrik** (loop 60 detik, tanpa melodi):

| Distrik | Isi |
|---|---|
| Perumahan | Burung pagi, sapu lidi, motor lewat jauh, tukang sayur sesekali |
| Perkampungan | Radio dari rumah, anak main, ayam, sendok di gelas |
| Ruko | Lalu lintas, klakson pendek, rolling door |
| Pasar | Keramaian tanpa kata jelas, timbangan, plastik |
| Desa | Angin di sawah, jangkrik, katak |
| Pinggir sungai | Air mengalir, mesin perahu jauh |

Waktu mengubah lapisan ambience: pagi lebih banyak burung, malam jangkrik dan sunyi. Hujan adalah lapisan tersendiri di atas ambience distrik.

**Musik belum diputuskan** (ROADMAP 5). Pilihan yang dipertimbangkan: tanpa musik seperti Brainy Dungeon (ambience saja), atau musik ringan hanya di layar koran, hasil, dan bengkel, sedangkan rute memakai ambience supaya isyarat suara gameplay tetap terdengar. Diputuskan di M3.

---

## 6. Spesifikasi Teknis

### Format

| Jenis | Format | Alasan |
|---|---|---|
| Ambience, musik | **OGG Vorbis** | Kompresi baik, loop mulus |
| SFX pendek | **WAV** | Latensi rendah untuk lemparan dan pendaratan |

### Struktur bus audio di Godot

```
Master
├── Ambience   <- slider "Suasana"
├── Musik      <- hanya kalau musik dipakai
└── SFX        <- slider "Efek suara"
    ├── Sepeda <- kayuhan dan angin, supaya bisa diredam saat layar jeda
    └── UI
```

Slider terpisah untuk suasana dan efek suara di pengaturan (DESIGN_SPEC 4).

**Yang sudah ada (run fase1b-umpan-balik 2026-10-14, usulan):** `default_bus_layout.tres` di root repo memuat `Master` → `SFX` → `Sepeda` saja (semua 0 dB, tanpa efek). `Ambience`, `Musik`, dan `UI` ditambahkan saat bunyinya ada; musik belum diputuskan. Bus `Sepeda` belum diredam saat jeda: autoload `Audio` menghentikan pemutarnya langsung (lihat "Perilaku di Android"). Bunyi lempar dan mendarat (run fase2b-bantu-audio 2026-10-15) diputar langsung di bus `SFX`, bukan `Sepeda`; tidak ada bus baru.

### Level dan pencampuran

- Normalisasi semua aset supaya volume relatifnya konsisten.
- Ambience jauh di bawah SFX; koran mendarat harus selalu terdengar di atas kayuhan dan ambience.
- Kayuhan duduk di bawah suara sasaran dan peringatan, karena terus berbunyi.
- Uji di speaker HP, bukan headphone.

### Perilaku di Android

- Berhenti saat app masuk background, lanjut wajar saat kembali.
  - **Bunyi sepeda (sudah ada):** background, kehilangan fokus, tombol jeda, dan back Android membuka layar jeda (BALANCING 2, keputusan pemilik 2026-10-14); autoload `Audio` menghentikan ketiga pemutar seketika lewat sinyal `JalanUji.jeda_berubah`, termasuk decit rem yang sedang berbunyi, dan juga saat `NOTIFICATION_APPLICATION_PAUSED`/`FOCUS_OUT` sampai sendiri. `Audio` `PROCESS_MODE_ALWAYS`, jadi pemutar tidak di-pause lalu dilanjutkan otomatis oleh `SceneTree.paused` (yang akan memutar sisa decit lama). Sesudah "Lanjut" bunyi kembali dari keadaan sekarang pada langkah berikutnya; rem harus ditahan ulang, jadi tidak ada decit tertunda.
  - **Bunyi lempar dan mendarat (sudah ada, run fase2b-bantu-audio):** jalur yang sama. Jeda (tombol jeda, back, `FOCUS_OUT`, `APPLICATION_PAUSED`) menghentikan "wus" dan bunyi mendarat yang sedang berbunyi seketika; selama jeda tidak ada bunyi baru (koran beku, lemparan ditolak); sesudah "Lanjut" bunyi lama tidak diputar ulang.
- Tangani headphone dicabut.
- Hormati mode senyap perangkat.

### Anggaran ukuran

Target **di bawah 10 MB** untuk audio M3 (sekitar 40 SFX dan 2–3 ambience).

### Penamaan file

```
sfx_bike_pedal_loop.wav
sfx_bike_bell_01.wav
sfx_land_mailbox_01.wav        <- 3 variasi per permukaan
sfx_land_porch_01.wav
sfx_land_grass_01.wav
sfx_land_miss_01.wav
sfx_obs_dog_growl.wav
sfx_mission_cat_meow_01.wav
sfx_ui_tap.wav
amb_perumahan_pagi.ogg
```

### Struktur folder

```
assets/audio/
  ambience/
  sfx/
    bike/
    throw/
    obstacle/
    mission/
    ui/
  LICENSES.md     <- WAJIB
```

---

## 7. Sumber Audio dan Lisensi

- Set CC0 (misalnya Kenney.nl, Freesound dengan lisensi CC0) boleh dipakai, tapi periksa lisensi tiap file.
- Suara khas Indonesia (tukang sayur, angkot, pasar) sebaiknya direkam sendiri atau dicari dengan lisensi yang jelas, karena jarang ada di set umum.
- Catat setiap file pihak ketiga di `assets/audio/LICENSES.md`: nama file, sumber, lisensi, tautan, kewajiban atribusi.

---

## 8. Urutan Produksi

1. **Fase 1–2:** kayuhan dengan pitch, freewheel, rem, swipe, empat bunyi mendarat. Placeholder boleh. (Kayuhan, freewheel, dan rem placeholder sudah ada sejak run fase1b-umpan-balik, bagian 3.2; "wus" dan empat bunyi mendarat sejak run fase2b-bantu-audio, bagian 3.1.)
2. **Fase 3–4:** anjing, mobil, tabrakan, tip, suara misi kucing, UI dasar, ambience perumahan.
3. **Fase 6–7:** kerusakan sepeda, bengkel, hasil harian, bel, keputusan musik.
4. **Fase 8:** ambience dan suara khas distrik berikutnya.

---

## 9. Yang Perlu Diputuskan

- Musik atau hanya ambience (M3).
- Suara khas yang direkam sendiri atau dari pustaka.
- Apakah pelanggan punya suara "gumam" per kepribadian.
- Getar (haptic) saat koran mendarat dan tabrakan, dan apakah bisa dimatikan terpisah.
