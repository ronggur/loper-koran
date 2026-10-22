# Pose berhenti, kaki turun (usulan, Fase 5C)

Status: **usulan, dipasang 2026-10-22, dinilai di HP** (`docs/ART_DIRECTION.md` 3.4). PNG dan JSON disalin byte demi byte ke `assets/sprites/loper/` dan masuk `loper_agen_frames.tres` gabungan lewat `tools/loper_art/bangun_frames.py`; `loper_agen_berhenti_frames.tres` di sini hanya acuan.

Kaki **kanan** turun ke tanah di kanan sepeda (sisi yang menghadap kamera, supaya terlihat di arah default; keputusan pemilik 2026-10-22), sepeda condong 7° ke kanan, pedal kiri di depan siap dikayuh, tangan di setang (siku dari `arm_ik`, jadi lengan lurus walau sepeda condong). Frame 1: badan atas turun 1 px (bernapas), digeser kaku seperti `rem_meluncur.py`.

## Isi
- `loper_agen_berhenti.png`: 2 kolom × 5 baris (arah), sel 46×58 px, titik pijak (23, 46) sama dengan sheet kayuh, offset Godot (0, −17).
- `loper_agen_berhenti.json`, `loper_agen_berhenti_frames.tres` (acuan), `preview/` (sheet ×4 bergrid, GIF lima arah: kayuh lalu berhenti).

| Animasi | Frame | fps | Loop |
|---|---|---|---|
| `berhenti_<arah>` | 0–1 | 3 | ya |

## Di game
`LoperAnim.pose_dari_gerak`: rem aktif dan kecepatan sudah 0 (sampai `POSE_MELUNCUR_TOLERANSI_UD`) = `Pose.BERHENTI`; rem aktif dan masih bergerak tetap `Pose.REM`. Menggantikan aturan lama "rem juga saat sudah berhenti".

## Keraguan
- Di arah kiri (kiri atas) kaki kanan sebagian tertutup tas boncengan.
- Di lajur kiri, kaki kanan menapak ke arah tengah jalan, bukan ke kerb (berbeda dari brief awal yang meminta kaki kiri).
- Belum ada frame peralihan rem → berhenti dan berhenti → kayuh.

Dibuat oleh `tools/loper_art/fase5c.py` (opsi `foot_down` di `tools/loper_art/loper.py`).
