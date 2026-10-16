# SPEC — 20261018-fase3c-hud-hasil

Run 3C Fase 3 (M2, prototype 3): radar, HUD rute final, tenggat, layar hasil, rumah bukan pelanggan abu-abu di mode bantu, spike rumah sisi dekat, checklist uji HP penutup Fase 3. Branch `feat/fase3c-hud-hasil`, dari `main` `82dbb9e` (sudah memuat PR #32 run 3B).

## Tujuan

Rute perumahan menjadi **satu rute lengkap dari awal sampai layar hasil** (DEV_PHASES Fase 3 "Selesai kalau"): radar di tepi kiri (seberang) dan kanan (dekat) memberi ancang-ancang, HUD rute final menggantikan HUD dev 3B (progres pelanggan, koin, skor/combo, sisa koran, kecepatan, stamina, tenggat) dan menghormati zona aman, tenggat memberi harga pada santai tanpa menghukum berlapis, dan layar hasil sederhana membuka dengan yang berhasil. Spike rumah sisi dekat menyiapkan keputusan pemilik dengan tangkapan layar tiga pendekatan.

## Keputusan dari pemilik (2026-10-17, jawaban atas pertanyaan orchestrator)

- **K-1 Tenggat = waktu tempuh rute pada santai × 1,15, tip hilang sesudah tenggat lewat.** Tenggat rute (detik) = `ceil(panjang_rute_ubin / KECEPATAN_SANTAI_UD × TENGGAT_PENGALI)` dengan `TENGGAT_PENGALI` 1,15 (BALANCING 6), jadi sekitar 90–92 detik untuk rute 232–240 ubin. Dihitung dari rute (murni, satu tempat), bukan angka tetap. Jam berjalan sejak rute dimulai, **membeku saat jeda/background** (rule gdscript), berhenti di garis akhir. Sesudah tenggat lewat: rute dan antaran tetap berjalan, antaran sah tetap memberi ongkos 15 koin, skor, dan combo seperti biasa, **tetapi tip tidak diberikan lagi** (satu konsekuensi ringan, tanpa potong koin, tanpa game over; prinsip 1 dan 2). Tenggat lewat ditandai jelas di HUD (teks + warna, bukan warna saja) dan dicatat netral di layar hasil. Game over / batas tabrakan / struktur sesi tetap terbuka (ROADMAP 5), tidak dikunci run ini.
- **K-2 Jangkauan radar bawaan 30 ubin ke depan** (`RADAR_JANGKAUAN_UBIN` 30, sama dengan jendela daur rumah; sekitar 5 detik ngebut, 10 detik santai). Angka awal di `Config`; kelak bisa jadi upgrade (GDD 4.3).
- **K-3 D-5 run 3B dipertahankan:** jangkauan bel dari 1,0 ubin di belakang sampai 4,0 ubin di depan sepeda. QA-008 run 3B selesai sebagai keputusan pemilik; GDD 5.4 dan BALANCING 6d diperbarui (hapus "perlu ditinjau pemilik", tetap usulan sampai uji HP).
- **K-4 Run 3C mulai tanpa hasil uji HP** Fase 2 (8.5), 3A (8.6), 3B (8.7); semuanya belum diisi. `DEV_PHASES` Fase 2, M1, dan butir yang bergantung uji HP tidak dicentang.
- **Berlaku dari run sebelumnya (jangan ditanyakan ulang):** run 3B K-1 sampai K-4 dan usulan O-1 sampai O-5 (tidak ditolak di review PR #32); jendela tetap sakelar `Config.JENDELA_KENA_BONUS` bawaan penalti; id rumah `<id_segmen>@<pos>`, tanpa save; sisi dekat hanya placeholder `bukan`. Sudah dikunci (ROADMAP 4b): Godot 4.7.2, skala ×3, 640×360 `canvas_items` + integer + expand, ubin 64×32, arah lempar bebas, package `com.rmh.kring`, CSV terjemahan.

## Keputusan orchestrator (usulan, bisa ditolak di review PR)

- **O-6 Sakelar dev Kidal dan Bantu pindah ke layar jeda** (layar pengaturan belum ada, DESIGN_SPEC 4). Strip atas HUD jadi bebas untuk panel progres; menyelesaikan QA-007 run 3B (tombol dev menutupi mobil seberang). Status tetap terbaca dari teks (`HUD_BANTU_MATI/NYALA`, kidal mati/nyala), target sentuh ≥ 42 px game.
- **O-7 Skor dan combo di kanan atas**, panel kedua di baris koin (slot "reputasi" DESIGN_SPEC 3.3 yang baru terisi di Fase 6). Panel kondisi sepeda (ban/rem/rantai) dan reputasi **tidak** dibuat (Fase 6). Label PUTUS 3B tetap ada di panel combo.
- **O-8 Tenggat di baris atas panel progres** (DESIGN_SPEC 3.2): kiri "WAKTU 1:32" (sisa), kanan "3/25 TERKIRIM" (`ACCENT`). Sesudah tenggat lewat: kiri "LEWAT +0:12" dengan warna `WARN` (teks berubah, bukan hanya warna). Label "HARI · distrik" belum dipakai (sistem hari belum ada, Fase 4/6).
- **O-9 Radar menandai pemberi tip** dengan penanda tip (GDD 4.3, DESIGN_SPEC 3.4); ini membatalkan bagian "pemberi tip tidak ditandai visual" dari O-3 run 3B. Rumah yang sudah terantar keluar dari radar. Sesudah tenggat lewat, pemberi tip tampil sebagai pelanggan biasa (tip sudah tidak ada, K-1). Penanda misi tidak dipakai (misi Fase 4).
- **O-10 "Masuk jangkauan lempar" di radar** = rumah pelanggan dengan jarak maju dari sepeda ke kotak suratnya ≤ `LEMPAR_JARAK_MAKS_UBIN` (5,0) dan belum di belakang sepeda. Penanda memakai aset `_jangkau` (garis luar `TEXT`, +2 px), warna jenis tetap.
- **O-11 Layar hasil** muncul sesudah garis akhir, saat sepeda berhenti **dan** tidak ada koran yang masih terbang. Banner "Rute selesai" 3A boleh tetap tampil sesaat sebelumnya. Tombol "Main lagi" (seed + 1) pindah dari tombol dev pojok ke layar hasil. Urutan isi dari yang berhasil (rule ui-scenes): terkirim (n/25), tip, koin, skor, lalu meleset dan status tenggat dengan nada netral (tanpa merah besar, tanpa kata "gagal"). Back Android di layar hasil tidak memulai ulang diam-diam (abaikan atau perilaku wajar yang dicatat), karena menu belum ada.
- **O-12 Definisi angka hasil, satu sumber di `scripts/systems/`:** terkirim = jumlah pelanggan terantar (`SkorRute`); meleset = pelanggan rute yang tidak terantar saat rute selesai (25 − terkirim); koin, tip, skor dari `SkorRute`; tenggat lewat (detik) dari sistem tenggat. UI hanya menampilkan (catatan 3B: jangan menghitung ulang di UI). Kotak progres per pelanggan (DESIGN_SPEC 3.2): **terkirim** (✓ `OK`), **terlewat** (× `FAIL`; pelanggan yang kotak suratnya sudah lebih dari `HUD_PROGRES_TERLEWAT_UBIN` di belakang sepeda tanpa terantar, usulan 3,0 ubin), **berikutnya** (▶ `ACCENT`; pelanggan belum terantar terdekat di depan), **belum** (kosong). Status dari logika murni, bukan dari node.

## Di luar scope

- Panel reputasi dan kondisi sepeda, kartu misi, penanda misi di radar, layar pengaturan, layar koran, bengkel, save, hari (Fase 4–6).
- Memutuskan pendekatan rumah sisi dekat (pemilik memutuskan sesudah spike), game over, batas tabrakan, struktur sesi, jendela bonus/penalti, target harian.
- Mengubah aturan gerak, lemparan, skor, rintangan, tabrakan, atau bel 3B, kecuali tip-sesudah-tenggat (K-1).
- Menggambar atau mengedit PNG dengan tangan (`art-assets.mdc`). Aset radar dan ikon HUD dari `tools/ui_art/hud_ikon.py` (sudah di `assets/sprites/ui/`) dipakai apa adanya; bila perlu aset baru, lewat renderer yang ada dan di-commit bersama skripnya. Graybox spike lewat `tools/env_art/` (skrip) atau digambar kode di scene dev, bukan PNG buatan tangan. Kembalikan berkas yang drift piksel tanpa sengaja (catatan 3A).
- Mengunduh aset apa pun.

## Kriteria penerimaan (bisa diuji)

### A. Tenggat (K-1)

- **AC-1 Tenggat murni** (`scripts/systems/`, satu sumber): `detik_tenggat(panjang_ubin)` = `ceil(panjang / KECEPATAN_SANTAI_UD × TENGGAT_PENGALI)`; keadaan tenggat maju dengan `dt` efektif (0 saat jeda), berhenti di garis akhir, memberi sisa detik, `lewat` (bool), dan detik lewat. Oracle literal: paling sedikit tiga panjang (mis. 232 → 89, 236 → 91, 240 → 92; 240 / 3,0 × 1,15 = 92,0 tepat, jadi galat float tidak boleh membuatnya 93 — Dev memverifikasi pembulatan dan menulis angka literal) dan tepi tepat di tenggat (sisa 0 = belum lewat atau lewat: ditulis eksplisit dan dites).
- **AC-2 Tip hilang sesudah tenggat (K-1):** teras ke pemberi tip sesudah tenggat lewat memberi ongkos 15 + skor + combo naik, tip 0, `jumlah_tip` tidak naik, tidak ada bunyi tip dan umpan "tip +5". Sebelum tenggat tetap +5. Dites murni (oracle literal) dan di scene (bunyi/umpan tip tidak muncul). Koin tidak pernah berkurang.
- **AC-3 Tenggat tidak menghentikan rute:** simulasi headless pemain yang berhenti lama (rem) sampai tenggat lewat tetap bisa menyelesaikan rute; `rute_selesai` tepat sekali; layar hasil terbuka. Mode bantu (santai otomatis) menyelesaikan rute sebelum tenggat tanpa tabrakan (dites dengan bot santai yang tidak berhenti, 20 seed).

### B. Radar (K-2, O-9, O-10, GDD 4.3, DESIGN_SPEC 3.4)

- **AC-4 Radar murni** (`scripts/systems/`): dari rute, posisi maju sepeda, status terantar, mode bantu, dan tenggat lewat → daftar penanda per strip (`seberang` = strip kiri, `dekat` = strip kanan) dengan jenis (`pelanggan`, `tip`, `bukan`), posisi vertikal 0..1 (atas = jauh 30 ubin di depan, bawah = dekat sepeda), dan bendera `jangkau` (O-10). Rumah di luar [0; `RADAR_JANGKAUAN_UBIN`] di depan tidak tampil; terantar tidak tampil; `bukan` hanya tampil di mode bantu; tip menjadi pelanggan biasa sesudah tenggat lewat. Kidal **tidak** menukar strip (strip mengikuti sisi dunia). Oracle literal: posisi vertikal untuk paling sedikit 3 jarak, tepi jangkauan (0 dan 30 inklusif/eksklusif ditulis eksplisit), batas `jangkau` 5,0.
- **AC-5 Radar di layar:** strip lebar 12 dari y 10 sampai y 182, kiri di x 4, kanan 4 px dari tepi kanan (menghormati inset zona aman, AC-9), bingkai `ui_radar_strip_9slice.png`, penanda dari `ui_radar_<jenis>[_jangkau].png`, penanda bergerak turun saat rumah mendekat; tidak menerima sentuhan; tidak bertumpuk dengan tombol jeda, panel progres, panel koin/skor, atau tombol bel di 640, 780, dan 800 (`tes_tata_letak.gd`). Jenis dibedakan bentuk juga (bukan pelanggan berlubang, tip bertitik), bukan hanya warna.
- **AC-6 Mode bantu: rumah bukan pelanggan abu-abu (GDD 5.3, D-8 run 2B):** saat mode bantu nyala, rumah bukan pelanggan di jangkauan tampil sebagai penanda `RADAR_BUKAN` berlubang; saat mati tidak tampil. Mengubah sakelar di tengah rute langsung berlaku. Pemilihan sasaran bantu tetap dari data rute (sudah sejak 3A; tes tetap hijau).

### C. HUD rute final (DESIGN_SPEC 3, O-6, O-7, O-8, O-12)

- **AC-7 Panel progres (tengah atas, lebar 260, y 8):** baris atas tenggat (O-8) dan "n/25 TERKIRIM"; baris bawah 25 kotak 8×8 jarak 2, status dari logika murni (O-12) dengan simbol (✓, ×, ▶, kosong garis putus-putus) — bukan warna saja. Oracle literal status kotak untuk urutan kejadian contoh (terantar, terlewat, berikutnya pindah).
- **AC-8 Panel kanan atas:** koin (ikon `ui_icon_koin` 14 + angka dengan pemisah ribuan titik, "1.250") dan skor/combo (O-7, label PUTUS 3B tetap); panel 9-slice `ui_panel_hud_9slice.png` (DESIGN_SPEC 1.3). Panel bawah kecepatan/stamina dan koran tetap (sudah sesuai 3.5) dan tetap dicerminkan saat kidal; bel tetap. HUD dev skor 3B dan tombol dev strip atas (Kidal, Bantu, Main lagi) dihapus dari scene rute; Kidal dan Bantu ada di layar jeda (O-6). Jalan uji (scene dev) boleh tetap memakai HUD dev bila perlu; tes lamanya hijau atau diubah dengan alasan tertulis.
- **AC-9 Zona aman dan rasio:** semua elemen HUD tepi memakai anchor + Container dan margin = max(margin DESIGN_SPEC, inset aman dari `DisplayServer.get_display_safe_area()` dikonversi ke piksel game), lewat satu fungsi murni yang dites dengan inset tiruan (kiri, kanan, atas; mis. cutout 30 px layar). `tes_tata_letak.gd` membuktikan di 640×360, 780×360, 800×360 (tangan kanan dan kidal): tidak ada tumpang tindih antar panel, radar, tombol jeda, tombol bel; HUD tidak masuk zona stick; panel atas tidak menutupi sepeda; elemen penting di 640×360 tengah. Tanpa hex di scene/skrip selain `palette.gd`; semua teks lewat `translations/ui.csv` (kunci baru `HUD_`, `HASIL_`).
- **AC-10 Tutup QA-012 dan QA-013 run 3B** (Minor celah tes, berkas yang disentuh run ini): tes yang membunuh mutan R07 (arah naik umpan melayang) dan R13 (label PUTUS saat antaran tidak sah).

### D. Layar hasil (O-11, O-12, rule ui-scenes)

- **AC-11 Angka hasil murni:** satu fungsi/kelas di `scripts/systems/` mengembalikan terkirim, meleset, koin, tip, skor, jumlah tepat (opsional), tenggat lewat (bool + detik) dari `SkorRute` + rute + tenggat. Oracle literal untuk paling sedikit dua skenario (semua terantar sebelum tenggat; sebagian meleset dan tenggat lewat).
- **AC-12 Scene `scenes/ui/layar_hasil.tscn`:** layar penuh `UI_BG`, panel `UI_PANEL`, judul Lilita One (`HASIL_JUDUL`), urutan dari yang berhasil (O-11), meleset dan tenggat netral (tanpa layar kalah, prinsip 2), tombol "Main lagi" ≥ 42 px game; autowrap/container melar; terbaca di 640, 780, 800. Muncul hanya sesudah sepeda berhenti dan tidak ada koran terbang; HUD rute dan kontrol tidak menerima sentuhan di bawahnya; jeda/back tidak merusak alur.
- **AC-13 Smoke test layar hasil (rule testing):** instansiasi scene, isi angka, cek teks tampil (lewat kunci, bukan kalimat tertanam), `pressed.emit()` tombol "Main lagi" → rute baru seed + 1, skor/koin/tenggat/radar/progres/rintangan/bel/oleng ter-reset (perluasan AC-22 run 3B). Juga tes scene: rute selesai → layar hasil muncul tepat sekali, angka sama dengan `SkorRute`.

### E. Spike rumah sisi dekat (TECH_PLAN Fase 3)

- **AC-14 Tiga pendekatan di graybox:** (1) punggung rumah apa adanya, rendah dan kontras rendah; (2) tembok atau pagar belakang rendah dengan rumah di belakangnya; (3) punggung rumah semi-transparan di dekat pemain (lewat `PenerapPenutup`/aturan penutup yang ada, bukan kode per objek). Di scene dev terpisah (mis. `scenes/dev/spike_sisi_dekat.tscn`) dengan sakelar pendekatan, dikecualikan dari paket ekspor; aset graybox lewat skrip `tools/env_art/` atau digambar kode. Tidak mengubah rute perumahan.
- **AC-15 Bukti:** tangkapan layar jendela asli 2340×1080 per pendekatan (sepeda di jalur dekat, di trotoar dekat, dan melempar ke sisi dekat; pelanggan dekat placeholder di spike saja) di `docs/loop/20261018-fase3c-hud-hasil/shots/spike_sisi_dekat/`, plus catatan perbandingan singkat (keterbacaan sasaran, menutupi sepeda, beban aset Fase 5/8) di LOG. **Dev dan QA tidak memilih**; orchestrator menanyakan pemilik.

### F. Umum

- **AC-16 Angka baru** di `scripts/config.gd` satu baris literal (`TENGGAT_PENGALI`, `RADAR_*`, `HUD_PROGRES_*`, `HASIL_*` dst.), tanpa angka ajaib di kode; `BALANCING.md` 6 (tenggat, tip sesudah tenggat) dan 10 (catatan perubahan) diperbarui; `DESIGN_SPEC.md` 3 (diterapkan, O-6..O-8), 3.4, 4 (Hasil 🟡 sketsa), `GDD.md` 4.3, 5.3, 5.4 (K-3), `TECH_PLAN.md` Fase 3 (status spike), `ROUTE_DESIGN`/`ROADMAP` bila relevan, `docs/README.md`, `AGENTS.md` (peta repo, perintah probe baru).
- **AC-17 Tes dengan mutan nyata dan oracle independen:** Dev mencatat di LOG daftar mutan (paling sedikit satu per sistem baru/berubah: tenggat, tip sesudah tenggat, radar posisi/jangkauan/jenis/bantu, progres kotak, angka hasil, margin zona aman, layar hasil) dan tes yang membunuhnya. Harapan tes literal, bukan memanggil fungsi yang dites.
- **AC-18 Invarian prinsip desain tetap dites:** tabrakan dan tenggat tidak menghentikan rute; ngebut dan santai sama-sama punya harga (santai: tenggat lebih ketat/tip hilang bila berhenti lama; ngebut: reaksi lebih sempit — tes 3B tetap hijau); koin tidak pernah berkurang.
- **AC-19 Checklist uji HP** `docs/SETUP_ANDROID.md` 8.8 (penutup Fase 3): 20 rute dibangun tanpa galat (bukti tes), 3 dimainkan (ROUTE_DESIGN 7), rute tidak terasa dihafal setelah tiga kali, tiap tabrakan bisa dijelaskan, radar terbaca saat ngebut, HUD final terbaca dan tidak menutupi apa pun di vivo V2108 (2400×1080, ada lubang kamera), tenggat terasa adil (santai sempat, berhenti lama terasa), tip hilang sesudah tenggat terbaca, layar hasil hangat, kidal/bantu di layar jeda mudah; plus lembar hasil. Uji 8.5–8.7 tetap terpisah.
- **AC-20 Gerbang:** `godot --headless --import` bersih; `run_tests.gd` + `tools/cek_keluaran_tes.py` (dan `--ketat`) lolos; `godot --headless --path . --quit-after 2` tanpa ERROR/WARNING; semua `tools/tests_cek/uji_*.py` lolos; `--export-pack "Android"` tidak memuat `tests/`, `docs/`, atau scene spike; probe jendela (perluas `probe_rute_jendela.gd`/`probe_rintangan_jendela.gd` atau probe baru) menghasilkan tangkapan layar di 1920×1080, 2340×1080, 2400×1080 (dan 1600×720): HUD final awal rute, radar dengan pelanggan/tip/jangkau, mode bantu dengan penanda abu-abu, tenggat hampir habis dan LEWAT, kotak progres campuran, layar hasil (semua terantar; ada meleset + tenggat lewat), layar jeda dengan sakelar Kidal/Bantu, kidal; keluar tanpa ERROR/WARNING (`ProbeKeluar`).

## Perubahan file/struktur yang diharapkan

- `scripts/systems/`: `tenggat_rute.gd` (`TenggatRute`), `radar_rute.gd` (`RadarRute`), `progres_rute.gd` atau bagian dari radar (status kotak), `hasil_rute.gd` (`HasilRute`), `zona_aman.gd` (margin dari inset), perubahan kecil `skor_rute.gd`/pemanggilnya (tip sesudah tenggat). Nama boleh lain, satu tanggung jawab per berkas.
- `scripts/ui/`: `hud_rute.gd` (+ `scenes/ui/hud_rute.tscn`), `radar_strip.gd`, `panel_progres.gd`, `layar_hasil.gd` (+ `scenes/ui/layar_hasil.tscn`), `layar_jeda.gd` (sakelar Kidal/Bantu); `scripts/entities/rute_main.gd`, `adegan_jalan.gd` (sambungan).
- `scenes/dev/spike_sisi_dekat.tscn` + skrip/aset graybox spike; `export_presets.cfg` (pengecualian spike) bila perlu.
- `tests/`: `tes_tenggat.gd`, `tes_radar.gd`, `tes_hasil.gd`, `tes_hud_rute_scene.gd` (atau setara), pembaruan `tes_tata_letak.gd`, `tes_rintangan_scene.gd`, `tes_rute_scene.gd`, `tes_export.gd`; probe jendela.
- `translations/ui.csv` (+ `.translation`), `scripts/config.gd`.

## Tes yang harus ada

- Tenggat: rumus, pembulatan, beku saat jeda, berhenti di garis akhir, tepi lewat.
- Tip sesudah tenggat: murni dan scene.
- Radar: posisi vertikal, jangkauan, jenis, terantar keluar, bantu abu-abu, tip → biasa sesudah tenggat, kidal tidak menukar, `jangkau`.
- Progres: status kotak (terkirim, terlewat, berikutnya, belum).
- Hasil: angka dari `SkorRute`, meleset = 25 − terkirim, tenggat lewat.
- Zona aman: margin dari inset tiruan; tata letak 640/780/800, kanan dan kidal.
- Smoke test layar hasil + Main lagi; layar jeda sakelar Kidal/Bantu.
- Invarian: tenggat dan tabrakan tidak menghentikan rute; mode bantu sempat sebelum tenggat.
- Mutan QA-012 (R07) dan QA-013 (R13) mati.

## Butuh uji perangkat nyata (NEEDS-MANUAL)

- Radar terbaca saat ngebut; jangkauan 30 ubin terasa memberi ancang-ancang; penanda tip dan jangkau terbaca.
- HUD final terbaca dan tidak menutupi sepeda, jalan di depan, atau rintangan di vivo V2108 (lubang kamera); zona aman nyata.
- Tenggat 1,15× santai terasa adil; tip hilang sesudah tenggat terasa wajar, bukan menghukum.
- Layar hasil hangat dan terbaca; Main lagi tidak tertekan tak sengaja.
- Sakelar Kidal/Bantu di layar jeda mudah dipakai.
- Penutup Fase 3 (ROUTE_DESIGN 7): 3 rute dimainkan, tidak terasa dihafal, tiap tabrakan bisa dijelaskan.
- Spike sisi dekat: keputusan pemilik dari tangkapan layar (bukan uji HP wajib).

## Dokumen yang ikut diperbarui

Lihat AC-16 dan AC-19. `DEV_PHASES.md` dicentang hanya sesudah PR dibuka, oleh orchestrator, untuk yang terbukti dan bukan NEEDS-MANUAL; Fase 3 **tidak** ditandai selesai sebelum uji HP pemilik.
