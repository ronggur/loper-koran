# Loop Log — 20261014-fase2a-lemparan
Scope: Run 2A Fase 2, inti lemparan koran (`ThrowSolver`, garis bidik = hasil, koran terbang, zona sasaran placeholder, sisa koran, jeda 0,35 detik) + perapian Run 1C (QA-001, QA-002, QA-005)  ·  Branch: `feat/fase2a-lemparan`  ·  Mulai: 2026-10-14  ·  Godot: 4.7.2

## Status: IN_PROGRESS   (iterasi saat ini: 1/2)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## NEEDS-MANUAL (uji di HP)
- [ ] (diisi QA dari SPEC bagian NEEDS-MANUAL dan temuan)

## Keputusan & catatan
- Keputusan pemilik 2026-10-14: jendela kena koran lewat sakelar `Config`, bawaan penalti ringan (antaran tidak sah, tanpa potong koin); keputusan akhir tetap terbuka (ROADMAP 5). Ukuran ubin 64×32 dikunci (ROADMAP 4b), dicatat orchestrator di `9405c45`.
- Uji HP oleh pemilik sendiri (bukan 3–5 orang). Izin pasang APK: vivo V2108 (`12d8c9da`) setelah QA PASS; A54 bila tersambung.

## Catatan Dev iterasi 1a

Bagian 1a dari 2 (Dev): logika murni lemparan + perapian P-1..P-3. Scene, garis bidik di dunia, koran terbang, bayangan, penanda, HUD koran, probe jendela, dan dokumen tampilan dikerjakan bagian 1b. Tidak push.

### Commit

| Commit | Ringkasan | File |
|---|---|---|
| `6d96a13` | feat: ThrowSolver lintasan koran dan ambang swipe 6% lebar viewport (D-1..D-4) | `scripts/systems/throw_solver.gd` (+`.uid`, baru), `iso.gd` (tinggi z), `lempar_waktu.gd` (`waktu_lepas`), `loper_anim.gd` (`sisi_dari_swipe` dipindah), `scripts/entities/jalan_uji.gd` (memanggil `ThrowSolver.sisi_dari_swipe` dengan lebar viewport), `scripts/config.gd` (`LEMPAR_*`, `KORAN_AWAL`; `LEMPAR_SWIPE_AMBANG_PX` dihapus), `docs/BALANCING.md` 2 dan 4, `tests/tes_lempar.gd` (+`.uid`, baru), `tests/run_tests.gd`, `tests/tes_sprite.gd`, `tests/tes_input_scene.gd` |
| `454224b` | feat: zona sasaran placeholder, sakelar jendela, sisa koran dan jeda 0,35 murni (D-6..D-10) | `scripts/systems/zona_sasaran.gd`, `sisa_koran.gd` (+`.uid`, baru), `scripts/config.gd` (`PENANDA_LAMA_DETIK`, `JENDELA_KENA_BONUS`, `JALAN_UJI_*` zona, isi ulang, `JALAN_UJI_RUMAH_X_UBIN` -2,0 → -3,0), `docs/BALANCING.md` 4, 5, 10, `tests/tes_lempar.gd` |
| `7f06b06` | test: titik gambar debu ruang dunia dan gambar ulang saat induk bergeser (P-1, P-2) | `scripts/entities/pancaran_piksel.gd` (`titik_gambar`), `tests/tes_umpan_balik.gd` (`_test_titik_gambar_debu`) |
| `4e720ae` | test: penjaga probe juga menangkap rujukan uid:// ke berkas probe (P-3) | `tests/tes_export.gd` |
| `8b8002c` | test: tepi inklusif jeda antar lempar tepat di batas toleransi | `tests/tes_lempar.gd` |
| (commit terakhir, lihat `git log`) | docs: peta repo dan catatan Dev iterasi 1a run 2A | `AGENTS.md`, `docs/README.md`, LOG ini |

Tiap commit kode diperiksa di klon bersih (`git clone` + checkout commit itu): import 0 `ERROR`/`WARNING`, `run_tests` 0 gagal + `cek_keluaran_tes.py --ketat` lolos, `--quit-after 2` 0 `ERROR`/`WARNING`, `git status --porcelain` kosong sesudahnya (6d96a13: 5082 lolos; 454224b: 5279; 7f06b06: 5287; 4e720ae: 5294).

### Keputusan di dalam ruang D-x (bisa ditolak di review)

- **D-1 (API).** `ThrowSolver.posisi_pada(lintasan, t) -> Vector3`: x, y = posisi tanah di dunia (ubin), z = tinggi (ubin); GDScript tidak punya tuple, `Vector3` tanpa alokasi. `hitung` dan `dari_swipe` mewajibkan `kecepatan_lateral_ud` dan `jeda_lepas_detik` (tanpa nilai bawaan) supaya garis bidik dan lemparan tidak mungkin memakai argumen berbeda diam-diam. `dari_swipe(awal, akhir, lebar, posisi, v_maju, v_lateral, jeda)` = satu panggilan untuk garis bidik tiap frame dan lemparan saat jari dilepas. Masukan tidak sah: sisi bukan seberang/dekat, posisi tidak hingga, lebar viewport tidak sah, panjang NaN/INF/negatif = `null` (tidak melempar); kecepatan dan jeda NaN/INF/negatif = 0.
- **D-2.** `sisi_dari_swipe` **dipindah** dari `LoperAnim` ke `ThrowSolver` (satu pemilik aturan swipe, tanpa rujukan melingkar LoperAnim ↔ ThrowSolver). Ambang = |dx| (bukan panjang total) ≥ 6% lebar viewport, inklusif dengan toleransi `LEMPAR_SWIPE_TOLERANSI_PX` 0,001 px (posisi sentuh Vector2 berpresisi tunggal: 46,8 tersimpan 46,7999992 sehingga tanpa toleransi swipe "tepat min" di 780 ditolak). Swipe dominan tegak tetap ditolak (aturan lama).
- **D-3.** Tinggi tangan `LEMPAR_TINGGI_TANGAN_UBIN` 0,7 ubin (≈ 22 px, setinggi setang di sel 46×58; usulan). Parabola h(s) = h0 + b s − a s² dengan a = (2H − h0) + 2√(H(H − h0)), b = a − h0: h(0) = tangan, h(1) = 0, maksimum tepat H di s ≤ 1/2. `Iso.tinggi_ke_layar`, `dunia_tinggi_ke_layar`, `posisi_gambar_tinggi` (dibulatkan); 1 ubin tinggi = `UBIN_UNIT_DUNIA` (32) px.
- **D-4: rekomendasi SPEC dipakai.** Titik lepas = posisi saat jari dilepas + (kecepatan maju, kecepatan lateral) × jeda lepas, lateral dijepit `BikeMotion.batas_lateral_ubin()`. Jeda lepas **bukan angka Config baru**: `LemparWaktu.waktu_lepas(fps, jumlah_frame, frame_lepas)` = `max(frame_lepas, 1) / fps` (2/12 ≈ 0,1667 detik dengan fps dari `.tres`), sama persis dengan syarat sinyal `lepas` di `LemparWaktu.langkah` (dites di dt 1/30, 1/60, 1/240). Sebelum jeda lepas lewat, `posisi_sejak_jari` = titik lepas setinggi tangan (bagian 1b tidak menggambar koran sebelum `koran_lepas`).
- **D-6 (data zona, usulan).** Koordinat zona = koordinat jalan (x lateral, y maju), persegi tepi min inklusif dan maks eksklusif di kedua sumbu (`Rect2`). Prioritas zona dulu, baru status pelanggan (kotak surat rumah bukan pelanggan di atas halaman pelanggan = `BUKAN_PELANGGAN`). **Rumah graybox seberang mundur dari lateral −2,0 ke −3,0** (`JALAN_UJI_RUMAH_X_UBIN`): rumah lama menempel di tepi trotoar sehingga tidak ada tempat untuk halaman/teras di depan fasad; sekarang 1 ubin rumput di depan fasad = halaman, teras dan strip jendela di kaki fasad. Kotak surat graybox tetap. Tabel ukuran di BALANCING 5. Bukan pelanggan: rumah seberang n mod 4 = 2 (2 atau 3 per putaran daur 9 slot). Kavling sisi dekat selalu pelanggan, tanpa jendela, hanya placeholder datar (tidak memutuskan ROADMAP 5).
- **D-7.** `const JENDELA_KENA_BONUS: bool = false` (bawaan penalti ringan); fungsi murni `status_antaran(hasil, jendela_bonus)` menerima sakelar sebagai parameter.
- **D-8/D-9.** `SisaKoran` terpisah dari `ThrowSolver`. Toleransi jeda memakai `LEMPAR_TOLERANSI_DETIK` yang sudah ada. Swipe yang ditolak (habis atau masih jeda) tidak mengurangi koran **dan tidak memulai ulang jeda**. Isi ulang: `jarak − jarak_saat_habis ≥ 16` tanpa toleransi. `jeda_lewat(NaN)` = true supaya derau tidak pernah mengunci lemparan (prinsip 2).
- **D-10.** `ZonaSasaran.Penanda`: `CENTANG` (sah penuh), `BINTANG` (bonus jendela), `SETENGAH` (halaman), `SILANG` (tidak sah). Warna (`OK`/`FAIL`) diserahkan ke node di 1b; fungsi murni hanya memetakan bentuk.
- **P-2.** Cabang `NOTIFICATION_TRANSFORM_CHANGED` **dipertahankan** dan dites (bukan dihapus): induk yang bergeser tanpa `maju` (sepeda dipasang ulang saat jeda, `_process` mati) memang mengubah letak gambar debu ruang dunia.

### Tes lama yang diubah (dan kenapa)

- `tests/tes_sprite.gd` `_test_sisi_dari_swipe`: memanggil `ThrowSolver.sisi_dari_swipe(..., 780)` (fungsi pindah). Ambang 12 px → 46,8 px (6% dari 780); contoh panjang total (11 datar + 5 tegak melempar, 8,5 + 8,4 tidak) diganti contoh |dx| (46 datar + 20 tegak = panjang 50,2 **tidak** melempar); contoh diagonal 40/30 dan 30/40 diperbesar ke 80/60 dan 60/80 karena 40 px kini di bawah ambang. Aturan arah, 45°, NaN, INF tetap.
- `tests/tes_input_scene.gd` `_test_lempar_serong_dan_tepi`: swipe 11 px (tolak) dan 12 px (lempar) di viewport 780 → 46 px (tolak) dan 46,8 px (lempar, inklusif). Swipe 60 px lain di semua tes tetap di atas ambang di 640/780/800, tidak diubah.
- `tests/tes_input_scene.gd` (cek rumah daur di sisi seberang) tidak diubah kodenya; nilainya ikut `Config.JALAN_UJI_RUMAH_X_UBIN` yang kini −3,0.
- `tests/tes_export.gd` `_pemakai_probe`: kini juga uid (P-3); label cek lama menyebut `uid://`.

### Mutan nyata (AC-10, AC-13; kode dikembalikan sesudah tiap mutan)

Diterapkan pada kode HEAD `8b8002c` lewat skrip penggantian satu baris/blok (berkas dipulihkan sesudah tiap mutan), lalu `run_tests` penuh. **36 mutan, 36 mati, 0 hidup.**

| Mutan | Hasil | Tes yang membunuh (contoh label) |
|---|---|---|
| A01 jepit u dihapus | mati, 3 gagal (5292 lolos) | "lebar 640.0: tepat maks dan 3x maks = u 1 (dijepit)"; "lebar 780.0: tepat maks dan 3x maks = u 1 (dijepit)" |
| A02 min/maks swipe tertukar | mati, 165 gagal (5130 lolos) | "lebar 640.0: tepat min = u 0 (melempar, inklusif)"; "lebar 640.0: tepat maks dan 3x maks = u 1 (dijepit)" |
| A03 warisan maju 0 | mati, 58 gagal (5237 lolos) | "lebar 640.0, 3.0 u/d, seberang u 0.0: geser maju = kecepatan x lama terbang = 1.35, dapat 0.0"; "lebar 640.0, 3.0 u/d, seberang u 0.5: geser maju = kecepatan x lama terbang = 1.8, dapat 0.0" |
| A04 warisan maju dihitung dua kali | mati, 54 gagal (5241 lolos) | "lebar 640.0, 3.0 u/d, seberang u 0.0: geser maju = kecepatan x lama terbang = 1.35, dapat 2.70000076293945"; "lebar 640.0, 3.0 u/d, seberang u 0.5: geser maju = kecepatan x lama terbang = 1.8, dapat 3.59999847412109" |
| A05 warisan lateral ditambahkan | mati, 2 gagal (5293 lolos) | "jeda lepas 0: kecepatan lateral 3 u/d tidak mengubah titik mendarat (tanpa warisan lateral), (3.25, -2.7) lawan (5.05, -2.7)"; "dengan jeda lepas: geser lateral selama terbang tetap tepat jarak samping (-3,25), dapat -5.05000019073486" |
| A06 rumus lintasan kedua di luar ThrowSolver | mati, 1 gagal (5294 lolos) | "tidak ada skrip lain yang memakai angka lintasan (rumus kedua): ["res://scripts/entities/jalan_uji.gd -> LEMPAR_JARAK_"]" |
| A07 jeda lepas diabaikan (titik lepas = posisi saat jari dilepas) | mati, 3 gagal (5292 lolos) | "ngebut 6 u/d + lateral 3 u/d x 1/6 detik: (0,2, -10) -> (0,7, -11), dapat (0.2, -10.0)"; "lateral dijepit ke tepi jalan resmi +-1.0, dapat 0.89999997615814 dan -0.89999997615814" |
| A08 lateral titik lepas tidak dijepit | mati, 1 gagal (5294 lolos) | "lateral dijepit ke tepi jalan resmi +-1.0, dapat 1.39999997615814 dan -1.39999997615814" |
| A09 akar lengkung salah (minus sqrt) | mati, 6 gagal (5289 lolos) | "u 0.0: tinggi tertinggi dari 2001 sampel = puncak 1.0 (toleransi 0.001), dapat 0.69999998807907"; "u 0.0: puncak analitik (s -1.21103222500738) tepat tinggi puncak, di paruh pertama" |
| A10 sisi swipe tertukar | mati, 60 gagal (5235 lolos) | "dari_swipe (kiri layar, /dx/ 120) = hitung(120, seberang)"; "swipe 47.0 px ke kiri layar = SEBERANG" |
| A11 tegak dominan tidak ditolak | mati, 2 gagal (5293 lolos) | "swipe miring dengan gerak tegak lebih besar (60/80) tidak melempar walau /dx/ di atas ambang"; "tepat 45 derajat (datar = tegak) ambigu: tidak melempar" |
| A12 toleransi swipe dibuang | mati, 6 gagal (5289 lolos) | "toleransi swipe hanya meredam derau presisi tunggal (< 0,01 px)"; "lebar 640.0: /dx/ dari Vector2 (presisi tunggal, 38.3999938964844) di min tetap melempar" |
| A13 ambang memakai panjang total, bukan |dx| | mati, 2 gagal (5293 lolos) | "46 datar + 20 tegak (panjang total 50,2 di atas ambang) tidak melempar: yang dihitung /dx/ saja"; "swipe sangat panjang tetap hingga dan melempar ke dekat" |
| A14 waktu_lepas meleset satu frame | mati, 5 gagal (5290 lolos) | "jeda lepas frame 2 di 12 fps = 0,1667 detik, dapat 0.25"; "frame lepas 0 = frame 1; fps atau jumlah frame tidak sah = 0" |
| Z01 prioritas jendela/teras tertukar | mati, 3 gagal (5292 lolos) | "tanpa kotak surat: JENDELA menang atas teras dan halaman"; "jendela menang atas teras" |
| Z02 prioritas kotak surat/halaman tertukar | mati, 21 gagal (5274 lolos) | "empat zona tumpang tindih (urutan [2, 1, 3, 0]) = KOTAK_SURAT"; "empat zona tumpang tindih (urutan [0, 3, 1, 2]) = KOTAK_SURAT" |
| Z03 prioritas = urutan daftar (zona pertama menang) | mati, 20 gagal (5275 lolos) | "empat zona tumpang tindih (urutan [2, 1, 3, 0]) = KOTAK_SURAT"; "empat zona tumpang tindih (urutan [1, 0, 2, 3]) = KOTAK_SURAT" |
| Z04 sakelar jendela diabaikan (selalu penalti) | mati, 2 gagal (5293 lolos) | "jendela: antaran penalti 0, bonus 3"; "jendela: penanda penalti 0, bonus 3" |
| Z05 sakelar jendela diabaikan (selalu bonus) | mati, 4 gagal (5291 lolos) | "jendela: antaran penalti 0, bonus 3"; "jendela: penanda penalti 0, bonus 3" |
| Z06 tepi maks inklusif | mati, 3 gagal (5292 lolos) | "tepi maks lateral (-1,5) eksklusif"; "tepi maks maju (0,5) eksklusif" |
| Z07 bukan pelanggan diabaikan | mati, 2 gagal (5293 lolos) | "teras rumah bukan pelanggan = BUKAN_PELANGGAN"; "zona prioritas tertinggi milik rumah bukan pelanggan = BUKAN_PELANGGAN" |
| Z08 sisi zona tidak dicek | mati, 1 gagal (5294 lolos) | "sisi salah (zona seberang untuk lemparan ke dekat, dan sebaliknya) = MELESET" |
| Z09 maju dunia tidak dibalik (y dunia dipakai sebagai maju) | mati, 48 gagal (5247 lolos) | "titik di kotak surat = KOTAK_SURAT"; "titik di teras = TERAS" |
| Z10 penanda halaman = centang | mati, 2 gagal (5293 lolos) | "halaman: penanda penalti 2, bonus 2"; "empat status antaran = empat bentuk penanda berbeda (tidak hanya warna), dapat [0, 1, 1, 3]" |
| Z11 penanda bonus = centang | mati, 2 gagal (5293 lolos) | "jendela: penanda penalti 0, bonus 3"; "empat status antaran = empat bentuk penanda berbeda (tidak hanya warna), dapat [0, 1, 2, 1]" |
| K01 koran berkurang dua kali | mati, 9 gagal (5286 lolos) | "30 lemparan diterima, tiap lemparan -1 tepat sekali, sisa 0"; "jarak saat habis dicatat (29 ubin)" |
| K02 koran tetap dilempar saat habis | mati, 2 gagal (5293 lolos) | "habis: tidak boleh melempar (tidak ada garis bidik)"; "habis: swipe tidak melempar, sisa tetap 0 (tidak negatif)" |
| K03 lemparan ditolak tetap mengurangi koran | mati, 2 gagal (5293 lolos) | "habis: swipe tidak melempar, sisa tetap 0 (tidak negatif)"; "0,349 detik: ditolak, koran tidak berkurang" |
| K04 jeda >= menjadi > | mati, 1 gagal (5294 lolos) | "tepi inklusif: 0.349999 diterima (perbandingan >=), 0.349998 ditolak" |
| K05 jeda > tanpa toleransi | mati, 15 gagal (5280 lolos) | "30 lemparan diterima, tiap lemparan -1 tepat sekali, sisa 0"; "habis: tidak boleh melempar (tidak ada garis bidik)" |
| K06 jeda tidak memulai ulang saat diterima | mati, 5 gagal (5290 lolos) | "lemparan pertama diterima, jeda mulai dari 0 (jari dilepas)"; "0,349 detik: ditolak, koran tidak berkurang" |
| K07 isi ulang tanpa syarat habis | mati, 2 gagal (5293 lolos) | "baru 15,99 ubin sesudah habis: belum diisi ulang"; "belum habis: tidak diisi ulang walau sudah jauh (isi ulang hanya bila habis)" |
| K08 dt tidak sah tetap memajukan jeda (jeda game tidak membeku) | mati, 3 gagal (5292 lolos) | "dt -1.0 tidak memajukan jeda antar lempar (jeda game membeku)"; "dt nan tidak memajukan jeda antar lempar (jeda game membeku)" |
| P1 M10 titik gambar tanpa transform terbalik | mati, 2 gagal (5293 lolos) | "(P-1) debu ruang dunia: transform global x titik_gambar(i) = posisi global dibulatkan, untuk semua partikel"; "(P-2) titik gambar mengikuti induk: bergeser -(32, 16) di ruang lokal, tetap di tempat yang sama di jalan" |
| P2 M14 tanpa gambar ulang TRANSFORM_CHANGED | mati, 1 gagal (5294 lolos) | "(P-2) induk bergeser tanpa maju: debu digambar ulang (0 kali)" |
| P3 penjaga probe hanya res:// (uid diabaikan) | mati, 1 gagal (5294 lolos) | "contoh buruk: ext_resource dan preload yang hanya memakai uid:// probe (tanpa res://) tertangkap: []" |

Pemetaan ke daftar AC-10: jepit u (A01), min/maks tertukar (A02), warisan maju 0 / dua kali (A03, A04), warisan lateral (A05), rumus sendiri di luar ThrowSolver (A06, penjaga teks), prioritas zona (Z01-Z03), sakelar jendela (Z04, Z05), koran berkurang dua kali / saat habis (K01-K03), jeda `>=` → `>` (K04; tanpa tes tepi `8b8002c` mutan ini setara karena toleransi, maka tes tepi ditambah), isi ulang tanpa syarat habis (K07), M10 (P1), M14 (P2), uid (P3). Belum dijalankan karena butuh scene 1b: garis bidik memakai kecepatan frame sebelumnya, lintasan dihitung ulang saat frame lepas (di 1a ada cek kontrol murni bahwa skenario tes membedakannya), jeda game tidak membekukan koran (K08 hanya bagian murni jeda antar lempar).

### Gerbang (HEAD sesudah commit docs)

- `godot --headless --import`: 0 `ERROR`/`SCRIPT ERROR`/`WARNING`.
- `godot --headless --script res://tests/run_tests.gd 2>&1 | tee build/tests.log`: **5295 lolos, 0 gagal**; `python3 tools/cek_keluaran_tes.py --ketat build/tests.log`: lolos (0 peringatan). Sebelum run ini (`f5b047d`): 4668.
- `python3 tools/tests_cek/uji_pemeriksa.py`: 16 kasus, 0 menyimpang; `uji_bangun_frames.py`: 41 lolos; `uji_sintesis_sepeda.py`: 32 lolos.
- `godot --headless --path . --quit-after 2`: 0 `ERROR`/`WARNING`.
- Klon bersih per commit kode: lihat bagian Commit. Ekspor `--export-pack` dan probe jendela tidak dijalankan di 1a (tidak ada scene/aset ekspor baru; 1b).

### Serah terima ke 1b

API publik baru (semua `static func`, `RefCounted`):

- `ThrowSolver` (`scripts/systems/throw_solver.gd`):
  - `class Lintasan`: `sisi`, `kekuatan`, `kecepatan_maju_ud`, `jeda_lepas`, `titik_lepas: Vector2`, `titik_mendarat: Vector2`, `jarak_samping`, `geser_maju`, `lama_terbang`, `tinggi_puncak`, `tinggi_tangan`, `lengkung_a`, `lengkung_b`.
  - `swipe_min_px(lebar_viewport_px: float) -> float`, `swipe_maks_px(lebar_viewport_px: float) -> float`, `cukup_panjang(panjang_px: float, lebar_viewport_px: float) -> bool`, `kekuatan(panjang_px: float, lebar_viewport_px: float) -> float` (−1 = tidak melempar).
  - `sisi_dari_swipe(awal: Vector2, akhir: Vector2, lebar_viewport_px: float) -> LoperAnim.Sisi`.
  - `jarak_samping_ubin(u) / lama_terbang_detik(u) / tinggi_puncak_ubin(u) -> float`, `arah_sisi(sisi) -> Vector2`.
  - `titik_lepas(posisi_sepeda: Vector2, kecepatan_maju_ud: float, kecepatan_lateral_ud: float, jeda_lepas_detik: float) -> Vector2`.
  - `hitung(panjang_swipe_px: float, lebar_viewport_px: float, sisi: LoperAnim.Sisi, posisi_sepeda: Vector2, kecepatan_maju_ud: float, kecepatan_lateral_ud: float, jeda_lepas_detik: float) -> Lintasan` (null = tidak melempar).
  - `dari_swipe(awal: Vector2, akhir: Vector2, lebar_viewport_px: float, posisi_sepeda: Vector2, kecepatan_maju_ud: float, kecepatan_lateral_ud: float, jeda_lepas_detik: float) -> Lintasan` — **pakai ini untuk garis bidik tiap frame dan lemparan saat jari dilepas.**
  - `posisi_pada(lintasan, t: float) -> Vector3` (t sejak lepas, dijepit), `tinggi_pada(lintasan, t) -> float`, `waktu_terbang(lintasan, detik_sejak_jari) -> float`, `lama_total(lintasan) -> float`, `sudah_mendarat(lintasan, detik_sejak_jari) -> bool`, `posisi_sejak_jari(lintasan, detik_sejak_jari) -> Vector3`.
- `Iso`: `tinggi_ke_layar(tinggi_ubin) -> Vector2`, `dunia_tinggi_ke_layar(dunia, tinggi_ubin) -> Vector2`, `posisi_gambar_tinggi(dunia, tinggi_ubin) -> Vector2` (bulat; bayangan = `posisi_gambar(dunia)`).
- `LemparWaktu.waktu_lepas(fps: float, jumlah_frame: int, frame_lepas: int) -> float` (jeda lepas; fps dari `SpriteFrames.get_animation_speed`).
- `ZonaSasaran` (`scripts/systems/zona_sasaran.gd`): enum `Jenis`, `Hasil` (`MELESET, KOTAK_SURAT, TERAS, HALAMAN, JENDELA, BUKAN_PELANGGAN`), `Antaran` (`TIDAK_SAH, SAH_PENUH, SAH_SETENGAH, SAH_BONUS`), `Penanda` (`SILANG, CENTANG, SETENGAH, BINTANG`), `const PRIORITAS`; `class Zona` (`persegi: Rect2` koordinat jalan, `sisi`, `jenis`, `pelanggan`, `rumah`); `buat(...)`, `ke_jalan(dunia) -> Vector2`, `memuat(zona, titik_dunia) -> bool`, `zona_kena(titik_dunia, sisi_lempar, daftar) -> Zona`, `klasifikasi(titik_dunia, sisi_lempar, daftar) -> Hasil`, `hasil_zona(zona) -> Hasil`, `status_antaran(hasil, jendela_bonus: bool) -> Antaran`, `sah(antaran) -> bool` (elips `OK` + bentuk lain), `penanda(antaran) -> Penanda`, `penanda_hasil(hasil, jendela_bonus) -> Penanda`, `pelanggan_jalan_uji(indeks) -> bool`, `zona_jalan_uji(indeks) -> Array[Zona]`, `zona_jalan_uji_sekitar(maju_ubin) -> Array[Zona]`, `klasifikasi_jalan_uji(titik_dunia, sisi_lempar) -> Hasil`.
- `SisaKoran` (`scripts/systems/sisa_koran.gd`): `class Keadaan` (`sisa`, `penuh`, `sejak_lempar_detik`, `habis_di_ubin`, `salin()`), `class Hasil` (`diterima`, `keadaan`); `awal(jumlah) -> Keadaan`, `jeda_lewat(sejak) -> bool`, `habis(k) -> bool`, `boleh_lempar(k) -> bool` (garis bidik hanya bila true), `terima(k, jarak_ubin) -> Hasil`, `langkah(k, dt) -> Keadaan` (beri `JedaSim.dt_efektif`), `isi_ulang_jalan_uji(k, jarak_ubin) -> Keadaan`.
- `PancaranPiksel.titik_gambar(i) -> Vector2`.
- Config baru: `LEMPAR_SWIPE_MIN_PECAHAN`, `LEMPAR_SWIPE_MAKS_PECAHAN`, `LEMPAR_SWIPE_TOLERANSI_PX`, `LEMPAR_JARAK_MIN/MAKS_UBIN`, `LEMPAR_TERBANG_MIN/MAKS_DETIK`, `LEMPAR_PUNCAK_MIN/MAKS_UBIN`, `LEMPAR_WARISAN_MAJU`, `LEMPAR_TINGGI_TANGAN_UBIN`, `LEMPAR_JEDA_DETIK`, `KORAN_AWAL`, `PENANDA_LAMA_DETIK`, `JENDELA_KENA_BONUS`, `JALAN_UJI_SEBERANG_{KOTAK_SURAT,HALAMAN,TERAS,JENDELA}_UBIN`, `JALAN_UJI_DEKAT_{KOTAK_SURAT,HALAMAN,TERAS}_UBIN`, `JALAN_UJI_BUKAN_PELANGGAN_SETIAP/SISA`, `JALAN_UJI_ISI_ULANG_UBIN`. Dihapus: `LEMPAR_SWIPE_AMBANG_PX`.
- Penjaga baru di `tes_lempar.gd` `_test_penjaga_rumus`: skrip di `scripts/` selain `config.gd` dan `throw_solver.gd` tidak boleh memakai `Config.LEMPAR_JARAK_*`, `LEMPAR_TERBANG_*`, `LEMPAR_PUNCAK_*`, `LEMPAR_WARISAN_MAJU`, `LEMPAR_TINGGI_TANGAN`, `LEMPAR_SWIPE_*` (node 1b harus lewat `ThrowSolver`).

Belum dikerjakan (1b):

- Scene: `JalanUji._saat_swipe_selesai` baru memakai `ThrowSolver.sisi_dari_swipe` untuk animasi saja; belum ada lintasan, `SisaKoran`, atau koran. `SepedaUji` belum menyimpan `BikeMotion.Hasil.lateral_ud` (dibutuhkan D-4); lebar viewport dari `get_viewport_rect().size.x`.
- D-9: `LoperSprite.lempar` masih menolak swipe selama animasi berjalan (0,333 detik < 0,35, jadi tidak bertabrakan bila `SisaKoran` dicek lebih dulu, tetapi penolakan terpisah itu harus dilepas/diselaraskan dan dites dua lempar cepat + `koran_lepas` tepat sekali).
- D-11: `SepedaUji.jeda()` memanggil `batalkan_lempar()`; lemparan yang sudah diterima harus tetap diluncurkan sesudah lanjut walau jeda datang sebelum frame lepas (lintasan sudah beku, waktu sejak jari dimajukan `dt_efektif`).
- Garis bidik (D-5, sampel `posisi_pada`, elips 10×5, `OK` + bentuk saat `sah`), koran terbang + bayangan + putaran 4 langkah, penanda (D-10, `PENANDA_LAMA_DETIK`), visual zona (strip jendela, penanda rumah bukan pelanggan, kavling dekat datar), HUD koran + kunci terjemahan, tata letak (AC-9), probe jendela (AC-12).
- Mutan scene AC-10 yang belum bisa dijalankan di 1a: garis bidik memakai kecepatan frame sebelumnya, lintasan dihitung ulang saat frame lepas (di 1a hanya kontrol murni yang membuktikan skenario tes membedakannya), jeda game tidak membekukan koran.
- Dokumen AC-14 sisanya: DESIGN_SPEC 3.5/3.7, ART_DIRECTION (koran placeholder dari kode), SETUP_ANDROID 8 (uji Run 2A), perintah probe baru di AGENTS.md dan `00-project-core.mdc`.

Tidak ada BLOCKED.
