# Loop Log — 20261024-ui2-semua-layar
Scope: Run UI-2 — redesain UI langkah 3-6 (hasil, koran, jeda, tutorial, banner, tombol jeda HUD) dalam satu PR  ·  Branch: feat/ui2-semua-layar (dari main d16b3bb, 0.7.0)  ·  Mulai: 2026-10-24  ·  Godot: 4.7.2.stable.official.ed1daf0bf

## Status: IN_PROGRESS   (iterasi 1/2; bagian A, B, dan C selesai)

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

### B1 — Halaman koran (selesai; commit `8e722be`, tes penutup mutan di commit berikutnya)
- Kode baru: `scripts/systems/tampil_koran.gd` (`TampilKoran`, murni: `tata` = margin max(12, inset), lebar kolom misi 236 dan 280 (di lebar >= 800), lebar kolom berita = isi - misi - 13, x garis tegak, persegi Berangkat 140x42 kanan bawah; `PeranTombol` TINTA/TIPIS/TERPILIH dengan `nama_tekstur_tombol`, `warna_teks_tombol`, `margin_isi_tombol`, `glif_pilih`; `foto_untuk_efek` dan `ikon_untuk_efek`; `ruang` (pembagian sisa kolom berita antara batang hiasan di atas dan kotak iklan di dasar), `iklan`, `batang_hiasan`, `baris_hiasan_muat`, `tinggi_hiasan`, `garis_ganda`), `scripts/ui/garis_ganda.gd`, `scripts/ui/garis_hiasan.gd`, `scripts/ui/kotak_iklan.gd` (garis putus dari `GarisSobek.segmen`). `GayaHud` mendapat fungsi BARU `tombol_koran(tombol, peran)`, `panel_koran()`, `kotak_notifikasi_koran()` dan 14 entri tekstur baru; fungsi lama tidak diubah. `theme.tres`: satu type variation BARU `LayarTeksMiniTebal` (Lexend SemiBold 10, untuk teks status misi; kanvas memberi status `font-weight: 600`); variation lain tidak diubah. `halaman_koran.tscn` dan `halaman_koran.gd` ditulis ulang (anchor + Container). Sinyal (`ambil_diminta`, `lewati_diminta`, `berangkat_diminta`), `isi(...)`, `atur_pilihan`, `pilihan`, `ada_misi`, `tampilkan_notifikasi`, `atur_inset`, `teks_tampil` (urutan sama), `teks_tombol`, `teks_status`, `tombol_*`, `rect_*`, `ukur_label` TETAP; baru: `peran_tombol`, `nama_foto`, `nama_ikon_utama`, `foto_tampil`, `iklan_tampil`, `notifikasi_tampil`, `hiasan_baris`, `tata` dan beberapa `rect_*`. `gaya_tombol` kini mengembalikan `StyleBoxTexture` (dulu `StyleBoxFlat`; tidak bisa dihindari karena bingkai tombol kini 9-slice). Perilaku, alur (Koran -> Rute), `HeadlineManager`/`PemuatHeadline`/misi, back per keadaan TIDAK berubah.
- Sesuai kanvas `Koran.dc.html`: kertas = `ColorRect` KORAN_KERTAS + `ui_kertas_tile` diulang (`TextureRect` TILE, Nearest); nama koran Lilita One 32 (variation `LayarAngkaBesar`, dinaikkan 5 px di atas margin seperti kanvas supaya garis ganda jatuh di y 46); "Hari N · Perumahan Melati" kanan (diturunkan 13 px supaya garis dasar sejajar nama); garis ganda 2+1+1 KORAN_TINTA; kolom berita | 6 + garis tegak 1 + 6 | misi 236/280; judul bagian dengan ikon 24 (kerucut atau bohlam menurut efek) dan label KAPITAL; foto 100x62 (hanya efek `jalan_diperbaiki` dan `mati_lampu`, "jalan dan lampu dulu" Spesifikasi.dc.html; efek lain tanpa foto dan tanpa ikon, headline mengisi lebar kolom); headline Lilita 24, ringan Lilita 16 dan batang hiasan 2 px (tiga baris, dua kolom, pola 100/100/100/80/60/100 persen); kotak misi `ui_koran_kotak` 9-slice garis ganda dengan ikon kucing 24; tombol Ambil/Lewati bingkai tipis (tidak terpilih) atau terpilih berongga bingkai tinta 3 px dengan glif centang, Berangkat tinta penuh 140x42 kanan bawah dengan panah; kotak "Iklan baris" 220x54 di kiri bawah kolom berita (garis putus KORAN_GARIS); kotak notifikasi save (isi KORAN_KERTAS_2, garis 1 px, glif "!" TINTA_2, tinggi >= 42) menggantikan iklan; inset aman; lebar 800.
- V-8 di koran: nama koran 32 (`LayarAngkaBesar`), headline 24 dan 16 (tidak berubah, Lilita), hari dan teks "tanpa misi" 12 (`LayarTeksUtama`), ringkasan dan notifikasi 11 (`LayarTeksKecil`), status misi 10 tebal (`LayarTeksMiniTebal`), label KAPITAL 10 (`LayarLabel`), tombol 12 (`TombolPeran`). **Tidak ada elemen yang turun ke +1.** Headline 40 huruf lebar dan ringkasan 60 muat di 640 sesudah dua penyesuaian tata letak, bukan penurunan huruf: jarak antar baris headline dirapatkan seperti kanvas (tinggi baris 1,05 em; bawaan Godot menambah 3 px: `KORAN_JARAK_BARIS_UTAMA_PX` -3, `_JUDUL_PX` -2, `_TEKS_PX` 1) dan kepala dipadatkan (nama dinaikkan 5 px). Kasus terburuk terukur di 640 (1920x1080): `terpanjang_save` = headline utama 40 huruf M/W dengan foto jalan (empat baris Lilita 24), headline misi 40 huruf (tiga baris), ringkasan 60 huruf (tiga baris), berita ringan 40 huruf (dua baris) dan notifikasi `KORAN_SAVE_TIDAK_TERBACA` 150 huruf (tiga baris): kolom berakhir tepat di batas bawah isi (y 348), tidak ada teks terpotong. Batang hiasan dan kotak iklan hanya hiasan: tinggi minimum 0 dan mengalah lebih dulu (iklan lalu baris hiasan), jadi kolom tidak pernah meluap karena hiasan.
- Teks: SATU kunci baru `KORAN_IKLAN_BARIS` = "IKLAN BARIS" (label kapital, pola kunci `KORAN_LABEL_*`) di `translations/ui.csv` (`ui.id.translation` terbarui lewat `--import`); kunci lama tidak diubah. **Penyimpangan dari kanvas karena V-3 (hanya dua kunci baru run ini): kotak iklan TIDAK memuat teks iklan "Dijual sepeda onthel, ban baru, bel nyaring. Hubungi Pak Darto, Blok C."; gantinya batang hiasan 2 px (sama dengan hiasan di bawah berita ringan).** Butuh keputusan bila teks iklan itu diinginkan: itu kunci baru kedua (jadi tiga kunci baru run ini, V-3 menyebut dua).
- Aset (V-4): `komponen.py --salin` + daftar tunggal `pasang.py` (`KORAN`, `IKON24`, `GLIF12` diperluas) memasang 14 berkas baru ke `assets/sprites/ui/` (total redesain terpasang 56 berkas: 53 komponen, sepeda, JSON sepeda, dan latar; bagian A berakhir di 42): `ui_koran_{kotak,btn_tinta,btn_tinta_tekan,btn_tipis,btn_terpilih}`, `ui_kertas_tile`, `ui_foto_{jalan,lampu}`, `ui_icon24_{kucing,kerucut,bohlam}`, `ui_glif_{centang_gelap,panah_terang,seru_tinta2}`; `.import` Lossless, tanpa mipmap, bukan VRAM. Berkas yang sudah terpasang byte-identik (skrip deterministik). Tanpa font atau palet baru; PNG tidak diedit tangan. Yang tetap tidak dipasang: `sepeda_besar`, sheet `lencana32` utuh, `panel_hud`, latar 640, sheet ikon dan glif utuh.
- Probe `tests/probe_halaman_koran_jendela.gd` (ditulis ulang): 17 keadaan (hari 1, Ambil, Lewati, hari 2, terpanjang foto jalan, terpanjang Ambil, terpanjang tanpa foto, foto lampu, tanpa misi, lanjutan, save rusak, save tidak terbaca, save gagal, terpanjang + save terpanjang, inset aman terpanjang, inset aman hari 1) x 1920x1080 (640), 2340x1080 (780), 2400x1080 (800), 1600x720 (800): **0 keadaan tidak sesuai di keempat ukuran** (teks terpotong, elemen atau teks di luar zona aman, tumpang tindih label/tombol/foto/ikon/iklan/notifikasi/kolom, tombol < 42x84, kolom meluap ke bawah, lebar kolom misi/berita, x garis tegak, dan Berangkat sama dengan `TampilKoran.tata`, foto 100x62). Tangkapan `<ukuran>_koran_<keadaan>.png` + `.json` di `shots/iter1/`. Saya MELIHAT tangkapan hari 1 dan tanpa misi (1920x1080), terpanjang_save dan inset_aman (1920x1080), ambil (2400x1080), foto_lampu (2340x1080) dan membandingkan dengan `Koran*.dc.html`: urutan blok, garis ganda di y 46, foto di kiri headline, kotak misi garis ganda, tombol tipis/terpilih/tinta, kotak iklan kiri bawah, dan notifikasi cocok; selisih tertulis di bawah. Dibanding baseline (`shots/baseline/*_koran_*`, kertas rata tanpa foto dan tanpa kotak iklan, tombol berbingkai polos, huruf 7 sampai 10): kini bertekstur kertas, berfoto, bertombol tinta, huruf V-8.
- Kontras (`tools/ukur_kontras_tangkapan.py`, diperluas `--jenis koran`, 16 keadaan x 4 ukuran, semua dari tangkapan nyata): teks terburuk **7,58:1** (1600x720 "Lewati" TINTA_2 di KERTAS_2; 7,67:1 di tiga ukuran lain, label "MISI SAMPINGAN"), tidak ada teks < 7:1 (teks tinta di atas kertas terang ikut diukur); kontrol aktif: Berangkat 15,28:1, Ambil/Lewati (garis tipis KORAN_GARIS) **3,89:1** (>= 3:1, alat kini gagal bila < 3 untuk `tombol` dan `pilih`); kotak misi 4,48:1 (wadah non-kontrol, dilaporkan saja seperti kartu bengkel/struk hasil, QA-003 UI-1).

Penyimpangan dari kanvas (usulan, bisa ditolak): (1) kotak iklan tanpa teks iklan (V-3, di atas); (2) panah Berangkat dan centang pilihan menempel di tepi kanan/kiri tombol, bukan dekat teks (`Button.icon` Godot; sama dengan "Hari berikutnya" bengkel); (3) kotak notifikasi selebar kolom berita (367 di 640), bukan selebar isi dikurangi Berangkat (464): teks 150 huruf jadi tiga baris dan tidak membuat tinggi kotak melebihi 58; (4) label "BERITA UTAMA" dan teman tampil kapital dari kunci lama (kanvas kapital lewat CSS); (5) berita utama efek selain jalan dan lampu tanpa ikon di judul (kanvas selalu mengisi ikon; tidak ada ikon untuk efek lain); (6) jarak antar baris headline dirapatkan (-3) supaya sama dengan tinggi baris kanvas; (7) tekan Ambil/Lewati memakai bingkai terpilih karena kanvas tidak punya bingkai tekan untuk pilihan; (8) status misi memakai variation baru `LayarTeksMiniTebal` (tebal 10), karena `LayarTeksMini` Regular tidak sama dengan kanvas.

Tes lama yang diubah (semua karena tampilan, bukan perilaku):
| Tes | Perubahan | Alasan |
|---|---|---|
| `tests/tes_halaman_koran.gd` `VARIASI_SAH` | daftar variation: `JudulBesar/JudulLayar/HudLabel/HudTeks/TeksKecil` -> `LayarAngkaBesar/JudulBesar/JudulLayar/LayarLabel/LayarTeksUtama/LayarTeksKecil/LayarTeksMiniTebal` | V-8 dan tata ulang |
| `tests/tes_halaman_koran.gd` `_test_tata_letak_semua_ukuran` | label di dalam zona aman: kotak `NamaKoran` boleh naik `KORAN_KEPALA_NAIK_PX` di atas margin (tinta tetap di dalam); sisanya sama | kepala seperti kanvas |
| `tests/tes_halaman_koran.gd` `_test_ambil_lewati` | cek bentuk: `StyleBoxFlat` (warna isi, lebar bingkai) -> tekstur bingkai (`koran_btn_tipis`/`koran_btn_terpilih`/`koran_btn_tinta`), peran, glif centang dan panah | tombol kini 9-slice |
| `tests/tes_halaman_koran.gd` `_test_notifikasi_dan_zona_aman` | notifikasi "menambah satu label" -> jumlah label sama (label iklan hilang, label notifikasi muncul) + iklan tersembunyi | kanvas: iklan = tanpa save |
| `tests/tes_halaman_koran.gd` `_test_font_dan_warna` | ditulis ulang: ukuran huruf V-8 per label (13 label), latar kontras (kotak notifikasi KERTAS_2), kontras teks tombol terhadap isi per peran, bingkai `StyleBoxTexture` | tombol 9-slice, V-8 |
| `tests/halaman_uji.gd` `terpanjang()` | efek `hajatan` -> `jalan_diperbaiki` (foto 100x62 ikut tampil: kasus tersempit); baru `dengan_efek()` | kasus terpanjang harus memuat foto |
| `tests/tes_export.gd` | `UI1_PNG_DIPASANG` + 14 aset koran, `UI1_SKRIP_IKUT` + skrip dan scene koran, `UI1_AWALAN_TAK_DIPASANG` tidak lagi memuat `ui_koran_`, `ui_foto_`, `ui_kertas_tile` (kini dipasang); contoh "tak ada di assets" diganti `ui_foto_hujan.png`, `ui_koran_foto_jalan.png`, `ui_sepeda_besar.png`, `ui_panel_hud.png` | aset koran dipasang |
Tes baru: `tests/tes_tampil_koran.gd` (murni, oracle kanvas literal; terdaftar di `run_tests.gd`) dan di `tests/tes_halaman_koran.gd`: `_test_tampilan_baru` (empat ukuran: kertas, foto, ikon, kolom, garis tegak, Berangkat, garis ganda, iklan, notifikasi), `_test_hari_panjang` (nomor hari 16 digit berelipsis), `_test_gaya_tombol_koran`, `_test_tata_sapuan` (224 kombinasi: empat ukuran x inset x tujuh halaman x empat notifikasi: tidak meluap, tidak bertumpuk, semua di zona aman, tidak terpotong). `tools/tests_cek/uji_ui_redesain.py` diperluas (isi assets = keluaran skrip, set tepat 56 berkas redesain, slice tombol tinta = tombol biasa dan kotak misi = panel, foto 100x62, kertas 4x4, ikon dan glif terdaftar); `tools/ukur_kontras_tangkapan.py` `--jenis koran`.

### Mutan nyata bagian B (32 dari 32 tertangkap; 1 setara)
Satu perubahan per mutan, runner kecil (`TesTampilKoran` + `TesKomponenUi` + `TesHalamanKoran` + `TesAlurHari`, sekitar 3000 pemeriksaan, 6 detik), `git checkout` sesudah tiap mutan, kode di-COMMIT lebih dulu (`8e722be`). Putaran pertama: 28 tertangkap, 4 lolos (B21, B26, B27, B31). B21, B26, B27 ditutup tes (commit penutup) dan diulang: tertangkap. B31 setara (`_hiasan_berita.visible = true` saat nol baris: node berukuran 0 dan tidak menggambar apa pun, tidak ada perbedaan terlihat atau terukur), dicatat.
| Mutan | Perubahan | Tertangkap oleh |
|---|---|---|
| B01 | lebar 800 tepat memakai 236 (`>=` jadi `>`) | "lebar 800: kolom misi 280" |
| B02 | garis tegak 1 px dihapus dari pemisah kolom | tata 640: isi, misi, berita |
| B03 | jarak 6 sebelum garis tegak dihapus | tata 640: garis x 385 |
| B04 | Berangkat memakai margin atas | tata inset (dan sapuan 113 pemeriksaan) |
| B05 | `peran_pilih` dibalik | "terpilih = TERPILIH" |
| B06 | TIPIS ditekan tetap bingkai tipis | "TIPIS ditekan = bingkai terpilih" |
| B07 | teks TINTA berwarna tinta | warna TINTA |
| B08 | geseran isi TINTA normal/ditekan tertukar | "TINTA normal: teks naik" |
| B09 | centang selalu ada | glif_pilih |
| B10 | foto selalu indeks 0 | "mati lampu: foto lampu" |
| B11 | ikon efek tertukar | "jalan diperbaiki: foto jalan, ikon kerucut" |
| B12 | iklan minimum `<=` | "ruang 28 tepat" |
| B13 | tinggi iklan `maxi` | "iklan 220x54 di dasar" |
| B14 | hiasan 0 baris | "tiga baris hiasan" |
| B15 | kolom hiasan tanpa jarak kolom | "dua batang penuh (178)" |
| B16 | baris hiasan muat tanpa jarak baris | "ruang 7: dua baris hiasan" |
| B17 | garis ganda tanpa celah | "garis ganda: 2 px, celah 1, 1 px" |
| B18 | margin kiri mengabaikan inset | "margin mengikuti inset" |
| B19 | iklan tanpa jarak dari hiasan | "ruang 60" |
| B20 | iklan tampil walau ada notifikasi | notifikasi menggantikan iklan (164 pemeriksaan) |
| B21 | `tampilkan_notifikasi` tidak menata iklan | seketika iklan tersembunyi (setelah ditambah) |
| B22 | foto selalu tampil | "efek hajatan: tanpa foto" |
| B23 | gaya pilihan terbalik | "awal: kedua tombol hanya garis tipis" |
| B24 | lebar kolom misi selalu 236 | "lebar 800: kolom misi 280" |
| B25 | efek foto tidak dibaca | "efek jalan_diperbaiki: foto jalan" |
| B26 | bingkai tekan sama dengan normal | gaya tombol koran (setelah ditambah) |
| B27 | `KORAN_FOTO_TINGGI_PX` 60 | ukuran PNG = Config (setelah ditambah) |
| B28 | `KORAN_KEPALA_NAIK_PX` 0 | "garis ganda ... di y 46" |
| B29 | jarak baris headline +3 | sapuan: Berangkat tepat di kanan bawah (kolom meluap) |
| B30 | goresan garis putus sisi bawah salah letak | "sisi bawah di y 11" |
| B31 | hiasan selalu tampil | SETARA (node 0 piksel) |
| B32 | tinggi minimum notifikasi dihapus | "notifikasi ... setinggi minimal 42" |

### Gerbang bagian B (2026-10-24, keluaran nyata)
- `godot --headless --import`: 0 baris ERROR/WARNING. `godot --headless --path . --quit-after 2`: 0 baris ERROR/WARNING.
- `run_tests.gd`: **25855 lolos, 0 gagal**; `tools/cek_keluaran_tes.py`: "lolos (25855 lolos, 0 gagal, 0 peringatan)" (akhir bagian A 24009; +1846 pemeriksaan).
- 17 berkas `tools/tests_cek/uji_*.py`: exit 0 semua (termasuk `uji_ui_redesain.py` diperluas).
- `godot --headless --path . --export-pack Android build/kring-uji.pck`: exit 0, 0 ERROR/WARNING; ada: 14 aset baru, `tampil_koran.gd`, `garis_ganda.gd`, `garis_hiasan.gd`, `kotak_iklan.gd`, `halaman_koran.tscn`; tidak ada: `sepeda_besar`, `ui_lencana32.png`, `ui_panel_hud.png`, `ui_koran_foto*`, tes dan probe koran, `tests/`.
- Probe jendela `probe_halaman_koran_jendela.gd` (1920x1080, 2340x1080, 2400x1080, 1600x720): 0 keadaan tidak sesuai. (Probe hasil/bengkel/reputasi/HUD/kondisi/misi tidak dijalankan ulang di bagian B: tidak ada kode yang mereka sentuh berubah; `GayaHud` hanya bertambah fungsi.)
- sha256 save asli sesudah semua tes dan probe: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e` (tidak berubah).

## Bagian C — Jeda, tutorial, banner, HUD

Commit kode: `a99094e` (C1 dan C2 dalam satu commit karena `Config`, `GayaHud`, dan `theme.tres` dipakai bersama). Probe baru `tests/probe_jeda_hud_jendela.gd`, perbandingan piksel `tools/bandingkan_tangkapan_hud.py`, kontras `tools/ukur_kontras_tangkapan.py --jenis jeda|tutorial|banner|hud_c`.

### C1 — Jeda, tutorial, banner (selesai)
- Kode baru: `scripts/systems/tampil_jeda.gd` (`TampilJeda`, murni: warna lapisan 72 %, kunci teks dan bingkai sakelar menurut keadaan, glif, dua pola kenop 22x12 `KENOP_MATI` dan `KENOP_NYALA` dari huruf per piksel, `perintah_kenop`), `scripts/systems/tampil_tutorial.gd` (`TampilTutorial`: titik langkah terisi sampai langkah sekarang, glif per langkah, `perintah_titik`), `scripts/ui/kenop_sakelar.gd` (`KenopSakelar`), `scripts/ui/titik_langkah.gd` (`TitikLangkah`). `GayaHud`: `panel_jeda()`, `bingkai_tombol()` (publik, untuk gambar tombol jeda HUD), `tombol_sakelar(tombol, nyala, pad_tambah)` dan `panel_hud(pad_x, pad_y)` dengan parameter baru yang bawaannya sama dengan sebelumnya (pemanggil lama tidak berubah); enam glif baru di `_TEKSTUR`.
- Layar jeda (`layar_jeda.tscn` dan `.gd` ditulis ulang, anchor + Container): lapisan `HUD_PANEL` alpha 0,72 (konstanta `JEDA_LAPISAN_ALPHA`; token `HUD_PANEL` alpha 0,84 tidak diubah), panel layar 232 lebar di tengah (CenterContainer), judul "JEDA" Lilita 24 dengan glif jeda, Lanjut peran utama (glif lanjut gelap di ujung kanan, `Button.icon` seperti "Hari berikutnya"), garis pemisah, dua sakelar peran sakelar (bingkai biasa saat mati, bingkai ACCENT saat nyala, teks `JEDA_KIDAL_*` / `HUD_BANTU_*` kata "mati"/"nyala" tetap, dan kenop 22x12: mati = kenop berongga di kiri dan kotak kosong di kanan, nyala = kenop terisi di kanan di atas ACCENT dan garis tegak di kiri: terbaca tanpa warna). Sinyal `lanjut_diminta`, `kidal_diubah`, `bantu_diubah`, `atur_kidal`, `atur_bantu`, `tampilkan`, `tampil`, `rect_*`, `sakelar_*` TETAP (nama simpul `JudulJeda`, `TombolLanjut`, `SakelarKidal`, `SakelarBantu` tetap); baru: `rect_panel`, `rect_judul`, `rect_kenop_*`, `kenop_*`, `tombol_lanjut`. Font: tombol `TombolPeran` 12 dan judul 24 (V-8).
- Tutorial (`tutorial.tscn`, `tutorial_controller.gd`): panel HUD 176 lebar (dulu 150) di (26, 88), label langkah `ACCENT` + titik langkah, glif aksen per langkah (naik, turun, panah, seru; kanvas hanya menunjukkan langkah 1 dengan glif naik) dan kalimat 10 px (`HudAngka`, berbungkus kata), Lewati peran tenang 64x42 di (66, 4). Tetap tidak memblokir input (hanya Lewati yang menerima sentuhan).
- Banner (`panel_akhir_rute.tscn`, `.gd`): panel HUD dengan glif di depan judul (centang `OK` untuk Rute selesai, tanda seru `WARN` untuk galat muat: di kanvas hanya Rute selesai ada glif), tombol Main lagi (hanya galat) peran utama.
- Gelembung petunjuk dari pelanggan: label `MISI_PETUNJUK_LABEL` = "PELANGGAN:" (`TEXT_2`, HudLabel 8) di kiri kalimat; lebar baris tetap 170, jadi gelembung tetap 184 lebar dan 33 tinggi (sama dengan sebelumnya). **Itu satu-satunya perubahan di HUD misi.** Kunci baru kedua dan TERAKHIR V-3 (kunci pertama `KORAN_IKLAN_BARIS`, bagian B); kalimat petunjuk tetap dari konten.
- **Banner hasil misi di HUD TIDAK diubah (keputusan Dev, perlu konfirmasi):** SPEC AC-5 menyebut "banner misi bila ada papan" memakai panel/tombol baru dan kanvas Banner.dc.html menambah ikon kucing 24 dan ikon koin 14, tetapi V-9 dan AC-6 mewajibkan banner (dan petunjuk) piksel-identik, dan ikon menambah lebar banner ke sekitar 205 px sehingga bertabrakan dengan panel baris 2 kolom kanan di 640. Dipilih V-9: banner tetap teks Lilita 16 pada panel HUD yang sama (dibuktikan piksel-identik di bawah); panel HUD itu memang sudah panel baru komponen HUD. Bila ikon kanvas diinginkan, perlu keputusan menggeser panel baris 2 atau banner.
- Aset (V-4): `komponen.py --salin` lewat daftar tunggal `pasang.py` memasang enam glif baru (`ui_glif_{jeda_terang,lanjut_gelap,naik_aksen,turun_aksen,panah_aksen,seru_aksen}`, total redesain terpasang 62: hanya yang dipakai); `.import` Lossless, tanpa mipmap, bukan VRAM. Kenop sakelar dari kode (tanpa PNG). `panel_hud` redesain TIDAK dipasang: panel HUD tetap `ui_panel_hud_9slice.png` yang ada (sama dengan `.pnl.hud`).
- Penyimpangan dari kanvas (usulan, bisa ditolak): (1) panel jeda di tengah layar secara tegak (CenterContainer), bukan di y 50, dan ruang cadangan 42 piksel "Pengaturan dan Keluar ke menu nanti" tidak dikosongkan (hanya anotasi papan); (2) glif Lanjut menempel di tepi kanan tombol (`Button.icon`, sama dengan "Hari berikutnya"); (3) kenop tidak ikut turun 2 px saat tombol sakelar ditekan (teks ikut turun); (4) jarak kenop dari tepi tombol 12 (tepi 4 + padding 4 + tambahan 4 seperti kanvas `padding-left: 8`); (5) "JEDA" tanpa letter-spacing .04em; (6) tutorial: glif tidak hanya naik (lihat atas) dan titik langkah terisi sampai langkah sekarang (kanvas hanya menunjukkan langkah 1); (7) banner galat muat memakai tanda seru WARN dan Main lagi peran utama (kanvas hanya menampilkan Rute selesai, Kucing ketemu, Kucingnya lolos, gelembung); (8) HUD misi banner lihat atas.
- Kontras (`tools/ukur_kontras_tangkapan.py`, dari tangkapan nyata, empat ukuran): jeda terburuk **10,14:1** ("Lanjut" gelap di atas ACCENT), garis Lanjut (kontrol aktif) **12,56:1** (>= 3:1), garis sakelar 8,53:1; tutorial dan banner: 0 teks < 7:1, banner Main lagi >= 3:1.

Tes lama yang diubah di C1 (alasan):
| Tes | Perubahan | Alasan |
|---|---|---|
| `tests/tes_jeda_scene.gd` `_test_tombol_dan_layar` | cek lapisan: `latar.color == Palette.HUD_PANEL` -> `TampilJeda.warna_lapisan()` (alpha 0,72) dan token HUD_PANEL tetap alpha 0,84; cek Lanjut: `StyleBoxFlat` garis TEXT -> `StyleBoxTexture` `btn_utama` dengan teks `UI_BG` | V-2 dan tombol peran utama |
| `tests/tes_export.gd` | enam glif baru di `UI1_PNG_DIPASANG`; skrip dan scene jeda/tutorial/banner di `UI1_SKRIP_IKUT` | aset dan skrip bagian C ikut paket |
| `tools/tests_cek/uji_ui_redesain.py` | bagian baru: enam glif terdaftar, kenop dari kode (dua pola 22x12 = `Config.JEDA_KENOP_*`, tanpa PNG kenop) | AC-10 |

### C2 — HUD (V-9, selesai)
- Kode baru: `scripts/systems/tampil_hud.gd` (`TampilHud`, murni: `warna_stamina` (FAIL di bawah 30), `posisi_tanda` (80 % dibulatkan ke bawah), `margin_bawah`, `koran_di_awal`, `nama_bingkai_jeda`, `posisi_glif_jeda`, `kunci_reputasi`, `reputasi_tampil`, `baris2_tampil`). `BarKecepatan` mendapat `tanda` dan `rect_tanda()`; `HudDasar` mendapat `rect_bar_*`, `rect_kolom_*`, `label_bawah`, `bar_kecepatan`, `bar_stamina`; `TombolJeda` digambar dari bingkai tombol biasa dan glif; `HudRute`: `GrupReputasi` di dalam `PanelKondisi`. `theme.tres`: type variation BARU `HudLabelBawah` (10) dan `HudAngkaBawah` (12) (`HudLabel`/`HudAngka` tidak diubah).
- **H-1 panel bawah:** kecepatan dan stamina berdampingan dalam satu panel 9-slice 220 lebar dan 39 tinggi (dulu 170 x 59): kolom 111 dan 89, jarak 8, label 10 px KAPITAL di atas bar tinggi 9, angka "3.0 u/d" 12 px di kanan label kecepatan, `LELAH` di kanan label stamina; panel koran 115 lebar, sama tinggi 39 (isi tidak berubah selain huruf dan panel 9-slice). Posisi: panel kecepatan x 196 (dulu 210), koran x 424 (dulu 400), berakhir x 539 di 640: tersisa 2 px dari zona tap bel dengan inset kanan 11 (541) dan 3 px dari zona tap bel kidal dengan inset kiri 10; zona stick berakhir x 192. Kidal dicerminkan seperti sebelumnya. **Tanda 80 % TIDAK ada di kode sebelum run ini** (DESIGN_SPEC 3.5 hanya mencatatnya, `BarKecepatan` tidak menggambar apa pun): ditambahkan sebagai garis `WARN` 1 px setinggi bar di 80 % lebar isi (x 88 di bar 111). Catatan angka: ambang sprite ngebut 0,80 dari kekuatan stick (santai 3,0 = 0, ngebut 6,0 = 1) jatuh di 5,4 u/d, yaitu 90 % bar (bar = kecepatan / 6,0); tanda mengikuti 80 % DESIGN_SPEC/V-9 (perlu keputusan: 80 % atau 90 %).
- **H-2 kolom kanan atas:** pilihan layout = **alternatif "berbagi panel kondisi"**, bukan menggabung ke panel koin. Ukur di 640: ruang baris 1 antara panel progres (berakhir x 450) dan tepi kanan (x 612) = 157 px (dengan jarak 5); panel koin + reputasi (7 + 14 + 3 + "1.250" 26 + 6 + 14 + 3 + "100" 19 + 7 = sekitar 99) + 5 + panel skor (>= 72, terukur 76) = sekitar 180 > 157. Hasil: baris 1 [koin][skor/combo] tidak berubah, baris 2 satu panel [ban rem rantai | bintang angka] 174 px (37) atau 181 px (100) dari 140 (tanpa reputasi), mulai x 431 di 640; baris 3 dihapus. Aturan tampil reputasi (hanya bila rute punya keadaan pelanggan) tetap.
- **H-3:** tombol jeda berbentuk tombol biasa (bingkai 9-slice `btn_biasa`, ditekan `btn_biasa_tekan`, glif jeda 12 px di (6, 5) atau (6, 7)); gambar 24x24 di (26, 8) dan area sentuh 42x42 di (17, 4) tidak berubah.
- **Bukti piksel-identik** (`tools/bandingkan_tangkapan_hud.py shots/baseline shots/iter1`, probe lama `probe_hud_rute`, `probe_misi`, `probe_reputasi` dijalankan ulang di 1920x1080 dan 2340x1080 dengan langkah tetap): **30 tangkapan per ukuran (hud_awal, radar, bantu_abu, progres_campuran, tenggat_hampir, tenggat_lewat, kidal; seluruh misi_* termasuk kartu, kucing di tiap titik, penanda tepi layar, banner selesai dan gagal; reputasi_hud_* termasuk inset) identik piksel demi piksel di luar pengecualian: 0 berbeda di kedua ukuran.** Pengecualian (tertulis di docstring alat): panel bawah (pita 90..540 x 80 dari bawah), kolom kanan atas (x lebar-225..lebar-20, y 0..130), tombol jeda (14..80 x 2..72), tutorial di `misi_*`, gelembung petunjuk di `misi_petunjuk` (label baru), dan derau animasi di sekitar pemain (x 150..270, y 230..345: dua jalan probe yang sama berbeda 36 sampai 45 piksel di sana, debu roda dan bingkai kayuh). Radar kiri dan kanan, panel progres dan tenggat, kartu misi, banner selesai dan gagal, tombol bel, penanda kucing, dan umpan melayang tidak dikecualikan. Dua tangkapan pertama sebuah jalan probe (`misi_awal` 2340x1080, sempat berbeda) tidak deterministik antar jalan; diulang dan identik.
- Zona swipe: panel koran dan panel kecepatan tidak menangkap sentuhan (dites sentuhan sungguhan di 640, 667, 780, 800: jari di tengah panel menjadi swipe atau stick menurut zona, `TesLayarCScene._test_sentuhan_panel_bawah`; tes lama `_test_tata_letak_kondisi` untuk panel baris 2 tetap hijau).
- Konsekuensi: **banner misi 24 huruf (batas data `MISI_BANNER_PANJANG_MAKS`, sekitar 242 px) akan menyentuh panel baris 2 di 640 saat reputasi tampil** (panel mulai x 431; banner terpanjang yang ada, 173 px, tidak). Tes lama menjaga lebar banner 240; diubah ke 176 (lihat tabel). Opsi bila itu masalah: menurunkan baris 2, memotong banner, atau memindahkan reputasi; perlu keputusan.

Tes lama yang diubah di C2 (alasan):
| Tes | Perubahan | Alasan |
|---|---|---|
| `tests/tes_hud_rute_scene.gd` `_test_sakelar_layar_jeda` | panel kecepatan mulai x 210 -> `HUD_PANEL_KECEPATAN_GESER_PX` (196) di dua cek | H-1 |
| `tests/tes_input_scene.gd` (tiga cek panel kecepatan, satu cek font) | x 210 dan lebar 170 -> x 196 dan lebar 220 (tangan kanan dan kidal); ukuran font panel bawah: angka 10 dan label 8 -> angka 12 dan label 10 (type variation baru) | H-1 |
| `tests/tes_gerak_scene.gd` | "bar stamina di bawah bar kecepatan, selebar, tinggi 7" -> bar berdampingan, sejajar tegak, tinggi 9 | H-1 |
| `tests/tes_reputasi_scene.gd` `_pelanggaran_hud`, `_test_hud_reputasi`, `_test_hud_tanpa_keadaan` | panel reputasi baris 3 (rata kanan dengan panel kondisi dan 5 px di bawahnya, simpul `PanelReputasi` dan `IsiReputasi`) -> penanda di dalam panel baris 2 (`GrupReputasi`), tidak ada panel reputasi sendiri; tumpang tindih diperiksa untuk panel baris 2 utuh; lebar banner asumsi 240 -> 176 (alasan di atas) | H-2 |
| `tests/probe_reputasi_jendela.gd` `_cek_hud` dan bagian inset | idem tes di atas | H-2 |
Tes baru: `tests/tes_tampil_layar_c.gd` (murni: lapisan, kunci, kenop (pola = perintah gambar), titik dan glif tutorial, stamina di ambang, tanda 80 %, margin dan urutan panel bawah, tombol jeda, baris 2) dan `tests/tes_layar_c_scene.gd` (scene: jeda di empat lebar, sakelar, tutorial per langkah, banner, HUD 4 lebar x kanan/kidal x inset x keadaan terpadat, isi HUD, gelembung petunjuk, sentuhan), terdaftar di `run_tests.gd`.

### C3 — Probe dan ukur
- Probe `tests/probe_jeda_hud_jendela.gd` (baru): `jeda_*` (4), `tutorial_*` (5), `banner_*` (5), `hud_c_*` (22 keadaan: awal, kecepatan penuh, stamina batas atas, stamina rendah, lelah, koran sedikit dan habis, kondisi AUS, PERLU_BENGKEL dengan "!", peringatan, reputasi 37 dan 100, skor besar, combo putus, terpadat, terpadat dengan misi dan petunjuk, kidal, inset, kidal + inset) di 1920x1080, 2340x1080, 2400x1080, 1600x720: **0 keadaan tidak sesuai di keempat ukuran** (teks terpotong, di luar layar atau zona aman, tumpang tindih, kolom bawah di zona stick, tinggi panel bawah > 40, bar tidak berdampingan, tombol < 42x84 kecuali Lewati 64x42 dan area sentuh jeda 42x42, tanda 80 %). Probe lama `probe_hud_rute`, `probe_misi`, `probe_reputasi` (1920x1080 dan 2340x1080): 0 keadaan tidak sesuai.
- Tangkapan DILIHAT (Read): jeda mati, nyala (1920x1080) dan nyala 1600x720; tutorial langkah 1 (1920x1080) dan 4 (2400x1080); banner Rute selesai dan galat muat; HUD awal, terpadat dengan misi dan petunjuk (1920x1080), terpadat kidal + inset (2340x1080), hud_c_awal. Penilaian: kecepatan dan stamina kini terbaca sekilas sebagai dua kolom dengan label di atas bar dan angka di samping label; tanda 80 % terlihat sebagai garis oranye di bar kecepatan; kolom kanan atas dua baris tidak penuh dan reputasi terbaca di ujung panel kondisi; panel bawah turun dari 59 ke 39 px sehingga lebih banyak jalan terlihat. Catatan visual: glif jeda 12 px di samping judul "JEDA" tampak kecil (sama dengan kanvas); gelembung petunjuk dua baris (label + kalimat bungkus) menempati ruang yang sama dengan sebelumnya.
- Kontras (`--jenis jeda|tutorial|banner|hud_c`, empat ukuran): semua teks >= 7:1 kecuali kata status berwarna token `FAIL` di HUD (`LELAH`, `HABIS`, `PUTUS`): **3,7 sampai 4,8:1 di atas panel HUD, PRA-ADA** (warna dan panel tidak diubah run ini; baseline sama), dilaporkan oleh alat sebagai "PRA-ADA" dan tidak menggagalkan. Perlu keputusan: ganti warna kata status HUD ke `WARN` atau tetap.

### Mutan nyata bagian C (41 dari 41 tertangkap; 1 setara)
Satu perubahan per mutan, runner kecil (`TesTampilLayarC` + `TesLayarCScene` + `TesJedaScene` + `TesHudRuteScene` + `TesReputasiScene` + `TesTataLetak` + `TesKomponenUi` + `TesGerakScene` + `TesInputScene`, sekitar 12 detik), `git checkout` sesudah tiap mutan, kode di-COMMIT lebih dulu (`a99094e`). Putaran pertama: 40 tertangkap, 1 lolos (C33), 1 setara (C04). C33 ditutup tes (`TombolJeda.bingkai()` dan `glif()` dites; commit penutup) dan diulang: tertangkap.
| Mutan | Perubahan | Tertangkap oleh |
|---|---|---|
| C01 | `JEDA_LAPISAN_ALPHA` 0,72 -> 0,84 | "lapisan jeda ... alpha 0,72 (V-2)" |
| C02 | kunci teks kidal tertukar | kunci teks kidal mati dan nyala |
| C03 | bingkai sakelar nyala selalu bingkai biasa | bingkai sakelar mati/nyala |
| C04 | rentang kenop `.` ikut digambar | SETARA: kedua pola kenop tidak memuat `.` (tanpa piksel transparan), jadi tidak ada beda terlihat |
| C05 | satu piksel garis tegak kenop nyala diubah | pola kenop nyala 22x12 |
| C06 | warna huruf `a` kenop = TEXT | warna huruf kenop dari Palette |
| C07 | titik langkah `<=` jadi `<` | langkah 1 dari 4: satu titik terisi |
| C08 | glif langkah melambat = naik | glif per langkah |
| C09 | cincin titik terisi 5x5 (bukan 6x6) | titik terisi: cincin gelap 1 px |
| C10 | lebar titik memakai `total` jarak (bukan `total - 1`) | lebar empat titik 22 px |
| C11 | stamina FAIL `<` jadi `<=` | stamina 30 ke atas: ACCENT |
| C12 | `HUD_STAMINA_AMBANG_RENDAH` 30 -> 35 | stamina 30 ke atas: ACCENT |
| C13 | tanda 80 % `floor` jadi `ceil` | tanda dibulatkan ke bawah |
| C14 | `HUD_BAR_TANDA_PECAHAN` 0,8 -> 0,9 | ambang 30, tanda 0,8, bar 9 tinggi |
| C15 | margin panel bawah kanan/kidal tertukar | margin kiri/kanan |
| C16 | koran di awal terbalik | koran di akhir (kanan) bawaan, di awal saat kidal |
| C17 | geser glif jeda memakai `tambah.y` | glif 12x12 di (6, 5) dan (6, 7) |
| C18 | reputasi 0 disembunyikan | kunci reputasi dijepit 0..100 |
| C19 | baris 2 tampil `or` jadi `and` | panel baris 2 tampil bila ada kondisi atau reputasi |
| C20 | `reputasi_tampil` `>= 0` jadi `> 0` | reputasi 0 tetap tampil |
| C21 | bingkai jeda ditekan diabaikan | bingkai tombol biasa, ditekan = btn_biasa_tekan |
| C22 | bar stamina selalu ACCENT | stamina 29,9: FAIL |
| C23 | bar kecepatan tanpa tanda | bar kecepatan bertanda 0,8 |
| C24 | `HUD_PANEL_KECEPATAN_GESER_PX` 196 -> 210 | margin kiri/kanan |
| C25 | `HUD_BAR_TINGGI_PX` 9 -> 7 | ambang 30, tanda 0,8, bar 9 tinggi |
| C26 | lapisan jeda alpha 0,84 (token) | lapisan HUD_PANEL alpha 0,72 menutup layar |
| C27 | atur_kidal tidak mengubah kenop | ketuk kidal: kenop kidal nyala saja |
| C28 | panel jeda tanpa lebar minimum | panel lebar 232 di tengah layar |
| C29 | grup reputasi selalu tersembunyi | reputasi 100 di dalam panel baris 2 |
| C30 | titik langkah tidak diatur | titik terisi (ACCENT) per langkah |
| C31 | galat muat memakai centang | galat muat dengan tanda seru WARN |
| C32 | `JEDA_PANEL_LEBAR_PX` 232 -> 240 | panel 232 lebar, kenop 22x12 |
| C33 | `TombolJeda.bingkai(true)` mengembalikan bingkai normal | tombol jeda menggambar bingkai biasa (ditekan: bingkai tekan) (setelah ditambah) |
| C34 | `HUD_PANEL_KORAN_GESER_PX` 424 -> 420 | geser 196, lebar 220, koran mulai 424 |
| C35 | tanda bar tanpa garis luar 1 px | tanda 80 %: x 88 di bar 111 |
| C36 | glif Lanjut di kiri | glif Lanjut gelap di ujung akhir |
| C37 | kunci teks bantu tertukar | kunci teks bantu mati dan nyala |
| C38 | label PELANGGAN: berwarna ACCENT | label di kiri kalimat ... label TEXT_2 |
| C39 | `HUD_PANEL_BAWAH_PAD_X_PX` 6 -> 7 | lebar panel = 2 x pad + kolom + jarak + kolom |
| C40 | `HUD_BAWAH_BARIS_TINGGI_PX` 15 -> 18 | panel kecepatan 220x39 dan koran 115x39 |
| C41 | panel koran tidak pindah ke awal saat kidal | kidal dicerminkan |
| C42 | `tampilkan_kondisi(null)` tetap menampilkan kondisi | tanpa kondisi dan tanpa reputasi: panel baris 2 tersembunyi |

### Gerbang bagian C (2026-10-24, keluaran nyata)
- `godot --headless --import`: 0 baris ERROR/WARNING. `godot --headless --path . --quit-after 2`: 0 baris ERROR/WARNING.
- `run_tests.gd`: **28415 lolos, 0 gagal**; `tools/cek_keluaran_tes.py`: "lolos (28415 lolos, 0 gagal, 0 peringatan)" (akhir bagian B 25855; +2560 pemeriksaan: `TesTampilLayarC` dan `TesLayarCScene`).
- 17 berkas `tools/tests_cek/uji_*.py`: exit 0 semua (termasuk `uji_ui_redesain.py` diperluas).
- `godot --headless --path . --export-pack Android build/kring-uji.pck`: exit 0, 0 ERROR/WARNING; ada: enam glif baru, `tampil_jeda.gd`, `tampil_tutorial.gd`, `tampil_hud.gd`, `kenop_sakelar.gd`, `titik_langkah.gd`, `layar_jeda.tscn`, `tutorial.tscn`, `panel_akhir_rute.tscn`, `hud_rute.tscn`; tidak ada: `tests/`, probe dan tes bagian C, `ui_sepeda_besar`, `ui_panel_hud.png` (redesain), `ui_lencana32.png`, PNG kenop.
- Probe jendela `probe_jeda_hud_jendela.gd` dan `probe_kondisi_jendela.gd` (1920x1080, 2340x1080, 2400x1080, 1600x720): 0 keadaan tidak sesuai. `probe_hud_rute`, `probe_misi`, `probe_reputasi` (1920x1080, 2340x1080): 0 keadaan tidak sesuai. `tools/bandingkan_tangkapan_hud.py`: 30 tangkapan per ukuran, 0 berbeda.
- sha256 save asli sesudah semua tes dan probe: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e` (tidak berubah).

### Butuh keputusan (bagian C)
1. Banner hasil misi HUD: ikon kanvas (kucing 24, koin 14) tidak dipasang demi V-9 piksel-identik dan lebar kolom kanan (lihat C1). 
2. Tanda bar kecepatan: 80 % (DESIGN_SPEC/V-9, dipakai) atau 90 % (setara ambang sprite ngebut 5,4 u/d).
3. Banner misi 24 huruf (batas data) akan menyentuh panel baris 2 di 640 bila reputasi tampil; opsi di C2.
4. Kata status berwarna `FAIL` di HUD (`LELAH`, `HABIS`, `PUTUS`) 3,7 sampai 4,8:1 (PRA-ADA): ganti ke `WARN` atau terima.
5. Panel jeda di tengah tegak (bukan y 50 kanvas) dan tanpa ruang cadangan 42.

## Bagian D — dokumen

## NEEDS-MANUAL
Lihat SPEC (SETUP_ANDROID 8.19).
