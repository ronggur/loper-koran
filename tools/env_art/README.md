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
| `lib.py` | Palet induk + tambahan, tekstur dinding/atap/tanah, pohon, semak, kotak surat, lampu jalan, sedan, angkot, bus kecil, motor, ayam, jemuran, kabel, asap, antena TV |
| `perumahan.py` | Jalan perumahan: aspal 3 ubin, lajur sepeda di kedua sisi, tiga bentuk rumah (`HOUSE_TYPES`: limasan, pelana, sayap) |
| `kampung.py` | Gang perkampungan 2 ubin: rumah rapat, warung, jemuran melintang, halaman, tiang listrik |
| `districts.py` | Ruko, pasar, desa, pinggir sungai, dan vinyet enam distrik |
| `details.py` | Loop detail pinggir jalan |
| `anim_hero.py` | Animasi adegan utama |
