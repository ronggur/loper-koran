# Meluncur dan rem (usulan)

Status: **usulan, belum dipakai di game** (belum ada di `loper_agen_frames.tres` maupun `loper_sprite.gd`). Dua sheet ini menutup baris "Meluncur" dan "Rem" di `docs/ART_DIRECTION.md` 3.4 dan baris Aset di `docs/TECH_PLAN.md` (Fase 1). Logika gerak bisa jalan dengan sprite kayuh yang ada; sheet ini hanya mengganti tampilannya.

Keduanya dibuat untuk **lima arah** (normal, serong_kanan, kanan, serong_kiri, kiri), bukan hanya normal. Dasarnya frame kayuh **santai 2** (engkol mendatar). Badan atas (kepala sampai pinggang) digeser **kaku** 1 px tanpa meregang, jadi bentuk topi dan kepala tidak berubah dari santai.

| Animasi | Frame | fps | Loop | Isi |
|---|---|---|---|---|
| `meluncur_<arah>` | 4 | 4 | ya | Pedal datar, kaki diam. Badan atas turun 1 px bergantian (bernapas pelan) |
| `rem_<arah>` | 4 | 8 | ya | Pedal datar, badan atas mundur 1 px ke belakang sepeda, lalu turun 1 px bergantian seperti bergetar menahan |

"Mundur" mengikuti arah sepeda di layar: normal dan serong_kanan ke kiri, kanan ke kiri, serong_kiri ke bawah, kiri ke kanan.

## Isi
- `loper_agen_meluncur.png`, `loper_agen_rem.png`: 4 kolom × 5 baris, sel 46×58, titik pijak (23, 46), offset Godot (0, −17). Urutan baris sama dengan santai.
- `loper_agen_meluncur.json`, `loper_agen_rem.json`: metadata dan region tiap frame.
- `preview/prev_<animasi>_<arah>.gif`: pratinjau ×4.

## Membuat ulang
```
python3 tools/loper_art/rem_meluncur.py --out build/loper_art/rem_meluncur
```

## Belum dipakai dan perlu diuji
- Pergeseran 1 px kecil di ×3. Kalau terlalu halus di HP, naikkan jadi 2 px di `REM` pada skrip, atau pakai pose rem khusus (kaki mengerem) lewat renderer.
- Jumlah frame dan fps adalah tebakan; tidak ada bunyi atau kecepatan yang disinkronkan.
- Berhenti (satu kaki turun ke tanah) belum dibuat.
