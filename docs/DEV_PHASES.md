# Fase Development — Loper Koran

Dokumen ini memecah pekerjaan jadi fase-fase kecil yang bisa dicentang. Fase mengikuti milestone M0–M4 di `ROADMAP.md`, tapi lebih rinci. ROADMAP menjawab "sudah sampai mana secara besar", dokumen ini menjawab "apa yang dikerjakan berikutnya".

## Cara memakai dokumen ini

- **Satu fase aktif dalam satu waktu** di jalur kode (Fase 0–4, lalu 6 dst.). Fase 5 adalah jalur produksi aset yang boleh berjalan paralel begitu art bible disepakati.
- Centang tugas (`[x]`) begitu selesai. Fase dianggap selesai hanya kalau **kriteria selesai** terpenuhi, bukan sekadar semua kotak tercentang.
- Saat fase selesai, ubah statusnya di tabel ringkasan, tulis tanggalnya, dan perbarui status milestone di `ROADMAP.md` kalau milestone-nya ikut selesai.
- Definition of Done untuk tugas kode (usulan, ditulis ke `CLAUDE.md` di Fase 0): jalan tanpa error, sudah dicoba dengan kontrol touch, angka baru masuk `scripts/config.gd`, teks baru masuk file terjemahan, dan tes logika lolos.
- Tugas baru yang muncul di tengah jalan ditambahkan ke fase yang relevan, bukan disimpan di kepala.
- **Uji di HP asli** di akhir setiap fase gameplay. Kontrol yang enak di editor belum tentu enak di layar sentuh.

Status: ⬜ belum mulai · 🟡 sedang dikerjakan · 🟨 kode selesai, uji HP menunggu · ✅ selesai

## Ringkasan

| Fase | Nama | Milestone | Status | Selesai |
|---|---|---|---|---|
| 0 | Fondasi teknis | M0 | ✅ run 0A (PR #12), 0B+0C (PR #14), uji HP di A54 lolos | 2026-10-13 |
| 1 | Gerak sepeda & kecepatan (prototype 1) | M1 | ✅ run 1A (PR #20), 1B (PR #21), 1C (PR #23) lolos QA; uji HP oleh pemilik lolos | 2026-10-14 |
| 2 | Lemparan koran (prototype 2) | M1 | 🟨 kode selesai: run 2A (PR #24), arah bebas (PR #25), 2B (PR #26) lolos QA; uji HP penutup (`SETUP_ANDROID.md` 8.5) menunggu pemilik | |
| 3 | Satu rute perumahan (prototype 3) | M2 | 🟨 kode selesai: run 3A (PR #28), 3B (PR #32), 3C (PR #33: radar, HUD rute, tenggat, layar hasil, keputusan sisi dekat tembok rendah) lolos QA; uji HP penutup (`SETUP_ANDROID.md` 8.8, juga 8.6 dan 8.7) menunggu pemilik | |
| 4 | Halaman depan koran & misi kucing (prototype 4) | M2 | 🟨 kode selesai: run 4A (PR #39: halaman depan koran, format dan pemuat misi dan headline, `HeadlineManager`, save v1, alur hari) dan 4B (PR #40: misi kucing P1, HUD misi, save v2, tutorial hari 1) lolos QA; uji HP penutup (`SETUP_ANDROID.md` 8.9 dan 8.10) menunggu pemilik; belum dicentang | |
| 5 | Aset gelombang 1 *(paralel)* | M2–M3 | 🟡 sprite pemain selesai; usulan gelombang 1 dirender 2026-10-20 (`tools/env_art/gelombang1/`, belum dipasang) | |
| 6 | Hari demi hari: reputasi, bengkel, ekonomi | M3 | 🟡 run 6A1 (kondisi sepeda, bengkel, koin sebagai saldo) dikerjakan 2026-10-20; 6A2 (reputasi, pelanggan) dan 6B menyusul; belum dicentang | |
| 7 | Vertical slice perumahan & audio dasar | M3 | ⬜ | |
| 8 | Distrik berikutnya, iklan, rilis | M4 | ⬜ | |

**Fase aktif: Fase 6, bagian 6A** (pemilik melompat ke 6A dengan sadar 2026-10-20; Fase 5 berjalan paralel dan belum selesai). Run 6A1 (kondisi sepeda, bengkel, koin sebagai saldo) dikerjakan lewat loop Dev↔QA, `docs/loop/20261020-fase6a1-bengkel-kondisi/`. Fase 2, 3, dan 4 sudah **kode selesai** (run 4A PR #39 dan 4B PR #40 lolos QA 2026-10-18) dan **menunggu uji HP pemilik** (`SETUP_ANDROID.md` 8.5 sampai 8.10); Fase 4 dan M2 tidak dicentang sebelum itu. Riwayat Fase 3: (satu rute perumahan; run 3C PR #33 lolos QA 2026-10-17 di iterasi 2: radar, HUD rute final, tenggat, layar hasil; tampilan rumah sisi dekat diputuskan pemilik 2026-10-17 = tembok/pagar belakang rendah; Fase 3 baru selesai sesudah uji HP pemilik `SETUP_ANDROID.md` 8.8; run 3B PR #32 lolos QA 2026-10-16 dan APK-nya terpasang di vivo V2108, uji HP 3B di `SETUP_ANDROID.md` 8.7 belum dilakukan; run 3A PR #28, uji HP 3A di `SETUP_ANDROID.md` 8.6, APK dengan trotoar bisa dilalui dan kotak surat di halaman (PR #30) terpasang di vivo V2108 2026-10-16, belum diuji pemilik; 3B dan 3C menyusul). Fase 2 (lemparan koran) tinggal menunggu uji HP pemilik, dan jalan uji tetap tersedia sebagai scene dev. Riwayat Fase 2:  Run 2A (inti lemparan) lolos QA 2026-10-14 di iterasi 2 (PR #24) dan terpasang di vivo V2108; mode bantu, audio lempar/mendarat, uji HP Fase 2, dan QA-008 (DEFERRED) di Run 2B. Fase 1 selesai 2026-10-14: run 1A, 1B, dan 1C (perapian temuan Run 1B, PR #23) lolos QA, dan uji di HP dinyatakan oke oleh pemilik 2026-10-14. Uji HP dilakukan pemilik sendiri, bukan 3-5 orang (keputusan pemilik 2026-10-14: uji HP cukup oleh pemilik sendiri, tanpa 3-5 penguji lain; tidak ada penguji lain). Riwayat Fase 1: dikerjakan lewat loop Dev↔QA (`LOOP-DEV-QA.md` Bagian 6). Run 1A (logika gerak inti) lolos QA 2026-10-14 di iterasi 1 (PR #20). Run 1B (umpan balik, audio placeholder, layar jeda, penyetelan, probe render) lolos QA 2026-10-14 di iterasi 1 (PR #21); APK terpasang di vivo V2108 (Android 12, 2400×1080) 2026-10-14. Yang tersisa: bukti probe render di A54 dan uji 3-5 orang (`SETUP_ANDROID.md` 8.2). Fase 0 selesai 2026-10-13: run 0A dan 0B+0C lolos QA 2026-10-09, dan uji HP di A54 (checklist `SETUP_ANDROID.md` bagian 8) dinyatakan lolos oleh pemilik 2026-10-13. Cek light 2D/glow/partikel/shader di Compatibility dipindah ke Fase 1 (Run 1B) karena butuh scene uji yang belum ada.

---

## Fase 0 — Fondasi teknis (M0)

**Tujuan:** project bisa dibangun jadi APK dan jalan di HP sungguhan sebelum gameplay dibuat.

- [x] Putuskan nama package Android: `com.rmh.kring` (2026-10-09, ROADMAP 4b)
- [x] Repo git `loper-koran`: root repo = root project Godot, dokumen di `docs/` (folder ini) dengan `docs/.gdignore`
- [x] Project Godot 4.7.2 landscape, renderer Compatibility (run 0A, 2026-10-09)
- [x] Resolusi dasar 640×360 dan stretch `canvas_items` + integer scale + `expand`, skala ×3 (dipilih 2026-10-09, ROADMAP 4b); diverifikasi di jendela desktop pada rasio 16:9, 19.5:9, 20:9 (run 0A, hasil di ROADMAP 4b)
- [x] Uji ketajaman piksel dan skala di HP (A54 2340×1080 → 780×360 ×3), termasuk memastikan tinggi jendela 1080 di Android supaya skala tidak turun ke ×2 (lolos di A54, dikonfirmasi pemilik 2026-10-13)
- [x] Import filter Nearest dan tanpa mipmap untuk sprite dunia; `snap_2d_transforms_to_pixel` aktif
- [x] `scripts/config.gd` berisi angka awal dari `BALANCING.md`
- [x] Input touch: stick melayang di zona kiri bawah, swipe di zona kanan, opsi kidal menukar zona; input keyboard untuk tes di editor (run 0B+0C, 2026-10-09; logika dites headless, rasa kontrol diuji di HP lewat butir "Uji APK di HP")
- [x] Pasang sprite pemain (`assets/sprites/loper/` dari `docs/design/character/loper_agen/`) dan scene `loper_agen.tscn` (di `scenes/entities/`)
- [x] Tes logika headless (`tests/run_tests.gd`) dan CI sederhana (CI hijau di PR #12)
- [x] `CLAUDE.md` / `AGENTS.md` dengan aturan coding dan Definition of Done
- [x] Preset export Android dan APK debug; panduan `SETUP_ANDROID.md` diadaptasi dari Brainy Dungeon (run 0B+0C, 2026-10-09; APK debug `com.rmh.kring` 0.1.0 dibangun lewat CLI dan terpasang di A54)
- [x] Uji APK di HP (checklist `SETUP_ANDROID.md` bagian 8 lolos di A54, dikonfirmasi pemilik 2026-10-13)

**Selesai kalau:** APK terpasang di HP dan sepeda placeholder bisa digerakkan dengan stick di layar sentuh.

---

## Fase 1 — Gerak sepeda & kecepatan (M1, prototype 1)

**Tujuan:** mengayuh, mengatur kecepatan, dan berpindah sisi terasa enak sebelum ada lemparan.

- [ ] Sistem koordinat dunia ↔ layar isometrik 2:1, jalan lurus naik ke kanan atas, ubin placeholder (ART_DIRECTION 2.2)
- [x] Kamera: sepeda di sepertiga kiri layar; saat ngebut sepeda bergeser maju sedikit di bingkai dan saat melambat mundur sedikit (dorongan kecepatan, permintaan Ronggur 2026-10-09; versi awalnya dikerjakan di PR #14, disetel di HP). Coba juga menurunkan posisi sepeda di layar: di A54 rumput kanan bawah kosong dan tinggi layar yang membatasi jalan ke depan (sekitar 2 detik saat ngebut), jadi sepeda lebih rendah memberi sekitar 30% lebih jauh tanpa mengubah skala ×3 (usulan dari uji A54, 2026-10-09; skala ×4 ditolak sementara karena viewport turun ke 585×270). Run 1B: sepeda 75% tinggi layar, dorongan maju 36 / mundur 20 px; lolos uji HP pemilik 2026-10-14
- [x] Uji ukuran kontrol dan HUD di A54: radius stick 35 px game, tombol kidal 38 dp (di bawah 44 dp rule `ui-scenes`), teks HUD 6 px. Perbesar kontrol dan HUD tanpa mengubah skala dunia bila perlu (run 1B: tombol 42 px game ≈ 44 dp, teks HUD 8 px, stick 35 tetap; lolos uji HP pemilik 2026-10-14)
- [x] Gerak maju terus dengan tiga tingkat kecepatan dari stick (santai/cepat/ngebut) dan transisi halus (BALANCING 2) (run 1A, PR #20, 2026-10-14; rasa dinilai di uji HP)
- [x] Melambat dan meluncur (stick bawah), rem saat ditarik penuh dan ditahan dengan ambang di ujung bawah (run 1A, PR #20, 2026-10-14; rasa dinilai di uji HP); ambang rem tetap usulan, ROADMAP 5
- [x] Pindah posisi lateral ke sisi seberang dan sisi dekat; batas tepi jalan (analog bebas, keputusan pemilik 2026-10-13; batas tepi aspal ±1 ubin; run 1A, PR #20; sejak 2026-10-16 batas tepi trotoar ±2 ubin, sepeda boleh naik trotoar)
- [x] Stamina: terkuras saat cepat dan ngebut, pulih saat meluncur (BALANCING 3) (run 1A, PR #20, 2026-10-14; rasa dinilai di uji HP)
- [x] Animasi pemain memilih `kecepatan_arah` dari input lewat `loper_sprite.gd`, laju kayuh mengikuti kecepatan (termasuk pose meluncur dan rem; run 1A, PR #20)
- [x] Umpan balik kecepatan dasar: debu roda, garis kecepatan (placeholder) (run 1B, PR #21, 2026-10-14; keterbacaan dinilai di uji HP); bunyi kayuhan, freewheel, dan rem placeholder lewat autoload `Audio`; tombol dan layar jeda
- [x] HUD sementara: bar kecepatan dan stamina (run 1A, PR #20)
- [x] Cek apakah light 2D, glow, partikel, dan shader warna bayangan yang dibutuhkan jalan di renderer Compatibility di HP target (ART_DIRECTION 2.3, 7); dipindah dari Fase 0 pada 2026-10-13, dikerjakan di Run 1B bersama partikel debu roda (2026-10-14: semua lolos di vivo V2108 / Adreno 618, 60,6 fps, HP uji dipilih pemilik; glow tipis; A54 belum dicek, bukti `docs/loop/20261014-fase1b-umpan-balik/render_vivo/`)
- [x] Uji di HP: ambang rem, rasa stick, keterbacaan sprite di skala ×3 (oleh pemilik, 2026-10-14; angka yang ada dipakai apa adanya)

**Selesai kalau:** pemilik mencoba di HP (keputusan pemilik 2026-10-14: uji HP cukup oleh pemilik sendiri, tanpa 3-5 penguji lain; semula 3–5 orang) dan bisa mengatur kecepatan, mengerem, dan pindah sisi tanpa penjelasan panjang; ambang rem tidak membuat sepeda berhenti tak sengaja.

---

## Fase 2 — Lemparan koran (M1, prototype 2)

**Tujuan:** lemparan yang mewarisi kecepatan terasa memuaskan dan bisa dikuasai.

- [x] Swipe di zona kanan menentukan arah lemparan seperti terlihat di layar (arah bebas, keputusan pemilik 2026-10-15, GDD 5.2; sisi untuk animasi diturunkan dari arah); panjang swipe menentukan kekuatan dan jarak (BALANCING 4) (run 2A, PR #24, 2026-10-14: `ThrowSolver`, 6–35% lebar viewport; run fase2-arah-bebas, PR #25, 2026-10-15: arah dari `Iso`, panjang \|v\| penuh, tanpa sudut ditolak; ambang usulan, ketelitian dinilai di uji HP)
- [x] Garis bidik putus-putus selama jari ditahan, lempar saat dilepas (run 2A, PR #24, 2026-10-14: garis bidik dan lemparan satu lintasan, dites termasuk flick; rasa dinilai di uji HP)
- [x] Koran mewarisi kecepatan sepeda, lengkung lemparan terlihat (tinggi + bayangan di tanah) (run 2A, PR #24, 2026-10-14; rasa dinilai di uji HP)
- [x] Zona sasaran placeholder: kotak surat, teras, halaman, jendela (nilai di BALANCING 5) (run 2A, PR #24, 2026-10-14; jendela lewat sakelar `Config`, bawaan penalti ringan, keputusan akhir ROADMAP 5; sisi dekat datar placeholder)
- [x] Sisa koran terbatas dan tampil di HUD (run 2A, PR #24, 2026-10-14; jeda antar lempar 0,35 detik; isi ulang khusus jalan uji)
- [x] Mode bantu: tap sisi layar untuk lempar otomatis ke kotak surat terdekat; kecepatan otomatis (run 2B, PR #26, 2026-10-15: tap di zona lempar, sisi dari garis jalan, kotak surat pelanggan terdekat di depan selalu kena lewat `ThrowSolver`, santai otomatis dengan stick opsional, sakelar di HUD dev; bunyi lempar dan mendarat placeholder ikut di PR yang sama; rasa dinilai di uji HP)
- [ ] Animasi lempar pemain ke sisi seberang dan sisi dekat (aset Fase 5)
- [ ] Uji di HP: ketelitian swipe pendek di layar kecil, lemparan saat ngebut

**Selesai kalau:** pemain bisa mengenai kotak surat dengan sengaja di ketiga kecepatan, dan pertanyaan kontrol di GDD 17 terjawab. **M1 selesai.**

---

## Fase 3 — Satu rute perumahan (M2, prototype 3)

**Tujuan:** satu rute lengkap dari awal sampai akhir dengan rumah, pelanggan, dan dua rintangan.

- [x] Format segmen rute dan pemuatnya (`DATA_SCHEMA.md` 3), 8–10 segmen perumahan buatan tangan, satu rute memakai 6–8 (`ROUTE_DESIGN.md`) (run 3A, PR #28, 2026-10-16: 9 segmen `assets/data/routes/perumahan/per_*.json`, `SegmenRute` + `PemuatRute`, satu rute memakai 7; format tetap usulan yang diterapkan, `DATA_SCHEMA.md` 3)
- [x] Rute dari urutan segmen acak dengan seed (run 3A, PR #28: `RouteBuilder` berseed, 25 pelanggan, koran awal 30; tiap rute memakai semua 5 segmen tengah, variasi dinilai lewat uji HP, LOG D-1)
- [x] Rumah pelanggan dan bukan pelanggan; distrik pertama hanya pelanggan di sisi seberang (run 3A, PR #28: rumah dan kotak surat dari data di `scenes/rute/rute.tscn`; rumah sisi dekat hanya placeholder `bukan`, cara tampilnya tetap terbuka)
- [x] Dua rintangan perumahan dengan pola perilakunya: anjing penjaga dan mobil keluar garasi (GDD 9.3) (run 3B, PR #32: `AnjingPenjaga`, `MobilGarasi`, `RintanganRute`; tanda ≥ 1,5 detik pada ngebut dan jalan keluar selalu ada dites; rasa tanda dinilai lewat uji HP 8.7)
- [x] Tabrakan: menghambat, tidak menghentikan rute (aturan pasti di BALANCING 6) (run 3B, PR #32: 1,0 u/d, oleng 0,6, kebal 1,0, combo putus, tanpa game over; keputusan pemilik K-1; rasa dinilai lewat uji HP 8.7). Catatan 2026-10-17: keputusan pemilik mengganti oleng dengan **jatuh** 1,2 detik (kecepatan 0, animasi jatuh lalu terjerembab), bangun dan dikayuh lagi dari 0, kebal 1,0 sejak bangun; tetap tidak menghentikan rute (BALANCING 6c, branch `feat/tabrakan-jatuh`)
- [x] Skor: nilai sasaran, combo, pengali kecepatan (BALANCING 5) (run 3B, PR #32: `SkorRute`, bonus tepat ×1,25, koin 15 + tip 5 dihitung terpisah dari skor, K-2 dan K-4; HUD dev sementara, HUD final di 3C)
- [x] Bel "Kring Kring!": tombol bel, "kring" dan "kring kring!", efek visual di atas setang, bunyi placeholder (GDD 5.4, SOUND_DESIGN 3.3; dimajukan dari Fase 6-7 oleh pemilik 2026-10-16, dikerjakan di Run 3B) (run 3B, PR #32; dinilai lewat uji HP 8.7)
- [x] Bunyi mendarat naik setengah nada tiap antaran beruntun sampai 5 tingkat, kembali ke nada dasar saat combo putus, dan denting tip sesudah bunyi mendarat (SOUND_DESIGN 3.1; ditunda dari Fase 2 run fase2b-bantu-audio karena skor dan combo belum ada; bunyi mendarat placeholder empat permukaan sudah ada, `BunyiLempar` + autoload `Audio`) (run 3B, PR #32; dinilai lewat uji HP 8.7)
- [x] Radar di tepi kiri dan kanan (DESIGN_SPEC 3.4) (run 3C, PR #33: `RadarRute`, jangkauan 30 ubin K-2, penanda pelanggan/tip/jangkau; keterbacaan saat ngebut dinilai lewat uji HP 8.8)
- [x] Mode bantu: rumah bukan pelanggan tampil abu-abu (`RADAR_BUKAN`) begitu radar ada (run 3C, PR #33: penanda abu-abu berlubang hanya saat mode bantu) (GDD 5.3; ditunda dari Fase 2 run fase2b-bantu-audio, D-8). Pemilihan sasaran bantu (`BantuLempar.pilih`) dipindah dari zona jalan uji ke data rute
- [x] HUD rute: progres pelanggan, koin, sisa koran, kecepatan, stamina (DESIGN_SPEC 3) (run 3C, PR #33: `HudRute`, panel progres + tenggat, koin, skor/combo, zona aman; sakelar Kidal/Bantu di layar jeda; keterbacaan dan zona aman nyata dinilai lewat uji HP 8.8)
- [x] Tenggat rute (run 3C, PR #33: `TenggatRute` = ceil(panjang / santai × 1,15), sesudah lewat hanya tip yang hilang, K-1; rasa adil dinilai lewat uji HP 8.8)
- [x] Layar hasil sederhana: terkirim, meleset, koin, tip (run 3C, PR #33: `HasilRute` + `scenes/ui/layar_hasil.tscn`, dibuka dengan yang berhasil, Main lagi)
- [x] Objek yang menutupi pemain jadi semi-transparan (run 3A, PR #28: `PenutupPemain` + satu `PenerapPenutup`; dibuktikan dengan objek uji, di rute nyata 0 kejadian menutupi pada lebar jalan resmi, LOG D-8 dan D-19; keterbacaan dinilai lewat uji HP 8.6)

**Selesai kalau:** satu rute 25 pelanggan bisa diselesaikan dari awal sampai layar hasil, dan rute yang sama tidak terasa dihafal setelah tiga kali main.

---

## Fase 4 — Halaman depan koran & misi kucing (M2, prototype 4)

**Tujuan:** satu hari utuh: baca koran, ambil misi, antar, lihat hasil.

- [ ] Layar halaman depan: berita utama, misi sampingan (Ambil/Lewati), berita ringan (desain di DESIGN_SPEC 4) (run 4A: kode dan tes selesai, `HalamanKoran`; belum dicentang sebelum uji HP `SETUP_ANDROID.md` 8.9 dan QA)
- [ ] Format misi dan headline (`DATA_SCHEMA.md` 1–2), contoh headline hari 1–3 (`CONTENT_GUIDE.md`) (run 4A: format dan pemuat, 8 berita utama, 8 ringan, 2 lanjutan, misi P1, tabel hari 1–3 di `CONTENT_GUIDE.md` 8; belum dicentang, QA dan keputusan orchestrator)
- [ ] Template Cari dan misi P1 Kucing Bu Ratmi: tiga titik, petunjuk dari lemparan tepat, menepi 1,5 detik, batas 12 rumah
- [ ] HUD misi ("Kucing 0/1", sisa rumah) dan banner selesai/gagal
- [ ] Flag lanjutan disimpan; headline hari berikutnya membaca flag (run 4A: save menyimpan `flag` dan `HeadlineManager` membacanya dan memprioritaskan lanjutan; flag hasil misi ditulis di 4B)
- [ ] Save sederhana (`user://save.json`) (run 4A: `SaveManager` v1, tulis atomik, simpan hanya di akhir hari, `DataSave.migrasi`; belum dicentang)

**Selesai kalau:** satu hari bisa dimainkan dari koran sampai hasil, dan hari berikutnya menampilkan headline lanjutan sesuai hasil misi. **M2 selesai.**

**Catatan run 4A (2026-10-18, usulan):** satu hari utuh Koran → Rute → Hasil → Hari berikutnya sudah ada dengan save, tanpa misi kucing. Alur hari berurutan ini **prototype yang tidak mengunci struktur sesi** (ROADMAP 5: hari terakhir, game over, target harian, misi lintas hari tetap terbuka). Efek berita utama hanya dicatat. Fase 4 dan M2 tidak dicentang sebelum run 4B dan uji HP.

---

## Fase 5 — Aset gelombang 1 (paralel, M2–M3)

**Tujuan:** mengganti placeholder rute perumahan dengan aset final. Daftar dan ukuran ada di ART_DIRECTION 6.

- [x] Sprite pemain Kemeja Agen: 5 arah × 3 kecepatan × 4 frame kayuh (2026-10-07)
- [ ] Animasi pemain: lempar ke sisi seberang dan sisi dekat, meluncur, rem, berhenti dengan kaki turun, tabrakan = jatuh (ART_DIRECTION 3.4; sejak 2026-10-17 `jatuh_normal` dan `terjerembab_normal` arah normal dipakai untuk semua arah; sisa: empat arah lain dan animasi bangkit)
- [ ] Koran: proyektil berputar, mendarat, terlipat di teras
- [ ] Ubin perumahan: jalan, marka, trotoar, kerb, rumput, polisi tidur
- [ ] Rumah modular perumahan (fasad sisi seberang, belakang sisi dekat, atap), kotak surat
- [ ] Properti: tong sampah, pohon, portal satpam, mobil tamu
- [ ] Rintangan: anjing penjaga (lari, berhenti), mobil keluar garasi (lampu mundur)
- [ ] Misi: kucing (diam, kabur), jejak kaki, mangkuk
- [ ] VFX dasar: debu roda, garis kecepatan, koran kena sasaran, tip
- [ ] Ikon HUD

**Usulan dirender 2026-10-15 (belum dipasang, belum menggantikan placeholder):** rintangan anjing dan mobil garasi, rumah pelanggan dan bukan pelanggan di dua sisi, antena TV (`tools/env_art/fase3.py`), ikon HUD dan penanda radar (`tools/ui_art/hud_ikon.py`). Rincian di ART_DIRECTION 6.4–6.6 dan 6.8. Tugas di atas dicentang setelah asetnya dipasang di rute dan dinilai di HP.

**Usulan gelombang 1 dirender 2026-10-20 (belum dipasang):** dari kanvas Claude Design "Aset Gelombang 1 (Fase 5)" (`docs/design/PROMPT_FASE5.md`), diporting ke `tools/env_art/gelombang1/`: koran (berputar, bayangan, mendarat di teras/rumput/kotak surat, terlipat), VFX (debu roda, garis kecepatan, bintang kena, koin tip, percikan), tong sampah, jejak kucing, mangkuk, kilau misi, portal dan pos satpam, modul tembok belakang rendah sisi dekat (4 varian + tiang), ubin polisi tidur, zebra, genangan. 29 sprite 1× + JSON di `build/`, mock di `docs/design/environment/gelombang1/`, uji `tools/tests_cek/uji_aset_gelombang1.py`. Rincian ART_DIRECTION 6.2–6.9.

- [ ] Salin sprite gelombang 1 ke `assets/sprites/` (tambah opsi salin di `render.py`) dan pasang di rute: koran dan bayangan menggantikan `pola_piksel.gd`, debu dan garis kecepatan menggantikan `umpan_balik_sepeda.gd`, bintang kena dan koin tip di `umpan_melayang_gambar.gd`, kilau dan jejak di misi kucing, tembok sisi dekat di `rumah_daur_rute.gd`
- [x] Putuskan keraguan warna gelombang 1 (ART_DIRECTION 11) sebelum palet induk dikunci (diputuskan 2026-10-21 oleh orchestrator atas delegasi pemilik, usulan; dicentang di Run 5A bersama pemasangannya, palet induk tetap dikunci setelah uji HP)

**Pembagian pemasangan (2026-10-21, `LOOP-DEV-QA.md` 6g):** Run 5A = ubin enam kolom, koran, VFX sepeda, kilau misi; Run 5B = tembok sisi dekat, jenis dekor di data segmen (tong sampah, pohon, lampu jalan), ubin garasi dan simbol, polisi tidur, zebra, genangan; Run 5C = animasi pemain yang kurang (berhenti dengan kaki turun, bangkit, jatuh empat arah lain), pose kucing ditangkap, ubin ujung kerb dan sudut trotoar. Aset M3 (lampu sepeda, jendela menyala, mobil tamu, hujan, logo, detail hidup 6.10, dan seterusnya) menunggu Fase 7.

**Selesai kalau:** rute perumahan bisa dimainkan tanpa placeholder.

---

## Fase 6 — Hari demi hari: reputasi, bengkel, ekonomi (M3)

- [ ] Kepribadian pelanggan dan reputasi distrik (GDD 8)
- [ ] Pelanggan baru dan berhenti
- [ ] Komponen sepeda: aus, rusak dengan tanda peringatan, efek di rute (GDD 12) (run 6A1, PR #43: kode dan tes selesai; belum dicentang karena "terasa menghambat, bukan memblokir" dan frekuensi peringatan butuh uji HP, `SETUP_ANDROID.md` 8.11)
- [x] Layar bengkel: servis dan upgrade (run 6A1, PR #43: `scenes/bengkel/`, `Economy`, `PemuatToko`, `upgrades.json`; dibuktikan tes smoke layar dan alur hari; keterbacaan dan harga di HP menunggu 8.11)
- [ ] Ekonomi dari `config.gd` (GDD 14.1, BALANCING 7) (run 6A1: harga bengkel dan ongkos naik sudah di `Config`; setoran tiga pos dan ekonomi cerita di 6B, belum dicentang)
- [ ] Milestone dasar (GDD 13)

## Fase 7 — Vertical slice perumahan & audio dasar (M3)

- [ ] Lighting dinamis, waktu pagi/siang/sore/malam dengan warna bayangan masing-masing (ART_DIRECTION 2.5), satu cuaca (hujan)
- [ ] Detail hidup pinggir jalan perumahan: jemuran, ayam, kucing, asap warung, layangan (ART_DIRECTION 6.10)
- [ ] Berita utama dengan efek dunia (minimal dua dari GDD 10.7)
- [ ] Misi P2 dan P3
- [ ] Efek suara inti dan ambience perumahan (`SOUND_DESIGN.md`)
- [ ] Playtest seminggu dalam game

**Selesai kalau:** seminggu dalam game di distrik perumahan bisa dimainkan tanpa kebuntuan. **M3 selesai.**

## Fase 8 — Distrik berikutnya, iklan, rilis (M4)

Dirinci setelah M3. Isinya: distrik perkampungan dan ruko, misi per distrik, iklan hadiah, kebijakan privasi dan Data Safety, store listing, uji tertutup.
