# Animasi jatuh terjerembab (usulan)

Status: **usulan, dipakai di game sejak 2026-10-17** (keputusan pemilik: tabrakan = jatuh, `docs/BALANCING.md` 6c, `docs/ART_DIRECTION.md` 3.4). PNG dan JSON disalin byte demi byte ke `assets/sprites/loper/` dan kedua animasi masuk `loper_agen_frames.tres` gabungan (50 animasi) lewat `tools/loper_art/bangun_frames.py`; `loper_agen_jatuh_frames.tres` di sini hanya acuan. Game memutar `jatuh_normal` lalu `terjerembab_normal` selama jatuh 1,2 detik untuk **semua arah** (frame dipilih `LoperAnim.frame_jatuh` dari lama sejak tabrakan), lalu langsung kembali ke kayuh dengan kedip kebal. Empat arah lain dan animasi bangkit adalah pekerjaan aset Fase 5.

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
Titik pijak (57, 51) = posisi sepeda saat menabrak. Sel lebih besar dari sheet kayuh, tapi jarak titik pijak ke tengah sel sama (51 − 34 = 46 − 29 = 17), jadi dengan `centered = true` offset tetap `Vector2(0, -17)`. Kedua animasi dipakai di AnimatedSprite2D yang sama dengan kayuh (dites di `tests/tes_sprite.gd`, diperiksa di tangkapan jendela asli `docs/loop/20261017-tabrakan-jatuh/shots/`).

Dibuat oleh `tools/loper_art/jatuh.py`.
