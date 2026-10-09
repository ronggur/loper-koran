# Loop Dev ↔ QA — Loper Koran

Instruksi untuk loop dua agent: **Agent 1 (Dev)** membangun, **Agent 2 (QA)** memvalidasi secara independen. Maksimal **2 iterasi** per run. Semua temuan dan perbaikan dicatat di satu file log `.md`.

Diadaptasi dari brief Pantow (`LOOP-DEV-QA.md` di folder `Apps/`) untuk repo ini: **satu repo, Godot 4 + GDScript, game landscape, tanpa backend**. Dipakai pertama kali untuk **Fase 0** (`DEV_PHASES.md`).

Cara pakai: buka Claude Code di root repo `loper-koran`, tempel **Bagian 1 (Prompt Orchestrator)** dan isi `SCOPE`. Bagian 2–5 dibaca agent masing-masing (orchestrator menyertakannya ke prompt mereka).

---

## 0. Prinsip loop

| Prinsip | Alasan |
|---|---|
| **Satu run = satu potongan kecil.** Fase 0 dipecah jadi run 0A, 0B, 0C (Bagian 6). | Satu fase penuh × 2 iterasi melebihi konteks. Selaras dengan `git-workflow`: satu branch = satu topik yang bisa di-review sekali duduk. |
| **QA tidak membaca ringkasan atau klaim Dev.** | QA hanya menerima SPEC, diff, dan hasil perintah yang ia jalankan sendiri. Agent yang diberi hipotesis cenderung mengonfirmasinya. |
| **Gerbang objektif dulu, penilaian subjektif belakangan.** | Import, tes, dan pemeriksaan keluaran Godot harus hijau sebelum QA menilai hal lain. Gagal gerbang = kembali ke Dev. |
| **Logika murni di `scripts/systems/`, dites headless.** | Hanya logika yang bisa dibuktikan oleh agent. Visual dan rasa kontrol tidak (lihat `NEEDS-MANUAL`). |
| **Setiap bug punya tes regresi** (kecuali murni visual/rasa kontrol, alasannya dicatat). | Fix tanpa tes bisa kembali. |
| **Jujur soal yang tidak bisa diuji.** | Rasa stick, ambang rem, ketelitian swipe, performa 60 fps, dan tampilan di rasio layar asli butuh HP nyata. QA menandai `NEEDS-MANUAL`, bukan `PASS` (`testing.mdc`). |
| **Berhenti dengan tegas.** | Akhir iterasi 2 dengan Blocker/Major terbuka → status `ESCALATED` dan lapor ke manusia. Tidak ada iterasi ke-3 diam-diam. |
| **Satu branch + satu PR per run, banyak commit, tidak di-squash oleh loop.** | Squash merge dilakukan user (`git-workflow`). Judul PR Conventional Commits. |
| **Tidak ada aksi keluar tanpa persetujuan.** | Selama loop: tidak push, tidak merge, tidak mengubah akun atau layanan di luar repo. PR dibuka orchestrator **setelah laporan akhir dan konfirmasi pemilik**. |

> **Pengecualian yang disengaja terhadap `git-workflow.mdc`.** Rule itu meminta pekerjaan selesai langsung di-push. Untuk run loop, push ditunda sampai pemilik mengonfirmasi laporan akhir (permintaan pemilik, mengikuti brief Pantow). Semua aturan lain di `git-workflow.mdc` tetap berlaku: branch dari `main` terbaru, tidak pernah ke `main`, tidak merge sendiri.

---

## 0b. Lingkungan (kondisi per 2026-10-09, periksa ulang di awal run)

| Alat | Status saat ini | Konsekuensi |
|---|---|---|
| Godot 4 | **Belum terpasang** (`godot` tidak ada di PATH, `/Applications/Godot.app` tidak ada) | Prasyarat run 0A: pemilik memasang Godot, atau agent mengunduh ke folder sementara di luar repo **setelah pemilik mengizinkan**. Tanpa Godot tidak ada tes yang bisa diklaim lolos (`00-project-core`). |
| Template export Godot | Belum ada | Dibutuhkan run 0C. Pastikan mendukung target Android yang dipersyaratkan Google Play (TECH_PLAN Fase 0). |
| Java | OpenJDK 17 | Cek syarat versi JDK untuk build Android Godot yang terpilih sebelum run 0C. |
| Android SDK | Ada di `~/Library/Android/sdk` (`platform-tools`, `cmdline-tools`, `build-tools`, `emulator`, `system-images`) | Bisa dipakai untuk emulator dan `adb`. |
| `adb` | `/opt/homebrew/bin/adb`, **tidak ada perangkat terhubung** | Uji di HP fisik = `NEEDS-MANUAL` sampai perangkat dicolok. Emulator hanya membuktikan APK terpasang dan jalan, **bukan** rasa kontrol touch. |
| `gh`, `python3` | Ada | Dipakai untuk PR dan alat `tools/loper_art/`. |

Aturan perangkat (dari `00-project-core`): periksa dulu apakah pemilik sedang memakai perangkat sebelum mengirim ketukan. Sebelum `pm clear` atau uninstall, cek `pm list packages` supaya tidak menghapus data yang ada. Menginstal app ke HP pemilik dilakukan hanya setelah pemilik mengizinkan.

Perintah verifikasi (macOS tanpa `godot` di PATH: `/Applications/Godot.app/Contents/MacOS/Godot`):

```bash
godot --headless --import
godot --headless --script res://tests/run_tests.gd 2>&1 | tee /tmp/tests.log
# lalu periksa: tidak ada SCRIPT ERROR / ERROR: / GAGAL, dan baris ringkasan "N lolos, 0 gagal" ada
```

Exit code Godot **tidak cukup** (`testing.mdc`): error skrip bisa lolos dengan "0 gagal".

---

## 1. Prompt Orchestrator (tempel ini)

```text
Kamu adalah ORCHESTRATOR loop Dev↔QA untuk repo Loper Koran. Ikuti
docs/LOOP-DEV-QA.md secara ketat.

SCOPE run ini:
  <isi, mis. "Run 0A: project Godot + resolusi + config.gd + sprite pemain + tes headless">
DESIGN: <path mockup di docs/design/ bila ada, atau "belum ada — Dev boleh mendesain
  hanya untuk layar dev/graybox">
RUN_ID: <yyyymmdd-slug, mis. 20261009-fase0a-fondasi>

Langkah:
1. Persiapan (kamu sendiri, tanpa subagent):
   a. Baca AGENTS.md, CLAUDE.md, dan semua .cursor/rules/*.mdc. Baca bagian
      DEV_PHASES.md dan TECH_PLAN.md untuk fase yang dikerjakan.
   b. Periksa lingkungan (Bagian 0b). Kalau Godot belum ada, hentikan dan minta
      pemilik memasangnya atau mengizinkan unduhan. Hanya sekali.
   c. Kumpulkan keputusan terbuka yang MENGHAMBAT scope ini (ROADMAP 5), dan tanyakan
      ke pemilik dalam SATU pesan dengan satu rekomendasi per keputusan. Jangan
      memutuskan sendiri: nama package, skala piksel, stretch mode, versi Godot.
   d. Tulis SPEC.md di docs/loop/<RUN_ID>/ (Bagian 3) dengan acceptance criteria
      yang bisa diuji. Minta konfirmasi bila scope ambigu — hanya sekali.
   e. Ikuti git-workflow.mdc: pindah ke main, tarik terbaru, pastikan sama dengan
      origin/main, buat branch <tipe>/<slug>, konfirmasi branch aktif. Buat LOG.md
      dari template (Bagian 5).
2. Ulangi untuk iterasi N = 1..2:
   a. Jalankan Agent 1 (Dev) via Agent tool — prompt dari Bagian 2.
      N=1: kerjakan SPEC. N>1: hanya perbaiki temuan OPEN di LOG.md.
   b. Jalankan Agent 2 (QA) via Agent tool BARU (konteks segar, bukan SendMessage
      ke Dev) — prompt dari Bagian 4. Jangan teruskan ringkasan Dev ke QA.
   c. Baca LOG.md. Jika tidak ada Blocker/Major OPEN dan semua gerbang hijau →
      status PASSED. Jika N=2 dan masih ada → status ESCALATED.
   d. Deteksi stagnasi: bila temuan yang sama muncul kembali dua kali, atau jumlah
      temuan OPEN tidak turun antar iterasi, hentikan dan eskalasi lebih awal.
3. Laporan akhir ke pemilik (≤ 25 baris): status, ringkasan perubahan, temuan
   OPEN/DEFERRED, daftar NEEDS-MANUAL (langkah uji di HP), keputusan desain yang
   diambil (supaya bisa ditolak di review), dan nama branch. Siapkan draf judul +
   deskripsi PR (format git-workflow). JANGAN push/PR/merge sebelum pemilik
   konfirmasi; setelah itu push branch dan buka PR. Merge tetap oleh pemilik.
4. Setelah PR dibuka: centang DEV_PHASES.md untuk tugas yang terbukti selesai
   (bukan yang NEEDS-MANUAL), di commit terpisah pada branch yang sama.
```

---

## 2. Instruksi Agent 1 — Developer

**Peran:** implementer. Mengerjakan item SPEC; pada iterasi ≥2 hanya memperbaiki temuan `OPEN` di `LOG.md`.

**Wajib sebelum menulis kode**
1. Baca `AGENTS.md`, `CLAUDE.md`, dan **semua** `.cursor/rules/*.mdc` yang `globs`-nya cocok dengan file yang akan disentuh (`gdscript`, `balancing`, `save-system`, `content-data`, `ui-scenes`, `art-assets`, `testing`, `docs`, dan `privacy-ads` untuk export).
2. Baca `SPEC.md` dan (iterasi ≥2) seluruh `LOG.md`.
3. Baca bagian dokumen yang relevan, bukan semuanya: `TECH_PLAN.md` Fase 0 dan 3.1, `ART_DIRECTION.md` bagian 7, `BALANCING.md` bagian 2, `docs/design/DESIGN_SPEC.md` bagian yang disentuh.
4. Urutan kerja Fase 0: **(1) project Godot + pengaturan display/impor → (2) `scripts/config.gd` + `scripts/ui/palette.gd` → (3) tes runner + pemeriksa keluaran → (4) sprite pemain + `loper_agen.tscn` → (5) input touch dan sepeda placeholder → (6) export Android.** Hanya kerjakan bagian yang masuk SPEC run ini.

**Aturan kode** (ringkasan; sumber: rule terkait)
- Tab, static typing wajib, `##` bahasa Indonesia, sisi jalan `seberang` / `dekat`. Logika di `scripts/systems/` sebagai `static func` tanpa node; node hanya menampilkan. Semua angka tuning ke `scripts/config.gd` (satu baris per konstanta, literal). Teks yang dilihat pemain lewat `tr()` / kunci terjemahan.
- Input dipisah dari logika; `InputEventScreenTouch` / `InputEventScreenDrag` dengan pelacakan `index`; keyboard hanya untuk tes di editor.
- Sprite dunia: Nearest, tanpa mipmap, Lossless, skala bulat, `snap_2d_transforms_to_pixel` aktif.
- **Jangan memutuskan** hal yang tercatat terbuka di `ROADMAP.md` bagian 5. Pakai keputusan yang diberikan pemilik di SPEC. Kalau butuh keputusan yang belum ada, catat di `LOG.md` sebagai `BLOCKED` dan lanjutkan bagian lain.
- Jangan menyalin aset dari Brainy Dungeon. Jangan mengedit PNG hasil renderer dengan tangan (`art-assets.mdc`).
- Tidak ada keystore, kredensial, `.godot/`, `build/`, APK/AAB di commit.

**Aturan desain** (hanya untuk layar dev/graybox di Fase 0; HUD final ada di fase lain)
- Ikuti `docs/design/DESIGN_SPEC.md` untuk token warna dan font. Layar dev boleh sederhana, tapi tetap memakai anchor + Container, zona aman 16:9, dan tidak memakai hex langsung di scene.
- Zona stick dan swipe, ukuran target sentuh, dan zona mati stick mengikuti `ui-scenes.mdc` dan `BALANCING.md` 2.

**Gerbang yang harus hijau sebelum menyerahkan ke QA** (jalankan sendiri, tempel ringkasan di `LOG.md`)
- `godot --headless --import` tanpa error.
- `godot --headless --script res://tests/run_tests.gd` dengan pemeriksaan keluaran (Bagian 0b): tidak ada `SCRIPT ERROR` / `ERROR:` / `GAGAL`, ringkasan `N lolos, 0 gagal` ada.
- Proyek terbuka tanpa error/warning baru: `godot --headless --path . --quit-after 2` (atau setara) dan baca keluarannya.
- Bila menyentuh `tools/loper_art/*.py`: render ulang dan commit hasilnya bersama (satu commit).

**Pada iterasi ≥2**
- Per temuan: `OPEN → FIXED`, isi kolom *Fix* (apa yang diubah, file, commit) dan *Test* (tes regresi). Jangan menandai `VERIFIED` — itu hak QA.
- Jangan mengerjakan hal di luar temuan. Bila temuan keliru atau tidak bisa direproduksi, beri alasan tertulis, status `DISPUTED` (QA memutuskan).

**Commit:** kecil dan sering, di branch kerja, **tidak pernah di `main`**. Format `<tipe>: <ringkasan>` (`feat`, `fix`, `tune`, `art`, `docs`, `test`, `chore`), bahasa Indonesia. Boleh memakai `.uid` dan `.import` hasil Godot; jangan commit `.godot/`. **Tidak push.**

**Output ke orchestrator:** hanya "selesai iterasi N" + path `LOG.md`. Detail ada di log.

---

## 3. SPEC.md — format acceptance criteria

Ditulis orchestrator sebelum iterasi 1; kontrak bagi Dev **dan** QA. Contoh isi untuk run 0A ada di Bagian 6.

```markdown
# SPEC — <RUN_ID>
## Tujuan
## Keputusan dari pemilik (dengan tanggal)
- Versi Godot, stretch mode, resolusi dasar, nama package (bila relevan)
## Di luar scope
## Kriteria penerimaan (bisa diuji)
- AC-1: ...  (satu kalimat, bisa dibuktikan lewat perintah atau tes)
## Perubahan file/struktur yang diharapkan
## Tes yang harus ada
## Butuh uji perangkat nyata (NEEDS-MANUAL)
## Dokumen yang ikut diperbarui (README docs, ROADMAP 5, DEV_PHASES)
```

---

## 4. Instruksi Agent 2 — QA / Validator

**Peran:** auditor independen dan skeptis. Tugas: **menemukan alasan kerja Dev belum layak**, bukan membenarkannya. Tidak menulis kode fitur; hanya boleh menulis **tes** reproduksi bila membantu membuktikan bug (tandai sebagai tes gagal yang menunggu fix, atau lampirkan langkah reproduksi).

**Input yang boleh dibaca:** `SPEC.md`, `docs/design/*`, `git diff main...HEAD`, `LOG.md`, kode, dan semua rule. **Dilarang** mengandalkan klaim "sudah beres" dari Dev — verifikasi sendiri.

**Prosedur (urut; kembali ke Dev bila Tahap 1 gagal)**

1. **Gerbang objektif** — jalankan sendiri dan catat keluaran ringkas:
   - `godot --headless --import`; `run_tests.gd` dengan pemeriksaan keluaran (Bagian 0b).
   - Kebersihan repo: tidak ada secret/keystore/`.godot/`/`build/`/APK di diff; tidak ada commit di `main`; commit sesuai format dan bahasa; file `.uid`/`.import` hadir bila Godot membuatnya.
   - Kalau Godot tidak tersedia, **nyatakan itu** dan tandai semua klaim tes sebagai tidak terverifikasi. Jangan menyatakan lolos.
2. **Kepatuhan SPEC** — telusuri tiap AC: kode + tes yang membuktikannya. AC tanpa bukti = temuan.
3. **Review kode terhadap rule**
   - `gdscript.mdc`: static typing, tidak ada angka ajaib, logika murni di `systems/`, tidak ada `kiri`/`kanan` untuk sisi jalan, RNG berseed, pemisahan input dari logika, penanganan pause/background.
   - `balancing.mdc`: `config.gd` satu baris per konstanta, literal, satuan benar, angka sama dengan `BALANCING.md` (atau dokumen diperbarui).
   - `ui-scenes.mdc` / `art-assets.mdc`: anchor + Container, tanpa hex di scene, impor Nearest/Lossless/tanpa mipmap, penamaan file, tidak ada aset dari Brainy Dungeon, tidak ada PNG hasil renderer yang diedit manual.
   - `content-data.mdc` / `save-system.mdc`: id permanen, tidak ada teks pemain tertanam di kode, simpan hanya di akhir hari.
   - Keputusan terbuka (ROADMAP 5) **tidak dipilih diam-diam**: nilai yang dipakai harus sama dengan yang dicatat pemilik di SPEC.
   - Edge case input touch: dua jari bersamaan (stick + swipe), jari terangkat di tengah gerak, zona mati stick, opsi kidal menukar zona, perilaku saat app di-background.
4. **Validasi visual** (bila ada scene yang bisa dijalankan): jalankan non-headless (editor atau `godot --path .`), dan bila bisa ambil tangkapan layar ke `docs/loop/<RUN_ID>/shots/iter<N>/` (mis. Movie Maker mode `--write-movie` atau `screencapture`). Periksa: piksel tajam (tanpa blur), jalan naik ke kanan atas, sprite pemain memilih arah dan kecepatan yang benar, tampilan di 16:9, 19,5:9, dan 20:9. Bila tidak bisa dijalankan, **nyatakan eksplisit** dan nilai lewat review kode; jangan mengaku sudah melihat layar yang tidak pernah dijalankan.
5. **Regresi** — tes lama tetap lulus; tidak ada tes dihapus/di-skip tanpa alasan.
6. **Tulis hasil ke `LOG.md`** — satu baris tabel per temuan (ID, severity, lokasi, deskripsi + langkah reproduksi/bukti). Temuan `FIXED` dari iterasi sebelumnya: reproduksi ulang → `VERIFIED` atau kembalikan `OPEN` dengan catatan. Hal yang tak bisa diuji di sini → `NEEDS-MANUAL` dengan langkah uji di HP.

**Severity**

| Level | Arti | Boleh lolos? |
|---|---|---|
| **Blocker** | Proyek tidak terbuka/crash, tes merah atau error skrip tersembunyi, kredensial/keystore di commit, commit di `main`, AC inti tidak jalan | Tidak |
| **Major** | Perilaku salah, melanggar rule atau prinsip desain, keputusan terbuka diputuskan diam-diam, logika kritis tanpa tes | Tidak |
| **Minor** | Polesan kecil, penamaan, komentar | Boleh `DEFERRED` dengan catatan |
| **Nit** | Preferensi gaya | Dicatat saja |

**Kriteria PASS iterasi:** semua gerbang hijau **dan** tidak ada Blocker/Major berstatus `OPEN`/`FIXED`/`DISPUTED`. `NEEDS-MANUAL` tidak menghalangi PASS, tapi **harus** muncul di laporan akhir dan Fase **tidak boleh dicentang selesai** sampai uji itu dilakukan.

**Output ke orchestrator:** `PASS` atau `FAIL` + jumlah temuan per severity + path `LOG.md`.

---

## 5. Template `LOG.md` (`docs/loop/<RUN_ID>/LOG.md`)

```markdown
# Loop Log — <RUN_ID>
Scope: …  ·  Branch: <…>  ·  Mulai: <tanggal>  ·  Godot: <versi>

## Status: IN_PROGRESS | PASSED | ESCALATED   (iterasi saat ini: N/2)

## Ringkasan iterasi
| Iter | Dev menyelesaikan | Gerbang (import/tes/keluaran) | QA verdict | Temuan baru | Terverifikasi |
|---|---|---|---|---|---|
| 1 | … | ✅/❌ | FAIL | 5 | 0 |

## Temuan
Status: OPEN → FIXED (Dev) → VERIFIED (QA) | DISPUTED | DEFERRED | NEEDS-MANUAL | BLOCKED

| ID | Iter | Sev | Lokasi | Temuan & reproduksi/bukti | Status | Fix (file/commit) | Tes regresi |
|---|---|---|---|---|---|---|---|
| G-001 | 1 | Major | scripts/config.gd:12 | Konstanta ditulis multi-baris, melanggar balancing.mdc; repro: … | VERIFIED | satu baris, `abc123` | run_tests "config satu baris" |

## NEEDS-MANUAL (uji di HP)
- [ ] Langkah, hasil yang diharapkan

## Keputusan & catatan
- Keputusan pemilik: …
- Dev DISPUTED G-00x: alasan … → putusan QA: …
```

---

## 6. Fase 0 dipecah jadi tiga run

Urutan berurutan; satu PR per run, run berikutnya dimulai dari `main` setelah PR sebelumnya di-merge pemilik. Hanya satu fase kode aktif (`DEV_PHASES.md`).

### Run 0A — Fondasi project (`RUN_ID` mis. `20261009-fase0a-fondasi`)

**Prasyarat dari pemilik (ditanyakan orchestrator sekali, dengan rekomendasi):**
- Pasang Godot, atau izin mengunduh ke folder sementara. TECH_PLAN usul kunci ke satu versi 4.7.x (sprite pemain baru dicek di 4.3: muat ulang `loper_agen_frames.tres` di versi terpilih).
- Stretch mode: `canvas_items` + skala bulat atau `viewport` 640×360 (ART_DIRECTION 7). Skala piksel ×3 atau ×4.
- Nama package Android: bisa ditunda ke run 0C, tapi harus ada sebelum export.

**Isi (dari `DEV_PHASES.md` Fase 0):**
- `project.godot` landscape, renderer Compatibility; `docs/.gdignore` sudah ada.
- Resolusi dasar dan stretch sesuai keputusan; `snap_2d_transforms_to_pixel` aktif; filter Nearest tanpa mipmap untuk sprite dunia.
- `scripts/config.gd` dengan angka awal dari `BALANCING.md` 2 (kecepatan, akselerasi, rem, zona mati, kecepatan lateral), satu baris per konstanta.
- `scripts/ui/palette.gd` dari token `DESIGN_SPEC.md` 1.1 dan `assets/palette/loper_master.gpl`; font Lexend dan Lilita One dengan catatan lisensi di `assets/LICENSES.md` (font belum dikunci, ART_DIRECTION 11: tandai usulan).
- Sprite pemain disalin dari `docs/design/character/loper_agen/` ke `assets/sprites/loper/`, scene `loper_agen.tscn`, dan skrip pemilih animasi `kecepatan_arah` (`loper_sprite.gd`).
- Ubin graybox (aspal, trotoar, rumput) dan kotak graybox rumah dan kotak surat di `_placeholder/`.
- `tests/run_tests.gd` + skrip pemeriksa keluaran di `tools/` + CI sederhana (`.github/workflows/`), keluaran ringkasan `N lolos, 0 gagal`.
- Perintah di `00-project-core.mdc` dan `AGENTS.md` diperbarui sesuai kenyataan (versi Godot, perintah tes).

**AC contoh:**
- AC-1: `godot --headless --import` selesai tanpa error pada clone bersih.
- AC-2: `run_tests.gd` lolos dengan pemeriksa keluaran dan memuat tes untuk: parser `config.gd` (satu baris, literal), pemilih tingkat dan arah sprite (ambang 33% / 80%, sudut 22,5° / 67,5°, `BALANCING.md` 2), dan keberadaan semua frame animasi di `SpriteFrames`.
- AC-3: Tidak ada angka tuning di luar `config.gd`; tidak ada hex di scene/skrip selain `palette.gd`.
- AC-4: Pengaturan impor sprite dunia: Nearest, tanpa mipmap, Lossless; `snap_2d_transforms_to_pixel` aktif.
- AC-5: Keputusan pemilik (versi Godot, stretch, skala) tercatat di `ROADMAP.md` 5 dan `TECH_PLAN.md` Fase 0 oleh orchestrator di commit `docs:` terpisah.
- **NEEDS-MANUAL:** tampilan di rasio 16:9, 19,5:9, 20:9 dan ketajaman piksel di layar nyata (bila belum ada HP, jalankan di jendela editor dan catat bahwa HP belum diuji).

### Run 0B — Input touch dan sepeda placeholder

**Isi:** stick melayang di zona kiri bawah, swipe di zona kanan, opsi kidal (tukar zona), keyboard untuk editor; sepeda placeholder bergerak di jalan graybox isometrik 2:1 (naik ke kanan atas), `loper_sprite.gd` memilih animasi dari gerak sebenarnya; HUD sementara kecepatan.

**Catatan:** ini sudah menyentuh sebagian Fase 1. Batasi ke "sepeda placeholder bergerak dengan stick" (kriteria M0); stamina, rem, dan pindah sisi tetap Fase 1.

**AC contoh:** logika pemetaan stick → kecepatan/arah murni di `scripts/systems/` dan dites headless (zona mati 15%, dua jari bersamaan, jari terangkat, kidal); node input tipis.
**NEEDS-MANUAL:** semua rasa kontrol di HP (ambang, ukuran zona, ketelitian swipe).

### Run 0C — Export Android dan APK

**Prasyarat dari pemilik:** nama package final; izin memasang ke HP (dan HP dicolok), atau keputusan memakai emulator untuk uji awal.

**Isi:** `export_presets.cfg` (landscape terkunci, tanpa keystore di repo), `SETUP_ANDROID.md` diadaptasi dari Brainy Dungeon (jangan menyalin nilai spesifik Brainy: package, keystore, plugin), APK debug ke `builds/` (tidak di-commit), pemeriksaan target API dan template export (TECH_PLAN Fase 0).

**AC contoh:** APK debug dibangun lewat perintah di `SETUP_ANDROID.md`; `aapt`/`apkanalyzer` menunjukkan package dan orientasi sesuai; tidak ada keystore/kredensial di diff; `.gitignore` menutup `builds/`.
**NEEDS-MANUAL:** APK terpasang di HP dan sepeda placeholder bergerak dengan stick — ini satu-satunya yang menutup Fase 0 dan M0 (`ROADMAP.md`). Fase 0 **tidak dicentang selesai** sebelum itu.

---

## 7. Batasan yang perlu diketahui

- QA berbasis agent tidak menggantikan uji di HP nyata untuk rasa kontrol, performa, dan tampilan rasio layar. Fase gameplay selalu ditutup dengan uji manual (`DEV_PHASES.md`).
- Tanpa Godot terpasang, loop tidak bisa menghasilkan bukti tes. Jangan menjalankan loop sebelum prasyarat 0A terpenuhi.
- Keputusan terbuka (ROADMAP 5) adalah milik pemilik. Loop yang "menyelesaikan" Fase 0 dengan menebak nama package atau skala piksel menciptakan utang yang mahal (nama package tidak bisa diganti setelah upload pertama).
- Run penuh (Dev + QA × 2 iterasi) memakan token besar; mulai dari 0A, jangan menggabungkan 0A–0C.
