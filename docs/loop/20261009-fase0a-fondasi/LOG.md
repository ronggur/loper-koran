# Loop Log — 20261009-fase0a-fondasi
Scope: Run 0A — fondasi project Godot  ·  Branch: feat/fase0a-fondasi-godot  ·  Mulai: 2026-10-09  ·  Godot: 4.7.2.stable.official.ed1daf0bf

## Status: PASSED   (selesai di iterasi 1/2; iterasi 2 tidak diperlukan: 0 Blocker, 0 Major, semua gerbang hijau)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 1 | SPEC penuh AC-1..AC-17: `project.godot`, `Config` + `ConfigParser`, `Palette` + `loper_master.gpl`, `LoperAnim` + `LoperSprite` + `loper_agen.tscn`, ubin graybox + `scenes/dev/graybox.tscn`, font + `LICENSES.md`, `run_tests.gd` (950 pemeriksaan) + `cek_keluaran_tes.py` + contoh log, probe layar, CI `tes.yml`, dokumen AC-16. Tidak ada `BLOCKED`. | ✅ import bersih di clone bersih, tes `950 lolos, 0 gagal` + pemeriksa exit 0, buka project 2 frame tanpa ERROR/WARNING | **PASS** (semua gerbang hijau, 0 Blocker, 0 Major) | 14: 0 Blocker, 0 Major, 4 Minor, 7 Nit, 3 NEEDS-MANUAL (Q-001..Q-014) | 0 (belum ada temuan berstatus FIXED) |

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|
| Q-001 | 1 | Minor | scripts/entities/loper_sprite.gd:28-31, 35-47 | `LoperSprite` tidak aman untuk `sprite_frames` null dan tidak bereaksi saat `sprite_frames` diganti. (a) `_ready()` selalu memanggil `play(animation)`; tanpa `sprite_frames` mesin mencetak `ERROR: There is no animation with name 'default'` (dari `LoperSprite.new()` yang masuk tree). (b) Setelah `sprite_frames` null lalu dipasang lagi, `speed_level`/`steer` yang diubah di sela itu tidak diterapkan dan animasi berhenti: `animation` tetap `ngebut_kiri` padahal `speed_level` = 1, `is_playing()` = false. Tidak ada jalur kode 0A yang memicunya (scene selalu berframes), jadi Minor, tapi akan kena saat varian baju menukar `SpriteFrames` (ART_DIRECTION 3.3, kosmetik) dan edge case ini diminta diperiksa. Repro: skrip di bagian "Lampiran repro Q-001" di bawah, dijalankan `godot --headless --path . --script <skrip>`. Usul: jaga `sprite_frames == null` di `_ready`, dan terapkan ulang animasi + `play()` saat `sprite_frames` berganti (sinyal `sprite_frames_changed` atau setter). | DEFERRED | ditunda ke run yang memasang varian baju atau menukar `SpriteFrames` (Fase 1/kosmetik); tidak ada jalur kode 0A yang memicunya | |
| Q-002 | 1 | Minor | tests/run_tests.gd:357 | Tes `pedal_rate` negatif terlalu longgar: `check(pemain.speed_scale >= 0.0, ...)`. Skrip memberi dokumentasi "nilai negatif dianggap 0" (loper_sprite.gd:11, loper_anim.gd:88-89), tapi mutan `return absf(laju_kayuh)` di `LoperAnim.skala_kayuh` (pedal_rate -2.0 jadi speed_scale 2.0, animasi justru dipercepat) tetap HIJAU. Repro: `python3 tools/tests_cek/qa_mutasi.py <klon>` (baris "anim: skala_kayuh absf bukan maxf") atau ganti `maxf(laju_kayuh, 0.0)` jadi `absf(laju_kayuh)` di klon lalu jalankan `run_tests.gd` + pemeriksa: exit 0. Usul: ubah jadi `== 0.0` (sesuai dokumentasi) atau perbarui dokumentasi bila mutlak memang diinginkan. | DEFERRED | ditunda ke run 0B; ubah ke `== 0.0` sesuai dokumentasi saat menyentuh `run_tests.gd` lagi | |
| Q-003 | 1 | Minor | tests/run_tests.gd:459-463, 595-596, 642-657, 685 | Empat mutan bermakna lolos HIJAU, yaitu celah penjaga untuk AC-8 dan AC-9: (1) `Camera2D.zoom = Vector2(1.5, 1.5)` di graybox.tscn tidak ketahuan (tes skala bulat hanya memeriksa `Node2D.scale`, bukan `Camera2D.zoom`, padahal zoom pecahan merusak piksel tajam); (2) `Color.RED` di skrip lolos pemindai hex (hanya hex, `Color("...")`, `Color.html/hex/from_string`, `Color8` yang dikenali); (3) `var sisi: String = "kiri"` lolos pemindai sisi karena `_kode_saja` membuang seluruh isi teks berkutip, jadi `kiri`/`kanan` di string data tidak pernah dilaporkan (hanya identifier yang diperiksa); (4) `var teks: String = "Halo pemain"; print(teks)` di skrip dan `Label`/`text =` di scene tidak punya penjaga sama sekali, padahal AC-9 menyatakan "tidak ada teks pemain di skrip atau scene". Saat ini tidak ada pelanggaran nyata (dicek QA dengan grep: tidak ada Label/text, Color.*, atau kiri/kanan di luar `NAMA_ARAH`), jadi Minor. Repro: `python3 tools/tests_cek/qa_mutasi.py <klon>`, baris "graybox: zoom kamera pecahan 1.5", "sprite: Color.RED", "sprite: string 'kiri' untuk sisi", "sprite: teks pemain di skrip". Usul: periksa `Camera2D.zoom` bulat, daftar putih untuk string `kiri`/`kanan` (hanya `NAMA_ARAH`), `Color\.[A-Z_]+` ditolak, dan pindai `text =` / `Label` di `.tscn`. | DEFERRED | ditunda ke run 0B (celah penjaga di `run_tests.gd`; saat ini tidak ada pelanggan nyata, dicek QA dengan grep) | |
| Q-004 | 1 | Minor | tools/env_art/graybox.py:41, 215, 217; scenes/dev/graybox.tscn | Ukuran graybox menyimpang dari ART_DIRECTION 2.2 tanpa alasan tercatat, padahal fungsinya "mengunci skala" (TECH_PLAN Fase 0, baris 233-234): rumah dibuat 3x2 ubin setinggi 48 px (lebar gambar 161 px) sedangkan tabel 2.2 memberi tapak 3x3 ubin, lebar sekitar 192 px, dinding ditambah atap sekitar 70 px; kotak surat 14 px (tabel: sekitar 20 px); trotoar 1 ubin penuh di tiap sisi (tabel: setengah ubin). Warna tepi ubin aspal memakai `#5F5B66` (Logam gelap) padahal tabel 2.4 memberi nada gelap aspal `#67636D`. Semuanya masih berstatus usulan, jadi bukan pelanggaran keputusan terkunci, tapi graybox yang dipakai menilai skala terhadap pemain sebaiknya mengikuti tabel atau mencatat alasannya. Bukti: `file assets/sprites/_placeholder/*.png` (161x129, 17x23) dan angka di graybox.py. | DEFERRED | ditunda: ukuran graybox masih usulan; dinilai pemilik di review PR, dikunci bersama ukuran ubin setelah graybox Fase 1 | |
| Q-005 | 1 | Nit | tools/cek_keluaran_tes.py:33 | Pemeriksa hanya menandai `ERROR:` bila di awal baris (`^\s*...`). Baris yang diawali teks lain, misalnya keluaran stdout dan stderr yang terpotong lalu bersambung, lolos: `(sed '$d' tools/tests_cek/baik.log; echo "x ERROR: tengah baris"; echo "950 lolos, 0 gagal") \| python3 tools/cek_keluaran_tes.py -` keluar 0. Sesuai bunyi AC-5 dan resep `grep '^ERROR:'` di testing.mdc, jadi hanya Nit; `SCRIPT ERROR` dan `GAGAL` sudah dicocokkan di mana saja. Usul: cocokkan `\bERROR:` atau tambah kasus di uji_pemeriksa. Varian lain yang diuji dan DITOLAK dengan benar: SCRIPT ERROR di tengah baris, ERROR berindentasi, berwarna ANSI, CRLF, ringkasan sebelum error, ringkasan ganda, `N lolos, M gagal`, `0 lolos`, kosong, `GAGAL` tanpa ringkasan. | DEFERRED | dicatat saja (sesuai bunyi AC-5 dan resep `grep` di testing.mdc) | |
| Q-006 | 1 | Nit | scripts/systems/config_parser.gd:131-132 | `ConfigParser` menerima `const A: int = 99999999999999999999` sebagai valid (regex hanya cek digit) dan memanggil `to_int()`, yang mencetak `ERROR: Cannot represent ... as a 64-bit signed integer` dari mesin dan menghasilkan nilai sampah. Juga menerima `007` (nol di depan). Config asli tidak memuat nilai itu; hanya soal kekokohan parser yang menjanjikan "literal valid". Parser lain yang diuji (komentar `#` dan `#` di dalam string, minus, `1.5e-3`, `1.5E+3`, array bersarang, `Array` tak bertipe, `;`, dua const sebaris, `@export`, `enum`, CRLF, hex, `1_000`, NaN/INF, escape, `:=`) berperilaku benar. | DEFERRED | dicatat saja (config asli tidak memuat nilai itu) | |
| Q-007 | 1 | Nit | scripts/systems/loper_anim.gd:42-48, 61-68, 90-93 | Kasus tepi yang tidak ditetapkan di `##`: `besar_arah_dari_sudut(NAN)` = 2 (hanya `arah_dari_gerak` yang menjaga NaN); `pedal_rate` INF atau 1e300 menghasilkan `speed_scale` = inf (tidak ada batas atas; mesin tetap tidak hang, diuji 5 frame); `is_zero_approx(lateral)` memakai epsilon absolut 1e-5, jadi `arah_dari_gerak(-1.0, 9e-6)` = 0 tapi `(-1.0, 2e-5)` = 2 dan `(-1e-9, 1e-6)` = 0 padahal sudutnya hampir 90 derajat; mutan toleransi sudut 1e-6 jadi 0.08 dan `is_zero_approx` jadi `== 0.0` juga HIJAU (batas tes 22,4/22,5/67,5/67,6 tidak sempit). Tidak berdampak di 0A (input 0B akan memberi nilai normal). Semua batas inklusif 22,5 dan 67,5 stabil pada laju 0,001 sampai 1e6 (diuji QA). | DEFERRED | dicatat saja; input 0B memberi nilai normal, perketat bila perlu di 0B | |
| Q-008 | 1 | Nit | docs/ROADMAP.md:3,13,57; docs/TECH_PLAN.md:217; docs/design/DESIGN_SPEC.md:1.1 | Dokumen belum mengikuti kenyataan 0A: ROADMAP baris status masih "per 7 Oktober 2026" (docs.mdc: status project berubah, tanggal status ROADMAP ikut diperbarui), baris 1 #3 dan 4b "sprite baru dicek di 4.3, muat ulang di 4.7.2" serta TECH_PLAN:217 padahal 0A sudah memuatnya di 4.7.2 (tes lolos). 4b milik orchestrator, jadi tinggal diteruskan. Selain itu DESIGN_SPEC 1.1 menyatakan token warna sudah ada di palet induk kecuali token UI, tetapi `RADAR_TIP` `#56C46E` (sama dengan `OK`) tidak ada di ART_DIRECTION 2.4 dan `loper_master.gpl`; tes Dev memilih 4 token radar yang memang ada (`run_tests.gd:563`) tanpa mencatat pengecualian ini. Selisih lama, bukan salah Dev, tapi sebaiknya disebut ke user (docs.mdc: jangan menambal diam-diam). | DEFERRED | ROADMAP (tanggal, #3, 4b), TECH_PLAN, ART_DIRECTION diperbarui orchestrator di `f05bb20`; selisih `RADAR_TIP` (#56C46E tidak ada di palet induk, DESIGN_SPEC 1.1) dilaporkan ke pemilik, tidak ditambal diam-diam | |
| Q-009 | 1 | Nit | scenes/dev/graybox.tscn:1; assets/palette/loper_master.gpl | `load_steps=8` padahal ada 6 `ext_resource` dan 0 `sub_resource` (seharusnya 7; Godot mengabaikan, tapi ui-scenes.mdc minta `load_steps` tetap valid dan editor akan menulis ulang jadi diff acak). `graybox.tscn` (65 node) dan `loper_master.gpl` dibuat oleh skrip sementara di scratchpad yang tidak di-commit (LOG Dev #7 dan #8), jadi tidak bisa dibuat ulang dari `tools/` saat ukuran ubin atau tabel palet berubah; tes hanya menjaga isi `.gpl` (bukan scene). `graybox.py` juga menulis langsung ke `assets/sprites/_placeholder/` (bawaan), bukan ke `build/` lalu disalin seperti aturan art-assets untuk renderer lain (bisa diubah lewat `--out`, tercatat di README alat). | DEFERRED | dicatat saja; `graybox.tscn` dan `.gpl` baru bisa dibuat ulang saat Fase 1 menggantikan graybox | |
| Q-010 | 1 | Nit | tools/env_art/graybox.py:79 | Klaim "deterministik, menjalankan ulang tidak mengubah byte" benar di mesin ini (QA: dua kali jalan + bandingkan dengan yang ter-commit = identik), tapi byte `zlib.compress(..., 9)` bergantung implementasi zlib (zlib vs zlib-ng, versi) sehingga mesin lain bisa menghasilkan PNG berbeda byte walau piksel sama. Usul: tulis pembanding berbasis piksel, atau catat batasnya di docstring. | DEFERRED | dicatat saja | |
| Q-011 | 1 | Nit | scenes/dev/graybox.tscn (RumahA), assets/sprites/_placeholder/house_graybox_kotak.png | Visual: pada tangkapan layar 2340x1080 ada garis hijau 1 px sepanjang dasar sisi kiri rumah A (tepi ubin rumput mengintip di bawah sisi samping kotak rumah). Kosmetik graybox; tidak ada blur, skala pecahan, atau tepi bergerigi acak (lihat catatan layar di bawah). Bukti: `shots/iter1/qa_jendela_2340x1080.png`, sekitar (450-645, 565-655) dalam piksel asli. | DEFERRED | dicatat saja (kosmetik graybox) | |
| Q-012 | 1 | - | .github/workflows/tes.yml | CI tidak bisa dijalankan lokal (runner Linux), jadi bukan PASS. Yang QA verifikasi dengan membaca dan mencocokkan: YAML valid (7 langkah), `on: pull_request` dan `push` ke `main`, `permissions: contents: read`, `timeout-minutes: 15`, `actions/checkout` dipin ke `3d3c42e5aac5ba805825da76410c181273ba90b1` (cocok dengan tag `v7.0.1` lewat `gh api`, rilis terbaru), SHA-512 Godot `9aa00f7a...c65` sama persis dengan baris `Godot_v4.7.2-stable_linux.x86_64.zip` di `SHA512-SUMS.txt` rilis `godotengine/godot-builds` 4.7.2-stable (diunduh QA), `case` versi `4.7.2.stable*` cocok dengan keluaran `godot --version` lokal, langkah tes memakai `set +e` + `PIPESTATUS` benar. Belum terbukti: perilaku Godot 4.7.2 headless di Ubuntu (peringatan khusus Linux, pustaka sistem), dan bahwa `git status --porcelain` bersih setelah import di runner. | NEEDS-MANUAL | | |
| Q-013 | 1 | - | project.godot, scenes/dev/graybox.tscn | Ketajaman dan skala di layar HP sungguhan belum terbukti. QA hanya membuktikan di desktop macOS (OpenGL 4.1 Metal, M1): probe headless dan jendela asli 1920x1080, 2340x1080, 2400x1080, 1560x720 menghasilkan viewport 640x360, 780x360, 800x360, 780x360 dengan skala bulat x3 atau x2, tangkapan layar identik byte dengan milik Dev, `cek_blok_piksel.py` 0 blok tidak seragam. Langkah uji HP di bagian NEEDS-MANUAL bawah. | NEEDS-MANUAL | | |
| Q-014 | 1 | - | project.godot (renderer) | Light 2D, glow, partikel, dan shader warna bayangan di renderer Compatibility pada HP target tidak dikerjakan di 0A (SPEC "Butuh uji perangkat nyata"); tidak diuji QA. Dicatat supaya tidak hilang dari checklist Fase 0. | NEEDS-MANUAL | | |

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

Tambahan QA (iterasi 1), langkah uji yang QA tidak bisa jalankan di sini (tidak ada HP terhubung ke sesi ini, tidak ada runner Linux):

- [ ] (Q-012) Buka PR dari `feat/fase0a-fondasi-godot` lalu pastikan job `tes` hijau di tab Actions: langkah "Pasang Godot" lolos `sha512sum -c`, langkah "Import project" tidak menemukan `ERROR:` dan `git status --porcelain` kosong, "Buka project dua frame" tanpa `WARNING:`, "Tes logika" menampilkan `950 lolos, 0 gagal` dengan `exit Godot=0, exit pemeriksa=0`, dan "Probe layar" tanpa `PECAHAN`. Kalau merah hanya karena peringatan khusus Linux, catat teks persisnya (jangan melonggarkan pemeriksa tanpa alasan).
- [ ] (Q-013) Di Samsung A54 (2340x1080, 19,5:9): pasang build uji (run 0C), buka `scenes/dev/graybox.tscn`, ambil tangkapan layar lewat `adb exec-out screencap -p > a54.png`, lalu `python3 tools/cek_blok_piksel.py 3 a54.png` (harapan: 0 blok tidak seragam, ukuran 2340x1080 dan sisa tepi 0,0). Periksa mata telanjang: piksel tajam, tidak ada blur, jalan naik ke kanan atas, rumah/kotak surat/pemain proporsional. Ulangi di perangkat atau emulator 16:9 (viewport 640x360) dan 20:9 (800x360). Jika `adb` menunjukkan tinggi jendela di bawah 1080 (bilah sistem tampak), skala turun ke x2 dengan tepi kosong besar: itu bukan salah skala bulat, tapi layar penuh imersif belum aktif di preset export.
- [ ] (Q-014) Sama dengan butir light 2D / glow / partikel / shader Dev di atas; Fase 0 tidak boleh dicentang selesai sebelum itu dan sebelum APK diuji di HP (`DEV_PHASES.md`).

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

## Catatan gerbang QA (iterasi 1)

Auditor: Agent 2 (QA), konteks segar, semua klaim Dev diperlakukan sebagai hipotesis dan dijalankan ulang. Lingkungan: macOS Apple M1, `godot --version` = `4.7.2.stable.official.ed1daf0bf`, Python 3 stdlib. Folder kerja sementara di scratchpad sesi (di luar repo): `klon_qa` (clone bersih), `klon_mut` (salinan untuk mutasi), `qa_logs/` (log buatan).

### Tahap 1, gerbang objektif: HIJAU

| # | Perintah | Hasil |
|---|---|---|
| 1 | `git clone --branch feat/fase0a-fondasi-godot <repo> klon_qa` lalu `godot --headless --import > qa_import.log 2>&1` | exit 0; `grep -nE 'ERROR\|WARNING\|SCRIPT'` kosong; `/usr/bin/git status --porcelain -uall` = 0 baris (AC-1) |
| 2 | `mkdir -p build; godot --headless --script res://tests/run_tests.gd 2>&1 \| tee build/tests.log` | baris akhir `950 lolos, 0 gagal`; 17 baris keluaran; sama persis dengan `tools/tests_cek/baik.log` |
| 3 | `python3 tools/cek_keluaran_tes.py build/tests.log` dan dengan `--ketat` | `pemeriksa: lolos (950 lolos, 0 gagal, 0 peringatan)`, exit 0 keduanya (AC-4) |
| 4 | Pemeriksaan QA sendiri: `grep -E 'SCRIPT ERROR\|^ERROR:\|GAGAL' build/tests.log` dan `grep -E '^[0-9]+ lolos, 0 gagal$' build/tests.log` | yang pertama kosong, yang kedua tepat 1 baris |
| 5 | `godot --headless --path . --quit-after 2` di klon | hanya banner versi; 0 baris ERROR/WARNING/SCRIPT (AC-3); status git tetap bersih |
| 6 | Kebersihan repo | `git rev-parse main origin/main` = `1f97f06f...` kembar; `git ls-remote --heads origin 'feat/*'` kosong (tidak ada push); 16 commit di branch, semua `<tipe>: <ringkasan>` bahasa Indonesia (feat/chore/test/art/docs) dengan badan penjelas; tidak ada `.godot/`, `build/`, APK/AAB, keystore, kredensial di diff (grep nama dan isi); `.gitignore` tidak diubah; `docs/ROADMAP.md` hanya bagian 6 yang berubah, `DEV_PHASES.md` dan `tools/loper_art/*.py` tidak tersentuh; semua `.gd` di luar `docs/` punya `.uid`, semua PNG dan TTF punya `.import`; tidak ada `.import` di `tools/` |
| 7 | AC-5, uji pemeriksa sendiri | `python3 tools/tests_cek/uji_pemeriksa.py`: 16 kasus, 0 menyimpang. Plus 26 log buatan QA dan 1 log baik (`qa_logs/`): SCRIPT ERROR, ERROR:, GAGAL + ringkasan gagal, tanpa ringkasan, `N lolos, M gagal`, kosong, ANSI, ERROR berindentasi, SCRIPT ERROR di tengah baris, ringkasan sebelum error, CRLF, ringkasan ganda, `0 lolos`, `USER SCRIPT ERROR` = semua exit 1; log baik, baik CRLF, ringkasan berekor spasi = exit 0. Lolos diam-diam yang ditemukan: `ERROR:` di tengah baris (Q-005); `error:` huruf kecil, `Parse Error:` tanpa awalan SCRIPT ERROR, dan `Segmentation fault` tanpa `handle_crash` (bukan bentuk keluaran Godot yang nyata, tidak dicatat sebagai temuan) |
| 8 | Error skrip setelah `await` (tes menggantung?) | Disisipkan `akar.fungsi_tidak_ada()` setelah `await process_frame` di `_test_graybox_di_tree`: proses TIDAK menggantung (selesai 0,5 detik), ringkasan tetap tercetak `947 lolos, 0 gagal` (exit Godot 0), dan pemeriksa menolak karena `SCRIPT ERROR` (exit 1). Ini membuktikan kenapa pemeriksa wajib. Exit code Godot saat ada tes gagal: 1 (diuji dengan ambang 0.34) |
| 9 | Graybox deterministik | `python3 -I tools/env_art/graybox.py --out <dua folder>` dua kali: 5 PNG identik antar-jalan dan identik byte dengan yang ter-commit. `cmp` `loper_agen.png`, `.json`, `_frames.tres` terhadap `docs/design/character/loper_agen/` = identik (AC-10) |
| 10 | Font dan lisensi (AC-11) | SHA-256 4 berkas cocok dengan `assets/LICENSES.md`; `git hash-object` cocok dengan blob google/fonts di commit `2eb0b48d...` (Lexend `f7099910`, OFL Lexend `b1477aae`, Lilita One `fdec368c`, OFL Lilita `055594f2`, via `gh api`); OFL.txt asli (teks "SIL OPEN FONT LICENSE Version 1.1"); font ditandai "usulan (belum dikunci)" |

### Uji mutasi (`python3 tools/tests_cek/qa_mutasi.py <klon>`, 65 mutasi pada salinan, semua dikembalikan)

Tertangkap MERAH (tes bermakna): semua angka `Config` yang disentuh (kecepatan, unit dunia, rem tahan, zona mati, ambang 0,33/0,80, sudut 22,5/67,5, skala, lateral, float tanpa titik, ekspresi, multi-baris), hex palet satu digit, alpha `HUD_PANEL` 0,84 jadi 0,85, token karangan, nama animasi/arah/tingkat ditukar, tanda lateral dibalik, batas 0,33 dan 0,80 dibuat eksklusif, mundur dianggap maju, `jepit_arah`, guard NaN stick, argumen `nama_animasi` terbalik, fase kayuh tidak dijaga, tidak `play()` di `_ready`, `speed_level`/`steer` tidak dijepit, fps/loop di `.tres` dan JSON, `.import` lossy/mipmap/VRAM, `scale_mode`/`aspect`/snap/orientasi/filter/viewport di `project.godot`, `texture_filter` dan `offset` scene pemain, kamera tidak bulat, skala Tanah 1,5, `Color(1,0,0)` di scene, angka ajaib di skrip, `.gitignore` tanpa `builds/`.

Lolos HIJAU: (setara, tidak dicatat) batas sudut 22,5 dan 67,5 "eksklusif" (setara karena toleransi 1e-6) dan `RADAR_BG` 0.60 jadi 0.6 (nilai sama); (celah, dicatat) `absf` pada `skala_kayuh` (Q-002), zoom kamera pecahan, `Color.RED`, string `"kiri"`, teks pemain di skrip (Q-003), toleransi sudut 0,08 dan `is_zero_approx` jadi `== 0.0` (Q-007).

### Tahap 2, kepatuhan SPEC (bukti kode dan tes)

| AC | Bukti | Hasil |
|---|---|---|
| AC-1 | baris 1 tabel di atas | OK |
| AC-2 | `project.godot:13-24` (name, main_scene, features `4.7`+`GL Compatibility`, viewport 640x360, `canvas_items`, `expand`, `integer`, orientation 0 = landscape tetap), `:28-29` renderer `gl_compatibility`, `:30-31` filter Nearest dan snap. Nama kunci benar untuk Godot 4.7 (dibuktikan oleh tes yang membaca `ProjectSettings`, `run_tests.gd:409-428`, dan oleh mutasi `scale_mode`/`aspect`/snap/orientasi yang membuat tes merah). Viewport sama dengan `Config` (`run_tests.gd:419-420`) | OK |
| AC-3 | baris 5 | OK |
| AC-4, AC-5 | baris 2-4, 7-8; `run_tests.gd:60-61` ringkasan dan `quit(1)` | OK; celah kecil Q-005 |
| AC-6a | `run_tests.gd:79-166`: contoh baik, 21 contoh buruk, file asli, perbandingan dengan `get_script_constant_map` | OK (Q-006 Nit) |
| AC-6b | `run_tests.gd:171-196` (0,32/0,329/0,33/0,5/0,80/0,81/1,0/di luar/negatif/NaN/INF/monoton) | OK |
| AC-6c | `run_tests.gd:208-256`: 22,4/22,5/67,5/67,6 di kedua sisi dan 4 laju, tanda dekat positif, mundur, vektor nol, NaN. Dokumentasi di `loper_anim.gd:51-60` | OK |
| AC-6d | `run_tests.gd:261-316`: 15 nama ada, tepat 15 animasi, 4 frame, loop, fps 8/10/12, region = JSON, atlas = sheet, ukuran sheet 184x870 | OK |
| AC-6e | `run_tests.gd:321-384` | OK; celah Q-002, Q-001 |
| AC-6f | `run_tests.gd:409-464` | OK |
| AC-6g | `run_tests.gd:510-565` (16 token = tabel 1.1 termasuk alpha; himpunan hex `.gpl` = tabel 2.4; RGB cocok hex) | OK (Q-008 catatan RADAR_TIP) |
| AC-6h | `run_tests.gd:592-638` | OK; celah Q-003 |
| AC-7 | `scripts/config.gd:16-67`: 22 konstanta satu baris; nilai = BALANCING 2 (3,0/4,5/6,0; 1,5; 3,0; 2,0; 5,0; 0,90; 0,25; 0,15; 3,0), ambang 0,33/0,80, 22,5/67,5, 640/360/3, 64/32/32; semuanya dijaga tes. Satu tambahan di luar daftar SPEC: `SPRITE_SUDUT_TOLERANSI_DERAJAT` (tercatat Dev #2, dibenarkan: tanpa toleransi 12 tes merah) | OK |
| AC-8 | `.import` semua PNG: `compress/mode=0`, `mipmaps/generate=false`, `detect_3d/compress_to=0`, `vram_texture=false`; `loper_agen.tscn:7` `texture_filter = 1`; `Tanah` dan `Objek` di graybox filter 1; tes `run_tests.gd:430-464` | OK (Q-003 soal zoom kamera) |
| AC-9 | `.gd` tab, tipe return dan variabel (pemindai QA sendiri: 0 pelanggaran param/var/for/spasi/trailing/`##` berbahasa Inggris); `kiri`/`kanan` hanya di `loper_anim.gd:16,20` (nama animasi, dijelaskan di `##` baris 9-12); tidak ada `Label`/`text` di scene, tidak ada `Color.*` di skrip | OK |
| AC-10 | baris 9 tabel gerbang; `LICENSES.md` mencatat graybox buatan sendiri | OK |
| AC-11, AC-12 | baris 10; `.gpl` 56 warna (nama + hex) | OK |
| AC-13 | bagian "Validasi visual" di bawah | OK untuk desktop; HP NEEDS-MANUAL |
| AC-14 | `.gitignore` tidak berubah dan menutup `.godot/`, `build/`, `builds/`, `*.apk`, `*.aab`; tidak ada `.import` di `tools/` | OK |
| AC-15 | Q-012 | NEEDS-MANUAL (dibaca dan dicocokkan) |
| AC-16 | `AGENTS.md`, `00-project-core.mdc`, `docs/README.md`, `ROADMAP.md` bagian 6 berubah di commit `dbe13ad`; 4b dan DEV_PHASES tidak diedit | OK (Q-008 Nit) |
| AC-17 | baris 6 | OK |
| D-1..D-5 | `loper_sprite.gd` di `scripts/entities/`, `loper_agen.tscn` di `scenes/entities/`; hanya 3 berkas sprite di `assets/sprites/loper/`; `LoperAnim` dan `ConfigParser` murni (`extends RefCounted`, `static func`) di `scripts/systems/`; `scenes/dev/graybox.tscn` tanpa teks pemain jadi `main_scene`; tidak ada tema/9-slice | OK |

Keputusan terbuka ROADMAP 5: tidak ada yang diputuskan diam-diam (cek diff; keputusan kecil Dev seperti `orientation=0`, `[importer_defaults]`, toleransi sudut tercatat di LOG Dev #2, #6).

### Tahap 3, review kode terhadap rule

`gdscript.mdc`, `balancing.mdc`, `testing.mdc`, `art-assets.mdc`, `ui-scenes.mdc`, `content-data.mdc`, `docs.mdc`, `git-workflow.mdc` ditelusuri terhadap diff: tidak ditemukan pelanggaran aturan; temuan hanya Minor/Nit di atas. Logika murni di `systems/` (tanpa node, tanpa `Time`/`randi`), nama file = snake_case `class_name`, `##` Indonesia, fungsi privat `_`, tidak ada hex di luar `palette.gd`, tidak ada teks pemain, tidak ada aset Brainy Dungeon, `tools/loper_art/*.py` tidak disentuh, kata "dikunci" hanya dipakai untuk keputusan 4b (layar/Godot) dan untuk status font "belum dikunci"; ubin 64x32 dan angka BALANCING tetap berlabel usulan. Kasus tepi yang QA jalankan (skrip harness di scratchpad, keluaran ada di temuan): `LoperAnim` dengan NaN, INF, 1e300, nol, negatif, mundur, batas sudut pada 9 laju dan dua cara membangun vektor (`rotated` dan `cos/sin`): 0 salah batas, hasil selalu dalam -2..2 (Q-007 untuk sisa); `ConfigParser` 52 masukan aneh (Q-006); `LoperSprite` sebelum masuk tree, `pedal_rate` INF/-INF/1e300 (tidak hang), `sprite_frames` null (Q-001).

### Validasi visual (jalankan nyata, jendela asli non-headless)

Perintah (diulang QA sendiri, bukan salinan angka Dev), dari root repo: `godot --path . --resolution <UK> --position 0,0 --script res://tests/probe_layar_jendela.gd -- docs/loop/20261009-fase0a-fondasi/shots/iter1/qa_jendela_<UK>.png` untuk UK = 1920x1080, 2340x1080, 2400x1080, 1560x720. Hasil dari Godot (OpenGL 4.1 Metal, Compatibility, Apple M1): jendela sama dengan yang diminta; viewport terlihat 640x360, 780x360, 800x360, 780x360; skala 3,0 / 3,0 / 3,0 / 2,0 (bulat); tepi kosong 0,0. Probe headless `godot --headless --path . --script res://tests/probe_layar.gd` menghasilkan 8 baris yang sama dengan LOG Dev. `python3 tools/cek_blok_piksel.py 3 qa_jendela_{1920x1080,2340x1080,2400x1080}.png`: 230400/280800/288000 blok, 0 tidak seragam, exit 0; `... 2 qa_jendela_1560x720.png` 280800 blok, 0 tidak seragam; kontrol negatif (skala 2 pada tangkapan x3) 7935 blok tidak seragam, exit 1. Tangkapan QA identik byte dengan milik Dev (`cmp`), jadi hasilnya dapat diulang.

Yang QA LIHAT (alat Read, 1920x1080, 2340x1080, 2400x1080 dibuka; 1560x720 hanya diperiksa mesin): jalan aspal 2 ubin naik dari kiri bawah ke kanan atas, trotoar di kedua sisi, rumput di tepi, dua kotak rumah di sisi seberang (kiri atas) dengan fasad gelap menghadap sisi dekat, dua kotak surat di depan fasad, pemain Kemeja Agen di lajur dekat menghadap kanan atas dengan bayangan. Piksel tajam tanpa blur, tepi tangga isometrik 2:1 rapi dan konsisten, tidak ada tepi bergerigi acak; urutan gambar benar (kotak surat di atas dinding rumah). Perbandingan rasio: 16:9 (640 lebar) memotong rumput kiri dan kanan paling dekat, 19,5:9 (780) dan 20:9 (800) hanya menambah latar abu-abu bawaan Godot di kiri-kanan (diorama selalu di tengah, tidak ada elemen yang terpotong); tinggi selalu 360, jadi zona aman 16:9 tetap utuh. Catatan visual: sprite pemain tampak kecil dibanding rumah graybox (lihat Q-004), garis hijau tipis di dasar rumah A (Q-011), latar abu-abu bawaan (memang belum ada keputusan latar). TIDAK dinilai di sini: tampilan di layar HP sungguhan, animasi bergerak (graybox statis), performa.

### Lampiran repro Q-001

```gdscript
# simpan di luar repo, jalankan: godot --headless --path <repo> --script <skrip ini>
extends SceneTree

func _initialize() -> void:
	var kosong: LoperSprite = LoperSprite.new()
	root.add_child(kosong)   # (a) ERROR: There is no animation with name 'default'.
	var p: LoperSprite = (load("res://scenes/entities/loper_agen.tscn") as PackedScene).instantiate()
	p.speed_level = 2
	p.steer = -2
	root.add_child(p)
	await process_frame
	var frames: SpriteFrames = p.sprite_frames
	p.sprite_frames = null
	p.speed_level = 1
	p.sprite_frames = frames
	print(p.animation, " ", p.is_playing())   # (b) tercetak: ngebut_kiri false; seharusnya cepat_kiri true
	quit()
```

### Ringkasan verdict iterasi 1

**PASS**: semua gerbang objektif hijau (import bersih di clone, `950 lolos, 0 gagal` + pemeriksa exit 0, buka project bersih, repo bersih, tidak ada commit di `main`, tidak ada push), seluruh AC-1..AC-17 dan D-1..D-5 punya bukti kode dan tes, uji mutasi menunjukkan tes menjaga logika kritis, 0 Blocker dan 0 Major. Terbuka: 4 Minor (Q-001..Q-004), 7 Nit (Q-005..Q-011), 3 NEEDS-MANUAL (Q-012..Q-014). Alasan severity: Q-001 diberi Minor (bukan Major) karena tidak ada jalur kode 0A yang menyentuh `sprite_frames` null atau penggantian frames; kalau orchestrator menilai varian baju sudah di depan mata, naikkan jadi Major. Fase 0 TIDAK boleh dicentang selesai: CI belum hijau di GitHub dan APK/HP belum diuji (run 0B dan 0C).
