# Animasi jatuh terjerembab (usulan)

Status: **usulan, dipakai di game sejak 2026-10-17** (keputusan pemilik: tabrakan = jatuh, `docs/BALANCING.md` 6c, `docs/ART_DIRECTION.md` 3.4). **Lima arah sejak Fase 5C (2026-10-22).** PNG dan JSON disalin byte demi byte ke `assets/sprites/loper/` dan animasinya masuk `loper_agen_frames.tres` gabungan (68 animasi) lewat `tools/loper_art/bangun_frames.py`; `loper_agen_jatuh_frames.tres` di sini hanya acuan. Game memutar `jatuh_<arah>`, lalu `terjerembab_<arah>`, lalu `bangkit_<arah>` (`../bangkit/`) selama jatuh 1,2 detik, dengan arah saat menabrak (frame dipilih `LoperAnim.frame_jatuh` dari lama sejak tabrakan), lalu kembali ke kayuh dengan kedip kebal.

Saat menabrak atau terpeleset: roda depan tertahan, pemain terlempar lewat setang, lalu jatuh tengkurap dengan muka ke tanah. Sepeda rebah ke kiri pengendara, topi lepas, koran berserakan.

## Isi
- `loper_agen_jatuh.png`: 5 kolom × 5 baris (arah), sel 140×88 px, latar transparan.
- `loper_agen_jatuh_frames.tres`: SpriteFrames Godot 4 (acuan).
- `loper_agen_jatuh.json`: metadata (sel, titik pijak, region tiap frame).
- `preview/`: sheet ×4 dengan grid sel dan titik pijak, GIF lima arah di atas jalan perumahan, dan GIF arah normal lama.

| Animasi | Frame | fps | Loop | Isi |
|---|---|---|---|---|
| `jatuh_<arah>` | 0–3 | 10 | tidak | menabrak, terlempar, mendarat, terjerembab |
| `terjerembab_<arah>` | 3–4 | 3 | ya | tengkurap, satu kaki bergerak pelan |

Baris: `normal`, `serong_kanan`, `kanan`, `serong_kiri`, `kiri` (sama dengan sheet kayuh). Arah kiri dan kanan dirender sendiri lewat yaw arah, tidak dicerminkan.

## Titik pijak
Titik pijak (70, 61) = posisi sepeda saat menabrak. Jarak titik pijak ke tengah sel sama dengan sheet kayuh (61 − 44 = 46 − 29 = 17), jadi dengan `centered = true` offset tetap `Vector2(0, -17)` dan animasi ini dipakai di AnimatedSprite2D yang sama dengan kayuh (dites di `tests/tes_sprite.gd`).

Sel 114×68 lama (titik pijak 57, 51) tidak cukup untuk arah lain: serong_kanan butuh 69 px ke kanan, kanan 27 px ke bawah, serong_kiri 53 px ke atas. Arah normal adalah sheet lama, piksel sama, hanya dipotong ulang ke sel baru.

## Keraguan (usulan, dinilai di HP)
- serong_kiri: tubuh tengkurap lurus ke atas layar terbaca seperti orang berdiri, jadi tubuh diputar 30° di tanah (frame terlempar separuhnya).
- Bintang benturan kuning tetap seperti arah normal (kuning = peringatan).
- Sisi gelap debu `#DCCBA6` (5 px) baru terlihat di arah lain; warnanya sudah ada di `jatuh.py`.

Dibuat oleh `tools/loper_art/jatuh.py` (arah normal) dan `tools/loper_art/fase5c.py` (lima arah).
