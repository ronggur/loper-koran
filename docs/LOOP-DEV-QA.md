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

**Status (2026-10-16):** Run 3A selesai, `PASSED` di iterasi 2/2, PR #28 (`feat/fase3a-rute`, `docs/loop/20261016-fase3a-rute/`), menunggu merge dan uji HP pemilik (`SETUP_ANDROID.md` 8.6). Perintah Run 3B di bawah sudah diperbarui dengan catatan dari 3A; ganti tanggal `RUN_ID` bila dimulai di hari lain dan isi baris `HASIL UJI HP` dari 8.5 dan 8.6. Run 3B selesai 2026-10-16, `PASSED` di iterasi 2/2, PR #32 (`feat/fase3b-rintangan-skor`, `docs/loop/20261017-fase3b-rintangan-skor/`), APK terpasang di vivo V2108, menunggu merge dan uji HP pemilik (`SETUP_ANDROID.md` 8.7). Perintah Run 3C di bawah memuat catatan dari 3B. Run 3C selesai 2026-10-17, `PASSED` di iterasi 2/2, PR #33 (`feat/fase3c-hud-hasil`, `docs/loop/20261018-fase3c-hud-hasil/`); keputusan pemilik K-1 tenggat 1,15× santai + tip hilang sesudah tenggat, K-2 radar 30 ubin, K-3 bel 1 ubin ke belakang, K-5 rumah sisi dekat tembok rendah; APK dibangun, belum terpasang (vivo tidak tersambung); Fase 3 menunggu uji HP pemilik (`SETUP_ANDROID.md` 8.8, juga 8.5–8.7). Fase berikutnya: Fase 4 (halaman depan koran dan misi kucing), perintah run belum ditulis.

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
    tindak lanjut review pemilik, LOG 3A D-28 sampai D-32; DIGANTI 2026-10-22: persegi area
    tidak digambar lagi di rute karena pemain mengira hanya area itu yang dinilai, zona dan
    penilaian tidak berubah, `AreaKotakGambar` dihapus). Sepeda boleh naik trotoar: batas
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
CATATAN DARI RUN 3B (sudah di main sesudah PR #32 di-merge; baca SPEC.md dan LOG.md di
  docs/loop/20261017-fase3b-rintangan-skor/, jangan menanyakan ulang):
  - Keputusan pemilik 2026-10-16: K-1 tabrakan BALANCING 6 (1,0 u/d, oleng 0,6, kebal 1,0,
    combo putus, tanpa game over), rintangan hanya separuh jalan sisinya; K-2 skor dan koin
    dihitung terpisah (koin 15 per antaran sah + tip 5); K-3 bel membuat anjing mundur;
    K-4 bonus tepat x1,25 aktif. Usulan orchestrator O-1..O-5 (satu antaran per pelanggan,
    halaman koin penuh, 30% pemberi tip berseed, bantu tanpa tepat, pengali dari kecepatan
    sebenarnya) berlaku sampai pemilik menolaknya di review PR #32.
  - HUD 3B = HUD dev sementara (skor, combo, koin); HUD final menggantikannya di 3C.
    QA-007 (DEFERRED ke 3C): tombol dev Kidal/Bantu di strip atas menutupi sebagian mobil
    seberang saat tanda lampu mundur; selesaikan saat menata HUD final.
  - Masih terbuka: D-5 jangkauan bel 1 ubin ke belakang (QA-008, tanyakan pemilik bila belum
    diputuskan di review PR #32); QA-012 (arah umpan melayang) dan QA-013 (label PUTUS) Minor
    celah tes, boleh ditutup di 3C bila menyentuh berkas yang sama.
  - Layar hasil memakai angka dari `SkorRute` (terkirim, meleset, koin, tip, skor); jangan
    menghitung ulang di UI.
HASIL UJI HP RUN 3B (ISI: tempel catatan dari SETUP_ANDROID 8.7, juga 8.5 dan 8.6 bila ada;
  kosongkan bila belum): ISI: ...
DESIGN: docs/design/DESIGN_SPEC.md (HUD 3, radar 3.4, umpan balik 3.6),
  docs/design/screens/hud-rute.png.
IZIN HP: sama dengan Run 3A.
RUN_ID: 20261018-fase3c-hud-hasil
```

## 6e. Fase 4: perintah mulai run (tempel di sesi baru)

Disimpan 2026-10-17, sesudah run 3C (PR #33) dan PR lanjutan #34 (mobil di celah samping rumah, kotak surat abu-abu), #35 (variasi kendaraan dan kucing, usulan), #36 (tabrakan = jatuh), #37 (ubin, lampu, pohon, usulan). Fase 4 dipecah dua run berurutan, satu PR per run:

| Run | Isi | Prasyarat |
|---|---|---|
| 4A | Format misi dan headline + pemuat, `HeadlineManager`, layar halaman depan koran (Ambil/Lewati, Berangkat), alur satu hari Koran → Rute → Hasil → hari berikutnya, `SaveManager` v1 + migrasi, flag, headline hari 1–3 | PR #37 di-merge (semua PR Fase 3 sudah di `main`) |
| 4B | Misi P1 Kucing Bu Ratmi (template Cari: tiga titik, petunjuk dari lemparan tepat, menepi, batas 12 rumah), HUD misi + banner, flag lanjutan → headline besok, rekap misi di layar hasil, tutorial terpandu (usulan) | PR 4A di-merge |

Catatan untuk semua run Fase 4:
- **Fase 3 belum tertutup.** Uji HP 8.6–8.8 (dan Fase 2 8.5) belum diisi pemilik saat bagian ini ditulis. Orchestrator menanyakan sekali apakah tetap mulai; Fase 3 dan M2 tidak dicentang sebelum uji HP.
- **Aset kucing** ada sebagai usulan di `tools/env_art/kendaraan.py` (PR #35: `mission_kucing_sheet` belang tiga berkalung + kucing dekorasi), tetapi belum disalin ke `assets/`. Run 4B menyalinnya lewat skripnya (tambah `--salin` bila belum ada), bukan disalin tangan. Catat drift render di mesin ini (run 3A, PR #35/#37).
- **Keputusan yang sudah ada, jangan ditanyakan ulang:** semua K-/O- run 3A, 3B, 3C; tabrakan = jatuh (pemilik 2026-10-17, PR #36); rumah sisi dekat = tembok rendah (K-5 run 3C); kotak surat abu-abu di rumah bukan pelanggan (pemilik 2026-10-17); CSV terjemahan; skala ×3.

### Run 4A — halaman depan koran dan satu hari utuh

```text
Kamu adalah ORCHESTRATOR loop Dev↔QA untuk repo Loper Koran. Ikuti docs/LOOP-DEV-QA.md
secara ketat (Bagian 1, Bagian 0c, Bagian 6e). Mulai dari main terbaru yang sudah memuat
PR #33 sampai #37; kalau belum, berhenti dan minta saya merge dulu.

SCOPE: Run 4A — Fase 4 bagian pertama: satu hari utuh tanpa misi kucing (DEV_PHASES Fase 4,
  TECH_PLAN Fase 4 dan 3.1–3.3, GDD 3.1 dan 10.1–10.3, DATA_SCHEMA 1, 2, 4, CONTENT_GUIDE 2
  dan 8, DESIGN_SPEC 4, STORY 6). Misi kucing, HUD misi, dan tutorial ada di Run 4B.
  - Format misi dan headline JSON di assets/data/ (DATA_SCHEMA 1–2, rule content-data) dan
    pemuatnya: field wajib, id permanen, rujukan flag, panjang headline maks 40 karakter;
    kunci formatnya di DATA_SCHEMA dengan contoh dari berkas nyata (tetap usulan). Semua teks
    pemain lewat kunci terjemahan (translations/, rule content-data).
  - `HeadlineManager` murni di scripts/systems/: tiga headline per hari (berita utama, misi
    sampingan, berita ringan) dari pool + flag, seed per hari (RNG berseed), lanjutan kemarin
    diprioritaskan. Contoh headline hari 1–3 (CONTENT_GUIDE 8, standar konten aman semua umur).
  - Layar halaman depan koran (DESIGN_SPEC 4: satu-satunya layar terang, krem; terbaca dalam
    10 detik): tiga headline, misi sampingan dengan ringkasan satu baris + Ambil/Lewati,
    tombol Berangkat; anchor + Container, target sentuh ≥ 42 px game, zona aman, 16:9–20:9.
    Melewati misi tanpa penalti (GDD 10.3). Misi yang diambil di 4A cukup tercatat (efeknya 4B).
  - Alur satu hari (TECH_PLAN 3.2, rule ui-scenes): Koran → Rute (scene rute yang ada) →
    Hasil (layar hasil 3C) → hari berikutnya; tombol "Main lagi" layar hasil diganti/ditambah
    "Hari berikutnya" sesuai alur (catat keputusan). Back Android wajar di tiap layar.
    Struktur sesi dan game over TIDAK diputuskan (ROADMAP 5); alur hari berurutan ini
    prototype yang tidak menguncinya — tulis itu di SPEC.
  - `SaveManager` v1 (`user://save.json`, rule save-system): simpan hanya di akhir hari,
    nomor versi + migrasi sejak awal, save rusak tidak ditimpa diam-diam, id permanen; flag
    hari, koin dan tip kumulatif dari `SkorRute`/`HasilRute` (jangan dihitung ulang di UI).
    Tes autoload tanpa scene tree (rule testing), tanpa menulis save sungguhan di tes.
  - Seed rute per hari (rute hari N deterministik dari seed hari), tetap memakai RouteBuilder.
  - Tes headless dengan mutan nyata dan oracle independen; smoke test layar koran (tekan
    Ambil/Lewati/Berangkat lewat pressed.emit()); validasi semua data baru; save: tulis/baca,
    migrasi, rusak, akhir hari saja.
  - Perbarui checklist uji HP (docs/SETUP_ANDROID.md bagian baru) untuk alur satu hari.
  Keputusan terbuka yang mungkin menghambat (tanyakan SEKALI, satu rekomendasi per
  keputusan): nama koran dan nama perumahan (TECH_PLAN Fase 4 ❓, CONTENT_GUIDE 8); apakah
  layar hasil menawarkan "Hari berikutnya" saja atau juga "Ulangi hari"; apa yang disimpan
  bila app ditutup di tengah rute (rute diulang dari awal hari, usulan); misi lintas hari dan
  misi aktif di save (DATA_SCHEMA 5, GDD 10.9) — boleh ditunda ke 4B bila tidak menghambat.
  Struktur sesi, game over, target harian (ROADMAP 5, M2) JANGAN diputuskan.
  Fase 4 dan M2 baru selesai setelah Run 4B dan uji HP pemilik; jangan dicentang sebelum itu.
HASIL UJI HP FASE 3 (ISI: tempel catatan dari SETUP_ANDROID 8.6, 8.7, 8.8, dan 8.5 Fase 2;
  kosongkan bila belum): ISI: ...
DESIGN: docs/design/DESIGN_SPEC.md (token bagian 1, layar 4, teks 5); belum ada mockup layar
  koran — Dev boleh mendesain layar koran mengikuti DESIGN_SPEC 4 (krem #F2E7C9 lewat
  palette.gd) dan menandainya usulan.
IZIN HP: boleh memasang APK ke vivo V2108 (adb 12d8c9da) setelah QA PASS; A54
  (RRCWA05E2NN) hanya bila tersambung. Hanya orchestrator yang menyentuh HP; cek layar
  menyala dan tidak sedang dipakai; tidak ada pm clear/uninstall/logcat -c. Save game
  pertama kali ditulis di run ini: JANGAN menghapus data app (pm clear) untuk menguji save.
RUN_ID: 20261018-fase4a-koran-hari
```

### Run 4B — misi kucing Bu Ratmi, HUD misi, tutorial, dan penutup Fase 4

Prasyarat: **PR Run 4A sudah di-merge ke `main`** (branch `feat/koran-hari-4a`, `RUN_ID` `20261018-fase4a-koran-hari`, status PASSED). Kalau belum, berhenti dan minta pemilik merge dulu.

Kondisi sesudah 4A (jangan dikerjakan ulang; baca `docs/loop/20261018-fase4a-koran-hari/SPEC.md` dan `LOG.md`):
- Sudah ada: `PemuatMisi`/`PemuatHeadline`, `HeadlineManager`, `SaveManager` v1 (`user://save.json`, tulis atomik, simpan hanya di akhir hari), `DataSave` (migrasi, `catat_hari`), `SeedHari`, `MesinHari` + `scenes/hari/hari.tscn` (scene utama), `HalamanKoran`, misi `p1_kucing` di `assets/data/missions/perumahan.json`, headline hari 1–3 dan dua lanjutan.
- Di 4A tombol Ambil hanya mencatat `terakhir.misi_diambil` dan `misi_jeda` (jeda 7 hari, S-4); rute tidak berubah dan **tidak ada kucing**. Flag hasil misi belum pernah ditulis permainan, jadi headline lanjutan baru muncul lewat tes. Jeda headline lanjutan 30 hari karena flag tidak dihapus sesudah headline tampil: 4B menetapkan aturan konsumsi flag.
- Hari 1 selalu memunculkan P1 (tutorial mendahului jeda).
- Aset kucing ada sebagai usulan di `tools/env_art/kendaraan.py` (PR #35: `mission_kucing_sheet` belang tiga berkalung + kucing dekorasi) dan **belum** disalin ke `assets/`.
- Terbuka dari 4A: `allowBackup` (rule `save-system` aktif vs preset export `false`; jangan diubah di 4B kecuali pemilik minta), Nit QA-011 (teks notifikasi simpan gagal "hari ini" ambigu, usul "hari sebelumnya"), tinjauan budaya konten hari 1–3.

```text
Kamu adalah ORCHESTRATOR loop Dev↔QA untuk repo Loper Koran. Ikuti docs/LOOP-DEV-QA.md
secara ketat (Bagian 1, Bagian 0c, Bagian 6e). Mulai dari main terbaru yang sudah memuat
PR Run 4A (SaveManager, hari.tscn, HalamanKoran ada di main); kalau belum, berhenti dan
minta saya merge dulu. Baca docs/loop/20261018-fase4a-koran-hari/{SPEC,LOG}.md dulu:
keputusan S-1..S-8 dan temuan DEFERRED (QA-007, QA-011) berlaku, jangan ditanyakan ulang.

SCOPE: Run 4B — Fase 4 bagian kedua: misi kucing dan penutup Fase 4 (DEV_PHASES Fase 4,
  TECH_PLAN Fase 4 dan 3.1–3.3, GDD 10.2–10.4 dan 10.9 dan 14.1, DATA_SCHEMA 1, 4, 5,
  CONTENT_GUIDE 3 dan 8, DESIGN_SPEC 3.1 dan 4, STORY 6).
  - `MissionManager` murni di scripts/systems/ dan template Cari (GDD 10.2–10.4): tiga titik
    kucing dari data misi `p1_kucing`, petunjuk dari lemparan **tepat** (inti kotak surat,
    K-4 run 3B; `ThrowSolver`/`SkorRute` tetap sumber hasil, jangan hitung ulang), menepi
    dalam 2 ubin selama 1,5 detik (stick, TANPA tombol baru), batas 12 rumah (bukan detik),
    penanda visual >= 2 detik + isyarat suara. Field khusus Cari (`langkah`, `petunjuk`,
    `target`, `batas`) mendapat validasi penuh di `PemuatMisi` (4A hanya memeriksa tipe).
    Posisi kucing dari seed hari (`SeedHari`), deterministik, RNG berseed.
  - Kucing di rute: salin aset lewat skrip `tools/env_art/kendaraan.py` (tambah `--salin`
    bila belum ada; JANGAN salin tangan; catat drift render di mesin ini, run 3A/PR #35/#37),
    impor Godot, scene kucing, tidak mengubah geometri rute dan tidak menutupi sasaran
    (PenutupPemain). Gagal TIDAK mengurangi koin atau tip (prinsip 2); kucing tidak
    menghalangi tabrakan/skor yang ada.
  - Misi diambil di koran MENGAKTIFKAN misi di rute; dilewati = rute tanpa kucing (S-7:
    Berangkat tanpa memilih = Lewati). Misi aktif dan hasilnya masuk save; bila perlu ubah
    versi save v1 -> v2 DENGAN migrasi dan tes migrasi (rule save-system; id permanen; save
    rusak tidak ditimpa). Misi lintas hari tetap terbuka (DATA_SCHEMA 5, GDD 10.9, ROADMAP 5):
    boleh dikerjakan HANYA bila perlu dan ditulis di SPEC sebagai usulan, tanpa mengunci
    struktur sesi.
  - HUD misi ("Kucing 0/1 · 8 rumah") dan banner selesai/gagal 1,5 detik (DESIGN_SPEC 3.1,
    CONTENT_GUIDE 3): bagian HUD rute yang ada (HudDasar/HudRute), tidak menutupi radar,
    sasaran, atau tombol bel; target sentuh >= 42 px bila interaktif; zona aman.
  - Hasil misi -> flag -> headline lanjutan besok ("Kucing Bu Ratmi Belum Ditemukan"):
    tulis flag di akhir hari lewat `DataSave.catat_hari`, aturan konsumsi flag (flag
    dihapus/diganti sesudah lanjutan tampil; jeda lanjutan konsisten dengan 4A), simpan
    hanya di akhir hari. Perbarui HeadlineManager/tes rantai hari 1 -> 2 -> 3.
  - Rekap misi di layar hasil (`HasilRute`/`layar_hasil`, tombol "Hari berikutnya" tetap).
  - Tutorial terpandu hari 1 (usulan TECH_PLAN Fase 4): pendek, bisa dilewati, tidak
    memblokir input; teks lewat kunci terjemahan; tidak muncul lagi sesudah selesai
    (disimpan di save).
  - Audio baru seperlunya (isyarat kucing, banner) lewat tools/audio_art/ + LICENSES.md,
    deterministik, uji_sintesis_* baru; ikon efek berita utama tidak termasuk (Fase 7).
  - Tes headless dengan mutan nyata dan oracle independen; smoke test layar koran ->
    Ambil -> Berangkat -> kucing ditemukan/gagal -> hasil -> hari berikutnya lewat
    pressed.emit(); tes tidak boleh menulis save sungguhan (pasang SaveManager ke pohon
    dengan jalur uji seperti 4A); probe jendela tangkapan layar HUD misi, banner, kucing,
    tutorial (2340x1080, 1920x1080, 2400x1080, 1600x720).
  - Perbarui checklist uji HP (docs/SETUP_ANDROID.md 8.9/8.10) untuk misi kucing dan
    tutorial; perbarui DATA_SCHEMA (format save baru, field Cari), AGENTS.md, README docs.
  Keputusan terbuka yang mungkin menghambat (tanyakan SEKALI, satu rekomendasi per
  keputusan): hadiah P1 (45 koin, GDD 14.1) dibayar kapan dan dari mana; efek Bu Ratmi jadi
  pelanggan setia (reputasi baru Fase 6: cukup flag di 4B); apakah mode bantu bisa menangkap
  kucing (rekomendasi: tidak, petunjuk tetap dari lemparan tepat); apakah kucing yang gagal
  dicari muncul lagi besok (rekomendasi: lewat headline lanjutan saja).
  Struktur sesi, game over, target harian (ROADMAP 5, M2) JANGAN diputuskan.
  PENUTUP FASE 4: DEV_PHASES Fase 4 dan M2 baru dicentang SETELAH QA PASS dan uji HP pemilik
  (SETUP_ANDROID 8.9 dan bagian misi kucing). Di run ini centang hanya butir yang terbukti
  oleh tes dan bukan NEEDS-MANUAL, di commit terpisah sesudah PR dibuka. Fase 3 dan M2
  tidak dicentang tanpa catatan uji HP pemilik.
HASIL UJI HP RUN 4A (ISI: tempel catatan dari SETUP_ANDROID 8.9; kosongkan bila belum): ISI: ...
DESIGN: docs/design/DESIGN_SPEC.md (token bagian 1, HUD 3.1, layar 4, teks 5); belum ada
  mockup HUD misi dan banner — Dev boleh mendesain mengikuti DESIGN_SPEC 3.1 dan menandainya
  usulan.
IZIN HP: boleh memasang APK ke vivo V2108 (adb 12d8c9da) setelah QA PASS dengan
  `adb install -r` (izin tetap pemilik 2026-10-17, tanpa bertanya lagi); A54 (RRCWA05E2NN)
  hanya bila tersambung. Hanya orchestrator yang menyentuh HP; cek layar menyala dan tidak
  sedang dipakai; tidak ada pm clear/uninstall/logcat -c; JANGAN menghapus data app (save
  game ada sejak 4A). Push, PR, dan merge tetap menunggu konfirmasi pemilik.
RUN_ID: <YYYYMMDD>-fase4b-misi-kucing   (tanggal hari run dimulai)
```

## 6f. Fase 6A: perintah mulai run (tempel di sesi baru)

Disimpan 2026-10-20, sesudah run 4B (PR #40). Fase 6A (TECH_PLAN Fase 6A, DEV_PHASES Fase 6) dipecah dua run berurutan, satu PR per run. Fase 5 (aset gelombang 1) berjalan paralel dan bukan bagian loop ini: pemilik melompat ke 6A dengan sadar (2026-10-20) dan Fase 5 belum selesai (hanya sprite pemain yang tercentang). Eksplorasi aset Fase 5 dijalankan di Claude Design lewat [`design/PROMPT_FASE5.md`](design/PROMPT_FASE5.md); hasilnya diporting ke `tools/env_art/` dan dipasang di run terpisah, tidak di run 6A.

| Run | Isi | Prasyarat |
|---|---|---|
| 6A1 | Koin jadi saldo (save v3), `BikeCondition` (aus, kerusakan, tanda peringatan, efek hanya menghambat lewat `BikeMotion`), kotak kondisi di HUD rute, layar bengkel (servis, upgrade, `upgrades.json`), alur Hasil → Bengkel → Hari berikutnya, `Economy` | PR #40 (run 4B) di-merge |
| 6A2 | `ReputationManager` (0–100 per distrik, status pelanggan `aktif`/`setia`/`berhenti`, kepribadian), pemetaan pelanggan tetap ke rute yang diacak (K-3 run 3A), pelanggan baru dan berhenti, `MilestoneTracker` dasar, penutup 6A | 6A1 di-merge |

Perintah di bawah hanya untuk **6A1**. 6A2 ditulis sesudah 6A1 di-merge, supaya memakai bentuk save dan layar bengkel yang nyata.

**Catatan run 6A2 (dikerjakan 2026-10-23, `RUN_ID` `20261023-fase6a2-reputasi-pelanggan`; SPEC dan LOG di `docs/loop/20261023-fase6a2-reputasi-pelanggan/`):** dipecah tiga bagian Dev berurutan (A: reputasi, pelanggan tetap, save v4, `RouteBuilder` dengan keadaan, simulasi laju; B: potongan koran terbuang; C: milestone, penanda reputasi di HUD dan layar hasil, ikon dan bunyi baru, probe jendela, dokumen penutup). Pelajaran untuk run berikutnya: (1) golden stateless (rute 60 seed x hari 1..5, skor 1000 urutan acak) dihitung skrip dari checkout `main`, bukan angka tulisan tangan; (2) layar hasil yang sudah padat dibuat dua kolom (kolom samping untuk data baru) supaya tinggi tidak bertambah, dan tes membuktikan lebar kolom utama tidak runtuh bila kolom samping kosong; (3) autoload (`Audio`) dipanggil dari skrip `class_name` lewat `_audio` (`get_node_or_null`), bukan nama global, supaya tes `--script` tetap bisa memuat; (4) denting dan pencacah yang direset per rute (`atur_ulang_rute`) dibaca di dalam satu hari, bukan lintas hari; (5) tangkapan layar probe wajib DILIHAT (Read PNG) di sedikitnya dua ukuran sebelum menyatakan tata letak benar. Mutan nyata: A 34, B 30, C 24 (semua tertangkap sesudah perbaikan tes).

Catatan untuk semua run Fase 6A:
- **Fase 2, 3, dan 4 belum tertutup.** Uji HP 8.5 sampai 8.10 (`SETUP_ANDROID.md`) dikerjakan pemilik; Fase 3, Fase 4, dan M2 tidak dicentang tanpa catatan uji HP. Orchestrator menanyakan sekali apakah tetap mulai dan memakai hasil uji HP yang ditempel pemilik (bila ada) sebagai masukan.
- **Fase 6B (mesin cerita) bukan scope.** Setoran tiga pos (keluarga 35%, bengkel 15%, tabungan 50%), kalender 120 hari, tenggat bab, dan akhir cerita datang di 6B. Di 6A1 bengkel dibayar langsung dari saldo koin pemain.
- **Keputusan yang sudah ada, jangan ditanyakan ulang:** semua K-/O- run 3A sampai 4B; gagal misi tidak pernah mengurangi koin (prinsip 2) dan kerusakan sepeda hanya menghambat, tidak menghentikan permainan (GDD 12.1); tanda peringatan mendahului kerusakan; perbaikan hanya di bengkel setelah antaran (GDD 12.3); satu mata uang koin, tidak bisa dibeli dengan uang asli (GDD 14); tabrakan = jatuh; rumah sisi dekat = tembok rendah; skala ×3; CSV terjemahan; hadiah P1 75 koin.
- **Save sudah v2** (`DataSave`, `user://save.json`). Run ini menambah v3 DENGAN migrasi v2 → v3 dan tes migrasi dengan fixture save 4B asli. Save hanya ditulis di akhir hari; belanja di bengkel ikut tertulis saat "Hari berikutnya". Bentuk save di `DATA_SCHEMA.md` 4.

### Run 6A1 — kondisi sepeda, bengkel, dan koin sebagai saldo

Prasyarat: **PR #40 (run 4B) sudah di-merge ke `main`** (`RUN_ID` `20261018-fase4b-misi-kucing`, PASSED). Kalau belum, berhenti dan minta pemilik merge dulu.

Kondisi sesudah 4B (jangan dikerjakan ulang; baca `docs/loop/20261018-fase4b-misi-kucing/SPEC.md` dan `LOG.md`):
- Sudah ada: `SaveManager` v2 dengan `koin` (hanya naik, sudah termasuk hadiah misi 75), `tip_total`, `terakhir`, `flag`, `misi_hasil`, `tutorial`, `pengaturan`; `MesinHari` (Koran → Rute → Hasil → Koran hari + 1); `HasilRute.Angka` (satu-satunya sumber angka hasil dan koin); `BikeMotion` (gerak, rem, stamina, lateral); `Tabrakan` (jatuh 1,2 detik, kebal sejak bangun); `SkorRute` (ongkos 15, tip 5); slot HUD kondisi sepeda dan reputasi di DESIGN_SPEC 3.3 yang belum terisi; ikon HUD di `tools/ui_art/hud_ikon.py` (periksa apakah ban, rem, rantai sudah ada).
- `docs/BALANCING.md` 8 (keausan) **kosong**; harga bengkel di BALANCING 7 masih usulan (tambal ban 100–150, rem 80, rantai 150, upgrade tingkat 1 500–800).
- Terbuka dari 4B (DEFERRED, tidak menuntut perubahan di run ini): QA-010 sampai QA-012 (keterbacaan kucing dan jendela petunjuk, dinilai di HP) dan P1 muncul lagi di hari 8.

```text
Kamu adalah ORCHESTRATOR loop Dev↔QA untuk repo Loper Koran. Ikuti docs/LOOP-DEV-QA.md
secara ketat (Bagian 1, Bagian 0c, Bagian 6f). Mulai dari main terbaru yang sudah memuat
PR #40 (run 4B: SaveManager v2, misi kucing, tutorial); kalau belum, berhenti dan minta
saya merge dulu. Baca docs/loop/20261018-fase4b-misi-kucing/{SPEC,LOG}.md dan
docs/loop/20261018-fase4a-koran-hari/{SPEC,LOG}.md dulu: keputusan yang sudah ada berlaku,
jangan ditanyakan ulang. Perbarui teks "Fase aktif" dan baris Fase 4 di docs/DEV_PHASES.md
bila masih mengatakan Fase 3 aktif atau 4B belum dikerjakan (commit terpisah, tanpa
mencentang Fase 4 atau M2).

SCOPE: Run 6A1 — Fase 6A bagian pertama: kondisi sepeda, bengkel, dan koin sebagai saldo
  (DEV_PHASES Fase 6, TECH_PLAN Fase 6A, GDD 11–14 dan 14.1, BALANCING 7 dan 8, DESIGN_SPEC
  3.3 dan layar Bengkel, DATA_SCHEMA 4, STORY 4 bagian setoran dan bengkel hanya sebagai
  konteks).
  - Save v2 -> v3 (`DataSave.migrasi`, `if versi < 3`, tes dengan fixture save 4B asli, v1,
    dan v0): `koin` menjadi SALDO yang boleh turun karena belanja; tambah `koin_total`
    (seumur hidup, hanya naik, awal = `koin` v2) untuk milestone nanti; tambah `sepeda`
    (kondisi tiap komponen 0–1, level upgrade tiap komponen) dan `statistik_aus` seperlunya.
    Invarian save-system tetap: `hari`, `koin_total`, `tip_total` hanya naik; save rusak
    atau versi lebih baru tidak ditimpa; id komponen dan upgrade permanen; simpan hanya di
    akhir hari (belanja bengkel ikut tertulis saat "Hari berikutnya"). Perbarui DATA_SCHEMA 4.
  - `BikeCondition` murni di scripts/systems/ (ban, rem, rantai; setang dan lampu hanya bila
    diperlukan, tulis alasannya di SPEC): kondisi 0–1; aus per rute dari ngebut dan sering
    mengerem (ambil dari telemetri `BikeMotion`, jangan hitung ulang gerak); kerusakan
    langsung dari tabrakan (`Tabrakan`); tanda peringatan lebih dulu (rantai berisik, rem
    berdecit) sebelum rusak; efek HANYA menghambat dan lewat pengali di `Config`
    (`BikeMotion` membaca pengali dari kondisi, tanpa angka literal); rute selalu bisa
    diselesaikan dengan semua komponen rusak (invarian, tes dengan `BikeMotion`: waktu
    tempuh rute <= tenggat untuk pemain yang santai terus). RNG berseed dari `SeedHari`.
    Objek jalan baru (paku, pecahan kaca, genangan) BUKAN scope (menambah jenis objek di
    DATA_SCHEMA 3); simpan sebagai usulan 6A2.
  - Kondisi di rute: tiga kotak per komponen di HUD (DESIGN_SPEC 3.3: ikon 14 px + kotak 5x5,
    tanda "!" WARN untuk perlu bengkel) lewat `HudDasar`/`HudRute`, tidak menutupi radar,
    sasaran, tombol bel, atau kartu misi; zona aman; pasangan visual untuk setiap bunyi
    peringatan. Bunyi peringatan dan servis lewat tools/audio_art/ (+ LICENSES.md,
    deterministik, `uji_sintesis_kondisi.py` baru dan langkah di .github/workflows/tes.yml).
    Ikon dan elemen UI baru lewat skrip (tools/ui_art/), bukan disalin tangan.
  - Layar bengkel (scenes/bengkel/, `MesinHari` mendapat keadaan Bengkel: Hasil -> Bengkel ->
    Hari berikutnya; Bengkel boleh dilewati satu tombol; back = keluar tanpa membeli lebih
    lanjut): kartu komponen dengan kondisi, harga servis, tombol Servis, daftar upgrade dari
    `assets/data/shop/upgrades.json` (komponen, level, harga, efek; TECH_PLAN 6A; pemuat
    tunggal `PemuatToko` dengan validasi dan data buruk ditolak, sama pola `PemuatMisi`),
    saldo koin, tombol hanya aktif bila saldo cukup, target sentuh >= 42 px. Upgrade yang
    wajib ada sejak sekarang karena syarat distrik: servis pertama, satu upgrade umum, dan
    ban anti-selip (TECH_PLAN 6A). Tombol iklan hadiah: disiapkan sebagai tempat kosong atau
    tidak ada; TIDAK diaktifkan (menunggu Fase 14, rule privacy-ads).
  - `Economy` murni: pembayaran servis dan upgrade, kenaikan ongkos servis bila banyak
    komponen rusak (GDD 12.3), saldo tidak pernah negatif, belanja tidak bisa dibatalkan
    sebagian (satu transaksi = satu perubahan state). Angka di `scripts/config.gd` dan
    `docs/BALANCING.md` 7 dan 8 (isi bagian 8: laju aus, efek tiap kerusakan, harga), semua
    ditandai usulan.
  - Layar hasil: baris kondisi sepeda singkat ("Rantai perlu servis") bila ada yang perlu;
    jangan mengubah angka koin yang sudah dihitung `HasilRute.Angka`.
  - Tes headless dengan mutan nyata dan oracle independen: aus dan kerusakan deterministik
    dari seed, efek hanya menghambat (invarian rute selesai), migrasi v2 -> v3, belanja tidak
    membuat saldo negatif dan `koin_total` tidak turun, `PemuatToko`, `MesinHari` keadaan
    Bengkel, smoke test layar Hasil -> Bengkel -> servis -> upgrade -> Hari berikutnya lewat
    pressed.emit() (tes tidak boleh menulis save sungguhan: pasang SaveManager ke pohon dengan
    jalur uji seperti 4A), probe jendela tangkapan layar HUD kondisi, tanda "!", layar
    bengkel, dan layar hasil (2340x1080, 1920x1080, 2400x1080, 1600x720).
  - Perbarui checklist uji HP (docs/SETUP_ANDROID.md 8.11: kerusakan terasa menghambat bukan
    memblokir, tanda peringatan terbaca, harga adil, seminggu hari tanpa kebuntuan),
    DATA_SCHEMA (save v3, upgrades.json), BALANCING 7 dan 8, DESIGN_SPEC (bengkel),
    AGENTS.md (peta repo dan perintah), README docs.
  Keputusan terbuka yang mungkin menghambat (tanyakan SEKALI, satu rekomendasi per
  keputusan):
  1. Koin menjadi saldo yang bisa turun (save v3) dan setoran tiga pos baru datang di 6B
     (rekomendasi: ya, bengkel dibayar langsung dari saldo; `koin_total` untuk milestone).
  2. Mode bantu dan keausan (GDD 12.5) (rekomendasi: mode bantu TIDAK mengubah keausan atau
     kerusakan, supaya hanya ada satu ekonomi; kerusakan sudah hanya menghambat).
  3. Kejadian di rute pada 6A1 (rekomendasi: hanya aus dan tabrakan; paku, kaca, genangan
     ditunda ke 6A2 karena menambah jenis objek jalan).
  4. Bengkel wajib dikunjungi atau boleh dilewati (rekomendasi: boleh dilewati; kondisi
     buruk hanya menghambat, jadi tidak ada layar yang memaksa).
  Reputasi, kepribadian pelanggan, pelanggan baru/berhenti, pemetaan pelanggan tetap,
  milestone, setoran tiga pos, kalender cerita, game over, dan target harian JANGAN
  dikerjakan atau diputuskan di run ini.
  PENUTUP: DEV_PHASES Fase 6 tidak dicentang di run ini (6A2 menyusul); centang hanya butir
  yang terbukti oleh tes dan bukan NEEDS-MANUAL, di commit terpisah sesudah PR dibuka.
  Fase 2, 3, 4, dan M2 tidak dicentang tanpa catatan uji HP pemilik.
HASIL UJI HP RUN 4A DAN 4B (ISI: tempel catatan dari SETUP_ANDROID 8.9 dan 8.10; kosongkan bila belum): ISI: ...
DESIGN: docs/design/DESIGN_SPEC.md (token bagian 1, HUD 3.3, layar 4 "Bengkel", teks 5);
  belum ada mockup layar bengkel dan kotak kondisi — Dev boleh mendesain mengikuti
  DESIGN_SPEC dan menandainya usulan.
IZIN HP: boleh memasang APK ke vivo V2108 (adb 12d8c9da) setelah QA PASS dengan
  `adb install -r` (izin tetap pemilik 2026-10-17, tanpa bertanya lagi); A54 (RRCWA05E2NN)
  hanya bila tersambung. Hanya orchestrator yang menyentuh HP; cek layar menyala dan tidak
  sedang dipakai; tidak ada uninstall/logcat -c. Edit save.json lewat run-as lebih disukai
  daripada pm clear, dan pm clear com.rmh.kring boleh bila perlu (izin pemilik 2026-10-18),
  tetapi catat save yang dipakai di LOG. Push, PR, dan merge tetap menunggu konfirmasi
  pemilik.
RUN_ID: <YYYYMMDD>-fase6a1-bengkel-kondisi   (tanggal hari run dimulai)
```

## 6g. Fase 5: perintah mulai run pasang aset (tempel di sesi baru)

Disimpan 2026-10-21, sesudah PR #42 (aset gelombang 1 dirender) dan PR #43 (run 6A1). Fase 5 berjalan paralel dengan Fase 6 (`DEV_PHASES.md`). Aset gelombang 1 sudah dirender sebagai usulan di `tools/env_art/gelombang1/` dan `tools/env_art/ubin_perumahan.py`, tetapi **belum disalin ke `assets/` dan belum dipasang**: rute masih memakai ubin graybox dan koran, VFX, serta kilau dari kode. Pemasangan dipecah tiga run berurutan, satu PR per run:

| Run | Isi | Prasyarat |
|---|---|---|
| 5A | Salin lewat skrip dan pasang tampilan: enam ubin kolom jalan, koran (putar, bayangan, tiga permukaan mendarat, terlipat), VFX sepeda (debu, garis kecepatan, bintang kena, koin tip), kilau misi; tiga penyesuaian renderer (kilau, tong abu-abu, satu polisi tidur) | PR #42 dan #43 di-merge |
| 5B | Tembok sisi dekat dan komposisi rumah dekat, jenis dekor di data segmen (tong sampah, pohon, lampu jalan; DATA_SCHEMA 3), ubin jalan masuk garasi dan simbol, polisi tidur, zebra, genangan. **Status (2026-10-22): di-merge PR #49** (`docs/loop/20261021-fase5b-tembok-dekor/`, QA PASS sesudah iterasi 2: kotak penutup dekor sisi dekat = sprite nyata, dibuktikan piksel; uji HP 8.13 belum ada): isi nyata = tembok empat varian + tiang dan rumah dekat digambar mundur 1,25 ubin, dekor `tong_sampah`/`pohon`/`lampu_jalan` di sembilan segmen, ubin jalan masuk garasi (sisi seberang), simbol sepeda, variasi rumput luar (`rumput_2`, `rumput_3`). **Tidak dikerjakan:** polisi tidur, zebra, genangan (M3, butuh desain gameplay), `aspal_N` (D-4), tong biru, lampu nyala | 5A di-merge |
| 5C | Animasi pemain yang kurang (berhenti dengan kaki turun, bangkit, jatuh dan terjerembab empat arah lain) lewat `tools/loper_art`, pose kucing ditangkap, ubin ujung kerb dan sudut trotoar. **Status (2026-10-22): di-merge PR #52** (`docs/loop/20261022-fase5c-animasi-simpang/`, QA PASS iterasi 1): animasi pemain PR #51 diverifikasi (arah jatuh ditahan, kayuh sesudah bangkit tanpa lompatan), pose kucing ditangkap, ujung kerb jalan masuk, simpang T hiasan (tiga dekat, satu seberang, P-6); sesudah QA juga area persegi kotak surat dihapus dan garis kecepatan dikembalikan ke posisi lama (permintaan pemilik). Uji HP 8.14 dan 8.15 belum diisi | 5A di-merge (boleh paralel dengan 5B) |
| 5D | Pelanggan sisi dekat (dimajukan dari Fase 8 oleh pemilik 2026-10-22, mulai hari 3, 8-9 dari 25), tembok sisi dekat dihapus jadi halaman terbuka, rumah dekat mundur 0,5 ubin dan didesain ulang dengan teras menjorok (Bagian 6j). **Status (2026-10-22): dikerjakan Dev iterasi 1 (bagian A, B, C) di branch `feat/fase5d-sisi-dekat`, menunggu QA dan uji HP 8.16** (`docs/loop/20261022-fase5d-sisi-dekat/`) | 5C di-merge (PR #52) dan PR #53 |

Perintah di bawah hanya untuk **5A**. Perintah 5B ada di Bagian 6h (ditulis sesudah 5A di-merge, dengan usulan pengubahan cakupan); 5C ditulis sesudah 5B.

Catatan untuk semua run Fase 5:
- **Aset hanya lewat renderer.** Dilarang menyalin atau mengedit PNG dengan tangan (`art-assets.mdc`); salinan ke `assets/` lewat opsi `--salin` pada skrip dan dibuktikan uji deterministik di `tools/tests_cek/`.
- **Pasang tampilan, jangan ubah logika.** ThrowSolver, skor, zona, tenggat, gerak, tabrakan, dan save tidak berubah. Tes lama lulus tanpa diubah angkanya.
- **Butir aset di `DEV_PHASES.md` tidak dicentang sebelum dinilai di HP** (keterbacaan koran di ×3, kilau di rumput, kontras ubin, 60 fps). Palet induk tidak dikunci sebelum itu.
- **Keputusan keraguan warna gelombang 1 (ART_DIRECTION 11) diambil orchestrator atas delegasi pemilik 2026-10-21, usulan, bisa ditolak di review PR:** kilau misi dua warna (krem terang dominan, kuning hanya titik tengah); bintang kena dan koin tip tetap kuning (muncul sekejap, bukan zona diam); tong sampah hijau diganti abu-abu logam; satu polisi tidur saja (versi gelombang 1, belang krem dan logam gelap); koran 8×6 dipakai apa adanya (diperbesar hanya bila uji HP menolak); lebar jalan 2 ubin aspal mengikuti `config.gd` (mock 3 ubin lama tidak berlaku). Debu dan garis kecepatan di trotoar krem distrik lain serta grading sore ditunda ke penilaian HP dan Fase 7.

### Run 5A — pasang aset gelombang 1: ubin, koran, VFX, kilau misi

Prasyarat: **PR #42 (aset gelombang 1) dan PR #43 (run 6A1) sudah di-merge ke `main`**. Kalau belum, berhenti dan minta pemilik merge dulu.

```text
Kamu adalah ORCHESTRATOR loop Dev↔QA untuk repo Loper Koran. Ikuti docs/LOOP-DEV-QA.md
secara ketat (Bagian 1, Bagian 0c, Bagian 6g). Mulai dari main terbaru yang sudah memuat
PR #43 (run 6A1) dan PR #42 (aset gelombang 1); kalau belum, berhenti dan minta saya merge
dulu. Baca docs/design/PROMPT_FASE5.md, ART_DIRECTION 2, 4, 6 dan 11, docs/loop/20261018-fase4b-misi-kucing/
{SPEC,LOG}.md (pola pemasangan aset, mutan, probe) dan docs/loop/20261020-fase6a1-bengkel-kondisi/
{SPEC,LOG}.md dulu: keputusan yang sudah ada berlaku, jangan ditanyakan ulang.

SCOPE: Run 5A — Fase 5, pasang aset gelombang 1 yang sudah dirender (DEV_PHASES Fase 5,
  ART_DIRECTION 6.2, 6.3, 6.7, 6.9, rule art-assets). TANPA menggambar aset baru kecuali tiga
  penyesuaian renderer di bawah. Perubahan hanya tampilan: ThrowSolver, skor, zona, tenggat,
  gerak, tabrakan, save tidak berubah, dan semua tes lama lulus tanpa diubah angkanya.
  - Salin lewat skrip, bukan tangan: tambah opsi `--salin` di tools/env_art/gelombang1/render.py
    dan tools/env_art/ubin_perumahan.py yang menyalin HANYA sprite yang dipasang run ini (pola
    kendaraan.py --salin run 4B): koran (prop_koran_putar, _bayangan, _teras, _rumput,
    _kotak_surat, _terlipat), VFX (vfx_debu_roda, vfx_garis_kecepatan_a/b/c, vfx_bintang_kena,
    vfx_koin_tip), mission_kilau, dan enam ubin kolom dasar (tile_perumahan_ rumput_seberang,
    trotoar_seberang, aspal_seberang, aspal_dekat, trotoar_dekat, rumput_dekat) + JSON titik
    pijak, ke assets/sprites/. Impor Nearest, Lossless, tanpa mipmap. Uji deterministik baru di
    tools/tests_cek/ (isi assets/ = hasil skrip, pola uji_aset_kucing.py) + langkah di
    .github/workflows/tes.yml. Aset yang belum dipasang TIDAK disalin.
  - Tiga penyesuaian renderer (keputusan pemilik yang didelegasikan ke orchestrator, 2026-10-21,
    usulan, ART_DIRECTION 11): (1) mission_kilau dua warna: krem terang dominan, kuning aksen hanya
    titik tengah, ritme tetap beda dari penanda sasaran; (2) tong sampah hijau diganti abu-abu
    logam (biru tetap bila tidak bentrok token DESIGN_SPEC 1.1); (3) hanya SATU polisi tidur di
    ekspor: versi gelombang 1 (belang krem/logam gelap); `prop_polisi_tidur` lama kuning-hitam di
    ubin_perumahan.py dibuang dari ekspor. Render ulang, perbarui mock di docs/design/environment/
    gelombang1/ dan uji_aset_gelombang1.py. Koran 8x6 dipakai apa adanya (nilai di HP).
  - Pasang di game (tampilan saja):
    a. Ubin: TanahDaur dan JalanDaur dari tiga tekstur (aspal, trotoar, rumput) ke enam KOLOM
       (rumput_seberang, trotoar_seberang, aspal_seberang, aspal_dekat, trotoar_dekat, rumput_dekat)
       menggantikan tile_graybox_*. Lebar jalan tetap 2 ubin aspal, trotoar 1 per sisi (config.gd).
       Posisi, batas jalan, dan sel_tanah tidak berubah; sambungan ubin tanpa celah (tes piksel).
       Varian *_masuk (garasi), *_simbol, aspal_N/rumput_N polos TIDAK dipasang (5B).
    b. Koran: sprite putar (4 frame, 12 fps) dan bayangan (pilih ukuran dari tinggi) menggantikan
       pola_piksel koran/bayangan; mendarat memakai prop_koran_teras, _rumput, atau _kotak_surat
       menurut permukaan (satu pemetaan murni dari hasil lemparan, dites); prop_koran_terlipat untuk
       keadaan terantar. Penanda kena/meleset, garis bidik, ikon koran HUD tetap dari kode.
    c. VFX sepeda: debu roda dan garis kecepatan menggantikan umpan_balik_sepeda.gd dengan ambang
       dan perilaku yang sama (tes lama tetap); bintang kena dan koin tip di umpan_melayang_gambar.
    d. Kilau misi menggantikan kilau kode di kucing misi (KucingHiasan), ukuran dan tempat tetap.
    Kode gambar lama (pola_piksel dan sejenisnya) hanya dibuang bila tidak lagi dipakai dan tidak
    ada tes yang bergantung; jangan membuang diam-diam (belajar dari QA-004 run 4B).
  - Di LUAR scope (jangan dikerjakan atau diputuskan): tembok sisi dekat dan komposisi rumah dekat
    (5B), tong sampah/pohon/lampu jalan di rute (butuh jenis dekor di data segmen, DATA_SCHEMA 3,
    5B), polisi tidur/zebra/genangan/percikan/pos dan portal satpam (M3), jejak kaki dan mangkuk
    kucing (belum dipakai petunjuk misi), varian ubin garasi dan simbol, animasi pemain (berhenti
    kaki turun, bangkit, jatuh empat arah lain, pose kucing ditangkap: 5C lewat tools/loper_art),
    ubin ujung kerb dan sudut trotoar, aset M3, audio, perubahan ThrowSolver/skor/zona, Fase 6A2.
  - Tes: pemetaan permukaan -> sprite mendarat, pemilihan frame bayangan dari tinggi, enam kolom
    ubin (jenis per x, tanpa celah), impor sprite (Nearest/Lossless/tanpa mipmap), tidak ada
    referensi ke aset yang belum dipasang, paket --export-pack memuat sprite baru; mutan nyata;
    probe jendela di 2340x1080, 1920x1080, 2400x1080, 1600x720 (rute siang dengan ubin baru,
    koran terbang, mendarat di tiga permukaan, terlipat, ngebut dengan debu dan garis, bintang
    kena dan koin tip, kilau kucing di rumput dan trotoar) dengan tangkapan layar yang DILIHAT QA;
    tes tidak boleh menulis save sungguhan (jalur uji SaveManager).
  - Dokumen: ART_DIRECTION (status terpasang vs usulan di 6.2, 6.3, 6.7, 6.9; 11 diperbarui dengan
    keputusan di atas; 2.6 lebar jalan 2 ubin; Changelog), DEV_PHASES Fase 5 (centang HANYA "Putuskan
    keraguan warna gelombang 1"; butir aset dicentang setelah dinilai di HP), AGENTS.md (peta repo
    dan perintah), docs/README.md, PROMPT_FASE5.md (catatan hasil), SETUP_ANDROID 8.12 (checklist HP).
  Keputusan terbuka yang mungkin menghambat: tidak ada (keraguan warna sudah diputuskan, Bagian 6g).
  Jangan mengunci palet induk. Bila ada hal baru, tanyakan SEKALI dengan satu rekomendasi.
  PENUTUP: DEV_PHASES Fase 5 tidak dicentang penuh (5B dan 5C menyusul); Fase 2, 3, 4, dan M2 tidak
  dicentang tanpa catatan uji HP pemilik. Run berikutnya: 5B (tembok sisi dekat, dekor di data
  segmen, ubin M3) dan 5C (animasi pemain), satu PR per run.
HASIL UJI HP RUN 4A, 4B, DAN 6A1 (ISI: tempel catatan dari SETUP_ANDROID 8.9, 8.10, 8.11; kosongkan
  bila belum): ISI: ...
DESIGN: docs/design/DESIGN_SPEC.md (token bagian 1) dan docs/design/environment/gelombang1/ (mock);
  tidak ada layar baru.
IZIN HP: boleh memasang APK ke vivo V2108 (adb 12d8c9da) setelah QA PASS dengan `adb install -r`
  (izin tetap pemilik 2026-10-17, tanpa bertanya lagi); A54 (RRCWA05E2NN) hanya bila tersambung.
  Hanya orchestrator yang menyentuh HP; cek layar menyala dan tidak sedang dipakai; tidak ada
  uninstall/logcat -c. Edit save.json lewat run-as lebih disukai daripada pm clear, dan pm clear
  com.rmh.kring boleh bila perlu (izin pemilik 2026-10-18), tetapi catat save yang dipakai di LOG.
  Push, PR, dan merge tetap menunggu konfirmasi pemilik.
RUN_ID: <YYYYMMDD>-fase5a-pasang-aset-gelombang1   (tanggal hari run dimulai)
```

## 6h. Fase 5: perintah Run 5B (tempel di sesi baru)

Disimpan 2026-10-21, sesudah Run 5A di-merge (PR #45). Run 5A memasang ubin enam kolom, koran, VFX sepeda, dan kilau misi (`docs/loop/20261021-fase5a-pasang-aset-gelombang1/`). 5B memasang sisi dekat dan dekor di pinggir jalan. 5C (animasi pemain) menyusul sebagai run terpisah; tidak dijalankan paralel dengan 5B karena keduanya mengubah `DEV_PHASES.md`, `ART_DIRECTION.md`, dan `AGENTS.md`.

**Usulan pengubahan cakupan 5B (bisa ditolak):** tabel 6g mencantumkan polisi tidur, zebra, dan genangan di 5B, tetapi daftar "di luar scope" run 5A menaruhnya di M3. Ketiganya menyiratkan perilaku gameplay (polisi tidur memperlambat, genangan licin) yang belum didesain, dan ubin hias yang tidak berefek menyesatkan pemain. Usulan: **5B tidak memasangnya** (tetap M3 bersama portal dan pos satpam, percikan); 5B memasang tembok sisi dekat, dekor di data segmen (tong sampah, pohon, lampu jalan), jalan masuk garasi, simbol sepeda, dan variasi ubin polos.

### Run 5B — tembok sisi dekat, dekor di data segmen, variasi ubin

Prasyarat: **PR #45 (Run 5A) sudah di-merge ke `main`.** Kalau belum, berhenti dan minta pemilik merge dulu.

```text
Kamu adalah ORCHESTRATOR loop Dev↔QA untuk repo Loper Koran. Ikuti docs/LOOP-DEV-QA.md
secara ketat (Bagian 1, Bagian 0c, Bagian 6g dan 6h). Mulai dari main terbaru yang sudah memuat
Run 5A (PR #45). Baca docs/loop/20261021-fase5a-pasang-aset-gelombang1/{SPEC,LOG}.md (pola --salin,
uji deterministik, probe, mutan, pelajaran: tekstur dimuat di _init/_ready bukan di _draw, jangan
menjalankan dua proses Godot sekaligus), docs/loop/20261018-fase3c-hud-hasil/ (spike sisi dekat),
ROADMAP 4b, ART_DIRECTION 2, 6.2, 6.4 (butir tembok belakang rendah), 6.7, 11, DATA_SCHEMA 3,
ROUTE_DESIGN, rule content-data dan art-assets dulu: keputusan yang sudah ada berlaku, jangan
ditanyakan ulang.

SCOPE: Run 5B — Fase 5, pasang tampilan sisi dekat dan dekor rute perumahan (DEV_PHASES Fase 5,
  ART_DIRECTION 6.4, 6.7, rule art-assets dan content-data). Perubahan tampilan dan data dekor;
  ThrowSolver, skor, zona, tenggat, gerak, tabrakan, rintangan, save, misi, dan kondisi sepeda tidak
  berubah, dan semua tes lama lulus tanpa diubah angkanya.
  - Salin lewat skrip, bukan tangan (`--salin`, pola run 5A; jangan menyalin PNG dengan tangan):
    (1) tembok sisi dekat dari tools/env_art/gelombang1: house_tembok_polos, _bata, _besi, _pot,
    _tiang + JSON titik pijak; (2) prop_tong_sampah_logam (abu-abu; versi biru TIDAK dipasang);
    (3) pohon dan lampu jalan dari tools/env_art/lampu_pohon.py: pilih secukupnya untuk perumahan
    (ART_DIRECTION 6.7: pohon rindang, glodokan tiang, ketapang kencana; lampu jalan versi MATI/siang,
    satu jenis per sisi). Skrip itu belum punya --salin dan belum punya uji deterministik: tambahkan
    keduanya (pola uji_aset_gelombang1.py / uji_aset_pasang_gelombang1.py) + langkah di
    .github/workflows/tes.yml; sprite 5B yang disalin tidak boleh mengubah isi pasangan 5A;
    (4) ubin tambahan dari ubin_perumahan.py: masuk garasi, simbol sepeda (trotoar_*_simbol), dan
    aspal_N/rumput_2/rumput_3 polos. Aset yang belum dipasang TIDAK disalin. Impor Nearest,
    Lossless, tanpa mipmap.
  - Pasang di game:
    a. Tembok sisi dekat di RumahDaurRute: tembok belakang rendah 14 unit di kaki kavling dengan
       rumah dekat penuh di belakangnya (keputusan pemilik 2026-10-17, geometri spike run 3C: tembok
       berpusat x = 3,125 ubin, rumah mundur 1,25 ubin; RUTE_RUMAH_DEKAT_X_UBIN sekarang 3.0, cocokkan
       dan catat selisihnya di SPEC). Satu modul per ubin sepanjang kavling, tiang di ujung, varian
       dipilih deterministik dari id rumah (tes seed sama = sama). Rumah dekat tetap tanpa kotak surat
       dan tanpa zona; sasaran sisi dekat TIDAK boleh tertutup tembok (ukur dengan MedanKoran seperti
       spike: badan kotak/zona 0%) dan tembok bukan penghalang gerak atau tabrakan.
    b. Jenis dekor di data segmen (DATA_SCHEMA 3, usulan): bidang opsional `dekor` pada segmen,
       daftar {jenis: tong_sampah|pohon|lampu_jalan, pos, sisi, varian}; validasi di SegmenRute
       (jenis dikenal, sisi, pos dalam panjang segmen, tidak menimpa pintu rumah, kotak surat, objek
       rintangan, atau lajur sepeda), berkas segmen lama tanpa `dekor` tetap sah. Gambar lewat satu
       kelas daur baru bergaya RintanganDaur (jendela daur, Y-sort, terdaftar ke penerap penutup agar
       pohon dan lampu menjadi semi-transparan di atas pemain; ROUTE_DESIGN aturan 5: jalur utama tidak
       tertutup). Tulis `dekor` tangan di 9 segmen perumahan (content: seperlunya, tidak menyesakkan
       jalur; pohon di rumput, lampu jalan di tepi trotoar, tong sampah di dekat kotak surat/gerbang).
       Perbarui DATA_SCHEMA 3, ROUTE_DESIGN, dan tes data (tolak jenis salah, sisi salah, di luar
       panjang, bertabrakan dengan rumah).
    c. Ubin: jalan masuk garasi di bawah rumah dengan mobil_garasi (ubin *_masuk di titik objek),
       simbol sepeda di lajur pada selang tetap (konstanta di config.gd), dan variasi polos
       aspal_N/rumput_N dipilih deterministik. Posisi, batas jalan, dan sel_tanah tidak berubah;
       sambungan tanpa celah (tes piksel seperti 5A).
  - Di LUAR scope (jangan dikerjakan atau diputuskan): polisi tidur, zebra, genangan, percikan,
    portal dan pos satpam, tong sampah biru (semua M3: perlu desain gameplay), jejak kaki dan mangkuk
    kucing, animasi pemain (5C), ubin ujung kerb dan sudut trotoar (5C), aset M3 (hujan, jendela
    menyala, lampu nyala/malam, mobil tamu), audio, perubahan ThrowSolver/skor/zona/rintangan, Fase 6A2.
  - Tes: validasi dekor, pemilihan varian tembok dan tiang, geometri tembok vs rumah dekat, sasaran
    sisi dekat tidak tertutup, penutup semi-transparan untuk pohon/lampu, ubin masuk/simbol di titik
    yang benar, tanpa celah, impor sprite, tidak ada referensi ke aset yang belum dipasang, paket
    --export-pack memuat sprite baru; mutan nyata; probe jendela di 2340x1080, 1920x1080, 2400x1080,
    1600x720 (sisi dekat dengan tembok tiga varian, tembok dan sasaran dekat, pohon/lampu menutupi
    pemain, tong sampah, garasi masuk, simbol sepeda, kidal) dengan tangkapan layar yang DILIHAT QA;
    tes tidak boleh menulis save sungguhan.
  - Dokumen: ART_DIRECTION (6.4, 6.7, 11, Changelog), DATA_SCHEMA 3, ROUTE_DESIGN, DEV_PHASES Fase 5
    (JANGAN mencentang butir aset sebelum dinilai di HP; perbarui catatan pembagian 5B/5C bila usulan
    pengubahan cakupan di Bagian 6h dipakai), LOOP-DEV-QA 6g (baris 5B), AGENTS.md, docs/README.md,
    SETUP_ANDROID 8.13 (checklist HP: tembok terbaca bukan pita gelap, sasaran dekat jelas, pohon dan
    lampu tidak membingungkan jalur, 60 fps).
  Keputusan terbuka yang mungkin menghambat: tidak ada (tinggi tembok dan mundur 1,25 ubin usulan
  sampai uji HP Bab 2). Jangan mengunci palet induk. Bila ada hal baru, tanyakan SEKALI dengan satu
  rekomendasi.
  Git: judul PR memakai Conventional Commits (feat:, art:, ...); release-please membacanya (git-workflow
  bagian Rilis). Jangan mengedit CHANGELOG.md, .release-please-manifest.json, atau membuat tag.
  PENUTUP: DEV_PHASES Fase 5 tidak dicentang penuh (5C menyusul); Fase 2, 3, 4, dan M2 tidak dicentang
  tanpa catatan uji HP pemilik. Run berikutnya: 5C (animasi pemain, ubin ujung kerb dan sudut trotoar),
  satu PR.
HASIL UJI HP RUN 4A, 4B, 6A1, DAN 5A (ISI: tempel catatan dari SETUP_ANDROID 8.9, 8.10, 8.11, 8.12;
  kosongkan bila belum): ISI: ...
DESIGN: docs/design/DESIGN_SPEC.md (token bagian 1) dan docs/design/environment/gelombang1/ (mock
  tembok: sisi_dekat_siang_x3.png, tembok_rantai_x3.png); tidak ada layar baru.
IZIN HP: boleh memasang APK ke vivo V2108 (adb 12d8c9da) setelah QA PASS dengan `adb install -r`
  (izin tetap pemilik 2026-10-17, tanpa bertanya lagi); A54 (RRCWA05E2NN) hanya bila tersambung.
  Hanya orchestrator yang menyentuh HP; cek layar menyala dan tidak sedang dipakai; tidak ada
  uninstall/logcat -c. Edit save.json lewat run-as lebih disukai daripada pm clear, dan pm clear
  com.rmh.kring boleh bila perlu (izin pemilik 2026-10-18), tetapi catat save yang dipakai di LOG.
  APK debug lokal dibangun dengan `godot --headless --export-debug "Android"`; CI juga membuat APK
  uji di setiap PR (artifact build-apk, tanda tangan sama dengan keystore lokal, SETUP_ANDROID 4b).
  Push, PR, dan merge tetap menunggu konfirmasi pemilik.
RUN_ID: <YYYYMMDD>-fase5b-tembok-dekor   (tanggal hari run dimulai)
```

## 6i. Fase 5: perintah Run 5C (tempel di sesi baru)

Disimpan 2026-10-22, sesudah Run 5B di-merge (PR #49) dan PR #51 masuk ke `main`. PR #51 dikerjakan di luar loop (kanvas Claude Design "Animasi Pemain Fase 5C" dan satu sesi kode) dan sudah memuat: `tools/loper_art/fase5c.py` (jatuh dan terjerembab lima arah, sel 140×88, titik pijak 70,61; bangkit lima arah, 6 frame; berhenti kaki kanan lima arah), `LoperAnim`/`LoperSprite` yang memakainya (jatuh per arah, bangkit di 0,6 detik terakhir dari jatuh 1,2 detik, `rem` dengan kecepatan 0 = `Pose.BERHENTI`), pose kucing `ditangkap_1/_2` di `mission_kucing_sheet` (`MISI_KUCING_KOLOM` 9, belum dipakai rute), dan ubin simpang T di `ubin_perumahan.py` (hanya di `build/`). Hasilnya **belum pernah dilihat QA independen** dan belum diuji di HP. Maka 5C tidak membuat aset animasi lagi: 5C memeriksa dan menyelesaikan pemasangannya.

**Putusan orchestrator Bagian 6i (usulan, bisa ditolak di review PR; jangan ditanyakan ulang):**

- **P-1 Simpang T dipasang sebagai hiasan** (keputusan pemilik 2026-10-22, menjawab ROUTE_DESIGN 8 "persimpangan: hanya dekorasi, atau ada lalu lintas yang memotong" untuk sekarang: hiasan dulu). Jalan samping tanpa lalu lintas, tanpa rintangan, tanpa sasaran; data simpang di segmen disusun supaya kelak mobil/motor bisa berbelok masuk atau keluar dari simpang (M3) tanpa mengubah format: tiap simpang punya posisi, sisi, dan lebar mulut yang bisa dibaca sistem lain. Ubin simpang dari `ubin_perumahan.py ekspor_simpang` disalin lewat `--salin` (sudut trotoar ikut terpasang lewat ubin ini).
- **P-2 Ujung kerb jalan masuk** (temuan C-F1 run 5B, 22 piksel) dikerjakan terpisah dari simpang: ubin ujung kerb di tepi `*_masuk`.
- **P-3 Pose kucing ditangkap** tampil selama bar progres tangkap > 0 (kucing sedang ditahan), dua frame 3 fps dari waktu animasi misi (membeku saat jeda); progres 0 = duduk seperti sekarang. `MissionManager`, `RencanaMisi`, syarat tangkap, dan angka misi tidak berubah.
- **P-4 Lama jatuh tidak berubah** (`TABRAKAN_JATUH_DETIK` 1,2 detik); akibatnya terjerembab hanya tampil 0,2 detik sebelum bangkit (jatuh 0,4 + bangkit 0,6). Itu bukan cacat untuk run ini, hanya dicatat dan masuk checklist HP.
- **P-5 Lempar 90°** (animasi lempar arah kiri/kanan) tetap tidak ada dan di luar scope.

### Run 5C — verifikasi animasi pemain, pose kucing ditangkap, ujung kerb jalan masuk, simpang hiasan

Prasyarat: **PR #49 (Run 5B) dan PR #51 sudah di-merge ke `main`.** Kalau belum, berhenti dan minta pemilik merge dulu.

```text
Kamu adalah ORCHESTRATOR loop Dev↔QA untuk repo Loper Koran. Ikuti docs/LOOP-DEV-QA.md
secara ketat (Bagian 1, Bagian 0c, Bagian 6g dan 6i). Mulai dari main terbaru yang sudah memuat
Run 5B (PR #49) dan PR #51. Baca dulu: docs/loop/20261021-fase5b-tembok-dekor/{SPEC,LOG}.md
(pola --salin, UbinKhusus, tes piksel, temuan C-F1 dan I2-F3, pelajaran: tekstur dimuat di _init/_ready
bukan di _draw, jangan menjalankan dua proses Godot sekaligus), `git show b69fc1f --stat` (isi PR #51),
ART_DIRECTION 3.4 dan 11 dan Changelog 2026-10-22, docs/design/character/loper_agen/{jatuh,bangkit,berhenti}/README.md,
tools/loper_art/fase5c.py, scripts/systems/loper_anim.gd, scripts/entities/{loper_sprite,kucing_misi,kucing_hiasan}.gd,
tools/env_art/ubin_perumahan.py dan kendaraan.py, rule art-assets, gdscript, testing: keputusan yang
sudah ada berlaku, jangan ditanyakan ulang. Bagian 6i mungkin belum ada di main; putusan di bawah
berlaku walaupun begitu.

PUTUSAN (usulan, bisa ditolak di review PR; jangan ditanyakan ulang):
  P-1 Simpang T dipasang sebagai hiasan (keputusan pemilik 2026-10-22): tanpa lalu lintas, rintangan,
      atau sasaran; data simpang disiapkan supaya kelak mobil/motor bisa berbelok (M3).
  P-2 Ujung kerb jalan masuk (C-F1 run 5B, 22 piksel) dikerjakan terpisah dari simpang.
  P-3 Pose kucing ditangkap tampil selama progres tangkap > 0, dua frame 3 fps; progres 0 = duduk.
  P-4 Lama jatuh tetap 1,2 detik; terjerembab hanya tampil 0,2 detik, dicatat untuk checklist HP.
  P-5 Lempar 90° di luar scope.

SCOPE: Run 5C — Fase 5, pasang dan buktikan animasi pemain, pose kucing ditangkap, ujung kerb
  jalan masuk, dan simpang T hiasan. Perubahan tampilan dan data segmen; ThrowSolver, skor, zona, tenggat, gerak (BikeMotion, angka rem
  dan kecepatan), tabrakan (lama jatuh), rintangan, save, MissionManager/RencanaMisi (syarat dan
  angka), kondisi sepeda, dan bengkel tidak berubah, dan semua tes lama lulus tanpa diubah
  angkanya. Satu-satunya perubahan tes lama yang boleh: yang sudah dibuat PR #51 (pose REM->BERHENTI
  pada sidik emas gerak, 68 animasi), dan catat setiap perubahan tes lama di LOG.
  A. Verifikasi dan penyempurnaan animasi pemain dari PR #51 (kode itu belum melewati QA):
     (1) Catat baseline di LOG: jumlah tes, pemeriksa, semua uji_*.py (uji_bangun_frames, uji_aset_kucing)
     di main sebelum mengubah apa pun.
     (2) Tambahkan probe jendela `tests/probe_animasi_pemain_jendela.gd` (pola probe_rintangan_jendela):
     jatuh, terjerembab, dan bangkit untuk kelima arah (-2..2) di 2340x1080, 1920x1080, 2400x1080,
     1600x720, dengan titik pijak sprite tetap sama sepanjang urutan (tidak melompat saat sel 114x68
     berganti 140x88), pose berhenti saat rem + kecepatan 0 (juga di titik tangkap kucing), serta
     transisi bangkit -> kayuh tanpa lompatan piksel; probe mencetak keadaan tidak sesuai. Tangkapan layar
     DILIHAT QA.
     (3) Tes yang menutup celah, dengan mutan nyata: waktu mulai bangkit = total - n/fps (batas
     inklusif dan toleransi), terjerembab 0,2 detik, arah dijepit, bangkit tidak mengubah lama jatuh
     (Tabrakan), berhenti hanya saat rem aktif dan kecepatan <= POSE_MELUNCUR_TOLERANSI_UD (NaN = REM),
     lempar dari BERHENTI memakai tingkat santai, jeda membekukan bangkit, jatuh di dalam jendela
     daur tidak menyimpan keadaan.
     (4) Periksa berhenti di skenario tangkap kucing nyata (menepi lalu rem): bila syarat tangkap
     (kecepatan <= MISI_TANGKAP_KECEPATAN_MAKS_UD tanpa rem) terpenuhi tanpa pose berhenti, LAPORKAN
     sebagai temuan Nit dan jangan ubah syarat tangkap atau gerak.
     (5) I2-F3 (pose jatuh vs kotak penutup pohon/lampu) tetap DEFERRED: ukur ulang dengan sel 140x88
     pada kombinasi data nyata (lampu dekat 24 / pohon 11 / pohon 8 lawan mobil seberang) dan catat
     angkanya; ubah hanya bila perbaikannya satu konstanta tanpa efek ke pose berkendara.
  B. Pose kucing ditangkap (P-3): KucingMisi/KucingHiasan menampilkan `ditangkap_1/_2` (kolom 7 dan 8,
     sheet `mission_kucing_sheet`, 3 fps) selama progres tangkap > 0 pada langkah `tangkap`, baris
     "masuk" seperti duduk; progres 0 = duduk; bar progres dan kilau tetap. Tampilan saja, tanpa
     mengubah titik pijak, kotak penutup, atau zona. Tes: frame benar menurut progres dan waktu,
     titik pijak tetap, tidak muncul di langkah bukan tangkap, jeda membeku, pembaca sheet memakai
     MISI_KUCING_KOLOM 9 (cek JSON = konstanta), tes misi lama lulus tanpa diubah. Perluas probe_misi_jendela
     (bar progres tangkap dengan pose ditangkap di empat ukuran, kidal).
  C. Ujung kerb jalan masuk (C-F1, P-2): tambahkan ubin ujung kerb ke tools/env_art/ubin_perumahan.py
     (keluaran deterministik, `--salin` memasangnya hanya untuk dua baris tetangga jalan masuk di
     sisi seberang), perluas `UbinKhusus`/`TanahDaur` agar memasangnya (posisi lain, batas jalan, dan
     sel_tanah tidak berubah), dan buat `cek_sambungan` untuk jalan masuk menjadi **0 piksel**
     (sekarang 22; hapus pengecualian C-F1 dari tes dan dokumen). Bukti: uji_aset_pasang_5b.py dan
     tes_ubin_5b.gd diperluas (susunan di game = adegan renderer, piksel-identik; referensi
     tests/data/ubin_potongan_5b.png diperbarui lewat skrip, bukan tangan); ubin yang tidak dipakai
     (aspal_N, *_dekat_masuk) TIDAK disalin; impor Nearest, Lossless, tanpa mipmap.
  D. Simpang T hiasan (P-1): (1) data: bidang opsional `simpang` di segmen (DATA_SCHEMA 3, usulan),
     daftar {pos, sisi: seberang|dekat}; validasi di SegmenRute (sisi dikenal, mulut simpang di dalam
     panjang segmen, tidak ada rumah/kavling, kotak surat, zona, dekor, rintangan, jalan masuk garasi,
     atau titik kucing misi di lebar mulut dan sudutnya); berkas segmen lama tanpa `simpang` tetap sah.
     RouteBuilder meneruskan simpang ke rute (posisi maju mutlak dan sisi) lewat satu fungsi baca yang
     kelak dipakai lalu lintas berbelok (M3), tanpa lalu lintas sekarang. (2) konten: tulis simpang di
     segmen baru atau segmen yang ada, secukupnya (minimal satu simpang seberang dan satu simpang dekat;
     ukur dan catat berapa persen rute dari 100 seed memuat simpang), tanpa mengurangi 25 pelanggan per rute. (3) tampilan:
     `--salin` ubin simpang (hanya yang dipakai), `UbinKhusus`/`TanahDaur` memasangnya termasuk lengan
     jalan samping yang berulang ke luar sejauh kolom yang tampil; sisi dekat: tembok dan rumah dekat
     terputus di mulut simpang; penutup pemain tidak berubah. Bukti: susunan simpang di game = adegan
     renderer piksel-identik (pola cek_simpang, oracle terpisah), ubin simpang deterministik di
     tools/tests_cek, sepeda bisa melintasi mulut simpang tanpa tabrakan dan tanpa perubahan gerak,
     zona tidak berubah. (4) tes lama: bila menambah segmen atau data mengubah susunan rute dari seed
     (pemilihan segmen, posisi rumah) dan karena itu angka tes lama berubah, utamakan cara yang
     mempertahankan susunan lama; bila tidak bisa, catat setiap tes yang angkanya berubah beserta
     alasannya di LOG dan minta putusan orchestrator, tanpa mengubah logika skor, lemparan, atau zona.
     Perluas probe_sisi_dekat_jendela atau buat probe simpang (simpang seberang, simpang dekat dengan
     tembok terputus, sepeda melintas, kidal, empat ukuran).
  E. Dokumen: ART_DIRECTION (3.4, 6.3, 11, Changelog; ganti "Dinilai di HP" bila perlu, jangan klaim
     sudah dinilai), DATA_SCHEMA 3 (bidang `simpang`), ROUTE_DESIGN (aturan simpang; bagian 8:
     persimpangan = hiasan dulu, keputusan pemilik 2026-10-22, lalu lintas berbelok M3), DEV_PHASES Fase 5 (perbarui catatan
     pembagian 5C; JANGAN mencentang butir aset sebelum dinilai di HP), LOOP-DEV-QA 6g (baris 5B =
     di-merge PR #49, baris 5C = status), AGENTS.md, docs/README.md, tools/loper_art/README.md bila
     perlu, SETUP_ANDROID 8.14 (checklist HP: jatuh lima arah terbaca dan pijak tidak melompat,
     bangkit mulus ke kayuh, terjerembab 0,2 detik terlalu singkat atau cukup, berhenti dengan kaki
     kanan terbaca saat menangkap kucing, kucing ditangkap terbaca bukan "mati", ujung kerb jalan
     masuk rapi, simpang terbaca sebagai jalan samping dan tidak dikira jalur yang harus dibelok,
     tembok dekat terputus wajar, 60 fps).
  Di LUAR scope (jangan dikerjakan atau diputuskan): lalu lintas di simpang (mobil/motor berbelok
  atau memotong, M3; hanya data simpangnya yang disiapkan), pemain berbelok masuk jalan samping,
  rute bercabang (ROUTE_DESIGN 8), lempar 90° (P-5), mengubah lama jatuh, syarat tangkap, atau gerak, polisi tidur, zebra, genangan,
  percikan, portal, pos satpam, tong biru (M3), aset M3 (hujan, jendela menyala, lampu nyala/malam,
  mobil tamu), audio, menggambar ulang sprite pemain (PNG hanya lewat renderer, jangan diedit tangan),
  Fase 6A2.
  Tes: semua di atas, ditambah seluruh keluaran 5B tetap hijau (tes tembok/dekor/ubin), paket
  --export-pack memuat sheet kucing 9 kolom dan frames.tres 68 animasi, real save sha256 tidak
  berubah, mutan nyata (satu perubahan, tes penuh, git checkout), probe empat ukuran dengan
  tangkapan layar yang DILIHAT QA; tes tidak boleh menulis save sungguhan.
  Keputusan terbuka yang mungkin menghambat: tidak ada (angka animasi, kaki kanan, 0,6 detik bangkit,
  dan letak simpang usulan sampai uji HP). Run ini lebih besar dari 5B: pecah Dev iterasi 1 menjadi
  bagian A+B, C+D, E (pola 5B), satu PR. Jangan mengunci palet induk. Bila ada hal baru, tanyakan SEKALI
  dengan satu rekomendasi.
  Git: judul PR memakai Conventional Commits (feat:, art:, ...); release-please membacanya (git-workflow
  bagian Rilis). Jangan mengedit CHANGELOG.md, .release-please-manifest.json, atau membuat tag.
  PENUTUP: DEV_PHASES Fase 5 tidak dicentang penuh (butir aset menunggu uji HP; polisi tidur, zebra,
  genangan, portal, pos satpam, aset M3 tetap M3); Fase 2, 3, 4, dan M2 tidak dicentang tanpa catatan
  uji HP pemilik. Satu PR.
HASIL UJI HP RUN 4A, 4B, 6A1, 5A, DAN 5B: BELUM ADA per 2026-10-22 (lembar SETUP_ANDROID 8.9 sampai
  8.13 belum diisi pemilik, tidak ada HP tersambung). Jadi Fase 2, 3, 4, M2, dan Fase 5 tidak dicentang;
  bila pemilik menempelkan catatan sebelum run, pakai catatan itu sebagai pengganti baris ini.
DESIGN: docs/design/character/loper_agen/{jatuh,bangkit,berhenti}/ (README, pratinjau, GIF), ubin simpang
  dari `python3 tools/env_art/ubin_perumahan.py` (build/env_art/ubin/simpang/, JSON posisi), dan
  docs/design/DESIGN_SPEC.md (token bagian 1); tidak ada layar baru.
IZIN HP: boleh memasang APK ke vivo V2108 (adb 12d8c9da) setelah QA PASS dengan `adb install -r`
  (izin tetap pemilik 2026-10-17, tanpa bertanya lagi); A54 (RRCWA05E2NN) hanya bila tersambung.
  Hanya orchestrator yang menyentuh HP; cek layar menyala dan tidak sedang dipakai; tidak ada
  uninstall/logcat -c. Edit save.json lewat run-as lebih disukai daripada pm clear, dan pm clear
  com.rmh.kring boleh bila perlu (izin pemilik 2026-10-18), tetapi catat save yang dipakai di LOG.
  APK debug lokal dibangun dengan `godot --headless --export-debug "Android"`; CI juga membuat APK
  uji di setiap PR (artifact build-apk, SETUP_ANDROID 4b).
  Push, PR, dan merge tetap menunggu konfirmasi pemilik.
RUN_ID: 20261022-fase5c-animasi-simpang
```

## 6j. Fase 5: perintah Run 5D (tempel di sesi baru)

Disimpan 2026-10-22, sesudah Run 5C di-merge (PR #52) dan perbaikan CI (PR #53). Pemilik menguji HP 2026-10-22 ("untuk uji hp sejauh ini oke semua"; revisi garis kecepatan sudah masuk #52), lalu memutuskan tiga hal yang mengubah keputusan lama: tembok sisi dekat (ROADMAP 4b, 2026-10-17) **dihapus** karena membuat sisi dekat terlihat berbeda dari sisi jauh; pelanggan di sisi dekat **dimajukan** dari Fase 8 ke Fase 5 (sebelum 6A2, supaya model pelanggan 6A2 dibangun di atas dua sisi); dan rumah dekat **mundur 0,5 ubin** sesudah melihat tangkapan mundur 0,25 sampai 1,5 tanpa tembok.

Angka ukur mundur tanpa tembok (oracle piksel `UkurPenutupPiksel`, sprite rumah dekat `_bukan` nyata, kasus terburuk antarjenis, hampir selalu `dekat_pelana_lintang`; tangkapan di `build/` sesi orchestrator, tidak dikomit):

| Mundur (ubin) | Badan kotak surat dekat tertutup | Zona kotak surat (cermin seberang / zona dekat sekarang) | Pemain di trotoar dekat, maks | Halaman terlihat, median |
|---|---|---|---|---|
| 0,25 | 97,3% | 90,6% / 87,5% | 45,0% | 0,22 |
| **0,5 (dipilih)** | **44,3%** | **68,5% / 58,0%** | **27,3%** | **0,47** |
| 0,75 | 1,4% | 43,5% / 24,8% | 10,5% | 0,72 |
| 1,0 | 0% | 18,6% / 3,9% | 1,9% | 0,97 |
| 1,25 (sekarang) | 0% | 2,9% / 0% | 0% | 1,22 |

Pemain di lajur dekat 0% mulai mundur 0,5. Rumah dekat yang lewat masuk ke bawah panel HUD bawah di semua nilai mundur (bukan efek mundur). Varian sprite rumah dekat `_pelanggan` punya kotak surat merah terpanggang di gambarnya.

**Putusan orchestrator Bagian 6j (usulan, bisa ditolak di review PR; jangan ditanyakan ulang):**

- **P-1 Halaman terbuka sisi dekat** (pemilik 2026-10-22): tembok dan tiang sisi dekat tidak lagi dipasang di rute; kavling dekat = halaman rumput terbuka seperti sisi jauh (jalan setapak, kotak surat di tepi trotoar). Rumah dekat digambar mundur **0,5 ubin** (`RUTE_RUMAH_DEKAT_MUNDUR_UBIN` 1,25 -> 0,5, pilihan pemilik). Aset tembok yang tidak dipakai lagi tidak disalin ke `assets/` (pola `--salin` hanya yang dipasang); kode `TembokDekat`/`VarianTembok` dihapus atau dilepas dari rute, keputusan Dev dicatat. ROADMAP 4b ditandai diganti, riwayat lama tetap.
- **P-2 Rumah dekat didesain ulang lewat renderer** (pemilik: "teras seharusnya terlihat dari samping, teras lebih panjang menjorok ke depan"): rumah dekat punya teras yang menjorok ke arah jalan sehingga terbaca dari samping walau kamera melihat rumah dari belakang; bentuk atap di sisi jalan boleh dibuat lebih rendah atau landai bila itu mengurangi penutupan; tanpa kotak surat terpanggang di sprite (kotak surat = sprite terpisah). Prasyarat: `fase3.py --salin` harus dulu menghasilkan ulang isi `assets/` yang sekarang (temuan PR #53: rumah `dekat_pelana_lintang` beda 40 piksel, sheet mobil garasi beda 9 piksel, tanpa tes penjaga); perbaiki dan tambahkan uji `tools/tests_cek` untuk rumah dan rintangan fase3 sebelum menggambar ulang.
- **P-3 Pudar hanya sebagai pelengkap, khusus rumah pelanggan dekat yang belum terantar** (menjawab pertanyaan pemilik "atau dibikin opacity aja, khusus yang pelanggan"): rumah tidak dibuat semi-transparan permanen (pendekatan "penuh semi-transparan" di spike run 3C paling buruk: 40%/78% sasaran tertutup dan layar ramai). Urutan: (a) desain P-2 sampai sasaran terlihat; (b) bila angka di bawah belum tercapai, rumah pelanggan dekat yang belum terantar memudar lewat SATU penerap yang ada (`PenerapPenutup`) hanya saat menutupi kotak surat sasaran yang sedang dalam jangkauan, garis bidik, koran terbang, atau pemain; rumah bukan pelanggan dan pelanggan yang sudah terantar memakai aturan penutup pemain biasa.
- **P-4 Pelanggan dekat mulai hari 3, sekitar 35%** (pemilik 2026-10-22): hari 1 dan 2 tetap hanya pelanggan seberang (tutorial alami GDD 9.1, diubah jadi "mulai hari 3"); sejak hari 3, 8 atau 9 dari 25 pelanggan di sisi dekat; total 25 per rute tetap, jadi tenggat dan skor tidak bergeser karena jumlah. Hari masuk ke `RouteBuilder` dari `HariMain`/`SeedHari` (tanpa RNG baru di luar seed hari); `rute.tscn` dan probe yang berjalan sendiri memakai perilaku hari 1 kecuali diberi hari. Titik kucing misi P1 tetap di rumah seberang.
- **P-5 Sasaran dekat = cermin sasaran seberang**: kotak surat oranye pelanggan dan abu-abu bukan pelanggan di tepi trotoar dekat, zona kotak surat, teras (mengikuti teras baru P-2), dan halaman dengan aturan penilaian, prioritas, dan angka skor yang sama (BALANCING 5); zona dekat placeholder jalan uji boleh tetap. Sasaran yang terlihat = yang dinilai (prediksi = hasil). Lempar ke sisi dekat memakai animasi yang sudah ada (`lempar_kanan_*`); lempar 90° tetap di luar scope.
- **P-6 Satu tip sekali di hari 3**: hari pertama ada pelanggan dekat, satu tip singkat (kunci terjemahan baru di `translations/ui.csv`) memberi tahu bahwa pelanggan kini juga ada di sisi dekat. Ditentukan dari nomor hari, tanpa bidang save baru.

### Run 5D — pelanggan sisi dekat, halaman terbuka, rumah dekat dengan teras menjorok

Prasyarat: **PR #52 (Run 5C) dan PR #53 sudah di-merge ke `main`.** Kalau belum, berhenti dan minta pemilik merge dulu.

```text
Kamu adalah ORCHESTRATOR loop Dev↔QA untuk repo Loper Koran. Ikuti docs/LOOP-DEV-QA.md
secara ketat (Bagian 1, Bagian 0c, Bagian 6g dan 6j). Mulai dari main terbaru yang sudah memuat
Run 5C (PR #52) dan perbaikan CI (PR #53). Baca dulu: docs/loop/20261022-fase5c-animasi-simpang/{SPEC,LOG}.md
dan docs/loop/20261021-fase5b-tembok-dekor/{SPEC,LOG}.md (pola --salin, oracle piksel
tests/ukur_penutup_piksel.gd, PenerapPenutup, golden rute dihitung skrip), spike sisi dekat run 3C
(docs/loop/20261018-fase3c-hud-hasil/, shots/spike_sisi_dekat/), ROADMAP 4b, GDD 4.2 dan 9.1,
ROUTE_DESIGN, BALANCING 5, DATA_SCHEMA 3, ART_DIRECTION 6.4-6.6, tools/env_art/fase3.py,
scripts/systems/{route_builder,segmen_rute,zona_sasaran,medan_koran,bantu_lempar,radar_rute,
sprite_rumah,tembok_dekat,penutup_pemain,seed_hari}.gd, scripts/entities/{rumah_daur_rute,rute_main,
hari_main,penerap_penutup}.gd, rule art-assets, content-data, gdscript, balancing, testing, ui-scenes:
keputusan yang sudah ada berlaku, jangan ditanyakan ulang. Bagian 6j mungkin belum ada di main;
putusan di bawah berlaku walaupun begitu.

PUTUSAN (usulan, bisa ditolak di review PR; jangan ditanyakan ulang):
  P-1 Tembok sisi dekat dihapus (pemilik 2026-10-22): kavling dekat = halaman terbuka seperti sisi
      jauh; rumah dekat digambar mundur 0,5 ubin (RUTE_RUMAH_DEKAT_MUNDUR_UBIN 1,25 -> 0,5).
  P-2 Rumah dekat didesain ulang lewat renderer: teras menjorok ke arah jalan, terbaca dari samping;
      atap sisi jalan boleh lebih rendah/landai; tanpa kotak surat terpanggang di sprite.
  P-3 Tidak ada semi-transparan permanen. Bila desain belum cukup, HANYA rumah pelanggan dekat yang
      belum terantar memudar lewat PenerapPenutup saat menutupi sasaran dalam jangkauan, garis bidik,
      koran terbang, atau pemain.
  P-4 Pelanggan dekat mulai hari 3, 8 atau 9 dari 25 pelanggan (sekitar 35%); hari 1-2 hanya seberang;
      total 25 tetap; titik kucing misi tetap di seberang.
  P-5 Sasaran dekat = cermin seberang (kotak surat oranye/abu-abu di tepi trotoar dekat, zona kotak
      surat, teras, halaman; aturan dan angka skor sama). Lempar ke dekat memakai lempar_kanan_*.
  P-6 Satu tip sekali di hari 3 (kunci terjemahan baru), dari nomor hari, tanpa bidang save baru.

SCOPE: Run 5D — Fase 5 (dimajukan dari Fase 8 oleh pemilik 2026-10-22): pelanggan di sisi dekat,
  halaman terbuka, rumah dekat dengan teras menjorok. ThrowSolver (lintasan), BikeMotion, tabrakan,
  tenggat (rumus), skor (angka), MissionManager/RencanaMisi, kondisi sepeda, bengkel, Economy, dan
  format save tidak berubah. Perubahan tes lama hanya bila disebabkan langsung oleh putusan di atas;
  catat SETIAP tes lama yang angkanya berubah beserta alasannya di LOG, dan golden rute yang berubah
  dihitung ulang oleh skrip (bukan tangan) dengan bukti per golden bahwa perbedaannya hanya akibat
  P-1/P-4/P-5 (pola banding P-6 run 5C).
  A. Rumah dekat dan halaman terbuka (P-1, P-2, P-3):
     (1) Baseline di LOG: jumlah tes, pemeriksa, semua uji_*.py, sha256 save asli, di main sebelum
     mengubah apa pun.
     (2) Perbaiki dulu reproduksi fase3.py: `--salin` harus menghasilkan isi assets/ yang sekarang
     piksel demi piksel (sekarang rumah dekat_pelana_lintang beda 40 piksel, obs_mobil_garasi_sheet
     9 piksel); tambahkan uji di tools/tests_cek (deterministik, isi assets/ = keluaran, juga di CI
     Linux; pakai mm()/panjang() dari engine sesuai tools/env_art/README). Bila assets/ yang sekarang
     ternyata tidak bisa dihasilkan ulang tanpa mengubah piksel, putuskan versi skrip sebagai sumber
     kebenaran dan catat bedanya.
     (3) Desain ulang rumah dekat (semua jenis dekat, pelanggan dan bukan) di fase3.py: teras menjorok
     ke arah jalan terbaca dari samping, atap sisi jalan boleh lebih rendah, tanpa kotak surat
     terpanggang; mock di docs/design/environment/; titik pijak JSON; --salin hanya yang dipakai.
     (4) Lepas tembok dari rute, mundur 0,5, halaman terbuka (jalan setapak boleh lewat ubin atau
     sprite yang ada; tidak ada aset tembok tersisa di assets/ bila tidak dipakai). Simpang: logika
     "tembok terputus" ikut disederhanakan, data simpang tetap sah.
     (5) Ukur dengan oracle piksel (pola run 5B/5C, semua jenis rumah dekat baru, tetangga, Y-sort):
     badan kotak surat dekat, zona kotak surat dekat, teras dekat, pemain di lajur dan trotoar dekat,
     koran terbang ke sasaran dekat. SASARAN: badan kotak surat dekat 0% tertutup, zona kotak surat
     dekat <= 5%, pemain di lajur dekat 0%, pemain di trotoar dekat 0% sesudah aturan pudar. Bila
     desain (3) tidak mencapainya, terapkan P-3 (pudar khusus pelanggan dekat yang belum terantar)
     lewat PenerapPenutup dan ukur lagi; kotak penutup = sprite nyata (pelajaran P-6 run 5B).
  B. Pelanggan dan sasaran sisi dekat (P-4, P-5, P-6):
     (1) Data: rumah dekat `pelanggan_boleh` di segmen secukupnya supaya tiap rute hari >= 3 bisa
     memilih 8-9 pelanggan dekat dari 25 dengan jarak antar pelanggan wajar; validasi SegmenRute
     (kotak surat dekat tidak bertumpuk dengan dekor, rintangan, jalan masuk, simpang); DATA_SCHEMA 3.
     (2) RouteBuilder: kuota sisi dari nomor hari (hari 1-2: 0 dekat; >= 3: 8 atau 9), deterministik
     dari seed hari, tanpa RNG baru di luar seed; hari masuk dari HariMain; rute.tscn/probe sendiri =
     perilaku hari 1 kecuali diberi hari. Ukur dan catat untuk 100 hari (3..102): jumlah dekat per rute
     (harus 8 atau 9), jarak, dan persentase.
     (3) Sasaran dekat: kotak surat oranye pelanggan dan abu-abu bukan pelanggan di tepi trotoar dekat,
     zona (ZonaSasaran/MedanKoran) cermin seberang dengan teras baru, prediksi = hasil (oracle gambar
     independen seperti QA-008), mode bantu ke sisi dekat (sisi tap, sasaran terdekat di depan), radar
     dan progres menampilkan pelanggan dekat, koran terlipat di teras dekat, tip dan skor sama aturannya.
     Bot bantu menyelesaikan 25 pelanggan di 20 seed hari >= 3 tanpa lewat tenggat.
     (4) Tip hari 3 (P-6): satu tip singkat, kunci baru di translations/ui.csv, tidak muncul di hari lain,
     tanpa save baru; tutorial hari 1 tidak berubah.
     (5) Probe: perluas probe_sisi_dekat_jendela atau buat probe baru: halaman terbuka, rumah dekat baru
     (semua jenis), teras dari samping, bidik dan lempar ke kotak surat dekat (kena, meleset, teras,
     halaman), mode bantu dekat, radar, pudar P-3 bila dipakai, hari 2 tanpa pelanggan dekat, hari 3 dengan
     tip, kidal, empat ukuran (2340x1080, 1920x1080, 2400x1080, 1600x720); mencetak keadaan tidak sesuai;
     tangkapan DILIHAT QA.
  C. Dokumen dan penutup: GDD 4.2 dan 9.1 (pelanggan dekat mulai hari 3), ROADMAP 4b (tembok diganti
     halaman terbuka, mundur 0,5, keputusan pemilik 2026-10-22, riwayat tetap), ROUTE_DESIGN, BALANCING 5
     (zona dekat), DATA_SCHEMA 3, ART_DIRECTION (6.x rumah dekat, Changelog), DEV_PHASES (catatan;
     butir pelanggan dua sisi Fase 8 ditandai dimajukan ke 5D; jangan mencentang aset sebelum uji HP),
     LOOP-DEV-QA 6g (baris 5D), AGENTS.md, docs/README.md, tools/env_art/README.md, SETUP_ANDROID 8.16
     (checklist HP: halaman dekat terbaca seperti sisi jauh, teras dekat terbaca dari samping, kotak surat
     dekat mudah dibidik, rumah dekat tidak menutupi sepeda, pudar tidak mengganggu bila dipakai, hari 3
     tip terbaca, 8-9 pelanggan dekat terasa adil terhadap tenggat, rumah dekat di bawah panel HUD bawah
     mengganggu atau tidak, 60 fps).
  Di LUAR scope (jangan dikerjakan atau diputuskan): reputasi, kepribadian, pelanggan tetap/berhenti,
  milestone (6A2), save baru, mengubah ThrowSolver/BikeMotion/tenggat/angka skor, lempar 90°, misi
  kucing di sisi dekat, mengubah HUD bawah (hanya diukur dan dicatat), polisi tidur, zebra, genangan,
  portal, pos satpam, tong biru, aset M3, audio baru, menggambar ulang sprite pemain.
  Tes: semua di atas, ditambah keluaran 5A/5B/5C tetap hijau kecuali yang disebabkan P-1/P-2/P-4/P-5
  (dicatat), paket --export-pack memuat rumah dekat baru dan tidak memuat aset tembok bila tidak
  dipakai, real save sha256 tidak berubah, mutan nyata (satu perubahan, tes penuh, git checkout;
  Dev >= 30, QA mengulang >= 10 pilihannya sendiri), probe empat ukuran dengan tangkapan yang DILIHAT
  QA; tes tidak boleh menulis save sungguhan; satu proses Godot sekaligus.
  Keputusan terbuka yang mungkin menghambat: bila desain P-2 tidak mencapai sasaran A(5) dan pudar P-3
  terasa mengganggu di tangkapan, berhenti dan tanyakan SEKALI dengan satu rekomendasi (misalnya
  mundur 0,75). Run ini besar: pecah Dev iterasi 1 menjadi bagian A, B, C (pola 5B/5C), satu PR.
  Git: judul PR memakai Conventional Commits; jangan mengedit CHANGELOG.md, .release-please-manifest.json,
  atau membuat tag.
  PENUTUP: butir aset Fase 5 tidak dicentang sebelum uji HP 8.16; butir pelanggan dua sisi di Fase 8
  diberi catatan "dimajukan ke Run 5D".
HASIL UJI HP: pemilik 2026-10-22 "untuk uji hp sejauh ini oke semua"; revisi garis kecepatan sudah
  diperbaiki di PR #52. Checklist 8.14 dan 8.15 (Run 5C dan hapus area kotak surat) belum diisi.
DESIGN: spike sisi dekat run 3C (tangkapan), mock rumah dekat baru dibuat di run ini
  (docs/design/environment/), docs/design/DESIGN_SPEC.md (token bagian 1); tidak ada layar baru selain tip.
IZIN HP: boleh memasang APK ke vivo V2108 (adb 12d8c9da) setelah QA PASS dengan `adb install -r`
  (izin tetap pemilik 2026-10-17, tanpa bertanya lagi); A54 (RRCWA05E2NN) hanya bila tersambung.
  Hanya orchestrator yang menyentuh HP; cek layar menyala dan tidak sedang dipakai; tidak ada
  uninstall/logcat -c. Edit save.json lewat run-as lebih disukai daripada pm clear, dan pm clear
  com.rmh.kring boleh bila perlu (izin pemilik 2026-10-18), tetapi catat save yang dipakai di LOG.
  APK debug lokal dibangun dengan `godot --headless --export-debug "Android"`; CI juga membuat APK
  uji di setiap PR (artifact build-apk, SETUP_ANDROID 4b).
  Push, PR, dan merge tetap menunggu konfirmasi pemilik.
RUN_ID: 20261022-fase5d-sisi-dekat
```

## 6k. Redesain UI: perintah Run UI-1 (tempel di sesi baru)

Disimpan 2026-10-23, sesudah Run 6A2 di-merge (PR #58, `main` = rilis 0.6.0). Pemilik menguji HP 2026-10-23 dan menilai UI layar penuh terlalu kecil, terlalu kosong, dan tombolnya polos; kanvas Claude Design "UI Loper Koran — Redesain" ([`design/redesain/README.md`](design/redesain/README.md)) menjawabnya. Porting dipecah per layar, satu PR per run (README redesain bagian 6). Run ini hanya langkah 1 dan 2:

| Run | Isi | Prasyarat |
|---|---|---|
| UI-1 | Komponen UI bersama (tombol empat peran, kartu, panel layar, chip, kotak kondisi besar) dan layar bengkel tata C. **Status (2026-10-23): dikerjakan Dev iterasi 1 (bagian A, B, C) di branch `feat/ui1-komponen-bengkel`, menunggu QA dan uji HP 8.18** (`docs/loop/20261023-ui1-komponen-bengkel/`) | 6A2 di-merge (PR #58) |
| UI-2 | Hasil (struk), koran, jeda dengan tutorial dan banner, HUD, skala font, dan latar hasil, dalam SATU PR (permintaan pemilik 2026-10-24). **Status (2026-10-24): lolos QA iterasi 1 dan di-merge (PR #66), menunggu uji HP 8.19** (`docs/loop/20261024-ui2-semua-layar/`; baris 6l) | UI-1 di-merge (PR #64, sudah) |

Perintah di bawah ringkasan dari SPEC run (`docs/loop/20261023-ui1-komponen-bengkel/SPEC.md`, kontraknya), bukan salinan kata demi kata dari pesan pemilik.

**Putusan orchestrator Bagian 6k (usulan, bisa ditolak di review PR; jangan ditanyakan ulang):**

- **U-1 Bengkel tata C**: sepeda dan tiga baris servis di satu panel kiri, upgrade di kolom kanan (kolom servis 48% | 8 | upgrade). Kondisi terbaca dari sepeda (chip "! Ban" atau "Rantai aus" di titik `titik_kecil` dari `sepeda.json`; sepeda baik bersih). Harga selalu chip di sebelah tombolnya. PERLU SERVIS = kartu menonjol bergaris WARN; Baik atau Dimiliki = kartu redup. Upgrade tingkat 2-3 tidak menambah kartu (kartu sama berganti isi, jejak I · II · III). Tiga kartu upgrade muat tanpa scroll di 640 dan 800.
- **U-2 Satu bahasa tombol**: empat peran (utama, biasa, sakelar, tenang); 9-slice dari aset kanvas; ditekan = wajah turun 2 px; nonaktif rata, diarsir, teks berganti alasan ("Koin kurang"), terbaca tanpa warna. "Hari berikutnya" 140x42 aksi utama, SELALU aktif, kanan bawah.
- **U-3 Komponen sebagai fungsi BARU** di `GayaHud` dan type variation BARU di `assets/ui/theme.tres`; `GayaHud.terapkan_tombol`, `kotak`, `panel_hud`, dan variation lama TIDAK diubah.
- **U-4 Latar bengkel dipasang untuk uji HP** walau lisensi generatornya belum dicatat: butir terbuka pemilik di LOG dan README redesain; ART_DIRECTION 9 menandainya belum boleh masuk rilis; tidak memblokir run. Latar tidak boleh menurunkan kontras (teks >= 7:1, garis komponen >= 3:1) diukur dari tangkapan nyata.
- **U-5 Tidak ada angka ekonomi atau aturan permainan yang berubah.** Teks hanya dari `translations/`; kunci baru seperlunya di `ui.csv`.

```text
Kamu adalah ORCHESTRATOR loop Dev↔QA untuk repo Loper Koran. Ikuti docs/LOOP-DEV-QA.md secara ketat
(Bagian 1, Bagian 0c, dan Bagian 6k). Mulai dari main terbaru yang sudah memuat Run 6A2 (PR #58).
Baca dulu: docs/design/redesain/README.md (semua), docs/design/redesain/kanvas/{ui.css,Bengkel*.dc.html,
Spesifikasi.dc.html}, docs/design/redesain/aset/{meta.json,sepeda.json}, tools/ui_art/redesain/*.py,
tools/tests_cek/uji_ui_redesain.py, docs/design/DESIGN_SPEC.md (1.1-1.3, 3.3, 4 baris Bengkel),
docs/loop/20261020-fase6a1-bengkel-kondisi/{SPEC,LOG}.md, docs/loop/20261023-fase6a2-reputasi-pelanggan/{SPEC,LOG}.md,
scenes/bengkel/bengkel.tscn, scripts/ui/{layar_bengkel,kotak_kondisi,gaya_hud,tombol_sentuh,palette}.gd,
assets/ui/theme.tres, scripts/systems/{economy,tampil_kondisi,data_toko,pemuat_toko}.gd,
tests/{tes_bengkel_scene,tes_kondisi_scene,tes_tata_letak,probe_bengkel_jendela}.gd, rule ui-scenes,
art-assets, gdscript, testing, docs, git-workflow. Pelajaran lama: tekstur dimuat di _init/_ready,
bukan _draw; satu proses Godot sekaligus; tes tidak menulis save sungguhan; pola --salin memasang HANYA
yang dipakai; mutan nyata (Dev >= 30, QA mengulang >= 10 pilihannya sendiri); QA mengukur sendiri
dan MELIHAT tangkapan. Keputusan yang sudah ada berlaku, jangan ditanyakan ulang.

PUTUSAN (usulan, bisa ditolak di review PR; jangan ditanyakan ulang): U-1 .. U-5 di atas.

SCOPE: Run UI-1 — redesain UI langkah 1 dan 2 (komponen + bengkel tata C). Tidak ada angka ekonomi
  atau aturan permainan yang berubah.
  A. Komponen: (1) baseline di LOG (tes, pemeriksa, semua uji_*.py, sha256 save asli
     37d6d6cb98a428a8d2cf68673a0090848e60de15b79fdfba9830d7552f9a549e); (2) komponen.py --salin
     (+ sepeda_fullbody.py/latar_bengkel.py --salin hanya menyalin berkas resmi docs/; UI_ART_SALIN_KE
     untuk uji) memasang HANYA yang dipakai bengkel ke assets/sprites/ui/ dengan .import Lossless;
     (3) uji_ui_redesain.py diperluas dan langkahnya di job `alat` tes.yml; (4) GayaHud.tombol_*,
     kartu_*, panel_layar, chip + type variation baru di theme.tres, fungsi lama tidak berubah, layar
     lain tidak berubah tampilannya (tangkapan sebelum/sesudah piksel sama); (5) kotak kondisi besar
     8x8 (jarak 2, "!" 3x9, berongga = AUS), KotakKondisi 14 px di HUD tidak berubah; tes murni
     pemilihan keadaan tombol/kartu/chip terbaca tanpa warna.
  B. Bengkel tata C: bengkel.tscn dan layar_bengkel.gd dibangun ulang dari kanvas (header y 11, isi
     y 46, margin 12 + inset aman, kolom 48% | 8 | upgrade, kartu servis x50 dan upgrade x62, chip
     harga 18, sepeda kecil 116x78 dengan chip di titik sepeda.json, papan alat, latar), lentur 640..800
     (anchor + Container), tiga upgrade tanpa scroll, tanpa hex di scene; keadaan a-g dari data nyata,
     tingkat 2-3 sebagai model tampilan dengan data uji (upgrades.json tidak berubah); perilaku tidak
     berubah (sinyal, API tes, Economy, simpan tepat sekali, Hari berikutnya selalu aktif, back Android);
     setiap tes lama yang diubah dicatat di LOG; tombol >= 42 tinggi dan >= 84 lebar, tanpa teks terpotong
     atau tumpang tindih, kontras diukur dari tangkapan nyata; probe_bengkel_jendela.gd diperbarui (empat
     ukuran + lebar 800, mencetak keadaan tidak sesuai), tangkapan DILIHAT QA.
  C. Dokumen dan penutup: DESIGN_SPEC 4 baris Bengkel, ART_DIRECTION 6.8/Changelog/9, redesain/README.md
     (bagian 6 butir 1-2, lisensi latar), tools/ui_art/README.md, AGENTS.md, docs/README.md,
     DEV_PHASES (catatan; aset UI TIDAK dicentang sebelum uji HP), SETUP_ANDROID 8.18, LOOP-DEV-QA 6k.
  Di LUAR scope (jangan dikerjakan atau diputuskan): layar hasil, koran, jeda, tutorial, banner, HUD
  rute (UI-2 dan seterusnya); lapisan jeda 72%; kunci teks koran "Iklan baris" dan hasil "Pelanggan:";
  upgrade baru atau tingkat 2-3 yang nyata (upgrades.json); ekonomi 6B; iklan hadiah (Fase 14);
  menyalin aset koran/struk/foto/lencana32 ke assets/; mengubah palet atau font induk; mencentang
  butir aset UI sebelum uji HP 8.18.
  Tes: semua di atas, keluaran 6A1/6A2/5x tetap hijau kecuali yang disebabkan U-1..U-5 (dicatat),
  paket --export-pack memuat aset bengkel baru dan TIDAK memuat aset redesain yang tidak dipasang,
  sha256 save asli tidak berubah, mutan nyata khusus logika tampilan bengkel (satu perubahan, tes
  penuh, git checkout; Dev >= 30, QA mengulang >= 10 pilihannya sendiri); tes tidak menulis save
  sungguhan; satu proses Godot sekaligus. Keputusan terbuka yang mungkin menghambat: bila tata C tidak
  muat di 640 untuk teks terpanjang, berhenti dan tanyakan SEKALI dengan satu rekomendasi.
  Git: judul PR Conventional Commits; jangan mengedit CHANGELOG.md, .release-please-manifest.json,
  atau membuat tag. Push, PR, dan merge menunggu konfirmasi pemilik.
HASIL UJI HP: pemilik 2026-10-22 "untuk uji hp sejauh ini oke semua" (6A1/6A0); uji 6A2 (8.17) belum
  diisi dan tidak memblokir run ini.
DESIGN: docs/design/redesain/ (kanvas, aset, README); tidak ada layar baru.
IZIN HP: boleh memasang APK ke vivo V2108 (adb 12d8c9da) setelah QA PASS dengan `adb install -r`
  (izin tetap pemilik 2026-10-17, tanpa bertanya lagi); A54 (RRCWA05E2NN) hanya bila tersambung.
  Hanya orchestrator yang menyentuh HP; cek layar menyala dan tidak sedang dipakai; tidak ada
  uninstall/logcat -c. Edit save.json lewat run-as lebih disukai daripada pm clear; pm clear
  com.rmh.kring boleh bila perlu (izin pemilik 2026-10-18), catat save yang dipakai di LOG.
RUN_ID: 20261023-ui1-komponen-bengkel
```

**Catatan run UI-1 (dikerjakan 2026-10-23; SPEC dan LOG di `docs/loop/20261023-ui1-komponen-bengkel/`):** dipecah tiga bagian Dev berurutan (A komponen, B bengkel, C dokumen). Pelajaran: (1) set aset yang dipasang didaftar SATU tempat (`tools/ui_art/redesain/pasang.py`) dan dibaca skrip `--salin` serta uji, jadi "hanya yang dipakai" ditegakkan mesin, bukan disiplin; (2) pola penolakan aset lampu nyala di `uji_aset_pasang_5b.py` terlalu luas dan salah menandai `ui_btn_sakelar_nyala.png`, gerbang bagian B menangkapnya; (3) label berbungkus kata yang baru tampil menghitung tinggi dengan lebar 0 dan Control menyimpan ukuran itu di offsetnya (isi bergeser ke atas); `LayarBengkel._pulihkan_batas` menegakkan persegi penuh; (4) peringatan kontras harus diukur dari tangkapan nyata (`tools/ukur_kontras_tangkapan.py`), bukan dari token: WARN di atas `UI_PANEL` 6,91:1 dan chip diredupkan 3,65:1 baru ketahuan di tangkapan; (5) `git checkout` milik harness mutan bisa membuang suntingan yang belum di-commit, jadi commit dulu sebelum mutan. Mutan nyata bagian B: 50 dari 50 tertangkap sesudah sembilan tes ditambah.

## 6l. Redesain UI: Run UI-2 (dikerjakan 2026-10-24)

SPEC dan LOG di `docs/loop/20261024-ui2-semua-layar/`, branch `feat/ui2-semua-layar` dari `main` 0.7.0 (memuat PR #64 UI-1). Menggantikan "satu layar per run" (6k) atas permintaan pemilik 2026-10-24 ("langsung aja semua jadi 1 PR"): langkah 3 sampai 6 porting redesain (hasil, koran, jeda/tutorial/banner, HUD) dalam satu PR, ditambah tiga amandemen pemilik yang masuk sesudah SPEC ditulis: V-8 skala font +2 di semua layar penuh (bengkel ikut), V-9 tata ulang HUD (kecepatan dan stamina berdampingan, kolom kanan atas dua baris), dan V-10 layar hasil di atas lingkungan yang baru dilalui dengan struk transparan. Dev iterasi 1 dipecah lima bagian berurutan, commit sendiri-sendiri: A (font V-8, komponen, hasil), B (koran), C (jeda, tutorial, banner, HUD V-9), E (V-10 dan tanda bar 90 persen), D (dokumen). Lolos QA iterasi 1 dan di-merge (PR #66, 2026-10-24); menunggu uji HP 8.19.

| Ringkasan | Nilai |
|---|---|
| Tes sesudah Dev | 28487 lolos, 0 gagal (baseline 23406); semua 17 `uji_*.py` exit 0; probe 0 keadaan tidak sesuai di 1920x1080, 2340x1080, 2400x1080, 1600x720 |
| Mutan nyata Dev | A 34/34, B 32/32 (+1 setara), C 41/41 (+1 setara), E 25/25 tertangkap |
| Aset | 32 berkas baru lewat `--salin` (total redesain terpasang 62), set tepat dijaga `uji_ui_redesain.py` |
| Kunci teks baru | `KORAN_IKLAN_BARIS`, `MISI_PETUNJUK_LABEL` (V-3) |
| Butuh keputusan pemilik (DEFERRED) | kata status FAIL HUD (LELAH, HABIS, PUTUS) 3,7 sampai 4,8:1 pra-ada; banner misi 24 huruf menyentuh panel baris 2 di 640 saat reputasi tampil; aset lencana lama 14x14 tak terpakai; lisensi latar bengkel; ikon banner misi kanvas tidak dipasang |

Pelajaran run ini: (1) tampilan baru yang memakai transparansi harus diukur dari tangkapan nyata terhadap latar terburuk, bukan dari token: struk transparan menjatuhkan teks hijau `OK` dari 7,34 ke 6,91:1 dan baris tanpa panel dari 7 ke 3,5:1 (di atas dunia terang); tangkapan kedua tanpa teks (`_latar.png`) membuat pengukuran per piksel mungkin, dan penggelapan RGB panel lebih murah daripada menaikkan alpha lapisan; (2) angka yang tertulis di spesifikasi bisa menyesatkan (tanda bar 80 persen padahal ambang sprite di 90 persen bar): turunkan angka dari kode dengan tes, bukan menyalin; (3) pemeriksa tata letak murni (`TampilXxx`) dengan oracle literal kanvas menangkap pergeseran 1 px yang tidak terlihat mata; (4) tangkapan pertama probe jendela dan animasi di sekitar pemain tidak deterministik, jadi perbandingan piksel HUD memakai daftar pengecualian tertulis; (5) elemen yang disembunyikan lewat per-frame (tip) tetap tampak satu frame bila layar baru dipotret langsung: sembunyikan juga seketika; (6) `git checkout` mutan hanya aman bila kode sudah di-commit.

## 6m. Garis finish dengan portal satpam (dikerjakan 2026-10-24)

SPEC dan LOG di `docs/loop/20261024-garis-finish-portal/`, branch `feat/garis-finish-portal` dari `main` 92255fa (rilis 0.7.0 + PR #66 UI-2). Usulan pemilik 2026-10-22, dikonfirmasi 2026-10-24 (ROADMAP 5): sepeda melaju otomatis keluar viewport menggantikan rem di garis akhir, dengan portal satpam sebagai penanda di dunia. Dev iterasi 1 dipecah empat bagian berurutan, commit sendiri-sendiri: A (aset portal dipasang lewat `render.py --salin`, baseline, G-1a), B (logika murni `AkhirRute`, `HasilRute.siap_tampil`, konstanta), C (scene: `PortalGaris`, gerak keluar, pembekuan kamera dan dunia, golden `main`, probe), D (dokumen). QA dan iterasi 2 belum.

**Putusan orchestrator (usulan, bisa ditolak di review PR; jangan ditanyakan ulang):**

- **G-1 Penanda = HANYA `prop_portal_satpam`** (dua frame, tertutup saat jauh, membuka mendekat); `prop_pos_satpam` tidak dipasang (M3). **G-1a (amandemen setelah ukuran Dev bagian A):** sel dan pijak semula 80x64 dan (14, 48) hanya berasal dari deskripsi ROADMAP; terukur memotong palang terbuka dan kaki penyangga tertutup, jadi diperbesar lewat renderer ke 80x92 dan pijak (14, 60).
- **G-2 Sesudah garis akhir** sepeda tidak direm: melaju lurus dengan laju minimal santai (diubah Bagian F, permintaan pemilik 2026-10-24: level ngebut 6,0 u/d, efek kondisi dan lelah dilepas, hiasan perumahan `HiasanRute` tetap tampak di depan portal) sampai seluruh badan keluar viewport; stick sungguhan, lemparan, dan mode bantu dikunci; kamera berhenti di garis.
- **G-3 Banner "Rute selesai"** muncul saat hampir keluar (bukan sesudah berhenti); tanpa kunci teks baru.
- **G-4 Layar hasil** tampil sesudah sepeda keluar dan semua koran terbang mendarat (`HasilRute.siap_tampil`).
- **G-5** Skor, tenggat, misi, kondisi sepeda, progres, radar, dan save tidak berubah (dibekukan di garis seperti sebelumnya, dibuktikan lawan golden dari worktree `main`); tanpa segmen atau panjang rute baru.
- **G-6** Tidak ada angka ekonomi atau aturan permainan yang berubah; teks pemain hanya dari `translations/`.

| Ringkasan | Nilai |
|---|---|
| Tes sesudah Dev | 29088 lolos, 0 gagal, 0 peringatan (baseline 28489; +599: bagian A +29 (aset dan paket portal), B +211 (`tes_garis_finish`), C +359 (`tes_garis_finish_scene` 338 dan perubahan tes lama)); semua 17 `uji_*.py` exit 0 (`uji_aset_pasang_gelombang1` 565 ke 587, `uji_aset_pasang_5b` 595 ke 599); `--export-pack` exit 0 dan memuat portal; probe `probe_rute_jendela` dan `probe_hasil_jendela` 0 keadaan tidak sesuai di 1920x1080, 2340x1080, 2400x1080, 1600x720; kontras hasil di atas dunia portal terburuk 7,36:1 (teks 7,84:1), 0 di bawah 7:1; sha256 save asli tidak berubah |
| Mutan nyata Dev | B 55/55 tertangkap (dua setara dihapus dari kode), C 51/51 bermakna tertangkap (satu identik karena salah ketik skrip dicoret); A tidak ada (aset, dijaga uji set tepat) |
| Aset | 1 aset terpasang: `prop_portal_satpam.{png,json}` (80x92, dua frame, pijak (14, 60)); `--salin` kini memasang 15 sprite |
| Konstanta baru | 12 di `scripts/config.gd` (`RUTE_KELUAR_*` 6 dan `RUTE_PORTAL_*` 6; bukan enam), `HASIL_BERHENTI_TOLERANSI_UD` dihapus (BALANCING 6h) |
| Kunci teks baru | tidak ada |
| Butuh keputusan pemilik (NEEDS-MANUAL, 8.20) | lateral portal −2,0 ubin, jarak buka 6,0 dan ambang banner 6,0 ubin; sepeda lewat di bawah panel kondisi dan panel koin/skor sebelum hilang (0,3 sampai 0,5 detik; HUD tidak diubah); lonjakan laju dari 0 ke 3,0 bila sempat berhenti persis di garis; waktu garis akhir sampai hasil (sekitar 2,6 sampai 3,1 detik normal, terpanjang sekitar 6 detik); lisensi latar bengkel (UI-1) masih terbuka |

Pelajaran run ini: (1) ukuran aset yang tertulis di roadmap bukan desain: ukur bounding box piksel sebelum mengunci SPEC; sel 80x64 memotong dua bagian sprite dan baru ketahuan karena bagian A mengukur bbox kedua frame (G-1a); (2) membekukan kamera saja tidak cukup: tanah dan jendela daur diukur relatif sepeda, jadi kamera yang tertinggal 14 sampai 18 ubin menimbulkan lubang; jarak dunia harus ikut dibekukan, dan keberadaan lubang dibuktikan dengan oracle independen plus kontrol yang sengaja digeser; (3) bukti "tidak ada yang berubah" (G-5) harus berasal dari perilaku lama yang dijalankan nyata (golden dari worktree `main`, dua kali jalan identik byte demi byte), dan bot golden harus menonaktifkan proses frame nyata supaya deterministik; (4) tes lama yang memang menolak rujukan ke aset yang kini dipasang (`tes_ubin`, `tes_koran_sprite`, `uji_aset_pasang_*`) gagal lebih dulu sebelum diubah, itu bukti asersinya hidup, dan tiap perubahannya dicatat per baris di LOG; (5) error skrip di satu tes bisa meracuni tes sesudahnya (scene tak terbersihkan, kamera aktif tertinggal, `tes_tata_letak` 12 gagal): baca kegagalan pertama, bukan hitungan gagal; (6) mutan yang lolos bisa setara: buktikan, lalu hapus kode redundan (klausa hampir keluar, penjaga NaN) alih-alih menambah tes; (7) `Audio.perbarui_sepeda(jeda=true)` juga mematikan denting milestone, jadi bunyi sepeda sesudah hasil dibuat senyap lewat kecepatan 0; (8) hanya tangkapan terpilih di-commit (40 berkas, 4,3 MB; pelajaran QA-006 UI-2); (9) `git checkout` mutan hanya aman bila kode sudah di-commit.

## 7. Batasan yang perlu diketahui

- QA berbasis agent tidak menggantikan uji di HP nyata untuk rasa kontrol, performa, dan tampilan rasio layar. Fase gameplay selalu ditutup dengan uji manual (`DEV_PHASES.md`).
- Tanpa Godot terpasang, loop tidak bisa menghasilkan bukti tes. Jangan menjalankan loop sebelum prasyarat 0A terpenuhi.
- Keputusan terbuka (ROADMAP 5) adalah milik pemilik. Loop yang "menyelesaikan" Fase 0 dengan menebak nama package atau skala piksel menciptakan utang yang mahal (nama package tidak bisa diganti setelah upload pertama).
- Run penuh (Dev + QA × 2 iterasi) memakan token besar; mulai dari 0A, jangan menggabungkan 0A dengan run lain, dan jangan melanjutkan run berikutnya di sesi yang sama (Bagian 0c). **Pengecualian yang disetujui pemilik (2026-10-09): 0B dan 0C boleh digabung jadi satu run** (lihat Bagian 6). Menggabungkan selain itu tetap tidak dianjurkan.
