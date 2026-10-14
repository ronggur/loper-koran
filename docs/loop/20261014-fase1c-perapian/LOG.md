# Loop Log — 20261014-fase1c-perapian
Scope: Run 1C Fase 1, perapian temuan Run 1B (QA-001 tes cabang pertahanan, QA-002 gambar tombol jeda, QA-003 probe keluar bersih, QA-004 probe render tidak ikut APK normal, QA-006 debu ruang dunia); tanpa penyetelan (uji HP 8.2 belum ada)  ·  Branch: `fix/fase1c-perapian`  ·  Mulai: 2026-10-14  ·  Godot: 4.7.2

## Status: IN_PROGRESS   (iterasi saat ini: 1/2)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 1 | D-1..D-5 (QA-001, QA-002, QA-003, QA-004, QA-006), 7 commit; tanpa angka penyetelan baru | ✅ import 0 ERROR/WARNING; `run_tests` 4668 lolos 0 gagal, `--ketat` lolos; uji_pemeriksa/bangun_frames/sintesis lolos; `--quit-after 2` bersih; 6 probe jendela keluar bersih; klon bersih per commit (lihat Catatan Dev) | menunggu QA | | |

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## NEEDS-MANUAL (uji di HP)
- [ ] (orchestrator) APK debug normal di vivo V2108: terpasang, jalan, isi APK tanpa berkas probe render.
- [ ] (QA-002) Tahan jempol di tombol jeda, tekan home, kembali, ketuk "Lanjut": ikon jeda tampil normal.
- [ ] (QA-006) Jejak debu tertinggal di jalan saat pindah sisi, terbaca dan tidak mengganggu.
- [ ] (QA-001 Q04) Swipe gesture navigasi sistem di atas tombol jeda tidak memicu jeda/lanjut.
- [ ] Checklist uji 3-5 orang Fase 1 (`SETUP_ANDROID.md` 8.2), termasuk QA-005 Run 1A dan Run 1B.

## Keputusan & catatan
- Keputusan pemilik 2026-10-14 (lihat SPEC): hasil uji HP 8.2 belum ada (kolom perintah masih template), jadi tidak ada angka penyetelan yang diubah; QA-005 Run 1A/1B tetap NEEDS-MANUAL. QA-004 dikerjakan (masuk scope).
- Lingkungan (orchestrator, 2026-10-14): Godot 4.7.2 `/opt/homebrew/bin/godot`; `adb` hanya vivo V2108 (12d8c9da), A54 tidak tersambung. `main` = `origin/main` = 7acbef7 (PR #21). PR #22 (docs perintah Run 1C) masih terbuka dan tidak dibutuhkan run ini.

## Catatan Dev iterasi 1

Agent 1 (Dev), 2026-10-14, macOS Apple M4, `godot` 4.7.2.stable.official.ed1daf0bf (`/opt/homebrew/bin/godot`), branch `fix/fase1c-perapian` (tidak ada commit di `main`, **tidak push**). HP/`adb` tidak disentuh, tidak ada unduhan, Editor Settings tidak diubah, `DEV_PHASES.md`/`ROADMAP.md` tidak diedit. **Tidak ada angka penyetelan yang berubah** (`scripts/config.gd` dan `BALANCING.md` tidak disentuh). Tabel Temuan tidak diisi (milik QA). **Tidak ada BLOCKED.**

### Commit (urut)

| Commit | Isi |
|---|---|
| `a960e28` fix: lepas status tekan tombol sentuh saat jeda dan lanjut (QA-002) | `scripts/ui/tombol_sentuh.gd`; `tests/tes_jeda_scene.gd` (regresi QA-002, TombolSentuh terpisah Q03/Q04) |
| `f052948` test: cincin rem padam saat jeda dan Audio berhenti sendiri (QA-001 Q01, Q02) | `tests/tes_jeda_scene.gd`, `tests/tes_bunyi.gd` |
| `abbf9c2` fix: probe render tidak ikut APK normal (QA-004) | `export_presets.cfg`, `tools/ekspor_cek_render.py`, `tests/tes_export.gd`, `docs/SETUP_ANDROID.md` 3 dan 6.1, `AGENTS.md`, `00-project-core.mdc` (satu commit, saling bergantung) |
| `61b3915` fix: probe jendela keluar tanpa ERROR/WARNING (QA-003) | `tests/probe_keluar.gd` (+ `.uid`) baru, enam `tests/probe_*_jendela.gd`, penjaga teks di `tests/run_tests.gd`, `AGENTS.md`, `00-project-core.mdc` |
| `512751e` fix: debu roda di ruang dunia (QA-006) | `scripts/entities/pancaran_piksel.gd`, `umpan_balik_sepeda.gd`, `tests/tes_umpan_balik.gd`, `tests/probe_umpan_balik_jendela.gd` (skenario pindah sisi), `docs/ART_DIRECTION.md` 2, `docs/SETUP_ANDROID.md` 8.2 |
| `8e583d2` fix: ProbeKeluar menjeda pohon sebelum menghentikan bunyi (QA-003) | `tests/probe_keluar.gd`, `tests/run_tests.gd` |
| (commit ini) docs: LOG Dev iterasi 1 run 1C | LOG ini + `shots/` (AC-7) |

### Pilihan desain per D-n (usulan, bisa ditolak di review)

- **D-1 (QA-001).** Satu tes per cabang, semuanya dengan mutan nyata (tabel mutan di bawah). Tanpa perubahan perilaku produksi untuk Q01, Q02, Q04.
  - Q01 (`tes_jeda_scene.gd` `_test_rem_padam_saat_jeda`, pemicu tombol, FOCUS_OUT, PAUSED, back): rem aktif + busur menyala → jeda → busur padam → lanjut → **stick disentuh ulang tanpa satu langkah pun**: busur tetap padam → langkah dt 0 → 14 langkah bawah penuh belum menyala → langkah ke-15 menyala (kontrol). Catatan jujur: selama jeda stick sudah dilepas (`lepas_semua`), jadi busur tidak tergambar walau cabang itu dihapus; dampak mutan hanya terlihat saat stick disentuh ulang sesudah lanjut sebelum `perbarui` berikutnya (di game sungguhan `_process` memanggil `perbarui` sebelum gambar, jadi praktis tidak terlihat). Tes memeriksa keadaan itu lewat `busur_rem_tampil()` yang sudah ada; tidak ada getter baru.
  - Q02 (`tes_bunyi.gd` `_test_notifikasi_sendiri`): instans `audio.gd` baru (`load().new()`) ditambahkan sementara ke root dengan `putar_di_driver_dummy`, ketiga pemutar berbunyi, lalu `propagate_notification` pada instans itu saja (tanpa `JalanUji`, tanpa `jeda_berubah`). Satu instans per notifikasi: `APPLICATION_PAUSED`, `APPLICATION_FOCUS_OUT`, dan juga `WM_CLOSE_REQUEST` (cabang yang sama).
  - Q03/Q04 (`tes_jeda_scene.gd` `_test_tombol_sentuh_terpisah`): satu `TombolSentuh` sendirian di viewport; jari turun di dalam, lalu `notification(PAUSED)`, `notification(UNPAUSED)`, pohon dijeda lalu lanjut, atau `hide()`/`show()`, lalu naik di dalam = tidak memicu; naik `canceled` di dalam (jari kedua dan jari pertama) = tidak memicu; ketukan biasa sesudahnya memicu tepat sekali. `ditekan` dihitung dari kedua jalur (sentuhan `_input` dan `pressed` bawaan).
  - **Temuan saat menulis tes Q03 (perlu diketahui QA):** di Godot 4.7.2 jari yang turun saat jari lain masih menempel tetap diemulasi menjadi tekan mouse (`is_pressed()` true; dicoba dengan skrip sementara). Akibatnya kode lama (`_jari = -1` saja) **tetap memicu** sesudah PAUSED lewat `pressed` bawaan `Button`: tes Q03 PAUSED dan pohon-dijeda gagal pada kode lama (2 gagal). Karena itu tes Q03/Q04 masuk commit yang sama dengan perbaikan D-2 (`a960e28`), bukan commit tes terpisah.
- **D-2 (QA-002).** Letak: `TombolSentuh` (paling umum; juga berlaku untuk "Lanjut"). Pada `NOTIFICATION_PAUSED`, `NOTIFICATION_UNPAUSED`, dan `NOTIFICATION_VISIBILITY_CHANGED`, `_lepas_tekan()` melupakan jari **dan** memanggil `notification(NOTIFICATION_SCROLL_BEGIN)` pada tombol itu sendiri: reaksi `BaseButton` atas notifikasi itu (sama dengan saat `ScrollContainer` mulai digeser) adalah membatalkan percobaan tekan (`press_attempt`) dan menggambar ulang, tanpa memancarkan `pressed`. Alasan: `button_pressed = false` tidak berlaku untuk tombol non-toggle; status tekan gambar sendiri hanya memperbaiki gambar, tidak mencegah `pressed` bawaan saat jari yang tertahan naik sesudah lanjut. Risiko: bergantung pada perilaku `BaseButton` atas `SCROLL_BEGIN` yang tidak didokumentasikan sebagai API; dijaga tes regresi (bila versi Godot lain mengubahnya, tes gagal). `TombolJeda._draw` tetap memakai `is_pressed()`.
- **D-3 (QA-003).** Pembantu bersama `tests/probe_keluar.gd` (`class_name ProbeKeluar`, `static func keluar(tree, kode)`): `tree.paused = true`, `Audio.hentikan_sepeda()` (dicari lewat `get_node_or_null("Audio")`), tunggu 0,25 detik (timer jalan walau pohon dijeda), `quit(kode)`. Dipakai di **kedua** jalur keluar (sukses dan gagal "scene utama tidak bisa dimuat") keenam probe yang memuat scene utama. Penyebab baris `ERROR`/`WARNING` dibuktikan audio: tanpa perubahan, `probe_umpan_balik_jendela.gd` 2340x1080 mencetak `WARNING: 2 ObjectDB instances were leaked at exit` dan `ERROR: 1 resources still in use at exit` (direproduksi di awal run); sesudahnya bersih. Jeda pohon ditambah di `8e583d2` karena satu kali `probe_dorongan_jendela.gd` masih bocor: probe dorongan dan input membiarkan `JalanUji._process` berjalan, jadi `perbarui` menyalakan loop lagi selama masa tunggu (bila jendela kebetulan fokus; tanpa fokus `JalanUji` sudah menjeda sendiri). Kebocoran itu tidak bisa saya ulangi dengan sengaja (dua putaran tanpa jeda pohon bersih, bergantung fokus jendela), jadi perbaikan ini berdasar penalaran kode, bukan reproduksi yang pasti. Penjaga teks di `run_tests.gd` (`_test_probe_keluar_bersih`): tiap `tests/probe_*.gd` yang memuat `application/run/main_scene` tidak memanggil `quit(` langsung, dan `ProbeKeluar` menjeda, menghentikan bunyi, menunggu, keluar (dengan contoh buruk). `--verbose` tidak dipakai: penyebab sudah jelas dari reproduksi dan pembanding.
- **D-4 (QA-004).** `exclude_filter` preset + `scenes/dev/cek_render.tscn, scripts/dev/cek_render.gd, assets/shaders/warna_bayangan.gdshader` (nama berkas persis, bukan `scripts/dev/*`). Bukti shader tidak dipakai game: grep `cek_render|warna_bayangan` di `.gd/.tscn/.tres/.cfg/.godot/.gdshader` hanya menemukan probe sendiri, `tools/ekspor_cek_render.py`, `tests/tes_cek_render.gd`, dan komentar di `palette.gd`; kini juga dijaga tes (`_pemakai_probe`: tidak ada `.gd/.tscn/.tres/.gdshader` di `scripts/`, `scenes/`, `assets/` selain probe yang memuat `res://<pola>`). Token `Palette.BAYANGAN_CONTOH` tidak dihapus; opsi preset lain tidak berubah. `tools/ekspor_cek_render.py`: `POLA_PROBE` dilepas dari satu-satunya baris `exclude_filter` (menolak tanpa mengubah apa pun bila baris/pola tidak ada), kedua berkas ditulis ulang dengan byte asli di `finally`, `OSError` (Godot tidak ditemukan) ditangkap, status pulih kedua berkas dicetak, hasil diperiksa memuat `BUKTI_PROBE` (daftar entri APK atau byte paket `.pck`) dan `project.binary` menunjuk probe; exit 1 bila tidak. `tes_export.gd`: `FILTER_PROBE` wajib di `exclude_filter` (pesan pelanggaran), tiga contoh buruk (tiap pola dihapus), pola menunjuk berkas yang ada, `POLA_PROBE` skrip = `FILTER_PROBE` (urai teks Python, dengan contoh buruk kurang/lebih), skrip memulihkan `export_presets.cfg`.
- **D-5 (QA-006).** `PancaranPiksel.ruang_dunia` (bawaan false). True: saat dipancarkan, titik muncul lokal diubah ke posisi global (`get_global_transform() * muncul`) dan disimpan; gerak partikel hanya `arah * kecepatan_px`; `_draw` membulatkan posisi global lalu membawanya ke ruang lokal dengan `get_global_transform().affine_inverse()` (induk di piksel bulat, jadi tetap bulat); `set_notify_transform` + `NOTIFICATION_TRANSFORM_CHANGED` menggambar ulang saat induk bergeser. Node tetap anak `SepedaUji` sebelum `LoperAgen`, jadi tetap di belakang pemain. **`top_level` ditolak**: dokumentasi Godot menyebut `top_level` juga memindah urutan gambar ke atas item lain (debu akan menutupi pengendara). Memindah node debu ke lapisan dunia di bawah `JalanUji` juga tidak dipilih (urutan gambar terhadap pemain lewat y-sort jadi tidak pasti). Hanya debu yang `ruang_dunia`; garis kecepatan tetap lokal. `posisi_global_partikel()` baru (untuk tes/probe, mengalokasi; tidak dipakai tiap frame). Tanpa alokasi baru per frame (`Transform2D` nilai). **Angka tidak diubah**: di tangkapan 2340x1080 jejak terbaca sebagai garis titik krem di belakang roda (ngebut) dan berbelok dari sisi lama (pindah sisi); tipis, keterbacaannya di HP tetap NEEDS-MANUAL. Catatan: debu di jalan kini bisa sedikit melewati objek y-sort lain di `Objek` (debu digambar di slot y-sort sepeda); placeholder, tidak terlihat masalah di tangkapan.

### Tes lama yang diubah

| Tes | Perubahan | Alasan |
|---|---|---|
| `tes_export.gd` `_test_preset_contoh_buruk` | Teks asal mutan "filter pengecualian kosong" diganti ke baris `exclude_filter` baru; + 3 contoh buruk pola probe | Baris preset berubah (D-4); mutan harus nyata, bukan no-op |
| `tes_export.gd` `_pelanggaran_preset` | + wajib `FILTER_PROBE` | D-4 |
| `tes_jeda_scene.gd` `_test_ketuk_jari_kedua` | Pembersihan jari dipindah ke pembantu `_angkat_semua_jari()` (perilaku sama) | Dipakai ulang tes baru |
| `probe_*_jendela.gd` (6) | `quit()`/`quit(1)` → `await ProbeKeluar.keluar(self[, 1])` | D-3 |
| `probe_umpan_balik_jendela.gd` | + skenario `pindah_sisi` sesudah `ngebut`, lalu ngebut 1,5 detik lagi sebelum rem; cetak lateral | AC-7 |

Tidak ada tes yang dihapus atau di-skip. Tes baru: `_test_rem_padam_saat_jeda` (×4), `_test_tombol_sentuh_terpisah`, `_test_tekan_tidak_tertinggal` (tes_jeda_scene), `_test_notifikasi_sendiri` (tes_bunyi), `_test_probe_tidak_ikut` (tes_export), `_test_debu_ruang_dunia` (tes_umpan_balik), `_test_probe_keluar_bersih` (run_tests). Pemeriksaan `run_tests`: 4576 (`main`) → 4668.

### Tabel mutan (dijalankan dengan skrip sementara di scratchpad: ganti satu potongan, `run_tests.gd`, `git checkout -- <berkas>`; `git status` bersih sesudahnya kecuali `shots/` yang belum di-commit)

| Mutan | Hasil | Tes yang gagal (contoh) |
|---|---|---|
| Q01 hapus `_kontrol.atur_rem(false)` di `_terapkan_jeda` | mati, 4 gagal | "TOMBOL_EMIT/FOCUS_OUT/PAUSED/BACK: sesudah lanjut stick disentuh ulang: busur rem tetap padam" |
| Q02 `Audio._notification` tidak menghentikan pemutar | mati, 3 gagal | "APPLICATION_PAUSED / APPLICATION_FOCUS_OUT / WM_CLOSE_REQUEST: semua pemutar sepeda berhenti lewat Audio._notification sendiri" |
| Q02a tanpa `APPLICATION_PAUSED` | mati, 1 gagal | "APPLICATION_PAUSED: semua pemutar ..." |
| Q02b tanpa `APPLICATION_FOCUS_OUT` | mati, 1 gagal | "APPLICATION_FOCUS_OUT: semua pemutar ..." |
| Q02c tanpa `WM_CLOSE_REQUEST` | mati, 1 gagal | "WM_CLOSE_REQUEST: semua pemutar ..." |
| Q03 `_lepas_tekan` tidak melupakan jari | mati, 8 gagal | "jari turun di tombol, lalu NOTIFICATION_PAUSED, lalu naik di dalam tombol: tidak memicu" (+ UNPAUSED, pohon dijeda, disembunyikan) |
| Q03a tanpa `PAUSED` di kondisi | mati, 8 gagal | "... lalu NOTIFICATION_PAUSED ..." |
| Q03b tanpa `UNPAUSED` | mati, 6 gagal | "... lalu NOTIFICATION_UNPAUSED ..." |
| Q03c tanpa `VISIBILITY_CHANGED` | mati, 4 gagal | "... lalu DISEMBUNYIKAN_LALU_DITAMPILKAN ..." |
| Q04 naik `canceled` di dalam tetap memicu | mati, 3 gagal | "jari kedua turun di tombol lalu naik canceled di dalam tombol: tidak memicu", "jari pertama (emulasi mouse) naik canceled ..." |
| QA-002 hapus `notification(NOTIFICATION_SCROLL_BEGIN)` | mati, 11 gagal | "sesudah lanjut: tombol jeda tidak dalam keadaan ditekan (gambar HUD_PANEL)", "FOCUS_OUT saat jari di tombol: jeda, status tekan tombol jeda dilepas", "jari itu naik di dalam tombol sesudah lanjut: tidak menjeda lagi, dapat [true, false, true, false, true, false, true]" |
| AC-5a hapus `scenes/dev/cek_render.tscn` dari preset | mati, 4 gagal | "export_presets.cfg memenuhi AC-19 ...: exclude_filter harus memuat scenes/dev/cek_render.tscn (probe render tidak ikut APK normal, QA-004)" |
| AC-5b hapus pola shader dari preset | mati, 4 gagal | "... exclude_filter harus memuat assets/shaders/warna_bayangan.gdshader ..." |
| AC-5c hapus ketiga pola dari preset | mati, 6 gagal | idem |
| AC-5d `POLA_PROBE` skrip kehilangan skrip probe | mati, 1 gagal | "POLA_PROBE di tools/ekspor_cek_render.py = pola probe di exclude_filter preset, dapat [scene, shader]" |
| AC-5e `ekspor_cek_render.py` tidak memulihkan `export_presets.cfg` (dijalankan langsung, `--pck`) | skrip: "export_presets.cfg pulih byte demi byte: TIDAK" + GAGAL, exit 1 (berkas dipulihkan dengan `git checkout`) | pemeriksaan pemulihan di skrip |
| AC-6a debu kembali ke ruang lokal (`ruang_dunia = true` dihapus) | mati, 5 gagal | "(a) pindah sisi: posisi global debu yang sudah ada tidak ikut bergeser (10 partikel)", "(b) maju: ...", "ngebut: debu tertinggal di jalan, terjauh 15.3 px dari roda (gerak debu sendiri paling jauh 18.0 px)", "pindah sisi sambil ngebut: jejak debu tertinggal di sisi lama (0.04 ubin ...)" |
| AC-6b `_pancar` menyimpan posisi lokal walau ruang dunia | mati, 2 gagal | "(c) debu baru muncul di roda belakang posisi sepeda sekarang (jarak 459.81 px ...)" |
| AC-6c debu `top_level` | mati, 3 gagal | "debu tanpa top_level dan tanpa z di atas pemain (urutan gambar tetap di belakang sprite)" |
| D-3a probe umpan balik `quit()` langsung | mati, 1 gagal | "res://tests/probe_umpan_balik_jendela.gd: semua jalur keluar lewat await ProbeKeluar.keluar (tanpa quit langsung): quit()" |
| D-3b jalur gagal probe gerak `quit(1)` langsung | mati, 1 gagal | idem untuk `probe_gerak_jendela.gd`: quit(1) |

Semua mutan mati. Mutan setara yang diketahui: tidak ada.

### Probe yang memuat `jalan_uji.tscn` dan hasil keluarnya (AC-4)

Enam probe memuat scene utama (`application/run/main_scene`): `probe_umpan_balik_jendela.gd`, `probe_dorongan_jendela.gd`, `probe_input_jendela.gd`, `probe_gerak_jendela.gd`, `probe_lempar_jendela.gd`, `probe_layar_jendela.gd`. `probe_layar.gd` (headless) tidak memuat scene dan tidak diubah. Di `HEAD` `8e583d2`, jendela asli 2340x1080 (`--position 0,0`), keluaran ke folder scratchpad di luar repo, dua putaran:

```
putaran 1 dan 2: probe_umpan_balik_jendela, probe_dorongan_jendela, probe_input_jendela, probe_gerak_jendela,
                 probe_lempar_jendela, probe_layar_jendela: exit 0, 0 baris ERROR/WARNING (termasuk leaked / still in use)
probe_umpan_balik_jendela 1920x1080 (sebelum 8e583d2): exit 0, 0 ERROR/WARNING
sebelum perubahan (di awal run, kode main): probe_umpan_balik_jendela 2340x1080 exit 0 dengan
  WARNING: 2 ObjectDB instances were leaked at exit / ERROR: 1 resources still in use at exit
```

Beberapa putaran mencetak `PERINGATAN: layar jeda terbuka (jendela kehilangan fokus)` milik probe sendiri (bukan `WARNING:` Godot; jendela kehilangan fokus, probe melanjutkan lewat `minta_lanjut`). Jalur gagal: dicek kode + penjaga teks (tidak dijalankan dengan scene utama yang rusak).

### Bukti ekspor (AC-5)

```
godot --headless --path . --export-pack "Android" build/kring-uji.pck
  exit 0, 0 ERROR/WARNING, 446.388 byte; grep -a -c: cek_render 0, warna_bayangan 0, res://tests/ 0, jalan_uji 8;
  project.binary main_scene = res://scenes/dev/jalan_uji.tscn
python3 tools/ekspor_cek_render.py --pck build/kring-cek-render.pck
  project.godot pulih byte demi byte: ya / export_presets.cfg pulih byte demi byte: ya
  464.032 byte, scene utama di project.binary = res://scenes/dev/cek_render.tscn; berkas probe di hasil ekspor: semua ada; exit 0
godot --headless --path . --export-debug "Android" builds/kring-kring-debug.apk
  exit 0, 0 ERROR/WARNING, 28.614.948 byte, 229 entri; entri cek_render [] , warna_bayangan [], assets/tests/ 0;
  assets/project.binary main_scene = jalan_uji.tscn
python3 tools/ekspor_cek_render.py --apk builds/kring-cek-render-debug.apk
  kedua berkas pulih: ya; berkas probe di hasil ekspor: semua ada; lolos
git status --porcelain sesudah semua ekspor: kosong (selain shots/ yang belum di-commit saat itu)
Pemulihan saat gagal: --godot /tidak/ada/godot -> "Godot tidak bisa dijalankan", exit 1; --godot /usr/bin/false -> exit 1;
  KeyboardInterrupt (SIGINT ke skrip yang menunggu godot palsu "sleep 20") -> exit 130; ketiganya: md5 project.godot dan
  export_presets.cfg sebelum = sesudah, dan selama ekspor keduanya memang berubah (md5 berbeda).
```

Sebelum D-4 paket normal memuat probe (QA Run 1B); saya tidak mengulang ekspor kode lama.

### Bukti visual (AC-7)

`godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_umpan_balik_jendela.gd -- docs/loop/20261014-fase1c-perapian/shots` (di `512751e`, kode debu sama dengan HEAD): 7 tangkapan (`santai`, `ngebut`, `pindah_sisi`, `rem`, `rem_berhenti`, `jeda`, `kidal_ngebut`). Keluaran: ngebut 6,00 u/d lateral 0,00, debu 10, garis 4; pindah_sisi 5,50 u/d lateral 0,75, debu 9, garis 4. `python3 tools/cek_blok_piksel.py 3 --kecualikan 1026,12,1315,139 --kecualikan 630,879,1141,1057 <png>` (kotak teks dari probe; `jeda` dan `kidal_ngebut` dengan kotak masing-masing): 7/7 berkas **0 blok tidak seragam**; kontrol negatif `pindah_sisi` tanpa pengecualian: 662 blok tidak seragam. Yang saya lihat: `ngebut` jejak titik krem 1-2 px sepanjang sekitar 100 px di belakang roda, sejajar jalan, di belakang sprite; `pindah_sisi` jejak titik dari garis tengah lama melengkung ke roda di sisi dekat, garis kecepatan tetap di sekitar pengendara. Jejak terbaca tetapi tipis.

### Gerbang (HEAD `8e583d2`, sebelum commit LOG)

```
godot --headless --import                                   # exit 0, 0 ERROR/WARNING
godot --headless --script res://tests/run_tests.gd 2>&1 | tee build/tests.log   # 4668 lolos, 0 gagal
python3 tools/cek_keluaran_tes.py --ketat build/tests.log   # pemeriksa: lolos (4668 lolos, 0 gagal, 0 peringatan)
python3 tools/tests_cek/uji_pemeriksa.py                    # 16 kasus, 0 menyimpang
python3 tools/tests_cek/uji_bangun_frames.py                # 41 lolos, 0 gagal
python3 tools/tests_cek/uji_sintesis_sepeda.py              # 32 lolos, 0 gagal
godot --headless --path . --quit-after 2                    # exit 0, 0 ERROR/WARNING
git diff main --name-only | grep -E "keystore|\.apk|\.aab|\.godot/|^build/|^builds/|\.jks|\.p12|export_credentials|override.cfg"   # kosong
```

Klon bersih per commit (`git clone` lokal ke scratchpad di luar repo, `checkout`, `git clean -fdx`, `rm -rf .godot`, import, `run_tests` + `--ketat`, `--quit-after 2`, tiga uji alat, `git status --porcelain` sesudah import dan di akhir); semua commit hijau sendiri, `.uid` baru (`tests/probe_keluar.gd.uid`) ter-commit:

| Commit | Import ERROR/WARNING | Porcelain sesudah import | `run_tests` | `--ketat` | `--quit-after 2` | uji_pemeriksa / bangun_frames / sintesis | Porcelain akhir |
|---|---|---|---|---|---|---|---|
| `a960e28` | 0 | kosong | 4593 lolos, 0 gagal | lolos | 0 | 16 kasus 0 menyimpang / 41 lolos / 32 lolos | kosong |
| `f052948` | 0 | kosong | 4627 lolos, 0 gagal | lolos | 0 | sama | kosong |
| `abbf9c2` | 0 | kosong | 4642 lolos, 0 gagal | lolos | 0 | sama | kosong |
| `61b3915` | 0 | kosong | 4653 lolos, 0 gagal | lolos | 0 | sama | kosong |
| `512751e` | 0 | kosong | 4668 lolos, 0 gagal | lolos | 0 | sama | kosong |
| `8e583d2` | 0 | kosong | 4668 lolos, 0 gagal | lolos | 0 | sama | kosong |

### Tidak bisa saya verifikasi

- Semua di HP (NEEDS-MANUAL di atas): ikon jeda sesudah home + Lanjut, swipe gesture sistem di atas tombol jeda (`canceled` dari OS sungguhan; tes memakai event sintetis), keterbacaan jejak debu, 60 fps dengan debu ruang dunia.
- Kebocoran `probe_dorongan_jendela.gd` yang muncul sekali tidak bisa diulang dengan sengaja; perbaikan `8e583d2` berdasar penalaran (lihat D-3).
- `SCROLL_BEGIN` sebagai cara melepas status tekan `BaseButton` hanya dibuktikan di Godot 4.7.2 desktop (headless dan tes); bukan API yang didokumentasikan untuk itu.
- Keluar dari game desktop dengan menutup jendela saat bunyi berjalan (catatan QA-003 Run 1B) tidak diuji; jalur itu `WM_CLOSE_REQUEST` → `Audio` berhenti sendiri (kini dites Q02), tanpa masa tunggu.
