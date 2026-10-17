# Loop Log — 20261018-fase4a-koran-hari
Scope: Run 4A — halaman depan koran, format misi dan headline, HeadlineManager, SaveManager v1, alur satu hari  ·  Branch: feat/koran-hari-4a  ·  Mulai: 2026-10-17  ·  Godot: 4.7.2.stable

## Status: IN_PROGRESS   (iterasi saat ini: 1/2, Dev selesai, menunggu QA)

Baseline (main 2910bed, sebelum perubahan): `godot --headless --import` bersih; `run_tests.gd` = 10907 lolos, 0 gagal; `tools/cek_keluaran_tes.py` lolos (0 peringatan).

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 1 | Seluruh AC-1 sampai AC-29: seed, mesin hari, save v1 + `SaveManager`, format dan pemuat misi/headline, konten hari 1-3, `HeadlineManager`, layar koran + palet krem, `hari.tscn` sebagai scene utama, tes (alur, layar, data, export), 19 mutan, probe jendela 4 resolusi, dokumen | import bersih; `run_tests.gd` 12963 lolos, 0 gagal (baseline 10907) dan `cek_keluaran_tes.py` lolos (0 peringatan); `--quit-after 2` tanpa ERROR/WARNING; `uji_pemeriksa` 16 kasus, `uji_bangun_frames` 51, `uji_sintesis_{sepeda,lempar,rute}` 32/111/90 lolos; `--export-pack` memuat JSON misi dan headline, terjemahan, scene baru, tanpa tests/docs/tools, dan pemuat jalan dari paket di folder luar repo; git bersih | (menunggu QA) | - | - |

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## Mutan (AC-26, diisi Dev; QA mengulang sedikitnya 5)
| # | Mutan (file, perubahan) | Tes yang merah | Dikembalikan |
|---|---|---|---|
| 1 | HeadlineManager mengabaikan jeda (`_headline_boleh` selalu true) | 6 gagal: `lanjutan yang masih dalam jeda tidak muncul lagi`, `60 hari berantai: tidak ada headline yang muncul di dalam jeda`, `dua dari tiga kandidat dalam jeda...` | ya |
| 2 | `randi()` global menggantikan RNG berseed di `_undi` | 7 gagal: `40 hari x 5 pemanggilan berulang: halaman selalu sama persis`, `flag yang tidak dikenal data diabaikan...`, `adanya lanjutan tidak mengubah undian berita utama` | ya |
| 3 | Lanjutan tidak diprioritaskan (`_pilih_lanjutan` mengembalikan null) | 11 gagal: `hari N flag kucing_belum: slot misi = headline lanjutan`, `... kucing_ketemu: slot ringan ...` | ya |
| 4 | `bobot` diabaikan (`total += 1`) | 4 gagal: distribusi 2000 benih di luar 4 sigma untuk bobot [1,3], [1,2,5], [4,1] | ya |
| 5 | Simpan dipanggil saat Berangkat (`HariMain._saat_berangkat`) | 13 gagal: `Berangkat: nol simpan`, `sampai layar hasil terbuka belum ada simpan sama sekali`, `'Hari berikutnya': tepat satu simpan` | ya |
| 6 | Save ditulis langsung tanpa berkas sementara (`sementara = jalur`) | 3 gagal: `simpan gagal bila berkas sementara tidak bisa dibuat`, `berkas save lama utuh byte demi byte ...`, `kode SaveManager menulis ke berkas sementara lalu rename` | ya |
| 7 | Migrasi menjatuhkan `flag` (`hasil.erase("flag")` sebelum penggabungan templat) | 1 gagal: `flag dipertahankan (termasuk yang tidak dikenal data)` | ya |
| 8 | Save rusak ditimpa tanpa salinan (`jalur_salinan_rusak = ""`, tanpa `_salin_rusak`) | 7 gagal: `berkas lama disalin utuh ke save.corrupt.<detik>.json` (tiga kasus), salinan kedua, tes alur `save rusak` | ya |
| 9 | `catat_hari` tidak menambah `koin_tip` ke `tip_total` | 4 gagal: `tip_total = 50 + angka.koin_tip`, `300 hari acak: state sama dengan oracle`, `isi berkas: ... tip_total 30` | ya |
| 10 | Koin dihitung ulang di `HariMain` (`catatan.angka.koin += 1`) | 3 gagal: `isi save: hari 2, koin 120, tip_total 25 (dari Angka yang sama)`, `terakhir = angka layar hasil ...`, `Lewati: koin tidak berkurang` | ya |
| 11 | Berangkat ganda memulai dua rute (hapus tolak `diterima`) | 1 gagal: `Berangkat diketuk empat kali: tepat satu rute (dibuat 4, anak 4)` | ya |
| 12 | `SeedHari.campur` konstan (`return dasar`) | 7 gagal: seed literal hari 1, 2, 60 dan headline, `campur(dasar, hari)`, 60 seed berbeda | ya |
| 13 | Panjang headline tidak divalidasi (`if false:` di `AturanTeks.periksa_kunci`) | 5 gagal: `headline 41 karakter ditolak`, `ringkasan 61 ...`, `hud 15 ...`, petunjuk 51 | ya |
| 14 | `MesinHari`: Hari berikutnya menaikkan hari 2 | 9 gagal: `hari naik tepat 1`, `satu hari utuh berakhir di KORAN hari 4`, `lima hari berturut-turut` | ya |
| 15 | `MesinHari.aksi_back(HASIL)` = KELUAR_APP | 2 gagal: `back di layar hasil = diabaikan` (murni dan scene) | ya |
| 16 | Tombol Ambil minimum 30 px (`KORAN_TOMBOL_PILIH_LEBAR_PX`) | LOLOS pada percobaan pertama (teks memanjangkan tombol ke >= 42); tes ditambah `ukuran minimum tombol >= 42 px, tidak bergantung pada panjang teks`, ulang: 8 gagal | ya (setelah perkuatan tes) |
| 17 | `KORAN_TINTA_2` jadi `#A09070` (kontras rendah) | 15 gagal: paritas DESIGN_SPEC 1.1, `kontras TINTA_2 di KERTAS = 2.54:1`, kontras label dan tombol | ya |
| 18 | `catat_hari` mengurangi koin dengan jumlah meleset | 9 gagal: `koin = 1000 + angka.koin`, `300 hari acak: ... tidak pernah turun`, oracle | ya |
| 19 | Lewati menjatuhkan penalti koin 1 | 8 gagal: `300 hari acak: ... tidak pernah turun`, `hari dengan koin 0 tidak mengurangi koin`, oracle | ya |

Cara: skrip pembantu mengganti satu potongan kode asli, menjalankan `run_tests.gd`, lalu `git checkout -- <berkas>`; `git status` bersih sesudah semua mutan (dicek). Dua belas mutan yang diwajibkan SPEC AC-26 ada di nomor 1, 2, 3, 4, 5, 6, 7, 8, 9 (tip), 10 (koin dihitung ulang di UI/HariMain), 11, 12, 13.

## NEEDS-MANUAL (uji di HP)
- [ ] Layar koran terbaca dalam 10 detik di A54 dan vivo V2108; krem tidak menyilaukan.
- [ ] Ambil, Lewati, Berangkat terasa pas (target sentuh), Ambil/Lewati bisa dibolak-balik.
- [ ] Alur satu hari: Koran → Rute → Hasil → "Hari berikutnya" → Koran hari 2 (headline dan rute berbeda dari hari 1).
- [ ] Force stop app di tengah rute, buka lagi: koran hari yang sama, progres kemarin utuh (JANGAN `pm clear`).
- [ ] Back Android: koran = keluar, rute = jeda, hasil = diabaikan.
- [ ] Sakelar Kidal/Bantu yang diubah di jeda bertahan ke hari berikutnya.

## Keputusan & catatan
- Keputusan pemilik 2026-10-17: tetap mulai walau uji HP Fase 3 kosong; koran "Warta Kring", perumahan "Perumahan Melati"; layar hasil "Hari berikutnya" saja; tutup di tengah rute = ulang hari dari layar koran; misi lintas hari ditunda ke 4B.
- Keputusan orchestrator S-1 sampai S-8 di SPEC (usulan, bisa ditolak di review).
- Catatan untuk PR: `allowBackup` (rule save-system: aktif; preset export: false) — tanyakan pemilik, jangan diubah di run ini.
- PR #38 (docs perintah Fase 4) masih terbuka di branch `docs/perintah-run-fase4`; tidak disentuh run ini.

### Catatan Dev iterasi 1 (penyimpangan, keputusan kecil, dan hal untuk ditinjau pemilik)
- **S-2 diterapkan:** JSON memuat KUNCI terjemahan; teks di `translations/konten.csv` (baru, didaftarkan di `project.godot`, `.csv.import` dan `.translation` ikut di-commit) untuk headline dan misi, dan `translations/ui.csv` untuk label layar (`KORAN_*`, `HASIL_HARI_BERIKUTNYA`). `run_tests.gd` kini membaca kedua CSV (awalan `KORAN_` dan `MISI_` ditambah; tes menolak kunci tidak ada dan kunci yatim di awalan baru; rule `content-data` diperbarui). Selisih dari contoh literal DATA_SCHEMA sudah ditulis di dokumen.
- **Layar hasil:** `LayarHasil.atur_mode_hari(true)` mengganti tombol jadi `HASIL_HARI_BERIKUTNYA` dan memancarkan `hari_berikutnya_diminta`; tanpa mode itu (rute.tscn sendiri: probe, tes 3A-3C, dev) tombol tetap "Main lagi" persis seperti 3C, jadi tes lama tidak diubah. "Main lagi" dari banner galat muat di dalam alur hari memakai seed + 1 (bukan seed hari); keadaan galat saja, tidak ada keputusan baru.
- **Scene utama:** `hari.tscn` (S-1). Tes yang menyebut scene utama diperbarui (alasan di pesan): `run_tests.gd` (`BERKAS_SCENE_UTAMA`), `tes_input_scene.gd`, `tes_rute_scene.gd`, `tes_cek_render.gd`, dan `tools/ekspor_cek_render.py` (`SCENE_UTAMA`, mengganti baris `run/main_scene` hanya saat ekspor probe). Tidak ada tes lama yang dihapus atau di-skip; jumlah tes naik dari 10907 ke 12963.
- **Tanpa autoload `DayManager`:** `HariMain` memegang alurnya; ia memakai `SaveManager` lewat jalur node `/root/SaveManager` (atau objek yang disuntik sebelum masuk pohon, dipakai tes). Bila autoload tidak ada, `HariMain` membuat satu sendiri (jalur save asli).
- **Definisi save rusak (AC-9 vs AC-10):** tipe salah di tingkat atas (`hari`, `koin`, `tip_total` bukan angka; `flag` bukan daftar; `misi_jeda`, `headline_jeda`, `terakhir`, `pengaturan` bukan objek; `versi` bukan angka), JSON rusak, bukan objek, kosong = RUSAK (disalin, state bawaan, notifikasi). Nilai tidak sah DI DALAM blok (negatif, tipe salah, flag bukan teks, volume di luar 0..1) dijepit atau diganti bawaan tanpa notifikasi (AC-10). Save tanpa `versi` = v0, digabung templat.
- **Jeda:** headline `jeda` dari hari tampil, misi dari hari diambil (S-4); hari 1 selalu P1 walau `misi_jeda` mengatakan lain (tutorial mendahului jeda). Bila semua kandidat headline dalam jeda, yang jedanya PALING CEPAT berakhir dipilih (tafsiran "paling lama lewat"; seri = urutan pustaka). Jeda headline lanjutan 30 hari karena flag tidak dihapus sesudah headline tampil (aturan konsumsi flag di 4B); flag belum pernah ditulis permainan di 4A jadi lanjutan belum muncul di permainan (hanya lewat tes).
- **Headline lanjutan slot misi:** `slot: misi` wajib punya tepat satu dari `misi` (id misi lanjutan yang ada) atau `misi_ditunda: true`. `kucing_belum` memakai `misi_ditunda`: headline tampil di baris misi tanpa tombol Ambil/Lewati dan tanpa teks "tidak ada misi". `kucing_ketemu` slot `ringan`.
- **AC-20:** Ambil dan Lewati menghasilkan save yang sama kecuali `terakhir.misi_diambil` DAN `misi_jeda` (misi yang diambil memicu jeda 7 hari, S-4; yang dilewati tidak memicu jeda). Itu bukan penalti. `DataSave.catat_hari` sendiri sama persis bila catatan jeda sama (dites).
- **Layar koran:** efek berita utama tidak ditampilkan sebagai teks tambahan di layar (hanya headline) supaya penguji tidak mengira efek berlaku; `efek` ada di `Halaman` dan di data. Tema: `JudulBesar` (Lilita One 24) ditambah ke `assets/ui/theme.tres` (DESIGN_SPEC 1.2 sudah menyebut ukuran 24). Token palet baru: `KORAN_KERTAS` `#F2E7C9`, `KORAN_KERTAS_2` `#E6D8B1`, `KORAN_TINTA` `#1C130F` (14,8:1), `KORAN_TINTA_2` `#4A3A2C` (8,8:1 di kertas, 7,7:1 di kertas kedua), `KORAN_GARIS` `#7A6642` (4,5:1; komponen). Tabel DESIGN_SPEC 1.1 kini 22 token (tes paritas diperbarui dari 17).
- **Tes save:** I/O hanya di `user://tes_save_4a/` dan `user://tes_save_4a_alur/` (dihapus lagi); `user://save.json` dicek ada/ukuran/sha256 sebelum dan sesudah (di mesin ini tidak ada). `SaveManager.lapor_ke_log` false di tes supaya `ERROR:` yang disengaja (simpan gagal) tidak mengotori log (pemeriksa keluaran menolak `ERROR:`).
- **Konten untuk ditinjau pemilik (budaya dan tulisan):** "Warga Hias Jalan untuk Tujuh Belasan", "Hajatan Warga Digelar Hari Ini" (ditulis netral), "Mati Lampu Semalam, Pagi Masih Redup", nama rekaan "Warung Bu Inah" dan "Blok B"; tiga berita utama (hujan deras, air pasang, panen raya) `aktif: false` karena distrik lain. Tabel hari 1-3 di CONTENT_GUIDE 8 dijaga tes.
- **HP:** tidak disentuh (tanpa adb). Probe jendela dijalankan di desktop (2340x1080, 1920x1080, 2400x1080, 1600x720; tangkapan di `shots/iter1/`, 10 keadaan per resolusi; semua 0 keadaan tidak sesuai: teks tidak terpotong, kontrol dalam layar dan tidak bertumpuk).
- **Untuk PR (jangan diputuskan Dev):** (1) `allowBackup`: rule save-system menulis `allowBackup="true"`, preset export saat ini false (SETUP_ANDROID, usulan run 0C); sekarang save sungguhan ada, jadi tanyakan pemilik, rekomendasi samakan sebelum rilis (Fase 14); tidak diubah di run ini. (2) Efek berita utama belum berlaku (S-5), tulis di deskripsi PR. (3) Alur hari berurutan = prototype, ROADMAP 5 tetap terbuka. (4) Kalimat tutup di tengah rute: save kemarin utuh, hari yang sama diulang dari koran. (5) Fase 3, Fase 4, M2 tidak dicentang.
- **Belum dikerjakan oleh Dev (sengaja):** centang DEV_PHASES, menandai apa pun "dikunci", misi kucing dan HUD misi (4B), audio koran, ikon efek, aset kucing.
