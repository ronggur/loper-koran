# Mock lingkungan (usulan)

Contoh art lingkungan dari kanvas "Lingkungan Loper Koran", dirender dengan `tools/env_art`. Semua masih **usulan** (lihat `docs/ART_DIRECTION.md` bagian 2.6). Gambar diperbesar ×2 dari piksel asli, kecuali `kampung_sore.webp` (×3) dan `detail_*.webp` (×5).

| File | Isi |
|---|---|
| `kampung_sore.webp` | Adegan utama: gang perkampungan sore, satu layar 640×360, loop 8 frame |
| `waktu_pagi.png`, `waktu_siang.png`, `waktu_sore.png`, `waktu_malam.png` | Jalan perumahan yang sama dalam empat waktu |
| `banding_hitam.png`, `banding_siang.png` | Bayangan hitam 28% vs bayangan berwarna, potongan sama |
| `distrik_*.png` | Satu potongan jalan per distrik dengan cahaya siang yang sama, 400×250 |
| `detail_jemuran.webp`, `detail_ayam.webp`, `detail_asap.webp` | Loop detail pinggir jalan |
| `strip_*.png` | Frame per frame dari loop detail (×3) |
| `fase3_perumahan.png` | Usulan Fase 3 (`fase3.py`): jalan perumahan siang dengan rumah pelanggan dan bukan pelanggan, anjing penjaga, mobil keluar garasi, koran di teras, enam jenis antena TV |
| `fase3_dua_sisi.png` | Usulan: distrik dengan pelanggan di dua sisi; rumah sisi dekat terlihat belakang, kotak surat di tepi lajur kanan |
| `fase3_anjing.png`, `fase3_mobil_garasi.png`, `fase3_antena_tv.png` | Sheet rintangan dan lembar contoh antena. Sprite 1× yang dipakai Godot ada di `assets/sprites/` |
| `kendaraan_perumahan.png` | Usulan (`kendaraan.py`): jalan perumahan siang dengan mobil tamu parkir (sein), lalu lintas dua arah, motor berpengendara, motor parkir, kucing misi dan kucing dekorasi. Sheet ada di `build/env_art/kendaraan/` |
| `ubin_perumahan_susun.png` | Usulan (`ubin_perumahan.py`): potongan jalan yang disusun ulang dari 18 ubin 64x32 (aspal 2 ubin, trotoar 1 ubin, tata letak game), ×2 |
| `lampu_pohon_siang.png`, `lampu_pohon_malam.png` | Usulan (`lampu_pohon.py`): jalan dari ubin baru dengan lampu jalan dan pohon, siang dan malam, ×2 |
| `gelombang1/komposisi_siang_x3.png`, `gelombang1/komposisi_sore_x3.png` | Usulan Fase 5 gelombang 1 (`gelombang1/render.py`): jalan perumahan siang dan sore ×3 dengan semua aset baru (koran terbang, di kotak surat, terlipat, di rumput; debu, garis kecepatan, bintang kena, koin tip, percikan; tong sampah, misi kucing, kilau; portal dan pos satpam; polisi tidur, zebra, genangan; tembok belakang rendah sisi dekat) |
| `gelombang1/sisi_dekat_siang_x3.png` | Usulan: hanya aset lama + modul tembok sisi dekat, untuk menilai keterbacaan kotak surat dan jalur |
| `gelombang1/tembok_rantai_x3.png`, `gelombang1/ubin_potongan_x3.png` | Usulan: delapan modul tembok disambung; potongan jalan dari ubin lama + ubin baru |
| `gelombang1/lembar_{koran,vfx,properti,dekat,ubin}_x5.png` | Usulan: lembar kontak sprite ×5 per papan, titik pijak ditandai magenta (penanda presentasi, bukan warna game) |

Render ulang: lihat `tools/env_art/README.md`.
