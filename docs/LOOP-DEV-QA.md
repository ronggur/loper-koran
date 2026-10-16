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
| **Satu sesi Claude Code per run; `/clear` atau sesi baru di antara run.** | Setiap giliran membawa seluruh riwayat percakapan. Semua keadaan penting sudah ada di repo (rule, `ROADMAP.md` 4b, `DEV_PHASES.md`, `SPEC.md`, `LOG.md`), jadi sesi baru tidak kehilangan apa-apa dan jauh lebih hemat token. Detail di Bagian 0c. |
| **Tidak ada aksi keluar tanpa persetujuan.** | Selama loop: tidak push, tidak merge, tidak mengubah akun atau layanan di luar repo. PR dibuka orchestrator **setelah laporan akhir dan konfirmasi pemilik**. |

> **Pengecualian yang disengaja terhadap `git-workflow.mdc`.** Rule itu meminta pekerjaan selesai langsung di-push. Untuk run loop, push ditunda sampai pemilik mengonfirmasi laporan akhir (permintaan pemilik, mengikuti brief Pantow). Semua aturan lain di `git-workflow.mdc` tetap berlaku: branch dari `main` terbaru, tidak pernah ke `main`, tidak merge sendiri.

---

## 0b. Lingkungan (kondisi per 2026-10-09, periksa ulang di awal run)

| Alat | Status saat ini | Konsekuensi |
|---|---|---|
| Godot 4.7.2 | Terpasang lewat Homebrew (`/opt/homebrew/bin/godot`, sejak run 0A) | Kalau tidak ada, pemilik memasangnya, atau agent mengunduh ke folder sementara di luar repo **setelah pemilik mengizinkan**. Tanpa Godot tidak ada tes yang bisa diklaim lolos (`00-project-core`). |
| Template export Godot | Belum ada (dicek 2026-10-09, `~/Library/Application Support/Godot/export_templates/` kosong) | Dibutuhkan run 0C (sekitar 1 GB). Unduhan dari rilis resmi `godotengine/godot-builds` dengan verifikasi checksum, **setelah pemilik mengizinkan**. Pastikan mendukung target Android yang dipersyaratkan Google Play (TECH_PLAN Fase 0). |
| Java | OpenJDK 17 | Cek syarat versi JDK untuk build Android Godot yang terpilih sebelum run 0C. |
| Android SDK | Ada di `~/Library/Android/sdk` (`platform-tools`, `cmdline-tools`, `build-tools`, `emulator`, `system-images`) | Bisa dipakai untuk emulator dan `adb`. |
| `adb` | `/opt/homebrew/bin/adb`; Samsung A54 (SM-A546E) terhubung bila dicolok (dicek 2026-10-09) | HP dipakai bersama project lain: periksa `adb devices` di awal run. Uji rasa kontrol di HP = `NEEDS-MANUAL` (QA tidak bisa merasakannya). Emulator hanya membuktikan APK terpasang dan jalan, **bukan** rasa kontrol touch. |
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

## 0c. Aturan sesi (satu sesi per run)

- **Mulai tiap run di sesi baru** (atau `/clear`), dari `main` yang sudah memuat PR run sebelumnya. Sesi baru memuat `CLAUDE.md` dan `.cursor/rules/` otomatis. Jangan melanjutkan run 0B di sesi yang sama dengan run 0A.
- **Jangan `/clear` di tengah run.** Dev dan QA sudah subagent berkonteks segar; orchestrator hanya memegang pointer ke `LOG.md`, jadi sesinya ringan.
- **Run selesai** = PR sudah dibuka dan `DEV_PHASES.md` dicentang (Bagian 1 langkah 4). Setelah itu aman `/clear`. Pemilik me-merge PR sebelum run berikutnya dimulai.
- **Sebelum clear, tulis dulu ke file** semua keputusan atau preferensi baru yang hanya ada di chat (ke `ROADMAP.md` 4b, rule `.cursor/rules/`, atau `SPEC.md`). Yang tidak ditulis akan hilang.
- **Kalau terpaksa berhenti di tengah run**: orchestrator memperbarui `LOG.md` (status, iterasi saat ini, langkah berikutnya) lalu pemilik membuka sesi baru dengan "lanjutkan run `<RUN_ID>`". Orchestrator membaca `SPEC.md` + `LOG.md` + `git log` branch dan melanjutkan dari iterasi terakhir. Skill `handoff` boleh dipakai untuk membuat `HANDOFF.md`.
- **Jika loop dijalankan sebagai Workflow** (skrip multi-agent): satu pemanggilan Workflow = satu run = satu sesi. Workflow juga hanya membaca file di repo, bukan riwayat chat; tiap agent() menerima prompt dari Bagian 2 dan 4. Batas 2 iterasi ditulis di skrip, dan hasil akhir tetap `LOG.md`. Gunakan `resumeFromRunId` untuk melanjutkan run yang terhenti, bukan memulai ulang.

---

## 1. Prompt Orchestrator (tempel ini)

```text
Kamu adalah ORCHESTRATOR loop Dev↔QA untuk repo Loper Koran. Ikuti
docs/LOOP-DEV-QA.md secara ketat. Sesi ini hanya untuk SATU run (Bagian 0c).
Kalau saya menulis "lanjutkan run <RUN_ID>", baca SPEC.md + LOG.md + git log
branch run itu dan lanjutkan dari iterasi terakhir, jangan mulai ulang.

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
   c. Baca keputusan yang sudah dikunci (ROADMAP 4b: skala ×3, Godot 4.7.2, stretch,
      package `com.rmh.kring`) dan jangan menanyakannya lagi. Kumpulkan keputusan
      terbuka lain yang MENGHAMBAT scope ini (ROADMAP 5), dan tanyakan ke pemilik
      dalam SATU pesan dengan satu rekomendasi per keputusan. Jangan memutuskan
      sendiri.
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
5. Tutup run: tulis ke file semua keputusan baru yang hanya ada di chat, lalu
   katakan "run selesai, aman /clear; mulai run berikutnya di sesi baru setelah
   PR di-merge" dan sebut RUN_ID run berikutnya.
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

## 6. Fase 0 dipecah jadi tiga run (0B dan 0C dijalankan sebagai satu run)

Urutan berurutan; satu PR per run, run berikutnya dimulai dari `main` setelah PR sebelumnya di-merge pemilik. Hanya satu fase kode aktif (`DEV_PHASES.md`).

> **Keputusan pemilik, 2026-10-09:** run 0B dan 0C **digabung** jadi satu run (`RUN_ID` `20261009-fase0bc-input-export`, satu branch, satu PR). Ini mengesampingkan "jangan menggabungkan" di Bagian 7. Alasannya: Fase 0 baru bisa ditutup kalau APK terpasang di HP dan sepeda bergerak dengan stick, jadi dua run terpisah menunda uji HP tanpa menambah keamanan. Aturan yang tetap berlaku untuk run gabungan: batas 2 iterasi dan satu QA per iterasi tidak berubah; bila konteks Dev terancam habis, boleh dua pemanggilan Dev berurutan di iterasi 1 (0B lalu 0C) sebelum QA. Risikonya (token sekitar dua kali run 0A, PR lebih besar, `ESCALATED` lebih mungkin) diterima pemilik. Bagian "Run 0B" dan "Run 0C" di bawah tetap menjadi daftar isinya.

### Run 0A — Fondasi project (`RUN_ID` mis. `20261009-fase0a-fondasi`)

**Keputusan yang sudah dikunci (ROADMAP 4b, 2026-10-09):** Godot 4.7.2, skala ×3, base 640×360 dengan stretch `canvas_items` + integer scale + `expand` (cadangan `viewport`), package `com.rmh.kring`. Sprite pemain baru dicek di 4.3: muat ulang `loper_agen_frames.tres` di 4.7.2.

**Prasyarat dari pemilik:** pasang Godot 4.7.2, atau izin mengunduh ke folder sementara di luar repo.

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
- AC-5: Hasil verifikasi stretch di tiga rasio layar dicatat di `ROADMAP.md` 4b (dipertahankan, atau diganti ke `viewport` dengan alasan) oleh orchestrator di commit `docs:` terpisah.
- **NEEDS-MANUAL:** tampilan di rasio 16:9, 19,5:9, 20:9 dan ketajaman piksel di layar nyata (bila belum ada HP, jalankan di jendela editor dan catat bahwa HP belum diuji).

### Run 0B — Input touch dan sepeda placeholder

**Isi:** stick melayang di zona kiri bawah, swipe di zona kanan, opsi kidal (tukar zona), keyboard untuk editor; sepeda placeholder bergerak di jalan graybox isometrik 2:1 (naik ke kanan atas), `loper_sprite.gd` memilih animasi dari gerak sebenarnya; HUD sementara kecepatan.

**Catatan:** ini sudah menyentuh sebagian Fase 1. Batasi ke "sepeda placeholder bergerak dengan stick" (kriteria M0); stamina, rem, dan pindah sisi tetap Fase 1.

**AC contoh:** logika pemetaan stick → kecepatan/arah murni di `scripts/systems/` dan dites headless (zona mati 15%, dua jari bersamaan, jari terangkat, kidal); node input tipis.
**NEEDS-MANUAL:** semua rasa kontrol di HP (ambang, ukuran zona, ketelitian swipe).

### Run 0C — Export Android dan APK

**Prasyarat dari pemilik:** izin memasang ke HP (Samsung A54, ROADMAP 4b; dipakai bersama project lain), atau keputusan memakai emulator untuk uji awal. Package sudah `com.rmh.kring`.

**Isi:** `export_presets.cfg` (landscape terkunci, tanpa keystore di repo), `SETUP_ANDROID.md` diadaptasi dari Brainy Dungeon (jangan menyalin nilai spesifik Brainy: package, keystore, plugin), APK debug ke `builds/` (tidak di-commit), pemeriksaan target API dan template export (TECH_PLAN Fase 0).

**AC contoh:** APK debug dibangun lewat perintah di `SETUP_ANDROID.md`; `aapt`/`apkanalyzer` menunjukkan package dan orientasi sesuai; tidak ada keystore/kredensial di diff; `.gitignore` menutup `builds/`.
**NEEDS-MANUAL:** APK terpasang di HP dan sepeda placeholder bergerak dengan stick — ini satu-satunya yang menutup Fase 0 dan M0 (`ROADMAP.md`). Fase 0 **tidak dicentang selesai** sebelum itu.

---

## 6b. Fase 1: perintah mulai run (tempel di sesi baru)

Disimpan 2026-10-09 supaya Fase 1 bisa dimulai tanpa menulis ulang. Tiap blok ditempel **utuh sebagai pesan pertama sesi baru** (`/clear` atau sesi baru; Bagian 0c). Isi baris bertanda `ISI:` sebelum menempel; hapus baris izin HP kalau HP tidak boleh disentuh. Tanggal di `RUN_ID` diganti kalau run dimulai di hari lain.

Prasyarat: PR run sprite lempar/melambat (`feat/sprite-lempar-melambat`) sudah di-merge ke `main`. Kalau belum, orchestrator berhenti dan minta merge dulu (branch kerja selalu dari `main` terbaru, `git-workflow.mdc`).

Bahan yang ada di `main` untuk Fase 1: `Iso`, `BikeDrive`, `TouchRouter`, `DoronganKecepatan`, scene uji `jalan_uji.tscn` (run 0B+0C); sprite `melambat` dan `lempar` terpasang (run sprite); sprite `meluncur` dan `rem` untuk lima arah ada di `docs/design/character/loper_agen/rem_meluncur/` tetapi **belum dipasang** (PR #16, usulan: pergeseran 1 px, jumlah frame dan fps tebakan, belum ada pose "berhenti").

### Run 1A — logika gerak inti

```text
Kamu adalah ORCHESTRATOR loop Dev↔QA untuk repo Loper Koran. Ikuti docs/LOOP-DEV-QA.md
secara ketat (Bagian 1 prosedur orchestrator, Bagian 0c satu sesi satu run). Mulai dari
main terbaru yang sudah memuat PR sprite lempar/melambat; kalau belum, berhenti dan minta
saya merge dulu.

SCOPE: Run 1A — Fase 1, logika gerak inti (DEV_PHASES Fase 1, TECH_PLAN Fase 1,
  BALANCING 2-3, GDD 5.2). Batasi ke butir berikut; umpan balik (debu, garis kecepatan,
  audio) dan penyetelan kamera/kontrol ada di Run 1B.
  - `BikeMotion` murni di scripts/systems/ (TECH_PLAN Fase 1): masukan stick + dt, keluaran
    kecepatan, posisi lateral, stamina, status rem. Boleh mengembangkan `BikeDrive` yang ada
    atau menggantikannya; catat pilihannya dan jaga tes lama yang masih relevan.
  - Rem tanpa tombol: stick di ujung bawah (>= 90%) ditahan 0,25 detik, berhenti dengan
    5,0 u/d² (BALANCING 2); tidak aktif saat belok diagonal; lepas stick = batal.
  - Meluncur: stick bawah menurunkan kecepatan ke 1,5 u/d, stamina pulih (BALANCING 2-3).
  - Pindah sisi sungguhan: kunci ke sisi `seberang`/`dekat` dengan batas tepi jalan
    (lebar jalan 2 ubin, lateral 3,0 u/d); nama sisi hanya seberang/dekat di kode; kidal
    tidak mengubah arti sisi. Ganti geser bebas placeholder run 0B (D-3).
  - Stamina (BALANCING 3): terkuras saat cepat/ngebut, pulih saat meluncur; efek saat habis
    mengikuti BALANCING 3; bar stamina di HUD (DESIGN_SPEC 3.5); rem menyalakan cincin
    bawah stick berwarna WARN (DESIGN_SPEC 3.7).
  - Pause: simulasi benar-benar berhenti saat app di-background/kehilangan fokus dan lanjut
    tanpa lompatan; stick dilepas bersih (sudah ada `batal_semua`).
  - Laju kayuh mengikuti kecepatan (`LoperSprite.pedal_rate`).
  - Pasang sprite `meluncur` dan `rem` (lima arah) ke SpriteFrames gabungan lewat skrip
    pembangun yang sudah ada; sambungkan ke status meluncur dan rem. Putuskan dengan satu
    REKOMENDASI TERTULIS di SPEC kapan memakai `melambat` (kayuh 4 fps) vs `meluncur` (kaki
    diam) vs `rem`; jangan menebak diam-diam, dan jangan menggambar PNG sendiri.
  - Tes headless untuk semua logika murni (ambang rem, tahan, lepas di tengah, dua jari,
    diagonal, stamina habis dan pulih, pause, batas jalan) dengan mutan nyata.
  Keputusan terbuka yang menghambat? Tanyakan SEKALI dengan satu rekomendasi per keputusan.
HASIL UJI HP SEBELUMNYA (ISI: tempel catatan saya dari A54; kosongkan bila tidak ada):
  ISI: dorongan kecepatan 28/20 px dan respon 0,35 dtk terasa ...; ukuran stick/tombol kidal ...;
  melambat dan lempar ...; ambang swipe lempar 12 px ...
DESIGN: docs/design/DESIGN_SPEC.md (token bagian 1, HUD 3.5, kontrol 3.7); belum ada mockup
  layar lain — Dev boleh mendesain hanya untuk layar dev/jalan uji.
IZIN HP: boleh memasang APK ke Samsung A54 (RRCWA05E2NN) setelah QA PASS; hanya
  orchestrator yang menyentuh HP; cek layar menyala dulu; tidak ada pm clear/uninstall.
RUN_ID: 20261010-fase1a-gerak
```

### Run 1B — umpan balik, penyetelan, dan penutup Fase 0

```text
Kamu adalah ORCHESTRATOR loop Dev↔QA untuk repo Loper Koran. Ikuti docs/LOOP-DEV-QA.md
secara ketat. Mulai dari main terbaru yang sudah memuat PR Run 1A; kalau belum, berhenti
dan minta saya merge dulu.

SCOPE: Run 1B — Fase 1, umpan balik kecepatan dan penyetelan, sekaligus menutup butir Fase 0
  yang tersisa (cek light 2D/glow/partikel/shader di renderer Compatibility pada A54).
  - Debu roda dan garis kecepatan (placeholder, partikel dari kode); catat hasil cek light 2D,
    glow, partikel, dan shader warna bayangan di Compatibility pada A54 sebagai bukti
    (tangkapan layar + log) — ini menutup butir "Cek apakah light 2D ..." yang dipindah
    dari Fase 0 ke Fase 1 pada 2026-10-13 (Q-014).
  - Audio placeholder (SOUND_DESIGN 3.2): kayuhan loop dengan pitch 1,0 / 1,15 / 1,3,
    meluncur, rem. Dibuat lewat skrip di tools/ (sintesis sederhana) atau tanyakan saya;
    JANGAN mengunduh aset dari internet. Ikuti TECH_PLAN 3.1 untuk autoload `Audio` dan
    gotcha autoload di tes headless (rule gdscript). Berhenti saat app di-background.
  - Ikon jeda sementara dan tombol jeda di luar zona stick/swipe (ui-scenes).
  - Penyetelan dari uji A54: posisi sepeda lebih rendah di bingkai (usulan di DEV_PHASES
    Fase 1; jangan menaikkan geser maju dorongan melewati sekitar 43 px tanpa itu), ukuran
    stick dan tombol kidal (38 dp, di bawah 44 dp), teks HUD 6 px, angka dorongan; semua
    lewat Config + BALANCING, tanpa mengubah skala x3.
  - Perbarui checklist uji HP (docs/SETUP_ANDROID.md bagian 8) untuk uji 3-5 orang Fase 1.
  Fase 1 baru selesai setelah uji 3-5 orang di HP (butir NEEDS-MANUAL); jangan dicentang
  sebelum itu.
HASIL UJI HP SEBELUMNYA (ISI: tempel catatan dari uji Run 1A di A54):
  ISI: rem ..., pindah sisi ..., stamina ..., meluncur/rem sprite ...
DESIGN: docs/design/DESIGN_SPEC.md (token bagian 1, HUD 3.5, kontrol 3.7).
IZIN HP: boleh memasang APK ke Samsung A54 (RRCWA05E2NN) setelah QA PASS; hanya
  orchestrator yang menyentuh HP; cek layar menyala dulu; tidak ada pm clear/uninstall.
RUN_ID: 20261010-fase1b-umpan-balik
```

## 6c. Fase 2: perintah mulai Run 2B (tempel di sesi baru)

Disimpan 2026-10-15, sesudah run 2A (PR #24) dan run arah bebas (`20261015-fase2-arah-bebas`, PR #25). Tempel blok ini **utuh sebagai pesan pertama sesi baru** (`/clear` atau sesi baru; Bagian 0c). Sebelum menempel, isi baris `ISI:`, hapus baris izin HP kalau HP tidak boleh disentuh, dan ganti tanggal di `RUN_ID` kalau run dimulai di hari lain.

Prasyarat: PR #25 (`feat/lempar-arah-bebas`) sudah di-merge ke `main`. Kalau belum, orchestrator berhenti dan minta merge dulu.

### Run 2B — mode bantu, bunyi lempar dan mendarat, penutup Fase 2

```text
Kamu adalah ORCHESTRATOR loop Dev↔QA untuk repo Loper Koran. Ikuti docs/LOOP-DEV-QA.md
secara ketat (Bagian 1 prosedur orchestrator, Bagian 0c satu sesi satu run). Mulai dari
main terbaru yang sudah memuat PR #25 (arah lempar bebas); kalau belum, berhenti dan minta
saya merge dulu.

SCOPE: Run 2B — Fase 2, butir yang tersisa (DEV_PHASES Fase 2, TECH_PLAN Fase 2, GDD 5.3,
  SOUND_DESIGN 3.1 dan 4.2, BALANCING 4-5), lalu menyiapkan penutup Fase 2 dan M1.
  - Mode bantu (GDD 5.3, rule ui-scenes: wajib ada dan sepenuhnya bisa dimainkan):
    tap di sisi layar melempar otomatis ke kotak surat terdekat di sisi itu; kecepatan
    otomatis. Logika pemilihan sasaran murni di scripts/systems/ dan memakai ThrowSolver
    yang sama (garis bidik dan hasil satu lintasan, warisan kecepatan tetap). Sakelar mode
    bantu di HUD dev (seperti tombol kidal) karena layar pengaturan belum ada. Kidal tetap
    berlaku. Rumah bukan pelanggan tampil abu-abu hanya di mode bantu bila radar sudah ada
    (radar baru Fase 3, jadi cukup dicatat).
  - Bunyi lempar dan mendarat placeholder (SOUND_DESIGN 3.1, 4.2): "wus" saat koran
    dilempar; mendarat di kotak surat, teras, rumput/halaman, dan meleset, tiga variasi per
    permukaan. Dibuat lewat skrip sintesis di tools/audio_art/ (stdlib, deterministik,
    seperti sintesis_sepeda.py) atau tanyakan saya; JANGAN mengunduh aset dari internet.
    Lewat autoload Audio; berhenti saat jeda dan background. Nada naik combo ditunda ke
    Fase 3 (skor dan combo belum ada); catat saja.
  - QA-008 run 2A (DEFERRED): oracle tes GambarPiksel.perintah_pola harus independen
    (warna dan alpha harapan ditulis eksplisit, bukan memanggil perintah_pola); empat mutan
    QA N16, N20, N21, N22 harus mati.
  - QA-005 run arah bebas (DEFERRED): mock docs/design/source/kontrol.html (dan render
    kontrol.png, kontrol-board.png bila dirender ulang lewat alat yang ada) serta tabel
    DESIGN_SPEC 6 masih menulis "swipe kiri = seberang, kanan = dekat"; perbarui ke arah
    bebas. Juga QA-006 (Nit): GDD 4.2 "jatuh di sisi seberang" → "mengarah ke".
  - Perbarui checklist uji HP (docs/SETUP_ANDROID.md bagian 8) untuk penutup Fase 2: kotak
    surat bisa dikenai dengan sengaja di santai, cepat, dan ngebut; ketelitian swipe
    pendek; mode bantu; bunyi lempar dan mendarat; dua pertanyaan kontrol GDD 17.
  - Tes headless untuk semua logika murni dengan mutan nyata (pemilihan sasaran mode bantu,
    tidak ada sasaran di jangkauan, tap di sisi tanpa rumah, sisa koran habis, jeda antar
    lempar, jeda game, kidal, pemetaan permukaan ke bunyi, bunyi berhenti saat jeda).
  Keputusan terbuka yang mungkin menghambat (tanyakan SEKALI, satu rekomendasi per
  keputusan): kecepatan otomatis di mode bantu (tingkat mana, dan apakah stick masih bisa
  pindah sisi dan mengerem); "sisi layar" = separuh layar kiri/kanan atau zona swipe saja;
  jangkauan "kotak surat terdekat" (hanya di depan? batas jarak?); apakah lemparan mode
  bantu selalu kena atau bisa meleset; apakah jeda antar lempar 0,35 detik dan jeda lepas
  0,17 detik perlu disetel ulang dari uji HP (pemilik sempat menyebut lemparan "gak
  responsif" sebelum arah bebas).
  Fase 2 dan M1 baru selesai setelah uji HP pemilik (butir NEEDS-MANUAL); jangan dicentang
  sebelum itu.
HASIL UJI HP SEBELUMNYA (ISI: tempel catatan saya dari vivo/A54; kosongkan bila tidak ada):
  Run arah bebas di vivo V2108 (2026-10-15): "this is much better". ISI: kotak surat di tiga
  kecepatan ...; swipe pendek ...; swipe kiri murni ke belakang ...; garis bidik saat
  melaju ...; rasa responsif ...
DESIGN: docs/design/DESIGN_SPEC.md (token bagian 1, HUD 3.5, umpan balik 3.6, kontrol 3.7);
  belum ada mockup mode bantu — Dev boleh mendesain hanya untuk layar dev/jalan uji.
IZIN HP: boleh memasang APK ke vivo V2108 (adb 12d8c9da) setelah QA PASS; A54
  (RRCWA05E2NN) hanya bila tersambung. Hanya orchestrator yang menyentuh HP; cek layar
  menyala dan tidak sedang dipakai; tidak ada pm clear/uninstall/logcat -c; log Godot di
  vivo lihat SETUP_ANDROID 6.1.
RUN_ID: 20261015-fase2b-bantu-audio
```

## 6d. Fase 3: perintah mulai run (tempel di sesi baru)

Disimpan 2026-10-15, sesudah run 2B (`20261015-fase2b-bantu-audio`, PR #26). Fase 3 terlalu besar untuk satu run (Bagian 0), jadi dipecah tiga run berurutan, satu PR per run:

| Run | Isi | Prasyarat |
|---|---|---|
| 3A | Format segmen dan pemuatnya, `RouteBuilder` berseed, rumah dan pelanggan dari data, zona sasaran dan mode bantu dari data rute, objek penutup semi-transparan | PR #26 di-merge; uji HP Fase 2 (SETUP_ANDROID 8.5) sudah dilakukan atau hasilnya ditempel |
| 3B | Rintangan anjing dan mobil garasi, tabrakan, skor + combo + pengali kecepatan, nada naik combo dan denting tip | PR 3A di-merge |
| 3C | Radar, HUD rute, tenggat, layar hasil, rumah abu-abu di mode bantu, spike rumah sisi dekat, uji 20 rute | PR 3B di-merge |

**Status (2026-10-16):** Run 3A selesai, `PASSED` di iterasi 2/2, PR #28 (`feat/fase3a-rute`, `docs/loop/20261016-fase3a-rute/`), menunggu merge dan uji HP pemilik (`SETUP_ANDROID.md` 8.6). Perintah Run 3B di bawah sudah diperbarui dengan catatan dari 3A; ganti tanggal `RUN_ID` bila dimulai di hari lain dan isi baris `HASIL UJI HP` dari 8.5 dan 8.6.

Tempel satu blok **utuh sebagai pesan pertama sesi baru** (`/clear` atau sesi baru; Bagian 0c). Isi baris `ISI:` sebelum menempel, hapus baris izin HP kalau HP tidak boleh disentuh, dan ganti tanggal di `RUN_ID` kalau run dimulai di hari lain.

Catatan untuk semua run Fase 3:
- **Aset.** Ada branch kerja lain `art/aset-fase3-perumahan` (dibuat 2026-10-15 di mesin pemilik, belum di-push saat bagian ini ditulis). Kalau PR-nya sudah di-merge, pakai asetnya. Kalau belum, tetap graybox lewat `tools/env_art/graybox.py`. Jangan menunggu aset (Fase 5 boleh paralel) dan jangan menggambar PNG sendiri.
- **Fase 2 harus tertutup dulu.** Kalau uji HP Fase 2 belum dilakukan, orchestrator menanyakan sekali apakah tetap mulai (Fase 3 boleh berjalan, tapi `DEV_PHASES` Fase 2 dan M1 tetap belum dicentang).
- **Bel.** Pertanyaan pemilik 2026-10-15 "fungsi bel ada di fase berapa?": dokumen menjadwalkan bel di Fase 6–7 (SOUND_DESIGN 8, GDD 17), dan orchestrator merekomendasikan memajukannya ke Fase 3 karena fungsinya mengusir pejalan kaki dan rintangan baru masuk Fase 3. **Diputuskan pemilik 2026-10-16: bel dimajukan ke Fase 3, dikerjakan di Run 3B** (jangan ditanyakan lagi).

### Run 3A — rute dari segmen dan rumah dari data

```text
Kamu adalah ORCHESTRATOR loop Dev↔QA untuk repo Loper Koran. Ikuti docs/LOOP-DEV-QA.md
secara ketat (Bagian 1 prosedur orchestrator, Bagian 0c satu sesi satu run, Bagian 6d
catatan Fase 3). Mulai dari main terbaru yang sudah memuat PR #26 (mode bantu dan bunyi
lempar); kalau belum, berhenti dan minta saya merge dulu.

SCOPE: Run 3A — Fase 3, fondasi rute (DEV_PHASES Fase 3, TECH_PLAN Fase 3, DATA_SCHEMA 3,
  ROUTE_DESIGN 1-3 dan 7, GDD 9.1, BALANCING 5-6). Rintangan, tabrakan, skor, radar, HUD
  rute, tenggat, dan layar hasil ada di Run 3B dan 3C; jangan dikerjakan di sini.
  - Format segmen rute JSON di assets/data/routes/perumahan/ dan pemuatnya (DATA_SCHEMA 3,
    rule content-data): field wajib, id permanen, jarak dalam ubin, sisi hanya
    seberang/dekat. Kunci formatnya di DATA_SCHEMA 3 dengan contoh dari berkas nyata.
  - 8-10 segmen perumahan buatan tangan; satu rute memakai 6-8 segmen (ROUTE_DESIGN 1-3):
    jalur utama selalu bersih, distrik pertama hanya pelanggan di sisi seberang (GDD 9.1),
    rute awal sekitar 25 pelanggan (BALANCING 7, GDD 14.1). Tempat rintangan boleh sudah
    ditandai di data, tapi perilakunya Run 3B.
  - `RouteBuilder` murni di scripts/systems/: urutan segmen acak dari seed (RNG berseed,
    tanpa randi global). Seed sama = rute sama, seed beda = rute beda; jumlah pelanggan
    dan koran awal (pelanggan + 20%, BALANCING 4) dihitung dari rute.
  - Rute sungguhan menggantikan jalan uji tanpa ujung sebagai scene main (atau scene rute
    baru; putuskan dengan satu rekomendasi tertulis di SPEC): rumah pelanggan dan bukan
    pelanggan dari data, zona sasaran dari data rumah (pengganti zona placeholder
    `ZonaSasaran.zona_jalan_uji*`), akhir rute yang jelas (cukup berhenti dan tanda
    "selesai" sementara; layar hasil Run 3C). Jalan uji boleh tetap ada sebagai scene dev.
  - Mode bantu (`BantuLempar.pilih`) dan penilaian lemparan memakai zona dari data rute;
    semua tes mode bantu, lemparan, dan bunyi tetap hijau atau diperbarui dengan alasan.
  - Objek yang menutupi pemain jadi semi-transparan: aturan satu tempat di renderer,
    bukan per objek (GDD 2.3, TECH_PLAN Fase 3).
  - Validasi data di tes headless (rule content-data): field wajib, id unik, rujukan,
    aturan adil yang bisa diperiksa mesin (jalur utama bersih, pelanggan hanya seberang),
    dan 20 rute acak berseed dibangun tanpa galat (ROUTE_DESIGN 7).
  - Tes headless dengan mutan nyata dan oracle independen (pelajaran QA-008 dan QA-001
    run 2B: harapan ditulis eksplisit, bukan memanggil fungsi yang dites).
  Keputusan terbuka yang mungkin menghambat (tanyakan SEKALI, satu rekomendasi per
  keputusan): segmen JSON atau scene Godot yang diekspor (DATA_SCHEMA 5); panjang segmen
  dan rute (ROUTE_DESIGN 8); cara memetakan pelanggan tetap ke rute yang diacak
  (DATA_SCHEMA 5); scene rute baru atau jalan uji diubah; apa yang terjadi di akhir rute
  sebelum layar hasil ada. Struktur sesi dan game over (ROADMAP 5, M2) JANGAN diputuskan;
  cukup pastikan desain 3A tidak menguncinya.
HASIL UJI HP FASE 2 (ISI: tempel catatan dari SETUP_ANDROID 8.5 di vivo/A54; kosongkan
  bila belum): ISI: kotak surat santai/cepat/ngebut .../10; swipe pendek ...; responsif
  0,35/0,17 ...; mode bantu ...; bunyi ...; ambang rem ...
ASET: ISI: PR art/aset-fase3-perumahan sudah di-merge? (ya → pakai; belum → graybox).
DESIGN: docs/design/DESIGN_SPEC.md (token bagian 1, umpan balik 3.6); belum ada mockup
  layar rute penuh — Dev boleh mendesain hanya untuk layar dev/rute sementara.
IZIN HP: boleh memasang APK ke vivo V2108 (adb 12d8c9da) setelah QA PASS; A54
  (RRCWA05E2NN) hanya bila tersambung. Hanya orchestrator yang menyentuh HP; cek layar
  menyala dan tidak sedang dipakai; tidak ada pm clear/uninstall/logcat -c; log Godot di
  vivo lihat SETUP_ANDROID 6.1.
RUN_ID: 20261016-fase3a-rute
```

### Run 3B — rintangan, tabrakan, skor

```text
Kamu adalah ORCHESTRATOR loop Dev↔QA untuk repo Loper Koran. Ikuti docs/LOOP-DEV-QA.md
secara ketat (Bagian 1, Bagian 0c, Bagian 6d). Mulai dari main terbaru yang sudah memuat
PR Run 3A; kalau belum, berhenti dan minta saya merge dulu.

SCOPE: Run 3B — Fase 3, rintangan dan skor (DEV_PHASES Fase 3, TECH_PLAN Fase 3, GDD 7 dan
  9.3, ROUTE_DESIGN 4-5, BALANCING 5-6, SOUND_DESIGN 3.1 dan 4.3).
  - Anjing penjaga: mesin keadaan murni diam → waspada (menggeram, berdiri) → mengejar
    sesuai kecepatan pemain → berhenti di batas halaman (GDD 9.3).
  - Mobil keluar garasi: lampu mundur dulu, tanda minimal 1,5 detik pada kecepatan ngebut
    (ROUTE_DESIGN 4), lalu bergerak.
  - Tabrakan menghambat, tidak menghentikan rute (BALANCING 6, prinsip 2); tiap tabrakan
    bisa dijelaskan pemain.
  - Skor: nilai sasaran, combo, pengali kecepatan (BALANCING 5); skor dan koin dipisah
    (usulan BALANCING 5) — jangan memutuskan hubungannya diam-diam.
  - Bunyi: nada mendarat naik setengah nada tiap antaran beruntun sampai 5 tingkat, kembali
    ke dasar saat combo putus, denting tip (SOUND_DESIGN 3.1; ditunda dari run 2B); anjing
    menggeram/menggonggong, mobil bip dan mesin, tabrakan (placeholder lewat sintesis
    stdlib di tools/audio_art/, JANGAN mengunduh aset). Setiap bunyi punya pasangan visual.
  - Invarian prinsip desain dites: tabrakan tidak menghentikan rute; ngebut punya harga dan
    santai punya harga; tanda bahaya datang sebelum bahaya.
  - Bel "Kring Kring!" (dimajukan dari Fase 6-7 oleh pemilik 2026-10-16; GDD 5.4, SOUND_DESIGN
    3.3): tombol bel di pojok kanan bawah (kidal: kiri bawah) yang tidak memulai swipe, satu
    ketukan "kring", ketukan kedua "kring kring!", jeda sekitar 1 detik, efek visual di atas
    setang (garis getar dan teks "KRING!"), bunyi placeholder lewat sintesis stdlib; fungsinya
    mengusir/membuat minggir rintangan yang boleh diusir (GDD 9.3, 15). Pejalan kaki belum ada
    di Fase 3, jadi cukup anjing atau rintangan yang aturannya jelas di GDD. Angka usulan.
  - Tes headless dengan mutan nyata dan oracle independen.
  Keputusan terbuka yang mungkin menghambat (tanyakan SEKALI, satu rekomendasi per
  keputusan): jendela bonus atau penalti (ROADMAP 5, sekarang sakelar bawaan penalti);
  hubungan skor dan koin; aturan pasti tabrakan (BALANCING 6). Bel SUDAH diputuskan
  (pemilik 2026-10-16, Bagian 6d): masuk Run 3B, jangan ditanyakan.
CATATAN DARI RUN 3A (sudah di main sesudah PR #28 di-merge; baca LOG.md dan SPEC.md di
  docs/loop/20261016-fase3a-rute/, jangan menanyakan ulang):
  - Struktur: `AdeganJalan` = dasar bersama `JalanUji` (scene dev) dan `RuteMain`
    (scenes/rute/rute.tscn, scene utama); `RouteBuilder` -> `Rute` (`RumahRute`, `ObjekRute`,
    `TitikMisiRute`); `PemuatRute` + `SegmenRute` (validasi data); `MedanKoran` (zona dan
    penutup untuk koran, satu kelas konkret); `ZonaSasaran.zona_rute_rentang`;
    `PenutupPemain` + satu `PenerapPenutup`.
  - Rintangan SUDAH ditandai di data segmen (`objek`: jenis `anjing_penjaga` dan
    `mobil_garasi`, jalur `seberang`/`dekat`, tidak pernah `tengah`, `tanda_ubin` >= 9) tapi
    belum berperilaku dan tidak digambar hidup. Sprite sheet sudah ada:
    assets/sprites/obstacles/obs_anjing_sheet.* dan obs_mobil_garasi_sheet.* (pakai apa
    adanya, titik pijak di JSON). Aturan adil dijaga validasi `SegmenRute`/`RouteBuilder`.
  - Jebakan GDScript 4.7.2 (LOG D-14): jangan membuat `class X extends MedanKoran` lalu
    menugaskan `X.new()` ke variabel bertipe `MedanKoran`; skrip tertahan di akhir proses
    (`ERROR: ... resources still in use at exit`). Satu kelas konkret, atau komposisi.
  - Keputusan pemilik 3A yang berlaku: sesudah garis akhir swipe dan tap bantu ditolak
    (QA-004/D-17) sampai 3C; akhir rute sementara = berhenti + banner + tombol dev "Main
    lagi" (seed + 1); id rumah `<id_segmen>@<pos>`, pemetaan ke id save ditunda ke Fase 6;
    jendela tetap sakelar penalti; sisi dekat hanya placeholder `bukan`.
  - Aset: `tools/env_art/fase3.py --salin` di mesin ini menghasilkan drift piksel kecil pada
    berkas yang tidak diubah. Setelah render ulang, kembalikan berkas yang tidak sengaja
    berubah (cek `git status`, bandingkan piksel); jangan edit PNG dengan tangan.
  - Kotak surat sasaran sekarang sprite kotak surat oranye (PR #29, bukan lagi kubus graybox)
    di pusat zona (rumah pelanggan seberang tanpa kotak merah, QA-005); aset final = Fase 5.
    Zona halaman/teras/jendela tidak digambar di tanah rute (D-20).
  - Kotak surat sekarang AREA di RUMPUT HALAMAN (PR #30, 2026-10-16): seberang 1,0 x 1,25 dan
    dekat 0,75 x 1,25 ubin, menempel trotoar, digambar di tanah rute (`AreaKotakGambar`;
    tindak lanjut review pemilik, LOG 3A D-28 sampai D-32). Sepeda boleh naik trotoar: batas
    lateral +-2,0 ubin (tepi trotoar), bukan lagi +-1,0 (revisi D-4, BALANCING 2 dan 5);
    rintangan (anjing, mobil garasi) harus diuji dari posisi sepeda di trotoar juga.
    Pertimbangkan "inti" 0,5 x 0,5 di pusat (zona lama) sebagai kandidat bonus "tepat" di
    skor (BALANCING 5); keputusan pemilik, jangan diputuskan sendiri dan tunggu hasil uji HP
    (SETUP_ANDROID 8.6 butir 9 dan 10).
  - Variasi rute (D-1): tiap rute memakai semua 5 segmen tengah. Bila hasil uji HP 3A
    bilang terasa dihafal, tambah segmen tengah (data saja) sebelum menambah rintangan baru.
  - Pelajaran QA 3A: tes harus menjaga ketergantungan pada seed (mutan goyangan nol selamat),
    angka ajaib kecil (2) juga dihitung, dan jangkauan tes literal untuk batas medan.
HASIL UJI HP RUN 3A (ISI: tempel catatan dari SETUP_ANDROID 8.6; kosongkan bila belum dan
  orchestrator akan menanyakan sekali) dan FASE 2 (8.5): ISI: ...
DESIGN: docs/design/DESIGN_SPEC.md (token bagian 1, umpan balik 3.6).
IZIN HP: sama dengan Run 3A.
RUN_ID: 20261017-fase3b-rintangan-skor
```

### Run 3C — radar, HUD rute, tenggat, layar hasil, penutup Fase 3

```text
Kamu adalah ORCHESTRATOR loop Dev↔QA untuk repo Loper Koran. Ikuti docs/LOOP-DEV-QA.md
secara ketat (Bagian 1, Bagian 0c, Bagian 6d). Mulai dari main terbaru yang sudah memuat
PR Run 3B; kalau belum, berhenti dan minta saya merge dulu.

SCOPE: Run 3C — Fase 3, sisa butir dan penutup M2 bagian rute (DEV_PHASES Fase 3, TECH_PLAN
  Fase 3, DESIGN_SPEC 3 dan 3.4, GDD 4.3 dan 5.3, BALANCING 6).
  - Radar di tepi kiri (seberang) dan kanan (dekat) (GDD 4.3, DESIGN_SPEC 3.4); mode bantu:
    rumah bukan pelanggan tampil abu-abu `RADAR_BUKAN` (GDD 5.3, ditunda dari run 2B D-8).
  - HUD rute final ukuran DESIGN_SPEC 3: progres pelanggan, koin, sisa koran, kecepatan,
    stamina; menghormati zona aman di 16:9, 19,5:9, 20:9.
  - Tenggat rute (BALANCING 6) tanpa game over: struktur sesi dan game over masih terbuka
    (ROADMAP 5), jadi tenggat lewat hanya ditandai, tidak menghukum berlapis (prinsip 2).
  - Layar hasil sederhana: terkirim, meleset, koin, tip; dibuka dengan yang berhasil
    (rule ui-scenes), semua teks lewat translations/ui.csv.
  - Spike rumah sisi dekat (TECH_PLAN Fase 3): bandingkan tiga pendekatan di graybox,
    tangkapan layar di docs/loop/<RUN_ID>/shots/, lalu tanyakan saya untuk memutuskan
    (atau tetapkan tanggal keputusan) — jangan memutuskan sendiri.
  - Perbarui checklist uji HP (docs/SETUP_ANDROID.md bagian 8) untuk penutup Fase 3:
    20 rute dibangun, 3 dimainkan (ROUTE_DESIGN 7), rute tidak terasa dihafal setelah tiga
    kali, tiap tabrakan bisa dijelaskan, radar terbaca saat ngebut.
  - Tes headless dengan mutan nyata dan oracle independen; smoke test layar hasil.
  Keputusan terbuka yang mungkin menghambat (tanyakan SEKALI, satu rekomendasi per
  keputusan): angka tenggat; apa yang terjadi saat tenggat lewat (tanpa memutuskan game
  over); jangkauan radar bawaan; pendekatan rumah sisi dekat (setelah spike).
  Fase 3 baru selesai setelah uji HP pemilik; jangan dicentang sebelum itu.
HASIL UJI HP RUN 3B (ISI: tempel catatan; kosongkan bila tidak ada): ISI: ...
DESIGN: docs/design/DESIGN_SPEC.md (HUD 3, radar 3.4, umpan balik 3.6),
  docs/design/screens/hud-rute.png.
IZIN HP: sama dengan Run 3A.
RUN_ID: 20261018-fase3c-hud-hasil
```

## 7. Batasan yang perlu diketahui

- QA berbasis agent tidak menggantikan uji di HP nyata untuk rasa kontrol, performa, dan tampilan rasio layar. Fase gameplay selalu ditutup dengan uji manual (`DEV_PHASES.md`).
- Tanpa Godot terpasang, loop tidak bisa menghasilkan bukti tes. Jangan menjalankan loop sebelum prasyarat 0A terpenuhi.
- Keputusan terbuka (ROADMAP 5) adalah milik pemilik. Loop yang "menyelesaikan" Fase 0 dengan menebak nama package atau skala piksel menciptakan utang yang mahal (nama package tidak bisa diganti setelah upload pertama).
- Run penuh (Dev + QA × 2 iterasi) memakan token besar; mulai dari 0A, jangan menggabungkan 0A dengan run lain, dan jangan melanjutkan run berikutnya di sesi yang sama (Bagian 0c). **Pengecualian yang disetujui pemilik (2026-10-09): 0B dan 0C boleh digabung jadi satu run** (lihat Bagian 6). Menggabungkan selain itu tetap tidak dianjurkan.
