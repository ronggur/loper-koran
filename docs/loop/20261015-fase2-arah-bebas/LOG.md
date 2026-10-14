# Loop Log — 20261015-fase2-arah-bebas
Scope: arah lempar koran bebas (perbaikan uji HP Run 2A)  ·  Branch: feat/lempar-arah-bebas  ·  Mulai: 2026-10-15  ·  Godot: 4.7.2.stable.official.ed1daf0bf

## Status: IN_PROGRESS   (iterasi saat ini: 1/2)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 1 | SPEC penuh: `ThrowSolver` arah bebas (D-1 sampai D-3), zona dari titik mendarat (D-4), lepas jari D-5 di `jalan_uji.gd`, tes AC-2 sampai AC-8 murni dan scene, probe jendela + 64 tangkapan (AC-10), dokumen AC-9, 11 mutan mati (AC-11). Commit `e3ce0f1`, `ead49dc`, `c26050b`, `9e0f8cd` | ✅ import bersih, 6052 lolos 0 gagal, `--ketat` lolos, `uji_pemeriksa` 16/16, `--quit-after 2` bersih, pack tanpa tests/docs/probe | | | |

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## NEEDS-MANUAL (uji di HP)
- [ ] Arah bebas terasa wajar: swipe ke arah rumah yang terlihat mengenai rumah itu (vivo V2108, juga A54 bila tersambung).
- [ ] Kotak surat seberang di depan bisa dikenai dengan sengaja di santai, cepat, ngebut.
- [ ] Swipe kiri murni (mendarat seberang sedikit ke belakang) tidak membingungkan.
- [ ] Swipe ke atas cukup panjang untuk lemparan jauh.
- [ ] Flick dan jari ditarik kembali.
- [ ] Pengamatan untuk Run 2B: apakah jeda antar lempar 0,35 detik dan jeda lepas 0,17 detik masih terasa "tidak responsif".

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

