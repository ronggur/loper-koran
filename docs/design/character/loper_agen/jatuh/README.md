# Animasi jatuh terjerembab (usulan)

Status: **usulan, belum dipakai di game.** Aturan sekarang di `docs/ART_DIRECTION.md` 3.4 dan `docs/BALANCING.md` 6 masih menulis tabrakan tanpa jatuh (oleng 0,6 detik). Animasi ini baru dipakai kalau aturan itu diubah.

Saat menabrak atau terpeleset: roda depan tertahan, pemain terlempar lewat setang, lalu jatuh tengkurap dengan muka ke tanah. Sepeda rebah ke kiri, topi lepas, koran berserakan. Baru arah `normal`; empat arah lain dan animasi bangkit belum dibuat.

## Isi
- `loper_agen_jatuh.png`: 5 frame berjajar, sel 114×68 px, latar transparan.
- `loper_agen_jatuh_frames.tres`: SpriteFrames Godot 4 dengan dua animasi.
- `loper_agen_jatuh.json`: metadata (sel, titik pijak, region tiap frame).
- `preview/`: sheet ×4 dan GIF di atas jalan.

| Animasi | Frame | fps | Loop | Isi |
|---|---|---|---|---|
| `jatuh_normal` | 0–3 | 10 | tidak | menabrak, terlempar, mendarat, terjerembab |
| `terjerembab_normal` | 3–4 | 3 | ya | tengkurap, satu kaki bergerak pelan |

## Titik pijak
Titik pijak (57, 51) = posisi sepeda saat menabrak. Sel lebih besar dari sheet kayuh, tapi jarak titik pijak ke tengah sel sama, jadi dengan `centered = true` offset tetap `Vector2(0, -17)`. Kedua animasi bisa disalin ke `loper_agen_frames.tres` dan dipakai di AnimatedSprite2D yang sama (sudah dicek di Godot 4.3).

Dibuat oleh `tools/loper_art/jatuh.py`.
