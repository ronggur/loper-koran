# SPEC — 20261009-fase0a-fondasi

Run 0A dari `docs/LOOP-DEV-QA.md` Bagian 6. Kontrak bagi Dev **dan** QA.

## Tujuan

Membuat fondasi project Godot 4.7.2 yang bisa diimpor, dites headless, dan dipakai run 0B: pengaturan layar dan impor, `config.gd`, `palette.gd`, sprite pemain terpasang dengan pemilih animasinya, ubin graybox, runner tes dengan pemeriksa keluaran, dan CI sederhana. Tanpa input touch (run 0B) dan tanpa export Android (run 0C).

## Keputusan dari pemilik (dengan tanggal)

Terkunci, jangan ditanyakan ulang (ROADMAP 4b, 2026-10-09):

- Godot **4.7.2**, renderer **Compatibility**, landscape.
- Skala piksel **×3**, base **640×360**, stretch `canvas_items`, `scale_mode = integer`, aspect `expand`. Cadangan `viewport` **tidak boleh dipakai tanpa persetujuan pemilik**: kalau verifikasi gagal, catat `BLOCKED` di LOG dan lapor.
- Nama package `com.rmh.kring` (hanya relevan di run 0C; jangan ditulis di 0A kecuali di dokumen yang sudah menyebutnya).
- Judul game **Kring Kring!** (GDD 5.4); dipakai untuk `config/name` di `project.godot`. Nama kerja repo tetap "Loper Koran".

Status **usulan** (jangan ditulis sebagai "dikunci" di mana pun):

- Ukuran ubin 64×32 (ART_DIRECTION 11, dikunci setelah graybox Fase 1).
- Font Lexend dan Lilita One (ART_DIRECTION 11).
- Semua angka di `BALANCING.md` bagian 2 (angka awal untuk prototype).
- Palet induk (ART_DIRECTION 2.4).

Keputusan struktur yang diambil orchestrator (bisa ditolak di review PR; dicatat di laporan akhir):

- D-1. `loper_sprite.gd` ditaruh di `scripts/entities/` dan `loper_agen.tscn` di `scenes/entities/`, **bukan** di `assets/sprites/loper/` seperti README sprite. Alasan: `gdscript.mdc` menaruh skrip node entitas di `scripts/entities/`, dan folder `assets/` hanya berisi aset. Hanya `loper_agen.png`, `loper_agen.json`, `loper_agen_frames.tres` yang disalin ke `assets/sprites/loper/`.
- D-2. Logika pemilih tingkat dan arah sprite adalah `static func` murni di `scripts/systems/` (`class_name LoperAnim`), dipakai oleh `LoperSprite`. Node hanya menampilkan.
- D-3. Parser format `config.gd` adalah `static func` murni di `scripts/systems/` (`class_name ConfigParser`) supaya bisa dites dengan contoh baik dan buruk, lalu dijalankan pada file asli.
- D-4. Scene utama sementara `scenes/dev/graybox.tscn` (tanpa teks pemain), supaya ada sesuatu yang bisa dibuka dan dipotret. Scene `Boot` menyusul di fase lain.
- D-5. Tema (`assets/ui/theme.tres`) dan panel 9-slice **tidak** dibuat di 0A (belum ada layar bertulisan). Dibuat di run pertama yang menampilkan teks pemain.

## Di luar scope

- Input touch, stick, swipe, kidal, keyboard (run 0B). Sepeda bergerak (0B).
- Proyeksi isometrik resmi dan sistem koordinat dunia↔layar (Fase 1). Graybox boleh memakai posisi statis.
- Export Android, `export_presets.cfg`, `android/`, keystore, APK (run 0C).
- File terjemahan dan `tr()` (format ditetapkan di run pertama yang butuh teks pemain). Tidak boleh ada teks pemain di scene 0A.
- Uji cahaya 2D, glow, partikel, shader di HP target (butuh HP, masuk NEEDS-MANUAL).
- Membuat atau mengubah sprite lewat renderer (`tools/loper_art/*.py` tidak disentuh). Ubin graybox boleh dibuat dengan skrip baru di `tools/env_art/` (bukan diedit tangan).
- Integrasi iklan, analytics, save (`SaveManager`).

## Kriteria penerimaan (bisa diuji)

Semua perintah dijalankan dari root repo. `GODOT` = `godot` (ada di PATH: `/opt/homebrew/bin/godot`, 4.7.2).

**Project dan impor**

- AC-1: Pada clone bersih branch ini (di folder di luar repo), `$GODOT --headless --import` selesai tanpa baris `ERROR:` / `SCRIPT ERROR`, dan sesudahnya `git status --porcelain` di clone itu **kosong** (semua `.uid` dan `.import` yang dibuat Godot sudah ter-commit; `.godot/` tidak ter-commit).
- AC-2: `project.godot` memuat: `config/name="Kring Kring!"`, `config/features` berisi `4.7` dan `GL Compatibility`, renderer `gl_compatibility`, orientasi landscape terkunci, viewport 640×360, `stretch/mode="canvas_items"`, `stretch/aspect="expand"`, `stretch/scale_mode="integer"`, `rendering/2d/snap/snap_2d_transforms_to_pixel=true`, default texture filter Nearest, `run/main_scene` menunjuk `res://scenes/dev/graybox.tscn`. Nilai layar harus sama dengan konstanta di `Config` (tes membandingkan keduanya).
- AC-3: `$GODOT --headless --path . --quit-after 2` berjalan sampai selesai tanpa `ERROR:`, `SCRIPT ERROR`, atau `WARNING:` di keluaran (scene utama termuat).

**Tes dan pemeriksa keluaran**

- AC-4: `$GODOT --headless --script res://tests/run_tests.gd 2>&1 | tee <log>` lalu `python3 tools/cek_keluaran_tes.py <log>` keluar 0. `run_tests.gd` mencetak baris ringkasan tepat `N lolos, 0 gagal`, mencetak `GAGAL: <label>` untuk tiap kegagalan, dan keluar dengan kode 1 bila ada yang gagal.
- AC-5: `tools/cek_keluaran_tes.py` keluar non-nol untuk log yang memuat `SCRIPT ERROR`, baris `ERROR:`, baris `GAGAL`, atau tanpa baris ringkasan `N lolos, 0 gagal` (juga untuk `N lolos, M gagal` dengan M>0). Baris `WARNING:` dilaporkan sebagai peringatan dan menjadi kegagalan hanya dengan `--ketat`. Bukti: contoh log baik dan buruk di `tools/tests_cek/` (atau setara) dan cara menjalankannya didokumentasikan; QA menjalankan sendiri.
- AC-6: `run_tests.gd` memuat tes (label bahasa Indonesia, rujuk bagian dokumen) untuk:
  - a. **Parser `config.gd`**: contoh baik (angka, float, bool, array literal) lolos; contoh buruk gagal (konstanta multi-baris, ekspresi `= A * 2`, referensi ke konstanta lain, tanpa tipe, huruf kecil); file `scripts/config.gd` asli lolos tanpa galat.
  - b. **Tingkat sprite dari stick** (BALANCING 2): kekuatan < 0,33 → santai (0); 0,33 sampai 0,80 inklusif → cepat (1); > 0,80 → ngebut (2); nilai di luar 0..1 dijepit; nilai negatif (stick bawah) → santai. Tes menyentuh batas 0,32 / 0,33 / 0,80 / 0,81.
  - c. **Arah sprite dari gerak** (BALANCING 2): sudut antara vektor gerak dan arah jalan < 22,5° → 0 (normal); 22,5° sampai 67,5° inklusif → ±1 (serong); > 67,5° → ±2 (90°). Tanda: lateral ke sisi `dekat` positif (kanan), ke sisi `seberang` negatif (kiri). Gerak mundur dan vektor nol → ditentukan dan didokumentasikan di `##`, ada tesnya. Tes menyentuh batas 22,4° / 22,5° / 67,5° / 67,6° di kedua sisi.
  - d. **Nama animasi**: untuk semua pasangan tingkat 0..2 × arah -2..2, `LoperAnim.nama_animasi(...)` menghasilkan nama yang **ada** di `SpriteFrames` `loper_agen_frames.tres`. `SpriteFrames` memuat tepat 15 animasi, tiap animasi 4 frame, loop aktif, fps 8 / 10 / 12 untuk santai / cepat / ngebut, dan region tiap frame sama dengan `loper_agen.json`.
  - e. **Scene pemain**: `scenes/entities/loper_agen.tscn` bisa diinstansiasi (tanpa masuk scene tree), mengatur `speed_level` dan `steer` mengubah `animation` sesuai `LoperAnim.nama_animasi`, nilai di luar jangkauan dijepit, `pedal_rate` negatif tidak membuat `speed_scale` negatif. Node di-`free()` di akhir.
  - f. **Pengaturan proyek**: tes membaca `ProjectSettings` dan `.import` sprite untuk memeriksa AC-2 (tanpa duplikat logika di tes lain) dan AC-8.
  - g. **Palet**: setiap token `UI_*`, `HUD_PANEL`, `OUTLINE`, `TEXT*`, `ACCENT`, `OK`, `FAIL`, `WARN`, `RADAR_*` di `palette.gd` bernilai sama dengan tabel `DESIGN_SPEC.md` 1.1 (hex dan alpha), dan warna palet induk yang dipakai ada di `assets/palette/loper_master.gpl`.
  - h. **Tanpa hex di luar palet**: tes memindai `scripts/**/*.gd` (kecuali `palette.gd`), `scenes/**/*.tscn`, dan `assets/**/*.tres` untuk pola hex warna dan `Color("...")`; hasilnya nol.

**Aturan kode dan data**

- AC-7: `scripts/config.gd` (`class_name Config extends RefCounted`, hanya `const`) memuat angka awal `BALANCING.md` bagian 2 yang sama persis (3,0 / 4,5 / 6,0 u/d; melambat 1,5; akselerasi 3,0; perlambatan melambat 2,0; rem 5,0 dengan ambang stick 0,90 dan tahan 0,25 detik; zona mati 0,15; lateral 3,0), ambang pemilih sprite (0,33 / 0,80 dan 22,5° / 67,5°), konstanta layar (640, 360, ×3) dan ubin (64×32 px, 32 unit dunia per ubin, usulan). Satu baris per konstanta, nilai literal, satuan di nama atau komentar `##`. Tidak ada angka tuning di luar `config.gd`.
- AC-8: Impor sprite dunia: Lossless, tanpa mipmap, tanpa kompresi VRAM (dibaca dari `.import`); node sprite memakai filter Nearest; skala bulat saja. Ubin graybox dan sprite pemain terbaca dengan setelan yang sama.
- AC-9: Semua `.gd` memakai tab, static typing (tipe return di setiap fungsi, tipe eksplisit untuk variabel dan properti `@export`), `##` bahasa Indonesia, nama sisi `seberang` / `dekat` (tidak ada `kiri` / `kanan` untuk sisi jalan; `steer` memakai nama animasi `kiri` / `kanan` karena nama itu berasal dari sprite aset yang dikunci: dijelaskan di `##`). Tidak ada teks pemain di skrip atau scene.
- AC-10: Aset: `assets/sprites/loper/` memuat `loper_agen.png`, `loper_agen.json`, `loper_agen_frames.tres` (byte-identik dengan sumber di `docs/design/character/loper_agen/`, kecuali bila `.tres` perlu dimuat ulang di 4.7.2: perubahan dijelaskan di LOG). Ubin graybox (aspal, trotoar, rumput, 64×32) serta kotak graybox rumah dan kotak surat ada di `assets/sprites/_placeholder/`, dibuat oleh skrip di `tools/env_art/` yang di-commit bersama hasilnya (satu commit). Tidak ada PNG yang diedit tangan, tidak ada aset dari Brainy Dungeon.
- AC-11: Font Lexend dan Lilita One ada di `assets/fonts/` bersama berkas lisensi OFL-nya, dan `assets/LICENSES.md` mencatat nama file, sumber (URL dan hash commit), lisensi, dan kewajiban atribusi untuk tiap aset pihak ketiga, dengan font ditandai **usulan** (belum dikunci). Bila unduhan tidak mungkin, catat `BLOCKED` di LOG dan lanjutkan sisanya.
- AC-12: `assets/palette/loper_master.gpl` ada dan memuat palet induk ART_DIRECTION 2.4 (nama + hex); `scripts/ui/palette.gd` (`class_name Palette`) memuat token DESIGN_SPEC 1.1 sebagai satu-satunya tempat hex.

**Verifikasi layar**

- AC-13: Bukti yang bisa diulang dicatat di LOG untuk tiga ukuran jendela yang mewakili 16:9, 19,5:9, dan 20:9 (mis. 1920×1080, 2340×1080, 2400×1080 dan satu ukuran ×2 seperti 1280×720): skala bulat yang dipakai Godot, ukuran viewport yang tampak (harus 640×360, 780×360, 800×360), dan tidak ada skala pecahan. Caranya boleh probe skrip headless dengan `--resolution` atau tangkapan layar; Dev menulis perintahnya persis di LOG, dan menyimpan tangkapan layar (kalau ada) di `docs/loop/20261009-fase0a-fondasi/shots/iter<N>/`. Bila hasil tidak sesuai harapan: `BLOCKED`, jangan ganti ke `viewport`.

**Kebersihan dan dokumen**

- AC-14: `.gitignore` tetap menutup `.godot/`, `build/`, `builds/`, APK/AAB; tidak ada keystore, kredensial, `.godot/`, `build/`, atau APK di diff; `tools/.gdignore` ada bila `tools/` memuat berkas yang diimpor Godot (cek dengan `--import` di clone bersih: tidak ada `.import` liar di `tools/`).
- AC-15: `.github/workflows/` memuat CI sederhana (pemicu `pull_request` dan `push` ke `main`): memasang Godot 4.7.2 dari rilis resmi (`godotengine/godot-builds`, dengan verifikasi checksum), menjalankan import, tes dengan `tee`, dan `tools/cek_keluaran_tes.py`. CI tidak bisa dijalankan lokal: QA memeriksa YAML dengan membaca dan menandai `NEEDS-MANUAL` sampai CI hijau di PR.
- AC-16: Dokumen diperbarui di commit yang sama dengan perubahannya: `AGENTS.md` (Perintah cepat, peta repo) dan `.cursor/rules/00-project-core.mdc` (Perintah: hapus "Project Godot belum ada", versi Godot, perintah tes + pemeriksa), `docs/README.md` (status, struktur), `docs/ROADMAP.md` bagian 6 (cara menjalankan). Catatan: `ROADMAP.md` 4b (hasil verifikasi stretch, AC-5 brief) ditulis orchestrator di commit `docs:` terpisah; Dev **tidak** mengedit 4b dan tidak mencentang `DEV_PHASES.md`.
- AC-17: Commit kecil, format `<tipe>: <ringkasan>` bahasa Indonesia, di branch `feat/fase0a-fondasi-godot`, tidak ada commit di `main`, tidak ada push.

## Perubahan file/struktur yang diharapkan

```
project.godot                              (Godot 4.7.2, pengaturan di AC-2)
icon.svg                                   (ikon sementara bawaan, bila Godot memintanya; ikon final di Fase 14)
scenes/dev/graybox.tscn                    (scene utama sementara, tanpa teks)
scenes/entities/loper_agen.tscn
scripts/config.gd
scripts/systems/config_parser.gd           (ConfigParser)
scripts/systems/loper_anim.gd              (LoperAnim)
scripts/entities/loper_sprite.gd           (LoperSprite)
scripts/ui/palette.gd                      (Palette)
assets/sprites/loper/{loper_agen.png,loper_agen.json,loper_agen_frames.tres} (+ .import)
assets/sprites/_placeholder/*.png          (+ .import)
assets/palette/loper_master.gpl
assets/fonts/*                             (+ .import, lisensi OFL)
assets/LICENSES.md
tools/env_art/graybox.py                   (pembuat ubin dan kotak graybox)
tools/cek_keluaran_tes.py                  (pemeriksa keluaran) + contoh log uji
tools/.gdignore                            (bila perlu)
tests/run_tests.gd
.github/workflows/tes.yml
```

## Tes yang harus ada

Lihat AC-6 (a–h) dan AC-5 (pemeriksa keluaran). Tiap bug yang ditemukan QA mendapat tes regresi di `tests/run_tests.gd` (atau contoh log baru untuk pemeriksa), kecuali murni visual.

## Butuh uji perangkat nyata (NEEDS-MANUAL)

- Ketajaman piksel dan tampilan di layar sungguhan pada 16:9, 19,5:9, 20:9. HP uji Samsung A54 (19,5:9) belum dicolok; kalau tidak ada, jalankan di jendela dan catat bahwa HP belum diuji.
- Pengecekan light 2D, glow, partikel, shader warna bayangan di renderer Compatibility pada HP target (tidak dikerjakan di 0A).
- CI hijau di GitHub (hanya terbukti setelah PR dibuka).

## Dokumen yang ikut diperbarui

`AGENTS.md`, `.cursor/rules/00-project-core.mdc`, `docs/README.md`, `docs/ROADMAP.md` (bagian 6 oleh Dev; 4b oleh orchestrator), `assets/LICENSES.md` (baru). `DEV_PHASES.md` dicentang orchestrator setelah PR dibuka, untuk tugas yang terbukti. Tidak ada keputusan di ROADMAP bagian 5 yang ditutup oleh run ini.
