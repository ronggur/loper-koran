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
| 0 | Fondasi teknis | M0 | 🟨 kode selesai: run 0A (PR #12) dan 0B+0C (QA lolos); uji HP dan cek light 2D menunggu | |
| 1 | Gerak sepeda & kecepatan (prototype 1) | M1 | ⬜ | |
| 2 | Lemparan koran (prototype 2) | M1 | ⬜ | |
| 3 | Satu rute perumahan (prototype 3) | M2 | ⬜ | |
| 4 | Halaman depan koran & misi kucing (prototype 4) | M2 | ⬜ | |
| 5 | Aset gelombang 1 *(paralel)* | M2–M3 | 🟡 sprite pemain selesai | |
| 6 | Hari demi hari: reputasi, bengkel, ekonomi | M3 | ⬜ | |
| 7 | Vertical slice perumahan & audio dasar | M3 | ⬜ | |
| 8 | Distrik berikutnya, iklan, rilis | M4 | ⬜ | |

**Fase aktif: Fase 0**, dikerjakan lewat loop Dev↔QA dalam tiga run (`LOOP-DEV-QA.md` Bagian 6). Run 0A (fondasi project) lolos QA 2026-10-09; run 0B dan 0C dijalankan sebagai satu run (keputusan pemilik) dan lolos QA 2026-10-09 (input touch, sepeda placeholder, export Android, APK debug terpasang di A54). Yang tersisa untuk menutup Fase 0: uji di HP (rasa kontrol, ketajaman dan skala) dan cek light 2D/glow/partikel/shader di Compatibility.

---

## Fase 0 — Fondasi teknis (M0)

**Tujuan:** project bisa dibangun jadi APK dan jalan di HP sungguhan sebelum gameplay dibuat.

- [x] Putuskan nama package Android: `com.rmh.kring` (2026-10-09, ROADMAP 4b)
- [x] Repo git `loper-koran`: root repo = root project Godot, dokumen di `docs/` (folder ini) dengan `docs/.gdignore`
- [x] Project Godot 4.7.2 landscape, renderer Compatibility (run 0A, 2026-10-09)
- [ ] Cek apakah light 2D, glow, partikel, dan shader warna bayangan yang dibutuhkan jalan di renderer Compatibility di HP target (ART_DIRECTION 2.3, 7)
- [x] Resolusi dasar 640×360 dan stretch `canvas_items` + integer scale + `expand`, skala ×3 (dipilih 2026-10-09, ROADMAP 4b); diverifikasi di jendela desktop pada rasio 16:9, 19.5:9, 20:9 (run 0A, hasil di ROADMAP 4b)
- [ ] Uji ketajaman piksel dan skala di HP (A54 2340×1080 → 780×360 ×3), termasuk memastikan tinggi jendela 1080 di Android supaya skala tidak turun ke ×2 (dikerjakan bersama run 0C)
- [x] Import filter Nearest dan tanpa mipmap untuk sprite dunia; `snap_2d_transforms_to_pixel` aktif
- [x] `scripts/config.gd` berisi angka awal dari `BALANCING.md`
- [x] Input touch: stick melayang di zona kiri bawah, swipe di zona kanan, opsi kidal menukar zona; input keyboard untuk tes di editor (run 0B+0C, 2026-10-09; logika dites headless, rasa kontrol diuji di HP lewat butir "Uji APK di HP")
- [x] Pasang sprite pemain (`assets/sprites/loper/` dari `docs/design/character/loper_agen/`) dan scene `loper_agen.tscn` (di `scenes/entities/`)
- [x] Tes logika headless (`tests/run_tests.gd`) dan CI sederhana (CI hijau di PR #12)
- [x] `CLAUDE.md` / `AGENTS.md` dengan aturan coding dan Definition of Done
- [x] Preset export Android dan APK debug; panduan `SETUP_ANDROID.md` diadaptasi dari Brainy Dungeon (run 0B+0C, 2026-10-09; APK debug `com.rmh.kring` 0.1.0 dibangun lewat CLI dan terpasang di A54)
- [ ] Uji APK di HP

**Selesai kalau:** APK terpasang di HP dan sepeda placeholder bisa digerakkan dengan stick di layar sentuh.

---

## Fase 1 — Gerak sepeda & kecepatan (M1, prototype 1)

**Tujuan:** mengayuh, mengatur kecepatan, dan berpindah sisi terasa enak sebelum ada lemparan.

- [ ] Sistem koordinat dunia ↔ layar isometrik 2:1, jalan lurus naik ke kanan atas, ubin placeholder (ART_DIRECTION 2.2)
- [ ] Kamera: sepeda di sepertiga kiri layar, melebar sedikit ke depan saat ngebut. Coba juga menurunkan posisi sepeda di layar: di A54 rumput kanan bawah kosong dan tinggi layar yang membatasi jalan ke depan (sekitar 2 detik saat ngebut), jadi sepeda lebih rendah memberi sekitar 30% lebih jauh tanpa mengubah skala ×3 (usulan dari uji A54, 2026-10-09; skala ×4 ditolak sementara karena viewport turun ke 585×270)
- [ ] Uji ukuran kontrol dan HUD di A54: radius stick 35 px game, tombol kidal 38 dp (di bawah 44 dp rule `ui-scenes`), teks HUD 6 px. Perbesar kontrol dan HUD tanpa mengubah skala dunia bila perlu
- [ ] Gerak maju terus dengan tiga tingkat kecepatan dari stick (santai/cepat/ngebut) dan transisi halus (BALANCING 2)
- [ ] Melambat dan meluncur (stick bawah), rem saat ditarik penuh dan ditahan dengan ambang di ujung bawah
- [ ] Pindah posisi lateral ke sisi seberang dan sisi dekat; batas tepi jalan
- [ ] Stamina: terkuras saat cepat dan ngebut, pulih saat meluncur (BALANCING 3)
- [ ] Animasi pemain memilih `kecepatan_arah` dari input lewat `loper_sprite.gd`, laju kayuh mengikuti kecepatan
- [ ] Umpan balik kecepatan dasar: debu roda, garis kecepatan (placeholder)
- [ ] HUD sementara: bar kecepatan dan stamina
- [ ] Uji di HP: ambang rem, rasa stick, keterbacaan sprite di skala ×3

**Selesai kalau:** 3–5 orang mencoba di HP dan bisa mengatur kecepatan, mengerem, dan pindah sisi tanpa penjelasan panjang; ambang rem tidak membuat sepeda berhenti tak sengaja.

---

## Fase 2 — Lemparan koran (M1, prototype 2)

**Tujuan:** lemparan yang mewarisi kecepatan terasa memuaskan dan bisa dikuasai.

- [ ] Swipe kiri/kanan di zona kanan menentukan sisi; panjang swipe menentukan kekuatan dan jarak (BALANCING 4)
- [ ] Garis bidik putus-putus selama jari ditahan, lempar saat dilepas
- [ ] Koran mewarisi kecepatan sepeda, lengkung lemparan terlihat (tinggi + bayangan di tanah)
- [ ] Zona sasaran placeholder: kotak surat, teras, halaman, jendela (nilai di BALANCING 5)
- [ ] Sisa koran terbatas dan tampil di HUD
- [ ] Mode bantu: tap sisi layar untuk lempar otomatis ke kotak surat terdekat; kecepatan otomatis
- [ ] Animasi lempar pemain ke sisi seberang dan sisi dekat (aset Fase 5)
- [ ] Uji di HP: ketelitian swipe pendek di layar kecil, lemparan saat ngebut

**Selesai kalau:** pemain bisa mengenai kotak surat dengan sengaja di ketiga kecepatan, dan pertanyaan kontrol di GDD 17 terjawab. **M1 selesai.**

---

## Fase 3 — Satu rute perumahan (M2, prototype 3)

**Tujuan:** satu rute lengkap dari awal sampai akhir dengan rumah, pelanggan, dan dua rintangan.

- [ ] Format segmen rute dan pemuatnya (`DATA_SCHEMA.md` 3), 8–10 segmen perumahan buatan tangan, satu rute memakai 6–8 (`ROUTE_DESIGN.md`)
- [ ] Rute dari urutan segmen acak dengan seed
- [ ] Rumah pelanggan dan bukan pelanggan; distrik pertama hanya pelanggan di sisi seberang
- [ ] Dua rintangan perumahan dengan pola perilakunya: anjing penjaga dan mobil keluar garasi (GDD 9.3)
- [ ] Tabrakan: menghambat, tidak menghentikan rute (aturan pasti di BALANCING 6)
- [ ] Skor: nilai sasaran, combo, pengali kecepatan (BALANCING 5)
- [ ] Radar di tepi kiri dan kanan (DESIGN_SPEC 3.4)
- [ ] HUD rute: progres pelanggan, koin, sisa koran, kecepatan, stamina (DESIGN_SPEC 3)
- [ ] Tenggat rute
- [ ] Layar hasil sederhana: terkirim, meleset, koin, tip
- [ ] Objek yang menutupi pemain jadi semi-transparan

**Selesai kalau:** satu rute 25 pelanggan bisa diselesaikan dari awal sampai layar hasil, dan rute yang sama tidak terasa dihafal setelah tiga kali main.

---

## Fase 4 — Halaman depan koran & misi kucing (M2, prototype 4)

**Tujuan:** satu hari utuh: baca koran, ambil misi, antar, lihat hasil.

- [ ] Layar halaman depan: berita utama, misi sampingan (Ambil/Lewati), berita ringan (desain di DESIGN_SPEC 4)
- [ ] Format misi dan headline (`DATA_SCHEMA.md` 1–2), contoh headline hari 1–3 (`CONTENT_GUIDE.md`)
- [ ] Template Cari dan misi P1 Kucing Bu Ratmi: tiga titik, petunjuk dari lemparan tepat, menepi 1,5 detik, batas 12 rumah
- [ ] HUD misi ("Kucing 0/1", sisa rumah) dan banner selesai/gagal
- [ ] Flag lanjutan disimpan; headline hari berikutnya membaca flag
- [ ] Save sederhana (`user://save.json`)

**Selesai kalau:** satu hari bisa dimainkan dari koran sampai hasil, dan hari berikutnya menampilkan headline lanjutan sesuai hasil misi. **M2 selesai.**

---

## Fase 5 — Aset gelombang 1 (paralel, M2–M3)

**Tujuan:** mengganti placeholder rute perumahan dengan aset final. Daftar dan ukuran ada di ART_DIRECTION 6.

- [x] Sprite pemain Kemeja Agen: 5 arah × 3 kecepatan × 4 frame kayuh (2026-10-07)
- [ ] Animasi pemain: lempar ke sisi seberang dan sisi dekat, meluncur, rem, berhenti dengan kaki turun, tabrakan/oleng (ART_DIRECTION 3.4)
- [ ] Koran: proyektil berputar, mendarat, terlipat di teras
- [ ] Ubin perumahan: jalan, marka, trotoar, kerb, rumput, polisi tidur
- [ ] Rumah modular perumahan (fasad sisi seberang, belakang sisi dekat, atap), kotak surat
- [ ] Properti: tong sampah, pohon, portal satpam, mobil tamu
- [ ] Rintangan: anjing penjaga (lari, berhenti), mobil keluar garasi (lampu mundur)
- [ ] Misi: kucing (diam, kabur), jejak kaki, mangkuk
- [ ] VFX dasar: debu roda, garis kecepatan, koran kena sasaran, tip
- [ ] Ikon HUD

**Selesai kalau:** rute perumahan bisa dimainkan tanpa placeholder.

---

## Fase 6 — Hari demi hari: reputasi, bengkel, ekonomi (M3)

- [ ] Kepribadian pelanggan dan reputasi distrik (GDD 8)
- [ ] Pelanggan baru dan berhenti
- [ ] Komponen sepeda: aus, rusak dengan tanda peringatan, efek di rute (GDD 12)
- [ ] Layar bengkel: servis dan upgrade
- [ ] Ekonomi dari `config.gd` (GDD 14.1, BALANCING 7)
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
