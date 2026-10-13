# Loop Log — 20261014-fase1b-umpan-balik
Scope: Run 1B Fase 1, umpan balik kecepatan (debu, garis), audio placeholder + autoload `Audio`, tombol dan layar jeda, penyetelan paket A54, probe render Compatibility, checklist uji 3-5 orang  ·  Branch: `feat/fase1b-umpan-balik`  ·  Mulai: 2026-10-14  ·  Godot: 4.7.2

## Status: IN_PROGRESS   (iterasi saat ini: 1/2)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## NEEDS-MANUAL (uji di HP)
- [ ] (orchestrator) Probe render di A54: light 2D, glow, CPU/GPU partikel, shader warna bayangan; tangkapan layar + log ke `render_a54/`.
- [ ] Checklist uji 3-5 orang Fase 1 (`SETUP_ANDROID.md` 8.2).

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
