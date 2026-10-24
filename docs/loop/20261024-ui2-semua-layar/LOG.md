# Loop Log — 20261024-ui2-semua-layar
Scope: Run UI-2 — redesain UI langkah 3-6 (hasil, koran, jeda, tutorial, banner, tombol jeda HUD) dalam satu PR  ·  Branch: feat/ui2-semua-layar (dari main d16b3bb, 0.7.0)  ·  Mulai: 2026-10-24  ·  Godot: 4.7.2.stable.official.ed1daf0bf

## Status: IN_PROGRESS   (iterasi 1/2; bagian A selesai)

## Lingkungan (orchestrator, awal run)
- Basis: `main` = `origin/main` = `d16b3bb` (rilis 0.7.0; memuat PR #64 UI-1). Branch dibuat dari sana.
- `adb devices`: tidak ada perangkat tersambung pada 2026-10-24 awal run.
- sha256 save asli: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e`.
- `.claude/` untracked: bukan bagian run, tidak di-commit.

## Amandemen scope (orchestrator, 2026-10-24, sebelum Dev A)
Pemilik menambah dua permintaan setelah SPEC ditulis: font bengkel dan hasil terlalu kecil, dan HUD diatur ulang (kecepatan dan stamina menumpuk). Menjadi V-8 (skala font +2, semua layar penuh, bengkel ikut) dan V-9 (H-1 panel bawah berdampingan, H-2 kolom kanan atas dipadatkan, H-3 tombol jeda) di SPEC; menggantikan V-6, AC-6, AC-8 versi awal. Catatan Dev per tes yang diubah wajib di bagian masing-masing.

## Butir terbuka pemilik
- Lisensi latar bengkel (UI-1) belum dicatat; belum boleh masuk rilis (ART_DIRECTION 9).
- Keputusan QA-003/D-1/D-2 UI-1 (kontras garis kartu, margin inset).
- Lapisan jeda 72 % (V-2) dinilai di HP.

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## Baseline (AC-1; diisi Dev bagian A, 2026-10-24, pohon kerja bersih di `b637062`, `main` + UI-1)
- `godot --headless --import`: tanpa ERROR/WARNING (0 baris).
- `run_tests.gd`: **23406 lolos, 0 gagal**; `tools/cek_keluaran_tes.py`: "lolos (23406 lolos, 0 gagal, 0 peringatan)".
- Semua `tools/tests_cek/uji_*.py` (17 berkas): exit 0 semua (aset_fase3, aset_gelombang1, aset_kucing, aset_lampu_pohon, aset_pasang_5b, aset_pasang_gelombang1, aset_simpang, bangun_frames, pemeriksa, sintesis_{kondisi,lempar,milestone,misi,rute,sepeda}, ui_lencana, ui_redesain).
- sha256 save asli sebelum dan sesudah baseline: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e` (tidak berubah).
- Tangkapan "sebelum" (jendela asli, 1920x1080 dan 2340x1080) di `shots/baseline/`: `bengkel_*` (probe_bengkel, 0 keadaan tidak sesuai), `hud_*` (probe_hud_rute: HUD, layar jeda `hud_jeda_sakelar`, layar hasil `hud_hasil_*`), `reputasi_*` (probe_reputasi: HUD reputasi dan layar hasil tujuh keadaan + inset + dari rute nyata), `koran_*` (probe_halaman_koran), `misi_*` (probe_misi: banner `misi_banner_*`, tutorial `misi_tutorial_lempar`, hasil `misi_hasil_*`). Semua probe: "probe selesai, 0 keadaan tidak sesuai".

## Bagian A — komponen tambahan + Hasil

### A1 — Skala font V-8 (selesai)
**Hasil: kenaikan PENUH (+2) terpasang untuk SEMUA elemen target; tidak ada elemen yang turun ke +1.**
- `assets/ui/theme.tres`: `LayarTeksUtama` 10 -> 12, `LayarTeksKecil` 9 -> 11, `LayarTeksMini` 8 -> 10, `LayarLabel` 8 -> 10, `TombolPeran` dan `TombolTipis` 10 -> 12, `ChipTeks` 10 -> 12, `ChipTeksBesar` 12 -> 14, `ChipTeksKecil` 8 -> 10. `LayarJudul` 24 tidak berubah. Variation HUD lama (`HudLabel`, `HudAngka`, `HudTeks`, `TeksKecil`, `JudulLayar`, `JudulBesar`) tidak diubah.
- Tinggi baris Lexend terukur (`Font.get_height`): 10 px = 13, 11 px = 14, 12 px = 15, 14 px = 18. Lebar terukur: "Ban Anti-Selip" 87 px (12 px SemiBold), "Rantai Hemat" 84 px, "Rem Pakem Racing Edition" (24 huruf) 163 px.
- `scripts/config.gd` (angka layout bengkel menyesuaikan, ukuran slice aset TIDAK berubah): chip kecil/normal/besar 14/18/24 -> **16/20/26** (`UI_CHIP_TINGGI_*`, pad vertikal kecil 2 -> 1); `BENGKEL_BAGIAN_TINGGI_PX` 12 -> 14; `BENGKEL_CATATAN_TINGGI_PX` 12 -> 14; `BENGKEL_PANEL_PAD_PX` 8 -> 6; kartu upgrade 62 -> **70** (tingkat tunggal) dan 72 tetap (bertingkat); kartu servis tetap 50 (jarak teks servis 3 -> 2, jarak baris status 2 -> 1); `BENGKEL_KARTU_JARAK_PX` 6 -> 4 -> 3 dan `BENGKEL_KARTU_PAD_AWAL_PX` 8 -> 6 (supaya nama upgrade nyata muat penuh di kolom upgrade sampai isi 580 px, inset aman 36 + 24); baru `BENGKEL_DESKRIPSI_BARIS_JEJAK_MAKS` 2 (kartu bertingkat), `BENGKEL_DESKRIPSI_BARIS_MAKS` 2 -> 3 (kartu tunggal; deskripsi nyata "Stamina awet dan rantai lebih tahan" butuh 3 baris di kolom 296 + inset), `BENGKEL_DESKRIPSI_JARAK_BARIS_PX` 1 (bawaan Label 3).
- `scripts/ui/layar_bengkel.gd`: jatah baris deskripsi per kartu (`max_lines_visible` 3 atau 2 bila ada jejak) dan jarak baris deskripsi dari Config. Struktur, sinyal, API, perilaku tidak berubah.
- Anggaran tinggi di 360: panggung sepeda tetap >= 82 (sepeda 78 + 4) di semua keadaan termasuk inset bawah 20; tiga kartu upgrade + judul bagian + jarak berakhir sebelum tombol "Hari berikutnya" (diperiksa probe: kartu tidak menutupi tombol, termasuk dengan inset).
- Probe `probe_bengkel_jendela.gd` (diperluas: cek kartu tidak menutupi "Hari berikutnya"): **0 keadaan tidak sesuai** di 1920x1080 (640), 2340x1080 (780), 2400x1080 (800), 1600x720 (800). Tangkapan di `shots/iter1/`. Kontras (`tools/ukur_kontras_tangkapan.py`, 1920x1080): semua teks >= 7,79:1 (terburuk "! Ban" 7,79; "Baik" 8,28), tombol >= 8,53:1; garis kartu 1,14..1,65:1 dan tombol nonaktif 1,14:1 (D-1 UI-1, tidak berubah, bukan kontrol aktif).
- Perubahan terukur: tinggi tinta "Rem Pakem" 7 -> 9 px game (+2), baris kecil "Perlu servis" 6,3 -> 7,7, "Banyak yang rusak..." 9 -> 11 (ukur kasar dari tangkapan 1920x1080 keadaan b, sebelum vs sesudah).
- Perbedaan tangkapan bengkel vs baseline UI-1: hanya ukuran huruf, tinggi chip, tinggi kartu upgrade, jarak baris, dan letak elemen yang bergeser karenanya (struktur sama).

Tes lama yang diubah (V-8; semua karena angka ukuran, bukan perilaku):
| Tes | Perubahan | Alasan |
|---|---|---|
| `tests/tes_komponen_ui.gd` `_test_tema` | ukuran font yang dijaga 10/9/8/10/8/12/10/10 -> 12/11/10 (Mini, ditambah)/10/10/14/12/12 | V-8 |
| `tests/tes_komponen_ui.gd` (dua `check`) | tinggi chip 14/18/24 -> 16/20/26 (`Config` dan `KomponenUi.tinggi_chip`) | V-8: tinggi baris Lexend 13/15/18 tidak muat di 14/18/24 |
| `tests/tes_tampil_bengkel.gd` | tinggi kartu upgrade tunggal 62 -> 70, bertingkat 72 (tetap) | V-8 |
| `tests/tes_bengkel_tata_c.gd` | chip Baik 18 -> 20, chip penanda 14 -> 16, chip saldo/harga 24/18 -> 26/20, kartu upgrade tunggal 62 -> 70, kartu servis tetap 50, jejak 72 tetap, komentar jatah baris deskripsi | V-8 |

### A2 — Komponen tambahan untuk Hasil (selesai)
- `tools/ui_art/redesain/pasang.py` (daftar tunggal) diperluas dan `komponen.py --salin` memasang HANYA yang dipakai hasil: `ui_struk` (9-slice 12x12), `ui_struk_takik` (6x10), `ui_icon24_{koin,bintang,lencana_perunggu,lencana_perak,lencana_emas}`, `ui_lencana32_{perunggu,perak,emas}` (sel dari sheet lencana32; sel "belum" tidak dipasang), `ui_glif_naik_ok`, `ui_glif_turun_teks2` = 12 berkas baru (total redesain terpasang 42). `kertas_tile`, `koran_*`, `foto_*`, sheet lencana32 utuh tetap tidak dipasang (bagian B memakai yang koran). `.import` Lossless, tanpa mipmap, bukan VRAM (diuji).
- `GayaHud`: `struk()` baru (tepi bergerigi diulang `TILE_FIT` seperti `border-image: round` kanvas); `_TEKSTUR` diperluas; fungsi dan variation lama tidak diubah. Theme: variation BARU `LayarAngkaBesar` (Lilita One 32, font sama dengan judul; tanpa font/palet baru).
- `tools/tests_cek/uji_ui_redesain.py` diperluas: lencana 32 = sel sheet, slice struk = `Config.UI_PANEL_SLICE_PX`, `lencana32` masuk daftar sumber yang dipasang (set tepat 42 berkas; hasil uji: LOLOS). `tests/tes_export.gd`: aset hasil + skrip/scene hasil ikut paket, awalan "tak dipasang" dipersempit (`ui_lencana32.` sheet, bukan `ui_struk`). `--export-pack`: struk, takik, lencana32, ikon24 koin, glif naik, `tampil_hasil.gd`, `garis_sobek.gd`, `layar_hasil.tscn` ada; `ui_koran_*`, `ui_kertas_tile`, `ui_foto_*`, sheet `ui_lencana32.png`, sepeda besar, dan tes/probe hasil tidak ada.
- Aset lama `ui_lencana_{perunggu,perak,emas}.png` (14x14, run 6A2) tidak lagi dipakai skrip mana pun sesudah layar hasil baru; DIBIARKAN (masih dijaga `uji_ui_lencana.py` dan `tes_export`), tidak dihapus tanpa keputusan: usulan hapus di bagian D bila orchestrator setuju.

### A3 — Layar hasil sebagai struk antaran (selesai)
- Kode baru: `scripts/systems/tampil_hasil.gd` (`TampilHasil`, murni: `tata` = margin max(12, inset), lebar struk/kolom 640..800, letak tombol 140x42 kanan bawah, batas bawah kolom, geser struk tanpa samping dari baris tombol, kolom sejajar struk hanya bila muat; `delta_reputasi`, `glif_terkirim`, nama lencana, `ada_samping`, baris kondisi), `scripts/ui/garis_sobek.gd`, `scripts/ui/garis_titik.gd`; `layar_hasil.tscn` dan `layar_hasil.gd` ditulis ulang (anchor + Container). Sinyal (`main_lagi_diminta`, `bengkel_diminta`), `isi(...)` dan semua API tes/probe lama tetap; baru: `atur_inset`, `rect_judul`, `rect_kartu`, `chip_reputasi`, `tata`. Teks tetap dari `translations/` (tanpa kunci baru), angka dari `HasilRute`.
- Sesuai kanvas: struk bergerigi dengan garis sobek bertakik (takik menempel tepi luar), angka "Terkirim" (glif centang: hijau hanya bila semua terantar) dan "Koin" (ikon koin 24) 32 px, baris berurut berhasil (Tip hijau, Skor, Tepat aksen), rekap misi selesai (bercentang) di bawah baris berhasil, baris netral (Meleset, Koran terbuang, Koin bersih), saldo dijepit, tenggat, rekap misi gagal, baris kondisi (glif "!" WARN); kolom samping 236 (300 di lebar 800): kartu reputasi (bintang, angka Lilita 24, chip perubahan dengan glif naik/turun), kartu pelanggan (jenis bukan nol), kartu target (lencana 32, nama, bilah 7 + n/target atau teks tamat), tingkat baru dengan ikon lencana 24; tombol aksi utama 140x42 kanan bawah (peran utama); tanpa data reputasi struk 360 ke tengah; inset aman.
- Penyimpangan dari kanvas (usulan, bisa ditolak): (1) label kapital kanvas ("TERKIRIM") tampil huruf biasa dengan spasi huruf, karena kunci teks `HASIL_*` tidak boleh berubah (V-3 hanya dua kunci baru); (2) teks "Koin" tetap "{n}" tanpa tanda "+" (tes lama menjaga "300"); (3) baris kondisi: teks `TEXT` dengan glif "!" `WARN` (teks WARN di atas isi struk 6,91:1 < 7:1); (4) di kasus terpadat kolom samping naik sejajar judul (y 12, bukan 44) karena pada huruf V-8 kolom 3 kartu + 3 tingkat baru tidak muat di atas tombol; di kasus ringan tetap sejajar struk (y 44); (5) struk tanpa samping yang cukup tinggi digeser ke kiri (x 122 di 640, bukan tengah 140) supaya tidak menutupi tombol; (6) bilah milestone tanpa garis sorot `#FFE08A` (bukan token Palette; tanpa palet baru); (7) angka Koin 10 digit berelipsis (kasus tak realistis).
- Tangkapan di `shots/iter1/` (`<ukuran>_hasil_<keadaan>.png` + `.json`): a_biasa, b_minus, c_semua_terkirim, d_lewat_tenggat, e_pelanggan, f_milestone_baru, g_semua_emas, h_terpadat, i_tanpa_reputasi, j_tanpa_reputasi_terpadat, k_main_lagi, l_angka_besar, m_inset_terpadat, n_inset_biasa, o_dari_rute (rute nyata) di 1920x1080 (640), 2340x1080 (780), 2400x1080 (800), 1600x720 (800). Probe `tests/probe_hasil_jendela.gd` (baru): **0 keadaan tidak sesuai di keempat ukuran** (zona aman, tumpang tindih struk/kolom/tombol/label, teks terpotong, tombol >= 42x84, lebar sesuai `TampilHasil.tata`, kolom di atas tombol). Saya MELIHAT tangkapan a, b, h, j, m (1920x1080) dan h (2400x1080) dan membandingkan dengan `Hasil*.dc.html`: struktur, takik, jarak, dan kolom cocok; selisih tertulis di atas.
- Kontras (`tools/ukur_kontras_tangkapan.py`, diperluas `--jenis hasil`): terburuk **7,34:1** (Tip hijau `OK` di atas isi struk) di semua 15 keadaan x 4 ukuran, tidak ada teks < 7:1; garis tombol utama 14,16:1; garis kartu 1,66:1 dan struk 1,02:1 (wadah non-kontrol, seperti QA-003 UI-1).
- Perilaku/ukuran: ukuran huruf V-8 di hasil: judul 24, angka 32, baris berhasil 12, netral dan pelanggan 11, label 10 (tinggi tinta tertinggi dijaga tes).
- Dua celah yang ditemukan sambil membangun dan ditutup tes: (a) `remove_child`+`add_child` untuk memindah baris rekap menghapus pemilik node dan nama unik `%RekapMisi` (tes lama menangkapnya); diganti `move_child`; (b) tinggi struk/kolom baru benar sesudah Container menghitung bungkus kata, jadi tata letak mendengarkan `resized` struk/kolom (maks 8 kali per frame, sisanya frame berikutnya).

Tes lama yang diubah (A3; semua karena tombol kini di kanan bawah di luar struk dan judul di atas struk, bukan perilaku):
| Tes | Perubahan | Alasan |
|---|---|---|
| `tests/tes_hud_rute_scene.gd` smoke layar hasil | "tombol di dalam panel" -> tombol di dalam layar dan tidak menutupi struk | tombol aksi utama kini di kanan bawah (AC-2) |
| `tests/tes_kondisi_scene.gd` hasil lima ukuran | sama; teks "di dalam panel" -> "di dalam struk" | idem |
| `tests/tes_potongan_scene.gd` layar hasil | sama | idem |
| `tests/tes_misi_scene.gd` tata letak | sama; tombol tidak menumpuk rekap dan struk | idem |
| `tests/tes_reputasi_scene.gd` | kolom samping terpisah dari struk (bukan di dalam panel); lencana baru memakai `LayarHasil.LENCANA_BARU` (ikon 24) dan target `LENCANA` (32); chip perubahan reputasi (`chip_reputasi()`) menggantikan label `NilaiReputasi`: warna OK/TEXT_2, teks "+2"/"-1"/"+0", glif; tanpa samping struk 360 menggantikan panel ~300; inset aman diterapkan lewat `atur_inset` | desain baru |
| `tests/probe_reputasi_jendela.gd` `_cek_hasil` dan `_hasil_inset` | pemeriksaan struk/kolom/tombol terpisah, inset diterapkan | idem |
Tes baru: `tests/tes_tampil_hasil.gd` (murni, oracle kanvas literal) dan `tests/tes_hasil_struk.gd` (scene: aset, struk, takik, rekap misi, kolom, geser, tombol, enam ukuran terpadat dengan/tanpa samping, inset, kontras, huruf, teks panjang), terdaftar di `run_tests.gd`.

### Mutan nyata bagian A (34 dari 34 tertangkap)
Satu perubahan per mutan, runner kecil (`TesTampilHasil` + `TesHasilStruk` + `TesKomponenUi`), `git checkout` sesudah tiap mutan, kode di-COMMIT lebih dulu (`3f441f6`). Putaran pertama: 28 tertangkap, 6 lolos (A20 kolom samping hanya bila reputasi, A21 kartu pelanggan selalu tampil, A22 baris terbuang tampil walau nol, A24 pengisi kolom selalu tampil, A25 lencana baru tergeser tingkat, A26 blok kondisi selalu tampil); ditutup dengan `_test_bagian_tampil_dan_sembunyi` dan satu cek posisi kartu pertama; putaran ulang keenamnya: semua tertangkap.
| Mutan | Perubahan | Tertangkap oleh |
|---|---|---|
| A01 | `lebar_kolom` 800 tepat memakai 236 | "lebar 800: kolom 300" |
| A02 | jarak struk-kolom 10 dihapus | tata 640: struk 370 |
| A03 | tombol memakai margin atas | tata inset |
| A04 | batas kolom dari dasar tombol | tata 640: batas 300 |
| A05 | geser struk di batas tepat (`>=`) | "struk 256 belum digeser" |
| A06 | geser struk salah arah | "struk 257 digeser x 122" |
| A07 | kolom_atas batas tepat (`<`) | "kolom 256 tepat muat" |
| A08 | delta nol dianggap naik | "nol: netral tanpa glif" |
| A09 | delta turun bergaya WARN | "turun 1: netral" |
| A10 | semua terantar tepat bukan hijau | glif_terkirim |
| A11 | 0 dari 0 hijau | glif_terkirim |
| A12 | indeks lencana 24 tergeser | nama tekstur lencana |
| A13 | batas tiga baris kondisi hilang | jumlah_baris_kondisi |
| A14 | ada_samping `and` | ada_samping |
| A15 | goresan sobek tanpa celah | segmen sobek |
| A16 | takik akhir keluar struk | takik menempel tepi |
| A17 | jarak titik bertambah | letak_titik |
| A18 | rekap selesai di posisi gagal | posisi rekap |
| A19 | glif misi tampil saat gagal | rekap gagal tanpa glif |
| A20 | kolom hanya bila reputasi | hanya milestone (setelah ditambah) |
| A21 | kartu pelanggan selalu tampil | semua nol (setelah ditambah) |
| A22 | baris terbuang tampil walau nol | tanpa terbuang (setelah ditambah) |
| A23 | tinggi tombol memakai lebar | terpadat (offset tombol) |
| A24 | pengisi kolom selalu tampil | kartu pertama y 12 (setelah ditambah) |
| A25 | lencana baru tergeser | indeks lencana baru (setelah ditambah) |
| A26 | blok kondisi selalu tampil | tanpa kondisi (setelah ditambah) |
| A27 | struk memakai `panel_layar` | tekstur struk |
| A28 | tepi struk tidak diulang | `TILE_FIT` |
| A29 | struk tanpa samping 340 | tata tanpa samping |
| A30 | angka Koin bukan ACCENT | warna angka |
| A31 | baris Tip huruf 11 | ukuran huruf |
| A32 | nama baris kondisi sama | galat skrip (find_child) |
| A33 | teks kondisi WARN | warna teks kondisi (< 7:1) |
| A34 | `HASIL_KOLOM_ATAS_PX` 0 | kolom sejajar struk |

### Gerbang bagian A (2026-10-24, keluaran nyata)
- `godot --headless --import`: 0 baris ERROR/WARNING. `godot --headless --path . --quit-after 2`: 0 baris ERROR/WARNING.
- `run_tests.gd`: **24009 lolos, 0 gagal**; `tools/cek_keluaran_tes.py`: "lolos (24009 lolos, 0 gagal, 0 peringatan)" (baseline 23406; +603 pemeriksaan: tes baru hasil dan komponen).
- 17 berkas `tools/tests_cek/uji_*.py`: exit 0 semua (termasuk `uji_ui_redesain.py` diperluas).
- `godot --headless --path . --export-pack Android build/kring-uji.pck`: exit 0; aset dan skrip hasil ada, aset tak dipasang tidak ada.
- Probe jendela (1920x1080, 2340x1080, 2400x1080, 1600x720): `probe_hasil`, `probe_bengkel`, `probe_reputasi`, `probe_hud_rute`, `probe_kondisi`, `probe_misi`: 0 keadaan tidak sesuai.
- sha256 save asli sesudah semua tes dan probe: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e` (tidak berubah).

## Bagian B — Koran

## Bagian C — Jeda, tutorial, banner, HUD

## Bagian D — dokumen

## NEEDS-MANUAL
Lihat SPEC (SETUP_ANDROID 8.19).
