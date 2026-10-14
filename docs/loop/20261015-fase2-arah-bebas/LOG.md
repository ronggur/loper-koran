# Loop Log — 20261015-fase2-arah-bebas
Scope: arah lempar koran bebas (perbaikan uji HP Run 2A)  ·  Branch: feat/lempar-arah-bebas  ·  Mulai: 2026-10-15  ·  Godot: 4.7.2.stable.official.ed1daf0bf

## Status: IN_PROGRESS   (iterasi saat ini: 2/2)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 1 | SPEC penuh: `ThrowSolver` arah bebas (D-1 sampai D-3), zona dari titik mendarat (D-4), lepas jari D-5 di `jalan_uji.gd`, tes AC-2 sampai AC-8 murni dan scene, probe jendela + 64 tangkapan (AC-10), dokumen AC-9, 11 mutan mati (AC-11). Commit `e3ce0f1`, `ead49dc`, `c26050b`, `9e0f8cd` | ✅ import bersih, 6052 lolos 0 gagal, `--ketat` lolos, `uji_pemeriksa` 16/16, `--quit-after 2` bersih, pack tanpa tests/docs/probe; QA ulang di HEAD `e6c6c8b`: ✅ sama (6052 lolos, 0 gagal) | FAIL (1 Major) | 4 (1 Major, 2 Minor, 1 Nit) | 0 |

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|
| QA-001 | 1 | Major | tests/tes_koran_scene.gd:609-634 (`_test_regresi_pemilik` scene) | Tes scene AC-6 tidak membuktikan regresi laporan pemilik: pencarian mulai tepat 45° dan syaratnya `sudut >= 45 - 0,001`, tanpa syarat \|dy\| > \|dx\| (tes murni punya syarat itu). Di HEAD, ngebut sudah memakai swipe 45,000° (\|dx\| = \|dy\| = 164,7559), yaitu batas, bukan rentang yang ditolak Run 2A. Repro: pasang aturan Run 2A di jalur scene saja (`JalanUji.lintasan_swipe` return null bila \|dy\| >= \|dx\|) lalu jalankan `run_tests`: 11 GAGAL di tes lain, tetapi ketiga cek AC-6 scene (santai, cepat, ngebut) tetap LOLOS dengan swipe 44,999998° (\|dx\| 190,211731 > \|dy\| 190,211716 karena derau float, jadi aturan Run 2A menerimanya). Skrip repro QA: mutan + `print` sementara di baris `var sudut` (tidak di-commit). Harapan: tes scene mensyaratkan swipe yang benar-benar ditolak Run 2A (\|dy\| > \|dx\| tegas, mis. sudut 46°–134°) di ketiga kecepatan, dan mati terhadap mutan di atas. | OPEN | | |
| QA-002 | 1 | Minor | docs/GDD.md:81 (GDD 4.2) | "Swipe ke kiri atau kanan menentukan sisi lemparan." masih aturan dua arah lama dan bertentangan dengan GDD 5.2 (arah bebas). SPEC: GDD boleh diubah bila salah fakta dan dicatat di LOG; catatan Dev menyebut "tidak ditemukan salah fakta". Usul: ubah jadi arah swipe di layar (sisi diturunkan dari arah), catat di LOG. | OPEN | | |
| QA-003 | 1 | Minor | docs/design/character/loper_agen/lempar/README.md:19 | Masih menulis "Swipe horizontal…", "Swipe vertikal atau lebih pendek dari 12 px … tidak melempar". Sejak run ini swipe vertikal melempar dan ambangnya 6% \|v\| (AC-8: teks yang menyebut aturan lama diperbarui). Repro: `git grep -n "Swipe vertikal" docs/design`. | OPEN | | |
| QA-004 | 1 | Nit | scripts/systems/zona_sasaran.gd:10 | Baris doc comment 213 karakter tidak dibungkus (baris lain berkas ini dibungkus sekitar 135). | OPEN | | |

## NEEDS-MANUAL (uji di HP)
- [ ] Arah bebas terasa wajar: swipe ke arah rumah yang terlihat mengenai rumah itu (vivo V2108, juga A54 bila tersambung).
- [ ] Kotak surat seberang di depan bisa dikenai dengan sengaja di santai, cepat, ngebut.
- [ ] Swipe kiri murni (mendarat seberang sedikit ke belakang) tidak membingungkan.
- [ ] Swipe ke atas cukup panjang untuk lemparan jauh.
- [ ] Flick dan jari ditarik kembali.
- [ ] Pengamatan untuk Run 2B: apakah jeda antar lempar 0,35 detik dan jeda lepas 0,17 detik masih terasa "tidak responsif".
- [ ] (QA) Garis bidik saat melaju tidak sejajar jari: di santai 3 u/d, jari 60° memberi lengkung garis bidik yang tampak sekitar 40° karena warisan maju (tangkapan `shots/qa-iter1/2340x1080_koran_bidik_atas_kotak_surat_seberang.png`). Sejajar hanya saat sepeda berhenti. Nilai di HP apakah ini membingungkan saat membidik.
- [ ] (QA) Batas sisi animasi = sumbu jalan di layar (kemiringan 1:2, sekitar 26,6°): swipe kanan atas yang lebih curam dari jalan memutar animasi lempar ke sisi seberang (mis. 30° = `lempar_kiri_*`). Nilai apakah animasi terasa cocok dengan arah koran.

## Keputusan & catatan
- Keputusan pemilik 2026-10-15 (chat): "arah bebas dong", jawaban atas usulan orchestrator (arah bebas vs dua sisi dilonggarkan). Dicatat di GDD 5.2 dan ROADMAP 4b, commit `06c6797`.
- Laporan pemilik 2026-10-14 sesudah uji Run 2A di vivo V2108: "lemparan koran rasanya gak responsif, suka gagal, terutama ke arah kiri". Penyebab terbukti orchestrator (SPEC, Latar belakang): swipe dominan tegak (45°–135°) ditolak, padahal sasaran seberang di depan terlihat di atas sepeda.
- Run dimulai di sesi yang sama dengan penutupan Run 2A (sesudah ringkasan konteks), atas permintaan langsung pemilik; menyimpang dari Bagian 0c (satu sesi per run) demi kelanjutan, keadaan run tetap seluruhnya di SPEC/LOG.

### Catatan Dev iterasi 1 (2026-10-15)

**Pilihan desain dalam batas SPEC (bisa ditolak QA atau di review):**
- `ThrowSolver` (`scripts/systems/throw_solver.gd`):
  - Fungsi baru `arah_tanah(v)` (`Iso.layar_ke_dunia(v)` dinormalkan), `sisi_dari_arah(arah)` (x < 0 seberang, selain itu dekat; x = 0 dan x = -0 = dekat; nol/NaN/tak hingga = `TIDAK_ADA`), dan `panjang_swipe(awal, akhir)` (|v|).
  - `sisi_dari_swipe` dipertahankan namanya dengan arti baru: `TIDAK_ADA` hanya bila |v| < min atau titik tidak sah.
  - `hitung(panjang, lebar, arah: Vector2, ...)`: parameter ketiga kini arah tanah (dinormalkan di dalam), bukan sisi. `Lintasan.arah` baru, `Lintasan.sisi` diturunkan dari arah.
  - `jarak_samping` → `Lintasan.jarak` dan `jarak_samping_ubin` → `jarak_ubin` (jarak tanah searah arah, bukan ke samping).
  - `arah_sisi(sisi)` dipertahankan untuk tes dan probe (lemparan melintang murni).
  - Panjang |v| dan normalisasi dihitung float 64-bit, supaya swipe sangat panjang (1e30) tidak meluap jadi tak hingga di `Vector2` presisi tunggal.
- `ZonaSasaran`: penyaring sisi **dihapus**, bukan diabaikan. Parameter `sisi_lempar` hilang dari `zona_kena(titik, daftar)`, `klasifikasi(titik, daftar)`, dan `klasifikasi_jalan_uji(titik)`. `Zona.sisi` tetap ada untuk gambar (`ZonaGambar`). `KoranLempar.hasil_mendarat` memanggil versi tanpa sisi.
- `JalanUji._saat_swipe_selesai` (D-5): pemeriksaan eksplisit `ThrowSolver.cukup_panjang(ThrowSolver.panjang_swipe(awal, akhir), lebar)` sebelum memilih lintasan. Arah posisi lepas tidak diperiksa sama sekali. Lintasan = garis bidik tampil, atau `lintasan_swipe` dari posisi lepas bila tidak ada.
- Tidak ada angka `Config` baru. `config.gd` hanya berubah di komentar (|dx| → |v|, "jarak ke samping" → "jarak tanah").
- GDD 5.2 dan ROADMAP 4b tidak diubah; tidak ditemukan salah fakta.

**Pengamatan untuk QA dan pemilik:**
- Saat sepeda melaju, garis bidik yang terlihat **tidak** lurus sejajar jari. Koran mewarisi kecepatan maju, jadi elips bergeser maju searah jalan, dan lengkungnya naik setinggi puncak. Yang sejajar jari adalah arah tanahnya (AC-2).
  - Untuk menunjukkannya, probe memotret garis bidik saat sepeda berhenti (`*_bidik_sejajar_berhenti_*`): sudut garis tanah dari titik lepas ke elips = sudut jari (120, 60, 180, 270 derajat).
  - Ditulis di DESIGN_SPEC 3.7. Rasa di HP = NEEDS-MANUAL.
- Swipe kiri murni di santai dengan u 0,5 mendarat 0,50 ubin di belakang titik lepas, di halaman seberang (probe `kiri_murni`).
- Probe 2340x1080 menemukan kotak surat seberang di depan:
  - santai: swipe 60 derajat, |v| 199 px;
  - ngebut: swipe 78 derajat, |v| 141 px.

  Kotak surat dekat dikenai dengan swipe 9 derajat (santai) dan 354 derajat (ngebut).

**Tes lama yang diganti (tidak dihapus tanpa pengganti):**
- `tests/tes_sprite.gd` `_test_sisi_dari_swipe`: harapan Run 2A ("tegak dominan dan 45 derajat = `TIDAK_ADA`", "46 datar + 20 tegak tidak melempar") diganti harapan arah bebas untuk vektor yang sama (atas = seberang, bawah = dekat, 45 derajat tidak ambigu, |v| 50,2 melempar). Garis pemisah sisi kini searah sumbu jalan di layar (kemiringan 1:2), jadi (-80, 60) dan (-51, 50) = dekat.
- `tests/tes_lempar.gd`:
  - "sisi salah = MELESET" diganti `_test_zona_dari_titik`;
  - "sisi TIDAK_ADA atau di luar enum tidak ada lintasan" diganti "arah nol/NaN/tak hingga tidak ada lintasan" dan "arah tidak satuan dinormalkan";
  - "dari_swipe: tegak dominan = null" diganti "swipe tegak 100 px melempar";
  - "dari_swipe = sisi_dari_swipe + hitung(|dx|)" diganti "= hitung(|v|, arah_tanah(v))".

  Tes rumus, lengkung, keterjangkauan, dan koran lempar memakai `ThrowSolver.arah_sisi(sisi)`, yaitu arah melintang murni dengan angka yang sama dengan Run 2A.
- `tests/tes_input_scene.gd`:
  - swipe (70 kanan, 40 atas) kini `lempar_kiri_ngebut_normal`, karena arah tanahnya maju sedikit ke seberang (x -0,16), sedangkan dulu dekat dari tanda dx;
  - swipe vertikal atas, vertikal bawah, dan miring 30/40 kini melempar dengan animasi yang diharapkan;
  - ditambah "46 px ke atas tidak melempar".
- `tests/tes_koran_scene.gd`:
  - `_test_flick_arah_lain` ditulis ulang untuk D-5: tiga kasus batal (|v_lepas| < min, termasuk ke arah lain) dan tiga kasus tetap melempar (berbelok tegak, berbalik ke kiri, turun), yang lintasannya = objek garis bidik tampil dan mendarat di elips;
  - `_test_sisa_koran_dan_jeda`: "swipe tegak tidak mengurangi" diganti "swipe < 6% datar dan tegak tidak mengurangi" dan "swipe tegak 100 px melempar, koran 27";
  - `_test_input_dan_kidal`: "dominan tegak = garis bidik hilang" diganti "berbelok ke atas = garis bidik tetap, ke seberang", ditambah kidal swipe ke atas (AC-4).

**Tes baru:**
- Murni (`tes_lempar.gd`):
  - `_test_arah_bebas` (AC-2): 18 sudut x 2 panjang x 3 lebar x 4 kecepatan, plus contoh hitung tangan;
  - `_test_tanpa_sudut_ditolak` (AC-3);
  - `_test_sisi_arah` (AC-4, termasuk x = 0 tepat lewat swipe (64, -32) dan x ± sedikit);
  - `_test_penjaga_aturan_lama` (AC-8: tanpa "dominan" dan "|dx|" di berkas jalur lempar);
  - `_test_zona_dari_titik` (AC-5: 2145 titik x 3 sisi x 2 sakelar, kotak surat dengan sisi lempar lawan, tanpa parameter sisi, zona seberang/dekat tidak bertumpuk);
  - `_test_regresi_pemilik` (AC-6: santai, cepat, ngebut, sudut 45 sampai 135 derajat, kotak surat seberang pelanggan di depan sepeda, sah; swipe 78 derajat melempar).
- Scene (`tes_koran_scene.gd`):
  - `_test_prediksi_empat_arah` (AC-7: atas, kanan, kiri, bawah, sepeda melambat selama terbang, mendarat di elips ≤ 1e-4);
  - `_test_regresi_pemilik` (AC-6 lewat event sentuh di tiga kecepatan sebenarnya dari stick).

**Probe (AC-10):** `tests/probe_koran_jendela.gd` ditulis ulang untuk swipe bersudut.
- Jalur jari digambar di lapisan probe (CanvasLayer 50, titik `ColorRect` 2x2 px game `Palette.ACCENT`, bukan bagian game). Probe mencetak sudut jari dan sudut garis tanah lemparan (silang ≤ 1e-4, bila tidak maka dihitung gagal).
- Pencarian sudut dimulai dari tengah rentang.

**Kejujuran:** commit `ead49dc` sempat memuat variabel `kiri`/`kanan` di probe, yang melanggar penjaga gaya nama sisi (1 GAGAL di `run_tests`). Ketahuan saat menjalankan mutan, lalu diperbaiki di `9e0f8cd`. Hasil gerbang di bawah berasal dari HEAD `9e0f8cd`.

### Hasil gerbang iterasi 1 (Dev, HEAD `9e0f8cd`)
- `godot --headless --import`: exit 0, 0 baris ERROR/WARNING; `git status` bersih sesudahnya.
- `godot --headless --script res://tests/run_tests.gd 2>&1 | tee build/tests.log` + `python3 tools/cek_keluaran_tes.py --ketat build/tests.log`: `pemeriksa: lolos (6052 lolos, 0 gagal, 0 peringatan)`. Baseline sebelum run: 5899.
- `python3 tools/tests_cek/uji_pemeriksa.py`: 16 kasus, 0 menyimpang.
- `godot --headless --path . --quit-after 2`: exit 0, 0 ERROR/WARNING.
- `godot --headless --path . --export-pack "Android" build/kring-uji.pck`: exit 0, 0 ERROR/WARNING. Jalur `res://` di paket dipindai: tidak ada `tests/`, `docs/`, `probe`, atau `cek_render`.
- Probe jendela 2340x1080 dan 1920x1080 (`--position 0,0`): exit 0, 0 ERROR/WARNING, "0 sasaran tidak ditemukan". Ada satu baris `PERINGATAN: layar jeda terbuka` di awal (jendela belum fokus, sama dengan run sebelumnya).
- 64 tangkapan di `docs/loop/20261015-fase2-arah-bebas/shots/`: `python3 tools/cek_blok_piksel.py 3 --kecualikan <kotak HUD/kidal yang dicetak probe>` = 64/64 dengan 0 blok tidak seragam.

### Mutan iterasi 1 (AC-11)
Mutan dijalankan lewat skrip di luar repo: kode diubah sementara, `run_tests.gd` dijalankan, lalu berkas dikembalikan. `git diff` bersih sesudahnya. Angka GAGAL di tabel ini dari putaran terakhir, sesudah probe diperbaiki.

| ID | Mutan | Hasil |
|---|---|---|
| M1 | `arah_tanah` tanpa `Iso` (vektor layar dipakai langsung) | mati, 40 GAGAL (AC-2 searah, arah) |
| M2 | `panjang_swipe` = \|dx\| | mati, 50 GAGAL |
| M3 | ambang min eksklusif tanpa toleransi | mati, 40 GAGAL + 4 SCRIPT ERROR |
| M4 | sisi x = 0 → seberang (`<=`) | mati, 3 GAGAL (x = 0 tepat) |
| M5 | solver menolak swipe tegak lagi (aturan Run 2A) | mati, 33 GAGAL |
| M6 | kekuatan dari \|dx\| di `dari_swipe` | mati, 41 GAGAL |
| M7 | `hasil_mendarat` kembali menyaring sisi lempar | mati, 3 GAGAL (`_test_zona_dari_titik`); tes scene AC-6 tidak menangkapnya (lemparan seberang memang bersisi seberang) |
| M8 | aturan batal dihapus (\|v_lepas\| < min tetap melempar) | mati, 6 GAGAL |
| M9 | arah saat diangkat membatalkan (tegak = batal) | mati, 25 GAGAL |
| M10 | lemparan dihitung ulang dari posisi lepas | mati, 17 GAGAL (flick, D-5) |
| M11 | `hitung` memakai arah tanpa dinormalkan | mati, 1 GAGAL (tes baru arah tidak satuan, `9e0f8cd`) |


### QA iterasi 1 (2026-10-15, HEAD `e6c6c8b`)

**Verdict: FAIL** (1 Major OPEN: QA-001). Gerbang hijau; perilaku fitur benar di semua yang diuji. Yang kurang adalah bukti tes scene AC-6.

**Gerbang (dijalankan QA sendiri, Godot 4.7.2.stable.official.ed1daf0bf):**
- `godot --headless --import`: exit 0, 0 ERROR/WARNING. Ada satu baris `cannot connect to daemon at tcp:5037` (adb editor, bukan ERROR/WARNING). `git status` bersih sesudahnya.
- `run_tests.gd` lalu `cek_keluaran_tes.py --ketat`: `pemeriksa: lolos (6052 lolos, 0 gagal, 0 peringatan)`.
- `uji_pemeriksa.py`: 16 kasus, 0 menyimpang.
- `--quit-after 2`: 0 ERROR/WARNING.
- `--export-pack "Android" build/qa-uji.pck`: 0 ERROR/WARNING. Byte `tests/`, `docs/`, `probe`, dan `cek_render` di paket = 0.
- Kebersihan: diff `main...HEAD` tanpa `.godot/`, `build/`, APK, keystore, atau rahasia. `main` = `8257acc` = merge-base (tidak ada commit di `main`). 7 commit berformat `tipe: ringkasan` berbahasa Indonesia dengan baris `Claude-Session`.

**Kepatuhan SPEC (ditelusuri ke kode dan tes):**
- AC-2 (D-1): `ThrowSolver.arah_tanah` = `_satuan(Iso.layar_ke_dunia(v))`. Diuji 18 sudut x 2 panjang x 3 lebar x 4 kecepatan (`tes_lempar.gd` `_test_arah_bebas`), termasuk ke bawah dan belakang. Contoh hitung tangan cocok dengan rumus `Iso`: kiri murni (-0,707, +0,707), atas murni (-0,707, -0,707).
- AC-3 (D-2): |v| dihitung float 64-bit. Ambang inklusif dengan toleransi; min - 0,01 tidak melempar; u dijepit. Tes per sudut ada.
- AC-4 (D-3): x < 0 seberang, x = 0 dan -0 dekat. (64, -32) memberi x tepat 0 dan dites, begitu juga ± sedikit. Kidal lewat tes scene.
- AC-5 (D-4): parameter sisi dihapus dari `zona_kena`/`klasifikasi`/`klasifikasi_jalan_uji`. Tes 2145 titik x 3 sisi dan tidak bertumpuk ada.
- AC-6: tes murni sah, karena mensyaratkan \|dy\| >= \|dx\| (kondisi tolak Run 2A) di tiga kecepatan `Config` sebenarnya. **Tes scene tidak membuktikannya: QA-001.**
- AC-7 dan D-5: `_saat_swipe_selesai` batal hanya bila `cukup_panjang(panjang_swipe(awal, akhir))` false; arah lepas tidak dibaca. Garis bidik basi swipe lain ditolak lewat nomor swipe. Tes flick, tarik kembali, empat arah, dan tanpa garis bidik ada dan mati terhadap mutan (Q17 sampai Q21).
- AC-8: tidak ada `dominan`/`|dx|` di jalur lempar (penjaga teks). Nama sisi tetap `seberang`/`dekat`. Sisa teks lama di luar kode: QA-002, QA-003.
- AC-9: BALANCING 2, 4, 5, 10, DESIGN_SPEC 3.7, TECH_PLAN, DEV_PHASES, SETUP_ANDROID 8.3 dan 8.4, serta AGENTS.md diperbarui. Rinciannya ditulis "usulan" dan tidak "dikunci". ROADMAP 5 "Ketelitian swipe pendek" tetap terbuka. Tidak ada angka `Config` baru dan tidak ada keputusan terbuka yang diambil diam-diam.
- Regresi: tidak ada fungsi tes yang hilang (dibandingkan dengan `main`). Jumlah `check(` naik di `tes_lempar` (194 → 231), `tes_koran_scene` (144 → 160), dan `tes_input_scene` (201 → 202), dan tetap di `tes_sprite` (203). Penggantian harapan yang dicatat Dev setara.

**Validasi visual (jendela asli, dijalankan QA):** `probe_koran_jendela.gd` di 2340x1080 dan 1920x1080 (`--position 0,0`) selesai dengan exit 0, 0 ERROR/WARNING, dan "0 sasaran tidak ditemukan". Tanpa baris PERINGATAN layar jeda. Ke-64 tangkapan lolos `cek_blok_piksel.py 3` dengan `--kecualikan` dari probe: 0 blok tidak seragam. Enam tangkapan yang dilihat langsung disimpan di `shots/qa-iter1/`; sisanya sama dengan tangkapan Dev dan dihapus supaya repo tidak membengkak. Yang terlihat:
- `2340x1080_koran_bidik_atas_kotak_surat_seberang`: jalur jari oranye naik ke kanan atas (sekitar 60°). Lengkung garis bidik putih dari tangan pengendara berakhir di elips hijau terisi (sah) tepat di kotak surat kuning sisi seberang di depan sepeda. Lengkungnya tampak lebih landai (sekitar 40°) daripada jari, karena warisan maju (NEEDS-MANUAL).
- `2340x1080_koran_kena_atas_kotak_surat_seberang`: penanda centang hijau di kotak surat seberang itu, dan HUD koran 29.
- `2340x1080_koran_bidik_kiri_murni`: jalur jari datar ke kiri. Garis bidik melengkung ke kiri, dan elips berada di halaman seberang di kiri sepeda, sedikit di belakang posisinya.
- `2340x1080_koran_bidik_sejajar_berhenti_atas_kanan`: sepeda 0,0 u/d, jari 60°, elips kecil di depan kiri atas. Probe mencetak garis tanah 60,0° = jari 60,0° (silang 0). Dari mata, lengkung yang mulai setinggi tangan sulit dinilai sejajar, jadi angka probe yang dipakai.
- `1920x1080_koran_bidik_bawah_ngebut`: jari ke bawah (jalurnya sebagian di luar layar). Pada 6 u/d warisan maju membawa elips ke depan di jalan sisi dekat.
- `1920x1080_koran_kidal_bidik_atas`: kidal, zona swipe di kiri. Jari lurus ke atas, dan garis bidik mengarah ke elips sah di kotak surat seberang di depan.

**Mutan QA (21, independen dari M1 sampai M11; skrip di luar repo; tiap berkas dikembalikan; `git status` bersih dari mutan):**

| ID | Mutan | Hasil |
|---|---|---|
| Q1 | `arah_tanah` menukar x dan y hasil `Iso` | mati, 98 GAGAL |
| Q2 | `arah_tanah` dibalik (minus) | mati, 128 GAGAL |
| Q3 | `arah_tanah` memakai `dunia_ke_layar` | mati, 52 GAGAL |
| Q4 | `panjang_swipe` = max(\|dx\|, \|dy\|) | mati, 20 GAGAL |
| Q5 | `panjang_swipe` = \|dx\| + \|dy\| | mati, 17 GAGAL |
| Q6 | ambang tanpa toleransi | mati, 8 GAGAL |
| Q7 | ambang eksklusif (> min + toleransi) | mati, 41 GAGAL + 4 error |
| Q8 | u dijepit sampai 2 | mati, 8 GAGAL |
| Q9 | u = \|v\| / maks (min tidak dikurangkan) | mati, 156 GAGAL |
| Q10 | sisi dari komponen y arah tanah | mati, 114 GAGAL |
| Q11 | seberang hanya bila x < -0,1 | mati, 4 GAGAL |
| Q12 | jarak hanya komponen melintang (tanda x) | mati, 13 GAGAL |
| Q13 | `Lintasan.sisi` dari maju/mundur | mati, 106 GAGAL |
| Q14 | `hitung` tidak menolak u < 0 | mati, 24 GAGAL |
| Q15 | `hasil_mendarat` MELESET bila sisi `TIDAK_ADA` | mati, 1 GAGAL |
| Q16 | `zona_kena` mengabaikan kotak surat dekat | mati, 8 GAGAL |
| Q17 | lepas jari batal bila \|dx_lepas\| < min | mati, 17 GAGAL |
| Q18 | pemeriksaan batal lepas jari dihapus | mati, 6 GAGAL |
| Q19 | garis bidik dipakai hanya bila sisi lepas sama | mati, 4 GAGAL |
| Q20 | cek nomor swipe garis bidik dihapus (garis bidik basi) | mati, 1 GAGAL |
| Q21 | garis bidik dari posisi jari + (0, -5) px | mati, 3 GAGAL |
| Q22 | aturan Run 2A (tolak \|dy\| >= \|dx\|) hanya di `JalanUji.lintasan_swipe` | mati secara total (11 GAGAL di tes input/flick/kidal), tetapi **ketiga cek AC-6 scene hidup**, lihat QA-001 |
