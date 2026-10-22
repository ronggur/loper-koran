# Animasi bangkit (usulan, Fase 5C)

Status: **usulan, dipasang 2026-10-22, dinilai di HP** (`docs/ART_DIRECTION.md` 3.4). PNG dan JSON disalin byte demi byte ke `assets/sprites/loper/` dan masuk `loper_agen_frames.tres` gabungan lewat `tools/loper_art/bangun_frames.py`; `loper_agen_bangkit_frames.tres` di sini hanya acuan.

Dari tengkurap sampai siap kayuh: bertumpu tangan, berlutut sambil memungut topi, berdiri dan berbalik kembali ke sepeda, meraih setang dan sadel, menegakkan sepeda, lalu duduk di sadel. Frame terakhir **sama piksel demi piksel** dengan kayuh santai frame 0 dan titik pijaknya sama, jadi `santai_<arah>` menyusul tanpa sepeda bergeser (dites di `tests/tes_sprite.gd`).

## Isi
- `loper_agen_bangkit.png`: 6 kolom × 5 baris (arah), sel 140×88 px, titik pijak (70, 61), offset Godot (0, −17).
- `loper_agen_bangkit.json`, `loper_agen_bangkit_frames.tres` (acuan), `preview/` (sheet ×4 bergrid, GIF lima arah: terjerembab → bangkit → kayuh).

| Animasi | Frame | fps | Loop |
|---|---|---|---|
| `bangkit_<arah>` | 0–5 | 10 | tidak |

## Di game
`LoperAnim.frame_jatuh` memutar bangkit di 0,6 detik terakhir jatuh (`TABRAKAN_JATUH_DETIK` 1,2), jadi lama jatuh tidak berubah: jatuh 0–0,4, terjerembab 0,4–0,6, bangkit 0,6–1,2 (frame terakhir ditahan sampai bangun).

## Keraguan
- Koran yang berserakan hilang di frame terakhir (belum dipungut, belum ada aturan koran hilang).
- Topi muncul di tangan di frame 1 tanpa gerakan meraih.
- Dari frame 4 ke 5 pemain langsung duduk (naik sepeda dalam satu langkah).
- Terjerembab tinggal 0,2 detik karena lama jatuh tidak diubah.

Dibuat oleh `tools/loper_art/fase5c.py`.
