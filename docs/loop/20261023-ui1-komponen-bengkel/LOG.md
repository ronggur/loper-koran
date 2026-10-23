# Loop Log — 20261023-ui1-komponen-bengkel
Scope: Run UI-1 — redesain UI langkah 1-2 (komponen + bengkel tata C)  ·  Branch: feat/ui1-komponen-bengkel  ·  Mulai: 2026-10-23  ·  Godot: 4.7.2.stable.official.ed1daf0bf

## Status: IN_PROGRESS   (iterasi saat ini: 1/2, Dev bagian A dan B selesai; bagian C berikutnya)

## Lingkungan (orchestrator, awal run)
- `main` = `origin/main` = `b99f5a9` (rilis 0.6.0; memuat PR #61, #62, #63). Branch dibuat dari sana.
- Godot 4.7.2 di `/opt/homebrew/bin/godot`; python3 dengan numpy 2.5.3 dan pillow 12.3.0; `cv2`/`sklearn` TIDAK terpasang (hanya dibutuhkan `latar_bengkel.py` membuat ulang latar; `--salin` hanya menyalin berkas jadi tidak perlu).
- `adb devices`: tidak ada perangkat tersambung (vivo/A54 belum dicolok). Pemasangan APK menunggu perangkat tersambung dan QA PASS.
- sha256 save asli `Kring Kring!/save.json` awal run: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e`.
- `.claude/` untracked di working tree: bukan bagian run, tidak di-commit.

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 1 | (bagian A, B, C belum) | | | | |

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## Baseline (AC-1; diisi Dev bagian A langkah 1)
Diambil di pohon kerja yang belum berubah selain `docs/loop/` (HEAD `0b34f64`, setara `main` `b99f5a9`), 2026-10-23, satu proses Godot sekaligus.
- `godot --headless --import`: selesai tanpa error; `git status` bersih (selain `.claude/` yang tidak di-commit).
- `run_tests.gd`: **20371 lolos, 0 gagal**; `tools/cek_keluaran_tes.py build/tests.log`: lolos (20371 lolos, 0 gagal, 0 peringatan), exit 0.
- `godot --headless --path . --quit-after 2`: tanpa ERROR/WARNING.
- Semua `tools/tests_cek/uji_*.py` exit 0 (17 skrip): aset_fase3 148, aset_gelombang1 352, aset_kucing 13, aset_lampu_pohon 183, aset_pasang_5b 595, aset_pasang_gelombang1 565, aset_simpang 214, bangun_frames 62, pemeriksa 16 kasus 0 menyimpang, sintesis_kondisi 55, sintesis_lempar 111, sintesis_milestone 18, sintesis_misi 47, sintesis_rute 90, sintesis_sepeda 32, ui_lencana 25, ui_redesain LOLOS.
- sha256 save asli (`~/Library/Application Support/Godot/app_userdata/Kring Kring!/save.json`): `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e` (sama dengan awal run; diperiksa lagi sesudah probe jendela).
- Tangkapan "sebelum" untuk bukti piksel-identik (AC-4): `probe_hud_rute_jendela.gd` di 1920x1080 (10 PNG: HUD awal, radar, jeda dengan sakelar, layar hasil, kidal, dst.) disimpan di scratchpad `sebelum/`; dibandingkan dengan keluaran sesudah perubahan.

## Bagian A — komponen (Dev, iterasi 1; commit 4204b25, dc2e4c5, f3655ef)
**Set aset terpasang** (daftar tunggal `tools/ui_art/redesain/pasang.py`; diputuskan dari papan `Bengkel.dc.html`, `Bengkel_Tingkat.dc.html`, `Spesifikasi.dc.html`) di `assets/sprites/ui/`, 30 berkas + `.import`:
- Tombol: 8 bingkai `ui_btn_{utama,utama_tekan,biasa,biasa_tekan,sakelar_nyala,tenang,tenang_tekan,nonaktif}` + `ui_arsir_nonaktif` (sakelar mati memakai `btn_biasa`; kanvas tidak punya `btn_sakelar_tekan`, `btn_biasa_tekan` dipakai).
- Panel dan kartu: `ui_panel_layar`, `ui_kartu_{biasa,menonjol,redup}`; chip: `ui_chip_{gelap,ok,warn,netral,aksen}` (kelimanya dipakai kanvas bengkel). `panel_hud` TIDAK dipasang ulang (sudah ada `ui_panel_hud_9slice.png`).
- `ui_bengkel_papan_alat`, `ui_bengkel_sepeda_kecil.png` + `ui_bengkel_sepeda.json` (salinan byte `sepeda.json`), `ui_bengkel_latar_800.png`.
- Ikon 24 (potongan sel dari sheet `ikon24`, piksel sama): `ui_icon24_{ban,rem,rantai}` (hanya tiga yang dipakai kartu servis dan upgrade). Glif 12 (potongan sel `glif12` per warna): `ui_glif_{seru_warn,centang_ok,centang_teks2,kunci_terang,panah_gelap}` (kombinasi nyata di kanvas).
- TIDAK dipasang (tidak dipakai bengkel): `sepeda_besar` (kanvas hanya `sepeda_kecil`), `bengkel_latar_640` (lihat keputusan 2), koran_*, struk*, foto_*, lencana32, ikon dan glif lain, `kertas_tile`, `panel_hud`, `lembar_*`.

**Keputusan kecil Dev (usulan; bisa ditolak di review)**
1. Ikon 24 dan glif 12 dipasang sebagai PNG per sel (bukan sheet utuh) supaya "tidak ada aset redesain yang tidak dipakai di `assets/`" terpenuhi; piksel sama dengan sheet, dijaga `uji_ui_redesain.py`. Run layar lain menambah sel ke `pasang.py`.
2. Latar: hanya `ui_bengkel_latar_800.png`. Kanvas selalu memakai latar 800 dengan `bgx = (lebar - 800) / 2` (di 640 terpotong 80 px tiap sisi); versi 640 = potongan tengah versi 800 (diuji), jadi tidak dipakai. SPEC AC-2 menyebut "640/800"; menambah 640 cukup satu baris di `pasang.py` bila bagian B memerlukannya.
3. Variabel lingkungan tujuan `--salin` bernama `UI_ART_SALIN_KE` (folder tujuan langsung, bukan akar repo) dan sama untuk ketiga skrip.
4. `latar_bengkel.py` memuat `cv2`/`sklearn` hanya di `main()` saat membuat ulang; `--salin` hanya menyalin berkas resmi docs/ (jalan tanpa kedua pustaka).
5. Nonaktif diarsir: `ui_btn_nonaktif.png` sel tengah 4x4 (tepat sebesar ubin) diganti `ui_arsir_nonaktif.png` saat dimuat pertama kali (`GayaHud._tekstur_nonaktif_arsir`, dibangun sekali, mode ubin). CSS kanvas menaruh arsir di balik `border-image ... fill` yang opak sehingga arsir di kanvas hampir tidak tampak; di sini arsir terlihat di tengah bingkai (tepi 4/6 px tetap rata). Tidak ada PNG yang diedit tangan.
6. Fokus tombol: garis ACCENT 1 px lurus berjarak 1 px (kanvas putus-putus; Godot tidak punya garis putus-putus).
7. `GayaHud.tombol_*` juga mengatur `disabled` (false untuk empat peran, true untuk `tombol_nonaktif`) dan `theme_type_variation` (`TombolPeran` SemiBold 10 untuk utama/biasa/sakelar, `TombolTipis` Regular 10 untuk tenang/nonaktif); memanggil fungsi peran lain pada tombol yang sama memulihkan. Teks alasan ("Koin kurang") dipilih pemanggil lewat `KomponenUi.teks_tombol`.
8. Type variation baru di `theme.tres` (U-3): `LayarTeksUtama` 10, `LayarTeksKecil` 9 Regular, `LayarLabel` 8 (KAPITAL dan spasi 0,1 em dibuat pemanggil: tema tidak punya `text-transform`/`letter-spacing`), `LayarJudul` Lilita One 24, `ChipTeks` 10, `ChipTeksKecil` 8, `ChipTeksBesar` 12, `TombolPeran`, `TombolTipis`. Tanpa token Palette baru (semua warna komponen sudah ada: `UI_BG`, `TEXT`, `TEXT_2`, `ACCENT`, `WARN`, `OUTLINE`; `#FFE08A` hanya muncul di bilah progres dan aset, belum dipakai kode).
9. Kotak kondisi besar: kelas BARU `KotakKondisiBesar` (+ `TampilKondisiBesar` murni); `KotakKondisi` 14 px untuk HUD tidak disentuh. Tanda "!" memakai pola 3x9 `PolaPiksel.TANDA_SERU_KONDISI` (bukan glif 12) dan selalu disediakan ruangnya (33x9 total). Berongga = lubang `UI_BG` bergaris `TEXT_2` (versi HUD memakai `UI_PANEL_RAISED`).
10. Chip tingkat upgrade (I, II, III) dan format teks penanda sepeda ("! Ban", "Ban aus") bagian B; di sini hanya status -> gaya + glif + kunci teks (`KomponenUi.chip`).

**Tes baru:** `tests/tes_komponen_ui.gd` (+550 pemeriksaan, terdaftar di `run_tests.gd`): Config = meta.json, ukuran 18 tekstur terpasang, 4 peran x 3 keadaan tombol (tekstur, margin, warna, bobot, teks alasan), kartu (sapuan kondisi 0..1 per 0,01 + batas + NaN), chip (7 status, tanpa tabrakan gaya/glif/teks, kunci ada di `ui.csv`), wujud `GayaHud` (StyleBoxTexture, tepi 4/6/4/6, margin isi, sakelar, ganti peran), arsir, fungsi lama tak berubah, kotak kondisi besar (geometri, sapuan warna dan luminans, node), tema. `tools/tests_cek/uji_ui_redesain.py` bagian 7 (+16 pemeriksaan); langkah sudah terdaftar di job `alat` `tes.yml` (nama langkah diperbarui; tidak ada yang butuh Godot).

**Gerbang bagian A (Dev):** `godot --headless --import` tanpa error; `--quit-after 2` tanpa ERROR/WARNING; `run_tests.gd` **20921 lolos, 0 gagal** + `cek_keluaran_tes.py` lolos (baseline 20371); semua `uji_*.py` exit 0 (termasuk `uji_ui_redesain.py` LOLOS); sha256 save asli tetap `37d6d6cb...549e`.
**Bukti layar lama tidak berubah:** `probe_hud_rute_jendela.gd` 1920x1080, tangkapan sebelum (pohon `0b34f64`, worktree terpisah, dua kali) lawan sesudah (pohon ini, dua kali): layar hasil (2), jeda sakelar, kidal, progres campuran, tenggat hampir, tenggat lewat piksel-identik di semua pasangan. Tiga tangkapan lain bervariasi menurut fase animasi dari jam dinding, bukan UI: `hud_awal` (sesudah run 1 beda seluruh layar, sesudah run 2 identik dengan sebelum), `hud_bantu_abu` (beda 24x12 px bahkan antara dua run SEBELUM) dan `hud_radar` (beda hanya di kotak 10x23 game px = fase kayuh sprite pemain; HUD identik). Kesimpulan: tampilan HUD, hasil, jeda tidak berubah.
**Pemeriksaan visual komponen:** skrip sementara di scratchpad (bukan di repo) merender tombol enam peran, tiga kartu, enam chip, kotak kondisi besar (baik/aus/perlu/nol), glif, ikon, panel layar di 1920x1080: semuanya tampil seperti kanvas (nonaktif diarsir, kartu menonjol bergaris WARN, kotak berongga dan "!" terbaca).

## Perubahan tes lama (AC-8; setiap tes lama yang diubah dan alasannya)
Bagian A: tidak ada tes lama yang diubah (hanya `tests/run_tests.gd` menambah satu panggilan `TesKomponenUi`).
Bagian B:
- `tests/tes_bengkel_scene.gd` `_test_kondisi_baru` (satu `check`): `kartu.tingkat.text == "Baik"` untuk komponen penuh diganti `not kartu.tingkat.visible`. Alasan: di tata C komponen penuh tidak punya teks status kecil (kanvas keadaan a: kartu redup hanya bertanda chip "Baik"); chip itu dites `label_baik.visible and text == "Baik"` (baris yang sama, tidak diubah). Hanya tiga pemeriksaan (ban, rem, rantai) yang berubah; sisa 59 `check` di berkas itu (servis, upgrade, ketukan ganda, saldo tepat, galat data, empat lebar x inset, tiga alur hari, back, background, kidal) lolos tanpa perubahan lewat API yang dipertahankan (`tombol_servis`, `tombol_beli`, `tombol_hari_berikutnya`, `semua_tombol`, `kartu_servis(id).{tombol,label_baik,harga,tingkat,kotak,nama}`, `kartu_upgrade(id).{harga,nama,deskripsi,tombol,label_dimiliki,panel}`, `teks_*`, `rect_*`, `galat_tampil`, `ongkos_tampil`, `jumlah_upgrade_tampil`).
- `tests/run_tests.gd`: tiga panggilan baru (`TesTampilBengkel`, `TesBengkelTataC`); tidak ada perubahan lain.
- `tests/probe_bengkel_jendela.gd`: ditulis ulang (AC-10).
- `tests/tes_export.gd`: fungsi baru `_test_aset_ui1_ikut_paket` (AC-12), fungsi lama tidak diubah.
- `tests/tes_kondisi_scene.gd` dan `tests/tes_tata_letak.gd`: TIDAK diubah (pemindai sumber di `tes_kondisi_scene` bahwa bengkel tanpa mode bantu dan tanpa iklan tetap lolos untuk `layar_bengkel.gd` dan `bengkel.tscn` baru; `tes_tata_letak` hanya menyebut bengkel di komentar).
- `tools/tests_cek/uji_aset_pasang_5b.py` (baris 67): pola aset 5B yang tak dipasang `r'nyala'` dipersempit jadi `r'^prop_lampu_.*nyala'`. Alasan: pola lama (bingkai lampu nyala) salah menandai `ui_btn_sakelar_nyala.png` yang dipasang bagian A (uji itu GAGAL di HEAD bagian A, `aebfde0`; tertangkap di gerbang bagian B). Kontrol "bingkai nyala terdeteksi" tetap memakai nama lampu.

## Butir terbuka pemilik
- **Lisensi latar bengkel** (`docs/design/redesain/latar_bengkel/sumber_ai.jpg`): generator dan ketentuan lisensi komersial belum dicatat. Latar dipasang untuk uji HP (U-4) tapi TIDAK boleh masuk rilis sebelum dicatat (ART_DIRECTION 9).

## NEEDS-MANUAL (uji di HP)
- [ ] SETUP_ANDROID 8.18 (lihat SPEC): bengkel terbaca sekilas; sepeda dan chip kondisi jelas; tombol enak ditekan, tiga keadaan jelas bedanya; kartu menonjol vs redup; harga dekat tombol; latar tidak mengganggu teks; tiga upgrade tanpa scroll; 60 fps.

## Keputusan & catatan
- Putusan U-1..U-5 dan semua keputusan lama: lihat SPEC. Tidak ada keputusan terbuka yang menghambat saat SPEC ditulis; kalau tata C tidak muat di 640 untuk teks terpanjang, berhenti dan tanyakan SEKALI dengan satu rekomendasi.


## Bagian B — bengkel tata C (Dev, iterasi 1; commit 47c7fbd, bdd3732, f45880d, c9370b7, 2ff7173, 98115b8, e754afd, dan commit penutup bagian B)

### Tabel kerja angka dari kanvas (langkah 1)
Sumber: `Bengkel.dc.html` (`renderVals`), `ui.css`, `Spesifikasi.dc.html`, README redesain 4, `sepeda.json`. Semuanya jadi `Config.BENGKEL_*` / `UI_*` (pemindai "tanpa angka literal" di `scripts/ui|systems`), dijaga tes dengan oracle literal.

| Butir | Kanvas | Di game |
|---|---|---|
| Margin layar | 12 + inset | `ZonaAman.margin(12, inset)` = max (aturan satu-satunya proyek, lihat deviasi D-2) |
| Judul / isi mulai | judul y 11, isi y 46 | judul y 12 (margin), baris atas 34 tinggi => isi y 46 (`BENGKEL_BARIS_ATAS_PX`) |
| Kolom | 48 % | 8 | upgrade; 616 -> 296 | 312 | `TampilBengkel.lebar_kolom` (tes: 616, 592, 756, 776) |
| Panel servis | padding 4 + garis 4 = 8, jarak 4, baris judul 12, catatan 12 | sama |
| Kartu servis / upgrade | 50 / 62 (72 bila bertingkat), jarak 4 / 6, isi kiri 8 kanan 4, jarak isi 6 | sama |
| Chip | harga/Baik/Dimiliki 18, tingkat 14, saldo 24, jarak isi 3 (4 besar) | sama (`ChipUi`) |
| Tombol | 84 x 42, "Hari berikutnya" 140 x 42 kanan bawah | sama; `GayaHud.tombol_*` |
| Sepeda / papan / latar | 116x78 (`bx = sw/2 - 58`, `by = sh - 4 - 78`), papan 360x104 (`sw/2 - 180`, dasar), latar 800 di tengah (`(W-800)/2`, KEEP_CENTERED + klip) | `TampilBengkel.tata_panggung`, `PanggungSepeda`, `GambarLatar` |
| Titik chip | `titik_kecil` ban (5,68), rem (74,4), rantai (33,54); chip ban di depan titik (`x - w - 4`, min 2), rem `x + 5`, rantai `x - 10`, `y + 6`; lainnya `y - 7` | `BENGKEL_SEPEDA_TITIK` (= JSON, dites), `TampilBengkel.rect_chip` + jepit ke panggung |
| Hasil ukur (640, tanpa inset) | stage `sh` = 92 | panggung 280x92, panel servis 296x302, kolom upgrade 312 (cocok) |

Muat di 640 untuk teks terpanjang: ya, tidak BLOCKED. Ukur Godot (Lexend): "Stamina awet dan rantai lebih tahan" 160 px (9 px) membungkus 2 baris di kolom teks ~103; "Perlu servis" 45 px (8 px) tidak muat sebaris dengan tiga kotak + "!" (33 + 5 + 45 = 83 > 72) sehingga turun di bawah kotak (lihat keputusan 3); "125.480" di chip besar 46 px; "Koin kurang" 62 px di tombol 76 px dalam; "Hari berikutnya" 80 + 12 + 4 di 132 px dalam. Tidak ada teks yang dipotong di 640 sampai 800 (tes dan probe).

### Yang dibangun
- Logika murni `scripts/systems/tampil_bengkel.gd` (`TampilBengkel`, tes `tests/tes_tampil_bengkel.gd`): keadaan kartu servis (`servis(kondisi, harga, saldo)`: kartu menonjol/redup/biasa lewat `KomponenUi.kartu_servis`, penuh lewat `Economy.penuh`, status, chip penanda AUS/PERLU), `aksi/kunci_tombol` (AKTIF, KURANG bertulis "Koin kurang", TIDAK_ADA), `upgrade(...)` satu kartu per komponen (tingkat dijual, jejak DIMILIKI/AKTIF/MENUNGGU, tinggi 62 atau 72, chip tingkat), `kunci_tingkat` (I, II, III), `lebar_kolom`, `tata_panggung`, `rect_chip`, `rect_titik`. Perluasan `KomponenUi`: `warna_teks_chip`, `pad_y_chip`, `jarak_chip`.
- Node: `ChipUi` (chip 9-slice, status -> gaya + glif + teks), `PanggungSepeda` (panggung, papan, sepeda, titik, chip penanda; semua dari `TampilBengkel`), `GayaHud.chip_gaya`, `LayarBengkel` ditulis ulang (anchor + Container; tanpa hex; tekstur const preload; kartu servis dan upgrade dari komponen bagian A), `bengkel.tscn` baru, tema: `LayarLabel` berspasi huruf 1 px (FontVariation) dan `LayarTeksMini` (8 Regular).
- Kunci baru `ui.csv`: `BENGKEL_LABEL_SALDO`, `BENGKEL_PENANDA_PERLU` ("! {nama}"), `BENGKEL_PENANDA_AUS` ("{nama} aus"), `BENGKEL_TINGKAT_1/2/3` (I, II, III), `BENGKEL_TINGKAT_LAIN`; kunci lama tidak diubah; `.translation` hasil impor ikut di-commit.
- Config: blok `BENGKEL_*` lama (jarak, rasio kolom, lebar harga) diganti blok tata C; `UI_CHIP_PAD_Y_*`, `UI_CHIP_JARAK_*`. Konstanta Vector2i ditolak parser Config, jadi ukuran dan titik berupa int dan `Array[int]`.
- Perilaku tak berubah: sinyal, API tes, Economy, `HariMain` (tidak disentuh). Tombol nonaktif tetap dilindungi penolakan atomik `Economy` (tes: `pressed.emit()` dan `ditekan.emit()` pada nonaktif -> state identik). Back Android, simpan sekali, dan alur Hasil -> Bengkel -> Hari berikutnya dijaga tes lama (lolos).
- `tools/ukur_kontras_tangkapan.py` (baru): ukur kontras dari tangkapan nyata + JSON persegi dari probe.

### Keputusan kecil Dev bagian B (usulan; bisa ditolak)
1. **"Rect sepeda" untuk AC-9 = panggung sepeda** (papan + sepeda, 280x92 di 640), bukan sprite 116x78 saja: di kanvas chip ban/rem berada di LUAR sprite (di depan titik ban dan sesudah titik rem). Tes memeriksa chip di dalam panggung, titik 5x5 di dalam gambar sepeda, dan chip tidak saling menumpuk.
2. **Kartu servis BAIK-belum-penuh** (kondisi 0,70..0,999): redup (aturan bagian A `KomponenUi.kartu_servis`, "BAIK = redup") tetapi tetap membawa chip harga + tombol Servis dan status "Baik"; penuh = chip "Baik" tanpa tombol. Sepeda bersih untuk tingkat BAIK.
3. **Teks status turun di bawah kotak kondisi** bila kolom teks sempit (`HFlowContainer`), bukan membungkus huruf demi huruf di sebelahnya seperti kanvas: di 640 "Perlu servis" (45 px) tidak muat sebaris dengan kotak (33) dan harga + tombol (160). Ditemukan lewat tes `inset 36` (status 22 px lebar dibungkus 3 baris, kartu 60 > 50). Sebaris bila muat (lebar 800).
4. **Status "Perlu servis" dan pesan galat berwarna TEXT, bukan WARN** (kanvas `c-warn`): WARN di atas `UI_PANEL` hanya 6,91:1 (< 7:1, AC-9). Pembeda tetap: kartu bergaris WARN, "!" WARN di kotak kondisi, chip penanda WARN (7,79:1), glif "!" WARN.
5. **Chip jejak tingkat "menunggu" tidak diredupkan (opacity .55 di kanvas ditolak)**: teksnya 3,65:1 di tangkapan nyata. Dibedakan dari "dimiliki" (centang) dan "aktif" (gaya aksen).
6. **Pelat `HUD_PANEL` di belakang judul "UPGRADE"**: judul ini di atas latar, tepat di bawah lampu (selalu tertutup cahaya lampu di 640..800, ACCENT di atas cahaya tidak terbaca). Satu pelat 3 px per sisi, tanpa token baru.
7. **Model tampilan tingkat 2-3**: satu kartu per komponen dari `PemuatToko` (dikelompokkan per `komponen`, urut `level`); `kartu.data` = tingkat yang sedang tampil; `tombol_beli(id)` hanya untuk id yang sedang tampil; `kartu_upgrade(id)` untuk id tingkat mana pun komponen itu. Jejak I, II, III dan tinggi 72 hanya bila data punya > 1 tingkat (`upgrades.json` tidak berubah: tiga kartu tunggal 62; diuji dengan data uji lima upgrade).
8. **Chip tingkat di bawah ikon**: aksen bila dimiliki atau komponen bertingkat, netral selain itu (menyatukan kanvas Bengkel a/d dan Bengkel_Tingkat yang tidak konsisten).
9. **Tinggi chip** dipaksa 14/18/24 lewat jarak isi atas-bawah 2/2/3 (`UI_CHIP_PAD_Y_*`) karena baris teks Lexend 8/10/12 setinggi 10/13/15 (kanvas line-height 8/12/-).
10. **Anti-bug tata letak**: label berbungkus kata yang baru tampil menghitung tinggi dengan lebar 0; `Batas` lalu membesar dan Control MENYIMPAN ukuran itu di offsetnya (isi bergeser ke atas layar, tertangkap probe keadaan galat). `LayarBengkel._pulihkan_batas` menegakkan persegi penuh sesudah `isi()` (deferred) dan tiap `_susun()`; `_susun` juga dijaga `is_inside_tree()` (sinyal `size_changed` ke layar yang sudah dicabut). Tes keadaan f memeriksa tinggi isi.

### Deviasi dari SPEC/kanvas (untuk ditolak atau diterima)
- **D-1** AC-9 "kontras garis komponen >= 3:1": TIDAK terpenuhi oleh desain untuk bingkai kartu (1,14..1,78:1; garis luar `OUTLINE` gelap di atas latar gelap) dan tombol nonaktif (1,14:1; sengaja redup, rata, diarsir). Tombol aktif 8,53..13,48:1. Teks semua >= 7,79:1. Kartu dibedakan dari latar lewat isi, bukan garis. QA/pemilik memutuskan apakah garis kartu perlu diberi sorot (itu mengubah aset bagian A).
- **D-2** Margin dengan inset = `max(12, inset)` (aturan `ZonaAman.margin`, dipakai layar lain dan tes lama), bukan `12 + inset` seperti papan kanvas g (README: "12 + inset aman (max)", ambigu). Tes keadaan g memakai margin 36 kiri dan 20 bawah supaya angka kanvas (kolom 284 | 300, sepeda by = 2) teruji.
- **D-3** Judul "Bengkel" y 12 (margin), bukan 11.
- **D-4** Ring luar panggung 1 px digambar di luar panggung (seperti `box-shadow` kanvas) sehingga ukuran panggung (92) sama persis.
- **D-5** `rem` panggung sangat sempit (inset besar): panggung punya tinggi minimum 40; di bawah 78 sepeda terklip bawah (tidak diuji di perangkat nyata mana pun; chip dijepit ke dalam panggung).

### Gerbang bagian B
- `godot --headless --import` tanpa error; `--quit-after 2` tanpa ERROR/WARNING.
- `run_tests.gd` + `tools/cek_keluaran_tes.py`: **23003 lolos, 0 gagal, 0 peringatan** (baseline A 20921; +2082 pemeriksaan: `TesTampilBengkel` murni, `TesBengkelTataC` scene (kontras token, keadaan a-g, gaya tombol, tingkat I-III, enam jendela x inset), `_test_aset_ui1_ikut_paket`, `TesKomponenUi` tak berubah). Dua tes baru terdaftar di `run_tests.gd` sesudah `TesBengkelScene`.
- Semua 17 `tools/tests_cek/uji_*.py` exit 0 (setelah perbaikan `uji_aset_pasang_5b.py`).
- Paket `godot --headless --path . --export-pack "Android" build/kring-uji.pck`: seluruh 29 PNG UI yang dipasang + `ui_bengkel_sepeda.json` ada; tidak ada `ui_koran_`, `ui_struk`, `sepeda_besar`, `ui_foto_`, `lencana32`, `latar_640`, `ui_kertas_tile`, `ui_lembar`, `glif12`, `ikon24`; skrip `tampil_bengkel`, `chip_ui`, `panggung_sepeda` di paket.
- Bukti layar lain tak berubah: `probe_hud_rute_jendela.gd` 1920x1080, sebelum (pohon `aebfde0` di worktree, dua kali) lawan sesudah (pohon ini): sembilan dari sepuluh tangkapan piksel-identik (hasil, jeda sakelar, kidal, radar, bantu abu, progres, tenggat); `hud_awal` beda 322.556 piksel di dua run SEBELUM sendiri (fase animasi jam dinding, sama seperti catatan bagian A), jadi bukan UI.
- sha256 save asli: `37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e` (tidak berubah, sebelum dan sesudah probe/tes).

### Probe dan tangkapan (AC-10)
`tests/probe_bengkel_jendela.gd`: keadaan a-g, sesudah servis, tingkat I, II, dan III dimiliki (data uji), di 1920x1080 (lebar 640), 2340x1080 (780), 2400x1080 (800), dan 1600x720 (800); lebar 667 dan 700 hanya di tes scene (`2001x1080`, `2100x1080`). Lebar 800 diperoleh dari rasio 20:9 (2400x1080 dan 1600x720): viewport `canvas_items` + `expand` melebarkan viewport game sesuai rasio jendela, jadi tidak perlu trik. Hasil: 0 keadaan tidak sesuai di keempat ukuran (teks terpotong, tumpang tindih, tombol < 42 tinggi / < 84 lebar, chip di luar kartu atau panggung, kolom != `lebar_kolom`). Tangkapan: `docs/loop/20261023-ui1-komponen-bengkel/shots/iter1/<ukuran>_bengkel_<keadaan>.png` (+ `.json` persegi teks untuk pengukur kontras). Dibandingkan dengan kanvas: kolom 296 | 312, panggung 92 tinggi, kartu 50 / 62, chip "! Ban", "! Rem", "Rantai aus" di titik sepeda, kartu menonjol bergaris WARN, kartu redup, "Koin kurang" diarsir, "Hari berikutnya" 140x42 kanan bawah, saldo enam digit, pesan galat: cocok. Beda disengaja: D-1..D-4, keputusan 3 dan 6.

### Kontras terukur dari tangkapan nyata (`python3 tools/ukur_kontras_tangkapan.py docs/loop/20261023-ui1-komponen-bengkel/shots/iter1 --awalan <ukuran>`)
Teks (latar = warna terbanyak di persegi teks, teks = persentil 98): terburuk 7,79:1 ("! Ban" WARN di chip warn), berikutnya 8,28:1 ("Baik" OK di chip ok); 0 teks < 7:1 di 44 tangkapan (11 keadaan x 4 ukuran), termasuk "UPGRADE" di atas pelat, status, deskripsi, harga, tombol. Garis komponen (pita luar 2 px game vs 2 px di luar): tombol aktif 8,53..13,48:1 (>= 3); kartu 1,14..1,78:1 dan tombol nonaktif 1,14:1 (< 3, lihat D-1). Dua temuan yang sudah diperbaiki sebelum angka akhir: chip jejak "menunggu" 3,65:1 (keputusan 5) dan WARN di atas `UI_PANEL` 6,91:1 (keputusan 4; tes `_test_kontras_token` menjaga kontras teks token terhadap isi tekstur terpasang secara deterministik).

### Mutan (AC-13; Dev, satu perubahan per mutan, `git checkout` sesudahnya)
Dijalankan dengan harness sementara (`build/mutan.py`, tidak di-commit) pada subset `TesTampilBengkel + TesKomponenUi + TesExport + TesBengkelTataC + TesBengkelScene`; subset ini adalah bagian dari `run_tests.gd` penuh. Putaran 1: 41 dari 50 tertangkap, 9 LOLOS (M28, M34, M42, M43, M44, M45, M46, M47, M50). Tes ditambah (jepit mendatar chip di panggung sempit, warna teks chip literal, warna nama upgrade dimiliki, warna teks status, titik penanda tidak tampil untuk komponen baik dan warnanya, tinggi chip penanda 14 dan chip harga/saldo/Baik 18/24, panah tombol hari di kanan); M40 hanya tertangkap lewat SCRIPT ERROR dan diperkuat dengan pemeriksaan eksplisit. Putaran 2 (pohon akhir): **50 dari 50 tertangkap**, pohon kerja bersih sesudahnya.

| Id | Perubahan | Tertangkap oleh (pemeriksaan pertama yang gagal) |
|---|---|---|
| M01 | aksi: saldo tepat harga jadi KURANG (`>=` -> `>`) | tes_tampil_bengkel: saldo 84 untuk harga 84 AKTIF |
| M02 | aksi: AKTIF dan KURANG tertukar | tes_tampil_bengkel kondisi 0,75 + 45 lain |
| M03 | aksi: tersedia=false tidak TIDAK_ADA | tes_tampil_bengkel kondisi 1,0 penuh |
| M04 | kunci_tombol: alasan "Koin kurang" hilang | tes_tampil_bengkel teks tombol |
| M05 | servis: kartu selalu biasa | tes_tampil_bengkel kondisi 1,0 |
| M06 | servis: penuh selalu false | tes_tampil_bengkel kondisi 1,0 |
| M07 | servis: status tampil saat penuh | tes_tampil_bengkel kondisi 1,0 |
| M08 | servis: AUS tanpa penanda di sepeda | tes_tampil_bengkel kondisi 0,50 |
| M09 | servis: kunci penanda PERLU dan AUS tertukar | tes_tampil_bengkel kondisi 0,50 |
| M10 | servis: harga tampil saat penuh | tes_tampil_bengkel kondisi 1,0 |
| M11 | upgrade: tingkat dimiliki dijual lagi (`>` -> `>=`) | tes_tampil_bengkel level 1 |
| M12 | upgrade: semua dimiliki menampilkan tingkat I | tes_tampil_bengkel level 3 |
| M13 | upgrade: dimiliki masih beraksi | tes_tampil_bengkel level 1 |
| M14 | upgrade: dimiliki tidak redup | tes_tampil_bengkel level 1 |
| M15 | upgrade: jejak tampil untuk satu tingkat | tes_tampil_bengkel level 0 |
| M16 | jejak: tingkat dimiliki bukan DIMILIKI (`<=` -> `<`) | tes_tampil_bengkel level 1 |
| M17 | upgrade: tinggi bertingkat tetap 62 | tes_tampil_bengkel bertingkat |
| M18 | chip tingkat: `or` -> `and` | tes_tampil_bengkel level 1 |
| M19 | jejak: gaya AKTIF dan MENUNGGU tertukar | tes_tampil_bengkel jejak gaya |
| M20 | kunci_tingkat: III jatuh ke angka biasa | tes_tampil_bengkel kunci I, II, III |
| M21 | lebar_kolom: floor alih-alih round | tes_tampil_bengkel lebar 640 |
| M22 | lebar_kolom: jarak 8 tidak dikurangi | tes_tampil_bengkel + tes_bengkel_tata_c |
| M23 | tata_panggung: sepeda menempel dasar | tes_tampil_bengkel panggung 280x92 |
| M24 | tata_panggung: papan memakai lebar sepeda | tes_tampil_bengkel panggung |
| M25 | rect_chip: chip ban di sisi salah | tes_tampil_bengkel ban + 30 lain |
| M26 | rect_chip: chip rantai di atas titik | tes_tampil_bengkel rantai |
| M27 | rect_chip: tanpa jepit tegak | tes_tampil_bengkel panggung 84 |
| M28 | rect_chip: tanpa jepit mendatar | LOLOS putaran 1; sekarang tes_tampil_bengkel panggung 160 lebar |
| M29 | SISI_PENANDA: ban sesudah titik | tes_tampil_bengkel sisi chip |
| M30 | titik_sepeda: y memakai x | tes_tampil_bengkel titik |
| M31 | Config titik ban y 67 | tes_tampil_bengkel titik (Config = JSON) |
| M32 | KomponenUi: kartu BAIK tidak redup | tes_tampil_bengkel kondisi 1,0 |
| M33 | KomponenUi: chip AUS bergaya WARN | tes_komponen_ui "AUS = netral + teks" |
| M34 | warna teks chip OK jadi TEXT | LOLOS putaran 1; sekarang tes_bengkel_tata_c warna teks chip |
| M35 | layar: gaya tombol aktif dan nonaktif tertukar | tes_bengkel_tata_c keadaan a |
| M36 | layar: catatan ongkos baru di 3 rusak | tes_bengkel_tata_c keadaan b |
| M37 | layar: label chip tidak ikut disembunyikan | tes_bengkel_scene penuh "Baik" |
| M38 | layar: kolom servis memakai lebar upgrade | tes_bengkel_tata_c keadaan g |
| M39 | layar: tombol hari memakai margin atas | tes_bengkel_tata_c keadaan g |
| M40 | layar: Beli selalu tingkat pertama | LOLOS-lemah putaran 1 (hanya crash); sekarang tes_bengkel_tata_c "kartu berganti ke III" |
| M41 | layar: tombol Beli tetap tampil saat dimiliki | tes_bengkel_tata_c keadaan d |
| M42 | layar: nama upgrade dimiliki tidak redup | LOLOS putaran 1; sekarang tes_bengkel_tata_c keadaan d |
| M43 | layar: warna status PERLU sama dengan AUS | LOLOS putaran 1; sekarang tes_bengkel_tata_c keadaan b |
| M44 | panggung: titik tampil walau baik | LOLOS putaran 1; sekarang tes_bengkel_tata_c keadaan a |
| M45 | panggung: titik PERLU bukan WARN | LOLOS putaran 1; sekarang tes_bengkel_tata_c keadaan b |
| M46 | panggung: chip penanda ukuran normal | LOLOS putaran 1; sekarang tes_bengkel_tata_c keadaan b (tinggi 14) |
| M47 | layar: panah Hari berikutnya di kiri teks | LOLOS putaran 1; sekarang tes_bengkel_tata_c gaya tombol |
| M48 | layar: galat data tidak ditampilkan | tes_bengkel_tata_c keadaan f |
| M49 | layar: kartu servis selalu biasa | tes_bengkel_tata_c keadaan a |
| M50 | ChipUi: tinggi chip tidak dipaksa | LOLOS putaran 1; sekarang tes_bengkel_tata_c chip Baik 18 |

Catatan: satu kejadian kerja, bukan mutan: `git checkout` milik harness sempat membuang suntingan `panggung_sepeda.gd` yang belum di-commit (menghapus `warna_titik`, membuat M44..M46 tampak "galat skrip"); suntingan dipasang ulang dan di-commit sebelum mutan itu diulang.

### Butir yang mengganjal / perlu keputusan
- D-1 (garis kartu 1,14..1,78:1 dan tombol nonaktif 1,14:1 < 3:1) dan D-2 (max vs 12 + inset).
- `uji_aset_pasang_5b.py` sudah gagal di HEAD bagian A (diperbaiki di sini).
- Lisensi latar bengkel tetap terbuka (bagian C mencatatnya di dokumen).
