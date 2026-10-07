# Sprite loper koran: Kemeja Agen (base model)

Pixel art isometrik 2:1. Sepeda melaju ke kanan atas layar, kamera dari kanan belakang, cahaya dari kiri atas.

Desain sejak 2026-10-07: celana panjang jogger, tanpa keranjang depan, dengan lampu depan dan bel. Ukuran sel dan titik pijak sama dengan versi sebelumnya.

## Isi
- `loper_agen.png`: sprite sheet 1×, latar transparan, bayangan sudah termasuk. 4 kolom × 15 baris, sel 46×58 px.
- `loper_agen_frames.tres`: SpriteFrames Godot 4 dengan 15 animasi, masing-masing 4 frame dan loop.
- `loper_agen.tscn`: AnimatedSprite2D siap pakai. Origin node ada di titik tengah sepeda di tanah, cocok untuk Y-sort.
- `loper_sprite.gd`: memilih animasi dari input stick (`speed_level`, `steer`, `pedal_rate`).
- `loper_agen.json`: metadata (sel, titik pijak, region tiap frame).
- `preview/loper_agen_x4.png`: sprite sheet ×4 untuk dilihat.
- `konversi/`: gambar AI yang diubah jadi pixel art, eksplorasi (lihat README di folder itu).
- `jatuh/`: animasi jatuh terjerembab, **usulan** (belum dipakai; lihat README di folder itu).
- `loper_agen_fullbody.png`: gambar full body skala besar, 294×283 px, kepala terpisah tanpa leher, untuk layar di luar rute (lihat `docs/ART_DIRECTION.md` 3.5). Pratinjau ×3 di `preview/loper_agen_fullbody_x3.png`.

## Pasang di Godot
Salin folder ini ke `res://assets/sprites/loper/`. Kalau foldernya berbeda, ubah path di `.tres` dan `.tscn`.
Pakai filter Nearest (sudah diatur di scene) dan skala bilangan bulat (×3 atau ×4).

## Nama animasi
`<kecepatan>_<arah>`

| Kecepatan | Stick | fps | Pose |
|---|---|---|---|
| santai | netral | 8 | duduk tegak |
| cepat | setengah ke atas | 10 | duduk, condong 50° |
| ngebut | penuh ke atas | 12 | berdiri dari sadel, condong 55°, sepeda bergoyang kiri-kanan |

| Arah | Stick | Menghadap di layar |
|---|---|---|
| normal | lurus | kanan atas (mengikuti jalan) |
| serong_kanan | serong kanan | kanan |
| kanan | 90° kanan | kanan bawah, ke sisi dekat |
| serong_kiri | serong kiri | atas |
| kiri | 90° kiri | kiri atas, ke sisi seberang |

Kiri dan kanan mengikuti arah pelempar, bukan arah layar.

## Titik pijak
Titik tengah sepeda di tanah ada di piksel (23, 46) tiap sel. Dengan `centered = true`, `offset = Vector2(0, -17)`.

## Urutan baris di sheet
santai: normal, serong_kanan, kanan, serong_kiri, kiri (baris 0–4), lalu cepat (5–9), lalu ngebut (10–14).
Kolom 0–3 adalah frame kayuh, berputar maju.

## Sumber dan render ulang
Sheet, JSON, `.tres`, dan isi `preview/` dibuat oleh `tools/loper_art/produce.py` (lihat `docs/ART_DIRECTION.md` bagian 4.1). `loper_agen.tscn` dan `loper_sprite.gd` ditulis tangan dan tidak ikut dirender ulang. Gambar full body dibuat oleh `tools/loper_art/fullbody/fullbody.py`.
Saat Fase 0, salin folder ini (tanpa `preview/`) ke `assets/sprites/loper/`. Folder di `docs/` adalah arsip desain yang diabaikan Godot.
