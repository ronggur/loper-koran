# Design Spec — Loper Koran UI

Spesifikasi visual untuk mengimplementasikan HUD dan layar game di Godot. Pasangan dari `ART_DIRECTION.md` (gaya dan aset) dan GDD bagian 4.3, 5.2, dan 12.4. Isinya diturunkan dari mock kanvas "Loper Koran — Kamera dan Kontrol" (papan **UI in-game** dan **Kontrol landscape**, 2026-10-05). Semua ukuran adalah **usulan** sampai dicoba di HP (Fase 1–3).

## 0. Cara memakai folder ini

| Path | Isi | Dipakai untuk |
|---|---|---|
| `design/DESIGN_SPEC.md` | Dokumen ini | Token, ukuran, perilaku, teks UI |
| `design/screens/hud-rute.png` | Render HUD saat mengantar, 1600×720 (×2 dari kanvas dasar) | Acuan visual HUD |
| `design/screens/kontrol.png` | Render zona kontrol, 1600×720 | Acuan zona stick dan swipe |
| `design/screens/*-board.png` | Papan lengkap dengan catatan | Konteks |
| `design/source/*.html` | Source HTML kedua papan (versi berdiri sendiri, latar `scene.png`) | Angka persis kalau spec ini kurang detail |
| `design/character/loper_agen/` | Sprite pemain produksi untuk Godot | Lihat `ART_DIRECTION.md` 3 |
| `design/bel/` | Tombol bel, efek "kring", ikon "!" (usulan) | Bagian 3.8 |
| `design/hud/` | Pratinjau ikon HUD, penanda radar, contoh radar di layar (usulan); PNG 1× di `assets/sprites/ui/` | Bagian 1.3, 3.3, 3.4 |

**Skala.** Kanvas dasar game tingginya 360 px dengan lebar 640–800 px tergantung rasio layar (ART_DIRECTION 7). **Semua angka di dokumen ini dalam piksel dasar (kanvas 800×360)**, kecuali ditulis lain. Mock digambar di 1600×720, jadi angka di source HTML dibagi 2. Di HP 1080p pembesarannya ×3.

**Yang TIDAK boleh diambil dari mockup:**

- **Latar jalan.** Mock memakai gambar jalan lama 400×180 yang diperbesar ×4, dengan pengendara lama dan rumah yang belum mengikuti aturan ART_DIRECTION. Yang dijadikan acuan hanya HUD.
- **Angka gameplay** (koin, jumlah pelanggan, hadiah). Ambil dari `scripts/config.gd` (`BALANCING.md`). Lihat bagian 6.
- **Teks contoh** ("Cari kucing Mimi", "dari berita hal. 2"). Teks mengikuti `CONTENT_GUIDE.md`.

**Merender ulang papan kontrol** (run fase2b-bantu-audio 2026-10-15, QA-005: `source/kontrol.html` diperbarui ke arah lempar bebas dan mode bantu). PNG dibuat dari HTML dengan Chrome headless dan dipotong dengan Pillow, tanpa diedit tangan. Render lama dibuat tanpa web font (font cadangan sans), jadi render ulang juga memblokir jaringan supaya Lexend/Lilita tidak termuat dan tampilannya setara (render HTML lama dengan perintah ini berbeda di sekitar 1% piksel area gambar dari `kontrol.png` lama (11.702 dari 1.153.600 piksel dengan selisih kanal > 16), hanya antialias teks):

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless --disable-gpu --hide-scrollbars \
  --force-device-scale-factor=1 --host-resolver-rules="MAP * ~NOTFOUND" --window-size=1728,1560 \
  --virtual-time-budget=8000 --user-data-dir=build/chrome --screenshot=build/kontrol-board.png \
  "file://$PWD/docs/design/source/kontrol.html"
python3 -c "from PIL import Image; p=Image.open('build/kontrol-board.png').convert('RGB'); p.save('docs/design/screens/kontrol-board.png', optimize=True); p.crop((64, 279, 1664, 1000)).save('docs/design/screens/kontrol.png', optimize=True)"
```

`kontrol.png` (1600×721) adalah potongan papan 1728×1560 di (64, 279), sama dengan berkas lama; potongan itu bergeser bila tinggi judul papan berubah. `hud-rute.html` belum dirender ulang.

---

## 1. Token

### 1.1 Warna

Simpan sebagai konstanta di satu tempat (`scripts/ui/palette.gd`, usulan) atau di Theme. Jangan menulis hex di scene.

| Token | Hex | Pemakaian |
|---|---|---|
| `UI_BG` | `#1C130F` | Latar layar penuh (koran, hasil, bengkel) |
| `UI_PANEL` | `#2A1E17` | Panel dan kartu di layar penuh |
| `UI_PANEL_RAISED` | `#36281E` | Garis dalam panel HUD, isi bar kosong, kotak progres yang belum |
| `HUD_PANEL` | `#0E0A1C` alpha 84% | Latar panel HUD di atas jalan |
| `OUTLINE` | `#0E0A1C` | Garis luar panel, bar, ikon (sama dengan sprite) |
| `TEXT` | `#FFF3E3` | Teks utama, isi bar kecepatan, kotak kondisi penuh |
| `TEXT_2` | `#CDB9A3` | Teks kedua, garis putus-putus |
| `ACCENT` | `#FFB22E` | Label penting, stamina, kotak progres berikutnya, knob stick |
| `OK` | `#56C46E` | Terkirim, tip |
| `FAIL` | `#D94F3D` | Meleset |
| `WARN` | `#FF8A3D` | Batas ngebut, kondisi sepeda perlu ke bengkel |

Radar (bagian 3.4):

| Token | Hex | Arti |
|---|---|---|
| `RADAR_BG` | `#0E0A1C` alpha 60% | Isi strip |
| `RADAR_PELANGGAN` | `#FFC94A` | Pelanggan biasa |
| `RADAR_TIP` | `#56C46E` | Pelanggan pemberi tip |
| `RADAR_MISI` | `#E98E3F` | Target misi |
| `RADAR_BUKAN` | `#969AA0` | Rumah bukan pelanggan (hanya mode bantu, usulan) |

Dunia (usulan, run fase1b-umpan-balik 2026-10-14):

| Token | Hex | Pemakaian |
|---|---|---|
| `BAYANGAN_CONTOH` | `#2E3550` | Warna bayangan contoh (siang, ART_DIRECTION 2.5) untuk shader warna bayangan (ART_DIRECTION 2.1 no. 5, 2.3); sementara hanya dipakai probe render `scenes/dev/cek_render.tscn`. Warna bayangan per distrik dan waktu menggantikannya nanti |

Halaman depan koran (usulan, run fase4a-koran-hari 2026-10-18; satu-satunya layar terang, bagian 4):

| Token | Hex | Pemakaian |
|---|---|---|
| `KORAN_KERTAS` | `#F2E7C9` | Latar halaman depan koran (krem dari sketsa bagian 4) |
| `KORAN_KERTAS_2` | `#E6D8B1` | Panel misi sampingan dan tombol tidak terpilih di atas kertas |
| `KORAN_TINTA` | `#1C130F` | Teks utama, headline, garis dan isi tombol terpilih (kontras 14,8:1 terhadap kertas) |
| `KORAN_TINTA_2` | `#4A3A2C` | Teks kedua: label, ringkasan, status (kontras 8,8:1 terhadap kertas, 7,7:1 terhadap kertas kedua) |
| `KORAN_GARIS` | `#7A6642` | Garis pemisah dan bingkai tombol tidak terpilih (kontras 4,5:1 terhadap kertas; komponen UI, bukan teks) |

Kontras teks terhadap latar di layar koran dijaga paling sedikit 7:1 dan garis komponen paling sedikit 3:1 (rumus WCAG), diuji `tests/tes_halaman_koran.gd`. Token koran bukan dari palet induk (usulan, belum diuji di HP: apakah krem terang menyilaukan setelah layar gelap).

Warna ini sudah ada di palet induk (ART_DIRECTION 2.4), kecuali token UI yang berasal dari Brainy Dungeon, token halaman koran, dan `BAYANGAN_CONTOH` (dari tabel warna bayangan ART_DIRECTION 2.5). **Warna jangan jadi satu-satunya pembeda**: penanda radar dan kotak progres juga dibedakan bentuk atau simbol (bagian 3.2 dan 3.4).

### 1.2 Tipografi

| Peran | Font | Ukuran dasar | Contoh |
|---|---|---|---|
| Judul layar | Lilita One | 16 / 24 | "Bengkel", headline koran (24 = `JudulBesar` untuk nama koran dan berita utama, 16 = `JudulLayar`, run 4A) |
| Angka HUD | Lexend SemiBold | 10 | Koin, sisa koran |
| Teks utama HUD | Lexend SemiBold | 8 | Judul misi |
| Teks kecil | Lexend Regular | 7 | Sub-judul, umpan balik |
| Label | Lexend SemiBold, huruf kapital, spasi 0,1 em | 8 (dulu 6) | "KECEPATAN", "MISI SAMPINGAN" |

Font sama dengan Brainy Dungeon dan **belum dikunci** (ART_DIRECTION 11). **Label 8 px (usulan dari uji A54, paket pemilik 2026-10-14):** ukuran 6 di kanvas dasar (18 px di layar 1080p) dinilai terlalu kecil, jadi `HudLabel` di `assets/ui/theme.tres` menjadi 8 (24 px di layar 1080p), sama dengan teks utama HUD. Panel kecepatan dan stamina ikut meninggi dari 57 menjadi 59 px game (y 293–352; baris pertama sudah setinggi angka 10 px, jadi hanya baris STAMINA yang bertambah) dan tetap di antara zona stick dan tengah layar tanpa menutupi sepeda (`tests/tes_tata_letak.gd`). Cek keterbacaannya di HP sebelum dikunci.

### 1.3 Bentuk

- **Panel HUD**: latar `HUD_PANEL`, garis luar 1 px `OUTLINE`, garis dalam 1 px `UI_PANEL_RAISED`, sudut tumpul 3 px bertingkat. Dibuat sebagai tekstur 9-slice 12×12 px supaya garisnya tetap piksel tajam (bukan StyleBoxFlat dengan radius halus).
- **Bar**: tinggi 7, garis luar 1 px, isi kosong `UI_PANEL_RAISED`.
- **Ikon HUD**: 14×14 px pixel art, garis luar 1 px, palet induk. Ditampilkan dengan skala bulat yang sama dengan dunia. Usulan 2026-10-15: `assets/sprites/ui/ui_icon_<nama>.png` (koin, reputasi, ban, rem, rantai, misi_kucing) dan bingkai panel `ui_panel_hud_9slice.png` (margin 4), dibuat `tools/ui_art/hud_ikon.py`. Ikon koran tetap `IKON_KORAN` di kode, tombol jeda dari kode.
- **Jarak**: tepi layar 8, antar panel 5, padding panel 5×7.

---

## 2. Theme Godot (usulan)

- HUD di `CanvasLayer` terpisah dari dunia, dengan anchor: kiri atas, tengah atas, kanan atas, kiri bawah, tengah bawah. Jangan memakai posisi absolut, karena lebar kanvas berubah 640–800.
- Satu `Theme` (`assets/ui/theme.tres`) berisi font, ukuran, dan panel 9-slice.
- Elemen yang harus terlihat di HP 16:9 diletakkan di area 640×360 tengah (zona aman, ART_DIRECTION 7).
- HUD tidak pernah menutupi jalan di depan sepeda (sepertiga kiri layar ke kanan atas).

---

## 3. HUD saat mengantar — `screens/hud-rute.png`

Informasi diletakkan di tepi layar supaya tengah, tempat jalan dan rumah, tetap bersih. Bagian bawah dekat jempol hanya berisi hal yang dilirik sekilas.

**Diterapkan run 3C (usulan, run `20261018-fase3c-hud-hasil`; `scenes/ui/hud_rute.tscn`, `scripts/ui/hud_rute.gd`, dasar bersama `scripts/ui/hud_dasar.gd`; dinilai di HP):** HUD rute final menggantikan HUD dev skor run 3B di scene rute. Yang dipasang: tombol jeda (3.1), panel progres dengan tenggat (3.2), panel koin dan panel skor/combo di kanan atas (3.3), radar kiri dan kanan (3.4), panel bawah kecepatan/stamina dan koran (3.5, tidak berubah), dan tombol bel (3.8). Belum dipasang: kartu misi (Fase 4), panel reputasi dan kondisi sepeda (Fase 6), label "HARI · distrik" (sistem hari belum ada). Usulan orchestrator yang ikut diterapkan, bisa ditolak di review PR:
- **O-6 Sakelar Kidal dan Bantu pindah ke layar jeda** (layar pengaturan belum ada, bagian 4): strip atas HUD bebas untuk panel progres; tombol dev Kidal, Bantu, dan "Main lagi" dihapus dari scene rute (jalan uji, scene dev, tetap memakai HUD dev).
- **O-7 Skor dan combo di kanan atas**, panel kedua di baris koin (slot reputasi 3.3 yang baru terisi di Fase 6). Label PUTUS run 3B tetap, menggantikan label COMBO di panel yang sama supaya lebar panel tidak melompat.
- **O-8 Tenggat di baris atas panel progres:** kiri "WAKTU 1:31" (sisa, label `TEXT_2` + angka `TEXT`), kanan "3/25 TERKIRIM" (`ACCENT`). Sesudah tenggat lewat: "LEWAT +0:12" dengan label dan angka `WARN` (teksnya berubah, bukan hanya warna).
- **Zona aman:** elemen yang menempel di tepi (radar, tombol jeda, panel kanan atas, panel bawah, bel) bergeser ke dalam sama besar bila inset aman perangkat (`DisplayServer.get_display_safe_area()`, dikonversi ke piksel game, hanya dibaca di perangkat mobile) lebih besar dari margin spec; margin = max(margin spec, inset), satu fungsi murni `ZonaAman` (dites dengan inset tiruan). Zona stick dan swipe tidak digeser.
- Tangkapan resmi 1920×1080, 2340×1080, 2400×1080, 1600×720: `docs/loop/20261018-fase3c-hud-hasil/shots/*_hud_*.png` (`tests/probe_hud_rute_jendela.gd`).

### 3.1 Kiri atas: jeda dan misi

| Elemen | Posisi | Ukuran | Isi |
|---|---|---|---|
| Tombol jeda | x 26, y 8 | 24×24 (gambar); area sentuh 42×42 | Dua batang 3×10 `TEXT`, garis luar panel `TEXT` supaya terlihat sebagai tombol |
| Kartu misi | x 26, y 40 | lebar 145 | Ikon misi 14 px, label "MISI SAMPINGAN" (`ACCENT`), judul misi, progres dan sisa rumah ("Kucing 0/1 · 8 rumah") |

**Area sentuh tombol jeda (usulan, paket pemilik 2026-10-14, run fase1b-umpan-balik):** gambar tetap 24×24 di (26, 8), tetapi area sentuhnya 42×42 px game (≥ 44 dp di A54: 450 dpi ×3, 44 dp ≈ 41,7 px game), x 17–59 (dipusatkan mendatar pada gambar), y 4–46 (sejajar tombol strip atas, berakhir sebelum zona swipe di y 48). Tidak masuk zona stick maupun swipe di 640, 780, dan 800, tidak menumpuk dengan tombol kidal (tengah atas), dan **tidak dicerminkan saat kidal** (strip atas bebas dari kontrol). Gambar dari kode (`scripts/ui/tombol_jeda.gd`), tanpa PNG. Ketukan diterima dari jari mana pun, juga saat jempol lain masih di stick (`TombolSentuh`). Konstanta `HUD_JEDA_*` di `scripts/config.gd`. Kartu misi nanti digeser bila menumpuk dengan area sentuh ini.

Kartu misi hanya muncul kalau misi diambil. Saat misi selesai atau gagal, kartu berganti banner singkat 1,5 detik (`CONTENT_GUIDE.md` 3) lalu hilang.

### 3.2 Tengah atas: progres rute

- Panel lebar 260, di tengah atas (y 8). Baris atas: "HARI 3 · <nama distrik>" di kiri, "3/25 TERKIRIM" di kanan (`ACCENT`).
- Baris bawah: **satu kotak per pelanggan**, urut sesuai rute. Untuk 25 pelanggan: kotak 8×8 dengan jarak 2.

| Status | Isi | Simbol |
|---|---|---|
| Terkirim | `OK` | ✓ |
| Meleset | `FAIL` | × |
| Berikutnya | `ACCENT` | ▶ |
| Belum | `UI_PANEL_RAISED`, garis putus-putus `TEXT_2` | kosong |

Kalau pelanggan lebih dari 25 (distrik lanjutan), kotak diganti bar bersegmen. Diputuskan setelah distrik kedua.

**Diterapkan run 3C (usulan; `scripts/ui/kotak_progres.gd`, status dari `scripts/systems/progres_rute.gd`, O-12):** isi samping panel 6 px (bukan 7) supaya 25 × 8 + 24 × 2 = 248 px muat di lebar 260 (`HUD_PROGRES_*` di `scripts/config.gd`). Status kotak dari logika murni: **terkirim** = pelanggan terantar (centang garis luar di `OK`); **terlewat** (baris "Meleset" di tabel) = pelanggan belum terantar yang kotak suratnya sudah lebih dari 3,0 ubin (`HUD_PROGRES_TERLEWAT_UBIN`) di belakang sepeda, atau semua yang belum terantar sesudah garis akhir (silang `TEXT` di `FAIL`); **berikutnya** = pelanggan belum terantar terdekat di depan (segitiga garis luar di `ACCENT`); **belum** = kosong bergaris putus-putus `TEXT_2` di `UI_PANEL_RAISED`. Pelanggan yang baru dilewati kurang dari 3 ubin tetap "belum" karena masih bisa dikenai lemparan ke belakang. Simbol berbeda bentuk, jadi status terbaca tanpa warna.

### 3.3 Kanan atas: koin, reputasi, kondisi sepeda

- Baris 1 (kanan 28, y 8): panel koin (ikon 14 + angka, pemisah ribuan titik: "1.250") dan panel reputasi (ikon bintang + angka).
- Baris 2 (jarak 5 di bawahnya): satu panel berisi **ban, rem, rantai**. Tiap komponen: ikon 14 px + tiga kotak 5×5.

| Kondisi | Kotak |
|---|---|
| Baik | Tiga kotak `TEXT` |
| Aus | Kotak yang tersisa tetap `TEXT`, yang hilang `UI_PANEL_RAISED` |
| Perlu ke bengkel | Kotak tersisa `WARN`, ditambah "!" `WARN` |

Kotak berkurang saat aus atau kena kejadian di rute (GDD 12). Tanda "!" berarti perlu diperbaiki di bengkel setelah pengantaran; efeknya hanya menghambat.

**Diterapkan run 3C (usulan, O-7):** baris 1 = [panel koin][panel skor/combo], tepi kanan 28, y 8, panel 9-slice `ui_panel_hud_9slice.png` (1.3). Koin: ikon `ui_icon_koin` 14 + angka dengan pemisah ribuan dari kunci `HUD_PEMISAH_RIBUAN` ("1.250"). Skor/combo: dua baris `HUD_SKOR` + angka (pemisah ribuan) dan `HUD_COMBO` + pengali; saat combo putus `HUD_COMBO_PUTUS` (`FAIL`) menggantikan label COMBO. Tidak dicerminkan saat kidal. Baris 2 (kondisi sepeda) dan panel reputasi belum ada (Fase 6).

### 3.4 Radar di tepi

GDD 4.3. Strip tipis di tepi kiri dan kanan, di separuh atas layar supaya tidak tertutup jempol.

- **Strip kiri = sisi seberang, strip kanan = sisi dekat**, sama dengan arah stick; lemparan bebas ke kiri atau ke atas juga mengarah ke seberang (GDD 5.2).
- Ukuran: lebar 12 (garis luar 1 px, isi 8 px `RADAR_BG`), dari y 10 sampai y 182. Kiri di x 4, kanan 4 px dari tepi kanan.
- **Atas strip = jauh di depan, bawah = dekat sepeda.** Penanda bergerak turun saat rumah mendekat.
- Penanda: 8×6 px dengan garis luar. Pelanggan biasa kotak kuning, tip kotak hijau dengan titik terang di tengah, misi bentuk belah ketupat oranye. Rumah bukan pelanggan (abu-abu) hanya tampil di mode bantu.
- **Masuk jangkauan lempar**: penanda mendapat garis luar `TEXT` dan membesar 2 px, warna jenis tetap supaya pemain tetap tahu jenisnya (tafsiran "berubah warna" di GDD 4.3, usulan).
- Panjang jangkauan radar adalah upgrade (GDD 4.3); angka awal ditaruh di `scripts/config.gd`.
- **Diterapkan run 3C (usulan; `scripts/ui/radar_strip.gd`, penanda dari `scripts/systems/radar_rute.gd`; K-2 dan O-9, O-10):** jangkauan bawaan 30 ubin ke depan (`RADAR_JANGKAUAN_UBIN`, keputusan pemilik 2026-10-17, kelak upgrade). Jarak rumah = jarak maju sepeda ke pusat zona kotak surat; tampil bila 0 ≤ jarak ≤ 30 (kedua tepi inklusif); posisi tegak = 1 − jarak/30 (atas = jauh). Rumah yang sudah terantar keluar dari radar. Pemberi tip ditandai penanda tip (O-9, membatalkan "pemberi tip tidak ditandai" run 3B); sesudah tenggat lewat pemberi tip tampil sebagai pelanggan biasa (tip sudah tidak ada). **Jangkau** (O-10) = rumah pelanggan dengan jarak ≤ jarak lempar terjauh (5,0 ubin, dari `ThrowSolver`), rumah bukan pelanggan tidak pernah jangkau. **Mode bantu:** rumah bukan pelanggan di jangkauan tampil sebagai penanda `RADAR_BUKAN` berlubang (GDD 5.3); sakelar diubah di tengah rute langsung berlaku. Strip mengikuti sisi dunia: kidal **tidak** menukar strip. Penanda misi belum dipakai (misi Fase 4). Strip tidak menerima sentuhan; posisinya ikut inset zona aman.
- **Aset (usulan, 2026-10-15, `tools/ui_art/hud_ikon.py`):** `assets/sprites/ui/ui_radar_<pelanggan|tip|misi|bukan>.png` (8×6) dan `ui_radar_<jenis>_jangkau.png` (10×8), bingkai strip `ui_radar_strip_9slice.png` (margin 2). Penanda bukan pelanggan digambar kotak abu-abu **berlubang** supaya bentuknya juga beda dari pelanggan (tafsiran, usulan). Contoh di layar: `design/hud/radar_contoh.png`.

### 3.5 Bawah: kecepatan, stamina, koran

| Elemen | Posisi | Isi |
|---|---|---|
| Kecepatan dan stamina | x 210, bawah 8, lebar 170 | Dua bar dengan label. Kecepatan: isi `TEXT`, garis tegak `WARN` di 80% menandai batas ngebut (sama dengan ambang sprite di BALANCING 2). Stamina: isi `ACCENT`, berubah `FAIL` di bawah 30 (usulan) |
| Sisa koran | x 400, bawah 8 | Label "KORAN", deret ikon koran 12 px (maksimal 8, yang terpakai redup 28%), lalu angka sisa |

Panel bawah diletakkan di antara zona stick dan tengah layar, jadi tidak tertutup jempol kiri dan tidak menutupi jalan di depan sepeda.

**Tafsiran HUD sementara sisa koran (usulan, run fase2a-lemparan 2026-10-14; `scripts/ui/hud_dev.gd`, `deret_koran.gd`):** panel koran satu baris dengan panel kecepatan (`BarisBawah`), celah 20 px sehingga mulai di x 400 (`HUD_PANEL_KORAN_GESER_PX`); baris atas label `HUD_KORAN` ("KORAN", `ACCENT`) dan angka sisa (`HUD_KORAN_ANGKA`, `TEXT`), baris bawah 8 ikon koran 12×12 dari kode berjarak 1 px (panel sekitar 117×39, berakhir di x sekitar 517). Delapan ikon dibaca sebagai **delapan koran terakhir**: selama sisa ≥ 8 semua ikon terang dan angkanya yang menunjukkan jumlah; di bawah 8 satu ikon redup (alpha 28%) per koran terpakai (`SisaKoran.ikon_hud`). Saat habis tampil label `HUD_KORAN_HABIS` ("HABIS", `FAIL`) di samping angka 0 dan semua ikon redup, jadi habis terbaca tanpa warna. Kidal: baris dicerminkan (panel kecepatan 210 dari tepi kanan, panel koran 400 dari tepi kanan). Panel di dalam zona swipe dan tidak menerima sentuhan (swipe yang dimulai di atasnya tetap melempar). Cek keterbacaan di HP sebelum dikunci.

### 3.6 Umpan balik melayang

- Muncul di atas rumah sasaran saat koran mendarat: panel kecil berisi ikon koin, angka, dan alasan ("+15 · teras tepat", "pelanggan puas").
- Naik 12 px dan memudar dalam 0,8 detik (usulan). Maksimal dua sekaligus; yang lama hilang lebih dulu.
- Meleset tidak memunculkan panel merah besar; cukup ikon × kecil di tempat koran jatuh, supaya gagal tidak terasa menghukum.
- **Penanda sementara Fase 2 (usulan, run fase2a-lemparan 2026-10-14; `scripts/entities/koran_gambar.gd`, `scripts/systems/pola_piksel.gd`):** belum ada panel koin (skor Fase 3), jadi yang tampil hanya penanda bentuk piksel dari kode 7 px di atas titik mendarat selama 0,8 detik (`PENANDA_LAMA_DETIK`), di atas koran yang tergeletak: centang 9×7 `OK` (kotak surat, teras), belah ketupat terisi separuh `OK` (halaman, sah setengah), bintang 9×9 `OK` (jendela bila sakelar bonus), silang kecil 7×7 `FAIL` (meleset, sisi salah, rumah bukan pelanggan, jendela dengan sakelar bawaan penalti ringan). Semua bergaris luar `OUTLINE`; bentuk yang membedakan, bukan hanya warna. Tidak naik atau memudar (penyederhanaan placeholder).
- **Penanda dan umpan balik run 3B (usulan, run `20261017-fase3b-rintangan-skor` 2026-10-16; `scripts/systems/pola_piksel.gd`, `scripts/systems/umpan_melayang.gd`, `scripts/entities/umpan_melayang_gambar.gd`):** di scene rute penanda koran dipilih skor (`SkorRute`): antaran **tepat** (inti 0,5 × 0,5 kotak surat, K-4) = **sasaran berlapis 9×9** (cincin dengan titik pusat) `OK`, bentuk berbeda dari centang, bintang, dan tanda "tidak ada sasaran" mode bantu (cincin kosong); koran ke rumah yang **sudah terantar** (O-1) = **garis datar 7×4 `TEXT_2`** (netral, bukan sah dan bukan gagal); lemparan mode bantu tidak pernah tepat (O-4), jadi tetap centang. **Umpan balik melayang versi minimal:** teks (bukan panel) di atas titik mendarat, kaki teks 18 px di atasnya, naik 12 px dan memudar dalam 0,8 detik, paling banyak dua sekaligus (yang lama hilang lebih dulu); isi satu baris per bagian: `RUTE_UMPAN_KOIN` "+15", `RUTE_UMPAN_TIP` "tip +5" bila ada, `RUTE_UMPAN_TEPAT` "TEPAT" bila tepat; font HUD 8 px `OK` bergaris luar `OUTLINE` 2 px. Hanya antaran sah pertama yang memunculkannya (netral dan meleset tidak). Jalan uji (scene dev) tidak menilai skor, jadi penandanya tetap seperti Fase 2.
- **HUD dev skor sementara (usulan run 3B; sejak run 3C hanya di jalan uji, scene dev: di scene rute digantikan panel koin dan skor/combo HUD final, 3.3 dan O-7; `scripts/ui/hud_dev.gd`):** panel di strip atas sisi swipe, 112 px dari tepi (tempat tombol dev "Main lagi" 96 px di sisi itu tetap bebas), y 4, lebar minimum 72, tiga baris `HudLabel` 8 px: `HUD_SKOR` "SKOR" + angka, `HUD_COMBO` "COMBO" + pengali untuk antaran berikutnya (`HUD_COMBO_ANGKA` "x1.3"), `HUD_KOIN` "KOIN" + angka; label `ACCENT`, angka `TEXT`, panel `HUD_PANEL` bergaris `OUTLINE`. Saat combo putus (tabrakan atau antaran tidak sah) label `HUD_COMBO_PUTUS` "PUTUS" `FAIL` tampil 0,8 detik di samping pengali yang kembali x1.0 (penanda teks, bukan hanya warna). Kidal: panel dicerminkan ke 112 px dari tepi kiri. Tidak menerima sentuhan. Hanya tampil di scene rute.
- **Tabrakan = jatuh (keputusan pemilik 2026-10-17, menggantikan oleng AC-8 run 3B):** sprite pemain memutar `jatuh_normal` (4 frame, 10 fps, sekali) lalu `terjerembab_normal` (2 frame, 3 fps, berulang) selama jatuh 1,2 detik, ikon kilatan 9×9 `WARN` 50 px di atas titik pijak selama jatuh, lalu bangun langsung ke animasi kayuh dan berkedip (alpha 0,5 tiap fase 0,1 detik) selama kebal 1,0 detik sejak bangun; bersama bunyi tabrakan dan label PUTUS. Selama jatuh garis bidik tidak tampil dan lemparan ditolak. Semua arah memakai gambar arah `normal` (arah lain dan animasi bangkit: aset Fase 5).

### 3.7 Kontrol — `screens/kontrol.png`

GDD 5.2.

| Elemen | Ukuran | Perilaku |
|---|---|---|
| Zona stick | x 8–192, y 186–352 | Stick muncul di tempat jempol menyentuh, hilang saat dilepas |
| Stick | cincin radius 35 (isi `TEXT` 14%, garis 2 px `TEXT` 70%), knob radius 15 `ACCENT` | Empat panah kecil di dalam cincin. Saat rem aktif (BALANCING 2), cincin bawah menyala `WARN` |
| Zona swipe | x 210 sampai tepi kanan −20, y 48–352 | Swipe di mana saja, kecuali sentuhan yang dimulai di zona tap bel (bagian 3.8). Garis bidik muncul selama jari ditahan |
| Garis bidik | titik 2 px tiap 4 px, `TEXT` | Berakhir di elips pendaratan 10×5 px yang sudah memperhitungkan kecepatan sepeda (BALANCING 4). Elips berubah `OK` kalau mengarah ke sasaran sah |

Opsi kidal menukar zona kiri dan kanan beserta panel bawah dan tombol bel. Mode bantu memakai tap di zona swipe untuk lempar otomatis; stick tetap tampil dan aktif (GDD 5.3, usulan 2026-10-15: kecepatan otomatis = santai tanpa sentuhan stick).

**Mode bantu di HUD sementara (usulan, run fase2b-bantu-audio 2026-10-15; `scripts/ui/hud_dev.gd`, `scripts/ui/kontrol_touch.gd`; GDD 5.3, BALANCING 4b):**
- **Tombol mode bantu** (sakelar, sampai layar pengaturan ada): di strip atas, satu baris dengan tombol kidal di tengah (`BarisTombol`, kidal lalu bantu, jarak 8 px `HUD_TOMBOL_JARAK_PX`), ukuran minimum sama dengan tombol kidal 96×42 px game, y 4–46, jadi di luar zona stick dan swipe (tangan kanan maupun kidal) di 640, 780, dan 800 dan tidak menumpuk dengan tombol jeda, tombol kidal, atau panel bawah. Tidak dicerminkan saat kidal. Gaya sama dengan tombol kidal (ditekan = `UI_PANEL_RAISED` bergaris `ACCENT`), dan statusnya juga terbaca dari teks: `HUD_BANTU_MATI` "Bantu: mati" / `HUD_BANTU_NYALA` "Bantu: nyala" (bukan hanya warna). Bawaan mati, tidak disimpan (belum ada save). Mudah dijangkau tapi tidak terpencet tak sengaja dinilai di HP.
- **Lemparan bantu** tidak menampilkan garis bidik (tap seketika); koran, bayangan, elips pendaratan, dan penanda kena tampil seperti lemparan swipe.
- **Tanda "tidak ada sasaran"** saat tap mode bantu tidak menemukan kotak surat terjangkau: cincin kecil 9×9 px game (`PolaPiksel.TANDA_TANPA_SASARAN`) isi `TEXT_2` bergaris luar `OUTLINE` di dalam dan di luar, berpusat di titik tap, selama 0,6 detik (`BANTU_TANDA_LAMA_DETIK`, membeku saat jeda). Bentuknya berbeda dari silang meleset (3.6) dan dari elips pendaratan; bukan teks dan bukan warna saja. Tap yang ditolak karena koran habis atau jeda antar lempar tidak memberi tanda (HUD koran sudah menampilkan HABIS).

**Tafsiran garis bidik (usulan, run fase2a-lemparan 2026-10-14; `scripts/ui/garis_bidik.gd`):** garis bidik digambar di **ruang dunia** (ikut kamera, di atas rumah dan sepeda), bukan dari titik awal swipe ke jari: titik 2×2 `TEXT` tiap 4 px sepanjang lengkung koran yang sebenarnya, mulai dari titik lepas setinggi tangan (sudah termasuk gerak sepeda selama jeda lepas, jadi saat ngebut garis mulai sedikit di depan pengendara) sampai elips pendaratan di tanah. Titiknya sampel lintasan `ThrowSolver` yang sama dengan lemparan, diperbarui tiap frame dari kecepatan sebenarnya. Elips biasa = cincin 10×5 `TEXT`; elips ke sasaran sah = elips **terisi** `OK` bergaris luar `OUTLINE` (berubah bentuk, bukan hanya warna). Titik mendarat yang **tertutup rumah** dari sudut kamera (di dalam kotak rumah atau di baliknya; koran pasti meleset di sana) = cincin **putus-putus** `TEXT` redup alpha 0,5, dan titik garis bidik yang tertutup rumah ikut redup, supaya ujung garis di belakang fasad tidak terbaca sebagai sasaran di atap atau dinding (garis bidik tetap digambar di atas objek; redup = "di balik rumah"; QA-004 run fase2a-lemparan iterasi 2, usulan). Aturannya murni (`ZonaSasaran.tertutup_kotak`): titik (x, y, z) tertutup bila ada d ≥ 0 dengan (x + d, y + d) di tapak kotak dan z + d ≤ tinggi kotak, karena keduanya jatuh di titik layar yang sama dan yang kedua lebih dekat ke kamera. **Arah bebas (usulan rinci, keputusan pemilik 2026-10-15, run fase2-arah-bebas):** koran terbang ke arah swipe seperti terlihat di layar, jadi garis tanah lemparan (dari titik lepas ke elips, tanpa tinggi) sejajar arah jari: swipe ke atas = garis ke rumah seberang di depan, ke kanan = ke sisi dekat, ke kiri murni = ke seberang sedikit ke belakang, ke bawah = ke sisi dekat di belakang. Saat sepeda melaju, elips bergeser maju searah jalan karena koran mewarisi kecepatan maju, dan lengkungnya naik setinggi puncak, jadi garis yang terlihat tidak lurus sejajar jari; yang sejajar adalah arah tanahnya (dites; tangkapan `docs/loop/20261015-fase2-arah-bebas/shots/*sejajar_berhenti*` saat sepeda berhenti). Tidak ada sudut swipe yang ditolak. Garis bidik hanya tampil selama jari ditahan, panjang swipe \|v\| ≥ 6% lebar viewport (ke arah mana pun), koran masih ada, dan jeda antar lempar 0,35 detik sudah lewat; hilang saat jari dilepas, dibatalkan, atau jeda. Saat jari dilepas, koran memakai lintasan garis bidik yang terakhir tampil: jari yang masih bergerak atau berbelok ke arah mana pun saat diangkat tidak membatalkan lemparan dan tidak menggeser titik mendarat dari elips yang terlihat; hanya jari yang ditarik kembali ke dekat titik awal (\|v\| di bawah 6%) yang membatalkan (QA-001 run fase2a-lemparan, D-5 run fase2-arah-bebas). Elips sah mengikuti zona yang memuat titik mendarat, apa pun sisi lemparannya. Garis putus lama dari titik awal swipe ke jari dihapus. Kekuatan titik di bawah jempol dinilai di HP.

### 3.8 Tombol bel dan efek "kring" (usulan, 2026-10-09)

GDD 5.4. Aset di `design/bel/`, render penempatan di `design/bel/preview/penempatan_hud.png` dan `penempatan_kontrol.png` (render 2026-10-09: tombol masih di posisi pojok lama, lihat "Posisi bel digeser ke dalam" di bawah).

| Elemen | Ukuran / posisi | Perilaku |
|---|---|---|
| Tombol bel | 40×40, pusat di (lebar −64, 296), kanan bawah agak ke dalam dari pojok. Kidal: pusat di (64, 296) (usulan 2026-10-17, dulu (lebar −28, 332) / (28, 332)) | Lingkaran: garis luar 1 px `OUTLINE`, cincin 1 px `TEXT` (seperti tombol jeda, supaya terbaca sebagai tombol), garis dalam `UI_PANEL_RAISED`, isi `HUD_PANEL`. Ikon bel kuning 20×19 |
| Zona tap bel | lingkaran radius 28 dari pusat tombol | Sentuhan yang **dimulai** di sini membunyikan bel; swipe yang hanya melewati tombol tetap swipe |
| Ditekan | | Cincin `ACCENT`, ikon turun 1 px, garis getar kecil di kiri-kanan ikon |
| Jeda | | Setelah "kring kring!" (GDD 5.4): ikon redup 45%, cincin `ACCENT` berkurang searah jarum jam selama jeda |
| Efek "kring" | di titik bel sprite pemain | Garis getar 4 frame (12 fps) + teks "KRING!" yang naik 1 px per frame; ketukan kedua mengganti teks jadi "KRING KRING!". Selalu tampil, juga saat suara mati |
| Ikon "!" | 11×13, 2 px di atas kepala | Muncul di atas warga atau hewan yang bereaksi, sekitar 0,5 detik, lalu mereka menepi |

**Diterapkan run 3B (usulan, `20261017-fase3b-rintangan-skor`; `scripts/ui/tombol_bel.gd`, `scripts/systems/touch_zones.gd`, `touch_router.gd`, `scripts/entities/efek_sepeda.gd`):**
- Tombol = sheet `assets/sprites/ui/ui_bel_tombol.png` dari `tools/ui_art/bel.py --salin`: diam, ditekan (selama jari bel menempel), lalu 8 frame jeda dengan cincin `ACCENT` 8/8 sampai 1/8 (cincin berkurang selama jeda 1,0 detik). Di kontainer `StripBel` (lebar penuh di tepi bawah); margin diatur kode dari konstanta, jadi pusatnya sama dengan pusat zona tap (posisi sekarang: lihat paragraf berikut). Tidak menerima sentuhan sebagai `Button`: zona tap dibaca `TouchRouter` (lingkaran radius 28 inklusif, diperiksa sebelum zona swipe), jadi hanya sentuhan yang turun di zona itu yang membunyikan bel; jari bel dilacak `index`-nya dan tidak pernah menjadi stick, swipe, garis bidik, atau tap mode bantu walau digeser. Swipe yang dimulai di luar lalu melewati atau berakhir di tombol tetap melempar. Saat jeda game tombol tidak bisa membunyikan bel. (Run 3B: pojok bawah sisi luar zona swipe termasuk zona bel; sejak 2026-10-17 pojok itu kembali zona swipe biasa.)
- Efek: garis getar `ui_bel_getar.png` (4 frame, 12 fps, di bawah sprite pemain) dan teks `RUTE_KRING` "KRING!" / `RUTE_KRING_KRING` "KRING KRING!" (kunci terjemahan dengan font HUD 8 px `ACCENT` bergaris luar `OUTLINE`, **bukan** `teks_kring*.png`, karena teks pemain tidak boleh di gambar), pojok kiri bawah teks 11 px kanan dan 12 px atas titik bel, naik 1 px per frame sampai 4 px, redup (alpha 0,6) pada frame terakhir. Titik bel = satu titik tetap (8, −29) dari titik pijak pemain (dari `santai_normal` di `bell_anchors.json`), bukan per animasi; efek tidak dicerminkan untuk arah 90° kiri (usulan, dinilai di HP).
- Ikon "!" (`ui_ikon_seru.png`) 28 px di atas titik pijak anjing yang bereaksi selama kaget 0,5 detik; anjing berdiri (`berhenti`) saat kaget, lalu lari mundur (sprite dicermin).

**Posisi bel digeser ke dalam (usulan, masukan uji pemilik 2026-10-17, review PR #33):** di posisi run 3B (pusat 28 px game dari tepi samping dan bawah) tombol terlalu di pojok sehingga jempol harus menekuk; kidal sama. Pusat kini **64 px game dari tepi layar sisi swipe** (`BEL_TOMBOL_PUSAT_SAMPING_PX`) dan **64 px game dari tepi bawah** (`BEL_TOMBOL_PUSAT_BAWAH_PX`): (lebar −64, 296), kidal (64, 296), jadi (576, 296) / (716, 296) / (736, 296) di lebar 640 / 780 / 800. Sekitar 1,2 cm dari tepi di vivo V2108 (64 px game = 192 px layar pada ×3). Kidal hanya dicerminkan mendatar (y tetap 296). Ukuran tombol 40×40 dan zona tap radius 28 tidak berubah; tombol di (lebar −84, 276), kidal (44, 276). Dua konstanta terpisah supaya jarak samping dan bawah bisa disetel sendiri-sendiri sesudah uji HP; `TouchZones.pusat_bel` dan margin `StripBel` di `HudDasar` membaca keduanya (scene `.tscn` tidak menulis margin). Zona tap (kotak luar x lebar −92 sampai lebar −36, y 268–324) di dalam zona swipe sisi lempar (x 210 sampai lebar −20, y 48–352), di luar zona stick, di bawah strip radar (y 10–182), dan tidak menumpuk dengan panel bawah (panel koran berakhir di x sekitar 517, jadi celah 31 px di lebar 640; kidal dicerminkan), tombol jeda, atau panel atas. Inset zona aman tetap menggeser tombol dan zona tap bersama (`geser_bel`, QA-002 run 3C). Sentuhan di posisi pojok lama sekarang swipe atau tap biasa. Dijaga `tests/tes_tata_letak.gd` (`_test_bel_dijangkau`, lebar 640, 780, 800, kanan dan kidal, dengan dan tanpa inset tiruan; sentuhan sungguhan). Ukuran 40 piksel dasar menjadi 120 px di layar 1080p; jangkauan jempol tanpa menekuk dinilai di HP (`SETUP_ANDROID.md` 8.8 butir 17).

---

## 4. Layar yang belum didesain

Status: ⬜ belum · 🟡 sketsa · ✅ disetujui

| Layar | Dibutuhkan di | Status | Yang harus ada |
|---|---|---|---|
| Halaman depan koran | Fase 4 | 🟡 | Nama koran dan hari, tiga headline (berita utama dengan ikon efek, misi sampingan dengan ringkasan satu baris dan tombol Ambil/Lewati, berita ringan), tombol Berangkat. Terbaca dalam 10 detik (GDD 10.1, `CONTENT_GUIDE.md` 2). **Sketsa run 4A (usulan, `scenes/koran/halaman_koran.tscn`, `scripts/ui/halaman_koran.gd`; tangkapan `docs/loop/20261018-fase4a-koran-hari/shots/iter1/*_koran_*.png`):** satu-satunya layar terang, latar `KORAN_KERTAS` (krem `#F2E7C9`), teks `KORAN_TINTA`/`KORAN_TINTA_2` (token bagian 1.1, kontras >= 7:1). Dua kolom di dalam zona aman (margin 12 px game atau inset perangkat). Kiri: "Warta Kring" (Lilita One 24), "Hari N · Perumahan Melati" (placeholder usulan), garis, label BERITA UTAMA dan headline (Lilita One 24, paling menonjol), garis, label BERITA RINGAN dan headline (Lilita One 16), baris notifikasi save rusak bila ada. Kanan: panel misi sampingan (`KORAN_KERTAS_2`, bingkai `KORAN_GARIS`): label MISI SAMPINGAN, headline (Lilita One 16), ringkasan satu baris (Lexend 8), tombol Ambil dan Lewati (96×42 px game) dan satu baris status; tombol Berangkat (136×42, terisi gelap) di kanan bawah di zona jempol kanan; tidak ada tombol jeda. Ambil/Lewati: awalnya belum dipilih (sama dengan Lewati), bisa dibolak-balik; pilihan terbaca dari teks status ("Misi diambil", "Misi dilewati", "Belum dipilih; berangkat = dilewati") dan bentuk (terpilih terisi gelap dengan bingkai 3 px, lainnya garis tipis 1 px), bukan warna saja. Tanpa misi memenuhi syarat: tombol Ambil/Lewati hilang dan baris misi berisi "Tidak ada misi sampingan hari ini". Ikon efek berita utama belum ada (aset 4B/Fase 5), efek hanya dicatat. Belum diuji di HP (`SETUP_ANDROID.md` 8.9) |
| Hasil harian | Fase 3–4 | 🟡 | Terkirim, meleset, tip, koin hari itu, perubahan reputasi, hasil misi dan efeknya ke pelanggan, pelanggan baru atau berhenti, milestone yang hampir tercapai, tombol iklan hadiah opsional (GDD 3.1, 13, 14.2). **Sketsa run 3C (usulan, O-11, O-12; `scenes/ui/layar_hasil.tscn`, `scripts/ui/layar_hasil.gd`, angka dari `scripts/systems/hasil_rute.gd`):** layar penuh `UI_BG`, panel `UI_PANEL` lebar 300, judul Lilita One `HASIL_JUDUL` "Hasil antaran", lalu dari yang berhasil: Terkirim "n/25", Tip "+koin dari n pelanggan", Koin, Skor (pemisah ribuan), Tepat (angka `ACCENT`), lalu Meleset dan status tenggat dengan nada netral `TEXT_2` ("Sampai sebelum tenggat" / "Lewat tenggat +m:ss; tip sesudahnya tidak ada"), tanpa merah besar dan tanpa kata "gagal" (prinsip 2), dan tombol "Main lagi" (≥ 42 px game, seed + 1; **di alur hari sejak run 4A tombolnya "Hari berikutnya" (`HASIL_HARI_BERIKUTNYA`) yang menyimpan hari itu; "Main lagi" hanya di rute yang dijalankan sendiri dan banner galat muat**). Muncul sesudah garis akhir saat sepeda berhenti dan tidak ada koran terbang; HUD dan kontrol sentuh tidak menerima sentuhan di bawahnya; back Android di layar ini diabaikan (menu belum ada). Reputasi, misi, pelanggan baru, milestone, dan iklan belum ada (Fase 4, 6, 14). Tangkapan `docs/loop/20261018-fase3c-hud-hasil/shots/*_hud_hasil_*.png` |
| Bengkel | Fase 6 | ⬜ | Kondisi tiap komponen, harga servis, upgrade, milestone target aktif, tombol iklan hadiah opsional (GDD 12.3, 13) |
| Jeda | Fase 1 | 🟡 | Lanjut, pengaturan, keluar ke menu. Game benar-benar berhenti. **Versi sementara (usulan, run fase1b-umpan-balik 2026-10-14):** `scenes/ui/layar_jeda.tscn`, lapisan gelap `HUD_PANEL` penuh layar di atas jalan dan HUD, judul "JEDA" (`JudulLayar`, `TEXT`), tombol "Lanjut" (tinggi 42 px game, gaya tombol HUD). Dibuka oleh tombol jeda, app ke background atau kehilangan fokus, dan back Android; ditutup hanya oleh "Lanjut" atau back (tanpa lanjut otomatis). Pengaturan dan keluar ke menu belum ada. **Run 3C (usulan, O-6):** sakelar `Kidal: mati/nyala` dan `Bantu: mati/nyala` (96×42 px game, satu ketukan membalik, status dari teks dan bingkai `ACCENT`) di bawah "Lanjut", sampai layar pengaturan ada |
| Pengaturan | Fase 3 | ⬜ | Opsi kidal, mode bantu, volume suasana dan efek suara (`SOUND_DESIGN.md` 6), getar |
| Peta distrik | M3 | ⬜ | Tergantung keputusan distrik bebas dipilih atau berurutan (GDD 9.5) |

Layar penuh memakai latar `UI_BG` dan panel `UI_PANEL` seperti papan mock, dengan judul Lilita One. Layar koran sebaiknya terasa seperti kertas koran (krem `#F2E7C9`, teks gelap), satu-satunya layar terang, supaya membaca headline jadi momen sendiri (usulan).

---

## 5. Teks UI

- Semua teks UI ditulis di satu file (`translations/ui.csv`, dikunci user 2026-10-09), bukan di scene, walaupun saat ini hanya Bahasa Indonesia. Scene boleh memuat kunci (mis. `HUD_KECEPATAN`) di properti teks, tidak pernah kalimat jadi.
- Label HUD huruf kapital pendek: "MISI SAMPINGAN", "TERKIRIM", "KECEPATAN", "STAMINA", "KORAN".
- Tombol kata kerja satu kata: "Ambil", "Lewati", "Berangkat", "Lanjut", "Servis".
- Aturan panjang teks misi dan headline: `CONTENT_GUIDE.md` 2–3.

---

## 6. Nilai di mockup yang harus dicek sebelum dipakai

| Di mock | Masalah | Pakai |
|---|---|---|
| "3 / 9 TERKIRIM", 9 kotak | Rute awal 25 pelanggan (BALANCING 6) | 25 kotak 8×8 (bagian 3.2) |
| Reputasi "3,5" | GDD 10.5 menambah reputasi dalam bilangan bulat per distrik | Putuskan: tampil sebagai bintang 0–5 atau angka bulat |
| "+25" pelanggan puas | Ongkos antar 15 koin, tip 5 (BALANCING 7) | Angka dari config |
| "Cari kucing Mimi", "dari berita hal. 2" | Misi P1 "Kucing Bu Ratmi"; koran hanya satu halaman depan (GDD 10.1) | Teks dari data misi |
| "HARI 3 · MELATI" | Nama perumahan: placeholder "Perumahan Melati" (usulan, `CONTENT_GUIDE.md` 8) | "Hari N · Perumahan Melati" di layar koran |
| Koin "1.250" | Patokan 300–375 koin per hari (GDD 14.1) | Angka dari save |
| Garis luar panel 3 px, radius 8 di mock ×2 | Di kanvas dasar menjadi 1,5 px | Panel 9-slice 1 px (bagian 1.3) |

---

## 7. Kaitan dengan dokumen lain

| Dokumen | Bagian |
|---|---|
| `GDD.md` | 4.3 radar, 5.2 kontrol, 10.3 HUD misi, 12.4 kondisi sepeda, 13 milestone, 14.2 iklan |
| `ART_DIRECTION.md` | 2.4 palet induk, 6.8 daftar aset HUD dan UI, 7 resolusi dan skala |
| `BALANCING.md` | 2 ambang ngebut dan rem, 4 lemparan, 7 ekonomi |
| `CONTENT_GUIDE.md` | Panjang headline, ringkasan, label HUD, banner |
| `SOUND_DESIGN.md` | Pasangan visual untuk setiap isyarat suara |
