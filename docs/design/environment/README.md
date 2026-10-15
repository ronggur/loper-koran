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

Render ulang: lihat `tools/env_art/README.md`.
