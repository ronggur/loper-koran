# Animasi lempar koran (usulan)

Status: **usulan, belum dipakai di game.** Arah lurus (normal) dan dua arah serong sudah ada; arah 90° kanan dan 90° kiri belum.

Empat frame per lemparan, sel 46×58 dan titik pijak (23, 46) sama dengan sheet kayuh, jadi bisa ditukar di `AnimatedSprite2D` yang sama. Kaki tetap mengayuh selama melempar. Kiri dan kanan mengikuti arah pelempar (kiri = sisi seberang, kanan = sisi dekat), jadi tidak dicerminkan.

| Frame | Isi |
|---|---|
| 1 Ambil | Tangan mengambil koran dari tas belakang. Sisi kiri: siku keluar ke samping supaya tangan terlihat di atas tas |
| 2 Angkat (kiri) / Tarik (kanan) | Koran diangkat di atas bahu, atau ditarik ke belakang |
| 3 Lepas | Koran lepas dari tangan. **Proyektil muncul di frame ini** (indeks 2) |
| 4 Ikut | Lengan terjulur tanpa koran |

12 fps, tidak loop, sekitar 0,35 detik. Selesai frame 4, kembali ke animasi kayuh dengan fase kayuh yang sama.

## Isi
- `loper_agen_lempar.png`: 4 kolom × 18 baris. Urutan: arah (normal, serong_kanan, serong_kiri) → kecepatan (santai, cepat, ngebut) → sisi (kiri, kanan).
- `loper_agen_lempar.json`: metadata. Nama animasi `lempar_<sisi>_<kecepatan>_<arah>`, `release_frame` 2, `source_row` = baris di `loper_agen.png` yang dipakai sebagai dasar.
- `preview/`: GIF per animasi (×4 di atas latar abu) dan tiga sheet ×2 per arah.

## Asal
Dibuat oleh `tools/loper_art/lempar.py`: frame kayuh dari `loper_agen.png` dipakai sebagai dasar, lalu lengan dan koran digambar ulang di atasnya. **Belum dari renderer model 3D** (`produce.py`), jadi kalau sheet kayuh dirender ulang, skrip ini dijalankan lagi. Memindahkan pose lempar ke renderer masih pekerjaan terbuka.

## Belum dibuat
- Arah 90° kanan dan 90° kiri (12 animasi). Sementara pakai serong di sisi yang sama.
- Sprite koran melayang (berputar 4 frame) dan efek mendarat.
