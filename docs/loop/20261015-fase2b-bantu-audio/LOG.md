# Loop Log — 20261015-fase2b-bantu-audio
Scope: Run 2B Fase 2 — mode bantu, bunyi lempar dan mendarat, QA-008/QA-005/QA-006, checklist uji HP penutup Fase 2  ·  Branch: `feat/mode-bantu-bunyi-lempar`  ·  Mulai: 2026-10-15  ·  Godot: 4.7.2

## Status: IN_PROGRESS   (iterasi saat ini: 1/2)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 1a | Bagian A: mode bantu AC-1..AC-8 (tap di `TouchRouter`, `BantuLempar` sisi tap + pemilihan sasaran, lemparan bantu di scene, tanda tanpa sasaran, sakelar HUD, kecepatan otomatis), AC-13 QA-008 (oracle gambar independen, N16/N20/N21/N22 mati), dokumen mode bantu (GDD 5.3, BALANCING 4b, DESIGN_SPEC 3.7, TECH_PLAN Fase 2, DEV_PHASES Fase 3, AGENTS peta repo). Bunyi, kontrol.html, SETUP_ANDROID = bagian B. HEAD kode `00954cd` | ✅ import 0 ERROR/WARNING; `run_tests` 6283 lolos 0 gagal; `cek_keluaran_tes.py` dan `--ketat` lolos (0 peringatan); `--quit-after 2` 0 ERROR/WARNING; `uji_pemeriksa` 16 kasus 0 menyimpang, `uji_bangun_frames` 41 lolos, `uji_sintesis_sepeda` 32 lolos; `--export-pack "Android"` tanpa `tests/`, `docs/`, probe | (menunggu QA) | | |

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## NEEDS-MANUAL (uji di HP)
- [ ] (diisi QA)

## Keputusan & catatan
- Keputusan pemilik 2026-10-15 (awal sesi): K-1 santai otomatis + stick opsional; K-2 sisi tap dari garis jalan di zona swipe; K-3 kotak surat pelanggan terdekat di depan, selalu kena, tanpa sasaran = tidak melempar; K-4 jeda 0,35/0,17 tetap. Rincian di SPEC.md.
- Hasil uji HP sebelumnya (run arah bebas, vivo V2108, 2026-10-15): "this is much better". Catatan rinci (kotak surat tiga kecepatan, swipe pendek, garis bidik saat melaju, responsif) belum diisi pemilik; dijadikan butir checklist AC-16.
- Perangkat: vivo V2108 (12d8c9da) tersambung di awal run; A54 tidak tersambung.

## Catatan Dev iterasi 1a

Bagian A dari dua pemanggilan Dev iterasi 1. Commit: `3cc2a77` (tes QA-008), `9192256` (logika murni mode bantu + config + BALANCING 4b), `c0fb888` (mode bantu di scene + HUD + terjemahan), `00954cd` (dokumen).

**Keputusan implementasi**
- **Tap (D-1)** di `TouchRouter`: `_maks_swipe_px` mencatat |v| terbesar dari titik awal (di `geser` dan di posisi `lepas`). Saat jari slot swipe diangkat, `swipe_selesai` tetap dipancarkan seperti dulu (jalan uji menolaknya karena pendek), lalu sinyal baru `tap_selesai(posisi = titik awal, durasi)` bila `not ThrowSolver.cukup_panjang(maks, lebar)` (ambang dan toleransi sama dengan swipe; tepat 6% = swipe). Tambahan: `jumlah_tap_selesai`, `panjang_swipe_maks()`. `batal`/`batal_semua` tidak pernah tap. Swipe dan tap saling eksklusif (tap ⇒ |v_lepas| < min ⇒ swipe ditolak), jadi tidak ada lemparan ganda.
- **Modul `BantuLempar`** (`scripts/systems/bantu_lempar.gd`): `sisi_tap(tap, posisi_sepeda_layar)` = `sisi_dari_arah(arah_tanah(tap − sepeda))`; tap tepat di titik pijak sepeda (vektor nol) = `DEKAT` (di garis), masukan tidak hingga = `TIDAK_ADA`. `pilih(sisi, posisi, v, v_lateral, jeda_lepas, lebar, daftar) -> Pilihan {zona, lintasan, kekuatan}`; `kandidat`, `cari_kekuatan` (bisection f(u) = |R(u)| − jarak(u), terjangkau bila f(0) ≥ 0 ≥ f(1); f turun tegas karena jarak naik 3,5/u sedangkan |R| berubah ≤ 1,8/u di ngebut), `arah_ke`, `jangkauan_maju_ubin`, `sisa_tanda`, `tanda_tampil`. Cek ulang: lintasan `ThrowSolver.hitung(panjang_untuk_kekuatan(u), …)` diterima hanya bila `ZonaSasaran.zona_kena(titik_mendarat, daftar) == zona` (lebih ketat dari "dinilai KOTAK_SURAT": zona yang menang harus kotak surat sasaran itu sendiri).
- **Tafsiran seri D-4** "lateral terkecil" = **selisih lateral pusat zona ke sepeda** terkecil (|x pusat − x sepeda|), lalu urutan daftar. Orchestrator/QA boleh menolak.
- **Satu sumber warisan kecepatan**: penjaga AC-4 Run 2A melarang `Config.LEMPAR_*` di luar `ThrowSolver`, jadi ditambahkan `ThrowSolver.geser_maju_ubin(v, u)` (dipakai juga oleh `hitung`, refaktor tanpa ubah angka) dan `ThrowSolver.panjang_untuk_kekuatan(u, lebar)` (kebalikan `kekuatan`). `BantuLempar` tidak memakai `Config.LEMPAR_*` (penjaga tetap hijau).
- **Daftar zona di scene**: `ZonaSasaran.zona_jalan_uji_rentang(maju, maju + jangkauan)` (baru) menggantikan `zona_jalan_uji_sekitar` yang SPEC sebut sebagai contoh, karena `sekitar` hanya mencakup ±1 kavling (4–8 ubin ke depan) sedangkan jangkauan lemparan sampai 10,5 ubin (ngebut); dengan `sekitar` kotak surat berikutnya sesudah rumah bukan pelanggan bisa tidak masuk daftar walau terjangkau.
- **Scene (`JalanUji`)**: `_saat_tap_selesai` → gerbang `mode bantu && !jeda && SisaKoran.boleh_lempar` → `pilihan_bantu(sisi_tap(posisi, posisi_layar_sepeda()))` → null = `KontrolTouch.tampilkan_tanda` + sinyal baru `bantu_tanpa_sasaran(posisi)`; ada = `_lempar(lintasan)`. `_lempar` dipakai bersama swipe dan tap (`SisaKoran.terima`, `KoranLempar.baru`, `_sepeda.lempar`, HUD, `koran_dilempar`). `posisi_layar_sepeda()` = posisi gambar sepeda − posisi kamera + setengah viewport (dites sama dengan transform kanvas sepeda). API publik baru: `atur_mode_bantu`, `mode_bantu`, `pilihan_bantu`, `posisi_layar_sepeda`.
- **Titik kait bagian B (bunyi)**: `koran_dilempar` tepat sekali per lemparan DITERIMA, swipe maupun tap (lemparan ditolak tidak memancarkannya); `koran_mendarat` tepat sekali per koran; `jeda_berubah` sudah ada. Didokumentasikan di kepala `jalan_uji.gd`.
- **Tanda D-6**: pola baru `PolaPiksel.TANDA_TANPA_SASARAN` (cincin 9×9, `w` = `TEXT_2`, garis luar `OUTLINE`; tidak ada token `MUTED` di Palette, jadi dipakai `TEXT_2`), digambar `KontrolTouch` (CanvasLayer, koordinat sentuhan) lewat `perintah_tanda()`; waktu `langkah_tanda(dt efektif)` dari `JalanUji.perbarui`, jadi membeku saat jeda.
- **Sakelar D-7**: `BarisTombol` (HBox) di `StripAtas` berisi `TombolKidal` lalu `TombolBantu` di tengah strip atas (tombol kidal bergeser 52 px ke kiri dari tengah; tes tata letak lama tetap hijau). Status terbaca dari teks `HUD_BANTU_MATI` "Bantu: mati" / `HUD_BANTU_NYALA` "Bantu: nyala" selain gaya ditekan. Sinyal `HudDev.bantu_diubah`, `atur_bantu`, `rect_tombol_bantu`.
- **K-1**: tidak ada kode baru; kecepatan otomatis = stick netral (santai 3,0, stamina +2/d), dites AC-6.
- **Angka baru di `config.gd`** (BALANCING 4b dan 2, commit yang sama): `BANTU_TOLERANSI_UBIN` 0,000001 (derau float di ujung u, jauh di bawah setengah lebar zona 0,25), `BANTU_CARI_ULANGAN` 48 (ketelitian u ~3,6e-15), `BANTU_TANDA_LAMA_DETIK` 0,6 (cukup terbaca, lebih pendek dari penanda 0,8 supaya tidak menumpuk saat tap berulang; usulan, dinilai di HP), `HUD_TOMBOL_JARAK_PX` 8.
- **QA-008 (AC-13)**: `tests/tes_koran_scene.gd` tidak lagi memanggil `GambarPiksel.perintah_pola`/`perintah_rentang`/`warna_huruf` sebagai oracle (`git grep` hanya menyisakan komentar). Oracle: tabel warna per huruf peran ditulis di tes (`_warna_peran`), pola dibaca per karakter, dibandingkan per piksel layar (`_peta_pola` vs `_peta_perintah`), plus titik uji eksplisit: ikon ke-3 alpha 1 dan ke-4 alpha 0,28 (`OUTLINE`/`TEXT`/`TEXT_2`), tiap piksel `w` penanda = `OK`/`FAIL` dan tiap `o` = `OUTLINE`, piksel `w` elips tertutup = `TEXT` alpha 0,5. Alpha 0,28 dan 0,5 ditulis literal dan `Config` dicek sama.

**Tes baru**: `tests/tes_bantu.gd` (murni: pembantu solver, tap ambang/tarik-kembali/dua jari/slot terisi/batal/kidal, sisi tap ~3300 titik × 5 posisi sepeda terhadap oracle garis layar 1:2, rentang zona, sasaran dasar/tepi, AC-4 grid 2880 keadaan: 5 kecepatan × 3 lateral × 3 kecepatan lateral × 2 sisi × 32 fase; 2846 bersasaran, 2870 dibandingkan dengan oracle keterjangkauan berangka BALANCING 4 literal, semua cocok; waktu tanda). `tests/tes_bantu_scene.gd` (AC-5 delapan skenario, AC-6, AC-7 di 640/780/800 kanan dan kidal). Jumlah tes 6082 → 6283.

**Tabel mutan** (dijalankan dengan skrip yang menerapkan satu mutan, menjalankan `run_tests`, menghitung `GAGAL:`, lalu mengembalikan isi berkas; `git diff` bersih dari mutan sesudahnya)

| Mutan | Berkas | Jumlah gagal |
|---|---|---|
| N16 `warna.a *= alpha` dibuang | `scripts/ui/gambar_piksel.gd` | 5 (mati) |
| N20 huruf `o` memakai warna utama | `scripts/ui/gambar_piksel.gd` | 33 (mati) |
| N21 huruf `w` dilewati | `scripts/ui/gambar_piksel.gd` | 26 (mati) |
| N22 alpha ditimpa 1 | `scripts/ui/gambar_piksel.gd` | 5 (mati) |
| M1 tap: ambang `<` jadi `<=` (`maks <= swipe_min_px`) | `touch_router.gd` | 7 |
| M2 tap: \|v\| maksimum jadi \|v\| akhir | `touch_router.gd` | 3 |
| M3 sisi tap: tanda dibalik | `bantu_lempar.gd` | 4 |
| M4 sisi tap: posisi sepeda diabaikan | `bantu_lempar.gd` | 4 |
| M5 sasaran: filter pelanggan dibuang | `bantu_lempar.gd` | 7 |
| M6 sasaran: filter "di depan" dibuang | `bantu_lempar.gd` | 3 |
| M7 sasaran: filter sisi dibuang | `bantu_lempar.gd` | 7 |
| M8 sasaran: pilih terjauh | `bantu_lempar.gd` | 4 |
| M9 sasaran: tanpa cek ulang `hitung`/`zona_kena` | `bantu_lempar.gd` | 2 |
| M10 sasaran: warisan kecepatan diabaikan di pencarian u | `bantu_lempar.gd` | 10 |
| S1 scene: gerbang jeda antar lempar dilewati untuk tap | `jalan_uji.gd` | 5 |
| S2 scene: sisa koran tidak dikurangi untuk tap (tanpa `terima`) | `jalan_uji.gd` | 11 |
| S3 scene: mode bantu diabaikan | `jalan_uji.gd` | 9 |
| S4 scene: kidal tidak dihormati (zona saat jari turun) | `touch_router.gd` | 19 |
| S5 scene: tanda tanpa sasaran tidak ditampilkan | `jalan_uji.gd` | 4 |
| S6 scene: tanda tidak pernah hilang | `jalan_uji.gd` | 1 |
| S7 scene: posisi layar sepeda tanpa kamera | `jalan_uji.gd` | 32 |
| S8 scene: gerbang jeda game dilewati untuk tap | `jalan_uji.gd` | 2 (awalnya 0: tes jeda game menap saat jeda antar lempar belum lewat; tes diperkuat menunggu 0,4 detik dulu, lalu mati) |

**Belum selesai / catatan**
- Bagian B (pemanggilan Dev berikutnya): bunyi lempar dan mendarat (D-9..D-13, AC-9..AC-12), `kontrol.html` dan DESIGN_SPEC 6 (AC-14), GDD 4.2 (AC-15), checklist `SETUP_ANDROID.md` 8 (AC-16), SOUND_DESIGN, `00-project-core.mdc`/`docs/README.md`, dan tangkapan layar AC-19 (tombol bantu mati/nyala, koran bantu, tanda tanpa sasaran, kidal + bantu). Pemeriksaan visual cepat lewat `probe_koran_jendela.gd` (di scratchpad, tidak di-commit): tombol "Kidal" dan "Bantu: mati" berdampingan di tengah strip atas, tidak menumpuk tombol jeda atau panel.
- Tidak ada BLOCKED.

