# Loop Log — 20261014-fase1b-umpan-balik
Scope: Run 1B Fase 1, umpan balik kecepatan (debu, garis), audio placeholder + autoload `Audio`, tombol dan layar jeda, penyetelan paket A54, probe render Compatibility, checklist uji 3-5 orang  ·  Branch: `feat/fase1b-umpan-balik`  ·  Mulai: 2026-10-14  ·  Godot: 4.7.2

## Status: IN_PROGRESS   (iterasi saat ini: 1/2)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 1 | 1a: jeda + layar jeda, penyetelan paket A54, debu/garis, QA-001/002 (7 commit). 1b: `BunyiSepeda` + autoload `Audio` + bus + 3 WAV sintesis, probe render `cek_render` + `tools/ekspor_cek_render.py`, mutan audio/probe, dokumen AC-13 (4 commit) | ✅ import 0 ERROR/WARNING; `run_tests` 4576 lolos 0 gagal, `--ketat` lolos; uji_pemeriksa/bangun_frames/sintesis lolos; `--quit-after 2` bersih; klon bersih per commit hijau, porcelain kosong | **PASS** (QA: gerbang hijau di klon bersih + 6 putaran ulang; 0 Blocker, 0 Major) | QA-001..QA-006: 0 Blocker, 0 Major, 5 Minor (QA-001..003 OPEN, QA-004 DEFERRED, QA-005 NEEDS-MANUAL), 1 Nit (QA-006 DEFERRED) | AC-1..AC-14 lewat kode + tes + perintah QA sendiri (AC-8/AC-9 desktop, A54 belum); 23 mutan QA: 13 mati, 4 hidup bermakna (QA-001), 6 setara |

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|
| QA-001 | 1 | Minor | `scripts/entities/jalan_uji.gd:96`, `scripts/autoload/audio.gd:51-53`, `scripts/ui/tombol_sentuh.gd:36,40-43` | Empat cabang pertahanan tanpa tes (mutan QA hidup, `run_tests` 4576 lolos 0 gagal dengan mutan): **Q01** hapus `_kontrol.atur_rem(false)` saat menjeda (cincin rem tetap menyala di bawah lapisan jeda sampai lanjut); **Q02** `Audio._notification` tidak menghentikan pemutar pada `APPLICATION_PAUSED`/`FOCUS_OUT` (jalur sendiri yang diklaim SOUND_DESIGN "Perilaku di Android"; kini hanya jalur sinyal `jeda_berubah` yang teruji); **Q03** `TombolSentuh._notification` tidak melupakan jari pada `PAUSED`/visibilitas; **Q04** sentuhan `canceled` di dalam tombol tetap memicu. Perilaku kode sekarang benar menurut pembacaan dan percobaan QA, tetapi tidak dijaga tes. Reproduksi: ganti potongan kode di lokasi, `godot --headless --script res://tests/run_tests.gd`, hasil 0 gagal. Saran: satu cek scene per cabang (cincin `atur_rem` padam selama jeda; `Audio` yang di-`add_child` tanpa `JalanUji` diam sesudah `propagate_notification(FOCUS_OUT)`; jari turun di tombol jeda lalu `NOTIFICATION_PAUSED` lalu naik = tidak memicu; naik `canceled` = tidak memicu) | OPEN | | |
| QA-002 | 1 | Minor | `scripts/ui/tombol_jeda.gd:31`, `scripts/ui/tombol_sentuh.gd:40-43` | Gambar tombol jeda tertinggal dalam keadaan "ditekan" (`UI_PANEL_RAISED`) sesudah lanjut bila jari masih di tombol saat jeda datang dari jalur lain. Reproduksi (skrip QA sementara, headless, jendela 2340x1080): jari 1 turun di pusat tombol jeda, `propagate_notification(FOCUS_OUT)` (jeda), jari 1 naik `canceled`, `FOCUS_IN`, `minta_lanjut()` → `TombolJeda.is_pressed()` = **true** sesudah lanjut (emulasi mouse tidak pernah menerima naik karena pohon dijeda). Ketukan berikutnya tetap menjeda dan memulihkan gambar, jadi fungsi aman; hanya tampilan menipu. Di HP: jempol di tombol jeda lalu tombol home/notifikasi. Saran: lepaskan status tekan (`button_pressed = false` atau `queue_redraw` dengan status sendiri) saat `NOTIFICATION_PAUSED`/`UNPAUSED` | OPEN | | |
| QA-003 | 1 | Minor | `tests/probe_umpan_balik_jendela.gd:88` | Probe jendela AC-9 keluar dengan `WARNING: 2 ObjectDB instances were leaked at exit` dan `ERROR: 1 resources still in use at exit`, di 2340x1080 dan 1920x1080. Penyebab: driver audio nyata (macOS) memutar loop kayuhan dan probe `quit()` tanpa `Audio.hentikan_sepeda()` + jeda singkat seperti runner tes (pilihan 1b-3 di Catatan Dev). Reproduksi: `godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_umpan_balik_jendela.gd -- <folder>`, lihat dua baris terakhir. Tangkapan tetap benar; tetapi baris `ERROR` di keluaran probe membuat "tanpa ERROR" tidak bisa dipakai sebagai penanda. Catatan: `godot --path . --quit-after 180` (game, jendela) keluar bersih karena jendela tanpa fokus langsung menjeda (bunyi berhenti); keluar saat bunyi berjalan (tutup jendela di desktop) belum diuji QA | OPEN | | |
| QA-004 | 1 | Minor | `export_presets.cfg:9-11`, `tools/ekspor_cek_render.py` | AC-8 meminta probe "tidak mengubah scene utama **atau isi APK normal**". Paket normal (`--export-pack "Android" build/qa-normal.pck`, QA) memuat `cek_render.scn`, `scripts/dev/cek_render.gdc` (+ `.remap`) dan shader; scene utama tetap `jalan_uji.tscn` dan tidak ada jalan pemain ke probe (diakui Dev, pilihan 1b-12). Perbaikan mungkin: `exclude_filter` preset normal mengecualikan berkas probe, dan `ekspor_cek_render.py` (yang sudah memulihkan `project.godot` byte demi byte) melepas pengecualian itu sementara. Tidak berbahaya untuk pemain; diputuskan di review PR | DEFERRED (tidak bisa dipicu pemain; ukuran kecil; keputusan pemilik di PR) | | |
| QA-005 | 1 | Minor | `scripts/config.gd` `KAMERA_SEPEDA_Y_PECAHAN`, `DORONGAN_MAJU_PX`; `docs/BALANCING.md` 2 | Angka paket pemilik dipasang benar dan lolos AC-6, tetapi dari ukuran QA (probe 640/780): (a) mundur penuh, sel sprite y 234–292 dan panel y 293: **jarak 1 px** di semua lebar; (b) 640 tangan kanan mundur penuh sprite x 170–216 berpotongan zona stick (x ≤ 192) 22×58 px; (c) jalan terlihat saat ngebut di 780 naik 2,10 → ~2,52 detik (+20%, SPEC menyebut "sekitar 25%"), di 640 justru turun 2,08 → ~2,03 detik (prinsip 1 dan 3: waktu bereaksi ngebut). Semua dicatat Dev; tidak ada pelanggaran SPEC, tetapi pemilik harus menilainya | NEEDS-MANUAL (uji 8.2: sepeda tertutup jempol di 16:9, jalan di depan saat ngebut di A54 dan layar 16:9) | | |
| QA-006 | 1 | Nit | `scripts/entities/umpan_balik_sepeda.gd`, `scripts/entities/pancaran_piksel.gd` | Partikel di ruang lokal sepeda: jejak debu ikut bergeser bersama sepeda saat pindah sisi (tidak tertinggal di jalan), dan garis kecepatan yang muncul di depan pengendara (asal x +30) tetap digambar di belakang sprite. Di tangkapan QA `iter1-qa/2340x1080_ngebut.png` 10 debu menumpuk menjadi satu goresan tipis krem di belakang roda dan 4 garis pendek; terbaca tapi samar. Placeholder (SPEC D-2), pengganti final `vfx_debu_roda.png` | DEFERRED (placeholder; keterbacaan di checklist 8.2) | | |

## NEEDS-MANUAL (uji di HP)
- [ ] (orchestrator) Probe render di A54: light 2D, glow, CPU/GPU partikel, shader warna bayangan; tangkapan layar + log ke `render_a54/`.
- [ ] Checklist uji 3-5 orang Fase 1 (`SETUP_ANDROID.md` 8.2).
- [ ] (QA-005) Di A54 dan satu HP 16:9 bila ada: tahan stick bawah sampai rem berhenti, lihat apakah jempol menutupi sepeda dan apakah sepeda nyaris menyentuh panel kecepatan; ngebut 6,0 u/d dan nilai apakah jalan di depan cukup jauh untuk bereaksi.
- [ ] (QA-002) Tahan jempol di tombol jeda, tekan home, kembali, ketuk "Lanjut": ikon jeda harus tampil normal (bukan terang/ditekan).
- [ ] Back Android: di jalan = layar jeda; di layar jeda = lanjut; app tidak keluar (`quit_on_go_back=false` hanya terbukti di desktop/tes).
- [ ] Ketukan tombol jeda dengan jari kedua saat jempol di stick (`TombolSentuh`), dan swipe sistem (gesture navigasi) di atas tombol tidak memicu jeda/lanjut (sentuhan `canceled`, QA-001 Q04).

## Keputusan & catatan
- Keputusan pemilik 2026-10-14 (lihat SPEC): lanjut tanpa catatan uji HP Run 1A; paket penyetelan usulan (tombol 42 px game ≈ 44 dp, HudLabel 8 px, stick 35 tetap, sepeda ~75% tinggi, dorongan maju 36); background/back/tombol membuka layar jeda tanpa lanjut otomatis.
- Orchestrator: `RUN_ID` diganti ke 2026-10-14 sesuai LOOP-DEV-QA 6b. Scope besar: iterasi 1 boleh dua pemanggilan Dev berurutan (1a: jeda + penyetelan + umpan balik visual + D-9; 1b: audio + probe render + dokumen) sebelum QA, mengikuti preseden run 0B+0C.
- A54 tidak terdeteksi `adb` saat persiapan (2026-10-14); dicek ulang sebelum tahap pasang APK.

## Catatan Dev

### Catatan Dev iterasi 1a

Bagian 1a dari iterasi 1 (jeda + penyetelan + umpan balik visual + D-9). Lingkungan: macOS (Apple M4, OpenGL 4.1 Metal), `godot --version` = `4.7.2.stable.official.ed1daf0bf`. Branch `feat/fase1b-umpan-balik`, tidak ada commit di `main`, **tidak push**, tidak menyentuh HP (`adb` tidak dipakai), tidak mengunduh apa pun. `DEV_PHASES.md` dan `ROADMAP.md` tidak diedit. **Tidak ada BLOCKED.**

Commit (urut): `304fe06` feat: tombol dan layar jeda, back, tombol 42 px; `a1de874` tune: sepeda 0,75, dorongan 36, HudLabel 8; `e17131e` feat: umpan balik kecepatan (debu, garis); `a962a47` fix: tombol Lanjut bergaris `TEXT`; `d0dbacc` test: QA-001 dan QA-002; `179fb1a` test: ketukan jari kedua dari input bersih (hasil mutan M24); `80ebc0a` test: probe jendela + tangkapan layar AC-9; lalu commit LOG ini. Tiap commit diperiksa di klon bersih (`git clone`, checkout commit, `rm -rf .godot`, import, `run_tests`, `cek_keluaran_tes.py --ketat`): semuanya hijau, import 0 ERROR/WARNING, `git status --porcelain -uall` kosong (lihat catatan "sekali tidak terulang" di Gerbang).

#### Bukti per AC (bagian 1a)

| AC | Bukti |
|---|---|
| AC-2 | `scripts/systems/umpan_balik_kecepatan.gd` (`laju_debu`, `kekuatan_garis`, `laju_garis`). `tests/tes_umpan_balik.gd`: `_test_debu` (0 di 0..2,999999; tepat 3,0 = laju minimum, inklusif; 3,75/4,5 linear; 6,0 maksimum; 6,5 dan 100 dijepit; monoton 0..7; debu rem 40/d juga di bawah 3,0 dan di 6,0; rem di 0 = 0; tanpa rem di 2,0 = 0; kurangi efek x0,5 di empat kasus), `_test_garis` (0 di bawah 4,5; tepat 4,5 = 0,25 inklusif; 4,875/5,25 linear; 6,0 = 1; 7 dan 1000 dijepit; laju = kekuatan x 14; kurangi efek = 0), `_test_masukan_aneh_dan_murni` (NaN, INF, -INF, -1, -0,0001 = 0 dengan dan tanpa rem; 500 masukan acak seed tetap: sama untuk masukan sama, dalam rentang). |
| AC-3 | `scripts/entities/pancaran_piksel.gd` + `umpan_balik_sepeda.gd` + `scenes/entities/umpan_balik_sepeda.tscn` (anak `SepedaUji`, digambar di belakang sprite). `tes_umpan_balik.gd` `_test_pancaran` (laju, batas 5, sejajar arah, habis umur, dt aneh) dan `_test_scene` di `jalan_uji.tscn` 780: tanpa `GPUParticles2D`/`CPUParticles2D`, dua `PancaranPiksel`; warna `Color(Palette.TEXT_2, 0,85)` dan `Color(Palette.TEXT, 0,7)`; arah = kebalikan arah jalan dari `Iso`; santai: debu tipis, 0 garis; ngebut: garis memancar (>0), debu lebih banyak dari santai; jumlah <= batas Config; stick dilepas: laju = rumus dari kecepatan sebenarnya; rem bergerak: debu rem 40/d; berhenti: 0 dan habis; kurangi efek di scene. `_test_scene_jeda`: kontrol (tanpa jeda posisi debu berubah dengan sendirinya), selama jeda 8 frame jumlah dan posisi debu dan garis tetap, `can_process()` false; sesudah lanjut bergerak lagi. |
| AC-6 | `scripts/config.gd`: `HUD_TOMBOL_TINGGI_PX` 42, `HUD_JEDA_SENTUH_PX` 42, `KAMERA_SEPEDA_Y_PECAHAN` **0,75** (tidak menabrak, jadi dipakai apa adanya), `DORONGAN_MAJU_PX` 36, mundur 20, respon 0,35, `STICK_RADIUS_PX` 35; `assets/ui/theme.tres` `HudLabel` 8. `tests/tes_tata_letak.gd` (640/780/800 x kanan/kidal, scene sungguhan, dorongan dijalankan sampai penuh lewat keyboard editor, galat < 0,05 px): (a) sel sprite 46x58 di maju penuh dan mundur penuh tidak berpotongan dengan panel (termasuk tepi) dan di dalam layar; (b) tombol kidal 96x42 dan jeda 42x42 di strip atas (y 4–46), tidak bertumpuk, tidak masuk zona stick/swipe kedua mode tangan, tombol jeda tetap (17, 4) saat kidal; (c) panel bawah di layar dan tidak masuk zona stick. Angka hasil: panel kecepatan y 293–352 (tinggi 59, dulu 57 dengan teks 6 px); sprite maju penuh y 206–264 (jarak ke panel 29 px), **mundur penuh y 234–292: jarak tegak ke panel hanya 1 px** di semua lebar (horizontal beririsan di 640/780/800 tangan kanan). BALANCING 2/10 dan DESIGN_SPEC 1.2/3.1 di commit yang sama (`a1de874`, `304fe06`). |
| AC-7 | `scripts/systems/jeda_sim.gd` (enum `Peristiwa {TIDAK_ADA, JEDA, LANJUT, BACK}`, `peristiwa_dari_notifikasi`, `jeda_sesudah`, `baru_lanjut_sesudah`, `dt_efektif`), `JalanUji` (`minta_jeda`, `minta_lanjut`, `_terapkan_jeda`, `SceneTree.paused`, sinyal `jeda_berubah`, `_exit_tree` melepas pause), `scripts/ui/tombol_jeda.gd`, `tombol_sentuh.gd`, `layar_jeda.gd` + `scenes/ui/layar_jeda.tscn` (`process_mode` WHEN_PAUSED, layer 20), `translations/ui.csv` (+`JEDA_JUDUL`, `JEDA_LANJUT`), `project.godot` `config/quit_on_go_back=false`. Murni: `tes_gerak.gd` `_test_jeda_sim` (tabel 12 baris notifikasi x status; RESUMED/FOCUS_IN = TIDAK_ADA; Lanjut; back membalik; urutan Android FOCUS_OUT, PAUSED, RESUMED, FOCUS_IN = tetap jeda; lanjut lewat Lanjut dan lewat back: dt pertama 0 lalu normal). Scene: `tests/tes_jeda_scene.gd` untuk lima pemicu (tombol `pressed.emit()`, tombol lewat `Input.parse_input_event`, FOCUS_OUT, PAUSED, back): layar jeda tampil + `SceneTree.paused`, `jeda_berubah(true)` sekali, stick/swipe dilepas, lempar ditutup, lama tahan 0; FOCUS_IN/RESUMED/ulang tidak menutup; `perbarui`/`_process` dt 1/60..100 tidak mengubah kecepatan, jarak, lateral, stamina, lama tahan, dorongan; frame dan progres `AnimatedSprite2D` tidak maju 6 frame (QA-007; kontrol tanpa jeda maju); sentuhan di zona stick dan swipe tidak memunculkan stick/lempar; lanjut (emit, sentuh Lanjut, atau back): dt pertama 0, stick harus disentuh ulang, rem 14 langkah belum / 15 langkah aktif, sprite berputar lagi. `_test_tombol_dan_layar` (area >= 42, gambar tepat (26, 8, 24, 24), tanpa teks/PNG, kunci terjemahan, `HUD_PANEL`, Lanjut tinggi >= 42 bergaris `TEXT`, lapisan menutup layar), `_test_back_dua_kali_dan_urutan`, `_test_ketuk_jari_kedua`, `_test_proyek_back`. Partikel berhenti: AC-3. Audio: bagian 1b (lihat bawah). |
| AC-9 (sebagian) | `tests/probe_umpan_balik_jendela.gd`, jendela asli, renderer `gl_compatibility`: `godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_umpan_balik_jendela.gd -- docs/loop/20261014-fase1b-umpan-balik/shots` dan sama dengan `1920x1080`. 12 berkas `{2340,1920}x1080_{santai,ngebut,rem,rem_berhenti,jeda,kidal_ngebut}.png`. Keadaan saat foto (780): santai 3,00 u/d debu 2 garis 0; ngebut 6,00 debu 9 garis 4, dorongan (35,96, -17,98); rem 4,50 rem aktif debu 13 (laju 40); rem berhenti 0,00 dorongan (-19,98, 9,99) debu 0; jeda (layar jeda, `jeda true`); kidal ngebut. 640 sama, sepeda di (213, 270) santai, (249, 252) ngebut, (193, 280) mundur penuh. Tombol jeda (17, 4, 42x42) gambar (26, 8, 24x24), tombol kidal 96x42, teks HUD 8 px terlihat di semua foto. `python3 tools/cek_blok_piksel.py 3 --kecualikan <tombol kidal> --kecualikan <panel> [--kecualikan <judul jeda> --kecualikan <Lanjut>]` (kotak dicetak probe): 12 berkas, 0 blok tidak seragam (partikel dan tombol jeda termasuk). Kontrol negatif: `2340x1080_ngebut.png` tanpa pengecualian = 664 blok tidak seragam (teks), exit 1. Yang saya lihat: debu krem di belakang roda belakang menjauh ke kiri bawah, gumpalan lebih tebal saat rem; garis putus bertangga 2:1 putih di sekitar pengendara saat ngebut, tidak ada saat santai; layar jeda gelap dengan "JEDA" dan tombol "Lanjut"; di 640 mundur penuh sepeda tepat di atas panel kecepatan dan dekat cincin stick. |
| AC-10 | `tes_gerak_scene.gd` `_test_stamina_di_scene` (QA-001: tiap langkah selama lelah dengan 0 < stamina < 30 penanda LELAH tampil; hilang tepat saat lelah padam, 101..139 langkah); `tes_gerak.gd` `_test_pose_langkah_tepat` (QA-002: dari tujuan + 0,06 satu langkah ke tujuan + 0,0267 = melambat; dari tujuan + 0,1 = meluncur; dari santai langkah pertama = meluncur). Mutan Q05 dan Q04 kini mati (M27, M28). |
| AC-11 (bagian 1a) | Lihat "Mutan nyata". |
| AC-12 | Penjaga lama lolos untuk semua berkas baru (tab, static typing, `##` bahasa Indonesia, tanpa angka literal di systems/entities/ui selain 0/1/2/-1/-2, tanpa hex, tanpa `Color.X`, kunci terjemahan, tanpa kiri/kanan untuk sisi). Semua angka baru di Config satu baris; `ConfigParser` membaca semuanya ("parser membaca semua konstanta Config"). `PancaranPiksel` memesan larik sekali (`siapkan`), `maju` tanpa alokasi. |
| AC-13 (bagian 1a) | `BALANCING.md` 2 (paragraf jeda, baris tombol 42 dan tombol jeda, letak sepeda 75%, dorongan 36, tabel umpan balik kecepatan, paragraf jalan terlihat saat ngebut) dan 10 (2026-10-14); `DESIGN_SPEC.md` 1.2 (Label 8), 3.1 (area sentuh jeda), 4 (layar jeda sementara, 🟡); `ART_DIRECTION.md` 2.3 (placeholder partikel); `GDD.md` 15 (kalimat "kompensasinya ... masih usulan" diperbarui dengan angka jalan terlihat). |

#### Pilihan di luar SPEC (bisa ditolak di review)

1. **Jeda = `SceneTree.paused`** (saran SPEC). Layar jeda `PROCESS_MODE_WHEN_PAUSED`; HUD, kontrol, sprite, partikel pausable. Titik kait `Audio` untuk bagian 1b: sinyal `JalanUji.jeda_berubah(jeda: bool)`, `JalanUji.sedang_jeda()`, dan pause pohon sendiri (pemutar yang pausable ikut berhenti). `JalanUji._exit_tree` melepas pause bila scene dibuang saat jeda.
2. **`TombolSentuh` (temuan saat kerja, bukan di SPEC).** Percobaan headless: sesudah tombol jeda diketuk jari pertama (yang menjeda pohon), lalu lanjut, lalu jempol di stick dan jari kedua mengetuk jeda, `Button` tidak menerima ketukan (`[true, false, false]`); di scene segar ketukan jari kedua berfungsi. Penyebab pastinya di GUI Godot (emulasi mouse dari jari pertama) tidak saya telusuri. Perbaikan: tombol jeda dan Lanjut membaca `InputEventScreenTouch` sendiri di `_input` (turun dan naik di dalam tombol = `ditekan`), klik mouse tetap lewat `pressed`; dua jalur dalam satu frame dipicu sekali (`Engine.get_process_frames`). Akibat kecil: dua ketukan pada tombol yang SAMA dalam satu frame proses dihitung sekali. Perlu dicoba di A54 (NEEDS-MANUAL).
3. **Letak area sentuh jeda**: gambar tetap (26, 8) sesuai SPEC; area 42x42 dipusatkan mendatar (x 17–59) dan sejajar tombol kidal di atas (y 4–46), jadi gambar tidak di tengah tegak area sentuhnya.
4. **`HUD_TOMBOL_TINGGI_PX` 36 -> 42 masuk commit jeda** (`304fe06`), bukan commit tune, karena tombol Lanjut (AC-7) harus >= 42 dan memakai konstanta yang sama.
5. **Partikel digambar sendiri (`PancaranPiksel`)**, bukan `CPUParticles2D`: posisi partikel CPUParticles2D tidak dibulatkan ke piksel game, sehingga dengan stretch `canvas_items` x3 kotak 1 px jatuh di antara blok (dibuktikan tidak langsung oleh mutan M31: tanpa pembulatan, `cek_blok_piksel` menemukan 7/116/64 blok tidak seragam di santai/ngebut/rem). SPEC mengizinkan "_draw sendiri". Partikel di ruang lokal sepeda (ekor pendek ikut sepeda), acak dengan `RandomNumberGenerator` benih tetap 1 dan 2.
6. **Debu sudah ada di santai** (tepat 3,0 inklusif = 4/detik): SPEC "di bawah santai 3,0 tidak berdebu" saya baca sebagai ambang inklusif. **Garis punya kekuatan minimum 0,25 tepat di 4,5** supaya "mulai di 4,5" terlihat dan ambang `>=` bisa dibedakan dari `>` (dengan rumus dari 0 mutan M01 setara). Laju garis = kekuatan x 14/detik (SPEC: "alpha atau jumlahnya"; saya memakai jumlah, alpha tetap 0,7).
7. **Warna partikel tanpa token baru**: debu `TEXT_2` (krem) alpha 0,85, garis `TEXT` alpha 0,7. Dicatat di ART_DIRECTION 2.3.
8. **Tombol Lanjut bergaris `TEXT`** (`a962a47`): dari tangkapan layar, garis `OUTLINE` tidak terlihat di atas lapisan gelap.
9. **`GayaHud`** (`scripts/ui/gaya_hud.gd`): gaya kotak/tombol yang dulu privat di `HudDev` dipindah supaya `LayarJeda` memakai bentuk yang sama.
10. **Awalan kunci terjemahan `JEDA_`**: pemeriksa kunci di `run_tests.gd` dulu hanya menerima `HUD_`; kini `HUD_` atau `JEDA_` (rule `content-data`: awalan per layar), dengan kontrol negatif.
11. **Jalan terlihat saat ngebut** (dihitung, dicatat di BALANCING 2 dan GDD 15): 780 dari ~2,10 ke ~2,52 detik, 800 ke ~2,59; **640 (16:9) justru ~2,08 -> ~2,03 detik** karena jalan keluar layar lewat tepi kanan (menurunkan sepeda tidak menolong, dorongan 36 memperpendek). Tidak mengubah angka; untuk dinilai pemilik.
12. `KontrolTouch.lepas_semua()` baru; handler notifikasinya sendiri dipertahankan (dobel dengan `JalanUji`, aman).

#### Tes lama yang diubah (alasan)

| Tes | Perubahan | Alasan |
|---|---|---|
| `tes_gerak.gd` `_test_jeda_sim` | Ditulis ulang untuk `JedaSim.Peristiwa` (tabel, Lanjut, back, urutan Android tetap jeda) | D-6: tanpa lanjut otomatis; API notifikasi lama (`notifikasi_lanjut`) dihapus |
| `tes_gerak_scene.gd` `_test_jeda` | Dihapus, digantikan `tes_jeda_scene.gd` `_test_jeda_lengkap` (lebih luas) | Memeriksa "lanjut otomatis" FOCUS_IN/RESUMED |
| `tes_gerak_scene.gd` `_test_jeda_di_tengah_tahan_rem` | Sesudah FOCUS_IN ditambah cek "tetap jeda" lalu `minta_lanjut()` | D-6 |
| `tes_gerak_scene.gd` `_test_stamina_di_scene` | "meluncur 1,67 detik masih lelah" diganti loop tiap langkah (QA-001); cek akhir ditambah 100 < langkah < 140 | D-9 |
| `tes_input_scene.gd` `_test_input_terpadu` | FOCUS_IN: "lanjut" -> "tetap jeda" lalu `minta_lanjut()`; sesudah PAUSED `minta_lanjut()` | D-6; selama jeda input berhenti, jadi tes input sesudahnya butuh lanjut |
| `tes_input_scene.gd` `_test_lempar_batal` (a, b, d, e) | `minta_lanjut()` sesudah FOCUS_OUT/PAUSED | D-6 (sama) |
| `tes_input_scene.gd` HUD kontainer | StripJeda diterima sebagai kontainer anchor ketiga (+cek anchor dan tema) | Tombol jeda baru |
| `tes_input_scene.gd` `_test_kidal_dan_hud` | Font label 6 -> 8 | D-7 |
| `tes_input_scene.gd` `_test_dorongan_kecepatan_scene` | Hanya label "(28, -14)" -> "maju penuh" (nilai sudah dari Config) | D-7 |
| `tes_input_murni.gd` `_test_dorongan_kecepatan` | 28 -> 36: (28,-14) -> (36,-18), (14,-7) -> (18,-9), pembagi 63,2% | D-7 |
| `run_tests.gd` terjemahan | Awalan `JEDA_` diterima | Kunci SPEC `JEDA_JUDUL`, `JEDA_LANJUT` |
| `probe_gerak_jendela.gd` | Saat jeda karena fokus: `minta_lanjut()` bukan FOCUS_IN | D-6 |

Tes baru: `tes_jeda_scene.gd`, `tes_tata_letak.gd`, `tes_umpan_balik.gd`, `_test_pose_langkah_tepat`. Jumlah pemeriksaan 3886 (`main`) -> 4357.

#### Gerbang (di `HEAD` `80ebc0a`, sebelum commit LOG)

```
godot --headless --import                                   # 0 baris ERROR/WARNING
mkdir -p build && godot --headless --script res://tests/run_tests.gd 2>&1 | tee build/tests.log   # 4357 lolos, 0 gagal
python3 tools/cek_keluaran_tes.py --ketat build/tests.log   # pemeriksa: lolos (4357 lolos, 0 gagal, 0 peringatan)
python3 tools/tests_cek/uji_pemeriksa.py                    # 16 kasus, 0 menyimpang
python3 tools/tests_cek/uji_bangun_frames.py                # 41 lolos, 0 gagal
godot --headless --path . --quit-after 2                    # 0 ERROR/WARNING
godot --headless --path . --script res://tests/probe_layar.gd   # 0 ERROR, 0 PECAHAN
git diff main --name-only | grep -E "keystore|\.apk|\.aab|\.godot/|^build/|^builds/|\.jks|\.p12|export_credentials|override.cfg"   # kosong
```
Klon bersih per commit: semua hijau. **Catatan jujur:** pada putaran pertama pemeriksaan per commit, `304fe06` sekali menghasilkan baris `ERROR` saat keluar (ekor log `at: clear (core/io/resource.cpp:822)`, pemeriksa exit 1). Tidak terulang di 2 klon segar berikutnya (import lalu tes) maupun 3 putaran ulang; `HEAD` 6 putaran berturut-turut hijau (3-4 detik). Log putaran itu tidak tersimpan. QA sebaiknya menjalankan beberapa putaran.
Autoload `Audio` belum ada (bagian 1b), jadi butir AC-1 "dengan autoload Audio terdaftar" dan `uji_sintesis_sepeda.py` belum berlaku di 1a.

#### Mutan nyata (AC-11, bagian 1a)

Skrip sementara di scratchpad (tidak di-commit): tiap mutan mengganti satu potongan kode, menjalankan `run_tests.gd` + `cek_keluaran_tes.py --ketat`, lalu memulihkan berkas (`git status` bersih sesudahnya). Mutan wajib SPEC untuk bagian ini: ambang garis (M01), debu tidak dijepit (M02), FOCUS_IN melanjutkan (M10), dt pertama tidak 0 (M12), sprite tidak dihentikan saat jeda (M14, M15), back tidak menjeda (M16). Mutan `BunyiSepeda`/audio (pitch tangga, rem tiap frame, bunyi tidak berhenti saat jeda) = bagian 1b.

| Mutan | Hasil | Tes yang menangkap (contoh) |
|---|---|---|
| M01 ambang garis `>=` -> `>` | 1 gagal | "tepat 4,5 (inklusif): garis mulai tampil" |
| M02 debu tidak dijepit | 2 gagal | "di atas ngebut dijepit ke maksimum", 500 acak dalam rentang |
| M03 ambang debu `>=` -> `>` | 3 gagal | "tepat di ambang 3,0 (inklusif)" |
| M04 debu rem juga di kecepatan 0 | 3 gagal | "rem aktif di kecepatan 0: tanpa debu", scene "rem sampai berhenti" |
| M05 kurangi efek tidak mematikan garis | 5 gagal | "kurangi efek di 4,5: garis mati" |
| M06 garis tangga (1 begitu lewat ambang) | 3 gagal | "5,25: separuh jalan (linear)" |
| M07 batas partikel diabaikan | 2 gagal | "dibatasi 5 (batas)", "laju besar tidak melewati batas" |
| M08 laju dari tujuan stick, bukan kecepatan | 3 gagal | scene "stick dilepas: laju dari kecepatan sebenarnya" |
| M09 partikel `PROCESS_MODE_ALWAYS` | 1 gagal | "selama jeda partikel tidak memancar dan tidak bergerak" |
| M10 FOCUS_IN melanjutkan | 44 gagal | tabel notifikasi, scene "FOCUS_IN/RESUMED tidak menutup layar jeda" |
| M11 RESUMED melanjutkan | 14 gagal | sama |
| M12 dt pertama sesudah lanjut tidak 0 | 13 gagal | `dt_efektif`, scene "langkah pertama sesudah lanjut ber-dt 0" |
| M13 `baru_lanjut` tidak menyala | 14 gagal | tabel, scene |
| M14 pohon tidak di-pause (sprite/partikel/input jalan) | 26 gagal | "SceneTree.paused menyala", frame sprite (QA-007), sentuhan selama jeda |
| M15 sprite pemain `PROCESS_MODE_ALWAYS` | 5 gagal | "frame AnimatedSprite2D pemain tidak maju selama jeda (QA-007)" |
| M16 back tidak menjeda | 7 gagal | tabel back, scene BACK |
| M17 back saat jeda tidak melanjutkan | 9 gagal | tabel, `_test_back_dua_kali_dan_urutan` |
| M18 back tidak dikenali | 14 gagal | "notifikasi 1007 = peristiwa BACK" (juga penjaga angka literal) |
| M19 tombol jeda tidak tersambung | 7 gagal | TOMBOL_EMIT/TOMBOL_SENTUH |
| M20 layar jeda tidak ditampilkan | 20 gagal | "layar jeda terbuka" |
| M21 jeda tidak melepas jari | 3 gagal | "stick dan swipe dilepas" |
| M22 `_exit_tree` tidak melepas pause | 14 gagal | "scene dibuang saat jeda: pause pohon dilepas" |
| M23 `jeda_berubah` tidak dipancarkan | 15 gagal | "jeda_berubah(true) sekali (titik kait Audio)" |
| M24 `TombolSentuh` tanpa jalur sentuh | **awalnya HIDUP**, kini 1 gagal | "ketukan jari pertama dan jari kedua ...". Hidup karena jari yang tertinggal dari tes sebelumnya membuat emulasi mouse menempel ke jari itu; dibunuh dengan mengangkat semua jari dulu (`179fb1a`) |
| M25 `TombolSentuh` memicu saat naik di luar | 1 gagal | "jari yang hanya naik atau hanya turun di dalam tombol jeda tidak menjeda" |
| M26 `quit_on_go_back` dihapus (true) | 2 gagal | `_test_proyek_back` |
| M27 Q05: penanda LELAH hanya di stamina 0 (QA-001) | 1 gagal | "QA-001: selama lelah dengan 0 < stamina < 30 ..." |
| M28 Q04: pose dari kecepatan awal langkah (QA-002) | 1 gagal + SCRIPT ERROR | "langkah yang membawa kecepatan ke dalam toleransi langsung melambat" |
| M29 sepeda 0,8 tinggi layar | 4 gagal | angka paket, "640 kanan mundur: persegi sprite ... tidak berpotongan dengan panel" |
| M30 tombol jeda dicerminkan saat kidal | 4 gagal | "tombol jeda tidak dicerminkan saat kidal" (+ penjaga literal) |
| M31 posisi partikel tidak dibulatkan | **HIDUP di `run_tests`** | Visual: tidak ada tes yang membaca piksel `_draw`. Tertangkap `cek_blok_piksel.py 3` pada tangkapan probe dengan mutan (7/116/64 blok tidak seragam di santai/ngebut/rem, exit 1); kode asli 0. Bukti visual AC-9, bukan tes otomatis |

Ringkas: 31 mutan, 30 tertangkap `run_tests` (M24 sesudah perbaikan tes), 1 hidup (M31) yang tertangkap pemeriksa blok piksel. Kode dikembalikan sesudah tiap mutan (`git status` bersih).

#### Potongan sprite dengan zona stick di 640 (AC-6, NEEDS-MANUAL untuk 16:9)

Sel sprite 46x58 (dari `tes_tata_letak.gd`, baris `[tata_letak]` di `build/tests.log`):
- Tangan kanan, maju penuh: sprite (226, 206)–(272, 264), zona stick (8, 186)–(192, 352): **tidak berpotongan**.
- Tangan kanan, mundur penuh (melambat/rem): sprite (170, 234)–(216, 292): **berpotongan 22x58 = 1276 px²** (x 170–192, seluruh tinggi sel). Jempol di zona stick bisa menutupi bagian kiri sepeda saat mundur penuh di layar 16:9 (di 780/800 sprite mundur mulai x 217/224, di luar zona stick x <= 192).
- Kidal (zona stick x 448–632): tidak berpotongan, maju maupun mundur.
- Catatan: jarak tegak sprite mundur penuh ke panel kecepatan hanya 1 px di semua lebar; bila panel bertambah tinggi (mis. baris koran nanti), 0,75 akan menabrak.

#### NEEDS-MANUAL tambahan dari bagian 1a

- Tombol jeda (gambar 24x24, area 42x42) mudah ditekan sengaja dan tidak tersentuh saat bermain; ketukan jari kedua saat jempol di stick berfungsi di A54 (`TombolSentuh`).
- Back Android menjeda dan (di layar jeda) melanjutkan; kembali dari home menampilkan layar jeda, tidak jalan sendiri.
- Debu dan garis kecepatan terbaca dan tidak mengganggu jalan di depan; garis bertangga 2:1 terbaca sebagai garis, bukan titik.
- Sepeda 75% dan dorongan 36: jalan di depan saat ngebut cukup di A54 (~2,5 detik); di 16:9 tetap ~2,0 detik dan sprite mundur penuh tertutup jempol sebagian.
- Tombol 42 px dan teks HUD 8 px nyaman dan terbaca.

#### Belum dikerjakan (untuk bagian 1b)

- D-3/D-4/D-5: `scripts/autoload/audio.gd` + daftar autoload di `project.godot`, `scripts/systems/bunyi_sepeda.gd`, `default_bus_layout.tres` (`Master` -> `SFX` -> `Sepeda`), `tools/audio_art/sintesis_sepeda.py` + README, tiga WAV + `.import` (loop), `assets/audio/LICENSES.md`, `tools/tests_cek/uji_sintesis_sepeda.py` (+ CI `tes.yml`), tes AC-4/AC-5, audio berhenti saat jeda (kaitkan ke `JalanUji.jeda_berubah`/`SceneTree.paused`; data pose ada di `SepedaUji.gerak` lewat `hasil.pose`, kecepatan dan rem di `SepedaUji.keadaan`; `BikeMotion.jeda` sudah memadamkan rem sehingga tepi naik rem lama tidak tersisa).
- D-8: probe render `scenes/dev/cek_render.tscn` + skrip, cara membuka di APK, `SETUP_ANDROID.md` (probe render dan **8.2 checklist 3-5 orang**, termasuk butir NEEDS-MANUAL di atas).
- AC-11 mutan audio (pitch tangga, rem tiap frame, bunyi tidak berhenti saat jeda).
- AC-13 sisanya: `SOUND_DESIGN.md`, `TECH_PLAN.md` 3.1, `SETUP_ANDROID.md`, `AGENTS.md` dan `.cursor/rules/00-project-core.mdc` (perintah probe jendela baru `tests/probe_umpan_balik_jendela.gd`, `scripts/autoload/`, `assets/audio/`, peta repo: `layar_jeda`, `tombol_jeda`, `tombol_sentuh`, `gaya_hud`, `umpan_balik_kecepatan`, `pancaran_piksel`, `umpan_balik_sepeda`, tes baru), `docs/README.md` (status).
- AC-9 sisanya bila ada: tidak ada untuk 1a.

### Catatan Dev iterasi 1b

Bagian 1b dari iterasi 1 (audio, probe render, mutan, dokumen). Lingkungan sama dengan 1a (macOS, Apple M4, OpenGL 4.1 Metal, `godot` 4.7.2.stable.official.ed1daf0bf). Branch `feat/fase1b-umpan-balik`, tidak ada commit di `main`, **tidak push**, tidak menyentuh HP/`adb` (ekspor APK hanya menulis `builds/`), tidak mengunduh apa pun, Editor Settings tidak diubah. `DEV_PHASES.md` dan `ROADMAP.md` tidak diedit. Bagian 1a tidak diubah kecuali tambahan cek audio di `tes_jeda_scene.gd` dan kabel `Audio` di `JalanUji` (dicatat di bawah). **Tidak ada BLOCKED.**

Commit (urut): `e37577c` feat: bunyi sepeda placeholder lewat autoload Audio dan sintesis stdlib (skrip sintesis + tiga WAV + `.import` di commit yang sama; `Config` + `BALANCING` di commit yang sama); `7e27409` feat: probe render Compatibility; `6cc6d83` test: perbarui_sepeda dengan jeda menghentikan decit (mutan M44); `57b4a0f` docs: probe di HP, checklist 8.2, perintah dan peta repo; lalu commit LOG ini.

#### Bukti per AC (bagian 1b)

| AC | Bukti |
|---|---|
| AC-1 | Lihat "Gerbang". Autoload terdaftar: `project.godot` `[autoload] Audio="*res://scripts/autoload/audio.gd"`; `--quit-after 2` 0 ERROR/WARNING dengan autoload itu. |
| AC-4 | `scripts/systems/bunyi_sepeda.gd` (`loop_aktif`, `pitch_kayuh`, `rem_dipicu`), `scripts/autoload/audio.gd`, `default_bus_layout.tres` (Master -> SFX -> Sepeda, 0 dB, tanpa efek). `tests/tes_bunyi.gd`: pitch 1,0/1,15/1,3 di 3,0/4,5/6,0, 3,75 = 1,075 dan 5,25 = 1,225 (linear), dijepit di bawah (0, 1,5, -5, -INF, NaN = 1,0) dan di atas (6,0001..INF = 1,3), monoton, naik di >= 290 dari 300 langkah 0,01 (bukan tangga); tabel 18 baris pose x kecepatan x rem x jeda (kayuh/melambat = kayuh, meluncur = freewheel, rem = diam, 0/NaN/INF/negatif = diam, jeda = diam); tepi naik rem (urutan 17 langkah: dipicu hanya di 2, 6, 16; tidak tiap langkah selama ditahan; rem yang menyala selama jeda tidak menyusul sesudah lanjut); autoload `load().new()` tanpa tree lalu `free()` (keputusan dihitung, tidak ada stream diputar, `PROCESS_MODE_ALWAYS`, tiga pemutar di bus Sepeda dengan volume Config); `audio.gd` tanpa komentar tidak memuat nama autoload mana pun (dari `ProjectSettings` + daftar TECH_PLAN 3.1) dan tidak mencari `/root/` (pemeriksa punya kontrol negatif); bus dari `AudioServer`; tiga stream: PCM 16-bit mono 22050 Hz, durasi, `.import` loop_mode 2/2/1 dan compress 0; **loop sungguhan**: ketiganya diputar di driver Dummy, sesudah 1,3 detik kedua loop masih berbunyi dan posisinya kembali ke awal, decit berhenti sendiri (sekitar 450-500 ms). Scene `jalan_uji.tscn` + `/root/Audio`: santai = kayuh pitch 1,0; mempercepat = pitch dari kecepatan sebenarnya; ngebut = 1,3; meluncur = freewheel, kayuh diam; rem: 14 langkah belum, langkah 15 decit sekali, 90 langkah lagi tetap sekali, loop diam; lepas lalu tahan lagi = decit lagi; jeda saat decit berbunyi = semua berhenti, tetap diam walau `perbarui(0,1)`; lanjut = tanpa decit lama, kayuh lagi; FOCUS_OUT = jeda + diam, FOCUS_IN tidak menyalakan; scene dibuang = diam. |
| AC-5 | `tools/audio_art/sintesis_sepeda.py` (stdlib `argparse, math, os, random, struct, sys, wave`; benih tetap 20261014) + README; WAV di `assets/audio/sfx/bike/` (nama SOUND_DESIGN 6): pedal 1,000 detik, freewheel 1,000 detik, rem 0,450 detik, total 108 KB (< 500 KB). `tools/tests_cek/uji_sintesis_sepeda.py` (32 pemeriksaan): stdlib saja (AST), dua kali jalan byte sama, berkas repo = keluaran skrip, format, durasi, tidak senyap, sambungan loop (sampel awal dan akhir <= 1% skala penuh, lompatan <= 2%; kenyataannya 0 dan 0), rem mulai dan berakhir tepat 0, `.import`, total, `assets/audio/LICENSES.md` mencatat ketiganya; kontrol negatif (1 byte diubah, loop berklik di awal/akhir, skrip yang mengimpor numpy/PIL). CI `.github/workflows/tes.yml` menjalankan uji ini bersama dua uji alat lain. |
| AC-7 (audio) | `tes_jeda_scene.gd` `_test_jeda_lengkap` untuk lima pemicu: sebelum jeda loop kayuh berbunyi; selama jeda `ada_bunyi()` false dan `sedang_jeda()` true; sesudah lanjut rem ditahan ulang = decit tepat sekali (tidak ada decit tertunda). |
| AC-8 | `scenes/dev/cek_render.tscn` + `scripts/dev/cek_render.gd`, `assets/shaders/warna_bayangan.gdshader`, token usulan `Palette.BAYANGAN_CONTOH` `#2E3550` (DESIGN_SPEC 1.1 "Dunia"), `tools/ekspor_cek_render.py`. Headless (`godot --headless --path . scenes/dev/cek_render.tscn`): 7 baris `[cek_render]` (perangkat, light2d, glow, cpu_partikel, gpu_partikel, shader_bayangan, ringkasan), piksel "tidak bisa dibaca headless", ringkasan `tidak_terbaca`, keluar sendiri, tanpa SCRIPT ERROR. `tests/tes_cek_render.gd`: pembantu murni (`adalah_penanda`, `campur`, `cocok`), node fitur (PointLight2D PCF5 + tekstur `GradientTexture2D`, occluder, CanvasModulate, WorldEnvironment Canvas glow layer 0, CPU + GPU partikel memancar, shader dengan BAYANGAN_CONTOH dan alpha 71/255, sprite kontrol tanpa shader), laporan headless tidak mengklaim apa pun, isolasi (scene utama jalan_uji, tidak ada `override.cfg`, `.gitignore` menutupnya, tidak ada skrip/scene game yang merujuk probe). Hasil desktop dan APK: lihat "Hasil probe desktop" dan "Cara membuka probe di APK". |
| AC-11 (1b) | Lihat "Mutan nyata (bagian 1b)". |
| AC-12 | Penjaga lama lolos untuk semua berkas baru (tab, typing, `##`, tanpa hex di luar palette, tanpa `Color.X`, tanpa kiri/kanan). Pemindai angka literal kini juga memindai `scripts/autoload/` (audio.gd tanpa literal; semua angka di Config `AUDIO_*`, satu baris, `ConfigParser` membaca semuanya). `scripts/dev/cek_render.gd` memakai konstanta bernama lokal (tata letak probe, bukan angka tuning game; tidak dipindai, lihat pilihan 6). `Audio` tidak mengalokasi per langkah (tiga fungsi statis murni, set `pitch_scale`). |
| AC-13 (1b) | `SOUND_DESIGN.md` (status, 3.2 tabel placeholder dan tempo, 6 bus yang ada, perilaku jeda/background, 8), `TECH_PLAN.md` 3.1 (`Audio` sudah ada), `BALANCING.md` 2 (tabel bunyi sepeda: pitch, volume) dan 10, `SETUP_ANDROID.md` 6.1 (probe render: arti hasil, cara membuka, perintah desktop, perintah A54 untuk orchestrator) dan **8.2** (checklist 3-5 orang: gabungan 8.1 + 1B, QA-005, QA-006, kriteria "Selesai kalau", langkah per penguji, lembar catatan tanpa data pribadi; 8.1 ditandai digabung), `AGENTS.md` dan `00-project-core.mdc` (perintah sintesis, uji alat, probe render, ekspor probe, probe jendela umpan balik, peta repo `scripts/autoload/`, `assets/audio/`, `assets/shaders/`, berkas 1a, tes baru), `docs/README.md` (status: run 1A ter-merge PR #20, run 1B; struktur), `assets/LICENSES.md` (merujuk `assets/audio/LICENSES.md`), `DESIGN_SPEC.md` 1.1 (token BAYANGAN_CONTOH). Konsistensi dokumen 1a: README masih menyebut run 1A "belum di-merge" (diperbaiki); dokumen lain 1a sejalan. |

#### Pilihan di luar SPEC (bisa ditolak di review)

1. **Decit rem tidak dipicu di kecepatan 0** (tepi naik rem saat sepeda sudah diam, mis. menahan stick bawah dari awal). Sejalan dengan debu rem (0 di kecepatan 0, D-1); SPEC hanya menyebut "tepi naik". Praktis jarang: rem butuh 0,25 detik tahan dan sepeda sudah bergerak saat itu.
2. **`Audio` `PROCESS_MODE_ALWAYS` dan menghentikan pemutar sendiri (`stop`)**, bukan mengandalkan `SceneTree.paused`. Diuji: pemutar yang ikut pause otomatis melanjutkan stream yang sama saat pohon lanjut, jadi decit rem yang terpotong jeda akan berbunyi lagi sesudah "Lanjut" (melanggar D-5). Bus `Sepeda` tidak diredam (pemutar sudah berhenti). `Audio` juga berhenti sendiri pada `APPLICATION_PAUSED`, `FOCUS_OUT`, dan `WM_CLOSE_REQUEST`.
3. **Driver audio `Dummy` tidak memutar stream** kecuali `putar_di_driver_dummy` dinyalakan (runner tes menyalakannya). Alasan, dicoba 2026-10-14: playback yang masih aktif saat Godot keluar paksa (`--quit-after 2`, gerbang AC-1) tidak sempat dilepas AudioServer, tercetak `WARNING: 2 ObjectDB instances were leaked` dan `ERROR: 1 resources still in use` (AudioStreamPlaybackWAV + WAV). Berhenti di frame terakhir tidak cukup; AudioServer baru melepasnya sesudah driver mencampur lagi. Akibatnya runner menunggu **0,25 detik** sesudah `hentikan_sepeda` sebelum `quit()` (dua frame headless terlalu cepat: 5 playback bocor; 0,25 detik: 6 dari 6 putaran bersih). Di HP dan desktop jendela (driver nyata) stream diputar biasa.
4. **`JalanUji` mencari `/root/Audio` lewat jalur node** (tipe dari `preload` skrip, konstanta `SKRIP_AUDIO`), bukan nama global `Audio`: scene tetap jalan tanpa autoload, dan skrip `class_name` tidak bergantung pada urutan registrasi autoload (gotcha rule `gdscript`). Data diberikan tiap `perbarui` sebagai argumen (`SepedaUji.pose()` baru, kecepatan, rem, jeda).
5. **WAV diimpor PCM (`compress/mode=0`)**, bukan QOA bawaan 4.7, supaya stream sama persis dengan berkas hasil skrip dan latensi rendah (SOUND_DESIGN 6). Loop lewat `edit/loop_mode=2` (Forward), rem `1` (Disabled), sesuai SPEC. Godot mengisi `loop_end` = 22049 (sampel terakhir dilewati; sampel 0 dan 22049 sama-sama 0, jadi tetap mulus).
6. **Probe di `scripts/dev/`** dengan konstanta tata letak lokal (bukan `Config`): angka panel, posisi lampu, ambang deteksi adalah alat ukur probe, bukan tuning game. Folder ini tidak masuk pemindai angka literal; hex dan `Color.X` tetap dipindai (warna dari `Palette`; satu `Color(0, 0, 0)` bernama `WARNA_PENANDA` untuk menghitung campuran kontrol).
7. **Glow probe: ambang 0,5 dan intensitas 2,0.** Dengan ambang 0,8-0,9 glow Compatibility 2D (LDR) hampir tidak memendarkan kotak `TEXT` (halo 0,056 lawan latar 0,050); ambang 0,5 + intensitas 2 memberi halo 0,102 lawan 0,050. Glow hanya untuk layer 0 (`background_canvas_max_layer` 0), panel lain di CanvasLayer 1-2 supaya pengukurannya tidak tercemar. Catatan untuk ART_DIRECTION (orchestrator): ambang glow di game perlu disetel ulang untuk Compatibility.
8. **Light probe:** `range_layer_min/max` = layer panel cahaya (1); tanpa itu PointLight2D di CanvasLayer 1 tidak menerangi apa pun (percobaan pertama: "tidak").
9. **Shader tanpa hint `source_color`**: warna bayangan dipakai apa adanya di ruang warna 2D Compatibility; modulate node tetap berlaku lewat `varying`. Disimpan di `assets/shaders/` karena akan dipakai sprite dunia nanti (ART_DIRECTION 2.3); status usulan.
10. **Pitch kayuhan mengubah tempo ketukan** (8 / 9,2 / 10,4 per detik), sedangkan animasi 8 / 10 / 12 fps (SOUND_DESIGN 3.2 meminta tempo disamakan). SPEC mengunci pitch 1,0/1,15/1,3; selisihnya dicatat di SOUND_DESIGN 3.2 dan checklist 8.2 untuk dinilai di HP.
11. **Volume usulan** `AUDIO_KAYUH_VOLUME_DB` -6, `AUDIO_FREEWHEEL_VOLUME_DB` -10, `AUDIO_REM_VOLUME_DB` -3 (ketiga WAV dinormalkan ke puncak -1 dBFS). Tidak ada di SPEC; dicatat BALANCING 2/10.
12. **APK normal ikut memuat berkas probe** (`cek_render.scn`, `.gdc`, shader; `export_filter` `all_resources`) tetapi tidak ada jalan untuk membukanya. Mengecualikannya lewat `exclude_filter` juga akan membuangnya dari build probe (preset sama), jadi tidak dilakukan.

#### Cara membuka probe di APK (D-8)

**Pilihan: build probe terpisah lewat `tools/ekspor_cek_render.py`** (stdlib): mengganti satu baris `run/main_scene` di `project.godot` ke `cek_render.tscn` hanya selama satu perintah ekspor (preset `Android` yang sama), memulihkan berkas byte demi byte di `finally` (juga saat gagal/Ctrl+C), lalu memeriksa `project.binary` di hasil ekspor. Scene utama yang di-commit tetap `jalan_uji.tscn`; tidak ada argumen atau tombol di game yang membuka probe.

- **`override.cfg` dicoba dan ditolak** (2026-10-14): `override.cfg` berisi `run/main_scene="res://scenes/dev/graybox.tscn"` di root, `--export-pack "Android"`: `project.binary` di paket tetap `application/run/main_scene` = `res://scenes/dev/jalan_uji.tscn` dan berkas `override.cfg` tidak ada di paket. `override.cfg` sekarang di `.gitignore` dan `tes_cek_render` memastikan tidak ada.
- **Argumen baris perintah di `JalanUji` tidak dipilih**: cara meneruskan argumen ke APK lewat `adb shell am start` tidak bisa dibuktikan tanpa HP, dan menambah jalan dari game ke probe.
- Bukti: `python3 tools/ekspor_cek_render.py --pck build/kring-cek-render.pck` exit 0, "project.godot pulih byte demi byte: ya", `scene utama di project.binary = res://scenes/dev/cek_render.tscn` (463.328 byte). `python3 tools/ekspor_cek_render.py --apk builds/kring-cek-render-debug.apk` exit 0, 28.631.804 byte, `assets/project.binary` = cek_render, 0 entri `assets/tests/`; sekitar 5,5 detik. `godot --headless --path . --export-debug "Android" builds/kring-kring-debug.apk` (normal) 0 ERROR/WARNING, `assets/project.binary` = jalan_uji. `--export-pack` normal = jalan_uji. Dari folder kosong: `godot --main-pack build/kring-cek-render.pck --resolution 2340x1080 -- --tangkap=...` menjalankan probe (ringkasan semua ya/cocok); `godot --headless --main-pack build/kring-uji.pck --quit-after 30` tanpa satu pun baris `[cek_render]`. `git status` bersih sesudah semua ekspor; `tes_export.gd` tetap hijau (preset tidak diubah).
- Perintah A54 untuk orchestrator (pasang probe, buka, `screencap`, `logcat -d -s godot | grep [cek_render]`, pasang ulang APK normal; tanpa `logcat -c`, `pm clear`, atau uninstall) di `SETUP_ANDROID.md` 6.1. APK probe memakai package yang sama, jadi menimpa build uji di HP sampai APK normal dipasang ulang.

#### Hasil probe desktop (non-headless, renderer Compatibility)

`godot --path . --resolution 2340x1080 --position 0,0 scenes/dev/cek_render.tscn -- --tangkap=docs/loop/20261014-fase1b-umpan-balik/shots/cek_render_2340x1080.png` (dan `1920x1080`):

```
[cek_render] perangkat: display=macOS os=macOS model="Mac16,10" renderer=gl_compatibility driver=opengl3 gpu="Apple M4" vendor="Apple" api="4.1 Metal - 90.5" jendela=(2340, 1080) viewport=(780.0, 360.0) skala=(3.0, 3.0) fps_rata=325.1 selama 5.0 detik
[cek_render] light2d: ya (terang dekat lampu 0.950, tepi gelap 0.119; bayangan occluder 0.148 vs sisi lain 0.604)
[cek_render] glow: ya (halo 4 px di luar kotak 0.102 vs latar jauh 0.050; inti #fff6e9)
[cek_render] cpu_partikel: ya (96 piksel game ACCENT terlihat, memancar true, 24 partikel)
[cek_render] gpu_partikel: ya (93 piksel game OK terlihat, memancar true, 24 partikel)
[cek_render] shader_bayangan: cocok (penanda 13 diperiksa, salah 0; kontrol hitam sesuai campuran 13/13; piksel lain 25 diperiksa, berubah 0; latar #cdb9a3 kalibrasi cocok; warna bayangan #2e3550 alpha 71/255)
[cek_render] ringkasan: light2d=ya glow=ya cpu_partikel=ya gpu_partikel=ya shader_bayangan=cocok renderer=gl_compatibility gpu="Apple M4" fps=325.1
```

(akhiran `| renderer=... gpu=... fps=...` di tiap baris fitur dipotong di sini). 1920x1080 (viewport 640): hasil sama, fps 361,3, cpu 93 / gpu 94 piksel. Yang saya lihat di `shots/cek_render_*.png`: panel 1 gelap dengan lingkaran cahaya hangat yang menerangi sprite pemain dan ubin, dan bayangan berbentuk baji di belakang kotak occluder; panel 2 kotak krem dengan pendar tipis; panel 3 titik oranye (CPU) dan hijau (GPU) naik; panel 4 dua sprite di latar krem, bayangan tanah sprite kanan kebiruan, kiri abu kehitaman. fps desktop tidak mewakili A54. **A54 belum dijalankan** (tugas orchestrator, NEEDS-MANUAL).

#### Tes lama yang diubah (bagian 1b, alasan)

| Tes | Perubahan | Alasan |
|---|---|---|
| `run_tests.gd` | Menyalakan `putar_di_driver_dummy` di awal; di akhir `hentikan_sepeda` + tunggu 0,25 detik sebelum `quit()`; memanggil `TesBunyi` dan `TesCekRender` | Pilihan 3 (tanpa tunggu: playback bocor saat keluar) |
| `run_tests.gd` `_test_palet` | Tabel DESIGN_SPEC 1.1: 16 -> 17 token | Token usulan `BAYANGAN_CONTOH` (D-8) |
| `run_tests.gd` pemindai angka | + `scripts/autoload/` (minimal 4 folder) | AC-12 untuk `audio.gd` |
| `run_tests.gd` kebersihan | `.gitignore` harus menutup `override.cfg` | AC-1/AC-8 |
| `tes_jeda_scene.gd` `_test_jeda_lengkap` | + 3 cek audio (kayuh sebelum jeda, diam selama jeda, decit sekali sesudah tahan ulang) | AC-7 "stream audio berhenti" |

Tes baru: `tests/tes_bunyi.gd`, `tests/tes_cek_render.gd`, `tools/tests_cek/uji_sintesis_sepeda.py`. Jumlah pemeriksaan `run_tests` 4357 (1a) -> 4576.

#### Gerbang (di `HEAD` `57b4a0f`, sebelum commit LOG)

```
godot --headless --import                                    # 0 baris ERROR/WARNING
mkdir -p build && godot --headless --script res://tests/run_tests.gd 2>&1 | tee build/tests.log   # 4576 lolos, 0 gagal (3 putaran berturut-turut)
python3 tools/cek_keluaran_tes.py --ketat build/tests.log    # pemeriksa: lolos (4576 lolos, 0 gagal, 0 peringatan)
python3 tools/tests_cek/uji_pemeriksa.py                     # 16 kasus, 0 menyimpang
python3 tools/tests_cek/uji_bangun_frames.py                 # 41 lolos, 0 gagal
python3 tools/tests_cek/uji_sintesis_sepeda.py               # 32 lolos, 0 gagal
godot --headless --path . --quit-after 2                     # 0 ERROR/WARNING (autoload Audio terdaftar)
godot --headless --path . --script res://tests/probe_layar.gd   # 0 ERROR, 0 PECAHAN
godot --headless --path . scenes/dev/cek_render.tscn         # 7 baris [cek_render], "tidak bisa dibaca headless", tanpa SCRIPT ERROR
git diff main --name-only | grep -E "keystore|\.apk|\.aab|\.godot/|^build/|^builds/|\.jks|\.p12|export_credentials|override.cfg"   # kosong
```

Klon bersih per commit (`git clone` ke scratch, `checkout`, `git clean -fdx`, import, `run_tests` + `--ketat`, `--quit-after 2`, tiga uji alat, `git status --porcelain`): `e37577c` 4517 lolos, `7e27409` 4574, `6cc6d83` 4576, `57b4a0f` 4576; semua 0 ERROR/WARNING import dan buka, pemeriksa lolos, ketiga uji alat lolos, porcelain kosong.

#### Mutan nyata (AC-11, bagian 1b)

Skrip sementara di scratchpad (tidak di-commit): tiap mutan mengganti satu potongan kode, menjalankan `run_tests.gd` + `cek_keluaran_tes.py --ketat`, lalu memulihkan berkas (`git status` bersih sesudahnya). Mutan wajib SPEC bagian ini: pitch tangga (M32), rem dipicu tiap frame (M33), bunyi tidak berhenti saat jeda (M34, M35, M40, M44).

| Mutan | Hasil | Tes yang menangkap (contoh) |
|---|---|---|
| M32 pitch tangga (santai sampai tepat 4,5, lalu 1,15) | 4 gagal | "3,75 = 1,075 (... linear, bukan tangga)" |
| M33 rem dipicu tiap frame (status sebelum diabaikan) | 9 gagal | "rem masih ditahan: tidak dipicu lagi", scene "decit tidak diulang tiap langkah" |
| M34 `atur_jeda` tidak menghentikan pemutar | 2 gagal | "jeda: semua bunyi sepeda berhenti, termasuk decit rem yang sedang berbunyi" |
| M35 `loop_aktif` mengabaikan jeda | 9 gagal | "TOMBOL_EMIT: semua stream audio sepeda berhenti selama jeda (D-5)" |
| M36 decit dipicu saat jeda (tertunda) | 4 gagal | "tepi naik selama jeda: tidak dipicu" |
| M37 `Audio` tanpa `PROCESS_MODE_ALWAYS` | 1 gagal | "Audio PROCESS_MODE_ALWAYS ..." (perilakunya sendiri tertutup karena `stop` eksplisit; lihat pilihan 2) |
| M38 pitch tidak dipasang ke pemutar | 2 gagal | "mempercepat (4.50 u/d): pitch mengikuti kecepatan sebenarnya (1.000)" |
| M39 meluncur = loop kayuh | 3 gagal | "meluncur = loop freewheel" |
| M40 `jeda_berubah` tidak disambung ke `Audio` | 2 gagal | "jeda: semua bunyi sepeda berhenti ..." |
| M41 `_exit_tree` tidak menghentikan bunyi | 1 gagal | "scene dibuang: semua bunyi sepeda berhenti" |
| M42 decit di kecepatan 0 | 2 gagal | "rem menyala di kecepatan 0: tidak berdecit" |
| M43 `audio.gd` merujuk `/root/SaveManager` | 2 gagal | "audio.gd tidak merujuk autoload ...: [SaveManager]" |
| M44 `perbarui_sepeda` tidak menghentikan decit saat jeda | **awalnya HIDUP**, kini 1 gagal | Hidup karena `atur_jeda` lewat sinyal sudah menghentikannya. Ditambah tes "perbarui_sepeda dengan jeda (tanpa atur_jeda): decit dan loop berhenti" (`6cc6d83`) |
| M45 probe headless mengklaim `cocok` | 2 gagal | headless: pembacaan piksel shader ditulis 'tidak bisa dibaca headless' |
| M46 skrip game menyebut `cek_render` | 1 gagal | "tidak ada skrip atau scene game yang merujuk probe" |
| M47 GPUParticles2D tidak memancar | 1 gagal | "CPUParticles2D dan GPUParticles2D sama-sama memancar" |
| M48 bayangan light mati | 1 gagal | "PointLight2D: bayangan lembut PCF5 ..." |
| M49 status rem sebelumnya tidak dicatat | 7 gagal | "rem ditahan 30 langkah: decit dipicu sekali" |
| M50 shader tidak mengganti penanda (jendela asli) | probe: `tidak cocok` (13/13 salah, mis. `#948576` lawan harapan `#a1948c`) | Probe desktop, bukan `run_tests` (piksel tidak terbaca headless) |
| M51 shader mengabaikan alpha (semua piksel RGB 0 diganti) | **HIDUP** (probe tetap `cocok`) | Setara pada data sekarang: sheet `loper_agen.png` tidak punya piksel RGB 0 selain penanda alpha 71 (dihitung: 0). Akan tertangkap begitu sprite memuat hitam lain |
| M52 `ekspor_cek_render.py` tanpa pemulihan | skrip menulis "project.godot pulih byte demi byte: TIDAK" + `GAGAL`, `git diff` menunjukkan `project.godot` berubah (dipulihkan dengan `git checkout`) | Pemeriksaan pemulihan di skrip |
| M53 ketukan kayuh terakhir di ujung loop (aset ikut dibuat ulang) | uji_sintesis 1 gagal | "sambungan loop tanpa klik: ujung tidak dekat nol (10047, 723), lompatan 9324" |
| M54 acak tanpa benih | uji_sintesis gagal | "dua kali jalan menghasilkan byte yang sama", byte-identik repo |
| M55 WAV rem diedit 1 byte | uji_sintesis 1 gagal | "berkas di repo byte-identik dengan keluaran skrip" |
| M56 `.import` kayuh `edit/loop_mode=0` (diimpor ulang) | run_tests 3 gagal + uji_sintesis 1 gagal | "loop maju dari sampel 0 sampai ujung (0..0 dari 22050)", "sesudah 1,3 detik ... kedua loop masih berbunyi" |

Ringkas: 25 mutan; 23 tertangkap (M44 sesudah tes tambahan; M50 oleh probe jendela), 1 setara pada data sekarang (M51), M37 tertangkap hanya oleh cek langsung. Kode dikembalikan sesudah tiap mutan (`git status` bersih; aset dan `.import` dibuat/diimpor ulang ke keadaan semula).

#### NEEDS-MANUAL tambahan dari bagian 1b

- (orchestrator) Probe render di A54 (`SETUP_ANDROID.md` 6.1): tujuh baris `[cek_render]` + tangkapan layar ke `render_a54/`; glow mungkin perlu ambang lain di GPU Mali (desktop: ambang 0,8-0,9 hampir tanpa halo).
- Bunyi di speaker A54: pitch naik saat ngebut, tempo ketukan lawan animasi (10,4 lawan 12 saat ngebut), freewheel, decit sekali, tanpa klik di sambungan loop, volume relatif (-6/-10/-3 dB), diam saat jeda dan background (checklist 8.2).
- Uji 3-5 orang Fase 1: `SETUP_ANDROID.md` 8.2.


## Catatan QA iterasi 1

Agent 2 (QA), 2026-10-14, `HEAD` `ee0bd07`, macOS Apple M4, `godot` 4.7.2.stable.official.ed1daf0bf (`/opt/homebrew/bin/godot`). Tidak ada kode fitur yang diubah; tidak push; HP/`adb` tidak disentuh; `DEV_PHASES.md`/`ROADMAP.md` tidak diedit. Klaim di Catatan Dev tidak dipakai sebagai bukti: semua di bawah dijalankan ulang oleh QA.

**Verdict: PASS** (semua gerbang hijau; 0 Blocker, 0 Major). Minor/Nit: QA-001..QA-006. Fase 1 tetap **tidak** boleh dicentang selesai: NEEDS-MANUAL (probe A54, checklist 8.2, QA-005) belum dilakukan.

### Gerbang (dijalankan QA)

Klon bersih (`git clone` ke scratch, checkout `feat/fase1b-umpan-balik`, `rm -rf .godot`):
```
godot --headless --import                                      # exit 0, 0 baris ERROR/WARNING
git status --porcelain -uall                                   # kosong sesudah import
godot --headless --script res://tests/run_tests.gd > build/tests.log 2>&1   # exit 0, "4576 lolos, 0 gagal"
python3 tools/cek_keluaran_tes.py --ketat build/tests.log      # pemeriksa: lolos (4576 lolos, 0 gagal, 0 peringatan)
python3 tools/tests_cek/uji_pemeriksa.py                       # 16 kasus, 0 menyimpang
python3 tools/tests_cek/uji_bangun_frames.py                   # 41 lolos, 0 gagal
python3 tools/tests_cek/uji_sintesis_sepeda.py                 # 32 lolos, 0 gagal
godot --headless --path . --quit-after 2                       # exit 0, 0 ERROR/WARNING (autoload Audio terdaftar)
git status --porcelain -uall                                   # kosong
```
- Kestabilan (Dev melaporkan satu `ERROR` saat keluar di `304fe06` yang tidak terulang): `run_tests` + `--ketat` 6 putaran berturut-turut di klon `HEAD`: 6/6 lolos. Klon bersih per commit (`git clean -fdx`, `rm -rf .godot`, import, tes, `--ketat`): `304fe06` 4071, `e17131e` 4349, `e37577c` 4517, `7e27409` 4574 lolos, semua 0 gagal, porcelain kosong.
- Kebersihan: `git diff main...HEAD --name-only | grep -E "keystore|\.apk|\.aab|\.godot/|^build/|^builds/|\.jks|\.p12|export_credentials|override.cfg"` kosong; tidak ada password/secret/token di diff; `.gitignore` menutup `override.cfg`. `main` = `f36c8be` (PR #20), tidak ada commit run ini di `main`. 14 commit `<tipe>: <ringkasan>` bahasa Indonesia (`feat`, `tune`, `fix`, `test`, `docs`), skrip sintesis + WAV di commit yang sama (`e37577c`), `Config` + `BALANCING` di commit yang sama. Semua `.gd` baru punya `.uid`; tiga WAV punya `.import` (loop_mode 2/2/1). Audio total 108 KB.
- Ekspor: `godot --headless --path . --export-pack "Android" build/qa-normal.pck` exit 0, 0 ERROR/WARNING; `project.binary` `run/main_scene` = `res://scenes/dev/jalan_uji.tscn`; tidak ada `tests/` atau `docs/` di paket; berkas probe ikut (QA-004). `python3 tools/ekspor_cek_render.py --pck build/qa-cek.pck`: scene utama paket = `cek_render.tscn`, "project.godot pulih byte demi byte: ya", md5 `project.godot` sebelum = sesudah, `git status` bersih. APK (`--export-debug`) tidak dijalankan QA (butuh Java SDK Path; klaim APK Dev tidak terverifikasi QA, paket `.pck` setara untuk isi dan scene utama).
- Probe render headless: `godot --headless --path . scenes/dev/cek_render.tscn`: 7 baris `[cek_render]`, 0 `SCRIPT ERROR`/`ERROR`, shader "tidak bisa dibaca headless", ringkasan `tidak_terbaca`.

### Kepatuhan SPEC (AC per AC)

| AC | Hasil QA | Bukti yang diperiksa |
|---|---|---|
| AC-1 | Terbukti | Gerbang di atas. |
| AC-2 | Terbukti | `umpan_balik_kecepatan.gd` dibaca (murni, `is_finite`, jepit `_pecahan`); `tes_umpan_balik.gd`; mutan QA Q16 (negatif dianggap positif) mati. Ambang debu 3,0 inklusif (santai sudah berdebu tipis) adalah tafsiran Dev atas "di bawah 3,0 tidak berdebu": sesuai teks, dicatat BALANCING 2. |
| AC-3 | Terbukti | `PancaranPiksel` (`_draw`, bukan GPU/CPUParticles2D, larik dipesan sekali, RNG berbenih), anak `SepedaUji` (pausable). Tes scene; mutan Q19 (alpha garis bukan dari Config) mati; Q13 (batas: ganti partikel terakhir, bukan tolak) hidup tapi setara terhadap SPEC (jumlah tidak melewati batas). Visual: lihat bawah. |
| AC-4 | Terbukti | `bunyi_sepeda.gd`, `audio.gd` (tidak merujuk autoload lain; `/root/Audio` dicari `JalanUji`, bukan sebaliknya), `default_bus_layout.tres` (`Sepeda` → `SFX` → `Master`). Mutan Q05 (pose REM diabaikan), Q07 (status rem tidak dilupakan), Q14 (pitch tidak linear di atas 4,5), Q15 (decit tidak dihentikan), Q20 (`perbarui_sepeda` saat jeda tidak menghentikan decit) mati. Q02 hidup (QA-001). Bunyi nyata di speaker: NEEDS-MANUAL. |
| AC-5 | Terbukti | `uji_sintesis_sepeda.py` 32 lolos (byte-identik, dua kali jalan sama, stdlib via AST, sambungan loop, `.import`, LICENSES); 108 KB; nama sesuai SOUND_DESIGN 6. |
| AC-6 | Terbukti (dengan catatan QA-005) | `Config`: tombol 42, jeda 42, Y 0,75, maju 36, mundur 20, respon 0,35, stick 35; `theme.tres` HudLabel 8. Probe QA: 780 dan 640 tombol jeda (17, 4, 42×42), gambar (26, 8, 24×24), kidal 96×42, panel y 293–352; sepeda mundur penuh y sampai 292 (1 px dari panel). Mutan Q12 (mundur 21) mati. |
| AC-7 | Terbukti | `JedaSim` + kabel `JalanUji` dibaca; mutan Q18 (jari tidak dilepas), Q22 (back saat jeda tidak lanjut), Q23 (RESUMED melanjutkan), Q17 (layar jeda ALWAYS) mati. Percobaan QA headless (skrip sementara, tidak di-commit): ketuk sentuh tombol jeda → jeda; ketuk sentuh "Lanjut" → lanjut; ketuk lagi → jeda; `WM_GO_BACK_REQUEST` saat jeda → lanjut dan pohon lepas pause, saat jalan → jeda; FOCUS_OUT dengan jari di tombol lalu FOCUS_IN → tetap jeda (tanpa lanjut otomatis). `quit_on_go_back=false` di `project.godot`. Q01, Q03, Q04 hidup (QA-001), status tekan tertinggal (QA-002). |
| AC-8 | Terbukti di desktop | Headless dan jendela asli 2340x1080 (Compatibility, Apple M4): `light2d=ya glow=ya cpu_partikel=ya gpu_partikel=ya shader_bayangan=cocok` (penanda 13/13, piksel lain 25 tidak berubah), tangkapan `shots/iter1-qa/cek_render_2340x1080.png` dilihat: lingkaran cahaya + baji bayangan occluder, kotak berpendar tipis, titik oranye (CPU) dan hijau (GPU), bayangan tanah sprite kanan kebiruan. Isolasi: lihat Ekspor. A54: NEEDS-MANUAL (orchestrator). |
| AC-9 | Terbukti | QA menjalankan ulang `tests/probe_umpan_balik_jendela.gd` di 2340x1080 dan 1920x1080 ke `shots/iter1-qa/` (12 berkas). `cek_blok_piksel.py 3` dengan kotak teks yang dicetak probe: 12/12 berkas 0 blok tidak seragam; kontrol negatif `2340x1080_ngebut.png` tanpa pengecualian = 664 blok, gagal. Yang QA lihat: santai tanpa garis, debu 1; ngebut 4 garis putih pendek bertangga 2:1 dan goresan debu krem di belakang roda (samar, QA-006); rem debu bertitik di belakang roda; layar jeda gelap dengan "JEDA" dan "Lanjut" bergaris terang, stick hilang; 640 mundur penuh sepeda tepat di atas panel dan cincin stick di kirinya. Probe keluar dengan ERROR/WARNING (QA-003). |
| AC-10 | Terbukti | Mutan QA Q21 (= Q05 lama: LELAH hanya di stamina 0) mati oleh tes QA-001; `_test_pose_langkah_tepat` ada (M28 tidak diulang QA). |
| AC-11 | Terbukti | Tabel mutan Dev lengkap untuk semua mutan wajib SPEC; QA menjalankan 23 mutan sendiri (bawah). |
| AC-12 | Terbukti | Penjaga gaya lolos di runner; pembacaan QA: tab, typing, `##` Indonesia, warna dari `Palette` (token baru `BAYANGAN_CONTOH` di `palette.gd`), teks lewat kunci `JEDA_*`, tanpa kiri/kanan untuk sisi jalan (kiri/kanan hanya sumbu layar di komentar Config), tanpa alokasi di `_process` (`PancaranPiksel.maju`, `Audio.perbarui_sepeda`). `scripts/dev/` tidak dipindai angka (alat ukur probe, dicatat Dev). |
| AC-13 | Terbukti | BALANCING 2/10 (angka sama dengan Config: debu 4→24, rem 40, garis 0,25/14, batas 24/6, pitch 1,0/1,15/1,3, volume −6/−10/−3, 0,75, 36/20/0,35, tombol 42), DESIGN_SPEC 1.2/3.1/4, SOUND_DESIGN 3.2/6/perilaku Android, TECH_PLAN 3.1, SETUP_ANDROID 6.1 + 8.2, GDD 15, AGENTS, 00-project-core: tidak ada angka yang saling berbeda. |
| AC-14 | Terbukti | Lihat Kebersihan. |

### Mutan QA (dijalankan sendiri, kode dipulihkan `git checkout --` tiap mutan; `git status` bersih sesudahnya)

| Mutan | Hasil |
|---|---|
| Q01 jeda tidak memadamkan cincin rem (`jalan_uji.gd:96`) | **HIDUP** (QA-001) |
| Q02 `Audio` tidak berhenti sendiri pada PAUSED/FOCUS_OUT | **HIDUP** (QA-001) |
| Q03 `TombolSentuh` tidak melupakan jari saat PAUSED/visibilitas | **HIDUP** (QA-001) |
| Q04 `TombolSentuh` memicu walau sentuhan `canceled` | **HIDUP** (QA-001) |
| Q05 `loop_aktif` mengabaikan pose REM | mati (1) |
| Q06 `perbarui` selalu mematikan `baru_lanjut` | hidup, setara (dt dihitung sebelum direset; `baru_lanjut` selalu false selama jeda) |
| Q07 `hentikan_sepeda` tidak melupakan status rem | mati (1) |
| Q08 sisa akumulasi pancar tidak direset saat laju 0 | hidup, nyaris setara (pancaran pertama maju < 1 partikel) |
| Q09 jari kedua merebut pelacakan tombol | hidup, setara praktis (tetap memicu sekali) |
| Q10 `_sepeda.jeda()` hanya saat status berubah | hidup, setara (selama jeda input dan proses berhenti) |
| Q11 pencegah pemicu ganda per frame dihapus | hidup, setara (JEDA/LANJUT idempoten) |
| Q12 `DORONGAN_MUNDUR_PX` 20 → 21 | mati (5) |
| Q13 batas partikel: ganti partikel terakhir saat penuh | hidup, setara terhadap SPEC (jumlah ≤ batas) |
| Q14 pitch cepat→ngebut kuadrat, bukan linear | mati (2) |
| Q15 `_hentikan_pemutar` tidak menghentikan decit | mati (2) |
| Q16 debu dari kecepatan absolut | mati (2) |
| Q17 layar jeda `process_mode` ALWAYS | mati (1) |
| Q18 kontrol tidak dilepas saat jeda | mati (4) |
| Q19 alpha garis 1,0 (bukan Config) | mati (1) |
| Q20 `perbarui_sepeda` saat jeda tidak menghentikan decit | mati (1) |
| Q21 LELAH hanya di stamina 0 (Q05 Run 1A) | mati (1) |
| Q22 back saat jeda tidak melanjutkan | mati (10) |
| Q23 `RESUMED` melanjutkan | mati (14) |

Ringkas: 23 mutan, 13 mati, 4 hidup bermakna (QA-001, Minor: cabang pertahanan, perilaku benar), 6 hidup setara.

### Regresi

`git diff main...HEAD -- tests/`: tidak ada tes yang di-skip. Cek yang dihapus/diubah semuanya terkait keputusan SPEC (lanjut otomatis D-6, 28→36, font 6→8, tabel token 16→17, awalan `JEDA_`, kontainer HUD ketiga) dan tercatat di tabel "Tes lama yang diubah" Dev; `_test_jeda` lama digantikan `tes_jeda_scene.gd` yang lebih luas. Jumlah pemeriksaan 3886 (`main`, menurut Dev) → 4576.

### Tidak bisa diverifikasi QA

- Semua di HP (A54): probe render, bunyi di speaker (pitch, klik sambungan, volume), back Android dan home sungguhan, sentuhan jari kedua dan `canceled` dari gesture sistem, keterbacaan debu/garis, 60 fps, rasa posisi sepeda 75% dan dorongan 36. Lihat NEEDS-MANUAL.
- APK `--export-debug` normal dan probe (butuh Java SDK Path); QA memakai `--export-pack` yang memakai filter preset yang sama.
- Keluar dari game desktop saat bunyi sedang berjalan (QA-003 catatan): tidak diuji karena jendela yang dibuka QA langsung kehilangan fokus dan menjeda.
