# Loop Log — 20261014-fase2a-lemparan
Scope: Run 2A Fase 2, inti lemparan koran (`ThrowSolver`, garis bidik = hasil, koran terbang, zona sasaran placeholder, sisa koran, jeda 0,35 detik) + perapian Run 1C (QA-001, QA-002, QA-005)  ·  Branch: `feat/fase2a-lemparan`  ·  Mulai: 2026-10-14  ·  Godot: 4.7.2

## Status: PASSED   (iterasi saat ini: 2/2)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 1 | 1a (logika murni + P-1..P-3) dan 1b (scene, garis bidik, koran terbang, penanda, zona, HUD koran, probe, dokumen); HEAD `9408318` | ✅ import 0 ERROR/WARNING, 5776 lolos 0 gagal, `--ketat` lolos, `--quit-after 2` bersih, PCK tanpa tests/docs/probe, klon bersih `git status` kosong | **FAIL** (1 Major OPEN) | 7 (Major 1, Minor 4 termasuk 1 NEEDS-MANUAL, Nit 2) | 0 |
| 2 | Perbaikan QA-001..QA-007 (lihat Catatan Dev iterasi 2); HEAD kode `65bc4ed` | ✅ import 0 ERROR/WARNING, 5899 lolos 0 gagal, `--ketat` lolos, `--quit-after 2` bersih, PCK tanpa tests/docs/probe, klon bersih `git status` kosong | **PASS** (0 Blocker/Major terbuka; QA diverifikasi ulang di klon bersih HEAD `fa3c601`: import 0 ERROR/WARNING, 5899 lolos 0 gagal, `--ketat` lolos, PCK bersih) | 2 (Minor 1: QA-008, Nit 1: QA-009) | 7 (QA-001..QA-007; QA-007 bagian terukur, sisanya NEEDS-MANUAL) |

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|
| QA-001 | 1 | Major | scripts/entities/jalan_uji.gd:144-148 (`_saat_swipe_selesai` memakai `akhir` dari event lepas), scripts/systems/touch_router.gd:81-92 | **AC-4/D-4 dilanggar saat jari masih bergerak ketika diangkat (flick).** Garis bidik yang tampil dihitung di `perbarui` dari `router.posisi_swipe()` frame terakhir, tetapi lemparan dihitung ulang di `_saat_swipe_selesai` dari posisi event LEPAS. Bila ada `InputEventScreenDrag` (atau posisi lepas berbeda) sesudah `perbarui` terakhir dan sebelum jari diangkat, \|dx\| lemparan berbeda dari garis bidik yang tampil, jadi koran TIDAK mendarat di elips terakhir. Keadaan sepeda sama; yang berbeda hanya masukan swipe. Tes AC-4 (`tes_koran_scene.gd` `_test_prediksi_sama_hasil`) selalu melepas di titik yang sama dengan drag terakhir sehingga kasus ini tidak pernah diuji. **Repro (dijalankan QA, skrip SceneTree sementara di klon, tidak di-commit):** viewport 780, sentuh jari 1 di (720, 200), geser ke (600, 200), `perbarui(1/60)` → garis bidik tampil, mendarat (-2.6326, -2.5605); lalu geser ke (570, 200) dan angkat di (570, 200) tanpa `perbarui` → lemparan mendarat (-3.0968, -2.6799), **selisih 0,479 ubin** (> 1e-4). Flick 30 px game per frame (90 px fisik / 16 ms) wajar di HP. Saran: lemparan memakai lintasan garis bidik yang terakhir tampil bila swipe ditahan cukup lama untuk menampilkannya (atau masukan swipe yang dibekukan saat `perbarui` terakhir), lalu tes scene: drag sesudah frame terakhir + lepas = titik mendarat tetap titik akhir garis bidik yang tampil. Bila Dev berpendapat posisi lepas lebih tepat, itu mengubah kontrak AC-4 dan harus diputuskan pemilik, bukan diam-diam. | VERIFIED | Lemparan memakai OBJEK lintasan garis bidik yang tampil untuk swipe itu (dibekukan pada langkah terakhir), bukan posisi lepas; tanpa garis bidik tampil dihitung dari posisi lepas dengan `lintasan_swipe` dan keadaan sepeda yang sama; posisi lepas yang sendirian tidak melempar (ditarik kembali < 6% atau tegak) = batal; `TouchRouter.nomor_swipe` mencegah garis bidik basi swipe yang dibatalkan. `scripts/entities/jalan_uji.gd` (`_saat_swipe_selesai`, `lintasan_bidik_tampil`, `_bidik_nomor`), `scripts/systems/touch_router.gd`, BALANCING 4, DESIGN_SPEC 3.7. `09bc6ff`, `109d3a5` | `tes_koran_scene.gd`: `_test_flick` (repro QA 720 → 600, langkah, 570, angkat di 560; dt 1/30 dan 1/240, sepeda mengerem lalu pindah sisi; kontrol selisih > 0,1 ubin), `_test_flick_arah_lain` (tarik kembali/tegak/ke titik awal = batal), `_test_swipe_tanpa_garis_bidik` (swipe satu frame, garis bidik basi). Mutan F1-F7 mati (F1 = bug lama) |
| QA-002 | 1 | Minor | docs/BALANCING.md:81 | Kalimat lama "Swipe berikutnya diabaikan selama animasi lempar berjalan (usulan sederhana)" masih ada di BALANCING 2, bertentangan dengan D-9 dan dengan BALANCING 4 baru ("Animasi lempar tidak lagi menolak swipe sendiri ... hanya jeda 0,35 dan sisa koran") dan kode `LoperSprite.lempar` (menyela lempar lama). Dua bagian dokumen yang sama berbeda aturan (rule `docs`: jangan biarkan dokumen berbeda). Repro: `grep -n "Swipe berikutnya diabaikan" docs/BALANCING.md`. | VERIFIED | Kalimat BALANCING 2 diganti aturan D-9 (animasi tidak menolak sendiri; menyela = tutup lempar lama lalu frame 0) + catatan 10. `docs/BALANCING.md`. `6e246cf` | Dokumen saja; `grep -n "Swipe berikutnya diabaikan" docs/BALANCING.md` kosong. Perilaku dijaga tes lama `_test_loper_sprite_lempar_menyela`, `_test_dua_lempar_cepat` |
| QA-003 | 1 | Minor | scripts/entities/koran_gambar.gd:69,55; scripts/entities/zona_gambar.gd:50; scripts/entities/jalan_uji.gd:180; scripts/ui/deret_koran.gd:29 | Kabel gambar node tidak dijaga tes headless; lima mutan QA HIDUP (5776 lolos, 0 gagal): Q16 penanda selalu `CENTANG` (meleset/bukan pelanggan/jendela tampil centang hijau; hanya warna yang beda), Q18 bayangan digambar di posisi udara bukan di tanah, Q23 rumah bukan pelanggan tidak pernah ditandai (semua kavling memakai pola pelanggan), Q24 `ZonaGambar.perbarui(0.0)` (zona tidak ikut jalan, bergeser dari rumah), Q27 ikon HUD terpakai tidak pernah redup. Fungsi murni pemetaannya dites (`ZonaSasaran.penanda`, `SisaKoran.ikon_hud`, `KoranLempar.lebar_bayangan_px`), tetapi node bisa mengabaikannya tanpa ketahuan. Saat ini perilakunya benar (dilihat di tangkapan QA), jadi Minor. Saran: ekspos data gambar yang murah dicek (mis. `KoranGambar.pola_penanda_tampil(koran)`, `ZonaGambar.kavling_bukan_pelanggan()`, `DeretKoran.alpha_ikon(i)`, `ZonaGambar` mengikuti `_pertama` dari jarak) dan cek di `tes_koran_scene.gd` `_test_hud_dan_zona`. | VERIFIED | Keputusan gambar pindah dari `_draw` ke perintah gambar `GambarPiksel` yang bisa dites: `KoranGambar.perintah_koran`/`perintah_tampil` (+ `pojok_bayangan`, `pojok_penanda`), `ZonaGambar.perintah_kavling_tampil`/`perintah_tampil`, `DeretKoran.alpha_ikon`/`perintah_tampil`; `_draw` hanya `GambarPiksel.gambar`. `8c5bfa9` | `tes_koran_scene.gd`: cek node UDARA/TANAH di `_test_elips_dan_jendela`, `_test_perintah_gambar_koran`, `_test_gambar_koran_terbang`, kabel zona di `_test_hud_dan_zona`, deret di `_test_habis_dan_isi_ulang`. Lima mutan QA (Q16, Q18, Q23, Q24, Q27) + G1-G5 mati |
| QA-004 | 1 | Minor | scripts/ui/garis_bidik.gd:74-84 (digambar di atas objek dunia) | Saat titik mendarat ada di belakang fasad (di dalam tapak rumah graybox seberang, mis. lempar panjang ke seberang), elips pendaratan dan ujung garis bidik digambar DI ATAS atap/dinding rumah, sehingga terbaca seperti sasaran di atap. Koran lalu mendarat "di dalam" rumah dan dinilai MELESET tanpa isyarat. Bukti: tangkapan QA `shots/iter1-qa/2340x1080_koran_bidik_panjang_seberang_ngebut.png` (elips di atap rumah), `2340x1080_koran_kidal_bidik_seberang.png` dan `1920x1080_koran_kidal_bidik_seberang.png` (elips di dinding samping). Tabrakan koran dengan objek di luar scope, tetapi keterbacaan prediksi (D-5) perlu dinilai: minimal dicatat di NEEDS-MANUAL; usulan perbaikan murah: elips/ujung garis yang jatuh di tapak rumah digambar redup atau sebagai cincin biasa (tetap cincin, sudah tidak sah). | VERIFIED | Aturan murni `ZonaSasaran.tertutup_kotak` / `tertutup_rumah_jalan_uji` / `tapak_rumah_jalan_uji` (titik tertutup bila ada titik kotak rumah di depannya pada posisi layar sama, tinggi koran dihitung); `KoranLempar.Elips` + `bentuk_elips`, `tertutup_pada`; elips TERTUTUP = cincin putus-putus `TEXT` alpha 0,5 (`PolaPiksel.ELIPS_TERTUTUP`), titik garis bidik tertutup redup (`GarisBidik.warna_titik`, `perintah_elips`); `Config.JALAN_UJI_RUMAH_PANJANG/DALAM/TINGGI_UBIN` (fakta aset), `GARIS_BIDIK_TERTUTUP_ALPHA`. DESIGN_SPEC 3.7, BALANCING 4. `270390e` | `tes_lempar.gd` `_test_tertutup_rumah` (kasus tepi, tinggi, dasar proyeksi, ukuran PNG rumah = Config, semua zona tidak tertutup, bentuk elips) dan pola di `_test_pola_piksel`; `tes_koran_scene.gd` `_test_elips_tertutup` + elips per kasus di `_test_elips_dan_jendela`. Mutan T1-T12: 11 mati, T10 hidup setara |
| QA-005 | 1 | Nit | docs/loop/20261014-fase2a-lemparan/LOG.md (Catatan Dev 1b, Tangkapan layar) | Klaim Dev "`bidik_pendek_seberang_santai` (elips biasa)" salah: keluaran probe QA dan tangkapan menunjukkan `elips sah true` (swipe min dari lateral 0 di santai mendarat tepat di kotak surat seberang, -1,5 lateral). Elips biasa tetap ada di `bidik_panjang_dekat_santai` dan `bidik_panjang_seberang_ngebut`, jadi AC-12 tetap terpenuhi. Catatan desain: swipe terpendek dari tengah jalan otomatis mengenai kotak surat (bahan uji HP). | VERIFIED | Klaim tangkapan di Catatan Dev 1b dikoreksi: `bidik_pendek_seberang_santai` = elips sah (kotak surat seberang), elips biasa ada di `bidik_panjang_dekat_santai`. LOG ini (commit catatan iterasi 2) | Dokumen saja (keluaran probe iterasi 2: `bidik_pendek_seberang_santai ... bentuk SAH`) |
| QA-006 | 1 | Nit | scripts/ui/gambar_piksel.gd:22-27 | `GambarPiksel.pola` mem-parse pola teks (`PolaPiksel.rentang_huruf`, 4 huruf) dan membuat Array baru tiap `_draw`; garis bidik dan koran digambar ulang tiap frame selama swipe/terbang. Kecil (pola ≤ 12×12), tetapi mudah di-cache per pola (rule `gdscript`: hindari alokasi per frame). | VERIFIED | `GambarPiksel.rentang_pola`: rentang per huruf tiap pola dihitung sekali dan disimpan (hanya-baca, kunci = isi pola); `perintah_pola` memakainya. `scripts/ui/gambar_piksel.gd`. `8c5bfa9` | `_test_perintah_gambar_koran` (objek sama untuk isi sama, = parse, hanya-baca, pola berbeda tidak tertukar). Mutan C1, C2 mati |
| QA-007 | 1 | Minor | scripts/config.gd:156 (`KORAN_BAYANGAN_ALPHA` 0,5, `OUTLINE`), koran 8×6, penanda 7-9 px | Keterbacaan di ×3: bayangan koran `OUTLINE` alpha 0,5 di atas aspal abu tua nyaris tak terlihat (tangkapan `2340x1080_koran_puncak_kotak_surat.png`, diperbesar QA), padahal BALANCING 4 "bayangan koran di tanah wajib tampil"; koran gulung di puncak (bingkai tegak 3-4 px lebar) dan penanda 7-9 px kecil dibanding layar penuh. Tidak bisa dinilai di desktop. | VERIFIED (bagian terukur) + NEEDS-MANUAL (keterbacaan di HP) | Bayangan koran alpha 0,5 → 0,85, lebar 8 → 4 px menjadi 10 → 6 px (`KORAN_BAYANGAN_*` di `scripts/config.gd`); kontras di aspal graybox sekitar 2,1:1 → 3,2:1 (trotoar 9,1:1, rumput 6,8:1). Ukuran koran 8×6 dan penanda 7-9 px TIDAK diubah: perlu pola baru atau piksel ×2 (mencampur ukuran piksel = keputusan gaya), jadi dinilai di HP. BALANCING 4/10, ART_DIRECTION 6.2 (usulan). `77556ce` | `tes_lempar.gd` `_test_bayangan_kontras` (WCAG ≥ 3:1 di atas warna PNG aspal, trotoar, rumput) dan cek lebar bayangan > koran, min 6. Mutan B1-B3 mati |
| QA-008 | 2 | Minor | scripts/ui/gambar_piksel.gd:19-29 dan 50-61 (`warna_huruf`, `perintah_pola`); oracle tes di tests/tes_koran_scene.gd:176, 848-851, 864-865, 966, 1013 | **Sisa celah QA-003: penerjemah perintah gambar dipakai sebagai oracle tes.** Tes kabel gambar membandingkan perintah node dengan `GambarPiksel.perintah_pola(...)` yang SAMA dengan yang dipakai node, jadi kesalahan di `perintah_pola`/`warna_huruf` sendiri tidak terlihat. Empat mutan QA HIDUP (5899 lolos, 0 gagal): N16 `warna.a *= alpha` dibuang (ikon HUD terpakai tidak redup 28% dan elips tertutup tidak redup, padahal AC-9/QA-004), N22 alpha ditimpa 1, N20 huruf `o` memakai warna utama (garis luar penanda/elips sah ikut OK/FAIL), N21 huruf `w` dilewati (isi warna penanda, elips sah, koran, dan ikon tidak digambar: penanda tinggal garis luar). Perilaku sekarang benar (dilihat di tangkapan `shots/iter2-qa/`: HUD HABIS 8 ikon redup, elips tertutup redup, penanda berwarna), jadi Minor. Repro: terapkan salah satu baris mutan di klon, `run_tests` tetap 0 gagal. Saran: tes harapan memakai rentang/warna yang ditulis eksplisit (mis. warna dan alpha perintah ikon ke-i, isi `w` penanda = `OK`/`FAIL`, garis luar = `OUTLINE`), bukan memanggil `perintah_pola`. | DEFERRED (Minor, orchestrator 2026-10-14: run PASSED di iterasi 2; tampilan sekarang benar menurut tangkapan QA iterasi 2; oracle independen untuk `GambarPiksel.perintah_pola` dikerjakan di Run 2B) | — | — |
| QA-009 | 2 | Nit | scripts/entities/jalan_uji.gd:153-169 (`_saat_swipe_selesai`) | Aturan baru "posisi lepas harus melempar sendiri" (109d3a5) hanya memeriksa ambang 6% dan dominan datar, **tidak memeriksa sisi**. Repro QA (skrip SceneTree sementara di klon): jari 1 di (500, 200), geser ke (420, 200), `perbarui(1/60)` → garis bidik SEBERANG tampil; geser ke (560, 200) dan angkat di sana tanpa langkah (swipe utuh = dx +60, arti DEKAT menurut D-2) → lemparan diterima ke SEBERANG (`lempar_kiri_santai_normal`). Prediksi = hasil tetap terjaga (yang terlempar = yang tampil), dan gerak semacam ini (> 100 px game dalam satu frame) hampir mustahil di HP, jadi Nit. Tidak tertulis di BALANCING 4 / DESIGN_SPEC 3.7; bila aturan ini dipertahankan, sebaiknya kasus sisi berlawanan dinyatakan (batal, atau ikut garis bidik). | Dicatat (Nit) | — | — |

## NEEDS-MANUAL (uji di HP)
- [ ] Ketelitian swipe pendek: swipe sekitar 6% lebar layar terbaca sebagai lempar dekat, tidak tertukar dengan sentuhan tak sengaja, ketukan, atau swipe tegak; swipe panjang 35% nyaman dijangkau jempol kanan.
- [ ] Mengenai kotak surat dengan sengaja di santai, cepat, dan ngebut; garis bidik membantu melempar lebih awal saat ngebut. Catat apakah swipe terpendek dari tengah jalan terlalu mudah mengenai kotak surat seberang (QA-005).
- [ ] Garis bidik dan elips terlihat di bawah jempol, tidak tertutup jari; elips sah (terisi) terbaca tanpa mengandalkan warna. Saat ngebut ke seberang lengkung tampak hampir lurus tegak di layar (proyeksi), nilai apakah masih terbaca sebagai lengkung.
- [ ] Flick cepat (jari masih bergerak saat diangkat): koran mendarat di elips terakhir yang terlihat (QA-001, diperbaiki iterasi 2)? Menarik jari kembali ke titik awal lalu mengangkat membatalkan lemparan tanpa terasa menelan swipe yang disengaja? Swipe sangat cepat (selesai sebelum garis bidik sempat tampil) tetap melempar?
- [ ] Elips dan ujung garis bidik yang jatuh di dalam atau di balik rumah kini cincin putus-putus redup dan titik redup (QA-004, iterasi 2): terbaca sebagai "di balik rumah, meleset", bukan sasaran di atap?
- [ ] Lengkung koran dan bayangan terbaca di ×3, terutama bayangan di atas aspal (iterasi 2: alpha 0,85, 10 → 6 px, kontras sekitar 3,2:1 di aspal graybox); koran 8×6 dan penanda centang, setengah, dan silang kecil (7-9 px, tidak diubah) terbaca; meleset tidak terasa menghukum (QA-007).
- [ ] Lempar ke sisi dekat terasa wajar walau zonanya placeholder datar.
- [ ] HUD sisa koran terbaca, tidak tertutup jempol kanan; swipe yang mulai di atas panel tetap melempar; habis (HABIS, ikon redup) lalu terisi ulang sesudah sekitar 16 ubin; kidal memindahkan panel. Tafsiran 8 ikon = delapan koran terakhir (ikon baru redup di bawah 8): cukup informatif?
- [ ] Jeda 0,35 detik tidak terasa menelan swipe yang disengaja.
- [ ] Home/notifikasi saat koran terbang dan tepat sesudah jari dilepas: layar jeda, koran diam, sesudah Lanjut mendarat tanpa lompatan, koran berkurang satu saja.
- [ ] Jendela penalti ringan (strip tanah di kaki fasad, silang kecil): terasa adil? Bahan keputusan ROADMAP 5. Strip jendela di tanah terbaca sebagai "jendela"?
- [ ] Teras placeholder (`UI_PANEL_RAISED`, gelap) mudah dikira bayangan rumah: terbaca sebagai sasaran?
- [ ] (QA iterasi 2) Aturan batal saat jari diangkat (109d3a5): swipe datar yang ujungnya melengkung (jempol naik atau turun saat diangkat) atau sedikit kembali sebelum diangkat tidak dibatalkan tanpa sengaja; catat berapa kali swipe yang terasa disengaja tidak melempar. Aturan ini usulan (BALANCING 4, DESIGN_SPEC 3.7) dan menunggu persetujuan pemilik di review PR.

## Keputusan & catatan
- Orchestrator 2026-10-14 sesudah PR #24 dibuka: APK debug normal (28,7 MB, tanpa probe, `tests/`, `docs/`) dipasang ke vivo V2108 (`12d8c9da`) dengan `adb install -r` atas permintaan pemilik (layar menyala, di launcher; tanpa `pm clear`/uninstall). A54 tidak dipasangi: saat dicek DroidCam OBS sedang terbuka. Uji HP (NEEDS-MANUAL di atas, `SETUP_ANDROID.md` 8) oleh pemilik.
- Orchestrator 2026-10-14: QA PASS iterasi 2 → status PASSED. QA-008 (Minor) DEFERRED ke Run 2B, QA-009 (Nit) dicatat. Orchestrator mengulang `run_tests` di HEAD `f6b0b87`: 5899 lolos, 0 gagal, `--ketat` lolos.
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

## Catatan Dev iterasi 1b

Bagian 1b dari 2 (Dev, bagian terakhir sebelum QA): kabel scene lemparan, garis bidik di ruang dunia, koran terbang + bayangan + penanda, zona placeholder tampil, HUD sisa koran, tes scene AC-4/6/7/8, tata letak AC-9, mutan scene AC-10, probe jendela AC-12, dokumen AC-14 sisanya. Logika murni 1a dipakai apa adanya (tidak ada rumus 1a yang diubah; `SisaKoran` hanya ditambah `ikon_hud`). Tidak push.

### Commit

| Commit | Ringkasan | File |
|---|---|---|
| `00ab6fd` | feat: KoranLempar dan PolaPiksel murni untuk koran terbang, garis bidik, dan penanda | `scripts/systems/koran_lempar.gd`, `pola_piksel.gd` (+`.uid`, baru), `sisa_koran.gd` (`ikon_hud`), `scripts/config.gd` (angka tampilan `KORAN_*`, `PENANDA_ATAS_PX`, `GARIS_BIDIK_SAMPEL`, `ZONA_GARIS_ALPHA`, `HUD_PANEL_KORAN_GESER_PX`, `HUD_KORAN_*`), `docs/BALANCING.md` 4 dan 10, `tests/tes_lempar.gd` (`_test_koran_lempar`, `_test_titik_bidik`, `_test_pola_piksel`) |
| `0e9b9f1` | feat: lemparan koran di jalan uji: garis bidik, koran terbang, penanda, zona, HUD koran | `scripts/entities/jalan_uji.gd`, `sepeda_uji.gd` (`lateral_ud`, `jeda_lepas`), `loper_sprite.gd` (D-9, `jeda_lepas`), `koran_gambar.gd`, `zona_gambar.gd` (+`.uid`, baru), `scripts/ui/garis_bidik.gd`, `deret_koran.gd`, `gambar_piksel.gd` (+`.uid`, baru), `hud_dev.gd`, `kontrol_touch.gd` (garis putus lama dihapus), `scenes/dev/jalan_uji.tscn`, `scenes/ui/hud_dev.tscn`, `translations/ui.csv` + `ui.id.translation`, `tests/tes_koran_scene.gd` (+`.uid`, baru), `run_tests.gd`, `tes_input_scene.gd`, `tes_sprite.gd`, `tes_tata_letak.gd` |
| `a0ac448` | test: titik lepas memakai lateral efektif dan tes jeda koran tahan mutan | `tests/tes_koran_scene.gd` |
| `ccd7aa6` | test: probe jendela lemparan koran dan tangkapan layar 640/780 (AC-12) | `tests/probe_koran_jendela.gd` (+`.uid`), `docs/loop/20261014-fase2a-lemparan/shots/` (36 PNG) |
| `ac9c327` | docs: tafsiran HUD koran, penanda, garis bidik, koran placeholder, dan uji HP Run 2A | `docs/design/DESIGN_SPEC.md` 3.5-3.7, `docs/ART_DIRECTION.md` 6.2, `docs/SETUP_ANDROID.md` 8.3, `AGENTS.md`, `.cursor/rules/00-project-core.mdc`, `docs/README.md` |
| (commit terakhir, lihat `git log`) | docs: catatan Dev iterasi 1b run 2A | LOG ini |

Klon bersih per commit kode (`git clone` + checkout): `00ab6fd` import 0 `ERROR`/`WARNING`, 5459 lolos 0 gagal, `--ketat` lolos, `--quit-after 2` bersih, `git status --porcelain` kosong; `0e9b9f1` sama, 5768 lolos. HEAD: lihat Gerbang.

### Keputusan di dalam ruang D-x (bisa ditolak di review)

- **D-4 (scene).** Satu fungsi `JalanUji.lintasan_swipe(awal, akhir)` = `ThrowSolver.sisi_dari_swipe` lalu `ThrowSolver.dari_swipe(..., posisi_dunia, kecepatan_ud, SepedaUji.lateral_ud, SepedaUji.jeda_lepas(sisi))`. Garis bidik dihitung di `perbarui` **sesudah** `SepedaUji.gerak` (keadaan frame ini); jari dilepas datang di `_input` sebelum `_process` berikutnya, jadi lemparan memakai keadaan yang sama persis dengan garis bidik yang tampil. `SepedaUji.lateral_ud` = `BikeMotion.Hasil.lateral_ud` langkah terakhir (0 di tepi jalan atau pada langkah `dt` 0). Jeda lepas dari `LoperSprite.jeda_lepas(sisi)` = `LemparWaktu.waktu_lepas` animasi yang akan dimainkan (2/12 detik).
- **D-4/D-11 (koran tidak terikat sinyal sprite).** Koran (`KoranLempar.Koran`) dibuat saat lemparan diterima dan maju dengan `dt` efektif `JalanUji`; tampil di udara saat `waktu_terbang + LEMPAR_TOLERANSI_DETIK >= 0` (sama dengan syarat frame lepas `LemparWaktu`), **bukan** saat sinyal `koran_lepas`. Alasan: D-11 meminta lemparan yang jedanya datang sebelum frame lepas tetap terbang sesudah lanjut, padahal `batalkan_lempar` menutup animasi tanpa sinyal. Di game kedua jam memakai `delta` yang sama, jadi koran muncul di tangan pada frame lepas.
- **D-9 (sprite).** `LoperSprite.lempar` tidak lagi menolak selama animasi. Yang menolak hanya `SisaKoran.boleh_lempar` di `JalanUji._saat_swipe_selesai` (koran ada dan jeda 0,35 lewat; ditolak = koran tidak berkurang, jeda tidak mulai ulang). Bila jam sprite tertinggal dan lempar baru datang saat animasi lama masih jalan, lempar lama ditutup dulu: `koran_lepas` dipancarkan bila belum, lalu `lempar_selesai`, baru lempar baru dari frame 0 (tiap lempar tetap tepat sekali kedua sinyal). `batalkan_lempar` tetap tanpa sinyal (jeda game). Dokumentasi `lempar_selesai` diperluas: "habis, atau disela lempar berikutnya".
- **D-5.** `GarisBidik` (`scripts/ui/`, Node2D anak akar dunia, digambar di atas objek): titik 2×2 `TEXT` di waktu `KoranLempar.waktu_titik_bidik` (titik pertama t = 0, lalu tiap kali jarak layar sepanjang lengkung dari titik sebelumnya ≥ 4 px, dari 96 + 1 sampel merata `posisi_pada`; tiap titik = proyeksi `Iso` sampel `posisi_pada`, dibulatkan). Elips 10×5 berpusat di titik mendarat: cincin `TEXT` biasa, elips **terisi** `OK` bergaris `OUTLINE` bila `KoranLempar.prediksi_antaran` sah (bentuk berubah). Tampil hanya bila swipe aktif, lintasan tidak null (|dx| ≥ min, dominan datar), `SisaKoran.boleh_lempar`, dan tidak jeda; disembunyikan saat jari dilepas (langsung di `_saat_swipe_selesai`), batal, atau jeda. Garis putus lama `KontrolTouch` dihapus.
- **D-10.** Pola piksel dari kode (`PolaPiksel`, huruf peran warna, tanpa hex): koran 8×6 empat langkah putar (mendatar, serong naik, tegak, serong turun) di `KORAN_PUTAR_FPS` 12 berulang sepanjang terbang (tafsiran "berputar 4 langkah" = 4 frame berulang, ART_DIRECTION 6.2); bayangan elips `OUTLINE` alpha 0,5 di lapisan tanah, lebar `roundi(8 − 2 × tinggi)` dijepit 4..8 px; koran tergeletak (frame 0) di lapisan tanah selama penanda; penanda di lapisan udara 7 px di atas titik mendarat: centang 9×7, setengah (belah ketupat terisi separuh) 7×7, bintang 9×9, silang 7×7; warna `OK` bila antaran sah, `FAIL` bila tidak (`KoranGambar.warna_penanda`). Penanda tidak naik/memudar (penyederhanaan placeholder; DESIGN_SPEC 3.6 panel koin baru di Fase 3). Semua digambar sebagai persegi piksel game bilangan bulat (`GambarPiksel`) supaya tajam di `canvas_items` ×3.
- **D-6 (tampilan zona).** `ZonaGambar` di antara ubin tanah dan objek dunia, kavling sama dengan slot rumah `ObjekDaur`; belah ketupat dirasterisasi per baris piksel (`PolaPiksel.rentang_poligon`, tepi 1 px `rentang_tepi`). Halaman garis `TEXT` 70%, teras `UI_PANEL_RAISED` + `OUTLINE`, jendela strip `TEXT_2` + `OUTLINE`, kotak surat sisi dekat datar `ACCENT` + `OUTLINE` (sisi seberang memakai graybox yang ada). Rumah bukan pelanggan: garis halaman dan teras `RADAR_BUKAN` + tanda lingkaran bergaris miring (cakram `RADAR_BUKAN` bergaris `OUTLINE`) datar di antara tengah halaman dan tepi depannya (versi pertama 14 px di atas tengah halaman tertutup dinding rumah, terlihat di tangkapan, lalu dipindah). Kavling sisi dekat selalu pelanggan.
- **D-8 (HUD).** Panel koran satu `HBoxContainer` (`BarisBawah`) dengan panel kecepatan, celah = 400 − 210 − 170 = 20 px dari `Config`; kidal = `BarisBawah` menempel kanan dan panel koran dipindah ke depan (`move_child`). Tafsiran 8 ikon: delapan koran terakhir (`SisaKoran.ikon_hud`: jumlah ikon = min(penuh, 8), terang = min(sisa, jumlah)); habis = label `HUD_KORAN_HABIS` + semua ikon redup 28%. Kunci baru `HUD_KORAN` (KORAN), `HUD_KORAN_ANGKA` ({n}), `HUD_KORAN_HABIS` (HABIS). Panel di dalam zona swipe dan `MOUSE_FILTER_IGNORE`.
- **Isi ulang di scene.** `SisaKoran.isi_ulang_jalan_uji` dipanggil tiap `perbarui` sesudah `SisaKoran.langkah(dt efektif)`.
- **Angka tampilan baru** (bukan angka lintasan; BALANCING 4 dan DESIGN_SPEC/ART_DIRECTION): `KORAN_PUTAR_FPS` 12, `KORAN_BAYANGAN_LEBAR_MAKS_PX` 8, `_MIN_PX` 4, `_SUSUT_PX_PER_UBIN` 2, `_ALPHA` 0,5, `PENANDA_ATAS_PX` 7, `GARIS_BIDIK_SAMPEL` 96, `ZONA_GARIS_ALPHA` 0,7, `HUD_PANEL_KORAN_GESER_PX` 400, `HUD_KORAN_IKON_MAKS` 8, `_IKON_PX` 12, `_IKON_JARAK_PX` 1, `_REDUP_ALPHA` 0,28.

### Tes lama yang diubah (dan kenapa)

- `tests/tes_sprite.gd` `_test_loper_sprite_lempar`: dua cek "lempar(SEBERANG) saat sedang melempar diabaikan (false)" dan "lempar yang diabaikan tidak mengulang animasi" **dihapus** karena D-9 (sprite tidak lagi menolak sendiri); diganti tes baru `_test_loper_sprite_lempar_menyela` (menyela sebelum dan sesudah frame lepas, sinyal tepat sekali, `batalkan_lempar` tanpa sinyal, `jeda_lepas`).
- `tests/tes_input_scene.gd`: pembantu `_swipe` sekarang melewati jeda antar lempar 0,35 detik dulu (`_lewati_jeda`: hanya `SisaKoran.langkah(akar.koran, 0,35)`, sepeda dan sprite tidak bergerak), karena tes animasi lama memajukan waktu sprite terpisah dari waktu scene. Cek "swipe kedua saat masih melempar diabaikan" kini memakai `lewati_jeda = false` dan labelnya "di dalam jeda 0,35 detik diabaikan (D-9)". Isi cek lain tidak berubah.
- `tests/tes_tata_letak.gd`: ditambah cek panel koran (posisi x 400 / cermin kidal, bawah 8, tidak menumpuk zona stick, panel kecepatan, tombol jeda/kidal, di dalam zona swipe, tidak memotong sprite); cek lama tidak diubah.

### Mutan nyata (AC-10; kode dikembalikan sesudah tiap mutan)

Skrip penggantian teks di luar repo (scratchpad), `run_tests` penuh per mutan, tes = HEAD `a0ac448` (S04, S05, S12, S13 dijalankan ulang di HEAD ini dengan stderr ikut dibaca; mutan lain dijalankan pada kode `0e9b9f1` + tes lateral). Baseline: 5776 lolos, 0 gagal, `--ketat` lolos. **20 mutan scene/1b, 20 mati, 0 hidup**, 0 `SCRIPT ERROR` (jumlah cek total sebagian mutan lebih kecil dari baseline karena tes berhenti dengan rapi lewat cek bernama + `return`, bukan error).

| Mutan | Hasil | Tes yang membunuh (contoh label) |
|---|---|---|
| S01 garis bidik dihitung sebelum sepeda digerakkan (kecepatan frame sebelumnya) | mati, 16 gagal | "skenario A dt 1/30: lintasan lemparan = lintasan garis bidik frame jari dilepas ..."; "skenario A dt 1/30: titik mendarat koran (-5.0, -4.662608, 0.0) = titik akhir garis bidik frame jari dilepas (-5.0, -4.442608, 0.0)" |
| S02 garis bidik memakai rumus/argumen sendiri (tanpa lateral dan jeda lepas) | mati, 20 gagal | sama dengan S01 (titik akhir -4.023 lawan mendarat -4.673) |
| S03 lintasan dihitung ulang saat frame lepas dari keadaan baru | mati, 28 gagal | "skenario A dt 1/30: tiap frame posisi koran = ThrowSolver.posisi_sejak_jari(lintasan beku)"; "... titik mendarat koran (-4.418901, -5.813201) = titik akhir garis bidik (-5.0, -4.663201)" |
| S04 jeda game tidak membekukan koran (`_perbarui_lemparan(dt)` mentah) | mati, 4 gagal | "TOMBOL: koran yang terbang tetap ada selama jeda (0)"; "PAUSED: ..." |
| S05 jeda game menghapus koran yang belum lepas/terbang | mati, 4 gagal | "TOMBOL: koran yang terbang tetap ada selama jeda (0)"; "lemparan tetap tercatat: koran 29, satu koran menunggu lepas" |
| S06 koran berkurang dua kali per lemparan (scene) | mati, 19 gagal | "skenario A dt 1/30: satu lemparan diterima, koran -1" |
| S07 LoperSprite tetap menolak lempar selama animasi (perilaku lama) | mati, 10 gagal | "lempar kedua (seberang) saat lempar pertama berjalan: dimulai (true), tidak ditolak sprite"; "lemparan saat animasi sebelumnya masih berjalan ..." |
| S08 garis bidik tampil walau jeda antar lempar/habis | mati, 2 gagal | "dalam jeda antar lempar (0,349): garis bidik tidak tampil walau swipe ditahan"; "habis: garis bidik tidak tampil walau swipe ditahan" |
| S09 HUD koran tidak dicerminkan saat kidal | mati, 6 gagal | "lebar 640 kidal: panel kecepatan pindah ke sisi stick kanan ..." (tes lama) dan cek panel koran tata letak |
| S10 sakelar jendela diabaikan di elips (selalu bonus) | mati, 1 gagal | "SEBERANG JENDELA: elips biasa (cincin TEXT)" |
| S11 garis bidik tidak hilang saat jari dilepas | mati, 4 gagal | "skenario A dt 1/30: garis bidik hilang saat jari dilepas" |
| S12 koran langsung di udara tanpa jeda lepas | mati, 6 gagal | "sebelum jeda lepas: belum di udara, di titik lepas setinggi tangan"; "skenario A dt 1/30: koran tampil di udara pada langkah yang melewati jeda lepas" |
| S13 hasil dinilai di titik lepas, bukan titik mendarat | mati, 9 gagal | "1008 lintasan x 2 sakelar: hasil, antaran, dan penanda saat mendarat = prediksi elips ..."; "kontrol: sampel memuat pendaratan sah (0) dan jendela (0)" |
| S14 isi ulang jalan uji tidak dipanggil di scene | mati, 2 gagal | "16,001 ubin sesudah habis: terisi ulang 30, HUD kembali, penanda habis hilang" |
| S15 kecepatan lateral efektif tidak disimpan (0) | mati, 2 gagal | "stick penuh ke sisi dekat: kecepatan lateral efektif 0.0 u/d"; "titik lepas = posisi + (maju, lateral) x jeda lepas" (tes ditambah di `a0ac448` karena mutan ini lolos dari tes prediksi = hasil: garis bidik dan lemparan sama-sama memakai 0) |
| S16 penanda tidak pernah selesai | mati, 5 gagal | "selesai tepat sesudah 0,8 detik penanda"; "TOMBOL: sesudah lanjut penanda habis dan koran dibuang" |
| S17 titik garis bidik bukan sampel (garis lurus lepas-mendarat) | mati, 16 gagal | "u 0.0, 0.0 u/d: layar_pada = proyeksi Iso posisi_pada" |
| S18 elips sah tidak berubah bentuk | mati, 1 gagal | "elips sah TERISI (bentuk berbeda dari cincin biasa, bukan hanya warna)" |
| S19 bayangan tidak mengecil saat tinggi naik | mati, 2 gagal | "bayangan: 8 px di tanah, 4 px paling kecil ..."; "bayangan tidak membesar saat tinggi naik" |
| S20 swipe yang ditolak jeda tetap memakai koran (scene) | mati, 6 gagal | "swipe dilepas di 0,349 detik: ditolak, koran tetap 29" |

Pemetaan ke sisa daftar AC-10 dari 1a: garis bidik kecepatan frame sebelumnya (S01), garis bidik rumus sendiri (S02; penjaga teks `_test_penjaga_rumus` 1a tetap lolos dengan skrip baru), lintasan dihitung ulang saat frame lepas (S03), jeda game tidak membekukan koran (S04, ditambah S05). Kontrol di tes AC-4 membuktikan skenario membedakan mutan ini: keadaan sepeda berubah di frame terakhir bidik, lintasan yang dihitung ulang saat lepas berbeda > 0,001 ubin, dan kecepatan berubah selama terbang.

### Gerbang (HEAD sebelum commit LOG = `ac9c327`; commit LOG hanya dokumen)

- `godot --headless --import`: 0 `ERROR`/`SCRIPT ERROR`/`WARNING` (klon bersih).
- `run_tests.gd | tee build/tests.log`: **5776 lolos, 0 gagal**; `python3 tools/cek_keluaran_tes.py --ketat build/tests.log`: lolos, 0 peringatan. Sesudah 1a: 5295.
- `uji_pemeriksa.py`: 16 kasus, 0 menyimpang; `uji_bangun_frames.py`: 41 lolos; `uji_sintesis_sepeda.py`: 32 lolos.
- `godot --headless --path . --quit-after 2`: 0 `ERROR`/`WARNING`.
- `godot --headless --path . --export-pack "Android" build/kring-uji.pck`: exit 0, 0 `ERROR`/`WARNING`; 304 jalur terbaca di paket, tidak ada `tests/`, `docs/`, atau `probe`; `koran_lempar` dan `garis_bidik` ada.
- Klon bersih HEAD: import, tes, `--ketat`, `--quit-after 2` bersih dan `git status --porcelain` kosong (lihat baris terakhir catatan ini).
- Probe jendela asli (`godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_koran_jendela.gd -- docs/loop/20261014-fase2a-lemparan/shots`, juga `1920x1080`): exit 0, tanpa `ERROR`/`WARNING`; satu baris `PERINGATAN: layar jeda terbuka (jendela kehilangan fokus)` di awal (jendela probe belum fokus; probe melanjutkan lewat `minta_lanjut`, sama dengan probe lama). Tujuh sasaran dikenai di tiap lebar dan hasil = prediksi (kotak surat, teras, halaman, jendela penalti, bukan pelanggan, meleset, kotak surat sisi dekat ngebut). `python3 tools/cek_blok_piksel.py 3 --kecualikan <kotak teks HUD dicetak probe>`: 36 tangkapan, 0 blok tidak seragam. Tangkapan dilihat sendiri (lihat D-6 untuk perbaikan tanda bukan pelanggan).

### Tangkapan layar (`docs/loop/20261014-fase2a-lemparan/shots/`, awalan `2340x1080_koran_` dan `1920x1080_koran_`)

- Garis bidik: `bidik_pendek_seberang_santai` (elips sah: swipe terpendek dari tengah jalan mendarat di kotak surat seberang; dikoreksi iterasi 2, QA-005), `bidik_kotak_surat` (elips sah, santai), `bidik_panjang_dekat_santai` (elips biasa), `bidik_pendek_dekat_ngebut`, `bidik_panjang_seberang_ngebut`, `bidik_dekat_kotak_surat_ngebut` (elips sah, ngebut).
- Koran di puncak lengkung dengan bayangan: `puncak_kotak_surat`, `puncak_dekat_kotak_surat_ngebut`.
- Penanda: `kena_kotak_surat`, `kena_teras` (centang), `kena_halaman` (setengah), `kena_jendela_penalti`, `kena_bukan_pelanggan`, `kena_meleset` (silang), `kena_dekat_kotak_surat_ngebut`.
- HUD koran: sebagian di semua tangkapan sesudah lemparan pertama (angka turun, 8 ikon terang), `hud_habis` (HABIS, 0, ikon redup, tanpa garis bidik walau swipe ditahan), `hud_isi_ulang` (30 lagi).
- Kidal: `kidal_bidik_seberang` (panel koran dan kecepatan dicerminkan, swipe kiri layar = seberang).

### Catatan untuk QA

- Viewport 800 (20:9) tidak ada di probe (jendela 2400×1080 tidak muat di monitor); 800 dicakup tes tata letak headless.
- Penanda kena/meleset dan koran berukuran kecil di ×3 (koran 8×6, penanda 7-9 px); keterbacaannya NEEDS-MANUAL (SETUP_ANDROID 8.3).
- Tidak ada BLOCKED.
- Klon bersih `0e61e33` (commit LOG): `godot --headless --import` 0 `ERROR`/`WARNING`, 5776 lolos 0 gagal, `--ketat` lolos, `--quit-after 2` 0 `ERROR`/`WARNING`, `git status --porcelain` kosong.

## Catatan QA iterasi 1

Diverifikasi sendiri oleh QA (tidak memakai klaim Dev). HEAD `9408318`, Godot 4.7.2.stable.official.ed1daf0bf (`/opt/homebrew/bin/godot`).

### Gerbang (klon bersih: `git clone` repo lokal ke scratchpad, checkout `feat/fase2a-lemparan`)

| Gerbang | Hasil |
|---|---|
| `godot --headless --import` | exit 0, 0 `ERROR`/`SCRIPT ERROR`/`WARNING`; `git status --porcelain` sesudahnya kosong |
| `run_tests.gd 2>&1 > build/tests.log` | **5776 lolos, 0 gagal**, 0 baris `SCRIPT ERROR`/`ERROR`/`GAGAL`/`WARNING` |
| `python3 tools/cek_keluaran_tes.py --ketat build/tests.log` | `pemeriksa: lolos (5776 lolos, 0 gagal, 0 peringatan)`, exit 0 |
| `tools/tests_cek/uji_pemeriksa.py` / `uji_bangun_frames.py` / `uji_sintesis_sepeda.py` | 16 kasus 0 menyimpang / 41 lolos 0 gagal / 32 lolos 0 gagal |
| `godot --headless --path . --quit-after 2` | exit 0, keluaran hanya baris versi |
| `--export-pack "Android" build/kring-uji.pck` | exit 0, tanpa `ERROR`/`WARNING`; 280 jalur terbaca dari PCK (`strings`), 0 jalur `tests/`, `docs/`, atau `probe`; `throw_solver`, `zona_sasaran`, `sisa_koran`, `koran_lempar`, `garis_bidik`, `koran_gambar`, `zona_gambar`, `deret_koran` ada |
| `git status --porcelain` akhir klon | kosong |
| Kebersihan diff `main...HEAD` | tidak ada keystore/APK/PCK/`.godot/`/`build/`/`builds/`/secret; 15 commit, semua `<tipe>: <ringkasan>` bahasa Indonesia; `main` tidak berubah (`b66034a` = merge-base); tidak ada push. `ROADMAP.md`/`GDD`/`TECH_PLAN` hanya disentuh commit orchestrator `9405c45`; `DEV_PHASES.md` tidak disentuh. `.uid` untuk semua skrip baru ada |

### Kepatuhan SPEC (ringkas)

- AC-2, AC-3: `tes_lempar.gd` (`_test_swipe_lebar`, `_test_rumus`, `_test_masukan_aneh_dan_murni`, `_test_titik_lepas`, `_test_iso_tinggi`, `_test_lengkung`) — dibaca dan dibuktikan mutan Q01-Q05, Q29.
- AC-4: satu panggilan `JalanUji.lintasan_swipe` → `ThrowSolver.dari_swipe` untuk garis bidik (sesudah `SepedaUji.gerak`) dan lemparan; lintasan dibekukan di `KoranLempar.Koran`; titik garis bidik = sampel `posisi_pada` (Q19 mati); penjaga teks rumus `_test_penjaga_rumus`. **Celah: QA-001** (posisi lepas jari ≠ posisi swipe garis bidik yang tampil).
- AC-5 (D-6, D-7): klasifikasi, tepi min inklusif/maks eksklusif (Q07, Q08 mati), prioritas, kavling tetangga (Q09), bukan pelanggan (Q10), sakelar jendela lewat parameter dan bawaan `JENDELA_KENA_BONUS: bool = false` dengan komentar "KEPUTUSAN TERBUKA" di `config.gd` dan "Masih terbuka" di BALANCING 5 (tidak diputuskan diam-diam). Sisi dekat: komentar `config.gd`, `zona_gambar.gd`, BALANCING 5 menyatakan hanya placeholder dan tidak memutuskan ROADMAP 5. Keterjangkauan dites (`_test_keterjangkauan`).
- AC-6 (D-8, D-9): `SisaKoran` + tes murni dan scene; jeda 0,35 inklusif (`LEMPAR_JEDA_DETIK` 0.35 = BALANCING 4), isi ulang hanya bila habis (Q11, Q32 mati), dua lempar cepat dan `koran_lepas` sekali (Q15 mati).
- AC-7 (D-11): koran memakai `dt` efektif (Q13 mati), garis bidik disembunyikan saat jeda (Q20 mati), lemparan di antara jari dilepas dan frame lepas tetap terbang (`_test_jeda_sebelum_lepas`), TOMBOL/PAUSED/FOCUS_OUT.
- AC-8: `_test_input_dan_kidal` (dua jari, kidal, panel HUD di zona swipe, tegak, batal). HUD tidak bisa menangkap sentuhan karena `KontrolTouch` membaca di `_input` (sebelum GUI) dan semua node panel `mouse_filter = 2`.
- AC-9: HUD koran di `HBoxContainer` (anchor + Container), warna hanya `Palette` (0 hex/`Color(` literal baru di skrip/scene), kunci `HUD_KORAN`, `HUD_KORAN_ANGKA`, `HUD_KORAN_HABIS` di `ui.csv` + `ui.id.translation`; tata letak 640/780/800 di `tes_tata_letak.gd`. Kabel gambar penanda/ikon: QA-003.
- AC-11: tab, static typing, `##` Indonesia; `kiri`/`kanan` hanya untuk sumbu layar (komentar swipe, `kiri_atas`), tidak untuk sisi jalan; angka baru semua di `config.gd` satu baris literal; Q12 (angka literal 640.0 di jalan_uji) dibunuh penjaga angka ajaib.
- AC-13: P-1/P-2/P-3 ada; mutan QA Q25 (urutan pembulatan di `titik_gambar`) hidup tetapi setara selama transform global induk bilangan bulat (posisi sepeda dibulatkan), jadi tidak dihitung temuan.
- AC-14: BALANCING 4, 5, 10, DESIGN_SPEC 3.5/3.6/3.7 (tafsiran usulan), ART_DIRECTION 6.2, SETUP_ANDROID 8.3, AGENTS.md, `00-project-core.mdc`, README ada. Sisa kalimat lama: QA-002.
- Tes lama yang dihapus: hanya dua cek `tes_sprite.gd` "lempar saat sedang melempar diabaikan" (sah karena D-9, diganti `_test_loper_sprite_lempar_menyela`); cek `sisi_dari_swipe` lama dipindah ke `ThrowSolver` dengan angka baru (6 cek bentuk lama masih ada: selisih saja, vektor nol, NaN, INF, sangat panjang, tegak); cek 12 px diganti 46/46,8 px. Tidak ada tes di-skip.

### Mutan QA (milik QA sendiri, di klon bersih, satu mutan per run penuh, berkas dipulihkan; `git status` klon kosong sesudahnya)

32 mutan: **25 mati, 7 hidup** (2 setara, 5 = QA-003). 0 mutan menyebabkan import gagal.

| Mutan | Hasil | Contoh cek yang membunuh |
|---|---|---|
| Q01 lateral titik lepas berlawanan arah (`ARAH_SEBERANG.x`) | mati, 3 gagal | "titik lepas = posisi + (maju, lateral) x jeda lepas" |
| Q02 tanah bergerak tak linear (`lerp(..., s*s)`) | mati, 3 | "u 0.0: tengah waktu = tengah jalur tanah" |
| Q03 u dibagi `maks` saja | mati, 140 | "tengah min-maks = u 0,5" |
| Q04 titik mendarat dari posisi sepeda, bukan titik lepas | mati, 1 | "geser lateral selama terbang tetap tepat jarak samping" |
| Q05 tanda tinggi z terbalik di `Iso` | mati, 2 | "1 ubin = 32 px ke atas" |
| Q06 penilaian mendarat selalu sakelar bonus | mati, 3 | "SEBERANG JENDELA: mendarat ... penanda SILANG" |
| Q07 / Q08 tepi min lateral / maju eksklusif | mati, 1 / 2 | "tepi min lateral dan maju (pojok min) inklusif" |
| Q09 zona sekitar tanpa kavling tetangga | mati, 2 | "titik halaman kavling 5 yang menjorok ke kavling 4 tetap HALAMAN" |
| Q10 `%` bukan `posmod` (nomor negatif) | mati, 2 | "nomor bukan pelanggan berulang, juga untuk nomor negatif" |
| Q11 isi ulang `>` bukan `>=` | mati, 1 | "16 ubin sesudah habis: penuh lagi" |
| Q12 lebar viewport tetap 640 di `lintasan_swipe` | mati, 7 | "swipe 46 px (di bawah ambang 46,8 = 6% dari 780) tidak melempar" + penjaga angka ajaib |
| Q13 langkah pertama sesudah lanjut memakai `dt` mentah untuk koran | mati, 3 | "TOMBOL: langkah pertama sesudah lanjut ber-dt 0" |
| Q14 `lateral_ud` dari stick, bukan lateral efektif | mati, 1 | "di tepi jalan (terhalang) kecepatan lateral efektif 0" |
| Q15 lempar disela tanpa `koran_lepas` tertunda | mati, 4 | "lempar pertama yang disela: koran_lepas (seberang) dan lempar_selesai sekali" |
| **Q16 node penanda selalu CENTANG** | **HIDUP** | (QA-003) |
| Q17 warna penanda selalu `OK` | mati, 3 | "SEBERANG MELESET: warna penanda FAIL" |
| **Q18 bayangan di posisi udara** | **HIDUP** | (QA-003) |
| Q19 titik garis bidik `floor` bukan `round` | mati, 4 | "30 titik garis bidik = proyeksi ThrowSolver.posisi_pada" |
| Q20 garis bidik tidak disembunyikan saat jeda | mati, 1 | "jeda: garis bidik hilang" |
| Q21 `_jeda or` dihapus di `_saat_swipe_selesai` | hidup, **setara**: jeda membatalkan semua jari lewat `batal_semua` (tanpa `swipe_selesai`) dan input berhenti saat pohon dijeda | — |
| Q22 koran tidak berputar | mati, 1 | "frame putar 12 fps, 4 langkah berulang" |
| **Q23 rumah bukan pelanggan tidak ditandai di gambar** | **HIDUP** | (QA-003) |
| **Q24 `ZonaGambar.perbarui(0.0)`** | **HIDUP** | (QA-003) |
| Q25 `titik_gambar` membulatkan sesudah transform saja | hidup, setara selama transform induk bulat | — |
| Q26 label HABIS tidak pernah tampil | mati, 1 | "habis: ... penanda HABIS tampil" |
| **Q27 ikon HUD tidak pernah redup** | **HIDUP** | (QA-003) |
| Q28 `ikon_hud` semua terang bila sisa > 0 | mati, 2 | "sisa 4: angka 4, 4 dari 8 ikon terang" |
| Q29 tepat 45 derajat melempar | mati, 1 | "tepat 45 derajat ... ambigu: tidak melempar" |
| Q30 sinyal `koran_mendarat` tidak dipancarkan | mati, 41 (+4 SCRIPT ERROR) | "TOMBOL: sesudah lanjut koran mendarat di titik prediksi" |
| Q31 `KoranLempar.posisi` sesudah mendarat lewat `posisi_sejak_jari` | mati, 1 | "skenario A dt 1/240: titik mendarat koran = titik akhir garis bidik" (presisi) |
| Q32 HUD koran tidak diperbarui di `perbarui` (isi ulang) | mati, 1 | "16,001 ubin sesudah habis: terisi ulang 30, HUD kembali" |

Repro tambahan QA-001: skrip SceneTree sementara (`tests/qa_repro_lepas.gd` di klon kedua, tidak di-commit) — keluaran `garis bidik tampil: mendarat (-2.632626, -2.56053), lemparan: mendarat (-3.096817, -2.679893), selisih 0.47929203510284 ubin`.

### Validasi visual (dijalankan QA sendiri, non-headless, jendela asli)

- `godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_koran_jendela.gd -- docs/loop/20261014-fase2a-lemparan/shots/iter1-qa` dan `--resolution 1920x1080`: exit 0, 0 `ERROR`/`WARNING`; satu baris `PERINGATAN: layar jeda terbuka (jendela kehilangan fokus)` (probe melanjutkan sendiri). Tujuh sasaran dikenai di tiap lebar, hasil = diharapkan, titik = prediksi. 36 tangkapan di `shots/iter1-qa/`.
- `python3 tools/cek_blok_piksel.py 3 --kecualikan <kotak teks HUD dari probe>`: 36 dari 36 tangkapan 0 blok tidak seragam.
- Dilihat sendiri (Read, sebagian diperbesar 3×): garis bidik titik putih melengkung dan berakhir di elips (santai seberang dan kidal jelas melengkung; panjang ke seberang saat ngebut hampir lurus tegak karena arah tanah tegak di layar); elips sah = elips hijau **terisi** bergaris luar, elips biasa = cincin putih; koran 8×6 di puncak di atas kotak surat, bayangan di aspal sangat samar (QA-007); penanda centang (kotak surat, teras, kotak surat dekat), belah ketupat setengah (halaman), silang merah kecil (meleset, jendela penalti, bukan pelanggan) — bentuk berbeda, tidak hanya warna; tanda lingkaran bergaris miring dan teras abu di rumah bukan pelanggan; HUD KORAN 30/29/26/24, HABIS merah + angka 0 + ikon redup, terisi ulang 30; kidal: panel koran dan kecepatan dicerminkan, swipe kiri layar = seberang; elips di atas atap/dinding saat mendarat di belakang fasad (QA-004).
- Tidak bisa diuji di sini: rasa swipe, keterbacaan di layar HP ×3 sungguhan, 60 fps, background/notifikasi Android asli, viewport 800 di jendela asli (2400×1080 tidak muat monitor; 800 hanya lewat tes tata letak headless). QA tidak menyentuh HP.

### Ringkasan untuk orchestrator

**FAIL** — Blocker 0, Major 1 (QA-001 OPEN), Minor 4 (QA-002, QA-003, QA-004 OPEN; QA-007 NEEDS-MANUAL), Nit 2 (QA-005, QA-006 dicatat). Gerbang objektif semua hijau.

## Catatan Dev iterasi 2

Iterasi 2 dari 2 (Dev): hanya temuan di LOG (QA-001 sampai QA-007). Tidak push; tidak ada commit di `main`. Status per temuan ada di tabel Temuan (FIXED; kolom QA dan status run tidak diisi Dev).

### Commit

| Commit | Ringkasan | Temuan |
|---|---|---|
| `09bc6ff` | fix: lemparan memakai lintasan garis bidik terakhir yang tampil | QA-001 |
| `6e246cf` | docs: selaraskan aturan animasi lempar di BALANCING 2 dengan D-9 | QA-002 |
| `8c5bfa9` | test: kabel gambar node lewat perintah gambar yang dites headless dan simpanan pola piksel | QA-003, QA-006 |
| `270390e` | fix: elips dan ujung garis bidik yang tertutup rumah digambar putus-putus redup | QA-004 |
| `77556ce` | tune: bayangan koran lebih pekat dan lebar supaya terbaca di aspal | QA-007 |
| `109d3a5` | fix: jari yang ditarik kembali atau tegak saat diangkat membatalkan lemparan | QA-001 (lanjutan, lihat bawah) |
| `65bc4ed` | test: probe koran mencetak bentuk elips dan tangkapan layar iterasi 2 | AC-12 (tangkapan ulang) |
| (commit terakhir, lihat `git log`) | docs: catatan Dev iterasi 2 run 2A | LOG ini, QA-005 |

### QA-001: pilihan perbaikan dan perilaku

- **Dipilih: lemparan memakai OBJEK lintasan garis bidik yang sedang tampil** (`JalanUji.lintasan_bidik_tampil`), bukan menghitung ulang. Alasan: jaminan struktural paling kuat; yang dilempar adalah objek yang sama yang digambar (`garis.lintasan()`), jadi tidak ada argumen, posisi jari, atau keadaan sepeda yang bisa berbeda. Alternatif "bekukan posisi jari saat langkah terakhir lalu hitung ulang" tetap memanggil `ThrowSolver` dua kali dan bergantung pada keadaan yang sama (lebih mudah rusak diam-diam). Lintasan beku itu dihitung pada langkah terakhir sesudah `SepedaUji.gerak`, dan jari dilepas datang di `_input` sebelum langkah berikutnya, jadi keadaan sepeda sama dengan yang dipakai lemparan sebelumnya (D-4 tidak berubah).
- **Swipe tanpa garis bidik tampil** untuk swipe itu (turun dan naik di antara dua langkah; atau langkah terakhir menolak swipe karena masih di bawah 6% atau tegak): dihitung dari posisi lepas dengan `lintasan_swipe` yang sama dan keadaan sepeda langkah terakhir. Tidak ada prediksi yang tampil, jadi tidak ada yang bisa berbeda; prediksi yang AKAN tampil pada keadaan itu = lintasan yang dilempar (dites `_test_swipe_tanpa_garis_bidik`). Swipe semacam ini realistis di HP: input sentuh dikumpulkan per frame, jadi flick sekitar 30 ms bisa turun dan naik dalam dua frame tanpa garis bidik sempat digambar; menelannya akan terasa seperti swipe hilang.
- **Posisi lepas tetap harus melempar sendiri** (`109d3a5`): jari yang ditarik kembali di bawah 6% atau berbelok dominan tegak saat diangkat membatalkan lemparan walau garis bidik masih tampil (tidak ada koran, jadi prediksi = hasil tetap terjaga). Ditemukan saat menjalankan ulang probe jendela: pembantu probe `_lepas_swipe_tanpa_lempar` menggeser jari ke titik awal lalu mengangkatnya tanpa langkah di antaranya, dan versi `09bc6ff` tetap melempar garis bidik yang tampil (tangkapan `bidik_panjang_seberang_ngebut` kehilangan garis bidiknya karena jeda 0,35). Gerak "tarik kembali untuk batal" lebih wajar daripada "yang terlihat selalu terlempar". Flick yang memanjang atau bergeser (posisi lepas tetap melempar) tetap memakai garis bidik yang tampil.
- **Garis bidik basi**: garis bidik swipe yang dibatalkan sistem (atau kidal berganti) masih tergambar sampai langkah berikutnya; swipe baru yang selesai sebelum langkah itu tidak boleh memakainya. `TouchRouter.nomor_swipe` naik tiap jari mengklaim slot swipe; `JalanUji` mencatat nomor swipe garis bidik yang tampil dan hanya memakainya untuk nomor yang sama.

### QA-003: keputusan gambar sebagai perintah

`GambarPiksel` kini membuat perintah `[rentang: Array[Vector3i], asal: Vector2, warna: Color]` (`perintah_pola`, `perintah_rentang`) dan menjalankannya (`gambar`). Tiap node menyusun perintahnya lewat fungsi yang bisa dipanggil tes; `_draw` hanya `GambarPiksel.gambar(self, perintah_tampil())`. Tes membandingkan perintah node dengan harapan yang ditulis eksplisit (pola penanda per bentuk dipetakan di tes, bukan lewat `PolaPiksel.pola_penanda`; letak bayangan dari titik tanah dihitung di tes). Sisa risiko yang tidak dites headless: `_draw` yang tidak memanggil `gambar` sama sekali (rendering tidak bisa dibaca headless); dilihat lewat tangkapan probe. Titik garis bidik tetap `draw_rect` langsung di `_draw` (tanpa alokasi per frame), warnanya dari `GarisBidik.warna_titik(i)` yang dites.

### QA-004: aturan "tertutup rumah"

Titik (x, y, z) dan (x + d, y + d, z + d) jatuh di titik layar yang sama (`Iso`: x − y tetap, (x + y)·16 − 32z tetap), dan yang kedua lebih dekat ke kamera bila d > 0. Jadi titik tertutup kotak rumah bila ada d ≥ 0 dengan (x + d, y + d) di tapak dan z + d ≤ tinggi kotak (`ZonaSasaran.tertutup_kotak`; irisan selang d harus terbuka, jadi titik tepat di tepi tidak tertutup). Tapak = lateral −5..−3 (kaki fasad −3, dalam 2 ubin), maju dari titik pijak sepanjang 3 ubin, tinggi 1,5 ubin (48 px), sama dengan `tools/env_art/graybox.py` dan dijaga tes terhadap ukuran PNG. Zona di kaki fasad (lateral ≥ −3) tidak pernah tertutup (dites semua zona). Elips: `SAH` didahulukan, lalu `TERTUTUP`, lalu `BIASA`. Garis bidik tetap digambar di atas objek (tidak ada Y-sort per titik); putus-putus + redup adalah konvensi "di balik objek". Titik garis bidik yang tinggi di depan fasad (di atas halaman) tetap terang dan memang benar digambar di atas dinding karena koran di depan dinding.

### Tes lama yang diubah

- `tes_lempar.gd`: label cek bayangan memakai angka `Config` (bukan teks "8 px ... 4 px").
- `tes_koran_scene.gd`: pembantu `_bidik_ke` kini memanggil `_bidik_sampai` (syarat lintasan apa pun); isi cek lama tidak berubah, ditambah cek kabel gambar.
- `tests/probe_koran_jendela.gd`: hanya keluaran cetak ditambah bentuk elips.
- Tidak ada cek yang dihapus atau dilewati.

### Mutan nyata iterasi 2 (kode dikembalikan sesudah tiap mutan; skrip penggantian di scratchpad, `run_tests` penuh per mutan)

**34 mutan, 33 mati, 1 hidup (setara).** F = QA-001 (pada kode `109d3a5`), Q/G/C = QA-003/QA-006 (kode `8c5bfa9`), T = QA-004 (kode `270390e`), B = QA-007 (kode `77556ce`).

| Mutan | Hasil | Tes yang membunuh (contoh label) |
|---|---|---|
| F1 lemparan dihitung ulang dari posisi lepas (bug lama QA-001) | mati, 6 gagal | "flick dt 1/30: titik mendarat koran (-3.251547, -9.400796, 0.0) = titik akhir garis bidik terakhir yang tampil (-2.632626, -9.082494, 0.0)" (selisih ≈ 0,62 ubin, sama jenisnya dengan repro QA) |
| F2 nomor swipe garis bidik tidak dicek (garis bidik basi dipakai) | mati, 1 | "swipe baru sebelum langkah berikutnya: dihitung dari posisinya sendiri (dekat), bukan garis bidik basi ..." |
| F3 tanpa garis bidik tampil tidak melempar | mati, 97 (+5 SCRIPT ERROR) | "swipe satu frame: melempar ..." dan tes animasi lama |
| F4 nomor swipe garis bidik tidak dicatat | mati, 6 | "flick dt 1/30: lintasan lemparan = objek lintasan garis bidik yang tampil" |
| F5 `TouchRouter` tidak menaikkan nomor swipe | mati, 1 | "swipe baru sebelum langkah berikutnya ..." |
| F6 garis bidik dibaca sesudah disembunyikan | mati, 6 | "flick dt 1/30: lintasan lemparan = objek lintasan garis bidik yang tampil" |
| F7 posisi lepas tidak dicek bila garis bidik tampil | mati, 4 | "di bawah 6%: jari diangkat tanpa langkah di antaranya: batal, koran tetap 30" |
| Q16 penanda selalu CENTANG | mati, 7 | "SEBERANG HALAMAN: node UDARA menggambar penanda SETENGAH warna OK" |
| Q18 bayangan di posisi udara | mati, 1 | "tiap langkah terbang: node TANAH menggambar bayangan elips OUTLINE di titik TANAH koran" |
| Q23 rumah bukan pelanggan tidak ditandai di gambar | mati, 1 | "node zona: kavling bukan pelanggan (RADAR_BUKAN, tanda bentuk) tepat untuk rumah bukan pelanggan [10, 14, 18]" |
| Q24 `ZonaGambar.perbarui(0.0)` | mati, 2 | "zona ikut jarak sepeda: kavling pertama -3 (dari -3) = JalanDaur.indeks_pertama(53,7) 10" |
| Q27 ikon HUD tidak pernah redup | mati, 2 | "sisa 4: gambar deret = 4 ikon alpha 1 lalu 4 ikon redup alpha 0,28" |
| G1 deret memakai alpha 1 langsung (melewati `alpha_ikon`) | mati, 2 | sama dengan Q27 |
| G2 penanda tanpa geser di atas titik mendarat | mati, 12 | "SEBERANG TERAS: node UDARA menggambar penanda CENTANG ..." |
| G3 lebar bayangan tetap (tidak dari tinggi) | mati, 1 | sama dengan Q18 |
| G4 koran di udara tidak berputar di gambar | mati, 1 | "tiap langkah terbang: node UDARA menggambar koran berputar di posisi udaranya" |
| G5 zona tanpa geser kavling | mati, 1 | "node zona: perintah gambar tiap kavling digeser ke letak kavling itu" |
| C1 simpanan pola memakai ukuran sebagai kunci | mati, 1 | "simpanan rentang pola: isi pola sama = objek yang sama ..." |
| C2 simpanan tidak pernah dipakai | mati, 1 | sama dengan C1 |
| T1 elips tidak pernah TERTUTUP | mati, 3 | "lempar maks ke seberang dari tengah jalan mendarat di dalam rumah: meleset, elips TERTUTUP (-5.0, -7.0)" |
| T2 tinggi titik diabaikan | mati, 2 | "di atas atap (lebih tinggi dari kotak) ...: tertutup false" |
| T3 hanya di dalam tapak (tanpa bayangan di balik kotak) | mati, 8 | "di atas atap ..." + penjaga angka literal |
| T4 arah geser d terbalik di lateral | mati, 8 | "di depan fasad (halaman) ...: tertutup false" |
| T5 titik garis bidik tertutup tidak redup | mati, 1 | "titik ujung garis bidik di balik rumah: redup" |
| T6 elips tertutup digambar cincin biasa | mati, 1 | "node garis bidik menggambar cincin putus-putus TEXT redup (alpha 0.5)" |
| T7 hanya kavling tengah yang dicek | mati, 1 | "jalan uji: di dalam rumah kavling 2 dan kavling 1 (maju 3,7, dekat batas kavling) ..." |
| T8 tapak di depan kaki fasad | mati, 5 | "semua zona sasaran jalan uji ... tidak tertutup rumah" |
| T9 tepi tertutup inklusif | mati, 2 | "tepat di kaki fasad (tepi tidak tertutup) ..." |
| **T10 `SAH` tidak didahulukan (tertutup dicek dulu)** | **hidup, setara** | Tidak ada zona sasaran yang tertutup (dites: semua zona jalan uji tidak tertutup), jadi lintasan sah tidak pernah tertutup dan urutan tidak berpengaruh dengan data sekarang. Urutan dipertahankan untuk zona masa depan. |
| T11 tinggi titik garis bidik diabaikan (pakai 0) | mati, 1 (sesudah cek ditambah) | "titik garis bidik yang tinggi (di atas garis atap dari kamera) tetap terlihat walau titik tanahnya tertutup" |
| T12 `JalanUji` memberi bentuk dari sah saja | mati, 2 | "elips tertutup rumah: bentuk TERTUTUP, bukan sah" |
| B1 alpha bayangan kembali 0,5 | mati, 2 | "bayangan koran di atas aspal 6c6872: kontras 2.06:1 (>= 3:1)"; rumput 2,96:1 |
| B2 lebar bayangan minimum kembali 4 | mati, 1 | "bayangan koran di tanah lebih lebar dari koran 8 px, paling kecil 6 px" |
| B3 lebar maksimum bayangan 8 | mati, 1 | sama dengan B2 |

Mutan QA iterasi 1 Q16, Q18, Q23, Q24, Q27 dijalankan ulang di tempat keputusan itu sekarang berada (setara maknanya dengan mutan QA) dan semuanya **mati**.

### Probe jendela dan tangkapan layar (AC-12)

- `godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_koran_jendela.gd -- docs/loop/20261014-fase2a-lemparan/shots` dan `--resolution 1920x1080`: exit 0, 0 `ERROR`/`WARNING`; satu baris `PERINGATAN: layar jeda terbuka (jendela kehilangan fokus)` seperti iterasi 1. Tujuh sasaran dikenai di tiap lebar, "0 sasaran tidak ditemukan".
- Bentuk elips (dicetak probe): `bidik_panjang_seberang_ngebut` dan `kidal_bidik_seberang` = `TERTUTUP`; kotak surat, teras, halaman, kotak surat dekat = `SAH`; jendela, bukan pelanggan, meleset di trotoar, panjang dekat santai = `BIASA`.
- Tangkapan yang berubah dan di-commit (`65bc4ed`): 2340x1080 `bidik_panjang_seberang_ngebut`, `kidal_bidik_seberang`, `puncak_kotak_surat`, `puncak_dekat_kotak_surat_ngebut`; 1920x1080 sama ditambah `bidik_panjang_dekat_santai`, `bidik_dekat_kotak_surat_ngebut` (selisih kecil di sekitar sepeda; swipe kotak surat dekat ngebut kini |dx| 39 px karena urutan probe tidak lagi ikut melempar saat pindah sisi, lihat QA-001 lanjutan).
- Dilihat sendiri (Read, diperbesar 2×): elips di atap rumah kini cincin putus-putus redup dan tiga titik terakhir garis redup; titik garis yang di depan fasad tetap terang (koran di depan dinding); kidal: elips putus-putus redup di dinding samping; bayangan koran di puncak lengkung (aspal di samping sepeda) kini blok gelap yang jelas.
- `python3 tools/cek_blok_piksel.py 3 --kecualikan <kotak teks HUD dari probe>`: 36 dari 36 tangkapan 0 blok tidak seragam.

### Gerbang AC-1 (HEAD kode `65bc4ed`)

- `godot --headless --import`: exit 0, 0 `ERROR`/`SCRIPT ERROR`/`WARNING`.
- `godot --headless --script res://tests/run_tests.gd 2>&1 | tee build/tests.log`: **5899 lolos, 0 gagal** (iterasi 1: 5776); `python3 tools/cek_keluaran_tes.py --ketat build/tests.log`: lolos, 0 peringatan.
- `tools/tests_cek/uji_pemeriksa.py`: 16 kasus, 0 menyimpang; `uji_bangun_frames.py`: 41 lolos 0 gagal; `uji_sintesis_sepeda.py`: 32 lolos 0 gagal.
- `godot --headless --path . --quit-after 2`: exit 0, 0 `ERROR`/`WARNING`.
- `godot --headless --path . --export-pack "Android" build/kring-uji.pck`: exit 0, 0 `ERROR`/`WARNING`; `strings` PCK: 0 baris memuat `tests/`, `docs/`, atau `probe_`; `garis_bidik`, `gambar_piksel`, `koran_gambar` ada.
- Diff `main...HEAD`: tidak ada keystore/APK/AAB/PCK/`.godot/`/`build/`/`builds/`.
- Klon bersih (`git clone` repo lokal ke scratchpad, checkout `feat/fase2a-lemparan` = `65bc4ed`): import 0 `ERROR`/`WARNING`, 5899 lolos 0 gagal, `--ketat` lolos, `--quit-after 2` 0 `ERROR`/`WARNING`, `git status --porcelain` kosong.

### Catatan untuk QA

- QA-007: hanya bayangan yang diubah; ukuran koran dan penanda tetap (alasan di tabel). Keterbacaan di HP tetap di NEEDS-MANUAL.
- QA-001 mengubah satu kesepakatan kecil yang perlu dilihat pemilik: posisi lepas yang sendirian tidak melempar membatalkan lemparan walau garis bidik tampil (bukan "yang tampil selalu terlempar"). Dicatat di BALANCING 4 dan DESIGN_SPEC 3.7 sebagai usulan.
- Tidak ada BLOCKED, tidak ada DISPUTED.

## Catatan QA iterasi 2

QA memverifikasi semuanya sendiri, tanpa memakai klaim Dev. HEAD `fa3c601` (kode `65bc4ed`), Godot 4.7.2.stable.official.ed1daf0bf (`/opt/homebrew/bin/godot`). Semua perintah dijalankan di klon bersih (`git clone` repo lokal ke scratchpad, checkout `feat/fase2a-lemparan`).

### Gerbang

| Gerbang | Hasil |
|---|---|
| `godot --headless --import` | exit 0, 0 `ERROR`/`SCRIPT ERROR`/`WARNING`; `git status --porcelain` sesudahnya kosong |
| `run_tests.gd > build/tests.log 2>&1` | **5899 lolos, 0 gagal**, 0 baris `SCRIPT ERROR`/`ERROR:`/`GAGAL`/`WARNING` |
| `python3 tools/cek_keluaran_tes.py --ketat build/tests.log` | `pemeriksa: lolos (5899 lolos, 0 gagal, 0 peringatan)`, exit 0 |
| `uji_pemeriksa.py` / `uji_bangun_frames.py` / `uji_sintesis_sepeda.py` | 16 kasus, 0 menyimpang / 41 lolos, 0 gagal / 32 lolos, 0 gagal |
| `godot --headless --path . --quit-after 2` | exit 0, keluarannya hanya baris versi |
| `--export-pack "Android" build/kring-uji.pck` | exit 0, 0 `ERROR`/`WARNING`; 0 jalur `tests/`, `docs/`, atau `probe` di PCK (`strings`); `scenes/dev` hanya `jalan_uji`, `graybox`, `rumah_graybox`, `kotak_surat_graybox` (tanpa `cek_render`); `garis_bidik`, `gambar_piksel`, `koran_gambar`, `throw_solver` ada |
| Kebersihan diff `main...HEAD` | 132 berkas (HEAD `fa3c601`), tanpa keystore/APK/AAB/PCK/`.godot/`/`build/`/`builds/`/secret. 25 commit, semua `<tipe>: <ringkasan>` bahasa Indonesia (tipe `feat`, `fix`, `docs`, `test`, `tune` sesuai `git-workflow`). `main` = merge-base `b66034a` (tidak ada commit di `main`), tidak ada push |
| Regresi tes | Baris tes yang dihapus di iterasi 2 hanya cetak probe, isi pembantu `_bidik_ke` yang dipindah ke `_bidik_sampai`, dan label cek bayangan lama (angka kini dari `Config`). Tidak ada cek yang dihapus atau di-skip. Tes iterasi 1 yang dihapus sudah dinilai QA iterasi 1 |
| `git status --porcelain` klon di akhir (sesudah semua mutan dan probe) | kosong, kecuali folder tangkapan `shots/iter2-qa/` yang sengaja dibuat probe |

### Verifikasi temuan iterasi 1

- **QA-001 → VERIFIED.** QA menjalankan skrip SceneTree sementara yang memakai pembantu `TesKoranScene` (tidak di-commit). (1) Repro iterasi 1 persis: 720 → 600, `perbarui(1/60)`, geser ke 570, angkat di 570. Garis bidik berakhir di (−2,632626, −2,613089), koran mendarat di (−2,632626, −2,613089), **selisih 0,00000000 ubin** (iterasi 1: 0,479). (2) Swipe sangat cepat dalam satu frame (turun, dua kali geser, angkat tanpa `perbarui`): garis bidik tidak pernah tampil, koran tetap terlempar dan mendarat tepat di `lintasan_swipe(awal, lepas)`. (3) Flick yang memendek tetapi masih ≥ 6%: yang terlempar adalah garis panjang yang tampil. (4) Flick yang menyeberang titik awal: lihat QA-009 (Nit). Mutan bug lama R1 (lemparan dihitung ulang dari posisi lepas) **mati**, 6 gagal ("flick dt 1/30: lintasan lemparan = objek lintasan garis bidik yang tampil"); varian R2 juga mati, 6 gagal. Garis bidik basi (N19) mati.
- **QA-002 → VERIFIED.** `grep -n "Swipe berikutnya diabaikan" docs/BALANCING.md` kosong (exit 1). BALANCING 2 kini memuat aturan D-9 yang sama dengan BALANCING 4.
- **QA-003 → VERIFIED.** Kelima mutan hidup iterasi 1 dijalankan ulang di tempat keputusannya sekarang berada, dan semuanya **mati**: Q16 (penanda selalu CENTANG) 7 gagal, Q18 (bayangan di posisi udara) 1, Q23 (bukan pelanggan tidak ditandai) 1, Q24 (`_zona.perbarui(0.0)`) 2, Q27 (ikon tidak pernah redup) 2. Celah satu tingkat di bawahnya (penerjemah `GambarPiksel` dipakai sebagai oracle) dicatat sebagai temuan baru QA-008.
- **QA-004 → VERIFIED.** Mutan N02–N09 mati (lihat tabel). Di tangkapan QA, `bidik_panjang_seberang_ngebut` menampilkan cincin putus-putus redup di atap dengan tiga titik ujung redup, dan `kidal_bidik_seberang` menampilkan cincin redup di dinding samping. Keluaran probe mencetak bentuk `TERTUTUP` untuk dua kasus itu.
- **QA-005 → VERIFIED.** Keluaran probe QA: `bidik_pendek_seberang_santai ... bentuk SAH`. Klaim di Catatan Dev 1b sudah dikoreksi.
- **QA-006 → VERIFIED.** `rentang_pola` menyimpan hasil per isi pola. Mutan N23 (simpanan tidak pernah diisi) mati.
- **QA-007 → VERIFIED (bagian terukur) + NEEDS-MANUAL.** `config.gd` (alpha 0,85, lebar 10 → 6 px) = BALANCING 4/10 = ART_DIRECTION 6.2. Di tangkapan `puncak_kotak_surat` yang diperbesar, bayangan terlihat sebagai blok gelap yang jelas di aspal, di samping sepeda. Koran gulung di puncak (bingkai tegak 3–4 px) tetap kecil, jadi keterbacaannya diuji di HP.

### Perilaku baru iterasi 2: batal saat jari diangkat (109d3a5)

- **Masih di dalam SPEC, bukan keputusan baru yang diam-diam.** D-2 menolak swipe dengan |dx| < 6% atau dominan tegak, dan swipe diukur dari titik awal ke titik lepas. Implementasi iterasi 1 juga sudah menolak posisi lepas semacam itu (lintasan dihitung dari posisi lepas). Hanya versi antara `09bc6ff` yang selalu melempar garis yang tampil. D-4 (prediksi = hasil) tetap terjaga karena batal berarti tidak ada koran. Aturan ini ditulis sebagai usulan di BALANCING 4, DESIGN_SPEC 3.7, dan Catatan Dev iterasi 2 ("perlu dilihat pemilik").
- **Dites dengan mutan.** N01 (aturan batal dibuang) mati, 4 gagal: "di bawah 6% / dominan tegak: jari diangkat tanpa langkah di antaranya: batal".
- **Celah kecil:** sisi posisi lepas tidak dicek (QA-009, Nit).
- **Risiko menelan swipe yang disengaja.** Dominan tegak dihitung dari seluruh swipe (awal → lepas), bukan segmen terakhir, jadi ujung yang melengkung hanya membatalkan bila total gerak tegak ≥ total gerak datar. Ini hanya bisa dinilai di HP, sehingga ditambahkan ke NEEDS-MANUAL.
- **Regresi QA-003/004/007:** nilai `Config` baru (`GARIS_BIDIK_TERTUTUP_ALPHA` 0,5, `JALAN_UJI_RUMAH_PANJANG/DALAM/TINGGI_UBIN` 3/2/1,5, bayangan) sama dengan BALANCING 4. Warna di diff iterasi 2 hanya `Palette` (0 hex atau `Color(` literal angka). `kiri`/`kanan` hanya muncul untuk sumbu layar di komentar. Elips tertutup berbeda **bentuk** (putus-putus), tidak hanya alpha. Penanda tetap centang, setengah, dan silang (dilihat).

### Mutan QA iterasi 2 (klon bersih, satu mutan per `run_tests` penuh, berkas dipulihkan, `git status` klon kosong sesudahnya)

**30 mutan: 24 mati, 6 hidup.** Empat yang hidup = QA-008. Dua lainnya adalah angka tampilan usulan dan tidak dijadikan temuan.

| Mutan | Hasil | Contoh cek yang membunuh |
|---|---|---|
| R1 bug QA-001: lintasan = `dari_lepas` | mati, 6 | "flick dt 1/30: lintasan lemparan = objek lintasan garis bidik yang tampil" |
| R2 garis bidik hanya dipakai bila kekuatan lepas sama | mati, 6 | sama |
| Q16 penanda selalu CENTANG | mati, 7 | "SEBERANG HALAMAN: node UDARA menggambar penanda SETENGAH warna OK" |
| Q18 bayangan di posisi udara | mati, 1 | "tiap langkah terbang: node TANAH menggambar bayangan elips OUTLINE di titik TANAH koran" |
| Q23 bukan pelanggan tidak ditandai | mati, 1 | "node zona: kavling bukan pelanggan ... [10, 14, 18]" |
| Q24 `_zona.perbarui(0.0)` | mati, 2 | "zona ikut jarak sepeda ..." |
| Q27 ikon tidak pernah redup | mati, 2 | "sisa 4: gambar deret = 4 ikon alpha 1 lalu 4 ikon redup" |
| N01 aturan batal dibuang | mati, 4 | "di bawah 6%: jari diangkat tanpa langkah di antaranya: batal" |
| N02 `tertutup_kotak` batas maju terbalik | mati, 2 | "jalan uji: di dalam rumah kavling 2 dan kavling 1 ..." |
| N03 kavling berikut tidak dicek | mati, 1 | sama |
| N04 tapak rumah setengah dalam | mati, 2 | "tapak rumah jalan uji: lateral -5..-3" + penjaga angka |
| N05 `bentuk_elips` dengan tinggi 1 ubin | mati, 1 | "lempar maks ke seberang ...: elips TERTUTUP" |
| N06 `tertutup_pada` selalu di titik mendarat | mati, 3 | "titik garis bidik: awal di tangan terlihat, ujung di dalam rumah tertutup" |
| N07 warna titik garis bidik terbalik | mati, 2 | "titik ujung garis bidik di balik rumah: redup" |
| N08 elips tertutup alpha 1 | mati, 1 | "node garis bidik menggambar cincin putus-putus TEXT redup" |
| N09 `titik_tertutup` terbalik | mati, 3 | "titik awal garis bidik (di tangan): terang" |
| N10 bayangan tanpa geser tegak | mati, 1 | "node TANAH menggambar bayangan ..." |
| N11 tinggi bayangan sepertiga lebar | mati, 2 | penjaga angka + kabel bayangan |
| N12 koran tergeletak frame 1 | mati, 8 | "node TANAH menggambar koran tergeletak di titik mendarat" |
| N13 alpha bayangan = `ZONA_GARIS_ALPHA` | mati, 1 | kabel bayangan |
| N14 zona digeser satu kavling | mati, 1 | "perintah gambar tiap kavling digeser ke letak kavling itu" |
| N15 `alpha_ikon` `<=` | mati, 2 | "sisa 4: gambar deret ..." |
| N19 nomor swipe tidak dibandingkan | mati, 1 | "swipe baru sebelum langkah berikutnya: ... bukan garis bidik basi" |
| N23 simpanan pola tidak diisi | mati, 1 | "simpanan rentang pola: isi pola sama = objek yang sama" |
| **N16 `warna.a *= alpha` dibuang** | **HIDUP** | (QA-008) |
| **N20 huruf `o` = warna utama** | **HIDUP** | (QA-008) |
| **N21 huruf `w` dilewati** | **HIDUP** | (QA-008) |
| **N22 alpha ditimpa 1** | **HIDUP** | (QA-008) |
| N17 `KORAN_BAYANGAN_ALPHA` 0,85 → 0,8 | hidup, diterima | Angka tampilan usulan: kontras tetap ≥ 3:1 sehingga tes kontras tidak gagal, dan tidak ada penjaga sinkron Config ↔ BALANCING untuk angka tampilan (konvensi repo). Sinkronnya dicek manual oleh QA: sama |
| N18 `GARIS_BIDIK_TERTUTUP_ALPHA` 0,5 → 0,6 | hidup, diterima | Alasan sama dengan N17 |
| (N03 percobaan pertama) | tidak diterapkan | Teks cocok di 2 tempat, lalu diulang dengan konteks dan dihitung sebagai N03 di atas |

### Validasi visual (QA sendiri, non-headless, jendela asli)

- `godot --path . --resolution 2340x1080 --position 0,0 --script res://tests/probe_koran_jendela.gd -- docs/loop/20261014-fase2a-lemparan/shots/iter2-qa`, lalu `--resolution 1920x1080`. Keduanya exit 0 dengan 0 `ERROR`/`WARNING`; satu baris `PERINGATAN: layar jeda terbuka (jendela kehilangan fokus)` (probe melanjutkan sendiri, sama seperti iterasi 1). Tujuh sasaran dikenai di tiap lebar, "0 sasaran tidak ditemukan". Hasil: 36 tangkapan di `shots/iter2-qa/`.
- `python3 tools/cek_blok_piksel.py 3 --kecualikan <kotak teks HUD/kidal yang dicetak probe>`: 36 dari 36 tangkapan, 0 blok tidak seragam.
- Dilihat sendiri (Read, sebagian diperbesar 2–4×):
  - `bidik_panjang_seberang_ngebut`: cincin putus-putus redup di atap dan titik ujung redup; titik di depan fasad tetap terang.
  - `kidal_bidik_seberang`: elips redup di dinding samping; panel koran dan kecepatan dicerminkan.
  - `puncak_kotak_surat`: koran gulung tegak kecil digambar di atas kotak surat; bayangannya blok gelap yang jelas di aspal.
  - `kena_halaman`: penanda belah ketupat setengah dan koran tergeletak.
  - `kena_meleset`: silang merah kecil di trotoar.
  - `hud_habis`: "HABIS 0" merah dan 8 ikon redup.
- Tidak bisa diuji di sini: rasa swipe dan aturan batal saat jari diangkat di jempol sungguhan, keterbacaan koran 8×6 dan penanda 7–9 px di layar HP ×3, 60 fps, background/notifikasi Android asli, dan viewport 800 di jendela asli (hanya lewat tes tata letak headless). QA tidak menyentuh HP.

### Ringkasan untuk orchestrator

**PASS.** Gerbang objektif semua hijau. Blocker 0, Major 0 terbuka (QA-001 VERIFIED). Minor: QA-002, QA-003, QA-004 VERIFIED; QA-007 VERIFIED (bagian terukur) + NEEDS-MANUAL; **QA-008 OPEN (Minor, boleh DEFERRED)**. Nit: QA-005, QA-006 VERIFIED; **QA-009 OPEN (Nit, dicatat)**. Daftar NEEDS-MANUAL diperbarui (aturan batal saat jari diangkat).
