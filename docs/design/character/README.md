# Karakter Loper Koran

Indeks semua aset karakter di repo. Sumber visual: kanvas Design **"Karakter Loper Koran"**. Semua gambar di sini dibuat oleh script di `tools/loper_art/`, jadi bisa dirender ulang. Game memakai salinan sheet kayuh, melambat, dan lempar di `assets/sprites/loper/` dan satu `loper_agen_frames.tres` gabungan (38 animasi) yang dibangun `tools/loper_art/bangun_frames.py` dari tiga JSON di sini.

## Pemain: Fajar Sidik (Kemeja Agen)

Nama dan latar tokoh ada di `docs/STORY.md` bagian 3. Desain baju dan aturan gaya di `docs/ART_DIRECTION.md` bagian 3.

| Folder | Isi | Status |
|---|---|---|
| [`loper_agen/`](./loper_agen/) | Sprite sheet kayuh 15 animasi (3 kecepatan × 5 arah), SpriteFrames, scene, skrip Godot | **Produksi** |
| [`loper_agen/base/`](./loper_agen/base/) | Papan base model: 5 arah santai dan 3 pose kecepatan (normal dan samping) | Acuan |
| `loper_agen/loper_agen_fullbody.png` | Gambar full body skala besar 240×292 dari konversi gambar AI (sejak 2026-10-08), kepala terpisah tanpa leher | Resmi |
| [`loper_agen/jatuh/`](./loper_agen/jatuh/) | Animasi jatuh terjerembab, arah normal | Usulan |
| [`loper_agen/lempar/`](./loper_agen/lempar/) | Animasi lempar koran kiri dan kanan, 3 kecepatan, arah normal dan dua serong (18 animasi); 90° belum ada | Usulan, dipakai di jalan uji sejak 2026-10-09 |
| [`loper_agen/melambat/`](./loper_agen/melambat/) | Tingkat kecepatan di bawah santai: frame santai yang sama, diputar 4 fps | Usulan, dipakai di jalan uji sejak 2026-10-09 |
| [`loper_agen/rem_meluncur/`](./loper_agen/rem_meluncur/) | Animasi meluncur (pedal datar) dan rem (badan sedikit mundur), 5 arah × 4 frame | Usulan |
| [`loper_agen/konversi2/`](./loper_agen/konversi2/) | Gambar sumber AI dan catatan perubahan untuk gambar full body resmi | Sumber |
| [`loper_agen/konversi/`](./loper_agen/konversi/) | Gambar AI yang diubah jadi pixel art dan disesuaikan ke brief | Eksplorasi |
| [`loper_agen/arsip/`](./loper_agen/arsip/) | Full body versi pertama, versi lima nada 294×283, dan versi celana 3/4 | Arsip, tidak dipakai |

## Varian baju

| Folder | Isi | Status |
|---|---|---|
| [`varian/`](./varian/) | Delapan varian baju (a–h): 5 arah santai dan animasi kayuh arah normal | a–g disimpan untuk item, belum diaudit; h = base model |

## Tokoh lain (belum ada desain)

Tokoh cerita (`docs/STORY.md` 3): Ayah, Ibu, Adik, Pak Darto, Dimas. Tokoh rute (`docs/CONTENT_GUIDE.md` 7): Bu Ratmi, satpam kompleks, Pak RT, Pak Sarmin, Pak Ujang. Belum ada sprite atau gambar untuk mereka.
