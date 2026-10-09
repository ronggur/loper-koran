# Animasi lempar koran (usulan)

Status: **usulan; dipakai di jalan uji sejak 2026-10-09** (run `sprite-lempar-melambat`, hanya animasi pemain, tanpa proyektil, skor, atau sasaran: itu Fase 2). Arah lurus (normal) dan dua arah serong sudah ada; arah 90° kanan dan 90° kiri belum.

Di game: salinan PNG dan JSON byte-identik ada di `assets/sprites/loper/`, dan 18 animasi ini digabung dengan 15 kayuh dan 5 melambat ke `assets/sprites/loper/loper_agen_frames.tres`.

Empat frame per lemparan, sel 46×58 dan titik pijak (23, 46) sama dengan sheet kayuh, jadi bisa ditukar di `AnimatedSprite2D` yang sama. Kaki tetap mengayuh selama melempar. Kiri dan kanan mengikuti arah pelempar (kiri = sisi seberang, kanan = sisi dekat), jadi tidak dicerminkan.

| Frame | Isi |
|---|---|
| 1 Ambil | Tangan mengambil koran dari tas belakang. Sisi kiri: siku keluar ke samping supaya tangan terlihat di atas tas |
| 2 Angkat (kiri) / Tarik (kanan) | Koran diangkat di atas bahu, atau ditarik ke belakang |
| 3 Lepas | Koran lepas dari tangan. **Proyektil muncul di frame ini** (indeks 2) |
| 4 Ikut | Lengan terjulur tanpa koran |

12 fps, tidak loop, sekitar 0,33 detik (4 frame). Selesai frame 4, kembali ke animasi kayuh sesuai tingkat dan arah saat itu; kaki lanjut dari fase frame terakhir (frame 3 lalu kayuh frame 0).

## Dipakai di game (usulan, 2026-10-09)
- Swipe horizontal di zona swipe memainkan `lempar_<sisi>_<kecepatan>_<arah>`: swipe ke kiri layar = sisi seberang (nama `kiri`), ke kanan layar = sisi dekat (`kanan`); kidal hanya menukar zona. Kecepatan = tingkat sprite saat swipe dilepas (melambat memakai santai), arah = arah sprite saat itu (90° memakai serong di sisi yang sama). Swipe vertikal atau lebih pendek dari 12 px (usulan, butuh uji HP) tidak melempar; swipe saat masih melempar diabaikan.
- `LoperSprite` memancarkan `koran_lepas(sisi)` tepat di frame 2 (`release_frame`, `Config.LEMPAR_FRAME_LEPAS`) dan `lempar_selesai`; proyektil koran (Fase 2) tinggal disambungkan ke sinyal itu.
- Alas sprite (baris piksel terbawah dan tapak roda tiga baris terbawah) tiap frame sama dengan frame kayuh sumbernya, jadi sprite tidak melompat saat berganti (dijaga `tests/tes_sprite.gd`).

## Isi
- `loper_agen_lempar.png`: 4 kolom × 18 baris. Urutan: arah (normal, serong_kanan, serong_kiri) → kecepatan (santai, cepat, ngebut) → sisi (kiri, kanan).
- `loper_agen_lempar.json`: metadata. Nama animasi `lempar_<sisi>_<kecepatan>_<arah>`, `release_frame` 2, `source_row` = baris di `loper_agen.png` yang dipakai sebagai dasar.
- `preview/`: GIF per animasi (×4 di atas latar abu) dan tiga sheet ×2 per arah.

## Asal
Dibuat oleh `tools/loper_art/lempar.py`: frame kayuh dari `loper_agen.png` dipakai sebagai dasar, lalu lengan dan koran digambar ulang di atasnya. **Belum dari renderer model 3D** (`produce.py`), jadi kalau sheet kayuh dirender ulang, skrip ini dijalankan lagi. Memindahkan pose lempar ke renderer masih pekerjaan terbuka.

## Belum dibuat
- Arah 90° kanan dan 90° kiri (12 animasi). Sementara pakai serong di sisi yang sama.
- Sprite koran melayang (berputar 4 frame) dan efek mendarat.
