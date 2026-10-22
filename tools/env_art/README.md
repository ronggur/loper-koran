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

**Sama di semua mesin:** hasil kali titik per piksel (tabrakan sinar, normal, tekstur) memakai `mm()` di `engine.py`, bukan operator `@` numpy. `@` memanggil BLAS (Accelerate di macOS, OpenBLAS di Linux) yang memilih kernel menurut CPU (AVX2, AVX-512, FMA), sehingga bit terakhir hasil bisa beda dan piksel di tepi bentuk ikut berubah; uji golden di CI Linux pernah gagal karena itu. Kode render baru yang mengalikan larik per piksel memakai `mm(a, b)`.

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

Variasi kendaraan dan kucing (usulan) dibuat oleh `kendaraan.py`, dari root repo, ke `build/env_art/kendaraan/` (sheet 1× + JSON titik pijak, lembar contoh warna, layar contoh). **`--salin` (run fase4b-misi-kucing) menyalin hanya `mission_kucing_sheet.{png,json}` ke `assets/sprites/npc/`** (kucing misi Bu Ratmi, dipakai `scenes/entities/kucing_misi.tscn`); mobil, motor, dan kucing dekorasi tetap hanya di `build/`. Hasil deterministik di mesin yang sama (`tools/tests_cek/uji_aset_kucing.py`); render di mesin run 4B berselisih beberapa ratus piksel dari mock PR #35 (`docs/design/environment/kendaraan_perumahan.png`, drift numpy/pillow), tanpa pengaruh pada game:

```
python3 tools/env_art/kendaraan.py               # mobil 5 model, motor 4 model, kucing 5 warna, layar contoh
python3 tools/env_art/kendaraan.py --salin       # juga salin sheet kucing misi ke assets/sprites/npc/
```

Ubin jalan perumahan (usulan), dari root repo. Tanpa argumen semua ubin (18 ubin 64x32, tanpa polisi tidur: K-1 run fase5a membuang `prop_polisi_tidur` kuning-hitam lama, satu-satunya polisi tidur adalah `tile_perumahan_polisi_tidur` gelombang 1) ke `build/env_art/ubin/` dengan cek sambungan (beda 0). **`--salin` (run fase5a-pasang-aset-gelombang1, D-1 dan D-2) menyalin hanya enam ubin kolom jalan (`tile_perumahan_{rumput_seberang,trotoar_seberang,aspal_seberang,aspal_dekat,trotoar_dekat,rumput_dekat}.png`) dan satu ubin rumput polos `tile_perumahan_rumput_1.png` (untuk kolom rumput di luar kolom pertama: `rumput_seberang` membawa tepi kerb luar yang akan berulang sebagai pita; `rumput_dekat` identik piksel dengan `rumput_1`) ke `assets/sprites/tiles/perumahan/`, ditambah `tile_perumahan.json` yang hanya memuat ubin yang dipasang** (hasil skrip, bukan salinan JSON penuh di build/). Ubin lain (simbol, masuk garasi, `aspal_N`, `rumput_2`, `rumput_3`) tetap hanya di build/. Dijaga `tools/tests_cek/uji_aset_pasang_gelombang1.py`. Lampu dan pohon belum disalin ke `assets/`:

```
python3 tools/env_art/ubin_perumahan.py          # 18 ubin 64x32 ke build/env_art/ubin/ (cek sambungan: beda 0)
python3 tools/env_art/ubin_perumahan.py --salin  # juga salin 7 ubin yang dipasang + JSON terpangkas ke assets/sprites/tiles/perumahan/
python3 tools/env_art/lampu_pohon.py             # 7 lampu (mati/nyala), 11 pohon, layar contoh siang dan malam ke build/env_art/lampu_pohon/
```

**Run fase5b-tembok-dekor (D-1 dan D-4) menambah ke ketiga `--salin`, tetap hanya yang dipasang:** `ubin_perumahan.py --salin` kini menyalin 13 ubin (enam kolom, `rumput_1`, `rumput_2`, `rumput_3`, dan empat ubin khusus `trotoar_seberang_masuk`, `rumput_seberang_masuk`, `trotoar_seberang_simbol`, `trotoar_dekat_simbol`; `aspal_1..3` dan `*_dekat_masuk` TIDAK) ke `assets/sprites/tiles/perumahan/` bersama `tile_perumahan.json` terpangkas (kunci `ubin_khusus`, `ubin_polos_luar`); `gelombang1/render.py --salin` menambah `house_tembok_{polos,bata,besi,pot,tiang}` ke `assets/sprites/houses/perumahan/` dan `prop_tong_sampah_logam` ke `assets/sprites/props/` (tong biru tidak); `lampu_pohon.py --salin` (baru) menyalin `prop_pohon_{rindang,glodokan,ketapang}`, `prop_lampu_lengan_seberang`, dan `prop_lampu_lengan_dekat` (satu bingkai MATI; bingkai nyala tidak disalin) ke `assets/sprites/props/`. `ENV_ART_SALIN_KE` mengganti tujuan ketiganya (lampu_pohon: folder `props` langsung). Dijaga `tools/tests_cek/uji_aset_pasang_5b.py` (deterministik, isi `assets/` = keluaran skrip, golden isi 5A byte-identik, impor Lossless, susunan ubin khusus = adegan renderer dan referensi `tests/data/ubin_potongan_5b.png`) dan `tools/tests_cek/uji_aset_lampu_pohon.py`; `uji_aset_pasang_gelombang1.py` diperbarui untuk daftar folder yang baru:

```
python3 tools/env_art/ubin_perumahan.py --salin           # 13 ubin yang dipasang + JSON terpangkas
python3 tools/env_art/gelombang1/render.py --salin        # 13 sprite 5A + lima tembok + tong sampah logam
python3 tools/env_art/lampu_pohon.py --salin              # tiga pohon + dua lampu mati ke assets/sprites/props/ (lalu godot --headless --import)
python3 tools/tests_cek/uji_aset_pasang_5b.py             # isi assets/ = keluaran ketiga skrip, impor Lossless, susunan ubin khusus
python3 tools/tests_cek/uji_aset_pasang_5b.py --perbarui-referensi   # tulis ulang tests/data/ubin_potongan_5b.png dari assets/
python3 tools/tests_cek/uji_aset_lampu_pohon.py           # lampu_pohon.py deterministik, palet, JSON, tanpa bingkai nyala
```

Aset gelombang 1 Fase 5 (usulan, 2026-10-20) dibuat oleh paket `gelombang1/`, port dari kanvas Claude Design "Aset Gelombang 1 (Fase 5) — Loper Koran" (`docs/design/PROMPT_FASE5.md`). Semua sprite digambar dengan kode: SDF (kotak, silinder, kapsul) yang di-raycast per piksel dengan proyeksi yang sama dengan `iso.py`, decal di bidang tanah, atau grid piksel eksplisit; palet induk ART_DIRECTION 2.4, garis luar `#0E0A1C`, bayangan penanda `#000000` alpha 71. Ubin alas, rumah, kotak surat, dan pemain diambil dari aset yang sudah ada tanpa diubah (`gelombang1/sumber.py`). Hasil ke `build/env_art/gelombang1/sprites/` (29 sprite 1×, frame berjajar kiri ke kanan, satu JSON per sprite: `cell`, `frames`, `fps`, `ground_anchor`, ditambah `manifest.json`) dan `board/` (pratinjau ×5, uji keterbacaan ×3 di aspal/trotoar/rumput, komposisi siang dan sore). **`--salin` (run fase5a-pasang-aset-gelombang1, D-1) menyalin hanya 13 sprite yang dipasang di rute (PNG + JSON): `prop_koran_{putar,bayangan,teras,rumput,kotak_surat,terlipat}` ke `assets/sprites/props/`, dan `vfx_debu_roda`, `vfx_garis_kecepatan_{a,b,c}`, `vfx_bintang_kena`, `vfx_koin_tip`, `mission_kilau` ke `assets/sprites/vfx/`.** Aset lain (tong sampah, jejak, mangkuk, portal, pos, tembok, percikan, polisi tidur, zebra, genangan) tetap hanya di `build/` sampai dipasang run berikutnya (5B, M3). Tiga penyesuaian K-1 (2026-10-21): `mission_kilau` dua warna (krem terang dominan, kuning aksen hanya titik tengah), tong sampah hijau diganti `prop_tong_sampah_logam` (abu-abu logam, dasar `logamg` bukan `#969AA0`) dan biru dipertahankan (tidak sama dengan token semantik DESIGN_SPEC 1.1), hanya satu polisi tidur. Deterministik, dijaga `tools/tests_cek/uji_aset_gelombang1.py` (renderer, palet, K-1, mock) dan `tools/tests_cek/uji_aset_pasang_gelombang1.py` (`--salin` = isi `assets/`, impor Lossless). Variabel lingkungan: `ENV_ART_OUT` (build), `ENV_ART_SALIN_KE` (tujuan `--salin`, dipakai uji), `ENV_ART_MOCK_KE` (tujuan `--mock`):

```
python3 tools/env_art/gelombang1/render.py          # sprite + papan ke build/env_art/gelombang1/
python3 tools/env_art/gelombang1/render.py --mock   # juga salin mock terpilih dan lembar kontak ke docs/design/environment/gelombang1/
python3 tools/env_art/gelombang1/render.py --salin  # juga salin 13 sprite yang dipasang ke assets/sprites/{props,vfx}/ (lalu godot --headless --import)
python3 tools/tests_cek/uji_aset_gelombang1.py      # deterministik, palet induk, manifest, K-1, mock docs = hasil skrip
python3 tools/tests_cek/uji_aset_pasang_gelombang1.py   # isi assets/sprites/{props,vfx,tiles/perumahan} = keluaran --salin, hanya yang dipasang, impor Lossless
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
| `ubin_perumahan.py` | Ubin jalan perumahan (usulan) dengan tata letak game (`config.gd`: aspal 2 ubin, trotoar 1 ubin): aspal seberang/dekat dengan marka, trotoar dengan kerb dan lajur sepeda (biasa, simbol, jalan masuk), rumput, aspal dan rumput polos tiga varian (polisi tidur lama dibuang di run fase5a). `--salin` memasang enam ubin kolom + `rumput_1` ke `assets/sprites/tiles/perumahan/`. Penampang dirender sekali sebagai adegan berulang tiap 1 ubin lalu dipotong per belah ketupat (64x32, 1.024 piksel, tanpa tumpang tindih), jadi kerb yang melewati batas ubin tetap menyambung |
| `lampu_pohon.py` | Lampu jalan (usulan) tujuh jenis: lengan, lengkung, ganda, taman, tiang beton, bambu, tenaga surya; mati/nyala, lengan ke sisi seberang atau dekat. Pohon sebelas jenis sebagai sprite tunggal: rindang, glodokan, ketapang, kelapa, pisang (sudah ada) dan flamboyan, pucuk merah, palem raja, pepaya, bambu, beringin (baru). Layar contoh siang dan malam dari ubin baru |
| `gelombang1/` | Aset gelombang 1 Fase 5 (usulan): `pxcore.py` (proyeksi, palet induk, SDF + raycast, garis luar, bayangan penanda, grid piksel), `koran.py` (koran gulung berputar, bayangan 3 ukuran, mendarat di teras/rumput/kotak surat, terlipat), `vfx.py` (debu roda, garis kecepatan 3 varian, bintang kena, koin tip "+5", percikan genangan), `properti.py` (tong sampah 2 warna (logam dan biru; hijau dibuang K-1), jejak kucing 2 varian, mangkuk, kilau misi, portal dan pos satpam), `tembok_ubin.py` (modul tembok belakang rendah sisi dekat 4 varian + tiang ujung, ubin polisi tidur, zebra, genangan), `sumber.py` (aset repo yang dipakai sebagai alas), `komposisi.py` (jalan perumahan 640×360 siang/sore dengan geometri game), `render.py` (ekspor sprite, JSON, papan, `--mock`, `--salin`) |
| `details.py` | Loop detail pinggir jalan |
| `anim_hero.py` | Animasi adegan utama |
| `graybox.py` | Ubin graybox 64x32 (aspal, trotoar, rumput), kotak rumah, dan kotak surat untuk `assets/sprites/_placeholder/` (hanya stdlib, bukan mock) |
