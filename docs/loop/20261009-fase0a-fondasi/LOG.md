# Loop Log — 20261009-fase0a-fondasi
Scope: Run 0A — fondasi project Godot  ·  Branch: feat/fase0a-fondasi-godot  ·  Mulai: 2026-10-09  ·  Godot: 4.7.2.stable.official.ed1daf0bf

## Status: IN_PROGRESS   (iterasi saat ini: 1/2)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 1 | SPEC penuh AC-1..AC-17: `project.godot`, `Config` + `ConfigParser`, `Palette` + `loper_master.gpl`, `LoperAnim` + `LoperSprite` + `loper_agen.tscn`, ubin graybox + `scenes/dev/graybox.tscn`, font + `LICENSES.md`, `run_tests.gd` (950 pemeriksaan) + `cek_keluaran_tes.py` + contoh log, probe layar, CI `tes.yml`, dokumen AC-16. Tidak ada `BLOCKED`. | ✅ import bersih di clone bersih, tes `950 lolos, 0 gagal` + pemeriksa exit 0, buka project 2 frame tanpa ERROR/WARNING | | | |

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|

## Catatan gerbang Dev (tempel ringkasan perintah dan hasilnya per iterasi)

### Iterasi 1

Lingkungan: macOS (Apple M1), `godot --version` = `4.7.2.stable.official.ed1daf0bf`, Python 3.14.4 (hanya stdlib). Commit Dev di branch `feat/fase0a-fondasi-godot` (`git log --oneline main..HEAD`, selain `acc9706` milik orchestrator), tidak ada commit di `main`, tidak ada push.

**AC-1, clone bersih** (folder di scratchpad, di luar repo):

```
git clone --branch feat/fase0a-fondasi-godot <repo> <scratchpad>/klon
cd <scratchpad>/klon
godot --headless --import > import.log 2>&1        # exit 0; grep -E "ERROR|SCRIPT ERROR|WARNING" import.log -> kosong
git status --porcelain -uall | wc -l               # 0  (hanya .godot/ yang ter-ignore)
find . -name "*.import" -not -path "./.godot/*" | grep -c "^./tools"   # 0, tidak ada .import liar di tools/
```

Catatan: hook `rtk` di mesin ini mengganti keluaran `git status --porcelain` menjadi kata `ok` saat bersih; hitungan di atas memakai `/usr/bin/git status --porcelain -uall | wc -l` untuk keluaran mentah. Godot tidak menulis ulang `project.godot`, `.tscn`, maupun `.tres` saat import (status tetap bersih), dan `loper_agen_frames.tres` termuat di 4.7.2 tanpa perubahan (byte-identik dengan sumber, dicek `cmp`).

**AC-4/AC-5, tes + pemeriksa** (di clone bersih dan di repo kerja, hasil sama):

```
mkdir -p build
godot --headless --script res://tests/run_tests.gd 2>&1 | tee build/tests.log     # ... 950 lolos, 0 gagal
python3 tools/cek_keluaran_tes.py build/tests.log            # pemeriksa: lolos (950 lolos, 0 gagal, 0 peringatan), exit 0
python3 tools/cek_keluaran_tes.py --ketat build/tests.log    # exit 0 (tidak ada WARNING)
python3 tools/tests_cek/uji_pemeriksa.py                     # uji pemeriksa: 16 kasus, 0 menyimpang
```

Exit code Godot saat ada tes gagal: 1 (dicoba dengan mengubah `SPRITE_AMBANG_NGEBUT` ke 0.85, lalu dikembalikan). Uji mutasi (perubahan sementara, semuanya dikembalikan, tidak di-commit): ambang 0.34 -> 2 GAGAL; panggilan fungsi tak ada di `LoperAnim` -> SCRIPT ERROR + `Compilation failed`, pemeriksa menolak (17 masalah); hex di `loper_sprite.gd` -> GAGAL; `const` multi-baris di `config.gd` -> 3 GAGAL; hex palet diubah 1 digit -> GAGAL; fungsi tanpa tipe return -> GAGAL. Semua dilaporkan oleh `cek_keluaran_tes.py` sebagai TIDAK LOLOS.

**AC-3, buka project:**

```
godot --headless --path . --quit-after 2     # keluaran hanya banner versi; grep -cE "ERROR|WARNING" -> 0
```

**Probe layar headless:** `godot --headless --path . --script res://tests/probe_layar.gd`, hasil di bagian AC-13 di bawah.

**Hal yang tidak bisa dijalankan lokal:** CI `.github/workflows/tes.yml` (Linux runner). YAML dibaca dengan `ruby -ryaml` (valid, 7 langkah). Checksum SHA-512 Godot Linux x86_64 yang disematkan dicocokkan dengan `SHA512-SUMS.txt` rilis `4.7.2-stable` dan dengan zip yang diunduh (`shasum -a 512 -c` = OK; SHA-256 zip juga sama dengan digest GitHub `cadd3204...29e4`).

## Bukti verifikasi layar (AC-13)

Hasil: **sesuai harapan di semua ukuran, tidak ada skala pecahan, cadangan `viewport` tidak dipakai dan tidak diperlukan.** Tidak ada `BLOCKED`.

Temuan teknis yang menentukan caranya: **`godot --headless` mengabaikan `--resolution`** (jendela root tetap 100x100, jadi `--resolution WxH` di mode headless tidak mengukur apa-apa). Karena itu probe mengubah `root.size` lalu membaca hasil hitungan stretch yang sama (`Window._update_viewport_size`). Movie Maker (`--write-movie`) tidak dipakai: ia selalu merekam 640x360 apa pun `--resolution`. Pembuktian kedua memakai jendela asli (non-headless, OpenGL 4.1 Metal, renderer Compatibility, Apple M1) yang menutup sendiri.

**1. Probe headless (semua rasio sekaligus)** , perintah persis dan keluarannya:

```
godot --headless --path . --script res://tests/probe_layar.gd
pengaturan: mode=canvas_items aspect=expand scale_mode=integer base=(640, 360)
jendela 1920x1080 (rasio 1.778): viewport terlihat 640x360, skala 3.0x3.0 (bulat), tepi kosong (0.0, 0.0) px
jendela 2340x1080 (rasio 2.167): viewport terlihat 780x360, skala 3.0x3.0 (bulat), tepi kosong (0.0, 0.0) px
jendela 2400x1080 (rasio 2.222): viewport terlihat 800x360, skala 3.0x3.0 (bulat), tepi kosong (0.0, 0.0) px
jendela 1280x720 (rasio 1.778): viewport terlihat 640x360, skala 2.0x2.0 (bulat), tepi kosong (0.0, 0.0) px
jendela 1560x720 (rasio 2.167): viewport terlihat 780x360, skala 2.0x2.0 (bulat), tepi kosong (0.0, 0.0) px
jendela 1600x720 (rasio 2.222): viewport terlihat 800x360, skala 2.0x2.0 (bulat), tepi kosong (0.0, 0.0) px
jendela 2560x1440 (rasio 1.778): viewport terlihat 640x360, skala 4.0x4.0 (bulat), tepi kosong (0.0, 0.0) px
jendela 1170x540 (rasio 2.167): viewport terlihat 780x360, skala 1.0x1.0 (bulat), tepi kosong (195.0, 90.0) px
```

Ukuran lain bisa diberikan: `... --script res://tests/probe_layar.gd -- 2340x1080 1500x700`. Nilai yang diharapkan di atas dijaga juga oleh `_test_layar_integer` di `run_tests.gd` (7 ukuran dengan viewport dan skala persis, 5 ukuran tak kelipatan: skala tetap bulat dan seragam). Pada ukuran yang bukan kelipatan (mis. 1170x540) Godot memilih skala bulat di bawahnya dan menyisakan tepi kosong (1170x540 -> x1 dengan tepi 195/90 px), tidak pernah skala pecahan.

**2. Jendela asli (non-headless), tangkapan layar dan ukuran dari Godot.** Perintah persis (jendela terbuka sekitar satu detik lalu menutup sendiri; `<UK>` = ukuran):

```
godot --path . --resolution <UK> --position 0,0 --script res://tests/probe_layar_jendela.gd -- docs/loop/20261009-fase0a-fondasi/shots/iter1/jendela_<UK>.png
```

| `--resolution` | Rasio | Jendela asli menurut Godot | Viewport terlihat | Skala |
|---|---|---|---|---|
| 1920x1080 | 16:9 | 1920x1080 | 640x360 | x3 |
| 2340x1080 | 19,5:9 (A54) | 2340x1080 | 780x360 | x3 |
| 2400x1080 | 20:9 | 2400x1080 | 800x360 | x3 |
| 1280x720 | 16:9 | 1280x720 | 640x360 | x2 |
| 1560x720 | 19,5:9 | 1560x720 | 780x360 | x2 |
| 1600x720 | 20:9 | 1600x720 | 800x360 | x2 |

Tangkapan layar (ukuran sama dengan jendela) ada di `docs/loop/20261009-fase0a-fondasi/shots/iter1/jendela_<UK>.png` (6 berkas). Ketajaman diperiksa mesin: tiap piksel game harus jadi blok skala x skala yang seragam.

```
python3 tools/cek_blok_piksel.py 3 docs/loop/20261009-fase0a-fondasi/shots/iter1/jendela_{1920x1080,2340x1080,2400x1080}.png
  -> 230400 / 280800 / 288000 blok, 0 tidak seragam, sisa tepi (0, 0), exit 0
python3 tools/cek_blok_piksel.py 2 docs/loop/20261009-fase0a-fondasi/shots/iter1/jendela_{1280x720,1560x720,1600x720}.png
  -> 230400 / 280800 / 288000 blok, 0 tidak seragam, sisa tepi (0, 0), exit 0
python3 tools/cek_blok_piksel.py 2 .../jendela_2340x1080.png      # kontrol negatif: skala salah -> 7935 blok tidak seragam, exit 1
```

Batas bukti ini: **desktop macOS, bukan HP.** Ketajaman dan skala di Samsung A54 (2340x1080, 780x360 x3) belum diuji (lihat NEEDS-MANUAL). Risiko untuk run 0C: di Android, jika tinggi jendela yang tersedia kurang dari 1080 (bilah sistem tidak disembunyikan), skala bulat turun ke x2 dengan tepi kosong besar. Layar penuh imersif harus dipastikan di preset export dan dicek di HP.

## NEEDS-MANUAL (uji di HP)
- [ ] Tampilan dan ketajaman piksel di 16:9, 19,5:9 (A54 2340×1080 → 780×360), dan 20:9 di layar sungguhan; jalankan scene `scenes/dev/graybox.tscn`, harapan: piksel tajam tanpa blur, skala bulat, tidak ada tepi bergerigi acak.
- [ ] Di HP: pastikan tinggi jendela yang dipakai game tepat 1080 (bilah sistem tersembunyi, layar penuh imersif) sehingga skala tetap x3. Dengan stretch `integer`, tinggi di bawah 1080 menurunkan skala ke x2 dan menyisakan tepi kosong. Dikerjakan di preset export run 0C; probe: `tests/probe_layar_jendela.gd` tidak bisa jalan di HP, jadi cek lewat tampilan dan tangkapan layar `adb`.
- [ ] CI GitHub Actions hijau pada PR (hanya bisa dibuktikan setelah PR dibuka). Dev tidak bisa menjalankan runner Linux; langkah dan checksum sudah diperiksa dengan membaca dan mencocokkan (lihat Catatan gerbang).
- [ ] Cek light 2D / glow / partikel / shader warna bayangan di renderer Compatibility pada HP target (tidak dikerjakan di 0A; masuk run berikutnya atau Fase 1).

## Keputusan & catatan
- Keputusan pemilik (ROADMAP 4b, 2026-10-09): Godot 4.7.2, skala ×3, base 640×360, `canvas_items` + integer + `expand`, package `com.rmh.kring`. Cadangan `viewport` tidak boleh dipakai tanpa persetujuan pemilik.
- Tidak ada keputusan terbuka (ROADMAP 5) yang menghambat scope 0A, jadi tidak ada pertanyaan ke pemilik. Ukuran ubin 64×32 dan font tetap berstatus usulan.
- Keputusan orchestrator D-1..D-5 ada di SPEC.md; dilaporkan ke pemilik di laporan akhir.

### Keputusan dan catatan Dev, iterasi 1 (untuk dinilai di review; tidak ada yang menutup keputusan ROADMAP bagian 5)

Struktur D-1..D-5 dari SPEC diikuti apa adanya: `loper_sprite.gd` di `scripts/entities/`, `loper_agen.tscn` di `scenes/entities/`, `LoperAnim` dan `ConfigParser` di `scripts/systems/`, scene utama `scenes/dev/graybox.tscn`, tanpa tema/9-slice. Keputusan kecil yang Dev ambil:

1. **Nama konstanta `Config`** (22 konstanta, satu baris, `##` di baris atasnya): `LAYAR_LEBAR_DASAR_PX`, `LAYAR_TINGGI_DASAR_PX`, `LAYAR_SKALA_PIKSEL`, `UBIN_LEBAR_PX`, `UBIN_TINGGI_PX`, `UBIN_UNIT_DUNIA`, `KECEPATAN_{SANTAI,CEPAT,NGEBUT,MELAMBAT,LATERAL}_UD`, `AKSELERASI_UD2`, `PERLAMBATAN_MELAMBAT_UD2`, `REM_PERLAMBATAN_UD2`, `REM_AMBANG_STICK`, `REM_TAHAN_DETIK`, `ZONA_MATI_STICK`, `SPRITE_AMBANG_CEPAT`, `SPRITE_AMBANG_NGEBUT`, `SPRITE_SUDUT_SERONG_DERAJAT`, `SPRITE_SUDUT_SIKU_DERAJAT`. Satuan di nama (PX, UD, UD2, DETIK, DERAJAT). Nilainya persis BALANCING 2 (usulan). Kecepatan fps animasi (8/10/12) tidak masuk `Config`: itu properti sprite (`.tres`/JSON), dibandingkan di tes, bukan angka tuning.
2. **`SPRITE_SUDUT_TOLERANSI_DERAJAT = 0.000001`** ditambahkan ke `Config`. Alasan: sudut dihitung dengan `atan2`; tanpa toleransi, vektor tepat 22,5 derajat bisa terbaca 22,4999999 dan jatuh ke "normal" padahal batasnya inklusif. Dengan toleransi, batas 22,5 dan 67,5 inklusif secara stabil (diuji pada tiga laju dan kedua sisi).
3. **Aturan `ConfigParser`**: `float` wajib berbentuk dengan titik desimal (`3.0`, bukan `3`); `int` menolak `3.5`; tipe didukung `int`, `float`, `bool`, `String`, `Array[...]` dari keempatnya; komentar `#` di ujung baris diizinkan; `:=` dan tanpa tipe ditolak. Tes juga mencocokkan nilai hasil parser dengan nilai `Config` yang dibaca GDScript (satu sumber).
4. **Kasus tepi yang ditetapkan di `##` `LoperAnim`** (bagian AC-6c "ditentukan dan didokumentasikan"): vektor nol, lateral nol (termasuk mundur murni) = arah 0; mundur dengan lateral = +-2 sesuai tanda lateral; NaN = 0 (arah) atau santai (tingkat, supaya NaN tidak jatuh ke ngebut); `lateral > 0` = sisi `dekat` = animasi `kanan` (positif). Tanda dan nama animasi `kiri`/`kanan` dijelaskan di `##` karena berasal dari sprite aset yang dikunci.
5. **`LoperSprite` berbeda dari `loper_sprite.gd` di folder desain** (arsip tidak diubah): memanggil `play()` di `_ready` (skrip lama tidak pernah memutar animasi bila animasi awal sudah `santai_normal`); setter memakai `LoperAnim.jepit_*`; `pedal_rate` NaN/negatif = `speed_scale` 0; fase kayuh dijaga lewat `set_frame_and_progress`; `push_warning` bila nama animasi tidak ada. Nama properti `speed_level`, `steer`, `pedal_rate` dipertahankan dari README sprite dan SPEC AC-6e.
6. **`project.godot`**: selain pengaturan AC-2, ditambah `[importer_defaults] texture` (Lossless, tanpa mipmap, `detect_3d/compress_to=0`) supaya aturan impor sprite berlaku untuk semua tekstur baru dan bisa dites; `rendering_method.mobile` juga `gl_compatibility`; orientasi `0` (landscape, bukan `sensor_landscape`, jadi tidak bisa terbalik 180 derajat; apakah boleh sensor adalah hal untuk run 0C). **Tidak ada `icon.svg` / `config/icon`**: Godot tidak memintanya, ikon bawaan Godot (logo Godot) berlisensi CC BY 4.0, ikon final di Fase 14. Warna latar bawaan Godot dibiarkan (menaruh warna di `project.godot` akan menggandakan token palet).
7. **Graybox**: `graybox.py` (stdlib, deterministik) membuat 3 ubin + kotak rumah 3x2 ubin tinggi 48 px (pivot 64,128) + kotak surat 17x23 (pivot 8,22), warna dari palet induk. `graybox.tscn` berisi 56 ubin statis (8 ubin sepanjang jalan x 7 lajur: rumput 2, trotoar, aspal 2 = lebar jalan 2 ubin sesuai BALANCING 6, trotoar, rumput), dua rumah, dua kotak surat, pemain, dan `Camera2D` di posisi bulat. Scene itu ditulis sekali oleh skrip sementara di scratchpad (tidak di-commit), jadi scene-nya statis dan bisa diganti Fase 1. Tanpa proyeksi isometrik resmi; rumus posisi hanya dipakai saat membuat berkasnya. `y_sort_origin` rumah diatur supaya kotak surat di depannya tergambar di atasnya.
8. **`loper_master.gpl`**: 56 baris (nama "Peran / nada" + hex), dihasilkan sekali oleh skrip sementara yang membaca tabel ART_DIRECTION 2.4 (tidak di-commit). Ada hex yang muncul di dua peran (mis. `#B47C5F`), dibiarkan karena tabel sumbernya begitu. Nama nada untuk Aspal dan Trotoar ("1"/"2") sengaja netral karena tabel tidak menyebut mana terang/gelap. Tes menjaga himpunan hex `.gpl` = himpunan hex tabel.
9. **Font**: berkas diganti nama ke `snake_case` dan ditaruh per folder (`assets/fonts/lexend/`, `assets/fonts/lilita_one/`) bersama `OFL.txt` hulu. Lexend adalah font variabel (satu berkas untuk Regular dan SemiBold). Blob git hasil unduhan dicocokkan dengan API GitHub (cocok). Isi font tidak diubah; hanya dibaca header tabel `name`-nya untuk memastikan itu font yang benar (data tak tepercaya tidak dijalankan).
10. **Tes di luar daftar AC-6**: scene tree (`await process_frame`: root belum siap di `_initialize`, jadi node yang ditambahkan ke `root` baru masuk tree setelah satu frame), lisensi font, `.gitignore`, dan tiga pemindai gaya (hex/`Color(...)`, angka literal di `scripts/systems|entities|ui` kecuali 0/1/2/-1/-2/0.0/1.0 dan `palette.gd`, serta tab/tipe return/`var` tanpa tipe/`kiri`-`kanan` di kode). Pemindai heuristik; tes memeriksa pemindai itu sendiri menangkap contoh pelanggaran. Tes cek versi mengharuskan Godot 4.7.x (sengaja gagal di versi minor lain). Jumlah 950 banyak berasal dari satu pemeriksaan per berkas/per ukuran/per animasi; label kegagalan menyebut baris atau berkas.
11. **`cek_keluaran_tes.py`**: `GAGAL` dicocokkan di mana pun dalam baris (sama dengan `grep` di `testing.mdc`); kode warna ANSI dibuang dulu (keluaran import Godot berwarna); crash (`handle_crash`, `Program crashed`) menolak; ringkasan ganda dan `0 lolos` menolak; exit 2 untuk berkas tak terbaca. `baik.log` adalah keluaran asli `run_tests.gd`; log `buruk_*.log` disisipi baris yang meniru bentuk keluaran Godot yang teramati di sesi ini (mis. `ERROR: Cannot open file 'res://scenes/dev/graybox.tscn'.` dan `SCRIPT ERROR: Invalid call. Nonexistent function ...`), tanpa kode warna kecuali `buruk_error_berwarna.log`.
12. **CI**: tanpa `--ketat` (peringatan tercetak tapi tidak menggagalkan), karena runner Linux tidak bisa dicoba lokal dan peringatan khusus Linux akan membuat PR pertama merah tanpa bisa didiagnosis; langkah "buka project dua frame" tetap menggagalkan pada `WARNING:`. `actions/checkout` dipin ke hash commit `v7.0.1` (hasil `gh api`, rilis terbaru saat ini). Mengganti Godot = mengganti `GODOT_RILIS`, `GODOT_VERSI_DIHARAPKAN`, `GODOT_SHA512`.
13. **Dokumen di luar daftar AC-16 yang ikut disesuaikan** karena jadi salah kalau dibiarkan: `.cursor/rules/testing.mdc` (resep `grep` diganti `tools/cek_keluaran_tes.py`, "Godot belum ada" dihapus) dan `docs/design/character/loper_agen/README.md` (lokasi runtime sprite, D-1). Tidak menyentuh `ROADMAP.md` 4b, bagian lain ROADMAP, `DEV_PHASES.md`, GDD, BALANCING (angka sama), maupun `tools/loper_art/`.
14. **Tidak dibuat** (sengaja): `tools/.gdignore` (di clone bersih tidak ada `.import` di `tools/`, jadi tidak perlu), `.gitattributes`, `icon.svg`, tema UI, terjemahan, autoload.
15. Pengamatan untuk fase berikutnya: `Palette` memuat `Color("#...")` yang dihitung Godot saat kompilasi; token dengan alpha (`HUD_PANEL` 0,84, `RADAR_BG` 0,60) memakai angka literal di `palette.gd` (satu-satunya file yang dikecualikan pemindai angka). Pemindai "tanpa hex" juga menolak `Color(angka)` di scene/`.tres`, lebih ketat dari bunyi SPEC (hex dan `Color("...")`), supaya warna di scene tidak lolos lewat angka.
