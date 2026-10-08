# Balancing — Loper Koran

Cara angka-angka game ini ditentukan, diuji, dan diubah. **Semua angka di dokumen ini adalah usulan awal** untuk prototype; tujuannya memberi titik mulai yang masuk akal, bukan jawaban akhir. Angka berubah lewat uji di HP, lalu dokumen ini diperbarui dari `scripts/config.gd`, bukan sebaliknya.

## 1. Satu sumber kebenaran

| File | Isi |
|---|---|
| `scripts/config.gd` | **Semua angka global**: kecepatan, stamina, lemparan, skor, tenggat, ekonomi, keausan. Satu-satunya tempat angka ini ditulis di kode. |
| `assets/data/missions/*.json` | Parameter tiap misi (batas, hadiah), format di `DATA_SCHEMA.md`. |
| `assets/data/routes/<distrik>/*.json` | Segmen rute: jarak rumah, posisi rintangan (`ROUTE_DESIGN.md`). |

Alur mengubah angka:

1. Ubah `scripts/config.gd`.
2. Jalankan tes logika (`tests/run_tests.gd`) yang mengecek target di bagian 9.
3. Coba di HP asli. Angka gerak dan lemparan tidak bisa dinilai dari editor.
4. Perbarui tabel di dokumen ini dan tulis alasannya di bagian 10.

**Satuan.** Jarak memakai **ubin** (1 ubin = 32 unit dunia = satu ubin 64×32 px di layar, ART_DIRECTION 2.2). Kecepatan dalam ubin per detik (u/d). Di skala ×3, 1 u/d kira-kira 107 piksel layar per detik di sepanjang jalan.

---

## 2. Kecepatan dan kontrol

| Angka | Usulan | Catatan |
|---|---|---|
| Kecepatan santai (stick netral) | 3,0 u/d | Tempo dasar. Satu layar 20:9 dilewati kira-kira dalam 7 detik |
| Kecepatan cepat | 4,5 u/d | |
| Kecepatan ngebut (stick penuh ke atas) | 6,0 u/d | |
| Melambat (stick bawah) | turun ke 1,5 u/d | Meluncur: stamina pulih |
| Akselerasi | 3,0 u/d² | |
| Perlambatan melambat | 2,0 u/d² | |
| Rem | 5,0 u/d² sampai berhenti | Aktif setelah stick di ujung bawah (≥ 90%) ditahan 0,25 detik |
| Zona mati stick | 15% | |
| Kecepatan pindah sisi (lateral) | 3,0 u/d | Lebar jalan perumahan 2 ubin |

Stick analog dipetakan halus: sumbu atas memetakan santai → ngebut, sumbu bawah memetakan santai → melambat. **Sprite** memilih tingkat dari posisi stick: di bawah 33% santai, 33–80% cepat, di atas 80% ngebut.

**Arah sprite** dipilih dari arah gerak sebenarnya (gabungan maju dan lateral), bukan dari stick langsung: sudut di bawah 22,5° = normal, 22,5–67,5° = serong, di atas 67,5° = 90°. Akibatnya, belok 90° hanya muncul saat sepeda pelan atau hampir berhenti, sesuai fisika.

---

## 3. Stamina

| Angka | Usulan |
|---|---|
| Stamina maksimum | 100 |
| Santai | +2 / detik (pulih pelan) |
| Cepat | −4 / detik |
| Ngebut | −12 / detik |
| Meluncur atau melambat | +15 / detik |
| Turunan | +10 / detik tambahan (distrik dengan medan) |
| Stamina habis | Kecepatan maksimum turun ke cepat sampai stamina kembali 30 |

Dari penuh, ngebut terus bertahan sekitar 8 detik, dan cepat terus sekitar 25 detik. Meluncur mengisi penuh dalam sekitar 7 detik. Tujuannya: ngebut dipakai untuk menyusul tenggat atau melewati rintangan, bukan sepanjang rute (GDD 2, prinsip 1).

---

## 4. Lemparan

| Angka | Usulan | Catatan |
|---|---|---|
| Swipe minimum | 6% lebar layar | Lebih pendek dari ini diabaikan |
| Swipe maksimum dihitung | 35% lebar layar | |
| Jarak lempar ke samping | 1,5 ubin (swipe pendek) sampai 5 ubin (swipe panjang) | Linear terhadap panjang swipe |
| Lama terbang | 0,45–0,75 detik | Naik dengan jarak |
| Tinggi puncak | 1,0–1,6 ubin | Bayangan koran di tanah wajib tampil |
| Warisan kecepatan sepeda | 100% ke arah maju | Ngebut membuat koran mendarat lebih jauh ke depan (GDD 5.1) |
| Jeda antar lemparan | 0,35 detik | |
| Jumlah koran di awal rute | pelanggan + 20% | 25 pelanggan → 30 koran |

Garis bidik menunjukkan titik mendarat **sudah termasuk** warisan kecepatan, supaya pemain belajar melempar lebih awal saat ngebut lewat apa yang dilihat, bukan coba-coba.

---

## 5. Sasaran dan skor

| Mendarat di | Antaran | Skor | Catatan |
|---|---|---|---|
| Kotak surat | ✅ | 100% | |
| Teras | ✅ | 100% | Pelanggan pemberi tip memberi tip |
| Halaman / rumput | ✅ | 50% | Pelanggan cerewet kesal (GDD 8) |
| Jendela | belum diputuskan | | Bonus atau penalti (ROADMAP 5) |
| Rumah bukan pelanggan, jalan, sisi salah | ❌ meleset | 0 | Memutus combo |

| Angka | Usulan |
|---|---|
| Combo | +0,1 pengali tiap antaran beruntun, maksimum ×2,0 |
| Combo putus | Meleset atau tabrakan |
| Bonus zigzag (seberang ↔ dekat bergantian) | +0,05 pengali tambahan, mulai distrik dua sisi |
| Pengali kecepatan saat melempar | santai ×1,0 · cepat ×1,2 · ngebut ×1,5 |

**Skor dan koin dipisah (usulan):** skor dipakai untuk milestone keahlian dan rasa main, sedangkan koin hanya dari ongkos antar, tip, dan hadiah misi (bagian 7), supaya ekonomi tetap dekat dengan patokan dunia nyata. Hubungan keduanya perlu diputuskan setelah prototype 3.

---

## 6. Rute, tenggat, dan tabrakan

| Angka | Usulan | Catatan |
|---|---|---|
| Lebar petak rumah | 4 ubin | Rumah 3 ubin + celah 1 ubin |
| Rute awal perumahan | 25 pelanggan di sisi seberang, panjang sekitar 250 ubin | Distrik pertama hanya satu sisi. Sela antar pelanggan diisi rumah bukan pelanggan, persimpangan, dan taman |
| Jarak rata-rata antar pelanggan | sekitar 9 ubin | Sekitar 2 detik pada kecepatan cepat, 3 detik pada santai |
| Lama rute | sekitar 55 detik (cepat) sampai 85 detik (santai) | |
| Tenggat | waktu tempuh rute pada kecepatan santai × 1,15 (sekitar 95 detik) | Santai terus masih sempat, tapi berhenti lama untuk misi butuh ngebut di bagian lain |
| Tabrakan | kecepatan turun ke 1,0 u/d, oleng 0,6 detik, combo putus | Tidak menghentikan rute |

Apakah ada game over atau batas tabrakan per hari masih terbuka (GDD 3.2).

---

## 7. Ekonomi

Patokan dari GDD 14.1 (diputuskan sebagai acuan). Angka bengkel di bawah adalah usulan.

| Angka | Nilai |
|---|---|
| 1 koin | Rp100 |
| Ongkos satu pengantaran | 15 koin (rentang 6–20 tergantung jenis koran) |
| Pemasukan satu hari rapi (25 rumah) | 300–375 koin |
| Tip pelanggan pemberi tip (teras tepat) | 5 koin (usulan) |
| Hadiah misi kecil / sedang / besar | 45 / 75 / 120 koin |
| Tambal ban | 100–150 koin (sekitar 1–2 jam kerja loper, usulan) |
| Servis rem | 80 koin (usulan) |
| Sambung / ganti rantai | 150 koin (usulan) |
| Upgrade komponen tingkat 1 | 500–800 koin, sekitar 2 hari kerja (usulan) |

Gagal misi tidak pernah mengurangi koin (GDD 10.5).

### 7.1 Ekonomi cerita (usulan, direvisi 2026-10-08)

Detail dan alasan ada di `STORY.md` bagian 4.1. Semua angka masuk `scripts/config.gd`.

| Parameter | Nilai awal |
|---|---|
| Target Tabungan Kuliah | 25.000 koin (Rp2.500.000) |
| Total kebutuhan awal kuliah / sumbangan keluarga | 50.000 / 25.000 koin |
| `HARI_CERITA` (kalender cerita) | 120 hari (20 April sampai 18 Agustus) |
| `HARI_CERITA_PER_RUTE` | 2 (satu rute dimainkan = hari utama + hari ringkas), jadi 60 rute, sekitar 5 jam |
| `PERSEN_HARI_RINGKAS` | 90 (pendapatan hari ringkas = 90% hari utama) |
| Pendapatan kotor hari utama (rata-rata) / per rute | sekitar 400 / 760 koin |
| Setoran Keluarga / Bengkel / Tabungan | 35% / 15% / 50% (tabungan sekitar 380 koin per rute) |
| Tabungan pemain rata-rata di akhir | sekitar 22.800 koin (91%) |
| Ambang akhir (hari ke-120) | Mandiri 100%; Dibantu warga 70 sampai 99% dan reputasi rata-rata minimal 60; di bawah itu Tunda setahun |

## 8. Keausan sepeda

Belum diisi. Diputuskan di Fase 6 bersama layar bengkel (GDD 12.5). Arah yang sudah disepakati: ngebut dan sering mengerem mempercepat aus, kejadian di rute (paku, kaca, genangan) bisa langsung merusak, setiap kerusakan punya tanda peringatan, dan kerusakan hanya menghambat.

---

## 9. Target yang dicek

| Target | Cara cek |
|---|---|
| Pemain yang santai terus dan tidak berhenti masih menyelesaikan rute sebelum tenggat | Tes logika: waktu tempuh rute ≤ tenggat |
| Ngebut tidak bisa dipakai sepanjang rute | Tes logika: stamina habis sebelum 25% rute |
| Satu hari rapi menghasilkan 300–375 koin | Tes logika dari jumlah pelanggan × ongkos |
| Lemparan bisa mengenai kotak surat di ketiga kecepatan | Uji HP (Fase 2) |
| 60–70% pemain baru menyelesaikan misi yang diambil | Playtest (GDD 10.8) |

---

## 10. Catatan perubahan

- **2026-10-07** — Angka awal ditulis sebagai usulan untuk Fase 0–3. Belum ada yang diuji.
