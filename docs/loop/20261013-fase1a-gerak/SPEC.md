# SPEC — 20261013-fase1a-gerak

Run 1A Fase 1 (`DEV_PHASES.md` Fase 1, `TECH_PLAN.md` Fase 1, `BALANCING.md` 2–3, GDD 5.2 dan 6): **logika gerak inti** sepeda di jalan uji. Kontrak bagi Dev **dan** QA. Prosedur penuh `docs/LOOP-DEV-QA.md` (maksimal 2 iterasi). `RUN_ID` di perintah tempel bertanggal 20261010; diganti ke tanggal mulai sesuai LOOP-DEV-QA 6b.

## Tujuan

Mengganti gerak placeholder run 0B (`BikeDrive`) dengan `BikeMotion` yang punya **rem tanpa tombol, meluncur, stamina, batas tepi jalan resmi, dan pause**, menampilkan stamina dan rem di HUD dan stick, memasang sprite `meluncur` dan `rem`, dan membuat laju kayuh mengikuti kecepatan. Semua logika murni dites headless dengan mutan nyata. Rasa kontrol dinilai di A54 sesudahnya (NEEDS-MANUAL).

## Keputusan dari pemilik (dengan tanggal)

- **2026-10-13, pindah sisi = analog bebas.** Posisi lateral tetap analog dari stick (komponen datar × 3,0 u/d), **tanpa kunci atau snap ke jalur**, ditambah batas tepi jalan resmi. Ini mengesampingkan butir SCOPE "kunci ke sisi seberang/dekat … ganti geser bebas (D-3)" dan sejalan dengan `ROUTE_DESIGN.md` 30 (posisi lateral bebas, tiga jalur bantu hanya untuk merancang) dan GDD 4.2 (posisi tengah menjangkau dua sisi).
- **2026-10-13, sprite stick bawah = ikuti fisika** (rincian di D-7).
- **2026-10-13, uji HP Fase 0 lolos** (PR #19): tidak ada angka dari uji A54 yang diminta berubah. Semua angka `BALANCING.md` 2–3 tetap usulan awal.
- Dari run sebelumnya, dikunci (jangan ditanyakan ulang): Godot 4.7.2, base 640×360 ×3, stretch `canvas_items` + integer + `expand`, `com.rmh.kring`, terjemahan CSV, export tanpa Gradle.
- Izin HP: orchestrator boleh memasang APK ke Samsung A54 (`RRCWA05E2NN`) setelah QA PASS; Dev dan QA tidak menyentuh HP. Tidak ada `pm clear`/uninstall.

Status **usulan** (jangan ditulis "dikunci"): semua angka gerak, rem, stamina, `pedal_rate`, warna dan bentuk penanda di HUD, aturan D-1 sampai D-9. Ambang rem tetap keputusan terbuka (ROADMAP 5, diputuskan lewat uji HP).

### Keputusan orchestrator (bisa ditolak di review PR)

- **D-1. `BikeMotion` menggantikan `BikeDrive`.** File baru `scripts/systems/bike_motion.gd` (`class_name BikeMotion extends RefCounted`, `static func`, tanpa node/`Time`/RNG). Keadaan sepeda dipegang satu objek data (mis. `BikeMotion.Keadaan`: kecepatan u/d, lateral ubin, stamina, lama tahan rem detik, rem aktif, lelah) dan satu langkah `langkah(keadaan, stick, dt) -> keadaan baru/hasil` yang tidak mengubah masukannya. `bike_drive.gd` dihapus; tes `BikeDrive` yang masih relevan dipindah ke `BikeMotion` (catat di LOG mana yang dipindah, diubah, atau dibuang beserta alasannya). Pemanggil (`SepedaUji`) hanya menyimpan keadaan dan menampilkan.
- **D-2. Rem tanpa tombol (BALANCING 2, GDD 5.2).** Syarat rem = **komponen bawah** stick sesudah zona mati (`-stick.y`, keluaran `StickMap`) **≥ `REM_AMBANG_STICK` (0,90), inklusif**. Karena yang diukur komponen bawah, diagonal penuh 45° (0,707) tidak pernah memenuhi; tidak ada konstanta sudut tambahan. Lama tahan bertambah `dt` selama syarat terpenuhi dan **kembali 0** begitu syarat tidak terpenuhi (stick naik, ke samping, atau dilepas). Rem **aktif** saat lama tahan ≥ `REM_TAHAN_DETIK` (0,25). Selama aktif kecepatan turun 5,0 u/d² sampai **0** (berhenti) dan tetap 0 selama ditahan. Sebelum aktif, stick bawah berperilaku meluncur biasa (D-3). Begitu rem lepas, kecepatan naik dengan akselerasi 3,0 u/d² menuju target stick. Jangkauan kecepatan menjadi 0 sampai 6,0 u/d (hanya rem yang bisa membawa di bawah 1,5). Hasil tidak boleh bergantung pada pembagian `dt` lebih dari toleransi kecil (langkah yang melewati batas 0,25 detik membagi sisa waktunya dengan benar, atau dibuktikan galatnya kecil dengan tes `dt` 1/30 lawan 1/240).
- **D-3. Meluncur dan melambat.** Stick ke bawah (komponen maju < 0 sesudah zona mati) dan rem belum aktif: kecepatan tujuan linear santai → melambat (`lerp(3,0, 1,5, bawah)`, rumus run 0B), turun 2,0 u/d². Stamina pulih +15/d selama stick ke bawah atau rem aktif (BALANCING 3 "meluncur atau melambat").
- **D-4. Lateral analog bebas dengan batas resmi (keputusan pemilik).** Lateral = komponen datar stick × `KECEPATAN_LATERAL_UD`, posisi dijepit ke ±`JALAN_LEBAR_UBIN`/2 (tepi aspal, ±1,0 ubin) sebagai **batas tepi jalan resmi**; kecepatan lateral efektif 0 bila terhalang tepi. Tanda: positif = `dekat`, negatif = `seberang`. Opsi kidal tidak mengubah arti sumbu (kidal hanya menukar zona). Konstanta jalan uji yang menjadi batas resmi dipindah ke bagian "Kecepatan dan kontrol" di `Config` bila perlu, nama tetap satu baris. Tidak ada `kiri`/`kanan` untuk sisi jalan.
- **D-5. Stamina (BALANCING 3).** Maksimum 100, mulai 100, dijepit 0..100. Laju per detik:
  - stick ke bawah atau rem aktif: **+15**;
  - selain itu dari **kecepatan sebenarnya**, linear per potong: ≤ 3,0 u/d → **+2**; 4,5 → **−4**; ≥ 6,0 → **−12** (di antara titik itu interpolasi linear, supaya tidak ada lompatan di ambang tingkat dan percepatan dari santai ke ngebut ikut menguras bertahap).
  - **Habis:** saat stamina mencapai 0, status `lelah` menyala; selama lelah kecepatan tujuan dijepit ke `KECEPATAN_CEPAT_UD` (4,5) dan, bila sedang di atasnya, turun dengan perlambatan 2,0 u/d². `lelah` padam saat stamina **≥ 30** (`STAMINA_PULIH_AMBANG`). Pada kecepatan 4,5 lajunya −4, jadi stamina tetap 0 sampai pemain melonggarkan stick: ini disengaja (ngebut punya harga, prinsip 1).
  - Medan (+10 turunan) di luar scope; jangan menambah konstanta yang belum dipakai.
- **D-6. Pause = simulasi berhenti.** `NOTIFICATION_APPLICATION_PAUSED` / `NOTIFICATION_APPLICATION_FOCUS_OUT`: simulasi `JalanUji` berhenti (kecepatan, jarak, stamina, lama tahan rem, dorongan kamera tidak berubah walau `_process` dipanggil atau waktu berjalan), stick dan swipe dilepas (`batal_semua`, sudah ada), lempar ditutup (sudah ada), lama tahan rem kembali 0. `NOTIFICATION_APPLICATION_RESUMED` / `FOCUS_IN`: simulasi lanjut otomatis dan **langkah pertama sesudahnya memakai dt 0** (tidak ada lompatan, juga tidak dari `LANGKAH_WAKTU_MAKS_DETIK`). Tombol jeda dan layar jeda ada di Run 1B; run ini tidak menambah UI jeda. Status jeda dihitung lewat fungsi yang bisa dites (bukan hanya `set_process`).
- **D-7. Sprite stick bawah, rem, dan lelah (keputusan pemilik: ikuti fisika).** Prioritas:
  1. rem aktif → `rem_<arah>` (termasuk saat sudah berhenti di kecepatan 0);
  2. stick ke bawah dan kecepatan sebenarnya **masih di atas** kecepatan tujuan (lebih dari toleransi kecil di `Config`) → `meluncur_<arah>` (kaki diam: sedang turun tanpa mengayuh);
  3. stick ke bawah dan kecepatan sudah sampai tujuan → `melambat_<arah>` (kayuh 4 fps menahan kecepatan rendah);
  4. selain itu kayuh `<tingkat>_<arah>` dengan tingkat dari stick (D-4 run 0B), **dijepit ke cepat selama lelah**.
  Arah tetap dari gerak sebenarnya (`LoperAnim.arah_dari_gerak`); di kecepatan 0 tanpa lateral arahnya normal. Lempar dari meluncur atau rem memakai `santai` (seperti melambat, D-3 run sprite). Pemilihan pose ada di `LoperAnim` (murni), bukan di node.
- **D-8. Laju kayuh mengikuti kecepatan.** Untuk animasi kayuh dan melambat: `pedal_rate = kecepatan sebenarnya / kecepatan nominal tingkat itu` (santai 3,0, cepat 4,5, ngebut 6,0, melambat 1,5), dijepit ke `[0, PEDAL_RATE_MAKS]` (usulan 1,5, `Config`). Meluncur dan rem tidak dikayuh: `pedal_rate` = 1 (animasinya napas/getar, fps dari `.tres`). Lempar tidak dipengaruhi (waktunya dari `LemparWaktu`). Fungsi murni di `LoperAnim` atau `BikeMotion`.
- **D-9. SpriteFrames 48 animasi.** `tools/loper_art/bangun_frames.py` ditambah dua sumber `rem_meluncur/loper_agen_meluncur.json` dan `rem_meluncur/loper_agen_rem.json` (urutan setelah lempar). Hasil: 15 kayuh + 5 melambat + 18 lempar + 5 meluncur + 5 rem = **48 animasi**; meluncur 4 fps loop, rem 8 fps loop (dari JSON). PNG/JSON disalin ke `assets/sprites/loper/` byte-identik dengan setelan impor sama (Lossless, Nearest, tanpa mipmap, tanpa VRAM). Jangan menggambar atau mengedit PNG; jangan mengubah `tools/loper_art/rem_meluncur.py`.

## Di luar scope

- Debu roda, garis kecepatan, getar kamera, audio, partikel, cek light 2D/glow/shader (Run 1B).
- Tombol/ikon jeda dan layar jeda, penyetelan posisi sepeda di bingkai, ukuran stick/tombol kidal/teks HUD, angka dorongan (Run 1B).
- Kunci atau snap jalur (ditolak pemilik), medan/turunan, tabrakan, mode bantu, proyektil koran (Fase 2), pose "berhenti" (Fase 4).
- Mengubah skala ×3, angka di BALANCING 2–3 (selain menambah yang baru dan mencatat rumus), `ROADMAP.md`, `DEV_PHASES.md`.

## Kriteria penerimaan (bisa diuji)

Perintah dari root repo, `godot` = 4.7.2. Semua tes lama tetap hijau kecuali yang memang harus berubah (daftar + alasan di LOG, mis. "SpriteFrames 38 animasi", "kecepatan tidak pernah di bawah 1,5").

- **AC-1 (gerbang):** `godot --headless --import` bersih (0 `ERROR`/`SCRIPT ERROR`/`WARNING`) dan di klon bersih `git status --porcelain` kosong sesudahnya (`.import`/`.uid` ter-commit). `run_tests.gd` → `tools/cek_keluaran_tes.py --ketat` exit 0; `tools/tests_cek/uji_pemeriksa.py` dan `uji_bangun_frames.py` lolos; `godot --headless --path . --quit-after 2` tanpa `ERROR`/`WARNING`; tidak ada keystore/APK/`.godot/`/`build/`/`builds/` di diff.
- **AC-2 (`BikeMotion`, kecepatan):** netral → 3,0; atas 0,5 → 4,5; atas penuh → 6,0; bawah penuh → 1,5 (sebelum rem); naik 3,0 u/d², turun 2,0 u/d², tidak melampaui tujuan untuk `dt` besar, `dt` 0/negatif/NaN/inf = tidak berubah; masukan stick NaN/di luar ±1 aman; fungsi murni (masukan tidak berubah, hasil sama untuk masukan sama).
- **AC-3 (rem, D-2):** tes untuk: komponen bawah 0,899 tidak pernah rem, 0,90 rem sesudah 0,25 detik (tepi inklusif); 0,249 detik tahan belum rem, 0,25 rem; turun 5,0 u/d² sampai 0 dan tetap 0 selama ditahan; stick dilepas (vektor nol) di tengah tahan → lama tahan 0 dan tidak rem; dilepas saat rem aktif → rem padam, kecepatan naik 3,0 u/d² ke santai; naik sesaat di atas ambang lalu kembali → hitungan mulai dari 0; diagonal (bawah 0,85 + samping 0,5, dan 45° penuh) tidak rem; stick bawah penuh dengan geser datar kecil (bawah ≥ 0,90) tetap rem; independen pembagian `dt` (1/30 vs 1/240 dalam toleransi tertulis).
- **AC-4 (stamina, D-5):** laju di titik 3,0/4,5/6,0 dan interpolasi di antaranya; +15 saat stick bawah dan saat rem; dijepit 0..100; dari penuh, ngebut terus (mulai santai) habis dalam 8,0–9,5 detik dan cepat terus dalam 24–27 detik; dari 0 meluncur penuh dalam ≤ 7 detik; lelah menyala tepat di 0, menjepit tujuan ke 4,5 (turun dari 6,0 dengan 2,0 u/d²), padam tepat di ≥ 30 dan bukan sebelumnya; sprite dijepit ke cepat selama lelah. Tes invarian prinsip 1: ngebut terus tidak bisa dipertahankan (stamina habis), santai tidak menguras.
- **AC-5 (lateral, D-4):** lateral = datar × 3,0 u/d; dijepit ±1,0; `lateral_ud` 0 saat terhalang dan bertanda benar saat bebas; diagonal maju+lateral dalam satu langkah; kidal tidak mengubah tanda (tes scene); penjaga lama "tidak ada `kiri`/`kanan` untuk sisi" tetap lolos.
- **AC-6 (pose dan laju kayuh, D-7, D-8):** tabel kasus di `LoperAnim` (murni): rem aktif (kecepatan > 0 dan = 0), meluncur (stick bawah, kecepatan di atas tujuan), melambat (sudah di tujuan, termasuk batas toleransi), kayuh tiga tingkat, lelah menjepit ngebut → cepat, arah dari gerak di tiap pose; semua nama hasil ada di `SpriteFrames`. `pedal_rate` di titik nominal = 1, di setengah = 0,5, di kecepatan 0 = 0, dijepit di `PEDAL_RATE_MAKS`, meluncur/rem = 1. Lempar dari meluncur/rem memakai santai.
- **AC-7 (aset, D-9):** `loper_agen_frames.tres` tepat 48 animasi, nama/urutan/frame/region sesuai JSON, fps dan loop benar; `uji_bangun_frames.py` diperbarui (deterministik, byte sama jika dijalankan dua kali, sumber rusak ditolak); salinan di `assets/` byte-identik dengan sumber.
- **AC-8 (pause, D-6):** tes scene: sesudah notifikasi PAUSED dan FOCUS_OUT, memanggil `_process`/`perbarui` dengan `dt` besar tidak mengubah kecepatan, jarak, stamina, lama tahan rem, atau geseran dorongan; stick dilepas dan lempar ditutup; sesudah RESUMED/FOCUS_IN langkah pertama ber-`dt` 0 dan langkah berikutnya normal. Pause di tengah tahan rem → setelah lanjut, rem tidak langsung aktif.
- **AC-9 (HUD dan stick):** panel bawah HUD (DESIGN_SPEC 3.5) memuat bar stamina kedua di bawah bar kecepatan: label `tr("HUD_STAMINA")`, isi `ACCENT`, `FAIL` di bawah 30 (konstanta `Config`), dan saat lelah ada penanda **bukan warna** (bentuk, ikon, atau teks lewat kunci terjemahan). Bar kecepatan kini menerima 0 u/d. Cincin stick: saat rem aktif **busur bawah** cincin digambar `WARN` (DESIGN_SPEC 3.7), hilang saat rem padam. Warna hanya dari `Palette`, anchor + Container, kunci terjemahan baru di `translations/ui.csv` (+ hasil impor). Panel tetap ikut pindah sisi saat kidal.
- **AC-10 (kabel scene):** tes terpadu lewat `Input.parse_input_event` pada viewport 780×360 (pola tes run 0B): stick bawah penuh ditahan > 0,25 detik → sepeda berhenti, animasi `rem_*`, cincin rem menyala; dilepas → jalan lagi; stick bawah sebentar → `meluncur_*` lalu `melambat_*`; ngebut terus → bar stamina turun dan lelah menyala; dua jari (stick + swipe) tetap bekerja selama rem dan meluncur; kidal.
- **AC-11 (mutan nyata):** Dev menjalankan mutan nyata pada `BikeMotion`, pemilih pose, `pedal_rate`, dan jeda (minimal: ambang rem `>=`→`>`, lama tahan tidak di-reset, rem berhenti di 1,5 bukan 0, stamina tanpa jepit, lelah padam di > 0, interpolasi stamina diganti tangga, pose meluncur/melambat tertukar, pause tidak menolkan dt pertama). Tiap mutan, tes yang menangkapnya, dan mutan yang hidup beserta alasannya dicatat di LOG. Kode dikembalikan sesudahnya.
- **AC-12 (aturan kode):** tab, static typing, `##` bahasa Indonesia, tidak ada angka tuning di luar `Config` (satu baris, literal), tidak ada hex di luar `palette.gd`, logika di `scripts/systems/`, node tipis; `ConfigParser` menerima semua konstanta baru.
- **AC-13 (bukti visual):** lewat pola `tests/probe_*_jendela.gd` di jendela asli 2340×1080, simpan ke `docs/loop/20261013-fase1a-gerak/shots/`: meluncur, melambat, rem (bergerak dan berhenti) dengan cincin rem `WARN`, bar stamina penuh/rendah (< 30)/lelah. `tools/cek_blok_piksel.py 3` lolos di luar teks HUD. Sprite meluncur/rem tidak melompat posisi saat berganti dari dan ke kayuh (ukur alas sprite).
- **AC-14 (dokumen, commit yang sama dengan perubahannya):** `BALANCING.md` 2 (rumus `BikeMotion` menggantikan paragraf "Rumus gerak di run 0B", rem, pose, `pedal_rate`, konstanta baru), 3 (rumus stamina, lelah), 10 (catatan perubahan 2026-10-13); `ART_DIRECTION.md` 3.4 (meluncur dan rem dipasang, usulan); `docs/design/character/loper_agen/rem_meluncur/README.md` dan `docs/design/character/README.md` (status dipakai); `tools/loper_art/README.md` (48 animasi); `AGENTS.md`, `.cursor/rules/00-project-core.mdc` (bila menyebut 38 animasi atau `bike_drive`), `docs/README.md`; `docs/SETUP_ANDROID.md` bagian 8 ditambah subbagian uji Run 1A (dari NEEDS-MANUAL). `DEV_PHASES.md` dan `ROADMAP.md` **tidak** diedit Dev.
- **AC-15 (git):** commit kecil `<tipe>: <ringkasan>` bahasa Indonesia di `feat/fase1a-gerak`, tidak ada commit di `main`, **tidak ada push**.

## Perubahan file/struktur yang diharapkan

```
scripts/systems/bike_motion.gd (baru), scripts/systems/bike_drive.gd (dihapus), scripts/systems/loper_anim.gd (pose, pedal_rate)
scripts/entities/sepeda_uji.gd, jalan_uji.gd (jeda), loper_sprite.gd (pose meluncur/rem bila perlu)
scripts/ui/hud_dev.gd (+ bar stamina), kontrol_touch.gd (busur rem), bar_kecepatan.gd (dipakai ulang atau digeneralisasi)
scripts/config.gd (+ stamina, PEDAL_RATE_MAKS, toleransi pose, ambang warna stamina)
assets/sprites/loper/loper_agen_{meluncur,rem}.{png,json}(+.import), loper_agen_frames.tres (48)
tools/loper_art/bangun_frames.py, tools/tests_cek/uji_bangun_frames.py
translations/ui.csv (+ HUD_STAMINA dan penanda lelah) + hasil impor
tests/ (tes BikeMotion, pose, pause, scene; probe jendela untuk AC-13)
docs: lihat AC-14
```

## Tes yang harus ada

Lihat AC-2 sampai AC-11. Ringkasnya: ambang rem (tepi 0,899/0,90), lama tahan (0,249/0,25), lepas di tengah, naik sesaat, diagonal, rem sampai 0, lepas rem, independen `dt`; stamina laju, jepit, habis, pulih, lelah dan ambang 30, durasi ngebut/cepat/meluncur; lateral dan batas; pose dan `pedal_rate`; jeda (PAUSED, FOCUS_OUT, RESUMED, FOCUS_IN, dt pertama 0, jeda di tengah tahan rem); dua jari; kidal; SpriteFrames 48. Mutan nyata (AC-11).

## Butuh uji perangkat nyata (NEEDS-MANUAL)

Orchestrator memasang APK ke A54 setelah QA PASS (bila HP tersambung). Pemilik menilai:
- Ambang rem: tarik stick penuh ke bawah dan tahan, apakah 0,25 detik dan 90% terasa pas; apakah sepeda pernah berhenti tak sengaja saat belok atau meluncur.
- Rem sampai berhenti lalu lepas: jalan lagi terasa wajar; sprite rem (getar 1 px) terbaca di ×3.
- Meluncur → melambat: kaki diam saat turun, lalu kayuh 4 fps; apakah pergantiannya terbaca atau mengganggu.
- Stamina: ngebut habis sekitar 8 detik, lelah menjepit ke cepat; bar stamina dan penanda lelah terbaca; pulih ke 30 lewat meluncur sekitar 2 detik.
- Laju kayuh mengikuti kecepatan saat mempercepat dari berhenti.
- Lateral analog sampai tepi aspal: batas terasa wajar; geser saat berhenti terlihat aneh atau tidak.
- Kembali dari background (home, notifikasi): tidak ada lompatan posisi, stamina, atau rem yang tersisa.

## Dokumen yang ikut diperbarui

Dev: AC-14. Orchestrator sesudah PR: `DEV_PHASES.md` Fase 1 (centang hanya yang terbukti, bukan yang NEEDS-MANUAL), `ROADMAP.md` bila ada keputusan baru.
