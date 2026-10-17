# env_art — renderer mock lingkungan

Renderer untuk mock lingkungan Loper Koran: rumah, jalan, kendaraan, pohon, hewan, dan properti dirender dari bentuk sederhana dengan proyeksi isometrik 2:1, arah cahaya, tiga nada, dan garis luar `#0E0A1C` yang sama dengan `tools/loper_art`. Sprite pemain diambil langsung dari `docs/design/character/loper_agen/loper_agen.png`. Hasilnya **usulan** (`docs/ART_DIRECTION.md` bagian 2.6), bukan aset produksi.

## Menjalankan

```
pip install numpy pillow
cd tools/env_art
python3 perumahan.py pagi siang sore malam hitam   # jalan perumahan, empat waktu + versi bayangan hitam
python3 kampung.py sore                            # gang perkampungan, satu frame
python3 anim_hero.py                               # gang perkampungan sore, loop 8 frame (WebP)
python3 districts.py                               # enam vinyet distrik, atau sebut namanya: ruko pasar ...
python3 details.py                                 # loop jemuran, ayam, asap warung + strip frame
```

Ubin dan kotak graybox untuk project Godot (Fase 0) dibuat oleh `graybox.py`, yang hanya memakai pustaka standar Python (tanpa numpy dan pillow) dan menulis langsung ke `assets/sprites/_placeholder/`:

```
python3 tools/env_art/graybox.py                   # dari root repo; hasil deterministik
```

Aset Fase 3 perumahan (usulan) dibuat oleh `fase3.py`, juga dari root repo. Tanpa argumen hasilnya ke `build/env_art/fase3/`; dengan `--salin` sprite 1× beserta JSON titik pijaknya disalin ke `assets/sprites/obstacles/`, `assets/sprites/houses/perumahan/`, dan `assets/sprites/props/` (`prop_kotak_surat`: bentuk `lib.kotak_surat` berwarna oranye graybox, sasaran scene rute; `prop_kotak_surat_bukan`: kotak surat abu-abu rumah bukan pelanggan seberang, lebih rendah dan tanpa celah surat, bukan sasaran), dan mock ×2 ke `docs/design/environment/fase3_*.png`. Hasilnya deterministik:

```
python3 tools/env_art/fase3.py --salin            # rintangan, rumah dua sisi, antena TV, kotak surat sasaran dan abu-abu, layar contoh
```

Graybox spike rumah sisi dekat (run fase3c-hud-hasil, usulan, TECH_PLAN Fase 3; bukan keputusan) dibuat oleh `spike_sisi_dekat.py`, dari root repo. Memakai `fase3.py` apa adanya. Hasil ke `build/env_art/spike_sisi_dekat/`; dengan `--salin` PNG + JSON (titik pijak, `tapak_ubin`, `tinggi_ubin` untuk kotak penutup) disalin ke `assets/sprites/_spike/sisi_dekat/`, yang dipakai hanya oleh scene dev `scenes/dev/spike_sisi_dekat.tscn` dan dikecualikan dari paket ekspor. Deterministik:

```
python3 tools/env_art/spike_sisi_dekat.py --salin  # tiga pendekatan: rendah + kontras rendah, tembok belakang, punggung penuh
```

Variasi kendaraan dan kucing (usulan) dibuat oleh `kendaraan.py`, dari root repo, ke `build/env_art/kendaraan/` (sheet 1× + JSON titik pijak, lembar contoh warna, layar contoh). Belum disalin ke `assets/`:

```
python3 tools/env_art/kendaraan.py               # mobil 5 model, motor 4 model, kucing 5 warna, layar contoh
```

Hasil masuk ke `build/env_art/` (tidak di-commit, bisa diganti lewat `ENV_ART_OUT`). Setelah dicek, salin yang dipakai ke `docs/design/environment/`.

## Cara kerja

- **Ray cast per piksel** pada primitif cembung (kotak, prisma atap pelana/limas/sandar, elipsoid, silinder, bidang bebas). Arah pandang dan proyeksi persis sama dengan `iso.py`: `sx = x − y`, `sy = (x + y)/2 − z`.
- **Nada dipanggang** dari cahaya kiri atas (terang/dasar/gelap) seperti sprite pemain.
- **Lapisan dinamis per waktu** (`TIMES` di `engine.py`): bayangan jatuh dari matahari (sudut pagi 24°, siang 52°, sore 20°, malam 40°), warna cahaya, warna bayangan, lampu titik bertingkat tiga cincin, jendela menyala dengan glow piksel.
- **Pemain** ditempel setelah render: bayangan bawaannya ikut warna bayangan waktu, badannya hanya kena setengah color grading. Benda bergaris luar yang menutupi pemain digambar semi-transparan.
- Garis luar dibuat dari batas antarbagian dan kedalaman, tanpa anti-aliasing.

## File

| File | Isi |
|---|---|
| `engine.py` | Primitif, ray cast, nada, bayangan, lampu, glow, garis luar, penempelan sprite, `TIMES` |
| `lib.py` | Palet induk + tambahan, tekstur dinding/atap/tanah, pohon (termasuk `TREE_KINDS`: rindang, glodokan, ketapang), kelapa, semak, kotak surat, lampu jalan, sedan, angkot, bus kecil, motor, ayam, jemuran, kabel, asap, antena TV |
| `perumahan.py` | Jalan perumahan: aspal 3 ubin, lajur sepeda di kedua sisi, tiga bentuk rumah (`HOUSE_TYPES`: limasan, pelana, sayap) |
| `kampung.py` | Gang perkampungan 2 ubin: rumah rapat, warung, jemuran melintang, halaman, tiang listrik |
| `districts.py` | Ruko, pasar, desa, pinggir sungai, dan vinyet enam distrik |
| `fase3.py` | Aset Fase 3 perumahan (usulan): anjing penjaga lima pose, mobil keluar garasi (sedan `lib.car()` diputar 90°, lampu mundur, cahaya di aspal, asap knalpot), rumah sisi seberang dan sisi dekat versi pelanggan dan bukan pelanggan (toren air, jemuran), enam jenis antena TV (`antena_v`), kotak surat sasaran oranye `prop_kotak_surat` (`kotak_surat_oranye`, sprite tunggal), kotak surat abu-abu bukan sasaran `prop_kotak_surat_bukan` (`kotak_surat_bukan`, sprite tunggal), layar contoh satu sisi dan dua sisi, ekspor sprite + JSON titik pijak. Memakai `engine.py`, `lib.py`, `perumahan.py` tanpa mengubahnya |
| `spike_sisi_dekat.py` | Spike rumah sisi dekat (usulan): punggung rumah rendah dan kontras rendah (`house_near_rendah`, warna dicampur 40% ke rumput), tembok belakang rendah (`tembok_belakang`), punggung penuh tanpa kotak surat di sprite; JSON dengan tapak dan tinggi untuk aturan penutup. Memakai `fase3.py` tanpa mengubahnya |
| `kendaraan.py` | Variasi kendaraan dan kucing (usulan): mobil sedan (bentuk `lib.car()`), hatchback, MPV, pikap bak, angkot (`lib.angkot`) dalam empat arah dengan lampu mati, jalan, rem, dan sein (skala ×1,3, sekitar 2×1 ubin); motor matic, bebek, sport, motor sayur, parkir miring di standar samping atau jalan dengan pengendara (skala ×1,7, helm setinggi kepala loper); kucing tujuh pose × empat arah, lima warna (belang tiga berkalung = kucing misi). Memakai `engine.py`, `lib.py`, `perumahan.py`, `fase3.py` tanpa mengubahnya |
| `details.py` | Loop detail pinggir jalan |
| `anim_hero.py` | Animasi adegan utama |
| `graybox.py` | Ubin graybox 64x32 (aspal, trotoar, rumput), kotak rumah, dan kotak surat untuk `assets/sprites/_placeholder/` (hanya stdlib, bukan mock) |
